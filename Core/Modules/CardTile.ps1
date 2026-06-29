# -------------------------------------------------------
# Control-type glyph shown in the top-right info pill (replaces the
# old colored MC/GP dot). Stroke-outline Path inside a Viewbox so it
# scales crisply with the S/M/L card scale. Gamepad glyph for gamepad
# titles, motion-controller glyph for motion titles. Tooltip names the
# control scheme on hover.
# -------------------------------------------------------
function global:New-ControlTypeIcon {
    param([string]$Controls, [double]$Sc = 1.0, $Stroke = $null)

    # Resting glyph stroke. Callers may override (e.g. the tile pill passes
    # the per-game family text color so the symbol + "i" share that hue).
    if ($Stroke -is [System.Windows.Media.Brush]) { $strokeBrush = $Stroke }
    elseif ($Stroke) { $strokeBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString([string]$Stroke) }
    else { $strokeBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c4c7d1") }

    # Builds one stroke-glyph Viewbox for a single control kind.
    $makeGlyph = {
        param([string]$Kind, [double]$Scale, $Brush)
        if ($Kind -eq "gamepad") {
            $data = "M8 8.7C5.3 8.7 3.9 10.7 3.3 13.8C2.9 16.1 4 17.6 5.7 17.6C7 17.6 7.6 16.5 8.5 16.1L15.5 16.1C16.4 16.5 17 17.6 18.3 17.6C20 17.6 21.1 16.1 20.7 13.8C20.1 10.7 18.7 8.7 16 8.7Z M6.4 11.6L6.4 14 M5.2 12.8L7.6 12.8 M14.7 11.7A1 1 0 1 1 16.7 11.7A1 1 0 1 1 14.7 11.7Z M16.5 13.3A1 1 0 1 1 18.5 13.3A1 1 0 1 1 16.5 13.3Z"
            $tip  = "Gamepad"
            $px   = 18
        } else {
            $data = "M7.7 8.2A4.3 2.2 0 1 1 16.3 8.2A4.3 2.2 0 1 1 7.7 8.2Z M12 9.8C10.8 9.8 10.2 10.9 10.3 12.1L10.9 17.6C11 18.8 11.2 19.4 12 19.4C12.8 19.4 13 18.8 13.1 17.6L13.7 12.1C13.8 10.9 13.2 9.8 12 9.8Z M11.1 11A0.9 0.9 0 1 1 12.9 11A0.9 0.9 0 1 1 11.1 11Z"
            $tip  = "Motion Controls"
            $px   = 14
        }
        $p = New-Object System.Windows.Shapes.Path
        $p.Data = [System.Windows.Media.Geometry]::Parse($data)
        $p.Stroke = $Brush
        $p.StrokeThickness = 1.9
        $p.StrokeLineJoin = [System.Windows.Media.PenLineJoin]::Round
        $p.StrokeStartLineCap = [System.Windows.Media.PenLineCap]::Round
        $p.StrokeEndLineCap = [System.Windows.Media.PenLineCap]::Round
        $box = New-Object System.Windows.Controls.Viewbox
        $box.Width  = [int]($px*$Scale)
        $box.Height = [int]($px*$Scale)
        $box.Stretch = [System.Windows.Media.Stretch]::Uniform
        $box.Child = $p
        $box.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $box.ToolTip = $tip
        return $box
    }

    # BOTH: gamepad + motion side by side (e.g. GTA V R.E.A.L.+Motion, UEVR).
    if ($Controls -eq "BOTH") {
        $row = New-Object System.Windows.Controls.StackPanel
        $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $row.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $row.ToolTip = "Gamepad + Motion Controls"
        $gp = & $makeGlyph "gamepad" $Sc $strokeBrush
        $mc = & $makeGlyph "motion"  $Sc $strokeBrush
        $mc.Margin = [System.Windows.Thickness]::new([int](5*$Sc), 0, 0, 0)
        $row.Children.Add($gp) | Out-Null
        $row.Children.Add($mc) | Out-Null
        return $row
    }

    $isGamepad = ($Controls -eq "GP" -or $Controls -eq "City-DLC")
    if ($isGamepad) { return (& $makeGlyph "gamepad" $Sc $strokeBrush) }
    return (& $makeGlyph "motion" $Sc $strokeBrush)
}

# -------------------------------------------------------
# Free-to-play games. Tiles for these get a small green "FREE"
# pill directly next to the family badge in the top-left, AND
# the description-page genre-tag line gets a green "FREE" run
# (rendered in OverviewPage.ps1 alongside the genre tags).
# Match is by exact Title string against Catalog.ps1.
# $global: so OverviewPage.ps1 can read the same list - single
# source of truth.
$global:FREE_GAME_TITLES = @(
    "Ashes 2063 VR",
    "Total Chaos VR",
    "Anomaly VR",
    "Iron Lung VR",
    "Sonic P-06 VR",
    "Receiver VR",
    "Daggerfall VR",
    "The Dark Mod VR",
    "I Can Gun VR"
)

# -------------------------------------------------------
# Work-in-progress games. Tiles for these get a small red "WIP"
# pill in the same spot the FREE pill uses, and the description
# page gets a matching red "WIP" pill at the top. For mods that
# run but are still rough / early. Match is by exact Title.
# $global: so DetailView.ps1 reads the same single source of truth.
$global:WIP_GAME_TITLES = @(
    "Cyberpunk 2077"
)

# -------------------------------------------------------
# Pulsing border glow shown immediately on a tile-body click.
# Purpose: confirm the click was registered while Show-Discover-
# Detail does its (sometimes multi-second) Steam library scan,
# image fetch, and detail-page build. Without this, the user
# sees nothing happen for a moment and re-clicks.
#
# Robustness story:
#   - The restore is driven by a DispatcherTimer with a hard
#     deadline, NOT by the animation's Completed event. The
#     Completed callback isn't reliable when the visual tree is
#     mutated mid-animation (Show-DiscoverDetail collapses the
#     entire list ScrollViewer while the glow is animating), which
#     is exactly what caused the "stuck green border" we saw in
#     testing.
#   - The animation runs purely for the visual fade. We don't care
#     when it finishes; the timer wipes the glow at a fixed time
#     regardless of animation state.
#   - Re-clicking the same card during the glow: the new call
#     cancels the running timer, kills the running animation, and
#     starts both fresh. Snapshot in card Resources is captured
#     only on the FIRST run so re-clicks don't accidentally save a
#     mid-animation green state as "original".
#
# Only called from the hotZone PreviewMouseLeftButtonDown
# handler below, which is the *single* code path for tile-body
# and hover-popup clicks that lead to Show-DiscoverDetail.
# Pill, info icon, VR-Ready button, and reload pill all set
# e.Handled = $true earlier in the bubble, so they never reach
# the hotZone -> never trigger this glow. That's intentional:
# those actions are instant and need no loading hint.
#
# Resolve-CardClickGlow deterministically finalizes a click-pulse on a
# card: it stops the restore timer (if any) and restores the card's
# border + Effect from the snapshot taken when the pulse started. This
# is the SAME work the restore DispatcherTimer does, factored out so it
# can also be forced on demand. It is called as a safety sweep whenever
# the grid is re-shown (Show-DiscoverOverview), which is what guarantees
# a pulse can never get left on a card and rasterize its title into the
# washed-out, ClearType-less look. Safe no-op if no pulse is in flight.
function global:Resolve-CardClickGlow {
    param($Card)
    if (-not $Card) { return }
    try {
        if ($Card.Resources.Contains("glowTimer")) {
            try { $t = $Card.Resources.Item("glowTimer"); if ($t) { $t.Stop() } } catch { }
            $Card.Resources.Remove("glowTimer") | Out-Null
        }
        if ($Card.Resources.Contains("glowOrigBd")) {
            # Stop any in-flight opacity animation so swapping the Effect
            # away doesn't leave a dangling animation clock on it.
            try {
                $eff = $Card.Effect
                if ($eff -is [System.Windows.Media.Effects.DropShadowEffect]) {
                    $eff.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $null)
                }
            } catch { }
            $Card.BorderBrush     = $Card.Resources.Item("glowOrigBd")
            $Card.BorderThickness = $Card.Resources.Item("glowOrigThk")
            $Card.Effect          = $Card.Resources.Item("glowOrigFx")
            $Card.Resources.Remove("glowOrigBd")  | Out-Null
            $Card.Resources.Remove("glowOrigThk") | Out-Null
            $Card.Resources.Remove("glowOrigFx")  | Out-Null
        }
    } catch { }
}

function global:Start-CardClickGlowThenOpen {
    param($Card, $Game)
    if (-not $Game) { return }
    # Immediate visual confirmation first...
    if ($Card) { Start-CardClickGlow -Card $Card }
    # ...then defer the heavy Open-DiscoverDetailFromList behind a REAL short
    # one-shot timer instead of Background priority. Background can fire before
    # the compositor has painted a single glow frame, so the click border only
    # showed up intermittently ("hangs before the border starts"). A ~80ms
    # timer guarantees the UI thread stays free long enough for WPF to paint
    # the green border/halo, THEN runs the (1-3s, UI-thread-hogging) navigation.
    # 80ms is imperceptible as a delay.
    $gameCap = $Game
    $navTimer = New-Object System.Windows.Threading.DispatcherTimer
    $navTimer.Interval = [TimeSpan]::FromMilliseconds(80)
    $navTimer.Add_Tick({
        $this.Stop()
        Open-DiscoverDetailFromList -Game $gameCap
    }.GetNewClosure())
    $navTimer.Start()
}

function global:Start-CardClickGlow {
    param($Card)
    if (-not $Card) { return }

    # Total duration of the visual effect. Shortened from 2000ms -
    # the user wants the glow to be a quick confirmation flash, not
    # a sustained announcement. 1200ms: fade in by ~200ms, hold
    # until ~700ms, fade out by 1200ms.
    $totalMs = 1200

    # If a prior glow is still in flight on this card, cancel it.
    # We kill both the timer and the running animation, but DON'T
    # restore from the snapshot here - the snapshot is still valid
    # and the new run will use it. Killing the animation snaps the
    # Effect.Opacity property back to its local value (whatever was
    # last set), which we immediately overwrite below.
    if ($Card.Resources.Contains("glowTimer")) {
        try {
            $oldTimer = $Card.Resources.Item("glowTimer")
            if ($oldTimer) { $oldTimer.Stop() }
        } catch { }
        $Card.Resources.Remove("glowTimer") | Out-Null
    }
    $hadPrior = $false
    if ($Card.Resources.Contains("glowOrigBd")) {
        $hadPrior = $true
        try {
            $effOnCard = $Card.Effect
            if ($effOnCard -is [System.Windows.Media.Effects.DropShadowEffect]) {
                $effOnCard.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $null)
            }
        } catch { }
    }

    # Capture original border + effect so we can revert. Only on
    # the FIRST run; re-clicks pull from the snapshot we already
    # have so we never accidentally save a mid-animation green
    # state as "original". The originalBdBrush resource was set at
    # card creation time and accounts for the tinted accent border.
    # Effect is usually $null on default cards; vrupdate cards
    # already have a DropShadowEffect we must restore byte-for-byte.
    if (-not $hadPrior) {
        $Card.Resources.Add("glowOrigBd",  $Card.BorderBrush)
        $Card.Resources.Add("glowOrigThk", $Card.BorderThickness)
        $Card.Resources.Add("glowOrigFx",  $Card.Effect)
    }

    # Glow halo: soft green outer shadow, no offset = halo.
    # BlurRadius 18 matches the visual density of the mockup.
    $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $glow.Color       = [System.Windows.Media.Color]::FromRgb(74, 222, 128)  # #4ade80
    $glow.BlurRadius  = 18
    $glow.ShadowDepth = 0
    $glow.Opacity     = 0.0
    $Card.Effect = $glow

    # Repaint border to a green SolidColorBrush we own (so we can
    # animate its Color without mutating the shared base brush).
    $animBrush = New-Object System.Windows.Media.SolidColorBrush
    $animBrush.Color = ([System.Windows.Media.Color]::FromRgb(74, 222, 128))
    $Card.BorderBrush = $animBrush
    $Card.BorderThickness = [System.Windows.Thickness]::new(1)

    # Animate halo opacity: fade up -> hold -> fade out over the
    # totalMs window. Key frames scale with totalMs so changing the
    # duration up top is enough to retune the whole curve.
    $rampInMs  = [int]($totalMs * 0.17)   # fade in
    $holdEndMs = [int]($totalMs * 0.58)   # plateau end
    $opAnim = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
    $opAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($totalMs))
    $kf0 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 0.0,  ([System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(0)))
    $kf1 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 0.55, ([System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds($rampInMs)))
    $kf2 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 0.55, ([System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds($holdEndMs)))
    $kf3 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame 0.0,  ([System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds($totalMs)))
    [void]$opAnim.KeyFrames.Add($kf0)
    [void]$opAnim.KeyFrames.Add($kf1)
    [void]$opAnim.KeyFrames.Add($kf2)
    [void]$opAnim.KeyFrames.Add($kf3)

    # Restore via DispatcherTimer instead of animation Completed
    # event. The animation Completed callback was unreliable
    # because Show-DiscoverDetail mutates the visual tree mid-
    # animation; the timer fires regardless of WPF render state.
    # Give it 150ms slack past the visual duration so a barely-
    # late frame doesn't pop the green border off while the eye
    # is still seeing it fade out.
    $restoreTimer = New-Object System.Windows.Threading.DispatcherTimer
    $restoreTimer.Interval = [TimeSpan]::FromMilliseconds($totalMs + 150)
    $cardCap = $Card
    $restoreTimer.Add_Tick({
        try {
            $restoreTimer.Stop()
            if (-not $cardCap) { return }
            Resolve-CardClickGlow -Card $cardCap
        } catch { }
    }.GetNewClosure())
    # Stash the timer on the card so re-clicks can cancel it.
    $Card.Resources.Add("glowTimer", $restoreTimer)
    $restoreTimer.Start()

    # Kick off the halo fade. The border color itself stays green
    # for the duration - the halo opacity is what reads as "pulse"
    # because the brush has no offset. This is exactly the look
    # of the mockup variant 1 the user picked.
    $glow.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $opAnim)
}


# ============================================================
# SHARED REDESIGN HELPERS (test)
# ------------------------------------------------------------
# Used by the tile FX, the neon button, and the post-scan state
# painters in Filter.ps1 so every state stays visually consistent.
# WPF rendering is not verifiable on Linux.
# ============================================================

# Soft straight-down black shadow that lifts a tile off the dark
# page (the 3D float). Returned fresh each call so callers can
# assign it without sharing one frozen instance across cards.
function global:New-TileElevationShadow {
    param([double]$Sc = 1.0)
    $elev = New-Object System.Windows.Media.Effects.DropShadowEffect
    $elev.Color       = [System.Windows.Media.Color]::FromRgb(0, 0, 0)
    $elev.BlurRadius  = [int](20 * $Sc)
    $elev.ShadowDepth = [int](5 * $Sc)
    $elev.Direction   = 270
    $elev.Opacity     = 0.60
    return $elev
}

# Paint an Install-type button in the neon state style: near-black
# tinted fill, 1px vivid outline, a luminance-dampened halo, and
# neon label text. ColorHex drives the whole look, so each state
# passes its own signal colour:
#   default/not-installed -> game accent
#   installed (game on disk, no mod) -> amber  (action: install mod)
#   VR Ready -> green   (ready to play)
#   update available -> blue
# The neon is intentionally a touch dimmer than a raw glow (user
# wanted it darker/weaker) while the fill keeps a little colour.
function global:Set-NeonButtonState {
    param($Button, $Text, [string]$ColorHex, [double]$Sc = 1.0, [switch]$Filled)
    if (-not $Button) { return }
    $vivid = Get-GlowColor $ColorHex
    # Dim ~20% so the neon reads as present, not glaring.
    $neon = [System.Windows.Media.Color]::FromRgb(
        [byte]([int]($vivid.R * 0.90)),
        [byte]([int]($vivid.G * 0.90)),
        [byte]([int]($vivid.B * 0.90)))
    $base = ConvertTo-MediaColor $ColorHex
    if ($Filled) {
        # Status buttons (VR Ready / Update): a clearly tinted fill
        # (~30% colour over near-black) so they stand apart - coloured
        # but still dark enough that the text stays readable.
        $fill = [System.Windows.Media.Color]::FromRgb(
            [byte]([Math]::Min(255, [int]($base.R * 0.30 + 9))),
            [byte]([Math]::Min(255, [int]($base.G * 0.30 + 9))),
            [byte]([Math]::Min(255, [int]($base.B * 0.30 + 9))))
        $Button.Background = New-Object System.Windows.Media.SolidColorBrush $fill
    } else {
        # Normal Install button: neutral dark background, NO accent
        # tint at all - the accent lives only in the glow frame + text.
        $fill = [System.Windows.Media.Color]::FromRgb(14, 14, 18)
        $Button.Background = New-Object System.Windows.Media.SolidColorBrush $fill
    }
    $Button.BorderThickness = [System.Windows.Thickness]::new(1)
    $Button.BorderBrush = New-Object System.Windows.Media.SolidColorBrush $neon
    $lum = ($neon.R * 0.299 + $neon.G * 0.587 + $neon.B * 0.114) / 255.0
    $op  = 0.72 - ($lum * 0.22)            # ~0.72 (dark) -> ~0.50 (bright)
    if ($op -lt 0.42) { $op = 0.42 }
    $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $glow.Color       = $neon
    $glow.BlurRadius  = [int](14 * $Sc)
    $glow.ShadowDepth = 0
    $glow.Opacity     = $op
    $Button.Effect = $glow
    if ($Text) {
        # Capture the build-time font once so state paints can reset
        # it - VR Ready bumps weight/size, everything else returns to
        # this baseline (SemiBold, original size, neon colour).
        if (-not $Button.Resources.Contains("btnBaseFont")) {
            $Button.Resources.Add("btnBaseFont", $Text.FontSize)
        }
        $Text.FontSize   = $Button.Resources.Item("btnBaseFont")
        $Text.FontWeight = [System.Windows.FontWeights]::SemiBold
        $Text.Foreground = New-Object System.Windows.Media.SolidColorBrush $neon
    }
}

# Paint a whole card for a post-scan state (card tint/border/effect
# + neon button + cap) so the three painters (Rebuild-Lookups, the
# live scan, and the end-of-scan restore) stay identical. State
# colours are chosen so the library reads at a glance:
#   update    -> blue  (tile keeps a blue halo)
#   ready      -> green (VR Ready, 3D elevation)
#   installed  -> amber (game on disk, VR mod still to install)
# The accent cap is hidden for every state - neon carries the colour.
function global:Set-CardStateVisual {
    param($Card, $BtnTxt, $BtnBrd, [string]$State)
    if (-not $Card) { return }
    $conv = [System.Windows.Media.BrushConverter]::new()
    switch ($State) {
        "update" {
            $UPDATE_BLUE = "#2563eb"
            $Card.Background = New-CardTintBrush -BaseHex "#0c0c10" -TintHex $UPDATE_BLUE -TopAlpha 0.22 -MidAlpha 0.05
            $bA = ConvertTo-MediaColor $UPDATE_BLUE; $bB = ConvertTo-MediaColor "#0c0c10"
            $Card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(
                [byte]([Math]::Round($bA.R*0.40 + $bB.R*0.60)),
                [byte]([Math]::Round($bA.G*0.40 + $bB.G*0.60)),
                [byte]([Math]::Round($bA.B*0.40 + $bB.B*0.60))))
            $Card.BorderThickness = [System.Windows.Thickness]::new(1)
            $g = New-Object System.Windows.Media.Effects.DropShadowEffect
            $g.Color = $bA; $g.BlurRadius = 16; $g.ShadowDepth = 0; $g.Opacity = 0.55
            $Card.Effect = $g
            if ($BtnTxt) { $BtnTxt.Text = "Update" }
            Set-NeonButtonState -Button $BtnBrd -Text $BtnTxt -ColorHex $UPDATE_BLUE -Filled
        }
        "ready" {
            # Brighter green spot at the TOP that fades down into the
            # near-black base - a gentle top glow instead of the old flat
            # faint wash, so VR Ready reads as lit rather than boring.
            # Plain background brush (NO DropShadow Effect on the card), so
            # the title + description text stay perfectly crisp.
            $vrBase = ConvertTo-MediaColor "#0c0c10"
            $vrGrn  = ConvertTo-MediaColor "#46a05a"
            $vrBlend = {
                param($a)
                [System.Windows.Media.Color]::FromRgb(
                    [byte]([Math]::Round($vrGrn.R * $a + $vrBase.R * (1 - $a))),
                    [byte]([Math]::Round($vrGrn.G * $a + $vrBase.G * (1 - $a))),
                    [byte]([Math]::Round($vrGrn.B * $a + $vrBase.B * (1 - $a))))
            }
            $vrBg = New-Object System.Windows.Media.RadialGradientBrush
            $vrBg.GradientOrigin = New-Object System.Windows.Point 0.5, 0.0
            $vrBg.Center         = New-Object System.Windows.Point 0.5, 0.0
            $vrBg.RadiusX = 0.95
            $vrBg.RadiusY = 0.80
            $vrBg.GradientStops.Add((New-Object System.Windows.Media.GradientStop ((& $vrBlend 0.257), 0.0)))  | Out-Null
            $vrBg.GradientStops.Add((New-Object System.Windows.Media.GradientStop ((& $vrBlend 0.086), 0.45))) | Out-Null
            $vrBg.GradientStops.Add((New-Object System.Windows.Media.GradientStop $vrBase, 1.0))              | Out-Null
            $vrBg.Freeze()
            $Card.Background = $vrBg
            $Card.BorderBrush = $conv.ConvertFromString("#1d2e22")
            $Card.BorderThickness = [System.Windows.Thickness]::new(1)
            # No card-level DropShadow here: it rasterizes the card and
            # softens the description text. VR Ready stays flat for crisp text.
            $Card.Effect = $null
            if ($BtnTxt) { $BtnTxt.Text = "VR Ready" }
            Set-NeonButtonState -Button $BtnBrd -Text $BtnTxt -ColorHex "#34d399" -Filled
            # Green fill + green frame; golden label (the colour from the
            # screenshot), a bit bolder for readability.
            if ($BtnTxt) {
                $BtnTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cdb77a")
                $BtnTxt.FontWeight = [System.Windows.FontWeights]::Bold
            }
            # VR Ready fill: a SMOOTH 2-stop green sheen (lit at the top,
            # a touch deeper at the bottom) - both stops opaque and in the
            # same green family, so it reads as gentle 3D rather than two
            # split halves. Button effect only; never touches the title.
            $vrGrad = New-Object System.Windows.Media.LinearGradientBrush
            $vrGrad.StartPoint = New-Object System.Windows.Point 0, 0
            $vrGrad.EndPoint   = New-Object System.Windows.Point 0, 1
            $vrGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(20, 34, 112, 82), 0.0))) | Out-Null
            $vrGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(20, 16, 66, 48), 1.0)))  | Out-Null
            $vrGrad.Freeze()
            if ($BtnBrd) {
                $BtnBrd.Background = $vrGrad
                # Keep the STANDARD green glow that Set-NeonButtonState
                # already applied (same strength as the Install buttons) so
                # the tile gets the same cool halo. We deliberately do NOT
                # add a stronger extra glow here - that earlier blur-14 halo
                # was what made the "VR Ready" text look fuzzy.
            }
        }
        "installed" {
            $Card.Background = New-CardTintBrush -BaseHex "#0c0c10" -TintHex "#f59e0b" -TopAlpha 0.16 -MidAlpha 0.05
            $Card.BorderBrush = $conv.ConvertFromString("#5c4420")
            $Card.BorderThickness = [System.Windows.Thickness]::new(1)
            $Card.Effect = $null
            Set-NeonButtonState -Button $BtnBrd -Text $BtnTxt -ColorHex "#f59e0b"
            # Same bold golden label as VR Ready, so an installed game's
            # Install button is an obvious "this game is on disk" marker
            # (distinct from a not-installed card's accent-coloured button).
            if ($BtnTxt) {
                $BtnTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cdb77a")
                $BtnTxt.FontWeight = [System.Windows.FontWeights]::Bold
            }
        }
    }
    $cap = $Card.Resources.Item("accentCap")
    if ($cap) { $cap.Visibility = [System.Windows.Visibility]::Collapsed }
}

# ------------------------------------------------------------
# Frosted state sync. The classic post-scan painters (Rebuild-
# Lookups + the end-of-scan repaint in Filter.ps1) paint cards in
# the flat classic style. When the frosted style is active we let
# that run, then immediately repaint the install-state in the
# frosted look via Set-CardStateVisual - keyed off the card's Tag
# so a single call covers update/ready/installed. No-op for the
# classic style or for cards with no install-state.
# ------------------------------------------------------------
function global:Sync-FrostedCardState {
    param($Card, $BtnTxt, $BtnBrd)
    if ($global:hubStyle -eq 'classic') { return }
    if (-not $Card) { return }
    $st = switch ([string]$Card.Tag) {
        "vrupdate"    { "update" }
        "vrinstalled" { "ready" }
        "installed"   { "installed" }
        default       { "" }
    }
    if ($st) {
        Set-CardStateVisual -Card $Card -BtnTxt $BtnTxt -BtnBrd $BtnBrd -State $st
        if ($Card.Resources.Contains("baseBgBrush")) { $Card.Resources.Remove("baseBgBrush") | Out-Null }
        if ($Card.Resources.Contains("baseBdBrush")) { $Card.Resources.Remove("baseBdBrush") | Out-Null }
        $Card.Resources.Add("baseBgBrush", $Card.Background) | Out-Null
        $Card.Resources.Add("baseBdBrush", $Card.BorderBrush) | Out-Null
    } else {
        # Not-installed / free: the card bg+border already hold the frosted
        # base look (restored from original* by the classic painter), but the
        # classic painter flattened the Install button to plain white text.
        # Restore the accent-neon Install button so the tile keeps its glow -
        # mirrors what New-GameCardFrosted builds and what the frosted scan
        # did for the default state.
        $acc = $Card.Resources.Item("originalAccent")
        if (-not $acc) { $acc = $Card.Resources.Item("baseAccent") }
        if (-not $acc) { $acc = "#dd6600" }
        if ($BtnBrd) { Set-NeonButtonState -Button $BtnBrd -Text $BtnTxt -ColorHex ([string]$acc) }
        # Frosted carries the accent in the neon button, not a left stripe.
        # The classic default painter re-shows the accent cap, so hide it
        # again here to match the frosted build look.
        $cap = $Card.Resources.Item("accentCap")
        if ($cap) { $cap.Visibility = [System.Windows.Visibility]::Collapsed }
    }
}

