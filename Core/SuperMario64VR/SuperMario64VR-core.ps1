# ============================================================
# Super Mario Coop VR Installer (sm64coopdx VR, by RaYRoD)
# ============================================================
# sm64coopdx VR brings Super Mario 64 into VR, built on the sm64coopdx
# PC port. Same exe runs VR (headset connected) or flat (no headset).
# This installer downloads the latest sm64coopdx VR release from GitHub
# and unpacks it to C:\Games\Super Mario Coop VR (or a folder you pick).
#
# The user supplies their own Super Mario 64 US .z64 ROM, placed as
# baserom.us.z64 in the game folder (or dropped onto the game window on
# first run). No game ROM is downloaded or shipped.
#
# Install layout:
#   <install_root>\Super Mario Coop VR\sm64coopdx.exe
#   <install_root>\Super Mario Coop VR\baserom.us.z64  (your ROM)
#   default install_root: C:\Games (fallback D:\Games, E:\Games)
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Super Mario Coop VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Super Mario Coop VR Installer" -ForegroundColor Cyan
    Write-Host " sm64coopdx VR by RaYRoD | Super Mario 64 US ROM required" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR        = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO_API_LATEST   = "https://api.github.com/repos/RaYRoD-TV/sm64coopdx-vr/releases"
$RELEASES_LATEST   = "https://github.com/RaYRoD-TV/sm64coopdx-vr/releases"
$INFO_URL          = "https://github.com/RaYRoD-TV/sm64coopdx-vr"
# Last-known-good asset, used only if the GitHub API cannot be reached.
# (The API path above always prefers the newest release.)
$KNOWN_FALLBACK_ZIP = "https://github.com/RaYRoD-TV/sm64coopdx-vr/releases/latest"
$GAME_FOLDER       = "Super Mario Coop VR"
$GAME_EXE          = "sm64coopdx.exe"
$DEFAULT_ROOTS     = @("C:\Games", "D:\Games", "E:\Games")

# Resolve the newest sm64coopdx*.zip asset via the GitHub API. Returns the
# browser_download_url, or $null on any failure (rate limit / offline /
# shape change) - the caller then falls back to the known URL + manual link.
function Get-Latestsm64coopdxZipUrl {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rels = Invoke-RestMethod -Uri $REPO_API_LATEST -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        # /releases returns ALL releases (incl. pre-releases) newest-first, so
        # this works even when the repo has only pre-releases (then
        # /releases/latest 404s). Take the newest release that ships a .zip,
        # preferring a win64 build, else the first .zip.
        foreach ($rel in @($rels)) {
            $zips = @($rel.assets | Where-Object { $_.name -match '(?i)\.zip$' })
            if ($zips.Count -gt 0) {
                $pick = $zips | Where-Object { $_.name -match '(?i)win' } | Select-Object -First 1
                if (-not $pick) { $pick = $zips[0] }
                if ($pick -and $pick.browser_download_url) { return [string]$pick.browser_download_url }
            }
        }

    } catch { }
    return $null
}

Write-Header

Write-Host "  sm64coopdx VR brings Super Mario 64 into immersive VR, built on" -ForegroundColor Gray
Write-Host "  the sm64coopdx PC port. With a headset on, the game renders in" -ForegroundColor Gray
Write-Host "  VR and you can lean around and look into the world. With no" -ForegroundColor Gray
Write-Host "  headset it just runs as the normal flat game - same exe, it" -ForegroundColor Gray
Write-Host "  works out which one you want on its own. VR work by RaYRoD." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    Super Mario 64 - US (NTSC) .z64 ROM that you own." -ForegroundColor Yellow
Write-Host "  Nothing from Nintendo is downloaded or included - only the" -ForegroundColor Gray
Write-Host "  sm64coopdx VR app is fetched (from the official GitHub releases)." -ForegroundColor Gray
Write-Host "  The game reads the ROM locally and it never leaves your PC." -ForegroundColor Gray
Write-Host ""
Write-Host "  Tested on Quest 3 and Pimax Dream Air, but it should run with" -ForegroundColor Gray
Write-Host "  any PCVR / OpenXR runtime." -ForegroundColor Gray
Pause-User "Press Enter to begin the installation or update..." | Out-Null

