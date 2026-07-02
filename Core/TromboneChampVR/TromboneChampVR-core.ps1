# ============================================================
#  Trombone Champ VR Installer (BaboonVR by Raicuparta)
# ============================================================
#
#  BaboonVR only works on an older Trombone Champ build, so we
#  pin the game to a known-good Steam manifest using Steam
#  Console's download_depot command (with a DepotDownloader
#  fallback), then move the depot out of Steam's reach into a
#  stable folder so a future Steam update can't break it.
#
#  The BaboonVR mod itself lives on itch.io and CANNOT be
#  auto-downloaded (itch requires a manual click), so the user
#  downloads 'baboon-vr-win.zip' themselves and points this
#  installer at it. We install the BepInEx mod files it contains
#  DIRECTLY and ignore the bundled RaiManager.exe.
#
#  NOTE: an OFFICIAL standalone VR game, Trombone Champ:
#  Unflattened, exists and is far more polished. This installer
#  is for the community meme mod; the official release is linked
#  in the intro and at the end.
#
#  Flow:
#    1) Steam Console download_depot 1059990 1059991 <manifest>
#       (DepotDownloader fallback after two failed attempts)
#    2) Locate the depot folder and move it to
#       C:\Games\Trombone Champ VR (default, user can change)
#    3) Drop steam_appid.txt so the EXE launches directly
#    4) Open the itch.io page, take the user's downloaded
#       baboon-vr-win.zip, and copy the BepInEx mod files into
#       the pinned game folder
#    5) Desktop shortcut on TromboneChamp.exe
# ============================================================

$Host.UI.RawUI.WindowTitle = "Trombone Champ VR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

# -------------------------------------------------------
#  Configuration
# -------------------------------------------------------
$MOD_NAME       = "BaboonVR 0.3.0 (by Raicuparta)"
$ITCH_URL       = "https://raicuparta.itch.io/baboon-vr"

# Trombone Champ pinned to the last mod-compatible manifest.
$DEPOT_APPID    = "1059990"
$DEPOT_DEPOTID  = "1059991"
$DEPOT_MANIFEST = "8892575399251592659"
$DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"

# Game executable inside the depot
$GAME_EXE       = "TromboneChamp.exe"

# Target install folder
$DEFAULT_PATH   = "C:\Games\Trombone Champ VR"

# The mod ZIP the user downloads from itch.io, and a file that
# only exists once the mod is correctly in place.
$MOD_ZIP_NAME   = "baboon-vr-win.zip"
$MOD_PROBE      = "BepInEx\plugins\BaboonVr\com.raicuparta.baboon-vr.dll"

# -------------------------------------------------------
#  Console helpers (defined inline per installer)
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "   Trombone Champ VR - Mod Installer" -ForegroundColor Cyan
    Write-Host "   Installs: $MOD_NAME" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
}
function Write-Step { param($num, $total, $text)
    Write-Host ""
    Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
    Write-Host ""
}
function Write-OK   { param($text) Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host "  [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host "  [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "  [XX] $text" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }
function Read-Marked { param($text) Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; return (Read-Host " >") }

# -------------------------------------------------------
#  Pre-flight
# -------------------------------------------------------
Write-Header

Write-Host "  Pins Trombone Champ to a known-good Steam depot in its own" -ForegroundColor White
Write-Host "  folder, then adds the BaboonVR mod. Your normal install is" -ForegroundColor White
Write-Host "  left untouched." -ForegroundColor White
Write-Host ""
Write-Host "  You'll need:" -ForegroundColor White
Write-Host "    - Trombone Champ owned on Steam (App $DEPOT_APPID)" -ForegroundColor Gray
Write-Host "    - Steam running and logged in" -ForegroundColor Gray
Write-Host "    - The mod ZIP from itch.io ('$MOD_ZIP_NAME') - you add it in step 4" -ForegroundColor Gray
Write-Host "    - About 1 GB free disk space" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to begin..." | Out-Null

# -------------------------------------------------------
#  STEP 1: Steam Console download_depot
# -------------------------------------------------------
Write-Step 1 5 "Download the compatible build via Steam Console"

try { Set-Clipboard -Value $DEPOT_COMMAND } catch {}

Write-Host "  This downloads the depot build of Trombone Champ." -ForegroundColor Gray
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   ACTION REQUIRED - Paste into Steam Console" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [OK] Depot command copied to clipboard." -ForegroundColor Yellow
Write-Host "  ( $DEPOT_COMMAND )" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press Enter to open the Steam Console, then click the input" -ForegroundColor White
Write-Host "  field, paste (Ctrl+V) and hit Enter." -ForegroundColor White
if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Host "  (i) Virtual Desktop: if it doesn't open, use Steam - View -" -ForegroundColor DarkGray
    Write-Host "      Console. DepotDownloader fallback kicks in after 2 tries." -ForegroundColor DarkGray
}
Pause-User "Press Enter to open the Steam Console..." | Out-Null
Start-Process "steam://nav/console"

