param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$game=if($env:PCVR_COJ_TEST_GAME){[IO.Path]::GetFullPath($env:PCVR_COJ_TEST_GAME)}else{Get-PCVRRememberedGameFolder -GameId 'call-of-juarez-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('CoJ.exe')}
if(-not $game -or -not(Test-Path -LiteralPath (Join-Path $game '.cojvr-public-install.json') -PathType Leaf)){throw 'No publisher CoJ VR installation was found.'}
if(Get-Process -Name CoJ -ErrorAction SilentlyContinue){throw 'Close Call of Juarez before uninstalling VR.'}
if(-not $HubConfirmed -and (Read-Host "Remove CoJ VR from '$game'? Type REMOVE") -cne 'REMOVE'){exit 0}
$version=(Get-Content -LiteralPath (Join-Path $game '.pcvrhub_version') -Raw).Trim()
if($version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?$'){throw 'Cannot resolve the installed publisher version. Preserve its backups and use the matching publisher package.'}
$publisher=if($env:PCVR_COJ_TEST_PUBLISHER){$env:PCVR_COJ_TEST_PUBLISHER}elseif($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_COJ_TEST_CACHE){Join-Path $env:PCVR_COJ_TEST_CACHE "$version\cojvr.ps1"}else{Join-Path $env:LOCALAPPDATA ("PCVR Mods Installer Hub\PublisherCache\CallOfJuarezVR\$version\cojvr.ps1")}
if(-not(Test-Path -LiteralPath $publisher -PathType Leaf)){throw 'Publisher uninstall tool is missing. Preserve the game backup and reinstall the same VR package first.'}
Write-Host '  The publisher restores its tracked original D3D9 files and keeps your saves.' -ForegroundColor White
[void](Wait-PCVRExplicitEnter -Message 'Press Enter to run publisher Uninstall / Restore...')
$args=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$publisher+'"'),'-Action','Uninstall','-GameDirectory',('"'+$game+'"'))
$p=Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Wait -PassThru -ErrorAction Stop
if($null -eq $p.ExitCode -or $p.ExitCode -ne 0){throw "Publisher Uninstall failed (exit $($p.ExitCode))."}
if(Test-Path -LiteralPath (Join-Path $game '.cojvr-public-install.json') -PathType Leaf){throw 'Publisher still reports CoJ VR installed. Preserve its backups and retry.'}
foreach($path in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))){if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force}}
Write-Host '  [OK] CoJ VR removed. Original Steam game and saves remain.' -ForegroundColor Green
