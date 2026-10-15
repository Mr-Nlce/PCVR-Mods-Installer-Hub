param([switch]$HubConfirmed,[switch]$NoPause,[string]$GameRoot='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-SpidyRemove([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
try{
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        if(-not $GameRoot){$GameRoot=$env:PCVR_SPIDY_TEST_ROOT}
        $full=[IO.Path]::GetFullPath($GameRoot)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
        if(-not $full.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or
            -not(Test-Path -LiteralPath (Join-Path (Split-Path -Parent $full) 'spidy-fixture.txt') -PathType Leaf)){
            throw 'Spidy removal fixture is not isolated.'
        }
    }else{
        $allowed=@((Join-Path $env:LOCALAPPDATA 'SpidyVR'),'D:\Games\SpidyVR','E:\Games\SpidyVR')
        $receipt=Join-Path $PSScriptRoot '.installed_path'
        $recorded=if(Test-Path -LiteralPath $receipt -PathType Leaf){([IO.File]::ReadAllText($receipt)).Trim()}else{''}
        $candidates=if($GameRoot){@($GameRoot)}elseif($recorded -and
            @($allowed|Where-Object {$_ -ieq $recorded}).Count -eq 1 -and
            (Test-Path -LiteralPath (Join-Path $recorded '.pcvrhub_spidy_ownership.csv') -PathType Leaf)){
            @($recorded)
        }else{@($allowed)}
        $full=$null
        foreach($candidate in $candidates){
            if(-not $candidate){continue}
            $path=[IO.Path]::GetFullPath($candidate)
            if(@($allowed|Where-Object {$_ -ieq $path}).Count -eq 0){continue}
            if(Test-Path -LiteralPath (Join-Path $path '.pcvrhub_spidy_ownership.csv') -PathType Leaf){
                if($full -and $full -ine $path){throw 'Several Spidy installs were found. Select one explicitly.'}
                $full=$path
            }
        }
        if(-not $full){throw 'No Hub-owned Spidy installation was found in its allowed launcher locations.'}
    }
    $manifest=Join-Path $full '.pcvrhub_spidy_ownership.csv'
    if(-not(Test-Path -LiteralPath $manifest -PathType Leaf)){throw 'No Hub-owned Spidy installation was found.'}
    $item=Get-Item -LiteralPath $full -Force
    if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'Linked Spidy folders cannot be removed safely.'}
    if(($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SPIDY_TEST_PROCESS_RUNNING -eq '1') -or
        ($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name @('Spider-Man','Spidy Launcher') -ErrorAction SilentlyContinue))){
        throw 'Close Spider-Man and Spidy Launcher before removal.'
    }
    if(-not $HubConfirmed){
        $answer=(''+(Read-Host "Remove Hub-owned Spidy files from '$full'? Type REMOVE")).Trim()
        if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-SpidyRemove 0}
    }
    $result=Uninstall-OwnedModPayload -GameRoot $full -Identity 'spidy'
    if(-not $result.Found){throw 'The Spidy ownership list vanished before removal.'}
    if($result.Preserved -gt 0 -and (Test-Path -LiteralPath $manifest)){
        $preserved=Join-Path $full '.pcvrhub_spidy_preserved.csv'
        if(Test-Path -LiteralPath $preserved){throw 'An older preserved-file list needs review before removal can finish.'}
        Move-Item -LiteralPath $manifest -Destination $preserved -ErrorAction Stop
    }
    Remove-Item -LiteralPath (Join-Path $full '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_SPIDY_TEST_RECEIPT){
        [IO.Path]::GetFullPath($env:PCVR_SPIDY_TEST_RECEIPT)
    }else{Join-Path $PSScriptRoot '.installed_path'}
    if(Test-Path -LiteralPath $receipt -PathType Leaf){
        if(([IO.File]::ReadAllText($receipt)).Trim() -ieq $full){Remove-Item -LiteralPath $receipt -Force -ErrorAction Stop}
    }
    Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
    Write-Host 'Steam game, other VR mod, reports and preferences remain.' -ForegroundColor Gray
    Finish-SpidyRemove 0
}catch{Write-Host "[X] $($_.Exception.Message)" -ForegroundColor Red;Finish-SpidyRemove 1}
