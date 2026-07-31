# ---------------------------------------------------------------
# Check on Startup: hover-reveal companion toggle next to the
# Check Installed button. Persisted to a small JSON settings
# file so the user only has to click it once. Settings file is
# user-data and never shipped in the release bundle.
# ---------------------------------------------------------------
$checkOnStartupBtn   = $window.FindName("CheckOnStartupBtn")
$checkOnStartupCheck = $window.FindName("CheckOnStartupCheck")
$checkOnStartupText  = $window.FindName("CheckOnStartupText")
$hoverGroup          = $window.FindName("CheckInstalledHoverGroup")

# Glow hover for the toggle. When the toggle is OFF, the
# default border is a subtle dark green - hovering swaps it to
# the bright green accent which is the inviting "click me to
# enable" cue. When ON, the border already IS the bright accent,
# so the helper's swap is a no-op - matching the "no glow when
# already active" behavior naturally.
Add-GlowHover -Border $checkOnStartupBtn -AccentHex "#5aa880"

# Style helper: paint the toggle to reflect on/off state.
function global:Update-CheckOnStartupVisualState {
    $on = [bool](Get-HubSetting -Key "checkOnStartup" -Default $false)
    if (-not $checkOnStartupBtn) { return }
    if ($on) {
        $checkOnStartupBtn.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0e4ade80")
        $checkOnStartupBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5aa880")
        $checkOnStartupCheck.Visibility = [System.Windows.Visibility]::Visible
        $checkOnStartupText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#aaccbb")
    } else {
        $checkOnStartupBtn.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#000000")
        $checkOnStartupBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0fffffff")
        $checkOnStartupCheck.Visibility = [System.Windows.Visibility]::Collapsed
        $checkOnStartupText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7e8a85")
    }
}
Update-CheckOnStartupVisualState

# Hover-reveal pattern: show the companion button when the
# mouse is over the Check Installed group. Hide it again with
# a delay so a quick mouse jiggle between the two buttons
# doesn't cause it to flicker shut.
$global:CheckHoverHideTimer = $null

function global:Show-CheckOnStartup {
    # A scan is running: keep the toggle hidden so it doesn't ride along while
    # the counter button lifts into the header.
    if ($global:ScanInProgress) {
        if ($checkOnStartupBtn) { $checkOnStartupBtn.Visibility = [System.Windows.Visibility]::Hidden }
        return
    }
    if ($global:CheckHoverHideTimer) {
        try { $global:CheckHoverHideTimer.Stop() } catch { }
        $global:CheckHoverHideTimer = $null
    }
    if ($checkOnStartupBtn) {
        $checkOnStartupBtn.Visibility = [System.Windows.Visibility]::Visible
    }
}

function global:Hide-CheckOnStartupSoon {
    if ($global:CheckHoverHideTimer) {
        try { $global:CheckHoverHideTimer.Stop() } catch { }
    }
    $global:CheckHoverHideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $global:CheckHoverHideTimer.Interval = [TimeSpan]::FromMilliseconds(450)
    $global:CheckHoverHideTimer.Add_Tick({
        $global:CheckHoverHideTimer.Stop()
        if ($checkOnStartupBtn) {
            # Hidden, not Collapsed - keeps the layout slot reserved
            # so the surrounding toolbar buttons don't shift by a few
            # pixels each time the reveal-button appears/disappears.
            $checkOnStartupBtn.Visibility = [System.Windows.Visibility]::Hidden
        }
    })
    $global:CheckHoverHideTimer.Start()
}

# Reveal trigger: ONLY the Check Installed button itself - not the whole
# hover group. The group has a transparent background so the VR Ready reveal
# survives the cursor crossing it, but that transparent area to the RIGHT of
# the button must NOT make the Check on Startup toggle appear. The toggle
# keeps itself visible on hover so the cursor can travel from the button
# onto it without it hiding.
$checkInstalledBtnEl = $window.FindName("CheckInstalledBtn")
if ($checkInstalledBtnEl) {
    $checkInstalledBtnEl.Add_MouseEnter({ Show-CheckOnStartup })
    $checkInstalledBtnEl.Add_MouseLeave({ Hide-CheckOnStartupSoon })
}
if ($checkOnStartupBtn) {
    $checkOnStartupBtn.Add_MouseEnter({ Show-CheckOnStartup })
    $checkOnStartupBtn.Add_MouseLeave({ Hide-CheckOnStartupSoon })
}