# ============================================================
# FROSTED-GLASS TILE FX (test redesign)
# ------------------------------------------------------------
# Additive-only visual layer. Does NOT touch the card's
# background brush, text, size, or any handler - everything
# below is hit-test-transparent overlay + a base elevation
# shadow, so all existing mechanics (hover repaint, click
# glow, steam preview, state painters) keep working unchanged.
#
# Three layers, painted bottom-to-top inside the card overlay:
#   1. Elevation shadow on the card itself  -> tile floats (3D)
#   2. Milky top sheen (white->transparent)  -> frosted glass
#   3. Glass bevel edge (light top / dark bottom) -> 3D rim
#
# The card's own Effect is used for the elevation shadow. The
# click-glow snapshots/restores $card.Effect, so it transparently
# preserves this shadow. Layers 2-4 are separate child elements
# with their own (or no) Effect, so the click-glow never disturbs
# them. NOTE: WPF blur/shadow/gradient rendering cannot be
# verified on Linux - visual tuning is by-eye on Windows only.
# ============================================================
function global:Add-FrostedGlassTileFx {
    param($Card, $Overlay, [string]$AccentHex, [double]$Sc = 1.0)

    if (-not $Card -or -not $Overlay) { return }
    $acc = ConvertTo-MediaColor $AccentHex
    $radius = [int](8 * $Sc)

    # ---- 1. (No card-level elevation shadow) ----------------
    # A DropShadowEffect on the card rasterizes it and turns OFF
    # ClearType, which softens the title text. The frosted look now
    # comes from the sheen + bevel below and the button's own glow
    # (which tints the tile) - all crisp, none blur the title.
    $Card.Effect = $null

    # ---- 2. Milky top sheen (frosted look) -----------------
    # White vertical gradient, brightest at the very top, gone by
    # ~55% height. A faint accent tint in the highlight ties it to
    # the card family. Reads as light catching a frosted pane.
    $sheen = New-Object System.Windows.Controls.Border
    $sheen.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
    $sheen.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $sheen.Height = [int](72 * $Sc)
    $sheen.Margin = [System.Windows.Thickness]::new(1, 1, 1, 0)
    $sheen.CornerRadius = [System.Windows.CornerRadius]::new($radius, $radius, 0, 0)
    $sheen.IsHitTestVisible = $false
    $shTop = [System.Windows.Media.Color]::FromArgb(
        24,
        [byte]([Math]::Round(255 * 0.82 + $acc.R * 0.18)),
        [byte]([Math]::Round(255 * 0.82 + $acc.G * 0.18)),
        [byte]([Math]::Round(255 * 0.82 + $acc.B * 0.18)))
    $shMid = [System.Windows.Media.Color]::FromArgb(7, 255, 255, 255)
    $shEnd = [System.Windows.Media.Color]::FromArgb(0, 255, 255, 255)
    $shBrush = New-Object System.Windows.Media.LinearGradientBrush
    $shBrush.StartPoint = New-Object System.Windows.Point 0, 0
    $shBrush.EndPoint   = New-Object System.Windows.Point 0, 1
    $shBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop $shTop, 0.0)) | Out-Null
    $shBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop $shMid, 0.45)) | Out-Null
    $shBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop $shEnd, 1.0)) | Out-Null
    $shBrush.Freeze()
    $sheen.Background = $shBrush
    $Overlay.Children.Add($sheen) | Out-Null

    # ---- 3. Glass bevel edge (3D rim) ----------------------
    # Transparent fill, 1px gradient stroke: bright at the top
    # (catches light), dark at the bottom (in shadow). Inset 0.5px
    # so it reads as the inner thickness of a glass pane sitting
    # just inside the card's own border.
    $bevel = New-Object System.Windows.Controls.Border
    $bevel.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $bevel.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    $bevel.Margin = [System.Windows.Thickness]::new(0.5)
    $bevel.CornerRadius = [System.Windows.CornerRadius]::new($radius)
    $bevel.BorderThickness = [System.Windows.Thickness]::new(1)
    $bevel.IsHitTestVisible = $false
    $bvBrush = New-Object System.Windows.Media.LinearGradientBrush
    $bvBrush.StartPoint = New-Object System.Windows.Point 0, 0
    $bvBrush.EndPoint   = New-Object System.Windows.Point 0, 1
    $bvBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(92, 255, 255, 255)), 0.0)) | Out-Null
    $bvBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(8, 255, 255, 255)), 0.5)) | Out-Null
    $bvBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(120, 0, 0, 0)), 1.0)) | Out-Null
    $bvBrush.Freeze()
    $bevel.BorderBrush = $bvBrush
    $Overlay.Children.Add($bevel) | Out-Null
}

# Hover "spotlights": two small soft accent glows (top-left + middle-right)
# layered behind the tile content, instead of flooding the whole card with
# a stronger flat tint (which read as a boring single-colour block). Each
# spot is a radial accent->transparent brush, so it lights a corner of the
# card and fades out. IsHitTestVisible=false; removed on MouseLeave.
function global:Set-CardHoverSpotlights {
    param($Card, [string]$AccentHex, [switch]$TopGlow)
    if (-not $Card) { return }
    $grid = $Card.Child
    if (-not $grid) { return }
    if ($Card.Resources.Contains("hoverSpots")) { return }
    $acc = ConvertTo-MediaColor $AccentHex
    $mkSpot = {
        param($cx, $cy, $rx, $ry, $aMax)
        $b = New-Object System.Windows.Controls.Border
        $b.IsHitTestVisible = $false
        $b.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $b.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rg = New-Object System.Windows.Media.RadialGradientBrush
        $rg.GradientOrigin = New-Object System.Windows.Point $cx, $cy
        $rg.Center         = New-Object System.Windows.Point $cx, $cy
        $rg.RadiusX = $rx; $rg.RadiusY = $ry
        $rg.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb([byte]$aMax, $acc.R, $acc.G, $acc.B), 0.0))) | Out-Null
        $rg.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb([byte]0, $acc.R, $acc.G, $acc.B), 1.0))) | Out-Null
        $rg.Freeze()
        $b.Background = $rg
        return $b
    }
    $spotHost = New-Object System.Windows.Controls.Grid
    $spotHost.IsHitTestVisible = $false
    [System.Windows.Controls.Grid]::SetRow($spotHost, 0)
    [System.Windows.Controls.Grid]::SetRowSpan($spotHost, 3)
    [System.Windows.Controls.Panel]::SetZIndex($spotHost, -1)
    # Gentle staggered "breathing": each spot fades between dim and bright,
    # offset by half a cycle, so one side brightens while the other dims and
    # vice versa - the tile subtly shifts instead of glowing flat.
    # Pulse cycle: each side EASES (SineEase) up to full and back down to
    # near-dark (0.1) once per period - smooth morphing, not on/off. The two
    # sides run opposite halves so their bright phases alternate; where they
    # cross, both sit mid-dim, blending the accent into soft frosty
    # gradients rather than a hard hand-off. "secondary" starts dark; the
    # primary side starts at full, giving VR Ready a soft start (the top
    # glow eases down instead of snapping).
    $pulseT = 7.0
    $mkPulse = {
        param($el, $kind, $period)
        if (-not $period) { $period = $pulseT }
        $kf = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $kf.Duration = [System.Windows.Duration]::new([TimeSpan]::FromSeconds($period))
        $kf.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $addKf = {
            param($v, $frac)
            $ease = New-Object System.Windows.Media.Animation.SineEase
            $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseInOut
            $k = New-Object System.Windows.Media.Animation.EasingDoubleKeyFrame
            $k.Value = $v
            $k.KeyTime = [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($period * $frac))
            $k.EasingFunction = $ease
            $kf.KeyFrames.Add($k) | Out-Null
        }
        switch ($kind) {
            # --- VR Ready: three phases rotate top -> left -> right, each
            #     lit while the other two sit dark (0.1) ---
            "t3" { $el.Opacity = 1.0; & $addKf 1.0 0.000; & $addKf 0.1 0.167; & $addKf 0.1 0.833; & $addKf 1.0 1.000 }
            "l3" { $el.Opacity = 0.1; & $addKf 0.1 0.000; & $addKf 0.1 0.167; & $addKf 1.0 0.333; & $addKf 0.1 0.500; & $addKf 0.1 1.000 }
            "r3" { $el.Opacity = 0.1; & $addKf 0.1 0.000; & $addKf 0.1 0.500; & $addKf 1.0 0.667; & $addKf 0.1 0.833; & $addKf 0.1 1.000 }
            # --- default/update: two opposite phases ---
            "s2" { $el.Opacity = 0.1; & $addKf 0.1 0.00; & $addKf 0.1 0.10; & $addKf 1.0 0.45; & $addKf 1.0 0.55; & $addKf 0.1 0.90; & $addKf 0.1 1.00 }
            default { $el.Opacity = 1.0; & $addKf 1.0 0.00; & $addKf 1.0 0.05; & $addKf 0.1 0.40; & $addKf 0.1 0.60; & $addKf 1.0 0.95; & $addKf 1.0 1.00 }
        }
        $el.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $kf)
    }
    $spot1 = & $mkSpot 0.26 0.3 0.5 0.5 62    # upper-left, where the title starts
    $spot2 = & $mkSpot 0.88 0.52 0.45 0.6 46  # middle-right
    if ($TopGlow) {
        # VR Ready: top blob, then left, then right light up one after the
        # other with the others dark. Top starts at full so the (now dimmer)
        # resting glow eases down softly on hover.
        $top = & $mkSpot 0.5 0.0 0.95 0.8 76
        & $mkPulse $top   "t3" 12
        & $mkPulse $spot1 "l3" 12
        & $mkPulse $spot2 "r3" 12
        $spotHost.Children.Add($top) | Out-Null
    } else {
        & $mkPulse $spot1 "p2"
        & $mkPulse $spot2 "s2"
    }
    $spotHost.Children.Add($spot1) | Out-Null
    $spotHost.Children.Add($spot2) | Out-Null
    $grid.Children.Add($spotHost) | Out-Null
    $Card.Resources.Add("hoverSpots", $spotHost)
}

function global:Clear-CardHoverSpotlights {
    param($Card)
    if (-not $Card) { return }
    if ($Card.Resources.Contains("hoverSpots")) {
        $sh = $Card.Resources.Item("hoverSpots")
        $grid = $Card.Child
        try {
            foreach ($ch in @($sh.Children)) {
                $ch.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
            }
        } catch { }
        try { if ($grid -and $grid.Children.Contains($sh)) { $grid.Children.Remove($sh) } } catch { }
        $Card.Resources.Remove("hoverSpots")
    }
}

# ============================================================
# NEON BUTTON STYLE (test redesign)
# ------------------------------------------------------------
# Clean neon Install button: no left accent cap, no sheen/bevel
# frills. The accent moves entirely onto a 1px vivid outline, a
# soft accent halo, and neon-colored label text on a near-black
# fill. Tiles already carry the color, so the button stays
# graphic and simple.
#
# Uses Get-GlowColor to floor the accent's luminance so even dark
# accents read as a vivid neon. The halo opacity is dampened by
# luminance so bright neons (green/yellow) don't bloom into a blob.
# The accent cap is only hidden (Collapsed), not removed, so the
# existing state/hover code that references it stays null-safe.
# WPF rendering is not verifiable on Linux.
# ============================================================
function global:Add-NeonButtonFx {
    param($Button, $Text, $Cap, [string]$AccentHex, [double]$Sc = 1.0)

    if (-not $Button) { return }
    # Hide the left accent bar - neon carries the colour instead.
    if ($Cap) { $Cap.Visibility = [System.Windows.Visibility]::Collapsed }
    # Default (mod not installed) state = game accent neon.
    Set-NeonButtonState -Button $Button -Text $Text -ColorHex $AccentHex -Sc $Sc
}


