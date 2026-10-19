param([switch]$HubConfirmed,[switch]$NoPause,[string]$GameRoot='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-KF2Remove([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
try {
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        if(-not $GameRoot){$GameRoot=$env:PCVR_KF2_TEST_ROOT}
        $root=[IO.Path]::GetFullPath($GameRoot)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $root.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
            -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $root) 'kf2-fixture.txt') -PathType Leaf)){
            throw 'KF2 removal fixture is not isolated.'
        }
    } else {
        $root=Join-Path $env:LOCALAPPDATA 'KF2VR'
        if($GameRoot -and [IO.Path]::GetFullPath($GameRoot) -ine [IO.Path]::GetFullPath($root)){
            throw 'Only the Hub-owned KF2VR launcher folder can be removed here.'
        }
    }
    if(-not(Test-Path -LiteralPath (Join-Path $root '.pcvrhub_kf2vr_ownership.csv') -PathType Leaf)){
        throw 'No Hub-owned GitHub KF2VR installation was found. Steam Workshop copies are removed in Steam.'
    }
    $item=Get-Item -LiteralPath $root -Force
    if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'Linked KF2VR folders cannot be removed safely.'}
    if($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name 'KFGame' -ErrorAction SilentlyContinue)){
        throw 'Close Killing Floor 2 before removing KF2VR.'
    }
    if(-not $HubConfirmed){
        $answer=(''+(Read-Host "Remove Hub-owned KF2VR files from '$root'? Type REMOVE")).Trim()
        if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-KF2Remove 0}
    }
    $result=Uninstall-OwnedModPayload -GameRoot $root -Identity 'kf2vr'
    if(-not $result.Found){throw 'The KF2VR ownership list vanished before removal.'}
    foreach($name in @('Start KF2VR.cmd','.pcvrhub_kf2vr_route','.pcvrhub_version')){
        $path=Join-Path $root $name
        if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force -ErrorAction Stop}
    }
    $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_KF2_TEST_RECEIPT){
        [IO.Path]::GetFullPath($env:PCVR_KF2_TEST_RECEIPT)
    }else{Join-Path $PSScriptRoot '.installed_path'}
    if(Test-Path -LiteralPath $receipt -PathType Leaf){
        if(([IO.File]::ReadAllText($receipt)).Trim() -ieq $root){Remove-Item -LiteralPath $receipt -Force -ErrorAction Stop}
    }
    Write-Host "[OK] Removed $($result.Removed) unchanged KF2VR file(s); preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
    Write-Host 'The original game, Workshop files, settings and previous release folders remain.' -ForegroundColor Gray
    Finish-KF2Remove 0
}catch{Write-Host "[X] $($_.Exception.Message)" -ForegroundColor Red;Finish-KF2Remove 1}
