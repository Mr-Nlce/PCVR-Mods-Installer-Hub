# ============================================================
# Starfield VR Mod Installer
# starfield2vr by mutars (based on PrayDog's REFramework)
# Two choices up front:
# 1) Runtime: OpenVR (SteamVR) or OpenXR
# 2) Store: Steam or Xbox Game Pass (PC)
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Starfield VR Mod Installer"
$ErrorActionPreference = "Stop"

$MOD_VERSION = "v2.0.0.Public"
$MOD_INFO_URL = "https://github.com/mutars/starfield2vr"
$MOD_URL_OPENVR = "https://github.com/mutars/starfield2vr/releases/download/v2.0.0.Public/starfield-vr-openvr-v2.0.0.Public.zip"
$MOD_URL_OPENXR = "https://github.com/mutars/starfield2vr/releases/download/v2.0.0.Public/starfield-vr-openxr-v2.0.0.Public.zip"
$VIGEMBUS_URL = "https://github.com/nefarius/ViGEmBus/releases/download/v1.22.0/ViGEmBus_1.22.0_x64_x86_arm64.exe"

$STEAM_FOLDER = "Starfield"
$GAMEPASS_PATH = "C:\XboxGames\Starfield\Content"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Starfield VR Mod Installer" -ForegroundColor Cyan
 Write-Host " starfield2vr $MOD_VERSION by mutars" -ForegroundColor Gray
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
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try {
 $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
 if ($p -and (Test-Path $p)) { return $p }
 } catch {}
 }
 return $null
}

function Get-SteamLibraries {
 param($steamPath)
 $libraries = @($steamPath)
 $vdfPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
 if (Test-Path $vdfPath) {
 $content = Get-Content $vdfPath -Raw
 $found = [regex]::Matches($content, '"path"\s+"([^"]+)"')
 foreach ($m in $found) {
 $lib = $m.Groups[1].Value -replace '\\\\', '\'
 if (Test-Path $lib) { $libraries += $lib }
 }
 }
 return $libraries
}

# -------------------------------------------------------
# Runtime choice
# -------------------------------------------------------
Write-Header

Write-Host " Which VR runtime do you use?" -ForegroundColor White
Write-Host ""
Write-Host " [1] OpenVR (SteamVR)" -ForegroundColor Yellow
Write-Host " [2] OpenXR (native OpenXR runtime - Oculus / Virtual Desktop / etc.)" -ForegroundColor Yellow
Write-Host ""
Write-Host " If you are unsure and you primarily use SteamVR, pick [1]." -ForegroundColor Gray
Write-Host ""

$runtimeChoice = ""
while ($runtimeChoice -notin @("1","2")) { $runtimeChoice = (Read-Host " Your choice (1/2)").Trim() }
$useOpenXR = ($runtimeChoice -eq "2")
$runtimeLabel = if ($useOpenXR) { "OpenXR" } else { "OpenVR (SteamVR)" }
$modUrl = if ($useOpenXR) { $MOD_URL_OPENXR } else { $MOD_URL_OPENVR }

# -------------------------------------------------------
# Store choice
# -------------------------------------------------------
Write-Host ""

# -------------------------------------------------------
# STEP 1: Locate Starfield (auto-detect Steam / Gamepass)
# -------------------------------------------------------
Write-Step 1 4 "Locating Starfield"

$gamePath = $null
$storeLabel = $null
$isGamepass = $false

