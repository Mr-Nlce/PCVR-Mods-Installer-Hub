param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
function Finish-RTCW([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Get-RTCWFileSha256([string]$Path){
    $stream=[IO.File]::OpenRead($Path)
    $sha=[Security.Cryptography.SHA256]::Create()
    try{return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}
    finally{$sha.Dispose();$stream.Dispose()}
}
$receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RTCW_TEST_RECEIPT){$env:PCVR_RTCW_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
if(-not $GameRoot -and (Test-Path -LiteralPath $receipt -PathType Leaf)){$GameRoot=([IO.File]::ReadAllText($receipt)).Trim()}
if(-not $GameRoot -or -not(Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_rtcwxr_ownership.csv') -PathType Leaf)){
    Write-Host '  No Hub-owned RealRTCW XR installation was found.' -ForegroundColor Yellow;Finish-RTCW 0
}
$root=[IO.Path]::GetFullPath($GameRoot)
if(Get-Process -Name 'RealRTCWXR' -ErrorAction SilentlyContinue){Write-Host '  Close RealRTCW XR before removing it.' -ForegroundColor Red;Finish-RTCW 1}
if(-not $HubConfirmed){$answer=([string](Read-Host "Remove Hub-owned VR files from '$root'? Type REMOVE")).Trim();if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-RTCW 0}}
$manifest=Join-Path $root '.pcvrhub_rtcwxr_ownership.csv'
$removed=0;$preserved=0
foreach($row in @(Import-Csv -LiteralPath $manifest)){
    $rel=[string]$row.Path
    if(-not $rel -or [IO.Path]::IsPathRooted($rel) -or $rel -match '(^|[\\/])\.\.([\\/]|$)'){throw 'Unsafe ownership manifest path.'}
    $path=[IO.Path]::GetFullPath((Join-Path $root $rel))
    if(-not $path.StartsWith($root.TrimEnd([char[]]'\\/')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Ownership manifest leaves the VR folder.'}
    if(-not(Test-Path -LiteralPath $path -PathType Leaf)){continue}
    if((Get-RTCWFileSha256 $path) -ne [string]$row.Sha256){$preserved++;continue}
    Remove-Item -LiteralPath $path -Force;$removed++
}
if($preserved -eq 0){
    foreach($name in @('.pcvrhub_version','.pcvrhub_rtcwxr_bundle','.pcvrhub_rtcwxr_ownership.csv')){Remove-Item -LiteralPath (Join-Path $root $name) -Force -ErrorAction SilentlyContinue}
    if(Test-Path -LiteralPath $receipt -PathType Leaf){try{if([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -ieq $root){Remove-Item -LiteralPath $receipt -Force}}catch{}}
}
Write-Host "  [OK] Removed $removed unchanged VR files; preserved $preserved changed files." -ForegroundColor Green
Write-Host '  Original RTCW, copied game and RealRTCW data, settings and saves remain.' -ForegroundColor Gray
Finish-RTCW 0
