param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$IDENTITY='mirrorsedgevr';$receipt=Join-Path $PSScriptRoot '.installed_path'
function Finish-MEVRUninstall([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-MEVROwnedRoot([string]$Path){return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'Binaries\MirrorsEdge.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Path ".pcvrhub_${IDENTITY}_ownership.csv") -PathType Leaf))}
if(-not(Test-MEVROwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)){try{$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}catch{$GameRoot=''}}
if(-not(Test-MEVROwnedRoot $GameRoot)){Write-Host "  No Hub-owned Mirror's Edge VR installation was found." -ForegroundColor Yellow;Finish-MEVRUninstall 0}
$GameRoot=(Get-Item -LiteralPath $GameRoot).FullName
if(Get-Process -Name 'MirrorsEdge' -ErrorAction SilentlyContinue){Write-Host "  [XX] Close Mirror's Edge before removing VR mode." -ForegroundColor Red;Finish-MEVRUninstall 1}
if(-not $HubConfirmed){$confirm=([string](Read-Host "Remove Hub-owned Mirror's Edge VR files from '$GameRoot'? Type REMOVE")).Trim();if($confirm -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-MEVRUninstall 0}}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $IDENTITY
if(-not $result.Found){throw 'The ownership manifest disappeared before removal.'}
if($result.Preserved -eq 0){Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue;if(Test-Path -LiteralPath $receipt){Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue}}
if($result.Preserved -gt 0){Write-Host "  [!!] $($result.Preserved) changed Hub-owned file(s) were preserved for safety." -ForegroundColor Yellow}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host "  Mirror's Edge, saves and unrelated files remain installed." -ForegroundColor Gray
Finish-MEVRUninstall 0
