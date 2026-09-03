# ============================================================
# Legend of Zelda: Ocarina of Time VR Installer
# (Shipwright-VR by ShinyWindow, built on Ship of Harkinian)
# ============================================================
# Shipwright-VR adds OpenVR stereo rendering to Ship of Harkinian,
# the PC port of The Legend of Zelda: Ocarina of Time (N64, 1998).
# The 3D world renders in the headset with motion-controller input;
# menus/HUD stay on the flat window for now (alpha limitation).
#
# The user supplies their own legally acquired Ocarina of Time ROM.
# On first launch soh.exe extracts the copyrighted assets from that
# ROM into an .otr archive - nothing from Nintendo is downloaded or
# shipped, and the Hub never bundles the ROM either.
#
# Install layout:
#   <install_root>\Ocarina of Time VR\soh.exe
#   default install_root: C:\Games (fallback D:\Games, E:\Games)
#
# OpenVR mod -> the runtime is SteamVR. Rendering must stay on
# DirectX11 (the SoH default on Windows); OpenGL does not hook.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Ocarina of Time VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Legend of Zelda: Ocarina of Time VR Installer" -ForegroundColor Cyan
    Write-Host " Shipwright-VR by ShinyWindow | your own N64 .z64 ROM required" -ForegroundColor Gray
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
$REPO              = "ShinyWindow/Shipwright-VR"
$REPO_API          = "https://api.github.com/repos/$REPO/releases"
$RELEASES_PAGE     = "https://github.com/$REPO/releases"
$INFO_URL          = "https://github.com/$REPO"
# Last-known-good asset, used only if the GitHub API cannot be reached.
$KNOWN_FALLBACK_ZIP = "https://github.com/ShinyWindow/Shipwright-VR/releases/download/v1.1/Ship-9.0.0-win64-ship.zip"
$KNOWN_FALLBACK_TAG = "v1.1"
$GAME_FOLDER       = "Ocarina of Time VR"
$GAME_EXE          = "soh.exe"
$DEFAULT_ROOTS     = @("C:\Games", "D:\Games", "E:\Games")
# Optional Djipi 3DS Experience pack (GameBanana mod 477979). The direct
# download link is opened in the browser - GameBanana cannot be fetched
# unattended, and the file is ~500 MB from a rate-limited source.
$DJIPI_URL         = "https://gamebanana.com/dl/1766765"
$DJIPI_PAGE        = "https://gamebanana.com/mods/477979"
$DJIPI_FILE        = "djipi_s_3ds_experience_-_final_pack.zip"

# Resolve the newest release zip via the GitHub API. Returns
# @{ Url=...; Tag=... } or $null on any failure (rate limit / offline /
# shape change) - the caller then falls back to the pinned URL.
function Get-LatestShipwrightVR {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rels = Invoke-RestMethod -Uri "$REPO_API`?per_page=5" -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        foreach ($rel in @($rels)) {
            # Asset names may change between releases (currently
            # Ship-<soh-ver>-win64-ship.zip) - match any .zip, prefer a
            # win64/ship-looking name, else take the first zip.
            $zips = @($rel.assets | Where-Object { $_.name -match '(?i)\.zip$' })
            if ($zips.Count -gt 0) {
                $pick = $zips | Where-Object { $_.name -match '(?i)(win64|ship)' } | Select-Object -First 1
                if (-not $pick) { $pick = $zips[0] }
                if ($pick -and $pick.browser_download_url) {
                    return @{ Url = [string]$pick.browser_download_url; Tag = [string]$rel.tag_name }
                }
            }
        }
    } catch { }
    return $null
}

Write-Header

