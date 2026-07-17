# ============================================================
# Forza Horizon 5 VR Installer
# lufz / VRMod (flat2VR Discord)   launcher: vrmod-launcher.exe
# VRMod v1.2.2 supports Forza Horizon 5 and 6 from the same
# launcher. The launcher injects into the game; the mod files
# must NOT live in the game folder, so we extract to
# C:\Games\Forza Horizon 5 VR and launch from there.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Forza Horizon 5 VR Installer"
$ErrorActionPreference = "Stop"

$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")
$GAME_FOLDER   = "Forza Horizon 5 VR"
$FLAT2VR_URL   = "https://discord.gg/uAeQkYBM4n"
$LUF_POST_URL  = "https://discord.com/channels/747967102895390741/1509055901582233740/1527195267823046697"
$ZIP_HINT      = "VRMod-v1_2_1.zip"
$LAUNCHER_NAME = "vrmod-launcher.exe"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Forza Horizon 5 VR Installer" -ForegroundColor Cyan
    Write-Host " lufz VRMod from the flat2VR Modding Discord" -ForegroundColor Gray
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
        if (-not (Test-Path -LiteralPath $p)) { Write-Warn "Path not found: $p"; continue }
        if (Test-Path -LiteralPath $p -PathType Container) { Write-Warn "That is a folder. Drag the .zip file itself."; continue }
        if ([System.IO.Path]::GetExtension($p) -ne ".zip") { Write-Warn "That is not a .zip file."; continue }
        return $p
    }
}

Write-Header
Write-Host " This sets up the lufz VRMod for your EXISTING Forza Horizon 5" -ForegroundColor White
Write-Host " install (Steam / Microsoft Store / Game Pass). No game files" -ForegroundColor Gray
Write-Host " are bundled - you download the free community mod yourself and" -ForegroundColor Gray
Write-Host " drag the .zip onto this window; the Hub does the rest." -ForegroundColor Gray
Write-Host ""

# ---- STEP 1: get the download ----
Write-Step 1 5 "Downloading the mod"
Write-Host "  lufz's VRMod is shared in the flat2VR Modding Discord." -ForegroundColor White
Write-Host "   - First the flat2VR invite opens; accept it to join." -ForegroundColor Gray
Write-Host "   - Then the download post opens; the file is named '$ZIP_HINT'." -ForegroundColor Gray
Pause-User "Press Enter to open the flat2VR invite..."
try { Start-Process $FLAT2VR_URL } catch { Write-Warn "Could not open the browser. Join manually: $FLAT2VR_URL" }
Pause-User "Press Enter once you have joined to open the download post..."
Write-Host "   - Opening the download post. The file is named '$ZIP_HINT'." -ForegroundColor Gray
try { Start-Process $LUF_POST_URL } catch { Write-Warn "Could not open the post. Open manually: $LUF_POST_URL" }
Write-Host ""
Write-Host "   ( If Discord won't scroll, you can also copy this link manually by selecting it (Ctrl+C) and pasting it into the browser's address bar (Ctrl+V) : $LUF_POST_URL )" -ForegroundColor DarkGray

