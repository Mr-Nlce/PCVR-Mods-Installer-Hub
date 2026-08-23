# ============================================================
#  VIRTUA COP 2 VR - VC2VR by NeuralF
# ============================================================
#  A native VR mod for the 1997 PC port. It intercepts the
#  game's software renderer, rebuilds the real 3D scene from
#  the geometry the engine projects each frame, and re-renders
#  it through OpenXR. The controller is the light gun.
#
#  !!! THE GAME IS NOT SOLD ANYWHERE. No Steam, no GOG, no
#  Epic - the user brings their own 1997 copy, and we ship
#  nothing of it. So there is no library to search: the user
#  DROPS PPJ2DD.EXE into this window and its folder is the
#  game root.
#
#  !!! THE 1997 LOADER READS ITS DATA FROM ..\BIN\ - one level
#  ABOVE the working directory. A stock install puts
#  PPJ2DD.EXE in the game root right NEXT TO the BIN folder,
#  so started from there it cannot find its own data and dies
#  hunting for a CD ("not found <drive>:\...\MOTCMN.BIN").
#  The author's fix, and what this installer does: create a
#  PROJECT subfolder and copy the game's LOOSE FILES into it -
#  files only, never the folders. BIN stays where it is, and
#  from inside PROJECT it is then exactly one level up.
#
#  TWO PROCESSES BY DESIGN: the game is 32-bit, the VR runtime
#  is 64-bit, and they cannot share one process. HGL_VIEW.DLL
#  rides inside the game, VC2VR.exe renders for the headset.
#  That is why the VR half does NOT go into the game folder.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Virtua Cop 2 VR Installer"
$ErrorActionPreference = "Stop"

function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  [$n/$t] $x" -ForegroundColor Cyan; Write-Host "  ----------------------------------------" -ForegroundColor DarkGray }
function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$MOD_NAME   = "VC2VR"
$MOD_AUTHOR = "NeuralF"
$REPO       = "NeuralF/Rea-Virtua-Cop-2-VR"
$RELEASES   = "https://github.com/$REPO/releases"
$GAME_EXE   = "PPJ2DD.EXE"
$PROJECT    = "PROJECT"
# The VR half lives on its own - it does not belong near the game.
$VR_ROOT    = Join-Path $env:LOCALAPPDATA "Programs\Virtua Cop 2 VR"

# Read from the real v0.9-beta archive (6 files, flat, 759,200 B,
# sha256 c4060259...), not guessed.
$GAME_SIDE  = @("HGL_VIEW.DLL", "HGL_VIEW.ini")
$VR_SIDE    = @("VC2VR.exe", "VC2VR.ini", "openxr_loader.dll")

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Virtua Cop 2 - VR" -ForegroundColor Cyan
Write-Host " $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Not a flat screen in a headset. The mod reads the geometry" -ForegroundColor White
Write-Host "  the 1997 engine draws each frame, rebuilds the real 3D scene" -ForegroundColor White
Write-Host "  from it, and renders that for your eyes - with the game's own" -ForegroundColor White
Write-Host "  textures, lighting and sky. You can look around corners the" -ForegroundColor White
Write-Host "  flat game never showed you." -ForegroundColor White
Write-Host ""
Write-Host "  Your controller is the light gun. Where the laser points is" -ForegroundColor Gray
Write-Host "  where the game registers the hit - at any zoom level." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU NEED YOUR OWN COPY OF THE 1997 PC GAME. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  It is not sold on Steam, GOG or anywhere else, and nothing of" -ForegroundColor Gray
Write-Host "  the game ships with this mod." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Where is the game? ------------------------------------
Write-Step 1 4 "Finding your copy of Virtua Cop 2"
Write-Host ""
Write-Host "  There is no store to ask, so please point at the game" -ForegroundColor White
Write-Host "  yourself: find " -NoNewline -ForegroundColor White
Write-Host "$GAME_EXE" -NoNewline -ForegroundColor Cyan
Write-Host " and DRAG IT INTO THIS WINDOW," -ForegroundColor White
Write-Host "  then press Enter. (You can also paste the full path.)" -ForegroundColor White
Write-Host ""
Write-Host "  It sits in the game's main folder, next to a BIN folder." -ForegroundColor Gray
Write-Host ""

