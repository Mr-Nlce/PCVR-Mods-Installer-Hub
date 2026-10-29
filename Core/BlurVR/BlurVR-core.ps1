$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\NewGameVRSetup.ps1')
while($true){
 try{Invoke-NewGameVRSetup -Key 'Blur' -InstallerFolder $PSScriptRoot;break}
 catch{
  $message='Blur VR setup did not complete: '+$_.Exception.Message
  Write-Host $message -ForegroundColor Red
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  $p=Get-NewGameVRProfile 'Blur'
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'blur-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl ('https://github.com/'+$p.Repo+'/releases'))
 }
}
