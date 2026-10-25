param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$previousLibraryMode=$env:PCVR_EVR_LIBRARY_ONLY
try{$env:PCVR_EVR_LIBRARY_ONLY='1';. (Join-Path $PSScriptRoot 'EnshroudedVR-core.ps1')}
finally{$env:PCVR_EVR_LIBRARY_ONLY=$previousLibraryMode}
$game=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_EVR_TEST_GAME){$env:PCVR_EVR_TEST_GAME}else{
    Get-PCVRRememberedGameFolder -GameId 'enshrouded-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('enshrouded.exe')
}
if(-not $game){$game=Find-SteamGameFolder -AppId '1203620' -SteamFolderNames @('Enshrouded') -ProbeExe 'enshrouded.exe' -HubGameId 'enshrouded-vr'}
if(-not $game -or -not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_enshroudedvr_ownership.csv') -PathType Leaf)){
    throw 'No Hub-owned Enshrouded VR installation was found.'
}
if($env:PCVR_HUB_TEST_MODE -ne '1' -and (Get-Process -Name enshrouded -ErrorAction SilentlyContinue)){throw 'Close Enshrouded before removing VR.'}
if(-not $HubConfirmed -and (Read-Host "Remove Hub-owned Enshrouded VR from '$game'? Type REMOVE") -cne 'REMOVE'){exit 0}
[void](Get-EVRPublisherOwnedUpdates -Game $game -SyncOwnership)
$result=Uninstall-OwnedModPayload -GameRoot $game -Identity 'enshroudedvr'
if(-not(Test-Path -LiteralPath (Join-Path $game 'dinput8.dll') -PathType Leaf)){
    foreach($p in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))){
        if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force}
    }
}
Write-Host "  [OK] Enshrouded VR files removed: $($result.Removed); earlier files restored: $($result.Restored)." -ForegroundColor Green
if($result.Preserved -gt 0){Write-Host "  Locally changed files kept: $($result.Preserved)." -ForegroundColor Yellow}
Write-Host '  Your game, saves, personal settings and unrelated files remain.' -ForegroundColor Gray
