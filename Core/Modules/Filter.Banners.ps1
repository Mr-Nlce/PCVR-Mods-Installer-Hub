# ---------------------------------------------------------------
# Banner buttons (List view + Library view) + Overview back/show
# ---------------------------------------------------------------

# Helper: open detail page for a banner game from a given origin.
# =============================================================
#  Absolute mod markers
# =============================================================
# !!! SOME MODS NEVER TOUCH THE GAME FOLDER. Hotbite's Elden Ring mod
# installs entirely under %LOCALAPPDATA%\Programs\Elden Ring VR Motion
# and runs the game through ModEngine from there. Every other marker
# field is relative to the game directory, so there was no honest way
# to detect it - the tile fell back to the launcher WE write, which
# meant it read "VR Ready" for anyone who had ever run the installer,
# mod or no mod.
#
# ModFileAbs takes full paths instead, environment variables included.
# They are checked on their own, never joined to a game directory.
function global:Test-AbsolutePathMarker {
    param($Values)
    if (-not $Values) { return $false }
    foreach ($raw in @($Values)) {
        if ([string]::IsNullOrWhiteSpace($raw)) { continue }
        try {
            $full = [Environment]::ExpandEnvironmentVariables([string]$raw)
            # Never Join-Path here: the value may name a drive that is
            # gone, and Join-Path resolves it and throws.
            if ([IO.File]::Exists($full) -or [IO.Directory]::Exists($full)) { return $true }
        } catch {}
    }
    return $false
}

function global:Test-AbsoluteModMarker {
    param($Game)
    if (-not $Game) { return $false }
    return (Test-AbsolutePathMarker -Values $Game.ModFileAbs)
}

# A catalog probe may list more than one legitimate relative location (for
# example F.E.A.R.'s old staged layout and its newer in-game overlay). Keep
# that representation out of Join-Path callers: arrays and pipe-separated
# legacy values are both accepted here, and a hit always has to exist below
# the supplied installation root.
function global:Test-RelativePathMarker {
    param([string]$Root, $Values)
    if ([string]::IsNullOrWhiteSpace($Root) -or -not $Values) { return $false }
    foreach ($rawValue in @($Values)) {
        foreach ($raw in (([string]$rawValue) -split '\|')) {
            $rel = $raw.Trim()
            if (-not $rel) { continue }
            try {
                # Catalog paths are stored with Windows separators because the
                # shipped Hub runs on Windows. Tests and diagnostics also run
                # under PowerShell on Linux, where a backslash is a literal
                # filename character. Normalize either separator before the
                # filesystem probe so both hosts inspect the same path tree.
                $separator = [string][IO.Path]::DirectorySeparatorChar
                $nativeRel = $rel.Replace('\', $separator).Replace('/', $separator)
                $candidate = Join-Path $Root $nativeRel
                if ([IO.File]::Exists($candidate) -or [IO.Directory]::Exists($candidate)) { return $true }
            } catch {}
        }
    }
    return $false
}

# RaiManager can keep BepInEx beside the downloaded manager package instead
# of copying it into the game. Its game-side doorstop_config.ini then points
# at BepInEx.Preloader.dll through an absolute targetAssembly path. Firewatch
# uses that layout in the wild, so a plain game-root ModFile probe misses a
# working installation. Follow only that explicit Doorstop path, require the
# configured preloader and the VR-specific marker below the same payload tree,
# and also require the game-side proxy (active or parked by our Flat/VR switch).
# This deliberately does not treat winhttp.dll or doorstop_config.ini alone as
# VR proof: both can be left behind by a partial or unrelated BepInEx install.
function global:Test-DoorstopTargetModMarker {
    param(
        [string]$GameRoot,
        [string]$TargetMarker,
        [string]$LoaderFile = 'winhttp.dll'
    )
    if ([string]::IsNullOrWhiteSpace($GameRoot) -or [string]::IsNullOrWhiteSpace($TargetMarker)) { return $false }
    try {
        $configPath = Join-Path $GameRoot 'doorstop_config.ini'
        if (-not [IO.File]::Exists($configPath)) { return $false }

        if ($LoaderFile) {
            $loaderRel = $LoaderFile.Trim()
            $loaderDir = Split-Path $loaderRel -Parent
            $loaderLeaf = Split-Path $loaderRel -Leaf
            $stem = [IO.Path]::GetFileNameWithoutExtension($loaderLeaf)
            $ext = [IO.Path]::GetExtension($loaderLeaf)
            $loaderCandidates = @(
                $loaderRel,
                $(if ($loaderDir) { Join-Path $loaderDir ($stem + '_bak' + $ext) } else { $stem + '_bak' + $ext }),
                ($loaderRel + '.pcvrhub_off')
            )
            if (-not (Test-RelativePathMarker -Root $GameRoot -Values $loaderCandidates)) { return $false }
        }

        $config = [IO.File]::ReadAllText($configPath)
        $match = [regex]::Match($config, '(?im)^\s*targetAssembly\s*=\s*(?<path>[^\r\n]+?)\s*$')
        if (-not $match.Success) { return $false }
        $assemblyRaw = [Environment]::ExpandEnvironmentVariables($match.Groups['path'].Value.Trim().Trim('"', "'"))
        if (-not $assemblyRaw) { return $false }
        $separator = [string][IO.Path]::DirectorySeparatorChar
        $assemblyNative = $assemblyRaw.Replace('\', $separator).Replace('/', $separator)
        $assemblyPath = if ([IO.Path]::IsPathRooted($assemblyNative)) {
            [IO.Path]::GetFullPath($assemblyNative)
        } else {
            [IO.Path]::GetFullPath((Join-Path $GameRoot $assemblyNative))
        }
        if (-not [IO.File]::Exists($assemblyPath)) { return $false }

        $candidateRoot = Split-Path $assemblyPath -Parent
        for ($depth = 0; $depth -lt 6 -and $candidateRoot; $depth++) {
            if (Test-RelativePathMarker -Root $candidateRoot -Values $TargetMarker) { return $true }
            $parent = [IO.Directory]::GetParent($candidateRoot)
            if (-not $parent) { break }
            $candidateRoot = $parent.FullName
        }
    } catch {}
    return $false
}

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


