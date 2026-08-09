# -------------------------------------------------------
# Bomb Rush Cyberfunk VR Mod Installer
# by Astienth - distributed via GitHub
#
# Walks the user through:
# 1. Auto-download mod ZIP from GitHub release + locate
# Bomb Rush Cyberfunk install folder
# 2. Extract mod files in place
#
# Like Road Redemption, this is a public GitHub release -
# the installer fetches the ZIP itself via Invoke-WebRequest.
# No drag-drop, no Discord, no manual download.
#
# Unlike Road Redemption, this mod does NOT bundle ViGEmBus.
# Bomb Rush Cyberfunk's third-person mode uses gamepad input
# natively. First-person mode adds VR-controller hand support
# via the mod, but no virtual gamepad mapping is involved -
# so we don't need the ViGEm step.
#
# The mod defaults to third-person view. To get the VR-hands
# experience, the user has to flip a config flag AFTER the
# first launch (firstPerson = true).
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "BombRushCyberFunk_VR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "1353230"
$GAME_NAME = "Bomb Rush Cyberfunk"

# GitHub URLs - direct, no login required.
$GITHUB_REPO_URL = "https://github.com/AstienVR/Bomb_Rush_Cyberfunk_VR"
$GITHUB_DOWNLOAD_URL = "https://github.com/AstienVR/Bomb_Rush_Cyberfunk_VR/releases/download/1.0.0/BombRushCyberFunk_VR.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Bomb Rush Cyberfunk VR Mod Installer" -ForegroundColor Cyan
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

