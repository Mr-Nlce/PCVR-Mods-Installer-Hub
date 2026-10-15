$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\DescentVRShared\DescentVRShared.ps1')
while($true){try{Invoke-DescentInstaller 'd1';break}catch{$message="Descent VR setup did not complete: $($_.Exception.Message)";Write-Host $message -ForegroundColor Red;if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};[void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)}}
