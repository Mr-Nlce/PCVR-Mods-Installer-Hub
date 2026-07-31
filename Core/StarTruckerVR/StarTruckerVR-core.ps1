# -------------------------------------------------------
# Star Trucker VR Mod Installer
# StarTruckerVR by Destroyjevski - distributed via Nexus Mods
#
# Walks the user through:
# 1. Nexus Mods download (free login gated - opens the Files page)
# 2. Locate the downloaded ZIP (Downloads scan, else drag-and-drop)
# 3. Auto-locate Star Trucker install folder (Steam / GOG / Xbox)
# 4. Merge the mod's GameFiles/ contents into the game ROOT folder
#
# IMPORTANT: this mod merges into the game ROOT (the folder that
# ends up with a "Mods" folder + version.dll at its root), NOT a
# subfolder. The mod ZIP wraps everything in GameFiles/, so we step
# into GameFiles/ and copy ITS contents. No original game files are
# modified; the "Play in Flat.bat" / "Back to VR.bat" files ship
# inside the mod and land in the game folder for the user to toggle
# modes. MelonLoader 0.7.3 is bundled with the mod (Mods\, version.dll,
# MelonLoader\); merging with a different MelonLoader may break it.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-InstallerFallback,
# Find-SteamGameFolder). These replace hard "exit 1" aborts with
# manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Star Trucker VR Installer"

$MOD_NAME = "StarTruckerVR"
$MOD_VERSION = "v1.0"
$MOD_AUTHOR = "Destroyjevski"

$GAME_APPID = "2380050"
$GAME_NAME = "Star Trucker"
$GAME_EXE  = "Star Trucker.exe"

# Nexus Mods page for StarTruckerVR. The file is behind a free Nexus
# login, so it cannot be pulled automatically - we open the Files
# tab and let the user grab it, then drag it back here.
$NEXUS_URL       = "https://www.nexusmods.com/startrucker/mods/17"
$NEXUS_FILES_URL = "$NEXUS_URL`?tab=files"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Star Trucker VR Mod Installer" -ForegroundColor Cyan
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

function Find-StarTruckerGamePath {
 # Step 1: Steam libraries
 $sp = Get-SteamPath
 if ($sp) {
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 $candidate = "$lib\steamapps\common\Star Trucker"
 if (Test-Path -LiteralPath "$candidate\$GAME_EXE") { return $candidate }
 }
 }
 # Step 2: GOG fallback
 foreach ($gg in @(
 "C:\GOG Games\Star Trucker", "D:\GOG Games\Star Trucker", "E:\GOG Games\Star Trucker",
 "${env:ProgramFiles(x86)}\GOG Galaxy\Games\Star Trucker",
 "${env:ProgramFiles}\GOG Galaxy\Games\Star Trucker"
 )) {
 if (Test-Path -LiteralPath "$gg\$GAME_EXE") { return $gg }
 }
 # Step 3: Xbox / Microsoft Store / PC Game Pass fallback - the game
 # ROOT is the Content folder.
 foreach ($xb in @("C:\XboxGames\Star Trucker\Content", "D:\XboxGames\Star Trucker\Content", "E:\XboxGames\Star Trucker\Content")) {
 if (Test-Path -LiteralPath "$xb\$GAME_EXE") { return $xb }
 }
 return $null
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header

Write-Host " Star Trucker VR turns Star Trucker into a stereoscopic 6DOF VR" -ForegroundColor White
Write-Host " experience with head tracking - played on a gamepad, just like" -ForegroundColor White
Write-Host " the flat game. No original game files are modified; removing the" -ForegroundColor White
Write-Host " mod restores the vanilla game." -ForegroundColor White
Write-Host ""
Write-Host " Virtual Desktop with VDXR is the tested OpenXR runtime; SteamVR" -ForegroundColor Gray
Write-Host " and Quest Link may work but are untested." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..."

