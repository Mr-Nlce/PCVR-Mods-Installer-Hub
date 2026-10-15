# ============================================================
# BannerGlass.ps1 - glass finish for the three
# featured banners (ListBanner, LibBanner, OvBanner)
#
#   The banner background is a flat colour wash (dark -> game
#   colour). On games whose art does not fill the width this
#   reads as a plain yellow/green/... box. This file lays a
#   "glass" finish over it, tinted per game:
#     base layer  (under the banner effects and the art)
#                 - a soft light pool in the game colour, top right
#                 - a gentle shade towards the bottom edge
#     top layer   (over art + fade, UNDER the title/buttons)
#                 - glass sheen on the upper half
#                 - a slow light sweep every few seconds
#                 - edge glow + hairline in the game colour (bottom,
#                   and top when EdgeTopEnabled)
#                 - inner rim: bright top edge, game colour bottom
#   Text and buttons stay above everything and are not touched.
#
#   Game detail page: the hero header gets the ambient haze of its own
#   art as background (visible in the side bands of the wide layout,
#   under the band effects), the frozen image's left/right edges melt
#   into that haze, and the same top glass layer (sheen, edge glows,
#   rim, sweep) lies over it in the page's accent colour. Every style
#   except Classic. Hooked by one guarded line
#   in DetailView.Page.ps1 (Add-DetailHeroGlass).
#   The banner Border itself (hover/press border) is not touched.
#
#   All glass styles use a slowly moving, softly blurred echo of the
#   current header art. The sharp right-hand image never moves. The
#   background source follows the banner's own successful image load.
#   "Glass + frost" additionally has:
#     - frosted panel behind kicker/title/buttons
#     - the left-side dark fade reduced (FrostFadeOpacity)
#     - Show/Explore/Shuffle buttons as glass pills with a hover glow
#
#   "Hero" is built like the game page hero:
#     - ambient echo of the art fills the whole banner (no flat colour)
#     - the art's left edge melts into that haze (opacity mask) instead
#       of ending in a hard box edge
#     - corner radius 10 like the game page hero
#     - glass edges/sheen/sweep and glass pills as in frost, no panel
#
#   Chosen in Help & feedback -> "Banner style" (Glass -> Glass + frost
#   -> Hero -> Classic), kept in the Hub settings as bannerGlassStyle.
#   Default: glass.
#
# Hooks Set-BannerForGame and the detail-page hero. To switch it off,
# set $global:HubBannerGlass = $false below.
# Everything is wrapped so a failure leaves the classic banner.
# ============================================================

$global:HubBannerGlass = $true

# Tuning knobs - all looks are adjusted here. Opacities are 0..1.
$global:BannerGlassConfig = @{
    GlowOpacity       = 0.38   # subdued, broad colour reflection
    GlowCenterX       = 0.52
    GlowCenterY       = 0.05   # fraction of banner height (top edge)
    GlowRadiusX       = 1.30
    GlowRadiusY       = 1.35
    ShadeOpacity      = 0.42   # dark shade at the bottom edge
    SheenOpacity      = 0.045  # featured banners: restrained full-height reflection
    DetailSheenOpacity = 0.10  # keep the detail-page treatment unchanged
    SweepEnabled      = $true
    SweepOpacity      = 0.033  # peak of the moving light band
    SweepWidth        = 140    # px
    SweepSkew         = -22    # degrees
    SweepSeconds      = 1.8    # time to cross the banner
    SweepPauseSeconds = 24.0   # rest between two sweeps
    DetailSweepOpacity      = 0.022 # detail hero: one third less intense
    DetailSweepPauseSeconds = 36.9  # detail hero: 50% longer full sweep cycle
    EdgeGlowOpacity   = 0.082  # detail-page edge treatment
    FeaturedEdgeGlowOpacity = 0.11
    EdgeGlowHeight    = 26     # px
    EdgeLineOpacity   = 0.32   # detail-page hairline treatment
    FeaturedEdgeLineOpacity = 0.38
    EdgeTopEnabled    = $true  # same glow + hairline mirrored on the top edge
    RimTopOpacity     = 0.20   # inner rim, bright top edge
    RimAccentOpacity  = 0.30   # inner rim, game colour at the bottom
    AccentMinValue    = 0.88   # glow colours are lifted to at least this brightness
    AccentMaxSat      = 0.85
    # ---- "Glass + frost" only ----
    AmbientOpacity    = 0.80   # header art haze behind the banner
    AmbientDecodeW    = 128    # local fallback only; bound banner art reuses its decoded source
    AmbientBlur       = 24
    GlassAmbientOpacity = 0.12 # moving colour remains visible over the original milky wash
    GlassAmbientBlur    = 90   # full-size source must not make lettering legible
    AmbientPanPixels  = 90     # visible movement during a short look
    AmbientPanMargin  = 190    # offset + strongest glass blur + a safety margin
    FrostFadeOpacity  = 0.70   # left dark fade for frosted style
    GlassFadeOpacity  = 0.42   # keep the default glass text area evenly lit
    ColorBallFadeOpacity = 0.14 # let Bokeh, Blobs and Orbs show through glass
    PanelEnabled      = $false # frosted panel behind the title - off (looked odd in test)
    PanelOpacityTop   = 0.50   # frosted panel fill, top
    PanelOpacityBot   = 0.38   # frosted panel fill, bottom
    PanelTint         = 0.12   # share of game colour in the panel fill
    PanelRimOpacity   = 0.16   # panel edge, bright top
    PanelMaxFrac      = 0.62   # panel never wider than this share of the banner
    PillOpacityTop    = 0.22   # button glass fill, top
    PillOpacityBot    = 0.06   # button glass fill, bottom
    PillHoverBoost    = 1.8    # fill multiplier while hovered
    PillGlowOpacity   = 0.55   # hover glow around the button
    PillGlowBlur      = 14
    AmbientScrim      = 0.30   # restore the soft frosted veil over the moving art
    # ---- "Hero" only ----
    HeroAmbientOpacity = 0.92
    HeroFadeOpacity    = 0.80  # left dark fade
    HeroMaskEnd        = 0.32  # art is fully visible from this share of its width
    HeroCornerRadius   = 10    # game page hero uses 10; classic banner 8
    # ---- Game detail page hero ----
    DetailAmbientOpacity = 0.92  # haze of the header art behind the hero
    DetailWideThreshold  = 1040  # same value as $heroThreshold in DetailView.Page.ps1
    DetailMaskFrac       = 0.08  # wide layout: image edges melt into the haze over this share
}

$global:BannerGlassBanners = @('ListBanner', 'LibBanner', 'OvBanner')
$global:BannerGlassStyleLabels = @{ glass = 'Glass'; frost = 'Glass + frost'; hero = 'Hero'; classic = 'Classic' }
$global:BannerGlassButtons = @('ListBannerShowBtn', 'ListBannerExploreBtn', 'LibBannerShowBtn', 'LibBannerExploreBtn', 'OvBannerShowBtn', 'OvBannerShuffleBtn')

# ------------------------------------------------------------
# Pure helpers (no WPF) - testable on any host
# ------------------------------------------------------------

