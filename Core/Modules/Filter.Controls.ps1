$filterAll       = $window.FindName("FilterAll")
$filterMC        = $window.FindName("FilterMC")
$filterGP        = $window.FindName("FilterGP")
$filterAllRing   = $window.FindName("FilterAllRing")
$filterMCRing    = $window.FindName("FilterMCRing")
$filterGPRing    = $window.FindName("FilterGPRing")
$filterAllGlowRing = $window.FindName("FilterAllGlowRing")
$filterMCGlowRing  = $window.FindName("FilterMCGlowRing")
$filterGPGlowRing  = $window.FindName("FilterGPGlowRing")
$filterInstalled = $window.FindName("FilterInstalled")
$filterVRReady   = $window.FindName("FilterVRReady")
$filterUpdate    = $window.FindName("FilterUpdate")
$filterUpdBadge  = $window.FindName("FilterUpdateBadge")
$filterUpdCount  = $window.FindName("FilterUpdateCount")
$installedFilterGroup = $window.FindName("InstalledFilterGroup")

# Soft hover on filter pills. The pills' active state already
# paints the accent border (see Set-FilterStyle / Set-InstallFilterMode)
# so we deliberately do NOT use Add-GlowHover here - that would
# paint the same accent border on hover, making "hovered inactive"
# indistinguishable from "active". Add-SoftHover instead just
# bumps the background up a notch + brightens the text one step;
# enough hover feedback to feel reactive, but visually distinct
# from the active state.
Add-SoftHover -Border $filterAll
Add-SoftHover -Border $filterMC
Add-SoftHover -Border $filterGP
Add-SoftHover -Border $filterInstalled
Add-SoftHover -Border $filterVRReady
Add-SoftHover -Border $filterUpdate

$activeFilter      = "ALL"
# Install-state filter is a tri-state, mutually exclusive with itself:
#   "off"       - no install filter (show everything)
#   "installed" - base game detected on this PC (state installed/ready/update)
#   "ready"     - VR mod installed and ready (state ready/update)
# The "Installed" pill toggles off<->installed, the "VR Ready" pill
# toggles off<->ready; turning one on turns the other off.
$script:installFilterMode = "off"

# Color tokens for the glass filter bar.
# Active = border highlight in the filter's own accent + white text.
# That style is identical to what Add-GlowHover paints on mouseover
# of an inactive pill - we co-opt it because the bordered look is
# the most visually distinctive without changing background fills.
# Inactive  = near-transparent white tint (the glass base).
# Hover (inactive) = slightly brighter glass tint, NO accent border.
#   Without this carve-out, hovering an inactive pill would paint
#   the same accent border as the active state and the user
#   couldn't tell which one is selected.
# Hover (active) = stays active-bordered; nothing extra to do.
$script:glassInactiveBg     = "#09ffffff"   #  ~3% white tint  (base)
$script:glassInactiveBd     = "#0fffffff"   #  subtle grey resting (unified inactive border)
$script:glassActiveBd       = "#ffeeb0"     # neutral accent for the All pill
$script:glassActiveBdMC     = "#ffeeb0"     # MC dot color
$script:glassActiveBdGP     = "#ffeeb0"     # GP dot color
$script:glassActiveBdInst   = "#ffeeb0"     # Installed dot color
$script:glassActiveBdReady  = "#34d399"     # VR Ready dot color (matches tile badge)
$script:glassInactiveBdAll   = "#0fffffff"   # subtle grey resting (unified)
$script:glassInactiveBdMC    = "#0fffffff"
$script:glassInactiveBdGP    = "#0fffffff"
$script:glassInactiveBdInst  = "#0fffffff"  # subtle grey resting (unified)
$script:glassInactiveBdReady = "#0fffffff"  # subtle grey resting (unified)
$script:glassBgAllOff="#000000"; $script:glassBgAllOn="#000000"
$script:glassBgMCOff="#000000"; $script:glassBgMCOn="#000000"
$script:glassBgGPOff="#000000"; $script:glassBgGPOn="#000000"
$script:glassBgInstOff="#000000"; $script:glassBgInstOn="#000000"
$script:glassBgReadyOff="#000000"; $script:glassBgReadyOn="#1634d399"
$script:glassFgInactive     = "#c7c7d0"
$script:glassFgActive       = "White"

function global:New-ChipGlow { param($hex = "#f0d860")
    $e = New-Object System.Windows.Media.Effects.DropShadowEffect
    $e.Color = [System.Windows.Media.ColorConverter]::ConvertFromString($hex)
    $e.BlurRadius = 13; $e.ShadowDepth = 0; $e.Opacity = 1.0
    return $e
}

# The three type pills render their selection edge in a dedicated top
# layer. Their faint outer ring is another real Border behind the opaque
# button, never a bitmap Effect on the button itself - a DropShadowEffect
# is cast by the pill's SILHOUETTE, so an opaque black pill threw a dark
# halo that showed up wherever it fell across its neighbour.
#
# GlowHex lets the two SOURCES of a lit pill look different:
#   the user picked it in the header  -> the amber selection glow
#   the Hub marked it on a game page  -> a cooler blue, so nobody reads
#                                        it as their own filter choice
function global:Sync-TypeFilterRing {
    param($Button, $Ring, $GlowRing, [bool]$GlowOn, [string]$GlowHex = "#80ffeeb0")
    if ($Button -and $Ring) { $Ring.BorderBrush = $Button.BorderBrush }
    if ($GlowRing) {
        if ($GlowOn) {
            try { $GlowRing.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($GlowHex) } catch {}
        }
        $GlowRing.Visibility = if ($GlowOn) {
            [System.Windows.Visibility]::Visible
        } else {
            [System.Windows.Visibility]::Collapsed
        }
    }
}

