$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\BlackOpsVRSetup.ps1')
while($true){
 try{Invoke-BO1VRSetup -InstallerFolder $PSScriptRoot;break}
 catch{
  $message='Black Ops VR setup did not complete: '+$_.Exception.Message
  Write-Host $message -ForegroundColor Red
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'call-of-duty-black-ops-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl 'https://github.com/BigManLucaVR/BO1VR/releases')
 }
}
