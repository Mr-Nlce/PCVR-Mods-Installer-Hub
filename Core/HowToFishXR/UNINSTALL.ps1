param([switch]$HubConfirmed)
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$ErrorActionPreference='Stop'
$game=Find-SteamGameFolder -AppId '4001890' -SteamFolderNames @('How to Fish') -Subdir 'How to Fish' -ProbeExe 'How to Fish.exe'
if(Test-Path -LiteralPath (Join-Path $PSScriptRoot '.installed_path')){ $p=(Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw).Trim(); if(Test-Path -LiteralPath $p){$game=$p} }
if(-not $game){throw 'How to Fish was not found.'}
if(-not $HubConfirmed){$a=Read-Host 'Type REMOVE to uninstall HowToFishXR';if($a -ne 'REMOVE'){exit 0}}
$r=Uninstall-OwnedModPayload -GameRoot $game -Identity 'howtofishxr'
if(-not $r.Found -or $r.Preserved -gt 0){throw 'HowToFishXR removal is incomplete; the install evidence was retained for recovery.'}
Remove-Item -LiteralPath (Join-Path $game 'BepInEx\.ts_versions\J_axon-HowToFishXR') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $game 'BepInEx\.ts_versions\HowToFishXR') -Force -ErrorAction SilentlyContinue
foreach($path in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'),(Join-Path $PSScriptRoot '.installed_version'))){Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue}
Write-Host "Removed $($r.Removed), restored $($r.Restored), preserved $($r.Preserved) changed file(s)." -ForegroundColor Green
Write-Host 'Shared BepInEx and the generated HowToFishXR config were retained.' -ForegroundColor Gray
Read-Host 'Press Enter to exit' | Out-Null
