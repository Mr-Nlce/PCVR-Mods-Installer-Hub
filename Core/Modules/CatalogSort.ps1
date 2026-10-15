# ===============================================================
# Global catalog ordering
#
# Reorders the EXISTING WPF tile objects. Cards are never rebuilt, so
# install-state labels, event handlers, image caches and an active search
# remain attached to the same objects. The compact CatalogIndex.ps1 owns
# stable ids, curated order and dates; this module only presents them.
# ===============================================================

$script:CatalogSortModes = @('hub', 'release', 'added')
$savedCatalogSort = [string](Get-HubSetting -Key 'catalogSort' -Default 'hub')
if ($script:CatalogSortModes -notcontains $savedCatalogSort) { $savedCatalogSort = 'hub' }
$global:CatalogSortMode = $savedCatalogSort

function global:Get-CatalogSortLabel {
    param([string]$Mode = $global:CatalogSortMode)
    switch ($Mode) {
        'release' { return 'Mod release' }
        'added'   { return 'Added to Hub' }
        default   { return 'Alphabetical' }
    }
}

function global:Get-CatalogSortDate {
    param($Game, [string]$Mode)
    if (-not $Game) { return $null }
    $value = if ($Mode -eq 'release') {
        $Game.ModReleasedDate
    } else {
        if ($Game.HubAddedDate) { $Game.HubAddedDate } else { $Game.HubAddedAt }
    }
    if (-not $value) { return $null }
    if ($value -is [datetime]) { return [datetime]$value }
    try {
        return [DateTime]::ParseExact(
            ([string]$value).Trim(),
            'yyyy-MM-dd',
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::None)
    } catch {
        return $null
    }
}

# Pure data helper, intentionally independent of WPF so catalog ordering can
# be regression-tested on every release.
function global:Get-CatalogGamesInOrder {
    param(
        [object[]]$Games,
        [ValidateSet('hub', 'release', 'added')]
        [string]$Mode = $global:CatalogSortMode
    )
    $records = @()
    $fallback = 0
    foreach ($game in @($Games)) {
        $catalogOrder = if ($null -ne $game.CatalogOrder) {
            [int]$game.CatalogOrder
        } else {
            1000000 + $fallback
        }
        $records += [pscustomobject]@{
            Game = $game
            Base = $catalogOrder
            Date = if ($Mode -eq 'hub') { $null } else { Get-CatalogSortDate -Game $game -Mode $Mode }
        }
        $fallback++
    }
    if ($Mode -eq 'hub') {
        return @($records | Sort-Object @{ Expression = { $_.Base }; Ascending = $true } |
            ForEach-Object { $_.Game })
    }
    $dateOrder = @(
        @{ Expression = { if ($_.Date) { 0 } else { 1 } }; Ascending = $true }
        @{ Expression = { if ($_.Date) { $_.Date.Ticks } else { 0 } }; Descending = $true }
        @{ Expression = { $_.Base }; Ascending = $true }
    )
    return @($records | Sort-Object -Property $dateOrder |
        ForEach-Object { $_.Game })
}

function global:Get-CatalogGameFromTile {
    param($Tile)
    if (-not $Tile -or -not $Tile.Resources) { return $null }
    foreach ($key in @('game', 'gameData')) {
        try {
            if ($Tile.Resources.Contains($key)) { return $Tile.Resources.Item($key) }
        } catch { }
    }
    return $null
}

# Decide the portrait order before the first tile is painted. This uses the
# same history, ignored IDs and installed-state rule as the list-view row.
function global:Get-LibraryRecentGames {
    param([object[]]$Games)
    if ($global:LibraryRecentClosed -or
        [bool](Get-HubSetting -Key 'libraryRecentlyPlayedHidden' -Default $false)) { return @() }
    $history = @(Get-HubSetting -Key 'playHistory' -Default @())
    $ignoredIds = @(Get-HubSetting -Key 'recentlyPlayedIgnoredGameIds' -Default @())
    $byTitle = @{}
    foreach ($game in @($Games)) {
        if ($game -and $game.Title) { $byTitle[[string]$game.Title] = $game }
    }
    $haveState = ($global:gameStateMap -and $global:gameStateMap.Count -gt 0)
    $seen = @{}
    $recent = @()
    foreach ($title in $history) {
        if ($recent.Count -ge 5) { break }
        if (-not $byTitle.ContainsKey([string]$title)) { continue }
        $game = $byTitle[[string]$title]
        $id = [string]$game.Id
        if ($seen.ContainsKey($id) -or $ignoredIds -contains $id) { continue }
        if ($haveState) {
            $state = $global:gameStateMap[[string]$title]
            if (-not $state -or @('ready','update') -notcontains [string]$state.State) { continue }
        }
        $seen[$id] = $true
        $recent += $game
    }
    return @($recent)
}

