. (Join-Path $PSScriptRoot 'InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'PublisherZipTransaction.ps1')

function Get-CodiesVRProfile([string]$Key) {
    switch($Key){
        'Grid2019' {return @{Key=$Key;Id='grid-2019-vr';Title='GRID (2019) VR';Package='Grid2019VR';App='703860';Folder='GRID (2019)';Exe='Grid_dx12.exe';Dll='d3d12.dll';Ini='gridvr12.ini';Identity='codiesgrid2019';Quip='Your nemesis has requested a less personal racing line.'}}
        'GridLegends' {return @{Key=$Key;Id='grid-legends-vr';Title='GRID Legends VR';Package='GridLegendsVR';App='1307710';Folder='GRID Legends';Exe='GridLegends.exe';Dll='d3d12.dll';Ini='gridvr12.ini';Identity='codiesgridlegends';Quip='Seneca hired a driver. The barriers got a demolition crew.'}}
        'Dirt4' {return @{Key=$Key;Id='dirt-4-vr';Title='DiRT 4 VR';Package='Dirt4VR';App='421020';Folder='DiRT 4';Exe='dirt4.exe';Dll='d3d11.dll';Ini='dirt4vr.ini';Identity='codiesdirt4';Quip='Your co-driver said cut. The tree disagreed.'}}
        default {throw 'Unknown CodiesVR game.'}
    }
}

function Assert-CodiesVRFixture([string]$Path) {
    $full=[IO.Path]::GetFullPath($Path);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
    if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $full 'codies-fixture.txt') -PathType Leaf)){throw 'CodiesVR tests require an isolated, marked game fixture.'}
    return $full
}

function Get-CodiesVRGame($Profile) {
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        $root=Assert-CodiesVRFixture $env:PCVR_CODIES_TEST_GAME
        if(-not(Test-Path -LiteralPath (Join-Path $root $Profile.Exe) -PathType Leaf)){throw "The game folder needs $($Profile.Exe)."}
        return $root
    }
    $candidates=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $Profile.Id -StateNames @('base_game_path','installed_path','user_located') -ProbeFiles @($Profile.Exe)
    if($saved){$candidates+=$saved}
    try{$steam=Find-SteamGameFolder -AppId $Profile.App -SteamFolderNames @($Profile.Folder) -ProbeExe $Profile.Exe -HubGameId $Profile.Id;if($steam){$candidates+=$steam}}catch{}
    if($Profile.Key -eq 'GridLegends'){
        $candidates+=@('C:\Program Files\EA Games\GRID Legends','C:\Program Files (x86)\Origin Games\GRID Legends')
    }
    foreach($root in @($candidates|Select-Object -Unique)){if($root -and (Test-Path -LiteralPath (Join-Path $root $Profile.Exe) -PathType Leaf)){return [IO.Path]::GetFullPath($root)}}
    $picked=Get-GameFolderInteractive -GameName $Profile.Title -ProbeFile $Profile.Exe
    if(-not $picked -or -not(Test-Path -LiteralPath (Join-Path $picked $Profile.Exe) -PathType Leaf)){throw "Choose the game folder containing $($Profile.Exe)."}
    [void](Save-HubRememberedGameFolder -GameId $Profile.Id -Title $Profile.Title -GameDir $picked -ProbeFiles @($Profile.Exe) -UserSelected)
    return [IO.Path]::GetFullPath($picked)
}

function Get-CodiesVRFlatTarget($Profile,[string]$Root) {
    if($Root -match '(?i)[\\/]steamapps[\\/]common[\\/]' -or $Profile.Key -ne 'GridLegends'){return "steam://rungameid/$($Profile.App)"}
    return (Join-Path $Root $Profile.Exe)
}

