# ============================================================
# Tormented Souls VR - Mod Installer
# ============================================================
#
# Installs cybensis/TormentedSoulsVR v1.0.0 onto a Tormented
# Souls build pinned to the manifest from the time the mod
# was released (May 2023). Current Steam versions of the game
# may have moved past this and break the mod's Unity hooks,
# so we download the pinned manifest via Steam Console.
#
# Flow:
# 1) Open Steam Console, run download_depot for the pinned
# manifest on the public branch
# 2) Auto-locate the depot folder, move/rename to a stable
# folder next to your Steam content
# 3) Extract TormentedSoulsVR-1.0.0.zip wrapper contents into
# the game root
# 4) Desktop shortcut + steam_appid.txt to prevent Steam
# from prompting for a re-install
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Tormented Souls VR Installer"
$ErrorActionPreference = "Stop"

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------
$MOD_URL = "https://github.com/cybensis/TormentedSoulsVR/releases/download/v1.0.0/TormentedSoulsVR-1.0.0.zip"
$MOD_NAME = "TormentedSoulsVR v1.0.0"
$MOD_AUTHOR = "cybensis"
$GITHUB_URL = "https://github.com/cybensis/TormentedSoulsVR"

# Steam depot - Tormented Souls, public branch, mod-compatible manifest
$DEPOT_APPID = "1367590"
$DEPOT_DEPOTID = "1367591"
$DEPOT_MANIFEST = "8039349334070823642"
$DEPOT_COMMAND = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"

# Target folder name. The depot is moved out of steamapps\content
# into a stable location under C:\Games. New default avoids Steam
# overwriting the depot folder on update and keeps the VR install
# completely separate from the retail game.
$DEFAULT_PARENT = "C:\Games"
$TARGET_NAME = "Tormented Souls VR"
$DEFAULT_PATH = Join-Path $DEFAULT_PARENT $TARGET_NAME

# Game executable details
$GAME_EXE = "TormentedSouls.exe"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Tormented Souls VR - Mod Installer" -ForegroundColor Cyan
 Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}

function Write-Step {
 param($num, $total, $text)
 Write-Host ""
 Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
 Write-Host ""
}

function Write-OK { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# -------------------------------------------------------
# STEP 1: Steam Depot Download
# -------------------------------------------------------
Write-Header
Write-Step 1 4 "Steam Depot Download"

Write-Host " Tormented Souls VR requires the original build of the game" -ForegroundColor White
Write-Host " from the time the mod was released. We'll download it via" -ForegroundColor White
Write-Host " Steam Console as a separate copy - your retail install" -ForegroundColor White
Write-Host " stays untouched." -ForegroundColor White
Write-Host ""
Write-Host " Here's what's about to happen:" -ForegroundColor Cyan
Write-Host " 1) The Steam Console will open automatically" -ForegroundColor White
Write-Host " 2) The download command is already copied to your clipboard" -ForegroundColor White
Write-Host " 3) Paste with Ctrl+V into the Steam Console and hit Enter" -ForegroundColor Yellow
Write-Host " 4) Wait for Steam to finish, then come back here" -ForegroundColor White
Write-Host ""
Write-Host " When Steam finishes it will show:" -ForegroundColor Gray
Write-Host " Depot download complete : ...\depot_$DEPOT_DEPOTID" -ForegroundColor Yellow
Write-Host ""

try { Set-Clipboard -Value $DEPOT_COMMAND } catch {}

Write-Host ""
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host " ACTION REQUIRED - Paste into Steam Console" -ForegroundColor Yellow
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " [OK] Depot command copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host " Press Enter to open the Steam Console..." -ForegroundColor Yellow
Write-Host " Then click the input field, paste (Ctrl+V) and hit Enter." -ForegroundColor Yellow
Write-Host ""
Write-Host ""
if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
 Write-Host " (i) Virtual Desktop users: the Steam Console may not open" -ForegroundColor DarkGray
 Write-Host "     automatically from inside a VD streaming session. If it" -ForegroundColor DarkGray
 Write-Host "     doesn't, open it manually: Steam menu bar - View - Console," -ForegroundColor DarkGray
 Write-Host "     then paste-and-Enter. Alternatively, choose [3] in the" -ForegroundColor DarkGray
 Write-Host "     next menu to use the DepotDownloader fallback." -ForegroundColor DarkGray
 Write-Host ""
}
Pause-User "Press Enter to open the Steam Console..."
Start-Process "steam://nav/console"
Write-OK "Steam Console opening..."

