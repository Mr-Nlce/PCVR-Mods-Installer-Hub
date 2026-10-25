# ============================================================
# HeaderFx.ps1 - animated background behind the
# header (HeaderBorder + FilterBar)
#
#   Styles chosen PER PAGE in Help & feedback -> "Header style"
#   and kept in the Hub settings (headerFxStyle_<page>):
#     none   - the old flat header
#     images - "game frieze": tilted catalog portraits drifting sideways
#     bokeh  - detail-page-only soft orbs in the game's cover colours.
#     glass  - detail-page alternative with the blurred game header
#              behind the orbs.
#   Pages: list (ListScroll), library (DiscoverHost tiles), explore
#   (DiscoverOverviewScroll), detail (DiscoverDetailScroll).
#   Defaults: images on list/library/explore, bokeh on detail.
#   "Header speed" (headerFxSpeed, 0 = still ... 2 = double) scales
#   every frieze/orb animation live, without rebuilding anything.
#
# The header-glasses click and Help menu both use Switch-HeaderFxStyle.
# The effect may be disabled with $global:HubHeaderFx = $false below.
# With the switch off the header keeps its original flat #0f0f12.
#
# No network on startup: the frieze only uses portraits that are
# already on disk (bundled Assets or the Hub's own image cache).
# Everything is wrapped so a failure leaves the plain header.
# ============================================================

$global:HubHeaderFx = $true

# Tuning knobs - all looks are adjusted here, nothing else needs to
# change. Opacities are 0..1.
$global:HeaderFxConfig = @{
    BaseHex            = '#0f0f12'  # Hub window background; scrims fade into it
    FriezeCount        = 18         # different portraits per start (strip is doubled for the loop)
    FriezeTileW        = 150        # keep 2 * FriezeCount * (W + Gap) under ~8000 px (one cached bitmap)
    FriezeTileH        = 240
    FriezeGap          = 10
    FriezeAngle        = -6         # degrees
    FriezeOpacity      = 0.42
    FriezeStartFrac    = 0.36       # strip starts at this fraction of the header width
    FriezePxPerSecond  = 12         # drift speed
    AmbientOpacity     = 0.70
    AmbientDecodeW     = 48         # tiny decode = free blur when stretched
    AmbientBlur        = 34
    OrbCount           = 6
    DetailOrbCount     = 8
    OrbMinSize         = 170
    OrbMaxSize         = 300
    OrbMinOpacity      = 0.40       # same range as Add-BannerOrbs (0.4..0.6)
    OrbMaxOpacity      = 0.60
    OrbBlur            = 22         # Add-BannerOrbs uses 22
    OrbDriftX          = 70         # px each way - the orbs WANDER, not wobble
    OrbDriftY          = 24
    OrbMinSeconds      = 7          # one sweep; x and y use different periods
    OrbMaxSeconds      = 13
    FadeMs             = 450
}

# ------------------------------------------------------------
# Pure helpers (no WPF) - testable on any host
# ------------------------------------------------------------
function global:ConvertTo-HeaderFxHsv {
    param([double]$R, [double]$G, [double]$B)   # 0..255
    $r = $R / 255.0; $g = $G / 255.0; $b = $B / 255.0
    $max = [Math]::Max($r, [Math]::Max($g, $b))
    $min = [Math]::Min($r, [Math]::Min($g, $b))
    $d = $max - $min
    $h = 0.0
    if ($d -gt 0.00001) {
        if ($max -eq $r)     { $h = 60.0 * ((($g - $b) / $d) % 6.0) }
        elseif ($max -eq $g) { $h = 60.0 * ((($b - $r) / $d) + 2.0) }
        else                 { $h = 60.0 * ((($r - $g) / $d) + 4.0) }
    }
    if ($h -lt 0) { $h += 360.0 }
    $s = if ($max -le 0) { 0.0 } else { $d / $max }
    return @($h, $s, $max)
}

function global:ConvertFrom-HeaderFxHsv {
    param([double]$H, [double]$S, [double]$V)   # H 0..360, S/V 0..1 -> '#rrggbb'
    $H = (($H % 360.0) + 360.0) % 360.0
    $c = $V * $S
    $x = $c * (1 - [Math]::Abs((($H / 60.0) % 2.0) - 1))
    $m = $V - $c
    $rgb = switch ([int][Math]::Floor($H / 60.0)) {
        0 { @($c, $x, 0) } 1 { @($x, $c, 0) } 2 { @(0, $c, $x) }
        3 { @(0, $x, $c) } 4 { @($x, 0, $c) } default { @($c, 0, $x) }
    }
    $r = [int][Math]::Round(($rgb[0] + $m) * 255)
    $g = [int][Math]::Round(($rgb[1] + $m) * 255)
    $b = [int][Math]::Round(($rgb[2] + $m) * 255)
    return ('#{0:x2}{1:x2}{2:x2}' -f $r, $g, $b)
}

function global:Get-HeaderFxHueDistance {
    param([double]$A, [double]$B)
    $d = [Math]::Abs($A - $B) % 360.0
    if ($d -gt 180) { $d = 360 - $d }
    return $d
}

