$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\CodiesVRInstaller.ps1')
while($true){
    try{Invoke-CodiesVRInstaller -Key 'GridLegends' -InstallerFolder $PSScriptRoot;break}
    catch{
        $message='GRID Legends VR setup did not complete: '+$_.Exception.Message
        Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'grid-legends-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl 'https://github.com/drowhunter/CodiesVR/releases')
    }
}