# -------------------------------------------------------
# Control-type glyph shown in the top-right info pill (replaces the
# old colored MC/GP dot). Stroke-outline Path inside a Viewbox so it
# scales crisply with the S/M/L card scale. Gamepad glyph for gamepad
# titles, motion-controller glyph for motion titles. Tooltip names the
# control scheme on hover.
# -------------------------------------------------------
# A SPLIT BUTTON NEEDS SOMETHING TO SPLIT BETWEEN.
#
# DualMode (REPO VR, Content Warning) always has both halves - the live
# build and the pinned depot build - so it splits unconditionally.
#
# TwoMods is different: it is a set of RIVAL mods, and normally only one of
# them is installed. Splitting the button then offers a choice that does
# not exist and advertises a mod the user did not pick. So the split
# appears only when at least TWO are on disk; with one, the tile keeps its normal
# "Start in VR", and Start-GameInVR with no mode launches whichever one
# is actually there. Even when three or more are installed, the compact tile
# remains two-way; every installed choice stays available on the detail page.
function global:Test-ShowDualSplit {
    param($st)
    if (-not $st) { return $false }
    # An entry can deliberately be BOTH DualMode and TwoMods (Elden Ring:
    # Current/Depot build choice plus Hotbite/ERVR mod choice). Its card is
    # the two-MOD card, so do not let DualMode force two mod buttons while
    # only one mod exists. The per-mod names are present in every scanned
    # TwoMods state and distinguish that shape from ordinary DualMode cards.
    if ($st.ModAName -or $st.ModBName -or $st.ModCName) {
        $presentCount = 0
        foreach ($slot in @('A','B','C','D','E','F','G','H')) {
            if ([bool](Get-AlternativeModValue $st ("Mod${slot}Present"))) { $presentCount++ }
        }
        return ([bool]$st.TwoMods -and $presentCount -ge 2)
    }
    if ($st.RouteSplit -or $st.DualMode) { return $true }
    return ([bool]$st.TwoMods -and [bool]$st.ModAPresent -and [bool]$st.ModBPresent)
}

# Pick the two actually installed Current/confirmed/legacy routes for the
# compact tile. The order is intentional: Current, last-confirmed depot,
# original legacy depot. If all three exist the first two stay on the tile
# and Legacy remains available on the detail page.
function global:Get-DualModeTilePair {
    param($Game, $State)
    if (-not $Game -or -not $State) { return @() }
    $definitions = @(
        [pscustomobject]@{ Mode='Current'; Present=[bool]$State.CurrentPresent; ButtonLabel=$(if ($Game.CurrentButtonLabel) { [string]$Game.CurrentButtonLabel } else { 'Current' }) }
        [pscustomobject]@{ Mode='Depot'; Present=[bool]$State.DepotPresent; ButtonLabel=$(if ($Game.DepotButtonLabel) { [string]$Game.DepotButtonLabel } else { 'Depot' }) }
        [pscustomobject]@{ Mode='LegacyDepot'; Present=[bool]$State.LegacyPresent; ButtonLabel=$(if ($Game.LegacyDepotButtonLabel) { ([string]$Game.LegacyDepotButtonLabel -replace '^(?i)Start\s+','') } else { 'Legacy' }) }
    )
    return @($definitions | Where-Object Present | Select-Object -First 2)
}

# One source of truth for update-button ownership on game tiles.  This is
# intentionally based on the split that is actually visible, not merely on a
# catalog entry being capable of hosting several mods.
function global:Get-CardUpdateActionLayout {
    param($State)
    $splitVisible = [bool](Test-ShowDualSplit $State)
    return [pscustomobject]@{
        SplitVisible = $splitVisible
        MainAction   = $(if ($splitVisible) { 'PlaySplit' } else { 'Update' })
        PillAction   = $(if ($splitVisible) { 'Update' } else { 'Play' })
    }
}

