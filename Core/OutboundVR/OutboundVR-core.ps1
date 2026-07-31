# -------------------------------------------------------
# Outbound VR Mod Installer
# OutboundVR by Destroyjevski - distributed via Nexus Mods
#
# Walks the user through:
# 1. Nexus Mods download (free login gated - opens the Files page)
# 2. Locate the downloaded ZIP (Downloads scan, else drag-and-drop)
# 3. Auto-locate Outbound install folder (Steam / Epic / Xbox)
# 4. Merge the mod's GameFiles/ contents into the game ROOT folder
#
# IMPORTANT: this mod merges into the game ROOT (the folder that
# ends up with a "BepInEx" folder + winhttp.dll at its root), NOT
# a subfolder. The mod ZIP wraps everything in Outbound_VR-<ver>/
# GameFiles/, so we step into GameFiles/ and copy ITS contents.
# No original game files are modified; the two "Switch to flat.bat"
# / "Back to VR.bat" files ship inside the mod and land in the game
# folder for the user to toggle modes.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-InstallerFallback,
# Find-SteamGameFolder). These replace hard "exit 1" aborts with
# manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Outbound VR Installer"

$MOD_NAME = "OutboundVR"
$MOD_VERSION = "v1.0"
$MOD_AUTHOR = "Destroyjevski"

$GAME_APPID = "2681030"
$GAME_NAME = "Outbound"
$GAME_EXE  = "Outbound.exe"

# Nexus Mods page for OutboundVR. The file is behind a free Nexus
# login, so it cannot be pulled automatically - we open the Files
# tab and let the user grab it, then drag it back here.
$NEXUS_URL       = "https://www.nexusmods.com/outbound/mods/28"
$NEXUS_FILES_URL = "$NEXUS_URL`?tab=files"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Outbound VR Mod Installer" -ForegroundColor Cyan
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

function Find-OutboundGamePath {
 # Step 1: Steam libraries
 $sp = Get-SteamPath
 if ($sp) {
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 $candidate = "$lib\steamapps\common\Outbound"
 if (Test-Path -LiteralPath "$candidate\$GAME_EXE") { return $candidate }
 }
 }
 # Step 2: Epic Games Store fallback
 foreach ($ep in @(
 "${env:ProgramFiles}\Epic Games\Outbound",
 "${env:ProgramFiles(x86)}\Epic Games\Outbound",
 "C:\Program Files\Epic Games\Outbound",
 "D:\Epic Games\Outbound", "E:\Epic Games\Outbound"
 )) {
 if (Test-Path -LiteralPath "$ep\$GAME_EXE") { return $ep }
 }
 # Step 3: Xbox / Microsoft Store / PC Game Pass fallback - the game
 # ROOT is the Content folder.
 foreach ($xb in @("C:\XboxGames\Outbound\Content", "D:\XboxGames\Outbound\Content", "E:\XboxGames\Outbound\Content")) {
 if (Test-Path -LiteralPath "$xb\$GAME_EXE") { return $xb }
 }
 return $null
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header

Write-Host " Outbound VR turns Outbound into a stereoscopic 6DOF VR" -ForegroundColor White
Write-Host " experience with head tracking - played on a gamepad, just" -ForegroundColor White
Write-Host " like the flat game. No original game files are modified;" -ForegroundColor White
Write-Host " removing the mod restores the vanilla game." -ForegroundColor White
Write-Host ""
Write-Host " Set your OpenXR runtime once before playing (pick one):" -ForegroundColor White
Write-Host "   - Virtual Desktop: choose VDXR in the Streamer app" -ForegroundColor Gray
Write-Host "     (recommended and the most-tested setup)." -ForegroundColor Gray
Write-Host "   - SteamVR: Settings -> OpenXR -> Set SteamVR as OpenXR" -ForegroundColor Gray
Write-Host "     runtime." -ForegroundColor Gray
Write-Host "   - Quest Link: set the Oculus runtime as the active OpenXR" -ForegroundColor Gray
Write-Host "     runtime in the Meta PC app." -ForegroundColor Gray
Write-Host ""

# -------------------------------------------------------
# STEP 1: download the mod from Nexus
# -------------------------------------------------------
Pause-User "Press Enter to start..."
Write-Step 1 3 "Downloading Outbound VR from Nexus Mods"
Write-Host " The mod is behind a free Nexus Mods login, so it cannot be" -ForegroundColor White
Write-Host " downloaded automatically." -ForegroundColor White
Write-Host ""
Write-Host " Pressing Enter opens the Files page - no need to copy or click:" -ForegroundColor Yellow
Write-Host "     (  $NEXUS_FILES_URL )" -ForegroundColor Gray
Write-Host ""
Write-Host " 1) Log in to Nexus Mods (free account)." -ForegroundColor White
Write-Host " 2) Download the OutboundVR file (Manual download)." -ForegroundColor White
Write-Host " 3) Come back here - the installer looks in your Downloads" -ForegroundColor White
Write-Host "    folder, or you can drag the file onto this window." -ForegroundColor White
# Check the disk before the browser - the file is often already there.
$preFound = Find-PredownloadedFile -Patterns @("*Outbound*VR*.zip","*OutboundVR*.zip","*Outbound*.zip") -Label "the Outbound VR mod"
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
    $modZip = Find-PredownloadedFile -Patterns @("*Outbound*VR*.zip","*OutboundVR*.zip","*Outbound*.zip") -Label "the Outbound VR mod" -PageAlreadyOpen
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
# STEP 3a: locate the Outbound install folder
# -------------------------------------------------------
Write-Step 3 3 "Locating Outbound and installing the mod"

