param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
Import-Module (Join-Path $PSHOME 'Modules\Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1') -Global -Force -ErrorAction Stop
$identity = 'journey_vr'
$receipt = ('' + $env:PCVR_JOURNEY_TEST_RECEIPT).Trim()
if (-not $receipt) { $receipt = Join-Path $PSScriptRoot '.installed_path' }

function Finish-JourneyRemoval([int]$Code) {
    if (-not $NoPause) { Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-JourneyOwnedRoot([string]$Path) {
    return [bool]($Path -and
        (Test-Path -LiteralPath ([IO.Path]::Combine($Path,'Journey.exe')) -PathType Leaf) -and
        (Test-Path -LiteralPath ([IO.Path]::Combine($Path,'.pcvrhub_journey_vr_ownership.csv')) -PathType Leaf))
}

if (-not (Test-JourneyOwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)) {
    $GameRoot = ([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
}
if (-not (Test-JourneyOwnedRoot $GameRoot)) {
    $saved = Get-PCVRRememberedGameFolder -GameId 'journey-vr' -ProbeFiles @('Journey.exe','.pcvrhub_journey_vr_ownership.csv') -StateNames @('installed_path','user_located')
    if (Test-JourneyOwnedRoot $saved) { $GameRoot = $saved }
}
if (-not (Test-JourneyOwnedRoot $GameRoot)) {
    $found = Find-SteamGameFolder -AppId '638230' -SteamFolderNames @('Journey') -ProbeExe 'Journey.exe' -HubGameId 'journey-vr'
    if (Test-JourneyOwnedRoot $found) { $GameRoot = $found }
}
if (-not (Test-JourneyOwnedRoot $GameRoot)) {
    foreach ($path in @('C:\Program Files (x86)\Steam\steamapps\common\Journey')) {
        if (Test-JourneyOwnedRoot $path) { $GameRoot = $path; break }
    }
}
if (-not (Test-JourneyOwnedRoot $GameRoot)) {
    Write-Host '  No Hub-owned Journey VR installation was found.' -ForegroundColor Yellow
    Finish-JourneyRemoval 0
}
if (Get-Process -Name 'Journey' -ErrorAction SilentlyContinue) {
    Write-Host '  [XX] Close Journey before removing VR mode.' -ForegroundColor Red
    Finish-JourneyRemoval 1
}
if (-not $HubConfirmed -and (Read-Host "Remove Hub-owned Journey VR files from '$GameRoot'? Type REMOVE") -cne 'REMOVE') {
    Finish-JourneyRemoval 0
}
$result = Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $identity
if (-not $result.Found) { throw 'The Journey ownership manifest disappeared before removal.' }
Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  Journey and your saves/settings remain. Generated VR settings can be removed manually.' -ForegroundColor Gray
if ($result.Preserved -gt 0) { Write-Host '  [!!] Modified mod files remain; review them before expecting a flat launch.' -ForegroundColor Yellow }
Finish-JourneyRemoval 0
