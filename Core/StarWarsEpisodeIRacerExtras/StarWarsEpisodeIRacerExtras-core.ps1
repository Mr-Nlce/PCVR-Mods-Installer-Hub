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
    Write-Host '[X] Rerun setup after restoring the community package; no new add-on receipt was written.' -ForegroundColor Yellow
    exit 1
}

$trackProbe = Join-Path $GameRoot "assets\custom_tracks\bigblue\out_modelblock.bin"
if (-not (Test-Path -LiteralPath $trackProbe -PathType Leaf)) {
    $recovery = Invoke-InstallerFallback -Action "verify the community tracks" `
        -Instructions "The expected track file is still missing. Copy only 'assets\custom_tracks' from the community pack into '$GameRoot\assets\custom_tracks', then choose Retry." `
        -RetryCheck { Test-Path -LiteralPath $trackProbe -PathType Leaf } `
        -DestFolder $GameRoot -AllowSkip $false
    if ($recovery -eq 'quit') { exit 1 }
    Write-Host '[X] The track payload is still unverified. No new add-on receipt was written.' -ForegroundColor Yellow
    exit 1
}
$tracksVersionPath = Join-Path $PSScriptRoot '..\StarWarsEpisodeIRacerTracks\.installed_version'
$tracksVersion = try { (Get-Content -LiteralPath $tracksVersionPath -Raw -ErrorAction Stop).Trim() } catch { '' }
if (-not (Test-IsTrackableInstalledVersion -Version $tracksVersion)) {
    throw 'The track installer did not record the downloaded release version. No add-on success was recorded.'
}
$pathReceipt = Join-Path $PSScriptRoot '.installed_path'
$versionReceipt = Join-Path $PSScriptRoot '.installed_version'
$oldPath = if (Test-Path -LiteralPath $pathReceipt -PathType Leaf) { [IO.File]::ReadAllBytes($pathReceipt) } else { $null }
$oldVersion = if (Test-Path -LiteralPath $versionReceipt -PathType Leaf) { [IO.File]::ReadAllBytes($versionReceipt) } else { $null }
try {
    [IO.File]::WriteAllText($versionReceipt,$tracksVersion,(New-Object Text.UTF8Encoding($false)))
    [IO.File]::WriteAllText($pathReceipt,$GameRoot,(New-Object Text.UTF8Encoding($false)))
} catch {
    if ($null -eq $oldPath) { Remove-Item -LiteralPath $pathReceipt -Force -ErrorAction SilentlyContinue } else { [IO.File]::WriteAllBytes($pathReceipt,$oldPath) }
    if ($null -eq $oldVersion) { Remove-Item -LiteralPath $versionReceipt -Force -ErrorAction SilentlyContinue } else { [IO.File]::WriteAllBytes($versionReceipt,$oldVersion) }
    throw
}
Pause-User "Press Enter to exit..." | Out-Null