function global:New-GameCardFrosted {
    param($game, $isExternal, $window)
    $card = New-Object System.Windows.Controls.Border
    # Snap the entire card's layout to integer pixels. WPF renders
    # ClearType text blurry when an element lands on a sub-pixel X/Y,
    # which can happen anywhere the scaled ([int] * $sc) measurements
    # or nested panels (DockPanel/StackPanel) produce a non-integer
    # offset - the Daggerfall/Sonic "fuzzy title" symptom. Setting
    # this once on the card root makes it inherit to every child, so
    # we fix the whole class of blur at the source instead of patching
    # individual elements. It only rounds layout positions, not glyph
    # rasterization, so text keeps its normal weight.
    $card.UseLayoutRounding = $true
    # Cards are built ONCE at base size (1.0). The S/M/L size is applied
    # non-destructively via LayoutTransform in Apply-CardScale, so
    # changing size never rebuilds the list - it's instant and keeps the
    # current filter/visibility state.
    $sc = 1.0
    $card.Width  = [int](175 * $sc)
    $card.Height = [int](160 * $sc)
    $card.Margin = [System.Windows.Thickness]::new(0, 0, [int](12*$sc), [int](12*$sc))
    $card.CornerRadius = [System.Windows.CornerRadius]::new([int](8*$sc))

    # Accent color drives the card tint. Externals fall back to a
    # neutral gray-blue so the tinted look stays consistent.
    $accentHex = if ($game.Accent) { $game.Accent } elseif ($isExternal) { "#445566" } else { "#666677" }
    $card.Background = New-CardTintBrush -BaseHex "#0c0c10" -TintHex $accentHex -TopAlpha 0.10 -MidAlpha 0.02
    # Border picks up a darker variant of the tint so the card edge
    # also belongs to the family. We blend accent with base at ~22%.
    $bAcc  = ConvertTo-MediaColor $accentHex
    $bBase = ConvertTo-MediaColor "#0c0c10"
    $bMix  = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Round($bAcc.R*0.22 + $bBase.R*0.78)),
        [byte]([Math]::Round($bAcc.G*0.22 + $bBase.G*0.78)),
        [byte]([Math]::Round($bAcc.B*0.22 + $bBase.B*0.78))
    )
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush $bMix
    $card.Cursor = [System.Windows.Input.Cursors]::Hand
    # Stash both for state-restore + hover handlers.
    # baseBgBrush/baseBdBrush get OVERWRITTEN by the update/ready
    # state painters so hover restores match the new state. The
    # "original" keys are immutable - they hold the colors the card
    # was first painted with, so the default branch (no install
    # detected) can revert cleanly even after multiple state cycles.
    foreach ($k in @("baseAccent","baseBgBrush","baseBdBrush","originalBgBrush","originalBdBrush","originalAccent")) {
        if ($card.Resources.Contains($k)) { $card.Resources.Remove($k) }
    }
    $card.Resources.Add("baseAccent",  $accentHex)
    $card.Resources.Add("baseBgBrush", $card.Background)
    $card.Resources.Add("baseBdBrush", $card.BorderBrush)
    $card.Resources.Add("originalBgBrush", $card.Background)
    $card.Resources.Add("originalBdBrush", $card.BorderBrush)
    $card.Resources.Add("originalAccent",  $accentHex)

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = [System.Windows.Thickness]::new([int](14*$sc))

    $r0 = New-Object System.Windows.Controls.RowDefinition; $r0.Height = [System.Windows.GridLength]::Auto
    $r1 = New-Object System.Windows.Controls.RowDefinition; $r1.Height = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $r2 = New-Object System.Windows.Controls.RowDefinition; $r2.Height = [System.Windows.GridLength]::Auto
    $grid.RowDefinitions.Add($r0)
    $grid.RowDefinitions.Add($r1)
    $grid.RowDefinitions.Add($r2)

    # Family pill: small accent-tinted label in the top-left of the
    # card. Replaces the previous 2px accent bar. Externals get a
    # neutral "External" label so they still get a pill at all.
    $famName = Get-ModFamily -Game $game -IsExternal $isExternal
    $famPill = New-Object System.Windows.Controls.Border
    $famPill.CornerRadius = [System.Windows.CornerRadius]::new([int](3*$sc))
    $famPill.Padding = [System.Windows.Thickness]::new([int](6*$sc), [int](2*$sc), [int](6*$sc), [int](2*$sc))
    $famPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $famPill.Margin = [System.Windows.Thickness]::new(0, 0, 0, [int](8*$sc))
    # Pill background: ~18% opacity of accent over base
    $famAcc = ConvertTo-MediaColor $accentHex
    $famBg  = ConvertTo-MediaColor "#16161a"
    $pillColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Round($famAcc.R*0.18 + $famBg.R*0.82)),
        [byte]([Math]::Round($famAcc.G*0.18 + $famBg.G*0.82)),
        [byte]([Math]::Round($famAcc.B*0.18 + $famBg.B*0.82))
    )
    $famPill.Background = New-Object System.Windows.Media.SolidColorBrush $pillColor
    # Pill text: lighter version of accent (mix accent with white at 50%)
    $famTxtColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Round($famAcc.R*0.5 + 255*0.5)),
        [byte]([Math]::Round($famAcc.G*0.5 + 255*0.5)),
        [byte]([Math]::Round($famAcc.B*0.5 + 255*0.5))
    )
    $famTxt = New-Object System.Windows.Controls.TextBlock
    $famTxt.Text = $famName.ToUpper()
    $famTxt.FontSize = [int](8*$sc)
    $famTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $famTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush $famTxtColor
    $famTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $famPill.Child = $famTxt

    # Top stack holds pill + title group together in row 0
    $topStack = New-Object System.Windows.Controls.StackPanel
    $topStack.Orientation = [System.Windows.Controls.Orientation]::Vertical
    [System.Windows.Controls.Grid]::SetRow($topStack, 0)
    $topStack.Children.Add($famPill) | Out-Null
    $grid.Children.Add($topStack) | Out-Null
    # Stash family pill ref so the steam-preview manager can hide
    # it while the big image is shown (otherwise the pill covers
    # part of the artwork)
    $card.Resources.Add("famPill", $famPill)
    $isFreeGame = $global:FREE_GAME_TITLES -contains $game.Title
    $isWipGame  = $global:WIP_GAME_TITLES -contains $game.Title

    # Title stack (dot moved to overlay below i button)
    $titleStack = New-Object System.Windows.Controls.StackPanel
    $titleStack.Margin = [System.Windows.Thickness]::new(0, 0, 0, 0)
    $topStack.Children.Add($titleStack) | Out-Null

    $titleText = New-Object System.Windows.Controls.TextBlock
    # "Jedi Knight: Jedi Outcast VR" otherwise wraps with "VR" alone on
    # the second line. Glue "Outcast VR" together with a non-breaking
    # space so the break falls earlier ("...Jedi / Outcast VR"), matching
    # how the Academy tile reads. Scoped to this one title.
    $titleDisplay = $game.Title
    if ($titleDisplay -eq "Jedi Knight: Jedi Outcast VR") {
        $nbsp = [char]0x00A0
        $titleDisplay = "Jedi Knight: Jedi Outcast" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "No One Lives Forever 2 VR") {
        # Same fix: glue "Forever 2 VR" together with non-breaking spaces
        # so the wrap falls after "Lives" ("No One Lives" / "Forever 2 VR")
        # instead of orphaning "VR" on its own line. Scoped to this title.
        $nbsp = [char]0x00A0
        $titleDisplay = "No One Lives Forever" + $nbsp + "2" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Saints Row: The Third VR") {
        # Glue "The Third VR" together with non-breaking spaces so the only
        # break point left is after the colon ("Saints Row:" / "The Third VR")
        # instead of orphaning "VR" on its own line. Matches the Jedi titles.
        $nbsp = [char]0x00A0
        $titleDisplay = "Saints Row: The" + $nbsp + "Third" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Portal 2: Community Edition VR") {
        # Glue "Edition VR" together so "VR" never lands alone on line 2;
        # the title then wraps naturally to "Portal 2: Community" / "Edition VR".
        $nbsp = [char]0x00A0
        $titleDisplay = "Portal 2: Community Edition" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Horizon Forbidden West VR") {
        # Glue "West VR" together so the break falls after "Forbidden":
        # "Horizon Forbidden" / "West VR", matching the Jedi titles.
        $nbsp = [char]0x00A0
        $titleDisplay = "Horizon Forbidden West" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Panzer Dragoon Remake") {
        # Break after "Dragoon" and tag VR onto line 2: "Panzer Dragoon" / "Remake VR".
        $nbsp = [char]0x00A0
        $titleDisplay = "Panzer" + $nbsp + "Dragoon Remake" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Another Crab's Treasure") {
        # Break after "Crab's" and tag VR onto line 2: "Another Crab's" / "Treasure VR".
        $nbsp = [char]0x00A0
        $titleDisplay = "Another" + $nbsp + "Crab's Treasure" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Monster Hunter Rise VR") {
        # Break after "Hunter": "Monster Hunter" / "Rise VR".
        $nbsp = [char]0x00A0
        $titleDisplay = "Monster" + $nbsp + "Hunter Rise" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Monster Hunter Stories 3 VR") {
        # Break after "Hunter": "Monster Hunter" / "Stories 3 VR".
        $nbsp = [char]0x00A0
        $titleDisplay = "Monster" + $nbsp + "Hunter Stories" + $nbsp + "3" + $nbsp + "VR"
    }
    $titleText.Text = $titleDisplay
    $titleText.FontSize = [int](13*$sc)
    $titleText.FontWeight = [System.Windows.FontWeights]::Bold
    $titleGrad = New-Object System.Windows.Media.LinearGradientBrush
    $titleGrad.StartPoint = [System.Windows.Point]::new(0, 0)
    $titleGrad.EndPoint   = [System.Windows.Point]::new(0, 1)
    $titleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(255,255,255), 0))) | Out-Null
    $titleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(168,176,186), 1))) | Out-Null
    $titleGrad.Freeze()
    $titleText.Foreground = $titleGrad
    $titleText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $titleText.TextWrapping = [System.Windows.TextWrapping]::Wrap
    # For free-to-play games, the title shares its row with a small
    # green "FREE" pill docked to the right. There's usually room here
    # because game titles aren't that long, and this keeps the family-
    # pill area at top clean. For paid games the title goes straight
    # into the titleStack as before.
    if ($isFreeGame) {
        $freePill = New-Object System.Windows.Controls.Border
        $freePill.CornerRadius = [System.Windows.CornerRadius]::new([int](2*$sc))
        $freePill.Padding = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
        $freePill.BorderThickness = [System.Windows.Thickness]::new(1)
        $freePill.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freePill.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(20, 52, 211, 153))
        $freePill.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $freePill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $freePill.Margin = [System.Windows.Thickness]::new([int](4*$sc), [int](1*$sc), 0, 0)
        $freeTxt = New-Object System.Windows.Controls.TextBlock
        $freeTxt.Text = "FREE"
        $freeTxt.FontSize = [int](8*$sc)
        $freeTxt.FontWeight = [System.Windows.FontWeights]::Bold
        $freeTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freeTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $freePill.Child = $freeTxt
        $titleRow = New-Object System.Windows.Controls.DockPanel
        $titleRow.LastChildFill = $true
        $titleRow.UseLayoutRounding = $true
        $titleRow.SnapsToDevicePixels = $true
        [System.Windows.Controls.DockPanel]::SetDock($freePill, [System.Windows.Controls.Dock]::Right)
        $titleRow.Children.Add($freePill) | Out-Null
        $titleRow.Children.Add($titleText) | Out-Null
        $titleStack.Children.Add($titleRow) | Out-Null
    } elseif ($isWipGame) {
        # Same layout as the FREE pill, but a red "WIP" badge for mods
        # that run yet are still early / rough.
        $wipPill = New-Object System.Windows.Controls.Border
        $wipPill.CornerRadius = [System.Windows.CornerRadius]::new([int](2*$sc))
        $wipPill.Padding = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
        $wipPill.BorderThickness = [System.Windows.Thickness]::new(1)
        $wipPill.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(248, 113, 113))
        $wipPill.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(20, 248, 113, 113))
        $wipPill.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $wipPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $wipPill.Margin = [System.Windows.Thickness]::new([int](4*$sc), [int](1*$sc), 0, 0)
        $wipTxt = New-Object System.Windows.Controls.TextBlock
        $wipTxt.Text = "WIP"
        $wipTxt.FontSize = [int](8*$sc)
        $wipTxt.FontWeight = [System.Windows.FontWeights]::Bold
        $wipTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(248, 113, 113))
        $wipTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $wipPill.Child = $wipTxt
        $titleRow = New-Object System.Windows.Controls.DockPanel
        $titleRow.LastChildFill = $true
        $titleRow.UseLayoutRounding = $true
        $titleRow.SnapsToDevicePixels = $true
        [System.Windows.Controls.DockPanel]::SetDock($wipPill, [System.Windows.Controls.Dock]::Right)
        $titleRow.Children.Add($wipPill) | Out-Null
        $titleRow.Children.Add($titleText) | Out-Null
        $titleStack.Children.Add($titleRow) | Out-Null
    } else {
        $titleStack.Children.Add($titleText) | Out-Null
    }

    # Auto-layout: measure the title's actual rendered width and use the
    # compact meta layout ONLY when the title would wrap to 2+ lines in
    # the available card width.
    #   1-line title: separate "Mod" line + "by Author" line below
    #   2-line title: single compact meta line "Mod . by Author"
    # No hardcoded game-name lists - the only thing that matters is whether
    # the title actually wraps, which depends on character widths ("Black
    # Mesa Source VR" fits, "Horizon Chase Turbo VR" doesn't even though
    # they're similar length).
    #
    # Available text width in the card: card content is ~158px wide at sc=1
    # after padding + cover-image space. Anything wider than that wraps.
    $titleTypeface = New-Object System.Windows.Media.Typeface(
        $titleText.FontFamily,
        [System.Windows.FontStyles]::Normal,
        [System.Windows.FontWeights]::Bold,
        [System.Windows.FontStretches]::Normal
    )
    $titleFormatted = New-Object System.Windows.Media.FormattedText(
        $titleDisplay,
        [System.Globalization.CultureInfo]::CurrentCulture,
        [System.Windows.FlowDirection]::LeftToRight,
        $titleTypeface,
        $titleText.FontSize,
        [System.Windows.Media.Brushes]::White,
        96
    )
    # Pixel cutoff = the width where WPF actually breaks the line. The
    # raw available width is ~158px but TextBlock wraps a bit earlier
    # because of word-boundary rounding. 145 catches titles like
    # "Panzer Dragoon Remake" that visually wrap to 2 lines but measure
    # under 158px in pure FormattedText. Tweak if new games show
    # mis-classified wrap behavior.
    $titleAvailWidth = [int](145 * $sc)
    $isLongTitle = ($titleFormatted.Width -gt $titleAvailWidth)

    if (-not $isLongTitle) {
        # Short title: keep the classic two-line meta block.
        $modText = New-Object System.Windows.Controls.TextBlock
        $modText.Text = $game.Mod
        $modText.FontSize = [int](10*$sc)
        $modText.FontWeight = [System.Windows.FontWeights]::Medium
        $modText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($game.Accent)
        $modText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $modText.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
        $titleStack.Children.Add($modText) | Out-Null

        # Add-on banner: small blue "+ <AddonName> add-on" tag right
        # below the mod-version line. Shows whenever the catalog entry
        # has an AddonInstaller field (currently used for HL2VRU on
        # all three Half-Life 2 VR cards). The banner is a visual hint
        # only - the actual install button lives on the detail view.
        if ($game.AddonInstaller -and $game.AddonName) {
            $addonBanner = New-Object System.Windows.Controls.Border
            $addonBanner.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0e2030")
            $addonBanner.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5599ee")
            $addonBanner.BorderThickness = [System.Windows.Thickness]::new(1)
            $addonBanner.CornerRadius   = [System.Windows.CornerRadius]::new([int](2*$sc))
            $addonBanner.Padding        = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
            $addonBanner.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
            $addonBanner.Margin = [System.Windows.Thickness]::new(0, [int](3*$sc), 0, 0)
            $addonTxt = New-Object System.Windows.Controls.TextBlock
            $addonTxt.Text = "+ $($game.AddonName) add-on"
            $addonTxt.FontSize = [int](8*$sc)
            $addonTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
            $addonTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7ab5ff")
            $addonTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $addonBanner.Child = $addonTxt
            $titleStack.Children.Add($addonBanner) | Out-Null
            $card.Resources.Add("addonBanner", $addonBanner)
        } elseif ($game.ImprovementTag) {
            # Generic blue "improvement" tag (same look as the add-on
            # banner) for entries that are VR improvement modlists
            # rather than a single drop-in mod (e.g. Fallout 4 VR /
            # Skyrim VR via Wabbajack). Purely a visual hint.
            $impBanner = New-Object System.Windows.Controls.Border
            $impBanner.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0e2030")
            $impBanner.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5599ee")
            $impBanner.BorderThickness = [System.Windows.Thickness]::new(1)
            $impBanner.CornerRadius    = [System.Windows.CornerRadius]::new([int](2*$sc))
            $impBanner.Padding         = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
            $impBanner.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
            $impBanner.Margin = [System.Windows.Thickness]::new(0, [int](3*$sc), 0, 0)
            $impTxt = New-Object System.Windows.Controls.TextBlock
            $impTxt.Text = $game.ImprovementTag
            $impTxt.FontSize = [int](8*$sc)
            $impTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
            $impTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7ab5ff")
            $impTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $impBanner.Child = $impTxt
            $titleStack.Children.Add($impBanner) | Out-Null
            $card.Resources.Add("addonBanner", $impBanner)
        }

        if (-not $isExternal -and $game.Author) {
            $authorText = New-Object System.Windows.Controls.TextBlock
            $authorText.Text = "by $($game.Author)"
            $authorText.FontSize = [int](9*$sc)
            $authorText.FontWeight = [System.Windows.FontWeights]::Medium
            $authorText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#555568")
            $authorText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $authorText.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
            $titleStack.Children.Add($authorText) | Out-Null
            $card.Resources.Add("authorText", $authorText)
        } elseif ($isExternal) {
            # Externals (LR / REFramework family entries that go through
            # the external installer) don't have a separate Author field,
            # so the title stack would be shorter (title + mod only). Add
            # an invisible spacer line that mimics authorText's height so
            # the layout matches MC cards - and so the hover handler has
            # something to "hide" to make room under the preview image.
            # SKIP the spacer when the card already has an addonBanner
            # (HL2VR family) - the banner gives the hover handler
            # something to hide already, and the spacer would push the
            # Description down into the Install button.
            if (-not ($game.AddonInstaller -and $game.AddonName) -and -not $game.ImprovementTag) {
                $spacerText = New-Object System.Windows.Controls.TextBlock
                $spacerText.Text = " "
                $spacerText.FontSize = [int](9*$sc)
                $spacerText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $spacerText.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
                $titleStack.Children.Add($spacerText) | Out-Null
                $card.Resources.Add("authorText", $spacerText)
            }
        }
    } else {
        # Long title wraps to 2 lines on its own. To avoid the mod + author
        # block pushing the description and Install button off the card, we
        # collapse both into ONE small line: "Mod . by Author" with the mod
        # portion in the game's accent colour and the author tail in muted
        # grey. Uses an Inlines run so colours can split inside one TextBlock.
        $metaLine = New-Object System.Windows.Controls.TextBlock
        $metaLine.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $metaLine.FontSize = [int](9*$sc)
        $metaLine.FontWeight = [System.Windows.FontWeights]::Medium
        $metaLine.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
        $metaLine.TextWrapping = [System.Windows.TextWrapping]::NoWrap
        $metaLine.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis

        if ($game.Mod) {
            $modRun = New-Object System.Windows.Documents.Run
            $modRun.Text = $game.Mod
            $modRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($game.Accent)
            [void]$metaLine.Inlines.Add($modRun)
        }
        if ($game.Mod -and $game.Author) {
            $sepRun = New-Object System.Windows.Documents.Run
            $sepRun.Text = " . "
            $sepRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#444455")
            [void]$metaLine.Inlines.Add($sepRun)
        }
        if ($game.Author) {
            $authRun = New-Object System.Windows.Documents.Run
            $authRun.Text = "by $($game.Author)"
            $authRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#888899")
            [void]$metaLine.Inlines.Add($authRun)
        }
        if ($metaLine.Inlines.Count -gt 0) {
            $titleStack.Children.Add($metaLine) | Out-Null
        }
        # The hover preview overlays this area. Stash the meta line so the
        # hover handler can hide it (avoids the image clipping the text).
        $card.Resources.Add("modText", $metaLine)
        # Long-title cards don't get a separate authorText - the author is
        # already part of $metaLine above. The hover handler tolerates a
        # missing authorText (early-returns on null).
    }


    # NOTE: $titleStack was already added to $topStack on line 1653,
    # which is already in $grid. Don't add it again - WPF only
    # permits one logical parent per element.

    # Description: forced to a single line with ellipsis. Long
    # descriptions or wrapping titles would otherwise push the
    # Install button out of the card. The full text remains
    # accessible via the auto-tooltip (only shown when truncated).
    $descText = New-Object System.Windows.Controls.TextBlock
    $descText.Text = $game.Description
    $descText.FontSize = [int](10*$sc)
    $descText.FontWeight = [System.Windows.FontWeights]::Medium
    $descText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#777788")
    $descText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $descText.TextWrapping  = [System.Windows.TextWrapping]::NoWrap
    $descText.TextTrimming  = [System.Windows.TextTrimming]::CharacterEllipsis
    $descText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    # When an addon banner is present (HL2VR family with HL2VRU),
    # Row 0 grows by the banner height (~14px). Description should
    # sit at the TOP of Row 1 with a small top-margin so it floats
    # just below the add-on tag and away from the Install button.
    if ($game.AddonInstaller -and $game.AddonName) {
        $descText.Margin = [System.Windows.Thickness]::new(0, [int](4*$sc), 0, 0)
    } else {
        $descText.Margin = [System.Windows.Thickness]::new(0, [int](6*$sc), 0, 0)
    }
    $descText.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    if ($game.Description) { $descText.ToolTip = $game.Description }
    [System.Windows.Controls.Grid]::SetRow($descText, 1)
    $grid.Children.Add($descText) | Out-Null

    # Button: solid accent color. Smart text-contrast: light accents
    # (high luminance, e.g. Alba green #88cc44) get dark text; dark
    # accents get white text. Threshold ~150 picks the right side
    # Install button - Option D layout. Slate background (sitting
    # between the card's bottom-gradient and pure black) keeps the
    # button calm and readable; a 3px accent-color cap on the left
    # signals "action pending" and preserves the card's color
    # identity without the full-bleed quietsch. Cap color is the
    # game's accent; text is a soft warm-white tinted by accent
    # luminance for legibility.
    $btnAccentHex = Get-DampenedAccentHex $accentHex
    $btnAcc = ConvertTo-MediaColor $btnAccentHex
    # Slate fill: dark-but-tinted - takes meaningful color from
    # the game's accent so the button reads as part of the card,
    # not a generic grey strip. ~18% accent / 82% near-black,
    # which keeps strong colors (red, magenta) recognizable while
    # still being calm enough to read text on.
    $slateColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($btnAcc.R * 0.18 + 10))))),
        [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($btnAcc.G * 0.18 + 10))))),
        [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($btnAcc.B * 0.18 + 10)))))
    )
    $btnBorder = New-Object System.Windows.Controls.Border
    $btnBorder.CornerRadius = [System.Windows.CornerRadius]::new([int](4*$sc))
    $btnBorder.Background   = New-Object System.Windows.Media.SolidColorBrush $slateColor
    $btnBorder.BorderThickness = [System.Windows.Thickness]::new(0, 1, 0, 0)
    $btnBorder.BorderBrush  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
    $btnBorder.Padding = [System.Windows.Thickness]::new(0, [int](6*$sc), 0, [int](6*$sc))
    [System.Windows.Controls.Grid]::SetRow($btnBorder, 2)

    # Text color: warm-white tinted by the accent so each card's
    # button text picks up its card's color signature. ~30% accent
    # mix - enough to be visible (warm red on a red card, mint on
    # a green one) without losing readability.
    $textColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Min(255, [int]([Math]::Round(180 + $btnAcc.R * 0.30)))),
        [byte]([Math]::Min(255, [int]([Math]::Round(176 + $btnAcc.G * 0.30)))),
        [byte]([Math]::Min(255, [int]([Math]::Round(172 + $btnAcc.B * 0.30))))
    )
    $btnFgBrush = New-Object System.Windows.Media.SolidColorBrush $textColor

    $btnText = New-Object System.Windows.Controls.TextBlock
    $btnText.FontSize = [int](11*$sc)
    $btnText.FontWeight = [System.Windows.FontWeights]::SemiBold
    $btnText.Foreground = $btnFgBrush
    $btnText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $btnText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $btnText.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center

    if ($isExternal) {
        $btnText.Text = if ($game.ButtonLabel) { $game.ButtonLabel } else {
            switch ($game.Type) {
                "steam"    { "Open in Steam" }
                "itch"     { "Open on itch.io" }
                default    { "Get Installer" }
            }
        }
    } elseif ($game.DirectDownload) {
        $btnText.Text = "Install"
        $btnBorder.Opacity = 1.0
    } else {
        $batPath = Join-Path $scriptDir $game.Bat
        $batExists = Test-Path $batPath
        $btnText.Text = if ($batExists) { "Install" } else { "Not found" }
        $btnBorder.Opacity = if ($batExists) { 1.0 } else { 0.4 }
    }

    # Inner grid with the label centered and a reload-pill area
    # docked right. Pill is collapsed by default and only shown
    # when Check Installed flips the card into the VR Ready state.
    $btnInner = New-Object System.Windows.Controls.Grid
    $btnText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

    # Free games: "FREE" sits just before the "Install" label as one
    # centered unit (reads "FREE  Install"), in the game's accent (glow)
    # colour. A horizontal StackPanel keeps the pair centered no matter
    # the widths. FREE starts hidden - Check Installed reveals it once
    # the game is confirmed, and hides it again in the green VR-Ready
    # state (leaving just the centered "VR Ready" label). Stored as a
    # card resource for that toggle.
    $freeBtnLabel = $null
    if ($isFreeGame) {
        $freeAccCol = Get-GlowColor $accentHex
        $freeBtnLabel = New-Object System.Windows.Controls.TextBlock
        $freeBtnLabel.Text = "FREE"
        $freeBtnLabel.FontSize = [int](11*$sc)
        $freeBtnLabel.FontWeight = [System.Windows.FontWeights]::Bold
        $freeBtnLabel.Foreground = New-Object System.Windows.Media.SolidColorBrush $freeAccCol
        $freeBtnLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $freeBtnLabel.Margin = [System.Windows.Thickness]::new(0, 0, [int](8*$sc), 0)
        $freeBtnLabel.Visibility = [System.Windows.Visibility]::Collapsed
        try {
            $fglow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $fglow.Color = $freeAccCol
            $fglow.BlurRadius = 6
            $fglow.ShadowDepth = 0
            $fglow.Opacity = 0.7
            $freeBtnLabel.Effect = $fglow
        } catch {}

        $freeStack = New-Object System.Windows.Controls.StackPanel
        $freeStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $freeStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $freeStack.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
        $btnText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $freeStack.Children.Add($freeBtnLabel) | Out-Null
        $freeStack.Children.Add($btnText) | Out-Null
        # Text rides ABOVE the glowing button (added to the shell below),
        # not inside it, so the button's glow can never blur the label.
        $btnTextLayer = $freeStack
    } else {
        $btnTextLayer = $btnText
    }

    # Accent cap on the left edge - 3px wide bar in the game's
    # accent color. Acts as the "action pending" signal in the
    # default Install state. Recolored on state transitions:
    # green when game is installed but not VR-modded, blue when
    # an update is available, hidden in the VR-Ready state.
    $accentCap = New-Object System.Windows.Controls.Border
    $accentCap.Width  = [int](5*$sc)
    $accentCap.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $accentCap.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    $accentCap.Background          = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accentHex)
    # Bleed through the button's inner padding (top/bottom) so the
    # cap touches the button edges without leaving slate gaps.
    $accentCap.Margin = [System.Windows.Thickness]::new(0, [int](-6*$sc), 0, [int](-6*$sc))
    $btnInner.Children.Add($accentCap) | Out-Null

    # Reload pill: small fixed-width strip on the right with a
    # subtle vertical divider on its left edge. Hidden until the
    # card flips to VR Ready (Tag = "vrinstalled"). Mouse clicks
    # on it set e.Handled = true so the card-level click handler
    # (which launches the game) doesn't also fire.
    $reloadPill = New-Object System.Windows.Controls.Border
    $reloadPill.Width = [int](28*$sc)
    $reloadPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $reloadPill.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    $reloadPill.Background     = [System.Windows.Media.Brushes]::Transparent
    $reloadPill.BorderThickness = [System.Windows.Thickness]::new(1, 0, 0, 0)
    $reloadPill.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
    $reloadPill.Cursor         = [System.Windows.Input.Cursors]::Hand
    $reloadPill.Visibility     = [System.Windows.Visibility]::Collapsed
    $reloadPill.Margin         = [System.Windows.Thickness]::new(0, [int](-6*$sc), 0, [int](-6*$sc))
    $reloadGlyph = New-Object System.Windows.Controls.TextBlock
    $reloadGlyph.Text = [char]0x21BB
    $reloadGlyph.FontSize = [int](13*$sc)
    $reloadGlyph.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI Symbol")
    $reloadGlyph.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
    $reloadGlyph.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $reloadGlyph.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $reloadPill.Child = $reloadGlyph
    $btnInner.Children.Add($reloadPill) | Out-Null

    # Hover feedback for the reinstall arrow itself. The pill has no
    # hover of its own otherwise - covers every button type (VR Ready,
    # Update, DualMode) since each card has one pill. To stay clearly
    # visible WITHOUT wiping the vrupdate blue recoloring, we stash the
    # pill's CURRENT background on enter and restore exactly that on
    # leave (never a blind Transparent, which previously erased blue).
    $reloadGlyph.Opacity = 0.75
    $reloadPill.Add_MouseEnter({
        if (-not $this.Resources.Contains("pillHovStash")) {
            $this.Resources.Add("pillHovStash", $this.Background)
        }
        # Lighten the pill: a clear translucent-white overlay on top of
        # whatever colour it has (reads on both transparent and blue),
        # plus a full-opacity glyph.
        $this.Background = New-Object System.Windows.Media.SolidColorBrush(
            [System.Windows.Media.Color]::FromArgb(60, 255, 255, 255))
        $this.Child.Opacity = 1.0
    })
    $reloadPill.Add_MouseLeave({
        # Restore the EXACT background we had before hover (transparent
        # or the vrupdate blue), so we never clobber the recoloring.
        if ($this.Resources.Contains("pillHovStash")) {
            $this.Background = $this.Resources.Item("pillHovStash")
            $this.Resources.Remove("pillHovStash") | Out-Null
        }
        $this.Child.Opacity = 0.75
    })

    # DualMode split overlay - sits on top of $btnText for REPO VR /
    # Content Warning VR style games where both Mode 1 (current) and
    # Mode 2 (depot) are installed in parallel. Two side-by-side
    # buttons: "Current" (left) and "Depot" (right). Collapsed by
    # default; shown on hover only when Filter.ps1 marks the state as
    # DualMode. Reload pill sits to the right of these as usual.
    $dualSplit = New-Object System.Windows.Controls.Grid
    $dualSplit.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $dualSplit.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    $dualSplit.Margin              = [System.Windows.Thickness]::new(
        [int](5*$sc), [int](-6*$sc), [int](28*$sc), [int](-6*$sc)
    )
    $dualSplit.Visibility = [System.Windows.Visibility]::Collapsed
    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $col2 = New-Object System.Windows.Controls.ColumnDefinition
    $col2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $dualSplit.ColumnDefinitions.Add($col1) | Out-Null
    $dualSplit.ColumnDefinitions.Add($col2) | Out-Null

    $dualCurrentBtn = New-Object System.Windows.Controls.Border
    $dualCurrentBtn.Background     = [System.Windows.Media.Brushes]::Transparent
    $dualCurrentBtn.BorderThickness = [System.Windows.Thickness]::new(0, 0, 1, 0)
    $dualCurrentBtn.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
    $dualCurrentBtn.Cursor         = [System.Windows.Input.Cursors]::Hand
    [System.Windows.Controls.Grid]::SetColumn($dualCurrentBtn, 0)
    $dualCurrentTxt = New-Object System.Windows.Controls.TextBlock
    $dualCurrentTxt.Text = ([char]0x25B6) + " " + $(if ($game.TwoMods -and $game.ModAName) { $game.ModAName } else { "Current" })
    $dualCurrentTxt.FontSize = $(if ($game.TwoMods) { 8.5 } else { 11 })*$sc
    $dualCurrentTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $dualCurrentTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
    $dualCurrentTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $dualCurrentTxt.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $dualCurrentBtn.Child = $dualCurrentTxt
    $dualSplit.Children.Add($dualCurrentBtn) | Out-Null

    $dualDepotBtn = New-Object System.Windows.Controls.Border
    $dualDepotBtn.Background     = [System.Windows.Media.Brushes]::Transparent
    $dualDepotBtn.BorderThickness = [System.Windows.Thickness]::new(0)
    $dualDepotBtn.Cursor         = [System.Windows.Input.Cursors]::Hand
    [System.Windows.Controls.Grid]::SetColumn($dualDepotBtn, 1)
    $dualDepotTxt = New-Object System.Windows.Controls.TextBlock
    $dualDepotTxt.Text = ([char]0x25B6) + " " + $(if ($game.TwoMods -and $game.ModBName) { $game.ModBName } else { "Depot" })
    $dualDepotTxt.FontSize = $(if ($game.TwoMods) { 8.5 } else { 11 })*$sc
    $dualDepotTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $dualDepotTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
    $dualDepotTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $dualDepotTxt.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $dualDepotBtn.Child = $dualDepotTxt
    $dualSplit.Children.Add($dualDepotBtn) | Out-Null

    $btnInner.Children.Add($dualSplit) | Out-Null

    $btnBorder.Child = $btnInner
    # Neon button redesign (test): no accent cap, no glass frills -
    # vivid neon outline + halo + neon label text on a near-black fill.
    Add-NeonButtonFx -Button $btnBorder -Text $btnText -Cap $accentCap -AccentHex $accentHex -Sc $sc
    # Button shell: the glowing $btnBorder sits at the bottom; the label
    # rides ON TOP as a sibling with NO Effect. A DropShadowEffect only
    # rasterizes its OWN subtree, so a sibling label stays crisp while the
    # button keeps its halo. The label's vertical margin gives the button
    # its height (the border stretches to match). Hidden-on-dual-mode keeps
    # the slot, so the DualSplit overlay still shows underneath.
    $btnShell = New-Object System.Windows.Controls.Grid
    [System.Windows.Controls.Grid]::SetRow($btnShell, 2)
    $btnShell.Children.Add($btnBorder) | Out-Null
    if ($btnTextLayer) {
        $btnTextLayer.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $btnTextLayer.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
        $btnTextLayer.Margin = [System.Windows.Thickness]::new(0, [int](6*$sc), 0, [int](6*$sc))
        $btnTextLayer.IsHitTestVisible = $false
        $btnShell.Children.Add($btnTextLayer) | Out-Null
    }
    $grid.Children.Add($btnShell) | Out-Null
    # Store btnText, reload pill, accent cap on card for later access by Check Installed
    if ($card.Resources.Contains("btnText")) { $card.Resources.Remove("btnText") }
    if ($card.Resources.Contains("btnBorder")) { $card.Resources.Remove("btnBorder") }
    if ($card.Resources.Contains("reloadPill")) { $card.Resources.Remove("reloadPill") }
    if ($card.Resources.Contains("reloadGlyph")) { $card.Resources.Remove("reloadGlyph") }
    if ($card.Resources.Contains("accentCap")) { $card.Resources.Remove("accentCap") }
    if ($card.Resources.Contains("dualSplit")) { $card.Resources.Remove("dualSplit") }
    if ($card.Resources.Contains("dualCurrentBtn")) { $card.Resources.Remove("dualCurrentBtn") }
    if ($card.Resources.Contains("dualDepotBtn")) { $card.Resources.Remove("dualDepotBtn") }
    if ($card.Resources.Contains("gameData")) { $card.Resources.Remove("gameData") }
    $card.Resources.Add("btnText", $btnText)
    $card.Resources.Add("btnBorder", $btnBorder)
    if ($card.Resources.Contains("freeBtnLabel")) { $card.Resources.Remove("freeBtnLabel") }
    $card.Resources.Add("freeBtnLabel", $freeBtnLabel)
    $card.Resources.Add("reloadPill", $reloadPill)
    $card.Resources.Add("reloadGlyph", $reloadGlyph)
    $card.Resources.Add("accentCap", $accentCap)
    $card.Resources.Add("dualSplit", $dualSplit)
    $card.Resources.Add("dualCurrentBtn", $dualCurrentBtn)
    $card.Resources.Add("dualDepotBtn", $dualDepotBtn)
    $card.Resources.Add("gameData", $game)

    # DualMode split click handlers - route to Start-GameInVR with
    # the explicit Mode parameter. We stop event bubbling so the
    # card-level click handler doesn't also fire.
    $dualCurrentBtn.Resources.Add("ownerCard", $card)
    $dualCurrentBtn.Add_MouseLeftButtonDown({
        param($s, $e)
        $owner = $this.Resources.Item("ownerCard")
        $g = $owner.Resources.Item("gameData")
        if ($g) {
            if (Get-Command Start-GameInVR -EA SilentlyContinue) {
                Start-GameInVR -Game $g -Mode $(if ($g.TwoMods) { "ModA" } else { "Current" })
            }
        }
        $e.Handled = $true
    }.GetNewClosure())
    $dualDepotBtn.Resources.Add("ownerCard", $card)
    $dualDepotBtn.Add_MouseLeftButtonDown({
        param($s, $e)
        $owner = $this.Resources.Item("ownerCard")
        $g = $owner.Resources.Item("gameData")
        if ($g) {
            if (Get-Command Start-GameInVR -EA SilentlyContinue) {
                Start-GameInVR -Game $g -Mode $(if ($g.TwoMods) { "ModB" } else { "Depot" })
            }
        }
        $e.Handled = $true
    }.GetNewClosure())
    # Tinted hover background on each split half so the user sees
    # which one they're about to click. Matches the green family.
    $dualCurrentBtn.Add_MouseEnter({
        $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
    }.GetNewClosure())
    $dualCurrentBtn.Add_MouseLeave({
        $this.Background = [System.Windows.Media.Brushes]::Transparent
    }.GetNewClosure())
    $dualDepotBtn.Add_MouseEnter({
        $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
    }.GetNewClosure())
    $dualDepotBtn.Add_MouseLeave({
        $this.Background = [System.Windows.Media.Brushes]::Transparent
    }.GetNewClosure())

    # Inviting hover effect: a soft light-sweep gradient travels
    # diagonally across the button on MouseEnter. Subtle but draws
    # the eye. Only fires when the button is in default state
    # (not "VR Ready" outline style which has its own visual).
    $btnBorder.Resources.Add("accentHex", $accentHex)
    # Store the owning card directly - VisualTreeHelper walks were
    # unreliable (returned null in some render states) which caused
    # the skip-on-vrinstalled check to fail.
    $btnBorder.Resources.Add("ownerCard", $card)
    $btnBorder.Add_MouseEnter({
        $owner = $this.Resources.Item("ownerCard")
        if ($owner -and $owner.Tag -eq "vrinstalled") {
            # DualMode (REPO VR / Content Warning VR with both modes
            # installed): show the Current | Depot split instead of
            # the single "Start in VR" label. Filter.ps1 sets
            # DualMode=$true on gameStateMap when it detects both an
            # in-Steam mod AND a C:\Games\...\ depot install.
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            if ($st -and ($st.DualMode -or $st.TwoMods)) {
                $bt = $owner.Resources.Item("btnText")
                # Hidden (not Collapsed): keep the text's layout slot so
                # the button keeps its normal height; the split overlays.
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Hidden }
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Visible }
                # NOTE: do NOT return - we still want the reload pill
                # to show via the second handler below.
            } else {
                # Swap "VR Ready" -> "Start in VR" on hover. For non-
                # externals an additional handler also reveals the
                # Reinstall pill; we don't touch that here so both run
                # cleanly without conflict.
                $bt = $owner.Resources.Item("btnText")
                if ($bt -and -not $owner.Resources.Contains("readyOrigText")) {
                    $owner.Resources.Add("readyOrigText", $bt.Text)
                    $bt.Text = "Start in VR"
                }
            }
            return
        }
        # vrupdate state: morph the button to green-outline
        # "Start in VR" - matches the VR-Ready button's look so
        # the user has a clear affordance to launch without
        # forcing the update. No shine animation here: the
        # morph itself is the hover signal.
        if ($owner -and $owner.Tag -eq "vrupdate") {
            # Guard against a second pass: the card-level MouseEnter
            # raises this handler so the morph fires on whole-tile
            # hover. Once morphed (flag set on the card), don't run
            # again - re-stashing the morphed state as 'original'
            # would corrupt the MouseLeave restore.
            if ($owner.Resources.Contains("vrupdMorphed")) { return }
            $owner.Resources.Add("vrupdMorphed", $true)
            # DualMode in update state: same 3-way split, but the
            # reload pill on the right keeps its blue "Update Mod"
            # tint (handled by the secondary hover handler below).
            # Update always targets the Current variant - Depot is
            # version-pinned and never updated.
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            if ($st -and $st.DualMode) {
                # Stash + clear the blue background so the split row
                # underneath reads cleanly. Leave + click restore use
                # the same stashed values.
                if ($this.Resources.Contains("preHoverBrush"))   { $this.Resources.Remove("preHoverBrush")   | Out-Null }
                if ($this.Resources.Contains("preHoverBdBrush")) { $this.Resources.Remove("preHoverBdBrush") | Out-Null }
                if ($this.Resources.Contains("preHoverBdThick")) { $this.Resources.Remove("preHoverBdThick") | Out-Null }
                $this.Resources.Add("preHoverBrush",   $this.Background)
                $this.Resources.Add("preHoverBdBrush", $this.BorderBrush)
                $this.Resources.Add("preHoverBdThick", $this.BorderThickness)
                # Match the VR-Ready outline style so the split row
                # has the same visual chrome as the ready-state hover.
                $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
                $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
                $this.BorderThickness = [System.Windows.Thickness]::new(1)
                $bt = $owner.Resources.Item("btnText")
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Hidden }
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Visible }
                # Blue update pill on the right - Update is always
                # for Current. Stash original colours so MouseLeave
                # restores them.
                $rp = $owner.Resources.Item("reloadPill")
                $rg = $owner.Resources.Item("reloadGlyph")
                if ($rp -and $rg) {
                    if (-not $this.Resources.Contains("preHoverPillBg"))     { $this.Resources.Add("preHoverPillBg",     $rp.Background)   }
                    if (-not $this.Resources.Contains("preHoverPillBd"))     { $this.Resources.Add("preHoverPillBd",     $rp.BorderBrush)  }
                    if (-not $this.Resources.Contains("preHoverPillGlyphFg")){ $this.Resources.Add("preHoverPillGlyphFg",$rg.Foreground)  }
                    $rp.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
                    $rp.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
                    $rg.Foreground  = [System.Windows.Media.Brushes]::White
                    $rp.Visibility  = [System.Windows.Visibility]::Visible
                }
                return
            }
            # Stash current bg + text + colors so MouseLeave can
            # restore them precisely.
            if ($this.Resources.Contains("preHoverBrush"))     { $this.Resources.Remove("preHoverBrush")     | Out-Null }
            if ($this.Resources.Contains("preHoverBdBrush"))   { $this.Resources.Remove("preHoverBdBrush")   | Out-Null }
            if ($this.Resources.Contains("preHoverBdThick"))   { $this.Resources.Remove("preHoverBdThick")   | Out-Null }
            if ($this.Resources.Contains("preHoverTxtFg"))     { $this.Resources.Remove("preHoverTxtFg")     | Out-Null }
            if ($this.Resources.Contains("preHoverTxtText"))   { $this.Resources.Remove("preHoverTxtText")   | Out-Null }
            $this.Resources.Add("preHoverBrush",   $this.Background)
            $this.Resources.Add("preHoverBdBrush", $this.BorderBrush)
            $this.Resources.Add("preHoverBdThick", $this.BorderThickness)
            $btnTxt = $owner.Resources.Item("btnText")
            if ($btnTxt) {
                $this.Resources.Add("preHoverTxtFg",   $btnTxt.Foreground)
                $this.Resources.Add("preHoverTxtText", $btnTxt.Text)
            }
            # Apply VR-Ready outline style + Start label.
            $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
            $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
            $this.BorderThickness = [System.Windows.Thickness]::new(1)
            if ($btnTxt) {
                $btnTxt.Text = "Start in VR"
                $btnTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
            }
            # Blue update pill on the right. Same colour as the
            # primary "Update" button it replaces. Stash original
            # colours so MouseLeave can restore the green VR-Ready
            # tint (or transparent default) the pill had before.
            $rp = $owner.Resources.Item("reloadPill")
            $rg = $owner.Resources.Item("reloadGlyph")
            if ($rp -and $rg) {
                if (-not $this.Resources.Contains("preHoverPillBg"))     { $this.Resources.Add("preHoverPillBg",     $rp.Background)   }
                if (-not $this.Resources.Contains("preHoverPillBd"))     { $this.Resources.Add("preHoverPillBd",     $rp.BorderBrush)  }
                if (-not $this.Resources.Contains("preHoverPillGlyphFg")){ $this.Resources.Add("preHoverPillGlyphFg",$rg.Foreground)  }
                $rp.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
                $rp.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
                $rg.Foreground  = [System.Windows.Media.Brushes]::White
                $rp.Visibility  = [System.Windows.Visibility]::Visible
            }
            return
        }
        # Default state hover: a diagonal sweep travels across the
        # slate background. Outer stops stay anchored at the slate
        # color so the button reverts cleanly when the band leaves
        # the [0,1] range; only the inner three stops animate. The
        # peak is the accent color at ~50% mix into the slate -
        # bright enough to read as a sweep without losing the
        # button's calm identity. Cap brighten plays on top.
        if ($this.Resources.Contains("preHoverBrush")) {
            $this.Resources.Remove("preHoverBrush") | Out-Null
        }
        $this.Resources.Add("preHoverBrush", $this.Background)

        $accH = $this.Resources.Item("accentHex")
        if (-not $accH) { return }
        $accCol = ConvertTo-MediaColor $accH

        # Anchor the sweep on the button's *current* fill, not on
        # a recomputed slate. This matters when the card has
        # transitioned to a different state (installed = green
        # outline; future states could be other colors): the sweep
        # should ride over whatever is there, not flash slate
        # underneath. The default Install state still gets the
        # slate look because that's literally what $this.Background
        # is in that case.
        $sweepBase = $null
        if ($this.Background -is [System.Windows.Media.SolidColorBrush]) {
            $sweepBase = $this.Background.Color
        } else {
            # Fallback: recreate slate from accent (only used if a
            # previous hover left a gradient mid-flight, very rare).
            $sweepBase = [System.Windows.Media.Color]::FromRgb(
                [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($accCol.R * 0.18 + 10))))),
                [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($accCol.G * 0.18 + 10))))),
                [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($accCol.B * 0.18 + 10)))))
            )
        }
        # Sweep peak: shift sweepBase 30% toward white. This works
        # for any anchor color - dark slate, green-outline, blue
        # update CTA - and reads as a uniform "shine across the
        # button" instead of a state-specific accent flash.
        $slateBase = $sweepBase
        $sweepPeak = [System.Windows.Media.Color]::FromArgb(
            $sweepBase.A,
            [byte]([Math]::Min(255, [int]([Math]::Round($sweepBase.R + (255 - $sweepBase.R) * 0.30)))),
            [byte]([Math]::Min(255, [int]([Math]::Round($sweepBase.G + (255 - $sweepBase.G) * 0.30)))),
            [byte]([Math]::Min(255, [int]([Math]::Round($sweepBase.B + (255 - $sweepBase.B) * 0.30))))
        )

        $brush = New-Object System.Windows.Media.LinearGradientBrush
        $brush.StartPoint = New-Object System.Windows.Point 0, 0
        $brush.EndPoint   = New-Object System.Windows.Point 1, 1
        $sOutA = New-Object System.Windows.Media.GradientStop $slateBase, 0.0
        $sLead = New-Object System.Windows.Media.GradientStop $slateBase, 0.0
        $sPeak = New-Object System.Windows.Media.GradientStop $sweepPeak, 0.0
        $sTail = New-Object System.Windows.Media.GradientStop $slateBase, 0.0
        $sOutB = New-Object System.Windows.Media.GradientStop $slateBase, 1.0
        $brush.GradientStops.Add($sOutA) | Out-Null
        $brush.GradientStops.Add($sLead) | Out-Null
        $brush.GradientStops.Add($sPeak) | Out-Null
        $brush.GradientStops.Add($sTail) | Out-Null
        $brush.GradientStops.Add($sOutB) | Out-Null
        $this.Background = $brush

        $dur = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(700))
        $aLead = New-Object System.Windows.Media.Animation.DoubleAnimation -0.35, 1.05, $dur
        $aPeak = New-Object System.Windows.Media.Animation.DoubleAnimation -0.20, 1.20, $dur
        $aTail = New-Object System.Windows.Media.Animation.DoubleAnimation -0.05, 1.35, $dur
        $sLead.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aLead)
        $sPeak.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aPeak)
        $sTail.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aTail)

        # Brighten the cap on top of the sweep - both effects
        # together: cap pulses, sweep travels.
        $cap = if ($owner) { $owner.Resources.Item("accentCap") } else { $null }
        if ($cap) {
            if (-not $this.Resources.Contains("preHoverCapBrush")) {
                $this.Resources.Add("preHoverCapBrush", $cap.Background)
            }
            $brightCap = [System.Windows.Media.Color]::FromRgb(
                [byte]([Math]::Min(255, [int]([Math]::Round($accCol.R + (255 - $accCol.R) * 0.30)))),
                [byte]([Math]::Min(255, [int]([Math]::Round($accCol.G + (255 - $accCol.G) * 0.30)))),
                [byte]([Math]::Min(255, [int]([Math]::Round($accCol.B + (255 - $accCol.B) * 0.30))))
            )
            $cap.Background = New-Object System.Windows.Media.SolidColorBrush $brightCap
        }
    })
    $btnBorder.Add_MouseLeave({
        # Return to whatever the button looked like before we hovered -
        # this might be the accent brush, the VR-Ready green, etc.
        # We captured it on MouseEnter so it's always current.
        # Skip entirely on VR-Ready/installed cards: MouseEnter also
        # skipped, so there's no preHoverBrush, and we must NOT
        # reset to accentHex - that would paint the green button
        # with the original (red/orange/yellow) accent color.
        $owner = $this.Resources.Item("ownerCard")
        if ($owner -and $owner.Tag -eq "vrinstalled") {
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            if ($st -and ($st.DualMode -or $st.TwoMods)) {
                # DualMode only: if the cursor is still over the card
                # (moved from button onto the split overlay on top of
                # it), don't tear down - otherwise button-leave/enter
                # oscillate at the boundary and the split flickers. The
                # card-level MouseLeave restores on true tile exit.
                if ($owner.IsMouseOver) { return }
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Collapsed }
                $bt = $owner.Resources.Item("btnText")
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Visible }
            } else {
                # Normal VR Ready: restore "VR Ready" the moment the
                # cursor leaves the button (no IsMouseOver guard - this
                # swap is button-hover only, so it must undo on button
                # leave even while still over the card). Idempotent.
                $bt = $owner.Resources.Item("btnText")
                if ($bt -and $owner.Resources.Contains("readyOrigText")) {
                    $bt.Text = $owner.Resources.Item("readyOrigText")
                    $owner.Resources.Remove("readyOrigText") | Out-Null
                }
            }
            return
        }
        # vrupdate restore: undo the morph to green Start-in-VR.
        # We stashed the original button bg/border/text on hover,
        # so we just put them back. Match against the same Tag so
        # we don't accidentally apply this branch to a card whose
        # state changed mid-hover.
        if ($owner -and $owner.Tag -eq "vrupdate") {
            # If the cursor is still somewhere over the card (just moved
            # off the button onto the card body), keep the morph - the
            # card-level MouseLeave will restore when it truly leaves the
            # tile. Without this, moving button->card body would flicker
            # the button back to "Update" while still hovering the tile.
            if ($owner.IsMouseOver) { return }
            # Actually leaving the tile: clear the morph flag so the
            # next hover re-arms cleanly.
            if ($owner.Resources.Contains("vrupdMorphed")) {
                $owner.Resources.Remove("vrupdMorphed") | Out-Null
            }
            # DualMode: hide split + show btnText again. The bg/border
            # restore below still runs for normal vrupdate path so we
            # branch only on btnText handling.
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            if ($st -and $st.DualMode) {
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Collapsed }
                $bt = $owner.Resources.Item("btnText")
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Visible }
                # Restore bg/border (no btnText text/colour to undo in
                # DualMode - we only toggled visibility on it).
                $preBg  = $this.Resources.Item("preHoverBrush")
                $preBd  = $this.Resources.Item("preHoverBdBrush")
                $preBdT = $this.Resources.Item("preHoverBdThick")
                if ($preBg)  { $this.Background      = $preBg }
                if ($preBd)  { $this.BorderBrush     = $preBd }
                if ($preBdT) { $this.BorderThickness = $preBdT }
                # Restore + hide the blue update pill.
                $rp = $owner.Resources.Item("reloadPill")
                $rg = $owner.Resources.Item("reloadGlyph")
                if ($rp -and $rg) {
                    $prePillBg  = $this.Resources.Item("preHoverPillBg")
                    $prePillBd  = $this.Resources.Item("preHoverPillBd")
                    $prePillGFg = $this.Resources.Item("preHoverPillGlyphFg")
                    if ($prePillBg)  { $rp.Background  = $prePillBg }
                    if ($prePillBd)  { $rp.BorderBrush = $prePillBd }
                    if ($prePillGFg) { $rg.Foreground  = $prePillGFg }
                    if ($this.Resources.Contains("preHoverPillBg"))      { $this.Resources.Remove("preHoverPillBg")      | Out-Null }
                    if ($this.Resources.Contains("preHoverPillBd"))      { $this.Resources.Remove("preHoverPillBd")      | Out-Null }
                    if ($this.Resources.Contains("preHoverPillGlyphFg")) { $this.Resources.Remove("preHoverPillGlyphFg") | Out-Null }
                    $rp.Visibility = [System.Windows.Visibility]::Collapsed
                }
                return
            }
            $preBg     = $this.Resources.Item("preHoverBrush")
            $preBd     = $this.Resources.Item("preHoverBdBrush")
            $preBdT    = $this.Resources.Item("preHoverBdThick")
            $preTxtFg  = $this.Resources.Item("preHoverTxtFg")
            $preTxtTx  = $this.Resources.Item("preHoverTxtText")
            if ($preBg)  { $this.Background      = $preBg }
            if ($preBd)  { $this.BorderBrush     = $preBd }
            if ($preBdT) { $this.BorderThickness = $preBdT }
            $btnTxt = $owner.Resources.Item("btnText")
            if ($btnTxt) {
                if ($preTxtTx) { $btnTxt.Text       = $preTxtTx }
                if ($preTxtFg) { $btnTxt.Foreground = $preTxtFg }
            }
            # Restore + hide the blue update pill that MouseEnter
            # revealed for the non-DualMode vrupdate hover.
            $rp = $owner.Resources.Item("reloadPill")
            $rg = $owner.Resources.Item("reloadGlyph")
            if ($rp -and $rg) {
                $prePillBg  = $this.Resources.Item("preHoverPillBg")
                $prePillBd  = $this.Resources.Item("preHoverPillBd")
                $prePillGFg = $this.Resources.Item("preHoverPillGlyphFg")
                if ($prePillBg)  { $rp.Background  = $prePillBg }
                if ($prePillBd)  { $rp.BorderBrush = $prePillBd }
                if ($prePillGFg) { $rg.Foreground  = $prePillGFg }
                if ($this.Resources.Contains("preHoverPillBg"))      { $this.Resources.Remove("preHoverPillBg")      | Out-Null }
                if ($this.Resources.Contains("preHoverPillBd"))      { $this.Resources.Remove("preHoverPillBd")      | Out-Null }
                if ($this.Resources.Contains("preHoverPillGlyphFg")) { $this.Resources.Remove("preHoverPillGlyphFg") | Out-Null }
                $rp.Visibility = [System.Windows.Visibility]::Collapsed
            }
            return
        }
        $pre = $this.Resources.Item("preHoverBrush")
        if ($pre) {
            $this.Background = $pre
        } else {
            # Fallback if MouseEnter never stashed (e.g. animation was
            # interrupted): rebuild from the accent.
            $accH = $this.Resources.Item("accentHex")
            if ($accH) {
                $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accH)
            }
        }
        # Restore the cap to its pre-hover color
        $cap = if ($owner) { $owner.Resources.Item("accentCap") } else { $null }
        if ($cap) {
            $preCap = $this.Resources.Item("preHoverCapBrush")
            if ($preCap) {
                $cap.Background = $preCap
                $this.Resources.Remove("preHoverCapBrush") | Out-Null
            }
        }
    })
    # Info pill: a small horizontal capsule in the top-right of the
    # card, combining the controls dot (left half) and the "i" info
    # symbol (right half). The full pill is clickable -> opens the
    # InfoUrl - so the click target is large enough for VR pointers.
    # Hovering the dot half shows the controls tooltip.
    $hasInfo = [bool]$game.InfoUrl
    $hasDot  = [bool]$game.Controls

    if ($hasInfo -or $hasDot) {
        $pill = New-Object System.Windows.Controls.Border
        $pill.Height = [int](22*$sc)
        $pill.Background = [System.Windows.Media.Brushes]::Transparent
        $pill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $pill.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
        $pill.Margin = [System.Windows.Thickness]::new(0, [int](8*$sc), [int](8*$sc), 0)
        if ($hasInfo) { $pill.Cursor = [System.Windows.Input.Cursors]::Hand }

        # Two layers so the hover glow never blurs the glyph + "i":
        # the rounded edge + glow live on $pillEdge (no text), the
        # content sits on top as a crisp sibling with no effect.
        $pillGrid = New-Object System.Windows.Controls.Grid
        $pill.Child = $pillGrid

        $pillEdge = New-Object System.Windows.Controls.Border
        $pillEdge.CornerRadius = [System.Windows.CornerRadius]::new([int](11*$sc))
        $pillEdge.Background = [System.Windows.Media.Brushes]::Transparent
        $pillEdge.BorderThickness = [System.Windows.Thickness]::new(1)
        $pillEdge.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#40404e")
        $pillGrid.Children.Add($pillEdge) | Out-Null

        $pillStack = New-Object System.Windows.Controls.StackPanel
        $pillStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $pillStack.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $pillStack.Margin = [System.Windows.Thickness]::new([int](7*$sc), 0, [int](8*$sc), 0)
        $pillGrid.Children.Add($pillStack) | Out-Null

        # Shared brush for the glyph + "i" so a hover can brighten both
        # at once (mutate one Color) - scoped to this pill only.
        $famTxtBrush = New-Object System.Windows.Media.SolidColorBrush $famTxtColor

        if ($hasDot) {
            $ctrlIcon = New-ControlTypeIcon -Controls $game.Controls -Sc $sc -Stroke $famTxtBrush
            $pillStack.Children.Add($ctrlIcon) | Out-Null
        }

        if ($hasInfo -and $hasDot) {
            # Thin separator between dot and "i"
            $sep = New-Object System.Windows.Controls.Border
            $sep.Width = 1
            $sep.Height = [int](11*$sc)
            $sep.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a4a")
            $sep.Margin = [System.Windows.Thickness]::new([int](7*$sc), 0, [int](7*$sc), 0)
            $sep.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $pillStack.Children.Add($sep) | Out-Null
        }

        if ($hasInfo) {
            $infoText = New-Object System.Windows.Controls.TextBlock
            $infoText.Text = "i"
            $infoText.FontSize = [int](12*$sc)
            $infoText.FontStyle = [System.Windows.FontStyles]::Italic
            $infoText.FontWeight = [System.Windows.FontWeights]::Bold
            $infoText.Foreground = $famTxtBrush
            $infoText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $infoText.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
            $infoText.Margin = [System.Windows.Thickness]::new(0, [int](-1*$sc), 0, 0)
            $pillStack.Children.Add($infoText) | Out-Null
            $pill.ToolTip = "Open mod page"

            # Hover: the pill lights up. The glyph + "i" brighten to a more
            # luminous accent (via their shared brush) and the text-free
            # edge layer gains a stronger family-hue glow - symbols stay
            # perfectly crisp while the pill clearly pops.
            $famTxtBright = [System.Windows.Media.Color]::FromRgb(
                [byte]([Math]::Round($famTxtColor.R*0.55 + 255*0.45)),
                [byte]([Math]::Round($famTxtColor.G*0.55 + 255*0.45)),
                [byte]([Math]::Round($famTxtColor.B*0.55 + 255*0.45)))
            $pillGlow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $pillGlow.Color = $famAcc
            $pillGlow.BlurRadius = [int](10*$sc)
            $pillGlow.ShadowDepth = 0
            $pillGlow.Opacity = 0.85
            $pillHoverBorder = New-Object System.Windows.Media.SolidColorBrush $famTxtBright
            $pillRestBorder  = $pillEdge.BorderBrush
            $pill.Add_MouseEnter({
                $famTxtBrush.Color = $famTxtBright
                $pillEdge.BorderBrush = $pillHoverBorder
                $pillEdge.Effect = $pillGlow
            }.GetNewClosure())
            $pill.Add_MouseLeave({
                $famTxtBrush.Color = $famTxtColor
                $pillEdge.BorderBrush = $pillRestBorder
                $pillEdge.Effect = $null
            }.GetNewClosure())

            $infoUrlCapture = $game.InfoUrl
            $pill.Add_PreviewMouseLeftButtonDown({
                param($s,$e)
                $e.Handled = $true
                Start-Process $infoUrlCapture
            }.GetNewClosure())
        }

        $overlay = New-Object System.Windows.Controls.Grid
        $overlay.Children.Add($grid) | Out-Null
        $overlay.Children.Add($pill) | Out-Null
        $card.Child = $overlay
        # Stash info pill so steam-preview can hide it during big image
        $card.Resources.Add("infoPill", $pill)
    } else {
        $overlay = New-Object System.Windows.Controls.Grid
        $overlay.Children.Add($grid) | Out-Null
        $card.Child = $overlay
    }

    # Frosted-glass redesign (test): elevation shadow + milky sheen +
    # glass bevel + glowing accent top bar. Additive overlay only -
    # everything above (text/size/handlers/hover) is untouched.
    Add-FrostedGlassTileFx -Card $card -Overlay $overlay -AccentHex $accentHex -Sc $sc

    # ---- Steam preview overlay (any card with a resolvable image) -----
    # A hidden top strip that the hover manager populates with the
    # Steam header image (or a custom HeaderUrl/PortraitUrl if set).
    $cardHeaderUrl = Get-GameImageUrl -Game $game -Kind "header"
    # Prefer the local disk cache if present (offline-capable).
    if ($game.SteamId -and -not $game.HeaderUrl) {
        $cachedCardHdr = Get-CachedImageUri -SteamId $game.SteamId -Kind "header"
        if ($cachedCardHdr) { $cardHeaderUrl = $cachedCardHdr }
    }
    if ($cardHeaderUrl) {
        $previewHost = New-Object System.Windows.Controls.Grid
        $previewHost.Visibility = [System.Windows.Visibility]::Collapsed
        $previewHost.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
        $previewHost.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $previewHost.Height = [int](80 * $sc)
        $clip = New-Object System.Windows.Media.RectangleGeometry
        $clip.Rect = New-Object System.Windows.Rect 0, 0, ([int](175*$sc)), ([int](80*$sc))
        $clip.RadiusX = [int](7*$sc); $clip.RadiusY = [int](7*$sc)
        $previewHost.Clip = $clip

        $previewImage = New-Object System.Windows.Controls.Image
        $previewImage.Stretch = [System.Windows.Media.Stretch]::UniformToFill
        $previewHost.Children.Add($previewImage) | Out-Null

        $previewMediaHost = New-Object System.Windows.Controls.Grid
        $previewHost.Children.Add($previewMediaHost) | Out-Null

        $fadeBottom = New-Object System.Windows.Shapes.Rectangle
        $fadeBottom.Height = [int](18*$sc)
        $fadeBottom.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
        $fadeGrad = New-Object System.Windows.Media.LinearGradientBrush
        $fadeGrad.StartPoint = New-Object System.Windows.Point 0, 0
        $fadeGrad.EndPoint   = New-Object System.Windows.Point 0, 1
        $fadeGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,0,0,0)), 0.0)) | Out-Null
        $fadeGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(220,22,22,26)), 1.0)) | Out-Null
        $fadeBottom.Fill = $fadeGrad
        $previewHost.Children.Add($fadeBottom) | Out-Null

        $overlay.Children.Insert(1, $previewHost) | Out-Null

        # We store the resolved URL (not the raw SteamId) so the
        # preview manager doesn't need to know about overrides.
        # SteamId is also stored so the preview can fall back to
        # the Fastly CDN if Akamai 404s.
        $card.Resources.Add("previewHeaderUrl", $cardHeaderUrl)
        # Store SteamId only for games that actually use Steam artwork.
        # Cards with a bundled HeaderUrl (e.g. Halo CE, whose SteamId is
        # the unrelated MCC) get $null here so the hover's cache re-resolve
        # and fastly fallback never replace the bundled art with the wrong
        # game's Steam image.
        $card.Resources.Add("previewSteamId",   $(if ($game.HeaderUrl) { "" } else { $game.SteamId }))
        # Portrait fallback URL - mirrors the detail hero's chain so a
        # game whose header.jpg fails on BOTH CDNs still shows something
        # on hover (the detail page already falls back to portrait; the
        # hover banner used to have no portrait step and went blank).
        $card.Resources.Add("previewPortraitUrl", (Get-GameImageUrl -Game $game -Kind "portrait"))
        $card.Resources.Add("hasVideo",         [bool]$game.HasVideo)
        $card.Resources.Add("previewHost",      $previewHost)
        $card.Resources.Add("previewImage",     $previewImage)
        $card.Resources.Add("previewMediaHost", $previewMediaHost)
    }

    # ---- Hot zone: click body -> Discover detail; hover -> preview ---
    # Transparent border covering the central body of the card,
    # excluding the pill area at the top and Install button at the
    # bottom. Click on this zone jumps to the Discover detail view.
    # Hovering arms the Steam-preview timer for SteamId cards.
    # Hot-zone covers the central body of the card. Top is 34px to
    # leave room for the family-pill area; bottom is 32px for the
    # install button. Right edge goes all the way - the small
    # "pill protection" zone below sits above this in the visual
    # tree to prevent the hover-preview from arming when the user
    # is heading toward the info pill.
    $hotZone = New-Object System.Windows.Controls.Border
    $hotZone.Background = [System.Windows.Media.Brushes]::Transparent
    $hotZone.IsHitTestVisible = $true
    $hotZone.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $hotZone.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    # Bottom margin must clear the install button so card-body
    # clicks (-> Description) never steal the button's hit-test,
    # but stay below the description text. 32*$sc was too low
    # (button-top stole by hotZone), 50*$sc was too high
    # (hotZone gave up half the description line). 41*$sc is the
    # midpoint that lands cleanly between the two.
    $hotZone.Margin = [System.Windows.Thickness]::new(0, [int](34*$sc), 0, [int](41*$sc))
    $hotZone.Cursor = [System.Windows.Input.Cursors]::Hand
    $hotZone.Tag = @{ Game = $game; Card = $card }

    # Activate the hover preview only on cards we have an image for.
    # We check the URL stash that was set up earlier in this function.
    if ($card.Resources.Contains("previewHeaderUrl")) {
        $hotZone.Add_MouseEnter({
            $info = $this.Tag
            if (-not $info) { return }
            $global:HoverPendingCard = $info.Card
            if ($global:HoverTimer) { try { $global:HoverTimer.Stop() } catch { } }
            $global:HoverTimer = New-Object System.Windows.Threading.DispatcherTimer
            $global:HoverTimer.Interval = [TimeSpan]::FromMilliseconds($global:HoverDelayMs)
            $global:HoverTimer.Add_Tick({
                $global:HoverTimer.Stop()
                if ($global:HoverPendingCard) {
                    # Don't pop the preview if the cursor has already moved
                    # onto the Install button - popping it would shift the
                    # button down and turn the intended click into a
                    # description click.
                    $bb = $global:HoverPendingCard.Resources.Item("btnBorder")
                    if ($bb -and $bb.IsMouseOver) { $global:HoverPendingCard = $null; return }
                    Start-CardPreview -Card $global:HoverPendingCard
                    $global:HoverPendingCard = $null
                }
            })
            $global:HoverTimer.Start()
        })
    }

    # PreviewMouseLeftButtonDown (tunneling) so we fire BEFORE the
    # card's own MouseLeftButtonDown installer handler. Mark the
    # event handled so the installer never fires for body clicks.
    $hotZone.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        $info = $s.Tag
        if (-not $info -or -not $info.Game) { return }
        $e.Handled = $true
        # Fire the pulsing green border glow as immediate visual
        # confirmation. Show-DiscoverDetail can take a couple of
        # seconds on the first click of a session (Steam library
        # registry walk, header image fetch). Without this, the
        # user sees nothing happen and re-clicks.
        #
        # CRITICAL: Open-DiscoverDetailFromList is a heavy synchronous
        # call that hogs the UI thread for 1-3 seconds. If we call
        # it inline here, the animation is *started* but WPF never
        # gets to render a single frame of it - rendering only
        # resumes once the dispatcher unwinds. The visible result:
        # glow flashes when the detail view closes, sometimes the
        # green border gets stuck.
        # Fix: kick off the glow, then defer the heavy call to the
        # next dispatcher tick at Background priority. This lets
        # the Render pass (priority above Background but below
        # Normal) commit a handful of glow frames before the heavy
        # work begins. The user perceives instant feedback even
        # though the actual navigation happens ~16-32ms later.
        Start-CardClickGlowThenOpen -Card $info.Card -Game $info.Game
    })

    $overlay.Children.Add($hotZone) | Out-Null
    [System.Windows.Controls.Panel]::SetZIndex($hotZone, 5)
    $card.Resources.Add("hotZone", $hotZone)

    # Pill-protection zone: covers only the top-right corner where
    # the info pill sits, so mouse paths heading toward the pill
    # don't arm the hover-preview timer. Limited to roughly the
    # top third of the card height + a 50px wide right strip.
    # ZIndex order is: hotZone(5) < pillGuard(10) < pill(20).
    # That way pill clicks pass through pillGuard, but pillGuard
    # blocks hotZone from arming the hover timer in this corner.
    $pillGuard = New-Object System.Windows.Controls.Border
    $pillGuard.Background = [System.Windows.Media.Brushes]::Transparent
    $pillGuard.IsHitTestVisible = $true
    $pillGuard.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $pillGuard.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
    $pillGuard.Width  = [int](50*$sc)
    $pillGuard.Height = [int](40*$sc)
    $overlay.Children.Add($pillGuard) | Out-Null
    [System.Windows.Controls.Panel]::SetZIndex($pillGuard, 10)
    # If the info pill exists, lift it above the guard so clicks reach it.
    if ($card.Resources.Contains("infoPill")) {
        [System.Windows.Controls.Panel]::SetZIndex($card.Resources.Item("infoPill"), 20)
    }

    # Click shield over the top strip (family badge + info-pill row).
    # The hot zone leaves this strip out, and nothing else handles
    # clicks there, so they used to fall through to the card-level
    # installer (clicking near the family tag started an install).
    # Route those clicks to the detail page instead - only the
    # explicit Install button should install. The info pill (ZIndex
    # 20) stays above this shield so its own click still works, and
    # there is deliberately no MouseEnter here so the hover preview
    # is never armed from this strip.
    $topShield = New-Object System.Windows.Controls.Border
    $topShield.Background = [System.Windows.Media.Brushes]::Transparent
    $topShield.IsHitTestVisible = $true
    $topShield.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $topShield.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
    $topShield.Height = [int](34*$sc)
    $topShield.Cursor = [System.Windows.Input.Cursors]::Hand
    $topShield.Tag = @{ Game = $game; Card = $card }
    $topShield.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        $info = $s.Tag
        if (-not $info -or -not $info.Game) { return }
        $e.Handled = $true
        Start-CardClickGlowThenOpen -Card $info.Card -Game $info.Game
    })
    $overlay.Children.Add($topShield) | Out-Null
    [System.Windows.Controls.Panel]::SetZIndex($topShield, 11)
    # Keep the info pill above the new shield so its own click still fires.
    if ($card.Resources.Contains("infoPill")) {
        [System.Windows.Controls.Panel]::SetZIndex($card.Resources.Item("infoPill"), 20)
    }

    # ---- Hover lift (frosted tiles only) ---------------------------
    # No cursor-following (that read as distracting drift) and no skew
    # (that distorted). Just a small UNIFORM lift on hover: the card
    # scales up a touch, stays rectangular and centred. Yields to the
    # hover-preview - once that is active ($global:HoverActiveCard) the
    # preview owns the RenderTransform (1.4x + Steam art), so this lift
    # only shows in the brief window before the preview overlay appears.
    # Core System.Windows.Media types (real WPF). Not testable on Linux.
    $tiltScale = New-Object System.Windows.Media.ScaleTransform 1.0, 1.0
    $card.Add_MouseEnter({
        param($s, $e)
        if ($global:HoverActiveCard) { return }   # preview owns the transform
        try {
            $tiltScale.ScaleX = 1.06; $tiltScale.ScaleY = 1.06
            $s.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
            $s.RenderTransform = $tiltScale
            # Ember sparks behind the text (TEST). Particles are separate
            # Ellipse elements on a Canvas placed BEHIND the text (ZIndex -1)
            # inside $grid - NO card DropShadowEffect, so the title stays
            # crisp (unlike the glow). Hover-only, this card only; MouseLeave
            # tears them down. ~6 = subtle. All core WPF types.
            if (-not $s.Resources.Contains("sparkCanvas")) {
                $cw = [double]$s.ActualWidth; $ch = [double]$s.ActualHeight
                if ($cw -gt 10 -and $ch -gt 10) {
                    $sCanvas = New-Object System.Windows.Controls.Canvas
                    $sCanvas.ClipToBounds = $true
                    $sCanvas.IsHitTestVisible = $false
                    [System.Windows.Controls.Grid]::SetRow($sCanvas, 0)
                    [System.Windows.Controls.Grid]::SetRowSpan($sCanvas, 3)
                    [System.Windows.Controls.Panel]::SetZIndex($sCanvas, -1)
                    $grid.Children.Add($sCanvas) | Out-Null
                    $s.Resources.Add("sparkCanvas", $sCanvas)
                    $rise = [Math]::Min(72.0, $ch - 18.0)
                    for ($si = 0; $si -lt 6; $si++) {
                        $sx  = Get-Random -Minimum 6 -Maximum ([int][Math]::Max(8, $cw - 6))
                        $dur = (Get-Random -Minimum 2800 -Maximum 4300) / 1000.0
                        $beg = (Get-Random -Minimum 0 -Maximum 2600) / 1000.0
                        $sz  = Get-Random -Minimum 3 -Maximum 5
                        $el = New-Object System.Windows.Shapes.Ellipse
                        $el.Width = $sz; $el.Height = $sz; $el.Opacity = 0.0
                        $rg = New-Object System.Windows.Media.RadialGradientBrush
                        $rg.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(255,255,190,120), 0.0))) | Out-Null
                        $rg.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(180,255,140,46), 0.55))) | Out-Null
                        $rg.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,255,120,30), 1.0))) | Out-Null
                        $el.Fill = $rg
                        $tt = New-Object System.Windows.Media.TranslateTransform 0, 0
                        $el.RenderTransform = $tt
                        [System.Windows.Controls.Canvas]::SetLeft($el, [double]$sx)
                        [System.Windows.Controls.Canvas]::SetTop($el, $ch - 14.0)
                        $sCanvas.Children.Add($el) | Out-Null
                        $yAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
                        $yAnim.From = 0.0; $yAnim.To = -$rise
                        $yAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromSeconds($dur))
                        $yAnim.BeginTime = [TimeSpan]::FromSeconds($beg)
                        $yAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                        $oAnim = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
                        $oAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromSeconds($dur))
                        $oAnim.BeginTime = [TimeSpan]::FromSeconds($beg)
                        $oAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                        $oAnim.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame (0.0, [System.Windows.Media.Animation.KeyTime]::FromPercent(0.0)))) | Out-Null
                        $oAnim.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame (0.85, [System.Windows.Media.Animation.KeyTime]::FromPercent(0.18)))) | Out-Null
                        $oAnim.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame (0.0, [System.Windows.Media.Animation.KeyTime]::FromPercent(1.0)))) | Out-Null
                        $el.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oAnim)
                        $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $yAnim)
                    }
                }
            }
        } catch { }
    }.GetNewClosure())
    $card.Add_MouseLeave({
        param($s, $e)
        try {
            if ($global:HoverActiveCard -ne $s) { $s.RenderTransform = $null }
            $tiltScale.ScaleX = 1.0; $tiltScale.ScaleY = 1.0
            # Hard cleanup of the spark particles so nothing "sticks".
            if ($s.Resources.Contains("sparkCanvas")) {
                $sCanvas = $s.Resources.Item("sparkCanvas")
                try {
                    foreach ($pEl in @($sCanvas.Children)) {
                        $pEl.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
                        if ($pEl.RenderTransform) {
                            $pEl.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $null)
                        }
                    }
                    $sCanvas.Children.Clear()
                    if ($grid.Children.Contains($sCanvas)) { $grid.Children.Remove($sCanvas) }
                } catch { }
                $s.Resources.Remove("sparkCanvas")
            }
        } catch { }
    }.GetNewClosure())
    # Hover: rebuild a slightly stronger tint gradient on enter, restore
    # the stored base brush on leave. Tag determines which accent / base
    # combination is currently in play (default / vrinstalled / vrupdate).
    $card.Add_MouseEnter({
        $tag = $this.Tag
        $acc = $this.Resources.Item("baseAccent")
        if (-not $acc) { return }
        if ($tag -eq "vrinstalled") {
            # VR Ready: drop the permanent (frozen) top glow to the flat
            # base, then re-create it as a softly pulsing top-centre blob
            # via -TopGlow, so the original glow stays (a touch darker) and
            # breathes in phase with the left spot instead of the whole
            # lighting switching. MouseLeave restores the full radial glow.
            $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb([byte]12, [byte]12, [byte]16))
            Set-CardHoverSpotlights -Card $this -AccentHex "#46a05a" -TopGlow
            # Only DualMode cards (Current|Depot split) get the morph on
            # whole-tile enter - the split otherwise only shows on direct
            # button hover and flickers at the boundary. Normal VR Ready
            # cards keep their "Start in VR" swap on direct button hover
            # ONLY (raising it tile-wide felt wrong - user feedback).
            $g = $this.Resources.Item("gameData")
            $isDual = $false
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
                if ($st -and ($st.DualMode -or $st.TwoMods)) { $isDual = $true }
            }
            if ($isDual) {
                $bb = $this.Resources.Item("btnBorder")
                if ($bb) {
                    try {
                        $ev = New-Object System.Windows.Input.MouseEventArgs(
                            [System.Windows.Input.Mouse]::PrimaryDevice, 0)
                        $ev.RoutedEvent = [System.Windows.Input.Mouse]::MouseEnterEvent
                        $bb.RaiseEvent($ev)
                    } catch { }
                }
            }
        } elseif ($tag -eq "vrupdate") {
            Set-CardHoverSpotlights -Card $this -AccentHex $acc
            # Fire the button's morph on whole-tile hover so "Update"
            # swaps to "Start in VR" the moment the cursor reaches the
            # tile, not only when it lands on the button (too brief).
            # The button MouseEnter has a morph-flag guard; its
            # MouseLeave has an IsMouseOver guard - so this is safe.
            $bb = $this.Resources.Item("btnBorder")
            if ($bb -and -not $this.Resources.Contains("vrupdMorphed")) {
                try {
                    $ev = New-Object System.Windows.Input.MouseEventArgs(
                        [System.Windows.Input.Mouse]::PrimaryDevice, 0)
                    $ev.RoutedEvent = [System.Windows.Input.Mouse]::MouseEnterEvent
                    $bb.RaiseEvent($ev)
                } catch { }
            }
        } else {
            Set-CardHoverSpotlights -Card $this -AccentHex $acc
        }
    })
    $card.Add_MouseLeave({
        Clear-CardHoverSpotlights -Card $this
        $stored = $this.Resources.Item("baseBgBrush")
        if ($stored) { $this.Background = $stored }
        # Whole-tile leave: restore the morphed update button / DualMode
        # split via the button's own MouseLeave (IsMouseOver is now false
        # so it runs the real restore). Only for the cards that morph
        # from the card level: vrupdate, and DualMode vrinstalled.
        $needLeave = $false
        if ($this.Tag -eq "vrupdate" -and $this.Resources.Contains("vrupdMorphed")) {
            $needLeave = $true
        } elseif ($this.Tag -eq "vrinstalled") {
            $g = $this.Resources.Item("gameData")
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
                if ($st -and ($st.DualMode -or $st.TwoMods)) { $needLeave = $true }
            }
        }
        if ($needLeave) {
            $bb = $this.Resources.Item("btnBorder")
            if ($bb) {
                try {
                    $ev = New-Object System.Windows.Input.MouseEventArgs(
                        [System.Windows.Input.Mouse]::PrimaryDevice, 0)
                    $ev.RoutedEvent = [System.Windows.Input.Mouse]::MouseLeaveEvent
                    $bb.RaiseEvent($ev)
                } catch { }
            }
        }
        # Cancel any pending preview activation, tear down current
        if ($global:HoverTimer) { try { $global:HoverTimer.Stop() } catch { } }
        $global:HoverPendingCard = $null
        if ($global:HoverActiveCard -eq $this) { End-CardPreview }
    })

    # Click
    if ($isExternal) {
        $urlCapture         = $game.Url
        $typeCapture        = $game.Type
        $downloadCapture    = if ($game.DownloadUrl) { $game.DownloadUrl } else { $null }
        $infoUrlExtCapture  = if ($game.InfoUrl) { $game.InfoUrl } else { $null }
        $directDlCapture    = if ($game.DirectDownload) { $game.DirectDownload } else { $null }
        $gameCapture        = $game
        $cardCapture        = $card
        $card.Add_MouseLeftButtonDown({
            # VR Ready state: launch the game via Steam (or LaunchExe
            # if the entry has one). Same behaviour as non-external
            # vrinstalled cards - the card flips into "Start in VR"
            # mode and clicking should play, not reopen the mod page.
            if ($cardCapture.Tag -eq "vrinstalled") {
                Start-GameInVR -Game $gameCapture
                return
            }
            # Wabbajack-based entries: clicking just opens the
            # Wabbajack site. No download is triggered by us and
            # no Downloads folder needs opening - Wabbajack handles
            # everything itself once the user grabs it.
            if ($gameCapture.WabbajackUrl) {
                Start-Process $gameCapture.WabbajackUrl
                return
            }
            if ($directDlCapture) {
                Start-Process $directDlCapture
            } elseif ($typeCapture -ne "steam") {
                # Skip the Downloads-folder pre-open for entries
                # whose Url is just a Discord invite - no download
                # is actually triggered, so the explorer window
                # would just clutter the desktop. Also skip for
                # Vivecraft: vivecraft.org/downloads is several
                # clicks deep (pick a Minecraft version, then
                # Forge/Fabric, then the file) so the user won't
                # see the Downloads folder for a while.
                $isDiscordOnly = $urlCapture -and ($urlCapture -match "discord\.com|discord\.gg")
                $isVivecraft   = ($gameCapture.Title -eq "Vivecraft")
                # steam:// links (e.g. a beta-branch switch via
                # steam://gameproperties/<id>) don't download anything
                # to the Downloads folder - they just open Steam - so
                # opening Explorer would only clutter the desktop.
                $isSteamProtocol = $downloadCapture -and ($downloadCapture -match "^steam://")
                # Only pre-open the Downloads folder when we are actually
                # about to trigger a download (DownloadUrl set). Page-only
                # external entries - those that just open a mod/downloads
                # page in the browser for a manual grab (e.g. X-Wing VR /
                # XWVM) - have no DownloadUrl, so nothing lands in Downloads
                # and the explorer window would only clutter the desktop.
                if ($downloadCapture -and -not $isDiscordOnly -and -not $isVivecraft -and -not $isSteamProtocol) {
                    $downloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
                    try { Start-Process explorer.exe "`"$downloadsPath`"" } catch {}
                    Start-Sleep -Milliseconds 400
                }
                if ($downloadCapture) {
                    $resolvedUrl = $downloadCapture
                    # If it's a GitHub API URL, resolve the actual asset download URL
                    if ($downloadCapture -match "api.github.com") {
                        try {
                            $apiUrl = $downloadCapture
                            $response = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "VRModHub" } -ErrorAction Stop
                            # If response is array (all releases), pick first (newest) with assets
                            if ($response -is [array]) {
                                $release = $response | Where-Object { $_.assets.Count -gt 0 } | Select-Object -First 1
                            } else {
                                $release = $response
                            }
                            $exeAsset = $release.assets | Where-Object { $_.name -match "\.(exe|zip)$" } | Select-Object -First 1
                            if ($exeAsset) { $resolvedUrl = $exeAsset.browser_download_url }
                        } catch {}
                    }
                    Start-Process $resolvedUrl
                }
            }
            # Open the catalog Url too - but for Vivecraft, skip this:
            # DownloadUrl already opened the downloads page above, and
            # opening Url after would push the homepage on top of it,
            # hiding the per-version download list the user actually
            # needs.
            if ($gameCapture.Title -ne "Vivecraft" -and $urlCapture) {
                Start-Process $urlCapture
            }
            # Info page is opened only via the i button, not automatically here
        }.GetNewClosure())
    } elseif ($game.DirectDownload) {
        $dlCapture = $game.DirectDownload
        $card.Add_MouseLeftButtonDown({
            Start-Process $dlCapture
        }.GetNewClosure())
    } else {
        $batPath = Join-Path $scriptDir $game.Bat
        if (Test-Path $batPath) {
            $batCapture    = $batPath
            $titleCapture  = $game.Title
            $folderCapture = if ($game.SteamFolder) { $game.SteamFolder } else { "" }
            $exeCapture    = if ($game.GameExe) { $game.GameExe } else { "" }
            # REFramework family marker is the shared launcher path,
            # NOT the mere presence of GameExe - several non-RE
            # entries (KSP, Another Crab's Treasure) carry a GameExe
            # for shortcut/launch purposes and must route to their
            # own START_INSTALLER.bat instead of REFrameworkVR-core.ps1.
            $isRefCapture  = ($game.Bat -like "REFrameworkVR\*")
            $gameCapture   = $game
            $cardCapture   = $card

            # Direct btnBorder click handler: catches Start-in-VR clicks
            # at the button itself, before they bubble to the card. On
            # Virtual Desktop, the first click after VR-Ready -> Start-
            # in-VR hover-morph could get swallowed because the visual
            # tree re-allocates mid-bubble. Handling at the source with
            # e.Handled = $true sidesteps that race. The card-level
            # handler below still runs for the body / install button.
            $btnBorder.Add_MouseLeftButtonDown({
                param($s, $e)
                if ($cardCapture.Tag -eq "vrinstalled") {
                    $e.Handled = $true
                    Start-GameInVR -Game $gameCapture
                    return
                }
                if ($cardCapture.Tag -eq "vrupdate") {
                    $btnTxtRef = $cardCapture.Resources.Item("btnText")
                    if ($btnTxtRef -and $btnTxtRef.Text -eq "Start in VR") {
                        $e.Handled = $true
                        Start-GameInVR -Game $gameCapture
                    }
                }
            }.GetNewClosure())

            $card.Add_MouseLeftButtonDown({
                # VR Ready state: clicking the card launches the
                # game via Start-GameInVR (uses the recorded
                # install path + LaunchExe + LaunchArgs). Reinstall
                # is handled by the small reload pill on the right
                # of the button (which sets e.Handled = $true to
                # stop this card-level handler from firing).
                if ($cardCapture.Tag -eq "vrinstalled") {
                    Start-GameInVR -Game $gameCapture
                    return
                }
                # vrupdate state: distinguish hover ("Start in VR")
                # from default ("Update"). When the button is
                # currently morphed to green Start-in-VR, clicking
                # launches the game; otherwise the click runs the
                # installer to apply the update. Source of truth
                # is the visible button text, set by the hover
                # handlers a few hundred lines above.
                if ($cardCapture.Tag -eq "vrupdate") {
                    # Hover detection: either btnText was morphed to
                    # "Start in VR" (normal vrupdate), or btnText is
                    # collapsed because the DualMode split is showing.
                    # In either case, clicking the card body (outside
                    # the reload pill, which sets Handled=true) means
                    # the user wants to launch, not update.
                    $btnTxtRef = $cardCapture.Resources.Item("btnText")
                    $isHovering = $false
                    if ($btnTxtRef) {
                        if ($btnTxtRef.Text -eq "Start in VR") { $isHovering = $true }
                        if ($btnTxtRef.Visibility -eq [System.Windows.Visibility]::Hidden) { $isHovering = $true }
                    }
                    if ($isHovering) {
                        # Resolve DualMode preference: if the card is
                        # dual-mode the primary action is "Current".
                        $stForCard = $null
                        if ($global:gameStateMap.ContainsKey($gameCapture.Title)) {
                            $stForCard = $global:gameStateMap[$gameCapture.Title]
                        }
                        if ($stForCard -and $stForCard.DualMode) {
                            Start-GameInVR -Game $gameCapture -Mode "Current"
                        } else {
                            Start-GameInVR -Game $gameCapture
                        }
                        return
                    }
                    # Default click on blue Update button (no hover -
                    # rare but covers click-through edge cases): wipe
                    # the stored version so the next Check Installed
                    # persists the new one after the installer runs.
                    Remove-InstalledVersion -Game $gameCapture
                }
                # Launch the installer and capture the process so
                # we can refresh state when it exits. Same auto-
                # refresh polling pattern used in the detail view's
                # primary button - whichever surface launched the
                # installer wins.
                # Launch through the logging wrapper so the installer's console
                # output is saved to Logs\<Title>-<timestamp>.log. Branch logic
                # (LukeRoss / REFramework / standard) lives in one place now:
                # Start-LoggedInstaller (Helpers.ps1).
                $launchedProc = Start-LoggedInstaller -Game $gameCapture -BatPath $batCapture -RequiresAdmin:([bool]$gameCapture.RequiresAdmin)
                if ($launchedProc) {
                    $global:PendingInstallTitle = $titleCapture
                    try {
                        $timer = New-Object System.Windows.Threading.DispatcherTimer
                        $timer.Interval = [TimeSpan]::FromMilliseconds(750)
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

            # Reload pill click: triggers a reinstall, and marks
            # the event Handled so the card-level click (Start in
            # VR for VR Ready cards) does not also fire.
            $reloadPill.Add_MouseLeftButtonDown({
                param($s, $e)
                $e.Handled = $true
                # vrupdate: clear stored .installed_version so the
                # next Check-Installed scan persists the new version
                # after the installer runs. Matches the card-level
                # click handler's behaviour for the Update path.
                if ($cardCapture.Tag -eq "vrupdate") {
                    try { Remove-InstalledVersion -Game $gameCapture } catch { }
                }
                # Launch + capture the process so we can auto-refresh
                # this card's state when the installer exits (same
                # poll pattern as the card-body click). Without this
                # the card kept showing "Update" after an update.
                $plProc = Start-LoggedInstaller -Game $gameCapture -BatPath $batCapture -RequiresAdmin:([bool]$gameCapture.RequiresAdmin)
                if ($plProc) {
                    $global:PendingInstallTitle = $titleCapture
                    try {
                        $plTimer = New-Object System.Windows.Threading.DispatcherTimer
                        $plTimer.Interval = [TimeSpan]::FromMilliseconds(750)
                        $plTimer.Tag = $plProc
                        $plTimer.Add_Tick({
                            param($ts, $te)
                            $tp = $ts.Tag
                            if (-not $tp -or $tp.HasExited) {
                                try { $ts.Stop() } catch {}
                                try { Invoke-PostInstallRefresh } catch {}
                            }
                        })
                        $plTimer.Start()
                    } catch {}
                }
            }.GetNewClosure())

            # VR Ready hover: swap "VR Ready" -> "Start in VR" while
            # the cursor is over the button. The light-sweep effect
            # is already skipped for vrinstalled cards (see the
            # btnBorder MouseEnter handler above) so there's no
            # animation conflict.
            $btnBorder.Add_MouseEnter({
                $owner = $this.Resources.Item("ownerCard")
                if ($owner -and $owner.Tag -eq "vrinstalled") {
                    $g = $owner.Resources.Item("gameData")
                    $st = $null
                    if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                        $st = $global:gameStateMap[$g.Title]
                    }
                    if ($st -and ($st.DualMode -or $st.TwoMods)) {
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Hidden }
                        $ds = $owner.Resources.Item("dualSplit")
                        if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Visible }
                    } else {
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt -and -not $owner.Resources.Contains("readyOrigText")) {
                            $owner.Resources.Add("readyOrigText", $bt.Text)
                            $bt.Text = "Start in VR"
                        }
                    }
                    $rp = $owner.Resources.Item("reloadPill")
                    if ($rp) { $rp.Visibility = [System.Windows.Visibility]::Visible }
                }
            }.GetNewClosure())
            $btnBorder.Add_MouseLeave({
                $owner = $this.Resources.Item("ownerCard")
                if ($owner -and $owner.Tag -eq "vrinstalled") {
                    $g = $owner.Resources.Item("gameData")
                    $st = $null
                    if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                        $st = $global:gameStateMap[$g.Title]
                    }
                    if ($st -and ($st.DualMode -or $st.TwoMods)) {
                        # DualMode only: keep the split while the cursor
                        # is still over the card (anti-flicker). Card
                        # MouseLeave restores on true tile exit.
                        if ($owner.IsMouseOver) { return }
                        $ds = $owner.Resources.Item("dualSplit")
                        if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Collapsed }
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Visible }
                        $rp = $owner.Resources.Item("reloadPill")
                        if ($rp) { $rp.Visibility = [System.Windows.Visibility]::Collapsed }
                    } else {
                        # Normal VR Ready: restore text on button leave
                        # immediately (button-hover-only swap).
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt -and $owner.Resources.Contains("readyOrigText")) {
                            $bt.Text = $owner.Resources.Item("readyOrigText")
                            $owner.Resources.Remove("readyOrigText") | Out-Null
                        }
                        $rp = $owner.Resources.Item("reloadPill")
                        if ($rp) { $rp.Visibility = [System.Windows.Visibility]::Collapsed }
                    }
                }
            }.GetNewClosure())
        }
    }

    return $card
}


# ============================================================
#  CARD RENDERER DISPATCHER
#  Two switchable tile styles share one entry point. The active
#  style is $global:hubStyle ('frosted' = default redesign, or
#  'classic' = the original flat tiles). The Switch Hub Style
#  menu item + the header VR-glasses click flip this and rebuild
#  the cards. Both renderers take the same (game, isExternal,
#  window) args and return the finished Border.
# ============================================================
function global:New-GameCard {
    param($game, $isExternal, $window)
    if ($global:hubStyle -eq 'classic') {
        return (New-GameCardClassic -game $game -isExternal $isExternal -window $window)
    }
    return (New-GameCardFrosted -game $game -isExternal $isExternal -window $window)
}

function global:New-GameCardClassic {
    param($game, $isExternal, $window)

    $card = New-Object System.Windows.Controls.Border
    # Snap the entire card's layout to integer pixels. WPF renders
    # ClearType text blurry when an element lands on a sub-pixel X/Y,
    # which can happen anywhere the scaled ([int] * $sc) measurements
    # or nested panels (DockPanel/StackPanel) produce a non-integer
    # offset - the Daggerfall/Sonic "fuzzy title" symptom. Setting
    # this once on the card root makes it inherit to every child, so
    # we fix the whole class of blur at the source instead of patching
    # individual elements. It only rounds layout positions, not glyph
    # rasterization, so text keeps its normal weight.
    $card.UseLayoutRounding = $true
    # Cards are built ONCE at base size (1.0). The S/M/L size is applied
    # non-destructively via LayoutTransform in Apply-CardScale, so
    # changing size never rebuilds the list - it's instant and keeps the
    # current filter/visibility state.
    $sc = 1.0
    $card.Width  = [int](175 * $sc)
    $card.Height = [int](160 * $sc)
    $card.Margin = [System.Windows.Thickness]::new(0, 0, [int](12*$sc), [int](12*$sc))
    $card.CornerRadius = [System.Windows.CornerRadius]::new([int](8*$sc))

    # Accent color drives the card tint. Externals fall back to a
    # neutral gray-blue so the tinted look stays consistent.
    $accentHex = if ($game.Accent) { $game.Accent } elseif ($isExternal) { "#445566" } else { "#666677" }
    $card.Background = New-CardTintBrush -BaseHex "#16161a" -TintHex $accentHex -TopAlpha 0.10 -MidAlpha 0.02
    # Border picks up a darker variant of the tint so the card edge
    # also belongs to the family. We blend accent with base at ~22%.
    $bAcc  = ConvertTo-MediaColor $accentHex
    $bBase = ConvertTo-MediaColor "#16161a"
    $bMix  = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Round($bAcc.R*0.22 + $bBase.R*0.78)),
        [byte]([Math]::Round($bAcc.G*0.22 + $bBase.G*0.78)),
        [byte]([Math]::Round($bAcc.B*0.22 + $bBase.B*0.78))
    )
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush $bMix
    $card.Cursor = [System.Windows.Input.Cursors]::Hand
    # Stash both for state-restore + hover handlers.
    # baseBgBrush/baseBdBrush get OVERWRITTEN by the update/ready
    # state painters so hover restores match the new state. The
    # "original" keys are immutable - they hold the colors the card
    # was first painted with, so the default branch (no install
    # detected) can revert cleanly even after multiple state cycles.
    foreach ($k in @("baseAccent","baseBgBrush","baseBdBrush","originalBgBrush","originalBdBrush","originalAccent")) {
        if ($card.Resources.Contains($k)) { $card.Resources.Remove($k) }
    }
    $card.Resources.Add("baseAccent",  $accentHex)
    $card.Resources.Add("baseBgBrush", $card.Background)
    $card.Resources.Add("baseBdBrush", $card.BorderBrush)
    $card.Resources.Add("originalBgBrush", $card.Background)
    $card.Resources.Add("originalBdBrush", $card.BorderBrush)
    $card.Resources.Add("originalAccent",  $accentHex)

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = [System.Windows.Thickness]::new([int](14*$sc))

    $r0 = New-Object System.Windows.Controls.RowDefinition; $r0.Height = [System.Windows.GridLength]::Auto
    $r1 = New-Object System.Windows.Controls.RowDefinition; $r1.Height = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $r2 = New-Object System.Windows.Controls.RowDefinition; $r2.Height = [System.Windows.GridLength]::Auto
    $grid.RowDefinitions.Add($r0)
    $grid.RowDefinitions.Add($r1)
    $grid.RowDefinitions.Add($r2)

    # Family pill: small accent-tinted label in the top-left of the
    # card. Replaces the previous 2px accent bar. Externals get a
    # neutral "External" label so they still get a pill at all.
    $famName = Get-ModFamily -Game $game -IsExternal $isExternal
    $famPill = New-Object System.Windows.Controls.Border
    $famPill.CornerRadius = [System.Windows.CornerRadius]::new([int](3*$sc))
    $famPill.Padding = [System.Windows.Thickness]::new([int](6*$sc), [int](2*$sc), [int](6*$sc), [int](2*$sc))
    $famPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $famPill.Margin = [System.Windows.Thickness]::new(0, 0, 0, [int](8*$sc))
    # Pill background: ~18% opacity of accent over base
    $famAcc = ConvertTo-MediaColor $accentHex
    $famBg  = ConvertTo-MediaColor "#16161a"
    $pillColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Round($famAcc.R*0.18 + $famBg.R*0.82)),
        [byte]([Math]::Round($famAcc.G*0.18 + $famBg.G*0.82)),
        [byte]([Math]::Round($famAcc.B*0.18 + $famBg.B*0.82))
    )
    $famPill.Background = New-Object System.Windows.Media.SolidColorBrush $pillColor
    # Pill text: lighter version of accent (mix accent with white at 50%)
    $famTxtColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Round($famAcc.R*0.5 + 255*0.5)),
        [byte]([Math]::Round($famAcc.G*0.5 + 255*0.5)),
        [byte]([Math]::Round($famAcc.B*0.5 + 255*0.5))
    )
    $famTxt = New-Object System.Windows.Controls.TextBlock
    $famTxt.Text = $famName.ToUpper()
    $famTxt.FontSize = [int](9*$sc)
    $famTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $famTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush $famTxtColor
    $famTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $famPill.Child = $famTxt

    # Top stack holds pill + title group together in row 0
    $topStack = New-Object System.Windows.Controls.StackPanel
    $topStack.Orientation = [System.Windows.Controls.Orientation]::Vertical
    [System.Windows.Controls.Grid]::SetRow($topStack, 0)
    $topStack.Children.Add($famPill) | Out-Null
    $grid.Children.Add($topStack) | Out-Null
    # Stash family pill ref so the steam-preview manager can hide
    # it while the big image is shown (otherwise the pill covers
    # part of the artwork)
    $card.Resources.Add("famPill", $famPill)
    $isFreeGame = $global:FREE_GAME_TITLES -contains $game.Title
    $isWipGame  = $global:WIP_GAME_TITLES -contains $game.Title

    # Title stack (dot moved to overlay below i button)
    $titleStack = New-Object System.Windows.Controls.StackPanel
    $titleStack.Margin = [System.Windows.Thickness]::new(0, 0, 0, 0)
    $topStack.Children.Add($titleStack) | Out-Null

    $titleText = New-Object System.Windows.Controls.TextBlock
    # "Jedi Knight: Jedi Outcast VR" otherwise wraps with "VR" alone on
    # the second line. Glue "Outcast VR" together with a non-breaking
    # space so the break falls earlier ("...Jedi / Outcast VR"), matching
    # how the Academy tile reads. Scoped to this one title.
    $titleDisplay = $game.Title
    if ($titleDisplay -eq "Jedi Knight: Jedi Outcast VR") {
        $nbsp = [char]0x00A0
        $titleDisplay = "Jedi Knight: Jedi Outcast" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "No One Lives Forever 2 VR") {
        # Same fix: glue "Forever 2 VR" together with non-breaking spaces
        # so the wrap falls after "Lives" ("No One Lives" / "Forever 2 VR")
        # instead of orphaning "VR" on its own line. Scoped to this title.
        $nbsp = [char]0x00A0
        $titleDisplay = "No One Lives Forever" + $nbsp + "2" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Saints Row: The Third VR") {
        # Glue "The Third VR" together with non-breaking spaces so the only
        # break point left is after the colon ("Saints Row:" / "The Third VR")
        # instead of orphaning "VR" on its own line. Matches the Jedi titles.
        $nbsp = [char]0x00A0
        $titleDisplay = "Saints Row: The" + $nbsp + "Third" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Portal 2: Community Edition VR") {
        # Glue "Edition VR" together so "VR" never lands alone on line 2;
        # the title then wraps naturally to "Portal 2: Community" / "Edition VR".
        $nbsp = [char]0x00A0
        $titleDisplay = "Portal 2: Community Edition" + $nbsp + "VR"
    }
    $titleText.Text = $titleDisplay
    $titleText.FontSize = [int](13*$sc)
    $titleText.FontWeight = [System.Windows.FontWeights]::SemiBold
    $titleGrad = New-Object System.Windows.Media.LinearGradientBrush
    $titleGrad.StartPoint = [System.Windows.Point]::new(0, 0)
    $titleGrad.EndPoint   = [System.Windows.Point]::new(0, 1)
    $titleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(255,255,255), 0))) | Out-Null
    $titleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(216,222,227), 1))) | Out-Null
    $titleGrad.Freeze()
    $titleText.Foreground = $titleGrad
    $titleText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $titleText.TextWrapping = [System.Windows.TextWrapping]::Wrap
    # For free-to-play games, the title shares its row with a small
    # green "FREE" pill docked to the right. There's usually room here
    # because game titles aren't that long, and this keeps the family-
    # pill area at top clean. For paid games the title goes straight
    # into the titleStack as before.
    if ($isFreeGame) {
        $freePill = New-Object System.Windows.Controls.Border
        $freePill.CornerRadius = [System.Windows.CornerRadius]::new([int](2*$sc))
        $freePill.Padding = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
        $freePill.BorderThickness = [System.Windows.Thickness]::new(1)
        $freePill.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freePill.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(20, 52, 211, 153))
        $freePill.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $freePill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $freePill.Margin = [System.Windows.Thickness]::new([int](4*$sc), [int](1*$sc), 0, 0)
        $freeTxt = New-Object System.Windows.Controls.TextBlock
        $freeTxt.Text = "FREE"
        $freeTxt.FontSize = [int](8*$sc)
        $freeTxt.FontWeight = [System.Windows.FontWeights]::Bold
        $freeTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freeTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $freePill.Child = $freeTxt
        $titleRow = New-Object System.Windows.Controls.DockPanel
        $titleRow.LastChildFill = $true
        $titleRow.UseLayoutRounding = $true
        $titleRow.SnapsToDevicePixels = $true
        [System.Windows.Controls.DockPanel]::SetDock($freePill, [System.Windows.Controls.Dock]::Right)
        $titleRow.Children.Add($freePill) | Out-Null
        $titleRow.Children.Add($titleText) | Out-Null
        $titleStack.Children.Add($titleRow) | Out-Null
    } elseif ($isWipGame) {
        # Same layout as the FREE pill, but a red "WIP" badge for mods
        # that run yet are still early / rough.
        $wipPill = New-Object System.Windows.Controls.Border
        $wipPill.CornerRadius = [System.Windows.CornerRadius]::new([int](2*$sc))
        $wipPill.Padding = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
        $wipPill.BorderThickness = [System.Windows.Thickness]::new(1)
        $wipPill.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(248, 113, 113))
        $wipPill.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(20, 248, 113, 113))
        $wipPill.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $wipPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $wipPill.Margin = [System.Windows.Thickness]::new([int](4*$sc), [int](1*$sc), 0, 0)
        $wipTxt = New-Object System.Windows.Controls.TextBlock
        $wipTxt.Text = "WIP"
        $wipTxt.FontSize = [int](8*$sc)
        $wipTxt.FontWeight = [System.Windows.FontWeights]::Bold
        $wipTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(248, 113, 113))
        $wipTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $wipPill.Child = $wipTxt
        $titleRow = New-Object System.Windows.Controls.DockPanel
        $titleRow.LastChildFill = $true
        $titleRow.UseLayoutRounding = $true
        $titleRow.SnapsToDevicePixels = $true
        [System.Windows.Controls.DockPanel]::SetDock($wipPill, [System.Windows.Controls.Dock]::Right)
        $titleRow.Children.Add($wipPill) | Out-Null
        $titleRow.Children.Add($titleText) | Out-Null
        $titleStack.Children.Add($titleRow) | Out-Null
    } else {
        $titleStack.Children.Add($titleText) | Out-Null
    }

    # Auto-layout: measure the title's actual rendered width and use the
    # compact meta layout ONLY when the title would wrap to 2+ lines in
    # the available card width.
    #   1-line title: separate "Mod" line + "by Author" line below
    #   2-line title: single compact meta line "Mod . by Author"
    # No hardcoded game-name lists - the only thing that matters is whether
    # the title actually wraps, which depends on character widths ("Black
    # Mesa Source VR" fits, "Horizon Chase Turbo VR" doesn't even though
    # they're similar length).
    #
    # Available text width in the card: card content is ~158px wide at sc=1
    # after padding + cover-image space. Anything wider than that wraps.
    $titleTypeface = New-Object System.Windows.Media.Typeface(
        $titleText.FontFamily,
        [System.Windows.FontStyles]::Normal,
        [System.Windows.FontWeights]::SemiBold,
        [System.Windows.FontStretches]::Normal
    )
    $titleFormatted = New-Object System.Windows.Media.FormattedText(
        $game.Title,
        [System.Globalization.CultureInfo]::CurrentCulture,
        [System.Windows.FlowDirection]::LeftToRight,
        $titleTypeface,
        $titleText.FontSize,
        [System.Windows.Media.Brushes]::White,
        96
    )
    # Pixel cutoff = the width where WPF actually breaks the line. The
    # raw available width is ~158px but TextBlock wraps a bit earlier
    # because of word-boundary rounding. 145 catches titles like
    # "Panzer Dragoon Remake" that visually wrap to 2 lines but measure
    # under 158px in pure FormattedText. Tweak if new games show
    # mis-classified wrap behavior.
    $titleAvailWidth = [int](145 * $sc)
    $isLongTitle = ($titleFormatted.Width -gt $titleAvailWidth)

    if (-not $isLongTitle) {
        # Short title: keep the classic two-line meta block.
        $modText = New-Object System.Windows.Controls.TextBlock
        $modText.Text = $game.Mod
        $modText.FontSize = [int](10*$sc)
        $modText.FontWeight = [System.Windows.FontWeights]::Medium
        $modText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($game.Accent)
        $modText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $modText.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
        $titleStack.Children.Add($modText) | Out-Null

        # Add-on banner: small blue "+ <AddonName> add-on" tag right
        # below the mod-version line. Shows whenever the catalog entry
        # has an AddonInstaller field (currently used for HL2VRU on
        # all three Half-Life 2 VR cards). The banner is a visual hint
        # only - the actual install button lives on the detail view.
        if ($game.AddonInstaller -and $game.AddonName) {
            $addonBanner = New-Object System.Windows.Controls.Border
            $addonBanner.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0e2030")
            $addonBanner.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5599ee")
            $addonBanner.BorderThickness = [System.Windows.Thickness]::new(1)
            $addonBanner.CornerRadius   = [System.Windows.CornerRadius]::new([int](2*$sc))
            $addonBanner.Padding        = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
            $addonBanner.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
            $addonBanner.Margin = [System.Windows.Thickness]::new(0, [int](3*$sc), 0, 0)
            $addonTxt = New-Object System.Windows.Controls.TextBlock
            $addonTxt.Text = "+ $($game.AddonName) add-on"
            $addonTxt.FontSize = [int](8*$sc)
            $addonTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
            $addonTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7ab5ff")
            $addonTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $addonBanner.Child = $addonTxt
            $titleStack.Children.Add($addonBanner) | Out-Null
            $card.Resources.Add("addonBanner", $addonBanner)
        } elseif ($game.ImprovementTag) {
            # Generic blue "improvement" tag (same look as the add-on
            # banner) for entries that are VR improvement modlists
            # rather than a single drop-in mod (e.g. Fallout 4 VR /
            # Skyrim VR via Wabbajack). Purely a visual hint.
            $impBanner = New-Object System.Windows.Controls.Border
            $impBanner.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0e2030")
            $impBanner.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5599ee")
            $impBanner.BorderThickness = [System.Windows.Thickness]::new(1)
            $impBanner.CornerRadius    = [System.Windows.CornerRadius]::new([int](2*$sc))
            $impBanner.Padding         = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
            $impBanner.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
            $impBanner.Margin = [System.Windows.Thickness]::new(0, [int](3*$sc), 0, 0)
            $impTxt = New-Object System.Windows.Controls.TextBlock
            $impTxt.Text = $game.ImprovementTag
            $impTxt.FontSize = [int](8*$sc)
            $impTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
            $impTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7ab5ff")
            $impTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $impBanner.Child = $impTxt
            $titleStack.Children.Add($impBanner) | Out-Null
            $card.Resources.Add("addonBanner", $impBanner)
        }

        if (-not $isExternal -and $game.Author) {
            $authorText = New-Object System.Windows.Controls.TextBlock
            $authorText.Text = "by $($game.Author)"
            $authorText.FontSize = [int](9*$sc)
            $authorText.FontWeight = [System.Windows.FontWeights]::Medium
            $authorText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#555568")
            $authorText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $authorText.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
            $titleStack.Children.Add($authorText) | Out-Null
            $card.Resources.Add("authorText", $authorText)
        } elseif ($isExternal) {
            # Externals (LR / REFramework family entries that go through
            # the external installer) don't have a separate Author field,
            # so the title stack would be shorter (title + mod only). Add
            # an invisible spacer line that mimics authorText's height so
            # the layout matches MC cards - and so the hover handler has
            # something to "hide" to make room under the preview image.
            # SKIP the spacer when the card already has an addonBanner
            # (HL2VR family) - the banner gives the hover handler
            # something to hide already, and the spacer would push the
            # Description down into the Install button.
            if (-not ($game.AddonInstaller -and $game.AddonName) -and -not $game.ImprovementTag) {
                $spacerText = New-Object System.Windows.Controls.TextBlock
                $spacerText.Text = " "
                $spacerText.FontSize = [int](9*$sc)
                $spacerText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $spacerText.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
                $titleStack.Children.Add($spacerText) | Out-Null
                $card.Resources.Add("authorText", $spacerText)
            }
        }
    } else {
        # Long title wraps to 2 lines on its own. To avoid the mod + author
        # block pushing the description and Install button off the card, we
        # collapse both into ONE small line: "Mod . by Author" with the mod
        # portion in the game's accent colour and the author tail in muted
        # grey. Uses an Inlines run so colours can split inside one TextBlock.
        $metaLine = New-Object System.Windows.Controls.TextBlock
        $metaLine.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $metaLine.FontSize = [int](9*$sc)
        $metaLine.FontWeight = [System.Windows.FontWeights]::Medium
        $metaLine.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
        $metaLine.TextWrapping = [System.Windows.TextWrapping]::NoWrap
        $metaLine.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis

        if ($game.Mod) {
            $modRun = New-Object System.Windows.Documents.Run
            $modRun.Text = $game.Mod
            $modRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($game.Accent)
            [void]$metaLine.Inlines.Add($modRun)
        }
        if ($game.Mod -and $game.Author) {
            $sepRun = New-Object System.Windows.Documents.Run
            $sepRun.Text = " . "
            $sepRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#444455")
            [void]$metaLine.Inlines.Add($sepRun)
        }
        if ($game.Author) {
            $authRun = New-Object System.Windows.Documents.Run
            $authRun.Text = "by $($game.Author)"
            $authRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#888899")
            [void]$metaLine.Inlines.Add($authRun)
        }
        if ($metaLine.Inlines.Count -gt 0) {
            $titleStack.Children.Add($metaLine) | Out-Null
        }
        # The hover preview overlays this area. Stash the meta line so the
        # hover handler can hide it (avoids the image clipping the text).
        $card.Resources.Add("modText", $metaLine)
        # Long-title cards don't get a separate authorText - the author is
        # already part of $metaLine above. The hover handler tolerates a
        # missing authorText (early-returns on null).
    }


    # NOTE: $titleStack was already added to $topStack on line 1653,
    # which is already in $grid. Don't add it again - WPF only
    # permits one logical parent per element.

    # Description: forced to a single line with ellipsis. Long
    # descriptions or wrapping titles would otherwise push the
    # Install button out of the card. The full text remains
    # accessible via the auto-tooltip (only shown when truncated).
    $descText = New-Object System.Windows.Controls.TextBlock
    $descText.Text = $game.Description
    $descText.FontSize = [int](10*$sc)
    $descText.FontWeight = [System.Windows.FontWeights]::Medium
    $descText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#777788")
    $descText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $descText.TextWrapping  = [System.Windows.TextWrapping]::NoWrap
    $descText.TextTrimming  = [System.Windows.TextTrimming]::CharacterEllipsis
    $descText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    # When an addon banner is present (HL2VR family with HL2VRU),
    # Row 0 grows by the banner height (~14px). Description should
    # sit at the TOP of Row 1 with a small top-margin so it floats
    # just below the add-on tag and away from the Install button.
    if ($game.AddonInstaller -and $game.AddonName) {
        $descText.Margin = [System.Windows.Thickness]::new(0, [int](4*$sc), 0, 0)
    } else {
        $descText.Margin = [System.Windows.Thickness]::new(0, [int](6*$sc), 0, 0)
    }
    $descText.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    if ($game.Description) { $descText.ToolTip = $game.Description }
    [System.Windows.Controls.Grid]::SetRow($descText, 1)
    $grid.Children.Add($descText) | Out-Null

    # Button: solid accent color. Smart text-contrast: light accents
    # (high luminance, e.g. Alba green #88cc44) get dark text; dark
    # accents get white text. Threshold ~150 picks the right side
    # Install button - Option D layout. Slate background (sitting
    # between the card's bottom-gradient and pure black) keeps the
    # button calm and readable; a 3px accent-color cap on the left
    # signals "action pending" and preserves the card's color
    # identity without the full-bleed quietsch. Cap color is the
    # game's accent; text is a soft warm-white tinted by accent
    # luminance for legibility.
    $btnAccentHex = Get-DampenedAccentHex $accentHex
    $btnAcc = ConvertTo-MediaColor $btnAccentHex
    # Slate fill: dark-but-tinted - takes meaningful color from
    # the game's accent so the button reads as part of the card,
    # not a generic grey strip. ~18% accent / 82% near-black,
    # which keeps strong colors (red, magenta) recognizable while
    # still being calm enough to read text on.
    $slateColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($btnAcc.R * 0.18 + 10))))),
        [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($btnAcc.G * 0.18 + 10))))),
        [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($btnAcc.B * 0.18 + 10)))))
    )
    $btnBorder = New-Object System.Windows.Controls.Border
    $btnBorder.CornerRadius = [System.Windows.CornerRadius]::new([int](4*$sc))
    $btnBorder.Background   = New-Object System.Windows.Media.SolidColorBrush $slateColor
    $btnBorder.BorderThickness = [System.Windows.Thickness]::new(0, 1, 0, 0)
    $btnBorder.BorderBrush  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
    $btnBorder.Padding = [System.Windows.Thickness]::new(0, [int](6*$sc), 0, [int](6*$sc))
    [System.Windows.Controls.Grid]::SetRow($btnBorder, 2)

    # Text color: warm-white tinted by the accent so each card's
    # button text picks up its card's color signature. ~30% accent
    # mix - enough to be visible (warm red on a red card, mint on
    # a green one) without losing readability.
    $textColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Min(255, [int]([Math]::Round(180 + $btnAcc.R * 0.30)))),
        [byte]([Math]::Min(255, [int]([Math]::Round(176 + $btnAcc.G * 0.30)))),
        [byte]([Math]::Min(255, [int]([Math]::Round(172 + $btnAcc.B * 0.30))))
    )
    $btnFgBrush = New-Object System.Windows.Media.SolidColorBrush $textColor

    $btnText = New-Object System.Windows.Controls.TextBlock
    $btnText.FontSize = [int](11*$sc)
    $btnText.FontWeight = [System.Windows.FontWeights]::SemiBold
    $btnText.Foreground = $btnFgBrush
    $btnText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $btnText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $btnText.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center

    if ($isExternal) {
        $btnText.Text = if ($game.ButtonLabel) { $game.ButtonLabel } else {
            switch ($game.Type) {
                "steam"    { "Open in Steam" }
                "itch"     { "Open on itch.io" }
                default    { "Get Installer" }
            }
        }
    } elseif ($game.DirectDownload) {
        $btnText.Text = "Install"
        $btnBorder.Opacity = 1.0
    } else {
        $batPath = Join-Path $scriptDir $game.Bat
        $batExists = Test-Path $batPath
        $btnText.Text = if ($batExists) { "Install" } else { "Not found" }
        $btnBorder.Opacity = if ($batExists) { 1.0 } else { 0.4 }
    }

    # Inner grid with the label centered and a reload-pill area
    # docked right. Pill is collapsed by default and only shown
    # when Check Installed flips the card into the VR Ready state.
    $btnInner = New-Object System.Windows.Controls.Grid
    $btnText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

    # Free games: "FREE" sits just before the "Install" label as one
    # centered unit (reads "FREE  Install"), in the game's accent (glow)
    # colour. A horizontal StackPanel keeps the pair centered no matter
    # the widths. FREE starts hidden - Check Installed reveals it once
    # the game is confirmed, and hides it again in the green VR-Ready
    # state (leaving just the centered "VR Ready" label). Stored as a
    # card resource for that toggle.
    $freeBtnLabel = $null
    if ($isFreeGame) {
        $freeAccCol = Get-GlowColor $accentHex
        $freeBtnLabel = New-Object System.Windows.Controls.TextBlock
        $freeBtnLabel.Text = "FREE"
        $freeBtnLabel.FontSize = [int](11*$sc)
        $freeBtnLabel.FontWeight = [System.Windows.FontWeights]::Bold
        $freeBtnLabel.Foreground = New-Object System.Windows.Media.SolidColorBrush $freeAccCol
        $freeBtnLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $freeBtnLabel.Margin = [System.Windows.Thickness]::new(0, 0, [int](8*$sc), 0)
        $freeBtnLabel.Visibility = [System.Windows.Visibility]::Collapsed
        try {
            $fglow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $fglow.Color = $freeAccCol
            $fglow.BlurRadius = 6
            $fglow.ShadowDepth = 0
            $fglow.Opacity = 0.7
            $freeBtnLabel.Effect = $fglow
        } catch {}

        $freeStack = New-Object System.Windows.Controls.StackPanel
        $freeStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $freeStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $freeStack.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
        $btnText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $freeStack.Children.Add($freeBtnLabel) | Out-Null
        $freeStack.Children.Add($btnText) | Out-Null
        $btnInner.Children.Add($freeStack) | Out-Null
    } else {
        $btnInner.Children.Add($btnText) | Out-Null
    }

    # Accent cap on the left edge - 3px wide bar in the game's
    # accent color. Acts as the "action pending" signal in the
    # default Install state. Recolored on state transitions:
    # green when game is installed but not VR-modded, blue when
    # an update is available, hidden in the VR-Ready state.
    $accentCap = New-Object System.Windows.Controls.Border
    $accentCap.Width  = [int](5*$sc)
    $accentCap.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $accentCap.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    $accentCap.Background          = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accentHex)
    # Bleed through the button's inner padding (top/bottom) so the
    # cap touches the button edges without leaving slate gaps.
    $accentCap.Margin = [System.Windows.Thickness]::new(0, [int](-6*$sc), 0, [int](-6*$sc))
    $btnInner.Children.Add($accentCap) | Out-Null

    # Reload pill: small fixed-width strip on the right with a
    # subtle vertical divider on its left edge. Hidden until the
    # card flips to VR Ready (Tag = "vrinstalled"). Mouse clicks
    # on it set e.Handled = true so the card-level click handler
    # (which launches the game) doesn't also fire.
    $reloadPill = New-Object System.Windows.Controls.Border
    $reloadPill.Width = [int](28*$sc)
    $reloadPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $reloadPill.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    $reloadPill.Background     = [System.Windows.Media.Brushes]::Transparent
    $reloadPill.BorderThickness = [System.Windows.Thickness]::new(1, 0, 0, 0)
    $reloadPill.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
    $reloadPill.Cursor         = [System.Windows.Input.Cursors]::Hand
    $reloadPill.Visibility     = [System.Windows.Visibility]::Collapsed
    $reloadPill.Margin         = [System.Windows.Thickness]::new(0, [int](-6*$sc), 0, [int](-6*$sc))
    $reloadGlyph = New-Object System.Windows.Controls.TextBlock
    $reloadGlyph.Text = [char]0x21BB
    $reloadGlyph.FontSize = [int](13*$sc)
    $reloadGlyph.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI Symbol")
    $reloadGlyph.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
    $reloadGlyph.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $reloadGlyph.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $reloadPill.Child = $reloadGlyph
    $btnInner.Children.Add($reloadPill) | Out-Null

    # Hover feedback for the reinstall arrow itself. The pill has no
    # hover of its own otherwise - covers every button type (VR Ready,
    # Update, DualMode) since each card has one pill. To stay clearly
    # visible WITHOUT wiping the vrupdate blue recoloring, we stash the
    # pill's CURRENT background on enter and restore exactly that on
    # leave (never a blind Transparent, which previously erased blue).
    $reloadGlyph.Opacity = 0.75
    $reloadPill.Add_MouseEnter({
        if (-not $this.Resources.Contains("pillHovStash")) {
            $this.Resources.Add("pillHovStash", $this.Background)
        }
        # Lighten the pill: a clear translucent-white overlay on top of
        # whatever colour it has (reads on both transparent and blue),
        # plus a full-opacity glyph.
        $this.Background = New-Object System.Windows.Media.SolidColorBrush(
            [System.Windows.Media.Color]::FromArgb(60, 255, 255, 255))
        $this.Child.Opacity = 1.0
    })
    $reloadPill.Add_MouseLeave({
        # Restore the EXACT background we had before hover (transparent
        # or the vrupdate blue), so we never clobber the recoloring.
        if ($this.Resources.Contains("pillHovStash")) {
            $this.Background = $this.Resources.Item("pillHovStash")
            $this.Resources.Remove("pillHovStash") | Out-Null
        }
        $this.Child.Opacity = 0.75
    })

    # DualMode split overlay - sits on top of $btnText for REPO VR /
    # Content Warning VR style games where both Mode 1 (current) and
    # Mode 2 (depot) are installed in parallel. Two side-by-side
    # buttons: "Current" (left) and "Depot" (right). Collapsed by
    # default; shown on hover only when Filter.ps1 marks the state as
    # DualMode. Reload pill sits to the right of these as usual.
    $dualSplit = New-Object System.Windows.Controls.Grid
    $dualSplit.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $dualSplit.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    $dualSplit.Margin              = [System.Windows.Thickness]::new(
        [int](5*$sc), [int](-6*$sc), [int](28*$sc), [int](-6*$sc)
    )
    $dualSplit.Visibility = [System.Windows.Visibility]::Collapsed
    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $col2 = New-Object System.Windows.Controls.ColumnDefinition
    $col2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $dualSplit.ColumnDefinitions.Add($col1) | Out-Null
    $dualSplit.ColumnDefinitions.Add($col2) | Out-Null

    $dualCurrentBtn = New-Object System.Windows.Controls.Border
    $dualCurrentBtn.Background     = [System.Windows.Media.Brushes]::Transparent
    $dualCurrentBtn.BorderThickness = [System.Windows.Thickness]::new(0, 0, 1, 0)
    $dualCurrentBtn.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
    $dualCurrentBtn.Cursor         = [System.Windows.Input.Cursors]::Hand
    [System.Windows.Controls.Grid]::SetColumn($dualCurrentBtn, 0)
    $dualCurrentTxt = New-Object System.Windows.Controls.TextBlock
    $dualCurrentTxt.Text = ([char]0x25B6) + " " + $(if ($game.TwoMods -and $game.ModAName) { $game.ModAName } else { "Current" })
    $dualCurrentTxt.FontSize = $(if ($game.TwoMods) { 8.5 } else { 11 })*$sc
    $dualCurrentTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $dualCurrentTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
    $dualCurrentTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $dualCurrentTxt.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $dualCurrentBtn.Child = $dualCurrentTxt
    $dualSplit.Children.Add($dualCurrentBtn) | Out-Null

    $dualDepotBtn = New-Object System.Windows.Controls.Border
    $dualDepotBtn.Background     = [System.Windows.Media.Brushes]::Transparent
    $dualDepotBtn.BorderThickness = [System.Windows.Thickness]::new(0)
    $dualDepotBtn.Cursor         = [System.Windows.Input.Cursors]::Hand
    [System.Windows.Controls.Grid]::SetColumn($dualDepotBtn, 1)
    $dualDepotTxt = New-Object System.Windows.Controls.TextBlock
    $dualDepotTxt.Text = ([char]0x25B6) + " " + $(if ($game.TwoMods -and $game.ModBName) { $game.ModBName } else { "Depot" })
    $dualDepotTxt.FontSize = $(if ($game.TwoMods) { 8.5 } else { 11 })*$sc
    $dualDepotTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $dualDepotTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
    $dualDepotTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $dualDepotTxt.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $dualDepotBtn.Child = $dualDepotTxt
    $dualSplit.Children.Add($dualDepotBtn) | Out-Null

    $btnInner.Children.Add($dualSplit) | Out-Null

    $btnBorder.Child = $btnInner
    $grid.Children.Add($btnBorder) | Out-Null
    # Store btnText, reload pill, accent cap on card for later access by Check Installed
    if ($card.Resources.Contains("btnText")) { $card.Resources.Remove("btnText") }
    if ($card.Resources.Contains("btnBorder")) { $card.Resources.Remove("btnBorder") }
    if ($card.Resources.Contains("reloadPill")) { $card.Resources.Remove("reloadPill") }
    if ($card.Resources.Contains("reloadGlyph")) { $card.Resources.Remove("reloadGlyph") }
    if ($card.Resources.Contains("accentCap")) { $card.Resources.Remove("accentCap") }
    if ($card.Resources.Contains("dualSplit")) { $card.Resources.Remove("dualSplit") }
    if ($card.Resources.Contains("dualCurrentBtn")) { $card.Resources.Remove("dualCurrentBtn") }
    if ($card.Resources.Contains("dualDepotBtn")) { $card.Resources.Remove("dualDepotBtn") }
    if ($card.Resources.Contains("gameData")) { $card.Resources.Remove("gameData") }
    $card.Resources.Add("btnText", $btnText)
    $card.Resources.Add("btnBorder", $btnBorder)
    if ($card.Resources.Contains("freeBtnLabel")) { $card.Resources.Remove("freeBtnLabel") }
    $card.Resources.Add("freeBtnLabel", $freeBtnLabel)
    $card.Resources.Add("reloadPill", $reloadPill)
    $card.Resources.Add("reloadGlyph", $reloadGlyph)
    $card.Resources.Add("accentCap", $accentCap)
    $card.Resources.Add("dualSplit", $dualSplit)
    $card.Resources.Add("dualCurrentBtn", $dualCurrentBtn)
    $card.Resources.Add("dualDepotBtn", $dualDepotBtn)
    $card.Resources.Add("gameData", $game)

    # DualMode split click handlers - route to Start-GameInVR with
    # the explicit Mode parameter. We stop event bubbling so the
    # card-level click handler doesn't also fire.
    $dualCurrentBtn.Resources.Add("ownerCard", $card)
    $dualCurrentBtn.Add_MouseLeftButtonDown({
        param($s, $e)
        $owner = $this.Resources.Item("ownerCard")
        $g = $owner.Resources.Item("gameData")
        if ($g) {
            if (Get-Command Start-GameInVR -EA SilentlyContinue) {
                Start-GameInVR -Game $g -Mode $(if ($g.TwoMods) { "ModA" } else { "Current" })
            }
        }
        $e.Handled = $true
    }.GetNewClosure())
    $dualDepotBtn.Resources.Add("ownerCard", $card)
    $dualDepotBtn.Add_MouseLeftButtonDown({
        param($s, $e)
        $owner = $this.Resources.Item("ownerCard")
        $g = $owner.Resources.Item("gameData")
        if ($g) {
            if (Get-Command Start-GameInVR -EA SilentlyContinue) {
                Start-GameInVR -Game $g -Mode $(if ($g.TwoMods) { "ModB" } else { "Depot" })
            }
        }
        $e.Handled = $true
    }.GetNewClosure())
    # Tinted hover background on each split half so the user sees
    # which one they're about to click. Matches the green family.
    $dualCurrentBtn.Add_MouseEnter({
        $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
    }.GetNewClosure())
    $dualCurrentBtn.Add_MouseLeave({
        $this.Background = [System.Windows.Media.Brushes]::Transparent
    }.GetNewClosure())
    $dualDepotBtn.Add_MouseEnter({
        $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
    }.GetNewClosure())
    $dualDepotBtn.Add_MouseLeave({
        $this.Background = [System.Windows.Media.Brushes]::Transparent
    }.GetNewClosure())

    # Inviting hover effect: a soft light-sweep gradient travels
    # diagonally across the button on MouseEnter. Subtle but draws
    # the eye. Only fires when the button is in default state
    # (not "VR Ready" outline style which has its own visual).
    $btnBorder.Resources.Add("accentHex", $accentHex)
    # Store the owning card directly - VisualTreeHelper walks were
    # unreliable (returned null in some render states) which caused
    # the skip-on-vrinstalled check to fail.
    $btnBorder.Resources.Add("ownerCard", $card)
    $btnBorder.Add_MouseEnter({
        $owner = $this.Resources.Item("ownerCard")
        if ($owner -and $owner.Tag -eq "vrinstalled") {
            # DualMode (REPO VR / Content Warning VR with both modes
            # installed): show the Current | Depot split instead of
            # the single "Start in VR" label. Filter.ps1 sets
            # DualMode=$true on gameStateMap when it detects both an
            # in-Steam mod AND a C:\Games\...\ depot install.
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            if ($st -and ($st.DualMode -or $st.TwoMods)) {
                $bt = $owner.Resources.Item("btnText")
                # Hidden (not Collapsed): keep the text's layout slot so
                # the button keeps its normal height; the split overlays.
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Hidden }
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Visible }
                # NOTE: do NOT return - we still want the reload pill
                # to show via the second handler below.
            } else {
                # Swap "VR Ready" -> "Start in VR" on hover. For non-
                # externals an additional handler also reveals the
                # Reinstall pill; we don't touch that here so both run
                # cleanly without conflict.
                $bt = $owner.Resources.Item("btnText")
                if ($bt -and -not $owner.Resources.Contains("readyOrigText")) {
                    $owner.Resources.Add("readyOrigText", $bt.Text)
                    $bt.Text = "Start in VR"
                }
            }
            return
        }
        # vrupdate state: morph the button to green-outline
        # "Start in VR" - matches the VR-Ready button's look so
        # the user has a clear affordance to launch without
        # forcing the update. No shine animation here: the
        # morph itself is the hover signal.
        if ($owner -and $owner.Tag -eq "vrupdate") {
            # Guard against a second pass: the card-level MouseEnter
            # raises this handler so the morph fires on whole-tile
            # hover. Once morphed (flag set on the card), don't run
            # again - re-stashing the morphed state as 'original'
            # would corrupt the MouseLeave restore.
            if ($owner.Resources.Contains("vrupdMorphed")) { return }
            $owner.Resources.Add("vrupdMorphed", $true)
            # DualMode in update state: same 3-way split, but the
            # reload pill on the right keeps its blue "Update Mod"
            # tint (handled by the secondary hover handler below).
            # Update always targets the Current variant - Depot is
            # version-pinned and never updated.
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            if ($st -and $st.DualMode) {
                # Stash + clear the blue background so the split row
                # underneath reads cleanly. Leave + click restore use
                # the same stashed values.
                if ($this.Resources.Contains("preHoverBrush"))   { $this.Resources.Remove("preHoverBrush")   | Out-Null }
                if ($this.Resources.Contains("preHoverBdBrush")) { $this.Resources.Remove("preHoverBdBrush") | Out-Null }
                if ($this.Resources.Contains("preHoverBdThick")) { $this.Resources.Remove("preHoverBdThick") | Out-Null }
                $this.Resources.Add("preHoverBrush",   $this.Background)
                $this.Resources.Add("preHoverBdBrush", $this.BorderBrush)
                $this.Resources.Add("preHoverBdThick", $this.BorderThickness)
                # Match the VR-Ready outline style so the split row
                # has the same visual chrome as the ready-state hover.
                $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
                $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
                $this.BorderThickness = [System.Windows.Thickness]::new(1)
                $bt = $owner.Resources.Item("btnText")
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Hidden }
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Visible }
                # Blue update pill on the right - Update is always
                # for Current. Stash original colours so MouseLeave
                # restores them.
                $rp = $owner.Resources.Item("reloadPill")
                $rg = $owner.Resources.Item("reloadGlyph")
                if ($rp -and $rg) {
                    if (-not $this.Resources.Contains("preHoverPillBg"))     { $this.Resources.Add("preHoverPillBg",     $rp.Background)   }
                    if (-not $this.Resources.Contains("preHoverPillBd"))     { $this.Resources.Add("preHoverPillBd",     $rp.BorderBrush)  }
                    if (-not $this.Resources.Contains("preHoverPillGlyphFg")){ $this.Resources.Add("preHoverPillGlyphFg",$rg.Foreground)  }
                    $rp.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
                    $rp.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
                    $rg.Foreground  = [System.Windows.Media.Brushes]::White
                    $rp.Visibility  = [System.Windows.Visibility]::Visible
                }
                return
            }
            # Stash current bg + text + colors so MouseLeave can
            # restore them precisely.
            if ($this.Resources.Contains("preHoverBrush"))     { $this.Resources.Remove("preHoverBrush")     | Out-Null }
            if ($this.Resources.Contains("preHoverBdBrush"))   { $this.Resources.Remove("preHoverBdBrush")   | Out-Null }
            if ($this.Resources.Contains("preHoverBdThick"))   { $this.Resources.Remove("preHoverBdThick")   | Out-Null }
            if ($this.Resources.Contains("preHoverTxtFg"))     { $this.Resources.Remove("preHoverTxtFg")     | Out-Null }
            if ($this.Resources.Contains("preHoverTxtText"))   { $this.Resources.Remove("preHoverTxtText")   | Out-Null }
            $this.Resources.Add("preHoverBrush",   $this.Background)
            $this.Resources.Add("preHoverBdBrush", $this.BorderBrush)
            $this.Resources.Add("preHoverBdThick", $this.BorderThickness)
            $btnTxt = $owner.Resources.Item("btnText")
            if ($btnTxt) {
                $this.Resources.Add("preHoverTxtFg",   $btnTxt.Foreground)
                $this.Resources.Add("preHoverTxtText", $btnTxt.Text)
            }
            # Apply VR-Ready outline style + Start label.
            $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
            $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
            $this.BorderThickness = [System.Windows.Thickness]::new(1)
            if ($btnTxt) {
                $btnTxt.Text = "Start in VR"
                $btnTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
            }
            # Blue update pill on the right. Same colour as the
            # primary "Update" button it replaces. Stash original
            # colours so MouseLeave can restore the green VR-Ready
            # tint (or transparent default) the pill had before.
            $rp = $owner.Resources.Item("reloadPill")
            $rg = $owner.Resources.Item("reloadGlyph")
            if ($rp -and $rg) {
                if (-not $this.Resources.Contains("preHoverPillBg"))     { $this.Resources.Add("preHoverPillBg",     $rp.Background)   }
                if (-not $this.Resources.Contains("preHoverPillBd"))     { $this.Resources.Add("preHoverPillBd",     $rp.BorderBrush)  }
                if (-not $this.Resources.Contains("preHoverPillGlyphFg")){ $this.Resources.Add("preHoverPillGlyphFg",$rg.Foreground)  }
                $rp.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
                $rp.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
                $rg.Foreground  = [System.Windows.Media.Brushes]::White
                $rp.Visibility  = [System.Windows.Visibility]::Visible
            }
            return
        }
        # Default state hover: a diagonal sweep travels across the
        # slate background. Outer stops stay anchored at the slate
        # color so the button reverts cleanly when the band leaves
        # the [0,1] range; only the inner three stops animate. The
        # peak is the accent color at ~50% mix into the slate -
        # bright enough to read as a sweep without losing the
        # button's calm identity. Cap brighten plays on top.
        if ($this.Resources.Contains("preHoverBrush")) {
            $this.Resources.Remove("preHoverBrush") | Out-Null
        }
        $this.Resources.Add("preHoverBrush", $this.Background)

        $accH = $this.Resources.Item("accentHex")
        if (-not $accH) { return }
        $accCol = ConvertTo-MediaColor $accH

        # Anchor the sweep on the button's *current* fill, not on
        # a recomputed slate. This matters when the card has
        # transitioned to a different state (installed = green
        # outline; future states could be other colors): the sweep
        # should ride over whatever is there, not flash slate
        # underneath. The default Install state still gets the
        # slate look because that's literally what $this.Background
        # is in that case.
        $sweepBase = $null
        if ($this.Background -is [System.Windows.Media.SolidColorBrush]) {
            $sweepBase = $this.Background.Color
        } else {
            # Fallback: recreate slate from accent (only used if a
            # previous hover left a gradient mid-flight, very rare).
            $sweepBase = [System.Windows.Media.Color]::FromRgb(
                [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($accCol.R * 0.18 + 10))))),
                [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($accCol.G * 0.18 + 10))))),
                [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($accCol.B * 0.18 + 10)))))
            )
        }
        # Sweep peak: shift sweepBase 30% toward white. This works
        # for any anchor color - dark slate, green-outline, blue
        # update CTA - and reads as a uniform "shine across the
        # button" instead of a state-specific accent flash.
        $slateBase = $sweepBase
        $sweepPeak = [System.Windows.Media.Color]::FromArgb(
            $sweepBase.A,
            [byte]([Math]::Min(255, [int]([Math]::Round($sweepBase.R + (255 - $sweepBase.R) * 0.30)))),
            [byte]([Math]::Min(255, [int]([Math]::Round($sweepBase.G + (255 - $sweepBase.G) * 0.30)))),
            [byte]([Math]::Min(255, [int]([Math]::Round($sweepBase.B + (255 - $sweepBase.B) * 0.30))))
        )

        $brush = New-Object System.Windows.Media.LinearGradientBrush
        $brush.StartPoint = New-Object System.Windows.Point 0, 0
        $brush.EndPoint   = New-Object System.Windows.Point 1, 1
        $sOutA = New-Object System.Windows.Media.GradientStop $slateBase, 0.0
        $sLead = New-Object System.Windows.Media.GradientStop $slateBase, 0.0
        $sPeak = New-Object System.Windows.Media.GradientStop $sweepPeak, 0.0
        $sTail = New-Object System.Windows.Media.GradientStop $slateBase, 0.0
        $sOutB = New-Object System.Windows.Media.GradientStop $slateBase, 1.0
        $brush.GradientStops.Add($sOutA) | Out-Null
        $brush.GradientStops.Add($sLead) | Out-Null
        $brush.GradientStops.Add($sPeak) | Out-Null
        $brush.GradientStops.Add($sTail) | Out-Null
        $brush.GradientStops.Add($sOutB) | Out-Null
        $this.Background = $brush

        $dur = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(700))
        $aLead = New-Object System.Windows.Media.Animation.DoubleAnimation -0.35, 1.05, $dur
        $aPeak = New-Object System.Windows.Media.Animation.DoubleAnimation -0.20, 1.20, $dur
        $aTail = New-Object System.Windows.Media.Animation.DoubleAnimation -0.05, 1.35, $dur
        $sLead.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aLead)
        $sPeak.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aPeak)
        $sTail.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aTail)

        # Brighten the cap on top of the sweep - both effects
        # together: cap pulses, sweep travels.
        $cap = if ($owner) { $owner.Resources.Item("accentCap") } else { $null }
        if ($cap) {
            if (-not $this.Resources.Contains("preHoverCapBrush")) {
                $this.Resources.Add("preHoverCapBrush", $cap.Background)
            }
            $brightCap = [System.Windows.Media.Color]::FromRgb(
                [byte]([Math]::Min(255, [int]([Math]::Round($accCol.R + (255 - $accCol.R) * 0.30)))),
                [byte]([Math]::Min(255, [int]([Math]::Round($accCol.G + (255 - $accCol.G) * 0.30)))),
                [byte]([Math]::Min(255, [int]([Math]::Round($accCol.B + (255 - $accCol.B) * 0.30))))
            )
            $cap.Background = New-Object System.Windows.Media.SolidColorBrush $brightCap
        }
    })
    $btnBorder.Add_MouseLeave({
        # Return to whatever the button looked like before we hovered -
        # this might be the accent brush, the VR-Ready green, etc.
        # We captured it on MouseEnter so it's always current.
        # Skip entirely on VR-Ready/installed cards: MouseEnter also
        # skipped, so there's no preHoverBrush, and we must NOT
        # reset to accentHex - that would paint the green button
        # with the original (red/orange/yellow) accent color.
        $owner = $this.Resources.Item("ownerCard")
        if ($owner -and $owner.Tag -eq "vrinstalled") {
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            if ($st -and ($st.DualMode -or $st.TwoMods)) {
                # DualMode only: if the cursor is still over the card
                # (moved from button onto the split overlay on top of
                # it), don't tear down - otherwise button-leave/enter
                # oscillate at the boundary and the split flickers. The
                # card-level MouseLeave restores on true tile exit.
                if ($owner.IsMouseOver) { return }
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Collapsed }
                $bt = $owner.Resources.Item("btnText")
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Visible }
            } else {
                # Normal VR Ready: restore "VR Ready" the moment the
                # cursor leaves the button (no IsMouseOver guard - this
                # swap is button-hover only, so it must undo on button
                # leave even while still over the card). Idempotent.
                $bt = $owner.Resources.Item("btnText")
                if ($bt -and $owner.Resources.Contains("readyOrigText")) {
                    $bt.Text = $owner.Resources.Item("readyOrigText")
                    $owner.Resources.Remove("readyOrigText") | Out-Null
                }
            }
            return
        }
        # vrupdate restore: undo the morph to green Start-in-VR.
        # We stashed the original button bg/border/text on hover,
        # so we just put them back. Match against the same Tag so
        # we don't accidentally apply this branch to a card whose
        # state changed mid-hover.
        if ($owner -and $owner.Tag -eq "vrupdate") {
            # If the cursor is still somewhere over the card (just moved
            # off the button onto the card body), keep the morph - the
            # card-level MouseLeave will restore when it truly leaves the
            # tile. Without this, moving button->card body would flicker
            # the button back to "Update" while still hovering the tile.
            if ($owner.IsMouseOver) { return }
            # Actually leaving the tile: clear the morph flag so the
            # next hover re-arms cleanly.
            if ($owner.Resources.Contains("vrupdMorphed")) {
                $owner.Resources.Remove("vrupdMorphed") | Out-Null
            }
            # DualMode: hide split + show btnText again. The bg/border
            # restore below still runs for normal vrupdate path so we
            # branch only on btnText handling.
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            if ($st -and $st.DualMode) {
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Collapsed }
                $bt = $owner.Resources.Item("btnText")
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Visible }
                # Restore bg/border (no btnText text/colour to undo in
                # DualMode - we only toggled visibility on it).
                $preBg  = $this.Resources.Item("preHoverBrush")
                $preBd  = $this.Resources.Item("preHoverBdBrush")
                $preBdT = $this.Resources.Item("preHoverBdThick")
                if ($preBg)  { $this.Background      = $preBg }
                if ($preBd)  { $this.BorderBrush     = $preBd }
                if ($preBdT) { $this.BorderThickness = $preBdT }
                # Restore + hide the blue update pill.
                $rp = $owner.Resources.Item("reloadPill")
                $rg = $owner.Resources.Item("reloadGlyph")
                if ($rp -and $rg) {
                    $prePillBg  = $this.Resources.Item("preHoverPillBg")
                    $prePillBd  = $this.Resources.Item("preHoverPillBd")
                    $prePillGFg = $this.Resources.Item("preHoverPillGlyphFg")
                    if ($prePillBg)  { $rp.Background  = $prePillBg }
                    if ($prePillBd)  { $rp.BorderBrush = $prePillBd }
                    if ($prePillGFg) { $rg.Foreground  = $prePillGFg }
                    if ($this.Resources.Contains("preHoverPillBg"))      { $this.Resources.Remove("preHoverPillBg")      | Out-Null }
                    if ($this.Resources.Contains("preHoverPillBd"))      { $this.Resources.Remove("preHoverPillBd")      | Out-Null }
                    if ($this.Resources.Contains("preHoverPillGlyphFg")) { $this.Resources.Remove("preHoverPillGlyphFg") | Out-Null }
                    $rp.Visibility = [System.Windows.Visibility]::Collapsed
                }
                return
            }
            $preBg     = $this.Resources.Item("preHoverBrush")
            $preBd     = $this.Resources.Item("preHoverBdBrush")
            $preBdT    = $this.Resources.Item("preHoverBdThick")
            $preTxtFg  = $this.Resources.Item("preHoverTxtFg")
            $preTxtTx  = $this.Resources.Item("preHoverTxtText")
            if ($preBg)  { $this.Background      = $preBg }
            if ($preBd)  { $this.BorderBrush     = $preBd }
            if ($preBdT) { $this.BorderThickness = $preBdT }
            $btnTxt = $owner.Resources.Item("btnText")
            if ($btnTxt) {
                if ($preTxtTx) { $btnTxt.Text       = $preTxtTx }
                if ($preTxtFg) { $btnTxt.Foreground = $preTxtFg }
            }
            # Restore + hide the blue update pill that MouseEnter
            # revealed for the non-DualMode vrupdate hover.
            $rp = $owner.Resources.Item("reloadPill")
            $rg = $owner.Resources.Item("reloadGlyph")
            if ($rp -and $rg) {
                $prePillBg  = $this.Resources.Item("preHoverPillBg")
                $prePillBd  = $this.Resources.Item("preHoverPillBd")
                $prePillGFg = $this.Resources.Item("preHoverPillGlyphFg")
                if ($prePillBg)  { $rp.Background  = $prePillBg }
                if ($prePillBd)  { $rp.BorderBrush = $prePillBd }
                if ($prePillGFg) { $rg.Foreground  = $prePillGFg }
                if ($this.Resources.Contains("preHoverPillBg"))      { $this.Resources.Remove("preHoverPillBg")      | Out-Null }
                if ($this.Resources.Contains("preHoverPillBd"))      { $this.Resources.Remove("preHoverPillBd")      | Out-Null }
                if ($this.Resources.Contains("preHoverPillGlyphFg")) { $this.Resources.Remove("preHoverPillGlyphFg") | Out-Null }
                $rp.Visibility = [System.Windows.Visibility]::Collapsed
            }
            return
        }
        $pre = $this.Resources.Item("preHoverBrush")
        if ($pre) {
            $this.Background = $pre
        } else {
            # Fallback if MouseEnter never stashed (e.g. animation was
            # interrupted): rebuild from the accent.
            $accH = $this.Resources.Item("accentHex")
            if ($accH) {
                $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accH)
            }
        }
        # Restore the cap to its pre-hover color
        $cap = if ($owner) { $owner.Resources.Item("accentCap") } else { $null }
        if ($cap) {
            $preCap = $this.Resources.Item("preHoverCapBrush")
            if ($preCap) {
                $cap.Background = $preCap
                $this.Resources.Remove("preHoverCapBrush") | Out-Null
            }
        }
    })
    # Info pill: a small horizontal capsule in the top-right of the
    # card, combining the controls dot (left half) and the "i" info
    # symbol (right half). The full pill is clickable -> opens the
    # InfoUrl - so the click target is large enough for VR pointers.
    # Hovering the dot half shows the controls tooltip.
    $hasInfo = [bool]$game.InfoUrl
    $hasDot  = [bool]$game.Controls

    if ($hasInfo -or $hasDot) {
        $pill = New-Object System.Windows.Controls.Border
        $pill.Height = [int](22*$sc)
        $pill.Background = [System.Windows.Media.Brushes]::Transparent
        $pill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $pill.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
        $pill.Margin = [System.Windows.Thickness]::new(0, [int](8*$sc), [int](8*$sc), 0)
        if ($hasInfo) { $pill.Cursor = [System.Windows.Input.Cursors]::Hand }

        # Two layers so the hover glow never blurs the glyph + "i":
        # the rounded edge + glow live on $pillEdge (no text), the
        # content sits on top as a crisp sibling with no effect.
        $pillGrid = New-Object System.Windows.Controls.Grid
        $pill.Child = $pillGrid

        $pillEdge = New-Object System.Windows.Controls.Border
        $pillEdge.CornerRadius = [System.Windows.CornerRadius]::new([int](11*$sc))
        $pillEdge.Background = [System.Windows.Media.Brushes]::Transparent
        $pillEdge.BorderThickness = [System.Windows.Thickness]::new(1)
        $pillEdge.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#40404e")
        $pillGrid.Children.Add($pillEdge) | Out-Null

        $pillStack = New-Object System.Windows.Controls.StackPanel
        $pillStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $pillStack.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $pillStack.Margin = [System.Windows.Thickness]::new([int](7*$sc), 0, [int](8*$sc), 0)
        $pillGrid.Children.Add($pillStack) | Out-Null

        # Shared brush for the glyph + "i" so a hover can brighten both
        # at once (mutate one Color) - scoped to this pill only.
        $famTxtBrush = New-Object System.Windows.Media.SolidColorBrush $famTxtColor

        if ($hasDot) {
            $ctrlIcon = New-ControlTypeIcon -Controls $game.Controls -Sc $sc -Stroke $famTxtBrush
            $pillStack.Children.Add($ctrlIcon) | Out-Null
        }

        if ($hasInfo -and $hasDot) {
            # Thin separator between dot and "i"
            $sep = New-Object System.Windows.Controls.Border
            $sep.Width = 1
            $sep.Height = [int](11*$sc)
            $sep.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a4a")
            $sep.Margin = [System.Windows.Thickness]::new([int](7*$sc), 0, [int](7*$sc), 0)
            $sep.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $pillStack.Children.Add($sep) | Out-Null
        }

        if ($hasInfo) {
            $infoText = New-Object System.Windows.Controls.TextBlock
            $infoText.Text = "i"
            $infoText.FontSize = [int](12*$sc)
            $infoText.FontStyle = [System.Windows.FontStyles]::Italic
            $infoText.FontWeight = [System.Windows.FontWeights]::Bold
            $infoText.Foreground = $famTxtBrush
            $infoText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $infoText.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
            $infoText.Margin = [System.Windows.Thickness]::new(0, [int](-1*$sc), 0, 0)
            $pillStack.Children.Add($infoText) | Out-Null
            $pill.ToolTip = "Open mod page"

            # Hover: the pill lights up. The glyph + "i" brighten to a more
            # luminous accent (via their shared brush) and the text-free
            # edge layer gains a stronger family-hue glow - symbols stay
            # perfectly crisp while the pill clearly pops.
            $famTxtBright = [System.Windows.Media.Color]::FromRgb(
                [byte]([Math]::Round($famTxtColor.R*0.55 + 255*0.45)),
                [byte]([Math]::Round($famTxtColor.G*0.55 + 255*0.45)),
                [byte]([Math]::Round($famTxtColor.B*0.55 + 255*0.45)))
            $pillGlow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $pillGlow.Color = $famAcc
            $pillGlow.BlurRadius = [int](10*$sc)
            $pillGlow.ShadowDepth = 0
            $pillGlow.Opacity = 0.85
            $pillHoverBorder = New-Object System.Windows.Media.SolidColorBrush $famTxtBright
            $pillRestBorder  = $pillEdge.BorderBrush
            $pill.Add_MouseEnter({
                $famTxtBrush.Color = $famTxtBright
                $pillEdge.BorderBrush = $pillHoverBorder
                $pillEdge.Effect = $pillGlow
            }.GetNewClosure())
            $pill.Add_MouseLeave({
                $famTxtBrush.Color = $famTxtColor
                $pillEdge.BorderBrush = $pillRestBorder
                $pillEdge.Effect = $null
            }.GetNewClosure())

            $infoUrlCapture = $game.InfoUrl
            $pill.Add_PreviewMouseLeftButtonDown({
                param($s,$e)
                $e.Handled = $true
                Start-Process $infoUrlCapture
            }.GetNewClosure())
        }

        $overlay = New-Object System.Windows.Controls.Grid
        $overlay.Children.Add($grid) | Out-Null
        $overlay.Children.Add($pill) | Out-Null
        $card.Child = $overlay
        # Stash info pill so steam-preview can hide it during big image
        $card.Resources.Add("infoPill", $pill)
    } else {
        $overlay = New-Object System.Windows.Controls.Grid
        $overlay.Children.Add($grid) | Out-Null
        $card.Child = $overlay
    }

    # ---- Steam preview overlay (any card with a resolvable image) -----
    # A hidden top strip that the hover manager populates with the
    # Steam header image (or a custom HeaderUrl/PortraitUrl if set).
    $cardHeaderUrl = Get-GameImageUrl -Game $game -Kind "header"
    # Prefer the local disk cache if present (offline-capable).
    if ($game.SteamId -and -not $game.HeaderUrl) {
        $cachedCardHdr = Get-CachedImageUri -SteamId $game.SteamId -Kind "header"
        if ($cachedCardHdr) { $cardHeaderUrl = $cachedCardHdr }
    }
    if ($cardHeaderUrl) {
        $previewHost = New-Object System.Windows.Controls.Grid
        $previewHost.Visibility = [System.Windows.Visibility]::Collapsed
        $previewHost.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
        $previewHost.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $previewHost.Height = [int](80 * $sc)
        $clip = New-Object System.Windows.Media.RectangleGeometry
        $clip.Rect = New-Object System.Windows.Rect 0, 0, ([int](175*$sc)), ([int](80*$sc))
        $clip.RadiusX = [int](7*$sc); $clip.RadiusY = [int](7*$sc)
        $previewHost.Clip = $clip

        $previewImage = New-Object System.Windows.Controls.Image
        $previewImage.Stretch = [System.Windows.Media.Stretch]::UniformToFill
        $previewHost.Children.Add($previewImage) | Out-Null

        $previewMediaHost = New-Object System.Windows.Controls.Grid
        $previewHost.Children.Add($previewMediaHost) | Out-Null

        $fadeBottom = New-Object System.Windows.Shapes.Rectangle
        $fadeBottom.Height = [int](18*$sc)
        $fadeBottom.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
        $fadeGrad = New-Object System.Windows.Media.LinearGradientBrush
        $fadeGrad.StartPoint = New-Object System.Windows.Point 0, 0
        $fadeGrad.EndPoint   = New-Object System.Windows.Point 0, 1
        $fadeGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,0,0,0)), 0.0)) | Out-Null
        $fadeGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(220,22,22,26)), 1.0)) | Out-Null
        $fadeBottom.Fill = $fadeGrad
        $previewHost.Children.Add($fadeBottom) | Out-Null

        $overlay.Children.Insert(1, $previewHost) | Out-Null

        # We store the resolved URL (not the raw SteamId) so the
        # preview manager doesn't need to know about overrides.
        # SteamId is also stored so the preview can fall back to
        # the Fastly CDN if Akamai 404s.
        $card.Resources.Add("previewHeaderUrl", $cardHeaderUrl)
        # Store SteamId only for games that actually use Steam artwork.
        # Cards with a bundled HeaderUrl (e.g. Halo CE, whose SteamId is
        # the unrelated MCC) get $null here so the hover's cache re-resolve
        # and fastly fallback never replace the bundled art with the wrong
        # game's Steam image.
        $card.Resources.Add("previewSteamId",   $(if ($game.HeaderUrl) { "" } else { $game.SteamId }))
        # Portrait fallback URL - mirrors the detail hero's chain so a
        # game whose header.jpg fails on BOTH CDNs still shows something
        # on hover (the detail page already falls back to portrait; the
        # hover banner used to have no portrait step and went blank).
        $card.Resources.Add("previewPortraitUrl", (Get-GameImageUrl -Game $game -Kind "portrait"))
        $card.Resources.Add("hasVideo",         [bool]$game.HasVideo)
        $card.Resources.Add("previewHost",      $previewHost)
        $card.Resources.Add("previewImage",     $previewImage)
        $card.Resources.Add("previewMediaHost", $previewMediaHost)
    }

    # ---- Hot zone: click body -> Discover detail; hover -> preview ---
    # Transparent border covering the central body of the card,
    # excluding the pill area at the top and Install button at the
    # bottom. Click on this zone jumps to the Discover detail view.
    # Hovering arms the Steam-preview timer for SteamId cards.
    # Hot-zone covers the central body of the card. Top is 34px to
    # leave room for the family-pill area; bottom is 32px for the
    # install button. Right edge goes all the way - the small
    # "pill protection" zone below sits above this in the visual
    # tree to prevent the hover-preview from arming when the user
    # is heading toward the info pill.
    $hotZone = New-Object System.Windows.Controls.Border
    $hotZone.Background = [System.Windows.Media.Brushes]::Transparent
    $hotZone.IsHitTestVisible = $true
    $hotZone.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $hotZone.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    # Bottom margin must clear the install button so card-body
    # clicks (-> Description) never steal the button's hit-test,
    # but stay below the description text. 32*$sc was too low
    # (button-top stole by hotZone), 50*$sc was too high
    # (hotZone gave up half the description line). 41*$sc is the
    # midpoint that lands cleanly between the two.
    $hotZone.Margin = [System.Windows.Thickness]::new(0, [int](34*$sc), 0, [int](41*$sc))
    $hotZone.Cursor = [System.Windows.Input.Cursors]::Hand
    $hotZone.Tag = @{ Game = $game; Card = $card }

    # Activate the hover preview only on cards we have an image for.
    # We check the URL stash that was set up earlier in this function.
    if ($card.Resources.Contains("previewHeaderUrl")) {
        $hotZone.Add_MouseEnter({
            $info = $this.Tag
            if (-not $info) { return }
            $global:HoverPendingCard = $info.Card
            if ($global:HoverTimer) { try { $global:HoverTimer.Stop() } catch { } }
            $global:HoverTimer = New-Object System.Windows.Threading.DispatcherTimer
            $global:HoverTimer.Interval = [TimeSpan]::FromMilliseconds($global:HoverDelayMs)
            $global:HoverTimer.Add_Tick({
                $global:HoverTimer.Stop()
                if ($global:HoverPendingCard) {
                    # Don't pop the preview if the cursor has already moved
                    # onto the Install button - popping it would shift the
                    # button down and turn the intended click into a
                    # description click.
                    $bb = $global:HoverPendingCard.Resources.Item("btnBorder")
                    if ($bb -and $bb.IsMouseOver) { $global:HoverPendingCard = $null; return }
                    Start-CardPreview -Card $global:HoverPendingCard
                    $global:HoverPendingCard = $null
                }
            })
            $global:HoverTimer.Start()
        })
    }

    # PreviewMouseLeftButtonDown (tunneling) so we fire BEFORE the
    # card's own MouseLeftButtonDown installer handler. Mark the
    # event handled so the installer never fires for body clicks.
    $hotZone.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        $info = $s.Tag
        if (-not $info -or -not $info.Game) { return }
        $e.Handled = $true
        # Fire the pulsing green border glow as immediate visual
        # confirmation. Show-DiscoverDetail can take a couple of
        # seconds on the first click of a session (Steam library
        # registry walk, header image fetch). Without this, the
        # user sees nothing happen and re-clicks.
        #
        # CRITICAL: Open-DiscoverDetailFromList is a heavy synchronous
        # call that hogs the UI thread for 1-3 seconds. If we call
        # it inline here, the animation is *started* but WPF never
        # gets to render a single frame of it - rendering only
        # resumes once the dispatcher unwinds. The visible result:
        # glow flashes when the detail view closes, sometimes the
        # green border gets stuck.
        # Fix: kick off the glow, then defer the heavy call to the
        # next dispatcher tick at Background priority. This lets
        # the Render pass (priority above Background but below
        # Normal) commit a handful of glow frames before the heavy
        # work begins. The user perceives instant feedback even
        # though the actual navigation happens ~16-32ms later.
        Start-CardClickGlowThenOpen -Card $info.Card -Game $info.Game
    })

    $overlay.Children.Add($hotZone) | Out-Null
    [System.Windows.Controls.Panel]::SetZIndex($hotZone, 5)
    $card.Resources.Add("hotZone", $hotZone)

    # Pill-protection zone: covers only the top-right corner where
    # the info pill sits, so mouse paths heading toward the pill
    # don't arm the hover-preview timer. Limited to roughly the
    # top third of the card height + a 50px wide right strip.
    # ZIndex order is: hotZone(5) < pillGuard(10) < pill(20).
    # That way pill clicks pass through pillGuard, but pillGuard
    # blocks hotZone from arming the hover timer in this corner.
    $pillGuard = New-Object System.Windows.Controls.Border
    $pillGuard.Background = [System.Windows.Media.Brushes]::Transparent
    $pillGuard.IsHitTestVisible = $true
    $pillGuard.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $pillGuard.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
    $pillGuard.Width  = [int](50*$sc)
    $pillGuard.Height = [int](40*$sc)
    $overlay.Children.Add($pillGuard) | Out-Null
    [System.Windows.Controls.Panel]::SetZIndex($pillGuard, 10)
    # If the info pill exists, lift it above the guard so clicks reach it.
    if ($card.Resources.Contains("infoPill")) {
        [System.Windows.Controls.Panel]::SetZIndex($card.Resources.Item("infoPill"), 20)
    }

    # Click shield over the top strip (family badge + info-pill row).
    # The hot zone leaves this strip out, and nothing else handles
    # clicks there, so they used to fall through to the card-level
    # installer (clicking near the family tag started an install).
    # Route those clicks to the detail page instead - only the
    # explicit Install button should install. The info pill (ZIndex
    # 20) stays above this shield so its own click still works, and
    # there is deliberately no MouseEnter here so the hover preview
    # is never armed from this strip.
    $topShield = New-Object System.Windows.Controls.Border
    $topShield.Background = [System.Windows.Media.Brushes]::Transparent
    $topShield.IsHitTestVisible = $true
    $topShield.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $topShield.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
    $topShield.Height = [int](34*$sc)
    $topShield.Cursor = [System.Windows.Input.Cursors]::Hand
    $topShield.Tag = @{ Game = $game; Card = $card }
    $topShield.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        $info = $s.Tag
        if (-not $info -or -not $info.Game) { return }
        $e.Handled = $true
        Start-CardClickGlowThenOpen -Card $info.Card -Game $info.Game
    })
    $overlay.Children.Add($topShield) | Out-Null
    [System.Windows.Controls.Panel]::SetZIndex($topShield, 11)
    # Keep the info pill above the new shield so its own click still fires.
    if ($card.Resources.Contains("infoPill")) {
        [System.Windows.Controls.Panel]::SetZIndex($card.Resources.Item("infoPill"), 20)
    }

    # Hover: rebuild a slightly stronger tint gradient on enter, restore
    # the stored base brush on leave. Tag determines which accent / base
    # combination is currently in play (default / vrinstalled / vrupdate).
    $card.Add_MouseEnter({
        $tag = $this.Tag
        $acc = $this.Resources.Item("baseAccent")
        if (-not $acc) { return }
        if ($tag -eq "vrinstalled") {
            # VR Ready: drop the permanent (frozen) top glow to the flat
            # base, then re-create it as a softly pulsing top-centre blob
            # via -TopGlow, so the original glow stays (a touch darker) and
            # breathes in phase with the left spot instead of the whole
            # lighting switching. MouseLeave restores the full radial glow.
            $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb([byte]12, [byte]12, [byte]16))
            Set-CardHoverSpotlights -Card $this -AccentHex "#46a05a" -TopGlow
            # Only DualMode cards (Current|Depot split) get the morph on
            # whole-tile enter - the split otherwise only shows on direct
            # button hover and flickers at the boundary. Normal VR Ready
            # cards keep their "Start in VR" swap on direct button hover
            # ONLY (raising it tile-wide felt wrong - user feedback).
            $g = $this.Resources.Item("gameData")
            $isDual = $false
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
                if ($st -and ($st.DualMode -or $st.TwoMods)) { $isDual = $true }
            }
            if ($isDual) {
                $bb = $this.Resources.Item("btnBorder")
                if ($bb) {
                    try {
                        $ev = New-Object System.Windows.Input.MouseEventArgs(
                            [System.Windows.Input.Mouse]::PrimaryDevice, 0)
                        $ev.RoutedEvent = [System.Windows.Input.Mouse]::MouseEnterEvent
                        $bb.RaiseEvent($ev)
                    } catch { }
                }
            }
        } elseif ($tag -eq "vrupdate") {
            Set-CardHoverSpotlights -Card $this -AccentHex $acc
            # Fire the button's morph on whole-tile hover so "Update"
            # swaps to "Start in VR" the moment the cursor reaches the
            # tile, not only when it lands on the button (too brief).
            # The button MouseEnter has a morph-flag guard; its
            # MouseLeave has an IsMouseOver guard - so this is safe.
            $bb = $this.Resources.Item("btnBorder")
            if ($bb -and -not $this.Resources.Contains("vrupdMorphed")) {
                try {
                    $ev = New-Object System.Windows.Input.MouseEventArgs(
                        [System.Windows.Input.Mouse]::PrimaryDevice, 0)
                    $ev.RoutedEvent = [System.Windows.Input.Mouse]::MouseEnterEvent
                    $bb.RaiseEvent($ev)
                } catch { }
            }
        } else {
            Set-CardHoverSpotlights -Card $this -AccentHex $acc
        }
    })
    $card.Add_MouseLeave({
        Clear-CardHoverSpotlights -Card $this
        $stored = $this.Resources.Item("baseBgBrush")
        if ($stored) { $this.Background = $stored }
        # Whole-tile leave: restore the morphed update button / DualMode
        # split via the button's own MouseLeave (IsMouseOver is now false
        # so it runs the real restore). Only for the cards that morph
        # from the card level: vrupdate, and DualMode vrinstalled.
        $needLeave = $false
        if ($this.Tag -eq "vrupdate" -and $this.Resources.Contains("vrupdMorphed")) {
            $needLeave = $true
        } elseif ($this.Tag -eq "vrinstalled") {
            $g = $this.Resources.Item("gameData")
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
                if ($st -and ($st.DualMode -or $st.TwoMods)) { $needLeave = $true }
            }
        }
        if ($needLeave) {
            $bb = $this.Resources.Item("btnBorder")
            if ($bb) {
                try {
                    $ev = New-Object System.Windows.Input.MouseEventArgs(
                        [System.Windows.Input.Mouse]::PrimaryDevice, 0)
                    $ev.RoutedEvent = [System.Windows.Input.Mouse]::MouseLeaveEvent
                    $bb.RaiseEvent($ev)
                } catch { }
            }
        }
        # Cancel any pending preview activation, tear down current
        if ($global:HoverTimer) { try { $global:HoverTimer.Stop() } catch { } }
        $global:HoverPendingCard = $null
        if ($global:HoverActiveCard -eq $this) { End-CardPreview }
    })

    # Click
    if ($isExternal) {
        $urlCapture         = $game.Url
        $typeCapture        = $game.Type
        $downloadCapture    = if ($game.DownloadUrl) { $game.DownloadUrl } else { $null }
        $infoUrlExtCapture  = if ($game.InfoUrl) { $game.InfoUrl } else { $null }
        $directDlCapture    = if ($game.DirectDownload) { $game.DirectDownload } else { $null }
        $gameCapture        = $game
        $cardCapture        = $card
        $card.Add_MouseLeftButtonDown({
            # VR Ready state: launch the game via Steam (or LaunchExe
            # if the entry has one). Same behaviour as non-external
            # vrinstalled cards - the card flips into "Start in VR"
            # mode and clicking should play, not reopen the mod page.
            if ($cardCapture.Tag -eq "vrinstalled") {
                Start-GameInVR -Game $gameCapture
                return
            }
            # Wabbajack-based entries: clicking just opens the
            # Wabbajack site. No download is triggered by us and
            # no Downloads folder needs opening - Wabbajack handles
            # everything itself once the user grabs it.
            if ($gameCapture.WabbajackUrl) {
                Start-Process $gameCapture.WabbajackUrl
                return
            }
            if ($directDlCapture) {
                Start-Process $directDlCapture
            } elseif ($typeCapture -ne "steam") {
                # Skip the Downloads-folder pre-open for entries
                # whose Url is just a Discord invite - no download
                # is actually triggered, so the explorer window
                # would just clutter the desktop. Also skip for
                # Vivecraft: vivecraft.org/downloads is several
                # clicks deep (pick a Minecraft version, then
                # Forge/Fabric, then the file) so the user won't
                # see the Downloads folder for a while.
                $isDiscordOnly = $urlCapture -and ($urlCapture -match "discord\.com|discord\.gg")
                $isVivecraft   = ($gameCapture.Title -eq "Vivecraft")
                # steam:// links (e.g. a beta-branch switch via
                # steam://gameproperties/<id>) don't download anything
                # to the Downloads folder - they just open Steam - so
                # opening Explorer would only clutter the desktop.
                $isSteamProtocol = $downloadCapture -and ($downloadCapture -match "^steam://")
                # Only pre-open the Downloads folder when we are actually
                # about to trigger a download (DownloadUrl set). Page-only
                # external entries - those that just open a mod/downloads
                # page in the browser for a manual grab (e.g. X-Wing VR /
                # XWVM) - have no DownloadUrl, so nothing lands in Downloads
                # and the explorer window would only clutter the desktop.
                if ($downloadCapture -and -not $isDiscordOnly -and -not $isVivecraft -and -not $isSteamProtocol) {
                    $downloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
                    try { Start-Process explorer.exe "`"$downloadsPath`"" } catch {}
                    Start-Sleep -Milliseconds 400
                }
                if ($downloadCapture) {
                    $resolvedUrl = $downloadCapture
                    # If it's a GitHub API URL, resolve the actual asset download URL
                    if ($downloadCapture -match "api.github.com") {
                        try {
                            $apiUrl = $downloadCapture
                            $response = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "VRModHub" } -ErrorAction Stop
                            # If response is array (all releases), pick first (newest) with assets
                            if ($response -is [array]) {
                                $release = $response | Where-Object { $_.assets.Count -gt 0 } | Select-Object -First 1
                            } else {
                                $release = $response
                            }
                            $exeAsset = $release.assets | Where-Object { $_.name -match "\.(exe|zip)$" } | Select-Object -First 1
                            if ($exeAsset) { $resolvedUrl = $exeAsset.browser_download_url }
                        } catch {}
                    }
                    Start-Process $resolvedUrl
                }
            }
            # Open the catalog Url too - but for Vivecraft, skip this:
            # DownloadUrl already opened the downloads page above, and
            # opening Url after would push the homepage on top of it,
            # hiding the per-version download list the user actually
            # needs.
            if ($gameCapture.Title -ne "Vivecraft" -and $urlCapture) {
                Start-Process $urlCapture
            }
            # Info page is opened only via the i button, not automatically here
        }.GetNewClosure())
    } elseif ($game.DirectDownload) {
        $dlCapture = $game.DirectDownload
        $card.Add_MouseLeftButtonDown({
            Start-Process $dlCapture
        }.GetNewClosure())
    } else {
        $batPath = Join-Path $scriptDir $game.Bat
        if (Test-Path $batPath) {
            $batCapture    = $batPath
            $titleCapture  = $game.Title
            $folderCapture = if ($game.SteamFolder) { $game.SteamFolder } else { "" }
            $exeCapture    = if ($game.GameExe) { $game.GameExe } else { "" }
            # REFramework family marker is the shared launcher path,
            # NOT the mere presence of GameExe - several non-RE
            # entries (KSP, Another Crab's Treasure) carry a GameExe
            # for shortcut/launch purposes and must route to their
            # own START_INSTALLER.bat instead of REFrameworkVR-core.ps1.
            $isRefCapture  = ($game.Bat -like "REFrameworkVR\*")
            $gameCapture   = $game
            $cardCapture   = $card

            # Direct btnBorder click handler: catches Start-in-VR clicks
            # at the button itself, before they bubble to the card. On
            # Virtual Desktop, the first click after VR-Ready -> Start-
            # in-VR hover-morph could get swallowed because the visual
            # tree re-allocates mid-bubble. Handling at the source with
            # e.Handled = $true sidesteps that race. The card-level
            # handler below still runs for the body / install button.
            $btnBorder.Add_MouseLeftButtonDown({
                param($s, $e)
                if ($cardCapture.Tag -eq "vrinstalled") {
                    $e.Handled = $true
                    Start-GameInVR -Game $gameCapture
                    return
                }
                if ($cardCapture.Tag -eq "vrupdate") {
                    $btnTxtRef = $cardCapture.Resources.Item("btnText")
                    if ($btnTxtRef -and $btnTxtRef.Text -eq "Start in VR") {
                        $e.Handled = $true
                        Start-GameInVR -Game $gameCapture
                    }
                }
            }.GetNewClosure())

            $card.Add_MouseLeftButtonDown({
                # VR Ready state: clicking the card launches the
                # game via Start-GameInVR (uses the recorded
                # install path + LaunchExe + LaunchArgs). Reinstall
                # is handled by the small reload pill on the right
                # of the button (which sets e.Handled = $true to
                # stop this card-level handler from firing).
                if ($cardCapture.Tag -eq "vrinstalled") {
                    Start-GameInVR -Game $gameCapture
                    return
                }
                # vrupdate state: distinguish hover ("Start in VR")
                # from default ("Update"). When the button is
                # currently morphed to green Start-in-VR, clicking
                # launches the game; otherwise the click runs the
                # installer to apply the update. Source of truth
                # is the visible button text, set by the hover
                # handlers a few hundred lines above.
                if ($cardCapture.Tag -eq "vrupdate") {
                    # Hover detection: either btnText was morphed to
                    # "Start in VR" (normal vrupdate), or btnText is
                    # collapsed because the DualMode split is showing.
                    # In either case, clicking the card body (outside
                    # the reload pill, which sets Handled=true) means
                    # the user wants to launch, not update.
                    $btnTxtRef = $cardCapture.Resources.Item("btnText")
                    $isHovering = $false
                    if ($btnTxtRef) {
                        if ($btnTxtRef.Text -eq "Start in VR") { $isHovering = $true }
                        if ($btnTxtRef.Visibility -eq [System.Windows.Visibility]::Hidden) { $isHovering = $true }
                    }
                    if ($isHovering) {
                        # Resolve DualMode preference: if the card is
                        # dual-mode the primary action is "Current".
                        $stForCard = $null
                        if ($global:gameStateMap.ContainsKey($gameCapture.Title)) {
                            $stForCard = $global:gameStateMap[$gameCapture.Title]
                        }
                        if ($stForCard -and $stForCard.DualMode) {
                            Start-GameInVR -Game $gameCapture -Mode "Current"
                        } else {
                            Start-GameInVR -Game $gameCapture
                        }
                        return
                    }
                    # Default click on blue Update button (no hover -
                    # rare but covers click-through edge cases): wipe
                    # the stored version so the next Check Installed
                    # persists the new one after the installer runs.
                    Remove-InstalledVersion -Game $gameCapture
                }
                # Launch the installer and capture the process so
                # we can refresh state when it exits. Same auto-
                # refresh polling pattern used in the detail view's
                # primary button - whichever surface launched the
                # installer wins.
                # Launch through the logging wrapper so the installer's console
                # output is saved to Logs\<Title>-<timestamp>.log. Branch logic
                # (LukeRoss / REFramework / standard) lives in one place now:
                # Start-LoggedInstaller (Helpers.ps1).
                $launchedProc = Start-LoggedInstaller -Game $gameCapture -BatPath $batCapture -RequiresAdmin:([bool]$gameCapture.RequiresAdmin)
                if ($launchedProc) {
                    $global:PendingInstallTitle = $titleCapture
                    try {
                        $timer = New-Object System.Windows.Threading.DispatcherTimer
                        $timer.Interval = [TimeSpan]::FromMilliseconds(750)
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

            # Reload pill click: triggers a reinstall, and marks
            # the event Handled so the card-level click (Start in
            # VR for VR Ready cards) does not also fire.
            $reloadPill.Add_MouseLeftButtonDown({
                param($s, $e)
                $e.Handled = $true
                # vrupdate: clear stored .installed_version so the
                # next Check-Installed scan persists the new version
                # after the installer runs. Matches the card-level
                # click handler's behaviour for the Update path.
                if ($cardCapture.Tag -eq "vrupdate") {
                    try { Remove-InstalledVersion -Game $gameCapture } catch { }
                }
                # Launch + capture the process so we can auto-refresh
                # this card's state when the installer exits (same
                # poll pattern as the card-body click). Without this
                # the card kept showing "Update" after an update.
                $plProc = Start-LoggedInstaller -Game $gameCapture -BatPath $batCapture -RequiresAdmin:([bool]$gameCapture.RequiresAdmin)
                if ($plProc) {
                    $global:PendingInstallTitle = $titleCapture
                    try {
                        $plTimer = New-Object System.Windows.Threading.DispatcherTimer
                        $plTimer.Interval = [TimeSpan]::FromMilliseconds(750)
                        $plTimer.Tag = $plProc
                        $plTimer.Add_Tick({
                            param($ts, $te)
                            $tp = $ts.Tag
                            if (-not $tp -or $tp.HasExited) {
                                try { $ts.Stop() } catch {}
                                try { Invoke-PostInstallRefresh } catch {}
                            }
                        })
                        $plTimer.Start()
                    } catch {}
                }
            }.GetNewClosure())

            # VR Ready hover: swap "VR Ready" -> "Start in VR" while
            # the cursor is over the button. The light-sweep effect
            # is already skipped for vrinstalled cards (see the
            # btnBorder MouseEnter handler above) so there's no
            # animation conflict.
            $btnBorder.Add_MouseEnter({
                $owner = $this.Resources.Item("ownerCard")
                if ($owner -and $owner.Tag -eq "vrinstalled") {
                    $g = $owner.Resources.Item("gameData")
                    $st = $null
                    if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                        $st = $global:gameStateMap[$g.Title]
                    }
                    if ($st -and ($st.DualMode -or $st.TwoMods)) {
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Hidden }
                        $ds = $owner.Resources.Item("dualSplit")
                        if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Visible }
                    } else {
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt -and -not $owner.Resources.Contains("readyOrigText")) {
                            $owner.Resources.Add("readyOrigText", $bt.Text)
                            $bt.Text = "Start in VR"
                        }
                    }
                    $rp = $owner.Resources.Item("reloadPill")
                    if ($rp) { $rp.Visibility = [System.Windows.Visibility]::Visible }
                }
            }.GetNewClosure())
            $btnBorder.Add_MouseLeave({
                $owner = $this.Resources.Item("ownerCard")
                if ($owner -and $owner.Tag -eq "vrinstalled") {
                    $g = $owner.Resources.Item("gameData")
                    $st = $null
                    if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                        $st = $global:gameStateMap[$g.Title]
                    }
                    if ($st -and ($st.DualMode -or $st.TwoMods)) {
                        # DualMode only: keep the split while the cursor
                        # is still over the card (anti-flicker). Card
                        # MouseLeave restores on true tile exit.
                        if ($owner.IsMouseOver) { return }
                        $ds = $owner.Resources.Item("dualSplit")
                        if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Collapsed }
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Visible }
                        $rp = $owner.Resources.Item("reloadPill")
                        if ($rp) { $rp.Visibility = [System.Windows.Visibility]::Collapsed }
                    } else {
                        # Normal VR Ready: restore text on button leave
                        # immediately (button-hover-only swap).
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt -and $owner.Resources.Contains("readyOrigText")) {
                            $bt.Text = $owner.Resources.Item("readyOrigText")
                            $owner.Resources.Remove("readyOrigText") | Out-Null
                        }
                        $rp = $owner.Resources.Item("reloadPill")
                        if ($rp) { $rp.Visibility = [System.Windows.Visibility]::Collapsed }
                    }
                }
            }.GetNewClosure())
        }
    }

    return $card
}