Write-Host ""
Pause-User "Press Enter once the download is complete..." | Out-Null

# -------------------------------------------------------
#  STEP 2: Locate + move depot to stable folder
# -------------------------------------------------------
Write-Step 2 5 "Locate depot and move to stable folder"

Write-Host "  Looking for Steam installation..." -ForegroundColor White

$steamInstallPath = $null
foreach ($reg in @(
    "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
    "HKLM:\SOFTWARE\Valve\Steam",
    "HKCU:\SOFTWARE\Valve\Steam"
)) {
    try {
        $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
        if ($p -and (Test-Path $p)) { $steamInstallPath = $p; break }
    } catch {}
}

$depotPath = $null

if ($steamInstallPath) {
    $autoPath = Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID"
    Write-Info "Expected depot path: $autoPath"
    if ((Test-Path $autoPath) -and (Test-Path (Join-Path $autoPath $GAME_EXE))) {
        $depotPath = $autoPath
        Write-OK "Depot folder found automatically!"
    } else {
        Write-Warn "Depot folder not found at expected location yet."
    }
} else {
    Write-Warn "Could not find Steam installation in registry."
}

if (-not $depotPath) {
    $probePaths = @()
    if ($steamInstallPath) {
        $probePaths += (Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID")
    }
    $depotPath = Resolve-DepotPath -GameName "Trombone Champ" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
    if (-not $depotPath) {
        Write-Fail "No depot folder provided."
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
}

# Sanity check: depot should contain the game exe
$depotExe = Join-Path $depotPath $GAME_EXE
if (-not (Test-Path $depotExe)) {
    Write-Warn "'$GAME_EXE' not found inside depot."
    Write-Host "  Download may be incomplete or the wrong manifest." -ForegroundColor Gray
    $choice = ""
    while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Marked "Install anyway? (Y/N)").Trim() }
    if ($choice -in @("n","N")) {
        Write-Info "Aborted by user."
        Pause-User "Press Enter to exit..." | Out-Null
        exit 0
    }
} else {
    Write-OK "$GAME_EXE confirmed in depot."
}

# Pick target folder and move there
$parentOfDepot = Split-Path $depotPath -Parent  # ...\app_1059990

Write-Host ""
Write-Host "  Default install location: $DEFAULT_PATH" -ForegroundColor Gray
Write-Host "  (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
Write-Host "   library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
$userInput = (Read-Marked "Press Enter for default, or type a full path").Trim().Trim('"')
if (-not $userInput) {
    $targetPath = $DEFAULT_PATH
} else {
    $targetPath = $userInput
}

$targetParent = Split-Path $targetPath -Parent
if ($targetParent -and -not (Test-Path $targetParent)) {
    try { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
    catch { Write-Fail "Could not create parent folder $targetParent : $_"; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
}

Write-Host ""
Write-Host "  Moving to: $targetPath" -ForegroundColor Gray

if (Test-Path $targetPath) {
    Write-Warn "A folder already exists at $targetPath"
    Write-Host "    [Y] Delete and proceed   [N] Keep it, abort" -ForegroundColor Gray
    $choice = ""
    while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Marked "Your choice (Y/N)").Trim() }
    if ($choice -in @("n","N")) {
        Write-Info "Aborted by user."
        Pause-User "Press Enter to exit..." | Out-Null
        exit 0
    }
    try { Remove-Item $targetPath -Recurse -Force -ErrorAction Stop }
    catch { Write-Fail "Could not delete: $_"; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
}

try {
    Move-Item -Path $depotPath -Destination $targetPath -ErrorAction Stop
    Write-OK "Game moved to: $targetPath"
} catch {
    Write-Fail "Move failed: $_"
    Write-Info "The game files are still at: $depotPath"
    Write-Host "  You can move that folder to '$targetPath' by hand, then re-run" -ForegroundColor Gray
    Write-Host "  this installer to finish the mod step." -ForegroundColor Gray
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}

# Clean up empty app_<id> folder
try {
    if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
        Remove-Item $parentOfDepot -Force
    }
} catch {}