# Toggle the persisted flag on click and update visuals.
if ($checkOnStartupBtn) {
    $checkOnStartupBtn.Add_PreviewMouseLeftButtonDown({
        $cur = [bool](Get-HubSetting -Key "checkOnStartup" -Default $false)
        Set-HubSetting -Key "checkOnStartup" -Value (-not $cur)
        Update-CheckOnStartupVisualState
    })
}

# Auto-trigger Check Installed at startup if the user enabled it.
# We use the dispatcher to fire after the window is fully loaded
# and the click handler can reach all UI elements.
if ([bool](Get-HubSetting -Key "checkOnStartup" -Default $false)) {
    $window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{
        try {
            # Check on Startup is the ONLY update check most users ever
            # run, so it must check ONLINE - same as a manual click. The
            # circuit breaker (see Invoke-ScanWebGet) caps an unreachable
            # server at a single ~2s timeout and then falls back to disk
            # for the rest, so a slow/dead server can't freeze the scan.
            $global:HubScanOnlineDown = $false
            Invoke-CheckInstalledScan
        } catch { }
    }) | Out-Null
}

# Desktop shortcut: ensure one exists AND points at the current icon.
# There is deliberately no "already created" flag: the Hub simply writes
# the shortcut on every launch. That is idempotent, and it also picks up
# icon changes for users who already have one.
# ($scriptDir / $rootDir come from VRModHub.ps1 - do not redefine
# them here; $MyInvocation in a dot-sourced module points at the
# module file itself, not at the entry script.)
$icoPath    = Join-Path $scriptDir "VR Mod Hub.ico"
$batPath    = Join-Path $rootDir "Start PCVR Mods Hub.bat"
$lnkPath    = Join-Path ([Environment]::GetFolderPath("Desktop")) "VR Mods Hub.lnk"

try {
    $shell    = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($lnkPath)
    $shortcut.TargetPath       = $batPath
    $shortcut.WorkingDirectory = $scriptDir
    $shortcut.Description      = "PCVR Mods Installer Hub"
    if (Test-Path $icoPath) { $shortcut.IconLocation = $icoPath }
    $shortcut.Save()
} catch {}

# Tidy up after the retired flag: installs from older builds still carry
# a ".shortcut_created" file that nothing reads any more.
try {
    $oldFlag = Join-Path $scriptDir ".shortcut_created"
    if (Test-Path $oldFlag) { Remove-Item $oldFlag -Force -ErrorAction SilentlyContinue }
} catch {}

# Populate the Recently Played row on first paint. Test mode shows
# the first 5 installed games (pre-scan: first 5 catalog entries
# with artwork). Once Start-GameInVR tracks launches, this list
# will be replaced by actual play history.
Write-HubTiming "before Build-RecentlyPlayed"
if (Get-Command Build-RecentlyPlayed -ErrorAction SilentlyContinue) {
    Build-RecentlyPlayed
}
Write-HubTiming "after Build-RecentlyPlayed"

