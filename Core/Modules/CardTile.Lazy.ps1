# ============================================================
# CardTile.Lazy.ps1 - viewport-driven card realization
# ------------------------------------------------------------
# Startup used to build every list card and every Library tile in
# full, element by element in PowerShell (~12 ms per card, so the
# cost grew linearly with the catalog). This module replaces that
# with a two-layer model:
#
#   1. DATA LAYER - every game still gets exactly one element in its
#      panel, but it is a cheap, fixed-size placeholder Border that
#      carries the game object ("gameData" / "game") and the scan
#      state (Tag). Scan, filter, sort, scale and search all keep
#      working on these elements, so they always see ALL games. The
#      placeholder has no temporary title: a second title briefly
#      appeared at another position during fast scrolling.
#
#   2. VISUAL LAYER - the full card content is built into the SAME
#      Border only when it scrolls into (or close to) the viewport.
#      Everything that is never looked at is never built. The scan
#      state recorded in gameStateMap is painted onto the card at
#      the moment it is built.
#
# Switch: $global:HubLazyCards ($true by default). Set the
# environment variable PCVR_HUB_LAZY_CARDS=0 before starting the Hub
# to get the previous behaviour (everything built up front) for an
# A/B comparison.
# ============================================================

if ($null -eq $global:HubLazyCards) {
    $global:HubLazyCards = -not ([string]$env:PCVR_HUB_LAZY_CARDS -eq '0')
}
# How far beyond the visible edge cards are prepared (device-independent px).
if ($null -eq $global:LazyRealizeAheadPx)  { $global:LazyRealizeAheadPx  = 220 }
# Maximum build time per dispatcher pass while scrolling. Further cards
# are built in the next pass, so input and rendering are never starved.
if ($null -eq $global:LazyRealizeBudgetMs) { $global:LazyRealizeBudgetMs = 30 }

$global:LazyHosts          = New-Object System.Collections.ArrayList
$global:LazyRealizeQueued  = $false
$global:LazyRealizeStats   = @{ Built = 0; Passes = 0; BuildMs = 0; Failed = 0 }
$global:LazyRetryTimer     = $null
$global:LazySettleTimer    = $null
$global:LazyFastUntil      = [DateTime]::MinValue
$global:LazyLastScrollAt    = [DateTime]::MinValue
$global:LazyIdleWarmTimer   = $null
$global:LazyIdleWarmBuilt   = 0

$script:LazyCardBg = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(14, 14, 18))
$script:LazyCardBg.Freeze()
$script:LazyCardBd = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(30, 30, 38))
$script:LazyCardBd.Freeze()
$script:LazyTileBg = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(22, 22, 26))
$script:LazyTileBg.Freeze()
$script:LazyTileBd = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(42, 42, 50))
$script:LazyTileBd.Freeze()

function global:Test-CardIsLazy {
    param($Element)
    if (-not $Element) { return $false }
    try { return [bool]$Element.Resources.Contains('cardLazy') } catch { return $false }
}

# Keep a failed card visible and useful. A failed build can have left partial
# resources or event handlers on its Border, so retrying that same Border
# automatically would duplicate handlers. A style rebuild creates a fresh
# placeholder and gives the renderer another chance.
function global:Show-LazyCardFailure {
    param($Card, $Game)
    if (-not $Card) { return }
    if (-not $Card.Resources.Contains('cardLazy')) { $Card.Resources.Add('cardLazy', $true) }
    if (-not $Card.Resources.Contains('cardBuildFailed')) { $Card.Resources.Add('cardBuildFailed', $true) }
    $Card.Background = $script:LazyCardBg
    $Card.BorderBrush = $script:LazyCardBd
    $Card.BorderThickness = [System.Windows.Thickness]::new(1)
    $content = [System.Windows.Controls.StackPanel]::new()
    $content.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $content.Margin = [System.Windows.Thickness]::new(9)
    $title = [System.Windows.Controls.TextBlock]::new()
    $title.Text = [string]$Game.Title
    $title.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $title.TextAlignment = [System.Windows.TextAlignment]::Center
    $title.Foreground = [System.Windows.Media.Brushes]::White
    [void]$content.Children.Add($title)
    $action = [System.Windows.Controls.TextBlock]::new()
    $action.Text = 'Show details'
    $action.Margin = [System.Windows.Thickness]::new(0, 9, 0, 0)
    $action.TextAlignment = [System.Windows.TextAlignment]::Center
    $action.Foreground = [System.Windows.Media.Brushes]::LightSkyBlue
    $action.Tag = $Game
    $action.Cursor = [System.Windows.Input.Cursors]::Hand
    $action.Add_PreviewMouseLeftButtonDown({
        param($sender, $eventArgs)
        $eventArgs.Handled = $true
        if (Get-Command Open-DiscoverDetailFromList -ErrorAction SilentlyContinue) {
            Open-DiscoverDetailFromList -Game $sender.Tag
        }
    })
    [void]$content.Children.Add($action)
    $Card.Child = $content
}