$gamePath    = $targetPath
$gameExePath = Join-Path $gamePath $GAME_EXE

# -------------------------------------------------------
#  STEP 3: steam_appid.txt
# -------------------------------------------------------
Write-Step 3 5 "Drop steam_appid.txt"

# Without this, Steam may try to re-install or update Trombone Champ
# whenever the user launches the EXE while Steam is running.
try {
    $steamAppIdFile = Join-Path $gamePath "steam_appid.txt"
    Set-Content -Path $steamAppIdFile -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force
    Write-OK "steam_appid.txt created (prevents Steam re-install prompt)."
} catch {
    Write-Warn "Could not create steam_appid.txt: $_"
    Write-Host "  Create a file called 'steam_appid.txt' next to $GAME_EXE," -ForegroundColor Gray
    Write-Host "  containing only the number $DEPOT_APPID." -ForegroundColor Gray
}

# -------------------------------------------------------
#  STEP 4: Add the BaboonVR mod files (user-supplied ZIP)
# -------------------------------------------------------
Write-Step 4 5 "Add the BaboonVR mod files"

Write-Host "  BaboonVR is on itch.io and can't be auto-downloaded:" -ForegroundColor White
Write-Host "    1) The itch.io page opens in your browser." -ForegroundColor White
Write-Host "    2) Click 'Download', then download '$MOD_ZIP_NAME'." -ForegroundColor White
Write-Host "    3) Come back here and press Enter." -ForegroundColor White
Pause-User "Press Enter to open the itch.io download page..." | Out-Null
try { Start-Process $ITCH_URL } catch { Write-Warn "Could not open the browser. Open manually: $ITCH_URL" }
Pause-User "Press Enter once '$MOD_ZIP_NAME' has finished downloading..." | Out-Null

# Locate the downloaded ZIP: probe the usual spots, then prompt with
# retry/skip fallbacks. No hard abort.
$modZip = $null
$attempt = 0
while (-not $modZip) {
    $attempt++
    $candidates = @(
        (Join-Path $env:USERPROFILE "Downloads\$MOD_ZIP_NAME"),
        (Join-Path $env:USERPROFILE "Desktop\$MOD_ZIP_NAME"),
        (Join-Path (Get-Location).Path $MOD_ZIP_NAME)
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { $modZip = $c; break }
    }
    if ($modZip) {
        Write-OK "Found mod ZIP: $modZip"
        break
    }

    Write-Warn "Could not find '$MOD_ZIP_NAME' (Downloads / Desktop / here)."
    Write-Host "    [P] Type full path   [R] Look again   [O] Re-open page   [S] Skip" -ForegroundColor Gray
    $pick = (Read-Marked "Your choice (P/R/O/S)").Trim()
    switch ($pick.ToUpper()) {
        "P" {
            $typed = (Read-Marked "Full path to '$MOD_ZIP_NAME' or its folder").Trim().Trim('"')
            if ($typed) {
                if ((Test-Path $typed) -and (Test-Path $typed -PathType Leaf)) {
                    $modZip = $typed
                } elseif ((Test-Path $typed -PathType Container) -and (Test-Path (Join-Path $typed $MOD_ZIP_NAME))) {
                    $modZip = (Join-Path $typed $MOD_ZIP_NAME)
                } else {
                    Write-Warn "Nothing usable at that path."
                }
            }
        }
        "O" { try { Start-Process $ITCH_URL } catch { Write-Warn "Open manually: $ITCH_URL" } }
        "S" {
            Write-Warn "Skipping the mod - the game will run flat (no VR)."
            break
        }
        default { }  # R or anything else -> loop and re-probe
    }
    if ($pick.ToUpper() -eq "S") { break }
    if ($attempt -ge 12 -and -not $modZip) {
        Write-Warn "Still no ZIP after several tries - continuing without the mod."
        break
    }
}