function global:Get-LibraryGamesInOrder {
    param([object[]]$Games, [string]$Mode = $global:CatalogSortMode, [object[]]$RecentGames = @())
    $sorted = @(Get-CatalogGamesInOrder -Games $Games -Mode $Mode)
    $seen = @{}
    $ordered = @()
    foreach ($game in @($RecentGames) + $sorted) {
        $id = [string]$game.Id
        if (-not $seen.ContainsKey($id)) { $seen[$id] = $true; $ordered += $game }
    }
    return @($ordered)
}

function global:Update-LibraryRecentBadgeLayout {
    if (-not $global:window) { return }
    $labelHost = $global:window.FindName('LibraryRecentHost')
    $column = $global:window.FindName('LibraryRecentColumn')
    if (-not $labelHost -or -not $column -or
        $labelHost.Visibility -ne [System.Windows.Visibility]::Visible) { return }
    $wideTitle = $global:window.FindName('LibraryRecentWideTitle')
    $narrowTitle = $global:window.FindName('LibraryRecentNarrowTitle')
    $windowWidth = if ($global:window.ActualWidth -gt 0) { $global:window.ActualWidth } else { $global:window.Width }
    $wide = ($windowWidth -ge 1200)
    $labelHost.Width = if ($wide) { 188 } else { 112 }
    $labelHost.Height = if ($wide) { 36 } else { 56 }
    $column.Width = [System.Windows.GridLength]::new($(if ($wide) { 196 } else { 120 }))
    if ($wideTitle) {
        $wideTitle.Visibility = if ($wide) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    }
    if ($narrowTitle) {
        $narrowTitle.Visibility = if ($wide) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    }
}

function global:Set-LibraryRecentLabel {
    param([int]$Count)
    if (-not $global:window) { return }
    $labelHost = $global:window.FindName('LibraryRecentHost')
    $column = $global:window.FindName('LibraryRecentColumn')
    $manage = $global:window.FindName('LibraryRecentManage')
    if (-not $labelHost -or -not $column) { return }
    $visible = ($Count -gt 0)
    $labelHost.Visibility = if ($visible) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $countText = $global:window.FindName('LibraryRecentCount')
    if ($countText) { $countText.Text = [string][Math]::Min(5, [Math]::Max(0, $Count)) }
    if ($visible) { Update-LibraryRecentBadgeLayout }
    else { $column.Width = [System.Windows.GridLength]::new(0) }
    if (-not $visible -and $manage) { $manage.Visibility = [System.Windows.Visibility]::Collapsed }
}

function global:Refresh-LibraryRecentPlacement {
    if (-not $global:DiscoverTilesBuilt -or -not $global:discoverPanel) { return }
    $games = @($global:discoverPanel.Children | ForEach-Object { Get-CatalogGameFromTile -Tile $_ })
    $recent = @(Get-LibraryRecentGames -Games $games)
    $global:LibraryRecentGameIds = @($recent | ForEach-Object { [string]$_.Id })
    Set-LibraryRecentLabel -Count $recent.Count
    Set-CatalogPanelOrder -Panel $global:discoverPanel -Mode $global:CatalogSortMode -UseCatalogOrder -PinnedIds $global:LibraryRecentGameIds
}