# ------------------------------------------------------------
# List cards (Custom Installers MC / GP, External)
# ------------------------------------------------------------
# Same outer geometry as New-GameCardFrosted / New-GameCardClassic
# (175 x 160, right/bottom margin 12, radius 8). The S/M/L size is a
# LayoutTransform set by Apply-CardScale on the element itself, so
# the placeholder and the later full card always occupy the same slot
# and building a card never shifts the layout.
function global:New-LazyGameCard {
    param($game, $isExternal)
    $card = [System.Windows.Controls.Border]::new()
    $card.UseLayoutRounding = $true
    $card.Width  = 175
    $card.Height = 160
    $card.Margin = [System.Windows.Thickness]::new(0, 0, 12, 12)
    $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $card.Background = $script:LazyCardBg
    $card.BorderBrush = $script:LazyCardBd
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.Tag = ""
    $card.Resources.Add('gameData', $game)
    $card.Resources.Add('cardIsExternal', [bool]$isExternal)
    $card.Resources.Add('cardLazy', $true)
    Register-FavoriteCard -Card $card -Game $game
    return $card
}

function global:Invoke-LazyGameCardBuild {
    param($Card)
    if (-not (Test-CardIsLazy $Card)) { return }
    $game = $Card.Resources.Item('gameData')
    $isExternal = $false
    try { $isExternal = [bool]$Card.Resources.Item('cardIsExternal') } catch { }
    $Card.Resources.Remove('cardLazy') | Out-Null
    $tag = [string]$Card.Tag
    try {
        if ($global:hubStyle -eq 'classic') {
            if (-not (Get-Command New-GameCardClassic -ErrorAction SilentlyContinue)) {
                . $global:HubCardClassicPath
            }
            [void](New-GameCardClassic -game $game -isExternal $isExternal -window $global:window -Into $Card)
        } else {
            [void](New-GameCardFrosted -game $game -isExternal $isExternal -window $global:window -Into $Card)
        }
    } catch {
        $global:LazyRealizeStats.Failed++
        try { Write-Host ("  [card-build] lazy build failed for '{0}': {1}" -f $game.Title, $_.Exception.Message) -ForegroundColor DarkYellow } catch { }
        Show-LazyCardFailure -Card $Card -Game $game
        return
    }
    # The scan may have recorded a state while this card was still a
    # placeholder. Paint it now with the same restore routine that is
    # used after a style switch or a single-game refresh.
    $Card.Tag = $tag
    if ($Card.Resources.Contains('feedbackReminder')) {
        $m=$Card.Margin
        $Card.Margin=[Windows.Thickness]::new($m.Left,32,$m.Right,$m.Bottom)
    }
    try {
        $state = $null
        if ($game -and $game.Title -and $global:gameStateMap) { $state = $global:gameStateMap[[string]$game.Title] }
        if ($state -and (Get-Command Restore-CardVisualState -ErrorAction SilentlyContinue)) {
            Restore-CardVisualState -Card $Card -Game $game -State $state
        }
    } catch {
        try { Write-Host ("  [card-build] state restore failed for '{0}': {1}" -f $game.Title, $_.Exception.Message) -ForegroundColor DarkYellow } catch { }
    }
}

