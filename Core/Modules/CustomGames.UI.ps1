# ---------------------------------------------------------------
# "My Games" UI (loaded by CustomGames.ps1)
# ---------------------------------------------------------------
# Everything here is built in code and inserted at runtime, so the
# window XAML stays untouched:
#   * menu item "My Games (Beta)" after "Desktop Shortcut" (on/off)
#   * a "My Games" section in the Library view (below the featured
#     banner) and in the List view (below Recently Played)
#   * tiles: click = launch, right-click = Favorite / Edit / Picture /
#     Folder / Remove, last tiles = "+ Add game" and "Import from Steam"
#   * add/edit dialog and Steam import dialog
# With the setting off, only the menu item exists.
# ---------------------------------------------------------------

function global:New-CgBrush {
    param([string]$Hex)
    return [System.Windows.Media.BrushConverter]::new().ConvertFromString($Hex)
}

function global:Test-CustomGamesEnabled {
    try { return [bool](Get-HubSetting -Key 'customGamesEnabled' -Default $false) } catch { return $false }
}

function global:Write-CustomGamesTrace {
    param([string]$Text)
    try { Write-HubTiming ("customgames: {0}" -f $Text) } catch { }
}

function global:Show-CustomGamesMessage {
    param(
        [string]$Text,
        [System.Windows.MessageBoxButton]$Buttons = [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]$Icon = [System.Windows.MessageBoxImage]::Information
    )
    try {
        if ($global:window) { return [System.Windows.MessageBox]::Show($global:window, $Text, 'My Games', $Buttons, $Icon) }
    } catch { }
    return [System.Windows.MessageBox]::Show($Text, 'My Games', $Buttons, $Icon)
}

# ---------------------------------------------------------------
# Menu item
# ---------------------------------------------------------------
function global:Update-CustomGamesMenuItem {
    if (-not $global:CustomGamesMenuSub) { return }
    if (Test-CustomGamesEnabled) {
        $n = @(Read-CustomGames).Count
        $global:CustomGamesMenuSub.Text = ('On ({0} games) - click to turn off' -f $n)
    } else {
        $global:CustomGamesMenuSub.Text = 'Off - launch your own games from the Hub'
    }
}

function global:Add-CustomGamesMenuItem {
    if (-not $global:window) { return }
    $anchor = $global:window.FindName('MiShortcut')
    if (-not $anchor) { $anchor = $global:window.FindName('MiStyle') }
    if (-not $anchor) { return }
    $panel = $anchor.Parent
    if ($panel -isnot [System.Windows.Controls.Panel]) { return }

    $b = New-Object System.Windows.Controls.Border
    $b.Name = 'MiCustomGames'
    $b.Background = [System.Windows.Media.Brushes]::Transparent
    $b.CornerRadius = [System.Windows.CornerRadius]::new(7)
    $b.Padding = [System.Windows.Thickness]::new(8, 9, 8, 9)
    $b.Cursor = [System.Windows.Input.Cursors]::Hand
    $row = New-Object System.Windows.Controls.StackPanel
    $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $dot = New-Object System.Windows.Shapes.Ellipse
    $dot.Width = 8; $dot.Height = 8
    $dot.Fill = New-CgBrush '#9a6ad8'
    $dot.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $dot.Margin = [System.Windows.Thickness]::new(2, 0, 11, 0)
    $col = New-Object System.Windows.Controls.StackPanel
    $t1 = New-Object System.Windows.Controls.TextBlock
    $t1.Text = 'My Games (Beta)'; $t1.FontSize = 13
    $t1.Foreground = New-CgBrush '#d8dee3'
    $t1.FontFamily = New-Object System.Windows.Media.FontFamily 'Segoe UI'
    $t2 = New-Object System.Windows.Controls.TextBlock
    $t2.FontSize = 11
    $t2.Foreground = New-CgBrush '#6a6a7e'
    $t2.FontFamily = New-Object System.Windows.Media.FontFamily 'Segoe UI'
    $t2.Margin = [System.Windows.Thickness]::new(0, 2, 0, 0)
    [void]$col.Children.Add($t1); [void]$col.Children.Add($t2)
    [void]$row.Children.Add($dot); [void]$row.Children.Add($col)
    $b.Child = $row
    $hover = New-CgBrush '#1e1e2a'
    $b.Add_MouseEnter({ $this.Background = $hover }.GetNewClosure())
    $b.Add_MouseLeave({ $this.Background = [System.Windows.Media.Brushes]::Transparent })
    $b.Add_MouseLeftButtonUp({ param($s, $e)
        $e.Handled = $true
        $indicatorToken = Start-HubActionIndicator -Target $s
        try {
            $on = -not (Test-CustomGamesEnabled)
            Set-HubSetting -Key 'customGamesEnabled' -Value $on
            Write-CustomGamesTrace ("enabled -> {0}" -f $on)
            if ($on) { Install-CustomGamesSections } else { Remove-CustomGamesSections }
            Update-CustomGamesMenuItem
        } catch {
            try { Write-HubActionFailure -Action 'Turn My Games on or off' -ErrorRecord $_ } catch { }
        } finally { Stop-HubActionIndicator -Token $indicatorToken }
    })
    $panel.Children.Insert($panel.Children.IndexOf($anchor) + 1, $b)
    $global:CustomGamesMenuSub = $t2
    if ($global:menuOverlay) {
        $global:menuOverlay.Add_IsVisibleChanged({ try { if ($global:menuOverlay.IsVisible) { Update-CustomGamesMenuItem } } catch { } })
    }
    Update-CustomGamesMenuItem
}

# ---------------------------------------------------------------
# Sections
# ---------------------------------------------------------------
function global:New-CustomGamesChip {
    param([string]$Text, [string]$Tip)
    $chip = New-Object System.Windows.Controls.Border
    $chip.Background = New-CgBrush '#1a1a22'
    $chip.CornerRadius = [System.Windows.CornerRadius]::new(3)
    $chip.BorderThickness = [System.Windows.Thickness]::new(1)
    $chip.BorderBrush = New-CgBrush '#3a3a48'
    $chip.Padding = [System.Windows.Thickness]::new(9, 4, 9, 4)
    $chip.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
    $chip.Cursor = [System.Windows.Input.Cursors]::Hand
    $chip.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    if ($Tip) { $chip.ToolTip = $Tip }
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.FontSize = 10.5; $tb.FontWeight = [System.Windows.FontWeights]::SemiBold
    $tb.Foreground = New-CgBrush '#cccccc'
    $tb.FontFamily = New-Object System.Windows.Media.FontFamily 'Segoe UI'
    $chip.Child = $tb
    $chip.Add_MouseEnter({ $this.BorderBrush = New-CgBrush '#9a6ad8' })
    $chip.Add_MouseLeave({ $this.BorderBrush = New-CgBrush '#3a3a48' })
    return $chip
}

