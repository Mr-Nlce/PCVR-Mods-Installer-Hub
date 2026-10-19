param([switch]$HubConfirmed,[switch]$NoPause,[string]$GameRoot='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-B2S([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
try{
    $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_B2S_TEST_RECEIPT){$env:PCVR_B2S_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
    if(-not $GameRoot -and (Test-Path -LiteralPath $receipt -PathType Leaf)){$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}
    if(-not $GameRoot){throw 'No Hub-installed Beyond VR folder was recorded.'}
    $root=[IO.Path]::GetFullPath($GameRoot)
    if($env:PCVR_HUB_TEST_MODE -eq '1'){$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\';if(-not $root.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root 'b2s-test-fixture.txt') -PathType Leaf)){throw 'Beyond removal test root is outside its fixture.'}}
    if(-not((Test-Path -LiteralPath (Join-Path $root 'BeyondTwoSouls_Steam.exe') -PathType Leaf) -or (Test-Path -LiteralPath (Join-Path $root 'BeyondTwoSouls.exe') -PathType Leaf))){throw 'The selected folder is not Beyond: Two Souls.'}
    if(-not(Test-Path -LiteralPath (Join-Path $root '.pcvrhub_b2svr_ownership.csv') -PathType Leaf)){throw 'No Hub-owned Beyond VR installation was found.'}
    if(Get-Process -Name 'BeyondTwoSouls','BeyondTwoSouls_Steam' -ErrorAction SilentlyContinue){throw 'Close Beyond: Two Souls before removal.'}
    if(-not $HubConfirmed){if((Read-Host "Remove Hub-owned Beyond VR files from '$root'? Type REMOVE") -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-B2S 0}}
    $r=Uninstall-OwnedModPayload -GameRoot $root -Identity 'b2svr';if(-not $r.Found){throw 'The Beyond VR ownership list vanished.'}
    if($r.Preserved -gt 0){$manifest=Join-Path $root '.pcvrhub_b2svr_ownership.csv';if(Test-Path -LiteralPath $manifest -PathType Leaf){Move-Item -LiteralPath $manifest -Destination (Join-Path $root '.pcvrhub_b2svr_preserved.csv') -Force}}
    Remove-Item -LiteralPath (Join-Path $root '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if((Test-Path -LiteralPath $receipt -PathType Leaf) -and ([IO.File]::ReadAllText($receipt)).Trim() -ieq $root){Remove-Item -LiteralPath $receipt -Force}
    Write-Host "[OK] Removed $($r.Removed); restored $($r.Restored); preserved $($r.Preserved) changed file(s)." -ForegroundColor Green
    Write-Host 'The original game, saves, personal VR settings and logs remain.' -ForegroundColor Gray
    Finish-B2S 0
}catch{Write-Host "[X] $($_.Exception.Message)" -ForegroundColor Red;Finish-B2S 1}