# A scan walks every game, including games whose card has not been
# built. Its painting code expects the card's sub-elements (button
# text, button border, cap, reload pill, ...). For a placeholder it
# paints into this throwaway proxy instead; only the resulting Tag is
# copied back. The recorded gameStateMap entry is identical to the
# built-card case, and the real card is painted from it when built.
function global:New-CardScanProxy {
    param($Card, $Game)
    $proxy = [System.Windows.Controls.Border]::new()
    $proxy.Tag = $Card.Tag
    $accent = if ($Game.Accent) { [string]$Game.Accent } elseif (-not $Game.Bat) { "#445566" } else { "#666677" }
    $bg = [System.Windows.Media.Brushes]::Transparent
    $r = $proxy.Resources
    $r.Add('gameData', $Game)
    $r.Add('btnText', [System.Windows.Controls.TextBlock]::new())
    $r.Add('btnBorder', [System.Windows.Controls.Border]::new())
    $r.Add('reloadPill', [System.Windows.Controls.Border]::new())
    $r.Add('reloadGlyph', [System.Windows.Controls.TextBlock]::new())
    $r.Add('accentCap', [System.Windows.Controls.Border]::new())
    $r.Add('freeBtnLabel', [System.Windows.Controls.TextBlock]::new())
    $r.Add('baseAccent', $accent)
    $r.Add('originalAccent', $accent)
    $r.Add('baseBgBrush', $bg)
    $r.Add('baseBdBrush', $bg)
    $r.Add('originalBgBrush', $bg)
    $r.Add('originalBdBrush', $bg)
    $r.Add('cardScanProxy', $true)
    return $proxy
}

# ------------------------------------------------------------
# Library tiles (portrait grid)
# ------------------------------------------------------------
function global:New-LazyDiscoverTile {
    param($Game)
    $tile = [System.Windows.Controls.Border]::new()
    $sizeKey = if ($global:DiscoverTileSize) { $global:DiscoverTileSize } else { "L" }
    $dim = $global:DiscoverTileSizes[$sizeKey]
    $tile.Width  = $dim.W
    $tile.Height = $dim.H
    # Same margin as New-DiscoverTile (room for the hover bloom).
    $tile.Margin = [System.Windows.Thickness]::new(0, 14, 14, 14)
    $tile.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $tile.Background = $script:LazyTileBg
    $tile.BorderBrush = $script:LazyTileBd
    $tile.BorderThickness = [System.Windows.Thickness]::new(1)
    $tile.Resources.Add('game', $Game)
    $tile.Resources.Add('cardLazy', $true)
    return $tile
}

function global:Invoke-LazyDiscoverTileBuild {
    param($Tile)
    if (-not (Test-CardIsLazy $Tile)) { return }
    $game = $Tile.Resources.Item('game')
    $Tile.Resources.Remove('cardLazy') | Out-Null
    # New-DiscoverTile builds into this Border and replaces the
    # placeholder look (transparent outer border, frame inside).
    $Tile.Background = [System.Windows.Media.Brushes]::Transparent
    $Tile.BorderThickness = [System.Windows.Thickness]::new(0)
    try {
        [void](New-DiscoverTile -Game $game -Into $Tile)
    } catch {
        $global:LazyRealizeStats.Failed++
        try { Write-Host ("  [library-build] lazy build failed for '{0}': {1}" -f $game.Title, $_.Exception.Message) -ForegroundColor DarkYellow } catch { }
        Show-LazyCardFailure -Card $Tile -Game $game
        return
    }
    if (Get-Command Update-DiscoverTileStatus -ErrorAction SilentlyContinue) {
        try { Update-DiscoverTileStatus -Tile $Tile } catch { }
    }
}

