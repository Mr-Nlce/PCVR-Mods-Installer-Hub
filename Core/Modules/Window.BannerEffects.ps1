# Wire up version label and update banner
$updateBanner     = $window.FindName("UpdateBanner")
$updateBannerText = $window.FindName("UpdateBannerText")
$versionLabel     = $window.FindName("VersionLabel")
$versionBadge     = $window.FindName("VersionBadge")
$headerVrIcon     = $window.FindName("HeaderVrIcon")
$headerHubTitle   = $window.FindName("HeaderHubTitle")
$headerTagline    = $window.FindName("HeaderTagline")

# Apply the subtle white -> light-grey vertical gradient (matching the
# card tiles and detail-page title) to the header logo text and the
# three game banner titles. Done programmatically so the XAML stays
# lean and the look stays in sync across the app.
function global:Set-TitleGradient {
    param($Element)
    if (-not $Element) { return }
    try {
        $g = New-Object System.Windows.Media.LinearGradientBrush
        $g.StartPoint = [System.Windows.Point]::new(0, 0)
        $g.EndPoint   = [System.Windows.Point]::new(0, 1)
        $g.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(255,255,255), 0))) | Out-Null
        $g.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(216,222,227), 1))) | Out-Null
        $g.Freeze()
        $Element.Foreground = $g
    } catch { }
}
Set-TitleGradient $headerHubTitle
Set-TitleGradient ($window.FindName("ListBannerTitle"))
Set-TitleGradient ($window.FindName("LibBannerTitle"))
Set-TitleGradient ($window.FindName("OvBannerTitle"))

# -------------------------------------------------------
# Explore banner: subtle slow-scrolling starfield eye-catcher.
# Built entirely in code and fully wrapped so any failure leaves
# the banner untouched (never breaks the window). Stars are laid
# out over 2x the banner height and the layer scrolls up by exactly
# one banner height on a Forever loop, so the wrap is seamless.
# -------------------------------------------------------
function global:Add-BannerStarfield {
    param([string]$BannerName, [double]$BannerH, [string]$StarColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }

        # Span the field far wider than the default banner so it still
        # fills the whole width when the window is maximized (the banner
        # stretches; the Border clips the overflow). Density is kept
        # constant (~1 star per 26px), so it looks the same at any size.
        $fieldW = 2600.0
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.Opacity = 0.7
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        # Hundreds of static stars move as one layer. Cache the composed
        # field once so WPF only translates a bitmap while it animates.
        $canvas.CacheMode = New-Object System.Windows.Media.BitmapCache

        # Deterministic field (seeded) so it looks identical every launch.
        $rand  = New-Object System.Random 1337
        $brush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($StarColorHex))
        $brush.Freeze()
        $starCount = [int]($fieldW / 26.0)
        for ($k = 0; $k -lt $starCount; $k++) {
            $x  = $rand.NextDouble() * $fieldW
            $y  = $rand.NextDouble() * $BannerH
            $sz = 1.2 + ($rand.NextDouble() * 1.6)
            $op = 0.30 + ($rand.NextDouble() * 0.60)
            foreach ($copy in 0, 1) {
                $e = New-Object System.Windows.Shapes.Ellipse
                $e.Width  = $sz
                $e.Height = $sz
                $e.Fill   = $brush
                $e.Opacity = $op
                [System.Windows.Controls.Canvas]::SetLeft($e, $x)
                [System.Windows.Controls.Canvas]::SetTop($e, $y + ($copy * $BannerH))
                [void]$canvas.Children.Add($e)
            }
        }

        $tt = New-Object System.Windows.Media.TranslateTransform
        $canvas.RenderTransform = $tt
        $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
        $anim.From = 0.0
        $anim.To   = -$BannerH
        $anim.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(23.04))
        $anim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $anim)

        # Insert the field BELOW the header image (just above the solid
        # background), so the image itself overlays the stars on the right -
        # pixel-perfect, no masking guesswork - exactly the way the buttons
        # and title overlay them. The dark fade gradient sitting above still
        # blends the image's edge, and the stars read through it across the
        # open left/middle of the banner.
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}
function global:Add-BannerOrbs {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cols = @("#34d399","#3a8add","#f0d860","#5fff8f","#36e0e0")
        $rand = New-Object System.Random
        $nOrb = 4 + $rand.Next(0, 7)
        $orbInfo = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $nOrb; $i++) {
            # Cycle the palette so several colours are always present.
            $col = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$i % $cols.Count])
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new($col, 0.0)) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $col.R, $col.G, $col.B), 1.0)) | Out-Null
            $orb = New-Object System.Windows.Shapes.Ellipse
            $size = 95.0 + ($rand.NextDouble() * 80.0)
            $orb.Width = $size; $orb.Height = $size
            $orb.Fill = $rg
            $orb.Opacity = 0.4 + ($rand.NextDouble() * 0.2)
            $blur = New-Object System.Windows.Media.Effects.BlurEffect
            $blur.Radius = 22
            $orb.Effect = $blur
            # Static blur + moving transform: render the blur once.
            $orb.CacheMode = New-Object System.Windows.Media.BitmapCache
            $tt = New-Object System.Windows.Media.TranslateTransform
            $orb.RenderTransform = $tt
            $dur = 6.0 + ($rand.NextDouble() * 5.0)
            # Gentle drift (small amplitude so orbs stay in view, don't wander out).
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(14 + $rand.NextDouble() * 12); $ax.To = (14 + $rand.NextDouble() * 14)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = -(8 + $rand.NextDouble() * 8); $ay.To = (8 + $rand.NextDouble() * 10)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur * 0.8))
            $ay.AutoReverse = $true
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ay.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            [void]$canvas.Children.Add($orb)
            # Even horizontal slot (with a little jitter) + a centred vertical band,
            # stored as fractions so we can re-place on resize.
            $fx = ($i + 0.5) / $nOrb + (($rand.NextDouble() - 0.5) * 0.06)
            $fy = 0.18 + $rand.NextDouble() * 0.34
            [void]$orbInfo.Add([pscustomobject]@{ el = $orb; sz = $size; fx = $fx; fy = $fy })
        }
        # The stretched canvas's ActualWidth IS the visible width; spread the orbs
        # across it (and re-spread on resize) so the count/colours look consistent
        # instead of mostly landing off-screen.
        $reflow = {
            $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            $ch = $canvas.ActualHeight; if ($ch -lt 20) { $ch = $BannerH }
            foreach ($o in $orbInfo) {
                [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2))
                [System.Windows.Controls.Canvas]::SetTop($o.el, ($o.fy * $ch) - ($o.sz / 2))
            }
        }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow)
        & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSynthGrid {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $refW = 1000.0
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.Width = $refW; $canvas.Height = $BannerH
        $canvas.ClipToBounds = $true
        $horizon = $BannerH * 0.34
        $cx = $refW / 2.0
        $cyan = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString("#36e0e0")); $cyan.Opacity = 0.45; $cyan.Freeze()
        $mag  = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString("#c850ff")); $mag.Opacity = 0.40; $mag.Freeze()
        # Horizon glow (centered).
        $gcol = [System.Windows.Media.ColorConverter]::ConvertFromString("#ff5fbd")
        $glow = New-Object System.Windows.Shapes.Ellipse
        $glow.Width = $refW * 0.8; $glow.Height = $BannerH * 1.0
        $gg = New-Object System.Windows.Media.RadialGradientBrush
        $gg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(80, $gcol.R, $gcol.G, $gcol.B), 0.0)) | Out-Null
        $gg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $gcol.R, $gcol.G, $gcol.B), 1.0)) | Out-Null
        $glow.Fill = $gg
        [System.Windows.Controls.Canvas]::SetLeft($glow, $cx - ($refW * 0.4))
        [System.Windows.Controls.Canvas]::SetTop($glow, $horizon - ($BannerH * 0.5))
        [void]$canvas.Children.Add($glow)
        # Converging vertical lines fanning from the centered vanishing point
        # out to (and past) both edges.
        for ($vx = -1000; $vx -le 1000; $vx += 50) {
            $ln = New-Object System.Windows.Shapes.Line
            $ln.X1 = $cx; $ln.Y1 = $horizon
            $ln.X2 = $cx + $vx; $ln.Y2 = $BannerH
            $ln.Stroke = $mag; $ln.StrokeThickness = 1
            [void]$canvas.Children.Add($ln)
        }
        # Static bright horizon line.
        $hl = New-Object System.Windows.Shapes.Line
        $hl.X1 = 0; $hl.X2 = $refW; $hl.Y1 = $horizon; $hl.Y2 = $horizon
        $hl.Stroke = $cyan; $hl.StrokeThickness = 1.4
        [void]$canvas.Children.Add($hl)
        # Floor: evenly spaced horizontal lines, periodic scroll down (seamless
        # because the lines repeat exactly every $spacing).
        $span = $BannerH - $horizon
        $spacing = $span / 7.0
        $floor = New-Object System.Windows.Controls.Canvas
        for ($r = -1; $r -le 8; $r++) {
            $yy = $horizon + ($spacing * $r)
            $ln = New-Object System.Windows.Shapes.Line
            $ln.X1 = 0; $ln.X2 = $refW; $ln.Y1 = $yy; $ln.Y2 = $yy
            $ln.Stroke = $cyan; $ln.StrokeThickness = 1
            [void]$floor.Children.Add($ln)
        }
        $tt = New-Object System.Windows.Media.TranslateTransform
        $floor.RenderTransform = $tt
        $floor.CacheMode = New-Object System.Windows.Media.BitmapCache
        $an = New-Object System.Windows.Media.Animation.DoubleAnimation
        $an.From = 0.0; $an.To = $spacing
        $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(1.6))
        $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $an)
        [void]$canvas.Children.Add($floor)
        # A Canvas does NOT scale its coordinate space to its size, so wrap the
        # fixed reference-width design in a Viewbox that stretches to fill the
        # whole banner at any window width (vanishing point stays centered).
        $vb = New-Object System.Windows.Controls.Viewbox
        $vb.Stretch = [System.Windows.Media.Stretch]::Fill
        $vb.IsHitTestVisible = $false
        $vb.Child = $canvas
        $vb.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $vb)
    } catch { }
}