# Re-check state for the single game whose Steam button was just
# clicked. Mirrors the "scope-respecting" pattern of post-install
# auto-refresh: if the user already opted into a full scan
# (gameStateMap populated), refresh everything for coherence;
# otherwise only this one card. Probing every game on every
# alt-tab back to the Hub would be overreach when the user only
# pressed one button.
$window.Add_Activated({
    if (-not $global:LastSteamButtonClickAt) { return }
    # A scan is walking the cards right now (the window processes events
    # again between its yields, so this CAN fire mid-scan). The scan
    # re-detects every game from disk anyway - consume the markers and
    # stay out of its way instead of rebuilding lookups underneath it.
    if ($global:ScanInProgress) {
        $global:LastSteamButtonClickAt    = $null
        $global:LastSteamButtonClickTitle = $null
        return
    }
    $age = [DateTime]::UtcNow - $global:LastSteamButtonClickAt
    if ($age.TotalMinutes -gt 30) { return }

    $title = $global:LastSteamButtonClickTitle
    # Consume markers so this only fires once per click. Random
    # later alt-tabs don't re-trigger.
    $global:LastSteamButtonClickAt    = $null
    $global:LastSteamButtonClickTitle = $null

    $hadFullScan = [bool]$global:UserRanFullScan
    if ($hadFullScan) {
        # User already opted into global state - keep it coherent.
        try { Invoke-CheckInstalledScan } catch { }
        return
    }

    # Single-game refresh path. Find the catalog entry, run the
    # same detection heuristics the full scan would for that one
    # title, write a single entry into gameStateMap, repaint just
    # that card. No global scan.
    if (-not $title) { return }
    try {
        $game = $null
        foreach ($g in @($ownGames + $ownGamesGP + $externalGames)) {
            if ($g.Title -eq $title) { $game = $g; break }
        }
        if (-not $game) { return }

        # Resolve Steam libraries the same way the full scan does.
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

        # Test if game is installed: SteamFolder, then FallbackPaths
        # (only the STEAM:* prefix variant - GOG/absolute aren't
        # relevant for a Get-on-Steam click).
        $installed = $false
        $gameDir   = $null
        if ($game.SteamFolder) {
            foreach ($lib in $steamLibs) {
                $candidate = Join-Path $lib "steamapps\common\$($game.SteamFolder)"
                if (Test-Path $candidate) { $installed = $true; $gameDir = $candidate; break }
            }
        }
        if (-not $installed -and $game.FallbackPaths) {
            foreach ($fp in $game.FallbackPaths) {
                if ($fp -like "STEAM:*") {
                    $folderName = $fp.Substring("STEAM:".Length)
                    foreach ($lib in $steamLibs) {
                        $candidate = Join-Path $lib "steamapps\common\$folderName"
                        if (Test-Path $candidate) { $installed = $true; $gameDir = $candidate; break }
                    }
                    if ($installed) { break }
                }
            }
        }
        if (-not $installed) { return }

        # Test if VR mod is also present. Mirrors the full-scan
        # logic but only for the ModFile / VrInstallRoot paths -
        # we skip Luke Ross RealRepo recursion since it's slow
        # and unlikely after a fresh Steam install.
        $vrInstalled = $false
        if ($game.ModFile) {
            $modPath = Join-Path $gameDir $game.ModFile
            if (Test-Path $modPath) {
                $vrInstalled = $true
            } elseif ($game.VrInstallRoot) {
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
                $altPath = Join-Path $altRoot $game.ModFile
                if (Test-Path $altPath) {
                    $vrInstalled = $true
                    if ($game.VrInstallEvidence) {
                        foreach ($ev in $game.VrInstallEvidence) {
                            if (-not (Test-Path (Join-Path $altRoot $ev))) { $vrInstalled = $false; break }
                        }
                    }
                    # The staged files alone prove nothing: they outlive the
                    # game. Same shared check the full scan uses - without it
                    # a fresh Hub shows a stale "VR Ready" on the very first
                    # screen, before the full scan has had a chance to correct
                    # it (this map is what the tiles read).
                    if ($vrInstalled -and -not (Test-StagedModStillValid -Game $game -StageRoot $altRoot)) {
                        $vrInstalled = $false
                    }
                }
            }
        }

        $accentHex = if ($game.Accent) { $game.Accent } else { "#666677" }
        if ($vrInstalled) {
            $global:gameStateMap[$title] = @{
                Tag = "vrinstalled"; Accent = $accentHex; State = "ready"
                BtnText = "VR Ready"; GameDir = $gameDir
            }
        } else {
            $global:gameStateMap[$title] = @{
                Tag = "installed"; Accent = $accentHex; State = "installed"
                BtnText = "Install Mod"; GameDir = $gameDir
            }
        }

        # Repaint just this title's card. Rebuild-Lookups walks
        # every card and applies whatever's in gameStateMap; cards
        # without an entry get skipped, so this only touches the
        # one we just wrote.
        try { Rebuild-Lookups } catch {}

        # Re-render the open detail page if it's showing this game,
        # so the user sees the new state without leaving the page.
        try {
            if ($global:currentDetailGame -and $global:currentDetailGame.Title -eq $title -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
                Show-DiscoverDetail -Game $global:currentDetailGame
            }
        } catch {}
    } catch { }
})