Write-Host "  The Legend of Zelda: Ocarina of Time (N64, 1998) - one of the" -ForegroundColor Gray
Write-Host "  most acclaimed games ever made - playable in the headset via" -ForegroundColor Gray
Write-Host "  Shipwright-VR, an OpenVR mod for the Ship of Harkinian PC port." -ForegroundColor Gray
Write-Host "  The 3D world renders in stereo with motion-controller input;" -ForegroundColor Gray
Write-Host "  menus and HUD stay on the flat game window for now (alpha)." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    a Nintendo 64 Ocarina of Time dump you own, as a .z64 file" -ForegroundColor Yellow
Write-Host "    (32 MB). Master Quest works too." -ForegroundColor Yellow
Write-Host "  Nothing from Nintendo is downloaded or included - only the" -ForegroundColor Gray
Write-Host "  Shipwright-VR app is fetched (from the official GitHub releases)." -ForegroundColor Gray
Write-Host "  The game reads the ROM locally and it never leaves your PC." -ForegroundColor Gray
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

Write-Host "  Default C:\Games - no admin rights, no UAC prompt. The" -ForegroundColor White
Write-Host "  '$GAME_FOLDER' folder is created inside whatever you choose." -ForegroundColor Gray
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

# ---- 2. download the latest Shipwright-VR release ------------
$InstallMode = Read-UpdateOrInstall -GameFolder $gameRoot -ModFile $GAME_EXE
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the app files." }

Write-Step 2 5 "Downloading Shipwright-VR (latest release)"

$tmp = Join-Path $installRoot "_hub_extract_tmp"
try {
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Fail "Could not create a temp folder under $installRoot : $_"
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
$zipDest = Join-Path $tmp "ShipwrightVR_latest.zip"

$relTag = $null
$urls = New-Object System.Collections.Generic.List[string]
Write-Info "Resolving the newest release via the GitHub API..."
$latest = Get-LatestShipwrightVR
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
    -Label "Shipwright-VR ($relTag)" `
    -ManualUrl $RELEASES_PAGE `
    -Instructions "Open the releases page, download the newest 'Ship-*-win64-ship.zip', save it as '$zipDest', then choose Retry." `
    -SkipMessage "" | Out-Null

# Hard guarantee: regardless of the helper's outcome, make sure we have a ZIP.
while (-not (Test-Path $zipDest)) {
    Write-Fail "The Shipwright-VR download is not present at: $zipDest"
    $fb = Invoke-InstallerFallback -Action "download Shipwright-VR" `
        -Subject "the latest Shipwright-VR release" `
        -Url $RELEASES_PAGE `
        -DestFile $zipDest `
        -Instructions "Download the newest 'Ship-*-win64-ship.zip' from the releases page, save it as '$zipDest', then choose Retry. You can also paste the full path to an already-downloaded ZIP." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
}
Write-OK "Shipwright-VR archive ready: $zipDest"

# ---- 3. extract into the game folder ------------------------
Write-Step 3 5 "Installing Shipwright-VR"

# Preserve the user's game data across a reinstall: the generated .otr
# archives (built from their ROM on first run), saves, mods and settings
# all live in the game folder.
if ($InstallMode -eq "update" -and (Test-Path $gameRoot)) {
    Write-Info "Keeping your saves, settings and generated game archives."
}

# Payload-verified extract: current releases are FLAT (soh.exe in the
# zip root), but Get-ExtractedPayloadRoot also survives a future
# wrapper folder. Merge is per-file, so oot.otr / saves / mods and
# shipofharkinian.json in an existing install stay untouched.
$exRes = Expand-ArchiveToTarget -ArchivePath $zipDest -TargetDir $gameRoot `
            -RelModFile $GAME_EXE -Markers @("soh.exe","soh.otr") `
            -Label "Shipwright-VR" `
            -SkipMessage "Skipped - the archive was not unpacked, so the game is not installed."
if ([string]$exRes -eq "quit") { try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}; Pause-User "Press Enter to exit."; exit 1 }

if (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($gameRoot, $GAME_EXE)))) {
    Write-Fail "$GAME_EXE is missing after extraction - the package layout may have changed."
    Write-Info "Get it manually from:"
    Write-Info "  $RELEASES_PAGE"
    try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."; exit 1
}
Write-OK "Shipwright-VR installed to: $gameRoot"
try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# ---- 4. your Ocarina of Time ROM ----------------------------
Write-Step 4 5 "Your Ocarina of Time ROM"

