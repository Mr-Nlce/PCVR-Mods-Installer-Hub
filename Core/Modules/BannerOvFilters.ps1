# ---------------------------------------------------------------
# Banner hover-close: after dwelling on a banner for 5 seconds,
# show a small Close + Always-disable overlay top-right. Close
# hides the banner for this session; Always disable persists
# the choice to the durable Hub state so the banner stays hidden
# on future launches.
# ---------------------------------------------------------------
function global:Setup-BannerHoverClose {
    param(
        $Banner,
        $Overlay,
        $CloseBtn,
        $DisableBtn,
        [string]$SettingKey
    )
    if (-not $Banner -or -not $Overlay -or -not $CloseBtn -or -not $DisableBtn) { return }

    $showTimer = New-Object System.Windows.Threading.DispatcherTimer
    $showTimer.Interval = [TimeSpan]::FromSeconds(5)
    $hideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $hideTimer.Interval = [TimeSpan]::FromMilliseconds(800)

    $showTimer.Add_Tick({
        $showTimer.Stop()
        $Overlay.Visibility = [System.Windows.Visibility]::Visible
    }.GetNewClosure())

    $hideTimer.Add_Tick({
        $hideTimer.Stop()
        $Overlay.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())

    $Banner.Add_MouseEnter({
        $hideTimer.Stop()
        if ($Overlay.Visibility -ne [System.Windows.Visibility]::Visible) {
            $showTimer.Stop()
            $showTimer.Start()
        }
    }.GetNewClosure())

    $Banner.Add_MouseLeave({
        $showTimer.Stop()
        if ($Overlay.Visibility -eq [System.Windows.Visibility]::Visible) {
            $hideTimer.Stop()
            $hideTimer.Start()
        }
    }.GetNewClosure())

    # Close = hide for this session only
    $CloseBtn.Add_MouseLeftButtonUp({
        $Banner.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())
    $CloseBtn.Add_MouseEnter({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") })
    $CloseBtn.Add_MouseLeave({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48") })

    # Always disable = hide + persist
    $DisableBtn.Add_MouseLeftButtonUp({
        $Banner.Visibility = [System.Windows.Visibility]::Collapsed
        if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
            Set-HubSetting -Key $SettingKey -Value $true
        }
    }.GetNewClosure())
    $DisableBtn.Add_MouseEnter({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") })
    $DisableBtn.Add_MouseLeave({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48") })
}

# Filter chip - bigger, bolder, with a colored left accent bar
# so the genre pills feel more like editorial features and
# less like flat radio buttons.


function global:New-OvFilterChip {
    param(
        [string]$Label,
        [string]$Key,
        [bool]$IsActive,
        [string]$AccentColor = "#dd6600",
        $IconGeometry = $null
    )

    # Size tracks the Explore S/M/L setting so the chips grow and shrink
    # with the rest of the Explore view. The M values match the original
    # fixed design exactly, so M looks identical to before.
    $szKey = if ($global:ExploreSize) { $global:ExploreSize } else { "M" }
    $sz = switch ($szKey) {
        "S"     { @{ Font = 11.0; Icon = 13; Corner = 5; Bar = 4; MinH = 26; LblL = 11; LblLIcon = 7; LblR = 12; LblV = 5; IconL = 10 } }
        "L"     { @{ Font = 12.5; Icon = 15; Corner = 6; Bar = 5; MinH = 30; LblL = 13; LblLIcon = 8; LblR = 14; LblV = 6; IconL = 12 } }
        default { @{ Font = 12.0; Icon = 14; Corner = 5; Bar = 4; MinH = 28; LblL = 12; LblLIcon = 7; LblR = 13; LblV = 5; IconL = 11 } }
    }

    $chip = New-Object System.Windows.Controls.Border
    $chip.CornerRadius = [System.Windows.CornerRadius]::new($sz.Corner)
    $chip.Padding = [System.Windows.Thickness]::new(0)
    $chip.Margin = [System.Windows.Thickness]::new(0, 0, 8, 8)
    $chip.Cursor = [System.Windows.Input.Cursors]::Hand
    $chip.BorderThickness = [System.Windows.Thickness]::new(1)
    if ($IsActive) {
        $chip.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a1a08")
        $chip.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentColor)
    } else {
        $chip.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161a")
        $chip.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
    }

    # Inner grid: colored accent bar on left + optional icon + label.
    $inner = New-Object System.Windows.Controls.Grid
    $inner.MinHeight = $sz.MinH
    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = New-Object System.Windows.GridLength $sz.Bar
    $inner.ColumnDefinitions.Add($col1) | Out-Null

    if ($IconGeometry) {
        $colIcon = New-Object System.Windows.Controls.ColumnDefinition
        $colIcon.Width = [System.Windows.GridLength]::Auto
        $inner.ColumnDefinitions.Add($colIcon) | Out-Null
    }

    $colLbl = New-Object System.Windows.Controls.ColumnDefinition
    $colLbl.Width = [System.Windows.GridLength]::Auto
    $inner.ColumnDefinitions.Add($colLbl) | Out-Null

    $accentBar = New-Object System.Windows.Shapes.Rectangle
    $accentBar.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentColor)
    [System.Windows.Controls.Grid]::SetColumn($accentBar, 0)
    $inner.Children.Add($accentBar) | Out-Null

    $iconPath = $null
    if ($IconGeometry) {
        $iconPath = New-Object System.Windows.Shapes.Path
        $iconPath.Data = $IconGeometry
        $iconPath.StrokeThickness    = 1.5
        $iconPath.StrokeLineJoin     = [System.Windows.Media.PenLineJoin]::Round
        $iconPath.StrokeStartLineCap = [System.Windows.Media.PenLineCap]::Round
        $iconPath.StrokeEndLineCap   = [System.Windows.Media.PenLineCap]::Round
        $iconPath.Width   = $sz.Icon
        $iconPath.Height  = $sz.Icon
        $iconPath.Stretch = [System.Windows.Media.Stretch]::Uniform
        $iconPath.SnapsToDevicePixels = $true
        $iconPath.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
        $iconPath.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $iconPath.Margin = [System.Windows.Thickness]::new($sz.IconL, 0, 0, 0)
        if ($IsActive) {
            $iconPath.Stroke = [System.Windows.Media.Brushes]::White
        } else {
            $iconPath.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentColor)
        }
        [System.Windows.Controls.Grid]::SetColumn($iconPath, 1)
        $inner.Children.Add($iconPath) | Out-Null
    }

    $txt = New-Object System.Windows.Controls.TextBlock
    $txt.Text = $Label.ToUpper()
    $txt.FontSize = $sz.Font
    $txt.FontWeight = [System.Windows.FontWeights]::Bold
    $txt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    if ($iconPath) {
        $txt.Margin = [System.Windows.Thickness]::new($sz.LblLIcon, $sz.LblV, $sz.LblR, $sz.LblV)
    } else {
        $txt.Margin = [System.Windows.Thickness]::new($sz.LblL, $sz.LblV, $sz.LblR, $sz.LblV)
    }
    $txt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    if ($IsActive) {
        $txt.Foreground = [System.Windows.Media.Brushes]::White
    } else {
        $txt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#bbbbbb")
    }
    $lblColIdx = if ($iconPath) { 2 } else { 1 }
    [System.Windows.Controls.Grid]::SetColumn($txt, $lblColIdx)
    $inner.Children.Add($txt) | Out-Null

    $chip.Child = $inner

    $chip.Resources.Add("filterKey", $Key)
    $chip.Resources.Add("filterText", $txt)
    $chip.Resources.Add("filterAccent", $AccentColor)
    if ($iconPath) {
        $chip.Resources.Add("filterIcon", $iconPath)
    }

    # Soft glow hover - border + text brighten on enter, restore on leave.
    Add-GlowHover -Border $chip -AccentHex $AccentColor
    return $chip
}

function global:Update-OvFilterChips {
    param($ChipPanel, [string]$ActiveKey)
    if (-not $ChipPanel) { return }
    foreach ($chip in $ChipPanel.Children) {
        # The power panel also carries the GPU rating controls at the end
        # of the row. They are not filter chips and have no filterKey, so
        # skip them - otherwise the else-branch below would repaint them
        # in chip colours every time the selection changes.
        if (-not $chip.Resources.Contains("filterKey")) { continue }
        # Genre cards (Explore genre grid) carry their own visual
        # state - background, border, glow and scale - so they are
        # repainted by their own helper instead of the chip colours.
        if ($chip.Resources.Contains("genreCard")) {
            Set-OvGenreCardState -Card $chip -Active ($chip.Resources.Item("filterKey") -eq $ActiveKey)
            continue
        }
        # Same for the segments of the joined PC POWER bar.
        if ($chip.Resources.Contains("powerSeg")) {
            Set-OvPowerSegState -Seg $chip -Active ($chip.Resources.Item("filterKey") -eq $ActiveKey)
            continue
        }
        $key  = $chip.Resources.Item("filterKey")
        $txt  = $chip.Resources.Item("filterText")
        $acc  = $chip.Resources.Item("filterAccent")
        $icon = $null
        if ($chip.Resources.Contains("filterIcon")) {
            $icon = $chip.Resources.Item("filterIcon")
        }
        if ($key -eq $ActiveKey) {
            $chip.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a1a08")
            $chip.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($acc)
            if ($txt)  { $txt.Foreground = [System.Windows.Media.Brushes]::White }
            if ($icon) { $icon.Stroke    = [System.Windows.Media.Brushes]::White }
        } else {
            $chip.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161a")
            $chip.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
            if ($txt)  { $txt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#bbbbbb") }
            if ($icon) { $icon.Stroke    = [System.Windows.Media.BrushConverter]::new().ConvertFromString($acc) }
        }
        # Drop any glow-hover stashes so a pending MouseLeave restore
        # can't clobber what we just set.
        if ($chip.Resources.Contains("ghBdBrush")) {
            $chip.Resources.Remove("ghBdBrush") | Out-Null
        }
        if ($txt -and $txt.Resources.Contains("ghFg")) {
            $txt.Resources.Remove("ghFg") | Out-Null
        }
    }
}

# ---------------------------------------------------------------
# Explore genre CARDS - large clickable tiles (icon on top, short
# label below) laid out in a UniformGrid: one row of 10 when the
# window is wide enough, two even rows of 5 when it is not.
# The power filter keeps using New-OvFilterChip unchanged.
# ---------------------------------------------------------------

# Short card labels. The genre rows further down keep the full
# names from $global:OverviewGenres; the full name is the tooltip.
$global:OvGenreCardLabels = @{
    "ALL"       = "All"
    "HORROR"    = "Horror"
    "ACTION"    = "Action"
    "ADVENTURE" = "Adventure"
    "RPG"       = "RPG"
    "COOP"      = "Co-op"
    "PUZZLE"    = "Puzzle"
    "SIM"       = "Sim & racing"
    "FREE"      = "Free"
    "NEW"       = "New"
}

# Card metrics per Explore S/M/L. MinCard = narrowest card width
# that still allows a single row; MaxRow = widest the whole grid may
# grow so cards do not turn into wide slabs on ultrawides.
function global:Get-OvGenreCardMetrics {
    param([string]$Size)
    if (-not $Size) { $Size = if ($global:ExploreSize) { $global:ExploreSize } else { "M" } }
    switch ($Size) {
        "S"     { return @{ H = 60; Icon = 18; IconGap = 7; Font = 11.5; Corner = 10; Gap = 8;  MinCard = 96;  MaxRow = 1300; Glow = 14 } }
        "L"     { return @{ H = 84; Icon = 24; IconGap = 9; Font = 13.5; Corner = 12; Gap = 10; MinCard = 120; MaxRow = 1700; Glow = 20 } }
        default { return @{ H = 72; Icon = 21; IconGap = 8; Font = 12.5; Corner = 11; Gap = 9;  MinCard = 108; MaxRow = 1500; Glow = 17 } }
    }
}

# Accent colour with an alpha (0..1) - for the selection ring.
function global:Get-OvAccentBrush {
    param([string]$AccentHex, [double]$Alpha = 1.0)
    $c = [System.Windows.Media.ColorConverter]::ConvertFromString($AccentHex)
    $a = [byte][Math]::Max(0, [Math]::Min(255, [Math]::Round(255 * $Alpha)))
    return New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb($a, $c.R, $c.G, $c.B))
}

# Pure layout rule (no WPF): all cards in one row when each card
# gets at least MinCard px, otherwise two rows (half rounded up).
# Width <= 0 means "not laid out yet" and keeps the single row;
# the SizeChanged hook corrects it on the first real layout pass.
function global:Get-OvGenreCardColumns {
    param([double]$Width, [string]$Size, [int]$Count = 10)
    if ($Count -lt 1) { return 1 }
    if ($Width -le 0) { return $Count }
    $m = Get-OvGenreCardMetrics -Size $Size
    if (($Width / $Count) -ge $m.MinCard) { return $Count }
    return [int][Math]::Ceiling($Count / 2.0)
}

# Mix an accent into the card ground (#141419) - solid result, so
# the card never shows the page through a translucent fill.
function global:Get-OvGenreCardTint {
    param([string]$AccentHex, [double]$Amount = 0.18)
    $a = [System.Windows.Media.ColorConverter]::ConvertFromString($AccentHex)
    $b = [System.Windows.Media.ColorConverter]::ConvertFromString("#141419")
    $mix = { param($x, $y) [byte][Math]::Round($y + ($x - $y) * $Amount) }
    $c = [System.Windows.Media.Color]::FromRgb((& $mix $a.R $b.R), (& $mix $a.G $b.G), (& $mix $a.B $b.B))
    return New-Object System.Windows.Media.SolidColorBrush $c
}

# Bright accents (FREE green, NEW blue, PUZZLE yellow, SIM green ...)
# would light up as a big glowing blob at the same strength as the dark
# reds/oranges. Damp tint, border and glow by perceived brightness:
# factor = 0.24 / relative luminance, clamped to 0.45..1.0 (0.24 is
# the Hub orange #dd6600, so orange/red/purple keep full strength).
function global:Get-OvGenreCardGlowFactor {
    param([string]$AccentHex)
    $h = ([string]$AccentHex).TrimStart('#')
    if ($h.Length -ne 6) { return 1.0 }
    $lin = {
        param([int]$v)
        $c = $v / 255.0
        if ($c -le 0.04045) { return $c / 12.92 }
        return [Math]::Pow(($c + 0.055) / 1.055, 2.4)
    }
    $r = & $lin ([Convert]::ToInt32($h.Substring(0, 2), 16))
    $g = & $lin ([Convert]::ToInt32($h.Substring(2, 2), 16))
    $b = & $lin ([Convert]::ToInt32($h.Substring(4, 2), 16))
    $lum = 0.2126 * $r + 0.7152 * $g + 0.0722 * $b
    if ($lum -le 0) { return 1.0 }
    return [Math]::Max(0.45, [Math]::Min(1.0, 0.24 / $lum))
}

function global:Start-OvGenreCardAnim {
    param($Target, $Property, [double]$To, [int]$Ms, $From = $null, $Ease = $null)
    if (-not $Target) { return }
    $an = New-Object System.Windows.Media.Animation.DoubleAnimation
    $an.To = $To
    if ($null -ne $From) { $an.From = [double]$From }
    $an.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($Ms))
    if (-not $Ease) {
        $Ease = New-Object System.Windows.Media.Animation.CubicEase
        $Ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
    }
    $an.EasingFunction = $Ease
    $Target.BeginAnimation($Property, $an)
}

# Paint a card for its resting state. SELECTED works like the header
# type pills (Motion Controls): no colour fill - dark ground, bright edge
# in the genre colour, a soft ring outside it and a glow hugging the
# edge. Bright colours are damped by glowFactor. Clears a running glow
# animation first so the state always wins.
function global:Set-OvGenreCardState {
    param($Card, [bool]$Active)
    if (-not $Card) { return }
    $bc     = [System.Windows.Media.BrushConverter]::new()
    $border = $Card.Resources.Item("cardBorder")
    $ring   = $Card.Resources.Item("cardRing")
    $txt    = $Card.Resources.Item("filterText")
    $acc    = $Card.Resources.Item("filterAccent")
    $fx     = $Card.Resources.Item("cardGlow")
    $f      = [double]$Card.Resources.Item("glowFactor")
    $Card.Resources.Item("cardState").Active = $Active
    $border.Background = $bc.ConvertFromString("#141419")
    if ($Active) {
        $border.BorderBrush = Get-OvGenreCardTint -AccentHex $acc -Amount (0.55 + 0.45 * $f)
        $ring.BorderBrush   = Get-OvAccentBrush -AccentHex $acc -Alpha (0.35 + 0.25 * $f)
        $ring.Visibility    = [System.Windows.Visibility]::Visible
        $txt.Foreground     = [System.Windows.Media.Brushes]::White
    } else {
        $border.BorderBrush = $bc.ConvertFromString("#23232b")
        $ring.Visibility    = [System.Windows.Visibility]::Collapsed
        $txt.Foreground     = $bc.ConvertFromString("#c4c4cc")
    }
    if ($fx) {
        $fx.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $null)
        $fx.Opacity = if ($Active) { 0.5 * $f } else { 0.0 }
    }
}

function global:New-OvGenreCard {
    param(
        [string]$Label,
        [string]$Key,
        [bool]$IsActive,
        [string]$AccentColor = "#dd6600",
        $IconGeometry = $null
    )
    $sz = Get-OvGenreCardMetrics
    $bc = [System.Windows.Media.BrushConverter]::new()
    $accColor = [System.Windows.Media.ColorConverter]::ConvertFromString($AccentColor)

    # Root grid = what the UniformGrid lays out. Layers, back to front:
    # glow (its drop shadow hugs the edge when selected), the visible
    # card, and the selection ring just outside the card edge. The
    # shadow never blurs the label text.
    $root = New-Object System.Windows.Controls.Grid
    $root.Height = $sz.H
    $root.Margin = [System.Windows.Thickness]::new(0, 0, $sz.Gap, $sz.Gap)
    $root.Cursor = [System.Windows.Input.Cursors]::Hand
    $root.Background = [System.Windows.Media.Brushes]::Transparent
    $root.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
    $cardScale = New-Object System.Windows.Media.ScaleTransform 1.0, 1.0
    $root.RenderTransform = $cardScale

    $glowLayer = New-Object System.Windows.Controls.Border
    $glowLayer.CornerRadius = [System.Windows.CornerRadius]::new($sz.Corner)
    $glowLayer.Background = $bc.ConvertFromString("#141419")
    $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $glow.Color = $accColor
    $glow.ShadowDepth = 0
    $glow.BlurRadius = $sz.Glow
    $glow.Opacity = 0.0
    $glowLayer.Effect = $glow
    $root.Children.Add($glowLayer) | Out-Null

    $card = New-Object System.Windows.Controls.Border
    $card.CornerRadius = [System.Windows.CornerRadius]::new($sz.Corner)
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.Padding = [System.Windows.Thickness]::new(6, 0, 6, 0)
    $root.Children.Add($card) | Out-Null

    $ring = New-Object System.Windows.Controls.Border
    $ring.Margin = [System.Windows.Thickness]::new(-2)
    $ring.CornerRadius = [System.Windows.CornerRadius]::new($sz.Corner + 2)
    $ring.BorderThickness = [System.Windows.Thickness]::new(2)
    $ring.IsHitTestVisible = $false
    $ring.Visibility = [System.Windows.Visibility]::Collapsed
    $root.Children.Add($ring) | Out-Null

    $stack = New-Object System.Windows.Controls.StackPanel
    $stack.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $stack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

    $iconScale = New-Object System.Windows.Media.ScaleTransform 1.0, 1.0
    $iconPath = $null
    if ($IconGeometry) {
        $iconPath = New-Object System.Windows.Shapes.Path
        $iconPath.Data = $IconGeometry
        $iconPath.Stroke = $bc.ConvertFromString($AccentColor)
        $iconPath.StrokeThickness    = 1.6
        $iconPath.StrokeLineJoin     = [System.Windows.Media.PenLineJoin]::Round
        $iconPath.StrokeStartLineCap = [System.Windows.Media.PenLineCap]::Round
        $iconPath.StrokeEndLineCap   = [System.Windows.Media.PenLineCap]::Round
        $iconPath.Width   = $sz.Icon
        $iconPath.Height  = $sz.Icon
        $iconPath.Stretch = [System.Windows.Media.Stretch]::Uniform
        $iconPath.SnapsToDevicePixels = $true
        $iconPath.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $iconPath.Margin = [System.Windows.Thickness]::new(0, 0, 0, $sz.IconGap)
        $iconPath.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
        $iconPath.RenderTransform = $iconScale
        $stack.Children.Add($iconPath) | Out-Null
    }

    $txt = New-Object System.Windows.Controls.TextBlock
    $txt.Text = $Label
    $txt.FontSize = $sz.Font
    $txt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $txt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $txt.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis
    $txt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $stack.Children.Add($txt) | Out-Null
    $card.Child = $stack

    # Same resource keys as New-OvFilterChip, plus the card parts.
    $root.Resources.Add("filterKey", $Key)
    $root.Resources.Add("filterText", $txt)
    $root.Resources.Add("filterAccent", $AccentColor)
    if ($iconPath) { $root.Resources.Add("filterIcon", $iconPath) }
    $root.Resources.Add("genreCard", $true)
    $root.Resources.Add("glowFactor", (Get-OvGenreCardGlowFactor -AccentHex $AccentColor))
    $root.Resources.Add("cardBorder", $card)
    $root.Resources.Add("cardRing", $ring)
    $root.Resources.Add("cardGlow", $glow)
    $root.Resources.Add("cardScale", $cardScale)
    $root.Resources.Add("iconScale", $iconScale)
    $root.Resources.Add("cardState", @{ Active = $IsActive; Pressed = $false })

    Set-OvGenreCardState -Card $root -Active $IsActive

    $sxP = [System.Windows.Media.ScaleTransform]::ScaleXProperty
    $syP = [System.Windows.Media.ScaleTransform]::ScaleYProperty
    $opP = [System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty

    # HOVER (deliberately quiet, no colour): lifted ground, lighter
    # neutral edge, white label, icon pops 15 %. On the selected card
    # only the glow brightens a little.
    $root.Add_MouseEnter({
        $st  = $this.Resources.Item("cardState")
        $brd = $this.Resources.Item("cardBorder")
        $bcv = [System.Windows.Media.BrushConverter]::new()
        if ($st.Active) {
            Start-OvGenreCardAnim -Target $this.Resources.Item("cardGlow") -Property $opP `
                -To (0.7 * [double]$this.Resources.Item("glowFactor")) -Ms 160
        } else {
            $brd.Background  = $bcv.ConvertFromString("#1b1b22")
            $brd.BorderBrush = $bcv.ConvertFromString("#4a4a56")
        }
        $this.Resources.Item("filterText").Foreground = [System.Windows.Media.Brushes]::White
        $ic = $this.Resources.Item("iconScale")
        Start-OvGenreCardAnim -Target $ic -Property $sxP -To 1.15 -Ms 160
        Start-OvGenreCardAnim -Target $ic -Property $syP -To 1.15 -Ms 160
    }.GetNewClosure())

    # LEAVE: always restores everything, no early exit - colours via
    # Set-OvGenreCardState, then glow/scales ease back from wherever
    # they were (also cancels a press that never got its button-up).
    $root.Add_MouseLeave({
        $st = $this.Resources.Item("cardState")
        $st.Pressed = $false
        $fx = $this.Resources.Item("cardGlow")
        $cur = $fx.Opacity
        Set-OvGenreCardState -Card $this -Active $st.Active
        $rest = $fx.Opacity
        Start-OvGenreCardAnim -Target $fx -Property $opP -From $cur -To $rest -Ms 220
        $ic = $this.Resources.Item("iconScale")
        Start-OvGenreCardAnim -Target $ic -Property $sxP -To 1.0 -Ms 180
        Start-OvGenreCardAnim -Target $ic -Property $syP -To 1.0 -Ms 180
        $cs = $this.Resources.Item("cardScale")
        Start-OvGenreCardAnim -Target $cs -Property $sxP -To 1.0 -Ms 180
        Start-OvGenreCardAnim -Target $cs -Property $syP -To 1.0 -Ms 180
    }.GetNewClosure())

    # PRESS: card sinks to 95 %.
    $root.Add_MouseLeftButtonDown({
        $this.Resources.Item("cardState").Pressed = $true
        $cs = $this.Resources.Item("cardScale")
        Start-OvGenreCardAnim -Target $cs -Property $sxP -To 0.95 -Ms 80
        Start-OvGenreCardAnim -Target $cs -Property $syP -To 0.95 -Ms 80
    }.GetNewClosure())

    return $root
}

# Width + column count of the genre grid. The grid is capped at
# MaxRow and left-aligned; the column rule is Get-OvGenreCardColumns.
function global:Update-OvGenreCardLayout {
    param($Panel)
    if (-not $Panel) { return }
    $parent = $Panel.Parent
    if (-not $parent -or $parent.ActualWidth -le 0) { return }
    $m = Get-OvGenreCardMetrics
    $w = [Math]::Min($parent.ActualWidth, $m.MaxRow)
    if ($w -le 0) { return }
    # Every card carries a Gap margin right and below. The panel is
    # Gap wider with a -Gap right margin so the last card ends flush
    # with the row, and the bottom margin is trimmed by the same Gap.
    $Panel.Margin = [System.Windows.Thickness]::new(0, 0, -$m.Gap, [Math]::Max(0, 12 - $m.Gap))
    $Panel.Width = $w + $m.Gap
    $cols = Get-OvGenreCardColumns -Width $w -Count $Panel.Children.Count
    if ($Panel.Columns -ne $cols) { $Panel.Columns = $cols }
}

# Genre accent colors - one ramp per bucket so the chips feel
# personal rather than uniform orange. Kept as a flat key->color
# map so external callers (e.g. Set-OvBannerForActiveGenre and
# Power-filter chip construction) stay drop-in compatible. Icon
# shapes are built programmatically in New-OvGenreIcon below.
$global:OvGenreColors = @{
    "ALL"       = "#dd6600"
    "HORROR"    = "#cc3344"
    "ACTION"    = "#dd6600"
    "ADVENTURE" = "#44aa88"
    "RPG"       = "#aa66dd"
    "COOP"      = "#44aadd"
    "PUZZLE"    = "#dd9922"
    "SIM"       = "#88aa44"
    "FREE"      = "#34D399"
    "NEW"       = "#38BDF8"
}

# Genre icons. Built programmatically as Geometry objects -
# combining EllipseGeometry/LineGeometry/RectangleGeometry inside
# a GeometryGroup. Avoids the Path Mini-Language parser entirely,
# which silently produced empty geometries in this PowerShell
# host. All shapes live inside a 16x16 viewbox and scale to the
# Path's Width/Height via Stretch=Uniform.
function global:New-OvGenreIcon {
    param([string]$Key)

    $g = New-Object System.Windows.Media.GeometryGroup
    $g.FillRule = [System.Windows.Media.FillRule]::Nonzero

    $addRect = {
        param($x, $y, $w, $h)
        $r = New-Object System.Windows.Media.RectangleGeometry
        $r.Rect = New-Object System.Windows.Rect $x, $y, $w, $h
        $g.Children.Add($r) | Out-Null
    }
    $addLine = {
        param($x1, $y1, $x2, $y2)
        $l = New-Object System.Windows.Media.LineGeometry
        $l.StartPoint = New-Object System.Windows.Point $x1, $y1
        $l.EndPoint   = New-Object System.Windows.Point $x2, $y2
        $g.Children.Add($l) | Out-Null
    }
    $addEllipse = {
        param($cx, $cy, $rx, $ry)
        $e = New-Object System.Windows.Media.EllipseGeometry
        $e.Center = New-Object System.Windows.Point $cx, $cy
        $e.RadiusX = $rx
        $e.RadiusY = $ry
        $g.Children.Add($e) | Out-Null
    }

    switch ($Key) {
        "ALL" {
            # 2x2 grid of small squares
            & $addRect 2 2 5 5
            & $addRect 9 2 5 5
            & $addRect 2 9 5 5
            & $addRect 9 9 5 5
        }
        "HORROR" {
            # Tombstone: rounded-top stone + cross inset. Reads as
            # "RIP / horror" cleanly - earlier ghost-with-eyes
            # version was reading as a smiley emoji.
            # Stone outline as a single PathGeometry: vertical sides
            # + arc top.
            $stone = New-Object System.Windows.Media.PathGeometry
            $fig = New-Object System.Windows.Media.PathFigure
            $fig.StartPoint = New-Object System.Windows.Point 3, 14
            $fig.IsClosed = $true
            $l1 = New-Object System.Windows.Media.LineSegment
            $l1.Point = New-Object System.Windows.Point 3, 6
            $fig.Segments.Add($l1) | Out-Null
            $arc = New-Object System.Windows.Media.ArcSegment
            $arc.Point = New-Object System.Windows.Point 13, 6
            $arc.Size  = New-Object System.Windows.Size 5, 4
            $arc.SweepDirection = [System.Windows.Media.SweepDirection]::Clockwise
            $arc.IsLargeArc = $false
            $arc.IsStroked  = $true
            $fig.Segments.Add($arc) | Out-Null
            $l2 = New-Object System.Windows.Media.LineSegment
            $l2.Point = New-Object System.Windows.Point 13, 14
            $fig.Segments.Add($l2) | Out-Null
            $stone.Figures.Add($fig) | Out-Null
            $g.Children.Add($stone) | Out-Null
            # Cross inset (vertical longer, horizontal shorter)
            & $addLine 8 6 8 12
            & $addLine 5.5 8.5 10.5 8.5
        }
        "ACTION" {
            # Crosshair: outer circle + 4 ticks + center dot
            & $addEllipse 8 8 5 5
            & $addLine 8 1 8 4
            & $addLine 8 12 8 15
            & $addLine 1 8 4 8
            & $addLine 12 8 15 8
            & $addEllipse 8 8 0.8 0.8
        }
        "ADVENTURE" {
            # Pine tree: 3 stacked triangle layers + small trunk.
            # Unambiguous wilderness/adventure symbol that reads
            # clearly even in 16x16. Earlier compass/map/flag/peak
            # attempts were too easily confused with other shapes.
            $tree = New-Object System.Windows.Media.PathGeometry
            $fig = New-Object System.Windows.Media.PathFigure
            $fig.StartPoint = New-Object System.Windows.Point 8, 1.5
            $fig.IsClosed = $true
            # Down-left to first layer bottom
            $segs = @(
                @(4, 6), @(6, 6),
                @(3, 9.5), @(5.5, 9.5),
                @(2.5, 13), @(13.5, 13),
                @(10.5, 9.5), @(13, 9.5),
                @(10, 6), @(12, 6)
            )
            foreach ($pt in $segs) {
                $seg = New-Object System.Windows.Media.LineSegment
                $seg.Point = New-Object System.Windows.Point $pt[0], $pt[1]
                $fig.Segments.Add($seg) | Out-Null
            }
            $tree.Figures.Add($fig) | Out-Null
            $g.Children.Add($tree) | Out-Null
            # Trunk
            & $addRect 7 13 2 1.5
        }
        "RPG" {
            # Sword: vertical blade + horizontal crossguard + pommel
            & $addLine 8 2 8 11
            & $addLine 5 5 11 5
            & $addLine 6 13 10 13
            & $addLine 8 11 8 14
        }
        "COOP" {
            # Two distinct person silhouettes (head + shoulders),
            # clearly separated. Earlier "two heads + shared
            # shoulders curve" was reading as one frowning face.
            # Person 1 (left)
            & $addEllipse 4.5 5 2 2
            & $addRect 1.5 8 6 6
            # Person 2 (right)
            & $addEllipse 11.5 5 2 2
            & $addRect 8.5 8 6 6
        }
        "PUZZLE" {
            # Simpler puzzle piece: square with circular bump on the
            # right side
            & $addRect 2 4 8 8
            & $addEllipse 11 8 2 2
        }
        "SIM" {
            # Steering wheel: outer ring + inner hub + 4 spokes
            & $addEllipse 8 8 6 6
            & $addEllipse 8 8 1.8 1.8
            & $addLine 8 2 8 6.2
            & $addLine 8 9.8 8 14
            & $addLine 2 8 6.2 8
            & $addLine 9.8 8 14 8
        }
        "FREE" {
            # Gift box: lid + body + a vertical ribbon down the
            # front + a two-loop bow on top. Reads as "free gift"
            # and pairs with the green FREE accent.
            & $addRect 2.6 5 10.8 2.6     # lid
            & $addRect 3.6 7.6 8.8 5.8    # body
            & $addLine 8 5 8 13.4         # ribbon down the front
            # Bow: two Bezier loops meeting at the knot (8,5).
            $bow = New-Object System.Windows.Media.PathGeometry
            $lf = New-Object System.Windows.Media.PathFigure
            $lf.StartPoint = New-Object System.Windows.Point 8, 5
            $lf.IsClosed = $true
            $lb1 = New-Object System.Windows.Media.BezierSegment
            $lb1.Point1 = New-Object System.Windows.Point 6.4, 2.4
            $lb1.Point2 = New-Object System.Windows.Point 3.6, 3
            $lb1.Point3 = New-Object System.Windows.Point 4.6, 4.6
            $lf.Segments.Add($lb1) | Out-Null
            $lb2 = New-Object System.Windows.Media.BezierSegment
            $lb2.Point1 = New-Object System.Windows.Point 5.2, 5.4
            $lb2.Point2 = New-Object System.Windows.Point 6.8, 5
            $lb2.Point3 = New-Object System.Windows.Point 8, 5
            $lf.Segments.Add($lb2) | Out-Null
            $bow.Figures.Add($lf) | Out-Null
            $rf = New-Object System.Windows.Media.PathFigure
            $rf.StartPoint = New-Object System.Windows.Point 8, 5
            $rf.IsClosed = $true
            $rb1 = New-Object System.Windows.Media.BezierSegment
            $rb1.Point1 = New-Object System.Windows.Point 9.6, 2.4
            $rb1.Point2 = New-Object System.Windows.Point 12.4, 3
            $rb1.Point3 = New-Object System.Windows.Point 11.4, 4.6
            $rf.Segments.Add($rb1) | Out-Null
            $rb2 = New-Object System.Windows.Media.BezierSegment
            $rb2.Point1 = New-Object System.Windows.Point 10.8, 5.4
            $rb2.Point2 = New-Object System.Windows.Point 9.2, 5
            $rb2.Point3 = New-Object System.Windows.Point 8, 5
            $rf.Segments.Add($rb2) | Out-Null
            $bow.Figures.Add($rf) | Out-Null
            $g.Children.Add($bow) | Out-Null
        }
        "NEW" {
            # Two clean sparkle crosses: instantly reads as fresh/new at the
            # same small size as the other line icons.
            & $addLine 8 1.5 8 10.5
            & $addLine 3.5 6 12.5 6
            & $addLine 12.5 10.5 12.5 14.5
            & $addLine 10.5 12.5 14.5 12.5
        }
    }

    return $g
}

function global:Build-OvGenreFilter {
    $panel = $window.FindName("OvGenreFilter")
    if (-not $panel) { return }
    $panel.Children.Clear()

    $chips = @(@{ Key="ALL"; Label="All" })
    foreach ($g in $global:OverviewGenres) {
        $chips += @{ Key=$g.Key; Label=$g.Label }
    }
    # FREE and NEW are cross-genre shortcuts. NEW deliberately comes
    # immediately after FREE and uses the same rolling title list as search.
    $chips += @{ Key="FREE"; Label="Free" }
    $chips += @{ Key="NEW"; Label="New" }
    foreach ($c in $chips) {
        $accent = $global:OvGenreColors[$c.Key]
        if (-not $accent) { $accent = "#dd6600" }
        # Build the matching icon geometry from .NET primitives.
        # Returns $null for unknown keys; chip falls back to a
        # label-only layout in that case.
        $iconGeo = $null
        try {
            $iconGeo = New-OvGenreIcon -Key $c.Key
        } catch {
            $iconGeo = $null
        }
        $cardLabel = $global:OvGenreCardLabels[$c.Key]
        if (-not $cardLabel) { $cardLabel = $c.Label }
        $chip = New-OvGenreCard -Label $cardLabel -Key $c.Key `
                                -IsActive ($c.Key -eq "ALL") `
                                -AccentColor $accent `
                                -IconGeometry $iconGeo
        if ($c.Key -eq 'NEW') {
            $chip.ToolTip = 'Added to the Hub during the last 10.5 days'
        } elseif ($cardLabel -ne $c.Label) {
            $chip.ToolTip = $c.Label
        }
        $keyCap = $c.Key
        $chip.Add_MouseLeftButtonUp({
            # Only a press that started on this card counts as a click.
            $st = $this.Resources.Item("cardState")
            if (-not $st.Pressed) { return }
            $st.Pressed = $false
            $global:OvActiveGenre = $keyCap
            Update-OvFilterChips -ChipPanel $global:OvGenreFilterPanel -ActiveKey $keyCap
            Apply-OvFilters
            # Refresh the featured banner to a game that fits the
            # active genre (or a random pick again when ALL).
            Set-OvBannerForActiveGenre
            if (Get-Command Set-BannerEffect -ErrorAction SilentlyContinue) {
                Set-BannerEffect -BannerName 'OvBanner' -BannerH 200 -ColorHex '#FFFFFF' -Effect (Get-BannerFxFor -Game $global:OvBannerGame -Featured)
            }
            # CLICK EFFECT, after the state repaint (which clears the glow
            # animation; the scale animations are simply replaced here):
            # spring back from 95 % with a slight overshoot
            # and a glow flash that settles on the selected-hover glow.
            $sxP = [System.Windows.Media.ScaleTransform]::ScaleXProperty
            $syP = [System.Windows.Media.ScaleTransform]::ScaleYProperty
            $back = New-Object System.Windows.Media.Animation.BackEase
            $back.Amplitude = 0.6
            $back.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
            $cs = $this.Resources.Item("cardScale")
            Start-OvGenreCardAnim -Target $cs -Property $sxP -From 0.95 -To 1.0 -Ms 260 -Ease $back
            Start-OvGenreCardAnim -Target $cs -Property $syP -From 0.95 -To 1.0 -Ms 260 -Ease $back
            Start-OvGenreCardAnim -Target $this.Resources.Item("cardGlow") `
                -Property ([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty) `
                -From (0.95 * [double]$this.Resources.Item("glowFactor")) `
                -To (0.7 * [double]$this.Resources.Item("glowFactor")) -Ms 420
            if ($this.IsMouseOver) {
                $this.Resources.Item("filterText").Foreground = [System.Windows.Media.Brushes]::White
            }
        }.GetNewClosure())
        $panel.Children.Add($chip) | Out-Null
    }
    # Grid width + 10/5 columns follow the window width. The hook is
    # attached once per parent (the panel is rebuilt on S/M/L changes).
    $par = $panel.Parent
    if ($par -and -not $par.Resources.Contains("ovGenreCardsHook")) {
        $par.Resources.Add("ovGenreCardsHook", $true)
        $par.Add_SizeChanged({
            param($s, $e)
            if (-not $e.WidthChanged) { return }
            if ($global:OvGenreFilterPanel) {
                Update-OvGenreCardLayout -Panel $global:OvGenreFilterPanel
            }
            # Same parent: the PC POWER row moves its GPU box under the
            # bar when the window gets too narrow for one line.
            Update-OvPowerRowLayout
        })
    }
    Update-OvGenreCardLayout -Panel $panel
    $global:OvGenreFilterPanel = $panel
    if (Get-Command Set-OvHeaderPillStyle -ErrorAction SilentlyContinue) {
        Set-OvHeaderPillStyle -Border ($window.FindName("OvGenreHeader"))
    }
}

# ---------------------------------------------------------------
# PC POWER row (Explore layout "Variant 3"): one joined tier bar,
# the Up to my PC / Exact tier segment and the GPU status box.
# ---------------------------------------------------------------
function global:Get-OvPowerRowMetrics {
    param([string]$Size)
    if (-not $Size) { $Size = if ($global:ExploreSize) { $global:ExploreSize } else { "M" } }
    switch ($Size) {
        "S"     { return @{ SegW = 92;  SegH = 36; Font = 11.5; Bar = 40; ModeH = 30; ModeFont = 11.5; GpuFont = 12.0; RateH = 28; Icon = 16; Head = 10.5 } }
        "L"     { return @{ SegW = 116; SegH = 44; Font = 13.5; Bar = 56; ModeH = 38; ModeFont = 13.0; GpuFont = 13.5; RateH = 34; Icon = 20; Head = 12.0 } }
        default { return @{ SegW = 104; SegH = 40; Font = 12.5; Bar = 48; ModeH = 34; ModeFont = 12.0; GpuFont = 12.5; RateH = 30; Icon = 18; Head = 11.0 } }
    }
}

# Resting paint of one tier segment. SELECTED = the same edge glow as the
# genre cards: no fill, a ring in the tier colour over the segment edge
# and a glow around it (damped for bright colours). The selected segment
# is lifted above its neighbours (ZIndex) so its ring is not covered.
function global:Set-OvPowerSegState {
    param($Seg, [bool]$Active)
    if (-not $Seg) { return }
    $bc   = [System.Windows.Media.BrushConverter]::new()
    $body = $Seg.Resources.Item("segBorder")
    $ring = $Seg.Resources.Item("segRing")
    $fx   = $Seg.Resources.Item("segGlow")
    $txt  = $Seg.Resources.Item("filterText")
    $bar  = $Seg.Resources.Item("segBar")
    $sel  = $Seg.Resources.Item("selectAccent")
    $f    = [double]$Seg.Resources.Item("glowFactor")
    $Seg.Resources.Item("segState").Active = $Active
    $body.Background = $bc.ConvertFromString("#141419")
    if ($Active) {
        $ring.BorderBrush = Get-OvAccentBrush -AccentHex $sel -Alpha (0.55 + 0.35 * $f)
        $ring.Visibility  = [System.Windows.Visibility]::Visible
        $txt.Foreground   = [System.Windows.Media.Brushes]::White
        [System.Windows.Controls.Panel]::SetZIndex($Seg, 1)
    } else {
        $ring.Visibility  = [System.Windows.Visibility]::Collapsed
        $txt.Foreground   = $bc.ConvertFromString("#a8a8b2")
        [System.Windows.Controls.Panel]::SetZIndex($Seg, 0)
    }
    $fx.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $null)
    $fx.Opacity = if ($Active) { 0.5 * $f } else { 0.0 }
    $bar.BeginAnimation([System.Windows.FrameworkElement]::WidthProperty, $null)
    $bar.Width = [double]$Seg.Resources.Item("barW")
}

function global:New-OvPowerSeg {
    param([string]$Label, [string]$Key, [string]$Color, [bool]$IsActive, [string]$Position = "mid", [string]$SelectColor = $null)
    $m  = Get-OvPowerRowMetrics
    $bc = [System.Windows.Media.BrushConverter]::new()
    if (-not $SelectColor) { $SelectColor = $Color }
    # The outer bar has CornerRadius 10 (1px border) - the end segments
    # round their own outer corners so their fill never pokes out.
    switch ($Position) {
        "first" { $cr = [System.Windows.CornerRadius]::new(9, 0, 0, 9); $rr = [System.Windows.CornerRadius]::new(10, 2, 2, 10); $bt = [System.Windows.Thickness]::new(0, 0, 1, 0) }
        "last"  { $cr = [System.Windows.CornerRadius]::new(0, 9, 9, 0); $rr = [System.Windows.CornerRadius]::new(2, 10, 10, 2); $bt = [System.Windows.Thickness]::new(0) }
        default { $cr = [System.Windows.CornerRadius]::new(0);          $rr = [System.Windows.CornerRadius]::new(2);           $bt = [System.Windows.Thickness]::new(0, 0, 1, 0) }
    }
    # Root grid, layers back to front: glow, segment body, selection ring.
    $seg = New-Object System.Windows.Controls.Grid
    $seg.Width  = $m.SegW
    $seg.Height = $m.SegH
    $seg.Cursor = [System.Windows.Input.Cursors]::Hand
    $seg.Background = [System.Windows.Media.Brushes]::Transparent

    $glowLayer = New-Object System.Windows.Controls.Border
    $glowLayer.CornerRadius = $cr
    $glowLayer.Background = $bc.ConvertFromString("#141419")
    $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $glow.Color = [System.Windows.Media.ColorConverter]::ConvertFromString($SelectColor)
    $glow.ShadowDepth = 0
    $glow.BlurRadius = 12
    $glow.Opacity = 0.0
    $glowLayer.Effect = $glow
    $seg.Children.Add($glowLayer) | Out-Null

    $body = New-Object System.Windows.Controls.Border
    $body.CornerRadius = $cr
    $body.BorderThickness = $bt
    $body.BorderBrush = $bc.ConvertFromString("#2a2a33")
    $seg.Children.Add($body) | Out-Null

    $ring = New-Object System.Windows.Controls.Border
    $ring.Margin = [System.Windows.Thickness]::new(-1)
    $ring.CornerRadius = $rr
    $ring.BorderThickness = [System.Windows.Thickness]::new(2)
    $ring.IsHitTestVisible = $false
    $ring.Visibility = [System.Windows.Visibility]::Collapsed
    $seg.Children.Add($ring) | Out-Null

    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $sp.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $txt = New-Object System.Windows.Controls.TextBlock
    $txt.Text = $Label
    $txt.FontSize = $m.Font
    $txt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $txt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $txt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $sp.Children.Add($txt) | Out-Null
    $bar = New-Object System.Windows.Shapes.Rectangle
    $bar.Height = 3
    $bar.RadiusX = 1.5
    $bar.RadiusY = 1.5
    $bar.Fill = $bc.ConvertFromString($Color)
    $bar.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $bar.Margin = [System.Windows.Thickness]::new(0, 6, 0, 0)
    $sp.Children.Add($bar) | Out-Null
    $body.Child = $sp

    $seg.Resources.Add("filterKey", $Key)
    $seg.Resources.Add("filterText", $txt)
    $seg.Resources.Add("filterAccent", $Color)
    $seg.Resources.Add("selectAccent", $SelectColor)
    $seg.Resources.Add("glowFactor", (Get-OvGenreCardGlowFactor -AccentHex $SelectColor))
    $seg.Resources.Add("powerSeg", $true)
    $seg.Resources.Add("segBorder", $body)
    $seg.Resources.Add("segRing", $ring)
    $seg.Resources.Add("segGlow", $glow)
    $seg.Resources.Add("segBar", $bar)
    $seg.Resources.Add("barW", [double]$m.Bar)
    $seg.Resources.Add("segState", @{ Active = $IsActive; Pressed = $false })
    Set-OvPowerSegState -Seg $seg -Active $IsActive

    $wP  = [System.Windows.FrameworkElement]::WidthProperty
    $opP = [System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty
    # HOVER (quiet): lifted ground, white label, colour bar stretches.
    # On the selected segment the glow brightens a little instead.
    $seg.Add_MouseEnter({
        $st = $this.Resources.Item("segState")
        if ($st.Active) {
            Start-OvGenreCardAnim -Target $this.Resources.Item("segGlow") -Property $opP `
                -To (0.7 * [double]$this.Resources.Item("glowFactor")) -Ms 160
        } else {
            $this.Resources.Item("segBorder").Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1b1b22")
        }
        $this.Resources.Item("filterText").Foreground = [System.Windows.Media.Brushes]::White
        Start-OvGenreCardAnim -Target $this.Resources.Item("segBar") -Property $wP -To ([double]$this.Resources.Item("barW") * 1.35) -Ms 160
    }.GetNewClosure())
    # LEAVE: unconditional restore, bar and glow ease back from where they were.
    $seg.Add_MouseLeave({
        $st = $this.Resources.Item("segState")
        $st.Pressed = $false
        $bar = $this.Resources.Item("segBar")
        $fx  = $this.Resources.Item("segGlow")
        $curW = $bar.Width
        $curO = $fx.Opacity
        Set-OvPowerSegState -Seg $this -Active $st.Active
        Start-OvGenreCardAnim -Target $bar -Property $wP -From $curW -To ([double]$this.Resources.Item("barW")) -Ms 180
        Start-OvGenreCardAnim -Target $fx -Property $opP -From $curO -To $fx.Opacity -Ms 220
    }.GetNewClosure())
    # PRESS: ground sinks darker until the button comes up.
    $seg.Add_MouseLeftButtonDown({
        $this.Resources.Item("segState").Pressed = $true
        $this.Resources.Item("segBorder").Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0f0f13")
    }.GetNewClosure())
    return $seg
}

function global:Build-OvPowerFilter {
    $panel = $window.FindName("OvPowerFilter")
    if (-not $panel) { return }
    $panel.Children.Clear()

    # "Any" keeps its grey bar but is selected with a neutral light edge.
    $chips = @(@{ Key="ALL"; Label="Any"; Color="#55555f"; Select="#d8d8e0" })
    foreach ($b in $global:OverviewPowerBuckets) {
        $chips += @{ Key=$b.Key; Label=$b.Label; Color=$b.Color }
    }
    for ($i = 0; $i -lt $chips.Count; $i++) {
        $c = $chips[$i]
        $pos = if ($i -eq 0) { "first" } elseif ($i -eq $chips.Count - 1) { "last" } else { "mid" }
        $chip = New-OvPowerSeg -Label $c.Label -Key $c.Key -Color $c.Color -IsActive ($c.Key -eq "ALL") -Position $pos -SelectColor $c.Select
        $keyCap = $c.Key
        $chip.Add_MouseLeftButtonUp({
            $st = $this.Resources.Item("segState")
            if (-not $st.Pressed) { return }
            $st.Pressed = $false
            $global:OvActivePower = $keyCap
            Update-OvFilterChips -ChipPanel $global:OvPowerFilterPanel -ActiveKey $keyCap
            Apply-OvFilters
            # CLICK EFFECT after the repaint: the colour bar flashes wide
            # and settles on the hover width, the new edge glow flashes up.
            $gf = [double]$this.Resources.Item("glowFactor")
            Start-OvGenreCardAnim -Target $this.Resources.Item("segGlow") `
                -Property ([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty) `
                -From (0.95 * $gf) -To (0.7 * $gf) -Ms 420
            $bw = [double]$this.Resources.Item("barW")
            Start-OvGenreCardAnim -Target $this.Resources.Item("segBar") `
                -Property ([System.Windows.FrameworkElement]::WidthProperty) `
                -From ($bw * 1.7) -To ($bw * 1.35) -Ms 320
        }.GetNewClosure())
        $panel.Children.Add($chip) | Out-Null
    }
    $global:OvPowerFilterPanel = $panel
    $hdr = $window.FindName("OvPowerHeaderText")
    if ($hdr) { $hdr.FontSize = (Get-OvPowerRowMetrics).Head }
    # GPU status box at the right end of the row.
    Add-OvGpuRateControls -Panel ($window.FindName("OvGpuBoxPanel"))
    Update-OvPowerRowLayout
}

# ---------------------------------------------------------------
# GPU rating for the Explore power filter ("Rate my GPU").
# ---------------------------------------------------------------
# The controls live in the GPU status box at the right end of the PC
# POWER row (OvGpuBox) - they belong to that selection.
# The Explore filter uses 4 coarse buckets, the detail page uses the
# 6 PowerTiers. Map a resolved GPU tier index onto a bucket key:
#   tier 0/1 (LOW,BASIC)   -> LOW
#   tier 2   (SOLID)       -> SOLID
#   tier 3/4 (STRONG,HIGH) -> HIGH
#   tier 5   (EXTREME)     -> EXTREME
# A GPU below the scale (-2) still maps to LOW - the honest closest
# bucket. -1 (unknown) has no bucket and is reported as such.
function global:Get-OvBucketKeyForGpuTier {
    param([int]$TierIdx)
    if ($TierIdx -eq -2) { return "LOW" }
    if ($TierIdx -lt 0)  { return $null }
    if ($TierIdx -le 1)  { return "LOW" }
    if ($TierIdx -eq 2)  { return "SOLID" }
    if ($TierIdx -le 4)  { return "HIGH" }
    return "EXTREME"
}

# Run the rating: read the GPU locally (the click is the consent),
# select the matching bucket in the power filter, report inline.
function global:Invoke-OvGpuRate {
    $resTxt = $global:OvRateResultTxt
    $gpu = Get-InstalledGpuName
    $bc = [System.Windows.Media.BrushConverter]::new()
    if (-not $gpu) {
        if ($resTxt) { $resTxt.Text = "No GPU detected"; $resTxt.Foreground = $bc.ConvertFromString("#8a93a3") }
        return
    }
    $idx = Get-GpuTierIndex -Name $gpu
    $key = Get-OvBucketKeyForGpuTier -TierIdx $idx
    if (-not $key) {
        if ($resTxt) { $resTxt.Text = "$gpu - not in the tier list"; $resTxt.Foreground = $bc.ConvertFromString("#8a93a3") }
        return
    }
    $global:OvActivePower = $key
    if ($global:OvPowerFilterPanel) {
        Update-OvFilterChips -ChipPanel $global:OvPowerFilterPanel -ActiveKey $key
    }
    Apply-OvFilters
    if ($resTxt) {
        $tierLabel = if ($idx -ge 0) { $global:PowerTiers[$idx].Label } else { "below LOW" }
        $resTxt.Text = "$gpu - $tierLabel"
        $resTxt.Foreground = $bc.ConvertFromString("#5fd08a")
    }
}

# Rate, remember the result text (an S/M/L rebuild restores it instead
# of claiming "not rated yet") and re-check the row layout, since the
# result text can be much longer than the placeholder.
function global:Invoke-OvGpuRateAndRefresh {
    Invoke-OvGpuRate
    if ($global:OvRateResultTxt) {
        $global:OvRateLastText = $global:OvRateResultTxt.Text
        $global:OvRateLastFg   = $global:OvRateResultTxt.Foreground
        $global:OvRateResultTxt.ToolTip = $global:OvRateResultTxt.Text
    }
    Update-OvPowerRowLayout
}

# Paint the "Always" toggle (checkbox look) to match its persisted state.
function global:Update-OvAlwaysRateVisual {
    param([bool]$On)
    if (-not $global:OvAlwaysRateBtn -or -not $global:OvAlwaysRateTxt) { return }
    $bc  = [System.Windows.Media.BrushConverter]::new()
    $box = $global:OvAlwaysRateBtn.Resources.Item("alwaysBox")
    $chk = $global:OvAlwaysRateBtn.Resources.Item("alwaysCheck")
    $global:OvAlwaysRateBtn.Resources["alwaysOn"] = $On
    if ($On) {
        $box.Background  = $bc.ConvertFromString("#ff8a2a")
        $box.BorderBrush = $bc.ConvertFromString("#ff8a2a")
        $chk.Visibility  = [System.Windows.Visibility]::Visible
        $global:OvAlwaysRateTxt.Foreground = $bc.ConvertFromString("#e8e8ec")
    } else {
        $box.Background  = [System.Windows.Media.Brushes]::Transparent
        $box.BorderBrush = $bc.ConvertFromString("#6a6a76")
        $chk.Visibility  = [System.Windows.Visibility]::Collapsed
        $global:OvAlwaysRateTxt.Foreground = $bc.ConvertFromString("#a8a8b2")
    }
}

# Exact tier mode hides the whole GPU box: there the user deliberately
# browses one tier, so their own GPU is irrelevant.
function global:Update-OvGpuRateVisibility {
    $vis = if ($global:OvPowerMode -eq "exact") {
        [System.Windows.Visibility]::Collapsed
    } else {
        [System.Windows.Visibility]::Visible
    }
    foreach ($el in @($global:OvRateBtn, $global:OvAlwaysRateBtn, $global:OvRateResultHost)) {
        if ($el) { $el.Visibility = $vis }
    }
    if (Get-Command Update-OvPowerRowLayout -ErrorAction SilentlyContinue) { Update-OvPowerRowLayout }
}

# Fill the GPU status box: chip icon, status text, "Always" toggle and
# the "Rate my GPU" button. $Panel is OvGpuBoxPanel inside OvGpuBox.
function global:Add-OvGpuRateControls {
    param($Panel)
    if (-not $Panel) { return }
    $Panel.Children.Clear()
    $m  = Get-OvPowerRowMetrics
    $bc = [System.Windows.Media.BrushConverter]::new()

    # Chip icon, built from primitives (see New-OvGenreIcon for why).
    $g = New-Object System.Windows.Media.GeometryGroup
    $r = New-Object System.Windows.Media.RectangleGeometry
    $r.Rect = New-Object System.Windows.Rect 4, 4, 8, 8
    $g.Children.Add($r) | Out-Null
    foreach ($ln in @(@(6,1.5,6,4), @(10,1.5,10,4), @(6,12,6,14.5), @(10,12,10,14.5),
                      @(1.5,6,4,6), @(1.5,10,4,10), @(12,6,14.5,6), @(12,10,14.5,10))) {
        $lg = New-Object System.Windows.Media.LineGeometry
        $lg.StartPoint = New-Object System.Windows.Point $ln[0], $ln[1]
        $lg.EndPoint   = New-Object System.Windows.Point $ln[2], $ln[3]
        $g.Children.Add($lg) | Out-Null
    }
    $icon = New-Object System.Windows.Shapes.Path
    $icon.Data = $g
    $icon.Stroke = $bc.ConvertFromString("#ff8a2a")
    $icon.StrokeThickness = 1.4
    $icon.StrokeStartLineCap = [System.Windows.Media.PenLineCap]::Round
    $icon.StrokeEndLineCap   = [System.Windows.Media.PenLineCap]::Round
    $icon.Width = $m.Icon
    $icon.Height = $m.Icon
    $icon.Stretch = [System.Windows.Media.Stretch]::Uniform
    $icon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $icon.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
    $Panel.Children.Add($icon) | Out-Null

    # Status text - Invoke-OvGpuRate writes the result here.
    $res = New-Object System.Windows.Controls.TextBlock
    $res.Text = "GPU not rated yet"
    $res.FontSize = $m.GpuFont
    $res.Foreground = $bc.ConvertFromString("#b4b4be")
    if ($global:OvRateLastText) {
        $res.Text = $global:OvRateLastText
        if ($global:OvRateLastFg) { $res.Foreground = $global:OvRateLastFg }
    }
    # Long GPU names are cut with an ellipsis; the full text is the tooltip.
    $res.MaxWidth = 300
    $res.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis
    $res.ToolTip = $res.Text
    $res.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $res.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $res.Margin = [System.Windows.Thickness]::new(0, 0, 14, 0)
    $Panel.Children.Add($res) | Out-Null
    $global:OvRateResultTxt = $res
    $global:OvRateResultHost = $window.FindName("OvGpuBox")

    # "Always" toggle: small checkbox + label.
    $alw = New-Object System.Windows.Controls.StackPanel
    $alw.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $alw.Background = [System.Windows.Media.Brushes]::Transparent
    $alw.Cursor = [System.Windows.Input.Cursors]::Hand
    $alw.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $alw.Margin = [System.Windows.Thickness]::new(0, 0, 12, 0)
    $alw.ToolTip = "Rate automatically every time you open Explore"
    $box = New-Object System.Windows.Controls.Border
    $box.Width = 14
    $box.Height = 14
    $box.CornerRadius = [System.Windows.CornerRadius]::new(3)
    $box.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $box.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $cg = New-Object System.Windows.Media.PathGeometry
    $cf = New-Object System.Windows.Media.PathFigure
    $cf.StartPoint = New-Object System.Windows.Point 2.5, 6
    $s1 = New-Object System.Windows.Media.LineSegment
    $s1.Point = New-Object System.Windows.Point 5, 8.5
    $cf.Segments.Add($s1) | Out-Null
    $s2 = New-Object System.Windows.Media.LineSegment
    $s2.Point = New-Object System.Windows.Point 9.5, 3
    $cf.Segments.Add($s2) | Out-Null
    $cg.Figures.Add($cf) | Out-Null
    $chk = New-Object System.Windows.Shapes.Path
    $chk.Data = $cg
    $chk.Stroke = $bc.ConvertFromString("#1b0e02")
    $chk.StrokeThickness = 1.8
    $chk.StrokeStartLineCap = [System.Windows.Media.PenLineCap]::Round
    $chk.StrokeEndLineCap   = [System.Windows.Media.PenLineCap]::Round
    $chk.StrokeLineJoin     = [System.Windows.Media.PenLineJoin]::Round
    $box.Child = $chk
    $alw.Children.Add($box) | Out-Null
    $alwTxt = New-Object System.Windows.Controls.TextBlock
    $alwTxt.Text = "Always"
    $alwTxt.FontSize = $m.GpuFont - 0.5
    $alwTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $alwTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $alwTxt.Margin = [System.Windows.Thickness]::new(7, 0, 0, 0)
    $alw.Children.Add($alwTxt) | Out-Null
    $alw.Resources.Add("alwaysBox", $box)
    $alw.Resources.Add("alwaysCheck", $chk)
    $global:OvAlwaysRateBtn = $alw
    $global:OvAlwaysRateTxt = $alwTxt
    $alw.Add_MouseEnter({
        $this.Resources.Item("alwaysBox").BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ff8a2a")
        $global:OvAlwaysRateTxt.Foreground = [System.Windows.Media.Brushes]::White
    })
    $alw.Add_MouseLeave({
        Update-OvAlwaysRateVisual -On ([bool]$this.Resources["alwaysOn"])
    })
    $alw.Add_MouseLeftButtonUp({
        $on = -not [bool](Get-HubSetting -Key "OvGpuRateAlways" -Default $false)
        Set-HubSetting -Key "OvGpuRateAlways" -Value $on
        Update-OvAlwaysRateVisual -On $on
        if ($on) { Invoke-OvGpuRateAndRefresh }
    })
    $Panel.Children.Add($alw) | Out-Null

    # "Rate my GPU" - orange outline on a light orange tint.
    $rate = New-Object System.Windows.Controls.Border
    $rate.Height = $m.RateH
    $rate.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $rate.BorderThickness = [System.Windows.Thickness]::new(1)
    $rate.BorderBrush = $bc.ConvertFromString("#ff8a2a")
    $rate.Background = Get-OvGenreCardTint -AccentHex "#ff8a2a" -Amount 0.14
    $rate.Padding = [System.Windows.Thickness]::new(12, 0, 12, 0)
    $rate.Cursor = [System.Windows.Input.Cursors]::Hand
    $rate.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $rate.ToolTip = "Reads your installed GPU name once, locally, and picks the matching power level"
    $rt = New-Object System.Windows.Controls.TextBlock
    $rt.Text = "Rate my GPU"
    $rt.FontSize = $m.GpuFont
    $rt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $rt.Foreground = [System.Windows.Media.Brushes]::White
    $rt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $rt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $rate.Child = $rt
    $rate.Resources.Add("pressed", $false)
    $global:OvRateBtn = $rate
    $rate.Add_MouseEnter({ $this.Background = Get-OvGenreCardTint -AccentHex "#ff8a2a" -Amount 0.26 })
    $rate.Add_MouseLeave({
        $this.Resources["pressed"] = $false
        $this.Background = Get-OvGenreCardTint -AccentHex "#ff8a2a" -Amount 0.14
    })
    $rate.Add_MouseLeftButtonDown({
        $this.Resources["pressed"] = $true
        $this.Background = Get-OvGenreCardTint -AccentHex "#ff8a2a" -Amount 0.40
    })
    $rate.Add_MouseLeftButtonUp({
        if (-not [bool]$this.Resources["pressed"]) { return }
        $this.Resources["pressed"] = $false
        $this.Background = Get-OvGenreCardTint -AccentHex "#ff8a2a" -Amount 0.26
        Invoke-OvGpuRateAndRefresh
    })
    $Panel.Children.Add($rate) | Out-Null

    $alwaysOn = [bool](Get-HubSetting -Key "OvGpuRateAlways" -Default $false)
    Update-OvAlwaysRateVisual -On $alwaysOn
    Update-OvGpuRateVisibility
    if ($alwaysOn -and $global:OvPowerMode -ne "exact") { Invoke-OvGpuRateAndRefresh }
}

# GPU box right of the bar when it fits, otherwise under it.
function global:Update-OvPowerRowLayout {
    if (-not $window) { return }
    $row  = $window.FindName("OvPowerRow")
    $left = $window.FindName("OvPowerLeft")
    $box  = $window.FindName("OvGpuBox")
    if (-not $row -or -not $left -or -not $box) { return }
    # The row stretches over its parent; read the parent so a resize is
    # judged by the new width even before the row itself re-arranged.
    $w = $row.ActualWidth
    if ($row.Parent -and $row.Parent.ActualWidth -gt 0) {
        $w = $row.Parent.ActualWidth - $row.Margin.Left - $row.Margin.Right
    }
    if ($w -le 0) { return }
    $inf = [System.Windows.Size]::new([double]::PositiveInfinity, [double]::PositiveInfinity)
    $left.Measure($inf)
    $box.Measure($inf)
    $boxW = $box.DesiredSize.Width - $box.Margin.Left - $box.Margin.Right + 18
    $fits = Test-OvPowerRowFits -RowWidth $w -LeftWidth $left.DesiredSize.Width -BoxWidth $boxW
    if ($fits) {
        [System.Windows.Controls.Grid]::SetRow($box, 0)
        [System.Windows.Controls.Grid]::SetColumn($box, 1)
        $box.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $box.Margin = [System.Windows.Thickness]::new(18, 0, 0, 0)
    } else {
        [System.Windows.Controls.Grid]::SetRow($box, 1)
        [System.Windows.Controls.Grid]::SetColumn($box, 0)
        $box.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $box.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
    }
}

# Pure rule (no WPF): the box (incl. its 18px gap) fits beside the bar.
function global:Test-OvPowerRowFits {
    param([double]$RowWidth, [double]$LeftWidth, [double]$BoxWidth)
    return (($LeftWidth + $BoxWidth) -le $RowWidth)
}

# Build a genre row: header + horizontal scroll of tiles + side
# arrows. Mouse wheel forwards to the page so vertical scrolling
# still works.
function global:New-OvGenreRow {
    param($Genre, $Games, [switch]$Deferred)

    $rowStack = New-Object System.Windows.Controls.StackPanel
    $rowStack.Margin = [System.Windows.Thickness]::new(0, 0, 0, 26)
    $rowStack.Resources.Add("genreKey", $Genre.Key)

    $hdr = New-Object System.Windows.Controls.StackPanel
    $hdr.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $hdr.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)

    $hdrTitle = New-Object System.Windows.Controls.TextBlock
    $hdrTitle.Text = $Genre.Label
    $hdrTitle.FontSize = 22
    $hdrTitle.FontWeight = [System.Windows.FontWeights]::Bold
    # White -> light-grey vertical gradient, matching tiles/banners/detail.
    $hdrTitleGrad = New-Object System.Windows.Media.LinearGradientBrush
    $hdrTitleGrad.StartPoint = [System.Windows.Point]::new(0, 0)
    $hdrTitleGrad.EndPoint   = [System.Windows.Point]::new(0, 1)
    $hdrTitleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(255,255,255), 0))) | Out-Null
    $hdrTitleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(216,222,227), 1))) | Out-Null
    $hdrTitleGrad.Freeze()
    $hdrTitle.Foreground = $hdrTitleGrad
    $hdrTitle.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $hdrTitle.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $hdr.Children.Add($hdrTitle) | Out-Null

    # Count bubble: a small rounded pill instead of a dashed text run.
    # Left margin keeps the same offset from the title as the old "  -  ".
    $countBubble = New-Object System.Windows.Controls.Border
    $countBubble.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $countBubble.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1e1e28")
    $countBubble.BorderThickness = [System.Windows.Thickness]::new(1)
    $countBubble.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2c2c3a")
    $countBubble.Padding = [System.Windows.Thickness]::new(7, 1, 7, 1)
    $countBubble.Margin = [System.Windows.Thickness]::new(10, 0, 0, 0)
    $countBubble.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $hdrCount = New-Object System.Windows.Controls.TextBlock
    $hdrCount.Text = "$($Games.Count) games"
    $hdrCount.FontSize = 10
    $hdrCount.FontWeight = [System.Windows.FontWeights]::SemiBold
    $hdrCount.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9a9aae")
    $hdrCount.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $countBubble.Child = $hdrCount
    # Enlarge a little on hover so the count is easier to read.
    Add-HoverScale -Element $countBubble -Scale 1.12
    $hdr.Children.Add($countBubble) | Out-Null

    $rowStack.Children.Add($hdr) | Out-Null

    $rowGrid = New-Object System.Windows.Controls.Grid

    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $scroll.HorizontalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Hidden
    $scroll.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Disabled
    # Forward mouse wheel to the visual parent so vertical page
    # scrolling still works when the cursor is over a row.
    $scroll.Add_PreviewMouseWheel({
        param($s, $e)
        $e.Handled = $true
        $parent = [System.Windows.Media.VisualTreeHelper]::GetParent($s)
        if ($parent) {
            $newEvent = New-Object System.Windows.Input.MouseWheelEventArgs `
                ([System.Windows.Input.Mouse]::PrimaryDevice, $e.Timestamp, $e.Delta)
            $newEvent.RoutedEvent = [System.Windows.UIElement]::MouseWheelEvent
            $parent.RaiseEvent($newEvent)
        }
    })

    $tilesPanel = New-Object System.Windows.Controls.StackPanel
    $tilesPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    # First copy: always present. In -Deferred mode the tiles are added
    # later, one per dispatcher cycle, by the background prewarm - the
    # header count still reflects $Games.Count so the row reads correctly
    # while its tiles stream in.
    if (-not $Deferred) {
        foreach ($g in $Games) {
            # Lazy cards (test build): a placeholder; built when scrolled into view.
            $tile = if ($global:HubLazyCards -and (Get-Command New-LazyOverviewTile -ErrorAction SilentlyContinue)) {
                New-LazyOverviewTile -Game $g
            } else {
                New-OverviewTile -Game $g
            }
            $tilesPanel.Children.Add($tile) | Out-Null
        }
    }
    # Horizontal scrolling inside a row brings unbuilt tiles into view.
    if ($global:HubLazyCards) {
        $scroll.Add_ScrollChanged({ if (Get-Command Request-LazyRealize -ErrorAction SilentlyContinue) { Request-LazyRealize } })
    }
    # Track whether the duplicate-copy has been added. We only add
    # it once we know the row actually overflows the viewport - if
    # everything fits, a duplicate would just show the same titles
    # twice on the page. The Loaded handler below makes the call
    # the moment WPF reports real Viewport/Extent widths.
    $tilesPanel.Tag = @{
        Games          = $Games
        DuplicateAdded = $false
    }
    $scroll.Content = $tilesPanel
    $rowGrid.Children.Add($scroll) | Out-Null

    # Right arrow
    $rightHost = New-Object System.Windows.Controls.Border
    $rightHost.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $rightHost.VerticalAlignment = [System.Windows.VerticalAlignment]::Stretch
    $rightHost.Width = 56
    $rightHost.Cursor = [System.Windows.Input.Cursors]::Hand
    $rightFade = New-Object System.Windows.Media.LinearGradientBrush
    $rightFade.StartPoint = New-Object System.Windows.Point 0, 0.5
    $rightFade.EndPoint   = New-Object System.Windows.Point 1, 0.5
    $rightFade.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,15,15,18)), 0.0)) | Out-Null
    $rightFade.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(220,15,15,18)), 0.7)) | Out-Null
    $rightHost.Background = $rightFade

    $rightBtn = New-Object System.Windows.Controls.Border
    $rightBtn.Width = 30; $rightBtn.Height = 30
    $rightBtn.CornerRadius = [System.Windows.CornerRadius]::new(15)
    $rightBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1e1e2a")
    $rightBtn.BorderThickness = [System.Windows.Thickness]::new(1)
    $rightBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
    $rightBtn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $rightBtn.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $rightBtn.Margin = [System.Windows.Thickness]::new(0, 0, 4, 0)
    $rightTxt = New-Object System.Windows.Controls.TextBlock
    $rightTxt.Text = ">"
    $rightTxt.FontSize = 16
    $rightTxt.FontWeight = [System.Windows.FontWeights]::Bold
    $rightTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    $rightTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $rightTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $rightTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $rightBtn.Child = $rightTxt

    # End-of-row hint. The row wraps back to the start when the right
    # arrow is clicked at the end - without a sign the user cannot tell
    # a wrap from "nothing happened". The arrow itself briefly turns
    # into a loop glyph, glows, and shows a one-word caption. Nothing
    # new appears elsewhere on screen, and the caption is short because
    # the arrow column is only 56px wide.
    # BUTTON AND CAPTION SHARE ONE GRID CELL, they are NOT stacked. In a
    # vertical stack the caption is part of the layout, so the moment it
    # becomes visible the pair is re-centred and the button jumps UP by
    # half the caption height. Here both sit in the same cell, each
    # centred, and the caption is pushed below the circle by a top
    # margin of its own - so the button stays on the exact same pixel
    # whether the caption shows or not.
    $rightStack = New-Object System.Windows.Controls.Grid
    $rightStack.HorizontalAlignment = $rightBtn.HorizontalAlignment
    $rightStack.VerticalAlignment   = $rightBtn.VerticalAlignment
    $rightStack.Margin = $rightBtn.Margin
    $rightBtn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $rightBtn.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $rightBtn.Margin = [System.Windows.Thickness]::new(0)
    [void]$rightStack.Children.Add($rightBtn)
    $rightCap = New-Object System.Windows.Controls.TextBlock
    $rightCap.Text = "repeat"
    $rightCap.FontSize = 8
    $rightCap.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $rightCap.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    $rightCap.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $rightCap.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    # Centred plus 36 top = 18px below the middle, i.e. just under the
    # 30px circle. The Grid grows for it, the button does not move.
    $rightCap.Margin = [System.Windows.Thickness]::new(0, 36, 0, 0)
    $rightCap.IsHitTestVisible = $false
    $rightCap.Visibility = [System.Windows.Visibility]::Collapsed
    [void]$rightStack.Children.Add($rightCap)
    $rightHost.Child = $rightStack

    # Left arrow - hidden until the user has scrolled away from start
    $leftHost = New-Object System.Windows.Controls.Border
    $leftHost.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $leftHost.VerticalAlignment = [System.Windows.VerticalAlignment]::Stretch
    $leftHost.Width = 56
    $leftHost.Cursor = [System.Windows.Input.Cursors]::Hand
    $leftHost.Visibility = [System.Windows.Visibility]::Collapsed
    $leftFade = New-Object System.Windows.Media.LinearGradientBrush
    $leftFade.StartPoint = New-Object System.Windows.Point 0, 0.5
    $leftFade.EndPoint   = New-Object System.Windows.Point 1, 0.5
    $leftFade.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(220,15,15,18)), 0.0)) | Out-Null
    $leftFade.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,15,15,18)), 0.7)) | Out-Null
    $leftHost.Background = $leftFade

    $leftBtn = New-Object System.Windows.Controls.Border
    $leftBtn.Width = 30; $leftBtn.Height = 30
    $leftBtn.CornerRadius = [System.Windows.CornerRadius]::new(15)
    $leftBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1e1e2a")
    $leftBtn.BorderThickness = [System.Windows.Thickness]::new(1)
    $leftBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
    $leftBtn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $leftBtn.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $leftBtn.Margin = [System.Windows.Thickness]::new(4, 0, 0, 0)
    $leftTxt = New-Object System.Windows.Controls.TextBlock
    $leftTxt.Text = "<"
    $leftTxt.FontSize = 16
    $leftTxt.FontWeight = [System.Windows.FontWeights]::Bold
    $leftTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    $leftTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $leftTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $leftTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $leftBtn.Child = $leftTxt
    $leftHost.Child = $leftBtn

    $scrollCap = $scroll
    $leftHostCap = $leftHost
    # Shows the wrap hint and takes it back after 1.2 s. One timer per
    # row, reused - restarting it while it runs just extends the hint.
    $rightBtnCap = $rightBtn; $rightTxtCap = $rightTxt; $rightCapCap = $rightCap
    $wrapGlyph   = "$([char]0x21BB)"      # clockwise open circle arrow
    $wrapArrow   = $rightTxt.Text
    $wrapTimer = New-Object System.Windows.Threading.DispatcherTimer
    $wrapTimer.Interval = [TimeSpan]::FromMilliseconds(1200)
    $wrapTimer.Add_Tick({
        $wrapTimer.Stop()
        try {
            $rightTxtCap.Text = $wrapArrow
            $rightTxtCap.FontSize = 16
            $rightBtnCap.Effect = $null
            $rightBtnCap.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
            $rightCapCap.Visibility = [System.Windows.Visibility]::Collapsed
        } catch { }
    }.GetNewClosure())
    $showWrapHint = {
        try {
            $rightTxtCap.Text = $wrapGlyph
            # The loop glyph reads smaller than ">" at the same size, so
            # it gets its own FontSize. No vertical offset - the glyph
            # stays centred in the circle, the TextBlock does that on
            # its own.
            $rightTxtCap.FontSize = 19
            $rightBtnCap.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ff9a3c")
            $g = New-Object System.Windows.Media.Effects.DropShadowEffect
            $g.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#dd6600")
            $g.BlurRadius = 14; $g.ShadowDepth = 0; $g.Opacity = 0.9
            $rightBtnCap.Effect = $g
            $rightCapCap.Visibility = [System.Windows.Visibility]::Visible
            $wrapTimer.Stop(); $wrapTimer.Start()
        } catch { }
    }.GetNewClosure()

    $rightHostCap = $rightHost
    $rightHost.Add_MouseLeftButtonUp({
        $cur = $scrollCap.HorizontalOffset
        $max = $scrollCap.ScrollableWidth
        if ($max -le 0) { return }
        # No duplicate-copy loop: when the user reaches the end,
        # the next right click wraps to the start. This avoids
        # ever showing the same title twice on screen at once
        # (which used to happen with the seamless duplicate copy
        # design when the viewport was wide).
        if ($cur -ge ($max - 1)) {
            $scrollCap.ScrollToHorizontalOffset(0)
            & $showWrapHint
        } else {
            $scrollCap.ScrollToHorizontalOffset([Math]::Min($cur + 360, $max))
        }
    }.GetNewClosure())
    $leftHost.Add_MouseLeftButtonUp({
        $cur = $scrollCap.HorizontalOffset
        $max = $scrollCap.ScrollableWidth
        if ($cur -le 0 -and $max -gt 0) {
            # At the start - wrap to the end so left-arrow on
            # offset 0 jumps to the tail.
            $scrollCap.ScrollToHorizontalOffset($max)
        } else {
            $scrollCap.ScrollToHorizontalOffset([Math]::Max($cur - 360, 0))
        }
    }.GetNewClosure())
    # ScrollChanged fires not only when the user scrolls but also
    # whenever Extent or Viewport size changes - i.e. on window
    # resize and on visibility-driven layout passes. We use that
    # to drive BOTH arrows from actual overflow (Extent vs Viewport)
    # instead of from a static "Count > 4" heuristic, so resizing
    # the window or filtering tiles correctly hides/shows arrows.
    $scroll.Add_ScrollChanged({
        param($s, $e)
        if ($s.HorizontalOffset -gt 5) {
            $leftHostCap.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $leftHostCap.Visibility = [System.Windows.Visibility]::Collapsed
        }
        # Right arrow visible only when there is something to
        # scroll to. No duplicate copy is added any more - the
        # arrow simply wraps to offset 0 when the user reaches
        # the end (see Add_MouseLeftButtonUp on $rightHost).
        $overflowing = ($s.ScrollableWidth -gt 1)
        if ($overflowing) {
            $rightHostCap.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $rightHostCap.Visibility = [System.Windows.Visibility]::Collapsed
        }
    }.GetNewClosure())

    $rowGrid.Children.Add($leftHost)  | Out-Null
    $rowGrid.Children.Add($rightHost) | Out-Null
    $rowStack.Children.Add($rowGrid) | Out-Null

    # Initial visibility: arrows start hidden. The ScrollChanged
    # handler above sets the right arrow visible on the first
    # layout pass once Extent/Viewport widths are measured, and
    # re-evaluates on every window resize and filter change. The
    # left arrow stays hidden until the user actually scrolls.
    $rightHost.Visibility = [System.Windows.Visibility]::Collapsed

    $rowStack.Resources.Add("scrollViewer", $scroll)
    $rowStack.Resources.Add("tilesPanel", $tilesPanel)
    $rowStack.Resources.Add("leftHost", $leftHost)
    $rowStack.Resources.Add("rightHost", $rightHost)

    return $rowStack
}

function global:Build-OvGenreRows {
    $panel = $window.FindName("OvGenreRows")
    if (-not $panel) { return }
    $panel.Children.Clear()
    $global:OvGenreRowsPanel = $panel

    $allGames = @()
    $allGames += $ownGames
    $allGames += $ownGamesGP
    $allGames += $externalGames
    $allGames = @($allGames | Where-Object { -not $_.UntestedInstaller })
    $global:OvAllGames = $allGames

    foreach ($genre in $global:OverviewGenres) {
        $genreGames = @()
        foreach ($g in $allGames) {
            if (Test-OverviewGameInGenre -Game $g -Genre $genre) { $genreGames += $g }
        }
        if ($genreGames.Count -eq 0) { continue }
        $row = New-OvGenreRow -Genre $genre -Games $genreGames
        $panel.Children.Add($row) | Out-Null
    }
    if (Get-Command Apply-CatalogSort -ErrorAction SilentlyContinue) {
        Apply-CatalogSort -Scope Explore -SkipFilter
    }
}

# Apply Genre + Power filter PLUS the header filter bar's
# Motion/Gamepad/Installed predicate so the Overview is fully
# integrated with the rest of the hub's controls.
function global:Apply-OvFilters {
    if (-not $global:OvGenreRowsPanel) { return }
    $genreKey = if ($global:OvActiveGenre) { $global:OvActiveGenre } else { "ALL" }
    $powerKey = if ($global:OvActivePower) { $global:OvActivePower } else { "ALL" }
    # FREE and NEW are cross-genre filters: keep every genre row, but show
    # only titles from their shared catalog-derived lists inside each.
    $freeOnly = ($genreKey -eq "FREE")
    $newOnly  = ($genreKey -eq "NEW")
    $crossGenreOnly = ($freeOnly -or $newOnly)

    foreach ($row in $global:OvGenreRowsPanel.Children) {
        $rowGenre = $row.Resources.Item("genreKey")
        $genreOk = ($genreKey -eq "ALL") -or $crossGenreOnly -or ($rowGenre -eq $genreKey)
        if (-not $genreOk) {
            $row.Visibility = [System.Windows.Visibility]::Collapsed
            continue
        }

        $tilesPanel = $row.Resources.Item("tilesPanel")
        $visibleCount = 0
        if ($tilesPanel) {
            # Power filter has two interpretations depending on
            # $global:OvPowerMode:
            #   "cumulative" (default) - "Solid" shows LOW + SOLID,
            #     "High" shows LOW + SOLID + HIGH. User sets their
            #     PC's ceiling once and sees everything they can run.
            #   "exact" - "Solid" shows ONLY Solid-tier games. User
            #     wants to browse a specific tier (curated discovery,
            #     hardware-tier comparison shopping, etc).
            # ALL bypasses the filter entirely in both modes.
            $maxPowerIdx = -1
            $exactPowerIdx = -1
            $isExactMode = ($global:OvPowerMode -eq "exact")
            if ($powerKey -ne "ALL") {
                if ($isExactMode) {
                    $exactPowerIdx = Get-OverviewPowerBucketIndex -Key $powerKey
                } else {
                    $maxPowerIdx = Get-OverviewPowerBucketIndex -Key $powerKey
                }
            }
            foreach ($tile in $tilesPanel.Children) {
                $g = $tile.Resources.Item("game")
                if (-not $g) { continue }
                $show = $true
                if ($freeOnly -and ($global:FREE_GAME_TITLES -notcontains $g.Title)) { $show = $false }
                if ($newOnly -and ($global:NEW_GAME_TITLES -notcontains $g.Title)) { $show = $false }
                if ($maxPowerIdx -ge 0) {
                    $bucket = Get-GamePowerBucket -Game $g
                    $bucketIdx = Get-OverviewPowerBucketIndex -Key $bucket
                    if ($bucketIdx -lt 0 -or $bucketIdx -gt $maxPowerIdx) { $show = $false }
                } elseif ($exactPowerIdx -ge 0) {
                    $bucket = Get-GamePowerBucket -Game $g
                    $bucketIdx = Get-OverviewPowerBucketIndex -Key $bucket
                    if ($bucketIdx -ne $exactPowerIdx) { $show = $false }
                }
                # Header filters: Motion / Gamepad / Installed.
                if ($show -and (Get-Command Test-GamePassesFilter -ErrorAction SilentlyContinue)) {
                    if (-not (Test-GamePassesFilter -GameData $g -Query "")) { $show = $false }
                }
                $tile.Visibility = if ($show) {
                    [System.Windows.Visibility]::Visible
                } else {
                    [System.Windows.Visibility]::Collapsed
                }
                if ($show) { $visibleCount++ }
            }
        }

        $row.Visibility = if ($visibleCount -gt 0) {
            [System.Windows.Visibility]::Visible
        } else {
            [System.Windows.Visibility]::Collapsed
        }

        # Right scroll arrow visibility is driven by the actual
        # overflow of the tile strip in the ScrollViewer - not by
        # a static tile count - so resizing the window or filtering
        # tiles correctly hides/shows the arrow. ScrollChanged fires
        # automatically on the next layout pass and refreshes this
        # again. We poke it here to also cover cases where pure
        # visibility changes don't fire ScrollChanged (e.g. when
        # the overall ExtentWidth happens to stay constant).
        $rightHost = $row.Resources.Item("rightHost")
        $leftHost  = $row.Resources.Item("leftHost")
        $sv = $row.Resources.Item("scrollViewer")
        if ($rightHost -and $sv) {
            if ($visibleCount -eq 0) {
                $rightHost.Visibility = [System.Windows.Visibility]::Collapsed
            } else {
                # InvalidateMeasure schedules a layout pass which
                # then fires ScrollChanged with the up-to-date
                # ExtentWidth / ViewportWidth - the handler does
                # the actual visibility math.
                $sv.InvalidateMeasure()
                # Direct fallback in case the layout pass is
                # deferred (e.g. row currently collapsed but about
                # to become visible).
                if ($sv.ExtentWidth -gt ($sv.ViewportWidth + 1)) {
                    $rightHost.Visibility = [System.Windows.Visibility]::Visible
                } else {
                    $rightHost.Visibility = [System.Windows.Visibility]::Collapsed
                }
            }
        }
        # Reset scroll to start when filter changes; left arrow hidden too.
        if ($sv) { $sv.ScrollToHorizontalOffset(0) }
        if ($leftHost) {
            $leftHost.Visibility = [System.Windows.Visibility]::Collapsed
        }
    }
    # Rows/tiles shown by the new filter are built next (lazy cards).
    if (Get-Command Request-LazyRealize -ErrorAction SilentlyContinue) { Request-LazyRealize }
}

$global:OverviewBuilt = $false
# Build the Explore "chrome" - banner + the genre / power / mode filter
# pills. Cheap next to the genre rows, and guarded so it runs exactly once
# whether the first trigger is the background prewarm or the user opening
# Explore (prevents duplicate filter pills across the two paths).
function global:Build-OverviewChrome {
    if ($global:OvChromeBuilt) { return }
    $global:OvActiveGenre = "ALL"
    $global:OvActivePower = "ALL"
    # Power-filter mode: "cumulative" (default - "your PC, show
    # everything I can run") or "exact" (only games of this specific
    # tier). The two modes share the same tier-pill UI; only the
    # interpretation in Apply-OvFilters differs.
    if (-not $global:OvPowerMode) { $global:OvPowerMode = "cumulative" }
    Set-OvBanner
    # Explore is built on demand, after startup's effect initialization.
    # Select the assigned effect only once its first featured game is known.
    if (Get-Command Set-BannerEffect -ErrorAction SilentlyContinue) {
        Set-BannerEffect -BannerName 'OvBanner' -BannerH 200 -ColorHex '#FFFFFF' -Effect (Get-BannerFxFor -Game $global:OvBannerGame -Featured)
    }
    Build-OvGenreFilter
    Build-OvPowerFilter
    Build-OvPowerModeToggle
    $global:OvChromeBuilt = $true
}

# Synchronous full build - used when the user opens Explore before the
# background prewarm has finished. Chrome (once) + ALL genre rows in one
# go. Build-OvGenreRows clears the panel first, so it cleanly supersedes
# any partial rows the prewarm added; clearing OvPrewarmActive makes the
# prewarm's remaining queued steps bail via the OverviewBuilt guard.
function global:Build-DiscoverOverview {
    if ($global:OverviewBuilt) { return }
    Build-OverviewChrome
    Build-OvGenreRows
    $global:OvPrewarmActive = $false
    $global:OverviewBuilt = $true
}

# Background prewarm: one empty row or one tile per paced idle tick. The
# timer leaves room for frames and pauses while the user moves or types.
function global:Start-OverviewPrewarm {
    if ($global:OverviewBuilt -or $global:OvPrewarmActive) { return }
    # Lazy cards (test build): Explore is built from placeholders in a few
    # hundred ms on first open, so no background prewarm is needed at all.
    if ($global:HubLazyCards) { return }
    Build-OverviewChrome
    $panel = $window.FindName("OvGenreRows")
    if (-not $panel) { return }
    $panel.Children.Clear()
    $global:OvGenreRowsPanel = $panel
    $allGames = @()
    $allGames += $ownGames
    $allGames += $ownGamesGP
    $allGames += $externalGames
    $allGames = @($allGames | Where-Object { -not $_.UntestedInstaller })
    $global:OvAllGames = $allGames
    # The old all-genres plan blocked the dispatcher for hundreds of ms.
    # Prepare one genre per paced tick before creating its tiles.
    $global:OvPrewarmAllGames = $allGames
    $global:OvPrewarmPlan     = New-Object System.Collections.Generic.List[object]
    $global:OvPrewarmPlanGenreIndex = 0
    $global:OvPrewarmPlanning = $true
    $global:OvPrewarmGi       = 0       # index into $plan (current genre row)
    $global:OvPrewarmTi       = 0       # index into current row's Games (next tile)
    $global:OvPrewarmCurPanel = $null   # current row's tilesPanel
    $global:OvPrewarmActive   = $true
    if ($global:OvPrewarmTimer) { try { $global:OvPrewarmTimer.Stop() } catch { } }
    $global:OvPrewarmTimer = New-Object System.Windows.Threading.DispatcherTimer
    $global:OvPrewarmTimer.Interval = [TimeSpan]::FromMilliseconds(125)
    $global:OvPrewarmTimer.Add_Tick({
        if ($global:OverviewBuilt -or -not $global:window -or -not $global:window.IsVisible) {
            $global:OvPrewarmTimer.Stop()
            $global:OvPrewarmActive = $false
            return
        }
        if ($global:StartupOverviewLastInputAt -and
            (([DateTime]::UtcNow - $global:StartupOverviewLastInputAt).TotalSeconds -lt 2)) { return }
        Invoke-OverviewPrewarmStep
    })
    $global:OvPrewarmTimer.Start()
}

# One prewarm step does the SMALLEST unit of work possible - build a
# single empty row shell, or append ONE tile - then re-queues itself at
# Background priority. A tile costs ~30-50ms (its Add_ handlers) and
# Render outranks Background, so an animation frame paints between every
# tile and the banner effects keep moving instead of stuttering in big
# per-row chunks. If the user opens Explore first, Build-DiscoverOverview
# builds everything synchronously and these steps bail via OverviewBuilt.
function global:Invoke-OverviewPrewarmStep {
    if ($global:OverviewBuilt) { $global:OvPrewarmActive = $false; return }
    if ($global:OvPrewarmPlanning) {
        if ($global:OvPrewarmPlanGenreIndex -lt $global:OverviewGenres.Count) {
            $genre = $global:OverviewGenres[$global:OvPrewarmPlanGenreIndex]
            $genreGames = @()
            foreach ($g in $global:OvPrewarmAllGames) {
                if (Test-OverviewGameInGenre -Game $g -Genre $genre) { $genreGames += $g }
            }
            if ($genreGames.Count -gt 0) {
                $global:OvPrewarmPlan.Add([pscustomobject]@{ Genre = $genre; Games = $genreGames }) | Out-Null
            }
            $global:OvPrewarmPlanGenreIndex++
            return
        }
        $global:OvPrewarmPlanning = $false
        $global:OvPrewarmAllGames = $null
    }
    $plan = $global:OvPrewarmPlan
    if (-not $plan -or $global:OvPrewarmGi -ge $plan.Count) {
        $global:OverviewBuilt = $true
        $global:OvPrewarmActive = $false
        $global:OvPrewarmCurPanel = $null
        if ($global:OvPrewarmTimer) { $global:OvPrewarmTimer.Stop() }
        if (Get-Command Apply-CatalogSort -ErrorAction SilentlyContinue) {
            try { Apply-CatalogSort -Scope Explore -SkipFilter } catch { }
        }
        if (Get-Command Apply-OvFilters -ErrorAction SilentlyContinue) { try { Apply-OvFilters } catch { } }
        return
    }
    $entry = $plan[$global:OvPrewarmGi]
    try {
        if (-not $global:OvPrewarmCurPanel) {
            # Build the (empty) row shell and add it now, so the header +
            # arrows appear immediately; tiles stream in on later steps.
            $row = New-OvGenreRow -Genre $entry.Genre -Games $entry.Games -Deferred
            $global:OvGenreRowsPanel.Children.Add($row) | Out-Null
            $global:OvPrewarmCurPanel = $row.Resources.Item("tilesPanel")
            $global:OvPrewarmTi = 0
        } else {
            # Append exactly one tile to the current row.
            $games = $entry.Games
            if ($global:OvPrewarmTi -lt $games.Count) {
                $g = $games[$global:OvPrewarmTi]
                $tile = New-OverviewTile -Game $g
                $global:OvPrewarmCurPanel.Children.Add($tile) | Out-Null
                $global:OvPrewarmTi++
            }
            if ($global:OvPrewarmTi -ge $games.Count) {
                if (Get-Command Set-CatalogPanelOrder -ErrorAction SilentlyContinue) {
                    try { Set-CatalogPanelOrder -Panel $global:OvPrewarmCurPanel -Mode $global:CatalogSortMode } catch { }
                }
                # Row finished - advance to the next genre next step.
                $global:OvPrewarmGi++
                $global:OvPrewarmCurPanel = $null
            }
        }
    } catch {
        # On any error skip to the next genre so the prewarm can't wedge.
        $global:OvPrewarmGi++
        $global:OvPrewarmCurPanel = $null
    }
}

# Wire up the power-mode toggle pill. Click flips between cumulative
# ("Your PC") and exact ("Exact Tier") and refreshes both the label
# text and the filtered tile visibility. Subtle hover feedback so
# the user sees the pill is interactive.
# Shared neon-glass styling for the small Explore section-header pills
# (the "GENRE" label box and the "PC POWER ..." mode toggle) so the two
# read as a matched pair: orange accent glass + 1.5px border, with
# corner/padding and the inner text/chevron scaled to the Explore S/M/L
# setting from stored XAML base sizes (idempotent - never compounds).
# Handles a Border whose child is a single TextBlock (GENRE) or a
# StackPanel of TextBlocks + a chevron Path (the toggle).
function global:Set-OvHeaderPillStyle {
    param([System.Windows.Controls.Border]$Border)
    if (-not $Border) { return }
    $ac  = [System.Windows.Media.ColorConverter]::ConvertFromString("#ffaa66")
    $mkA = { param($a) [System.Windows.Media.Color]::FromArgb([byte]$a, $ac.R, $ac.G, $ac.B) }
    $mkGlass = {
        param($topA, $botA)
        $gb = New-Object System.Windows.Media.LinearGradientBrush
        $gb.StartPoint = New-Object System.Windows.Point 0, 0
        $gb.EndPoint   = New-Object System.Windows.Point 0, 1
        $gb.GradientStops.Add((New-Object System.Windows.Media.GradientStop ((& $mkA $topA), 0.0))) | Out-Null
        $gb.GradientStops.Add((New-Object System.Windows.Media.GradientStop ((& $mkA $botA), 1.0))) | Out-Null
        return $gb
    }
    $szKey = if ($global:ExploreSize) { $global:ExploreSize } else { "M" }
    $cfg = switch ($szKey) {
        "S"     { @{ Corner = 9;  PadX = 10; PadY = 4; Fac = 0.95 } }
        "L"     { @{ Corner = 12; PadX = 15; PadY = 7; Fac = 1.18 } }
        default { @{ Corner = 10; PadX = 12; PadY = 5; Fac = 1.0  } }
    }
    $Border.CornerRadius    = [System.Windows.CornerRadius]::new($cfg.Corner)
    $Border.Padding         = [System.Windows.Thickness]::new($cfg.PadX, $cfg.PadY, $cfg.PadX, $cfg.PadY)
    $Border.BorderThickness = [System.Windows.Thickness]::new(1.5)
    # No fill - just the outline. A filled box made these section
    # headers read like coloured category chips; the bare border keeps
    # them as quiet labels and cuts down on overall colour.
    $Border.Background      = [System.Windows.Media.Brushes]::Transparent
    $Border.BorderBrush     = New-Object System.Windows.Media.SolidColorBrush (& $mkA 120)
    $kids = New-Object System.Collections.ArrayList
    $child = $Border.Child
    if ($child -is [System.Windows.Controls.TextBlock]) {
        [void]$kids.Add($child)
    } elseif ($child -and $child.Children) {
        foreach ($el in $child.Children) { [void]$kids.Add($el) }
    }
    foreach ($el in $kids) {
        if ($el -is [System.Windows.Controls.TextBlock]) {
            if (-not $el.Resources.Contains("baseFs")) { $el.Resources.Add("baseFs", [double]$el.FontSize) }
            $el.FontSize = [double]$el.Resources.Item("baseFs") * $cfg.Fac
        } elseif ($el -is [System.Windows.Shapes.Path]) {
            if (-not $el.Resources.Contains("baseW")) {
                $el.Resources.Add("baseW", [double]$el.Width)
                $el.Resources.Add("baseH", [double]$el.Height)
            }
            $el.Width  = [double]$el.Resources.Item("baseW") * $cfg.Fac
            $el.Height = [double]$el.Resources.Item("baseH") * $cfg.Fac
        }
    }
}

function global:Apply-OvPowerModeToggleStyle {
    # S/M/L change: rebuild the segment at the new size.
    Build-OvPowerModeToggle
}

# Two-option segment "Up to my PC" (cumulative) / "Exact tier" (exact).
# Apply-OvFilters reads $global:OvPowerMode together with
# $global:OvActivePower; ALL ("Any") bypasses both modes.
function global:Build-OvPowerModeToggle {
    $seg = $window.FindName("OvPowerModeSeg")
    if (-not $seg) { return }
    $seg.Children.Clear()
    $m = Get-OvPowerRowMetrics
    $opts = @(
        @{ Mode = "cumulative"; Label = "Up to my PC"; Tip = "Show every game your PC can run: this tier and all lower ones" },
        @{ Mode = "exact";      Label = "Exact tier";  Tip = "Show only games of exactly this tier" }
    )
    foreach ($o in $opts) {
        $b = New-Object System.Windows.Controls.Border
        $b.Height = $m.ModeH
        $b.CornerRadius = [System.Windows.CornerRadius]::new(7)
        $b.Padding = [System.Windows.Thickness]::new(12, 0, 12, 0)
        $b.Cursor = [System.Windows.Input.Cursors]::Hand
        $b.ToolTip = $o.Tip
        $t = New-Object System.Windows.Controls.TextBlock
        $t.Text = $o.Label
        $t.FontSize = $m.ModeFont
        $t.FontWeight = [System.Windows.FontWeights]::SemiBold
        $t.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $t.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $b.Child = $t
        $b.Resources.Add("powerMode", $o.Mode)
        $b.Resources.Add("modeText", $t)
        $b.Resources.Add("pressed", $false)
        $b.Add_MouseEnter({
            if ($this.Resources.Item("powerMode") -ne $global:OvPowerMode) {
                $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1b1b22")
            }
            $this.Resources.Item("modeText").Foreground = [System.Windows.Media.Brushes]::White
        })
        $b.Add_MouseLeave({
            $this.Resources["pressed"] = $false
            Update-OvPowerModeLabel
        })
        $b.Add_MouseLeftButtonDown({
            $this.Resources["pressed"] = $true
            $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#101014")
        })
        $b.Add_MouseLeftButtonUp({
            if (-not [bool]$this.Resources["pressed"]) { return }
            $this.Resources["pressed"] = $false
            $global:OvPowerMode = $this.Resources.Item("powerMode")
            Update-OvPowerModeLabel
            Apply-OvFilters
        })
        $seg.Children.Add($b) | Out-Null
    }
    $global:OvPowerModeToggleBorder = $window.FindName("OvPowerModeToggle")
    $global:OvPowerModeSegPanel = $seg
    Update-OvPowerModeLabel
}

# Repaint the mode segment for the current $global:OvPowerMode.
function global:Update-OvPowerModeLabel {
    $mode = if ($global:OvPowerMode -eq "exact") { "exact" } else { "cumulative" }
    if ($global:OvPowerModeSegPanel) {
        $bc = [System.Windows.Media.BrushConverter]::new()
        foreach ($b in $global:OvPowerModeSegPanel.Children) {
            $t = $b.Resources.Item("modeText")
            if ($b.Resources.Item("powerMode") -eq $mode) {
                $b.Background = $bc.ConvertFromString("#26262e")
                $t.Foreground = [System.Windows.Media.Brushes]::White
            } else {
                $b.Background = [System.Windows.Media.Brushes]::Transparent
                $t.Foreground = $bc.ConvertFromString("#a8a8b2")
            }
        }
    }
    # The GPU rating only makes sense in cumulative ("Up to my PC") mode.
    if (Get-Command Update-OvGpuRateVisibility -ErrorAction SilentlyContinue) {
        Update-OvGpuRateVisibility
    }
}

function global:Show-DiscoverOverview {
    param([string]$Origin = "TILES")
    if (Get-Command Request-HeaderBackArrowUpdate -ErrorAction SilentlyContinue) { Request-HeaderBackArrowUpdate }
    # Manual navigation invalidates the forward stack (same as
    # the corresponding logic in Show-DiscoverDetail).
    if ($global:NavForwardStack -and -not $global:NavSuppressForwardClear) {
        $global:NavForwardStack.Clear()
    }
    # Track where the user came from so the back button knows
    # where to return to. Origin is "LIST" if the user opened
    # Explore from the VR-mod-list banner, "TILES" otherwise.
    $global:OverviewOrigin = $Origin
    Build-DiscoverOverview
    # Update the banner's back-button label to match origin.
    if ($global:OverviewBackText) {
        $global:OverviewBackText.Text = if ($Origin -eq "LIST") {
            "Back to mod list"
        } else {
            "Back to library"
        }
    }
    $global:discoverDetail.Visibility    = [System.Windows.Visibility]::Collapsed
    $global:discoverTiles.Visibility     = [System.Windows.Visibility]::Collapsed
    $global:discoverOverview.Visibility  = [System.Windows.Visibility]::Visible
    $global:discoverHost.Visibility      = [System.Windows.Visibility]::Visible
    # Safety sweep: finalize any click-pulse glow that may still be in
    # flight (or stuck) on a card from before we navigated away. The
    # cards are built once and reused, so without this a pulse left on a
    # card would persist - and an Effect on the card Border rasterizes
    # its title into the washed-out, ClearType-less look. Forcing the
    # resolve here makes returning to the grid always glow-clean.
    if ($global:cardGameMap -and (Get-Command Resolve-CardClickGlow -ErrorAction SilentlyContinue)) {
        foreach ($c in @($global:cardGameMap.Keys)) { Resolve-CardClickGlow -Card $c }
    }
    if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Collapsed }
    if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
    if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
    if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
    if (Get-Command Apply-ExploreSize -ErrorAction SilentlyContinue) { Apply-ExploreSize $global:ExploreSize }
}

# Back button - returns to whichever view spawned the overview.
function global:Hide-DiscoverOverview {
    $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed
    $global:discoverDetail.Visibility   = [System.Windows.Visibility]::Collapsed
    if (Get-Command Request-HeaderBackArrowUpdate -ErrorAction SilentlyContinue) { Request-HeaderBackArrowUpdate }
    if ($global:OverviewOrigin -eq "LIST") {
        # Return to the VR-mod list view.
        $global:discoverHost.Visibility = [System.Windows.Visibility]::Collapsed
        if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Visible }
    } else {
        # Default: return to the portrait library (tiles).
        $global:discoverTiles.Visibility = [System.Windows.Visibility]::Visible
        $global:discoverHost.Visibility  = [System.Windows.Visibility]::Visible
        if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Collapsed }
        Build-DiscoverTiles
        Refresh-DiscoverStatuses
    }
    if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
    if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
    if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
}

# Called from list-card click - opens Discover and goes straight
# to the detail view of the clicked game.
function global:Open-DiscoverDetailFromList {
    param($Game)
    $global:DetailOrigin = "LIST"
    Build-DiscoverTiles
    Refresh-DiscoverStatuses
    $global:discoverHost.Visibility = [System.Windows.Visibility]::Visible
    if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Collapsed }
    Update-FilterBarForMode
    Update-DiscoverBtnState
    Show-DiscoverDetail -Game $Game
}

# Toggle handler
$global:ViewSwitchQueued = $false
$discoverBtn.Add_PreviewMouseLeftButtonDown({
    if ($global:ViewSwitchQueued) { return }
    $switchToken = Start-ViewSwitchIndicator
    $global:ViewSwitchQueued = $true
    try {
    # As with Scan games, let WPF render the lit glyph before any synchronous
    # tile building or status refresh blocks the UI dispatcher.
    [void]$window.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Input,
        [Action]{
    $switchCompleted = $false
    try {
    # A detail/overview sub-view lives INSIDE discoverHost, so the
    # toggle below only collapses the host and leaves the description
    # page (and its filter-pill selection) alive underneath - it stays
    # "stuck". Tear the sub-view down first, exactly like the header
    # Back button does, so Hide-DiscoverDetail -> Restore-FilterPills
    # resets the pills and the detail does not linger.
    if ($global:discoverDetail -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
        if (Get-Command Hide-DiscoverDetail -ErrorAction SilentlyContinue) { Hide-DiscoverDetail }
        return
    }
    if ($global:discoverOverview -and $global:discoverOverview.Visibility -eq [System.Windows.Visibility]::Visible) {
        if (Get-Command Hide-DiscoverOverview -ErrorAction SilentlyContinue) { Hide-DiscoverOverview }
        return
    }
    if ($global:discoverHost.Visibility -eq [System.Windows.Visibility]::Visible) {
        if ($global:HoverMediaElement) {
            try { $global:HoverMediaElement.Stop()  } catch { }
            try { $global:HoverMediaElement.Close() } catch { }
            $global:HoverMediaElement.Source = $null
            $global:HoverMediaElement = $null
        }
        $global:discoverHost.Visibility = [System.Windows.Visibility]::Collapsed
        if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Visible }
        Update-FilterBarForMode
        Update-DiscoverBtnState
        if (Get-Command Apply-Filter -ErrorAction SilentlyContinue) { Apply-Filter }
        if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
        # Remember the view, exactly like S/M/L does, so someone who only
        # uses one of the two lands there again after a restart.
        if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
            Set-HubSetting -Key "startView" -Value "LIST"
        }
    } else {
        Build-DiscoverTiles
        Refresh-DiscoverStatuses
        $global:discoverDetail.Visibility = [System.Windows.Visibility]::Collapsed
        if ($global:discoverOverview) {
            $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed
        }
        $global:discoverTiles.Visibility  = [System.Windows.Visibility]::Visible
        $global:discoverHost.Visibility = [System.Windows.Visibility]::Visible
        if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Collapsed }
        Update-FilterBarForMode
        Update-DiscoverBtnState
        if (Get-Command Apply-Filter -ErrorAction SilentlyContinue) { Apply-Filter }
        if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
        if (Get-Command Apply-LibrarySize -ErrorAction SilentlyContinue) { Apply-LibrarySize $global:LibrarySize }
        if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
            Set-HubSetting -Key "startView" -Value "LIBRARY"
        }
    }
    $switchCompleted = $true
    } finally {
        Stop-ViewSwitchIndicator -Token $switchToken -Immediate:(-not $switchCompleted)
        $global:ViewSwitchQueued = $false
    }
        }.GetNewClosure())
    } catch {
        $global:ViewSwitchQueued = $false
        Stop-ViewSwitchIndicator -Token $switchToken -Immediate
        throw
    }
})