# ---------------------------------------------------------------
# Proactive steam_appid.txt heal for all DepotInstall games.
# Walks every catalog entry marked DepotInstall = $true, resolves
# its install path via FallbackPaths, and writes steam_appid.txt
# next to the EXE if missing. Catches the case where an install
# predates the per-installer steam_appid.txt fix - those folders
# would otherwise trigger Steam's "install this game" dialog on
# every launch attempt. Silent / non-blocking: any failure is
# swallowed, the rest of Hub startup proceeds normally.
# ---------------------------------------------------------------
# steam_appid.txt proactive heal. This walks every depot-install game,
# resolves its folder via .installed_path / FallbackPaths, and drops a
# steam_appid.txt if missing (so depot launches don't trigger Steam's
# "install this game" dialog). It does a lot of disk Test-Path work and
# Steam-library resolution, so it MUST NOT run before the window is shown
# - doing so delayed window open by 6-8s. We hook it to ContentRendered,
# which fires AFTER the first paint (window already visible). The handler
# body runs in module scope, so $ownGames / $ownGamesGP are in reach with
# no closure juggling. Healing only needs to finish before a game launch,
# and the launch path writes steam_appid.txt itself as a final safety net.
# Dismiss the launcher splash the INSTANT the window is first painted - BEFORE
# the heavier ContentRendered work below (steam_appid heal, Explore prewarm).
# That work used to run first and the ready flag was only written in the LAST
# handler, so the splash lingered ~0.5-1s after the Hub was already visible.
# Registered before the others so it fires first; the flag write is a couple
# of bytes to %TEMP% and returns immediately.
$window.Add_ContentRendered({
    try { Set-Content -Path (Join-Path $env:TEMP "PCVRHub_ready.flag") -Value "1" -ErrorAction SilentlyContinue } catch { }
})

$window.Add_ContentRendered({
    try {
        $depotCatalog = @($ownGames + $ownGamesGP)
        foreach ($g in $depotCatalog) {
            if (-not $g.DepotInstall) { continue }
            if (-not $g.SteamId)      { continue }

            $healedPath = $null

            # Primary signal: .installed_path file written by the installer.
            # This is the ground truth - it points at the exact folder
            # where the game was placed, regardless of whether that's
            # in FallbackPaths or a custom drive/location.
            if (Get-Command Read-InstalledPath -ErrorAction SilentlyContinue) {
                try {
                    $recorded = Read-InstalledPath -Game $g
                    if ($recorded -and (Test-Path $recorded)) { $healedPath = $recorded }
                } catch {}
            }

            # Fallback: catalog FallbackPaths. STEAM: tokens are resolved
            # against every known Steam library.
            if (-not $healedPath -and $g.FallbackPaths) {
                $steamLibsLocal = $null
                foreach ($p in $g.FallbackPaths) {
                    $candidatePaths = @()
                    if ($p -like "STEAM:*") {
                        if ($null -eq $steamLibsLocal) {
                            $steamLibsLocal = @()
                            foreach ($rk in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam", "HKLM:\SOFTWARE\Valve\Steam", "HKCU:\SOFTWARE\Valve\Steam")) {
                                try {
                                    $sp = (Get-ItemProperty -Path $rk -ErrorAction Stop).InstallPath
                                    if ($sp -and (Test-Path $sp)) { $steamLibsLocal += $sp; break }
                                } catch {}
                            }
                            if ($steamLibsLocal.Count -gt 0) {
                                $vdf = Join-Path $steamLibsLocal[0] "steamapps\libraryfolders.vdf"
                                if (Test-Path $vdf) {
                                    [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
                                        $lib = $_.Groups[1].Value -replace '\\\\', '\'
                                        if ((Test-Path $lib) -and ($steamLibsLocal -notcontains $lib)) {
                                            $steamLibsLocal += $lib
                                        }
                                    }
                                }
                            }
                        }
                        $folder = $p.Substring("STEAM:".Length)
                        foreach ($lib in $steamLibsLocal) {
                            $candidatePaths += (Join-Path $lib "steamapps\common\$folder")
                        }
                    } else {
                        $candidatePaths += $p
                    }
                    foreach ($cp in $candidatePaths) {
                        if (Test-Path $cp) { $healedPath = $cp; break }
                    }
                    if ($healedPath) { break }
                }
            }

            if (-not $healedPath) { continue }

            # Drop steam_appid.txt unconditionally - the file is harmless
            # if the folder turns out not to be the right one, but missing
            # it breaks depot launches with Steam's install-this-game
            # dialog. Folder existence is signal enough.
            $appidFile = Join-Path $healedPath "steam_appid.txt"
            if (Test-Path $appidFile) { continue }   # Already healed
            try {
                Set-Content -Path $appidFile -Value $g.SteamId -Encoding ASCII -NoNewline -Force
            } catch { }
        }
        # Warm the on-disk image cache for any games whose art we haven't
        # saved yet. Runs in one decoupled background runspace. Deferred to
        # an ApplicationIdle tick so creating/starting the runspace (a brief
        # UI-thread cost - the mouse "busy" spinner) doesn't hold up the
        # first interactive frame; it happens once the UI is idle instead.
        # Capture the game list HERE (script-scoped collections are visible
        # in this handler) and close over it, so the deferred delegate
        # doesn't rely on script-scope visibility from its own context.
        if (Get-Command Start-ImageCacheWarm -ErrorAction SilentlyContinue) {
            $warmGames = @($ownGames + $ownGamesGP + $externalGames)
            $window.Dispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::ApplicationIdle,
                [action]{
                    try { Start-ImageCacheWarm -Games $warmGames } catch { }
                }.GetNewClosure()
            ) | Out-Null
        }
    } catch { }
})

