param([string]$GameRoot='', [string]$StateRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$IDENTITY='slimeranchervr';$GAME_EXE='SlimeRancher.exe'

function Finish-SRVR([int]$Code){if(-not$NoPause){Write-Host '';Read-Host 'Press Enter to exit'|Out-Null};exit $Code}
function Test-SRVRRoot([string]$Path){return [bool]($Path-and(Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf))}

try{
    if(-not$StateRoot){$StateRoot=$PSScriptRoot}
    if(-not(Test-SRVRRoot $GameRoot)){try{$saved=([IO.File]::ReadAllText((Join-Path $StateRoot '.installed_path'))).Trim();if(Test-SRVRRoot $saved){$GameRoot=$saved}}catch{}}
    if(-not(Test-SRVRRoot $GameRoot)){$GameRoot=Find-SteamGameFolder -AppId '433340' -SteamFolderNames @('Slime Rancher') -ProbeExe $GAME_EXE -GogNames @('Slime Rancher') -EpicNames @('SlimeRancher') -HubGameId 'slime-rancher-vr'}
    if(-not(Test-SRVRRoot $GameRoot)){Write-Host '[X] Slime Rancher was not found. No files were changed.' -ForegroundColor Red;Finish-SRVR 1}
    if(-not$HubConfirmed){$answer=(''+(Read-Host "Remove SRVR from '$GameRoot'? Type REMOVE")).Trim();if($answer-cne'REMOVE'){Write-Host 'Cancelled. Nothing changed.';Finish-SRVR 0}}

    $manifest=Join-Path $GameRoot ".pcvrhub_${IDENTITY}_ownership.csv"
    $removed=0;$restored=0;$preserved=0
    if(Test-Path -LiteralPath $manifest -PathType Leaf){
        $result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $IDENTITY
        if(-not$result.Found){throw 'The ownership record disappeared before removal.'}
        $removed=[int]$result.Removed;$restored=[int]$result.Restored;$preserved=[int]$result.Preserved
    }else{
        $legacy=Join-Path $GameRoot 'SRML\Mods\SRVR.dll'
        $legacySha='5E45BDE8CC6402692248E2A9005CBC12D8C7A637F6FB5C5C276222F5C66480E7'
        if(-not(Test-Path -LiteralPath $legacy -PathType Leaf)){throw 'No Hub ownership record or legacy SRVR.dll was found.'}
        if((Get-FileHash -LiteralPath $legacy -Algorithm SHA256).Hash-ne$legacySha){throw 'SRVR.dll is changed or unknown. Nothing was deleted by guesswork.'}
        Remove-Item -LiteralPath $legacy -Force -ErrorAction Stop
        $removed=1
    }

    if($preserved-eq0){
        foreach($name in @('.pcvrhub_version','.pcvrhub.install.json')){Remove-Item -LiteralPath (Join-Path $GameRoot $name) -Force -ErrorAction SilentlyContinue}
        foreach($name in @('.installed_path','.installed_version')){Remove-Item -LiteralPath (Join-Path $StateRoot $name) -Force -ErrorAction SilentlyContinue}
    }
    Write-Host " [OK] Removed $removed, restored $restored, preserved $preserved changed file(s)." -ForegroundColor Green
    Write-Host ' [KEEP] SRML, other SRML mods, saves and configuration were retained.' -ForegroundColor Gray
    Finish-SRVR 0
}catch{Write-Host '[X] Slime Rancher VR could not be removed safely.' -ForegroundColor Red;Write-Host "    $($_.Exception.Message)" -ForegroundColor Yellow;Finish-SRVR 1}
