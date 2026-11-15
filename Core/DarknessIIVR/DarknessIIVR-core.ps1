$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\PublisherGameHandoff.ps1')
$game = @{
    Id='the-darkness-ii-vr'; Title='The Darkness II'; Publisher='darkness2'; App='67370'; SteamFolder=@('Darkness II','The Darkness II')
    Base=@('DarknessII.exe','Cache.Windows\H.Misc.cache')
    Proof=@('d3d9.dll','openxr_loader.dll','Darkness2VR.ini')
    HashProof=@('d3d9.dll','openxr_loader.dll'); Processes=@('DarknessII','TrilexModInstaller')
    Notes='Close the game. Trilex installs the OpenXR runtime and can prepare optional HD textures.'
    Done='Use Start in VR in the Hub. For texture options or uninstall, reopen Trilex.'
    Quip='Embrace the Darkness. Keep both hands free.'
}
Invoke-PublisherGameHandoff -Game $game -InstallerFolder $PSScriptRoot
