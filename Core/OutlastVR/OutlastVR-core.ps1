# ============================================================
#  Outlast VR - Halcyon (dhalcyon)
# ------------------------------------------------------------
#  THE MOD BRINGS ITS OWN INSTALLER: Outlast-VR.bat.
#  It MUST run from inside the game folder - it checks for
#  OLGame.exe next to it and aborts otherwise. So the four files
#  are copied into Binaries\Win64 and the bat is started THERE.
#  It handles the rest from then on, including the configuration
#  under Documents\My Games\Outlast.
#
#  THE DOWNLOAD IS HOSTED ON PATREON BUT NEEDS NO ACCOUNT: an
#  address of the form patreon.com/file?h=...&m=... is public, so
#  the installer fetches it directly (same as the Luke Ross one).
#  A copy already on disk is used first; the page is only opened
#  if the download itself fails.
#
#  THE TARGET FOLDER IS Binaries\Win64, NOT the game folder
#  itself - the most common mix-up with this game.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Outlast VR Installer"
$ErrorActionPreference = "Stop"

# EVERY installer brings its own console helpers - they are NOT in
# InstallerSafety.ps1.
function Write-Step {
    param([int]$Step, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}
function Write-OK   { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m"  -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m"  -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m"  -ForegroundColor Red }
function Pause-User {
    param($text = "Press Enter to continue...")
    Write-Host ""
    Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow
    Read-Host
}
function Read-YesNo {
    param([string]$Prompt)
    while ($true) {
        Write-Host ""
        $a = (Read-Host " $Prompt [Y/N]").Trim().ToUpper()
        if ($a -eq "Y" -or $a -eq "YES") { return $true }
        if ($a -eq "N" -or $a -eq "NO")  { return $false }
        Write-Warn "Please type Y or N."
    }
}

$GAME_NAME   = "Outlast"
$APP_ID      = "238320"
$GAME_EXE    = "OLGame.exe"
$BIN_SUB     = "Binaries\Win64"
$MOD_NAME    = "Outlast VR"
$MOD_AUTHOR  = "Halcyon"
$MOD_VERSION = "August 2026"
$MOD_BAT     = "Outlast-VR.bat"
$MOD_FILES   = @("Outlast-VR.bat", "d3d9.dll", "openxr_loader.dll", "outlastvr.ini")
$POST_URL    = "https://www.patreon.com/dhalcyon/posts/nowhere-to-hide-165840706"
$FILE_URL    = "https://www.patreon.com/file?h=165840706&m=712144361"
$GRAIN_URL   = "https://www.nexusmods.com/outlast/mods/65?tab=files"
$TFC_URL     = "https://www.nexusmods.com/site/mods/588?tab=files"
$DOTNET6_URL = "https://aka.ms/dotnet/6.0/windowsdesktop-runtime-win-x64.exe"

# ---- The SECOND mod, added 2026-08-20 -------------------------
# Hammerthis' mod is built on a completely different idea: it does
# NOT put anything in the game folder. It launches Outlast through
# Steam, waits for OLGame.exe and injects a DLL into the running
# process. His README says "Extract this ZIP anywhere. You do not
# need to copy files into the Outlast game directory."
#
# WE STILL PUT IT UNDER THE GAME - in <game>\_vrmods\hammerthis\ -
# and "anywhere" covers that. Three reasons: the Hub can then find
# it the same way it finds every other mod, uninstalling is one
# folder to delete, and the two mods sit side by side where anyone
# can see both. No file of the game itself is touched either way.
#
# ALL RELEASES ARE PRERELEASES -> the list is queried, not /latest.
$MODB_NAME   = "Outlast VR (alpha)"
$MODB_AUTHOR = "Hammerthis"
$MODB_REPO   = "Hammerthis/Outlast-Vr-Mod"
$MODB_RELEASES = "https://github.com/$MODB_REPO/releases"
$MODB_DIR    = "_vrmods\hammerthis"
$MODB_BAT    = "PLAY_OUTLAST_VR.bat"
# Read from the real archive, not guessed: 18 entries, 5,943,108 B,
# sha256 c72196d7613a15f119060f0a5447b7b9a9897076804c95cc51b825ad49a236c7
$MODB_FILES  = @("PLAY_OUTLAST_VR.bat", "PLAY_OUTLAST_VR.ps1", "INJECT_VR_NOW.bat",
                 "UNLOAD_VR.bat", "RESTORE_OUTLAST_SETTINGS.bat", "injector.exe",
                 "OutlastVRDiagnostic.dll", "outlast_vr.ini")
# Where the two switch launchers go - same shape as BioShock.
$VRLAUNCH    = "_vrmods\VRLaunch"
$LAUNCH_A    = "Outlast VR (Halcyon).bat"
$LAUNCH_B    = "Outlast VR (Hammerthis).bat"

# ---- Header ---------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Outlast VR - Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Stereo rendering, full head tracking and VR cutscenes for" -ForegroundColor White
Write-Host "  Outlast. Two mods exist: one is gamepad-only, the other" -ForegroundColor White
Write-Host "  adds tracked controllers and VR hands." -ForegroundColor White
Write-Host ""
Write-Host "  One thing before you start:" -ForegroundColor White
Write-Host "   - " -NoNewline -ForegroundColor White
Write-Host " RUN OUTLAST ONCE NORMALLY FIRST " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     The game creates its settings files on that first launch," -ForegroundColor White
Write-Host "     and the mod's own installer needs them to be there." -ForegroundColor White
Write-Host ""

# ---- 0. WHICH MOD? --------------------------------------------
# Two mods, two very different approaches - the choice is not a
# matter of taste, so both are described before it is made.
Write-Host "  ------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "   Two Outlast VR mods exist. Which one?" -ForegroundColor Cyan
Write-Host "  ------------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "   [1] $MOD_NAME by $MOD_AUTHOR" -ForegroundColor White
Write-Host "       Controls: " -NoNewline -ForegroundColor Gray
Write-Host " GAMEPAD ONLY " -ForegroundColor Black -BackgroundColor DarkCyan
Write-Host "       Stereo rendering, full head tracking, VR cutscenes." -ForegroundColor Gray
Write-Host "       You hold a gamepad. There are no VR hands, and the" -ForegroundColor Gray
Write-Host "       camcorder is raised with a button, not with your arm." -ForegroundColor Gray
Write-Host "       The more mature of the two. Available via Patreon." -ForegroundColor Gray
Write-Host ""
Write-Host "   [2] $MODB_NAME by $MODB_AUTHOR" -ForegroundColor White
Write-Host "       Controls: " -NoNewline -ForegroundColor Gray
Write-Host " VR CONTROLLERS " -ForegroundColor Black -BackgroundColor Magenta
Write-Host "       Tracked controllers and VR hands. You reach out and" -ForegroundColor Gray
Write-Host "       GRAB the camcorder, raise it to your face yourself," -ForegroundColor Gray
Write-Host "       and R3 on it gives you the night vision." -ForegroundColor Gray
Write-Host "       " -NoNewline
Write-Host " EARLY ALPHA - expect bugs " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "       Props can vanish at some angles, shadows can shift," -ForegroundColor Gray
Write-Host "       framerate can drop, and the motion interactions are" -ForegroundColor Gray
Write-Host "       incomplete. Free, on GitHub." -ForegroundColor Gray
Write-Host ""
Write-Host "   [3] Both - installed side by side, switchable afterwards." -ForegroundColor White
Write-Host "       The Hub then shows one Play button per mod, so you" -ForegroundColor Gray
Write-Host "       can pick gamepad or VR controllers per session." -ForegroundColor Gray
Write-Host ""
$modChoice = ""
for ($i = 1; $i -le 20; $i++) {
    $modChoice = ("" + (Read-Host "  Your choice [1/2/3]")).Trim()
    if ($modChoice -in @("1","2","3")) { break }
    Write-Host "  Please answer 1, 2 or 3." -ForegroundColor Yellow
}
if ($modChoice -notin @("1","2","3")) {
    Write-Fail "No choice made - nothing was installed."
    Pause-User "Press Enter to exit."
    exit 1
}
$doA = ($modChoice -eq "1" -or $modChoice -eq "3")
$doB = ($modChoice -eq "2" -or $modChoice -eq "3")
Write-Host ""

# ---- 1. Locate the game ---------------------------------------
Write-Step 1 5 "Locating $GAME_NAME"
$gameRoot = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("Outlast") -ProbeExe "$BIN_SUB\$GAME_EXE"
if (-not $gameRoot) {
    # GOG and Epic create the same structure, just elsewhere.
    foreach ($c in @("C:\GOG Games\Outlast",
                     "C:\Program Files (x86)\GOG Galaxy\Games\Outlast",
                     "C:\Program Files\Epic Games\Outlast",
                     "C:\Program Files (x86)\Epic Games\Outlast")) {
        if (Test-Path -LiteralPath (Join-Path $c "$BIN_SUB\$GAME_EXE")) { $gameRoot = $c; break }
    }
}
if (-not $gameRoot) {
    Write-Warn "Could not find $GAME_NAME automatically."
    Write-Host "  Point me at the folder that CONTAINS Binaries\, for example:" -ForegroundColor White
    Write-Host "     C:\Program Files (x86)\Steam\steamapps\common\Outlast" -ForegroundColor Gray
    $gameRoot = (Read-Host "  Game folder").Trim().Trim('"')
}
$binDir = Join-Path $gameRoot $BIN_SUB
if (-not (Test-Path -LiteralPath (Join-Path $binDir $GAME_EXE))) {
    Write-Fail "No $GAME_EXE under $BIN_SUB - stopping rather than guessing."
    Write-Host "  Expected: $binDir\$GAME_EXE" -ForegroundColor Yellow
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameRoot"
Write-OK "Mod files go into: $binDir"

# Probe write access quietly - the announcement comes where it applies.
$needsAdmin = $false
try {
    $probe = Join-Path $binDir ".pcvrhub_write_probe"
    Set-Content -LiteralPath $probe -Value "ok" -ErrorAction Stop
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
} catch { $needsAdmin = $true }

if ($doA) {
# ---- Halcyon: the file-copy route -----------------------------
    # ---- 2. Fetch the archive -------------------------------------
    Write-Step 2 5 "The download"
    Write-Host ""
    # !!! PATREON FILE LINKS ARE PUBLIC - WE CAN FETCH THEM !!!
    # An address of the form patreon.com/file?h=...&m=... needs NO login
    # and works independently of any account. The Luke Ross installer has
    # always downloaded its mod exactly that way.
    # So no hand-placement is requested here, it is downloaded directly -
    # the search on disk is only the fallback for when the file is
    # already there or the network is down.
    $patterns = @("*Outlast*VR*.zip", "*OutlastVR*.zip", "*Outlast*.zip")
    $modZip = Find-PredownloadedFile -Patterns $patterns -Label "the Outlast VR mod"
    if (-not $modZip) {
        $tmpDl = Join-Path $env:TEMP ("outlastvr_dl_" + [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $tmpDl -Force | Out-Null
        $dest = Join-Path $tmpDl "Outlast-VR.zip"
        Invoke-SafeDownload -Urls @($FILE_URL) -Destination $dest -Label "$MOD_NAME" `
            -ManualUrl $POST_URL `
            -Instructions "Download the Outlast VR ZIP from the Patreon post, save it as '$dest', then choose Retry."
        if (Test-Path -LiteralPath $dest) { $modZip = $dest }
    }
    if (-not $modZip -or -not (Test-Path -LiteralPath $modZip)) {
        Write-Fail "No archive found - nothing was changed."
        Write-Host "  Download it from:" -ForegroundColor White
        Write-Host "     $POST_URL" -ForegroundColor Cyan
        Pause-User "Press Enter to exit."
        exit 1
    }
    Write-OK "Using: $modZip"

    # ---- 3. Put the files in place --------------------------------
    Write-Step 3 5 "Copying the files next to $GAME_EXE"

    $tmp = Join-Path $env:TEMP ("outlastvr_" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    [void](Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $tmp -Label $MOD_NAME)

    # The files may sit flat or inside a wrapper folder - so search the
    # WHOLE tree for the known bat rather than one fixed level.
    $allFiles = @(Get-ChildItem -LiteralPath $tmp -Recurse -File -Force -ErrorAction SilentlyContinue)
    if ($needsAdmin) {
        Pause-User "Press Enter to copy the files into the game folder - UAC required..." | Out-Null
    }
    $sources = @(); $copyFailed = $false
    foreach ($f in $MOD_FILES) {
        $hit = $allFiles | Where-Object { $_.Name -ieq $f } | Select-Object -First 1
        if (-not $hit) { continue }
        $sources += $hit.FullName
        try { Copy-Item -LiteralPath $hit.FullName -Destination (Join-Path $binDir $f) -Force -ErrorAction Stop }
        catch { $copyFailed = $true }
    }
    if ($copyFailed -and $sources.Count -gt 0) {
        Write-Warn "Copying into that folder needs administrator rights. Asking for them ..."
        $srcList = ($sources | ForEach-Object { "'" + $_ + "'" }) -join ","
        $ps = "foreach (`$s in @($srcList)) { Copy-Item -LiteralPath `$s -Destination '$binDir' -Force }"
        try { Start-Process powershell -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-Command",$ps) -Verb RunAs -Wait -ErrorAction Stop }
        catch { Write-Warn "The elevated copy was declined or failed." }
    }

    $missing = @()
    foreach ($f in $MOD_FILES) { if (-not (Test-Path -LiteralPath (Join-Path $binDir $f))) { $missing += $f } }
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

    if ($missing.Count -gt 0) {
        Write-Fail "These files did not arrive:"
        foreach ($m in $missing) { Write-Host "   $m" -ForegroundColor Yellow }
        Write-Host "  Copy them by hand into:" -ForegroundColor White
        Write-Host "     $binDir" -ForegroundColor Yellow
        Pause-User "Press Enter to exit."
        exit 1
    }
    Write-OK "All four files are in place."

    # ---- 4. The mod's own installer -------------------------------
    Write-Step 4 5 "Running the mod's own installer"
    Write-Host ""
    Write-Host "  $MOD_BAT does the actual setup, and it has to run from the" -ForegroundColor White
    Write-Host "  game folder - which is where it now sits. It also writes to" -ForegroundColor White
    Write-Host "  Outlast's config under your Documents folder." -ForegroundColor White
    Write-Host ""
    Write-Host "  Make sure Outlast is CLOSED - the script checks and refuses" -ForegroundColor White
    Write-Host "  to run otherwise." -ForegroundColor White
    Write-Host ""
    $batPath = Join-Path $binDir $MOD_BAT
    Pause-User "Press Enter to run $MOD_BAT..." | Out-Null
    try {
        Start-Process -FilePath $batPath -WorkingDirectory $binDir -Wait -ErrorAction Stop
        Write-OK "$MOD_BAT finished."
    } catch {
        Write-Warn "Could not start it: $($_.Exception.Message)"
        Write-Host "  Run it yourself from: $binDir" -ForegroundColor Yellow
    }

    # Marker for the Hub - into the INSTALLER folder, not the game folder.
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}

} else {
    Write-Info "Skipping the Halcyon mod - not chosen."
    $grainRemoved = $false
}

# ---- 4b. Hammerthis: the injector route -----------------------
# Nothing is copied into the game folder here. The whole mod lives
# in one folder and drives Outlast from outside.
if ($doB) {
    Write-Host ""
    Write-Info "Installing $MODB_NAME by $MODB_AUTHOR"
    $bDir = Join-Path $gameRoot $MODB_DIR

    # All releases are prereleases -> query the LIST. /releases/latest
    # returns nothing for a repo that has never had a stable release.
    $bUrl = $null; $bTag = ""; $bAsset = ""; $bSize = 0
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/$MODB_REPO/releases" `
                    -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
        foreach ($r in @($rels)) {
            $a = @($r.assets) | Where-Object { $_.name -match '(?i)\.zip$' } | Select-Object -First 1
            if ($a) { $bUrl = [string]$a.browser_download_url; $bTag = [string]$r.tag_name
                      $bAsset = [string]$a.name; $bSize = [long]$a.size; break }
        }
    } catch { Write-Warn "GitHub could not be reached." }
    if ($bUrl) { Write-OK "Release: $bTag  ($bAsset)" } else { $bUrl = $MODB_RELEASES }

    $bTmp = Join-Path $env:TEMP ("outlastvrb_" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $bTmp -Force | Out-Null
    $bZip = Join-Path $bTmp "OutlastVR.zip"

    # Name AND size have to match the current release, or an older copy
    # in the downloads folder would install silently.
    $bHave = Find-PredownloadedFile -Patterns @("OutlastVR-v*.zip") -Label "the Outlast VR alpha" `
                 -ExpectedName $bAsset -ExpectedSize $bSize
    if ($bHave -and (Test-Path -LiteralPath $bHave)) {
        $bZip = $bHave
        Write-Info "Using the copy you already downloaded."
    } else {
        Invoke-SafeDownload -Urls @($bUrl) -Destination $bZip -Label "$MODB_NAME $bTag" `
            -ManualUrl $MODB_RELEASES `
            -Instructions "Download the OutlastVR zip from the releases page, save it as '$bZip', then choose Retry."
    }

    if (Test-Path -LiteralPath $bZip) {
        # The archive carries a wrapper folder (OutlastVR-v0.1.0-alpha\)
        # whose name changes with every release - so the payload root is
        # RESOLVED through a marker file rather than assumed.
        $st = Expand-ArchiveToTarget -ArchivePath $bZip -TargetDir $bDir `
                -RelModFile $MODB_BAT `
                -Markers @("injector.exe", "outlast_vr.ini") `
                -Label "$MODB_NAME" `
                -SkipMessage "Nothing was copied."
        if ([string]$st -eq "ok" -or [string]$st -eq "manual") {
            # Proof on disk, file by file - the archive has eight parts
            # that all have to be there for the injector to work.
            $bMissing = @()
            foreach ($f in $MODB_FILES) {
                if (-not (Test-Path -LiteralPath (Join-Path $bDir $f))) { $bMissing += $f }
            }
            if ($bMissing.Count -gt 0) {
                Write-Fail ("These did not arrive: " + ($bMissing -join ", "))
                $doB = $false
            } else {
                Write-OK "Installed and verified: $bDir"
            }
        } else {
            Write-Fail "The package could not be unpacked."
            $doB = $false
        }
    } else {
        Write-Fail "No package - the alpha was not installed."
        $doB = $false
    }
    try { Remove-Item -LiteralPath $bTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}

# ---- 4c. The switch, when both are installed ------------------
# !!! THE TWO MODS MUST NOT RUN AT THE SAME TIME.
# Halcyon works through d3d9.dll, which Outlast loads at startup.
# Hammerthis injects into the running process. With Halcyon's proxy in
# place, launching through his bat would put both in the same process.
# So each launcher puts the other one out of the way first: parking
# d3d9.dll means renaming it, never deleting it.
$haveA = Test-Path -LiteralPath (Join-Path $gameRoot "$BIN_SUB\d3d9.dll")
$haveAParked = Test-Path -LiteralPath (Join-Path $gameRoot "$BIN_SUB\d3d9.dll.off")
$haveB = Test-Path -LiteralPath (Join-Path $gameRoot "$MODB_DIR\$MODB_BAT")
if (($haveA -or $haveAParked) -and $haveB) {
    Write-Host ""
    Write-Info "Both mods are installed - writing the two launchers."
    $vl = Join-Path $gameRoot $VRLAUNCH
    New-Item -ItemType Directory -Path $vl -Force | Out-Null
    $binAbs = Join-Path $gameRoot $BIN_SUB
    $bAbs   = Join-Path $gameRoot $MODB_DIR

    $batA = @"
@echo off
title Outlast VR - Halcyon
rem Bring Halcyon's proxy back if the other launcher parked it, then
rem start the game normally through Steam.
if exist "$binAbs\d3d9.dll.off" move /Y "$binAbs\d3d9.dll.off" "$binAbs\d3d9.dll" >nul
start "" "steam://rungameid/$APP_ID"
"@
    $batB = @"
@echo off
title Outlast VR - Hammerthis (alpha)
rem Park Halcyon's proxy so the two do not end up in one process,
rem then hand over to the alpha's own launcher.
if exist "$binAbs\d3d9.dll" move /Y "$binAbs\d3d9.dll" "$binAbs\d3d9.dll.off" >nul
cd /d "$bAbs"
call "$MODB_BAT"
"@
    try {
        Set-Content -LiteralPath (Join-Path $vl $LAUNCH_A) -Value $batA -Encoding ASCII -Force
        Set-Content -LiteralPath (Join-Path $vl $LAUNCH_B) -Value $batB -Encoding ASCII -Force
        Write-OK "Switch ready - the Hub shows one Play button per mod."
    } catch { Write-Warn "Could not write the launchers: $($_.Exception.Message)" }
}

# ---- 5. Remove the film grain (optional) ----------------------
# !!! THIS COMPANION MOD CANNOT BE INSTALLED BY COPYING !!!
# Counted: the archive holds SEVEN files and NOT ONE of them belongs
# in the game - they are GameProfile.xml, ObjectDescriptors and a
# TexturePack, i.e. INSTRUCTIONS FOR A PATCHING TOOL. Per
# GameProfile.xml it modifies the .upk packages under
# OLGame\CookedPCConsole.
# Without that tool there is NOTHING to copy, and we do not pretend
# otherwise. What we can do: fetch the file and put it where the user
# will find it.
$grainRemoved = $false
Write-Step 5 5 "Optional: remove the film grain"
Write-Host ""
Write-Host "  Outlast has film grain baked in - it is the game, not the mod." -ForegroundColor White
Write-Host "  A Nexus mod removes it without touching the other post effects." -ForegroundColor White
Write-Host "" 
Write-Host "  Purely cosmetic - VR works fine without it. It takes about five" -ForegroundColor Gray
Write-Host "  minutes: two downloads, then three clicks in a small tool that" -ForegroundColor Gray
Write-Host "  this installer opens and walks you through." -ForegroundColor Gray
Write-Host ""
if (Read-YesNo "  Fetch the film-grain mod as well?") {
    # Counterpart to the heading of the second half further down -
    # otherwise only that one looks like a section of its own.
    Write-Host ""
    Write-Host " ============================================================" -ForegroundColor Magenta
    Write-Host "  FIRST HALF - getting the two downloads" -ForegroundColor Cyan
    Write-Host " ============================================================" -ForegroundColor Magenta
    $fgPatterns = @("*Remove*Film*Grain*.zip", "*FilmGrain*.zip")
    $fgZip = Find-PredownloadedFile -Patterns $fgPatterns -Label "the film-grain mod"
    if (-not $fgZip) {
        Pause-User "Press Enter to open the Nexus page..." | Out-Null
        try { Start-Process $GRAIN_URL } catch { Write-Warn "Open manually: $GRAIN_URL" }
        Pause-User "Press Enter once the download has finished..." | Out-Null
        $fgZip = Find-PredownloadedFile -Patterns $fgPatterns -Label "the film-grain mod" -PageAlreadyOpen
    }
    if ($fgZip -and (Test-Path -LiteralPath $fgZip)) {
        # Put it NEXT TO the game - not inside, it does not belong there.
        $fgDir = Join-Path $gameRoot "_FilmGrainMod"
        try {
            New-Item -ItemType Directory -Path $fgDir -Force -ErrorAction Stop | Out-Null
            [void](Expand-ArchiveOrFallback -ArchivePath $fgZip -DestinationFolder $fgDir -Label "film-grain mod")
            # The archive holds a subfolder with the GameProfile.xml -
            # and THAT is the one the tool wants, not the one above it.
            $gp = Get-ChildItem -LiteralPath $fgDir -Recurse -File -Force -ErrorAction SilentlyContinue |
                  Where-Object { $_.Name -ieq "GameProfile.xml" } | Select-Object -First 1
            if ($gp) { $fgDir = $gp.DirectoryName }
            Write-OK "Mod folder ready: $fgDir"
        } catch { Write-Warn "Could not unpack it: $($_.Exception.Message)" }

        # ---- Fetch the tool -------------------------------------------
        # !!! TEXT ALONE HELPS NOBODY - it scrolls away before it is
        # needed. So the tool is fetched too, placed next to the mod
        # folder and started. The three steps then sit directly above the
        # running window.
        # !!! THIS TRANSITION USED TO DROWN IN THE DOWNLOAD NOISE !!!
        # The user has just answered two download questions and sees a
        # wall of [OK] lines. A white paragraph in between does not
        # stand out - but a SEPARATE section starts here. So it gets the
        # same heading as the steps further down.
        Write-Host ""
        Write-Host ""
        Write-Host " ============================================================" -ForegroundColor Magenta
        Write-Host "  NOW THE SECOND HALF - a small tool does the actual work" -ForegroundColor Cyan
        Write-Host " ============================================================" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "  What you just downloaded is NOT copied into the game. It is" -ForegroundColor White
        Write-Host "  a texture pack, and a tool has to patch it into Outlast's" -ForegroundColor White
        Write-Host "  own packages. That tool is free, and this installer fetches" -ForegroundColor White
        Write-Host "  it, opens it and walks you through three clicks." -ForegroundColor White
        Write-Host ""
        Write-Host "     TFC Installer for UE2-UE3" -ForegroundColor Cyan
        Write-Host ""
        $tfcPatterns = @("*TFC*Installer*.zip", "*TFCInstaller*.zip")
        $tfcZip = Find-PredownloadedFile -Patterns $tfcPatterns -Label "the TFC Installer"
        if (-not $tfcZip) {
            Pause-User "Press Enter to open its download page..." | Out-Null
            try { Start-Process $TFC_URL } catch { Write-Warn "Open manually: $TFC_URL" }
            Write-Host ""
            Write-Host "  Grab the file under Main files, then come back here." -ForegroundColor White
            Pause-User "Press Enter once the download has finished..." | Out-Null
            $tfcZip = Find-PredownloadedFile -Patterns $tfcPatterns -Label "the TFC Installer" -PageAlreadyOpen
        }

        $tfcExe = $null
        if ($tfcZip -and (Test-Path -LiteralPath $tfcZip)) {
            $tfcDir = Join-Path $gameRoot "_FilmGrainMod\TFCInstaller"
            try {
                New-Item -ItemType Directory -Path $tfcDir -Force -ErrorAction Stop | Out-Null
                [void](Expand-ArchiveOrFallback -ArchivePath $tfcZip -DestinationFolder $tfcDir -Label "TFC Installer")
                $hit = Get-ChildItem -LiteralPath $tfcDir -Recurse -File -Force -ErrorAction SilentlyContinue |
                       Where-Object { $_.Name -ieq "TFCInstaller.exe" } | Select-Object -First 1
                if ($hit) { $tfcExe = $hit.FullName; Write-OK "Tool ready: $tfcExe" }
                else { Write-Warn "No TFCInstaller.exe inside that archive." }
            } catch { Write-Warn "Could not unpack the tool: $($_.Exception.Message)" }
        }

        if ($tfcExe) {
            # ---- START IT FIRST, THEN WALK THROUGH IT -----------------
            # All three steps used to be printed at once and only then
            # came the launch - by the time the user needed them they had
            # scrolled away. Now: open the tool, check that it runs, and
            # THEN one step at a time, each with its own Enter gate and
            # the matching path on the clipboard.
            Write-Host ""
            Write-Host "  The tool opens now. Leave this window where it is -" -ForegroundColor White
            Write-Host "  it will walk you through three steps, one at a time." -ForegroundColor White
            Pause-User "Press Enter to open the tool..." | Out-Null
            try { Start-Process -FilePath $tfcExe -WorkingDirectory (Split-Path $tfcExe -Parent) } catch {
                Write-Warn "Could not start it: $($_.Exception.Message)"
            }

            # ---- Is it running at all? --------------------------------
            Write-Host ""
            Write-Host "  Did a window open?" -ForegroundColor White
            Write-Host "     Enter        yes - carry on" -ForegroundColor Gray
            Write-Host "     I  + Enter   no, nothing happened" -ForegroundColor Gray
            $ans = ""
            try { $ans = (Read-Host "  Your answer").Trim().ToUpper() } catch {}
            if ($ans -eq "I") {
                # The tool names .NET 6 in its own requirements.txt.
                # If that is missing, there is NEITHER a window NOR an
                # error message - which is why the question above is the
                # only reliable way to detect this.
                Write-Host ""
                Write-Host "  Then the .NET Desktop Runtime 6 is missing - the tool" -ForegroundColor White
                Write-Host "  needs it and says so in its own requirements. Without it" -ForegroundColor White
                Write-Host "  nothing appears at all, not even an error." -ForegroundColor White
                Write-Host ""
                $rtDir = Join-Path $env:TEMP ("dotnet6_" + [System.IO.Path]::GetRandomFileName())
                New-Item -ItemType Directory -Path $rtDir -Force | Out-Null
                $rtExe = Join-Path $rtDir "windowsdesktop-runtime-6-win-x64.exe"
                Invoke-SafeDownload -Urls @($DOTNET6_URL) -Destination $rtExe -Label ".NET Desktop Runtime 6" `
                    -ManualUrl $DOTNET6_URL `
                    -Instructions "Download the .NET Desktop Runtime 6 (x64) installer, save it as '$rtExe', then choose Retry."
                if (Test-Path -LiteralPath $rtExe) {
                    Pause-User "Press Enter to install it - UAC required..." | Out-Null
                    try { Start-Process -FilePath $rtExe -Wait -Verb RunAs -ErrorAction Stop; Write-OK "Runtime installed." }
                    catch { Write-Warn "The install was declined or failed: $($_.Exception.Message)" }
                    Pause-User "Press Enter to open the tool again..." | Out-Null
                    try { Start-Process -FilePath $tfcExe -WorkingDirectory (Split-Path $tfcExe -Parent) } catch {
                        Write-Warn "Still could not start it. Run it by hand: $tfcExe"
                    }
                }
                try { Remove-Item -LiteralPath $rtDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            }

            # ---- Step 1 of 3 ------------------------------------------
            try { Set-Clipboard -Value $gameRoot } catch {}
            Write-Host ""
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " STEP 1 of 3 - the Game folder" -ForegroundColor Cyan
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  In the tool:" -ForegroundColor White
            Write-Host "   a) click the " -NoNewline -ForegroundColor White
            Write-Host " Game folder " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host " button" -ForegroundColor White
            Write-Host "   b) click into the LOWER text field" -ForegroundColor White
            Write-Host "   c) Ctrl+V, press " -NoNewline -ForegroundColor White
            Write-Host " Select Folder " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Write-Host "  This path is on your clipboard now:" -ForegroundColor White
            Write-Host ""
            Write-Host "   $gameRoot " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Pause-User "Done? Press Enter for step 2..." | Out-Null

            # ---- Step 2 of 3 ------------------------------------------
            try { Set-Clipboard -Value $fgDir } catch {}
            Write-Host ""
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " STEP 2 of 3 - the Mod folder" -ForegroundColor Cyan
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "   a) click the " -NoNewline -ForegroundColor White
            Write-Host " Mod folder " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host " button" -ForegroundColor White
            Write-Host "   b) click into the same LOWER text field" -ForegroundColor White
            Write-Host "   c) Ctrl+V, press " -NoNewline -ForegroundColor White
            Write-Host " Select Folder " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Write-Host "  This path is on your clipboard now:" -ForegroundColor White
            Write-Host ""
            Write-Host "   $fgDir " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Pause-User "Done? Press Enter for step 3..." | Out-Null

            # ---- Step 3 of 3 ------------------------------------------
            Write-Host ""
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " STEP 3 of 3 - apply it" -ForegroundColor Cyan
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  Click " -NoNewline -ForegroundColor White
            Write-Host " Update Outlast + DLCs " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host " and wait." -ForegroundColor White
            Write-Host "  It just skips the DLCs if they are not installed." -ForegroundColor Gray
            Write-Host ""
            Write-Host "  It copies your original packages aside first, inside the" -ForegroundColor Gray
            Write-Host "  game folder. Restore Backup in the same tool puts them" -ForegroundColor Gray
            Write-Host "  back, so nothing here is permanent." -ForegroundColor Gray
            Write-Host ""
            Write-Host "  When it says it finished, CLOSE the tool - you do not need" -ForegroundColor White
            Write-Host "  it again unless you want to undo this." -ForegroundColor White
            Write-Host ""
            Pause-User "Closed it? Press Enter to finish..." | Out-Null
            Write-OK "Film grain removed. Start the game and see."
            # Remember this, so the closing text further down does not
            # claim the film grain is still there.
            $grainRemoved = $true
        } else {
            Write-Info "Without the tool the files just sit there - they are here when you want them:"
            Write-Host "     $fgDir" -ForegroundColor Yellow
            Write-Host "  Get the tool at: $TFC_URL" -ForegroundColor Cyan
        }

    } else {
        Write-Info "Skipped - nothing was changed."
    }
} else {
    Write-Info "Skipped. You can run this installer again later."
}

Write-Host ""
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " IN THE GAME" -ForegroundColor Cyan
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Press Insert to open the menu, then the VR tab - tune Eye" -ForegroundColor White
Write-Host "  Separation and Convergence until it sits right for you." -ForegroundColor White
Write-Host "  Turn motion blur OFF in Outlast's own settings." -ForegroundColor White
Write-Host ""
Write-Host "  One thing the author names himself, so it does not surprise" -ForegroundColor Gray
Write-Host "  you: light flares can pass through walls. Harmless, and not" -ForegroundColor Gray
Write-Host "  fixed yet." -ForegroundColor Gray
Write-Host ""
if ($grainRemoved) {
    Write-Host "  Outlast has film grain baked in - but you just removed it" -ForegroundColor Gray
    Write-Host "  with the Remove Film Grain mod, so that one is handled." -ForegroundColor Gray
} else {
    Write-Host "  Outlast also has film grain baked in. Run this installer" -ForegroundColor Gray
    Write-Host "  again if you want to remove it - it is the last step." -ForegroundColor Gray
}
Write-Host ""
Write-Host "  You are not armed. You never were. Now you can look behind you." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
