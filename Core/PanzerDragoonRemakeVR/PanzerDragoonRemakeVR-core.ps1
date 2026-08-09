# -------------------------------------------------------
# Panzer Dragoon Remake VR Mod Installer
# by Astienth - distributed via GitHub
#
# Walks the user through:
# 1. Auto-download mod ZIP from GitHub release + locate
# Panzer Dragoon Remake install folder
# 2. Extract mod files in place
#
# GitHub-distributed (public release URL), so the installer
# fetches the ZIP itself via Invoke-WebRequest. No drag-drop,
# no Discord, no manual download.
#
# This is a motion-controls mod with full 6dof right-hand
# controller for aiming and shooting. VR controllers are
# NOT mapped to a virtual gamepad - they're wired directly
# through OpenVR/SteamVR. So no ViGEmBus step needed.
#
# bHaptics support (vest + arms) and Provolver/ProTubeVR
# haptic-gun support are bundled in.
#
# Left-handed mode is supported by the mod itself via a
# config flag (leftHanded in com.astien.PanzerDragoonRemakeVR.cfg
# after first launch). Unlike Dino Trauma, no separate cfg
# file needs to be swapped in.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "PanzerDragoonRemakeVR"
$MOD_VERSION = "v1.0 (bHaptics + Provolver)"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "1178880"
$GAME_NAME = "Panzer Dragoon Remake"

# GitHub URLs - direct, no login required.
$GITHUB_REPO_URL = "https://github.com/Astienth/Panzer_Dragoon_Remake_VR_bHaptics_Provolver"
$GITHUB_DOWNLOAD_URL = "https://github.com/Astienth/Panzer_Dragoon_Remake_VR_bHaptics_Provolver/releases/download/1.0/PanzerDragoonRemakeVR_bHaptics_Provolver.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Panzer Dragoon Remake VR Mod Installer" -ForegroundColor Cyan
 Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}

function Write-Step {
 param([int]$Step, [int]$Total, [string]$Title)
 Write-Host ""
 Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
 Write-Host "----------------------------------------" -ForegroundColor DarkGray
}

