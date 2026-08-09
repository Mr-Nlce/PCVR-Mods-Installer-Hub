# -------------------------------------------------------
# Driftwood VR Mod Installer
# by Astienth - distributed via GitHub
#
# Walks the user through:
# 1. Auto-download mod ZIP from GitHub release + locate
# Driftwood install folder
# 2. Extract mod files in place
#
# GitHub-distributed (public release URL), so the installer
# fetches the ZIP itself via Invoke-WebRequest. No drag-drop,
# no Discord, no manual download.
#
# This is a motion-controls mod with full body-lean gameplay:
# - Lean left/right in real life to steer
# - Lean forward to accelerate
# - Raise BOTH hands above your head for air break
# The left joystick (steering) ALWAYS prevails over the
# motion gaming movements - lean-to-turn is additive.
#
# VR-controller input goes directly through OpenVR/SteamVR -
# no virtual gamepad layer, so no ViGEmBus step needed.
#
# bHaptics support (vest + arms) bundled in.
#
# Naming pitfall: the GitHub ZIP filename has a typo -
# "Drifwood" (one 'f'), not "Driftwood". The repo name uses
# capital W ("DriftWood_VR_bHaptics"). The game itself, the
# install folder, and the DLL all use the correct two-'f'
# spelling. Don't second-guess - the URL is right.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "Driftwood_VR"
$MOD_VERSION = "v1.0 (bHaptics)"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "2223700"
$GAME_NAME = "Driftwood"

# GitHub URLs - direct, no login required.
# Note: ZIP filename has the "Drifwood" typo (one 'f') and the
# repo name capitalises the W. Both are intentional - that's
# how Astienth published the release.
$GITHUB_REPO_URL = "https://github.com/Astienth/DriftWood_VR_bHaptics"
$GITHUB_DOWNLOAD_URL = "https://github.com/Astienth/DriftWood_VR_bHaptics/releases/download/1.0/Drifwood_VRMod_bHaptics.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Driftwood VR Mod Installer" -ForegroundColor Cyan
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