# Pick up to $Max vivid, clearly different colours from a BGRA32
# pixel buffer. Dark and grey pixels are ignored; the remaining ones
# are binned by hue (24 bins) and weighted by saturation * value, so
# the colours that visually dominate the art win. Every result is
# pushed to orb-friendly brightness/saturation. If $BaseHex (the
# curated per-game banner colour) is given it always comes first.
# Too few vivid colours (grey/brown art) -> hue-shifted siblings of
# the first colour fill up, so there are always $Max entries.
function global:Get-HeaderFxPalette {
    param([byte[]]$Pixels, [int]$Width, [int]$Height, [int]$Stride, [string]$BaseHex, [int]$Max = 4)
    $out = New-Object System.Collections.ArrayList
    $hues = New-Object System.Collections.ArrayList
    if ($BaseHex -and $BaseHex -match '^#?([0-9a-fA-F]{6})$') {
        $hx = $Matches[1]
        $hsv = ConvertTo-HeaderFxHsv ([Convert]::ToInt32($hx.Substring(0,2),16)) ([Convert]::ToInt32($hx.Substring(2,2),16)) ([Convert]::ToInt32($hx.Substring(4,2),16))
        [void]$out.Add((ConvertFrom-HeaderFxHsv $hsv[0] ([Math]::Max(0.55, $hsv[1])) ([Math]::Max(0.85, $hsv[2]))))
        [void]$hues.Add($hsv[0])
    }
    if ($Pixels -and $Width -gt 0 -and $Height -gt 0) {
        if ($Stride -le 0) { $Stride = $Width * 4 }
        $bins = 24
        $wt = New-Object 'double[]' $bins
        $sr = New-Object 'double[]' $bins; $sg = New-Object 'double[]' $bins; $sb = New-Object 'double[]' $bins
        for ($y = 0; $y -lt $Height; $y++) {
            $row = $y * $Stride
            for ($x = 0; $x -lt $Width; $x++) {
                $i = $row + ($x * 4)
                if ($i + 2 -ge $Pixels.Length) { break }
                $b = [double]$Pixels[$i]; $g = [double]$Pixels[$i + 1]; $r = [double]$Pixels[$i + 2]
                $hsv = ConvertTo-HeaderFxHsv $r $g $b
                if ($hsv[2] -lt 0.25 -or $hsv[1] -lt 0.30) { continue }
                $k = [int][Math]::Floor($hsv[0] / (360.0 / $bins)) % $bins
                $w = $hsv[1] * $hsv[2]
                $wt[$k] += $w; $sr[$k] += $r * $w; $sg[$k] += $g * $w; $sb[$k] += $b * $w
            }
        }
        $order = 0..($bins - 1) | Where-Object { $wt[$_] -gt 0 } | Sort-Object { -$wt[$_] }
        $total = 0.0; foreach ($k in $order) { $total += $wt[$k] }
        foreach ($k in $order) {
            if ($out.Count -ge $Max) { break }
            if ($total -gt 0 -and ($wt[$k] / $total) -lt 0.04) { break }   # stray specks are not a colour of the game
            $hsv = ConvertTo-HeaderFxHsv ($sr[$k] / $wt[$k]) ($sg[$k] / $wt[$k]) ($sb[$k] / $wt[$k])
            $tooClose = $false
            foreach ($h in $hues) { if ((Get-HeaderFxHueDistance $h $hsv[0]) -lt 28) { $tooClose = $true; break } }
            if ($tooClose) { continue }
            [void]$out.Add((ConvertFrom-HeaderFxHsv $hsv[0] ([Math]::Max(0.55, $hsv[1])) ([Math]::Max(0.85, $hsv[2]))))
            [void]$hues.Add($hsv[0])
        }
    }
    if ($out.Count -eq 0) { [void]$out.Add('#ff8a22'); [void]$hues.Add(28.0) }   # Hub orange
    # Fill up with NEIGHBOURS of colours the game really has (a paler and
    # a deeper, slightly turned tone) - never with foreign hues, otherwise
    # a blue game would suddenly get magenta orbs.
    $found = $hues.Count
    $variants = @(@(12, 0.40, 1.00), @(-12, 0.85, 0.80))
    $vi = 0
    while ($out.Count -lt $Max -and $vi -lt ($found * $variants.Count)) {
        $v = $variants[[int][Math]::Floor($vi / $found)]
        $h0 = [double]$hues[$vi % $found]
        [void]$out.Add((ConvertFrom-HeaderFxHsv ($h0 + $v[0]) $v[1] $v[2])); $vi++
    }
    return ,([string[]]$out.ToArray())
}

# ------------------------------------------------------------
# Per-page style + speed (pure - testable without WPF)
# ------------------------------------------------------------
$global:HeaderFxStyleOrder  = @('none', 'images')
$global:HeaderFxDetailStyleOrder = @('none', 'images', 'bokeh', 'glass')
$global:HeaderFxStyleLabels = @{ none = 'Off'; images = 'Moving images'; bokeh = 'Glowing orbs'; glass = 'Glass colours' }
$global:HeaderFxPageLabels  = @{ list = 'List view'; library = 'Library'; explore = 'Explore'; detail = 'Game page' }
$global:HeaderFxDefaultStyle = @{ list = 'images'; library = 'images'; explore = 'images'; detail = 'bokeh' }
$global:HeaderFxSpeedSteps  = @(0.0, 0.5, 1.0, 1.5, 2.0)

# Which page is showing. Detail and Explore live INSIDE DiscoverHost,
# so they are checked first; DiscoverHost alone means the Library tiles.
function global:Get-HeaderFxContextFor {
    param([bool]$DetailVisible, [bool]$OverviewVisible, [bool]$LibraryVisible, [bool]$ListVisible)
    if ($DetailVisible)   { return 'detail' }
    if ($OverviewVisible) { return 'explore' }
    if ($LibraryVisible)  { return 'library' }
    return 'list'
}

function global:Get-HeaderFxStyleKey {
    param([string]$Context)
    return ('headerFxStyle_' + $Context)
}

# Stored value -> valid style; anything unknown falls back to the page default.
function global:Resolve-HeaderFxStyle {
    param([string]$Context, $Stored)
    $v = ([string]$Stored).Trim().ToLowerInvariant()
    $order = if ($Context -eq 'detail') { $global:HeaderFxDetailStyleOrder } else { $global:HeaderFxStyleOrder }
    if ($order -contains $v) { return $v }
    $d = $global:HeaderFxDefaultStyle[$Context]
    if ($d) { return $d }
    return 'images'
}

function global:Get-HeaderFxNextStyle {
    param([string]$Current, [string]$Context = 'list')
    $order = if ($Context -eq 'detail') { $global:HeaderFxDetailStyleOrder } else { $global:HeaderFxStyleOrder }
    $i = [array]::IndexOf([string[]]$order, [string]$Current)
    if ($i -lt 0) { return $order[0] }
    return $order[($i + 1) % $order.Count]
}

# Stored value -> speed 0..2; unreadable -> 1 (normal).
function global:ConvertTo-HeaderFxSpeed {
    param($Stored)
    $d = 0.0
    $txt = ([string]$Stored).Trim().Replace(',', '.')
    if (-not [double]::TryParse($txt, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)) { return 1.0 }
    if ([double]::IsNaN($d)) { return 1.0 }
    return [Math]::Min(2.0, [Math]::Max(0.0, $d))
}

function global:Get-HeaderFxNextSpeed {
    param([double]$Current)
    foreach ($s in $global:HeaderFxSpeedSteps) { if ($s -gt ($Current + 0.001)) { return [double]$s } }
    return [double]$global:HeaderFxSpeedSteps[0]
}

function global:Format-HeaderFxSpeed {
    param([double]$Speed)
    if ($Speed -le 0) { return 'Still' }
    return ($Speed.ToString('0.##', [Globalization.CultureInfo]::InvariantCulture) + 'x')
}

