param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-EDFUninstall([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-EDFOwnedRoot([string]$Path){return [bool]($Path -and(Test-Path -LiteralPath (Join-Path $Path 'EDF6.exe') -PathType Leaf) -and(Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_edf6vr_ownership.csv') -PathType Leaf))}
if(-not(Test-EDFOwnedRoot $GameRoot)){try{$saved=(Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw -ErrorAction Stop).Trim();if(Test-EDFOwnedRoot $saved){$GameRoot=$saved}}catch{}}
if(-not(Test-EDFOwnedRoot $GameRoot)){Write-Host '[X] No Hub-owned EDF6VR installation was found. Nothing was guessed or deleted.' -ForegroundColor Red;Finish-EDFUninstall 1}
if(Get-Process -Name EDF6,LaunchGame -ErrorAction SilentlyContinue){Write-Host '[X] Close EDF6 before removing the VR mod.' -ForegroundColor Red;Finish-EDFUninstall 1}
if(-not $HubConfirmed){if((Read-Host "Remove Hub-owned EDF6VR files from '$GameRoot'? Type REMOVE").Trim() -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-EDFUninstall 0}}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'edf6vr' -ParkedAlternates @{'Mods\Plugins\EDF6VR.dll'='Mods\Plugins\EDF6VR.dll.disabled'}
Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
Write-Host '[KEEP] Shared EDFModLoader files remain for other EDF6 mods.' -ForegroundColor Gray
Write-Host '[KEEP] EDF6VR.ini, EDF6ClearLoot.ini, saves and unrelated plugins remain.' -ForegroundColor Gray
if($result.Preserved -eq 0 -and -not(Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_edf6vr_ownership.csv') -PathType Leaf)){Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue;Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Force -ErrorAction SilentlyContinue}
Finish-EDFUninstall 0
