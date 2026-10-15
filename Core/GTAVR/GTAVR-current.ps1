# Current GTA V Legacy VR setup by DeployAbi.
# The executable is acquired from the publisher's GitHub release and
# is never bundled with the Hub.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')

$Host.UI.RawUI.WindowTitle = 'Grand Theft Auto V VR Installer'
$APP_ID = '271590'
$GAME_EXE = 'GTA5.exe'
$PACKAGE_NAME = 'GTAVR-Setup-and-Play.exe'
$REPO = 'DeployAbi/GTAVR'
$RELEASES = "https://github.com/$REPO/releases"
$FALLBACK_TAG = 'v0.11.19-ffb-test'
$FALLBACK_URL = "$RELEASES/download/$FALLBACK_TAG/$PACKAGE_NAME"
$VERSION_PROOF = '.pcvrhub_deployabi_version'
$INFO_POST = 'https://discord.com/channels/747967102895390741/1545350924237668453'
$QUIP = 'Pull off the heist, outrun the stars, and own the streets of Los Santos.'
$CONTRACT = New-PCVRInstallerContract -Id 'gta-v-vr' -GameName 'GTAVR by DeployAbi' -Acquisition GitHub `
    -AntivirusNotice -ReleasePageUrl $RELEASES -RequiredInstalledFileGroups @(
        'GTA5.exe','gtavr_install_manifest.txt','version.dll','OVRInject.dll','GTAVRBridge.asi',
        'VRLaunch\DeployAbi\GTAVR-Setup-and-Play.exe')

function Write-Header {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ' Grand Theft Auto V VR - Installer' -ForegroundColor Cyan
    Write-Host ' Current GTA V Legacy - motion controls by DeployAbi' -ForegroundColor Gray
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ''
}
function Write-Step { param([int]$Number,[int]$Total,[string]$Text) Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-OK   { param([string]$Text) Write-Host " [OK] $Text" -ForegroundColor Green }
function Write-Info { param([string]$Text) Write-Host " [..] $Text" -ForegroundColor Gray }
function Write-Warn { param([string]$Text) Write-Host " [!!] $Text" -ForegroundColor Yellow }
function Pause-User { param([string]$Text='Press Enter to continue...') Write-Host ''; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host | Out-Null }

function Test-GtaRoot {
    param([string]$Path)
    if (-not $Path) { return $false }
    try {
        $exe = Join-Path $Path 'GTA5.exe'
        if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { return $false }
        $archive = @(
            (Join-Path $Path 'update\update.rpf'),
            (Join-Path $Path 'x64a.rpf')
        ) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
        if (-not $archive) { return $false }
        return (([int64](Get-Item -LiteralPath $exe -ErrorAction Stop).Length + [int64](Get-Item -LiteralPath $archive -ErrorAction Stop).Length) -ge 100MB)
    } catch { return $false }
}

function Assert-GtaTestFixture([string]$Path) {
    if ($env:PCVR_HUB_TEST_MODE -ne '1') { throw 'Fixture access is allowed only in test mode.' }
    $full = [IO.Path]::GetFullPath($Path)
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    $parent = Split-Path -Parent $full
    if (-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath (Join-Path $parent 'gtavr-fixture.txt') -PathType Leaf)) {
        throw 'GTAVR test paths must stay below an isolated temporary fixture.'
    }
    return $full
}

function Get-ArchiveInputFolders {
    try {
        $workspace = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        return @(
            (Join-Path $workspace 'Archive Input\Grand Theft Auto V VR'),
            (Join-Path $workspace 'Archive Input\Neue Spiele'),
            (Join-Path $workspace 'Archive Input')
        )
    } catch { return @() }
}

function Test-DeployAbiPackage([string]$Path) {
    if (-not (Test-DownloadedPayload -Path $Path -IntendedPath $PACKAGE_NAME)) { return $false }
    $stream = $null
    try {
        $stream = [IO.File]::OpenRead($Path)
        if ($stream.Length -lt 512) { return $false }
        $reader = New-Object IO.BinaryReader($stream)
        $stream.Position = 0x3c
        $peOffset = $reader.ReadInt32()
        if ($peOffset -lt 0x40 -or $peOffset -gt ($stream.Length - 4)) { return $false }
        $stream.Position = $peOffset
        return ($reader.ReadUInt32() -eq 0x00004550)
    } catch { return $false } finally { if ($stream) { $stream.Dispose() } }
}
function Get-DeployAbiFileTag([string]$Path) {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_GTAV_TEST_TAG) {
        if (-not (Test-IsTrackableInstalledVersion $env:PCVR_GTAV_TEST_TAG)) { throw 'The isolated test version is not trackable.' }
        return $env:PCVR_GTAV_TEST_TAG
    }
    $version = (Get-Item -LiteralPath $Path -ErrorAction Stop).VersionInfo.ProductVersion
    $tag = 'v' + ((''+$version).TrimStart('v','V'))
    if (-not (Test-IsTrackableInstalledVersion $tag)) { throw 'The fallback EXE does not expose a trackable publisher version.' }
    return $tag
}

function Find-GtaRoot {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_GTAV_TEST_GAME) {
        $testGame = Assert-GtaTestFixture $env:PCVR_GTAV_TEST_GAME
        if (-not (Test-GtaRoot $testGame)) { throw 'The isolated GTA fixture lacks base-game evidence.' }
        return $testGame
    }
    $found = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Grand Theft Auto V') `
        -EpicNames @('GTAV','Grand Theft Auto V') -ProbeExe $GAME_EXE
    if (Test-GtaRoot $found) { return $found }
    foreach ($candidate in @(
        'C:\Program Files\Rockstar Games\Grand Theft Auto V',
        'C:\Program Files (x86)\Rockstar Games\Grand Theft Auto V',
        'C:\Program Files\Epic Games\GTAV',
        'C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto V'
    )) {
        if (Test-GtaRoot $candidate) { return $candidate }
    }
    $manual = Get-GameFolderInteractive -GameName 'Grand Theft Auto V Legacy' -ProbeFile $GAME_EXE -ManualUrl $INFO_POST
    if ($manual -in @('quit','skip')) { return $null }
    if (Test-GtaRoot $manual) { return $manual }
    return $null
}