# THE HUB MAY ALREADY KNOW WHERE IT IS (2026-08-20). "Locate Game" on
# the game's page writes the folder into .installed_path right next to
# this script - and asking the user to drag the same exe in again after
# they have just pointed at it is pure friction.
# It is VERIFIED, not trusted: the folder must still exist and still
# hold PPJ2DD.EXE. A moved or deleted install falls straight through to
# the prompt below, so a stale note can never send the installer at the
# wrong folder.
$gameRoot = $null
# TWO FILES CAN HOLD A PATH HERE, and they mean different things:
#   .game_path      - the GAME folder, written by this installer.
#   .installed_path - what the SCAN reads. It ends up pointing at the VR
#                     application folder (that is where VC2VR.exe lives),
#                     but "Locate Game" writes the GAME folder into it.
# So both are read, and whichever actually holds PPJ2DD.EXE wins - the
# file's name decides nothing, its content does.
$recorded = $null
foreach ($cand in @(".game_path", ".installed_path")) {
    if ($recorded) { break }
    try {
        $cf = Join-Path $PSScriptRoot $cand
        if (Test-Path -LiteralPath $cf) {
            $v = (Get-Content -LiteralPath $cf -TotalCount 1 -ErrorAction Stop | Select-Object -First 1)
            if ($v) {
                $v = $v.Trim()
                if ($v -and (Test-Path -LiteralPath "$($v.TrimEnd('\'))\$GAME_EXE")) { $recorded = $v }
            }
        }
    } catch {}
}
if ($recorded -and (Test-Path -LiteralPath "$($recorded.TrimEnd('\'))\$GAME_EXE")) {
    Write-OK "Already located: $recorded"
    Write-Host ""
    Write-Host "   [1] Use this folder" -ForegroundColor White
    Write-Host "   [2] Point at a different copy" -ForegroundColor White
    Write-Host ""
    $useRec = ""
    for ($i = 1; $i -le 20; $i++) {
        $useRec = ("" + (Read-Host "  Enter 1 or 2")).Trim()
        if ($useRec -in @("1","2")) { break }
        Write-Host "  Please answer 1 or 2." -ForegroundColor Yellow
    }
    if ($useRec -eq "1") { $gameRoot = $recorded }
} elseif ($recorded) {
    Write-Warn "The folder the Hub had noted is gone, or no longer holds ${GAME_EXE}"
    Write-Host "  $recorded" -ForegroundColor Gray
    Write-Host "  Please point at the game again." -ForegroundColor White
    Write-Host ""
}

for ($try = 1; ($try -le 10) -and (-not $gameRoot); $try++) {
    $raw = ("" + (Read-Host "  Drop $GAME_EXE here")).Trim()
    if (-not $raw) { continue }
    # A drag-and-drop lands quoted when the path has spaces.
    $raw = $raw.Trim('"').Trim("'").Trim()
    if ($raw -eq "q") { break }

    if (-not (Test-Path -LiteralPath $raw)) {
        Write-Warn "Not found: $raw"
        continue
    }
    $item = Get-Item -LiteralPath $raw -ErrorAction SilentlyContinue
    if ($item -and $item.PSIsContainer) {
        # A folder was dropped - accept it if the exe is inside.
        $cand = "$($item.FullName.TrimEnd('\'))\$GAME_EXE"
        if (Test-Path -LiteralPath $cand) { $item = Get-Item -LiteralPath $cand }
        else { Write-Warn "That folder has no $GAME_EXE in it."; continue }
    }
    if ($item.Name -ne $GAME_EXE) {
        # Not a refusal: a different exe in the right folder still tells
        # us where the game is, so check the folder before giving up.
        $sibling = "$($item.DirectoryName.TrimEnd('\'))\$GAME_EXE"
        if (Test-Path -LiteralPath $sibling) {
            Write-Info "Using $GAME_EXE from the same folder."
            $item = Get-Item -LiteralPath $sibling
        } else {
            Write-Warn "That is $($item.Name), and there is no $GAME_EXE beside it."
            continue
        }
    }
    $gameRoot = $item.DirectoryName
    break
}

