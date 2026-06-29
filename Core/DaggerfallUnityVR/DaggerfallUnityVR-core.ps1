# ============================================================
#  Daggerfall Unity VR Installer (DFUVR by LokiusV)
# ============================================================
# Three-part setup:
#   1) Daggerfall (DOS) on Steam (App 1812390, free) - supplies
#      the original 1996 game data that Daggerfall Unity reads.
#   2) Daggerfall Unity (open-source Unity engine port) - a
#      standalone build fetched from GitHub (NOT on Steam).
#      Installed to C:\Games\Daggerfall Unity VR.
#   3) DFUVR (the VR mod, BepInEx-based) - downloaded from
#      GitHub and extracted on top of the DFU folder
#      (winhttp.dll + doorstop_config.ini + BepInEx\ +
#      DaggerfallUnity_Data overrides).
#
# The mod irreversibly overwrites KeyBinds.txt, so we back up
# the DFU user-data folder first. Never bundles any payload -
# everything is downloaded at install time.
# ============================================================

# Load installer-safety helpers (Invoke-SafeDownload,
# Expand-ArchiveOrFallback, Invoke-InstallerFallback, Get-SevenZip).
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Daggerfall Unity VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME    = "Daggerfall Unity VR (DFUVR)"
$MOD_AUTHOR  = "LokiusV"
$GAME_FOLDER = "Daggerfall Unity VR"
$GAME_EXE    = "DaggerfallUnity.exe"
$MOD_FILE    = "BepInEx\plugins\DFUVR.dll"   # proof the VR mod is present
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")

# DOS Daggerfall on Steam (free) - source of original game data
$DOS_APPID   = "1812390"

# Daggerfall Unity engine - pinned GitHub release
$DFU_URL     = "https://github.com/Interkarma/daggerfall-unity/releases/download/v1.1.1-cve-2025/dfu_windows_64bit-v1.1.1.zip"
$DFU_RELEASES_PAGE = "https://github.com/Interkarma/daggerfall-unity/releases"

# DFUVR VR mod - GitHub release
$DFUVR_URL   = "https://github.com/LokiusV/Daggerfall-Unity-VR/releases/download/v.0.9.1/DFUVR_V.0.9.1_Early_Access.zip"
$DFUVR_RELEASES_PAGE = "https://github.com/LokiusV/Daggerfall-Unity-VR/releases"

# DFU writes config + saves here; KeyBinds.txt gets overwritten by the mod
$DFU_USER_DATA = Join-Path $env:USERPROFILE "AppData\LocalLow\Daggerfall Workshop\Daggerfall Unity"

# ---- Inline console helpers (per-installer; NOT shared) -----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  Daggerfall Unity VR Installer" -ForegroundColor Cyan
    Write-Host "  DFUVR by LokiusV - VR for the Daggerfall Unity engine" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-WritableRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

function Get-SteamPath {
    foreach ($reg in @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam",
        "HKCU:\SOFTWARE\Valve\Steam"
    )) {
        try {
            $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
            if ($p -and (Test-Path $p)) { return $p }
        } catch {}
    }
    return $null
}

function Test-DosDaggerfallInstalled {
    # Look for the DOS Daggerfall library folder across Steam libs.
    $steam = Get-SteamPath
    if (-not $steam) { return $false }
    $libs = @($steam)
    $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        $content = Get-Content $vdf -Raw
        foreach ($m in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
            $p = $m.Groups[1].Value -replace '\\\\', '\'
            if (Test-Path $p) { $libs += $p }
        }
    }
    foreach ($lib in ($libs | Select-Object -Unique)) {
        $manifest = Join-Path $lib "steamapps\appmanifest_$DOS_APPID.acf"
        if (Test-Path $manifest) { return $true }
        # Also accept the actual game files: some installs have no readable
        # .acf (moved/merged library, manual copy), but the DOS data is what
        # Daggerfall Unity actually needs. DAGGER.exe is the original launcher.
        $dagExe = Join-Path $lib "steamapps\common\The Elder Scrolls Daggerfall\DF\DAGGER\DAGGER.exe"
        if (Test-Path $dagExe) { return $true }
    }
    return $false
}

