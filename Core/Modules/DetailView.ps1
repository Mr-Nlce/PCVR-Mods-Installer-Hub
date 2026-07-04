# Subtle scale-up on hover for non-clickable elements (hero
# banner, description images, info pills). RenderTransform = no
# layout shift, no clipping issues. Origin centered.
function global:Add-HoverScale {
    param($Element, [double]$Scale = 1.02)
    if (-not $Element) { return }
    $s = $Scale
    $Element.Add_MouseEnter({
        $sc = New-Object System.Windows.Media.ScaleTransform $s, $s
        $this.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
        $this.RenderTransform = $sc
    }.GetNewClosure())
    $Element.Add_MouseLeave({
        $this.RenderTransform = $null
    })
}

function global:New-DiscoverTile {
    param($Game)
    $tile = New-Object System.Windows.Controls.Border
    # Portrait library capsule (2:3, matches Steam library_600x900).
    # Size driven by the user-selected S/M/L preference.
    $sizeKey = if ($global:DiscoverTileSize) { $global:DiscoverTileSize } else { "L" }
    $dim = $global:DiscoverTileSizes[$sizeKey]
    $tile.Width  = $dim.W
    $tile.Height = $dim.H
    # Vertical margin big enough that the hover glow (drop-shadow,
    # blur radius 14) can render above and below the tile without
    # being clipped by the row above/the WrapPanel itself. Same
    # fix used by the Explore tiles - without the top margin the
    # glow only reads on the left/right/bottom sides.
    $tile.Margin = [System.Windows.Thickness]::new(0, 14, 14, 14)
    # The outer tile is now a bare, non-clipping, transparent container so
    # the hover glow (which lives on the $glowFrame layer below) can bloom
    # OUTSIDE the rounded rectangle. The visible rounded frame + background
    # moved down to $glowFrame; the portrait + tags live in $contentFrame
    # which carries NO effect, so they never get rasterized / washed out on
    # hover. Only the frame glows; image and tags stay crisp.
    $tile.CornerRadius = [System.Windows.CornerRadius]::new(0)
    $tile.Background   = [System.Windows.Media.Brushes]::Transparent
    $tile.BorderThickness = [System.Windows.Thickness]::new(0)
    $tile.Cursor = [System.Windows.Input.Cursors]::Hand
    # The vertical margin (above) gives the bloom room so neighbor tiles in
    # the WrapPanel don't shave it. ClipToBounds MUST stay false so the
    # glow can extend past the tile bounds.
    $tile.ClipToBounds = $false

    $root = New-Object System.Windows.Controls.Grid
    $root.ClipToBounds = $false
    $tile.Child = $root

    # Bottom layer: the visible rounded frame + background. The hover
    # DropShadowEffect is attached HERE (see below), so only this empty
    # frame is rasterized when the glow lights up - never the content.
    $glowFrame = New-Object System.Windows.Controls.Border
    $glowFrame.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $glowFrame.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161a")
    $glowFrame.BorderThickness = [System.Windows.Thickness]::new(1)
    $glowFrame.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a32")
    $root.Children.Add($glowFrame) | Out-Null

    # Top layer: rounds + clips the portrait and its tag overlays. NO
    # effect here, so ClearType text (tags/title) and the image stay sharp.
    $contentFrame = New-Object System.Windows.Controls.Border
    $contentFrame.CornerRadius = [System.Windows.CornerRadius]::new(8)
    $contentFrame.ClipToBounds = $true
    $contentFrame.Margin = [System.Windows.Thickness]::new(1)
    $root.Children.Add($contentFrame) | Out-Null

    $grid = New-Object System.Windows.Controls.Grid
    $grid.ClipToBounds = $true
    $contentFrame.Child = $grid

    # Resolve portrait image: respects PortraitUrl override, then SteamId default.
    $portraitUrl = Get-GameImageUrl -Game $Game -Kind "portrait"
    $headerUrl   = Get-GameImageUrl -Game $Game -Kind "header"
    # Prefer the local disk cache if present - loads synchronously.
    if ($Game.SteamId -and -not $Game.PortraitUrl) {
        $cachedPortrait = Get-CachedImageUri -SteamId $Game.SteamId -Kind "portrait"
        if ($cachedPortrait) { $portraitUrl = $cachedPortrait }
    }

    if ($portraitUrl) {
        $img = New-Object System.Windows.Controls.Image
        $img.Stretch = [System.Windows.Media.Stretch]::UniformToFill
        try {
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $bmp.UriSource = New-Object System.Uri $portraitUrl
            $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            # If the portrait fails (older Steam titles often miss
            # library_600x900.jpg), fall back through:
            # fastly portrait -> akamai header -> fastly header.
            $hdrCap   = $headerUrl
            $sidCap   = $Game.SteamId
            $imgRef   = $img
            $bmp.Add_DownloadFailed({
                param($s, $e)
                # Try fastly portrait
                if ($sidCap) {
                    try {
                        $hb = New-Object System.Windows.Media.Imaging.BitmapImage
                        $hb.BeginInit()
                        $hb.UriSource = New-Object System.Uri (Get-SteamPortraitUrlFastly $sidCap)
                        $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                        $hb.EndInit()
                        if ($hb.CanFreeze) { $hb.Freeze() }
                        $imgRef.Source = $hb
                        $imgRef.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                        return
                    } catch { }
                }
                # Then akamai header
                if ($hdrCap) {
                    try {
                        $hb = New-Object System.Windows.Media.Imaging.BitmapImage
                        $hb.BeginInit()
                        $hb.UriSource = New-Object System.Uri $hdrCap
                        $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                        $hb.EndInit()
                        if ($hb.CanFreeze) { $hb.Freeze() }
                        $imgRef.Source = $hb
                        $imgRef.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                        return
                    } catch { }
                }
                # Lastly fastly header
                if ($sidCap) {
                    try {
                        $hb = New-Object System.Windows.Media.Imaging.BitmapImage
                        $hb.BeginInit()
                        $hb.UriSource = New-Object System.Uri (Get-SteamHeaderUrlFastly $sidCap)
                        $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                        $hb.EndInit()
                        if ($hb.CanFreeze) { $hb.Freeze() }
                        $imgRef.Source = $hb
                        $imgRef.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                    } catch { }
                }
            }.GetNewClosure())
            $bmp.EndInit()
            if ($bmp.CanFreeze) { $bmp.Freeze() }
            $img.Source = $bmp
        } catch { }
        $grid.Children.Add($img) | Out-Null

        # Strong bottom gradient so title overlay stays readable
        $gradRect = New-Object System.Windows.Shapes.Rectangle
        $gradRect.Height = 110
        $gradRect.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
        $gb = New-Object System.Windows.Media.LinearGradientBrush
        $gb.StartPoint = New-Object System.Windows.Point 0, 0
        $gb.EndPoint   = New-Object System.Windows.Point 0, 1
        $gb.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,0,0,0)), 0.0)) | Out-Null
        $gb.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(230,10,10,12)), 1.0)) | Out-Null
        $gradRect.Fill = $gb
        $grid.Children.Add($gradRect) | Out-Null
    } else {
        $accentHex = if ($Game.Accent) { $Game.Accent } else { "#445566" }
        $glowFrame.Background = New-CardTintBrush -BaseHex "#16161a" -TintHex $accentHex -TopAlpha 0.20 -MidAlpha 0.06
    }

    # Title overlay at bottom-left
    $titleStack = New-Object System.Windows.Controls.StackPanel
    $titleStack.Margin = [System.Windows.Thickness]::new(14, 0, 14, 12)
    $titleStack.VerticalAlignment   = [System.Windows.VerticalAlignment]::Bottom
    $titleStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left

    $accentHex = if ($Game.Accent) { $Game.Accent } else { "#666677" }
    $famAcc = ConvertTo-MediaColor $accentHex
    $famBg  = ConvertTo-MediaColor "#16161a"
    $pillColor = [System.Windows.Media.Color]::FromArgb(
        220,
        [byte]([Math]::Round($famAcc.R*0.65 + $famBg.R*0.35)),
        [byte]([Math]::Round($famAcc.G*0.65 + $famBg.G*0.35)),
        [byte]([Math]::Round($famAcc.B*0.65 + $famBg.B*0.35))
    )

    # Controls pill above the title - native hub colors so it
    # matches the filter buttons in the header.
    # Motion=#44cc66 (green), Gamepad=#dd6600 (orange).
    $ctrlLabelTile = switch ($Game.Controls) {
        "MC"   { "MOTION" }
        "GP"   { "GAMEPAD" }
        "BOTH" { "BOTH" }
        default { "" }
    }
    $ctrlPillBgHex = switch ($Game.Controls) {
        "MC"   { "#44cc66" }
        "GP"   { "#dd6600" }
        "BOTH" { "#8888ff" }
        default { "#888888" }
    }
    $ctrlPillFgHex = switch ($Game.Controls) {
        "MC"   { "#0a1a0a" }
        default { "#ffffff" }
    }
    if ($ctrlLabelTile) {
        $ctrlPillTile = New-Object System.Windows.Controls.Border
        $ctrlPillTile.CornerRadius = [System.Windows.CornerRadius]::new(2)
        $ctrlPillTile.Padding = [System.Windows.Thickness]::new(5, 1, 5, 1)
        $ctrlPillTile.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $ctrlPillTile.Margin = [System.Windows.Thickness]::new(0, 0, 0, 5)
        $ctrlPillTile.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ctrlPillBgHex)
        $ctrlTxtTile = New-Object System.Windows.Controls.TextBlock
        $ctrlTxtTile.Text = $ctrlLabelTile
        $ctrlTxtTile.FontSize = 8
        $ctrlTxtTile.FontWeight = [System.Windows.FontWeights]::SemiBold
        $ctrlTxtTile.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ctrlPillFgHex)
        $ctrlTxtTile.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $ctrlPillTile.Child = $ctrlTxtTile
        $titleStack.Children.Add($ctrlPillTile) | Out-Null
    }

    $titleTxt = New-Object System.Windows.Controls.TextBlock
    $titleTxt.Text = $Game.Title
    $titleTxt.FontSize = 14
    $titleTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $titleTxt.Foreground = [System.Windows.Media.Brushes]::White
    $titleTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $titleTxt.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $ts = New-Object System.Windows.Media.Effects.DropShadowEffect
    $ts.Color = [System.Windows.Media.Color]::FromRgb(0,0,0)
    $ts.BlurRadius = 6; $ts.ShadowDepth = 1; $ts.Opacity = 0.95
    $titleTxt.Effect = $ts
    $titleStack.Children.Add($titleTxt) | Out-Null

    $grid.Children.Add($titleStack) | Out-Null

    # Status badge top-right (filled at runtime from gameStateMap)
    $statusPill = New-Object System.Windows.Controls.Border
    $statusPill.CornerRadius = [System.Windows.CornerRadius]::new(3)
    $statusPill.Padding = [System.Windows.Thickness]::new(7, 2, 7, 2)
    $statusPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $statusPill.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
    $statusPill.Margin = [System.Windows.Thickness]::new(0, 10, 10, 0)
    $statusPill.Visibility = [System.Windows.Visibility]::Collapsed
    $statusTxt = New-Object System.Windows.Controls.TextBlock
    $statusTxt.FontSize = 9
    $statusTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $statusTxt.Foreground = [System.Windows.Media.Brushes]::White
    $statusTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $statusPill.Child = $statusTxt
    $grid.Children.Add($statusPill) | Out-Null

    # FREE pill top-left for free-to-play games (via
    # $global:FREE_GAME_TITLES). It lies over the cover art, so it
    # carries a drop shadow (same idea as the title text already
    # uses) to lift it off busy box-art and stay readable even when
    # the art bakes the game title into the top of the image
    # (e.g. I Can Gun VR). No solid fill behind it.
    if ($global:FREE_GAME_TITLES -and ($global:FREE_GAME_TITLES -contains $Game.Title)) {
        $freePillPt = New-Object System.Windows.Controls.Border
        $freePillPt.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $freePillPt.Padding = [System.Windows.Thickness]::new(7, 2, 7, 2)
        $freePillPt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $freePillPt.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
        $freePillPt.Margin = [System.Windows.Thickness]::new(10, 10, 0, 0)
        $freePillPt.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(20, 52, 211, 153))
        $freePillPt.BorderThickness = [System.Windows.Thickness]::new(1)
        $freePillPt.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freeShadowPt = New-Object System.Windows.Media.Effects.DropShadowEffect
        $freeShadowPt.Color = [System.Windows.Media.Color]::FromRgb(0, 0, 0)
        $freeShadowPt.BlurRadius = 6
        $freeShadowPt.ShadowDepth = 1
        $freeShadowPt.Opacity = 0.9
        $freePillPt.Effect = $freeShadowPt
        $freeTxtPt = New-Object System.Windows.Controls.TextBlock
        $freeTxtPt.Text = "FREE"
        $freeTxtPt.FontSize = 9
        $freeTxtPt.FontWeight = [System.Windows.FontWeights]::Bold
        $freeTxtPt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freeTxtPt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $freePillPt.Child = $freeTxtPt
        $grid.Children.Add($freePillPt) | Out-Null
    }

    $tile.Resources.Add("statusPill", $statusPill)
    $tile.Resources.Add("statusTxt",  $statusTxt)
    $tile.Resources.Add("game",       $Game)

    # Press-flash overlay tinted in the game's own accent color.
    # Sits on top of the image + status pill (added last = top of
    # z-order). Hidden until press (Opacity=0).
    $flash = New-Object System.Windows.Shapes.Rectangle
    $flashHex = if ($Game.Accent) { $Game.Accent } else { "#ffcc66" }
    $flash.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($flashHex)
    $flash.Opacity = 0
    $flash.IsHitTestVisible = $false
    $flash.RadiusX = 8
    $flash.RadiusY = 8
    $grid.Children.Add($flash) | Out-Null
    $tile.Resources.Add("flash", $flash)

    $gameCapture = $Game
    $flashCap = $flash
    $tile.Add_MouseLeftButtonUp({
        # Do NOT reset flash/scale here - they must stay visible
        # during the defer below until the new page actually loads.
        $global:DetailOrigin = "TILES"
        Invoke-DeferredAction -DelayMs 800 -Action { Show-DiscoverDetail -Game $gameCapture }
    }.GetNewClosure())

    # Press: tinted overlay flash at 10% opacity. Tag marks the
    # tile as "pressed" so MouseLeave doesn't tear down the visual
    # feedback while the page is loading. Auto-reset timer fires
    # after 2.6s no matter what - prevents stuck state when the
    # user returns from the detail page.
    # Accent-colored glow on hover - same pattern as the explore-
    # area tiles in OverviewPage.ps1. Pre-brighten the accent 50%
    # toward white so dark accents still read as a halo. Effect is
    # pre-attached at Opacity=0 (no perf cost) and faded in on
    # MouseEnter, reset on MouseLeave + the press-auto-reset timer.
    $accentRawDt = if ($Game.Accent) { $Game.Accent } else { "#ffcc66" }
    $accentColorDt = [System.Windows.Media.ColorConverter]::ConvertFromString($accentRawDt)
    $glowRDt = [byte]([Math]::Round($accentColorDt.R * 0.5 + 255 * 0.5))
    $glowGDt = [byte]([Math]::Round($accentColorDt.G * 0.5 + 255 * 0.5))
    $glowBDt = [byte]([Math]::Round($accentColorDt.B * 0.5 + 255 * 0.5))
    $glowColorDt = [System.Windows.Media.Color]::FromRgb($glowRDt, $glowGDt, $glowBDt)
    $glowDt = New-Object System.Windows.Media.Effects.DropShadowEffect
    $glowDt.Color = $glowColorDt
    $glowDt.BlurRadius = 14
    $glowDt.ShadowDepth = 0
    $glowDt.Opacity = 0
    $glowFrame.Effect = $glowDt
    $tile.Resources.Add("glow", $glowDt)
    $tile.Resources.Add("glowFrame", $glowFrame)
    $glowCapDt = $glowDt

    $tile.Add_MouseLeftButtonDown({
        $flashCap.Opacity = 0.10
        $this.Tag = "pressed"
        $tileCap = $this
        $fcap = $flashCap
        # Capture the per-tile glow so the auto-reset timer can
        # clear it regardless of where the mouse ended up.
        $gcap = $this.Resources["glow"]
        $gfcap = $this.Resources["glowFrame"]
        $resetT = New-Object System.Windows.Threading.DispatcherTimer
        $resetT.Interval = [TimeSpan]::FromMilliseconds(2600)
        $resetT.Add_Tick({
            $this.Stop()
            $fcap.Opacity = 0
            $tileCap.Tag = $null
            $tileCap.RenderTransform = $null
            if ($gfcap) { $gfcap.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a32") }
            if ($gcap) { $gcap.Opacity = 0 }
        }.GetNewClosure())
        $resetT.Start()
    }.GetNewClosure())

    $tile.Add_MouseEnter({
        # Hover parity with the Explore genre-row tiles
        # (New-OverviewTile): hide the static border so ONLY the
        # accent glow reads, scale 1.06, light the glow at 0.95.
        # The grey #4a4a55 border used to mute the bloom - dropping
        # it to Transparent is what makes the accent colour glow
        # much more and stand out, matching the explore list.
        $sc = New-Object System.Windows.Media.ScaleTransform 1.06, 1.06
        $this.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
        $this.RenderTransform = $sc
        $gf = $this.Resources["glowFrame"]
        if ($gf) { $gf.BorderBrush = [System.Windows.Media.Brushes]::Transparent }
        $g = $this.Resources["glow"]
        if ($g) { $g.Opacity = 0.95 }
    })
    $tile.Add_MouseLeave({
        # Skip reset if pressed - press state persists until the
        # auto-reset timer clears it.
        if ($this.Tag -eq "pressed") { return }
        $gf = $this.Resources["glowFrame"]
        if ($gf) { $gf.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a32") }
        $this.RenderTransform = $null
        $g = $this.Resources["glow"]
        if ($g) { $g.Opacity = 0 }
    }.GetNewClosure())

    return $tile
}

function global:Update-DiscoverTileStatus {
    param($Tile)
    $g = $Tile.Resources.Item("game")
    if (-not $g.Title) { return }
    $state = $global:gameStateMap[$g.Title]
    $pill = $Tile.Resources.Item("statusPill")
    $txt  = $Tile.Resources.Item("statusTxt")
    if (-not $state -or -not $pill) {
        if ($pill) { $pill.Visibility = [System.Windows.Visibility]::Collapsed }
        return
    }
    $pill.Visibility = [System.Windows.Visibility]::Visible
    switch ($state.State) {
        "ready"     { $txt.Text = "VR READY"; $pill.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a6e3a") }
        "update"    { $txt.Text = "UPDATE";   $pill.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cc6600") }
        "installed" { $txt.Text = "INSTALLED"; $pill.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48") }
        default     { $pill.Visibility = [System.Windows.Visibility]::Collapsed }
    }
}

# Helper: build a stylized info section (heading + body bullets/lines)
# Render the PC Power Scale gauge for a game in the Discover detail
# view. Returns a Border element matching the "Bar gauge" mockup:
# heading row + 6-segment bar with marker(s) + tier labels + GPU/CPU
# sub-panel. A single-tier game gets one marker, a range game gets
# a span between two markers. The active tier(s) are tinted with a
# blue accent ramp for visual continuity with the rest of the UI.
function global:New-PowerScaleBlock {
    param($Game)
    $tier = Get-PowerTier -Game $Game

    # Container card
    $card = New-Object System.Windows.Controls.Border
    $card.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#13131a")
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
    $card.Padding = [System.Windows.Thickness]::new(14, 12, 14, 12)
    $card.Margin = [System.Windows.Thickness]::new(0, 0, 0, 14)

    $stack = New-Object System.Windows.Controls.StackPanel
    $card.Child = $stack

    # ---- Heading row ----
    $headRow = New-Object System.Windows.Controls.DockPanel
    $headRow.LastChildFill = $false
    $headRow.Margin = [System.Windows.Thickness]::new(0, 0, 0, 12)

    $headLeft = New-Object System.Windows.Controls.TextBlock
    $headLeft.Text = "PC Power"
    $headLeft.FontSize = 14
    $headLeft.FontWeight = [System.Windows.FontWeights]::SemiBold
    $headLeft.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cccccc")
    $headLeft.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    [System.Windows.Controls.DockPanel]::SetDock($headLeft, [System.Windows.Controls.Dock]::Left)
    $headRow.Children.Add($headLeft) | Out-Null

    $headRight = New-Object System.Windows.Controls.TextBlock
    if ($tier.IsRange) {
        $headRight.Text = "$($global:PowerTiers[$tier.StartIdx].Label) -> $($global:PowerTiers[$tier.EndIdx].Label)"
    } else {
        $headRight.Text = $global:PowerTiers[$tier.StartIdx].Label
    }
    $headRight.FontSize = 13
    $headRight.FontWeight = [System.Windows.FontWeights]::SemiBold
    $headRight.Foreground = [System.Windows.Media.Brushes]::White
    $headRight.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    [System.Windows.Controls.DockPanel]::SetDock($headRight, [System.Windows.Controls.Dock]::Right)
    $headRow.Children.Add($headRight) | Out-Null
    $stack.Children.Add($headRow) | Out-Null

    # ---- 6-segment bar with marker(s) ----
    # Use a Grid that overlays the segment row + the marker triangle(s).
    $barHost = New-Object System.Windows.Controls.Grid
    $barHost.Height = 18
    $barHost.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)

    # Segments: a 6-column UniformGrid for equal widths
    $segGrid = New-Object System.Windows.Controls.Primitives.UniformGrid
    $segGrid.Rows = 1
    $segGrid.Columns = 6
    $segGrid.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
    $segGrid.Height = 8

    # Active blue ramp (lightest -> darkest as tier index goes up)
    # so the gauge has a natural "fuller = stronger" gradient feel.
    # Inactive segments use a dark slate.
    $activeColors = @(
        "#2a3a48",  # 0 LOW (dim slate-blue)
        "#3a5a78",  # 1 BASIC
        "#4a7aa0",  # 2 SOLID
        "#6a9ad8",  # 3 STRONG
        "#85b3e8",  # 4 HIGH
        "#a8c8f5"   # 5 EXTREME
    )
    $inactiveColor = "#2a2a32"

    # Active segments collected so we can animate them on hover
    # (wave-cascade effect, see card.Add_MouseEnter below).
    $activeSegments = New-Object System.Collections.Generic.List[object]

    for ($i = 0; $i -lt 6; $i++) {
        $seg = New-Object System.Windows.Controls.Border
        $seg.Height = 8
        $isActive = ($i -ge $tier.StartIdx) -and ($i -le $tier.EndIdx)
        # Also fill segments BELOW the start to give a "fill up to here"
        # gauge feel. Without this the bar would have isolated colored
        # cells which reads as broken.
        $isFilled = ($i -le $tier.EndIdx)
        $col = if ($isFilled) { $activeColors[$i] } else { $inactiveColor }
        $seg.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($col)
        # Side margins to make the segments visually distinct (the
        # mockup used 2px gaps via flex - we get the same with margin)
        $seg.Margin = [System.Windows.Thickness]::new(1, 0, 1, 0)
        # Round the very first/last so the bar reads as a pill
        if ($i -eq 0) {
            $seg.CornerRadius = [System.Windows.CornerRadius]::new(2, 0, 0, 2)
            $seg.Margin = [System.Windows.Thickness]::new(0, 0, 1, 0)
        } elseif ($i -eq 5) {
            $seg.CornerRadius = [System.Windows.CornerRadius]::new(0, 2, 2, 0)
            $seg.Margin = [System.Windows.Thickness]::new(1, 0, 0, 0)
        }
        # Each segment scales from its bottom edge during the wave
        # so the "rise" reads as the bar bulging upward, not floating.
        $segScale = New-Object System.Windows.Media.ScaleTransform 1, 1
        $seg.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 1.0
        $seg.RenderTransform = $segScale
        if ($isFilled) { $activeSegments.Add($seg) | Out-Null }
        $segGrid.Children.Add($seg) | Out-Null
    }
    $barHost.Children.Add($segGrid) | Out-Null

    # Marker(s): we draw a downward-pointing triangle ABOVE the bar
    # that "points to" the active segment. For a range we draw two
    # markers at the bounds. Done with a Path geometry so we can
    # position-precisely as a fraction of the bar width.
    function New-MarkerTriangle {
        $p = New-Object System.Windows.Shapes.Path
        $p.Fill = [System.Windows.Media.Brushes]::White
        $p.Data = [System.Windows.Media.Geometry]::Parse("M 0,0 L 12,0 L 6,8 Z")
        $p.Width = 12
        $p.Height = 8
        $p.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $p.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
        return $p
    }

    # Position the marker once layout is known and re-position on
    # resize. We always render exactly one marker - for range tiers
    # (e.g. "SOLID -> STRONG") the marker sits at the midpoint
    # between the two tier centers, which reads as "somewhere in
    # this band" without cluttering the bar with two arrows.
    $markerCanvas = New-Object System.Windows.Controls.Canvas
    $markerCanvas.Height = 8
    $markerCanvas.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    $startIdx = $tier.StartIdx
    $endIdx   = $tier.EndIdx

    $m1 = New-MarkerTriangle
    # TranslateTransform lets the hover animation lift the marker
    # upward (it "jumps" toward the bar) and pulse there.
    $markerLift = New-Object System.Windows.Media.TranslateTransform 0, 0
    $m1.RenderTransform = $markerLift
    $markerCanvas.Children.Add($m1) | Out-Null

    $segGrid.Add_SizeChanged({
        param($s, $e)
        $w = $e.NewSize.Width
        if ($w -le 0) { return }
        $segW = $w / 6.0
        $startCenter = $startIdx * $segW + ($segW / 2.0)
        $endCenter   = $endIdx   * $segW + ($segW / 2.0)
        # Midpoint of the range (== startCenter for single-tier games)
        $markerX = ($startCenter + $endCenter) / 2.0
        [System.Windows.Controls.Canvas]::SetLeft($m1, $markerX - 6)
    }.GetNewClosure())

    $barHost.Children.Add($markerCanvas) | Out-Null
    $stack.Children.Add($barHost) | Out-Null

    # ---- Tier labels under the bar (6 evenly spaced) ----
    $labelGrid = New-Object System.Windows.Controls.Primitives.UniformGrid
    $labelGrid.Rows = 1
    $labelGrid.Columns = 6
    $labelGrid.Margin = [System.Windows.Thickness]::new(0, 0, 0, 14)
    for ($i = 0; $i -lt 6; $i++) {
        $lbl = New-Object System.Windows.Controls.TextBlock
        $shortLabel = switch ($i) {
            0 { "LOW" }
            1 { "BASIC" }
            2 { "SOLID" }
            3 { "STRONG" }
            4 { "HIGH" }
            5 { "EXTREME" }
        }
        $lbl.Text = $shortLabel
        $lbl.FontSize = 10
        $lbl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $lbl.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $isActive = ($i -ge $tier.StartIdx) -and ($i -le $tier.EndIdx)
        if ($isActive) {
            $lbl.Foreground = [System.Windows.Media.Brushes]::White
            $lbl.FontWeight = [System.Windows.FontWeights]::SemiBold
        } else {
            $lbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
        }
        $labelGrid.Children.Add($lbl) | Out-Null
    }
    $stack.Children.Add($labelGrid) | Out-Null

    # ---- GPU/CPU sub-panel ----
    # Show specs for the active tier (or the high end of a range).
    $specTier = $global:PowerTiers[$tier.EndIdx]

    $specBox = New-Object System.Windows.Controls.Border
    $specBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0e0e14")
    $specBox.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $specBox.Padding = [System.Windows.Thickness]::new(12, 9, 12, 9)

    $specRow = New-Object System.Windows.Controls.StackPanel
    $specRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $specBox.Child = $specRow

    function New-SpecBlock {
        param([string]$Label, [string]$Value)
        $sp = New-Object System.Windows.Controls.StackPanel
        $sp.Orientation = [System.Windows.Controls.Orientation]::Vertical
        $hd = New-Object System.Windows.Controls.TextBlock
        $hd.Text = $Label
        $hd.FontSize = 11
        $hd.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
        $hd.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $hd.Margin = [System.Windows.Thickness]::new(0, 0, 0, 2)
        $sp.Children.Add($hd) | Out-Null
        $vl = New-Object System.Windows.Controls.TextBlock
        $vl.Text = $Value
        $vl.FontSize = 12
        $vl.Foreground = [System.Windows.Media.Brushes]::White
        $vl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $sp.Children.Add($vl) | Out-Null
        return $sp
    }

    $specRow.Children.Add((New-SpecBlock "GPU" $specTier.Gpu)) | Out-Null

    # Vertical divider
    $div = New-Object System.Windows.Controls.Border
    $div.Width = 1
    $div.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
    $div.Margin = [System.Windows.Thickness]::new(16, 2, 16, 2)
    $specRow.Children.Add($div) | Out-Null

    $specRow.Children.Add((New-SpecBlock "CPU" $specTier.Cpu)) | Out-Null

    $stack.Children.Add($specBox) | Out-Null

    # ---------------------------------------------------------------
    # Hover animation - "wave cascade"
    # ---------------------------------------------------------------
    # Each active segment scales up vertically with a staggered start
    # so the bar reads as a wave rising from left to right. Marker
    # triangle pulses in sync. All animations loop while the cursor
    # is over the whole card; MouseLeave stops them and resets state.
    # We attach to the OUTER card so the user gets the effect whether
    # they hover over the bar, the heading, or the spec row.
    $animSegments = $activeSegments
    $animMarker   = $m1
    $animMarkerLift = $markerLift
    $animLabel    = $headRight
    $card.Add_MouseEnter({
        # Each segment: ScaleY 1 -> 1.6 -> 1 over 1.4s, staggered
        # 110ms apart so the wave reads as a left-to-right ripple.
        for ($i = 0; $i -lt $animSegments.Count; $i++) {
            $seg = $animSegments[$i]
            $st  = $seg.RenderTransform
            $da = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
            $da.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(1400))
            $da.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $da.BeginTime = [TimeSpan]::FromMilliseconds($i * 110)
            $kf1 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 1.0, ([System.Windows.Media.Animation.KeyTime]::FromPercent(0.0))
            $kf2 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 1.6, ([System.Windows.Media.Animation.KeyTime]::FromPercent(0.5))
            $kf3 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 1.0, ([System.Windows.Media.Animation.KeyTime]::FromPercent(1.0))
            $da.KeyFrames.Add($kf1) | Out-Null
            $da.KeyFrames.Add($kf2) | Out-Null
            $da.KeyFrames.Add($kf3) | Out-Null
            $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $da)
        }
        # Marker: lift up ~11px (about 3mm at 96dpi) and pulse there.
        # The lift uses the same 1.4s loop so it rides on top of the
        # wave - the triangle "jumps" toward the bar and bobs.
        $lift = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $lift.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(1400))
        $lift.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $lk1 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 0.0,   ([System.Windows.Media.Animation.KeyTime]::FromPercent(0.0))
        $lk2 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame -11.0, ([System.Windows.Media.Animation.KeyTime]::FromPercent(0.5))
        $lk3 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 0.0,   ([System.Windows.Media.Animation.KeyTime]::FromPercent(1.0))
        $lift.KeyFrames.Add($lk1) | Out-Null
        $lift.KeyFrames.Add($lk2) | Out-Null
        $lift.KeyFrames.Add($lk3) | Out-Null
        $animMarkerLift.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $lift)
        # Marker glow pulse.
        if (-not $animMarker.Effect) {
            $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $glow.Color = [System.Windows.Media.Colors]::White
            $glow.BlurRadius = 8
            $glow.ShadowDepth = 0
            $glow.Opacity = 0
            $animMarker.Effect = $glow
        }
        $pulse = New-Object System.Windows.Media.Animation.DoubleAnimation
        $pulse.From = 0
        $pulse.To = 0.95
        $pulse.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(700))
        $pulse.AutoReverse = $true
        $pulse.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $animMarker.Effect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $pulse)
        # Power-tier label (e.g. "SOLID"): glow in soft blue-white so
        # it reads as "lit up" while hovering.
        if (-not $animLabel.Effect) {
            $lglow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $lglow.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#bcd4ff")
            $lglow.BlurRadius = 12
            $lglow.ShadowDepth = 0
            $lglow.Opacity = 0
            $animLabel.Effect = $lglow
        }
        $lpulse = New-Object System.Windows.Media.Animation.DoubleAnimation
        $lpulse.From = 0.15
        $lpulse.To = 1.0
        $lpulse.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(900))
        $lpulse.AutoReverse = $true
        $lpulse.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $animLabel.Effect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $lpulse)
    }.GetNewClosure())
    $card.Add_MouseLeave({
        # Stop all looping animations and reset to idle.
        foreach ($seg in $animSegments) {
            $st = $seg.RenderTransform
            $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $null)
            $st.ScaleY = 1.0
        }
        $animMarkerLift.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $null)
        $animMarkerLift.Y = 0
        if ($animMarker.Effect) {
            $animMarker.Effect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $null)
            $animMarker.Effect.Opacity = 0
        }
        if ($animLabel.Effect) {
            $animLabel.Effect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $null)
            $animLabel.Effect.Opacity = 0
        }
    }.GetNewClosure())

    return $card
}

