# Metal Gear Solid V: The Phantom Pain VR - GitHub prerelease installer.
# Contract: Steam game 287700; current/prerelease route; game proof
# mgsvtpp.exe; mod proof hook + configs + controls helper + owned binocular
# assets + ownership manifest;
# normal Steam launch; MGS5VR configuration and all unrelated files survive
# updates/removal; dinput8.dll collisions are backed up and restored.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Metal Gear Solid V VR Installer'
$APP_ID = '287700'
$GAME_EXE = 'mgsvtpp.exe'
$REPO = 'nikamigaming-create/MGS5VR'
$RELEASES = "https://github.com/$REPO/releases"
$FALLBACK_TAG = 'experimental-2026-09-20'
$FALLBACK_NAME = 'MGS5VR-experimental-2026-09-20.zip'
$FALLBACK_URL = "https://github.com/$REPO/releases/download/$FALLBACK_TAG/$FALLBACK_NAME"
$IDENTITY = 'mgs5vr'
$QUIP = 'The battlefield changes when every movement is your own.'
$MGS_MANAGED_PATHS = @(
    'dinput8.dll',
    'mgs5vr.ini',
    'mgs5vr-controls.ini',
    'mgs5vr_controls.exe',
    'Edit-Controls.cmd',
    'tools\edit-controls.ps1',
    'retail-assets\Assets\tpp\item\tel\Scenes\tel0_main0_def.fmdl',
    'retail-assets\Assets\tpp\item\tel\Pictures\tel0_main0_def_c00_bsm.dds',
    '.pcvrhub_mgs5vr_ownership.csv'
)
$contract = New-PCVRInstallerContract -Id 'metal-gear-solid-v-the-phantom-pain-vr' `
    -GameName 'Metal Gear Solid V: The Phantom Pain VR' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $RELEASES -RequiredInstalledFileGroups @(
        'dinput8.dll','mgs5vr.ini','mgs5vr-controls.ini','mgs5vr_controls.exe',
        'Edit-Controls.cmd','tools\edit-controls.ps1',
        'retail-assets\Assets\tpp\item\tel\Scenes\tel0_main0_def.fmdl',
        'retail-assets\Assets\tpp\item\tel\Pictures\tel0_main0_def_c00_bsm.dds',
        '.pcvrhub_mgs5vr_ownership.csv'
    )

function Write-MGSStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host ''
}
function Write-MGSOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-MGSInfo([string]$Text) { Write-Host "  [..] $Text" -ForegroundColor Gray }
function Write-MGSWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function Test-MGSRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf))
}

function Set-MGSConfigEnabled([string]$Source,[string]$Destination) {
    $text = [IO.File]::ReadAllText($Source)
    foreach ($name in @('enabled','camera_observer','head_camera_experiment','controller_rig_experiment','wrist_hud_experiment')) {
        $pattern = '(?m)^(\s*' + [regex]::Escape($name) + '\s*=)\s*0\s*$'
        $text = [regex]::Replace($text,$pattern,'${1}1')
    }
    [IO.File]::WriteAllText($Destination,$text,(New-Object Text.UTF8Encoding $false))
}

function Save-MGSInstallSnapshot([string]$GameRoot,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $filesRoot = Join-Path $SnapshotRoot 'files'
    $records = @()
    foreach ($relative in $MGS_MANAGED_PATHS) {
        $source = Join-Path $GameRoot $relative
        $exists = Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{ Relative=$relative; Exists=$exists }
        if ($exists) {
            $copy = Join-Path $filesRoot $relative
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy))
            Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $GameRoot '.pcvrhub_mgs5vr_backup'
    $backupCopy = Join-Path $SnapshotRoot 'ownership-backup'
    $backupExists = Test-Path -LiteralPath $backup -PathType Container
    if ($backupExists) { Copy-Item -LiteralPath $backup -Destination $backupCopy -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{ Records=$records; BackupExists=$backupExists; SnapshotRoot=$SnapshotRoot }
}

function Restore-MGSInstallSnapshot([string]$GameRoot,$Snapshot) {
    foreach ($record in @($Snapshot.Records)) {
        $target = Join-Path $GameRoot ([string]$record.Relative)
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
        if ($record.Exists) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath (Join-Path (Join-Path $Snapshot.SnapshotRoot 'files') ([string]$record.Relative)) `
                -Destination $target -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $GameRoot '.pcvrhub_mgs5vr_backup'
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue }
    if ($Snapshot.BackupExists) {
        Copy-Item -LiteralPath (Join-Path $Snapshot.SnapshotRoot 'ownership-backup') -Destination $backup -Recurse -Force -ErrorAction Stop
    }
}

