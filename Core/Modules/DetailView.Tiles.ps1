# Subtle scale-up on hover for non-clickable elements (hero
# banner, description images, info pills). RenderTransform = no
# layout shift, no clipping issues. Origin centered.
# ------------------------------------------------------------
#  Start-GameProcess
# ------------------------------------------------------------
#  A single place for "open the game/launcher". The reason this
#  function exists is ONE catalog field: LaunchAsAdmin.
#
#  WHY IT BECAME NECESSARY (2026-08-19, found via World War VR):
#  RyanCraighead states plainly in his README that his launcher must
#  run AS ADMINISTRATOR. "Start in VR" used to start it normally -
#  without the rights to inspect the game files under Program Files.
#  His error message is then "The game executables are from an
#  unsupported build", which looks like a broken game and is not one.
#
#  Only entries WITH the field are elevated - nothing changes for the
#  others. If the user cancels the UAC prompt, it is NOT started
#  unelevated as a substitute: that would be exactly the run that
#  produces the misleading message.
# ------------------------------------------------------------
function global:Start-GameProcess {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string]$Arguments = "",
        [string]$WorkingDirectory = "",
        $Game = $null
    )
    $sp = @{ FilePath = $FilePath }
    if ($Arguments)        { $sp["ArgumentList"] = $Arguments }
    if ($WorkingDirectory) { $sp["WorkingDirectory"] = $WorkingDirectory }
    if ($Game -and $Game.LaunchAsAdmin) { $sp["Verb"] = "RunAs" }
    Start-Process @sp
}

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

# Decode Steam portrait art close to the largest on-screen Library tile size
# instead of keeping every 600x900 source fully decoded. At 250+ games this
# removes hundreds of megabytes of bitmap pressure. The DPI-aware cap retains
# full sharpness on scaled displays and never upscales beyond Steam's source.
function global:Get-LibraryPortraitDecodeWidth {
    if ($global:LibraryPortraitDecodeWidth) { return [int]$global:LibraryPortraitDecodeWidth }
    $w = 320
    try {
        $dpi = [System.Windows.Media.VisualTreeHelper]::GetDpi($global:window)
        $w = [int][Math]::Ceiling(285.0 * $dpi.DpiScaleX)
    } catch { }
    if ($w -lt 320) { $w = 320 }
    if ($w -gt 600) { $w = 600 }
    $global:LibraryPortraitDecodeWidth = $w
    return $w
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
    $portraitDecodeWidth = Get-LibraryPortraitDecodeWidth
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
        # Linear filtering is sufficient because the bitmap is decoded almost
        # exactly at its physical display width. It is substantially cheaper
        # than Fant resampling while the portrait grid is moving.
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode(
            $img,
            [System.Windows.Media.BitmapScalingMode]::LowQuality
        )
        try {
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $bmpUri = New-Object System.Uri $portraitUrl
            $bmp.UriSource = $bmpUri
            $bmp.DecodePixelWidth = $portraitDecodeWidth
            $bmp.CacheOption = if ($bmpUri.IsFile) {
                [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            } else {
                [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand
            }
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
                        $hb.DecodePixelWidth = $portraitDecodeWidth
                        $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand
                        $hb.EndInit()
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
                        $hbUri = New-Object System.Uri $hdrCap
                        $hb.UriSource = $hbUri
                        $hb.DecodePixelWidth = $portraitDecodeWidth
                        $hb.CacheOption = if ($hbUri.IsFile) {
                            [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                        } else {
                            [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand
                        }
                        $hb.EndInit()
                        if ($hbUri.IsFile -and $hb.CanFreeze) { $hb.Freeze() }
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
                        $hb.DecodePixelWidth = $portraitDecodeWidth
                        $hb.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand
                        $hb.EndInit()
                        $imgRef.Source = $hb
                        $imgRef.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                    } catch { }
                }
            }.GetNewClosure())
            $bmp.EndInit()
            if ($bmpUri.IsFile -and $bmp.CanFreeze) { $bmp.Freeze() }
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
        "VRGP" { "GAMEPAD" }
        "BOTH" { "BOTH" }
        default { "" }
    }
    $ctrlPillBgHex = switch ($Game.Controls) {
        "MC"   { "#44cc66" }
        "GP"   { "#dd6600" }
        "VRGP" { "#dd6600" }
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
    # Small, static text shadow: cache once so scrolling only moves it.
    $titleTxt.CacheMode = New-Object System.Windows.Media.BitmapCache
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
        $freePillPt.CacheMode = New-Object System.Windows.Media.BitmapCache
        $freeTxtPt = New-Object System.Windows.Controls.TextBlock
        $freeTxtPt.Text = "FREE"
        $freeTxtPt.FontSize = 9
        $freeTxtPt.FontWeight = [System.Windows.FontWeights]::Bold
        $freeTxtPt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freeTxtPt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $freePillPt.Child = $freeTxtPt
        $grid.Children.Add($freePillPt) | Out-Null
    }

    # The portrait/Steam-style Library needs the same quality fact as the
    # regular game cards. Bottom-right is deliberately reserved for this
    # marker: FREE occupies top-left, install status top-right, controls and
    # title stay bottom-left. Reuse the shared faceted marker so its shape,
    # accessible name and tooltip cannot drift between the two views.
    if ($Game.Gem) {
        $libraryGem = New-GemMarker -Scale 1.0 -Preview
        $libraryGem.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $libraryGem.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
        $libraryGem.Margin = [System.Windows.Thickness]::new(0, 0, 10, 10)
        $libraryGem.ToolTip = 'Polished Gem'
        [System.Windows.Controls.Panel]::SetZIndex($libraryGem, 12)
        $grid.Children.Add($libraryGem) | Out-Null
        $tile.Resources.Add('libraryGem', $libraryGem)
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
    # created up front but attached only during hover/click. An Effect with
    # Opacity=0 still makes WPF rasterize the full tile-sized frame, so leaving
    # it attached to every idle tile is a major scrolling cost.
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
        if ($gfcap -and $gcap) { $gfcap.Effect = $gcap; $gcap.Opacity = 0.95 }
        $resetT = New-Object System.Windows.Threading.DispatcherTimer
        $resetT.Interval = [TimeSpan]::FromMilliseconds(2600)
        $resetT.Add_Tick({
            $this.Stop()
            $fcap.Opacity = 0
            $tileCap.Tag = $null
            $tileCap.RenderTransform = $null
            if ($gfcap) { $gfcap.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a32") }
            if ($gcap) { $gcap.Opacity = 0 }
            if ($gfcap) { $gfcap.Effect = $null }
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
        if ($gf -and $g) { $gf.Effect = $g; $g.Opacity = 0.95 }
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
        if ($gf) { $gf.Effect = $null }
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