# ---- 1. pick a writable install root ------------------------
Write-Step 1 5 "Choosing an install or update location"

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

Write-Host "  Default location: C:\Games\$GAME_FOLDER" -ForegroundColor White
Write-Host "  Press Enter to accept it, or type a different folder to install into" -ForegroundColor Gray
Write-Host "  (the '$GAME_FOLDER' folder is created inside whatever you choose)." -ForegroundColor Gray
$chosen = (Read-Host "  Install root [C:\Games]").Trim().Trim('"')

$installRoot = $null
if ($chosen) {
    if (Test-WritableRoot -Root $chosen) { $installRoot = [string]$chosen }
    else { Write-Fail "Not writable: $chosen - falling back to the defaults." }
}
if (-not $installRoot) {
    foreach ($r in $DEFAULT_ROOTS) {
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r; break }
    }
}
if (-not $installRoot) {
    Write-Warn "None of C:\Games, D:\Games, E:\Games is writable."
    Write-Host "  Enter a folder where the game should be installed." -ForegroundColor White
    while (-not $installRoot) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
Write-OK "Install root: $installRoot"
$gameRoot = Join-Path $installRoot $GAME_FOLDER

# ---- 2. download the latest sm64coopdx release ---------------
# --- Update-or-install choice (shared helper) ---
$InstallMode = Read-UpdateOrInstall -GameFolder $gameRoot -ModFile "sm64coopdx.exe"
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the mod files." }

Write-Step 2 5 "Downloading sm64coopdx (latest release)"

$tmp = Join-Path $installRoot "_hub_extract_tmp"
try {
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Fail "Could not create a temp folder under $installRoot : $_"
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
$zipDest = Join-Path $tmp "sm64coopdx_latest.zip"

$urls = New-Object System.Collections.Generic.List[string]
Write-Info "Resolving the newest release via the GitHub API..."
$apiUrl = Get-Latestsm64coopdxZipUrl
if ($apiUrl) {
    Write-OK "Latest release asset: $apiUrl"
    [void]$urls.Add($apiUrl)
} else {
    Write-Warn "GitHub API not reachable (rate limit / offline). Using last-known URL."
}
# Always also queue the known-good URL as a secondary source.
if ([string]$apiUrl -ne [string]$KNOWN_FALLBACK_ZIP) { [void]$urls.Add($KNOWN_FALLBACK_ZIP) }

Invoke-SafeDownload -Urls $urls -Destination $zipDest `
    -Label "sm64coopdx (Super Mario Coop VR build)" `
    -ManualUrl $RELEASES_LATEST `
    -Instructions "Open the releases page, download the newest 'sm64coopdx.vX.Y.Z.zip', save it as '$zipDest', then choose Retry." `
    -SkipMessage "" | Out-Null

# Hard guarantee: regardless of the helper's outcome, make sure we have a ZIP.
while (-not (Test-Path $zipDest)) {
    Write-Fail "The sm64coopdx download is not present at: $zipDest"
    $fb = Invoke-InstallerFallback -Action "download sm64coopdx" `
        -Subject "the latest sm64coopdx release" `
        -Url $RELEASES_LATEST `
        -DestFile $zipDest `
        -Instructions "Download the newest 'sm64coopdx.vX.Y.Z.zip' from the releases page, save it as '$zipDest', then choose Retry. You can also paste the full path to an already-downloaded ZIP." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
}
Write-OK "sm64coopdx archive ready: $zipDest"

# ---- 3. extract + flatten into the game folder --------------
Write-Step 3 5 "Installing sm64coopdx"

$unpack = Join-Path $tmp "unpack"
$extractOk = $false
while (-not $extractOk) {
    try {
        if (Test-Path $unpack) { Remove-Item $unpack -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $unpack -Force -ErrorAction Stop | Out-Null
        Expand-Archive -Path $zipDest -DestinationPath $unpack -Force -ErrorAction Stop
        $extractOk = $true
    } catch {
        Write-Fail "Could not extract the ZIP: $_"
        $fb = Invoke-InstallerFallback -Action "extract the sm64coopdx ZIP" `
            -Subject "the downloaded sm64coopdx ZIP" `
            -Url $RELEASES_LATEST `
        -DestFile $zipDest `
            -Instructions "The ZIP may be incomplete. Re-download the newest 'sm64coopdx.vX.Y.Z.zip', save it as '$zipDest', then choose Retry. Or paste the path to a fresh ZIP." `
            -AllowSkip $false
        if ([string]$fb -eq "quit") {
            try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        $again = (Read-Host "  ZIP path (Enter to retry same)").Trim().Trim('"')
        if ($again -and (Test-Path $again) -and ($again -match '\.zip$')) { $zipDest = [string]$again }
    }
}

# The release ZIP wraps everything in an x64\ folder. Find sm64coopdx.exe
# anywhere in the tree and treat its folder as the real payload root, so
# this works whether the layout is wrapped or flat.
$exeItem = Get-ChildItem -Path $unpack -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
while (-not $exeItem) {
    Write-Fail "'$GAME_EXE' not found in the extracted files."
    $fb = Invoke-InstallerFallback -Action "find $GAME_EXE in the download" `
        -Subject "the sm64coopdx download" `
        -Url $RELEASES_LATEST `
        -DestFile $zipDest `
        -Instructions "The ZIP did not contain $GAME_EXE - it may be the wrong file. Grab the newest 'sm64coopdx.vX.Y.Z.zip' from the releases page, save it as '$zipDest', then choose Retry." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
    $again = (Read-Host "  ZIP path (Enter to retry same)").Trim().Trim('"')
    if ($again -and (Test-Path $again) -and ($again -match '\.zip$')) {
        $zipDest = [string]$again
        try {
            if (Test-Path $unpack) { Remove-Item $unpack -Recurse -Force -ErrorAction SilentlyContinue }
            New-Item -ItemType Directory -Path $unpack -Force -ErrorAction Stop | Out-Null
            Expand-Archive -Path $zipDest -DestinationPath $unpack -Force -ErrorAction Stop
        } catch { Write-Fail "Re-extract failed: $_" }
    }
    $exeItem = Get-ChildItem -Path $unpack -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
$payloadDir = Split-Path -Parent $exeItem.FullName

# Preserve the user's ROM + saves + mods across a reinstall (they live in
# the game folder, which we are about to wipe).
$preserveDir = Join-Path $tmp "user_backup"
$preserved = @()
try { New-Item -ItemType Directory -Path $preserveDir -Force -ErrorAction Stop | Out-Null } catch {}
foreach ($__it in @("baserom.us.z64", "mods", "sav", "save", "coopnet")) {
    $__src = Join-Path $gameRoot $__it
    if (Test-Path -LiteralPath $__src) {
        try { Move-Item -LiteralPath $__src -Destination (Join-Path $preserveDir $__it) -Force -ErrorAction Stop; $preserved += $__it } catch {}
    }
}

$placedOk = $false
while (-not $placedOk) {
    try {
        if (Test-Path $gameRoot) { Remove-Item $gameRoot -Recurse -Force -ErrorAction Stop }
        New-Item -ItemType Directory -Path $gameRoot -Force -ErrorAction Stop | Out-Null
        $null = Get-ChildItem -Path $payloadDir -Force | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $gameRoot -Force -ErrorAction Stop
        }
        $placedOk = $true
    } catch {
        Write-Fail "Could not place the game files: $_"
        $fb = Invoke-InstallerFallback -Action "copy the sm64coopdx files into place" `
            -Instructions "Copy the CONTENTS of '$payloadDir' into '$gameRoot' (so that $GAME_EXE sits at its root). Then choose Retry, or Skip to finish manually." `
            -SourceFolder "$payloadDir" `
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
Write-OK "Game installed at: $gameRoot"

# ---- 4. provide the Super Mario 64 US ROM ------------------
Write-Step 4 5 "Your Super Mario 64 US ROM"

# Restore anything preserved from a previous install.
if ($preserved.Count -gt 0) {
    foreach ($__it in $preserved) {
        try { Move-Item -LiteralPath (Join-Path $preserveDir $__it) -Destination (Join-Path $gameRoot $__it) -Force -ErrorAction Stop } catch {}
    }
    Write-OK "Kept your existing ROM / saves / mods."
}

$baserom = Join-Path $gameRoot "baserom.us.z64"
$romPlaced = (Test-Path -LiteralPath $baserom)
if ($romPlaced) {
    Write-OK "baserom.us.z64 is already in place - you're set."
} else {
    Write-Host "  You must provide your OWN Super Mario 64 US ROM (.z64)." -ForegroundColor White
    Write-Host "  Nothing from Nintendo is downloaded or included; the game" -ForegroundColor Gray
    Write-Host "  reads the ROM locally and it never leaves your PC." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Drag your .z64 file onto THIS window, then press Enter" -ForegroundColor White
    Write-Host "  (it is copied in as baserom.us.z64). A .zip / .7z / .rar" -ForegroundColor White
    Write-Host "  that contains the ROM works too - it is unpacked" -ForegroundColor White
    Write-Host "  automatically. Or just press Enter to skip - you can also" -ForegroundColor White
    Write-Host "  drop a .z64 onto the game window on first launch and it" -ForegroundColor White
    Write-Host "  sets itself up." -ForegroundColor White
    Write-Host ""
    $romIn = (Read-Host "  ROM path (or Enter to skip)").Trim().Trim('"')
    if ($romIn -and (Test-Path -LiteralPath $romIn)) {
        $romSource = $romIn
        $romTmp    = $null
        $ext = [System.IO.Path]::GetExtension($romIn).ToLower()
        # If an archive was dropped, unpack it and locate the .z64 inside.
        # ROM downloads are often a .zip/.7z/.rar holding the .z64. We take
        # the largest .z64 found (the real ROM). Uses the shared multi-format
        # extractor (7-Zip if present, else PowerShell's zip fallback).
        if ($ext -in @(".zip", ".7z", ".rar")) {
            Write-Info "Archive detected - unpacking and locating the .z64 inside..."
            $romTmp = Join-Path $env:TEMP ("sm64_rom_" + [Guid]::NewGuid().ToString("N"))
            try {
                New-Item -ItemType Directory -Path $romTmp -Force -ErrorAction Stop | Out-Null
                Expand-ArchiveOrFallback -ArchivePath $romIn -DestinationFolder $romTmp -Label "Super Mario 64 ROM" `
                    -SkipMessage "Skipped - the archive was not unpacked." | Out-Null
                $inner = Get-ChildItem -LiteralPath $romTmp -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Extension.ToLower() -eq ".z64" } |
                    Sort-Object Length -Descending | Select-Object -First 1
                if ($inner) {
                    $romSource = $inner.FullName
                    Write-OK "Found ROM in archive: $($inner.Name)"
                } else {
                    Write-Warn "No .z64 ROM found inside the archive."
                    Write-Host "    Put your ROM here yourself, named baserom.us.z64:" -ForegroundColor Gray
                    Write-Host "    $gameRoot" -ForegroundColor Cyan
                    $romSource = $null
                    try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                }
            } catch {
                Write-Warn "Could not unpack the archive: $_"
                Write-Host "    Put your ROM here yourself, named baserom.us.z64:" -ForegroundColor Gray
                Write-Host "    $gameRoot" -ForegroundColor Cyan
                $romSource = $null
                try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            }
        }
        if ($romSource) {
            try {
                Copy-Item -LiteralPath $romSource -Destination $baserom -Force -ErrorAction Stop
                Write-OK "ROM set up as baserom.us.z64."
                $romPlaced = $true
            } catch {
                Write-Warn "Could not copy the ROM: $_"
                Write-Host "    Put it here yourself, named baserom.us.z64:" -ForegroundColor Gray
                Write-Host "    $gameRoot" -ForegroundColor Cyan
            }
        }
        if ($romTmp) { try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {} }
    } elseif ($romIn) {
        Write-Warn "That path was not found - skipping."
        Write-Host "    Put your ROM here, named baserom.us.z64:" -ForegroundColor Gray
        Write-Host "    $gameRoot" -ForegroundColor Cyan
    } else {
        Write-Info "Skipped - drop a .z64 onto the game window on first launch."
    }
}

# ---- 5. desktop shortcut + finish ---------------------------
Write-Step 5 5 "Creating a desktop shortcut"
$exePath = Join-Path $gameRoot $GAME_EXE
if (-not (Test-Path $exePath)) {
    Write-Warn "Game EXE not found after install - shortcut skipped."
    Write-Host "  Open '$gameRoot' and confirm $GAME_EXE is there; if it sits in a" -ForegroundColor Gray
    Write-Host "  subfolder, move that folder's contents up one level." -ForegroundColor Gray
} else {
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $lnkPath = Join-Path $desktop "Super Mario Coop VR.lnk"
        $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $exePath -WorkingDir $gameRoot -IconPath $exePath
        Write-OK "Desktop shortcut created: Super Mario Coop VR"
    } catch {
        Write-Warn "Could not create the desktop shortcut: $_"
        Write-Host "  You can launch the game manually with:" -ForegroundColor Gray
        Write-Host "    $exePath" -ForegroundColor Cyan
    }
}

# Record the install path so the Hub's "VR Installed" check + Start-in-VR find it.
try {
    Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Force -ErrorAction Stop
} catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Super Mario Coop VR (sm64coopdx) is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  How to play:" -ForegroundColor White
Write-Host "   1. Start your VR runtime first (Quest Link, Virtual Desktop," -ForegroundColor White
Write-Host "      or SteamVR) if you want VR." -ForegroundColor White
Write-Host "   2. Launch with the 'Super Mario Coop VR' desktop shortcut, or run:" -ForegroundColor White
Write-Host "        $exePath" -ForegroundColor Cyan
Write-Host "   3. Same exe for both: with a headset connected it boots into" -ForegroundColor White
Write-Host "      VR, otherwise you get the flat game." -ForegroundColor White
if (-not $romPlaced) {
    Write-Host "   4. No ROM yet: drop your Super Mario 64 US .z64 onto the game" -ForegroundColor White
    Write-Host "      window on first launch, or place it here as baserom.us.z64:" -ForegroundColor White
    Write-Host "        $gameRoot" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "  Play solo: click Play on the main menu - fully offline. Co-op" -ForegroundColor Gray
Write-Host "  still works too (Host, or join by IP)." -ForegroundColor Gray
Write-Host ""
Write-Host "  VR controls: left stick moves, right stick is the camera, A jump," -ForegroundColor Gray
Write-Host "  B punch, left trigger crouch/ground-pound, grips grab/throw, left" -ForegroundColor Gray
Write-Host "  menu button pauses, right-stick click cycles the VR mode." -ForegroundColor Gray
Write-Host "  All VR settings are in the in-game pause menu under 'VR' (right" -ForegroundColor Gray
Write-Host "  after Cheats). D-pad up or F10 cycles Diorama / Third / First person." -ForegroundColor Gray
Write-Host ""

try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Write-Host "  Wahoo! Grab your cap and go bag every last star." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
