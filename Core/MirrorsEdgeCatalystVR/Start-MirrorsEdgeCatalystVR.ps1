param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference='Stop'
foreach($relative in @('MirrorsEdgeCatalyst.exe','mecxr_launcher.exe','mecxr_live.dll')){
    if(-not(Test-Path -LiteralPath (Join-Path $GameDirectory $relative) -PathType Leaf)){
        throw "Mirror's Edge Catalyst VR is incomplete: $relative. Use Reinstall in the Hub."
    }
}
$launcher=Join-Path $GameDirectory 'mecxr_launcher.exe'
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_MEC_TEST_LAUNCH_CAPTURE){
    [pscustomobject]@{File=$launcher;WorkingDirectory=$GameDirectory}|ConvertTo-Json -Compress|Set-Content -LiteralPath $env:PCVR_MEC_TEST_LAUNCH_CAPTURE -Encoding UTF8
    exit 0
}
Start-Process -FilePath $launcher -WorkingDirectory $GameDirectory -ErrorAction Stop|Out-Null
