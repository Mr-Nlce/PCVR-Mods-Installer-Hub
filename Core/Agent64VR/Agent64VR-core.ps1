$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\KingEJUnityVRSetup.ps1')
while($true){try{Invoke-KingEJVRSetup -Key 'Agent64' -InstallerFolder $PSScriptRoot;break}catch{$message='Agent 64: Spies Never Die VR setup did not complete: '+$_.Exception.Message;Write-Host $message -ForegroundColor Red;if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'agent-64-spies-never-die-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl 'https://github.com/King-EJ/Agent-64-Spies-Never-Die-VR-Mod/releases')}}
