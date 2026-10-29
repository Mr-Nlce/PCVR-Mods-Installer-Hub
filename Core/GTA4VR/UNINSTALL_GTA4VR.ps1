param([Alias('GameDir')][string]$GameDirectory,[ValidateSet('bordplate','gamepad')][string]$Mod='bordplate',[switch]$HubConfirmed,[string]$Desktop)
$ErrorActionPreference='Stop'
function Invoke-GTA4Removal {
    $helpers=if(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'GTA4VRProfiles.ps1')){$PSScriptRoot}else{Join-Path $PSScriptRoot '..\Modules'}
    foreach($name in @('OwnedModFiles.ps1','PublisherZipTransaction.ps1','GTA4VRProfiles.ps1')){. (Join-Path $helpers $name)}
    $root=if($GameDirectory){$GameDirectory}else{[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))}
    $game=Get-GTA4Root $root
    if(-not $HubConfirmed){Write-Host ('Remove '+(Get-GTA4Profile $Mod).Name+'? The other mod, saves and changed settings are kept.');if((Read-Host 'Type REMOVE to continue') -cne 'REMOVE'){return}}
    Remove-GTA4Profile -Game $game -Mod $Mod -Desktop $Desktop
    Write-Host '  [OK] Selected VR mod removed. The other profile and your settings are kept.' -ForegroundColor Green
    Write-Host '  Roman has another bowling invitation.' -ForegroundColor Magenta
    if(-not [Console]::IsInputRedirected){while([Console]::KeyAvailable){[void][Console]::ReadKey($true)}}
    [void](Read-Host 'Press Enter to close setup...')
}
while($true){
 try{Invoke-GTA4Removal;break}
 catch{
  Write-Host $_.Exception.Message -ForegroundColor Red
  if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
  [void](Read-Host 'Close GTA IV or correct the folder, then press Enter to retry...')
 }
}