# Portrait sources that need NO network: bundled Assets first, then
# portraits the Hub has already cached. Returns file:// URIs.
# Runs on the UI thread, so no per-game Test-Path/Get-Command: the
# cache folder is listed ONCE and looked up in a hashtable, bundled
# files use [IO.File]::Exists, and only the final picks become URIs.
function global:Get-HeaderFxPortraitUris {
    param([object[]]$Games, [int]$Count = 18, [int]$Seed = -1, [string]$CacheDir)
    if (-not $CacheDir -and (Get-Command Get-ImageCacheDir -ErrorAction SilentlyContinue)) {
        try { $CacheDir = Get-ImageCacheDir } catch { $CacheDir = $null }
    }
    $cached = @{}
    if ($CacheDir -and [IO.Directory]::Exists($CacheDir)) {
        try {
            foreach ($f in [IO.Directory]::EnumerateFiles($CacheDir, 'steam_*_portrait.jpg')) {
                if ((New-Object IO.FileInfo $f).Length -gt 0) { $cached[[IO.Path]::GetFileName($f).ToLowerInvariant()] = $f }
            }
        } catch { }
    }
    $root = $global:HubHelpersCoreRoot
    $all = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($g in $Games) {
        if (-not $g) { continue }
        $path = $null
        try {
            $p = [string]$g.PortraitUrl
            if ($p -and $root -and $p -notmatch '^https?://') {
                $abs = [IO.Path]::Combine($root, ($p -replace '[\\/]', [IO.Path]::DirectorySeparatorChar))
                if ([IO.File]::Exists($abs)) { $path = $abs }
            }
            if (-not $path -and $g.SteamId) {
                $k = ('steam_{0}_portrait.jpg' -f $g.SteamId).ToLowerInvariant()
                if ($cached.ContainsKey($k)) { $path = $cached[$k] }
            }
        } catch { $path = $null }
        if ($path -and -not $seen.ContainsKey($path)) { $seen[$path] = $true; [void]$all.Add($path) }
    }
    $rand = if ($Seed -ge 0) { New-Object System.Random $Seed } else { New-Object System.Random }
    # Fisher-Yates so every start shows a different selection.
    for ($i = $all.Count - 1; $i -gt 0; $i--) {
        $j = $rand.Next(0, $i + 1)
        $t = $all[$i]; $all[$i] = $all[$j]; $all[$j] = $t
    }
    $n = [Math]::Min($Count, $all.Count)
    $out = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $n; $i++) {
        $u = ConvertTo-HubFileUri -Path $all[$i]
        if ($u) { [void]$out.Add($u) }
    }
    return ,([string[]]$out.ToArray())
}

# Header art for the ambient echo: local file, cached Steam header,
# then the online URL (the detail page loads that one anyway).
function global:Get-HeaderFxAmbientUri {
    param($Game)
    if (-not $Game) { return $null }
    try {
        $h = [string]$Game.HeaderUrl
        if ($h -and $h -notmatch '^https?://' -and $global:HubHelpersCoreRoot) {
            $abs = Join-Path $global:HubHelpersCoreRoot $h
            if (Test-Path -LiteralPath $abs) { return (ConvertTo-HubFileUri -Path $abs) }
        }
        if ($Game.SteamId -and (Get-Command Get-CachedImageUri -ErrorAction SilentlyContinue)) {
            $c = Get-CachedImageUri -SteamId ([string]$Game.SteamId) -Kind 'header'
            if ($c) { return $c }
        }
        if (Get-Command Get-GameImageUrl -ErrorAction SilentlyContinue) {
            return (Get-GameImageUrl -Game $Game -Kind 'header')
        }
    } catch { }
    return $null
}

# Everything below needs WPF and a window. On a host without either
# (tests, Linux pwsh) the pure helpers above stay available.
if (-not $global:HubHeaderFx) { return }
if (-not $global:window) { return }
if (-not ('System.Windows.Media.Brush' -as [type])) { return }

# ------------------------------------------------------------
# WPF part
# ------------------------------------------------------------
function global:New-HeaderFxBrush {
    param([string]$Hex, [byte]$Alpha = 255)
    $c = [System.Windows.Media.ColorConverter]::ConvertFromString($Hex)
    $b = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb($Alpha, $c.R, $c.G, $c.B))
    $b.Freeze()
    return $b
}

# Horizontal or vertical fade from the Hub background colour into
# transparent; stops are @(offset, alpha) pairs.
function global:New-HeaderFxScrim {
    param([string]$Direction, [object[]]$Stops)
    $base = [System.Windows.Media.ColorConverter]::ConvertFromString($global:HeaderFxConfig.BaseHex)
    $lg = New-Object System.Windows.Media.LinearGradientBrush
    if ($Direction -eq 'left') {
        $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(1, 0)
    } else {
        $lg.StartPoint = [System.Windows.Point]::new(0, 1); $lg.EndPoint = [System.Windows.Point]::new(0, 0)
    }
    foreach ($s in $Stops) {
        $col = [System.Windows.Media.Color]::FromArgb([byte]$s[1], $base.R, $base.G, $base.B)
        [void]$lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($col, [double]$s[0]))
    }
    $lg.Freeze()
    $r = New-Object System.Windows.Shapes.Rectangle
    $r.Fill = $lg
    $r.IsHitTestVisible = $false
    return $r
}

function global:New-HeaderFxBitmap {
    param([string]$Uri, [int]$DecodeWidth)
    $bi = New-Object System.Windows.Media.Imaging.BitmapImage
    $bi.BeginInit()
    $bi.UriSource = [Uri]$Uri
    $bi.DecodePixelWidth = $DecodeWidth
    $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bi.CreateOptions = [System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreColorProfile
    $bi.EndInit()
    return $bi
}

function global:Start-HeaderFxFade {
    param($Element, [double]$To, [scriptblock]$Done)
    $a = New-Object System.Windows.Media.Animation.DoubleAnimation
    $a.To = $To
    $a.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds($global:HeaderFxConfig.FadeMs))
    $a.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
    if ($Done) { $a.Add_Completed($Done) }
    $Element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $a)
}

# --- speed ------------------------------------------------------
# Every looping frieze/orb animation runs on its OWN controllable clock
# that is remembered on its layer (Layer.Tag = list of clocks). "Header
# speed" then only changes SpeedRatio on those clocks - live, no rebuild.
# 0 = paused where it is. Fades are NOT registered: they always run at
# normal speed, otherwise a still header could never fade in or out.
function global:Start-HeaderFxAnim {
    param($Layer, $Target, $Property, $Animation)
    $clock = $Animation.CreateClock()
    $Target.ApplyAnimationClock($Property, $clock)
    if ($Layer) {
        if ($Layer.Tag -isnot [System.Collections.ArrayList]) { $Layer.Tag = New-Object System.Collections.ArrayList }
        [void]$Layer.Tag.Add($clock)
    }
    Set-HeaderFxClockSpeed -Clock $clock -Speed $global:HeaderFxSpeed
}

function global:Set-HeaderFxClockSpeed {
    param($Clock, [double]$Speed)
    try {
        $c = $Clock.Controller
        if (-not $c) { return }
        if ($Speed -le 0) { $c.Pause() }
        else { $c.SpeedRatio = $Speed; $c.Resume() }
    } catch { }
}

function global:Set-HeaderFxLayerSpeed {
    param($Layer, [double]$Speed)
    if (-not $Layer -or $Layer.Tag -isnot [System.Collections.ArrayList]) { return }
    foreach ($c in @($Layer.Tag)) { Set-HeaderFxClockSpeed -Clock $c -Speed $Speed }
}

