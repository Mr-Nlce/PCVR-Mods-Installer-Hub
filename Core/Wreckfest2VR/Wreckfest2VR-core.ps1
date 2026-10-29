$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\NewGameVRSetup.ps1')
while($true){
 try{Invoke-NewGameVRSetup -Key 'Wreckfest2' -InstallerFolder $PSScriptRoot;break}
 catch{
  $message='Wreckfest 2 VR setup did not complete: '+$_.Exception.Message
  Write-Host $message -ForegroundColor Red
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  $p=Get-NewGameVRProfile 'Wreckfest2'
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'wreckfest-2-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl ('https://github.com/'+$p.Repo+'/releases'))
 }
}