if ($modZip -and (Test-Path $modZip)) {
    $modTmp = Join-Path $env:TEMP "TromboneChampVR_$([System.IO.Path]::GetRandomFileName())"
    New-Item -ItemType Directory -Path $modTmp | Out-Null

    Write-Info "Extracting '$MOD_ZIP_NAME'..."
    $efb = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $modTmp -Label "BaboonVR" `
            -SkipMessage "Skipped - BaboonVR was not extracted; the mod will NOT load."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..." | Out-Null; exit 1 }

    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        # Find the 'Mod' folder (the part RaiManager would have applied).
        $modSrc = $null
        $manifestHit = Get-ChildItem -Path $modTmp -Recurse -Filter "manifest.json" -ErrorAction SilentlyContinue |
                       Where-Object { $_.DirectoryName -match '(\\|/)Mod$' } | Select-Object -First 1
        if ($manifestHit) {
            $modSrc = $manifestHit.DirectoryName
        } else {
            $candDir = Join-Path $modTmp "Mod"
            if (Test-Path $candDir) { $modSrc = $candDir }
        }

        if (-not $modSrc) {
            Write-Warn "Couldn't find the mod's 'Mod' folder inside the ZIP."
            Write-Host "  Inside '$modTmp' there should be a 'Mod' folder containing" -ForegroundColor Gray
            Write-Host "  BepInEx and CopyToGame. Copy 'Mod\BepInEx' into the game" -ForegroundColor Gray
            Write-Host "  folder and 'Mod\CopyToGame\*' into the game root by hand." -ForegroundColor Gray
            Pause-User "Press Enter once you've copied the files (or to continue)..." | Out-Null
        } else {
            $copied = $true
            # winhttp.dll + doorstop_config.ini -> game root
            try {
                $ctg = Join-Path $modSrc "CopyToGame"
                if (Test-Path $ctg) {
                    Copy-Item -Path (Join-Path $ctg "*") -Destination $gamePath -Recurse -Force -ErrorAction Stop
                }
            } catch { $copied = $false; Write-Warn "CopyToGame copy failed: $_" }
            # BepInEx tree -> game\BepInEx
            try {
                $bep = Join-Path $modSrc "BepInEx"
                if (Test-Path $bep) {
                    Copy-Item -Path $bep -Destination $gamePath -Recurse -Force -ErrorAction Stop
                }
            } catch { $copied = $false; Write-Warn "BepInEx copy failed: $_" }

            if (Test-Path (Join-Path $gamePath $MOD_PROBE)) {
                Write-OK "BaboonVR mod files installed."
            } elseif ($copied) {
                Write-Warn "Mod files copied, but the expected plugin wasn't found:"
                Write-Warn "  $MOD_PROBE"
                Write-Warn "The mod may still work; check the game folder if VR doesn't start."
            } else {
                Write-Warn "Some mod files may not have copied. Inspect:"
                Write-Warn "  $gamePath"
                Write-Host "  Manual fallback: copy 'Mod\BepInEx' into '$gamePath' and" -ForegroundColor Gray
                Write-Host "  'Mod\CopyToGame\*' into '$gamePath' from:" -ForegroundColor Gray
                Write-Host "  $modSrc" -ForegroundColor Gray
                Pause-User "Press Enter to continue..." | Out-Null
            }
        }
    } else {
        Write-Warn "Mod extraction was skipped. The game will run flat (no VR)."
        Write-Host "  To finish later: extract '$MOD_ZIP_NAME', then copy 'Mod\BepInEx'" -ForegroundColor Gray
        Write-Host "  into '$gamePath' and 'Mod\CopyToGame\*' into '$gamePath'." -ForegroundColor Gray
    }

    try { Remove-Item -Path $modTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
} else {
    Write-Warn "No mod ZIP applied. Trombone Champ is installed but will run flat."
    Write-Host "  Re-run this installer once you've downloaded '$MOD_ZIP_NAME' to" -ForegroundColor Gray
    Write-Host "  add the VR mod." -ForegroundColor Gray
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
#  STEP 5: Desktop shortcut
# -------------------------------------------------------
Write-Step 5 5 "Create desktop shortcut"

try {
    $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Trombone Champ VR.lnk" -TargetPath $gameExePath -WorkingDir $gamePath -IconPath "$gameExePath,0"
    Write-OK "Desktop shortcut 'Trombone Champ VR' created."
} catch {
    Write-Warn "Could not create desktop shortcut: $_"
    Write-Host "  Launch manually from:" -ForegroundColor Gray
    Write-Host "  $gameExePath" -ForegroundColor Yellow
}

# -------------------------------------------------------
#  Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Done. Before launching:" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  1. Steam client running   2. Start SteamVR" -ForegroundColor White
Write-Host "  3. Launch via the 'Trombone Champ VR' desktop shortcut" -ForegroundColor White
Write-Host ""
Write-Host "  Pucker up, hit the slide, and toot your way to glory." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit." | Out-Null
exit 0
