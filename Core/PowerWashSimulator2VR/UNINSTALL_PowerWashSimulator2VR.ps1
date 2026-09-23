param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$identity='wetrealityxr'
$receipt=Join-Path $PSScriptRoot '.installed_path'
function Finish-WRUninstall([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-WROwnedRoot([string]$Path){return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'PowerWash Simulator 2.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $Path ".pcvrhub_${identity}_ownership.csv") -PathType Leaf))}

if(-not(Test-WROwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)){try{$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}catch{$GameRoot=''}}
if(-not(Test-WROwnedRoot $GameRoot)){Write-Host '  No Hub-owned Wet Reality XR installation was found.' -ForegroundColor Yellow;Finish-WRUninstall 0}
$GameRoot=(Get-Item -LiteralPath $GameRoot).FullName
if(Get-Process -Name 'PowerWash Simulator 2' -ErrorAction SilentlyContinue){Write-Host '  [XX] Close PowerWash Simulator 2 before removing VR mode.' -ForegroundColor Red;Finish-WRUninstall 1}
if(-not $HubConfirmed){$confirm=([string](Read-Host "Remove Hub-owned Wet Reality XR files from '$GameRoot'? Type REMOVE")).Trim();if($confirm -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-WRUninstall 0}}

$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $identity
if(-not $result.Found){throw 'The ownership manifest disappeared before removal.'}
if($result.Preserved -eq 0){
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if(Test-Path -LiteralPath $receipt -PathType Leaf){try{$saved=([IO.File]::ReadAllText($receipt)).Trim();if([IO.Path]::GetFullPath($saved)-eq[IO.Path]::GetFullPath($GameRoot)){Remove-Item -LiteralPath $receipt -Force}}catch{}}
}
if($result.Preserved -gt 0){Write-Host "  [!!] $($result.Preserved) changed Hub-owned file(s) were preserved for safety." -ForegroundColor Yellow}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  PowerWash Simulator 2, saves and MelonPreferences.cfg remain installed.' -ForegroundColor Gray
Finish-WRUninstall 0

