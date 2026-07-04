# ============================================================
# Receiver VR Installer
# ============================================================
# Standalone VR build of Wolfire's "Receiver" (the 7DFPS gun-
# handling sim). The ReceiVR release is a complete, self-
# contained Unity game with SteamVR/OpenVR baked in - it does
# NOT need the Steam copy of Receiver. We download it, flatten
# the "Receiver" wrapper folder, install to C:\Games\Receiver VR,
# and drop a desktop shortcut. Never bundles the payload.
# ============================================================

# Load installer-safety helpers (Invoke-SafeDownload,
# Expand-ArchiveOrFallback, Invoke-InstallerFallback, Get-SevenZip).
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Receiver VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME    = "Receiver VR"
$MOD_AUTHOR  = "ShadowBrian (VR port) / Wolfire Games"
$INFO_URL    = "https://www.wolfire.com/receiver/"
$MOD_URL     = "https://github.com/ShadowBrian/7DFPS/releases/download/v1.01-beta23/ReceiVR.zip"
$GAME_FOLDER = "Receiver VR"
$GAME_EXE    = "Receiver.exe"
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")

# ---- Inline console helpers (per-installer; NOT shared) -----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  Receiver VR Installer" -ForegroundColor Cyan
    Write-Host "  Standalone VR build of Wolfire's gun-handling sim" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-WritableRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

# -------------------------------------------------------
# STEP 0: Welcome
# -------------------------------------------------------
Write-Header
Write-Host "  About this mod:" -ForegroundColor White
Write-Host "  - Receiver VR is a standalone VR build of Wolfire's Receiver," -ForegroundColor Gray
Write-Host "    the 7-day FPS gun-handling simulation." -ForegroundColor Gray
Write-Host "  - Self-contained: it ships its own game files + SteamVR, so it" -ForegroundColor Gray
Write-Host "    does NOT need the Steam copy of Receiver installed." -ForegroundColor Gray
Write-Host "  - Motion controls. Detailed handgun simulation (Colt 1911," -ForegroundColor Gray
Write-Host "    S&W Model 10 revolver, Glock 17), turrets and shock drones." -ForegroundColor Gray
Write-Host "  - Installs to C:\Games\$GAME_FOLDER (no UAC issues there)." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to begin..."

# -------------------------------------------------------
# STEP 1: Download the VR build
# -------------------------------------------------------
Write-Step 1 3 "Downloading $MOD_NAME"

$tempDir    = Join-Path $env:TEMP "_receivr_tmp"
$modArchive = Join-Path $tempDir "ReceiVR.zip"
$modExtract = Join-Path $tempDir "extract"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $tempDir   -Force | Out-Null
New-Item -ItemType Directory -Path $modExtract -Force | Out-Null