function global:Set-CatalogPanelOrder {
    param(
        $Panel,
        [ValidateSet('hub', 'release', 'added')]
        [string]$Mode = $global:CatalogSortMode,
        [switch]$UseCatalogOrder,
        [string[]]$PinnedIds = @()
    )
    if (-not $Panel -or $Panel.Children.Count -lt 2) { return }

    $records = @()
    $position = 0
    foreach ($child in @($Panel.Children)) {
        $game = Get-CatalogGameFromTile -Tile $child
        $base = $position
        if ($UseCatalogOrder -and $game -and $null -ne $game.CatalogOrder) {
            $base = [int]$game.CatalogOrder
        } else {
            try {
                if ($child.Resources.Contains('_hubViewOrder')) {
                    $base = [int]$child.Resources.Item('_hubViewOrder')
                } else {
                    $child.Resources.Add('_hubViewOrder', $position)
                }
            } catch { }
        }
        $pin = [array]::IndexOf($PinnedIds, [string]$game.Id)
        $records += [pscustomobject]@{
            Child = $child
            Game  = $game
            Base  = $base
            Pin   = if ($pin -ge 0) { $pin } else { 1000000 }
            Date  = if ($Mode -eq 'hub' -or -not $game) { $null } else {
                Get-CatalogSortDate -Game $game -Mode $Mode
            }
        }
        $position++
    }

    if ($Mode -eq 'hub') {
        $ordered = @($records | Sort-Object @{ Expression = { $_.Pin }; Ascending = $true }, @{ Expression = { $_.Base }; Ascending = $true })
    } else {
        $panelOrder = @(
            @{ Expression = { $_.Pin }; Ascending = $true }
            @{ Expression = { if ($_.Game -and $_.Date) { 0 } elseif ($_.Game) { 1 } else { 2 } }; Ascending = $true }
            @{ Expression = { if ($_.Date) { $_.Date.Ticks } else { 0 } }; Descending = $true }
            @{ Expression = { $_.Base }; Ascending = $true }
        )
        $ordered = @($records | Sort-Object -Property $panelOrder)
    }

    $changed = $false
    for ($i = 0; $i -lt $ordered.Count; $i++) {
        if (-not [object]::ReferenceEquals($ordered[$i].Child, $Panel.Children[$i])) {
            $changed = $true
            break
        }
    }
    if (-not $changed) { return }

    # Snapshot first, then detach and reattach the SAME controls.
    $children = @($ordered | ForEach-Object { $_.Child })
    $Panel.Children.Clear()
    foreach ($child in $children) { $Panel.Children.Add($child) | Out-Null }
}

function global:Set-CatalogSortUi {
    if (-not $global:window) { return }
    $label = $global:window.FindName('OrderLabel')
    if ($label) { $label.Text = Get-CatalogSortLabel }
    $dotMap = @{
        hub     = $global:window.FindName('OrderDotHub')
        release = $global:window.FindName('OrderDotRelease')
        added   = $global:window.FindName('OrderDotAdded')
    }
    foreach ($mode in $dotMap.Keys) {
        if ($dotMap[$mode]) {
            $dotMap[$mode].Visibility = if ($mode -eq $global:CatalogSortMode) {
                [System.Windows.Visibility]::Visible
            } else {
                [System.Windows.Visibility]::Collapsed
            }
        }
    }
}

function global:Apply-CatalogSort {
    param(
        [ValidateSet('All', 'List', 'Library', 'Explore')]
        [string]$Scope = 'All',
        [switch]$ResetScroll,
        [switch]$SkipFilter
    )
    $mode = $global:CatalogSortMode

    if ($Scope -in @('All', 'List')) {
        foreach ($name in @('OwnGameList', 'OwnGameListGP', 'ExternalGameList')) {
            Set-CatalogPanelOrder -Panel $global:window.FindName($name) -Mode $mode
        }
    }
    if ($Scope -in @('All', 'Library')) {
        if ($global:discoverPanel -and $global:DiscoverTilesBuilt) {
            Set-CatalogPanelOrder -Panel $global:discoverPanel -Mode $mode -UseCatalogOrder -PinnedIds $global:LibraryRecentGameIds
        }
    }
    if ($Scope -in @('All', 'Explore')) {
        if ($global:OvGenreRowsPanel) {
            foreach ($row in @($global:OvGenreRowsPanel.Children)) {
                $tiles = $null
                $scroll = $null
                try {
                    $tiles = $row.Resources.Item('tilesPanel')
                    $scroll = $row.Resources.Item('scrollViewer')
                } catch { }
                if ($tiles) {
                    Set-CatalogPanelOrder -Panel $tiles -Mode $mode
                    try {
                        if ($tiles.Tag -is [hashtable] -and $tiles.Tag.ContainsKey('Games')) {
                            $tiles.Tag['Games'] = @(Get-CatalogGamesInOrder -Games @($tiles.Tag['Games']) -Mode $mode)
                        }
                    } catch { }
                }
                if ($ResetScroll -and $scroll) { try { $scroll.ScrollToHorizontalOffset(0) } catch { } }
            }
        }
    }

    if ($ResetScroll) {
        foreach ($scroll in @($global:listScroll, $global:discoverTiles, $global:discoverOverview)) {
            if ($scroll -and $scroll.Visibility -eq [System.Windows.Visibility]::Visible) {
                try { $scroll.ScrollToTop() } catch { }
            }
        }
    }
    if (-not $SkipFilter -and (Get-Command Apply-Filter -ErrorAction SilentlyContinue)) {
        # Visibility is recalculated on the same tile objects, so an active
        # search and every filter survive a sort change.
        try { Apply-Filter } catch { }
    }
}

