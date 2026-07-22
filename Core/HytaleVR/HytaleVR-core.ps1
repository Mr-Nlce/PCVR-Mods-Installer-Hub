# ============================================================
# Hytale VR Installer (HytaleVRInjector-mod by heurazy)
# ============================================================
# Windows x64 VR injector/dashboard for Hytale (v1.0+).
# This installer downloads the latest windows-x64 release ZIP
# from GitHub and unpacks it to C:\Games\Hytale VR (or a folder
# you pick). The Hytale game itself stays where its own launcher
# put it (%APPDATA%\Hytale\...) - only the injector lives here.
#
# You must own Hytale and have it installed through the official
# Hytale Launcher - nothing from the game is downloaded here.
#
# Install layout:
#   <install_root>\Hytale VR\hytale_camera_dashboard.exe
#   <install_root>\Hytale VR\openvr_api.dll (+ hooks, manifests, assets)
#   <install_root>\Hytale VR\Start Hytale VR.bat  (game + dashboard combo)
#   default install_root: C:\Games (fallback D:\Games, E:\Games)
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Hytale VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Hytale VR Installer" -ForegroundColor Cyan
    Write-Host " HytaleVRInjector-mod by heurazy | Hytale (own copy) required" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR        = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO_API_LATEST   = "https://api.github.com/repos/heurazy/HytaleVRInjector-mod/releases/latest"
$RELEASES_LATEST   = "https://github.com/heurazy/HytaleVRInjector-mod/releases/latest"
$INFO_URL          = "https://github.com/heurazy/HytaleVRInjector-mod"
# Last-known-good windows-x64 asset, used only if the GitHub API cannot be reached.
$KNOWN_FALLBACK_ZIP = "https://github.com/heurazy/HytaleVRInjector-mod/releases/download/v1.0.0/HytaleVRInjector-mod-v1.0.0-windows-x64.zip"
$GAME_FOLDER       = "Hytale VR"
$DASH_EXE          = "hytale_camera_dashboard.exe"
$COMBO_BAT         = "Start Hytale VR.bat"
$ICON_FILE         = "Hytale_VR.ico"
$DEFAULT_ROOTS     = @("C:\Games", "D:\Games", "E:\Games")
# Hytale's own launcher-managed install (game itself - NOT touched here).
$HYTALE_CLIENT_REL = "Hytale\install\release\package\game\latest\Client\HytaleClient.exe"

# Resolve the newest windows-x64 *.zip asset via the GitHub API. Returns the
# browser_download_url, or $null on any failure (rate limit / offline / shape
# change). NOTE: never hardcode a literal asset URL as the primary source -
# runtime API resolution keeps the installer on the newest build.
$script:LatestTag = $null
function Get-LatestWinZipUrl {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rel = Invoke-RestMethod -Uri $REPO_API_LATEST -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        $asset = $rel.assets | Where-Object { $_.name -match '(?i)windows.*x64.*\.zip$' } | Select-Object -First 1
        if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -match '(?i)\.zip$' } | Select-Object -First 1 }
        if ($asset -and $asset.browser_download_url) {
            # Remember the tag so the version marker below is written
            # deterministically (previously we relied on the Hub scan
            # seeding it from the latest tag - timing-dependent).
            $script:LatestTag = [string]$rel.tag_name
            return [string]$asset.browser_download_url
        }
    } catch { }
    return $null
}

Write-Header

Write-Host "  Hytale VR is a VR injector for Hytale by heurazy (version 1.0)." -ForegroundColor Gray
Write-Host "  It renders the game to your headset through SteamVR, with native" -ForegroundColor Gray
Write-Host "  motion-controlled hands, via an external camera dashboard." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU MUST OWN AND INSTALL HYTALE YOURSELF:" -ForegroundColor White
Write-Host "    Get the game through the official Hytale Launcher (hytale.com)." -ForegroundColor Yellow
Write-Host "    This installer only fetches the injector - nothing from the game." -ForegroundColor Gray
Write-Host ""
Write-Host "  NOTE: close Hytale before installing or updating - a hook DLL" -ForegroundColor Yellow
Write-Host "  that is already injected cannot be replaced while the game runs." -ForegroundColor Yellow
Write-Host "  The view is centered manually per session (see the final steps)." -ForegroundColor Gray
Pause-User "Press Enter to begin the installation or update..." | Out-Null

