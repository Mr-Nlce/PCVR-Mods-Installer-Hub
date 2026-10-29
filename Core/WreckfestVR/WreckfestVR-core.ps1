$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\NewGameVRSetup.ps1')
while($true){
 try{Invoke-NewGameVRSetup -Key 'Wreckfest' -InstallerFolder $PSScriptRoot;break}
 catch{
  $message='Wreckfest VR setup did not complete: '+$_.Exception.Message
  Write-Host $message -ForegroundColor Red
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  $p=Get-NewGameVRProfile 'Wreckfest'
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'wreckfest-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl ('https://github.com/'+$p.Repo+'/releases'))
 }
}
