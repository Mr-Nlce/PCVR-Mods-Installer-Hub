# -------------------------------------------------------
# Amnesia VR Mod Installer (Sclerosis remake)
# by CreaTeam - distributed via itch.io
#
# Walks the user through:
# 1. Opens itch.io download page in browser
# 2. User downloads Sclerosis_VR_v1.8.16.zip manually
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Amnesia: The Dark Descent install folder
# 5. Extract mod files in place next to Amnesia.exe
# 6. Verify Sclerosis.exe exists post-install
#
# Sclerosis is a free fan-made VR remake of Amnesia: The
# Dark Descent built in Unity. It requires Amnesia: The
# Dark Descent on Steam (AppID 57300) to be installed.
# The mod ships its own engine (Unity) - Sclerosis.exe
# is the new launch target, NOT the original Amnesia.exe.
#
# Development status: the mod author halted development
# in 2024. v1.8.16 is the final shipping version.
# No auto-updater - we pin the version.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME = "Sclerosis (Amnesia VR Remake)"
$MOD_VERSION = "v1.8.16"
$MOD_AUTHOR = "CreaTeam"

$GAME_APPID = "57300"
$GAME_NAME = "Amnesia The Dark Descent"

# itch.io mod page - user downloads the ZIP from here.
# Direct download URL not extractable (itch token-protected).
$ITCH_PAGE_URL = "https://createam.itch.io/sclerosis-an-amnesia-vr-remake"
$EXPECTED_ZIP = "Sclerosis_VR_v1.8.16.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Yellow
 Write-Host " Amnesia VR Mod Installer" -ForegroundColor Cyan
 Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Yellow
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

function Get-SteamLibraryFolders {
 $steam = Get-SteamPath
 if (-not $steam) { return @() }
 $libs = @($steam)
 $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
 if (Test-Path $vdf) {
 $content = Get-Content $vdf -Raw
 $matches = [regex]::Matches($content, '"path"\s+"([^"]+)"')
 foreach ($m in $matches) {
 $path = $m.Groups[1].Value -replace '\\\\', '\'
 if (Test-Path $path) { $libs += $path }
 }
 }
 return $libs | Select-Object -Unique
}

function Find-AmnesiaGamePath {
 foreach ($lib in (Get-SteamLibraryFolders)) {
 $candidate = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path $candidate) {
 # Verify Amnesia.exe OR AmnesiaGW.exe exists - either
 # confirms a real Amnesia install. AmnesiaGW.exe is
 # the alternate-engine binary mentioned in the mod's
 # bundled HOW_TO_INSTALL.txt; we accept either as proof
 # the folder is a real game install (not just empty).
 $exe1 = Join-Path $candidate "Amnesia.exe"
 $exe2 = Join-Path $candidate "AmnesiaGW.exe"
 if ((Test-Path $exe1) -or (Test-Path $exe2)) {
 return $candidate
 }
 }
 }
 return $null
}

# -------------------------------------------------------
# STEP 0: Welcome + Itch.io page open
# -------------------------------------------------------
Write-Header
Write-Host " About this mod:" -ForegroundColor White
Write-Host " - Sclerosis is a free fan-made VR remake of Amnesia: TDD" -ForegroundColor Gray
Write-Host " - Built in Unity, ships its own engine" -ForegroundColor Gray
Write-Host " - REQUIRES Amnesia: The Dark Descent on Steam (owned + installed)" -ForegroundColor Gray
Write-Host " - Motion controls + room-scale support" -ForegroundColor Gray
Write-Host ""
Write-Host " Download steps (do these now):" -ForegroundColor White
Write-Host " 1. The mod page will open in your browser" -ForegroundColor White
Write-Host " 2. Scroll down to the Download section" -ForegroundColor White
Write-Host " 3. Click 'Download' next to: $EXPECTED_ZIP (~916 MB)" -ForegroundColor White
Write-Host " 4. Skip the optional donation prompt (No thanks, just take me to the downloads)" -ForegroundColor White
Write-Host " 5. Come back here and drag the downloaded ZIP into this window" -ForegroundColor White
Write-Host ""
Write-Host " Mod page URL:" -ForegroundColor Cyan
Write-Host " -> $ITCH_PAGE_URL" -ForegroundColor DarkGray
Pause-User "Press Enter to open the itch.io page in your browser..."
try { Start-Process $ITCH_PAGE_URL } catch {
 Write-Warn "Could not open browser. Visit the URL above manually."
}

# -------------------------------------------------------
# STEP 1: Get the ZIP from the user
# -------------------------------------------------------
Write-Step 1 4 "Locate the downloaded ZIP"
Write-Host " Once $EXPECTED_ZIP is on your disk, drop it here." -ForegroundColor Gray
Write-Host ""

