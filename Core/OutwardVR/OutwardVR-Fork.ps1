# =============================================================
#  Outward VR - CompoundVR fork (current Mono build)
# =============================================================
# THE NEW ONE. cybensis built the original OutwardVR and stopped at
# v0.9.2; that build only runs on an old Definitive Edition, which is
# why the other half of this tile downloads a pinned Steam depot.
#
# The CompoundVR fork carries on from there and runs on the current
# default-mono build. The actual download is BepInEx 5.4.21/Mono and
# cannot load on Steam's default IL2CPP branch. It replaces the old
# full-body rig with real hands and held weapons, adds snap turning and
# tightens the melee response.
#
# !!! THE TWO SHARE A FILE NAME. Both ship BepInEx\plugins\OutwardVR.dll,
# so that file can never tell them apart. Only the fork ships
# vrgloves.bundle - read from both archives, not guessed - and that is
# what the Hub uses as this mod's marker.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME     = "Outward VR"
$MOD_AUTHOR   = "CompoundVR"
$MOD_URL      = "https://compoundvr.com/mods/outward-vr-mod.zip"
$MOD_PAGE     = "https://compoundvr.com/games/outward/"
$STEAM_APPID  = "794260"
$STEAM_FOLDER = "Outward"
$GAME_SUBDIR  = "Outward_Defed"
$GAME_EXE     = "Outward Definitive Edition.exe"
$GAME_DATA    = "Outward Definitive Edition_Data"
# The marker: only the fork ships this.
$MOD_MARKER   = "BepInEx\plugins\vrgloves.bundle"
$MOD_PLUGIN   = "BepInEx\plugins\OutwardVR.dll"
$LAUNCH_FORK  = "Outward VR (CompoundVR).bat"
$VRLAUNCH_SUB = "VRLaunch"

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Write-Do   { param($m) Write-Host "  [->] $m" -ForegroundColor Cyan }
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  [$n/$t] $x  " -ForegroundColor Black -BackgroundColor Cyan; Write-Host "" }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-OutwardMonoBuild {
    param([string]$GameDir)
    if (-not $GameDir) { return $false }
    return (Test-Path -LiteralPath (Join-PathLexical $GameDir "Outward Definitive Edition_Data\Managed\Assembly-CSharp.dll") -PathType Leaf)
}

