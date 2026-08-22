# ============================================================
#  Pathfinder: Kingmaker VR - VRMaker by PinkMilkProductions
# ------------------------------------------------------------
#  WE DO NOT USE THE RAI MANAGER. The release is a package for
#  Raicuparta's Rai Manager (RaiManager.exe, 37 MB) - the mod
#  content sits inside it as RaiManager\Mod\. We copy only that
#  content and leave the manager entirely alone.
#
#  TWO PARTS BELONG IN THE GAME, and the archive says where:
#    Mod\CopyToGame\*  -> content DIRECTLY into the game folder
#                         (winhttp.dll, doorstop_config.ini,
#                          Kingmaker_Data\..., VRMakerAssets\...)
#    Mod\BepInEx\      -> as BepInEx\ into the game folder
#
#  !!! AND THE POINT WITHOUT WHICH NOTHING WORKS !!!
#  doorstop_config.ini contains a HARD-CODED PATH FROM THE AUTHOR'S
#  OWN MACHINE:
#     targetAssembly=C:\VRProjects\VRMaker\RaiManager\Mod\BepInEx\...
#  The Rai Manager rewrites it during install. If WE do not, Doorstop
#  looks for a folder that exists on no other machine - BepInEx never
#  loads, the mod does nothing, and there is NO error message. So we
#  set the value to the standard path relative to the game.
#
#  THE MOD RUNS ON SteamVR (openvr_api.dll, SteamVR.dll,
#  actions.json), not OpenXR - so SteamVR has to be running.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Pathfinder Kingmaker VR Installer"
$ErrorActionPreference = "Stop"

# EVERY installer brings its own console helpers.
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

$GAME_NAME   = "Pathfinder: Kingmaker"
$APP_ID      = "640820"
$GAME_EXE    = "Kingmaker.exe"
$MOD_NAME    = "VRMaker"
$MOD_AUTHOR  = "PinkMilkProductions"
$REPO        = "PinkMilkProductions/VRMaker"
$RELEASES    = "https://github.com/$REPO/releases"
$MOD_PROBE   = "BepInEx\plugins\VRMaker.dll"

