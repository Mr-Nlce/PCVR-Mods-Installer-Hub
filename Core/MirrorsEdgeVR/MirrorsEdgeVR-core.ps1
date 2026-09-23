$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle="Mirror's Edge VR Installer"
$APP_ID='17410'
$GAME_EXE='Binaries\MirrorsEdge.exe'
$REPO='letsgosportsteam/mirrors-edge-vr-mod'
$RELEASES_URL="https://github.com/$REPO/releases"
$FALLBACK_TAG='v0.2.2-alpha'
$FALLBACK_ASSET='mevr-0.2.2-alpha.zip'
$FALLBACK_URL='https://github.com/letsgosportsteam/mirrors-edge-vr-mod/releases/download/v0.2.2-alpha/mevr-0.2.2-alpha.zip'
$IDENTITY='mirrorsedgevr'
$REQUIRED=@('Binaries\d3d9.dll','Binaries\openxr_loader.dll','Binaries\mevr.ini')
$contract=New-PCVRInstallerContract -Id 'mirrors-edge-vr' -GameName "Mirror's Edge VR" -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $RELEASES_URL `
    -RequiredInstalledFileGroups @($REQUIRED+@(".pcvrhub_${IDENTITY}_ownership.csv"))

function Write-MEVRStep([int]$Number,[int]$Total,[string]$Text){Write-Host '';Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan;Write-Host ''}
function Write-MEVROK([string]$Text){Write-Host "  [OK] $Text" -ForegroundColor Green}
function Write-MEVRWarn([string]$Text){Write-Host "  [!!] $Text" -ForegroundColor Yellow}

function Test-MEVRGameRoot([string]$Path){
    return [bool]($Path -and
        (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf -ErrorAction SilentlyContinue) -and
        (Test-Path -LiteralPath (Join-Path $Path 'Engine\Config\BaseEngine.ini') -PathType Leaf -ErrorAction SilentlyContinue))
}
function Test-MEVRPayload([string]$Root){
    return [bool]($Root -and
        (Test-Path -LiteralPath (Join-Path $Root 'd3d9.dll') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'openxr_loader.dll') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'mevr.ini') -PathType Leaf))
}
function Get-MEVRGameRoot {
    $game=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("Mirror's Edge",'mirrors edge') -ProbeExe $GAME_EXE -HubGameId 'mirrors-edge-vr'
    if(Test-MEVRGameRoot $game){return (Get-Item -LiteralPath $game).FullName}
    foreach($fallback in @(
        "C:\Program Files (x86)\Steam\steamapps\common\mirrors edge",
        "C:\Program Files\Steam\steamapps\common\mirrors edge",
        "C:\Program Files\EA Games\Mirror's Edge",
        "C:\Program Files (x86)\Origin Games\Mirror's Edge",
        "C:\Program Files (x86)\EA Games\Mirror's Edge"
    )){if(Test-MEVRGameRoot $fallback){return (Get-Item -LiteralPath $fallback).FullName}}
    $picked=Get-GameFolderInteractive -GameName "Mirror's Edge" -ProbeFile $GAME_EXE -ManualUrl 'https://github.com/letsgosportsteam/mirrors-edge-vr-mod#installation'
    if($picked -in @('quit','skip',$null) -or -not(Test-MEVRGameRoot $picked)){return $null}
    return (Get-Item -LiteralPath $picked).FullName
}
function Get-MEVRRelease {
    $release=Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true `
        -AssetPatterns @('(?i)^mevr-.*\.zip$') -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG `
        -FallbackAssetName $FALLBACK_ASSET -SkipReleasesWithoutMatchingAsset
    [pscustomobject]@{Tag=[string]$release.Tag;Url=[string]$release.Url;Name=[string]$release.AssetName;PageUrl=[string]$release.PageUrl}
}
function New-MEVRStage([string]$ExtractRoot,[string]$Stage){
    if(-not(Test-MEVRPayload $ExtractRoot)){throw 'The release archive does not contain the three functional Mirror''s Edge VR files.'}
    $bin=Join-Path $Stage 'Binaries';[void][IO.Directory]::CreateDirectory($bin)
    foreach($name in @('d3d9.dll','openxr_loader.dll','mevr.ini')){Copy-Item -LiteralPath (Join-Path $ExtractRoot $name) -Destination (Join-Path $bin $name) -Force -ErrorAction Stop}
    return $Stage
}
function Save-MEVRSnapshot([string]$GameRoot,[string]$SnapshotRoot){
    [void][IO.Directory]::CreateDirectory($SnapshotRoot);$files=Join-Path $SnapshotRoot 'files'
    $rel=@($REQUIRED+@(".pcvrhub_${IDENTITY}_ownership.csv",'.pcvrhub_version'))
    $manifest=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    if(Test-Path -LiteralPath $manifest -PathType Leaf){try{$rel+=@(Import-Csv $manifest|ForEach-Object RelativePath)}catch{}}
    $records=@();foreach($r in @($rel|Where-Object{$_}|Select-Object -Unique)){$src=Join-Path $GameRoot $r;$exists=Test-Path -LiteralPath $src -PathType Leaf;$records+=[pscustomobject]@{Relative=$r;Exists=$exists};if($exists){$dst=Join-Path $files $r;[void][IO.Directory]::CreateDirectory((Split-Path -Parent $dst));Copy-Item -LiteralPath $src -Destination $dst -Force}}
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup";$backupExists=Test-Path -LiteralPath $backup -PathType Container
    if($backupExists){Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'ownership-backup') -Recurse -Force}
    [pscustomobject]@{Records=$records;BackupExists=$backupExists;SnapshotRoot=$SnapshotRoot}
}
function Restore-MEVRSnapshot([string]$GameRoot,$Snapshot){
    foreach($record in @($Snapshot.Records)){$target=Join-Path $GameRoot $record.Relative;if(Test-Path -LiteralPath $target -PathType Leaf){Remove-Item -LiteralPath $target -Force};if($record.Exists){[void][IO.Directory]::CreateDirectory((Split-Path -Parent $target));Copy-Item -LiteralPath (Join-Path (Join-Path $Snapshot.SnapshotRoot 'files') $record.Relative) -Destination $target -Force}}
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup";if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Recurse -Force};if($Snapshot.BackupExists){Copy-Item -LiteralPath (Join-Path $Snapshot.SnapshotRoot 'ownership-backup') -Destination $backup -Recurse -Force}
}
function Install-MEVROwnedPayload([string]$GameRoot,[string]$Stage,[string]$Version,[string]$Receipt){
    if(-not(Test-MEVRGameRoot $GameRoot)){throw 'The selected folder is not a complete Mirror''s Edge installation.'}
    foreach($relative in $REQUIRED){if(-not(Test-Path -LiteralPath (Join-Path $Stage $relative) -PathType Leaf)){throw "The normalized install stage is missing $relative."}}
    [void](Install-OwnedModPayload -SourceRoot $Stage -GameRoot $GameRoot -Identity $IDENTITY -KeepExistingRelativePaths @('Binaries\mevr.ini') -AdoptIdenticalExisting)
    $watch=@($REQUIRED|ForEach-Object{Join-Path $GameRoot $_})+@(Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv")
    if(-not(Confirm-PlacedFilesSurvive -Paths $watch -GameDir $GameRoot -NoClear)){throw 'Required Mirror''s Edge VR files are missing after installation.'}
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $GameRoot -Version $Version -InstalledPathReceiptPaths @($Receipt) -Route 'Current')
}
function global:Invoke-MirrorsEdgeVRInstaller {
    $work=$null;$game=$null;$snapshot=$null;$changesStarted=$false
    try{
        Clear-Host;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host "  Mirror's Edge VR - Installer" -ForegroundColor Cyan;Write-Host '  Native stereo, 6DoF and motion parkour' -ForegroundColor Gray;Write-Host ('='*60) -ForegroundColor Magenta;Write-Host ''
        Write-Host '  This alpha currently supports Virtual Desktop with VDXR only.' -ForegroundColor Yellow
        Write-Host '  SteamVR and Meta Link / Air Link are not supported.' -ForegroundColor Yellow
        Write-Host '  Microsoft Visual C++ 2015-2022 Redistributable x86 is required.' -ForegroundColor White
        Write-Host '  Antivirus software may inspect the runtime. Setup checks required' -ForegroundColor Yellow
        Write-Host '  files without assuming why a missing file disappeared.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading these requirements, press Enter to proceed...')

        Write-MEVRStep 1 5 "Locating Mirror's Edge"
        $game=Get-MEVRGameRoot;if(-not $game){throw 'Setup cancelled before any game file was changed.'}
        if(Get-Process -Name 'MirrorsEdge' -ErrorAction SilentlyContinue){throw 'Mirror''s Edge is running. Close it completely and retry.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable. Run setup as administrator and retry.'}
        Write-MEVROK "Found: $game"

        Write-MEVRStep 2 5 'Getting the newest alpha release'
        $release=Get-MEVRRelease;if(-not(Test-IsTrackableInstalledVersion $release.Tag)){throw 'GitHub did not provide a trackable prerelease version.'}
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_mevr_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'mevr.zip';$downloaded=Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Mirror's Edge VR $($release.Tag)" -ManualUrl $release.PageUrl -AllowSkip $false
        if(-not($downloaded -eq $true -or [string]$downloaded -in @('retry','manual'))){throw 'The official VR release was not downloaded.'}
        $extract=Join-Path $work 'extract';if([string](Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label "Mirror's Edge VR release" -AllowSkip $false -QuietProgress) -notin @('ok','manual','retry')){throw 'The official VR release could not be extracted.'}
        $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'd3d9.dll';$stage=New-MEVRStage -ExtractRoot $payload -Stage (Join-Path $work 'stage')
        Write-MEVROK "Functional publisher package $($release.Tag) verified."

        Write-MEVRStep 3 5 'Preparing a recoverable game-folder transaction'
        $snapshot=Save-MEVRSnapshot -GameRoot $game -SnapshotRoot (Join-Path $work 'rollback');$changesStarted=$true
        Write-MEVROK 'Existing Hub-owned files and collisions are recoverable.'

        Write-MEVRStep 4 5 'Installing and checking the VR runtime'
        Write-Host '  This can take a moment. The setup is actively copying and checking' -ForegroundColor Gray
        Write-Host '  the runtime beside Binaries\MirrorsEdge.exe.' -ForegroundColor Gray
        Install-MEVROwnedPayload -GameRoot $game -Stage $stage -Version $release.Tag -Receipt (Join-Path $PSScriptRoot '.installed_path');$changesStarted=$false

        Write-MEVRStep 5 5 'Finishing setup';Write-MEVROK "Mirror's Edge VR $($release.Tag) is installed and tracked."
        Write-Host '';Write-Host '  1. Connect through Virtual Desktop with VDXR, then use Start in VR.' -ForegroundColor White
        Write-Host '  2. Stereo begins after a level loads; the startup remains flat.' -ForegroundColor White
        Write-Host ''
        Write-Host '  [!!] FIRST CONNECTED LAUNCH REQUIRES ONE RESTART' -ForegroundColor Yellow
        Write-Host '  3. Quit the game completely, then use Start in VR again.' -ForegroundColor Yellow
        Write-Host '     The VR mod needs this restart to apply the correct headset resolution.' -ForegroundColor Yellow
        Write-Host '     Without it, the game can remain in a small flat window in the headset.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  If chapter loading freezes, disable PhysX in the game settings.' -ForegroundColor Yellow
        Write-Host '  Hold Y for one second to open the in-headset VR settings.' -ForegroundColor Cyan
        Write-Host '';Write-Host '  The city has no handrails for confidence, only for parkour.' -ForegroundColor Magenta;Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    }catch{
        if($changesStarted -and $game -and $snapshot){try{Restore-MEVRSnapshot -GameRoot $game -Snapshot $snapshot;Write-MEVRWarn "The previous Mirror's Edge folder state was restored."}catch{Write-MEVRWarn ('Rollback also needs attention: '+$_.Exception.Message)}}
        throw
    }finally{if($work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}}
}
if(((''+$env:PCVR_MEVR_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-MirrorsEdgeVRInstaller}