# '#rrggbb' -> @(r, g, b) as 0..255 ints, or $null.
function global:ConvertFrom-BannerGlassHex {
    param([string]$Hex)
    if (-not $Hex) { return $null }
    $h = $Hex.Trim().TrimStart('#')
    if ($h.Length -eq 8) { $h = $h.Substring(2) }   # #aarrggbb -> rrggbb
    if ($h.Length -ne 6 -or $h -notmatch '^[0-9a-fA-F]{6}$') { return $null }
    return @(
        [Convert]::ToInt32($h.Substring(0, 2), 16),
        [Convert]::ToInt32($h.Substring(2, 2), 16),
        [Convert]::ToInt32($h.Substring(4, 2), 16))
}

# Lift a colour to a bright, not over-saturated glow tone with the
# same hue: dark curated tones (e.g. a deep olive) would otherwise
# glow as mud. Returns '#rrggbb'.
function global:ConvertTo-BannerGlassAccent {
    param([string]$Hex, [double]$MinValue = 0.88, [double]$MaxSat = 0.85)
    $rgb = ConvertFrom-BannerGlassHex $Hex
    if (-not $rgb) { return '#ffcf8c' }
    $r = $rgb[0] / 255.0; $g = $rgb[1] / 255.0; $b = $rgb[2] / 255.0
    $max = [Math]::Max($r, [Math]::Max($g, $b))
    $min = [Math]::Min($r, [Math]::Min($g, $b))
    $d = $max - $min
    $h = 0.0
    if ($d -gt 0) {
        if ($max -eq $r)     { $h = 60.0 * ((($g - $b) / $d) % 6.0) }
        elseif ($max -eq $g) { $h = 60.0 * ((($b - $r) / $d) + 2.0) }
        else                 { $h = 60.0 * ((($r - $g) / $d) + 4.0) }
    }
    if ($h -lt 0) { $h += 360.0 }
    $s = if ($max -gt 0) { $d / $max } else { 0.0 }
    $s = [Math]::Min($s, $MaxSat)
    $v = [Math]::Max($max, $MinValue)
    $c = $v * $s
    $hh = $h / 60.0
    $x = $c * (1.0 - [Math]::Abs(($hh % 2.0) - 1.0))
    $m = $v - $c
    if ($hh -lt 1)     { $r1 = $c; $g1 = $x; $b1 = 0.0 }
    elseif ($hh -lt 2) { $r1 = $x; $g1 = $c; $b1 = 0.0 }
    elseif ($hh -lt 3) { $r1 = 0.0; $g1 = $c; $b1 = $x }
    elseif ($hh -lt 4) { $r1 = 0.0; $g1 = $x; $b1 = $c }
    elseif ($hh -lt 5) { $r1 = $x; $g1 = 0.0; $b1 = $c }
    else               { $r1 = $c; $g1 = 0.0; $b1 = $x }
    $to = { param($f) [Math]::Min(255, [Math]::Max(0, [int][Math]::Round(($f + $m) * 255))) }
    return ('#{0:x2}{1:x2}{2:x2}' -f (& $to $r1), (& $to $g1), (& $to $b1))
}

# Which colour tints the glass for a game: the curated banner colour
# (same source as the banner background), then the catalog Accent,
# then the controls colour the kicker already uses.
function global:Resolve-BannerGlassBaseHex {
    param($Game)
    if (-not $Game) { return '#ffcf8c' }
    $hex = $null
    if (Get-Command Get-BannerColorForGame -ErrorAction SilentlyContinue) {
        try { $hex = Get-BannerColorForGame -Game $Game } catch { $hex = $null }
    }
    if (-not $hex -and $Game.Accent) { $hex = [string]$Game.Accent }
    if (-not $hex) {
        $hex = switch ($Game.Controls) {
            'MC'    { '#44cc66' }
            'GP'    { '#dd6600' }
            'BOTH'  { '#8888ff' }
            default { '#dd6600' }
        }
    }
    return $hex
}

function global:Resolve-BannerGlassStyle {
    param($Stored)
    $s = ([string]$Stored).Trim().ToLower()
    if ($s -eq 'classic') { return 'classic' }
    if ($s -eq 'frost')   { return 'frost' }
    if ($s -eq 'hero')    { return 'hero' }
    return 'glass'
}

function global:Get-BannerGlassNextStyle {
    param([string]$Current)
    switch (Resolve-BannerGlassStyle $Current) {
        'glass' { return 'frost' }
        'frost' { return 'hero' }
        'hero'  { return 'classic' }
    }
    return 'glass'
}

# 'ListBannerBg' -> 'ListBanner'; anything that is not one of the three
# featured banners -> $null.
function global:Get-BannerGlassNameFromBg {
    param([string]$BgName)
    if (-not $BgName) { return $null }
    $n = $BgName -replace 'Bg$', ''
    if ($global:BannerGlassBanners -contains $n) { return $n }
    return $null
}

# Mix two '#rrggbb' colours; $T = share of $B (0..1). Returns '#rrggbb'.
function global:Get-BannerGlassMix {
    param([string]$A, [string]$B, [double]$T)
    $ca = ConvertFrom-BannerGlassHex $A; $cb = ConvertFrom-BannerGlassHex $B
    if (-not $ca) { $ca = @(15, 15, 21) }
    if (-not $cb) { return ('#{0:x2}{1:x2}{2:x2}' -f $ca[0], $ca[1], $ca[2]) }
    $o = @(0, 1, 2 | ForEach-Object { [int][Math]::Round($ca[$_] * (1 - $T) + $cb[$_] * $T) })
    return ('#{0:x2}{1:x2}{2:x2}' -f $o[0], $o[1], $o[2])
}

# Decode only local art here. For remote art, reuse the ImageSource already
# being loaded by the normal banner/detail view; never start a second request.
function global:Get-BannerGlassAmbientUri {
    param($Game)
    if (-not $Game) { return $null }
    try {
        $h = [string]$Game.HeaderUrl
        if ($h -and $h -notmatch '^https?://' -and $global:HubHelpersCoreRoot -and (Get-Command ConvertTo-HubFileUri -ErrorAction SilentlyContinue)) {
            $abs = Join-Path $global:HubHelpersCoreRoot $h
            if (Test-Path -LiteralPath $abs) { return (ConvertTo-HubFileUri -Path $abs) }
        }
        if ($Game.SteamId -and (Get-Command Get-CachedImageUri -ErrorAction SilentlyContinue)) {
            $c = Get-CachedImageUri -SteamId ([string]$Game.SteamId) -Kind 'header'
            if ($c -and ([Uri]$c).IsFile) { return $c }
        }
    } catch { }
    return $null
}

# ------------------------------------------------------------
# WPF building blocks
# ------------------------------------------------------------

function global:New-BannerGlassColor {
    param([string]$Hex, [double]$Opacity)
    $rgb = ConvertFrom-BannerGlassHex $Hex
    if (-not $rgb) { $rgb = @(255, 255, 255) }
    $a = [byte][Math]::Min(255, [Math]::Max(0, [int][Math]::Round($Opacity * 255)))
    return [System.Windows.Media.Color]::FromArgb($a, [byte]$rgb[0], [byte]$rgb[1], [byte]$rgb[2])
}