function global:Set-FilterStyle {
    param($active)
    $script:activeFilter = $active

    # When the Motion filter is active, the Gamepad section shows ONLY the
    # VRGP titles (VR controllers mapped as a standard gamepad), because those
    # are the gamepad entries that also match a motion search. Relabel the
    # section header so they read as their own category beneath the true
    # motion-control titles: "VR controllers mapped as Gamepad". For ALL/GP it
    # goes back to the normal "Gamepad controls".
    try {
        $win = if ($global:window) { $global:window } else { $window }
        $hgpKind = $win.FindName("HeaderGPKind")
        if ($hgpKind) {
            if ($active -eq "MC") {
                $hgpKind.Text = "VR controllers mapped as Gamepad"
                if (Get-Command Set-TitleGradient -ErrorAction SilentlyContinue) { Set-TitleGradient $hgpKind }
                $hgpSub2 = $win.FindName("HeaderGPSub")
                if ($hgpSub2 -and $null -ne $global:HubVRGPCount) { $hgpSub2.Text = "$($global:HubVRGPCount) mods" }
            } else {
                $hgpKind.Text = "Gamepad controls"
                try { $hgpKind.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") } catch {}
                $hgpSub2 = $win.FindName("HeaderGPSub")
                if ($hgpSub2 -and $null -ne $global:HubGPCount) { $hgpSub2.Text = "$($global:HubGPCount) mods" }
            }
        }
        $vis = if ($active -eq "MC") { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
        $mIco = $win.FindName("HeaderGPMotionIcon"); if ($mIco) { $mIco.Visibility = $vis }
        $eqTx = $win.FindName("HeaderGPEq");        if ($eqTx) { $eqTx.Visibility = $vis }
        # Gamepad glyph left margin: 11 normally (spacing from the title), but
        # 0 in MC mode where the visible "=" already provides the gap - else it
        # sits 3-4 chars too far right after the "=".
        $gpIco = $win.FindName("HeaderGPGamepadIcon")
        if ($gpIco) { $gpIco.Margin = if ($active -eq "MC") { [System.Windows.Thickness]::new(0,0,7,0) } else { [System.Windows.Thickness]::new(11,0,7,0) } }
    } catch {}
    $whiteBrush = [System.Windows.Media.Brushes]::White
    $inactiveFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassFgInactive)

    # Drop any Add-SoftHover stash on the four pills BEFORE we paint.
    # Without this, the sequence "hover inactive pill -> click it ->
    # leave" restores the pre-click grey foreground from shFg, and the
    # now-active pill stays grey. Same cleanup pattern Set-ScaleActive
    # uses for the S/M/L buttons.
    foreach ($pill in @($filterAll, $filterMC, $filterGP)) {
        if ($pill.Resources.Contains("shBg")) { $pill.Resources.Remove("shBg") | Out-Null }
        $tb = if ($pill -eq $filterAll) { $pill.Child } else { $pill.Child.Children[1] }
        if ($tb -and $tb.Resources.Contains("shFg")) { $tb.Resources.Remove("shFg") | Out-Null }
    }

    # All pill - background NEVER changes (always the glass base),
    # the active state is signaled by an accent border + white text.
    # Active foreground uses the Brushes::White literal (same as
    # FilterInstalled + the Set-ScaleActive S/M/L buttons). Going
    # through BrushConverter.ConvertFromString("White") produces a
    # foreground that visibly reads slightly off-white on the dark
    # glass background - it's the same RGB value (255/255/255) but
    # the brush instance doesn't end up looking identical in WPF.
    # The Brushes::White singleton is the working reference.
    $filterAll.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString($(if ($active -eq "ALL") { $script:glassBgAllOn } else { $script:glassBgAllOff }))
    $filterAll.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($(if ($active -eq "ALL") { $script:glassActiveBd } else { $script:glassInactiveBdAll }))
    ($filterAll.Child).Foreground = $(if ($active -eq "ALL") { $whiteBrush } else { $inactiveFg })
    # MC pill
    $filterMC.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString($(if ($active -eq "MC") { $script:glassBgMCOn } else { $script:glassBgMCOff }))
    $filterMC.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($(if ($active -eq "MC") { $script:glassActiveBdMC } else { $script:glassInactiveBdMC }))
    ($filterMC.Child.Children[1]).Foreground = $(if ($active -eq "MC") { $whiteBrush } else { $inactiveFg })
    # GP pill
    $filterGP.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString($(if ($active -eq "GP") { $script:glassBgGPOn } else { $script:glassBgGPOff }))
    $filterGP.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($(if ($active -eq "GP") { $script:glassActiveBdGP } else { $script:glassInactiveBdGP }))
    ($filterGP.Child.Children[1]).Foreground = $(if ($active -eq "GP") { $whiteBrush } else { $inactiveFg })
    # USER'S OWN CHOICE: amber glow, the look the header has always had.
    Sync-TypeFilterRing $filterAll $filterAllRing $filterAllGlowRing ($active -eq "ALL")
    Sync-TypeFilterRing $filterMC  $filterMCRing  $filterMCGlowRing  ($active -eq "MC")
    Sync-TypeFilterRing $filterGP  $filterGPRing  $filterGPGlowRing  ($active -eq "GP")
    # Never put an Effect back on the opaque button layer. Selection glow
    # and the topmost crisp outline are handled by the sibling rings above.
    $filterAll.Effect = $null
    $filterMC.Effect  = $null
    $filterGP.Effect  = $null
}

# Detail-page ONLY: visually MARK which attributes the shown game has
# (Motion Controls / Gamepad, Installed / VR Ready) so they read at a
# glance, since the filter pills have no filtering purpose while a single
# game's page is open. This is purely cosmetic - it does NOT change
# $script:activeFilter or $script:installFilterMode, so the list/Explore
# filter selection is completely untouched. Hide-DiscoverDetail calls
# Restore-FilterPills to repaint the real filter state on the way back.
function global:Set-DetailFilterMarks {
    param($Game)
    if (-not $Game) { return }
    $whiteBr = [System.Windows.Media.Brushes]::White
    $inactBd = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassInactiveBd)
    $inactFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassFgInactive)
    $glassBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassInactiveBg)

    # Drop any Add-SoftHover stash so a later MouseLeave can't restore a
    # stale pre-hover look (same cleanup Set-FilterStyle does).
    foreach ($pill in @($filterAll, $filterMC, $filterGP, $filterInstalled, $filterVRReady, $filterUpdate)) {
        if (-not $pill) { continue }
        if ($pill.Resources.Contains("shBg")) { $pill.Resources.Remove("shBg") | Out-Null }
        $tb = if ($pill -eq $filterAll) { $pill.Child } elseif ($pill -eq $filterInstalled -or $pill -eq $filterVRReady -or $pill -eq $filterUpdate) { $pill.Child.Children[0] } else { $pill.Child.Children[1] }
        if ($tb -and $tb.Resources.Contains("shFg")) { $tb.Resources.Remove("shFg") | Out-Null }
        $pill.Background = [System.Windows.Media.Brushes]::Black
        # Detail-page marking is border + text only - drop any leftover
        # filter glow (e.g. the previously active "All" pill in the list)
        # so a detail page never shows a faint lingering Leuchtrahmen.
        $pill.Effect = $null
    }

    $ctrl  = "$($Game.Controls)"
    $hasMC = ($ctrl -eq "MC" -or $ctrl -eq "BOTH")
    $hasGP = ($ctrl -eq "GP" -or $ctrl -eq "BOTH" -or $ctrl -eq "VRGP")
    $st = $null
    if ($global:gameStateMap) { $st = $global:gameStateMap[$Game.Title] }
    $isReady     = $st -and ($st.Tag -in @("vrinstalled", "vrupdate"))
    $installedOnly = $st -and ($st.Tag -eq "installed")
    # An available update is its own fact about THIS game, so the Update
    # pill is marked here too - same as Needs Mod and VR Ready.
    $isUpdateLit = $st -and ($st.Tag -eq "vrupdate")
    # Needs Mod lights ONLY when the base game is present but the mod is
    # NOT installed yet. A VR Ready title already has the mod, so it marks
    # VR Ready only (not Needs Mod). Both pills stay open via DetailBothPills.
    $installedLit = $installedOnly
    # Tell Sync-InstallPills to keep both pills open (no hover collapse)
    # while a VR Ready title's detail page is shown.
    $global:DetailBothPills = [bool]$isReady

    # All pill is not an attribute -> always dimmed on a detail page.
    # !!! THIS IS THE HUB TALKING, NOT THE USER (2026-08-20).
    # On a game page these pills stop being a filter and become a label:
    # they say which category THIS game falls into. If that looked exactly
    # like a header selection it would read as "my filter changed by
    # itself" - so the two must not share one look.
    # THE HEADER uses the ring layers (no Effect, no shadow artefact).
    # THE HUB'S OWN MARK uses the SOFT GLOW FRAME the Hub has always had
    # for this - a DropShadowEffect on the pill. Different mechanism,
    # visibly different edge, and no ring is shown alongside it.
    if ($filterAll) {
        $filterAll.BorderBrush = $inactBd
        ($filterAll.Child).Foreground = $inactFg
        Sync-TypeFilterRing $filterAll $filterAllRing $filterAllGlowRing $false
        $filterAll.Effect = $null
    }
    if ($filterMC) {
        $filterMC.BorderBrush = if ($hasMC) { [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassActiveBdMC) } else { $inactBd }
        ($filterMC.Child.Children[1]).Foreground = if ($hasMC) { $whiteBr } else { $inactFg }
        Sync-TypeFilterRing $filterMC $filterMCRing $filterMCGlowRing $false
        $filterMC.Effect = $(if ($hasMC) { New-ChipGlow $script:glassActiveBdMC } else { $null })
    }
    if ($filterGP) {
        $filterGP.BorderBrush = if ($hasGP) { [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassActiveBdGP) } else { $inactBd }
        ($filterGP.Child.Children[1]).Foreground = if ($hasGP) { $whiteBr } else { $inactFg }
        Sync-TypeFilterRing $filterGP $filterGPRing $filterGPGlowRing $false
        $filterGP.Effect = $(if ($hasGP) { New-ChipGlow $script:glassActiveBdGP } else { $null })
    }
    if ($filterInstalled) {
        # Always visible. Lit only for "Needs Mod" (base present, no mod);
        # a VR Ready title does NOT light this pill.
        $filterInstalled.Visibility = [System.Windows.Visibility]::Visible
        $filterInstalled.BorderBrush = if ($installedLit) { [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassActiveBdInst) } else { $inactBd }
        ($filterInstalled.Child.Children[0]).Foreground = if ($installedLit) { $whiteBr } else { $inactFg }
        # Set BY THE HUB, so it wears the soft glow frame - see the note above.
        $filterInstalled.Effect = $(if ($installedLit) { New-ChipGlow $script:glassActiveBdInst } else { $null })
    }
    # VR Ready: ALWAYS visible (no hover-reveal). Marked when the game is
    # VR Ready, otherwise shown unselected - so the pill is always present
    # and clickable and the cluster never shifts under the cursor.
    if ($filterVRReady) {
        $filterVRReady.Visibility = [System.Windows.Visibility]::Visible
        if ($isReady) {
            $filterVRReady.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassActiveBdReady)
            ($filterVRReady.Child.Children[0]).Foreground = $whiteBr
            $filterVRReady.Effect = New-ChipGlow $script:glassActiveBdReady
        } else {
            $filterVRReady.BorderBrush = $inactBd
            ($filterVRReady.Child.Children[0]).Foreground = $inactFg
            $filterVRReady.Effect = $null
        }
    }
    # Update: only shown at all when this game HAS one, and then lit the
    # same way. Its blue is the colour the header uses for Update too.
    if ($filterUpdate) {
        if ($isUpdateLit) {
            $filterUpdate.Visibility = [System.Windows.Visibility]::Visible
            $filterUpdate.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#60a5fa")
            ($filterUpdate.Child.Children[0]).Foreground = $whiteBr
            $filterUpdate.Effect = New-ChipGlow "#60a5fa"
        } else {
            $filterUpdate.BorderBrush = $inactBd
            ($filterUpdate.Child.Children[0]).Foreground = $inactFg
            $filterUpdate.Effect = $null
        }
    }
}