# -------------------------------------------------------
# STEP 0: Welcome
# -------------------------------------------------------
Write-Header
Write-Host "  About this mod:" -ForegroundColor White
Write-Host "  - DFUVR adds VR to Daggerfall Unity, the open-source engine" -ForegroundColor Gray
Write-Host "    recreation of the 1996 RPG The Elder Scrolls II: Daggerfall." -ForegroundColor Gray
Write-Host "  - Motion controls. Early-access - playable but a bit janky." -ForegroundColor Gray
Write-Host ""
Write-Host "  This installer will set up three things:" -ForegroundColor White
Write-Host "  1. Daggerfall (DOS) from Steam - free, supplies the game data" -ForegroundColor Gray
Write-Host "  2. Daggerfall Unity engine - downloaded to C:\Games\$GAME_FOLDER" -ForegroundColor Gray
Write-Host "  3. The DFUVR VR mod - added on top of the engine" -ForegroundColor Gray
Write-Host ""
Write-Host "  IMPORTANT: Set ALL monitors to 1920x1080 before playing or" -ForegroundColor Yellow
Write-Host "  the in-game UI may not render. Keep the game window focused." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to begin..."

# -------------------------------------------------------
# STEP 1: DOS Daggerfall on Steam (free game data)
# -------------------------------------------------------
Write-Step 1 6 "Daggerfall (DOS) on Steam"

if (Test-DosDaggerfallInstalled) {
    Write-OK "Daggerfall (DOS) is installed in your Steam library."
} else {
    Write-Warn "Daggerfall (DOS) was not found in your Steam library."
    Write-Host "  It's FREE on Steam and supplies the original game data that" -ForegroundColor White
    Write-Host "  Daggerfall Unity reads. Install it, then come back here." -ForegroundColor White
    Write-Host ""
    Write-Host "  Opening the Steam install prompt (App $DOS_APPID)..." -ForegroundColor Gray
    try { Start-Process "steam://install/$DOS_APPID" } catch {
        try { Start-Process "https://store.steampowered.com/app/$DOS_APPID/" } catch {}
    }
    Write-Host ""
    Write-Host "  In Steam: click Install, let it finish, then return here." -ForegroundColor White
    Pause-User "Press Enter once Daggerfall (DOS) is installed (or to continue anyway)..."
}

# -------------------------------------------------------
# STEP 2: Choose install location for the engine
# -------------------------------------------------------
Write-Step 2 6 "Choosing the install location"

$defaultParent = $null
foreach ($r in $DEFAULT_ROOTS) {
    if (Test-WritableRoot -Root $r) { $defaultParent = [string]$r; break }
}
if (-not $defaultParent) { $defaultParent = "C:\Games" }
$defaultPath = Join-Path $defaultParent $GAME_FOLDER

Write-Host "  Default install location: $defaultPath" -ForegroundColor Gray
Write-Host "  (Recommended: C:\Games keeps it off the Steam library and away" -ForegroundColor DarkGray
Write-Host "   from Program Files / UAC issues.)" -ForegroundColor DarkGray
Write-Host ""
$userInput = (Read-Host "  Press Enter to use the default, or type a different full path").Trim().Trim('"')
if (-not $userInput) {
    $installRoot = $defaultPath
} elseif ((Split-Path $userInput -Leaf) -eq $GAME_FOLDER) {
    $installRoot = $userInput
} else {
    $installRoot = Join-Path $userInput $GAME_FOLDER
}
$chosenParent = Split-Path $installRoot -Parent
if (-not (Test-WritableRoot -Root $chosenParent)) {
    Write-Warn "That location isn't writable: $chosenParent"
    Write-Host "  Enter a different folder (avoid Program Files / Users):" -ForegroundColor White
    $newParent = $null
    while (-not $newParent) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $newParent = [string]$r }
        else { Write-Fail "Not writable: $r" }
    }
    $installRoot = Join-Path $newParent $GAME_FOLDER
}
Write-OK "Installing to: $installRoot"