Write-Host ""
Pause-User "Press Enter once the Steam depot download is complete..."

# -------------------------------------------------------
# Auto-detect depot path from Steam registry
# -------------------------------------------------------
Write-Host ""
Write-Host " Looking for Steam installation..." -ForegroundColor White

$steamInstallPath = $null
foreach ($reg in @(
 "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
 "HKLM:\SOFTWARE\Valve\Steam",
 "HKCU:\SOFTWARE\Valve\Steam"
)) {
 try {
 $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
 if ($p -and (Test-Path $p)) { $steamInstallPath = $p; break }
 } catch {}
}

$depotPath = $null

if ($steamInstallPath) {
 $autoPath = Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID"
 Write-Info "Expected depot path: $autoPath"
 if ((Test-Path $autoPath) -and (Test-Path (Join-Path $autoPath $GAME_EXE))) {
 $depotPath = $autoPath
 Write-OK "Depot folder found automatically!"
 } else {
 Write-Warn "Depot folder not found at expected location."
 Write-Host " This usually means the download isn't finished yet," -ForegroundColor Gray
 Write-Host " or Steam used a different path." -ForegroundColor Gray
 }
} else {
 Write-Warn "Could not find Steam installation in registry."
}

if (-not $depotPath) {
    $probePaths = @()
    if ($steamInstallPath) {
        $probePaths += (Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID")
    }
    $depotPath = Resolve-DepotPath -GameName "Tormented Souls" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
    if (-not $depotPath) {
        Write-Fail "No depot folder provided."
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

# Sanity check: depot should contain the game exe
$depotExe = Join-Path $depotPath $GAME_EXE
if (-not (Test-Path $depotExe)) {
 Write-Warn "'$GAME_EXE' not found inside depot."
 Write-Host " Expected: $depotExe" -ForegroundColor Gray
 Write-Host " This usually means the download is incomplete or the wrong" -ForegroundColor Gray
 Write-Host " manifest was downloaded. Install anyway?" -ForegroundColor White
 $choice = ""
 while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host " Continue? (Y/N)").Trim() }
 if ($choice -in @("n","N")) {
 Write-Info "Aborted by user."
 Pause-User "Press Enter to exit..."
 exit 0
 }
} else {
 Write-OK "$GAME_EXE confirmed in depot."
}

# -------------------------------------------------------
# STEP 2: Move & rename depot folder
# -------------------------------------------------------
Write-Step 2 4 "Moving game to stable folder"

$parentOfDepot = Split-Path $depotPath -Parent # ...\app_1367590

Write-Host " Default install location: $DEFAULT_PATH" -ForegroundColor Gray
Write-Host " (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
Write-Host "  library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
Write-Host ""
$userInput = (Read-Host " Press Enter to use default, or type a different full path").Trim().Trim('"')
if (-not $userInput) {
 $targetPath = $DEFAULT_PATH
} else {
 $targetPath = $userInput
}

# Make sure parent exists so the move can succeed
$targetParent = Split-Path $targetPath -Parent
if ($targetParent -and -not (Test-Path $targetParent)) {
 try { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
 catch { Write-Fail "Could not create parent folder $targetParent : $_"; Pause-User "Press Enter to exit..."; exit 1 }
}

Write-Host ""
Write-Host " Current location: $depotPath" -ForegroundColor Gray
Write-Host " Moving to: $targetPath" -ForegroundColor Gray
Write-Host ""
Write-Host " Why? Steam may overwrite the app_$DEPOT_APPID folder during" -ForegroundColor Gray
Write-Host " future depot downloads. Moving to a stable name keeps the" -ForegroundColor Gray
Write-Host " VR install safe and separate from your retail Tormented Souls." -ForegroundColor Gray
Write-Host ""

if (Test-Path $targetPath) {
 Write-Warn "A folder already exists at $targetPath"
 Write-Host " This may be from a previous install. Delete it to continue?" -ForegroundColor White
 Write-Host " [Y] Delete existing folder and proceed" -ForegroundColor White
 Write-Host " [N] Keep it, abort install" -ForegroundColor Gray
 $choice = ""
 while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host " Your choice (Y/N)").Trim() }
 if ($choice -in @("n","N")) {
 Write-Info "Aborted by user."
 Pause-User "Press Enter to exit..."
 exit 0
 }
 try { Remove-Item $targetPath -Recurse -Force -ErrorAction Stop }
 catch { Write-Fail "Could not delete: $_"; Pause-User "Press Enter to exit..."; exit 1 }
}

