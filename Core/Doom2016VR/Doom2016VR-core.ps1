# DOOM (2016) VR - KHARVOX installer.
# Contract: Steam base game proof DOOMx64.exe + DOOMx64vk.exe; the mod
# remains in a separate DOOM 2016 VR folder; launcher, OpenXR layer and
# ownership manifest prove the Current route; LocalAppData launcher settings
# and the original game directory remain outside Hub ownership.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'DOOM (2016) VR Installer'
$APP_ID = '379720'
$REPO = 'CactusVRStudios/KHARVOX'
$RELEASES = "https://github.com/$REPO/releases"
$FALLBACK_TAG = 'v1.1.0'
$FALLBACK_NAME = 'KHARVOX-v1.1.zip'
$FALLBACK_URL = "https://github.com/$REPO/releases/download/$FALLBACK_TAG/$FALLBACK_NAME"
$IDENTITY = 'kharvox'
$QUIP = 'Rip and tear now means reaching out and doing it yourself.'
$contract = New-PCVRInstallerContract -Id 'doom-2016-vr' -GameName 'DOOM (2016) VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $RELEASES `
    -RequiredInstalledFileGroups @(
        'KharvoxLauncher.exe','KharvoxLayer.dll','KharvoxLayer.json',
        'openxr_loader.dll','.pcvrhub_kharvox_ownership.csv'
    )

function Write-DoomStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host ''
}
function Write-DoomOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-DoomInfo([string]$Text) { Write-Host "  [..] $Text" -ForegroundColor Gray }
function Write-DoomWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function Get-DoomDesktopRoot {
    $override = ('' + $env:PCVR_DOOM2016_DESKTOP_ROOT).Trim()
    if ($override) { return $override }
    return [Environment]::GetFolderPath('Desktop')
}

function Test-DoomGameRoot([string]$Path) {
    return [bool]($Path -and
        (Test-Path -LiteralPath (Join-Path $Path 'DOOMx64.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path 'DOOMx64vk.exe') -PathType Leaf))
}

function Test-DoomWritableRoot([string]$Root) {
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path -LiteralPath $Root -PathType Container)) { [void][IO.Directory]::CreateDirectory($Root) }
        $probe = Join-Path $Root ('.pcvr-write-' + [Guid]::NewGuid().ToString('N'))
        [IO.File]::WriteAllText($probe,'ok',(New-Object Text.UTF8Encoding $false))
        Remove-Item -LiteralPath $probe -Force -ErrorAction Stop
        return $true
    } catch { return $false }
}

function Get-DoomPortableTarget {
    foreach ($root in @('C:\Games','D:\Games','E:\Games')) {
        if (Test-DoomWritableRoot $root) { return (Join-Path $root 'DOOM 2016 VR') }
    }
    Write-DoomWarn 'No standard Games folder is writable.'
    while ($true) {
        $candidate = ('' + (Read-Host '  Enter a writable parent folder')).Trim().Trim('"')
        if (Test-DoomWritableRoot $candidate) { return (Join-Path $candidate 'DOOM 2016 VR') }
        Write-DoomWarn "Not writable: $candidate"
    }
}