function global:Add-BannerCircuit {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $h = $BannerH
        # Traces as Polylines (no path-string parsing, no fragile path animation
        # API -> robust + locale-safe). "Data" flows along them via an animated
        # StrokeDashOffset. Waypoints span the full width and height.
        $routes = @(
            @(-20, ($h*0.12), 400, ($h*0.12), 460, ($h*0.48), 1000, ($h*0.48), 1060, ($h*0.10), 1700, ($h*0.10), 1760, ($h*0.55), 2620, ($h*0.55)),
            @(-20, ($h*0.86), 260, ($h*0.86), 320, ($h*0.50), 760, ($h*0.50), 820, ($h*0.90), 1320, ($h*0.90), 1380, ($h*0.52), 1900, ($h*0.52), 1960, ($h*0.88), 2620, ($h*0.88)),
            @(-20, ($h*0.30), 600, ($h*0.30), 660, ($h*0.70), 1200, ($h*0.70), 1260, ($h*0.26), 1860, ($h*0.26), 1920, ($h*0.72), 2620, ($h*0.72))
        )
        $traceCols = @("#34d399","#36e0e0")
        $rand = New-Object System.Random
        $ci = 0
        foreach ($r in $routes) {
            $tb = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($traceCols[$ci % $traceCols.Count])); $tb.Opacity = 0.55
            $pl = New-Object System.Windows.Shapes.Polyline
            $pts = New-Object System.Windows.Media.PointCollection
            for ($i = 0; $i -lt $r.Count; $i += 2) {
                $pts.Add([System.Windows.Point]::new([double]$r[$i], [double]$r[$i + 1])) | Out-Null
            }
            $pl.Points = $pts
            $pl.Stroke = $tb
            $pl.StrokeThickness = 1.6
            $pl.Fill = $null
            $dash = New-Object System.Windows.Media.DoubleCollection
            $dash.Add(2.0); $dash.Add(7.0)
            $pl.StrokeDashArray = $dash
            $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $anim.From = 0; $anim.To = -18
            $anim.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(1.1 + $rand.NextDouble() * 0.9))
            $anim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $pl.BeginAnimation([System.Windows.Shapes.Shape]::StrokeDashOffsetProperty, $anim)
            [void]$canvas.Children.Add($pl)
            $ci++
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerNetwork {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $fieldW = 1600.0
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        # Ten nodes still read as a connected constellation, while cutting the
        # all-pairs line updates from 91 to 45 per animation tick.
        $n = 10; $maxD = 180.0
        $rand = New-Object System.Random
        $nodeBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString("#5fff8f")); $nodeBrush.Freeze()
        $nodes = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $n; $i++) {
            $e = New-Object System.Windows.Shapes.Ellipse
            $e.Width = 3.4; $e.Height = 3.4; $e.Fill = $nodeBrush
            $node = [pscustomobject]@{ x = $rand.NextDouble() * $fieldW; y = $rand.NextDouble() * $BannerH; vx = ($rand.NextDouble() - 0.5) * 28; vy = ($rand.NextDouble() - 0.5) * 28; el = $e }
            [System.Windows.Controls.Canvas]::SetLeft($e, $node.x)
            [System.Windows.Controls.Canvas]::SetTop($e, $node.y)
            [void]$canvas.Children.Add($e)
            [void]$nodes.Add($node)
        }
        $lines = New-Object System.Collections.ArrayList
        for ($a = 0; $a -lt $n; $a++) {
            for ($b = $a + 1; $b -lt $n; $b++) {
                $ln = New-Object System.Windows.Shapes.Line
                $ln.StrokeThickness = 1
                $ln.Stroke = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(0, 52, 211, 153))
                [void]$canvas.Children.Insert(0, $ln)
                [void]$lines.Add([pscustomobject]@{ a = $a; b = $b; el = $ln })
            }
        }
        $state = [pscustomobject]@{ nodes = $nodes; lines = $lines; w = $fieldW; h = $BannerH; maxD = $maxD; last = [DateTime]::Now }
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(40)
        $timer.Add_Tick({
            try {
                # List, Library, Explore and Detail keep separate banner
                # visuals alive. Do no simulation work for a collapsed page.
                if (-not $banner.IsVisible) { $state.last = [DateTime]::Now; return }
                $now = [DateTime]::Now; $dt = ($now - $state.last).TotalSeconds; if ($dt -gt 0.1) { $dt = 0.1 }; $state.last = $now
                foreach ($nd in $state.nodes) {
                    $nd.x += $nd.vx * $dt; $nd.y += $nd.vy * $dt
                    if ($nd.x -lt 0) { $nd.x = 0; $nd.vx = -$nd.vx } elseif ($nd.x -gt $state.w) { $nd.x = $state.w; $nd.vx = -$nd.vx }
                    if ($nd.y -lt 0) { $nd.y = 0; $nd.vy = -$nd.vy } elseif ($nd.y -gt $state.h) { $nd.y = $state.h; $nd.vy = -$nd.vy }
                    [System.Windows.Controls.Canvas]::SetLeft($nd.el, $nd.x)
                    [System.Windows.Controls.Canvas]::SetTop($nd.el, $nd.y)
                }
                foreach ($lp in $state.lines) {
                    $na = $state.nodes[$lp.a]; $nb = $state.nodes[$lp.b]
                    $dx = $na.x - $nb.x; $dy = $na.y - $nb.y; $dist = [Math]::Sqrt($dx * $dx + $dy * $dy)
                    if ($dist -lt $state.maxD) {
                        $lp.el.X1 = $na.x; $lp.el.Y1 = $na.y; $lp.el.X2 = $nb.x; $lp.el.Y2 = $nb.y
                        $al = [byte](150 * (1 - ($dist / $state.maxD)))
                        $lp.el.Stroke.Color = [System.Windows.Media.Color]::FromArgb($al, 52, 211, 153)
                    } else {
                        $lp.el.Stroke.Color = [System.Windows.Media.Color]::FromArgb(0, 52, 211, 153)
                    }
                }
            } catch { }
        }.GetNewClosure())
        $timer.Start()
        if (-not $global:BannerTimers) { $global:BannerTimers = New-Object System.Collections.ArrayList }
        [void]$global:BannerTimers.Add($timer)
        # Remember this banner's network timer by name. The network effect is
        # the only one driven by a polled DispatcherTimer; re-rolling a banner
        # to a different effect detaches its canvas but leaves that timer
        # ticking, so the timed rotation needs to stop it by name first.
        if (-not $global:BannerNetTimers) { $global:BannerNetTimers = @{} }
        $global:BannerNetTimers[$BannerName] = $timer
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerHex {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $fieldW = 2600.0
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $cols = @("#34d399","#36e0e0","#5fff8f")
        $outline = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(46, 52, 211, 153)); $outline.Freeze()
        $w = 30.0; $hgt = 26.0
        $cells = New-Object System.Collections.ArrayList
        # Row levels scale with the banner height so taller banners (M/L)
        # get more rows and fill top-to-bottom instead of leaving the
        # lower third empty. ~4 hexes per row level, spread across width.
        $rowLevels = [Math]::Max(3, [int][Math]::Round($BannerH / 48.0))
        $nHex = 4 * $rowLevels
        for ($i = 0; $i -lt $nHex; $i++) {
            $poly = New-Object System.Windows.Shapes.Polygon
            $pts = New-Object System.Windows.Media.PointCollection
            $pts.Add([System.Windows.Point]::new($w * 0.25, 0)) | Out-Null
            $pts.Add([System.Windows.Point]::new($w * 0.75, 0)) | Out-Null
            $pts.Add([System.Windows.Point]::new($w, $hgt * 0.5)) | Out-Null
            $pts.Add([System.Windows.Point]::new($w * 0.75, $hgt)) | Out-Null
            $pts.Add([System.Windows.Point]::new($w * 0.25, $hgt)) | Out-Null
            $pts.Add([System.Windows.Point]::new(0, $hgt * 0.5)) | Out-Null
            $poly.Points = $pts
            $poly.Stroke = $outline; $poly.StrokeThickness = 1
            $cc = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$rand.Next($cols.Count)])
            $fillB = [System.Windows.Media.SolidColorBrush]::new($cc); $fillB.Opacity = 0
            $poly.Fill = $fillB
            [System.Windows.Controls.Canvas]::SetTop($poly, 6 + ($i % $rowLevels) * (($BannerH - 38) / [Math]::Max(1, $rowLevels - 1)))
            $pa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $pa.From = 0; $pa.To = 0.5
            $pa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(2.6 + $rand.NextDouble() * 2.5))
            $pa.AutoReverse = $true
            $pa.BeginTime = [TimeSpan]::FromSeconds($rand.NextDouble() * 4.0)
            $pa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $fillB.BeginAnimation([System.Windows.Media.SolidColorBrush]::OpacityProperty, $pa)
            [void]$canvas.Children.Add($poly)
            [void]$cells.Add($poly)
        }
        # The canvas stretches to the banner, so its ActualWidth IS the visible
        # width. Spread the cells evenly across it (and re-spread on resize) so
        # they always fill the banner instead of scattering off-screen.
        $reflow = {
            $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            for ($j = 0; $j -lt $cells.Count; $j++) {
                $fx = (($j + 0.5) / $cells.Count) * ($cw - 30)
                [System.Windows.Controls.Canvas]::SetLeft($cells[$j], $fx)
            }
        }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow)
        & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerEmbers {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $fieldW = 2600.0
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $count = [int]($fieldW / 55.0)
        for ($i = 0; $i -lt $count; $i++) {
            $em = New-Object System.Windows.Shapes.Ellipse
            $sz = 1.4 + $rand.NextDouble() * 2.2
            $em.Width = $sz; $em.Height = $sz
            $ec = [System.Windows.Media.Color]::FromArgb(255, 255, [byte](180 + $rand.Next(40)), [byte](90 + $rand.Next(60)))
            $em.Fill = [System.Windows.Media.SolidColorBrush]::new($ec)
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 2.0
            $em.Effect = $bl
            $em.CacheMode = New-Object System.Windows.Media.BitmapCache
            [System.Windows.Controls.Canvas]::SetLeft($em, $rand.NextDouble() * $fieldW)
            [System.Windows.Controls.Canvas]::SetTop($em, 0)
            $tt = New-Object System.Windows.Media.TranslateTransform
            $em.RenderTransform = $tt
            $dur = 5.0 + $rand.NextDouble() * 5.0
            $ya = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ya.From = $BannerH + 8; $ya.To = -8
            $ya.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            # Negative begin time: at t=0 each ember is already partway up its
            # rise (phase-distributed across the height) instead of resting at
            # translateY=0 (which sat them all at the top until their turn).
            $ya.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $ya.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ya)
            $xa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $xa.From = -(4 + $rand.NextDouble() * 6); $xa.To = (4 + $rand.NextDouble() * 8)
            $xa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(1.5 + $rand.NextDouble() * 2.0))
            $xa.AutoReverse = $true
            $xa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $xa.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $xa)
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $oa.From = 0.2; $oa.To = 0.95
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(0.8 + $rand.NextDouble() * 1.2))
            $oa.AutoReverse = $true
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $em.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            [void]$canvas.Children.Add($em)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