# ---- Find the game -------------------------------------------
function Get-OutwardFolder {
    $p = $null
    if (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue) {
        try { $p = Find-SteamGameFolder -AppId $STEAM_APPID -SteamFolderNames @($STEAM_FOLDER) -ProbeExe "$GAME_SUBDIR\$GAME_EXE" } catch {}
    }
    # !!! THERE IS NO Find-GogGameFolder IN THIS HUB. GOG installs are
    # found through the catalog's FallbackPaths ("GOG:<folder>") and, for
    # the installer itself, by probing the usual GOG roots directly.
    if (-not $p) {
        # GOG and Epic both just drop the game in a folder - the mod is a
        # BepInEx drop-in and does not care which store sold it.
        foreach ($root in @("C:\GOG Games", "D:\GOG Games",
                            "C:\Program Files (x86)\GOG Galaxy\Games",
                            "C:\Program Files\GOG Galaxy\Games",
                            "C:\Program Files\Epic Games",
                            "C:\Program Files (x86)\Epic Games",
                            "D:\Epic Games", "E:\Epic Games")) {
            foreach ($folder in @("Outward", "Outward Definitive Edition")) {
                $cand = Join-PathLexical (Join-PathLexical $root $folder) ""
                $cand = $cand.TrimEnd([char[]]"\/")
                if (Test-Path -LiteralPath (Join-PathLexical $cand "$GAME_SUBDIR\$GAME_EXE")) { $p = $cand; break }
                if (Test-Path -LiteralPath (Join-PathLexical $cand $GAME_EXE)) { $p = $cand; break }
            }
            if ($p) { break }
        }
    }
    if (-not $p) {
        try { $p = Get-GameFolderInteractive -GameName "Outward Definitive Edition" -ExeName $GAME_EXE } catch {}
    }
    return $p
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Outward VR  -  CompoundVR fork" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Full 6DOF motion controls on the current Mono game build." -ForegroundColor White
Write-Host "  Real hands and held weapons instead of the old full-body rig," -ForegroundColor White
Write-Host "  snap turning, and a much quicker melee response." -ForegroundColor White
Write-Host ""
Write-Host "  No old depot download: Steam must use the current default-mono" -ForegroundColor Gray
Write-Host "  branch because this package contains BepInEx 5 for Mono." -ForegroundColor Gray
Write-Host ""
Show-AntivirusNotice

# ---- 1. Game -------------------------------------------------
Write-Step 1 3 "Finding Outward"

$gameRoot = Get-OutwardFolder
if (-not $gameRoot) {
    Write-Fail "Could not find Outward: Definitive Edition."
    Pause-User "Press Enter to exit."
    exit 1
}
$gameDir = Join-PathLexical $gameRoot $GAME_SUBDIR
if (-not (Test-Path -LiteralPath (Join-PathLexical $gameDir $GAME_EXE))) {
    # Some installs have the exe directly in the root.
    if (Test-Path -LiteralPath (Join-PathLexical $gameRoot $GAME_EXE)) { $gameDir = $gameRoot }
    else {
        Write-Fail "No '$GAME_EXE' under $gameRoot"
        Pause-User "Press Enter to exit."
        exit 1
    }
}
Write-OK "Game folder: $gameDir"

# The downloaded fork is objectively a BepInEx 5 Mono package. On
# IL2CPP its files can sit beside the EXE but Doorstop cannot load the
# managed game assemblies, producing a flat launch and no BepInEx log.
# Refuse that false-success state before touching the game.
if (-not (Test-OutwardMonoBuild -GameDir $gameDir)) {
    Write-Host ""
    Write-Fail "This Outward installation is the IL2CPP build; the VR mod cannot load in it."
    Write-Host ""
    Write-Host "  In Steam: Outward -> Properties -> Betas" -ForegroundColor White
    Write-Host "  Select: default-mono - Public default branch (mono)" -ForegroundColor Cyan
    Write-Host "  Wait for Steam to finish, then run this installer again." -ForegroundColor White
    Write-Host ""
    Write-Host "  The Mono branch contains the current game content; it changes" -ForegroundColor Gray
    Write-Host "  the scripting backend required by BepInEx 5." -ForegroundColor Gray
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Mono build verified (Assembly-CSharp.dll found)."

# !!! REFUSE TO OVERWRITE THE OLD MOD SILENTLY. Both write the same
# plugin file, so installing on top would leave a mixed install that
# looks fine and is not.
$oldHere = (Test-Path -LiteralPath (Join-PathLexical $gameDir $MOD_PLUGIN)) -and
           -not (Test-Path -LiteralPath (Join-PathLexical $gameDir $MOD_MARKER))
if ($oldHere) {
    Write-Host ""
    Write-Host "  THE ORIGINAL OutwardVR IS INSTALLED HERE. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Write-Host ""
    Write-Host "  Found BepInEx\plugins\OutwardVR.dll without the fork's" -ForegroundColor White
    Write-Host "  vrgloves.bundle - that is cybensis's original build." -ForegroundColor White
    Write-Host ""
    Write-Host "  Both mods use the same plugin file name, so the fork would" -ForegroundColor Gray
    Write-Host "  overwrite it. The original belongs on the pinned depot copy," -ForegroundColor Gray
    Write-Host "  not on your current game." -ForegroundColor Gray
    Write-Host ""
    $go = ""
    for ($k = 1; $k -le 20; $k++) {
        $go = ("" + (Read-Host "  Replace it with the fork? [y/n]")).Trim().ToLower()
        if ($go -in @("y","n","yes","no")) { break }
        Write-Host "  Please answer y or n." -ForegroundColor Yellow
    }
    if ($go -notin @("y","yes")) {
        Write-Info "Nothing was changed."
        Pause-User "Press Enter to exit."
        exit 0
    }
}

# ---- 2. Download ---------------------------------------------
Write-Step 2 3 "Getting the fork"

$tmp = Join-PathLexical $env:TEMP ("OutwardVR_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-PathLexical $tmp "outward-vr-mod.zip"

# Address is a literal, never assembled - hub rule after the scanner
# false positive.
$dl = Invoke-DownloadOrFallback -Url $MOD_URL -Destination $zip -Label "$MOD_NAME (CompoundVR fork)" -ManualUrl $MOD_URL
if (-not $dl) {
    Write-Fail "Could not get the mod."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Archive ready."

# ---- 3. Install ----------------------------------------------
Write-Step 3 3 "Installing into the game"

$ex = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $tmp -Label $MOD_NAME
if ([string]$ex -eq "quit") {
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# The archive nests everything under OutwardVR-<version>\.
$probe = Get-ChildItem -LiteralPath $tmp -Filter "vrgloves.bundle" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $probe) {
    Write-Fail "vrgloves.bundle was not in that archive - wrong download?"
    Write-Info "Expected the fork from $MOD_PAGE"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
# .../BepInEx/plugins/vrgloves.bundle -> up three levels is the payload root
$srcRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $probe.FullName))

try {
    Copy-Item -Path (Join-PathLexical $srcRoot "*") -Destination $gameDir -Recurse -Force -ErrorAction Stop
} catch {
    Write-Fail "Could not copy the mod: $($_.Exception.Message)"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

$markerPath = Join-PathLexical $gameDir $MOD_MARKER
if (-not (Test-Path -LiteralPath $markerPath)) {
    Write-Fail "vrgloves.bundle did not arrive in $gameDir"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Mod files in place."

[void](Confirm-PlacedFilesSurvive `
    -Paths @($markerPath, (Join-PathLexical $gameDir $MOD_PLUGIN)) `
    -GameDir $gameRoot `
    -ArchivePath $zip)

# ---- Launcher ------------------------------------------------
# !!! ONE LAUNCHER PER MOD, AND ONLY WHILE THE MOD IS REALLY THERE.
# A shared launcher makes the two-mod split impossible, and a stale one
# makes the tile claim a mod that is gone.
$launchFolder = if ($gameDir -ieq $gameRoot) { "%~dp0.." } else { "%~dp0..\$GAME_SUBDIR" }
$batBody = "@echo off`r`nsetlocal`r`nrem Outward VR - CompoundVR fork (current Mono build)`r`ncd /d `"$launchFolder`"`r`nif not exist `"$GAME_DATA\Managed\Assembly-CSharp.dll`" (`r`n  echo [ERROR] Outward is not on Steam's default-mono branch.`r`n  echo Select default-mono under Outward - Properties - Betas, then reinstall the VR mod.`r`n  pause`r`n  exit /b 1`r`n)`r`nstart `"`" `"$GAME_EXE`"`r`n"
try {
    $lDir = Join-PathLexical $gameRoot $VRLAUNCH_SUB
    if (-not (Test-Path -LiteralPath $lDir)) { New-Item -ItemType Directory -Path $lDir -Force | Out-Null }
    Set-Content -LiteralPath (Join-PathLexical $lDir $LAUNCH_FORK) -Value $batBody -Encoding ASCII -Force
    Write-OK "Registered with the Hub."
} catch { Write-Warn "Could not write the launcher: $($_.Exception.Message)" }

try {
    Set-Content -LiteralPath (Join-PathLexical $PSScriptRoot ".installed_path") -Value $gameRoot -Encoding UTF8 -Force
    Set-Content -LiteralPath (Join-PathLexical $PSScriptRoot ".installed_path_current") -Value $gameRoot -Encoding UTF8 -Force
} catch {}
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Write-Host ""
Write-Host "  IN THE HEADSET " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host "   - Your arm swings the weapon; hold it out in front to block." -ForegroundColor White
Write-Host "   - Snap turning is on by default. Head-bob is off." -ForegroundColor White
Write-Host "   - A gamepad still works when your arms need a break." -ForegroundColor Gray
Write-Host ""
Write-Host "  Settings live in $GAME_SUBDIR\BepInEx\config." -ForegroundColor Gray
Write-Host ""
Write-OK "$MOD_NAME (CompoundVR fork) installed."
Write-Host ""
Pause-User "Press Enter to exit"
