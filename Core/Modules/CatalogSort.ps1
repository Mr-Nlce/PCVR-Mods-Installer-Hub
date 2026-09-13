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

function global:Set-CatalogPanelOrder {
    param(
        $Panel,
        [ValidateSet('hub', 'release', 'added')]
        [string]$Mode = $global:CatalogSortMode
    )
    if (-not $Panel -or $Panel.Children.Count -lt 2) { return }

    $records = @()
    $position = 0
    foreach ($child in @($Panel.Children)) {
        $base = $position
        try {
            if ($child.Resources.Contains('_hubViewOrder')) {
                $base = [int]$child.Resources.Item('_hubViewOrder')
            } else {
                $child.Resources.Add('_hubViewOrder', $position)
            }
        } catch { }
        $game = Get-CatalogGameFromTile -Tile $child
        $records += [pscustomobject]@{
            Child = $child
            Game  = $game
            Base  = $base
            Date  = if ($Mode -eq 'hub' -or -not $game) { $null } else {
                Get-CatalogSortDate -Game $game -Mode $Mode
            }
        }
        $position++
    }

    if ($Mode -eq 'hub') {
        $ordered = @($records | Sort-Object @{ Expression = { $_.Base }; Ascending = $true })
    } else {
        $panelOrder = @(
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
            Set-CatalogPanelOrder -Panel $global:discoverPanel -Mode $mode
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
    $global:catalogOrderPill.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        $e.Handled = $true
        if (Test-CatalogOrderMenuOpen) { Close-CatalogOrderMenu } else { Open-CatalogOrderMenu }
    })
}
if ($global:catalogOrderScrim) {
    $global:catalogOrderScrim.Add_MouseLeftButtonDown({
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
    $choice.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        $e.Handled = $true
        Close-CatalogOrderMenu
        Set-CatalogSortMode -Mode $modeCapture -Persist
    }.GetNewClosure())
}

$window.Add_PreviewKeyDown({
    param($s, $e)
    if ($e.Key -eq [System.Windows.Input.Key]::Escape -and (Test-CatalogOrderMenuOpen)) {
        $e.Handled = $true
        Close-CatalogOrderMenu
    }
})

Set-CatalogSortUi
Apply-CatalogSort -Scope List -SkipFilter