# Parallax starfield: multiple depth layers drifting LEFT at different speeds
# and star sizes for a sense of depth. Each layer tiles its pattern across
# 2*period and translates by -period, so the loop is seamless.
function global:Add-BannerParallax {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $col = [System.Windows.Media.ColorConverter]::ConvertFromString($ColorHex)
        $period = 1400.0
        $rand = New-Object System.Random
        $layers = @(
            @{ n = 70; sz = 0.9; op = 0.45; dur = 60.0 },
            @{ n = 55; sz = 1.4; op = 0.70; dur = 38.0 },
            @{ n = 36; sz = 2.1; op = 1.00; dur = 24.0 }
        )
        foreach ($L in $layers) {
            $layer = New-Object System.Windows.Controls.Canvas
            for ($i = 0; $i -lt $L.n; $i++) {
                $x = $rand.NextDouble() * $period
                $y = $rand.NextDouble() * $BannerH
                $o = $L.op * (0.5 + $rand.NextDouble() * 0.5)
                foreach ($copy in 0, 1) {
                    $st = New-Object System.Windows.Shapes.Ellipse
                    $st.Width = $L.sz; $st.Height = $L.sz
                    $st.Fill = [System.Windows.Media.SolidColorBrush]::new($col)
                    $st.Opacity = $o
                    [System.Windows.Controls.Canvas]::SetLeft($st, $x + ($copy * $period))
                    [System.Windows.Controls.Canvas]::SetTop($st, $y)
                    [void]$layer.Children.Add($st)
                }
            }
            $tt = New-Object System.Windows.Media.TranslateTransform
            $layer.RenderTransform = $tt
            $layer.CacheMode = New-Object System.Windows.Media.BitmapCache
            $an = New-Object System.Windows.Media.Animation.DoubleAnimation
            $an.From = 0.0; $an.To = -$period
            $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($L.dur))
            $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
            [void]$canvas.Children.Add($layer)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerNebula {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        # Nebula used to ignore ColorHex and always paint a cyan/blue/violet
        # wash. That made dark or warm games look unrelated to their own art.
        # Build three visible shades from the caller's game accent instead.
        $baseCol = [System.Windows.Media.ColorConverter]::ConvertFromString($ColorHex)
        $makeTint = {
            param([double]$WhiteMix)
            [System.Windows.Media.Color]::FromRgb(
                [byte][Math]::Round($baseCol.R + ((255 - $baseCol.R) * $WhiteMix)),
                [byte][Math]::Round($baseCol.G + ((255 - $baseCol.G) * $WhiteMix)),
                [byte][Math]::Round($baseCol.B + ((255 - $baseCol.B) * $WhiteMix)))
        }.GetNewClosure()
        $cols = @((& $makeTint 0.08), (& $makeTint 0.30), (& $makeTint 0.16))
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 3; $i++) {
            $col = $cols[$i]
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new($col, 0.0)) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $col.R, $col.G, $col.B), 1.0)) | Out-Null
            $blob = New-Object System.Windows.Shapes.Ellipse
            $sz = $BannerH * 2.4
            $blob.Width = $sz; $blob.Height = $sz; $blob.Fill = $rg; $blob.Opacity = 0.5
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 40; $blob.Effect = $bl
            $blob.CacheMode = New-Object System.Windows.Media.BitmapCache
            $tt = New-Object System.Windows.Media.TranslateTransform
            $blob.RenderTransform = $tt
            # Keep the cloudy drift calm, but make it legible: the former
            # 18-28 second travel looked completely static in narrow side bands.
            $dur = 10.0 + $rand.NextDouble() * 6.0
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(40 + $rand.NextDouble() * 40); $ax.To = (40 + $rand.NextDouble() * 50)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = -(20 + $rand.NextDouble() * 20); $ay.To = (20 + $rand.NextDouble() * 24)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur * 0.9)); $ay.AutoReverse = $true
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ay.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            # A cheap composited opacity pulse makes the motion readable even
            # when most of a large blurred cloud is clipped by a side band.
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $oa.From = 0.32; $oa.To = 0.60
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur * 0.55))
            $oa.AutoReverse = $true
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $oa.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $oa.BeginTime = [TimeSpan]::FromSeconds(-($i * 1.1))
            $blob.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            [System.Windows.Controls.Canvas]::SetTop($blob, ($BannerH / 2) - ($sz / 2))
            [void]$canvas.Children.Add($blob)
            [void]$info.Add([pscustomobject]@{ el = $blob; sz = $sz; fx = (($i + 0.5) / 3.0) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerMeteors {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        for ($i = 0; $i -lt 7; $i++) {
            $rect = New-Object System.Windows.Shapes.Rectangle
            $rect.Width = 150; $rect.Height = 2; $rect.RadiusX = 1; $rect.RadiusY = 1
            $lg = New-Object System.Windows.Media.LinearGradientBrush
            $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(1, 0)
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 200, 235, 255), 0.0)) | Out-Null
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 255, 255, 255), 1.0)) | Out-Null
            $rect.Fill = $lg
            $gl = New-Object System.Windows.Media.Effects.DropShadowEffect; $gl.Color = [System.Windows.Media.Color]::FromRgb(143, 208, 255); $gl.BlurRadius = 6; $gl.ShadowDepth = 0; $gl.Opacity = 0.9; $rect.Effect = $gl
            $rect.CacheMode = New-Object System.Windows.Media.BitmapCache
            # Descend across the WHOLE banner width: scale the drop to the
            # banner height (instead of a fixed ~515px that dove out the bottom
            # in the first third and left the meteors stuck bottom-left). The
            # tail tilt is derived from the same vector so it stays aligned.
            $xRange = 2920.0
            $yDelta = [Math]::Max(50.0, $BannerH * 1.2)
            $angleDeg = [Math]::Atan2($yDelta, $xRange) * 180.0 / [Math]::PI
            $tg = New-Object System.Windows.Media.TransformGroup
            $tg.Children.Add([System.Windows.Media.RotateTransform]::new($angleDeg)) | Out-Null
            $tt = New-Object System.Windows.Media.TranslateTransform
            $tg.Children.Add($tt) | Out-Null
            $rect.RenderTransform = $tg
            [System.Windows.Controls.Canvas]::SetTop($rect, -($BannerH * 0.15) + $rand.NextDouble() * ([Math]::Max(40.0, $BannerH * 0.55)))
            [System.Windows.Controls.Canvas]::SetLeft($rect, 0)
            $dur = 10.8 + $rand.NextDouble() * 7.2
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -320; $ax.To = 2600
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = 0; $ay.To = $yDelta
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ay.BeginTime = $ax.BeginTime
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            [void]$canvas.Children.Add($rect)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSonar {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $origins = @(@{ fx = 0.26; fy = 0.6; col = "#34d399" }, @{ fx = 0.72; fy = 0.42; col = "#36e0e0" })
        $info = New-Object System.Collections.ArrayList
        foreach ($o in $origins) {
            $col = [System.Windows.Media.ColorConverter]::ConvertFromString($o.col)
            for ($k = 0; $k -lt 3; $k++) {
                $ring = New-Object System.Windows.Shapes.Ellipse
                $ring.Width = 24; $ring.Height = 24
                $ring.Stroke = [System.Windows.Media.SolidColorBrush]::new($col); $ring.StrokeThickness = 1.5; $ring.Fill = $null
                $ring.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
                $st = [System.Windows.Media.ScaleTransform]::new(0.2, 0.2)
                $ring.RenderTransform = $st
                $period = 7.0; $bt = [TimeSpan]::FromSeconds($k * ($period / 3.0))
                $sa = New-Object System.Windows.Media.Animation.DoubleAnimation
                $sa.From = 0.2; $sa.To = 11
                $sa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($period)); $sa.BeginTime = $bt
                $sa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $sa)
                $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $sa)
                $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
                $oa.From = 0.7; $oa.To = 0.0
                $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($period)); $oa.BeginTime = $bt
                $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                $ring.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
                [System.Windows.Controls.Canvas]::SetTop($ring, ($o.fy * $BannerH) - 12)
                [void]$canvas.Children.Add($ring)
                [void]$info.Add([pscustomobject]@{ el = $ring; fx = $o.fx })
            }
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($r in $info) { [System.Windows.Controls.Canvas]::SetLeft($r.el, ($r.fx * $cw) - 12) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerMotes {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $moteBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(190, 215, 230)); $moteBrush.Freeze()
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 42; $i++) {
            $d = New-Object System.Windows.Shapes.Ellipse
            $s = 0.8 + $rand.NextDouble() * 1.6
            $d.Width = $s; $d.Height = $s; $d.Fill = $moteBrush
            $tt = New-Object System.Windows.Media.TranslateTransform
            $d.RenderTransform = $tt
            $dx = 6 + $rand.NextDouble() * 8; $dy = 6 + $rand.NextDouble() * 8
            $durx = 5.0 + $rand.NextDouble() * 6.0; $dury = 5.0 + $rand.NextDouble() * 6.0
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -$dx; $ax.To = $dx
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($durx)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $durx))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = -$dy; $ay.To = $dy
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dury)); $ay.AutoReverse = $true
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ay.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dury))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $oa.From = 0.15; $oa.To = 0.6
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(1.5 + $rand.NextDouble() * 2.5)); $oa.AutoReverse = $true
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $oa.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * 3.0))
            $d.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            [System.Windows.Controls.Canvas]::SetTop($d, $rand.NextDouble() * $BannerH)
            [void]$canvas.Children.Add($d)
            [void]$info.Add([pscustomobject]@{ el = $d; fx = $rand.NextDouble() })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($m in $info) { [System.Windows.Controls.Canvas]::SetLeft($m.el, $m.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerEqualizer {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $n = 28
        $base = [System.Windows.Media.ColorConverter]::ConvertFromString($ColorHex)
        $baseDark = [System.Windows.Media.Color]::FromRgb([byte]($base.R * 0.55), [byte]($base.G * 0.55), [byte]($base.B * 0.55))
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $n; $i++) {
            $barCol  = $base
            $barDark = $baseDark
            $bar = New-Object System.Windows.Shapes.Rectangle
            $bar.RadiusX = 2; $bar.RadiusY = 2; $bar.Height = $BannerH; $bar.Opacity = 0.1
            $lg = New-Object System.Windows.Media.LinearGradientBrush
            $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(0, 1)
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($barCol, 0.0)) | Out-Null
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($barDark, 1.0)) | Out-Null
            $bar.Fill = $lg
            $bar.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 1.0)
            $stf = [System.Windows.Media.ScaleTransform]::new(1, 0.3)
            $bar.RenderTransform = $stf
            [System.Windows.Controls.Canvas]::SetTop($bar, 0)
            $dur = 3.4 + $rand.NextDouble() * 3.0
            $sa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $sa.From = 0.15 + $rand.NextDouble() * 0.25; $sa.To = 0.7 + $rand.NextDouble() * 0.3
            $sa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur)); $sa.AutoReverse = $true
            $sa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $sa.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $sa.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $stf.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $sa)
            [void]$canvas.Children.Add($bar)
            [void]$info.Add([pscustomobject]@{ el = $bar })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            $ch = $canvas.ActualHeight
            $bw = $cw / $info.Count
            for ($j = 0; $j -lt $info.Count; $j++) { $info[$j].el.Width = $bw * 0.7; $info[$j].el.Height = $ch; [System.Windows.Controls.Canvas]::SetLeft($info[$j].el, ($j * $bw) + ($bw * 0.15)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSpeed {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cyan = [System.Windows.Media.ColorConverter]::ConvertFromString("#36e0e0")
        $rand = New-Object System.Random
        for ($i = 0; $i -lt 7; $i++) {
            $rect = New-Object System.Windows.Shapes.Rectangle
            $rect.Height = 1.5; $rect.Width = 90 + $rand.NextDouble() * 130; $rect.RadiusX = 1; $rect.RadiusY = 1
            $lg = New-Object System.Windows.Media.LinearGradientBrush
            $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(1, 0)
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $cyan.R, $cyan.G, $cyan.B), 0.0)) | Out-Null
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(230, $cyan.R, $cyan.G, $cyan.B), 1.0)) | Out-Null
            $rect.Fill = $lg
            $tt = New-Object System.Windows.Media.TranslateTransform
            $rect.RenderTransform = $tt
            [System.Windows.Controls.Canvas]::SetTop($rect, (0.08 + $rand.NextDouble() * 0.84) * $BannerH)
            [System.Windows.Controls.Canvas]::SetLeft($rect, 0)
            $dur = 6.0 + $rand.NextDouble() * 6.0
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -260; $ax.To = 2600
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            [void]$canvas.Children.Add($rect)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerFlow {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rect = New-Object System.Windows.Shapes.Rectangle
        $rect.Height = $BannerH
        $lg = New-Object System.Windows.Media.LinearGradientBrush
        $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(1, 0)
        $lg.SpreadMethod = [System.Windows.Media.GradientSpreadMethod]::Repeat
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.ColorConverter]::ConvertFromString("#16d0a0"), 0.0)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.ColorConverter]::ConvertFromString("#2ab0ff"), 0.34)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.ColorConverter]::ConvertFromString("#9a5cff"), 0.67)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.ColorConverter]::ConvertFromString("#16d0a0"), 1.0)) | Out-Null
        $rt = New-Object System.Windows.Media.TranslateTransform
        $lg.RelativeTransform = $rt
        $rect.Fill = $lg
        # Semi-transparent wash so it layers as a moving colour flow OVER the
        # banner (art + scrim) instead of a dark band hidden underneath.
        $rect.Opacity = 0.40
        # Fade the wash out toward the RIGHT so it stays on the left+middle
        # (title area) and never covers the right-aligned game art. Full to
        # ~0.42, gone by ~0.60 - safely clear of the art on any banner width.
        $mask = New-Object System.Windows.Media.LinearGradientBrush
        $mask.StartPoint = [System.Windows.Point]::new(0, 0); $mask.EndPoint = [System.Windows.Point]::new(1, 0)
        $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 255, 255, 255), 0.0)) | Out-Null
        $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 255, 255, 255), 0.42)) | Out-Null
        $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 255, 255, 255), 0.60)) | Out-Null
        $rect.OpacityMask = $mask
        $an = New-Object System.Windows.Media.Animation.DoubleAnimation
        $an.From = 0.0; $an.To = 1.0
        $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(18.0))
        $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $rt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
        [System.Windows.Controls.Canvas]::SetTop($rect, 0); [System.Windows.Controls.Canvas]::SetLeft($rect, 0)
        [void]$canvas.Children.Add($rect)
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }; $rect.Width = $cw; $rect.Height = $canvas.ActualHeight }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        # Flow is a translucent wash: add it ON TOP (above art + scrim) so the
        # moving colour is actually visible, unlike the particle effects which
        # sit under the art. Canvas IsHitTestVisible=false keeps clicks working.
        [void]$grid.Children.Add($canvas)
    } catch { }
}

