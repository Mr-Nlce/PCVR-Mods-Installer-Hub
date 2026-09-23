# Painkiller: Overdose VR - governed stable GitHub installer.
# The publisher ships a standalone VR launcher which lives beside Bin and Data.
# The original Bin\Overdose.exe remains the unchanged Flat launch route.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Painkiller: Overdose VR Installer'
$APP_ID = '3270'
$GAME_EXE = 'Bin\Overdose.exe'
$REPO = 'STRParagor/painkiller-overdose-vr'
$RELEASES_URL = "https://github.com/$REPO/releases"
$FALLBACK_TAG = 'v.1.1'
$FALLBACK_ASSET = 'Painkiiiler.-.Overdose.VR.v.1.1.zip'
$FALLBACK_URL = 'https://github.com/STRParagor/painkiller-overdose-vr/releases/download/v.1.1/Painkiiiler.-.Overdose.VR.v.1.1.zip'
$IDENTITY = 'painkilleroverdosevr'
$HUB_LAUNCHER = 'Start Painkiller Overdose VR.bat'
$QUIP = 'Purgatory was only the warm-up. Overdose is administered in stereo.'

$contract = New-PCVRInstallerContract -Id 'painkiller-overdose-vr' -GameName 'Painkiller: Overdose VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $RELEASES_URL `
    -RequiredInstalledFileGroups @($HUB_LAUNCHER,".pcvrhub_${IDENTITY}_ownership.csv")

function Write-PKODStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host ''
}
function Write-PKODOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-PKODWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }
function Write-PKODInfo([string]$Text) { Write-Host "  $Text" -ForegroundColor Gray }

function Test-PKODGameRoot([string]$Path) {
    return [bool]($Path -and
        (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf -ErrorAction SilentlyContinue) -and
        (Test-Path -LiteralPath (Join-Path $Path 'Bin') -PathType Container -ErrorAction SilentlyContinue) -and
        (Test-Path -LiteralPath (Join-Path $Path 'Data') -PathType Container -ErrorAction SilentlyContinue))
}

function Get-PKODPublisherExecutable([string]$Root) {
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $null }
    $matches=@(Get-ChildItem -LiteralPath $Root -File -Filter '*.exe' -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match '(?i)^Painkiller\s*-\s*Overdose\s+VR\s+v?\.?[0-9].*\.exe$'
    })
    if ($matches.Count -ne 1) { return $null }
    return $matches[0]
}

function Test-PKODPayload([string]$Root,[string]$Version='') {
    $launcher=Get-PKODPublisherExecutable $Root
    if (-not $launcher -or $launcher.Length -lt 1MB) { return $false }
    if (-not (Test-Path -LiteralPath (Join-Path $Root 'ReadMe! EN.txt') -PathType Leaf)) { return $false }
    if ($Version) {
        $digits=([regex]::Match($Version,'[0-9]+(?:\.[0-9]+)+')).Value
        if (-not $digits -or $launcher.Name -notmatch [regex]::Escape($digits)) { return $false }
    }
    return $true
}

