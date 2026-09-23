# Fast, disk-only version sources used by the visible post-install refresh.
# Network sources are deliberately excluded: this function runs on WPF's UI
# thread and must finish before the activity presentation is restored.
function global:Get-PostInstallLocalTrackedVersion {
    param($Game,[string]$GameDir)
    if (-not $Game) { return $null }
    if ($Game.ThunderstoreAuthor -and $Game.ThunderstorePackage -and $GameDir) {
        foreach ($key in @("$($Game.ThunderstoreAuthor)-$($Game.ThunderstorePackage)","$($Game.ThunderstorePackage)")) {
            try {
                $path=Join-Path $GameDir "BepInEx\.ts_versions\$key"
                if (Test-Path -LiteralPath $path -PathType Leaf) {
                    $value=([IO.File]::ReadAllText($path)).Trim()
                    if (Test-IsTrackableInstalledVersion -Version $value) { return $value }
                }
            } catch {}
        }
    }
    if ($Game.TrackedVersion -and (Test-IsTrackableInstalledVersion -Version $Game.TrackedVersion)) {
        return ([string]$Game.TrackedVersion).Trim()
    }
    $fromLabel=Get-ModVersionFromString -ModString $Game.Mod
    if (Test-IsTrackableInstalledVersion -Version $fromLabel) { return $fromLabel }
    return $null
}

# Post-install auto-refresh: when an installer cmd.exe exits,
# we want the Hub to silently re-render the detail page so the
# user sees the new INSTALLED pill and green VR Ready button
# immediately, without manually clicking Check Installed.
#
# IMPORTANT: scope-respecting behaviour. Installation changes one catalog
# entry, so this route always verifies and repaints only that process-bound
# game. It never forces a full library scan the user did not request.
# Called from the DispatcherTimer poll above (see the install button click
# handler in the detail view), which detects when the launched wrapper really
# terminates. A status file is success evidence only and never an end signal.
function global:Test-PostInstallRefreshScanActive {
    if (-not $global:ScanInProgress) { return $false }
    $alive = $false
    try { $alive = ($script:scanHeartbeat -and ((Get-Date) - $script:scanHeartbeat).TotalSeconds -lt 60) } catch {}
    if ($alive) { return $true }

    # Use the same stale-heartbeat recovery as the scan entry point. A dead
    # scan must not swallow an installer completion forever merely because its
    # old global lock survived.
    $global:ScanInProgress = $false
    $global:ScanQueued = $false
    try { Unlock-ScanUi } catch {}
    try { if (Get-Command Stop-ScanSpinner -ErrorAction SilentlyContinue) { Stop-ScanSpinner } } catch {}
    return $false
}

function global:Resolve-PostInstallRefreshState {
    param($PreviousState, $CandidateState, [bool]$ConfirmedInstallerSuccess)
    if (-not $ConfirmedInstallerSuccess -and $PreviousState -and $PreviousState.State -eq 'update') {
        return $PreviousState
    }
    return $CandidateState
}

function global:Resolve-PostInstallRefreshTarget {
    param([string]$GameId = '', [string]$Title = '')
    if (-not $GameId) { $GameId = '' + $global:PendingInstallGameId }
    if (-not $Title) { $Title = '' + $global:PendingInstallTitle }
    $game = $null
    $games=@($ownGames + $ownGamesGP + $externalGames)
    foreach ($candidate in $games) {
        $candidateId = if (Get-Command Get-HubGameStateId -ErrorAction SilentlyContinue) { '' + (Get-HubGameStateId -Game $candidate) } else { '' + $candidate.Id }
        if ($GameId -and $candidateId -eq $GameId) { $game = $candidate; break }
    }
    if (-not $game -and $Title) {
        foreach ($candidate in $games) {
            if ($candidate.Title -eq $Title) { $game=$candidate; break }
        }
    }
    return [pscustomobject]@{ Game=$game; GameId=$GameId; Title=$(if ($game) { [string]$game.Title } else { $Title }) }
}

