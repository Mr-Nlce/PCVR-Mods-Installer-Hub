param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-Turok([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-TurokOwned([string]$Path){return [bool]($Path -and
    (Test-Path -LiteralPath (Join-Path $Path 'sobek_Shipping_Steam_x64.exe') -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_turokvr_ownership.csv') -PathType Leaf))}
if(-not(Test-TurokOwned $GameRoot)){try{$candidate=([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"');if(Test-TurokOwned $candidate){$GameRoot=$candidate}}catch{}}
if(-not(Test-TurokOwned $GameRoot)){Write-Host '  No Hub-owned Turok VR installation was found.' -ForegroundColor Yellow;Finish-Turok 0}
if(Get-Process -Name 'sobek_Shipping_Steam_x64' -ErrorAction SilentlyContinue){Write-Host '  Close Turok before removing VR files.' -ForegroundColor Red;Finish-Turok 1}
if(-not $HubConfirmed){$answer=([string](Read-Host "Remove Hub-owned Turok VR files from '$GameRoot'? Type REMOVE")).Trim();if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-Turok 0}}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'turokvr'
if(-not $result.Found){throw 'The Turok VR ownership manifest disappeared before removal.'}
if($result.Preserved -eq 0){
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt){try{if([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -eq [IO.Path]::GetFullPath($GameRoot)){Remove-Item -LiteralPath $receipt -Force}}catch{}}
}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed files." -ForegroundColor Green
Write-Host '  TurokVRUser.ini, saves, unrelated mods and the base game stay in place.' -ForegroundColor Gray
$configBackup=Join-Path $GameRoot 'kexengine.cfg.pre-turokvr.bak'
if(Test-Path -LiteralPath $configBackup -PathType Leaf){Write-Host '  Publisher backup remains: kexengine.cfg.pre-turokvr.bak. Review it before restoring game video settings.' -ForegroundColor Yellow}
Finish-Turok 0
