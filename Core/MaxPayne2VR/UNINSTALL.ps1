param([switch]$HubConfirmed)
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1');. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$ErrorActionPreference='Stop';$game=Find-SteamGameFolder -AppId '12150' -SteamFolderNames @('Max Payne 2 The Fall of Max Payne','Max Payne 2') -ProbeExe 'MaxPayne2.exe' -GogNames @('Max Payne 2','Max Payne 2 The Fall of Max Payne')
if(Test-Path -LiteralPath (Join-Path $PSScriptRoot '.installed_path')){$p=(Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw).Trim();if(Test-Path -LiteralPath $p){$game=$p}}
if(-not$game){throw 'Max Payne 2 was not found.'};if(-not$HubConfirmed){if((Read-Host 'Type REMOVE to uninstall MaxPayne2VR') -ne 'REMOVE'){exit 0}}
$r=Uninstall-OwnedModPayload -GameRoot $game -Identity 'maxpayne2vr' -ParkedAlternates @{'winmm.dll'='winmm.dll.pcvrhub_off'}
Write-Host "Removed $($r.Removed), restored $($r.Restored), preserved $($r.Preserved) changed file(s)." -ForegroundColor Green;Write-Host 'MaxPayne2VR.ini was retained with your calibration and comfort settings.' -ForegroundColor Gray;Read-Host 'Press Enter to exit'|Out-Null