# Disk and state probing is deliberately isolated from WPF. This function may
# run synchronously for tests/fallbacks or inside the private post-install
# runspace. It never touches a card, tile or other Dispatcher-owned object.
function global:Get-PostInstallDetectionSnapshot {
    param($Game,[string]$Title,$PreviousState=$null)
    $result=[ordered]@{
        Action='None'; Title=$Title; Game=$Game; StateEntry=$null; RecordedPath=''
        ConfirmedInstallerSuccess=$false
    }
    if (-not $Game) { return [pscustomobject]$result }
    $confirmedInstallerSuccess=$false

    # Consume the process-bound transaction and perform all receipt migration
    # on this worker too. Those calls can touch several recovery files and were
    # the largest remaining source of UI-thread stalls.
    $okMk=Get-UpdateOkMarkerPath -Game $Game
    if ($okMk -and (Test-Path -LiteralPath $okMk -PathType Leaf)) {
        $status=$null
        try { $status=Get-Content -LiteralPath $okMk -Raw -ErrorAction Stop | ConvertFrom-Json } catch {}
        $confirmedSuccess=[bool]($status -and ([string]$status.outcome -eq 'success'))
        if ($confirmedSuccess) { $confirmedInstallerSuccess=$true }
        $primaryWritten=[bool]($confirmedSuccess -and $status.versionWritten)
        $secondaryWritten=[bool]($confirmedSuccess -and $status.versionBWritten)
        if ($confirmedSuccess -and $status.installedPath -and (Test-Path -LiteralPath ([string]$status.installedPath) -PathType Container)) {
            Write-PersistentGameStateValue -Game $Game -Name 'installed_path' -Value ([string]$status.installedPath)
        }
        $pendDir=$null
        try { $pendDir=Read-InstalledPath -Game $Game } catch {}
        try { [void](Read-LaunchOverride -Game $Game) } catch {}
        if (-not $pendDir -and $PreviousState -and $PreviousState.GameDir) { $pendDir=[string]$PreviousState.GameDir }
        if ($confirmedSuccess -and ($primaryWritten -or $secondaryWritten)) {
            if ($primaryWritten) {
                $exact=('' + $status.versionValue).Trim()
                if (-not (Test-IsTrackableInstalledVersion -Version $exact)) { $exact=Read-VersionStampFile -Path (Get-InstalledVersionPath -Game $Game) }
                if ($exact) { Write-InstalledVersion -Game $Game -Version $exact -GameDir $pendDir }
            }
            if ($secondaryWritten) {
                $exactB=('' + $status.versionBValue).Trim()
                if (-not (Test-IsTrackableInstalledVersion -Version $exactB)) { $exactB=Read-VersionStampFile -Path (Get-InstalledVersionPathB -Game $Game) }
                if ($exactB) { Write-InstalledVersionB -Game $Game -Version $exactB -GameDir $pendDir }
            }
        } elseif ($confirmedSuccess -and -not ($Game.NoVersionSeed -and $Game.TwoMods)) {
            Invalidate-SupersededInstalledVersion -Game $Game -GameDir $pendDir
        }
        Remove-Item -LiteralPath $okMk -Force -ErrorAction SilentlyContinue
    }

    $recordedPath=Read-InstalledPath -Game $Game
    $modPresent=$true
    $postTwoProbe=$null
    if ($Game.TwoMods) {
        $postTwoProbe=Get-TwoModsPresence -Game $Game -FallbackRoot $recordedPath
        $postDefs=@(Get-AlternativeModDefinitions -Game $Game)
        $postPresent=@($postDefs | Where-Object { [bool](Get-AlternativeModValue $postTwoProbe ("$($_.Mode)Present")) })
        $modPresent=if ($Game.TwoModsRequireBoth) { $postDefs.Count -gt 0 -and $postPresent.Count -eq $postDefs.Count } else { $postPresent.Count -gt 0 }
    } elseif ($recordedPath -and $Game.ModFile) {
        $modPresent=Test-RelativePathMarker -Root $recordedPath -Values @($Game.ModFile,$Game.ModFileAlt,$Game.ModFileAlt2)
        if (-not $modPresent -and $Game.DoorstopTargetModFile) {
            $modPresent=Test-DoorstopTargetModMarker -GameRoot $recordedPath -TargetMarker $Game.DoorstopTargetModFile -LoaderFile $Game.DoorstopLoaderFile
        }
        if (-not $modPresent -and $Game.VrInstallRoot) {
            $vr=$Game.VrInstallRoot
            if     ($vr -like 'LOCALAPPDATA:*') { $vr=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) ($vr.Substring('LOCALAPPDATA:'.Length)) }
            elseif ($vr -like 'APPDATA:*')      { $vr=Join-Path ([Environment]::GetFolderPath('ApplicationData')) ($vr.Substring('APPDATA:'.Length)) }
            elseif ($vr -like 'PROGRAMDATA:*')  { $vr=Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) ($vr.Substring('PROGRAMDATA:'.Length)) }
            elseif ($vr -like 'USERPROFILE:*')  { $vr=Join-Path ([Environment]::GetFolderPath('UserProfile')) ($vr.Substring('USERPROFILE:'.Length)) }
            $modPresent=Test-RelativePathMarker -Root $vr -Values @($Game.ModFile,$Game.ModFileAlt,$Game.ModFileAlt2)
            if ($modPresent) { $recordedPath=$vr }
        }
    }

    $postDualProbe=$null
    if ($Game.DualMode) {
        $postDualProbe=Get-DualModePresence -Game $Game
        if ($postDualProbe.AnyPresent) {
            $modPresent=$true
            $postDualRoot=Get-DualModePreferredRoot -Presence $postDualProbe
            if ($postDualRoot) { $recordedPath=$postDualRoot }
        }
    }
    if ($modPresent -and $recordedPath -and -not (Test-VrInstallEvidenceContract -Game $Game -Root $recordedPath)) { $modPresent=$false }
    $baseGamePresent=$true
    # Get-DualModePresence already validated the base-game proof belonging to
    # the exact selected route. Reapplying the primary route's GameExe here
    # would reject a valid legacy standalone executable (Gen1Recomp) merely
    # because the successor uses a different filename (DramaticShapeVR.exe).
    if ($postDualProbe -and $postDualProbe.AnyPresent) { $baseGamePresent=$true }
    elseif ($recordedPath) { $baseGamePresent=Test-BaseGameInstallProof -Game $Game -Root $recordedPath }
    if (-not $baseGamePresent -and $Game.VrInstallRoot) {
        $previousBaseRoot=if ($PreviousState -and $PreviousState.GameDir) { [string]$PreviousState.GameDir } else { '' }
        if ($previousBaseRoot -and (Test-BaseGameInstallProof -Game $Game -Root $previousBaseRoot)) { $baseGamePresent=$true }
        elseif ($confirmedInstallerSuccess) { $baseGamePresent=$true }
    }

    if ($recordedPath -and (Test-Path -LiteralPath $recordedPath -PathType Container) -and $baseGamePresent -and $modPresent) {
        $stateEntry=@{ Tag='vrinstalled'; Accent=$(if ($Game.Accent) { $Game.Accent } else { '#666677' }); State='ready'; BtnText='VR Ready'; GameDir=$recordedPath }
        if ($Game.DualMode) {
            $dm=if ($postDualProbe) { $postDualProbe } else { Get-DualModePresence -Game $Game }
            $stateEntry.CurrentPresent=[bool]$dm.CurrentPresent; $stateEntry.DepotPresent=[bool]$dm.DepotPresent
            $stateEntry.LegacyPresent=[bool]$dm.LegacyPresent; $stateEntry.RouteSplit=[bool]$dm.MultiplePresent
            $stateEntry.CurrentDir=$dm.CurrentDir; $stateEntry.DepotDir=$dm.DepotDir; $stateEntry.LegacyDir=$dm.LegacyDir
            if ($dm.BothPresent) { $stateEntry.DualMode=$true }
        }
        if ($Game.TwoMods) {
            $pi=if ($postTwoProbe) { $postTwoProbe } else { Get-TwoModsPresence -Game $Game -FallbackRoot $recordedPath }
            $piDefs=@(Get-AlternativeModDefinitions -Game $Game)
            $piPresent=@($piDefs | Where-Object { [bool](Get-AlternativeModValue $pi ("$($_.Mode)Present")) })
            $stateEntry.TwoMods=if ($Game.TwoModsRequireBoth) { $piDefs.Count -gt 0 -and $piPresent.Count -eq $piDefs.Count } else { $piPresent.Count -gt 0 }
            Set-AlternativeModStateFields -State $stateEntry -Game $Game -Presence $pi
            $remainingTargets=@(Get-AlternativeModsNeedingManualUpdate -Game $Game -Presence $pi)
            if ($remainingTargets.Count -gt 0) {
                $uniqueSlots=@($remainingTargets | ForEach-Object { [string]$_.Slot } | Where-Object { $_ } | Sort-Object -Unique)
                $uniqueRoutes=@($remainingTargets | ForEach-Object { [string]$_.Route } | Where-Object { $_ } | Sort-Object -Unique)
                $stateEntry.Tag='vrupdate'; $stateEntry.State='update'; $stateEntry.UpdateTargetCount=$remainingTargets.Count
                $stateEntry.UpdateTargetSlot=if ($uniqueSlots.Count -eq 1) { [string]$uniqueSlots[0] } else { $null }
                $stateEntry.UpdateTargetRoute=if ($uniqueRoutes.Count -eq 1) { [string]$uniqueRoutes[0] } else { $null }
                $names=@($remainingTargets | ForEach-Object { $label=if ($_.Name) { [string]$_.Name } else { "Mod $($_.Slot)" }; if ($_.Route) { "$label ($($_.Route))" } else { $label } })
                $stateEntry.UpdateEvidence=(($names -join ', ') + ' is missing its required current-release proof file')
                $stateEntry.BtnText=Get-UpdateActionLabel -Game $Game -State $stateEntry -Fallback 'Update Mod'
            }
        }
        $stateEntry=Resolve-PostInstallRefreshState -PreviousState $PreviousState -CandidateState $stateEntry -ConfirmedInstallerSuccess $confirmedInstallerSuccess
        $postVer=Read-InstalledVersion -Game $Game -GameDir $recordedPath
        if (-not $postVer -and -not $Game.NoVersionSeed) {
            $postVer=Get-PostInstallLocalTrackedVersion -Game $Game -GameDir $recordedPath
            if ($postVer) { Write-InstalledVersion -Game $Game -Version $postVer -GameDir $recordedPath }
        }
        $result.Action='Set'; $result.StateEntry=$stateEntry
    } elseif ($recordedPath -and (Test-Path -LiteralPath $recordedPath -PathType Container) -and $baseGamePresent) {
        $label=if ($Game.Bat) { 'Install' } elseif ($Game.Type -eq 'steam') { 'Open in Steam' } elseif ($Game.Type -eq 'itch') { 'Open on itch.io' } else { 'Get Installer' }
        $result.Action='Set'
        $result.StateEntry=@{ Tag='installed'; State='installed'; Border='#2a5c38'; BtnText=$label; BtnColor='#66dd88'; GameDir=$recordedPath }
    } elseif ($recordedPath -and (Test-Path -LiteralPath $recordedPath -PathType Container) -and -not $baseGamePresent) {
        $result.Action='Remove'
    }
    $result.RecordedPath='' + $recordedPath
    $result.ConfirmedInstallerSuccess=$confirmedInstallerSuccess
    return [pscustomobject]$result
}

