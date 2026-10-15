param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
Import-Module (Join-Path $PSHOME 'Modules\Microsoft.PowerShell.Utility\Microsoft.PowerShell.Utility.psd1') -Global -Force -ErrorAction Stop
$receipt=(''+$env:PCVR_MISIDE_TEST_RECEIPT).Trim();if(-not $receipt){$receipt=Join-Path $PSScriptRoot '.installed_path'}
function Finish-MiSideRemoval([int]$Code){if(-not $NoPause){Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-MiSideOwnedRoot([string]$Path){return [bool]($Path -and (Test-Path -LiteralPath $Path -PathType Container) -and (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_misidevr_ownership.csv') -PathType Leaf))}
if(-not(Test-MiSideOwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)){$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}
if(-not(Test-MiSideOwnedRoot $GameRoot)){Write-Host '  No Hub-owned MiSide VR plugin was found.' -ForegroundColor Yellow;Finish-MiSideRemoval 0}
if(Get-Process -Name 'MiSideFull' -ErrorAction SilentlyContinue){Write-Host '  [XX] Close MiSide before removing VR mode.' -ForegroundColor Red;Finish-MiSideRemoval 1}
if(-not $HubConfirmed -and (Read-Host "Remove Hub-owned MiSide VR files from '$GameRoot'? Type REMOVE") -cne 'REMOVE'){Finish-MiSideRemoval 0}
$mod=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'misidevr'
if(-not $mod.Found){throw 'The MiSide VR ownership manifest disappeared before removal.'}
$plugins=Join-Path $GameRoot 'BepInEx\plugins'
$remainingPlugins=@(Get-ChildItem -LiteralPath $plugins -Recurse -File -Filter '*.dll' -ErrorAction SilentlyContinue)
$bep=$null
if($remainingPlugins.Count -eq 0 -and (Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_miside_bep_ownership.csv') -PathType Leaf)){
    $bep=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'miside_bep'
}elseif($remainingPlugins.Count -gt 0){
    Write-Host '  [!!] Other BepInEx plugins remain. The shared loader is left in place.' -ForegroundColor Yellow
}
Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue
Write-Host "  [OK] MiSide VR files removed: $($mod.Removed); restored: $($mod.Restored); changed files kept: $($mod.Preserved)." -ForegroundColor Green
if($bep){Write-Host "  [OK] Hub-owned loader files removed: $($bep.Removed); restored: $($bep.Restored)." -ForegroundColor Green}
Write-Host '  The Steam game, saves, generated config and unrelated plugins remain.' -ForegroundColor Gray
Finish-MiSideRemoval 0
