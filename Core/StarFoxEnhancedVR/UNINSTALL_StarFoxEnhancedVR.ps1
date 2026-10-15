param([switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-StarFoxRemove([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
try{
    $roots=@()
    $saved=Get-PCVRRememberedGameFolder -GameId 'star-fox-enhanced-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('LAUNCH-PCVR.bat')
    if($saved){$roots+=@($saved)}
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $receipt -PathType Leaf){$roots+=@(([IO.File]::ReadAllText($receipt)).Trim())}
    foreach($candidate in @($roots|Where-Object{$_}|Select-Object -Unique)){
        try{
            $full=[IO.Path]::GetFullPath($candidate).TrimEnd([char[]]'\/')
            if((Split-Path -Leaf $full) -cne 'Star Fox Enhanced PCVR'){continue}
            if(-not(Test-Path -LiteralPath (Join-Path $full '.pcvrhub_starfoxenhanced_ownership.csv') -PathType Leaf)){continue}
            $item=Get-Item -LiteralPath $full -Force
            if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){continue}
            $root=$full;break
        }catch{}
    }
    if(-not $root){throw 'No Hub-owned Star Fox Enhanced PCVR folder was found. Nothing was removed.'}
    if(Get-Process -Name starfox_pcvr -ErrorAction SilentlyContinue){throw 'Close Star Fox Enhanced PCVR first.'}
    if(-not $HubConfirmed){$answer=(''+(Read-Host "Remove Hub-owned PCVR files from '$root'? Type REMOVE")).Trim();if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-StarFoxRemove 0}}
    $result=Uninstall-OwnedModPayload -GameRoot $root -Identity 'starfoxenhanced'
    if(-not $result.Found){throw 'The ownership manifest vanished before removal.'}
    Remove-Item -LiteralPath (Join-Path $root '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if(Test-Path -LiteralPath $receipt -PathType Leaf){Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue}
    Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
    Write-Host 'Your ROM stays untouched. Generated assets, VR saves, settings and optional music remain for review.' -ForegroundColor Gray
    Finish-StarFoxRemove 0
}catch{Write-Host "[X] $($_.Exception.Message)" -ForegroundColor Red;Finish-StarFoxRemove 1}
