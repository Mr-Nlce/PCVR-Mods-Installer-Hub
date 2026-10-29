param([string]$GameDirectory,[switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\AliensPredator2Setup.ps1')
while($true){try{
 if(-not $GameDirectory){$GameDirectory=Get-Avp2Game (Get-Avp2Test)}
 if(Get-Process -Name lithtech,AVP2 -ErrorAction SilentlyContinue){throw 'Close AvP2 and its launcher before removal.'}
 if(-not $HubConfirmed){Write-Host '  Remove unchanged Hub-owned VR files and restore earlier originals. Saves and edited settings stay.' -ForegroundColor Yellow;[void](Wait-PCVRExplicitEnter -Message 'Press Enter to remove AvP2 VR...')}
 $r=Invoke-Avp2Privileged remove $GameDirectory
 $test=Get-Avp2Test;$desktop=if($test){[string]$test.Desktop}else{[Environment]::GetFolderPath('DesktopDirectory')};Set-Avp2Shortcut $GameDirectory $desktop -Remove
 foreach($f in @('.pcvrhub_version')){if([IO.File]::Exists((Join-Path $GameDirectory $f))){Remove-Item -LiteralPath (Join-Path $GameDirectory $f) -Force}}
 $receipt=Join-Path $PSScriptRoot '.installed_path';if([IO.File]::Exists($receipt)){Remove-Item -LiteralPath $receipt -Force}
 Write-Host '  [OK] VR files removed. Saved games and edited settings remain.' -ForegroundColor Green
 Write-Host '  Game over, man! Try the other two campaigns.' -ForegroundColor Magenta
 [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...');break
}catch{if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $_.Exception.Message -GameId 'aliens-versus-predator-2-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl $script:Avp2Page)}}
