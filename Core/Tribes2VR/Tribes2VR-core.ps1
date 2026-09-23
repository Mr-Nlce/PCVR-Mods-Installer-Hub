# Tribes 2 VR - free PlayT2/TribesNEXT base game plus the Discord beta mod.
# The commercial-free base installer and Valve's 32-bit OpenVR runtime remain
# publisher downloads; no third-party executable or DLL is bundled with Hub.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'Tribes2VRElevatedOperations.ps1')

$Host.UI.RawUI.WindowTitle = 'Tribes 2 VR Installer'
$IDENTITY = 'tribes2vr'
$VERSION = 'discord-0.1-beta+openvr-2.5.1'
$GAME_EXE = 'GameData\Tribes2.exe'
$DEFAULT_ROOT = 'C:\Dynamix\Tribes2'
$BASE_PAGE = 'https://playt2.com/config'
$BASE_INSTALLER_URL = 'https://files.playt2.com/Install/Tribes2Config_2.3_Preview.exe'
$DISCORD_INVITE = 'https://discord.gg/uAeQkYBM4n'
$DISCORD_THREAD = 'https://discord.com/channels/747967102895390741/1548700072697528461'
$DISCORD_DOWNLOAD = 'https://discord.com/channels/747967102895390741/1548700072697528461/1548700072697528461'
$OPENVR_URL = 'https://raw.githubusercontent.com/ValveSoftware/openvr/v2.5.1/bin/win32/openvr_api.dll'
$OPENVR_PAGE = 'https://github.com/ValveSoftware/openvr/releases/tag/v2.5.1'
$REQUIRED_MOD_FILES = @('tribes2vr_launcher.exe','tribes2vr.dll','tribes2vr.ini')
$contract = New-PCVRInstallerContract -Id 'tribes-2-vr' -GameName 'Tribes 2 VR' -Acquisition Discord -AntivirusNotice `
    -DiscordInviteUrl $DISCORD_INVITE -DiscordDownloadUrl $DISCORD_DOWNLOAD -ReleasePageUrl $DISCORD_THREAD `
    -RequiredInstalledFileGroups @(
        'GameData\Tribes2.exe','GameData\uninstall_TribesNEXT.exe|GameData\console_client_patches.cs',
        'GameData\tribes2vr_launcher.exe','GameData\tribes2vr.dll','GameData\tribes2vr.ini',
        'GameData\openvr_api.dll','GameData\Tribes2VR.ico','GameData\.pcvrhub_tribes2vr_ownership.csv'
    )

function Write-TribesStep([int]$Number,[int]$Total,[string]$Text) { Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-TribesOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-TribesWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }
function Write-TribesNote([string]$Text) { Write-Host "  $Text" -ForegroundColor Gray }

function Test-Tribes2Root([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root $GAME_EXE) -PathType Leaf -ErrorAction SilentlyContinue))
}

