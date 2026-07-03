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
    foreach ($pill in @($filterAll, $filterMC, $filterGP, $filterInstalled, $filterVRReady)) {
        if (-not $pill) { continue }
        if ($pill.Resources.Contains("shBg")) { $pill.Resources.Remove("shBg") | Out-Null }
        $tb = if ($pill -eq $filterAll) { $pill.Child } elseif ($pill -eq $filterInstalled -or $pill -eq $filterVRReady) { $pill.Child.Children[0] } else { $pill.Child.Children[1] }
        if ($tb -and $tb.Resources.Contains("shFg")) { $tb.Resources.Remove("shFg") | Out-Null }
        $pill.Background = [System.Windows.Media.Brushes]::Black
        # Detail-page marking is border + text only - drop any leftover
        # filter glow (e.g. the previously active "All" pill in the list)
        # so a detail page never shows a faint lingering Leuchtrahmen.
        $pill.Effect = $null
    }

    $ctrl  = "$($Game.Controls)"
    $hasMC = ($ctrl -eq "MC" -or $ctrl -eq "BOTH")
    $hasGP = ($ctrl -eq "GP" -or $ctrl -eq "BOTH")
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
    foreach ($pill in @($filterInstalled, $filterVRReady)) {
        if (-not $pill) { continue }
        if ($pill.Resources.Contains("shBg")) { $pill.Resources.Remove("shBg") | Out-Null }
        $tb = $pill.Child.Children[0]
        if ($tb -and $tb.Resources.Contains("shFg")) { $tb.Resources.Remove("shFg") | Out-Null }
        $pill.Background = $glassBg
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
        $tags     = if ($GameData.Tags)  { $GameData.Tags } else { @() }
        $controls = if ($GameData.Controls) { $GameData.Controls } else { "" }
        $textMatch = $Query -eq "" -or $title.Contains($Query) -or $mod.Contains($Query) -or
                     $pill.Contains($Query) -or
                     ($tags | Where-Object { $_ -and "$_".ToLower().Contains($Query) }).Count -gt 0
        # Keyword shortcuts: typing "free" lists every FREE title and "wip"
        # lists every work-in-progress title (matched by Title, on top of the
        # normal text match above). $null -contains is safe -> false.
        if ($Query -eq "free" -and ($global:FREE_GAME_TITLES -contains $GameData.Title)) { $textMatch = $true }
        if ($Query -eq "wip"  -and ($global:WIP_GAME_TITLES  -contains $GameData.Title)) { $textMatch = $true }
        $ctrlMatch = $script:activeFilter -eq "ALL" -or $controls -eq $script:activeFilter -or
                     ($script:activeFilter -eq "MC" -and $controls -eq "BOTH") -or
                     ($script:activeFilter -eq "GP" -and $controls -eq "BOTH")
        $instMatch = $true
        if ($script:installFilterMode -ne "off") {
            if (-not $global:gameStateMap -or $global:gameStateMap.Count -eq 0) {
                # No scan has run yet: the install filter cannot know anything, so
                # it stays inactive (shows everything) instead of emptying the list.
                # The Scan games button pulses to point the user at the scan.
                $instMatch = $true
            } else {
                $st = $global:gameStateMap[$GameData.Title]
                if ($script:installFilterMode -eq "ready") {
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
    # List view cards. Each card is evaluated INDEPENDENTLY and FAIL-OPEN:
    # if testing a single game throws (or its data is missing), that card is
    # SHOWN, never hidden, and the loop continues. One bad entry can never
    # freeze the search or make unrelated games vanish.
    if ($view -eq "List") {
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
    }
    # Discover tiles (built lazily; only iterate when present)
    if ($view -eq "Library" -and $global:discoverPanel -and $global:DiscoverTilesBuilt) {
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

function global:Get-GithubLatestTagCached {
    # Return the latest GitHub release tag for $Repo, cached on disk with a TTL
    # so repeated scans/restarts do not exhaust the 60/hour unauthenticated
    # GitHub API limit. On a rate-limit or transient error the LAST known tag is
    # returned (so the update state stays stable) and the shared online-down
    # flag is NOT tripped - a 403 means the host is reachable, just limited, and
    # must not kill the other checks (Alien Isolation web check, other repos).
    param([string]$Repo)
    if (-not $Repo) { return $null }
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
    $entry = $script:ghVerCache[$Repo]
    $now = [DateTime]::UtcNow
    if ($entry -and $entry.tag -and $entry.checked) {
        try {
            $age = ($now - [DateTime]::Parse($entry.checked, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).TotalHours
            if ($age -lt $ttlHours) { return [string]$entry.tag }
        } catch {}
    }
    # Use the github.com /releases/latest REDIRECT (web, not the API). It 302s
    # to /releases/tag/<tag>, so the tag is in the final URL - and the website
    # is NOT bound by the 60/hour unauthenticated API limit that the api.github
    # endpoint enforces. HEAD only, so no page body is downloaded. 2>$null keeps
    # a rare transient error out of the Hub transcript.
    $tag = $null
    try {
        $resp = Invoke-WebRequest -Uri "https://github.com/$Repo/releases/latest" -Method Head -UseBasicParsing -TimeoutSec 6 -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" } -EA Stop 2>$null
        $final = ""
        try { $final = [string]$resp.BaseResponse.ResponseUri.AbsoluteUri } catch {}
        if (-not $final -and $resp.Headers.Location) { $final = [string]$resp.Headers.Location }
        if ($final -match '/releases/tag/([^/?#]+)') { $tag = [System.Uri]::UnescapeDataString($matches[1]).Trim() }
    } catch {
        Write-Host "[GithubCheck] $Repo : web check failed ($($_.Exception.Message)) - using cached tag if present"
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
    if ($tag) {
        $script:ghVerCache[$Repo] = @{ tag = $tag; checked = $now.ToString("o") }
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
    $wv = $null
    try {
        $wua  = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" }
        $wResp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5 -Headers $wua -EA Stop
        $wHtml = [string]$wResp.Content
        if     ($wHtml -match 'Test Build\s+v?([0-9][0-9A-Za-z.\-]+)') { $wv = "v" + $matches[1] }
        elseif ($wHtml -match 'GRAND[^0-9<]{0,30}v?([0-9]+(?:\.[0-9]+)+[0-9A-Za-z\-]*)') { $wv = "v" + $matches[1] }
        elseif ($wHtml -match '\bv([0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z\-]*)') { $wv = "v" + $matches[1] }
        if ($wv) { Write-Host "[AICheck] $Title : web version = $wv" }
        else     { Write-Host ("[AICheck] $Title : page fetched ({0} chars) but no version matched" -f $wHtml.Length) }
    } catch {
        Write-Host "[AICheck] $Title : page fetch failed - $($_.Exception.Message)"
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

function global:Invoke-CheckInstalledScan {
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

    # Xbox / Microsoft Store roots. The standard install location is
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

    $found = 0
    $vrFound = 0
    foreach ($card in $global:cardGameMap.Keys) {
        $game = $global:cardGameMap[$card]
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
        if ($vrInstalled -and $game.DualMode -and $game.DepotPath -and $game.ModFile) {
            $depotHasMod = (Test-Path (Join-Path $game.DepotPath $game.ModFile))
            # Mode 1 candidate: any Steam-library steamapps\common\<SteamFolder>
            # that has the ModFile.
            $currentHasMod = $false
            $currentDir    = $null
            if ($game.SteamFolder) {
                foreach ($lib in $steamLibs) {
                    $c = Join-Path $lib "steamapps\common\$($game.SteamFolder)"
                    if ((Test-Path $c) -and (Test-Path (Join-Path $c $game.ModFile))) {
                        $currentHasMod = $true
                        $currentDir    = $c
                        break
                    }
                }
            }
            if ($depotHasMod -and $currentHasMod) {
                $dualModeBothPresent = $true
                $dualModeCurrentDir  = $currentDir
                $dualModeDepotDir    = $game.DepotPath
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
            $tmIpf = Get-InstalledPathFile -Game $game
            if ($tmIpf -and (Test-Path $tmIpf)) {
                $tmParent = $null
                try { $tmParent = Read-InstalledPath -Game $game } catch {}
                if ($tmParent -and (Test-Path $tmParent)) {
                    # Per-mod presence. Each mod installs into its own
                    # subfolder under the recorded parent. We search the
                    # subfolder RECURSIVELY for the launcher so a mod that
                    # unpacked one level deep still counts. The launch
                    # choice is offered as soon as EITHER mod is present;
                    # a missing mod's button routes to its installer.
                    if ($game.ModASub -and $game.ModALaunch) {
                        $subA = Join-Path $tmParent $game.ModASub
                        if (Test-Path $subA) {
                            $hitA = Get-ChildItem -Path $subA -Filter $game.ModALaunch -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                            if ($hitA) { $tmAPresent = $true; $twoModsADir = (Split-Path -Parent $hitA.FullName) }
                        }
                    }
                    if ($game.ModBSub -and $game.ModBLaunch) {
                        $subB = Join-Path $tmParent $game.ModBSub
                        if (Test-Path $subB) {
                            $hitB = Get-ChildItem -Path $subB -Filter $game.ModBLaunch -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                            if ($hitB) { $tmBPresent = $true; $twoModsBDir = (Split-Path -Parent $hitB.FullName) }
                        }
                    }
                    if ($tmAPresent -or $tmBPresent) { $vrInstalled = $true }
                    $twoModsAnyPresent = ($tmAPresent -or $tmBPresent)
                }
            }
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
        if ($isFreeGame -and -not $vrInstalled) { $installed = $false }

        if ($vrInstalled) {
            # For Thunderstore-based mods: query live version and deprecated status
            $needsUpdate  = $false
            $installedVer = Read-InstalledVersion -Game $game

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
                        Write-InstalledVersion -Game $game -Version $ghVer
                        $installedVer = $ghVer
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
                        Write-InstalledVersion -Game $game -Version $tsVer
                    } elseif ($installedVer -and $installedVer -eq $tsVer) {
                        # Up to date - keep the Hub cache in sync so a
                        # later scan without .ts_versions still works.
                        Write-InstalledVersion -Game $game -Version $installedVer
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
            } elseif ($game.GithubRepo) {
                # GitHub release check: latest tag vs the installed version.
                # Mirrors the Thunderstore branch above. Seeds the cache on
                # the first scan after install (GitHub installers always pull
                # releases/latest, so "no stored version yet" = current latest).
                $ghVer = Get-GithubLatestTagCached -Repo $game.GithubRepo
                if ($ghVer) {
                    if (-not $installedVer) {
                        Write-InstalledVersion -Game $game -Version $ghVer
                        $installedVer = $ghVer
                    } elseif ($installedVer -ne $ghVer) {
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
                        Write-InstalledVersion -Game $game -Version $wv
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
                        Write-InstalledVersion -Game $game -Version $expectedVer
                        $installedVer = $expectedVer
                    } elseif ($installedVer -ne $expectedVer) {
                        $needsUpdate = $true
                    }
                }
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
                $global:gameStateMap[$game.Title] = @{ Tag="vrupdate"; Accent=$accentHex; State="update"; BtnText="Update"; DualMode=$dualModeBothPresent; CurrentDir=$dualModeCurrentDir; DepotDir=$dualModeDepotDir }
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

        # Align the slot's left edge with where STATE begins one row below, so
        # the totals sit exactly above the spot the Scan games button used to
        # occupy. Pills are left-docked => x positions are fixed, so a one-time
        # measure after layout is stable.
        try {
            $global:window.UpdateLayout()
            $stateLbl = $global:window.FindName("StateLabel")
            if ($stateLbl) {
                $zero  = [System.Windows.Point]::new(0,0)
                # Target = where the State pills (and the old Scan games button)
                # BEGIN = STATE label RIGHT edge + its right margin, not its left
                # edge. That puts the totals exactly above the old button spot.
                $targetX = ($stateLbl.TransformToVisual($global:window).Transform($zero).X) + $stateLbl.ActualWidth + 8
                $slotX   = $slot.TransformToVisual($global:window).Transform($zero).X
                $newLeft = $slot.Margin.Left + ($targetX - $slotX)
                if ($newLeft -lt 0) { $newLeft = 0 }
                $slot.Margin = [System.Windows.Thickness]::new($newLeft, 0, 0, 0)
            }
        } catch {}

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

    # Check finished: re-enable + re-arm the Scan-on-Startup hover toggle.
    $global:ScanInProgress = $false
    $cosbEnd = $global:window.FindName("CheckOnStartupBtn")
    if ($cosbEnd) { $cosbEnd.IsEnabled = $true; $cosbEnd.Visibility = [System.Windows.Visibility]::Hidden }
}

# Thin wrapper: the Check Installed button reuses the scan
# function above. Anything that wants to refresh the install
# state programmatically (e.g. the post-install auto-refresh
# below) calls Invoke-CheckInstalledScan directly.
$checkInstalledBtn.Add_PreviewMouseLeftButtonDown({
    # Explicit check -> probe online fresh, even if a previous scan in
    # this session marked the server as down.
    $global:HubScanOnlineDown = $false
    Invoke-CheckInstalledScan
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
                    Remove-InstalledVersion -Game $pendGame
                    Remove-Item $okMk -Force -ErrorAction SilentlyContinue
                }
            }
        } catch {}
    }
    $hadFullScan = ($global:gameStateMap -and $global:gameStateMap.Count -gt 0)

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
                    $global:gameStateMap[$title] = @{
                        Tag     = "vrinstalled"
                        Accent  = $accentHex
                        State   = "ready"
                        BtnText = "VR Ready"
                        GameDir = $recordedPath
                    }
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