function Find-KharvoxPayload([string]$Root) {
    $candidates = @((Get-Item -LiteralPath $Root -ErrorAction SilentlyContinue)) +
        @(Get-ChildItem -LiteralPath $Root -Directory -Recurse -ErrorAction SilentlyContinue)
    foreach ($candidate in $candidates) {
        if ((Test-Path -LiteralPath (Join-Path $candidate.FullName 'KharvoxLauncher.exe') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $candidate.FullName 'KharvoxLayer.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $candidate.FullName 'KharvoxLayer.json') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $candidate.FullName 'openxr_loader.dll') -PathType Leaf)) {
            return $candidate.FullName
        }
    }
    return $null
}

function Install-DoomKharvoxPayload([string]$Payload,[string]$Target) {
    # KHARVOX itself rewrites this publisher-owned Vulkan layer manifest from
    # a relative path to the selected absolute install path. Prepare the new
    # release with that final value before ownership hashes are recorded. This
    # is runtime metadata, not the user's launcher settings (those remain in
    # LocalAppData), so an earlier launcher rewrite is safe to replace.
    $layerPath = Join-Path $Payload 'KharvoxLayer.json'
    $layer = Get-Content -LiteralPath $layerPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if (-not $layer.layer -or [string]$layer.layer.name -ne 'VK_LAYER_KHARVOX_OPENXR') {
        throw 'The publisher package has an unexpected KHARVOX layer manifest.'
    }
    $layer.layer.library_path = Join-Path $Target 'KharvoxLayer.dll'
    [IO.File]::WriteAllText($layerPath,($layer | ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding $false))
    [void](Install-OwnedModPayload -SourceRoot $Payload -GameRoot $Target -Identity $IDENTITY `
        -ReplaceChangedOwnedRelativePaths @('KharvoxLayer.json') -AdoptIdenticalExisting)
}

function global:Restore-DoomKharvoxInsideTarget([string]$ArchivePath,[string]$Target) {
    $fullTarget = [IO.Path]::GetFullPath($Target).TrimEnd('\','/')
    if ((Split-Path -Leaf $fullTarget) -ne 'DOOM 2016 VR') { throw "Recovery refused unexpected target: $Target" }
    $stage = Join-Path $fullTarget '_pcvrhub_kharvox_recovery'
    try {
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
        [void][IO.Directory]::CreateDirectory($stage)
        $localArchive = Join-Path $stage ('KHARVOX' + [IO.Path]::GetExtension($ArchivePath))
        Copy-Item -LiteralPath $ArchivePath -Destination $localArchive -Force -ErrorAction Stop
        $extract = Join-Path $stage 'release'
        $expanded = Expand-ArchiveOrFallback -ArchivePath $localArchive -DestinationFolder $extract -Label 'KHARVOX antivirus recovery' -AllowSkip $false
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'KHARVOX could not be unpacked inside the excluded VR folder.' }
        $payload = Find-KharvoxPayload $extract
        if (-not $payload) { throw 'The recovery package contains no usable KHARVOX payload.' }
        Install-DoomKharvoxPayload -Payload $payload -Target $fullTarget
        return $true
    } finally {
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Save-DoomTargetSnapshot([string]$Target,[string]$SnapshotRoot) {
    $existed = Test-Path -LiteralPath $Target -PathType Container
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    if ($existed) {
        Get-ChildItem -LiteralPath $Target -Force -ErrorAction Stop | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $SnapshotRoot -Recurse -Force -ErrorAction Stop
        }
    }
    return [pscustomobject]@{ Existed=$existed; Root=$SnapshotRoot }
}

function Restore-DoomTargetSnapshot([string]$Target,$Snapshot) {
    $fullTarget = [IO.Path]::GetFullPath($Target).TrimEnd('\','/')
    if ((Split-Path -Leaf $fullTarget) -ne 'DOOM 2016 VR') { throw "Rollback refused unexpected target: $Target" }
    if (Test-Path -LiteralPath $fullTarget -PathType Container) {
        Get-ChildItem -LiteralPath $fullTarget -Force -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction Stop
    } else { [void][IO.Directory]::CreateDirectory($fullTarget) }
    if ($Snapshot.Existed) {
        Get-ChildItem -LiteralPath $Snapshot.Root -Force -ErrorAction Stop | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $fullTarget -Recurse -Force -ErrorAction Stop
        }
    } else {
        Remove-Item -LiteralPath $fullTarget -Force -ErrorAction SilentlyContinue
    }
}

function global:Invoke-Doom2016VRInstaller {
    $work = $null
    $target = $null
    $snapshot = $null
    $changesStarted = $false
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  DOOM (2016) VR - Installer' -ForegroundColor Cyan
        Write-Host '  Installs: KHARVOX by CactusVRStudios' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  KHARVOX adds room-scale 6DoF, true stereo rendering' -ForegroundColor White
        Write-Host '  and tracked motion controls through OpenXR.' -ForegroundColor White
        Write-Host '  Before first VR launch, start original DOOM flat once and' -ForegroundColor Yellow
        Write-Host '  accept its license; otherwise loading a save can appear stuck.' -ForegroundColor Yellow
        Write-Host '  The VR runtime stays outside the original DOOM folder.' -ForegroundColor Gray
        Write-Host '  KHARVOX v1.0 supports the legal Steam version of DOOM.' -ForegroundColor Yellow
        Write-Host '  Start with the default SFS rendering mode.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to proceed with setup...')

        Write-DoomStep 1 5 'Locating DOOM (2016)'
        $game = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('DOOM') -ProbeExe 'DOOMx64.exe' `
            -HubGameId 'doom-2016-vr'
        if (-not (Test-DoomGameRoot $game)) {
            if ($game -and (Test-Path -LiteralPath (Join-Path $game 'DOOMx64.exe') -PathType Leaf)) {
                Write-DoomWarn 'DOOMx64vk.exe is missing. KHARVOX requires the Vulkan game executable.'
            }
            $game = Get-GameFolderInteractive -GameName 'DOOM (2016)' -ProbeFile 'DOOMx64vk.exe' `
                -ManualUrl 'https://store.steampowered.com/app/379720/'
        }
        if ($game -in @('quit','skip',$null) -or -not (Test-DoomGameRoot $game)) {
            throw 'Select a complete DOOM (2016) folder containing DOOMx64.exe and DOOMx64vk.exe.'
        }
        $game = (Get-Item -LiteralPath $game).FullName
        if (Get-Process -Name @('DOOMx64','DOOMx64vk') -ErrorAction SilentlyContinue) {
            throw 'DOOM is running. Close it completely and run setup again.'
        }
        Write-DoomOK "Found complete game: $game"

        Write-DoomStep 2 5 'Choosing the separate KHARVOX folder'
        $target = Get-DoomPortableTarget
        if (-not (Test-Path -LiteralPath $target -PathType Container)) { [void][IO.Directory]::CreateDirectory($target) }
        Write-DoomOK "VR folder: $target"
        Write-DoomInfo 'No KHARVOX file is copied into the original DOOM folder.'

        Write-DoomStep 3 5 'Getting the current GitHub release'
        $release = Resolve-GitHubReleaseAsset -Repo $REPO `
            -AssetPatterns @('(?i)^KHARVOX(?:[-_.].*)?\.zip$') `
            -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_NAME
        Write-DoomInfo "Release: $($release.Tag)"
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_kharvox_' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive = Join-Path $work 'KHARVOX-release.zip'
        $downloaded = Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive `
            -Label "KHARVOX $($release.Tag)" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if (-not ($downloaded -eq $true -or [string]$downloaded -in @('retry','manual'))) {
            throw 'The KHARVOX release was not downloaded.'
        }

        Write-DoomStep 4 5 'Installing the complete recoverable VR runtime'
        $extract = Join-Path $work 'release'
        $expanded = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract `
            -Label 'KHARVOX release' -AllowSkip $false
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The KHARVOX archive could not be extracted.' }
        $payload = Find-KharvoxPayload $extract
        if (-not $payload) { throw 'The downloaded package has no usable KHARVOX launcher and OpenXR layer.' }
        $snapshot = Save-DoomTargetSnapshot -Target $target -SnapshotRoot (Join-Path $work 'rollback')
        $changesStarted = $true
        Install-DoomKharvoxPayload -Payload $payload -Target $target
        $watch = @('KharvoxLauncher.exe','KharvoxLayer.dll','KharvoxLayer.json','openxr_loader.dll') |
            ForEach-Object { Join-Path $target $_ }
        $recopy = {
            [void](Restore-DoomKharvoxInsideTarget -ArchivePath $archive -Target $target)
        }.GetNewClosure()
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $target -Recopy $recopy)) {
            throw 'The required KHARVOX files did not survive the antivirus recovery check.'
        }
        Write-DoomOK 'Launcher, OpenXR layer and assets are installed.'

        Write-DoomStep 5 5 'Registering the launcher and first configuration'
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $target -Version ([string]$release.Tag) `
            -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route Current)
        $desktop = Get-DoomDesktopRoot
        if ($desktop) {
            [void](New-DesktopShortcut -LnkPath (Join-Path $desktop 'DOOM 2016 VR.lnk') `
                -TargetPath (Join-Path $target 'KharvoxLauncher.exe') -WorkingDir $target `
                -IconPath "$(Join-Path $target 'KharvoxLauncher.exe'),0" -Description 'Configure and launch DOOM (2016) through KHARVOX')
        }
        $changesStarted = $false
        Write-DoomOK "KHARVOX $($release.Tag) is installed and tracked."
        Write-Host ''
        Write-Host '  The KHARVOX launcher opens next only after your confirmation.' -ForegroundColor White
        Write-Host '  Confirm the detected Steam DOOM folder.' -ForegroundColor White
        Write-Host '  Start with SFS; use AER only as a fallback.' -ForegroundColor Yellow
        Write-Host '  Native Stereo was removed in KHARVOX v1.0.' -ForegroundColor Gray
        Write-Host '  With SteamVR active, set resolution in SteamVR itself.' -ForegroundColor Gray
        Write-Host '  Change graphics quality only from the main menu.' -ForegroundColor Gray
        Write-Host '  Keep all launcher files together in the VR folder.' -ForegroundColor Gray
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the KHARVOX configuration launcher...')
        Start-Process -FilePath (Join-Path $target 'KharvoxLauncher.exe') -WorkingDirectory $target -ErrorAction Stop | Out-Null
        Write-Host ''
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Setup complete.' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  KHARVOX is installed in its separate VR folder.' -ForegroundColor White
        Write-Host '  Your original Steam installation remains unchanged.' -ForegroundColor Gray
        Write-Host '  Finish any settings in the launcher, then return here.' -ForegroundColor Gray
        Write-Host ''
        Write-Host "  $QUIP" -ForegroundColor Magenta
        Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $target -and $snapshot) {
            try { Restore-DoomTargetSnapshot -Target $target -Snapshot $snapshot; Write-DoomWarn 'The previous VR-folder state was restored.' }
            catch { Write-DoomWarn "Automatic rollback needs review: $($_.Exception.Message)" }
        }
        Write-Host ''; Write-Host "  [XX] $($_.Exception.Message)" -ForegroundColor Red
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ($env:PCVR_DOOM2016_LIBRARY_ONLY -ne '1') { Invoke-Doom2016VRInstaller }
