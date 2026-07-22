# ============================================================
# Saints Row: The Third VR Installer
# Layers zolika1351's ZMenu (trainer/menu) with its VR build
# onto an EXISTING, user-owned copy of Saints Row: The Third
# (Steam or GOG). We ship ZERO game files. The mod is hosted on
# MEGA and cannot be fetched automatically - the user downloads
# the zip and drags it in. We copy the menu files into the game
# folder, then overlay the "build with VR support" contents on
# top (which swaps in the VR-enabled ZMenuSR3.asi + openvr_api).
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Saints Row: The Third VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME    = "Saints Row: The Third"
$GAME_EXE     = "SaintsRowTheThird_DX11.exe"
$STEAM_FOLDER = "Saints Row the Third"
$GOG_FOLDER   = "Saints Row 3"
$APP_ID       = "55230"
$INFO_URL     = "https://zolika1351.pages.dev/mods/sr3menu"
$MEGA_URL     = "https://mega.nz/file/jZQikZBD#tT2K3URk_7SvTR9kEep2m-RPIh4eKEcAdVXXSuM1B1w"
$VR_FOLDER    = "build with VR support"
$MOD_MARKER   = "openvr_api.dll"
$SHORTCUT     = "Saints Row The Third VR"

# ---- inline console helpers --------------------------------
function Write-Header {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  Saints Row: The Third - ZMenu + VR Installer" -ForegroundColor White
    Write-Host "  Mod by zolika1351   |   $INFO_URL" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
}
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [XX] $t" -ForegroundColor Red }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# ---- folder detection --------------------------------------
# Drag the Saints Row folder or the DX11 exe onto the window.
# Resolves the folder that holds the DX11 exe. Loops until valid
# or cancelled (empty input).
function Get-Sr3Folder {
    while ($true) {
        Write-Host ""
        Write-Host " Drag your Saints Row: The Third folder (or $GAME_EXE)" -ForegroundColor White
        Write-Host " onto this window and press Enter." -ForegroundColor White
        Write-Host " (You can also type or paste the full path.)" -ForegroundColor Gray
        Write-Host " Leave empty and press Enter to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " Path"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path $p)) { Write-Warn "Path not found: $p"; continue }
        if (Test-Path $p -PathType Container) {
            if (Test-Path (Join-Path $p $GAME_EXE)) { return $p }
            Write-Warn "No $GAME_EXE in that folder (the exe name can vary by version)."
            $ok = (Read-Host "  Use this folder anyway? [Y]es / [N]o").Trim().ToLower()
            if ($ok -eq "y") { return $p }
            continue
        }
        $dir = Split-Path -Parent $p
        return $dir
    }
}

# Drag a downloaded file here. Accepts the listed extensions, or a
# folder (an already-extracted copy of the mod). Loops until valid
# or the user leaves it empty (cancel).
function Get-DroppedItem {
    param([string]$Label, [string[]]$Exts)
    while ($true) {
        Write-Host ""
        Write-Host " Drag the downloaded $Label onto this window and press Enter," -ForegroundColor Yellow
        Write-Host " or leave empty to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " File or folder"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path $p)) { Write-Warn "Not found: $p"; continue }
        if (Test-Path $p -PathType Container) { return $p }   # already-extracted folder is fine
        $ext = [System.IO.Path]::GetExtension($p).ToLower()
        if ($Exts -and ($Exts -notcontains $ext)) {
            Write-Warn "That is a '$ext' file. Expected one of: $($Exts -join ', '), or a folder."
            continue
        }
        return $p
    }
}

