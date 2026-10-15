param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
Import-Module (Join-Path $PSHOME 'Modules\Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1') -Global -Force -ErrorAction Stop
$receipt=(''+$env:PCVR_HEC_TEST_RECEIPT).Trim()
if(-not $receipt){$receipt=Join-Path $PSScriptRoot '.installed_path'}
function Finish-HecRemoval([int]$Code){if(-not $NoPause){Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-HecOwnedRoot([string]$Path){
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'HighEntropy.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_hecvr_ownership.csv') -PathType Leaf))
}
if(-not(Test-HecOwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)){
    $GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
}
if(-not(Test-HecOwnedRoot $GameRoot)){
    Write-Host '  No Hub-owned HECVR installation was found.' -ForegroundColor Yellow
    Finish-HecRemoval 0
}
if(Get-Process -Name 'HighEntropy' -ErrorAction SilentlyContinue){
    Write-Host '  [XX] Close High Entropy before removing VR mode.' -ForegroundColor Red
    Finish-HecRemoval 1
}
if(-not $HubConfirmed -and (Read-Host "Remove Hub-owned HECVR files from '$GameRoot'? Type REMOVE") -cne 'REMOVE'){
    Finish-HecRemoval 0
}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'hecvr'
if(-not $result.Found){throw 'The HECVR ownership manifest disappeared before removal.'}
Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  The Steam game, saves, unrelated mods and changed files remain.' -ForegroundColor Gray
if($result.Preserved -gt 0){Write-Host '  [!!] Changed mod files remain; inspect them before expecting a flat launch.' -ForegroundColor Yellow}
Finish-HecRemoval 0