# Restore the view the user last had open (mod list or library), the same
# way S/M/L is restored. This runs SYNCHRONOUSLY before ShowDialog: doing it
# on ApplicationIdle meant the window painted the mod list first and visibly
# flipped over a moment later.
if (Get-Command Get-HubSetting -ErrorAction SilentlyContinue) {
    $savedView = [string](Get-HubSetting -Key "startView" -Default "LIST")
    if ($savedView -eq "LIBRARY") {
        try {
            if (Get-Command Build-DiscoverTiles -ErrorAction SilentlyContinue) { Build-DiscoverTiles }
            if ($global:discoverDetail)   { $global:discoverDetail.Visibility   = [System.Windows.Visibility]::Collapsed }
            if ($global:discoverOverview) { $global:discoverOverview.Visibility = [System.Windows.Visibility]::Collapsed }
            if ($global:discoverTiles)    { $global:discoverTiles.Visibility    = [System.Windows.Visibility]::Visible }
            if ($global:discoverHost)     { $global:discoverHost.Visibility     = [System.Windows.Visibility]::Visible }
            if ($global:listScroll)       { $global:listScroll.Visibility       = [System.Windows.Visibility]::Collapsed }
            if (Get-Command Update-FilterBarForMode -ErrorAction SilentlyContinue) { Update-FilterBarForMode }
            if (Get-Command Update-DiscoverBtnState -ErrorAction SilentlyContinue) { Update-DiscoverBtnState }
            if (Get-Command Sync-ScaleButtonsToMode -ErrorAction SilentlyContinue) { Sync-ScaleButtonsToMode }
            if (Get-Command Apply-LibrarySize -ErrorAction SilentlyContinue)       { Apply-LibrarySize $global:LibrarySize }
            Write-HubTiming "start view restored: library"
        } catch { }
        # The install-status pass is the slow part - that one still happens
        # after the window is up, exactly like the mod list does it.
        $window.Dispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::ApplicationIdle,
            [action]{
                try { if (Get-Command Refresh-DiscoverStatuses -ErrorAction SilentlyContinue) { Refresh-DiscoverStatuses } } catch { }
            }.GetNewClosure()
        ) | Out-Null
    }
}

Write-HubTiming "before ShowDialog (window goes interactive next)"

