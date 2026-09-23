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

# Single reader for the persisted flag - used by the toggle, its visual
# state and the startup scan, so all three can never disagree.
#
# WHY NOT A PLAIN [bool] CAST: [bool]"False" is TRUE in PowerShell (any
# non-empty string is true). If the value ever ends up in the JSON as a
# STRING instead of a real boolean, a plain cast makes the setting
# impossible to switch off - it reads "on" forever, no matter how often
# the user clicks it. This reader takes the stored text at face value.
function global:Get-CheckOnStartupFlag {
    $raw = Get-HubSetting -Key "checkOnStartup" -Default $false
    if ($null -eq $raw) { return $false }
    if ($raw -is [bool]) { return [bool]$raw }
    $s = ([string]$raw).Trim()
    if ($s -match '^(?i)(false|0|no|off)$') { return $false }
    if ($s -match '^(?i)(true|1|yes|on)$')  { return $true }
    return [bool]$raw
}

# Style helper: paint the toggle to reflect on/off state.
function global:Update-CheckOnStartupVisualState {
    $on = Get-CheckOnStartupFlag
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
        $cur = Get-CheckOnStartupFlag
        # Write a REAL boolean (not a string) so the JSON holds
        # true/false and the reader above never has to guess.
        Set-HubSetting -Key "checkOnStartup" -Value ([bool](-not $cur))
        Update-CheckOnStartupVisualState
    })
}

# Check on Startup: the scan now runs PRE-PAINT, shortly before
# ShowDialog - see the block right above the ShowDialog timing marker
# at the end of this file. Nothing to wire up here any more.

# Desktop shortcut: ensure one exists AND points at the current icon.
# There is deliberately no "already created" flag - the Hub rewrites it
# on every launch, which is idempotent and also picks up icon changes.
# The one thing that DOES stop it is the user's own opt-out: the
# "Desktop Shortcut" item in the 3-dots menu writes desktopShortcut=false
# into the durable Hub state, and then nothing is recreated here, so a
# shortcut the user deleted stays deleted. Both the flag reader and the
# writer live in Helpers.ps1 so the menu handler can reuse them.
if ((Get-Command Get-HubShortcutFlag -ErrorAction SilentlyContinue) -and
    (Get-HubShortcutFlag)) {
    [void](Set-HubDesktopShortcut -Enabled $true)
}

# Tidy up after the retired flag: installs from older builds still carry
# a ".shortcut_created" file that nothing reads any more.
try {
    $oldFlag = Join-Path $scriptDir ".shortcut_created"
    if (Test-Path $oldFlag) { Remove-Item $oldFlag -Force -ErrorAction SilentlyContinue }
} catch {}

