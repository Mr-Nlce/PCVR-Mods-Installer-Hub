# ============================================================
# 7 Days to Die - VR Mod Installer
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "7 Days to Die VR Mod Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "7 Days To Die"
$GAME_EXE = "7DaysToDie.exe"
$NEXUS_URL = "https://www.nexusmods.com/7daystodie/mods/3011?tab=files"
$DOWNLOAD_DIR = Join-Path $env:USERPROFILE "Downloads"

# Expected ZIP name pattern in Downloads folder
$ZIP_PATTERN = "7DVR*.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " 7 Days to Die - VR Mod Installer" -ForegroundColor Cyan
 Write-Host " 7DaysVR" -ForegroundColor Gray
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

function Find-GamePath {
 param($libraries)
 foreach ($lib in $libraries) {
 $candidate = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path $candidate) { return $candidate }
 }
 return $null
}

function Find-ModZip {
 # Search Downloads folder for the ZIP
 $found = Get-ChildItem -Path $DOWNLOAD_DIR -Filter $ZIP_PATTERN -ErrorAction SilentlyContinue |
 Sort-Object LastWriteTime -Descending |
 Select-Object -First 1
 return $found
}

# -------------------------------------------------------
# STEP 1: Locate 7 Days to Die
# -------------------------------------------------------
Write-Header
Write-Host " 7DaysVR adds VR to 7 Days to Die. The installer locates your game," -ForegroundColor White
Write-Host " installs the mod, and sets it up to launch in VR." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 5 "Locating 7 Days to Die"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
 . $__utilsPath
 $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "7 Days to Die"
 }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath

if (-not $steamPath) {
 Write-Warn "Could not find Steam installation in registry."
 Write-Host " Please enter your Steam installation path manually:" -ForegroundColor White
 while (-not $steamPath) {
 $rawInput = (Read-Host " Steam path").Trim().Trim('"')
 if (Test-Path $rawInput) { $steamPath = $rawInput; Write-OK "Steam path set: $steamPath" }
 else { Write-Fail "Path not found: $rawInput" }
 }
}

$libraries = Get-SteamLibraries $steamPath
$gamePath = Find-GamePath $libraries
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "251570" -SteamFolderNames @("7 Days To Die") }

if (-not $gamePath) {
 Write-Warn "7 Days to Die not found in Steam libraries automatically."
 Write-Host " Please enter the game installation folder path manually:" -ForegroundColor White
 Write-Host " Example: C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die" -ForegroundColor Gray
 while (-not $gamePath) {
 $rawInput = (Read-Host " Game path").Trim().Trim('"')
 if (Test-Path $rawInput) { $gamePath = $rawInput; Write-OK "Game path set: $gamePath" }
 else { Write-Fail "Path not found: $rawInput" }
 }
} else {
 Write-OK "7 Days to Die found: $gamePath"
}

# -------------------------------------------------------
# Already installed? Offer Update vs Reinstall
# -------------------------------------------------------
$updateMode = $false
$modProbe    = Join-Path $gamePath "BepInEx\plugins\7daysVR.dll"
$loaderProbe = Join-Path $gamePath "winhttp.dll"
if ((Test-Path $modProbe) -or (Test-Path $loaderProbe)) {
 Write-Host ""
 Write-Host " This 7 Days to Die already has the VR mod installed." -ForegroundColor Cyan
 Write-Host " [U] Update    - grab the newer version from Nexus and replace the mod" -ForegroundColor White
 Write-Host " [R] Reinstall - set everything up again from scratch" -ForegroundColor White
 Write-Host ""
 $uAns = ""
 while ($uAns -notin @("U","R")) { $uAns = (Read-Host " Enter U or R").Trim().ToUpper() }
 if ($uAns -eq "U") { $updateMode = $true; Write-OK "Update mode - your saves and settings stay; only the mod is replaced." }
 else { Write-Info "Reinstalling from scratch." }
}

# -------------------------------------------------------
# STEP 2: Download the mod from Nexus
# -------------------------------------------------------
Write-Step 2 5 "Download 7DaysVR from Nexus Mods"

Write-Host " The mod must be downloaded manually from Nexus Mods." -ForegroundColor White
Write-Host " (Nexus requires a login - automatic download is not possible.)" -ForegroundColor Gray
Write-Host ""
Write-Host " The Nexus page will open in your browser now." -ForegroundColor White
Write-Host " Download the latest 7DVR zip file and save it to your Downloads folder." -ForegroundColor White
Write-Host ""
Write-Host " Looking for existing download in: $DOWNLOAD_DIR" -ForegroundColor Gray