try {
 Move-Item -Path $depotPath -Destination $targetPath -ErrorAction Stop
 Write-OK "Game moved to: $targetPath"
} catch {
 Write-Fail "Move failed: $_"
 Write-Info "The game files are still at: $depotPath"
 $__fb = Invoke-InstallerFallback -Action "move depot files to install folder" `
 -Instructions "The game files are still at '$depotPath'. Manually move/cut them to '$targetPath' (your chosen install location). Confirm '$targetPath' has enough free disk space (~6 GB). Then choose Retry." `
 -SkipMessage "Skipped - game files are still in the temp folder; you must move them before launching." `
 -DestFolder "$targetPath" `
 -AllowSkip $true
 -Instructions "Read the messages above for what failed. Try to address it manually then choose Retry, or Skip to continue without it." `
 -SkipMessage "Skipped - some functionality may not work." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-check is not possible here without knowing local state.
 # If the user fixed the issue, the next pass through the
 # installer will succeed. Exit cleanly so they can re-run.
 Pause-User "Please re-run the installer once the issue is resolved. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

# Clean up empty app_<id> folder
try {
 if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
 Remove-Item $parentOfDepot -Force
 }
} catch {}

$gamePath = $targetPath
$gameExePath = Join-Path $gamePath $GAME_EXE

# -------------------------------------------------------
# STEP 3: Download and install the mod
# -------------------------------------------------------
Write-Step 3 4 "Installing the VR mod"

$tempDir = Join-Path $env:TEMP "TormentedSoulsVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null

$zipFile = Join-Path $tempDir "TormentedSoulsVR.zip"
$extractDir = Join-Path $tempDir "extract"

Write-Host " Downloading $MOD_NAME from GitHub..." -ForegroundColor White
try {
 Invoke-WebRequest -Uri $MOD_URL -OutFile $zipFile -UseBasicParsing -ErrorAction Stop
 Write-OK "Mod downloaded."
} catch {
 Write-Fail "Mod download failed: $_"
 Write-Host ""
 Write-Host " Please download the mod manually from:" -ForegroundColor Yellow
 Write-Host " $GITHUB_URL/releases" -ForegroundColor Yellow
 Write-Host " Then extract the contents of the wrapper folder into:" -ForegroundColor Yellow
 Write-Host " $gamePath" -ForegroundColor Yellow
 $__fb = Invoke-InstallerFallback -Action "install folder creation" `
 -Instructions "Manually create '$tempDir' (right-click in Explorer -> New folder), or close all programs locking that path. Make sure you have write permission. Then choose Retry." `
 -SkipMessage "Skipped - no install folder; the rest of this installer will fail." `
 -AllowSkip $false
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Retry folder create
 try {
 if (-not (Test-Path $gameDir)) {
 New-Item -ItemType Directory -Path $gameDir -Force -ErrorAction Stop | Out-Null
 }
 Write-OK "Folder ready: $gameDir"
 } catch {
 Pause-User "Still cannot create folder. Choose a different path then re-run. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
}

Write-Host " Extracting mod files to temp..." -NoNewline -ForegroundColor White
try {
 Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force -ErrorAction Stop
 Write-Host " OK" -ForegroundColor Green
} catch {
 Write-Host " FAILED" -ForegroundColor Red
 Write-Fail "Extraction failed: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$zipFile' with 7-Zip or Windows Explorer, and extract its contents into '$extractDir'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$zipFile" -Parent) `
 -DestFolder "$extractDir" `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # User claims they extracted manually. Re-run extract logic
 # by exiting and forcing re-run (we don't know which archive
 # variable this catch belongs to without context).
 Pause-User "We will exit so you can re-run with the fixed environment. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

# The mod zip contains a wrapper folder 'TormentedSoulsVR-1.0.0/'
$wrapper = Get-ChildItem -Path $extractDir -Directory -Filter "TormentedSoulsVR-*" |
 Select-Object -First 1
if ($wrapper) {
 $sourceRoot = $wrapper.FullName
 Write-Info "Wrapper folder: $($wrapper.Name)"
} else {
 $sourceRoot = $extractDir
 Write-Info "No wrapper folder found - using zip root."
}

Write-Host " Copying mod files into game root..." -NoNewline -ForegroundColor White
try {
 Get-ChildItem -Path $sourceRoot -Force | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
 }
 Write-Host " OK" -ForegroundColor Green
 Write-OK "Mod installed to: $gamePath"
} catch {
 Write-Host " FAILED" -ForegroundColor Red
 Write-Fail "Copy failed: $_"
 $__fb = Invoke-InstallerFallback -Action "file copy into game folder" `
 -Instructions "Manually copy the extracted mod files into '$gamePath'. Watch for UAC permission prompts. Then choose Skip below to continue with downstream installer steps." `
 -SkipMessage "Skipped - mod files were NOT copied; install is incomplete." `
 -DestFolder "$gamePath" `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-check is not possible here without knowing local state.
 # If the user fixed the issue, the next pass through the
 # installer will succeed. Exit cleanly so they can re-run.
 Pause-User "Please re-run the installer once the issue is resolved. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

$bepinexPath = Join-Path $gamePath "BepInEx"
if (Test-Path $bepinexPath) {
 Write-OK "BepInEx structure confirmed at: $bepinexPath"
} else {
 Write-Warn "BepInEx folder not visible at expected location."
}

# Drop a steam_appid.txt next to the EXE. Without this, Steam may
# detect the running game, notice the Library entry isn't pointing
# here, and prompt the user to reinstall. With this file, the Steam
# API knows which AppID this is and lets it run normally.
try {
 $steamAppIdFile = Join-Path $gamePath "steam_appid.txt"
 Set-Content -Path $steamAppIdFile -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force
 Write-OK "steam_appid.txt created (prevents Steam re-install prompt)."
} catch {
 Write-Warn "Could not create steam_appid.txt: $_"
 Write-Host " If Steam prompts you to reinstall Tormented Souls, manually" -ForegroundColor Gray
 Write-Host " create a file called 'steam_appid.txt' next to the game EXE," -ForegroundColor Gray
 Write-Host " containing just the number: $DEPOT_APPID" -ForegroundColor Gray
}

# Record the install path for the Hub. Tormented Souls VR lives under
# steamapps\content\TormentedSouls-VR\, which isn't where the Hub
# would normally scan (steamapps\common). Writing the actual path
# here lets the Hub's card detection pick it up reliably even if the
# user also has the retail game installed.
try {
 $pathFile = Join-Path $PSScriptRoot ".installed_path"
 Set-Content -Path $pathFile -Value $gamePath -Encoding UTF8 -Force
} catch {}

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 4: Summary + Desktop Shortcut
# -------------------------------------------------------
Write-Step 4 4 "All Done!"

Write-Host " Your Tormented Souls VR installation is ready." -ForegroundColor White
Write-Host ""
Write-Host " Game folder: $gamePath" -ForegroundColor Yellow
Write-Host " Launch EXE: $gameExePath" -ForegroundColor Yellow
Write-Host ""

Write-Host " IMPORTANT notes before you play:" -ForegroundColor Cyan
Write-Host ""
Write-Host " >> Start SteamVR BEFORE launching Tormented Souls." -ForegroundColor Yellow
Write-Host " >> Launch via the desktop shortcut, NOT via Steam." -ForegroundColor Yellow
Write-Host " (Launching via Steam would run your retail version)" -ForegroundColor Gray
Write-Host ""
Write-Host " Quick control reminders:" -ForegroundColor White
Write-Host " - Shooting: hold left trigger first, then pull right trigger" -ForegroundColor Gray
Write-Host " - Height/rotation recalibration: hold Y button at preferred" -ForegroundColor Gray
Write-Host " height/facing until the menu opens" -ForegroundColor Gray
Write-Host " - Tested on Quest 2 / Oculus Touch; other controllers may" -ForegroundColor Gray
Write-Host " need manual SteamVR binding setup" -ForegroundColor Gray
Write-Host ""

if (Test-Path $gameExePath) {
 try {
 $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Tormented Souls VR.lnk" -TargetPath $gameExePath -WorkingDir $gamePath -IconPath "$gameExePath,0"
 Write-OK "Desktop shortcut 'Tormented Souls VR' created."
 } catch {
 Write-Warn "Could not create shortcut: $_"
 Write-Host " Launch manually from:" -ForegroundColor Gray
 Write-Host " $gameExePath" -ForegroundColor Yellow
 }
}

Write-Host ""
Write-Host " Opening installation folder..." -ForegroundColor Gray
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

Write-Host ""
Write-Host " The manor's locked doors await, Caroline." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
