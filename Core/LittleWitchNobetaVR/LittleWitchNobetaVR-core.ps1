$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$REPO='Pk-c/WitchNobetaVR'
$RELEASES="https://github.com/$REPO/releases"
$FALLBACK_TAG='v0.1.1'
$FALLBACK_ASSET='NobetaVR-0.1.1.zip'
$FALLBACK_URL='https://github.com/Pk-c/WitchNobetaVR/releases/download/v0.1.1/NobetaVR-0.1.1.zip'
$IDENTITY='nobetavr'
$GAME_ID='little-witch-nobeta-vr'
$GAME_EXE='LittleWitchNobeta.exe'
$PROOF=@('BepInEx\plugins\NobetaVR.dll','BepInEx\core\BepInEx.Unity.IL2CPP.dll',
    'winhttp.dll','doorstop_config.ini','dotnet\hostpolicy.dll',
    'LittleWitchNobeta_Data\Plugins\x86_64\openxr_loader.dll',
    'LittleWitchNobeta_Data\Plugins\x86_64\UnityOpenXR.dll',
    'LittleWitchNobeta_Data\UnitySubsystems\UnityOpenXR\UnitySubsystemsManifest.json')
$CONTRACT=New-PCVRInstallerContract -Id $GAME_ID -GameName 'Little Witch Nobeta VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $RELEASES `
    -RequiredInstalledFileGroups @($PROOF + @('.pcvrhub_nobetavr_ownership.csv'))