function global:Restore-FilterPills {
    # Repaint the pills to reflect the REAL filter state after a detail
    # page temporarily marked them. Re-applies the CURRENT values, so no
    # filter state changes; Set-InstallFilterMode also restores the
    # correct Installed/VR Ready visibility via Sync-InstallPills.
    $global:DetailBothPills = $false
    if (Get-Command Set-FilterStyle -ErrorAction SilentlyContinue)      { Set-FilterStyle $script:activeFilter }
    if (Get-Command Set-InstallFilterMode -ErrorAction SilentlyContinue) { Set-InstallFilterMode $script:installFilterMode }
}

# Install-state filter is orthogonal to ALL/MC/GP - it stacks on top.
# Mode is one of "off" / "installed" / "ready" (see $script:installFilterMode).
# Swap model: exactly one pill is the visible "anchor" (leftmost), the other
# is the collapsed "partner" revealed on hover to the RIGHT of the anchor.
#   mode "ready"              -> anchor = VR Ready (active), partner = Installed
#   mode "off" / "installed"  -> anchor = Installed,         partner = VR Ready
# Clicking the partner promotes it to anchor (its filter becomes active) and
# the old anchor collapses; clicking the anchor toggles its own filter.
function global:Set-InstallFilterMode {
    param([string]$Mode)
    $script:installFilterMode = $Mode
    $glassBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassInactiveBg)
    $inactBd = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassInactiveBd)
    $inactFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassFgInactive)
    $inactInst  = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassInactiveBdInst)
    $inactReady = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassInactiveBdReady)
    $whiteBr = [System.Windows.Media.Brushes]::White

    # Same hover-cache cleanup as Set-FilterStyle - otherwise the
    # MouseLeave after clicking restores the pre-click grey.
    foreach ($pill in @($filterInstalled, $filterVRReady, $filterUpdate)) {
        if (-not $pill) { continue }
        if ($pill.Resources.Contains("shBg")) { $pill.Resources.Remove("shBg") | Out-Null }
        $tb = $pill.Child.Children[0]
        if ($tb -and $tb.Resources.Contains("shFg")) { $tb.Resources.Remove("shFg") | Out-Null }
        $pill.Background = $glassBg
    }
    # THE NUMBER IN THE BADGE HAS THE SAME TRAP, and it did bite:
    # Add-SoftHover collects ALL TextBlocks under the pill - the digit
    # included - and stores the resting colour in "shFg" on hover. The
    # loop above only clears Child.Children[0], which is the label. So
    # anyone who hovered the pill and then clicked it got the OLD, muted
    # digit colour written back on leaving - which is why the number was
    # hard to read while selected and only brightened again on the next
    # hover.
    if ($filterUpdCount -and $filterUpdCount.Resources.Contains("shFg")) {
        $filterUpdCount.Resources.Remove("shFg") | Out-Null
    }

    if ($filterInstalled) {
        if ($Mode -eq "installed") {
            $filterInstalled.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassActiveBdInst)
            $filterInstalled.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassBgInstOn)
            ($filterInstalled.Child.Children[0]).Foreground = $whiteBr
            $filterInstalled.Effect = New-ChipGlow
        } else {
            $filterInstalled.BorderBrush = $inactInst
            $filterInstalled.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassBgInstOff)
            ($filterInstalled.Child.Children[0]).Foreground = $inactFg
            $filterInstalled.Effect = $null
        }
    }
    if ($filterVRReady) {
        if ($Mode -eq "ready") {
            $filterVRReady.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassActiveBdReady)
            $filterVRReady.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassBgReadyOn)
            ($filterVRReady.Child.Children[0]).Foreground = $whiteBr
            $filterVRReady.Effect = New-ChipGlow "#34d399"
        } else {
            $filterVRReady.BorderBrush = $inactReady
            $filterVRReady.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassBgReadyOff)
            ($filterVRReady.Child.Children[0]).Foreground = $inactFg
            $filterVRReady.Effect = $null
        }
    }

    # --- Updates pill: visible only after a scan AND only when there is
    # something to update at all. It deliberately sits OUTSIDE the
    # anchor/partner swap of the two pills above and takes no part in it.
    # Handled centrally here because all three places that reveal the
    # pills after a scan call Set-InstallFilterMode anyway.
    if ($filterUpdate) {
        $updCount = 0
        try {
            if ($global:gameStateMap -and $global:gameStateMap.Count -gt 0) {
                foreach ($k in $global:gameStateMap.Keys) {
                    $stv = $global:gameStateMap[$k]
                    if ($stv -and $stv.State -eq "update") { $updCount++ }
                }
            }
        } catch {}
        if ($updCount -gt 0) {
            $filterUpdate.Visibility = [System.Windows.Visibility]::Visible
            if ($filterUpdCount) { $filterUpdCount.Text = [string]$updCount }
        } else {
            # Nothing to update -> pill gone. If it was the active
            # filter, the mode falls back - otherwise the list would show
            # nothing and nobody would know why.
            $filterUpdate.Visibility = [System.Windows.Visibility]::Collapsed
            if ($filterUpdCount) { $filterUpdCount.Text = "0" }
            if ($Mode -eq "update") { $script:installFilterMode = "off"; $Mode = "off" }
        }
        # The badge carrying the number. It is on screen in the
        # DESELECTED state too - hence a restrained, semi-transparent blue
        # there (12 % opacity) with a muted digit; selected, both get
        # stronger (27 %, bright digit). #AARRGGBB, the first two digits
        # are alpha.
        if ($filterUpdBadge) {
            $filterUpdBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString(
                $(if ($Mode -eq "update") { "#4460A5FA" } else { "#1F60A5FA" }))
        }
        if ($filterUpdCount) {
            # SELECTED: PURE WHITE, on purpose. On hover Add-SoftHover
            # lifts any text that is NOT pure white to #dddddd - with
            # #EAF3FD the digit actually got darker when hovered and
            # flickered back and forth. Pure white is left alone by the
            # hover, exactly like the label of the active pill.
            $filterUpdCount.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString(
                $(if ($Mode -eq "update") { "#FFFFFF" } else { "#8FB6DD" }))
        }
        if ($Mode -eq "update") {
            $filterUpdate.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#60a5fa")
            $filterUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassBgReadyOn)
            ($filterUpdate.Child.Children[0]).Foreground = $whiteBr
            $filterUpdate.Effect = New-ChipGlow "#60a5fa"
        } else {
            $filterUpdate.BorderBrush = $inactBd
            $filterUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassBgReadyOff)
            ($filterUpdate.Child.Children[0]).Foreground = $inactFg
            $filterUpdate.Effect = $null
        }
    }

    # --- Anchor / partner layout ---
    # Delegated to Sync-InstallPills. Crucially this does NOT reorder the pills
    # on click: a reorder while both are visible would move a pill out from
    # under the cursor (you click one and the other lands under the pointer).
    # The clicked pill stays put, the other lingers, and the reorder happens
    # only later when the partner collapses (mouse left the cluster).
    Sync-InstallPills
}

