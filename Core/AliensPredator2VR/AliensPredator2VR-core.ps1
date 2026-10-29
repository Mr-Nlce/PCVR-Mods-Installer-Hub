$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\AliensPredator2Setup.ps1')
while($true){
 try{Invoke-Avp2Setup -Folder $PSScriptRoot;break}
 catch{
  $message='Aliens versus Predator 2 VR setup did not complete: '+$_.Exception.Message
  Write-Host $message -ForegroundColor Red
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'aliens-versus-predator-2-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl 'https://github.com/Bassquake/Aliens-Versus-Predator-2-VR/releases')
 }
}
