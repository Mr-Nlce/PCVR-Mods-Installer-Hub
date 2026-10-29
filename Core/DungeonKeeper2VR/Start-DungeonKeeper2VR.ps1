param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference = 'Stop'
foreach($relative in @('DKII-DX.exe','DKII_VR.cmd','DK2VR\Run-VR.ps1','DK2VR\payload\DK2VR.dll','DK2VR\DK2VRHost.exe','DK2VR\openxr_loader.dll')) {
    if(-not(Test-Path -LiteralPath (Join-Path $GameDirectory $relative) -PathType Leaf)) {
        throw "Dungeon Keeper 2 VR is incomplete: $relative. Use Reinstall in the Hub."
    }
}
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_DK2_TEST_LAUNCH_CAPTURE) {
    [pscustomobject]@{File=(Join-Path $GameDirectory 'DKII_VR.cmd');WorkingDirectory=$GameDirectory} |
        ConvertTo-Json -Compress | Set-Content -LiteralPath $env:PCVR_DK2_TEST_LAUNCH_CAPTURE -Encoding UTF8
    exit 0
}
Start-Process -FilePath (Join-Path $GameDirectory 'DKII_VR.cmd') -WorkingDirectory $GameDirectory -ErrorAction Stop | Out-Null
