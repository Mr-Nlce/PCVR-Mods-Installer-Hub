# Current GTA V Legacy VR setup by DeployAbi.
# The executable is acquired from its authenticated Discord post and
# is never bundled with the Hub.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')

$Host.UI.RawUI.WindowTitle = 'Grand Theft Auto V VR Installer'
$APP_ID = '271590'
$GAME_EXE = 'GTA5.exe'
$PACKAGE_NAME = 'GTAVR-Setup-and-Play.exe'
$REVIEWED_RELEASE = 'discord-2026-09-09-1547246592376053770'
$RELEASE_PROOF = '.pcvrhub_release_deployabi_20260909_1547246592376053770'
$DISCORD_INVITE = 'https://discord.gg/uAeQkYBM4n'
$INFO_POST = 'https://discord.com/channels/747967102895390741/1545350924237668453'
$DOWNLOAD_POST = 'https://discord.com/channels/747967102895390741/1545350924237668453/1547246592376053770'
$QUIP = 'Pull off the heist, outrun the stars, and own the streets of Los Santos.'

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
    return (Test-DownloadedPayload -Path $Path -IntendedPath $PACKAGE_NAME)
}

function Find-GtaRoot {
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

function Get-ReviewedLauncher([string]$Destination) {
    $found = Find-PredownloadedFile -Patterns @($PACKAGE_NAME) `
        -ExtraFolders (Get-ArchiveInputFolders) `
        -Label 'GTAVR Setup and Play by DeployAbi'
    if ($found -and (Test-DeployAbiPackage $found)) {
        Copy-Item -LiteralPath $found -Destination $Destination -Force -ErrorAction Stop
        return $Destination
    }

    Write-Host ' The current mod is attached to an authenticated Flat2VR Discord post.' -ForegroundColor White
    Write-Host ' At each step, press Enter; the installer opens the exact page.' -ForegroundColor Gray
    Write-Host ''
    Write-Host ' [1/3] Join the Flat2VR Modding Discord.' -ForegroundColor Cyan
    Write-Host "       $DISCORD_INVITE" -ForegroundColor DarkGray
    Pause-User 'Press Enter to open the server invite...'
    try { Start-Process $DISCORD_INVITE } catch { Write-Warn "Open manually: $DISCORD_INVITE" }
    Write-Host ''
    Write-Host ' [2/3] Open the game thread and read the current notes.' -ForegroundColor Cyan
    Write-Host "       $INFO_POST" -ForegroundColor DarkGray
    Pause-User 'Press Enter to open the GTA V VR information thread...'
    try { Start-Process $INFO_POST } catch { Write-Warn "Open manually: $INFO_POST" }
    Write-Host ''
    Write-Host ' [3/3] Download GTAVR-Setup-and-Play.exe from the exact post.' -ForegroundColor Cyan
    Write-Host "       $DOWNLOAD_POST" -ForegroundColor DarkGray
    Pause-User 'Press Enter to open the official download post...'
    try { Start-Process $DOWNLOAD_POST } catch { Write-Warn "Open manually: $DOWNLOAD_POST" }
    Pause-User 'Wait for the download to finish, then press Enter so the Hub can find it...'

    $found = Find-PredownloadedFile -Patterns @($PACKAGE_NAME) `
        -ExtraFolders (Get-ArchiveInputFolders) `
        -Label 'GTAVR Setup and Play by DeployAbi'
    if ($found -and (Test-DeployAbiPackage $found)) {
        Copy-Item -LiteralPath $found -Destination $Destination -Force -ErrorAction Stop
        return $Destination
    }

    $validator = { param([string]$Candidate) Test-DeployAbiPackage $Candidate }.GetNewClosure()
    $retry = { Test-DeployAbiPackage $Destination }.GetNewClosure()
    $result = Invoke-InstallerFallback -Action 'GTAVR Discord download' -Subject $PACKAGE_NAME `
        -Url $DOWNLOAD_POST -DestFile $Destination -FileValidator $validator -RetryCheck $retry `
        -Instructions 'Download GTAVR-Setup-and-Play.exe from the linked Discord post, then drag that EXE into this window.' `
        -SkipMessage 'The current-build launcher is required.' -AllowSkip $false
    if ([string]$result -eq 'retry' -and (Test-DeployAbiPackage $Destination)) { return $Destination }
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

function Park-LegacyHooks([string]$GameRoot) {
    foreach ($name in @('RealVR.asi','GTAVR.asi')) {
        $active = Join-Path $GameRoot $name
        $parked = "$active.off"
        if (Test-Path -LiteralPath $active -PathType Leaf) {
            Move-Item -LiteralPath $active -Destination $parked -Force -ErrorAction Stop
            Write-Info "Parked the inactive legacy hook: $name"
        }
    }
    $disabled = Join-Path $GameRoot 'gtavr.disabled'
    if (Test-Path -LiteralPath $disabled -PathType Leaf) { Remove-Item -LiteralPath $disabled -Force -ErrorAction Stop }
}

Write-Header
Write-Host ' This is the recommended setup for the current GTA V Legacy build.' -ForegroundColor White
Write-Host ' It supports 6DOF head tracking, motion controllers, Virtual Desktop' -ForegroundColor White
Write-Host ' and a configurable in-headset overlay.' -ForegroundColor White
Write-Host ''
Write-Host ' IMPORTANT:' -ForegroundColor Yellow
Write-Host '  - GTA V Legacy Story Mode only; never use the mod in GTA Online.' -ForegroundColor Yellow
Write-Host '  - The author launcher is unsigned. Antivirus software may flag it.' -ForegroundColor Yellow
Write-Host '  - Run it as your normal Windows user, NOT as administrator.' -ForegroundColor Yellow
Write-Host '  - The author app stores its own settings and logs in' -ForegroundColor Gray
Write-Host '    %LOCALAPPDATA%\GTAVR. The portable Hub itself remains unchanged.' -ForegroundColor Gray
Show-AntivirusNotice
Pause-User 'Press Enter to continue...'

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

Write-Step 2 5 'Getting the Discord release'
$workRoot = Join-Path ([IO.Path]::GetTempPath()) ('PCVRHub_GTAVR_' + [Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($workRoot)
try {
    $reviewed = Get-ReviewedLauncher -Destination (Join-Path $workRoot $PACKAGE_NAME)
    if (-not $reviewed -or -not (Test-DeployAbiPackage $reviewed)) { throw 'A usable GTAVR launcher was not supplied.' }
    Write-OK 'The Discord launcher is ready.'

    Write-Step 3 5 'Preparing safe Hub launch and switching'
    $launch = Install-HubLaunchFiles -GameRoot $gtaDir -ReviewedExe $reviewed
    $legacyPresent = (Test-Path -LiteralPath (Join-Path $gtaDir 'RealVR.asi') -PathType Leaf) -or `
                     (Test-Path -LiteralPath (Join-Path $gtaDir 'RealVR.asi.off') -PathType Leaf)
    if ($legacyPresent) {
        Write-OK 'Existing R.E.A.L. setup detected and preserved for switching.'
        Write-Info 'Its active hooks are parked only while DeployAbi is selected.'
    }
    Park-LegacyHooks -GameRoot $gtaDir

    Write-Step 4 5 'Running GTAVR Setup and Play'
    Write-Host ' In the author window:' -ForegroundColor White
    Write-Host '  1. Confirm the detected GTA V Legacy folder.' -ForegroundColor Gray
    Write-Host '  2. Click Install / Update Everything.' -ForegroundColor Gray
    Write-Host '  3. Use Verify if offered, then close the author window to return.' -ForegroundColor Gray
    Write-Host '  4. Play later through the Hub button; it reopens this same launcher.' -ForegroundColor Gray
    Write-Host ''
    $oldInstallDir = $env:GTAV_INSTALL_DIR
    $oldExePath = $env:GTAV_EXE_PATH
    try {
        $env:GTAV_INSTALL_DIR = $gtaDir
        $env:GTAV_EXE_PATH = $gtaExe
        $proc = Start-Process -FilePath $launch.Launcher -WorkingDirectory (Split-Path -Parent $launch.Launcher) -PassThru -ErrorAction Stop
        $proc.WaitForExit()
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
        throw 'One or more GTAVR files disappeared after installation. Check antivirus history, then retry.'
    }
    Set-Content -LiteralPath (Join-Path $gtaDir $RELEASE_PROOF) -Value $REVIEWED_RELEASE -Encoding ASCII -Force
    Set-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Value $gtaDir -Encoding UTF8 -Force
    Set-Content -LiteralPath (Join-Path $PSScriptRoot '.deployabi_path') -Value $gtaDir -Encoding UTF8 -Force
    Set-Content -LiteralPath (Join-Path $PSScriptRoot '.launch_exe') -Value $launch.Batch -Encoding UTF8 -Force

    $desktop = [Environment]::GetFolderPath('Desktop')
    if ($desktop) {
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
    Write-Host ''
    Write-Host " $QUIP" -ForegroundColor Magenta
    Write-Host ''
    Pause-User 'Press Enter to exit'
} finally {
    if ((Test-Path -LiteralPath $workRoot -PathType Container) -and ([IO.Path]::GetFullPath($workRoot)).StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
