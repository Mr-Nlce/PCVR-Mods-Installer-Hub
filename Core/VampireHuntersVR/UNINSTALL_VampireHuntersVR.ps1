param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$game=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_VH_TEST_GAME){$env:PCVR_VH_TEST_GAME}else{
    Get-PCVRRememberedGameFolder -GameId 'vampire-hunters-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('Vampire Hunters.exe','UnityPlayer.dll','GameAssembly.dll')
}
if(-not $game){$game=Find-SteamGameFolder -AppId '2206270' -SteamFolderNames @('Vampire Hunters') -ProbeExe 'Vampire Hunters.exe' -HubGameId 'vampire-hunters-vr'}
if(-not $game -or -not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_vampirehuntersvr_ownership.csv') -PathType Leaf)){
    throw 'No Hub-owned Vampire Hunters VR plugin was found.'
}
if(Get-Process -Name 'Vampire Hunters' -ErrorAction SilentlyContinue){throw 'Close Vampire Hunters before removing VR.'}
if(-not $HubConfirmed -and (Read-Host "Remove Hub-owned Vampire Hunters VR from '$game'? Type REMOVE") -cne 'REMOVE'){exit 0}
$mod=Uninstall-OwnedModPayload -GameRoot $game -Identity 'vampirehuntersvr'
$loader=$null
if(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_vhbepinex_ownership.csv') -PathType Leaf){
    $loader=Uninstall-OwnedModPayload -GameRoot $game -Identity 'vhbepinex'
}
if(-not(Test-Path -LiteralPath (Join-Path $game 'BepInEx\plugins\VampireHuntersVR\VampireHuntersVR.dll') -PathType Leaf)){
    foreach($p in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))){
        if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force}
    }
}
Write-Host "  [OK] VR plugin files removed: $($mod.Removed); earlier files restored: $($mod.Restored)." -ForegroundColor Green
if($loader){Write-Host "  Hub-owned BepInEx files removed: $($loader.Removed); earlier files restored: $($loader.Restored)." -ForegroundColor Green}
if($mod.Preserved -gt 0 -or ($loader -and $loader.Preserved -gt 0)){Write-Host '  Locally changed files and generated settings were kept.' -ForegroundColor Yellow}
Write-Host '  The game, saves, user settings and unrelated mods remain.' -ForegroundColor Gray