function Get-PKODRelease {
    $release=Resolve-GitHubReleaseAsset -Repo $REPO `
        -AssetPatterns @('(?i)^Paink+i+l+er.*Overdose.*VR.*\.zip$') `
        -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_ASSET `
        -SkipReleasesWithoutMatchingAsset
    return [pscustomobject]@{
        Tag=[string]$release.Tag; Url=[string]$release.Url; Name=[string]$release.AssetName; PageUrl=[string]$release.PageUrl
    }
}

function Get-PKODGameRoot {
    $game=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Painkiller Overdose') `
        -ProbeExe $GAME_EXE -GogNames @('Painkiller Overdose') -HubGameId 'painkiller-overdose-vr'
    if (Test-PKODGameRoot $game) { return (Get-Item -LiteralPath $game).FullName }
    foreach ($fallback in @(
        'C:\Program Files (x86)\Steam\steamapps\common\Painkiller Overdose',
        'C:\Program Files (x86)\GOG Galaxy\Games\Painkiller Overdose',
        'C:\GOG Games\Painkiller Overdose',
        'C:\Program Files (x86)\DreamCatcher\Painkiller Overdose'
    )) {
        if (Test-PKODGameRoot $fallback) { return (Get-Item -LiteralPath $fallback).FullName }
    }
    $picked=Get-GameFolderInteractive -GameName 'Painkiller Overdose' -ProbeFile $GAME_EXE `
        -ManualUrl 'https://github.com/STRParagor/painkiller-overdose-vr#installation'
    if ($picked -in @('quit','skip',$null) -or -not (Test-PKODGameRoot $picked)) { return $null }
    return (Get-Item -LiteralPath $picked).FullName
}

function New-PKODInstallStage([string]$ExtractRoot,[string]$Stage,[string]$Version) {
    if (-not (Test-PKODPayload -Root $ExtractRoot -Version $Version)) {
        throw 'The release is missing its functional VR launcher or English readme.'
    }
    [void][IO.Directory]::CreateDirectory($Stage)
    foreach ($file in @(Get-ChildItem -LiteralPath $ExtractRoot -File -ErrorAction Stop)) {
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $Stage $file.Name) -Force -ErrorAction Stop
    }
    $publisher=Get-PKODPublisherExecutable $Stage
    $batch=@(
        '@echo off',
        'setlocal',
        'cd /d "%~dp0"',
        ('start "" "%~dp0{0}"' -f $publisher.Name.Replace('%','%%')),
        'exit /b 0'
    ) -join "`r`n"
    [IO.File]::WriteAllText((Join-Path $Stage $HUB_LAUNCHER),$batch,(New-Object Text.UTF8Encoding $false))
    if (-not (Test-PKODPayload -Root $Stage -Version $Version) -or
        -not (Test-Path -LiteralPath (Join-Path $Stage $HUB_LAUNCHER) -PathType Leaf)) {
        throw 'The normalized Painkiller: Overdose VR install stage is incomplete.'
    }
    return $Stage
}

function Save-PKODSnapshot([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $filesRoot=Join-Path $SnapshotRoot 'files'
    $relatives=[Collections.Generic.List[string]]::new()
    $stageBase=[IO.Path]::GetFullPath($Stage).TrimEnd('\','/')
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -File -ErrorAction Stop)) {
        $relatives.Add($file.FullName.Substring($stageBase.Length+1))
    }
    $manifest=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        try { foreach ($row in @(Import-Csv -LiteralPath $manifest)) { if ($row.RelativePath) { $relatives.Add([string]$row.RelativePath) } } } catch {}
    }
    foreach ($extra in @(".pcvrhub_${IDENTITY}_ownership.csv",".pcvrhub_${IDENTITY}_ownership.csv.new",'.pcvrhub_version')) { $relatives.Add($extra) }
    $records=@()
    foreach ($relative in @($relatives | Select-Object -Unique)) {
        $source=Join-Path $GameRoot $relative
        $exists=Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{ Relative=$relative; Exists=$exists }
        if ($exists) {
            $copy=Join-Path $filesRoot $relative
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy))
            Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop
        }
    }
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup"
    $backupExists=Test-Path -LiteralPath $backup -PathType Container
    if ($backupExists) { Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'ownership-backup') -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{ Records=$records; BackupExists=$backupExists; SnapshotRoot=$SnapshotRoot }
}

function Restore-PKODSnapshot([string]$GameRoot,$Snapshot) {
    foreach ($record in @($Snapshot.Records)) {
        $target=Join-Path $GameRoot ([string]$record.Relative)
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
        if ($record.Exists) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath (Join-Path (Join-Path $Snapshot.SnapshotRoot 'files') ([string]$record.Relative)) -Destination $target -Force -ErrorAction Stop
        }
    }
    $backup=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup"
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue }
    if ($Snapshot.BackupExists) { Copy-Item -LiteralPath (Join-Path $Snapshot.SnapshotRoot 'ownership-backup') -Destination $backup -Recurse -Force -ErrorAction Stop }
}

function Install-PKODOwnedPayload {
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string]$SourceRoot,
        [Parameter(Mandatory=$true)][string]$Version,
        [Parameter(Mandatory=$true)][string]$InstalledPathReceipt
    )
    if (-not (Test-PKODGameRoot $GameRoot)) { throw 'The selected folder is not a complete Painkiller: Overdose installation.' }
    if (-not (Test-PKODPayload -Root $SourceRoot -Version $Version)) { throw 'The install stage has no verified Painkiller: Overdose VR launcher.' }
    if (-not (Test-Path -LiteralPath (Join-Path $SourceRoot $HUB_LAUNCHER) -PathType Leaf)) { throw 'The stable Hub VR launcher is missing from the install stage.' }
    [void](Install-OwnedModPayload -SourceRoot $SourceRoot -GameRoot $GameRoot -Identity $IDENTITY -AdoptIdenticalExisting)
    $publisher=Get-PKODPublisherExecutable $GameRoot
    if (-not $publisher -or -not (Test-PKODPayload -Root $GameRoot -Version $Version)) { throw 'The installed publisher VR launcher failed its functional proof.' }
    $watch=@($publisher.FullName,(Join-Path $GameRoot $HUB_LAUNCHER),(Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"))
    if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $GameRoot -NoClear)) { throw 'Required Painkiller: Overdose VR files are missing after installation.' }
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $GameRoot -Version $Version `
        -InstalledPathReceiptPaths @($InstalledPathReceipt) -Route 'Current')
}