function global:New-SteamTheatreButton {
    param([string]$AccentHex = "#4db8ff")

    # Hover-tooltip mockup that mimics the SteamVR Settings ->
    # Dashboard panel: row with the setting name on the left and
    # an Off/On segmented control on the right, plus a small
    # caption underneath. Replaces the external screenshot we
    # used to bundle for Gunfire and the README mentions of this
    # setting in other games.
    $accent = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)

    $tooltip = New-Object System.Windows.Controls.ToolTip
    $tooltip.Background  = [System.Windows.Media.Brushes]::Transparent
    $tooltip.BorderBrush = [System.Windows.Media.Brushes]::Transparent
    $tooltip.Padding     = [System.Windows.Thickness]::new(0)
    $tooltip.HasDropShadow = $false

    $tipOuter = New-Object System.Windows.Controls.Border
    $tipOuter.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a1a24")
    $tipOuter.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
    $tipOuter.BorderThickness = [System.Windows.Thickness]::new(1)
    $tipOuter.CornerRadius    = [System.Windows.CornerRadius]::new(6)
    $tipOuter.Padding         = [System.Windows.Thickness]::new(8)
    $tipShadow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $tipShadow.Color = [System.Windows.Media.Color]::FromArgb(180,0,0,0)
    $tipShadow.BlurRadius = 16
    $tipShadow.ShadowDepth = 4
    $tipShadow.Opacity = 0.6
    $tipOuter.Effect = $tipShadow

    $tipInner = New-Object System.Windows.Controls.Border
    $tipInner.Background   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1f2227")
    $tipInner.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $tipInner.Padding      = [System.Windows.Thickness]::new(14, 10, 14, 10)
    $tipInner.MinWidth     = 260

    $tipStack = New-Object System.Windows.Controls.StackPanel
    $tipInner.Child = $tipStack

    # Header line: where to find the setting
    $tipHeader = New-Object System.Windows.Controls.TextBlock
    $tipHeader.Text = "SteamVR Settings -> Dashboard"
    $tipHeader.FontSize = 11
    $tipHeader.FontWeight = [System.Windows.FontWeights]::SemiBold
    $tipHeader.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#888888")
    $tipHeader.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $tipHeader.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    $tipStack.Children.Add($tipHeader) | Out-Null

    # Setting row: name + Off/On segmented buttons
    $rowGrid = New-Object System.Windows.Controls.Grid
    $rowGrid.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
    $cName = New-Object System.Windows.Controls.ColumnDefinition
    $cName.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $cToggle = New-Object System.Windows.Controls.ColumnDefinition
    $cToggle.Width = [System.Windows.GridLength]::Auto
    $rowGrid.ColumnDefinitions.Add($cName)   | Out-Null
    $rowGrid.ColumnDefinitions.Add($cToggle) | Out-Null

    $nameTxt = New-Object System.Windows.Controls.TextBlock
    $nameTxt.Text = "Present Non-VR Apps on" + [Environment]::NewLine + "Theater Screen Upon Launch"
    $nameTxt.FontSize = 11
    $nameTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dddddd")
    $nameTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $nameTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $nameTxt.Margin = [System.Windows.Thickness]::new(0, 0, 12, 0)
    [System.Windows.Controls.Grid]::SetColumn($nameTxt, 0)
    $rowGrid.Children.Add($nameTxt) | Out-Null

    # Off/On segmented control
    $togglePanel = New-Object System.Windows.Controls.StackPanel
    $togglePanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    [System.Windows.Controls.Grid]::SetColumn($togglePanel, 1)
    $togglePanel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $offBtn = New-Object System.Windows.Controls.Border
    $offBtn.Background    = $accent
    $offBtn.CornerRadius  = [System.Windows.CornerRadius]::new(2)
    $offBtn.Padding       = [System.Windows.Thickness]::new(10, 3, 10, 3)
    $offBtn.Margin        = [System.Windows.Thickness]::new(0, 0, 2, 0)
    $offTxt = New-Object System.Windows.Controls.TextBlock
    $offTxt.Text = "Off"
    $offTxt.FontSize = 10
    $offTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $offTxt.Foreground = [System.Windows.Media.Brushes]::Black
    $offTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $offBtn.Child = $offTxt
    $togglePanel.Children.Add($offBtn) | Out-Null

    $onBtn = New-Object System.Windows.Controls.Border
    $onBtn.Background    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
    $onBtn.CornerRadius  = [System.Windows.CornerRadius]::new(2)
    $onBtn.Padding       = [System.Windows.Thickness]::new(10, 3, 10, 3)
    $onTxt = New-Object System.Windows.Controls.TextBlock
    $onTxt.Text = "On"
    $onTxt.FontSize = 10
    $onTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#888888")
    $onTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $onBtn.Child = $onTxt
    $togglePanel.Children.Add($onBtn) | Out-Null

    $rowGrid.Children.Add($togglePanel) | Out-Null
    $tipStack.Children.Add($rowGrid) | Out-Null

    # Footer caption: "Set to OFF" with a top divider
    $footerBorder = New-Object System.Windows.Controls.Border
    $footerBorder.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
    $footerBorder.BorderThickness = [System.Windows.Thickness]::new(0, 1, 0, 0)
    $footerBorder.Margin          = [System.Windows.Thickness]::new(0, 4, 0, 0)
    $footerBorder.Padding         = [System.Windows.Thickness]::new(0, 4, 0, 0)
    $footerTxt = New-Object System.Windows.Controls.TextBlock
    $footerTxt.Text = "Set to OFF"
    $footerTxt.FontSize = 10
    $footerTxt.Foreground = $accent
    $footerTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $footerBorder.Child = $footerTxt
    $tipStack.Children.Add($footerBorder) | Out-Null

    $tipOuter.Child = $tipInner
    $tooltip.Content = $tipOuter

    # The clickable button itself
    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius  = [System.Windows.CornerRadius]::new(4)
    $btn.Padding       = [System.Windows.Thickness]::new(10, 6, 10, 6)
    $btn.Margin        = [System.Windows.Thickness]::new(0, 8, 0, 0)
    $btn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $btn.Cursor = [System.Windows.Input.Cursors]::Hand
    $accentColor = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
    # Tinted fill: ~12% accent, rest dark
    $tintFill = [System.Windows.Media.Color]::FromArgb(
        [byte]30,
        $accentColor.Color.R, $accentColor.Color.G, $accentColor.Color.B
    )
    $btn.Background = New-Object System.Windows.Media.SolidColorBrush $tintFill
    $tintBorder = [System.Windows.Media.Color]::FromArgb(
        [byte]160,
        $accentColor.Color.R, $accentColor.Color.G, $accentColor.Color.B
    )
    $btn.BorderBrush     = New-Object System.Windows.Media.SolidColorBrush $tintBorder
    $btn.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $btn.ToolTip = $tooltip
    [System.Windows.Controls.ToolTipService]::SetInitialShowDelay($btn, 200)
    [System.Windows.Controls.ToolTipService]::SetShowDuration($btn, 600000)

    # Brighten accent a touch for the label so it pops on the dark fill
    $labelColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Min(255, $accentColor.Color.R + 30)),
        [byte]([Math]::Min(255, $accentColor.Color.G + 30)),
        [byte]([Math]::Min(255, $accentColor.Color.B + 30))
    )
    $labelBrush = New-Object System.Windows.Media.SolidColorBrush $labelColor

    $btnContent = New-Object System.Windows.Controls.StackPanel
    $btnContent.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    # Info icon (drawn as ellipse + "i")
    $iconBox = New-Object System.Windows.Controls.Grid
    $iconBox.Width = 13; $iconBox.Height = 13
    $iconBox.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
    $iconBox.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $iconCircle = New-Object System.Windows.Shapes.Ellipse
    $iconCircle.Width = 13; $iconCircle.Height = 13
    $iconCircle.Stroke = $labelBrush
    $iconCircle.StrokeThickness = 1.4
    $iconBox.Children.Add($iconCircle) | Out-Null
    $iconI = New-Object System.Windows.Controls.TextBlock
    $iconI.Text = "i"
    $iconI.FontSize = 9
    $iconI.FontWeight = [System.Windows.FontWeights]::Bold
    $iconI.Foreground = $labelBrush
    $iconI.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $iconI.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $iconI.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $iconBox.Children.Add($iconI) | Out-Null
    $btnContent.Children.Add($iconBox) | Out-Null

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = "Disable Steam Theatre"
    $lbl.FontSize = 12
    $lbl.FontWeight = [System.Windows.FontWeights]::Medium
    $lbl.Foreground = $labelBrush
    $lbl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $lbl.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $btnContent.Children.Add($lbl) | Out-Null
    $btn.Child = $btnContent

    # Click behaviour: clicking the button should ALSO show the
    # tooltip (not just hover). StaysOpen=true is required because
    # otherwise WPF dismisses the tooltip the instant we set it
    # open from inside a click handler. We then auto-close on
    # MouseLeave OR on any outside click / scroll, so the tooltip
    # behaves like a normal hover-tip even though it was opened
    # via click.
    $tooltipRef = $tooltip
    $btnRef     = $btn
    $btn.Add_MouseLeftButtonUp({
        param($s, $e)
        if ($tooltipRef.IsOpen) {
            # Second click closes it (toggle behaviour).
            $tooltipRef.IsOpen = $false
            $global:OpenTheatreTooltip = $null
            $global:OpenTheatreOwner   = $null
        } else {
            $tooltipRef.PlacementTarget = $this
            $tooltipRef.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom
            $tooltipRef.StaysOpen = $true
            $tooltipRef.IsOpen = $true
            $global:OpenTheatreTooltip = $tooltipRef
            $global:OpenTheatreOwner   = $btnRef
        }
        # Don't bubble - otherwise the window-level outside-click
        # handler below would immediately close the tooltip we
        # just opened.
        $e.Handled = $true
    }.GetNewClosure())

    # Close on MouseLeave so the tooltip vanishes once the cursor
    # moves away - matches the user's expectation from regular
    # hover tooltips.
    $btn.Add_MouseLeave({
        if ($tooltipRef.IsOpen) {
            $tooltipRef.IsOpen = $false
            $global:OpenTheatreTooltip = $null
            $global:OpenTheatreOwner   = $null
        }
    }.GetNewClosure())

    Add-SweepHover -Border $btn
    return $btn
}

# Uninstall guide button - sits next to the Steam Theatre button
# at the end of the readme. Click reveals a numbered step-by-step
# tooltip explaining how to safely remove the VR mod and the
# game. Steps adapt based on whether the game uses Steam launch
# options (which the user has to clear manually - we can't do it
# from the Hub since Steam doesn't expose that API).
function global:Show-ExePicker {
    # Small WinForms list dialog: the user confirms which .exe launches
    # the game in a located folder (used when the catalog LaunchExe is
    # absent / named differently). Returns the chosen full exe path or
    # $null. Input is an array of full exe paths.
    param(
        [string[]]$Exes,
        [string]$Title
    )
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Select the game exe for " + $Title
    $form.Width = 480
    $form.Height = 340
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Which file launches the game?"
    $lbl.SetBounds(12, 10, 440, 20)

    $list = New-Object System.Windows.Forms.ListBox
    $list.SetBounds(12, 36, 444, 212)
    foreach ($e in $Exes) { [void]$list.Items.Add((Split-Path -Leaf $e)) }
    if ($list.Items.Count -gt 0) { $list.SelectedIndex = 0 }

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "Use this"
    $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $ok.SetBounds(280, 258, 80, 30)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = "Cancel"
    $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancel.SetBounds(372, 258, 80, 30)

    $form.Controls.AddRange(@($lbl, $list, $ok, $cancel))
    $form.AcceptButton = $ok
    $form.CancelButton = $cancel

    $res = $form.ShowDialog()
    if ($res -eq [System.Windows.Forms.DialogResult]::OK -and $list.SelectedIndex -ge 0) {
        return $Exes[$list.SelectedIndex]
    }
    return $null
}

function global:New-ClearLocationButton {
    # Removes a user-located game's recorded path + launch override +
    # marker so the entry goes back to "not found" and the user can
    # locate it again from scratch. Correction path for user mistakes.
    param(
        $Game,
        [string]$AccentHex = "#888899"
    )
    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius    = [System.Windows.CornerRadius]::new(7)
    $btn.Padding         = [System.Windows.Thickness]::new(16, 10, 16, 10)
    $btn.Cursor          = [System.Windows.Input.Cursors]::Hand
    $btn.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161d")
    $btn.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $btn.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8a5560")

    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text       = "Clear"
    $t.FontSize   = 14
    $t.FontWeight = [System.Windows.FontWeights]::SemiBold
    $t.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#d2a0ad")
    $btn.Child    = $t

    $tip = New-Object System.Windows.Controls.ToolTip
    $tip.Content = "Forget the located folder for this game."
    $btn.ToolTip = $tip

    $btn.Add_MouseLeftButtonUp({
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $r = [System.Windows.Forms.MessageBox]::Show(
                ("Forget the saved location for " + $Game.Title + "?`r`n`r`nIt will go back to 'not found' until you locate it again."),
                "Clear location",
                [System.Windows.Forms.MessageBoxButtons]::YesNo)
            if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
            foreach ($f in @((Get-InstalledPathFile -Game $Game), (Get-LaunchOverrideFile -Game $Game), (Get-UserLocatedFile -Game $Game))) {
                if ($f -and (Test-Path $f)) { try { Remove-Item -Path $f -Force -ErrorAction SilentlyContinue } catch {} }
            }
            $global:PendingInstallTitle = $Game.Title
            try { Invoke-PostInstallRefresh } catch {}
            [System.Windows.Forms.MessageBox]::Show(
                ($Game.Title + " location cleared."),
                "Clear location") | Out-Null
        } catch {}
    }.GetNewClosure())

    return $btn
}

function global:New-TwoModsButton {
    # A green "VR Ready"-style launch button for one of a TwoMods game's
    # two alternative mods. Click routes to Start-GameInVR with the
    # given Mode ("ModA" / "ModB"). Used on the detail page when both
    # mods are installed, so the user picks which one to launch.
    param(
        $Game,
        [string]$Mode,
        [string]$Label,
        [string]$AccentHex = "#888899",
        [switch]$Installed
    )
    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius    = [System.Windows.CornerRadius]::new(7)
    $btn.Padding         = [System.Windows.Thickness]::new(16, 10, 16, 10)
    $btn.Cursor          = [System.Windows.Input.Cursors]::Hand
    # Keep a constant height: without this the button vertical-stretches
    # to the row, so it grows when the (slightly taller) Reinstall pill
    # slides in on hover. Centering pins it to its own content height.
    $btn.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $btn.BorderThickness = [System.Windows.Thickness]::new(1.5)
    if ($Installed) {
        $btn.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
        $btn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fa873")
    } else {
        $btn.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161d")
        $btn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a47")
    }

    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text       = $Label
    $t.FontSize   = 14
    $t.FontWeight = [System.Windows.FontWeights]::SemiBold
    $t.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($(if ($Installed) { "#88dd99" } else { "#c2cad2" }))
    $btn.Child    = $t

    $btn.Add_MouseLeftButtonUp({
        try { Start-GameInVR -Game $Game -Mode $Mode } catch {}
    }.GetNewClosure())

    return $btn
}

function global:Resolve-LocatedRoot {
    # Given a user-picked folder and a relative file (ModFile or
    # LaunchExe), return the folder that actually holds <root>\<RelFile>.
    # Many mods don't sit directly in the folder the user picks: the
    # file may be in a subfolder, an extra nesting level (e.g. Epic
    # "...\Cyberpunk 2077\Cyberpunk 2077\bin\..."), or the user may have
    # picked a subfolder of the real root. We check, in order:
    #   1. the picked folder directly,
    #   2. descendants (bounded depth) for <dir>\RelFile,
    #   3. up to two parent folders.
    # Returns the true root, or $null if the file isn't found anywhere.
    # Normalizing .installed_path to this root means the regular scan's
    # "Join-Path .installed_path ModFile" check keeps working unchanged.
    param([string]$Picked, [string]$RelFile, [int]$MaxDepth = 4)
    if ([string]::IsNullOrWhiteSpace($Picked) -or [string]::IsNullOrWhiteSpace($RelFile)) { return $null }
    # 1. Direct hit - the common, fast case.
    if (Test-Path (Join-Path $Picked $RelFile)) { return $Picked }
    $suffix = "\" + $RelFile
    # 2. Bounded descendant search. Filter by the leaf file name so the
    #    recursion stays cheap, then confirm the FULL relative path
    #    matches (so a stray same-named file elsewhere can't match).
    try {
        $leaf = Split-Path -Leaf $RelFile
        $hits = Get-ChildItem -LiteralPath $Picked -Filter $leaf -Recurse -Depth $MaxDepth -File -ErrorAction SilentlyContinue
        foreach ($h in $hits) {
            if ($h.FullName.EndsWith($suffix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $root = $h.FullName.Substring(0, $h.FullName.Length - $suffix.Length)
                if (($root) -and (Test-Path -LiteralPath $root) -and (Test-Path (Join-Path $root $RelFile))) {
                    return $root
                }
            }
        }
    } catch {}
    # 3. Walk up to two parents (user picked a subfolder of the root).
    $up = $Picked
    for ($i = 0; $i -lt 2; $i++) {
        $up = Split-Path -Parent $up
        if ([string]::IsNullOrWhiteSpace($up)) { break }
        if (Test-Path (Join-Path $up $RelFile)) { return $up }
    }
    return $null
}

function global:New-LocateButton {
    # A user-pointed install locator. Shown on the detail page only when
    # Check Installed did not find the game. Opens a folder picker, checks
    # the ModFile is actually in the chosen folder, records the path via
    # Get-InstalledPathFile (the same file the scan reads + re-verifies),
    # then refreshes. Deleting the folder later still demotes correctly
    # because the scan re-checks the path + ModFile every run.
    param(
        $Game,
        [string]$AccentHex = "#888899",
        [string]$Label = "Locate Game"
    )

    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius     = [System.Windows.CornerRadius]::new(7)
    $btn.Padding          = [System.Windows.Thickness]::new(16, 10, 16, 10)
    $btn.Cursor           = [System.Windows.Input.Cursors]::Hand
    $btn.Background       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161d")
    $btn.BorderThickness  = [System.Windows.Thickness]::new(1.5)
    $btn.BorderBrush      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#50505f")

    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text       = $Label
    $t.FontSize   = 14
    $t.FontWeight = [System.Windows.FontWeights]::SemiBold
    $t.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c2cad2")
    $btn.Child    = $t

    $tip = New-Object System.Windows.Controls.ToolTip
    $tip.Content = "Already installed somewhere the Hub did not find?"
    $btn.ToolTip = $tip

    $btn.Add_MouseLeftButtonUp({
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
            if ($Game.TwoMods) {
                $dlg.Description = 'Select the "' + $Game.Title + '" folder that holds the mod subfolders (' + $Game.ModASub + ' / ' + $Game.ModBSub + ').'
            } else {
                $dlg.Description = 'Select the folder where "' + $Game.Title + '" or the VR mod exe is installed.'
            }
            $dlg.ShowNewFolderButton = $false
            if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
            $picked = $dlg.SelectedPath
            if ([string]::IsNullOrWhiteSpace($picked) -or -not (Test-Path $picked)) { return }

            # One label for all the messages below so the wording matches
            # the game type: TwoMods titles name BOTH mods (e.g. "NALULUNA
            # / lufz mod files") instead of an awkward singular "its VR
            # mod", and the title's own "VR" isn't echoed twice.
            $modLabel = if ($Game.TwoMods -and $Game.ModAName -and $Game.ModBName) {
                $Game.ModAName + " / " + $Game.ModBName + " mod files"
            } else {
                "VR mod files"
            }
            # For the Plan B message we've only found the FLAT game install,
            # nothing VR yet - so drop the trailing " VR" from the Hub title
            # (e.g. "Forza Horizon 6 VR" -> "Forza Horizon 6") so we don't
            # imply a VR install exists at that point.
            $baseTitle = $Game.Title -replace ' VR$', ''

            # Two-tier detection with positive feedback either way:
            #   Plan A - the VR mod is here            -> VR Ready
            #   Plan B - only the game itself is here  -> installed (add mod later)
            # We only fall back to a confirm prompt if NEITHER is found.
            $modHit    = $false   # VR mod present (Plan A)
            $gameHit   = $false   # game itself present (Plan B)
            $chosenExe = $null    # launch target for the per-game override

            # ---- Plan A: is the VR mod here? ----
            # Resolve the real root: the ModFile may sit in a subfolder, an
            # extra nesting level, or one folder off. On a hit we normalize
            # $picked so the recorded .installed_path is exactly what the
            # scan re-checks later.
            if ($Game.ModFile) {
                $r = Resolve-LocatedRoot -Picked $picked -RelFile $Game.ModFile
                if ($r) { $modHit = $true; $picked = $r }
            }
            # VrInstallRoot games keep the mod OUTSIDE the game folder
            # (%LocalAppData% etc.); check that root too. We do NOT move
            # $picked - it stays the game folder the user pointed at.
            if (-not $modHit -and $Game.VrInstallRoot -and $Game.ModFile) {
                $vrRoot = $Game.VrInstallRoot
                if     ($vrRoot -like "LOCALAPPDATA:*") { $vrRoot = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) ($vrRoot.Substring("LOCALAPPDATA:".Length)) }
                elseif ($vrRoot -like "APPDATA:*")      { $vrRoot = Join-Path ([Environment]::GetFolderPath("ApplicationData"))      ($vrRoot.Substring("APPDATA:".Length)) }
                elseif ($vrRoot -like "PROGRAMDATA:*")  { $vrRoot = Join-Path ([Environment]::GetFolderPath("CommonApplicationData")) ($vrRoot.Substring("PROGRAMDATA:".Length)) }
                elseif ($vrRoot -like "USERPROFILE:*")  { $vrRoot = Join-Path ([Environment]::GetFolderPath("UserProfile"))           ($vrRoot.Substring("USERPROFILE:".Length)) }
                if ($vrRoot -and (Test-Path (Join-Path $vrRoot $Game.ModFile))) { $modHit = $true }
            }
            # TwoMods games have no single ModFile: a mod is present if
            # either mod's launcher is found under the recorded parent.
            # Be forgiving if the user picked a subfolder - normalize up.
            if ($Game.TwoMods) {
                $tmSubs = @()
                if ($Game.ModASub -and $Game.ModALaunch) { $tmSubs += ,@($Game.ModASub, $Game.ModALaunch) }
                if ($Game.ModBSub -and $Game.ModBLaunch) { $tmSubs += ,@($Game.ModBSub, $Game.ModBLaunch) }
                $tmFound = $false
                foreach ($p in $tmSubs) {
                    $sd = Join-Path $picked $p[0]
                    if ((Test-Path $sd) -and (Get-ChildItem -Path $sd -Filter $p[1] -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1)) { $tmFound = $true }
                }
                if (-not $tmFound) {
                    foreach ($p in $tmSubs) {
                        if (Get-ChildItem -Path $picked -Filter $p[1] -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) {
                            $picked = Split-Path -Parent $picked
                            $tmFound = $true
                            break
                        }
                    }
                }
                if ($tmFound) { $modHit = $true }
            }

            # ---- Plan B: no VR mod -> is the game itself here? ----
            # Look for the game's exe. First the catalog LaunchExe (also
            # matched in a subfolder); otherwise scan for any plausible
            # game exe - exactly one is taken automatically, several let
            # the user pick. A found exe both proves the install (gameHit)
            # and, for normal games, becomes the launch override. TwoMods
            # (per-mod launch) and VrInstallRoot (launched from their own
            # root) never store a single-exe override.
            if (-not $modHit) {
                if ($Game.LaunchExe) {
                    if (Test-Path (Join-Path $picked $Game.LaunchExe)) {
                        $gameHit = $true   # at the root; Start-in-VR finds it, no override needed
                    } else {
                        $rg = Resolve-LocatedRoot -Picked $picked -RelFile $Game.LaunchExe
                        if ($rg) {
                            $picked  = $rg
                            $gameHit = $true
                            if (-not $Game.VrInstallRoot) { $chosenExe = Join-Path $rg $Game.LaunchExe }
                        }
                    }
                }
                if (-not $gameHit) {
                    $exeCands = @()
                    try {
                        $exeCands = @(Get-ChildItem -Path $picked -Filter *.exe -File -ErrorAction SilentlyContinue |
                            Where-Object { $_.Name -notmatch '(?i)(crashhandler|crashreport|vc_redist|vcredist|dxsetup|directx|dotnet|notification_helper|unins|uninstall|_setup|installer|redist)' } |
                            Sort-Object Length -Descending |
                            Select-Object -ExpandProperty FullName)
                    } catch {}
                    $cand = $null
                    if ($exeCands.Count -eq 1) { $cand = $exeCands[0] }
                    elseif ($exeCands.Count -gt 1) { $cand = Show-ExePicker -Exes $exeCands -Title $Game.Title }
                    if ($cand) {
                        $gameHit = $true
                        if (-not $Game.TwoMods -and -not $Game.VrInstallRoot) { $chosenExe = $cand }
                    }
                }
            }

            # ---- Assign the VR launcher for the located install ----
            # When the mod is found (Plan A) Start-in-VR launches via the
            # recorded .installed_path + LaunchExe. That works directly
            # when the LaunchExe sits at the root (the common case). If it
            # instead lives in a subfolder, resolve it (no prompt) and
            # store it as the override so the right exe still runs. Plan B
            # already set $chosenExe from its scan/pick. TwoMods launch
            # per-mod and VrInstallRoot launch from their own root, so
            # both skip a single-exe override.
            if (-not $chosenExe -and $Game.LaunchExe -and -not $Game.TwoMods -and -not $Game.VrInstallRoot) {
                if (-not (Test-Path (Join-Path $picked $Game.LaunchExe))) {
                    $rl = Resolve-LocatedRoot -Picked $picked -RelFile $Game.LaunchExe
                    if ($rl) { $chosenExe = Join-Path $rl $Game.LaunchExe }
                }
            }

            # ---- Last resort: nothing found at all ----
            # (VrInstallRoot titles are exempt - their base game folder
            # legitimately holds neither the mod nor the launcher.)
            if (-not $modHit -and -not $gameHit -and -not $Game.VrInstallRoot) {
                $ask = [System.Windows.Forms.MessageBox]::Show(
                    ('No ' + $modLabel + ' or game files found in:' + "`r`n" + $picked + "`r`n`r`nLink this folder anyway so " + $Game.Title + " shows as installed? You can add the VR mod later."),
                    "Locate Game",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo)
                if ($ask -ne [System.Windows.Forms.DialogResult]::Yes) { return }
            }

            $ipf = Get-InstalledPathFile -Game $Game
            if (-not $ipf) {
                [System.Windows.Forms.MessageBox]::Show("This title cannot store a located path.", "Locate Game") | Out-Null
                return
            }
            try { New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ipf) | Out-Null } catch {}
            try { Set-Content -Path $ipf -Value $picked -Encoding UTF8 -Force } catch {}

            # Revive games (e.g. Quake 2 VR): "Start in VR" routes through
            # ReviveInjector.exe only when a ".revive_launch" marker sits
            # in the folder. The installer normally drops it, but a located
            # install may lack it. Write it - ONLY if absent, so we never
            # clobber an existing setup - pointing at the injector, exactly
            # like the installer (found path, else the documented default).
            # Safe for Oculus-direct users too: if no injector is found at
            # launch time the Revive route falls through to a direct start.
            if ($Game.Revive) {
                try {
                    $rvMarker = Join-Path $picked ".revive_launch"
                    if (-not (Test-Path $rvMarker)) {
                        $rvInj = $null
                        $rvCands = @(
                            (Join-Path $env:ProgramFiles "Revive\ReviveInjector.exe"),
                            (Join-Path $env:ProgramFiles "Revive\Revive\ReviveInjector.exe")
                        )
                        $pf86 = ${env:ProgramFiles(x86)}
                        if ($pf86) { $rvCands += (Join-Path $pf86 "Revive\ReviveInjector.exe") }
                        foreach ($c in $rvCands) { if (Test-Path $c) { $rvInj = $c; break } }
                        if (-not $rvInj) { $rvInj = Join-Path $env:ProgramFiles "Revive\ReviveInjector.exe" }
                        Set-Content -Path $rvMarker -Value $rvInj -Encoding ASCII -Force
                    }
                } catch {}
            }

            # Store the launch override from the exe we found/picked in
            # Plan B (or a subfolder-resolved LaunchExe). TwoMods and
            # VrInstallRoot games are intentionally excluded - they launch
            # per-mod or from their own VR root, so a single-exe override
            # would be wrong - and $chosenExe is never set for them above.
            if ($chosenExe -and -not $Game.TwoMods -and -not $Game.VrInstallRoot) {
                try {
                    $ovf = Get-LaunchOverrideFile -Game $Game
                    if ($ovf) {
                        try { New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ovf) | Out-Null } catch {}
                        try { Set-Content -Path $ovf -Value $chosenExe -Encoding UTF8 -Force } catch {}
                    }
                } catch {}
            }

            # Mark this as user-located so the detail page offers
            # Re-locate / Clear instead of the one-shot Locate button.
            try {
                $ulf = Get-UserLocatedFile -Game $Game
                if ($ulf) {
                    try { New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ulf) | Out-Null } catch {}
                    try { Set-Content -Path $ulf -Value $picked -Encoding UTF8 -Force } catch {}
                }
            } catch {}

            $global:PendingInstallTitle = $Game.Title
            try { Invoke-PostInstallRefresh } catch {}

            if ($modHit) {
                $msg = "Success - " + $modLabel + " found for " + $Game.Title + "." + "`r`n`r`nLocation:`r`n" + $picked + "`r`n`r`nIt will now show as VR Ready."
            } elseif ($gameHit) {
                $msg = "Success - " + $baseTitle + " installation found." + "`r`n`r`nLocation:`r`n" + $picked + "`r`n`r`nIt will show as installed. Install the VR mod to make it VR Ready."
            } else {
                $msg = $Game.Title + " linked to:`r`n" + $picked + "`r`n`r`nNo " + $modLabel + " detected yet; it will show VR Ready once the VR mod is installed."
            }
            [System.Windows.Forms.MessageBox]::Show($msg, "Locate Game") | Out-Null
        } catch {}
    }.GetNewClosure())

    return $btn
}

function global:New-UninstallGuideButton {
    param(
        $Game,
        [string]$AccentHex = "#cc6655"
    )

    $accent = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)

    # Heuristic: which games need a "clear Steam launch options"
    # step? Detected by the mod family / install pattern rather
    # than a per-game flag. Covers:
    #   - Luke Ross R.E.A.L. VR (37 titles, -eac_launcher)
    #   - Subnautica / Below Zero (SubmersedVR, -vrmode openvr)
    #   - Descenders, Dawn (-vrmode OpenVR)
    #   - Deep Rock Galactic (-overridenohmd -dx11)
    #   - Garry's Mod (autoexec config)
    #   - Lethal Company (custom launch line)
    $hasSteamArgs = $false
    if ($Game.Mod) {
        $m = $Game.Mod
        if ($m -match "R\.E\.A\.L\. VR") { $hasSteamArgs = $true }
        if ($m -match "SubmersedVR")     { $hasSteamArgs = $true }
        if ($m -match "DescendersVR")    { $hasSteamArgs = $true }
        if ($m -match "DawnVR")          { $hasSteamArgs = $true }
        if ($m -match "DRG[ -]?VRG")     { $hasSteamArgs = $true }
        if ($m -match "GModVR")          { $hasSteamArgs = $true }
        if ($m -match "LCVR")            { $hasSteamArgs = $true }
    }
    $isSteam = (-not $Game.Type -or $Game.Type -eq "steam")

    # Is this a self-contained C:\Games install rather than an in-place mod?
    # Quake builds and the depot titles install into their own folder under
    # C:\Games - they are NOT registered in Steam, so the "uninstall via
    # Steam" advice is wrong for them. To remove one you just delete the
    # folder; the original game (if owned) is never touched. Detected by a
    # C:\Games path in DepotPath or FallbackPaths.
    $standaloneFolderPath = $null
    if ($Game.DepotPath -and ($Game.DepotPath -match '[A-Za-z]:\\games\\')) {
        $standaloneFolderPath = $Game.DepotPath
    }
    if (-not $standaloneFolderPath -and $Game.FallbackPaths) {
        foreach ($fp in $Game.FallbackPaths) {
            if ($fp -match '^[A-Za-z]:\\games\\') { $standaloneFolderPath = $fp; break }
        }
    }
    $isStandaloneFolder = [bool]$standaloneFolderPath

    # User-provided games: the Hub layers a mod onto a copy of the game
    # that the user already owns and supplied. It never installed the
    # base game, so "uninstall via Steam" is wrong - to undo, you remove
    # the mod files from your own game folder. GTA V and NOLF2 each have
    # their own dedicated installer for this.
    $isGtaVr = ($Game.Title -eq "Grand Theft Auto V VR")
    $isNolf2 = ($Game.Title -eq "No One Lives Forever 2 VR")
    $isUserProvidedMod = ($isGtaVr -or $isNolf2)

    $tooltip = New-Object System.Windows.Controls.ToolTip
    $tooltip.Background  = [System.Windows.Media.Brushes]::Transparent
    $tooltip.BorderBrush = [System.Windows.Media.Brushes]::Transparent
    $tooltip.Padding     = [System.Windows.Thickness]::new(0)
    $tooltip.HasDropShadow = $false

    $tipOuter = New-Object System.Windows.Controls.Border
    $tipOuter.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a1a24")
    $tipOuter.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
    $tipOuter.BorderThickness = [System.Windows.Thickness]::new(1)
    $tipOuter.CornerRadius    = [System.Windows.CornerRadius]::new(6)
    $tipOuter.Padding         = [System.Windows.Thickness]::new(8)
    $tipShadow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $tipShadow.Color = [System.Windows.Media.Color]::FromArgb(180,0,0,0)
    $tipShadow.BlurRadius = 16
    $tipShadow.ShadowDepth = 4
    $tipShadow.Opacity = 0.6
    $tipOuter.Effect = $tipShadow

    $tipInner = New-Object System.Windows.Controls.Border
    $tipInner.Background   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1f2227")
    $tipInner.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $tipInner.Padding      = [System.Windows.Thickness]::new(14, 12, 14, 12)
    $tipInner.MinWidth     = 360
    $tipInner.MaxWidth     = 420

    $tipStack = New-Object System.Windows.Controls.StackPanel
    $tipInner.Child = $tipStack

    # Header
    $tipHeader = New-Object System.Windows.Controls.TextBlock
    $tipHeader.Text = if ($isStandaloneFolder) { "How to remove this VR build" } else { "How to safely remove the VR mod" }
    $tipHeader.FontSize = 13
    $tipHeader.FontWeight = [System.Windows.FontWeights]::SemiBold
    $tipHeader.Foreground = [System.Windows.Media.Brushes]::White
    $tipHeader.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $tipHeader.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
    $tipStack.Children.Add($tipHeader) | Out-Null

    # Build step list. Order:
    #   1. (only if launch options set) Clear Steam launch options
    #   2. Browse local files (so user knows where the folder lives)
    #   3. Uninstall via Steam
    #   4. Delete leftover files
    $steps = @()
    if ($isUserProvidedMod) {
        if ($isGtaVr) {
            $steps += "The R.E.A.L. VR mod was layered into your OWN copy of GTA V - the Hub never installed the base game, so do NOT uninstall it via Steam or Epic."
            $steps += "To remove just the VR mod, open your GTA V folder and delete the mod files: RealVR.ini, the 'asi' folder, ScriptHookV.dll, dinput8.dll, RealConfig.bat and the RealRepo folder (plus GTAVR.asi and openvr_api.dll if you added motion controls)."
            $steps += "If you ran RealConfig.bat, rename settings_ori.xml back to settings.xml to undo the VR graphics preset."
            $steps += "Your base game stays fully playable in flat mode afterwards."
        } else {
            $steps += "The R.E.A.L. VR mod was layered into your OWN copy of No One Lives Forever 2 - the Hub never installed the game, which is a retail / non-Steam install."
            $steps += "To remove just the VR mod, open your NOLF2 folder and restore the originals the installer saved in the '_backup_pre_REAL' folder (copy them back, overwriting the modded files), then delete the VR-only files: VR.rez, VRlaunchcmds.txt and the NOLF2Revive folder."
            $steps += "To remove the game itself, uninstall it via Windows Settings -> Apps -> Installed apps (or its own uninstaller) - it is not in Steam."
        }
        $steps += "Delete the '$($Game.Title)' desktop shortcut the installer created."
    } elseif ($isStandaloneFolder) {
        $folderLeaf = Split-Path $standaloneFolderPath -Leaf
        $steps += "This VR build lives in its own folder and is NOT registered in Steam - there is nothing to uninstall there."
        $steps += "Just delete the folder 'C:\Games\$folderLeaf'. That removes the VR build completely."
        $steps += "Delete the desktop shortcut too, if the installer created one."
        if ($Game.SteamId) {
            $steps += "Your original game (in Steam or GOG, if you own it) is left completely untouched - this never modified it."
        }
        if ($Game.DualMode) {
            $steps += "If you instead chose the in-place Steam version, remove that one the Steam way: Browse local files, Uninstall in Steam, then delete any leftover mod files."
        }
    } else {
        if ($hasSteamArgs -and $isSteam) {
            $steps += "Open Steam, right-click the game -> Properties -> General -> clear the Launch Options text field."
        }
        if ($isSteam) {
            $steps += "Right-click the game in Steam -> Manage -> Browse local files. The install folder opens in Explorer - keep it open for step 4."
            $steps += "Back in Steam: right-click the game -> Manage -> Uninstall. Steam removes most files but often leaves mod files behind."
            $steps += "In the Explorer window from step 2, delete the whole game folder. Now the VR mod is gone for good."
        } else {
            $steps += "Open the game's install folder (GOG Galaxy: right-click -> Manage installation -> Show folder; itch.io: in the launcher, right-click -> Show local files)."
            $steps += "Uninstall the game through your launcher (GOG Galaxy or itch.io)."
            $steps += "Delete any remaining files from the install folder."
        }
        $steps += "Optional: reinstall the game later if you want to play it without VR mods."
    }

    $stepIdx = 1
    foreach ($s in $steps) {
        $row = New-Object System.Windows.Controls.StackPanel
        $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $row.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)

        $num = New-Object System.Windows.Controls.Border
        $num.Width = 20
        $num.Height = 20
        $num.CornerRadius = [System.Windows.CornerRadius]::new(10)
        $num.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(60, $accent.Color.R, $accent.Color.G, $accent.Color.B))
        $num.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
        $num.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $numTxt = New-Object System.Windows.Controls.TextBlock
        $numTxt.Text = "$stepIdx"
        $numTxt.FontSize = 11
        $numTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $numTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
        $numTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $numTxt.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
        $numTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $num.Child = $numTxt
        $row.Children.Add($num) | Out-Null

        $stepTxt = New-Object System.Windows.Controls.TextBlock
        $stepTxt.Text = $s
        $stepTxt.FontSize = 12
        $stepTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cccccc")
        $stepTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $stepTxt.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $stepTxt.MaxWidth = 360
        $row.Children.Add($stepTxt) | Out-Null

        $tipStack.Children.Add($row) | Out-Null
        $stepIdx++
    }

    # Footer removed - the steps stand on their own.

    $tipOuter.Child = $tipInner
    $tooltip.Content = $tipOuter

    # The clickable button itself - same visual rhythm as the
    # Steam Theatre button (info icon + label, accent-tinted bg).
    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius  = [System.Windows.CornerRadius]::new(4)
    $btn.Padding       = [System.Windows.Thickness]::new(10, 6, 10, 6)
    $btn.Margin        = [System.Windows.Thickness]::new(0, 8, 0, 0)
    $btn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $btn.Cursor = [System.Windows.Input.Cursors]::Hand
    $tintFill = [System.Windows.Media.Color]::FromArgb([byte]30, $accent.Color.R, $accent.Color.G, $accent.Color.B)
    $btn.Background = New-Object System.Windows.Media.SolidColorBrush $tintFill
    $tintBorder = [System.Windows.Media.Color]::FromArgb([byte]160, $accent.Color.R, $accent.Color.G, $accent.Color.B)
    $btn.BorderBrush     = New-Object System.Windows.Media.SolidColorBrush $tintBorder
    $btn.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $btn.ToolTip = $tooltip
    [System.Windows.Controls.ToolTipService]::SetInitialShowDelay($btn, 200)
    [System.Windows.Controls.ToolTipService]::SetShowDuration($btn, 600000)

    $labelColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Min(255, $accent.Color.R + 30)),
        [byte]([Math]::Min(255, $accent.Color.G + 30)),
        [byte]([Math]::Min(255, $accent.Color.B + 30))
    )
    $labelBrush = New-Object System.Windows.Media.SolidColorBrush $labelColor

    $btnContent = New-Object System.Windows.Controls.StackPanel
    $btnContent.Orientation = [System.Windows.Controls.Orientation]::Horizontal

    # Trash-can icon - simple geometry: short top bar (lid) + body box
    $iconBox = New-Object System.Windows.Controls.Grid
    $iconBox.Width = 13; $iconBox.Height = 13
    $iconBox.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
    $iconBox.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $iconLid = New-Object System.Windows.Shapes.Rectangle
    $iconLid.Width = 11; $iconLid.Height = 1.5
    $iconLid.Fill = $labelBrush
    $iconLid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $iconLid.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    $iconLid.Margin = [System.Windows.Thickness]::new(0, 1, 0, 0)
    $iconBox.Children.Add($iconLid) | Out-Null
    $iconBody = New-Object System.Windows.Shapes.Rectangle
    $iconBody.Width = 8; $iconBody.Height = 9
    $iconBody.Stroke = $labelBrush
    $iconBody.StrokeThickness = 1.2
    $iconBody.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $iconBody.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
    $iconBox.Children.Add($iconBody) | Out-Null
    $btnContent.Children.Add($iconBox) | Out-Null

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = "Uninstall Guide"
    $lbl.FontSize = 12
    $lbl.FontWeight = [System.Windows.FontWeights]::Medium
    $lbl.Foreground = $labelBrush
    $lbl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $lbl.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $btnContent.Children.Add($lbl) | Out-Null
    $btn.Child = $btnContent

    # Click toggle (matches theatre-button behavior).
    $tooltipRef = $tooltip
    $btnRef     = $btn
    $btn.Add_MouseLeftButtonUp({
        param($s, $e)
        if ($tooltipRef.IsOpen) {
            $tooltipRef.IsOpen = $false
            $global:OpenTheatreTooltip = $null
            $global:OpenTheatreOwner   = $null
        } else {
            $tooltipRef.PlacementTarget = $this
            $tooltipRef.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom
            $tooltipRef.StaysOpen = $true
            $tooltipRef.IsOpen = $true
            $global:OpenTheatreTooltip = $tooltipRef
            $global:OpenTheatreOwner   = $btnRef
        }
        $e.Handled = $true
    }.GetNewClosure())

    $btn.Add_MouseLeave({
        if ($tooltipRef.IsOpen) {
            $tooltipRef.IsOpen = $false
            $global:OpenTheatreTooltip = $null
            $global:OpenTheatreOwner   = $null
        }
    }.GetNewClosure())

    Add-SweepHover -Border $btn
    return $btn
}

