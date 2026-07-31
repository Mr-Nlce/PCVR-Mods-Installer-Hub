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

Write-Host "  You provide your own dump. What is needed, exactly:" -ForegroundColor White
Write-Host "    Nintendo 64 - not GameCube, 3DS or Virtual Console" -ForegroundColor Gray
Write-Host "    a .z64 file, 32 MB (33,554,432 bytes)" -ForegroundColor Gray
Write-Host "    Ocarina of Time OR Ocarina of Time: Master Quest" -ForegroundColor Gray
Write-Host "    several regions and revisions work - check yours below" -ForegroundColor Gray
Write-Host ""
Write-Host "  On the first launch soh.exe reads it once and generates an .otr" -ForegroundColor Gray
Write-Host "  archive; after that the ROM is no longer read. It never leaves" -ForegroundColor Gray
Write-Host "  your PC." -ForegroundColor Gray
Write-Host ""
Write-Host "  This checker is the authoritative answer on whether your exact" -ForegroundColor Gray
Write-Host "  file is supported:" -ForegroundColor Gray
Write-Host ""
Write-Host "  https://ship.equipment/" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Drag & drop your ROM file onto this window and press Enter to" -ForegroundColor White
Write-Host "  copy it into the game folder now - or just press Enter to skip:" -ForegroundColor White
Write-Host "  soh.exe will ask you to pick the ROM on its first start instead." -ForegroundColor Gray
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
try { if ($relTag) { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $relTag -Encoding UTF8 -Force } } catch {}
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".launch_exe") -Value $exePath -Encoding UTF8 -Force } catch {}

# ---- HD texture pack (optional) -----------------------------
# OoT Reloaded 4K (evilgames.eu): a ~4 GB .7z holding a single .o2r that
# Ship of Harkinian loads from its mods\ folder as "alternate assets".
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  OPTIONAL: HD texture pack (OoT Reloaded 4K)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  A 4K HD texture pack for Ocarina of Time. It's fully optional" -ForegroundColor White
Write-Host "  and you can toggle it in-game with Tab, so it's risk-free." -ForegroundColor White
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |            LARGE DOWNLOAD - ABOUT 4 GB               |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Both the download and the extraction take a while and show a" -ForegroundColor Gray
Write-Host "  progress percentage. You can skip now and add it any time by" -ForegroundColor Gray
Write-Host "  re-running this installer." -ForegroundColor Gray
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
                        Write-Host "  Turn them on in-game: press Esc, go to Enhancements >" -ForegroundColor Gray
                        Write-Host "  Graphics / Mods and tick 'Use alternate assets'. Press" -ForegroundColor Gray
                        Write-Host "  Tab during play to toggle the textures on/off." -ForegroundColor Gray
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
                            Write-Host "  Enable in-game via Esc > Enhancements > Graphics / Mods >" -ForegroundColor Gray
                            Write-Host "  'Use alternate assets' (Tab toggles them during play)." -ForegroundColor Gray
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

# -------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |            REQUIRED IN-GAME SETTINGS                 |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Without these the headset shows nothing or a broken image:" -ForegroundColor White
Write-Host ""
Write-Host "   Graphics backend         " -NoNewline -ForegroundColor White; Write-Host " DirectX11 (default) " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Window aspect ratio      " -NoNewline -ForegroundColor White; Write-Host " 4:3 " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   MSAA                     " -NoNewline -ForegroundColor White; Write-Host " Off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Internal Resolution      " -NoNewline -ForegroundColor White; Write-Host " 100% " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Do NOT toggle 'Enable advanced settings' while playing, and" -ForegroundColor Gray
Write-Host "  do not switch to OpenGL." -ForegroundColor Gray
Write-Host ""
Write-Host "  IN-GAME MENU: lift the headset slightly, click the game window" -ForegroundColor Cyan
Write-Host "  on the desktop and press Esc - settings, VR controller input," -ForegroundColor Gray
Write-Host "  quality-of-life options and cheats all live there." -ForegroundColor Gray
Write-Host ""
Write-Host "  ENHANCEMENTS (Esc > VR mod settings > Enhancements, on the right):" -ForegroundColor Cyan
if ($doHd -in @("y","Y")) {
    Write-Host "   - Tick 'Use Alternate Assets' to switch the HD textures on." -ForegroundColor Gray
}
Write-Host "   - Scroll down and tick 'Disable Black Bar Letterboxes' to remove" -ForegroundColor Gray
Write-Host "     the black bars in cutscenes and dialogue." -ForegroundColor Gray
Write-Host ""
Write-Host "  HOW TO PLAY:" -ForegroundColor Cyan
Write-Host "    Launch with 'Start in VR' in the Hub, or use the new" -ForegroundColor Gray
Write-Host "    'Ocarina of Time VR' desktop shortcut. On the first start," -ForegroundColor Gray
Write-Host "    soh.exe processes your ROM (watch for 'OTR Successfully" -ForegroundColor Gray
Write-Host "    Generated'), then the game begins." -ForegroundColor Gray
Write-Host ""
Write-Host "  HEADS UP: indoor pre-rendered areas do not render properly yet," -ForegroundColor Yellow
Write-Host "  so in those rooms you have to feel your way to the exit." -ForegroundColor Yellow
Write-Host ""
Write-Host "  See the README for menu tips, HUD options and slingshot aiming." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  The Hero of Time answers Hyrule's call once more." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