# Linear gradient from @(offset, hex, opacity) triples. Vertical
# (top -> bottom) unless -Horizontal.
function global:New-BannerGlassLinear {
    param([object[]]$Stops, [switch]$Horizontal)
    $lg = New-Object System.Windows.Media.LinearGradientBrush
    $lg.StartPoint = [System.Windows.Point]::new(0, 0)
    if ($Horizontal) { $lg.EndPoint = [System.Windows.Point]::new(1, 0) }
    else             { $lg.EndPoint = [System.Windows.Point]::new(0, 1) }
    foreach ($s in $Stops) {
        [void]$lg.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BannerGlassColor $s[1] ([double]$s[2])), [double]$s[0]))
    }
    $lg.Freeze()
    return $lg
}

function global:New-BannerGlassRect {
    param($Fill)
    $r = New-Object System.Windows.Shapes.Rectangle
    $r.Fill = $Fill
    $r.IsHitTestVisible = $false
    $r.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $r.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    return $r
}

function global:New-BannerGlassLayer {
    $g = New-Object System.Windows.Controls.Grid
    $g.IsHitTestVisible = $false
    $g.Tag = 'BannerGlass'
    $g.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $g.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    return $g
}

# The featured art is right-aligned and keeps its aspect ratio. The
# reflection fills the remaining banner width and fades out before the art.
function global:Get-BannerGlassReflectionWidth {
    param([double]$BannerWidth, [double]$BannerHeight, [double]$ArtWidth, [double]$ArtHeight)
    if ($BannerWidth -le 0) { return 0.0 }
    if ($BannerHeight -le 0 -or $ArtWidth -le 0 -or $ArtHeight -le 0) { return $BannerWidth }
    $drawnArtWidth = [Math]::Min($BannerWidth, $BannerHeight * $ArtWidth / $ArtHeight)
    return [Math]::Max(0.0, $BannerWidth - $drawnArtWidth)
}

# Base layer: sits directly above the banner background, below the
# banner effects (they insert at index 1 too, so they land above it)
# and below the art.
function global:New-BannerGlassBase {
    param([string]$Accent, [switch]$Uniform)
    $cfg = $global:BannerGlassConfig
    $layer = New-BannerGlassLayer

    if ($Uniform) {
        # The classic banner has a bright right-side gradient. Cover it only
        # for the default glass style, before adding the broad colour glow.
        $ground = Get-BannerGlassMix '#101116' $Accent 0.14
        [void]$layer.Children.Add((New-BannerGlassRect (New-Object System.Windows.Media.SolidColorBrush (New-BannerGlassColor $ground 0.94))))
    }

    $rg = New-Object System.Windows.Media.RadialGradientBrush
    $rg.Center         = [System.Windows.Point]::new($cfg.GlowCenterX, $cfg.GlowCenterY)
    $rg.GradientOrigin = [System.Windows.Point]::new($cfg.GlowCenterX, $cfg.GlowCenterY)
    $rg.RadiusX = $cfg.GlowRadiusX
    $rg.RadiusY = $cfg.GlowRadiusY
    [void]$rg.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BannerGlassColor $Accent $cfg.GlowOpacity), 0.0))
    [void]$rg.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BannerGlassColor $Accent ($cfg.GlowOpacity * 0.35)), 0.45))
    [void]$rg.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BannerGlassColor $Accent 0.0), 1.0))
    $rg.Freeze()
    [void]$layer.Children.Add((New-BannerGlassRect $rg))

    $shade = New-BannerGlassLinear -Stops @(
        @(0.0,  '#000000', 0.0),
        @(0.45, '#000000', 0.0),
        @(1.0,  '#000000', $cfg.ShadeOpacity))
    [void]$layer.Children.Add((New-BannerGlassRect $shade))
    return $layer
}

# Frost: ambient echo layer (header art, tiny decode, blurred,
# overscanned so no soft edge shows). Sits right above the background.
function global:Get-BannerGlassPanPlan {
    $cfg = $global:BannerGlassConfig
    $limit = [int]$cfg.AmbientPanPixels
    $x = Get-Random -Minimum (-$limit) -Maximum ($limit + 1)
    $y = Get-Random -Minimum (-$limit) -Maximum ($limit + 1)
    return [pscustomobject]@{
        StartX = [double]$x
        EndX = [double]$(if ($x -ge 0) { -$limit } else { $limit })
        StartY = [double]$y
        EndY = [double]$(if ($y -ge 0) { -$limit } else { $limit })
        SecondsX = [double](60 + (Get-Random -Minimum 0 -Maximum 16))
        SecondsY = [double](85 + (Get-Random -Minimum 0 -Maximum 16))
    }
}

function global:New-BannerGlassAmbient {
    param($Game, [double]$Opacity = -1, $ImageSource, $ImageElement)
    $cfg = $global:BannerGlassConfig
    $bi = $ImageSource
    $uri = if ($ImageElement) { $null } else { Get-BannerGlassAmbientUri -Game $Game }
    if ($uri) {
        $bi = New-Object System.Windows.Media.Imaging.BitmapImage
        $bi.BeginInit()
        $bi.UriSource = [Uri]$uri
        $bi.DecodePixelWidth = $cfg.AmbientDecodeW
        $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bi.CreateOptions = [System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreColorProfile
        $bi.EndInit()
    }
    if (-not $bi -and -not $ImageElement) { return $null }
    $layer = New-BannerGlassLayer
    $layer.ClipToBounds = $true
    $img = New-Object System.Windows.Controls.Image
    $img.IsHitTestVisible = $false
    if ($ImageElement) {
        # The normal banner loader may replace its BitmapImage after a CDN
        # failure. Binding follows the final source without another request.
        $binding = New-Object System.Windows.Data.Binding('Source')
        $binding.Source = $ImageElement
        $binding.Mode = [System.Windows.Data.BindingMode]::OneWay
        [void][System.Windows.Data.BindingOperations]::SetBinding($img, [System.Windows.Controls.Image]::SourceProperty, $binding)
    } else {
        $img.Source = $bi
    }
    $img.Stretch = [System.Windows.Media.Stretch]::UniformToFill
    $img.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $img.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $img.Margin = [System.Windows.Thickness]::new(-[double]$cfg.AmbientPanMargin)
    [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($img, [System.Windows.Media.BitmapScalingMode]::Linear)
    $bl = New-Object System.Windows.Media.Effects.BlurEffect
    $bl.Radius = $cfg.AmbientBlur
    $img.Effect = $bl
    $img.CacheMode = New-Object System.Windows.Media.BitmapCache
    $img.Opacity = $(if ($Opacity -ge 0) { $Opacity } else { $cfg.AmbientOpacity })
    # Render-thread translation of the cached haze. The overscan exceeds
    # both the maximum offset and blur radius, so no empty edge can enter.
    $plan = Get-BannerGlassPanPlan
    $pan = New-Object System.Windows.Media.TranslateTransform
    $pan.X = $plan.StartX
    $pan.Y = $plan.StartY
    $img.RenderTransform = $pan
    $panX = New-Object System.Windows.Media.Animation.DoubleAnimation
    $panX.From = $plan.StartX
    $panX.To = $plan.EndX
    $panX.Duration = [System.Windows.Duration]::new([TimeSpan]::FromSeconds($plan.SecondsX))
    $panX.AutoReverse = $true
    $panX.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $panY = New-Object System.Windows.Media.Animation.DoubleAnimation
    $panY.From = $plan.StartY
    $panY.To = $plan.EndY
    $panY.Duration = [System.Windows.Duration]::new([TimeSpan]::FromSeconds($plan.SecondsY))
    $panY.AutoReverse = $true
    $panY.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $pan.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $panX)
    $pan.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $panY)
    [void]$layer.Children.Add($img)
    [void]$layer.Children.Add((New-BannerGlassRect (New-Object System.Windows.Media.SolidColorBrush (New-BannerGlassColor '#0a0a0c' $cfg.AmbientScrim))))
    return $layer
}