# Persist window geometry on close. RestoreBounds gives the
# un-maximized rectangle even when the window is currently
# maximized - so the next start restores BOTH the user's
# preferred size/position AND the maximized state.
$window.Add_Closing({
    if (-not (Get-Command Set-HubSetting -ErrorAction SilentlyContinue)) { return }
    try {
        # PS 5.1 / .NET Framework 4.x lacks [double]::IsFinite -
        # use IsNaN + IsInfinity (present everywhere) for the
        # finite check on RestoreBounds values.
        function _isFiniteNum($v) {
            if ($null -eq $v) { return $false }
            try {
                $d = [double]$v
                return -not ([double]::IsNaN($d) -or [double]::IsInfinity($d))
            } catch { return $false }
        }

        $isMax = ($window.WindowState -eq [System.Windows.WindowState]::Maximized)
        # RestoreBounds gives the un-maximized rect even when the
        # window is currently maximized - so the next start
        # restores BOTH preferred size/position AND maximized state.
        $rect  = $window.RestoreBounds
        $w = $rect.Width;  $h = $rect.Height
        $l = $rect.X;      $t = $rect.Y
        if (-not (_isFiniteNum $w) -or $w -le 0) { $w = $window.ActualWidth }
        if (-not (_isFiniteNum $h) -or $h -le 0) { $h = $window.ActualHeight }
        if (-not (_isFiniteNum $l)) { $l = $window.Left }
        if (-not (_isFiniteNum $t)) { $t = $window.Top  }

        Set-HubSetting -Key "winMaximized" -Value ([string]$isMax)
        if ($w -gt 0) { Set-HubSetting -Key "winWidth"  -Value ([int]$w) }
        if ($h -gt 0) { Set-HubSetting -Key "winHeight" -Value ([int]$h) }
        if (_isFiniteNum $l) { Set-HubSetting -Key "winLeft" -Value ([int]$l) }
        if (_isFiniteNum $t) { Set-HubSetting -Key "winTop"  -Value ([int]$t) }
    } catch { }
})

# Bring the window to the foreground once it is first rendered. A
# normal launch (shortcut / double-click) inherits foreground rights
# from the launching process, but the post-update relaunch is started
# by a background PowerShell process that does NOT hold those rights -
# so Windows would leave the new window behind whatever was last active
# (typically the Explorer folder it was started from). Activate() alone
# is blocked by the foreground lock; the brief Topmost toggle is the
# reliable WPF way to lift the window above others without needing
# foreground rights, then drop it back to a normal z-order on top.
$window.Add_ContentRendered({
    try {
        if ($window.WindowState -eq [System.Windows.WindowState]::Minimized) {
            $window.WindowState = [System.Windows.WindowState]::Normal
        }
        [void]$window.Activate()
        $window.Topmost = $true
        $window.Topmost = $false
        [void]$window.Focus()
    } catch { }
})

# ---------------------------------------------------------------
# Live update-banner reveal. The update check runs DETACHED in the
# background (see Start PCVR Mods Hub.bat) so it never blocks the
# window - it writes the .update_available marker a few seconds after
# the Hub is already open. We poll for that marker AFTER the window is
# interactive and reveal the banner in-session the moment it appears,
# so the user gets a fully loaded, usable Hub immediately and the small
# banner at the top just lights up quietly once the check finishes.
# Reveal-only: never hides anything. Polling stops as soon as the banner
# is shown, or after ~60s (the check is normally done within a few
# seconds; the cap keeps a dead/slow network from polling forever).
# ---------------------------------------------------------------
$window.Add_ContentRendered({
    # A marker from a previous run already revealed the banner at
    # startup - nothing left to wait for.
    if ($global:UpdateBannerWired) { return }
    $global:UpdateProbeCount = 0
    $global:UpdateProbeTimer = New-Object System.Windows.Threading.DispatcherTimer
    $global:UpdateProbeTimer.Interval = [TimeSpan]::FromMilliseconds(1500)
    $global:UpdateProbeTimer.Add_Tick({
        $global:UpdateProbeCount++
        try {
            $markerFile = Join-Path $global:scriptDir ".update_available"
            if (Test-Path $markerFile) {
                # The updater writes this marker ONLY when a newer release
                # exists (it deletes a stale one when up to date), so its
                # presence alone means an update is available.
                $info = Get-Content $markerFile -Raw -ErrorAction Stop | ConvertFrom-Json
                if ($info -and $info.LatestVersion -and (Get-Command Show-UpdateBanner -ErrorAction SilentlyContinue)) {
                    Show-UpdateBanner -Info $info
                    $global:UpdateProbeTimer.Stop()
                    return
                }
            }
        } catch {
            # Marker may be mid-write; retry on the next tick.
        }
        if ($global:UpdateProbeCount -ge 40) { $global:UpdateProbeTimer.Stop() }
    })
    $global:UpdateProbeTimer.Start()
})