# ---- STEP 2: drag the zip ----
Write-Step 2 5 "Locating the downloaded zip"
$zipPath = Get-DraggedZip -ExpectHint $ZIP_HINT
if (-not $zipPath) { Write-Info "No zip provided - cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
$zipLeaf = Split-Path -Leaf $zipPath
if ($zipLeaf -notlike "VRMod-*") {
    Write-Warn "Expected a 'VRMod-*.zip' - continuing anyway with '$zipLeaf'."
}
Write-OK "Using: $zipLeaf"

# ---- STEP 3: choose location + extract ----
Write-Step 3 5 "Installing the mod files"
$defaultParent = $null
foreach ($r in $DEFAULT_ROOTS) { if (Test-WritableRoot -Root $r) { $defaultParent = [string]$r; break } }
if (-not $defaultParent) { $defaultParent = "C:\Games" }
$installRoot = Join-Path $defaultParent $GAME_FOLDER
Write-Host "  Install location: $installRoot" -ForegroundColor Gray
Write-Host "  (Kept OUT of the game folder on purpose - the mod must not" -ForegroundColor DarkGray
Write-Host "   live inside Forza Horizon 5's own install folder.)" -ForegroundColor DarkGray
try { New-Item -ItemType Directory -Force -Path $installRoot | Out-Null } catch {}

$r = Expand-ArchiveOrFallback -ArchivePath $zipPath -DestinationFolder $installRoot -Label "lufz VRMod" `
        -SkipMessage "Skipped - the mod files were NOT extracted. The install is incomplete."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$r -eq "ok" -or [string]$r -eq "manual") { Write-OK "Mod files extracted to $installRoot" }

# ---- STEP 4: verify launcher + desktop shortcut ----
Write-Step 4 5 "Finishing setup"
$launcherPath = Join-Path $installRoot $LAUNCHER_NAME
if (-not (Test-Path $launcherPath)) {
    # Fallback: the zip may have unpacked into a nested subfolder - search.
    $found = Get-ChildItem -Path $installRoot -Filter $LAUNCHER_NAME -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $launcherPath = $found.FullName; $installRoot = Split-Path -Parent $launcherPath }
}
if (Test-Path $launcherPath) {
    Write-OK "Launcher found: $LAUNCHER_NAME"
} else {
    Write-Warn "$LAUNCHER_NAME not found under $installRoot - check the extracted files manually."
}

# Custom desktop-shortcut icon. Copy the bundled .ico into the install
# root so the shortcut keeps a stable icon path (mirrors the FH6
# installer). Falls back to the launcher's own icon if the copy fails.
$iconDest = Join-Path $installRoot "ForzaHorizon5_VR.ico"
try { Copy-Item -Path (Join-Path $PSScriptRoot "ForzaHorizon5_VR.ico") -Destination $iconDest -Force } catch {}

try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "Forza Horizon 5 VR.lnk"
    $sc = New-DesktopShortcut -LnkPath $lnk -TargetPath $launcherPath -WorkingDir $installRoot -IconPath $(if (Test-Path $iconDest) { $iconDest } else { $launcherPath }) -Description "Launch the Forza Horizon 5 VR mod (lufz VRMod)"
    Write-OK "Desktop shortcut created with custom icon: Forza Horizon 5 VR"
} catch {
    Write-Warn "Could not create the desktop shortcut. You can start $LAUNCHER_NAME from $installRoot."
}

# Record install path + launcher for the Hub. Single-mod game: the
# .launch_exe override makes "Start in VR" open vrmod-launcher.exe
# directly (unlike FH6, which keeps the two-mod choice instead).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $installRoot -Encoding UTF8 -Force } catch {}
try { Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value $launcherPath -Encoding UTF8 -Force } catch {}

# Record the installed mod version so the Hub's update badge works
# (catalog pins the current lufz version; a mismatch shows Update).
# NORMALIZED without a leading "v" - the Hub compares against
# Get-ModVersionFromString output, which strips the v.
#
# PRIMARY source: the VERSION file lufz ships inside the zip. It is
# authoritative and survives a renamed zip, so it beats parsing the
# file name. Fall back to the zip name, then to the pinned release.
#
# (History: the 1.2.1 hotfixes reused the same zip name AND VERSION,
# so the Hub had to track them as 1.2.1b/1.2.1c. lufz moved to a real
# 1.2.2, so that workaround is retired - the zip is honest again.)
$lufzVer = "1.2.2"
$lufzVerFile = Join-Path $installRoot "VERSION"
$lufzVerFound = $false
if (Test-Path -LiteralPath $lufzVerFile) {
    try {
        $fv = (Get-Content -LiteralPath $lufzVerFile -TotalCount 1 -ErrorAction Stop | Select-Object -First 1)
        if ($fv) { $fv = $fv.Trim() }
        if ($fv -match '^\d+\.\d+') { $lufzVer = $fv; $lufzVerFound = $true }
    } catch {}
}
if (-not $lufzVerFound -and $zipLeaf -match '(?i)VRMod[-_]v?([0-9][0-9_.]*)') {
    $pv = $matches[1].Replace("_", ".").Trim(".")
    if ($pv -match '^\d+\.\d+') { $lufzVer = $pv }
}
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $lufzVer -Encoding ASCII -Force } catch {}

# ---- STEP 5: how to play ----
Write-Step 5 5 "How to play"
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " lufz VRMod - HOW TO PLAY" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " 1) Start from the desktop shortcut (or run vrmod-launcher.exe)." -ForegroundColor White
Write-Host " 2) Browse to your ForzaHorizon5.exe (or start the game and use" -ForegroundColor White
Write-Host "    Auto-detect Running), select it, then click 'Install VR Mod'" -ForegroundColor White
Write-Host "    (needed once per game install folder)." -ForegroundColor White
Write-Host " 3) Start SteamVR, then click 'Play in VR' - it launches the" -ForegroundColor White
Write-Host "    game, or enables the headset if it is already running" -ForegroundColor White
Write-Host "    (best from the main menu, garage, or while driving)." -ForegroundColor White
Write-Host ""
Write-Host " Settings: for OpenXR 6DoF turn HDR OFF and set in-game FOV to" -ForegroundColor Gray
Write-Host " maximum. SimVR allows frame generation. On NVIDIA you can try" -ForegroundColor Gray
Write-Host " the experimental Frame Generation toggle in the launcher." -ForegroundColor Gray
Write-Host ""
Write-Host " Your VR mod is installed here (opening it now):" -ForegroundColor White
Write-Host "   $installRoot" -ForegroundColor Gray
Write-Host " Run it from this folder or the desktop shortcut - the launcher" -ForegroundColor Gray
Write-Host " connects to Forza Horizon 5 itself." -ForegroundColor Gray
try { Start-Process $installRoot } catch {}
# ---- Signoff ----
Write-Host ""
Write-Host " Viva Mexico - drop the roof, floor it, and chase that horizon." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
