param([string]$GameDir,[ValidateSet('Current','Depot')][string]$BuildMode='Current')

$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherZipTransaction.ps1')
. (Join-Path $PSScriptRoot 'EldenRingDepot.ps1')

$repo='IlyaMez/EldenringVR'
$page="https://github.com/$repo/releases"
$pinned='v0.8.0'
$pattern='(?i)^ERVR-v\d+\.\d+\.\d+\.zip$'
$env:PCVR_HUB_RECOVERY_PAGE=if($BuildMode -eq 'Depot'){"$page/tag/$pinned"}else{$page}
$required=@('dxgi.dll','dinput8.dll','ReShade.ini','LICENSE-ReShade.txt','ERVR Launcher.exe',
    'ERVR\ERVR.dll','ERVR\ERVR.ini','ERVR\bhaptics_library.dll')
$keepFiles=@('ReShade.ini','ERVR\ERVR.ini')

function Test-ErvrInstalledFiles([string]$Root,[string]$Phase) {
    foreach($name in $required){
        $path=Join-Path $Root $name
        $present=[IO.File]::Exists($path)
        Write-PCVRFileCheckResult -Path $path -Present $present -Phase $Phase -DisplayName $name
        if(-not $present){$name}
    }
}

# Keep the pre-ERVR loader backups when migrating an existing Hub install.
function Merge-ErvrLegacyOwnership([string]$Root) {
    $legacy=Join-Path $Root '.pcvrhub-ervr-backup'
    $oldManifest=Join-Path $legacy 'manifest.txt'
    if(-not [IO.File]::Exists($oldManifest)){return}
    $manifest=Join-Path $Root '.pcvrhub_ervr_ownership.csv'
    $backup=Join-Path $Root '.pcvrhub_ervr_backup'
    $modes=@{}
    foreach($line in [IO.File]::ReadAllLines($oldManifest)){
        if($line -match '^(dxgi\.dll|dinput8\.dll|ReShade\.ini)=(restore|remove|keep)$'){$modes[$Matches[1]]=$Matches[2]}
    }
    $rows=@(Import-Csv -LiteralPath $manifest)
    foreach($row in $rows){
        $relative=[string]$row.RelativePath
        if($relative -eq 'ERVR\ERVR.dll' -or $modes[$relative] -eq 'remove'){$row.HadOriginal='False'}
        if($modes[$relative] -eq 'restore'){
            $saved=Join-Path $legacy $relative
            if(-not [IO.File]::Exists($saved)){throw "Prior ERVR recovery file is missing: $relative"}
            [void][IO.Directory]::CreateDirectory($backup)
            Copy-Item -LiteralPath $saved -Destination (Join-Path $backup $relative) -Force
            $row.HadOriginal='True'
        }
    }
    $rows | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding UTF8
}

