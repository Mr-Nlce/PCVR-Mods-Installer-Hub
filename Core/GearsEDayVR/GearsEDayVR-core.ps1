$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OctoberNativeVRSetup.ps1')
while($true){try{Invoke-OctoberNativeSetup -Key 'GearsEDay' -InstallerFolder $PSScriptRoot;break}catch{$message='Gears of War: E-Day VR setup did not complete: '+$_.Exception.Message;Write-Host $message -ForegroundColor Red;if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'gears-of-war-e-day-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl 'https://github.com/paultaran00/GoWEDay-VR/releases')}}
