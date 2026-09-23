# ELDERBORN VR - preconfigured UUVR Discord installer plus first-party
# motion-control and roomscale bridge.
#
# Contract: Steam/Humble and GOG game roots must contain ELDERBORN.exe;
# the Flat2VR invite and exact Discord download post are separate, gated
# actions; the package is accepted by current functional contents rather
# than a historical name, size or hash; publisher runtime logs and caches
# are not installed; user configs survive updates and removal; every game
# file written by setup is tracked by a recoverable ownership manifest.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'ELDERBORN VR Installer'
$APP_ID = '727850'
$GAME_EXE = 'ELDERBORN.exe'
$IDENTITY = 'elderbornvr'
$VERSION = 'discord-2026-08-28+elderbornvrmod-1.27.0'
$BUNDLED_MOD_VERSION = '1.27.0'
$BUNDLED_MOD_SHA256 = '2EA907FE767D557D536E43C69B60EE60D76B160A41BEA7FD2E87141B39B4F6B8'
$BUNDLED_MOD = Join-Path $PSScriptRoot 'Bundled\ElderbornVRMod.dll'
$DISCORD_INVITE = 'https://discord.gg/uAeQkYBM4n'
$DISCORD_THREAD = 'https://discord.com/channels/747967102895390741/1542935421649027152'
$DISCORD_DOWNLOAD = 'https://discord.com/channels/747967102895390741/1542935421649027152/1542935629313351770'
$CONFIG_PATHS = @('BepInEx\config\BepInEx.cfg','BepInEx\config\raicuparta.uuvr-modern.cfg')
$SKIP_PATHS = @('BepInEx\LogOutput.log')
$contract = New-PCVRInstallerContract -Id 'elderborn-vr' -GameName 'ELDERBORN VR' `
    -Acquisition Discord -AntivirusNotice -DiscordInviteUrl $DISCORD_INVITE `
    -DiscordDownloadUrl $DISCORD_DOWNLOAD -ReleasePageUrl $DISCORD_THREAD `
    -RequiredInstalledFileGroups @(
        'winhttp.dll|winhttp.dll.pcvrhub_off',
        'doorstop_config.ini',
        'BepInEx\core\BepInEx.dll',
        'BepInEx\core\BepInEx.Preloader.dll',
        'BepInEx\patchers\Uuvr.Patcher.dll',
        'BepInEx\plugins\Uuvr.dll',
        'BepInEx\plugins\Uuvr.XR.Management.dll',
        'BepInEx\plugins\Uuvr.XR.OpenXR.dll',
        'BepInEx\plugins\ElderbornVRMod.dll',
        'BepInEx\config\raicuparta.uuvr-modern.cfg',
        '.pcvrhub_elderbornvr_ownership.csv'
    )

function Write-ElderbornStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host ''
}
function Write-ElderbornOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-ElderbornNote([string]$Text) { Write-Host "  $Text" -ForegroundColor Gray }
function Write-ElderbornWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function Test-ElderbornBundledMod([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction SilentlyContinue)) { return $false }
    try {
        return ((Get-Item -LiteralPath $Path -ErrorAction Stop).Length -eq 43008 -and
                (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash -eq $BUNDLED_MOD_SHA256)
    } catch { return $false }
}

function Test-ElderbornRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf -ErrorAction SilentlyContinue))
}

function Test-ElderbornArchive([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction SilentlyContinue)) { return $false }
    return [bool](Test-ZipPayloadAnchors -Path $Path -MinimumMatches 9 -MinimumEntries 20 -AnchorPatterns @(
        '(?i)(^|[\\/])winhttp\.dll$',
        '(?i)(^|[\\/])doorstop_config\.ini$',
        '(?i)(^|[\\/])BepInEx[\\/]core[\\/]BepInEx\.dll$',
        '(?i)(^|[\\/])BepInEx[\\/]core[\\/]BepInEx\.Preloader\.dll$',
        '(?i)(^|[\\/])BepInEx[\\/]patchers[\\/]Uuvr\.Patcher\.dll$',
        '(?i)(^|[\\/])BepInEx[\\/]plugins[\\/]Uuvr\.dll$',
        '(?i)(^|[\\/])BepInEx[\\/]plugins[\\/]Uuvr\.XR\.Management\.dll$',
        '(?i)(^|[\\/])BepInEx[\\/]plugins[\\/]Uuvr\.XR\.OpenXR\.dll$',
        '(?i)(^|[\\/])BepInEx[\\/]config[\\/]raicuparta\.uuvr-modern\.cfg$'
    ))
}

function Find-ElderbornPayload([string]$Root) {
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $null }
    $candidates = @((Get-Item -LiteralPath $Root)) + @(Get-ChildItem -LiteralPath $Root -Directory -Recurse -ErrorAction SilentlyContinue)
    foreach ($candidate in $candidates) {
        $base = $candidate.FullName
        if ((Test-Path -LiteralPath (Join-Path $base 'winhttp.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $base 'doorstop_config.ini') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $base 'BepInEx\core\BepInEx.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $base 'BepInEx\core\BepInEx.Preloader.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $base 'BepInEx\patchers\Uuvr.Patcher.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $base 'BepInEx\plugins\Uuvr.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $base 'BepInEx\plugins\Uuvr.XR.Management.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $base 'BepInEx\plugins\Uuvr.XR.OpenXR.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $base 'BepInEx\config\raicuparta.uuvr-modern.cfg') -PathType Leaf)) {
            return $base
        }
    }
    return $null
}

function Copy-ElderbornPayloadToStage([string]$Payload,[string]$Stage) {
    [void][IO.Directory]::CreateDirectory($Stage)
    $base = [IO.Path]::GetFullPath($Payload).TrimEnd('\','/')
    foreach ($file in @(Get-ChildItem -LiteralPath $Payload -Recurse -File -ErrorAction Stop)) {
        $relative = $file.FullName.Substring($base.Length + 1).Replace('/','\')
        if ($SKIP_PATHS -contains $relative -or $relative.StartsWith('BepInEx\cache\',[StringComparison]::OrdinalIgnoreCase)) { continue }
        $target = Join-Path $Stage $relative
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force -ErrorAction Stop
    }
    if (-not (Test-ElderbornBundledMod $BUNDLED_MOD)) {
        throw 'The Hub-bundled Elderborn motion-control bridge is missing or damaged. No game file was changed.'
    }
    $modTarget = Join-Path $Stage 'BepInEx\plugins\ElderbornVRMod.dll'
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $modTarget))
    Copy-Item -LiteralPath $BUNDLED_MOD -Destination $modTarget -Force -ErrorAction Stop
    return $Stage
}

function Save-ElderbornInstallSnapshot([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $paths = [Collections.Generic.List[string]]::new()
    $stageBase = [IO.Path]::GetFullPath($Stage).TrimEnd('\','/')
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File -ErrorAction Stop)) {
        $paths.Add($file.FullName.Substring($stageBase.Length + 1).Replace('/','\'))
    }
    $manifest = Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        try { foreach ($row in @(Import-Csv -LiteralPath $manifest)) { if ($row.RelativePath) { $paths.Add([string]$row.RelativePath) } } } catch {}
    }
    foreach ($extra in @(".pcvrhub_${IDENTITY}_ownership.csv",".pcvrhub_${IDENTITY}_ownership.csv.new",'.pcvrhub_version','winhttp.dll.pcvrhub_off')) { $paths.Add($extra) }
    $records = @()
    foreach ($relative in @($paths | Select-Object -Unique)) {
        $source = Join-Path $GameRoot $relative
        $exists = Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{ Relative=$relative; Exists=$exists }
        if ($exists) {
            $copy = Join-Path (Join-Path $SnapshotRoot 'files') $relative
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy))
            Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup"
    $backupCopy = Join-Path $SnapshotRoot 'ownership-backup'
    $backupExists = Test-Path -LiteralPath $backup -PathType Container
    if ($backupExists) { Copy-Item -LiteralPath $backup -Destination $backupCopy -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{ Records=$records; BackupExists=$backupExists; SnapshotRoot=$SnapshotRoot }
}

function Restore-ElderbornInstallSnapshot([string]$GameRoot,$Snapshot) {
    foreach ($record in @($Snapshot.Records)) {
        $target = Join-Path $GameRoot ([string]$record.Relative)
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
        if ($record.Exists) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath (Join-Path (Join-Path $Snapshot.SnapshotRoot 'files') ([string]$record.Relative)) -Destination $target -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $GameRoot ".pcvrhub_${IDENTITY}_backup"
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue }
    if ($Snapshot.BackupExists) { Copy-Item -LiteralPath (Join-Path $Snapshot.SnapshotRoot 'ownership-backup') -Destination $backup -Recurse -Force -ErrorAction Stop }
}

function Enable-ElderbornForUpdate([string]$GameRoot) {
    $live = Join-Path $GameRoot 'winhttp.dll'
    $parked = Join-Path $GameRoot 'winhttp.dll.pcvrhub_off'
    if ((Test-Path -LiteralPath $live -PathType Leaf) -and (Test-Path -LiteralPath $parked -PathType Leaf)) {
        throw 'Both active and parked UUVR loaders exist. Resolve that collision before updating.'
    }
    if (-not (Test-Path -LiteralPath $parked -PathType Leaf)) { return $false }
    $manifest = Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw 'A parked UUVR loader exists without a Hub ownership record. Nothing was overwritten.' }
    $row = @(Import-Csv -LiteralPath $manifest | Where-Object RelativePath -eq 'winhttp.dll' | Select-Object -First 1)[0]
    if (-not $row -or (Get-FileHash -LiteralPath $parked -Algorithm SHA256).Hash -ne [string]$row.InstalledSha256) {
        throw 'The parked UUVR loader differs from the Hub ownership record. Nothing was overwritten.'
    }
    Move-Item -LiteralPath $parked -Destination $live -Force -ErrorAction Stop
    return $true
}

function Restore-ElderbornFlatChoice([string]$GameRoot,[bool]$WasFlat) {
    if (-not $WasFlat) { return }
    $live = Join-Path $GameRoot 'winhttp.dll'
    $parked = Join-Path $GameRoot 'winhttp.dll.pcvrhub_off'
    if (-not (Test-Path -LiteralPath $live -PathType Leaf) -or (Test-Path -LiteralPath $parked)) {
        throw 'The previous Flat-mode choice could not be restored safely.'
    }
    Move-Item -LiteralPath $live -Destination $parked -Force -ErrorAction Stop
}

function Get-ElderbornArchive {
    $override = ('' + $env:PCVR_ELDERBORN_ARCHIVE).Trim()
    if ($override) {
        if (-not (Test-ElderbornArchive $override)) { throw 'The supplied Elderborn test/source archive is not a complete, safe UUVR package.' }
        return [IO.Path]::GetFullPath($override)
    }
    # Invoke-PCVRDiscordDownloadFlow executes these callbacks from the shared
    # foundation scope. Capture the validator body itself so it remains
    # callable there; a bare Test-ElderbornArchive command name does not.
    $validator = ${function:Test-ElderbornArchive}.GetNewClosure()
    $findCandidate = {
        $downloads = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
        foreach ($candidate in @(Get-ChildItem -LiteralPath $downloads -Filter '*.zip' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending)) {
            if (& $validator $candidate.FullName) { return $candidate.FullName }
        }
        return $null
    }.GetNewClosure()
    return (Invoke-PCVRDiscordDownloadFlow -Label 'ElderbornVR.zip' -InviteUrl $DISCORD_INVITE `
        -DownloadPostUrl $DISCORD_DOWNLOAD -FilePatterns @('ElderbornVR*.zip','*.zip') `
        -SourceDescription 'a Flat2VR Discord attachment' -FindCandidate $findCandidate -ValidateCandidate $validator)
}

function global:Invoke-ElderbornVRInstaller {
    $work = $null
    $game = $null
    $snapshot = $null
    $changesStarted = $false
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  ELDERBORN VR - Installer' -ForegroundColor Cyan
        Write-Host '  UUVR 0.4.0 plus roomscale motion controls' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Stereo VR, tracked hands, physical weapon motion and roomscale' -ForegroundColor White
        Write-Host "  are enabled by the first-party ElderbornVRMod $BUNDLED_MOD_VERSION." -ForegroundColor White
        Write-Host '  Steam/Humble and GOG installations are supported.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to proceed with setup...')

        Write-ElderbornStep 1 4 'Locating ELDERBORN'
        $game = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('ELDERBORN') -ProbeExe $GAME_EXE `
            -GogNames @('ELDERBORN') -HubGameId 'elderborn-vr'
        if (-not (Test-ElderbornRoot $game)) {
            $game = Get-GameFolderInteractive -GameName 'ELDERBORN' -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/727850/'
        }
        if ($game -in @('quit','skip',$null) -or -not (Test-ElderbornRoot $game)) { throw 'Setup cancelled before any game file was changed.' }
        $game = (Get-Item -LiteralPath $game).FullName
        if (Get-Process -Name 'ELDERBORN' -ErrorAction SilentlyContinue) { throw 'ELDERBORN is running. Close it completely and run setup again.' }
        if (-not (Test-InstallerTargetWritable -TargetPath $game)) { throw 'The game folder is not writable. Run this installer as administrator, then try again.' }
        Write-ElderbornOK "Found: $game"

        Write-ElderbornStep 2 4 'Getting the Flat2VR Discord package'
        $archive = Get-ElderbornArchive
        if (-not $archive) { throw 'No usable ElderbornVR archive was supplied.' }
        Write-ElderbornOK 'The archive is readable, path-safe and contains the complete UUVR payload.'

        Write-ElderbornStep 3 4 'Installing the UUVR profile recoverably'
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_elderborn_' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $extract = Join-Path $work 'release'
        $expanded = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'ElderbornVR package' -AllowSkip $false -QuietProgress
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The ElderbornVR archive could not be extracted.' }
        $payload = Find-ElderbornPayload $extract
        if (-not $payload) { throw 'The current package has no complete BepInEx and UUVR payload.' }
        $stage = Copy-ElderbornPayloadToStage -Payload $payload -Stage (Join-Path $work 'owned-payload')
        if ((Test-Path -LiteralPath (Join-Path $stage 'BepInEx\LogOutput.log')) -or (Test-Path -LiteralPath (Join-Path $stage 'BepInEx\cache'))) {
            throw 'Publisher runtime leftovers were not removed from the install payload.'
        }
        $snapshot = Save-ElderbornInstallSnapshot -GameRoot $game -Stage $stage -SnapshotRoot (Join-Path $work 'rollback')
        $changesStarted = $true
        $wasFlat = Enable-ElderbornForUpdate -GameRoot $game
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY `
            -KeepExistingRelativePaths $CONFIG_PATHS -AdoptIdenticalExisting)
        $watch = @(
            'winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.dll','BepInEx\core\BepInEx.Preloader.dll',
            'BepInEx\patchers\Uuvr.Patcher.dll','BepInEx\plugins\Uuvr.dll','BepInEx\plugins\Uuvr.XR.Management.dll',
            'BepInEx\plugins\Uuvr.XR.OpenXR.dll','BepInEx\plugins\ElderbornVRMod.dll',
            'BepInEx\config\raicuparta.uuvr-modern.cfg',
            ".pcvrhub_${IDENTITY}_ownership.csv"
        ) | ForEach-Object { Join-Path $game $_ }
        $recopy = {
            [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $game -Identity $IDENTITY `
                -KeepExistingRelativePaths $CONFIG_PATHS -AdoptIdenticalExisting)
        }.GetNewClosure()
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -Recopy $recopy)) {
            throw 'The required UUVR files did not survive the recovery check.'
        }
        Restore-ElderbornFlatChoice -GameRoot $game -WasFlat $wasFlat

        Write-ElderbornStep 4 4 'Verifying the Hub state and recommended settings'
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version $VERSION `
            -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current)
        $changesStarted = $false
        Write-ElderbornOK 'ELDERBORN VR is installed and tracked.'
        Write-Host ''
        Write-Host '  Start your OpenXR runtime before ELDERBORN, then launch the game' -ForegroundColor White
        Write-Host '  normally. Press [F3] to enable UUVR. The motion controls and' -ForegroundColor White
        Write-Host '  roomscale bridge then load automatically. Press [F4] to recenter.' -ForegroundColor Green
        Write-Host '  [F5] toggles head-position tracking as well as the UUVR UI;' -ForegroundColor Yellow
        Write-Host '  normally leave it alone so roomscale stays enabled.' -ForegroundColor Yellow
        Write-Host '  Recommended: Windowed, VSync/Bloom/AO/Motion Blur off,' -ForegroundColor Yellow
        Write-Host '  Anti-Aliasing off (or FXAA only; never TAA).' -ForegroundColor Yellow
        Write-ElderbornNote 'The complete settings image and troubleshooting notes are on the game page.'
        Write-Host ''
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Setup complete.' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  The dungeon is still brutal. At least the blade now has depth.' -ForegroundColor Magenta
        Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $game -and $snapshot) {
            try { Restore-ElderbornInstallSnapshot -GameRoot $game -Snapshot $snapshot; Write-ElderbornWarn 'The previous game-folder state was restored.' }
            catch { Write-ElderbornWarn ('Rollback also needs attention: ' + $_.Exception.Message) }
        }
        Write-Host ''; Write-Host ('  [XX] ' + $_.Exception.Message) -ForegroundColor Red
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ((('' + $env:PCVR_ELDERBORN_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-ElderbornVRInstaller }
