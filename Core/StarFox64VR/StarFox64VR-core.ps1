# ============================================================
# Star Fox 64 VR Installer (Star Fox 64 VR, by RaYRoD)
# ============================================================
# Star Fox 64 VR brings Star Fox 64 into VR, built on the Starship
# PC port. Same exe runs VR (headset connected) or flat (no headset).
# This installer downloads the latest Star Fox 64 VR release from GitHub
# and unpacks it to C:\Games\Star Fox 64 VR (or a folder you pick).
#
# The user supplies their own Star Fox 64 US .z64 ROM, placed as
# their Star Fox 64 US .z64 ROM, selected via a file picker on first
# launch. No game ROM is downloaded or shipped.
#
# Install layout:
#   <install_root>\Star Fox 64 VR\Starship.exe
#   default install_root: C:\Games (fallback D:\Games, E:\Games)
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Star Fox 64 VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Star Fox 64 VR Installer" -ForegroundColor Cyan
    Write-Host " Star Fox 64 VR by RaYRoD | Star Fox 64 US ROM required" -ForegroundColor Gray
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
$REPO_API_LATEST   = "https://api.github.com/repos/RaYRoD-TV/StarFox64-VR/releases"
$RELEASES_LATEST   = "https://github.com/RaYRoD-TV/StarFox64-VR/releases"
$INFO_URL          = "https://github.com/RaYRoD-TV/StarFox64-VR"
# Last-known-good asset, used only if the GitHub API cannot be reached.
# (The API path above always prefers the newest release.)
$KNOWN_FALLBACK_ZIP = "https://github.com/RaYRoD-TV/StarFox64-VR/releases/download/v0.1.6-beta/StarFox64-VR-win64.zip"
$GAME_FOLDER       = "Star Fox 64 VR"
$GAME_EXE          = "Starship.exe"
$DEFAULT_ROOTS     = @("C:\Games", "D:\Games", "E:\Games")

