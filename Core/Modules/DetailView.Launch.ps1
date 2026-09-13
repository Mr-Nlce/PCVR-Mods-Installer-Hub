# Return the dedicated Hub launcher only when a legacy Locate Game value is
# provably the base-game EXE in the same recorded folder.  Older Hub builds
# stored that EXE even for titles whose installer later created a required VR
# launcher.  Exact path equality keeps genuine custom-store overrides intact.
function global:Get-ReplacementForObsoleteBaseLaunchOverride {
    param($Game,[string]$InstalledRoot,[string]$LaunchOverride)
    if (-not $Game -or -not $InstalledRoot -or -not $LaunchOverride -or
        -not $Game.GameExe -or -not $Game.LaunchExe -or
        ([string]$Game.GameExe).Equals([string]$Game.LaunchExe,[StringComparison]::OrdinalIgnoreCase)) { return $null }
    try {
        $root = [IO.Path]::GetFullPath($InstalledRoot).TrimEnd([char[]]'\/')
        $saved = [IO.Path]::GetFullPath($LaunchOverride).TrimEnd([char[]]'\/')
        $baseGame = [IO.Path]::GetFullPath((Join-Path $root ([string]$Game.GameExe))).TrimEnd([char[]]'\/')
        $dedicated = [IO.Path]::GetFullPath((Join-Path $root ([string]$Game.LaunchExe))).TrimEnd([char[]]'\/')
        if ($saved.Equals($baseGame,[StringComparison]::OrdinalIgnoreCase) -and
            (Test-Path -LiteralPath $dedicated -PathType Leaf)) { return $dedicated }
    } catch {}
    return $null
}