# Load the detection library
try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
 . $__utilsPath
 $det = Find-GameInstall -GameName "Starfield" `
 -Steam @{ Folder = $STEAM_FOLDER } `
 -Gamepass @{ Folder = "Starfield"; ContentSubfolder = $true } `
 -ExeName "Starfield.exe"

 if ($det.Candidates.Count -gt 1) {
 # Multiple installs found - ask the user which one to mod
 Write-Host " Multiple Starfield installs detected:" -ForegroundColor White
 Write-Host ""
 for ($i = 0; $i -lt $det.Candidates.Count; $i++) {
 $c = $det.Candidates[$i]
 Write-Host " [$($i+1)] $($c.Source)" -ForegroundColor Yellow
 Write-Host " $($c.Path)" -ForegroundColor Gray
 }
 Write-Host ""
 $pick = ""
 while (-not ($pick -as [int]) -or [int]$pick -lt 1 -or [int]$pick -gt $det.Candidates.Count) {
 $pick = (Read-Host " Your choice (1-$($det.Candidates.Count))").Trim()
 }
 $chosen = $det.Candidates[[int]$pick - 1]
 $gamePath = $chosen.Path
 $storeLabel = if ($chosen.Source -like "Gamepass*") { "Xbox Game Pass" } else { "Steam" }
 $isGamepass = ($chosen.Source -like "Gamepass*")
 }
 elseif ($det.Found) {
 $gamePath = $det.Path
 $storeLabel = if ($det.Source -like "Gamepass*") { "Xbox Game Pass" } else { "Steam" }
 $isGamepass = ($det.Source -like "Gamepass*")
 Write-OK "Found via $($det.Source): $gamePath"
 }
 }
} catch {
 Write-Info "Detection library not available, falling back to manual input."
}

# Manual fallback - if auto-detection found nothing
if (-not $gamePath) {
 Write-Warn "Starfield was not auto-detected."
 Write-Host " Please pick your install type and enter the game folder:" -ForegroundColor White
 Write-Host ""
 Write-Host " [1] Steam" -ForegroundColor Yellow
 Write-Host " [2] Xbox Game Pass / Microsoft Store" -ForegroundColor Yellow
 Write-Host ""
 $storeChoice = ""
 while ($storeChoice -notin @("1","2")) { $storeChoice = (Read-Host " Your choice (1/2)").Trim() }
 $isGamepass = ($storeChoice -eq "2")
 $storeLabel = if ($isGamepass) { "Xbox Game Pass" } else { "Steam" }
 Write-Host ""
 if ($isGamepass) {
 Write-Host " Game Pass install folder (contains Starfield.exe, usually in ...\Content):" -ForegroundColor White
 } else {
 Write-Host " Steam install folder (contains Starfield.exe):" -ForegroundColor White
 }
 while (-not $gamePath) {
 $rawInput = (Read-Host " Starfield path").Trim().Trim('"')
 if (Test-Path $rawInput) { $gamePath = $rawInput; Write-OK "Game path set: $gamePath" }
 else { Write-Fail "Path not found: $rawInput" }
 }
}

Write-Info "Using: $storeLabel ($gamePath)"

$starfieldExe = Join-Path $gamePath "Starfield.exe"
if (-not (Test-Path $starfieldExe)) {
 Write-Warn "Starfield.exe not found in the game folder."
 Write-Host " Continuing anyway - make sure you picked the right folder." -ForegroundColor Gray
}

# -------------------------------------------------------
# STEP 2: Download & install the VR mod
# -------------------------------------------------------
Write-Step 2 4 "Downloading starfield2vr ($runtimeLabel)"

[System.Net.ServicePointManager]::SecurityProtocol = `
 [System.Net.ServicePointManager]::SecurityProtocol -bor `
 [System.Net.SecurityProtocolType]::Tls12

$tempDir = Join-Path $env:TEMP "StarfieldVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$zipPath = Join-Path $tempDir "starfield2vr.zip"
$extractDir = Join-Path $tempDir "extract"

Write-Host " Downloading from GitHub ... " -NoNewline -ForegroundColor White
try {
 Invoke-WebRequest -Uri $modUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Download error: $_"
 $__fb = Invoke-InstallerFallback -Action ".NET runtime download" `
 -Url "https://dotnet.microsoft.com/download/dotnet/7.0" `
 -Instructions "Install .NET 7 Desktop Runtime manually from https://dotnet.microsoft.com/download/dotnet/7.0 (x64 build)." `
 -SkipMessage "Skipped - the tool that needs .NET will not run; you can install .NET later and re-run." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-detect .NET 7 Desktop Runtime
 if (Test-DotNet7Desktop) {
 Write-OK ".NET 7 Desktop Runtime detected."
 } else {
 Pause-User "Still no .NET 7. Install it then re-run. Press Enter to exit..."
 exit 1
 }
 }
 # User chose Skip - continue at own risk
}

