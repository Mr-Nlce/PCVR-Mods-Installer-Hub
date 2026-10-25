$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\GrayHorizonInstaller.ps1')
while($true){
    try{Invoke-GrayHorizonInstaller -Number 5 -InstallerFolder $PSScriptRoot;break}
    catch{
        $message="Forza Horizon 5 GrayHorizon setup did not complete: $($_.Exception.Message)"
        Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot -RecoveryPageUrl 'https://github.com/GrayHorizon-mod/Forza-Horizon-VR/releases')
    }
}

