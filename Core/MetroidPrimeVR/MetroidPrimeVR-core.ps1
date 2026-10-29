$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\MetroidPrimeNativeSetup.ps1')
$choice=([string]$env:PCVR_HUB_INSTALLER_CHOICE).Trim().ToLowerInvariant()
if(-not $choice -and $env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_METROID_NATIVE_TEST){
    $testChoice=Get-MetroidNativeTest
    $choice=if($testChoice.Variant -eq 'Legacy'){'legacy'}else{'native'}
}
if(-not $choice){
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host '  Metroid Prime VR - choose a separate variant' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host '  1. RECOMMENDED - PrimedGun 2.0 native OpenXR' -ForegroundColor Green
    Write-Host '     Auto-update, including Windows prereleases.' -ForegroundColor Green
    Write-Host '  2. Legacy - Dolphin-based PrimedGun 1.1.7' -ForegroundColor White
    Write-Host '     Fixed legacy download. Existing legacy installs and saves stay separate.' -ForegroundColor Gray
    Write-Host '     Requires a powerful PC for Dolphin-based VR.' -ForegroundColor Yellow
    while($choice -notin @('native','legacy')){
        switch((Read-Host '  Choose 1 or 2 (Enter = recommended, Q cancels)').Trim().ToLowerInvariant()){
            ''{$choice='native'} '1'{$choice='native'} '2'{$choice='legacy'} 'q'{exit 1}
        }
    }
}
if($choice -notin @('native','legacy')){throw 'Unknown Metroid variant selection.'}
while($true){
    try{if($choice -eq 'legacy'){Invoke-MetroidLegacySetup -InstallerFolder $PSScriptRoot}else{Invoke-MetroidNativeSetup -InstallerFolder $PSScriptRoot};break}
    catch{
        $message='Metroid Prime VR setup did not complete: '+$_.Exception.Message
        Write-Host $message -ForegroundColor Red
        if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
        $recoveryPage=if($choice -eq 'legacy'){(Get-MetroidLegacySource).Page}else{'https://github.com/iChris4/MetroidPrimePortVR/releases'}
        [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'metroid-prime-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl $recoveryPage)
    }
}