function global:Apply-PostInstallDetectionSnapshot {
    param($Snapshot)
    if (-not $Snapshot) { return }
    $title=[string]$Snapshot.Title
    if ($Snapshot.Action -eq 'Set') { $global:gameStateMap[$title]=$Snapshot.StateEntry }
    elseif ($Snapshot.Action -eq 'Remove' -and $global:gameStateMap.ContainsKey($title)) { $global:gameStateMap.Remove($title) | Out-Null }
    if ($Snapshot.Action -in @('Set','Remove')) {
        try { Rebuild-Lookups } catch {}
        try { if (Get-Command Refresh-DiscoverStatuses -ErrorAction SilentlyContinue) { Refresh-DiscoverStatuses } } catch {}
    }
    try {
        if ($global:window -and $global:window.Dispatcher) {
            $global:window.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Render,[action]{})
        }
    } catch {}
    try {
        if ($global:currentDetailGame -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) { Show-DiscoverDetail -Game $global:currentDetailGame }
    } catch {}
}

function global:Invoke-PostInstallRefresh {
    param([string]$GameId = '', [string]$Title = '')
    $target=Resolve-PostInstallRefreshTarget -GameId $GameId -Title $Title
    if (Test-PostInstallRefreshScanActive) {
        $global:PostInstallRefreshPending=$true
        if ($target.GameId) { $global:PendingInstallGameId=$target.GameId }
        if ($target.Title) { $global:PendingInstallTitle=$target.Title }
        return
    }
    if (-not $target.Game) { return }
    $previousState=$null
    try { $previousState=$global:gameStateMap[$target.Title] } catch {}
    $snapshot=Get-PostInstallDetectionSnapshot -Game $target.Game -Title $target.Title -PreviousState $previousState
    Apply-PostInstallDetectionSnapshot -Snapshot $snapshot
}

