$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\PublisherGameHandoff.ps1')
$game = @{
    Id='tiny-tinas-wonderlands-vr'; Title='Tiny Tina''s Wonderlands'; Publisher='wonderlands'; App='1286680'; SteamFolder='Tiny Tina''s Wonderlands'
    Base=@('OakGame\Binaries\Win64\Wonderlands.exe','OakGame\Content\Paks\pakchunk0-WindowsNoEditor.pak')
    Proof=@('OakGame\Binaries\Win64\xinput1_3.dll','OakGame\Binaries\Win64\openxr_loader.dll','OakGame\Binaries\Win64\WonderlandsVR.ini')
    HashProof=@('OakGame\Binaries\Win64\xinput1_3.dll','OakGame\Binaries\Win64\openxr_loader.dll'); Processes=@('Wonderlands','TrilexModInstaller')
    Notes='Steam edition. VR requires DirectX 11. Turn DLSS Quality off if gameplay renders in only one eye.'
    Done='Use Start in VR in the Hub to launch in DirectX 11 mode. Manage repair and removal in Trilex.'
    Quip='Roll for initiative. Aim with both hands.'
}
Invoke-PublisherGameHandoff -Game $game -InstallerFolder $PSScriptRoot
