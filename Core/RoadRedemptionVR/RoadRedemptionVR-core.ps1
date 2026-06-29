# -------------------------------------------------------
# Road Redemption VR Mod Installer
# by Astienth - distributed via GitHub
#
# Walks the user through:
# 1. Auto-download mod ZIP from GitHub release + locate
# Road Redemption install folder
# 2. Extract mod files in place
# 3. ViGEmBus install (REQUIRED for VR controllers)
#
# This is the FIRST Astienth mod distributed via public
# GitHub instead of Discord-gated. Because the download URL
# is public and direct, the installer fetches the ZIP itself
# via Invoke-WebRequest - no manual drag-and-drop needed.
#
# This is a motion-controls mod with VR controllers mapped
# as Xbox controllers, plus motion-gesture attacks (throw
# your arm to swing weapons). bHaptics support included.
#
# Important: NOT compatible with the Epic Store version of
# the game - Steam version only.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "RoadRedemption_VR"
$MOD_VERSION = "v1.0.0 (bHaptics)"
$MOD_AUTHOR = "Astienth"

$GAME_APPID = "300380"
$GAME_NAME = "Road Redemption"

# GitHub URLs - direct, no login required.
$GITHUB_REPO_URL = "https://github.com/AstienVR/Road_Redemption_VR_bHaptics"
$GITHUB_DOWNLOAD_URL = "https://github.com/AstienVR/Road_Redemption_VR_bHaptics/releases/download/1.0/RoadRedemptionVR.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Road Redemption VR Mod Installer" -ForegroundColor Cyan
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

