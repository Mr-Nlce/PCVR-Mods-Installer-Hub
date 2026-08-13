# ============================================================
# Banjo-Kazooie VR Installer (BanjoKazooie-VR by RaYRoD)
# ============================================================
# BanjoKazooie-VR is a native OpenXR VR build of Lighthouse, the
# Harbour Masters PC port of Banjo-Kazooie (N64, 1998). The whole
# game renders per eye with head tracking; the same exe runs flat
# when no headset answers (--vr / --novr force either way).
#
# The user supplies their own Banjo-Kazooie ROM (.z64). On first
# launch the extraction wizard reads it once and builds bk.o2r -
# nothing from Nintendo is downloaded or shipped.
#
# Install layout:
#   <install_root>\Banjo-Kazooie VR\Lighthouse.exe
#   default install_root: C:\Games (fallback D:\Games, E:\Games)
#
# The release ZIP is FLAT (Lighthouse.exe in the zip root).
# Expand-ArchiveToTarget also survives a future wrapper folder.
#
# The Hub tracks updates via the GitHub latest-release tag (the
# catalog's GithubRepo field); this installer records the EXACT
# tag_name in .installed_version so the two compare cleanly.
#
# NOTE ON THE GRAPHICS BACKEND: the exe forces the OpenGL backend
# itself when VR is requested (OpenXR binds to WGL) - there is no
# backend setting for the user to change.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Banjo-Kazooie VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Banjo-Kazooie VR Installer" -ForegroundColor Cyan
    Write-Host " BanjoKazooie-VR by RaYRoD | your own N64 .z64 ROM required" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR         = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO               = "RaYRoD-TV/BanjoKazooie-VR"
$REPO_API           = "https://api.github.com/repos/$REPO/releases"
$RELEASES_PAGE      = "https://github.com/$REPO/releases"
# Last-known-good asset, used only if the GitHub API cannot be reached.
$KNOWN_FALLBACK_ZIP = "https://github.com/RaYRoD-TV/BanjoKazooie-VR/releases/download/v0.1/BanjoKazooie-VR-v0.1-win64.zip"
$KNOWN_FALLBACK_TAG = "v0.1"
$GAME_FOLDER        = "Banjo-Kazooie VR"
$GAME_EXE           = "Lighthouse.exe"
$DEFAULT_ROOTS      = @("C:\Games", "D:\Games", "E:\Games")

# Resolve the newest release zip via the GitHub API. Returns
# @{ Url=...; Tag=... } or $null on any failure (rate limit / offline /
# shape change) - the caller then falls back to the pinned URL.
function Get-LatestBanjoKazooieVR {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rels = Invoke-RestMethod -Uri "$REPO_API`?per_page=5" -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        foreach ($rel in @($rels)) {
            # !!! NICHT JEDES RELEASE IST EIN SPIELBARES PAKET !!!
            # RaYRoD-TV hat bei ALLEN seinen VR-Ports ein Release
            # "hub-patch-2" mit NUR QUELLTEXT hochgeladen. Bei Banjo:
            # BanjoKazooie-VR-2-source.zip, 87 Dateien, 324 KB, KEINE
            # Lighthouse.exe - das echte Paket hat 16 Dateien und 5,5 MB.
            # Test-IsPayloadRelease und Select-PayloadAsset stehen in
            # InstallerSafety.ps1 und pruefen Tag, Dateiname UND Groesse
            # (unter 1 MB ist kein Spiel).
            if (-not (Test-IsPayloadRelease -Release $rel)) { continue }
            $pick = Select-PayloadAsset -Assets $rel.assets
            if ($pick -and $pick.browser_download_url) {
                return @{ Url = [string]$pick.browser_download_url; Tag = [string]$rel.tag_name }
            }
        }

    } catch { }
    return $null
}

Write-Header

Write-Host "  Banjo-Kazooie (N64, 1998) in the headset: the whole game renders" -ForegroundColor Gray
Write-Host "  per eye with head tracking, built on Lighthouse, the Harbour" -ForegroundColor Gray
Write-Host "  Masters PC port. Four view modes - Third Person, First Person," -ForegroundColor Gray
Write-Host "  Diorama and Theater - and motion controllers mapped to the N64" -ForegroundColor Gray
Write-Host "  pad. No headset connected? The same exe runs the flat game." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    Banjo-Kazooie - US (NTSC) 1.0 .z64 ROM that you own." -ForegroundColor Yellow
Write-Host "  Nothing from Nintendo is downloaded or included - only the" -ForegroundColor Gray
Write-Host "  BanjoKazooie-VR app is fetched (from the official GitHub" -ForegroundColor Gray
Write-Host "  releases). The game reads the ROM locally and it never leaves" -ForegroundColor Gray
Write-Host "  your PC." -ForegroundColor Gray
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
Write-Host "  C:\Games needs no admin rights, so there's no Windows UAC prompt." -ForegroundColor Gray
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

# ---- 2. download the latest BanjoKazooie-VR release ----------
$InstallMode = Read-UpdateOrInstall -GameFolder $gameRoot -ModFile $GAME_EXE
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the app files." }

