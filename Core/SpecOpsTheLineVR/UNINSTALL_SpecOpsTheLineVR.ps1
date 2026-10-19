param([switch]$HubConfirmed,[switch]$NoPause,[string]$GameRoot='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-Spec([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
try{
    $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SPECOPS_TEST_RECEIPT){$env:PCVR_SPECOPS_TEST_RECEIPT}else{Join-Path $PSScriptRoot '.installed_path'}
    if(-not $GameRoot -and (Test-Path -LiteralPath $receipt -PathType Leaf)){$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}
    if(-not $GameRoot){throw 'No Hub-installed Spec Ops VR folder was recorded.'}
    $root=[IO.Path]::GetFullPath($GameRoot)
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        $tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+'\'
        if(-not $root.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $root 'specops-fixture.txt') -PathType Leaf)){throw 'Spec Ops removal test root is outside its fixture.'}
    }
    $runtime=Join-Path $root 'Binaries\Win32'
    foreach($f in @('SpecOpsTheLine.exe','.pcvrhub_specopsvr_ownership.csv')){if(-not(Test-Path -LiteralPath (Join-Path $runtime $f) -PathType Leaf)){throw "Spec Ops removal needs $f."}}
    if(Get-Process -Name 'SpecOpsTheLine' -ErrorAction SilentlyContinue){throw 'Close Spec Ops: The Line before removal.'}
    if(-not $HubConfirmed){if((Read-Host "Remove Hub-owned Spec Ops VR files from '$root'? Type REMOVE") -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-Spec 0}}
    $r=Uninstall-OwnedModPayload -GameRoot $runtime -Identity 'specopsvr';if(-not $r.Found){throw 'The Spec Ops VR ownership record vanished.'}
    if($r.Preserved -gt 0){$manifest=Join-Path $runtime '.pcvrhub_specopsvr_ownership.csv';if(Test-Path -LiteralPath $manifest -PathType Leaf){Move-Item -LiteralPath $manifest -Destination (Join-Path $runtime '.pcvrhub_specopsvr_preserved.csv') -Force}}
    Remove-Item -LiteralPath (Join-Path $root '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if((Test-Path -LiteralPath $receipt -PathType Leaf) -and ([IO.File]::ReadAllText($receipt)).Trim() -ieq $root){Remove-Item -LiteralPath $receipt -Force}
    Write-Host "[OK] Removed $($r.Removed); restored $($r.Restored); preserved $($r.Preserved) changed file(s)." -ForegroundColor Green
    if($r.Preserved -gt 0){Write-Host 'Changed VR files were kept. Review them before deleting; the game is not marked VR Ready.' -ForegroundColor Yellow}
    Write-Host 'The base game, saves, logs and Steam launch options were not changed.' -ForegroundColor Gray
    Finish-Spec 0
}catch{Write-Host "[X] $($_.Exception.Message)" -ForegroundColor Red;Finish-Spec 1}
