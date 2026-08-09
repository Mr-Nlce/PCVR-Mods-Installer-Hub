# ============================================================
# Iron Lung VR Installer (by Jack Randolph)
# ============================================================
# Iron Lung VR is a standalone Unity-based fan-game VR remake
# of the original Iron Lung (by David Szymanski, of DUSK).
# Distributed via itch.io - no automated download is possible
# (itch.io requires the user's session/button click), so this
# installer prompts the user to download the ZIP manually and
# drag-and-drop it in.
#
# Install layout:
#   <install_root>\Iron Lung VR\Iron Lung VR.exe       (and Unity data)
#   default install_root: C:\Games  (fallback D:\Games, etc.)
#
# Nothing here is shipped inside the Hub - the user-supplied
# ZIP (~150 MB) provides the entire game payload.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Iron Lung VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Iron Lung VR Installer" -ForegroundColor Cyan
    Write-Host " by Jack Randolph | itch.io download required" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR     = Split-Path -Parent $MyInvocation.MyCommand.Path
$ITCH_PAGE_URL  = "https://jackaapacka.itch.io/iron-lung-vr"
$EXPECTED_ZIP   = "1.2.0.zip"
$GAME_FOLDER    = "Iron Lung VR"
$GAME_EXE       = "Iron Lung VR.exe"
# Preferred install roots in order; first writable wins.
$DEFAULT_ROOTS  = @("C:\Games", "D:\Games", "E:\Games")

Write-Header

Write-Host "  Iron Lung VR is a standalone Unity VR fan-game by Jack Randolph -" -ForegroundColor Gray
Write-Host "  a roomscale recreation of David Szymanski's submarine horror." -ForegroundColor Gray
Write-Host "  It is distributed on itch.io and is not on Steam." -ForegroundColor Gray
Write-Host ""
Write-Host "  Download steps (do these now):" -ForegroundColor White
Write-Host "   1. The download page will open in your browser" -ForegroundColor White
Write-Host "   2. Scroll down to the Download section" -ForegroundColor White
Write-Host "   3. Click Download next to: $EXPECTED_ZIP (~150 MB)" -ForegroundColor White
Write-Host "   4. Come back here and drag the downloaded ZIP into this window" -ForegroundColor White
Write-Host ""
Write-Host "  itch.io page:" -ForegroundColor Cyan
Write-Host "   -> $ITCH_PAGE_URL" -ForegroundColor DarkGray
Pause-User "Press Enter to open the itch.io page in your browser..." | Out-Null
try { Start-Process $ITCH_PAGE_URL } catch {
    Write-Warn "Could not open the browser. Visit the URL above manually."
}

# ---- 1. drag-and-drop the ZIP -------------------------------
Write-Step 1 4 "Locate the downloaded ZIP"
Write-Host "  Once $EXPECTED_ZIP is on your disk, drop it here." -ForegroundColor Gray
Write-Host ""

$modZip = $null
$attempts = 0
while (-not $modZip) {
    $attempts++
    Write-Host "  Drag-and-drop the downloaded ZIP into this window," -ForegroundColor Yellow
    Write-Host "  or paste / type its full path, then press Enter." -ForegroundColor White
    Write-Host "  (Press Enter on an empty line to skip this attempt.)" -ForegroundColor DarkGray
    $r = (Read-Host "  ZIP path").Trim().Trim('"')
    if (-not $r) {
        if ($attempts -ge 5) {
            $fb = Invoke-InstallerFallback -Action "locate the Iron Lung VR ZIP" `
                -Subject "the Iron Lung VR download from itch.io" `
                -Url $ITCH_PAGE_URL `
                -Instructions "Open the itch.io page, download '$EXPECTED_ZIP', then come back and drag it in. Choose Retry once the ZIP is on disk." `
                -AllowSkip $false
            if ([string]$fb -eq "quit") {
                Write-Fail "Cannot continue without the download."
                Pause-User "Press Enter to exit..." | Out-Null
                exit 1
            }
            $attempts = 0
        }
        continue
    }
    if (-not (Test-Path $r)) { Write-Fail "File not found: $r"; continue }
    if ($r -notmatch '\.zip$') { Write-Fail "Path is not a ZIP archive: $r"; continue }
    $modZip = [string]$r
    Write-OK "Archive located: $modZip"
}