# Frost: translucent panel behind kicker/title/buttons. Width follows the
# title's MaxWidth (it changes with S/M/L) but never more than
# PanelMaxFrac of the banner.
function global:New-BannerGlassPanel {
    param([string]$Accent, [string]$BannerName, $HostEl)
    $cfg = $global:BannerGlassConfig
    $fill = Get-BannerGlassMix '#0f0f15' $Accent $cfg.PanelTint
    $p = New-Object System.Windows.Controls.Border
    $p.IsHitTestVisible = $false
    $p.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $p.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    $p.Margin = [System.Windows.Thickness]::new(8)
    $p.Width = 420
    $p.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $p.BorderThickness = [System.Windows.Thickness]::new(1)
    $p.Background = New-BannerGlassLinear -Stops @(
        @(0.0, $fill, $cfg.PanelOpacityTop),
        @(1.0, $fill, $cfg.PanelOpacityBot))
    $p.BorderBrush = New-BannerGlassLinear -Stops @(
        @(0.0,  '#ffffff', $cfg.PanelRimOpacity),
        @(0.45, '#ffffff', ($cfg.PanelRimOpacity * 0.25)),
        @(1.0,  $Accent, ($cfg.PanelRimOpacity * 0.75)))
    # Faint sheen inside the panel's upper half.
    $sh = New-Object System.Windows.Shapes.Rectangle
    $sh.IsHitTestVisible = $false
    $sh.RadiusX = 5; $sh.RadiusY = 5
    $sh.Fill = New-BannerGlassLinear -Stops @(
        @(0.0,  '#ffffff', 0.06),
        @(0.45, '#ffffff', 0.0))
    $p.Child = $sh
    $titleEl = $global:window.FindName($BannerName + 'Title')
    $fit = {
        try {
            $w = $HostEl.ActualWidth
            if ($w -lt 40) { return }
            $tw = 380.0
            if ($titleEl -and $titleEl.MaxWidth -gt 0 -and -not [double]::IsInfinity($titleEl.MaxWidth)) { $tw = [double]$titleEl.MaxWidth }
            $p.Width = [Math]::Max(120.0, [Math]::Min($tw + 64.0, $w * $cfg.PanelMaxFrac))
        } catch { }
    }.GetNewClosure()
    $HostEl.Add_SizeChanged($fit)
    return $p
}

