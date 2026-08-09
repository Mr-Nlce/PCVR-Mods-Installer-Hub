# -------------------------------------------------------
# Dinkum VR Mod Installer
# DinkumVR by Destroyjevski - distributed via Nexus Mods
#
# Walks the user through:
# 1. Nexus Mods download (free login gated - opens the Files page)
# 2. Locate the downloaded ZIP (Downloads scan, else drag-and-drop)
# 3. Auto-locate the Dinkum install folder (Steam)
# 4. Merge the mod's GameFiles/ contents into the game ROOT folder
#
# IMPORTANT: this mod merges into the game ROOT (the folder that ends
# up with a "BepInEx" folder + winhttp.dll next to Dinkum.exe), NOT a
# subfolder. The mod ZIP wraps everything in DinkumVR-<ver>/GameFiles/,
# so we step into GameFiles/ and copy ITS contents. No original game
# files are modified; the "Play in Flat.bat" / "Back to VR.bat" files
# ship inside the mod and land in the game folder for the user to
# toggle modes.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-InstallerFallback,
# Find-SteamGameFolder). These replace hard "exit 1" aborts with
# manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Dinkum VR Installer"

$MOD_NAME = "DinkumVR"
$MOD_VERSION = "v1.0.0"
$MOD_AUTHOR = "Destroyjevski"

$GAME_APPID = "1062520"
$GAME_NAME = "Dinkum"
$GAME_EXE  = "Dinkum.exe"

# Nexus Mods page for DinkumVR. The file is behind a free Nexus login,
# so it cannot be pulled automatically - we open the Files tab and let
# the user grab it, then drag it back here.
$NEXUS_URL       = "https://www.nexusmods.com/dinkum/mods/440"
$NEXUS_FILES_URL = "$NEXUS_URL`?tab=files"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Dinkum VR Mod Installer" -ForegroundColor Cyan
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

function Find-DinkumGamePath {
 $sp = Get-SteamPath
 if ($sp) {
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 $candidate = "$lib\steamapps\common\Dinkum"
 if (Test-Path -LiteralPath "$candidate\$GAME_EXE") { return $candidate }
 }
 }
 return $null
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header

Write-Host " Dinkum VR turns Dinkum into a stereoscopic 6DOF VR" -ForegroundColor White
Write-Host " experience with head tracking - played on a gamepad, just" -ForegroundColor White
Write-Host " like the flat game. No original game files are modified;" -ForegroundColor White
Write-Host " removing the mod restores the vanilla game." -ForegroundColor White
Write-Host ""
Write-Host " Set your OpenXR runtime once before playing:" -ForegroundColor White
Write-Host "   - Virtual Desktop: choose VDXR in the Streamer app" -ForegroundColor Gray
Write-Host "     (the only tested setup)." -ForegroundColor Gray
Write-Host "   - SteamVR / Quest Link may work but are untested." -ForegroundColor Gray
Write-Host ""

# -------------------------------------------------------
# STEP 1: download the mod from Nexus
# -------------------------------------------------------
Pause-User "Press Enter to start..."
Write-Step 1 3 "Downloading Dinkum VR from Nexus Mods"
Write-Host " The mod is behind a free Nexus Mods login, so it cannot be" -ForegroundColor White
Write-Host " downloaded automatically." -ForegroundColor White
Write-Host ""
Write-Host " Pressing Enter opens the Files page - no need to copy or click:" -ForegroundColor Yellow
Write-Host "     (  $NEXUS_FILES_URL )" -ForegroundColor Gray
Write-Host ""
Write-Host " 1) Log in to Nexus Mods (free account)." -ForegroundColor White
Write-Host " 2) Download the DinkumVR file (Manual download)." -ForegroundColor White
Write-Host " 3) Come back here - the installer looks in your Downloads" -ForegroundColor White
Write-Host "    folder, or you can drag the file onto this window." -ForegroundColor White
# Check the disk before the browser - the file is often already there.
$preFound = Find-PredownloadedFile -Patterns @("*Dinkum*VR*.zip","*DinkumVR*.zip","*Dinkum*.zip") -Label "the Dinkum VR mod"
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
    $modZip = Find-PredownloadedFile -Patterns @("*Dinkum*VR*.zip","*DinkumVR*.zip","*Dinkum*.zip") -Label "the Dinkum VR mod" -PageAlreadyOpen
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
# STEP 3a: locate the Dinkum install folder
# -------------------------------------------------------
Write-Step 3 3 "Locating Dinkum and installing the mod"

