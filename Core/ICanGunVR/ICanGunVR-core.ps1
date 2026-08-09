# ============================================================
# I Can Gun VR Installer (by Patrick Koenig)
# ============================================================
# I Can Gun is a standalone Unity first-person shooter where
# you operate your weapon in full manual detail while scavenging
# procedurally generated levels for documents. Distributed via
# itch.io - no automated download is possible (itch requires the
# user's session / button click), so this installer prompts the
# user to download the ZIP manually and drag-and-drop it in.
#
# Install layout (the ZIP extracts flat):
#   <install_root>\I Can Gun VR\ICG.exe   (+ ICG_Data, Mono, ...)
#   default install_root: C:\Games  (fallback D:\Games, E:\Games)
#
# Nothing here is shipped inside the Hub - the user-supplied
# ZIP (~597 MB) provides the entire game payload.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "I Can Gun VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " I Can Gun VR Installer" -ForegroundColor Cyan
    Write-Host " by Patrick Koenig | itch.io download required" -ForegroundColor Gray
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
$ITCH_PAGE_URL  = "https://patrickkoenig.itch.io/i-can-gun"
$EXPECTED_ZIP   = "i-can-gun-win.zip"
$GAME_FOLDER    = "I Can Gun VR"
$GAME_EXE       = "ICG.exe"
# Preferred install roots in order; first writable wins.
$DEFAULT_ROOTS  = @("C:\Games", "D:\Games", "E:\Games")

Write-Header

Write-Host "  I Can Gun is a standalone tactical first-person shooter by" -ForegroundColor Gray
Write-Host "  Patrick Koenig. You operate your weapon in full manual detail" -ForegroundColor Gray
Write-Host "  (press F1 in-game for an interactive help overlay) while" -ForegroundColor Gray
Write-Host "  scavenging procedurally generated levels for documents," -ForegroundColor Gray
Write-Host "  guarded by machines that do not know mercy." -ForegroundColor Gray
Write-Host "  Playable with Mouse + Keyboard and/or in VR (Vive, Rift)." -ForegroundColor Gray
Write-Host "  It is a free itch.io download and is not on Steam." -ForegroundColor Gray
Write-Host ""
Write-Host "  Download steps (do these now):" -ForegroundColor White
Write-Host "   1. The download page will open in your browser" -ForegroundColor White
Write-Host "   2. Scroll down to the Download section" -ForegroundColor White
Write-Host "   3. Click Download next to: $EXPECTED_ZIP (~597 MB)" -ForegroundColor White
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
            $fb = Invoke-InstallerFallback -Action "locate the I Can Gun ZIP" `
                -Subject "the I Can Gun download from itch.io" `
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
    Write-Warn "An existing I Can Gun VR install was found at: $gameRoot"
    Write-Host "  Press Enter to overwrite it, or close this window to abort." -ForegroundColor Gray
    Pause-User "Press Enter to overwrite..." | Out-Null
}

# ---- 3. extract the ZIP -------------------------------------
Write-Step 3 4 "Extracting I Can Gun VR"