# Top layer: above art + fade, below the title block.
function global:New-BannerGlassTop {
    param([string]$Accent, [string]$BannerName, [switch]$Frost, [double]$RimRadius = 7, $ImageElement)
    $cfg = $global:BannerGlassConfig
    $layer = New-BannerGlassLayer
    $layer.ClipToBounds = $true

    if ($Frost -and $BannerName -and $cfg.PanelEnabled) {
        [void]$layer.Children.Add((New-BannerGlassPanel -Accent $Accent -BannerName $BannerName -HostEl $layer))
    }

    # One subdued reflection across the entire text area, from top to
    # bottom. Only its final few pixels fade before the right-hand art.
    $sheenOpacity = if ($BannerName) { $cfg.SheenOpacity } else { $cfg.DetailSheenOpacity }
    $sheenStops = if ($BannerName) {
        @(@(0.0, '#ffffff', $sheenOpacity), @(1.0, '#ffffff', ($sheenOpacity * 0.60)))
    } else {
        @(@(0.0, '#ffffff', $sheenOpacity), @(0.42, '#ffffff', ($sheenOpacity * 0.30)), @(0.58, '#ffffff', 0.0))
    }
    $sheen = New-BannerGlassLinear -Stops $sheenStops
    $sheenRect = New-BannerGlassRect $sheen
    if ($BannerName -and $ImageElement) {
        $sheenRect.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $edgeFade = New-BannerGlassLinear -Horizontal -Stops @(
            @(0.0, '#ffffff', 1.0), @(0.97, '#ffffff', 1.0), @(1.0, '#ffffff', 0.0))
        $sheenRect.OpacityMask = $edgeFade
        $fitSheen = {
            $source = $ImageElement.Source
            $artW = if ($source) { [double]$source.Width } else { 0.0 }
            $artH = if ($source) { [double]$source.Height } else { 0.0 }
            $sheenRect.Width = Get-BannerGlassReflectionWidth -BannerWidth $layer.ActualWidth -BannerHeight $layer.ActualHeight -ArtWidth $artW -ArtHeight $artH
        }.GetNewClosure()
        $layer.Add_SizeChanged($fitSheen)
        $ImageElement.Add_SizeChanged($fitSheen)
        $layer.Add_Unloaded({ $ImageElement.Remove_SizeChanged($fitSheen) }.GetNewClosure())
    }
    [void]$layer.Children.Add($sheenRect)

    # Soft glow from the edge + 1 px hairline (strongest under the art),
    # in the game colour. Bottom always; top too when EdgeTopEnabled.
    $edges = @('Bottom')
    if ($cfg.EdgeTopEnabled) { $edges += 'Top' }
    $edgeGlowOpacity = if ($BannerName) { $cfg.FeaturedEdgeGlowOpacity } else { $cfg.EdgeGlowOpacity }
    $edgeLineOpacity = if ($BannerName) { $cfg.FeaturedEdgeLineOpacity } else { $cfg.EdgeLineOpacity }
    foreach ($side in $edges) {
        $isTop = ($side -eq 'Top')
        $glowStops = if ($isTop) { @(@(0.0, $Accent, $edgeGlowOpacity), @(1.0, $Accent, 0.0)) }
                     else        { @(@(0.0, $Accent, 0.0), @(1.0, $Accent, $edgeGlowOpacity)) }
        $edge = New-BannerGlassRect (New-BannerGlassLinear -Stops $glowStops)
        $edge.VerticalAlignment = if ($isTop) { [System.Windows.VerticalAlignment]::Top } else { [System.Windows.VerticalAlignment]::Bottom }
        $edge.Height = $cfg.EdgeGlowHeight
        [void]$layer.Children.Add($edge)

        $line = New-BannerGlassRect (New-BannerGlassLinear -Horizontal -Stops @(
            @(0.0,  $Accent, 0.0),
            @(0.35, $Accent, ($edgeLineOpacity * 0.55)),
            @(0.72, $Accent, $edgeLineOpacity),
            @(1.0,  $Accent, ($edgeLineOpacity * 0.25))))
        $line.VerticalAlignment = $edge.VerticalAlignment
        $line.Height = 1
        [void]$layer.Children.Add($line)
    }

    # Inner rim: bright top edge (catches the light), game colour at
    # the bottom. Radius 7 = banner radius 8 minus its 1 px border.
    $rim = New-Object System.Windows.Controls.Border
    $rim.IsHitTestVisible = $false
    $rim.CornerRadius = [System.Windows.CornerRadius]::new($RimRadius)
    $rim.BorderThickness = [System.Windows.Thickness]::new(1)
    $rim.BorderBrush = New-BannerGlassLinear -Stops @(
        @(0.0,  '#ffffff', $cfg.RimTopOpacity),
        @(0.30, '#ffffff', ($cfg.RimTopOpacity * 0.20)),
        @(0.65, $Accent, 0.0),
        @(1.0,  $Accent, $cfg.RimAccentOpacity))
    [void]$layer.Children.Add($rim)

    # Light sweep: a skewed band that crosses the banner, then rests.
    if ($cfg.SweepEnabled) {
        $isDetailHero = [string]::IsNullOrWhiteSpace($BannerName)
        $sweepOpacity = if ($isDetailHero) { $cfg.DetailSweepOpacity } else { $cfg.SweepOpacity }
        $sweepPauseSeconds = if ($isDetailHero) { $cfg.DetailSweepPauseSeconds } else { $cfg.SweepPauseSeconds }
        $band = New-Object System.Windows.Shapes.Rectangle
        $band.IsHitTestVisible = $false
        $band.Width = $cfg.SweepWidth
        $band.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $band.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $band.Fill = New-BannerGlassLinear -Horizontal -Stops @(
            @(0.0, '#ffffff', 0.0),
            @(0.5, '#ffffff', $sweepOpacity),
            @(1.0, '#ffffff', 0.0))
        $tg = New-Object System.Windows.Media.TransformGroup
        $sk = New-Object System.Windows.Media.SkewTransform
        $sk.AngleX = $cfg.SweepSkew
        $tt = New-Object System.Windows.Media.TranslateTransform
        $tt.X = -2.0 * $cfg.SweepWidth
        [void]$tg.Children.Add($sk)
        [void]$tg.Children.Add($tt)
        $band.RenderTransform = $tg
        [void]$layer.Children.Add($band)
        # (Re)start on every size change: the travel distance is the
        # real banner width, so the speed looks the same on S/M/L and
        # on any window width. Random start offset keeps the three
        # banners from sweeping in lockstep.
        $phase = (New-Object System.Random).NextDouble() * $sweepPauseSeconds
        $restart = {
            try {
                $w = $layer.ActualWidth
                if ($w -lt 40) { return }
                $from = -2.0 * $cfg.SweepWidth
                $to   = $w + $cfg.SweepWidth
                $a = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
                $a.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($cfg.SweepSeconds + $sweepPauseSeconds))
                $a.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                $a.BeginTime = [TimeSpan]::FromSeconds(-$phase)
                $k0 = New-Object System.Windows.Media.Animation.DiscreteDoubleKeyFrame $from, ([System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::Zero))
                $k1 = New-Object System.Windows.Media.Animation.EasingDoubleKeyFrame $to, ([System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($cfg.SweepSeconds)))
                $ease = New-Object System.Windows.Media.Animation.SineEase
                $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseInOut
                $k1.EasingFunction = $ease
                $k2 = New-Object System.Windows.Media.Animation.DiscreteDoubleKeyFrame $to, ([System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($cfg.SweepSeconds + $sweepPauseSeconds)))
                [void]$a.KeyFrames.Add($k0); [void]$a.KeyFrames.Add($k1); [void]$a.KeyFrames.Add($k2)
                $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $a)
            } catch { }
        }.GetNewClosure()
        $layer.Add_SizeChanged($restart)
    }
    return $layer
}

# ------------------------------------------------------------
# Apply / remove
# ------------------------------------------------------------

# Stop the sweep clock of a glass layer before it is dropped, so a
# discarded layer does not keep animating in the background.
function global:Stop-BannerGlassLayer {
    param($Layer)
    try {
        foreach ($sub in @($Layer.Children)) {
            if ($sub.RenderTransform -is [System.Windows.Media.TranslateTransform]) {
                $sub.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $null)
                $sub.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $null)
            }
            if ($sub.RenderTransform -is [System.Windows.Media.TransformGroup]) {
                foreach ($t in $sub.RenderTransform.Children) {
                    if ($t -is [System.Windows.Media.TranslateTransform]) {
                        $t.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $null)
                    }
                }
            }
        }
    } catch { }
}

function global:Remove-BannerGlass {
    param([string]$BannerName)
    $banner = $global:window.FindName($BannerName)
    if (-not $banner -or ($banner.Child -isnot [System.Windows.Controls.Grid])) { return }
    $g = $banner.Child
    for ($i = $g.Children.Count - 1; $i -ge 0; $i--) {
        $ch = $g.Children[$i]
        if ($ch -and $ch.Tag -eq 'BannerGlass') {
            Stop-BannerGlassLayer $ch
            $g.Children.RemoveAt($i)
        }
    }
}

function global:Update-BannerGlassFade {
    param([string]$BannerName)
    if (-not $global:window -or -not $BannerName) { return }
    $fade = $global:window.FindName($BannerName + 'Fade')
    if (-not $fade) { return }
    $cfg = $global:BannerGlassConfig
    $style = $global:BannerGlassStyle
    $effect = if ($global:BannerFxByBanner) { [string]$global:BannerFxByBanner[$BannerName] } else { '' }
    $fade.Opacity = if ($style -eq 'frost') { $cfg.FrostFadeOpacity }
                    elseif ($style -eq 'hero') { $cfg.HeroFadeOpacity }
                    elseif ($style -eq 'glass' -and $effect -match '^(bokeh|blob|orbs)') { $cfg.ColorBallFadeOpacity }
                    elseif ($style -eq 'glass') { $cfg.GlassFadeOpacity }
                    else { 1.0 }
}