function Test-NobetaGame([string]$Path){
    if(-not $Path){return $false}
    return [bool]((Test-Path -LiteralPath ([IO.Path]::Combine($Path,$GAME_EXE)) -PathType Leaf) -and
        (Test-Path -LiteralPath ([IO.Path]::Combine($Path,'LittleWitchNobeta_Data','globalgamemanagers')) -PathType Leaf))
}
function Get-NobetaGameRoot([scriptblock]$ReadInput=$null){
    $candidates=[Collections.Generic.List[string]]::new()
    try{$saved=([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"');if($saved){$candidates.Add($saved)}}catch{}
    try{$saved=Get-PCVRRememberedGameFolder -GameId $GAME_ID -StateNames @('installed_path','user_located') -ProbeFiles @($GAME_EXE);if($saved){$candidates.Add($saved)}}catch{}
    try{$found=Find-SteamGameFolder -AppId '1049890' -SteamFolderNames @('Little Witch Nobeta') -ProbeExe $GAME_EXE -HubGameId $GAME_ID;if($found){$candidates.Add($found)}}catch{}
    $candidates.Add('C:\Program Files (x86)\Steam\steamapps\common\Little Witch Nobeta')
    foreach($path in @($candidates|Select-Object -Unique)){if(Test-NobetaGame $path){return (Get-Item -LiteralPath $path).FullName}}
    Write-Host '  Select the Steam Little Witch Nobeta folder containing LittleWitchNobeta.exe.' -ForegroundColor Yellow
    while($true){
        $raw=if($ReadInput){& $ReadInput}else{Read-Host 'Game folder (drag/paste path, Q to cancel)'}
        if($null -eq $raw){throw 'The game-folder input stream ended.'}
        $path=(''+$raw).Trim().Trim('"').Trim("'")
        if($path -ieq 'Q'){return $null}
        if(Test-NobetaGame $path){return (Get-Item -LiteralPath $path).FullName}
        Write-Host '  The selected folder has no complete Little Witch Nobeta base game.' -ForegroundColor Yellow
    }
}
function Get-NobetaRelease {
    $release=Resolve-GitHubReleaseAsset -Repo $REPO -AssetPatterns @('(?i)^NobetaVR-[0-9].*\.zip$') `
        -IncludePrerelease $true -SkipReleasesWithoutMatchingAsset -FallbackUrl $FALLBACK_URL `
        -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_ASSET
    if(-not(Test-IsTrackableInstalledVersion ([string]$release.Tag))){throw 'GitHub did not return a trackable NobetaVR release.'}
    return $release
}
function Assert-NobetaChildPath([string]$Path,[string]$Root){
    $full=[IO.Path]::GetFullPath($Path).TrimEnd('\','/')
    $parent=[IO.Path]::GetFullPath($Root).TrimEnd('\','/')
    if(-not $full.StartsWith(($parent+[IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)){
        throw "Path escapes its expected root: $Path"
    }
}
function New-NobetaStage([string]$Archive,[string]$Work){
    $outer=Join-Path $Work 'publisher'
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $outer -Label 'NobetaVR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The NobetaVR ZIP could not be opened.'}
    $payload=Get-ExtractedPayloadRoot -ExtractDir $outer -RelModFile 'BepInEx\plugins\NobetaVR.dll'
    if(-not $payload){throw 'The publisher ZIP has no NobetaVR plugin payload.'}
    foreach($relative in $PROOF){if(-not(Test-Path -LiteralPath (Join-Path $payload $relative) -PathType Leaf)){throw "Publisher ZIP is missing $relative"}}
    $stage=Join-Path $Work 'stage';[void][IO.Directory]::CreateDirectory($stage)
    foreach($file in @(Get-ChildItem -LiteralPath $payload -Recurse -File -Force -ErrorAction Stop)){
        $relative=$file.FullName.Substring($payload.Length+1)
        if($relative -ieq 'NobetaVR-Uninstall.bat'){continue}
        $target=Join-Path $stage $relative
        Assert-NobetaChildPath -Path $target -Root $stage
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force -ErrorAction Stop
    }
    return $stage
}
function Save-NobetaSnapshot([string]$Game,[string]$Stage,[string]$SnapshotRoot){
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $paths=[Collections.Generic.List[string]]::new()
    foreach($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)){[void]$paths.Add($file.FullName.Substring($Stage.Length+1))}
    $manifest=Join-Path $Game '.pcvrhub_nobetavr_ownership.csv'
    if(Test-Path -LiteralPath $manifest){foreach($row in @(Import-Csv -LiteralPath $manifest)){if($row.RelativePath){[void]$paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)))}}}
    foreach($name in @('.pcvrhub_nobetavr_ownership.csv','.pcvrhub_version')){[void]$paths.Add($name)}
    $records=@()
    foreach($relative in @($paths|Select-Object -Unique)){
        $source=Join-OwnedRelativePath -Root $Game -Relative $relative
        $exists=Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{Relative=$relative;Exists=$exists}
        if($exists){$copy=Join-OwnedRelativePath -Root (Join-Path $SnapshotRoot 'files') -Relative $relative;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy));Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_nobetavr_backup'
    $hadBackup=Test-Path -LiteralPath $backup -PathType Container
    if($hadBackup){Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'ownership-backup') -Recurse -Force -ErrorAction Stop}
    return [pscustomobject]@{Records=$records;HadBackup=$hadBackup;Root=$SnapshotRoot}
}
function Restore-NobetaSnapshot([string]$Game,$Snapshot){
    foreach($record in @($Snapshot.Records)){
        $target=Join-OwnedRelativePath -Root $Game -Relative ([string]$record.Relative)
        if(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force -ErrorAction Stop}
        if($record.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-OwnedRelativePath -Root (Join-Path $Snapshot.Root 'files') -Relative ([string]$record.Relative)) -Destination $target -Force -ErrorAction Stop}
    }
    $backup=Join-Path $Game '.pcvrhub_nobetavr_backup';Assert-NobetaChildPath -Path $backup -Root $Game
    if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop}
    if($Snapshot.HadBackup){Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'ownership-backup') -Destination $backup -Recurse -Force -ErrorAction Stop}
}
function Write-NobetaProofCheckpoint([string]$Label,[string]$Root){
    foreach($relative in $PROOF){Write-Host ("  [{0}] {1}: {2}" -f $Label,$relative,[bool](Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) -ForegroundColor DarkGray}
}
function global:Invoke-LittleWitchNobetaVRInstaller {
    $work=$null;$game=$null;$snapshot=$null;$changed=$false;$keepWork=$false
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta
        Write-Host '  Little Witch Nobeta VR Installer' -ForegroundColor Cyan
        Write-Host '  WIP release by Pk-c' -ForegroundColor Gray
        Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  Requires the Steam Little Witch Nobeta game.' -ForegroundColor White
        Write-Host '  The publisher ZIP includes BepInEx and OpenXR. Setup keeps game saves,' -ForegroundColor White
        Write-Host '  unrelated plugins and pre-existing files through an ownership backup.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter after reading this to start setup...')
        Write-Host '  [1/4] Find the game and check the destination' -ForegroundColor Cyan
        $game=Get-NobetaGameRoot;if(-not $game){return}
        if(Get-Process -Name 'LittleWitchNobeta' -ErrorAction SilentlyContinue){throw 'Close Little Witch Nobeta before installing.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable.'}
        Write-Host '  [2/4] Get the official NobetaVR release' -ForegroundColor Cyan
        Write-Host '  Setup checks the latest matching GitHub release, including prereleases.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download NobetaVR...')
        $release=Get-NobetaRelease
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_nobeta_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'NobetaVR.zip'
        $download=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "NobetaVR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if($download -ne $true -and [string]$download -notin @('retry','manual')){throw 'NobetaVR download was not completed.'}
        $stage=New-NobetaStage -Archive $archive -Work $work
        Write-Host '  [3/4] Install verified VR files with rollback' -ForegroundColor Cyan
        Write-NobetaProofCheckpoint -Label before-copy -Root $game
        $snapshot=Save-NobetaSnapshot -Game $game -Stage $stage -SnapshotRoot (Join-Path $work 'rollback')
        $changed=$true
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY -ProgressLabel 'Installing NobetaVR files')
        Write-NobetaProofCheckpoint -Label after-copy -Root $game
        foreach($relative in $PROOF){if(-not(Test-Path -LiteralPath (Join-Path $game $relative) -PathType Leaf)){throw "Installed NobetaVR file is missing: $relative"}}
        if(-not(Confirm-PlacedFilesSurvive -Paths @($PROOF|ForEach-Object{Join-Path $game $_}) -GameDir $game -NoClear)){throw 'Required NobetaVR files did not survive the post-copy check.'}
        Write-NobetaProofCheckpoint -Label after-observation -Root $game
        [void](Complete-PCVRInstallTransaction -Contract $CONTRACT -GameDir $game -Version ([string]$release.Tag) `
            -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current)
        $changed=$false
        Write-Host '  [4/4] Finish' -ForegroundColor Cyan
        Write-Host "  [OK] NobetaVR $($release.Tag) files were installed and recorded." -ForegroundColor Green
        Write-Host '  Start in VR opens the Steam game. Actual loader, controls and headset need a real test.' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  A little magic goes a long way in VR.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changed -and $game -and $snapshot){
            Write-NobetaProofCheckpoint -Label before-rollback -Root $game
            try{Restore-NobetaSnapshot -Game $game -Snapshot $snapshot;Write-NobetaProofCheckpoint -Label after-rollback -Root $game;Write-Host '  Previous files restored.' -ForegroundColor Yellow}
            catch{$keepWork=$true;Write-Host ('  Rollback needs attention; backup retained at '+$work+': '+$_.Exception.Message) -ForegroundColor Red}
        }
        throw
    }finally{
        if($work -and -not $keepWork -and (Test-Path -LiteralPath $work -PathType Container)){
            $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
            $full=[IO.Path]::GetFullPath($work)
            if($full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $full -Leaf) -like 'pcvr_nobeta_*'){
                Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

if($env:PCVR_NOBETA_LIBRARY_ONLY -ne '1'){Invoke-LittleWitchNobetaVRInstaller}