function global:Add-BannerPlasma {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $palette = @("#34d399","#36e0e0","#3a8add","#c850ff")
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 3; $i++) {
            $start = [System.Windows.Media.ColorConverter]::ConvertFromString($palette[$i % $palette.Count])
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $stop0 = [System.Windows.Media.GradientStop]::new($start, 0.0)
            $rg.GradientStops.Add($stop0) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 0, 0, 0), 1.0)) | Out-Null
            $blob = New-Object System.Windows.Shapes.Ellipse
            $sz = $BannerH * 1.9
            $blob.Width = $sz; $blob.Height = $sz; $blob.Fill = $rg; $blob.Opacity = 0.6
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 36; $blob.Effect = $bl
            $blob.CacheMode = New-Object System.Windows.Media.BitmapCache
            $tt = New-Object System.Windows.Media.TranslateTransform
            $blob.RenderTransform = $tt
            $dur = 12.0 + $rand.NextDouble() * 6.0
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(40 + $rand.NextDouble() * 40); $ax.To = (40 + $rand.NextDouble() * 50)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            # Keep each blob's palette colour fixed while it drifts. Animating
            # the GradientStop invalidated BitmapCache every frame and forced
            # the radius-36 blur to be recomputed continuously. The three
            # differently coloured blobs preserve the multi-colour look.
            [System.Windows.Controls.Canvas]::SetTop($blob, ($BannerH / 2) - ($sz / 2))
            [void]$canvas.Children.Add($blob)
            [void]$info.Add([pscustomobject]@{ el = $blob; sz = $sz; fx = (($i + 0.5) / 3.0) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerBlobs {
    param([string]$BannerName, [double]$BannerH, [string[]]$Palette)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $palette = $Palette
        if (-not $palette -or $palette.Count -lt 2) { $palette = @("#34d399","#36e0e0","#3a8add","#c850ff") }
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 3; $i++) {
            $start = [System.Windows.Media.ColorConverter]::ConvertFromString($palette[$i % $palette.Count])
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $stop0 = [System.Windows.Media.GradientStop]::new($start, 0.0)
            $rg.GradientStops.Add($stop0) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 0, 0, 0), 1.0)) | Out-Null
            $blob = New-Object System.Windows.Shapes.Ellipse
            $sz = $BannerH * 1.9
            $blob.Width = $sz; $blob.Height = $sz; $blob.Fill = $rg; $blob.Opacity = 0.6
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 36; $blob.Effect = $bl
            $blob.CacheMode = New-Object System.Windows.Media.BitmapCache
            $tt = New-Object System.Windows.Media.TranslateTransform
            $blob.RenderTransform = $tt
            $dur = 12.0 + $rand.NextDouble() * 6.0
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(40 + $rand.NextDouble() * 40); $ax.To = (40 + $rand.NextDouble() * 50)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            # A changing fill invalidates the cached blur every frame. The
            # palette remains visible across the three drifting blobs without
            # cycling every individual blob through every hue.
            [System.Windows.Controls.Canvas]::SetTop($blob, ($BannerH / 2) - ($sz / 2))
            [void]$canvas.Children.Add($blob)
            [void]$info.Add([pscustomobject]@{ el = $blob; sz = $sz; fx = (($i + 0.5) / 3.0) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerStripes {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rect = New-Object System.Windows.Shapes.Rectangle
        $rect.Height = $BannerH
        $cFaint = [System.Windows.Media.Color]::FromArgb(20, 52, 211, 153)
        $cClear = [System.Windows.Media.Color]::FromArgb(0, 52, 211, 153)
        $lg = New-Object System.Windows.Media.LinearGradientBrush
        $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(0.08, 0.08)
        $lg.SpreadMethod = [System.Windows.Media.GradientSpreadMethod]::Repeat
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($cFaint, 0.0)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($cFaint, 0.49)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($cClear, 0.5)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($cClear, 1.0)) | Out-Null
        $rt = New-Object System.Windows.Media.TranslateTransform
        $lg.RelativeTransform = $rt
        $rect.Fill = $lg
        $anx = New-Object System.Windows.Media.Animation.DoubleAnimation
        $anx.From = 0.0; $anx.To = 0.08
        $anx.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(6.0))
        $anx.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $rt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $anx)
        $any = New-Object System.Windows.Media.Animation.DoubleAnimation
        $any.From = 0.0; $any.To = 0.08
        $any.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(6.0))
        $any.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $rt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $any)
        [System.Windows.Controls.Canvas]::SetTop($rect, 0); [System.Windows.Controls.Canvas]::SetLeft($rect, 0)
        [void]$canvas.Children.Add($rect)
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }; $rect.Width = $cw; $rect.Height = $canvas.ActualHeight }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerTwinkle {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $dotBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(80, 230, 200)); $dotBrush.Freeze()
        $gap = 40.0; $fieldW = 2000.0
        $cols = [int]($fieldW / $gap)
        $rows = [int]($BannerH / $gap) + 1
        for ($r = 0; $r -lt $rows; $r++) {
            for ($c = 0; $c -lt $cols; $c++) {
                $d = New-Object System.Windows.Shapes.Ellipse
                $d.Width = 3.2; $d.Height = 3.2; $d.Fill = $dotBrush; $d.Opacity = 0
                [System.Windows.Controls.Canvas]::SetLeft($d, $c * $gap + ($gap / 2))
                [System.Windows.Controls.Canvas]::SetTop($d, $r * $gap + ($gap / 2))
                $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
                $oa.From = 0; $oa.To = 0.7
                $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(2.2)); $oa.AutoReverse = $true
                $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                $oa.BeginTime = [TimeSpan]::FromSeconds((($c + $r) % 12) * 0.18)
                $d.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
                [void]$canvas.Children.Add($d)
            }
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerRain {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $col = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(150, 195, 225)); $col.Freeze()
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 70; $i++) {
            $len = 8 + $rand.NextDouble() * 12
            $drop = New-Object System.Windows.Shapes.Rectangle
            $drop.Width = 1; $drop.Height = $len; $drop.RadiusX = 0.5; $drop.RadiusY = 0.5
            $drop.Fill = $col; $drop.Opacity = 0.1 + $rand.NextDouble() * 0.25
            $tt = New-Object System.Windows.Media.TranslateTransform
            $drop.RenderTransform = $tt
            [System.Windows.Controls.Canvas]::SetTop($drop, -$len)
            $dur = (1.4 + $rand.NextDouble() * 1.2)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = 0; $ay.To = ($BannerH + $len + 4)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            [void]$canvas.Children.Add($drop)
            [void]$info.Add([pscustomobject]@{ el = $drop; fx = $rand.NextDouble() })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($d in $info) { [System.Windows.Controls.Canvas]::SetLeft($d.el, $d.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerBokeh {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex, [string[]]$Palette)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cols = if ($Palette -and $Palette.Count -ge 2) { $Palette } else { @("#36e0e0","#3a8add","#c850ff","#34d399") }
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 10; $i++) {
            $c = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$i % $cols.Count])
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new($c, 0.0)) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $c.R, $c.G, $c.B), 1.0)) | Out-Null
            $sz = 34 + $rand.NextDouble() * 60
            $e = New-Object System.Windows.Shapes.Ellipse
            $e.Width = $sz; $e.Height = $sz; $e.Fill = $rg; $e.Opacity = 0.5
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 6 + $rand.NextDouble() * 14; $e.Effect = $bl
            $e.CacheMode = New-Object System.Windows.Media.BitmapCache
            $tt = New-Object System.Windows.Media.TranslateTransform
            $e.RenderTransform = $tt
            $durx = 9 + $rand.NextDouble() * 10
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(10 + $rand.NextDouble() * 14); $ax.To = (10 + $rand.NextDouble() * 14)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($durx)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $durx))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = -(6 + $rand.NextDouble() * 10); $ay.To = (6 + $rand.NextDouble() * 10)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($durx * 0.85)); $ay.AutoReverse = $true
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ay.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $durx))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $oa.From = 0.25; $oa.To = 0.65
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(5 + $rand.NextDouble() * 5)); $oa.AutoReverse = $true
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $oa.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * 5))
            $e.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            [System.Windows.Controls.Canvas]::SetTop($e, ((0.18 + $rand.NextDouble() * 0.64) * $BannerH) - ($sz / 2))
            [void]$canvas.Children.Add($e)
            [void]$info.Add([pscustomobject]@{ el = $e; sz = $sz; fx = (0.06 + $rand.NextDouble() * 0.88) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerShards {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cols = @("#36e0e0","#c850ff","#34d399","#3a8add")
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 40; $i++) {
            $s = 3 + $rand.NextDouble() * 4
            $poly = New-Object System.Windows.Shapes.Polygon
            $pts = New-Object System.Windows.Media.PointCollection
            $pts.Add([System.Windows.Point]::new(0, -$s)) | Out-Null
            $pts.Add([System.Windows.Point]::new($s, $s)) | Out-Null
            $pts.Add([System.Windows.Point]::new(-$s, $s)) | Out-Null
            $poly.Points = $pts
            $cc = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$i % $cols.Count])
            $poly.Fill = [System.Windows.Media.SolidColorBrush]::new($cc); $poly.Opacity = 0.2 + $rand.NextDouble() * 0.4
            $poly.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
            $tg = New-Object System.Windows.Media.TransformGroup
            $rot = [System.Windows.Media.RotateTransform]::new(0)
            $tt = New-Object System.Windows.Media.TranslateTransform
            $tg.Children.Add($rot) | Out-Null; $tg.Children.Add($tt) | Out-Null
            $poly.RenderTransform = $tg
            $rdur = 8 + $rand.NextDouble() * 10
            $ra = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ra.From = 0; $ra.To = 360
            $ra.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($rdur))
            $ra.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ra.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $rdur))
            $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $ra)
            $ddur = 6 + $rand.NextDouble() * 5
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -6; $ax.To = 6
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($ddur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $ddur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = -6; $ay.To = 6
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($ddur * 1.1)); $ay.AutoReverse = $true
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ay.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $ddur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            [System.Windows.Controls.Canvas]::SetTop($poly, $rand.NextDouble() * $BannerH)
            [void]$canvas.Children.Add($poly)
            [void]$info.Add([pscustomobject]@{ el = $poly; fx = $rand.NextDouble() })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, $o.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerWaves {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $lines = @(
            @{ r = 54; g = 224; b = 224; amp = 10; off = 0.50; wl = 240.0; dur = 9.0;  dir = -1 },
            @{ r = 52; g = 211; b = 153; amp = 7;  off = 0.62; wl = 180.0; dur = 7.0;  dir = 1 },
            @{ r = 58; g = 138; b = 221; amp = 13; off = 0.42; wl = 300.0; dur = 12.0; dir = -1 }
        )
        foreach ($L in $lines) {
            $poly = New-Object System.Windows.Shapes.Polyline
            $poly.Stroke = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(130, [byte]$L.r, [byte]$L.g, [byte]$L.b))
            $poly.StrokeThickness = 1.5
            $pts = New-Object System.Windows.Media.PointCollection
            $baseY = $L.off * $BannerH
            # Overhang past BOTH banner edges (same fix as the silk ribbons):
            # a line scrolling right (dir=+1) used to uncover a gap on the
            # left, one scrolling left (dir=-1) a gap on the right, until the
            # one-wavelength loop snapped back. The wave is periodic in wl and
            # the translate is exactly one wl, so with this overhang the line
            # spans the full width at all times - no shrinking, no snap.
            for ($x = -500; $x -le 3200; $x += 8) {
                $y = $baseY + $L.amp * [Math]::Sin(2 * [Math]::PI * $x / $L.wl)
                $pts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            $poly.Points = $pts
            $tt = New-Object System.Windows.Media.TranslateTransform
            $poly.RenderTransform = $tt
            $an = New-Object System.Windows.Media.Animation.DoubleAnimation
            $an.From = 0; $an.To = ($L.dir * $L.wl)
            $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($L.dur))
            $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
            [void]$canvas.Children.Add($poly)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerRays {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cols = @("#36e0e0","#34d399","#3a8add")
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 5; $i++) {
            $c = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$i % $cols.Count])
            $w = 40 + $rand.NextDouble() * 70
            $rect = New-Object System.Windows.Shapes.Rectangle
            $rect.Width = $w; $rect.Height = ($BannerH * 1.8)
            $lg = New-Object System.Windows.Media.LinearGradientBrush
            $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(1, 0)
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $c.R, $c.G, $c.B), 0.0)) | Out-Null
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(85, $c.R, $c.G, $c.B), 0.5)) | Out-Null
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $c.R, $c.G, $c.B), 1.0)) | Out-Null
            $rect.Fill = $lg
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 6; $rect.Effect = $bl
            $rect.CacheMode = New-Object System.Windows.Media.BitmapCache
            $tg = New-Object System.Windows.Media.TransformGroup
            $tg.Children.Add([System.Windows.Media.RotateTransform]::new(16)) | Out-Null
            $tt = New-Object System.Windows.Media.TranslateTransform
            $tg.Children.Add($tt) | Out-Null
            $rect.RenderTransform = $tg
            [System.Windows.Controls.Canvas]::SetTop($rect, -($BannerH * 0.4))
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $oa.From = 0.25; $oa.To = 0.7
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(8 + $rand.NextDouble() * 6)); $oa.AutoReverse = $true
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $oa.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * 8))
            $rect.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            $dxdur = 9 + $rand.NextDouble() * 5
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -10; $ax.To = 10
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dxdur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dxdur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            [void]$canvas.Children.Add($rect)
            [void]$info.Add([pscustomobject]@{ el = $rect; w = $w; fx = (($i + 0.5) / 5.0) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.w / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerLava {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cols = @("#dd6600","#ff7a3c","#ffb152")
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 3; $i++) {
            $c = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$i % $cols.Count])
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new($c, 0.0)) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $c.R, $c.G, $c.B), 1.0)) | Out-Null
            $sz = $BannerH * 0.95
            $e = New-Object System.Windows.Shapes.Ellipse
            $e.Width = $sz; $e.Height = $sz; $e.Fill = $rg; $e.Opacity = 0.6
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 14; $e.Effect = $bl
            $e.CacheMode = New-Object System.Windows.Media.BitmapCache
            $e.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
            $tg = New-Object System.Windows.Media.TransformGroup
            $sct = [System.Windows.Media.ScaleTransform]::new(1, 1)
            $tt = New-Object System.Windows.Media.TranslateTransform
            $tg.Children.Add($sct) | Out-Null; $tg.Children.Add($tt) | Out-Null
            $e.RenderTransform = $tg
            $sxd = 11 + $rand.NextDouble() * 5
            $sx = New-Object System.Windows.Media.Animation.DoubleAnimation
            $sx.From = 0.85; $sx.To = 1.15
            $sx.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($sxd)); $sx.AutoReverse = $true
            $sx.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $sx.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $sx.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $sxd))
            $sct.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $sx)
            $syd = 13 + $rand.NextDouble() * 5
            $sy = New-Object System.Windows.Media.Animation.DoubleAnimation
            $sy.From = 1.12; $sy.To = 0.88
            $sy.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($syd)); $sy.AutoReverse = $true
            $sy.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $sy.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $sy.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $syd))
            $sct.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $sy)
            $tyd = 14 + $rand.NextDouble() * 6
            $ty = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ty.From = -($BannerH * 0.12); $ty.To = ($BannerH * 0.12)
            $ty.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($tyd)); $ty.AutoReverse = $true
            $ty.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ty.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ty.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $tyd))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ty)
            [System.Windows.Controls.Canvas]::SetTop($e, ($BannerH / 2) - ($sz / 2))
            [void]$canvas.Children.Add($e)
            [void]$info.Add([pscustomobject]@{ el = $e; sz = $sz; fx = (($i + 0.5) / 3.0) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerTopo {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $ribbons = @(
            @{ r = 125; g = 211; b = 252; off = 0.42; amp = 14; w = 26; wl = 300.0; dur = 10.0; dir = -1 },
            @{ r = 59;  g = 130; b = 246; off = 0.55; amp = 18; w = 30; wl = 380.0; dur = 13.0; dir = 1 },
            @{ r = 94;  g = 234; b = 212; off = 0.66; amp = 11; w = 22; wl = 240.0; dur = 8.0;  dir = -1 }
        )
        foreach ($rb in $ribbons) {
            $baseY = $rb.off * $BannerH
            # Extend each ribbon well PAST both banner edges instead of
            # starting at x=0. A ribbon that drifts right (dir = +1) used to
            # move its left edge inward, uncovering a blank gap on the left
            # that grew until the loop wrapped - looking like the band got
            # shorter and then snapped back. The wave is periodic in wl and the
            # translate is exactly one wl, so with this overhang on both sides
            # the scroll stays seamless: full width at all times, no visible
            # jump.
            $x0 = -500; $x1 = 3200
            $fig = New-Object System.Windows.Media.PathFigure
            $fig.StartPoint = [System.Windows.Point]::new($x0, $baseY)
            $polyPts = New-Object System.Windows.Media.PointCollection
            for ($x = $x0; $x -le $x1; $x += 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl)
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            for ($x = $x1; $x -ge $x0; $x -= 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl) + $rb.w
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            $polySeg = New-Object System.Windows.Media.PolyLineSegment
            $polySeg.Points = $polyPts
            $fig.Segments.Add($polySeg) | Out-Null; $fig.IsClosed = $true
            $geo = New-Object System.Windows.Media.PathGeometry
            $geo.Figures.Add($fig) | Out-Null
            $path = New-Object System.Windows.Shapes.Path
            $path.Data = $geo
            $path.Fill = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(70, [byte]$rb.r, [byte]$rb.g, [byte]$rb.b))
            $tt = New-Object System.Windows.Media.TranslateTransform
            $path.RenderTransform = $tt
            $an = New-Object System.Windows.Media.Animation.DoubleAnimation
            $an.From = 0; $an.To = ($rb.dir * $rb.wl)
            $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($rb.dur))
            $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
            [void]$canvas.Children.Add($path)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerVortex {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex,
          # 0.5 = centre of the image (the default, as before). Other
          # values place the galaxy off to one side so two fit next to
          # each other.
          [double]$CenterFrac = 0.5, [double]$Scale = 1.0)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $dotBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(120, 210, 255)); $dotBrush.Freeze()
        $n = 90; $maxR = $BannerH * 0.42
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $n; $i++) {
            $theta = $i * 0.5
            $radd = ($i / ($n - 1.0)) * $maxR
            $sz = 0.8 + $rand.NextDouble() * 1.4
            $dot = New-Object System.Windows.Shapes.Ellipse
            $dot.Width = $sz; $dot.Height = $sz; $dot.Fill = $dotBrush; $dot.Opacity = 0.15 + $rand.NextDouble() * 0.4
            [void]$canvas.Children.Add($dot)
            [void]$info.Add([pscustomobject]@{ el = $dot; th = $theta; rad = $radd; sz = $sz })
        }
        $rot = [System.Windows.Media.RotateTransform]::new(0)
        $canvas.RenderTransform = $rot
        $canvas.CacheMode = New-Object System.Windows.Media.BitmapCache
        $ra = New-Object System.Windows.Media.Animation.DoubleAnimation
        $ra.From = 0; $ra.To = 360
        $ra.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(22.0))
        $ra.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $ra)
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            $cx = $cw * $CenterFrac; $cy = $BannerH / 2; $rot.CenterX = $cx; $rot.CenterY = $cy
            foreach ($o in $info) {
                [System.Windows.Controls.Canvas]::SetLeft($o.el, $cx + [Math]::Cos($o.th) * $o.rad * 1.8 * $Scale - ($o.sz / 2))
                [System.Windows.Controls.Canvas]::SetTop($o.el, $cy + [Math]::Sin($o.th) * $o.rad * $Scale - ($o.sz / 2))
            } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSnow {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $flake = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(225, 240, 250)); $flake.Freeze()
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 50; $i++) {
            $d = 2 + $rand.NextDouble() * 3
            $e = New-Object System.Windows.Shapes.Ellipse
            $e.Width = $d; $e.Height = $d; $e.Fill = $flake; $e.Opacity = 0.3 + $rand.NextDouble() * 0.5
            $tt = New-Object System.Windows.Media.TranslateTransform
            $e.RenderTransform = $tt
            [System.Windows.Controls.Canvas]::SetTop($e, -3)
            $ydur = 6 + $rand.NextDouble() * 5
            # Fall the full L-size distance regardless of the current banner
            # height (smaller sizes just clip the bottom). Duration scales with
            # it so the speed stays identical - no resize handling, stays smooth.
            $fall = [Math]::Max($BannerH, 224.0) + 6
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = 0; $ay.To = $fall
            # Actual fall duration (scales with $fall so speed stays constant
            # across banner sizes). Seed the negative BeginTime from the SAME
            # duration so flakes start spread over the WHOLE fall - otherwise
            # they only fill the top portion at t=0 and fall as one clump.
            $actualDur = $ydur * $fall / ($BannerH + 6)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($actualDur))
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $actualDur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            $xdur = 3 + $rand.NextDouble() * 2
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(4 + $rand.NextDouble() * 8); $ax.To = (4 + $rand.NextDouble() * 8)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($xdur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $xdur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            [void]$canvas.Children.Add($e)
            [void]$info.Add([pscustomobject]@{ el = $e; fx = $rand.NextDouble() })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, $o.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerBreathe {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $specs = @(
            @{ col = "#34d399"; fx = 0.5; fy = 0.5;  dur = 7.0; phase = 0.0 },
            @{ col = "#3a8add"; fx = 0.2; fy = 1.05; dur = 9.0; phase = 1.5 }
        )
        $info = New-Object System.Collections.ArrayList
        foreach ($s in $specs) {
            $c = [System.Windows.Media.ColorConverter]::ConvertFromString($s.col)
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(85, $c.R, $c.G, $c.B), 0.0)) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $c.R, $c.G, $c.B), 1.0)) | Out-Null
            $e = New-Object System.Windows.Shapes.Ellipse
            $e.Fill = $rg
            $e.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
            $st = [System.Windows.Media.ScaleTransform]::new(1, 1)
            $e.RenderTransform = $st
            $sc = New-Object System.Windows.Media.Animation.DoubleAnimation
            $sc.From = 1.0; $sc.To = 1.12
            $sc.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($s.dur)); $sc.AutoReverse = $true
            $sc.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $sc.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $sc.BeginTime = [TimeSpan]::FromSeconds(-$s.phase)
            $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $sc)
            $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $sc)
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $oa.From = 0.25; $oa.To = 0.7
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($s.dur)); $oa.AutoReverse = $true
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $oa.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $oa.BeginTime = [TimeSpan]::FromSeconds(-$s.phase)
            $e.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            [void]$canvas.Children.Add($e)
            [void]$info.Add([pscustomobject]@{ el = $e; fx = $s.fx; fy = $s.fy })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            $size = ([Math]::Max($cw, $BannerH)) * 1.4
            foreach ($o in $info) { $o.el.Width = $size; $o.el.Height = $size
                [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($size / 2))
                [System.Windows.Controls.Canvas]::SetTop($o.el, ($o.fy * $BannerH) - ($size / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerMatrix {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $glyphs = "01<>=*+-/#$%&?XY".ToCharArray()
        $fs = 13.0; $spacing = 20.0; $stripH = $BannerH + 60.0
        $lines = [int]($stripH / $fs) + 1
        $nCols = [int](1600 / $spacing)
        $fam = New-Object System.Windows.Media.FontFamily("Consolas")
        for ($c = 0; $c -lt $nCols; $c++) {
            $sb = New-Object System.Text.StringBuilder
            for ($l = 0; $l -lt $lines; $l++) {
                [void]$sb.Append($glyphs[$rand.Next(0, $glyphs.Length)])
                if ($l -lt ($lines - 1)) { [void]$sb.Append("`n") }
            }
            $tb = New-Object System.Windows.Controls.TextBlock
            $tb.Text = $sb.ToString(); $tb.FontFamily = $fam; $tb.FontSize = $fs
            $tb.LineHeight = $fs; $tb.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
            $tb.TextAlignment = [System.Windows.TextAlignment]::Center
            $tb.Foreground = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(52, 211, 153))
            $mask = New-Object System.Windows.Media.LinearGradientBrush
            $mask.StartPoint = [System.Windows.Point]::new(0, 0); $mask.EndPoint = [System.Windows.Point]::new(0, 1)
            $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 255, 255, 255), 0.0)) | Out-Null
            $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 255, 255, 255), 0.85)) | Out-Null
            $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 255, 255, 255), 1.0)) | Out-Null
            $tb.OpacityMask = $mask; $tb.Opacity = 0.85
            $tt = New-Object System.Windows.Media.TranslateTransform
            $tb.RenderTransform = $tt
            [System.Windows.Controls.Canvas]::SetLeft($tb, $c * $spacing)
            [System.Windows.Controls.Canvas]::SetTop($tb, -$stripH)
            $dur = (2.5 + $rand.NextDouble() * 2.0) * 1.3333
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = 0; $ay.To = ($stripH + $BannerH)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            [void]$canvas.Children.Add($tb)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerHyper {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $brush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(190, 220, 255)); $brush.Freeze()
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 90; $i++) {
            $streak = New-Object System.Windows.Shapes.Rectangle
            $streak.Width = 10; $streak.Height = 2.6; $streak.Fill = $brush; $streak.RadiusX = 1; $streak.RadiusY = 1
            $tg = New-Object System.Windows.Media.TransformGroup
            $sx = [System.Windows.Media.ScaleTransform]::new(1, 1)
            $tt = New-Object System.Windows.Media.TranslateTransform
            $rotd = $rand.NextDouble() * 360.0
            $tg.Children.Add($sx) | Out-Null; $tg.Children.Add($tt) | Out-Null
            $tg.Children.Add([System.Windows.Media.RotateTransform]::new($rotd)) | Out-Null
            $streak.RenderTransform = $tg
            $dur = (1.4 + $rand.NextDouble() * 1.2) * 2.0
            $bt = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $at = New-Object System.Windows.Media.Animation.DoubleAnimation
            $at.From = 0; $at.To = 1400
            $at.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $at.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $at.BeginTime = $bt
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $at)
            $asx = New-Object System.Windows.Media.Animation.DoubleAnimation
            $asx.From = 0.5; $asx.To = 14
            $asx.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $asx.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $asx.BeginTime = $bt
            $sx.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $asx)
            $ao = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ao.From = 0.0; $ao.To = 0.9
            $ao.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ao.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ao.BeginTime = $bt
            $streak.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $ao)
            [void]$canvas.Children.Add($streak)
            [void]$info.Add($streak)
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($s in $info) { [System.Windows.Controls.Canvas]::SetLeft($s, $cw / 2); [System.Windows.Controls.Canvas]::SetTop($s, $BannerH / 2) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerTunnel {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $stroke = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(80, 200, 255)); $stroke.Freeze()
        $n = 10; $maxR = $BannerH * 0.95
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $n; $i++) {
            $hex = New-Object System.Windows.Shapes.Polygon
            $pts = New-Object System.Windows.Media.PointCollection
            for ($k = 0; $k -lt 6; $k++) {
                $a = $k * [Math]::PI / 3.0
                $pts.Add([System.Windows.Point]::new([Math]::Cos($a) * 1.7 * $maxR, [Math]::Sin($a) * $maxR)) | Out-Null
            }
            $hex.Points = $pts; $hex.Stroke = $stroke; $hex.StrokeThickness = 2.0; $hex.Fill = $null
            $st = [System.Windows.Media.ScaleTransform]::new(0.12, 0.12)
            $hex.RenderTransform = $st
            $dur = 16.0
            $bt = [TimeSpan]::FromSeconds(-(($i / [double]$n) * $dur))
            $sa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $sa.From = 0.12; $sa.To = 1.0
            $sa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $sa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $sa.BeginTime = $bt
            $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $sa)
            $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $sa)
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $oa.BeginTime = $bt
            $oa.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(0)))) | Out-Null
            $oa.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.85, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.15)))) | Out-Null
            $oa.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.85, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.78)))) | Out-Null
            $oa.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur)))) | Out-Null
            $hex.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            [void]$canvas.Children.Add($hex)
            [void]$info.Add($hex)
        }
        $rot = [System.Windows.Media.RotateTransform]::new(0)
        $canvas.RenderTransform = $rot
        $ra = New-Object System.Windows.Media.Animation.DoubleAnimation
        $ra.From = 0; $ra.To = 360
        $ra.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(60.0))
        $ra.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $ra)
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            $cx = $cw / 2; $cy = $BannerH / 2; $rot.CenterX = $cx; $rot.CenterY = $cy
            foreach ($h in $info) { [System.Windows.Controls.Canvas]::SetLeft($h, $cx); [System.Windows.Controls.Canvas]::SetTop($h, $cy) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerKaleido {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $ribbons = @(
            @{ r = 245; g = 166; b = 35; off = 0.42; amp = 14; w = 26; wl = 300.0; dur = 10.0; dir = -1 },
            @{ r = 244; g = 114; b = 182; off = 0.55; amp = 18; w = 30; wl = 380.0; dur = 13.0; dir = 1 },
            @{ r = 251; g = 113; b = 133; off = 0.66; amp = 11; w = 22; wl = 240.0; dur = 8.0;  dir = -1 }
        )
        foreach ($rb in $ribbons) {
            $baseY = $rb.off * $BannerH
            # Extend each ribbon well PAST both banner edges instead of
            # starting at x=0. A ribbon that drifts right (dir = +1) used to
            # move its left edge inward, uncovering a blank gap on the left
            # that grew until the loop wrapped - looking like the band got
            # shorter and then snapped back. The wave is periodic in wl and the
            # translate is exactly one wl, so with this overhang on both sides
            # the scroll stays seamless: full width at all times, no visible
            # jump.
            $x0 = -500; $x1 = 3200
            $fig = New-Object System.Windows.Media.PathFigure
            $fig.StartPoint = [System.Windows.Point]::new($x0, $baseY)
            $polyPts = New-Object System.Windows.Media.PointCollection
            for ($x = $x0; $x -le $x1; $x += 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl)
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            for ($x = $x1; $x -ge $x0; $x -= 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl) + $rb.w
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            $polySeg = New-Object System.Windows.Media.PolyLineSegment
            $polySeg.Points = $polyPts
            $fig.Segments.Add($polySeg) | Out-Null; $fig.IsClosed = $true
            $geo = New-Object System.Windows.Media.PathGeometry
            $geo.Figures.Add($fig) | Out-Null
            $path = New-Object System.Windows.Shapes.Path
            $path.Data = $geo
            $path.Fill = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(70, [byte]$rb.r, [byte]$rb.g, [byte]$rb.b))
            $tt = New-Object System.Windows.Media.TranslateTransform
            $path.RenderTransform = $tt
            $an = New-Object System.Windows.Media.Animation.DoubleAnimation
            $an.From = 0; $an.To = ($rb.dir * $rb.wl)
            $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($rb.dur))
            $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
            [void]$canvas.Children.Add($path)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerComet {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $br = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(120, 220, 255)); $br.Freeze()
        $brHead = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(225, 245, 255)); $brHead.Freeze()
        $nTrail = 36; $delta = 1.3
        $dur = 6.0 * 1.3333
        $orbit = New-Object System.Windows.Controls.Canvas
        $orbit.IsHitTestVisible = $false
        $orbit.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
        $squish = [System.Windows.Media.ScaleTransform]::new(1, 1)
        $orbit.RenderTransform = $squish
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $nTrail; $i++) {
            $frac = $i / ($nTrail - 1.0)
            $d = 2.0 + (1 - $frac) * 11.0
            $dot = New-Object System.Windows.Shapes.Ellipse
            $dot.Width = $d; $dot.Height = $d
            $dot.Fill = if ($i -le 1) { $brHead } else { $br }
            $dot.Opacity = [Math]::Pow((1 - $frac), 1.4) * 0.8 + 0.04
            if ($i -eq 0) {
                # Glowing head ball: bright core + soft halo.
                $gl = New-Object System.Windows.Media.Effects.BlurEffect; $gl.Radius = 10; $dot.Effect = $gl; $dot.Opacity = 1.0
                $dot.CacheMode = New-Object System.Windows.Media.BitmapCache
            } elseif ($i -le 3) {
                # A couple of near-head dots glow too so the ball reads as luminous, not a hard disc.
                $gl2 = New-Object System.Windows.Media.Effects.BlurEffect; $gl2.Radius = 4; $dot.Effect = $gl2
                $dot.CacheMode = New-Object System.Windows.Media.BitmapCache
            }
            $rot = [System.Windows.Media.RotateTransform]::new(0)
            $dot.RenderTransform = $rot
            $start = -($i * $delta)
            $ra = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ra.From = $start; $ra.To = ($start + 360)
            $ra.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ra.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $ra)
            [void]$orbit.Children.Add($dot)
            [void]$info.Add([pscustomobject]@{ el = $dot; rot = $rot; d = $d })
        }
        [void]$canvas.Children.Add($orbit)
        $reflow = { $cw = $canvas.ActualWidth; $ch = $canvas.ActualHeight
            if ($cw -lt 20) { return }
            if ($ch -lt 20) { $ch = $BannerH }
            $Rx = $cw * 0.34; $Ry = $ch * 0.30
            $orbit.Width = $cw; $orbit.Height = $ch
            if ($Rx -gt 0) { $squish.ScaleY = $Ry / $Rx }
            foreach ($o in $info) {
                [System.Windows.Controls.Canvas]::SetLeft($o.el, ($cw / 2) + $Rx - ($o.d / 2))
                [System.Windows.Controls.Canvas]::SetTop($o.el, ($ch / 2) - ($o.d / 2))
                $o.rot.CenterX = ($o.d / 2) - $Rx
                $o.rot.CenterY = ($o.d / 2)
            } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSpark {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $nEmit = 10; $perEmit = 7
        $info = New-Object System.Collections.ArrayList
        for ($e = 0; $e -lt $nEmit; $e++) {
            $fx = ($e + 0.5) / $nEmit
            $isBottom = (($e % 2) -eq 0)
            $emitY = if ($isBottom) { $BannerH * 0.90 } else { $BannerH * 0.10 }
            for ($s = 0; $s -lt $perEmit; $s++) {
                $sp = New-Object System.Windows.Shapes.Ellipse
                $sp.Width = 2.2; $sp.Height = 2.2
                $warm = if ($rand.NextDouble() -lt 0.5) { [System.Windows.Media.Color]::FromRgb(255, 200, 120) } else { [System.Windows.Media.Color]::FromRgb(255, 150, 80) }
                $sp.Fill = [System.Windows.Media.SolidColorBrush]::new($warm)
                $tt = New-Object System.Windows.Media.TranslateTransform
                $sp.RenderTransform = $tt
                [System.Windows.Controls.Canvas]::SetTop($sp, $emitY)
                $dur = 1.2 + $rand.NextDouble() * 1.0
                $sbt = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
                $vx = ($rand.NextDouble() - 0.5) * 280
                $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
                $ax.From = 0; $ax.To = $vx
                $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
                $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.BeginTime = $sbt
                $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
                $ay = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
                $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
                $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ay.BeginTime = $sbt
                $eUp = New-Object System.Windows.Media.Animation.QuadraticEase; $eUp.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
                $eDn = New-Object System.Windows.Media.Animation.QuadraticEase; $eDn.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseIn
                if ($isBottom) {
                    $peak = -(($BannerH * 0.45) + $rand.NextDouble() * ($BannerH * 0.40))
                    $ay.KeyFrames.Add([System.Windows.Media.Animation.EasingDoubleKeyFrame]::new($peak, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.40)), $eUp)) | Out-Null
                    $ay.KeyFrames.Add([System.Windows.Media.Animation.EasingDoubleKeyFrame]::new(($peak * 0.45), [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur)), $eDn)) | Out-Null
                } else {
                    $pop  = -(($BannerH * 0.05) + $rand.NextDouble() * ($BannerH * 0.10))
                    $fall =  (($BannerH * 0.55) + $rand.NextDouble() * ($BannerH * 0.30))
                    $ay.KeyFrames.Add([System.Windows.Media.Animation.EasingDoubleKeyFrame]::new($pop, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.25)), $eUp)) | Out-Null
                    $ay.KeyFrames.Add([System.Windows.Media.Animation.EasingDoubleKeyFrame]::new($fall, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur)), $eDn)) | Out-Null
                }
                $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
                $op = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
                $op.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
                $op.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $op.BeginTime = $sbt
                $op.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(0)))) | Out-Null
                $op.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(1.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.06)))) | Out-Null
                $op.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(1.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.55)))) | Out-Null
                $op.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur)))) | Out-Null
                $sp.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $op)
                [void]$canvas.Children.Add($sp)
                [void]$info.Add([pscustomobject]@{ el = $sp; fx = $fx })
            }
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, $o.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerField {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $seg = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(102, 52, 211, 153)); $seg.Freeze()
        $spacing = 32.0
        $build = {
            $cw = $canvas.ActualWidth; $ch = $canvas.ActualHeight
            if ($cw -lt 20 -or $ch -lt 20) { return }
            $canvas.Children.Clear()
            $cols = [int]([Math]::Ceiling($cw / $spacing)) + 1
            $rows = [int]([Math]::Ceiling($ch / $spacing)) + 1
            for ($r = 0; $r -lt $rows; $r++) {
                for ($c = 0; $c -lt $cols; $c++) {
                    $tick = New-Object System.Windows.Shapes.Rectangle
                    $tick.Width = 14; $tick.Height = 1.2; $tick.Fill = $seg
                    $tick.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
                    $rot = [System.Windows.Media.RotateTransform]::new(0)
                    $tick.RenderTransform = $rot
                    [System.Windows.Controls.Canvas]::SetLeft($tick, $c * $spacing - 7)
                    [System.Windows.Controls.Canvas]::SetTop($tick, $r * $spacing)
                    $base = (($c + $r) * 20) % 360
                    $aa = New-Object System.Windows.Media.Animation.DoubleAnimation
                    $aa.From = ($base - 40); $aa.To = ($base + 40)
                    $aa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(6.0)); $aa.AutoReverse = $true
                    $aa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $aa.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
                    $aa.BeginTime = [TimeSpan]::FromSeconds(-((($c + $r) % 8) * 0.4))
                    $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $aa)
                    [void]$canvas.Children.Add($tick)
                }
            }
        }.GetNewClosure()
        $canvas.Add_SizeChanged($build); & $build
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSilk {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $ribbons = @(
            @{ r = 54;  g = 224; b = 224; off = 0.42; amp = 14; w = 26; wl = 300.0; dur = 10.0; dir = -1 },
            @{ r = 200; g = 80;  b = 255; off = 0.55; amp = 18; w = 30; wl = 380.0; dur = 13.0; dir = 1 },
            @{ r = 52;  g = 211; b = 153; off = 0.66; amp = 11; w = 22; wl = 240.0; dur = 8.0;  dir = -1 }
        )
        foreach ($rb in $ribbons) {
            $baseY = $rb.off * $BannerH
            # Extend each ribbon well PAST both banner edges instead of
            # starting at x=0. A ribbon that drifts right (dir = +1) used to
            # move its left edge inward, uncovering a blank gap on the left
            # that grew until the loop wrapped - looking like the band got
            # shorter and then snapped back. The wave is periodic in wl and the
            # translate is exactly one wl, so with this overhang on both sides
            # the scroll stays seamless: full width at all times, no visible
            # jump.
            $x0 = -500; $x1 = 3200
            $fig = New-Object System.Windows.Media.PathFigure
            $fig.StartPoint = [System.Windows.Point]::new($x0, $baseY)
            $polyPts = New-Object System.Windows.Media.PointCollection
            for ($x = $x0; $x -le $x1; $x += 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl)
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            for ($x = $x1; $x -ge $x0; $x -= 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl) + $rb.w
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            $polySeg = New-Object System.Windows.Media.PolyLineSegment
            $polySeg.Points = $polyPts
            $fig.Segments.Add($polySeg) | Out-Null; $fig.IsClosed = $true
            $geo = New-Object System.Windows.Media.PathGeometry
            $geo.Figures.Add($fig) | Out-Null
            $path = New-Object System.Windows.Shapes.Path
            $path.Data = $geo
            $path.Fill = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(70, [byte]$rb.r, [byte]$rb.g, [byte]$rb.b))
            $tt = New-Object System.Windows.Media.TranslateTransform
            $path.RenderTransform = $tt
            $an = New-Object System.Windows.Media.Animation.DoubleAnimation
            $an.From = 0; $an.To = ($rb.dir * $rb.wl)
            $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($rb.dur))
            $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
            [void]$canvas.Children.Add($path)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerBubbles {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $ringBr = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(150, 225, 235)); $ringBr.Freeze()
        $hlBr = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(220, 250, 255)); $hlBr.Freeze()
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 42; $i++) {
            $rr = 4 + $rand.NextDouble() * 8; $d = $rr * 2
            $bc = New-Object System.Windows.Controls.Canvas
            $bc.Width = $d; $bc.Height = $d; $bc.IsHitTestVisible = $false; $bc.Opacity = 0.3 + $rand.NextDouble() * 0.3
            $ring = New-Object System.Windows.Shapes.Ellipse
            $ring.Width = $d; $ring.Height = $d; $ring.Stroke = $ringBr; $ring.StrokeThickness = 1.2; $ring.Fill = $null
            [System.Windows.Controls.Canvas]::SetLeft($ring, 0); [System.Windows.Controls.Canvas]::SetTop($ring, 0)
            $hl = New-Object System.Windows.Shapes.Ellipse
            $hl.Width = ($d * 0.26); $hl.Height = ($d * 0.26); $hl.Fill = $hlBr
            [System.Windows.Controls.Canvas]::SetLeft($hl, $d * 0.22); [System.Windows.Controls.Canvas]::SetTop($hl, $d * 0.2)
            [void]$bc.Children.Add($ring); [void]$bc.Children.Add($hl)
            $tt = New-Object System.Windows.Media.TranslateTransform
            $bc.RenderTransform = $tt
            [System.Windows.Controls.Canvas]::SetTop($bc, $BannerH + 10)
            $ydur = 7 + $rand.NextDouble() * 5
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = 0; $ay.To = -($BannerH + 20 + $d)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($ydur))
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $ydur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            $xdur = 3 + $rand.NextDouble() * 2
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(5 + $rand.NextDouble() * 6); $ax.To = (5 + $rand.NextDouble() * 6)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($xdur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $xdur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            [void]$canvas.Children.Add($bc)
            [void]$info.Add([pscustomobject]@{ el = $bc; fx = $rand.NextDouble() })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, $o.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

# Dispatcher: route a banner to one of the animated effects.
function global:Add-BannerEffect {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex, [string]$Effect)
    switch ($Effect) {
        "parallax" { Add-BannerParallax  -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "nebula"    { Add-BannerNebula    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "meteors"   { Add-BannerMeteors   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "sonar"     { Add-BannerSonar     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "motes"     { Add-BannerMotes     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "equalizer" { Add-BannerEqualizer -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "speed"     { Add-BannerSpeed     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "flow"      { Add-BannerFlow      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "plasma"    { Add-BannerPlasma    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "blobsunset" { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#ff7a4d","#ffb020","#ff4d80","#ff9a3d") }
        "blobcandy"  { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#ff5fa2","#a45cff","#36d0e0","#ff8fd0") }
        "blobocean"  { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#16d0a0","#2ab0ff","#4de0d0","#3a8add") }
        "blobember"  { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#ff4d2e","#ff8a1e","#ffd24d","#e0341e") }
        "blobtoxic"  { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#8aff3a","#34e07a","#c8ff2e","#2ee0a0") }
        "blobice"    { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#8ad8ff","#4db8ff","#a0e8ff","#5de0e0") }
        "blobviolet" { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#c850ff","#8a5cff","#ff5fd0","#6a4dff") }
        "blobmidnight" { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#3a5cff","#6a4dff","#2a8aff","#4d5cff") }
        "blobamber"    { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#ffb020","#2ab0ff","#ffd24d","#3a8add") }
        "blobrose"     { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#ff5f8a","#ff8fb0","#ff4d6a","#ffa0c0") }
        "blobforest"   { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#34d399","#a0e04d","#2ab08a","#c8ff6a") }
        "stripes"   { Add-BannerStripes   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "twinkle"   { Add-BannerTwinkle   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "rain"      { Add-BannerRain      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "bokeh"     { Add-BannerBokeh     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "bokehsunset" { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#ff7a4d","#ffb020","#ff4d80","#ff9a3d") }
        "bokehcandy"  { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#ff5fa2","#a45cff","#36d0e0","#ff8fd0") }
        "bokehember"  { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#ff4d2e","#ff8a1e","#ffd24d","#e0341e") }
        "bokehtoxic"  { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#8aff3a","#34e07a","#c8ff2e","#2ee0a0") }
        "bokehviolet" { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#c850ff","#8a5cff","#ff5fd0","#6a4dff") }
        "bokehmidnight" { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#3a5cff","#6a4dff","#2a8aff","#4d5cff") }
        "bokehgold"     { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#ffcf4d","#8a5cff","#ffe08a","#6a4dff") }
        "bokehmint"     { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#4de0c0","#8affd0","#2ec0a0","#a0ffe0") }
        "bokehcoral"    { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#ff6a4d","#ff9a3d","#ffd24d","#ff4d7a") }
        "shards"    { Add-BannerShards    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "waves"     { Add-BannerWaves     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "rays"      { Add-BannerRays      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "lava"      { Add-BannerLava      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "topo"      { Add-BannerTopo      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "vortex"    { Add-BannerVortex    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "snow"      { Add-BannerSnow      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "breathe"   { Add-BannerBreathe   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "matrix"    { Add-BannerMatrix    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "hyper"     { Add-BannerHyper     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "tunnel"    { Add-BannerTunnel    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "kaleido"   { Add-BannerKaleido   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "comet"     { Add-BannerComet     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "spark"     { Add-BannerSpark     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "field"     { Add-BannerField     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "silk"      { Add-BannerSilk      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "bubbles"   { Add-BannerBubbles   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        # ---- Colour variants (2026-08-16) --------------------------
        # The same animation, only the colour is pinned instead of
        # following the banner accent. Five per effect.
        "sparkgold"     { Add-BannerSpark -BannerName $BannerName -BannerH $BannerH -ColorHex "#ffc247" }
        "sparkice"      { Add-BannerSpark -BannerName $BannerName -BannerH $BannerH -ColorHex "#7fd8ff" }
        "sparkviolet"   { Add-BannerSpark -BannerName $BannerName -BannerH $BannerH -ColorHex "#c07bff" }
        "sparkblood"    { Add-BannerSpark -BannerName $BannerName -BannerH $BannerH -ColorHex "#ff3b30" }
        "sparkmint"     { Add-BannerSpark -BannerName $BannerName -BannerH $BannerH -ColorHex "#4fe0a8" }
        "bubblesdeep"   { Add-BannerBubbles -BannerName $BannerName -BannerH $BannerH -ColorHex "#2f8fd8" }
        "bubblestoxic"  { Add-BannerBubbles -BannerName $BannerName -BannerH $BannerH -ColorHex "#8aff3a" }
        "bubblesgold"   { Add-BannerBubbles -BannerName $BannerName -BannerH $BannerH -ColorHex "#ffcf5c" }
        "bubblesviolet" { Add-BannerBubbles -BannerName $BannerName -BannerH $BannerH -ColorHex "#b06bff" }
        "bubblesmono"   { Add-BannerBubbles -BannerName $BannerName -BannerH $BannerH -ColorHex "#cfd8e3" }
        "meteorsember"  { Add-BannerMeteors -BannerName $BannerName -BannerH $BannerH -ColorHex "#ff7a1a" }
        "meteorsice"    { Add-BannerMeteors -BannerName $BannerName -BannerH $BannerH -ColorHex "#8fe4ff" }
        "meteorstoxic"  { Add-BannerMeteors -BannerName $BannerName -BannerH $BannerH -ColorHex "#9bff5a" }
        "meteorsrose"   { Add-BannerMeteors -BannerName $BannerName -BannerH $BannerH -ColorHex "#ff5f8a" }
        "meteorsgold"   { Add-BannerMeteors -BannerName $BannerName -BannerH $BannerH -ColorHex "#ffd36e" }
        "hexcyan"       { Add-BannerHex -BannerName $BannerName -BannerH $BannerH -ColorHex "#8fd3e2" }
        "hexmagenta"    { Add-BannerHex -BannerName $BannerName -BannerH $BannerH -ColorHex "#dda2bf" }
        "hexlime"       { Add-BannerHex -BannerName $BannerName -BannerH $BannerH -ColorHex "#bcd8a0" }
        "hexamber"      { Add-BannerHex -BannerName $BannerName -BannerH $BannerH -ColorHex "#e0c599" }
        "hexsteel"      { Add-BannerHex -BannerName $BannerName -BannerH $BannerH -ColorHex "#b9c4cf" }
        "fieldcyan"     { Add-BannerField -BannerName $BannerName -BannerH $BannerH -ColorHex "#39d8ff" }
        "fieldrose"     { Add-BannerField -BannerName $BannerName -BannerH $BannerH -ColorHex "#ff6fa8" }
        "fieldgold"     { Add-BannerField -BannerName $BannerName -BannerH $BannerH -ColorHex "#ffc95c" }
        "fieldtoxic"    { Add-BannerField -BannerName $BannerName -BannerH $BannerH -ColorHex "#93ff4d" }
        "fieldsteel"    { Add-BannerField -BannerName $BannerName -BannerH $BannerH -ColorHex "#a8bccd" }
        "vortexgold"    { Add-BannerVortex -BannerName $BannerName -BannerH $BannerH -ColorHex "#ffcb57" }
        "vortexice"     { Add-BannerVortex -BannerName $BannerName -BannerH $BannerH -ColorHex "#7fd0ff" }
        "vortexrose"    { Add-BannerVortex -BannerName $BannerName -BannerH $BannerH -ColorHex "#ff6fa8" }
        "vortextoxic"   { Add-BannerVortex -BannerName $BannerName -BannerH $BannerH -ColorHex "#8dff5c" }
        "vortexviolet"  { Add-BannerVortex -BannerName $BannerName -BannerH $BannerH -ColorHex "#b478ff" }
        # Two galaxies instead of one - the same function twice, offset
        # and a little smaller so they fit side by side.
        "vortextwin"  { Add-BannerVortex -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex -CenterFrac 0.36 -Scale 0.72
                        Add-BannerVortex -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex -CenterFrac 0.64 -Scale 0.72 }
        "vortextwinice"  { Add-BannerVortex -BannerName $BannerName -BannerH $BannerH -ColorHex "#7fd0ff" -CenterFrac 0.36 -Scale 0.72
                           Add-BannerVortex -BannerName $BannerName -BannerH $BannerH -ColorHex "#7fd0ff" -CenterFrac 0.64 -Scale 0.72 }
        # Theme-fitting recolours of existing effects. Same animation code,
        # only the colour is pinned instead of following the banner accent.
        # These names are deliberately NOT in $global:BannerFxPool - they are
        # added as candidates per game by Get-BannerFxFor, like "synth"/"flow".
        "bloodrain"   { Add-BannerRain    -BannerName $BannerName -BannerH $BannerH -ColorHex "#c81028" }
        "bloodsnow"   { Add-BannerSnow    -BannerName $BannerName -BannerH $BannerH -ColorHex "#d42a2a" }
        "pinkbubbles" { Add-BannerBubbles -BannerName $BannerName -BannerH $BannerH -ColorHex "#ff8fd0" }
        "orbs"    { Add-BannerOrbs      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "synth"   { Add-BannerSynthGrid -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "circuit" { Add-BannerCircuit   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "network" { Add-BannerNetwork   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "hex"     { Add-BannerHex       -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "embers"  { Add-BannerEmbers    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        default   { Add-BannerStarfield -BannerName $BannerName -BannerH $BannerH -StarColorHex $ColorHex }
    }
}

# Replace whatever effect a banner currently has with a fresh one. Removes
# any previously added effect layer (tagged "BannerFx") first.
function global:Set-BannerEffect {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex, [string]$Effect)
    # Network is the only banner effect driven by a DispatcherTimer. Stop its
    # old timer before replacing/removing the visual, otherwise a detached
    # 30-Hz simulation keeps consuming the UI thread indefinitely.
    if (Get-Command Stop-BannerNetTimer -ErrorAction SilentlyContinue) {
        Stop-BannerNetTimer -BannerName $BannerName
    }
    $banner = $global:window.FindName($BannerName)
    if ($banner -and ($banner.Child -is [System.Windows.Controls.Grid])) {
        $g = $banner.Child
        for ($i = $g.Children.Count - 1; $i -ge 0; $i--) {
            $ch = $g.Children[$i]
            if ($ch -and $ch.Tag -eq "BannerFx") { $g.Children.RemoveAt($i) }
        }
    }
    Add-BannerEffect -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex -Effect $Effect
}

# Re-roll the per-banner effects (used on Explore shuffle). Picks are random,
# so an effect can occasionally stay. Stops old network timers first so they
# don't keep ticking on removed canvases.
function global:Reshuffle-BannerEffects {
    try {
        if ($global:BannerTimers) {
            foreach ($t in $global:BannerTimers) { try { $t.Stop() } catch { } }
            $global:BannerTimers.Clear()
        }
        Set-BannerEffect -BannerName "OvBanner"   -BannerH 200 -ColorHex "#FFFFFF" -Effect (Get-BannerFxFor -Game $global:OvBannerGame)
        Set-BannerEffect -BannerName "ListBanner" -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:ListBannerGame)
        Set-BannerEffect -BannerName "LibBanner"  -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:LibBannerGame)
    } catch { }
}

# Stop and forget a banner's network-effect timer (if it has one) so a
# re-roll doesn't leave it ticking on a detached canvas.
function global:Stop-BannerNetTimer {
    param([string]$BannerName)
    if (-not $global:BannerNetTimers) { return }
    $t = $global:BannerNetTimers[$BannerName]
    if ($t) {
        try { $t.Stop() } catch { }
        if ($global:BannerTimers) { try { $global:BannerTimers.Remove($t) } catch { } }
        $global:BannerNetTimers.Remove($BannerName) | Out-Null
    }
}

# Timed rotation for the two VR-mod-list banners ONLY (Steam portrait
# list + library tiles). Picks a new featured game and a fresh random
# effect for each - the same pair of moves the Explore Shuffle button
# makes - but never touches the Explore banner, which has its own
# Shuffle. Skips a banner the user has disabled.
function global:Invoke-ListLibBannerRotation {
    $listDisabled = [bool](Get-HubSetting -Key "bannerListDisabled" -Default $false)
    $libDisabled  = [bool](Get-HubSetting -Key "bannerLibDisabled"  -Default $false)
    if (-not $listDisabled -and (Get-Command Set-ListBanner -ErrorAction SilentlyContinue)) {
        try {
            Set-ListBanner
            Stop-BannerNetTimer "ListBanner"
            Set-BannerEffect -BannerName "ListBanner" -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:ListBannerGame)
        } catch { }
    }
    if (-not $libDisabled -and (Get-Command Set-LibBanner -ErrorAction SilentlyContinue)) {
        try {
            Set-LibBanner
            Stop-BannerNetTimer "LibBanner"
            Set-BannerEffect -BannerName "LibBanner" -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:LibBannerGame)
        } catch { }
    }
}

# General banner-effect pool. The neon synth-grid road is deliberately
# NOT in here: it is the one theme-specific effect, so it only appears
# for futuristic / techy games via Get-BannerFxFor (below). Every other
# effect is fair game for any banner.
$global:BannerFxPool = @("stars","parallax","orbs","circuit","network","hex","embers","nebula","meteors","sonar","motes","equalizer","speed","plasma","blobsunset","blobcandy","blobocean","blobember","blobtoxic","blobice","blobviolet","blobmidnight","blobamber","blobrose","blobforest","stripes","twinkle","rain","bokeh","bokehsunset","bokehcandy","bokehember","bokehtoxic","bokehviolet","bokehmidnight","bokehgold","bokehmint","bokehcoral","shards","waves","rays","lava","topo","vortex","snow","breathe","matrix","hyper","tunnel","kaleido","comet","spark","field","silk","bubbles","sparkgold","sparkice","sparkviolet","sparkblood","sparkmint","bubblesdeep","bubblestoxic","bubblesgold","bubblesviolet","bubblesmono","meteorsember","meteorsice","meteorstoxic","meteorsrose","meteorsgold","hexcyan","hexmagenta","hexlime","hexamber","hexsteel","fieldcyan","fieldrose","fieldgold","fieldtoxic","fieldsteel","vortexgold","vortexice","vortexrose","vortextoxic","vortexviolet","vortextwin")

# Titles eligible for the synth-grid even if their tags carry no
# futuristic marker (explicit opt-in).
$global:FuturisticBannerTitles = @(
    "Dolphin VR + ReduX"
)

# Tags that mark a game as modern / futuristic / techy enough for the
# neon synth-grid road to fit.
$global:FuturisticBannerTags = @(
    "cyberpunk", "sci-fi", "scifi", "sci fi", "neon", "futuristic",
    "synthwave", "retrowave", "outrun", "cyber", "techno", "dystopian"
)

# True when a game reads as futuristic / techy (explicit title or any
# futuristic tag). Gates the synth-grid effect.
function global:Test-FuturisticGame {
    param($Game)
    if (-not $Game) { return $false }
    if ($Game.Title -and ($global:FuturisticBannerTitles -contains $Game.Title)) { return $true }
    if ($Game.Tags) {
        foreach ($t in $Game.Tags) {
            $tl = ("$t").ToLower()
            foreach ($f in $global:FuturisticBannerTags) {
                if ($tl -eq $f -or $tl.Contains($f)) { return $true }
            }
        }
    }
    return $false
}

# Titles eligible for the bright rainbow "flow" wash even if their tags
# carry no colourful marker (explicit opt-in). Flow's garish teal/blue/
# purple only fits comic-like or vividly colourful games - never dark ones
# (Doom, Quake, etc.). Add titles here to let flow appear on them.
$global:ColorfulBannerTitles = @(
    "Cruelty Squad VR",
    "R.E.P.O. VR",
    "Sonic P-06 VR",
    "Astrodogs VR",
    "Bomb Rush Cyberfunk",
    "Life is Strange: BtS",
    "Paperklay VR",
    "PEAK VR",
    "Slime Rancher VR",
    "Trombone Champ VR",
    "Alba VR",
    "StreetDog BMX VR"
)

# Tags that mark a game as comic / cartoon / vividly colourful enough for
# the flow wash to fit.
$global:ColorfulBannerTags = @(
    "comic", "cartoon", "cartoony", "cel-shaded", "cel shaded", "toon",
    "colorful", "colourful", "vibrant", "stylized", "stylised",
    "psychedelic", "arcade", "cute", "whimsical"
)

# Titles explicitly BARRED from the flow wash even if a tag would match -
# e.g. Bendy is tagged "comic" but is black-and-white, so the rainbow flow
# does not fit. Add titles here to keep flow off them.
$global:ColorfulBannerExclude = @(
    "Bendy VR"
)

# True when a game reads as comic-like / vividly colourful (explicit title
# or any colourful tag). Gates the flow wash.
function global:Test-ColorfulGame {
    param($Game)
    if (-not $Game) { return $false }
    if ($Game.Title -and ($global:ColorfulBannerExclude -contains $Game.Title)) { return $false }
    if ($Game.Title -and ($global:ColorfulBannerTitles -contains $Game.Title)) { return $true }
    if ($Game.Tags) {
        foreach ($t in $Game.Tags) {
            $tl = ("$t").ToLower()
            foreach ($f in $global:ColorfulBannerTags) {
                if ($tl -eq $f -or $tl.Contains($f)) { return $true }
            }
        }
    }
    return $false
}

# ---------------------------------------------------------------
# Theme-fitting banner effects
# ---------------------------------------------------------------
# A few effects fit certain games so well that they should show up
# noticeably more often there - without ever becoming the only thing
# that game's banner does. Same opt-in shape as synth/flow above:
# the effect is ADDED as a candidate, never forced, so the normal
# rotation still comes up most of the time.

# Retro/boomer shooters and gory id-style games: rain and snow recoloured
# to blood red read as falling gore rather than weather.
$global:GoreBannerTitles = @(
    "Doom VR", "Doom 2 VR", "Doom 3 BFG VR",
    "Quake VR", "Quake 2 VR", "Quake 3 VR",
    "Painkiller Black Edition",
    "Heretic VR", "Hexen VR", "Hexen II VR", "Strife VR",
    "Ashes 2063 VR", "Dusk HD (DLC) VR", "Total Chaos VR"
)
# Verified to exist in the catalog; deliberately narrow so unrelated
# shooters do not start raining blood.
$global:GoreBannerTags = @("boomer shooter")

# Titles explicitly BARRED from the blood recolours even though a tag
# matches - same idea as ColorfulBannerExclude. Mouse P.I. is tagged
# "boomer shooter" but is a monochrome 1930s noir cartoon, so red gore
# would fight its black-and-white art the way flow fights Bendy's.
$global:GoreBannerExclude = @(
    "Mouse P.I. For Hire VR"
)

# True when a game is a gory retro shooter. Gates bloodrain / bloodsnow.
function global:Test-GoreGame {
    param($Game)
    if (-not $Game) { return $false }
    if ($Game.Title -and ($global:GoreBannerExclude -contains $Game.Title)) { return $false }
    if ($Game.Title -and ($global:GoreBannerTitles -contains $Game.Title)) { return $true }
    if ($Game.Tags) {
        foreach ($t in $Game.Tags) {
            $tl = ("$t").ToLower()
            foreach ($f in $global:GoreBannerTags) { if ($tl -eq $f) { return $true } }
        }
    }
    return $false
}

# Underwater / ocean-survival games, where the existing bubbles effect is
# the single most fitting one in the pool - so it gets extra weight rather
# than a new effect.
$global:AquaticBannerTitles = @(
    "Subnautica VR", "Subnautica: Below Zero", "Raft VR"
)
$global:AquaticBannerTags = @("underwater")

# True when a game plays in or on water. Weights the bubbles effect.
function global:Test-AquaticGame {
    param($Game)
    if (-not $Game) { return $false }
    if ($Game.Title -and ($global:AquaticBannerTitles -contains $Game.Title)) { return $true }
    if ($Game.Tags) {
        foreach ($t in $Game.Tags) {
            $tl = ("$t").ToLower()
            foreach ($f in $global:AquaticBannerTags) { if ($tl -eq $f) { return $true } }
        }
    }
    return $false
}

# Games whose look calls for candy-pink bubbles instead of the accent-
# coloured ones. Title-only on purpose: this is a per-game art call, not
# something a tag can decide.
$global:PinkBubbleBannerTitles = @(
    "Slime Rancher VR"
)

# True when a game should get the pink bubble variant as a candidate.
function global:Test-PinkBubbleGame {
    param($Game)
    if (-not $Game) { return $false }
    if ($Game.Title -and ($global:PinkBubbleBannerTitles -contains $Game.Title)) { return $true }
    return $false
}

# Pick one banner effect for a banner showing $Game. The synth-grid is
# only added as a candidate (so it CAN come up, never guaranteed) when
# the game reads as futuristic; a null game falls back to the general
# pool (no synth).
function global:Get-BannerFxFor {
    param($Game)
    $pool = @($global:BannerFxPool)
    if (Test-FuturisticGame -Game $Game) { $pool += "synth" }
    if (Test-ColorfulGame    -Game $Game) { $pool += "flow" }
    # Theme-fitting extras. Added as several copies so they come up
    # clearly more often than a 1-in-56 pool entry, while the normal
    # rotation still wins roughly 9 times out of 10 - "especially
    # fitting when it happens", not "this game's effect".
    if (Test-GoreGame -Game $Game) {
        $pool += @("bloodrain","bloodrain","bloodrain","bloodsnow","bloodsnow","bloodsnow")
    }
    if (Test-AquaticGame -Game $Game) {
        # bubbles is already in the pool once; these extra copies are what
        # make it the one you notice on an underwater banner.
        $pool += @("bubbles","bubbles","bubbles","bubbles","bubbles")
    }
    if (Test-PinkBubbleGame -Game $Game) {
        $pool += @("pinkbubbles","pinkbubbles","pinkbubbles","pinkbubbles")
    }
    # Genre-flavoured colour variants (2026-08-16). The same restraint as
    # above: a few extra copies so they stand out on matching games - not
    # a permanent effect.
    if (Test-FuturisticGame -Game $Game) {
        # Neon on hexagons and a dot grid - cyberpunk, sci-fi.
        $pool += @("hexcyan","hexcyan","hexmagenta","hexmagenta","fieldcyan","vortextwinice")
    }
    if (Test-AquaticGame -Game $Game) {
        # Deep blue and colourless grey read as water.
        $pool += @("bubblesdeep","bubblesdeep","bubblesmono")
    }
    if (Test-GoreGame -Game $Game) {
        # Red sparks instead of rain - same mood, different motion.
        $pool += @("sparkblood","sparkblood","meteorsember")
    }
    return ($pool | Get-Random)
}

Set-BannerEffect -BannerName "OvBanner"   -BannerH 200 -ColorHex "#FFFFFF" -Effect (Get-BannerFxFor -Game $global:OvBannerGame)
Set-BannerEffect -BannerName "ListBanner" -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:ListBannerGame)
Set-BannerEffect -BannerName "LibBanner"  -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:LibBannerGame)

function global:Add-BannerDotPulse {
    # Give the control-type dot before "featured mod" a slow, subtle pulse with
    # a soft glow that peaks at maximum size - a small eye-catcher. Uses a
    # RenderTransform (render-time, no layout reflow, so the text never shifts).
    # The glow COLOUR is set per featured game in Set-BannerForGame; here we
    # only build the (colour-independent) scale + blur animations once.
    param([string]$DotName)
    try {
        $dot = $global:window.FindName($DotName)
        if (-not $dot) { return }
        $dot.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
        $st = New-Object System.Windows.Media.ScaleTransform 1.0, 1.0
        $dot.RenderTransform = $st

        $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
        $glow.ShadowDepth = 0
        $glow.BlurRadius  = 0
        $glow.Opacity     = 0.85
        $glow.Color       = [System.Windows.Media.Colors]::White   # retinted per game
        $dot.Effect = $glow

        $ease = New-Object System.Windows.Media.Animation.SineEase
        $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseInOut
        $dur = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(1700))

        $scaleAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
        $scaleAnim.From = 1.0
        $scaleAnim.To   = 0.7
        $scaleAnim.Duration = $dur
        $scaleAnim.AutoReverse = $true
        $scaleAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $scaleAnim.EasingFunction = $ease
        $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $scaleAnim)
        $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $scaleAnim)

        # Glow rides the SAME timing, inverted: full at rest (normal size) and
        # gone at the small end - so the dot clearly "breathes" inward, glowing
        # at full size, then dips to a small plain dot and back.
        $glowAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
        $glowAnim.From = 8.0
        $glowAnim.To   = 0.0
        $glowAnim.Duration = $dur
        $glowAnim.AutoReverse = $true
        $glowAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $glowAnim.EasingFunction = $ease
        $glow.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::BlurRadiusProperty, $glowAnim)
    } catch { }
}
Add-BannerDotPulse "ListBannerCtrlDot"
Add-BannerDotPulse "LibBannerCtrlDot"
Add-BannerDotPulse "OvBannerCtrlDot"

if ($versionLabel) { $versionLabel.Text = "v$HUB_VERSION" }

# Header hover-grow: version badge, VR headset glyph, and the
# "Install n!ce VR mods..." tagline all subtly scale up on hover,
# matching the motion language used by the list banner and tag
# chips. Pure visual flourish - no click action attached.
function global:Add-HeaderHoverGrow {
    param($Element, [double]$Scale = 1.08)
    if (-not $Element) { return }
    $Element.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
    $scaleCapture = $Scale
    $elemCapture  = $Element
    $elemCapture.Add_MouseEnter({
        $s = New-Object System.Windows.Media.ScaleTransform $scaleCapture, $scaleCapture
        $elemCapture.RenderTransform = $s
    }.GetNewClosure())
    $elemCapture.Add_MouseLeave({
        $elemCapture.RenderTransform = $null
    }.GetNewClosure())
}
Add-HeaderHoverGrow -Element $versionBadge   -Scale 1.10
Add-HeaderHoverGrow -Element $headerVrIcon   -Scale 1.15
Add-HeaderHoverGrow -Element $headerHubTitle -Scale 1.04
Add-HeaderHoverGrow -Element $headerTagline  -Scale 1.04

# Populate and reveal the "Update X available" banner. Factored into a
# global function (instead of an inline block that ran once at load time)
# so a background update check that finishes AFTER the window is already
# open can call it to reveal the banner live in the SAME session - the
# Hub loads and is usable immediately, then this little banner lights up
# quietly once the check is done. Idempotent: the hover/click handlers are
# wired only once (guarded by a flag); repeat calls just refresh the text
# and keep the banner visible. Elements are re-resolved via FindName so the
# function works when called later from a timer tick (outside module scope).
$global:UpdateBannerWired = $false
function global:Show-UpdateBanner {
    param($Info)
    if (-not $Info -or -not $Info.LatestVersion) { return }
    $banner     = $global:window.FindName("UpdateBanner")
    $bannerText = $global:window.FindName("UpdateBannerText")
    if (-not $banner -or -not $bannerText) { return }
    $bannerText.Text   = "Update $($Info.LatestVersion) available"
    $banner.Visibility = [System.Windows.Visibility]::Visible
    if (-not $global:UpdateBannerWired) {
        $global:UpdateBannerWired = $true
        $banner.Add_MouseEnter({
            $b = $global:window.FindName("UpdateBanner")
            if ($b) { $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#234a23") }
        })
        $banner.Add_MouseLeave({
            $b = $global:window.FindName("UpdateBanner")
            if ($b) { $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a2e1a") }
        })
        $banner.Add_PreviewMouseLeftButtonDown({
            $updaterPath = Join-Path $global:scriptDir "Update-Hub.ps1"
            Start-Process "powershell.exe" -ArgumentList `
                "-NoProfile -ExecutionPolicy Bypass -File `"$updaterPath`""
            $global:window.Close()
        })
    }
}

# A marker left by a previous run (genuine update not yet applied) reveals
# the banner immediately on startup. A marker written by THIS session's
# background check is picked up live by the poll in Startup.ps1.
if ($script:updateInfo) { Show-UpdateBanner -Info $script:updateInfo }