# ---- 2. pick a writable install root ------------------------
Write-Step 2 4 "Choosing an install location"

function Test-WritableRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path $Root)) {
            New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null
        }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

$installRoot = $null
foreach ($r in $DEFAULT_ROOTS) {
    if (Test-WritableRoot -Root $r) { $installRoot = [string]$r; break }
}
if (-not $installRoot) {
    Write-Warn "None of the default roots (C:\Games, D:\Games, E:\Games) is writable."
    Write-Host "  Enter a folder where the game should be installed (will create '$GAME_FOLDER' inside)." -ForegroundColor White
    while (-not $installRoot) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
Write-OK "Install root: $installRoot"
$gameRoot = Join-Path $installRoot $GAME_FOLDER

# If an old install exists, offer overwrite.
if (Test-Path (Join-Path $gameRoot $GAME_EXE)) {
    Write-Warn "An existing Iron Lung VR install was found at: $gameRoot"
    Write-Host "  Press Enter to overwrite it, or close this window to abort." -ForegroundColor Gray
    Pause-User "Press Enter to overwrite..." | Out-Null
}

# ---- 3. extract the ZIP -------------------------------------
Write-Step 3 4 "Extracting Iron Lung VR"

# Extract to a temp folder under the install root, then flatten
# the single top-level "1.2.0" subfolder into <gameRoot>.
$tmp = Join-Path $installRoot "_iron_lung_extract_tmp"
try {
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
    Expand-Archive -Path $modZip -DestinationPath $tmp -Force -ErrorAction Stop
} catch {
    Write-Fail "Could not extract the ZIP: $_"
    Write-Host "  The ZIP may be corrupted. Re-download from itch.io and try again." -ForegroundColor Gray
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}

# Find the EXE inside the extracted tree to locate the real game folder.
$exeItem = Get-ChildItem -Path $tmp -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exeItem) {
    Write-Fail "'$GAME_EXE' not found in the ZIP."
    Write-Host "  The download may be the wrong file. Make sure you grabbed $EXPECTED_ZIP" -ForegroundColor Gray
    Write-Host "  from $ITCH_PAGE_URL" -ForegroundColor Gray
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
$extractedDir = Split-Path -Parent $exeItem.FullName

# Wipe any prior install, then move the extracted files into place.
try {
    if (Test-Path $gameRoot) { Remove-Item $gameRoot -Recurse -Force -ErrorAction Stop }
    New-Item -ItemType Directory -Path $gameRoot -Force -ErrorAction Stop | Out-Null
    $null = Get-ChildItem -Path $extractedDir -Force | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $gameRoot -Force -ErrorAction Stop
    }
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Fail "Could not place the game files: $_"
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
Write-OK "Game installed at: $gameRoot"

# ---- 4. desktop shortcut ------------------------------------
Write-Step 4 4 "Creating a desktop shortcut"
$exePath = Join-Path $gameRoot $GAME_EXE
if (-not (Test-Path $exePath)) {
    Write-Warn "Game EXE not found after install - shortcut skipped."
} else {
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $lnkPath = Join-Path $desktop "Iron Lung VR.lnk"
        $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $exePath -WorkingDir $gameRoot -IconPath $exePath
        Write-OK "Desktop shortcut created: Iron Lung VR"
    } catch {
        Write-Warn "Could not create the desktop shortcut: $_"
        Write-Host "  You can launch the game manually with:" -ForegroundColor Gray
        Write-Host "    $exePath" -ForegroundColor Cyan
    }
}

# Record the install path so the Hub's "VR Installed" check finds it.
try {
    $marker = Join-Path $SCRIPT_DIR ".installed_path"
    Set-Content -Path $marker -Value $gameRoot -Force -ErrorAction Stop
} catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Iron Lung VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Start SteamVR (or your OpenXR runtime) first, then launch" -ForegroundColor White
Write-Host "  with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the 'Iron Lung VR'" -ForegroundColor White
Write-Host "  desktop shortcut, or run:" -ForegroundColor White
Write-Host "    $exePath" -ForegroundColor Cyan
Write-Host ""

Write-Host "  Dive deep, pilot. The dark has teeth." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