Write-Host "  Needed: a Nintendo 64 .z64 dump of Ocarina of Time or Master" -ForegroundColor White
Write-Host "  Quest, exactly 33,554,432 bytes (32 MB). Most regions and" -ForegroundColor White
Write-Host "  revisions work; this checker settles your exact file:" -ForegroundColor White
Write-Host "     https://ship.equipment/" -ForegroundColor Cyan
Write-Host ""
Write-Host " >>> Drag your ROM onto this window, then press Enter. " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     Enter on its own skips this - soh.exe then asks for the ROM" -ForegroundColor Gray
Write-Host "     on its first start." -ForegroundColor Gray
$romIn = (Read-Host "  ROM path (or Enter to skip)").Trim().Trim('"')
if ($romIn -and (Test-Path -LiteralPath $romIn)) {
    try {
        Copy-Item -LiteralPath $romIn -Destination $gameRoot -Force -ErrorAction Stop
        Write-OK "ROM copied next to soh.exe - it will be picked up on first launch."
    } catch {
        Write-Warn "Could not copy the ROM: $_"
        Write-Host "    Put it into this folder yourself, or pick it when soh.exe asks:" -ForegroundColor Gray
        Write-Host "    $gameRoot" -ForegroundColor Cyan
    }
} elseif ($romIn) {
    Write-Warn "That file was not found - soh.exe will ask for the ROM on first start."
} else {
    Write-Info "Skipped - soh.exe will ask for the ROM on its first start."
}

# ---- 5. shortcut + Hub markers ------------------------------
Write-Step 5 5 "Finishing up"

$exePath = Join-Path $gameRoot $GAME_EXE
$lnk = New-DesktopShortcut -TargetPath $exePath -ShortcutName "Ocarina of Time VR" `
         -WorkingDir $gameRoot -IconPath $exePath `
         -Description "The Legend of Zelda: Ocarina of Time in the headset (Shipwright-VR)"
if ($lnk) { Write-OK "Desktop shortcut created: Ocarina of Time VR" }
else      { Write-Warn "Could not create the desktop shortcut - use 'Start in VR' in the Hub." }

try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}
if ($relTag -and $relTag -ne $KNOWN_FALLBACK_TAG) {
    try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $relTag -Encoding UTF8 -Force } catch {}
    # Also next to the GAME, so a new Hub build does not lose the marker.
    try { Save-InstalledStamp -GameDir $installRoot -Version $relTag -HubDir $SCRIPT_DIR } catch {}
} else {
    # !!! NEVER RECORD THE FALLBACK TAG (2026-08-20). $KNOWN_FALLBACK_TAG
    # is what we use when GitHub was unreachable - it is a guess, not the
    # version that was installed. Writing it would age exactly like the
    # hard-coded number that plagued Forza: the tile would show an Update
    # badge no reinstall can clear. No marker is self-healing - the next
    # scan seeds the real current tag.
    try { Remove-Item -LiteralPath (Join-Path $SCRIPT_DIR ".installed_version") -Force -ErrorAction SilentlyContinue } catch {}
}
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".launch_exe") -Value $exePath -Encoding UTF8 -Force } catch {}