# Timer callbacks used to swallow every post-install refresh exception. That
# produced the worst possible symptom: the installer window closed, the tile
# stayed on Update, and no log explained why. Every install surface now calls
# this one guarded entry point, which keeps the Hub alive while making the
# failure visible and durable.
function global:Start-PostInstallScanActivity {
    # Preserve the exact completed-scan presentation. The focused refresh must
    # temporarily use the same visible working state as a manual full scan, but
    # must not replace its already-audited totals after the one-game check.
    $state = [pscustomobject]@{
        Count=$null; CountVisibility=$null
        Text=$null; TextVisibility=$null; TextValue=$null; TextForeground=$null; TextFontSize=$null
        Mag=$null; MagVisibility=$null
        Shimmer=$null; ShimmerVisibility=$null
        OwnsSpinner=$false
    }
    try {
        if (-not $global:window) { return $state }
        $state.Count = $global:window.FindName('CheckInstalledCount')
        $state.Text = $global:window.FindName('CheckInstalledText')
        $state.Mag = $global:window.FindName('CheckInstalledMagRight')
        $state.Shimmer = $global:window.FindName('CheckInstalledShimmer')

        if ($state.Count) {
            $state.CountVisibility = $state.Count.Visibility
            $state.Count.Visibility = [System.Windows.Visibility]::Collapsed
        }
        if ($state.Text) {
            $state.TextVisibility = $state.Text.Visibility
            $state.TextValue = [string]$state.Text.Text
            $state.TextForeground = $state.Text.Foreground
            $state.TextFontSize = [double]$state.Text.FontSize
            $state.Text.Visibility = [System.Windows.Visibility]::Visible
            $state.Text.Text = 'Scanning...'
            $state.Text.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#ffcc44')
            $state.Text.FontSize = 14
        }
        if ($state.Mag) {
            $state.MagVisibility = $state.Mag.Visibility
            $state.Mag.Visibility = [System.Windows.Visibility]::Visible
        }
        if ($state.Shimmer) {
            $state.ShimmerVisibility = $state.Shimmer.Visibility
            $state.Shimmer.Visibility = [System.Windows.Visibility]::Collapsed
        }

        $spinnerWasActive = [bool]$global:ScanSpinnerActive
        if (Get-Command Start-ScanSpinner -ErrorAction SilentlyContinue) { Start-ScanSpinner }
        $state.OwnsSpinner = [bool](-not $spinnerWasActive -and $global:ScanSpinnerActive)

        # This is the part the former implementation missed. Starting a visual
        # and immediately doing synchronous detection in the same timer tick
        # does not guarantee that WPF has presented it. The manual scan drains
        # the render queue before detection; use that exact barrier here too.
        try { $global:window.UpdateLayout() } catch {}
        if ($global:window.Dispatcher) {
            $flushFrame = New-Object System.Windows.Threading.DispatcherFrame
            $stopFlush = { $flushFrame.Continue = $false }.GetNewClosure()
            [void]$global:window.Dispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                [action]$stopFlush)
            [System.Windows.Threading.Dispatcher]::PushFrame($flushFrame)
        }
    } catch {}
    return $state
}

