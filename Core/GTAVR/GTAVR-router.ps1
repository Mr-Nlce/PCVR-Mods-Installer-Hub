param(
    [Alias('InstallerChoice')]
    [ValidateSet('','current','legacy')]
    [string]$Mod = ''
)

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'Grand Theft Auto V VR Installer'

function Write-MenuHeader {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ' Grand Theft Auto V VR - Installer' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ''
}

if (-not $Mod) {
    Write-MenuHeader
    Write-Host ' Choose the VR setup:' -ForegroundColor White
    Write-Host ''
    Write-Host '  [1] Current GTA V Legacy - GTAVR by DeployAbi' -ForegroundColor Green
    Write-Host '      RECOMMENDED - current game build, 6DOF motion controls.' -ForegroundColor Green
    Write-Host ''
    Write-Host '  [2] R.E.A.L. r7 + VRV patcher' -ForegroundColor White
    Write-Host '      Older alternative with gamepad and optional old motion overlay.' -ForegroundColor Gray
    Write-Host '      Compatibility depends on the installed GTA V Legacy build.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Both setups may remain installed. The Hub launch buttons park the' -ForegroundColor Gray
    Write-Host '  inactive hook before starting the selected one.' -ForegroundColor Gray
    Write-Host ''
    for ($attempt = 1; $attempt -le 10; $attempt++) {
        $choice = ('' + (Read-Host " Enter 1 or 2 (attempt $attempt/10), or Q to quit")).Trim().ToLowerInvariant()
        if ($choice -eq '1') { $Mod = 'current'; break }
        if ($choice -eq '2') { $Mod = 'legacy'; break }
        if ($choice -in @('q','quit','exit')) { exit 0 }
        Write-Host '  Please enter 1, 2 or Q.' -ForegroundColor Yellow
    }
    if (-not $Mod) { throw 'No valid installer option was selected.' }
}

$target = if ($Mod -eq 'current') {
    Join-Path $PSScriptRoot 'GTAVR-current.ps1'
} else {
    Join-Path $PSScriptRoot 'GTAVR-core.ps1'
}
if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Installer component is missing: $target" }
& $target

