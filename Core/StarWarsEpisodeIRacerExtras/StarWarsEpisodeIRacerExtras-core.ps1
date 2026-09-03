param([string]$GameRoot = "")

$mainDir = Join-Path $PSScriptRoot "..\StarWarsEpisodeIRacerVR"
$tracksScript = Join-Path $PSScriptRoot "..\StarWarsEpisodeIRacerTracks\StarWarsEpisodeIRacerTracks-core.ps1"

function Pause-User([string]$Text="Press Enter to continue...") { Write-Host ""; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }
function Test-RacerRoot([string]$Path) { return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path "SWEP1RCR.EXE") -PathType Leaf)) }

Clear-Host
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Star Wars Episode I Racer - Community Tracks" -ForegroundColor Cyan
Write-Host " Installs: SW_RACER_RE community tracks by tim-tim707 community" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " This copies only assets\custom_tracks." -ForegroundColor White
Write-Host " The pack's different dinput.dll is never installed over PCVR." -ForegroundColor Yellow
Pause-User "Press Enter to proceed with setup..." | Out-Null

if (-not (Test-RacerRoot $GameRoot)) {
    try { $GameRoot = (Get-Content -LiteralPath (Join-Path $mainDir ".installed_path") -Raw).Trim() } catch {}
}
if (-not (Test-RacerRoot $GameRoot)) {
    Write-Host "[X] Racer PCVR must be installed first." -ForegroundColor Red
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tracksScript -GameRoot $GameRoot -NoIntro -NoPause
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Community tracks could not be installed." -ForegroundColor Red
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}

$trackProbe = Join-Path $GameRoot "assets\custom_tracks\bigblue\out_modelblock.bin"
if (-not (Test-Path -LiteralPath $trackProbe -PathType Leaf)) {
    Write-Host "[X] Community tracks could not be verified." -ForegroundColor Red
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot ".installed_path"), $GameRoot, (New-Object Text.UTF8Encoding($false)))
Pause-User "Press Enter to exit..." | Out-Null