if (-not $gameRoot) {
    Write-Fail "No game folder - nothing was installed."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameRoot"

# The BIN folder is what the loader is really after. Say so plainly
# now rather than letting the game fail later with a CD error.
if (-not (Test-Path -LiteralPath "$gameRoot\BIN")) {
    Write-Warn "There is no BIN folder next to $GAME_EXE."
    Write-Host "  The game reads all its data from there. Without it the game" -ForegroundColor White
    Write-Host "  cannot start, with or without this mod." -ForegroundColor White
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- 2. Fetch the mod -----------------------------------------
Write-Step 2 4 "Downloading $MOD_NAME"

$url = $null; $tag = ""; $assetName = ""; $assetSize = 0; $body = ""
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" `
              -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
    # !!! THE AUTHOR ALSO UPLOADS EVERY FILE SEPARATELY beside the
    # package - HGL_VIEW.DLL, VC2VR.exe, the two .ini files and the
    # OpenXR loader are all their own assets. We want the COMPLETE
    # zip, so match VC2VR*.zip and never a loose file.
    $a = @($rel.assets) | Where-Object { $_.name -match '(?i)^VC2VR.*\.zip$' } | Select-Object -First 1
    if (-not $a) { $a = @($rel.assets) | Where-Object { $_.name -match '(?i)\.zip$' -and $_.name -notmatch '(?i)source' } | Select-Object -First 1 }
    if ($a) {
        $url = [string]$a.browser_download_url; $tag = [string]$rel.tag_name
        $assetName = [string]$a.name; $assetSize = [long]$a.size; $body = [string]$rel.body
    }
} catch { Write-Warn "GitHub could not be reached - falling back to the releases page." }
if ($url) { Write-OK "Release: $tag  ($assetName)" } else { $url = $RELEASES }

$tmp = Join-Path $env:TEMP ("vc2vr_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-Path $tmp "VC2VR.zip"

$have = Find-PredownloadedFile -Patterns @("VC2VR-v*.zip", "VC2VR*.zip") -Label "the VC2VR package" `
            -ExpectedName $assetName -ExpectedSize $assetSize
if ($have -and (Test-Path -LiteralPath $have)) {
    $zip = $have
    Write-Info "Using the copy you already downloaded."
} else {
    Invoke-SafeDownload -Urls @($url) -Destination $zip -Label "$MOD_NAME $tag" `
        -ManualUrl $RELEASES `
        -Instructions "Download VC2VR-v<version>.zip from the releases page (the COMPLETE zip, not the single files), save it as '$zip', then choose Retry."
}
if (-not (Test-Path -LiteralPath $zip)) {
    Write-Fail "No package - your game folder was not touched."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# The author publishes the package's sha256 in the release note.
if ($body -and $assetName) {
    $sum = Confirm-ReleaseChecksum -FilePath $zip -AssetName $assetName -ReleaseBody $body
    if ([string]$sum -eq "mismatch") {
        Write-Fail "The download does not match the checksum in the release note - stopping."
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit."
        exit 1
    }
}

$unp = Join-Path $tmp "x"
$st = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $unp -Label "$MOD_NAME"
if ([string]$st -ne "ok" -and [string]$st -ne "manual") {
    Write-Fail "The package could not be unpacked."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
# Resolve the payload root through a file that must be there, so a
# wrapper folder in a future release changes nothing.
$modRoot = $unp
$probe = Get-ChildItem -LiteralPath $unp -Recurse -Filter "HGL_VIEW.DLL" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($probe) { $modRoot = $probe.DirectoryName }
$missing = @()
foreach ($f in ($GAME_SIDE + $VR_SIDE)) {
    if (-not (Test-Path -LiteralPath "$modRoot\$f")) { $missing += $f }
}
if ($missing.Count -gt 0) {
    Write-Fail ("The package is incomplete: " + ($missing -join ", "))
    Write-Host "  That usually means a single file was downloaded instead of" -ForegroundColor White
    Write-Host "  the complete VC2VR zip." -ForegroundColor White
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Package verified."

# ---- 3. Build the PROJECT folder ------------------------------
Write-Step 3 4 "Setting up the PROJECT folder"
Write-Host ""
Write-Host "  The 1997 loader reads its data from one level ABOVE where it" -ForegroundColor Gray
Write-Host "  runs. Started from the game root, it looks OUTSIDE the game" -ForegroundColor Gray
Write-Host "  and fails hunting for a CD. Copying the loose files into a" -ForegroundColor Gray
Write-Host "  PROJECT subfolder puts BIN exactly one level up, where it" -ForegroundColor Gray
Write-Host "  expects it. Your original files stay where they are." -ForegroundColor Gray
Write-Host ""

$projDir = "$($gameRoot.TrimEnd('\'))\$PROJECT"
try { New-Item -ItemType Directory -Path $projDir -Force -ErrorAction Stop | Out-Null }
catch {
    Write-Fail "Could not create $projDir : $($_.Exception.Message)"
    Pause-User "Press Enter to exit."
    exit 1
}

# FILES ONLY, never the folders - BIN and SE must stay in the root.
$copied = 0
foreach ($f in @(Get-ChildItem -LiteralPath $gameRoot -File -ErrorAction SilentlyContinue)) {
    try {
        Copy-Item -LiteralPath $f.FullName -Destination "$projDir\$($f.Name)" -Force -ErrorAction Stop
        $copied++
    } catch { Write-Warn "Could not copy $($f.Name): $($_.Exception.Message)" }
}
Write-OK "$copied game file(s) copied into $PROJECT."

foreach ($f in $GAME_SIDE) {
    Copy-Item -LiteralPath "$modRoot\$f" -Destination "$projDir\$f" -Force
}
Write-OK "Mod renderer placed in $PROJECT."

if (-not (Test-Path -LiteralPath "$projDir\$GAME_EXE")) {
    Write-Fail "$GAME_EXE did not make it into $PROJECT - stopping."
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- 4. The VR half -------------------------------------------
Write-Step 4 4 "Placing the VR application"
try { New-Item -ItemType Directory -Path $VR_ROOT -Force -ErrorAction Stop | Out-Null } catch {}
foreach ($f in $VR_SIDE) {
    Copy-Item -LiteralPath "$modRoot\$f" -Destination "$($VR_ROOT.TrimEnd('\'))\$f" -Force
}
$vrOk = $true
foreach ($f in $VR_SIDE) { if (-not (Test-Path -LiteralPath "$($VR_ROOT.TrimEnd('\'))\$f")) { $vrOk = $false } }
if ($vrOk) {
    Write-OK "VR application: $VR_ROOT"
    Save-InstalledStamp -GameDir @($VR_ROOT, $gameRoot) -Version $tag -HubDir $PSScriptRoot
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $VR_ROOT -Encoding UTF8 -Force } catch {}
    # Remember the GAME folder separately, so a later run does not ask
    # for the exe again. .installed_path cannot carry it - the scan needs
    # that one pointing at the VR application.
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".game_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}

    # ---- ONE LAUNCHER THAT DOES THE WHOLE DANCE -------------------
    # Two executables, in order, from two different folders, and the
    # game MUST run with PROJECT as its working directory. Nobody should
    # have to remember that. This batch file is what "Start in VR" on the
    # game's page runs, and what a desktop shortcut can point at.
    $launchBat = "$($VR_ROOT.TrimEnd('\'))\Play Virtua Cop 2 VR.bat"
    $bat = @"
@echo off
title Virtua Cop 2 VR
color 0B
echo.
rem The Hub's own banner - magenta rules, same as every installer.
powershell -NoProfile -Command "Write-Host ('  ' + '=' * 60) -ForegroundColor Magenta; Write-Host '   VIRTUA COP 2 VR' -ForegroundColor Cyan; Write-Host ('  ' + '=' * 60) -ForegroundColor Magenta"
echo.
echo   Start SteamVR / Virtual Desktop first.
echo.
echo   In the game:
echo.
rem Only these two lines are coloured. "color" would repaint the whole
rem console, so one PowerShell call per line does it properly instead.
powershell -NoProfile -Command "Write-Host '     1.  Press ALT      (twice on a virtual keyboard)' -ForegroundColor Yellow"
powershell -NoProfile -Command "Write-Host '     2.  Click Device  ->  Direct 3D + 3D view   (use the mouse)' -ForegroundColor Yellow"
echo.
echo   VR then starts by itself. Pick your level in the headset.
echo.
pause
cd /d "$projDir"
start "" "$projDir\$GAME_EXE"
timeout /t 15
cd /d "$VR_ROOT"
start "" "$VR_ROOT\VC2VR.exe"
timeout /t 3 >nul
"@
    try {
        Set-Content -LiteralPath $launchBat -Value $bat -Encoding ASCII -Force
        Write-OK "Launcher created: $launchBat"
    } catch { Write-Warn "Could not write the launcher: $($_.Exception.Message)" }

    # ---- Icon + desktop shortcut ----------------------------------
    # A .bat has no icon of its own, so the shortcut needs a real .ico
    # file that STAYS on disk - it is referenced, not embedded. It goes
    # next to the launcher rather than into the game folder, so the
    # user's own game install keeps nothing of ours.
    $icoSrc = Join-Path $PSScriptRoot "VirtuaCop2_VR.ico"
    $icoDst = "$($VR_ROOT.TrimEnd('\'))\VirtuaCop2_VR.ico"
    $icoOk = $false
    try {
        if (Test-Path -LiteralPath $icoSrc) {
            Copy-Item -LiteralPath $icoSrc -Destination $icoDst -Force -ErrorAction Stop
            $icoOk = (Test-Path -LiteralPath $icoDst)
        }
    } catch {}

    Write-Host ""
    Write-Host "  Put a shortcut on your Desktop?" -ForegroundColor White
    Write-Host "  It starts everything - the game and VR - in one click." -ForegroundColor Gray
    Write-Host ""
    $wantLnk = ""
    for ($i = 1; $i -le 20; $i++) {
        $wantLnk = ("" + (Read-Host "  Create it? [y/n]")).Trim().ToLower()
        if ($wantLnk -in @("y","n","yes","no")) { break }
        Write-Host "  Please answer y or n." -ForegroundColor Yellow
    }
    if ($wantLnk -in @("y","yes")) {
        try {
            $lnk = New-DesktopShortcut -LnkPath "$([Environment]::GetFolderPath('Desktop'))\Virtua Cop 2 VR.lnk" `
                       -TargetPath $launchBat -WorkingDir $VR_ROOT `
                       -IconPath $(if ($icoOk) { "$icoDst,0" } else { "" }) `
                       -Description "Virtua Cop 2 VR"
            if ($lnk) { Write-OK "Desktop shortcut created." }
            else { Write-Warn "The shortcut could not be created." }
        } catch { Write-Warn "The shortcut could not be created: $($_.Exception.Message)" }
    }
} else {
    Write-Fail "The VR application did not arrive in $VR_ROOT."
}
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   HOW TO PLAY
  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Press " -NoNewline -ForegroundColor White
