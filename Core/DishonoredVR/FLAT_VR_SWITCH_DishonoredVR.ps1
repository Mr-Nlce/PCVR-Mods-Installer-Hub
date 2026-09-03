# =============================================================
#  Dishonored - switch between VR and flat
# =============================================================
# WHY. The mod's prologue cutscene is glitched in VR: it can block
# progress in the first mission. The author's own advice is to play that
# part flat and switch to VR afterwards. Doing that by hand means
# knowing which file to move - so this does it.
#
# HOW. The whole mod hangs off ONE file: Binaries\Win32\d3d9.dll, the
# proxy the game loads at startup. Rename it and Dishonored runs exactly
# as it always did; rename it back and VR returns. Nothing else is
# touched, and nothing is ever deleted - the file is renamed to
# d3d9.dll.flat and back.
#
# !!! NOT AUTOMATIC, AND NOT PART OF A LAUNCHER. Flipping this behind
# the user's back would mean the game silently starting in the wrong
# mode. You run it, you see which mode is active, you choose.

$ErrorActionPreference = "Stop"

$BIN_SUB   = "Binaries\Win32"
$PROXY     = "d3d9.dll"
$PROXY_OFF = "d3d9.dll.flat"
$GAME_EXE  = "Dishonored.exe"

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Write-Do   { param($m) Write-Host "  [->] $m" -ForegroundColor Cyan }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Dishonored - VR on or off" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""

# ---- The game must be closed ---------------------------------
if (@(Get-Process -Name "Dishonored" -ErrorAction SilentlyContinue).Count -gt 0) {
    Write-Fail "Dishonored is running. Close it, then run this again."
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- Find the install ----------------------------------------
$gameRoot = $null
try {
    $rp = Join-Path $PSScriptRoot ".installed_path"
    if (Test-Path -LiteralPath $rp) { $gameRoot = (Get-Content -LiteralPath $rp -Raw -ErrorAction Stop).Trim() }
} catch {}
if (-not $gameRoot -or -not (Test-Path -LiteralPath $gameRoot)) {
    try {
        . (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
        $gameRoot = Find-SteamGameFolder -AppId "205100" -SteamFolderNames @("Dishonored") -ProbeExe "$BIN_SUB\$GAME_EXE"
    } catch {}
}
if (-not $gameRoot) {
    Write-Warn "Could not find your Dishonored folder."
    $gameRoot = (Read-Host "  Paste it here (or Enter to exit)").Trim().Trim('"')
    if (-not $gameRoot -or -not (Test-Path -LiteralPath $gameRoot)) {
        Write-Info "Nothing was changed."
        Pause-User "Press Enter to exit."
        exit 0
    }
}
$binDir = Join-Path $gameRoot $BIN_SUB
$on  = Join-Path $binDir $PROXY
$off = Join-Path $binDir $PROXY_OFF

if (-not (Test-Path -LiteralPath (Join-Path $binDir "dxvk_d3d9.dll"))) {
    Write-Fail "Dishonored VR does not look installed in $gameRoot"
    Write-Do "Run the installer first."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameRoot"

# ---- Which way round is it? ----------------------------------
$vrOn  = Test-Path -LiteralPath $on
$vrOff = Test-Path -LiteralPath $off
Write-Host ""
if ($vrOn -and -not $vrOff) {
    Write-Host "  VR is currently ON." -ForegroundColor Green
} elseif ($vrOff -and -not $vrOn) {
    Write-Host "  VR is currently OFF - the game runs flat." -ForegroundColor Yellow
} elseif ($vrOn -and $vrOff) {
    Write-Warn "Both $PROXY and $PROXY_OFF exist."
    Write-Host "  VR counts as ON - the game loads $PROXY. Delete the stray" -ForegroundColor Gray
    Write-Host "  $PROXY_OFF yourself if you are sure which one you want." -ForegroundColor Gray
    Pause-User "Press Enter to exit."
    exit 1
} else {
    Write-Fail "Neither $PROXY nor $PROXY_OFF is there - the mod is incomplete."
    Write-Do "Run the installer again."
    Pause-User "Press Enter to exit."
    exit 1
}

Write-Host ""
Write-Host "  [1] VR on   - stereo, motion controls, roomscale" -ForegroundColor Cyan
Write-Host "  [2] VR off  - plain flatscreen Dishonored" -ForegroundColor Cyan
Write-Host "      Use this for the glitched prologue, then switch back." -ForegroundColor Gray
Write-Host "  [3] Leave it as it is" -ForegroundColor Gray
Write-Host ""
$pick = ""
for ($k = 1; $k -le 20; $k++) {
    $pick = ("" + (Read-Host "  Enter 1, 2 or 3")).Trim()
    if ($pick -in @("1","2","3")) { break }
    Write-Host "  Please answer 1, 2 or 3." -ForegroundColor Yellow
}
if ($pick -eq "3") { Write-Info "Nothing was changed."; Pause-User "Press Enter to exit."; exit 0 }

try {
    if ($pick -eq "1") {
        if ($vrOn) { Write-Info "VR was already on - nothing to do." }
        else { Move-Item -LiteralPath $off -Destination $on -ErrorAction Stop; Write-OK "VR is on." }
    } else {
        if ($vrOff) { Write-Info "VR was already off - nothing to do." }
        else { Move-Item -LiteralPath $on -Destination $off -ErrorAction Stop; Write-OK "VR is off - the game runs flat." }
    }
} catch {
    Write-Fail "Could not switch: $($_.Exception.Message)"
    Write-Do "Close Steam and anything holding the folder, then try again."
}

Write-Host ""
Write-Host "  Use Start in VR in the Hub or launch through Steam either way." -ForegroundColor Gray
Write-Host "  A direct .exe launch crashes at the menu." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to exit."