function global:New-CustomGamesSection {
    param([ValidateSet('Library', 'List')][string]$Context)
    $root = New-Object System.Windows.Controls.StackPanel
    $root.Name = "CustomGamesSection$Context"
    $root.Margin = if ($Context -eq 'Library') { [System.Windows.Thickness]::new(0, 0, 0, 22) } else { [System.Windows.Thickness]::new(0, 0, 0, 18) }

    $headerRow = New-Object System.Windows.Controls.StackPanel
    $headerRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $headerRow.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)

    $pill = New-Object System.Windows.Controls.Border
    $pill.CornerRadius = [System.Windows.CornerRadius]::new(11)
    $pill.Background = New-CgBrush '#0dffffff'
    $pill.BorderThickness = [System.Windows.Thickness]::new(1)
    $pill.BorderBrush = New-CgBrush '#22ffffff'
    $pill.Padding = [System.Windows.Thickness]::new(10, 6, 10, 6)
    $pill.Cursor = [System.Windows.Input.Cursors]::Hand
    $pill.ToolTip = 'Click to collapse / expand'
    $pillRow = New-Object System.Windows.Controls.StackPanel
    $pillRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $icon = New-Object System.Windows.Shapes.Path
    # Gamepad-ish glyph
    $icon.Data = [System.Windows.Media.Geometry]::Parse('M6,8 H18 A4,4 0 0 1 22,12 V14 A3,3 0 0 1 16.5,15.5 L15,14 H9 L7.5,15.5 A3,3 0 0 1 2,14 V12 A4,4 0 0 1 6,8 Z M6,10.5 V13.5 M4.5,12 H7.5')
    $icon.Stroke = New-CgBrush '#9a6ad8'
    $icon.StrokeThickness = 1.6
    $icon.Width = 16; $icon.Height = 12
    $icon.Stretch = [System.Windows.Media.Stretch]::Uniform
    $icon.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
    $icon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = 'My Games'
    $title.FontSize = 13; $title.FontWeight = [System.Windows.FontWeights]::SemiBold
    $title.Foreground = [System.Windows.Media.Brushes]::White
    $title.FontFamily = New-Object System.Windows.Media.FontFamily 'Segoe UI'
    $title.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $badge = New-Object System.Windows.Controls.Border
    $badge.MinWidth = 22; $badge.Height = 22
    $badge.CornerRadius = [System.Windows.CornerRadius]::new(11)
    $badge.Background = New-CgBrush '#2b2146'
    $badge.BorderThickness = [System.Windows.Thickness]::new(1)
    $badge.BorderBrush = New-CgBrush '#9a6ad8'
    $badge.Margin = [System.Windows.Thickness]::new(9, 0, 0, 0)
    $badge.Padding = [System.Windows.Thickness]::new(5, 0, 5, 0)
    $count = New-Object System.Windows.Controls.TextBlock
    $count.Text = '0'
    $count.FontSize = 11; $count.FontWeight = [System.Windows.FontWeights]::Bold
    $count.Foreground = New-CgBrush '#dccbff'
    $count.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $count.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $badge.Child = $count
    $sub = New-Object System.Windows.Controls.TextBlock
    $sub.Text = ('click to launch  {0}  right-click to edit' -f [char]0x00B7)
    $sub.FontSize = 11; $sub.FontWeight = [System.Windows.FontWeights]::Medium
    $sub.Foreground = New-CgBrush '#8a7aa8'
    $sub.Margin = [System.Windows.Thickness]::new(16, 0, 0, 0)
    $sub.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    [void]$pillRow.Children.Add($icon); [void]$pillRow.Children.Add($title)
    [void]$pillRow.Children.Add($badge); [void]$pillRow.Children.Add($sub)
    $pill.Child = $pillRow

    $add = New-CustomGamesChip -Text '+ Add game' -Tip 'Add any game: a Steam game, a program (.exe) or a launcher link'
    $import = New-CustomGamesChip -Text 'Import from Steam' -Tip 'Pick installed Steam games to add in one go'
    $add.Add_MouseLeftButtonUp({ param($s, $e) $e.Handled = $true; Show-CustomGameEditor -Game $null })
    $import.Add_MouseLeftButtonUp({ param($s, $e) $e.Handled = $true; Show-SteamImportDialog })

    [void]$headerRow.Children.Add($pill)
    [void]$headerRow.Children.Add($add)
    [void]$headerRow.Children.Add($import)

    $wrap = New-Object System.Windows.Controls.WrapPanel
    $wrap.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $wrap.HorizontalAlignment = if ($Context -eq 'Library') { [System.Windows.HorizontalAlignment]::Center } else { [System.Windows.HorizontalAlignment]::Left }

    $wrapCap = $wrap
    $pill.Add_MouseLeftButtonUp({ param($s, $e)
        $e.Handled = $true
        $collapsed = -not [bool](Get-HubSetting -Key 'customGamesCollapsed' -Default $false)
        try { Set-HubSetting -Key 'customGamesCollapsed' -Value $collapsed } catch { }
        foreach ($sec in @($global:CustomGamesSections.Values)) {
            if ($sec -and $sec.Panel) {
                $sec.Panel.Visibility = if ($collapsed) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
            }
        }
    }.GetNewClosure())

    [void]$root.Children.Add($headerRow)
    [void]$root.Children.Add($wrap)
    return [pscustomobject]@{ Context = $Context; Root = $root; Panel = $wrap; Count = $count }
}

function global:Install-CustomGamesSections {
    if (-not $global:window) { return }
    if (-not $global:CustomGamesSections) { $global:CustomGamesSections = @{} }

    # Library: directly below the featured banner, above the portrait grid.
    if (-not $global:CustomGamesSections['Library']) {
        $libBanner = $global:window.FindName('LibBanner')
        if ($libBanner -and $libBanner.Parent -is [System.Windows.Controls.Panel]) {
            $sec = New-CustomGamesSection -Context 'Library'
            $p = $libBanner.Parent
            $p.Children.Insert($p.Children.IndexOf($libBanner) + 1, $sec.Root)
            $global:CustomGamesSections['Library'] = $sec
        } else { Write-CustomGamesTrace 'LibBanner not found - no Library section' }
    }
    # List: directly below Recently Played, above "Custom Installers".
    if (-not $global:CustomGamesSections['List']) {
        $recent = $global:window.FindName('RecentlyPlayedSection')
        if ($recent -and $recent.Parent -is [System.Windows.Controls.Panel]) {
            $sec = New-CustomGamesSection -Context 'List'
            $p = $recent.Parent
            $p.Children.Insert($p.Children.IndexOf($recent) + 1, $sec.Root)
            $global:CustomGamesSections['List'] = $sec
        } else { Write-CustomGamesTrace 'RecentlyPlayedSection not found - no List section' }
    }
    Update-CustomGamesSections
}

function global:Remove-CustomGamesSections {
    if (-not $global:CustomGamesSections) { return }
    foreach ($key in @($global:CustomGamesSections.Keys)) {
        $sec = $global:CustomGamesSections[$key]
        try {
            if ($sec -and $sec.Root -and $sec.Root.Parent -is [System.Windows.Controls.Panel]) {
                [void]$sec.Root.Parent.Children.Remove($sec.Root)
            }
        } catch { }
    }
    $global:CustomGamesSections = @{}
}

function global:Get-CustomGamesTileSize {
    param([string]$Context)
    if ($Context -eq 'Library') {
        # 70 % of the Library portrait size (S/M/L), so the row stays a
        # compact launcher strip above the Hub's own catalog.
        $key = if ($global:DiscoverTileSize) { $global:DiscoverTileSize } else { 'L' }
        $dim = $null
        try { $dim = $global:DiscoverTileSizes[$key] } catch { }
        if (-not $dim) { $dim = @{ W = 250; H = 375 } }
        return @{ W = [int]($dim.W * 0.7); H = [int]($dim.H * 0.7) }
    }
    # List: same sizing rule as the Recently Played row.
    $f = switch ($global:SCALE) { 1.5 { 4.0 / 3.0 } 2.0 { 16.0 / 9.0 } default { 1.0 } }
    return @{ W = [int](108 * $f); H = [int](154 * $f) }
}