function global:Set-BannerGlass {
    param([string]$BannerName, $Game)
    try {
        Remove-BannerGlass -BannerName $BannerName
        $cfg = $global:BannerGlassConfig
        $style = $global:BannerGlassStyle
        $isFrost = ($style -eq 'frost')
        $isHero  = ($style -eq 'hero')
        $hasAmb  = ($style -ne 'classic')
        # Per-style settings on existing banner elements. Only Opacity /
        # OpacityMask / CornerRadius are touched - properties nothing else
        # in the Hub sets on these elements - and they are put back to the
        # XAML values for glass/classic.
        $banner  = $global:window.FindName($BannerName)
        $fadeEl  = $global:window.FindName($BannerName + 'Fade')
        $bgEl    = $global:window.FindName($BannerName + 'Bg')
        $imgEl   = $global:window.FindName($BannerName + 'Image')
        if ($fadeEl) { Update-BannerGlassFade -BannerName $BannerName }
        # With the haze the flat colour rectangle is hidden (Opacity 0), so
        # the haze can sit BELOW it at index 0 and the banner effects (which
        # insert at index 1) stay visible above the haze.
        # (Set to 0 below only once a haze layer was actually built, so a
        # game without any art keeps its colour background.)
        if ($bgEl) { $bgEl.Opacity = 1.0 }
        if ($banner -is [System.Windows.Controls.Border]) {
            $banner.CornerRadius = [System.Windows.CornerRadius]::new($(if ($isHero) { $cfg.HeroCornerRadius } else { 8 }))
        }
        if ($imgEl) {
            if ($isHero) {
                $mask = New-Object System.Windows.Media.LinearGradientBrush
                $mask.StartPoint = [System.Windows.Point]::new(0, 0.5)
                $mask.EndPoint   = [System.Windows.Point]::new(1, 0.5)
                [void]$mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 0, 0, 0), 0.0))
                [void]$mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 0, 0, 0), $cfg.HeroMaskEnd))
                [void]$mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 0, 0, 0), 1.0))
                $mask.Freeze()
                $imgEl.OpacityMask = $mask
            } else {
                $imgEl.OpacityMask = $null
            }
        }
        if ($style -eq 'classic') { return }
        if (-not $Game) { return }
        if (-not $banner -or ($banner.Child -isnot [System.Windows.Controls.Grid])) { return }
        $g = $banner.Child
        $accent = ConvertTo-BannerGlassAccent -Hex (Resolve-BannerGlassBaseHex -Game $Game) -MinValue $cfg.AccentMinValue -MaxSat $cfg.AccentMaxSat

        # Base layer right above the background rectangle.
        $bg = $global:window.FindName($BannerName + 'Bg')
        $bgIdx = if ($bg) { $g.Children.IndexOf($bg) } else { 0 }
        if ($bgIdx -lt 0) { $bgIdx = 0 }
        $baseLayer = New-BannerGlassBase -Accent $accent -Uniform:($style -eq 'glass')
        $g.Children.Insert([Math]::Min($bgIdx + 1, $g.Children.Count), $baseLayer)
        if ($hasAmb) {
            try {
                $ambOp = $(if ($isHero) { $cfg.HeroAmbientOpacity } else { $cfg.AmbientOpacity })
                $amb = New-BannerGlassAmbient -Game $Game -Opacity $ambOp -ImageSource $(if ($imgEl) { $imgEl.Source } else { $null }) -ImageElement $imgEl
                if ($amb) {
                    if ($style -eq 'glass') {
                        # Keep the original opaque milk-glass base. A very soft
                        # colour echo travels above it, below the banner FX.
                        $amb.Children[0].Opacity = $cfg.GlassAmbientOpacity
                        $amb.Children[0].Effect.Radius = $cfg.GlassAmbientBlur
                        $amb.Children[1].Visibility = [System.Windows.Visibility]::Collapsed
                        $g.Children.Insert($g.Children.IndexOf($baseLayer) + 1, $amb)
                    } else {
                        $g.Children.Insert(0, $amb)
                        if ($bgEl) { $bgEl.Opacity = 0.0 }
                    }
                }
            } catch { }
        }

        # Top layer right above the left-side fade (so above the art and
        # every banner effect), below the back button / title block.
        $fade = $global:window.FindName($BannerName + 'Fade')
        $fadeIdx = if ($fade) { $g.Children.IndexOf($fade) } else { -1 }
        $topIdx = if ($fadeIdx -ge 0) { $fadeIdx + 1 } else { $g.Children.Count }
        $rimR = $(if ($isHero) { $cfg.HeroCornerRadius - 1 } else { 7 })
        $g.Children.Insert($topIdx, (New-BannerGlassTop -Accent $accent -BannerName $BannerName -Frost:$isFrost -RimRadius $rimR -ImageElement $imgEl))
    } catch {
        try { Remove-BannerGlass -BannerName $BannerName } catch { }
        if (Get-Command Write-HubTiming -ErrorAction SilentlyContinue) {
            Write-HubTiming ("bannerglass: {0} failed: {1}" -f $BannerName, $_.Exception.Message)
        }
    }
}

function global:Get-BannerGlassGameFor {
    param([string]$BannerName)
    switch ($BannerName) {
        'ListBanner' { return $global:ListBannerGame }
        'LibBanner'  { return $global:LibBannerGame }
        'OvBanner'   { return $global:OvBannerGame }
    }
    return $null
}

# --- Frost: glass pills on the banner buttons --------------------
# The buttons keep their own handlers (hover sweep, press border, leave
# reset). Ours are added AFTER theirs, so on leave we put the glass fill
# back, and on enter the glass fill (brighter) + glow replace the sweep.
# Base colour = the button's own border colour from the XAML.
function global:Get-BannerGlassPillBrush {
    param([string]$Hex, [double]$Boost = 1.0)
    $cfg = $global:BannerGlassConfig
    $hi = Get-BannerGlassMix $Hex '#ffffff' 0.35
    return (New-BannerGlassLinear -Stops @(
        @(0.0,  $hi,  [Math]::Min(1.0, $cfg.PillOpacityTop * $Boost)),
        @(0.55, $Hex, [Math]::Min(1.0, ($cfg.PillOpacityTop * 0.45) * $Boost)),
        @(1.0,  $Hex, [Math]::Min(1.0, $cfg.PillOpacityBot * $Boost))))
}

function global:Set-BannerGlassPill {
    param($Btn, [switch]$Hover)
    if (-not $Btn) { return }
    $hex = $global:BannerGlassPillColor[[string]$Btn.Name]
    if (-not $hex) { return }
    if ($global:BannerGlassStyle -ne 'frost' -and $global:BannerGlassStyle -ne 'hero') {
        if ($Btn.Effect -and $Btn.Effect.GetType().Name -eq 'DropShadowEffect' -and $global:BannerGlassPillGlows.Contains($Btn.Effect)) { $Btn.Effect = $null }
        return
    }
    $cfg = $global:BannerGlassConfig
    if ($Hover) {
        $Btn.Background = Get-BannerGlassPillBrush $hex $cfg.PillHoverBoost
        $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
        $glow.ShadowDepth = 0
        $glow.BlurRadius = $cfg.PillGlowBlur
        $glow.Color = New-BannerGlassColor $hex 1.0
        $glow.Opacity = $cfg.PillGlowOpacity
        [void]$global:BannerGlassPillGlows.Add($glow)
        $Btn.Effect = $glow
    } else {
        $Btn.Background = Get-BannerGlassPillBrush $hex 1.0
        if ($Btn.Effect -and $global:BannerGlassPillGlows.Contains($Btn.Effect)) { $Btn.Effect = $null }
        $global:BannerGlassPillGlows.Clear()
    }
}

