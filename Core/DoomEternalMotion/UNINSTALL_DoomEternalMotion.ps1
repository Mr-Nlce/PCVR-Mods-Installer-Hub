param([ValidateSet('','argent','eternal')][string]$Mod='',[switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$script:GameId='doom-eternal-motion-vr'
$script:Slots=@{
    argent=@{Folder='ARGENT';Identity='doomargent';State='mod_a_path';Receipt='.installed_path_a';Version='.pcvrhub_version';Launcher='ArgentLauncher.exe'}
    eternal=@{Folder='EternalVR';Identity='doometernalvr';State='mod_b_path';Receipt='.installed_path_b';Version='.pcvrhub_version_b';Launcher='EternalVR.Launcher.exe'}
}
function Finish-DoomRemove([int]$Code){if(-not $NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Get-DoomRemovalRoot([hashtable]$Slot){
    $candidates=@()
    $saved=Get-PCVRRememberedGameFolder -GameId $script:GameId -StateNames @([string]$Slot.State) -ProbeFiles @()
    if($saved){$candidates+=@($saved)}
    $receipt=Join-Path $PSScriptRoot ([string]$Slot.Receipt)
    if(Test-Path -LiteralPath $receipt -PathType Leaf){try{$candidates+=@(([IO.File]::ReadAllText($receipt)).Trim())}catch{}}
    foreach($drive in @('C:','D:','E:')){
        $games=[IO.Path]::Combine(($drive+'\'),'Games')
        if(-not(Test-Path -LiteralPath $games -PathType Container)){continue}
        $candidates+=@([IO.Path]::Combine($games,'DOOM Eternal VR',[string]$Slot.Folder))
    }
    foreach($candidate in @($candidates|Where-Object{$_}|Select-Object -Unique)){
        try{
            $full=[IO.Path]::GetFullPath($candidate).TrimEnd([char[]]'\/')
            if((Split-Path -Leaf $full) -cne [string]$Slot.Folder -or (Split-Path -Leaf (Split-Path -Parent $full)) -cne 'DOOM Eternal VR'){continue}
            if(-not(Test-Path -LiteralPath (Join-Path $full ('.pcvrhub_'+$Slot.Identity+'_ownership.csv')) -PathType Leaf)){continue}
            $item=Get-Item -LiteralPath $full -Force
            if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){continue}
            return $full
        }catch{}
    }
    return $null
}
try{
    if(-not $Mod){
        Write-Host 'DOOM Eternal Motion VR - remove one launcher' -ForegroundColor Cyan
        Write-Host '[1] KHARVOX: ARGENT' -ForegroundColor White
        Write-Host '[2] EternalVR' -ForegroundColor White
        $choice=(''+(Read-Host 'Choose 1, 2 or Q')).Trim().ToLowerInvariant()
        if($choice -eq '1'){$Mod='argent'}elseif($choice -eq '2'){$Mod='eternal'}elseif($choice -in @('q','quit')){Finish-DoomRemove 0}else{throw 'Choose [1], [2] or [Q].'}
    }
    $slot=$script:Slots[$Mod]
    $root=Get-DoomRemovalRoot -Slot $slot
    if(-not $root){throw "No Hub-owned $($slot.Folder) installation was found. Nothing was removed."}
    if(Get-Process -Name @('DOOMEternalx64vk','ArgentLauncher','EternalVR.Launcher') -ErrorAction SilentlyContinue){throw 'Close DOOM Eternal and both VR launchers first.'}
    if(-not $HubConfirmed){$answer=(''+(Read-Host "Remove Hub-owned $($slot.Folder) files from '$root'? Type REMOVE")).Trim();if($answer -cne 'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-DoomRemove 0}}
    $result=Uninstall-OwnedModPayload -GameRoot $root -Identity ([string]$slot.Identity)
    if(-not $result.Found){throw 'The selected ownership manifest vanished before removal.'}
    Remove-Item -LiteralPath (Join-Path $root ([string]$slot.Version)) -Force -ErrorAction SilentlyContinue
    $receipt=Join-Path $PSScriptRoot ([string]$slot.Receipt)
    if(Test-Path -LiteralPath $receipt -PathType Leaf){Remove-Item -LiteralPath $receipt -Force -ErrorAction SilentlyContinue}
    $generic=Join-Path $PSScriptRoot '.installed_path'
    if(Test-Path -LiteralPath $generic -PathType Leaf){
        $recorded=([IO.File]::ReadAllText($generic)).Trim()
        if($recorded -ieq $root){
            $other=if($Mod -eq 'argent'){'.installed_path_b'}else{'.installed_path_a'}
            $otherFile=Join-Path $PSScriptRoot $other
            if(Test-Path -LiteralPath $otherFile -PathType Leaf){Copy-Item -LiteralPath $otherFile -Destination $generic -Force}
            else{Remove-Item -LiteralPath $generic -Force}
        }
    }
    Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
    Write-Host 'The retail game, publisher settings and other VR launcher were not removed.' -ForegroundColor Gray
    Finish-DoomRemove 0
}catch{Write-Host "[X] $($_.Exception.Message)" -ForegroundColor Red;Finish-DoomRemove 1}