function global:Test-CustomGameMatchesSearch {
    param($Game, [string]$Query)
    if ([string]::IsNullOrWhiteSpace($Query)) { return $true }
    $title = [string]$Game.title
    foreach ($word in ($Query.Trim() -split '\s+')) {
        if (-not $word) { continue }
        if ($word -in @('favorites', 'favorite')) {
            if (-not (Test-GameFavorite -Game $Game)) { return $false }
            continue
        }
        if ($word.StartsWith('-') -and $word.Length -gt 1) {
            if ($title.IndexOf($word.Substring(1), [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $false }
        } elseif ($title.IndexOf($word, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
            return $false
        }
    }
    return $true
}

function global:Update-CustomGamesSearch {
    $q = ''
    try { if ($global:CustomGamesSearchBox) { $q = [string]$global:CustomGamesSearchBox.Text } } catch { }
    foreach ($sec in @($global:CustomGamesSections.Values)) {
        if (-not $sec) { continue }
        $visible = 0
        foreach ($child in @($sec.Panel.Children)) {
            $g = $child.Tag
            if ($g -is [string]) {
                # action tiles: only without a search
                $child.Visibility = if ($q.Trim()) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
                continue
            }
            $show = Test-CustomGameMatchesSearch -Game $g -Query $q
            $child.Visibility = if ($show) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
            if ($show) { $visible++ }
        }
        # Whole section disappears when a search matches none of the user's games.
        $sec.Root.Visibility = if ($q.Trim() -and $visible -eq 0) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    }
}

function global:Update-CustomGamesSections {
    if (-not $global:CustomGamesSections -or $global:CustomGamesSections.Count -eq 0) { return }
    $games = @(Get-CustomGamesSorted -Games @(Read-CustomGames))
    if ($global:CustomGamesLoadError) { Write-CustomGamesTrace $global:CustomGamesLoadError }
    $collapsed = $false
    try { $collapsed = [bool](Get-HubSetting -Key 'customGamesCollapsed' -Default $false) } catch { }
    foreach ($sec in @($global:CustomGamesSections.Values)) {
        if (-not $sec) { continue }
        $sec.Panel.Children.Clear()
        $sec.Count.Text = [string]$games.Count
        $dim = Get-CustomGamesTileSize -Context $sec.Context
        foreach ($g in $games) {
            try { [void]$sec.Panel.Children.Add((New-CustomGameTile -Game $g -W $dim.W -H $dim.H)) }
            catch { Write-CustomGamesTrace ("tile failed for {0}: {1}" -f $g.title, $_.Exception.Message) }
        }
        [void]$sec.Panel.Children.Add((New-CustomGamesActionTile -Kind 'add' -W $dim.W -H $dim.H))
        [void]$sec.Panel.Children.Add((New-CustomGamesActionTile -Kind 'steam' -W $dim.W -H $dim.H))
        $sec.Panel.Visibility = if ($collapsed) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    }
    Update-CustomGamesSearch
    $global:CustomGamesBuiltSizeSig = Get-CustomGamesSizeSig
}

function global:Get-CustomGamesSizeSig {
    return ('{0}|{1}' -f $global:DiscoverTileSize, $global:SCALE)
}

# ---------------------------------------------------------------
# Tiles
# ---------------------------------------------------------------
function global:New-CustomGamesActionTile {
    param([ValidateSet('add', 'steam')][string]$Kind, [int]$W, [int]$H)
    $tile = New-Object System.Windows.Controls.Border
    $tile.Tag = "action:$Kind"
    $tile.Width = $W; $tile.Height = $H
    $tile.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $tile.Margin = [System.Windows.Thickness]::new(0, 0, 10, 10)
    $tile.Background = New-CgBrush '#0cffffff'
    $tile.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $tile.BorderBrush = New-CgBrush '#3a3550'
    $tile.Cursor = [System.Windows.Input.Cursors]::Hand
    $stack = New-Object System.Windows.Controls.StackPanel
    $stack.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $stack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $big = New-Object System.Windows.Controls.TextBlock
    $big.Text = if ($Kind -eq 'add') { '+' } else { [string][char]0x21E9 }
    $big.FontSize = [Math]::Max(26, [int]($W / 4))
    $big.Foreground = New-CgBrush '#9a6ad8'
    $big.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = if ($Kind -eq 'add') { 'Add game' } else { 'Import from Steam' }
    $label.FontSize = 12; $label.FontWeight = [System.Windows.FontWeights]::SemiBold
    $label.Foreground = New-CgBrush '#c9c2dc'
    $label.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $label.TextAlignment = [System.Windows.TextAlignment]::Center
    $label.Margin = [System.Windows.Thickness]::new(8, 2, 8, 0)
    [void]$stack.Children.Add($big); [void]$stack.Children.Add($label)
    $tile.Child = $stack
    $tile.Add_MouseEnter({ $this.BorderBrush = New-CgBrush '#9a6ad8'; $this.Background = New-CgBrush '#169a6ad8' })
    $tile.Add_MouseLeave({ $this.BorderBrush = New-CgBrush '#3a3550'; $this.Background = New-CgBrush '#0cffffff' })
    if ($Kind -eq 'add') {
        $tile.Add_MouseLeftButtonUp({ param($s, $e) $e.Handled = $true; Show-CustomGameEditor -Game $null })
    } else {
        $tile.Add_MouseLeftButtonUp({ param($s, $e) $e.Handled = $true; Show-SteamImportDialog })
    }
    return $tile
}

function global:New-CustomGameTile {
    param($Game, [int]$W, [int]$H)
    $accent = Get-CustomGameAccent $Game
    $missing = ((Get-CustomGameAvailability $Game) -eq 'missing')

    $tile = New-Object System.Windows.Controls.Border
    $tile.Tag = $Game
    $tile.Width = $W; $tile.Height = $H
    $tile.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $tile.Margin = [System.Windows.Thickness]::new(0, 0, 10, 10)
    $tile.BorderThickness = [System.Windows.Thickness]::new(1)
    $tile.BorderBrush = New-CgBrush '#2a2a35'
    $tile.Cursor = [System.Windows.Input.Cursors]::Hand
    $tile.ClipToBounds = $true
    $tip = $Game.title
    switch ($Game.launchType) {
        'steam' { $tip += "`nSteam game (App ID $($Game.steamAppId))" }
        'uri'   { $tip += "`n$($Game.uri)" }
        default { $tip += "`n$($Game.exePath)" }
    }
    if ($Game.lastPlayed) { $tip += "`nLast played: $($Game.lastPlayed.Replace('T', ' '))" }
    if ($missing) { $tip += "`nProgram not found - right-click > Edit" }
    $tile.ToolTip = $tip

    # Generated title card underneath everything - it is what remains
    # when no artwork loads at all.
    $grad = New-Object System.Windows.Media.LinearGradientBrush
    $grad.StartPoint = [System.Windows.Point]::new(0, 0)
    $grad.EndPoint = [System.Windows.Point]::new(1, 1)
    $c = [System.Windows.Media.ColorConverter]::ConvertFromString($accent)
    [void]$grad.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(150, $c.R, $c.G, $c.B), 0))
    [void]$grad.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromRgb(18, 18, 26), 1))
    $tile.Background = $grad

    $grid = New-Object System.Windows.Controls.Grid

    $card = New-Object System.Windows.Controls.StackPanel
    $card.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $card.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $iconPath = Resolve-CustomGameArtPath $Game.icon
    if ($iconPath) {
        try {
            $ico = New-Object System.Windows.Controls.Image
            $bi = New-Object System.Windows.Media.Imaging.BitmapImage
            $bi.BeginInit(); $bi.UriSource = [Uri]::new($iconPath); $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad; $bi.EndInit()
            $ico.Source = $bi
            $ico.Width = [Math]::Min(48, [int]($W / 3)); $ico.Height = $ico.Width
            $ico.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
            [void]$card.Children.Add($ico)
        } catch { }
    }
    $name = New-Object System.Windows.Controls.TextBlock
    $name.Text = $Game.title
    $name.FontSize = [Math]::Max(12, [int]($W / 11))
    $name.FontWeight = [System.Windows.FontWeights]::SemiBold
    $name.Foreground = [System.Windows.Media.Brushes]::White
    $name.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $name.TextAlignment = [System.Windows.TextAlignment]::Center
    $name.Margin = [System.Windows.Thickness]::new(10, 0, 10, 0)
    [void]$card.Children.Add($name)
    [void]$grid.Children.Add($card)

    $img = New-Object System.Windows.Controls.Image
    $img.Stretch = [System.Windows.Media.Stretch]::UniformToFill
    [void]$grid.Children.Add($img)
    $urls = @(Get-CustomGameArtUris -Game $Game -Kind 'portrait')
    # A wide picture still beats a plain card when no portrait exists.
    $urls += @(Get-CustomGameArtUris -Game $Game -Kind 'wide')
    if ($urls.Count -gt 0 -and (Get-Command Set-SafeBannerImage -ErrorAction SilentlyContinue)) {
        try { Set-SafeBannerImage -ImageEl $img -Urls $urls -TitleEl $card } catch { }
    }

    # Small type chip, top-left.
    $chip = New-Object System.Windows.Controls.Border
    $chip.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $chip.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    $chip.Margin = [System.Windows.Thickness]::new(6)
    $chip.Padding = [System.Windows.Thickness]::new(5, 1, 5, 1)
    $chip.CornerRadius = [System.Windows.CornerRadius]::new(3)
    $chip.Background = if ($missing) { New-CgBrush '#cc8a2020' } else { New-CgBrush '#b0101018' }
    $chipText = New-Object System.Windows.Controls.TextBlock
    $chipText.FontSize = 9; $chipText.FontWeight = [System.Windows.FontWeights]::Bold
    $chipText.Foreground = New-CgBrush '#e8e0ff'
    $chipText.Text = if ($missing) { 'MISSING' } else { switch ($Game.launchType) { 'steam' { 'STEAM' } 'uri' { 'LINK' } default { 'EXE' } } }
    $chip.Child = $chipText
    [void]$grid.Children.Add($chip)

    # Hover overlay with a play glyph.
    $overlay = New-Object System.Windows.Controls.Border
    $overlay.Background = New-CgBrush '#66000000'
    $overlay.Visibility = [System.Windows.Visibility]::Collapsed
    $overlay.IsHitTestVisible = $false
    $play = New-Object System.Windows.Shapes.Path
    $play.Data = [System.Windows.Media.Geometry]::Parse('M 0,0 L 11,7 L 0,14 Z')
    $play.Fill = [System.Windows.Media.Brushes]::White
    $play.Width = [Math]::Max(22, [int]($W / 6)); $play.Height = $play.Width * 1.25
    $play.Stretch = [System.Windows.Media.Stretch]::Uniform
    $play.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $play.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $overlay.Child = $play
    [void]$grid.Children.Add($overlay)

    # Keep the same favorite marker visible in both My Games layouts.
    $favoriteHeart = [System.Windows.Controls.TextBlock]::new()
    $favoriteHeart.Text = [string][char]0x2665
    $favoriteHeart.FontFamily = [System.Windows.Media.FontFamily]::new('Segoe UI Symbol')
    $favoriteHeart.FontSize = [Math]::Max(17, [int]($W / 9))
    $favoriteHeart.Foreground = New-CgBrush '#ff5b91'
    $favoriteHeart.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $favoriteHeart.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
    $favoriteHeart.Margin = [System.Windows.Thickness]::new(0, 0, 9, 7)
    $favoriteHeart.IsHitTestVisible = $false
    $favoriteHeart.Visibility = if (Test-GameFavorite -Game $Game) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    [System.Windows.Controls.Panel]::SetZIndex($favoriteHeart, 15)
    [void]$grid.Children.Add($favoriteHeart)
    $tile.Resources['customFavoriteHeart'] = $favoriteHeart

    if ($missing) { $grid.Opacity = 0.55 }
    $tile.Child = $grid

    $accentBrush = New-CgBrush $accent
    $overlayCap = $overlay
    $tile.Add_MouseEnter({ $this.BorderBrush = $accentBrush; $overlayCap.Visibility = [System.Windows.Visibility]::Visible }.GetNewClosure())
    $tile.Add_MouseLeave({ $this.BorderBrush = New-CgBrush '#2a2a35'; $overlayCap.Visibility = [System.Windows.Visibility]::Collapsed }.GetNewClosure())

    $id = [string]$Game.id
    $tile.Add_MouseLeftButtonUp({ param($s, $e) $e.Handled = $true; Invoke-CustomGameLaunch -Id $id }.GetNewClosure())
    $tile.ContextMenu = New-CustomGameContextMenu -Game $Game
    return $tile
}

