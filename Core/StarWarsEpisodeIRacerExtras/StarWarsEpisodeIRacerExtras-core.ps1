param([string]$GameRoot = "")

. "$PSScriptRoot\..\Modules\InstallerSafety.ps1"

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
    $locatedRoot = Get-GameFolderInteractive -GameName "Star Wars Episode I Racer" -ProbeFile "SWEP1RCR.EXE"
    if ($locatedRoot -in @('quit','skip') -or -not (Test-RacerRoot $locatedRoot)) { exit 1 }
    $GameRoot = $locatedRoot
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tracksScript -GameRoot $GameRoot -NoIntro -NoPause
if ($LASTEXITCODE -ne 0) {
    $trackProbe = Join-Path $GameRoot "assets\custom_tracks\bigblue\out_modelblock.bin"
    $recovery = Invoke-InstallerFallback -Action "install the community tracks" `
        -Instructions "The automatic track installer did not finish. Copy only the community pack's 'assets\custom_tracks' folder into '$GameRoot\assets\custom_tracks'. Never copy its dinput.dll over the PCVR build, then choose Retry." `
        -RetryCheck { Test-Path -LiteralPath $trackProbe -PathType Leaf } `
        -SourceFolder (Split-Path -Parent $tracksScript) -DestFolder $GameRoot -AllowSkip $false
    if ($recovery -eq 'quit') { exit 1 }
}

$trackProbe = Join-Path $GameRoot "assets\custom_tracks\bigblue\out_modelblock.bin"
if (-not (Test-Path -LiteralPath $trackProbe -PathType Leaf)) {
    $recovery = Invoke-InstallerFallback -Action "verify the community tracks" `
        -Instructions "The expected track file is still missing. Copy only 'assets\custom_tracks' from the community pack into '$GameRoot\assets\custom_tracks', then choose Retry." `
        -RetryCheck { Test-Path -LiteralPath $trackProbe -PathType Leaf } `
        -DestFolder $GameRoot -AllowSkip $false
    if ($recovery -eq 'quit') { exit 1 }
}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot ".installed_path"), $GameRoot, (New-Object Text.UTF8Encoding($false)))
Pause-User "Press Enter to exit..." | Out-Null