# ---- 0. sanity check: is Hytale itself installed? ------------
# Non-blocking: the injector installs fine without the game; we just
# tell the user what is missing so first launch is not a mystery.
$hytaleClient = Join-Path ([Environment]::GetFolderPath("ApplicationData")) $HYTALE_CLIENT_REL
if (Test-Path -LiteralPath $hytaleClient) {
    Write-OK "Hytale found: $hytaleClient"
} else {
    Write-Warn "Hytale was not found at the default launcher location:"
    Write-Host "    $hytaleClient" -ForegroundColor Gray
    Write-Host "  That is fine if you installed it elsewhere - otherwise install" -ForegroundColor Gray
    Write-Host "  Hytale via the official Hytale Launcher before playing." -ForegroundColor Gray
}

# ---- 1. pick a writable install root ------------------------
Write-Step 1 4 "Choosing an install or update location"

function Test-WritableRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path $Root)) {
            New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null
        }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

Write-Host "  Default location: C:\Games\$GAME_FOLDER  (recommended)" -ForegroundColor White
Write-Host "  Installing under C:\Games avoids UAC / Program Files permission" -ForegroundColor Gray
Write-Host "  weirdness - the injector writes next to its own files at runtime." -ForegroundColor Gray
Write-Host "  Press Enter to accept it, or type a different folder to install into." -ForegroundColor Gray
$chosen = (Read-Host "  Install root [C:\Games]").Trim().Trim('"')