# ---------------------------------------------------------------
# Auto-rotate the two VR-mod-list banners (Steam portrait list +
# library tiles) so their featured game + effect changes during a
# session instead of staying fixed until restart. Fires on a random
# 5-15 minute interval, re-randomised each tick so the cadence never
# feels mechanical. The Explore banner is left out on purpose - it
# has its own Shuffle control.
# ---------------------------------------------------------------
$global:BannerRotateTimer = New-Object System.Windows.Threading.DispatcherTimer
$global:BannerRotateTimer.Interval = [TimeSpan]::FromMinutes((Get-Random -Minimum 5 -Maximum 16))
$global:BannerRotateTimer.Add_Tick({
    if (Get-Command Invoke-ListLibBannerRotation -ErrorAction SilentlyContinue) {
        try { Invoke-ListLibBannerRotation } catch { }
    }
    try { $global:BannerRotateTimer.Interval = [TimeSpan]::FromMinutes((Get-Random -Minimum 5 -Maximum 16)) } catch { }
})
$global:BannerRotateTimer.Start()

# ---------------------------------------------------------------
# Warm the Explore/Discover overview in the background once the Hub
# is open and idle. Building the genre rows the first time costs a
# few seconds (many tiles + Add_ handlers), so doing it lazily on the
# first Explore click makes that click stall. Instead we kick off
# Start-OverviewPrewarm at Background priority right after the window
# is interactive; it builds the rows incrementally (one tile per
# dispatcher cycle) so the banner animations keep rendering between
# steps (no multi-second freeze, no per-row stutter), and the first
# Explore switch is instant. Idempotent + safe:
# if the user opens Explore before the prewarm finishes,
# Build-DiscoverOverview takes over synchronously and the remaining
# prewarm steps bail via the $global:OverviewBuilt guard - no double
# build, no duplicate rows. Background priority yields to input/render,
# so it never delays window open. Building into the still-collapsed
# overview subtree does not change what is on screen.
# ---------------------------------------------------------------
$window.Add_ContentRendered({
    if ($global:OverviewBuilt) { return }
    $window.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [action]{
            try {
                if (-not $global:OverviewBuilt -and (Get-Command Start-OverviewPrewarm -ErrorAction SilentlyContinue)) {
                    Start-OverviewPrewarm
                }
            } catch { }
        }
    ) | Out-Null
})

# Signal the launcher splash that the window is up, and record the real
# load time for the next launch's progress estimate. Best-effort; written
# to %TEMP% only (never the Hub folder - ship-guard).
$window.Add_ContentRendered({
    try {
        Set-Content -Path (Join-Path $env:TEMP "PCVRHub_ready.flag") -Value "1" -ErrorAction SilentlyContinue
        if ($global:HubLoadStart) {
            $secs = ([DateTime]::UtcNow - $global:HubLoadStart).TotalSeconds
            if ($secs -gt 0.5 -and $secs -lt 60) {
                Set-Content -Path (Join-Path $env:TEMP "PCVRHub_lastload.txt") -Value ([string]([Math]::Round($secs, 2))) -ErrorAction SilentlyContinue
            }
        }
    } catch { }
})

# ------------------------------------------------------------
# Crash guard
# ------------------------------------------------------------
# WPF kills the whole process on ANY unhandled exception raised on the
# UI thread - a throw inside a DispatcherTimer tick or a click handler
# makes the window disappear with no message, which users report as
# "the hub just closed and crashed". Handling it here turns that into a
# dismissible notice plus a log line, and keeps the Hub running. This is
# a safety net, not a licence to skip try/catch at the call sites.
try {
    $dispatcherObj = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    $dispatcherObj.Add_UnhandledException({
        param($src, $ev)
        $ev.Handled = $true
        $msg = ""
        try { $msg = [string]$ev.Exception.Message } catch {}
        try {
            $logDir = Join-Path $global:scriptDir "Logs"
            if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
            $stamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            $trace = ""
            try { $trace = [string]$ev.Exception.ToString() } catch {}
            Add-Content -Path (Join-Path $logDir "hub-errors.log") -Value "[$stamp] $trace`r`n" -ErrorAction SilentlyContinue
        } catch {}
        try {
            [System.Windows.MessageBox]::Show(
                ("Something went wrong, but the Hub is still running." + [Environment]::NewLine + [Environment]::NewLine +
                 $msg + [Environment]::NewLine + [Environment]::NewLine +
                 "Details were written to Logs\hub-errors.log."),
                "Unexpected error",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning) | Out-Null
        } catch {}
    })
} catch {}

$window.ShowDialog() | Out-Null
