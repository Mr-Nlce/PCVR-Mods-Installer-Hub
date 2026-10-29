param([string]$GameDir='', [switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InkVRSetup.ps1')
$test=Get-InkVRTest
if(-not $GameDir){$GameDir=Get-InkVRGame $test}
if(-not(Test-InkVRBase $GameDir) -or -not(Test-Path -LiteralPath (Join-Path $GameDir '.pcvrhub_inkvr_ownership.csv'))){throw 'Choose the current Bendy game with a Hub-owned InkVR installation. The Team Beef depot cannot be removed here.'}
if(Get-Process -Name 'Bendy and the Ink Machine','InkVR Launcher' -ErrorAction SilentlyContinue){throw 'Close the game and InkVR launcher before uninstalling.'}
Write-Host '  Remove InkVR from the current game. Saves, edited settings and the separate Team Beef depot are kept.' -ForegroundColor Yellow
if(-not $HubConfirmed){[void](Wait-PCVRExplicitEnter -Message 'Press Enter to remove InkVR, or close this window to cancel...')}
$result=Uninstall-OwnedModPayload -GameRoot $GameDir -Identity inkvr
$desktop=if($test){$test.Desktop}else{[Environment]::GetFolderPath('Desktop')};$path=Join-Path $desktop 'Bendy InkVR.lnk'
if(Test-Path -LiteralPath $path){$lnk=(New-Object -ComObject WScript.Shell).CreateShortcut($path);if($lnk.TargetPath -ieq (Join-Path $GameDir 'InkVR\InkVR Launcher.exe') -and $lnk.Arguments -eq '--play vr'){Remove-Item -LiteralPath $path -Force}}
if($result.Preserved -eq 0){
 foreach($name in @('.pcvrhub_version','.pcvrhub_inkvr_version','.pcvrhub.install.json','.pcvrhub.install.json.previous')){ $p=Join-Path $GameDir $name;if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force} }
}
Write-Host ('  [OK] InkVR removal finished. Edited files kept: '+$result.Preserved) -ForegroundColor Green
Write-Host '';Write-Host '  Dreams come to life. So does the ink.' -ForegroundColor Magenta
[void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