Write-Host "Start in VR" -NoNewline -ForegroundColor Cyan
Write-Host " on this game's page in the Hub." -ForegroundColor White
Write-Host ""
Write-Host "  That runs the launcher this installer just wrote, and it does" -ForegroundColor Gray
Write-Host "  the whole sequence for you - the game from the right folder," -ForegroundColor Gray
Write-Host "  then the VR half once you are in a level. You never have to" -ForegroundColor Gray
Write-Host "  find either program yourself." -ForegroundColor Gray
Write-Host ""
Write-Host "  ONE THING ONLY YOU CAN DO, the first time: " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  When the game starts it takes NO keyboard and NO mouse input." -ForegroundColor White
Write-Host "  It just sits in the main menu." -ForegroundColor White
Write-Host ""
Write-Host "  Press " -NoNewline -ForegroundColor White
Write-Host "ALT" -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " to reach the pause screen - only from there can" -ForegroundColor White
Write-Host "  anything be set. On a virtual screen (Virtual Desktop and" -ForegroundColor White
Write-Host "  the like) press ALT TWICE on the virtual keyboard." -ForegroundColor White
Write-Host ""
Write-Host "  The mouse works from there: click Device, then pick" -ForegroundColor White
Write-Host "    Direct 3D + 3D view" -ForegroundColor Black -BackgroundColor Cyan
Write-Host "  - THAT entry is the mod. It is remembered afterwards." -ForegroundColor White
Write-Host ""
Write-Host "  The VR half then starts BY ITSELF after 15 seconds, and you" -ForegroundColor Gray
Write-Host "  can pick your level from inside the headset." -ForegroundColor Gray
Write-Host ""
Write-Host "  >>> Point. Shoot. Reload with a flick. Just like the cabinet." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
exit 0