function Sync-CodiesVRLaunchState($Profile,[string]$Root) {
    # A former store's ordinary EXE is an automatically reconstructed override,
    # not a custom launcher. It must not outrank the newly committed game root.
    # Preserve genuinely different executables selected by the user.
    $stateModule=Join-Path $PSScriptRoot 'HubState.ps1'
    & {
        param($Module,$Profile,$Root)
        . $Module
        $game=[pscustomobject]@{Id=$Profile.Id;Title=$Profile.Title}
        $old=Read-PersistentGameStateValue -Game $game -Name 'launch_exe'
        try{
            if($old -and [IO.Path]::GetFileName([string]$old) -ieq $Profile.Exe -and
                [IO.Path]::GetFullPath((Split-Path -Parent ([string]$old))).TrimEnd('\') -ine [IO.Path]::GetFullPath($Root).TrimEnd('\')){
                Reset-PersistentGameStateValue -Game $game -Name 'launch_exe'
            }
        }catch{ }
    } $stateModule $Profile $Root
    [void](Save-HubRememberedGameFolder -GameId $Profile.Id -Title $Profile.Title -GameDir $Root -ProbeFiles @($Profile.Exe))
}

function Wait-CodiesVRFirstStart($Profile,[string]$Root,[string]$ConfigPath) {
    if(Test-Path -LiteralPath $ConfigPath -PathType Leaf){return}
    Write-Host ''
    Write-Host ('='*60) -ForegroundColor Yellow
    Write-Host '  FIRST FLAT START REQUIRED' -ForegroundColor Yellow
    Write-Host "  Start $($Profile.Folder), reach the main menu, then exit." -ForegroundColor White
    if($Profile.Key -eq 'Grid2019'){Write-Host '  In Steam, choose DirectX 12 (Grid_dx12.exe), including for VR.' -ForegroundColor Green}
    Write-Host '  The game must create its graphics settings before VR setup.' -ForegroundColor White
    Write-Host ('  Required settings: '+$ConfigPath) -ForegroundColor Gray
    while(-not(Test-Path -LiteralPath $ConfigPath -PathType Leaf)){
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start the game normally and create its settings...')
        if($env:PCVR_HUB_TEST_MODE -eq '1'){
            if($env:PCVR_CODIES_TEST_FLAT_CAPTURE){[IO.File]::AppendAllText($env:PCVR_CODIES_TEST_FLAT_CAPTURE,((Get-CodiesVRFlatTarget $Profile $Root)+[Environment]::NewLine))}
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $ConfigPath));[IO.File]::WriteAllText($ConfigPath,'<hardware_settings_config />')
        }else{Start-Process -FilePath (Get-CodiesVRFlatTarget $Profile $Root) -ErrorAction Stop|Out-Null}
        [void](Wait-PCVRExplicitEnter -Message 'After reaching the main menu and closing the game, press Enter to continue...')
        if(-not(Test-Path -LiteralPath $ConfigPath -PathType Leaf)){Write-Host '  [!!] Settings are still missing. Start the game once, save its options and exit.' -ForegroundColor Yellow}
    }
    Write-Host '  [OK] Game settings found.' -ForegroundColor Green
}

