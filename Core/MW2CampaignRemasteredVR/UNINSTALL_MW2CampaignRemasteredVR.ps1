param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$id='modern-warfare-2-campaign-remastered-vr'
$game=if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_MW2_TEST_GAME){[IO.Path]::GetFullPath($env:PCVR_MW2_TEST_GAME)}else{
    Get-PCVRRememberedGameFolder -GameId $id -StateNames @('installed_path','user_located','base_game_path') -ProbeFiles @('MW2CR.exe')
}
if(-not $game -or -not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_mw2overlord_ownership.csv') -PathType Leaf)){throw 'No Hub-owned Overlord VR installation was found.'}
if(Get-Process -Name MW2CR,overlord -ErrorAction SilentlyContinue){throw 'Close the game and Overlord before removal.'}
if(-not $HubConfirmed -and (Read-Host "Remove Hub-owned Overlord VR files from '$game'? Type REMOVE") -cne 'REMOVE'){exit 0}
$result=Uninstall-OwnedModPayload -GameRoot $game -Identity 'mw2overlord'
if(-not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_mw2overlord_ownership.csv') -PathType Leaf)){
    foreach($path in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))){
        if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force -ErrorAction Stop}
    }
}
Write-Host "  [OK] Overlord files removed: $($result.Removed); earlier files restored: $($result.Restored)." -ForegroundColor Green
if($result.Preserved -gt 0){Write-Host "  Changed files preserved: $($result.Preserved)." -ForegroundColor Yellow}
Write-Host '  Battle.net game files, saves and unrelated files remain.' -ForegroundColor Gray
