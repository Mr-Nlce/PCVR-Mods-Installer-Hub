$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\KingEJUnityVRSetup.ps1')
while($true){try{Invoke-KingEJVRSetup -Key 'IHateThisPlace' -InstallerFolder $PSScriptRoot;break}catch{$message='I Hate This Place VR setup did not complete: '+$_.Exception.Message;Write-Host $message -ForegroundColor Red;if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'i-hate-this-place-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl 'https://github.com/King-EJ/I-Hate-This-Place-VR-Mod/releases')}}