function global:Initialize-BannerGlassPills {
    $global:BannerGlassPillColor = @{}
    $global:BannerGlassPillGlows = New-Object System.Collections.ArrayList
    foreach ($n in $global:BannerGlassButtons) {
        $b = $global:window.FindName($n)
        if (-not $b) { continue }
        try {
            if ($b.BorderBrush -is [System.Windows.Media.SolidColorBrush]) {
                $c = $b.BorderBrush.Color
                $global:BannerGlassPillColor[$n] = ('#{0:x2}{1:x2}{2:x2}' -f $c.R, $c.G, $c.B)
            }
            $b.Add_MouseEnter({ try { if ($global:BannerGlassStyle -eq 'frost' -or $global:BannerGlassStyle -eq 'hero') { Set-BannerGlassPill -Btn $this -Hover } } catch { } })
            $b.Add_MouseLeave({ try { if ($global:BannerGlassStyle -eq 'frost' -or $global:BannerGlassStyle -eq 'hero') { Set-BannerGlassPill -Btn $this } } catch { } })
        } catch { }
    }
}

function global:Update-BannerGlassPills {
    if (-not $global:BannerGlassPillColor) { return }
    foreach ($n in $global:BannerGlassButtons) {
        $b = $global:window.FindName($n)
        if (-not $b -or -not $global:BannerGlassPillColor[$n]) { continue }
        try {
            if ($global:BannerGlassStyle -eq 'frost' -or $global:BannerGlassStyle -eq 'hero') {
                Set-BannerGlassPill -Btn $b
            } else {
                $b.Background = [System.Windows.Media.Brushes]::Transparent
                if ($b.Effect -and $global:BannerGlassPillGlows.Contains($b.Effect)) { $b.Effect = $null }
            }
        } catch { }
    }
}

# --- Game detail page hero ---------------------------------------
# Called from DetailView.Page.ps1 right after the hero is built (one
# guarded line). Keeps a reference so a style switch re-applies it live.
function global:Set-DetailHeroGlass {
    $hero = $global:BannerGlassDetailHero
    if (-not $hero -or ($hero.Child -isnot [System.Windows.Controls.Grid])) { return }
    $g = $hero.Child
    for ($i = $g.Children.Count - 1; $i -ge 0; $i--) {
        $ch = $g.Children[$i]
        if ($ch -and $ch.Tag -eq 'BannerGlass') { Stop-BannerGlassLayer $ch; $g.Children.RemoveAt($i) }
    }
    Update-DetailHeroMask
    if ($global:BannerGlassStyle -eq 'classic') { return }
    $cfg = $global:BannerGlassConfig
    $accent = ConvertTo-BannerGlassAccent -Hex $global:BannerGlassDetailAccent -MinValue $cfg.AccentMinValue -MaxSat $cfg.AccentMaxSat
    # Haze of the header art at the very bottom (ZIndex -1): below the
    # title placeholder, the side-band effects (0) and the image (5).
    if ($global:BannerGlassDetailGame) {
        try {
            $heroImage = @($g.Children | Where-Object { $_ -is [System.Windows.Controls.Image] -and $_.Tag -ne 'BannerGlass' }) | Select-Object -First 1
            $amb = New-BannerGlassAmbient -Game $global:BannerGlassDetailGame -Opacity $cfg.DetailAmbientOpacity -ImageSource $(if ($heroImage) { $heroImage.Source } else { $null }) -ImageElement $heroImage
            if ($amb) {
                [System.Windows.Controls.Panel]::SetZIndex($amb, -1)
                $g.Children.Insert(0, $amb)
            }
        } catch { }
    }
    # The hero has no border, so the rim follows its full radius.
    $r = 10.0
    try { $r = [double]$hero.CornerRadius.TopLeft } catch { }
    $top = New-BannerGlassTop -Accent $accent -RimRadius $r
    # Above the header image (the wide layout lifts it to ZIndex 5) and
    # the side-band effects (ZIndex 0).
    [System.Windows.Controls.Panel]::SetZIndex($top, 10)
    [void]$g.Children.Add($top)
}

# Wide layout only (image frozen + centred, side bands visible): fade the
# image's left/right edge into the haze instead of a hard cut. Narrow
# (full-bleed) and Classic: no mask.
function global:Update-DetailHeroMask {
    $hero = $global:BannerGlassDetailHero
    if (-not $hero -or ($hero.Child -isnot [System.Windows.Controls.Grid])) { return }
    $cfg = $global:BannerGlassConfig
    $img = $null
    foreach ($ch in $hero.Child.Children) {
        if ($ch -is [System.Windows.Controls.Image] -and $ch.Tag -ne 'BannerGlass') { $img = $ch; break }
    }
    if (-not $img) { return }
    $wide = ($hero.ActualWidth -ge $cfg.DetailWideThreshold)
    if ($wide -and $global:BannerGlassStyle -ne 'classic') {
        $f = [double]$cfg.DetailMaskFrac
        $m = New-Object System.Windows.Media.LinearGradientBrush
        $m.StartPoint = [System.Windows.Point]::new(0, 0.5)
        $m.EndPoint   = [System.Windows.Point]::new(1, 0.5)
        [void]$m.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 0, 0, 0), 0.0))
        [void]$m.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 0, 0, 0), $f))
        [void]$m.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 0, 0, 0), 1.0 - $f))
        [void]$m.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 0, 0, 0), 1.0))
        $m.Freeze()
        $img.OpacityMask = $m
    } else {
        $img.OpacityMask = $null
    }
}

function global:Add-DetailHeroGlass {
    param($Hero, $Game, [string]$AccentHex)
    if (-not $global:HubBannerGlass) { return }
    try {
        $hex = $AccentHex
        if (-not (ConvertFrom-BannerGlassHex $hex)) { $hex = Resolve-BannerGlassBaseHex -Game $Game }
        $global:BannerGlassDetailAccent = $hex
        $global:BannerGlassDetailGame = $Game
        # The previous page's hero is discarded - stop its sweep first.
        $old = $global:BannerGlassDetailHero
        $global:BannerGlassDetailHero = $Hero
        try {
            if ($old -and -not [object]::ReferenceEquals($old, $Hero) -and ($old.Child -is [System.Windows.Controls.Grid])) {
                foreach ($ch in @($old.Child.Children)) { if ($ch -and $ch.Tag -eq 'BannerGlass') { Stop-BannerGlassLayer $ch } }
            }
        } catch { }
        # Re-check the mask whenever the hero switches between the wide
        # and the narrow layout (window resize / maximize).
        try {
            if ($Hero -and -not [object]::ReferenceEquals($old, $Hero)) {
                $Hero.Add_SizeChanged({ try { if ([object]::ReferenceEquals($this, $global:BannerGlassDetailHero)) { Update-DetailHeroMask } } catch { } })
                $Hero.Add_Loaded({ try { if ([object]::ReferenceEquals($this, $global:BannerGlassDetailHero)) { Update-DetailHeroMask } } catch { } })
            }
        } catch { }
        Set-DetailHeroGlass
    } catch {
        if (Get-Command Write-HubTiming -ErrorAction SilentlyContinue) {
            Write-HubTiming ("bannerglass: detail hero failed: {0}" -f $_.Exception.Message)
        }
    }
}

function global:Update-AllBannerGlass {
    foreach ($n in $global:BannerGlassBanners) {
        Set-BannerGlass -BannerName $n -Game (Get-BannerGlassGameFor $n)
    }
    try { Set-DetailHeroGlass } catch { }
    try { Update-BannerGlassPills } catch { }
}

