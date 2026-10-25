param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference = 'Stop'
$runtime = $GameDirectory
foreach ($relative in @('Play VR.cmd','tools\blvr_xr_host.exe','bin\d3d9.dll','.pcvrhub_version')) {
    if (-not (Test-Path -LiteralPath (Join-Path $runtime $relative) -PathType Leaf)) {
        throw "Brutal Legend VR runtime is incomplete: $relative. Use Reinstall in the Hub."
    }
}
if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_BLVR_TEST_LAUNCH_CAPTURE) {
    [pscustomobject]@{File=(Join-Path $runtime 'Play VR.cmd');WorkingDirectory=$runtime} |
        ConvertTo-Json -Compress | Set-Content -LiteralPath $env:PCVR_BLVR_TEST_LAUNCH_CAPTURE -Encoding UTF8
    exit 0
}
Start-Process -FilePath (Join-Path $runtime 'Play VR.cmd') -WorkingDirectory $runtime -ErrorAction Stop | Out-Null