function Find-DriftwoodGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Steam installdir is "Driftwood" (single word, no spaces).
 # The Unity data folder mirrors that as "Driftwood_Data".
 # Demo (during early-access period) used the same naming
 # but with " Demo" suffix; we try that as a last resort.
 foreach ($folder in @("Driftwood", "Driftwood Demo")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\Driftwood_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header

Write-Host " Driftwood VR is distributed as a public GitHub release." -ForegroundColor White
Write-Host " The installer fetches the ZIP directly and extracts it." -ForegroundColor White
Write-Host ""
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " This is a MOTION CONTROLS mod with full body lean:" -ForegroundColor White
Write-Host " - Lean left / right to steer" -ForegroundColor White
Write-Host " - Lean forward to accelerate" -ForegroundColor White
Write-Host " - Raise BOTH hands above your head for air break" -ForegroundColor White
Write-Host " The left joystick (steering) always overrides motion" -ForegroundColor White
Write-Host " gaming - they're additive, joystick wins." -ForegroundColor White
Write-Host ""
Write-Host " Stand-up VR play is recommended for the lean motions to" -ForegroundColor White
Write-Host " feel right." -ForegroundColor White
Write-Host ""
Write-Host " No ViGEmBus needed - VR controllers wire directly through" -ForegroundColor White
Write-Host " OpenVR/SteamVR." -ForegroundColor White
Write-Host ""
Write-Host " bHaptics support is bundled in (vest + arms). If you have" -ForegroundColor White
Write-Host " bHaptics gear, launch the bHaptics Player and turn the" -ForegroundColor White
Write-Host " devices on BEFORE launching the game." -ForegroundColor White
Write-Host ""
Write-Host " Source repo (info, README, support):" -ForegroundColor Gray
Write-Host " $GITHUB_REPO_URL" -ForegroundColor DarkGray
Write-Host ""
Pause-User "Press Enter to start the install..."

# -------------------------------------------------------
# STEP 1: Locate Driftwood + download mod
# -------------------------------------------------------
Write-Step 1 2 "Locating Driftwood + downloading mod"

$gamePath = Find-DriftwoodGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "2223700" -SteamFolderNames @("Driftwood") }
if ($gamePath) {
 Write-OK "Found Driftwood at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Driftwood in any Steam library."
 Write-Host " Please paste the path to your Driftwood folder" -ForegroundColor White
 Write-Host " (the folder that contains 'Driftwood.exe')." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Driftwood folder").Trim().Trim('"')
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
$modZip = Join-Path $env:TEMP "DriftwoodVR_$([System.IO.Path]::GetRandomFileName()).zip"
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

$tempExtract = Join-Path $env:TEMP "DriftwoodVR_$([System.IO.Path]::GetRandomFileName())"
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
$modDll = Join-Path $gamePath "BepInEx\plugins\Driftwood_VR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but Driftwood_VR.dll is missing."
} else {
 Write-OK "BepInEx + Driftwood_VR.dll present."
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
Write-Host " and turn the devices on. The mod detects them at startup." -ForegroundColor White
Write-Host ""
Write-Host " Launch Driftwood normally via Steam, the desktop shortcut," -ForegroundColor White
Write-Host " or the" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Controls:" -ForegroundColor White
Write-Host " Left stick -> Steering / accelerate / air brake / UI" -ForegroundColor Gray
Write-Host " up = accelerate, down = air brake," -ForegroundColor Gray
Write-Host " left/right = steer" -ForegroundColor Gray
Write-Host " Right stick -> Look around (click = pause menu)" -ForegroundColor Gray
Write-Host " A button -> Confirm / Push skate" -ForegroundColor Gray
Write-Host " B button -> Cancel / Back" -ForegroundColor Gray
Write-Host " Y button -> Map" -ForegroundColor Gray
Write-Host " X button -> Hold to restart track / UI function" -ForegroundColor Gray
Write-Host " Left trigger -> Hand brake (left)" -ForegroundColor Gray
Write-Host " Right trigger -> Hand brake (right)" -ForegroundColor Gray
Write-Host " Right grip -> HotKey modifier (see combos below)" -ForegroundColor Gray
Write-Host ""
Write-Host " Hotkey combos (hold Right Grip + ...):" -ForegroundColor Cyan
Write-Host " L stick click + R stick click -> Recenter view" -ForegroundColor Gray
Write-Host " RG + L stick click -> Toggle 1st/3rd person" -ForegroundColor Gray
Write-Host " RG + L stick up / down -> Switch wheels" -ForegroundColor Gray
Write-Host " RG + L stick left / right -> Switch board" -ForegroundColor Gray
Write-Host " RG + Y -> Skip song" -ForegroundColor Gray
Write-Host ""
Write-Host " MOTION GAMING:" -ForegroundColor Cyan
Write-Host " Lean left / right -> Steer (joystick still wins)" -ForegroundColor Gray
Write-Host " Lean forward -> Accelerate" -ForegroundColor Gray
Write-Host " BOTH hands above head -> Air break" -ForegroundColor Gray
Write-Host ""
Write-Host " A picture of these controls is bundled with the mod at:" -ForegroundColor Gray
Write-Host " $gamePath\VRControls.jpg" -ForegroundColor DarkGray
Write-Host ""
Write-Host " Features:" -ForegroundColor Gray
Write-Host " - Full body-lean motion controls" -ForegroundColor Gray
Write-Host " - bHaptics support (vest + arms)" -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to anything else (e.g. winhttp_bak.dll)." -ForegroundColor Gray
Write-Host " Renaming back to winhttp.dll re-activates it." -ForegroundColor Gray
Write-Host ""
Write-Host " Catch the ramp. Catch the line. Catch some air." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
