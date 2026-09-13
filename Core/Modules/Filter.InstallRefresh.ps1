# Resolve one freshly installed game's tracked version without scanning any
# other library.  This closes the first-use gap for older installers that do
# not write their downloaded tag themselves: previously the version was only
# seeded by a later full scan, so replacing the Hub in between lost the fact.
function global:Get-PostInstallTrackedVersion {
    param($Game, [string]$GameDir)
    if (-not $Game) { return $null }
    if ($Game.ThunderstoreAuthor -and $Game.ThunderstorePackage) {
        # Thunderstore installers normally leave the exact installed package
        # version in BepInEx\.ts_versions. Read that first: unlike the live
        # endpoint it tells us what THIS run installed, and it also works
        # offline. Older/depot installer modes may not have the file, so the
        # package endpoint remains the fallback.
        if ($GameDir) {
            try {
                foreach ($tsVersionKey in @(
                    "$($Game.ThunderstoreAuthor)-$($Game.ThunderstorePackage)",
                    "$($Game.ThunderstorePackage)"
                )) {
                    $tsLocalPath = Join-Path $GameDir "BepInEx\.ts_versions\$tsVersionKey"
                    if (Test-Path -LiteralPath $tsLocalPath -PathType Leaf) {
                        $tsLocal = (Get-Content -LiteralPath $tsLocalPath -Raw -ErrorAction Stop).Trim()
                        if (Test-IsTrackableInstalledVersion -Version $tsLocal) { return $tsLocal }
                    }
                }
            } catch {}
        }
        try {
            $tsUri = "https://thunderstore.io/api/experimental/package/$($Game.ThunderstoreAuthor)/$($Game.ThunderstorePackage)/"
            $tsData = Invoke-RestMethod -Uri $tsUri -TimeoutSec 5 -ErrorAction Stop
            if ($tsData -and $tsData.latest -and $tsData.latest.version_number) {
                return ([string]$tsData.latest.version_number).Trim()
            }
        } catch {}
    }
    if ($Game.GithubCommitRepo) {
        try {
            $commitBranch = if ($Game.GithubCommitBranch) { [string]$Game.GithubCommitBranch } else { 'main' }
            return (Get-GithubLatestCommitCached -Repo $Game.GithubCommitRepo -Branch $commitBranch)
        } catch {}
    }
    if ($Game.GithubRepo -and -not $Game.GithubRepoB) {
        try {
            $postRepo = Get-SelectedGithubRepo -Game $Game -GameDir $GameDir
            $postPrerelease = Get-GithubPrereleasePreference -Game $Game -GameDir $GameDir
            $uri = if ($postPrerelease) {
                "https://api.github.com/repos/$postRepo/releases?per_page=1"
            } else {
                "https://api.github.com/repos/$postRepo/releases/latest"
            }
            $r = Invoke-RestMethod -Uri $uri -Headers @{ 'User-Agent'='PCVR-Mods-Hub' } -TimeoutSec 5 -ErrorAction Stop
            if ($postPrerelease) { $r = @($r) | Select-Object -First 1 }
            if ($r -and $r.tag_name) { return ([string]$r.tag_name).Trim() }
        } catch {}
    }
    if ($Game.GitHubNightly) {
        try {
            $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$($Game.GitHubNightly)/releases/latest" `
                    -Headers @{ 'User-Agent'='PCVR-Mods-Hub' } -TimeoutSec 5 -ErrorAction Stop
            if ($Game.RollingUpdate -and $Game.RollingUpdateAsset) {
                $a = @($r.assets | Where-Object { $_.name -eq $Game.RollingUpdateAsset }) | Select-Object -First 1
                if ($a -and $a.updated_at) { return ([string]$a.updated_at).Trim() }
            } elseif ($r.tag_name) { return ([string]$r.tag_name).Trim() }
        } catch {}
    }
    if ($Game.CodebergRepo) {
        try { return (Get-CodebergLatestTagCached -Repo $Game.CodebergRepo -IncludePrerelease:([bool]$Game.CodebergPrerelease)) } catch {}
    }
    if ($Game.WebVersionUrl) {
        try { return (Get-WebVersionCached -Url $Game.WebVersionUrl -Title $Game.Title) } catch {}
    }
    # Manual/authenticated sources can expose a hidden machine version without
    # putting it on the compact tile. Unlike release dates or file timestamps,
    # this value is an exact build identity and is safe to compare later.
    if ($Game.TrackedVersion -and (Test-IsTrackableInstalledVersion -Version $Game.TrackedVersion)) {
        return ([string]$Game.TrackedVersion).Trim()
    }
    return (Get-ModVersionFromString -ModString $Game.Mod)
}

