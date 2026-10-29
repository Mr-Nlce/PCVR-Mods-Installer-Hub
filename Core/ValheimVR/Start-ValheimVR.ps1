param([string]$GameDirectory='',[string]$RuntimeRoot='',[switch]$PlanOnly)
$ErrorActionPreference='Stop'
$helper=Join-Path $PSScriptRoot 'StoreLaunch.ps1'
if(-not(Test-Path -LiteralPath $helper)){$helper=Join-Path $PSScriptRoot '..\Modules\StoreLaunch.ps1'}
. $helper
function Get-ValheimLaunchPlan([string]$Root,[switch]$RequireVr){
 if(-not $Root){$Root=Split-Path -Parent $PSScriptRoot}
 $Root=[IO.Path]::GetFullPath($Root)
 foreach($file in @('valheim.exe','UnityPlayer.dll','Valheim_Data\Managed\assembly_valheim.dll')){
  if(-not(Test-Path -LiteralPath (Join-Path $Root $file) -PathType Leaf)){throw 'The Valheim game folder is incomplete. Use Locate Game in the Hub and select valheim.exe.'}
 }
 if($RequireVr){
  foreach($file in @('winhttp.dll','doorstop_config.ini','BepInEx\core\BepInEx.dll','BepInEx\core\BepInEx.Preloader.dll','BepInEx\plugins\ValheimVRMod.dll','Valheim_Data\Managed\SteamVR.dll','Valheim_Data\Plugins\x86_64\XRSDKOpenVR.dll')){
   if(-not(Test-Path -LiteralPath (Join-Path $Root $file) -PathType Leaf)){throw 'Required Valheim VR files are missing. Use Update / Reinstall in the Hub to repair them, then try Start in VR again.'}
  }
 }
 $xbox=Get-PCVRXboxLaunchRegistration -GameRoot $Root -Names @('Valheim')
 if($xbox.IsXbox){
  if(-not $xbox.AppId){throw 'Windows could not identify Valheim. Start it once from the Xbox app, then try again. No Steam game license is required.'}
  return [pscustomobject]@{Store='Xbox';Target=$xbox.AppId;Arguments='-force-d3d11';Root=$Root}
 }
 if($Root -match '(?i)[\\/]steamapps[\\/]common[\\/]'){
  return [pscustomobject]@{Store='Steam';Target='steam://run/892970//-force-d3d11/';Arguments='';Root=$Root}
 }
 throw 'This Valheim folder could not be assigned to Steam or the Xbox app. Open the game once from its store and use Locate Game again.'
}
if($env:PCVR_VALHEIM_LIBRARY_ONLY -ne '1'){
 try{
  $plan=Get-ValheimLaunchPlan $GameDirectory -RequireVr
  if($PlanOnly){$plan;return}
  if($plan.Store -eq 'Xbox'){Start-PCVRXboxApplication -AppId $plan.Target -Arguments $plan.Arguments}
  else{Start-Process -FilePath $plan.Target -ErrorAction Stop}
 }catch{
  Add-Type -AssemblyName PresentationFramework
  [void][System.Windows.MessageBox]::Show($_.Exception.Message,'Start Valheim VR','OK','Warning');exit 1
 }
}