function global:New-CustomGameContextMenu {
    param($Game)
    $id = [string]$Game.id
    $menu = New-Object System.Windows.Controls.ContextMenu
    $add = {
        param($header, [scriptblock]$action)
        $mi = New-Object System.Windows.Controls.MenuItem
        $mi.Header = $header
        $mi.Add_Click($action)
        [void]$menu.Items.Add($mi)
    }
    & $add 'Play' ({ Invoke-CustomGameLaunch -Id $id }.GetNewClosure())
    $favoriteItem = [System.Windows.Controls.MenuItem]::new()
    $favoriteItem.Header = ([string][char]0x2665 + ' Favorite')
    $favoriteItem.Tag = 'favorite-toggle'
    $favoriteItem.IsCheckable = $true
    $favoriteItem.IsChecked = [bool](Test-GameFavorite -Game $Game)
    $favoriteGame = $Game
    $favoriteItem.Add_Click({
        param($sender, $eventArgs)
        Set-CustomGameFavorite -Game $favoriteGame -Favorite ([bool]$sender.IsChecked)
    }.GetNewClosure())
    [void]$menu.Items.Add($favoriteItem)
    & $add 'Edit...' ({ Show-CustomGameEditor -Game (Get-CustomGame -Id $id) }.GetNewClosure())
    & $add 'Change picture...' ({ Set-CustomGamePictureInteractive -Id $id }.GetNewClosure())
    [void]$menu.Items.Add((New-Object System.Windows.Controls.Separator))
    & $add 'Open game folder' ({ Open-CustomGameFolder -Id $id }.GetNewClosure())
    if ($Game.steamAppId) {
        $appId = [string]$Game.steamAppId
        & $add 'Open Steam store page' ({ try { Start-Process ("steam://store/{0}" -f $appId) } catch { } }.GetNewClosure())
    }
    [void]$menu.Items.Add((New-Object System.Windows.Controls.Separator))
    & $add 'Remove from My Games' ({
        $g = Get-CustomGame -Id $id
        if (-not $g) { return }
        $r = Show-CustomGamesMessage -Text ("Remove ""{0}"" from My Games?`n`nOnly the Hub entry and its picture are removed. The game itself stays installed." -f $g.title) -Buttons ([System.Windows.MessageBoxButton]::YesNo) -Icon ([System.Windows.MessageBoxImage]::Question)
        if ($r -ne [System.Windows.MessageBoxResult]::Yes) { return }
        try {
            if (Remove-CustomGame -Id $id) {
                if (Test-GameFavorite -Game $g) { [void](Set-GameFavorite -Game $g -Favorite $false) }
                Write-CustomGamesTrace ("removed {0}" -f $id)
            }
        } catch { Write-HubActionFailure -Action 'Remove game from My Games' -ErrorRecord $_ }
        Update-CustomGamesSections
    }.GetNewClosure())
    return $menu
}

function global:Set-CustomGameFavorite {
    param($Game, [bool]$Favorite)
    if (-not $Game -or -not $Game.id) { return }
    try {
        [void](Set-GameFavorite -Game $Game -Favorite $Favorite)
        Sync-CustomGameFavoriteTiles -GameId ([string]$Game.id)
    } catch {
        Write-HubActionFailure -Action ("Mark {0} as favorite" -f $Game.title) -ErrorRecord $_
    }
}

function global:Sync-CustomGameFavoriteTiles {
    param([string]$GameId)
    if (-not $global:CustomGamesSections) { return }
    foreach ($sec in @($global:CustomGamesSections.Values)) {
        if (-not $sec -or -not $sec.Panel) { continue }
        $tiles = @{}
        $games = @()
        foreach ($child in @($sec.Panel.Children)) {
            $game = $child.Tag
            if (-not $game -or $game -is [string]) { continue }
            $key = [string]$game.id
            $tiles[$key] = $child
            $games += $game
            if ($key -ne $GameId) { continue }
            $marked = [bool](Test-GameFavorite -Game $game)
            $heart = $child.Resources.Item('customFavoriteHeart')
            if ($heart) { $heart.Visibility = if ($marked) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed } }
            foreach ($item in @($child.ContextMenu.Items)) {
                if ($item -is [System.Windows.Controls.MenuItem] -and $item.Tag -eq 'favorite-toggle') { $item.IsChecked = $marked }
            }
        }
        $index = 0
        foreach ($game in @(Get-CustomGamesSorted -Games $games)) {
            $tile = $tiles[[string]$game.id]
            $old = $sec.Panel.Children.IndexOf($tile)
            if ($old -ne $index) {
                [void]$sec.Panel.Children.Remove($tile)
                $sec.Panel.Children.Insert($index, $tile)
            }
            $index++
        }
    }
    Update-CustomGamesSearch
}