# Finalize version tracking for a CONFIRMED successful legacy installer that
# supplied path evidence but no version marker of its own. This is intentionally
# separate from cancellation (which calls nothing and preserves old recovery).
# Keeping it as a small production helper also makes the exact state transition
# independently regression-testable without constructing a WPF detail page.
function global:Complete-LegacyPostInstallVersionTracking {
    param($Game, [string]$GameDir)
    $resolvedVersion = Get-PostInstallTrackedVersion -Game $Game -GameDir $GameDir
    if (Test-IsTrackableInstalledVersion -Version $resolvedVersion) {
        Write-InstalledVersion -Game $Game -Version $resolvedVersion -GameDir $GameDir
        return $resolvedVersion
    }
    Invalidate-SupersededInstalledVersion -Game $Game -GameDir $GameDir
    return $null
}

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
    # Cancel-safe update tracking: the installer wrapper drops a typed
    # transaction result in the per-user runtime folder ONLY when its core
    # produced fresh version/path success evidence. Successful older cores may
    # end with `exit 0`; Run-Installer finalizes those from its finally block.
    # A cancel/failure changes no completion evidence, so no result is written.
    # If the result is present the mod was really (re)installed. Exact version
    # evidence is imported directly; a path-only legacy success resolves its
    # current source version or blocks every superseded recovery value. No
    # marker = cancelled = leave the tracked version untouched so the card
    # correctly keeps showing "Update".
    if ($title) {
        try {
            $pendGame = $null
            foreach ($g in @($ownGames + $ownGamesGP + $externalGames)) {
                if ($g.Title -eq $title) { $pendGame = $g; break }
            }
            if ($pendGame) {
                $okMk = Get-UpdateOkMarkerPath -Game $pendGame
                if ($okMk -and (Test-Path $okMk)) {
                    # The wrapper records whether THIS installer run wrote an
                    # authoritative version marker.  Preserve and mirror such
                    # a value; only legacy installers that wrote no version
                    # need the old clear-and-seed path.  Unconditionally
                    # clearing here was the Forza 5/6 loop: the installer wrote
                    # 1.3.19 correctly and this refresh blanked it immediately.
                    $status = $null
                    try { $status = Get-Content -LiteralPath $okMk -Raw -ErrorAction Stop | ConvertFrom-Json } catch {}
                    # The wrapper's marker is a typed result, not a bare
                    # presence flag. Only an explicitly successful result may
                    # reset/reseed tracked versions. A malformed or legacy
                    # marker is consumed harmlessly and cannot clear Update.
                    $confirmedSuccess = [bool]($status -and ([string]$status.outcome -eq 'success'))
                    $primaryWritten = [bool]($confirmedSuccess -and $status.versionWritten)
                    $secondaryWritten = [bool]($confirmedSuccess -and $status.versionBWritten)

                    # The transaction result is the one authoritative bridge
                    # from legacy installer files into the canonical state.
                    # Import it before a normal read, otherwise an older
                    # LocalAppData value could hide the version/path written by
                    # this installer run.
                    if ($confirmedSuccess -and $status.installedPath -and (Test-Path -LiteralPath ([string]$status.installedPath) -PathType Container)) {
                        Write-PersistentGameStateValue -Game $pendGame -Name 'installed_path' -Value ([string]$status.installedPath)
                    }

                    # The folder comes from the path the installer just
                    # recorded, with the scan's own state as a second source.
                    $pendDir = $null
                    try { $pendDir = Read-InstalledPath -Game $pendGame } catch {}
                    # Reading once migrates a freshly written .launch_exe to
                    # the durable state index as well.  This is essential for
                    # external launchers after the Hub folder is replaced.
                    try { [void](Read-LaunchOverride -Game $pendGame) } catch {}
                    if (-not $pendDir) {
                        try {
                            $stP = $global:gameStateMap[$pendGame.Title]
                            if ($stP -and $stP.GameDir) { $pendDir = $stP.GameDir }
                        } catch {}
                    }
                    if (-not $confirmedSuccess) {
                        # Fail closed: refresh detection below, but preserve
                        # every installed-version value exactly as it was.
                    } elseif ($primaryWritten -or $secondaryWritten) {
                        if ($primaryWritten) {
                            $exact = ('' + $status.versionValue).Trim()
                            if (-not (Test-IsTrackableInstalledVersion -Version $exact)) {
                                $exact = Read-VersionStampFile -Path (Get-InstalledVersionPath -Game $pendGame)
                            }
                            if ($exact) { Write-InstalledVersion -Game $pendGame -Version $exact -GameDir $pendDir }
                        }
                        if ($secondaryWritten) {
                            $exactB = ('' + $status.versionBValue).Trim()
                            if (-not (Test-IsTrackableInstalledVersion -Version $exactB)) {
                                $exactB = Read-VersionStampFile -Path (Get-InstalledVersionPathB -Game $pendGame)
                            }
                            if ($exactB) { Write-InstalledVersionB -Game $pendGame -Version $exactB -GameDir $pendDir }
                        }
                    } elseif (-not ($pendGame.NoVersionSeed -and $pendGame.TwoMods)) {
                        # A confirmed path-only legacy install supersedes the
                        # old version. Resolve the exact new build BEFORE any
                        # read can recover the stale game-side stamp/manifest.
                        # If the source is temporarily unavailable, durably
                        # block that stale recovery and let a later scan seed
                        # the version when the source becomes available.
                        [void](Complete-LegacyPostInstallVersionTracking -Game $pendGame -GameDir $pendDir)
                    } else {
                        # FH6 can install NALULUNA without touching the lufz
                        # build.  No version write in that branch means "the
                        # tracked lufz mod was untouched", not "forget it".
                        # Keeping the marker preserves a pending lufz update.
                    }
                    if (Test-Path -LiteralPath $okMk -PathType Leaf) {
                        Remove-Item -LiteralPath $okMk -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        } catch { throw }
    }
    $hadFullScan = [bool]$global:UserRanFullScan

    if ($hadFullScan) {
        # User has already scanned at least once - keep their
        # global state coherent by re-running the full scan.
        try { Invoke-CheckInstalledScan } catch { Fail-InstalledScan -ErrorRecord $_ }
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
                $postTwoProbe = $null
                if ($game.TwoMods) {
                    $postTwoProbe = Get-TwoModsPresence -Game $game -FallbackRoot $recordedPath
                    $modPresent = if ($game.TwoModsRequireBoth) {
                        $postDefs = @(Get-AlternativeModDefinitions -Game $game)
                        $postPresent = @($postDefs | Where-Object { [bool](Get-AlternativeModValue $postTwoProbe ("$($_.Mode)Present")) })
                        ($postDefs.Count -gt 0 -and $postPresent.Count -eq $postDefs.Count)
                    } else {
                        (@(Get-AlternativeModDefinitions -Game $game | Where-Object { [bool](Get-AlternativeModValue $postTwoProbe ("$($_.Mode)Present")) }).Count -gt 0)
                    }
                } elseif ($recordedPath -and $game.ModFile) {
                    $modPresent = (Test-Path (Join-Path $recordedPath $game.ModFile))
                    if (-not $modPresent -and $game.ModFileAlt) {
                        $modPresent = (Test-Path (Join-Path $recordedPath $game.ModFileAlt))
                    }
                    if (-not $modPresent -and $game.DoorstopTargetModFile) {
                        $modPresent = Test-DoorstopTargetModMarker -GameRoot $recordedPath -TargetMarker $game.DoorstopTargetModFile -LoaderFile $game.DoorstopLoaderFile
                    }
                    # !!! VrInstallRoot GAMES KEEP THE MOD OUTSIDE THE GAME
                    # FOLDER (2026-08-20) - %LocalAppData% and the like. The
                    # recorded path is then the GAME folder, so looking only
                    # there finds nothing and the card falls back to
                    # "Install VR Mod" even though the mod is right there.
                    # The Locate dialog already checks this root and reports
                    # the mod as found; without the same check here the two
                    # disagree, which is exactly what the user sees.
                    if (-not $modPresent -and $game.VrInstallRoot) {
                        $vr = $game.VrInstallRoot
                        if     ($vr -like "LOCALAPPDATA:*") { $vr = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) ($vr.Substring("LOCALAPPDATA:".Length)) }
                        elseif ($vr -like "APPDATA:*")      { $vr = Join-Path ([Environment]::GetFolderPath("ApplicationData"))      ($vr.Substring("APPDATA:".Length)) }
                        elseif ($vr -like "PROGRAMDATA:*")  { $vr = Join-Path ([Environment]::GetFolderPath("CommonApplicationData")) ($vr.Substring("PROGRAMDATA:".Length)) }
                        elseif ($vr -like "USERPROFILE:*")  { $vr = Join-Path ([Environment]::GetFolderPath("UserProfile"))           ($vr.Substring("USERPROFILE:".Length)) }
                        try {
                            if (Test-Path -LiteralPath (Join-Path $vr $game.ModFile)) { $modPresent = $true }
                        } catch {}
                    }
                }
                # A DualMode title can use distinct current/depot proof files.
                # The exact side probes must therefore be allowed to confirm a
                # successful install even when the catalog's generic ModFile
                # belongs only to the other side.
                $postDualProbe = $null
                if ($game.DualMode) {
                    try {
                        $postDualProbe = Get-DualModePresence -Game $game
                        if ($postDualProbe.AnyPresent) {
                            $modPresent = $true
                            # Depot/legacy routes use their own path receipts,
                            # not the generic .installed_path. Use the exact
                            # positive probe immediately so first-time installs
                            # turn green without waiting for a full rescan.
                            $postDualRoot = Get-DualModePreferredRoot -Presence $postDualProbe
                            if ($postDualRoot) { $recordedPath = $postDualRoot }
                        }
                    } catch {}
                }
                if ($recordedPath -and (Test-Path $recordedPath) -and $modPresent) {
                    # A version-aware installer already supplied the exact
                    # value.  A legacy installer did not; resolve only this
                    # game's source now and durably mirror the result.  No
                    # full disk/library scan is triggered.
                    $postVer = Read-InstalledVersion -Game $game -GameDir $recordedPath
                    if (-not $postVer -and -not $game.NoVersionSeed) {
                        $postVer = Get-PostInstallTrackedVersion -Game $game -GameDir $recordedPath
                        if ($postVer) { Write-InstalledVersion -Game $game -Version $postVer -GameDir $recordedPath }
                    }
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
                        $dm = if ($postDualProbe) { $postDualProbe } else { Get-DualModePresence -Game $game }
                        $stateEntry.CurrentPresent = [bool]$dm.CurrentPresent
                        $stateEntry.DepotPresent   = [bool]$dm.DepotPresent
                        $stateEntry.LegacyPresent  = [bool]$dm.LegacyPresent
                        $stateEntry.RouteSplit     = [bool]$dm.MultiplePresent
                        $stateEntry.CurrentDir     = $dm.CurrentDir
                        $stateEntry.DepotDir       = $dm.DepotDir
                        $stateEntry.LegacyDir      = $dm.LegacyDir
                        if ($dm.BothPresent) {
                            $stateEntry.DualMode   = $true
                        }
                    }
                    if ($game.TwoMods) {
                        $pi = if ($postTwoProbe) { $postTwoProbe } else { Get-TwoModsPresence -Game $game -FallbackRoot $recordedPath }
                        $piDefs = @(Get-AlternativeModDefinitions -Game $game)
                        $piPresent = @($piDefs | Where-Object { [bool](Get-AlternativeModValue $pi ("$($_.Mode)Present")) })
                        $anyTwo = if ($game.TwoModsRequireBoth) { $piDefs.Count -gt 0 -and $piPresent.Count -eq $piDefs.Count }
                                  else { $piPresent.Count -gt 0 }
                        $stateEntry.TwoMods     = $anyTwo
                        Set-AlternativeModStateFields -State $stateEntry -Game $game -Presence $pi
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
                elseif ($recordedPath -and (Test-Path $recordedPath)) {
                    # GAME FOUND, MOD NOT THERE YET (2026-08-20). The branch
                    # above only fires when the mod file is on disk, so
                    # locating a game by hand wrote NO state at all - and
                    # without a state entry the detail page shows no
                    # "Game installed - ready for the VR mod" pill until a
                    # full scan has run. For a title that no scan can find
                    # anyway (Virtua Cop 2 is in no library), that pill
                    # would never appear.
                    # Same shape the full scan writes for this case, so both
                    # agree and nothing downstream has to tell them apart.
                    # The LABEL is computed exactly as the full scan does
                    # it (Filter.ps1 line 3962), so both paths put the same
                    # word on the button. Writing a literal here gave the
                    # tile "Install VR Mod" after a Locate and "Install"
                    # after a scan - same state, two different buttons.
                    $lbl = if ($game.Bat) { "Install" }
                           elseif ($game.Type -eq "steam") { "Open in Steam" }
                           elseif ($game.Type -eq "itch")  { "Open on itch.io" }
                           else { "Get Installer" }
                    $global:gameStateMap[$title] = @{
                        Tag      = "installed"
                        State    = "installed"
                        Border   = "#2a5c38"
                        BtnText  = $lbl
                        BtnColor = "#66dd88"
                        GameDir  = $recordedPath
                    }
                    try { Rebuild-Lookups } catch {}
                }
            }
        } catch { throw }
    }

    # Re-render the open detail page so the new state shows up
    # immediately, regardless of which branch we took.
    try {
        if ($global:currentDetailGame -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
            Show-DiscoverDetail -Game $global:currentDetailGame
        }
    } catch {}
}

# Timer callbacks used to swallow every post-install refresh exception. That
# produced the worst possible symptom: the installer window closed, the tile
# stayed on Update, and no log explained why. Every install surface now calls
# this one guarded entry point, which keeps the Hub alive while making the
# failure visible and durable.
function global:Invoke-PostInstallRefreshSafely {
    try {
        Invoke-PostInstallRefresh
    } catch {
        if (Get-Command Write-HubActionFailure -ErrorAction SilentlyContinue) {
            Write-HubActionFailure -Action 'Refresh installed mod status' -ErrorRecord $_
        } else {
            try { Write-Host ("[HubError] Refresh installed mod status: " + $_.Exception.Message) -ForegroundColor Red } catch {}
        }
    }
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
                Invoke-PostInstallRefreshSafely
                return
            }
            if ((Get-Date) -gt $st.Deadline) { try { $s.Stop() } catch {} }
        })
        $timer.Start()
    } catch {
        if (Get-Command Write-HubActionFailure -ErrorAction SilentlyContinue) {
            Write-HubActionFailure -Action 'Watch installer completion' -ErrorRecord $_
        }
    }
}