$gamePath = Find-DinkumGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId $GAME_APPID -SteamFolderNames @("Dinkum") -ProbeExe $GAME_EXE }
if ($gamePath) {
 Write-OK "Found Dinkum at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Dinkum via Steam."
 Write-Host " Please paste the path to your Dinkum folder" -ForegroundColor White
 Write-Host " (the game ROOT folder, where $GAME_EXE lives)." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Dinkum folder").Trim().Trim('"').Trim("'")
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
$tempExtract = Join-Path $env:TEMP "DinkumVR_$([System.IO.Path]::GetRandomFileName())"
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
}

# The ZIP layout is DinkumVR-<ver>/GameFiles/<payload>. We must copy the
# CONTENTS of GameFiles (BepInEx, Dinkum_Data, winhttp.dll, the two
# switch .bat files, ...) into the game root. Find the GameFiles folder
# wherever it sits; if it isn't found, fall back to unwrapping a single
# wrapper folder, then to the extract root.
$srcRoot = $tempExtract
$gameFilesDir = Get-ChildItem -LiteralPath $tempExtract -Directory -Recurse -Filter "GameFiles" -ErrorAction SilentlyContinue |
                Select-Object -First 1
if ($gameFilesDir) {
 $srcRoot = $gameFilesDir.FullName
} else {
 $rootEntries = Get-ChildItem -LiteralPath $tempExtract
 if ($rootEntries.Count -eq 1 -and $rootEntries[0].PSIsContainer -and $rootEntries[0].Name -ne "BepInEx") {
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
 -Instructions "Manually copy the extracted mod files from '$srcRoot' into '$gamePath' (the Dinkum game folder), merging when asked. Watch for UAC permission prompts. Then choose Skip to continue." `
 -SkipMessage "Skipped - mod files were NOT copied; install is incomplete." `
 -SourceFolder "$srcRoot" `
 -DestFolder "$gamePath" `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 Pause-User "We will exit so you can re-run with the fixed environment. Press Enter to exit..."
 exit 1
 }
}

try { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Sanity check
$bepinexDir = Join-Path $gamePath "BepInEx"
$winhttp    = Join-Path $gamePath "winhttp.dll"
$modDll     = Join-Path $gamePath "BepInEx\plugins\DinkumVR\DinkumVR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $winhttp)) {
 Write-Warn "BepInEx is there but winhttp.dll is missing - the mod loader may not start."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx + winhttp.dll are there, but DinkumVR.dll is missing from BepInEx\plugins\DinkumVR."
} else {
 Write-OK "BepInEx + winhttp.dll + DinkumVR.dll present in the game folder."
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
Write-Host " What to do now:" -ForegroundColor White
Write-Host "   1) In the Virtual Desktop Streamer app, set VDXR as the" -ForegroundColor Gray
Write-Host "      OpenXR runtime, then put your headset on." -ForegroundColor Gray
Write-Host "   2) Launch with" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or through Steam." -ForegroundColor Gray
Write-Host "   3) Grab a gamepad - VR is active right away, and Dinkum" -ForegroundColor Gray
Write-Host "      starts fast (no long first launch)." -ForegroundColor Gray
Write-Host ""
Write-Host " Controls: GAMEPAD, just like flat mode." -ForegroundColor White
Write-Host "   - Two view modes on one button (R3), switchable any time:" -ForegroundColor Gray
Write-Host "     third person in true stereo, and a bodyless first person." -ForegroundColor Gray
Write-Host "   - Right stick turns left/right; look up/down and around" -ForegroundColor Gray
Write-Host "     with your head." -ForegroundColor Gray
Write-Host "   - The view auto-recenters on every mode switch. If your" -ForegroundColor Gray
Write-Host "     seating has drifted, tap R3 twice." -ForegroundColor Gray
Write-Host "   - Menus are a panel in front of you, operated with stick or" -ForegroundColor Gray
Write-Host "     D-pad plus A/B, exactly like a controller in flat mode." -ForegroundColor Gray
Write-Host ""
Write-Host " Switching between VR and flat (quit the game first; saves" -ForegroundColor White
Write-Host " are shared): use the VR / Flat switch button on this game's" -ForegroundColor White
Write-Host " page in the Hub. The active mode is highlighted." -ForegroundColor White
Write-Host ""
Write-Host " Menu size and placement are all in the config file:" -ForegroundColor Gray
Write-Host " $(Join-Path $gamePath 'BepInEx\config\dinkumvr.dinkumvr.cfg')" -ForegroundColor DarkGray
Write-Host " Delete it to restore the defaults." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to exit."
