# Gothic II VR PCVR: a separate publisher runtime reading owned Gold/NotR data.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$APP_ID='39510';$REPO='dubrovskiy-yevhen-stakelogic/gothic2-vr';$IDENTITY='gothicii'
$RELEASES="https://github.com/$REPO/releases"
$FALLBACK_TAG='v0.2.0';$FALLBACK_ASSET='Gothic-II-VR-0.2.0-PCVR-and-Quest.zip'
$FALLBACK_URL='https://github.com/dubrovskiy-yevhen-stakelogic/gothic2-vr/releases/download/v0.2.0/Gothic-II-VR-0.2.0-PCVR-and-Quest.zip'
$DEFAULT_TARGET='C:\Games\Gothic II VR'
$REQUIRED=@('Gothic2Notr.exe','openxr_loader.dll','Tempest.dll','dxcompiler.dll','dxil.dll',
    'Start-PCVR.ps1','START-PCVR.cmd','START-STEAMVR.cmd','START-OCULUS.cmd',
    'START-VIRTUAL-DESKTOP.cmd','vrhands\BigHandLeft.uxrh','vrhands\BigHandRight.uxrh',
    'launcher-game-path.txt',".pcvrhub_${IDENTITY}_ownership.csv")
$CONTRACT=New-PCVRInstallerContract -Id 'gothic-ii-vr' -GameName 'Gothic II VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $RELEASES -Routes @('Standalone') -RequiredInstalledFileGroups $REQUIRED