# A clock that has not ticked yet may ignore Pause(); re-apply once the
# layer is really running so "Still" also holds for freshly built layers.
function global:Request-HeaderFxLayerSpeed {
    param($Layer)
    if (-not $Layer) { return }
    $l = $Layer
    $t = New-Object System.Windows.Threading.DispatcherTimer
    $t.Interval = [TimeSpan]::FromMilliseconds(250)
    $t.Add_Tick({ $this.Stop(); Set-HeaderFxLayerSpeed -Layer $l -Speed $global:HeaderFxSpeed }.GetNewClosure())
    $t.Start()
}

function global:Stop-HeaderFxLayerClocks {
    param($Layer)
    if (-not $Layer -or $Layer.Tag -isnot [System.Collections.ArrayList]) { return }
    foreach ($c in @($Layer.Tag)) { try { $c.Controller.Stop() } catch { } }
    $Layer.Tag.Clear()
}

function global:Set-HeaderFxSpeed {
    param([double]$Speed, [switch]$Save)
    $global:HeaderFxSpeed = [Math]::Min(2.0, [Math]::Max(0.0, $Speed))
    foreach ($l in @($global:HeaderFxFriezeLayer, $global:HeaderFxBokehLayer, $global:HeaderFxAmbientLayer)) {
        Set-HeaderFxLayerSpeed -Layer $l -Speed $global:HeaderFxSpeed
    }
    if ($Save) { Request-HeaderFxSettingSave -Key 'headerFxSpeed' -Value ([double]$global:HeaderFxSpeed) }
    Write-HubTiming ("headerfx: speed {0}" -f $global:HeaderFxSpeed)
}

# --- host layer -------------------------------------------------
# One Grid behind HeaderBorder AND FilterBar (Row 0, RowSpan 2), so
# the effect runs through both rows as one band. The two Borders
# become transparent; the host paints the old #0f0f12 itself.
function global:Initialize-HeaderFxHost {
    $root = $global:window.Content
    if ($root -isnot [System.Windows.Controls.Grid]) { return $false }
    $hb = $global:window.FindName('HeaderBorder')
    $fb = $global:window.FindName('FilterBar')
    if (-not $hb -or -not $fb) { return $false }
    # !!! Rows 0 and 1 of the root Grid are Height="Auto". WPF measures
    # every child of an Auto row with UNLIMITED height, so any element in
    # here that has a natural size (the stretched ambient Image above all)
    # would make the header grow to the image's full height - that is what
    # broke the detail pages in the first test build. A Canvas always
    # reports a desired size of 0x0, so it can never push the rows; it is
    # still ARRANGED to the rows' real size, and the effect Grid inside is
    # pinned to exactly that size on every SizeChanged.
    $outer = New-Object System.Windows.Controls.Canvas
    $outer.Name = 'HeaderFxHostCanvas'
    $outer.IsHitTestVisible = $false
    $outer.ClipToBounds = $true
    $outer.Background = New-HeaderFxBrush $global:HeaderFxConfig.BaseHex
    [System.Windows.Controls.Grid]::SetRow($outer, 0)
    [System.Windows.Controls.Grid]::SetRowSpan($outer, 2)
    [System.Windows.Controls.Panel]::SetZIndex($outer, -1)
    $hostGrid = New-Object System.Windows.Controls.Grid
    $hostGrid.Name = 'HeaderFxHost'
    $hostGrid.IsHitTestVisible = $false
    $hostGrid.ClipToBounds = $true
    $hostGrid.Width = 0; $hostGrid.Height = 0
    [void]$outer.Children.Add($hostGrid)
    $outer.Add_SizeChanged({
        param($sender, $e)
        try {
            $hostGrid.Width  = [Math]::Max(0, $e.NewSize.Width)
            $hostGrid.Height = [Math]::Max(0, $e.NewSize.Height)
        } catch { }
    }.GetNewClosure())
    $root.Children.Insert(0, $outer)
    $hb.Background = [System.Windows.Media.Brushes]::Transparent
    $fb.Background = [System.Windows.Media.Brushes]::Transparent
    $global:HeaderFxHost = $hostGrid
    return $true
}

# --- frieze -----------------------------------------------------
function global:Build-HeaderFxFrieze {
    $cfg = $global:HeaderFxConfig
    $games = @($global:HeaderFxGames)
    $uris = Get-HeaderFxPortraitUris -Games $games -Count $cfg.FriezeCount
    if ($uris.Count -lt 4) { Write-HubTiming ("headerfx: frieze skipped, only {0} local portraits" -f $uris.Count); return $null }

    $layer = New-Object System.Windows.Controls.Grid
    $layer.IsHitTestVisible = $false
    $layer.Opacity = 0

    $canvas = New-Object System.Windows.Controls.Canvas
    $canvas.ClipToBounds = $true
    $strip = New-Object System.Windows.Controls.StackPanel
    $strip.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $strip.Opacity = $cfg.FriezeOpacity
    $tileStep = $cfg.FriezeTileW + $cfg.FriezeGap
    # The set twice in a row: the strip moves by exactly one set width
    # and jumps back - the second copy is then where the first was, so
    # the loop is seamless.
    $built = 0
    # Decode each portrait once; the seamless second strip shares its frozen bitmap.
    $bitmaps = New-Object System.Collections.ArrayList
    foreach ($u in $uris) {
        try {
            $bmp = New-HeaderFxBitmap -Uri $u -DecodeWidth $cfg.FriezeTileW
            $bmp.Freeze()
            [void]$bitmaps.Add($bmp)
        } catch { }
    }
    foreach ($pass in 1..2) {
        foreach ($bmp in $bitmaps) {
            try {
                $ib = New-Object System.Windows.Media.ImageBrush $bmp
                $ib.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                $ib.Freeze()
                $tile = New-Object System.Windows.Controls.Border
                $tile.Width = $cfg.FriezeTileW; $tile.Height = $cfg.FriezeTileH
                $tile.CornerRadius = [System.Windows.CornerRadius]::new(8)
                $tile.Margin = [System.Windows.Thickness]::new(0, 0, $cfg.FriezeGap, 0)
                $tile.Background = $ib
                [void]$strip.Children.Add($tile)
                $built++
            } catch { }
        }
    }
    if ($built -lt 8) { return $null }
    $setWidth = ($built / 2) * $tileStep
    # Moving only a cached bitmap keeps the drift cheap on the render thread.
    # Above ~8000 px the cache texture could exceed the GPU limit - then
    # WPF simply draws the tiles every frame instead.
    if (($setWidth * 2) -lt 8000) { $strip.CacheMode = New-Object System.Windows.Media.BitmapCache }
    $tt = New-Object System.Windows.Media.TranslateTransform
    $rt = New-Object System.Windows.Media.RotateTransform ([double]$cfg.FriezeAngle)
    $tg = New-Object System.Windows.Media.TransformGroup
    [void]$tg.Children.Add($tt)
    [void]$tg.Children.Add($rt)
    $strip.RenderTransform = $tg
    [void]$canvas.Children.Add($strip)
    [void]$layer.Children.Add($canvas)

    $place = {
        $w = $layer.ActualWidth; $h = $layer.ActualHeight
        if ($w -lt 50) { return }
        $x0 = $w * $global:HeaderFxConfig.FriezeStartFrac
        [System.Windows.Controls.Canvas]::SetLeft($strip, $x0)
        [System.Windows.Controls.Canvas]::SetTop($strip, ($h - $global:HeaderFxConfig.FriezeTileH) / 2)
        # Tilt around the middle of the VISIBLE stretch (rotation comes after
        # the drift in the group, so this point stays fixed on screen) - the
        # strip then never climbs out of the band at either end.
        $rt.CenterX = ($w - $x0) / 2
        $rt.CenterY = $global:HeaderFxConfig.FriezeTileH / 2
    }.GetNewClosure()
    $layer.Add_SizeChanged($place)

    $secs = [Math]::Max(20.0, $setWidth / [double]$cfg.FriezePxPerSecond)
    $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
    $anim.From = 0; $anim.To = -$setWidth
    $anim.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($secs))
    $anim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    Start-HeaderFxAnim -Layer $layer -Target $tt -Property ([System.Windows.Media.TranslateTransform]::XProperty) -Animation $anim
    Request-HeaderFxLayerSpeed -Layer $layer

    # Scrims: the title side stays clean, the bottom melts into the bar line.
    [void]$layer.Children.Add((New-HeaderFxScrim -Direction 'left' -Stops @(@(0.00,255), @(0.34,255), @(0.48,204), @(0.70,90), @(1.00,48))))
    [void]$layer.Children.Add((New-HeaderFxScrim -Direction 'bottom' -Stops @(@(0.00,235), @(0.45,0))))
    Write-HubTiming ("headerfx: frieze built, {0} portraits, loop {1:N0} s" -f ($built / 2), $secs)
    return $layer
}

