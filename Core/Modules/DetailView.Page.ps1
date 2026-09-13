function global:Show-DiscoverDetail {
    param($Game)
    $detailBuildWatch = [System.Diagnostics.Stopwatch]::StartNew()
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
    $global:DetailUninstallGuide = $null
    $global:DetailReadmeLinkSessions = New-Object 'System.Collections.Generic.List[object]'
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

    # Back button - outline only (no fill), matching the Explore page's
    # back button and the rating buttons: transparent background, light
    # border, orange border on hover. Transparent (not $null) so the
    # whole area stays hit-testable.
    $backBtn = New-Object System.Windows.Controls.Border
    $backBtn.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $backBtn.Background = [System.Windows.Media.Brushes]::Transparent
    $backBtn.BorderThickness = [System.Windows.Thickness]::new(1)
    $backBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
    $backBtn.Padding = [System.Windows.Thickness]::new(14, 9, 18, 9)
    $backBtn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $backBtn.Margin = [System.Windows.Thickness]::new(0, 0, 0, 16)
    $backBtn.Cursor = [System.Windows.Input.Cursors]::Hand

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
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
        $stack = $this.Child
        if ($stack -and $stack.Children.Count -ge 2) {
            $stack.Children[0].Stroke = [System.Windows.Media.Brushes]::White
            $stack.Children[1].Foreground = [System.Windows.Media.Brushes]::White
        }
    })
    $backBtn.Add_MouseLeave({
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

    # Register the hero border under a stable name so the shared banner
    # effect system (Add-BannerEffect, which resolves its target via
    # $global:window.FindName) can attach an animated layer to it. Used
    # by the wide-monitor centered layout below.
    # Each detail view rebuilds this hero, so a prior view likely left
    # these names registered against now-discarded elements. Clear them
    # first (the hero itself no longer needs a name, but the two side-
    # band effect panels below do). Guarded: if the window has no
    # NameScope the effect just won't attach and the layout still works.
    $heroFxName = "DetailHeroBanner"
    foreach ($nm in @($heroFxName, "DetailHeroBandLeft", "DetailHeroBandRight")) {
        if (Get-Command Stop-BannerNetTimer -ErrorAction SilentlyContinue) {
            try { Stop-BannerNetTimer -BannerName $nm } catch { }
        }
        try { $global:window.UnregisterName($nm) } catch {}
    }

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

        # --- Wide-monitor centered layout -----------------------------
        # On a wide window the hero is much wider than a 460x215 Steam
        # header's aspect ratio. UniformToFill then scales the image to
        # the WIDTH and crops most of the height away - you see only a
        # thin horizontal sliver. Fix: past a threshold width, stop
        # filling. Instead cap the image at a fixed width, center it, and
        # switch to Uniform so the WHOLE header shows. The exposed side
        # bands then reveal the animated banner effect + accent edges
        # sitting behind it. Below the threshold nothing changes: the
        # image full-bleeds as before.
        #
        # 465 is the header's native width; the hero is 360 tall. Past
        # the threshold we DON'T shrink the image - we FREEZE it at the
        # exact size it had just before the switch: width = threshold,
        # height = 360, still UniformToFill so the crop looks identical.
        # It just stops growing wider and centers, and the accent/effect
        # bands fill the gap on either side. No size jump at the switch.
        $heroThreshold = 1040.0  # hero width past which we freeze + center
        $heroImgRef2   = $heroImg
        $heroRef2      = $hero
        $accentHexRef  = $accentHex
        $heroGameRef   = $Game
        $script:__heroFxApplied = $false
        $script:__heroBandL = $null
        $script:__heroBandR = $null
        $heroApplyLayout = {
            param($hw)
            try {
                if ($hw -ge $heroThreshold) {
                    # Frozen-crop, centered mode. Keep UniformToFill (same
                    # crop as before the switch) and cap the width at the
                    # threshold so the image is exactly the size it was the
                    # instant before we switched - no shrink, no jump.
                    $heroImgRef2.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                    $heroImgRef2.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
                    $heroImgRef2.MaxWidth = $heroThreshold
                    # Once the bands exist, keep their width in sync as the
                    # window grows wider (each band = half the exposed gap).
                    if ($script:__heroBandL -and $script:__heroBandR) {
                        $bw = [Math]::Max(80.0, ($hw - $heroThreshold) / 2.0)
                        $script:__heroBandL.Width = $bw
                        $script:__heroBandR.Width = $bw
                    }
                    # Accent edges: a horizontal gradient that is accent-
                    # tinted at both rims and transparent across the
                    # middle, so it frames the centered image without
                    # touching it. Rebuilt each time in case the accent
                    # differs per game.
                    try {
                        $edge = New-Object System.Windows.Media.LinearGradientBrush
                        $edge.StartPoint = [System.Windows.Point]::new(0, 0.5)
                        $edge.EndPoint   = [System.Windows.Point]::new(1, 0.5)
                        $acc = [System.Windows.Media.ColorConverter]::ConvertFromString($accentHexRef)
                        $accSoft = [System.Windows.Media.Color]::FromArgb(150, $acc.R, $acc.G, $acc.B)
                        $accNone = [System.Windows.Media.Color]::FromArgb(0,   $acc.R, $acc.G, $acc.B)
                        $edge.GradientStops.Add((New-Object System.Windows.Media.GradientStop $accSoft, 0.0))  | Out-Null
                        $edge.GradientStops.Add((New-Object System.Windows.Media.GradientStop $accNone, 0.22)) | Out-Null
                        $edge.GradientStops.Add((New-Object System.Windows.Media.GradientStop $accNone, 0.78)) | Out-Null
                        $edge.GradientStops.Add((New-Object System.Windows.Media.GradientStop $accSoft, 1.0))  | Out-Null
                        if ($edge.CanFreeze) { $edge.Freeze() }
                        $heroRef2.Background = $edge
                    } catch {}
                    # Animated effect in the side bands. The banner effects
                    # scatter their elements across a wide (~2600px) field,
                    # so a single full-width layer barely populates the two
                    # narrow rims we can actually see. Instead give each rim
                    # its OWN effect panel, sized to the band, and fill both
                    # with the SAME random effect - guaranteed, matching
                    # left+right coverage. Done once.
                    if (-not $script:__heroFxApplied) {
                        try {
                            if ((Get-Command Get-BannerFxFor -ErrorAction SilentlyContinue) -and
                                (Get-Command Set-BannerEffect -ErrorAction SilentlyContinue)) {
                                $fx = Get-BannerFxFor -Game $heroGameRef
                                $hg = $heroRef2.Child
                                if ($hg -is [System.Windows.Controls.Grid]) {
                                    # Width of each visible side band = half
                                    # of (hero width - frozen image width).
                                    # The frozen image is $heroThreshold wide;
                                    # clamp so a slightly-over width still
                                    # gives a sane band.
                                    $bandW = [Math]::Max(80.0, ($hw - $heroThreshold) / 2.0)
                                    foreach ($side in @("Left","Right")) {
                                        $bandName = "DetailHeroBand$side"
                                        $band = New-Object System.Windows.Controls.Border
                                        $band.Width  = $bandW
                                        $band.Height = 360
                                        $band.ClipToBounds = $true
                                        $band.IsHitTestVisible = $false
                                        $band.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
                                        $band.HorizontalAlignment = if ($side -eq "Left") {
                                            [System.Windows.HorizontalAlignment]::Left
                                        } else {
                                            [System.Windows.HorizontalAlignment]::Right
                                        }
                                        # Each band needs a Grid child for the
                                        # effect system to attach to.
                                        $bandGrid = New-Object System.Windows.Controls.Grid
                                        $band.Child = $bandGrid
                                        # Behind the image (ZIndex 0); image is
                                        # bumped to 5 below.
                                        [System.Windows.Controls.Panel]::SetZIndex($band, 0)
                                        [void]$hg.Children.Add($band)
                                        if ($side -eq "Left") { $script:__heroBandL = $band } else { $script:__heroBandR = $band }
                                        try { $global:window.UnregisterName($bandName) } catch {}
                                        try { $global:window.RegisterName($bandName, $band) } catch {}
                                        Set-BannerEffect -BannerName $bandName -BannerH 360 -ColorHex $accentHexRef -Effect $fx
                                    }
                                }
                                # Keep the header image above the bands.
                                [System.Windows.Controls.Panel]::SetZIndex($heroImgRef2, 5)
                                $script:__heroFxApplied = $true
                            }
                        } catch {}
                    }
                } else {
                    # Narrow: original full-bleed behavior.
                    $heroImgRef2.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                    $heroImgRef2.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
                    $heroImgRef2.MaxWidth = [double]::PositiveInfinity
                }
            } catch {}
        }.GetNewClosure()
        # Re-evaluate whenever the hero is resized (window resize / maximize).
        $hero.Add_SizeChanged({ param($s,$e) & $heroApplyLayout $e.NewSize.Width }.GetNewClosure())
        # Apply once on load too, in case the initial width is already wide.
        $hero.Add_Loaded({ param($s,$e) & $heroApplyLayout $s.ActualWidth }.GetNewClosure())
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
            $heroUri = New-Object System.Uri $heroUrl
            $bmp.UriSource = $heroUri
            $bmp.CacheOption = if ($heroUri.IsFile) {
                [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            } else {
                [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand
            }
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
                        $hbUri = New-Object System.Uri (Get-SteamHeaderUrlFastly $sidCap)
                        $hb.UriSource = $hbUri
                        $hb.CacheOption = if ($hbUri.IsFile) { [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad } else { [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand }
                        $hb.EndInit()
                        if ($hbUri.IsFile -and $hb.CanFreeze) { $hb.Freeze() }
                        $imgRefH.Source = $hb
                        return
                    } catch { }
                }
                # Then fall back to portrait
                if ($portraitUrlCap) {
                    try {
                        $hb = New-Object System.Windows.Media.Imaging.BitmapImage
                        $hb.BeginInit()
                        $hbUri = New-Object System.Uri $portraitUrlCap
                        $hb.UriSource = $hbUri
                        $hb.CacheOption = if ($hbUri.IsFile) { [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad } else { [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand }
                        $hb.EndInit()
                        if ($hbUri.IsFile -and $hb.CanFreeze) { $hb.Freeze() }
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
                    $hbUri = New-Object System.Uri $heroUrlCap
                    $hb.UriSource = $hbUri
                    $hb.CacheOption = if ($hbUri.IsFile) { [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad } else { [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand }
                    $hb.EndInit()
                    if ($hbUri.IsFile -and $hb.CanFreeze) { $hb.Freeze() }
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
            if ($heroUri.IsFile -and $bmp.CanFreeze) { $bmp.Freeze() }
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
        "VRGP" { "VR Controller = Gamepad" }
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

    # VR READY pill - the FIRST badge after the title, before every
    # other pill. Until now "VR Ready" existed ONLY as the resting
    # label of the action button, and that button swapped to
    # "Start in VR" on hover - so the ready state was invisible the
    # moment the cursor touched it, and the start affordance was
    # invisible until then. The state now lives here permanently and
    # the button below is always the start button.
    # Deliberately louder than the INSTALLED / FREE pills: rounded,
    # a filled dot, a brighter border and a soft green glow. It is a
    # STATE, not a category, and has to read as one at a glance.
    $vrReadyState = $global:gameStateMap[$Game.Title]
    if ($vrReadyState -and $vrReadyState.State -eq "ready") {
        $vrPill = New-Object System.Windows.Controls.Border
        $vrPill.CornerRadius = [System.Windows.CornerRadius]::new(11)
        $vrPill.Padding = [System.Windows.Thickness]::new(10, 3, 11, 3)
        $vrPill.Margin = [System.Windows.Thickness]::new(10, 4, 0, 0)
        $vrPill.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        # No fill: the hero banner behind the title row is animated and
        # a tinted pill muddies the text on it. Border + glow carry the
        # pill on their own.
        $vrPill.Background = [System.Windows.Media.Brushes]::Transparent
        $vrPill.BorderThickness = [System.Windows.Thickness]::new(1)
        $vrPill.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ade9f")
        try {
            $vrGlow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $vrGlow.Color = [System.Windows.Media.ColorConverter]::ConvertFromString("#34d399")
            $vrGlow.BlurRadius = 12; $vrGlow.ShadowDepth = 0; $vrGlow.Opacity = 0.55
            $vrPill.Effect = $vrGlow
        } catch {}
        $vrPillStack = New-Object System.Windows.Controls.StackPanel
        $vrPillStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        # Dot as a Unicode code point, not a literal character - the
        # whole tree is ASCII only.
        $vrDot = New-Object System.Windows.Controls.TextBlock
        $vrDot.Text = "$([char]0x25CF)"
        $vrDot.FontSize = 8
        $vrDot.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7df3bd")
        $vrDot.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $vrDot.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
        [void]$vrPillStack.Children.Add($vrDot)
        $vrTxt = New-Object System.Windows.Controls.TextBlock
        $vrTxt.Text = "VR READY"
        $vrTxt.FontSize = 10
        $vrTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $vrTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7df3bd")
        $vrTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $vrTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        [void]$vrPillStack.Children.Add($vrTxt)
        $vrPill.Child = $vrPillStack
        $titleRow.Children.Add($vrPill) | Out-Null
        Add-HoverScale -Element $vrPill -Scale 1.08
    }
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

    # Roomscale pill: catalog-flagged titles whose VR mod supports
    # room-scale play. Same accent-tinted badge style as the controls
    # pill. Also searchable via the "roomscale" keyword (Filter.ps1).
    if ($Game.Roomscale) {
        $rsPill = New-Object System.Windows.Controls.Border
        $rsPill.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $rsPill.Padding = [System.Windows.Thickness]::new(8, 3, 8, 3)
        $rsPill.Margin = [System.Windows.Thickness]::new(8, 4, 0, 0)
        $rsPill.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $rsBg = [System.Windows.Media.Color]::FromRgb(
            [byte]([Math]::Round($famAcc.R*0.18 + 22*0.82)),
            [byte]([Math]::Round($famAcc.G*0.18 + 22*0.82)),
            [byte]([Math]::Round($famAcc.B*0.18 + 26*0.82))
        )
        $rsPill.Background = New-Object System.Windows.Media.SolidColorBrush $rsBg
        $rsTxt = New-Object System.Windows.Controls.TextBlock
        $rsTxt.Text = "ROOMSCALE"
        $rsTxt.FontSize = 10
        $rsTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $rsTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(
            [byte]([Math]::Round($famAcc.R*0.5 + 255*0.5)),
            [byte]([Math]::Round($famAcc.G*0.5 + 255*0.5)),
            [byte]([Math]::Round($famAcc.B*0.5 + 255*0.5))
        ))
        $rsTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $rsPill.Child = $rsTxt
        $titleRow.Children.Add($rsPill) | Out-Null
        Add-HoverScale -Element $rsPill -Scale 1.08
    }

    # Game-installed pill: surfaces "yes the user actually owns and
    # has installed this game on disk" when the on-disk scan picked
    # it up. Sits between the controls pill and any auto-update
    # pill so it reads as a peer status badge. Green palette to
    # match the same green used by the VR Ready button later.
    # Pill is hidden on first load (before the user runs "Check
    # Installed") - we only show it once we have positive evidence.
    $detectState = $global:gameStateMap[$Game.Title]
    # Standalone free games have no separate base-game installation to report.
    # FreeBaseGame entries (Muck and Daggerfall) do, so their positive base-game
    # detection uses the same INSTALLED pill as a paid game.
    $isFreeGameDV = ($global:FREE_GAME_TITLES -and ($global:FREE_GAME_TITLES -contains $Game.Title))
    $isFreeBaseGameDV = ($isFreeGameDV -and [bool]$Game.FreeBaseGame)
    $instPillTags = if ($isFreeGameDV -and -not $isFreeBaseGameDV) { @("vrinstalled", "vrupdate") } else { @("installed", "vrinstalled", "vrupdate") }
    # VR READY already implies the game is on disk, so the INSTALLED
    # pill next to it would say the same thing twice. It only shows
    # when the game is there WITHOUT the VR mod being ready.
    $instPillHidden = ($detectState -and $detectState.State -eq "ready")
    if ($detectState -and ($detectState.Tag -in $instPillTags) -and -not $instPillHidden) {
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
    } elseif ($Game.Author -and $Game.Author -match '(?i)\(auto[- ]updates?\)') {
        # Some entries (e.g. Alien: Isolation) carry the marker in Author
        # instead of Mod, because the tile shows it on the author line for
        # space reasons. Honour it here too so the pill is consistent.
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
            # The catalog stores a leading "(auto-updates)" marker in Author so
            # the TILE can show it on its own line (space-constrained there).
            # On the detail page that marker does not belong in "Created by" -
            # strip it here and show only the real modder name(s). The mod
            # value already carries the auto-update meaning, and the entry also
            # has an "auto-updates" search tag.
            $authClean = $Game.Author
            if ($authClean -match '^\s*\(auto-updates?\)\s*(.*)$') { $authClean = $matches[1] }
            $authVal.Text = $authClean
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
                    # Standalone free games have no base-game install to report.
                    # FreeBaseGame entries retain the explicit installed status.
                    if ($isFreeGameDV -and -not $isFreeBaseGameDV) {
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

    # Elden Ring's current and pinned builds share one save location. Keep
    # the choice visible and actionable beside the page's main controls,
    # instead of burying a non-clickable filename in the README.
    if ($Game.SaveBuildSwitch) {
        try {
            $saveBuildControl = New-EldenRingSaveBuildControl -Game $Game -AccentHex $accentHex
            $saveBuildControl.Margin = [System.Windows.Thickness]::new(0, -8, 0, 18)
            $stack.Children.Add($saveBuildControl) | Out-Null
        } catch {}
    }
    if ($Game.EldenRingSettingsTools) {
        try {
            $eldenSettings = New-EldenRingSettingsControl -Game $Game
            $eldenSettings.Margin = [System.Windows.Thickness]::new(0, -10, 0, 18)
            $stack.Children.Add($eldenSettings) | Out-Null
        } catch {}
    }

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
        "Black Mesa Source VR" = "Black Mesa Source VR is a fan-made reimagining of the original Half-Life, rebuilt as a Half-Life 2: Episode Two mod and now playable in VR."
        "SiN Episodes: Emergence" = "SiN Episodes: Emergence is a story-driven first-person shooter set in Freeport. As HardCorps commander John Blade, battle Elexis Sinclaire's forces through city streets, laboratories and industrial complexes using fast gunplay, interactive environments and vehicles."
        "Silent Hill 3 VR" = "Silent Hill 3 follows Heather Mason as an ordinary trip through a shopping mall turns into a nightmare tied to the cult and events of Silent Hill. Explore oppressive environments, solve puzzles and fight grotesque creatures while uncovering why Heather is being drawn into the town's history."
        "Silent Hill VR" = "Silent Hill (1999) is a psychological survival horror game in which Harry Mason searches for his missing daughter in the fog-covered town of Silent Hill. Explore unsettling locations, solve puzzles, and survive terrifying creatures while uncovering the town's dark secrets."
        "F.E.A.R. VR" = "F.E.A.R. is a supernatural first-person shooter that combines intense gunfights, slow-motion combat, and psychological horror. As a member of an elite response unit, you investigate a mysterious military force connected to the unsettling psychic child Alma."
        "Mario Kart 64 VR" = "Experience the classic kart racing action of Mario Kart 64 in immersive VR. Race through iconic tracks with full 6DOF head tracking, bringing the world to life from inside the driver's seat. Built on SpaghettiKart, the Mario Kart 64 PC port - you bring your own US ROM, and nothing from Nintendo is included."
        "Legend of Zelda: Ocarina of Time VR" = "The Legend of Zelda: Ocarina of Time is a groundbreaking action-adventure game originally released for the Nintendo 64 in 1998. According to Metacritic, it is considered one of the best video games of all time. Shipwright-VR brings its 3D world into the headset via an OpenVR renderer for the Ship of Harkinian PC port, with motion-controller input."
        "Legend of Zelda: Twilight Princess" = "The Legend of Zelda: Twilight Princess is an action-adventure game in which Link must save Hyrule from the encroaching Twilight Realm. Explore vast environments, solve intricate dungeons, battle dangerous enemies, and transform into a wolf to uncover secrets. Dusklight VR brings the GameCube adventure into virtual reality with stereoscopic rendering and tracked motion controls."
        "Ring Racers VR" = "Dr. Robotnik's Ring Racers is a fast-paced kart racing game featuring dozens of characters, tracks, items, and advanced movement mechanics. Thanks to the new OpenXR port, the chaotic races can now be experienced in immersive PCVR."
        "Sonic Robo Blast 2 VR" = "Sonic Robo Blast 2 is a long-running fan-made 3D platformer inspired by the classic Sonic games, featuring fast-paced gameplay, exploration - now with OpenXR support."
        "Hytale VR" = "Hytale is a block-based sandbox RPG that combines exploration, combat, crafting and building in a large fantasy world. Explore dangerous dungeons, fight creatures, create your own adventures and shape the world however you like. This entry adds an experimental SteamVR injector by heurazy with native motion-controlled hands, driven by an external camera dashboard."
        "Star Fox 64 VR" = "Star Fox 64 VR is a full PCVR port of the N64 classic, built on the Starship PC port with an OpenXR layer on top. Put on a headset and you are flying the Arwing for real - the scene renders once per eye with full head tracking, and the motion controllers drive flight, menus and everything else. No headset connected? The same exe runs as the normal flat game. You bring your own Star Fox 64 US ROM dump."
        "Super Mario 64 VR" = "sm64coopdx VR brings Super Mario 64 to immersive virtual reality, built on the sm64coopdx PC port. Look and lean naturally into the world with a VR headset. You bring your own Super Mario 64 US ROM - nothing from Nintendo is included, and the ROM never leaves your machine."
        "F-Zero X VR" = "F-Zero X is a high-speed futuristic racing game where players compete in anti-gravity machines across extreme tracks filled with sharp turns, jumps, and hazards. Featuring up to 30 racers at once, it focuses on intense speed, aggressive competition, and mastering each vehicle's unique handling. This VR build renders it in real stereo with 6DoF head tracking, on top of G-Diffuser, Zorkats' native PC port - you bring your own US Rev 0 ROM."
        "Diddy Kong Racing VR" = "Diddy Kong Racing is a colorful kart racing adventure where players explore a hub world, compete in races, and take on special challenges and boss battles. Unlike traditional kart racers, it features three different vehicle types - cars, hovercrafts, and planes - each offering a distinct way to race across its varied tracks. This VR build renders the whole game inside the headset with full head tracking, on top of Golden Balloon, akratch's PC port - you bring your own US 1.1 or EU 1.1 ROM."
        "Banjo-Kazooie VR" = "Banjo the bear and Kazooie the bird explore interconnected worlds to rescue Banjo's sister from the witch Gruntilda. The game combines platforming, exploration, puzzles, collectibles, and a wide range of abilities unlocked throughout the adventure. This VR build renders the whole game per eye with head tracking, on top of Lighthouse, the Harbour Masters PC port - you bring your own US ROM."
        "Pokemon Gen 1 VR" = "Pokemon Gen 1 Recomp Voxel VR brings the classic first-generation adventure into a fully explorable voxel-based 3D world. Travel across Kanto, catch and battle Pokemon, and experience the familiar journey from an immersive first-person VR perspective."
        "Blood VR" = "Blood: One Unit Whole Blood is the complete DOS release of Monolith's cult horror shooter, including the Plasma Pak and Cryptic Passage expansion. RazeXR brings Caleb's campaign into PCVR with tracked motion controls and controller-held voxel weapons."
        "NAM VR" = "NAM is a Build-engine Vietnam War shooter created with input from Vietnam veterans. RazeXR brings its campaign into PCVR with tracked motion controls and controller-held voxel weapons; the related NAPALM release can be imported separately."
        "Battlefield 1942 VR" = "Battlefield 1942 is a classic World War II first-person shooter that lets you fight across large battlefields as infantry or take control of tanks, aircraft, ships, and other vehicles."
        "Virtua Cop 2 VR" = "Virtua Cop 2 is a fast-paced arcade light-gun shooter where players take down criminals across a series of action-packed stages. It features branching routes, boss battles, and quick target-based gameplay built around accuracy, reaction speed, and avoiding civilian casualties."
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
    $steamDescPending = $false
    if ($customDescriptions.ContainsKey($Game.Title)) {
        $steamDesc = $customDescriptions[$Game.Title]
        if ($toolInfoTitles -contains $Game.Title) { $infoHeading = "Tool Info" }
    } else {
        $steamDesc = Get-SteamShortDescription -SteamId $Game.SteamId
        if (-not $steamDesc -and $Game.SteamId -and -not $global:SteamDescCache.ContainsKey([string]$Game.SteamId)) {
            # Keep the Game Info layout stable and useful while the targeted
            # Steam request runs in the background. It replaces this text on
            # completion; no network operation blocks the page-opening click.
            $steamDesc = "Loading the Steam game description in the background. The mod guide and controls below are ready now."
            $steamDescPending = $true
        }
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
            if ($Game.NoticeUrl -or $Game.NoticeGameTitle) {
                $noticeLink = New-Object System.Windows.Controls.TextBlock
                # The label is free to set (NoticeUrlLabel). Without one
                # the old text stays - the two existing entries (Metal
                # Hellsinger, Trombone Champ) point at an official VR
                # edition in the Steam store.
                $noticeLink.Text = if ($Game.NoticeUrlLabel) { [string]$Game.NoticeUrlLabel } else { "Open the official VR version on Steam" }
                $noticeLink.FontSize = 13
                $noticeLink.FontWeight = [System.Windows.FontWeights]::SemiBold
                $noticeLink.TextDecorations = [System.Windows.TextDecorations]::Underline
                $noticeLink.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(240, 184, 72))
                $noticeLink.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $noticeLink.Cursor = [System.Windows.Input.Cursors]::Hand
                $noticeLink.Margin = [System.Windows.Thickness]::new(0, 6, 0, 0)
                if ($Game.NoticeGameTitle) {
                    $noticeLink.Tag = [pscustomobject]@{ Kind='Game'; Value=[string]$Game.NoticeGameTitle }
                } else {
                    $noticeLink.Tag = [pscustomobject]@{ Kind='Url'; Value=[string]$Game.NoticeUrl }
                }
                $noticeLink.Add_MouseLeftButtonUp({
                    param($s, $e)
                    try {
                        if ($s.Tag.Kind -eq 'Game') {
                            $targetGame = $null
                            if ($global:CatalogGameByTitle -and $global:CatalogGameByTitle.ContainsKey([string]$s.Tag.Value)) { $targetGame = $global:CatalogGameByTitle[[string]$s.Tag.Value] }
                            if (-not $targetGame) { $targetGame = @(@($global:ownGames) + @($global:ownGamesGP) + @($global:externalGames) | Where-Object Title -eq ([string]$s.Tag.Value) | Select-Object -First 1)[0] }
                            if ($targetGame) { Show-DiscoverDetail -Game $targetGame }
                        } else { Start-Process ([string]$s.Tag.Value) }
                    } catch {}
                })
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
        if ($steamDescPending) {
            $pendingDescTxt = $descTxt
            $pendingTitle = [string]$Game.Title
            $steamInfoReady = {
                param($loadedDescription, $loadedScreenshot, $failed)
                if (-not $global:currentDetailGame -or [string]$global:currentDetailGame.Title -ne $pendingTitle) { return }
                if ($loadedDescription) {
                    $pendingDescTxt.Text = [string]$loadedDescription
                } elseif ($failed) {
                    $pendingDescTxt.Text = "Steam game details are temporarily unavailable. The complete mod guide below remains ready to use."
                } else {
                    $pendingDescTxt.Text = "Steam has no game description for this title. The complete mod guide below remains ready to use."
                }
            }.GetNewClosure()
            Start-SteamDetailInfoFetch -SteamId ([string]$Game.SteamId) -Completed $steamInfoReady
        }

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
                if (Test-Path $shotAbs) { $shotUrl = ConvertTo-HubFileUri -Path $shotAbs }
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
                # Preserve the complete source image in its own aspect ratio.
                # Never impose Height/MaxHeight here: UniformToFill would then
                # crop square or portrait artwork to the artificial viewport.
                $shotImg = New-Object System.Windows.Controls.Image
                # Steam screenshots are 16:9; UniformToFill keeps
                # the aspect while filling the available width.
                # WPF auto-scales the bitmap to the container size,
                # so the source image dimensions don't matter.
                $shotImg.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                try {
                    $sbmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $sbmp.BeginInit()
                    $shotUri = New-Object System.Uri $shotUrl
                    $sbmp.UriSource = $shotUri
                    $sbmp.DecodePixelWidth = 1280
                    $sbmp.CacheOption = if ($shotUri.IsFile) {
                        [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    } else {
                        [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand
                    }
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
                            $hbUri = New-Object System.Uri $hdrFallback
                            $hb.UriSource = $hbUri
                            $hb.DecodePixelWidth = 1280
                            $hb.CacheOption = if ($hbUri.IsFile) { [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad } else { [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand }
                            $hb.EndInit()
                            if ($hbUri.IsFile -and $hb.CanFreeze) { $hb.Freeze() }
                            $shotImgRef.Source = $hb
                        } catch { }
                    }.GetNewClosure())
                    $sbmp.EndInit()
                    if ($shotUri.IsFile -and $sbmp.CanFreeze) { $sbmp.Freeze() }
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
    $similar = Get-SimilarGames -Game $Game -Count 12
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
                    $simHdrUri = New-Object System.Uri $simHdrUrl
                    $tbmp.UriSource = $simHdrUri
                    $tbmp.DecodePixelWidth = 320
                    $tbmp.CacheOption = if ($simHdrUri.IsFile) {
                        [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    } else {
                        [System.Windows.Media.Imaging.BitmapCacheOption]::OnDemand
                    }
                    $tbmp.EndInit()
                    if ($simHdrUri.IsFile -and $tbmp.CanFreeze) { $tbmp.Freeze() }
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

    # Video strip (position 1, directly under the Game Info row) - only for
    # catalog entries that set a VideoUrl; every other game is unchanged.
    if ($Game.VideoUrl) {
        try {
            $vstrip = New-VideoStripElement -Game $Game -AccentHex $accentHex
            $vstrip2 = $null
            if ($Game.VideoUrl2) { $vstrip2 = New-VideoStripElement -Game $Game -AccentHex $accentHex -Which "Secondary" }
            if ($vstrip -and $vstrip2) {
                # Side by side with a gap, each taking half the width.
                $vrow = New-Object System.Windows.Controls.Grid
                $c1 = New-Object System.Windows.Controls.ColumnDefinition
                $cgap = New-Object System.Windows.Controls.ColumnDefinition
                $c2 = New-Object System.Windows.Controls.ColumnDefinition
                $c1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
                $cgap.Width = New-Object System.Windows.GridLength(14)
                $c2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
                $vrow.ColumnDefinitions.Add($c1) | Out-Null
                $vrow.ColumnDefinitions.Add($cgap) | Out-Null
                $vrow.ColumnDefinitions.Add($c2) | Out-Null
                [System.Windows.Controls.Grid]::SetColumn($vstrip, 0)
                [System.Windows.Controls.Grid]::SetColumn($vstrip2, 2)
                $vrow.Children.Add($vstrip) | Out-Null
                $vrow.Children.Add($vstrip2) | Out-Null
                $stack.Children.Add($vrow) | Out-Null
            } elseif ($vstrip) {
                $stack.Children.Add($vstrip) | Out-Null
            }
        } catch {}
    }

    # README sections (if available)
    $sections = Read-GameReadme -Game $Game
    $readmeLinks = $null
    $deferredUninstallBox = $null
    $discordSectionText = $null
    if (Get-Command Get-GameDiscordSectionText -ErrorAction SilentlyContinue) {
        try { $discordSectionText = Get-GameDiscordSectionText -Game $Game } catch { }
    }
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
        # A README can switch the re-sorting off with <!-- hub:keep-order -->
        # (see Read-GameReadme). Needed for pages that document TWO mods
        # in sequence: sorting would rip sections out of their mod's block.
        $keepOrder = ($sections.Contains("_keepOrder") -and $sections["_keepOrder"])
        $preferred = @("About this mod", "About", "Where to get the game", "What it installs", "Requirements", "Note")
        if ($keepOrder) { $preferred = @() }
        $skip      = @{ "How to use" = $true; "More info" = $true }
        # A centrally registered channel replaces only short, dedicated
        # Discord link sections. Detailed onboarding sections such as
        # "Discord workflow" remain part of the README.
        if ($discordSectionText) {
            foreach ($sectionKey in $sections.get_Keys()) {
                if ([string]$sectionKey -match '^(?i:discord|discord links?|discord support)$') {
                    $skip[[string]$sectionKey] = $true
                }
            }
        }
        # Sections that should always render AT THE END, in this
        # order. Substring match (case-insensitive) on the heading
        # so e.g. "Support Astienth" hits "support", "Related
        # communities" hits "related", "Uninstall / temporarily
        # disable" hits "uninstall". Donations / community links /
        # uninstall guidance belong below the main usage info, not
        # interleaved with it.
        $tailPatterns = @("related", "communit", "discord", "support", "donat", "credit", "deactivate", "uninstall", "deinstall")
        if ($keepOrder) { $tailPatterns = @() }
        $shown = @{}
        $theatreBtnPlaced = $false
        # Pull baseDir so embedded images like ![Layout](pic.webp)
        # can resolve to absolute paths during rendering.
        $imgBase = if ($sections.Contains("_baseDir")) { $sections["_baseDir"] } else { $null }
        $readmeTexts = @($sections.get_Keys() | Where-Object { -not $_.StartsWith('_') } | ForEach-Object { [string]$_; [string]$sections[$_] })
        if ($sections.Contains('_quip')) { $readmeTexts += [string]$sections['_quip'] }
        $readmeLinks = New-ReadmeLinkSession -Game $Game -Texts $readmeTexts -BaseDir $imgBase -DeferLocalIndex
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
                try {
                    $sec = New-DetailSection -Heading $key -Body $sections[$key] -AccentHex $accentHex -AppendChild $append -ImageBaseDir $imgBase -Game $Game -LinkSession $readmeLinks -PreserveSubheadings:$keepOrder
                    if ($sec) { $stack.Children.Add($sec) | Out-Null }
                } catch { }
                $shown[$key] = $true
            }
        }
        # Middle block: remaining h2 sections that are NOT tail items.
        # NOTE: iterate via get_Keys() rather than .Keys - a section
        # heading literally named "Keys" (or any OrderedDictionary member
        # name) would otherwise shadow the .Keys property and PowerShell
        # would return that section's VALUE (a single string) instead of
        # the key collection, so only one section would render.
        foreach ($key in $sections.get_Keys()) {
            if ($key -eq "_tagline" -or $key -eq "_baseDir" -or $key -eq "_quip" -or $key -eq "_keepOrder" -or $shown.Contains($key) -or $skip.Contains($key)) { continue }
            if ((& $isTail $key)) { continue }
            try {
                $sec = New-DetailSection -Heading $key -Body $sections[$key] -AccentHex $accentHex -ImageBaseDir $imgBase -Game $Game -LinkSession $readmeLinks -PreserveSubheadings:$keepOrder
                if ($sec) { $stack.Children.Add($sec) | Out-Null }
            } catch { }
            $shown[$key] = $true
        }
        # Tail block: render tail sections last, grouped by pattern
        # in $tailPatterns order. Within a single pattern (e.g. two
        # "support" sections), preserve README order.
        foreach ($pat in $tailPatterns) {
            foreach ($key in $sections.get_Keys()) {
                if ($key -eq "_tagline" -or $key -eq "_baseDir" -or $key -eq "_quip" -or $key -eq "_keepOrder" -or $shown.Contains($key) -or $skip.Contains($key)) { continue }
                if (-not $key.ToString().ToLower().Contains($pat)) { continue }
                try {
                $sec = New-DetailSection -Heading $key -Body $sections[$key] -AccentHex $accentHex -ImageBaseDir $imgBase -Game $Game -LinkSession $readmeLinks -PreserveSubheadings:$keepOrder
                if ($sec) { $stack.Children.Add($sec) | Out-Null }
            } catch { }
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
        # External mods need safe removal guidance too. They skip the Steam
        # Theatre control, but still get the guide and any located author
        # uninstaller beside it.
        if ($true) {
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

            # Holds the button row AND, under it, the uninstall guide
            # when it is expanded. One container, so both travel
            # together whether the box renders here or is deferred
            # below the quip.
            $guideHost = New-Object System.Windows.Controls.StackPanel
            $guideHost.Children.Add($standaloneBox) | Out-Null

            # Only add the Theatre button if it wasn't already placed
            # in the Requirements section above.
            if (-not $isExternal -and -not $theatreBtnPlaced) {
                $standaloneBtn = New-SteamTheatreButton -AccentHex $accentHex
                $standaloneBtn.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
                $standaloneRow.Children.Add($standaloneBtn) | Out-Null
            }

            # (Flat / VR switch moved to the main action row, after
            # Open in Steam.) Keep the flag for the defer logic below.
            $flatBtnPlaced = $false

            # Uninstall Guide button: always shown for non-external
            # games. Adapts steps based on whether the game uses
            # Steam launch options that need clearing first.
            $uninstallBtn = New-UninstallGuideButton -Game $Game -AccentHex "#cc6655" -HostPanel $guideHost
            $uninstallBtn.Margin = [System.Windows.Thickness]::new(0, 0, 0, 0)
            $standaloneRow.Children.Add($uninstallBtn) | Out-Null

            # "Uninstall now" beside the guide - ONLY when the entry
            # names an uninstaller AND that file is really on disk.
            # Everything without UninstallExe is untouched by this.
            $uninstallActions = @(Resolve-UninstallActions -Game $Game)
            $targetedActions = @($uninstallActions | Where-Object { $_.TargetMod })
            if ($Game.TwoMods -and $targetedActions.Count -gt 0) {
                $uninstallChoices = @(Get-TwoModUninstallChoices -Game $Game -Actions $targetedActions)
                if ($Game.SeparateUninstallButtons) {
                    # BioShock has two independent removers. Naming both
                    # actions directly is clearer than a generic Windows
                    # Yes/No/Cancel dialog whose buttons cannot say A and B.
                    foreach ($choice in @($uninstallChoices | Where-Object Removable)) {
                        $action = $choice.Action
                        $unNowBtn = New-UninstallNowButton -Game $Game -ExePath $action.Path -Label $action.Label -ProbeFile $action.ProbeFile -Arguments $action.Arguments
                        $unNowBtn.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
                        $standaloneRow.Children.Add($unNowBtn) | Out-Null
                    }
                } elseif (@($uninstallChoices | Where-Object Removable).Count -gt 0) {
                    # Other two-mod entries keep one compact entry point. Its
                    # dialog shows detected states before either action runs.
                    $unNowBtn = New-UninstallNowButton -Game $Game -Label 'Uninstall now' -Choices $uninstallChoices
                    $unNowBtn.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
                    $standaloneRow.Children.Add($unNowBtn) | Out-Null
                }
            } else {
              foreach ($uninstallAction in $uninstallActions) {
                $unNowBtn = New-UninstallNowButton -Game $Game -ExePath $uninstallAction.Path -Label $uninstallAction.Label -ProbeFile $uninstallAction.ProbeFile -Arguments $uninstallAction.Arguments
                # SAME top and bottom margin as the guide next to it. The
                # call site zeroes that one, so any other value here drops
                # this button lower and makes the whole row taller - which
                # is exactly what made it look like the wrong size.
                $unNowBtn.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
                $standaloneRow.Children.Add($unNowBtn) | Out-Null
              }
            }

            # If the Theatre button is alongside (box has 2 buttons),
            # render now - before the quip. If the Uninstall button is
            # alone, defer it so the quip renders first.
            if (-not $theatreBtnPlaced -or $flatBtnPlaced) {
                $stack.Children.Add($guideHost) | Out-Null
            } else {
                $deferredUninstallBox = $guideHost
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

    # One central, durable Discord registry supplies the discussion/support
    # block for README-backed and external pages alike. It is deliberately
    # rendered after the README tail (credits/community/support) and before
    # the closing game quip, so every page keeps the same predictable place.
    if ($discordSectionText) {
        try {
            $discordSection = New-DetailSection -Heading 'Discord discussion & support' -Body $discordSectionText -AccentHex $accentHex -Game $Game -LinkSession $readmeLinks
            if ($discordSection) { $stack.Children.Add($discordSection) | Out-Null }
        } catch { }
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
        Set-TextBlockWithLinks -TextBlock $cqtb -Text $quipText -LinkSession $readmeLinks -Game $Game -AccentHex $accentHex
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
    $updateActionLabel = Get-UpdateActionLabel -Game $Game -State $state -Fallback 'Update Mod'
    # A separate update action is necessary only when the page has several
    # launch variants to preserve. Ordinary one-mod pages keep the established
    # contract: the primary blue button updates and the neighbour starts VR.
    $detailUsesSeparateUpdate = $isUpdate -and ([bool]$Game.TwoMods -or (Test-ShowDualSplit $state))
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
        # The label no longer swaps on hover - the pill next to the
        # title carries the state, so this button says what it does
        # from the start. Resting colours stay exactly the ones the
        # "VR Ready" button had; hover lifts them to the brighter
        # green that the old hover label used, so the button still
        # visibly reacts.
        $primaryTxt.Text = "Start in VR  $([char]0x25B6)"
        $primaryBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
        $primaryBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
        $primaryBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fa873")
        $primaryTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
        $primaryIconKind = "check"
        $primaryIconColor = "#88dd99"
    } elseif ($isUpdate) {
        if ($detailUsesSeparateUpdate) {
            $primaryTxt.Text = "Start in VR  $([char]0x25B6)"
            $primaryBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
            $primaryBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
            $primaryBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fa873")
            $primaryTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
            $primaryIconKind = "check"
            $primaryIconColor = "#88dd99"
        } else {
            $primaryTxt.Text = $updateActionLabel
            $primaryBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
            $primaryBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
            $primaryBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#6da3ff")
            $primaryTxt.Foreground = [System.Windows.Media.Brushes]::White
            $primaryIconKind = "update"
            $primaryIconColor = "#FFFFFF"
        }
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
        # desaturated (150+0.22 instead of 180+0.30). Family identity
        # stays visible, but the button clearly steps back.
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
    # In the ready state the label already carries the play glyph, so
    # the left status icon stays hidden in EVERY hover state.
    if ($isReady -or $detailUsesSeparateUpdate) { $primaryIcon.Visibility = [System.Windows.Visibility]::Collapsed }
    [void]$primaryStack.Children.Add($primaryIcon)
    [void]$primaryStack.Children.Add($primaryTxt)
    $primaryBtn.Child = $primaryStack
    # Add the gloss overlay AFTER setting the child - the helper
    # wraps the current child in a Grid that also holds the gloss
    # layer. The host Background stays a SolidColorBrush so
    # Add-SweepHover continues to work below.
    Add-ButtonGloss -Border $primaryBtn -Intensity 0.10

    # Companion action beside the primary button. Ready uses Reinstall.
    # A normal one-mod update keeps Update primary and exposes Start in VR;
    # multi-launch pages keep their launch choices and expose exact Update.
    $reinstallBtn = $null
    # Easy External Installer entries are discovery/redirect records. The Hub
    # may detect their game and VR payload, but it owns no installer that could
    # legitimately service a Reinstall action.
    if (Test-ShowDetailReinstallAction -IsExternal:$isExternal -IsReady:$isReady -IsUpdate:$isUpdate) {
        $reinstallBtn = New-Object System.Windows.Controls.Border
        $reinstallBtn.CornerRadius    = [System.Windows.CornerRadius]::new(7)
        # Symmetric padding to match Mod Page / Open in Steam
        # so the row reads as a coherent button group.
        $reinstallBtn.Padding         = [System.Windows.Thickness]::new(16, 10, 16, 10)
        if ($detailUsesSeparateUpdate) {
            $reinstallBtn.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
            $reinstallBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
            $reinstallBtn.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#6da3ff")
        } elseif ($isUpdate) {
            $reinstallBtn.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
            $reinstallBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
            $reinstallBtn.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fa873")
        } else {
            $reinstallBtn.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#15151e")
            $reinstallBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
            $reinstallBtn.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5a6aa8")
        }
        $reinstallBtn.Cursor          = [System.Windows.Input.Cursors]::Hand
        $reinstallBtn.Margin          = [System.Windows.Thickness]::new(0, 0, 10, 0)
        # Permanently visible - no slide-out any more. The button used
        # to appear only while the primary button was hovered, which
        # hid a real action behind a gesture nobody discovers.
        $reinstallBtn.Visibility      = [System.Windows.Visibility]::Visible

        $reinstallStack = New-Object System.Windows.Controls.StackPanel
        $reinstallStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        # Reload glyph matches the one used in the main card list
        # (CardTile.ps1) for the reinstall pill that slides out of
        # Start-in-VR - same Unicode arrow, same Segoe UI Symbol
        # font - so the two reinstall affordances read as the same
        # control across both views.
        if ($detailUsesSeparateUpdate) {
            $reinstallIconColor = "#FFFFFF"
        } elseif ($isUpdate) {
            $reinstallIconColor = "#88dd99"
        } else {
            $reinstallIconColor = "#dddddd"
        }
        $reinstallIcon = New-Object System.Windows.Controls.TextBlock
        $reinstallIcon.Text = $(if ($isUpdate -and -not $detailUsesSeparateUpdate) { "" } else { [char]0x21BB })
        $reinstallIcon.FontSize = 16
        $reinstallIcon.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI Symbol")
        $reinstallIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($reinstallIconColor)
        $reinstallIcon.Margin = [System.Windows.Thickness]::new(0, 0, $(if ($isUpdate -and -not $detailUsesSeparateUpdate) { 0 } else { 8 }), 0)
        $reinstallIcon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $reinstallStack.Children.Add($reinstallIcon) | Out-Null
        $reinstallTxt = New-Object System.Windows.Controls.TextBlock
        if ($detailUsesSeparateUpdate) {
            $reinstallTxt.Text = $updateActionLabel
        } elseif ($isUpdate) {
            $reinstallTxt.Text = "Start in VR  $([char]0x25B6)"
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
        if ($detailUsesSeparateUpdate) {
            $reinstallTxt.Foreground = [System.Windows.Media.Brushes]::White
        } elseif ($isUpdate) {
            $reinstallTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
        } else {
            $reinstallTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dddddd")
        }
        $reinstallStack.Children.Add($reinstallTxt) | Out-Null
        $reinstallBtn.Child = $reinstallStack
        Add-ButtonGloss -Border $reinstallBtn -Intensity 0.08

        # Snapshot resting brushes so leave restores them cleanly.
        # Only the thickness is still needed: the hover no longer
        # repaints anything, so the old resting background / border /
        # foreground snapshots have no consumer left.
        $restingBdT    = $primaryBtn.BorderThickness
        $startText   = "Start in VR  $([char]0x25B6)"
        $restingText = if ($isUpdate -and -not $detailUsesSeparateUpdate) { $updateActionLabel } else { $startText }
        $isReadyLocal = $isReady  # captured for the closure
        $hoverState  = @{ PrimaryHover = $false; ReinstallHover = $false; RowHover = $false; Opened = $false }
        $isUpdateLocal = $isUpdate  # captured for closure
        # DualMode container - assigned later when we know whether
        # the game qualifies. The closure below picks up DepotBtn
        # by referencing the hashtable, so a later assignment is
        # visible to the closure when it runs.
        $dualRef = @{ DepotBtn = $null }

        $applyHoverState = {
            # Nothing slides out any more - Reinstall and Depot are
            # always on screen. All this still does is the colour lift
            # on the PRIMARY button, so only its own hover counts.
            # Hovering Reinstall must NOT light up the primary button,
            # and the row-wide hold that kept the popover open is gone
            # with the popover.
            $isHovering = $hoverState.PrimaryHover
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
                # !!! NOT IN UPDATE STATE ANY MORE. Start in VR is a real
                # button beside this one now, so morphing the update
                # button into it on hover only made the update vanish
                # under the cursor - and it meant the row said "Update"
                # twice while the way to play was hidden.
                if ($isUpdate) {
                    # leave the label alone: this button updates.
                } elseif ($st -and $st.DualMode) {
                    $primaryTxt.Text = "Start Current  $([char]0x25B6)"
                } else {
                    $primaryTxt.Text = $startText
                }
                # NO colour change here any more. The hover look is the
                # page-wide standard from Add-StandardHover (sweep shine +
                # glow ring) - this button used to additionally repaint its
                # background, border and text, which made it the one button
                # that behaved differently. Worse, repainting the
                # Background from this handler killed the sweep: it runs
                # first (attached earlier) and swaps the brush the sweep
                # was about to animate.
                # What stays is the only part that carries INFORMATION:
                # the label, which in update state offers to start instead
                # of updating.
                $primaryBtn.BorderThickness = [System.Windows.Thickness]::new(1.5)
                # The hover label already carries the play glyph; hide the
                # left status icon so "Start in VR" doesn't show two symbols.
                if ($primaryIcon) { $primaryIcon.Visibility = [System.Windows.Visibility]::Collapsed }
            } else {
                $hoverState.Opened = $false
                $primaryTxt.Text       = $restingText
                $primaryBtn.BorderThickness = $restingBdT
                if ($primaryIcon -and -not $isReadyLocal) { $primaryIcon.Visibility = [System.Windows.Visibility]::Visible }
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
            # No repaint here either - sweep + glow ring is the whole
            # hover look now. Repainting Background from this handler
            # also swallowed the sweep, because this handler runs first.
        }.GetNewClosure())
        $reinstallBtn.Add_MouseLeave({
            $hoverState.ReinstallHover = $false
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
        $reinstallStartsGame = ($isUpdate -and -not $detailUsesSeparateUpdate)
        $reinstallScriptDir = $script:scriptDir
        $reinstallBtn.Add_MouseLeftButtonUp({
            if (-not $reinstallGameRef) { return }
            if ($reinstallStartsGame) {
                Start-GameInVR -Game $reinstallGameRef
                return
            }
            if (-not $reinstallGameRef.Bat) {
                Write-HubActionFailure -Action ("Open " + $reinstallGameRef.Title + " installer") -Message 'No Hub installer is configured for this entry.'
                return
            }
            if (-not $reinstallScriptDir) {
                Write-HubActionFailure -Action ("Open " + $reinstallGameRef.Title + " installer") -Message 'The Hub Core folder could not be resolved.'
                return
            }
            $batPath = Join-Path $reinstallScriptDir $reinstallGameRef.Bat
            if (-not (Test-Path $batPath)) {
                Write-HubActionFailure -Action ("Open " + $reinstallGameRef.Title + " installer") -Message ("The configured installer is missing: " + $batPath)
                return
            }
            # Run through the logging wrapper (Start-LoggedInstaller, Helpers.ps1):
            # saves output to Logs\<Title>-<timestamp>.log; the branch logic and
            # the RequiresAdmin elevated path live in one place.
            $updateChoice = Get-InstallerChoiceForUpdate -Game $reinstallGameRef
            $riProc = Start-LoggedInstaller -Game $reinstallGameRef -BatPath $batPath -RequiresAdmin:([bool]$reinstallGameRef.RequiresAdmin) -InstallerChoice $updateChoice
            # Same auto-refresh as the primary Install button, so a
            # reinstall/update done via this pill updates the page and
            # clears a pending update badge without a manual re-scan.
            if ($riProc) {
                try {
                    $global:PendingInstallTitle = $reinstallGameRef.Title
                    $riTimer = New-Object System.Windows.Threading.DispatcherTimer
                    $riTimer.Interval = [TimeSpan]::FromMilliseconds(750)
                    $riTimer.Tag = $riProc
                    $riTimer.Add_Tick({
                        param($s, $e)
                        $proc = $s.Tag
                        if (Test-InstallerRefreshReady -Process $proc) {
                            try { $s.Stop() } catch {}
                            Invoke-PostInstallRefreshSafely
                        }
                    })
                    $riTimer.Start()
                } catch {}
            } else {
                # No process handle: watch this one game's marker.
                try { Watch-InstallMarkerForRefresh -Game $reinstallGameRef } catch {}
            }
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
        if ($stForBtn -and $stForBtn.DualMode -and ($isReady -or $detailUsesSeparateUpdate)) {
            Start-GameInVR -Game $gameForBtn -Mode "Current"
            return
        }
        if ($stForBtn -and $stForBtn.DepotPresent -and -not $stForBtn.CurrentPresent -and ($isReady -or $detailUsesSeparateUpdate)) {
            Start-GameInVR -Game $gameForBtn -Mode "Depot"
            return
        }
        # Ready and multi-launch update states play here. A normal single-mod
        # update deliberately falls through to the installer below.
        if ($isReady -or $detailUsesSeparateUpdate) {
            Start-GameInVR -Game $gameForBtn
            return
        }
        # Non-ready state falls through to the install/get action below.
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
            Write-HubActionFailure -Action ("Open " + $gameForBtn.Title + " installer") -Message ("The configured installer is missing: " + $batPath)
            return
        }
        # Run the installer through the logging wrapper (Start-LoggedInstaller
        # in Helpers.ps1): output is saved to Logs\<Title>-<timestamp>.log, and
        # the branch logic (LukeRoss / REFramework / standard) plus the
        # RequiresAdmin elevated path now live in one place. We capture the
        # launched process so the detail view auto-refreshes when it exits -
        # users were complaining the page didn't update post-install without a
        # manual Check Installed run.
        $updateChoice = Get-InstallerChoiceForUpdate -Game $gameForBtn
        $launchedProc = Start-LoggedInstaller -Game $gameForBtn -BatPath $batPath -RequiresAdmin:([bool]$gameForBtn.RequiresAdmin) -InstallerChoice $updateChoice
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
                    if (Test-InstallerRefreshReady -Process $proc) {
                        try { $s.Stop() } catch {}
                        Invoke-PostInstallRefreshSafely
                    }
                })
                $timer.Start()
            } catch {}
        } else {
            # No process handle: watch this one game's marker.
            try { Watch-InstallMarkerForRefresh -Game $gameForBtn } catch {}
        }
    }.GetNewClosure())
    # Every button on this page gets the SAME hover: sweep + glow ring.
    # The old exception ("don't sweep ready/update, it competes with the
    # Reinstall-pill animation") is obsolete - that animation is gone.
    Add-StandardHover -Border $primaryBtn
    # Wabbajack guide entries have no Hub installer - the "Get
    # Wabbajack" + mod-link buttons + Open in Steam fully cover the
    # flow, so we suppress the generic Install/primary button here.
    if (-not $Game.WabbajackUrl) {
        $twoSt = $global:gameStateMap[$Game.Title]
        if ($Game.TwoMods -and (($twoSt -and $twoSt.TwoMods) -or $Game.TwoModsAlwaysShowChoices -or $Game.CombinedModInstaller)) {
            # Launch actions stay explicit because each installed mod starts
            # differently. Installation has two deliberate policies:
            # legacy TwoModsAlwaysShowChoices pages may preselect a mod,
            # while CombinedModInstaller pages expose ONE setup button and
            # let the shared batch show its numbered menu. The latter scales
            # cleanly when a fourth or fifth alternative arrives.
            $alternativeDefinitions = @(Get-AlternativeModDefinitions -Game $Game -State $twoSt)
            $useCombinedInstaller = [bool]$Game.CombinedModInstaller
            foreach ($definition in $alternativeDefinitions) {
                if ($definition.Present) {
                    $play = New-TwoModsButton -Game $Game -Mode ([string]$definition.Mode) -Label ("Play " + [string]$definition.Name) -AccentHex $accentHex -Installed:$true
                    $play.Margin = [System.Windows.Thickness]::new(0,0,10,0)
                    $btnRow.Children.Add($play) | Out-Null
                    Add-StandardHover -Border $play
                    Add-ButtonGloss -Border $play -Intensity 0.10
                } elseif ($Game.TwoModsAlwaysShowChoices -and -not $useCombinedInstaller) {
                    $install = New-TwoModsButton -Game $Game -Mode ([string]$definition.Mode) -Label ("Install " + [string]$definition.Name) -AccentHex $accentHex
                    $install.Margin = [System.Windows.Thickness]::new(0,0,10,0)
                    $btnRow.Children.Add($install) | Out-Null
                    Add-StandardHover -Border $install
                }
            }
            if ($useCombinedInstaller) {
                $installedAlternativeCount = @($alternativeDefinitions | Where-Object Present).Count
                $installerLabel = if ($Game.AlternativeInstallerLabel) { [string]$Game.AlternativeInstallerLabel }
                                  elseif ($installedAlternativeCount) { 'Install / manage mods' }
                                  else { 'Install VR mod' }
                $installerMenu = New-TwoModsButton -Game $Game -Mode 'InstallerMenu' -Label $installerLabel -AccentHex $accentHex
                $installerMenu.Margin = [System.Windows.Thickness]::new(0,0,10,0)
                $btnRow.Children.Add($installerMenu) | Out-Null
                Add-StandardHover -Border $installerMenu
                Add-ButtonGloss -Border $installerMenu -Intensity 0.08
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
        $userLocated = [bool](Read-PersistentGameStateValue -Game $Game -Name 'user_located')
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
    # AlwaysOfferLocate: normally the Locate button waits for a scan to
    # have run, because before that "not detected" means nothing. For a
    # game that is IN NO LIBRARY AT ALL - not on Steam, GOG or Epic, the
    # user brings their own copy - a scan can never find it, so waiting
    # for one hides the button forever. Those entries set the flag and
    # get the button as soon as the tile is not showing an install.
    # Everything without the flag behaves exactly as before.
    } elseif (($global:HasRunInstalledScan -or $Game.AlwaysOfferLocate) -and (-not ($isReady -or $isUpdate -or $isInstalledNoMod -or $isFreeScanned)) -and ($Game.ModFile -or $Game.TwoMods)) {
        try {
            $locateBtn = New-LocateButton -Game $Game -AccentHex $accentHex
            $locateBtn.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
            Add-StandardHover -Border $locateBtn
            $btnRow.Children.Add($locateBtn) | Out-Null
        } catch {}
    }

    # DualMode depot button. Usually it appears when both variants exist;
    # titles such as PEAK also expose the known-good depot when it is the
    # only installed variant, so Start in VR cannot accidentally route to
    # the broken current Steam build.
    $depotBtn = $null
    $isDualMode = $false
    if ($Game.DualMode -and -not $Game.TwoMods -and ($isReady -or $isUpdate)) {
        $st = $global:gameStateMap[$Game.Title]
        if ($st -and ($st.DualMode -or $st.DepotPresent)) {
            $isDualMode = [bool]$st.DualMode
            $depotBtn = New-Object System.Windows.Controls.Border
            $depotBtn.CornerRadius    = [System.Windows.CornerRadius]::new(7)
            $depotBtn.Padding         = [System.Windows.Thickness]::new(16, 10, 16, 10)
            $depotBtn.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
            $depotBtn.BorderThickness = [System.Windows.Thickness]::new(1)
            $depotBtn.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
            $depotBtn.Cursor          = [System.Windows.Input.Cursors]::Hand
            $depotBtn.Margin          = [System.Windows.Thickness]::new(0, 0, 10, 0)
            $depotBtn.Visibility      = [System.Windows.Visibility]::Visible

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
            $depotTxt.Text = if ($Game.DepotButtonLabel) { "Start " + [string]$Game.DepotButtonLabel } else { "Start Depot" }
            $depotTxt.FontSize = 14
            $depotTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
            $depotTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $depotTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
            $depotTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $depotStack.Children.Add($depotTxt) | Out-Null
            $depotBtn.Child = $depotStack
            Add-ButtonGloss -Border $depotBtn -Intensity 0.08

            # Hover tint to distinguish active button
            # No repaint - see the Reinstall button above.
            $depotBtn.Add_MouseEnter({
                $closeTimer.Stop()
                $hoverState.ReinstallHover = $true
                & $applyHoverState
            }.GetNewClosure())
            $depotBtn.Add_MouseLeave({
                $hoverState.ReinstallHover = $false
                $closeTimer.Stop(); $closeTimer.Start()
            }.GetNewClosure())

            $depotGameRef = $Game
            $depotBtn.Add_MouseLeftButtonUp({
                if ($depotGameRef) { Start-GameInVR -Game $depotGameRef -Mode "Depot" }
            }.GetNewClosure())

            Add-StandardHover -Border $depotBtn
            $btnRow.Children.Add($depotBtn) | Out-Null
            $dualRef.DepotBtn = $depotBtn
        }
    }

    # Optional older pinned build, deliberately not part of the card split.
    # PEAK's AstienVR 1.44.a install stays reachable here without ever being
    # mistaken for the recommended Andrey04o Depot 2.1a button.
    if ($Game.LegacyDepotPath -and $Game.LegacyDepotLaunchExe -and $Game.LegacyDepotModFile) {
        $legacyPresent = $false
        foreach ($cand in (Get-LegacyDepotCandidatePaths -Game $Game)) {
            if ((Test-Path -LiteralPath (Join-Path $cand $Game.LegacyDepotLaunchExe) -PathType Leaf) -and
                (Test-Path -LiteralPath (Join-Path $cand $Game.LegacyDepotModFile) -PathType Leaf)) {
                $legacyPresent = $true; break
            }
        }
        if ($legacyPresent) {
            $legacyLabel = if ($Game.LegacyDepotButtonLabel) { [string]$Game.LegacyDepotButtonLabel } else { "Start Legacy" }
            $legacyBtn = New-TwoModsButton -Game $Game -Mode "LegacyDepot" -Label $legacyLabel -AccentHex $accentHex -Installed
            $legacyBtn.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
            Add-StandardHover -Border $legacyBtn
            $btnRow.Children.Add($legacyBtn) | Out-Null
        }
    }

    if ($reinstallBtn) {
        Add-StandardHover -Border $reinstallBtn
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
                                if ($p -and (Test-LiteralPathSafe -Path $p -PathType Container) -and ($libs -notcontains $p)) {
                                    $libs += $p
                                }
                            }
                        }
                    }
                }
                foreach ($lib in $libs) {
                    $candidate = Join-HubPathLexical $lib "steamapps\common\$($Game.SteamFolder)"
                    if (Test-LiteralPathSafe -Path $candidate -PathType Container) { $baseDir = $candidate; break }
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

        # Add-ons with a unique payload marker are detected directly. That
        # survives a Hub update, whose clean release intentionally contains
        # no runtime .installed_path files. Older/overlay add-ons without a
        # unique probe retain the installer-marker fallback below.
        if ($baseInstalled -and $baseDir -and $Game.AddonProbeFile) {
            foreach ($addonProbe in @(([string]$Game.AddonProbeFile) -split '\|' | Where-Object { $_ })) {
                if (Test-Path -LiteralPath (Join-Path $baseDir $addonProbe.Trim()) -PathType Leaf) { $addonInstalled = $true; break }
            }
        }
        if ($baseInstalled -and -not $addonInstalled -and $Game.AddonInstaller) {
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
                            $probeOkay = $true
                            if ($Game.AddonProbeFile) {
                                $probeOkay = $false
                                foreach ($addonProbe in @(([string]$Game.AddonProbeFile) -split '\|' | Where-Object { $_ })) {
                                    if (Test-Path -LiteralPath (Join-Path $recorded $addonProbe.Trim()) -PathType Leaf) { $probeOkay = $true; break }
                                }
                            }
                            $addonInstalled = [bool]$probeOkay
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
                        # addon install lands in Core\Logs like every other
                        # install. Release hygiene guarantees that runtime
                        # contents are removed before packaging.
                        $addonLogsDir = Get-HubRuntimeLogsRoot
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
                                if (Test-InstallerRefreshReady -Process $p) {
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
                Add-StandardHover -Border $addonBtn
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
        Add-StandardHover -Border $wjBtn
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
            Add-StandardHover -Border $mbBtn
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
        # while staying muted next to the primary CTAs.
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
        Add-StandardHover -Border $infoBtnD
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
            # V6 muted blue palette. Open-in-Steam keeps a
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
        Add-StandardHover -Border $steamBtn
        $btnRow.Children.Add($steamBtn) | Out-Null
    }

    # Flat / VR switch - in the MAIN action row, after Open in Steam.
    # Only for winhttp-based BepInEx mods (or a game with an explicit
    # FlatVR proxy, e.g. Portal 2) that are actually VR-installed.
    $fvSt2 = $global:gameStateMap[$Game.Title]
    if ((($Game.ModFile -and ($Game.ModFile -match 'BepInEx')) -or $Game.FlatVREnabled -or $Game.FlatVRIniFile -or ($Game.Bat -and ($Game.Bat -match 'LukeRossVR'))) -and $fvSt2 -and ($fvSt2.Tag -in @("vrinstalled","vrupdate"))) {
        $flatBtn = New-FlatVRToggleButton -Game $Game -AccentHex $accentHex
        $flatBtn.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
        Add-StandardHover -Border $flatBtn
        $btnRow.Children.Add($flatBtn) | Out-Null
    }

    # README file/folder links need a bounded directory index for installed
    # games. Build it only after the fully composed page has had a render turn:
    # images, text, buttons and web links are visible first, local path mentions
    # become clickable immediately afterwards. Guard against a fast navigation
    # to another game before this idle callback runs.
    if ($global:DetailReadmeLinkSessions -and $global:DetailReadmeLinkSessions.Count -gt 0) {
        $deferredLinkSessions = $global:DetailReadmeLinkSessions
        $deferredLinkTitle = [string]$Game.Title
        $global:discoverDetail.Dispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::ContextIdle,
            [Action]{
                if ($global:currentDetailGame -and
                    [string]$global:currentDetailGame.Title -eq $deferredLinkTitle -and
                    [object]::ReferenceEquals($global:DetailReadmeLinkSessions, $deferredLinkSessions)) {
                    try { Update-DetailReadmeLinks } catch { }
                }
            }.GetNewClosure()
        ) | Out-Null
    }
    $detailBuildWatch.Stop()
    if (Get-Command Write-HubTiming -ErrorAction SilentlyContinue) {
        Write-HubTiming ("detail page built: {0} ({1} ms)" -f $Game.Title, $detailBuildWatch.ElapsedMilliseconds)
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
    # Wide detail heroes can own two 30-Hz network-effect timers. Their visual
    # tree is about to be discarded, so stop those timers explicitly instead
    # of letting detached simulations accumulate across visited games.
    if (Get-Command Stop-BannerNetTimer -ErrorAction SilentlyContinue) {
        foreach ($nm in @("DetailHeroBanner", "DetailHeroBandLeft", "DetailHeroBandRight")) {
            try { Stop-BannerNetTimer -BannerName $nm } catch { }
        }
    }
    $global:DetailDescTxt = $null
    $global:DetailReadmeTextBlocks = $null
    $global:DetailUninstallGuide = $null
    $global:DetailReadmeLinkSessions = $null
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
    if (Get-Command Apply-CatalogSort -ErrorAction SilentlyContinue) {
        Apply-CatalogSort -Scope Library -SkipFilter
    }
}

function global:Refresh-DiscoverStatuses {
    foreach ($tile in $global:discoverPanel.Children) {
        Update-DiscoverTileStatus -Tile $tile
    }
}
