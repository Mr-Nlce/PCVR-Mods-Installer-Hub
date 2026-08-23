# ============================================================
#  AWAY VR - AwayVR by Pk-c (Chromatic Mod)
# ============================================================
#  A BepInEx mod for AWAY: Journey to the Unexpected (Unity
#  2017). It is simply unpacked into the game folder - no
#  setup, no registry, no folder of its own.
#
#  TWO THINGS ABOUT THIS ARCHIVE that must survive the install:
#   1. It ships an ALREADY PATCHED globalgamemanagers. The
#      engine reads that file BEFORE the mono runtime exists,
#      so no plugin could switch the OpenVR device on in time.
#      The original travels along as .orig and is put back by
#      the uninstaller.
#   2. The same patch puts Direct3D 11 at the head of the
#      graphics API list. Under D3D12, Unity 2017 fails to
#      start VR SILENTLY.
#  So everything is copied unchanged, overwriting what is in
#  the way - exactly what the author's instructions say.
#
#  UNINSTALLING IS HIS, NOT OURS: the archive drops
#  "uninstall VR.bat" into the game folder. It restores the
#  configuration file, removes every file the mod added and
#  deletes itself. We build nothing of our own for that.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "AWAY VR Installer"
$ErrorActionPreference = "Stop"

function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  [$n/$t] $x" -ForegroundColor Cyan; Write-Host "  ----------------------------------------" -ForegroundColor DarkGray }
function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$GAME_NAME = "AWAY: Journey to the Unexpected"
$APP_ID    = "573110"
$GAME_EXE  = "Away.exe"
$MOD_NAME  = "AwayVR"
$MOD_AUTHOR= "Pk-c"
$REPO      = "Pk-c/AwayVR"
$RELEASES  = "https://github.com/$REPO/releases"
$REL_MOD   = "BepInEx\plugins\AwayVR.dll"

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " AWAY: Journey to the Unexpected - VR" -ForegroundColor Cyan
Write-Host " $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  6DOF with tracked hands: you swing melee weapons with your" -ForegroundColor White
Write-Host "  arm, arm a grenade by squeezing and throw it as hard as you" -ForegroundColor White
Write-Host "  actually throw. Room-scale walking, snap or smooth turning," -ForegroundColor White
Write-Host "  camera collision - and the game's flat interface rebuilt as" -ForegroundColor White
Write-Host "  panels you can look at instead of a screen overlay." -ForegroundColor White
Write-Host ""
Write-Host "  SteamVR must be running before the game starts. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Locate the game ---------------------------------------
Write-Step 1 3 "Finding $GAME_NAME"
$gameDir = Find-SteamGameFolder -AppId $APP_ID `
             -SteamFolderNames @("AWAY Journey to the Unexpected","AWAY") -ProbeExe $GAME_EXE
if (-not $gameDir) {
    # String concatenation instead of Join-Path: a dead drive
    # letter would make Join-Path throw (hub-wide rule).
    foreach ($c in @("C:\GOG Games\AWAY Journey to the Unexpected",
                     "C:\Program Files (x86)\GOG Galaxy\Games\AWAY Journey to the Unexpected",
                     "D:\GOG Games\AWAY Journey to the Unexpected",
                     "E:\GOG Games\AWAY Journey to the Unexpected")) {
        if (Test-Path -LiteralPath "$c\$GAME_EXE") { $gameDir = $c; break }
    }
}
if (-not $gameDir) { $gameDir = Get-GameFolderInteractive -GameName $GAME_NAME -ProbeFile $GAME_EXE }
if (-not $gameDir -or -not (Test-Path -LiteralPath "$gameDir\$GAME_EXE")) {
    Write-Fail "Could not find $GAME_EXE - nothing was installed."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameDir"
$null = Show-UpdateNoticeIfInstalled -TargetDir $gameDir -RelModFile $REL_MOD -Label "AWAY VR"

# ---- 2. Fetch and unpack the mod ------------------------------
Write-Step 2 3 "Downloading and installing $MOD_NAME"

$url = $null; $tag = ""; $assetName = ""; $assetSize = 0
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" `
               -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
    $a = Select-PayloadAsset -Assets $rel.assets
    if ($a -and $a.browser_download_url) {
        $url = [string]$a.browser_download_url
        $tag = [string]$rel.tag_name
        $assetName = [string]$a.name
        $assetSize = [long]$a.size
    }
    if ($url) { Write-OK "Release: $tag  ($assetName)" }
} catch { Write-Warn "GitHub could not be reached - falling back to the releases page." }
if (-not $url) { $url = $RELEASES }

