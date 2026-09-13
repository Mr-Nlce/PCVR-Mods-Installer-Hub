$ownList     = $window.FindName("OwnGameList")
$ownListGP   = $window.FindName("OwnGameListGP")
$extList     = $window.FindName("ExternalGameList")

$headerMC  = $window.FindName("HeaderMC")
$headerGP  = $window.FindName("HeaderGP")
$headerExt = $window.FindName("HeaderExt")
$dividerMC = $window.FindName("DividerMC")
$dividerGP = $window.FindName("DividerGP")

# The three collapsible list headers use the same subtle render-time grow as
# the Hub title.  RenderTransform does not trigger a list relayout, so the
# large tile collections stay completely untouched while the pointer moves.
Add-HeaderHoverGrow -Element $headerMC  -Scale 1.025
Add-HeaderHoverGrow -Element $headerGP  -Scale 1.025
Add-HeaderHoverGrow -Element $headerExt -Scale 1.025

$headerMC.Add_PreviewMouseLeftButtonDown({
    $ownList.Visibility = if ($ownList.Visibility -eq [System.Windows.Visibility]::Visible) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    $dividerMC.Visibility = $ownList.Visibility
}.GetNewClosure())
$headerGP.Add_PreviewMouseLeftButtonDown({
    $ownListGP.Visibility = if ($ownListGP.Visibility -eq [System.Windows.Visibility]::Visible) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    $dividerGP.Visibility = $ownListGP.Visibility
}.GetNewClosure())
$headerExt.Add_PreviewMouseLeftButtonDown({
    $extList.Visibility = if ($extList.Visibility -eq [System.Windows.Visibility]::Visible) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
}.GetNewClosure())

# Load the saved scale BEFORE the initial card-build so cards
# are constructed at the right size on the first pass. Previously
# the cards were built with default SCALE=1.0 here, then Apply-Scale
# rebuilt them ALL again later when a saved 1.5/2.0 was found -
# doubling the startup time at M and L.
if (Get-Command Get-HubSetting -ErrorAction SilentlyContinue) {
    try {
        $savedScaleEarly = Get-HubSetting -Key "scaleList" -Default 1.0
        if ($savedScaleEarly -is [string]) {
            try { $savedScaleEarly = [double]$savedScaleEarly } catch { $savedScaleEarly = 1.0 }
        }
        if ($savedScaleEarly -in @(1.0, 1.5, 2.0)) {
            $global:SCALE = $savedScaleEarly
        }
    } catch { }
}

# Active tile style, loaded before the card-build loop so New-GameCard
# dispatches to the right renderer on the first pass. 'frosted' is the
# default redesign; 'classic' is the original flat tiles. Flipped (and
# persisted) by the Switch Hub Style menu item + the header VR-glasses
# click, which then rebuild the cards.
$global:hubStyle = [string](Get-HubSetting -Key "hubStyle" -Default "frosted")
if ($global:hubStyle -ne "classic") { $global:hubStyle = "frosted" }

