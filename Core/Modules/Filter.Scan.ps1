# Set ONLY by a real, user-triggered full scan. The startup quick-scan also
# fills $global:gameStateMap, so that map can never be used to decide whether
# the user opted into full scans - doing so made every installer end with an
# unwanted scan over all games.
$global:UserRanFullScan = $false
$global:InstalledScanCompleted = $false
$script:LoggedUpdateEvidence = @{}

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

# A failed scan must restore the exact controls it disabled, leave a durable
# report and never strand the Hub in a permanent Scanning state. Every route
# that can start a full scan calls this same cleanup path.
function global:Fail-InstalledScan {
    param($ErrorRecord, [switch]$Quiet)
    try { if (Get-Command Stop-HubStateBatch -ErrorAction SilentlyContinue) { Stop-HubStateBatch } } catch {}
    try { Unlock-ScanUi } catch {}
    try { if (Get-Command Stop-ScanSpinner -ErrorAction SilentlyContinue) { Stop-ScanSpinner } } catch {}
    $global:ScanInProgress = $false
    $global:ScanQueued = $false
    $global:InstalledScanCompleted = $false
    try {
        $count = $global:window.FindName('CheckInstalledCount')
        $text = $global:window.FindName('CheckInstalledText')
        $mag = $global:window.FindName('CheckInstalledMagRight')
        $startupToggle = $global:window.FindName('CheckOnStartupBtn')
        if ($count) { $count.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($text) {
            $text.Visibility = [System.Windows.Visibility]::Visible
            $text.Text = 'Scan failed - retry'
            $text.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#ff7777')
            $text.FontSize = 12
        }
        if ($mag) { $mag.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($startupToggle) { $startupToggle.IsEnabled = $true; $startupToggle.Visibility = [System.Windows.Visibility]::Hidden }
    } catch {}
    if (Get-Command Write-HubActionFailure -ErrorAction SilentlyContinue) {
        Write-HubActionFailure -Action 'Scan installed games' -ErrorRecord $ErrorRecord -Quiet:$Quiet
    }
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
    $global:InstalledScanCompleted = $false
    $global:InstalledScanFailedGames = @{}
    $global:ScanGameErrors = New-Object System.Collections.ArrayList
    if (Get-Command Start-HubStateBatch -ErrorAction SilentlyContinue) { Start-HubStateBatch }
    $scanTotalWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $scanOnlineMs = 0L
    $scanDetectionMs = 0L
    $scanSlowGames = New-Object System.Collections.ArrayList

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
    # BIGGER AND BETWEEN TWO MAGNIFIERS WHILE SCANNING (2026-08-20):
    # on a re-scan the content shrinks to a small "Scanning..." inside
    # a button sized for "X on PC, Y VR Ready" - which looked empty and
    # broken. The state is reset below when the counter takes over.
    $checkInstalledText.FontSize = 14
    $magRight = $global:window.FindName("CheckInstalledMagRight")
    if ($magRight) { $magRight.Visibility = [System.Windows.Visibility]::Visible }

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

    # Resolve once per Hub session. Missing registry keys are normal and must
    # not generate transcripted TerminatingError records for every scan.
    $steamLibs = if (Get-Command Get-HubSteamLibraries -ErrorAction SilentlyContinue) {
        @(Get-HubSteamLibraries)
    } else { @() }

    # GOG Galaxy install roots. GOG doesn't have a single VDF
    # listing all libraries the way Steam does, so we collect
    # plausible roots: the Galaxy install folder's "Games"
    # subfolder (from registry), plus the well-documented default
    # locations for both Galaxy-managed and standalone installs.
    # Each root will have the game's folder name appended at
    # FallbackPaths-resolution time (GOG: prefix below).
    $gogRoots = @()
    foreach ($probe in @(
        @{ View='Registry64'; Sub='SOFTWARE\GOG.com\GalaxyClient\paths' },
        @{ View='Registry32'; Sub='SOFTWARE\GOG.com\GalaxyClient\paths' },
        @{ View='Registry64'; Sub='SOFTWARE\WOW6432Node\GOG.com\GalaxyClient\paths' }
    )) {
        $p = Get-HubRegistryValueQuiet -Hive LocalMachine -View $probe.View -SubKey $probe.Sub -Name 'client'
        if ($p) {
            $g = Get-HubExistingChildDirectory -BasePath $p -ChildPath 'Games'
            if ($g -and ($gogRoots -notcontains $g)) { $gogRoots += $g }
        }
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

    # Update sources must never hold up the installed-games scan. The old
    # synchronous prewarm spent up to 3.5 seconds here (and one DNS/HTTP call
    # could overrun that soft deadline), before a single game was inspected.
    # Read the last verified disk cache now and hand every stale/missing source
    # to the existing hidden worker below. Warm-cache update badges still paint
    # in this pass; new results are available on the next scan/start. Local game
    # detection therefore has a deterministic runtime even when GitHub is down.
    #
    # Reload the in-memory caches from disk FIRST: a worker spawned by an
    # earlier scan (this session or a previous one) has since written fresh
    # entries to disk that our lazily-loaded in-memory copies don't have.
    # Clearing them forces the getters to re-read the files on next use, so
    # straggler results actually surface THIS scan.
    $script:ghVerCache  = $null
    $script:webVerCache = $null

    $global:HubVersionCacheOnly = $false
    # The isolated WPF regression harness has no network authority and sets
    # this explicit test flag. Preserve the ordinary production behaviour,
    # while preventing a deliberately blocked socket from polluting the smoke
    # transcript and masking real Hub exceptions.
    $global:HubScanOnlineDown = [bool]$global:HubDisableScanNetwork
    $global:HubThunderstoreOnlineDown = [bool]$global:HubDisableScanNetwork
    $scanOnlineWatch = [System.Diagnostics.Stopwatch]::StartNew()

    # ---- Hand stale/missing sources to the background worker ----
    # Every online-checkable game whose disk-cache entry is missing or older
    # than the 6h TTL is queued here. The scan itself performs no synchronous
    # GitHub/web prewarm. A single-instance lock with a 10-minute staleness
    # expiry ensures that a crashed worker cannot block future refreshes.
    try {
        $ttlH = 6
        $nowU = [DateTime]::UtcNow
        $ghDisk = @{}; $webDisk = @{}
        $versionCacheDir = Get-HubVersionCacheRoot
        # LocalAppData is the preferred volatile-cache location, but it is not
        # a prerequisite for detecting installed games. Restricted/redirected
        # profiles can legitimately provide no runtime root; in that case the
        # scan continues cacheless and simply defers online prewarming.
        $ghF  = if ($versionCacheDir) { Join-Path $versionCacheDir ".gh_version_cache" } else { $null }
        $webF = if ($versionCacheDir) { Join-Path $versionCacheDir ".web_version_cache" } else { $null }
        if ($ghF -and (Test-Path -LiteralPath $ghF -PathType Leaf))  { try { $r = Get-Content -LiteralPath $ghF -Raw | ConvertFrom-Json;  foreach ($p in $r.PSObject.Properties) { $ghDisk[$p.Name]  = [string]$p.Value.checked } } catch {} }
        if ($webF -and (Test-Path -LiteralPath $webF -PathType Leaf)) { try { $r = Get-Content -LiteralPath $webF -Raw | ConvertFrom-Json; foreach ($p in $r.PSObject.Properties) { $webDisk[$p.Name] = [string]$p.Value.checked } } catch {} }
        function Test-CacheFresh([hashtable]$m, [string]$k) {
            if (-not $m.ContainsKey($k)) { return $false }
            try { return ((($nowU) - [DateTime]::Parse($m[$k], $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).TotalHours -lt $ttlH) } catch { return $false }
        }
        $pending = @()
        foreach ($g in $global:allGameData) {
            if ($g.GithubCommitRepo) {
                $commitBranch = if ($g.GithubCommitBranch) { [string]$g.GithubCommitBranch } else { 'main' }
                $commitKey = "$($g.GithubCommitRepo)#commit:$commitBranch"
                if (-not (Test-CacheFresh $ghDisk $commitKey)) {
                    $pending += , @{ K='ghcommit'; A=[string]$g.GithubCommitRepo; B=$commitBranch }
                }
            }
            if ($g.GithubRepo) {
                $repo = Get-SelectedGithubRepo -Game $g
                $reposToWarm = @($repo)
                if ($g.GithubRepoAlt -and $g.GithubRepoAlt -notin $reposToWarm) { $reposToWarm += $g.GithubRepoAlt }
                if ($g.GithubRepoAlt -and $g.GithubRepo -notin $reposToWarm) { $reposToWarm += $g.GithubRepo }
                $channelPrefs = if ($g.GithubChannelChoice) { @($false,$true) } else { @([bool]$g.GithubPrerelease) }
                foreach ($warmRepo in $reposToWarm) {
                    foreach ($pref in $channelPrefs) {
                        if (-not (Test-CacheFresh $ghDisk $(if ($pref) { "$warmRepo#pre" } else { $warmRepo }))) {
                            $pending += , @{ K = "gh"; A = $warmRepo; P = $pref }
                        }
                    }
                }
            }
            if ($g.GithubRepoB) {
                $bPref = if ($null -ne $g.GithubRepoBPrerelease) { [bool]$g.GithubRepoBPrerelease } else { [bool]$g.GithubPrerelease }
                $bKey = if ($bPref) { "$($g.GithubRepoB)#pre" } else { [string]$g.GithubRepoB }
                if (-not (Test-CacheFresh $ghDisk $bKey)) {
                    $pending += , @{ K = "gh"; A = [string]$g.GithubRepoB; P = $bPref }
                }
            }
            if (-not $g.GithubRepo -and -not $g.GithubRepoB -and $g.WebVersionUrl) {
                if (-not (Test-CacheFresh $webDisk $g.WebVersionUrl)) { $pending += , @{ K = "web"; A = $g.WebVersionUrl; T = $g.Title } }
            }
        }
        # Several catalog tiles can intentionally share one upstream project
        # (RazeXR covers seven games). Hand each remote key to the worker only
        # once so one missing cache entry never becomes seven identical calls.
        $pendingUnique = [ordered]@{}
        foreach ($item in $pending) {
            $key = @([string]$item.K,[string]$item.A,[string]$item.B,[string][bool]$item.P) -join '|'
            if (-not $pendingUnique.Contains($key)) { $pendingUnique[$key] = $item }
        }
        $pending = @($pendingUnique.Values)
        if ($pending.Count -gt 0 -and $versionCacheDir -and -not $global:HubDisableVersionPrewarm) {
            $lockF   = Join-Path $versionCacheDir ".prewarm_worker.lock"
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
                ($pending | ConvertTo-Json) | Set-Content -Path (Join-Path $versionCacheDir ".prewarm_pending.json") -Encoding UTF8 -Force
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
    if ($scanOnlineWatch) { $scanOnlineWatch.Stop(); $scanOnlineMs = $scanOnlineWatch.ElapsedMilliseconds }
    $global:HubVersionCacheOnly = $true

    $found = 0
    $vrFound = 0
    # Snapshot of the keys, not the live collection: the yield below lets
    # other code run, and anything that rebuilds the lookups mid-scan
    # would otherwise break the enumeration.
    $scanDetectionWatch = [System.Diagnostics.Stopwatch]::StartNew()
    foreach ($card in @($global:cardGameMap.Keys)) {
        $game = $global:cardGameMap[$card]
        $scanGameWatch = [System.Diagnostics.Stopwatch]::StartNew()
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
        # Most FREE entries are standalone downloads with no separate base
        # game, so Steam metadata must not gate their availability. Muck and
        # Daggerfall are explicit FreeBaseGame exceptions: they stay in FREE,
        # but an installed unmodded game is also useful Needs Mod evidence.
        $isFreeGame = ($global:FREE_GAME_TITLES -and ($global:FREE_GAME_TITLES -contains $game.Title))
        $isFreeBaseGame = ($isFreeGame -and [bool]$game.FreeBaseGame)
        # Locate support: a game the user pointed the Hub at (via the
        # "Locate install" button) has a recorded path file even without
        # a SteamFolder - let it through so Priority 1 can verify it.
        $locatedGate = $null
        try { $locatedGate = Read-InstalledPath -Game $game } catch {}
        $hasLocated = [bool]$locatedGate
        if (-not $game.SteamFolder -and -not $isFreeGame -and -not $hasLocated) { continue }
        $installed = $false
        $gameDir   = $null

        # Priority 1: a canonical durable path wins as the BASE-GAME path only
        # when it contains the catalog's base-game proof. Some installers store
        # a deliberately separate VR runtime here (DOOM 2016/KHARVOX is the
        # concrete case). Treating that mod root as the game used to skip Steam
        # discovery, then the later base proof rejected it, leaving both
        # Installed and VR Ready false. Keep the path for the VR proof below,
        # but do not let a typed mod root impersonate the base game.
        if ($locatedGate -and (Test-Path -LiteralPath $locatedGate -PathType Container) -and
            (Test-BaseGameInstallProof -Game $game -Root $locatedGate)) {
            $installed = $true
            $gameDir   = $locatedGate
        }

        # A stale legacy receipt still needs cleanup when no valid canonical
        # or imported location resolved. It must never replace Priority 1.
        $installedPathFile = Get-InstalledPathFile -Game $game
        $rawRecordedPath = $null
        if (-not $installed -and $installedPathFile -and (Test-Path $installedPathFile)) {
            try {
                $rawRecordedPath = (Get-Content $installedPathFile -Raw -EA SilentlyContinue)
                if ($rawRecordedPath) { $rawRecordedPath = $rawRecordedPath.Trim() }
            } catch { }
        }
        if (-not $installed -and $rawRecordedPath -and (Test-Path $rawRecordedPath)) {
            $installed = $true
            $gameDir   = $rawRecordedPath
        } elseif (-not $installed -and $rawRecordedPath -and -not (Test-Path $rawRecordedPath)) {
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
        $steamAppIds = @(Get-CatalogSteamAppIds -Game $game)
        if (-not $installed -and (-not $isFreeGame -or $isFreeBaseGame) -and $steamAppIds.Count) {
            foreach ($appId in $steamAppIds) {
                foreach ($lib in $steamLibs) {
                    $acf = Join-Path $lib "steamapps\appmanifest_$appId.acf"
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
                if ($installed) { break }
            }
        }

        # Priority 2: regular Steam library scan.
        # Skipped for standalone free games: their availability never depends
        # on Steam. FreeBaseGame entries deliberately keep this detection so
        # their unmodded Steam install can appear in Needs Mod.
        if (-not $installed -and (-not $isFreeGame -or $isFreeBaseGame)) {
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
        # A durable Locate Game / installer receipt is Priority 1 and must
        # remain authoritative. Static fallbacks are discovery candidates,
        # not permission to replace a path the user explicitly assigned.
        # Depot entries are the deliberate exception: their separate copy
        # can coexist with the normal game path and still has to be found.
        if ($game.FallbackPaths -and (-not $installed -or $game.DepotInstall)) {
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
                        $candidates += [System.IO.Path]::Combine(([string]$lib).TrimEnd([char[]]"\/"), ("steamapps\content$tail").TrimStart([char[]]"\/"))
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

                # The disposable installer lab must never inspect or adopt a
                # real installation on the host PC. Production never defines
                # HubFileSystemLabRoot, so this guard has no runtime effect.
                if ($global:HubFileSystemLabRoot) {
                    $labPrefix = [IO.Path]::GetFullPath([string]$global:HubFileSystemLabRoot).TrimEnd('\') + '\'
                    $candidates = @($candidates | Where-Object {
                        try { [IO.Path]::GetFullPath([string]$_).StartsWith($labPrefix,[StringComparison]::OrdinalIgnoreCase) }
                        catch { $false }
                    })
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
        if ($installed -and $gameDir -and $steamAppIds.Count -and -not $game.DepotInstall) {
            $gdLower = ([string]$gameDir).ToLower()
            $marker  = "\steamapps\common\"
            $idx     = $gdLower.IndexOf($marker)
            if ($idx -ge 0) {
                $libRoot  = ([string]$gameDir).Substring(0, $idx)
                $manifestFound = $false
                foreach ($appId in $steamAppIds) {
                    $manifest = Join-Path $libRoot ("steamapps\appmanifest_" + $appId + ".acf")
                    if (Test-Path -LiteralPath $manifest) { $manifestFound = $true; break }
                }
                if (-not $manifestFound) {
                    # Steam does not have this game installed any more -
                    # what is left in the folder are mod leftovers.
                    $installed = $false
                    $gameDir   = $null
                }
            }
        }

        # Optional strict base-game proof. This rejects a durable path or
        # launcher folder that contains only mod leftovers. It checks a few
        # fixed original files rather than recursively measuring a huge game
        # directory, so it does not reintroduce the old scan delay.
        if ($installed -and -not (Test-BaseGameInstallProof -Game $game -Root $gameDir)) {
            $installed = $false
            $gameDir = $null
            $depotMatched = $false
        }

        # Check if VR mod is installed
        $vrInstalled = $false
        # Depot install: the existence of the STEAM_CONTENT /
        # STEAM_COMMON folder we listed in FallbackPaths is itself
        # proof of a working VR install - that folder only appears
        # after the depot download we orchestrated. Skip all other
        # heuristics for these games.
        # !!! NOT ON ITS OWN. The comment above assumed the folder we
        # matched could only be the depot copy we downloaded. That is
        # false wherever FallbackPaths also lists the PLAIN STEAM
        # INSTALL - Elden Ring and Ready Or Not both do - and then
        # simply owning the game read as "VR Ready" with no mod on disk
        # at all. Martin hit exactly that: motion mod installed, no Luke
        # Ross, and the gamepad tile claimed VR Ready.
        #
        # So the mod's own marker still has to be there. Every
        # DepotInstall entry declares one (checked: all 15), and in a
        # real depot copy it is present, so nothing that genuinely works
        # loses its state.
        if ($depotMatched) {
            if ($game.ModFile) {
                $dmMarker = Join-Path $gameDir $game.ModFile
                if (Test-Path -LiteralPath $dmMarker) {
                    $vrInstalled = $true
                } elseif ($game.ModFileAlt -and (Test-Path -LiteralPath (Join-Path $gameDir $game.ModFileAlt))) {
                    $vrInstalled = $true
                } elseif ($game.ModFileAlt2 -and (Test-Path -LiteralPath (Join-Path $gameDir $game.ModFileAlt2))) {
                    $vrInstalled = $true
                } elseif (Test-AbsoluteModMarker -Game $game) {
                    $vrInstalled = $true
                }
            } else {
                $vrInstalled = $true
            }
        }
        # If this install was placed by our installer (.installed_path exists),
        # we trust that as a strong signal - BUT we still verify the
        # ModFile is actually on disk at the recorded path. Otherwise
        # the user could delete the VR mod manually and the hub would
        # still display "VR Ready" indefinitely (stale state).
        # An absolute marker settles it on its own - it does not depend
        # on any recorded game path.
        if (-not $vrInstalled -and (Test-AbsoluteModMarker -Game $game)) { $vrInstalled = $true }

        $recordedPathFile = Get-InstalledPathFile -Game $game
        # $locatedGate already represents the canonical LocalAppData/Core
        # recovery value (or a proven durable-root migration). A freshly
        # extracted Hub intentionally has no adjacent .installed_path file, so
        # gating this proof on that legacy receipt made a valid external VR
        # runtime invisible after moving to a new Hub copy.
        $recordedPath = $locatedGate
        if (-not $vrInstalled -and $recordedPath -and (Test-Path -LiteralPath $recordedPath -PathType Container)) {
            $recordedEvidenceOk = $true
            foreach ($ev in @($game.VrInstallEvidence)) {
                if ($ev -and -not (Test-Path -LiteralPath (Join-Path $recordedPath ([string]$ev)))) {
                    $recordedEvidenceOk = $false
                    break
                }
            }
            if ($recordedPath -and (Test-Path $recordedPath)) {
                # Recorded path is still valid. If we know what the
                # mod's marker file looks like (ModFile), verify it.
                if ($game.ModFile) {
                    $rp = Join-Path $recordedPath $game.ModFile
                    if ($recordedEvidenceOk -and (Test-Path $rp)) {
                        $vrInstalled = $true
                    } elseif ($recordedEvidenceOk -and $game.ModFileAlt -and (Test-Path (Join-Path $recordedPath $game.ModFileAlt))) {
                        # Alternate marker - e.g. Anomaly is VR-ready via the
                        # new AoeVrLauncher.exe OR the old JSGME.exe.
                        $vrInstalled = $true
                    } elseif ($recordedEvidenceOk -and $game.ModFileAlt2 -and (Test-Path (Join-Path $recordedPath $game.ModFileAlt2))) {
                        $vrInstalled = $true
                    } elseif ($recordedEvidenceOk -and $game.DoorstopTargetModFile -and (Test-DoorstopTargetModMarker -GameRoot $recordedPath -TargetMarker $game.DoorstopTargetModFile -LoaderFile $game.DoorstopLoaderFile)) {
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
                        if ($lrFound -and $recordedEvidenceOk) { $vrInstalled = $true }
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
                        if ($recordedEvidenceOk -and (Test-Path (Join-Path $recordedPath $game.LaunchExe))) { $vrInstalled = $true }
                    } else {
                        $vrInstalled = ($installed -and $recordedEvidenceOk)
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
            # THIRD marker, deliberately narrow (2026-08-20). Four Luke
            # Ross titles put their executable in a DIFFERENT subfolder
            # per store - Xbox builds use WinGDK instead of Win64, and
            # Kingdom Come II has its own folder per store. The mod goes
            # next to that exe, so ModFile (which holds the Steam path)
            # misses those installs: they run fine but the tile never
            # said "VR Ready".
            # ModFileAlt2 is OPTIONAL and only set on those four entries.
            # Anything without it behaves exactly as before - this cannot
            # affect the other 241 games.
            if (-not $modPathFound -and $game.ModFileAlt2) {
                $modPathFound = Test-Path (Join-Path $gameDir $game.ModFileAlt2)
            }
            if (-not $modPathFound -and $game.DoorstopTargetModFile) {
                $modPathFound = Test-DoorstopTargetModMarker -GameRoot $gameDir -TargetMarker $game.DoorstopTargetModFile -LoaderFile $game.DoorstopLoaderFile
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
                # ModFileAlt COUNTS HERE TOO (2026-08-20, found via
                # PEAK): there ModFile holds the file of the CURRENT
                # mod and ModFileAlt the one of the DEPOT build.
                # Anyone who installed the depot build into
                # C:\Games\PEAK VR was never detected, because only
                # ModFile was checked at this spot. A second marker
                # that counts in the game folder must also count at
                # the alternative root.
                if ((-not (Test-Path $altPath)) -and $game.ModFileAlt) {
                    $altPath = Join-Path $altRoot $game.ModFileAlt
                }
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
        $dualModeMultiplePresent = $false
        $dualModeCurrentPresent = $false
        $dualModeDepotPresent = $false
        $dualModeLegacyPresent = $false
        $dualModeCurrentDir  = $null
        $dualModeDepotDir    = $null
        $dualModeLegacyDir   = $null
        if ($game.DualMode) {
            # Mode 1 candidate: any Steam-library steamapps\common\<SteamFolder>
            # that has the ModFile, next to the pinned depot build. Shared
            # probe (above) so the post-install refresh sees the same thing.
            $dmProbe = Get-DualModePresence -Game $game -Libs $steamLibs
            $dualModeCurrentPresent = [bool]$dmProbe.CurrentPresent
            $dualModeDepotPresent   = [bool]$dmProbe.DepotPresent
            $dualModeLegacyPresent  = [bool]$dmProbe.LegacyPresent
            $dualModeCurrentDir     = $dmProbe.CurrentDir
            $dualModeDepotDir       = $dmProbe.DepotDir
            $dualModeLegacyDir      = $dmProbe.LegacyDir
            if ($dmProbe.BothPresent) {
                $dualModeBothPresent = $true
            }
            $dualModeMultiplePresent = [bool]$dmProbe.MultiplePresent
            # Current and depot variants may deliberately use different
            # proof files (Risk of Rain 2's maintained Thunderstore marker
            # versus DrBibop's legacy DLL). Do not require the generic marker
            # pass to succeed before these exact side-specific probes count.
            if ($dmProbe.AnyPresent) {
                $vrInstalled = $true
                # Replace an earlier unmodded base-game hit with the root
                # that supplied the positive VR evidence. Otherwise a normal
                # Steam copy wins Priority 2, the legacy/depot probe turns the
                # tile green, but GameDir still points at the flat Steam game.
                # That misdirects version recovery and any generic detail-page
                # action even though the correct standalone copy was found.
                $gameDir = Get-DualModePreferredRoot -Presence $dmProbe
                $installed = [bool]$gameDir
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
        $twoModsCDir = $null
        $tmAPresent = $false
        $tmBPresent = $false
        $tmCPresent = $false
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
                    $tmCPresent  = $tmProbe.CPresent
                    $twoModsADir = $tmProbe.ADir
                    $twoModsBDir = $tmProbe.BDir
                    $twoModsCDir = $tmProbe.CDir
                    $definedMods = @(Get-AlternativeModDefinitions -Game $game)
                    $presentMods = @($definedMods | Where-Object { [bool](Get-AlternativeModValue $tmProbe ("$($_.Mode)Present")) })
                    if ($presentMods.Count -gt 0) {
                        # If a ModFile is defined (GTA5 verifies RealVR.asi),
                        # require it at the recorded path too - a leftover
                        # launcher alone must NOT read as VR Ready without
                        # the actual VR mod on disk.
                        if ($game.ModFile -and $game.TwoModsRequireBoth) {
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
                    if ($game.TwoModsRequireBoth) { $twoModsAnyPresent = ($definedMods.Count -gt 0 -and $presentMods.Count -eq $definedMods.Count) }
                    else { $twoModsAnyPresent = ($presentMods.Count -gt 0) }
            }
        }

        # Get-TwoModsPresence already probes the known game root, dedicated
        # per-mod records, external roots and absolute markers. Re-probing
        # individual catalog fields here used to bypass its scope rules and
        # could fabricate Mod A from Mod B's shared file (notably Elden Ring
        # and Outward). Its verdict is therefore authoritative.

        # For alternative-mod entries, the per-mod probes above are the
        # authoritative answer. This clears earlier broad signals such as an
        # absolute Hotbite folder or ERVR's generic ModFile when there is no
        # valid game/depot root, and prevents stale common launchers from
        # painting the card VR Ready.
        if ($game.TwoMods -and -not $game.TwoModsRequireBoth) {
            $vrInstalled = [bool]$twoModsAnyPresent
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
            # The user/installer-recorded root is authoritative here as it is
            # for every other title. Only guess the historical C:/D:/E: roots
            # when that durable location no longer resolves.
            $hyRec = $null
            try { $hyRec = Read-InstalledPath -Game $game } catch {}
            if ($hyRec) {
                $hyRecOk = $false
                try {
                    $hyRecOk = (Test-Path -LiteralPath ([System.IO.Path]::Combine($hyRec, "Start Hytale VR.bat"))) -or `
                               (Test-Path -LiteralPath ([System.IO.Path]::Combine($hyRec, "hytale_camera_dashboard.exe")))
                } catch {}
                if ($hyRecOk) { $hyModRoot = $hyRec }
            }
            # [IO.Path]::Combine, NOT Join-Path: Join-Path VALIDATES the
            # drive and throws DriveNotFoundException on machines without
            # a D:/E: drive, which killed this whole detection block
            # (Join-Path returned $null -> Test-Path -LiteralPath $null
            # -> terminating bind error -> "[scan] detection failed").
            # Combine is a pure string op; Test-Path itself handles
            # missing drives gracefully (returns $false, no throw).
            if (-not $hyModRoot) {
                foreach ($hr in @("C:\Games\Hytale VR", "D:\Games\Hytale VR", "E:\Games\Hytale VR")) {
                    if ($global:HubFileSystemLabRoot) { continue }
                    $hyBat  = [System.IO.Path]::Combine($hr, "Start Hytale VR.bat")
                    $hyDash = [System.IO.Path]::Combine($hr, "hytale_camera_dashboard.exe")
                    if ((Test-Path -LiteralPath $hyBat) -or (Test-Path -LiteralPath $hyDash)) { $hyModRoot = $hr; break }
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

        if ($isFreeGame -and -not $isFreeBaseGame -and -not $vrInstalled) { $installed = $false }

        if ($vrInstalled) {
            # For Thunderstore-based mods: query live version and deprecated status
            $needsUpdate  = $false
            # An Update tile must always carry the positive evidence that
            # produced it. Presentation dates are never update evidence.
            $updateEvidence = $null
            # Optional exact alternative slot. This is set only when the
            # evidence itself identifies one and only one installed mod.
            $updateTargetSlot = $null
            # $gameDir is resolved above; hand it over so checked
            # installation-side recovery evidence is available when the
            # canonical LocalAppData value is absent.
            # Current and Depot are independent installations. For catalog
            # entries that opt into Current-route tracking, a shared central
            # value may belong to the pinned Depot and therefore must never be
            # copied into Current before its own marker has been read.
            $routeAwareCurrentUpdate = [bool](($game.CurrentRouteUpdate -or $game.ThunderstoreCurrentRouteUpdate) -and $game.DualMode)
            $installedVer = if ($routeAwareCurrentUpdate) { $null } else { Read-InstalledVersion -Game $game -GameDir $gameDir }
            # Migration/repair pass: once a valid value was found, ensure the
            # canonical state plus game-side recovery evidence exist. Both
            # writers skip identical values, so settled scans remain read-only.
            if ($installedVer -and -not $routeAwareCurrentUpdate) { Write-InstalledVersion -Game $game -Version $installedVer -GameDir $gameDir }

            if ($game.GithubCommitRepo) {
                $commitBranch = if ($game.GithubCommitBranch) { [string]$game.GithubCommitBranch } else { 'main' }
                $commitVer = Get-GithubLatestCommitCached -Repo $game.GithubCommitRepo -Branch $commitBranch
                if ($commitVer) {
                    if (-not $installedVer) {
                        Write-InstalledVersion -Game $game -Version $commitVer -GameDir $gameDir
                    } elseif (Test-OnlineVersionIsNewer -Installed $installedVer -Online $commitVer) {
                        $needsUpdate = $true
                        $updateEvidence = "GitHub branch build $commitVer is newer than installed $installedVer"
                    }
                }
            } elseif ($game.GitHubNightly) {
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
                    # Strip the tag's leading "v" - exactly as in the
                    # Codeberg branch. Otherwise a marker "1.3.18" is
                    # forever unequal to the tag "v1.3.18" and the tile
                    # keeps reporting an update after EVERY install.
                    # ONLY when online is GENUINELY NEWER - an installed
                    # build that is AHEAD must not raise an update badge
                    # (see Test-OnlineVersionIsNewer).
                    } elseif (Test-OnlineVersionIsNewer -Installed $installedVer -Online $ghVer) {
                        $needsUpdate = $true
                        $updateEvidence = "GitHub release $ghVer is newer than installed $installedVer"
                    }
                }
            } elseif ($game.ThunderstoreAuthor -and $game.ThunderstorePackage) {
                # Thunderstore has its own cache and circuit breaker. A failed
                # GitHub/web request earlier in catalog order must not erase a
                # valid Thunderstore update later in the same scan.
                $tsData = Get-ThunderstorePackageCached -Author $game.ThunderstoreAuthor -Package $game.ThunderstorePackage
                if ($tsData) {
                  try {
                    $tsVer  = [string]$tsData.Version
                    $tsDepr = [bool]$tsData.Deprecated

                    # Some authors publish to GitHub first and mirror to
                    # Thunderstore later. PEAK's installer deliberately takes
                    # the newer stable release from either source, so its tile
                    # must use the same rule or a GitHub-only update would stay
                    # invisible. Opt-in keeps every other Thunderstore entry's
                    # existing channel behavior unchanged.
                    if ($game.UpdateCheckBothSources -and $game.GithubRepo) {
                        $ghAlso = Get-GithubLatestTagCached -Repo $game.GithubRepo -IncludePrerelease:$false
                        if ($ghAlso -and (Test-OnlineVersionIsNewer -Installed $tsVer -Online $ghAlso)) { $tsVer = $ghAlso }
                    }

                    # Read the exact Current/confirmed-depot package marker.
                    # For opt-in multi-route games this deliberately refuses
                    # a Legacy version from a different mod/version namespace.
                    $tsRoute = Get-ThunderstoreRouteInstallState -Game $game -Presence $dmProbe `
                        -GameDir $gameDir -FallbackVersion $installedVer
                    $installedVer = $tsRoute.Version

                    # ONLY when Thunderstore is GENUINELY NEWER. PEAK VR
                    # is now installed from GitHub (1.4.1) while the check
                    # runs against Thunderstore (1.4.0) - an inequality
                    # test made the tile show a permanent update that does
                    # not exist.
                    if (-not $tsDepr -and $tsRoute.CurrentMissing -and $routeAwareCurrentUpdate) {
                        $needsUpdate = $true
                        $updateEvidence = "Current Thunderstore release $tsVer is available; only the pinned $($tsRoute.Route) route is installed"
                    } elseif (-not $tsDepr -and $tsRoute.UnversionedCurrent -and $routeAwareCurrentUpdate) {
                        $needsUpdate = $true
                        $updateEvidence = "Current Thunderstore release $tsVer is available; installed Current route has no package-version marker"
                    } elseif (-not $tsDepr -and $installedVer -and (Test-OnlineVersionIsNewer -Installed $installedVer -Online $tsVer)) {
                        $needsUpdate = $true
                        $updateEvidence = "Thunderstore release $tsVer is newer than installed $($tsRoute.Route) $installedVer"
                        # Do NOT pin installed_version to the OLD value
                        # here - the .ts_versions/ file already holds
                        # the truth and we resync the Hub cache after
                        # the user installs the update.
                    } elseif (-not $installedVer -and -not $tsDepr -and -not $tsRoute.RouteSpecific) {
                        Write-InstalledVersion -Game $game -Version $tsVer -GameDir $gameDir
                    } elseif ($installedVer) {
                        # Equal OR installed is ahead - both mean "up to
                        # date". The cache gets the value that is ACTUALLY
                        # installed.
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
                    $updateEvidence = 'obsolete Anomaly VR folder layout is present'
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
                    if ($ghVer -and (Test-OnlineVersionIsNewer -Installed $hyInst -Online $ghVer)) {
                        $needsUpdate = $true
                        $updateEvidence = "GitHub release $ghVer is newer than installed Hytale build $hyInst"
                    }
                } else {
                    # 1.0.0+ always ships CHANGELOG.md, so its absence means a
                    # pre-1.0 install - flag the update regardless of whatever
                    # the old seeding may have stamped on. Self-correcting:
                    # after the update the CHANGELOG is there and drives the
                    # comparison from then on.
                    $needsUpdate = $true
                    $updateEvidence = 'installed Hytale build predates the release-owned CHANGELOG identity'
                }
            } elseif ($game.GithubRepoB -or ($game.TwoMods -and $game.GithubRepo -and $game.GithubRepoPresenceFile)) {
                # TWO INDEPENDENT MODS IN ONE TILE (BioShock: balouza and
                # BioVRDev). Each mod has its own repo and its own version
                # marker, and a repo is only checked when THAT mod is really
                # on disk - a balouza release must never raise an Update
                # badge on a BioVRDev-only install. With both installed,
                # either repo can raise it. Presence is decided by the file
                # each mod parks in its own store; both fields may list
                # alternatives separated by "|" (Steam's Build\Final and
                # Epic's Build\FinalEpic).
                $twoPairs = @()
                if ($game.TwoMods) {
                    if (-not $tmProbe) { $tmProbe = Get-TwoModsPresence -Game $game -FallbackRoot $gameDir }
                    $repoAPre = Get-GithubPrereleasePreference -Game $game -GameDir $gameDir
                    $repoBPre = if ($null -ne $game.GithubRepoBPrerelease) { [bool]$game.GithubRepoBPrerelease } else { [bool]$game.GithubPrerelease }
                    # Release slot (A/B) and physical mod slot are independent.
                    # FH6 keeps NALULUNA as Mod A, while its two GitHub-fed
                    # launchers are physical Mods B and C. Explicit mapping
                    # prevents either repo from raising an update on the wrong
                    # installed package.
                    $repoAModSlot = if ($game.GithubRepoModSlot) { [string]$game.GithubRepoModSlot } else { 'A' }
                    $repoBModSlot = if ($game.GithubRepoBModSlot) { [string]$game.GithubRepoBModSlot } else { 'B' }
                    $twoDefs = @(
                        @{ Present = [bool](Get-AlternativeModValue $tmProbe ("Mod${repoAModSlot}Present")); Root = Get-AlternativeModValue $tmProbe ("Mod${repoAModSlot}Root"); Probe = $game.GithubRepoPresenceFile;  VersionFile = $game.GithubRepoVersionFile;  Repo = $game.GithubRepo;  Slot = 'A'; TargetSlot = $repoAModSlot; Prerelease = $repoAPre },
                        @{ Present = [bool](Get-AlternativeModValue $tmProbe ("Mod${repoBModSlot}Present")); Root = Get-AlternativeModValue $tmProbe ("Mod${repoBModSlot}Root"); Probe = $game.GithubRepoBPresenceFile; VersionFile = $game.GithubRepoBVersionFile; Repo = $game.GithubRepoB; Slot = 'B'; TargetSlot = $repoBModSlot; Prerelease = $repoBPre }
                    )
                    foreach ($td in $twoDefs) {
                        if (-not $td.Present -or -not $td.Repo -or -not $td.Root) { continue }
                        if ($td.Probe -and -not (Test-RelativePathMarker -Root $td.Root -Values $td.Probe)) { continue }
                        $twoPairs += , $td
                    }
                } else {
                    $twoRootV = $null
                    try { $twoRootV = Read-InstalledPath -Game $game } catch {}
                    if (-not $twoRootV) { $twoRootV = $gameDir }
                    if ($twoRootV -and (Test-Path -LiteralPath $twoRootV)) {
                        $repoAPre = Get-GithubPrereleasePreference -Game $game -GameDir $twoRootV
                        $repoBPre = if ($null -ne $game.GithubRepoBPrerelease) { [bool]$game.GithubRepoBPrerelease } else { [bool]$game.GithubPrerelease }
                        foreach ($td in @(
                            @{ Probe = $game.GithubRepoPresenceFile;  VersionFile = $game.GithubRepoVersionFile;  Repo = $game.GithubRepo;  Slot = 'A'; Root = $twoRootV; Prerelease = $repoAPre },
                            @{ Probe = $game.GithubRepoBPresenceFile; VersionFile = $game.GithubRepoBVersionFile; Repo = $game.GithubRepoB; Slot = 'B'; Root = $twoRootV; Prerelease = $repoBPre }
                        )) {
                            if ($td.Probe -and $td.Repo -and (Test-RelativePathMarker -Root $twoRootV -Values $td.Probe)) { $twoPairs += , $td }
                        }
                    }
                }
                $githubUpdateTargetSlots = New-Object 'System.Collections.Generic.List[string]'
                $githubUpdateEvidence = New-Object 'System.Collections.Generic.List[string]'
                foreach ($tp in $twoPairs) {
                    $tag = Get-GithubLatestTagCached -Repo $tp.Repo -IncludePrerelease:([bool]$tp.Prerelease)
                    if (-not $tag) { continue }
                    $versionRoot = [string]$tp.Root
                    $have = $null
                    # A build-owned marker can carry the exact release tag.
                    # Prefer it over legacy shared A/B stamps when a catalog
                    # entry changes which of its two builds is primary.
                    if ($tp.VersionFile) {
                        # A retained legacy layout may keep the same release
                        # marker in a second relative location. Arrays and
                        # pipe-separated values are both accepted, just like
                        # the presence probes used by the same catalog entry.
                        foreach ($rawVersionFile in @($tp.VersionFile)) {
                            foreach ($relativeVersionFile in (([string]$rawVersionFile) -split '\|')) {
                                if ([string]::IsNullOrWhiteSpace($relativeVersionFile)) { continue }
                                try {
                                    $separator = [string][IO.Path]::DirectorySeparatorChar
                                    $nativeVersionFile = $relativeVersionFile.Trim().Replace('\', $separator).Replace('/', $separator)
                                    $have = Read-VersionStampFile -Path (Join-Path $versionRoot $nativeVersionFile)
                                } catch {}
                                if ($have) { break }
                            }
                            if ($have) { break }
                        }
                    }
                    if (-not $have) {
                        $have = if ($tp.Slot -eq 'B') { Read-InstalledVersionB -Game $game -GameDir $versionRoot }
                                else { Read-InstalledVersion -Game $game -GameDir $versionRoot }
                    }
                    if ($have) {
                        if ($tp.Slot -eq 'B') { Write-InstalledVersionB -Game $game -Version $have -GameDir $versionRoot }
                        else { Write-InstalledVersion -Game $game -Version $have -GameDir $versionRoot }
                    }
                    if ([string]::IsNullOrWhiteSpace($have)) {
                        # First scan after an install: seed, don't nag.
                        if ($tp.Slot -eq 'B') { Write-InstalledVersionB -Game $game -Version $tag -GameDir $versionRoot }
                        else { Write-InstalledVersion -Game $game -Version $tag -GameDir $versionRoot }
                    } elseif (Test-OnlineVersionIsNewer -Installed $have -Online $tag) {
                        [void]$githubUpdateEvidence.Add("GitHub release $tag is newer than installed alternative-build version $have")
                        if ($game.TwoMods -and $tp.TargetSlot -match '^[A-H]$') {
                            [void]$githubUpdateTargetSlots.Add([string]$tp.TargetSlot)
                        }
                    }
                }
                if ($githubUpdateEvidence.Count -gt 0) {
                    $needsUpdate = $true
                    $updateEvidence = ($githubUpdateEvidence -join '; ')
                    $uniqueGithubTargets = @($githubUpdateTargetSlots | Sort-Object -Unique)
                    if ($uniqueGithubTargets.Count -eq 1) { $updateTargetSlot = [string]$uniqueGithubTargets[0] }
                }
            } elseif ($game.GithubRepo) {
                # GitHub release check: latest tag vs the installed version.
                # Mirrors the Thunderstore branch above. Seeds the cache on
                # the first scan after install (GitHub installers always pull
                # releases/latest, so "no stored version yet" = current latest).
                # Honor an AV-fallback choice from either the durable game-side
                # source marker or the Hub cache.
                $repoToCheck = Get-SelectedGithubRepo -Game $game -GameDir $gameDir
                $checkPrerelease = Get-GithubPrereleasePreference -Game $game -GameDir $gameDir
                $ghVer = Get-GithubLatestTagCached -Repo $repoToCheck -IncludePrerelease:$checkPrerelease
                if ($ghVer) {
                    $releaseRoute = Get-CurrentRouteInstallState -Game $game -Presence $dmProbe `
                        -GameDir $gameDir -FallbackVersion $installedVer -Source Release
                    if ($routeAwareCurrentUpdate) {
                        $installedVer = $releaseRoute.Version
                    }
                    if ($routeAwareCurrentUpdate -and $releaseRoute.CurrentMissing) {
                        $needsUpdate = $true
                        $updateEvidence = "Current GitHub release $ghVer is available; only the pinned $($releaseRoute.Route) route is installed"
                    } elseif ($routeAwareCurrentUpdate -and $releaseRoute.UnversionedCurrent) {
                        $needsUpdate = $true
                        $updateEvidence = "Current GitHub release $ghVer is available; installed Current route has no release-version marker"
                    } elseif (-not $installedVer) {
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
                    # Strip the tag's leading "v" - exactly as in the
                    # Codeberg branch. Otherwise a marker "1.3.18" is
                    # forever unequal to the tag "v1.3.18" and the tile
                    # keeps reporting an update after EVERY install.
                    # ONLY when online is GENUINELY NEWER - an installed
                    # build that is AHEAD must not raise an update badge
                    # (see Test-OnlineVersionIsNewer).
                    } elseif (Test-OnlineVersionIsNewer -Installed $installedVer -Online $ghVer) {
                        $needsUpdate = $true
                        $updateEvidence = "GitHub release $ghVer is newer than installed $installedVer"
                    } elseif ($routeAwareCurrentUpdate) {
                        # The route-owned proof is exact and can safely repair
                        # the shared durable value after a Depot installer ran.
                        Write-InstalledVersion -Game $game -Version $installedVer -GameDir $releaseRoute.Root
                    }
                }
            } elseif ($game.CodebergRepo) {
                # Like the GitHub branch above, only against Codeberg.
                # Same rules: a missing marker is seeded with the current
                # tag ("no marker = the newest was just installed") unless
                # NoVersionSeed says otherwise; if the marker differs from
                # the tag, an update badge appears.
                $cbVer = Get-CodebergLatestTagCached -Repo $game.CodebergRepo -IncludePrerelease:([bool]$game.CodebergPrerelease)
                if ($cbVer) {
                    if (-not $installedVer) {
                        if (-not $game.NoVersionSeed) {
                            Write-InstalledVersion -Game $game -Version $cbVer -GameDir $gameDir
                            $installedVer = $cbVer
                        }
                    } elseif (Test-OnlineVersionIsNewer -Installed $installedVer -Online $cbVer) {
                        $needsUpdate = $true
                        $updateEvidence = "Codeberg release $cbVer is newer than installed $installedVer"
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
                    } elseif (Test-OnlineVersionIsNewer -Installed $installedVer -Online $wv) {
                        $needsUpdate = $true
                        $updateEvidence = "published web release $wv is newer than installed $installedVer"
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
                    # The mod is present, but without a version identity its
                    # age is unknown. Do not turn missing evidence into an
                    # Update claim; a Hub-managed install will write the exact
                    # marker and become comparable from that point onward.
                } else {
                    $ivDigits = ("$lrInst" -replace '[^\d]','')
                    if ($nvDigits -and $ivDigits -and ([int64]$nvDigits -gt [int64]$ivDigits)) {
                        $needsUpdate = $true
                        $updateEvidence = "published REAL build $($global:REALVR_NEWEST) is newer than installed $lrInst"
                    }
                }
            } else {
                # Manual/authenticated source: compare an exact hidden build id
                # first, then fall back to a legacy version embedded in Mod.
                # Catalog release dates are presentation metadata only and are
                # NEVER allowed to decide whether an installed build is older.
                $expectedVer = if ($game.TrackedVersion) {
                    ([string]$game.TrackedVersion).Trim()
                } else {
                    Get-ModVersionFromString -ModString $game.Mod
                }
                if ($expectedVer) {
                    if (-not $installedVer) {
                        Write-InstalledVersion -Game $game -Version $expectedVer -GameDir $gameDir
                        $installedVer = $expectedVer
                    } elseif (Test-OnlineVersionIsNewer -Installed $installedVer -Online $expectedVer) {
                        $needsUpdate = $true
                        $updateEvidence = "reviewed manual build $expectedVer is newer than installed $installedVer"
                    }
                }
            }

            # Evidence-only checks for manual-download mods. Exact variants
            # are a version file written by the installer or a reviewed binary
            # build timestamp from the distributed archive. A catalog release
            # date is deliberately not consulted here: it describes a release,
            # not the identity of a particular DLL already on the user's PC.
            # ModBuildStamp = "yyyy-MM-dd HH:mm"
            # is the LastWriteTime the modder's own build carries INSIDE
            # the zip. Zip extraction preserves that timestamp, so every
            # install of a given build has the same stamp on disk - no
            # matter WHEN it was extracted. An older build therefore
            # always reads older, and a fresh one always reads current.
            # A 2h slack absorbs timezone/DST oddities in zip stamps.
            # MOST RELIABLE VARIANT: a version file the installer itself
            # wrote into the game folder. ModVersionFile = path relative to
            # the game folder, ModVersion = what a current install contains.
            # A written version is not a guess.
            # File present -> AUTHORITATIVE, the timestamp checks are skipped.
            # File missing (installed before this existed, or by hand) ->
            # fall through to the old behaviour, nothing gets worse.
            # ModOutdatedFile: a file that ONLY the old layout has. Unlike
            # ModLegacyFile below it does not care whether the current ModFile
            # is there too - some mods keep the same marker across a
            # restructure, so its presence proves nothing. F.E.A.R. VR is that
            # case: bin\x64\fearvr-host.exe exists in both generations, while
            # tools\install.ps1 exists only in the pre-overlay one.
            #
            # ModA/B/CUpdateRequiredFile is the equivalent for a particular
            # alternative mod on a shared tile. The primary probe continues
            # to detect an old manual build so it can still be launched or
            # removed; a missing reviewed-release proof raises Update only
            # for the slot that is actually installed. This is used for
            # sources such as authenticated Discord posts where no live API
            # version comparison is possible.
            if (-not $needsUpdate -and $game.TwoMods) {
                if (-not $tmProbe) { $tmProbe = Get-TwoModsPresence -Game $game -FallbackRoot $gameDir }
                $migrationUpdate = Get-AlternativeMigrationUpdate -Game $game -Presence $tmProbe
                if ($migrationUpdate) {
                    $needsUpdate = $true
                    $updateTargetSlot = [string]$migrationUpdate.ToSlot
                    $updateEvidence = [string]$migrationUpdate.Evidence
                }
            }

            if (-not $needsUpdate -and $game.TwoMods) {
                if (-not $tmProbe) { $tmProbe = Get-TwoModsPresence -Game $game -FallbackRoot $gameDir }
                $manualUpdateTargets = @(Get-AlternativeModsNeedingManualUpdate -Game $game -Presence $tmProbe)
                if ($manualUpdateTargets.Count -gt 0) {
                    $needsUpdate = $true
                    $manualNames = @($manualUpdateTargets | ForEach-Object { if ($_.Name) { $_.Name } else { "Mod $($_.Slot)" } })
                    $updateEvidence = (($manualNames -join ', ') + ' is missing its required current-release proof file')
                    if ($manualUpdateTargets.Count -eq 1) { $updateTargetSlot = [string]$manualUpdateTargets[0].Slot }
                }
            }

            if (-not $needsUpdate -and $game.ModOutdatedFile -and $gameDir) {
                try {
                    if (Test-Path -LiteralPath (Join-Path $gameDir $game.ModOutdatedFile)) {
                        $needsUpdate = $true
                        $updateEvidence = "obsolete release-only file is present: $($game.ModOutdatedFile)"
                    }
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
                        $updateEvidence = "legacy file exists while its current replacement is absent: $($game.ModLegacyFile)"
                    }
                } catch {}
            }

            # ModRequiredFile: a file a COMPLETE install MUST have. If the
            # mod is present (ModFile there) but this file is NOT, then it
            # was installed with an older recipe - e.g. before a dependency
            # was added. This is the mirror image of ModLegacyFile: there
            # an OLD file betrays the old state, here a MISSING file
            # betrays the incomplete one.
            # Without this case nobody with a merely incomplete install
            # would ever see an update - the main mod's version has not
            # changed, after all.
            if (-not $needsUpdate -and $game.ModRequiredFile -and $game.ModFile -and $gameDir) {
                try {
                    if ((Test-Path -LiteralPath (Join-Path $gameDir $game.ModFile)) -and
                        -not (Test-Path -LiteralPath (Join-Path $gameDir $game.ModRequiredFile))) {
                        $needsUpdate = $true
                        $updateEvidence = "installed mod is missing required release file: $($game.ModRequiredFile)"
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
                        $vfExpected = ([string]$game.ModVersion).Trim()
                        if (Test-OnlineVersionIsNewer -Installed $vfHave -Online $vfExpected) {
                            $needsUpdate = $true
                            $updateEvidence = "release-owned version file has $vfHave; reviewed build is $vfExpected"
                        }
                    }
                } catch {}
            }

            if (-not $verFileDecided -and -not $needsUpdate -and $game.ModBuildStamp -and $game.ModFile -and $gameDir) {
                try {
                    $bsFile = Join-Path $gameDir $game.ModFile
                    if (Test-Path -LiteralPath $bsFile) {
                        $bsDate = [DateTime]::ParseExact([string]$game.ModBuildStamp, 'yyyy-MM-dd HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)
                        $bsItem = Get-Item -LiteralPath $bsFile -ErrorAction Stop
                        if ($bsItem.LastWriteTime -lt $bsDate.AddHours(-2)) {
                            $needsUpdate = $true
                            $updateEvidence = "installed release binary predates reviewed archive build stamp $($game.ModBuildStamp)"
                        }
                    }
                } catch {}
            }

            if ($needsUpdate) {
                if (-not $updateEvidence) {
                    # Fail closed: an unaccounted boolean must never be enough
                    # to paint a tile blue. Every future update path has to
                    # name its evidence explicitly.
                    $needsUpdate = $false
                    Write-Host ("[UpdateCheck] Ignored unproven update state for '" + $game.Title + "'.") -ForegroundColor Yellow
                } else {
                    # A scan may run several times in one session (startup,
                    # user scan, post-install refresh). Repeating the same 20+
                    # evidence lines on every pass makes the diagnostic log
                    # look alarming while adding no information. Log a game's
                    # evidence once, and again only when the reason changes.
                    $evidenceKey = if ($game.Id) { [string]$game.Id } else { [string]$game.Title }
                    $evidenceValue = [string]$updateEvidence
                    if (-not $script:LoggedUpdateEvidence.ContainsKey($evidenceKey) -or
                        $script:LoggedUpdateEvidence[$evidenceKey] -cne $evidenceValue) {
                        Write-Host ("[UpdateCheck] " + $game.Title + ": " + $updateEvidence) -ForegroundColor DarkCyan
                        $script:LoggedUpdateEvidence[$evidenceKey] = $evidenceValue
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
                $updateUiState = @{ UpdateTargetSlot = $updateTargetSlot }
                $updateActionLabel = Get-UpdateActionLabel -Game $game -State $updateUiState -Fallback 'Update Mod'
                if ($btnTxt) {
                    $btnTxt.Text       = $updateActionLabel
                    $btnTxt.Foreground = [System.Windows.Media.Brushes]::White
                }
                $reloadForUpdate = $card.Resources.Item("reloadPill")
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
                $stateEntry = @{ Tag="vrupdate"; Accent=$accentHex; State="update"; BtnText=$updateActionLabel; UpdateEvidence=$updateEvidence; UpdateTargetSlot=$updateTargetSlot; DualMode=$dualModeBothPresent; RouteSplit=$dualModeMultiplePresent; CurrentPresent=$dualModeCurrentPresent; DepotPresent=$dualModeDepotPresent; LegacyPresent=$dualModeLegacyPresent; CurrentDir=$dualModeCurrentDir; DepotDir=$dualModeDepotDir; LegacyDir=$dualModeLegacyDir; TwoMods=$twoModsAnyPresent; GameDir=$gameDir }
                if ($game.TwoMods) { Set-AlternativeModStateFields -State $stateEntry -Game $game -Presence $tmProbe }
                $global:gameStateMap[$game.Title] = $stateEntry
                if ($reloadForUpdate) {
                    $updateLayout = Get-CardUpdateActionLayout -State $stateEntry
                    $reloadForUpdate.ToolTip = if ($updateLayout.PillAction -eq 'Update') { $updateActionLabel } else { 'Start in VR' }
                }
                if ($game.TwoMods -or $game.DualMode) { Update-AlternativeModSplit -Card $card }
            } else {
                # VR Ready: shift the whole card to a calm green tint.
                # Button becomes outline-style with checkmark.
                $card.Background  = New-CardTintBrush -BaseHex "#16161a" -TintHex "#46a05a" -TopAlpha 0.10 -MidAlpha 0.02
                $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1d2e22")
                $card.Effect = $null
                $card.Tag = "vrinstalled"
                $reloadForReady = $card.Resources.Item("reloadPill")
                if ($reloadForReady) { $reloadForReady.ToolTip = 'Reinstall Mod' }
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
                $stateEntry = @{ Tag="vrinstalled"; Accent=$accentHex; State="ready"; BtnText="VR Ready"; GameDir=$gameDir; DualMode=$dualModeBothPresent; RouteSplit=$dualModeMultiplePresent; CurrentPresent=$dualModeCurrentPresent; DepotPresent=$dualModeDepotPresent; LegacyPresent=$dualModeLegacyPresent; CurrentDir=$dualModeCurrentDir; DepotDir=$dualModeDepotDir; LegacyDir=$dualModeLegacyDir; TwoMods=$twoModsAnyPresent }
                if ($game.TwoMods) { Set-AlternativeModStateFields -State $stateEntry -Game $game -Presence $tmProbe }
                $global:gameStateMap[$game.Title] = $stateEntry
                if ($game.TwoMods -or $game.DualMode) { Update-AlternativeModSplit -Card $card }
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
                $global:InstalledScanFailedGames[$game.Title] = $true
                if (-not $global:ScanGameErrors) { $global:ScanGameErrors = New-Object System.Collections.ArrayList }
                [void]$global:ScanGameErrors.Add(("{0}: {1}" -f $game.Title, $_.Exception.Message))
                Write-Host ("  [scan] detection failed for '" + $game.Title + "': " + $_.Exception.Message) -ForegroundColor Yellow
            } catch {}
        } finally {
            if ($scanGameWatch) {
                $scanGameWatch.Stop()
                if ($global:HubScanTrace -and $scanGameWatch.ElapsedMilliseconds -ge 50) {
                    Write-Host ("[ScanTrace] {0}={1}ms" -f $game.Title,$scanGameWatch.ElapsedMilliseconds)
                }
                if ($scanGameWatch.ElapsedMilliseconds -ge 250) {
                    [void]$scanSlowGames.Add(("{0}={1}ms" -f $game.Title, $scanGameWatch.ElapsedMilliseconds))
                }
            }
        }
}
    if ($scanDetectionWatch) { $scanDetectionWatch.Stop(); $scanDetectionMs = $scanDetectionWatch.ElapsedMilliseconds }

    # Update the counter button. Pre-scan it showed "Check Installed"
    # in CheckInstalledText; post-scan we hide that and reveal the
    # CheckInstalledCount StackPanel where the numbers ("47" / "42")
    # live in their own ExtraBold + #5fff8f TextBlocks so they pop
    # against the surrounding muted "installed" / "VR ready" labels.
    # If no VR-ready games were found we hide the separator + VR
    # ready segment entirely to keep the button compact.
    if ($checkInstalledText) {
        $checkInstalledText.Visibility = [System.Windows.Visibility]::Collapsed
        # Undo the scanning state: the font size and the second
        # magnifier belonged to "Scanning..." only. Without this the
        # right-hand magnifier would sit next to the finished counter.
        $checkInstalledText.FontSize = 12
    }
    $magRightDone = $global:window.FindName("CheckInstalledMagRight")
    if ($magRightDone) { $magRightDone.Visibility = [System.Windows.Visibility]::Collapsed }
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
    # With zero games on the PC the separator is collapsed, leaving the
    # play triangle immediately against the C in "PC". Four WPF units are
    # roughly one millimetre at 96 DPI. Keep the established spacing when
    # the separator is visible.
    if ($checkInstalledReadyIcon) {
        $iconLeft = if ($vrFound -eq 0) { 4 } else { 0 }
        $checkInstalledReadyIcon.Margin = [System.Windows.Thickness]::new($iconLeft, 0, 5, 0)
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
    if (Get-Command Complete-HubStateBatch -ErrorAction SilentlyContinue) { Complete-HubStateBatch }
    try { if (Get-Command Stop-ScanSpinner -ErrorAction SilentlyContinue) { Stop-ScanSpinner } } catch {}

    # Hand the window back to the user.
    Unlock-ScanUi
    try { if ($script:scanPumpWatch) { $script:scanPumpWatch.Stop() } } catch {}
    $script:scanPumpWatch = $null

    # Check finished: re-enable + re-arm the Scan-on-Startup hover toggle.
    $global:ScanInProgress = $false
    $global:InstalledScanCompleted = $true
    if ($scanTotalWatch) {
        $scanTotalWatch.Stop()
        Write-Host ("[Scan] completed in {0} ms (online/cache {1} ms, detection {2} ms, UI/finalize {3} ms); {4} on PC, {5} VR Ready, {6} errors." -f `
            $scanTotalWatch.ElapsedMilliseconds, $scanOnlineMs, $scanDetectionMs,
            [Math]::Max(0, ($scanTotalWatch.ElapsedMilliseconds - $scanOnlineMs - $scanDetectionMs)),
            $found, $vrFound, $global:InstalledScanFailedGames.Count)
        if ($scanSlowGames.Count -gt 0) {
            Write-Host ("[Scan] slow entries: " + ($scanSlowGames -join '; '))
        }
    }
    if ($global:InstalledScanFailedGames.Count -gt 0 -and (Get-Command Write-HubActionFailure -ErrorAction SilentlyContinue)) {
        Write-HubActionFailure -Action 'Scan installed games' `
            -Message ("The scan finished, but {0} game entr{1} could not be checked. The remaining results are valid." -f `
                $global:InstalledScanFailedGames.Count, $(if ($global:InstalledScanFailedGames.Count -eq 1) { 'y' } else { 'ies' }))
    }
    if (Get-Command Update-UninstallGuideLinks -ErrorAction SilentlyContinue) { Update-UninstallGuideLinks }
    if (Get-Command Update-DetailReadmeLinks -ErrorAction SilentlyContinue) { Update-DetailReadmeLinks }
    $cosbEnd = $global:window.FindName("CheckOnStartupBtn")
    if ($cosbEnd) { $cosbEnd.IsEnabled = $true; $cosbEnd.Visibility = [System.Windows.Visibility]::Hidden }

    # An installer finished while this scan was running - do the refresh it
    # asked for now that the collections are stable again.
    if ($global:PostInstallRefreshPending) {
        $global:PostInstallRefreshPending = $false
        try {
            [void]$global:window.Dispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                [action]{ Invoke-PostInstallRefreshSafely })
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
    $global:HubThunderstoreOnlineDown = $false
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
                $scanFailure = $_
                Fail-InstalledScan -ErrorRecord $scanFailure
            }
            finally { $global:ScanQueued = $false }
        })
}.GetNewClosure())