# Hard invariant enforcer: the anchor pill is ALWAYS visible - it is a core
# UI element and must never vanish. The partner is visible only while the
# cursor is genuinely over the install cluster (the Installed group or the
# Check Installed counter). Safe to call at any time (e.g. after a scan that
# pumped the dispatcher) to restore a correct, consistent pill state.
function global:Sync-InstallPills {
    if (-not ($filterInstalled -and $filterVRReady -and $installedFilterGroup)) { return }
    # Both Installed and VR Ready stay permanently visible once the scan group
    # is shown (no hover-reveal) - so a click always lands on a real pill.
    $filterInstalled.Visibility = [System.Windows.Visibility]::Visible
    $filterVRReady.Visibility   = [System.Windows.Visibility]::Visible
    return
    # On a VR Ready game's detail page both pills are shown on purpose
    # (Installed + VR Ready). Keep them open - don't collapse one away
    # when the cursor enters or leaves the cluster.
    if ($global:DetailBothPills) {
        $filterInstalled.Visibility = [System.Windows.Visibility]::Visible
        $filterVRReady.Visibility   = [System.Windows.Visibility]::Visible
        return
    }
    if ($script:installFilterMode -eq "ready") {
        $anchor = $filterVRReady;   $partner = $filterInstalled
    } else {
        $anchor = $filterInstalled; $partner = $filterVRReady
    }
    $anchor.Visibility = [System.Windows.Visibility]::Visible
    $cig = $window.FindName("CheckInstalledHoverGroup")
    # The partner pill is REVEALED only while the cursor is over the Installed
    # group. Hovering the Check Installed counter must NOT newly reveal it - a
    # cold hover or click there (e.g. running a scan) should never shift the
    # bar; it only KEEPS an already-revealed partner up. Without the
    # "currently visible" guard the post-scan Sync (fired while the cursor
    # still sits on the counter you just clicked) pops the VR Ready pill open.
    $partnerVisible = ($partner.Visibility -eq [System.Windows.Visibility]::Visible)
    $hovering = $installedFilterGroup.IsMouseOver -or ($cig -and $cig.IsMouseOver -and $partnerVisible)
    if ($hovering) {
        # Both visible. Do NOT reorder here - moving a pill while it is on
        # screen would shift it under/away from the cursor. Positions stay
        # exactly as they are until the mouse leaves.
        $partner.Visibility = [System.Windows.Visibility]::Visible
        if ($script:vrReadyHideTimer) { $script:vrReadyHideTimer.Stop() }
    } else {
        # Mouse has left the cluster: collapse the partner, then settle the
        # layout so the anchor is leftmost and the partner reveals to its
        # RIGHT next time. Safe to reorder now - the partner is invisible, so
        # nothing jumps under the cursor.
        $partner.Visibility = [System.Windows.Visibility]::Collapsed
        if (($installedFilterGroup.Children.Count -ge 2) -and ($installedFilterGroup.Children[0] -ne $anchor)) {
            $installedFilterGroup.Children.Remove($anchor)
            $installedFilterGroup.Children.Insert(0, $anchor)
        }
        $anchor.Margin  = [System.Windows.Thickness]::new(0)
        $partner.Margin = [System.Windows.Thickness]::new(6, 0, 0, 0)
    }
}

