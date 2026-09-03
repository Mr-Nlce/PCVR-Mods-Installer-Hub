# =============================================================
# Elden Ring - switch between current and pinned-depot saves
# =============================================================
# The current Steam build and the pinned 1.16.2 build read the same
# %APPDATA% save. A newer save cannot be opened by 1.16.2, so this tool
# parks each build's set under its own suffix. It is deliberately manual:
# the user chooses the intended build with the game closed.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "EldenRingSaveManager.ps1")

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Elden Ring - switch save between builds" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""

$running = @(Get-Process -Name "eldenring", "start_protected_game" -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) {
    Write-Fail "Elden Ring is running. Close it completely, then run this again."
    Write-Host "  Moving a save while the game holds it can lose progress." -ForegroundColor Gray
    Pause-User "Press Enter to exit."
    exit 1
}

$root = Join-Path $env:APPDATA "EldenRing"
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    Write-Fail "No save folder at $root"
    Write-Host "  Start Elden Ring once so it creates one." -ForegroundColor Gray
    Pause-User "Press Enter to exit."
    exit 1
}
$dir = Select-EldenRingSaveAccountDirectory -SaveRoot $root
if (-not $dir) {
    Write-Fail "No Elden Ring account folder was selected."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Save folder: $dir"

$state = Get-EldenRingSaveState -SaveDirectory $dir
Write-Host ""
Write-Host "  Right now:" -ForegroundColor White
Write-Host ("    live save file(s)      : " + $state.LiveFiles.Count) -ForegroundColor Gray
Write-Host ("    parked current file(s) : " + $state.CurrentFiles.Count) -ForegroundColor Gray
Write-Host ("    parked depot file(s)   : " + $state.DepotFiles.Count) -ForegroundColor Gray
if ($state.Marker) { Write-Host ("    recorded active build   : " + $state.Marker) -ForegroundColor Gray }
Write-Host ""

Write-Host "  [1] Play the CURRENT Steam build" -ForegroundColor Cyan
Write-Host "      Parks the depot set and restores the current set." -ForegroundColor Gray
Write-Host ""
Write-Host "  [2] Play the PINNED 1.16.2 VR build" -ForegroundColor Cyan
Write-Host "      Parks the current set and restores the depot set." -ForegroundColor Gray
Write-Host ""
Write-Host "  [3] Do nothing" -ForegroundColor Gray
Write-Host ""
$mode = ""
for ($try = 1; $try -le 20; $try++) {
    $mode = ("" + (Read-Host "  Enter 1, 2 or 3")).Trim()
    if ($mode -in @("1","2","3")) { break }
    Write-Warn "Please answer 1, 2 or 3."
}
if ($mode -eq "3") { Write-Info "Nothing was changed."; Pause-User "Press Enter to exit."; exit 0 }
if ($mode -notin @("1","2")) { Write-Fail "No valid choice was made."; Pause-User "Press Enter to exit."; exit 1 }

$target = if ($mode -eq "1") { "Current" } else { "Depot" }
$result = Invoke-EldenRingSaveSwitch -SaveDirectory $dir -TargetBuild $target
if (-not $result.Success) {
    Write-Fail "The save was not switched: $($result.Reason)"
    Write-Host "  No parked save was overwritten. Any dated safety backup that" -ForegroundColor Gray
    Write-Host "  was already completed remains under .pcvrhub-save-backups." -ForegroundColor Gray
    Pause-User "Press Enter to exit."
    exit 1
}

if ($result.Changed) { Write-OK "$target is now the active save set." }
else { Write-Info $result.Reason }
if ($result.Backup) { Write-OK "Verified safety copy: $($result.Backup)" }
Write-Host ""
Write-Host "  TURN STEAM CLOUD OFF FOR ELDEN RING " -NoNewline -ForegroundColor Black -BackgroundColor Red
Write-Host ""
Write-Host "  Steam properties > General > Steam Cloud. Otherwise Steam can" -ForegroundColor White
Write-Host "  put its own save back and undo the separation while syncing." -ForegroundColor White
Write-Host ""
try { Start-Process explorer.exe $dir } catch {}
Pause-User "Press Enter to exit."