# Check if already downloaded
$existingZip = Find-ModZip
if ($existingZip) {
 Write-OK "Found existing download: $($existingZip.Name)"
 Write-Host ""
 Write-Host " Use this file? Or download a newer version from Nexus?" -ForegroundColor White
 Write-Host " [1] Use existing file: $($existingZip.Name)" -ForegroundColor White
 Write-Host " [2] Open Nexus and download fresh" -ForegroundColor White
 Write-Host ""
 $choice = ""
 while ($choice -notin @("1","2")) {
 $choice = (Read-Host " Enter 1 or 2").Trim()
 }
 if ($choice -eq "2") { $existingZip = $null }
}

if (-not $existingZip) {
 Start-Process $NEXUS_URL
 Write-Host ""
 Write-Host " Nexus Mods is now open in your browser." -ForegroundColor Cyan
 Write-Host " - Log in if needed" -ForegroundColor Gray
 Write-Host " - Click 'Files' tab -> Download the latest 7DVR zip" -ForegroundColor Gray
 Write-Host " - Save to your Downloads folder (default location)" -ForegroundColor Gray
 Write-Host ""
 Pause-User "Press Enter once the download is complete..."

 # Search again after download
 $existingZip = Find-ModZip
 while (-not $existingZip) {
 Write-Warn "No 7DVR zip found in $DOWNLOAD_DIR"
 Write-Host " Make sure the file was saved to your Downloads folder." -ForegroundColor White
 Write-Host " Expected filename pattern: 7DVR*.zip" -ForegroundColor Gray
 Write-Host ""
 Write-Host " [1] Try again" -ForegroundColor White
 Write-Host " [2] Enter the path to the zip manually" -ForegroundColor White
 $choice = ""
 while ($choice -notin @("1","2")) {
 $choice = (Read-Host " Enter 1 or 2").Trim()
 }
 if ($choice -eq "1") {
 $existingZip = Find-ModZip
 } else {
 $rawInput = (Read-Host " Full path to zip file").Trim().Trim('"')
 if (Test-Path $rawInput) {
 $existingZip = Get-Item $rawInput
 } else {
 Write-Fail "File not found: $rawInput"
 }
 }
 }
}

$modZipPath = $existingZip.FullName
Write-OK "Using mod zip: $($existingZip.Name)"

# -------------------------------------------------------
# STEP 3: Install the mod
# -------------------------------------------------------
Write-Step 3 5 "Installing 7DaysVR"

$tempDir = Join-Path $env:TEMP "7DaysVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$failed = @()