# --- ambient echo + big orbs ------------------------------------
function global:Add-HeaderFxOrbs {
    param($Layer, [string[]]$Palette, [int]$Count = 0)
    $cfg = $global:HeaderFxConfig
    $canvas = New-Object System.Windows.Controls.Canvas
    $canvas.Tag = 'HeaderFxOrbs'
    $canvas.IsHitTestVisible = $false
    $canvas.Opacity = 0
    if ($Count -le 0) { $Count = $cfg.OrbCount }
    $rand = New-Object System.Random
    $info = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $Count; $i++) {
        $c = [System.Windows.Media.ColorConverter]::ConvertFromString($Palette[$i % $Palette.Count])
        $rg = New-Object System.Windows.Media.RadialGradientBrush
        # Two stops only, exactly like Add-BannerOrbs: full colour in the
        # centre running straight out to nothing - no hard core, no rim.
        [void]$rg.GradientStops.Add([System.Windows.Media.GradientStop]::new($c, 0.0))
        [void]$rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $c.R, $c.G, $c.B), 1.0))
        $rg.Freeze()
        $sz = $cfg.OrbMinSize + $rand.NextDouble() * ($cfg.OrbMaxSize - $cfg.OrbMinSize)
        $e = New-Object System.Windows.Shapes.Ellipse
        $e.Width = $sz; $e.Height = $sz; $e.Fill = $rg
        $bl = New-Object System.Windows.Media.Effects.BlurEffect
        $bl.Radius = $cfg.OrbBlur
        $e.Effect = $bl
        # Blur rendered once, then only moved and faded.
        $e.CacheMode = New-Object System.Windows.Media.BitmapCache
        $tt = New-Object System.Windows.Media.TranslateTransform
        $e.RenderTransform = $tt
        # Wandering: x and y run on DIFFERENT periods (ratio 0.55..0.8), so
        # every orb traces a slow, never-repeating-looking loop instead of a
        # straight back-and-forth. Random start phases keep them out of step.
        $dur = $cfg.OrbMinSeconds + $rand.NextDouble() * ($cfg.OrbMaxSeconds - $cfg.OrbMinSeconds)
        $durY = $dur * (0.55 + $rand.NextDouble() * 0.25)
        $dx = $cfg.OrbDriftX * (0.6 + $rand.NextDouble() * 0.4)
        $dy = $cfg.OrbDriftY * (0.6 + $rand.NextDouble() * 0.4)
        $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
        $ax.From = -$dx; $ax.To = $dx
        $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
        $ax.AutoReverse = $true; $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
        $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur * 2))
        Start-HeaderFxAnim -Layer $Layer -Target $tt -Property ([System.Windows.Media.TranslateTransform]::XProperty) -Animation $ax
        $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
        $ay.From = -$dy; $ay.To = $dy
        $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($durY))
        $ay.AutoReverse = $true; $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $ay.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
        $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $durY * 2))
        Start-HeaderFxAnim -Layer $Layer -Target $tt -Property ([System.Windows.Media.TranslateTransform]::YProperty) -Animation $ay
        $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
        $oa.From = $cfg.OrbMinOpacity; $oa.To = $cfg.OrbMaxOpacity
        $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(6 + $rand.NextDouble() * 6))
        $oa.AutoReverse = $true; $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $oa.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * 6))
        Start-HeaderFxAnim -Layer $Layer -Target $e -Property ([System.Windows.UIElement]::OpacityProperty) -Animation $oa
        [void]$canvas.Children.Add($e)
        # Even slots across the width with jitter; vertical centre around
        # the middle of the band so the big ones spill over both edges.
        $fx = 0.10 + (($i + 0.5) / $Count) * 0.88 + (($rand.NextDouble() - 0.5) * 0.08)
        $fy = 0.30 + $rand.NextDouble() * 0.40
        [void]$info.Add([pscustomobject]@{ el = $e; sz = $sz; fx = $fx; fy = $fy })
    }
    $reflow = {
        $cw = $canvas.ActualWidth; $ch = $canvas.ActualHeight
        if ($cw -lt 50 -or $ch -lt 20) { return }
        foreach ($o in $info) {
            [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2))
            [System.Windows.Controls.Canvas]::SetTop($o.el, ($o.fy * $ch) - ($o.sz / 2))
        }
    }.GetNewClosure()
    $canvas.Add_SizeChanged($reflow)
    # Orbs sit UNDER the scrims (index 1 = right after the ambient image).
    $Layer.Children.Insert([Math]::Min(1, $Layer.Children.Count), $canvas)
    Start-HeaderFxFade -Element $canvas -To 1.0
    Request-HeaderFxLayerSpeed -Layer $Layer
    Write-HubTiming ("headerfx: orbs {0}" -f ($Palette -join ','))
}