if (-not (Invoke-SafeDownload -Urls @($MOD_URL) -Destination $modArchive -Label $MOD_NAME `
        -ManualUrl "https://github.com/ShadowBrian/7DFPS/releases" `
        -Instructions "Download 'ReceiVR.zip' from the GitHub releases page and drop it into the opened folder, then choose Retry." `
        -SkipMessage "Skipped - Receiver VR was NOT downloaded; cannot continue.")) {
    if (-not (Test-Path $modArchive)) {
        Write-Fail "No Receiver VR archive available. Aborting."
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

# -------------------------------------------------------
# STEP 2: Choose install root + extract + install
# -------------------------------------------------------
Write-Step 2 3 "Installing to C:\Games"

# Hub convention: self-contained games with their own exe install to
# C:\Games (off the Steam library, away from Program Files / UAC).
# We show that as the recommended default but let the user pick any
# folder - whatever they choose is where it goes (and gets recorded
# in .installed_path so the Hub launches it from there).
$defaultParent = $null
foreach ($r in $DEFAULT_ROOTS) {
    if (Test-WritableRoot -Root $r) { $defaultParent = [string]$r; break }
}
if (-not $defaultParent) { $defaultParent = "C:\Games" }
$defaultPath = Join-Path $defaultParent $GAME_FOLDER

Write-Host "  Default install location: $defaultPath" -ForegroundColor Gray
Write-Host "  (Recommended: C:\Games keeps the install off the Steam library" -ForegroundColor DarkGray
Write-Host "   and away from any Program Files / UAC issues.)" -ForegroundColor DarkGray
Write-Host ""
$userInput = (Read-Host "  Press Enter to use the default, or type a different full path").Trim().Trim('"')
if (-not $userInput) {
    $installRoot = $defaultPath
} else {
    # User gave a path. If it ends in the game folder name use it as
    # is; otherwise treat it as a parent and create the game folder
    # inside it.
    if ((Split-Path $userInput -Leaf) -eq $GAME_FOLDER) {
        $installRoot = $userInput
    } else {
        $installRoot = Join-Path $userInput $GAME_FOLDER
    }
}

# Make sure the chosen parent is writable; if not, fall back to a
# prompt loop so the install never dies on an unwritable location.
$chosenParent = Split-Path $installRoot -Parent
if (-not (Test-WritableRoot -Root $chosenParent)) {
    Write-Warn "That location isn't writable: $chosenParent"
    Write-Host "  Enter a different folder (avoid Program Files / Users):" -ForegroundColor White
    $newParent = $null
    while (-not $newParent) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $newParent = [string]$r }
        else { Write-Fail "Not writable: $r" }
    }
    $installRoot = Join-Path $newParent $GAME_FOLDER
}
Write-OK "Installing to: $installRoot"

if (Test-Path $installRoot) {
    Write-Warn "Folder already exists: $installRoot"
    Write-Host "  [Y] Delete and reinstall   [N] Abort" -ForegroundColor White
    $choice = ""
    while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host "  Choice (Y/N)").Trim() }
    if ($choice -in @("n","N")) {
        Write-Info "Aborted."
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..."; exit 0
    }
    try { Remove-Item $installRoot -Recurse -Force -ErrorAction Stop }
    catch {
        Write-Fail "Could not delete: $($_.Exception.Message)"
        Write-Host "  Close any running Receiver VR window, then re-run the installer." -ForegroundColor Yellow
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..."; exit 1
    }
}
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null

# Extract (handles .zip; interactive manual fallback on failure).
$exResult = Expand-ArchiveOrFallback -ArchivePath $modArchive -DestinationFolder $modExtract `
                -Label "Receiver VR" `
                -SkipMessage "Skipped - Receiver VR archive was NOT extracted; install is incomplete."
if ([string]$exResult -eq "quit") {
    try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit..."; exit 1
}

# The zip wraps everything in a "Receiver" folder. Flatten: if the
# extract dir holds exactly one folder, treat that as the payload
# root. Then near-folder recovery: if Receiver.exe is not at the
# payload root, search one level down for the folder containing it.
$payload = $modExtract
$probe = @(Get-ChildItem -Path $modExtract -ErrorAction SilentlyContinue)
if ($probe.Count -eq 1 -and $probe[0].PSIsContainer) { $payload = $probe[0].FullName }
if (-not (Test-Path (Join-Path $payload $GAME_EXE))) {
    $hit = Get-ChildItem -Path $modExtract -Recurse -Filter $GAME_EXE -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $payload = Split-Path $hit.FullName -Parent }
}

Write-Host "  Copying Receiver VR files ... " -NoNewline -ForegroundColor White
$copyOk = $false
try {
    Get-ChildItem -Path $payload | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $installRoot -Recurse -Force
    }
    Write-Host "OK" -ForegroundColor Green
    $copyOk = $true
} catch {
    Write-Host "FAILED" -ForegroundColor Red
    Write-Fail "Copy failed: $($_.Exception.Message)"
    $__fb = Invoke-InstallerFallback -Action "copying Receiver VR files" `
        -Instructions "Copy the contents of '$payload' into '$installRoot' (so that $GAME_EXE sits at its root). Then choose Retry." `
        -SkipMessage "Skipped - game files were NOT copied; install is incomplete." `
        -SourceFolder "$payload" `
        -DestFolder "$installRoot" `
        -AllowSkip $true
    if ([string]$__fb -eq "quit") { try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}; Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$__fb -eq "retry") {
        try {
            Get-ChildItem -Path $payload | ForEach-Object { Copy-Item -Path $_.FullName -Destination $installRoot -Recurse -Force }
            $copyOk = $true
        } catch {}
    }
}

$gameExePath = Join-Path $installRoot $GAME_EXE
if (Test-Path $gameExePath) {
    Write-OK "Receiver.exe present at $installRoot"
    # Record install path so the Hub flips to "VR Ready" immediately.
    try {
        $pathFile = Join-Path $PSScriptRoot ".installed_path"
        Set-Content -Path $pathFile -Value $installRoot -Encoding UTF8 -Force
    } catch {}
} else {
    Write-Warn "Receiver.exe not found at the install root after copy."
    Write-Host "  Check $installRoot for a subfolder and move its contents up." -ForegroundColor Yellow
}

# Cleanup temp.
try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 3: Desktop shortcut
# -------------------------------------------------------
Write-Step 3 3 "Creating Desktop Shortcut"

if (Test-Path $gameExePath) {
    try {
        $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Receiver VR.lnk" -TargetPath $gameExePath -WorkingDir $installRoot -IconPath "$gameExePath,0"
        Write-OK "Desktop shortcut 'Receiver VR' created."
    } catch {
        Write-Warn "Could not create shortcut: $($_.Exception.Message)"
        Write-Info "Launch manually: $gameExePath"
    }
} else {
    Write-Warn "Skipping shortcut - Receiver.exe not found."
}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation complete." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Installed to: $installRoot" -ForegroundColor Gray
Write-Host ""
Write-Host "  Start SteamVR first, then launch:" -ForegroundColor White
Write-Host "  - Via the Hub: Start in VR  ->  runs Receiver.exe" -ForegroundColor Gray
Write-Host "  - Desktop shortcut: 'Receiver VR'" -ForegroundColor Gray
Write-Host ""
Write-Host "  Rack the slide. Mind the chamber. The Mindkill is patient." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
