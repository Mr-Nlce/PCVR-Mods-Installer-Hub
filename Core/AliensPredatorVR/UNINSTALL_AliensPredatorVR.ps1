param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
Import-Module (Join-Path $PSHOME 'Modules\Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1') -Global -Force -ErrorAction Stop
$receipt=(''+$env:PCVR_AVP_TEST_RECEIPT).Trim();if(-not $receipt){$receipt=Join-Path $PSScriptRoot '.installed_path'}
function Finish-AvpRemoval([int]$Code){if(-not $NoPause){Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-AvpOwnedRoot([string]$Path){
    return [bool]($Path -and (Test-Path -LiteralPath $Path -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_avpvr_ownership.csv') -PathType Leaf))
}
if(-not(Test-AvpOwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)){$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}
if(-not(Test-AvpOwnedRoot $GameRoot)){Write-Host '  No Hub-owned AvP VR installation was found.' -ForegroundColor Yellow;Finish-AvpRemoval 0}
if(Get-Process -Name 'AvP','avpvr_x64' -ErrorAction SilentlyContinue){Write-Host '  [XX] Close Aliens versus Predator before removing VR mode.' -ForegroundColor Red;Finish-AvpRemoval 1}
if(-not $HubConfirmed -and (Read-Host "Remove Hub-owned AvP VR files from '$GameRoot'? Type REMOVE") -cne 'REMOVE'){Finish-AvpRemoval 0}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'avpvr'
if(-not $result.Found){throw 'The AvP VR ownership manifest disappeared before removal.'}
Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  Licensed game data, saves, profiles, CD music and changed files remain.' -ForegroundColor Gray
if($result.Preserved -gt 0){Write-Host '  [!!] Changed VR files remain; inspect them before expecting a flat launch.' -ForegroundColor Yellow}
Finish-AvpRemoval 0