function global:Set-CatalogSortMode {
    param(
        [ValidateSet('hub', 'release', 'added')]
        [string]$Mode,
        [switch]$Persist
    )
    $global:CatalogSortMode = $Mode
    if ($Persist -and (Get-Command Set-HubSetting -ErrorAction SilentlyContinue)) {
        Set-HubSetting -Key 'catalogSort' -Value $Mode
    }
    Set-CatalogSortUi
    Apply-CatalogSort -Scope All -ResetScroll
}

# UI wiring -----------------------------------------------------
$global:catalogOrderPill = $window.FindName('OrderPill')
$global:catalogOrderOverlay = $window.FindName('OrderOverlay')
$global:catalogOrderScrim = $window.FindName('OrderScrim')
$global:catalogOrderChevron = $window.FindName('OrderChevron')

function global:Test-CatalogOrderMenuOpen {
    return ($global:catalogOrderOverlay -and
        $global:catalogOrderOverlay.Visibility -eq [System.Windows.Visibility]::Visible)
}
function global:Set-CatalogOrderPillActive {
    param([bool]$Active)
    if (-not $global:catalogOrderPill) { return }
    $global:catalogOrderPill.BorderBrush =
        [System.Windows.Media.BrushConverter]::new().ConvertFromString(
            $(if ($Active) { '#3a8add' } else { '#2a2a35' }))
}
function global:Open-CatalogOrderMenu {
    if (Get-Command Close-HubMenu -ErrorAction SilentlyContinue) { Close-HubMenu }
    $global:catalogOrderOverlay.Visibility = [System.Windows.Visibility]::Visible
    Set-CatalogOrderPillActive -Active $true
    if ($global:catalogOrderChevron) {
        $global:catalogOrderChevron.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
        $global:catalogOrderChevron.RenderTransform = [System.Windows.Media.RotateTransform]::new(180)
    }
}
function global:Close-CatalogOrderMenu {
    if (-not $global:catalogOrderOverlay) { return }
    $global:catalogOrderOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    Set-CatalogOrderPillActive -Active ($global:catalogOrderPill -and $global:catalogOrderPill.IsMouseOver)
    if ($global:catalogOrderChevron) {
        $global:catalogOrderChevron.RenderTransform = [System.Windows.Media.RotateTransform]::new(0)
    }
}

if ($global:catalogOrderPill) {
    $global:catalogOrderPill.Add_MouseEnter({ Set-CatalogOrderPillActive -Active $true })
    $global:catalogOrderPill.Add_MouseLeave({
        Set-CatalogOrderPillActive -Active (Test-CatalogOrderMenuOpen)
    })
    # Open only after the physical click is complete. If the overlay becomes
    # visible on button-down, its scrim receives that same click's button-up
    # and immediately closes the menu again.
    $global:catalogOrderPill.Add_PreviewMouseLeftButtonUp({
        param($s, $e)
        $e.Handled = $true
        if (Test-CatalogOrderMenuOpen) { Close-CatalogOrderMenu } else { Open-CatalogOrderMenu }
    })
}
if ($global:catalogOrderScrim) {
    # Keep the overlay hit-testable until this physical click has fully
    # finished. Collapsing it on button-down can retarget the matching
    # button-up to a featured banner underneath and open that game.
    $global:catalogOrderScrim.Add_PreviewMouseLeftButtonUp({
        param($s, $e)
        $e.Handled = $true
        Close-CatalogOrderMenu
    })
}
if ($global:catalogOrderOverlay) {
    $global:catalogOrderOverlay.Add_PreviewMouseWheel({ Close-CatalogOrderMenu })
}