function global:Update-AlternativeModSplit {
    param($Card)
    if (-not $Card) { return }
    $game = $Card.Resources.Item('gameData')
    if (-not $game -or (-not $game.TwoMods -and -not $game.DualMode)) { return }
    $state = $null
    try { $state = $global:gameStateMap[$game.Title] } catch {}
    $pair = if ($game.TwoMods) {
        @(Get-AlternativeModTilePair -Game $game -State $state)
    } else {
        @(Get-DualModeTilePair -Game $game -State $state)
    }
    if ($pair.Count -lt 2) { return }
    $left = $Card.Resources.Item('dualCurrentBtn')
    $right = $Card.Resources.Item('dualDepotBtn')
    foreach ($item in @(@{ Button=$left; Definition=$pair[0] }, @{ Button=$right; Definition=$pair[1] })) {
        $button = $item.Button; $definition = $item.Definition
        if (-not $button -or -not $definition) { continue }
        if ($button.Resources.Contains('launchMode')) { $button.Resources.Remove('launchMode') | Out-Null }
        $button.Resources.Add('launchMode', [string]$definition.Mode)
        if ($button.Child -is [System.Windows.Controls.TextBlock]) {
            $label = [string]$definition.ButtonLabel
            $cardScale = 1.0
            try { if ($Card.Resources.Contains('cardScale')) { $cardScale = [double]$Card.Resources.Item('cardScale') } } catch {}
            $button.Child.Text = ([char]0x25B6) + ' ' + $label
            $button.Child.FontSize = $(if ($label.Length -gt 8) { 7.8 } else { 8.5 }) * $cardScale
        }
    }
}

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

    # VRGP: VR controllers mapped as a gamepad - motion glyph "=" gamepad
    # glyph. Says "these VR controllers behave as a standard gamepad", the
    # honest label for ports with no true 6DoF/roomscale (New Star GP, the
    # RaYRoD N64 ports, many Astienth mods).
    if ($Controls -eq "VRGP") {
        $row = New-Object System.Windows.Controls.StackPanel
        $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $row.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $row.ToolTip = "VR controllers mapped as Gamepad"
        $mc = & $makeGlyph "motion"  $Sc $strokeBrush
        $eq = New-Object System.Windows.Controls.TextBlock
        $eq.Text = "="
        $eq.Foreground = $strokeBrush
        $eq.FontSize = [double](13 * $Sc)
        $eq.FontWeight = [System.Windows.FontWeights]::Bold
        $eq.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $eq.Margin = [System.Windows.Thickness]::new([int](3*$Sc), 0, [int](3*$Sc), 0)
        $gp = & $makeGlyph "gamepad" $Sc $strokeBrush
        $row.Children.Add($mc) | Out-Null
        $row.Children.Add($eq) | Out-Null
        $row.Children.Add($gp) | Out-Null
        return $row
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
# $global:FREE_GAME_TITLES is NOT defined here any more: it is
# DERIVED in Catalog.ps1 (which loads first) from each entry's
# "free" tag - one edit there drives pill, filter and search.
# -------------------------------------------------------

# -------------------------------------------------------
# Work-in-progress games. Tiles for these get a small red "WIP"
# pill beside the title (and beside FREE when both facts apply),
# while the description page gets a matching red "WIP" pill at
# the top. For mods that run but are still rough / early.
# Match is by exact Title.
# $global: so DetailView.ps1 reads the same single source of truth.
$global:WIP_GAME_TITLES = @(
    "Sons of the Forest",
    "theHunter: Call of the Wild VR",
    "Legend of Zelda: Twilight Princess",
    "Arma 3 VR",
    "C&C Generals: Zero Hour",
    "Borderlands GOTY Enhanced",
    "Elden Ring VR",
    "Ghost Recon Wildlands VR",
    "Stardew Valley VR",
    "GTA IV VR",
    "My Friendly Neighborhood VR",
    "Muck VR",
    "Shenmue I & II",
    "Red Faction VR",
    "Silent Hill 3 VR",
    "Singularity VR",
    "Max Payne 2 VR",
    "The Witness",
    "SnowRunner VR",
    "EARTH DEFENSE FORCE 6 VR",
    "Titanfall 2 VR",
    "Tribes 2 VR",
    "GoldenEye 007 VR",
    "Deus Ex: Human Revolution - DC",
    "PowerWash Simulator 2 VR",
    "Mirror's Edge VR",
    "Kingdom Come: Deliverance VR",
    "Oblivion (2006)",
    "Thief (2014) VR"
)

# A Gem marks the primary VR mod as one of the Hub's most complete and
# polished experiences. It is intentionally a catalog fact instead of a
# presentation-only tag: cards, search and the primary-mod detail row all read
# the same value. Optional add-ons are not implied by the primary Gem flag.
function global:New-GemMarker {
    param(
        [double]$Scale = 1.0,
        [switch]$Detail,
        [switch]$Preview
    )

    # A small faceted jewel reads as an actual diamond at every scale; the
    # former solid rhombus looked like an ordinary bullet or decoration.
    $marker = New-Object System.Windows.Controls.Grid
    $size = if ($Detail) { 14.0 } elseif ($Preview) { [Math]::Max(10.0, [Math]::Round(12.0 * $Scale)) } else { [Math]::Max(11.0, [Math]::Round(14.0 * $Scale)) }
    $marker.Width = $size
    $marker.Height = $size
    $view = New-Object System.Windows.Controls.Viewbox
    $gemCanvas = New-Object System.Windows.Controls.Grid
    $gemCanvas.Width = 20
    $gemCanvas.Height = 20
    $outline = New-Object System.Windows.Shapes.Path
    $outline.Data = [System.Windows.Media.Geometry]::Parse('M 2,7 L 6,2 L 14,2 L 18,7 L 10,18 Z')
    $outline.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#18394c')
    $outline.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#71d7ff')
    $outline.StrokeThickness = 1.5
    $outline.StrokeLineJoin = [System.Windows.Media.PenLineJoin]::Round
    $facets = New-Object System.Windows.Shapes.Path
    $facets.Data = [System.Windows.Media.Geometry]::Parse('M 2,7 L 18,7 M 6,2 L 10,7 L 14,2 M 2,7 L 10,18 L 18,7 M 10,7 L 10,18')
    $facets.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#b9edff')
    $facets.StrokeThickness = 1.0
    $facets.StrokeLineJoin = [System.Windows.Media.PenLineJoin]::Round
    $facets.Opacity = 0.9
    $gemCanvas.Children.Add($outline) | Out-Null
    $gemCanvas.Children.Add($facets) | Out-Null
    $view.Child = $gemCanvas
    $marker.Children.Add($view) | Out-Null
    $marker.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $marker.Margin = if ($Detail) {
        [System.Windows.Thickness]::new(6, 1, 0, 0)
    } elseif ($Preview) {
        [System.Windows.Thickness]::new([int](5 * $Scale), 0, 0, 0)
    } else {
        [System.Windows.Thickness]::new([int](5 * $Scale), 0, 0, [int](8 * $Scale))
    }
    $marker.ToolTip = if ($Preview) { "Polished Gem" } else { "Gem - polished, native-feeling VR" }
    if ($Preview) {
        $marker.Opacity = 0.72
        $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
        $glow.Color = [System.Windows.Media.Color]::FromRgb(113, 215, 255)
        $glow.BlurRadius = 5
        $glow.ShadowDepth = 0
        $glow.Opacity = 0.35
        $marker.Effect = $glow
    }
    [System.Windows.Automation.AutomationProperties]::SetName($marker, "Gem: highly complete and polished VR mod")
    return $marker
}

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
    # The button is static between state/hover changes. Cache the small neon
    # surface so list scrolling moves a bitmap instead of re-running the
    # shadow shader for every visible card on every frame.
    $Button.CacheMode = New-Object System.Windows.Media.BitmapCache
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
            if ($BtnTxt) {
                $BtnTxt.Inlines.Clear()
                $arrBase = $BtnTxt.FontSize; if ([double]::IsNaN($arrBase)) { $arrBase = 12.0 }
                # Cap the line box to the normal text height so the larger
                # arrow glyph does NOT grow the button; the bold arrow just
                # reads bigger within the same-height line.
                $BtnTxt.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
                $BtnTxt.LineHeight = $arrBase * 1.33
                $arrRun = New-Object System.Windows.Documents.Run ([string][char]0x2193)
                $arrRun.FontSize   = $arrBase * 1.3
                $arrRun.FontWeight = [System.Windows.FontWeights]::Bold
                [void]$BtnTxt.Inlines.Add($arrRun)
                [void]$BtnTxt.Inlines.Add((New-Object System.Windows.Documents.Run ([string]" Update")))
            }
            Set-NeonButtonState -Button $BtnBrd -Text $BtnTxt -ColorHex $UPDATE_BLUE -Filled
            # Resting Update text stays clearly readable but remains visually
            # distinct from the pure-white real mouse-over state.
            if ($BtnTxt) {
                $BtnTxt.Foreground = $conv.ConvertFromString("#b9ccf4")
            }
            if ($BtnBrd) {
                # Semi-transparent blue fill so the card's ember/frost FX show
                # through the Update button - a bit more opaque than VR Ready
                # (alpha 40 vs 20). Hover keeps this (it never repaints the
                # background), and MouseLeave restores it, so both states stay
                # see-through. Only the Update button - never the Play pill.
                $uGrad = New-Object System.Windows.Media.LinearGradientBrush
                $uGrad.StartPoint = New-Object System.Windows.Point 0, 0
                $uGrad.EndPoint   = New-Object System.Windows.Point 0, 1
                $uGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(40, 40, 92, 205), 0.0))) | Out-Null
                $uGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(40, 22, 54, 128), 1.0))) | Out-Null
                $uGrad.Freeze()
                $BtnBrd.Background = $uGrad
            }
            if ($Card -and $BtnTxt) {
                if ($Card.Resources.Contains("updLabelRest")) { $Card.Resources.Remove("updLabelRest") | Out-Null }
                $Card.Resources.Add("updLabelRest", $BtnTxt.Foreground)
            }
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
