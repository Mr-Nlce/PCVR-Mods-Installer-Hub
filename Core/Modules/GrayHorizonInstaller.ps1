# Game-specific GrayHorizon entry points use the same transactional drop-in flow.
. (Join-Path $PSScriptRoot 'InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'PublisherZipTransaction.ps1')
function Get-GrayHorizonRoute([string]$Root,[int]$Number) {
    if(-not $Root -or -not(Test-Path -LiteralPath (Join-Path $Root "ForzaHorizon$Number.exe") -PathType Leaf)){return ''}
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
        if(-not [IO.Path]::GetFullPath($Root).StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $Root 'grayhorizon-fixture.txt') -PathType Leaf)){throw 'GrayHorizon tests require an isolated game fixture.'}
        $route=[string]$env:PCVR_GH_TEST_ROUTE
        if($route -eq 'Steam' -or ($Number -ne 4 -and $route -eq 'Xbox')){return $route}
        return ''
    }
    $app=@{4='1293830';5='1551360';6='2483190'}[$Number]
    $manifest=Join-Path (Split-Path -Parent (Split-Path -Parent $Root)) "appmanifest_$app.acf"
    if((Test-Path -LiteralPath $manifest -PathType Leaf) -and $Root -match '(?i)[\\/]steamapps[\\/]common[\\/]'){return 'Steam'}
    if($Number -ne 4 -and (Test-Path -LiteralPath (Join-Path $Root 'MicrosoftGame.config') -PathType Leaf)){return 'Xbox'}
    return ''
}
function Get-GrayHorizonGame([int]$Number,[string]$Id) {
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        $r=Get-GrayHorizonRoute $env:PCVR_GH_TEST_GAME $Number
        if(-not $r){throw "This Forza Horizon $Number store/build is not supported."}
        return [pscustomobject]@{Root=[IO.Path]::GetFullPath($env:PCVR_GH_TEST_GAME);Route=$r}
    }
    $exe="ForzaHorizon$Number.exe";$c=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $Id -StateNames @('installed_path','user_located') -ProbeFiles @($exe)
    if($saved){$c+=$saved}
    try{$s=Find-SteamGameFolder -AppId (@{4='1293830';5='1551360';6='2483190'}[$Number]) -SteamFolderNames @("ForzaHorizon$Number","Forza Horizon $Number") -ProbeExe $exe -HubGameId $Id;if($s){$c+=$s}}catch{}
    if($Number -ne 4){
        $c+="C:\XboxGames\Forza Horizon $Number\Content"
        foreach($drive in Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue){$c+=Join-Path $drive.Root "XboxGames\Forza Horizon $Number\Content"}
    }
    foreach($p in @($c|Select-Object -Unique)){$r=Get-GrayHorizonRoute $p $Number;if($r){return [pscustomobject]@{Root=[IO.Path]::GetFullPath($p);Route=$r}}}
    $picked=Get-GameFolderInteractive -GameName "Forza Horizon $Number" -ProbeFile $exe
    $r=Get-GrayHorizonRoute $picked $Number
    if(-not $r){throw "Choose the Steam game folder$(if($Number -ne 4){' or Xbox Content folder'}). FH4 supports Steam only."}
    [void](Save-HubRememberedGameFolder -GameId $Id -Title "Forza Horizon $Number VR - GrayHorizon" -GameDir $picked -ProbeFiles @($exe) -UserSelected)
    return [pscustomobject]@{Root=[IO.Path]::GetFullPath($picked);Route=$r}
}
function Get-GrayHorizonStoreTarget([string]$Root,[int]$Number,[string]$Route) {
    if($Route -eq 'Steam'){return "steam://rungameid/$(@{4='1293830';5='1551360';6='2483190'}[$Number])"}
    if($env:PCVR_HUB_TEST_MODE -eq '1'){return "shell:AppsFolder\PCVRFixture.FH$Number!Game"}
    [xml]$config=[IO.File]::ReadAllText((Join-Path $Root 'MicrosoftGame.config'))
    $identity=[string]$config.Game.Identity.Name
    $exe=@($config.Game.ExecutableList.Executable|Where-Object{[string]$_.Name -ieq "ForzaHorizon$Number.exe"}|Select-Object -First 1)
    $package=@()
    if($identity){try{$package=@(Get-AppxPackage -Name $identity -ErrorAction SilentlyContinue|Select-Object -First 1)}catch{}}
    if($identity -and $exe.Count -and $package.Count -and $package[0].PackageFamilyName -and $exe[0].Id){return "shell:AppsFolder\$($package[0].PackageFamilyName)!$($exe[0].Id)"}
    $start=@()
    try{$start=@(Get-StartApps -ErrorAction SilentlyContinue|Where-Object{$_.Name -eq "Forza Horizon $Number"}|Select-Object -First 1)}catch{}
    if($start.Count -and $start[0].AppID){return "shell:AppsFolder\$($start[0].AppID)"}
    throw 'The Xbox application launch identity was not found. Launch the game once from the Xbox app and retry. No VR files were changed.'
}
function Get-GrayHorizonArchive([int]$Number,[string]$Destination) {
    if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_GH_TEST_ARCHIVE){Copy-Item -LiteralPath $env:PCVR_GH_TEST_ARCHIVE -Destination $Destination -Force -ErrorAction Stop;return}
    $page='https://github.com/GrayHorizon-mod/Forza-Horizon-VR/releases'
    try{$release=Resolve-GitHubReleaseAsset -Repo 'GrayHorizon-mod/Forza-Horizon-VR' -IncludePrerelease $false -AssetPatterns @("(?i)^GrayHorizon-FH$Number-.+\.zip$") -SkipReleasesWithoutMatchingAsset}catch{$release=$null}
    if($release -and $release.Resolved -and $release.Url){[void](Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $Destination -Label "GrayHorizon FH$Number" -ManualUrl $page -AllowSkip:$false);return [string]$release.Tag}
    Write-Host '  [!!] The release could not be resolved automatically. Download the ZIP for this game from its official release page.' -ForegroundColor Yellow
    [void](Open-PCVRPageAfterEnter -Url $page -Message 'Press Enter to open the official GrayHorizon releases...')
    while($true){
        [void](Wait-PCVRExplicitEnter -Message "After downloading the FH$Number ZIP, press Enter to check Downloads...")
        $found=Find-PCVRDownloadedCandidate -Patterns @("GrayHorizon-FH$Number-*.zip")
        if($found){Write-Host "  Found: $found" -ForegroundColor Cyan;if((Read-Host '  Use this ZIP? Y/N').Trim() -match '^(?i:y|yes)$'){Copy-Item -LiteralPath $found -Destination $Destination -Force;return}}
        $path=(Read-Host '  Drag/paste the ZIP path, or press Enter to reopen the release page').Trim().Trim('"').Trim("'")
        if($path -and (Test-Path -LiteralPath $path -PathType Leaf)){Copy-Item -LiteralPath $path -Destination $Destination -Force;return}
        [void](Open-PCVRPageAfterEnter -Url $page -Message 'Press Enter to reopen the official releases...')
    }
}
function Show-GrayHorizonRequiredSettings([int]$Number) {
    Write-Host ''
    Write-Host '  REQUIRED IN-GAME SETTINGS' -ForegroundColor Green
    Write-Host '  Video: V-Sync OFF, frame rate UNLOCKED, motion blur OFF.' -ForegroundColor Yellow
    Write-Host '  Turn OFF the game''s TAA/FXAA/DLSS/FSR/XeSS/CAS and Frame Generation.' -ForegroundColor Yellow
    Write-Host '  Use the mod''s own upscaler/AA. Turn MSAA off when using its upscaler.' -ForegroundColor White
    if($Number -ne 4){Write-Host '  HDR OFF (also check Windows HDR if the option is unavailable).' -ForegroundColor Yellow}
    $hud=if($Number -eq 4){'Horizontal 8 / Vertical 37'}else{'Horizontal 5 / Vertical 9'}
    Write-Host "  HUD and gameplay > HUD Safe Frame: $hud." -ForegroundColor Yellow
    Write-Host '  Data Out: ON, IP 127.0.0.1, port 20440. This enables per-car HUD layouts.' -ForegroundColor Yellow
    if($Number -eq 6){Write-Host '  Radar position: Center right.' -ForegroundColor Yellow}
    Write-Host '  If using SimHub/a rig, forward its old telemetry destination in GrayHorizon Settings.' -ForegroundColor White
}
function New-GrayHorizonShortcut([string]$Path,[string]$Root,[int]$Number,[string]$Target) {
    $shell=New-Object -ComObject WScript.Shell
    try{
        $link=$shell.CreateShortcut($Path);$link.TargetPath=Join-Path $env:WINDIR 'explorer.exe'
        $link.Arguments=$Target;$link.WorkingDirectory=$Root;$link.IconLocation=(Join-Path $Root "ForzaHorizon$Number.exe")+',0'
        $link.Description="Start Forza Horizon $Number with GrayHorizon VR";$link.Save()
    }finally{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell)}
}
function Write-GrayHorizonPlacementCheckpoint([string]$Root,[string[]]$Files,[string]$Phase) {
    $missing=@();$items=@()
    foreach($name in $Files){
        $exists=Test-Path -LiteralPath (Join-Path $Root $name) -PathType Leaf
        $items+="$name=$exists"
        if(-not $exists){$missing+=$name}
    }
    $log=Join-Path $Root '.pcvrhub_grayhorizon_install.log'
    if((Test-Path -LiteralPath $log) -and (Get-Item -LiteralPath $log).Length -gt 1048576){[IO.File]::WriteAllText($log,'Earlier placement diagnostics rotated.'+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))}
    [IO.File]::AppendAllText($log,((Get-Date -Format o)+' '+$Phase+' '+($items -join '; ')+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
    return $missing
}
function Invoke-GrayHorizonInstaller([int]$Number,[string]$InstallerFolder) {
    $ErrorActionPreference='Stop'
    $id="forza-horizon-$Number-grayhorizon-vr";$identity="grayhorizonfh$Number"
    $title="Forza Horizon $Number VR - GrayHorizon";$manifest=".pcvrhub_${identity}_ownership.csv"
    $versionFile='.pcvrhub_grayhorizon_version';$work=$null;$game=$null;$snapshot=$null;$changed=$false
    $report=Start-PCVRInstallerTestReport -InstallerId $id -GameTitle $title -ModName 'GrayHorizon' -FileStem "forza-horizon-$Number-grayhorizon" -InstallerFolder $InstallerFolder
    try{
        if($env:PCVR_HUB_TEST_MODE -ne '1'){Clear-Host}
        $Host.UI.RawUI.WindowTitle="$title Installer"
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host "  $title" -ForegroundColor Cyan
        Write-Host '  Untested Hub installer - help us confirm it on a real game' -ForegroundColor White
        Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host "  $(if($Number -eq 4){'Steam only.'}else{'Steam or Xbox/Game Pass.'}) OpenXR cockpit VR; use a gamepad or wheel." -ForegroundColor White
        Write-Host '  Close other VR launchers. Online use is at your own risk.' -ForegroundColor Yellow
        Write-Host '  Your saves, HUD layouts and existing configuration are preserved.' -ForegroundColor White
        Write-Host '  A report in Hub Core\Logs\Untested records the files before/after installation and this installer log.' -ForegroundColor Cyan
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message "After reading this, press Enter to locate Forza Horizon $Number...")
        $game=Get-GrayHorizonGame $Number $id;$root=$game.Root
        Write-Host "  [OK] Game ($($game.Route)): $root" -ForegroundColor Green
        Add-PCVRInstallerTestReportTarget -Session $report -Path $root -GameDir $root -Route $game.Route
        if(Get-Process -Name "ForzaHorizon$Number" -ErrorAction SilentlyContinue){throw 'Close the game before installing or updating GrayHorizon.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $root)){throw 'The game folder is not writable. Run the Hub as administrator for this Xbox/protected-folder installation, then retry.'}
        if((Test-Path -LiteralPath (Join-Path $root 'dxgi.dll')) -or (Test-Path -LiteralPath (Join-Path $root '.vrmod_install.json'))){throw 'A different DXGI/VR deployment is present. Remove the active VR mod through its existing Hub tile/launcher before testing GrayHorizon; keep your saves and original game. No files were changed.'}
        $target=Get-GrayHorizonStoreTarget $root $Number $game.Route
        Show-GrayHorizonRequiredSettings $Number
        if(-not(Test-Path -LiteralPath (Join-Path $root "gh${Number}vr.ini"))){
            Write-Host '  Set these options in the normal game now, save them, then exit the game.' -ForegroundColor Green
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the game and configure these settings...')
            if($env:PCVR_HUB_TEST_MODE -ne '1'){Start-Process -FilePath (Join-Path $env:WINDIR 'explorer.exe') -ArgumentList $target -ErrorAction Stop}
            [void](Wait-PCVRExplicitEnter -Message 'After saving the settings and closing the game, press Enter to continue...')
            if(Get-Process -Name "ForzaHorizon$Number" -ErrorAction SilentlyContinue){throw 'The game is still running. Close it, then Retry.'}
        }
        [void](Wait-PCVRExplicitEnter -Message "Press Enter to check and download GrayHorizon for FH$Number...")
        $tempBase=if($env:PCVR_HUB_TEST_MODE -eq '1'){$env:PCVR_HUB_TEST_LOCALAPPDATA}else{[IO.Path]::GetTempPath()}
        $work=New-PCVRInstallerTempSession -BasePath $tempBase
        $archive=Join-Path $work 'GrayHorizon.zip';$releaseVersion=Get-GrayHorizonArchive $Number $archive
        $stage=Join-Path $work 'stage';$safe=Test-ZipArchiveEntrySafety -ArchivePath $archive -DestinationFolder $stage
        if(-not $safe.Safe -or -not $safe.Inspectable){throw 'The publisher ZIP is unreadable or contains unsafe paths.'}
        if((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $stage -Label "GrayHorizon FH$Number" -AllowSkip:$false -QuietProgress) -ne 'ok'){throw 'The complete publisher ZIP could not be extracted.'}
        $required=@('xinput1_3.dll','openxr_loader.dll','GrayHorizon Settings.exe',"gh${Number}vr.ini")
        if($Number -eq 4){$required+=@('nvngx_dlss.dll','amd_fidelityfx_loader_dx12.dll','amd_fidelityfx_upscaler_dx12.dll')}
        foreach($name in $required){if(-not(Test-Path -LiteralPath (Join-Path $stage $name) -PathType Leaf)){throw "The publisher package lacks $name. Choose the complete FH$Number ZIP."}}
        $version=[Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $stage 'xinput1_3.dll')).FileVersion
        if(-not(Test-IsTrackableInstalledVersion $version)){$version=[string]$releaseVersion}
        if(-not(Test-IsTrackableInstalledVersion $version)){
            $version=(Read-Host '  Release version shown on the official page for this ZIP').Trim()
            if(-not(Test-IsTrackableInstalledVersion $version)){throw 'No exact release version was confirmed; no game files were changed.'}
        }
        if($game.Route -eq 'Xbox'){Move-Item -LiteralPath (Join-Path $stage 'xinput1_3.dll') -Destination (Join-Path $stage 'xinput1_4.dll');$required[0]='xinput1_4.dll'}
        $linkName='Start GrayHorizon VR.lnk'
        New-GrayHorizonShortcut -Path (Join-Path $stage $linkName) -Root $root -Number $Number -Target $target
        $required+=@($linkName,$manifest)
        $routes=if($Number -eq 4){@('Steam')}else{@('Steam','Xbox')}
        $contract=New-PCVRInstallerContract -Id $id -GameName $title -Acquisition GitHub -Routes $routes -AntivirusNotice -ReleasePageUrl 'https://github.com/GrayHorizon-mod/Forza-Horizon-VR/releases' -RequiredInstalledFileGroups (@("ForzaHorizon$Number.exe")+$required)
        $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $root -Stage $stage -Identity $identity -SnapshotRoot (Join-Path $work 'rollback') -ExtraPaths @($versionFile)
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to install or update the complete GrayHorizon package...')
        Write-Host '  Backing up existing files, copying the mod and checking it; this may take a few seconds.' -ForegroundColor Cyan
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $root -Identity $identity -KeepExistingRelativePaths @("gh${Number}vr.ini") -AdoptIdenticalExisting -ReplaceChangedOwnedRelativePaths @('xinput1_3.dll','xinput1_4.dll','openxr_loader.dll','GrayHorizon Settings.exe','nvngx_dlss.dll','amd_fidelityfx_loader_dx12.dll','amd_fidelityfx_upscaler_dx12.dll'))
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_GH_TEST_FAILURE -eq 'copy-missing'){Remove-Item -LiteralPath (Join-Path $root 'openxr_loader.dll') -Force}
        $missing=@(Write-GrayHorizonPlacementCheckpoint -Root $root -Files $required -Phase 'immediately-after-copy')
        if($missing.Count){throw ('Required files were not placed: '+($missing -join ', ')+'. A copy, path or permission problem is possible. No antivirus cause has been established.')}
        if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_GH_TEST_FAILURE -eq 'vanish'){Remove-Item -LiteralPath (Join-Path $root 'openxr_loader.dll') -Force}
        Start-Sleep -Seconds 3
        $missing=@(Write-GrayHorizonPlacementCheckpoint -Root $root -Files $required -Phase 'after-observation')
        if($missing.Count){
            $retry={
                [void](Write-GrayHorizonPlacementCheckpoint -Root $root -Files $required -Phase 'before-retry')
                [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $root -Identity $identity -KeepExistingRelativePaths @("gh${Number}vr.ini") -AdoptIdenticalExisting)
                [void](Write-GrayHorizonPlacementCheckpoint -Root $root -Files $required -Phase 'after-retry')
            }.GetNewClosure()
            $recoveryInput=if($env:PCVR_HUB_TEST_MODE -eq '1'){{'Q'}}else{$null}
            if(-not(Confirm-PlacedFilesSurvive -Paths @($required|ForEach-Object{Join-Path $root $_}) -GameDir $root -WaitSeconds 0 -Recopy $retry -ReadInput $recoveryInput -NoClear)){throw 'Required GrayHorizon files disappeared after copying; setup was cancelled and the earlier files will be restored.'}
        }
        [void](Write-GrayHorizonPlacementCheckpoint -Root $root -Files $required -Phase 'before-commit')
        $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1'){$env:PCVR_GH_TEST_RECEIPT}else{Join-Path $InstallerFolder '.installed_path'}
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $root -Version $version -InstalledPathReceiptPaths @($receipt) -AdditionalVersionReceiptPaths @((Join-Path $root $versionFile)) -Route $game.Route)
        $changed=$false
        $desktop=if($env:PCVR_HUB_TEST_MODE -eq '1'){$env:PCVR_TEST_REPORT_DIR}else{[Environment]::GetFolderPath('DesktopDirectory')}
        $desktopLabel="Forza Horizon $Number - GrayHorizon VR ($($game.Route))"
        $desktopLink=Join-Path $desktop ($desktopLabel+'.lnk')
        try{if(-not(Test-Path -LiteralPath $desktopLink)){Copy-Item -LiteralPath (Join-Path $root $linkName) -Destination $desktopLink -ErrorAction Stop}}catch{Write-Host '  The Desktop shortcut could not be saved. Start in VR in the Hub remains available.' -ForegroundColor Yellow}
        Write-Host "  [OK] GrayHorizon $version is installed." -ForegroundColor Green
        Write-Host '  1. Use Start in VR in the Hub with your headset connected and OpenXR ready.' -ForegroundColor Green
        Write-Host "  Alternative: start from $(if($game.Route -eq 'Steam'){'Steam'}else{'the Xbox app'}) or the $desktopLabel Desktop shortcut." -ForegroundColor White
        Write-Host '  Switch to cockpit view. Restart once after the first headset launch for the correct render size.' -ForegroundColor Yellow
        Write-Host '  Press Ctrl+Space to recenter; F12 opens the VR menu.' -ForegroundColor White
        Write-Host '  Play a few minutes, then use Provide feedback in the Hub to share your test-result.txt.' -ForegroundColor Cyan
        try {
            $reportPath=Complete-PCVRInstallerTestReport -Session $report -Outcome Success -ModVersion $version
            Show-PCVRInstallerTestReportResult -ReportPath $reportPath
        } catch {Write-Host ('  [!!] The test report could not be saved: '+$_.Exception.Message) -ForegroundColor Yellow}
        Write-Host ''
        $quip=@{4='Four seasons, one insurance claim.';5='The festival has requested that you stop using cacti as apex markers.';6='The racing line is a suggestion. The guardrail is less flexible.'}[$Number]
        Write-Host "  $quip" -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        $installError=$_
        if($changed -and $snapshot -and $game){
            [void](Write-GrayHorizonPlacementCheckpoint -Root $game.Root -Files $required -Phase 'before-rollback')
            Restore-PCVRPublisherZipSnapshot -GameRoot $game.Root -Snapshot $snapshot
            [void](Write-GrayHorizonPlacementCheckpoint -Root $game.Root -Files $required -Phase 'after-rollback')
            Write-Host '  Previous files were restored.' -ForegroundColor Yellow
        }
        Write-Host ('  Setup did not complete: '+$installError.Exception.Message) -ForegroundColor Red
        try {
            $reportPath=Complete-PCVRInstallerTestReport -Session $report -Outcome Failed -FailureMessage $installError.Exception.Message -ModVersion ([string]$version)
            Show-PCVRInstallerTestReportResult -ReportPath $reportPath
        } catch {Write-Host ('  [!!] The test report could not be saved: '+$_.Exception.Message) -ForegroundColor Yellow}
        throw $installError
    }finally{
        if(-not $report.Completed){try{[void](Complete-PCVRInstallerTestReport -Session $report -Outcome Cancelled)}catch{}}
        if($work){Remove-PCVRInstallerTempSession -Path $work}
    }
}

