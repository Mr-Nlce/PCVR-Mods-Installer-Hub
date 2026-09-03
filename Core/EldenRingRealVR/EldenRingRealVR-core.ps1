# =============================================================
#  Elden Ring VR - Gamepad (Luke Ross R.E.A.L.)
# =============================================================
# WHY THIS IS ITS OWN ENTRY (2026-08-29). Elden Ring now has THREE VR
# mods, and they do not divide the way one tile can show:
#
#   Hotbite      motion controls, lives in %LOCALAPPDATA%, no game files
#   Ilya's ERVR  motion controls, lives in <game>\Game
#   R.E.A.L.     gamepad,         lives in <game>\Game
#
# The two motion mods belong together on one tile. R.E.A.L. is a
# different kind of mod for a different kind of player, so it gets its
# own - and that also makes the collision visible instead of hidden:
#
# !!! ILYA AND R.E.A.L. BOTH SHIP dxgi.dll INTO <game>\Game AND CANNOT
# COEXIST. Ilya's author says so outright. This installer refuses to
# write over the other one silently.
#
# The actual install is done by the shared Luke Ross installer, which
# knows Elden Ring by name and handles the whole job. Nothing is
# rebuilt here.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path (Split-Path -Parent $PSScriptRoot) "EldenRingVR\EldenRingDepot.ps1")

$MOD_NAME     = "Elden Ring VR - Gamepad"
$MOD_AUTHOR   = "Luke Ross"
$STEAM_APPID  = "1245620"
$GAME_FOLDER  = "ELDEN RING"
$GAME_PROBE   = "Game\eldenring.exe"
$VRLAUNCH_SUB = "VRLaunch"
$LAUNCH_B     = "Elden Ring VR (Gamepad).bat"

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Write-Do   { param($m) Write-Host "  [->] $m" -ForegroundColor Cyan }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-EldenRingFolder {
    $p = $null
    if (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue) {
        try { $p = Find-SteamGameFolder -AppId $STEAM_APPID -SteamFolderNames @($GAME_FOLDER) -ProbeExe $GAME_PROBE } catch {}
    }
    if (-not $p) {
        try { $p = Get-GameFolderInteractive -GameName "Elden Ring" -ExeName "eldenring.exe" } catch {}
    }
    return $p
}

function Write-VrLauncher {
    param([string]$GameDir, [string]$Name, [string]$Body)
    try {
        $dir = Join-Path $GameDir $VRLAUNCH_SUB
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Set-Content -Path (Join-Path $dir $Name) -Value $Body -Encoding ASCII -Force
        return $true
    } catch { return $false }
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Elden Ring VR  -  Gamepad (R.E.A.L. by Luke Ross)" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Stereo VR with the camera on your head and the game played" -ForegroundColor White
Write-Host "  on a gamepad - the whole game, front to back, with none of" -ForegroundColor White
Write-Host "  the rough edges the motion-control mods still have." -ForegroundColor White
Write-Host ""
Write-Host "  If you want your hands in the game instead, close this and" -ForegroundColor Gray
Write-Host "  pick 'Elden Ring VR (Motion Controls)' in the Hub." -ForegroundColor Gray
Write-Host ""
Show-AntivirusNotice

# ---- Select Current or the separate 1.16.2 depot copy --------
$currentGameDir = Get-EldenRingFolder
if (-not $currentGameDir) {
    Write-Fail "Could not find your Elden Ring folder."
    Pause-User "Press Enter to exit."
    exit 1
}
$target = Select-EldenRingBuildTarget -CurrentGameDir $currentGameDir
if (-not $target) {
    Write-Info "Nothing was changed."
    Pause-User "Press Enter to exit."
    exit 0
}
$gameDir = $target.GameDir
Write-OK "Selected $($target.Mode): $gameDir"

$gameSub = Join-Path $gameDir "Game"
$ervrThere = (Test-Path -LiteralPath (Join-Path $gameSub "ERVR\ERVR.dll"))
if ($ervrThere) {
    Write-Host ""
    Write-Host "  ILYA'S ERVR IS INSTALLED IN THIS GAME FOLDER. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Write-Host ""
    Write-Host "  Both mods use the same file - dxgi.dll - and they cannot" -ForegroundColor White
    Write-Host "  both be in place. Ilya's own instructions say the same." -ForegroundColor White
    Write-Host ""
    Write-Host "  Installing R.E.A.L. now would overwrite it, and Elden Ring" -ForegroundColor Gray
    Write-Host "  would start with neither working properly." -ForegroundColor Gray
    Write-Host ""
    Write-Do "Remove ERVR first (its tile has an uninstaller), then come back."
    Write-Host ""
    Write-Warn "Installation is blocked to prevent a mixed, broken loader state."
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- Hand over to the shared installer ------------------------
$lr = Join-Path (Split-Path -Parent $PSScriptRoot) "LukeRossVR\LukeRossVR-core.ps1"
if (-not (Test-Path -LiteralPath $lr)) {
    Write-Fail "The Luke Ross installer is missing: $lr"
    Pause-User "Press Enter to exit."
    exit 1
}
Write-Host ""
Write-Info "Handing over to the Luke Ross installer..."
# It knows this game as "Elden Ring" in its own GAMES table - not by
# our tile title.
& $lr -GameTitle "Elden Ring" -GamePath $gameDir

# ---- Register with the Hub -----------------------------------
$realThere = (Test-Path -LiteralPath (Join-Path $gameSub "RealRepo\RealVR64.dll")) -or
             (Test-Path -LiteralPath (Join-Path $gameSub "RealRepo_\RealVR64.dll"))
if ($realThere) {
    $launcher = Write-EldenRingGamepadLauncher -GameDir $gameDir
    Write-OK "Registered with the Hub."
    try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}
    try {
        $suffix = if ($target.Mode -eq "Depot") { "Depot 1.16.2" } else { "Current" }
        $ws = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "Elden Ring VR Gamepad ($suffix).lnk"))
        $lnk.TargetPath = $launcher
        $lnk.WorkingDirectory = Split-Path -Parent $launcher
        $lnk.Description = "Elden Ring VR with Luke Ross R.E.A.L. ($suffix)"
        $lnk.Save()
    } catch { Write-Warn "Could not create the desktop shortcut." }
} else {
    Write-Info "R.E.A.L. was not detected afterwards - nothing was registered."
}

Write-Host ""
Pause-User "Press Enter to exit"