# Extract to a temp folder under the install root, then move the
# real game folder (the one holding ICG.exe) into <gameRoot>. The
# ZIP extracts flat, but the recursive EXE search also handles a
# wrapped layout, so this works either way.
$tmp = Join-Path $installRoot "_icangun_extract_tmp"
$extractOk = $false
while (-not $extractOk) {
    try {
        if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
        Expand-Archive -Path $modZip -DestinationPath $tmp -Force -ErrorAction Stop
        $extractOk = $true
    } catch {
        Write-Fail "Could not extract the ZIP: $_"
        $fb = Invoke-InstallerFallback -Action "extract the I Can Gun ZIP" `
            -Subject "the downloaded $EXPECTED_ZIP" `
            -Url $ITCH_PAGE_URL `
            -Instructions "The ZIP may be incomplete or corrupted. Re-download '$EXPECTED_ZIP' from itch.io, then choose Retry. If you have a fresh copy at a different path, drag it in now." `
            -AllowSkip $false
        if ([string]$fb -eq "quit") {
            try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        # Let the user point at a fresh ZIP before retrying.
        Write-Host "  Drag in the ZIP again (or press Enter to retry the same file)." -ForegroundColor White
        $again = (Read-Host "  ZIP path").Trim().Trim('"')
        if ($again -and (Test-Path $again) -and ($again -match '\.zip$')) { $modZip = [string]$again }
    }
}

# Find the EXE inside the extracted tree to locate the real game folder.
$exeItem = Get-ChildItem -Path $tmp -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
while (-not $exeItem) {
    Write-Fail "'$GAME_EXE' not found in the extracted files."
    $fb = Invoke-InstallerFallback -Action "find $GAME_EXE in the download" `
        -Subject "the I Can Gun download" `
        -Url $ITCH_PAGE_URL `
        -Instructions "The ZIP did not contain $GAME_EXE - it may be the wrong file. Make sure you grabbed '$EXPECTED_ZIP' from the itch.io page, then choose Retry to re-extract." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
    Write-Host "  Drag in the correct ZIP, then press Enter." -ForegroundColor White
    $again = (Read-Host "  ZIP path").Trim().Trim('"')
    if ($again -and (Test-Path $again) -and ($again -match '\.zip$')) {
        $modZip = [string]$again
        try {
            if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
            New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
            Expand-Archive -Path $modZip -DestinationPath $tmp -Force -ErrorAction Stop
        } catch { Write-Fail "Re-extract failed: $_" }
    }
    $exeItem = Get-ChildItem -Path $tmp -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
$extractedDir = Split-Path -Parent $exeItem.FullName

# Wipe any prior install, then move the extracted files into place.
$placedOk = $false
while (-not $placedOk) {
    try {
        if (Test-Path $gameRoot) { Remove-Item $gameRoot -Recurse -Force -ErrorAction Stop }
        New-Item -ItemType Directory -Path $gameRoot -Force -ErrorAction Stop | Out-Null
        $null = Get-ChildItem -Path $extractedDir -Force | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $gameRoot -Force -ErrorAction Stop
        }
        $placedOk = $true
    } catch {
        Write-Fail "Could not place the game files: $_"
        $fb = Invoke-InstallerFallback -Action "copy the game files into place" `
            -Instructions "Copy the contents of '$extractedDir' into '$gameRoot' (so that $GAME_EXE sits at its root). Then choose Retry, or Skip to finish manually." `
            -SourceFolder "$extractedDir" `
            -DestFolder "$gameRoot" `
            -AllowSkip $true
        if ([string]$fb -eq "quit") {
            try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        if ([string]$fb -eq "skip") { break }
    }
}
try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
Write-OK "Game installed at: $gameRoot"

# ---- 4. desktop shortcut ------------------------------------
Write-Step 4 4 "Creating a desktop shortcut"
$exePath = Join-Path $gameRoot $GAME_EXE
if (-not (Test-Path $exePath)) {
    Write-Warn "Game EXE not found after install - shortcut skipped."
    Write-Host "  Open '$gameRoot' and confirm $GAME_EXE is there; if it sits in a" -ForegroundColor Gray
    Write-Host "  subfolder, move its contents up one level." -ForegroundColor Gray
} else {
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $lnkPath = Join-Path $desktop "I Can Gun VR.lnk"
        $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $exePath -WorkingDir $gameRoot -IconPath $exePath
        Write-OK "Desktop shortcut created: I Can Gun VR"
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
Write-Host "  I Can Gun VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Start SteamVR (or your OpenXR runtime) first, then launch" -ForegroundColor White
Write-Host "  with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the 'I Can Gun VR'" -ForegroundColor White
Write-Host "  desktop shortcut, or run:" -ForegroundColor White
Write-Host "    $exePath" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Tip: press F1 in-game for the interactive weapon-handling help." -ForegroundColor Gray
Write-Host "  Tip: if it runs slow, pick a lower quality in the startup dialog." -ForegroundColor Gray
Write-Host ""

Write-Host "  Know your weapon. Find the papers. The machines never blink." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