$orderChoiceMap = @{
    hub     = $window.FindName('OrderChoiceHub')
    release = $window.FindName('OrderChoiceRelease')
    added   = $window.FindName('OrderChoiceAdded')
}
foreach ($mode in $orderChoiceMap.Keys) {
    $choice = $orderChoiceMap[$mode]
    if (-not $choice) { continue }
    $choice.Add_MouseEnter({
        $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#1e1e2a')
    })
    $choice.Add_MouseLeave({ $this.Background = [System.Windows.Media.Brushes]::Transparent })
    $modeCapture = $mode
    $choice.Add_PreviewMouseLeftButtonUp({
        param($s, $e)
        $e.Handled = $true
        Set-CatalogSortMode -Mode $modeCapture -Persist
        Close-CatalogOrderMenu
    }.GetNewClosure())
}

# The Gem facet acts on button-down in Filter.Controls so the selection state
# paints immediately. Close the menu only on button-up; this retains the
# overlay until the physical click is complete and prevents click-through to
# a featured banner or game card underneath.
$orderGemChoice = $window.FindName('FilterGem')
if ($orderGemChoice) {
    $orderGemChoice.Add_PreviewMouseLeftButtonUp({
        param($s, $e)
        $e.Handled = $true
        Close-CatalogOrderMenu
    })
}

$window.Add_PreviewKeyDown({
    param($s, $e)
    if ($e.Key -eq [System.Windows.Input.Key]::Escape -and (Test-CatalogOrderMenuOpen)) {
        $e.Handled = $true
        Close-CatalogOrderMenu
    }
})

$libraryRecentHost = $window.FindName('LibraryRecentHost')
$libraryRecentManage = $window.FindName('LibraryRecentManage')
$libraryRecentClose = $window.FindName('LibraryRecentClose')
$libraryRecentDisable = $window.FindName('LibraryRecentDisable')
if ($libraryRecentHost -and $libraryRecentManage -and $libraryRecentClose -and $libraryRecentDisable) {
    $window.Add_SizeChanged({ Update-LibraryRecentBadgeLayout })
    # Match the list-view header's deliberate five-second management hover.
    $global:LibraryRecentShowTimer = New-Object System.Windows.Threading.DispatcherTimer
    $global:LibraryRecentShowTimer.Interval = [TimeSpan]::FromSeconds(5)
    $global:LibraryRecentHideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $global:LibraryRecentHideTimer.Interval = [TimeSpan]::FromMilliseconds(800)
    $global:LibraryRecentShowTimer.Add_Tick({
        $global:LibraryRecentShowTimer.Stop()
        if ($libraryRecentHost.IsMouseOver -and $libraryRecentHost.Visibility -eq [System.Windows.Visibility]::Visible) {
            $libraryRecentManage.Visibility = [System.Windows.Visibility]::Visible
        }
    }.GetNewClosure())
    $global:LibraryRecentHideTimer.Add_Tick({
        $global:LibraryRecentHideTimer.Stop()
        $libraryRecentManage.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())
    $libraryRecentHost.Add_MouseEnter({
        $global:LibraryRecentHideTimer.Stop()
        if ($libraryRecentManage.Visibility -ne [System.Windows.Visibility]::Visible) {
            $global:LibraryRecentShowTimer.Stop()
            $global:LibraryRecentShowTimer.Start()
        }
    }.GetNewClosure())
    $libraryRecentHost.Add_MouseLeave({
        $global:LibraryRecentShowTimer.Stop()
        if ($libraryRecentManage.Visibility -eq [System.Windows.Visibility]::Visible) {
            $global:LibraryRecentHideTimer.Stop()
            $global:LibraryRecentHideTimer.Start()
        }
    }.GetNewClosure())
    $libraryRecentClose.Add_PreviewMouseLeftButtonUp({
        param($s, $e)
        $e.Handled = $true
        $global:LibraryRecentClosed = $true
        $global:LibraryRecentShowTimer.Stop()
        $global:LibraryRecentHideTimer.Stop()
        Refresh-LibraryRecentPlacement
    }.GetNewClosure())
    $libraryRecentDisable.Add_PreviewMouseLeftButtonUp({
        param($s, $e)
        $e.Handled = $true
        Set-HubSetting -Key 'libraryRecentlyPlayedHidden' -Value $true
        $global:LibraryRecentShowTimer.Stop()
        $global:LibraryRecentHideTimer.Stop()
        Refresh-LibraryRecentPlacement
    }.GetNewClosure())
}

Set-CatalogSortUi
Apply-CatalogSort -Scope List -SkipFilter
