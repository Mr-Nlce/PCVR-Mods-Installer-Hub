# -------------------------------------------------------
# Circuit Superstars VR Mod Installer
# by Astienth - distributed via GitHub
#
# Walks the user through:
# 1. Auto-download mod ZIP from GitHub release + locate
# Circuit Superstars install folder
# 2. Extract mod files in place
#
# GitHub-distributed (public release URL), so the installer
# fetches the ZIP itself via Invoke-WebRequest. No drag-drop,
# no Discord, no manual download.
#
# Gamepad/keyboard - no VR controllers. ViGEmBus is not needed.
#
# bHaptics vest support (vest only, no arms).
#
# Naming pitfall worth noting:
# Game title: "Circuit Superstars" (two words, capitalised)
# Steam folder: "Circuit Superstars" (preserves the spaces)
# Unity data: "circuit-superstars_Data" (lowercase, hyphenated)
# Game EXE: "circuit-superstars.exe" (same casing as Unity)
# Mod DLL: "CircuitSuperstars_VR.dll"
#
# Astienth-repo quirk: the README is at
# github.com/Astienth/Circuit_Superstars_VR_bHaptics but the
# release download URL points at a *different* repo,
# github.com/Astienth/Circuit_Superstars_VR (no `_bHaptics`
# suffix). Both are intentional - the author hosts the README
# in one repo and the binary release in the other. We use the
# download URL as-is and the README repo for "info" links.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "CircuitSuperstars_VRMod"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "1097130"
$GAME_NAME = "Circuit Superstars"

# GitHub URLs - direct, no login required.
# README/info repo: ..._bHaptics (where the docs live)
# Download repo: no suffix (where the binary release lives)
$GITHUB_REPO_URL = "https://github.com/Astienth/Circuit_Superstars_VR_bHaptics"
$GITHUB_DOWNLOAD_URL = "https://github.com/Astienth/Circuit_Superstars_VR/releases/download/1.0.0/CircuitSuperstars_VRMod.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Circuit Superstars VR Mod Installer" -ForegroundColor Cyan
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

function Find-CircuitSuperstarsGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Steam installdir is "Circuit Superstars" (two words). The
 # Unity data folder inside is "circuit-superstars_Data"
 # (lowercase + hyphen - reflects the EXE name).
 foreach ($folder in @("Circuit Superstars", "CircuitSuperstars")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\circuit-superstars_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header

Write-Host " Circuit Superstars VR is distributed as a public GitHub" -ForegroundColor White
Write-Host " release. The installer fetches the ZIP directly and" -ForegroundColor White
Write-Host " extracts it." -ForegroundColor White
Write-Host ""
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " This is a GAMEPAD/KEYBOARD mod - no VR controller support." -ForegroundColor White
Write-Host " ViGEmBus is not needed." -ForegroundColor White
Write-Host ""
Write-Host " bHaptics support (VEST only, no arms). If you have a" -ForegroundColor White
Write-Host " bHaptics vest, launch the bHaptics Player and connect" -ForegroundColor White
Write-Host " the vest BEFORE launching the game." -ForegroundColor White
Write-Host ""
Write-Host " The mod offers a first-person toggle (default is third-" -ForegroundColor White
Write-Host " person, the game's native camera). Tunneling is on by" -ForegroundColor White
Write-Host " default in first-person to reduce motion sickness; you" -ForegroundColor White
Write-Host " can disable it in the config file if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " Source repo (info, README, support):" -ForegroundColor Gray
Write-Host " $GITHUB_REPO_URL" -ForegroundColor DarkGray
Write-Host ""
Pause-User "Press Enter to start the install..."

# -------------------------------------------------------
# STEP 1: Locate Circuit Superstars + download mod
# -------------------------------------------------------
Write-Step 1 2 "Locating Circuit Superstars + downloading mod"

$gamePath = Find-CircuitSuperstarsGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1097130" -SteamFolderNames @("Circuit Superstars") }
if ($gamePath) {
 Write-OK "Found Circuit Superstars at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Circuit Superstars in any Steam library."
 Write-Host " Please paste the path to your Circuit Superstars folder" -ForegroundColor White
 Write-Host " (the folder that contains 'circuit-superstars.exe')." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Circuit Superstars folder").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 $gamePath = $r
 Write-OK "Game folder set: $gamePath"
 } else {
 Write-Fail "Folder not found: $r"
 }
 }
}

# Download the mod ZIP from GitHub directly.
$modZip = Join-Path $env:TEMP "CircuitSuperstarsVR_$([System.IO.Path]::GetRandomFileName()).zip"
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

$tempExtract = Join-Path $env:TEMP "CircuitSuperstarsVR_$([System.IO.Path]::GetRandomFileName())"
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
$modDll = Join-Path $gamePath "BepInEx\plugins\CircuitSuperstars_VR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but CircuitSuperstars_VR.dll is missing."
} else {
 Write-OK "BepInEx + CircuitSuperstars_VR.dll present."
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
Write-Host " If you have a bHaptics vest, launch the bHaptics Player" -ForegroundColor White
Write-Host " and connect the vest. The mod detects it at startup." -ForegroundColor White
Write-Host ""
Write-Host " Launch Circuit Superstars normally via Steam, the desktop" -ForegroundColor White
Write-Host " shortcut, or the 'Start in VR' button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Use a GAMEPAD or KEYBOARD+MOUSE - no VR controller support." -ForegroundColor Yellow
Write-Host " Game controls are unchanged." -ForegroundColor Gray
Write-Host ""
Write-Host " VR-specific hotkeys:" -ForegroundColor White
Write-Host " Double-press START on gamepad / F1 on keyboard" -ForegroundColor Gray
Write-Host " -> Toggle first-person view on/off" -ForegroundColor Gray
Write-Host " Hold START on gamepad / F2 on keyboard" -ForegroundColor Gray
Write-Host " -> Recenter VR view" -ForegroundColor Gray
Write-Host ""
Write-Host " Configuration:" -ForegroundColor Gray
Write-Host " The mod ships with a config file at:" -ForegroundColor Gray
Write-Host " BepInEx\config\CircuitSuperstars_VR.cfg" -ForegroundColor DarkGray
Write-Host " Tunable options:" -ForegroundColor Gray
Write-Host " tunneling = true / false" -ForegroundColor Gray
Write-Host " Vignette in first-person to reduce motion sickness." -ForegroundColor Gray
Write-Host " horizonalView = true / false" -ForegroundColor Gray
Write-Host " When true, the game's horizontal plane stays level" -ForegroundColor Gray
Write-Host " with the real world (less in-VR car-tilt feel)." -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to anything else (e.g. winhttp_bak.dll)." -ForegroundColor Gray
Write-Host " Renaming back to winhttp.dll re-activates it." -ForegroundColor Gray
Write-Host ""
Write-Host " Tiny cars, huge corners. Mind the apex." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