# Populate the real Recently Played history before first paint. A cold start
# deliberately shows saved launches before any optional installed-games scan;
# the scan later removes entries whose VR mod is no longer available.
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
        try { Invoke-CheckInstalledScan } catch { Fail-InstalledScan -ErrorRecord $_ -Quiet }
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

        # Shared per-session Steam discovery: no repeated registry exceptions
        # when this focused refresh follows a store button click.
        $steamLibs = if (Get-Command Get-HubSteamLibraries -ErrorAction SilentlyContinue) {
            @(Get-HubSteamLibraries)
        } else { @() }

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
        # A surviving steamapps folder is not a surviving game. Steam removes
        # its own executable on uninstall but intentionally leaves VR-mod files
        # behind; the focused refresh must apply the same executable/original-
        # file contract as the full scan before it can paint Installed or Ready.
        if ($installed -and -not (Test-BaseGameInstallProof -Game $game -Root $gameDir)) {
            $installed = $false
            $gameDir = $null
        }
        if (-not $installed) {
            if ($global:gameStateMap.ContainsKey($title)) { $global:gameStateMap.Remove($title) | Out-Null }
            try { Rebuild-Lookups } catch {}
            try { if (Get-Command Refresh-DiscoverStatuses -ErrorAction SilentlyContinue) { Refresh-DiscoverStatuses } } catch {}
            return
        }

        # Test if VR mod is also present. Mirrors the full-scan
        # logic but only for the ModFile / VrInstallRoot paths -
        # we skip Luke Ross RealRepo recursion since it's slow
        # and unlikely after a fresh Steam install.
        $vrInstalled = $false
        if ($game.ModFile) {
            $vrEvidenceRoot = $gameDir
            # A mod may have more than one legitimate on-disk marker. Halo
            # MCC, for example, uses HaloMCCVR.dll in the prerelease channel
            # and halo3xr.dll in Latest/Stable. The full scan already accepts
            # all three catalog marker fields; startup must reach the same
            # verdict or a correctly installed channel disappears on launch.
            if (Test-RelativePathMarker -Root $gameDir -Values @($game.ModFile, $game.ModFileAlt, $game.ModFileAlt2)) {
                $vrInstalled = $true
            } elseif ($game.DoorstopTargetModFile -and (Test-DoorstopTargetModMarker -GameRoot $gameDir -TargetMarker $game.DoorstopTargetModFile -LoaderFile $game.DoorstopLoaderFile)) {
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
                if (Test-RelativePathMarker -Root $altRoot -Values @($game.ModFile, $game.ModFileAlt, $game.ModFileAlt2)) {
                    $vrInstalled = $true
                    $vrEvidenceRoot = $altRoot
                    if (-not (Test-VrInstallEvidenceContract -Game $game -Root $altRoot)) { $vrInstalled = $false }
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
            if ($vrInstalled -and -not (Test-VrInstallEvidenceContract -Game $game -Root $vrEvidenceRoot)) {
                $vrInstalled = $false
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

# Complete the visible hand-off as one ordered event: restore the window,
# activate it, then and only then tell the launcher splash to close. The old
# split handlers wrote the ready flag before a later disk-heavy depot pass and
# before foreground activation, which could leave a blank desktop gap.
$global:HubStartupTransitionComplete = $false
$window.Add_ContentRendered({
    if ($global:HubStartupTransitionComplete) { return }
    $global:HubStartupTransitionComplete = $true

    try {
        if ($window.WindowState -eq [System.Windows.WindowState]::Minimized) {
            $window.WindowState = [System.Windows.WindowState]::Normal
        }
        [void]$window.Activate()
        $window.Topmost = $true
        $window.Topmost = $false
        [void]$window.Focus()
    } catch { }

    $startupTemp = [string]$env:TEMP
    if ([string]::IsNullOrWhiteSpace($startupTemp)) {
        try { $startupTemp = [IO.Path]::GetTempPath() } catch { $startupTemp = $PSScriptRoot }
    }
    try {
        if ($global:HubLoadStart) {
            $secs = ([DateTime]::UtcNow - $global:HubLoadStart).TotalSeconds
            if ($secs -gt 0.5 -and $secs -lt 300) {
                Set-Content -Path (Join-Path $startupTemp "PCVRHub_lastload.txt") -Value ([string]([Math]::Round($secs, 2))) -ErrorAction SilentlyContinue
            }
        }
    } catch { }
    try {
        Set-Content -Path (Join-Path $startupTemp "PCVRHub_ready.flag") -Value "1" -ErrorAction SilentlyContinue
        Write-HubTiming "window activated; launcher ready signal written"
    } catch { }
})

# Pre-build the Steam-style portrait library only after the first window
# paint. Build-DiscoverTiles itself yields between small batches, so this
# warms the hidden alternate view without moving the old five-second cost
# into startup or blocking interaction. A very fast user switch simply sees
# the remaining tiles appear progressively while the same queue continues.
$window.Add_ContentRendered({
    if ($global:DiscoverLibraryWarmScheduled) { return }
    $global:DiscoverLibraryWarmScheduled = $true
    $window.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::ApplicationIdle,
        [Action]{ try { if (Get-Command Build-DiscoverTiles -ErrorAction SilentlyContinue) { Build-DiscoverTiles } } catch { } }
    ) | Out-Null
})

# Check on Startup must not turn application startup into a 20-25 second
# blocking operation. The window/launcher hand-off above completes first; the
# opted-in scan then starts on the dispatcher and uses its normal UI-pump path,
# so status fills in while the already-open Hub remains responsive.
$window.Add_ContentRendered({
    if ($global:StartupInstalledScanScheduled -or -not (Get-CheckOnStartupFlag)) { return }
    $global:StartupInstalledScanScheduled = $true
    $window.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [action]{
            Write-HubTiming "before startup scan (post-paint)"
            if (-not ($global:ScanInProgress -or $global:ScanQueued)) {
                $global:HubScanOnlineDown = $false
                $global:HubThunderstoreOnlineDown = $false
                try { Invoke-CheckInstalledScan }
                catch { Fail-InstalledScan -ErrorRecord $_ -Quiet }
                try { if (Get-Command Refresh-DiscoverStatuses -ErrorAction SilentlyContinue) { Refresh-DiscoverStatuses } } catch { }
            }
            Write-HubTiming "after startup scan (post-paint)"
        }.GetNewClosure()
    ) | Out-Null
})

# ---------------------------------------------------------------
# Proactive steam_appid.txt heal for DepotInstall games. This is recovery
# for older Hub depots; each installer and launch route still writes the file
# itself. Process one catalog entry per low-priority dispatcher turn so the
# newly visible Hub remains responsive and the work cannot delay the splash
# hand-off or foreground activation.
# ---------------------------------------------------------------
function global:Invoke-StartupDepotHealStep {
    try {
        $queue = $global:StartupDepotHealQueue
        $dispatcher = $global:StartupDepotHealDispatcher
        if ($null -eq $queue -or $queue.Count -eq 0) {
            if (-not $global:StartupImageWarmScheduled -and (Get-Command Start-ImageCacheWarm -ErrorAction SilentlyContinue)) {
                $global:StartupImageWarmScheduled = $true
                $dispatcher.BeginInvoke(
                    [System.Windows.Threading.DispatcherPriority]::ApplicationIdle,
                    [action]{
                        try { Start-ImageCacheWarm -Games @($global:StartupImageWarmGames) } catch { }
                    }
                ) | Out-Null
            }
            return
        }

        $g = $queue.Dequeue()
        try {
            $healedPath = $null

            if (Get-Command Read-InstalledPath -ErrorAction SilentlyContinue) {
                try {
                    $recorded = Read-InstalledPath -Game $g
                    if ($recorded -and (Test-Path $recorded)) { $healedPath = $recorded }
                } catch {}
            }

            if (-not $healedPath -and $g.FallbackPaths) {
                foreach ($p in $g.FallbackPaths) {
                    $candidatePaths = @()
                    if ($p -like "STEAM:*") {
                        if (-not $global:StartupDepotSteamLibrariesReady) {
                            $global:StartupDepotSteamLibrariesReady = $true
                            $global:StartupDepotSteamLibraries = if (Get-Command Get-HubSteamLibraries -ErrorAction SilentlyContinue) {
                                @(Get-HubSteamLibraries)
                            } else { @() }
                        }
                        $folder = $p.Substring("STEAM:".Length)
                        foreach ($lib in @($global:StartupDepotSteamLibraries)) {
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

            if ($healedPath) {
                $appidFile = Join-Path $healedPath "steam_appid.txt"
                if (-not (Test-Path -LiteralPath $appidFile -PathType Leaf)) {
                    Set-Content -LiteralPath $appidFile -Value $g.SteamId -Encoding ASCII -NoNewline -Force -ErrorAction Stop
                }
            }
        } catch { }

        $dispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [action]{ Invoke-StartupDepotHealStep }
        ) | Out-Null
    } catch { }
}

$window.Add_ContentRendered({
    if ($global:StartupDepotHealScheduled) { return }
    $global:StartupDepotHealScheduled = $true
    $global:StartupDepotHealDispatcher = $window.Dispatcher
    $global:StartupDepotSteamLibrariesReady = $false
    $global:StartupDepotSteamLibraries = @()
    $global:StartupImageWarmScheduled = $false
    $global:StartupImageWarmGames = @($ownGames + $ownGamesGP + $externalGames)
    $global:StartupDepotHealQueue = New-Object System.Collections.Queue
    foreach ($g in @($ownGames + $ownGamesGP)) {
        if ($g.DepotInstall -and $g.SteamId) { $global:StartupDepotHealQueue.Enqueue($g) }
    }
    $window.Dispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [action]{ Invoke-StartupDepotHealStep }
    ) | Out-Null
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

# Log the persisted choice before ShowDialog, but never execute the scan here:
# doing so made an optional library refresh part of application startup.
Write-HubTiming ("checkOnStartup resolved to: {0}" -f (Get-CheckOnStartupFlag))

# Permanently hidden modders (settings key "hiddenModders") only took effect
# once the user typed something: the library is built with every tile visible
# and Apply-Filter never ran at startup. Run it once here - and ONLY when the
# list is non-empty, so a normal start does exactly what it always did.
try {
    if ($global:HiddenModders -and $global:HiddenModders.Count -gt 0) {
        Write-HubTiming ("applying hiddenModders ({0})" -f $global:HiddenModders.Count)
        if (Get-Command Apply-Filter -ErrorAction SilentlyContinue) { Apply-Filter }
    }
} catch { }

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
            $markerFile = Get-HubUpdateInfoPath
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
            $logDir = Get-HubRuntimeLogsRoot
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
                 "Open Help & Feedback > Logs & report a problem for the full report."),
                "Unexpected error",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning) | Out-Null
        } catch {}
    })
} catch {}

$window.ShowDialog() | Out-Null

# End the transcript while the WPF host is still in a normal script frame.
# Letting PowerShell tear an active transcript down together with the closed
# dispatcher can append a content-free `TerminatingError(): System error.` to
# an otherwise clean log. This is lifecycle cleanup, not error filtering:
# every exception that occurred while the Hub was running remains recorded.
if ($script:HubTranscriptStarted) {
    try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch {}
    $script:HubTranscriptStarted = $false
    try { Compress-HubSessionLog -Path $hubLog } catch {}
}
