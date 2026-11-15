# Original and Remastered share their EXE/resource names, but use different
# Unity scripting backends and separate Steam apps. Never infer an edition
# from its folder spelling or from the installed VR plugin.
. (Join-Path $PSScriptRoot 'GameInstallProof.ps1')
function global:Get-DawnVRGameEdition {
    param([string]$Root)
    if(-not (Test-PCVRGameInstallProof -GameId 'life-is-strange-bts' -Root $Root)){return $null}
    $data=Join-Path $Root 'Life is Strange - Before the Storm_Data'
    $il2cpp=(Test-Path -LiteralPath (Join-Path $Root 'GameAssembly.dll') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $data 'il2cpp_data\Metadata\global-metadata.dat') -PathType Leaf)
    $mono=Test-Path -LiteralPath (Join-Path $data 'Managed\Assembly-CSharp.dll') -PathType Leaf
    if($il2cpp){return 'Remastered'}
    if($mono){return 'Original'}
    return $null
}
function global:Get-DawnVRSteamAppId {
    param([string]$Root)
    switch(Get-DawnVRGameEdition -Root $Root){'Original'{'554620'} 'Remastered'{'1265930'}}
}
