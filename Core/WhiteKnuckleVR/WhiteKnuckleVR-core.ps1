# ============================================================
#  WHITE KNUCKLE VR - by kyanite-rock
# ============================================================
#  A full 6DOF conversion for White Knuckle, the speed-climbing
#  game by Dark Machine Games. Two parts have to be in place:
#    1. BepInEx 5, x64 - NOT bundled with the mod. The author
#       says so plainly: the x86 and IL2CPP builds do not work.
#    2. the mod archive, which mirrors the game folder and is
#       copied over it as-is.
#
#  !!! THE AUTHOR'S DESIGN DECISION, AND IT SHAPES EVERYTHING:
#  every VR interaction feeds the EXISTING physics system as an
#  input. The player moves exactly as in the flat game - the only
#  difference is that hands do the climbing. That is why buffs and
#  debuffs keep working untouched, and why the mod does not need a
#  single game file replaced.
#
#  !!! TWO LAUNCHES ARE REQUIRED AND THE FIRST ONE IS FLAT.
#  The first start writes three config files into BepInEx\config\
#  and stays on the monitor. That is not a fault - it is how the
#  mod gets its settings written. VR only comes on the second
#  start. Without saying this, everyone reports a broken mod after
#  launch one.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "White Knuckle VR Installer"
$ErrorActionPreference = "Stop"

function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  [$n/$t] $x" -ForegroundColor Cyan; Write-Host "  ----------------------------------------" -ForegroundColor DarkGray }
function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$GAME_NAME  = "White Knuckle"
$APP_ID     = "3195790"
$GAME_EXE   = "White Knuckle.exe"
$MOD_NAME   = "White Knuckle VR"
$MOD_AUTHOR = "kyanite-rock"
$REPO       = "kyanite-rock/White_Knuckle_VR"
$RELEASES   = "https://github.com/$REPO/releases"

# x64 BepInEx 5, exactly as the author specifies. The x86 and
# IL2CPP builds are explicitly named as not working.
$BEPINEX_URL = "https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.2/BepInEx_win_x64_5.4.23.2.zip"
$BEPINEX_TAG = "https://github.com/BepInEx/BepInEx/releases/latest"

# Read from the real archive of v1.0.2 (10 entries, 1,200,149 B,
# sha256 853710e7...), not guessed. The archive mirrors the game
# folder, so it is copied over the root unchanged.
$REL_MOD    = "BepInEx\plugins\WhiteKnuckleVRMod.dll"
$MOD_FILES  = @(
    "BepInEx\plugins\WhiteKnuckleVRMod.dll",
    "White Knuckle_Data\Managed\Unity.XR.OpenXR.dll",
    "White Knuckle_Data\Managed\Unity.XR.Management.dll",
    "White Knuckle_Data\Plugins\x86_64\openxr_loader.dll",
    "White Knuckle_Data\Plugins\x86_64\UnityOpenXR.dll",
    "White Knuckle_Data\UnitySubsystems\UnityOpenXR\UnitySubsystemsManifest.json"
)

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " White Knuckle - VR" -ForegroundColor Cyan
Write-Host " $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Full 6DOF VR with roomscale movement and gesture-based" -ForegroundColor White
Write-Host "  motion controls. You climb with your hands." -ForegroundColor White
Write-Host ""
Write-Host "  Every VR interaction feeds the game's EXISTING physics as" -ForegroundColor Gray
Write-Host "  an input, so you move exactly as in the flat game - and" -ForegroundColor Gray
Write-Host "  buffs and debuffs keep working untouched." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Locate the game ---------------------------------------
Write-Step 1 4 "Finding $GAME_NAME"
$gameDir = Find-SteamGameFolder -AppId $APP_ID `
             -SteamFolderNames @("White Knuckle", "WhiteKnuckle") `
             -ProbeExe $GAME_EXE