# ---------------------------------------------------------------
# Actions
# ---------------------------------------------------------------
function global:Invoke-CustomGameLaunch {
    param([string]$Id)
    $g = Get-CustomGame -Id $Id
    if (-not $g) { return }
    $plan = Resolve-CustomGameLaunch -Game $g
    Write-CustomGamesTrace ("launch {0} kind={1} target={2} error={3}" -f $g.title, $plan.Kind, $plan.FilePath, $plan.Error)
    if ($plan.Error) {
        $r = Show-CustomGamesMessage -Text ("{0}`n`n{1}`n`nEdit the entry now?" -f $g.title, $plan.Error) -Buttons ([System.Windows.MessageBoxButton]::YesNo) -Icon ([System.Windows.MessageBoxImage]::Warning)
        if ($r -eq [System.Windows.MessageBoxResult]::Yes) { Show-CustomGameEditor -Game $g }
        return
    }
    try {
        if ($plan.Kind -eq 'uri') {
            Start-Process $plan.FilePath
        } else {
            $sp = @{ FilePath = $plan.FilePath }
            if ($plan.Arguments) { $sp['ArgumentList'] = $plan.Arguments }
            if ($plan.WorkingDirectory) { $sp['WorkingDirectory'] = $plan.WorkingDirectory }
            if ($plan.RunAsAdmin) { $sp['Verb'] = 'RunAs' }
            Start-Process @sp
        }
    } catch {
        Write-HubActionFailure -Action ("Start {0}" -f $g.title) -ErrorRecord $_
        return
    }
    try { [void](Set-CustomGamePlayed -Id $Id) } catch { }
    try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized } } catch { }
    Update-CustomGamesSections
}

function global:Open-CustomGameFolder {
    param([string]$Id)
    $g = Get-CustomGame -Id $Id
    if (-not $g) { return }
    $dir = $null
    if ($g.launchType -eq 'exe' -and $g.exePath) { $dir = [IO.Path]::GetDirectoryName($g.exePath) }
    if (-not $dir -and $g.steamAppId) {
        $app = @(Get-SteamInstalledApps) | Where-Object { $_.AppId -eq $g.steamAppId } | Select-Object -First 1
        if ($app) { $dir = $app.InstallDir }
    }
    if ($dir -and (Test-Path -LiteralPath $dir -PathType Container)) {
        try { Start-Process explorer.exe -ArgumentList ('"{0}"' -f $dir) } catch { }
    } else {
        [void](Show-CustomGamesMessage -Text 'No local game folder is known for this entry.')
    }
}

function global:Select-CustomGameFile {
    param([string]$Filter, [string]$InitialPath)
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = $Filter
    try {
        if ($InitialPath) {
            $d = if (Test-Path -LiteralPath $InitialPath -PathType Container) { $InitialPath } else { [IO.Path]::GetDirectoryName($InitialPath) }
            if ($d -and (Test-Path -LiteralPath $d -PathType Container)) { $dlg.InitialDirectory = $d }
        }
    } catch { }
    $owner = $global:window
    if ($owner -and $dlg.ShowDialog($owner)) { return $dlg.FileName }
    if (-not $owner -and $dlg.ShowDialog()) { return $dlg.FileName }
    return $null
}

$global:CustomGamesImageFilter = 'Images (*.jpg;*.jpeg;*.png;*.bmp;*.gif)|*.jpg;*.jpeg;*.png;*.bmp;*.gif'

function global:Set-CustomGamePictureInteractive {
    param([string]$Id)
    $g = Get-CustomGame -Id $Id
    if (-not $g) { return }
    $file = Select-CustomGameFile -Filter $global:CustomGamesImageFilter
    if (-not $file) { return }
    try {
        $g.portrait = Import-CustomGameArt -Id $Id -SourcePath $file -Kind 'portrait'
        [void](Save-CustomGame -Game $g -AllowDuplicate)
    } catch {
        [void](Show-CustomGamesMessage -Text $_.Exception.Message -Icon ([System.Windows.MessageBoxImage]::Warning))
        return
    }
    Update-CustomGamesSections
}

# ---------------------------------------------------------------
# Add / edit dialog
# ---------------------------------------------------------------
$global:CustomGamesDialogStyles = @'
<Window.Resources>
    <Style TargetType="TextBlock">
        <Setter Property="Foreground" Value="#c9cbd6"/>
        <Setter Property="FontFamily" Value="Segoe UI"/>
        <Setter Property="FontSize" Value="12"/>
    </Style>
    <Style TargetType="TextBox">
        <Setter Property="Background" Value="#1a1a24"/>
        <Setter Property="Foreground" Value="#ffffff"/>
        <Setter Property="BorderBrush" Value="#34344a"/>
        <Setter Property="CaretBrush" Value="#ffffff"/>
        <Setter Property="Padding" Value="6,4"/>
        <Setter Property="FontSize" Value="12"/>
    </Style>
    <Style TargetType="RadioButton">
        <Setter Property="Foreground" Value="#e0e0ea"/>
        <Setter Property="Margin" Value="0,0,16,0"/>
        <Setter Property="FontSize" Value="12"/>
    </Style>
    <Style TargetType="CheckBox">
        <Setter Property="Foreground" Value="#e0e0ea"/>
        <Setter Property="FontSize" Value="12"/>
    </Style>
    <Style TargetType="Button">
        <Setter Property="Padding" Value="12,4"/>
        <Setter Property="MinWidth" Value="76"/>
        <Setter Property="Background" Value="#262636"/>
        <Setter Property="Foreground" Value="#ffffff"/>
        <Setter Property="BorderBrush" Value="#44445a"/>
    </Style>
</Window.Resources>
'@

