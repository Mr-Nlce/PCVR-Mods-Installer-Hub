param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
$ErrorActionPreference = 'Stop'
$candidates = @((Join-Path $GameDirectory 'VR'),$GameDirectory)
foreach ($root in $candidates) {
    $launch = Join-Path $root 'Forsaken VR.cmd'
    $exe = Join-Path $root 'game\projectx.exe'
    $openxr = Join-Path $root 'game\libopenxr_loader.dll'
    $level = Join-Path $root 'game\Data\levels\alpha\alpha.mxv'
    $manifest = Join-Path $root 'install-manifest.txt'
    if ((Test-Path -LiteralPath $launch -PathType Leaf) -and
        (Test-Path -LiteralPath $exe -PathType Leaf) -and
        (Test-Path -LiteralPath $openxr -PathType Leaf) -and
        (Test-Path -LiteralPath $level -PathType Leaf) -and
        (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        # Exact publisher VR arguments; never select its flat launcher or the Remaster EXE.
        if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_FORSAKEN_TEST_LAUNCH_CAPTURE) {
            [pscustomobject]@{Executable=$exe;Arguments='-window -vr -vrres 100 -log';WorkingDirectory=(Join-Path $root 'game')} |
                ConvertTo-Json -Compress | Set-Content -LiteralPath $env:PCVR_FORSAKEN_TEST_LAUNCH_CAPTURE -Encoding UTF8
            exit 0
        }
        Start-Process -FilePath $exe -ArgumentList '-window -vr -vrres 100 -log' -WorkingDirectory (Join-Path $root 'game') -ErrorAction Stop | Out-Null
        exit 0
    }
}
throw 'Forsaken VR runtime is incomplete. Run the Hub installer again.'