# Populate a TextBlock with text + clickable hyperlinks. Splits the
# input on URL patterns (http://, https://) and emits a Run for
# each plain-text chunk and a Hyperlink for each URL. The Hyperlink
# fires Start-Process on its NavigateUri when clicked so the user's
# default browser opens the page.
#
# Without this helper, README text was rendered as plain-text in
# a single TextBlock - URLs printed but were not clickable, which
# tripped up users who expected them to behave like links.
function global:Set-TextBlockWithLinks {
    param(
        [System.Windows.Controls.TextBlock]$TextBlock,
        [string]$Text,
        [string]$AccentHex = $null,
        [double]$BaseFont = 14
    )
    if (-not $TextBlock) { return }
    $TextBlock.Inlines.Clear()
    if ([string]::IsNullOrEmpty($Text)) { return }

    # We parse the text into typed spans (text / url / bold / code)
    # so the final TextBlock renders bold + inline code as real
    # Inlines instead of leaving raw `**` and `` ` `` in the
    # output. Order of parsing matters: URLs first (they may
    # contain `*` or `_`), then code (covers paths and command
    # names), then bold.
    $spans = New-Object System.Collections.Generic.List[object]
    $spans.Add(@{ Kind='text'; Text=$Text }) | Out-Null

    $splitFn = {
        param($inSpans, $pattern, $kind)
        $out = New-Object System.Collections.Generic.List[object]
        foreach ($s in $inSpans) {
            if ($s.Kind -ne 'text') { $out.Add($s) | Out-Null; continue }
            $cur = 0
            $matches = [regex]::Matches($s.Text, $pattern)
            foreach ($m in $matches) {
                if ($m.Index -gt $cur) {
                    $out.Add(@{ Kind='text'; Text=$s.Text.Substring($cur, $m.Index - $cur) }) | Out-Null
                }
                $inner = if ($m.Groups.Count -gt 1 -and $m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Value }
                $out.Add(@{ Kind=$kind; Text=$inner }) | Out-Null
                $cur = $m.Index + $m.Length
            }
            if ($cur -lt $s.Text.Length) {
                $out.Add(@{ Kind='text'; Text=$s.Text.Substring($cur) }) | Out-Null
            }
        }
        return $out
    }
    $spans = & $splitFn $spans '(?i)\bhttps?://[^\s<>"\)\],]+' 'url'

    # Combined bold+code first: **`text`** -> one bold-mono span.
    # Must run before the standalone bold/code passes, otherwise
    # the code pass eats the backticks and leaves the ** stranded
    # as literal text on either side.
    $spans = & $splitFn $spans '\*\*`([^`]+)`\*\*'           'boldcode'
    $spans = & $splitFn $spans '\*\*([^\*]+)\*\*'             'bold'
    $spans = & $splitFn $spans '`([^`]+)`'                    'code'

    # Typography pass: prettify dashes and arrows in prose. Runs after
    # url/bold/code are split out so it only touches plain text spans -
    # code spans (paths, commands like --flag) and URLs keep their literal
    # ASCII. "->" -> real arrow; " -- " and a spaced " - " used as a
    # sentence break -> em-dash. List bullets never reach here (the readme
    # parser strips "- " before calling this), so a " - " here is mid-line.
    # When an accent colour is supplied, the dash/arrow GLYPH is emitted as
    # its own 'accentsym' span so it renders tinted instead of plain white;
    # the surrounding spaces stay in the text spans. Without an accent the
    # glyph is just inlined as normal text.
    $emdash = [char]0x2014
    $arrow  = [char]0x2192
    $typoSplit = {
        param($inSpans)
        $out = New-Object System.Collections.Generic.List[object]
        foreach ($s in $inSpans) {
            if ($s.Kind -ne 'text') { $out.Add($s) | Out-Null; continue }
            $t = $s.Text
            # Normalise the three source forms to a single sentinel glyph
            # first, then split on the glyph so each becomes its own span.
            $t = $t -replace '\s*->\s*', (' ' + $arrow + ' ')
            $t = $t -replace '\s--\s',   (' ' + $emdash + ' ')
            $t = $t -replace '\s-\s',    (' ' + $emdash + ' ')
            if (-not $AccentHex) { $out.Add(@{ Kind='text'; Text=$t }) | Out-Null; continue }
            $cur = 0
            $matches = [regex]::Matches($t, "[$emdash$arrow]")
            if ($matches.Count -eq 0) { $out.Add(@{ Kind='text'; Text=$t }) | Out-Null; continue }
            foreach ($m in $matches) {
                if ($m.Index -gt $cur) {
                    $out.Add(@{ Kind='text'; Text=$t.Substring($cur, $m.Index - $cur) }) | Out-Null
                }
                $out.Add(@{ Kind='accentsym'; Text=$m.Value }) | Out-Null
                $cur = $m.Index + $m.Length
            }
            if ($cur -lt $t.Length) {
                $out.Add(@{ Kind='text'; Text=$t.Substring($cur) }) | Out-Null
            }
        }
        return $out
    }
    $spans = & $typoSplit $spans

    # Button pills: [[A]], [[Grip]], [[Both Back Buttons]] -> small grey
    # key-cap pills. Done LAST and across text AND bold spans, so a pill
    # written inside **bold** (e.g. "**[[A]] button**") keeps the rest of
    # the run bold instead of leaving stray ** in the output. A pill that
    # came from a bold span is tagged 'pill' either way (the cap styling
    # is the same); only the leftover words around it stay bold.
    $pillSplit = {
        param($inSpans)
        $out = New-Object System.Collections.Generic.List[object]
        foreach ($s in $inSpans) {
            if ($s.Kind -ne 'text' -and $s.Kind -ne 'bold') { $out.Add($s) | Out-Null; continue }
            $cur = 0
            $matches = [regex]::Matches($s.Text, '\[\[([^\]]+)\]\]')
            if ($matches.Count -eq 0) { $out.Add($s) | Out-Null; continue }
            foreach ($m in $matches) {
                if ($m.Index -gt $cur) {
                    $out.Add(@{ Kind=$s.Kind; Text=$s.Text.Substring($cur, $m.Index - $cur) }) | Out-Null
                }
                $out.Add(@{ Kind='pill'; Text=$m.Groups[1].Value }) | Out-Null
                $cur = $m.Index + $m.Length
            }
            if ($cur -lt $s.Text.Length) {
                $out.Add(@{ Kind=$s.Kind; Text=$s.Text.Substring($cur) }) | Out-Null
            }
        }
        return $out
    }
    $spans = & $pillSplit $spans

    foreach ($s in $spans) {
        switch ($s.Kind) {
            'text' {
                $run = New-Object System.Windows.Documents.Run $s.Text
                $TextBlock.Inlines.Add($run) | Out-Null
            }
            'accentsym' {
                # Em-dash / arrow tinted in the game's accent colour so the
                # separator reads as a soft themed glyph instead of a hard
                # white bar. SemiBold gives it just enough presence.
                $run = New-Object System.Windows.Documents.Run $s.Text
                $run.FontWeight = [System.Windows.FontWeights]::SemiBold
                try {
                    $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                } catch { }
                $TextBlock.Inlines.Add($run) | Out-Null
            }
            'bold' {
                $run = New-Object System.Windows.Documents.Run $s.Text
                $run.FontWeight = [System.Windows.FontWeights]::Bold
                $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e8e8f0")
                $TextBlock.Inlines.Add($run) | Out-Null
            }
            'boldcode' {
                # **`x`** - bold weight + monospace + warm code tint.
                $run = New-Object System.Windows.Documents.Run $s.Text
                $run.FontWeight = [System.Windows.FontWeights]::Bold
                $run.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas, Cascadia Mono, Courier New")
                $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e6c992")
                $TextBlock.Inlines.Add($run) | Out-Null
            }
            'code' {
                # Inline code: monospace + subtle warm tint, no
                # background box (would break line height). Reads
                # as "this is a file/command/path token".
                $run = New-Object System.Windows.Documents.Run $s.Text
                $run.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas, Cascadia Mono, Courier New")
                $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e6c992")
                $TextBlock.Inlines.Add($run) | Out-Null
            }
            'pill' {
                # Controller-button key-cap: small neutral grey rounded
                # pill. Neutral (not accent) so single letters stay
                # legible regardless of the game's accent colour. All
                # dimensions are derived from $BaseFont (the surrounding
                # readme text size) so the pill grows/shrinks with S/M/L
                # instead of staying a fixed size while the text scales.
                # Reference ratios are tuned at BaseFont 14 (= the old
                # fixed values: font 10.5, height 17, pad 6/1, radius 8,
                # line 13).
                $pillFont   = [math]::Round($BaseFont * 0.75, 1)
                $pillHeight = [int][math]::Round($BaseFont * 1.214)
                $pillPadX   = [int][math]::Round($BaseFont * 0.43)
                $pillRadius = [math]::Round($BaseFont * 0.571, 1)
                $pillLine   = [int][math]::Round($BaseFont * 0.929)
                $pill = New-Object System.Windows.Controls.Border
                $pill.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a36")
                $pill.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
                $pill.BorderThickness = [System.Windows.Thickness]::new(1)
                $pill.CornerRadius    = [System.Windows.CornerRadius]::new($pillRadius)
                $pill.Padding         = [System.Windows.Thickness]::new($pillPadX, 1, $pillPadX, 1)
                $pill.Height          = $pillHeight
                $pill.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $ptxt = New-Object System.Windows.Controls.TextBlock
                $ptxt.Text = $s.Text
                $ptxt.FontSize = $pillFont
                $ptxt.FontWeight = [System.Windows.FontWeights]::SemiBold
                $ptxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dddde6")
                $ptxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $ptxt.TextAlignment = [System.Windows.TextAlignment]::Center
                $ptxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
                $ptxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $ptxt.MinWidth = 8
                $ptxt.Margin = [System.Windows.Thickness]::new(0)
                $ptxt.Padding = [System.Windows.Thickness]::new(0)
                $ptxt.LineHeight = $pillLine
                $ptxt.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
                $pill.Child = $ptxt
                $container = New-Object System.Windows.Documents.InlineUIContainer $pill
                $container.BaselineAlignment = [System.Windows.BaselineAlignment]::Center
                $TextBlock.Inlines.Add($container) | Out-Null
            }
            'url' {
                $url = $s.Text
                $trim = '.,;:!?'
                while ($url.Length -gt 0 -and $trim.Contains($url[$url.Length - 1])) {
                    $url = $url.Substring(0, $url.Length - 1)
                }
                $hyperlink = New-Object System.Windows.Documents.Hyperlink
                $linkText = New-Object System.Windows.Documents.Run $url
                $hyperlink.Inlines.Add($linkText) | Out-Null
                try { $hyperlink.NavigateUri = New-Object System.Uri($url) } catch { }
                $hyperlink.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#6cb6ff")
                $hyperlink.TextDecorations = $null
                $hyperlink.Cursor = [System.Windows.Input.Cursors]::Hand
                $urlCapture = $url
                $hyperlink.Add_Click({
                    try { Start-Process $urlCapture } catch { }
                }.GetNewClosure())
                $hyperlink.Add_MouseEnter({
                    $this.TextDecorations = [System.Windows.TextDecorations]::Underline
                })
                $hyperlink.Add_MouseLeave({
                    $this.TextDecorations = $null
                })
                $TextBlock.Inlines.Add($hyperlink) | Out-Null
            }
        }
    }
}

function global:New-DetailSection {
    param(
        [string]$Heading,
        [string]$Body,
        [string]$AccentHex = "#666677",
        $AppendChild = $null,
        [string]$ImageBaseDir = $null
    )
    # Markdown -> nice typography. Source is ASCII via [char]
    # escapes so the release audit stays clean. The actual
    # bold/code inline parsing happens in Set-TextBlockWithLinks
    # below; this scope only handles per-line layout:
    #   * `- foo`  / `* foo`   -> indented bullet with U+2022 dot
    #   * `1. foo` / `2. foo`  -> indented number with extra space
    # Headings (`## ...`) inside the body are stripped - the
    # section already has a heading at the top.
    $bullet = [char]0x2022
    $bulletReplace = "  $bullet "

    # Single function used by all three rendering paths below
    # (image-mode pre-chunk, image-mode tail, no-image body).
    # Removes leading hash headings, normalises bullets and
    # numbered steps, collapses 3+ blank lines to 2. The bold
    # markers `**...**` and inline code `` ` `` are LEFT in -
    # Set-TextBlockWithLinks renders them as real bold / mono runs.
    # Sentinel char that marks a "code block line" - renderBody
    # turns these into monospace rows with a subtle chip bg. Using
    # a control char keeps it from ever colliding with real text.
    $codeMark = [char]0x0001
    # A copyable launch-command line (single-line launch args or a
    # console command). Renders as a code chip with click-to-copy.
    $copyMark = [char]0x0005
    # A flavour "quip" line (markdown prefix '>>> '). Rendered as a
    # single accent-coloured box with no heading at the very end.
    $quipMark = [char]0x0006
    # Table sentinels: $tableMark prefixes a markdown table row, with
    # cells joined by $cellSep. $tableHdr marks the header row so it
    # renders bolder. The |---| separator line is dropped.
    $tableMark = [char]0x0002
    $tableHdr  = [char]0x0003
    $cellSep   = [char]0x0004
    $formatBody = {
        param([string]$txt)
        if (-not $txt) { return $txt }
        $txt = $txt -replace "`r`n", "`n"
        $lines = $txt -split "`n"
        $out = New-Object System.Collections.Generic.List[string]
        $blankRun = 0
        $inStep = $false   # are we inside a numbered step (for continuation indent)?
        $inBullet = $false # are we inside a bullet (for continuation indent)?
        $inFence = $false  # are we inside a ``` code fence?
        $copyFence = $false # is the current fence a copyable launch command?
        $lastWasParagraph = $false  # was the previous emitted line a plain paragraph?
        for ($li = 0; $li -lt $lines.Count; $li++) {
            $raw = $lines[$li]
            $line = $raw
            # Code fence toggle: a line that is just ``` (optionally
            # with a language tag like ```bash). Don't emit the
            # fence marker line itself.
            if ($line -match '^[ \t]*```') {
                if (-not $inFence) {
                    # Opening a fence: look ahead to decide whether
                    # this is a COPYABLE launch command. Only single
                    # non-empty content lines that look like launch
                    # parameters / console commands qualify - NOT
                    # multi-line config blocks, file paths, or cvar
                    # dumps. Heuristic: exactly one content line, and
                    # it starts with '-' (launch args like
                    # "-overridenohmd -dx11") or "download_depot" /
                    # "steam" style console commands.
                    $content = New-Object System.Collections.Generic.List[string]
                    $j = $li + 1
                    while ($j -lt $lines.Count -and ($lines[$j] -notmatch '^[ \t]*```')) {
                        if (($lines[$j] -replace '[ \t]+$', '').Trim() -ne '') {
                            $content.Add($lines[$j].Trim()) | Out-Null
                        }
                        $j++
                    }
                    $copyFence = $false
                    if ($content.Count -eq 1) {
                        $c0 = $content[0]
                        if ($c0 -match '^-' -or $c0 -match '^(?i)(download_depot|app_update|steam|steamcmd)\b') {
                            $copyFence = $true
                        }
                    }
                }
                $inFence = -not $inFence
                if (-not $inFence) { $copyFence = $false }
                $inStep = $false
                continue
            }
            if ($inFence) {
                # Inside a fence: keep the line verbatim (trim only
                # trailing ws) and tag it as a code line. A copyable
                # launch command gets $copyMark instead of $codeMark.
                $mark = if ($copyFence) { $copyMark } else { $codeMark }
                $out.Add($mark + ($line -replace '[ \t]+$', '')) | Out-Null
                $lastWasParagraph = $false
                $inStep = $false
                $inBullet = $false
                continue
            }
            if ($line -match '^[ \t]*#{1,6}[ \t]+\S') { continue }
            $line = $line -replace '[ \t]+$', ''
            # Markdown table row: a line that starts with '|' and has
            # at least one more '|'. The |---|---| separator line is
            # dropped. Each row becomes a $tableMark-tagged line with
            # cells joined by $cellSep; the first row of a table is
            # tagged as the header.
            $tt = $line.TrimStart()
            if ($tt -match '^\|.*\|' ) {
                # Separator row (only -, :, |, spaces) -> drop, but it
                # confirms the row above was a header.
                if ($tt -match '^\|[\s:|-]+\|?\s*$' -and ($tt -match '-')) {
                    if ($out.Count -gt 0 -and $out[$out.Count - 1].Length -gt 0 -and $out[$out.Count - 1][0] -eq $tableMark) {
                        $out[$out.Count - 1] = $tableHdr + $out[$out.Count - 1].Substring(1)
                    }
                    $inStep = $false; $inBullet = $false; $lastWasParagraph = $false
                    continue
                }
                # Data/header row: split on '|', drop the empty first
                # and last fields from the leading/trailing pipes.
                $cells = $tt -split '\|'
                $cells = $cells[1..($cells.Count - 1)]
                if ($cells.Count -gt 0 -and $cells[$cells.Count - 1].Trim() -eq '') {
                    $cells = $cells[0..($cells.Count - 2)]
                }
                $cells = $cells | ForEach-Object { $_.Trim() }
                $out.Add($tableMark + ($cells -join $cellSep)) | Out-Null
                $inStep = $false; $inBullet = $false; $lastWasParagraph = $false
                continue
            }
            # Flavour quip: a line beginning with '>>> '. Rendered as a
            # standalone accent box at the end. Strip the marker.
            if ($line -match '^[ \t]*>>>[ \t]?') {
                $qtext = $line -replace '^[ \t]*>>>[ \t]?', ''
                $out.Add($quipMark + $qtext.Trim()) | Out-Null
                $inStep = $false; $inBullet = $false; $lastWasParagraph = $false
                continue
            }
            $hadIndent = ($line -match '^[ \t]+\S')
            $trimmed = $line.TrimStart()
            if ($trimmed -eq '') {
                $blankRun++
                if ($blankRun -le 1) { $out.Add('') | Out-Null }
                $inStep = $false
                $inBullet = $false
                $lastWasParagraph = $false
                continue
            }
            $blankRun = 0
            if ($trimmed -match '^[-*][ \t]+(.*)$') {
                $out.Add($bulletReplace + $Matches[1]) | Out-Null
                $inStep = $false
                $inBullet = $true
                $lastWasParagraph = $false
            } elseif ($trimmed -match '^(\d+)\.[ \t]+(.*)$') {
                # Numbered step: flush-left "N. text" - no leading
                # indent, so 1..9 all start at the same column.
                $out.Add($Matches[1] + ". " + $Matches[2]) | Out-Null
                $inStep = $true
                $inBullet = $false
                $lastWasParagraph = $false
            } elseif (($inStep -or $inBullet) -and $hadIndent) {
                # Continuation line of the current step/bullet.
                # Markdown soft-wraps it, so append to the previous
                # line's text with a space rather than emitting a
                # separate hard-break line - the TextBlock then
                # wraps it naturally and the bullet/step stays as
                # one indented block.
                if ($out.Count -gt 0) {
                    $out[$out.Count - 1] = $out[$out.Count - 1] + " " + $trimmed
                } else {
                    $out.Add($trimmed) | Out-Null
                }
                $lastWasParagraph = $false
            } else {
                # Plain paragraph line. In Markdown a single newline
                # inside a paragraph is a soft wrap (renders as a
                # space), not a hard break - only blank lines split
                # paragraphs. So if the previous emitted line was
                # also a plain paragraph line, append to it with a
                # space rather than starting a new element.
                if ($lastWasParagraph -and $out.Count -gt 0) {
                    $out[$out.Count - 1] = $out[$out.Count - 1] + " " + $trimmed
                } else {
                    $out.Add($trimmed) | Out-Null
                }
                $inStep = $false
                $inBullet = $false
                $lastWasParagraph = $true
            }
        }
        return (($out -join "`n").Trim())
    }

    # ---- size config (drives heading + body scale together) ----
    $rmCfg0 = $global:DetailTextSizes[$global:DetailSize]
    if (-not $rmCfg0) { $rmCfg0 = $global:DetailTextSizes["M"] }
    # Heading sits a few pt above the body and scales with it.
    $headFont = [int]$rmCfg0.Font + 1

    # ---- per-line body renderer -------------------------------
    # Renders a cleaned body string line-by-line into $target:
    #   * "  <dot> text"  (level-1)  -> accent dot + text
    #   * "<square> text" (level-2)  -> dim square + indented text
    #   * "N. text"       (step)     -> outline number badge + text
    #   * anything else              -> plain wrapped paragraph
    # Bold (**) and code (` `) inside each line are rendered as
    # real runs by Set-TextBlockWithLinks. Every text block is
    # registered for live S/M/L resizing.
    $sq = [char]0x25AA   # small black square (level-2 bullet)
    # Cap all readme text at one comfortable reading width so long
    # sentences don't shoot across the whole pane once they sit
    # below the Similar Games column. ~720px keeps lines roughly
    # the same length as the top "What this installer does" block.
    # Readme text width scales with the window so a maximised
    # window doesn't leave a huge empty band on the right, but is
    # clamped so lines never get fatiguingly long. ~65% of the
    # window width, between 720 (small) and 1040 (large) - the
    # upper bound adds roughly 5-6 words per line vs the floor.
    $readmeMaxW = 720
    try {
        $winW = 0
        if ($global:discoverDetail -and $global:discoverDetail.ActualWidth -gt 0) {
            $winW = $global:discoverDetail.ActualWidth
        } elseif ($global:window -and $global:window.ActualWidth -gt 0) {
            $winW = $global:window.ActualWidth
        }
        if ($winW -gt 0) {
            $calc = [int]($winW * 0.78)
            if ($calc -lt 720)  { $calc = 720 }
            if ($calc -gt 1040) { $calc = 1040 }
            $readmeMaxW = $calc
        }
    } catch { }
    $renderBody = {
        param($target, [string]$cleaned)
        if (-not $cleaned) { return }
        $cfg = $global:DetailTextSizes[$global:DetailSize]
        if (-not $cfg) { $cfg = $global:DetailTextSizes["M"] }
        foreach ($ln in ($cleaned -split "`n")) {
            # Code-fence line: sentinel-prefixed. Render as a
            # monospace row inside a subtle dark chip so launch
            # options / commands stand out as copy-pasteable code.
            # Plain code-fence line ($codeMark): a monospace chip for
            # config blocks, paths, cvars. NOT clickable - these aren't
            # one-shot commands you'd copy wholesale.
            if ($ln.Length -gt 0 -and $ln[0] -eq $codeMark) {
                $codeText = $ln.Substring(1)
                # Blank line inside a fence: skip it rather than draw an
                # empty chip box.
                if ($codeText.Trim() -eq '') { continue }
                $codeBox = New-Object System.Windows.Controls.Border
                $codeBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c1c24")
                $codeBox.BorderThickness = [System.Windows.Thickness]::new(1)
                $codeBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a34")
                $codeBox.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $codeBox.Padding = [System.Windows.Thickness]::new(10, 5, 10, 5)
                $codeBox.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)
                $codeBox.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                $ctb = New-Object System.Windows.Controls.TextBlock
                $ctb.Text = $codeText
                $ctb.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas, Cascadia Mono, Courier New")
                $ctb.FontSize = $cfg.Font
                $ctb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e6c992")
                $ctb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $codeBox.Child = $ctb
                $target.Children.Add($codeBox) | Out-Null
                if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($ctb) | Out-Null }
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($ctb) | Out-Null }
                continue
            }

            # Copyable launch command ($copyMark): a single-line launch
            # parameter or console command. Click anywhere on the chip
            # to copy it. The hover tooltip says "Copy", so no icon is
            # needed; a brief "Copied!" confirms the action.
            if ($ln.Length -gt 0 -and $ln[0] -eq $copyMark) {
                $codeText = $ln.Substring(1)
                $codeBox = New-Object System.Windows.Controls.Border
                $codeBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c1c24")
                $codeBox.BorderThickness = [System.Windows.Thickness]::new(1)
                $codeBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a34")
                $codeBox.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $codeBox.Padding = [System.Windows.Thickness]::new(10, 5, 10, 5)
                $codeBox.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)
                $codeBox.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                $codeBox.Cursor = [System.Windows.Input.Cursors]::Hand
                $codeBox.ToolTip = "Copy on click"
                $cgrid = New-Object System.Windows.Controls.Grid
                $cc0 = New-Object System.Windows.Controls.ColumnDefinition
                $cc0.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
                $cc1 = New-Object System.Windows.Controls.ColumnDefinition
                $cc1.Width = [System.Windows.GridLength]::Auto
                $cgrid.ColumnDefinitions.Add($cc0)
                $cgrid.ColumnDefinitions.Add($cc1)
                $ctb = New-Object System.Windows.Controls.TextBlock
                $ctb.Text = $codeText
                $ctb.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas, Cascadia Mono, Courier New")
                $ctb.FontSize = $cfg.Font
                $ctb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e6c992")
                $ctb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $ctb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                [System.Windows.Controls.Grid]::SetColumn($ctb, 0)
                $cgrid.Children.Add($ctb) | Out-Null
                # Status label only (no icon - the tooltip already says
                # "Copy"). Flips to "Copied!" briefly on click.
                $copyStatus = New-Object System.Windows.Controls.TextBlock
                $copyStatus.Text = ""
                $copyStatus.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $copyStatus.FontSize = [int]$cfg.Font - 2
                $copyStatus.FontWeight = [System.Windows.FontWeights]::SemiBold
                $copyStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fcf80")
                $copyStatus.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $copyStatus.Margin = [System.Windows.Thickness]::new(10, 0, 2, 0)
                [System.Windows.Controls.Grid]::SetColumn($copyStatus, 1)
                $cgrid.Children.Add($copyStatus) | Out-Null
                $codeBox.Child = $cgrid
                $codeBox.Tag = [PSCustomObject]@{ Text = $codeText; Status = $copyStatus; Box = $codeBox }
                $codeBox.Add_MouseLeftButtonUp({
                    param($s, $e)
                    try {
                        $info = $s.Tag
                        [System.Windows.Clipboard]::SetText($info.Text)
                        $info.Status.Text = "Copied!"
                        # Confirming glow: briefly tint the chip green so
                        # there's a clear visual signal the copy worked.
                        $s.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16301f")
                        $s.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fcf80")
                        $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
                        $glow.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#5fcf80")
                        $glow.BlurRadius = 14
                        $glow.ShadowDepth = 0
                        $glow.Opacity = 0.85
                        $s.Effect = $glow
                        $tmr = New-Object System.Windows.Threading.DispatcherTimer
                        $tmr.Interval = [TimeSpan]::FromSeconds(1.6)
                        $tmr.Tag = $info
                        $tmr.Add_Tick({
                            param($ts, $te)
                            $ts.Stop()
                            $ts.Tag.Status.Text = ""
                            # Revert the glow + tint cleanly.
                            $b = $ts.Tag.Box
                            $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c1c24")
                            $b.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a34")
                            $b.Effect = $null
                        })
                        $tmr.Start()
                    } catch {}
                })
                $codeBox.Add_MouseEnter({
                    param($s, $e)
                    # Don't fight the green confirm glow if it's active.
                    if ($null -ne $s.Effect) { return }
                    $s.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#24242e")
                    $s.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a46")
                })
                $codeBox.Add_MouseLeave({
                    param($s, $e)
                    # Leave the confirm glow intact if it's showing.
                    if ($null -ne $s.Effect) { return }
                    $s.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c1c24")
                    $s.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a34")
                })
                $target.Children.Add($codeBox) | Out-Null
                if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($ctb) | Out-Null }
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($ctb) | Out-Null }
                continue
            }
            if ($ln.Trim() -eq '') { continue }

            # Flavour quip ($quipMark): a single accent-coloured box
            # with no heading, used as a closing one-liner. Consistent
            # look across all readmes.
            if ($ln.Length -gt 0 -and $ln[0] -eq $quipMark) {
                $qtext = $ln.Substring(1)
                $qBox = New-Object System.Windows.Controls.Border
                $qBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161e")
                $qBox.BorderThickness = [System.Windows.Thickness]::new(0, 0, 0, 0)
                $qBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                $qBox.CornerRadius = [System.Windows.CornerRadius]::new(6)
                $qBox.Padding = [System.Windows.Thickness]::new(14, 10, 14, 10)
                $qBox.Margin = [System.Windows.Thickness]::new(0, 14, 0, 4)
                $qBox.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                $qBox.MaxWidth = $readmeMaxW
                # Accent bar on the left edge for a clean, branded look.
                $qBox.BorderThickness = [System.Windows.Thickness]::new(3, 0, 0, 0)
                $qtb = New-Object System.Windows.Controls.TextBlock
                $qtb.Text = $qtext
                $qtb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $qtb.FontSize = [int]$cfg.Font + 1
                $qtb.FontStyle = [System.Windows.FontStyles]::Italic
                $qtb.FontWeight = [System.Windows.FontWeights]::SemiBold
                $qtb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                $qtb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $qBox.Child = $qtb
                $target.Children.Add($qBox) | Out-Null
                if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($qtb) | Out-Null }
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($qBox) | Out-Null }
                continue
            }

            # a subtle striped chip so multi-column control lists read
            # as a real table rather than raw "| a | b |" text.
            if ($ln.Length -gt 0 -and ($ln[0] -eq $tableMark -or $ln[0] -eq $tableHdr)) {
                $isHdr = ($ln[0] -eq $tableHdr)
                $cells = $ln.Substring(1) -split ([regex]::Escape([string]$cellSep))
                # Defensive: an all-empty header row (e.g. "| | |") would
                # render as a blank highlighted bar - skip it entirely.
                if ($isHdr -and (($cells | Where-Object { $_.Trim() -ne '' }).Count -eq 0)) { continue }
                $rowBorder = New-Object System.Windows.Controls.Border
                if ($isHdr) {
                    $rowBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c1c24")
                } else {
                    $rowBorder.Background = [System.Windows.Media.Brushes]::Transparent
                }
                $rowBorder.BorderThickness = [System.Windows.Thickness]::new(0, 0, 0, 1)
                $rowBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a34")
                $rowBorder.Padding = [System.Windows.Thickness]::new(8, 5, 8, 5)
                $rowBorder.MaxWidth = $readmeMaxW
                $rowBorder.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                $grid = New-Object System.Windows.Controls.Grid
                for ($ci = 0; $ci -lt $cells.Count; $ci++) {
                    $cd = New-Object System.Windows.Controls.ColumnDefinition
                    if ($ci -eq 0 -and $cells.Count -gt 1) {
                        $cd.Width = [System.Windows.GridLength]::new(170)
                    } else {
                        $cd.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
                    }
                    $grid.ColumnDefinitions.Add($cd)
                }
                for ($ci = 0; $ci -lt $cells.Count; $ci++) {
                    $ctb = New-Object System.Windows.Controls.TextBlock
                    Set-TextBlockWithLinks -TextBlock $ctb -Text $cells[$ci] -AccentHex $AccentHex -BaseFont $rmCfg0.Font
                    $ctb.FontSize = $cfg.Font
                    $ctb.LineHeight = $cfg.LineHeight
                    $ctb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                    $ctb.Margin = [System.Windows.Thickness]::new(0, 0, 12, 0)
                    $ctb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                    if ($isHdr) {
                        $ctb.FontWeight = [System.Windows.FontWeights]::SemiBold
                        $ctb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                    } else {
                        $ctb.FontWeight = [System.Windows.FontWeights]::Medium
                        $ctb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c8c8d4")
                    }
                    [System.Windows.Controls.Grid]::SetColumn($ctb, $ci)
                    $grid.Children.Add($ctb) | Out-Null
                    if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($ctb) | Out-Null }
                }
                $rowBorder.Child = $grid
                $target.Children.Add($rowBorder) | Out-Null
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($rowBorder) | Out-Null }
                continue
            }

            $isB1 = $ln -match ('^\s*' + [regex]::Escape($bullet) + '\s+(.*)$')
            $b1text = if ($isB1) { $Matches[1] } else { $null }
            # Level-2 bullet: starts with the square marker
            $isB2 = $ln -match ('^\s*' + [regex]::Escape($sq) + '\s+(.*)$')
            $b2text = if ($isB2) { $Matches[1] } else { $null }
            # Numbered step
            $isStep = $ln -match '^(\d+)\.\s+(.*)$'
            $stepNum = if ($isStep) { $Matches[1] } else { $null }
            $stepTxt = if ($isStep) { $Matches[2] } else { $null }

            if ($isStep) {
                $row = New-Object System.Windows.Controls.StackPanel
                $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal
                $row.Margin = [System.Windows.Thickness]::new(0, 3, 0, 3)
                $badgeSize = [int]$cfg.Font + 8
                $badge = New-Object System.Windows.Controls.Border
                $badge.Width = $badgeSize
                $badge.Height = $badgeSize
                $badge.CornerRadius = [System.Windows.CornerRadius]::new($badgeSize / 2)
                $badge.BorderThickness = [System.Windows.Thickness]::new(1.5)
                $badge.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                $badge.Background = [System.Windows.Media.Brushes]::Transparent
                $badge.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
                $badge.Margin = [System.Windows.Thickness]::new(0, 1, 10, 0)
                $bnum = New-Object System.Windows.Controls.TextBlock
                $bnum.Text = $stepNum
                $bnum.FontSize = [int]$cfg.Font - 2
                $bnum.FontWeight = [System.Windows.FontWeights]::Bold
                $bnum.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                $bnum.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
                $bnum.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $badge.Child = $bnum
                $row.Children.Add($badge) | Out-Null
                $stb = New-Object System.Windows.Controls.TextBlock
                Set-TextBlockWithLinks -TextBlock $stb -Text $stepTxt -AccentHex $AccentHex -BaseFont $rmCfg0.Font
                $stb.FontSize = $cfg.Font
                $stb.LineHeight = $cfg.LineHeight
                $stb.FontWeight = [System.Windows.FontWeights]::Medium
                $stb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $stb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c8c8d4")
                $stb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $stb.MaxWidth = $readmeMaxW
                $row.Children.Add($stb) | Out-Null
                $target.Children.Add($row) | Out-Null
                if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($stb) | Out-Null }
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($stb) | Out-Null }
                continue
            }

            if ($isB1 -or $isB2) {
                $row = New-Object System.Windows.Controls.StackPanel
                $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal
                $leftMargin = if ($isB2) { 22 } else { 0 }
                $row.Margin = [System.Windows.Thickness]::new($leftMargin, 3, 0, 3)
                $mk = New-Object System.Windows.Controls.TextBlock
                if ($isB2) {
                    $mk.Text = "$sq"
                    $mk.FontSize = [int]$cfg.Font - 3
                    $mk.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8a8a98")
                } else {
                    $mk.Text = "$bullet"
                    $mk.FontSize = $cfg.Font
                    $mk.FontWeight = [System.Windows.FontWeights]::Bold
                    $mk.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
                }
                $mk.LineHeight = $cfg.LineHeight
                $mk.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
                $mk.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
                $mk.MinWidth = 10
                $row.Children.Add($mk) | Out-Null
                $btb = New-Object System.Windows.Controls.TextBlock
                $bodyText = if ($isB2) { $b2text } else { $b1text }
                Set-TextBlockWithLinks -TextBlock $btb -Text $bodyText -AccentHex $AccentHex -BaseFont $rmCfg0.Font
                $btb.FontSize = $cfg.Font
                $btb.LineHeight = $cfg.LineHeight
                $btb.FontWeight = [System.Windows.FontWeights]::Medium
                $btb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $btb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c8c8d4")
                $btb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                $btb.MaxWidth = $readmeMaxW
                $row.Children.Add($btb) | Out-Null
                $target.Children.Add($row) | Out-Null
                if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($btb) | Out-Null }
                if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($btb) | Out-Null }
                continue
            }

            # Plain paragraph line
            $ptb = New-Object System.Windows.Controls.TextBlock
            Set-TextBlockWithLinks -TextBlock $ptb -Text $ln -AccentHex $AccentHex -BaseFont $rmCfg0.Font
            $ptb.FontSize = $cfg.Font
            $ptb.LineHeight = $cfg.LineHeight
            $ptb.FontWeight = [System.Windows.FontWeights]::Medium
            $ptb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $ptb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c8c8d4")
            $ptb.TextWrapping = [System.Windows.TextWrapping]::Wrap
            $ptb.MaxWidth = $readmeMaxW
            $ptb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
            $ptb.Margin = [System.Windows.Thickness]::new(0, 2, 0, 2)
            $target.Children.Add($ptb) | Out-Null
            if ($null -ne $global:DetailReadmeTextBlocks) { $global:DetailReadmeTextBlocks.Add($ptb) | Out-Null }
            if ($null -ne $global:DetailWidthBlocks) { $global:DetailWidthBlocks.Add($ptb) | Out-Null }
        }
    }
    $box = New-Object System.Windows.Controls.Border
    $box.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $box.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#13131a")
    $box.BorderThickness = [System.Windows.Thickness]::new(1)
    $box.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
    $box.Padding = [System.Windows.Thickness]::new(14, 10, 14, 12)
    $box.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)

    $stack = New-Object System.Windows.Controls.StackPanel
    $box.Child = $stack

    # Accent left bar in heading row
    $headRow = New-Object System.Windows.Controls.StackPanel
    $headRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $headRow.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
    $bar = New-Object System.Windows.Controls.Border
    $bar.Width = 3
    $bar.CornerRadius = [System.Windows.CornerRadius]::new(2)
    $bar.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
    $bar.Margin = [System.Windows.Thickness]::new(0, 1, 8, 1)
    $headRow.Children.Add($bar) | Out-Null

    $h = New-Object System.Windows.Controls.TextBlock
    $h.Text = $Heading
    $h.FontSize = $headFont
    $h.FontWeight = [System.Windows.FontWeights]::SemiBold
    $h.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#f0f0f4")
    $h.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $headRow.Children.Add($h) | Out-Null
    $stack.Children.Add($headRow) | Out-Null
    # Register the heading so Apply-DetailSize can rescale it with
    # the body. We tag it as a heading so the resizer knows to use
    # font+1 rather than the plain body size.
    if ($null -ne $global:DetailReadmeTextBlocks) {
        $h.Tag = "heading"
        $global:DetailReadmeTextBlocks.Add($h) | Out-Null
    }

    # Body rendering: split out markdown image syntax
    # `![alt](path)` so we can show the image as a real Image
    # control instead of leaving it as visible text. Anything
    # between two image tokens (or before/after them) is rendered
    # as a normal TextBlock with the existing bullet/bold cleanup.
    $imgRegex = '!\[[^\]]*\]\(([^)]+)\)'
    $imgMatches = [regex]::Matches($Body, $imgRegex)

    if ($imgMatches.Count -gt 0 -and $ImageBaseDir) {
        $cursor = 0
        foreach ($m in $imgMatches) {
            # Text before the image
            if ($m.Index -gt $cursor) {
                $textChunk = $Body.Substring($cursor, $m.Index - $cursor)
                $cleaned = & $formatBody $textChunk
                & $renderBody $stack $cleaned
            }
            # The image itself (resolve relative to the README's folder)
            $rel = $m.Groups[1].Value
            $abs = if ([System.IO.Path]::IsPathRooted($rel)) { $rel } else { Join-Path $ImageBaseDir $rel }
            if (Test-Path $abs) {
                try {
                    $img = New-Object System.Windows.Controls.Image
                    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $bmp.BeginInit()
                    $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $bmp.UriSource = New-Object System.Uri($abs, [System.UriKind]::Absolute)
                    $bmp.EndInit()
                    if ($bmp.CanFreeze) { $bmp.Freeze() }
                    $img.Source = $bmp
                    $img.Stretch = [System.Windows.Media.Stretch]::Uniform
                    $img.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                    # Inline preview can use most of the detail
                    # pane width so labels stay readable. The
                    # click-to-enlarge handler below opens the
                    # full image.
                    $img.MaxWidth = 900
                    $img.Cursor = [System.Windows.Input.Cursors]::Hand
                    $img.ToolTip = "Click to enlarge"
                    # Keep the tooltip short-lived so it doesn't linger
                    # after the mouse moves away.
                    [System.Windows.Controls.ToolTipService]::SetInitialShowDelay($img, 300)
                    [System.Windows.Controls.ToolTipService]::SetShowDuration($img, 1500)
                    $img.Margin = [System.Windows.Thickness]::new(0, 4, 0, 8)
                    # Stash the absolute path on the control so the
                    # click handler can find it without closure
                    # capture (PS5 quirks with $abs in closures).
                    $img.Tag = $abs
                    $img.Add_MouseLeftButtonUp({
                        param($s, $e)
                        $path = $s.Tag
                        if (-not $path -or -not (Test-Path $path)) { return }
                        try {
                            # Lightbox window: borderless, near-fullscreen,
                            # dark backdrop. Click anywhere or press Esc
                            # closes. We size the window to fit the
                            # working area minus a 60px margin so the
                            # image always has breathing room.
                            $sb = [System.Windows.SystemParameters]
                            $wa = $sb::WorkArea
                            $win = New-Object System.Windows.Window
                            $win.WindowStyle  = [System.Windows.WindowStyle]::None
                            $win.AllowsTransparency = $true
                            $win.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cc000000")
                            $win.ShowInTaskbar = $false
                            $win.WindowStartupLocation = [System.Windows.WindowStartupLocation]::Manual
                            $win.Left   = $wa.Left + 30
                            $win.Top    = $wa.Top + 30
                            $win.Width  = $wa.Width - 60
                            $win.Height = $wa.Height - 60
                            $win.Topmost = $true
                            $win.ResizeMode = [System.Windows.ResizeMode]::NoResize
                            try {
                                if ($global:window) { $win.Owner = $global:window }
                            } catch {}
                            $grid = New-Object System.Windows.Controls.Grid
                            $bigImg = New-Object System.Windows.Controls.Image
                            $bigBmp = New-Object System.Windows.Media.Imaging.BitmapImage
                            $bigBmp.BeginInit()
                            $bigBmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                            $bigBmp.UriSource = New-Object System.Uri($path, [System.UriKind]::Absolute)
                            $bigBmp.EndInit()
                            if ($bigBmp.CanFreeze) { $bigBmp.Freeze() }
                            $bigImg.Source = $bigBmp
                            $bigImg.Stretch = [System.Windows.Media.Stretch]::Uniform
                            $bigImg.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
                            $bigImg.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
                            $bigImg.Margin = [System.Windows.Thickness]::new(20)
                            $grid.Children.Add($bigImg) | Out-Null
                            # Hint label in top-right corner
                            $hint = New-Object System.Windows.Controls.TextBlock
                            $hint.Text = "Click anywhere or press Esc to close"
                            $hint.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cccccc")
                            $hint.FontSize = 12
                            $hint.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
                            $hint.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
                            $hint.Margin = [System.Windows.Thickness]::new(0, 12, 18, 0)
                            $hint.IsHitTestVisible = $false
                            $grid.Children.Add($hint) | Out-Null
                            $win.Content = $grid
                            $win.Add_MouseLeftButtonUp({ param($a, $b) try { $a.Close() } catch {} })
                            $win.Add_KeyDown({
                                param($a, $b)
                                if ($b.Key -eq [System.Windows.Input.Key]::Escape) {
                                    try { $a.Close() } catch {}
                                }
                            })
                            $win.Show()
                            $win.Focus() | Out-Null
                        } catch {}
                    })
                    $stack.Children.Add($img) | Out-Null
                } catch {
                    # Fall back: show the markdown literal so the
                    # info isn't lost - better than silently
                    # eating the image.
                    $fb = New-Object System.Windows.Controls.TextBlock
                    $fb.Text = $m.Value
                    $fb.FontSize = 13
                    $fb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#777788")
                    $fb.TextWrapping = [System.Windows.TextWrapping]::Wrap
                    $fb.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
                    $stack.Children.Add($fb) | Out-Null
                }
            }
            $cursor = $m.Index + $m.Length
        }
        # Tail text after the last image
        if ($cursor -lt $Body.Length) {
            $tail = $Body.Substring($cursor)
            $cleaned = & $formatBody $tail
            & $renderBody $stack $cleaned
        }
    } else {
        # No images: render the cleaned body line-by-line so
        # bullets, sub-bullets and numbered steps get their proper
        # markers/badges.
        $cleanBody = & $formatBody $Body
        & $renderBody $stack $cleanBody
    }

    if ($AppendChild) {
        $stack.Children.Add($AppendChild) | Out-Null
    }

    return $box
}