$gamePath = Find-OutboundGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId $GAME_APPID -SteamFolderNames @("Outbound") -EpicNames @("Outbound") -ProbeExe $GAME_EXE }
if ($gamePath) {
 Write-OK "Found Outbound at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Outbound (Steam / Epic / Xbox)."
 Write-Host " Please paste the path to your Outbound folder" -ForegroundColor White
 Write-Host " (the game ROOT folder, where $GAME_EXE lives)." -ForegroundColor White
 Write-Host ""
 while (-not $gamePath) {
 $r = (Read-Host " Outbound folder").Trim().Trim('"').Trim("'")
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
$tempExtract = Join-Path $env:TEMP "OutboundVR_$([System.IO.Path]::GetRandomFileName())"
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

# The ZIP layout is Outbound_VR-<ver>/GameFiles/<payload>. We must copy
# the CONTENTS of GameFiles (BepInEx, dotnet, winhttp.dll, the two
# switch .bat files, ...) into the game root. Find the GameFiles folder
# wherever it sits; if it isn't found, fall back to unwrapping a single
# wrapper folder, then to the extract root.
$srcRoot = $tempExtract
$gameFilesDir = Get-ChildItem -LiteralPath $tempExtract -Directory -Recurse -Filter "GameFiles" -ErrorAction SilentlyContinue |
                Select-Object -First 1
if ($gameFilesDir) {
 $srcRoot = $gameFilesDir.FullName
} else {
 # No GameFiles folder - unwrap a lone non-BepInEx wrapper folder.
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
 -Instructions "Manually copy the extracted mod files from '$srcRoot' into '$gamePath' (the Outbound game folder), merging when asked. Watch for UAC permission prompts. Then choose Skip to continue." `
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
$bepinexDir = Join-Path $gamePath "BepInEx"
$winhttp    = Join-Path $gamePath "winhttp.dll"
$modDll     = Join-Path $gamePath "BepInEx\plugins\OutboundVR\OutboundVR.dll"
if (-not (Test-Path $bepinexDir)) {
 Write-Warn "BepInEx folder not found in $gamePath after copy."
} elseif (-not (Test-Path $winhttp)) {
 Write-Warn "BepInEx is there but winhttp.dll is missing - the mod loader may not start."
} elseif (-not (Test-Path $modDll)) {
 Write-Warn "BepInEx + winhttp.dll are there, but OutboundVR.dll is missing from BepInEx\plugins\OutboundVR."
} else {
 Write-OK "BepInEx + winhttp.dll + OutboundVR.dll present in the game folder."
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
Write-Host " (or Epic) normally." -ForegroundColor White
Write-Host ""
Write-Host " FIRST LAUNCH ONLY: expect a longer startup (up to several" -ForegroundColor Yellow
Write-Host " minutes; the window may stay black) while the mod generates" -ForegroundColor Yellow
Write-Host " helper files once. Don't close it - every later launch is fast." -ForegroundColor Yellow
Write-Host ""
Write-Host " Controls: GAMEPAD, just like flat mode." -ForegroundColor White
Write-Host "   - Aim with your head: interactions follow your gaze. A small" -ForegroundColor Gray
Write-Host "     bracket shows the target (cyan = usable, orange = blocked)." -ForegroundColor Gray
Write-Host "   - Right stick turns left/right; look up/down with your head." -ForegroundColor Gray
Write-Host "   - Click the right stick (R3) to re-center the view any time." -ForegroundColor Gray
Write-Host "   - L3 + R3 together toggles the entire HUD on/off." -ForegroundColor Gray
Write-Host ""
Write-Host " Switching modes (quit the game first; saves are shared):" -ForegroundColor White
Write-Host "   - To play flat: run 'Switch to flat.bat' in the game folder." -ForegroundColor Gray
Write-Host "   - To return to VR: run 'Back to VR.bat' there." -ForegroundColor Gray
Write-Host "   $gamePath" -ForegroundColor DarkGray
Write-Host ""
Write-Host " Config (arms position/size, etc.): BepInEx\config in the game" -ForegroundColor Gray
Write-Host " folder. To remove the mod entirely, delete the mod files -" -ForegroundColor Gray
Write-Host " the vanilla game is restored." -ForegroundColor Gray
Write-Host ""
Write-Host " Chart the drift, trust your gut, and roll on into the unknown." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
