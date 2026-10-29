$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\NewGameVRSetup.ps1')
while($true){
 try{Invoke-NewGameVRSetup -Key 'Ratchet1' -InstallerFolder $PSScriptRoot;break}
 catch{
  $message='Ratchet & Clank 1 VR setup did not complete: '+$_.Exception.Message
  Write-Host $message -ForegroundColor Red
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  $p=Get-NewGameVRProfile 'Ratchet1'
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'ratchet-clank-1-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl ('https://github.com/'+$p.Repo+'/releases'))
 }
}