$modZip = $null
while (-not $modZip) {
 Write-Host " Drag-and-drop the downloaded ZIP into this window," -ForegroundColor Yellow
 Write-Host " or paste/type its full path, then press Enter:" -ForegroundColor White
 $r = (Read-Host " ZIP path").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 if ($r -match '\.zip$') {
 $modZip = $r
 Write-OK "Archive located: $modZip"
 } else {
 Write-Fail "Path is not a ZIP archive: $r"
 }
 } else {
 Write-Fail "File not found: $r"
 }
}

# -------------------------------------------------------
# STEP 2: Locate the Amnesia install
# -------------------------------------------------------
Write-Step 2 4 "Locating Amnesia: The Dark Descent"

$gamePath = Find-AmnesiaGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "57300" -SteamFolderNames @("Amnesia The Dark Descent") -ProbeExe "Sclerosis.exe" -GogNames @("Amnesia The Dark Descent") }
if ($gamePath) {
 Write-OK "Found Amnesia at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Amnesia: The Dark Descent in any Steam library."
 Write-Host " Please paste the path to your Amnesia folder" -ForegroundColor White
 Write-Host " (the folder that contains Amnesia.exe), then press Enter:" -ForegroundColor White
 while (-not $gamePath) {
 $r = (Read-Host " Amnesia folder").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 $exe1 = Join-Path $r "Amnesia.exe"
 $exe2 = Join-Path $r "AmnesiaGW.exe"
 if ((Test-Path $exe1) -or (Test-Path $exe2)) {
 $gamePath = $r
 Write-OK "Confirmed Amnesia folder: $gamePath"
 } else {
 Write-Fail "No Amnesia.exe or AmnesiaGW.exe in: $r"
 }
 } else {
 Write-Fail "Folder not found: $r"
 }
 }
}

# -------------------------------------------------------
# STEP 3: Extract the mod into the Amnesia folder
# -------------------------------------------------------
Write-Step 3 4 "Installing mod files"
Write-Host " Extracting $EXPECTED_ZIP contents directly into:" -ForegroundColor Gray
Write-Host " $gamePath" -ForegroundColor DarkGray
Write-Host ""

try {
 Expand-Archive -LiteralPath $modZip -DestinationPath $gamePath -Force -ErrorAction Stop
 Write-OK "Files extracted."
} catch {
 Write-Fail "Extraction failed: $_"
 Write-Host ""
 Write-Host " Manual fallback: open the ZIP and copy every file/folder" -ForegroundColor Yellow
 Write-Host " inside it to:" -ForegroundColor Yellow
 Write-Host " $gamePath" -ForegroundColor DarkGray
 # Hard abort replaced by safe fallback - user can fix and retry, or quit cleanly
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$gamePath'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
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

# Verify Sclerosis.exe arrived
$sclerosisExe = Join-Path $gamePath "Sclerosis.exe"
if (Test-Path $sclerosisExe) {
 Write-OK "Sclerosis.exe present in game folder."
} else {
 Write-Warn "Sclerosis.exe not found after extraction."
 Write-Host " The ZIP may have had a different structure than expected." -ForegroundColor Yellow
 Write-Host " Check $gamePath for a subfolder and move Sclerosis.exe up." -ForegroundColor Yellow
}

# -------------------------------------------------------
# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# STEP 4: Desktop shortcut
# -------------------------------------------------------
Write-Step 4 4 "Creating Desktop Shortcut"

if (Test-Path $sclerosisExe) {
 try {
 $shell = New-Object -ComObject WScript.Shell
 $shortcut = $shell.CreateShortcut("$env:USERPROFILE\Desktop\Amnesia VR.lnk")
 $shortcut.TargetPath = $sclerosisExe
 $shortcut.WorkingDirectory = $gamePath
 $shortcut.Description = "Amnesia VR - Sclerosis remake"
 # Sclerosis.exe ships its own icon - use it directly.
 $shortcut.IconLocation = "$sclerosisExe,0"
 $shortcut.Save()
 Write-OK "Desktop shortcut 'Amnesia VR' created."
 } catch {
 Write-Warn "Could not create shortcut: $_"
 Write-Info "Launch manually: $sclerosisExe"
 }
} else {
 Write-Warn "Skipping shortcut - Sclerosis.exe not found."
}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Installation complete." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host " Launch via the Hub: Start in VR -> runs Sclerosis.exe" -ForegroundColor White
Write-Host " Desktop shortcut: 'Amnesia VR' -> Sclerosis.exe" -ForegroundColor White
Write-Host ""
Write-Host " Tinderboxes lit. Mind still slipping. Welcome to the dark." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
