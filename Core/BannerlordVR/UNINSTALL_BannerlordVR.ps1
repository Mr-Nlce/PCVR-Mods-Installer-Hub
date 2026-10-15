param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$receipt=Join-Path $PSScriptRoot '.installed_path'
function Finish-BannerlordUninstall([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-BannerlordOwnedRoot([string]$Path){return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'bin\Win64_Shipping_Client\TaleWorlds.MountAndBlade.Launcher.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_bannerlordvr_ownership.csv') -PathType Leaf))}
if(-not(Test-BannerlordOwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)){try{$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}catch{$GameRoot=''}}
if(-not(Test-BannerlordOwnedRoot $GameRoot)){Write-Host '  No Hub-owned BannerlordVR installation was found.' -ForegroundColor Yellow;Finish-BannerlordUninstall 0}
$GameRoot=(Get-Item -LiteralPath $GameRoot).FullName
if(Get-Process -Name 'Bannerlord','Bannerlord.Native','TaleWorlds.MountAndBlade.Launcher' -ErrorAction SilentlyContinue){Write-Host '  [XX] Close Bannerlord and its launcher first.' -ForegroundColor Red;Finish-BannerlordUninstall 1}
if(-not $HubConfirmed){$confirm=([string](Read-Host "Remove Hub-owned BannerlordVR files from '$GameRoot'? Type REMOVE")).Trim();if($confirm -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-BannerlordUninstall 0}}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'bannerlordvr'
if(-not $result.Found){throw 'The ownership manifest disappeared before removal.'}
if($result.Preserved -eq 0){Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue;if(Test-Path -LiteralPath $receipt){Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue}}
if($result.Preserved -gt 0){Write-Host "  [!!] $($result.Preserved) changed Hub-owned file(s) were preserved." -ForegroundColor Yellow}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  Harmony, Bannerlord, saves and unrelated modules remain installed.' -ForegroundColor Gray
Finish-BannerlordUninstall 0
