$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\Round8VRSetup.ps1')
while($true){
 try{Invoke-Round8VRSetup -Key 'TombLegend' -InstallerFolder $PSScriptRoot;break}
 catch{
  $message='Tomb Raider: Legend VR setup did not complete: '+$_.Exception.Message
  Write-Host $message -ForegroundColor Red
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'tomb-raider-legend-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl $(if($script:PublisherVRActiveReleasePage){$script:PublisherVRActiveReleasePage}elseif($script:Round8RecoveryPage){$script:Round8RecoveryPage}else{'https://github.com/'+(Get-Round8VRProfile 'TombLegend').Repo+'/releases'}))
 }
}
