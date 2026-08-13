# ---------------------------------------------------------------
# Banner buttons (List view + Library view) + Overview back/show
# ---------------------------------------------------------------

# Helper: open detail page for a banner game from a given origin.
function global:Open-BannerDetail {
    param($Game, [string]$Origin)
    if (-not $Game) { return }
    $global:DetailOrigin = $Origin
    Build-DiscoverTiles
    Refresh-DiscoverStatuses
    if ($global:discoverOverview) {
        $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed
    }
    $global:discoverHost.Visibility = [System.Windows.Visibility]::Visible
    if ($global:listScroll) { $global:listScroll.Visibility = [System.Windows.Visibility]::Collapsed }
    if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
    if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
    Show-DiscoverDetail -Game $Game
}

# Helper: short orange-glow border on banner button press. Only
# BorderBrush flips, not BorderThickness or Background - the XAML
# reserves a 1.5px transparent/colored border on every banner
# button so press never shifts the inner text layout. Background
# stays at hover color (cursor is still over the button).
function global:Add-BannerButtonPress {
    param($Btn, [string]$PressColor = "#ffcc66")
    if (-not $Btn) { return }
    $color = $PressColor
    $Btn.Add_MouseLeftButtonDown({
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($color)
    }.GetNewClosure())
}

# Light-sweep hover for the transparent banner CTAs (Show / View this mod /
# Explore all games / Shuffle) - the same travelling shine the game-tile
# Install buttons use, but over a transparent base so it never changes the
# button's border or text colour. A translucent white band rides diagonally
# behind the text once per hover (700ms, one-shot) and the outer stops stay
# fully transparent, so the button reverts to a clean transparent fill when
# the band leaves the [0,1] range. MouseLeave restores Transparent outright.
function global:Start-BannerButtonSweep {
    param($Btn)
    if (-not $Btn) { return }
    $clear = [System.Windows.Media.Color]::FromArgb(0,   255, 255, 255)
    $shine = [System.Windows.Media.Color]::FromArgb(64,  255, 255, 255)
    $brush = New-Object System.Windows.Media.LinearGradientBrush
    $brush.StartPoint = New-Object System.Windows.Point 0, 0
    $brush.EndPoint   = New-Object System.Windows.Point 1, 1
    $sOutA = New-Object System.Windows.Media.GradientStop $clear, 0.0
    $sLead = New-Object System.Windows.Media.GradientStop $clear, 0.0
    $sPeak = New-Object System.Windows.Media.GradientStop $shine, 0.0
    $sTail = New-Object System.Windows.Media.GradientStop $clear, 0.0
    $sOutB = New-Object System.Windows.Media.GradientStop $clear, 1.0
    $brush.GradientStops.Add($sOutA) | Out-Null
    $brush.GradientStops.Add($sLead) | Out-Null
    $brush.GradientStops.Add($sPeak) | Out-Null
    $brush.GradientStops.Add($sTail) | Out-Null
    $brush.GradientStops.Add($sOutB) | Out-Null
    $Btn.Background = $brush
    $dur = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(700))
    $aLead = New-Object System.Windows.Media.Animation.DoubleAnimation -0.35, 1.05, $dur
    $aPeak = New-Object System.Windows.Media.Animation.DoubleAnimation -0.20, 1.20, $dur
    $aTail = New-Object System.Windows.Media.Animation.DoubleAnimation -0.05, 1.35, $dur
    $sLead.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aLead)
    $sPeak.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aPeak)
    $sTail.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aTail)
}

# Run an action after a delay via the WPF dispatcher. Lets buttons
# that navigate to another page show their press-glow border for
# one rendered frame before the transition wipes the source view.
function global:Invoke-DeferredAction {
    param([scriptblock]$Action, [int]$DelayMs = 500)
    $t = New-Object System.Windows.Threading.DispatcherTimer
    $t.Interval = [TimeSpan]::FromMilliseconds($DelayMs)
    $actCap = $Action
    $t.Add_Tick({
        $this.Stop()
        & $actCap
    }.GetNewClosure())
    $t.Start()
}