function global:Show-CustomGameEditor {
    param($Game)
    $isNew = (-not $Game)
    $rec = if ($isNew) { ConvertTo-CustomGameRecord @{ id = (New-CustomGameId); launchType = 'exe'; source = 'manual' } } else { ConvertTo-CustomGameRecord $Game }

    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="My Games" Width="640" SizeToContent="Height"
        ResizeMode="NoResize" WindowStartupLocation="CenterOwner"
        Background="#101018">
$($global:CustomGamesDialogStyles)
    <Grid Margin="20">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="150"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" Margin="0,0,18,0">
            <TextBlock x:Name="Heading" FontSize="17" FontWeight="SemiBold" Foreground="White" Margin="0,0,0,14"/>

            <TextBlock Text="Name"/>
            <TextBox x:Name="NameBox" Margin="0,3,0,12"/>

            <TextBlock Text="Start with"/>
            <StackPanel Orientation="Horizontal" Margin="0,5,0,12">
                <RadioButton x:Name="RbSteam" Content="Steam game" GroupName="lt"/>
                <RadioButton x:Name="RbExe" Content="Program (.exe)" GroupName="lt"/>
                <RadioButton x:Name="RbUri" Content="Link / other launcher" GroupName="lt"/>
            </StackPanel>

            <StackPanel x:Name="SteamPanel">
                <TextBlock Text="Pick an installed Steam game"/>
                <ComboBox x:Name="SteamPick" Margin="0,3,0,12" IsEditable="False"/>
            </StackPanel>

            <TextBlock x:Name="AppIdLabel" Text="Steam App ID"/>
            <TextBox x:Name="AppIdBox" Margin="0,3,0,12"/>

            <StackPanel x:Name="ExePanel">
                <TextBlock Text="Program"/>
                <DockPanel Margin="0,3,0,12">
                    <Button x:Name="ExeBrowse" Content="Browse..." DockPanel.Dock="Right" Margin="6,0,0,0"/>
                    <TextBox x:Name="ExeBox"/>
                </DockPanel>
                <TextBlock Text="Start in folder (optional - default: the program's folder)"/>
                <DockPanel Margin="0,3,0,12">
                    <Button x:Name="WdBrowse" Content="Browse..." DockPanel.Dock="Right" Margin="6,0,0,0"/>
                    <TextBox x:Name="WdBox"/>
                </DockPanel>
                <CheckBox x:Name="AdminChk" Content="Run as administrator" Margin="0,0,0,12"/>
            </StackPanel>

            <StackPanel x:Name="UriPanel">
                <TextBlock Text="Link"/>
                <TextBox x:Name="UriBox" Margin="0,3,0,3"/>
                <TextBlock Text="e.g. com.epicgames.launcher://apps/...?action=launch  or  goggalaxy://openGameView/..." Foreground="#6a6a7e" FontSize="11" TextWrapping="Wrap" Margin="0,0,0,12"/>
            </StackPanel>

            <StackPanel x:Name="ArgsPanel">
                <TextBlock Text="Launch options (optional)"/>
                <TextBox x:Name="ArgsBox" Margin="0,3,0,12"/>
            </StackPanel>

            <TextBlock Text="Accent colour"/>
            <UniformGrid x:Name="AccentSwatches" Columns="8" Margin="0,5,0,2"/>
            <TextBlock x:Name="AccentChoice" Foreground="#8d8da6" FontSize="11" Margin="0,0,0,12"/>

            <TextBlock x:Name="ErrorText" Foreground="#ff7070" TextWrapping="Wrap" Margin="0,0,0,8" Visibility="Collapsed"/>

            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,6,0,0">
                <Button x:Name="SaveBtn" Content="Save" IsDefault="True"/>
                <Button x:Name="CancelBtn" Content="Cancel" IsCancel="True" Margin="8,0,0,0"/>
            </StackPanel>
        </StackPanel>

        <StackPanel Grid.Column="1">
            <TextBlock Text="Picture" Margin="0,40,0,4"/>
            <Border Width="150" Height="225" CornerRadius="6" Background="#1a1a24" BorderBrush="#34344a" BorderThickness="1" ClipToBounds="True">
                <Grid>
                    <TextBlock x:Name="PreviewHint" Text="Steam artwork is used automatically when a Steam App ID is set." TextWrapping="Wrap" TextAlignment="Center" VerticalAlignment="Center" Margin="10" Foreground="#6a6a7e" FontSize="11"/>
                    <Image x:Name="Preview" Stretch="UniformToFill"/>
                </Grid>
            </Border>
            <Button x:Name="PicBrowse" Content="Choose portrait..." Margin="0,8,0,0"/>
            <Button x:Name="WideBrowse" Content="Choose wide image..." Margin="0,6,0,0"/>
            <Button x:Name="PicClear" Content="Use automatic" Margin="0,6,0,0"/>
            <TextBlock Text="Portrait 600x900 looks best. Pictures are copied into the Hub's data folder." Foreground="#6a6a7e" FontSize="10.5" TextWrapping="Wrap" Margin="0,8,0,0"/>
        </StackPanel>
    </Grid>
</Window>
"@
    $dlg = [Windows.Markup.XamlReader]::Parse($xaml)
    try { if ($global:window) { $dlg.Owner = $global:window } } catch { }
    $f = @{}
    foreach ($n in 'Heading','NameBox','RbSteam','RbExe','RbUri','SteamPanel','SteamPick','AppIdLabel','AppIdBox','ExePanel','ExeBrowse','ExeBox','WdBrowse','WdBox','AdminChk','UriPanel','UriBox','ArgsPanel','ArgsBox','AccentSwatches','AccentChoice','ErrorText','SaveBtn','CancelBtn','PreviewHint','Preview','PicBrowse','WideBrowse','PicClear') {
        $f[$n] = $dlg.FindName($n)
    }
    $f.Heading.Text = if ($isNew) { 'Add a game' } else { 'Edit "' + $rec.title + '"' }
    $f.NameBox.Text = $rec.title
    $f.AppIdBox.Text = $rec.steamAppId
    $f.ExeBox.Text = $rec.exePath
    $f.WdBox.Text = $rec.workingDir
    $f.AdminChk.IsChecked = [bool]$rec.runAsAdmin
    $f.UriBox.Text = $rec.uri
    $f.ArgsBox.Text = $rec.arguments
    # Picture choice lives here until Save: @{ portrait = <stored name or new source path>; ... }
    $state = @{ Rec = $rec; PortraitSource = $null; WideSource = $null; ClearArt = $false; SteamApps = $null; Saved = $null; Accent = $rec.accent }

    $palette = @(
        @{ Name='Automatic'; Hex='' },
        @{ Name='Red'; Hex='#f45b69' }, @{ Name='Orange'; Hex='#ff8a22' },
        @{ Name='Amber'; Hex='#f8bb43' }, @{ Name='Yellow'; Hex='#f3df4d' },
        @{ Name='Lime'; Hex='#8ad85a' }, @{ Name='Green'; Hex='#44cc66' },
        @{ Name='Mint'; Hex='#33d6ad' }, @{ Name='Cyan'; Hex='#36d8ef' },
        @{ Name='Blue'; Hex='#3a8add' }, @{ Name='Indigo'; Hex='#7c5cff' },
        @{ Name='Purple'; Hex='#a46ad8' }, @{ Name='Pink'; Hex='#eb62b5' },
        @{ Name='Burgundy'; Hex='#a33b5a' }, @{ Name='Teal'; Hex='#168f92' },
        @{ Name='Silver'; Hex='#b8c4d6' }
    )
    if ($state.Accent -and -not @($palette | Where-Object { $_.Hex -ieq $state.Accent }).Count) {
        $palette += @{ Name='Current colour'; Hex=$state.Accent }
    }
    $state.Swatches = New-Object System.Collections.ArrayList
    $updateAccent = {
        foreach ($item in $state.Swatches) {
            $item.Button.BorderBrush = if ($item.Hex -ieq $state.Accent) { New-CgBrush '#ffffff' } else { New-CgBrush '#45455a' }
            $item.Button.BorderThickness = if ($item.Hex -ieq $state.Accent) { [System.Windows.Thickness]::new(2) } else { [System.Windows.Thickness]::new(1) }
        }
        $chosen = @($palette | Where-Object { $_.Hex -ieq $state.Accent } | Select-Object -First 1)
        $f.AccentChoice.Text = if ($chosen.Count) { $chosen[0].Name } else { 'Automatic' }
    }.GetNewClosure()
    foreach ($colour in $palette) {
        $button = New-Object System.Windows.Controls.Button
        $button.Width = 34; $button.Height = 26
        $button.Margin = [System.Windows.Thickness]::new(0, 0, 5, 5)
        $button.Padding = [System.Windows.Thickness]::new(0)
        $button.Background = if ($colour.Hex) { New-CgBrush $colour.Hex } else { New-CgBrush '#262636' }
        $button.Content = if ($colour.Hex) { '' } else { 'Auto' }
        $button.FontSize = 9
        if (-not $colour.Hex) {
            $button.HorizontalContentAlignment = [System.Windows.HorizontalAlignment]::Left
            $button.Padding = [System.Windows.Thickness]::new(3,0,0,0)
        }
        $button.ToolTip = $colour.Name
        $hex = [string]$colour.Hex
        $button.Add_Click({ $state.Accent = $hex; & $updateAccent }.GetNewClosure())
        [void]$f.AccentSwatches.Children.Add($button)
        [void]$state.Swatches.Add([pscustomobject]@{ Button=$button; Hex=$hex })
    }
    & $updateAccent

    $refreshPreview = {
        $f.Preview.Source = $null
        $uris = @()
        if ($state.PortraitSource) { $uris += (ConvertTo-CustomGameUri $state.PortraitSource) }
        elseif ($state.WideSource) { $uris += (ConvertTo-CustomGameUri $state.WideSource) }
        else {
            $probe = ConvertTo-CustomGameRecord $state.Rec
            if ($state.ClearArt) { $probe.portrait = ''; $probe.wide = '' }
            $probe.steamAppId = ([string]$f.AppIdBox.Text).Trim()
            $uris += @(Get-CustomGameArtUris -Game $probe -Kind 'portrait')
            $uris += @(Get-CustomGameArtUris -Game $probe -Kind 'wide')
        }
        if ($uris.Count -gt 0 -and (Get-Command Set-SafeBannerImage -ErrorAction SilentlyContinue)) {
            try { Set-SafeBannerImage -ImageEl $f.Preview -Urls $uris -TitleEl $f.PreviewHint } catch { }
        } else {
            $f.PreviewHint.Visibility = [System.Windows.Visibility]::Visible
        }
    }.GetNewClosure()

    $applyType = {
        $t = if ($f.RbSteam.IsChecked) { 'steam' } elseif ($f.RbUri.IsChecked) { 'uri' } else { 'exe' }
        $vis = { param($b) if ($b) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed } }
        $f.SteamPanel.Visibility = & $vis ($t -eq 'steam')
        $f.ExePanel.Visibility = & $vis ($t -eq 'exe')
        $f.UriPanel.Visibility = & $vis ($t -eq 'uri')
        $f.ArgsPanel.Visibility = & $vis ($t -ne 'uri')
        $f.AppIdLabel.Text = if ($t -eq 'steam') { 'Steam App ID' } else { 'Steam App ID (optional - only for artwork)' }
        if ($t -eq 'steam' -and $null -eq $state.SteamApps) {
            $state.SteamApps = @()
            try { $state.SteamApps = @(Get-SteamInstalledApps | Where-Object { -not $_.IsTool }) } catch { }
            [void]$f.SteamPick.Items.Add('(choose)')
            foreach ($a in $state.SteamApps) { [void]$f.SteamPick.Items.Add(('{0}   [{1}]' -f $a.Name, $a.AppId)) }
            $f.SteamPick.SelectedIndex = 0
            if ($state.SteamApps.Count -eq 0) { $f.SteamPick.IsEnabled = $false; $f.SteamPick.Items[0] = '(no installed Steam games found)' }
        }
    }.GetNewClosure()

    switch ($rec.launchType) { 'steam' { $f.RbSteam.IsChecked = $true } 'uri' { $f.RbUri.IsChecked = $true } default { $f.RbExe.IsChecked = $true } }
    foreach ($rb in @($f.RbSteam, $f.RbExe, $f.RbUri)) { $rb.Add_Checked({ & $applyType }.GetNewClosure()) }
    & $applyType

    $f.SteamPick.Add_SelectionChanged({
        $i = $f.SteamPick.SelectedIndex - 1
        if ($i -lt 0 -or $i -ge $state.SteamApps.Count) { return }
        $a = $state.SteamApps[$i]
        $f.AppIdBox.Text = $a.AppId
        if (-not ([string]$f.NameBox.Text).Trim()) { $f.NameBox.Text = $a.Name }
        & $refreshPreview
    }.GetNewClosure())
    $f.AppIdBox.Add_LostFocus({ & $refreshPreview }.GetNewClosure())

    $f.ExeBrowse.Add_Click({
        $file = Select-CustomGameFile -Filter 'Programs (*.exe;*.bat;*.cmd;*.lnk)|*.exe;*.bat;*.cmd;*.lnk|All files (*.*)|*.*' -InitialPath ([string]$f.ExeBox.Text)
        if (-not $file) { return }
        $f.ExeBox.Text = $file
        if (-not ([string]$f.NameBox.Text).Trim()) {
            $nameGuess = $null
            try {
                $vi = [Diagnostics.FileVersionInfo]::GetVersionInfo($file)
                if ($vi.ProductName -and $vi.ProductName.Trim().Length -gt 1) { $nameGuess = $vi.ProductName.Trim() }
            } catch { }
            if (-not $nameGuess) { $nameGuess = [IO.Path]::GetFileNameWithoutExtension($file) }
            $f.NameBox.Text = $nameGuess
        }
    }.GetNewClosure())
    $f.WdBrowse.Add_Click({
        $file = Select-CustomGameFile -Filter 'Any file in the folder|*.*' -InitialPath ([string]$f.ExeBox.Text)
        if ($file) { $f.WdBox.Text = [IO.Path]::GetDirectoryName($file) }
    }.GetNewClosure())
    $f.PicBrowse.Add_Click({
        $file = Select-CustomGameFile -Filter $global:CustomGamesImageFilter
        if ($file) { $state.PortraitSource = $file; $state.ClearArt = $false; & $refreshPreview }
    }.GetNewClosure())
    $f.WideBrowse.Add_Click({
        $file = Select-CustomGameFile -Filter $global:CustomGamesImageFilter
        if ($file) { $state.WideSource = $file; $state.ClearArt = $false; & $refreshPreview }
    }.GetNewClosure())
    $f.PicClear.Add_Click({
        $state.PortraitSource = $null; $state.WideSource = $null; $state.ClearArt = $true; & $refreshPreview
    }.GetNewClosure())

    $f.SaveBtn.Add_Click({
        $r = ConvertTo-CustomGameRecord $state.Rec
        $r.title = ([string]$f.NameBox.Text).Trim()
        $r.launchType = if ($f.RbSteam.IsChecked) { 'steam' } elseif ($f.RbUri.IsChecked) { 'uri' } else { 'exe' }
        $r.steamAppId = ([string]$f.AppIdBox.Text).Trim()
        $r.exePath = ([string]$f.ExeBox.Text).Trim().Trim('"')
        $r.workingDir = ([string]$f.WdBox.Text).Trim().Trim('"')
        $r.runAsAdmin = [bool]$f.AdminChk.IsChecked
        $r.uri = ([string]$f.UriBox.Text).Trim()
        $r.arguments = ([string]$f.ArgsBox.Text).Trim()
        $r.accent = [string]$state.Accent
        # Fields of the other launch types are not kept.
        if ($r.launchType -ne 'exe') { $r.exePath = ''; $r.workingDir = ''; $r.runAsAdmin = $false }
        if ($r.launchType -ne 'uri') { $r.uri = '' } else { $r.arguments = '' }
        $problems = @(Test-CustomGameRecord $r)
        if ($r.launchType -eq 'exe' -and $r.exePath -and -not (Test-Path -LiteralPath $r.exePath -PathType Leaf)) {
            $problems += ('Program not found: {0}' -f $r.exePath)
        }
        if ($problems.Count -gt 0) {
            $f.ErrorText.Text = ($problems -join "`n")
            $f.ErrorText.Visibility = [System.Windows.Visibility]::Visible
            return
        }
        try {
            if ($state.ClearArt) {
                foreach ($k in 'portrait', 'wide') {
                    $p = Resolve-CustomGameArtPath $r.$k
                    if ($p) { try { Remove-Item -LiteralPath $p -Force } catch { } }
                    $r.$k = ''
                }
            }
            if ($state.PortraitSource) { $r.portrait = Import-CustomGameArt -Id $r.id -SourcePath $state.PortraitSource -Kind 'portrait' }
            if ($state.WideSource) { $r.wide = Import-CustomGameArt -Id $r.id -SourcePath $state.WideSource -Kind 'wide' }
            if ($r.launchType -eq 'exe') { $newIcon = [string](Export-CustomGameExeIcon -Id $r.id -ExePath $r.exePath); if ($newIcon) { $r.icon = $newIcon } }
            $state.Saved = Save-CustomGame -Game $r
            Write-CustomGamesTrace ("saved {0} ({1}, {2})" -f $r.title, $r.id, $r.launchType)
            $dlg.DialogResult = $true
        } catch {
            $f.ErrorText.Text = $_.Exception.Message
            $f.ErrorText.Visibility = [System.Windows.Visibility]::Visible
        }
    }.GetNewClosure())

    & $refreshPreview
    [void]$dlg.ShowDialog()
    if ($state.Saved) {
        Update-CustomGamesSections
        Update-CustomGamesMenuItem
    }
    return $state.Saved
}

