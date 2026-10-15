$ErrorActionPreference='Stop'
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PENUMBRA_TEST_PORTABLE_ROOT){
    $global:HubPortableStateRootOverride=$env:PCVR_PENUMBRA_TEST_PORTABLE_ROOT
    $global:HubLegacyPortableStateRootOverride=Join-Path $env:PCVR_PENUMBRA_TEST_PORTABLE_ROOT 'legacy'
    $global:HubRuntimeRootOverride=Join-Path $env:PCVR_PENUMBRA_TEST_PORTABLE_ROOT 'runtime'
}
& (Join-Path $PSScriptRoot '..\PenumbraFrameworkVR\PenumbraFrameworkVR-core.ps1') -Game BlackPlague -Mode Install
