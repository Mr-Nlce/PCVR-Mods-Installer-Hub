param([string]$ElevatedContext='')
$ErrorActionPreference='Stop'
$adminRequest=$null;$adminTranscript=$false;$adminCompleted=$false;$adminRawTranscript=$null
if($ElevatedContext){
 . (Join-Path $PSScriptRoot '..\Modules\BlackWhitePreparation.ps1')
 Initialize-BlackWhiteConsole
 if(-not(Test-BlackWhiteAdministrator)){throw 'Administrator continuation requires Windows approval.'}
 $adminRequest=Get-Content -LiteralPath $ElevatedContext -Raw|ConvertFrom-Json
 foreach($name in @('Game','Desktop','StateRoot','PortableRoot','Local','Roaming','UserProfile','Result','Log','RuntimeRoot','Downloads')){
  if(-not $adminRequest.$name -or -not [IO.Path]::IsPathRooted([string]$adminRequest.$name)){throw ('Missing administrator continuation path: '+$name)}
 }
 if(-not(Test-Path -LiteralPath (Join-Path $adminRequest.Game 'runblack.exe') -PathType Leaf)){throw 'The selected Black & White game is missing.'}
 $global:BlackWhiteSelectedGame=[string]$adminRequest.Game;$global:BlackWhiteDesktopOverride=[string]$adminRequest.Desktop
 $global:HubStateRootOverride=[string]$adminRequest.StateRoot;$global:HubPortableStateRootOverride=[string]$adminRequest.PortableRoot
 $global:HubLocalAppDataRootOverride=[string]$adminRequest.Local;$global:HubRuntimeRootOverride=[string]$adminRequest.RuntimeRoot
 $global:BlackWhiteDownloadsOverride=[string]$adminRequest.Downloads
 $env:PCVR_HUB_GAME_ID='black-white-vr'
 $env:LOCALAPPDATA=[string]$adminRequest.Local;$env:APPDATA=[string]$adminRequest.Roaming;$env:USERPROFILE=[string]$adminRequest.UserProfile
 $env:PCVR_HUB_INSTALL_STATUS_PATH=[string]$adminRequest.Status;$env:PCVR_HUB_INSTALL_RUN_ID=[string]$adminRequest.RunId
 $adminRawTranscript=Join-Path (Split-Path $ElevatedContext -Parent) 'blackwhite-raw-transcript.tmp'
 Start-Transcript -LiteralPath $adminRawTranscript -ErrorAction Stop|Out-Null;$adminTranscript=$true
}
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\Round8VRSetup.ps1')
if($adminRequest){function global:Get-PCVRDownloadsFolder {return [string]$global:BlackWhiteDownloadsOverride}}
try{
while($true){
 try{
  if($adminRequest -and $adminRequest.Uninstall){
   Invoke-Round8VRUninstall -Key 'BlackWhite' -InstallerFolder $PSScriptRoot -HubConfirmed
   Write-Host '';Write-Host '  Please do not teach the Creature to eat the villagers.' -ForegroundColor Magenta
   [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
  }else{Invoke-Round8VRSetup -Key 'BlackWhite' -InstallerFolder $PSScriptRoot}
  if($adminRequest){$adminCompleted=$true}
  break
 }
 catch{
  $message='Black & White VR setup did not complete: '+$_.Exception.Message
  Write-Host $message -ForegroundColor Red
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'black-white-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl $(if($script:PublisherVRActiveReleasePage){$script:PublisherVRActiveReleasePage}elseif($script:Round8RecoveryPage){$script:Round8RecoveryPage}else{'https://github.com/'+(Get-Round8VRProfile 'BlackWhite').Repo+'/releases'}))
 }
}
}finally{
 if($adminTranscript){Stop-Transcript|Out-Null;$adminTranscript=$false}
 if($adminRequest -and $adminRawTranscript -and (Test-Path -LiteralPath $adminRawTranscript -PathType Leaf)){
  Write-BlackWhiteSafeTranscript -Source $adminRawTranscript -Destination $adminRequest.Log
  Remove-Item -LiteralPath $adminRawTranscript -Force
 }
}
if($adminRequest -and $adminCompleted){[IO.File]::WriteAllText($adminRequest.Result,(@{Success=$true;Game=$adminRequest.Game}|ConvertTo-Json))}