# ------------------------------------------------------------
# Explore tiles (horizontal genre rows)
# ------------------------------------------------------------
function global:New-LazyOverviewTile {
    param($Game)
    $tile = [System.Windows.Controls.Border]::new()
    $sizeKey = if ($global:ExploreSize) { $global:ExploreSize } else { "M" }
    $dim = $global:OverviewTileSizes[$sizeKey]
    if (-not $dim) { $dim = $global:OverviewTileSizes["M"] }
    $tile.Width  = $dim.W
    $tile.Height = $dim.H
    # Same margin as New-OverviewTile.
    $tile.Margin = [System.Windows.Thickness]::new(0, 14, 10, 14)
    $tile.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $tile.Background = $script:LazyTileBg
    $tile.BorderBrush = $script:LazyTileBd
    $tile.BorderThickness = [System.Windows.Thickness]::new(1)
    $tile.Resources.Add('game', $Game)
    $tile.Resources.Add('cardLazy', $true)
    return $tile
}

function global:Invoke-LazyOverviewTileBuild {
    param($Tile)
    if (-not (Test-CardIsLazy $Tile)) { return }
    $game = $Tile.Resources.Item('game')
    $Tile.Resources.Remove('cardLazy') | Out-Null
    $Tile.Background = [System.Windows.Media.Brushes]::Transparent
    $Tile.BorderThickness = [System.Windows.Thickness]::new(0)
    try {
        [void](New-OverviewTile -Game $game -Into $Tile)
    } catch {
        $global:LazyRealizeStats.Failed++
        try { Write-Host ("  [explore-build] lazy build failed for '{0}': {1}" -f $game.Title, $_.Exception.Message) -ForegroundColor DarkYellow } catch { }
        Show-LazyCardFailure -Card $Tile -Game $game
    }
}

# ------------------------------------------------------------
# Hosts and realization passes
# ------------------------------------------------------------
# A host is one ScrollViewer plus the WrapPanels inside it whose
# children are realized on demand.
function global:Register-LazyHost {
    param([string]$Name, $Scroll, [scriptblock]$GetPanels, [scriptblock]$Build, [switch]$Horizontal)
    if (-not $global:HubLazyCards -or -not $Scroll) { return }
    foreach ($h in $global:LazyHosts) { if ($h.Name -eq $Name) { return } }
    # -Horizontal: every panel is a single-row horizontal strip inside its
    # own ScrollViewer (Explore genre rows); x is checked against that.
    [void]$global:LazyHosts.Add([pscustomobject]@{
        Name = $Name; Scroll = $Scroll; GetPanels = $GetPanels; Build = $Build; Horizontal = [bool]$Horizontal
    })
    $Scroll.Add_ScrollChanged({
        param($sender, $eventArgs)
        Register-LazyScrollMove -Sender $sender -EventArgs $eventArgs
        Request-LazyRealize
    })
    $Scroll.Add_IsVisibleChanged({ Request-LazyRealize })
    $Scroll.Add_SizeChanged({ Request-LazyRealize })
}

function global:Request-LazyRealize {
    if (-not $global:HubLazyCards -or $global:LazyRealizeQueued) { return }
    if (-not $global:window -or -not $global:window.Dispatcher) { return }
    $global:LazyRealizeQueued = $true
    # Background priority runs after layout and rendering, so positions
    # are current and a running scroll animation is never starved.
    [void]$global:window.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [System.Action]{
            $global:LazyRealizeQueued = $false
            try { Invoke-LazyRealizePass }
            catch { try { Write-HubTiming ("lazy: pass failed: {0}" -f $_.Exception.Message) } catch { } }
        })
}

