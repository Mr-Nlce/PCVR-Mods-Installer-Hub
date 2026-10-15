param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-Nobeta([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit' | Out-Null};exit $Code}
function Test-NobetaOwned([string]$Path){
    return [bool]($Path -and
        (Test-Path -LiteralPath (Join-Path $Path 'LittleWitchNobeta.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_nobetavr_ownership.csv') -PathType Leaf))
}
if(-not(Test-NobetaOwned $GameRoot)){
    try{$candidate=([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"');if(Test-NobetaOwned $candidate){$GameRoot=$candidate}}catch{}
}
if(-not(Test-NobetaOwned $GameRoot)){
    Write-Host '  No Hub-owned Little Witch Nobeta VR installation was found.' -ForegroundColor Yellow
    Finish-Nobeta 0
}
if(Get-Process -Name 'LittleWitchNobeta' -ErrorAction SilentlyContinue){
    Write-Host '  Close Little Witch Nobeta before removing the VR mod.' -ForegroundColor Red
    Finish-Nobeta 1
}
if(-not $HubConfirmed){
    $answer=([string](Read-Host "Remove Hub-owned NobetaVR files from '$GameRoot'? Type REMOVE")).Trim()
    if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-Nobeta 0}
}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'nobetavr'
if(-not $result.Found){throw 'The NobetaVR ownership manifest disappeared before removal.'}
if($result.Preserved -eq 0){
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt){
        try{if([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -eq [IO.Path]::GetFullPath($GameRoot)){Remove-Item -LiteralPath $receipt -Force}}catch{}
    }
}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed files." -ForegroundColor Green
Write-Host '  Game files, saves, settings and unrelated BepInEx plugins remain.' -ForegroundColor Gray
Finish-Nobeta 0
