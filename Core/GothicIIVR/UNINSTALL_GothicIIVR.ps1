param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-Gothic([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-GothicOwned([string]$Path){return [bool]($Path -and
    (Test-Path -LiteralPath (Join-Path $Path 'Gothic2Notr.exe') -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_gothicii_ownership.csv') -PathType Leaf))}
if(-not(Test-GothicOwned $GameRoot)){try{$candidate=([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"');if(Test-GothicOwned $candidate){$GameRoot=$candidate}}catch{}}
if(-not(Test-GothicOwned $GameRoot)){Write-Host '  No Hub-owned Gothic II VR installation was found.' -ForegroundColor Yellow;Finish-Gothic 0}
if(Get-Process -Name 'Gothic2Notr' -ErrorAction SilentlyContinue){Write-Host '  Close Gothic II VR before removing it.' -ForegroundColor Red;Finish-Gothic 1}
if(-not $HubConfirmed){$answer=([string](Read-Host "Remove Hub-owned Gothic II VR files from '$GameRoot'? Type REMOVE")).Trim();if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-Gothic 0}}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'gothicii'
if(-not $result.Found){throw 'The Gothic II VR ownership manifest disappeared before removal.'}
if($result.Preserved -eq 0){
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt){try{if([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -eq [IO.Path]::GetFullPath($GameRoot)){Remove-Item -LiteralPath $receipt -Force}}catch{}}
}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed files." -ForegroundColor Green
Write-Host '  Purchased game data, launcher path, settings, saves and unrelated files stay in place.' -ForegroundColor Gray
Finish-Gothic 0
