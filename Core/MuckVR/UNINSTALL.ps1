param([switch]$HubConfirmed)
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1');. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$ErrorActionPreference='Stop';$game=Find-SteamGameFolder -AppId '1625450' -SteamFolderNames @('Muck') -ProbeExe 'Muck.exe'
if(Test-Path -LiteralPath (Join-Path $PSScriptRoot '.installed_path')){$p=(Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw).Trim();if(Test-Path -LiteralPath $p){$game=$p}}
if(-not $game){throw 'Muck was not found.'};if(-not $HubConfirmed){if((Read-Host 'Type REMOVE to uninstall MuckVR') -ne 'REMOVE'){exit 0}}
$r=Uninstall-OwnedModPayload -GameRoot $game -Identity 'muckvr'
if(-not $r.Found -or $r.Preserved -gt 0){throw 'MuckVR removal is incomplete; the install evidence was retained for recovery.'}
foreach($n in @('Elektroney-MuckVR','MuckVR')){Remove-Item -LiteralPath (Join-Path $game "BepInEx\.ts_versions\$n") -Force -ErrorAction SilentlyContinue}
foreach($path in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'),(Join-Path $PSScriptRoot '.installed_version'))){Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue}
Write-Host "Removed $($r.Removed), restored $($r.Restored), preserved $($r.Preserved) changed file(s)." -ForegroundColor Green
Write-Host 'Shared BepInEx was retained. The original globalgamemanagers was restored.' -ForegroundColor Gray;Read-Host 'Press Enter to exit'|Out-Null