# These run as GLOBAL functions (not closures), so $script:installFilterMode
# and $script:vrReadyHideTimer resolve LIVE in the script scope rather than a
# frozen .GetNewClosure() snapshot. The hover handlers call these so the
# revealed partner always matches the CURRENT mode (e.g. when VR Ready is the
# active anchor, hovering reveals Installed - and vice versa).
function global:Show-InstallPartner {
    if (-not ($filterInstalled -and $filterVRReady)) { return }
    if ($script:vrReadyHideTimer) { $script:vrReadyHideTimer.Stop() }
    $partner = if ($script:installFilterMode -eq "ready") { $filterInstalled } else { $filterVRReady }
    if ($partner) { $partner.Visibility = [System.Windows.Visibility]::Visible }
}
function global:Freeze-InstallPartnerHide {
    if ($script:vrReadyHideTimer) { $script:vrReadyHideTimer.Stop() }
}
function global:Schedule-InstallPartnerHide {
    if ($script:vrReadyHideTimer) { $script:vrReadyHideTimer.Stop(); $script:vrReadyHideTimer.Start() }
}
function global:Tick-InstallPartner {
    if ($script:vrReadyHideTimer) { $script:vrReadyHideTimer.Stop() }
    Sync-InstallPills
}

# Pure predicate so list cards and discover tiles share the same logic.
function global:Test-GamePassesFilter {
    param($GameData, [string]$Query)
    try {
        if (-not $GameData) { return $true }
        $title    = if ($GameData.Title) { "$($GameData.Title)".ToLower() } else { "" }
        $mod      = if ($GameData.Mod)   { "$($GameData.Mod)".ToLower() }   else { "" }
        $pill     = if ($GameData.Pill)  { "$($GameData.Pill)".ToLower() }  else { "" }
        $author   = if ($GameData.Author) { "$($GameData.Author)".ToLower() } else { "" }
        $tags     = if ($GameData.Tags)  { $GameData.Tags } else { @() }
        $controls = if ($GameData.Controls) { $GameData.Controls } else { "" }

        # A search term starting with "-" EXCLUDES instead of including, so
        # "-praydog" hides every entry by that modder. Several may be chained
        # ("-praydog -astienth"), and they combine with a normal term:
        # "resident -praydog" searches for resident and drops his entries.
        # Split on whitespace, sort the parts into wanted / unwanted, and put
        # the wanted ones back together so a multi-word search like
        # "ghost recon" keeps working exactly as before.
        $excludeTerms = @()
        $unhideTerms  = @()
        $keepQuery    = $Query
        if ($Query -match '(^|\s)[-+]\S') {
            $parts  = @($Query -split '\s+' | Where-Object { $_ })
            $wanted = @()
            for ($pi = 0; $pi -lt $parts.Count; $pi++) {
                $part = $parts[$pi]
                if ($part.Length -gt 1 -and ($part.StartsWith("-") -or $part.StartsWith("+"))) {
                    $sign = $part.Substring(0,1)
                    $term = $part.Substring(1)
                    # A modder name can be two words ("-luke ross"). Keep
                    # attaching the following words while the result is still
                    # a known author - longest match wins, and everything
                    # after it stays a normal search term.
                    $take = 0
                    for ($pj = $pi + 1; $pj -lt $parts.Count; $pj++) {
                        $nxt = $parts[$pj]
                        if ($nxt.StartsWith("-") -or $nxt.StartsWith("+")) { break }
                        $cand = ($term + " " + $nxt)
                        if (Test-KnownModderName -Name $cand) { $term = $cand; $take = $pj - $pi }
                        else { break }
                    }
                    $pi += $take
                    if ($sign -eq "-") { $excludeTerms += $term } else { $unhideTerms += $term }
                }
                else { $wanted += $part }
            }
            $keepQuery = ($wanted -join " ").Trim()
        }

        # The exclusion is matched against the MODDER and the GENRE TAGS,
        # deliberately NOT against the title - otherwise "-real" would kill
        # every game with "real" in its name. Mod and Pill are included
        # because some entries name the modder there instead of in Author
        # (e.g. "lufz (auto-update)"); the tags carry the genres, so
        # "-horror" and "-racing" work the same way as "-praydog".
        $allExcludes = @()
        if ($excludeTerms.Count -gt 0) { $allExcludes += $excludeTerms }
        # Permanently hidden modders (settings key "hiddenModders"). They act
        # like a standing "-name" and are matched the same way. A "+name" in
        # the box lifts one, so a hidden modder is never unreachable.
        if ($global:HiddenModders -and $global:HiddenModders.Count -gt 0) {
            foreach ($hm in $global:HiddenModders) {
                if ($hm -and ($unhideTerms -notcontains $hm)) { $allExcludes += $hm }
            }
        }
        foreach ($ex in $allExcludes) {
            if (-not $ex) { continue }
            if ($author.Contains($ex) -or $mod.Contains($ex) -or $pill.Contains($ex)) { return $false }
            if (($tags | Where-Object { $_ -and "$_".ToLower() -eq $ex }).Count -gt 0) { return $false }
        }

        $Query = $keepQuery
        $textMatch = $Query -eq "" -or $title.Contains($Query) -or $mod.Contains($Query) -or
                     $pill.Contains($Query) -or $author.Contains($Query) -or
                     ($tags | Where-Object { $_ -and "$_".ToLower().Contains($Query) }).Count -gt 0
        # Keyword shortcuts: typing "free" lists every FREE title and "wip"
        # lists every work-in-progress title (matched by Title, on top of the
        # normal text match above). "new" is reserved exclusively for titles
        # added to the Hub during the rolling 10.5-day window; without the
        # override below it would also return unrelated names such as New Star
        # GP. $null -contains is safe -> false.
        if ($Query -eq "free" -and ($global:FREE_GAME_TITLES -contains $GameData.Title)) { $textMatch = $true }
        if ($Query -eq "wip"  -and ($global:WIP_GAME_TITLES  -contains $GameData.Title)) { $textMatch = $true }
        if ($Query -eq "new") { $textMatch = ($global:NEW_GAME_TITLES -contains $GameData.Title) }
        # "roomscale" / "room-scale" / "room scale" lists every title whose
        # VR mod supports room-scale play (Roomscale flag in the catalog).
        if (($Query -eq "roomscale" -or $Query -eq "room-scale" -or $Query -eq "room scale") -and $GameData.Roomscale) { $textMatch = $true }
        $ctrlMatch = $script:activeFilter -eq "ALL" -or $controls -eq $script:activeFilter -or
                     ($script:activeFilter -eq "MC" -and ($controls -eq "BOTH" -or $controls -eq "VRGP")) -or
                     ($script:activeFilter -eq "GP" -and ($controls -eq "BOTH" -or $controls -eq "VRGP"))
        $instMatch = $true
        if ($script:installFilterMode -ne "off") {
            if (-not $global:gameStateMap -or $global:gameStateMap.Count -eq 0) {
                # No scan has run yet: the install filter cannot know anything, so
                # it stays inactive (shows everything) instead of emptying the list.
                # The Scan games button pulses to point the user at the scan.
                $instMatch = $true
            } else {
                $st = $global:gameStateMap[$GameData.Title]
                if ($script:installFilterMode -eq "update") {
                    # Updates = installed AND a newer version exists. A
                    # true subset of VR Ready.
                    $instMatch = ($st -ne $null) -and ($st.State -eq "update")
                } elseif ($script:installFilterMode -eq "ready") {
                    # VR Ready = the VR mod is installed (states ready/update).
                    # This is the modded subset of Installed.
                    $instMatch = ($st -ne $null) -and ($st.State -in @("ready", "update"))
                } else {
                    # Needs Mod = the base game is present on this PC but the VR mod
                    # is NOT installed yet (state "installed" only). This is the
                    # "could add a mod" list. ready/update are the already-modded
                    # games and belong to VR Ready, so the two pills are disjoint
                    # (Needs Mod + VR Ready = the "X on PC" total: e.g. 8 + 76 = 84).
                    $instMatch = ($st -ne $null) -and ($st.State -eq "installed")
                }
            }
        }
        return ($textMatch -and $ctrlMatch -and $instMatch)
    } catch {
        # Fail-open: a single malformed entry or transient error must NEVER
        # make a game vanish from search. Showing one extra card is harmless;
        # silently hiding a game is the bug we are guarding against.
        return $true
    }
}

