$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherVRSetup.ps1')
while($true){
    try{Invoke-PublisherVRSetup -Key 'AmongSleep' -InstallerFolder $PSScriptRoot;break}
    catch{
        $message='Among the Sleep VR setup did not complete: '+$_.Exception.Message
        Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'among-the-sleep-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl $(if($script:PublisherVRActiveReleasePage){$script:PublisherVRActiveReleasePage}else{'https://github.com/King-EJ/Among-the-Sleep-VR/releases'}))
    }
}