# Launch a VR-installed game using the most reliable method we
# have for it. Priority:
#   1. LaunchExe with optional LaunchArgs, run from the detected
#      install folder (gameDir from the last Check Installed scan).
#      Used for depot-installed games that need specific launch
#      parameters (Gunfire's -vrmode OpenVR, BMS's MO2 profile).
#   2. Fall back to Steam if SteamId is set - works for the
#      majority of native VR mods (REFramework, UEVR, Luke Ross
#      etc.) that auto-inject when the game starts.
#   3. If neither route is valid, report the launch failure. A Play
#      action never opens an installer or web page as a fallback.
function global:Start-GameInVR {
    param(
        $Game,
        # For DualMode games (REPO VR, CW VR): "Current" launches the
        # Thunderstore mod inside the Steam library via the regular
        # Steam protocol; "Depot" launches the pinned legacy install
        # directly from C:\Games\<Name> VR\ with DepotLaunchArgs.
        # Unset = use normal priority-chain detection (default).
        [string]$Mode = $null
    )

    # Track this launch in the play history FIRST, before any launch path
    # returns. Most-recent-first ringbuffer (max 8). A game permanently
    # hidden from its Recently Played tile is deliberately not re-added.
    # Tests use an isolated state root, so production history is untouched.
    if ($Game -and $Game.Title) {
        try {
            $gameId = Get-HubGameStateId -Game $Game
            $historyChanged = Add-HubRecentlyPlayedGame -Title $Game.Title -GameId $gameId
            # Rebuild the Recently Played row so the launch becomes
            # visible immediately, without waiting for a Hub restart.
            if ($historyChanged -and (Get-Command Build-RecentlyPlayed -ErrorAction SilentlyContinue)) {
                try { Build-RecentlyPlayed } catch { }
            }
        } catch { }
    }

    # The Elden Ring motion entry never executes its historical common
    # launcher. Older copies of that file contain a console choice between
    # Hotbite and ERVR. Even a generic Current/Depot launch is kept inside
    # the Hub: try the installed payloads directly and otherwise point back
    # to the two explicit Play buttons.
    if ($Game.EldenRingDirectMotionLaunch -and $Mode -in @('Current','Depot')) {
        $erState = $global:gameStateMap[$Game.Title]
        $erRoot = if ($Mode -eq 'Depot') {
            if ($erState -and $erState.DepotDir) { [string]$erState.DepotDir } else { [string]$Game.DepotPath }
        } else {
            if ($erState -and $erState.CurrentDir) { [string]$erState.CurrentDir } else { [string]$erState.GameDir }
        }
        foreach ($erKind in @('Hotbite','ERVR')) {
            if ($erRoot -and (Invoke-EldenRingDirectMotionLaunch -Kind $erKind -GameDir $erRoot)) {
                try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized } } catch {}
                return
            }
        }
        try { [void](Show-EldenRingSaveMessage -Text 'Use Play Hotbite or Play ERVR on this page. The Hub will not reopen the obsolete console chooser.' -Title 'Choose the Elden Ring VR mod' -Icon Information) } catch {}
        return
    }

    # A single installed PEAK variant still uses the ordinary card click.
    # Resolve it here once for every surface (card and detail page): prefer
    # the recommended 2.1.a depot when no current copy is present, and fall
    # back to the legacy depot only when it is the sole detected choice.
    if (-not $Mode -and $Game.DualMode) {
        $autoState = $global:gameStateMap[$Game.Title]
        if ($autoState -and $autoState.DepotPresent -and -not $autoState.CurrentPresent) {
            $Mode = "Depot"
        } elseif ($Game.LegacyDepotLaunchExe -and (-not $autoState -or (-not $autoState.CurrentPresent -and -not $autoState.DepotPresent))) {
            foreach ($cand in (Get-LegacyDepotCandidatePaths -Game $Game)) {
                if ((Test-Path -LiteralPath (Join-Path $cand $Game.LegacyDepotLaunchExe) -PathType Leaf) -and
                    ($Game.LegacyDepotModFile -and (Test-Path -LiteralPath (Join-Path $cand $Game.LegacyDepotModFile) -PathType Leaf))) {
                    $Mode = "LegacyDepot"; break
                }
            }
        }
    }

    # A breaking-update title may retain its original depot as a third,
    # detail-page-only choice. It deliberately stays outside DualMode:
    # the normal Depot half is reserved for the last confirmed snapshot.
    if ($Mode -eq "LegacyDepot" -and $Game.LegacyDepotLaunchExe) {
        $legacyRoot = $null
        $legacyExe = $null
        foreach ($cand in (Get-LegacyDepotCandidatePaths -Game $Game)) {
            if (-not $cand) { continue }
            $tryExe = Join-Path $cand $Game.LegacyDepotLaunchExe
            $markerOK = $true
            if ($Game.LegacyDepotModFile) { $markerOK = Test-Path -LiteralPath (Join-Path $cand $Game.LegacyDepotModFile) -PathType Leaf }
            if ((Test-Path -LiteralPath $tryExe -PathType Leaf) -and $markerOK) {
                $legacyRoot = $cand; $legacyExe = $tryExe; break
            }
        }
        if ($legacyExe) {
            if ($Game.SteamId) {
                try { Set-Content -LiteralPath (Join-Path $legacyRoot "steam_appid.txt") -Value $Game.SteamId -Encoding ASCII -NoNewline -Force } catch {}
            }
            try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized } } catch {}
            try {
                if ($Game.LegacyDepotLaunchArgs) {
                    Start-Process -FilePath $legacyExe -ArgumentList $Game.LegacyDepotLaunchArgs -WorkingDirectory $legacyRoot
                } else {
                    Start-Process -FilePath $legacyExe -WorkingDirectory $legacyRoot
                }
            } catch {}
            return
        }
        $legacyName = if ($Game.LegacyDepotButtonLabel) { [string]$Game.LegacyDepotButtonLabel } else { 'Legacy depot' }
        try { [System.Windows.Forms.MessageBox]::Show("The $legacyName copy of $($Game.Title) is no longer present. Run the installer and choose the original legacy option again.", "$($Game.Title) legacy depot") | Out-Null } catch {}
        return
    }

    # DualMode shortcut: when the caller explicitly picks a variant,
    # bypass the priority chain and launch the requested variant
    # directly. This keeps the dual-button hover behaviour simple -
    # the click handlers pass "Current" or "Depot" and we route
    # straight to the matching launch path.
    if ($Mode -and $Game.DualMode) {
        $state = $global:gameStateMap[$Game.Title]
        if ($Mode -eq "Depot" -and $Game.DepotPath -and $Game.DepotLaunchExe) {
            # The user may pick the depot folder freely; the installer
            # records the chosen one. Catalog path first, then the
            # recorded one - otherwise the button launches into nothing.
            $depotRoot = $Game.DepotPath
            $depotExe  = [System.IO.Path]::Combine(([string]$depotRoot).TrimEnd([char[]]"\/"), ([string]$Game.DepotLaunchExe).TrimStart([char[]]"\/"))
            if (-not (Test-Path $depotExe)) {
                foreach ($cand in (Get-DepotCandidatePaths -Game $Game)) {
                    $try = [System.IO.Path]::Combine(([string]$cand).TrimEnd([char[]]"\/"), ([string]$Game.DepotLaunchExe).TrimStart([char[]]"\/"))
                    if (Test-Path $try) { $depotRoot = $cand; $depotExe = $try; break }
                }
            }
            if (Test-Path $depotExe) {
                # steam_appid.txt safety net (same as the normal path)
                if ($Game.SteamId) {
                    $appidRelative = if ($Game.DepotSteamAppIdFile) { [string]$Game.DepotSteamAppIdFile } else { 'steam_appid.txt' }
                    $appidFile = [System.IO.Path]::Combine(([string]$depotRoot).TrimEnd([char[]]"\/"), $appidRelative.TrimStart([char[]]"\/"))
                    if (-not (Test-Path $appidFile)) {
                        try { Set-Content -Path $appidFile -Value $Game.SteamId -Encoding ASCII -NoNewline -Force } catch { }
                    }
                }
                $depotWorkingDirectory = $depotRoot
                if ($Game.DepotWorkingDirectory) {
                    $workingCandidate = [System.IO.Path]::Combine(([string]$depotRoot).TrimEnd([char[]]"\/"), ([string]$Game.DepotWorkingDirectory).TrimStart([char[]]"\/"))
                    if (Test-Path -LiteralPath $workingCandidate -PathType Container) { $depotWorkingDirectory = $workingCandidate }
                }
                try {
                    if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized }
                } catch { }
                try {
                    if ($Game.DepotLaunchArgs) {
                        Start-Process -FilePath $depotExe -ArgumentList $Game.DepotLaunchArgs -WorkingDirectory $depotWorkingDirectory
                    } else {
                        Start-Process -FilePath $depotExe -WorkingDirectory $depotWorkingDirectory
                    }
                } catch { }
                return
            }
        }
        if ($Mode -eq "Current" -and $Game.CurrentLaunchExe) {
            # Some current-build variants need their own offline/mod launcher
            # rather than steam:// (Elden Ring would otherwise start EAC and
            # bypass the selected VR route). The scan records the exact Steam
            # root in CurrentDir when both variants are present.
            $currentRoot = if ($state -and $state.CurrentDir) { [string]$state.CurrentDir } else { $null }
            if ($currentRoot) {
                $currentExe = Join-Path $currentRoot $Game.CurrentLaunchExe
                if (Test-Path -LiteralPath $currentExe) {
                    try {
                        if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized }
                    } catch { }
                    try {
                        if ($Game.CurrentLaunchArgs) {
                            Start-Process -FilePath $currentExe -ArgumentList $Game.CurrentLaunchArgs -WorkingDirectory $currentRoot
                        } else {
                            Start-Process -FilePath $currentExe -WorkingDirectory $currentRoot
                        }
                    } catch { }
                    return
                }
            }
        }
        if ($Mode -eq "Current" -and $Game.SteamId) {
            try {
                if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized }
            } catch { }
            try { Start-Process "steam://rungameid/$($Game.SteamId)" } catch { }
            return
        }
    }

    # TwoMods routing (separate from DualMode): launch one of the two
    # alternative VR mods from its subfolder under the .installed_path
    # parent. The detail-page split passes -Mode "ModA"/"ModB"; a plain
    # Start in VR (no Mode) launches whichever single mod is present, or
    # falls back to mod A when both exist.
    if ($Game.TwoMods) {
        # WHERE TO LOOK. Read-InstalledPath alone is NOT enough: that
        # marker lives in the HUB folder, so a freshly unpacked Hub has
        # none even though both mods sit in the game folder - and this
        # function would then find no launcher and open the INSTALLER
        # instead of starting the game. So: the recorded path first
        # (precise), then the folder the scan already resolved for this
        # title, then the game folder each mod's launcher was found in.
        $tmParent = $null
        try { $tmParent = Read-InstalledPath -Game $Game } catch { }
        $tmState = $global:gameStateMap[$Game.Title]
        if ((-not $tmParent) -and $tmState -and $tmState.GameDir) {
            try { if (Test-Path -LiteralPath $tmState.GameDir) { $tmParent = $tmState.GameDir } } catch { }
        }
        # Elden Ring used to fall back to a shared batch file which asked
        # Hotbite or ERVR AGAIN in a console. The split-button click already
        # made that choice. Launch its real payload directly, including old
        # installations which never received the dedicated launchers.
        if ($Game.EldenRingDirectMotionLaunch -and ($Mode -in @('ModA','ModB') -or -not $Mode)) {
            $kind = if ($Mode -eq 'ModB' -or (-not $Mode -and $tmState -and -not $tmState.ModAPresent -and $tmState.ModBPresent)) { 'ERVR' } else { 'Hotbite' }
            $preferred = if ($Mode -eq 'ModA' -and $tmState -and $tmState.ModARoot) { [string]$tmState.ModARoot }
                         elseif ($Mode -eq 'ModB' -and $tmState -and $tmState.ModBRoot) { [string]$tmState.ModBRoot }
                         else { [string]$tmParent }
            $directRoots = @($preferred)
            if ($tmState) { $directRoots += @($tmState.GameDir, $tmState.CurrentDir, $tmState.DepotDir) }
            foreach ($directRoot in @($directRoots | Where-Object { $_ } | Select-Object -Unique)) {
                if (Invoke-EldenRingDirectMotionLaunch -Kind $kind -GameDir ([string]$directRoot)) {
                    try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized } } catch { }
                    return
                }
            }
        }
        # Resolve every declared mod slot, not just A/B. Each launcher is
        # searched recursively below its isolated subfolder so wrapped ZIPs
        # remain usable. The scan's exact directory is the final authority.
        $tmPaths = @{}
        $tmDefinitions = @(Get-AlternativeModDefinitions -Game $Game -State $tmState)
        foreach ($definition in $tmDefinitions) {
            $candidateRoot = if ($definition.Root) { [string]$definition.Root } else { [string]$tmParent }
            $candidatePath = $null
            if ($candidateRoot -and (Test-Path -LiteralPath $candidateRoot -PathType Container) -and $definition.Sub -and ($definition.Launch -or $definition.LaunchAlt)) {
                $sub = Join-Path $candidateRoot ([string]$definition.Sub)
                if (Test-Path -LiteralPath $sub -PathType Container) {
                    foreach ($launchName in @(@($definition.Launch,$definition.LaunchAlt) | Where-Object { $_ })) {
                        $hit = Get-ChildItem -LiteralPath $sub -Filter ([string]$launchName) -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($hit) { $candidatePath = $hit.FullName; break }
                    }
                }
            }
            if (-not $candidatePath -and $definition.RootLaunch -and $candidateRoot -and ($definition.Launch -or $definition.LaunchAlt)) {
                foreach ($launchName in @(@($definition.Launch,$definition.LaunchAlt) | Where-Object { $_ })) {
                    $rootLaunch = Join-Path $candidateRoot ([string]$launchName)
                    if (Test-Path -LiteralPath $rootLaunch -PathType Leaf) { $candidatePath = $rootLaunch; break }
                }
            }
            if (-not $candidatePath -and $definition.Dir -and ($definition.Launch -or $definition.LaunchAlt)) {
                foreach ($launchName in @(@($definition.Launch,$definition.LaunchAlt) | Where-Object { $_ })) {
                    $scanned = Join-Path ([string]$definition.Dir) ([string]$launchName)
                    if (Test-Path -LiteralPath $scanned -PathType Leaf) { $candidatePath = $scanned; break }
                }
            }
            if ($candidatePath) { $tmPaths[[string]$definition.Mode] = $candidatePath }
        }
        $tmPick = $null
        if ($Mode -and $tmPaths.ContainsKey([string]$Mode)) {
            $tmPick = [string]$tmPaths[[string]$Mode]
        } elseif (-not $Mode) {
            foreach ($definition in $tmDefinitions) {
                if ($tmPaths.ContainsKey([string]$definition.Mode)) { $tmPick = [string]$tmPaths[[string]$definition.Mode]; break }
            }
        }
        if ($tmPick) {
            try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized } } catch { }
            try {
                Start-Process -FilePath $tmPick -WorkingDirectory (Split-Path -Parent $tmPick) -ErrorAction Stop
            } catch {
                Write-HubActionFailure -Action ("Start " + $Game.Title + " in VR") -ErrorRecord $_
            }
            return
        }
        # Migration fallback for Elden Ring installs made by a Hub version
        # that wrote only the shared chooser, before dedicated Hotbite/ERVR
        # launchers existed. Real probe markers still decide presence; this
        # fallback only supplies a usable launch path. A new install/reinstall
        # writes the dedicated launchers and no longer reaches this branch.
        $requestedPresent = [bool]($Mode -and $tmState -and (Get-AlternativeModValue $tmState ("${Mode}Present")))
        if ($requestedPresent -and $Game.LaunchExe -and -not $Game.DisableSharedTwoModsFallback) {
            $legacyRoots = @($tmParent)
            if ($tmState) { $legacyRoots += @($tmState.GameDir, $tmState.CurrentDir, $tmState.DepotDir) }
            foreach ($legacyRoot in $legacyRoots) {
                if (-not $legacyRoot) { continue }
                if ($Mode -eq "ModB" -and $Game.ModBProbeFile -and -not (Test-RelativePathMarker -Root $legacyRoot -Values $Game.ModBProbeFile)) { continue }
                $legacyCommon = Join-Path $legacyRoot $Game.LaunchExe
                if (Test-Path -LiteralPath $legacyCommon -PathType Leaf) {
                    try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized } } catch { }
                    try { Start-Process -FilePath $legacyCommon -WorkingDirectory (Split-Path -Parent $legacyCommon) } catch { }
                    return
                }
            }
        }
        # A Play action never changes meaning. Missing launch evidence is an
        # actionable error; installation belongs exclusively to the installer
        # buttons, and the author's page belongs exclusively to Mod Page.
        $requestedName = if ($Mode -match '^Mod[A-H]$') { [string](Get-AlternativeModValue $Game ("${Mode}Name")) } else { '' }
        $missingDetail = if ($requestedName) {
            "The launcher for $requestedName was not found. Use its update/reinstall arrow to repair the installation."
        } else {
            "No installed VR launcher was found. Use the update/reinstall arrow to repair the installation."
        }
        Write-HubActionFailure -Action ("Start " + $Game.Title + " in VR") -Message $missingDetail
        return
    }

    $state = $global:gameStateMap[$Game.Title]
    $gameDir = $null

    # Some mods require the store bootstrap even when a valid executable or
    # an older locate-game override exists. Dishonored VR is the first strict
    # case: its author documents that a direct Dishonored.exe start crashes
    # at the menu. This route intentionally outranks saved executable paths.
    if ($Game.SteamLaunchOnly -and $Game.SteamId) {
        try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized } } catch {}
        try { Start-Process ("steam://rungameid/" + [string]$Game.SteamId) } catch {}
        return
    }

    # Launch override (from the "Locate Game" exe-picker): a genuinely
    # different store executable wins. A legacy base-EXE override is upgraded
    # to the installer's dedicated launcher when both resolve in one folder.
    try {
        # HIGHEST PRIORITY: the starter that sits in the GAME folder. For mods
        # that moved into the game folder this is the only file that is
        # guaranteed to be the current one - recorded paths and recorded
        # starters can both still point at a previous install elsewhere, and
        # those files usually still exist, so no check on them can tell.
        if ($Game.LaunchExeAlt) {
            try {
                $altBase = $null
                if ($global:gameStateMap -and $global:gameStateMap[$Game.Title]) {
                    $altBase = $global:gameStateMap[$Game.Title].GameDir
                }
                if (-not $altBase) {
                    foreach ($fp in @($Game.FallbackPaths)) {
                        if ($fp -and ($fp -notmatch '^(EPIC|XBOX|STEAM):') -and (Test-Path -LiteralPath $fp)) { $altBase = $fp; break }
                    }
                }
                if ($altBase) {
                    $altLaunch = Join-Path $altBase $Game.LaunchExeAlt
                    if (Test-Path -LiteralPath $altLaunch) {
                        try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized } } catch { }
                        Start-GameProcess -FilePath $altLaunch -WorkingDirectory (Split-Path -Parent $altLaunch) -Game $Game
                        return
                    }
                }
            } catch { }
        }

        $launchOverride = Read-LaunchOverride -Game $Game
        $recordedForOverride = Read-InstalledPath -Game $Game
        $replacementOverride = Get-ReplacementForObsoleteBaseLaunchOverride -Game $Game -InstalledRoot $recordedForOverride -LaunchOverride $launchOverride
        if ($replacementOverride) {
            Write-PersistentGameStateValue -Game $Game -Name 'launch_exe' -Value $replacementOverride
            $launchOverride = $replacementOverride
        }
        if ($launchOverride -and (Test-Path $launchOverride)) {
            try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Minimized } } catch { }
            $ovDir = Split-Path -Parent $launchOverride
            if ($Game.LaunchArgs) {
                Start-GameProcess -FilePath $launchOverride -Arguments $Game.LaunchArgs -WorkingDirectory $ovDir -Game $Game
            } else {
                Start-GameProcess -FilePath $launchOverride -WorkingDirectory $ovDir -Game $Game
            }
            return
        }
    } catch { }

    # Priority 0: an installer-recorded .installed_path wins over
    # everything (same rule the Check-Installed scan uses). Games we
    # copied OUT of Steam to C:\Games (e.g. Penumbra VR - the old
    # engine breaks under Program Files) must launch from that copy,
    # never via steam://rungameid which would start the unmodded
    # retail build in steamapps\common. We only trust the recorded
    # path if it still resolves AND holds the expected LaunchExe.
    try {
        $recordedLaunchPath = Read-InstalledPath -Game $Game
        if ($recordedLaunchPath -and (Test-Path $recordedLaunchPath)) {
            if ($Game.LaunchExe) {
                if (Test-Path (Join-Path $recordedLaunchPath $Game.LaunchExe)) {
                    $gameDir = $recordedLaunchPath
                }
            } else {
                $gameDir = $recordedLaunchPath
            }
        }
    } catch { }

    # Resolve VrInstallRoot if the game has one (GZDoomVR titles
    # install the engine into %LocalAppData%\GZDoomVR\ rather than
    # the Steam folder - the Steam install only holds the IWAD).
    # Tokens supported here match what Filter.ps1 resolves during
    # the scan: LOCALAPPDATA, APPDATA, PROGRAMDATA, USERPROFILE.
    # Anything else is taken as an absolute path.
    if (-not $gameDir -and $Game.VrInstallRoot -and $Game.LaunchExe) {
        $vrRoot = $Game.VrInstallRoot
        if     ($vrRoot -like "LOCALAPPDATA:*") { $vrRoot = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) ($vrRoot.Substring("LOCALAPPDATA:".Length)) }
        elseif ($vrRoot -like "APPDATA:*")      { $vrRoot = Join-Path ([Environment]::GetFolderPath("ApplicationData"))      ($vrRoot.Substring("APPDATA:".Length)) }
        elseif ($vrRoot -like "PROGRAMDATA:*")  { $vrRoot = Join-Path ([Environment]::GetFolderPath("CommonApplicationData")) ($vrRoot.Substring("PROGRAMDATA:".Length)) }
        elseif ($vrRoot -like "USERPROFILE:*")  { $vrRoot = Join-Path ([Environment]::GetFolderPath("UserProfile"))           ($vrRoot.Substring("USERPROFILE:".Length)) }
        if ((Test-Path $vrRoot) -and (Test-Path (Join-Path $vrRoot $Game.LaunchExe))) {
            $gameDir = $vrRoot
        }
    }

    # Trust state.GameDir only if the folder still exists AND contains
    # the expected LaunchExe. Stale state entries (uninstall, drive
    # reorganization, hub interrupted mid-scan) would otherwise carry
    # an invalid path and skip the FallbackPaths walk below.
    if (-not $gameDir -and $state -and $state.GameDir -and (Test-Path $state.GameDir)) {
        if ($Game.LaunchExe) {
            if (Test-Path (Join-Path $state.GameDir $Game.LaunchExe)) {
                $gameDir = $state.GameDir
            }
        } else {
            $gameDir = $state.GameDir
        }
    }

    # Walk FallbackPaths for any game that has them, not just
    # DepotInstall. Lots of titles can live in C:\Games\... outside
    # the state map (post-install state never refreshed, manual move,
    # etc.) - we should still find them. STEAM: tokens expand to
    # <library>\steamapps\common\<name> for each Steam library.
    if (-not $gameDir -and $Game.FallbackPaths) {
        # Lazily build the list of Steam libraries; only needed if a
        # STEAM: token appears in this game's FallbackPaths.
        $steamLibsResolved = $null
        foreach ($p in (Expand-DrivePaths $Game.FallbackPaths)) {
            $candidatePaths = @()
            if ($p -like "STEAM:*") {
                if ($null -eq $steamLibsResolved) {
                    $steamLibsResolved = if (Get-Command Get-HubSteamLibraries -ErrorAction SilentlyContinue) {
                        @(Get-HubSteamLibraries)
                    } else { @() }
                }
                $folder = $p.Substring("STEAM:".Length)
                foreach ($lib in $steamLibsResolved) {
                    $candidatePaths += (Join-HubPathLexical $lib "steamapps\common\$folder")
                }
            } else {
                $candidatePaths += $p
            }

            foreach ($cp in $candidatePaths) {
                if (-not (Test-Path $cp)) { continue }
                if ($Game.LaunchExe) {
                    if (Test-Path (Join-Path $cp $Game.LaunchExe)) {
                        $gameDir = $cp
                        break
                    }
                } else {
                    $gameDir = $cp
                    break
                }
            }
            if ($gameDir) { break }
        }
    }

    # Hide the Hub window before launching - VR games need full
    # foreground focus, otherwise the Hub stays on top and the
    # game window can't claim focus / SteamVR doesn't pick up
    # the right HWND. We minimise rather than close so the user
    # can come back to the Hub when they alt-tab out of the game.
    try {
        if ($global:window) {
            $global:window.WindowState = [System.Windows.WindowState]::Minimized
        }
    } catch { }

    if ($Game.LaunchExe -and $gameDir) {
        $exePath = Join-Path $gameDir $Game.LaunchExe
        if (Test-Path $exePath) {
            # Revive launch route: some VR builds target the Oculus runtime
            # only (e.g. Quake 2 VR) and must run THROUGH Revive on a non-
            # Oculus headset. When the installer set that up it drops a
            # ".revive_launch" marker (holding the injector path) in the
            # game folder. If present - and ONLY then - launch via
            # ReviveInjector.exe with the game EXE as its argument, exactly
            # like the desktop shortcut but independent of it (the user may
            # have deleted the shortcut).
            $reviveMarker = Join-Path $gameDir ".revive_launch"
            if (Test-Path $reviveMarker) {
                $reviveInjector = $null
                try { $storedInj = (Get-Content $reviveMarker -Raw -ErrorAction Stop).Trim() } catch { $storedInj = "" }
                if ($storedInj -and (Test-Path $storedInj)) { $reviveInjector = $storedInj }
                if (-not $reviveInjector) {
                    $injCands = @(
                        (Join-Path $env:ProgramFiles "Revive\ReviveInjector.exe"),
                        (Join-Path $env:ProgramFiles "Revive\Revive\ReviveInjector.exe")
                    )
                    $pf86 = ${env:ProgramFiles(x86)}
                    if ($pf86) { $injCands += (Join-Path $pf86 "Revive\ReviveInjector.exe") }
                    foreach ($cand in $injCands) { if (Test-Path $cand) { $reviveInjector = $cand; break } }
                }
                if ($reviveInjector) {
                    try { Start-Process -FilePath $reviveInjector -ArgumentList "`"$exePath`"" -WorkingDirectory $gameDir; return } catch { }
                }
                # Injector not found: fall through to a direct launch as a
                # last resort (better than doing nothing).
            }
            # Safety net: depot-installed games need steam_appid.txt
            # next to the EXE, or Steam intercepts the launch with an
            # "install this game" dialog. Older installs from before
            # this file was written by the installers won't have it -
            # drop it in now if it's missing.
            # EXCLUDE Scrap Mechanic VR only: its launch target is the
            # mod's own manager (ScrapMechanicVR.exe), which links
            # Steamworks itself. A steam_appid.txt in that folder makes
            # it read the wrong appid and lose its managed install - and
            # the desktop shortcut, sharing that folder, breaks too.
            $isDepotInstall = [bool]$Game.DepotInstall
            $isOutsideSteamCommon = ($gameDir -notmatch '\\steamapps\\common\\')
            if ($Game.SteamId -and $Game.Title -ne "Scrap Mechanic VR" -and ($isDepotInstall -or $isOutsideSteamCommon)) {
                $appidFile = Join-Path $gameDir "steam_appid.txt"
                if (-not (Test-Path $appidFile)) {
                    try { Set-Content -Path $appidFile -Value $Game.SteamId -Encoding ASCII -NoNewline -Force } catch { }
                }
            }
            try {
                # Working directory: default to the game root (the
                # long-standing behaviour for every title). The four
                # titles below launch an exe that lives in a SUBFOLDER
                # of the game dir, and their desktop shortcuts already
                # set that subfolder as the working directory. We mirror
                # that here so "Start in VR" behaves identically to the
                # shortcut. This matters most for Penumbra (old HPL1
                # engine loads shaders relative to CWD - wrong CWD gives
                # the "couldn't load pointlight2d" crash); the others are
                # included for shortcut/Hub parity. Explicit whitelist so
                # no game outside this set changes behaviour.
                $subfolderExeTitles = @(
                    "Crysis VR",
                    "Cyberpunk 2077",
                    "Jedi Knight: Jedi Academy VR",
                    "Jedi Knight: Jedi Outcast VR",
                    "Penumbra: Overture VR",
                    "Outer Wilds VR",
                    "Outward DE VR",
                    "Selaco VR",
                    "Halo Master Chief Collection VR"
                )
                $launchWorkDir = $gameDir
                if ($subfolderExeTitles -contains $Game.Title) {
                    $exeParent = Split-Path -Parent $exePath
                    if ($exeParent) { $launchWorkDir = $exeParent }
                }

                # GZDoomVR titles: the installer records the FULL launch args
                # (iwad + vr_mode + any chosen 3D-mod -file entries) in a
                # per-WAD marker file next to gzdoomvr.exe. Prefer it over the
                # catalog's static LaunchArgs so Start-in-VR loads the SAME
                # mods as the desktop shortcut. Keyed by the WAD leaf from
                # VrInstallEvidence, matching how the installer names the file.
                $effectiveArgs = $Game.LaunchArgs
                if ($Game.VrInstallEvidence -and $Game.VrInstallEvidence.Count -gt 0) {
                    try {
                        $__wadLeaf = Split-Path $Game.VrInstallEvidence[0] -Leaf
                        if ($__wadLeaf) {
                            $__argKey  = ($__wadLeaf -replace '[^A-Za-z0-9]', '_')
                            $__argFile = Join-Path $gameDir ".vrlaunchargs_$__argKey"
                            if (Test-Path -LiteralPath $__argFile) {
                                $__savedArgs = (Get-Content -LiteralPath $__argFile -Raw -ErrorAction Stop).Trim()
                                if ($__savedArgs) { $effectiveArgs = $__savedArgs }
                            }
                        }
                    } catch { }
                }

                if ($effectiveArgs) {
                    Start-GameProcess -FilePath $exePath -Arguments $effectiveArgs -WorkingDirectory $launchWorkDir -Game $Game
                } else {
                    Start-GameProcess -FilePath $exePath -WorkingDirectory $launchWorkDir -Game $Game
                }
                return
            } catch { }
        }
    }

    # Custom-install detection: games that have a VrInstallRoot or
    # a recorded .installed_path (e.g. Tomb Raider 1 VR, Outward DE
    # VR, Tormented Souls VR) live OUTSIDE Steam. If we got here
    # without finding a valid $gameDir + LaunchExe, the user has
    # deleted the install folder under us. The state map is stale
    # and the next Check-Installed scan will repair it - but we
    # must NOT fall through to the steam://rungameid handler below,
    # which would launch the unmodded retail game instead.
    $isCustomInstall = ($Game.VrInstallRoot -or (Get-InstalledPathFile -Game $Game))

    # !!! BUT FIRST: IS THE MOD ITSELF STILL THERE? (2026-08-20)
    # Not finding the LAUNCHER is not the same as the install being gone.
    # An entry whose LaunchExe is a batch file the installer writes can
    # lose that one file - an older install, a cleanup, a new Hub build
    # that added the launcher - while the mod sits perfectly fine next to
    # it. Wiping the recorded path and the state in that situation
    # destroys a working install and tells the user something false.
    # So: if the ModFile is still on disk, say what is actually missing
    # and leave everything alone.
    $modStillThere = $false
    if ($isCustomInstall -and -not $gameDir -and $Game.ModFile) {
        $probeRoots = @()
        if ($Game.VrInstallRoot) {
            $pr = $Game.VrInstallRoot
            if     ($pr -like "LOCALAPPDATA:*") { $pr = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) ($pr.Substring("LOCALAPPDATA:".Length)) }
            elseif ($pr -like "APPDATA:*")      { $pr = Join-Path ([Environment]::GetFolderPath("ApplicationData"))      ($pr.Substring("APPDATA:".Length)) }
            elseif ($pr -like "PROGRAMDATA:*")  { $pr = Join-Path ([Environment]::GetFolderPath("CommonApplicationData")) ($pr.Substring("PROGRAMDATA:".Length)) }
            elseif ($pr -like "USERPROFILE:*")  { $pr = Join-Path ([Environment]::GetFolderPath("UserProfile"))           ($pr.Substring("USERPROFILE:".Length)) }
            $probeRoots += $pr
        }
        try { $rp = Read-InstalledPath -Game $Game; if ($rp) { $probeRoots += $rp } } catch {}
        foreach ($rt in $probeRoots) {
            if (-not $rt) { continue }
            try { if (Test-Path -LiteralPath "$($rt.TrimEnd('\'))\$($Game.ModFile)") { $modStillThere = $true; break } } catch {}
        }
    }
    if ($modStillThere) {
        try { if ($global:window) { $global:window.WindowState = [System.Windows.WindowState]::Normal } } catch {}
        try {
            [System.Windows.MessageBox]::Show(
                "$($Game.Title) is installed, but the file that starts it is missing.`n`nRun the installer once from this page - it writes that file and changes nothing else about your install.",
                "Launcher missing",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information) | Out-Null
        } catch {}
        return
    }

    if ($isCustomInstall -and -not $gameDir) {
        # Clear the cached "VR Ready" state so the card flips back
        # to "Install" on next paint, and wipe any stale
        # .installed_path so the next Check-Installed scan sees
        # a clean slate.
        try {
            if ($global:gameStateMap.ContainsKey($Game.Title)) {
                $global:gameStateMap.Remove($Game.Title) | Out-Null
            }
        } catch { }
        try {
            $stalePath = Get-InstalledPathFile -Game $Game
            if ($stalePath -and (Test-Path $stalePath)) {
                Remove-Item $stalePath -Force -EA SilentlyContinue
            }
            $staleVer = Get-InstalledVersionPath -Game $Game
            if ($staleVer -and (Test-Path $staleVer)) {
                Remove-Item $staleVer -Force -EA SilentlyContinue
            }
        } catch { }
        # Restore the hub window we minimised above so the user
        # sees the message, then trigger a full re-scan so all
        # cards reflect reality.
        try {
            if ($global:window) {
                $global:window.WindowState = [System.Windows.WindowState]::Normal
            }
        } catch { }
        try {
            [System.Windows.MessageBox]::Show(
                "$($Game.Title) install folder no longer exists.`n`nThe install has been cleared. Run the installer again to reinstall.",
                "Install missing",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            ) | Out-Null
        } catch { }
        # Repair the state only as far as the user has opted in: a full
        # rescan is fine for someone who already ran Scan games, but for
        # anyone who never did, scanning the whole PC off the back of a
        # failed launch would be unrequested. Clearing this one game's
        # state above is enough for them - the card falls back to
        # "Install" on the next paint.
        if ($global:UserRanFullScan) {
            try { Invoke-CheckInstalledScan } catch { Fail-InstalledScan -ErrorRecord $_ -Quiet }
        }
        return
    }

    # Some mods do NOT run through the retail exe: they have their own
    # launcher and steam://rungameid would start the plain, flat game.
    # Reaching this point means every VR route above failed, so launching
    # via Steam would silently hand the user the desktop version instead
    # of VR. Say so rather than pretend it worked.
    #   NeverSteamLaunch = $true  in the catalog opts a game into this.
    if ($Game.NeverSteamLaunch) {
        try {
            [System.Windows.MessageBox]::Show(
                ("$($Game.Title) starts through its own launcher, and the Hub " +
                 "could not find it.`n`nRun the installer again from this page - " +
                 "it re-creates the launcher and reconnects 'Start in VR'."),
                "Cannot start in VR", "OK", "Warning") | Out-Null
        } catch { }
        return
    }

    # Non-depot games: regular Steam launch is fine - the game lives
    # in the Steam library and Steam knows how to start it.
    if ($Game.SteamId) {
        try {
            Start-Process "steam://rungameid/$($Game.SteamId)" -ErrorAction Stop
            return
        } catch {
            Write-HubActionFailure -Action ("Start " + $Game.Title + " in VR") -ErrorRecord $_
            return
        }
    }
    Write-HubActionFailure -Action ("Start " + $Game.Title + " in VR") -Message 'No verified game or VR launcher is configured for this entry.'
}