function Test-GothicBase([string]$Path){
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'system\Gothic2.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path 'Data') -PathType Container))
}
function Get-GothicBaseRoot([scriptblock]$ReadInput=$null){
    $candidates=[Collections.Generic.List[string]]::new()
    $saved=Get-PCVRRememberedGameFolder -GameId 'gothic-ii-vr' -StateNames @('base_game_path','user_located') -ProbeFiles @('system\Gothic2.exe')
    if($saved){$candidates.Add($saved)}
    try{$steam=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Gothic II') -ProbeExe 'system\Gothic2.exe' -HubGameId 'gothic-ii-vr';if($steam){$candidates.Add($steam)}}catch{}
    foreach($path in @('C:\Program Files (x86)\Steam\steamapps\common\Gothic II',
        'C:\Program Files (x86)\GOG Galaxy\Games\Gothic 2 Gold','C:\GOG Games\Gothic 2 Gold',
        'C:\Program Files (x86)\JoWooD\Gothic II',
        'C:\Program Files (x86)\JoWooD Productions Software AG\Gothic II Gold')){$candidates.Add($path)}
    foreach($path in @($candidates|Select-Object -Unique)){if(Test-GothicBase $path){return (Get-Item -LiteralPath $path).FullName}}
    Write-Host '  Gothic II Gold / Night of the Raven data were not found.' -ForegroundColor Yellow
    Write-Host '  Select the purchased game folder containing Data and system\Gothic2.exe.' -ForegroundColor White
    while($true){
        $raw=if($ReadInput){& $ReadInput}else{Read-Host 'Game folder (drag/paste path, Q to cancel)'}
        $path=(''+$raw).Trim().Trim('"').Trim("'")
        if($path -ieq 'Q'){return $null}
        if(Test-GothicBase $path){return (Get-Item -LiteralPath $path).FullName}
        Write-Host '  The selected folder needs Data and system\Gothic2.exe.' -ForegroundColor Yellow
    }
}
function Get-GothicTargetRoot([string]$Base,[scriptblock]$ReadInput=$null){
    $remembered=$null
    try{$remembered=([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"')}catch{}
    if(-not $remembered){$remembered=Get-PCVRRememberedGameFolder -GameId 'gothic-ii-vr' -StateNames @('installed_path') -ProbeFiles @('Gothic2Notr.exe')}
    $default=if($remembered -and (Test-Path -LiteralPath $remembered -PathType Container)){$remembered}else{$DEFAULT_TARGET}
    while($true){
        Write-Host "  PCVR folder: $default" -ForegroundColor Cyan
        $raw=if($ReadInput){& $ReadInput}else{Read-Host 'Enter = use this folder; paste another folder; Q = cancel'}
        $value=(''+$raw).Trim().Trim('"').Trim("'")
        if($value -ieq 'Q'){return $null}
        $target=if($value){$value}else{$default}
        try{$target=[IO.Path]::GetFullPath($target).TrimEnd('\','/');$baseFull=[IO.Path]::GetFullPath($Base).TrimEnd('\','/')
            $hubRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\','/')
            if($target -ieq $baseFull -or $target.StartsWith($baseFull+'\',[StringComparison]::OrdinalIgnoreCase) -or
                $target -ieq $hubRoot -or $target.StartsWith($hubRoot+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Choose a separate folder outside the purchased game and Hub.'}
            if(-not(Test-InstallerTargetWritable -TargetPath $target)){throw 'The selected folder is not writable. Choose another folder or Q to cancel.'}
            return $target
        }catch{Write-Host ('  Invalid target: '+$_.Exception.Message) -ForegroundColor Yellow}
    }
}
function Get-GothicRelease {
    $r=Resolve-GitHubReleaseAsset -Repo $REPO -AssetPatterns @('(?i)^Gothic-II-VR-[0-9].*-PCVR-and-Quest\.zip$') `
        -IncludePrerelease $true -SkipReleasesWithoutMatchingAsset -FallbackUrl $FALLBACK_URL `
        -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_ASSET
    if(-not(Test-IsTrackableInstalledVersion ([string]$r.Tag))){throw 'GitHub did not return a trackable Gothic II VR version.'}
    return $r
}
function New-GothicStage([string]$Archive,[string]$Work){
    $outer=Join-Path $Work 'outer';$result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $outer -Label 'Gothic II VR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The Gothic II VR publisher ZIP could not be opened.'}
    $stage=Join-Path $outer 'PCVR'
    foreach($name in @($REQUIRED|Where-Object{$_ -notin @('launcher-game-path.txt',".pcvrhub_${IDENTITY}_ownership.csv")})){
        if(-not(Test-Path -LiteralPath (Join-Path $stage $name) -PathType Leaf)){throw "PCVR publisher payload is missing $name"}
    }
    foreach($name in @('VR.ini','Gamepad.ini','Gothic.ini','launcher-game-path.txt')){
        if(Test-Path -LiteralPath (Join-Path $stage $name)){throw "Publisher archive unexpectedly contains user profile file $name"}
    }
    return $stage
}
function Save-GothicSnapshot([string]$Target,[string]$Stage,[string]$Destination){
    [void][IO.Directory]::CreateDirectory($Destination);$paths=[Collections.Generic.List[string]]::new()
    foreach($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)){$paths.Add($file.FullName.Substring($Stage.Length+1))}
    $manifest=Join-Path $Target ".pcvrhub_${IDENTITY}_ownership.csv"
    if(Test-Path -LiteralPath $manifest){foreach($row in @(Import-Csv -LiteralPath $manifest)){if($row.RelativePath){$paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)))}}}
    foreach($name in @('launcher-game-path.txt',".pcvrhub_${IDENTITY}_ownership.csv",'.pcvrhub_version')){$paths.Add($name)}
    $records=@();foreach($rel in @($paths|Select-Object -Unique)){$source=Join-Path $Target $rel;$exists=Test-Path -LiteralPath $source -PathType Leaf;$records+=[pscustomobject]@{Relative=$rel;Exists=$exists};if($exists){$copy=Join-Path (Join-Path $Destination 'files') $rel;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy));Copy-Item -LiteralPath $source -Destination $copy -Force}}
    $backup=Join-Path $Target ".pcvrhub_${IDENTITY}_backup";$hasBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hasBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $Destination 'ownership-backup') -Recurse -Force}
    return [pscustomobject]@{Records=$records;HasBackup=$hasBackup;Folder=$Destination}
}
function Restore-GothicSnapshot([string]$Target,$Snapshot){
    foreach($record in @($Snapshot.Records)){$path=Join-Path $Target ([string]$record.Relative);if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force};if($record.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $path));Copy-Item -LiteralPath (Join-Path (Join-Path $Snapshot.Folder 'files') ([string]$record.Relative)) -Destination $path -Force}}
    $backup=Join-Path $Target ".pcvrhub_${IDENTITY}_backup";if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Recurse -Force};if($Snapshot.HasBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Folder 'ownership-backup') -Destination $backup -Recurse -Force}
}
function global:Invoke-GothicIIVRInstaller {
    $work=$null;$target=$null;$snapshot=$null;$changed=$false
    try{
        Clear-Host;Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Gothic II VR Installer' -ForegroundColor Cyan
        Write-Host '  PCVR alpha by dubrovskiy-yevhen-stakelogic' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  Requires your own Gothic II Gold / Night of the Raven installation.' -ForegroundColor White
        Write-Host '  This setup reads its data but installs VR into a separate folder.' -ForegroundColor White
        Write-Host '  SteamVR, Meta Link and Virtual Desktop have publisher launchers.' -ForegroundColor White
        Write-Host '  The Hub Start button uses your currently selected OpenXR runtime.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to continue...')
        Write-Host '  [1/4] Find Gothic II Gold / Night of the Raven' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        $base=Get-GothicBaseRoot;if(-not $base){return}
        $target=Get-GothicTargetRoot -Base $base;if(-not $target){return}
        if(Get-Process -Name 'Gothic2Notr' -ErrorAction SilentlyContinue){throw 'Close Gothic II VR before installing.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $target)){throw 'The PCVR target folder is not writable.'}
        Write-Host '  [2/4] Download and inspect the PCVR release' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        Write-Host '  The next step checks the official GitHub release and downloads its ZIP.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download Gothic II VR...')
        $release=Get-GothicRelease
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_gothicii_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'GothicIIVR.zip'
        $download=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "Gothic II VR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if($download -ne $true -and [string]$download -notin @('retry','manual')){throw 'Gothic II VR download was not completed.'}
        $stage=New-GothicStage -Archive $archive -Work $work
        Write-Host '  [3/4] Install the separate PCVR runtime' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        $snapshot=Save-GothicSnapshot -Target $target -Stage $stage -Destination (Join-Path $work 'rollback');$changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $target -Identity $IDENTITY -AdoptIdenticalExisting -ProgressLabel 'Installing Gothic II PCVR files')
        Write-PCVRAtomicText -Path (Join-Path $target 'launcher-game-path.txt') -Value $base
        foreach($name in $REQUIRED){if(-not(Test-Path -LiteralPath (Join-Path $target $name) -PathType Leaf)){throw "Installed Gothic II VR file is missing: $name"}}
        if(-not(Confirm-PlacedFilesSurvive -Paths @($REQUIRED|ForEach-Object{Join-Path $target $_}) -GameDir $target -NoClear)){throw 'Required Gothic II VR files did not survive installation.'}
        [void](Complete-PCVRInstallTransaction -Contract $CONTRACT -GameDir $target -Version ([string]$release.Tag) -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Standalone)
        $changed=$false
        [void](Save-HubRememberedGameFolder -GameId 'gothic-ii-vr' -Title 'Gothic II VR' -GameDir $base -ProbeFiles @('system\Gothic2.exe') -StateName 'base_game_path')
        [void](Save-HubRememberedGameFolder -GameId 'gothic-ii-vr' -Title 'Gothic II VR' -GameDir $base -ProbeFiles @('system\Gothic2.exe') -StateName 'user_located')
        Write-Host '  [4/4] Finish and start with OpenXR' -ForegroundColor Cyan
        Write-Host '  ----------------------------------------' -ForegroundColor DarkGray
        Write-Host "  [OK] PCVR $($release.Tag) installed in $target" -ForegroundColor Green
        Write-Host '  Start in VR uses active OpenXR; the three named runtime scripts are also in that folder.' -ForegroundColor Yellow
        Write-Host '  Headset and gameplay remain unverified until you start your own copy.' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  The Valley of Mines is closer than ever.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{if($changed -and $target -and $snapshot){try{Restore-GothicSnapshot -Target $target -Snapshot $snapshot;Write-Host '  Previous PCVR files restored.' -ForegroundColor Yellow}catch{Write-Host ('  Rollback needs attention: '+$_.Exception.Message) -ForegroundColor Red}};throw}
    finally{if($work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if(((''+$env:PCVR_GOTHICII_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-GothicIIVRInstaller}
