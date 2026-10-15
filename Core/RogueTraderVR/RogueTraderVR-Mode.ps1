# The two VR packages occupy separate Owlcat UMM directories. UMM loads
# enabled mods from Params.xml, so switch only these two IDs before launch.
function Get-RogueTraderProfileRoot {
    param([string]$Override = '')
    if ($Override) { return [IO.Path]::GetFullPath($Override) }
    return (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'AppData\LocalLow\Owlcat Games\Warhammer 40000 Rogue Trader\UnityModManager')
}

function Test-RogueTraderModPayload {
    param([ValidateSet('Maqueta','RTVR')][string]$Mode,[string]$ProfileRoot)
    $folder = if ($Mode -eq 'Maqueta') { 'RTMaquetaXR' } else { 'RTVR' }
    $dll = if ($Mode -eq 'Maqueta') { 'RTMaquetaXR.dll' } else { 'RTVR.dll' }
    if (-not ((Test-Path -LiteralPath (Join-Path $ProfileRoot "$folder\Info.json") -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $ProfileRoot "$folder\$dll") -PathType Leaf))) { return $false }
    if ($Mode -eq 'Maqueta') {
        return ((Test-Path -LiteralPath (Join-Path $ProfileRoot 'RTMaquetaXR\W40KRT-VR-Launcher.exe') -PathType Leaf) -and
                (Test-Path -LiteralPath (Join-Path $ProfileRoot 'RTMaquetaXR\portable-install.json') -PathType Leaf))
    }
    return ((Test-Path -LiteralPath (Join-Path $ProfileRoot 'WASDMovement\WASDMovement.dll') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $ProfileRoot '0ToyBox0\ToyBox.dll') -PathType Leaf))
}

function Set-RogueTraderModMode {
    param([ValidateSet('Maqueta','RTVR')][string]$Mode,[string]$ProfileRoot,[switch]$AllowMissingSelected)
    if (Get-Process -Name WH40KRT -ErrorAction SilentlyContinue) { throw 'Close Rogue Trader before switching VR mods.' }
    if (-not $AllowMissingSelected -and -not (Test-RogueTraderModPayload -Mode $Mode -ProfileRoot $ProfileRoot)) { throw "The selected $Mode mod is incomplete or missing." }
    $params = Join-Path $ProfileRoot 'Params.xml'
    $xml = New-Object Xml.XmlDocument
    $xml.XmlResolver = $null
    if (Test-Path -LiteralPath $params -PathType Leaf) { $xml.Load($params) }
    else { [void]$xml.AppendChild($xml.CreateElement('Param')) }
    if (-not $xml.DocumentElement -or $xml.DocumentElement.Name -ne 'Param') { throw 'Unexpected Owlcat mod settings format.' }
    $mods = $xml.SelectSingleNode('/Param/ModParams')
    if (-not $mods) { $mods = $xml.DocumentElement.AppendChild($xml.CreateElement('ModParams')) }
    foreach ($item in @(@{Id='RTMaquetaXR';Selected=($Mode -eq 'Maqueta');Present=($AllowMissingSelected -or (Test-Path -LiteralPath (Join-Path $ProfileRoot 'RTMaquetaXR') -PathType Container) -or $mods.SelectSingleNode("Mod[@Id='RTMaquetaXR']"))},
                       @{Id='RTVR';Selected=($Mode -eq 'RTVR');Present=((Test-Path -LiteralPath (Join-Path $ProfileRoot 'RTVR') -PathType Container) -or $mods.SelectSingleNode("Mod[@Id='RTVR']"))})) {
        if (-not $item.Present) { continue }
        $node = $mods.SelectSingleNode("Mod[@Id='$($item.Id)']")
        if (-not $node) { $node = $mods.AppendChild($xml.CreateElement('Mod')); $node.SetAttribute('Id',[string]$item.Id) }
        $node.SetAttribute('Enabled',$(if ($item.Selected) { 'true' } else { 'false' }))
    }
    $temporary = Join-Path $ProfileRoot ('Params.xml.pcvrhub-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        $xml.Save($temporary)
        $check = New-Object Xml.XmlDocument; $check.XmlResolver = $null; $check.Load($temporary)
        foreach ($entry in @(@{Id='RTMaquetaXR';Want=($Mode -eq 'Maqueta')},@{Id='RTVR';Want=($Mode -eq 'RTVR')})) {
            $node = $check.SelectSingleNode("/Param/ModParams/Mod[@Id='$($entry.Id)']")
            if ($node -and ([string]$node.GetAttribute('Enabled') -ne $(if($entry.Want){'true'}else{'false'}))) { throw 'Mod activation verification failed.' }
        }
        Move-Item -LiteralPath $temporary -Destination $params -Force
    } finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force } }
}