# ---- HD texture pack (optional) -----------------------------
# OoT Reloaded 4K (evilgames.eu): a ~4 GB .7z holding a single .o2r that
# Ship of Harkinian loads whatever sits in its mods\ folder by itself.
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  OPTIONAL: HD texture pack (OoT Reloaded 4K)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  4K textures for Ocarina of Time. Download and unpack take a" -ForegroundColor White
Write-Host "  while - about 4 GB, with a progress percentage." -ForegroundColor White
Write-Host ""
$doHd = ""
while ($doHd -notin @("y","Y","n","N")) { $doHd = (Read-Host "  Install the HD texture pack now? (Y/N)").Trim() }
if ($doHd -in @("y","Y")) {
    $hdUrl  = "https://evilgames.eu/files/texture-packs/oot-reloaded-v11.0.0-soh-o2r-4k.7z"
    $hdName = "oot-reloaded-v11.0.0-soh-o2r-4k.7z"
    $hdTmp  = Join-Path $installRoot "_hub_hd_tmp"
    try { if (Test-Path $hdTmp) { Remove-Item $hdTmp -Recurse -Force -EA SilentlyContinue }; New-Item -ItemType Directory -Path $hdTmp -Force | Out-Null } catch {}
    $hd7z   = Join-Path $hdTmp $hdName

    # Before pulling ~4 GB, see if the user already has the exact file in
    # their Downloads folder and offer to reuse it.
    $usedLocal = $false
    $dlHit = Join-Path (Join-Path $env:USERPROFILE "Downloads") $hdName
    if (Test-Path -LiteralPath $dlHit) {
        Write-Host ""
        Write-OK "Found '$hdName' already in your Downloads folder."
        $useDl = ""
        while ($useDl -notin @("y","Y","n","N")) { $useDl = (Read-Host "  Use that file instead of downloading ~4 GB again? (Y/N)").Trim() }
        if ($useDl -in @("y","Y")) {
            try { Copy-Item -LiteralPath $dlHit -Destination $hd7z -Force -ErrorAction Stop; $usedLocal = $true; Write-OK "Using the file from Downloads." }
            catch { Write-Warn "Could not use that file: $($_.Exception.Message)" }
        }
    }

    if (-not $usedLocal) {
        Write-Host ""
        Invoke-SafeDownload -Urls @($hdUrl) -Destination $hd7z `
            -Label "OoT Reloaded 4K (~4 GB)" `
            -ManualUrl $hdUrl `
            -Instructions "Download '$hdName' from the link that opened, save it as '$hd7z', then choose Retry." `
            -SkipMessage "Skipped the HD texture pack." | Out-Null
    }

    if (Test-Path -LiteralPath $hd7z) {
        $sevenZip = Get-SevenZip
        $modsDir  = Join-Path $gameRoot "mods"
        if ($sevenZip) {
            $hdOut = Join-Path $hdTmp "extract"
            $hdDone = $false
            while (-not $hdDone) {
                Write-Host ""
                $ok7z = Expand-7zWithProgress -SevenZip $sevenZip -Archive $hd7z -Dest $hdOut -Label "HD textures"
                $o2r = $null
                if ($ok7z) { $o2r = Get-ChildItem -LiteralPath $hdOut -Recurse -Filter "*.o2r" -File -EA SilentlyContinue | Select-Object -First 1 }
                if ($o2r) {
                    try {
                        if (-not (Test-Path -LiteralPath $modsDir)) { New-Item -ItemType Directory -Path $modsDir -Force | Out-Null }
                        Copy-Item -LiteralPath $o2r.FullName -Destination (Join-Path $modsDir $o2r.Name) -Force -ErrorAction Stop
                        Write-OK "HD textures installed: mods\$($o2r.Name)"
                        Write-Host ""
                        Write-Host "  Current builds pick anything in mods\ up by themselves -" -ForegroundColor Gray
                        Write-Host "  there is nothing to switch on. Press Tab during play to" -ForegroundColor Gray
                        Write-Host "  toggle the textures off and on." -ForegroundColor Gray
                    } catch { Write-Warn "Could not copy the .o2r into mods\: $($_.Exception.Message)" }
                    $hdDone = $true
                } else {
                    # Extraction failed (or produced no .o2r). Don't just skip
                    # and waste the ~4 GB download - let the user retry or
                    # finish it by hand.
                    Write-Host ""
                    Write-Warn "The HD texture pack could not be unpacked automatically."
                    Write-Host "  You don't have to lose the download. Choose:" -ForegroundColor White
                    Write-Host "   [R] Retry the extraction" -ForegroundColor White
                    Write-Host "   [O] Open the .7z and the game's mods folder, so you can" -ForegroundColor White
                    Write-Host "       unpack it yourself and drop the .o2r into mods\" -ForegroundColor White
                    Write-Host "   [S] Skip the HD textures (you can add them later)" -ForegroundColor White
                    $ch = (Read-Host "  R / O / S").Trim().ToUpper()
                    if ($ch -eq "R") { continue }
                    elseif ($ch -eq "O") {
                        try { if (-not (Test-Path -LiteralPath $modsDir)) { New-Item -ItemType Directory -Path $modsDir -Force | Out-Null } } catch {}
                        # Move the .7z out of the temp dir (which gets wiped
                        # below) into the game folder so it survives.
                        $persist = Join-Path $gameRoot $hdName
                        try { Move-Item -LiteralPath $hd7z -Destination $persist -Force -ErrorAction Stop } catch { $persist = $hd7z }
                        try { Start-Process explorer.exe "/select,`"$persist`"" } catch { try { Start-Process explorer.exe (Split-Path -Parent $persist) } catch {} }
                        try { Start-Process explorer.exe $modsDir } catch {}
                        Write-Host ""
                        Write-Host "  Archive: $persist" -ForegroundColor Cyan
                        Write-Host "  Unpack it (right-click > 7-Zip > Extract, or double-click)," -ForegroundColor Gray
                        Write-Host "  then copy the .o2r file into:" -ForegroundColor Gray
                        Write-Host "    $modsDir" -ForegroundColor Cyan
                        Write-Host ""
                        Read-Host "  Press Enter once you've placed the .o2r (or to continue without it)" | Out-Null
                        $placed = Get-ChildItem -LiteralPath $modsDir -Filter "*.o2r" -File -EA SilentlyContinue | Select-Object -First 1
                        if ($placed) {
                            Write-OK "Found HD textures: mods\$($placed.Name)"
                            Write-Host "  Loads by itself on the next start (Tab toggles the" -ForegroundColor Gray
                            Write-Host "  textures off and on during play)." -ForegroundColor Gray
                        } else {
                            Write-Info "No .o2r in mods yet - the archive is at $persist for later."
                        }
                        $hdDone = $true
                    }
                    else { Write-Info "Skipped the HD texture pack."; $hdDone = $true }
                }
            }
        } else {
            Write-Warn "7-Zip unavailable - skipped the HD texture pack."
        }
    } else {
        Write-Info "HD texture pack not downloaded - skipped."
    }
    try { Remove-Item $hdTmp -Recurse -Force -EA SilentlyContinue } catch {}
}

# ---- Djipi's 3DS Experience (optional, 3D backgrounds) -------
# GameBanana mod 477979. Ocarina of Time draws Castle Town and many
# interiors with flat pre-rendered backdrops; in VR those sit in front
# of the player and block the view (the "feel your way to the exit"
# problem). This pack ships real 3D geometry for those scenes, so the
# 2D backdrops can be switched off and the rooms render properly.
# The zip holds two folders: "0000 - Djipi's 3DS Experience" and
# "0001 - Skilar's Art Plus Link"; only the first one is installed.
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  OPTIONAL: Djipi's 3DS Experience (3D backgrounds)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Castle Town and many interiors are flat backdrops that block" -ForegroundColor White
Write-Host "  your view in VR. This pack replaces them with real 3D geometry." -ForegroundColor White
Write-Host "  Browser download, about 500 MB, usually ~20 minutes." -ForegroundColor White
Write-Host ""
$doDjipi = ""
while ($doDjipi -notin @("y","Y","n","N")) { $doDjipi = (Read-Host "  Install Djipi's 3DS Experience now? (Y/N)").Trim() }

$djipiInstalled = $false
$djipiMode      = ""
if ($doDjipi -in @("y","Y")) {

    # -- which look --------------------------------------------
    Write-Host ""
    # [2] IS THE RECOMMENDATION, INDEPENDENTLY OF THE HD PACK. The full
    # pack can cause crashes in cutscenes - demonstrated on a real
    # machine with Saria's mod from the pack: that one part turned off,
    # crash gone. So it is NOT the VR mod. The plain 3D backgrounds are
    # the part VR actually needs; the rest is looks.
    Write-Host "   [2] Only the 3D backgrounds - RECOMMENDED." -ForegroundColor Green
    Write-Host "       This is the part VR actually needs, and it pairs with" -ForegroundColor Gray
    Write-Host "       the HD textures." -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [1] The whole 3DS look - can cause problems." -ForegroundColor Gray
    Write-Host "       Character and world replacements from the full pack" -ForegroundColor Gray
    Write-Host "       have been seen to CRASH CUTSCENES (traced to Saria's" -ForegroundColor Gray
    Write-Host "       model). Purely cosmetic, and not for use with the HD" -ForegroundColor Gray
    Write-Host "       textures." -ForegroundColor Gray
    if ($doHd -in @("y","Y")) {
        Write-Host "  You installed the HD pack - take [2]." -ForegroundColor Cyan
    }
    Write-Host ""
    $djipiPick = ""
    while ($djipiPick -notin @("1","2")) { $djipiPick = (Read-Host "  Your choice (Enter or 2 for the backgrounds, 1 for the full look)").Trim(); if ($djipiPick -eq "") { $djipiPick = "2" } }
    $djipiMode = if ($djipiPick -eq "1") { "full" } else { "bg" }
    if ($djipiMode -eq "full") {
        Write-Host ""
        Write-Warn "Full pack chosen - if a cutscene crashes, this is the first"
        Write-Host "   thing to remove. The backgrounds alone (choice 2) are the" -ForegroundColor White
        Write-Host "   part VR needs." -ForegroundColor White
    }

    # -- get the archive (browser download, then disk scan) -----
    $djPat = @("djipi_s_3ds_experience*.zip", "*djipi*3ds*experience*.zip", "*djipi*.zip")
    $djZip = Find-PredownloadedFile -Patterns $djPat -Label "the Djipi 3DS Experience pack"
    if (-not $djZip) {
        Write-Host ""
        Write-Host "  Enter starts '$DJIPI_FILE' in your browser." -ForegroundColor White
        Write-Host "  Leave it running - roughly 20 minutes - then come back here." -ForegroundColor White
        Write-Host "  If it does not start: $DJIPI_PAGE" -ForegroundColor Gray
        Pause-User "Press Enter to start the download in your browser..."
        try { Start-Process $DJIPI_URL } catch { Write-Warn "Open this yourself: $DJIPI_URL" }
        Pause-User "Press Enter once the download has finished (about 20 minutes)..."
        $djZip = Find-PredownloadedFile -Patterns $djPat -Label "the Djipi 3DS Experience pack" -PageAlreadyOpen
    }
    while (-not $djZip) {
        Write-Host ""
        Write-Host "  Drag the downloaded ZIP into this window, or paste its full" -ForegroundColor Yellow
        Write-Host "  path, then press Enter (leave empty to skip this pack):" -ForegroundColor White
        $djIn = (Read-Host "  ZIP path").Trim().Trim('"').Trim("'")
        if (-not $djIn) { Write-Info "Skipped Djipi's 3DS Experience."; break }
        if (Test-Path -LiteralPath $djIn) {
            if ($djIn -match '(?i)\.zip$') { $djZip = $djIn; Write-OK "Archive located: $djZip" }
            else { Write-Warn "That is not a .zip file: $djIn" }
        } else { Write-Warn "File not found: $djIn" }
    }

    # -- unpack and copy the chosen files into mods\ ------------
    if ($djZip) {
        $djTmp = Join-Path $installRoot "_hub_djipi_tmp"
        try {
            if (Test-Path $djTmp) { Remove-Item $djTmp -Recurse -Force -EA SilentlyContinue }
            New-Item -ItemType Directory -Path $djTmp -Force | Out-Null
        } catch {}
        $djOut = Join-Path $djTmp "extract"

        Write-Host ""
        Write-Info "Unpacking the pack - about 500 MB, this takes a moment..."
        $okDj = $false
        $sevenZipDj = Get-SevenZip
        if ($sevenZipDj) {
            $okDj = Expand-7zWithProgress -SevenZip $sevenZipDj -Archive $djZip -Dest $djOut -Label "Djipi 3DS Experience"
        }
        if (-not $okDj) {
            try { Expand-Archive -LiteralPath $djZip -DestinationPath $djOut -Force -ErrorAction Stop; $okDj = $true }
            catch { Write-Warn "Could not unpack the archive: $($_.Exception.Message)" }
        }

        $djAll = @()
        if ($okDj) { $djAll = @(Get-ChildItem -LiteralPath $djOut -Recurse -Filter "*.o2r" -File -EA SilentlyContinue) }
        if ($djAll.Count -eq 0) {
            Write-Warn "No .o2r files were found in the archive - nothing installed."
            Write-Host "  Unpack '$DJIPI_FILE' yourself and copy the .o2r files from" -ForegroundColor Gray
            Write-Host "  the 'Djipi's 3DS Experience' folder into:" -ForegroundColor Gray
            Write-Host "    $(Join-Path $gameRoot 'mods')" -ForegroundColor Cyan
        } else {
            # Skilar's Art Plus Link (folder 0001) is left out: it changes
            # Link himself, and the pack's own troubleshooting names custom
            # Link cosmetics as the first thing to remove when SoH crashes.
            $djFiles  = @($djAll | Where-Object { $_.FullName -notmatch '(?i)(Skilar|Art\s*Plus)' })
            $djSkilar = $djAll.Count - $djFiles.Count
            $djPick   = @()

            if ($djipiMode -eq "bg") {
                $djPick = @($djFiles | Where-Object { $_.Name -match '(?i)3DE\s*-\s*2[67]\s+Background' })
                if ($djPick.Count -lt 2) {
                    Write-Host ""
                    Write-Warn "The two background files were not found by name in this pack."
                    Write-Host "  Expected these two:" -ForegroundColor Gray
                    Write-Host "    Djipi's 3DE - 26 Background 3DS.o2r" -ForegroundColor Gray
                    Write-Host "    Djipi's 3DE - 27 Background Textures.o2r" -ForegroundColor Gray
                    Write-Host "  The pack may have been renamed since. Choose:" -ForegroundColor White
                    Write-Host "   [A] Install the whole pack instead (3DS look)" -ForegroundColor White
                    Write-Host "   [S] Skip this pack" -ForegroundColor White
                    $djAlt = (Read-Host "  A / S").Trim().ToUpper()
                    if ($djAlt -eq "A") { $djPick = $djFiles; $djipiMode = "full" } else { $djPick = @() }
                }
            } else {
                $djPick = $djFiles
            }

            if ($djPick.Count -gt 0) {
                $djModsDir = Join-Path $gameRoot "mods"
                try { if (-not (Test-Path -LiteralPath $djModsDir)) { New-Item -ItemType Directory -Path $djModsDir -Force | Out-Null } } catch {}
                $djCopied = 0
                foreach ($f in $djPick) {
                    try {
                        Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $djModsDir $f.Name) -Force -ErrorAction Stop
                        $djCopied++
                    } catch { Write-Warn "Could not copy $($f.Name): $($_.Exception.Message)" }
                }
                if ($djCopied -gt 0) {
                    $djipiInstalled = $true
                    Write-OK "$djCopied file(s) copied into mods\"
                    if ($djipiMode -eq "bg") {
                        foreach ($f in $djPick) { Write-Host "    $($f.Name)" -ForegroundColor Gray }
                    }
                    if ($djSkilar -gt 0) {
                        Write-Info "Left out: Skilar's Art Plus Link ($djSkilar file(s)) - it changes"
                        Write-Host "       Link's own look, and custom Link cosmetics are the first" -ForegroundColor Gray
                        Write-Host "       suspect if the game crashes. Copy them in yourself if you" -ForegroundColor Gray
                        Write-Host "       want them." -ForegroundColor Gray
                    }
                    if ($djipiMode -eq "full" -and $doHd -in @("y","Y")) {
                        Write-Host ""
                        Write-Warn "You now have BOTH the 3DS look and the HD texture pack in mods\."
                        Write-Host "  They are two different art styles for the same surfaces. For" -ForegroundColor Gray
                        Write-Host "  the 3DS look, delete this file from the mods folder:" -ForegroundColor Gray
                        Write-Host "    OoT_Reloaded_v11.0.0_4K.o2r" -ForegroundColor Cyan
                    }
                } else {
                    Write-Warn "Nothing could be copied into mods\ - the pack is not installed."
                }
            } else {
                Write-Info "Skipped Djipi's 3DS Experience."
            }
        }
        try { Remove-Item $djTmp -Recurse -Force -EA SilentlyContinue } catch {}
    }
}

# -------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  REQUIRED SETTINGS - without these the headset stays black or" -ForegroundColor Cyan
Write-Host "  the image is broken:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Graphics backend         " -NoNewline -ForegroundColor White; Write-Host " DirectX11 (default) " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Window aspect ratio      " -NoNewline -ForegroundColor White; Write-Host " 4:3 " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   MSAA                     " -NoNewline -ForegroundColor White; Write-Host " Off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Internal Resolution      " -NoNewline -ForegroundColor White; Write-Host " 100% " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Do NOT toggle 'Enable advanced settings' while playing, and" -ForegroundColor Gray
Write-Host "  do not switch to OpenGL." -ForegroundColor Gray
Write-Host ""
Write-Host "  IN-GAME MENU: click the game window on the desktop, press Esc." -ForegroundColor Cyan
Write-Host ""
Write-Host "  ENHANCEMENTS (Esc > VR mod settings > Enhancements, on the right):" -ForegroundColor Cyan
# NOTHING TO SWITCH ON FOR mods\ ANY MORE. Older guides (ours included)
# said to tick "Use Alternate Assets" - current Ship of Harkinian builds no
# longer offer that entry and load the mods folder on their own.
Write-Host "   - Tick 'Disable Black Bar Letterboxes' (bars in cutscenes)." -ForegroundColor Gray
Write-Host ""
# THE FOUR SETTINGS VR ACTUALLY NEEDS - gathered here so they do not have
# to be hunted across three menus. The 2D backdrops used to appear only
# in the Djipi branch further down; this is the place where all four
# stand together.
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "  |  THE SETTINGS THAT MATTER FOR VR                         |" -ForegroundColor Yellow
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "   Enhancements > Graphics > Mods" -ForegroundColor White
Write-Host "     " -NoNewline; Write-Host " Disable 2D Pre-Rendered Scenes " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host " ON" -ForegroundColor White
Write-Host "     " -NoNewline; Write-Host " Disable Fixed Camera " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host " ON" -ForegroundColor White
Write-Host "   VR Settings > Gameplay" -ForegroundColor White
Write-Host "     " -NoNewline; Write-Host " Hide Link's Body " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host " ON" -ForegroundColor White
Write-Host "   VR Settings > Physical Combat" -ForegroundColor White
Write-Host "     " -NoNewline; Write-Host " Physical Combat " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host " ON" -ForegroundColor White
Write-Host "   The menu layout differs between builds - go by the setting" -ForegroundColor DarkGray
Write-Host "   names, not the path." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  START:" -NoNewline -ForegroundColor Cyan; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the new desktop shortcut." -ForegroundColor Cyan
Write-Host "  The first start builds the game archive from your ROM." -ForegroundColor Gray
Write-Host ""
if ($djipiInstalled) {
    Write-Host "  3D BACKGROUNDS - one more toggle:" -ForegroundColor Cyan
    Write-Host "   Enhancements > Graphics   " -NoNewline -ForegroundColor White; Write-Host " TICK Disable 2D Pre-Rendered Scenes " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "   (in some builds: 'Disable 2D Pre-rendered Backgrounds')" -ForegroundColor Gray
    Write-Host "   Reads backwards, but it is right: the toggle switches the" -ForegroundColor Gray
    Write-Host "   FLAT backdrops off so the pack's 3D rooms can show. The" -ForegroundColor Gray
    Write-Host "   game says so itself - 'Enable this when using a mod that" -ForegroundColor Gray
    Write-Host "   implements 3D backdrops for these areas.'" -ForegroundColor Gray
    Write-Host "   It takes effect on the next scene change, so leave the area" -ForegroundColor Gray
    Write-Host "   and come back." -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "  HEADS UP: rooms with pre-rendered backdrops render broken in" -ForegroundColor Yellow
    Write-Host "  VR. The optional Djipi pack above fixes exactly that." -ForegroundColor Yellow
    Write-Host ""
}
Write-Host "  Menu tips, HUD options and troubleshooting are" -ForegroundColor Gray
Write-Host "  on this game's page in the Hub." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to exit."
