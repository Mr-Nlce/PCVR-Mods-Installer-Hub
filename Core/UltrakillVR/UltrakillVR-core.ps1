# ============================================================
# ULTRAKILL - VRTRAKILL_FRAUD VR Mod Installer
# ============================================================
#
# Installs VRTRAKILL_FRAUD v2.0.0 (by Squaresweets) onto a
# pinned ULTRAKILL build (the "first fraud hotfix"). The mod
# requires this exact build - current Steam versions will not
# work. We download the pinned build via Steam Console depot
# download, then install BepInEx and the mod on top.
#
# Flow:
# 1) Open Steam Console, run download_depot for the pinned
# manifest - game is downloaded as a separate copy so
# your retail ULTRAKILL stays untouched.
# 2) Auto-locate the depot folder, move/rename to a stable
# folder next to your Steam content.
# 3) Download and install BepInEx into the game folder.
# 4) Download and install VRTRAKILL_FRAUD v2.0.0.
# 5) Desktop shortcut + steam_appid.txt.
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "ULTRAKILL VR Installer"
$ErrorActionPreference = "Stop"

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------
$MOD_URL = "https://github.com/Squaresweets/VRTRAKILL_FRAUD/releases/download/v2.0.0/ULTRAKILL_COPYTOROOT.zip"
$MOD_NAME = "VRTRAKILL_FRAUD v2.0.0"
$MOD_AUTHOR = "Squaresweets"
$GITHUB_URL = "https://github.com/Squaresweets/VRTRAKILL_FRAUD"

# BepInEx 5 stable (Unity Mono x64)
$BEPINEX_URL = "https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.2/BepInEx_win_x64_5.4.23.2.zip"

# Steam depot - ULTRAKILL, first fraud hotfix build
$DEPOT_APPID = "1229490"
$DEPOT_DEPOTID = "1229491"
$DEPOT_MANIFEST = "5628746843149106870"
$DEPOT_COMMAND = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"

# Target folder name. The depot is moved out of steamapps\content
# into a stable location under C:\Games to avoid Steam overwriting
# the depot folder on update.
$DEFAULT_PARENT = "C:\Games"
$TARGET_NAME = "ULTRAKILL VR"
$DEFAULT_PATH = Join-PathLexical $DEFAULT_PARENT $TARGET_NAME

# Game executable
$GAME_EXE = "ULTRAKILL.exe"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " ULTRAKILL - VR Mod Installer" -ForegroundColor Cyan
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