function global:Apply-Filter {
    $query = ""
    try { if ($searchBox) { $query = $searchBox.Text.Trim().ToLower() } } catch { $query = "" }
    $view = if (Get-Command Get-CurrentView -ErrorAction SilentlyContinue) { Get-CurrentView } else { "List" }
    # Filter the List cards ALWAYS - not only when List is the tracked view.
    # Both the List and the Library hold the SAME games; gating this on the
    # tracked view meant a view-tracking mismatch (e.g. after toggling
    # Library <-> List with an active query) could leave one list stuck on the
    # last search, because clearing the box then ran the OTHER branch and
    # never re-showed these cards. Updating the currently-hidden list's
    # visibility too is harmless and guarantees whichever view you switch to
    # is already correct. Each card is FAIL-OPEN: if testing one game throws
    # (or its data is missing) that card is SHOWN, never hidden, and the loop
    # continues, so one bad entry can never freeze the search.
    for ($i = 0; $i -lt $global:allCards.Count; $i++) {
        $card = $global:allCards[$i]
        if (-not $card) { continue }
        $vis = [System.Windows.Visibility]::Visible
        try {
            $gameData = if ($i -lt $global:allGameData.Count) { $global:allGameData[$i] } else { $null }
            if ($gameData -and -not (Test-GamePassesFilter -GameData $gameData -Query $query)) {
                $vis = [System.Windows.Visibility]::Collapsed
            }
        } catch { $vis = [System.Windows.Visibility]::Visible }
        $card.Visibility = $vis
    }
    # Discover/Library tiles - filter ALWAYS when built, for the same reason:
    # keep the hidden view consistent so a cleared query re-shows every tile
    # regardless of which view is tracked or visible.
    if ($global:discoverPanel -and $global:DiscoverTilesBuilt) {
        foreach ($tile in $global:discoverPanel.Children) {
            if (-not $tile) { continue }
            $g = $null
            try { $g = $tile.Resources.Item("game") } catch {}
            if (-not $g) { continue }
            $vis = [System.Windows.Visibility]::Visible
            try {
                if (-not (Test-GamePassesFilter -GameData $g -Query $query)) {
                    $vis = [System.Windows.Visibility]::Collapsed
                }
            } catch { $vis = [System.Windows.Visibility]::Visible }
            $tile.Visibility = $vis
        }
    }
    # Overview tiles - re-run the genre+power+header-filter pipeline
    # so Motion/Gamepad/Installed in the header bar also affect
    # the explore page. Isolated so a hiccup there can't break list search.
    if ($view -eq "Explore" -and $global:OverviewBuilt -and (Get-Command Apply-OvFilters -ErrorAction SilentlyContinue)) {
        try { Apply-OvFilters } catch {}
    }
}

