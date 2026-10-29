$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherVRSetup.ps1')
while($true){
    try{Invoke-PublisherVRSetup -Key 'DeadSpace2' -InstallerFolder $PSScriptRoot;break}
    catch{
        $message='Dead Space 2 VR setup did not complete: '+$_.Exception.Message
        Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'dead-space-2-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl $(if($script:PublisherVRActiveReleasePage){$script:PublisherVRActiveReleasePage}else{'https://github.com/chortdev/DeadSpace2VR/releases'}))
    }
}