$null = Show-UpdateNoticeIfInstalled -TargetDir $gameRoot -RelModFile $GAME_EXE -Label "Banjo-Kazooie VR"
Write-Step 2 5 "Downloading BanjoKazooie-VR (latest release)"

$tmp = Join-Path $installRoot "_hub_extract_tmp"
try {
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Fail "Could not create a temp folder under $installRoot : $_"
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
$zipDest = Join-Path $tmp "BanjoKazooieVR_latest.zip"

$relTag = $null
$urls = New-Object System.Collections.Generic.List[string]
Write-Info "Resolving the newest release via the GitHub API..."
$latest = Get-LatestBanjoKazooieVR
if ($latest) {
    Write-OK "Latest release: $($latest.Tag)"
    $relTag = [string]$latest.Tag
    [void]$urls.Add([string]$latest.Url)
} else {
    Write-Warn "GitHub API not reachable (rate limit / offline). Using last-known build."
    $relTag = $KNOWN_FALLBACK_TAG
}
# Always also queue the known-good URL as a secondary source.
if (-not $latest -or ([string]$latest.Url -ne [string]$KNOWN_FALLBACK_ZIP)) { [void]$urls.Add($KNOWN_FALLBACK_ZIP) }

Invoke-SafeDownload -Urls $urls -Destination $zipDest `
    -Label "BanjoKazooie-VR ($relTag)" `
    -ManualUrl $RELEASES_PAGE `
    -Instructions "Open the releases page, download the newest 'BanjoKazooie-VR-*-win64.zip', save it as '$zipDest', then choose Retry." `
    -SkipMessage "" | Out-Null

# Hard guarantee: regardless of the helper's outcome, make sure we have a ZIP.
while (-not (Test-Path $zipDest)) {
    Write-Fail "The BanjoKazooie-VR download is not present at: $zipDest"
    $fb = Invoke-InstallerFallback -Action "download BanjoKazooie-VR" `
        -Subject "the latest BanjoKazooie-VR release" `
        -Url $RELEASES_PAGE `
        -DestFile $zipDest `
        -Instructions "Download the newest 'BanjoKazooie-VR-*-win64.zip' from the releases page, save it as '$zipDest', then choose Retry. You can also paste the full path to an already-downloaded ZIP." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
}
Write-OK "BanjoKazooie-VR archive ready: $zipDest"

# ---- 3. extract into the game folder ------------------------
Write-Step 3 5 "Installing BanjoKazooie-VR"

# Preserve the user's game data across a reinstall: the generated
# bk.o2r (built from their ROM), saves, mods and settings all live
# in the game folder, and the merge below is per-file.
if ($InstallMode -eq "update" -and (Test-Path $gameRoot)) {
    Write-Info "Keeping your saves, settings and generated game archive."
}

# Payload-verified extract: current releases are FLAT (Lighthouse.exe
# in the zip root), but Get-ExtractedPayloadRoot also survives a future
# wrapper folder.
$exRes = Expand-ArchiveToTarget -ArchivePath $zipDest -TargetDir $gameRoot `
            -RelModFile $GAME_EXE -Markers @("Lighthouse.exe","lighthouse.o2r") `
            -Label "BanjoKazooie-VR" `
            -SkipMessage "Skipped - the archive was not unpacked, so the game is not installed."
if ([string]$exRes -eq "quit") { try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}; Pause-User "Press Enter to exit."; exit 1 }

if (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($gameRoot, $GAME_EXE)))) {
    Write-Fail "$GAME_EXE is missing after extraction - the package layout may have changed."
    Write-Info "Get it manually from:"
    Write-Info "  $RELEASES_PAGE"
    try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."; exit 1
}
Write-OK "BanjoKazooie-VR installed to: $gameRoot"
try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# ---- 4. your Banjo-Kazooie ROM ------------------------------
Write-Step 4 5 "Your Banjo-Kazooie ROM"

Write-Host "  You provide your own dump. What is needed, exactly:" -ForegroundColor White
Write-Host "    Nintendo 64 Banjo-Kazooie, US (NTSC) 1.0, as a .z64 file" -ForegroundColor Gray
Write-Host "  On the first launch the extraction wizard reads it once and" -ForegroundColor Gray
Write-Host "  builds bk.o2r; after that the ROM is no longer needed. It never" -ForegroundColor Gray
Write-Host "  leaves your PC." -ForegroundColor Gray
Write-Host ""
Write-Host "  Drag & drop your ROM onto this window and press Enter to copy it" -ForegroundColor White
Write-Host "  into the game folder now - a .zip / .7z / .rar holding the .z64" -ForegroundColor White
Write-Host "  works too. Or just press Enter to skip: the wizard asks you to" -ForegroundColor White
Write-Host "  pick the ROM on its first start instead." -ForegroundColor White
$romIn = (Read-Host "  ROM path (or Enter to skip)").Trim().Trim('"')
$romPlaced = $false
if ($romIn -and (Test-Path -LiteralPath $romIn)) {
    $romSource = $romIn
    $romTmp    = $null
    $ext = [System.IO.Path]::GetExtension($romIn).ToLower()
    # ROM downloads are often an archive holding the .z64. Unpack it and
    # take the largest .z64 inside (the real ROM).
    if ($ext -in @(".zip", ".7z", ".rar")) {
        Write-Info "Archive detected - unpacking and locating the .z64 inside..."
        $romTmp = Join-Path $env:TEMP ("bk_rom_" + [Guid]::NewGuid().ToString("N"))
        try {
            New-Item -ItemType Directory -Path $romTmp -Force -ErrorAction Stop | Out-Null
            Expand-ArchiveOrFallback -ArchivePath $romIn -DestinationFolder $romTmp -Label "Banjo-Kazooie ROM" `
                -SkipMessage "Skipped - the archive was not unpacked." | Out-Null
            $inner = Get-ChildItem -LiteralPath $romTmp -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension.ToLower() -eq ".z64" } |
                Sort-Object Length -Descending | Select-Object -First 1
            if ($inner) {
                $romSource = $inner.FullName
                Write-OK "Found ROM in archive: $($inner.Name)"
            } else {
                Write-Warn "No .z64 ROM found inside the archive."
                Write-Host "    Put your ROM into this folder yourself:" -ForegroundColor Gray
                Write-Host "    $gameRoot" -ForegroundColor Cyan
                $romSource = $null
            }
        } catch {
            Write-Warn "Could not unpack the archive: $($_.Exception.Message)"
            Write-Host "    Put your ROM into this folder yourself:" -ForegroundColor Gray
            Write-Host "    $gameRoot" -ForegroundColor Cyan
            $romSource = $null
        }
    }
    if ($romSource) {
        try {
            $romName = [System.IO.Path]::GetFileName($romSource)
            Copy-Item -LiteralPath $romSource -Destination ([System.IO.Path]::Combine($gameRoot, $romName)) -Force -ErrorAction Stop
            Write-OK "ROM copied next to $GAME_EXE - the wizard picks it up on first launch."
            $romPlaced = $true
        } catch {
            Write-Warn "Could not copy the ROM: $($_.Exception.Message)"
            Write-Host "    Put it into this folder yourself, or pick it when the wizard asks:" -ForegroundColor Gray
            Write-Host "    $gameRoot" -ForegroundColor Cyan
        }
    }
    if ($romTmp) { try { Remove-Item $romTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {} }
} elseif ($romIn) {
    Write-Warn "That file was not found - the wizard will ask for the ROM on first start."
} else {
    Write-Info "Skipped - the wizard will ask for the ROM on its first start."
}