function global:Invoke-PainkillerOverdoseVRInstaller {
    $work=$null; $game=$null; $snapshot=$null; $changesStarted=$false
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Painkiller: Overdose VR - Installer' -ForegroundColor Cyan
        Write-Host '  Motion-control OpenXR conversion by STR_Paragor' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host '  This setup adds the official standalone VR launcher beside' -ForegroundColor White
        Write-Host '  the existing Bin and Data folders. Bin\Overdose.exe remains' -ForegroundColor White
        Write-Host '  the unchanged Flat version.' -ForegroundColor White
        Write-Host ''
        Write-PKODWarn 'The VR launcher is incompatible with other Overdose mods.'
        Write-PKODWarn 'When VR starts, it deletes Data\LScripts and Data\Textures'
        Write-PKODWarn 'if present. Back up custom files in those folders first.'
        Write-Host ''
        Write-Host '  The publisher launcher is unsigned. Antivirus software may' -ForegroundColor Yellow
        Write-Host '  inspect or remove it. Setup verifies the file after copying' -ForegroundColor Yellow
        Write-Host '  and reports missing files without assuming the cause.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'After reading the warning, press Enter to proceed...')

        Write-PKODStep 1 5 'Locating Painkiller: Overdose'
        $game=Get-PKODGameRoot
        if (-not $game) { throw 'Setup cancelled before any game file was changed.' }
        if (Get-Process -Name 'Overdose','Painkiller - Overdose VR*' -ErrorAction SilentlyContinue) { throw 'Painkiller: Overdose is running. Close it completely and try again.' }
        if (-not (Test-InstallerTargetWritable -TargetPath $game)) { throw 'The game folder is not writable. Run setup as administrator, then try again.' }
        Write-PKODOK "Found: $game"

        Write-PKODStep 2 5 'Getting the newest stable VR release'
        $release=Get-PKODRelease
        if (-not (Test-IsTrackableInstalledVersion $release.Tag)) { throw 'GitHub did not provide a trackable stable release version.' }
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_pkod_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'PainkillerOverdoseVR.zip'
        $downloaded=Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "Painkiller: Overdose VR $($release.Tag)" `
            -ManualUrl $release.PageUrl -AllowSkip $false
        if (-not ($downloaded -eq $true -or [string]$downloaded -in @('retry','manual'))) { throw 'The official VR release was not downloaded.' }
        $extract=Join-Path $work 'extract'
        if ([string](Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'Painkiller: Overdose VR release' -AllowSkip $false -QuietProgress) -notin @('ok','manual','retry')) {
            throw 'The official VR release could not be extracted.'
        }
        $payload=Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'ReadMe! EN.txt'
        $stage=New-PKODInstallStage -ExtractRoot $payload -Stage (Join-Path $work 'stage') -Version $release.Tag
        Write-PKODOK "Functional publisher package $($release.Tag) verified."

        Write-PKODStep 3 5 'Preparing a recoverable game-folder transaction'
        $snapshot=Save-PKODSnapshot -GameRoot $game -Stage $stage -SnapshotRoot (Join-Path $work 'rollback')
        $changesStarted=$true
        Write-PKODOK 'Existing Hub-owned files and collisions are recoverable.'

        Write-PKODStep 4 5 'Installing and checking the VR launcher'
        $receipt=Join-Path $PSScriptRoot '.installed_path'
        Install-PKODOwnedPayload -GameRoot $game -SourceRoot $stage -Version $release.Tag -InstalledPathReceipt $receipt
        $changesStarted=$false
        $publisher=Get-PKODPublisherExecutable $game
        try {
            [void](New-DesktopShortcut -ShortcutName 'Painkiller Overdose VR' -TargetPath (Join-Path $game $HUB_LAUNCHER) `
                -WorkingDir $game -IconPath ($publisher.FullName+',0') -Description 'Launch Painkiller: Overdose in VR')
            Write-PKODOK 'Desktop shortcut created.'
        } catch { Write-PKODWarn 'VR is installed, but the optional desktop shortcut could not be created.' }

        Write-PKODStep 5 5 'Finishing setup'
        Write-PKODOK "Painkiller: Overdose VR $($release.Tag) is installed and tracked."
        Write-Host ''
        Write-Host '  1. Use Start in VR in the Hub.' -ForegroundColor White
        Write-Host '  2. Or use the Painkiller Overdose VR desktop shortcut.' -ForegroundColor White
        Write-Host '  The original Bin\Overdose.exe remains the Flat launch route.' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  First VR start may spend 30 seconds to 5 minutes preparing' -ForegroundColor Yellow
        Write-Host '  game files. Later launches should be fast. Connect through' -ForegroundColor Yellow
        Write-Host '  Virtual Desktop, Steam Link or Meta Horizon Link first.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $game -and $snapshot) {
            try { Restore-PKODSnapshot -GameRoot $game -Snapshot $snapshot; Write-PKODWarn 'The previous Painkiller: Overdose folder state was restored.' }
            catch { Write-PKODWarn ('Rollback also needs attention: '+$_.Exception.Message) }
        }
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ((('' + $env:PCVR_PKOD_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-PainkillerOverdoseVRInstaller }