# A large scroll jump can put a new screen of unbuilt cards in view.
# Spend the next passes on that screen; resume the small look-ahead band
# after scrolling has been still for 160 ms. The normal per-pass time
# budget stays unchanged so the scroll animation remains responsive.
function global:Register-LazyScrollMove {
    param($Sender, $EventArgs)
    if ([Math]::Abs([double]$EventArgs.VerticalChange) -gt 0 -or
        [Math]::Abs([double]$EventArgs.HorizontalChange) -gt 0) {
        $global:LazyLastScrollAt = [DateTime]::UtcNow
    }
    $verticalChange = 0.0
    $horizontalChange = 0.0
    $viewportHeight = 0.0
    $viewportWidth = 0.0
    try { $verticalChange = [Math]::Abs([double]$EventArgs.VerticalChange) } catch { }
    try { $horizontalChange = [Math]::Abs([double]$EventArgs.HorizontalChange) } catch { }
    try { $viewportHeight = [double]$Sender.ViewportHeight } catch { }
    try { $viewportWidth = [double]$Sender.ViewportWidth } catch { }
    if (($viewportHeight -gt 0 -and $verticalChange -gt (0.75 * $viewportHeight)) -or
        ($viewportWidth -gt 0 -and $horizontalChange -gt (0.75 * $viewportWidth))) {
        $global:LazyFastUntil = [DateTime]::MaxValue
    }
    if ($global:LazyFastUntil -ne [DateTime]::MaxValue) { return }
    if (-not $global:LazySettleTimer) {
        $global:LazySettleTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $global:LazySettleTimer.Interval = [TimeSpan]::FromMilliseconds(160)
        $global:LazySettleTimer.Add_Tick({
            $global:LazySettleTimer.Stop()
            $global:LazyFastUntil = [DateTime]::MinValue
            Request-LazyRealize
        })
    }
    $global:LazySettleTimer.Stop()
    $global:LazySettleTimer.Start()
}

# Prepare a few cards just below the current list viewport while the user is
# idle. WPF elements must be created on the UI dispatcher; one card per tick
# keeps input and animations ahead of this optional work. Never walk the whole
# catalog or warm an invisible view.
function global:Invoke-LazyIdleWarmStep {
    if (-not $global:HubLazyCards -or -not $global:window -or
        $global:window.WindowState -eq [System.Windows.WindowState]::Minimized -or
        $global:ScanInProgress -or $global:ScanQueued -or
        $global:LazyRealizeQueued -or
        $global:LazyFastUntil -eq [DateTime]::MaxValue -or
        ([DateTime]::UtcNow - $global:LazyLastScrollAt).TotalSeconds -lt 3) { return }
    if ($global:LazyIdleWarmBuilt -ge 36) {
        $global:LazyIdleWarmTimer.Stop()
        return
    }
    $hostInfo = @($global:LazyHosts | Where-Object { $_.Name -eq 'List' }) | Select-Object -First 1
    if (-not $hostInfo -or -not $hostInfo.Scroll.IsVisible) { return }
    $candidates = Get-LazyCandidates -HostInfo $hostInfo -Ahead 800
    $next = @($candidates | Where-Object { $_.Dist -gt 0 } | Sort-Object Dist, Order) | Select-Object -First 1
    if (-not $next) {
        $global:LazyIdleWarmTimer.Stop()
        return
    }
    & $next.Build $next.Element
    $global:LazyIdleWarmBuilt++
}

function global:Start-LazyIdleWarm {
    if (-not $global:HubLazyCards -or $global:LazyIdleWarmTimer) { return }
    $global:LazyIdleWarmTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $global:LazyIdleWarmTimer.Interval = [TimeSpan]::FromSeconds(1)
    $global:LazyIdleWarmTimer.Add_Tick({ Invoke-LazyIdleWarmStep })
    $delay = [System.Windows.Threading.DispatcherTimer]::new()
    $delay.Interval = [TimeSpan]::FromSeconds(20)
    $delay.Add_Tick({
        $delay.Stop()
        if ($global:window -and $global:window.IsVisible) { $global:LazyIdleWarmTimer.Start() }
    }.GetNewClosure())
    $delay.Start()
}

# While a scan walks the cards the realization waits (the scan pumps
# the dispatcher, which would otherwise run passes between games and
# slow the scan). A short timer resumes as soon as the scan is over.
function global:Start-LazyRetryTimer {
    if (-not $global:LazyRetryTimer) {
        $global:LazyRetryTimer = New-Object System.Windows.Threading.DispatcherTimer
        $global:LazyRetryTimer.Interval = [TimeSpan]::FromMilliseconds(300)
        $global:LazyRetryTimer.Add_Tick({
            if ($global:ScanInProgress) { return }
            $global:LazyRetryTimer.Stop()
            Request-LazyRealize
        })
    }
    if (-not $global:LazyRetryTimer.IsEnabled) { $global:LazyRetryTimer.Start() }
}