function global:Invoke-MGS5VRInstaller {
  $work = $null
  $game = $null
  $snapshot = $null
  $changesStarted = $false
  try {
    Clear-Host
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  Metal Gear Solid V: The Phantom Pain VR - Installer' -ForegroundColor Cyan
    Write-Host '  Installs: MGS5VR by nikamigaming-create' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
    Write-Host '  Experimental native OpenXR VR with tracked hands,' -ForegroundColor White
    Write-Host '  wrist HUD, motion aiming and field interactions.' -ForegroundColor White
    Write-Host '  Requires the current TPP 1.0.15.4 Steam game build.' -ForegroundColor Yellow
    Write-Host '  Quest 3 + Touch is tested; other headsets are unverified.' -ForegroundColor Gray
    Write-Host '  Existing MGS5VR settings and any prior dinput8.dll are kept' -ForegroundColor Gray
    Write-Host '  recoverable. Other dinput8 proxy mods cannot run alongside it.' -ForegroundColor Gray
    Write-Host '  FIRST START: finish the opening hospital prompts and character' -ForegroundColor Yellow
    Write-Host '  creation flat before entering VR. If already in VR, press Enter' -ForegroundColor Yellow
    Write-Host '  at the bed, then use the Meta dashboard to finish character' -ForegroundColor Yellow
    Write-Host '  creation on the desktop monitor.' -ForegroundColor Yellow
    Show-AntivirusNotice -Compact
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to proceed with setup...')

    Write-MGSStep 1 4 'Locating Metal Gear Solid V: The Phantom Pain'
    $game = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('MGS_TPP') -ProbeExe $GAME_EXE `
        -HubGameId 'metal-gear-solid-v-the-phantom-pain-vr'
    if (-not (Test-MGSRoot $game)) {
        $game = Get-GameFolderInteractive -GameName 'Metal Gear Solid V: The Phantom Pain' `
            -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/287700/'
    }
    if ($game -in @('quit','skip',$null) -or -not (Test-MGSRoot $game)) { throw 'Setup cancelled before any game file was changed.' }
    $game = (Get-Item -LiteralPath $game).FullName
    if (Get-Process -Name 'mgsvtpp' -ErrorAction SilentlyContinue) { throw 'MGSV is running. Close it completely and run setup again.' }
    Write-MGSOK "Found: $game"

    Write-MGSStep 2 4 'Getting the current experimental GitHub release'
    $release = Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true `
        -AssetPatterns @('(?i)^MGS5VR(?:[-_.].*)?\.zip$') `
        -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_NAME
    Write-MGSInfo "Prerelease: $($release.Tag)"
    $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_mgs5vr_' + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($work)
    $archive = Join-Path $work 'MGS5VR-release.zip'
    $downloaded = Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive `
        -Label "MGS5VR $($release.Tag)" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
    if (-not ($downloaded -eq $true -or [string]$downloaded -in @('retry','manual'))) { throw 'The MGS5VR release was not downloaded.' }

    Write-MGSStep 3 4 'Installing with recoverable file ownership'
    $extract = Join-Path $work 'release'
    $expanded = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'MGS5VR release' -AllowSkip $false
    if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The MGS5VR archive could not be extracted.' }
    $dll = Get-ChildItem -LiteralPath $extract -Filter 'dinput8.dll' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $dll) { throw 'The current release contains no dinput8.dll VR hook.' }
    $payload = $dll.DirectoryName
    $configSource = Join-Path $payload 'mgs5vr.ini'
    if (-not (Test-Path -LiteralPath $configSource -PathType Leaf)) { throw 'The current release contains no mgs5vr.ini configuration.' }
    $controlsConfigSource = Join-Path $payload 'mgs5vr-controls.ini'
    if (-not (Test-Path -LiteralPath $controlsConfigSource -PathType Leaf)) { throw 'The current release contains no mgs5vr-controls.ini configuration.' }
    $stage = Join-Path $work 'owned-payload'
    [void][IO.Directory]::CreateDirectory($stage)
    foreach ($relative in @('dinput8.dll','mgs5vr_controls.exe','Edit-Controls.cmd','tools\edit-controls.ps1')) {
        $source = Join-Path $payload $relative
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "The current release is missing its required $relative file." }
        $target = Join-Path $stage $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop
    }
    $importer = Join-Path $payload 'mgs5vr_import.exe'
    if (-not (Test-Path -LiteralPath $importer -PathType Leaf)) { throw 'The current release contains no owned-game asset importer.' }
    Write-MGSInfo 'Importing the binocular model and material from your owned game data...'
    & $importer $game (Join-Path $stage 'retail-assets')
    if ($LASTEXITCODE -ne 0) { throw 'The owned binocular asset import failed. Verify the game files in Steam and retry.' }
    foreach ($relative in @(
        'retail-assets\Assets\tpp\item\tel\Scenes\tel0_main0_def.fmdl',
        'retail-assets\Assets\tpp\item\tel\Pictures\tel0_main0_def_c00_bsm.dds'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $stage $relative) -PathType Leaf)) { throw "The importer did not create $relative." }
    }
    $snapshot = Save-MGSInstallSnapshot -GameRoot $game -SnapshotRoot (Join-Path $work 'rollback')
    $changesStarted = $true
    [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting)
    $configTarget = Join-Path $game 'mgs5vr.ini'
    if (-not (Test-Path -LiteralPath $configTarget -PathType Leaf)) {
        Set-MGSConfigEnabled -Source $configSource -Destination $configTarget
        Write-MGSOK 'Tracked VR, hands and wrist HUD enabled in a new config.'
    } else {
        Write-MGSOK 'Existing mgs5vr.ini settings preserved.'
    }
    $controlsConfigTarget = Join-Path $game 'mgs5vr-controls.ini'
    if (-not (Test-Path -LiteralPath $controlsConfigTarget -PathType Leaf)) {
        Copy-Item -LiteralPath $controlsConfigSource -Destination $controlsConfigTarget -Force -ErrorAction Stop
        Write-MGSOK 'Current default controls installed.'
    } else {
        Write-MGSOK 'Existing mgs5vr-controls.ini bindings preserved.'
    }
    $watch = @(
        'dinput8.dll','mgs5vr_controls.exe','Edit-Controls.cmd','tools\edit-controls.ps1',
        'retail-assets\Assets\tpp\item\tel\Scenes\tel0_main0_def.fmdl',
        'retail-assets\Assets\tpp\item\tel\Pictures\tel0_main0_def_c00_bsm.dds'
    ) | ForEach-Object { Join-Path $game $_ }
    $recopy = { [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY -AdoptIdenticalExisting) }.GetNewClosure()
    if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -Recopy $recopy)) {
        throw 'The required MGS5VR files did not survive the antivirus recovery check.'
    }

    Write-MGSStep 4 4 'Verifying the Hub route and controls'
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version ([string]$release.Tag) `
        -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current)
    $changesStarted = $false
    Write-MGSOK "MGS5VR $($release.Tag) is installed and tracked."
    Write-Host ''
    Write-Host '  1. Make your headset software the active OpenXR runtime.' -ForegroundColor White
    Write-Host '  2. Start MGSV normally through Steam and use Action Type.' -ForegroundColor White
    Write-Host '  3. Load Continue > Resume Game first.' -ForegroundColor White
    Write-Host '  4. Tracked VR now enters automatically.' -ForegroundColor Yellow
    Write-Host '  Use Edit-Controls.cmd in the game folder to change bindings.' -ForegroundColor Gray
    Write-Host '  The complete illustrated controls are on the game page.' -ForegroundColor Gray
    Write-Host ''
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  Setup complete.' -ForegroundColor Green
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
    Write-Host "  $QUIP" -ForegroundColor Magenta
    Write-Host ''
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
  } catch {
    if ($changesStarted -and $game -and $snapshot) {
        try { Restore-MGSInstallSnapshot -GameRoot $game -Snapshot $snapshot; Write-MGSWarn 'The previous game-folder state was restored.' }
        catch { Write-MGSWarn "Automatic rollback needs review: $($_.Exception.Message)" }
    }
    Write-Host ''; Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red
    throw
  } finally {
    if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
  }
}

if ($env:PCVR_MGS5VR_LIBRARY_ONLY -ne '1') { Invoke-MGS5VRInstaller }
