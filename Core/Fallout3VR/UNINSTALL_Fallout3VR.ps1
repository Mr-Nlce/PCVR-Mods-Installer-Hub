param([switch]$HubConfirmed,[switch]$NoPause,[string]$GameRoot='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-FO3([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
try{
    $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_FO3_TEST_RECEIPT){$env:PCVR_FO3_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
    if(-not $GameRoot -and (Test-Path -LiteralPath $receipt -PathType Leaf)){$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}
    if(-not $GameRoot){throw 'No Hub-installed Fallout 3 VR launcher was recorded.'}
    $root=[IO.Path]::GetFullPath($GameRoot)
    if($env:PCVR_HUB_TEST_MODE -eq '1'){$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\';if(-not $root.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root 'fo3vr-test-fixture.txt') -PathType Leaf)){throw 'Fallout 3 VR removal test root is outside its fixture.'}}
    foreach($f in @('THEwill_Fallout3_VR.exe','.pcvrhub_fo3vr_ownership.csv')){if(-not(Test-Path -LiteralPath (Join-Path $root $f) -PathType Leaf)){throw "Removal needs $f."}}
    if(Get-Process -Name 'Fallout3','THEwill_Fallout3_VR' -ErrorAction SilentlyContinue){throw 'Close Fallout 3 and its VR launcher before removal.'}
    if(-not $HubConfirmed){if((Read-Host "Remove Hub-owned Fallout 3 VR files from '$root'? Type REMOVE") -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-FO3 0}}
    $r=Uninstall-OwnedModPayload -GameRoot $root -Identity 'fo3vr';if(-not $r.Found){throw 'The Fallout 3 VR ownership list vanished.'}
    if($r.Preserved -gt 0){$manifest=Join-Path $root '.pcvrhub_fo3vr_ownership.csv';if(Test-Path -LiteralPath $manifest -PathType Leaf){Move-Item -LiteralPath $manifest -Destination (Join-Path $root '.pcvrhub_fo3vr_preserved.csv') -Force}}
    Remove-Item -LiteralPath (Join-Path $root '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if((Test-Path -LiteralPath $receipt -PathType Leaf) -and ([IO.File]::ReadAllText($receipt)).Trim() -ieq $root){Remove-Item -LiteralPath $receipt -Force}
    Write-Host "[OK] Removed $($r.Removed); restored $($r.Restored); preserved $($r.Preserved) changed file(s)." -ForegroundColor Green
    Write-Host 'The Steam game, saves and launcher session recovery files remain.' -ForegroundColor Gray
    Finish-FO3 0
}catch{Write-Host "[X] $($_.Exception.Message)" -ForegroundColor Red;Finish-FO3 1}