# Launch a VR-installed game using the most reliable method we
# have for it. Priority:
#   1. LaunchExe with optional LaunchArgs, run from the detected
#      install folder (gameDir from the last Check Installed scan).
#      Used for depot-installed games that need specific launch
#      parameters (Gunfire's -vrmode OpenVR, BMS's MO2 profile).
#   2. Fall back to Steam if SteamId is set - works for the
#      majority of native VR mods (REFramework, UEVR, Luke Ross
#      etc.) that auto-inject when the game starts.
#   3. Final fallback: open the InfoUrl / store page so the user
#      can launch from there.
function global:Start-GameInVR {
    param(
        $Game,
        # For DualMode games (REPO VR, CW VR): "Current" launches the
        # Thunderstore mod inside the Steam library via the regular
        # Steam protocol; "Depot" launches the pinned legacy install
        # directly from C:\Games\<Name> VR\ with DepotLaunchArgs.
        # Unset = use normal priority-chain detection (default).
        [string]$Mode = $null
    )

    # Track this launch in the play history FIRST, before any launch
    # path returns. Most-recent-first ringbuffer (max 8). Used by the
    # Recently Played row and Build-DiscoverTiles. Done up here so the
    # DualMode (Current/Depot) and TwoMods (ModA/ModB) paths - which
    # launch and return early below - still register. Failed launches
    # still count: the list reflects what the user tried to play.
    if ($Game -and $Game.Title) {
        try {
            $history = Get-HubSetting -Key "playHistory" -Default @()
            if (-not $history) { $history = @() }
            # ConvertFrom-Json returns a typed array; force to a
            # generic ArrayList so we can mutate it cleanly.
            $list = New-Object System.Collections.ArrayList
            foreach ($h in $history) {
                if ($h -and $h -ne $Game.Title) { [void]$list.Add($h) }
            }
            $list.Insert(0, $Game.Title)
            while ($list.Count -gt 8) { $list.RemoveAt($list.Count - 1) }
            Set-HubSetting -Key "playHistory" -Value @($list)
            # Rebuild the Recently Played row so the launch becomes
            # visible immediately, without waiting for a Hub restart.
            if (Get-Command Build-RecentlyPlayed -ErrorAction SilentlyContinue) {
                try { Build-RecentlyPlayed } catch { }
            }
        } catch { }
    }

    # DualMode shortcut: when the caller explicitly picks a variant,
    # bypass the priority chain and launch the requested variant
    # directly. This keeps the dual-button hover behaviour simple -
    # the click handlers pass "Current" or "Depot" and we route
    # straight to the matching launch path.
    if ($Mode -and $Game.DualMode) {
        $state = $global:gameStateMap[$Game.Title]
        if ($Mode -eq "Depot" -and $Game.DepotPath -and $Game.DepotLaunchExe) {
            $depotExe = Join-Path $Game.DepotPath $Game.DepotLaunchExe
            if (Test-Path $depotExe) {
                # steam_appid.txt safety net (same as the normal path)
                if ($Game.SteamId) {
                    $appidFile = Join-Path $Game.DepotPath "steam_appid.txt"
                    if (-not (Test-Path $appidFile)) {
                        try { Set-Content -Path $appidFile -Value $Game.SteamId -Encoding ASCII -NoNewline -Force } catch { }
                    }
                }
                try {
                    if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized }
                } catch { }
                try {
                    if ($Game.DepotLaunchArgs) {
                        Start-Process -FilePath $depotExe -ArgumentList $Game.DepotLaunchArgs -WorkingDirectory $Game.DepotPath
                    } else {
                        Start-Process -FilePath $depotExe -WorkingDirectory $Game.DepotPath
                    }
                } catch { }
                return
            }
        }
        if ($Mode -eq "Current" -and $Game.SteamId) {
            try {
                if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized }
            } catch { }
            try { Start-Process "steam://rungameid/$($Game.SteamId)" } catch { }
            return
        }
    }

    # TwoMods routing (separate from DualMode): launch one of the two
    # alternative VR mods from its subfolder under the .installed_path
    # parent. The detail-page split passes -Mode "ModA"/"ModB"; a plain
    # Start in VR (no Mode) launches whichever single mod is present, or
    # falls back to mod A when both exist.
    if ($Game.TwoMods) {
        $tmParent = $null
        try { $tmParent = Read-InstalledPath -Game $Game } catch { }
        # Resolve each mod's launcher under its own subfolder, searching
        # RECURSIVELY so a mod that unpacked one level deep still launches.
        $tmAPath = $null; $tmBPath = $null
        if ($tmParent -and (Test-Path $tmParent)) {
            if ($Game.ModASub -and $Game.ModALaunch) {
                $sA = Join-Path $tmParent $Game.ModASub
                if (Test-Path $sA) { $hA = Get-ChildItem -Path $sA -Filter $Game.ModALaunch -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1; if ($hA) { $tmAPath = $hA.FullName } }
            }
            if ($Game.ModBSub -and $Game.ModBLaunch) {
                $sB = Join-Path $tmParent $Game.ModBSub
                if (Test-Path $sB) { $hB = Get-ChildItem -Path $sB -Filter $Game.ModBLaunch -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1; if ($hB) { $tmBPath = $hB.FullName } }
            }
        }
        $tmAOk = [bool]$tmAPath
        $tmBOk = [bool]$tmBPath
        $tmPick = $null
        if     ($Mode -eq "ModA" -and $tmAOk) { $tmPick = $tmAPath }
        elseif ($Mode -eq "ModB" -and $tmBOk) { $tmPick = $tmBPath }
        elseif (-not $Mode) {
            if     ($tmAOk -and -not $tmBOk) { $tmPick = $tmAPath }
            elseif ($tmBOk -and -not $tmAOk) { $tmPick = $tmBPath }
            elseif ($tmAOk -and $tmBOk)      { $tmPick = $tmAPath }
        }
        if ($tmPick) {
            try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized } } catch { }
            try { Start-Process -FilePath $tmPick -WorkingDirectory (Split-Path -Parent $tmPick) } catch { }
            return
        }
        # The requested mod is not installed yet: open its installer so
        # the user can add it (the installer lets them pick which mod),
        # rather than silently doing nothing.
        if ($Mode -eq "ModA" -or $Mode -eq "ModB") {
            if ($Game.Bat -and $global:scriptDir) {
                $tmBat = Join-Path $global:scriptDir $Game.Bat
                if (Test-Path $tmBat) {
                    try { Start-LoggedInstaller -Game $Game -BatPath $tmBat -RequiresAdmin:([bool]$Game.RequiresAdmin) | Out-Null } catch { }
                    return
                }
            }
            if ($Game.InfoUrl) { try { Start-Process $Game.InfoUrl } catch { }; return }
        }
    }

    $state = $global:gameStateMap[$Game.Title]
    $gameDir = $null

    # Launch override (from the "Locate Game" exe-picker): the user's
    # explicit choice of which exe runs the game - e.g. a differently
    # named exe from another store. It wins over every other route.
    try {
        $launchOverride = Read-LaunchOverride -Game $Game
        if ($launchOverride -and (Test-Path $launchOverride)) {
            try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized } } catch { }
            $ovDir = Split-Path -Parent $launchOverride
            if ($Game.LaunchArgs) {
                Start-Process -FilePath $launchOverride -ArgumentList $Game.LaunchArgs -WorkingDirectory $ovDir
            } else {
                Start-Process -FilePath $launchOverride -WorkingDirectory $ovDir
            }
            return
        }
    } catch { }

    # Priority 0: an installer-recorded .installed_path wins over
    # everything (same rule the Check-Installed scan uses). Games we
    # copied OUT of Steam to C:\Games (e.g. Penumbra VR - the old
    # engine breaks under Program Files) must launch from that copy,
    # never via steam://rungameid which would start the unmodded
    # retail build in steamapps\common. We only trust the recorded
    # path if it still resolves AND holds the expected LaunchExe.
    try {
        $recordedLaunchPath = Read-InstalledPath -Game $Game
        if ($recordedLaunchPath -and (Test-Path $recordedLaunchPath)) {
            if ($Game.LaunchExe) {
                if (Test-Path (Join-Path $recordedLaunchPath $Game.LaunchExe)) {
                    $gameDir = $recordedLaunchPath
                }
            } else {
                $gameDir = $recordedLaunchPath
            }
        }
    } catch { }

    # Resolve VrInstallRoot if the game has one (GZDoomVR titles
    # install the engine into %LocalAppData%\GZDoomVR\ rather than
    # the Steam folder - the Steam install only holds the IWAD).
    # Tokens supported here match what Filter.ps1 resolves during
    # the scan: LOCALAPPDATA, APPDATA, PROGRAMDATA, USERPROFILE.
    # Anything else is taken as an absolute path.
    if (-not $gameDir -and $Game.VrInstallRoot -and $Game.LaunchExe) {
        $vrRoot = $Game.VrInstallRoot
        if     ($vrRoot -like "LOCALAPPDATA:*") { $vrRoot = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) ($vrRoot.Substring("LOCALAPPDATA:".Length)) }
        elseif ($vrRoot -like "APPDATA:*")      { $vrRoot = Join-Path ([Environment]::GetFolderPath("ApplicationData"))      ($vrRoot.Substring("APPDATA:".Length)) }
        elseif ($vrRoot -like "PROGRAMDATA:*")  { $vrRoot = Join-Path ([Environment]::GetFolderPath("CommonApplicationData")) ($vrRoot.Substring("PROGRAMDATA:".Length)) }
        elseif ($vrRoot -like "USERPROFILE:*")  { $vrRoot = Join-Path ([Environment]::GetFolderPath("UserProfile"))           ($vrRoot.Substring("USERPROFILE:".Length)) }
        if ((Test-Path $vrRoot) -and (Test-Path (Join-Path $vrRoot $Game.LaunchExe))) {
            $gameDir = $vrRoot
        }
    }

    # Trust state.GameDir only if the folder still exists AND contains
    # the expected LaunchExe. Stale state entries (uninstall, drive
    # reorganization, hub interrupted mid-scan) would otherwise carry
    # an invalid path and skip the FallbackPaths walk below.
    if (-not $gameDir -and $state -and $state.GameDir -and (Test-Path $state.GameDir)) {
        if ($Game.LaunchExe) {
            if (Test-Path (Join-Path $state.GameDir $Game.LaunchExe)) {
                $gameDir = $state.GameDir
            }
        } else {
            $gameDir = $state.GameDir
        }
    }

    # Walk FallbackPaths for any game that has them, not just
    # DepotInstall. Lots of titles can live in C:\Games\... outside
    # the state map (post-install state never refreshed, manual move,
    # etc.) - we should still find them. STEAM: tokens expand to
    # <library>\steamapps\common\<name> for each Steam library.
    if (-not $gameDir -and $Game.FallbackPaths) {
        # Lazily build the list of Steam libraries; only needed if a
        # STEAM: token appears in this game's FallbackPaths.
        $steamLibsResolved = $null
        foreach ($p in (Expand-DrivePaths $Game.FallbackPaths)) {
            $candidatePaths = @()
            if ($p -like "STEAM:*") {
                if ($null -eq $steamLibsResolved) {
                    $steamLibsResolved = @()
                    foreach ($rk in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam", "HKLM:\SOFTWARE\Valve\Steam", "HKCU:\SOFTWARE\Valve\Steam")) {
                        try {
                            $sp = (Get-ItemProperty -Path $rk -ErrorAction Stop).InstallPath
                            if ($sp -and (Test-Path $sp)) { $steamLibsResolved += $sp; break }
                        } catch {}
                    }
                    if ($steamLibsResolved.Count -gt 0) {
                        $vdf = Join-Path $steamLibsResolved[0] "steamapps\libraryfolders.vdf"
                        if (Test-Path $vdf) {
                            [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
                                $lib = $_.Groups[1].Value -replace '\\\\', '\'
                                if ((Test-Path $lib) -and ($steamLibsResolved -notcontains $lib)) {
                                    $steamLibsResolved += $lib
                                }
                            }
                        }
                    }
                }
                $folder = $p.Substring("STEAM:".Length)
                foreach ($lib in $steamLibsResolved) {
                    $candidatePaths += (Join-Path $lib "steamapps\common\$folder")
                }
            } else {
                $candidatePaths += $p
            }

            foreach ($cp in $candidatePaths) {
                if (-not (Test-Path $cp)) { continue }
                if ($Game.LaunchExe) {
                    if (Test-Path (Join-Path $cp $Game.LaunchExe)) {
                        $gameDir = $cp
                        break
                    }
                } else {
                    $gameDir = $cp
                    break
                }
            }
            if ($gameDir) { break }
        }
    }

    # Hide the Hub window before launching - VR games need full
    # foreground focus, otherwise the Hub stays on top and the
    # game window can't claim focus / SteamVR doesn't pick up
    # the right HWND. We minimise rather than close so the user
    # can come back to the Hub when they alt-tab out of the game.
    try {
        if ($global:window) {
            $global:window.WindowState = [System.Windows.WindowState]::Minimized
        }
    } catch { }

    if ($Game.LaunchExe -and $gameDir) {
        $exePath = Join-Path $gameDir $Game.LaunchExe
        if (Test-Path $exePath) {
            # Revive launch route: some VR builds target the Oculus runtime
            # only (e.g. Quake 2 VR) and must run THROUGH Revive on a non-
            # Oculus headset. When the installer set that up it drops a
            # ".revive_launch" marker (holding the injector path) in the
            # game folder. If present - and ONLY then - launch via
            # ReviveInjector.exe with the game EXE as its argument, exactly
            # like the desktop shortcut but independent of it (the user may
            # have deleted the shortcut).
            $reviveMarker = Join-Path $gameDir ".revive_launch"
            if (Test-Path $reviveMarker) {
                $reviveInjector = $null
                try { $storedInj = (Get-Content $reviveMarker -Raw -ErrorAction Stop).Trim() } catch { $storedInj = "" }
                if ($storedInj -and (Test-Path $storedInj)) { $reviveInjector = $storedInj }
                if (-not $reviveInjector) {
                    $injCands = @(
                        (Join-Path $env:ProgramFiles "Revive\ReviveInjector.exe"),
                        (Join-Path $env:ProgramFiles "Revive\Revive\ReviveInjector.exe")
                    )
                    $pf86 = ${env:ProgramFiles(x86)}
                    if ($pf86) { $injCands += (Join-Path $pf86 "Revive\ReviveInjector.exe") }
                    foreach ($cand in $injCands) { if (Test-Path $cand) { $reviveInjector = $cand; break } }
                }
                if ($reviveInjector) {
                    try { Start-Process -FilePath $reviveInjector -ArgumentList "`"$exePath`"" -WorkingDirectory $gameDir; return } catch { }
                }
                # Injector not found: fall through to a direct launch as a
                # last resort (better than doing nothing).
            }
            # Safety net: depot-installed games need steam_appid.txt
            # next to the EXE, or Steam intercepts the launch with an
            # "install this game" dialog. Older installs from before
            # this file was written by the installers won't have it -
            # drop it in now if it's missing.
            $isDepotInstall = [bool]$Game.DepotInstall
            $isOutsideSteamCommon = ($gameDir -notmatch '\\steamapps\\common\\')
            if ($Game.SteamId -and ($isDepotInstall -or $isOutsideSteamCommon)) {
                $appidFile = Join-Path $gameDir "steam_appid.txt"
                if (-not (Test-Path $appidFile)) {
                    try { Set-Content -Path $appidFile -Value $Game.SteamId -Encoding ASCII -NoNewline -Force } catch { }
                }
            }
            try {
                # Working directory: default to the game root (the
                # long-standing behaviour for every title). The four
                # titles below launch an exe that lives in a SUBFOLDER
                # of the game dir, and their desktop shortcuts already
                # set that subfolder as the working directory. We mirror
                # that here so "Start in VR" behaves identically to the
                # shortcut. This matters most for Penumbra (old HPL1
                # engine loads shaders relative to CWD - wrong CWD gives
                # the "couldn't load pointlight2d" crash); the others are
                # included for shortcut/Hub parity. Explicit whitelist so
                # no game outside this set changes behaviour.
                $subfolderExeTitles = @(
                    "Penumbra: Overture VR",
                    "Outer Wilds VR",
                    "Outward DE VR",
                    "Selaco VR"
                )
                $launchWorkDir = $gameDir
                if ($subfolderExeTitles -contains $Game.Title) {
                    $exeParent = Split-Path -Parent $exePath
                    if ($exeParent) { $launchWorkDir = $exeParent }
                }
                if ($Game.LaunchArgs) {
                    Start-Process -FilePath $exePath -ArgumentList $Game.LaunchArgs -WorkingDirectory $launchWorkDir
                } else {
                    Start-Process -FilePath $exePath -WorkingDirectory $launchWorkDir
                }
                return
            } catch { }
        }
    }

    # Custom-install detection: games that have a VrInstallRoot or
    # a recorded .installed_path (e.g. Tomb Raider 1 VR, Outward DE
    # VR, Tormented Souls VR) live OUTSIDE Steam. If we got here
    # without finding a valid $gameDir + LaunchExe, the user has
    # deleted the install folder under us. The state map is stale
    # and the next Check-Installed scan will repair it - but we
    # must NOT fall through to the steam://rungameid handler below,
    # which would launch the unmodded retail game instead.
    $isCustomInstall = ($Game.VrInstallRoot -or (Get-InstalledPathFile -Game $Game))
    if ($isCustomInstall -and -not $gameDir) {
        # Clear the cached "VR Ready" state so the card flips back
        # to "Install" on next paint, and wipe any stale
        # .installed_path so the next Check-Installed scan sees
        # a clean slate.
        try {
            if ($global:gameStateMap.ContainsKey($Game.Title)) {
                $global:gameStateMap.Remove($Game.Title) | Out-Null
            }
        } catch { }
        try {
            $stalePath = Get-InstalledPathFile -Game $Game
            if ($stalePath -and (Test-Path $stalePath)) {
                Remove-Item $stalePath -Force -EA SilentlyContinue
            }
            $staleVer = Get-InstalledVersionPath -Game $Game
            if ($staleVer -and (Test-Path $staleVer)) {
                Remove-Item $staleVer -Force -EA SilentlyContinue
            }
        } catch { }
        # Restore the hub window we minimised above so the user
        # sees the message, then trigger a full re-scan so all
        # cards reflect reality.
        try {
            if ($global:window) {
                $global:window.WindowState = [System.Windows.WindowState]::Normal
            }
        } catch { }
        try {
            [System.Windows.MessageBox]::Show(
                "$($Game.Title) install folder no longer exists.`n`nThe install has been cleared. Run the installer again to reinstall.",
                "Install missing",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            ) | Out-Null
        } catch { }
        try { Invoke-CheckInstalledScan } catch { }
        return
    }

    # Non-depot games: regular Steam launch is fine - the game lives
    # in the Steam library and Steam knows how to start it.
    if ($Game.SteamId) {
        try { Start-Process "steam://rungameid/$($Game.SteamId)"; return } catch { }
    }
    if ($Game.InfoUrl) {
        try { Start-Process $Game.InfoUrl } catch { }
    }
}

function global:Show-DiscoverDetail {
    param($Game)
    # Detail page: turn the (now purpose-less) filter pills into at-a-
    # glance attribute markers for THIS game. Purely cosmetic - does not
    # touch the real filter selection. Restore-FilterPills repaints the
    # real state when the page closes.
    if (Get-Command Set-DetailFilterMarks -ErrorAction SilentlyContinue) {
        try { Set-DetailFilterMarks -Game $Game } catch { }
    }
    # Manual navigation invalidates the forward stack - same as
    # browsers. The XButton2 forward handler sets
    # $global:NavSuppressForwardClear briefly so its own replay
    # call doesn't wipe the stack it was just popping from.
    if ($global:NavForwardStack -and -not $global:NavSuppressForwardClear) {
        $global:NavForwardStack.Clear()
    }
    # Click-through guard: a list-card click opens the detail page
    # on MouseLeftButtonDown; the matching MouseLeftButtonUp then
    # bubbles into whichever detail-page button now sits at the
    # cursor (Steam link, info button, etc.). Stamp the open time
    # so click handlers can ignore Up-events that arrive within
    # 250ms of the page becoming visible.
    $global:DetailOpenedAtMs = [Environment]::TickCount
    $global:discoverTiles.Visibility  = [System.Windows.Visibility]::Collapsed
    # Hide the Overview view too - it sits in the same host as
    # tiles + detail and would otherwise stay layered on top.
    if ($global:discoverOverview) {
        $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed
    }
    $global:discoverDetail.Visibility = [System.Windows.Visibility]::Visible
    $global:discoverDetailHost.Children.Clear()
    # Track all README/setup body text blocks built for this page
    # so Apply-DetailSize can resize them live. New empty list per
    # detail-page open; cleared again by Hide-DiscoverDetail.
    $global:DetailReadmeTextBlocks = New-Object System.Collections.Generic.List[object]
    # Blocks whose MaxWidth should track the window/container width
    # live (paragraphs, bullets, steps, code). Headings are NOT in
    # here - they stay full width. Recreated per detail-page open.
    $global:DetailWidthBlocks = New-Object System.Collections.Generic.List[object]
    if (-not $global:DetailWidthHandlerSet) {
        # Attach once: when the detail scroll container resizes,
        # recompute the readme text width so lines grow on big
        # windows and shrink on small ones, clamped 720-1040.
        $global:discoverDetail.Add_SizeChanged({
            if (-not $global:DetailWidthBlocks) { return }
            $w = $global:discoverDetail.ActualWidth
            if ($w -le 0) { return }
            $calc = [int]($w * 0.78)
            if ($calc -lt 720)  { $calc = 720 }
            if ($calc -gt 1040) { $calc = 1040 }
            foreach ($b in $global:DetailWidthBlocks) {
                if ($b) { $b.MaxWidth = $calc }
            }
        })
        $global:DetailWidthHandlerSet = $true
    }
    if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
    # Reset the scroll position to the top. WPF caches the
    # ScrollViewer's vertical offset across content swaps; without
    # this, opening a new game's detail page would leave the
    # viewport scrolled to wherever the previous game was. We do it
    # both immediately AND once layout has settled - the immediate
    # call covers the common case, the dispatched call catches the
    # case where new content is taller than the prior scroll offset.
    try { $global:discoverDetail.ScrollToTop() } catch { }
    $global:discoverDetail.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Loaded,
        [Action]{ try { $global:discoverDetail.ScrollToTop() } catch { } }
    ) | Out-Null
    # Track which game is currently shown so Check Installed can
    # refresh the action button (Install Mod -> VR Ready) without
    # the user having to navigate away and back.
    $global:currentDetailGame = $Game

    $stack = New-Object System.Windows.Controls.StackPanel
    $global:discoverDetailHost.Children.Add($stack) | Out-Null

    $accentHex = if ($Game.Accent) { $Game.Accent } else { "#666677" }
    $famAcc = ConvertTo-MediaColor $accentHex

    # Back button - a more substantial circular arrow control
    # so it doesn't get lost above the hero. SVG arrow plus label,
    # accent-colored border on hover.
    $backBtn = New-Object System.Windows.Controls.Border
    $backBtn.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $backBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a1a22")
    $backBtn.BorderThickness = [System.Windows.Thickness]::new(1)
    $backBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
    $backBtn.Padding = [System.Windows.Thickness]::new(14, 9, 18, 9)
    $backBtn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $backBtn.Margin = [System.Windows.Thickness]::new(0, 0, 0, 16)
    $backBtn.Cursor = [System.Windows.Input.Cursors]::Hand

    # Subtle ambient shadow
    $backShadow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $backShadow.Color = [System.Windows.Media.Color]::FromRgb(0,0,0)
    $backShadow.BlurRadius = 8
    $backShadow.ShadowDepth = 2
    $backShadow.Opacity = 0.4
    $backBtn.Effect = $backShadow

    $backInner = New-Object System.Windows.Controls.StackPanel
    $backInner.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $backInner.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $backBtn.Child = $backInner

    # SVG arrow: a simple left-pointing chevron drawn as a Path
    $backArrow = New-Object System.Windows.Shapes.Path
    $backArrow.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cccccc")
    $backArrow.StrokeThickness = 2
    $backArrow.StrokeEndLineCap = [System.Windows.Media.PenLineCap]::Round
    $backArrow.StrokeStartLineCap = [System.Windows.Media.PenLineCap]::Round
    $backArrow.StrokeLineJoin = [System.Windows.Media.PenLineJoin]::Round
    $backArrow.Fill = $null
    $backArrow.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $backArrow.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
    $backArrow.Data = [System.Windows.Media.Geometry]::Parse("M 7,0 L 0,6 L 7,12")
    $backInner.Children.Add($backArrow) | Out-Null

    $backTxt = New-Object System.Windows.Controls.TextBlock
    # Only the explore page gets a special label; all other origins
    # (library tiles, list cards) read "Back to library" since
    # that's where the navigation effectively returns to.
    $backTxt.Text = if ($global:DetailOrigin -eq "OVERVIEW") {
        "Back to explore"
    } else {
        "Back to library"
    }
    $backTxt.FontSize = 13
    $backTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $backTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cccccc")
    $backTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $backTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $backInner.Children.Add($backTxt) | Out-Null

    # Hover: lift with orange border (matches Explore all games),
    # brighten text + arrow. Hard-coded orange instead of the
    # game's accent so the brighter press glow (#ffcc66) has a
    # consistent, clearly different baseline to contrast against.
    $backBtn.Add_MouseEnter({
        $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#252530")
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
        $stack = $this.Child
        if ($stack -and $stack.Children.Count -ge 2) {
            $stack.Children[0].Stroke = [System.Windows.Media.Brushes]::White
            $stack.Children[1].Foreground = [System.Windows.Media.Brushes]::White
        }
    })
    $backBtn.Add_MouseLeave({
        $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a1a22")
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
        $stack = $this.Child
        if ($stack -and $stack.Children.Count -ge 2) {
            $stack.Children[0].Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cccccc")
            $stack.Children[1].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cccccc")
        }
    })
    # Press-glow: brighter border on MouseDown so the click is
    # visibly registered.
    $backBtn.Add_MouseLeftButtonDown({
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ffcc66")
    })
    # Defer page transition by ~120ms so the press-glow renders one
    # frame before Hide-DiscoverDetail wipes the page.
    $backBtn.Add_MouseLeftButtonUp({
        Invoke-DeferredAction -Action { Hide-DiscoverDetail }
    })
    $stack.Children.Add($backBtn) | Out-Null
    $global:DetailBackBtn = $backBtn
    if (Get-Command Request-HeaderBackArrowUpdate -ErrorAction SilentlyContinue) { Request-HeaderBackArrowUpdate }

    # Hero area: 360px tall, header.jpg with optional trailer fade-in.
    # We try a trailer for every Steam game - if it 404s the MediaElement
    # silently fails and we keep the still image.
    $hero = New-Object System.Windows.Controls.Border
    $hero.Height = 360
    $hero.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $hero.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0a0a0c")
    $hero.ClipToBounds = $true
    $hero.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $hero.Margin = [System.Windows.Thickness]::new(0, 0, 0, 18)

    # Subtle hover scale - same mechanic as the explore banners.
    # RenderTransform (not LayoutTransform) so the page below
    # doesn't shift. No press/glow effect since the hero isn't
    # clickable - just a gentle "alive" reaction on hover.
    Add-HoverScale -Element $hero -Scale 1.02

    $heroGrid = New-Object System.Windows.Controls.Grid
    $hero.Child = $heroGrid

    $heroUrl = Get-GameImageUrl -Game $Game -Kind "header"
    # Prefer the local disk cache if we've saved this header before -
    # loads synchronously from file and works with no network. BUT only
    # when there's no explicit bundled HeaderUrl override: for entries
    # like Halo CE (which borrow an unrelated SteamId only as a last-
    # resort fallback) the Steam cache would wrongly replace the real
    # bundled art.
    if ($Game.SteamId -and -not $Game.HeaderUrl) {
        $cachedHero = Get-CachedImageUri -SteamId $Game.SteamId -Kind "header"
        if ($cachedHero) { $heroUrl = $cachedHero }
    }

    # Always lay down a tinted background + title placeholder FIRST, as
    # the bottom layer. If the header image loads it covers this; if the
    # image fails to download (CDN 404 / TLS hiccup), the title stays
    # visible instead of an empty black banner. This is also what the
    # user sees during the brief async image load.
    $hero.Background = New-CardTintBrush -BaseHex "#0a0a0c" -TintHex $accentHex -TopAlpha 0.30 -MidAlpha 0.10
    $placeholder = New-Object System.Windows.Controls.TextBlock
    $placeholder.Text = $Game.Title
    $placeholder.FontSize = 36
    $placeholder.FontWeight = [System.Windows.FontWeights]::Bold
    $placeholder.Foreground = [System.Windows.Media.Brushes]::White
    $placeholder.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $placeholder.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $placeholder.TextAlignment = [System.Windows.TextAlignment]::Center
    $placeholder.MaxWidth = 700
    $placeholder.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $placeholder.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $heroGrid.Children.Add($placeholder) | Out-Null

    if ($heroUrl) {
        $heroImg = New-Object System.Windows.Controls.Image
        # UniformToFill = image bleeds to fill the container, full-bleed
        # look like Steam's storefront. Some cropping at top/bottom is
        # accepted to avoid black bars.
        $heroImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
        # Local file art (manual portrait/header for non-Steam games)
        # is served through the global frozen-bitmap cache, so
        # re-opening the same game does not re-decode it from disk.
        # Get-CachedBitmap returns $null for remote Steam URLs, which
        # fall through to the download path + fallback chain below.
        $heroCached = $null
        try { $heroCached = Get-CachedBitmap $heroUrl } catch { $heroCached = $null }
        if ($heroCached) { $heroImg.Source = $heroCached }
        if (-not $heroCached) {
        try {
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $bmp.UriSource = New-Object System.Uri $heroUrl
            $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            # If header fails to download (Steam CDN occasionally
            # 404s on header.jpg for older titles, or TLS handshake
            # hiccups), try fastly header, then portrait, then the
            # primary URL once more, before giving up to the title.
            $imgRefH    = $heroImg
            $phRef      = $placeholder
            $sidCap     = $Game.SteamId
            $heroUrlCap = $heroUrl
            $portraitUrlCap = Get-GameImageUrl -Game $Game -Kind "portrait"
            $bmp.Add_DownloadFailed({
                param($s, $e)
                # Try fastly header first
                if ($sidCap) {
                    try {
                        $hb = New-Object System.Windows.Media.Imaging.BitmapImage
                        $hb.BeginInit()
                        $hb.UriSource = New-Object System.Uri (Get-SteamHeaderUrlFastly $sidCap)
                        $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                        $hb.EndInit()
                        if ($hb.CanFreeze) { $hb.Freeze() }
                        $imgRefH.Source = $hb
                        return
                    } catch { }
                }
                # Then fall back to portrait
                if ($portraitUrlCap) {
                    try {
                        $hb = New-Object System.Windows.Media.Imaging.BitmapImage
                        $hb.BeginInit()
                        $hb.UriSource = New-Object System.Uri $portraitUrlCap
                        $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                        $hb.EndInit()
                        if ($hb.CanFreeze) { $hb.Freeze() }
                        $imgRefH.Source = $hb
                        return
                    } catch { }
                }
                # One more try at the primary URL - the original failure
                # is often a transient TLS/CDN hiccup (the "it showed up
                # after a Hub restart" case).
                try {
                    $hb = New-Object System.Windows.Media.Imaging.BitmapImage
                    $hb.BeginInit()
                    $hb.UriSource = New-Object System.Uri $heroUrlCap
                    $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $hb.EndInit()
                    if ($hb.CanFreeze) { $hb.Freeze() }
                    $imgRefH.Source = $hb
                    return
                } catch { }
                # Everything failed: drop the (empty) image so the title
                # placeholder behind it stays visible instead of a blank
                # banner.
                try {
                    $imgRefH.Source = $null
                    $imgRefH.Visibility = [System.Windows.Visibility]::Collapsed
                    if ($phRef) { $phRef.Visibility = [System.Windows.Visibility]::Visible }
                } catch { }
            }.GetNewClosure())
            $bmp.EndInit()
            if ($bmp.CanFreeze) { $bmp.Freeze() }
            $heroImg.Source = $bmp
        } catch { }
        }
        $heroGrid.Children.Add($heroImg) | Out-Null

        # Trailer playback is currently disabled. Steam migrated from
        # /movies/{appid}/movie480.mp4 to per-game hashed .webm URLs
        # that need to be scraped from the store page, and WPF's
        # MediaElement uses Windows Media Foundation which doesn't
        # decode VP8/VP9 anyway. The "Open in Steam" button below
        # gives the user a path to the trailer on Steam itself.
    }
    $stack.Children.Add($hero) | Out-Null

    # Compute the controls label - shown as a pill next to the
    # family pill in the title row below (no separate row needed).
    $controlsLabel = switch ($Game.Controls) {
        "MC"   { "Motion Controls" }
        "GP"   { "Gamepad VR" }
        "BOTH" { "Motion + Gamepad" }
        default { "" }
    }

    # Title row + family pill
    $titleRow = New-Object System.Windows.Controls.StackPanel
    $titleRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $titleRow.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
    $titleBig = New-Object System.Windows.Controls.TextBlock
    $titleBig.Text = $Game.Title
    $titleBig.FontSize = 28
    $titleBig.FontWeight = [System.Windows.FontWeights]::Bold
    # Subtle white -> light-grey vertical gradient, matching the card tiles.
    $titleBigGrad = New-Object System.Windows.Media.LinearGradientBrush
    $titleBigGrad.StartPoint = [System.Windows.Point]::new(0, 0)
    $titleBigGrad.EndPoint   = [System.Windows.Point]::new(0, 1)
    $titleBigGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(255,255,255), 0))) | Out-Null
    $titleBigGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(216,222,227), 1))) | Out-Null
    $titleBigGrad.Freeze()
    $titleBig.Foreground = $titleBigGrad
    $titleBig.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $titleBig.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $titleRow.Children.Add($titleBig) | Out-Null
    Add-HoverScale -Element $titleBig -Scale 1.02

    $famName = Get-ModFamily -Game $Game -IsExternal $false
    $famBg  = ConvertTo-MediaColor "#16161a"
    $famPillColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Round($famAcc.R*0.18 + $famBg.R*0.82)),
        [byte]([Math]::Round($famAcc.G*0.18 + $famBg.G*0.82)),
        [byte]([Math]::Round($famAcc.B*0.18 + $famBg.B*0.82))
    )
    $famPill2 = New-Object System.Windows.Controls.Border
    $famPill2.CornerRadius = [System.Windows.CornerRadius]::new(3)
    $famPill2.Padding = [System.Windows.Thickness]::new(8, 3, 8, 3)
    $famPill2.Margin = [System.Windows.Thickness]::new(14, 4, 0, 0)
    $famPill2.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $famPill2.Background = New-Object System.Windows.Media.SolidColorBrush $famPillColor
    $famTxt2 = New-Object System.Windows.Controls.TextBlock
    $famTxt2.Text = $famName.ToUpper()
    $famTxt2.FontSize = 10
    $famTxt2.FontWeight = [System.Windows.FontWeights]::SemiBold
    $famTxt2.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Round($famAcc.R*0.5 + 255*0.5)),
        [byte]([Math]::Round($famAcc.G*0.5 + 255*0.5)),
        [byte]([Math]::Round($famAcc.B*0.5 + 255*0.5))
    ))
    $famTxt2.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $famPill2.Child = $famTxt2
    $titleRow.Children.Add($famPill2) | Out-Null
    Add-HoverScale -Element $famPill2 -Scale 1.08

    # Controls pill (Motion Controls / Gamepad VR / Motion + Gamepad)
    # sits next to the family pill - same row, no extra vertical
    # space, reads as a related badge.
    if ($controlsLabel) {
        $ctrlPill = New-Object System.Windows.Controls.Border
        $ctrlPill.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $ctrlPill.Padding = [System.Windows.Thickness]::new(8, 3, 8, 3)
        $ctrlPill.Margin = [System.Windows.Thickness]::new(8, 4, 0, 0)
        $ctrlPill.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $ctrlBg = [System.Windows.Media.Color]::FromRgb(
            [byte]([Math]::Round($famAcc.R*0.18 + 22*0.82)),
            [byte]([Math]::Round($famAcc.G*0.18 + 22*0.82)),
            [byte]([Math]::Round($famAcc.B*0.18 + 26*0.82))
        )
        $ctrlPill.Background = New-Object System.Windows.Media.SolidColorBrush $ctrlBg
        $ctrlTxt = New-Object System.Windows.Controls.TextBlock
        $ctrlTxt.Text = $controlsLabel.ToUpper()
        $ctrlTxt.FontSize = 10
        $ctrlTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $ctrlTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(
            [byte]([Math]::Round($famAcc.R*0.5 + 255*0.5)),
            [byte]([Math]::Round($famAcc.G*0.5 + 255*0.5)),
            [byte]([Math]::Round($famAcc.B*0.5 + 255*0.5))
        ))
        $ctrlTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $ctrlPill.Child = $ctrlTxt
        $titleRow.Children.Add($ctrlPill) | Out-Null
        Add-HoverScale -Element $ctrlPill -Scale 1.08
    }

    # Game-installed pill: surfaces "yes the user actually owns and
    # has installed this game on disk" when the on-disk scan picked
    # it up. Sits between the controls pill and any auto-update
    # pill so it reads as a peer status badge. Green palette to
    # match the same green used by the VR Ready button later.
    # Pill is hidden on first load (before the user runs "Check
    # Installed") - we only show it once we have positive evidence.
    $detectState = $global:gameStateMap[$Game.Title]
    # Free games sit in the "installed" (ready-to-install) state by
    # default after a scan even though no VR build is on disk yet -
    # they have no purchase requirement. For them, only surface the
    # INSTALLED pill once the VR version is actually present
    # (vrinstalled / vrupdate); otherwise omit it. Non-free games
    # keep the original behaviour (pill for installed too, meaning
    # the base game is on disk).
    $isFreeGameDV = ($global:FREE_GAME_TITLES -and ($global:FREE_GAME_TITLES -contains $Game.Title))
    $instPillTags = if ($isFreeGameDV) { @("vrinstalled", "vrupdate") } else { @("installed", "vrinstalled", "vrupdate") }
    if ($detectState -and $detectState.Tag -in $instPillTags) {
        $instPill = New-Object System.Windows.Controls.Border
        $instPill.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $instPill.Padding = [System.Windows.Thickness]::new(8, 3, 8, 3)
        $instPill.Margin = [System.Windows.Thickness]::new(8, 4, 0, 0)
        $instPill.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        # Match the dezent H-style green used by the VR Ready
        # button so installed status reads consistently throughout
        # the UI - subtle bg, brighter green border, mint text.
        $instPill.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
        $instPill.BorderThickness = [System.Windows.Thickness]::new(1)
        $instPill.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4d8a5e")
        $instTxt = New-Object System.Windows.Controls.TextBlock
        $instTxt.Text = "INSTALLED"
        $instTxt.FontSize = 10
        $instTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $instTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
        $instTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $instPill.Child = $instTxt
        $titleRow.Children.Add($instPill) | Out-Null
        Add-HoverScale -Element $instPill -Scale 1.08
    }

    # Auto-update pill: some mods auto-update from GitHub nightly
    # builds. We surface that as a third badge so the user knows
    # the mod stays current without manual intervention.
    $hasAutoUpdate = $false
    if ($Game.Mod -and ($Game.Mod -match '(?i)auto[- ]update' -or $Game.Mod -match '(?i)REF-nightly')) {
        $hasAutoUpdate = $true
    } elseif ($Game.GitHubNightly) {
        $hasAutoUpdate = $true
    }
    if ($hasAutoUpdate) {
        $autoPill = New-Object System.Windows.Controls.Border
        $autoPill.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $autoPill.Padding = [System.Windows.Thickness]::new(8, 3, 8, 3)
        $autoPill.Margin = [System.Windows.Thickness]::new(8, 4, 0, 0)
        $autoPill.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $autoBg = [System.Windows.Media.Color]::FromRgb(
            [byte]([Math]::Round($famAcc.R*0.18 + 22*0.82)),
            [byte]([Math]::Round($famAcc.G*0.18 + 22*0.82)),
            [byte]([Math]::Round($famAcc.B*0.18 + 26*0.82))
        )
        $autoPill.Background = New-Object System.Windows.Media.SolidColorBrush $autoBg
        $autoTxt = New-Object System.Windows.Controls.TextBlock
        $autoTxt.Text = "AUTO-UPDATE"
        $autoTxt.FontSize = 10
        $autoTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $autoTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(
            [byte]([Math]::Round($famAcc.R*0.5 + 255*0.5)),
            [byte]([Math]::Round($famAcc.G*0.5 + 255*0.5)),
            [byte]([Math]::Round($famAcc.B*0.5 + 255*0.5))
        ))
        $autoTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $autoPill.Child = $autoTxt
        $titleRow.Children.Add($autoPill) | Out-Null
        Add-HoverScale -Element $autoPill -Scale 1.08
    }

    # FREE pill: free-to-play games (Anomaly VR / Iron Lung VR /
    # Sonic P-06 VR via $global:FREE_GAME_TITLES set in CardTile.ps1)
    # get a green FREE pill at the end of the title-row badges -
    # same green as the FREE pill on the card tile (#34D399).
    if ($global:FREE_GAME_TITLES -and ($global:FREE_GAME_TITLES -contains $Game.Title)) {
        $freePillDV = New-Object System.Windows.Controls.Border
        $freePillDV.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $freePillDV.Padding = [System.Windows.Thickness]::new(8, 3, 8, 3)
        $freePillDV.Margin = [System.Windows.Thickness]::new(8, 4, 0, 0)
        $freePillDV.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $freePillDV.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(20, 52, 211, 153))
        $freePillDV.BorderThickness = [System.Windows.Thickness]::new(1)
        $freePillDV.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freeTxtDV = New-Object System.Windows.Controls.TextBlock
        $freeTxtDV.Text = "FREE"
        $freeTxtDV.FontSize = 10
        $freeTxtDV.FontWeight = [System.Windows.FontWeights]::Bold
        $freeTxtDV.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freeTxtDV.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $freePillDV.Child = $freeTxtDV
        $titleRow.Children.Add($freePillDV) | Out-Null
        Add-HoverScale -Element $freePillDV -Scale 1.08
    }

    # WIP pill: work-in-progress mods (via $global:WIP_GAME_TITLES set in
    # CardTile.ps1) get a red WIP pill at the end of the title-row badges,
    # matching the red WIP pill on the card tile.
    if ($global:WIP_GAME_TITLES -and ($global:WIP_GAME_TITLES -contains $Game.Title)) {
        $wipPillDV = New-Object System.Windows.Controls.Border
        $wipPillDV.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $wipPillDV.Padding = [System.Windows.Thickness]::new(8, 3, 8, 3)
        $wipPillDV.Margin = [System.Windows.Thickness]::new(8, 4, 0, 0)
        $wipPillDV.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $wipPillDV.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(20, 248, 113, 113))
        $wipPillDV.BorderThickness = [System.Windows.Thickness]::new(1)
        $wipPillDV.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(248, 113, 113))
        $wipTxtDV = New-Object System.Windows.Controls.TextBlock
        $wipTxtDV.Text = "WIP"
        $wipTxtDV.FontSize = 10
        $wipTxtDV.FontWeight = [System.Windows.FontWeights]::Bold
        $wipTxtDV.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(248, 113, 113))
        $wipTxtDV.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $wipPillDV.Child = $wipTxtDV
        $titleRow.Children.Add($wipPillDV) | Out-Null
        Add-HoverScale -Element $wipPillDV -Scale 1.08
    }

    $stack.Children.Add($titleRow) | Out-Null

    # Mod meta strip (Option A): two columns under a thin
    # top-border. Tiny grey labels mark VR MOD and CREATED BY,
    # values below in slightly-brighter readable grey. More
    # designed than a plain italic line, scales cleanly if we
    # ever add more meta fields (license, last update, etc).
    $modClean = $Game.Mod
    if ($modClean) {
        $modClean = $modClean -replace '\s*\(auto-updates?\)\s*$', ''
        $modClean = $modClean -replace '\s+auto-updates?\s*$', ''
        $modClean = $modClean.Trim()
    }

    if ($modClean -or $Game.Author) {
        $metaBox = New-Object System.Windows.Controls.Border
        # Outer wrapper used only for spacing - the actual top
        # border lives on the inner StackPanel below so it ends
        # right after the author column instead of stretching
        # across the full page width.
        $metaBox.Margin  = [System.Windows.Thickness]::new(0, 6, 0, 14)

        $metaRow = New-Object System.Windows.Controls.StackPanel
        $metaRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        # Border + Padding live here so the line is exactly the
        # width of the meta cells.
        $metaRow.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left

        # Wrap the row in a sub-Border that carries the top line.
        # Done this way (Border around StackPanel rather than
        # StackPanel directly) because StackPanel doesn't expose
        # BorderThickness/BorderBrush properties. Hierarchy is
        # metaBox -> metaInner -> metaRow.
        $metaInner = New-Object System.Windows.Controls.Border
        $metaInner.BorderThickness = [System.Windows.Thickness]::new(0, 1, 0, 0)
        $metaInner.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1e1e26")
        $metaInner.Padding         = [System.Windows.Thickness]::new(0, 12, 0, 0)
        $metaInner.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $metaInner.Child = $metaRow
        $metaBox.Child = $metaInner

        if ($modClean) {
            $modCol = New-Object System.Windows.Controls.StackPanel
            $modCol.Margin = [System.Windows.Thickness]::new(0, 0, 24, 0)
            $modLbl = New-Object System.Windows.Controls.TextBlock
            $modLbl.Text = "VR MOD"
            $modLbl.FontSize = 9
            $modLbl.FontWeight = [System.Windows.FontWeights]::SemiBold
            $modLbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
            $modLbl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            # Letter-spacing via simple pad - WPF doesn't expose tracking
            # cleanly without Typography hacks; tag it visually with weight
            # + small size + muted color to read as a label.
            $modCol.Children.Add($modLbl) | Out-Null
            $modVal = New-Object System.Windows.Controls.TextBlock
            $modVal.Text = $modClean
            $modVal.FontSize = 13
            $modVal.FontWeight = [System.Windows.FontWeights]::Medium
            $modVal.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dddddd")
            $modVal.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $modVal.Margin = [System.Windows.Thickness]::new(0, 2, 0, 0)
            $modCol.Children.Add($modVal) | Out-Null
            $metaRow.Children.Add($modCol) | Out-Null
            Add-HoverScale -Element $modVal -Scale 1.04
        }

        if ($Game.Author) {
            $authCol = New-Object System.Windows.Controls.StackPanel
            $authCol.Margin = [System.Windows.Thickness]::new(0, 0, 0, 0)
            # Vertical separator before this column. Use a thin
            # Border so it visually divides the two cells.
            if ($modClean) {
                $sep = New-Object System.Windows.Controls.Border
                $sep.Width = 1
                $sep.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1e1e26")
                $sep.Margin = [System.Windows.Thickness]::new(0, 0, 24, 0)
                $metaRow.Children.Add($sep) | Out-Null
            }
            $authLbl = New-Object System.Windows.Controls.TextBlock
            $authLbl.Text = "CREATED BY"
            $authLbl.FontSize = 9
            $authLbl.FontWeight = [System.Windows.FontWeights]::SemiBold
            $authLbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
            $authLbl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $authCol.Children.Add($authLbl) | Out-Null
            $authVal = New-Object System.Windows.Controls.TextBlock
            $authVal.Text = $Game.Author
            $authVal.FontSize = 13
            $authVal.FontWeight = [System.Windows.FontWeights]::Medium
            $authVal.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dddddd")
            $authVal.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $authVal.Margin = [System.Windows.Thickness]::new(0, 2, 0, 0)
            $authCol.Children.Add($authVal) | Out-Null
            $metaRow.Children.Add($authCol) | Out-Null
            Add-HoverScale -Element $authVal -Scale 1.04
        }

        $stack.Children.Add($metaBox) | Out-Null
    }

    # Status line
    $state = $global:gameStateMap[$Game.Title]
    # Don't render a redundant "* VR Ready" line - the action button
    # below already says "VR Ready" so showing it twice is noise.
    # All other states (update / installed / default) carry useful
    # extra info beyond what the button conveys.
    $skipStatus = ($state -and $state.State -eq "ready")
    if (-not $skipStatus) {
        $renderStatus = $true
        $primaryText      = ""   # bold, accent-coloured leading text
        $detailText       = ""   # softer trailing text
        $bgArgb           = $null
        # Local to this block - DO NOT use $accentHex here, that
        # name is reused by the rest of Show-DiscoverDetail for
        # the game's Accent colour.
        $pillAccentHex    = $null
        $detailHex        = "#8a8f99"  # consistent muted detail across states
        if ($state) {
            switch ($state.State) {
                "update"    {
                    $primaryText   = "Update available"
                    $detailText    = ""
                    $bgArgb        = @(26, 255, 176, 96)   # ~10% alpha amber tint
                    $pillAccentHex = "#ffb060"
                }
                "installed" {
                    # Free games have no base-game install to report -
                    # they're simply always ready for the VR mod. Drop
                    # the "Game installed" lead-in for them and keep
                    # only the ready-state text.
                    if ($global:FREE_GAME_TITLES -and ($global:FREE_GAME_TITLES -contains $Game.Title)) {
                        $primaryText = "Ready for the VR mod"
                        $detailText  = ""
                    } else {
                        $primaryText = "Game installed"
                        $detailText  = " - ready for the VR mod"
                    }
                    $bgArgb        = @(26, 126, 213, 154)  # ~10% alpha green tint
                    $pillAccentHex = "#7ed59a"
                }
                default     { $renderStatus = $false }
            }
        } elseif ($global:gameStateMap.Count -gt 0) {
            # A scan has been run, but this game wasn't found. The
            # blue "You'll need X installed first" hint card below
            # this section already covers this case with a clearer
            # next-step. Skip the redundant status line.
            $renderStatus = $false
        } else {
            # No scan run yet - skip the line entirely. The Check
            # Installed button in the header is the right place to
            # find that action; we don't need a verbose hint here.
            $renderStatus = $false
        }
        if ($renderStatus) {
            # Compact left-anchored pill: no full-width container, no
            # full border. Just a coloured 3px left accent bar with a
            # soft tint behind it. Sits on its own line above the
            # action buttons without competing with them.
            $statusBox = New-Object System.Windows.Controls.Border
            $statusBox.CornerRadius        = [System.Windows.CornerRadius]::new(0, 3, 3, 0)
            $statusBox.Background          = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb($bgArgb[0], $bgArgb[1], $bgArgb[2], $bgArgb[3]))
            $statusBox.BorderThickness     = [System.Windows.Thickness]::new(3, 0, 0, 0)
            $statusBox.BorderBrush         = [System.Windows.Media.BrushConverter]::new().ConvertFromString($pillAccentHex)
            $statusBox.Padding             = [System.Windows.Thickness]::new(8, 4, 10, 4)
            $statusBox.Margin              = [System.Windows.Thickness]::new(0, 0, 0, 14)
            $statusBox.HorizontalAlignment = "Left"

            $statusRow = New-Object System.Windows.Controls.TextBlock
            $statusRow.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $statusRow.FontSize   = 11
            $statusRow.VerticalAlignment = "Center"

            $primaryRun = New-Object System.Windows.Documents.Run
            $primaryRun.Text       = $primaryText
            $primaryRun.FontWeight = "Medium"
            $primaryRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($pillAccentHex)
            $statusRow.Inlines.Add($primaryRun) | Out-Null

            if ($detailText) {
                $detailRun = New-Object System.Windows.Documents.Run
                $detailRun.Text       = $detailText
                $detailRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($detailHex)
                $statusRow.Inlines.Add($detailRun) | Out-Null
            }

            $statusBox.Child = $statusRow
            $stack.Children.Add($statusBox) | Out-Null
        }
    }

    # Get-the-game hint: only shown when a scan has run AND the
    # underlying Steam game wasn't located. The hub knows two
    # things at this point that the user might not: that they
    # need the source game first, and that the prominent blue
    # button below opens the Steam store page for it. We put
    # those two facts in a short callout so the path is clear.
    # isExternal tracks whether this is a full Steam VR release
    # (Half-Life Alyx etc) rather than a mod over a flat game -
    # for those the hint doesn't apply since there's no separate
    # source game to fetch. Detected once, reused below.
    $isExternal = $false
    foreach ($eg in $externalGames) {
        if ($eg.Title -eq $Game.Title) { $isExternal = $true; break }
    }
    $hintGameStateD = $global:gameStateMap[$Game.Title]
    $hintIsInstalledD = $hintGameStateD -and $hintGameStateD.Tag -in @("installed", "vrinstalled", "vrupdate")
    # StandaloneVR builds (e.g. Receiver VR) ship a complete, self-
    # contained VR game. They keep a SteamId only for store images /
    # ownership context, but the player does NOT need the Steam version
    # at all, so the "you'll need X installed first" hint is wrong and
    # is suppressed for them.
    $hintNeeded = $global:HasRunInstalledScan -and -not $hintIsInstalledD -and $Game.SteamId -and -not $isExternal -and -not $Game.StandaloneVR
    # Daggerfall VR is special: its SteamId is the free DOS Daggerfall (the
    # source game data), but the VR build installs to a SEPARATE folder, so
    # the install-state scan tracks the mod, not the base game - the base is
    # never flagged as installed. If the player already has DOS Daggerfall on
    # disk, the "you'll need Daggerfall installed first" hint is wrong, so
    # suppress it (the FREE / Install-Mod highlight is left untouched).
    if ($hintNeeded -and $Game.Title -eq "Daggerfall VR" -and (Test-DosDaggerfallOnDisk)) {
        $hintNeeded = $false
    }
    if ($hintNeeded) {
        # Strip the trailing " VR" suffix from the catalog title so
        # the hint reads as the actual game name rather than the
        # mod's catalog label. ("Onimusha 2 VR" -> "Onimusha 2")
        $sourceName = $Game.Title -replace '\s+VR$', ''

        $hintBox = New-Object System.Windows.Controls.Border
        $hintBox.CornerRadius    = [System.Windows.CornerRadius]::new(5)
        $hintBox.Background      = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(38, 37, 99, 235))
        $hintBox.BorderThickness = [System.Windows.Thickness]::new(1)
        $hintBox.BorderBrush     = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(110, 37, 99, 235))
        $hintBox.Padding         = [System.Windows.Thickness]::new(12, 9, 12, 9)
        $hintBox.Margin          = [System.Windows.Thickness]::new(0, 0, 0, 14)

        $hintTxt = New-Object System.Windows.Controls.TextBlock
        # DepotInstall games: the user needs the game in their Steam
        # *account* (so DepotDownloader is allowed to fetch it), but
        # they do NOT need the current version installed. Our installer
        # downloads its own pinned older build into a separate folder.
        # Worst case is they already have Steam's current version
        # installed, which is fine - we ignore it. So the message
        # focuses on ownership, not installation.
        if ($Game.DepotInstall) {
            $hintTxt.Text = "You need to OWN $sourceName on Steam, but you DON'T need to install it. The installer fetches its own pinned version into a separate folder. If you don't own the game yet, click ``Get on Steam`` below."
        } else {
            $hintTxt.Text = "You'll need $sourceName installed first. If you don't own it yet, click ``Get on Steam`` below to head to the store page."
        }
        $hintTxt.FontSize     = 12
        $hintTxt.Foreground   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cfd6e6")
        $hintTxt.FontFamily   = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $hintTxt.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $hintTxt.LineHeight   = 18
        $hintBox.Child = $hintTxt
        $stack.Children.Add($hintBox) | Out-Null
    }

    # Action buttons row: created and inserted right after the
    # status line so users see Install/Mod Page/Steam directly
    # below the hero. The button content is populated further
    # down in this function; once added to the visual tree, any
    # children appended later will render in order.
    $btnRow = New-Object System.Windows.Controls.StackPanel
    $btnRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    # Top margin keeps the buttons fully visible when the page is
    # scrolled all the way up - was 2px which let the top edge
    # graze the hero/title bottom on tall layouts.
    $btnRow.Margin = [System.Windows.Thickness]::new(0, 10, 0, 18)
    $stack.Children.Add($btnRow) | Out-Null

    # PC Power Scale: hardware-tier indicator. Sits between the
    # action buttons and the README so the user sees recommended
    # specs before reading the rest. Tier mapping is in
    # Get-PowerTier (see top of file).
    $stack.Children.Add((New-PowerScaleBlock -Game $Game)) | Out-Null

    # Two-column row directly under Power Scale: Game Info (left)
    # and Similar Games (right). Game Info is auto-loaded from the
    # Steam Store API at render time; if nothing comes back we drop
    # to a single-column layout (Similar Games gets the full width)
    # so we never show an empty placeholder box.
    # Custom Game/Tool Info text. These OVERRIDE the cached Steam
    # description on purpose: several titles have no Steam page, or had a
    # SteamId pointing at the wrong product, so our own text must win over
    # whatever the json cache holds (damage control for stale entries).
    # Normal Steam titles (not in this map) still use their store text.
    $infoHeading = "Game Info"
    $customDescriptions = @{
        "Metroid Prime VR" = "Metroid Prime is a critically acclaimed first-person action-adventure game developed by Retro Studios and published by Nintendo. Originally released for the GameCube in November 2002 and now fully playable in VR with 6DoF motion controls."
        "Perfect Dark VR" = "Perfect Dark is a legendary sci-fi secret agent shooter launched by the developer studio Rare in 2000. The series centers on secret agent Joanna Dark, who works for the Carrington Institute and battles the rival megacorporation dataDyne as well as extraterrestrial threats."
        "Ashes 2063 VR" = "Ashes 2063 is a free, post-apocalyptic total conversion for GZDoom by Vostyok - build-style ruins and fast Doom combat with a Stalker and Fallout flavour. This entry adds motion controls through gzdoomvr, an OpenVR fork of GZDoom by hh79. Includes the Enriched campaign, Afterglow and the Hard Reset expansion."
        "Total Chaos VR" = "Total Chaos is a free survival-horror total conversion for Doom II on GZDoom by Sam Prebble (wadaholic), set on the abandoned mining island of Fort Oasis with improvised melee weapons, scarce ammo and a heavy horror atmosphere. This entry adds motion controls by swapping the bundled engine for gzdoomvr, an OpenVR fork of GZDoom by hh79."
        "No One Lives Forever 2 VR" = "No One Lives Forever 2: A Spy in H.A.R.M.'s Way (2002) is Monolith's beloved retro-spy stealth shooter starring superspy Cate Archer. Luke Ross's R.E.A.L. mod converts the original English v1.3 release into a full first-person VR experience with roomscale head tracking and gamepad controls, layered onto a copy of the game that you own and provide yourself. Localized VR menus are available in German, Spanish, French and Italian."
        "Freespace 2 VR" = "The FreeSpace 2 VR mod (integrated via the FreeSpace Open project) brings the legendary 1999 space classic to modern headsets as a full-fledged virtual reality experience with graphic enhancements."
        "Richard Burns Rally VR" = "Richard Burns Rally (RBR) in virtual reality is considered the ultimate VR rally experience within the sim-racing community. The original game dates back to 2004, yet thanks to modern community mods and OpenXR/OpenVR, it runs smoothly at high frame rates (90-120 FPS) even on mid-range PCs."
        "The Dark Mod VR"      = "The Dark Mod is a free, standalone, open-source stealth game for PC. The project pays homage to the classic games in the Thief series (Dark Project) and perfectly captures their dark Gothic-steampunk atmosphere."
        "Metal: Hellsinger VR" = "Metal: Hellsinger is a rhythm-driven first-person shooter: shoot, dash and slaughter demons in time with a heavy-metal soundtrack across the eight hells, building your Fury multiplier the better you hit the beat."
        "I Can Gun VR"         = "I Can Gun is a first-person shooter with a twist: you operate your weapon in full manual detail - racking the slide, checking the chamber, managing the magazine - while scavenging procedurally generated levels guarded by merciless machines."
        "Anomaly GAMMA"        = "S.T.A.L.K.E.R. GAMMA is a free, standalone, hardcore survival modification for S.T.A.L.K.E.R. Anomaly. It combines over 400 mods into an immersive gameplay experience where you must repair and craft your own gear and fight for survival in the dangerous Zone."
        "Ratchet & Clank VR"   = "Developer Rybread69 is creating a large Unreal Engine VR project that recreates worlds from the first four PS2 Ratchet & Clank games. You can explore planets like Novalis, Aridia, and Oozla in first-person VR, smash crates, collect Bolts, use gadgets, and fire familiar weapons. There is no combat yet, so it currently feels more like an interactive museum of classic Ratchet & Clank memories."
        "UEVR Deluxe"          = "UEVR (Universal Unreal Engine VR Mod) is a groundbreaking, free, open-source tool developed by praydog that allows users to play almost any Unreal Engine 4 or 5 flatscreen game in virtual reality. It works by injecting VR functionality directly into the game engine, transforming games that were not originally designed for VR into immersive experiences."
        "UUVR / Rai Pal"       = "UUVR (Universal Unity VR) is an experimental open-source modification by developer Raicuparta that transforms flat PC games developed with the Unity engine into VR games. The easiest way to use it is through Rai Pal, Raicuparta's manager for universal game mods, which auto-detects your installed and owned games, identifies their engine, and installs, runs, and updates the correct version of UUVR for you."
        "Dolphin VR + ReduX"   = "Dolphin VR is an older, specialized modification of the popular Dolphin Emulator that allows users to play Nintendo GameCube and Wii games in Virtual Reality. Dolphin VR ReduX (also frequently referred to as Dolphin XR) is a major, modern revival of that project, using the modern Dolphin core and up-to-date VR runtime standards."
        "Sonic P-06 VR"        = "Sonic P-06 (Project '06) is an unofficial, fan-made remake of the notoriously buggy Sonic the Hedgehog (2006), rebuilt in the Unity engine by programmer Ian `"ChaosX`" Moris to create a polished, high-quality experience. It fixes broken physics, improves graphics with upscaled textures, and enhances controls for all playable characters."
        "Anomaly VR"           = "Welcome to the most complete and immersive S.T.A.L.K.E.R. experience yet. S.T.A.L.K.E.R. Anomaly is a free, stand-alone mod built on the 64-bit X-Ray engine, reinvigorated and enhanced to deliver the definitive survival sandbox in the Chornobyl Exclusion Zone."
        "Iron Lung VR"         = "Iron Lung is a short dread-driven submarine horror game from the developer of DUSK, The Moon Sliver, and Squirrel Stapler. The VR recreation was created by Jack Randolph."
        "Vivecraft"            = "Vivecraft is the premier open-source mod that transforms Minecraft: Java Edition into a fully immersive Virtual Reality experience. It supports major VR headsets and provides room-scale movement, motion-controlled interactions, and full multiplayer compatibility with non-VR players."
        "World of Warcraft VR" = "World of Warcraft is a massive online role-playing game where players explore the world of Azeroth, complete quests, and develop their own hero. You can choose from different races and classes, fight monsters, collect gear, and team up with other players in dungeons, raids, and PvP battles."
        "Halo CE VR"           = "Halo: Combat Evolved VR is a full VR conversion of the original 2003 PC release. As the Master Chief, with the AI Cortana, you crash-land on a mysterious ring-world and battle the alien Covenant to uncover its secrets."
        "Quake 3 VR"           = "Quake III Arena is id Software's acclaimed 1999 arena shooter - fast, skill-based combat in gothic and sci-fi arenas, with bot matches and up to 16-player multiplayer. This installs Quake 3 VR (q3vr): a 6DoF motion-controlled PCVR port built on ioquake3 and Quake3Quest, with the full single-player campaign and crossplay multiplayer with PC and Quest players."
        "Breath of the Wild VR" = "Experience Hyrule like never before! BetterVR transforms The Legend of Zelda: Breath of the Wild into a full 6DOF PCVR adventure. Explore vast landscapes, climb towering mountains, and face powerful enemies with a whole new sense of scale and immersion."
        "Escape from Tarkov VR" = "SPT VR brings the harsh extraction shooter experience of Tarkov into immersive PCVR. Raid alone against AI PMCs and Scavs, manage your gear, loot dangerous locations, and survive tense firefights where every mistake can cost you everything. Build your stash, upgrade your setup, and make it back alive before the raid turns against you."
    }
    $toolInfoTitles = @("UEVR Deluxe", "UUVR / Rai Pal", "Dolphin VR + ReduX")
    if ($customDescriptions.ContainsKey($Game.Title)) {
        $steamDesc = $customDescriptions[$Game.Title]
        if ($toolInfoTitles -contains $Game.Title) { $infoHeading = "Tool Info" }
    } else {
        $steamDesc = Get-SteamShortDescription -SteamId $Game.SteamId
    }
    $hasGameInfo = [bool]$steamDesc

    $infoRow = New-Object System.Windows.Controls.Grid
    $infoRow.Margin = [System.Windows.Thickness]::new(0, 0, 0, 14)
    if ($hasGameInfo) {
        # Game Info gets more width than Similar Games so the
        # description (and its screenshot) has room to breathe and
        # the right column doesn't leave a wide gap on big windows.
        $col1 = New-Object System.Windows.Controls.ColumnDefinition
        $col1.Width = [System.Windows.GridLength]::new(1.7, [System.Windows.GridUnitType]::Star)
        $colGap = New-Object System.Windows.Controls.ColumnDefinition
        $colGap.Width = [System.Windows.GridLength]::new(10)
        $col2 = New-Object System.Windows.Controls.ColumnDefinition
        $col2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $infoRow.ColumnDefinitions.Add($col1)   | Out-Null
        $infoRow.ColumnDefinitions.Add($colGap) | Out-Null
        $infoRow.ColumnDefinitions.Add($col2)   | Out-Null
    } else {
        $col1 = New-Object System.Windows.Controls.ColumnDefinition
        $col1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $infoRow.ColumnDefinitions.Add($col1) | Out-Null
    }

    if ($hasGameInfo) {
        # --- Left: Game Info box ---
        $gameInfoBox = New-Object System.Windows.Controls.Border
        $gameInfoBox.CornerRadius = [System.Windows.CornerRadius]::new(6)
        $gameInfoBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#13131a")
        $gameInfoBox.BorderThickness = [System.Windows.Thickness]::new(1)
        $gameInfoBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
        $gameInfoBox.Padding = [System.Windows.Thickness]::new(14, 10, 14, 12)
        [System.Windows.Controls.Grid]::SetColumn($gameInfoBox, 0)
        $gameInfoStack = New-Object System.Windows.Controls.StackPanel
        # Top-aligned so its ActualHeight is the real CONTENT height,
        # not the stretched-to-row height. The Similar-Games count
        # handler measures this; if it measured the stretched height
        # it would feed back through the shared row and runaway.
        $gameInfoStack.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $gameInfoBox.Child = $gameInfoStack
        # Optional prominent notice at the very top of the info box
        # (catalog field "Notice", with optional clickable "NoticeUrl").
        # Used e.g. for Metal: Hellsinger VR to point at the official
        # VR release. Amber-bordered so it stands out above the desc.
        if ($Game.Notice) {
            $noticeBox = New-Object System.Windows.Controls.Border
            $noticeBox.CornerRadius = [System.Windows.CornerRadius]::new(5)
            $noticeBox.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(28, 224, 168, 58))
            $noticeBox.BorderThickness = [System.Windows.Thickness]::new(1)
            $noticeBox.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(224, 168, 58))
            $noticeBox.Padding = [System.Windows.Thickness]::new(11, 9, 11, 10)
            $noticeBox.Margin = [System.Windows.Thickness]::new(0, 0, 0, 12)
            $noticeStack = New-Object System.Windows.Controls.StackPanel
            $noticeBox.Child = $noticeStack
            $noticeHead = New-Object System.Windows.Controls.TextBlock
            $noticeHead.Text = "IMPORTANT - ABOUT THIS MOD"
            $noticeHead.FontSize = 12
            $noticeHead.FontWeight = [System.Windows.FontWeights]::Bold
            $noticeHead.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(240, 184, 72))
            $noticeHead.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $noticeHead.Margin = [System.Windows.Thickness]::new(0, 0, 0, 5)
            $noticeStack.Children.Add($noticeHead) | Out-Null
            $noticeTxt = New-Object System.Windows.Controls.TextBlock
            $noticeTxt.Text = [string]$Game.Notice
            $noticeTxt.FontSize = 14
            $noticeTxt.TextWrapping = [System.Windows.TextWrapping]::Wrap
            $noticeTxt.LineHeight = 20
            $noticeTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(220, 210, 190))
            $noticeTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $noticeStack.Children.Add($noticeTxt) | Out-Null
            if ($Game.NoticeUrl) {
                $noticeLink = New-Object System.Windows.Controls.TextBlock
                $noticeLink.Text = "Open the official VR version on Steam"
                $noticeLink.FontSize = 13
                $noticeLink.FontWeight = [System.Windows.FontWeights]::SemiBold
                $noticeLink.TextDecorations = [System.Windows.TextDecorations]::Underline
                $noticeLink.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(240, 184, 72))
                $noticeLink.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $noticeLink.Cursor = [System.Windows.Input.Cursors]::Hand
                $noticeLink.Margin = [System.Windows.Thickness]::new(0, 6, 0, 0)
                $noticeLink.Tag = [string]$Game.NoticeUrl
                $noticeLink.Add_MouseLeftButtonUp({ param($s, $e) try { Start-Process $s.Tag } catch {} })
                $noticeStack.Children.Add($noticeLink) | Out-Null
            }
            $gameInfoStack.Children.Add($noticeBox) | Out-Null
            # Subtle zoom on hover, same as the description image below.
            Add-HoverScale -Element $noticeBox -Scale 1.02
        }
        # Heading row with accent bar
        $giHead = New-Object System.Windows.Controls.StackPanel
        $giHead.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $giHead.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
        $giBar = New-Object System.Windows.Controls.Border
        $giBar.Width = 3
        $giBar.CornerRadius = [System.Windows.CornerRadius]::new(2)
        $giBar.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accentHex)
        $giBar.Margin = [System.Windows.Thickness]::new(0, 1, 8, 1)
        $giHead.Children.Add($giBar) | Out-Null
        $giHeadTxt = New-Object System.Windows.Controls.TextBlock
        $giHeadTxt.Text = $infoHeading
        $giHeadCfg = $global:DetailTextSizes[$global:DetailSize]
        if (-not $giHeadCfg) { $giHeadCfg = $global:DetailTextSizes["M"] }
        $giHeadTxt.FontSize = [int]$giHeadCfg.Font + 1
        $giHeadTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $giHeadTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#f0f0f4")
        $giHeadTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $giHead.Children.Add($giHeadTxt) | Out-Null
        $gameInfoStack.Children.Add($giHead) | Out-Null
        if ($null -ne $global:DetailReadmeTextBlocks) {
            $giHeadTxt.Tag = "heading"
            $global:DetailReadmeTextBlocks.Add($giHeadTxt) | Out-Null
        }

        # Description text - rendered immediately, no button.
        # Font size follows the Detail-view S/M/L preference (own
        # persisted setting, independent from Library/Explore size).
        # Updated live by Apply-DetailSize when the user toggles
        # S/M/L while on a detail page.
        $descTxt = New-Object System.Windows.Controls.TextBlock
        $descTxt.Text = $steamDesc
        $descSizeKey = if ($global:DetailSize) { $global:DetailSize } else { "M" }
        $descCfg = $global:DetailTextSizes[$descSizeKey]
        if (-not $descCfg) { $descCfg = $global:DetailTextSizes["M"] }
        $descTxt.FontSize   = $descCfg.Font
        $descTxt.LineHeight = $descCfg.LineHeight
        $descTxt.FontWeight = [System.Windows.FontWeights]::Medium
        $descTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c8c8d4")
        $descTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $descTxt.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $gameInfoStack.Children.Add($descTxt) | Out-Null
        $global:DetailDescTxt = $descTxt

        # UEVR has no Steam page - show the bundled compat-grid
        # image so the Tool Info box has a visual.
        if ($Game.Title -eq "UEVR Deluxe") {
            $uevrShotPath = Join-Path $script:scriptDir "Assets\UEVR_compat_grid.jpg"
            if (Test-Path $uevrShotPath) {
                $shotBorder = New-Object System.Windows.Controls.Border
                $shotBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $shotBorder.ClipToBounds = $true
                $shotBorder.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
                $shotBorder.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
                $shotImg = New-Object System.Windows.Controls.Image
                $shotImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                try {
                    $sbmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $sbmp.BeginInit()
                    $sbmp.UriSource = ([System.Uri]$uevrShotPath)
                    $sbmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $sbmp.EndInit()
                    if ($sbmp.CanFreeze) { $sbmp.Freeze() }
                    $shotImg.Source = $sbmp
                } catch { }
                $shotBorder.Child = $shotImg
                $gameInfoStack.Children.Add($shotBorder) | Out-Null
                Add-HoverScale -Element $shotBorder -Scale 1.02
            }
        }
        # UUVR / Rai Pal has no Steam page - show the bundled
        # description image so the Tool Info box has a visual, the
        # same way UEVR shows its compat grid above.
        if ($Game.Title -eq "UUVR / Rai Pal") {
            $uuvrShotPath = Join-Path $script:scriptDir "Assets\UUVR_description.jpg"
            if (Test-Path $uuvrShotPath) {
                $shotBorder = New-Object System.Windows.Controls.Border
                $shotBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $shotBorder.ClipToBounds = $true
                $shotBorder.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
                $shotBorder.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
                $shotImg = New-Object System.Windows.Controls.Image
                $shotImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                try {
                    $sbmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $sbmp.BeginInit()
                    $sbmp.UriSource = ([System.Uri]$uuvrShotPath)
                    $sbmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $sbmp.EndInit()
                    if ($sbmp.CanFreeze) { $sbmp.Freeze() }
                    $shotImg.Source = $sbmp
                } catch { }
                $shotBorder.Child = $shotImg
                $gameInfoStack.Children.Add($shotBorder) | Out-Null
                Add-HoverScale -Element $shotBorder -Scale 1.02
            }
        }
        if ($Game.Title -eq "Dolphin VR + ReduX") {
            $dolphinShotPath = Join-Path $script:scriptDir "Assets\DolphinVR_screenshot.jpg"
            if (Test-Path $dolphinShotPath) {
                $shotBorder = New-Object System.Windows.Controls.Border
                $shotBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $shotBorder.ClipToBounds = $true
                $shotBorder.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
                $shotBorder.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
                $shotImg = New-Object System.Windows.Controls.Image
                $shotImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                try {
                    $sbmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $sbmp.BeginInit()
                    $sbmp.UriSource = ([System.Uri]$dolphinShotPath)
                    $sbmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $sbmp.EndInit()
                    if ($sbmp.CanFreeze) { $sbmp.Freeze() }
                    $shotImg.Source = $sbmp
                } catch { }
                $shotBorder.Child = $shotImg
                $gameInfoStack.Children.Add($shotBorder) | Out-Null
                Add-HoverScale -Element $shotBorder -Scale 1.02
            }
        }
        # Sonic P-06 has no Steam page either - load the bundled
        # screenshot so the Game Info box has a visual, same pattern
        # as UEVR above.
        if ($Game.Title -eq "Sonic P-06 VR") {
            $sonicShotPath = Join-Path $script:scriptDir "Assets\SonicP06_screenshot.jpg"
            if (Test-Path $sonicShotPath) {
                $shotBorder = New-Object System.Windows.Controls.Border
                $shotBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $shotBorder.ClipToBounds = $true
                $shotBorder.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
                $shotBorder.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
                $shotImg = New-Object System.Windows.Controls.Image
                $shotImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                try {
                    $sbmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $sbmp.BeginInit()
                    $sbmp.UriSource = ([System.Uri]$sonicShotPath)
                    $sbmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $sbmp.EndInit()
                    if ($sbmp.CanFreeze) { $sbmp.Freeze() }
                    $shotImg.Source = $sbmp
                } catch { }
                $shotBorder.Child = $shotImg
                $gameInfoStack.Children.Add($shotBorder) | Out-Null
                Add-HoverScale -Element $shotBorder -Scale 1.02
            }
        }
        # Anomaly VR has no Steam page - load the bundled
        # screenshot so the Game Info box has a visual, same pattern
        # as Sonic P-06 above.
        if ($Game.Title -eq "Anomaly VR") {
            $anomalyShotPath = Join-Path $script:scriptDir "Assets\AnomalyVR_screenshot.jpg"
            if (Test-Path $anomalyShotPath) {
                $shotBorder = New-Object System.Windows.Controls.Border
                $shotBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $shotBorder.ClipToBounds = $true
                $shotBorder.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
                $shotBorder.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
                $shotImg = New-Object System.Windows.Controls.Image
                $shotImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                try {
                    $sbmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $sbmp.BeginInit()
                    $sbmp.UriSource = ([System.Uri]$anomalyShotPath)
                    $sbmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $sbmp.EndInit()
                    if ($sbmp.CanFreeze) { $sbmp.Freeze() }
                    $shotImg.Source = $sbmp
                } catch { }
                $shotBorder.Child = $shotImg
                $gameInfoStack.Children.Add($shotBorder) | Out-Null
                Add-HoverScale -Element $shotBorder -Scale 1.02
            }
        }
        # Iron Lung VR has no Steam page - load the bundled
        # screenshot so the Game Info box has a visual, same pattern
        # as Anomaly VR / Sonic P-06 above.
        if ($Game.Title -eq "Iron Lung VR") {
            $ironLungShotPath = Join-Path $script:scriptDir "Assets\IronLungVR_screenshot.jpg"
            if (Test-Path $ironLungShotPath) {
                $shotBorder = New-Object System.Windows.Controls.Border
                $shotBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $shotBorder.ClipToBounds = $true
                $shotBorder.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
                $shotBorder.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
                $shotImg = New-Object System.Windows.Controls.Image
                $shotImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                try {
                    $sbmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $sbmp.BeginInit()
                    $sbmp.UriSource = ([System.Uri]$ironLungShotPath)
                    $sbmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $sbmp.EndInit()
                    if ($sbmp.CanFreeze) { $sbmp.Freeze() }
                    $shotImg.Source = $sbmp
                } catch { }
                $shotBorder.Child = $shotImg
                $gameInfoStack.Children.Add($shotBorder) | Out-Null
                Add-HoverScale -Element $shotBorder -Scale 1.02
            }
        }
        # Vivecraft has no Steam page - load the bundled screenshot
        # into the Game Info box, same pattern as Iron Lung above.
        if ($Game.Title -eq "Vivecraft") {
            $vivecraftShotPath = Join-Path $script:scriptDir "Assets\Vivecraft_screenshot.jpg"
            if (Test-Path $vivecraftShotPath) {
                $shotBorder = New-Object System.Windows.Controls.Border
                $shotBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $shotBorder.ClipToBounds = $true
                $shotBorder.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
                $shotBorder.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
                $shotImg = New-Object System.Windows.Controls.Image
                $shotImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                try {
                    $sbmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $sbmp.BeginInit()
                    $sbmp.UriSource = ([System.Uri]$vivecraftShotPath)
                    $sbmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $sbmp.EndInit()
                    if ($sbmp.CanFreeze) { $sbmp.Freeze() }
                    $shotImg.Source = $sbmp
                } catch { }
                $shotBorder.Child = $shotImg
                $gameInfoStack.Children.Add($shotBorder) | Out-Null
                Add-HoverScale -Element $shotBorder -Scale 1.02
            }
        }
        # World of Warcraft has no Steam page - load the bundled
        # screenshot so the Game Info box has a visual, same pattern
        # as Anomaly VR / Sonic P-06 above.
        if ($Game.Title -eq "World of Warcraft VR") {
            $wowShotPath = Join-Path $script:scriptDir "Assets\WorldOfWarcraft_screenshot.jpg"
            if (Test-Path $wowShotPath) {
                $shotBorder = New-Object System.Windows.Controls.Border
                $shotBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $shotBorder.ClipToBounds = $true
                $shotBorder.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
                $shotBorder.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
                $shotImg = New-Object System.Windows.Controls.Image
                $shotImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                try {
                    $sbmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $sbmp.BeginInit()
                    $sbmp.UriSource = ([System.Uri]$wowShotPath)
                    $sbmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $sbmp.EndInit()
                    if ($sbmp.CanFreeze) { $sbmp.Freeze() }
                    $shotImg.Source = $sbmp
                } catch { }
                $shotBorder.Child = $shotImg
                $gameInfoStack.Children.Add($shotBorder) | Out-Null
                Add-HoverScale -Element $shotBorder -Scale 1.02
            }
        }
        # Fill the empty space below the description with a Steam
        # screenshot. Threshold ~400 chars roughly matches "fits in
        # a reasonable column height with image room left". For
        # very long descriptions we skip the image to avoid cramming.
        # Skip for UEVR (synthetic description, no Steam media).
        # A bundled ScreenshotUrl (e.g. Halo CE) is deliberately provided
        # and always shows. The ~400-char limit only gates the Steam-media
        # fallback, where a long Steam description leaves no room.
        if ($Game.ScreenshotUrl -or ($steamDesc.Length -lt 400 -and $Game.SteamId)) {
            $shotUrl = $null
            # A bundled ScreenshotUrl always wins (e.g. Halo CE, which
            # ships its own art and has no SteamId).
            if ($Game.ScreenshotUrl) {
                $shotAbs = Join-Path $script:scriptDir $Game.ScreenshotUrl
                if (Test-Path $shotAbs) { $shotUrl = ([System.Uri]$shotAbs).AbsoluteUri }
            }
            # Prefer the locally-cached screenshot file (works offline).
            if (-not $shotUrl -and $Game.SteamId) {
                $shotUrl = Get-CachedImageUri -SteamId $Game.SteamId -Kind "screenshot"
            }
            # Then the live screenshot URL from the appdetails cache.
            if (-not $shotUrl -and $Game.SteamId) {
                $shotUrl = Get-SteamScreenshot -SteamId $Game.SteamId
            }
            # Some Steam apps return no screenshots in /appdetails
            # (older titles, private depots). Fall back to our LOCAL
            # cached header first (works offline), then the network
            # header, so the panel still has a visual.
            if (-not $shotUrl -and $Game.SteamId) {
                $shotUrl = Get-CachedImageUri -SteamId $Game.SteamId -Kind "header"
            }
            if (-not $shotUrl -and $Game.SteamId) {
                $shotUrl = Get-SteamHeaderUrl $Game.SteamId
            }
            if ($shotUrl) {
                $shotBorder = New-Object System.Windows.Controls.Border
                $shotBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $shotBorder.ClipToBounds = $true
                $shotBorder.Margin = [System.Windows.Thickness]::new(0, 10, 0, 0)
                $shotBorder.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
                $shotImg = New-Object System.Windows.Controls.Image
                # Steam screenshots are 16:9; UniformToFill keeps
                # the aspect while filling the available width.
                # WPF auto-scales the bitmap to the container size,
                # so the source image dimensions don't matter.
                $shotImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                try {
                    $sbmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $sbmp.BeginInit()
                    $sbmp.UriSource = New-Object System.Uri $shotUrl
                    $sbmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    # If the chosen URL fails (e.g. screenshot URL
                    # 404s on older titles), try the header banner
                    # as a last resort.
                    $hdrFallback = Get-SteamHeaderUrl $Game.SteamId
                    $shotImgRef = $shotImg
                    $sbmp.Add_DownloadFailed({
                        param($s, $e)
                        if (-not $hdrFallback) { return }
                        try {
                            $hb = New-Object System.Windows.Media.Imaging.BitmapImage
                            $hb.BeginInit()
                            $hb.UriSource = New-Object System.Uri $hdrFallback
                            $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                            $hb.EndInit()
                            if ($hb.CanFreeze) { $hb.Freeze() }
                            $shotImgRef.Source = $hb
                        } catch { }
                    }.GetNewClosure())
                    $sbmp.EndInit()
                    if ($sbmp.CanFreeze) { $sbmp.Freeze() }
                    $shotImg.Source = $sbmp
                } catch { }
                $shotBorder.Child = $shotImg
                $gameInfoStack.Children.Add($shotBorder) | Out-Null
                Add-HoverScale -Element $shotBorder -Scale 1.02
            }
        }

        $infoRow.Children.Add($gameInfoBox) | Out-Null
    }

    # --- Right: Similar Games box ---
    $simBox = New-Object System.Windows.Controls.Border
    $simBox.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $simBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#13131a")
    $simBox.BorderThickness = [System.Windows.Thickness]::new(1)
    $simBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
    $simBox.Padding = [System.Windows.Thickness]::new(14, 10, 14, 12)
    [System.Windows.Controls.Grid]::SetColumn($simBox, $(if ($hasGameInfo) { 2 } else { 0 }))
    $simStack = New-Object System.Windows.Controls.StackPanel
    $simBox.Child = $simStack
    # Heading
    $simHead = New-Object System.Windows.Controls.StackPanel
    $simHead.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $simHead.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    $simBar = New-Object System.Windows.Controls.Border
    $simBar.Width = 3
    $simBar.CornerRadius = [System.Windows.CornerRadius]::new(2)
    $simBar.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accentHex)
    $simBar.Margin = [System.Windows.Thickness]::new(0, 1, 8, 1)
    $simHead.Children.Add($simBar) | Out-Null
    $simHeadTxt = New-Object System.Windows.Controls.TextBlock
    $simHeadTxt.Text = "Similar Games"
    $simHeadCfg = $global:DetailTextSizes[$global:DetailSize]
    if (-not $simHeadCfg) { $simHeadCfg = $global:DetailTextSizes["M"] }
    $simHeadTxt.FontSize = [int]$simHeadCfg.Font + 1
    $simHeadTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $simHeadTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#f0f0f4")
    $simHeadTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $simHead.Children.Add($simHeadTxt) | Out-Null
    $simStack.Children.Add($simHead) | Out-Null
    if ($null -ne $global:DetailReadmeTextBlocks) {
        $simHeadTxt.Tag = "heading"
        $global:DetailReadmeTextBlocks.Add($simHeadTxt) | Out-Null
    }
    # Mini-rows: small thumbnail + title + family pill. Fetch a few
    # extra candidates so the visible count can grow to fill a tall
    # Game Info box (e.g. when a Notice is shown) and re-balance on
    # window resize.
    $similar = Get-SimilarGames -Game $Game -Count 8
    $simTileList = New-Object System.Collections.ArrayList
    if ($similar -and $similar.Count -gt 0) {
        foreach ($simGame in $similar) {
            $simRow = New-Object System.Windows.Controls.Border
            $simRow.Background = [System.Windows.Media.Brushes]::Transparent
            $simRow.Padding = [System.Windows.Thickness]::new(6, 6, 6, 6)
            $simRow.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)
            $simRow.CornerRadius = [System.Windows.CornerRadius]::new(4)
            $simRow.Cursor = [System.Windows.Input.Cursors]::Hand
            $simRowGrid = New-Object System.Windows.Controls.Grid
            $cThumb = New-Object System.Windows.Controls.ColumnDefinition
            $cThumb.Width = [System.Windows.GridLength]::new(170)
            $cText  = New-Object System.Windows.Controls.ColumnDefinition
            $cText.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
            $simRowGrid.ColumnDefinitions.Add($cThumb) | Out-Null
            $simRowGrid.ColumnDefinitions.Add($cText)  | Out-Null
            # Thumbnail (header image) - keeps Steam header.jpg
            # 2.14:1 aspect; sized to fill the right column nicely
            # without becoming a full-size hero.
            $simHdrUrl = Get-GameImageUrl -Game $simGame -Kind "header"
            if ($simGame.SteamId) {
                $cachedSimHdr = Get-CachedImageUri -SteamId $simGame.SteamId -Kind "header"
                if ($cachedSimHdr) { $simHdrUrl = $cachedSimHdr }
            }
            if ($simHdrUrl) {
                $thumb = New-Object System.Windows.Controls.Border
                $thumb.Width = 160; $thumb.Height = 75
                $thumb.CornerRadius = [System.Windows.CornerRadius]::new(3)
                $thumb.ClipToBounds = $true
                $thumb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                $thumbImg = New-Object System.Windows.Controls.Image
                $thumbImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                try {
                    $tbmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $tbmp.BeginInit()
                    $tbmp.UriSource = New-Object System.Uri $simHdrUrl
                    $tbmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $tbmp.EndInit()
                    if ($tbmp.CanFreeze) { $tbmp.Freeze() }
                    $thumbImg.Source = $tbmp
                } catch { }
                $thumb.Child = $thumbImg
                [System.Windows.Controls.Grid]::SetColumn($thumb, 0)
                $simRowGrid.Children.Add($thumb) | Out-Null
            }
            # Title text
            $simTitleStack = New-Object System.Windows.Controls.StackPanel
            $simTitleStack.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $simTitleStack.Margin = [System.Windows.Thickness]::new(12, 0, 0, 0)
            [System.Windows.Controls.Grid]::SetColumn($simTitleStack, 1)
            $simTitleTxt = New-Object System.Windows.Controls.TextBlock
            $simTitleTxt.Text = $simGame.Title
            $simTitleTxt.FontSize = 13
            $simTitleTxt.FontWeight = [System.Windows.FontWeights]::Medium
            # Subtle top-down sheen like the card titles, a touch stronger.
            $simTitleGrad = New-Object System.Windows.Media.LinearGradientBrush
            $simTitleGrad.StartPoint = [System.Windows.Point]::new(0, 0)
            $simTitleGrad.EndPoint   = [System.Windows.Point]::new(0, 1)
            $simTitleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(255,255,255), 0))) | Out-Null
            $simTitleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(194,202,210), 1))) | Out-Null
            if ($simTitleGrad.CanFreeze) { $simTitleGrad.Freeze() }
            $simTitleTxt.Foreground = $simTitleGrad
            $simTitleTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $simTitleTxt.TextWrapping = [System.Windows.TextWrapping]::NoWrap
            $simTitleTxt.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis
            $simTitleStack.Children.Add($simTitleTxt) | Out-Null
            # Sub-line: control type (+ FREE) instead of the old family tag.
            $simCtrl = switch ($simGame.Controls) { "MC" { "Motion Controls" } "GP" { "Gamepad" } default { "" } }
            $simIsFree = ($global:FREE_GAME_TITLES -contains $simGame.Title)
            if ($simCtrl -or $simIsFree) {
                $simSubTxt = New-Object System.Windows.Controls.TextBlock
                $simSubTxt.FontSize = 9.5
                $simSubTxt.FontWeight = [System.Windows.FontWeights]::Medium
                $simSubTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $simSubTxt.Margin = [System.Windows.Thickness]::new(0, 1, 0, 0)
                if ($simCtrl) {
                    $rCtrl = New-Object System.Windows.Documents.Run $simCtrl
                    $rCtrl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8a8a9a")
                    $simSubTxt.Inlines.Add($rCtrl)
                }
                if ($simIsFree) {
                    $rFree = New-Object System.Windows.Documents.Run ($(if ($simCtrl) { "  +  FREE" } else { "FREE" }))
                    $rFree.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
                    $rFree.FontWeight = [System.Windows.FontWeights]::SemiBold
                    $simSubTxt.Inlines.Add($rFree)
                }
                $simTitleStack.Children.Add($simSubTxt) | Out-Null
            }
            $simRowGrid.Children.Add($simTitleStack) | Out-Null
            $simRow.Child = $simRowGrid
            # Hover effect + click navigates to the similar game
            $simRow.Add_MouseEnter({
                $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a1a24")
            })
            $simRow.Add_MouseLeave({
                $this.Background = [System.Windows.Media.Brushes]::Transparent
            })
            # Subtle zoom on hover (whole tile: header image + title +
            # control sub-line) so it reads more clearly on hover, like
            # the description image. RenderTransform resets on leave.
            Add-HoverScale -Element $simRow -Scale 1.05
            $simGameCap = $simGame
            $simRow.Add_MouseLeftButtonUp({
                Show-DiscoverDetail -Game $simGameCap
            }.GetNewClosure())
            $simStack.Children.Add($simRow) | Out-Null
            [void]$simTileList.Add($simRow)
        }
        # Default to 4 visible; the handler below grows/shrinks this.
        for ($si = 0; $si -lt $simTileList.Count; $si++) {
            $simTileList[$si].Visibility = $(if ($si -lt 4) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed })
        }
        # Scale the visible count to the Game Info box height. We
        # measure the info STACK's content height (text-driven, never
        # stretched), so toggling sim tiles cannot feed back into the
        # measured height -> no layout loop. Fires on first layout and
        # again whenever a window resize re-wraps the description.
        if ($hasGameInfo -and $gameInfoStack) {
            $simListCap = $simTileList
            $balanceSim = {
                param($s, $e)
                try {
                    $h = $s.ActualHeight
                    if ($h -le 0) { return }
                    # Pick the tile count whose height is closest to the
                    # info box (Round, not Floor) so the column fills the
                    # available space promptly instead of leaving a gap.
                    # ~93px per tile row, ~26px for the header.
                    $n = [int][Math]::Round(($h - 26) / 93)
                    if ($n -lt 4) { $n = 4 }
                    if ($n -gt $simListCap.Count) { $n = $simListCap.Count }
                    for ($j = 0; $j -lt $simListCap.Count; $j++) {
                        $vis = $(if ($j -lt $n) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed })
                        if ($simListCap[$j].Visibility -ne $vis) { $simListCap[$j].Visibility = $vis }
                    }
                } catch {}
            }.GetNewClosure()
            $gameInfoStack.Add_SizeChanged($balanceSim)
        }
    } else {
        $noneTxt = New-Object System.Windows.Controls.TextBlock
        $noneTxt.Text = "No similar games found"
        $noneTxt.FontSize = 12
        $noneTxt.FontWeight = [System.Windows.FontWeights]::Medium
        $noneTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
        $noneTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $simStack.Children.Add($noneTxt) | Out-Null
    }
    $infoRow.Children.Add($simBox) | Out-Null

    $stack.Children.Add($infoRow) | Out-Null

    # README sections (if available)
    $sections = Read-GameReadme -Game $Game
    $deferredUninstallBox = $null
    # README sections (if available). isExternal was already
    # determined above (for the get-the-game hint) - reusing here.
    $hasReadme = ($sections.Count -gt 0)
    if ($hasReadme) {
        # Section ordering: prioritize what users care about.
        # We skip "How to use" because the README typically says
        # "Double-click START_INSTALLER.bat" - irrelevant in the
        # hub where the Install button does that for the user.
        # We also skip "More info" because we already render a
        # "Mod Page" button below.
        $preferred = @("About this mod", "About", "Where to get the game", "What it installs", "Requirements", "Note")
        $skip      = @{ "How to use" = $true; "More info" = $true }
        # Sections that should always render AT THE END, in this
        # order. Substring match (case-insensitive) on the heading
        # so e.g. "Support Astienth" hits "support", "Related
        # communities" hits "related", "Uninstall / temporarily
        # disable" hits "uninstall". Donations / community links /
        # uninstall guidance belong below the main usage info, not
        # interleaved with it.
        $tailPatterns = @("related", "communit", "discord", "support", "donat", "credit", "deactivate", "uninstall", "deinstall")
        $shown = @{}
        $theatreBtnPlaced = $false
        # Pull baseDir so embedded images like ![Layout](pic.webp)
        # can resolve to absolute paths during rendering.
        $imgBase = if ($sections.Contains("_baseDir")) { $sections["_baseDir"] } else { $null }
        # Helper: does a heading match any tail pattern?
        $isTail = {
            param($heading)
            $h = $heading.ToString().ToLower()
            foreach ($p in $tailPatterns) { if ($h.Contains($p)) { return $true } }
            return $false
        }
        foreach ($key in $preferred) {
            if ($sections.Contains($key) -and $sections[$key]) {
                # Append the Steam Theatre button inside the
                # Requirements box for all non-external games.
                $append = $null
                if ($key -eq "Requirements" -and -not $isExternal) {
                    $append = New-SteamTheatreButton -AccentHex $accentHex
                    $theatreBtnPlaced = $true
                }
                $stack.Children.Add((New-DetailSection -Heading $key -Body $sections[$key] -AccentHex $accentHex -AppendChild $append -ImageBaseDir $imgBase)) | Out-Null
                $shown[$key] = $true
            }
        }
        # Middle block: remaining h2 sections that are NOT tail items.
        foreach ($key in $sections.Keys) {
            if ($key -eq "_tagline" -or $key -eq "_baseDir" -or $key -eq "_quip" -or $shown.Contains($key) -or $skip.Contains($key)) { continue }
            if ((& $isTail $key)) { continue }
            $stack.Children.Add((New-DetailSection -Heading $key -Body $sections[$key] -AccentHex $accentHex -ImageBaseDir $imgBase)) | Out-Null
            $shown[$key] = $true
        }
        # Tail block: render tail sections last, grouped by pattern
        # in $tailPatterns order. Within a single pattern (e.g. two
        # "support" sections), preserve README order.
        foreach ($pat in $tailPatterns) {
            foreach ($key in $sections.Keys) {
                if ($key -eq "_tagline" -or $key -eq "_baseDir" -or $key -eq "_quip" -or $shown.Contains($key) -or $skip.Contains($key)) { continue }
                if (-not $key.ToString().ToLower().Contains($pat)) { continue }
                $stack.Children.Add((New-DetailSection -Heading $key -Body $sections[$key] -AccentHex $accentHex -ImageBaseDir $imgBase)) | Out-Null
                $shown[$key] = $true
            }
        }
        # If the README didn't have a Requirements section but the
        # game still benefits from the Theatre Mode hint, render a
        # small stand-alone block at the end with the Theatre button
        # AND the Uninstall Guide button side by side.
        #
        # Ordering rule: when the box holds BOTH the Theatre hint and
        # the Uninstall button, it reads as a "tools" row and looks
        # fine before the closing quip. But when the Theatre button was
        # already placed in Requirements, this box holds ONLY the lone
        # Uninstall button - and ending on "here's how to uninstall"
        # right before the flavour quip looks backwards. In that case
        # we defer the box so the quip comes first.
        if (-not $isExternal) {
            $standaloneBox = New-Object System.Windows.Controls.Border
            $standaloneBox.CornerRadius = [System.Windows.CornerRadius]::new(6)
            $standaloneBox.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#13131a")
            $standaloneBox.BorderThickness = [System.Windows.Thickness]::new(1)
            $standaloneBox.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
            $standaloneBox.Padding = [System.Windows.Thickness]::new(14, 10, 14, 12)
            $standaloneBox.Margin  = [System.Windows.Thickness]::new(0, 0, 0, 10)

            $standaloneRow = New-Object System.Windows.Controls.StackPanel
            $standaloneRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
            $standaloneBox.Child = $standaloneRow

            # Only add the Theatre button if it wasn't already placed
            # in the Requirements section above.
            if (-not $theatreBtnPlaced) {
                $standaloneBtn = New-SteamTheatreButton -AccentHex $accentHex
                $standaloneBtn.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
                $standaloneRow.Children.Add($standaloneBtn) | Out-Null
            }

            # Uninstall Guide button: always shown for non-external
            # games. Adapts steps based on whether the game uses
            # Steam launch options that need clearing first.
            $uninstallBtn = New-UninstallGuideButton -Game $Game -AccentHex "#cc6655"
            $uninstallBtn.Margin = [System.Windows.Thickness]::new(0, 0, 0, 0)
            $standaloneRow.Children.Add($uninstallBtn) | Out-Null

            # If the Theatre button is alongside (box has 2 buttons),
            # render now - before the quip. If the Uninstall button is
            # alone, defer it so the quip renders first.
            if (-not $theatreBtnPlaced) {
                $stack.Children.Add($standaloneBox) | Out-Null
            } else {
                $deferredUninstallBox = $standaloneBox
            }
        }
    } elseif ($Game.Description -and -not $isExternal) {
        # No README found and not an external - render the inline
        # description. Routed through Set-TextBlockWithLinks so any
        # URLs in the description render as clickable hyperlinks
        # rather than plain text.
        # Externals deliberately skip this: their Description is
        # only used for the card-tile third line (e.g. "by praydog",
        # "by fholger"); in the detail view the same info already
        # appears in the meta-strip header as CREATED BY, and a
        # Support box rounds things off below. A duplicate paragraph
        # in the body would just be clutter.
        $descBlock = New-Object System.Windows.Controls.TextBlock
        $descBlock.FontSize = 13
        $descBlock.FontWeight = [System.Windows.FontWeights]::Medium
        $descBlock.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c8c8d4")
        $descBlock.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $descBlock.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $descBlock.LineHeight = 20
        $descBlock.Margin = [System.Windows.Thickness]::new(0, 0, 0, 18)
        $descAccent = if ($Game.Accent) { $Game.Accent } else { "#666677" }
        Set-TextBlockWithLinks -TextBlock $descBlock -Text $Game.Description -AccentHex $descAccent -BaseFont 13
        $stack.Children.Add($descBlock) | Out-Null
    }

    # Flavour quip box. README-backed games carry their quip in the
    # extracted "_quip" section (so it survives even when it sits under
    # a skipped heading like "More info"); externals use the catalog
    # Quip field. Either way it renders as one accent left-bar box with
    # italic semibold accent text and no heading, as the closing line.
    $quipText = $null
    if ($Game.Quip) {
        # A per-game catalog Quip always wins - this lets games that
        # share a README (REFramework family, Luke Ross titles) each
        # carry their own game-specific quip instead of the shared one.
        $quipText = $Game.Quip
    } elseif ($hasReadme -and $sections.Contains("_quip") -and $sections["_quip"]) {
        $quipText = $sections["_quip"]
    }
    if ($quipText) {
        $cqBox = New-Object System.Windows.Controls.Border
        $cqBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161e")
        $cqBox.BorderThickness = [System.Windows.Thickness]::new(3, 0, 0, 0)
        $cqBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accentHex)
        $cqBox.CornerRadius = [System.Windows.CornerRadius]::new(6)
        $cqBox.Padding = [System.Windows.Thickness]::new(14, 10, 14, 10)
        $cqBox.Margin = [System.Windows.Thickness]::new(0, 0, 0, 18)
        $cqBox.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $cqBox.Cursor = [System.Windows.Input.Cursors]::Arrow
        # Slight grow-from-left on hover.
        $cqScale = New-Object System.Windows.Media.ScaleTransform
        $cqScale.ScaleX = 1.0; $cqScale.ScaleY = 1.0
        $cqBox.RenderTransform = $cqScale
        $cqBox.RenderTransformOrigin = (New-Object System.Windows.Point(0, 0.5))
        $cqtb = New-Object System.Windows.Controls.TextBlock
        $cqtb.Text = $quipText
        $cqtb.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $cqtb.FontSize = 14
        $cqtb.FontStyle = [System.Windows.FontStyles]::Italic
        $cqtb.FontWeight = [System.Windows.FontWeights]::SemiBold
        $cqtb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accentHex)
        $cqtb.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $cqBox.Child = $cqtb
        # Stash the accent so the hover handler can glow in the game's
        # colour.
        $cqBox.Tag = $accentHex
        # Hover: lighter box (keeps text legible on dark accents), a
        # slightly bigger scale, and a soft accent-coloured glow so the
        # quip feels inviting. All state is reset unconditionally on
        # leave so nothing lingers.
        $cqBox.Add_MouseEnter({
            param($s, $e)
            $s.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2b2b36")
            if ($s.RenderTransform) {
                $s.RenderTransform.ScaleX = 1.03
                $s.RenderTransform.ScaleY = 1.10
            }
            try {
                $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
                $glow.Color = [System.Windows.Media.ColorConverter]::ConvertFromString([string]$s.Tag)
                $glow.BlurRadius = 18
                $glow.ShadowDepth = 0
                $glow.Opacity = 0.7
                $s.Effect = $glow
            } catch {}
        })
        $cqBox.Add_MouseLeave({
            param($s, $e)
            $s.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161e")
            if ($s.RenderTransform) {
                $s.RenderTransform.ScaleX = 1.0
                $s.RenderTransform.ScaleY = 1.0
            }
            $s.Effect = $null
        })
        $stack.Children.Add($cqBox) | Out-Null
    }

    # Deferred lone Uninstall-Guide box: rendered here, after the quip,
    # so the closing flavour line isn't followed by "how to uninstall".
    if ($deferredUninstallBox) {
        $stack.Children.Add($deferredUninstallBox) | Out-Null
    }

    # since they have no README to host a ## Support section. Look
    # mirrors the Luke Ross README block: muted bordered box with
    # a heading, the support text, and the clickable link.
    if (-not $hasReadme -and $Game.SupportUrl) {
        $supportBox = New-Object System.Windows.Controls.Border
        $supportBox.CornerRadius    = [System.Windows.CornerRadius]::new(6)
        $supportBox.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#13131a")
        $supportBox.BorderThickness = [System.Windows.Thickness]::new(1)
        $supportBox.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
        $supportBox.Padding         = [System.Windows.Thickness]::new(14, 12, 14, 14)
        $supportBox.Margin          = [System.Windows.Thickness]::new(0, 0, 0, 18)

        $supStack = New-Object System.Windows.Controls.StackPanel
        $supportBox.Child = $supStack

        # Heading - small caps style label, same as the meta-strip
        # at the top of the page.
        $supLbl = New-Object System.Windows.Controls.TextBlock
        $supLbl.Text = "SUPPORT THE MOD"
        $supLbl.FontSize = 9
        $supLbl.FontWeight = [System.Windows.FontWeights]::SemiBold
        $supLbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
        $supLbl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $supStack.Children.Add($supLbl) | Out-Null

        # Body text + link. SupportText is the explanatory line;
        # if missing, fall back to a generic phrasing so we never
        # render an empty-looking box.
        $supText = if ($Game.SupportText) { $Game.SupportText } else { "If you enjoy this mod, consider supporting the maintainer:" }
        $supBody = New-Object System.Windows.Controls.TextBlock
        $supBody.FontSize = 13
        $supBody.FontWeight = [System.Windows.FontWeights]::Medium
        $supBody.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c8c8d4")
        $supBody.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $supBody.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $supBody.LineHeight = 20
        $supBody.Margin = [System.Windows.Thickness]::new(0, 6, 0, 6)
        $supBody.Text = $supText
        $supStack.Children.Add($supBody) | Out-Null

        # Clickable link, routed through Set-TextBlockWithLinks so
        # the underline-on-hover + click-to-open behavior matches
        # the rest of the Hub.
        $supLink = New-Object System.Windows.Controls.TextBlock
        $supLink.FontSize = 13
        $supLink.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $supLink.LineHeight = 20
        Set-TextBlockWithLinks -TextBlock $supLink -Text $Game.SupportUrl
        $supStack.Children.Add($supLink) | Out-Null

        $stack.Children.Add($supportBox) | Out-Null
    }

    # Action buttons (btnRow already added to stack above, right
    # below status block - we only populate it here).
    # Saturated solid colors throughout - cleaner read, friendlier
    # to the gloss overlay added below, and Add-SweepHover still
    # works because Background stays a SolidColorBrush.
    $primaryBtn = New-Object System.Windows.Controls.Border
    $primaryBtn.CornerRadius = [System.Windows.CornerRadius]::new(7)
    # Same padding as the reinstall pill next to it so their heights match
    # exactly (no fixed Height - it sizes to content like its neighbour).
    $primaryBtn.Padding = [System.Windows.Thickness]::new(16, 10, 16, 10)
    $primaryBtn.Cursor = [System.Windows.Input.Cursors]::Hand
    $primaryBtn.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
    # MinWidth keeps the width steady when the label swaps between
    # "VR Ready" and "Start in VR" - the button never grows wider on hover.
    $primaryBtn.MinWidth = 162
    # Inner stack holds the icon + label.
    $primaryStack = New-Object System.Windows.Controls.StackPanel
    $primaryStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $primaryStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $primaryTxt = New-Object System.Windows.Controls.TextBlock
    $primaryTxt.FontSize = 14
    $primaryTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $primaryTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $primaryTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $primaryTxt.Margin = [System.Windows.Thickness]::new(9, 0, 0, 0)
    # Clamp the line box so a tall glyph (the play triangle in the hover
    # label) cannot grow the button's height - it stays the same in every
    # state.
    $primaryTxt.LineHeight = 20
    $primaryTxt.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
    $isReady = ($state -and $state.State -eq "ready")
    $isUpdate = ($state -and $state.State -eq "update")
    $isInstalledNoMod = ($state -and $state.Tag -eq "installed")
    # Free game that Check Installed found NOT yet VR-installed (the scan
    # records State="free"). We highlight its Install button the same way
    # owned-but-no-mod games are highlighted, to nudge the free install.
    $isFreeScanned = ($state -and $state.State -eq "free")
    # Icon kind + color depend on state.
    $primaryIconKind  = "download"
    $primaryIconColor = "#FFFFFF"
    if ($isReady) {
        # VR Ready: very subtle green bg with a brighter, slightly
        # thicker (1.5px) border that signals "this is the active
        # state for this game" without screaming. Background pulled
        # way down per the user's preference (no more "algae green").
        $primaryTxt.Text = "VR Ready"
        $primaryBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
        $primaryBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
        $primaryBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fa873")
        $primaryTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
        $primaryIconKind = "check"
        $primaryIconColor = "#88dd99"
    } elseif ($isUpdate) {
        # Update available: solid blue with a brighter blue border
        # (1.5px) for the same "primary CTA" emphasis pattern. Hover
        # reveals "Start in VR" so the user can launch without forcing
        # the update.
        $primaryTxt.Text = "Update Mod"
        $primaryBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
        $primaryBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
        $primaryBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#6da3ff")
        $primaryTxt.Foreground = [System.Windows.Media.Brushes]::White
        $primaryIconKind = "update"
        $primaryIconColor = "#FFFFFF"
    } elseif ($isInstalledNoMod -or $isFreeScanned) {
        # Game owned but no VR mod yet - the page's primary action.
        # (Also FREE games confirmed not-installed by Check Installed:
        # same green emphasis so the free install is the obvious next step.)
        # Same H-style green as VR Ready but signals "install me"
        # via the brighter 1.5px border. Same family, same emphasis.
        # Label tracks the tile-button convention: external + itch
        # games say "Get Installer" (sends user to mod page); games
        # with a Hub-bundled installer (.Bat) say "Install Mod"
        # (Hub will actually run something).
        if ($Game.ButtonLabel) {
            $primaryTxt.Text = $Game.ButtonLabel
        } elseif ($Game.Type -eq "external" -or $Game.Type -eq "itch") {
            $primaryTxt.Text = "Get Installer"
        } else {
            $primaryTxt.Text = "Install Mod"
        }
        $primaryBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
        $primaryBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
        $primaryBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fa873")
        $primaryTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
        $primaryIconKind = "download"
        $primaryIconColor = "#88dd99"
    } else {
        # Default: state unknown OR scanned-not-found. Family-accent
        # slate that visibly steps back so Get on Steam dominates as
        # the primary CTA. Background ~40% darker than previous
        # iteration (factor 0.10+8 instead of 0.18+10), foreground
        # desaturated (150+0.22 instead of 180+0.30). Familie-Identitaet
        # bleibt sichtbar, der Button tritt aber klar zurueck.
        # Label follows the same tile-button convention as the
        # isInstalledNoMod branch above.
        if ($Game.ButtonLabel) {
            $primaryTxt.Text = $Game.ButtonLabel
        } elseif ($Game.Type -eq "external" -or $Game.Type -eq "itch") {
            $primaryTxt.Text = "Get Installer"
        } else {
            $primaryTxt.Text = "Install Mod"
        }
        # New style: near-transparent family-tint bg + a clearly
        # coloured family-accent 1.5px border (the border carries the
        # "clickable" signal), with brightened accent-tinted text.
        $slateColor = [System.Windows.Media.Color]::FromRgb(
            [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($famAcc.R * 0.09 + 6))))),
            [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($famAcc.G * 0.09 + 6))))),
            [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($famAcc.B * 0.09 + 6)))))
        )
        $primaryBtn.Background = New-Object System.Windows.Media.SolidColorBrush $slateColor
        $primaryBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
        $slateBorder = [System.Windows.Media.Color]::FromRgb(
            [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($famAcc.R * 0.55 + 60))))),
            [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($famAcc.G * 0.55 + 60))))),
            [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($famAcc.B * 0.55 + 60)))))
        )
        $primaryBtn.BorderBrush = New-Object System.Windows.Media.SolidColorBrush $slateBorder
        $fgColor = [System.Windows.Media.Color]::FromRgb(
            [byte]([Math]::Min(255, [int]([Math]::Round(120 + $famAcc.R * 0.45)))),
            [byte]([Math]::Min(255, [int]([Math]::Round(120 + $famAcc.G * 0.45)))),
            [byte]([Math]::Min(255, [int]([Math]::Round(120 + $famAcc.B * 0.45))))
        )
        $primaryTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush $fgColor
        $primaryIconKind = "download"
        # Match icon color to text foreground for monochrome look.
        $primaryIconHexR = [string]::Format("{0:X2}", [int]$fgColor.R)
        $primaryIconHexG = [string]::Format("{0:X2}", [int]$fgColor.G)
        $primaryIconHexB = [string]::Format("{0:X2}", [int]$fgColor.B)
        $primaryIconColor = "#$primaryIconHexR$primaryIconHexG$primaryIconHexB"
    }
    # Assemble icon + label and hang it as the button's content.
    $primaryIcon = New-ActionIcon -Kind $primaryIconKind -ColorHex $primaryIconColor -Size 15
    [void]$primaryStack.Children.Add($primaryIcon)
    [void]$primaryStack.Children.Add($primaryTxt)
    $primaryBtn.Child = $primaryStack
    # Add the gloss overlay AFTER setting the child - the helper
    # wraps the current child in a Grid that also holds the gloss
    # layer. The host Background stays a SolidColorBrush so
    # Add-SweepHover continues to work below.
    Add-ButtonGloss -Border $primaryBtn -Intensity 0.10

    # VR Ready / Update hover: a sibling Reinstall pill slides into
    # the row when the user hovers the primary button. In VR Ready
    # state it's a subtle grey "Reinstall Mod"; in Update state it's
    # blue with a reload icon - signaling clearly that an update is
    # waiting (click pill = run the update).
    $reinstallBtn = $null
    if ($isReady -or $isUpdate) {
        $reinstallBtn = New-Object System.Windows.Controls.Border
        $reinstallBtn.CornerRadius    = [System.Windows.CornerRadius]::new(7)
        # Symmetric padding to match Mod Page / Open in Steam
        # so the row reads as a coherent button group.
        $reinstallBtn.Padding         = [System.Windows.Thickness]::new(16, 10, 16, 10)
        if ($isUpdate) {
            $reinstallBtn.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
            $reinstallBtn.BorderThickness = [System.Windows.Thickness]::new(0)
        } else {
            $reinstallBtn.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#15151e")
            $reinstallBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
            $reinstallBtn.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5a6aa8")
        }
        $reinstallBtn.Cursor          = [System.Windows.Input.Cursors]::Hand
        $reinstallBtn.Margin          = [System.Windows.Thickness]::new(0, 0, 10, 0)
        $reinstallBtn.Visibility      = [System.Windows.Visibility]::Collapsed

        $reinstallStack = New-Object System.Windows.Controls.StackPanel
        $reinstallStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        # Reload glyph matches the one used in the main card list
        # (CardTile.ps1) for the reinstall pill that slides out of
        # Start-in-VR - same Unicode arrow, same Segoe UI Symbol
        # font - so the two reinstall affordances read as the same
        # control across both views.
        if ($isUpdate) {
            $reinstallIconColor = "#FFFFFF"
        } else {
            $reinstallIconColor = "#dddddd"
        }
        $reinstallIcon = New-Object System.Windows.Controls.TextBlock
        $reinstallIcon.Text = [char]0x21BB
        $reinstallIcon.FontSize = 16
        $reinstallIcon.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI Symbol")
        $reinstallIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($reinstallIconColor)
        $reinstallIcon.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
        $reinstallIcon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $reinstallStack.Children.Add($reinstallIcon) | Out-Null
        $reinstallTxt = New-Object System.Windows.Controls.TextBlock
        if ($isUpdate) {
            $reinstallTxt.Text = "Update Mod"
        } else {
            $reinstallTxt.Text = "Reinstall Mod"
        }
        # FontSize 14 + SemiBold to match the other action
        # buttons in the row. The previous 13 + Regular felt
        # noticeably thinner and lighter than its neighbours.
        $reinstallTxt.FontSize = 14
        $reinstallTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $reinstallTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $reinstallTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        if ($isUpdate) {
            $reinstallTxt.Foreground = [System.Windows.Media.Brushes]::White
        } else {
            $reinstallTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dddddd")
        }
        $reinstallStack.Children.Add($reinstallTxt) | Out-Null
        $reinstallBtn.Child = $reinstallStack
        Add-ButtonGloss -Border $reinstallBtn -Intensity 0.08

        # Snapshot resting brushes so leave restores them cleanly.
        $restingBg     = $primaryBtn.Background
        $restingBd     = $primaryBtn.BorderBrush
        $restingBdT    = $primaryBtn.BorderThickness
        $restingFg     = $primaryTxt.Foreground
        if ($isUpdate) {
            $restingText = "Update Mod"
        } else {
            $restingText = "VR Ready"
        }
        $startText   = "Start in VR  $([char]0x25B6)"
        $hoverState  = @{ PrimaryHover = $false; ReinstallHover = $false; RowHover = $false; Opened = $false }
        $isUpdateLocal = $isUpdate  # captured for closure
        # DualMode container - assigned later when we know whether
        # the game qualifies. The closure below picks up DepotBtn
        # by referencing the hashtable, so a later assignment is
        # visible to the closure when it runs.
        $dualRef = @{ DepotBtn = $null }

        $applyHoverState = {
            # The popover OPENS only from the primary button (or the
            # already-revealed reinstall pill). RowHover alone must NOT
            # open it - it only HOLDS an already-open popover while the
            # cursor roams the row (e.g. over Mod Page / Open in Steam).
            $opensIt = $hoverState.PrimaryHover -or $hoverState.ReinstallHover
            $holdsIt = $hoverState.RowHover -and $hoverState.Opened
            $isHovering = $opensIt -or $holdsIt
            if ($opensIt) { $hoverState.Opened = $true }
            if ($isHovering) {
                # Hover always shows green "Start in VR" on the
                # primary button - same in both states. In update
                # state this gives the user the option to launch
                # the game without forcing the update; in ready
                # state it surfaces the start affordance directly.
                # Border stays 1.5px so size doesn't snap on hover.
                # DualMode: primary label becomes "Start Current"
                # since the user picks between Current and Depot.
                $st = $null
                if ($global:gameStateMap.ContainsKey($Game.Title)) {
                    $st = $global:gameStateMap[$Game.Title]
                }
                if ($st -and $st.DualMode) {
                    $primaryTxt.Text = "Start Current  $([char]0x25B6)"
                } else {
                    $primaryTxt.Text = $startText
                }
                $primaryBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c2a22")
                $primaryBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
                $primaryBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#74c98a")
                $primaryTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#a6ecbb")
                # The hover label already carries the play glyph; hide the
                # left status icon so "Start in VR" doesn't show two symbols.
                if ($primaryIcon) { $primaryIcon.Visibility = [System.Windows.Visibility]::Collapsed }
                $reinstallBtn.Visibility = [System.Windows.Visibility]::Visible
                if ($dualRef.DepotBtn) { $dualRef.DepotBtn.Visibility = [System.Windows.Visibility]::Visible }
            } else {
                $hoverState.Opened = $false
                $primaryTxt.Text       = $restingText
                $primaryBtn.Background = $restingBg
                $primaryBtn.BorderThickness = $restingBdT
                if ($restingBd) { $primaryBtn.BorderBrush = $restingBd }
                $primaryTxt.Foreground = $restingFg
                if ($primaryIcon) { $primaryIcon.Visibility = [System.Windows.Visibility]::Visible }
                $reinstallBtn.Visibility = [System.Windows.Visibility]::Collapsed
                if ($dualRef.DepotBtn) { $dualRef.DepotBtn.Visibility = [System.Windows.Visibility]::Collapsed }
            }
        }.GetNewClosure()

        # Closing the popover is delayed by 250ms so the user has
        # time to move from primary to reinstall (and back) across
        # the small margin gap. If a MouseEnter fires on either
        # element before the timer ticks, the timer is cancelled
        # and the popover stays open. Without this, leaving primary
        # collapses reinstall before the cursor reaches it.
        $closeTimer = New-Object System.Windows.Threading.DispatcherTimer
        $closeTimer.Interval = [TimeSpan]::FromMilliseconds(250)
        $closeTimer.Add_Tick({
            $closeTimer.Stop()
            & $applyHoverState
        }.GetNewClosure())

        $primaryBtn.Add_MouseEnter({
            $closeTimer.Stop()
            $hoverState.PrimaryHover = $true
            & $applyHoverState
        }.GetNewClosure())
        $primaryBtn.Add_MouseLeave({
            $hoverState.PrimaryHover = $false
            $closeTimer.Stop(); $closeTimer.Start()
        }.GetNewClosure())
        $reinstallBtn.Add_MouseEnter({
            $closeTimer.Stop()
            $hoverState.ReinstallHover = $true
            & $applyHoverState
            if ($isUpdateLocal) {
                # Slightly brighter blue on hover - keeps the
                # update-blue identity, just lifts the contrast.
                $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3b82f6")
            } else {
                $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#252535")
                $reinstallTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dddddd")
                $reinstallIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dddddd")
            }
        }.GetNewClosure())
        $reinstallBtn.Add_MouseLeave({
            $hoverState.ReinstallHover = $false
            if ($isUpdateLocal) {
                $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
            } else {
                $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a1a22")
                $reinstallTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#aaaaaa")
                $reinstallIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#aaaaaa")
            }
            $closeTimer.Stop(); $closeTimer.Start()
        }.GetNewClosure())

        # Whole-row hover: keep the popped-out buttons (Reinstall, Depot)
        # visible while the cursor is anywhere in the button row - even
        # over Mod Page / Open in Steam. They collapse only when the
        # cursor leaves the entire row. MouseEnter/Leave on the StackPanel
        # fire on row enter/exit, not when moving between its children.
        $btnRow.Add_MouseEnter({
            $closeTimer.Stop()
            $hoverState.RowHover = $true
            & $applyHoverState
        }.GetNewClosure())
        $btnRow.Add_MouseLeave({
            $hoverState.RowHover = $false
            $closeTimer.Stop(); $closeTimer.Start()
        }.GetNewClosure())

        $reinstallGameRef = $Game
        $reinstallScriptDir = $script:scriptDir
        $reinstallBtn.Add_MouseLeftButtonUp({
            if (-not $reinstallGameRef) { return }
            if (-not $reinstallGameRef.Bat) { return }
            if (-not $reinstallScriptDir) { return }
            $batPath = Join-Path $reinstallScriptDir $reinstallGameRef.Bat
            if (-not (Test-Path $batPath)) { return }
            # Run through the logging wrapper (Start-LoggedInstaller, Helpers.ps1):
            # saves output to Logs\<Title>-<timestamp>.log; the branch logic and
            # the RequiresAdmin elevated path live in one place.
            Start-LoggedInstaller -Game $reinstallGameRef -BatPath $batPath -RequiresAdmin:([bool]$reinstallGameRef.RequiresAdmin) | Out-Null
        }.GetNewClosure())
    }

    $gameForBtn = $Game
    $scriptDirCap = $script:scriptDir
    $primaryBtn.Add_MouseLeftButtonDown({
        if (-not $gameForBtn) { return }
        # DualMode: primary button always launches "Current" variant.
        # The depot variant has its own button in the row.
        $stForBtn = $null
        if ($global:gameStateMap.ContainsKey($gameForBtn.Title)) {
            $stForBtn = $global:gameStateMap[$gameForBtn.Title]
        }
        if ($stForBtn -and $stForBtn.DualMode -and $isReady) {
            Start-GameInVR -Game $gameForBtn -Mode "Current"
            return
        }
        # Ready state: always Start in VR.
        if ($isReady) {
            Start-GameInVR -Game $gameForBtn
            return
        }
        # Update state: if the user is currently hovering (button
        # has morphed to green "Start in VR"), launch the game.
        # Otherwise (button still shows blue "Update Mod"), run the
        # installer to apply the update.
        if ($isUpdate -and $hoverState -and $hoverState.PrimaryHover) {
            if ($stForBtn -and $stForBtn.DualMode) {
                Start-GameInVR -Game $gameForBtn -Mode "Current"
            } else {
                Start-GameInVR -Game $gameForBtn
            }
            return
        }
        if (-not $gameForBtn.Bat) {
            # "Get Installer" should open the DOWNLOAD, not the info
            # page. Prefer DownloadUrl (the installer/release asset);
            # fall back to InfoUrl only if no DownloadUrl is set. This
            # keeps InfoUrl free to drive the "i" pill / info page.
            # BUT: a raw api.github.com/... DownloadUrl returns JSON,
            # not a page a browser can use - DetailView (unlike the
            # card list) does not resolve the API, so for those we
            # fall back to a human-facing page (InfoUrl, then Url).
            $getUrl = if ($gameForBtn.DownloadUrl -and ($gameForBtn.DownloadUrl -notmatch 'api\.github\.com')) {
                $gameForBtn.DownloadUrl
            } elseif ($gameForBtn.InfoUrl) {
                $gameForBtn.InfoUrl
            } else {
                $gameForBtn.Url
            }
            if ($getUrl) {
                # Steam-type games (the Half-Life family is the only
                # case here, since they ship the VR mod via the
                # regular Steam store page): set the same single-
                # game refresh marker the Steam button below uses,
                # so the install state flips on return without a
                # manual Check Installed. External/itch games are
                # not in any Steam library, so we skip the marker
                # for them - the refresh would no-op anyway and
                # leaving the marker slot free preserves it for a
                # later real Steam-button click.
                if ($gameForBtn.Type -eq "steam") {
                    $global:LastSteamButtonClickAt    = [DateTime]::UtcNow
                    $global:LastSteamButtonClickTitle = $gameForBtn.Title
                }
                Start-Process $getUrl
            }
            return
        }
        if (-not $scriptDirCap) { return }
        $batPath = Join-Path $scriptDirCap $gameForBtn.Bat
        if (-not (Test-Path $batPath)) {
            if ($gameForBtn.InfoUrl) { Start-Process $gameForBtn.InfoUrl }
            return
        }
        # Run the installer through the logging wrapper (Start-LoggedInstaller
        # in Helpers.ps1): output is saved to Logs\<Title>-<timestamp>.log, and
        # the branch logic (LukeRoss / REFramework / standard) plus the
        # RequiresAdmin elevated path now live in one place. We capture the
        # launched process so the detail view auto-refreshes when it exits -
        # users were complaining the page didn't update post-install without a
        # manual Check Installed run.
        $launchedProc = Start-LoggedInstaller -Game $gameForBtn -BatPath $batPath -RequiresAdmin:([bool]$gameForBtn.RequiresAdmin)
        # Auto-refresh after the installer exits. We use a
        # DispatcherTimer running on the UI thread instead of the
        # async Register-ObjectEvent path, because:
        #   1. The Action block of Register-ObjectEvent runs on a
        #      separate runspace where script-scope variables and
        #      functions aren't reliably visible, even via global
        #      lookups, so the refresh sometimes silently no-ops.
        #   2. EnableRaisingEvents has a race condition with
        #      processes that exit very quickly - the event may
        #      already have fired before we subscribe.
        # Polling on the UI thread sidesteps both. 750ms tick is
        # invisible to the user and cheap.
        if ($launchedProc) {
            try {
                $global:PendingInstallTitle = $gameForBtn.Title
                $timer = New-Object System.Windows.Threading.DispatcherTimer
                $timer.Interval = [TimeSpan]::FromMilliseconds(750)
                # Stash the process on the timer so the Tick handler
                # can find it without closure capture (PS5 quirks).
                $timer.Tag = $launchedProc
                $timer.Add_Tick({
                    param($s, $e)
                    $proc = $s.Tag
                    if (-not $proc -or $proc.HasExited) {
                        try { $s.Stop() } catch {}
                        try { Invoke-PostInstallRefresh } catch {}
                    }
                })
                $timer.Start()
            } catch {}
        }
    }.GetNewClosure())
    # Only attach the universal sweep hover when the button doesn't
    # already have a state-aware hover. ready/update have a sibling
    # Reinstall-pill animation; sweeping over them would compete.
    if (-not ($isReady -or $isUpdate)) {
        Add-SweepHover -Border $primaryBtn
    }
    # Wabbajack guide entries have no Hub installer - the "Get
    # Wabbajack" + mod-link buttons + Open in Steam fully cover the
    # flow, so we suppress the generic Install/primary button here.
    if (-not $Game.WabbajackUrl) {
        $twoSt = $global:gameStateMap[$Game.Title]
        if ($Game.TwoMods -and $twoSt -and $twoSt.TwoMods) {
            # TwoMods: offer a launch choice between the two alternative
            # mods. A present mod shows "Play X" and launches; a not-yet-
            # installed mod shows "Install X" and opens its installer.
            # The choice appears as soon as one mod is on disk.
            $aPresent = [bool]$twoSt.ModAPresent
            $bPresent = [bool]$twoSt.ModBPresent
            $playA = New-TwoModsButton -Game $Game -Mode "ModA" -Label ($(if ($aPresent) { "Play " } else { "Install " }) + $twoSt.ModAName) -AccentHex $accentHex -Installed:$aPresent
            $playA.Margin = [System.Windows.Thickness]::new(0,0,10,0)
            $btnRow.Children.Add($playA) | Out-Null
            $playB = New-TwoModsButton -Game $Game -Mode "ModB" -Label ($(if ($bPresent) { "Play " } else { "Install " }) + $twoSt.ModBName) -AccentHex $accentHex -Installed:$bPresent
            $playB.Margin = [System.Windows.Thickness]::new(0,0,10,0)
            $btnRow.Children.Add($playB) | Out-Null
            # TwoMods has no single primary button, so the Reinstall Mod
            # pill (built above when VR Ready) is revealed by hovering
            # either Play button. Reuses the same hover state + close
            # timer as the normal primary-button popover.
            if ($reinstallBtn) {
                $playA.Add_MouseEnter({ $closeTimer.Stop(); $hoverState.PrimaryHover = $true; & $applyHoverState }.GetNewClosure())
                $playA.Add_MouseLeave({ $hoverState.PrimaryHover = $false; $closeTimer.Stop(); $closeTimer.Start() }.GetNewClosure())
                $playB.Add_MouseEnter({ $closeTimer.Stop(); $hoverState.PrimaryHover = $true; & $applyHoverState }.GetNewClosure())
                $playB.Add_MouseLeave({ $hoverState.PrimaryHover = $false; $closeTimer.Stop(); $closeTimer.Start() }.GetNewClosure())
            }
        } else {
            $btnRow.Children.Add($primaryBtn) | Out-Null
        }
    }

    # Locate / correction buttons. Once the user has located a game (a
    # .user_located marker exists) the one-shot "Locate Game" button is
    # replaced by "Re-locate Game" + "Clear" so user mistakes (wrong
    # folder / wrong exe) stay correctable. Before that, "Locate Game"
    # shows only when Check Installed did NOT find the game and there is
    # a ModFile to verify.
    $userLocated = $false
    try {
        $ulfChk = Get-UserLocatedFile -Game $Game
        $userLocated = ($ulfChk -and (Test-Path $ulfChk))
    } catch {}
    if ($userLocated) {
        try {
            $locGroup = New-Object System.Windows.Controls.StackPanel
            $locGroup.Orientation = [System.Windows.Controls.Orientation]::Horizontal
            $locGroup.Background = [System.Windows.Media.Brushes]::Transparent

            $reBtn = New-LocateButton -Game $Game -AccentHex $accentHex -Label "Re-locate Game"
            $reBtn.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
            $locGroup.Children.Add($reBtn) | Out-Null

            # Clear is a secondary action - hidden until the user hovers
            # the group (same idea as the Reinstall pill that reveals on
            # Start-in-VR hover), so the row is not cluttered with
            # always-visible buttons.
            $clrBtn = New-ClearLocationButton -Game $Game -AccentHex $accentHex
            $clrBtn.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
            $clrBtn.Visibility = [System.Windows.Visibility]::Collapsed
            $locGroup.Children.Add($clrBtn) | Out-Null

            $locGroup.Add_MouseEnter({ $clrBtn.Visibility = [System.Windows.Visibility]::Visible }.GetNewClosure())
            $locGroup.Add_MouseLeave({ $clrBtn.Visibility = [System.Windows.Visibility]::Collapsed }.GetNewClosure())

            $btnRow.Children.Add($locGroup) | Out-Null
        } catch {}
    } elseif ($global:HasRunInstalledScan -and (-not ($isReady -or $isUpdate -or $isInstalledNoMod -or $isFreeScanned)) -and ($Game.ModFile -or $Game.TwoMods)) {
        try {
            $locateBtn = New-LocateButton -Game $Game -AccentHex $accentHex
            $locateBtn.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
            $btnRow.Children.Add($locateBtn) | Out-Null
        } catch {}
    }

    # DualMode "Start Depot" button - only built for REPO VR / Content
    # Warning VR style games where both Mode 1 (current Thunderstore
    # install in Steam library) AND Mode 2 (pinned depot in C:\Games\)
    # are present simultaneously. Inserted between primary and the
    # reinstall pill so the hover row reads:
    #   Start Current | Start Depot | Reinstall Mod
    $depotBtn = $null
    $isDualMode = $false
    if ($Game.DualMode -and ($isReady -or $isUpdate)) {
        $st = $global:gameStateMap[$Game.Title]
        if ($st -and $st.DualMode) {
            $isDualMode = $true
            $depotBtn = New-Object System.Windows.Controls.Border
            $depotBtn.CornerRadius    = [System.Windows.CornerRadius]::new(7)
            $depotBtn.Padding         = [System.Windows.Thickness]::new(16, 10, 16, 10)
            $depotBtn.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
            $depotBtn.BorderThickness = [System.Windows.Thickness]::new(1)
            $depotBtn.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
            $depotBtn.Cursor          = [System.Windows.Input.Cursors]::Hand
            $depotBtn.Margin          = [System.Windows.Thickness]::new(0, 0, 10, 0)
            $depotBtn.Visibility      = [System.Windows.Visibility]::Collapsed

            $depotStack = New-Object System.Windows.Controls.StackPanel
            $depotStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
            $depotIcon = New-Object System.Windows.Controls.TextBlock
            $depotIcon.Text = [char]0x25B6
            $depotIcon.FontSize = 13
            $depotIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
            $depotIcon.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
            $depotIcon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $depotStack.Children.Add($depotIcon) | Out-Null
            $depotTxt = New-Object System.Windows.Controls.TextBlock
            $depotTxt.Text = "Start Depot"
            $depotTxt.FontSize = 14
            $depotTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
            $depotTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $depotTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
            $depotTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $depotStack.Children.Add($depotTxt) | Out-Null
            $depotBtn.Child = $depotStack
            Add-ButtonGloss -Border $depotBtn -Intensity 0.08

            # Hover tint to distinguish active button
            $depotBtn.Add_MouseEnter({
                $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1c2a22")
                $closeTimer.Stop()
                $hoverState.ReinstallHover = $true
                & $applyHoverState
            }.GetNewClosure())
            $depotBtn.Add_MouseLeave({
                $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
                $hoverState.ReinstallHover = $false
                $closeTimer.Stop(); $closeTimer.Start()
            }.GetNewClosure())

            $depotGameRef = $Game
            $depotBtn.Add_MouseLeftButtonUp({
                if ($depotGameRef) { Start-GameInVR -Game $depotGameRef -Mode "Depot" }
            }.GetNewClosure())

            $btnRow.Children.Add($depotBtn) | Out-Null
            $dualRef.DepotBtn = $depotBtn
        }
    }

    if ($reinstallBtn) {
        $btnRow.Children.Add($reinstallBtn) | Out-Null
    }

    # ----- Add-on button (e.g. HL2VRU Unleashed for the Half-Life 2
    # VR family) -----------------------------------------------------
    # Shows only when the catalog entry declares an AddonInstaller.
    # Three visual states based on the base mod's install status:
    #
    #   1) Base NOT installed yet   -> dimmed, not clickable.
    #                                  Tooltip explains the prerequisite.
    #   2) Base installed (VR Ready) but add-on NOT installed
    #                               -> "lit": blue background with
    #                                  brighter outline, sweep hover.
    #   3) Base + add-on installed  -> green-outlined "Reinstall <Name>",
    #                                  mirroring the VR Ready style on
    #                                  the primary button.
    #
    # State detection is local to this function so it does not need
    # the gameStateMap. The base-installed test uses ModFile present
    # under the resolved $gameDir (the standard hub check). The
    # add-on-installed test uses AddonProbeFile in the same folder.
    if ($Game.AddonInstaller -and $Game.AddonName) {
        # Resolve where the base game/mod lives. For the HL2VR family
        # this is always <SteamLibrary>\steamapps\common\Half-Life 2 VR\.
        # We borrow Filter.ps1's resolution logic: prefer the cached
        # state map's GameDir (set by Invoke-CheckInstalledScan), else
        # walk the same fallback the filter uses. Keep this strictly
        # read-only so we never touch state by simply opening the page.
        $baseDir = $null
        if ($state -and $state.GameDir) { $baseDir = $state.GameDir }
        if (-not $baseDir) {
            try {
                $recordedPath = Read-InstalledPath -Game $Game
                if ($recordedPath -and (Test-Path $recordedPath)) {
                    $baseDir = $recordedPath
                }
            } catch { }
        }
        if (-not $baseDir -and $Game.SteamFolder) {
            try {
                $libs = @()
                $steamRoot = $null
                try {
                    $rk = "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"
                    if (Test-Path $rk) {
                        $steamRoot = (Get-ItemProperty -Path $rk -Name InstallPath -EA SilentlyContinue).InstallPath
                    }
                    if (-not $steamRoot) {
                        $rk2 = "HKLM:\SOFTWARE\Valve\Steam"
                        if (Test-Path $rk2) {
                            $steamRoot = (Get-ItemProperty -Path $rk2 -Name InstallPath -EA SilentlyContinue).InstallPath
                        }
                    }
                } catch { }
                if ($steamRoot -and (Test-Path $steamRoot)) {
                    $libs += $steamRoot
                    $vdf = Join-Path $steamRoot "steamapps\libraryfolders.vdf"
                    if (Test-Path $vdf) {
                        $vdfText = Get-Content $vdf -Raw -EA SilentlyContinue
                        if ($vdfText) {
                            $pathMatches = [regex]::Matches($vdfText, '"path"\s+"([^"]+)"')
                            foreach ($m in $pathMatches) {
                                $p = $m.Groups[1].Value -replace '\\\\', '\'
                                if ($p -and (Test-Path $p) -and ($libs -notcontains $p)) {
                                    $libs += $p
                                }
                            }
                        }
                    }
                }
                foreach ($lib in $libs) {
                    $candidate = Join-Path $lib "steamapps\common\$($Game.SteamFolder)"
                    if (Test-Path $candidate) { $baseDir = $candidate; break }
                }
            } catch { }
        }

        $baseInstalled  = $false
        $addonInstalled = $false
        if ($baseDir -and (Test-Path $baseDir)) {
            if ($Game.ModFile) {
                $modPath = Join-Path $baseDir $Game.ModFile
                if (Test-Path $modPath) { $baseInstalled = $true }
            } else {
                # No ModFile defined -> treat folder existence as enough.
                $baseInstalled = $true
            }
        }

        # Addon-installed detection: use the installer's own
        # .installed_path marker file. We can't probe for a "new" file
        # under the base game's folder because some add-ons (like
        # HL2VRU) overwrite vanilla files rather than adding new ones,
        # so an existence check would false-positive on every fresh
        # base install. The marker lives next to the installer .ps1
        # and is only written when our installer ran successfully.
        if ($baseInstalled -and $Game.AddonInstaller) {
            try {
                $coreRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
                $addonDir = [System.IO.Path]::GetDirectoryName((Join-Path $coreRoot $Game.AddonInstaller))
                $markerPath = Join-Path $addonDir ".installed_path"
                if (Test-Path $markerPath) {
                    # Verify the marker still points at the same base
                    # folder we resolved above. Stops the button from
                    # claiming "installed" if the user installed the
                    # add-on into a different Steam library and later
                    # moved or deleted that one.
                    $recorded = (Get-Content $markerPath -Raw -EA SilentlyContinue)
                    if ($recorded) {
                        $recorded = $recorded.Trim()
                        if ($recorded -and (Test-Path $recorded)) {
                            # Same base folder OR add-on was installed
                            # into one of the HL2VR siblings - the
                            # add-on lives in the same folder anyway,
                            # so any valid recorded path counts.
                            $addonInstalled = $true
                        }
                    }
                }
            } catch { }
        }

        $addonBtn = New-Object System.Windows.Controls.Border
        $addonBtn.CornerRadius = [System.Windows.CornerRadius]::new(7)
        $addonBtn.Padding = [System.Windows.Thickness]::new(16, 10, 16, 10)
        $addonBtn.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
        $addonStack = New-Object System.Windows.Controls.StackPanel
        $addonStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $addonTxt = New-Object System.Windows.Controls.TextBlock
        $addonTxt.FontSize = 14
        $addonTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $addonTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $addonTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $addonTxt.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)

        if (-not $baseInstalled) {
            # State 1: dimmed
            $addonBtn.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#181820")
            $addonBtn.BorderThickness = [System.Windows.Thickness]::new(1)
            $addonBtn.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
            $addonBtn.Cursor         = [System.Windows.Input.Cursors]::Arrow
            $addonBtn.Opacity        = 0.55
            $addonBtn.ToolTip        = "Install the base $($Game.Mod) first."
            $addonIcon = New-ActionIcon -Kind "download" -ColorHex "#555568" -Size 14
            $addonTxt.Text = "+ Install $($Game.AddonName) add-on"
            $addonTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5b5b6e")
        } elseif ($addonInstalled) {
            # State 3: green-outlined Reinstall
            $addonBtn.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
            $addonBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
            $addonBtn.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fa873")
            $addonBtn.Cursor         = [System.Windows.Input.Cursors]::Hand
            $addonBtn.ToolTip        = "$($Game.AddonName) is installed. Click to reinstall."
            $addonIcon = New-ActionIcon -Kind "check" -ColorHex "#88dd99" -Size 14
            $addonTxt.Text = "$($Game.AddonName) installed"
            $addonTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
        } else {
            # State 2: lit / ready to install
            $addonBtn.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0e2030")
            $addonBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
            $addonBtn.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5599ee")
            $addonBtn.Cursor         = [System.Windows.Input.Cursors]::Hand
            $addonBtn.ToolTip        = "Install $($Game.AddonName) add-on on top of $($Game.Mod)."
            $addonIcon = New-ActionIcon -Kind "download" -ColorHex "#7ab5ff" -Size 14
            $addonTxt.Text = "+ Install $($Game.AddonName) add-on"
            $addonTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7ab5ff")
        }
        [void]$addonStack.Children.Add($addonIcon)
        [void]$addonStack.Children.Add($addonTxt)
        $addonBtn.Child = $addonStack

        if ($baseInstalled) {
            $addonInstallerCap = $Game.AddonInstaller
            $addonBtn.Add_MouseLeftButtonUp({
                param($s, $e)
                $batPath = Join-Path $PSScriptRoot ".."
                $batPath = Join-Path $batPath $addonInstallerCap
                # Path normalisation: $PSScriptRoot here is Core\Modules\,
                # so go up one level to Core\ before applying the
                # AddonInstaller-relative path (e.g. "HL2VRU\HL2VRU-core.ps1").
                $batPath = [System.IO.Path]::GetFullPath($batPath)
                if (Test-Path $batPath) {
                    try {
                        # Route through the logging wrapper (Kind=Direct: a bare
                        # powershell -File of the addon's installer .ps1) so the
                        # addon install lands in Logs\ like every other install.
                        $addonLogsDir = Join-Path $global:scriptDir "Logs"
                        $addonArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$($global:RunInstallerPath)`" -Title `"$($Game.Title)`" -Kind Direct -BatPath `"$batPath`" -LogsDir `"$addonLogsDir`""
                        $proc = Start-Process "powershell.exe" -ArgumentList $addonArgs -PassThru
                        # Poll for installer exit and re-render the detail
                        # page so the addon button flips to "installed"
                        # without a manual refresh. Same pattern the hub
                        # uses for the primary install button.
                        if ($proc) {
                            $gameForRefresh = $Game
                            $timer = New-Object System.Windows.Threading.DispatcherTimer
                            $timer.Interval = [TimeSpan]::FromMilliseconds(750)
                            $timer.Tag = $proc
                            $timer.Add_Tick({
                                param($s, $e)
                                $p = $s.Tag
                                if (-not $p -or $p.HasExited) {
                                    try { $s.Stop() } catch { }
                                    # Re-render the detail page for the
                                    # game we are currently looking at.
                                    try {
                                        if ($global:currentDetailGame) {
                                            Show-DiscoverDetail -Game $global:currentDetailGame
                                        }
                                    } catch { }
                                }
                            })
                            $timer.Start()
                        }
                    } catch { }
                }
            }.GetNewClosure())
            if (-not $addonInstalled) {
                Add-SweepHover -Border $addonBtn
            }
        }

        $btnRow.Children.Add($addonBtn) | Out-Null
    }

    if ($Game.WabbajackUrl) {
        # Wabbajack-based entries (Fallout 4 VR / Skyrim VR modlists)
        # are installed via Wabbajack, not from Steam. "Get Wabbajack"
        # is the leftmost / primary CTA (Wabbajack purple), followed
        # by Mod Page and Open in Steam.
        $wjBtn = New-Object System.Windows.Controls.Border
        $wjBtn.CornerRadius = [System.Windows.CornerRadius]::new(7)
        $wjBtn.Padding = [System.Windows.Thickness]::new(16, 10, 16, 10)
        $wjBtn.Cursor = [System.Windows.Input.Cursors]::Hand
        $wjBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4a3a78")
        $wjBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
        $wjBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8a72d8")
        $wjBtn.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
        $wjStack = New-Object System.Windows.Controls.StackPanel
        $wjStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $wjIcon = New-ActionIcon -Kind "download" -ColorHex "#FFFFFF" -Size 14
        [void]$wjStack.Children.Add($wjIcon)
        $wjTxt = New-Object System.Windows.Controls.TextBlock
        $wjTxt.Text = "Get Wabbajack"
        $wjTxt.FontSize = 14
        $wjTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $wjTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $wjTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $wjTxt.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
        $wjTxt.Foreground = [System.Windows.Media.Brushes]::White
        [void]$wjStack.Children.Add($wjTxt)
        $wjBtn.Child = $wjStack
        Add-ButtonGloss -Border $wjBtn -Intensity 0.10
        $wjUrlCap = $Game.WabbajackUrl
        $wjBtn.Add_MouseLeftButtonUp({
            try { Start-Process $wjUrlCap } catch { }
        }.GetNewClosure())
        Add-SweepHover -Border $wjBtn
        $btnRow.Children.Add($wjBtn) | Out-Null
    }

    if ($Game.ModButtons) {
        # Multiple named link buttons (e.g. Fallout 4 VR: "VR
        # Essentials" + "London VR"). Replaces the single generic
        # "Mod Page" button. Each entry is @{ Label=...; Url=... }.
        foreach ($mb in $Game.ModButtons) {
            $mbBtn = New-Object System.Windows.Controls.Border
            $mbBtn.CornerRadius = [System.Windows.CornerRadius]::new(7)
            $mbBtn.Padding = [System.Windows.Thickness]::new(16, 10, 16, 10)
            $mbBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#122c33")
            $mbBtn.BorderThickness = [System.Windows.Thickness]::new(1)
            $mbBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a7a92")
            $mbBtn.Cursor = [System.Windows.Input.Cursors]::Hand
            $mbBtn.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
            $mbStack = New-Object System.Windows.Controls.StackPanel
            $mbStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
            $mbIcon = New-ActionIcon -Kind "external" -ColorHex "#b8dde8" -Size 14
            [void]$mbStack.Children.Add($mbIcon)
            $mbTxt = New-Object System.Windows.Controls.TextBlock
            $mbTxt.Text = $mb.Label
            $mbTxt.FontSize = 14
            $mbTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
            $mbTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#b8dde8")
            $mbTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $mbTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $mbTxt.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
            [void]$mbStack.Children.Add($mbTxt)
            $mbBtn.Child = $mbStack
            $mbUrlCap = $mb.Url
            $mbBtn.Add_MouseLeftButtonUp({ try { Start-Process $mbUrlCap } catch {} }.GetNewClosure())
            Add-SweepHover -Border $mbBtn
            $btnRow.Children.Add($mbBtn) | Out-Null
        }
    }

    if (-not $Game.ModButtons -and -not $Game.HideModPageButton -and ($Game.InfoUrl -or $Game.ModPageUrl)) {
        $infoBtnD = New-Object System.Windows.Controls.Border
        $infoBtnD.CornerRadius = [System.Windows.CornerRadius]::new(7)
        $infoBtnD.Padding = [System.Windows.Thickness]::new(16, 10, 16, 10)
        # V7 secondary-button palette: a touch more substance than
        # the previous matte grey so the button doesn't read as
        # disabled. Background lifted, border notably brighter
        # (the main "I'm clickable" signal), text/icon brighter too.
        # V6 teal palette for clear color identity. Mod Page
        # used to be neutral grey which read as disabled next
        # to the also-greyish Open-in-Steam button. Teal pulls
        # it out of the grey-band and signals "info/docs" tone
        # while staying gedaempft vs the primary CTAs.
        $infoBtnD.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0e1c21")
        $infoBtnD.BorderThickness = [System.Windows.Thickness]::new(1.5)
        $infoBtnD.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4a9ab0")
        $infoBtnD.Cursor = [System.Windows.Input.Cursors]::Hand
        $infoBtnD.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
        $infoStack = New-Object System.Windows.Controls.StackPanel
        $infoStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $infoIcon = New-ActionIcon -Kind "external" -ColorHex "#b8dde8" -Size 14
        [void]$infoStack.Children.Add($infoIcon)
        $infoBtnDTxt = New-Object System.Windows.Controls.TextBlock
        $infoBtnDTxt.Text = "Mod Page"
        $infoBtnDTxt.FontSize = 14
        $infoBtnDTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $infoBtnDTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#b8dde8")
        $infoBtnDTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $infoBtnDTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $infoBtnDTxt.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
        [void]$infoStack.Children.Add($infoBtnDTxt)
        $infoBtnD.Child = $infoStack
        # No ButtonGloss here: the gradient brightens only the
        # top half of the border and leaves the bottom flat. On a
        # secondary button where the border IS the main clickable
        # signal, we want the lift applied uniformly all the way
        # around. Keeping the SolidColorBrush at #44445a achieves
        # that. Primary buttons still get the gloss because their
        # background does the heavy lifting there.
        # ModPageUrl override allows a different URL for the "Mod
        # Page" button than the InfoUrl used by the Install Mod
        # button. Lets entries point those two buttons at different
        # destinations (e.g. Discord invite for community page vs.
        # static downloads page for the actual installer).
        $infoUrlCap = if ($Game.ModPageUrl) { $Game.ModPageUrl } else { $Game.InfoUrl }
        $infoBtnD.Add_MouseLeftButtonUp({ Start-Process $infoUrlCap }.GetNewClosure())
        Add-SweepHover -Border $infoBtnD
        $btnRow.Children.Add($infoBtnD) | Out-Null
    }

    if ($Game.SteamId -and -not $Game.HideSteamButton) {
        $detectStateBtn = $global:gameStateMap[$Game.Title]
        $isInstalledBtn = $detectStateBtn -and $detectStateBtn.Tag -in @("installed", "vrinstalled", "vrupdate")
        $needsBuying    = $global:HasRunInstalledScan -and -not $isInstalledBtn
        # Daggerfall VR special case (see the hint block above): its SteamId
        # is the free DOS Daggerfall, detected by its own files rather than
        # the VR-mod scan. If the player already has it on disk, drop the
        # emphasized "Get on Steam" CTA to the muted "Open in Steam" - they
        # do not need to fetch it.
        if ($needsBuying -and $Game.Title -eq "Daggerfall VR" -and (Test-DosDaggerfallOnDisk)) {
            $needsBuying = $false
        }

        $steamBtn = New-Object System.Windows.Controls.Border
        $steamBtn.CornerRadius = [System.Windows.CornerRadius]::new(7)
        $steamBtn.Padding = [System.Windows.Thickness]::new(16, 10, 16, 10)
        $steamBtn.Cursor = [System.Windows.Input.Cursors]::Hand
        $steamStack = New-Object System.Windows.Controls.StackPanel
        $steamStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $steamBtnTxt = New-Object System.Windows.Controls.TextBlock
        $steamBtnTxt.FontSize = 14
        $steamBtnTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $steamBtnTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $steamBtnTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $steamBtnTxt.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
        $steamIconKind  = "steam"
        $steamIconColor = "#FFFFFF"
        if ($needsBuying) {
            # Prominent CTA - same blue palette as the Update state.
            # Solid #2563eb with the 1.5px brighter-blue border that
            # marks "emphasized" state across the Hub.
            $steamBtn.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
            $steamBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
            $steamBtn.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#6da3ff")
            $steamBtnTxt.Text       = "Get on Steam"
            $steamBtnTxt.Foreground = [System.Windows.Media.Brushes]::White
            $steamIconKind  = "check"
            $steamIconColor = "#FFFFFF"
        } else {
            # V6 gedaempftes blue palette. Open-in-Steam keeps a
            # clear Steam-blue identity so it reads as "the Steam
            # button" rather than a generic grey tile - but the
            # tones stay matter than the Get-on-Steam CTA above
            # so it remains visually subordinate to whichever
            # primary button sits to its left.
            $steamBtn.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#101a30")
            $steamBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
            $steamBtn.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5078cc")
            $steamBtnTxt.Text       = "Open in Steam"
            $steamBtnTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#b8cdf0")
            $steamIconKind  = "steam"
            $steamIconColor = "#b8cdf0"
        }
        $steamIcon = New-ActionIcon -Kind $steamIconKind -ColorHex $steamIconColor -Size 14
        [void]$steamStack.Children.Add($steamIcon)
        [void]$steamStack.Children.Add($steamBtnTxt)
        $steamBtn.Child = $steamStack
        if ($needsBuying) {
            # Primary CTA: gloss adds the catch-light on the
            # blue background that makes the button feel like
            # a physical click target.
            Add-ButtonGloss -Border $steamBtn -Intensity 0.10
        }
        # Open-in-Steam branch (else): no gloss - the gradient
        # would brighten only the top half of the border and
        # leave the bottom flat. On a secondary button where
        # the border IS the main clickable signal we want the
        # SolidColorBrush at #45607e to stay uniform.
        $sIdCap = $Game.SteamId
        $titleCap = $Game.Title
        $steamBtn.Add_MouseLeftButtonUp({
            # Mark this click so that when the user comes back to
            # the Hub, we know to refresh state for this one game
            # (they may have just bought/installed via Steam).
            # Title is stashed alongside the timestamp so the
            # Activated handler can scope a single-game refresh
            # rather than forcing a full scan the user didn't ask
            # for - same scope-respecting pattern as post-install.
            $global:LastSteamButtonClickAt    = [DateTime]::UtcNow
            $global:LastSteamButtonClickTitle = $titleCap
            Start-Process "steam://store/$sIdCap"
        }.GetNewClosure())
        Add-SweepHover -Border $steamBtn
        $btnRow.Children.Add($steamBtn) | Out-Null
    }
}

function global:Hide-DiscoverDetail {
    # Repaint the filter pills back to the real list/Explore filter state
    # (the detail page had marked them with the game's attributes).
    if (Get-Command Restore-FilterPills -ErrorAction SilentlyContinue) {
        try { Restore-FilterPills } catch { }
    }
    if (Get-Command Request-HeaderBackArrowUpdate -ErrorAction SilentlyContinue) { Request-HeaderBackArrowUpdate }
    if ($global:HoverMediaElement) {
        try { $global:HoverMediaElement.Stop()  } catch { }
        try { $global:HoverMediaElement.Close() } catch { }
        $global:HoverMediaElement.Source = $null
        $global:HoverMediaElement = $null
    }
    $global:DetailDescTxt = $null
    $global:DetailReadmeTextBlocks = $null
    $global:DetailWidthBlocks = $null
    $global:discoverDetailHost.Children.Clear()
    $global:discoverDetail.Visibility = [System.Windows.Visibility]::Collapsed
    # Safety sweep: finalize any click-pulse glow still in flight (or
    # stuck) on a card. Cards are built once and reused, and an Effect
    # left on a card Border rasterizes its title into the washed-out,
    # ClearType-less look. This back-from-detail path flips visibility
    # directly (it does not route through Show-DiscoverOverview), so the
    # sweep must happen here too - this is the primary way users return
    # to the grid.
    if ($global:cardGameMap -and (Get-Command Resolve-CardClickGlow -ErrorAction SilentlyContinue)) {
        foreach ($c in @($global:cardGameMap.Keys)) { Resolve-CardClickGlow -Card $c }
    }
    # Return to whichever view spawned the detail page.
    if ($global:DetailOrigin -eq "OVERVIEW" -and $global:discoverOverview) {
        $global:discoverOverview.Visibility = [System.Windows.Visibility]::Visible
        $global:discoverTiles.Visibility    = [System.Windows.Visibility]::Collapsed
    } elseif ($global:DetailOrigin -eq "LIST") {
        # From the list-view banner Show button -> back to list.
        $global:discoverHost.Visibility = [System.Windows.Visibility]::Collapsed
        if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Visible }
        if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
        if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
    } else {
        $global:discoverTiles.Visibility = [System.Windows.Visibility]::Visible
    }
    $global:DetailOrigin = $null
    $global:currentDetailGame = $null
    if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
}

function global:Build-DiscoverTiles {
    if ($global:DiscoverTilesBuilt) { return }
    $allGames = @()
    $allGames += $ownGames
    $allGames += $ownGamesGP
    $allGames += $externalGames

    # Reorder by play history: surface the 5 most-recent launches
    # at the top of the Discover page so the user lands on what
    # they actually play. Read once at build time - DiscoverTilesBuilt
    # caches the result for the session. Next Hub start picks up
    # any new launches.
    try {
        $history = Get-HubSetting -Key "playHistory" -Default @()
        if ($history -and $history.Count -gt 0) {
            $recentTitles = @()
            $cnt = 0
            foreach ($title in $history) {
                if ($cnt -ge 5) { break }
                if ($recentTitles -notcontains $title) {
                    $recentTitles += $title
                    $cnt++
                }
            }
            if ($recentTitles.Count -gt 0) {
                # Build lookup of catalog by title.
                $byTitle = @{}
                foreach ($g in $allGames) {
                    if ($g.Title) { $byTitle[$g.Title] = $g }
                }
                # Front: recent games (in history order, most recent first).
                # Back: everything else in original catalog order.
                $front = @()
                foreach ($t in $recentTitles) {
                    if ($byTitle.ContainsKey($t)) { $front += $byTitle[$t] }
                }
                $frontTitles = @($front | ForEach-Object { $_.Title })
                $back = @()
                foreach ($g in $allGames) {
                    if ($frontTitles -notcontains $g.Title) { $back += $g }
                }
                $allGames = @($front + $back)
            }
        }
    } catch { }

    foreach ($g in $allGames) {
        $tile = New-DiscoverTile -Game $g
        $global:discoverPanel.Children.Add($tile) | Out-Null
    }
    $global:DiscoverTilesBuilt = $true
}

function global:Refresh-DiscoverStatuses {
    foreach ($tile in $global:discoverPanel.Children) {
        Update-DiscoverTileStatus -Tile $tile
    }
}