# Resolve the newest Starship*.zip asset via the GitHub API. Returns the
# browser_download_url, or $null on any failure (rate limit / offline /
# shape change) - the caller then falls back to the known URL + manual link.
function Get-LatestStarshipZipUrl {
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

Write-Host "  Star Fox 64 VR brings Star Fox 64 into immersive VR, built on" -ForegroundColor Gray
Write-Host "  the Starship PC port. With a headset on, the game renders in" -ForegroundColor Gray
Write-Host "  VR and you can lean around and look into the world. With no" -ForegroundColor Gray
Write-Host "  headset it just runs as the normal flat game - same exe, it" -ForegroundColor Gray
Write-Host "  works out which one you want on its own. VR work by RaYRoD." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    Star Fox 64 - US (NTSC) .z64 ROM that you own." -ForegroundColor Yellow
Write-Host "  Nothing from Nintendo is downloaded or included - only the" -ForegroundColor Gray
Write-Host "  Star Fox 64 VR app is fetched (from the official GitHub releases)." -ForegroundColor Gray
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

# ---- 2. download the latest Starship release ---------------
# --- Update-or-install choice (shared helper) ---
$InstallMode = Read-UpdateOrInstall -GameFolder $gameRoot -ModFile "Starship.exe"
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the mod files." }

Write-Step 2 5 "Downloading Starship (latest release)"

$tmp = Join-Path $installRoot "_hub_extract_tmp"
try {
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Fail "Could not create a temp folder under $installRoot : $_"
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
$zipDest = Join-Path $tmp "Starship_latest.zip"

$urls = New-Object System.Collections.Generic.List[string]
Write-Info "Resolving the newest release via the GitHub API..."
$apiUrl = Get-LatestStarshipZipUrl
if ($apiUrl) {
    Write-OK "Latest release asset: $apiUrl"
    [void]$urls.Add($apiUrl)
} else {
    Write-Warn "GitHub API not reachable (rate limit / offline). Using last-known URL."
}
# Always also queue the known-good URL as a secondary source.
if ([string]$apiUrl -ne [string]$KNOWN_FALLBACK_ZIP) { [void]$urls.Add($KNOWN_FALLBACK_ZIP) }

Invoke-SafeDownload -Urls $urls -Destination $zipDest `
    -Label "Starship (Star Fox 64 VR build)" `
    -ManualUrl $RELEASES_LATEST `
    -Instructions "Open the releases page, download the newest 'Starship.vX.Y.Z.zip', save it as '$zipDest', then choose Retry." `
    -SkipMessage "" | Out-Null

# Hard guarantee: regardless of the helper's outcome, make sure we have a ZIP.
while (-not (Test-Path $zipDest)) {
    Write-Fail "The Starship download is not present at: $zipDest"
    $fb = Invoke-InstallerFallback -Action "download Starship" `
        -Subject "the latest Starship release" `
        -Url $RELEASES_LATEST `
        -DestFile $zipDest `
        -Instructions "Download the newest 'Starship.vX.Y.Z.zip' from the releases page, save it as '$zipDest', then choose Retry. You can also paste the full path to an already-downloaded ZIP." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
}
Write-OK "Starship archive ready: $zipDest"

# ---- 3. extract + flatten into the game folder --------------
Write-Step 3 5 "Installing Starship"

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
        $fb = Invoke-InstallerFallback -Action "extract the Starship ZIP" `
            -Subject "the downloaded Starship ZIP" `
            -Url $RELEASES_LATEST `
        -DestFile $zipDest `
            -Instructions "The ZIP may be incomplete. Re-download the newest 'Starship.vX.Y.Z.zip', save it as '$zipDest', then choose Retry. Or paste the path to a fresh ZIP." `
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

# The release ZIP wraps everything in an x64\ folder. Find Starship.exe
# anywhere in the tree and treat its folder as the real payload root, so
# this works whether the layout is wrapped or flat.
$exeItem = Get-ChildItem -Path $unpack -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
while (-not $exeItem) {
    Write-Fail "'$GAME_EXE' not found in the extracted files."
    $fb = Invoke-InstallerFallback -Action "find $GAME_EXE in the download" `
        -Subject "the Starship download" `
        -Url $RELEASES_LATEST `
        -DestFile $zipDest `
        -Instructions "The ZIP did not contain $GAME_EXE - it may be the wrong file. Grab the newest 'Starship.vX.Y.Z.zip' from the releases page, save it as '$zipDest', then choose Retry." `
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
foreach ($__it in @("config.yml", "save", "saves", "mods")) {
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
        $fb = Invoke-InstallerFallback -Action "copy the Starship files into place" `
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

# ---- 4. your Star Fox 64 US ROM ----------------------------
Write-Step 4 5 "Your Star Fox 64 US ROM"

# Restore settings / saves preserved from a previous install.
if ($preserved.Count -gt 0) {
    foreach ($__it in $preserved) {
        try { Move-Item -LiteralPath (Join-Path $preserveDir $__it) -Destination (Join-Path $gameRoot $__it) -Force -ErrorAction Stop } catch {}
    }
    Write-OK "Kept your existing settings / saves."
}

Write-Host "  You provide your OWN Star Fox 64 US ROM (.z64)." -ForegroundColor White
Write-Host "  Nothing from Nintendo is downloaded or included - the game" -ForegroundColor Gray
Write-Host "  reads your ROM dump locally and builds its asset archive once." -ForegroundColor Gray
Write-Host ""
Write-Host "  On FIRST LAUNCH a file picker opens - just select your .z64" -ForegroundColor White
Write-Host "  there. Nothing to place now." -ForegroundColor White
Write-Host ""
Write-Host "  Supported: US 1.0 and US 1.1. If your ROM is .n64, convert it" -ForegroundColor Gray
Write-Host "  to .z64 first (hack64.net/tools/swapper.php)." -ForegroundColor Gray
$romPlaced = $false

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
        $lnkPath = Join-Path $desktop "Star Fox 64 VR.lnk"
        $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $exePath -WorkingDir $gameRoot -IconPath $exePath
        Write-OK "Desktop shortcut created: Star Fox 64 VR"
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
Write-Host "  Star Fox 64 VR (Starship) is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  How to play:" -ForegroundColor White
Write-Host "   1. Start your VR runtime first (Quest Link/Air Link, Virtual" -ForegroundColor White
Write-Host "      Desktop, or SteamVR) if you want VR." -ForegroundColor White
Write-Host "   2. Launch with the 'Star Fox 64 VR' desktop shortcut, or run:" -ForegroundColor White
Write-Host "        $exePath" -ForegroundColor Cyan
Write-Host "   3. On first launch, pick your Star Fox 64 US .z64 in the file" -ForegroundColor White
Write-Host "      picker. Headset connected boots into VR; otherwise it's flat." -ForegroundColor White
Write-Host "      Force it with --vr or --novr; no flag = auto-detect." -ForegroundColor White
Write-Host ""
Write-Host "  VR controls: left stick flies / navigates menus, right trigger" -ForegroundColor Gray
Write-Host "  or A fires the laser (hold to charge), left trigger or B is a" -ForegroundColor Gray
Write-Host "  smart bomb, grips bank left/right (double-squeeze = barrel roll)," -ForegroundColor Gray
Write-Host "  right stick up/down boost/brake, right-stick click cycles the" -ForegroundColor Gray
Write-Host "  view mode, left-stick click opens the desktop menu, menu pauses." -ForegroundColor Gray
Write-Host ""
Write-Host "  View modes (right-stick click): Third-person, First-person," -ForegroundColor Gray
Write-Host "  Cockpit, Diorama (tabletop) and Theater (comfy flat screen)." -ForegroundColor Gray
Write-Host "  All VR options are in-game: pause, then pull the right trigger." -ForegroundColor Gray
Write-Host ""

try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Write-Host "  Do a barrel roll, Fox - the Lylat System is counting on you." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