if (-not $gameDir) { $gameDir = Get-GameFolderInteractive -GameName $GAME_NAME -ProbeFile $GAME_EXE }
if (-not $gameDir -or -not (Test-Path -LiteralPath "$gameDir\$GAME_EXE")) {
    Write-Fail "Could not find $GAME_EXE - nothing was installed."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameDir"
$null = Show-UpdateNoticeIfInstalled -TargetDir $gameDir -RelModFile $REL_MOD -Label "White Knuckle VR"

$tmp = Join-Path $env:TEMP ("wkvr_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

# ---- 2. BepInEx 5 (x64) ---------------------------------------
Write-Step 2 4 "BepInEx 5 (x64)"

# The loader is only counted as present when its CORE is there -
# an empty BepInEx folder from a failed run would otherwise pass.
if (Test-Path -LiteralPath "$gameDir\BepInEx\core\BepInEx.dll") {
    Write-OK "BepInEx is already in place."
} else {
    Write-Info "Downloading BepInEx 5 (x64) - the x86 and IL2CPP builds do not work here."
    $bepZip = Join-Path $tmp "bepinex.zip"
    Invoke-SafeDownload -Urls @($BEPINEX_URL) -Destination $bepZip -Label "BepInEx 5 (x64)" `
        -ManualUrl $BEPINEX_TAG `
        -Instructions "Download BepInEx_win_x64_5.x.x.x.zip, save it as '$bepZip', then choose Retry."
    if (Test-Path -LiteralPath $bepZip) {
        $st = Expand-ArchiveOrFallback -ArchivePath $bepZip -DestinationFolder $gameDir -Label "BepInEx 5"
        if ([string]$st -eq "ok" -and (Test-Path -LiteralPath "$gameDir\BepInEx\core\BepInEx.dll")) {
            Write-OK "BepInEx installed."
        } else {
            Write-Fail "BepInEx did not arrive - the mod cannot load without it."
            try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit."
            exit 1
        }
    } else {
        Write-Fail "No BepInEx package - stopping before the mod is copied."
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit."
        exit 1
    }
}

# ---- 3. The mod -----------------------------------------------
Write-Step 3 4 "Downloading $MOD_NAME"

$url = $null; $tag = ""; $assetName = ""; $assetSize = 0
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" `
              -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
    $a = @($rel.assets) | Where-Object { $_.name -match '(?i)\.zip$' } | Select-Object -First 1
    if ($a) {
        $url = [string]$a.browser_download_url; $tag = [string]$rel.tag_name
        $assetName = [string]$a.name; $assetSize = [long]$a.size
    }
} catch { Write-Warn "GitHub could not be reached - falling back to the releases page." }
if ($url) { Write-OK "Release: $tag  ($assetName)" } else { $url = $RELEASES }

$modZip = Join-Path $tmp "WhiteKnuckleVR.zip"
# Name AND size have to match this release, or an older copy in the
# downloads folder would install itself silently.
$have = Find-PredownloadedFile -Patterns @("WhiteKnuckleVR*.zip") -Label "the White Knuckle VR package" `
            -ExpectedName $assetName -ExpectedSize $assetSize
if ($have -and (Test-Path -LiteralPath $have)) {
    $modZip = $have
    Write-Info "Using the copy you already downloaded."
} else {
    Invoke-SafeDownload -Urls @($url) -Destination $modZip -Label "$MOD_NAME $tag" `
        -ManualUrl $RELEASES `
        -Instructions "Download the White Knuckle VR zip from the releases page, save it as '$modZip', then choose Retry."
}
if (-not (Test-Path -LiteralPath $modZip)) {
    Write-Fail "No package - the mod was not installed."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# The archive MIRRORS the game folder (BepInEx\, White Knuckle_Data\,
# WhiteKnuckleVR\), so it is extracted over the root unchanged - no
# wrapper folder to resolve.
$st = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $gameDir -Label "$MOD_NAME"
if ([string]$st -ne "ok" -and [string]$st -ne "manual") {
    Write-Fail "The package could not be unpacked."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# Proof on disk, file by file. The mod DLL alone is not enough: the
# OpenXR runtime pieces go into the game's own data folder, and
# without them the plugin loads and finds no headset.
$missing = @()
foreach ($f in $MOD_FILES) {
    if (-not (Test-Path -LiteralPath "$gameDir\$f")) { $missing += $f }
}
if ($missing.Count -gt 0) {
    Write-Fail ("These did not arrive: " + ($missing -join ", "))
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Installed and verified: $gameDir"
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}
if ($tag) { try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $tag -Encoding UTF8 -Force } catch {} }
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# ---- 4. The two launches --------------------------------------
Write-Step 4 4 "How the first start works"
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   LAUNCH ONCE IN FLAT MODE FIRST - THAT IS NOT A FAULT" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Start the game and wait for the MAIN MENU. It stays on" -ForegroundColor White
Write-Host "     the monitor - that first run writes the mod's three" -ForegroundColor White
Write-Host "     config files. Then close the game." -ForegroundColor White
Write-Host ""
Write-Host "  2. Start your VR runtime, then launch again." -ForegroundColor White
Write-Host "     Now it comes up in VR." -ForegroundColor White
Write-Host ""
Write-Host "  Any OpenXR headset should work. The author tested on a" -ForegroundColor Gray
Write-Host "  Quest 2 and has no Index to test with - Index owners get" -ForegroundColor Gray
Write-Host "  their own control scheme, but it is untested." -ForegroundColor Gray
Write-Host ""
Write-Host "  The mod renders in MULTI-PASS, because the game's custom" -ForegroundColor Gray
Write-Host "  shaders are not compiled for single-pass. If the frame" -ForegroundColor Gray
Write-Host "  rate is short, renderScale in the VR settings menu is the" -ForegroundColor Gray
Write-Host "  first thing to lower." -ForegroundColor Gray
Write-Host ""
Write-Host "  Pause in-game for the VR settings; the full control map" -ForegroundColor Gray
Write-Host "  and every gesture are on this game's page in the Hub." -ForegroundColor Gray
Write-Host ""
Write-Host "  >>> Your hands are the only thing between you and the drop." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
exit 0