function Get-CodiesVRArchive($Profile,[string]$Destination) {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_CODIES_TEST_ARCHIVE){
        Copy-Item -LiteralPath $env:PCVR_CODIES_TEST_ARCHIVE -Destination $Destination -Force
        return ''
    }
    $handover=Get-PCVRRecoveryInput -PathType Leaf
    if($handover -and [IO.Path]::GetExtension($handover) -ieq '.zip'){
        Copy-Item -LiteralPath $handover -Destination $Destination -Force
        Write-Host '  [OK] Using the publisher ZIP supplied in installer recovery.' -ForegroundColor Green
        return ''
    }
    $page='https://github.com/drowhunter/CodiesVR/releases'
    $pattern='(?i)^'+[regex]::Escape($Profile.Package)+'-[0-9].*\.zip$'
    $release=Resolve-GitHubReleaseAsset -Repo 'drowhunter/CodiesVR' -AssetPatterns @($pattern) -IncludePrerelease $false -SkipReleasesWithoutMatchingAsset
    if($release.Resolved -and $release.Url){
        Write-Host ('  Downloading '+$Profile.Title+'; transfer progress is shown while it runs.') -ForegroundColor Gray
        [void](Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $Destination -Label $Profile.Title -ManualUrl $page -AllowSkip:$false -QuietProgress -DisableGitHubAssetReresolution)
        return ([string]$release.Tag)
    }
    Write-Host '  [!!] The current game-specific ZIP could not be resolved. Use its official release page.' -ForegroundColor Yellow
    Write-Host "  Choose $($Profile.Package)-<version>.zip. Other games may have newer, separate releases." -ForegroundColor White
    while($true){
        [void](Open-PCVRPageAfterEnter -Url $page -Message 'Press Enter to open the official CodiesVR releases...')
        [void](Wait-PCVRExplicitEnter -Message 'After downloading the ZIP for this game, press Enter to check Downloads...')
        $found=Find-PCVRDownloadedCandidate -Patterns @($Profile.Package+'-*.zip')
        if($found){Write-Host "  Found: $found" -ForegroundColor Cyan;if((Read-Host '  Use this ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){Copy-Item -LiteralPath $found -Destination $Destination -Force;return ''}}
        $path=(Read-Host '  Drag/paste the ZIP path, or press Enter to reopen releases').Trim().Trim('"').Trim("'")
        if($path -and (Test-Path -LiteralPath $path -PathType Leaf)){Copy-Item -LiteralPath $path -Destination $Destination -Force;return ''}
    }
}

function Write-CodiesVRCheckpoint($Profile,[string]$Root,[string[]]$Required,[string]$Phase) {
    $missing=@();$items=@()
    foreach($name in $Required){$exists=Test-Path -LiteralPath (Join-Path $Root $name) -PathType Leaf;$items+="$name=$exists";if(-not $exists){$missing+=$name}}
    Write-Host ('  File check ['+$Phase+']: '+($items -join '; ')) -ForegroundColor DarkGray
    return $missing
}

function Invoke-CodiesVRInstaller([string]$Key,[string]$InstallerFolder) {
    $ErrorActionPreference='Stop';$p=Get-CodiesVRProfile $Key
    $page='https://github.com/drowhunter/CodiesVR/releases'
    $manifest=".pcvrhub_$($p.Identity)_ownership.csv";$versionFile=".pcvrhub_$($p.Identity)_version"
    $work=$null;$root=$null;$snapshot=$null;$changed=$false;$report=$null;$version=''
    $candidate=Test-PCVRUntestedInstaller -InstallerId $p.Id
    if($candidate){$report=Start-PCVRInstallerTestReport -InstallerId $p.Id -GameTitle $p.Title -ModName 'CodiesVR' -FileStem $p.Id -InstallerFolder $InstallerFolder}
    try {
        if($env:PCVR_HUB_TEST_MODE -ne '1'){Clear-Host}
        $Host.UI.RawUI.WindowTitle=$p.Title+' Installer'
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host ('  '+$p.Title+' - CodiesVR') -ForegroundColor Cyan
        if($candidate){Write-Host '  Untested Hub installer - help confirm it on a real game' -ForegroundColor Yellow}
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Seated OpenXR cockpit VR. Keep using your gamepad or wheel.' -ForegroundColor White
        Write-Host '  Use Virtual Desktop / VDXR where supported. SteamVR may show ghosting.' -ForegroundColor Yellow
        Write-Host '  Close the game. Your saves and existing configuration are preserved.' -ForegroundColor White
        if($candidate){Write-Host '  Destination file lists and this log are saved in Hub Core\Logs\Untested.' -ForegroundColor Cyan}
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message ('After reading this, press Enter to locate '+$p.Folder+'...'))
        $root=Get-CodiesVRGame $p
        if($Key -ne 'GridLegends' -and $root -notmatch '(?i)[\\/]steamapps[\\/]common[\\/]'){throw 'Choose the installed Steam library folder for this game. Only the Steam edition is supported.'}
        $route=if($root -match '(?i)[\\/]steamapps[\\/]common[\\/]' -or $Key -ne 'GridLegends'){'Steam'}else{'EA'}
        Write-Host "  [OK] Game ($route): $root" -ForegroundColor Green
        if($report){Add-PCVRInstallerTestReportTarget -Session $report -Path $root -GameDir $root -Route $route}
        $processNames=@([IO.Path]::GetFileNameWithoutExtension($p.Exe));if($Key -eq 'Grid2019'){$processNames+='Grid'}
        if(Get-Process -Name $processNames -ErrorAction SilentlyContinue){throw 'Close the game before installing or updating CodiesVR.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $root)){throw 'The game folder is not writable. Check its permissions, then Retry.'}
        $docs=if($env:PCVR_HUB_TEST_MODE -eq '1'){$env:PCVR_CODIES_TEST_DOCUMENTS}else{[Environment]::GetFolderPath('MyDocuments')}
        if(-not $docs){throw 'The Windows Documents folder could not be found; no VR files were changed.'}
        $config=Join-Path $docs ('My Games\'+$p.Folder+'\hardwaresettings\hardware_settings_config.xml')
        Wait-CodiesVRFirstStart -Profile $p -Root $root -ConfigPath $config
        if(Get-Process -Name $processNames -ErrorAction SilentlyContinue){throw 'The game is still running. Exit it completely, then Retry.'}
        [void](Wait-PCVRExplicitEnter -Message ('Press Enter to check and download the current '+$p.Title+' ZIP...'))
        $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
        $archive=Join-Path $work 'publisher.zip';$releaseVersion=Get-CodiesVRArchive $p $archive
        $extract=Join-Path $work 'publisher';$safe=Test-ZipArchiveEntrySafety -ArchivePath $archive -DestinationFolder $extract
        if(-not $safe.Safe -or -not $safe.Inspectable){throw 'The publisher ZIP is unreadable or contains unsafe archive paths.'}
        Write-Host '  Inspecting and extracting the publisher package; this may take a few seconds.' -ForegroundColor Cyan
        if((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label $p.Title -AllowSkip:$false -QuietProgress) -ne 'ok'){throw 'The publisher ZIP could not be extracted.'}
        $dlls=@(Get-ChildItem -LiteralPath $extract -Filter $p.Dll -File -Recurse)
        if($dlls.Count -ne 1){throw "The selected game package needs one usable $($p.Dll). No game files were changed."}
        $packageRoot=$dlls[0].DirectoryName
        $versionPath=Join-Path $packageRoot 'VERSION.txt'
        if(Test-Path -LiteralPath $versionPath){
            $metadata=[IO.File]::ReadAllText($versionPath)
            $match=[regex]::Match($metadata,'(?im)^\s*(Grid2019VR|GridLegendsVR|Dirt4VR)\s+v?([0-9]+(?:\.[0-9]+){1,3}(?:[-.][0-9A-Za-z]+)*)')
            if($match.Success){if($match.Groups[1].Value -ine $p.Package){throw 'This ZIP is for a different CodiesVR game. Choose the ZIP for this tile.'};$version=$match.Groups[2].Value}
        }
        if(-not(Test-IsTrackableInstalledVersion $version)){$version=[Diagnostics.FileVersionInfo]::GetVersionInfo($dlls[0].FullName).ProductVersion}
        if(-not(Test-IsTrackableInstalledVersion $version)){$version=[string]$releaseVersion}
        if(-not(Test-IsTrackableInstalledVersion $version)){$version=(Read-Host '  Release version shown on the official page for this game ZIP').Trim()}
        if(-not(Test-IsTrackableInstalledVersion $version)){throw 'No exact mod version was established. No game files were changed.'}
        $stage=Join-Path $work 'deployment';[void][IO.Directory]::CreateDirectory($stage)
        Copy-Item -LiteralPath $dlls[0].FullName -Destination (Join-Path $stage $p.Dll)
        $publisherTarget=Join-Path $stage '_vrmods\CodiesVR'
        [void][IO.Directory]::CreateDirectory($publisherTarget)
        Get-ChildItem -LiteralPath $packageRoot -Force|ForEach-Object{Copy-Item -LiteralPath $_.FullName -Destination $publisherTarget -Recurse -Force}
        $required=@($p.Exe,$p.Dll,$manifest)
        $routes=if($Key -eq 'GridLegends'){@('Steam','EA')}else{@('Steam')}
        $contract=New-PCVRInstallerContract -Id $p.Id -GameName $p.Title -Acquisition GitHub -Routes $routes -AntivirusNotice -ReleasePageUrl $page -RequiredInstalledFileGroups $required
        $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $root -Stage $stage -Identity $p.Identity -SnapshotRoot (Join-Path $work 'rollback') -ExtraPaths @($versionFile)
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update CodiesVR...')
        Write-Host '  Backing up existing files, copying the mod and checking it; this may take a few seconds.' -ForegroundColor Cyan
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $root -Identity $p.Identity -AdoptIdenticalExisting -ReplaceChangedOwnedRelativePaths @($p.Dll))
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_CODIES_TEST_FAILURE -eq 'copy-missing'){Remove-Item -LiteralPath (Join-Path $root $p.Dll) -Force}
        $missing=@(Write-CodiesVRCheckpoint $p $root $required 'immediately-after-copy')
        if($missing.Count){throw ('Required files were not placed: '+($missing -join ', ')+'. A copy, path or permissions problem is possible; no antivirus cause is established.')}
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_CODIES_TEST_FAILURE -eq 'vanish'){Remove-Item -LiteralPath (Join-Path $root $p.Dll) -Force}
        Start-Sleep -Seconds 3
        $missing=@(Write-CodiesVRCheckpoint $p $root $required 'after-observation')
        if($missing.Count){
            $retry={
                [void](Write-CodiesVRCheckpoint $p $root $required 'before-retry')
                [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $root -Identity $p.Identity -AdoptIdenticalExisting)
                [void](Write-CodiesVRCheckpoint $p $root $required 'after-retry')
            }.GetNewClosure()
            $recoveryInput=if($env:PCVR_HUB_TEST_MODE -eq '1'){{'Q'}}else{$null}
            if(-not(Confirm-PlacedFilesSurvive -Paths @($required|ForEach-Object{Join-Path $root $_}) -GameDir $root -WaitSeconds 0 -Recopy $retry -ReadInput $recoveryInput -NoClear)){throw 'Required files disappeared after copying. Setup was cancelled and previous files will be restored.'}
        }
        [void](Write-CodiesVRCheckpoint $p $root $required 'before-commit')
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1'){$env:PCVR_CODIES_TEST_RECEIPT}else{Join-Path $InstallerFolder '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $root -Version $version -Route $route -InstalledPathReceiptPaths @($receipt) -AdditionalVersionReceiptPaths @((Join-Path $root $versionFile)))
        $changed=$false
        Sync-CodiesVRLaunchState -Profile $p -Root $root
        Write-Host "  [OK] $($p.Title) $version is installed." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub with your headset connected and OpenXR active.' -ForegroundColor Green
        Write-Host "  Alternative: start the game normally through $(if($route -eq 'Steam'){'Steam'}else{'the EA app'})." -ForegroundColor White
        if($Key -eq 'Grid2019'){Write-Host '  IMPORTANT: choose DirectX 12 when Steam asks. The DirectX 11 version cannot enter VR.' -ForegroundColor Yellow}
        if($Key -eq 'GridLegends'){Write-Host '  F10 opens the VR menu; F5 recenters; F8 toggles the HUD.' -ForegroundColor Cyan}
        else{Write-Host '  Insert opens the VR menu; Home recenters; Page Up toggles the HUD.' -ForegroundColor Cyan}
        Write-Host '  Prefer VDXR where supported. If movement ghosts, try Mono mode or disable runtime motion smoothing.' -ForegroundColor Yellow
        Write-Host '  Choose render resolution in the mod menu. Keep ordinary frame generation off in alternate-eye mode.' -ForegroundColor White
        if($Key -eq 'Dirt4'){Write-Host '  Start with Alternate-eye mode. Native stereo is experimental.' -ForegroundColor Yellow}
        if($Key -eq 'GridLegends'){Write-Host '  Optional: Settings > Install Optiscaler offers the publisher upscaler package. Finish or skip its DLSS prompt; wait for completion before restarting.' -ForegroundColor White}
        if($report){$reportPath=Complete-PCVRInstallerTestReport -Session $report -Outcome Success -ModVersion $version;Show-PCVRInstallerTestReportResult -ReportPath $reportPath}
        Write-Host '';Write-Host ('  '+$p.Quip) -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        $failure=$_
        if($changed -and $snapshot -and $root){
            [void](Write-CodiesVRCheckpoint $p $root $required 'before-rollback')
            Restore-PCVRPublisherZipSnapshot -GameRoot $root -Snapshot $snapshot
            [void](Write-CodiesVRCheckpoint $p $root $required 'after-rollback')
            Write-Host '  Previous files were restored.' -ForegroundColor Yellow
        }
        Write-Host ('  Setup did not complete: '+$failure.Exception.Message) -ForegroundColor Red
        if($report -and -not $report.Completed){try{$reportPath=Complete-PCVRInstallerTestReport -Session $report -Outcome Failed -FailureMessage $failure.Exception.Message -ModVersion $version;Show-PCVRInstallerTestReportResult -ReportPath $reportPath}catch{Write-Host ('  [!!] The test report could not be saved: '+$_.Exception.Message) -ForegroundColor Yellow}}
        throw $failure
    }finally{
        if($report -and -not $report.Completed){try{[void](Complete-PCVRInstallerTestReport $report -Outcome Cancelled)}catch{}}
        if($work){Remove-PCVRInstallerTempSession -Path $work}
    }
}
