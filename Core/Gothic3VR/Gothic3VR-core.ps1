$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\PublisherGameHandoff.ps1')
$game = @{
    Id='gothic-3-vr'; Title='Gothic 3'; Publisher='gothic'; App='39500'; SteamFolder='Gothic 3'
    GogNames=@('Gothic 3')
    Base=@('Gothic3.exe','Data\_compiledMesh.pak')
    Proof=@('Gothic3VRLauncher.exe','scripts\Script_Gothic3VRDiagnostics.dll','scripts\Gothic3VRDiagnostics\openxr_loader.dll','patches\Patch_Gothic3VRResolution.dll','scripts\Script_paru.dll')
    HashProof=@(); Processes=@('Gothic3','Gothic3VRLauncher','UnionStarter')
    Notes='Start Gothic 3 Classic flat once and close it. The Hub can make a separate VR copy or use one you already have.'
    Done='Start in VR opens the Gothic 3 VR launcher. Choose your OpenXR runtime and calibrate the headset there.'
    Quip='Welcome to Myrtana. Draw your bow by hand.'
}
Invoke-PublisherGameHandoff -Game $game -InstallerFolder $PSScriptRoot