# ---- Header ---------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Pathfinder: Kingmaker VR Mod Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  The whole campaign in VR, played from above like a table:" -ForegroundColor White
Write-Host "  grab the world with both grips and pull, rotate and scale it" -ForegroundColor White
Write-Host "  to move around. Point a controller where you want to go or" -ForegroundColor White
Write-Host "  who to attack - it works like a laser pointer for the mouse." -ForegroundColor White
Write-Host "  There is also a first-person mode you hold a button for." -ForegroundColor White
Write-Host ""
Write-Host "  This mod runs on " -NoNewline -ForegroundColor White
Write-Host " SteamVR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " - start it before the game." -ForegroundColor White
Write-Host "  Controls are built for Oculus Touch (Quest 2 / 3) and the" -ForegroundColor Gray
Write-Host "  Valve Index. Other controllers can be rebound in SteamVR's" -ForegroundColor Gray
Write-Host "  own binding interface." -ForegroundColor Gray
Write-Host ""
Write-Host "  The author calls it 'almost playable start to finish' - about" -ForegroundColor Yellow
Write-Host "  95% of the way to a 1.0. Kingdom management is the known gap," -ForegroundColor White
Write-Host "  and the frame rate dips in your own town hub." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Locate the game ---------------------------------------
Write-Step 1 5 "Locating $GAME_NAME"
$gameDir = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("Pathfinder Kingmaker") -ProbeExe $GAME_EXE
if (-not $gameDir) {
    # Per his manifest the author supports Steam AND GOG.
    foreach ($c in @("C:\GOG Games\Pathfinder Kingmaker",
                     "C:\Program Files (x86)\GOG Galaxy\Games\Pathfinder Kingmaker",
                     "C:\Program Files\Epic Games\PathfinderKingmaker",
                     "C:\Program Files (x86)\Epic Games\PathfinderKingmaker")) {
        if (Test-Path -LiteralPath (Join-Path $c $GAME_EXE)) { $gameDir = $c; break }
    }
}
if (-not $gameDir) {
    Write-Warn "Could not find the game automatically."
    Write-Host "  Point me at the folder that holds $GAME_EXE, for example:" -ForegroundColor White
    Write-Host "     C:\Program Files (x86)\Steam\steamapps\common\Pathfinder Kingmaker" -ForegroundColor Gray
    $gameDir = (Read-Host "  Game folder").Trim().Trim('"')
}
if (-not $gameDir -or -not (Test-Path -LiteralPath (Join-Path $gameDir $GAME_EXE))) {
    Write-Fail "No $GAME_EXE in that folder - stopping rather than guessing."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameDir"

# Probe write access quietly - the announcement comes where it applies.
$needsAdmin = $false
try {
    $probe = Join-Path $gameDir ".pcvrhub_write_probe"
    Set-Content -LiteralPath $probe -Value "ok" -ErrorAction Stop
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
} catch { $needsAdmin = $true }

# ---- 2. The game's graphics options, in flat mode -------------
# TESTED ON A REAL MACHINE: without these four values the image in VR
# is unusable - blurred text, black single-eye surfaces over the
# buildings, everything so dark that only outlines are visible,
# performance on the floor. The cause is screen-space effects:
# computed from the depth buffer of ONE image and laid over BOTH eyes.
#
# !!! HOW TO GET THIS GAME FLAT - AND HOW NOT TO !!!
# Renaming winhttp.dll is NOT enough. The bundled VRPatcher rewrites
# Kingmaker_Data\globalgamemanagers during install and puts "OpenVR"
# into enabledVRDevices. That is Unity's own VR switch and it takes
# effect at startup, BEFORE any plugin loads. With BepInEx unhooked
# the game therefore still starts in VR mode, only nobody is driving
# it - the result is a completely blue image instead of the main menu.
# THE PATCHER DOES LEAVE A BACKUP, though: globalgamemanagers.bak,
# evidenced by its own strings "Created backup in '" and "Backup
# already exists.". We restore that, let the user change the settings,
# and then put the patched state back.
Write-Step 2 5 "The game's own graphics options - do this first, flat"

$gmDir  = Join-Path $gameDir "Kingmaker_Data"
$gmFile = Join-Path $gmDir "globalgamemanagers"
$gmBak  = Join-Path $gmDir "globalgamemanagers.bak"
$gmPark = Join-Path $gmDir "globalgamemanagers.vr"
$gmSwapped = $false
if ((Test-Path -LiteralPath $gmFile) -and (Test-Path -LiteralPath $gmBak)) {
    try {
        Copy-Item -LiteralPath $gmFile -Destination $gmPark -Force -ErrorAction Stop
        Copy-Item -LiteralPath $gmBak  -Destination $gmFile -Force -ErrorAction Stop
        $gmSwapped = $true
        Write-Info "VR is switched off for a moment so the game starts flat."
    } catch { Write-Warn "Could not put the original globalgamemanagers back: $($_.Exception.Message)" }
}

Write-Host ""
Write-Host "  The game opens now, WITHOUT VR. Go to " -NoNewline -ForegroundColor White
Write-Host " Settings > Graphics " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " and set:" -ForegroundColor White
Write-Host ""
Write-Host "        V-Sync            off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        Bloom             off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        Depth of Field    off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        HBAO              low " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  These are screen-space effects: the game works them out from" -ForegroundColor White
Write-Host "  ONE image and lays the result over BOTH eyes. Left on, you get" -ForegroundColor White
Write-Host "  blurred text, black shadows stuck to the buildings, a picture" -ForegroundColor White
Write-Host "  so dark you only see outlines - and the frame rate collapses." -ForegroundColor White
Write-Host ""
Write-Host "  Then CLOSE the game and press Enter." -ForegroundColor White
Write-Host ""
if (Read-YesNo "  Open the game now?") {
    try { Start-Process -FilePath (Join-Path $gameDir $GAME_EXE) -WorkingDirectory $gameDir }
    catch { Write-Warn "Could not start it - open it from Steam instead." }
    Pause-User "Game closed? Press Enter to continue..." | Out-Null
} else {
    Write-Info "Skipped - but those four still have to be set."
}

# Restore the patched state so VR is active again.
if ($gmSwapped) {
    try {
        Copy-Item -LiteralPath $gmPark -Destination $gmFile -Force -ErrorAction Stop
        Remove-Item -LiteralPath $gmPark -Force -ErrorAction SilentlyContinue
        Write-OK "VR is switched back on."
    } catch { Write-Warn "Could not restore the VR file - run this installer again to repair it." }
}

# ---- 3. Download ----------------------------------------------
Write-Step 3 5 "Downloading $MOD_NAME"
Write-Host "  About 21 MB. The download is a Rai Manager package - we take" -ForegroundColor Gray
Write-Host "  only the mod out of it and leave the manager alone." -ForegroundColor Gray

$tmp = Join-Path $env:TEMP ("vrmaker_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-Path $tmp "VRMaker.zip"

$url = $null; $tag = "latest"
try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" `
               -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
    if (Test-IsPayloadRelease -Release $rel) {
        $pick = Select-PayloadAsset -Assets $rel.assets -PlatformPattern '(?i)VRMaker' -MinBytes 1000000
        if ($pick -and $pick.browser_download_url) {
            $url = [string]$pick.browser_download_url
            $tag = [string]$rel.tag_name
        }
    }
    if ($url) { Write-OK "Release: $tag" }
} catch { Write-Warn "GitHub could not be reached - trying the releases page." }

$have = Find-PredownloadedFile -Patterns @("VRMaker_Installer*.zip", "*VRMaker*.zip") -Label "the VRMaker release"
if ($have -and (Test-Path -LiteralPath $have)) {
    $zip = $have
} else {
    if (-not $url) { $url = "https://github.com/$REPO/releases/latest/download/VRMaker_Installer_20251301.zip" }
    Invoke-SafeDownload -Urls @($url) -Destination $zip -Label "$MOD_NAME $tag" `
        -ManualUrl $RELEASES `
        -Instructions "Download the VRMaker installer zip from the releases page, save it as '$zip', then choose Retry."
}
if (-not (Test-Path -LiteralPath $zip)) {
    Write-Fail "No archive - nothing was changed."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- 3. Just the mod, without the manager ---------------------
Write-Step 4 5 "Installing the mod (without the Rai Manager)"

$ex = Join-Path $tmp "x"
New-Item -ItemType Directory -Path $ex -Force | Out-Null
[void](Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $ex -Label $MOD_NAME)

# Search the whole tree for the two source folders - today the
# wrapper is called RaiManager\Mod, and that can change.
$copyToGame = Get-ChildItem -LiteralPath $ex -Recurse -Directory -Force -ErrorAction SilentlyContinue |
              Where-Object { $_.Name -ieq "CopyToGame" } | Select-Object -First 1
$bepinSrc   = Get-ChildItem -LiteralPath $ex -Recurse -Directory -Force -ErrorAction SilentlyContinue |
              Where-Object { $_.Name -ieq "BepInEx" -and $_.Parent.Name -ieq "Mod" } | Select-Object -First 1
if (-not $copyToGame -or -not $bepinSrc) {
    Write-Fail "The archive does not have the expected Mod\CopyToGame and Mod\BepInEx folders."
    Write-Host "  Nothing was changed. The mod's layout has probably moved." -ForegroundColor White
    try { if ($zip -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

if ($needsAdmin) {
    Pause-User "Press Enter to copy the mod into the game folder - UAC required..." | Out-Null
}

# Do NOT carry the author's runtime leftovers along: his log, his
# Cache folders and the empty marker files.
$skip = @("LogOutput.log", "BEPINEX_FILES", "FILES_THAT_GET_COPIED_ON_INSTALL")
function Copy-Tree {
    param([string]$From, [string]$To)
    $n = 0
    foreach ($f in @(Get-ChildItem -LiteralPath $From -Recurse -File -Force -ErrorAction SilentlyContinue)) {
        if ($skip -contains $f.Name) { continue }
        $rel = $f.FullName.Substring($From.Length).TrimStart('\','/')
        if ($rel -match '(^|\\)cache(\\|$)') { continue }
        $dst = Join-Path $To $rel
        $dir = Split-Path $dst -Parent
        try {
            if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null }
            Copy-Item -LiteralPath $f.FullName -Destination $dst -Force -ErrorAction Stop
            $n++
        } catch { }
    }
    return $n
}

$a = Copy-Tree -From $copyToGame.FullName -To $gameDir
$b = Copy-Tree -From $bepinSrc.FullName   -To (Join-Path $gameDir "BepInEx")
Write-OK "$a game files, $b BepInEx files copied."

# If the copy failed on permissions, retry it elevated.
if (-not (Test-Path -LiteralPath (Join-Path $gameDir $MOD_PROBE))) {
    Write-Warn "Copying into that folder needs administrator rights. Asking for them ..."
    $ps = "Copy-Item -LiteralPath '$($copyToGame.FullName)\*' -Destination '$gameDir' -Recurse -Force; " +
          "Copy-Item -LiteralPath '$($bepinSrc.FullName)' -Destination '$gameDir' -Recurse -Force"
    try { Start-Process powershell -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-Command",$ps) -Verb RunAs -Wait -ErrorAction Stop }
    catch { Write-Warn "The elevated copy was declined or failed." }
}

# !!! THE DECISIVE STEP: REPLACE THE AUTHOR'S HARD-CODED PATH !!!
# Without it BepInEx never loads and the mod does nothing - silently.
$doorstop = Join-Path $gameDir "doorstop_config.ini"
if (Test-Path -LiteralPath $doorstop) {
    try {
        $lines = @(Get-Content -LiteralPath $doorstop -ErrorAction Stop)
        $fixed = @($lines | ForEach-Object {
            if ($_ -match '^\s*targetAssembly\s*=') { 'targetAssembly=BepInEx\core\BepInEx.Preloader.dll' } else { $_ }
        })
        Set-Content -LiteralPath $doorstop -Value $fixed -Encoding ASCII -ErrorAction Stop
        Write-OK "doorstop_config.ini now points at this game's own BepInEx."
    } catch { Write-Warn "Could not rewrite doorstop_config.ini: $($_.Exception.Message)" }
} else {
    Write-Warn "doorstop_config.ini did not arrive - the mod will not load."
}

$missing = @()
foreach ($f in @($MOD_PROBE, "winhttp.dll", "doorstop_config.ini",
                 "BepInEx\core\BepInEx.Preloader.dll", "BepInEx\patchers\VRPatcher.dll")) {
    if (-not (Test-Path -LiteralPath (Join-Path $gameDir $f))) { $missing += $f }
}
try { if ($zip -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}

if ($missing.Count -gt 0) {
    Write-Fail "These did not arrive:"
    foreach ($m in $missing) { Write-Host "   $m" -ForegroundColor Yellow }
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Mod is in place."

# Marker for the Hub - into the INSTALLER folder, not the game.
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $tag -Encoding UTF8 -Force } catch {}

# ---- 4. Playing -----------------------------------------------
Write-Step 5 5 "Playing"
Write-Host ""
Write-Host "  START STEAMVR FIRST, then launch the game as usual." -ForegroundColor Yellow
Write-Host ""
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " OCULUS TOUCH CONTROLS" -ForegroundColor Cyan
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "   Right A        interact" -ForegroundColor White
Write-Host "   Left A / X     pause  (hold: first-person mode)" -ForegroundColor White
Write-Host "   Left Y         abilities bar  (hold: escape menu)" -ForegroundColor White
Write-Host "   Left trigger   party member select" -ForegroundColor White
Write-Host "   Right trigger  in-game menus (stats, equipment, journal)" -ForegroundColor White
Write-Host "   Both grips     hold and move your hands to pull, rotate and" -ForegroundColor White
Write-Host "                  scale the world - like Demeo" -ForegroundColor White
Write-Host "   Left stick     move  |  Right stick  turn (first-person)" -ForegroundColor White
Write-Host ""
Write-Host "  In combat, point at where you want to go or who to attack." -ForegroundColor Gray
Write-Host "  Your controller is a laser pointer for the mouse." -ForegroundColor Gray
Write-Host ""
Write-Host "  First-person movement is plain continuous walking - there are" -ForegroundColor Gray
Write-Host "  no comfort options yet, and menus or loading screens can be" -ForegroundColor Gray
Write-Host "  janky. Worth knowing if your VR legs are new." -ForegroundColor Gray
Write-Host ""
Write-Host "  Your kingdom can wait. The dice cannot." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
