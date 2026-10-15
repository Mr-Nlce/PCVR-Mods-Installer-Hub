param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
Import-Module (Join-Path $PSHOME 'Modules\Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1') -Global -Force -ErrorAction Stop
$identity = 'bladevr'
$receipt = ('' + $env:PCVR_BLADE_TEST_RECEIPT).Trim()
if (-not $receipt) { $receipt = Join-Path $PSScriptRoot '.installed_path' }

function Finish-BladeRemoval([int]$Code) {
    if (-not $NoPause) { Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-BladeOwnedRoot([string]$Path) {
    return [bool]($Path -and
        (Test-Path -LiteralPath (Join-Path $Path 'bin\bin\Blade.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_bladevr_ownership.csv') -PathType Leaf))
}
if (-not (Test-BladeOwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)) {
    $GameRoot = ([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
}
if (-not (Test-BladeOwnedRoot $GameRoot)) {
    Write-Host '  No Hub-owned BladeVR installation was found.' -ForegroundColor Yellow
    Finish-BladeRemoval 0
}
if (Get-Process -Name 'Blade' -ErrorAction SilentlyContinue) {
    Write-Host '  [XX] Close Blade of Darkness before removing VR mode.' -ForegroundColor Red
    Finish-BladeRemoval 1
}
if (-not $HubConfirmed -and (Read-Host "Remove Hub-owned BladeVR files from '$GameRoot'? Type REMOVE") -cne 'REMOVE') {
    Finish-BladeRemoval 0
}
$result = Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $identity
if (-not $result.Found) { throw 'The BladeVR ownership manifest disappeared before removal.' }
Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  Blade of Darkness, saves and unrelated mods remain installed.' -ForegroundColor Gray
if ($result.Preserved -gt 0) { Write-Host '  [!!] Changed mod files remain; inspect them before expecting a flat launch.' -ForegroundColor Yellow }
Finish-BladeRemoval 0