# ---------------------------------------------------------------
# Steam import dialog
# ---------------------------------------------------------------
function global:Show-SteamImportDialog {
    $apps = @()
    try { $apps = @(Get-SteamInstalledApps) } catch { Write-CustomGamesTrace ("steam scan failed: {0}" -f $_.Exception.Message) }
    if ($apps.Count -eq 0) {
        [void](Show-CustomGamesMessage -Text "No installed Steam games were found.`n`nThe Hub reads Steam's library folders (libraryfolders.vdf) and the appmanifest files in each library. Is Steam installed on this PC?" -Icon ([System.Windows.MessageBoxImage]::Warning))
        return
    }

    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Import from Steam" Width="560" Height="640"
        WindowStartupLocation="CenterOwner" Background="#101018">
$($global:CustomGamesDialogStyles)
    <DockPanel Margin="18">
        <StackPanel DockPanel.Dock="Top">
            <TextBlock Text="Import from Steam" FontSize="17" FontWeight="SemiBold" Foreground="White"/>
            <TextBlock Text="Tick the games to add to My Games. They start through Steam, artwork comes from Steam." Foreground="#8a8a9e" TextWrapping="Wrap" Margin="0,4,0,12"/>
            <DockPanel Margin="0,0,0,8">
                <CheckBox x:Name="ToolsChk" Content="Show tools &amp; runtimes" DockPanel.Dock="Right" VerticalAlignment="Center" Margin="10,0,0,0"/>
                <TextBox x:Name="FilterBox"/>
            </DockPanel>
        </StackPanel>
        <DockPanel DockPanel.Dock="Bottom" Margin="0,12,0,0">
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
                <Button x:Name="ImportBtn" Content="Import" IsDefault="True"/>
                <Button x:Name="CancelBtn" Content="Cancel" IsCancel="True" Margin="8,0,0,0"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal">
                <Button x:Name="AllBtn" Content="Select shown"/>
                <Button x:Name="NoneBtn" Content="Select none" Margin="6,0,0,0"/>
                <TextBlock x:Name="StatusText" VerticalAlignment="Center" Margin="12,0,0,0" Foreground="#8a8a9e"/>
            </StackPanel>
        </DockPanel>
        <Border BorderBrush="#26262e" BorderThickness="1" CornerRadius="4">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel x:Name="ListHost" Margin="8,6,8,6"/>
            </ScrollViewer>
        </Border>
    </DockPanel>
</Window>
"@
    $dlg = [Windows.Markup.XamlReader]::Parse($xaml)
    try { if ($global:window) { $dlg.Owner = $global:window } } catch { }
    $f = @{}
    foreach ($n in 'ToolsChk','FilterBox','ImportBtn','CancelBtn','AllBtn','NoneBtn','StatusText','ListHost') { $f[$n] = $dlg.FindName($n) }

    $rows = @()
    foreach ($a in $apps) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Tag = $a
        $cb.Margin = [System.Windows.Thickness]::new(0, 3, 0, 3)
        $content = New-Object System.Windows.Controls.StackPanel
        $t1 = New-Object System.Windows.Controls.TextBlock
        $t1.Text = $a.Name
        $t1.Foreground = New-CgBrush '#e8e8f0'
        $t1.FontSize = 12.5
        $t2 = New-Object System.Windows.Controls.TextBlock
        $note = "App ID $($a.AppId)"
        if ($a.AlreadyAdded) { $note += ('  {0}  already in My Games' -f [char]0x00B7) }
        elseif ($a.HubTitle) { $note += ('  {0}  has a Hub entry: {1}' -f [char]0x00B7, $a.HubTitle) }
        if ($a.IsTool) { $note += ('  {0}  tool / runtime' -f [char]0x00B7) }
        $t2.Text = $note
        $t2.Foreground = New-CgBrush '#6a6a7e'
        $t2.FontSize = 10.5
        [void]$content.Children.Add($t1); [void]$content.Children.Add($t2)
        $cb.Content = $content
        if ($a.AlreadyAdded) { $cb.IsChecked = $true; $cb.IsEnabled = $false }
        [void]$f.ListHost.Children.Add($cb)
        $rows += $cb
    }

    $updateStatus = {
        $n = @($rows | Where-Object { $_.IsEnabled -and $_.IsChecked }).Count
        $f.StatusText.Text = ('{0} selected' -f $n)
        $f.ImportBtn.Content = if ($n -gt 0) { "Import $n" } else { 'Import' }
        $f.ImportBtn.IsEnabled = ($n -gt 0)
    }.GetNewClosure()
    $applyFilter = {
        $q = ([string]$f.FilterBox.Text).Trim()
        $tools = [bool]$f.ToolsChk.IsChecked
        foreach ($cb in $rows) {
            $a = $cb.Tag
            $show = ($tools -or -not $a.IsTool) -and (-not $q -or $a.Name.IndexOf($q, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or $a.AppId -eq $q)
            $cb.Visibility = if ($show) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
        }
    }.GetNewClosure()
    foreach ($cb in $rows) {
        $cb.Add_Checked({ & $updateStatus }.GetNewClosure())
        $cb.Add_Unchecked({ & $updateStatus }.GetNewClosure())
    }
    $f.FilterBox.Add_TextChanged({ & $applyFilter }.GetNewClosure())
    $f.ToolsChk.Add_Checked({ & $applyFilter }.GetNewClosure())
    $f.ToolsChk.Add_Unchecked({ & $applyFilter }.GetNewClosure())
    $f.AllBtn.Add_Click({
        foreach ($cb in $rows) { if ($cb.IsEnabled -and $cb.Visibility -eq [System.Windows.Visibility]::Visible) { $cb.IsChecked = $true } }
    }.GetNewClosure())
    $f.NoneBtn.Add_Click({ foreach ($cb in $rows) { if ($cb.IsEnabled) { $cb.IsChecked = $false } } }.GetNewClosure())
    $result = @{ Added = 0 }
    $f.ImportBtn.Add_Click({
        $picked = @($rows | Where-Object { $_.IsEnabled -and $_.IsChecked } | ForEach-Object { $_.Tag })
        try {
            $result.Added = Import-SteamAppsAsCustomGames -Apps $picked
            Write-CustomGamesTrace ("steam import: {0} picked, {1} added" -f $picked.Count, $result.Added)
            $dlg.DialogResult = $true
        } catch {
            Write-HubActionFailure -Action 'Import Steam games into My Games' -ErrorRecord $_
        }
    }.GetNewClosure())

    & $applyFilter
    & $updateStatus
    [void]$dlg.ShowDialog()
    if ($result.Added -gt 0) {
        Update-CustomGamesSections
        Update-CustomGamesMenuItem
    }
}