$tempDir = Join-Path $env:TEMP "_dfuvr_tmp"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

if (Test-Path $installRoot) {
    Write-Warn "A folder already exists at $installRoot"
    Write-Host "  [Y] Delete it and reinstall fresh   [N] Keep it, install over the top" -ForegroundColor White
    $c = ""
    while ($c -notin @("y","Y","n","N")) { $c = (Read-Host "  Your choice (Y/N)").Trim() }
    if ($c -in @("y","Y")) {
        try { Remove-Item $installRoot -Recurse -Force -ErrorAction Stop } catch { Write-Warn "Could not fully delete - will install over the top." }
    }
}
if (-not (Test-Path $installRoot)) { New-Item -ItemType Directory -Path $installRoot -Force | Out-Null }

# -------------------------------------------------------
# STEP 3: Download + install the Daggerfall Unity engine
# -------------------------------------------------------
Write-Step 3 6 "Downloading Daggerfall Unity engine"

$dfuZip = Join-Path $tempDir "dfu_engine.zip"
$dfuExtract = Join-Path $tempDir "dfu_extract"
New-Item -ItemType Directory -Path $dfuExtract -Force | Out-Null

if (-not (Invoke-SafeDownload -Urls @($DFU_URL) -Destination $dfuZip -Label "Daggerfall Unity engine" `
        -ManualUrl $DFU_RELEASES_PAGE `
        -Instructions "Download the Windows 64-bit Daggerfall Unity release zip and drop it into the opened folder, then choose Retry." `
        -SkipMessage "Skipped - the engine was NOT downloaded; cannot continue.")) {
    if (-not (Test-Path $dfuZip)) {
        Write-Fail "No engine archive available. Aborting."
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..."; exit 1
    }
}

$exDfu = Expand-ArchiveOrFallback -ArchivePath $dfuZip -DestinationFolder $dfuExtract `
            -Label "Daggerfall Unity engine" `
            -SkipMessage "Skipped - engine archive was NOT extracted; install is incomplete."
if ([string]$exDfu -eq "quit") { try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }

# Flatten: locate the folder that actually holds DaggerfallUnity.exe.
$dfuPayload = $dfuExtract
if (-not (Test-Path (Join-Path $dfuPayload $GAME_EXE))) {
    $hit = Get-ChildItem -Path $dfuExtract -Recurse -Filter $GAME_EXE -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $dfuPayload = Split-Path $hit.FullName -Parent }
}

Write-Host "  Installing engine files ... " -NoNewline -ForegroundColor White
$engineOk = $false
try {
    Get-ChildItem -Path $dfuPayload | ForEach-Object { Copy-Item -Path $_.FullName -Destination $installRoot -Recurse -Force }
    Write-Host "OK" -ForegroundColor Green
    $engineOk = $true
} catch {
    Write-Host "FAILED" -ForegroundColor Red
    $__fb = Invoke-InstallerFallback -Action "installing the engine files" `
        -Instructions "Copy the contents of '$dfuPayload' into '$installRoot' (so $GAME_EXE sits at its root). Then choose Retry." `
        -SkipMessage "Skipped - engine files were NOT copied; install is incomplete." `
        -SourceFolder "$dfuPayload" -DestFolder "$installRoot" -AllowSkip $true
    if ([string]$__fb -eq "quit") { try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$__fb -eq "retry") { try { Get-ChildItem -Path $dfuPayload | ForEach-Object { Copy-Item -Path $_.FullName -Destination $installRoot -Recurse -Force }; $engineOk = $true } catch {} }
}
if (Test-Path (Join-Path $installRoot $GAME_EXE)) { Write-OK "Daggerfall Unity engine installed." }
else { Write-Warn "$GAME_EXE not found at install root - check $installRoot." }

# -------------------------------------------------------
# STEP 4: First run + KeyBinds backup
# -------------------------------------------------------
Write-Step 4 6 "First run + settings backup"

Write-Host "  Daggerfall Unity needs to run ONCE on flat screen so it can:" -ForegroundColor White
Write-Host "  - locate your Daggerfall (DOS) game data, and" -ForegroundColor Gray
Write-Host "  - create its config (KeyBinds.txt, Settings.ini)." -ForegroundColor Gray
Write-Host ""
Write-Host "  The VR mod OVERWRITES KeyBinds.txt, so we'll back it up after." -ForegroundColor Yellow
Write-Host ""
$exePath = Join-Path $installRoot $GAME_EXE
if (Test-Path $exePath) {
    Write-Host "  [Y] Launch Daggerfall Unity now   [N] I'll do it myself later" -ForegroundColor White
    $c = ""
    while ($c -notin @("y","Y","n","N")) { $c = (Read-Host "  Your choice (Y/N)").Trim() }
    if ($c -in @("y","Y")) {
        try {
            Start-Process -FilePath $exePath -WorkingDirectory $installRoot
            Write-Host "  Complete the DFU setup wizard (point it at your Daggerfall data)," -ForegroundColor Gray
            Write-Host "  then CLOSE Daggerfall Unity and come back here." -ForegroundColor Gray
            Pause-User "Press Enter once you've run it once and closed it..."
        } catch { Write-Warn "Could not launch automatically: $($_.Exception.Message)" }
    }
} else {
    Write-Warn "Skipping launch - engine exe not found."
}

# Back up the DFU user-data folder (KeyBinds.txt etc.) if present.
if (Test-Path $DFU_USER_DATA) {
    $backupDir = "$DFU_USER_DATA.pre-vr.bak"
    try {
        if (Test-Path $backupDir) { $backupDir = "$DFU_USER_DATA.pre-vr-$(Get-Date -Format 'yyyyMMdd-HHmmss').bak" }
        Copy-Item -Path $DFU_USER_DATA -Destination $backupDir -Recurse -Force -ErrorAction Stop
        Write-OK "Backed up DFU settings to: $backupDir"
    } catch {
        Write-Warn "Could not back up settings: $($_.Exception.Message)"
        Write-Host "  Manually copy '$DFU_USER_DATA' somewhere safe before playing." -ForegroundColor Yellow
    }
} else {
    Write-Info "No DFU user-data folder yet - it'll be created on first run."
    Write-Host "  (If you skipped the launch above, back up KeyBinds.txt later.)" -ForegroundColor DarkGray
}

# -------------------------------------------------------
# STEP 5: Download + install the DFUVR mod
# -------------------------------------------------------
Write-Step 5 6 "Installing the DFUVR VR mod"

$modZip = Join-Path $tempDir "dfuvr_mod.zip"
$modExtract = Join-Path $tempDir "dfuvr_extract"
New-Item -ItemType Directory -Path $modExtract -Force | Out-Null

if (-not (Invoke-SafeDownload -Urls @($DFUVR_URL) -Destination $modZip -Label $MOD_NAME `
        -ManualUrl $DFUVR_RELEASES_PAGE `
        -Instructions "Download the DFUVR early-access zip from the releases page and drop it into the opened folder, then choose Retry." `
        -SkipMessage "Skipped - the VR mod was NOT downloaded; the engine will stay flat.")) {
    if (-not (Test-Path $modZip)) {
        Write-Fail "No VR mod archive available."
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..."; exit 1
    }
}

$exMod = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $modExtract `
            -Label $MOD_NAME `
            -SkipMessage "Skipped - VR mod archive was NOT extracted."
if ([string]$exMod -eq "quit") { try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }

# Flatten the "DFUVR_V.0.9.1_Early_Access" wrapper: find the folder
# that holds winhttp.dll (the BepInEx doorstop loader).
$modPayload = $modExtract
if (-not (Test-Path (Join-Path $modPayload "winhttp.dll"))) {
    $hit = Get-ChildItem -Path $modExtract -Recurse -Filter "winhttp.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $modPayload = Split-Path $hit.FullName -Parent }
}

Write-Host "  Adding VR mod files on top of the engine ... " -NoNewline -ForegroundColor White
$modOk = $false
try {
    Get-ChildItem -Path $modPayload | ForEach-Object { Copy-Item -Path $_.FullName -Destination $installRoot -Recurse -Force }
    Write-Host "OK" -ForegroundColor Green
    $modOk = $true
} catch {
    Write-Host "FAILED" -ForegroundColor Red
    $__fb = Invoke-InstallerFallback -Action "installing the VR mod files" `
        -Instructions "Copy the contents of '$modPayload' into '$installRoot' (merge/overwrite). Then choose Retry." `
        -SkipMessage "Skipped - VR mod files were NOT copied." `
        -SourceFolder "$modPayload" -DestFolder "$installRoot" -AllowSkip $true
    if ([string]$__fb -eq "quit") { try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$__fb -eq "retry") { try { Get-ChildItem -Path $modPayload | ForEach-Object { Copy-Item -Path $_.FullName -Destination $installRoot -Recurse -Force }; $modOk = $true } catch {} }
}

$modDll = Join-Path $installRoot $MOD_FILE
if (Test-Path $modDll) {
    Write-OK "DFUVR.dll present - VR mod installed."
    try {
        $pathFile = Join-Path $PSScriptRoot ".installed_path"
        Set-Content -Path $pathFile -Value $installRoot -Encoding UTF8 -Force
    } catch {}
} else {
    Write-Warn "DFUVR.dll not found after install - check $installRoot\BepInEx\plugins."
}

# Cleanup temp.
try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 6: Display hint + desktop shortcut
# -------------------------------------------------------
Write-Step 6 6 "Display settings + desktop shortcut"

Write-Host "  Opening Windows display settings..." -ForegroundColor Gray
Write-Host "  Set ALL connected monitors to 1920x1080, or the in-game UI" -ForegroundColor Yellow
Write-Host "  may not render at all." -ForegroundColor Yellow
try { Start-Process "ms-settings:display" } catch {}
Pause-User "Press Enter once your monitors are set to 1920x1080..."

if (Test-Path $exePath) {
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut("$env:USERPROFILE\Desktop\Daggerfall Unity VR.lnk")
        $shortcut.TargetPath = $exePath
        $shortcut.WorkingDirectory = $installRoot
        $shortcut.Description = "Daggerfall Unity VR (DFUVR by LokiusV)"
        $shortcut.IconLocation = "$exePath,0"
        $shortcut.Save()
        Write-OK "Desktop shortcut 'Daggerfall Unity VR' created."
    } catch {
        Write-Warn "Could not create shortcut: $($_.Exception.Message)"
        Write-Info "Launch manually: $exePath"
    }
}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Installation complete." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Installed to: $installRoot" -ForegroundColor Gray
Write-Host ""
Write-Host "  To play:" -ForegroundColor White
Write-Host "  1. Make sure all monitors are at 1920x1080." -ForegroundColor Gray
Write-Host "  2. Start SteamVR." -ForegroundColor Gray
Write-Host "  3. Launch via the Hub (Start in VR) or the desktop shortcut." -ForegroundColor Gray
Write-Host "  4. First-run menu: pick your Controller type (Oculus/Meta," -ForegroundColor Gray
Write-Host "     HTC Vive Wands, or other)." -ForegroundColor Gray
Write-Host "  5. In-game: hold LEFT X then Y to calibrate; set height with" -ForegroundColor Gray
Write-Host "     the RIGHT thumbstick; sheath sits at your left hand." -ForegroundColor Gray
Write-Host ""
Write-Host "  KEEP THE GAME WINDOW FOCUSED while playing (the mod emulates" -ForegroundColor Yellow
Write-Host "  mouse/keyboard input on your desktop)." -ForegroundColor Yellow
Write-Host ""
Write-Host "  The Mantellan Crux awaits. Mind the spell reflection." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