Write-Host " Extracting ... " -NoNewline -ForegroundColor White
try {
 Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Extract error: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$zipPath' with 7-Zip or Windows Explorer, and extract its contents into '$extractDir'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder "$zipPath" `
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

# Payload is a flat set of DLLs - merge into game root.
Write-Host " Copying mod files into game folder ... " -NoNewline -ForegroundColor White
try {
 $rc = @($extractDir, $gamePath, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/R:2", "/W:1")
 & robocopy @rc | Out-Null
 if ($LASTEXITCODE -ge 8) { throw "robocopy exit code $LASTEXITCODE" }
 Write-Host "OK" -ForegroundColor Green
 Write-OK "Mod files installed."
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Copy error: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open the archive in the temp folder (path printed by the installer just above) with 7-Zip, and extract its contents into '$extractDir'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
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

try { Remove-Item $tempDir -Recurse -Force } catch {}

# -------------------------------------------------------
# STEP 3: ViGEmBus driver (required for motion controllers as gamepad)
# -------------------------------------------------------
Write-Step 3 4 "ViGEmBus driver"

Write-Host " Starfield has no native motion-controller support, so the mod" -ForegroundColor White
Write-Host " emulates a virtual Xbox gamepad for controller input. That" -ForegroundColor White
Write-Host " requires the ViGEmBus driver (from Nefarius, widely used and" -ForegroundColor White
Write-Host " open source)." -ForegroundColor White
Write-Host ""
Write-Host " If you already have ViGEmBus installed (e.g. for DS4Windows" -ForegroundColor Gray
Write-Host " or another VR mod in this hub), you can skip this step." -ForegroundColor Gray
Write-Host ""

# Detect an existing ViGEmBus install so users who already have it can
# just press Enter. Re-installing stays available via V. If it's not
# detected, fall back to the normal Y/N prompt below.
$vigemPresent = $false
try { $vigemPresent = Test-ViGEmBusInstalled } catch { $vigemPresent = $false }

$vigem = ""
if ($vigemPresent) {
 Write-OK "ViGEmBus already detected on this PC."
 Write-Host ""
 Write-Host " Press ENTER to continue to the next step (recommended)." -ForegroundColor White
 Write-Host " If your controller input gives you trouble, you can (re)install" -ForegroundColor Gray
 Write-Host " it: type V then Enter." -ForegroundColor Gray
 $reinst = (Read-Host " [Enter] skip / [V] reinstall").Trim()
 if ($reinst -in @("v","V")) { $vigem = "y" } else { $vigem = "n" }
} else {
 Write-Host " [Y] Download and open the ViGEmBus installer now" -ForegroundColor White
 Write-Host " [N] Skip (already installed or install manually later)" -ForegroundColor White
 Write-Host ""
 while ($vigem -notin @("y","Y","n","N")) { $vigem = (Read-Host " Your choice (Y/N)").Trim() }
}

if ($vigem -in @("y","Y")) {
 $vigemExe = Join-Path $env:TEMP "ViGEmBus_1.22.0_x64_x86_arm64.exe"
 $r = Invoke-DownloadOrFallback -Url $VIGEMBUS_URL -Destination $vigemExe `
        -Label "ViGEmBus v1.22.0 driver" `
        -ManualUrl "https://github.com/nefarius/ViGEmBus/releases/tag/v1.22.0" `
        -Instructions "Download 'ViGEmBus_1.22.0_x64_x86_arm64.exe' from the GitHub releases page. Place it at '$vigemExe' and choose Retry." `
        -SkipMessage "Skipped - ViGEmBus driver not installed; controller emulation will NOT work (questionable result)."
 if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ($r -eq $true) {
  Write-OK "Launching ViGEmBus installer (UAC prompt will appear)..."
  Start-Process -FilePath $vigemExe
  Write-Info "Follow the installer wizard, then come back here."
 }
 Pause-User "Press Enter once the ViGEmBus installer is done (or if you skip it)..."
} else {
 Write-Info "Skipped ViGEmBus installation."
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
# STEP 4: Done + important settings reminder
# -------------------------------------------------------
Write-Step 4 4 "Installation Summary"

Write-Host " Runtime: $runtimeLabel" -ForegroundColor Gray
Write-Host " Store: $storeLabel" -ForegroundColor Gray
Write-Host " Install path: $gamePath" -ForegroundColor Gray
Write-Host ""

Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Important in-game settings (set BEFORE playing in VR)" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Display: Windowed" -ForegroundColor White
Write-Host " Frame Generation: OFF (never turn this on!)" -ForegroundColor Yellow
Write-Host " VSYNC: OFF" -ForegroundColor White
Write-Host " Motion Blur: OFF" -ForegroundColor White
Write-Host " Depth of Field: OFF" -ForegroundColor White
Write-Host " Dynamic Resolution: OFF (recommended)" -ForegroundColor White
Write-Host ""
Write-Host " TAA, DLSS and CAS are fine. Frame Generation will break VR." -ForegroundColor Gray
Write-Host ""

if ($useOpenXR) {
 Write-Host "--- OpenXR note ---" -ForegroundColor Cyan
 Write-Host " Make sure your headset's runtime is set as the default" -ForegroundColor White
 Write-Host " OpenXR runtime (in Oculus app, Virtual Desktop, etc.)" -ForegroundColor White
 Write-Host " before launching the game." -ForegroundColor White
 Write-Host ""
}

Write-Host "--- How to play ---" -ForegroundColor Cyan
Write-Host " 1. Start your VR runtime (SteamVR / Oculus / Virtual Desktop)" -ForegroundColor White
Write-Host " 2. Launch Starfield the usual way for your store" -ForegroundColor White
Write-Host " 3. Press F11 on the flat monitor (not in HMD) for the" -ForegroundColor White
Write-Host " in-game overlay: resolution scale, recording fix, recenter" -ForegroundColor White
Write-Host ""

Write-Host " Mod page: $MOD_INFO_URL" -ForegroundColor Gray
Write-Host ""
Write-Host " The stars are waiting. Constellation awaits, Starborn." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the game folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