# List banner (in the VR-mod list view)
$listBannerShowBtn    = $window.FindName("ListBannerShowBtn")
$listBannerExploreBtn = $window.FindName("ListBannerExploreBtn")
$listBannerImage      = $window.FindName("ListBannerImage")
$listBannerTitle      = $window.FindName("ListBannerTitle")
if ($listBannerShowBtn) {
    $listBannerShowBtn.Add_MouseLeftButtonUp({
        # NOTE: do not reset Background/BorderBrush here - the
        # MouseLeftButtonDown press-glow must stay visible during
        # the 1200ms defer below. Resetting here was killing the
        # glow immediately on click release.
        Invoke-DeferredAction -DelayMs 1200 -Action { Open-BannerDetail -Game $global:ListBannerGame -Origin "LIST" }
    })
    $listBannerShowBtn.Add_MouseEnter({ Start-BannerButtonSweep $this })
    $listBannerShowBtn.Add_MouseLeave({
        $this.Background  = [System.Windows.Media.Brushes]::Transparent
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#bfa845")
    })
    $listBannerShowBtn.Add_MouseLeftButtonDown({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#f0d860") })
}
if ($listBannerExploreBtn) {
    $listBannerExploreBtn.Add_MouseLeftButtonUp({
        # Do NOT reset styles here - the press-glow set by
        # MouseLeftButtonDown must persist during the 1200ms defer.
        Invoke-DeferredAction -DelayMs 1200 -Action { Show-DiscoverOverview -Origin "LIST" }
    })
    $listBannerExploreBtn.Add_MouseEnter({ Start-BannerButtonSweep $this })
    $listBannerExploreBtn.Add_MouseLeave({
        $this.Background  = [System.Windows.Media.Brushes]::Transparent
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    })
    Add-BannerButtonPress -Btn $listBannerExploreBtn -PressColor "#ffcc66"
}
# Banner art + title are alt click targets for opening the detail
# view - same effect as "Show". Hover grows the banner slightly
# (same ScaleTransform pattern as the portrait-grid tiles); press
# keeps the orange glow border as click confirmation while the
# detail page lazy-loads.
#
# IMPORTANT: hover MouseEnter/Leave are wired to the outer banner
# Border, NOT to Image/Title. WPF RenderTransform is render-time
# only - hit-test bounds stay at the un-transformed size. Hooking
# the scale handler to the Image directly caused jitter because
# the *visual* image extended past its hit-test rectangle on
# scale-up, the cursor briefly left the Image hit area, Leave
# fired, banner shrank back, cursor was over Image again, Enter
# fired ... and so on. Border bounds never move so this is stable.
$global:ListBannerBorder = $window.FindName("ListBanner")
function global:Set-BannerHoverGrow {
    param($BannerBorder, [string]$State = "none")
    if (-not $BannerBorder) { return }
    if ($State -eq "hover") {
        $sc = New-Object System.Windows.Media.ScaleTransform 1.02, 1.02
        $BannerBorder.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
        $BannerBorder.RenderTransform = $sc
        $BannerBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4a4a55")
        $BannerBorder.BorderThickness = [System.Windows.Thickness]::new(1)
    } elseif ($State -eq "press") {
        $sc = New-Object System.Windows.Media.ScaleTransform 1.02, 1.02
        $BannerBorder.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
        $BannerBorder.RenderTransform = $sc
        $BannerBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ff8822")
        $BannerBorder.BorderThickness = [System.Windows.Thickness]::new(2)
    } else {
        $BannerBorder.RenderTransform = $null
        $BannerBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
        $BannerBorder.BorderThickness = [System.Windows.Thickness]::new(1)
    }
}
# Hover on outer Border (jitter-free), click on Image/Title only.
if ($global:ListBannerBorder) {
    $global:ListBannerBorder.Add_MouseEnter({ Set-BannerHoverGrow -BannerBorder $global:ListBannerBorder -State "hover" })
    $global:ListBannerBorder.Add_MouseLeave({ Set-BannerHoverGrow -BannerBorder $global:ListBannerBorder -State "none" })
}
if ($listBannerImage) {
    $listBannerImage.Cursor = [System.Windows.Input.Cursors]::Hand
    $listBannerImage.Add_MouseLeftButtonDown({ Set-BannerHoverGrow -BannerBorder $global:ListBannerBorder -State "press" })
    $listBannerImage.Add_MouseLeftButtonUp({ Open-BannerDetail -Game $global:ListBannerGame -Origin "LIST" })
}
if ($listBannerTitle) {
    $listBannerTitle.Cursor = [System.Windows.Input.Cursors]::Hand
    $listBannerTitle.Add_MouseLeftButtonDown({ Set-BannerHoverGrow -BannerBorder $global:ListBannerBorder -State "press" })
    $listBannerTitle.Add_MouseLeftButtonUp({ Open-BannerDetail -Game $global:ListBannerGame -Origin "LIST" })
}

# Library banner (in the portrait grid view)
$libBannerShowBtn    = $window.FindName("LibBannerShowBtn")
$libBannerExploreBtn = $window.FindName("LibBannerExploreBtn")
$libBannerImage      = $window.FindName("LibBannerImage")
$libBannerTitle      = $window.FindName("LibBannerTitle")
if ($libBannerShowBtn) {
    $libBannerShowBtn.Add_MouseLeftButtonUp({
        # Do NOT reset styles - press-glow must persist during defer.
        Invoke-DeferredAction -DelayMs 1200 -Action { Open-BannerDetail -Game $global:LibBannerGame -Origin "TILES" }
    })
    $libBannerShowBtn.Add_MouseEnter({ Start-BannerButtonSweep $this })
    $libBannerShowBtn.Add_MouseLeave({
        $this.Background  = [System.Windows.Media.Brushes]::Transparent
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#bfa845")
    })
    $libBannerShowBtn.Add_MouseLeftButtonDown({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#f0d860") })
}
if ($libBannerExploreBtn) {
    $libBannerExploreBtn.Add_MouseLeftButtonUp({
        # Do NOT reset styles - press-glow must persist during defer.
        Invoke-DeferredAction -DelayMs 1200 -Action { Show-DiscoverOverview -Origin "TILES" }
    })
    $libBannerExploreBtn.Add_MouseEnter({ Start-BannerButtonSweep $this })
    $libBannerExploreBtn.Add_MouseLeave({
        $this.Background  = [System.Windows.Media.Brushes]::Transparent
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    })
    Add-BannerButtonPress -Btn $libBannerExploreBtn -PressColor "#ffcc66"
}
$global:LibBannerBorder = $window.FindName("LibBanner")
if ($global:LibBannerBorder) {
    $global:LibBannerBorder.Add_MouseEnter({ Set-BannerHoverGrow -BannerBorder $global:LibBannerBorder -State "hover" })
    $global:LibBannerBorder.Add_MouseLeave({ Set-BannerHoverGrow -BannerBorder $global:LibBannerBorder -State "none" })
}
if ($libBannerImage) {
    $libBannerImage.Cursor = [System.Windows.Input.Cursors]::Hand
    $libBannerImage.Add_MouseLeftButtonDown({ Set-BannerHoverGrow -BannerBorder $global:LibBannerBorder -State "press" })
    $libBannerImage.Add_MouseLeftButtonUp({ Open-BannerDetail -Game $global:LibBannerGame -Origin "TILES" })
}
if ($libBannerTitle) {
    $libBannerTitle.Cursor = [System.Windows.Input.Cursors]::Hand
    $libBannerTitle.Add_MouseLeftButtonDown({ Set-BannerHoverGrow -BannerBorder $global:LibBannerBorder -State "press" })
    $libBannerTitle.Add_MouseLeftButtonUp({ Open-BannerDetail -Game $global:LibBannerGame -Origin "TILES" })
}

# Overview back + banner buttons
$ovBackBtn    = $window.FindName("OverviewBackBtn")
$ovShowBtn    = $window.FindName("OvBannerShowBtn")
$ovShuffleBtn = $window.FindName("OvBannerShuffleBtn")
$ovBannerImage = $window.FindName("OvBannerImage")
$ovBannerTitle = $window.FindName("OvBannerTitle")
# Cache the back-button label so Show-DiscoverOverview can swap it
# between "Back to library" and "Back to mod list" per origin.
$global:OverviewBackText = $window.FindName("OverviewBackBtnText")
if ($ovBackBtn) {
    $ovBackBtn.Add_MouseLeftButtonUp({
        Invoke-DeferredAction -Action { Hide-DiscoverOverview }
    })
    $ovBackBtn.Add_MouseEnter({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") })
    $ovBackBtn.Add_MouseLeave({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48") })
    Add-BannerButtonPress -Btn $ovBackBtn
}
if ($ovShowBtn) {
    $ovShowBtn.Add_MouseLeftButtonUp({
        # Do NOT reset styles - press-glow must persist during defer.
        Invoke-DeferredAction -DelayMs 1200 -Action { Open-BannerDetail -Game $global:OvBannerGame -Origin "OVERVIEW" }
    })
    $ovShowBtn.Add_MouseEnter({ Start-BannerButtonSweep $this })
    $ovShowBtn.Add_MouseLeave({
        $this.Background  = [System.Windows.Media.Brushes]::Transparent
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#bfa845")
    })
    $ovShowBtn.Add_MouseLeftButtonDown({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#f0d860") })
}
if ($ovShuffleBtn) {
    # Shuffle within the active genre filter. If "ALL" is selected,
    # this falls through to the unfiltered Set-OvBanner behaviour
    # via Set-OvBannerForActiveGenre's own ALL branch.
    $ovShuffleBtn.Add_MouseLeftButtonUp({
        $this.Background  = [System.Windows.Media.Brushes]::Transparent
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
        Set-OvBannerForActiveGenre
        if (Get-Command Reshuffle-BannerEffects -ErrorAction SilentlyContinue) { Reshuffle-BannerEffects }
    })
    $ovShuffleBtn.Add_MouseEnter({ Start-BannerButtonSweep $this })
    $ovShuffleBtn.Add_MouseLeave({
        $this.Background  = [System.Windows.Media.Brushes]::Transparent
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    })
    Add-BannerButtonPress -Btn $ovShuffleBtn
}
$global:OvBannerBorder = $window.FindName("OvBanner")
if ($global:OvBannerBorder) {
    $global:OvBannerBorder.Add_MouseEnter({ Set-BannerHoverGrow -BannerBorder $global:OvBannerBorder -State "hover" })
    $global:OvBannerBorder.Add_MouseLeave({ Set-BannerHoverGrow -BannerBorder $global:OvBannerBorder -State "none" })
}
if ($ovBannerImage) {
    $ovBannerImage.Cursor = [System.Windows.Input.Cursors]::Hand
    $ovBannerImage.Add_MouseLeftButtonDown({ Set-BannerHoverGrow -BannerBorder $global:OvBannerBorder -State "press" })
    $ovBannerImage.Add_MouseLeftButtonUp({ Open-BannerDetail -Game $global:OvBannerGame -Origin "OVERVIEW" })
}
if ($ovBannerTitle) {
    $ovBannerTitle.Cursor = [System.Windows.Input.Cursors]::Hand
    $ovBannerTitle.Add_MouseLeftButtonDown({ Set-BannerHoverGrow -BannerBorder $global:OvBannerBorder -State "press" })
    $ovBannerTitle.Add_MouseLeftButtonUp({ Open-BannerDetail -Game $global:OvBannerGame -Origin "OVERVIEW" })
}

# Initial banner loads
# Initial banner loads (skipped per banner if user has set
# bannerListDisabled / bannerLibDisabled to true).
$listBannerEl = $window.FindName("ListBanner")
$libBannerEl  = $window.FindName("LibBanner")

$listDisabled = [bool](Get-HubSetting -Key "bannerListDisabled" -Default $false)
$libDisabled  = [bool](Get-HubSetting -Key "bannerLibDisabled"  -Default $false)

if ($listDisabled -and $listBannerEl) {
    $listBannerEl.Visibility = [System.Windows.Visibility]::Collapsed
} else {
    try { Set-ListBanner } catch { }
}
if ($libDisabled -and $libBannerEl) {
    $libBannerEl.Visibility = [System.Windows.Visibility]::Collapsed
} else {
    try { Set-LibBanner } catch { }
}

# Wire hover-close on both banners (no-op if already disabled).
Setup-BannerHoverClose `
    -Banner     $listBannerEl `
    -Overlay    ($window.FindName("ListBannerCloseOverlay")) `
    -CloseBtn   ($window.FindName("ListBannerCloseBtn")) `
    -DisableBtn ($window.FindName("ListBannerDisableBtn")) `
    -SettingKey "bannerListDisabled"

Setup-BannerHoverClose `
    -Banner     $libBannerEl `
    -Overlay    ($window.FindName("LibBannerCloseOverlay")) `
    -CloseBtn   ($window.FindName("LibBannerCloseBtn")) `
    -DisableBtn ($window.FindName("LibBannerDisableBtn")) `
    -SettingKey "bannerLibDisabled"


$filterAll       = $window.FindName("FilterAll")
$filterMC        = $window.FindName("FilterMC")
$filterGP        = $window.FindName("FilterGP")
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
    $filterAll.Effect = $(if ($active -eq "ALL") { New-ChipGlow } else { $null })
    $filterMC.Effect  = $(if ($active -eq "MC")  { New-ChipGlow } else { $null })
    $filterGP.Effect  = $(if ($active -eq "GP")  { New-ChipGlow } else { $null })
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
    # Needs Mod lights ONLY when the base game is present but the mod is
    # NOT installed yet. A VR Ready title already has the mod, so it marks
    # VR Ready only (not Needs Mod). Both pills stay open via DetailBothPills.
    $installedLit = $installedOnly
    # Tell Sync-InstallPills to keep both pills open (no hover collapse)
    # while a VR Ready title's detail page is shown.
    $global:DetailBothPills = [bool]$isReady

    # All pill is not an attribute -> always dimmed on a detail page.
    if ($filterAll) {
        $filterAll.BorderBrush = $inactBd
        ($filterAll.Child).Foreground = $inactFg
    }
    if ($filterMC) {
        $filterMC.BorderBrush = if ($hasMC) { [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassActiveBdMC) } else { $inactBd }
        ($filterMC.Child.Children[1]).Foreground = if ($hasMC) { $whiteBr } else { $inactFg }
    }
    if ($filterGP) {
        $filterGP.BorderBrush = if ($hasGP) { [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassActiveBdGP) } else { $inactBd }
        ($filterGP.Child.Children[1]).Foreground = if ($hasGP) { $whiteBr } else { $inactFg }
    }
    if ($filterInstalled) {
        # Always visible. Lit only for "Needs Mod" (base present, no mod);
        # a VR Ready title does NOT light this pill.
        $filterInstalled.Visibility = [System.Windows.Visibility]::Visible
        $filterInstalled.BorderBrush = if ($installedLit) { [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassActiveBdInst) } else { $inactBd }
        ($filterInstalled.Child.Children[0]).Foreground = if ($installedLit) { $whiteBr } else { $inactFg }
    }
    # VR Ready: ALWAYS visible (no hover-reveal). Marked when the game is
    # VR Ready, otherwise shown unselected - so the pill is always present
    # and clickable and the cluster never shifts under the cursor.
    if ($filterVRReady) {
        $filterVRReady.Visibility = [System.Windows.Visibility]::Visible
        if ($isReady) {
            $filterVRReady.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($script:glassActiveBdReady)
            ($filterVRReady.Child.Children[0]).Foreground = $whiteBr
        } else {
            $filterVRReady.BorderBrush = $inactBd
            ($filterVRReady.Child.Children[0]).Foreground = $inactFg
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
    # DIE ZAHL IM TRAEGER HAT DIESELBE FALLE, und sie hat zugeschlagen:
    # Add-SoftHover sammelt ALLE TextBlocks unter der Pille - also auch die
    # Ziffer - und legt beim Hover die Ruhefarbe in "shFg" ab. Die Schleife
    # oben raeumt nur Child.Children[0] auf, das ist die Beschriftung. Wer
    # die Pille also erst ueberfahren und dann angeklickt hat, bekam beim
    # Verlassen die ALTE, gedaempfte Ziffernfarbe zurueckgeschrieben -
    # deshalb war die Zahl im ausgewaehlten Zustand schlecht lesbar und
    # wurde erst beim naechsten Hover wieder heller.
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

    # --- Updates-Pille: sichtbar nur nach einem Scan UND nur wenn es
    # ueberhaupt etwas zu aktualisieren gibt. Sie steht bewusst NEBEN dem
    # Anker/Partner-Tausch der beiden oberen Pillen und macht daran nichts
    # mit. Hier zentral erledigt, weil alle drei Stellen, die die Pillen
    # nach einem Scan einblenden, ohnehin Set-InstallFilterMode aufrufen.
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
            # Nichts zu aktualisieren -> Pille weg. War sie der aktive
            # Filter, faellt der Modus zurueck, sonst zeigte die Liste
            # nichts mehr und niemand wuesste warum.
            $filterUpdate.Visibility = [System.Windows.Visibility]::Collapsed
            if ($filterUpdCount) { $filterUpdCount.Text = "0" }
            if ($Mode -eq "update") { $script:installFilterMode = "off"; $Mode = "off" }
        }
        # Der Traeger der Zahl. Sie steht auch im ABGEWAEHLTEN Zustand da -
        # deshalb dort ein zurueckhaltendes, halbdurchlaessiges Blau (12 %
        # Deckung) mit gedaempfter Ziffer; angewaehlt wird beides kraeftiger
        # (27 %, helle Ziffer). #AARRGGBB, die ersten zwei Stellen sind Alpha.
        if ($filterUpdBadge) {
            $filterUpdBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString(
                $(if ($Mode -eq "update") { "#4460A5FA" } else { "#1F60A5FA" }))
        }
        if ($filterUpdCount) {
            # ANGEWAEHLT: REINES WEISS, mit Absicht. Add-SoftHover hellt beim
            # Hover jeden Text auf #dddddd auf, der NICHT reinweiss ist -
            # bei #EAF3FD wurde die Ziffer dadurch beim Ueberfahren sogar
            # dunkler und sprang hin und her. Reinweiss laesst der Hover in
            # Ruhe, genau wie bei der Beschriftung der aktiven Pille.
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
        # normal text match above). $null -contains is safe -> false.
        if ($Query -eq "free" -and ($global:FREE_GAME_TITLES -contains $GameData.Title)) { $textMatch = $true }
        if ($Query -eq "wip"  -and ($global:WIP_GAME_TITLES  -contains $GameData.Title)) { $textMatch = $true }
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
                    # Updates = installiert UND es liegt eine neuere Version
                    # vor. Echte Teilmenge von VR Ready.
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
    # Eigener Schalter, kein Tausch: an oder aus. Die beiden anderen
    # Pillen behalten ihr Wechselspiel unter sich.
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

$searchPlaceholder = $window.FindName("SearchPlaceholder")
# ---------------------------------------------------------------
# Search hint under the box. Two states in one spot:
#   normal  -> the examples line
#   "-name" -> offer to hide that modder for good, with the way back
# Only visible while the box has focus, and it hangs below the pill on
# its own layer, so showing it never moves the header.
# ---------------------------------------------------------------
$searchHintHost  = $window.FindName("SearchHintHost")
$searchHint      = $window.FindName("SearchHint")
$searchHidePanel = $window.FindName("SearchHidePanel")
$searchHideChk   = $window.FindName("SearchHideChk")
$searchHideText  = $window.FindName("SearchHideText")

# Permanently hidden modders live in .hub-settings.json, next to the view
# choice and the S/M/L size - no new file format, survives a Hub update.
function global:Get-HiddenModders {
    $raw = $null
    try { $raw = Get-HubSetting -Key "hiddenModders" -Default @() } catch {}
    $out = @()
    foreach ($x in @($raw)) { if ($x) { $out += ([string]$x).Trim().ToLower() } }
    return ,$out
}
function global:Set-HiddenModders {
    param([string[]]$List)
    $clean = @()
    foreach ($x in @($List)) { if ($x) { $clean += ([string]$x).Trim().ToLower() } }
    $global:HiddenModders = @($clean | Sort-Object -Unique)
    try { Set-HubSetting -Key "hiddenModders" -Value $global:HiddenModders } catch {}
}
$global:HiddenModders = Get-HiddenModders

# The name behind a "-" or "+" only counts as a MODDER when the catalog
# actually knows it - otherwise "-horror" would offer to hide a modder
# called horror. Genres are excluded here on purpose.
# Shared by the filter and the hint: does the catalog know a modder whose
# name contains this string? Used to decide whether "-luke ross" is one name
# or a name plus a search word.
function global:Test-KnownModderName {
    param([string]$Name)
    $n = ([string]$Name).Trim().ToLower()
    if (-not $n) { return $false }
    foreach ($g in $global:allGameData) {
        if (-not $g) { continue }
        $a = if ($g.Author) { "$($g.Author)".ToLower() } else { "" }
        if ($a -and $a.Contains($n)) { return $true }
    }
    return $false
}

# Stricter than Test-KnownModderName: used to decide whether the "hide this
# modder" box appears at all. Contains() alone matched a single letter - "-l"
# hits half the catalog - so the box popped up while the name was still being
# typed. A modder counts as MEANT only from three characters on, and only when
# a WORD of the author name starts with it ("luk" -> "Luke Ross", but "uke"
# does not).
function global:Resolve-ModderName {
    param([string]$Name)
    $n = ([string]$Name).Trim().ToLower()
    if ($n.Length -lt 3) { return $null }

    if ($n.Contains(" ")) {
        # A fragment with a space ("luke ross") cannot be a single word -
        # compare it against the start of the whole author string.
        $hits = @()
        foreach ($g in $global:allGameData) {
            if (-not $g) { continue }
            $a = if ($g.Author) { "$($g.Author)".ToLower() } else { "" }
            if (-not $a) { continue }
            $a = ($a -replace '\([^)]*\)', ' ').Trim()
            # Compare against each CREDIT, not only the whole field: a
            # two-word alias can sit in second place ("Abyss-c0re / Doom
            # Slayer"), where the field never starts with it.
            foreach ($credit in ($a -split '\s*[+/&,]\s*')) {
                $c = $credit.Trim()
                if ($c -and $c.StartsWith($n) -and ($hits -notcontains $c)) { $hits += $c }
            }
        }
        if ($hits.Count -eq 0) { return $null }
        # @() around the pipeline is not cosmetic: with ONE hit the pipeline
        # returns a plain string, and [0] on a string is its first CHARACTER.
        # That is where "Hide f permanently" came from for "-fholger".
        $sorted = @($hits | Sort-Object Length)
        $shortest = [string]$sorted[0]
        foreach ($h in $hits) { if (-not $h.StartsWith($shortest)) { return $null } }
        return $shortest
    }

    # Single word. An author field can hold SEVERAL credits ("PureDark +
    # Astienth"), and each credit can be a multi-word name ("Luke Ross").
    # So split into credits first, then into words.
    $words      = @()   # distinct matching words
    $incomplete = $false
    foreach ($g in $global:allGameData) {
        if (-not $g) { continue }
        $a = if ($g.Author) { "$($g.Author)".ToLower() } else { "" }
        if (-not $a) { continue }
        # Markers like "(auto-update)" are not part of anybody's name.
        $a = ($a -replace '\([^)]*\)', ' ').Trim()
        foreach ($credit in ($a -split '\s*[+/&,]\s*')) {
            # Hyphen, underscore and # BELONG to these names: dr-89, xen-42,
            # abyss-c0re, #yevhen4817, simply-jos. Splitting them apart left
            # a dozen modders impossible to hide.
            $cw = @($credit -split '[^a-z0-9\._#-]+' | Where-Object { $_ })
            for ($k = 0; $k -lt $cw.Count; $k++) {
                if (-not $cw[$k].StartsWith($n)) { continue }
                if ($words -notcontains $cw[$k]) { $words += $cw[$k] }
                # The word is followed by another word inside the SAME credit,
                # so it is only part of a name ("luke" of "luke ross"). Wait
                # for the rest instead of offering to hide a first name that
                # two different people share.
                if ($k -lt ($cw.Count - 1)) { $incomplete = $true }
            }
        }
    }
    # A fully typed name wins even when longer names also start with it:
    # "rayrod" is a modder in its own right next to "rayrod-tv".
    if (-not $incomplete -and ($words -contains $n)) { return $n }
    if ($incomplete) { return $null }
    # Exactly one modder name, or nothing: "astien" still fits both "astienth"
    # and "astienvr", so nothing is offered until it is unambiguous.
    if ($words.Count -eq 1) { return [string]$words[0] }
    return $null
}

function global:Get-SearchModderTerm {
    param([string]$Text, [string]$Prefix)
    $parts = @(([string]$Text).Trim().ToLower() -split '\s+' | Where-Object { $_ })
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $part = $parts[$i]
        # Prefix "" means: look at the bare words too, so typing the name
        # again - with -, with + or with nothing - brings the box back.
        $isCand = if ($Prefix) { $part.Length -gt 1 -and $part.StartsWith($Prefix) }
                  else { -not ($part.StartsWith("-") -or $part.StartsWith("+")) }
        if (-not $isCand) { continue }
        $term = if ($Prefix) { $part.Substring(1) } else { $part }
        # Attach following words first ("luke ross"), then resolve the whole
        # thing to the modder's real name.
        for ($j = $i + 1; $j -lt $parts.Count; $j++) {
            $nxt = $parts[$j]
            if ($nxt.StartsWith("-") -or $nxt.StartsWith("+")) { break }
            $cand = ($term + " " + $nxt)
            if (Test-KnownModderName -Name $cand) { $term = $cand } else { break }
        }
        $full = Resolve-ModderName -Name $term
        if (-not $full) { continue }
        return $full
    }
    return $null
}

# Examples shown INSIDE the box, one after another, while it has focus and is
# empty. Short on purpose - the pill is narrow, and anything longer gets cut
# off mid-word.
$script:SearchExamples = @("e.g. cyberpunk", "e.g. praydog", "e.g. roomscale", "e.g. free", "e.g. -horror", "e.g. -praydog")
$script:SearchExampleIx = 0
$script:SearchExampleTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:SearchExampleTimer.Interval = [TimeSpan]::FromMilliseconds(2600)
$script:SearchExampleTimer.Add_Tick({
    # Stop as soon as the box is no longer empty or lost focus - the
    # placeholder is hidden then anyway.
    if (-not $searchBox -or -not $searchBox.IsKeyboardFocusWithin -or $searchBox.Text.Length -gt 0) {
        $script:SearchExampleTimer.Stop(); return
    }
    if ($searchPlaceholder) {
        $script:SearchExampleIx = ($script:SearchExampleIx + 1) % $script:SearchExamples.Count
        $searchPlaceholder.Text = $script:SearchExamples[$script:SearchExampleIx]
    }
})

function global:Start-SearchExamples {
    if (-not $searchPlaceholder) { return }
    $script:SearchExampleIx = 0
    $searchPlaceholder.Text = $script:SearchExamples[0]
    $script:SearchExampleTimer.Start()
}
function global:Stop-SearchExamples {
    try { $script:SearchExampleTimer.Stop() } catch {}
    if ($searchPlaceholder) { $searchPlaceholder.Text = "Search" }
}

function global:Update-SearchHint {
    if (-not $searchHintHost) { return }
    if (-not $searchBox.IsKeyboardFocusWithin) {
        $searchHintHost.Visibility = [System.Windows.Visibility]::Collapsed
        return
    }
    $txt = [string]$searchBox.Text

    $minusName = Get-SearchModderTerm -Text $txt -Prefix "-"
    $plusName  = Get-SearchModderTerm -Text $txt -Prefix "+"

    if ($plusName -and ($global:HiddenModders -contains $plusName)) {
        # A hidden modder is being brought back - offer to drop them from
        # the standing list instead of only lifting them for this search.
        $script:searchHintTarget = $plusName
        $script:searchHintMode   = "unhide"
        $searchHideChk.IsChecked = $false
        $searchHideChk.Content   = "Hide $plusName permanently"
        $searchHint.Visibility      = [System.Windows.Visibility]::Collapsed
        $searchHidePanel.Visibility = [System.Windows.Visibility]::Visible
        $searchHintHost.Visibility  = [System.Windows.Visibility]::Visible
        return
    }
    $plainName = Get-SearchModderTerm -Text $txt -Prefix ""
    if (-not $minusName -and $plainName -and ($global:HiddenModders -contains $plainName)) {
        # Typing a hidden modder's name plainly: show the box ticked so it can
        # simply be un-ticked.
        $script:searchHintTarget = $plainName
        $script:searchHintMode   = "hide"
        $searchHideChk.IsChecked = $true
        $searchHideChk.Content   = "Hide $plainName permanently"
        $searchHint.Visibility      = [System.Windows.Visibility]::Collapsed
        $searchHidePanel.Visibility = [System.Windows.Visibility]::Visible
        $searchHintHost.Visibility  = [System.Windows.Visibility]::Visible
        return
    }
    if ($minusName) {
        $script:searchHintTarget = $minusName
        $script:searchHintMode   = "hide"
        $searchHideChk.IsChecked = ($global:HiddenModders -contains $minusName)
        $searchHideChk.Content   = "Hide $minusName permanently"
        $searchHint.Visibility      = [System.Windows.Visibility]::Collapsed
        $searchHidePanel.Visibility = [System.Windows.Visibility]::Visible
        $searchHintHost.Visibility  = [System.Windows.Visibility]::Visible
        return
    }
    $script:searchHintTarget = $null
    $script:searchHintMode   = "examples"
    $searchHidePanel.Visibility = [System.Windows.Visibility]::Collapsed
    $searchHint.Visibility      = [System.Windows.Visibility]::Collapsed
    $searchHintHost.Visibility  = [System.Windows.Visibility]::Collapsed
}

if ($searchHideChk) {
    $searchHideChk.Add_Click({
        $name = $script:searchHintTarget
        if (-not $name) { return }
        $list = @($global:HiddenModders)
        if ($script:searchHintMode -eq "unhide") {
            # Ticking the box here MEANS "stop hiding".
            if ($this.IsChecked) { $list = @($list | Where-Object { $_ -ne $name }) }
            elseif ($list -notcontains $name) { $list += $name }
        } else {
            if ($this.IsChecked) { if ($list -notcontains $name) { $list += $name } }
            else { $list = @($list | Where-Object { $_ -ne $name }) }
        }
        Set-HiddenModders -List $list
        Apply-Filter
        Update-SearchHint
    })
}
if ($searchBox) {
    $searchBox.Add_GotKeyboardFocus({ Start-SearchExamples; Update-SearchHint })
    $searchBox.Add_LostKeyboardFocus({
        param($sender, $e)
        # If focus moved INTO the hint panel itself, keep it open - collapsing
        # here is what used to swallow the click on the checkbox.
        try {
            $to = $e.NewFocus
            while ($to) {
                if ($to -eq $searchHintHost) { return }
                $to = [System.Windows.Media.VisualTreeHelper]::GetParent($to)
            }
        } catch {}
        Stop-SearchExamples
        if ($searchHintHost) { $searchHintHost.Visibility = [System.Windows.Visibility]::Collapsed }
    })
}

$searchBox.Add_TextChanged({
    # Typing in the search box while the description (detail) page is
    # open used to leave the detail sitting on top: the live filter ran
    # against the hidden library underneath, so nothing was visible and
    # the detail's filter-pill selection lingered. Tear the detail down
    # the same way the Back button does (Hide-DiscoverDetail ->
    # Restore-FilterPills) and reveal the filtered portrait library so
    # the search is actually visible.
    if ($this.Text.Length -gt 0 -and $global:discoverDetail -and
        $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
        if (Get-Command Hide-DiscoverDetail -ErrorAction SilentlyContinue)      { Hide-DiscoverDetail }
        if (Get-Command Build-DiscoverTiles -ErrorAction SilentlyContinue)      { Build-DiscoverTiles }
        if (Get-Command Refresh-DiscoverStatuses -ErrorAction SilentlyContinue) { Refresh-DiscoverStatuses }
        if ($global:discoverOverview) { $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($global:discoverTiles)    { $global:discoverTiles.Visibility    = [System.Windows.Visibility]::Visible }
        if ($global:discoverHost)     { $global:discoverHost.Visibility     = [System.Windows.Visibility]::Visible }
        if ($global:listScroll)       { $global:listScroll.Visibility       = [System.Windows.Visibility]::Collapsed }
        if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
        if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
        if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
        if (Get-Command Apply-LibrarySize -ErrorAction SilentlyContinue)       { Apply-LibrarySize $global:LibrarySize }
    }
    Apply-Filter
    if (Get-Command Update-SearchHint -ErrorAction SilentlyContinue) { Update-SearchHint }
    if ($searchPlaceholder) {
        $searchPlaceholder.Visibility = if ($this.Text.Length -gt 0) {
            [System.Windows.Visibility]::Collapsed
        } else {
            [System.Windows.Visibility]::Visible
        }
    }
})

# Pressing Enter while on the Explore or Detail page jumps to the
# Library (the Steam portrait list), where the live text filter
# already shows whatever the query matches. On the Library and List
# views the filter is live as you type, so Enter is a no-op there.
# This mirrors the Discover button's "show library" branch so the
# portrait tiles are built, revealed and filtered in one step.
$searchBox.Add_KeyDown({
    param($s, $e)
    if ($e.Key -ne [System.Windows.Input.Key]::Enter) { return }
    $view = if (Get-Command Get-CurrentView -ErrorAction SilentlyContinue) { Get-CurrentView } else { "List" }
    if ($view -ne "Explore" -and $view -ne "Detail") { return }
    $e.Handled = $true
    # Leave the detail/overview sub-view the same way the Back button
    # does - tear it down so Hide-DiscoverDetail -> Restore-FilterPills
    # resets the filter pills. The bare Visibility flip below collapsed
    # the detail but skipped this, so the description's pill selection
    # lingered. (The forced-tiles block right after still lands us on
    # the filtered library, overriding the origin view Hide returns to.)
    if ($global:discoverDetail -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
        if (Get-Command Hide-DiscoverDetail -ErrorAction SilentlyContinue) { Hide-DiscoverDetail }
    } elseif ($global:discoverOverview -and $global:discoverOverview.Visibility -eq [System.Windows.Visibility]::Visible) {
        if (Get-Command Hide-DiscoverOverview -ErrorAction SilentlyContinue) { Hide-DiscoverOverview }
    }
    if (Get-Command Build-DiscoverTiles -ErrorAction SilentlyContinue)      { Build-DiscoverTiles }
    if (Get-Command Refresh-DiscoverStatuses -ErrorAction SilentlyContinue) { Refresh-DiscoverStatuses }
    if ($global:discoverDetail)   { $global:discoverDetail.Visibility   = [System.Windows.Visibility]::Collapsed }
    if ($global:discoverOverview) { $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed }
    if ($global:discoverTiles)    { $global:discoverTiles.Visibility    = [System.Windows.Visibility]::Visible }
    if ($global:discoverHost)     { $global:discoverHost.Visibility     = [System.Windows.Visibility]::Visible }
    if ($global:listScroll)       { $global:listScroll.Visibility       = [System.Windows.Visibility]::Collapsed }
    if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
    if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
    if (Get-Command Apply-Filter -ErrorAction SilentlyContinue)            { Apply-Filter }
    if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
    if (Get-Command Apply-LibrarySize -ErrorAction SilentlyContinue)       { Apply-LibrarySize $global:LibrarySize }
})

# --- Check Installed ---
$checkInstalledBtn  = $window.FindName("CheckInstalledBtn")
$checkInstalledText = $window.FindName("CheckInstalledText")
$checkInstalledCount      = $window.FindName("CheckInstalledCount")
$checkInstalledCountInst  = $window.FindName("CheckInstalledCountInst")
$checkInstalledCountReady = $window.FindName("CheckInstalledCountReady")
$checkInstalledCountSep   = $window.FindName("CheckInstalledCountSep")
$checkInstalledShimmer    = $window.FindName("CheckInstalledShimmer")
$checkInstalledShimmerXf  = $window.FindName("CheckInstalledShimmerXf")

# Permanent green halo on the counter button. DropShadowEffect with
# no offset = soft outer glow. Pre-scan state ("Check Installed"
# text) gets a dimmed halo - the button is interesting but doesn't
# scream for attention; Invoke-CheckInstalledScan promotes it to
# the full eye-catcher halo after the scan completes. WPF can't
# stack multiple drop shadows like CSS, so we go with a single
# blur and just animate its intensity between the two states.
$ciGlow = New-Object System.Windows.Media.Effects.DropShadowEffect
$ciGlow.Color       = [System.Windows.Media.Color]::FromRgb(74, 222, 128)
$ciGlow.BlurRadius  = 8
$ciGlow.ShadowDepth = 0
$ciGlow.Opacity     = 0.25
$checkInstalledBtn.Effect = $ciGlow

# Periodic shimmer sweep on the counter button.
# Timing:
#   - 1.5s sweep from left edge to past right edge
#   - random 12-60s pause (no movement, parked off-screen right)
#   - then repeats with a fresh random pause each cycle
# Why randomised pause: a fixed 13s interval reads as mechanical/
# clock-like. Varying the pause per cycle keeps the effect feeling
# alive without ever being obtrusive.
# Implementation: single-shot DoubleAnimation on the Transform,
# whose Completed event arms a DispatcherTimer with a random
# interval, which on tick re-runs the sweep. Simple loop.
# An earlier version used RepeatBehavior::Forever with a fixed
# 14.5s key-framed animation - works but pauses are identical
# every cycle, which is exactly what we're moving away from.
#
# Range: X from -100 (hidden off the left edge) to 300 (well past
# the right edge - the shimmer Border is Width=80, and even a wide
# counter button is comfortably under 220px). The TranslateTransform
# is built fresh in code rather than declared in XAML because a
# XAML-parser-frozen Transform silently refuses animations on its
# properties in some WPF versions.
#
# The shimmer Border itself starts with Visibility=Collapsed (set
# in Window.ps1). Invoke-CheckInstalledScan flips it to Visible
# once the counter takes over from the "Check Installed" label.
# The animation loop runs unconditionally though - cheap to leave
# ticking, and the moment the user does their first scan the
# shimmer is already in sync.
$shimmerTx = New-Object System.Windows.Media.TranslateTransform
$shimmerTx.X = -100
$checkInstalledShimmer.RenderTransform = $shimmerTx
$checkInstalledShimmerXf = $shimmerTx

$shimmerRand = New-Object System.Random
$shimmerPauseTimer = New-Object System.Windows.Threading.DispatcherTimer

# Build the sweep animation once and reuse it. Beginning a fresh
# animation each cycle reseats X to -100 automatically via the
# KeyFrame at t=0.
$shimmerSweep = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
$shimmerSweep.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(1500))
$kfS0 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame -100.0, ([System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(0)))
$kfS1 = New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame  300.0, ([System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(1500)))
[void]$shimmerSweep.KeyFrames.Add($kfS0)
[void]$shimmerSweep.KeyFrames.Add($kfS1)

# On sweep completion: park X at 300, arm the pause timer with a
# fresh random 12-60s interval, and wait for tick.
$shimmerSweep.Add_Completed({
    $shimmerTx.BeginAnimation(
        [System.Windows.Media.TranslateTransform]::XProperty,
        $null
    )
    $shimmerTx.X = 300
    $pauseMs = $shimmerRand.Next(12000, 60001)  # 12.000-60.000 ms inclusive
    $shimmerPauseTimer.Interval = [TimeSpan]::FromMilliseconds($pauseMs)
    $shimmerPauseTimer.Start()
}.GetNewClosure())

# On pause-timer tick: stop the timer, kick off another sweep.
$shimmerPauseTimer.Add_Tick({
    $shimmerPauseTimer.Stop()
    $shimmerTx.BeginAnimation(
        [System.Windows.Media.TranslateTransform]::XProperty,
        $shimmerSweep
    )
}.GetNewClosure())

# Kick off the first sweep immediately. From here the Completed ->
# pause-timer -> Tick -> sweep loop runs forever.
$shimmerTx.BeginAnimation(
    [System.Windows.Media.TranslateTransform]::XProperty,
    $shimmerSweep
)

# --- Shimmer opt-out (session + persistent) ---
# Dwell over the counter for 5s and a small overlay appears with
# two chips: "Disable shimmer" (session only) and "Always Disable"
# (writes shimmerDisabled=true to hub-settings.json). Same idiom
# as the banner / recently-played hover overlays.
# script:shimmerDisabled is the session-level flag; reads from the
# persisted setting at startup and can be flipped to true mid-
# session by the user. Invoke-CheckInstalledScan checks this
# before promoting the shimmer to Visible.
$script:shimmerDisabled = $false
if (Get-Command Get-HubSetting -ErrorAction SilentlyContinue) {
    $script:shimmerDisabled = [bool](Get-HubSetting -Key "shimmerDisabled" -Default $false)
}
$shimmerDisableOverlay  = $window.FindName("ShimmerDisableOverlay")
$shimmerDisableBtn      = $window.FindName("ShimmerDisableBtn")
$shimmerAlwaysDisableBtn= $window.FindName("ShimmerAlwaysDisableBtn")

if ($shimmerDisableOverlay -and $shimmerDisableBtn -and $shimmerAlwaysDisableBtn) {
    $sdShowTimer = New-Object System.Windows.Threading.DispatcherTimer
    $sdShowTimer.Interval = [TimeSpan]::FromSeconds(5)
    $sdHideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $sdHideTimer.Interval = [TimeSpan]::FromMilliseconds(800)

    $sdShowTimer.Add_Tick({
        $sdShowTimer.Stop()
        # Only reveal if the shimmer is actually running (i.e. the
        # counter has taken over from "Check Installed"). Otherwise
        # offering to disable a non-running effect is pointless and
        # confusing.
        if ($checkInstalledShimmer -and
            $checkInstalledShimmer.Visibility -eq [System.Windows.Visibility]::Visible) {
            $shimmerDisableOverlay.Visibility = [System.Windows.Visibility]::Visible
        }
    }.GetNewClosure())

    $sdHideTimer.Add_Tick({
        $sdHideTimer.Stop()
        $shimmerDisableOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())

    # Dwell trigger: only count time when the counter is showing
    # the post-scan state. During "Check Installed" the shimmer
    # isn't running so there's nothing to opt out of.
    $checkInstalledBtn.Add_MouseEnter({
        $sdHideTimer.Stop()
        if (-not $checkInstalledShimmer) { return }
        if ($checkInstalledShimmer.Visibility -ne [System.Windows.Visibility]::Visible) { return }
        if ($shimmerDisableOverlay.Visibility -ne [System.Windows.Visibility]::Visible) {
            $sdShowTimer.Stop()
            $sdShowTimer.Start()
        }
    }.GetNewClosure())

    $checkInstalledBtn.Add_MouseLeave({
        $sdShowTimer.Stop()
        if ($shimmerDisableOverlay.Visibility -eq [System.Windows.Visibility]::Visible) {
            $sdHideTimer.Stop()
            $sdHideTimer.Start()
        }
    }.GetNewClosure())

    # MouseEnter on overlay itself cancels the hide-timer so the
    # cursor can travel across the button -> overlay gap without
    # the overlay vanishing.
    $shimmerDisableOverlay.Add_MouseEnter({
        $sdHideTimer.Stop()
    }.GetNewClosure())
    $shimmerDisableOverlay.Add_MouseLeave({
        $sdHideTimer.Stop()
        $sdHideTimer.Start()
    }.GetNewClosure())

    # "Disable shimmer" = hide it for this session only. Animation
    # keeps ticking under the hood (cheap, harmless) so a future
    # re-enable would just need Visibility=Visible. We also stop
    # the overlay's own timers and hide it.
    $shimmerDisableBtn.Add_MouseLeftButtonUp({
        if ($checkInstalledShimmer) {
            $checkInstalledShimmer.Visibility = [System.Windows.Visibility]::Collapsed
        }
        $script:shimmerDisabled = $true
        $shimmerDisableOverlay.Visibility = [System.Windows.Visibility]::Collapsed
        $sdShowTimer.Stop()
        $sdHideTimer.Stop()
    }.GetNewClosure())
    $shimmerDisableBtn.Add_MouseEnter({
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    })
    $shimmerDisableBtn.Add_MouseLeave({
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
    })

    # "Always Disable" = same plus persist to hub-settings so the
    # next launch starts without the shimmer entirely.
    $shimmerAlwaysDisableBtn.Add_MouseLeftButtonUp({
        if ($checkInstalledShimmer) {
            $checkInstalledShimmer.Visibility = [System.Windows.Visibility]::Collapsed
        }
        $script:shimmerDisabled = $true
        $shimmerDisableOverlay.Visibility = [System.Windows.Visibility]::Collapsed
        $sdShowTimer.Stop()
        $sdHideTimer.Stop()
        if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
            Set-HubSetting -Key "shimmerDisabled" -Value $true
        }
    }.GetNewClosure())
    $shimmerAlwaysDisableBtn.Add_MouseEnter({
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    })
    $shimmerAlwaysDisableBtn.Add_MouseLeave({
        $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48")
    })
}

# Glow hover for Check Installed. Same green accent the button
# itself uses so it reads as part of its identity. The hover is
# harmless during the post-click pulse animation since the helper
# only modifies BorderBrush + Foreground; the pulse drives
# Background.
Add-GlowHover -Border $checkInstalledBtn -AccentHex "#5aa880"

# Build a card->game lookup - wrapped in function so Scale can rebuild it
function global:Rebuild-Lookups {
    $global:allCards    = @()
    $global:allGameData = @()
    foreach ($child in $ownList.Children)   { $global:allCards += $child }
    foreach ($child in $ownListGP.Children) { $global:allCards += $child }
    foreach ($child in $extList.Children)   { $global:allCards += $child }
    foreach ($g in $ownGames)               { $global:allGameData += $g }
    foreach ($g in $ownGamesGP)             { $global:allGameData += $g }
    foreach ($g in $externalGames)          { $global:allGameData += $g }

    $global:cardGameMap = @{}
    $ownAndGPGames = @()
    foreach ($g in $ownGames)   { $ownAndGPGames += $g }
    foreach ($g in $ownGamesGP) { $ownAndGPGames += $g }
    $ownCards = @(); foreach ($ch in $ownList.Children)   { $ownCards += $ch }
    $gpCards  = @(); foreach ($ch in $ownListGP.Children) { $gpCards  += $ch }
    $allOwnCards = $ownCards + $gpCards
    for ($i = 0; $i -lt [Math]::Min($allOwnCards.Count, $ownAndGPGames.Count); $i++) {
        $global:cardGameMap[$allOwnCards[$i]] = $ownAndGPGames[$i]
    }
    $extCards = @(); foreach ($ch in $extList.Children) { $extCards += $ch }
    for ($i = 0; $i -lt [Math]::Min($extCards.Count, $externalGames.Count); $i++) {
        $global:cardGameMap[$extCards[$i]] = $externalGames[$i]
    }

    # Restore visual state from gameStateMap onto new cards.
    # We don't store brushes in the map (they're tied to disposed
    # cards) - we store the accent + state name and rebuild brushes
    # here using the same helpers that initial card creation uses.
    if ($global:gameStateMap -and $global:gameStateMap.Count -gt 0) {
        foreach ($card in $global:cardGameMap.Keys) {
            $g = $global:cardGameMap[$card]
            if (-not $g.Title) { continue }
            $state = $global:gameStateMap[$g.Title]
            if (-not $state) { continue }
            $card.Tag = $state.Tag
            $accH = if ($state.Accent) { $state.Accent } else { $card.Resources.Item("baseAccent") }
            if (-not $accH) { $accH = "#666677" }
            $btnTxt = $card.Resources.Item("btnText")
            $btnBrd = $card.Resources.Item("btnBorder")
            $card.Effect = $null

            switch ($state.State) {
                "update" {
                    # Update state: unified blue (#2563eb), regardless of accent.
                    $UPDATE_BLUE = "#2563eb"
                    $card.Background = New-CardTintBrush -BaseHex "#16161a" -TintHex $UPDATE_BLUE -TopAlpha 0.22 -MidAlpha 0.05
                    $aA = ConvertTo-MediaColor $UPDATE_BLUE; $aB = ConvertTo-MediaColor "#16161a"
                    $card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(
                        [byte]([Math]::Round($aA.R*0.40 + $aB.R*0.60)),
                        [byte]([Math]::Round($aA.G*0.40 + $aB.G*0.60)),
                        [byte]([Math]::Round($aA.B*0.40 + $aB.B*0.60))
                    ))
                    $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
                    $glow.Color = $aA; $glow.BlurRadius = 16; $glow.ShadowDepth = 0; $glow.Opacity = 0.55
                    $card.Effect = $glow
                    if ($btnTxt) {
                        $btnTxt.Text = "Update"
                        $btnTxt.Foreground = [System.Windows.Media.Brushes]::White
                    }
                    if ($btnBrd) {
                        $btnBrd.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($UPDATE_BLUE)
                        $btnBrd.BorderThickness = [System.Windows.Thickness]::new(0)
                    }
                    # Cap matches the update theme: blue, visible.
                    $cap = $card.Resources.Item("accentCap")
                    if ($cap) {
                        $cap.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($UPDATE_BLUE)
                        $cap.Visibility = [System.Windows.Visibility]::Visible
                    }
                    # Refresh resources so hover tint matches the new
                    # state. Without these the rebuilt card would
                    # hover in its original accent color, not blue.
                    $card.Resources.Remove("baseBgBrush") | Out-Null
                    $card.Resources.Remove("baseBdBrush") | Out-Null
                    $card.Resources.Add("baseBgBrush", $card.Background)
                    $card.Resources.Add("baseBdBrush", $card.BorderBrush)
                    $card.Resources.Remove("baseAccent") | Out-Null
                    $card.Resources.Add("baseAccent", $UPDATE_BLUE)
                }
                "ready" {
                    $card.Background = New-CardTintBrush -BaseHex "#16161a" -TintHex "#46a05a" -TopAlpha 0.10 -MidAlpha 0.02
                    $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1d2e22")
                    if ($btnTxt) {
                        $btnTxt.Text = "VR Ready"
                        $btnTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
                    }
                    $fblR = $card.Resources.Item("freeBtnLabel")
                    if ($fblR) { $fblR.Visibility = [System.Windows.Visibility]::Collapsed }
                    if ($btnBrd) {
                        $btnBrd.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
                        $btnBrd.BorderThickness = [System.Windows.Thickness]::new(1)
                        $btnBrd.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
                    }
                    # VR Ready is complete - no "action pending"
                    # signal; hide the cap. Without this, a card
                    # repainted via Rebuild-Lookups (single-game
                    # refresh, post-install refresh) would keep the
                    # cap from its previous default state and show
                    # an accent stripe alongside the green Ready
                    # outline.
                    $cap = $card.Resources.Item("accentCap")
                    if ($cap) { $cap.Visibility = [System.Windows.Visibility]::Collapsed }
                }
                default {
                    # "installed": game found, no VR mod yet - blue tint
                    if ($state.Tag -eq "installed") {
                        $conv3 = [System.Windows.Media.BrushConverter]::new()
                        $card.Background  = New-CardTintBrush -BaseHex "#16161a" -TintHex "#46a05a" -TopAlpha 0.18 -MidAlpha 0.06
                        $card.BorderBrush = $conv3.ConvertFromString("#2a5c38")
                        $card.BorderThickness = [System.Windows.Thickness]::new(1)
                        if ($btnTxt) {
                            if ($state.BtnText) { $btnTxt.Text = $state.BtnText }
                            $btnTxt.Foreground = $conv3.ConvertFromString("#66dd88")
                        }
                        if ($btnBrd) {
                            $btnBrd.Background      = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
                            $btnBrd.BorderThickness = [System.Windows.Thickness]::new(1)
                            $btnBrd.BorderBrush     = $conv3.ConvertFromString("#2a5c38")
                        }
                        # Cap in matching green to signal "action
                        # available: install the VR mod".
                        $cap = $card.Resources.Item("accentCap")
                        if ($cap) {
                            $cap.Background = $conv3.ConvertFromString("#5cb344")
                            $cap.Visibility = [System.Windows.Visibility]::Visible
                        }
                    } else {
                        if ($btnTxt -and $state.BtnText) { $btnTxt.Text = $state.BtnText }
                        # Free games: restore the accent glow + reveal the
                        # FREE label on the button (matches the scan's
                        # free-state painting so filter switches don't drop
                        # it).
                        if ($state.Tag -eq "free") {
                            try {
                                $glowAccP = if ($state.Accent) { $state.Accent } else { $card.Resources.Item("baseAccent") }
                                $card.Effect = $null
                                $card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush (Get-GlowColor $glowAccP)
                                $card.BorderThickness = [System.Windows.Thickness]::new(1)
                                $fblP = $card.Resources.Item("freeBtnLabel")
                                if ($fblP) { $fblP.Visibility = [System.Windows.Visibility]::Visible }
                            } catch {}
                        }
                    }
                }
            }
            Sync-FrostedCardState -Card $card -BtnTxt $btnTxt -BtnBrd $btnBrd
            # Refresh stored brushes so hover reflects current state
            if ($card.Resources.Contains("baseBgBrush")) { $card.Resources.Remove("baseBgBrush") }
            if ($card.Resources.Contains("baseBdBrush")) { $card.Resources.Remove("baseBdBrush") }
            $card.Resources.Add("baseBgBrush", $card.Background)
            $card.Resources.Add("baseBdBrush", $card.BorderBrush)
        }
    }
}
$global:gameStateMap = @{}  # title -> @{Tag; BgColor; BorderColor; BtnText; BtnColor}
Rebuild-Lookups

# Reusable scan logic. Used by:
#   - the Check Installed button click (PreviewMouseLeftButtonDown)
#   - the post-install auto-refresh (Invoke-PostInstallRefresh)
# Side-effects: rebuilds $global:gameStateMap, repaints all cards,
# and updates the status pill text.

# TwoMods presence probe - which of a two-mod entry's launchers are on
# disk, and where. Shared on purpose: the full scan AND the post-install
# refresh both need it. Before this existed the refresh wrote a minimal
# state entry without any TwoMods fields, so a freshly installed two-mod
# game showed a single button until the Hub was restarted.
function global:Get-TwoModsPresence {
    param($Game, [string]$FallbackRoot)
    $res = @{ APresent = $false; BPresent = $false; ADir = $null; BDir = $null; Root = $null }
    if (-not $Game -or -not $Game.TwoMods) { return $res }
    # The recorded .installed_path is the precise answer - but it lives in
    # the HUB folder, so a fresh Hub (or one installed next to an older
    # one) has none even though the mods are sitting in the game folder.
    # In that case fall back to the folder the scan already resolved, so
    # an install made by another Hub still shows both mods instead of a
    # single button.
    $root = $null
    $ipf = Get-InstalledPathFile -Game $Game
    if ($ipf -and (Test-Path $ipf)) {
        try { $root = Read-InstalledPath -Game $Game } catch {}
    }
    if ((-not $root) -and $FallbackRoot) {
        try { if (Test-Path -LiteralPath $FallbackRoot) { $root = $FallbackRoot } } catch {}
    }
    if (-not $root -or -not (Test-Path $root)) { return $res }
    $res.Root = $root
    # Each mod's launcher lives somewhere under its subfolder - searched
    # RECURSIVELY so a mod that unpacked one level deeper still counts.
    if ($Game.ModASub -and $Game.ModALaunch) {
        $subA = Join-Path $root $Game.ModASub
        if (Test-Path $subA) {
            $hitA = Get-ChildItem -Path $subA -Filter $Game.ModALaunch -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hitA) { $res.APresent = $true; $res.ADir = (Split-Path -Parent $hitA.FullName) }
        }
    }
    if ($Game.ModBSub -and $Game.ModBLaunch) {
        $subB = Join-Path $root $Game.ModBSub
        if (Test-Path $subB) {
            $hitB = Get-ChildItem -Path $subB -Filter $Game.ModBLaunch -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hitB) { $res.BPresent = $true; $res.BDir = (Split-Path -Parent $hitB.FullName) }
        }
    }
    return $res
}

# DualMode presence probe - are BOTH the pinned-depot build and a current
# Steam-library build modded? Shared for the same reason as the TwoMods
# probe above: the full scan and the post-install refresh must agree, or
# the split button disappears until the Hub is restarted.
# $Libs is optional - the scan already has its library list and passes it
# in; the refresh has none and lets the function look them up itself.
function global:Get-DualModePresence {
    param($Game, $Libs)
    $res = @{ BothPresent = $false; CurrentDir = $null; DepotDir = $null }
    if (-not $Game -or -not $Game.DualMode -or -not $Game.DepotPath -or -not $Game.ModFile) { return $res }
    # THE TWO SIDES DO NOT ALWAYS CARRY THE SAME MOD FILE. This used to
    # test ModFile in both places, which only works when it is one mod on
    # two builds (Bendy, REPO). PEAK is two DIFFERENT mods: the current
    # PeakVR by Andrey04o lives in the Steam copy, while the older PEAK_VR
    # by AstienVR only ever exists in the pinned depot build - so the depot
    # folder was searched for a file that can never be there, BothPresent
    # stayed false, and the split button never appeared no matter what was
    # installed. Each side now counts if EITHER of the entry's two mod
    # files is present. For entries where ModFileAlt is just the parked
    # "disabled" name, that reads correctly too: the mod IS installed.
    $relList = @($Game.ModFile)
    if ($Game.ModFileAlt) { $relList += $Game.ModFileAlt }
    # Nicht nur der Katalogpfad: der Nutzer darf den Depot-Ordner frei
    # waehlen, und der Installer hat den gewaehlten aufgezeichnet.
    $depotDir = $null
    foreach ($cand in (Get-DepotCandidatePaths -Game $Game)) {
        foreach ($rel in $relList) {
            if (Test-Path (Join-Path $cand $rel)) { $depotDir = $cand; break }
        }
        if ($depotDir) { break }
    }
    if (-not $depotDir) { return $res }
    if (-not $Game.SteamFolder) { return $res }
    if (-not $Libs -or $Libs.Count -eq 0) {
        $Libs = @()
        $sp = $null
        foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
            try { $p = (Get-ItemProperty -Path $reg -EA Stop).InstallPath; if ($p -and (Test-Path $p)) { $sp = $p; break } } catch {}
        }
        if ($sp) {
            $Libs += $sp
            $vdf = Join-Path $sp "steamapps\libraryfolders.vdf"
            if (Test-Path $vdf) {
                [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
                    $l = $_.Groups[1].Value -replace '\\\\', '\'; if (Test-Path $l) { $Libs += $l }
                }
            }
        }
    }
    foreach ($lib in $Libs) {
        $c = Join-Path $lib "steamapps\common\$($Game.SteamFolder)"
        if (-not (Test-Path $c)) { continue }
        $currentHit = $false
        foreach ($rel in $relList) {
            if (Test-Path (Join-Path $c $rel)) { $currentHit = $true; break }
        }
        if ($currentHit) {
            $res.BothPresent = $true
            $res.CurrentDir  = $c
            $res.DepotDir    = $depotDir
            break
        }
    }
    return $res
}

# Online state for the scan's per-game version checks. Once the server
# is found unreachable we stop probing for the rest of the session; an
# explicit Check Installed click clears it to probe fresh again.
$global:HubScanOnlineDown = $false

# Single bounded online GET for the scan's per-game version checks.
# Circuit breaker: once the server is unreachable we retry ONCE after
# a 3s wait; if that also fails we flip $global:HubScanOnlineDown and
# every later call returns $null immediately - so the scan can never
# grind on dozens of back-to-back timeouts. Returns the response or $null.
function global:Invoke-ScanWebGet {
    param([string]$Uri, [hashtable]$Headers)
    if ($global:HubScanOnlineDown) { return $null }
    try {
        if ($Headers) {
            return (Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 2 -Headers $Headers -EA Stop)
        } else {
            return (Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 2 -EA Stop)
        }
    } catch {
        # First miss: assume the server/network is unreachable and stop
        # ALL further online checks for the rest of the scan. No retry,
        # no sleep - a slow or dead server must never freeze the UI
        # thread. Worst case is one ~2s timeout for the whole scan.
        $global:HubScanOnlineDown = $true
        return $null
    }
}

function global:Get-CodebergLatestTagCached {
    # Wie Get-GithubLatestTagCached, nur fuer Codeberg. Codeberg laeuft auf
    # FORGEJO und hat dieselbe API-Form wie Gitea:
    #   https://codeberg.org/api/v1/repos/<owner>/<repo>/releases?limit=1
    # Das erste Element traegt tag_name. Anders als bei GitHub gibt es kein
    # enges 60/Stunde-Limit, deshalb steht hier die API VORNE und der
    # RSS-Feed (/releases.rss, ebenfalls von Forgejo bereitgestellt) ist nur
    # der Rueckfall.
    #
    # Eigene Cache-Datei .cb_version_cache, damit sich Codeberg- und
    # GitHub-Schluessel nie in die Quere kommen. Gleiche TTL von 6 Stunden,
    # gleiches Verhalten bei Fehlern: der ZULETZT bekannte Tag wird
    # zurueckgegeben, damit der Update-Zustand stabil bleibt.
    param([string]$Repo, [switch]$IncludePrerelease)
    if (-not $Repo) { return $null }
    $cacheKey = if ($IncludePrerelease) { "$Repo#pre" } else { $Repo }
    $ttlHours = 6
    if ($null -eq $script:cbVerCache) {
        $script:cbVerCache = @{}
        $script:cbVerCacheFile = Join-Path $global:scriptDir ".cb_version_cache"
        if (Test-Path $script:cbVerCacheFile) {
            try {
                $raw = Get-Content $script:cbVerCacheFile -Raw | ConvertFrom-Json
                foreach ($p in $raw.PSObject.Properties) {
                    $script:cbVerCache[$p.Name] = @{ tag = [string]$p.Value.tag; checked = [string]$p.Value.checked }
                }
            } catch {}
        }
    }
    $entry = $script:cbVerCache[$cacheKey]
    $now = [DateTime]::UtcNow
    if ($entry -and $entry.tag -and $entry.checked) {
        try {
            $age = ($now - [DateTime]::Parse($entry.checked, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).TotalHours
            if ($age -lt $ttlHours) { return [string]$entry.tag }
        } catch {}
    }
    # Dieselbe Sicherung wie bei GitHub: ist eine fruehere Onlinepruefung in
    # DIESEM Scan schon gescheitert, wird das Netz nicht noch einmal
    # angefasst - sonst stapeln sich Zeitueberschreitungen zu einem langen
    # Einfrieren der Oberflaeche.
    if ($global:HubScanOnlineDown -or $global:HubVersionCacheOnly) {
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
    $tag = $null
    try {
        $rel = Invoke-RestMethod -Uri "https://codeberg.org/api/v1/repos/$Repo/releases?limit=5" `
                   -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 3 -EA Stop 2>$null
        foreach ($r in @($rel)) {
            if ($r.draft) { continue }
            if ($r.prerelease -and -not $IncludePrerelease) { continue }
            if ($r.tag_name) { $tag = [string]$r.tag_name.Trim(); break }
        }
    } catch {
        Write-Host "[CodebergCheck] $Repo : API-Pruefung fehlgeschlagen ($($_.Exception.Message)) - versuche den RSS-Feed"
    }
    if (-not $tag) {
        try {
            $rssResp = Invoke-WebRequest -Uri "https://codeberg.org/$Repo/releases.rss" `
                           -UseBasicParsing -TimeoutSec 3 `
                           -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" } -EA Stop
            $rss = [string]$rssResp.Content
            if ($rss) {
                # Forgejo setzt den Tag in die <link>-Adresse des Eintrags:
                #   https://codeberg.org/<owner>/<repo>/releases/tag/<tag>
                $m = [regex]::Match($rss, [regex]::Escape($Repo) + '/releases/tag/([^<"&]+)')
                if ($m.Success) {
                    $t = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value).Trim()
                    if ($t) { $tag = $t }
                }
            }
        } catch {
            Write-Host "[CodebergCheck] $Repo : auch der RSS-Feed ging nicht ($($_.Exception.Message))"
            # Nur ein echter Verbindungsfehler darf den Scan-weiten Schalter
            # umlegen - eine Begrenzung bedeutet, der Rechner ist erreichbar.
            if ($_.Exception.Message -notmatch "rate limit|403|forbidden") { $global:HubScanOnlineDown = $true }
        }
    }
    if ($tag) {
        $script:cbVerCache[$cacheKey] = @{ tag = $tag; checked = $now.ToString("o") }
        try {
            $obj = @{}
            foreach ($k in $script:cbVerCache.Keys) { $obj[$k] = $script:cbVerCache[$k] }
            ($obj | ConvertTo-Json) | Set-Content -Path $script:cbVerCacheFile -Encoding UTF8 -Force
        } catch {}
        return $tag
    }
    if ($entry -and $entry.tag) { return [string]$entry.tag }
    return $null
}

function global:Get-GithubLatestTagCached {
    # Return the latest GitHub release tag for $Repo, cached on disk with a TTL
    # so repeated scans/restarts do not exhaust the 60/hour unauthenticated
    # GitHub API limit. On a rate-limit or transient error the LAST known tag is
    # returned (so the update state stays stable) and the shared online-down
    # flag is NOT tripped - a 403 means the host is reachable, just limited, and
    # must not kill the other checks (Alien Isolation web check, other repos).
    #
    # -IncludePrerelease: some mods only ship PRE-releases (e.g. Halo MCC VR is
    # an alpha). GitHub's /releases/latest redirect ignores prereleases, so for
    # those repos it 404s and we would never see an update. When this switch is
    # set we instead read the newest entry from the GitHub API /releases list
    # (which includes prereleases) and use its tag. Cached under a distinct key
    # so it never collides with a normal /latest lookup of the same repo.
    param([string]$Repo, [switch]$IncludePrerelease)
    if (-not $Repo) { return $null }
    $cacheKey = if ($IncludePrerelease) { "$Repo#pre" } else { $Repo }
    $ttlHours = 6
    if ($null -eq $script:ghVerCache) {
        $script:ghVerCache = @{}
        $script:ghVerCacheFile = Join-Path $global:scriptDir ".gh_version_cache"
        if (Test-Path $script:ghVerCacheFile) {
            try {
                $raw = Get-Content $script:ghVerCacheFile -Raw | ConvertFrom-Json
                foreach ($p in $raw.PSObject.Properties) {
                    $script:ghVerCache[$p.Name] = @{ tag = [string]$p.Value.tag; checked = [string]$p.Value.checked }
                }
            } catch {}
        }
    }
    $entry = $script:ghVerCache[$cacheKey]
    $now = [DateTime]::UtcNow
    if ($entry -and $entry.tag -and $entry.checked) {
        try {
            $age = ($now - [DateTime]::Parse($entry.checked, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).TotalHours
            if ($age -lt $ttlHours) { return [string]$entry.tag }
        } catch {}
    }
    # Respect the scan-wide circuit breaker: if an earlier online check in
    # THIS scan already failed/timed out, do NOT touch the network again -
    # fall straight back to the last known tag (or null). This is what stops
    # an unreachable github.com (firewall/DNS) from stacking a per-repo
    # connection timeout into a multi-minute UI-thread freeze on a first run
    # with an empty cache: the first miss trips the breaker, the rest skip.
    if ($global:HubScanOnlineDown -or $global:HubVersionCacheOnly) {
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
    $tag = $null
    if ($IncludePrerelease) {
        # Prerelease-aware path, WEBSITE FIRST: <repo>/releases.atom is served by
        # github.com, not by the API, so it has NO 60/hour limit - and it lists
        # prereleases, newest first. Each entry carries the tag in its <id> as
        #   tag:github.com,2008:Repository/<repoId>/<tag>
        # Verified against four repos in this Hub, including prerelease-only
        # ones (witcher3-vr -> v0.9.0-alpha.1, fear-vr -> v1.0.0-beta.7) and
        # normal ones (anvilengine2vr -> v2.0.0.Public, REFramework-nightly).
        # The API stays as the fallback below.
        # Deliberately NOT via Invoke-ScanWebGet: that helper trips the
        # scan-wide online-down breaker on any failure, and a missing atom
        # feed must not kill the rest of the scan - the API fallback right
        # below still has a chance.
        try {
            $atomResp = Invoke-WebRequest -Uri "https://github.com/$Repo/releases.atom" `
                            -UseBasicParsing -TimeoutSec 3 `
                            -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" } -EA Stop
            $atom = [string]$atomResp.Content
            if ($atom) {
                $m = [regex]::Match($atom, 'Repository/[0-9]+/([^<]+)')
                if ($m.Success) {
                    $t = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value).Trim()
                    if ($t) { $tag = $t }
                }
            }
        } catch {
            Write-Host "[GithubCheck] $Repo (prerelease) : atom feed failed ($($_.Exception.Message)) - trying the API"
        }
        if (-not $tag) {
          try {
            $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases?per_page=1" -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 2 -EA Stop 2>$null
            $first = $rel | Select-Object -First 1
            if ($first -and $first.tag_name) { $tag = [string]$first.tag_name.Trim() }
        } catch {
            Write-Host "[GithubCheck] $Repo (prerelease) : API check failed ($($_.Exception.Message)) - using cached tag if present"
            # A 403 (rate limit) means the host is reachable - do NOT trip the
            # scan-wide breaker. Only a genuine connection failure should.
            if ($_.Exception.Message -notmatch "rate limit|403|forbidden") { $global:HubScanOnlineDown = $true }
            if ($entry -and $entry.tag) { return [string]$entry.tag }
            return $null
          }
        }
        if ($tag) {
            $script:ghVerCache[$cacheKey] = @{ tag = $tag; checked = $now.ToString("o") }
            try {
                $obj = @{}
                foreach ($k in $script:ghVerCache.Keys) { $obj[$k] = $script:ghVerCache[$k] }
                ($obj | ConvertTo-Json) | Set-Content -Path $script:ghVerCacheFile -Encoding UTF8 -Force
            } catch {}
            return $tag
        }
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
    # Use the github.com /releases/latest REDIRECT (web, not the API). It 302s
    # to /releases/tag/<tag>, so the tag is in the final URL - and the website
    # is NOT bound by the 60/hour unauthenticated API limit that the api.github
    # endpoint enforces. HEAD only, so no page body is downloaded. 2>$null keeps
    # a rare transient error out of the Hub transcript.
    $tag = $null
    try {
        $resp = Invoke-WebRequest -Uri "https://github.com/$Repo/releases/latest" -Method Head -UseBasicParsing -TimeoutSec 2 -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" } -EA Stop 2>$null
        $final = ""
        # Windows PowerShell 5.1 exposes the final URL as BaseResponse.ResponseUri;
        # PowerShell 7 has no such property and uses RequestMessage.RequestUri
        # instead. Reading only the 5.1 name made this fail silently on 7.
        try { $final = [string]$resp.BaseResponse.ResponseUri.AbsoluteUri } catch {}
        if (-not $final) { try { $final = [string]$resp.BaseResponse.RequestMessage.RequestUri.AbsoluteUri } catch {} }
        if (-not $final -and $resp.Headers.Location) { $final = [string]$resp.Headers.Location }
        if ($final -match '/releases/tag/([^/?#]+)') { $tag = [System.Uri]::UnescapeDataString($matches[1]).Trim() }
    } catch {
        Write-Host "[GithubCheck] $Repo : web check failed ($($_.Exception.Message)) - using cached tag if present"
        # A timeout / connection failure means github.com is unreachable or
        # too slow. Trip the scan-wide breaker so the remaining repos this
        # scan skip the network instead of each eating another timeout.
        $global:HubScanOnlineDown = $true
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
    if ($tag) {
        $script:ghVerCache[$cacheKey] = @{ tag = $tag; checked = $now.ToString("o") }
        try {
            $obj = @{}
            foreach ($k in $script:ghVerCache.Keys) { $obj[$k] = $script:ghVerCache[$k] }
            ($obj | ConvertTo-Json) | Set-Content -Path $script:ghVerCacheFile -Encoding UTF8 -Force
        } catch {}
        return $tag
    }
    if ($entry -and $entry.tag) { return [string]$entry.tag }
    return $null
}

function global:Get-WebVersionCached {
    # Return the published version string from a mod's own website (the GRAND
    # mod for Alien Isolation), cached on disk with the same 6h TTL as the
    # GitHub release checks so back-to-back scans skip the live page fetch -
    # the slowest single online check. No timeout is lowered, so a slow-but-
    # valid page is never cut short. On a fetch failure the last-known cached
    # value is returned, so the update state stays stable.
    param([string]$Url, [string]$Title)
    if (-not $Url) { return $null }
    $ttlHours = 6
    if ($null -eq $script:webVerCache) {
        $script:webVerCache = @{}
        $script:webVerCacheFile = Join-Path $global:scriptDir ".web_version_cache"
        if (Test-Path $script:webVerCacheFile) {
            try {
                $raw = Get-Content $script:webVerCacheFile -Raw | ConvertFrom-Json
                foreach ($wp in $raw.PSObject.Properties) {
                    $script:webVerCache[$wp.Name] = @{ ver = [string]$wp.Value.ver; checked = [string]$wp.Value.checked }
                }
            } catch {}
        }
    }
    $entry = $script:webVerCache[$Url]
    $now = [DateTime]::UtcNow
    if ($entry -and $entry.ver -and $entry.checked) {
        try {
            $age = ($now - [DateTime]::Parse($entry.checked, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).TotalHours
            if ($age -lt $ttlHours) { return [string]$entry.ver }
        } catch {}
    }
    # Respect the scan-wide circuit breaker (same rule as every online scan
    # check): if an earlier check this scan already failed, do NOT touch the
    # network again - return the last known version or null.
    if ($global:HubScanOnlineDown -or $global:HubVersionCacheOnly) {
        if ($entry -and $entry.ver) { return [string]$entry.ver }
        return $null
    }
    $wv = $null
    try {
        # The slow part of this check is the NETWORK (DNS + TLS + any http->https
        # ->www redirect hops + a slow server), NOT the page itself - parsing the
        # whole 72 KB page takes well under 1 ms. Invoke-WebRequest's -TimeoutSec
        # in Windows PowerShell 5.1 applies per-hop and does not bound DNS, so a
        # slow lookup or a multi-hop redirect could still stall the scan ~10s and
        # then succeed (hence "checked, no error" in the log).
        #
        # Fix: run the fetch on a background runspace and impose ONE hard total
        # time budget (6s) over the entire operation - DNS, connect, redirects
        # and body read included. If the budget is exceeded we abandon the call,
        # trip the scan-wide breaker, and fall back to the cached version. The
        # full page IS read (cheap), so no version string can ever be cut off.
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
        $fetchBudgetMs = 2000
        $ps = [PowerShell]::Create()
        [void]$ps.AddScript({
            param($u)
            try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
            $r = [System.Net.HttpWebRequest]::Create($u)
            $r.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
            $r.AllowAutoRedirect = $true
            $r.Timeout          = 2000
            $r.ReadWriteTimeout = 2000
            $resp = $r.GetResponse()
            try {
                $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
                try { return $sr.ReadToEnd() } finally { $sr.Close() }
            } finally { $resp.Close() }
        }).AddArgument($Url)
        $async = $ps.BeginInvoke()
        $wHtml = ""
        if ($async.AsyncWaitHandle.WaitOne($fetchBudgetMs)) {
            try {
                $res = $ps.EndInvoke($async)
                if ($res -and $res.Count -gt 0) { $wHtml = [string]$res[0] }
            } catch { throw }
            finally { $ps.Dispose() }
        } else {
            # Over budget: abandon the runspace (it dies with the process /
            # scan) and treat it exactly like a timeout.
            try { $ps.Stop() } catch {}
            try { $ps.Dispose() } catch {}
            throw [System.TimeoutException]::new("web version fetch exceeded ${fetchBudgetMs}ms budget")
        }
        if     ($wHtml -match 'Test Build\s+v?([0-9][0-9A-Za-z.\-]+)') { $wv = "v" + $matches[1] }
        elseif ($wHtml -match 'GRAND[^0-9<]{0,30}v?([0-9]+(?:\.[0-9]+)+[0-9A-Za-z\-]*)') { $wv = "v" + $matches[1] }
        elseif ($wHtml -match '\bv([0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z\-]*)') { $wv = "v" + $matches[1] }
        if ($wv) { Write-Host "[AICheck] $Title : web version = $wv" }
        else     { Write-Host ("[AICheck] $Title : page fetched ({0} chars) but no version matched" -f $wHtml.Length) }
    } catch {
        Write-Host "[AICheck] $Title : page fetch failed - $($_.Exception.Message)"
        # Timeout / unreachable -> trip the scan-wide breaker so the rest of
        # this scan skips the network instead of each eating another timeout.
        $global:HubScanOnlineDown = $true
        if ($entry -and $entry.ver) { return [string]$entry.ver }
        return $null
    }
    if ($wv) {
        $script:webVerCache[$Url] = @{ ver = $wv; checked = $now.ToString("o") }
        try {
            $obj = @{}
            foreach ($wk in $script:webVerCache.Keys) { $obj[$wk] = $script:webVerCache[$wk] }
            ($obj | ConvertTo-Json) | Set-Content -Path $script:webVerCacheFile -Encoding UTF8 -Force
        } catch {}
        return $wv
    }
    if ($entry -and $entry.ver) { return [string]$entry.ver }
    return $null
}

function global:Invoke-RotatingOnlinePrewarm {
    # Warm the version cache for online-checkable games in a ROTATING order.
    # Problem this solves: a single persistently-slow repo sitting at a fixed
    # scan position would trip the circuit breaker FIRST every scan and starve
    # every other repo forever (they would never get cached). By rotating which
    # repo is attempted first each scan - offset kept in a tiny file so it
    # advances across sessions - every healthy repo eventually lands an early
    # slot, before the breaker trips, and caches itself for 6h (dropping off the
    # network). The breaker still caps the whole prewarm at ONE timeout, so this
    # never reintroduces the multi-minute freeze.
    try {
        $items = @()
        foreach ($g in $global:allGameData) {
            if ($g.GithubRepo) {
                $repo = $g.GithubRepo
                if ($g.GithubRepoAlt) {
                    try {
                        $ipf = Get-InstalledPathFile -Game $g
                        if ($ipf) {
                            $vs = Join-Path (Split-Path -Parent $ipf) ".vrv_source"
                            if ((Test-Path $vs) -and ((Get-Content $vs -Raw -EA Stop).Trim() -eq "francisco")) { $repo = $g.GithubRepoAlt }
                        }
                    } catch {}
                }
                $items += , @{ K = "gh"; A = $repo; P = [bool]$g.GithubPrerelease }
                # Two-mod entries track a second repo - warm that one as well,
                # otherwise its badge check would be the only live call left
                # in the scan.
                if ($g.GithubRepoB) { $items += , @{ K = "gh"; A = $g.GithubRepoB; P = [bool]$g.GithubPrerelease } }
            } elseif ($g.WebVersionUrl) {
                $items += , @{ K = "web"; A = $g.WebVersionUrl; T = $g.Title }
            }
        }
        if ($items.Count -eq 0) { return }
        $off = 0
        if ($items.Count -gt 1) {
            $rotFile = Join-Path $global:scriptDir ".gh_check_rotation"
            if (Test-Path $rotFile) {
                try { $off = [int]((Get-Content $rotFile -Raw -EA SilentlyContinue).Trim()) } catch { $off = 0 }
            }
            $off = (($off % $items.Count) + $items.Count) % $items.Count
            try { Set-Content -Path $rotFile -Value ([string](($off + 1) % $items.Count)) -Encoding ASCII -Force } catch {}
        }
        for ($i = 0; $i -lt $items.Count; $i++) {
            # Soft time budget: once the scan's deadline passes, stop probing
            # the network. Tripping the breaker makes the Cached getters below
            # return cache-only, so the remaining repos are skipped instantly
            # rather than each risking another slow fetch. They keep their
            # last-known cache and refresh on a future scan (rotation gives each
            # an early slot over time). This is what bounds the scan's online
            # phase to ~the budget instead of "sum of every slow host".
            if ($global:PrewarmDeadline -and ([DateTime]::UtcNow -gt $global:PrewarmDeadline)) {
                $global:HubScanOnlineDown = $true
                break
            }
            $it = $items[($off + $i) % $items.Count]
            try {
                if ($it.K -eq "gh") { [void](Get-GithubLatestTagCached -Repo $it.A -IncludePrerelease:([bool]$it.P)) }
                else { [void](Get-WebVersionCached -Url $it.A -Title $it.T) }
            } catch {}
        }
    } catch {}
}

# --- Scan UI lock -------------------------------------------------
# While a scan yields the UI thread back to WPF (see the pump inside
# Invoke-CheckInstalledScan), the window is alive - it paints and
# animates, but nothing in a half-finished scan should be interactive.
# Lock-ScanUi therefore switches BOTH input paths off:
#   - mouse:    IsHitTestVisible = $false on the window content
#   - keyboard: Preview blockers on the window (tunneling, so they run
#               before the search box or any shortcut sees the key -
#               typing in the search box mid-scan would tear down the
#               detail view and re-filter the very cards being scanned)
# Unlock-ScanUi reverses both and is safe to call when nothing is
# locked - it is used at scan end, in the self-heal path and in the
# click handler's crash catch.
function global:Lock-ScanUi {
    try {
        $script:scanInputLock = $global:window.Content
        if ($script:scanInputLock) { $script:scanInputLock.IsHitTestVisible = $false }
    } catch { $script:scanInputLock = $null }
    try {
        if (-not $script:scanKeysLocked) {
            if (-not $script:scanKeyBlock) {
                $script:scanKeyBlock  = [System.Windows.Input.KeyEventHandler]{ param($s, $e) $e.Handled = $true }
                $script:scanTextBlock = [System.Windows.Input.TextCompositionEventHandler]{ param($s, $e) $e.Handled = $true }
            }
            $global:window.AddHandler([System.Windows.UIElement]::PreviewKeyDownEvent,   $script:scanKeyBlock,  $true)
            $global:window.AddHandler([System.Windows.UIElement]::PreviewTextInputEvent, $script:scanTextBlock, $true)
            $script:scanKeysLocked = $true
        }
    } catch { $script:scanKeysLocked = $false }
}

function global:Unlock-ScanUi {
    try { if ($script:scanInputLock) { $script:scanInputLock.IsHitTestVisible = $true } } catch {}
    $script:scanInputLock = $null
    if ($script:scanKeysLocked) {
        try { $global:window.RemoveHandler([System.Windows.UIElement]::PreviewKeyDownEvent,   $script:scanKeyBlock)  } catch {}
        try { $global:window.RemoveHandler([System.Windows.UIElement]::PreviewTextInputEvent, $script:scanTextBlock) } catch {}
        $script:scanKeysLocked = $false
    }
}

# Set ONLY by a real, user-triggered full scan. The startup quick-scan also
# fills $global:gameStateMap, so that map can never be used to decide whether
# the user opted into full scans - doing so made every installer end with an
# unwanted scan over all games.
$global:UserRanFullScan = $false

# Align the TopScanSlot's left edge with where the STATE pills begin one
# row below, so the "X on PC | Y VR Ready" totals sit exactly above the
# spot the Scan games button used to occupy.
#
# This is a MEASUREMENT, so it only produces a correct result once the
# window has really been laid out. The startup (pre-paint) scan runs
# before ShowDialog, where the visual tree has never been arranged and
# the measured X positions are meaningless - the totals then end up too
# far left. Startup.ps1 therefore calls this again after ContentRendered.
# Safe to call repeatedly: $slotX already includes the current margin, so
# the correction converges instead of drifting.
function global:Align-TopScanSlot {
    try {
        $slot = $global:window.FindName("TopScanSlot")
        if (-not $slot) { return }
        $global:window.UpdateLayout()
        $stateLbl = $global:window.FindName("StateLabel")
        if (-not $stateLbl) { return }
        # Target = where the State pills (and the old Scan games button)
        # BEGIN = STATE label RIGHT edge + its right margin, not its left
        # edge. That puts the totals exactly above the old button spot.
        $zero    = [System.Windows.Point]::new(0,0)
        $targetX = ($stateLbl.TransformToVisual($global:window).Transform($zero).X) + $stateLbl.ActualWidth + 8
        $slotX   = $slot.TransformToVisual($global:window).Transform($zero).X
        $newLeft = $slot.Margin.Left + ($targetX - $slotX)
        if ($newLeft -lt 0) { $newLeft = 0 }
        $slot.Margin = [System.Windows.Thickness]::new($newLeft, 0, 0, 0)
    } catch {}
}

function global:Invoke-CheckInstalledScan {
    $global:UserRanFullScan = $true
    # Re-entrancy guard. The scan now hands the UI thread back between
    # games (see the pump inside the loop), so a timer tick or a queued
    # call could otherwise start a second scan on top of a running one -
    # which would rebuild the very collections this one is walking.
    #
    # Self-healing: if a previous scan died mid-way (unhandled error), the
    # flag would stay set and the window would stay click-blind forever.
    # A scan updates its heartbeat at every yield, so a stale flag is one
    # whose heartbeat is more than a minute old - in that case clean up
    # after the dead run and carry on instead of refusing.
    if ($global:ScanInProgress) {
        $alive = $false
        try { $alive = ($script:scanHeartbeat -and ((Get-Date) - $script:scanHeartbeat).TotalSeconds -lt 60) } catch {}
        if ($alive) { return }
        Unlock-ScanUi
        try { if (Get-Command Stop-ScanSpinner -ErrorAction SilentlyContinue) { Stop-ScanSpinner } } catch {}
    }
    $global:ScanInProgress = $true
    $global:ScanQueued = $false

    # Lock mouse + keyboard for the duration (see Lock-ScanUi above).
    Lock-ScanUi

    # Paced yields: at most one every ~80 ms, measured, so a fast machine
    # doesn't pay for a repaint per game and a slow one still breathes.
    # The empty delegate is built once - converting a scriptblock to an
    # [action] on every yield would allocate for nothing.
    if (-not $script:scanPumpAction) { $script:scanPumpAction = [action]{} }
    $script:scanPumpWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $script:scanHeartbeat = Get-Date

    # Light up the Scan games button. It runs on its own render thread, so
    # it keeps moving even while this scan holds the UI thread - which is
    # the only reason it exists. Wrapped because a missing indicator must
    # never stop a scan.
    try { if (Get-Command Start-ScanSpinner -ErrorAction SilentlyContinue) { Start-ScanSpinner } } catch {}

    # Freeze the install-pill reveal timer for the duration of the scan.
    # The scan pumps the dispatcher (Dispatcher.Invoke below), which would
    # otherwise let a pending hide-timer tick fire mid-scan and collapse a
    # pill even though the user only clicked Check Installed. Pills are
    # re-synced at the very end of the scan via Sync-InstallPills.
    if ($script:vrReadyHideTimer) { $script:vrReadyHideTimer.Stop() }
    # Restore the "Check Installed" TextBlock for the duration of
    # the scan so "Scanning..." can be shown. If this is a re-scan,
    # the count StackPanel is currently visible and the text is
    # collapsed - swap them back temporarily.
    if ($checkInstalledCount) {
        $checkInstalledCount.Visibility = [System.Windows.Visibility]::Collapsed
    }
    # Also hide the shimmer for the duration of the scan - the
    # button is in its "working" state right now ("Scanning...")
    # and the eye-catcher sweep would compete with that. We'll
    # bring it back when the counter takes over below.
    if ($checkInstalledShimmer) {
        $checkInstalledShimmer.Visibility = [System.Windows.Visibility]::Collapsed
    }
    $checkInstalledText.Visibility = [System.Windows.Visibility]::Visible
    $checkInstalledText.Text = "Scanning..."
    $checkInstalledText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ffcc44")

    # A check is now running: hide + disable the Scan-on-Startup hover toggle
    # BEFORE the dispatcher pump below, so it actually leaves the screen before
    # the UI-thread-blocking scan work freezes everything. The Background pump
    # processes the render queue, so the hide is painted before the freeze.
    # Show-CheckOnStartup honours $global:ScanInProgress so a hover can't bring
    # it back mid-scan.
    $global:ScanInProgress = $true
    $cosb = $global:window.FindName("CheckOnStartupBtn")
    if ($cosb) { $cosb.Visibility = [System.Windows.Visibility]::Collapsed; $cosb.IsEnabled = $false }
    if ($global:CheckHoverHideTimer) { try { $global:CheckHoverHideTimer.Stop() } catch {} }

    # Force WPF to fully drain its layout + render queue so the hide above is
    # actually painted before the synchronous scan work freezes the UI thread.
    # A single Invoke(Background) can leave a second layout pass pending; a
    # DispatcherFrame "DoEvents" loop pumps every priority above Background
    # (incl. Render) until idle, which the heavier header layout now needs.
    $flushFrame = New-Object System.Windows.Threading.DispatcherFrame
    $null = $window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{ $flushFrame.Continue = $false })
    [System.Windows.Threading.Dispatcher]::PushFrame($flushFrame)

    # Mark scan-run so the detail view's "Get on Steam" hint can
    # distinguish "scanned and not found" from "never scanned" -
    # both leave gameStateMap[Title] empty, but only the first one
    # justifies a prominent CTA.
    $global:HasRunInstalledScan = $true

    # Needs Mod / VR Ready are revealed at the END of this function, a beat
    # AFTER the counter button lifts into the header - revealing them here would
    # widen the filter row and shove the button sideways mid-lift.

    # Per-scan cache for GitHub-nightly release tags. Multiple
    # REFramework games share the same praydog/REFramework-nightly
    # repo, so we hold the result here and reuse it for every game
    # rather than hitting the API once per title.
    $script:scanGhTagCache = @{}

    # Get Steam libraries
    $steamPath = $null
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p=(Get-ItemProperty -Path $reg -EA Stop).InstallPath; if($p -and (Test-Path $p)){$steamPath=$p; break} } catch {}
    }

    $steamLibs = @()
    if ($steamPath) {
        $steamLibs += $steamPath
        $vdf = Join-Path $steamPath "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            [regex]::Matches((Get-Content $vdf -Raw),'"path"\s+"([^"]+)"') | ForEach-Object {
                $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$steamLibs+=$l}
            }
        }
    }

    # GOG Galaxy install roots. GOG doesn't have a single VDF
    # listing all libraries the way Steam does, so we collect
    # plausible roots: the Galaxy install folder's "Games"
    # subfolder (from registry), plus the well-documented default
    # locations for both Galaxy-managed and standalone installs.
    # Each root will have the game's folder name appended at
    # FallbackPaths-resolution time (GOG: prefix below).
    $gogRoots = @()
    foreach ($reg in @(
        "HKLM:\SOFTWARE\WOW6432Node\GOG.com\GalaxyClient\paths",
        "HKLM:\SOFTWARE\GOG.com\GalaxyClient\paths"
    )) {
        try {
            # SilentlyContinue (not Stop): on machines without GOG Galaxy this
            # key is absent, and -EA Stop made Get-ItemProperty raise a
            # terminating error that Start-Transcript logged on every scan.
            # SilentlyContinue returns $null, which the if-check below handles.
            $p = (Get-ItemProperty -Path $reg -EA SilentlyContinue).client
            if ($p) {
                $g = Join-Path $p "Games"
                if (Test-Path $g) { $gogRoots += $g }
            }
        } catch {}
    }
    # Default roots commonly used by GOG installers and by users
    # who picked a custom location at install time.
    foreach ($root in @(
        "C:\GOG Games",
        "C:\Program Files (x86)\GOG Galaxy\Games",
        "C:\Program Files (x86)\GalaxyClient\Games",
        "${env:ProgramFiles}\GOG Galaxy\Games",
        "${env:ProgramFiles(x86)}\GOG Galaxy\Games",
        "D:\GOG Games",
        "E:\GOG Games"
    )) {
        if ($root -and (Test-Path $root) -and ($gogRoots -notcontains $root)) {
            $gogRoots += $root
        }
    }

    # Epic Games Launcher install roots. Epic's default install path
    # is "C:\Program Files\Epic Games" (epicgames.com support docs).
    # Like GOG there's no Steam-style library VDF we can scrape, so
    # we collect plausible roots: the documented default plus the
    # common user picks (different drive, %ProgramFiles% variants).
    # Each root will have the game's folder name appended at
    # FallbackPaths-resolution time (EPIC: prefix below).
    $epicRoots = @()
    foreach ($root in @(
        "${env:ProgramFiles}\Epic Games",
        "${env:ProgramFiles(x86)}\Epic Games",
        "C:\Program Files\Epic Games",
        "C:\Epic Games",
        "D:\Epic Games",
        "E:\Epic Games",
        "D:\Program Files\Epic Games",
        "E:\Program Files\Epic Games"
    )) {
        if ($root -and (Test-Path $root) -and ($epicRoots -notcontains $root)) {
            $epicRoots += $root
        }
    }

    # AND the roots Epic ACTUALLY used. The list above is guesswork; the
    # launcher manifests are the truth. Every installed game has a JSON
    # .item file under %ProgramData%\Epic\EpicGamesLauncher\Data\Manifests
    # with its real InstallLocation, so the PARENT of each of those is a
    # live Epic root - including a library on a drive nobody guessed.
    # Purely additive: the guessed roots stay, this only adds more.
    # The installers already read these manifests via Find-SteamGameFolder;
    # the Hub's own scan did not, so an Epic copy outside the default
    # folder was invisible on the tile while the installer found it.
    try {
        $epicManifestDir = Join-Path $env:ProgramData "Epic\EpicGamesLauncher\Data\Manifests"
        if ($env:ProgramData -and (Test-Path $epicManifestDir)) {
            foreach ($item in (Get-ChildItem -Path $epicManifestDir -Filter *.item -ErrorAction SilentlyContinue)) {
                try {
                    $loc = (Get-Content -LiteralPath $item.FullName -Raw -ErrorAction Stop | ConvertFrom-Json).InstallLocation
                    if (-not $loc) { continue }
                    $parent = Split-Path -Parent $loc
                    if ($parent -and (Test-Path $parent) -and ($epicRoots -notcontains $parent)) {
                        $epicRoots += $parent
                    }
                } catch { }
            }
        }
    } catch { }
    # C:\XboxGames (configurable, but per-drive). Apps install as
    # <Title>\Content\<exe>. The Content subdir is part of the
    # XBOX: resolver below - the catalog only needs to provide the
    # title-level folder name as it appears on disk (which often
    # has its colons replaced by dashes, e.g. "Halo- The Master
    # Chief Collection").
    $xboxRoots = @()
    foreach ($root in @(
        "C:\XboxGames",
        "D:\XboxGames",
        "E:\XboxGames",
        "F:\XboxGames"
    )) {
        if ($root -and (Test-Path $root) -and ($xboxRoots -notcontains $root)) {
            $xboxRoots += $root
        }
    }

    # Ubisoft Connect roots. The installer plants games under
    # <Ubisoft Game Launcher>\games\<Title>. The launcher itself is
    # typically in Program Files (x86), but the games dir can be
    # redirected; we collect plausible roots and rely on Test-Path
    # to filter.
    $ubisoftRoots = @()
    foreach ($root in @(
        "${env:ProgramFiles(x86)}\Ubisoft\Ubisoft Game Launcher\games",
        "${env:ProgramFiles}\Ubisoft\Ubisoft Game Launcher\games",
        "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games",
        "C:\Ubisoft\Ubisoft Game Launcher\games",
        "D:\Ubisoft\Ubisoft Game Launcher\games",
        "E:\Ubisoft\Ubisoft Game Launcher\games"
    )) {
        if ($root -and (Test-Path $root) -and ($ubisoftRoots -notcontains $root)) {
            $ubisoftRoots += $root
        }
    }

    # Rotating online prewarm: warm the update caches so the per-card loop below
    # reads them instead of hitting the network inline. Runs synchronously but
    # under a soft TIME BUDGET: Invoke-RotatingOnlinePrewarm checks a deadline
    # between repos and trips the scan-wide breaker once ~4s have passed, so the
    # scan hands control back quickly instead of grinding through every slow
    # host. Repos warmed before the deadline show their update badge THIS scan.
    # Whatever did NOT make the window is handed to a BACKGROUND WORKER PROCESS
    # (Modules\PrewarmWorker.ps1, hidden, fire-and-forget) that finishes those
    # checks with generous timeouts and merge-writes the same disk caches - the
    # next scan / Hub start reads them from disk and paints the badges. The
    # user consented to online checks by clicking Scan.
    #
    # Reload the in-memory caches from disk FIRST: a worker spawned by an
    # earlier scan (this session or a previous one) has since written fresh
    # entries to disk that our lazily-loaded in-memory copies don't have.
    # Clearing them forces the getters to re-read the files on next use, so
    # straggler results actually surface THIS scan.
    $script:ghVerCache  = $null
    $script:webVerCache = $null

    $global:HubVersionCacheOnly = $false
    $global:HubScanOnlineDown = $false
    $global:PrewarmDeadline = [DateTime]::UtcNow.AddMilliseconds(3500)
    Invoke-RotatingOnlinePrewarm
    $global:PrewarmDeadline = $null

    # ---- Hand the leftovers to the background worker ----
    # "Leftover" = any online-checkable game whose disk-cache entry is missing
    # or older than the 6h TTL after the budgeted prewarm above. That covers
    # every miss reason uniformly (deadline hit, breaker tripped mid-loop,
    # first-ever scan with a cold cache). Single-instance guard via a lock
    # file with a 10-minute staleness expiry, so a crashed worker can never
    # block future spawns for good.
    try {
        $ttlH = 6
        $nowU = [DateTime]::UtcNow
        $ghDisk = @{}; $webDisk = @{}
        $ghF  = Join-Path $global:scriptDir ".gh_version_cache"
        $webF = Join-Path $global:scriptDir ".web_version_cache"
        if (Test-Path $ghF)  { try { $r = Get-Content $ghF -Raw | ConvertFrom-Json;  foreach ($p in $r.PSObject.Properties) { $ghDisk[$p.Name]  = [string]$p.Value.checked } } catch {} }
        if (Test-Path $webF) { try { $r = Get-Content $webF -Raw | ConvertFrom-Json; foreach ($p in $r.PSObject.Properties) { $webDisk[$p.Name] = [string]$p.Value.checked } } catch {} }
        function Test-CacheFresh([hashtable]$m, [string]$k) {
            if (-not $m.ContainsKey($k)) { return $false }
            try { return ((($nowU) - [DateTime]::Parse($m[$k], $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).TotalHours -lt $ttlH) } catch { return $false }
        }
        $pending = @()
        foreach ($g in $global:allGameData) {
            if ($g.GithubRepo) {
                $repo = $g.GithubRepo
                if ($g.GithubRepoAlt) {
                    try {
                        $ipfP = Get-InstalledPathFile -Game $g
                        if ($ipfP) {
                            $vsP = Join-Path (Split-Path -Parent $ipfP) ".vrv_source"
                            if ((Test-Path $vsP) -and ((Get-Content $vsP -Raw -EA Stop).Trim() -eq "francisco")) { $repo = $g.GithubRepoAlt }
                        }
                    } catch {}
                }
                if (-not (Test-CacheFresh $ghDisk $(if ($g.GithubPrerelease) { "$repo#pre" } else { $repo }))) { $pending += , @{ K = "gh"; A = $repo; P = [bool]$g.GithubPrerelease } }
            } elseif ($g.WebVersionUrl) {
                if (-not (Test-CacheFresh $webDisk $g.WebVersionUrl)) { $pending += , @{ K = "web"; A = $g.WebVersionUrl; T = $g.Title } }
            }
        }
        if ($pending.Count -gt 0) {
            $lockF   = Join-Path $global:scriptDir ".prewarm_worker.lock"
            $lockOk  = $true
            if (Test-Path $lockF) {
                try {
                    $lockAge = ($nowU - [DateTime]::Parse((Get-Content $lockF -Raw -EA Stop).Trim(), $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).TotalMinutes
                    if ($lockAge -lt 10) { $lockOk = $false }   # a worker is (probably) still running
                } catch {}
            }
            $workerF = Join-Path $global:scriptDir "Modules\PrewarmWorker.ps1"
            if ($lockOk -and (Test-Path $workerF)) {
                Set-Content -Path $lockF -Value ($nowU.ToString("o")) -Encoding ASCII -Force
                ($pending | ConvertTo-Json) | Set-Content -Path (Join-Path $global:scriptDir ".prewarm_pending.json") -Encoding UTF8 -Force
                Start-Process -FilePath "powershell.exe" `
                    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File', "`"$workerF`"", '-ScriptDir', "`"$global:scriptDir`"") `
                    -WindowStyle Hidden
                Write-Host "[Prewarm] $($pending.Count) online check(s) handed to the background worker; results show next scan."
            }
        }
    } catch {}

    # Version-check phase done for THIS scan. Switch ONLY the gh/web version
    # getters to cache-only for the per-card loop - their inline network call
    # was the freeze, and any repo they missed is already handed to the
    # background worker above. Deliberately NOT the scan-wide breaker: the
    # loop's GitHubNightly (api.github.com) and Thunderstore checks have no
    # disk cache and are not covered by the worker - tripping the breaker
    # here would silently kill their update badges for good. They keep their
    # original behaviour (2s timeout, self-trip on first failure).
    $global:HubVersionCacheOnly = $true

    $found = 0
    $vrFound = 0
    # Snapshot of the keys, not the live collection: the yield below lets
    # other code run, and anything that rebuilds the lookups mid-scan
    # would otherwise break the enumeration.
    foreach ($card in @($global:cardGameMap.Keys)) {
        $game = $global:cardGameMap[$card]
        # THIS is what keeps the Hub alive during a scan. Every ~80 ms the
        # UI thread is handed back to WPF long enough to run layout, paint
        # and animation ticks, then the scan continues where it left off.
        # Without it the whole window is a still image until the scan ends:
        # banner effects stop, the Scan-on-Startup toggle can't disappear,
        # and Windows eventually declares the Hub not responding. Input is
        # locked out above, so nothing can be clicked in these gaps.
        if ($script:scanPumpWatch -and $script:scanPumpWatch.ElapsedMilliseconds -ge 80) {
            $script:scanPumpWatch.Restart()
            $script:scanHeartbeat = Get-Date
            try { $window.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, $script:scanPumpAction) } catch {}
        }
        # Per-game guard: one game whose detection throws must NEVER
        # kill the scan for every game after it. Errors are recorded and
        # the loop continues with the next game.
        try {
        # Free standalone VR games (Anomaly, Iron Lung, Sonic P-06,
        # Receiver) have no purchase/ownership requirement - they are
        # always ready to install. They may have a SteamFolder set
        # only so the Hub can pull Steam artwork/info, NOT to gate
        # availability on a Steam install. So we do not require a
        # SteamFolder match for them: if the Hub already installed one
        # (recorded .installed_path below) it shows "VR Ready",
        # otherwise it shows the green "ready to install" state - never
        # "needs buying" and never dependent on finding a Steam copy.
        $isFreeGame = ($global:FREE_GAME_TITLES -and ($global:FREE_GAME_TITLES -contains $game.Title))
        # Locate support: a game the user pointed the Hub at (via the
        # "Locate install" button) has a recorded path file even without
        # a SteamFolder - let it through so Priority 1 can verify it.
        $ipfGate = $null
        try { $ipfGate = Get-InstalledPathFile -Game $game } catch {}
        $hasLocated = ($ipfGate -and (Test-Path $ipfGate))
        if (-not $game.SteamFolder -and -not $isFreeGame -and -not $hasLocated) { continue }
        $installed = $false
        $gameDir   = $null

        # Priority 1: an installer-recorded path wins over everything.
        # Written by installers that put the game in a custom or
        # non-standard location (e.g. Outward in C:\Games\, Tormented
        # Souls in steamapps\content\). If this exists and resolves,
        # it IS the install - no heuristic guessing.
        #
        # We can't use Read-InstalledPath here because it returns
        # $null when the recorded path no longer exists - we'd never
        # see the stale file in order to clean it up. Read the raw
        # content directly so we can distinguish "no file" from
        # "file points to a deleted folder".
        $installedPathFile = Get-InstalledPathFile -Game $game
        $rawRecordedPath = $null
        if ($installedPathFile -and (Test-Path $installedPathFile)) {
            try {
                $rawRecordedPath = (Get-Content $installedPathFile -Raw -EA SilentlyContinue)
                if ($rawRecordedPath) { $rawRecordedPath = $rawRecordedPath.Trim() }
            } catch { }
        }
        if ($rawRecordedPath -and (Test-Path $rawRecordedPath)) {
            $installed = $true
            $gameDir   = $rawRecordedPath
        } elseif ($rawRecordedPath -and -not (Test-Path $rawRecordedPath)) {
            # Recorded path no longer exists on disk - clear the
            # stale .installed_path AND .installed_version files so
            # downstream checks don't keep using them as evidence.
            try { Remove-Item $installedPathFile -Force -EA SilentlyContinue } catch { }
            $staleVer = Get-InstalledVersionPath -Game $game
            if ($staleVer -and (Test-Path $staleVer)) {
                try { Remove-Item $staleVer -Force -EA SilentlyContinue } catch { }
            }
        }

        # Priority 2a: authoritative Steam appmanifest lookup by AppId.
        # Steam records the real install folder in appmanifest_<id>.acf
        # ("installdir"), so this is immune to the catalog SteamFolder
        # name drifting from the actual on-disk folder. Additive: only
        # runs when nothing matched yet, and falls through to the
        # name-based scan below if no manifest/folder is found.
        if (-not $installed -and -not $isFreeGame -and $game.SteamId) {
            foreach ($lib in $steamLibs) {
                $acf = Join-Path $lib "steamapps\appmanifest_$($game.SteamId).acf"
                if (Test-Path $acf) {
                    try {
                        $mm = [regex]::Match((Get-Content $acf -Raw), '"installdir"\s+"([^"]+)"')
                        if ($mm.Success) {
                            $cand = Join-Path $lib "steamapps\common\$($mm.Groups[1].Value)"
                            if (Test-Path $cand) { $installed = $true; $gameDir = $cand; break }
                        }
                    } catch {}
                }
            }
        }

        # Priority 2: regular Steam library scan.
        # Skipped for free games: their availability never depends on
        # a Steam copy existing, and we don't want the unmodded Steam
        # build picked up as the launch dir.
        if (-not $installed -and -not $isFreeGame) {
            foreach ($lib in $steamLibs) {
                $candidate = Join-Path $lib "steamapps\common\$($game.SteamFolder)"
                if (Test-Path $candidate) {
                    $installed = $true
                    $gameDir   = $candidate
                    break
                }
            }
        }

        # Priority 3: static FallbackPaths.
        # For DepotInstall games we want EVERY fallback path checked,
        # regardless of whether Priority 2 already produced a hit.
        # Why: Priority 2 finds the retail game in steamapps\common,
        # but the VR mod actually lives elsewhere (a renamed depot
        # under steamapps\content, or a separate folder under
        # C:\Games\). Only a fallback-path match tells us the VR
        # version exists. First fallback path that exists wins.
        $depotMatched = $false
        if ($game.FallbackPaths) {
            foreach ($fp in (Expand-DrivePaths $game.FallbackPaths)) {
                # Build the list of concrete paths to test. STEAM_*
                # prefixes expand to one path per Steam library;
                # everything else is taken as an absolute path.
                # Note: ${env:ProgramFiles} style placeholders inside
                # double-quoted game-def strings are expanded at
                # script-load time, so we don't need extra handling.
                $candidates = @()
                if ($fp -like "STEAM_CONTENT*") {
                    $tail = $fp.Substring("STEAM_CONTENT".Length)
                    foreach ($lib in $steamLibs) {
                        $candidates += (Join-Path $lib "steamapps\content$tail")
                    }
                } elseif ($fp -like "STEAM_COMMON*") {
                    $tail = $fp.Substring("STEAM_COMMON".Length)
                    foreach ($lib in $steamLibs) {
                        $candidates += (Join-Path $lib "steamapps\common$tail")
                    }
                } elseif ($fp -like "STEAM:*") {
                    $folderName = $fp.Substring("STEAM:".Length)
                    foreach ($lib in $steamLibs) {
                        $candidates += (Join-Path $lib "steamapps\common\$folderName")
                    }
                } elseif ($fp -like "GOG:*") {
                    # GOG: expands the game folder against every
                    # detected GOG root. Each root already ends
                    # at the "Games" parent (or the standalone
                    # equivalent), so we just append the folder.
                    $folderName = $fp.Substring("GOG:".Length)
                    foreach ($root in $gogRoots) {
                        $candidates += (Join-Path $root $folderName)
                    }
                } elseif ($fp -like "EPIC:*") {
                    # EPIC: expands the game folder against every
                    # detected Epic Games Launcher root. Same
                    # pattern as GOG: above.
                    $folderName = $fp.Substring("EPIC:".Length)
                    foreach ($root in $epicRoots) {
                        $candidates += (Join-Path $root $folderName)
                    }
                } elseif ($fp -like "XBOX:*") {
                    # XBOX: expands to <xbox-root>\<folder>\Content
                    # because MS Store apps put the actual game
                    # under a "Content" subdir inside the title's
                    # folder. The catalog just supplies the title
                    # folder; we append \Content here so the path
                    # matches Test-Path against the real game dir.
                    $folderName = $fp.Substring("XBOX:".Length)
                    foreach ($root in $xboxRoots) {
                        $candidates += (Join-Path $root "$folderName\Content")
                    }
                } elseif ($fp -like "UBI:*") {
                    # UBI: expands the game folder against every
                    # detected Ubisoft Connect "games" root.
                    $folderName = $fp.Substring("UBI:".Length)
                    foreach ($root in $ubisoftRoots) {
                        $candidates += (Join-Path $root $folderName)
                    }
                } elseif ($fp -like "APPDATA:*") {
                    # APPDATA: expands the tail against %APPDATA% for
                    # launcher-managed installs outside Steam (e.g.
                    # Hytale). A tail ending in .exe is an existence
                    # PROBE: the game only counts as installed when
                    # that exe is really on disk, and its parent
                    # folder becomes the candidate - a bare folder
                    # left behind by a partial download never
                    # lights the tile.
                    $tail = $fp.Substring("APPDATA:".Length)
                    $apRoot = [Environment]::GetFolderPath("ApplicationData")
                    if ($apRoot -and $tail) {
                        $apPath = Join-Path $apRoot $tail
                        if ($tail -match '\.exe$') {
                            if (Test-Path -LiteralPath $apPath) { $candidates += (Split-Path -Parent $apPath) }
                        } else {
                            $candidates += $apPath
                        }
                    }
                } else {
                    if ($fp) { $candidates += $fp }
                }

                # First candidate that exists on disk wins.
                foreach ($candidate in $candidates) {
                    if ($candidate -and (Test-Path $candidate)) {
                        $installed = $true
                        $gameDir   = $candidate
                        if ($game.DepotInstall) { $depotMatched = $true }
                        break
                    }
                }
                if ($depotMatched) { break }
            }
        }

        # ---------------------------------------------------------------
        # LEFTOVER GUARD: a folder under steamapps\common is NOT proof
        # that the game is installed.
        #
        # Steam removes only its OWN files when you uninstall. Anything a
        # mod put there stays - so the folder survives with, say, just
        # RealRepo\RealVR64.dll in it, and every check above happily
        # reports "installed" and then "VR Ready" and then "Update".
        # That is what Far Cry 4 did after being uninstalled.
        #
        # Steam's own bookkeeping settles it: appmanifest_<AppId>.acf
        # exists exactly as long as Steam has the game installed, and is
        # deleted on uninstall. One Test-Path, no folder walking.
        #
        # Deliberately narrow - it only ever REMOVES a hit that came from
        # a steamapps\common folder:
        #   - no SteamId, or the folder is somewhere else (Epic, GOG,
        #     C:\Games, a depot under steamapps\content) -> untouched
        #   - DepotInstall entries -> untouched, their pinned builds have
        #     no manifest by design
        #   - library root is derived from the path itself, so it also
        #     covers second and third Steam libraries on other drives
        if ($installed -and $gameDir -and $game.SteamId -and -not $game.DepotInstall) {
            $gdLower = ([string]$gameDir).ToLower()
            $marker  = "\steamapps\common\"
            $idx     = $gdLower.IndexOf($marker)
            if ($idx -ge 0) {
                $libRoot  = ([string]$gameDir).Substring(0, $idx)
                $manifest = Join-Path $libRoot ("steamapps\appmanifest_" + $game.SteamId + ".acf")
                if (-not (Test-Path -LiteralPath $manifest)) {
                    # Steam does not have this game installed any more -
                    # what is left in the folder are mod leftovers.
                    $installed = $false
                    $gameDir   = $null
                }
            }
        }

        # Check if VR mod is installed
        $vrInstalled = $false
        # Depot install: the existence of the STEAM_CONTENT /
        # STEAM_COMMON folder we listed in FallbackPaths is itself
        # proof of a working VR install - that folder only appears
        # after the depot download we orchestrated. Skip all other
        # heuristics for these games.
        if ($depotMatched) {
            $vrInstalled = $true
        }
        # If this install was placed by our installer (.installed_path exists),
        # we trust that as a strong signal - BUT we still verify the
        # ModFile is actually on disk at the recorded path. Otherwise
        # the user could delete the VR mod manually and the hub would
        # still display "VR Ready" indefinitely (stale state).
        $recordedPathFile = Get-InstalledPathFile -Game $game
        if (-not $vrInstalled -and $recordedPathFile -and (Test-Path $recordedPathFile)) {
            $recordedPath = $null
            try { $recordedPath = Read-InstalledPath -Game $game } catch {}
            if ($recordedPath -and (Test-Path $recordedPath)) {
                # Recorded path is still valid. If we know what the
                # mod's marker file looks like (ModFile), verify it.
                if ($game.ModFile) {
                    $rp = Join-Path $recordedPath $game.ModFile
                    if (Test-Path $rp) {
                        $vrInstalled = $true
                    } elseif ($game.ModFileAlt -and (Test-Path (Join-Path $recordedPath $game.ModFileAlt))) {
                        # Alternate marker - e.g. Anomaly is VR-ready via the
                        # new AoeVrLauncher.exe OR the old JSGME.exe.
                        $vrInstalled = $true
                    } elseif ($game.ModFile -like "*RealVR64*") {
                        # Luke Ross: user may have renamed RealVR64.dll
                        # to dxgi.dll (some games need this). Look for
                        # any of the LR markers.
                        $lrFound = $false
                        foreach ($mk in @("RealVR64.dll", "RealConfig.bat", "dxgi.dll")) {
                            if (Get-ChildItem -Path $recordedPath -Filter $mk -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) {
                                $lrFound = $true; break
                            }
                        }
                        if ($lrFound) { $vrInstalled = $true }
                    }
                } elseif (-not $game.TwoMods) {
                    # No single ModFile to verify. We must NOT trust the
                    # recorded path blindly: a USER-LOCATED path can point
                    # at any folder (including an empty/wrong one), which
                    # would otherwise flip the card to "VR Ready" with
                    # nothing actually installed. So require the LaunchExe
                    # to be present at the recorded path as proof. Only when
                    # a game has neither a ModFile NOR a LaunchExe (nothing
                    # checkable at all) do we fall back to trusting the
                    # record. TwoMods games also have no ModFile, but they
                    # are verified by their own block below, so we exclude
                    # them here rather than trusting the path.
                    if ($game.LaunchExe) {
                        if (Test-Path (Join-Path $recordedPath $game.LaunchExe)) { $vrInstalled = $true }
                    } else {
                        $vrInstalled = $installed
                    }
                }
            }
        }
        if (-not $vrInstalled -and $installed -and $gameDir -and $game.ModFile) {
            # Default: ModFile lives inside the Steam game folder.
            # This covers ~95% of mods (BepInEx plugins, dropped
            # DLLs etc).
            $modPath = Join-Path $gameDir $game.ModFile
            $modPathFound = Test-Path $modPath
            # Alternate marker: VR-ready via either of two files (e.g.
            # Anomaly: new AoeVrLauncher.exe OR the old JSGME.exe).
            if (-not $modPathFound -and $game.ModFileAlt) {
                $modPathFound = Test-Path (Join-Path $gameDir $game.ModFileAlt)
            }

            # Alternative: VrInstallRoot is set when the mod
            # installs to a separate location (e.g. GZDoomVR in
            # %LocalAppData%). The string can start with one of:
            #   LOCALAPPDATA:    -> %LocalAppData%
            #   APPDATA:         -> %AppData% (Roaming)
            #   PROGRAMDATA:     -> C:\ProgramData
            #   USERPROFILE:     -> %USERPROFILE%
            #   <abs path>       -> taken as-is
            # ModFile is then relative to the resolved root. Plus
            # an optional VrInstallEvidence list lets us look for
            # additional sentinel files - e.g. DOOM2.WAD inside the
            # shared GZDoomVR wads/ folder, which proves Doom 2
            # is installed even though gzdoomvr.exe alone wouldn't.
            if (-not $modPathFound -and $game.VrInstallRoot) {
                $altRoot = $game.VrInstallRoot
                if ($altRoot -like "LOCALAPPDATA:*") {
                    $altRoot = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) ($altRoot.Substring("LOCALAPPDATA:".Length))
                } elseif ($altRoot -like "APPDATA:*") {
                    $altRoot = Join-Path ([Environment]::GetFolderPath("ApplicationData")) ($altRoot.Substring("APPDATA:".Length))
                } elseif ($altRoot -like "PROGRAMDATA:*") {
                    $altRoot = Join-Path ([Environment]::GetFolderPath("CommonApplicationData")) ($altRoot.Substring("PROGRAMDATA:".Length))
                } elseif ($altRoot -like "USERPROFILE:*") {
                    $altRoot = Join-Path ([Environment]::GetFolderPath("UserProfile")) ($altRoot.Substring("USERPROFILE:".Length))
                }
                # Now altRoot is an absolute path. The base check is
                # ModFile relative to it.
                $altPath = Join-Path $altRoot $game.ModFile
                if (Test-Path $altPath) {
                    $modPathFound = $true
                    # If extra evidence files are required (e.g. the
                    # game-specific WAD must be there too), check
                    # all of them - any one missing fails the match.
                    if ($game.VrInstallEvidence) {
                        foreach ($ev in $game.VrInstallEvidence) {
                            $evPath = Join-Path $altRoot $ev
                            if (-not (Test-Path $evPath)) {
                                $modPathFound = $false
                                break
                            }
                        }
                    }
                }
            }

            if ($modPathFound) {
                $vrInstalled = $true
            } elseif ($game.ModFile -like "*RealRepo*") {
                # Luke Ross: RealRepo and related files can sit next to any
                # game exe - Binaries\Win64\, Game\, Phoenix\binaries\win64\,
                # root, etc. Additionally, some overhauls (e.g. Elden Ring
                # Reforged) have the user rename RealVR64.dll -> dxgi.dll,
                # which would miss a DLL-only check. We look for any of:
                #   - RealVR64.dll (default)
                #   - the RealRepo folder (always present, never renamed)
                #   - RealConfig.bat (always present, always required)
                $lrMarkers = @("RealVR64.dll", "RealConfig.bat")
                foreach ($marker in $lrMarkers) {
                    if (Get-ChildItem -Path $gameDir -Filter $marker -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) {
                        $vrInstalled = $true; break
                    }
                }
                if (-not $vrInstalled) {
                    $realRepoDir = Get-ChildItem -Path $gameDir -Directory -Filter "RealRepo" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($realRepoDir) { $vrInstalled = $true }
                }
            }
        }

        # Stage-based mods (F.E.A.R. VR lives in %USERPROFILE%\FearVR) keep
        # their files after the game is uninstalled and would otherwise keep
        # reading as VR Ready. Test-StagedModStillValid is the shared check -
        # the startup quick-scan in Startup.ps1 calls exactly the same one.
        if ($vrInstalled -and $game.VrManifest) {
            $stageRoot = $null
            try { if ($recordedPathFile -and (Test-Path $recordedPathFile)) { $stageRoot = Read-InstalledPath -Game $game } } catch { $stageRoot = $null }
            if (-not $stageRoot -or -not (Test-Path $stageRoot)) { $stageRoot = Resolve-VrInstallRoot $game.VrInstallRoot }
            if (-not (Test-StagedModStillValid -Game $game -StageRoot $stageRoot)) { $vrInstalled = $false }
        }

        # Retrieve stored btnText reference
        $btnTxt = $null
        $btnBrd = $null
        $btnTxt = $null
        $btnBrd = $null
        $btnTxt = $card.Resources.Item("btnText")
        $btnBrd  = $card.Resources.Item("btnBorder")
        # Local accent for state-update brushes (mirrors New-GameCard logic)
        $accentHex = if ($game.Accent) { $game.Accent } elseif (-not $game.Bat) { "#445566" } else { "#666677" }
        $btnFgBrush = [System.Windows.Media.Brushes]::White

        # DualMode detection: a few Thunderstore games (REPO VR, Content
        # Warning VR) ship two parallel installs - the current auto-
        # updating Thunderstore mod inside the Steam library AND a
        # legacy pinned-depot install under C:\Games\<Name> VR\. When
        # BOTH exist we want a 3-way split start button. Detect by
        # checking the depot path independent of which mode the
        # priority chain above picked as $gameDir.
        $dualModeBothPresent = $false
        $dualModeCurrentDir  = $null
        $dualModeDepotDir    = $null
        if ($vrInstalled) {
            # Mode 1 candidate: any Steam-library steamapps\common\<SteamFolder>
            # that has the ModFile, next to the pinned depot build. Shared
            # probe (above) so the post-install refresh sees the same thing.
            $dmProbe = Get-DualModePresence -Game $game -Libs $steamLibs
            if ($dmProbe.BothPresent) {
                $dualModeBothPresent = $true
                $dualModeCurrentDir  = $dmProbe.CurrentDir
                $dualModeDepotDir    = $dmProbe.DepotDir
            }
        }

        # TwoMods detection (separate mechanism from the Current/Depot
        # DualMode above - does NOT touch DepotPath/DualMode). Games with
        # two alternative VR mods install each into its own subfolder
        # under the recorded .installed_path parent. VR Ready if EITHER
        # launcher is present; a launch choice is offered when BOTH are.
        $twoModsAnyPresent = $false
        $twoModsADir = $null
        $twoModsBDir = $null
        $tmAPresent = $false
        $tmBPresent = $false
        if ($game.TwoMods) {
            # Presence comes from the shared probe (above), so the scan and
            # the post-install refresh can never disagree about which mods
            # are on disk. The launch choice is offered as soon as EITHER
            # mod is present; a missing mod's button routes to its installer.
            $tmProbe  = Get-TwoModsPresence -Game $game -FallbackRoot $gameDir
            $tmParent = $tmProbe.Root
            if ($tmParent) {
                    $tmAPresent  = $tmProbe.APresent
                    $tmBPresent  = $tmProbe.BPresent
                    $twoModsADir = $tmProbe.ADir
                    $twoModsBDir = $tmProbe.BDir
                    if ($tmAPresent -or $tmBPresent) {
                        # If a ModFile is defined (GTA5 verifies RealVR.asi),
                        # require it at the recorded path too - a leftover
                        # launcher alone must NOT read as VR Ready without
                        # the actual VR mod on disk.
                        if ($game.ModFile) {
                            $tmRoot = $null
                            try { $tmRoot = Read-InstalledPath -Game $game } catch {}
                            if (-not $tmRoot) { $tmRoot = $tmParent }
                            # ModFileAlt matters here: BioShock's Epic build
                            # keeps the exe in Build\FinalEpic, so testing
                            # only ModFile would leave every Epic install
                            # short of VR Ready in this branch.
                            if ($tmRoot -and (Test-Path (Join-Path $tmRoot $game.ModFile))) { $vrInstalled = $true }
                            elseif ($tmRoot -and $game.ModFileAlt -and (Test-Path (Join-Path $tmRoot $game.ModFileAlt))) { $vrInstalled = $true }
                        } else {
                            $vrInstalled = $true
                        }
                    }
                    # TwoModsRequireBoth: some games must NOT offer the
                    # choice until both mods are really installed. BioShock
                    # is one - its two mods cannot coexist in the game
                    # folder, so the switch only makes sense once both are
                    # parked on disk.
                    if ($game.TwoModsRequireBoth) { $twoModsAnyPresent = ($tmAPresent -and $tmBPresent) }
                    else { $twoModsAnyPresent = ($tmAPresent -or $tmBPresent) }
            }
        }

        # Foreign-install / lost-marker fallback: if the game folder is known
        # (VR detected via ModFile) but the Hub-side launcher markers were
        # absent, detect each mod directly from its real file on disk - so a
        # GTA5 install done by ANOTHER Hub still shows that Motion is
        # available, not just VR Ready.
        # TwoModsRequireBoth games are skipped here on purpose: their two
        # mods share the game folder, so a file probe cannot tell them
        # apart (BioShock's payloads are BioshockVR.dll and bioshockvr.dll -
        # the same name on Windows). Only the per-mod launchers written by
        # the installer are trustworthy for those.
        if ($game.TwoMods -and $gameDir -and -not $game.TwoModsRequireBoth) {
            if (-not $tmAPresent -and $game.ModFile -and (Test-Path (Join-Path $gameDir $game.ModFile))) {
                $tmAPresent = $true
            }
            if (-not $tmBPresent -and $game.ModBProbeFile -and (Test-Path (Join-Path $gameDir $game.ModBProbeFile))) {
                $tmBPresent = $true
            }
            if ($tmAPresent -or $tmBPresent) { $twoModsAnyPresent = $true }
        }

        # One-time lufz VRMod baseline migration: lufz installs made before
        # the catalog pinned a version have no .installed_version file - the
        # generic version block below would silently SEED those to the
        # current pin and existing users would never see the update badge.
        # Every lufz install from before the pin can only be the single old
        # beta build, so: lufz mod present + version file missing = old
        # install. Write the old baseline once; the pin comparison below
        # then raises the Update badge, and the installer writes the real
        # version on the next (re)install, which clears it again.
        if ($game.ModBSub -eq "lufz" -and $tmBPresent) {
            try {
                $lufzIvp = Get-InstalledVersionPath -Game $game
                if ($lufzIvp -and -not (Test-Path $lufzIvp)) {
                    Set-Content -Path $lufzIvp -Value "1.0.0" -Encoding ASCII -Force
                }
            } catch {}
        }

        # Free games are available to install without buying, but that
        # does NOT mean they are installed. They only turn green when
        # their VR mod is actually on disk (vrInstalled). Until then
        # they stay in their normal accent state - same as any other
        # not-yet-installed game - so green keeps meaning "installed".
        # A FallbackPath or .installed_path match earlier may have set
        # $installed = $true (folder exists on disk), but for free games
        # that must NOT trigger the green "installed" card - only the
        # verified vrInstalled state does. So clear it here.
        # ---- Hytale VR: direct on-disk dual-file check ----------------
        # The game installs via its own external launcher (client under
        # %APPDATA%), the mod via our installer. BOTH files are verified
        # directly on disk on EVERY scan, independent of any marker or
        # priority logic above - nothing can bypass it:
        #   game = HytaleClient.exe under %APPDATA%
        #   mod  = combo launcher bat OR dashboard exe at a standard
        #          root (or the recorded custom root)
        # mod present            -> VR Ready
        # only the game present  -> installed
        # NOTE: Hytale is a PAID game (WIP pill only) - it must never be
        # treated as a free title.
        if ($game.Title -eq "Hytale VR") {
            $hyClient = $null
            try { $hyClient = Join-Path ([Environment]::GetFolderPath("ApplicationData")) "Hytale\install\release\package\game\latest\Client\HytaleClient.exe" } catch {}
            $hyClientOk = ($hyClient -and (Test-Path -LiteralPath $hyClient))
            $hyModRoot = $null
            # [IO.Path]::Combine, NOT Join-Path: Join-Path VALIDATES the
            # drive and throws DriveNotFoundException on machines without
            # a D:/E: drive, which killed this whole detection block
            # (Join-Path returned $null -> Test-Path -LiteralPath $null
            # -> terminating bind error -> "[scan] detection failed").
            # Combine is a pure string op; Test-Path itself handles
            # missing drives gracefully (returns $false, no throw).
            foreach ($hr in @("C:\Games\Hytale VR", "D:\Games\Hytale VR", "E:\Games\Hytale VR")) {
                $hyBat  = [System.IO.Path]::Combine($hr, "Start Hytale VR.bat")
                $hyDash = [System.IO.Path]::Combine($hr, "hytale_camera_dashboard.exe")
                if ((Test-Path -LiteralPath $hyBat) -or (Test-Path -LiteralPath $hyDash)) { $hyModRoot = $hr; break }
            }
            if (-not $hyModRoot) {
                $hyRec = $null
                try { $hyRec = Read-InstalledPath -Game $game } catch {}
                if ($hyRec) {
                    # Same drive-safety for the recorded path (it can point
                    # at a drive that no longer exists); Combine can still
                    # throw on illegal characters, so keep it guarded.
                    $hyRecOk = $false
                    try {
                        $hyRecOk = (Test-Path -LiteralPath ([System.IO.Path]::Combine($hyRec, "Start Hytale VR.bat"))) -or `
                                   (Test-Path -LiteralPath ([System.IO.Path]::Combine($hyRec, "hytale_camera_dashboard.exe")))
                    } catch {}
                    if ($hyRecOk) { $hyModRoot = $hyRec }
                }
            }
            if ($hyModRoot) {
                $installed   = $true
                $gameDir     = $hyModRoot
                $vrInstalled = $true
            } elseif ($hyClientOk -and -not $installed) {
                $installed = $true
                $gameDir   = (Split-Path -Parent $hyClient)
            }
        }

        if ($isFreeGame -and -not $vrInstalled) { $installed = $false }

        if ($vrInstalled) {
            # For Thunderstore-based mods: query live version and deprecated status
            $needsUpdate  = $false
            # $gameDir is resolved above; hand it over so the in-game
            # marker outranks the Hub-local copy.
            $installedVer = Read-InstalledVersion -Game $game -GameDir $gameDir

            if ($game.GitHubNightly) {
                $ghVer = $null
                # Cache the full release object (tag + asset timestamps)
                # so that games sharing a repo only hit the API once per
                # scan. REFramework-nightly is shared across all REF games;
                # rolling-update games (e.g. L4D2VR where the author replaces
                # the ZIP under the same tag) need per-asset updated_at.
                $cached = $null
                if ($script:scanGhTagCache.ContainsKey($game.GitHubNightly)) {
                    $cached = $script:scanGhTagCache[$game.GitHubNightly]
                } else {
                    $ghUrl  = "https://api.github.com/repos/$($game.GitHubNightly)/releases/latest"
                    $ghResp = Invoke-ScanWebGet -Uri $ghUrl -Headers @{ "User-Agent"="PCVR-Mods-Hub"; "Accept"="application/vnd.github+json" }
                    if ($ghResp) {
                        try {
                            $ghData = $ghResp.Content | ConvertFrom-Json
                            $assetMap = @{}
                            foreach ($a in $ghData.assets) { $assetMap[$a.name] = $a.updated_at }
                            $cached = @{ Tag = $ghData.tag_name; Assets = $assetMap }
                            $script:scanGhTagCache[$game.GitHubNightly] = $cached
                        } catch {
                            $script:scanGhTagCache[$game.GitHubNightly] = $null
                        }
                    } else {
                        # Server down or breaker tripped - cache the miss so
                        # other games sharing this repo don't retry either.
                        $script:scanGhTagCache[$game.GitHubNightly] = $null
                    }
                }
                if ($cached) {
                    # Pick what we compare against:
                    #  - RollingUpdate=$true games use the tracked asset's
                    #    updated_at timestamp (changes whenever the author
                    #    re-uploads the ZIP, even under the same tag).
                    #  - All other GitHubNightly games stay on tag_name
                    #    (REFramework-nightly bumps tags per build).
                    if ($game.RollingUpdate -and $game.RollingUpdateAsset) {
                        $ghVer = $cached.Assets[$game.RollingUpdateAsset]
                    } else {
                        $ghVer = $cached.Tag
                    }
                }
                if ($ghVer) {
                    if (-not $installedVer) {
                        # Seeding a missing marker with the current tag says
                        # "no marker = just installed latest". That only holds
                        # when the tracked mod is the ONLY mod for the entry.
                        # On a TwoMods entry (Forza Horizon 6: NALULUNA from
                        # ko-fi OR lufz from GitHub) the installer writes the
                        # marker ONLY for the lufz branch - so a missing
                        # marker means "lufz is not installed here". Seeding
                        # it anyway would nag a NALULUNA user with an Update
                        # badge for a mod they never installed. NoVersionSeed
                        # keeps that entry silent until lufz is really there.
                        if (-not $game.NoVersionSeed) {
                            Write-InstalledVersion -Game $game -Version $ghVer -GameDir $gameDir
                            $installedVer = $ghVer
                        }
                    } elseif ($installedVer -ne $ghVer) {
                        $needsUpdate = $true
                    }
                }
            } elseif ($game.ThunderstoreAuthor -and $game.ThunderstorePackage) {
                $tsUrl  = "https://thunderstore.io/api/experimental/package/$($game.ThunderstoreAuthor)/$($game.ThunderstorePackage)/"
                $tsResp = Invoke-ScanWebGet -Uri $tsUrl
                if ($tsResp) {
                  try {
                    $tsData = $tsResp.Content | ConvertFrom-Json
                    $tsVer  = $tsData.latest.version_number
                    $tsDepr = $tsData.is_deprecated -eq $true

                    # For Thunderstore games, the .ts_versions/ file the
                    # installer writes after each successful install is
                    # the authoritative source - it always reflects what
                    # was JUST installed. installed_version is a Hub-side
                    # cache that goes stale the moment the installer
                    # updates .ts_versions, so we must read .ts_versions
                    # first and let it override the cache.
                    $tsVerFile = Join-Path $gameDir "BepInEx\.ts_versions\$($game.ThunderstoreAuthor)-$($game.ThunderstorePackage)"
                    if (Test-Path $tsVerFile) {
                        $tsLocal = (Get-Content $tsVerFile -Raw).Trim()
                        if ($tsLocal) { $installedVer = $tsLocal }
                    }

                    if (-not $tsDepr -and $installedVer -and $installedVer -ne $tsVer) {
                        $needsUpdate = $true
                        # Do NOT pin installed_version to the OLD value
                        # here - the .ts_versions/ file already holds
                        # the truth and we resync the Hub cache after
                        # the user installs the update.
                    } elseif (-not $installedVer -and -not $tsDepr) {
                        Write-InstalledVersion -Game $game -Version $tsVer -GameDir $gameDir
                    } elseif ($installedVer -and $installedVer -eq $tsVer) {
                        # Up to date - keep the Hub cache in sync so a
                        # later scan without .ts_versions still works.
                        Write-InstalledVersion -Game $game -Version $installedVer -GameDir $gameDir
                    }
                  } catch {}
                }
            } elseif ($game.Title -eq "Anomaly VR") {
                # Migration to the AoE VR launcher: an OLD Hub install
                # still has versioned MODS\amomaly_aoe_vr* folders. Flag
                # "update" ONE last time to push the user onto the new
                # launcher installer. That installer's cleanup removes the
                # MODS\amomaly_aoe_vr* footprint, so this returns $null on
                # the next scan and the banner disappears for good - future
                # updates run through the launcher, not the Hub.
                if (Get-AnomalyInstalledModVersion -GameDir $gameDir) {
                    $needsUpdate = $true
                }
            } elseif ($game.Title -eq "Hytale VR") {
                # Hytale VR reads its installed version from the mod's OWN
                # CHANGELOG.md (first "## [x.y.z]" heading), which travels
                # with the mod - same idea as Luke Ross's in-folder
                # .real_vr_version. It must NOT use the generic GitHub
                # branch below: that branch seeds a MISSING marker with the
                # CURRENT latest tag, on the assumption that "no marker =
                # just installed latest". The pre-1.0 Hytale installer never
                # wrote a marker, so on the first scan after 1.0.0 shipped
                # the Hub stamped stale 0.1.x installs as "v1.0.0" and the
                # Update tile never appeared.
                $ghVer  = Get-GithubLatestTagCached -Repo $game.GithubRepo -IncludePrerelease:([bool]$game.GithubPrerelease)
                $hyInst = $null
                if ($gameDir) {
                    try {
                        $hyLog = [System.IO.Path]::Combine($gameDir, "CHANGELOG.md")
                        if (Test-Path -LiteralPath $hyLog) {
                            foreach ($hyLine in (Get-Content -LiteralPath $hyLog -ErrorAction Stop)) {
                                if ($hyLine -match '^##\s*\[(\d+(?:\.\d+)+)\]') { $hyInst = "v" + $matches[1]; break }
                            }
                        }
                    } catch {}
                }
                if ($hyInst) {
                    $installedVer = $hyInst
                    Write-InstalledVersion -Game $game -Version $hyInst -GameDir $gameDir
                    if ($ghVer -and (($hyInst -replace '^[vV]','') -ne ($ghVer -replace '^[vV]',''))) { $needsUpdate = $true }
                } else {
                    # 1.0.0+ always ships CHANGELOG.md, so its absence means a
                    # pre-1.0 install - flag the update regardless of whatever
                    # the old seeding may have stamped on. Self-correcting:
                    # after the update the CHANGELOG is there and drives the
                    # comparison from then on.
                    $needsUpdate = $true
                }
            } elseif ($game.GithubRepoB) {
                # TWO INDEPENDENT MODS IN ONE TILE (BioShock: balouza and
                # BioVRDev). Each mod has its own repo and its own version
                # marker, and a repo is only checked when THAT mod is really
                # on disk - a balouza release must never raise an Update
                # badge on a BioVRDev-only install. With both installed,
                # either repo can raise it. Presence is decided by the file
                # each mod parks in its own store; both fields may list
                # alternatives separated by "|" (Steam's Build\Final and
                # Epic's Build\FinalEpic).
                $twoRootV = $null
                try { $twoRootV = Read-InstalledPath -Game $game } catch {}
                if (-not $twoRootV) { $twoRootV = $gameDir }
                $twoPairs = @()
                if ($twoRootV -and (Test-Path -LiteralPath $twoRootV)) {
                    $twoDefs = @(
                        @{ Probe = $game.GithubRepoPresenceFile;  Repo = $game.GithubRepo;  Path = (Get-InstalledVersionPath  -Game $game) },
                        @{ Probe = $game.GithubRepoBPresenceFile; Repo = $game.GithubRepoB; Path = (Get-InstalledVersionPathB -Game $game) }
                    )
                    foreach ($td in $twoDefs) {
                        if (-not $td.Probe -or -not $td.Repo -or -not $td.Path) { continue }
                        foreach ($cand in (([string]$td.Probe) -split '\|')) {
                            $cand = $cand.Trim()
                            if (-not $cand) { continue }
                            if (Test-Path -LiteralPath (Join-Path $twoRootV $cand)) { $twoPairs += , $td; break }
                        }
                    }
                }
                foreach ($tp in $twoPairs) {
                    $tag = Get-GithubLatestTagCached -Repo $tp.Repo -IncludePrerelease:([bool]$game.GithubPrerelease)
                    if (-not $tag) { continue }
                    $have = $null
                    if (Test-Path -LiteralPath $tp.Path) {
                        try { $have = (Get-Content -LiteralPath $tp.Path -Raw -ErrorAction Stop).Trim() } catch {}
                    }
                    if ([string]::IsNullOrWhiteSpace($have)) {
                        # First scan after an install: seed, don't nag.
                        try { [System.IO.File]::WriteAllText($tp.Path, $tag, (New-Object System.Text.UTF8Encoding $false)) } catch {}
                    } elseif ($have -ne $tag) {
                        $needsUpdate = $true
                    }
                }
            } elseif ($game.GithubRepo) {
                # GitHub release check: latest tag vs the installed version.
                # Mirrors the Thunderstore branch above. Seeds the cache on
                # the first scan after install (GitHub installers always pull
                # releases/latest, so "no stored version yet" = current latest).
                $repoToCheck = $game.GithubRepo
                # Honor an AV-fallback choice: if the installer switched this
                # machine to the backup source, track THAT repo for updates so
                # the user is not nagged to update to a fork their AV blocks.
                if ($game.GithubRepoAlt) {
                    try {
                        $ipfV = Get-InstalledPathFile -Game $game
                        if ($ipfV) {
                            $vsrcV = Join-Path (Split-Path -Parent $ipfV) ".vrv_source"
                            if ((Test-Path $vsrcV) -and ((Get-Content $vsrcV -Raw -ErrorAction Stop).Trim() -eq "francisco")) { $repoToCheck = $game.GithubRepoAlt }
                        }
                    } catch {}
                }
                $ghVer = Get-GithubLatestTagCached -Repo $repoToCheck -IncludePrerelease:([bool]$game.GithubPrerelease)
                if ($ghVer) {
                    if (-not $installedVer) {
                        # Seeding a missing marker with the current tag says
                        # "no marker = just installed latest". That only holds
                        # when the tracked mod is the ONLY mod for the entry.
                        # On a TwoMods entry (Forza Horizon 6: NALULUNA from
                        # ko-fi OR lufz from GitHub) the installer writes the
                        # marker ONLY for the lufz branch - so a missing
                        # marker means "lufz is not installed here". Seeding
                        # it anyway would nag a NALULUNA user with an Update
                        # badge for a mod they never installed. NoVersionSeed
                        # keeps that entry silent until lufz is really there.
                        if (-not $game.NoVersionSeed) {
                            Write-InstalledVersion -Game $game -Version $ghVer -GameDir $gameDir
                            $installedVer = $ghVer
                        }
                    } elseif ($installedVer -ne $ghVer) {
                        $needsUpdate = $true
                    }
                }
            } elseif ($game.CodebergRepo) {
                # Wie der GitHub-Zweig darueber, nur gegen Codeberg. Gleiche
                # Regeln: fehlt der Marker, wird er mit dem aktuellen Tag
                # gesetzt ("kein Marker = gerade das Neueste installiert"),
                # es sei denn NoVersionSeed sagt etwas anderes; weicht der
                # Marker vom Tag ab, gibt es eine Update-Kachel.
                $cbVer = Get-CodebergLatestTagCached -Repo $game.CodebergRepo -IncludePrerelease:([bool]$game.CodebergPrerelease)
                if ($cbVer) {
                    if (-not $installedVer) {
                        if (-not $game.NoVersionSeed) {
                            Write-InstalledVersion -Game $game -Version $cbVer -GameDir $gameDir
                            $installedVer = $cbVer
                        }
                    } elseif (($installedVer -replace '^[vV]','') -ne ($cbVer -replace '^[vV]','')) {
                        $needsUpdate = $true
                    }
                }
            } elseif ($game.WebVersionUrl) {
                # Mods distributed only via their own website (the GRAND mod for
                # Alien Isolation). The published version is read via
                # Get-WebVersionCached, which caches the result on disk with the
                # same 6h TTL as the GitHub checks - so repeat scans skip the
                # live page fetch (the slowest single online check) instead of
                # paying it every time. No timeout is lowered, so a slow-but-
                # valid page is never cut short. Logged ([AICheck]).
                if (-not $global:HubScanOnlineDown) {
                  $wv = Get-WebVersionCached -Url $game.WebVersionUrl -Title $game.Title
                  if ($wv) {
                    if (-not $installedVer) {
                        Write-InstalledVersion -Game $game -Version $wv -GameDir $gameDir
                        $installedVer = $wv
                    } elseif ($installedVer -ne $wv) {
                        $needsUpdate = $true
                    }
                  }
                }
            } elseif ($game.Bat -like 'LukeRossVR*') {
                # Luke Ross: read the installed build primarily from a version
                # file INSIDE the mod's install folder (travels with the mod, so
                # any Hub - even a fresh one - sees it). Fall back to the Hub-
                # local .real_version_<title> marker (NOT .installed_version,
                # which Invoke-PostInstallRefresh deletes). We are inside
                # "if ($vrInstalled)", so the mod is on disk; no version found
                # anywhere = installed by an older Hub that didn't record it.
                $nvDigits = ("$($global:REALVR_NEWEST)" -replace '[^\d]','')
                $lrInst   = $null
                if ($gameDir) {
                    $lrGameMarker = Join-Path $gameDir ".real_vr_version"
                    if (Test-Path $lrGameMarker) {
                        $lrInst = (Get-Content $lrGameMarker -Raw -ErrorAction SilentlyContinue)
                        if ($lrInst) { $lrInst = $lrInst.Trim() }
                    }
                }
                if (-not $lrInst) {
                    $lrIvp    = Get-InstalledVersionPath -Game $game
                    $lrMarker = if ($lrIvp) { $lrIvp -replace '\.installed_version_', '.real_version_' } else { $null }
                    if ($lrMarker -and (Test-Path $lrMarker)) {
                        $lrInst = (Get-Content $lrMarker -Raw -ErrorAction SilentlyContinue)
                        if ($lrInst) { $lrInst = $lrInst.Trim() }
                    }
                }
                if (-not $lrInst) {
                    if ($nvDigits) { $needsUpdate = $true }
                } else {
                    $ivDigits = ("$lrInst" -replace '[^\d]','')
                    if ($nvDigits -and $ivDigits -and ([int64]$nvDigits -gt [int64]$ivDigits)) { $needsUpdate = $true }
                }
            } else {
                # Non-Thunderstore: compare Mod string version to installed_version
                $expectedVer = Get-ModVersionFromString -ModString $game.Mod
                if ($expectedVer) {
                    if (-not $installedVer) {
                        Write-InstalledVersion -Game $game -Version $expectedVer -GameDir $gameDir
                        $installedVer = $expectedVer
                    } elseif ($installedVer -ne $expectedVer) {
                        $needsUpdate = $true
                    }
                }
            }

            # Date-based update pin for manual-download mods (Nexus etc.)
            # with NO online version check: the catalog can carry
            #   ModReleasedAt = "yyyy-MM-dd"
            # (maintained by hand - set it to the date the modder shipped
            # the newest build). If the installed mod file on disk is OLDER
            # than that date, the user installed before the release ->
            # Update badge. Install moment = MAX(CreationTime, LastWrite):
            # archives preserve the modder's build time as LastWriteTime,
            # extraction stamps CreationTime with the install moment.
            #
            # 7-DAY GRACE, and why it is essential: on an IN-PLACE update
            # (extracting over the old install - the normal update path)
            # Windows KEEPS the file's original CreationTime, and the new
            # LastWriteTime is the modder's build time, which sits a few
            # days BEFORE the release date. Without grace the badge would
            # never clear after such an update. Threshold = release date
            # minus 7 days: fresh builds (within a week of release) count
            # as current, while genuinely old installs stay flagged.
            # Trade-off: someone who installed the OLD build in the last 7
            # days before the new release misses the badge - acceptable;
            # push ModReleasedAt a week later if that ever matters.
            # EXACT VARIANT for mods with no version number anywhere
            # (Patreon downloads): ModBuildStamp = "yyyy-MM-dd HH:mm"
            # is the LastWriteTime the modder's own build carries INSIDE
            # the zip. Zip extraction preserves that timestamp, so every
            # install of a given build has the same stamp on disk - no
            # matter WHEN it was extracted. An older build therefore
            # always reads older, and a fresh one always reads current.
            # This is stricter than ModReleasedAt below, which has to
            # fall back on the install moment and cannot tell "installed
            # the old build yesterday" from "installed the new one".
            # A 2h slack absorbs timezone/DST oddities in zip stamps.
            # MOST RELIABLE VARIANT: a version file the installer itself
            # wrote into the game folder. ModVersionFile = path relative to
            # the game folder, ModVersion = what a current install contains.
            # Everything below infers the version from file timestamps, which
            # breaks whenever an archive carries older dates than the release
            # it belongs to - exactly why GAMMA kept showing an update right
            # after being updated. A written version is not a guess.
            # File present -> AUTHORITATIVE, the timestamp checks are skipped.
            # File missing (installed before this existed, or by hand) ->
            # fall through to the old behaviour, nothing gets worse.
            # ModOutdatedFile: a file that ONLY the old layout has. Unlike
            # ModLegacyFile below it does not care whether the current ModFile
            # is there too - some mods keep the same marker across a
            # restructure, so its presence proves nothing. F.E.A.R. VR is that
            # case: bin\x64\fearvr-host.exe exists in both generations, while
            # tools\install.ps1 exists only in the pre-overlay one.
            if (-not $needsUpdate -and $game.ModOutdatedFile -and $gameDir) {
                try {
                    if (Test-Path -LiteralPath (Join-Path $gameDir $game.ModOutdatedFile)) { $needsUpdate = $true }
                } catch {}
            }

            # An install from BEFORE a mod changed its file layout still has
            # the old marker on disk but not the new one. That is proof of an
            # outdated install, whatever any version marker says - so it
            # forces the Update badge. ModLegacyFile names that old marker.
            if (-not $needsUpdate -and $game.ModLegacyFile -and $game.ModFile -and $gameDir) {
                try {
                    if ((Test-Path -LiteralPath (Join-Path $gameDir $game.ModLegacyFile)) -and
                        -not (Test-Path -LiteralPath (Join-Path $gameDir $game.ModFile))) {
                        $needsUpdate = $true
                    }
                } catch {}
            }

            # ModRequiredFile: eine Datei, die eine VOLLSTAENDIGE Installation
            # haben MUSS. Ist die Mod da (ModFile vorhanden), diese Datei aber
            # NICHT, dann wurde mit einem aelteren Rezept installiert - z.B.
            # bevor eine Abhaengigkeit dazukam. Das ist der Gegenfall zu
            # ModLegacyFile: dort verraet eine ALTE Datei den alten Stand,
            # hier verraet eine FEHLENDE Datei den unvollstaendigen.
            # Ohne diesen Fall bekaeme niemand ein Update angezeigt, dessen
            # Installation nur unvollstaendig ist - die Version der Hauptmod
            # hat sich ja nicht geaendert.
            if (-not $needsUpdate -and $game.ModRequiredFile -and $game.ModFile -and $gameDir) {
                try {
                    if ((Test-Path -LiteralPath (Join-Path $gameDir $game.ModFile)) -and
                        -not (Test-Path -LiteralPath (Join-Path $gameDir $game.ModRequiredFile))) {
                        $needsUpdate = $true
                    }
                } catch {}
            }

            $verFileDecided = $false
            if ($game.ModVersionFile -and $game.ModVersion -and $gameDir) {
                try {
                    $vfPath = Join-Path $gameDir $game.ModVersionFile
                    if (Test-Path -LiteralPath $vfPath) {
                        $vfHave = ((Get-Content -LiteralPath $vfPath -Raw -ErrorAction Stop) -replace '[^\x20-\x7E]', '').Trim()
                        $verFileDecided = $true
                        if ($vfHave -ne ([string]$game.ModVersion).Trim()) { $needsUpdate = $true }
                    }
                } catch {}
            }

            if (-not $verFileDecided -and -not $needsUpdate -and $game.ModBuildStamp -and $game.ModFile -and $gameDir) {
                try {
                    $bsFile = Join-Path $gameDir $game.ModFile
                    if (Test-Path -LiteralPath $bsFile) {
                        $bsDate = [DateTime]::ParseExact([string]$game.ModBuildStamp, 'yyyy-MM-dd HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)
                        $bsItem = Get-Item -LiteralPath $bsFile -ErrorAction Stop
                        if ($bsItem.LastWriteTime -lt $bsDate.AddHours(-2)) { $needsUpdate = $true }
                    }
                } catch {}
            }

            if (-not $verFileDecided -and -not $needsUpdate -and $game.ModReleasedAt -and $game.ModFile -and $gameDir) {
                try {
                    $mrFile = Join-Path $gameDir $game.ModFile
                    if (Test-Path -LiteralPath $mrFile) {
                        $mrDate = [DateTime]::ParseExact([string]$game.ModReleasedAt, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
                        $mrThreshold = $mrDate.ToUniversalTime().AddDays(-7)
                        $mrItem = Get-Item -LiteralPath $mrFile -ErrorAction Stop
                        $mrInstalled = if ($mrItem.CreationTimeUtc -gt $mrItem.LastWriteTimeUtc) { $mrItem.CreationTimeUtc } else { $mrItem.LastWriteTimeUtc }
                        if ($mrInstalled -lt $mrThreshold) { $needsUpdate = $true }
                    }
                } catch {}
            }

            if ($needsUpdate) {
                # Update available: switch to a unified blue ("update
                # blue" = #2563eb) regardless of the accent color, so
                # the whole library reads "blue = update" at a glance.
                # Card gets blue tint + blue glow ring + blue button.
                $UPDATE_BLUE = "#2563eb"
                $card.Background  = New-CardTintBrush -BaseHex "#16161a" -TintHex $UPDATE_BLUE -TopAlpha 0.22 -MidAlpha 0.05
                $bAcc2 = ConvertTo-MediaColor $UPDATE_BLUE
                $bBase2 = ConvertTo-MediaColor "#16161a"
                $bMix2  = [System.Windows.Media.Color]::FromRgb(
                    [byte]([Math]::Round($bAcc2.R*0.40 + $bBase2.R*0.60)),
                    [byte]([Math]::Round($bAcc2.G*0.40 + $bBase2.G*0.60)),
                    [byte]([Math]::Round($bAcc2.B*0.40 + $bBase2.B*0.60))
                )
                $card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush $bMix2
                # Outer glow: DropShadowEffect with no offset = soft halo
                $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
                $glow.Color = $bAcc2
                $glow.BlurRadius = 16
                $glow.ShadowDepth = 0
                $glow.Opacity = 0.55
                $card.Effect = $glow
                $card.Tag = "vrupdate"
                if ($btnTxt) {
                    $btnTxt.Text       = "Update"
                    $btnTxt.Foreground = [System.Windows.Media.Brushes]::White
                }
                if ($btnBrd) {
                    $btnBrd.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($UPDATE_BLUE)
                    $btnBrd.BorderThickness = [System.Windows.Thickness]::new(0)
                }
                # Repaint the accent cap blue to match the update theme
                $cap = $card.Resources.Item("accentCap")
                if ($cap) {
                    # Keep the cap in the original game accent (not
                    # blue) - the update signal lives on the right-
                    # side pill that appears on hover. Cap stays in
                    # the game's identity colour so the card still
                    # reads as the same game at a glance.
                    $cap.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accentHex)
                    $cap.Visibility = [System.Windows.Visibility]::Visible
                }
                # Refresh stored base brushes so hover also reflects the new state
                $card.Resources.Remove("baseBgBrush") | Out-Null
                $card.Resources.Remove("baseBdBrush") | Out-Null
                $card.Resources.Add("baseBgBrush", $card.Background)
                $card.Resources.Add("baseBdBrush", $card.BorderBrush)
                # Override stored accent too - MouseEnter reads
                # baseAccent for the vrupdate hover tint (line ~2700).
                # Without this swap, hovering an update card would
                # tint it back in the original game accent.
                $card.Resources.Remove("baseAccent") | Out-Null
                $card.Resources.Add("baseAccent", $UPDATE_BLUE)
                $global:gameStateMap[$game.Title] = @{ Tag="vrupdate"; Accent=$accentHex; State="update"; BtnText="Update"; DualMode=$dualModeBothPresent; CurrentDir=$dualModeCurrentDir; DepotDir=$dualModeDepotDir; TwoMods=$twoModsAnyPresent; ModAPresent=$tmAPresent; ModBPresent=$tmBPresent; ModADir=$twoModsADir; ModBDir=$twoModsBDir; ModAName=$game.ModAName; ModBName=$game.ModBName; GameDir=$gameDir }
            } else {
                # VR Ready: shift the whole card to a calm green tint.
                # Button becomes outline-style with checkmark.
                $card.Background  = New-CardTintBrush -BaseHex "#16161a" -TintHex "#46a05a" -TopAlpha 0.10 -MidAlpha 0.02
                $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1d2e22")
                $card.Effect = $null
                $card.Tag = "vrinstalled"
                if ($btnTxt -and $btnBrd) {
                    $btnTxt.Text       = "VR Ready"
                    $fblS = $card.Resources.Item("freeBtnLabel"); if ($fblS) { $fblS.Visibility = [System.Windows.Visibility]::Collapsed }
                    $btnTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
                    # Button itself becomes outline-style (transparent fill, soft green border)
                    $btnBrd.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
                    $btnBrd.BorderThickness = [System.Windows.Thickness]::new(1)
                    $btnBrd.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
                }
                # Hide the accent cap - VR Ready is a complete state,
                # no "action pending" signal needed.
                $cap = $card.Resources.Item("accentCap")
                if ($cap) { $cap.Visibility = [System.Windows.Visibility]::Collapsed }
                # Reveal the reload pill on the right of the button
                $card.Resources.Remove("baseBgBrush") | Out-Null
                $card.Resources.Remove("baseBdBrush") | Out-Null
                $card.Resources.Add("baseBgBrush", $card.Background)
                $card.Resources.Add("baseBdBrush", $card.BorderBrush)
                $global:gameStateMap[$game.Title] = @{ Tag="vrinstalled"; Accent=$accentHex; State="ready"; BtnText="VR Ready"; GameDir=$gameDir; DualMode=$dualModeBothPresent; CurrentDir=$dualModeCurrentDir; DepotDir=$dualModeDepotDir; TwoMods=$twoModsAnyPresent; ModAPresent=$tmAPresent; ModBPresent=$tmBPresent; ModADir=$twoModsADir; ModBDir=$twoModsBDir; ModAName=$game.ModAName; ModBName=$game.ModBName }
            }
            $vrFound++
            $found++
        } elseif ($installed) {
            # Game installed, no VR mod yet: noticeable green tint + styled button
            $conv = [System.Windows.Media.BrushConverter]::new()
            $card.Background  = New-CardTintBrush -BaseHex "#16161a" -TintHex "#46a05a" -TopAlpha 0.18 -MidAlpha 0.06
            $card.BorderBrush = $conv.ConvertFromString("#2a5c38")
            $card.BorderThickness = [System.Windows.Thickness]::new(1)
            $card.Effect = $null
            $card.Tag = "installed"
            $btnLabel = if ($game.Bat) { "Install" } elseif ($game.Type -eq "steam") { "Open in Steam" } elseif ($game.Type -eq "itch") { "Open on itch.io" } else { "Get Installer" }
            if ($btnTxt) {
                $btnTxt.Text       = $btnLabel
                $btnTxt.Foreground = $conv.ConvertFromString("#66dd88")
            }
            if ($btnBrd) {
                $btnBrd.Background      = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
                $btnBrd.BorderThickness = [System.Windows.Thickness]::new(1)
                $btnBrd.BorderBrush     = $conv.ConvertFromString("#2a5c38")
            }
            # Cap recolored green to match the card's installed-but-not-VR
            # tint. Still signals "action available: install VR mod".
            $cap = $card.Resources.Item("accentCap")
            if ($cap) {
                $cap.Background = $conv.ConvertFromString("#5cb344")
                $cap.Visibility = [System.Windows.Visibility]::Visible
            }
            $global:gameStateMap[$game.Title] = @{ Tag="installed"; State="installed"; Border="#2a5c38"; BtnText=$btnLabel; BtnColor="#66dd88" }
            $found++
        } else {
            # Default state (game not installed): revert visuals to
            # the very first-paint look. We use the immutable
            # "original*" resources here, not the live "base*" ones,
            # because base* may have been overwritten by a previous
            # update/ready state painter. Without this fallback, a
            # card that was once blue (update) would stay blue even
            # after being uninstalled.
            $origBg = $card.Resources.Item("originalBgBrush")
            $origBd = $card.Resources.Item("originalBdBrush")
            $origAcc = $card.Resources.Item("originalAccent")
            if ($origBg) { $card.Background  = $origBg }
            if ($origBd) { $card.BorderBrush = $origBd }
            $card.Effect = $null
            $card.Tag = ""
            # Restore base* keys too so future hovers tint correctly.
            if ($origBg) {
                $card.Resources.Remove("baseBgBrush") | Out-Null
                $card.Resources.Add("baseBgBrush", $origBg)
            }
            if ($origBd) {
                $card.Resources.Remove("baseBdBrush") | Out-Null
                $card.Resources.Add("baseBdBrush", $origBd)
            }
            if ($origAcc) {
                $card.Resources.Remove("baseAccent") | Out-Null
                $card.Resources.Add("baseAccent", $origAcc)
            }
            if ($btnTxt) {
                $btnTxt.Text       = if ($game.Bat) { "Install" } elseif ($game.Type -eq "steam") { "Open in Steam" } elseif ($game.Type -eq "itch") { "Open on itch.io" } else { "Get Installer" }
                $btnTxt.Foreground = [System.Windows.Media.Brushes]::White
            }
            # Reset the cap back to the game's original accent color.
            # Cards that flipped through vrupdate (blue cap) or
            # installed (green cap) need to revert here.
            $cap = $card.Resources.Item("accentCap")
            if ($cap) {
                $capColor = if ($origAcc) { $origAcc } else { $accentHex }
                $cap.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($capColor)
                $cap.Visibility = [System.Windows.Visibility]::Visible
            }
            # Free games stay in this accent state (never green unless
            # the VR mod is on disk). Give them a soft accent-coloured
            # glow so they still read as "special / no purchase needed"
            # without borrowing the green installed look.
            if ($isFreeGame) {
                try {
                    $glowAcc = if ($origAcc) { $origAcc } else { $accentHex }
                    # No DropShadowEffect here - a whole-card glow rasterizes
                    # the card and dims/softens the title text. Instead we
                    # highlight free games with a brighter accent-coloured
                    # border, which leaves the content layer untouched so
                    # text stays maximally readable.
                    $card.Effect = $null
                    $fbCol = Get-GlowColor $glowAcc
                    $card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush $fbCol
                    $card.BorderThickness = [System.Windows.Thickness]::new(1)
                    # Reveal the "FREE" tag on the Install button now that
                    # Check Installed has confirmed the free game (it starts
                    # hidden and only shows post-scan).
                    $fblShow = $card.Resources.Item("freeBtnLabel")
                    if ($fblShow) { $fblShow.Visibility = [System.Windows.Visibility]::Visible }
                    # Record a "free" state so later repaints (filter
                    # switches, etc.) keep the accent border + FREE label
                    # instead of reverting to a plain not-installed card.
                    $global:gameStateMap[$game.Title] = @{ Tag="free"; State="free"; Accent=$accentHex; BtnText=$btnTxt.Text }
                } catch {}
            } else {
                # Not installed and not free: drop any stale state entry
                # (e.g. a prior "VR Ready") so a later Rebuild-Lookups
                # repaint cannot restore the green card from the map after
                # the user deleted the install folder. The inline reset
                # above fixes the card now; this stops it coming back.
                if ($global:gameStateMap.ContainsKey($game.Title)) {
                    $global:gameStateMap.Remove($game.Title) | Out-Null
                }
            }
        }
        Sync-FrostedCardState -Card $card -BtnTxt $btnTxt -BtnBrd $btnBrd
            } catch {
            try {
                if (-not $global:ScanGameErrors) { $global:ScanGameErrors = New-Object System.Collections.ArrayList }
                [void]$global:ScanGameErrors.Add(("{0}: {1}" -f $game.Title, $_.Exception.Message))
                Write-Host ("  [scan] detection failed for '" + $game.Title + "': " + $_.Exception.Message) -ForegroundColor Yellow
            } catch {}
        }
}

    # Update the counter button. Pre-scan it showed "Check Installed"
    # in CheckInstalledText; post-scan we hide that and reveal the
    # CheckInstalledCount StackPanel where the numbers ("47" / "42")
    # live in their own ExtraBold + #5fff8f TextBlocks so they pop
    # against the surrounding muted "installed" / "VR ready" labels.
    # If no VR-ready games were found we hide the separator + VR
    # ready segment entirely to keep the button compact.
    if ($checkInstalledText) {
        $checkInstalledText.Visibility = [System.Windows.Visibility]::Collapsed
    }
    if ($checkInstalledCountInst)  { $checkInstalledCountInst.Text  = "$found" }
    if ($checkInstalledCountReady) { $checkInstalledCountReady.Text = "$vrFound" }
    if ($checkInstalledCount) {
        $checkInstalledCount.Visibility = [System.Windows.Visibility]::Visible
    }
    if ($checkInstalledCountSep -and $checkInstalledCountReady) {
        $sepVis = if ($vrFound -gt 0) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
        $checkInstalledCountSep.Visibility   = $sepVis
        $checkInstalledCountReady.Visibility = $sepVis
        # Also collapse the trailing " VR ready" label when there's
        # no VR-ready count. The label is the sibling immediately
        # after CheckInstalledCountReady in the StackPanel.
        $parent = $checkInstalledCountReady.Parent
        if ($parent -and $parent.Children.Count -ge 5) {
            $parent.Children[4].Visibility = $sepVis
        }
    }
    # Promote the counter glow from dimmed (BlurRadius 8 / Opacity
    # 0.25) to the full eye-catcher (BlurRadius 18 / Opacity 0.55).
    # The Effect object on $checkInstalledBtn is the one we built
    # at module init; we mutate its properties so the live element
    # picks up the new look immediately without a re-render.
    if ($checkInstalledBtn.Effect -is [System.Windows.Media.Effects.DropShadowEffect]) {
        $checkInstalledBtn.Effect.BlurRadius = 12
        $checkInstalledBtn.Effect.Opacity    = 0.22
    }
    # Reveal the shimmer overlay. It was Collapsed during the pre-
    # scan "Check Installed" state to keep that state calm; now
    # that the counter is the eye-catcher, the sweep can run. The
    # underlying animation has been ticking since module init, so
    # the shimmer joins the cycle wherever it currently is - no
    # explicit Start needed and no jarring "Frame 0" jump.
    # Skip if the user has opted out of the shimmer (either
    # session-only via "Disable shimmer" or persistently via
    # "Always Disable" -> shimmerDisabled in hub-settings).
    if ($checkInstalledShimmer -and -not $script:shimmerDisabled) {
        $checkInstalledShimmer.Visibility = [System.Windows.Visibility]::Visible
    }
    # Drop any glow-hover stash on this TextBlock - if the user
    # clicked while hovering, MouseLeave would otherwise restore
    # the pre-click foreground (default dimmed green) and undo the
    # brighter post-scan color we just set.
    if ($checkInstalledText -and $checkInstalledText.Resources.Contains("ghFg")) {
        $checkInstalledText.Resources.Remove("ghFg") | Out-Null
    }

    # Force WPF to re-render all modified cards
    $window.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Render, [action]{
        foreach ($list in @($ownList, $ownListGP, $extList)) {
            $list.InvalidateVisual()
            $list.UpdateLayout()
        }
    })

    # Apply saved states to current cards immediately (no scale-switch needed)
    if ($global:gameStateMap -and $global:gameStateMap.Count -gt 0) {
        foreach ($card in @($global:cardGameMap.Keys)) {
            # Same paced yield as in the detection loop - repainting 200+
            # cards is the second place a scan can sit on the UI thread
            # long enough to look dead.
            if ($script:scanPumpWatch -and $script:scanPumpWatch.ElapsedMilliseconds -ge 80) {
                $script:scanPumpWatch.Restart()
                $script:scanHeartbeat = Get-Date
                try { $window.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, $script:scanPumpAction) } catch {}
            }
            $g = $global:cardGameMap[$card]
            if (-not $g.Title) { continue }
            $state = $global:gameStateMap[$g.Title]
            if (-not $state) { continue }
            $card.Tag = $state.Tag
            $accH = if ($state.Accent) { $state.Accent } else { $card.Resources.Item("baseAccent") }
            if (-not $accH) { $accH = "#666677" }
            $btnTxt = $card.Resources.Item("btnText")
            $btnBrd = $card.Resources.Item("btnBorder")
            $card.Effect = $null

            switch ($state.State) {
                "update" {
                    # Update state: unified blue (#2563eb), regardless of accent.
                    $UPDATE_BLUE = "#2563eb"
                    $card.Background = New-CardTintBrush -BaseHex "#16161a" -TintHex $UPDATE_BLUE -TopAlpha 0.22 -MidAlpha 0.05
                    $aA = ConvertTo-MediaColor $UPDATE_BLUE; $aB = ConvertTo-MediaColor "#16161a"
                    $card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(
                        [byte]([Math]::Round($aA.R*0.40 + $aB.R*0.60)),
                        [byte]([Math]::Round($aA.G*0.40 + $aB.G*0.60)),
                        [byte]([Math]::Round($aA.B*0.40 + $aB.B*0.60))
                    ))
                    $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
                    $glow.Color = $aA; $glow.BlurRadius = 16; $glow.ShadowDepth = 0; $glow.Opacity = 0.55
                    $card.Effect = $glow
                    if ($btnTxt) {
                        $btnTxt.Text = "Update"
                        $btnTxt.Foreground = [System.Windows.Media.Brushes]::White
                    }
                    if ($btnBrd) {
                        $btnBrd.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($UPDATE_BLUE)
                        $btnBrd.BorderThickness = [System.Windows.Thickness]::new(0)
                    }
                    # Refresh resources so hover tint matches the new
                    # state. Without these the rebuilt card would
                    # hover in its original accent color, not blue.
                    $card.Resources.Remove("baseBgBrush") | Out-Null
                    $card.Resources.Remove("baseBdBrush") | Out-Null
                    $card.Resources.Add("baseBgBrush", $card.Background)
                    $card.Resources.Add("baseBdBrush", $card.BorderBrush)
                    $card.Resources.Remove("baseAccent") | Out-Null
                    $card.Resources.Add("baseAccent", $UPDATE_BLUE)
                }
                "ready" {
                    $card.Background = New-CardTintBrush -BaseHex "#16161a" -TintHex "#46a05a" -TopAlpha 0.10 -MidAlpha 0.02
                    $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1d2e22")
                    if ($btnTxt) {
                        $btnTxt.Text = "VR Ready"
                        $btnTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
                    }
                    $fblR = $card.Resources.Item("freeBtnLabel")
                    if ($fblR) { $fblR.Visibility = [System.Windows.Visibility]::Collapsed }
                    if ($btnBrd) {
                        $btnBrd.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
                        $btnBrd.BorderThickness = [System.Windows.Thickness]::new(1)
                        $btnBrd.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
                    }
                }
                "free" {
                    # Free game, not yet VR-installed: brighter accent
                    # border (no whole-card glow, so text stays crisp) +
                    # reveal the FREE label on the button.
                    try {
                        $card.Effect = $null
                        $card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush (Get-GlowColor $accH)
                        $card.BorderThickness = [System.Windows.Thickness]::new(1)
                    } catch {}
                    if ($btnTxt -and $state.BtnText) { $btnTxt.Text = $state.BtnText }
                    $fblF = $card.Resources.Item("freeBtnLabel")
                    if ($fblF) { $fblF.Visibility = [System.Windows.Visibility]::Visible }
                }
                default {
                    if ($btnTxt -and $state.BtnText) { $btnTxt.Text = $state.BtnText }
                }
            }
            Sync-FrostedCardState -Card $card -BtnTxt $btnTxt -BtnBrd $btnBrd
        }
    }
    # Mirror new state into discover tiles, if they've been built.
    if ($global:discoverPanel -and $global:DiscoverTilesBuilt) {
        Refresh-DiscoverStatuses
    }
    # If a detail page is currently open, re-render it so the
    # action button reflects the new state (Install Mod -> VR Ready)
    # without the user having to navigate away and back.
    if ($global:currentDetailGame -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
        Show-DiscoverDetail -Game $global:currentDetailGame
    }
    # Always re-apply the filter after a scan - the gameStateMap
    # was just rewritten and the Installed filter (if active) needs
    # the new visibility set immediately. Cheap to run unconditionally.
    if (Get-Command Apply-Filter -ErrorAction SilentlyContinue) {
        Apply-Filter
    }
    # Recently Played row may now have more candidates - the scan
    # might have just revealed installed games that weren't known
    # at first launch. Cheap rebuild keeps the row in sync.
    if (Get-Command Build-RecentlyPlayed -ErrorAction SilentlyContinue) {
        Build-RecentlyPlayed
    }
    # Restore a correct, consistent pill state after all the dispatcher
    # pumping above. Guarantees the anchor pill is visible (it must never
    # vanish) and the partner matches the current hover state.
    if (Get-Command Sync-InstallPills -ErrorAction SilentlyContinue) {
        Sync-InstallPills
    }

    # Scan done: lift the counter button up into the header (TopScanSlot) so the
    # filter row shows only the Needs Mod / VR Ready pills, while the
    # "X on PC / Y VR ready" totals read as a status line beside the title.
    # On the FIRST lift we play a short slide-up + fade so the eye follows the
    # button travelling up from the filter row into the header, then a brief
    # green glow pulse settles on the totals. Idempotent: a re-scan finds it
    # already in the slot and skips both the move and the animation.
    $hg   = $global:window.FindName("CheckInstalledHoverGroup")
    $slot = $global:window.FindName("TopScanSlot")
    if ($hg -and $slot -and ($hg.Parent -ne $slot)) {
        $p = $hg.Parent
        if ($p -and $p.Children.Contains($hg)) { $p.Children.Remove($hg) | Out-Null }
        $hg.Margin = [System.Windows.Thickness]::new(0)
        $slot.Children.Add($hg) | Out-Null

        # Pre-paint startup scan: the window has not been shown yet, so the
        # measurement below cannot work and nobody can see an animation.
        # Set the final state and let Startup.ps1 re-align after the first
        # real layout (ContentRendered).
        $prePaint = [bool]$global:PrePaintScanActive

        Align-TopScanSlot
        if ($prePaint) { $global:TopScanSlotNeedsAlign = $true }

        if (-not $prePaint) {
        $tt = New-Object System.Windows.Media.TranslateTransform
        $tt.Y = 46
        $hg.RenderTransform = $tt
        $hg.Opacity = 0.25
        $ease = New-Object System.Windows.Media.Animation.CubicEase
        $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
        $slide = New-Object System.Windows.Media.Animation.DoubleAnimation
        $slide.From = 46; $slide.To = 0
        $slide.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(420))
        $slide.EasingFunction = $ease
        $fade = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fade.From = 0.25; $fade.To = 1
        $fade.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(420))
        $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $slide)
        $hg.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fade)

        $cib = $global:window.FindName("CheckInstalledBtn")
        if ($cib -and ($cib.Effect -is [System.Windows.Media.Effects.DropShadowEffect])) {
            $restGlow = $cib.Effect.Opacity
            $pulse = New-Object System.Windows.Media.Animation.DoubleAnimation
            $pulse.From = $restGlow; $pulse.To = 0.9
            $pulse.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(260))
            $pulse.AutoReverse = $true
            $pulse.BeginTime = [TimeSpan]::FromMilliseconds(170)
            $pulse.FillBehavior = [System.Windows.Media.Animation.FillBehavior]::Stop
            $cib.Effect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty, $pulse)
        }

        # Reveal Needs Mod / VR Ready a beat LATER (~520 ms). If they appear
        # immediately they widen the filter row and shove the counter button
        # sideways before it can lift off. By the time this fires the button is
        # already up in the header, so the pills simply fade in.
        $script:pillRevealTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:pillRevealTimer.Interval = [TimeSpan]::FromMilliseconds(520)
        $script:pillRevealTimer.Add_Tick({
            $script:pillRevealTimer.Stop()
            $g = $global:window.FindName("InstalledFilterGroup")
            if ($g) {
                $g.Visibility = [System.Windows.Visibility]::Visible
                $gf = New-Object System.Windows.Media.Animation.DoubleAnimation
                $gf.From = 0; $gf.To = 1
                $gf.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(260))
                $g.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $gf)
                if (Get-Command Set-InstallFilterMode -ErrorAction SilentlyContinue) { Set-InstallFilterMode $script:installFilterMode }
                # On a detail page the pills must show THIS game's marked state,
                # not the list filter state - re-mark after Set-InstallFilterMode
                # (which runs later than the earlier detail refresh) so the
                # detail marking wins.
                if ($global:currentDetailGame -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
                    if (Get-Command Set-DetailFilterMarks -ErrorAction SilentlyContinue) { Set-DetailFilterMarks -Game $global:currentDetailGame }
                }
            }
        })
        $script:pillRevealTimer.Start()
        } else {
            # Pre-paint startup scan: no animation choreography to protect,
            # so show the pills right away. The very first frame the user
            # sees is then the finished layout - no counter sitting in the
            # wrong spot for half a second and jumping sideways after.
            $gp = $global:window.FindName("InstalledFilterGroup")
            if ($gp) {
                $gp.Visibility = [System.Windows.Visibility]::Visible
                $gp.Opacity = 1
                if (Get-Command Set-InstallFilterMode -ErrorAction SilentlyContinue) { Set-InstallFilterMode $script:installFilterMode }
            }
            if ($hg) { $hg.Opacity = 1 }
        }
    } else {
        # Re-scan: button already in the header and pills already showing - just
        # make sure they are visible and correctly painted.
        $g2 = $global:window.FindName("InstalledFilterGroup")
        if ($g2) {
            $g2.Visibility = [System.Windows.Visibility]::Visible
            if (Get-Command Set-InstallFilterMode -ErrorAction SilentlyContinue) { Set-InstallFilterMode $script:installFilterMode }
            if ($global:currentDetailGame -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
                if (Get-Command Set-DetailFilterMarks -ErrorAction SilentlyContinue) { Set-DetailFilterMarks -Game $global:currentDetailGame }
            }
        }
    }

    # Scan over - put the light out and let its thread go.
    try { if (Get-Command Stop-ScanSpinner -ErrorAction SilentlyContinue) { Stop-ScanSpinner } } catch {}

    # Hand the window back to the user.
    Unlock-ScanUi
    try { if ($script:scanPumpWatch) { $script:scanPumpWatch.Stop() } } catch {}
    $script:scanPumpWatch = $null

    # Check finished: re-enable + re-arm the Scan-on-Startup hover toggle.
    $global:ScanInProgress = $false
    $cosbEnd = $global:window.FindName("CheckOnStartupBtn")
    if ($cosbEnd) { $cosbEnd.IsEnabled = $true; $cosbEnd.Visibility = [System.Windows.Visibility]::Hidden }

    # An installer finished while this scan was running - do the refresh it
    # asked for now that the collections are stable again.
    if ($global:PostInstallRefreshPending) {
        $global:PostInstallRefreshPending = $false
        try {
            [void]$global:window.Dispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                [action]{ try { Invoke-PostInstallRefresh } catch {} })
        } catch {}
    }

    # The user hit the X mid-scan and the Closing guard deferred it -
    # honour it now, one dispatcher turn later so this function unwinds
    # completely first.
    if ($global:CloseAfterScan) {
        $global:CloseAfterScan = $false
        try {
            [void]$global:window.Dispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                [action]{ try { $global:window.Close() } catch {} })
        } catch {}
    }
}

# The window's X and Alt+F4 go through the non-client area, which the
# scan's hit-test lock cannot reach - so a user CAN ask to close while a
# scan is walking the cards. Closing mid-scan would tear the window down
# inside the scan's nested dispatcher frame. Instead: remember the wish,
# cancel this close, and let the scan's epilogue perform it. Escape
# hatch: if the scan's heartbeat is stale the scan is dead, and the
# close goes through normally - a crashed scan must never trap the user
# in the Hub.
$window.Add_Closing({
    param($s, $e)
    if (-not $global:ScanInProgress) { return }
    $alive = $false
    try { $alive = ($script:scanHeartbeat -and ((Get-Date) - $script:scanHeartbeat).TotalSeconds -lt 60) } catch {}
    if (-not $alive) { return }
    $e.Cancel = $true
    $global:CloseAfterScan = $true
})

# Thin wrapper: the Check Installed button reuses the scan
# function above. Anything that wants to refresh the install
# state programmatically (e.g. the post-install auto-refresh
# below) calls Invoke-CheckInstalledScan directly.
$checkInstalledBtn.Add_PreviewMouseLeftButtonDown({
    # A scan is already queued or running - don't stack a second one.
    # ScanQueued is separate from ScanInProgress on purpose: the scan
    # function itself owns ScanInProgress as its re-entrancy guard, so
    # setting it here would make the deferred call below bail out.
    if ($global:ScanInProgress -or $global:ScanQueued) { return }
    # Explicit check -> probe online fresh, even if a previous scan in
    # this session marked the server as down.
    $global:HubScanOnlineDown = $false
    # Light the neon border NOW and let this click handler return, then run
    # the scan one dispatcher turn later at Input priority, which sits below
    # Render - so the button's click state and the light are painted first.
    # The scan itself calls Start-ScanSpinner too, but that is a no-op while
    # this one is lit.
    try { if (Get-Command Start-ScanSpinner -ErrorAction SilentlyContinue) { Start-ScanSpinner } } catch {}
    $global:ScanQueued = $true
    [void]$global:window.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Input,
        [action]{
            try { Invoke-CheckInstalledScan }
            catch {
                # The scan died. Give the window back immediately rather
                # than leaving it click-blind until the next attempt.
                Unlock-ScanUi
                try { if (Get-Command Stop-ScanSpinner -ErrorAction SilentlyContinue) { Stop-ScanSpinner } } catch {}
                $global:ScanInProgress = $false
            }
            finally { $global:ScanQueued = $false }
        })
}.GetNewClosure())

# Post-install auto-refresh: when an installer cmd.exe exits,
# we want the Hub to silently re-render the detail page so the
# user sees the new INSTALLED pill and green VR Ready button
# immediately, without manually clicking Check Installed.
#
# IMPORTANT: scope-respecting behaviour.
#   - If the user has run Check Installed at least once
#     (gameStateMap is populated), trigger a full re-scan so all
#     cards stay coherent with each other.
#   - If they haven't (gameStateMap is empty), only update state
#     for the one specific game they just installed. We don't
#     force a full scan they didn't ask for.
# Called from the DispatcherTimer poll above (see the install
# button click handler in the detail view), which detects when
# the launched cmd.exe terminates. The target title is stashed
# in $global:PendingInstallTitle by the click handler.
function global:Invoke-PostInstallRefresh {
    # Not while a scan is walking the card collections. The scan hands the
    # UI thread back between games, so the timers that call in here can now
    # actually fire mid-scan - and this function rebuilds the very lookups
    # the scan is enumerating. Remember it and run it once the scan is done,
    # so the marker handling below is never simply lost.
    if ($global:ScanInProgress) { $global:PostInstallRefreshPending = $true; return }
    $title = $global:PendingInstallTitle
    # Cancel-safe update tracking: the installer wrapper drops a
    # ".update_ok" marker (next to .installed_version) ONLY when its core
    # ran to completion - a cancel calls 'exit' first, so no marker. If
    # the marker is present the mod was really (re)installed: drop the
    # tracked version so the scan below reseeds it to the current online
    # build and the Update flag clears. No marker = cancelled = leave the
    # tracked version untouched so the card keeps showing "Update".
    if ($title) {
        try {
            $pendGame = $null
            foreach ($g in @($ownGames + $ownGamesGP + $externalGames)) {
                if ($g.Title -eq $title) { $pendGame = $g; break }
            }
            if ($pendGame) {
                $okMk = Get-UpdateOkMarkerPath -Game $pendGame
                if ($okMk -and (Test-Path $okMk)) {
                    # The in-game marker has to go as well, otherwise the OLD
                    # version stays the ground truth and the card keeps saying
                    # Update after a successful reinstall. The folder comes
                    # from the path the installer just recorded, with the
                    # scan's own state as a second source.
                    $pendDir = $null
                    try { $pendDir = Read-InstalledPath -Game $pendGame } catch {}
                    if (-not $pendDir) {
                        try {
                            $stP = $global:gameStateMap[$pendGame.Title]
                            if ($stP -and $stP.GameDir) { $pendDir = $stP.GameDir }
                        } catch {}
                    }
                    # Blank the tracked version instead of deleting the
                    # marker - same effect for the scan (empty reads as
                    # "unknown"), without a delete anywhere near a game
                    # folder.
                    Reset-InstalledVersion -Game $pendGame -GameDir $pendDir
                    if (Test-Path -LiteralPath $okMk -PathType Leaf) {
                        Remove-Item -LiteralPath $okMk -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        } catch {}
    }
    $hadFullScan = [bool]$global:UserRanFullScan

    if ($hadFullScan) {
        # User has already scanned at least once - keep their
        # global state coherent by re-running the full scan.
        try { Invoke-CheckInstalledScan } catch {}
    } elseif ($title) {
        # First-time scenario: the user installed a single mod
        # without ever running Check Installed. We only mark
        # this one game so the detail page can update, without
        # forcing a global scan they never opted into.
        try {
            $game = $null
            foreach ($g in @($ownGames + $ownGamesGP + $externalGames)) {
                if ($g.Title -eq $title) { $game = $g; break }
            }
            if ($game) {
                # The installer wrote .installed_path on success.
                # Its presence + a resolvable path is conclusive
                # evidence that both the game is installed AND
                # the mod is in place - no further heuristics
                # needed. This mirrors the Priority 1 branch in
                # the full scan.
                $recordedPath = Read-InstalledPath -Game $game
                # Verify the ModFile is actually on disk (not just the
                # folder) so a half-failed install or a deleted mod file
                # can't flip the card to "VR Ready". Games without a
                # ModFile (depot installs) keep folder-existence as before.
                $modPresent = $true
                if ($recordedPath -and $game.ModFile) {
                    $modPresent = (Test-Path (Join-Path $recordedPath $game.ModFile))
                    if (-not $modPresent -and $game.ModFileAlt) {
                        $modPresent = (Test-Path (Join-Path $recordedPath $game.ModFileAlt))
                    }
                }
                if ($recordedPath -and (Test-Path $recordedPath) -and $modPresent) {
                    $accentHex = if ($game.Accent) { $game.Accent } else { "#666677" }
                    $stateEntry = @{
                        Tag     = "vrinstalled"
                        Accent  = $accentHex
                        State   = "ready"
                        BtnText = "VR Ready"
                        GameDir = $recordedPath
                    }
                    # Two-mod entries need their per-mod fields here too.
                    # Without them this fast path wrote a state without any
                    # TwoMods info, and the tile fell back to ONE button
                    # until the Hub was restarted - exactly what happened
                    # after installing the second BioShock mod. Same probe
                    # as the full scan, so both agree.
                    # Same story for DualMode games (Bendy, Content Warning):
                    # without these the split between the current build and
                    # the pinned depot build only appeared after a restart.
                    if ($game.DualMode) {
                        $dm = Get-DualModePresence -Game $game
                        if ($dm.BothPresent) {
                            $stateEntry.DualMode   = $true
                            $stateEntry.CurrentDir = $dm.CurrentDir
                            $stateEntry.DepotDir   = $dm.DepotDir
                        }
                    }
                    if ($game.TwoMods) {
                        $pi = Get-TwoModsPresence -Game $game -FallbackRoot $recordedPath
                        $anyTwo = if ($game.TwoModsRequireBoth) { $pi.APresent -and $pi.BPresent }
                                  else { $pi.APresent -or $pi.BPresent }
                        $stateEntry.TwoMods     = $anyTwo
                        $stateEntry.ModAPresent = $pi.APresent
                        $stateEntry.ModBPresent = $pi.BPresent
                        $stateEntry.ModADir     = $pi.ADir
                        $stateEntry.ModBDir     = $pi.BDir
                        $stateEntry.ModAName    = $game.ModAName
                        $stateEntry.ModBName    = $game.ModBName
                    }
                    $global:gameStateMap[$title] = $stateEntry
                    # Repaint the library/list card for this title.
                    # Rebuild-Lookups walks every card and applies
                    # whatever is in gameStateMap; cards without a
                    # state entry are skipped (continue), so this
                    # does NOT scan or repaint cards we didn't ask
                    # for - only the one we just installed.
                    try { Rebuild-Lookups } catch {}
                }
            }
        } catch {}
    }

    # Re-render the open detail page so the new state shows up
    # immediately, regardless of which branch we took.
    try {
        if ($global:currentDetailGame -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
            Show-DiscoverDetail -Game $global:currentDetailGame
        }
    } catch {}
}

# Fallback for launches where we get no process handle back (a UAC
# elevation that hands us no object, or Start-Process throwing). Without
# a handle we can't poll for exit, so the install would finish with the
# Hub none the wiser and the user would have to reach for Scan games -
# which for someone who never opted into scanning means an unrequested
# sweep of their whole PC. Instead we watch this ONE game's
# .installed_path marker: when it appears or its timestamp moves, the
# installer got far enough to record success, and we run the normal
# post-install refresh (which itself decides single-game vs full scan).
# Gives up quietly after 15 minutes so no timer lingers.
function global:Watch-InstallMarkerForRefresh {
    param($Game)
    if (-not $Game) { return }
    $marker = $null
    try { $marker = Get-InstalledPathFile -Game $Game } catch {}
    if (-not $marker) { return }
    $stamp = $null
    try { if (Test-Path -LiteralPath $marker) { $stamp = (Get-Item -LiteralPath $marker -Force).LastWriteTimeUtc } } catch {}
    $global:PendingInstallTitle = $Game.Title
    try {
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(2)
        $timer.Tag = @{ Marker = $marker; Stamp = $stamp; Deadline = (Get-Date).AddMinutes(15) }
        $timer.Add_Tick({
            param($s, $e)
            $st = $s.Tag
            if (-not $st) { try { $s.Stop() } catch {}; return }
            $done = $false
            try {
                if (Test-Path -LiteralPath $st.Marker) {
                    $now = (Get-Item -LiteralPath $st.Marker -Force).LastWriteTimeUtc
                    if (-not $st.Stamp -or $now -gt $st.Stamp) { $done = $true }
                }
            } catch {}
            if ($done) {
                try { $s.Stop() } catch {}
                try { Invoke-PostInstallRefresh } catch {}
                return
            }
            if ((Get-Date) -gt $st.Deadline) { try { $s.Stop() } catch {} }
        })
        $timer.Start()
    } catch {}
}