$tmp = Join-Path $env:TEMP ("awayvr_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-Path $tmp "AwayVR.zip"

# An already-downloaded file is only used when the name AND the size
# match the current release - otherwise an old build sitting in the
# downloads folder would look just as good as the right one.
$have = Find-PredownloadedFile -Patterns @("AwayVR-*.zip") -Label "the AwayVR release" `
            -ExpectedName $assetName -ExpectedSize $assetSize
if ($have -and (Test-Path -LiteralPath $have)) {
    $zip = $have
    Write-Info "Using the copy you already downloaded."
} else {
    Invoke-SafeDownload -Urls @($url) -Destination $zip -Label "$MOD_NAME $tag" `
        -ManualUrl $RELEASES `
        -Instructions "Download the AwayVR zip from the releases page, save it as '$zip', then choose Retry."
}
if (-not (Test-Path -LiteralPath $zip)) {
    Write-Fail "No package - the game was not touched."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# The archive is FLAT and goes into the game folder exactly as it
# is: Away_Data\ (with the patched globalgamemanagers), BepInEx\,
# winhttp.dll, doorstop_config.ini, .doorstop_version, licenses\,
# README.txt and "uninstall VR.bat".
$st = Expand-ArchiveToTarget -ArchivePath $zip -TargetDir $gameDir `
        -RelModFile $REL_MOD `
        -Markers @("winhttp.dll", "doorstop_config.ini", "Away_Data\globalgamemanagers.orig") `
        -Label "AwayVR" `
        -SkipMessage "Nothing was copied - the game is untouched."
if ([string]$st -ne "ok" -and [string]$st -ne "manual") {
    Write-Fail "The package could not be unpacked - the game is untouched."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
try { if ($zip -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}

# Proof on disk, not a claim. The .orig matters most: without it
# there is no clean uninstall.
$missing = @()
foreach ($f in @($REL_MOD, "winhttp.dll", "Away_Data\globalgamemanagers", "Away_Data\globalgamemanagers.orig", "uninstall VR.bat")) {
    if (-not (Test-Path -LiteralPath "$gameDir\$f")) { $missing += $f }
}
if ($missing.Count -gt 0) {
    Write-Fail ("These did not arrive: " + ($missing -join ", "))
    Write-Host "  Unpack the zip into $gameDir by hand and run this again." -ForegroundColor White
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Installed and verified on disk."
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}
if ($tag) { try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $tag -Encoding UTF8 -Force } catch {} }
# ALSO write the durable stamp next to the GAME (2026-08-20).
# The line above lands inside the Hub folder and is gone as
# soon as a new Hub build is dropped in; the scan then finds
# no marker and seeds the CURRENT online tag, swallowing a
# pending update. The game-side stamp survives that.
Save-InstalledStamp -GameDir $gameDir -Version $tag

# ---- 3. Playing -----------------------------------------------
Write-Step 3 3 "Playing"
Write-Host ""
Write-Host "  START STEAMVR FIRST, headset on, THEN launch the game. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Start in VR on this game's page in the Hub does the launch." -ForegroundColor White
Write-Host ""
Write-Host "  Click BOTH STICKS for the mod's own settings menu - turning," -ForegroundColor White
Write-Host "  weapon size, world scale, HUD, player height, and more. Every" -ForegroundColor White
Write-Host "  change applies live." -ForegroundColor White
Write-Host ""
Write-Host "  Two settings in there are worth knowing about, because they" -ForegroundColor Gray
Write-Host "  undo assumptions that only hold on a flat screen:" -ForegroundColor Gray
Write-Host "    HIT BOX   - the game pins a melee blow's damage volume two" -ForegroundColor Gray
Write-Host "                metres ahead of your head, so it sinks when you" -ForegroundColor Gray
Write-Host "                crouch" -ForegroundColor Gray
Write-Host "    KNOCKBACK - the game throws a struck enemy along its own" -ForegroundColor Gray
Write-Host "                forward, which is only 'away from you' on a" -ForegroundColor Gray
Write-Host "                screen, where you always face what you hit" -ForegroundColor Gray
Write-Host ""
Write-Host "  The full control map is on this game's page in the Hub." -ForegroundColor Gray
Write-Host ""
Write-Host "  >>> The narrator promised an adventure. He did not promise" -ForegroundColor Magenta
Write-Host "      your arms would be this tired." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
exit 0