$work=$null
$snapshot=$null
$keepWork=$false
$gameSub=$null
try{
    Write-Host ''
    Write-Host "  ELDEN RING VR | ERVR | $BuildMode" -ForegroundColor Cyan
    Write-Host '  Only play offline or through Seamless Co-op, with Easy Anti-Cheat off.' -ForegroundColor Yellow
    Write-Host '  This setup preserves your existing ERVR and ReShade settings.' -ForegroundColor White
    Show-AntivirusNotice -Compact
    if(-not (Test-EldenRingRoot $GameDir)){throw 'Choose an Elden Ring folder that contains Game\eldenring.exe.'}
    $gameSub=Join-Path $GameDir 'Game'
    if(Get-Process -Name 'eldenring','start_protected_game','ERSC_Seamless' -ErrorAction SilentlyContinue){
        throw 'Close Elden Ring before installing or updating ERVR.'
    }
    if(-not (Test-InstallerTargetWritable -TargetPath $gameSub)){throw "The selected game folder is not writable: $gameSub"}
    foreach($marker in @('RealRepo\RealVR64.dll','RealRepo_\RealVR64.dll','RealVR.ini')){
        if([IO.File]::Exists((Join-Path $gameSub $marker))){throw 'R.E.A.L. is present in this game copy. Remove it first, or choose a separate copy for ERVR.'}
    }
    $installed=[IO.File]::Exists((Join-Path $gameSub 'ERVR\ERVR.dll'))
    if(-not $installed -and [IO.File]::Exists((Join-Path $gameSub 'dinput8.dll'))){
        throw 'Another dinput8.dll loader is present. Use the publisher instructions or choose a clean game copy.'
    }
    if(-not $installed -and [IO.File]::Exists((Join-Path $gameSub 'dxgi.dll'))){
        throw 'Another dxgi.dll graphics loader is present. Remove that loader or choose a clean game copy.'
    }

    $work=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
    $archive=Join-Path $work 'ERVR.zip'
    $manual=Get-PCVRRecoveryInput -PathType Leaf
    if($manual){
        Copy-Item -LiteralPath $manual -Destination $archive -Force
    }else{
        [void](Wait-PCVRExplicitEnter -Message "Press Enter to download ERVR for the selected $BuildMode copy...")
        Write-Host '  Checking GitHub and downloading the Windows ZIP...' -ForegroundColor Cyan
        if($BuildMode -eq 'Depot'){
            $url="$page/download/$pinned/ERVR-$pinned.zip"
        }else{
            $release=Resolve-GitHubReleaseAsset -Repo $repo -IncludePrerelease $false -AssetPatterns @($pattern) -SkipReleasesWithoutMatchingAsset
            if(-not $release.Resolved){throw 'GitHub did not return an ERVR Windows ZIP. Retry or supply the publisher ZIP in Recovery.'}
            $url=[string]$release.Url
        }
        $download=@{Urls=@($url);Destination=$archive;Label='ERVR';PlainProgress=$true;FunctionalPayloadOnly=$true
            DisableGitHubAssetReresolution=$true;ManualUrl=$env:PCVR_HUB_RECOVERY_PAGE;AllowSkip=$false}
        [void](Invoke-SafeDownload @download)
    }
    Write-Host '  Checking the ZIP contents and preparing required files...' -ForegroundColor Cyan
    $stage=Join-Path $work 'stage'
    $safe=Test-ZipArchiveEntrySafety -ArchivePath $archive -DestinationFolder $stage
    if(-not $safe.Inspectable -or -not $safe.Safe){throw 'ERVR needs a readable publisher ZIP with safe file paths.'}
    if((Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $stage -Label 'ERVR' -AllowSkip $false) -ne 'ok'){
        throw 'The ERVR ZIP could not be opened.'
    }
    $source=Get-ChildItem -LiteralPath $stage -Recurse -File -Filter 'ERVR.dll' |
        Where-Object {$_.Directory.Name -ieq 'ERVR'} | Select-Object -First 1
    if(-not $source){throw 'The ZIP has no ERVR runtime.'}
    $payload=$source.Directory.Parent.FullName
    foreach($file in $required){
        if(-not [IO.File]::Exists((Join-Path $payload $file))){throw "The publisher ZIP is missing $file. No game files were changed."}
    }
    $fileVersion=[Diagnostics.FileVersionInfo]::GetVersionInfo($source.FullName).ProductVersion
    if($fileVersion -notmatch '^\d+\.\d+\.\d+$'){throw 'ERVR.dll does not report an installed version.'}
    $version="v$fileVersion"
    if($BuildMode -eq 'Depot' -and $version -ne $pinned){
        throw "The selected 1.16.2 Depot route uses ERVR $pinned. Use its release page, or choose Current for other versions."
    }
    $installStage=Join-Path $work 'install'
    [void][IO.Directory]::CreateDirectory($installStage)
    foreach($relative in @('dxgi.dll','dinput8.dll','ReShade.ini','LICENSE-ReShade.txt','ERVR Launcher.exe','ERVR')){
        Copy-Item -LiteralPath (Join-Path $payload $relative) -Destination $installStage -Recurse -Force
    }
    $snapshot=Save-PCVRPublisherZipSnapshot -GameRoot $gameSub -Stage $installStage -Identity 'ervr' -SnapshotRoot (Join-Path $work 'rollback')
    Write-Host "  Installing ERVR $version and checking the result..." -ForegroundColor Cyan
    $firstManifest=-not [IO.File]::Exists((Join-Path $gameSub '.pcvrhub_ervr_ownership.csv'))
    $install=@{SourceRoot=$installStage;GameRoot=$gameSub;Identity='ervr';KeepExistingRelativePaths=$keepFiles
        AdoptIdenticalExisting=$true;ReconcileIdenticalOwnedFiles=$true}
    [void](Install-OwnedModPayload @install)
    if($firstManifest){Merge-ErvrLegacyOwnership $gameSub}
    if(@(Test-ErvrInstalledFiles $gameSub 'after-copy').Count){throw 'Required ERVR files are missing after copying.'}
    $retry={
        [void]@(Test-ErvrInstalledFiles $gameSub 'before-retry')
        $missing=@($required|ForEach-Object{Join-Path $gameSub $_}|Where-Object{-not [IO.File]::Exists($_)})
        if($missing.Count -and -not (Restore-FromArchiveInGameFolder -ArchivePath $archive -GameDir $gameSub -Paths $missing)){
            throw 'Required ERVR files could not be restored from the publisher ZIP.'
        }
        [void]@(Test-ErvrInstalledFiles $gameSub 'after-retry')
    }
    if(-not (Confirm-PlacedFilesSurvive -Paths @($required|ForEach-Object{Join-Path $gameSub $_}) -GameDir $gameSub -Recopy $retry -NoClear)){
        [void]@(Test-ErvrInstalledFiles $gameSub 'after-observation')
        throw 'Required ERVR files did not survive the copy check.'
    }
    [void]@(Test-ErvrInstalledFiles $gameSub 'after-observation')
    $groups=@('Game\eldenring.exe')+@($required|ForEach-Object{"Game\$_"})
    $contract=New-PCVRInstallerContract -Id 'elden-ring-motion-controls' -GameName 'Elden Ring VR' -Acquisition GitHub -AntivirusNotice -Routes @('Current','Depot') -ReleasePageUrl $page -RequiredInstalledFileGroups $groups
    $commit=@{Contract=$contract;GameDir=$GameDir;VersionSlot='Secondary';Version=$version;Route=$BuildMode;InstalledPathReceiptPaths=@((Join-Path $PSScriptRoot '.installed_path'))}
    [void](Complete-PCVRInstallTransaction @commit)
    $snapshot=$null
    try{
        $launcher=Write-EldenRingMotionLauncher -GameDir $GameDir
        if($env:PCVR_HUB_TEST_MODE -ne '1' -and $env:OS -eq 'Windows_NT'){
            $label=if($BuildMode -eq 'Depot'){'Depot 1.16.2'}else{'Current'}
            [void](New-DesktopShortcut -TargetPath $launcher -ShortcutName "Elden Ring VR Motion ($label)" -WorkingDir (Split-Path -Parent $launcher))
        }
    }catch{Write-Warning 'The separate launcher could not be refreshed. Use the matching ERVR button in the Hub.'}
    Write-Host "  [OK] ERVR $version is installed for $BuildMode." -ForegroundColor Green
    Write-Host '  Start the desired OpenXR runtime, then use the matching ERVR button.' -ForegroundColor White
    Write-Host '  Rise, Tarnished, and raise the shield yourself.' -ForegroundColor Magenta
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    exit 0
}catch{
    $message=$_.Exception.Message
    if($snapshot){
        [void]@(Test-ErvrInstalledFiles $gameSub 'before-rollback')
        try{
            Restore-PCVRPublisherZipSnapshot -GameRoot $gameSub -Snapshot $snapshot
            [void]@(Test-ErvrInstalledFiles $gameSub 'after-rollback')
        }catch{
            $keepWork=$true
            $message+=" Rollback was incomplete. Recovery files are in $work."
        }
    }
    Write-Host "  ERVR setup did not complete: $message" -ForegroundColor Red
    exit 1
}finally{
    if($work -and -not $keepWork){
        try{Remove-PCVRInstallerTempSession -Path $work}catch{Write-Warning "Could not clear the temporary ERVR files: $work"}
    }
}