# Mirror a directory tree into a destination, merging and
# overwriting files (safe to run on a re-install). Returns the
# number of files copied.
function Copy-Tree {
    param([string]$Src, [string]$Dst)
    $count = 0
    if (-not (Test-Path $Dst)) { New-Item -ItemType Directory -Path $Dst -Force | Out-Null }
    Get-ChildItem -Path $Src -Force -Recurse | ForEach-Object {
        $rel = $_.FullName.Substring($Src.Length).TrimStart('\')
        $target = Join-Path $Dst $rel
        if ($_.PSIsContainer) {
            if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
        } else {
            $tdir = Split-Path -Parent $target
            if (-not (Test-Path $tdir)) { New-Item -ItemType Directory -Path $tdir -Force | Out-Null }
            Copy-Item -Path $_.FullName -Destination $target -Force
            $count++
        }
    }
    return $count
}


# ============================================================
Write-Header

# ---- STEP 1: locate Saints Row: The Third ----
Write-Host " This installs zolika1351's ZMenu plus its VR build onto Saints Row: The" -ForegroundColor White
Write-Host " Third Remastered, adding a stereoscopic VR view. Gamepad controls." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 4 "Locating your Saints Row: The Third install"
$gameDir = $null
try { $gameDir = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @($STEAM_FOLDER) -ProbeExe $GAME_EXE -GogNames @($GOG_FOLDER) } catch { $gameDir = $null }

if ($gameDir) {
    Write-OK "Found: $gameDir"
} else {
    Write-Warn "Could not auto-detect the install (Steam / GOG)."
    Write-Info "Steam:       ...\steamapps\common\$STEAM_FOLDER"
    Write-Info "GOG Galaxy:  C:\Program Files (x86)\GOG Galaxy\Games\$GOG_FOLDER"
    Write-Info "GOG offline: C:\GOG Games\$GOG_FOLDER"
    $gameDir = Get-Sr3Folder
    if (-not $gameDir) {
        # Last-resort manual path entry (shared helper).
        $manual = Get-GameFolderInteractive -GameName $GAME_NAME -ProbeFile $GAME_EXE -ManualUrl $INFO_URL
        if ($manual -and ($manual -notin @("quit","skip")) -and (Test-Path $manual)) {
            $gameDir = $manual
        }
    }
}
if (-not $gameDir) {
    Write-Fail "No valid Saints Row: The Third folder - cannot continue."
    Write-Info "Make sure the game is installed and that $GAME_EXE exists in its folder."
    Pause-User "Press Enter to exit..." -Color Yellow
    exit 1
}
Write-OK "Game folder: $gameDir"

# ---- STEP 2: get the mod from MEGA (manual download) ----
Write-Step 2 4 "Downloading the ZMenu + VR build"
Write-Host " The mod is hosted on MEGA, so it has to be downloaded by hand." -ForegroundColor White
Write-Host " 1) The MEGA page will open in your browser." -ForegroundColor White
Write-Host " 2) Download ZMenuSR3_v23_07_27_1.zip (this exact version)." -ForegroundColor White
Write-Host "    Do NOT use a newer build - newer ZMenu versions are incompatible." -ForegroundColor Yellow
Write-Host " 3) Come back here and drag that zip onto this window." -ForegroundColor White
Write-Host ""
Write-Host " Page:  $MEGA_URL" -ForegroundColor DarkGray
Pause-User "Press Enter to open the MEGA download page..." -Color Yellow
try { Start-Process $MEGA_URL } catch { Write-Warn "Could not open the browser. Open this link manually:"; Write-Host "   $MEGA_URL" -ForegroundColor Cyan }

$drop = Get-DroppedItem -Label "ZMenu zip (or an already-extracted folder)" -Exts @(".zip", ".7z", ".rar")
if (-not $drop) {
    Write-Fail "No file provided - cannot install without the mod."
    Pause-User "Press Enter to exit..." -Color Yellow
    exit 1
}
Write-OK "Got: $drop"

# ---- STEP 3: extract + install into the game folder ----
Write-Step 3 4 "Installing the menu and VR build"

# Resolve a folder that holds the mod files (extract the archive,
# or use the dragged folder directly).
$modRoot = $null
if (Test-Path $drop -PathType Container) {
    $modRoot = $drop
    Write-Info "Using the dragged folder directly (no extraction needed)."
} else {
    $xtemp = Join-Path $env:TEMP ("sr3vr_" + [System.IO.Path]::GetRandomFileName())
    try { New-Item -ItemType Directory -Force -Path $xtemp | Out-Null } catch {}
    $extracted = $false
    try { Expand-Archive -Path $drop -DestinationPath $xtemp -Force; $extracted = $true } catch { Write-Warn "Built-in extraction failed: $_" }
    if (-not $extracted) {
        # Fallback: 7z / manual extraction helper.
        try { $r = Expand-ArchiveOrFallback -ArchivePath $drop -DestinationFolder $xtemp -Label "ZMenu zip"; if ($r) { $extracted = $true } } catch {}
    }
    if (-not $extracted) {
        Write-Fail "Could not extract the archive."
        Write-Info "Extract it yourself, then re-run and drag the extracted folder in."
        Pause-User "Press Enter to exit..." -Color Yellow
        exit 1
    }
    $modRoot = $xtemp
}

# Find the actual mod root inside the extraction: the folder that
# holds the VR build subfolder, or failing that, dinput8.dll.
$vrDir = Get-ChildItem -Path $modRoot -Recurse -Directory -Filter $VR_FOLDER -ErrorAction SilentlyContinue | Select-Object -First 1
if ($vrDir) {
    $modRoot = Split-Path -Parent $vrDir.FullName
} else {
    $loaderHit = Get-ChildItem -Path $modRoot -Recurse -Filter "dinput8.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($loaderHit) { $modRoot = Split-Path -Parent $loaderHit.FullName }
}
Write-Info "Mod files: $modRoot"

$vrSupport = Join-Path $modRoot $VR_FOLDER
$copied = 0

# Pass 1: copy everything EXCEPT the "build with VR support" folder
# into the game folder.
try {
    Get-ChildItem -Path $modRoot -Force | Where-Object { $_.Name -ne $VR_FOLDER } | ForEach-Object {
        if ($_.PSIsContainer) { $copied += (Copy-Tree -Src $_.FullName -Dst (Join-Path $gameDir $_.Name)) }
        else { Copy-Item -Path $_.FullName -Destination (Join-Path $gameDir $_.Name) -Force; $copied++ }
    }
    Write-OK "Copied the base menu files into the game folder."
} catch {
    Write-Fail "Could not copy the base files: $_"
    Pause-User "Press Enter to exit..." -Color Yellow
    exit 1
}

# Pass 2: overlay the CONTENTS of "build with VR support" into the
# game folder (this swaps in the VR ZMenuSR3.asi + openvr_api.dll +
# the vr_actions json files). The folder itself is NOT copied.
if (Test-Path $vrSupport) {
    try {
        Get-ChildItem -Path $vrSupport -Force | ForEach-Object {
            if ($_.PSIsContainer) { $copied += (Copy-Tree -Src $_.FullName -Dst (Join-Path $gameDir $_.Name)) }
            else { Copy-Item -Path $_.FullName -Destination (Join-Path $gameDir $_.Name) -Force; $copied++ }
        }
        Write-OK "Applied the VR build on top."
    } catch {
        Write-Warn "Could not apply the VR build: $_"
        Write-Warn "The menu may work but VR will not. Re-run to try again."
    }
} else {
    Write-Warn "'$VR_FOLDER' not found in the download - VR will not be enabled."
    Write-Warn "Make sure you downloaded the full ZMenu zip from the MEGA page."
}

# Verify the VR marker landed.
if (Test-Path (Join-Path $gameDir $MOD_MARKER)) {
    Write-OK "$MOD_MARKER present - VR build installed ($copied files copied)."
} else {
    Write-Warn "$MOD_MARKER missing after install - VR may not be active."
}

# Record where we installed so the Hub launches the modded exe.
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch { Write-Warn "Could not write .installed_path (the Hub may need a manual path)." }

# Desktop shortcut to the DX11 exe (the mod loads via dinput8.dll
# when this exe runs).
$exePath = Join-Path $gameDir $GAME_EXE
if (Test-Path $exePath) {
    $lnk = New-DesktopShortcut -TargetPath $exePath -ShortcutName $SHORTCUT -WorkingDir $gameDir
    if ($lnk) { Write-OK "Desktop shortcut created: $SHORTCUT.lnk" }
    else { Write-Warn "Could not create the desktop shortcut (not critical)." }
} else {
    Write-Warn "$GAME_EXE not found in the game folder - skipping shortcut."
}

# ---- STEP 4: how to play in VR ----
Write-Step 4 4 "How to start VR in-game"
Write-Host " Launch with 'Start in VR' in the Hub, or the new desktop shortcut" -ForegroundColor White
Write-Host " the Hub's Start button, or run the DX11 exe directly)." -ForegroundColor White
Write-Host ""
Write-Host " Once you are in the game:" -ForegroundColor White
Write-Host "   1) Press F7 to open the ZMenu trainer menu." -ForegroundColor White
Write-Host "   2) Scroll down to VR and press it." -ForegroundColor White
Write-Host "   3) Choose Start VR. That is all - put on your headset." -ForegroundColor White
Write-Host ""
Write-Host " You can stop VR again from the same menu at any time." -ForegroundColor Gray
Write-Host ""
Write-Host " Tips:" -ForegroundColor White
Write-Host "   - In Misc - Game Tweaks, disable fake distant vehicles and" -ForegroundColor Gray
Write-Host "     peds, or they may sometimes spawn right next to you." -ForegroundColor Gray
Write-Host "   - Low FPS? Enable Performance Mode and adjust its settings." -ForegroundColor Gray
Pause-User "Press Enter when you have read the steps above..." -Color Yellow

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Done! ZMenu + VR build is installed." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Steelport is yours, Boss - now reach out and run the city with your own two hands." -ForegroundColor Magenta

Pause-User "Press Enter to exit..."