# ---------------------------------------------------------------
# Wiring
# ---------------------------------------------------------------
try {
    # Catalog arrays live in VRModHub.ps1's script scope; keep a reference
    # while it is in reach (used only to mark "has a Hub entry" on import).
    $global:CustomGamesCatalogGames = @($ownGames) + @($ownGamesGP) + @($externalGames)
    Add-CustomGamesMenuItem
    $global:CustomGamesSearchBox = $global:window.FindName('SearchBox')
    if ($global:CustomGamesSearchBox) {
        $global:CustomGamesSearchBox.Add_TextChanged({ try { Update-CustomGamesSearch } catch { } })
    }
    # Built after the first frame, so the feature never delays startup.
    $global:window.Add_ContentRendered({
        try {
            if (Test-CustomGamesEnabled) {
                $global:window.Dispatcher.BeginInvoke(
                    [System.Windows.Threading.DispatcherPriority]::Background,
                    [Action]{ try { Install-CustomGamesSections } catch { Write-CustomGamesTrace ("install failed: {0}" -f $_.Exception.Message) } }
                ) | Out-Null
            }
        } catch { }
    })
    # Follow S/M/L tile-size changes: rebuild when a section becomes visible
    # again (view switch) or the size signature changed.
    $global:CustomGamesSizeTimer = New-Object System.Windows.Threading.DispatcherTimer
    $global:CustomGamesSizeTimer.Interval = [TimeSpan]::FromMilliseconds(700)
    $global:CustomGamesSizeTimer.Add_Tick({
        try {
            if ($global:CustomGamesSections -and $global:CustomGamesSections.Count -gt 0 -and
                (Get-CustomGamesSizeSig) -ne $global:CustomGamesBuiltSizeSig) {
                Update-CustomGamesSections
            }
        } catch { }
    })
    $global:CustomGamesSizeTimer.Start()
    Write-CustomGamesTrace ("ready, enabled={0}" -f (Test-CustomGamesEnabled))
} catch {
    Write-CustomGamesTrace ("wiring failed: {0}" -f $_.Exception.Message)
}