# Read the tiny decoded bitmap and derive the orb palette. Online
# images may not be decoded yet; retried a few times like
# Set-BannerAmbientColor does, then the curated colour alone is used.
function global:Resolve-HeaderFxPalette {
    param($Bitmap, $Game, $Layer, [int]$Attempt = 0, [bool]$Glass = $false)
    if ($global:HeaderFxAmbientLayer -ne $Layer) { return }    # page changed meanwhile
    $base = $null
    try { $base = Get-BannerColorForGame -Game $Game } catch { }
    $pixels = $null; $w = 0; $h = 0; $stride = 0
    if ($Bitmap) {
        try {
            if ($Bitmap.IsDownloading -or $Bitmap.PixelWidth -lt 4) {
                if ($Attempt -lt 12) {
                    $b = $Bitmap; $g = $Game; $l = $Layer; $n = $Attempt + 1
                    $t = New-Object System.Windows.Threading.DispatcherTimer
                    $t.Interval = [TimeSpan]::FromMilliseconds(200)
                    $glassStyle = $Glass
                    $t.Add_Tick({ $this.Stop(); Resolve-HeaderFxPalette $b $g $l $n $glassStyle }.GetNewClosure())
                    $t.Start()
                    return
                }
            } else {
                $conv = New-Object System.Windows.Media.Imaging.FormatConvertedBitmap
                $conv.BeginInit(); $conv.Source = $Bitmap
                $conv.DestinationFormat = [System.Windows.Media.PixelFormats]::Bgra32
                $conv.EndInit()
                $w = $conv.PixelWidth; $h = $conv.PixelHeight; $stride = $w * 4
                $pixels = New-Object 'byte[]' ($stride * $h)
                $conv.CopyPixels($pixels, $stride, 0)
            }
        } catch { $pixels = $null }
    }
    $pal = Get-HeaderFxPalette -Pixels $pixels -Width $w -Height $h -Stride $stride -BaseHex $base -Max 4
    Add-HeaderFxOrbs -Layer $Layer -Palette $pal -Count $(if ($Glass) { $global:HeaderFxConfig.OrbCount } else { $global:HeaderFxConfig.DetailOrbCount })
}

function global:Build-HeaderFxAmbient {
    param($Game, [bool]$Glass = $false)
    $cfg = $global:HeaderFxConfig
    $layer = New-Object System.Windows.Controls.Grid
    $layer.Uid = if ($Glass) { 'HeaderFxGlass' } else { 'HeaderFxDetailOrbs' }
    $layer.IsHitTestVisible = $false
    $layer.Opacity = 0
    $bmp = $null
    $uri = Get-HeaderFxAmbientUri -Game $Game
    if ($uri) {
        try {
            $bmp = New-HeaderFxBitmap -Uri $uri -DecodeWidth $cfg.AmbientDecodeW
            $img = New-Object System.Windows.Controls.Image
            $img.Source = $bmp
            $img.Stretch = [System.Windows.Media.Stretch]::UniformToFill
            $img.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
            $img.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            # Overscan so the blur never shows a soft edge.
            $img.Margin = [System.Windows.Thickness]::new(-80)
            [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($img, [System.Windows.Media.BitmapScalingMode]::Linear)
            $bl = New-Object System.Windows.Media.Effects.BlurEffect
            $bl.Radius = $cfg.AmbientBlur
            $img.Effect = $bl
            $img.CacheMode = New-Object System.Windows.Media.BitmapCache
            $img.Opacity = $cfg.AmbientOpacity
            if ($Glass) { [void]$layer.Children.Add($img) }
        } catch { $bmp = $null }
    }
    if ($layer.Children.Count -eq 0) {
        # No art at all: an empty first child keeps the orb insert index stable.
        [void]$layer.Children.Add((New-Object System.Windows.Controls.Canvas))
    }
    if ($Glass) {
        [void]$layer.Children.Add((New-HeaderFxScrim -Direction 'left' -Stops @(@(0.00,240), @(0.40,175), @(1.00,120))))
        [void]$layer.Children.Add((New-HeaderFxScrim -Direction 'bottom' -Stops @(@(0.00,255), @(0.55,0))))
    } else {
        [void]$layer.Children.Add((New-HeaderFxScrim -Direction 'left' -Stops @(@(0.00,155), @(0.40,70), @(1.00,25))))
        [void]$layer.Children.Add((New-HeaderFxScrim -Direction 'bottom' -Stops @(@(0.00,170), @(0.55,0))))
    }
    $global:HeaderFxAmbientLayer = $layer
    $b = $bmp; $g = $Game; $l = $layer
    $global:window.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [Action]{ try { Resolve-HeaderFxPalette $b $g $l 0 $Glass } catch { } }.GetNewClosure()
    ) | Out-Null
    return $layer
}

# --- bokeh outside the detail page --------------------------------
# Same orbs as on a game page, in the Hub's own colours (the palette of
# Add-BannerOrbs plus Hub orange), no ambient art underneath.
function global:Build-HeaderFxBokeh {
    $layer = New-Object System.Windows.Controls.Grid
    $layer.IsHitTestVisible = $false
    $layer.Opacity = 0
    # Empty first child keeps the orb insert index (1) the same as on the
    # ambient layer, so the orbs end up under the scrims.
    [void]$layer.Children.Add((New-Object System.Windows.Controls.Canvas))
    [void]$layer.Children.Add((New-HeaderFxScrim -Direction 'left' -Stops @(@(0.00,200), @(0.35,90), @(1.00,40))))
    [void]$layer.Children.Add((New-HeaderFxScrim -Direction 'bottom' -Stops @(@(0.00,235), @(0.50,0))))
    Add-HeaderFxOrbs -Layer $layer -Palette @('#ff8a22', '#3a8add', '#34d399', '#36e0e0', '#f0d860')
    return $layer
}

# --- view tracking ----------------------------------------------
function global:Get-HeaderFxCurrentContext {
    $det = [bool]($global:discoverDetail   -and $global:discoverDetail.IsVisible)
    $ovw = [bool]($global:discoverOverview -and $global:discoverOverview.IsVisible)
    $lib = [bool]($global:discoverHost     -and $global:discoverHost.IsVisible)
    $lst = [bool]($global:listScroll       -and $global:listScroll.IsVisible)
    return (Get-HeaderFxContextFor -DetailVisible $det -OverviewVisible $ovw -LibraryVisible $lib -ListVisible $lst)
}