# Unbuilt elements of one host that intersect the viewport extended by
# $Ahead pixels. Dist = 0 for visible elements, otherwise the distance
# to the viewport edge, so visible cards are always built first.
function global:Get-LazyCandidates {
    param($HostInfo, [double]$Ahead)
    $found = New-Object System.Collections.ArrayList
    $sv = $HostInfo.Scroll
    if (-not $sv -or -not $sv.IsVisible) { return , $found }
    $vh = [double]$sv.ViewportHeight
    if ($vh -le 0) { $vh = [double]$sv.ActualHeight }
    if ($vh -le 0) { return , $found }
    $origin = [System.Windows.Point]::new(0, 0)
    $visible = [System.Windows.Visibility]::Visible
    $order = 0
    foreach ($panel in @(& $HostInfo.GetPanels)) {
        if (-not $panel -or -not $panel.IsVisible) { continue }
        $py = 0.0
        try { $py = $panel.TransformToAncestor($sv).Transform($origin).Y } catch { continue }
        if ($py -gt ($vh + $Ahead)) { continue }
        if (($py + $panel.ActualHeight) -lt (-$Ahead)) { continue }
        if ($HostInfo.Horizontal) {
            # The whole strip is one row: it is in view vertically (checked
            # above); now walk left to right inside the row's own viewport.
            $rowDist = if (($py + $panel.ActualHeight) -lt 0) { -($py + $panel.ActualHeight) } elseif ($py -gt $vh) { $py - $vh } else { 0.0 }
            $hsv = $panel.Parent
            $x0 = 0.0; $vw = [double]$sv.ViewportWidth
            if ($hsv -is [System.Windows.Controls.ScrollViewer]) {
                $x0 = [double]$hsv.HorizontalOffset
                $vw = [double]$hsv.ViewportWidth
                if ($vw -le 0) { $vw = [double]$hsv.ActualWidth }
            }
            foreach ($child in $panel.Children) {
                if (-not $child) { continue }
                if (-not $child.Resources.Contains('cardLazy')) { continue }
                if ($child.Resources.Contains('cardBuildFailed')) { continue }
                if ($child.Visibility -ne $visible) { continue }
                $x = [System.Windows.Media.VisualTreeHelper]::GetOffset($child).X - $x0
                if ($x -gt ($vw + $Ahead)) { break }
                $w = [double]$child.DesiredSize.Width
                if ($w -le 0) { $w = [double]$child.ActualWidth }
                if (($x + $w) -lt (-$Ahead)) { continue }
                $xDist = if (($x + $w) -lt 0) { -($x + $w) } elseif ($x -gt $vw) { $x - $vw } else { 0.0 }
                $order++
                [void]$found.Add([pscustomobject]@{ Element = $child; Dist = ($rowDist + $xDist); Order = $order; Build = $HostInfo.Build })
            }
            continue
        }
        foreach ($child in $panel.Children) {
            if (-not $child) { continue }
            if (-not $child.Resources.Contains('cardLazy')) { continue }
            if ($child.Resources.Contains('cardBuildFailed')) { continue }
            if ($child.Visibility -ne $visible) { continue }
            $y = $py + [System.Windows.Media.VisualTreeHelper]::GetOffset($child).Y
            # WrapPanel places children in order, top to bottom: the first
            # unbuilt card below the window means all later ones are too.
            if ($y -gt ($vh + $Ahead)) { break }
            $h = [double]$child.DesiredSize.Height
            if ($h -le 0) { $h = [double]$child.ActualHeight }
            if (($y + $h) -lt (-$Ahead)) { continue }
            $dist = if (($y + $h) -lt 0) { -($y + $h) } elseif ($y -gt $vh) { $y - $vh } else { 0.0 }
            $order++
            [void]$found.Add([pscustomobject]@{ Element = $child; Dist = $dist; Order = $order; Build = $HostInfo.Build })
        }
    }
    return , $found
}