# ---- 5. shortcut + Hub markers ------------------------------
Write-Step 5 5 "Finishing up"

$exePath = Join-Path $gameRoot $GAME_EXE
$lnk = New-DesktopShortcut -TargetPath $exePath -ShortcutName "Banjo-Kazooie VR" `
         -WorkingDir $gameRoot -IconPath $exePath `
         -Description "Banjo-Kazooie in the headset (BanjoKazooie-VR by RaYRoD)"
if ($lnk) { Write-OK "Desktop shortcut created: Banjo-Kazooie VR" }
else      { Write-Warn "Could not create the desktop shortcut - use 'Start in VR' in the Hub." }

# Hub markers: install path for "Start in VR" + the EXACT release tag
# for the update badge (the Hub compares this string against the
# GitHub latest tag, so it must match tag_name verbatim).
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}
try { if ($relTag) { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $relTag -Encoding UTF8 -Force } } catch {}
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".launch_exe") -Value $exePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Banjo-Kazooie VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |        START YOUR VR RUNTIME BEFORE THE GAME         |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Quest Link, Virtual Desktop or SteamVR " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  With a runtime running the game boots into VR; without one it" -ForegroundColor Gray
Write-Host "  runs as the normal flat game." -ForegroundColor Gray
Write-Host ""
Write-Host "  HOW TO PLAY:" -ForegroundColor Cyan
Write-Host "    Launch with" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or use the new" -ForegroundColor Gray
Write-Host "    'Banjo-Kazooie VR' desktop shortcut." -ForegroundColor Gray
if (-not $romPlaced) {
    Write-Host "    On the first start the extraction wizard asks for your" -ForegroundColor Gray
    Write-Host "    Banjo-Kazooie .z64 ROM and builds the game archive." -ForegroundColor Gray
} else {
    Write-Host "    On the first start the extraction wizard builds the game" -ForegroundColor Gray
    Write-Host "    archive from your ROM." -ForegroundColor Gray
}
Write-Host ""
Write-Host "  Click the RIGHT STICK to cycle the four view modes: Third" -ForegroundColor Gray
Write-Host "  Person, First Person, Diorama and Theater." -ForegroundColor Gray
Write-Host ""
Write-Host "  See the README for the full control mapping and VR options." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Grab your bird and go. Gruntilda's tower won't climb itself." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