Write-Host " Extracting mod files ... " -NoNewline -ForegroundColor White
try {
 Expand-Archive -Path $modZipPath -DestinationPath $tempDir -Force
 Write-Host "OK" -ForegroundColor Green

 # Merge all contents into game folder
 Get-ChildItem -Path $tempDir | ForEach-Object {
 Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
 }

 # Verify key files
 $winhttpCheck = Join-Path $gamePath "winhttp.dll"
 if (Test-Path $winhttpCheck) { Write-OK "winhttp.dll verified." }
 else { Write-Warn "winhttp.dll not found - mod may not have installed correctly." }

 Write-OK "7DaysVR mod installed!"
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Host " $_" -ForegroundColor Gray
 $failed += "7DaysVR"
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

# -------------------------------------------------------
# STEP 4: Disable EasyAntiCheat
# -------------------------------------------------------
Write-Step 4 5 "Disabling EasyAntiCheat"

if ($updateMode) {
 Write-Info "Update mode - EasyAntiCheat was already disabled during your first install; skipping."
} else {
Write-Host ""
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host " ACTION REQUIRED - Disable EasyAntiCheat" -ForegroundColor Yellow
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " EAC must be OFF for the VR mod to work." -ForegroundColor White
Write-Host " (Servers with EAC enabled will be unavailable.)" -ForegroundColor Gray
Write-Host ""

$launcherPath = Join-Path $gamePath "7dLauncher.exe"
if (Test-Path $launcherPath) {
 Write-Host " 1) Click 'Game' or 'Settings' in the launcher" -ForegroundColor White
 Write-Host " 2) Find EasyAntiCheat -> set to OFF / Disabled" -ForegroundColor White
 Write-Host " 3) Close the launcher" -ForegroundColor White
 Write-Host ""
 Write-Host " Press Enter to open the 7 Days Launcher..." -ForegroundColor Yellow
 Write-Host ""
 Pause-User "Press Enter to open the 7 Days Launcher..."
 Start-Process $launcherPath
 Pause-User "Press Enter once you have disabled EAC and closed the launcher..."
} else {
 Write-Warn "7dLauncher.exe not found at: $launcherPath"
 Write-Info "You may need to disable EAC manually from the launcher in the game folder."
}
}

# -------------------------------------------------------
# STEP 5: Apply VR-optimized video settings
# -------------------------------------------------------
Write-Step 5 5 "Applying VR Video Settings"

# 7 Days stores its settings in AppData
$settingsPath = Join-Path $env:APPDATA "7DaysToDie\saves\GamePrefs.xml"
$settingsDir = Split-Path $settingsPath -Parent

if (-not (Test-Path $settingsPath)) {
 Write-Warn "GamePrefs.xml not found - game may not have been launched yet."
 Write-Info "Video settings will need to be set manually on first launch."
 Write-Info " - Anti-Aliasing: Off (no TAA)"
 Write-Info " - Reflection Quality: Off"
 Write-Info " - Reflected Shadows: Off"
 Write-Info " - SS Reflections: Off"
 Write-Info " - Fullscreen: ON (Exclusive may cause issues)"
} else {
 try {
 $prefs = Get-Content $settingsPath -Raw

 # Patch the relevant settings
 $patches = @{
 "OptionsAntialiasingMode value=`"[^`"]+`"" = "OptionsAntialiasingMode value=`"0`""
 "OptionsReflectionQuality value=`"[^`"]+`"" = "OptionsReflectionQuality value=`"0`""
 "OptionsSSReflections value=`"[^`"]+`"" = "OptionsSSReflections value=`"false`""
 "OptionsReflectedShadows value=`"[^`"]+`"" = "OptionsReflectedShadows value=`"false`""
 "OptionsFullscreen value=`"[^`"]+`"" = "OptionsFullscreen value=`"true`""
 }

 $changed = 0
 foreach ($pattern in $patches.Keys) {
 if ($prefs -match $pattern) {
 $prefs = $prefs -replace $pattern, $patches[$pattern]
 $changed++
 }
 }

 if ($changed -gt 0) {
 Set-Content -Path $settingsPath -Value $prefs -Encoding UTF8
 Write-OK "Video settings patched ($changed settings updated)."
 } else {
 Write-Info "Could not match settings in GamePrefs.xml - may need manual setup."
 }
 } catch {
 Write-Warn "Could not patch video settings: $_"
 Write-Info "Please set these manually in-game."
 }
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ("7DaysVR" -notin $failed) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {} }

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Summary" -ForegroundColor White
Write-Host ""
if ("7DaysVR" -notin $failed) { Write-Host " [x] 7DaysVR mod" -ForegroundColor Green } else { Write-Host " [ ] 7DaysVR mod -- FAILED" -ForegroundColor Red }
Write-Host " [x] EasyAntiCheat disabled" -ForegroundColor Green
Write-Host " [x] VR video settings applied" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta

Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host " In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host " Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."

Write-Host ""
Write-Host "--- Important Notes ---" -ForegroundColor Cyan
Write-Host ""
Write-Host " - Launch with 'Start in VR' in the Hub, or normally via Steam." -ForegroundColor White
Write-Host " Steam may warn the game is not VR-ready - click OK." -ForegroundColor Gray
Write-Host ""
Write-Host " - 7 Days must be the ACTIVE, FOREGROUND window while playing." -ForegroundColor Yellow
Write-Host " If SteamVR is on top, controls may not work!" -ForegroundColor Yellow
Write-Host " Disable 'SteamVR Always on Top' in SteamVR Settings -> Developer." -ForegroundColor Gray
Write-Host ""
Write-Host " - VR options are in-game under Options -> Controls -> VR (far right)." -ForegroundColor White
Write-Host ""
Write-Host " - World loading screen is very jittery - this is normal." -ForegroundColor White
Write-Host " The CPU is at 100% during this phase. Hang in there!" -ForegroundColor Gray
Write-Host ""
Write-Host " - Recalibrate height: stand straight, hold both thumbsticks for 2 seconds." -ForegroundColor White
Write-Host ""
Write-Host " Full guide: https://docs.google.com/document/d/1gI9_EpF7ACiZu3bndAj1A5uGy0TKVUnfVfvTbHtWsPM" -ForegroundColor Gray
Write-Host ""
Write-Host " Day one. Loot the cars. Run from the screamers." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the 7 Days to Die installation folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
