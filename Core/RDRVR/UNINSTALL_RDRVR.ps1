param([switch]$HubConfirmed,[switch]$NoPause,[string]$GameRoot='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-RdrRemove([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
try{
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        if(-not $GameRoot){$GameRoot=$env:PCVR_RDR_TEST_GAME}
        $full=[IO.Path]::GetFullPath($GameRoot)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
            -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $full) 'rdrvr-fixture.txt') -PathType Leaf)){
            throw 'RDRVR removal fixture is not isolated.'
        }
    }else{
        $receipt=Join-Path $PSScriptRoot '.installed_path'
        if(-not $GameRoot -and (Test-Path -LiteralPath $receipt -PathType Leaf)){$GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')}
        if(-not $GameRoot){throw 'No RDRVR game folder receipt exists. Locate the installed game before removal.'}
        $full=[IO.Path]::GetFullPath($GameRoot)
    }
    if(-not(Test-Path -LiteralPath (Join-Path $full 'RDR.exe') -PathType Leaf)){throw 'The selected folder is not a Red Dead Redemption game.'}
    $item=Get-Item -LiteralPath $full -Force
    if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'Linked game folders cannot be removed safely.'}
    $manifest=Join-Path $full '.pcvrhub_rdrvr_ownership.csv'
    if(-not(Test-Path -LiteralPath $manifest -PathType Leaf)){throw 'No Hub-owned RDRVR installation was found.'}
    if(($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_PROCESS_RUNNING -eq '1') -or
        ($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name 'RDR' -ErrorAction SilentlyContinue))){throw 'Close Red Dead Redemption before removal.'}
    if(-not $HubConfirmed){
        $answer=(''+(Read-Host "Remove Hub-owned RDRVR files from '$full'? Type REMOVE")).Trim()
        if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-RdrRemove 0}
    }
    $result=Uninstall-OwnedModPayload -GameRoot $full -Identity 'rdrvr'
    if(-not $result.Found){throw 'The RDRVR ownership list vanished before removal.'}
    if($result.Preserved -gt 0 -and (Test-Path -LiteralPath $manifest -PathType Leaf)){
        $preserved=Join-Path $full '.pcvrhub_rdrvr_preserved.csv'
        if(Test-Path -LiteralPath $preserved){throw 'An older preserved-file list needs review before removal can finish.'}
        Move-Item -LiteralPath $manifest -Destination $preserved -ErrorAction Stop
    }
    Remove-Item -LiteralPath (Join-Path $full '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_RDR_TEST_RECEIPT){
        [IO.Path]::GetFullPath($env:PCVR_RDR_TEST_RECEIPT)
    }else{Join-Path $PSScriptRoot '.installed_path'}
    if(Test-Path -LiteralPath $receipt -PathType Leaf){
        if(([IO.File]::ReadAllText($receipt)).Trim() -ieq $full){Remove-Item -LiteralPath $receipt -Force}
    }
    Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
    Write-Host 'The game, RedHook and personal headset settings remain.' -ForegroundColor Gray
    Finish-RdrRemove 0
}catch{Write-Host "[X] $($_.Exception.Message)" -ForegroundColor Red;Finish-RdrRemove 1}
