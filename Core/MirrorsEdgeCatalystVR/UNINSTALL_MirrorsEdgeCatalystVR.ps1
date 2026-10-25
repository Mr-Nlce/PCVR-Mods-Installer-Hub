param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
$game=if($env:PCVR_MEC_TEST_GAME){[IO.Path]::GetFullPath($env:PCVR_MEC_TEST_GAME)}else{Get-PCVRRememberedGameFolder -GameId 'mirrors-edge-catalyst-vr' -StateNames @('installed_path','user_located') -ProbeFiles @('MirrorsEdgeCatalyst.exe')}
if(-not $game -or -not(Test-Path -LiteralPath (Join-Path $game 'mecxr_live.dll') -PathType Leaf)){throw 'No Catalyst VR runtime was found.'}
if(Get-Process -Name MirrorsEdgeCatalyst -ErrorAction SilentlyContinue){throw 'Close Catalyst before uninstalling VR.'}
if(-not $HubConfirmed -and (Read-Host "Open publisher Setup to remove VR from '$game'? Type REMOVE") -cne 'REMOVE'){exit 0}
$setup=if($env:PCVR_MEC_TEST_SETUP){$env:PCVR_MEC_TEST_SETUP}else{Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\PublisherCache\Catalyst\Publisher-Setup.exe'}
if(-not(Test-Path -LiteralPath $setup -PathType Leaf)){throw 'Publisher Setup is not cached. Reinstall the current Catalyst VR package from the Hub, then use Uninstall.'}
Write-Host '  In publisher Setup, select Uninstall / Remove VR for this game.' -ForegroundColor White
Write-Host "  Game: $game" -ForegroundColor Cyan
[void](Wait-PCVRExplicitEnter -Message 'Press Enter to open publisher Setup for removal...')
$p=Start-Process -FilePath $setup -Wait -PassThru -ErrorAction Stop
if($null -eq $p.ExitCode -or $p.ExitCode -ne 0){throw "Publisher Setup exited with code $($p.ExitCode)."}
if(Test-Path -LiteralPath (Join-Path $game 'mecxr_live.dll') -PathType Leaf){throw 'Publisher Setup did not remove the VR runtime. Choose Uninstall / Remove and retry.'}
foreach($path in @((Join-Path $game '.pcvrhub_version'),(Join-Path $PSScriptRoot '.installed_path'))){if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force}}
Write-Host '  [OK] Publisher VR runtime removed. Original game and saves remain.' -ForegroundColor Green
