$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OctoberNativeVRSetup.ps1')
while($true){try{Invoke-OctoberNativeSetup -Key 'RE5' -InstallerFolder $PSScriptRoot;break}catch{$message='Resident Evil 5 VR setup did not complete: '+$_.Exception.Message;Write-Host $message -ForegroundColor Red;if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'resident-evil-5-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl 'https://github.com/SpreadTheBirb/ResidentEvil5VR/releases')}}