function Find-BombRushCyberfunkGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Steam installdir is "Bomb Rush Cyberfunk" (with spaces,
 # lowercase 'f' in "funk"). The Unity data folder mirrors
 # that as "Bomb Rush Cyberfunk_Data". Note that the mod
 # itself uses CamelCase "BombRushCyberFunk_VR.dll" with a
 # capital F - that's only inside BepInEx\plugins.
 foreach ($folder in @("Bomb Rush Cyberfunk", "BombRushCyberfunk", "BombRushCyberFunk", "Bomb Rush Cyberfunk Demo")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path -LiteralPath "$candidate\Bomb Rush Cyberfunk_Data") { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# Intro: explain what's about to happen
# -------------------------------------------------------
Write-Header

Write-Host " Bomb Rush Cyberfunk VR is distributed as a public GitHub" -ForegroundColor White
Write-Host " release. The installer fetches the ZIP directly and" -ForegroundColor White
Write-Host " extracts it." -ForegroundColor White
Write-Host ""
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " This is a power-HIGH mod (RTX 4080-class GPU recommended)." -ForegroundColor White
Write-Host " The graphics-heavy graffiti world is the bottleneck." -ForegroundColor White
Write-Host ""
Write-Host " TWO VIEW MODES:" -ForegroundColor White
Write-Host " THIRD-PERSON (default): play with a gamepad. The game" -ForegroundColor White
Write-Host " renders in VR but the camera follows your character" -ForegroundColor White
Write-Host " from outside, like the original game." -ForegroundColor White
Write-Host " FIRST-PERSON (config flag): VR controllers act as your" -ForegroundColor White
Write-Host " hands. Strong VR legs recommended for full-immersive" -ForegroundColor White
Write-Host " mode (camera follows head movements at all times)." -ForegroundColor White
Write-Host " Switch modes by editing BepInEx\config\BombRushCyberFunk_VR.cfg" -ForegroundColor White
Write-Host " AFTER your first launch with the mod installed." -ForegroundColor White
Write-Host ""
Write-Host " NO ViGEmBus is needed - this mod doesn't bundle it." -ForegroundColor White
Write-Host ""
Write-Host " Source repo (info, README, support):" -ForegroundColor Gray
Write-Host " $GITHUB_REPO_URL" -ForegroundColor DarkGray
Write-Host ""
Pause-User "Press Enter to start the install..."

# -------------------------------------------------------
# STEP 1: Locate the Bomb Rush Cyberfunk install + download mod
# -------------------------------------------------------
Write-Step 1 2 "Locating Bomb Rush Cyberfunk + downloading mod"

$gamePath = Find-BombRushCyberfunkGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1353230" -SteamFolderNames @("Bomb Rush Cyberfunk") -GogNames @("Bomb Rush Cyberfunk") }
if ($gamePath) {
 Write-OK "Found Bomb Rush Cyberfunk at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Bomb Rush Cyberfunk in any Steam library."
 Write-Host " Please paste the path to your Bomb Rush Cyberfunk folder" -ForegroundColor White
 Write-Host " (the folder that contains 'Bomb Rush Cyberfunk.exe')." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Bomb Rush Cyberfunk folder").Trim().Trim('"')
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
$modZip = Join-Path $env:TEMP "BombRushCyberFunkVR_$([System.IO.Path]::GetRandomFileName()).zip"
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

$tempExtract = Join-Path $env:TEMP "BombRushCyberFunkVR_$([System.IO.Path]::GetRandomFileName())"
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
$modDll = Join-Path $gamePath "BepInEx\plugins\BombRushCyberFunk_VR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but BombRushCyberFunk_VR.dll is missing."
} else {
 Write-OK "BepInEx + BombRushCyberFunk_VR.dll present."
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
Write-Host " Launch Bomb Rush Cyberfunk normally via Steam, the desktop" -ForegroundColor White
Write-Host " shortcut, or the" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Default after install: THIRD-PERSON view with gamepad." -ForegroundColor Yellow
Write-Host " Switch to first-person + VR controllers via config (below)." -ForegroundColor Gray
Write-Host ""
Write-Host " THIRD-PERSON (default):" -ForegroundColor Cyan
Write-Host " Use a gamepad. Recenter VR view: hold the START button." -ForegroundColor Gray
Write-Host ""
Write-Host " FIRST-PERSON (firstPerson = true):" -ForegroundColor Cyan
Write-Host " VR controllers map EXACTLY as an Xbox controller:" -ForegroundColor Gray
Write-Host " X button -> Trick 1" -ForegroundColor Gray
Write-Host " Y button -> Trick 2" -ForegroundColor Gray
Write-Host " B button -> Trick 3 / Cancel in menus" -ForegroundColor Gray
Write-Host " A button -> Jump / Validate in menus" -ForegroundColor Gray
Write-Host " Left joystick -> Move" -ForegroundColor Gray
Write-Host " Right joystick -> Rotate camera" -ForegroundColor Gray
Write-Host " Left grip (LB) -> Dash / turbo" -ForegroundColor Gray
Write-Host " Right grip (RB) -> Slide" -ForegroundColor Gray
Write-Host " Left trigger (LT)-> Toggle style" -ForegroundColor Gray
Write-Host " Right trigger(RT)-> Interact" -ForegroundColor Gray
Write-Host " Recenter VR view: click and HOLD the left joystick." -ForegroundColor Gray
Write-Host ""
Write-Host " HOTKEY GESTURE (D-Pad replacement):" -ForegroundColor Cyan
Write-Host " VR controllers don't have a D-Pad, so it's mapped via" -ForegroundColor Gray
Write-Host " a hotkey: PRESS AND HOLD the right-stick click FIRST," -ForegroundColor Gray
Write-Host " THEN tilt or click the left stick:" -ForegroundColor Gray
Write-Host " Hotkey + Left stick tilt -> D-Pad up/down/left/right" -ForegroundColor Gray
Write-Host " Hotkey + Left stick click -> Dance menu" -ForegroundColor Gray
Write-Host ""
Write-Host " Known issue: in the character selection screen the" -ForegroundColor Gray
Write-Host " left stick can be a little tricky to trigger - keep" -ForegroundColor Gray
Write-Host " insisting." -ForegroundColor Gray
Write-Host ""
Write-Host " Configuration:" -ForegroundColor Gray
Write-Host " The config file is created AFTER your first launch with" -ForegroundColor Gray
Write-Host " the mod, at:" -ForegroundColor Gray
Write-Host " BepInEx\config\BombRushCyberFunk_VR.cfg" -ForegroundColor DarkGray
Write-Host ""
Write-Host " Options:" -ForegroundColor Gray
Write-Host " firstPerson = true (enable first-person + VR" -ForegroundColor Gray
Write-Host " hands; default is false)" -ForegroundColor Gray
Write-Host " fullImmersive = true (only with firstPerson = true:" -ForegroundColor Gray
Write-Host " head fully follows in-game" -ForegroundColor Gray
Write-Host " head movements - needs strong" -ForegroundColor Gray
Write-Host " VR legs)" -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " Tag the city. Outrun the cops. Drop the beat." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
