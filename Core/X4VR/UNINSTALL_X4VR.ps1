param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-X4Removal([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit' | Out-Null};exit $Code}
function Test-X4Owned([string]$Path){
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'X4.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_x4vr_ownership.csv') -PathType Leaf))
}
if(-not(Test-X4Owned $GameRoot)){
    try{$candidate=([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"');if(Test-X4Owned $candidate){$GameRoot=$candidate}}catch{}
}
if(-not(Test-X4Owned $GameRoot)){Write-Host '  No Hub-owned X4 VR installation was found.' -ForegroundColor Yellow;Finish-X4Removal 0}
if(Get-Process -Name X4,X4VRLauncher -ErrorAction SilentlyContinue){Write-Host '  Close X4 and X4VRLauncher before removal.' -ForegroundColor Red;Finish-X4Removal 1}
if(-not $HubConfirmed){
    $answer=([string](Read-Host "Remove Hub-owned X4 VR files from '$GameRoot'? Type REMOVE")).Trim()
    if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-X4Removal 0}
}
$releasePath=[IO.Path]::GetFullPath((Join-Path $GameRoot 'X4_VR\build\Release')).TrimEnd('\','/')
$regKey='HKCU:\Software\FreeTrack\FreeTrackClient'
$current=$null
try{$current=[string](Get-ItemProperty -Path $regKey -Name Path -ErrorAction Stop).Path}catch{}
$currentPath=$null
if($current){try{$currentPath=[IO.Path]::GetFullPath($current).TrimEnd('\','/')}catch{}}
if($currentPath -and $currentPath -ieq $releasePath){
    $backup=Join-Path $GameRoot 'X4_VR\config\freetrack-path.backup'
    if(Test-Path -LiteralPath $backup -PathType Leaf){
        $prior=([IO.File]::ReadAllText($backup)).Trim()
        if($prior){Set-ItemProperty -Path $regKey -Name Path -Value $prior -ErrorAction Stop}
        else{Remove-ItemProperty -Path $regKey -Name Path -ErrorAction Stop}
    } else {Remove-ItemProperty -Path $regKey -Name Path -ErrorAction Stop}
    if(Test-Path -LiteralPath $backup -PathType Leaf){Remove-Item -LiteralPath $backup -Force -ErrorAction Stop}
    Write-Host '  Previous FreeTrack path restored or the VR path removed.' -ForegroundColor Green
} elseif($current){Write-Host '  A different FreeTrack path is active and was left unchanged.' -ForegroundColor Gray}
$hud=Join-Path $GameRoot 'extensions\x4vr_hud'
if((Test-Path -LiteralPath (Join-Path $hud 'x4vr_hud.txt') -PathType Leaf) -and
    ([IO.Path]::GetFullPath($hud).StartsWith(([IO.Path]::GetFullPath($GameRoot).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase))){
    Remove-Item -LiteralPath $hud -Recurse -Force -ErrorAction Stop
    Write-Host '  Removed the publisher-marked generated HUD extension.' -ForegroundColor Green
}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'x4vr'
if(-not $result.Found){throw 'X4 VR ownership record disappeared before removal.'}
if($result.Preserved -eq 0){
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt -PathType Leaf){
        try{if([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -ieq [IO.Path]::GetFullPath($GameRoot)){Remove-Item -LiteralPath $receipt -Force}}catch{}
    }
}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed files." -ForegroundColor Green
Write-Host '  X4, saves, settings and unrelated extensions remain.' -ForegroundColor Gray
Finish-X4Removal 0
