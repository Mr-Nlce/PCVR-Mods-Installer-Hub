# ============================================================
# Forza Horizon 6 VR Installer
# Two VR mods to choose from:
#   1) NALULUNA (free, ko-fi)        launcher: fh6vr.exe
#   2) lufz / VRMod (flat2VR Discord) launcher: vrmod-launcher.exe
# Both ship a separate launcher that injects into the game; the
# mod files must NOT live in the game folder, so we extract to
# C:\Games\Forza Horizon 6 VR and launch from there.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Forza Horizon 6 VR Installer"
$ErrorActionPreference = "Stop"

$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")
$GAME_FOLDER   = "Forza Horizon 6 VR"
$KOFI_URL      = "https://ko-fi.com/s/03bdcc5fe9"
$FLAT2VR_URL   = "https://discord.gg/uAeQkYBM4n"
$LUF_POST_URL  = "https://discord.com/channels/747967102895390741/1509055901582233740/1514330703582593167"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Forza Horizon 6 VR Installer" -ForegroundColor Cyan
    Write-Host " Two community VR mods to choose from" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [XX] $t" -ForegroundColor Red }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
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

# Drag-drop loop: the user drags the downloaded mod .zip onto the
# window. Accepts a dragged (quoted) path or a typed path; loops until
# a real .zip is given or the user cancels.
function Get-DraggedZip {
    param([string]$ExpectHint)
    while ($true) {
        Write-Host ""
        Write-Host " Drag the downloaded $ExpectHint onto this window and press Enter." -ForegroundColor Yellow
        Write-Host " (You can also type or paste the full path.)" -ForegroundColor Gray
        Write-Host " Leave empty and press Enter to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " Zip path"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path $p)) { Write-Warn "Path not found: $p"; continue }
        if (Test-Path $p -PathType Container) { Write-Warn "That is a folder. Drag the .zip file itself."; continue }
        if ([System.IO.Path]::GetExtension($p) -ne ".zip") { Write-Warn "That is not a .zip file."; continue }
        return $p
    }
}

Write-Header
Write-Host " This sets up a VR mod for your EXISTING Forza Horizon 6 install" -ForegroundColor White
Write-Host " (Steam / Microsoft Store / Game Pass). No game files are" -ForegroundColor Gray
Write-Host " bundled - you download the free community mod yourself and" -ForegroundColor Gray
Write-Host " drag the .zip onto this window; the Hub does the rest." -ForegroundColor Gray
Write-Host ""

# ---- STEP 1: choose the mod ----
Write-Step 1 6 "Choosing a VR mod"
Write-Host "  Which VR mod do you want to set up?" -ForegroundColor White
Write-Host ""
Write-Host "   [1] NALULUNA  - free on ko-fi  (recommended)" -ForegroundColor Green
Write-Host "   [2] lufz VRMod - from the flat2VR Modding Discord" -ForegroundColor White
Write-Host ""
$modChoice = ""
while ($modChoice -ne "1" -and $modChoice -ne "2") {
    $modChoice = (Read-Host "  Enter 1 or 2 [default: 1]").Trim()
    if ($modChoice -eq "") { $modChoice = "1" }
    if ($modChoice -ne "1" -and $modChoice -ne "2") { Write-Warn "Please type 1 or 2." }
}
if ($modChoice -eq "1") {
    $modName      = "NALULUNA"
    $modSub       = "NALULUNA"
    $launcherName = "fh6vr.exe"
    $zipHint      = "fh6vr_<version>.zip"
} else {
    $modName      = "lufz VRMod"
    $modSub       = "lufz"
    $launcherName = "vrmod-launcher.exe"
    $zipHint      = "VRMod-v1.0.0-beta.1.zip"
}
Write-OK "Selected: $modName"