function Test-Tribes2CommunityPatch([string]$Root) {
    if (-not (Test-Tribes2Root $Root)) { return $false }
    $uninstaller = Join-Path $Root 'GameData\uninstall_TribesNEXT.exe'
    $clientPatch = Join-Path $Root 'GameData\console_client_patches.cs'
    if (Test-Path -LiteralPath $uninstaller -PathType Leaf -ErrorAction SilentlyContinue) { return $true }
    if (-not (Test-Path -LiteralPath $clientPatch -PathType Leaf -ErrorAction SilentlyContinue)) { return $false }
    return [bool](Get-ChildItem -LiteralPath $Root -Filter 'TribesNEXT_*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Resolve-Tribes2Root([string]$Path) {
    $value = ('' + $Path).Trim().Trim('"').Trim("'")
    if (-not $value -or -not (Test-Path -LiteralPath $value -ErrorAction SilentlyContinue)) { return $null }
    $item = Get-Item -LiteralPath $value -ErrorAction SilentlyContinue
    if (-not $item) { return $null }
    if (-not $item.PSIsContainer) {
        if ($item.Name -ine 'Tribes2.exe') { return $null }
        $data = $item.Directory
        if ($data.Name -ieq 'GameData') { return $data.Parent.FullName }
        return $null
    }
    if (Test-Tribes2Root $item.FullName) { return $item.FullName }
    if ($item.Name -ieq 'GameData' -and (Test-Path -LiteralPath (Join-Path $item.FullName 'Tribes2.exe') -PathType Leaf)) { return $item.Parent.FullName }
    return $null
}

function Find-Tribes2Root {
    $candidates = [Collections.Generic.List[string]]::new()
    foreach ($candidate in @(
        ('' + $env:PCVR_TRIBES2_GAME_ROOT).Trim(),
        $(try { ([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim() } catch { '' }),
        $(try { Get-HubLocatedGameFolder -GameId 'tribes-2-vr' -ProbeFiles @($GAME_EXE) } catch { '' }),
        $DEFAULT_ROOT,'D:\Dynamix\Tribes2','E:\Dynamix\Tribes2'
    )) { if ($candidate) { $candidates.Add($candidate) } }
    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        $root = Resolve-Tribes2Root $candidate
        if ($root -and (Test-Tribes2CommunityPatch $root)) { return $root }
    }
    return $null
}

function Read-Tribes2RootInteractive {
    Write-Host ''
    Write-Host '  Drag Tribes2.exe onto this window, paste the game root or GameData' -ForegroundColor White
    Write-Host '  folder, then press Enter. Type Q to stop without changes.' -ForegroundColor Gray
    for ($i=1; $i -le 10; $i++) {
        $raw = ('' + (Read-Host "  Game path (attempt $i/10)")).Trim()
        if ($raw -match '(?i)^(q|quit|exit)$') { return $null }
        $root = Resolve-Tribes2Root $raw
        if (-not $root) { Write-Host '  That path does not contain GameData\Tribes2.exe.' -ForegroundColor Yellow; continue }
        if (-not (Test-Tribes2CommunityPatch $root)) {
            Write-Host '  Tribes 2 was found, but the required TribesNEXT community patch was not.' -ForegroundColor Yellow
            Write-Host '  Run the PlayT2 configuration installer, keep the patch selected, then try again.' -ForegroundColor Gray
            continue
        }
        return $root
    }
    return $null
}

function Install-Tribes2BaseGame([string]$WorkRoot) {
    Write-Host '  The official PlayT2 package is about 917 MiB and is not digitally signed.' -ForegroundColor Yellow
    Write-Host "  It proposes $DEFAULT_ROOT. Keep 'Install community patch' checked." -ForegroundColor White
    Write-Host '  At the end choose I Agree, then Apply Patch. The setup itself needs UAC.' -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the official PlayT2 installer...')
    $installer = Join-Path $WorkRoot 'Tribes2Config_2.3_Preview.exe'
    Write-TribesNote 'Downloading the official free-game and community-patch installer...'
    $got = Invoke-SafeDownload -Urls @($BASE_INSTALLER_URL) -Destination $installer -Label 'Tribes 2 Config 2.3 Preview' `
        -ManualUrl $BASE_PAGE -AllowSkip $false -QuietProgress
    if (-not ($got -eq $true -or [string]$got -in @('retry','manual'))) { throw 'The official PlayT2 installer was not downloaded.' }
    if ((Get-Item -LiteralPath $installer).Length -lt 100MB) { throw 'The downloaded PlayT2 file is incomplete or not the official installer.' }
    Write-Host ''
    Write-Host '  Windows will now request administrator rights for the official setup.' -ForegroundColor Yellow
    Write-Host "  Keep 'Install community patch' checked; finish with I Agree and Apply Patch." -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start the official PlayT2 setup...')
    $process = Start-Process -FilePath $installer -Verb RunAs -Wait -PassThru -ErrorAction Stop
    if ($null -eq $process.ExitCode -or [int]$process.ExitCode -ne 0) { throw "The PlayT2 setup did not finish successfully (exit code $($process.ExitCode))." }
    $root = Find-Tribes2Root
    if (-not $root) { $root = Read-Tribes2RootInteractive }
    if (-not $root) { throw 'The patched Tribes 2 installation was not found after the official setup.' }
    return $root
}

function Select-Tribes2Root([string]$WorkRoot) {
    $detected = Find-Tribes2Root
    if ($detected) { Write-TribesOK "Patched Tribes 2 found: $detected"; return $detected }
    Write-Host '  Tribes 2 with the required community patch was not detected.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  [1] Download/install the free game and community patch, then add VR' -ForegroundColor Yellow
    Write-Host '  [2] The patched game already exists - locate Tribes2.exe' -ForegroundColor Yellow
    Write-Host '  [Q] Stop without changes' -ForegroundColor Gray
    while ($true) {
        $choice = ('' + (Read-Host '  Choice')).Trim().ToUpperInvariant()
        if ($choice -eq '1') { return (Install-Tribes2BaseGame -WorkRoot $WorkRoot) }
        if ($choice -eq '2') { return (Read-Tribes2RootInteractive) }
        if ($choice -eq 'Q') { return $null }
        Write-Host '  Choose 1, 2 or Q.' -ForegroundColor Yellow
    }
}

function Test-Tribes2Archive([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf -ErrorAction SilentlyContinue)) { return $false }
    return [bool](Test-ZipPayloadAnchors -Path $Path -MinimumMatches 3 -MinimumEntries 3 -AnchorPatterns @(
        '(?i)(^|[\\/])tribes2vr_launcher\.exe$',
        '(?i)(^|[\\/])tribes2vr\.dll$',
        '(?i)(^|[\\/])tribes2vr\.ini$'
    ))
}

function Get-Tribes2Archive {
    $override = ('' + $env:PCVR_TRIBES2_ARCHIVE).Trim()
    if ($override) {
        if (-not (Test-Tribes2Archive $override)) { throw 'The supplied Tribes2VR archive is not a complete, path-safe package.' }
        return [IO.Path]::GetFullPath($override)
    }
    $validator = ${function:Test-Tribes2Archive}.GetNewClosure()
    $findCandidate = {
        $downloads = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
        foreach ($candidate in @(Get-ChildItem -LiteralPath $downloads -Filter 'Tribes2VR*.zip' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending)) {
            if (& $validator $candidate.FullName) { return $candidate.FullName }
        }
        return $null
    }.GetNewClosure()
    return (Invoke-PCVRDiscordDownloadFlow -Label 'Tribes2VR beta' -InviteUrl $DISCORD_INVITE `
        -DownloadPostUrl $DISCORD_DOWNLOAD -FilePatterns @('Tribes2VR*.zip','*.zip') `
        -SourceDescription 'a Flat2VR Discord post with a Google Drive download' `
        -FindCandidate $findCandidate -ValidateCandidate $validator)
}

function Find-Tribes2Payload([string]$ExtractRoot) {
    $launcher = Get-ChildItem -LiteralPath $ExtractRoot -Filter 'tribes2vr_launcher.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $launcher) { return $null }
    $root = $launcher.DirectoryName
    foreach ($name in $REQUIRED_MOD_FILES) { if (-not (Test-Path -LiteralPath (Join-Path $root $name) -PathType Leaf)) { return $null } }
    return $root
}

function Get-PEMachine([string]$Path) {
    try {
        $stream = [IO.File]::OpenRead($Path)
        try {
            $reader = New-Object IO.BinaryReader($stream)
            $stream.Position = 0x3C; $offset = $reader.ReadInt32(); $stream.Position = $offset
            if ($reader.ReadUInt32() -ne 0x00004550) { return 0 }
            return [int]$reader.ReadUInt16()
        } finally { $stream.Dispose() }
    } catch { return 0 }
}

function New-Tribes2Stage([string]$Payload,[string]$WorkRoot) {
    $stage = Join-Path $WorkRoot 'stage'; [void][IO.Directory]::CreateDirectory($stage)
    foreach ($name in $REQUIRED_MOD_FILES) { Copy-Item -LiteralPath (Join-Path $Payload $name) -Destination (Join-Path $stage $name) -Force -ErrorAction Stop }
    $openvrOverride = ('' + $env:PCVR_TRIBES2_OPENVR).Trim()
    $openvr = Join-Path $stage 'openvr_api.dll'
    if ($openvrOverride) {
        Copy-Item -LiteralPath $openvrOverride -Destination $openvr -Force -ErrorAction Stop
    } else {
        Write-Host '  The beta archive omits openvr_api.dll. Tribes 2 is 32-bit, so' -ForegroundColor White
        Write-Host '  setup will fetch Valve OpenVR 2.5.1 win32 from the official tag.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the official 32-bit OpenVR runtime...')
        Write-TribesNote 'Downloading Valve OpenVR 2.5.1 win32...'
        $got = Invoke-SafeDownload -Urls @($OPENVR_URL) -Destination $openvr -Label 'Valve OpenVR 2.5.1 win32' `
            -ManualUrl $OPENVR_PAGE -AllowSkip $false -QuietProgress
        if (-not ($got -eq $true -or [string]$got -in @('retry','manual'))) { throw 'The official OpenVR runtime was not downloaded.' }
    }
    if ((Get-PEMachine $openvr) -ne 0x014c) { throw 'openvr_api.dll is not a valid 32-bit Windows runtime.' }
    $icon = Join-Path $PSScriptRoot 'Tribes2VR.ico'
    if (-not (Test-Path -LiteralPath $icon -PathType Leaf)) { throw 'The Tribes 2 VR shortcut icon is missing.' }
    Copy-Item -LiteralPath $icon -Destination (Join-Path $stage 'Tribes2VR.ico') -Force -ErrorAction Stop
    return $stage
}

function Save-Tribes2Snapshot([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $paths = [Collections.Generic.List[string]]::new()
    $stageBase = [IO.Path]::GetFullPath($Stage).TrimEnd('\','/')
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File -ErrorAction Stop)) {
        $paths.Add(('GameData\' + $file.FullName.Substring($stageBase.Length + 1).Replace('/','\')))
    }
    $manifest = Join-Path $GameRoot 'GameData\.pcvrhub_tribes2vr_ownership.csv'
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        try { foreach ($row in @(Import-Csv -LiteralPath $manifest)) { if ($row.RelativePath) { $paths.Add('GameData\' + [string]$row.RelativePath) } } } catch {}
    }
    foreach ($extra in @('GameData\.pcvrhub_tribes2vr_ownership.csv','GameData\.pcvrhub_tribes2vr_ownership.csv.new','.pcvrhub_version')) { $paths.Add($extra) }
    $records = @()
    foreach ($relative in @($paths | Select-Object -Unique)) {
        $source = Join-Path $GameRoot $relative
        $exists = Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{ Relative=$relative; Existed=$exists }
        if ($exists) {
            $copy = Join-Path (Join-Path $SnapshotRoot 'files') $relative
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $copy))
            Copy-Item -LiteralPath $source -Destination $copy -Force -ErrorAction Stop
        }
    }
    $records | Export-Csv -LiteralPath (Join-Path $SnapshotRoot 'records.csv') -NoTypeInformation -Encoding UTF8
    $backup = Join-Path $GameRoot 'GameData\.pcvrhub_tribes2vr_backup'
    if (Test-Path -LiteralPath $backup -PathType Container) { Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'ownership-backup') -Recurse -Force -ErrorAction Stop }
    return $SnapshotRoot
}

function Restore-Tribes2Snapshot([string]$GameRoot,[string]$SnapshotRoot) {
    $records = Import-Csv -LiteralPath (Join-Path $SnapshotRoot 'records.csv')
    foreach ($record in @($records)) {
        $target = Join-Path $GameRoot ([string]$record.Relative)
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction Stop }
        if ([string]$record.Existed -eq 'True') {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath (Join-Path (Join-Path $SnapshotRoot 'files') ([string]$record.Relative)) -Destination $target -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $GameRoot 'GameData\.pcvrhub_tribes2vr_backup'
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop }
    $saved = Join-Path $SnapshotRoot 'ownership-backup'
    if (Test-Path -LiteralPath $saved -PathType Container) { Copy-Item -LiteralPath $saved -Destination $backup -Recurse -Force -ErrorAction Stop }
}

function Install-Tribes2OwnedPayload([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot) {
    $dataRoot = Join-Path $GameRoot 'GameData'
    $watch = @('tribes2vr_launcher.exe','tribes2vr.dll','tribes2vr.ini','openvr_api.dll','Tribes2VR.ico','.pcvrhub_tribes2vr_ownership.csv') | ForEach-Object { Join-Path $dataRoot $_ }
    if (Test-InstallerTargetWritable -TargetPath $dataRoot) {
        [void](Install-OwnedModPayload -SourceRoot $Stage -GameRoot $dataRoot -Identity $IDENTITY -KeepExistingRelativePaths @('tribes2vr.ini') -AdoptIdenticalExisting)
        $recopy = { [void](Install-OwnedModPayload -SourceRoot $Stage -GameRoot $dataRoot -Identity $IDENTITY -KeepExistingRelativePaths @('tribes2vr.ini') -AdoptIdenticalExisting) }.GetNewClosure()
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $dataRoot -Recopy $recopy)) { throw 'Required Tribes 2 VR files are still missing.' }
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $GameRoot -Version $VERSION `
            -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current)
        return
    }

    Write-Host '  Copying into GameData needs administrator rights.' -ForegroundColor Yellow
    Write-Host '  The next UAC request is only for the recoverable VR-file transaction.' -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to request administrator rights and install the VR files...')
    $result = Invoke-Tribes2VRElevatedOperation -Action Install -GameRoot $GameRoot -SourceRoot $Stage -Version $VERSION -SnapshotRoot $SnapshotRoot
    if ($result -and [string]$result.FailureKind -eq 'MissingAfterCopy') {
        $recopy = {
            $retry = Invoke-Tribes2VRElevatedOperation -Action Install -GameRoot $GameRoot -SourceRoot $Stage -Version $VERSION -SnapshotRoot $SnapshotRoot
            if (-not $retry -or -not [bool]$retry.Success) { throw ([string]$retry.Error) }
        }.GetNewClosure()
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $dataRoot -Recopy $recopy -NoClear)) { throw 'Required Tribes 2 VR files are still missing.' }
    }
}

