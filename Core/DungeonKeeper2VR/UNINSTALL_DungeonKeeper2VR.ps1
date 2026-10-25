param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$game=if($env:PCVR_DK2_TEST_GAME){[IO.Path]::GetFullPath($env:PCVR_DK2_TEST_GAME)}else{Get-PCVRRememberedGameFolder -GameId 'dungeon-keeper-2-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('DKII-DX.exe')}
if(-not $game -or -not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_dk2vr_ownership.csv') -PathType Leaf)){throw 'No Hub-owned Dungeon Keeper 2 VR installation was found.'}
if(Get-Process -Name 'DKII-DX','DKII','DK2VRHost' -ErrorAction SilentlyContinue){throw 'Close Dungeon Keeper 2 before removing its VR mod.'}
if(-not $HubConfirmed -and (Read-Host "Remove Hub-owned Dungeon Keeper 2 VR from '$game'? Type REMOVE") -cne 'REMOVE'){exit 0}
$result=Uninstall-OwnedModPayload -GameRoot $game -Identity 'dk2vr'
if(-not(Test-Path -LiteralPath (Join-Path $game 'DK2VR\payload\DK2VR.dll') -PathType Leaf)){
    foreach($path in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))){if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force}}
}
Write-Host "  [OK] Removed $($result.Removed) unchanged Hub-owned files; restored $($result.Restored) earlier files." -ForegroundColor Green
if($result.Preserved){Write-Host "  Kept $($result.Preserved) locally changed files." -ForegroundColor Yellow}
Write-Host 'Your original game, saves and settings remain.' -ForegroundColor White