function Write-OK { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# -------------------------------------------------------
# STEP 1: Steam Depot Download
# -------------------------------------------------------
Write-Header
Write-Host " VRTRAKILL_FRAUD by Squaresweets - full motion-controlled VR for" -ForegroundColor White
Write-Host " ULTRAKILL. Pins the required Steam build (current version unsupported)." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 5 "Steam Depot Download"

Write-Host " VRTRAKILL_FRAUD requires a specific older version of ULTRAKILL." -ForegroundColor White
Write-Host " We download it as a separate copy - your retail ULTRAKILL stays untouched." -ForegroundColor White
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
# !!! LOOK BEFORE ASKING. Steam keeps a finished depot in
# steamapps\content, so a second run - or a run after a crash - already
# has the files. Prompting first and probing only afterwards sends the
# user to fetch gigabytes that are already on disk. Find-SteamDepotPath
# is cheap and touches nothing.
$script:PreFoundDepot = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE
if ($script:PreFoundDepot) {
    Write-OK "The depot is already downloaded: $script:PreFoundDepot"
    Write-Info "Skipping the download - nothing to fetch again."
}
if (-not $script:PreFoundDepot) {

Pause-User "Press Enter to open the Steam Console..."
# Both protocol addresses: depending on the Steam build only one works.
foreach ($cu in @("steam://open/console", "steam://nav/console")) {
    try { Start-Process $cu; Start-Sleep -Milliseconds 900 } catch {}
}
}
Write-Info "Steam Console opening..."

Write-Host ""
Pause-User "Press Enter once the Steam depot download is complete..."

# -------------------------------------------------------
# Auto-detect depot path
# -------------------------------------------------------
Write-Host ""
Write-Host " Locating depot folder..." -ForegroundColor White

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

$probePaths = @(Get-SteamDepotProbePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -AdditionalSteamRoots @($steamInstallPath))
$depotPath = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE -AdditionalSteamRoots @($steamInstallPath)
if ($depotPath) { Write-Info "Depot folder found automatically: $depotPath" }
else { Write-Warn "Depot folder not found yet in any Steam library." }

if (-not $depotPath) {
    $depotPath = Resolve-DepotPath -GameName "ULTRAKILL" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
    if (-not $depotPath) {
        Write-Fail "No depot folder provided."
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

$depotExe = Join-PathLexical $depotPath $GAME_EXE
if (-not (Test-Path $depotExe)) {
 Write-Warn "'$GAME_EXE' not found inside depot - download may be incomplete."
 $choice = ""
 while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host " Continue anyway? (Y/N)").Trim() }
 if ($choice -in @("n","N")) {
 Write-Info "Aborted by user."
 Pause-User "Press Enter to exit..."
 exit 0
 }
} else {
 Write-Info "$GAME_EXE confirmed in depot."
}

# -------------------------------------------------------
# STEP 2: Move & rename depot folder
# -------------------------------------------------------
Write-Step 2 5 "Moving game to stable folder"

$parentOfDepot = Get-PathParentLexical $depotPath

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

$targetParent = Get-PathParentLexical $targetPath
if (-not (Test-InstallerTargetWritable -TargetPath $targetPath)) {
 Write-Fail "The target folder is not writable: $targetParent"
 Pause-User "Press Enter to exit..."; exit 1
}

Write-Host ""
Write-Host " Current location: $depotPath" -ForegroundColor Gray
Write-Host " Moving to: $targetPath" -ForegroundColor Gray
Write-Host ""
Write-Host " Why? Steam may overwrite the depot_$DEPOT_DEPOTID folder on" -ForegroundColor Gray
Write-Host " future depot downloads. A stable folder keeps the VR install" -ForegroundColor Gray
Write-Host " safe and separate from your retail ULTRAKILL." -ForegroundColor Gray
Write-Host ""

if (Test-LiteralPathSafe -Path $targetPath -PathType Container) {
 Write-Warn "A folder already exists at $targetPath"
 Write-Info "Merging the pinned build; saves, BepInEx configs/plugins and other additional files are preserved."
}

try {
 $null = Merge-DirectoryTreeVerified -Source $depotPath -Destination $targetPath -RemoveSource -Label "ULTRAKILL depot build"
 Write-Info "Game installed at: $targetPath"
} catch {
 Write-Fail "Merge failed: $_"
 $__fb = Invoke-InstallerFallback -Action "merge depot files into the install folder" `
 -Instructions "Copy the contents of '$depotPath' into '$targetPath' without deleting additional destination files. Confirm '$targetPath' has enough free disk space (~3 GB). Then choose Retry." `
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

try {
 if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
 Remove-Item $parentOfDepot -Force
 }
} catch {}

$gamePath = $targetPath
$gameExePath = Join-Path $gamePath $GAME_EXE

# -------------------------------------------------------
# STEP 3: Install BepInEx
# -------------------------------------------------------
Write-Step 3 5 "Installing BepInEx 5.4.23.2"

$tempDir = Join-Path $env:TEMP "UltrakillVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Host " Downloading BepInEx 5.4.23.2 ... " -NoNewline -ForegroundColor White
$bepZip = Join-Path $tempDir "BepInEx.zip"
$bepExtract = Join-Path $tempDir "BepInEx"
try {
 Invoke-WebRequest -Uri $BEPINEX_URL -OutFile $bepZip -UseBasicParsing -ErrorAction Stop
 Expand-Archive -Path $bepZip -DestinationPath $bepExtract -Force
 Write-Host "OK" -ForegroundColor Green

 $null = Merge-DirectoryTreeVerified -Source $bepExtract -Destination $gamePath -Label "BepInEx files" `
    -KeepExistingRelativePaths @("BepInEx\config")
 $winhttpCheck = Join-Path $gamePath "winhttp.dll"
 if (Test-Path $winhttpCheck) { Write-Info "BepInEx installed (winhttp.dll verified)." }
 else { Write-Warn "winhttp.dll not found - BepInEx may not have installed correctly." }
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "BepInEx download failed: $_"
 Write-Host ""
 Write-Host " Download BepInEx 5.4.23.2 manually from:" -ForegroundColor Yellow
 Write-Host " https://github.com/BepInEx/BepInEx/releases/tag/v5.4.23.2" -ForegroundColor Yellow
 Write-Host " Extract the ZIP contents into: $gamePath" -ForegroundColor Yellow
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$bepZip' with 7-Zip or Windows Explorer, and extract its contents into '$bepExtract'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$bepZip" -Parent) `
 -DestFolder "$bepExtract" `
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

# -------------------------------------------------------
# STEP 4: Install VRTRAKILL_FRAUD v2.0.0
# -------------------------------------------------------
Write-Step 4 5 "Installing VRTRAKILL_FRAUD v2.0.0"

Write-Host " Downloading $MOD_NAME ... " -NoNewline -ForegroundColor White
$modZip = Join-Path $tempDir "VRTRAKILL.zip"
$modExtract = Join-Path $tempDir "VRTRAKILL"
try {
 Invoke-WebRequest -Uri $MOD_URL -OutFile $modZip -UseBasicParsing -ErrorAction Stop
 Expand-Archive -Path $modZip -DestinationPath $modExtract -Force
 Write-Host "OK" -ForegroundColor Green

 # ZIP has a root folder ULTRAKILL_COPYTOROOT\ - unwrap it
 $modChildren = @(Get-ChildItem -Path $modExtract)
 if ($modChildren.Count -eq 1 -and $modChildren[0].PSIsContainer) {
 $modPayload = $modChildren[0].FullName
 Write-Info "ZIP root folder detected: '$($modChildren[0].Name)' - unwrapping."
 } else {
 $modPayload = $modExtract
 }

 $null = Merge-DirectoryTreeVerified -Source $modPayload -Destination $gamePath -Label "VRTRAKILL mod files" `
    -KeepExistingRelativePaths @("BepInEx\config")

 $dllCheck = Join-Path $gamePath "BepInEx\plugins\VRTRAKILL\VRTRAKILL.dll"
 if (Test-Path $dllCheck) { Write-Info "VRTRAKILL.dll verified." }
 else { Write-Warn "VRTRAKILL.dll not found at expected path - check installation." }

 Write-Info "VRTRAKILL_FRAUD v2.0.0 installed."
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Mod download failed: $_"
 Write-Host ""
 Write-Host " Download the mod manually from:" -ForegroundColor Yellow
 Write-Host " $GITHUB_URL/releases" -ForegroundColor Yellow
 Write-Host " Extract ULTRAKILL_COPYTOROOT contents into: $gamePath" -ForegroundColor Yellow
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$modExtract'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
 -DestFolder "$modExtract" `
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

# steam_appid.txt to prevent Steam re-install prompt
try {
 Set-Content -Path (Join-Path $gamePath "steam_appid.txt") -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force
 Write-Info "steam_appid.txt created."
} catch {
 Write-Warn "Could not create steam_appid.txt: $_"
}

# Record install path for Hub detection
try {
 Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force
} catch {}

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 5: Summary + First Launch
# -------------------------------------------------------
Write-Step 5 5 "All Done!"

Write-Host " Game folder: $gamePath" -ForegroundColor Gray
Write-Host " Launch EXE: $gameExePath" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " [x] Steam depot build (first fraud hotfix)" -ForegroundColor Green
Write-Host " [x] BepInEx 5.4.23.2" -ForegroundColor Green
Write-Host " [x] VRTRAKILL_FRAUD v2.0.0" -ForegroundColor Green
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " Launch SteamVR before the game to avoid it potentially" -ForegroundColor White
Write-Host " starting sometimes out of focus." -ForegroundColor White
Write-Host " Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub or the desktop" -ForegroundColor White
Write-Host " shortcut - NOT via Steam." -ForegroundColor White
Write-Host " (Launching via Steam would run your retail version.)" -ForegroundColor Gray
Write-Host ""
Write-Host " If the game starts without VR on the first launch:" -ForegroundColor White
Write-Host " Close it and launch again - this is normal." -ForegroundColor White
Write-Host ""
Write-Host " SteamVR Theatre Mode must be OFF:" -ForegroundColor Gray
Write-Host " SteamVR -> Settings -> Dashboard -> 'Present Non-VR Applications...' -> OFF" -ForegroundColor Gray
Write-Host ""
Write-Host " Note: HUD flickering and some visual bugs are known mod issues." -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""

# Desktop shortcut
if (Test-Path $gameExePath) {
 try {
 $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\ULTRAKILL VR.lnk" -TargetPath $gameExePath -WorkingDir $gamePath -IconPath "$gameExePath,0"
 Write-Info "Desktop shortcut 'ULTRAKILL VR' created."
 } catch {
 Write-Warn "Could not create shortcut: $_"
 Write-Host " Launch manually from: $gameExePath" -ForegroundColor Gray
 }
}

Write-Host ""
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

Write-Host " VIOLENCE. PERFECT DARK. IN VR." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