Write-HubTiming "Controls before Motion cards"
foreach ($game in $ownGames) {
    try   { $ownList.Children.Add((New-GameCard $game $false $window)) | Out-Null }
    catch { try { Write-Host "  [card-build] skipped '$($game.Title)': $_" -ForegroundColor DarkYellow } catch {}; $ownList.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
}
Write-HubTiming "Controls after Motion cards"
foreach ($game in $ownGamesGP) {
    try   { $ownListGP.Children.Add((New-GameCard $game $false $window)) | Out-Null }
    catch { try { Write-Host "  [card-build] skipped '$($game.Title)': $_" -ForegroundColor DarkYellow } catch {}; $ownListGP.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
}
Write-HubTiming "Controls after Gamepad cards"
foreach ($game in $externalGames) {
    try   { $extList.Children.Add((New-GameCard $game $true  $window)) | Out-Null }
    catch { try { Write-Host "  [card-build] skipped '$($game.Title)': $_" -ForegroundColor DarkYellow } catch {}; $extList.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
}
Write-HubTiming "Controls after External cards"

# Section-header mod counts (Custom Installers split by control type + External).
try {
    $hmcSub = $window.FindName("HeaderMCSub"); if ($hmcSub) { $hmcSub.Text = "$(@($ownGames).Count) mods" }
    $global:HubGPCount   = @($ownGamesGP).Count
    $global:HubVRGPCount = @($ownGamesGP | Where-Object { $_.Controls -eq "VRGP" }).Count
    $hgpSub = $window.FindName("HeaderGPSub"); if ($hgpSub) { $hgpSub.Text = "$(@($ownGamesGP).Count) mods" }
    $hexSub = $window.FindName("HeaderExtSub"); if ($hexSub) { $hexSub.Text = "$(@($externalGames).Count) mods" }
} catch {}

# Scale S / M / L buttons
$scaleSBtn = $window.FindName("ScaleS")
$scaleMBtn = $window.FindName("ScaleM")
$scaleLBtn = $window.FindName("ScaleL")

# Soft hover on the size selector - same reasoning as the filter
# pills above. The active button has an accent border; hover gets
# only a background brighten so the two states stay distinguishable.
Add-SoftHover -Border $scaleSBtn
Add-SoftHover -Border $scaleMBtn
Add-SoftHover -Border $scaleLBtn

function global:Set-ScaleActive { param($active)
    foreach ($btn in @($scaleSBtn, $scaleMBtn, $scaleLBtn)) {
        # Inactive: glass base bg + soft glass border. Identical to
        # the inactive state of the filter pills - the row reads as
        # one visual family.
        $btn.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#09ffffff")
        $btn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0fffffff")
        ($btn.Child).Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#aaaaaa")
        # Drop the SoftHover stash so a pending MouseLeave can't
        # undo what we just set (see Add-SoftHover comments).
        if ($btn.Resources.Contains("shBg")) { $btn.Resources.Remove("shBg") | Out-Null }
        if ($btn.Child -and $btn.Child.Resources.Contains("shFg")) {
            $btn.Child.Resources.Remove("shFg") | Out-Null
        }
        # Also drop the old Add-GlowHover stash key in case anything
        # else still touches it - defensive, costs nothing.
        if ($btn.Child -and $btn.Child.Resources.Contains("ghFg")) {
            $btn.Child.Resources.Remove("ghFg") | Out-Null
        }
    }
    # Active: keep glass background, signal selection via a neutral
    # accent border + white text. Same active-look pattern as the
    # filter pills, so the whole bar reads consistently.
    $active.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#09ffffff")
    $active.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5566aa")
    ($active.Child).Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ffffff")
}

# Apply the gentle S/M/L card curve to the EXISTING cards via
# LayoutTransform - no Clear()/New-GameCard rebuild, so switching size
# is instant (previously a ~4-5s full rebuild) and the filter state
# (card visibility) is preserved. The S/M/L *level* stays 1.0/1.5/2.0
# everywhere else (buttons, persistence, headers, Recently Played);
# only the card body uses the gentle 1.0/1.2/1.4 curve. Headers and the
# ListBanner are NOT cards (they live outside these panels) and are
# scaled separately by their FontSize maps, so they never double-scale.
function global:Apply-CardScale {
    $cardScale = switch ($global:SCALE) {
        1.5     { 1.15 }
        2.0     { 1.3 }
        default { 1.0 }
    }
    foreach ($panel in @($ownList, $ownListGP, $extList)) {
        if (-not $panel) { continue }
        foreach ($card in $panel.Children) {
            if (-not $card) { continue }
            if ($cardScale -eq 1.0) {
                $card.LayoutTransform = $null
            } else {
                $card.LayoutTransform = New-Object System.Windows.Media.ScaleTransform $cardScale, $cardScale
            }
        }
    }
}

# ------------------------------------------------------------
# Switch the tile style at runtime. Flips $global:hubStyle, persists
# it to the durable Hub state, then tears down + rebuilds all three card
# lists with the other renderer (New-GameCard dispatches on the flag),
# re-applies the S/M/L scale, and re-runs Rebuild-Lookups so install
# states + the card->game map are restored onto the fresh cards.
# Mirrors the initial build loop. WPF rendering is not verifiable on
# Linux - the switch logic is, the look is tuned by-eye on Windows.
# ------------------------------------------------------------
function global:Switch-HubStyle {
    $global:hubStyle = if ($global:hubStyle -eq 'classic') { 'frosted' } else { 'classic' }
    if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
        Set-HubSetting -Key "hubStyle" -Value $global:hubStyle
    }
    foreach ($p in @($ownList, $ownListGP, $extList)) { if ($p) { $p.Children.Clear() } }
    foreach ($game in $ownGames) {
        try   { $ownList.Children.Add((New-GameCard $game $false $global:window)) | Out-Null }
        catch { $ownList.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
    }
    foreach ($game in $ownGamesGP) {
        try   { $ownListGP.Children.Add((New-GameCard $game $false $global:window)) | Out-Null }
        catch { $ownListGP.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
    }
    foreach ($game in $externalGames) {
        try   { $extList.Children.Add((New-GameCard $game $true $global:window)) | Out-Null }
        catch { $extList.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
    }
    if (Get-Command Apply-CardScale     -ErrorAction SilentlyContinue) { Apply-CardScale }
    if (Get-Command Rebuild-Lookups     -ErrorAction SilentlyContinue) { Rebuild-Lookups }
    if (Get-Command Apply-CatalogSort   -ErrorAction SilentlyContinue) { Apply-CatalogSort -Scope List -SkipFilter }
    if (Get-Command Build-RecentlyPlayed -ErrorAction SilentlyContinue) { Build-RecentlyPlayed }
}

# Scale the list-view featured banner (ListBanner) to the list S/M/L
# scale (1.0/1.5/2.0): height, text and layout spacing together. Kept
# separate from Apply-Scale so startup can scale the banner without a
# full card rebuild. Normal (1.0) = the XAML defaults (height 140,
# title 22, sub 11, kicker 10, grid top-margin 16, button pad 14/7,
# button font 11).
function global:Set-ListBannerScale { param($sc)
    $lb = switch ($sc) {
        1.0     { @{ H = 140; Title = 22; Sub = 11; Kicker = 10; Top = 16; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
        1.5     { @{ H = 156; Title = 25; Sub = 12; Kicker = 11; Top = 20; BtnFont = 12; BtnPadX = 16; BtnPadY = 8 } }
        2.0     { @{ H = 174; Title = 28; Sub = 13; Kicker = 12; Top = 24; BtnFont = 13; BtnPadX = 18; BtnPadY = 9 } }
        default { @{ H = 140; Title = 22; Sub = 11; Kicker = 10; Top = 16; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
    }
    if (-not $global:window) { return }
    $lbB = $global:window.FindName("ListBanner")
    if ($lbB) { $lbB.Height = $lb.H }
    $lbT = $global:window.FindName("ListBannerTitle")
    if ($lbT) { $lbT.FontSize = $lb.Title }
    $lbS = $global:window.FindName("ListBannerSubtitle")
    if ($lbS) { $lbS.FontSize = $lb.Sub }
    $lbK = $global:window.FindName("ListBannerKicker")
    if ($lbK) { $lbK.FontSize = $lb.Kicker }
    $lbG = $global:window.FindName("ListBannerTitleGrid")
    if ($lbG) { $lbG.Margin = [System.Windows.Thickness]::new(22, $lb.Top, 22, 16) }
    $lbPad = [System.Windows.Thickness]::new($lb.BtnPadX, $lb.BtnPadY, $lb.BtnPadX, $lb.BtnPadY)
    $lbShow = $global:window.FindName("ListBannerShowBtn")
    if ($lbShow) { $lbShow.Padding = $lbPad }
    $lbExp = $global:window.FindName("ListBannerExploreBtn")
    if ($lbExp) { $lbExp.Padding = $lbPad }
    $lbShowTxt = $global:window.FindName("ListBannerShowBtnText")
    if ($lbShowTxt) { $lbShowTxt.FontSize = $lb.BtnFont }
    $lbExpTxt = $global:window.FindName("ListBannerExploreBtnText")
    if ($lbExpTxt) { $lbExpTxt.FontSize = $lb.BtnFont }
    $lbExpArr = $global:window.FindName("ListBannerExploreBtnArrow")
    if ($lbExpArr) { $lbExpArr.FontSize = $lb.BtnFont + 2 }
    # Re-fit the showing banner to the new font size without shuffling
    # the featured game (no-op if the refit helper isn't loaded yet,
    # e.g. during early startup - the sizes above still apply).
    if (Get-Command Refresh-ListBannerSameGame -ErrorAction SilentlyContinue) {
        try { Refresh-ListBannerSameGame } catch { }
    }
}

function global:Set-HeaderFontScale { param($sc)
    # Section-header (Custom Installers MC/GP, External, Recently Played)
    # point sizes per list scale. Pulled out of Apply-Scale so it can run
    # at STARTUP too - otherwise L/M headers keep their XAML default size
    # until the user toggles S/M/L once.
    $hdr = switch ($sc) {
        1.0     { @{ Title = 12; Sub = 10 } }
        1.5     { @{ Title = 14; Sub = 11 } }
        2.0     { @{ Title = 17; Sub = 13 } }
        default { @{ Title = 14; Sub = 11 } }
    }
    if ($global:window) {
        foreach ($n in @("HeaderMCTitle","HeaderGPTitle","HeaderExtTitle","RecentlyPlayedTitle","HeaderMCKind","HeaderGPKind")) {
            $t = $global:window.FindName($n); if ($t) { $t.FontSize = $hdr.Title }
        }
        foreach ($n in @("HeaderMCSub","HeaderGPSub","HeaderExtSub","RecentlyPlayedSub")) {
            $t = $global:window.FindName($n); if ($t) { $t.FontSize = $hdr.Sub }
        }
    }
}

function global:Apply-Scale { param($sc, $activeBtn)
    $global:SCALE = $sc
    # The active-button glow is already set by On-ScaleClick before this
    # runs, so we don't re-set it here.
    # Transform-scale the existing cards instead of rebuilding them.
    Apply-CardScale
    # Recently Played row scales with S/M/L too - rebuild after so its
    # tile size matches the active scale (only a handful of tiles).
    if (Get-Command Build-RecentlyPlayed -ErrorAction SilentlyContinue) {
        Build-RecentlyPlayed
    }
    # Persist the user's choice so it survives a hub restart.
    if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
        Set-HubSetting -Key "scaleList" -Value $sc
    }
    # Scale the three category section headers (Custom Installers
    # MC / GP, External Installers) with the list scale so the whole
    # view grows together, not just the cards. Map the 1.0/1.5/2.0
    # scale factors to sensible header point sizes.
    Set-HeaderFontScale $sc
    # Scale the list-view featured banner (ListBanner) to match.
    Set-ListBannerScale $sc
}

# Per-view size settings - each view (List/Library/Explore/Detail)
# has its own S/M/L choice, persisted to the durable Hub state so the
# user's preference per area survives restart.
#
# - List view  (old VR-mod list, card tiles): $global:SCALE (1.0/1.5/2.0)
# - Library    (Steam-style portrait list):   $global:LibrarySize  S/M/L
# - Explore    (horizontal genre rows):       $global:ExploreSize  S/M/L
# - Detail     (description page font size):  $global:DetailSize   S/M/L
#
# DiscoverTileSize still exists as a shim that mirrors whichever
# sub-view is currently visible (Library or Explore) so existing
# tile-building code keeps working unchanged.
$global:LibrarySize = "L"
$global:ExploreSize = "M"
$global:DetailSize  = "M"
if (Get-Command Get-HubSetting -ErrorAction SilentlyContinue) {
    $global:LibrarySize = [string](Get-HubSetting -Key "sizeLibrary" -Default "L")
    $global:ExploreSize = [string](Get-HubSetting -Key "sizeExplore" -Default "M")
    $global:DetailSize  = [string](Get-HubSetting -Key "sizeDetail"  -Default "M")
    # List view also gets persisted - keep this in sync with
    # Apply-Scale's Set-HubSetting call above.
    $savedScale = Get-HubSetting -Key "scaleList" -Default 1.0
    if ($savedScale -is [string]) {
        try { $savedScale = [double]$savedScale } catch { $savedScale = 1.0 }
    }
    if ($savedScale -in @(1.0, 1.5, 2.0)) {
        $global:SCALE = $savedScale
    }
}
$global:DiscoverTileSize    = $global:LibrarySize  # initial shim
$global:DiscoverTileSizes   = @{
    "S" = @{ W = 220; H = 330 }
    "M" = @{ W = 250; H = 375 }
    "L" = @{ W = 275; H = 413 }
}

# Overview tile sizes for the horizontal genre rows. Smaller
# than Library since they sit in a packed row, not a grid.
$global:OverviewTileSizes = @{
    "S" = @{ W = 140; H = 210 }
    "M" = @{ W = 175; H = 260 }
    "L" = @{ W = 215; H = 320 }
}

# Detail-view text sizing: maps S/M/L to font size + line height.
# Drives the Steam description AND the README (set-up) body text.
$global:DetailTextSizes = @{
    "S" = @{ Font = 12; LineHeight = 18 }
    "M" = @{ Font = 14; LineHeight = 21 }
    "L" = @{ Font = 16; LineHeight = 24 }
}

# Apply Library size (Steam-style portrait list). Updates the
# live tile widths/heights immediately.
function global:Apply-LibrarySize { param($sizeKey)
    if (-not $global:DiscoverTileSizes.ContainsKey($sizeKey)) { return }
    $global:LibrarySize = $sizeKey
    $global:DiscoverTileSize = $sizeKey  # keep shim in sync
    $dim = $global:DiscoverTileSizes[$sizeKey]
    if ($global:discoverPanel -and $global:DiscoverTilesBuilt) {
        foreach ($tile in $global:discoverPanel.Children) {
            $tile.Width  = $dim.W
            $tile.Height = $dim.H
        }
    }
    # The library featured banner (LibBanner) is XAML with fixed sizes
    # and was the only one of the three banners not tracking S/M/L.
    # Scale it the same gentle way as the List and Explore banners -
    # height, text and layout spacing together - so the whole banner
    # grows with the portrait tiles. S = the XAML defaults (height 140,
    # title 22, sub 11, kicker 10, grid top-margin 16, button pad 14/7,
    # button font 11).
    $lb = switch ($sizeKey) {
        "S"     { @{ H = 140; Title = 22; Sub = 11; Kicker = 10; Top = 16; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
        "M"     { @{ H = 156; Title = 25; Sub = 12; Kicker = 11; Top = 20; BtnFont = 12; BtnPadX = 16; BtnPadY = 8 } }
        "L"     { @{ H = 174; Title = 28; Sub = 13; Kicker = 12; Top = 24; BtnFont = 13; BtnPadX = 18; BtnPadY = 9 } }
        default { @{ H = 140; Title = 22; Sub = 11; Kicker = 10; Top = 16; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
    }
    if ($global:window) {
        $lbB = $global:window.FindName("LibBanner")
        if ($lbB) { $lbB.Height = $lb.H }
        $lbT = $global:window.FindName("LibBannerTitle")
        if ($lbT) { $lbT.FontSize = $lb.Title }
        $lbS = $global:window.FindName("LibBannerSubtitle")
        if ($lbS) { $lbS.FontSize = $lb.Sub }
        $lbK = $global:window.FindName("LibBannerKicker")
        if ($lbK) { $lbK.FontSize = $lb.Kicker }
        $lbG = $global:window.FindName("LibBannerInnerGrid")
        if ($lbG) { $lbG.Margin = [System.Windows.Thickness]::new(22, $lb.Top, 22, 16) }
        $lbPad = [System.Windows.Thickness]::new($lb.BtnPadX, $lb.BtnPadY, $lb.BtnPadX, $lb.BtnPadY)
        $lbShow = $global:window.FindName("LibBannerShowBtn")
        if ($lbShow) { $lbShow.Padding = $lbPad }
        $lbExp = $global:window.FindName("LibBannerExploreBtn")
        if ($lbExp) { $lbExp.Padding = $lbPad }
        $lbShowTxt = $global:window.FindName("LibBannerShowBtnText")
        if ($lbShowTxt) { $lbShowTxt.FontSize = $lb.BtnFont }
        $lbExpTxt = $global:window.FindName("LibBannerExploreBtnText")
        if ($lbExpTxt) { $lbExpTxt.FontSize = $lb.BtnFont }
        $lbExpArr = $global:window.FindName("LibBannerExploreBtnArrow")
        if ($lbExpArr) { $lbExpArr.FontSize = $lb.BtnFont + 2 }
        # Re-fit the showing banner to the new font size without
        # shuffling the featured game.
        if (Get-Command Refresh-LibBannerSameGame -ErrorAction SilentlyContinue) {
            try { Refresh-LibBannerSameGame } catch { }
        }
    }
    if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
        Set-HubSetting -Key "sizeLibrary" -Value $sizeKey
    }
}

# Apply Explore size (horizontal genre rows). Same idea.
function global:Apply-ExploreSize { param($sizeKey)
    if (-not $global:OverviewTileSizes.ContainsKey($sizeKey)) { return }
    $global:ExploreSize = $sizeKey
    $global:DiscoverTileSize = $sizeKey  # keep shim in sync
    $ovDim = $global:OverviewTileSizes[$sizeKey]
    if (-not $ovDim) { return }
    if ($global:OverviewBuilt -and $global:OvGenreRowsPanel) {
        foreach ($row in $global:OvGenreRowsPanel.Children) {
            $tilesPanel = $row.Resources.Item("tilesPanel")
            if ($tilesPanel) {
                foreach ($tile in $tilesPanel.Children) {
                    $tile.Width  = $ovDim.W
                    $tile.Height = $ovDim.H
                }
            }
        }
    }
    if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
        Set-HubSetting -Key "sizeExplore" -Value $sizeKey
    }
    # The featured Explore banner is XAML with fixed sizes, so it
    # doesn't move with the genre tiles on its own. Scale its height,
    # text AND layout spacing together with S/M/L so the whole banner
    # grows as one piece - if only the fonts moved, the genre line
    # would drift toward (S) or away from (L) the buttons, since the
    # title block is top-anchored and the buttons are bottom-anchored.
    # M = the XAML defaults (height 200, title 24, sub 11, kicker 10,
    # grid top-margin 68, button pad 14/7, button font 11).
    $banner = switch ($sizeKey) {
        "S"     { @{ H = 184; Title = 21; Sub = 11;   Kicker = 9;  Top = 62; BtnFont = 11; BtnPadX = 12; BtnPadY = 6 } }
        "M"     { @{ H = 200; Title = 24; Sub = 11;   Kicker = 10; Top = 70; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
        "L"     { @{ H = 224; Title = 27; Sub = 12.5; Kicker = 11; Top = 82; BtnFont = 12; BtnPadX = 16; BtnPadY = 8 } }
        default { @{ H = 200; Title = 24; Sub = 11;   Kicker = 10; Top = 70; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
    }
    if ($global:window) {
        $ob = $global:window.FindName("OvBanner")
        if ($ob) { $ob.Height = $banner.H }
        $obt = $global:window.FindName("OvBannerTitle")
        if ($obt) { $obt.FontSize = $banner.Title }
        $obs = $global:window.FindName("OvBannerSubtitle")
        if ($obs) { $obs.FontSize = $banner.Sub }
        $obk = $global:window.FindName("OvBannerKicker")
        if ($obk) { $obk.FontSize = $banner.Kicker }
        # Title-grid top margin grows with banner height so the title
        # block stays vertically centred between the back button and
        # the action buttons instead of drifting.
        $obg = $global:window.FindName("OvBannerTitleGrid")
        if ($obg) { $obg.Margin = [System.Windows.Thickness]::new(22, $banner.Top, 22, 16) }
        # Action buttons scale with the text so they don't look tiny at
        # L or oversized at S.
        $btnPad = [System.Windows.Thickness]::new($banner.BtnPadX, $banner.BtnPadY, $banner.BtnPadX, $banner.BtnPadY)
        $showBtn = $global:window.FindName("OvBannerShowBtn")
        if ($showBtn) { $showBtn.Padding = $btnPad }
        $shufBtn = $global:window.FindName("OvBannerShuffleBtn")
        if ($shufBtn) { $shufBtn.Padding = $btnPad }
        $showTxt = $global:window.FindName("OvBannerShowBtnText")
        if ($showTxt) { $showTxt.FontSize = $banner.BtnFont }
        $shufTxt = $global:window.FindName("OvBannerShuffleBtnText")
        if ($shufTxt) { $shufTxt.FontSize = $banner.BtnFont }
        # Re-fit the current banner so its title re-truncates against
        # the new font size / width - WITHOUT shuffling to a new game
        # (size change should not change which mod is featured).
        if ($global:OverviewBuilt -and (Get-Command Refresh-OvBannerSameGame -ErrorAction SilentlyContinue)) {
            try { Refresh-OvBannerSameGame } catch { }
        }
    }
    # Genre + power filter buttons scale with Explore S/M/L too. They're
    # cheap (a dozen chips) so rebuild them at the new size, then restore
    # the active genre/power selection that the rebuild reset to ALL.
    if ($global:OverviewBuilt) {
        if (Get-Command Build-OvGenreFilter -ErrorAction SilentlyContinue) {
            Build-OvGenreFilter
            if ($global:OvGenreFilterPanel -and (Get-Command Update-OvFilterChips -ErrorAction SilentlyContinue)) {
                $gk = if ($global:OvActiveGenre) { $global:OvActiveGenre } else { "ALL" }
                Update-OvFilterChips -ChipPanel $global:OvGenreFilterPanel -ActiveKey $gk
            }
        }
        if (Get-Command Build-OvPowerFilter -ErrorAction SilentlyContinue) {
            Build-OvPowerFilter
            if ($global:OvPowerFilterPanel -and (Get-Command Update-OvFilterChips -ErrorAction SilentlyContinue)) {
                $pk = if ($global:OvActivePower) { $global:OvActivePower } else { "ALL" }
                Update-OvFilterChips -ChipPanel $global:OvPowerFilterPanel -ActiveKey $pk
            }
        }
        if (Get-Command Apply-OvPowerModeToggleStyle -ErrorAction SilentlyContinue) {
            Apply-OvPowerModeToggleStyle
        }
    }
}
function global:Apply-DetailSize { param($sizeKey)
    if (-not $global:DetailTextSizes.ContainsKey($sizeKey)) { return }
    $global:DetailSize = $sizeKey
    $cfg = $global:DetailTextSizes[$sizeKey]
    if ($global:DetailDescTxt) {
        $global:DetailDescTxt.FontSize   = $cfg.Font
        $global:DetailDescTxt.LineHeight = $cfg.LineHeight
    }
    if ($global:DetailReadmeTextBlocks) {
        foreach ($tb in $global:DetailReadmeTextBlocks) {
            if ($tb) {
                if ($tb.Tag -eq "heading") {
                    # Section headings sit one point above body and
                    # scale together with it.
                    $tb.FontSize = [int]$cfg.Font + 1
                } elseif ($tb.Tag -eq 'guide-number') {
                    $tb.FontSize = [int]$cfg.Font - 2
                    $tb.LineHeight = $cfg.LineHeight
                } else {
                    $tb.FontSize   = $cfg.Font
                    $tb.LineHeight = $cfg.LineHeight
                }
                # Button pills are InlineUIContainers embedded in the
                # text runs. Their Border/TextBlock have fixed pixel
                # sizes set at render time, so a plain FontSize bump on
                # the parent TextBlock leaves them behind. Walk the
                # inlines, find the pill containers, and rescale their
                # geometry from the new body font using the SAME ratios
                # the renderer uses (base*0.75 font, *1.214 height, etc.)
                # so a live S/M/L toggle keeps pills matched to the text.
                try {
                    $pillBase = if ($tb.Tag -eq "heading") { [int]$cfg.Font + 1 } else { $cfg.Font }
                    foreach ($inl in @($tb.Inlines)) {
                        if ($inl -is [System.Windows.Documents.InlineUIContainer]) {
                            $brd = $inl.Child
                            if ($brd -is [System.Windows.Controls.Border]) {
                                $brd.Height       = [int][math]::Round($pillBase * 1.214)
                                $padX             = [int][math]::Round($pillBase * 0.43)
                                $brd.Padding      = [System.Windows.Thickness]::new($padX, 1, $padX, 1)
                                $brd.CornerRadius = [System.Windows.CornerRadius]::new([math]::Round($pillBase * 0.571, 1))
                                $inner = $brd.Child
                                if ($inner -is [System.Windows.Controls.TextBlock]) {
                                    $inner.FontSize   = [math]::Round($pillBase * 0.75, 1)
                                    $inner.LineHeight = [int][math]::Round($pillBase * 0.929)
                                }
                            }
                        }
                    }
                } catch { }
            }
        }
    }
    if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
        Set-HubSetting -Key "sizeDetail" -Value $sizeKey
    }
}

# Compatibility shim: callers using the old function name still
# work (they target Library by default since that was the old
# discover view).
function global:Apply-DiscoverTileSize { param($sizeKey)
    Apply-LibrarySize $sizeKey
}

# Identify which of the four views is currently visible so the
# S/M/L click + sync routes to the right setting.
function global:Get-CurrentView {
    if ($global:discoverHost -and $global:discoverHost.Visibility -eq [System.Windows.Visibility]::Visible) {
        if ($global:discoverDetail -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
            return "Detail"
        }
        if ($global:discoverOverview -and $global:discoverOverview.Visibility -eq [System.Windows.Visibility]::Visible) {
            return "Explore"
        }
        return "Library"
    }
    return "List"
}

# Sync the S/M/L button state to whatever the *active* mode's
# size currently is. Called on mode switches so the active
# button reflects reality.
function global:Sync-ScaleButtonsToMode {
    # When discoverHost isn't built yet (very early in startup),
    # treat as List view - Get-CurrentView would otherwise return
    # "List" by default but the early bail-out used to skip the
    # whole function, which left the S button un-highlighted on
    # startup if the user had S saved. M/L still worked because
    # Apply-Scale highlighted them directly on rebuild.
    $view = if ($global:discoverHost) { Get-CurrentView } else { "List" }
    $key = switch ($view) {
        "Detail"  { $global:DetailSize }
        "Explore" { $global:ExploreSize }
        "Library" { $global:LibrarySize }
        default {
            switch ($global:SCALE) {
                1.0 { "S" }
                1.5 { "M" }
                2.0 { "L" }
                default { "S" }
            }
        }
    }
    switch ($key) {
        "S" { Set-ScaleActive $scaleSBtn }
        "M" { Set-ScaleActive $scaleMBtn }
        "L" { Set-ScaleActive $scaleLBtn }
        default { Set-ScaleActive $scaleSBtn }
    }
}

# Per-view S/M/L click: routes to whichever Apply-* corresponds to
# the visible view, so each view keeps its own independent size.
function global:On-ScaleClick { param($listScale, $discoverSize, $activeBtn)
    # Set the active-button glow FIRST so the user gets instant visual
    # confirmation of their click. The card rebuild below can take ~2s
    # for the full list at a new size; if we ran it inline the UI thread
    # would be blocked and the glow would only paint AFTER the rebuild
    # finished (looking like the button didn't respond). So we set the
    # glow, then defer the heavy work by one dispatcher cycle at
    # Background priority - the glow paints immediately, the rebuild
    # runs right after.
    Set-ScaleActive $activeBtn
    $view = Get-CurrentView
    $doResize = {
        switch ($view) {
            "Detail"  { Apply-DetailSize  $discoverSize }
            "Explore" { Apply-ExploreSize $discoverSize }
            "Library" { Apply-LibrarySize $discoverSize }
            default   { Apply-Scale $listScale $activeBtn }
        }
    }.GetNewClosure()
    if ($global:window) {
        $global:window.Dispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [action]$doResize
        ) | Out-Null
    } else {
        & $doResize
    }
}

# Apply persisted sizes to whatever's already built on startup,
# so the user's saved preferences are reflected from frame 1.
# Apply-LibrarySize runs unconditionally: its tile loop is self-
# guarded (only resizes tiles once built), but the featured banner
# must be scaled to the saved size right away - otherwise it shows
# at the XAML default until the user toggles S/M/L once.
Apply-LibrarySize $global:LibrarySize
if ($global:OverviewBuilt)      { Apply-ExploreSize $global:ExploreSize }
# List cards are built at base size above; apply the saved S/M/L
# scale via LayoutTransform (instant, no rebuild) and highlight the
# matching button.
Apply-CardScale
# Scale the list banner to the saved size too - Apply-CardScale only
# handles the cards, so without this the banner stays at the XAML
# default until the user toggles S/M/L once.
Set-ListBannerScale $global:SCALE
if ($global:SCALE -ne 1.0) {
    $initialScaleBtn = switch ($global:SCALE) {
        1.5 { $scaleMBtn }
        2.0 { $scaleLBtn }
        default { $scaleSBtn }
    }
    Set-ScaleActive $initialScaleBtn
}

Sync-ScaleButtonsToMode
if (Get-Command Set-HeaderFontScale -ErrorAction SilentlyContinue) { Set-HeaderFontScale $global:SCALE }
if (Get-Command Restore-FilterPills -ErrorAction SilentlyContinue) { Restore-FilterPills }
$scaleSBtn.Add_PreviewMouseLeftButtonDown({ On-ScaleClick 1.0 "S" $scaleSBtn }.GetNewClosure())
$scaleMBtn.Add_PreviewMouseLeftButtonDown({ On-ScaleClick 1.5 "M" $scaleMBtn }.GetNewClosure())
$scaleLBtn.Add_PreviewMouseLeftButtonDown({ On-ScaleClick 2.0 "L" $scaleLBtn }.GetNewClosure())

# ---------------------------------------------------------------
# Recently Played - small tile row sitting between the Featured
# banner and the Custom Installers section in the Library list.
# Shows the five most recent launch requests, newest first.
# A later installed-games scan removes entries whose VR mod is no longer
# present, while a cold start can render saved history immediately.
# ---------------------------------------------------------------
$recentSection      = $window.FindName("RecentlyPlayedSection")
$recentList         = $window.FindName("RecentlyPlayedList")
$recentHeader       = $window.FindName("RecentlyPlayedHeader")
$recentHeaderHost   = $window.FindName("RecentlyPlayedHeaderHost")
$recentCloseOverlay = $window.FindName("RecentlyPlayedCloseOverlay")
$recentCloseBtn     = $window.FindName("RecentlyPlayedCloseBtn")
$recentDisableBtn   = $window.FindName("RecentlyPlayedDisableBtn")
$script:recentTileDwellTimers = New-Object System.Collections.ArrayList

# Match the three Custom Installer section headers: a small render-only grow
# confirms that this text surface is interactive without relaying out the row
# or touching any of its portrait tiles.
Add-HeaderHoverGrow -Element $recentHeader -Scale 1.025

function Clear-RecentlyPlayedTileDwellTimers {
    foreach ($timer in @($script:recentTileDwellTimers)) {
        try { $timer.Stop() } catch {}
    }
    $script:recentTileDwellTimers.Clear()
}

function global:Build-RecentlyPlayed {
    if (-not $recentList) { return }

    # Toggle: user dismissed the section permanently via the
    # hover-overlay's "Always disable" button. Setting persists
    # across sessions.
    $hidden = [bool](Get-HubSetting -Key "recentlyPlayedHidden" -Default $false)
    if ($hidden) {
        Clear-RecentlyPlayedTileDwellTimers
        $recentList.Children.Clear()
        $script:recentBuiltSig = $null
        if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Collapsed }
        return
    }

    # Pick the 5 most recently launched games from play history.
    # If the user hasn't launched anything yet, the section stays
    # hidden - that matches the header's "Click to launch in VR -
    # last 5 games shown" promise. Showing test entries before any
    # launch would mislead the user into thinking they had played
    # games they hadn't.
    $candidates = @()
    try {
        $history = Get-HubSetting -Key "playHistory" -Default @()
        $ignoredIds = @(Get-HubSetting -Key "recentlyPlayedIgnoredGameIds" -Default @())
        if ($history -and $history.Count -gt 0) {
            $byTitle = @{}
            foreach ($g in @($ownGames + $ownGamesGP + $externalGames)) {
                if ($g.Title) { $byTitle[$g.Title] = $g }
            }
            # ONLY GAMES WHOSE VR MOD IS STILL THERE (2026-08-20).
            # Before this, the row was built from playHistory alone, so
            # a game stayed in "Recently Played" after its mod had been
            # deleted - and clicking it tried to launch something that
            # no longer exists. History records what WAS played; it must
            # not decide what CAN be played now.
            # "ready" and "update" both mean the mod is on disk;
            # "installed" means only the game is there, and "free" means
            # nothing at all.
            # NOTE ON THE EMPTY MAP: before the first scan gameStateMap
            # is empty. Filtering then would blank the row on every cold
            # start, so with no map at all the history is shown as
            # before, and the next scan trims it.
            $haveState = ($global:gameStateMap -and $global:gameStateMap.Count -gt 0)
            foreach ($title in $history) {
                if ($candidates.Count -ge 5) { break }
                if (-not $byTitle.ContainsKey($title)) { continue }
                $candidate = $byTitle[$title]
                $candidateId = Get-HubGameStateId -Game $candidate
                if ($candidateId -and $ignoredIds -contains $candidateId) { continue }
                if ($haveState) {
                    $st = $global:gameStateMap[$title]
                    if (-not $st) { continue }
                    if (@("ready", "update") -notcontains [string]$st.State) { continue }
                }
                $candidates += $candidate
            }
        }
    } catch { }

    if ($candidates.Count -eq 0) {
        Clear-RecentlyPlayedTileDwellTimers
        $recentList.Children.Clear()
        $script:recentBuiltSig = $null
        if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Collapsed }
        return
    }

    # Idempotency guard: Check Installed / Check on Startup calls
    # Build-RecentlyPlayed after every scan to "keep the row in
    # sync", but the row's contents only depend on playHistory +
    # the candidate titles - the scan doesn't change either. Wiping
    # and rebuilding the tiles when nothing has changed makes the
    # portrait images flicker. So we cache a signature of the last
    # built tile order and bail out early if it matches.
    # The signature has to carry the install state too: the candidate
    # list now depends on it, and without it a rescan that removed a
    # game would leave the old row on screen.
    $stateSig = ""
    try {
        $stateSig = (($candidates | ForEach-Object {
            $s = $global:gameStateMap[$_.Title]
            if ($s) { "$($_.Title)=$($s.State)" } else { "$($_.Title)=?" }
        }) -join ";")
    } catch { }
    $sig = (($candidates | ForEach-Object { $_.Title }) -join "`n") + "|scale=$($global:SCALE)|st=$stateSig"
    if ($script:recentBuiltSig -eq $sig -and $recentList.Children.Count -gt 0) {
        # Already rendering the same tiles. Just ensure visibility
        # state is correct in case it was collapsed/hidden before.
        if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Visible }
        $collapsed = [bool](Get-HubSetting -Key "recentlyPlayedCollapsed" -Default $false)
        if ($recentList) {
            $recentList.Visibility = if ($collapsed) {
                [System.Windows.Visibility]::Collapsed
            } else {
                [System.Windows.Visibility]::Visible
            }
        }
        return
    }
    # Signature differs (or first build) - do a full rebuild.
    Clear-RecentlyPlayedTileDwellTimers
    $recentList.Children.Clear()
    $script:recentBuiltSig = $sig

    # Tile size scales with the active SCALE so S/M/L acts on this
    # row too. Base 90x128 at SCALE 1.0 - that's a comfortable
    # hand-sized tile that stays out of the way of the main list.
    # Base bumped +1/5 over the original 90x128 so even S reads a bit
    # larger; M and L then grow +1/3 per step on top of this base.
    $baseW = 108
    $baseH = 154
    $sc = $global:SCALE
    if (-not $sc) { $sc = 1.0 }
    # Recently Played tiles grow gently: +1/3 per step (S -> M -> L),
    # not the full list scale, so the row stays compact.
    $rpFactor = switch ($sc) {
        1.5     { 4.0 / 3.0 }                    # M: +1/3 over S
        2.0     { (4.0 / 3.0) * (4.0 / 3.0) }    # L: +1/3 over M
        default { 1.0 }                          # S
    }
    $tileW = [int]($baseW * $rpFactor)
    $tileH = [int]($baseH * $rpFactor)

    foreach ($g in $candidates) {
        $tile = New-Object System.Windows.Controls.Border
        $tile.Width  = $tileW
        $tile.Height = $tileH
        $tile.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $tile.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
        $tile.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a1a22")
        $tile.BorderThickness = [System.Windows.Thickness]::new(1)
        $tile.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
        $tile.Cursor = [System.Windows.Input.Cursors]::Hand
        $tile.ClipToBounds = $true

        $tileGrid = New-Object System.Windows.Controls.Grid

        # Portrait artwork - use Steam library_600x900 if SteamId
        # is set, custom Asset image otherwise. Fallback to dark
        # background if neither resolves.
        # IMPORTANT: load asynchronously (no OnLoad cache option) so
        # 5x Steam-CDN HTTPS downloads do not block Hub startup. The
        # tile shows its dark background immediately and the portrait
        # fades in when WPF finishes streaming it. CacheOption.OnLoad
        # would force a synchronous download on the UI thread and
        # roughly double startup time when the Recently Played row
        # is visible.
        $portraitUrl = Get-GameImageUrl -Game $g -Kind "portrait"
        if ($portraitUrl) {
            try {
                $img = New-Object System.Windows.Controls.Image
                $img.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit()
                $bmp.UriSource = ([System.Uri]$portraitUrl)
                $bmp.CreateOptions = [System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreImageCache
                # No CacheOption -> default streams asynchronously.
                $bmp.EndInit()
                $img.Source = $bmp
                $tileGrid.Children.Add($img) | Out-Null
            } catch { }
        }

        # Bottom gradient overlay for title legibility.
        $titleBg = New-Object System.Windows.Shapes.Rectangle
        $titleBg.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
        $titleBg.Height = 36
        $gradStops = New-Object System.Windows.Media.GradientStopCollection
        $gradStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,0,0,0), 0))) | Out-Null
        $gradStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(220,0,0,0), 1))) | Out-Null
        $titleBg.Fill = New-Object System.Windows.Media.LinearGradientBrush $gradStops, ([System.Windows.Point]::new(0,0)), ([System.Windows.Point]::new(0,1))
        $tileGrid.Children.Add($titleBg) | Out-Null

        # Title text (truncated with ellipsis if too long).
        $titleTxt = New-Object System.Windows.Controls.TextBlock
        $titleTxt.Text = $g.Title
        $titleTxt.FontSize = [Math]::Max(9, [int](9 * $sc))
        $titleTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $titleTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $titleTxt.Foreground = [System.Windows.Media.Brushes]::White
        $titleTxt.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis
        $titleTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
        $titleTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $titleTxt.TextAlignment = [System.Windows.TextAlignment]::Center
        $titleTxt.Margin = [System.Windows.Thickness]::new(4, 0, 4, 6)
        $tileGrid.Children.Add($titleTxt) | Out-Null

        # Per-tile privacy controls. They remain completely absent from normal
        # interaction until the pointer rests on this Recently Played tile for
        # seven seconds. Close removes this one history entry; Always disable
        # also stores the stable game ID so later launches do not re-add it.
        $tileManageOverlay = New-Object System.Windows.Controls.StackPanel
        $tileManageOverlay.Orientation = [System.Windows.Controls.Orientation]::Vertical
        $tileManageOverlay.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $tileManageOverlay.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $tileManageOverlay.Margin = [System.Windows.Thickness]::new(0, 5, 5, 0)
        $tileManageOverlay.Visibility = [System.Windows.Visibility]::Collapsed
        $tileManageOverlay.Tag = 'RecentlyPlayedManagementOverlay'
        [System.Windows.Controls.Panel]::SetZIndex($tileManageOverlay, 25)

        $tileCloseBtn = New-Object System.Windows.Controls.Border
        $tileCloseBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ee1a1a22")
        $tileCloseBtn.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $tileCloseBtn.BorderThickness = [System.Windows.Thickness]::new(1)
        $tileCloseBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
        $tileCloseBtn.Padding = [System.Windows.Thickness]::new(6, 3, 6, 3)
        $tileCloseBtn.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)
        $tileCloseBtn.Cursor = [System.Windows.Input.Cursors]::Hand
        $tileCloseBtn.Tag = 'RecentlyPlayedClose'
        $tileCloseBtn.ToolTip = "Remove this game from Recently Played. It returns after the next launch."
        $tileCloseText = New-Object System.Windows.Controls.TextBlock
        $tileCloseText.Text = "Close"
        $tileCloseText.FontSize = [Math]::Max(8, [int](8 * $rpFactor))
        $tileCloseText.FontWeight = [System.Windows.FontWeights]::SemiBold
        $tileCloseText.Foreground = [System.Windows.Media.Brushes]::White
        $tileCloseText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $tileCloseBtn.Child = $tileCloseText
        $tileManageOverlay.Children.Add($tileCloseBtn) | Out-Null

        $tileIgnoreBtn = New-Object System.Windows.Controls.Border
        $tileIgnoreBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ee1a1a22")
        $tileIgnoreBtn.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $tileIgnoreBtn.BorderThickness = [System.Windows.Thickness]::new(1)
        $tileIgnoreBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677")
        $tileIgnoreBtn.Padding = [System.Windows.Thickness]::new(6, 3, 6, 3)
        $tileIgnoreBtn.Cursor = [System.Windows.Input.Cursors]::Hand
        $tileIgnoreBtn.Tag = 'RecentlyPlayedAlwaysDisable'
        $tileIgnoreBtn.ToolTip = "Always hide this game from Recently Played."
        $tileIgnoreText = New-Object System.Windows.Controls.TextBlock
        $tileIgnoreText.Text = "Always disable"
        $tileIgnoreText.FontSize = [Math]::Max(8, [int](8 * $rpFactor))
        $tileIgnoreText.FontWeight = [System.Windows.FontWeights]::SemiBold
        $tileIgnoreText.Foreground = [System.Windows.Media.Brushes]::White
        $tileIgnoreText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $tileIgnoreBtn.Child = $tileIgnoreText
        $tileManageOverlay.Children.Add($tileIgnoreBtn) | Out-Null
        $tileGrid.Children.Add($tileManageOverlay) | Out-Null

        $tile.Child = $tileGrid

        # Hover: subtle accent border lift (matches the Library
        # card hover idiom but in a more compact way). The management
        # controls appear only after a deliberate seven-second dwell.
        $accent = if ($g.Accent) { $g.Accent } else { "#666677" }
        $tileDwellTimer = New-Object System.Windows.Threading.DispatcherTimer
        $tileDwellTimer.Interval = [TimeSpan]::FromSeconds(7)
        $tileForDwell = $tile
        $overlayForDwell = $tileManageOverlay
        $timerForDwellTick = $tileDwellTimer
        $tileDwellTimer.Add_Tick({
            $timerForDwellTick.Stop()
            if ($tileForDwell.IsMouseOver) {
                $overlayForDwell.Visibility = [System.Windows.Visibility]::Visible
            }
        }.GetNewClosure())
        [void]$script:recentTileDwellTimers.Add($tileDwellTimer)
        $timerForTile = $tileDwellTimer
        $overlayForTile = $tileManageOverlay
        $tile.Add_MouseEnter({
            $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accent)
            $timerForTile.Stop()
            if ($overlayForTile.Visibility -ne [System.Windows.Visibility]::Visible) {
                $timerForTile.Start()
            }
        }.GetNewClosure())
        $tile.Add_MouseLeave({
            $timerForTile.Stop()
            $overlayForTile.Visibility = [System.Windows.Visibility]::Collapsed
            $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
        }.GetNewClosure())

        $closeGameRef = $g
        $tileCloseBtn.Add_PreviewMouseLeftButtonDown({ param($sender, $e) $e.Handled = $true })
        $tileCloseBtn.Add_PreviewMouseLeftButtonUp({
            param($sender, $e)
            $e.Handled = $true
            $gameId = Get-HubGameStateId -Game $closeGameRef
            if (Remove-HubRecentlyPlayedGame -Title $closeGameRef.Title -GameId $gameId) {
                $script:recentBuiltSig = $null
                Build-RecentlyPlayed
            }
        }.GetNewClosure())
        $tileCloseBtn.Add_MouseEnter({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") })
        $tileCloseBtn.Add_MouseLeave({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677") })

        $ignoreGameRef = $g
        $tileIgnoreBtn.Add_PreviewMouseLeftButtonDown({ param($sender, $e) $e.Handled = $true })
        $tileIgnoreBtn.Add_PreviewMouseLeftButtonUp({
            param($sender, $e)
            $e.Handled = $true
            $gameId = Get-HubGameStateId -Game $ignoreGameRef
            if (Remove-HubRecentlyPlayedGame -Title $ignoreGameRef.Title -GameId $gameId -AlwaysHide) {
                $script:recentBuiltSig = $null
                Build-RecentlyPlayed
            }
        }.GetNewClosure())
        $tileIgnoreBtn.Add_MouseEnter({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") })
        $tileIgnoreBtn.Add_MouseLeave({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666677") })

        # Click - direct Start-GameInVR per Martin's spec. No
        # detail-view detour: the tile is a one-tap launcher. While the
        # delayed privacy overlay is visible, its buttons own the click.
        $gameRef = $g
        $manageOverlayRef = $tileManageOverlay
        $tile.Add_PreviewMouseLeftButtonDown({
            if ($manageOverlayRef.Visibility -eq [System.Windows.Visibility]::Visible) { return }
            Start-GameInVR -Game $gameRef
        }.GetNewClosure())

        $recentList.Children.Add($tile) | Out-Null
    }

    if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Visible }

    # Honor a persisted collapsed-state. The Hide link (right side
    # of the header) handles "permanently hide the whole section";
    # the header-click toggles just the tile list. Both states
    # survive Hub restarts via the durable Hub state.
    $collapsed = [bool](Get-HubSetting -Key "recentlyPlayedCollapsed" -Default $false)
    if ($recentList) {
        $recentList.Visibility = if ($collapsed) {
            [System.Windows.Visibility]::Collapsed
        } else {
            [System.Windows.Visibility]::Visible
        }
    }
}

if ($recentSection -and $recentHeaderHost -and $recentCloseOverlay -and $recentCloseBtn -and $recentDisableBtn) {
    # Hover-overlay pattern matching the featured banner: 5 seconds
    # of hover on the header reveals Close + Always disable. Close
    # hides this session only; Always disable persists to
    # durable Hub state so the section stays gone on restart.
    # Hover target is the header host only (not the tile list) so
    # users can still mouse-over tiles to launch without triggering
    # the overlay.

    # 5-second show timer on hover, 800ms hide timer on leave.
    $rpShowTimer = New-Object System.Windows.Threading.DispatcherTimer
    $rpShowTimer.Interval = [TimeSpan]::FromSeconds(5)
    $rpHideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $rpHideTimer.Interval = [TimeSpan]::FromMilliseconds(800)

    $rpShowTimer.Add_Tick({
        $rpShowTimer.Stop()
        $recentCloseOverlay.Visibility = [System.Windows.Visibility]::Visible
    }.GetNewClosure())
    $rpHideTimer.Add_Tick({
        $rpHideTimer.Stop()
        $recentCloseOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())

    $recentHeaderHost.Add_MouseEnter({
        $rpHideTimer.Stop()
        if ($recentCloseOverlay.Visibility -ne [System.Windows.Visibility]::Visible) {
            $rpShowTimer.Stop()
            $rpShowTimer.Start()
        }
    }.GetNewClosure())
    $recentHeaderHost.Add_MouseLeave({
        $rpShowTimer.Stop()
        if ($recentCloseOverlay.Visibility -eq [System.Windows.Visibility]::Visible) {
            $rpHideTimer.Stop()
            $rpHideTimer.Start()
        }
    }.GetNewClosure())

    # Close = hide the section for this session (no persist).
    $recentCloseBtn.Add_MouseLeftButtonUp({
        if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Collapsed }
    }.GetNewClosure())
    $recentCloseBtn.Add_MouseEnter({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") })
    $recentCloseBtn.Add_MouseLeave({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48") })

    # Always disable = hide + persist.
    $recentDisableBtn.Add_MouseLeftButtonUp({
        if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Collapsed }
        if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
            Set-HubSetting -Key "recentlyPlayedHidden" -Value $true
        }
    }.GetNewClosure())
    $recentDisableBtn.Add_MouseEnter({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") })
    $recentDisableBtn.Add_MouseLeave({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48") })
}

if ($recentHeader) {
    # Click-toggle: collapse the tile list. Same idiom as the
    # Custom Installers / Game Pass / Custom Setups headers.
    # Distinct from the hover-overlay (Close / Always disable) -
    # that one hides the whole section; this one just folds the
    # tile list up and the user can unfold it again.
    $recentHeader.Add_PreviewMouseLeftButtonDown({
        if (-not $recentList) { return }
        $vis = if ($recentList.Visibility -eq [System.Windows.Visibility]::Visible) {
            [System.Windows.Visibility]::Collapsed
        } else {
            [System.Windows.Visibility]::Visible
        }
        $recentList.Visibility = $vis
        Set-HubSetting -Key "recentlyPlayedCollapsed" -Value ($vis -eq [System.Windows.Visibility]::Collapsed)
    })
}

# Search
$searchBox   = $window.FindName("SearchBox")
# Help & Feedback menu - rendered as an in-window overlay (MenuOverlay in the
# root Grid), NOT a Popup. A Popup delivered each click to BOTH itself and the
# content behind it (the banner). The overlay keeps everything in one visual
# tree: the scrim swallows outside clicks, and the menu lives in a different
# branch than the banner/cards, so a menu click can never route to them. All
# three items are wired: Suggest and Report open GitHub issue forms, Discord
# opens the invite.
$global:menuBtn     = $window.FindName("MenuBtn")
$global:menuDots    = $window.FindName("MenuDots")
$global:menuOverlay = $window.FindName("MenuOverlay")
$global:menuScrim   = $window.FindName("MenuScrim")

# Shared brushes (one instance reused across handlers - fine in WPF).
$bc = [System.Windows.Media.BrushConverter]::new()
$global:brBtnRest   = $bc.ConvertFromString("#16161a")
$global:brBtnBorder = $bc.ConvertFromString("#3a3a48")
$global:brBlue      = $bc.ConvertFromString("#3a8add")
$global:brDotRest   = $bc.ConvertFromString("#aaaaaa")
$global:brWhite     = [System.Windows.Media.Brushes]::White

# "Active" look = blue border + white dots. Used for both hover and open.
function global:Set-MenuBtnActive {
    param([bool]$Active)
    $global:menuBtn.BorderBrush = if ($Active) { $global:brBlue } else { $global:brBtnBorder }
    foreach ($d in $global:menuDots.Children) {
        $d.Fill = if ($Active) { $global:brWhite } else { $global:brDotRest }
    }
}
function global:Test-HubMenuOpen {
    return ($global:menuOverlay.Visibility -eq [System.Windows.Visibility]::Visible)
}
function global:Open-HubMenu {
    if (Get-Command Close-CatalogOrderMenu -ErrorAction SilentlyContinue) { Close-CatalogOrderMenu }
    # Re-read the shortcut flag on every open: a second Hub instance or a
    # externally restored state must not leave a stale label behind.
    if (Get-Command Update-HubShortcutMenuItem -ErrorAction SilentlyContinue) { Update-HubShortcutMenuItem }
    $global:menuOverlay.Visibility = [System.Windows.Visibility]::Visible
    $global:menuBtn.Background = $global:brBtnRest
    Set-MenuBtnActive -Active $true
}
function global:Close-HubMenu {
    $global:menuOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    $global:menuBtn.Background = $global:brBtnRest
    Set-MenuBtnActive -Active ($global:menuBtn.IsMouseOver)
}

# Trigger hover: dots white + border blue. Leave falls back to the open state.
$global:menuBtn.Add_MouseEnter({ Set-MenuBtnActive -Active $true })
$global:menuBtn.Add_MouseLeave({ Set-MenuBtnActive -Active (Test-HubMenuOpen) })
# Click the trigger: toggle the overlay. Handled so nothing else reacts.
$global:menuBtn.Add_PreviewMouseLeftButtonDown({ param($s, $e)
    $e.Handled = $true
    if (Test-HubMenuOpen) { Close-HubMenu } else { Open-HubMenu }
    # Click FX: a quick brightness pulse that fades back to the rest colour.
    # Its own animated brush (so it doesn't disturb the shared rest brush) and
    # an animation that repaints itself - no reliance on a mouse-up, which the
    # open menu's scrim would otherwise swallow.
    $pulse = New-Object System.Windows.Media.SolidColorBrush (
        [System.Windows.Media.Color][System.Windows.Media.ColorConverter]::ConvertFromString("#16161a"))
    $this.Background = $pulse
    $anim = New-Object System.Windows.Media.Animation.ColorAnimation
    $anim.From     = [System.Windows.Media.Color][System.Windows.Media.ColorConverter]::ConvertFromString("#3a3a52")
    $anim.To       = [System.Windows.Media.Color][System.Windows.Media.ColorConverter]::ConvertFromString("#16161a")
    $anim.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(220))
    $pulse.BeginAnimation([System.Windows.Media.SolidColorBrush]::ColorProperty, $anim)
})

# Scrim: any click outside the menu closes it and goes nowhere else.
$global:menuScrim.Add_MouseLeftButtonDown({ param($s, $e)
    $e.Handled = $true
    Close-HubMenu
})
# Scrolling dismisses the menu too.
$global:menuOverlay.Add_PreviewMouseWheel({ param($s, $e) Close-HubMenu })

# Menu item hover (shared look). MouseLeave always restores Transparent.
$menuItemEnter = { $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1e1e2a") }
$menuItemLeave = { $this.Background = [System.Windows.Media.Brushes]::Transparent }

$miSuggest = $window.FindName("MiSuggest")
$miReport  = $window.FindName("MiReport")
$miDiscord = $window.FindName("MiDiscord")

$miSuggest.Add_MouseEnter($menuItemEnter); $miSuggest.Add_MouseLeave($menuItemLeave)
$miReport.Add_MouseEnter($menuItemEnter);  $miReport.Add_MouseLeave($menuItemLeave)
$miDiscord.Add_MouseEnter($menuItemEnter); $miDiscord.Add_MouseLeave($menuItemLeave)

# Item click: mark handled, then close, then run the action.
$miSuggest.Add_MouseLeftButtonUp({ param($s, $e)
    $e.Handled = $true
    Close-HubMenu
    # Opens the GitHub "VR mod suggestion" issue form. Renders as a form
    # once the issue templates are committed to the repo.
    Start-Process "https://github.com/Mr-Nlce/PCVR-Mods-Installer-Hub/issues/new?template=mod-suggestion.yml"
})
$miReport.Add_MouseLeftButtonUp({ param($s, $e)
    $e.Handled = $true
    Close-HubMenu
    # Runtime logs live in the obvious portable Core\Logs folder. Release
    # hygiene requires that folder to be absent or empty before packaging, so
    # a release ZIP can never ship somebody's paths or previous output.
    # Open the newest log preselected so it can be dragged straight into the
    # bug report that opens next.
    try {
        $logsDir = Get-HubRuntimeLogsRoot
        if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
        $allLogs = @(Get-ChildItem $logsDir -Filter *.log -File -ErrorAction SilentlyContinue |
                     Sort-Object LastWriteTime -Descending)
        # Never preselect an empty live transcript when a useful report exists.
        $newest = $allLogs | Where-Object Length -gt 0 | Select-Object -First 1
        if (-not $newest) { $newest = $allLogs | Select-Object -First 1 }
        if ($newest) { Start-Process explorer.exe "/select,`"$($newest.FullName)`"" }
        else         { Start-Process explorer.exe $logsDir }
    } catch {}
    # Opens the GitHub bug-report issue form. Renders as a form once the
    # issue templates are committed to the repo.
    Start-Process "https://github.com/Mr-Nlce/PCVR-Mods-Installer-Hub/issues/new?template=bug-report.yml"
})
# Discord keeps the existing, already-verified invite.
$miDiscord.Add_MouseLeftButtonUp({ param($s, $e)
    $e.Handled = $true
    Close-HubMenu
    Start-Process "https://discord.gg/uAeQkYBM4n"
})

# Switch Hub Style: flip frosted <-> classic tiles (persisted) and
# rebuild the card lists. Same hover treatment as the other items.
$miStyle = $window.FindName("MiStyle")
if ($miStyle) {
    $miStyle.Add_MouseEnter($menuItemEnter); $miStyle.Add_MouseLeave($menuItemLeave)
    $miStyle.Add_MouseLeftButtonUp({ param($s, $e)
        $e.Handled = $true
        Close-HubMenu
        if (Get-Command Switch-HubStyle -ErrorAction SilentlyContinue) { Switch-HubStyle }
    })
}

# Desktop Shortcut: opt-out for the shortcut the Hub writes on every
# launch. The dot and the sub-line carry the current state, because
# unlike the style toggle the result is off-screen (on the desktop).
$global:miShortcut    = $window.FindName("MiShortcut")
$global:miShortcutDot = $window.FindName("MiShortcutDot")
$global:miShortcutSub = $window.FindName("MiShortcutSub")
function global:Update-HubShortcutMenuItem {
    if (-not $global:miShortcutSub) { return }
    $on = $true
    if (Get-Command Get-HubShortcutFlag -ErrorAction SilentlyContinue) { $on = [bool](Get-HubShortcutFlag) }
    $global:miShortcutSub.Text = if ($on) { "Currently on - click to turn off" }
                                 else     { "Currently off - click to turn on" }
    if ($global:miShortcutDot) {
        $global:miShortcutDot.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString(
            $(if ($on) { "#4ac07a" } else { "#55555f" }))
    }
}
if ($global:miShortcut) {
    $global:miShortcut.Add_MouseEnter($menuItemEnter)
    $global:miShortcut.Add_MouseLeave($menuItemLeave)
    $global:miShortcut.Add_MouseLeftButtonUp({ param($s, $e)
        $e.Handled = $true
        Close-HubMenu
        if (-not (Get-Command Get-HubShortcutFlag -ErrorAction SilentlyContinue)) { return }
        $newState = -not [bool](Get-HubShortcutFlag)
        # Persist FIRST (a real boolean, so the reader never has to guess),
        # then act on the desktop: even if writing/deleting the .lnk fails,
        # the next launch will not recreate an unwanted shortcut.
        Set-HubSetting -Key "desktopShortcut" -Value ([bool]$newState)
        [void](Set-HubDesktopShortcut -Enabled $newState)
        Update-HubShortcutMenuItem
    })
    Update-HubShortcutMenuItem
}

# Clicking the header VR-glasses glyph also flips the tile style
# (tooltip "Switch style" set in XAML). Same action as the menu item.
if ($headerVrIcon) {
    $headerVrIcon.Add_MouseLeftButtonUp({ param($s, $e)
        $e.Handled = $true
        if (Get-Command Switch-HubStyle -ErrorAction SilentlyContinue) { Switch-HubStyle }
    })
}