$filterAll.Add_PreviewMouseLeftButtonDown({ Set-FilterStyle "ALL"; Apply-Filter })
$filterMC.Add_PreviewMouseLeftButtonDown({  Set-FilterStyle "MC";  Apply-Filter })
$filterGP.Add_PreviewMouseLeftButtonDown({  Set-FilterStyle "GP";  Apply-Filter })
# Soft attention pulse on the Check Installed button. Used when
# the user enables the "Installed" filter but hasn't run a scan
# yet - we draw the eye to where they need to click. Pulses the
# background brightness 3 times over ~2.4s. Colors are matched to
# the new glass counter style: base #1a4ade80 (the resting bg),
# bright #4d4ade80 (about 3x brighter green tint). The permanent
# DropShadowEffect halo is untouched - this only affects Background.
function global:Pulse-CheckInstalledButton {
    if (-not $checkInstalledBtn) { return }
    $base   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a4ade80")
    $bright = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4d4ade80")
    $count = 0
    $maxCount = 6   # 3 full cycles (on/off/on/off/on/off)
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(400)
    $timer.Add_Tick({
        $script:pulseCount++
        if ($script:pulseCount -gt $script:pulseMax) {
            $script:pulseTimer.Stop()
            $checkInstalledBtn.Background = $script:pulseBase
            return
        }
        $checkInstalledBtn.Background = if ($script:pulseCount % 2 -eq 1) {
            $script:pulseBright
        } else {
            $script:pulseBase
        }
    })
    $script:pulseTimer  = $timer
    $script:pulseBase   = $base
    $script:pulseBright = $bright
    $script:pulseCount  = 0
    $script:pulseMax    = $maxCount
    $timer.Start()
}

