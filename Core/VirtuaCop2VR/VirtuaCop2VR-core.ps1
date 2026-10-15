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

# The two roots follow the publisher's v1.0-beta package and launcher.
$GAME_SIDE  = @("HGL_VIEW.DLL", "HGL_VIEW.ini")
$VR_SIDE    = @("VC2VR.exe", "VC2VR.ini", "openxr_loader.dll", "gun.obj", "gun.mtl", "gun.bmp")

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
$gameRoot = Get-PCVRRememberedGameFolder -ProbeFiles @($GAME_EXE)
if ($gameRoot) { Write-OK "Using remembered Virtua Cop 2 game folder: $gameRoot" }
# TWO FILES CAN HOLD A PATH HERE, and they mean different things:
#   .game_path      - the GAME folder, written by this installer.
#   .installed_path - what the SCAN reads. It ends up pointing at the VR
#                     application folder (that is where VC2VR.exe lives),
#                     but "Locate Game" writes the GAME folder into it.
# So both are read, and whichever actually holds PPJ2DD.EXE wins - the
# file's name decides nothing, its content does.
$recorded = $gameRoot
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

$testArchive = if ($env:PCVR_HUB_TEST_MODE -eq '1') { ('' + $env:PCVR_VC2_TEST_ARCHIVE).Trim() } else { '' }
if ($testArchive) {
    if (-not (Test-Path -LiteralPath $testArchive -PathType Leaf)) { throw 'The isolated VC2VR test archive is missing.' }
    $release = [pscustomobject]@{ Tag='v1.0-beta'; Url=[IO.Path]::GetFullPath($testArchive); AssetName='VC2VR-v1.0-beta_2.zip'; PageUrl=$RELEASES; Local=$true }
} else {
    $asset = Resolve-GitHubReleaseAsset -Repo $REPO -IncludePrerelease $true `
        -AssetPatterns @('(?i)^VC2VR[-_.].*\.zip$') -SkipReleasesWithoutMatchingAsset `
        -FallbackUrl 'https://github.com/NeuralF/Rea-Virtua-Cop-2-VR/releases/download/v1.0-beta/VC2VR-v1.0-beta_2.zip' `
        -FallbackTag 'v1.0-beta' -FallbackAssetName 'VC2VR-v1.0-beta_2.zip'
    $release = [pscustomobject]@{ Tag=[string]$asset.Tag; Url=[string]$asset.Url; AssetName=[string]$asset.AssetName; PageUrl=[string]$asset.PageUrl; Local=$false; NeedsManual=([string]$asset.Url -eq [string]$asset.PageUrl) }
}
Write-OK "Release: $($release.Tag)  ($($release.AssetName))"

$tmp = Join-Path $env:TEMP ("vc2vr_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-Path $tmp "VC2VR.zip"

if ($release.Local) {
    Copy-Item -LiteralPath $release.Url -Destination $zip -Force -ErrorAction Stop
} elseif ($release.NeedsManual) {
    Write-Warn "The current publisher release needs a manually selected ZIP."
    $got = Invoke-InstallerFallback -Action 'VC2VR download' -Url ([string]$release.PageUrl) `
        -DestFile $zip -RetryCheck { Test-Path -LiteralPath $zip -PathType Leaf } -AllowSkip:$false
    if ([string]$got -notin @('manual','retry')) { throw 'The VC2VR ZIP was not selected.' }
} else {
    $got = Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $zip -Label "$MOD_NAME $($release.Tag)" `
        -ManualUrl ([string]$release.PageUrl) -ExpectedReleaseTag ([string]$release.Tag) -AllowSkip $false
    if (-not ($got -eq $true -or [string]$got -in @('retry','manual'))) { throw 'The VC2VR ZIP was not downloaded.' }
}
if (-not (Test-Path -LiteralPath $zip)) {
    Write-Fail "No package - your game folder was not touched."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
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
    if ($f -eq 'HGL_VIEW.ini' -and (Test-Path -LiteralPath "$projDir\$f" -PathType Leaf)) { continue }
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
    if ($f -eq 'VC2VR.ini' -and (Test-Path -LiteralPath "$VR_ROOT\$f" -PathType Leaf)) { continue }
    Copy-Item -LiteralPath "$modRoot\$f" -Destination "$($VR_ROOT.TrimEnd('\'))\$f" -Force
}
$vrIniPath = Join-Path $VR_ROOT 'VC2VR.ini'
$gameToLaunch = Join-Path $projDir $GAME_EXE
if (Test-Path -LiteralPath $vrIniPath -PathType Leaf) {
    $vrIni = [IO.File]::ReadAllText($vrIniPath)
    if ($vrIni -match '(?im)^\s*gameexe\s*=') {
        $vrIni = [regex]::Replace($vrIni, '(?im)^[^\S\r\n]*gameexe[^\S\r\n]*=.*$', [System.Text.RegularExpressions.MatchEvaluator]{ param($match) "gameexe = $gameToLaunch" })
    } elseif ($vrIni -match '(?im)^\s*\[vr\]\s*$') {
        $section = [regex]::Match($vrIni, '(?im)^\s*\[vr\][^\r\n]*')
        $vrIni = $vrIni.Insert($section.Index + $section.Length, "`r`ngameexe = $gameToLaunch")
    } else { throw 'The publisher VC2VR.ini has no [vr] section.' }
    [IO.File]::WriteAllText($vrIniPath, $vrIni, [Text.UTF8Encoding]::new($false))
}
$vrOk = $true
foreach ($f in $VR_SIDE) { if (-not (Test-Path -LiteralPath "$($VR_ROOT.TrimEnd('\'))\$f")) { $vrOk = $false } }
if ($vrOk) {
    Write-OK "VR application: $VR_ROOT"
    # The publisher executable now launches and configures the game itself.
    # The explicit gameexe path connects our separate VR and game folders.
    $launchBat = "$($VR_ROOT.TrimEnd('\'))\Play Virtua Cop 2 VR.bat"
    $bat = @"
@echo off
title Virtua Cop 2 VR
cd /d "$VR_ROOT"
start "" "$VR_ROOT\VC2VR.exe"
"@
    try {
        Set-Content -LiteralPath $launchBat -Value $bat -Encoding ASCII -Force
        Write-OK "Launcher created: $launchBat"
    } catch { Write-Warn "Could not write the launcher: $($_.Exception.Message)" }
    if (-not (Test-Path -LiteralPath $launchBat -PathType Leaf)) { throw 'The VC2VR launcher could not be created.' }
    Set-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_version') -Value ([string]$release.Tag) -Encoding UTF8 -Force -ErrorAction Stop
    Set-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Value $VR_ROOT -Encoding UTF8 -Force -ErrorAction Stop
    Set-Content -LiteralPath (Join-Path $PSScriptRoot '.game_path') -Value $gameRoot -Encoding UTF8 -Force -ErrorAction Stop
    Save-InstalledStamp -GameDir @($VR_ROOT, $gameRoot) -Version ([string]$release.Tag) -HubDir $PSScriptRoot

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
    throw 'Required VC2VR files are missing after installation.'
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
Write-Host "  That opens VC2VR.exe. It launches the game from the PROJECT" -ForegroundColor Gray
Write-Host "  folder and selects the VR renderer automatically." -ForegroundColor Gray
Write-Host ""
Write-Host "  If the headset waits for the game, check the gameexe path in" -ForegroundColor White
Write-Host "  VC2VR.ini and the original game's BIN folder." -ForegroundColor White
Write-Host ""
Write-Host "  >>> Point. Shoot. Reload with a flick. Just like the cabinet." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
exit 0