function global:Get-HeaderFxStyle {
    param([string]$Context)
    if (-not $global:HeaderFxStyleCache) { $global:HeaderFxStyleCache = @{} }
    if (-not $global:HeaderFxStyleCache.ContainsKey($Context)) {
        $stored = $null
        if (Get-Command Get-HubSetting -ErrorAction SilentlyContinue) {
            try { $stored = Get-HubSetting -Key (Get-HeaderFxStyleKey $Context) -Default $null } catch { $stored = $null }
        }
        $global:HeaderFxStyleCache[$Context] = Resolve-HeaderFxStyle -Context $Context -Stored $stored
    }
    return $global:HeaderFxStyleCache[$Context]
}

function global:Set-HeaderFxStyle {
    param([string]$Context, [string]$Style)
    $Style = Resolve-HeaderFxStyle -Context $Context -Stored $Style
    if (-not $global:HeaderFxStyleCache) { $global:HeaderFxStyleCache = @{} }
    $global:HeaderFxStyleCache[$Context] = $Style
    Request-HeaderFxSettingSave -Key (Get-HeaderFxStyleKey $Context) -Value $Style
    Write-HubTiming ("headerfx: style {0} = {1}" -f $Context, $Style)
    $global:HeaderFxKey = $null
    Update-HeaderFxMode
}

function global:Switch-HeaderFxStyle {
    $ctx = Get-HeaderFxCurrentContext
    Set-HeaderFxStyle -Context $ctx -Style (Get-HeaderFxNextStyle -Current (Get-HeaderFxStyle -Context $ctx) -Context $ctx)
}

# A settings write checksums and replaces the state document. Coalesce rapid
# clicks so the animation changes immediately and only the final choice is
# persisted. Closing flushes any pending choice together with window geometry.
function global:Request-HeaderFxSettingSave {
    param([string]$Key, $Value)
    if (-not $global:HeaderFxPendingSettings) { $global:HeaderFxPendingSettings = @{} }
    $global:HeaderFxPendingSettings[$Key] = $Value
    if ($global:HeaderFxSaveTimer) { $global:HeaderFxSaveTimer.Stop(); $global:HeaderFxSaveTimer.Start() }
}

function global:Save-HeaderFxPendingSettings {
    if ($global:HeaderFxSaveTimer) { $global:HeaderFxSaveTimer.Stop() }
    if (-not $global:HeaderFxPendingSettings -or -not (Get-Command Set-HubSetting -ErrorAction SilentlyContinue)) { return }
    $pending = $global:HeaderFxPendingSettings
    $global:HeaderFxPendingSettings = @{}
    foreach ($key in @($pending.Keys)) { Set-HubSetting -Key $key -Value $pending[$key] }
}

# Fade a persistent layer (frieze / Hub bokeh) in or out. Hidden layers are
# collapsed AND paused, so they cost nothing while away.
function global:Show-HeaderFxLayer {
    param($Layer, [bool]$Visible)
    if (-not $Layer) { return }
    if ($Visible) {
        $Layer.Visibility = [System.Windows.Visibility]::Visible
        Set-HeaderFxLayerSpeed -Layer $Layer -Speed $global:HeaderFxSpeed
        Start-HeaderFxFade -Element $Layer -To 1.0
    } else {
        if ($Layer.Visibility -ne [System.Windows.Visibility]::Visible) { return }
        $l = $Layer
        Start-HeaderFxFade -Element $l -To 0.0 -Done ({
            if ($l.Opacity -le 0.01) {
                $l.Visibility = [System.Windows.Visibility]::Collapsed
                Set-HeaderFxLayerSpeed -Layer $l -Speed 0
            }
        }.GetNewClosure())
    }
}

function global:Update-HeaderFxMode {
    if (-not $global:HeaderFxHost -or -not $global:HeaderFxReady) { return }
    $ctx = Get-HeaderFxCurrentContext
    $style = Get-HeaderFxStyle -Context $ctx
    $game = if ($ctx -eq 'detail' -and ($style -eq 'bokeh' -or $style -eq 'glass')) { $global:currentDetailGame } else { $null }
    $key = $ctx + '|' + $style
    if ($game) { $key += '|' + [string]$game.Title }
    if ($key -eq $global:HeaderFxKey) { return }
    $global:HeaderFxKey = $key

    $wantFrieze  = ($style -eq 'images')
    $wantBokeh   = ($style -eq 'bokeh' -and $ctx -ne 'detail')
    $wantAmbient = (($style -eq 'bokeh' -or $style -eq 'glass') -and $ctx -eq 'detail')

    if ($wantFrieze -and -not $global:HeaderFxFriezeLayer) {
        $global:HeaderFxFriezeLayer = Build-HeaderFxFrieze
        if ($global:HeaderFxFriezeLayer) { [void]$global:HeaderFxHost.Children.Add($global:HeaderFxFriezeLayer) }
    }
    if ($wantBokeh -and -not $global:HeaderFxBokehLayer) {
        $global:HeaderFxBokehLayer = Build-HeaderFxBokeh
        [void]$global:HeaderFxHost.Children.Add($global:HeaderFxBokehLayer)
    }
    Show-HeaderFxLayer -Layer $global:HeaderFxFriezeLayer -Visible $wantFrieze
    Show-HeaderFxLayer -Layer $global:HeaderFxBokehLayer  -Visible $wantBokeh

    # The ambient layer belongs to ONE game: always replaced, never reused.
    Remove-HeaderFxAmbient
    if ($wantAmbient -and $game) {
        $layer = Build-HeaderFxAmbient -Game $game -Glass ($style -eq 'glass')
        [void]$global:HeaderFxHost.Children.Add($layer)
        Start-HeaderFxFade -Element $layer -To 1.0
        Write-HubTiming ("headerfx: ambient for '{0}'" -f $game.Title)
    }
    Update-HeaderFxMenuItems
}

function global:Remove-HeaderFxAmbient {
    $old = $global:HeaderFxAmbientLayer
    if (-not $old) { return }
    $global:HeaderFxAmbientLayer = $null
    $hostGrid = $global:HeaderFxHost
    Start-HeaderFxFade -Element $old -To 0.0 -Done ({
        # Stop the orb clocks and drop the layer for good.
        Stop-HeaderFxLayerClocks -Layer $old
        try { [void]$hostGrid.Children.Remove($old) } catch { }
    }.GetNewClosure())
}