function global:Invoke-LazyRealizePass {
    param([switch]$VisibleOnly, [switch]$NoBudget)
    if (-not $global:HubLazyCards -or $global:LazyHosts.Count -eq 0) { return }
    if ($global:ScanInProgress) { Start-LazyRetryTimer; return }
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $fast = ($global:LazyFastUntil -eq [DateTime]::MaxValue)
    $ahead = if ($VisibleOnly -or $fast) { 0.0 } else { [double]$global:LazyRealizeAheadPx }
    $all = New-Object System.Collections.ArrayList
    $order = 0
    foreach ($h in $global:LazyHosts) {
        $c = Get-LazyCandidates -HostInfo $h -Ahead $ahead
        foreach ($candidate in $c) {
            $order++
            $candidate.Order = $order
            [void]$all.Add($candidate)
        }
    }
    if ($all.Count -eq 0) { return }
    $ordered = @($all | Sort-Object -Property Dist, Order)
    $built = 0
    $more = $false
    foreach ($cand in $ordered) {
        if (-not $NoBudget -and $built -gt 0 -and $watch.ElapsedMilliseconds -ge $global:LazyRealizeBudgetMs) {
            $more = $true
            break
        }
        & $cand.Build $cand.Element
        $built++
    }
    $watch.Stop()
    $global:LazyRealizeStats.Built += $built
    $global:LazyRealizeStats.Passes++
    $global:LazyRealizeStats.BuildMs += $watch.ElapsedMilliseconds
    try {
        Write-HubTiming ("lazy: built {0} in {1} ms (total {2} built, {3} ms){4}" -f `
            $built, $watch.ElapsedMilliseconds, $global:LazyRealizeStats.Built, $global:LazyRealizeStats.BuildMs,
            $(if ($VisibleOnly) { ' [visible only]' } else { '' }))
    } catch { }
    # Cards that are still pending (budget hit, or the look-ahead band
    # after a visible-only pass) are handled in the next pass.
    if ($more -or $VisibleOnly) { Request-LazyRealize }
}

# Called once from Startup.ps1, right before ShowDialog.
function global:Register-LazyCardHosts {
    if (-not $global:HubLazyCards -or -not $global:window) { return }
    $listScroll = $global:window.FindName('ListScroll')
    Register-LazyHost -Name 'List' -Scroll $listScroll -GetPanels {
        @($global:window.FindName('OwnGameList'), $global:window.FindName('OwnGameListGP'), $global:window.FindName('ExternalGameList'), $global:window.FindName('UntestedGameList'))
    } -Build { param($el) Invoke-LazyGameCardBuild -Card $el }
    $ovScroll = $global:window.FindName('DiscoverOverviewScroll')
    Register-LazyHost -Name 'Explore' -Scroll $ovScroll -Horizontal -GetPanels {
        $rows = @()
        if ($global:OvGenreRowsPanel) {
            foreach ($row in $global:OvGenreRowsPanel.Children) {
                if (-not $row -or -not $row.IsVisible) { continue }
                $tp = $null
                try { $tp = $row.Resources.Item('tilesPanel') } catch { }
                if ($tp) { $rows += $tp }
            }
        }
        $rows
    } -Build { param($el) Invoke-LazyOverviewTileBuild -Tile $el }
    $libScroll = $global:window.FindName('DiscoverTilesScroll')
    Register-LazyHost -Name 'Library' -Scroll $libScroll -GetPanels {
        @($global:discoverPanel)
    } -Build { param($el) Invoke-LazyDiscoverTileBuild -Tile $el }

    # First frame: build exactly the visible cards synchronously before
    # the first render, so the window never opens with empty frames.
    # The look-ahead band follows in the next (budgeted) pass.
    $global:window.Add_Loaded({
        try {
            $global:window.UpdateLayout()
            Write-HubTiming "lazy: window loaded, building visible cards"
            Invoke-LazyRealizePass -VisibleOnly -NoBudget
            Start-LazyIdleWarm
        } catch {
            try { Write-HubTiming ("lazy: initial pass failed: {0}" -f $_.Exception.Message) } catch { }
        }
    })
}