$filterInstalled.Add_PreviewMouseLeftButtonDown({
    if ($script:installFilterMode -eq "ready") {
        # Installed is the revealed partner -> promote it (swap).
        Set-InstallFilterMode "installed"
    } else {
        # Installed is the anchor -> toggle its own filter on/off.
        $newMode = if ($script:installFilterMode -eq "installed") { "off" } else { "installed" }
        Set-InstallFilterMode $newMode
    }
    Apply-Filter
    # If a filter is on but no scan has been run yet, draw attention to
    # the Check Installed button so the user knows what populates the list.
    if (($script:installFilterMode -ne "off") -and ($global:gameStateMap.Count -eq 0)) {
        Pulse-CheckInstalledButton
    }
})

$filterVRReady.Add_PreviewMouseLeftButtonDown({
    if ($script:installFilterMode -eq "ready") {
        # VR Ready is the active anchor -> toggle it off (back to Installed).
        Set-InstallFilterMode "off"
    } else {
        # VR Ready is the revealed partner -> promote it (swap).
        Set-InstallFilterMode "ready"
    }
    Apply-Filter
    if (($script:installFilterMode -ne "off") -and ($global:gameStateMap.Count -eq 0)) {
        Pulse-CheckInstalledButton
    }
})

$filterUpdate.Add_PreviewMouseLeftButtonDown({
    # A switch of its own, not a swap: on or off. The other two pills
    # keep their exchange to themselves.
    $newMode = if ($script:installFilterMode -eq "update") { "off" } else { "update" }
    Set-InstallFilterMode $newMode
    Apply-Filter
    if (($script:installFilterMode -ne "off") -and ($global:gameStateMap.Count -eq 0)) {
        Pulse-CheckInstalledButton
    }
})

# --- Reveal the partner pill while hovering the Installed group ---
# Only one pill (the "anchor") is visible at rest; the other ("partner") is
# collapsed and revealed to the RIGHT of the anchor while the cursor is over
# the group. Which pill is anchor vs partner depends on the active mode (see
# Set-InstallFilterMode). InstalledFilterGroup is a transparent StackPanel so
# the gap between the pills is not a dead zone; a generous hide-timer covers
# the cursor leaving the group. The anchor is never collapsed by the timer -
# only the partner is.
if ($filterInstalled -and $filterVRReady -and $installedFilterGroup) {
    $vrReadyHideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $vrReadyHideTimer.Interval = [TimeSpan]::FromMilliseconds(650)
    $vrReadyHideTimer.Add_Tick({ Tick-InstallPartner })
    $script:vrReadyHideTimer = $vrReadyHideTimer

    $installedFilterGroup.Add_MouseEnter({ Show-InstallPartner })
    $installedFilterGroup.Add_MouseLeave({ Schedule-InstallPartnerHide })

    # The Check Installed counter sits immediately to the right. Moving from
    # the partner toward it (e.g. to run a scan because it is pulsing) must
    # NOT collapse the partner - otherwise the bar shifts mid-reach and the
    # wrong control gets clicked. Entering the Check Installed group cancels
    # the hide-timer (keeps the partner up if it is showing) but does NOT
    # force it visible - a cold hover straight onto Check Installed should
    # not shift the bar. Leaving it restarts the hide-timer.
    $checkInstalledHoverGroup = $window.FindName("CheckInstalledHoverGroup")
    if ($checkInstalledHoverGroup) {
        $checkInstalledHoverGroup.Add_MouseEnter({ Freeze-InstallPartnerHide })
        $checkInstalledHoverGroup.Add_MouseLeave({ Schedule-InstallPartnerHide })
    }
}