# --- Help & feedback menu ---------------------------------------
# Two items, built here so the whole feature stays in this file. They are
# inserted right after "Switch Hub Style" (MiStyle) and copy its look.
# Clicking does NOT close the menu: the header behind it changes at once,
# so the user can click through the options and watch.
function global:New-HeaderFxMenuItem {
    param([string]$Name, [string]$DotHex, [string]$Title)
    $b = New-Object System.Windows.Controls.Border
    $b.Name = $Name
    $b.Background = [System.Windows.Media.Brushes]::Transparent
    $b.CornerRadius = [System.Windows.CornerRadius]::new(7)
    $b.Padding = [System.Windows.Thickness]::new(8, 9, 8, 9)
    $b.Cursor = [System.Windows.Input.Cursors]::Hand
    $row = New-Object System.Windows.Controls.StackPanel
    $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $dot = New-Object System.Windows.Shapes.Ellipse
    $dot.Width = 8; $dot.Height = 8
    $dot.Fill = New-HeaderFxBrush $DotHex
    $dot.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $dot.Margin = [System.Windows.Thickness]::new(2, 0, 11, 0)
    $col = New-Object System.Windows.Controls.StackPanel
    $t1 = New-Object System.Windows.Controls.TextBlock
    $t1.Text = $Title; $t1.FontSize = 13
    $t1.Foreground = New-HeaderFxBrush '#d8dee3'
    $t1.FontFamily = New-Object System.Windows.Media.FontFamily 'Segoe UI'
    $t2 = New-Object System.Windows.Controls.TextBlock
    $t2.FontSize = 11
    $t2.Foreground = New-HeaderFxBrush '#6a6a7e'
    $t2.FontFamily = New-Object System.Windows.Media.FontFamily 'Segoe UI'
    $t2.Margin = [System.Windows.Thickness]::new(0, 2, 0, 0)
    [void]$col.Children.Add($t1); [void]$col.Children.Add($t2)
    [void]$row.Children.Add($dot); [void]$row.Children.Add($col)
    $b.Child = $row
    $hover = New-HeaderFxBrush '#1e1e2a'
    $b.Add_MouseEnter({ $this.Background = $hover }.GetNewClosure())
    $b.Add_MouseLeave({ $this.Background = [System.Windows.Media.Brushes]::Transparent })
    return [pscustomobject]@{ Item = $b; Sub = $t2 }
}

function global:Update-HeaderFxMenuItems {
    if ($global:HeaderFxMenuStyleSub) {
        $ctx = Get-HeaderFxCurrentContext
        $cur = Get-HeaderFxStyle -Context $ctx
        $global:HeaderFxMenuStyleSub.Text = [string]$global:HeaderFxStyleLabels[$cur]
    }
    if ($global:HeaderFxMenuSpeedSub) {
        $nxt = Get-HeaderFxNextSpeed -Current $global:HeaderFxSpeed
        $global:HeaderFxMenuSpeedSub.Text = ('Currently {0} - click for {1}' -f (Format-HeaderFxSpeed $global:HeaderFxSpeed), (Format-HeaderFxSpeed $nxt))
    }
}

function global:Add-HeaderFxMenuItems {
    $anchor = $global:window.FindName('MiStyle')
    if (-not $anchor) { return }
    $panel = $anchor.Parent
    if ($panel -isnot [System.Windows.Controls.Panel]) { return }
    $at = $panel.Children.IndexOf($anchor) + 1

    $style = New-HeaderFxMenuItem -Name 'MiHeaderFxStyle' -DotHex '#ff8a22' -Title 'Header style'
    $style.Item.Add_MouseLeftButtonUp({ param($s, $e)
        $e.Handled = $true
        $indicatorToken = Start-HubActionIndicator -Target $s
        try {
            Switch-HeaderFxStyle
            Update-HeaderFxMenuItems
        } catch { } finally { Stop-HubActionIndicator -Token $indicatorToken }
    })
    $speed = New-HeaderFxMenuItem -Name 'MiHeaderFxSpeed' -DotHex '#36e0e0' -Title 'Header speed'
    $speed.Item.Add_MouseLeftButtonUp({ param($s, $e)
        $e.Handled = $true
        try {
            Set-HeaderFxSpeed -Speed (Get-HeaderFxNextSpeed -Current $global:HeaderFxSpeed) -Save
            Update-HeaderFxMenuItems
        } catch { }
    })
    $panel.Children.Insert($at, $style.Item)
    $panel.Children.Insert($at + 1, $speed.Item)
    $global:HeaderFxMenuStyleSub = $style.Sub
    $global:HeaderFxMenuSpeedSub = $speed.Sub
    # Labels follow the page the menu is opened on.
    if ($global:menuOverlay) {
        $global:menuOverlay.Add_IsVisibleChanged({ try { if ($global:menuOverlay.IsVisible) { Update-HeaderFxMenuItems } } catch { } })
    }
    Update-HeaderFxMenuItems
}

# --- wiring -----------------------------------------------------
try {
    if (Initialize-HeaderFxHost) {
        $global:HeaderFxKey = $null
        $global:HeaderFxReady = $false
        $global:HeaderFxStyleCache = @{}
        $storedSpeed = $null
        if (Get-Command Get-HubSetting -ErrorAction SilentlyContinue) {
            try { $storedSpeed = Get-HubSetting -Key 'headerFxSpeed' -Default $null } catch { }
        }
        $global:HeaderFxSpeed = if ($null -eq $storedSpeed) { 1.0 } else { ConvertTo-HeaderFxSpeed $storedSpeed }
        $global:HeaderFxPendingSettings = @{}
        $global:HeaderFxSaveTimer = New-Object System.Windows.Threading.DispatcherTimer
        $global:HeaderFxSaveTimer.Interval = [TimeSpan]::FromMilliseconds(700)
        $global:HeaderFxSaveTimer.Add_Tick({ Save-HeaderFxPendingSettings })
        # Pending choices join the same final geometry commit at close.
        # The catalog arrays live in VRModHub.ps1's script scope, which event
        # handlers cannot see later - keep a reference while it is in reach.
        $global:HeaderFxGames = @($ownGames) + @($ownGamesGP) + @($externalGames)
        try { Add-HeaderFxMenuItems } catch { Write-HubTiming ("headerfx: menu items failed: {0}" -f $_.Exception.Message) }
        # View changes: visibility events give the instant switch, a slow
        # timer catches detail -> detail jumps (same page, other game).
        foreach ($el in @($global:discoverDetail, $global:discoverOverview, $global:discoverHost, $global:listScroll)) {
            if ($el) { $el.Add_IsVisibleChanged({ try { Update-HeaderFxMode } catch { } }) }
        }
        $global:HeaderFxTimer = New-Object System.Windows.Threading.DispatcherTimer
        $global:HeaderFxTimer.Interval = [TimeSpan]::FromMilliseconds(400)
        $global:HeaderFxTimer.Add_Tick({ try { Update-HeaderFxMode } catch { } })
        # Built after the first frame, so the effect never delays startup.
        $global:window.Add_ContentRendered({
            try {
                $global:window.Dispatcher.BeginInvoke(
                    [System.Windows.Threading.DispatcherPriority]::Background,
                    [Action]{ try { $global:HeaderFxReady = $true; Update-HeaderFxMode; $global:HeaderFxTimer.Start() } catch { } }
                ) | Out-Null
            } catch { }
        })
        Write-HubTiming ("headerfx: host ready, speed {0}" -f $global:HeaderFxSpeed)
    }
} catch {
    Write-HubTiming ("headerfx: disabled after error: {0}" -f $_.Exception.Message)
}