# -------------------------------------------------------
# STEP 1: download the mod from Nexus
# -------------------------------------------------------
Write-Step 1 3 "Downloading Star Trucker VR from Nexus Mods"
Write-Host " The mod is behind a free Nexus Mods login, so it cannot be" -ForegroundColor White
Write-Host " downloaded automatically." -ForegroundColor White
Write-Host ""
Write-Host " Pressing Enter opens the Files page - no need to copy or click:" -ForegroundColor Yellow
Write-Host "     (  $NEXUS_FILES_URL )" -ForegroundColor Gray
Write-Host ""
Write-Host " 1) Log in to Nexus Mods (free account)." -ForegroundColor White
Write-Host " 2) Download the StarTruckerVR file (Manual download)." -ForegroundColor White
Write-Host " 3) Come back here - the installer looks in your Downloads" -ForegroundColor White
Write-Host "    folder, or you can drag the file onto this window." -ForegroundColor White
# Check the disk before the browser - the file is often already there.
$preFound = Find-PredownloadedFile -Patterns @("*Star*Trucker*VR*.zip","*StarTruckerVR*.zip","*Trucker*.zip") -Label "the Star Trucker VR mod"
if (-not $preFound) {
    Pause-User "Press Enter to open the download page on Nexus Mods..."
    try { Start-Process $NEXUS_FILES_URL } catch { Write-Warn "Open manually: $NEXUS_FILES_URL" }
}

# -------------------------------------------------------
# STEP 2: locate the downloaded ZIP (Downloads scan, else drag-drop)
# -------------------------------------------------------
Write-Step 2 3 "Locate the downloaded ZIP"

$modZip = $preFound

# The pre-check ran BEFORE the browser opened, so look again now that the
# user has had a chance to download. Without this second pass the promise
# above ("we look in your Downloads folder") would only hold on a re-run.
if (-not $modZip) {
    Pause-User "Press Enter once the download has finished..."
    $modZip = Find-PredownloadedFile -Patterns @("*Star*Trucker*VR*.zip","*StarTruckerVR*.zip","*Trucker*.zip") -Label "the Star Trucker VR mod" -PageAlreadyOpen
}

if (-not $modZip) {
 Write-Host " Drop the downloaded ZIP here (or paste its full path)." -ForegroundColor Gray
 Write-Host ""
 while (-not $modZip) {
 Write-Host " Drag-and-drop the downloaded ZIP into this window," -ForegroundColor Yellow
 Write-Host " or paste/type its full path, then press Enter" -ForegroundColor White
 Write-Host " (leave empty to cancel):" -ForegroundColor DarkGray
 $r = (Read-Host " ZIP path").Trim().Trim('"').Trim("'")
 if (-not $r) { Write-Fail "No file provided - cannot install without the mod."; Pause-User "Press Enter to exit..."; exit 1 }
 if (Test-Path -LiteralPath $r) {
 if ($r -match '\.zip$|\.7z$|\.rar$') {
 $modZip = $r
 Write-OK "Archive located: $modZip"
 } else {
 Write-Fail "Path is not a ZIP/7z/RAR archive: $r"
 }
 } else {
 Write-Fail "File not found: $r"
 }
 }
}

# -------------------------------------------------------
# STEP 3a: locate the Star Trucker install folder
# -------------------------------------------------------
Write-Step 3 3 "Locating Star Trucker and installing the mod"

$gamePath = Find-StarTruckerGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId $GAME_APPID -SteamFolderNames @("Star Trucker") -GogNames @("Star Trucker") -ProbeExe $GAME_EXE }
if ($gamePath) {
 Write-OK "Found Star Trucker at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Star Trucker (Steam / GOG / Xbox)."
 Write-Host " Please paste the path to your Star Trucker folder" -ForegroundColor White
 Write-Host " (the game ROOT folder, where $GAME_EXE lives)." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Star Trucker folder").Trim().Trim('"').Trim("'")
 if (-not $r) { continue }
 if (Test-Path -LiteralPath $r) {
 $gamePath = $r
 Write-OK "Game folder set: $gamePath"
 } else {
 Write-Fail "Folder not found: $r"
 }
 }
}