function Get-ReviewedLauncher([string]$Destination,[string]$SelectedFile='') {
    $script:DeployAbiInstalledTag = ''
    if ($SelectedFile) {
        $selected = ConvertTo-PCVRCanonicalUserPath $SelectedFile
        if (-not (Test-DeployAbiPackage $selected)) { throw 'The selected file is not a usable Windows Setup EXE.' }
        Copy-Item -LiteralPath $selected -Destination $Destination -Force -ErrorAction Stop
        if (-not (Test-DeployAbiPackage $Destination)) { throw 'The selected publisher Setup could not be staged.' }
        $script:DeployAbiInstalledTag = Get-DeployAbiFileTag $Destination
        return $Destination
    }
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_GTAV_TEST_DOWNLOAD_SOURCE) {
        if ($env:PCVR_GTAV_TEST_DOWNLOAD_SOURCE -eq 'FAIL') { return $null }
        $testSource = Assert-GtaTestFixture $env:PCVR_GTAV_TEST_DOWNLOAD_SOURCE
        return (Get-ReviewedLauncher -Destination $Destination -SelectedFile $testSource)
    }
    $release = Resolve-GitHubReleaseAsset -Repo $REPO -AssetPatterns @('(?i)^GTAVR-Setup-and-Play\.exe$') `
        -IncludePrerelease $true -SkipReleasesWithoutMatchingAsset -FallbackUrl $FALLBACK_URL `
        -FallbackTag $FALLBACK_TAG -FallbackAssetName $PACKAGE_NAME
    if (-not (Test-IsTrackableInstalledVersion ([string]$release.Tag))) { throw 'GitHub did not provide a trackable release.' }
    $download = Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $Destination -Label "GTAVR $($release.Tag)" `
        -ManualUrl $RELEASES -AllowSkip $true
    if ($download -eq $true -or [string]$download -in @('retry','manual')) {
        if (-not (Test-DeployAbiPackage $Destination)) { throw 'The GitHub download is not a usable Windows Setup EXE.' }
        $script:DeployAbiInstalledTag = [string]$release.Tag
        return $Destination
    }
    return $null
}

function Copy-VerifiedFile([string]$Source,[string]$Destination) {
    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void][IO.Directory]::CreateDirectory($parent) }
    if ((Test-Path -LiteralPath $Destination -PathType Leaf) -and -not (Test-DeployAbiPackage $Destination)) {
        $backup = "$Destination.user-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Move-Item -LiteralPath $Destination -Destination $backup -Force -ErrorAction Stop
        Write-Warn "Preserved a different existing launcher as: $backup"
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force -ErrorAction Stop
    if (-not (Test-DeployAbiPackage $Destination)) { throw 'The stable launcher copy failed verification.' }
}

function Install-HubLaunchFiles([string]$GameRoot,[string]$ReviewedExe) {
    $launchRoot = Join-Path $GameRoot 'VRLaunch'
    $deployRoot = Join-Path $launchRoot 'DeployAbi'
    [void][IO.Directory]::CreateDirectory($deployRoot)
    $launcher = Join-Path $deployRoot $PACKAGE_NAME
    Copy-VerifiedFile -Source $ReviewedExe -Destination $launcher

    $switchSource = Join-Path $PSScriptRoot 'GTAVR-Switch.ps1'
    $switchDest = Join-Path $launchRoot 'SetVRMode.ps1'
    Copy-Item -LiteralPath $switchSource -Destination $switchDest -Force -ErrorAction Stop
    $currentBat = Join-Path $launchRoot 'GTA5 VR (DeployAbi).bat'
    $batText = '@echo off' + "`r`n" + 'powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SetVRMode.ps1" -Mode deployabi' + "`r`n"
    Set-Content -LiteralPath $currentBat -Value $batText -Encoding ASCII -Force -NoNewline
    return [pscustomobject]@{ Launcher=$launcher; Batch=$currentBat; Switch=$switchDest }
}

Write-Header
Write-Host ' This is the recommended setup for the current GTA V Legacy build.' -ForegroundColor White
Write-Host ' It supports 6DOF head tracking, motion controllers, Virtual Desktop' -ForegroundColor White
Write-Host ' and a configurable in-headset overlay.' -ForegroundColor White
Write-Host ''
Write-Host ' IMPORTANT:' -ForegroundColor Yellow
Write-Host '  - GTA V Legacy Story Mode only; never use the mod in GTA Online.' -ForegroundColor Yellow
Write-Host '  - In Rockstar Games Launcher > Settings > General, set BattlEye OFF' -ForegroundColor Yellow
Write-Host '    before Story Mode modding. You do not need to install BattlEye.' -ForegroundColor Yellow
Write-Host '  - On a first install, start unmodded Story Mode once without VR,' -ForegroundColor White
Write-Host '    reach the world, then close GTA before installing the mod.' -ForegroundColor White
Write-Host '  - The author launcher is unsigned. Antivirus software may flag it.' -ForegroundColor Yellow
Write-Host '  - Publisher Setup needs administrator approval (UAC) to write' -ForegroundColor Yellow
Write-Host '    protected game folders. Windows will ask before it opens.' -ForegroundColor Yellow
Write-Host '  - The author app stores its own settings and logs in' -ForegroundColor Gray
Write-Host '    %LOCALAPPDATA%\GTAVR. The portable Hub itself remains unchanged.' -ForegroundColor Gray
Show-AntivirusNotice
Pause-User 'Press Enter to continue...'
$battleEyeAnswer = ('' + (Read-Host 'Confirm BattlEye is OFF in Rockstar Games Launcher: type OFF (or Q to quit)')).Trim().ToUpperInvariant()
if ($battleEyeAnswer -eq 'Q') { return }
if ($battleEyeAnswer -ne 'OFF') { throw 'BattlEye must be OFF in Rockstar Games Launcher before installing GTAVR for Story Mode.' }

Write-Step 1 5 'Locating GTA V Legacy'
$gtaDir = Find-GtaRoot
if (-not $gtaDir) { throw 'No GTA V Legacy folder was selected. Nothing was installed.' }
$gtaExe = Join-Path $gtaDir $GAME_EXE
Write-OK "Game folder: $gtaDir"
$gameVersion = ''
try { $gameVersion = (Get-Item -LiteralPath $gtaExe -ErrorAction Stop).VersionInfo.FileVersion } catch {}
if ($gameVersion) { Write-Info "Detected GTA5.exe version: $gameVersion" }
Write-Host ' The author launcher performs the authoritative build check and refuses' -ForegroundColor Gray
Write-Host ' to activate on an unsupported executable.' -ForegroundColor Gray
if (Get-Process -Name 'GTA5','GTA5_BE' -ErrorAction SilentlyContinue) { throw 'Close GTA V before installing or switching VR mods.' }

Write-Step 2 5 'Getting the GitHub release'
$workRoot = Join-Path ([IO.Path]::GetTempPath()) ('PCVRHub_GTAVR_' + [Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($workRoot)
try {
    $reviewed = $null
    $handover = Get-PCVRRecoveryInput -PathType Leaf
    if ($handover) { [void](Set-PCVRRecoveryInput '') }
    while (-not $reviewed) {
        Write-Host '  [Enter] Download the latest official GitHub prerelease' -ForegroundColor White
        Write-Host '  [L] Choose an already downloaded publisher Setup EXE' -ForegroundColor White
        Write-Host '  [O] Open the official GitHub releases page' -ForegroundColor White
        Write-Host '  [Q] Cancel setup' -ForegroundColor White
        $choice = if ($handover) { 'L' } else { ('' + (Read-Host 'Choose Enter, L, O or Q')).Trim().ToUpperInvariant() }
        switch ($choice) {
            '' {
                Write-Info 'Checking the official GitHub release; this may take a little time.'
                try { $reviewed = Get-ReviewedLauncher -Destination (Join-Path $workRoot $PACKAGE_NAME) }
                catch { Write-Warn ('GitHub did not provide a usable Setup: ' + $_.Exception.Message) }
            }
            'L' {
                $path = if ($handover) { $handover } else { Read-Host 'Drag the downloaded EXE here or paste its full path (Q to cancel)' }
                $handover = $null
                if ((''+$path).Trim().ToUpperInvariant() -eq 'Q') { throw 'GTAVR Setup was cancelled before any game files were changed.' }
                try { $reviewed = Get-ReviewedLauncher -Destination (Join-Path $workRoot $PACKAGE_NAME) -SelectedFile $path }
                catch { Write-Warn ('Selected file was not accepted: ' + $_.Exception.Message) }
            }
            'O' {
                [void](Open-PCVRPageAfterEnter -Message 'Press Enter to open the official GTAVR GitHub releases page...' -Url $RELEASES)
            }
            'Q' { throw 'GTAVR Setup was cancelled before any game files were changed.' }
            default { Write-Warn 'Choose Enter, L, O or Q.' }
        }
    }
    if (-not $reviewed -or -not (Test-DeployAbiPackage $reviewed)) { throw 'A usable GTAVR launcher was not supplied.' }
    Write-OK "Publisher launcher $script:DeployAbiInstalledTag is ready."
    if ($script:DeployAbiInstalledTag -eq 'v0.11.19-ffb-test' -and $gameVersion -ne '1.0.3889.0') {
        Write-Warn 'This test release documents GTA V Legacy 1.0.3889.0. Your game build may not be supported; check the release notes.'
    }

    Write-Step 3 5 'Checking installed VR setups'
    $legacyPresent = (Test-Path -LiteralPath (Join-Path $gtaDir 'RealVR.asi') -PathType Leaf) -or `
                     (Test-Path -LiteralPath (Join-Path $gtaDir 'RealVR.asi.off') -PathType Leaf)
    if ($legacyPresent) {
        Write-OK 'Existing R.E.A.L. setup detected and preserved for switching.'
        Write-Info 'Its active hooks are parked only while DeployAbi is selected.'
    }
    Write-Info 'Installation leaves the active VR mode unchanged; Hub Play handles switching.'

    Write-Step 4 5 'Running GTAVR Setup and Play'
    Write-Host ' In the author window:' -ForegroundColor White
    Write-Host '  1. Confirm the detected GTA V Legacy folder.' -ForegroundColor Gray
    Write-Host '  2. Click Install / Update Everything.' -ForegroundColor Gray
    Write-Host '  3. Use Verify if offered, then close the author window to return.' -ForegroundColor Gray
    Write-Host '  4. Play later through the Hub button; it reopens this same launcher.' -ForegroundColor Gray
    Write-Host '  Windows may request administrator approval (UAC) for publisher Setup.' -ForegroundColor Yellow
    Write-Host ''
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Setup...')
    $oldInstallDir = $env:GTAV_INSTALL_DIR
    $oldExePath = $env:GTAV_EXE_PATH
    try {
        $env:GTAV_INSTALL_DIR = $gtaDir
        $env:GTAV_EXE_PATH = $gtaExe
        if ($env:PCVR_HUB_TEST_MODE -eq '1') {
            [void](Assert-GtaTestFixture $gtaDir)
            if ($env:PCVR_GTAV_TEST_PUBLISHER_FAIL -eq '1') { throw 'Isolated publisher Setup failure.' }
            foreach ($name in @('gtavr_install_manifest.txt','version.dll','OVRInject.dll','GTAVRBridge.asi')) {
                [IO.File]::WriteAllText((Join-Path $gtaDir $name),'isolated publisher fixture')
            }
        } else {
            $proc = Start-Process -FilePath $reviewed -WorkingDirectory (Split-Path -Parent $reviewed) -Verb RunAs -PassThru -ErrorAction Stop
            $proc.WaitForExit()
        }
    } finally {
        if ($null -eq $oldInstallDir) { Remove-Item Env:GTAV_INSTALL_DIR -ErrorAction SilentlyContinue } else { $env:GTAV_INSTALL_DIR = $oldInstallDir }
        if ($null -eq $oldExePath) { Remove-Item Env:GTAV_EXE_PATH -ErrorAction SilentlyContinue } else { $env:GTAV_EXE_PATH = $oldExePath }
    }

    Write-Step 5 5 'Verifying and recording the selected setup'
    $required = @('gtavr_install_manifest.txt','version.dll','OVRInject.dll','GTAVRBridge.asi')
    $missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $gtaDir $_) -PathType Leaf) })
    if ($missing.Count) {
        throw ('The author setup was closed before a complete GTAVR install was verified. Missing: ' + ($missing -join ', ') + '. Re-run this option and click Install / Update Everything.')
    }
    if (-not (Confirm-PlacedFilesSurvive -Paths @($required | ForEach-Object { Join-Path $gtaDir $_ }) -GameDir $gtaDir)) {
        throw 'Required GTAVR files are missing after installation. Check the log, target path, permissions and protection history, then retry.'
    }
    $launch = Install-HubLaunchFiles -GameRoot $gtaDir -ReviewedExe $reviewed
    Set-Content -LiteralPath (Join-Path $PSScriptRoot '.launch_exe') -Value $launch.Batch -Encoding UTF8 -Force
    [void](Complete-PCVRInstallTransaction -Contract $CONTRACT -GameDir $gtaDir -Version $script:DeployAbiInstalledTag `
        -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path'),(Join-Path $PSScriptRoot '.deployabi_path')) `
        -AdditionalVersionReceiptPaths @((Join-Path $gtaDir $VERSION_PROOF)) -VersionSlot Secondary -Route Current)

    $desktop = [Environment]::GetFolderPath('Desktop')
    if ($desktop -and $env:PCVR_HUB_TEST_MODE -ne '1') {
        try {
            $icon = if (Test-Path -LiteralPath $gtaExe -PathType Leaf) { $gtaExe } else { $launch.Launcher }
            [void](New-DesktopShortcut -LnkPath (Join-Path $desktop 'Grand Theft Auto V VR - DeployAbi.lnk') `
                -TargetPath $launch.Batch -WorkingDir $gtaDir -IconPath $icon)
            Write-OK 'Desktop shortcut created: Grand Theft Auto V VR - DeployAbi'
        } catch { Write-Warn 'Could not create the optional desktop shortcut; the Hub launch button is ready.' }
    }
    Write-OK 'Current GTAVR is installed and recorded as VR Ready.'
    Write-Host ''
    Write-Host ' HOW TO PLAY' -ForegroundColor Yellow
    Write-Host '  Use Play GTAVR Motion on this game page. The Hub parks R.E.A.L.,' -ForegroundColor White
    Write-Host '  enables DeployAbi, and opens GTAVR Setup and Play.' -ForegroundColor White
    Write-Host '  Click Play Story Mode there. Press Delete in VR for its overlay.' -ForegroundColor White
    Write-Host '  A flat theater view may remain for about one minute after the' -ForegroundColor White
    Write-Host '  Story Mode world loads before VR engages. If it stays, see the' -ForegroundColor White
    Write-Host '  README and %LOCALAPPDATA%\GTAVR\launcher.log.' -ForegroundColor White
    Write-Host ''
    Write-Host " $QUIP" -ForegroundColor Magenta
    Write-Host ''
    Pause-User 'Press Enter to exit'
} finally {
    if ((Test-Path -LiteralPath $workRoot -PathType Container) -and ([IO.Path]::GetFullPath($workRoot)).StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