function Find-RoadRedemptionGamePath {
 $sp = Get-SteamPath
 if (-not $sp) { return $null }
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 # Steam installdir is "Road Redemption" (with space) but
 # the Unity data folder is "RoadRedemption_Data" (no space).
 # Presence of RoadRedemption_Data is the strongest signal
 # we found the right install. The mod is not compatible
 # with Epic Store, so we don't bother scanning Epic paths.
 foreach ($folder in @("Road Redemption", "RoadRedemption", "Road Redemption Demo")) {
 $candidate = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path (Join-Path $candidate "RoadRedemption_Data")) { return $candidate }
 if (Test-Path $candidate) { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# Intro: explain what's about to happen
# -------------------------------------------------------
Write-Header

Write-Host " Road Redemption VR is distributed as a public GitHub" -ForegroundColor White
Write-Host " release. The installer fetches the ZIP directly and" -ForegroundColor White
Write-Host " extracts it." -ForegroundColor White
Write-Host ""
Write-Host " IMPORTANT BEFORE INSTALLING:" -ForegroundColor Yellow
Write-Host " ----------------------------" -ForegroundColor Yellow
Write-Host " This mod is NOT compatible with the Epic Store version" -ForegroundColor White
Write-Host " of the game - Steam version ONLY." -ForegroundColor White
Write-Host ""
Write-Host " This mod uses OpenVR by default. OpenXR is supported" -ForegroundColor White
Write-Host " via a config edit if you prefer." -ForegroundColor White
Write-Host ""
Write-Host " This is a MOTION CONTROLS mod with VR controllers mapped" -ForegroundColor White
Write-Host " as an Xbox controller, plus motion-gesture attacks. To" -ForegroundColor White
Write-Host " use VR controllers you MUST install ViGEmBus (the" -ForegroundColor White
Write-Host " installer can do it for you in step 3)." -ForegroundColor White
Write-Host ""
Write-Host " Features included: bHaptics support (vest + arms)." -ForegroundColor White
Write-Host ""
Write-Host " Source repo (info, README, support):" -ForegroundColor Gray
Write-Host " $GITHUB_REPO_URL" -ForegroundColor DarkGray
Write-Host ""
Pause-User "Press Enter to start the install..."

# -------------------------------------------------------
# STEP 1: Locate the Road Redemption install + download mod
# -------------------------------------------------------
Write-Step 1 3 "Locating Road Redemption + downloading mod"

$gamePath = Find-RoadRedemptionGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "300380" -SteamFolderNames @("Road Redemption") }
if ($gamePath) {
 Write-OK "Found Road Redemption at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Road Redemption in any Steam library."
 Write-Host " Please paste the path to your Road Redemption folder" -ForegroundColor White
 Write-Host " (the folder that contains 'RoadRedemption.exe')." -ForegroundColor White
 Write-Host ""
 Write-Host " Reminder: this mod only works with the STEAM version." -ForegroundColor Yellow
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Road Redemption folder").Trim().Trim('"')
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
$modZip = Join-Path $env:TEMP "RoadRedemptionVR_$([System.IO.Path]::GetRandomFileName()).zip"
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
Write-Step 2 3 "Installing mod files"

$tempExtract = Join-Path $env:TEMP "RoadRedemptionVR_$([System.IO.Path]::GetRandomFileName())"
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
$modDll = Join-Path $gamePath "BepInEx\plugins\RoadRedemption_VR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx is there but RoadRedemption_VR.dll is missing."
} else {
 Write-OK "BepInEx + RoadRedemption_VR.dll present."
}

# -------------------------------------------------------
# STEP 3: ViGEmBus driver (REQUIRED for VR controllers)
# -------------------------------------------------------
Write-Step 3 3 "ViGEmBus driver (REQUIRED for VR controllers)"

Write-Host " Road Redemption VR maps your VR controllers to a virtual" -ForegroundColor Gray
Write-Host " Xbox gamepad through ViGEmBus. Without this driver" -ForegroundColor Gray
Write-Host " installed, the game won't accept your VR controller" -ForegroundColor Gray
Write-Host " input." -ForegroundColor Gray
Write-Host ""
Write-Host " If you've already installed ViGEmBus (e.g. for another" -ForegroundColor White
Write-Host " Astienth mod, Virtual Desktop, or any controller-emulation" -ForegroundColor White
Write-Host " software), you can safely skip this." -ForegroundColor White
Write-Host ""

$vigemExe = Get-ChildItem -Path (Join-Path $gamePath "BepInEx\redist") -Filter "ViGEmBus_*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

# Detect an existing ViGEmBus install so users who already have it
# (very common - it ships with many VR mods, Virtual Desktop, DS4Windows,
# etc.) can just press Enter. Re-installing stays available via V.
$vigemPresent = $false
try { $vigemPresent = Test-ViGEmBusInstalled } catch { $vigemPresent = $false }

if ($vigemExe -and $vigemPresent) {
 Write-OK "ViGEmBus already detected on this PC."
 Write-Host ""
 Write-Host " Press ENTER to continue to the next step (recommended)." -ForegroundColor White
 Write-Host " If your VR controllers give you trouble, you can (re)install" -ForegroundColor Gray
 Write-Host " it: type V then Enter." -ForegroundColor Gray
 $reinst = (Read-Host " [Enter] skip / [V] reinstall").Trim()
 if ($reinst -in @("v","V")) {
 Write-Host ""
 Write-Host " Running ViGEmBus setup - approve the Windows admin prompt..." -ForegroundColor Gray
 $attempts = @(
 @{ VArgs = "/quiet /norestart"; Label = "silent" },
 @{ VArgs = "/passive /norestart"; Label = "with progress bar" },
 @{ VArgs = ""; Label = "interactive" }
 )
 $vigemDone = $false
 foreach ($attempt in $attempts) {
 try {
 if ($attempt.VArgs) {
 $proc = Start-Process -FilePath $vigemExe.FullName -ArgumentList $attempt.VArgs -Wait -PassThru -ErrorAction Stop
 } else {
 $proc = Start-Process -FilePath $vigemExe.FullName -Wait -PassThru -ErrorAction Stop
 }
 if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
 Write-OK "ViGEmBus installed ($($attempt.Label))."
 $vigemDone = $true
 break
 } elseif ($proc.ExitCode -eq 1602) {
 Write-Info "ViGEmBus setup cancelled by user."
 $vigemDone = $true
 break
 } else {
 Write-Host " Tried $($attempt.Label) mode - exit $($proc.ExitCode), trying next..." -ForegroundColor DarkGray
 }
 } catch {
 Write-Host " Tried $($attempt.Label) mode - threw error, trying next..." -ForegroundColor DarkGray
 }
 }
 if (-not $vigemDone) {
 Write-Warn "ViGEmBus setup didn't complete cleanly. You can run it manually:"
 Write-Host " $($vigemExe.FullName)" -ForegroundColor DarkGray
 }
 } else {
 Write-Info "Keeping the existing ViGEmBus install."
 }
}
elseif ($vigemExe) {
 Write-Host " The mod ZIP includes the ViGEmBus setup file." -ForegroundColor White
 Write-Host " File: $($vigemExe.Name)" -ForegroundColor DarkGray
 Write-Host ""
 Write-Host " >>> [Y] Install ViGEmBus now (required for VR controllers)" -ForegroundColor Yellow
 Write-Host " >>> [N] Skip - already installed, or I'll use a real gamepad" -ForegroundColor Gray
 $choice = ""
 while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host " Your choice (Y/N)").Trim() }
 if ($choice -in @("y","Y")) {
 Write-Host ""
 Write-Host " Running ViGEmBus setup - approve the Windows admin prompt..." -ForegroundColor Gray
 $attempts = @(
 @{ VArgs = "/quiet /norestart"; Label = "silent" },
 @{ VArgs = "/passive /norestart"; Label = "with progress bar" },
 @{ VArgs = ""; Label = "interactive" }
 )
 $vigemDone = $false
 foreach ($attempt in $attempts) {
 try {
 if ($attempt.VArgs) {
 $proc = Start-Process -FilePath $vigemExe.FullName -ArgumentList $attempt.VArgs -Wait -PassThru -ErrorAction Stop
 } else {
 $proc = Start-Process -FilePath $vigemExe.FullName -Wait -PassThru -ErrorAction Stop
 }
 if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
 Write-OK "ViGEmBus installed ($($attempt.Label))."
 $vigemDone = $true
 break
 } elseif ($proc.ExitCode -eq 1602) {
 Write-Info "ViGEmBus setup cancelled by user."
 $vigemDone = $true
 break
 } else {
 Write-Host " Tried $($attempt.Label) mode - exit $($proc.ExitCode), trying next..." -ForegroundColor DarkGray
 }
 } catch {
 Write-Host " Tried $($attempt.Label) mode - threw error, trying next..." -ForegroundColor DarkGray
 }
 }
 if (-not $vigemDone) {
 Write-Warn "ViGEmBus setup didn't complete cleanly. You can run it manually:"
 Write-Host " $($vigemExe.FullName)" -ForegroundColor DarkGray
 }
 } else {
 Write-Info "ViGEmBus skipped. If your VR controllers don't work in-game,"
 Write-Info "come back and run the setup manually:"
 Write-Host " $($vigemExe.FullName)" -ForegroundColor DarkGray
 }
} else {
 Write-Warn "ViGEmBus installer not found in BepInEx\redist - the mod ZIP may be a different version."
 Write-Info "If your VR controllers don't work in-game, look for ViGEmBus_*.exe inside the mod folder."
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
Write-Host " Launch Road Redemption normally via Steam, the desktop" -ForegroundColor White
Write-Host " shortcut, or the 'Start in VR' button in the Hub." -ForegroundColor White
Write-Host ""
Write-Host " Controls:" -ForegroundColor White
Write-Host " - VR controllers map EXACTLY as an Xbox controller" -ForegroundColor Gray
Write-Host " (ABXY = same buttons, grips = LB/RB, triggers = LT/RT)" -ForegroundColor Gray
Write-Host " - Recenter VR view: hold the X button for 1.5 seconds" -ForegroundColor Gray
Write-Host ""
Write-Host " VR MOTION GESTURES (weapon attacks):" -ForegroundColor Cyan
Write-Host " Throw your LEFT arm toward your left side -> Left attack" -ForegroundColor Gray
Write-Host " Throw your RIGHT arm toward your right side -> Right attack" -ForegroundColor Gray
Write-Host " Works with melee weapons like baseball bats and metal pipes." -ForegroundColor Gray
Write-Host ""
Write-Host " Features:" -ForegroundColor Gray
Write-Host " - Third-person view (default, like the original game)" -ForegroundColor Gray
Write-Host " - First-person view: basic and full-immersive modes" -ForegroundColor Gray
Write-Host " - bHaptics support (vest + arms)" -ForegroundColor Gray
Write-Host ""
Write-Host " Configuration:" -ForegroundColor Gray
Write-Host " The config file is created AFTER your first launch with" -ForegroundColor Gray
Write-Host " the mod, at:" -ForegroundColor Gray
Write-Host " BepInEx\config\RoadRedemption_VR.cfg" -ForegroundColor DarkGray
Write-Host ""
Write-Host " Options:" -ForegroundColor Gray
Write-Host " firstPersonView = true (enable first-person)" -ForegroundColor Gray
Write-Host " firstPersonViewFull = true (head follows player rotation)" -ForegroundColor Gray
Write-Host " vignette = true (motion-sickness vignette)" -ForegroundColor Gray
Write-Host " maxVignetteValue = 0-100 (vignette intensity, 100 max)" -ForegroundColor Gray
Write-Host " fixValveIndex = true (fix UI scaling for Valve Index" -ForegroundColor Gray
Write-Host " if it appears too large)" -ForegroundColor Gray
Write-Host ""
Write-Host " Switch runtime to OpenXR (default is OpenVR):" -ForegroundColor Gray
Write-Host " Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor DarkGray
Write-Host " vrApi = OpenXR" -ForegroundColor Gray
Write-Host ""
Write-Host " To deactivate the mod later: rename winhttp.dll in the" -ForegroundColor Gray
Write-Host " game folder to winhttp_bak.dll" -ForegroundColor Gray
Write-Host ""
Write-Host " Two wheels, one bat. Pavement remembers." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