function global:Stop-PostInstallScanActivity {
    param($State)
    if (-not $State) { return }
    if ($State.OwnsSpinner) {
        try { if (Get-Command Stop-ScanSpinner -ErrorAction SilentlyContinue) { Stop-ScanSpinner } } catch {}
    }
    try { if ($State.Count) { $State.Count.Visibility = $State.CountVisibility } } catch {}
    try {
        if ($State.Text) {
            $State.Text.Visibility = $State.TextVisibility
            $State.Text.Text = $State.TextValue
            $State.Text.Foreground = $State.TextForeground
            $State.Text.FontSize = $State.TextFontSize
        }
    } catch {}
    try { if ($State.Mag) { $State.Mag.Visibility = $State.MagVisibility } } catch {}
    try { if ($State.Shimmer) { $State.Shimmer.Visibility = $State.ShimmerVisibility } } catch {}
}

function global:Complete-PostInstallRefreshSafely {
    param(
        [string]$GameId = '',
        [string]$Title = '',
        $ActivityState = $null,
        [bool]$PreviousPostInstallRefresh = $false
    )
    try {
        Invoke-PostInstallRefresh -GameId $GameId -Title $Title
    } catch {
        if (Get-Command Write-HubActionFailure -ErrorAction SilentlyContinue) {
            Write-HubActionFailure -Action 'Refresh installed mod status' -ErrorRecord $_
        } else {
            try { Write-Host ("[HubError] Refresh installed mod status: " + $_.Exception.Message) -ForegroundColor Red } catch {}
        }
    } finally {
        if ($ActivityState) { Stop-PostInstallScanActivity -State $ActivityState }
        $global:PostInstallRefreshInProgress = $PreviousPostInstallRefresh
    }
}