function global:Invoke-Tribes2VRInstaller {
    $work = $null; $gameRoot = $null; $snapshot = $null; $changesStarted = $false; $usedElevation = $false
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Tribes 2 VR - Installer' -ForegroundColor Cyan
        Write-Host '  Free PlayT2 game + required TribesNEXT patch + VR beta' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host '  The VR beta provides stereo rendering, head tracking and motion controls.' -ForegroundColor White
        Write-Host '  The original game is free. Its community patch is required.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start setup...')

        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_tribes2_' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)

        Write-TribesStep 1 5 'Finding or installing the free patched game'
        $gameRoot = Select-Tribes2Root -WorkRoot $work
        if (-not $gameRoot -or -not (Test-Tribes2CommunityPatch $gameRoot)) { throw 'Setup stopped before any game file was changed.' }
        $gameRoot = (Get-Item -LiteralPath $gameRoot).FullName
        if (Get-Process -Name 'Tribes2','tribes2vr_launcher' -ErrorAction SilentlyContinue) { throw 'Tribes 2 is running. Close it completely and run setup again.' }
        Write-TribesOK "Game and TribesNEXT patch verified: $gameRoot"

        Write-TribesStep 2 5 'Getting the VR beta from its Discord post'
        $archive = Get-Tribes2Archive
        if (-not $archive) { throw 'No usable Tribes2VR archive was supplied.' }
        Write-TribesOK 'The archive is readable, path-safe and contains launcher, DLL and configuration.'

        Write-TribesStep 3 5 'Adding the official 32-bit OpenVR runtime'
        $extract = Join-Path $work 'extract'
        $expanded = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'Tribes2VR beta' -AllowSkip $false -QuietProgress
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The Tribes2VR archive could not be extracted.' }
        $payload = Find-Tribes2Payload $extract
        if (-not $payload) { throw 'The current archive is missing a functional launcher, DLL or INI file.' }
        $stage = New-Tribes2Stage -Payload $payload -WorkRoot $work
        Write-TribesOK 'VR beta and Valve OpenVR 2.5.1 win32 are staged together.'

        Write-TribesStep 4 5 'Installing the VR launcher recoverably'
        $snapshot = Save-Tribes2Snapshot -GameRoot $gameRoot -Stage $stage -SnapshotRoot (Join-Path $work 'rollback')
        $changesStarted = $true
        $usedElevation = -not (Test-InstallerTargetWritable -TargetPath (Join-Path $gameRoot 'GameData'))
        Install-Tribes2OwnedPayload -GameRoot $gameRoot -Stage $stage -SnapshotRoot $snapshot
        $changesStarted = $false
        Write-TribesOK 'Launcher, mod, preserved configuration, OpenVR runtime and ownership record verified.'

        Write-TribesStep 5 5 'Creating the Tribes 2 VR shortcut'
        try {
            $dataRoot = Join-Path $gameRoot 'GameData'
            [void](New-DesktopShortcut -ShortcutName 'Tribes 2 VR' -TargetPath (Join-Path $dataRoot 'tribes2vr_launcher.exe') `
                -WorkingDir $dataRoot -IconPath (Join-Path $dataRoot 'Tribes2VR.ico') -Description 'Launch Tribes 2 in VR')
            Write-TribesOK 'Desktop shortcut created.'
        } catch { Write-TribesWarn 'VR is installed, but the optional desktop shortcut could not be created.' }

        Write-Host ''; Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Setup complete.' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host '  Start in VR uses tribes2vr_launcher.exe. Press [F2] to toggle' -ForegroundColor White
        Write-Host '  motion controls and [F9] to recenter your body and hands.' -ForegroundColor White
        Write-Host '  This beta has no real FOV control. Use Numpad [+]/[-] for perceived' -ForegroundColor Yellow
        Write-Host '  world scale and [ / ] for weapon size; the INI keeps your tuning.' -ForegroundColor Yellow
        Write-Host '  Early-beta limits and the complete controls are on the game page.' -ForegroundColor Gray
        Write-Host ''
        Write-Host '  Shazbot. The skiing line now runs straight through your headset.' -ForegroundColor Magenta
        Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $gameRoot -and $snapshot) {
            try {
                if ($usedElevation) { [void](Invoke-Tribes2VRElevatedOperation -Action Restore -GameRoot $gameRoot -SnapshotRoot $snapshot) }
                else { Restore-Tribes2Snapshot -GameRoot $gameRoot -SnapshotRoot $snapshot }
                Write-TribesWarn 'The previous Tribes 2 VR state was restored.'
            } catch { Write-TribesWarn ('Rollback also needs attention: ' + $_.Exception.Message) }
        }
        Write-Host ''; Write-Host ('  [XX] ' + $_.Exception.Message) -ForegroundColor Red
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ((('' + $env:PCVR_TRIBES2_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-Tribes2VRInstaller }
