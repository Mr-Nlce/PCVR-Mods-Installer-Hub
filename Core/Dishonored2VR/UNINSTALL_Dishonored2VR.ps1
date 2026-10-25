param([switch]$HubConfirmed,[switch]$NoPause,[string]$GameRoot='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-D2([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
try{
    $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_D2_TEST_RECEIPT){$env:PCVR_D2_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
    if(-not $GameRoot -and (Test-Path -LiteralPath $receipt -PathType Leaf)){$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}
    if(-not $GameRoot){throw 'No Hub-installed Dishonored 2 VR folder was recorded.'}
    $root=[IO.Path]::GetFullPath($GameRoot)
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
        if(-not $root.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root 'dishonored2-fixture.txt') -PathType Leaf)){throw 'Dishonored 2 removal test root is outside its fixture.'}
    }
    foreach($name in @('Dishonored2.exe','.pcvrhub_dishonored2vr_ownership.csv')){if(-not(Test-Path -LiteralPath (Join-Path $root $name) -PathType Leaf)){throw "Dishonored 2 removal needs $name."}}
    if(Get-Process -Name 'Dishonored2' -ErrorAction SilentlyContinue){throw 'Close Dishonored 2 before removal.'}
    if(-not $HubConfirmed){if((Read-Host "Remove Hub-owned Dishonored 2 VR files from '$root'? Type REMOVE") -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-D2 0}}
    $result=Uninstall-OwnedModPayload -GameRoot $root -Identity 'dishonored2vr';if(-not $result.Found){throw 'The Dishonored 2 VR ownership record vanished.'}
    if($result.Preserved -gt 0){$manifest=Join-Path $root '.pcvrhub_dishonored2vr_ownership.csv';if(Test-Path -LiteralPath $manifest -PathType Leaf){Move-Item -LiteralPath $manifest -Destination (Join-Path $root '.pcvrhub_dishonored2vr_preserved.csv') -Force}}
    Remove-Item -LiteralPath (Join-Path $root '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if((Test-Path -LiteralPath $receipt -PathType Leaf) -and ([IO.File]::ReadAllText($receipt)).Trim() -ieq $root){Remove-Item -LiteralPath $receipt -Force}
    Write-Host "[OK] Removed $($result.Removed); restored $($result.Restored); preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
    if($result.Preserved -gt 0){Write-Host 'Changed VR files remain for your review; the game is no longer marked VR Ready.' -ForegroundColor Yellow}
    Write-Host 'The Steam game, saves, logs and unrelated files remain.' -ForegroundColor Gray
    Finish-D2 0
}catch{Write-Host "[X] $($_.Exception.Message)" -ForegroundColor Red;Finish-D2 1}
