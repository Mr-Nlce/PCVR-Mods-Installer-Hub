param([switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-MarioRemove([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
try{
    $candidates=@()
    $saved=Get-PCVRRememberedGameFolder -GameId 'super-mario-3d-world-vr' -StateNames @('cemu_path') -ProbeFiles @('Cemu.exe')
    if($saved){$candidates+=@(Join-Path $saved 'Mario3DWorld-VR')}
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt -PathType Leaf){$candidates+=@(([IO.File]::ReadAllText($receipt)).Trim())}
    foreach($candidate in @($candidates|Where-Object{$_}|Select-Object -Unique)){
        try{
            $full=[IO.Path]::GetFullPath($candidate).TrimEnd([char[]]'\/')
            if((Split-Path -Leaf $full) -cne 'Mario3DWorld-VR'){continue}
            $cemu=Split-Path -Parent $full
            if(-not(Test-Path -LiteralPath (Join-Path $cemu 'Cemu.exe') -PathType Leaf)){continue}
            if(-not(Test-Path -LiteralPath (Join-Path $full '.pcvrhub_sm3dwvr_ownership.csv') -PathType Leaf)){continue}
            $item=Get-Item -LiteralPath $full -Force
            if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){continue}
            $root=$full;break
        }catch{}
    }
    if(-not $root){throw 'No Hub-owned Mario 3D World VR folder was found. Nothing was removed.'}
    if(Get-Process -Name Cemu -ErrorAction SilentlyContinue){throw 'Close Cemu and its VR launcher first.'}
    if(-not $HubConfirmed){$answer=(''+(Read-Host "Remove Hub-owned VR files from '$root'? Type REMOVE")).Trim();if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-MarioRemove 0}}
    $result=Uninstall-OwnedModPayload -GameRoot $root -Identity 'sm3dwvr'
    if(-not $result.Found){throw 'The ownership manifest vanished before removal.'}
    Remove-Item -LiteralPath (Join-Path $root '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if(Test-Path -LiteralPath $receipt -PathType Leaf){Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue}
    Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
    Write-Host 'Your Wii U game, Cemu, saves and unrelated graphic packs remain.' -ForegroundColor Gray
    Finish-MarioRemove 0
}catch{Write-Host "[X] $($_.Exception.Message)" -ForegroundColor Red;Finish-MarioRemove 1}