# -------------------------------------------------------
# STEP 3b: extract + merge the mod's GameFiles into the game ROOT
# -------------------------------------------------------
$tempExtract = Join-Path $env:TEMP "StarTruckerVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null

try {
 Write-Host " Extracting archive..." -ForegroundColor Gray
 Expand-Archive -LiteralPath $modZip -DestinationPath $tempExtract -Force
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
 Pause-User "We will exit so you can re-run with the fixed environment. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

# The ZIP layout is GameFiles/<payload>. We must copy the CONTENTS of
# GameFiles (Mods, MelonLoader, version.dll, Star Trucker_Data, the two
# switch .bat files, ...) into the game root. Find the GameFiles folder
# wherever it sits; if it isn't found, fall back to unwrapping a single
# wrapper folder, then to the extract root.
$srcRoot = $tempExtract
$gameFilesDir = Get-ChildItem -LiteralPath $tempExtract -Directory -Recurse -Filter "GameFiles" -ErrorAction SilentlyContinue |
                Select-Object -First 1
if ($gameFilesDir) {
 $srcRoot = $gameFilesDir.FullName
} else {
 # No GameFiles folder - unwrap a lone non-Mods wrapper folder.
 $rootEntries = Get-ChildItem -LiteralPath $tempExtract
 if ($rootEntries.Count -eq 1 -and $rootEntries[0].PSIsContainer -and $rootEntries[0].Name -ne "Mods") {
 $srcRoot = $rootEntries[0].FullName
 }
}

Write-Host " Copying mod files into: $gamePath" -ForegroundColor Gray
try {
 Get-ChildItem -LiteralPath $srcRoot | ForEach-Object {
 Copy-Item -LiteralPath $_.FullName -Destination $gamePath -Recurse -Force
 }
 Write-OK "Mod files installed into the game folder."
} catch {
 Write-Fail "Copy failed: $_"
 $__fb = Invoke-InstallerFallback -Action "file copy into game folder" `
 -Instructions "Manually copy the extracted mod files from '$srcRoot' into '$gamePath' (the Star Trucker game folder), merging when asked. Watch for UAC permission prompts. Then choose Skip to continue." `
 -SkipMessage "Skipped - mod files were NOT copied; install is incomplete." `
 -SourceFolder "$srcRoot" `
 -DestFolder "$gamePath" `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 Pause-User "We will exit so you can re-run with the fixed environment. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

try { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Sanity check
$modsDir  = Join-Path $gamePath "Mods"
$loader   = Join-Path $gamePath "version.dll"
$modDll   = Join-Path $gamePath "Mods\StarTruckerVR.dll"
if (-not (Test-Path $modsDir)) {
 Write-Warn "Mods folder not found in $gamePath after copy."
} elseif (-not (Test-Path $loader)) {
 Write-Warn "Mods is there but version.dll (MelonLoader) is missing - the mod loader may not start."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "MelonLoader is there, but StarTruckerVR.dll is missing from the Mods folder."
} else {
 Write-OK "Mods + version.dll + StarTruckerVR.dll present in the game folder."
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
Write-Host " VR is active immediately - no batch file is needed to start" -ForegroundColor White
Write-Host " in VR. Launch with 'Start in VR' in the Hub, or through Steam" -ForegroundColor White
Write-Host " (or GOG) normally. Set VDXR as your OpenXR runtime first." -ForegroundColor White
Write-Host ""
Write-Host " FIRST LAUNCH ONLY: expect a longer startup (several minutes;" -ForegroundColor Yellow
Write-Host " the window may stay black) while MelonLoader builds helper" -ForegroundColor Yellow
Write-Host " files once. Don't close it - every later launch is fast." -ForegroundColor Yellow
Write-Host ""
Write-Host " See the README for controls, mode switching, and how to" -ForegroundColor Gray
Write-Host " uninstall. Switch .bat files sit in the game folder:" -ForegroundColor Gray
Write-Host "   $gamePath" -ForegroundColor DarkGray
Write-Host ""
Write-Host " Big rig, bigger view - haul the void in stereo." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