function global:Set-BannerGlassStyle {
    param([string]$Style, [switch]$Save)
    $global:BannerGlassStyle = Resolve-BannerGlassStyle $Style
    if ($Save) {
        try {
            if (Get-Command Request-HeaderFxSettingSave -ErrorAction SilentlyContinue) {
                Request-HeaderFxSettingSave -Key 'bannerGlassStyle' -Value $global:BannerGlassStyle
            } elseif (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
                Set-HubSetting -Key 'bannerGlassStyle' -Value $global:BannerGlassStyle
            }
        } catch { }
    }
    Update-AllBannerGlass
}

# --- Help & feedback menu ---------------------------------------
# One item, inserted after the HeaderFx items when they exist (else
# after "Switch Hub Style"), same look. Clicking does NOT close the
# menu, so the banner behind it can be compared at once.
function global:New-BannerGlassMenuItem {
    $b = New-Object System.Windows.Controls.Border
    $b.Name = 'MiBannerGlass'
    $b.Background = [System.Windows.Media.Brushes]::Transparent
    $b.CornerRadius = [System.Windows.CornerRadius]::new(7)
    $b.Padding = [System.Windows.Thickness]::new(8, 9, 8, 9)
    $b.Cursor = [System.Windows.Input.Cursors]::Hand
    $row = New-Object System.Windows.Controls.StackPanel
    $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $dot = New-Object System.Windows.Shapes.Ellipse
    $dot.Width = 8; $dot.Height = 8
    $dot.Fill = New-Object System.Windows.Media.SolidColorBrush (New-BannerGlassColor '#f0d860' 1.0)
    $dot.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $dot.Margin = [System.Windows.Thickness]::new(2, 0, 11, 0)
    $col = New-Object System.Windows.Controls.StackPanel
    $t1 = New-Object System.Windows.Controls.TextBlock
    $t1.Text = 'Banner style'; $t1.FontSize = 13
    $t1.Foreground = New-Object System.Windows.Media.SolidColorBrush (New-BannerGlassColor '#d8dee3' 1.0)
    $t1.FontFamily = New-Object System.Windows.Media.FontFamily 'Segoe UI'
    $t2 = New-Object System.Windows.Controls.TextBlock
    $t2.FontSize = 11
    $t2.Foreground = New-Object System.Windows.Media.SolidColorBrush (New-BannerGlassColor '#6a6a7e' 1.0)
    $t2.FontFamily = New-Object System.Windows.Media.FontFamily 'Segoe UI'
    $t2.Margin = [System.Windows.Thickness]::new(0, 2, 0, 0)
    [void]$col.Children.Add($t1); [void]$col.Children.Add($t2)
    [void]$row.Children.Add($dot); [void]$row.Children.Add($col)
    $b.Child = $row
    $hover = New-Object System.Windows.Media.SolidColorBrush (New-BannerGlassColor '#1e1e2a' 1.0)
    $b.Add_MouseEnter({ $this.Background = $hover }.GetNewClosure())
    $b.Add_MouseLeave({ $this.Background = [System.Windows.Media.Brushes]::Transparent })
    return [pscustomobject]@{ Item = $b; Sub = $t2 }
}

function global:Update-BannerGlassMenuItem {
    if (-not $global:BannerGlassMenuSub) { return }
    $cur = Resolve-BannerGlassStyle $global:BannerGlassStyle
    $global:BannerGlassMenuSub.Text = [string]$global:BannerGlassStyleLabels[$cur]
}

function global:Add-BannerGlassMenuItem {
    $anchor = $global:window.FindName('MiStyle')
    if (-not $anchor) { return }
    $panel = $anchor.Parent
    if ($panel -isnot [System.Windows.Controls.Panel]) { return }
    $at = $panel.Children.IndexOf($anchor) + 1
    foreach ($ch in @($panel.Children)) {
        if ($ch -is [System.Windows.FrameworkElement] -and ($ch.Name -eq 'MiHeaderFxStyle' -or $ch.Name -eq 'MiHeaderFxSpeed')) {
            $i = $panel.Children.IndexOf($ch) + 1
            if ($i -gt $at) { $at = $i }
        }
    }
    $mi = New-BannerGlassMenuItem
    $mi.Item.Add_MouseLeftButtonUp({ param($s, $e)
        $e.Handled = $true
        try {
            Set-BannerGlassStyle -Style (Get-BannerGlassNextStyle -Current $global:BannerGlassStyle) -Save
            Update-BannerGlassMenuItem
        } catch { }
    })
    $panel.Children.Insert($at, $mi.Item)
    $global:BannerGlassMenuSub = $mi.Sub
    Update-BannerGlassMenuItem
}

# --- wiring -----------------------------------------------------
try {
    if ($global:HubBannerGlass -and $global:window -and -not $global:BannerGlassWrapped) {
        $stored = $null
        if (Get-Command Get-HubSetting -ErrorAction SilentlyContinue) {
            try { $stored = Get-HubSetting -Key 'bannerGlassStyle' -Default $null } catch { $stored = $null }
        }
        $global:BannerGlassStyle = Resolve-BannerGlassStyle $stored

        # Wrap Set-BannerForGame: every banner fill (startup, rotation,
        # shuffle, genre chips, S/M/L refits) runs through it, so the glass
        # re-tints itself without touching any caller.
        $inner = Get-Command Set-BannerForGame -CommandType Function -ErrorAction SilentlyContinue
        if ($inner) {
            $global:BannerGlassInnerSetBanner = $inner.ScriptBlock
            function global:Set-BannerForGame {
                param($Game, $TitleEl, $SubEl, $ImageEl, $BgEl, $DotEl, $KickerEl, [string]$KickerPrefix = "FEATURED VR MOD")
                & $global:BannerGlassInnerSetBanner @PSBoundParameters
                try {
                    if ($BgEl -and $Game) {
                        $bn = Get-BannerGlassNameFromBg -BgName ([string]$BgEl.Name)
                        if ($bn) { Set-BannerGlass -BannerName $bn -Game $Game }
                    }
                } catch { }
            }
            $global:BannerGlassWrapped = $true
        }

        try { Initialize-BannerGlassPills } catch { Write-HubTiming ("bannerglass: pills failed: {0}" -f $_.Exception.Message) }
        try { Add-BannerGlassMenuItem } catch { Write-HubTiming ("bannerglass: menu item failed: {0}" -f $_.Exception.Message) }
        if ($global:menuOverlay) {
            $global:menuOverlay.Add_IsVisibleChanged({ try { if ($global:menuOverlay.IsVisible) { Update-BannerGlassMenuItem } } catch { } })
        }
        # The List/Library banners were already filled (Filter.Banners.ps1)
        # before this file loaded - give them their glass now.
        Update-AllBannerGlass
        Write-HubTiming ("bannerglass: ready, style {0}" -f $global:BannerGlassStyle)
    }
} catch {
    try { Write-HubTiming ("bannerglass: disabled after error: {0}" -f $_.Exception.Message) } catch { }
}
