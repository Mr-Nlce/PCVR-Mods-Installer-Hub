param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
Import-Module (Join-Path $PSHOME 'Modules\Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1') -Global -Force -ErrorAction Stop
$identity = 'flower_vr'
$receipt = ('' + $env:PCVR_FLOWER_TEST_RECEIPT).Trim()
if (-not $receipt) { $receipt = Join-Path $PSScriptRoot '.installed_path' }

function Finish-FlowerRemoval([int]$Code) {
    if (-not $NoPause) { Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-FlowerOwnedRoot([string]$Path) {
    return [bool]($Path -and
        (Test-Path -LiteralPath ([IO.Path]::Combine($Path,'Flower.exe')) -PathType Leaf) -and
        (Test-Path -LiteralPath ([IO.Path]::Combine($Path,'.pcvrhub_flower_vr_ownership.csv')) -PathType Leaf))
}

if (-not (Test-FlowerOwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)) {
    $GameRoot = ([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
}
if (-not (Test-FlowerOwnedRoot $GameRoot)) {
    $saved = Get-PCVRRememberedGameFolder -GameId 'flower-vr' -ProbeFiles @('Flower.exe','.pcvrhub_flower_vr_ownership.csv') -StateNames @('installed_path','user_located')
    if (Test-FlowerOwnedRoot $saved) { $GameRoot = $saved }
}
if (-not (Test-FlowerOwnedRoot $GameRoot)) {
    $found = Find-SteamGameFolder -AppId '966330' -SteamFolderNames @('Flower') -GogNames @('Flower') -ProbeExe 'Flower.exe' -HubGameId 'flower-vr'
    if (Test-FlowerOwnedRoot $found) { $GameRoot = $found }
}
if (-not (Test-FlowerOwnedRoot $GameRoot)) {
    foreach ($path in @('C:\Program Files (x86)\Steam\steamapps\common\Flower','C:\Program Files (x86)\GOG Galaxy\Games\Flower','C:\GOG Games\Flower','C:\Program Files\Epic Games\Flower')) {
        if (Test-FlowerOwnedRoot $path) { $GameRoot = $path; break }
    }
}
if (-not (Test-FlowerOwnedRoot $GameRoot)) {
    Write-Host '  No Hub-owned Flower VR installation was found.' -ForegroundColor Yellow
    Finish-FlowerRemoval 0
}
if (Get-Process -Name 'Flower' -ErrorAction SilentlyContinue) {
    Write-Host '  [XX] Close Flower before removing VR mode.' -ForegroundColor Red
    Finish-FlowerRemoval 1
}
if (-not $HubConfirmed -and (Read-Host "Remove Hub-owned Flower VR files from '$GameRoot'? Type REMOVE") -cne 'REMOVE') {
    Finish-FlowerRemoval 0
}
$result = Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $identity
if (-not $result.Found) { throw 'The Flower ownership manifest disappeared before removal.' }
Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  Flower and your saves/settings remain. Generated VR settings can be removed manually.' -ForegroundColor Gray
if ($result.Preserved -gt 0) { Write-Host '  [!!] Modified mod files remain; review them before expecting a flat launch.' -ForegroundColor Yellow }
Finish-FlowerRemoval 0
