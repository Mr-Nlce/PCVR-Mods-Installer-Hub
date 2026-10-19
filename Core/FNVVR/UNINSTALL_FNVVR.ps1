param([switch]$HubConfirmed,[switch]$NoPause,[string]$GameRoot='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-FNV([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
try{
    $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_FNV_TEST_RECEIPT){$env:PCVR_FNV_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
    if(-not $GameRoot -and (Test-Path -LiteralPath $receipt -PathType Leaf)){$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}
    if(-not $GameRoot){throw 'No Hub-installed FNVVR folder was recorded.'}
    $root=[IO.Path]::GetFullPath($GameRoot)
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
        if(-not $root.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root 'fnvvr-test-fixture.txt') -PathType Leaf)){throw 'FNVVR removal test root is outside its fixture.'}
    }
    foreach($f in @('FalloutNV.exe','Data\FalloutNV.esm','.pcvrhub_fnvvr_ownership.csv')){if(-not(Test-Path -LiteralPath (Join-Path $root $f) -PathType Leaf)){throw "FNVVR removal needs $f."}}
    if(Get-Process -Name 'FalloutNV' -ErrorAction SilentlyContinue){throw 'Close Fallout: New Vegas before removal.'}
    if(-not $HubConfirmed){if((Read-Host "Remove Hub-owned FNVVR files from '$root'? Type REMOVE") -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-FNV 0}}
    $r=Uninstall-OwnedModPayload -GameRoot $root -Identity 'fnvvr';if(-not $r.Found){throw 'The FNVVR ownership list vanished.'}
    if($r.Preserved -gt 0){$manifest=Join-Path $root '.pcvrhub_fnvvr_ownership.csv';if(Test-Path -LiteralPath $manifest -PathType Leaf){Move-Item -LiteralPath $manifest -Destination (Join-Path $root '.pcvrhub_fnvvr_preserved.csv') -Force}}
    Remove-Item -LiteralPath (Join-Path $root '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if((Test-Path -LiteralPath $receipt -PathType Leaf) -and ([IO.File]::ReadAllText($receipt)).Trim() -ieq $root){Remove-Item -LiteralPath $receipt -Force}
    Write-Host "[OK] Removed $($r.Removed); restored $($r.Restored); preserved $($r.Preserved) changed file(s)." -ForegroundColor Green
    Write-Host 'The base game, saves and personal VR settings remain.' -ForegroundColor Gray
    Finish-FNV 0
}catch{Write-Host "[X] $($_.Exception.Message)" -ForegroundColor Red;Finish-FNV 1}