$installRoot = $null
if ($chosen) {
    if (Test-WritableRoot -Root $chosen) { $installRoot = [string]$chosen }
    else { Write-Fail "Not writable: $chosen - falling back to the defaults." }
}
if (-not $installRoot) {
    foreach ($r in $DEFAULT_ROOTS) {
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r; break }
    }
}
if (-not $installRoot) {
    Write-Warn "None of C:\Games, D:\Games, E:\Games is writable."
    Write-Host "  Enter a folder where the mod should be installed." -ForegroundColor White
    while (-not $installRoot) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
Write-OK "Install root: $installRoot"
$gameRoot = Join-Path $installRoot $GAME_FOLDER

# ---- 2. download the latest windows-x64 release --------------
$InstallMode = Read-UpdateOrInstall -GameFolder $gameRoot -ModFile $DASH_EXE
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the mod files." }

$null = Show-UpdateNoticeIfInstalled -TargetDir $installRoot -RelModFile $DASH_EXE -Label "Hytale VR"
Write-Step 2 4 "Downloading Hytale VR (latest windows-x64 release)"

$tmp = Join-Path $installRoot "_hytalevr_extract_tmp"
try {
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Fail "Could not create a temp folder under $installRoot : $_"
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
$zipDest = Join-Path $tmp "HytaleVR_latest.zip"

$urls = New-Object System.Collections.Generic.List[string]
Write-Info "Resolving the newest release via the GitHub API..."
$apiUrl = Get-LatestWinZipUrl
if ($apiUrl) {
    Write-OK "Latest windows-x64 asset: $apiUrl"
    [void]$urls.Add($apiUrl)
} else {
    Write-Warn "GitHub API not reachable (rate limit / offline). Using last-known URL."
}
if ([string]$apiUrl -ne [string]$KNOWN_FALLBACK_ZIP) { [void]$urls.Add($KNOWN_FALLBACK_ZIP) }

Invoke-SafeDownload -Urls $urls -Destination $zipDest `
    -Label "Hytale VR (windows-x64 build)" `
    -ManualUrl $RELEASES_LATEST `
    -Instructions "Open the releases page, download the newest 'HytaleVRInjector-mod-*-windows-x64.zip', save it as '$zipDest', then choose Retry." `
    -SkipMessage "" | Out-Null

while (-not (Test-Path $zipDest)) {
    Write-Fail "The Hytale VR download is not present at: $zipDest"
    $fb = Invoke-InstallerFallback -Action "download Hytale VR" `
        -Subject "the latest windows-x64 release" `
        -Url $RELEASES_LATEST `
        -Instructions "Download the newest 'HytaleVRInjector-mod-*-windows-x64.zip' from the releases page, save it as '$zipDest', then choose Retry. You can also paste the full path to an already-downloaded ZIP." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
    Write-Host "  If you already have the ZIP, paste its full path (or Enter to recheck '$zipDest')." -ForegroundColor White
    $alt = (Read-Host "  ZIP path").Trim().Trim('"')
    if ($alt -and (Test-Path -LiteralPath $alt) -and ($alt -match '\.zip$')) { $zipDest = [string]$alt }
}
Write-OK "Hytale VR archive ready: $zipDest"

# ---- 3. extract + place into the mod folder ------------------
Write-Step 3 4 "Installing Hytale VR"

$unpack = Join-Path $tmp "unpack"
$extractOk = $false
while (-not $extractOk) {
    try {
        if (Test-Path $unpack) { Remove-Item $unpack -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $unpack -Force -ErrorAction Stop | Out-Null
        Expand-Archive -LiteralPath $zipDest -DestinationPath $unpack -Force -ErrorAction Stop
        $extractOk = $true
    } catch {
        Write-Fail "Could not extract the ZIP: $_"
        $fb = Invoke-InstallerFallback -Action "extract the Hytale VR ZIP" `
            -Subject "the downloaded windows-x64 ZIP" `
            -Url $RELEASES_LATEST `
            -Instructions "The ZIP may be incomplete. Re-download the newest 'HytaleVRInjector-mod-*-windows-x64.zip', save it as '$zipDest', then choose Retry. Or paste the path to a fresh ZIP." `
            -AllowSkip $false
        if ([string]$fb -eq "quit") {
            try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        $again = (Read-Host "  ZIP path (Enter to retry same)").Trim().Trim('"')
        if ($again -and (Test-Path -LiteralPath $again) -and ($again -match '\.zip$')) { $zipDest = [string]$again }
    }
}

# The release ZIP may ship flat or wrapped in a folder. Find the dashboard
# exe anywhere in the tree and treat its folder as the real payload root.
$exeItem = Get-ChildItem -Path $unpack -Filter $DASH_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
while (-not $exeItem) {
    Write-Fail "'$DASH_EXE' not found in the extracted files."
    $fb = Invoke-InstallerFallback -Action "find $DASH_EXE in the download" `
        -Subject "the Hytale VR download" `
        -Url $RELEASES_LATEST `
        -Instructions "The ZIP did not contain $DASH_EXE - it may be the wrong file. Grab the newest 'HytaleVRInjector-mod-*-windows-x64.zip' from the releases page, save it as '$zipDest', then choose Retry." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
    $again = (Read-Host "  ZIP path (Enter to retry same)").Trim().Trim('"')
    if ($again -and (Test-Path -LiteralPath $again) -and ($again -match '\.zip$')) {
        $zipDest = [string]$again
        try {
            if (Test-Path $unpack) { Remove-Item $unpack -Recurse -Force -ErrorAction SilentlyContinue }
            New-Item -ItemType Directory -Path $unpack -Force -ErrorAction Stop | Out-Null
            Expand-Archive -LiteralPath $zipDest -DestinationPath $unpack -Force -ErrorAction Stop
        } catch { Write-Fail "Re-extract failed: $_" }
    }
    $exeItem = Get-ChildItem -Path $unpack -Filter $DASH_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
$payloadDir = Split-Path -Parent $exeItem.FullName

$placedOk = $false
while (-not $placedOk) {
    try {
        if (Test-Path $gameRoot) { Remove-Item $gameRoot -Recurse -Force -ErrorAction Stop }
        New-Item -ItemType Directory -Path $gameRoot -Force -ErrorAction Stop | Out-Null
        $null = Get-ChildItem -Path $payloadDir -Force | ForEach-Object {
            Move-Item -LiteralPath $_.FullName -Destination $gameRoot -Force -ErrorAction Stop
        }
        $placedOk = $true
    } catch {
        Write-Fail "Could not place the mod files: $_"
        $fb = Invoke-InstallerFallback -Action "copy the Hytale VR files into place" `
            -Instructions "Copy the CONTENTS of '$payloadDir' into '$gameRoot' (so that $DASH_EXE sits at its root). Then choose Retry, or Skip to finish manually." `
            -SourceFolder "$payloadDir" `
            -DestFolder "$gameRoot" `
            -AllowSkip $true
        if ([string]$fb -eq "quit") {
            try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        if ([string]$fb -eq "skip") { break }
    }
}
Write-OK "Mod installed at: $gameRoot"

# ---- 4. combo launcher + desktop shortcut + finish -----------
Write-Step 4 4 "Creating the launcher and desktop shortcut"

# The combo .bat starts the Hytale Launcher (which patches and boots the
# game) AND the camera dashboard together, so everything needed for a
# headset session is one double-click away. The launcher exe lives in a
# VERSIONED folder under %APPDATA%\Hytale\...\launcher\, so it is resolved
# at run time, newest folder first. Fallbacks, in order:
#   1) newest %APPDATA%\Hytale\install\release\package\launcher\*\hytale-launcher.exe
#   2) the game client exe directly (skips the launcher)
#   3) dashboard only, with a note telling the user to start Hytale themselves
$batPath = Join-Path $gameRoot $COMBO_BAT
$batLines = @(
    '@echo off'
    'cd /d "%~dp0"'
    'setlocal enabledelayedexpansion'
    'rem ---- locate the Hytale Launcher (real install path first) ----'
    'set "HYLAUNCH="'
    'set "HYPROG=%LOCALAPPDATA%\Programs\Hypixel Studios\Hytale Launcher\hytale-launcher.exe"'
    'if exist "%HYPROG%" set "HYLAUNCH=%HYPROG%"'
    'if not defined HYLAUNCH ('
    '  rem fallback: older layouts kept the launcher in a versioned folder under %APPDATA%'
    '  set "HYBASE=%APPDATA%\Hytale\install\release\package\launcher"'
    '  if exist "!HYBASE!" ('
    '    for /f "delims=" %%D in (''dir /b /ad /o-n "!HYBASE!" 2^>nul'') do ('
    '      if not defined HYLAUNCH if exist "!HYBASE!\%%D\hytale-launcher.exe" set "HYLAUNCH=!HYBASE!\%%D\hytale-launcher.exe"'
    '    )'
    '  )'
    ')'
    'set "HYCLIENT=%APPDATA%\Hytale\install\release\package\game\latest\Client\HytaleClient.exe"'
    'if defined HYLAUNCH ('
    '  start "" "!HYLAUNCH!"'
    ') else if exist "!HYCLIENT!" ('
    '  start "" /d "%APPDATA%\Hytale\install\release\package\game\latest\Client" "!HYCLIENT!"'
    ') else ('
    '  echo Hytale Launcher not found - start Hytale yourself, then this dashboard.'
    ')'
    'endlocal'
    'rem ---- start the camera dashboard next to this script ----'
    'start "" "%~dp0hytale_camera_dashboard.exe"'
)
try {
    Set-Content -Path $batPath -Value $batLines -Encoding ASCII -ErrorAction Stop
    Write-OK "Combo launcher written: $batPath"
} catch {
    Write-Warn "Could not write the combo launcher: $_"
    Write-Host "  You can start the game via the Hytale Launcher and run" -ForegroundColor Gray
    Write-Host "  $DASH_EXE from $gameRoot yourself." -ForegroundColor Gray
}

# Ship the icon next to the bat so the shortcut gets proper art.
$icoSrc = Join-Path $SCRIPT_DIR $ICON_FILE
$icoDst = Join-Path $gameRoot $ICON_FILE
$shortcutIcon = $null
if (Test-Path $icoSrc) {
    try { Copy-Item -LiteralPath $icoSrc -Destination $icoDst -Force -ErrorAction Stop } catch {}
    if (Test-Path $icoDst) { $shortcutIcon = $icoDst }
}

if (Test-Path $batPath) {
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $lnkPath = Join-Path $desktop "Hytale VR.lnk"
        if ($shortcutIcon) {
            $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $batPath -WorkingDir $gameRoot -IconPath $shortcutIcon
        } else {
            $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $batPath -WorkingDir $gameRoot
        }
        Write-OK "Desktop shortcut created: Hytale VR (game launcher + dashboard)"
    } catch {
        Write-Warn "Could not create the desktop shortcut: $_"
    }
} else {
    Write-Warn "Combo launcher missing - shortcut skipped."
}

# Record the install path so the Hub's "VR Installed" check + Start-in-VR find it.
try {
    Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Force -ErrorAction Stop
    # Version marker for the Update tile: the EXACT GitHub tag (string-
    # compared against the latest tag by the background check). Fallback
    # v1.0.0 covers the pinned-URL path when the API was unreachable.
    $verTag = if ($script:LatestTag) { $script:LatestTag } else { "v1.0.0" }
    try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $verTag -Encoding UTF8 -Force } catch {}
} catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Hytale VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  ONE-TIME GAME SETTING (first launch):" -ForegroundColor Yellow
Write-Host "    In Hytale's Video settings, set Anti-aliasing FXAA to OFF." -ForegroundColor White
Write-Host ""
Write-Host "  EVERY SESSION (takes ~10 seconds):" -ForegroundColor Yellow
Write-Host "    1. Start SteamVR (headset connected)." -ForegroundColor White
Write-Host "    2. Launch with 'Start in VR' in the Hub, or the 'Hytale VR'" -ForegroundColor White
Write-Host "       desktop shortcut - either starts the" -ForegroundColor White
Write-Host "       Hytale Launcher AND the camera dashboard together." -ForegroundColor White
Write-Host "    3. Enter a world or join a server." -ForegroundColor White
Write-Host "    4. Press F7 in-game to show the player coordinate block." -ForegroundColor White
Write-Host "    5. In the dashboard, click 'Scan player block' (takes ~5s)." -ForegroundColor White
Write-Host "    6. Select the detected coordinate block, then click 'Center VR'." -ForegroundColor White
Write-Host ""
Write-Host "  Keep SteamVR running and Hytale focused while playing." -ForegroundColor Gray
Write-Host ""

try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Write-Host "  Block by block, a whole world wraps around you." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