# ---- STEP 2: get the download ----
Write-Step 2 6 "Downloading the mod"
if ($modChoice -eq "1") {
    Write-Host "  NALULUNA's mod is FREE on ko-fi. On the page that opens:" -ForegroundColor White
    Write-Host "   - set the amount to 0 (or any tip you like) and download," -ForegroundColor Gray
    Write-Host "   - the file is named like '$zipHint' (newest version)." -ForegroundColor Gray
    try { Start-Process $KOFI_URL } catch { Write-Warn "Could not open the browser. Open manually: $KOFI_URL" }
    Write-Host ""
    Write-Host "  ko-fi page: $KOFI_URL" -ForegroundColor DarkGray
} else {
    Write-Host "  lufz's VRMod is shared in the flat2VR Modding Discord." -ForegroundColor White
    Write-Host "   - First the flat2VR invite opens; accept it to join." -ForegroundColor Gray
    Write-Host "   - Then the download post opens; the file is named '$zipHint'." -ForegroundColor Gray
    Pause-User "Press Enter to open the flat2VR invite..."
    try { Start-Process $FLAT2VR_URL } catch { Write-Warn "Could not open the browser. Join manually: $FLAT2VR_URL" }
    Pause-User "Press Enter once you have joined the Discord..."
    Write-Host "   - Opening the download post. The file is named '$zipHint'." -ForegroundColor Gray
    try { Start-Process $LUF_POST_URL } catch { Write-Warn "Could not open the post. Open manually: $LUF_POST_URL" }
    Write-Host ""
    Write-Host "   ( If Discord won't scroll, you can also copy this link manually by selecting it (Ctrl+C) and pasting it into the browser's address bar (Ctrl+V) : $LUF_POST_URL )" -ForegroundColor DarkGray
}
# ---- STEP 3: drag the zip ----
Write-Step 3 6 "Locating the downloaded zip"
$zipPath = Get-DraggedZip -ExpectHint $zipHint
if (-not $zipPath) { Write-Info "No zip provided - cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
$zipLeaf = Split-Path -Leaf $zipPath
if ($modChoice -eq "1" -and $zipLeaf -notlike "fh6vr_*") {
    Write-Warn "Expected a 'fh6vr_*.zip' - continuing anyway with '$zipLeaf'."
} elseif ($modChoice -eq "2" -and $zipLeaf -notlike "VRMod-*") {
    Write-Warn "Expected a 'VRMod-*.zip' - continuing anyway with '$zipLeaf'."
}
Write-OK "Using: $zipLeaf"

# ---- STEP 4: choose location + extract ----
Write-Step 4 6 "Installing the mod files"
$defaultParent = $null
foreach ($r in $DEFAULT_ROOTS) { if (Test-WritableRoot -Root $r) { $defaultParent = [string]$r; break } }
if (-not $defaultParent) { $defaultParent = "C:\Games" }
$installRoot = Join-Path $defaultParent $GAME_FOLDER
# Each mod gets its OWN subfolder so installing both (e.g. to compare
# them) never lets one overwrite the other's files - notably the shared
# openxr_loader.dll.
$modFolder = Join-Path $installRoot $modSub
Write-Host "  Install location: $modFolder" -ForegroundColor Gray
Write-Host "  (Kept OUT of the game folder on purpose - the mod must not" -ForegroundColor DarkGray
Write-Host "   live inside Forza Horizon 6's own install folder.)" -ForegroundColor DarkGray
try { New-Item -ItemType Directory -Force -Path $modFolder | Out-Null } catch {}

$r = Expand-ArchiveOrFallback -ArchivePath $zipPath -DestinationFolder $modFolder -Label "$modName VR mod" `
        -SkipMessage "Skipped - the mod files were NOT extracted. The install is incomplete."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$r -eq "ok" -or [string]$r -eq "manual") { Write-OK "Mod files extracted to $modFolder" }

# ---- STEP 5: verify launcher + desktop shortcut ----
Write-Step 5 6 "Finishing setup"
$launcherPath = Join-Path $modFolder $launcherName
if (-not (Test-Path $launcherPath)) {
    # Fallback: the zip may have unpacked into a nested subfolder - search.
    $found = Get-ChildItem -Path $modFolder -Filter $launcherName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $launcherPath = $found.FullName; $modFolder = Split-Path -Parent $launcherPath }
}
if (Test-Path $launcherPath) {
    Write-OK "Launcher found: $launcherName"
} else {
    Write-Warn "$launcherName not found under $modFolder - check the extracted files manually."
}

# Custom desktop-shortcut icon, shared by both mods. Copy the bundled
# .ico into the install root so the shortcut keeps a stable icon path
# (mirrors the BotW installer). Falls back to the launcher's own icon
# if the copy fails for any reason.
$iconDest = Join-Path $installRoot "ForzaHorizon6_VR.ico"
try { Copy-Item -Path (Join-Path $PSScriptRoot "ForzaHorizon6_VR.ico") -Destination $iconDest -Force } catch {}

try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "Forza Horizon 6 VR.lnk"
     $sc = New-DesktopShortcut -LnkPath $lnk -TargetPath $launcherPath -WorkingDir $modFolder -IconPath $(if (Test-Path $iconDest) { $iconDest } else { $launcherPath }) -Description "Launch the Forza Horizon 6 VR mod ($modName)"
    Write-OK "Desktop shortcut created with custom icon: Forza Horizon 6 VR"
} catch {
    Write-Warn "Could not create the desktop shortcut. You can start $launcherName from $modFolder."
}

# Record the PARENT install path. The Hub's TwoMods detection then
# checks both mod subfolders (NALULUNA / lufz) under it: VR Ready if
# either launcher is present, with a launch choice when both are.
# We deliberately do NOT write a .launch_exe override here - that would
# short-circuit the two-mod choice and always launch one fixed mod.
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $installRoot -Encoding UTF8 -Force } catch {}
# Clean up any stale single-launcher override from an older install.
try { $ov = Join-Path $PSScriptRoot ".launch_exe"; if (Test-Path $ov) { Remove-Item $ov -Force -ErrorAction SilentlyContinue } } catch {}

# ---- STEP 6: how to play ----
Write-Step 6 6 "How to play"
Write-Host "============================================================" -ForegroundColor Yellow
if ($modChoice -eq "1") {
    Write-Host " NALULUNA - HOW TO PLAY" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " 1) Start from the desktop shortcut (or run fh6vr.exe) and" -ForegroundColor White
    Write-Host "    press the 'Launch' button to start Forza Horizon 6." -ForegroundColor White
    Write-Host " 2) Once you are in a car, press Tab a few times to switch" -ForegroundColor White
    Write-Host "    to cockpit view - that view is shown in the headset." -ForegroundColor White
    Write-Host " 3) Ctrl + Space recenters the headset." -ForegroundColor White
    Write-Host ""
    Write-Host " Settings: lower graphics, V-Sync OFF, frame rate unlimited," -ForegroundColor Gray
    Write-Host " motion blur / DLSS / frame generation OFF. DIBR mode is the" -ForegroundColor Gray
    Write-Host " smoothest starting point." -ForegroundColor Gray
    Write-Host ""
    Write-Host " Can't see the in-car UI (map, speedometer, etc.)? In Settings >" -ForegroundColor Gray
    Write-Host " HUD & Gameplay, set 'HUD Safe Frame Vertical' to 25 (far right)." -ForegroundColor Gray
} else {
    Write-Host " lufz VRMod - HOW TO PLAY" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " 1) Start from the desktop shortcut (or run vrmod-launcher.exe)." -ForegroundColor White
    Write-Host " 2) Browse to your ForzaHorizon6.exe (or use Auto-detect" -ForegroundColor White
    Write-Host "    Running), then click 'Install VR Mod'." -ForegroundColor White
    Write-Host " 3) Start SteamVR, start the game, then click 'Play in VR'" -ForegroundColor White
    Write-Host "    once you reach the main menu, garage, or are driving." -ForegroundColor White
    Write-Host ""
    Write-Host " Settings: for OpenXR 6DoF turn HDR OFF and set in-game FOV to" -ForegroundColor Gray
    Write-Host " maximum. SimVR allows frame generation. On NVIDIA you can try" -ForegroundColor Gray
    Write-Host " the experimental Frame Generation toggle in the launcher." -ForegroundColor Gray
}
Write-Host ""
Write-Host " Your VR mod is installed here (opening it now):" -ForegroundColor White
Write-Host "   $modFolder" -ForegroundColor Gray
Write-Host " Run it from this folder or the desktop shortcut - the launcher" -ForegroundColor Gray
Write-Host " connects to Forza Horizon 6 itself." -ForegroundColor Gray
try { Start-Process $modFolder } catch {}
# ---- Signoff ----
Write-Host ""
Write-Host " Chase the horizon, feel every gear change, and let the festival roar." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
