param([ValidateSet('deployabi','gamepad','motion')][string]$Mode = 'deployabi')

$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $PSScriptRoot
$realIni = Join-Path $dir 'RealVR.ini'
$realOn = Join-Path $dir 'RealVR.asi'
$realOff = Join-Path $dir 'RealVR.asi.off'
$motionOn = Join-Path $dir 'GTAVR.asi'
$motionOff = Join-Path $dir 'GTAVR.asi.off'
$deployDisabled = Join-Path $dir 'gtavr.disabled'
$deployManifest = Join-Path $dir 'gtavr_install_manifest.txt'

if (Get-Process -Name 'GTA5','GTA5_BE' -ErrorAction SilentlyContinue) {
    throw 'Close GTA V before switching VR mods.'
}

if ($Mode -eq 'deployabi') {
    # Preserve R.E.A.L. and its old motion overlay, but park both hooks so two
    # camera/render paths can never load into the same game run.
    if (Test-Path -LiteralPath $realOn -PathType Leaf) { Move-Item -LiteralPath $realOn -Destination $realOff -Force }
    if (Test-Path -LiteralPath $motionOn -PathType Leaf) { Move-Item -LiteralPath $motionOn -Destination $motionOff -Force }
    if (Test-Path -LiteralPath $deployDisabled -PathType Leaf) { Remove-Item -LiteralPath $deployDisabled -Force }
    $launcher = Join-Path $PSScriptRoot 'DeployAbi\GTAVR-Setup-and-Play.exe'
    if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) { throw 'The reviewed GTAVR Setup and Play launcher is missing. Re-run the Hub installer.' }
    Start-Process -FilePath $launcher -WorkingDirectory (Split-Path -Parent $launcher)
    return
}

# The author's own inert marker keeps DeployAbi installed while R.E.A.L. is
# selected. The next DeployAbi start removes it again.
if ((Test-Path -LiteralPath $deployManifest -PathType Leaf) -and -not (Test-Path -LiteralPath $deployDisabled -PathType Leaf)) {
    Set-Content -LiteralPath $deployDisabled -Value 'Disabled by PCVR Mods Hub while R.E.A.L. is selected.' -Encoding ASCII -Force
}
if (Test-Path -LiteralPath $realOff -PathType Leaf) { Move-Item -LiteralPath $realOff -Destination $realOn -Force }

if ($Mode -eq 'motion') {
    if (Test-Path -LiteralPath $realIni -PathType Leaf) { (Get-Content -LiteralPath $realIni) -replace '^\s*VRAPI\s*=.*', 'VRAPI = 2' | Set-Content -LiteralPath $realIni }
    if (Test-Path -LiteralPath $motionOff -PathType Leaf) { Move-Item -LiteralPath $motionOff -Destination $motionOn -Force }
} else {
    if (Test-Path -LiteralPath $realIni -PathType Leaf) { (Get-Content -LiteralPath $realIni) -replace '^\s*VRAPI\s*=.*', 'VRAPI = 3' | Set-Content -LiteralPath $realIni }
    if (Test-Path -LiteralPath $motionOn -PathType Leaf) { Move-Item -LiteralPath $motionOn -Destination $motionOff -Force }
}

$exe = Join-Path $dir 'PlayGTAV.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'PlayGTAV.exe is missing. Re-run the R.E.A.L. installer option.' }
Start-Process -FilePath $exe -ArgumentList '-nobattleye' -WorkingDirectory $dir