function Write-OK { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m" -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

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

function Get-SteamLibraries {
 param($SteamPath)
 $libs = @()
 if (-not $SteamPath) { return $libs }
 $libs += $SteamPath
 $vdf = Join-Path $SteamPath "steamapps\libraryfolders.vdf"
 if (Test-Path $vdf) {
 [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
 $l = $_.Groups[1].Value -replace '\\\\', '\'
 if (Test-Path $l) { $libs += $l }
 }
 }
 return ($libs | Select-Object -Unique)
}

function Find-PanzerDragoonGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Steam installdir is "Panzer Dragoon Remake" (with spaces,
 # no colon - Windows paths can't contain colons even if
 # the marketing name says "Panzer Dragoon: Remake"). The
 # Unity data folder mirrors that as "Panzer Dragoon Remake_Data".
 foreach ($folder in @("Panzer Dragoon Remake", "PanzerDragoonRemake", "Panzer Dragoon")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\Panzer Dragoon Remake_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# Intro: explain what's about to happen
# -------------------------------------------------------
Write-Header

Write-Host " Panzer Dragoon Remake VR is distributed as a public GitHub" -ForegroundColor White
Write-Host " release. The installer fetches the ZIP directly and" -ForegroundColor White
Write-Host " extracts it." -ForegroundColor White
Write-Host ""
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " This is a MOTION CONTROLS mod with full 6dof right-hand" -ForegroundColor White
Write-Host " aiming. The dragon moves with the left stick (only when" -ForegroundColor White
Write-Host " you're looking forward - the mod uses head direction to" -ForegroundColor White
Write-Host " decide whether move-input is active)." -ForegroundColor White
Write-Host ""
Write-Host " No ViGEmBus needed - VR controllers wire directly through" -ForegroundColor White
Write-Host " OpenVR/SteamVR." -ForegroundColor White
Write-Host ""
Write-Host " Haptic devices supported (optional - turn them on BEFORE" -ForegroundColor White
Write-Host " launching the game so the mod can detect them):" -ForegroundColor White
Write-Host " - bHaptics vest + arms (launch the bHaptics Player)" -ForegroundColor White
Write-Host " - Provolver / ProTubeVR (turn the device on)" -ForegroundColor White
Write-Host ""
Write-Host " Left-handed mode is supported via a config flag in" -ForegroundColor White
Write-Host " BepInEx\config\com.astien.PanzerDragoonRemakeVR.cfg" -ForegroundColor White
Write-Host " (created after first launch). No separate file swap needed." -ForegroundColor White
Write-Host ""
Write-Host " Source repo (info, README, support):" -ForegroundColor Gray
Write-Host " $GITHUB_REPO_URL" -ForegroundColor DarkGray
Write-Host ""
Pause-User "Press Enter to start the install..."

# -------------------------------------------------------
# STEP 1: Locate the Panzer Dragoon Remake install + download mod
# -------------------------------------------------------
Write-Step 1 2 "Locating Panzer Dragoon Remake + downloading mod"

$gamePath = Find-PanzerDragoonGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1178880" -SteamFolderNames @("Panzer Dragoon Remake") -GogNames @("Panzer Dragoon Remake") }
if ($gamePath) {
 Write-OK "Found Panzer Dragoon Remake at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Panzer Dragoon Remake in any Steam library."
 Write-Host " Please paste the path to your Panzer Dragoon Remake folder" -ForegroundColor White
 Write-Host " (the folder that contains 'Panzer Dragoon Remake.exe')." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Panzer Dragoon Remake folder").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 $gamePath = $r
 Write-OK "Game folder set: $gamePath"
 } else {
 Write-Fail "Folder not found: $r"
 }
 }
}

# Download the mod ZIP from GitHub directly. Use a temp file so
# we never persist the download alongside the installer.
$modZip = Join-Path $env:TEMP "PanzerDragoonRemakeVR_$([System.IO.Path]::GetRandomFileName()).zip"
Write-Host ""
Write-Host " Downloading mod ZIP from GitHub..." -ForegroundColor Gray
Write-Host " $GITHUB_DOWNLOAD_URL" -ForegroundColor DarkGray
try {
 # Force TLS 1.2 - older PowerShell defaults to SSL3/TLS1.0 which
 # GitHub Releases rejects. UseBasicParsing avoids the IE engine
 # initialisation pop-up on machines where IE has never been opened.
 [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
 Invoke-WebRequest -Uri $GITHUB_DOWNLOAD_URL -OutFile $modZip -UseBasicParsing -ErrorAction Stop
 Write-OK "Downloaded to: $modZip"
} catch {
 Write-Fail "Download failed: $_"
 Write-Host ""
 Write-Host " Possible causes: no internet, GitHub down, firewall blocking." -ForegroundColor Yellow
 Write-Host " You can grab the ZIP manually from:" -ForegroundColor Yellow
 Write-Host " $GITHUB_DOWNLOAD_URL" -ForegroundColor DarkGray
 $__fb = Invoke-InstallerFallback -Action "install folder creation" `
 -Instructions "Manually create '$gamePath' (right-click in Explorer -> New folder), or close all programs locking that path. Make sure you have write permission. Then choose Retry." `
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

# -------------------------------------------------------
# STEP 2: Extract mod files into the game folder
# -------------------------------------------------------
Write-Step 2 2 "Installing mod files"

$tempExtract = Join-Path $env:TEMP "PanzerDragoonRemakeVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null

try {
 Write-Host " Extracting archive..." -ForegroundColor Gray
 Expand-Archive -Path $modZip -DestinationPath $tempExtract -Force
} catch {
 Write-Fail "Extract failed: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$tempExtract'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
 -DestFolder "$tempExtract" `
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

$rootEntries = Get-ChildItem -Path $tempExtract
$srcRoot = $tempExtract
if ($rootEntries.Count -eq 1 -and $rootEntries[0].PSIsContainer) {
 if ($rootEntries[0].Name -ne "BepInEx") {
 $srcRoot = $rootEntries[0].FullName
 }
}

Write-Host " Copying files into: $gamePath" -ForegroundColor Gray
try {
 Get-ChildItem -Path $srcRoot | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
 }
 Write-OK "Mod files installed."
} catch {
 Write-Fail "Copy failed: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open the archive in the temp folder (path printed by the installer just above) with 7-Zip, and extract its contents into '$gamePath'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -DestFolder "$gamePath" `
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

# Clean up both temp artefacts.
try { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}
try { Remove-Item $modZip -Force -ErrorAction SilentlyContinue } catch {}

# Sanity check
$bepinexDir = Join-Path $gamePath "BepInEx"
$modDll = Join-Path $gamePath "BepInEx\plugins\PanzerDragoonRemakeVR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but PanzerDragoonRemakeVR.dll is missing."
} else {
 Write-OK "BepInEx + PanzerDragoonRemakeVR.dll present."
}

# -------------------------------------------------------
# Record install path so the Hub can mark VR Ready
# -------------------------------------------------------
try {
 $pathFile = Join-Path $PSScriptRoot ".installed_path"
 Set-Content -Path $pathFile -Value $gamePath -Encoding UTF8 -Force
} catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " BEFORE LAUNCHING:" -ForegroundColor Yellow
Write-Host " If you have bHaptics devices, launch the bHaptics Player" -ForegroundColor White
Write-Host " and turn the devices on. If you have a Provolver /" -ForegroundColor White
Write-Host " ProTubeVR, turn it on. The mod detects them at startup." -ForegroundColor White
Write-Host ""
Write-Host " Launch Panzer Dragoon Remake normally via Steam, the" -ForegroundColor White
Write-Host " desktop shortcut, or the" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Controls:" -ForegroundColor White
Write-Host " Left stick -> Move dragon (only when looking forward)" -ForegroundColor Gray
Write-Host " + navigate menus" -ForegroundColor Gray
Write-Host " Right stick -> Not used" -ForegroundColor Gray
Write-Host " A button -> Menu confirm" -ForegroundColor Gray
Write-Host " B button -> Menu back" -ForegroundColor Gray
Write-Host " X button -> Recenter view" -ForegroundColor Gray
Write-Host " Y button -> Pause menu" -ForegroundColor Gray
Write-Host " Left grip -> Rotate view left" -ForegroundColor Gray
Write-Host " Right grip -> Rotate view right" -ForegroundColor Gray
Write-Host " Right trigger-> Shoot single shots" -ForegroundColor Gray
Write-Host " Left trigger -> Hold for targeting mode (aim with right" -ForegroundColor Gray
Write-Host " hand). Release to shoot auto-aiming shots." -ForegroundColor Gray
Write-Host ""
Write-Host " MOTION:" -ForegroundColor Cyan
Write-Host " Full 6dof right-hand controller. Aim and shoot with" -ForegroundColor Gray
Write-Host " your right hand." -ForegroundColor Gray
Write-Host ""
Write-Host " A picture of these controls is bundled with the mod at:" -ForegroundColor Gray
Write-Host " $gamePath\VRControls.jpg" -ForegroundColor DarkGray
Write-Host ""
Write-Host " Features:" -ForegroundColor Gray
Write-Host " - bHaptics support (vest + arms)" -ForegroundColor Gray
Write-Host " - Provolver / ProTubeVR haptic-gun support" -ForegroundColor Gray
Write-Host ""
Write-Host " Left-handed mode:" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\com.astien.PanzerDragoonRemakeVR.cfg" -ForegroundColor DarkGray
Write-Host " (created after your first launch with the mod) and set:" -ForegroundColor Gray
Write-Host " leftHanded = true" -ForegroundColor Gray
Write-Host " Left and right trigger functions will swap, and the gun" -ForegroundColor Gray
Write-Host " will be in your left hand." -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to anything else (e.g. winhttp_bak.dll)." -ForegroundColor Gray
Write-Host " Renaming back to winhttp.dll re-activates it." -ForegroundColor Gray
Write-Host ""
Write-Host " Mount up, Rider. The Empire won't fall on its own." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