# Start the complete disk/state probe in a private runspace. Only the compact
# snapshot crosses back to WPF, where state assignment and repaint remain
# serialized on the Dispatcher thread.
function global:Start-PostInstallDetectionAsync {
    param(
        [string]$GameId = '',
        [string]$Title = '',
        $ActivityState = $null,
        [bool]$PreviousPostInstallRefresh = $false,
        [scriptblock]$DetectionScript = $null,
        [int]$PollMilliseconds = 40
    )
    if (-not $global:window -or -not $global:window.Dispatcher) { return $false }
    if (Test-PostInstallRefreshScanActive) { return $false }
    $target=Resolve-PostInstallRefreshTarget -GameId $GameId -Title $Title
    if (-not $target.Game) { return $false }
    $previousState=$null
    try { $previousState=$global:gameStateMap[$target.Title] } catch {}
    $runspace=$null; $powerShell=$null
    try {
        $iss=[Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $workerCommand='Get-PostInstallDetectionSnapshot'
        if ($DetectionScript) {
            $workerCommand='__PCVRPostInstallDetectionFixture'
            $iss.Commands.Add((New-Object Management.Automation.Runspaces.SessionStateFunctionEntry($workerCommand,$DetectionScript.ToString())))
        } else {
            # Copy function *definitions*, never live ScriptBlock objects. A
            # live block remains bound to the WPF runspace; invoking and later
            # disposing it from another runspace can corrupt the Hub session.
            $allowedLeaves=@('HubState.ps1','VRModHub.ps1','Helpers.ps1','Filter.ps1','Filter.Banners.ps1','Filter.ScanSources.ps1','Filter.InstallRefresh.ps1')
            $explicitNames=@(
                'Get-PostInstallDetectionSnapshot','Resolve-PostInstallRefreshState','Get-PostInstallLocalTrackedVersion',
                'Test-IsTrackableInstalledVersion','Get-InstalledVersionPath','Get-InstalledPathFile','Read-InstalledPath',
                'Get-LaunchOverrideFile','Read-LaunchOverride','Get-GameStampPath','Read-VersionStampFile',
                'Import-PendingInstallerVersion','Read-InstalledVersionProof','Read-InstalledVersion','Write-InstalledVersion',
                'Get-InstalledVersionPathB','Read-InstalledVersionB','Write-InstalledVersionB','Invalidate-SupersededInstalledVersion',
                'Get-UpdateOkMarkerPath','Test-RelativePathMarker','Test-BaseGameInstallProof','Test-VrInstallEvidenceContract',
                'Join-HubPathLexical','Test-HubWindowsStylePathLexical'
            )
            $added=@{}
            foreach ($command in @(Get-Command -CommandType Function)) {
                $sourceLeaf=''
                # Dynamic/host functions have no ScriptBlock.File. Calling
                # Split-Path with that empty value creates a terminating error
                # for every such function under the Hub's Stop preference.
                # A transcript records even caught errors, so one refresh used
                # to spend minutes writing thousands of errors before the
                # actual detection worker could start.
                $sourceFile=''
                try { $sourceFile='' + $command.ScriptBlock.File } catch {}
                if ($sourceFile) {
                    try { $sourceLeaf=[IO.Path]::GetFileName($sourceFile) } catch {}
                }
                if (($allowedLeaves -notcontains $sourceLeaf) -and ($explicitNames -notcontains $command.Name)) { continue }
                if ($added.ContainsKey($command.Name)) { continue }
                $definition=''+$command.Definition
                if (-not $definition) { continue }
                $iss.Commands.Add((New-Object Management.Automation.Runspaces.SessionStateFunctionEntry($command.Name,$definition)))
                $added[$command.Name]=$true
            }
            if (-not $added.ContainsKey('Get-PostInstallDetectionSnapshot')) { throw 'Post-install detection function was not copied into the worker.' }
            foreach ($variable in @(
                @{Name='scriptDir';Value=$script:scriptDir},
                @{Name='HubStateRootOverride';Value=$global:HubStateRootOverride},
                @{Name='HubPortableStateRootOverride';Value=$global:HubPortableStateRootOverride},
                @{Name='HubLegacyPortableStateRootOverride';Value=$global:HubLegacyPortableStateRootOverride},
                @{Name='HubRuntimeRootOverride';Value=$global:HubRuntimeRootOverride}
            )) {
                $iss.Variables.Add((New-Object Management.Automation.Runspaces.SessionStateVariableEntry($variable.Name,$variable.Value,'')))
            }
            # Unlike the other override readers, Get-HubLocalApplicationDataRoot
            # distinguishes an undefined variable from a defined-but-empty one.
            # Do not inject a null override into production: that would hide the
            # real Windows LocalAppData folder from the worker. Tests that use a
            # deliberate isolated LocalAppData root still receive it explicitly.
            if ($global:HubLocalAppDataRootOverride) {
                $iss.Variables.Add((New-Object Management.Automation.Runspaces.SessionStateVariableEntry(
                    'HubLocalAppDataRootOverride',$global:HubLocalAppDataRootOverride,'')))
            }
        }
        $runspace=[Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
        try { $runspace.ApartmentState='MTA' } catch {}
        $runspace.Open()
        $powerShell=[PowerShell]::Create(); $powerShell.Runspace=$runspace
        [void]$powerShell.AddCommand($workerCommand).AddParameter('Game',$target.Game).AddParameter('Title',$target.Title).AddParameter('PreviousState',$previousState)
        $async=$powerShell.BeginInvoke()
        if (-not $script:PostInstallDetectionWorkers) { $script:PostInstallDetectionWorkers=@{} }
        $workerRegistry=$script:PostInstallDetectionWorkers
        $key=[Guid]::NewGuid().ToString('N')
        $timer=New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval=[TimeSpan]::FromMilliseconds([Math]::Max(10,$PollMilliseconds))
        $workerPowerShell=$powerShell; $workerRunspace=$runspace; $workerAsync=$async; $workerKey=$key
        $workerActivity=$ActivityState; $workerPreviousFlag=$PreviousPostInstallRefresh
        $timer.Add_Tick({
            param($sender,$eventArgs)
            if (-not $workerAsync.IsCompleted) { return }
            $sender.Stop()
            try {
                $allResults=@($workerPowerShell.EndInvoke($workerAsync))
                $snapshot=@($allResults | Where-Object { $_ -and $_.PSObject.Properties['Action'] }) | Select-Object -Last 1
                if (-not $snapshot) { throw 'The post-install worker returned no detection snapshot.' }
                Apply-PostInstallDetectionSnapshot -Snapshot $snapshot
            } catch {
                if (Get-Command Write-HubActionFailure -ErrorAction SilentlyContinue) { Write-HubActionFailure -Action 'Refresh installed mod status' -ErrorRecord $_ }
                else { try { Write-Host ("[HubError] Refresh installed mod status: " + $_.Exception.Message) -ForegroundColor Red } catch {} }
            } finally {
                try { $workerPowerShell.Dispose() } catch {}
                try { $workerRunspace.Dispose() } catch {}
                try { if ($workerRegistry) { $workerRegistry.Remove($workerKey) } } catch {}
                if ($workerActivity) { Stop-PostInstallScanActivity -State $workerActivity }
                $global:PostInstallRefreshInProgress=$workerPreviousFlag
            }
        }.GetNewClosure())
        $workerRegistry[$key]=[pscustomobject]@{ Timer=$timer; PowerShell=$powerShell; Runspace=$runspace; Async=$async }
        $timer.Start()
        return $true
    } catch {
        try { if ($powerShell) { $powerShell.Dispose() } } catch {}
        try { if ($runspace) { $runspace.Dispose() } } catch {}
        return $false
    }
}

function global:Invoke-PostInstallRefreshSafely {
    param([string]$GameId = '', [string]$Title = '', [switch]$ShowScanActivity)
    $activityState = $null
    $previousPostInstallRefresh = [bool]$global:PostInstallRefreshInProgress
    $global:PostInstallRefreshInProgress = $true
    # A post-installer repaint touches both card renderers and can hold the UI
    # thread for several seconds on a populated, already-scanned library. Give
    # it the complete visible manual-scan prelude, not merely a spinner object
    # that has not yet reached the screen. Never borrow or stop activity owned
    # by an actual queued/running scan.
    if ($ShowScanActivity -and -not $global:ScanInProgress -and -not $global:ScanQueued) {
        $activityState = Start-PostInstallScanActivity
    }

    # Installer timers run on the WPF dispatcher. Queue the worker launch after
    # the visible prelude, then keep every disk/state probe in its own runspace.
    # The Dispatcher sees only the final state assignment and card repaint.
    if ($activityState -and $global:window -and $global:window.Dispatcher) {
        try {
            $queuedGameId = $GameId
            $queuedTitle = $Title
            $queuedActivity = $activityState
            $queuedPrevious = $previousPostInstallRefresh
            $queuedWork = {
                $started=Start-PostInstallDetectionAsync -GameId $queuedGameId -Title $queuedTitle `
                    -ActivityState $queuedActivity -PreviousPostInstallRefresh $queuedPrevious
                if (-not $started) {
                    Complete-PostInstallRefreshSafely -GameId $queuedGameId -Title $queuedTitle `
                        -ActivityState $queuedActivity -PreviousPostInstallRefresh $queuedPrevious
                }
            }.GetNewClosure()
            [void]$global:window.Dispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Input,
                [action]$queuedWork)
            return
        } catch {
            # A dispatcher teardown must not lose the completed install. Fall
            # through to the same guarded synchronous cleanup path.
        }
    }
    Complete-PostInstallRefreshSafely -GameId $GameId -Title $Title `
        -ActivityState $activityState -PreviousPostInstallRefresh $previousPostInstallRefresh
}

# Consume an installer refresh that completed while a live installed-games
# scan owned the collections. Keeping this transition in one helper makes the
# scan epilogue explicit and prevents the saved game identity from expiring
# unused after the global scan flag is released.
function global:Invoke-DeferredPostInstallRefresh {
    if (-not $global:PostInstallRefreshPending) { return }
    $deferredGameId = '' + $global:PendingInstallGameId
    $deferredTitle = '' + $global:PendingInstallTitle
    $global:PostInstallRefreshPending = $false
    $global:PendingInstallGameId = $null
    $global:PendingInstallTitle = $null
    Invoke-PostInstallRefreshSafely -GameId $deferredGameId -Title $deferredTitle -ShowScanActivity
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
        $watchId = if (Get-Command Get-HubGameStateId -ErrorAction SilentlyContinue) { '' + (Get-HubGameStateId -Game $Game) } else { '' + $Game.Id }
        $timer.Tag = @{ Marker = $marker; Stamp = $stamp; Deadline = (Get-Date).AddMinutes(15); GameId = $watchId; Title = [string]$Game.Title }
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
                Invoke-PostInstallRefreshSafely -GameId ([string]$st.GameId) -Title ([string]$st.Title) -ShowScanActivity
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
