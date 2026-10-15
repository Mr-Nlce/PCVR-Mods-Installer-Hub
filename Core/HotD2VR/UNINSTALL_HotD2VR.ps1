param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
$previousLibraryMode = $env:PCVR_HOTD_LIBRARY_ONLY
$env:PCVR_HOTD_LIBRARY_ONLY = '1'
. (Join-Path $PSScriptRoot 'HotD2VR-core.ps1')
$env:PCVR_HOTD_LIBRARY_ONLY = $previousLibraryMode
$Host.UI.RawUI.WindowTitle = 'HotD2VR Uninstaller'

function Finish-HotDRemoval([int]$Code) {
    if (-not $NoPause) { Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}

if (-not $GameRoot) {
    $installed = Find-HotDInstalled
    if ($installed) { $GameRoot = $installed.Root }
}
if (-not $GameRoot -or -not (Get-HotDInstalled $GameRoot)) {
    Write-Host '  No complete HotD2VR publisher installation was found.' -ForegroundColor Yellow
    Finish-HotDRemoval 0
}
if (Get-Process -Name 'Hod2','HotD2VR' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path.StartsWith($GameRoot,[StringComparison]::OrdinalIgnoreCase) }) {
    Write-Host '  Close HotD2VR before removing the mod.' -ForegroundColor Red
    Finish-HotDRemoval 1
}
Write-Host '  Publisher removal keeps your copied game, disc ISO, saves,' -ForegroundColor White
Write-Host '  settings and update backups. Original game files stay intact.' -ForegroundColor White
if (-not $HubConfirmed -and (Read-Host "Remove HotD2VR from '$GameRoot'? Type REMOVE") -cne 'REMOVE') {
    Finish-HotDRemoval 0
}
$exe = Join-Path $GameRoot 'HotD2VR.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Publisher uninstaller executable is missing.' }
if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HOTD_TEST_UNINSTALL -eq '1') {
    [void](Assert-HotDFixtureRoot -Path $GameRoot)
    if ($env:PCVR_HOTD_TEST_UNINSTALL_EXIT -and [int]$env:PCVR_HOTD_TEST_UNINSTALL_EXIT -ne 0) {
        throw "Publisher uninstaller ended with exit code $env:PCVR_HOTD_TEST_UNINSTALL_EXIT."
    }
    foreach ($relative in @('install.json','HotD2VR.exe','build\pcvr\ddraw.dll',
            'build\pcvr\openxr_loader.dll','pcvr\run-probe.ps1',
            'working\pcvr\game\ddraw.dll','working\pcvr\game\openxr_loader.dll')) {
        $target = Join-Path $GameRoot $relative
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force }
    }
} else {
    $process = Start-Process -FilePath $exe -ArgumentList @('/uninstall',('"' + $GameRoot + '"')) `
        -WorkingDirectory $GameRoot -Wait -PassThru -ErrorAction Stop
    if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) {
        throw "Publisher uninstaller ended with exit code $($process.ExitCode)."
    }
}
if (Get-HotDInstalled $GameRoot) {
    throw 'Publisher removal left a complete VR installation. Hub state was kept for review.'
}
$stamp = Join-Path $GameRoot '.pcvrhub_version'
if (Test-Path -LiteralPath $stamp -PathType Leaf) { Remove-Item -LiteralPath $stamp -Force }
$receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HOTD_TEST_RECEIPT) {
    [IO.Path]::GetFullPath($env:PCVR_HOTD_TEST_RECEIPT)
} else { Join-Path $PSScriptRoot '.installed_path' }
if (Test-Path -LiteralPath $receipt -PathType Leaf) {
    $saved = (Get-Content -LiteralPath $receipt -Raw).Trim().Trim('"')
    if ($saved -ieq $GameRoot) { Remove-Item -LiteralPath $receipt -Force }
}
Write-Host '  [OK] Publisher HotD2VR removal completed.' -ForegroundColor Green
Write-Host '  Copied game data and your saves/settings remain available.' -ForegroundColor Gray
Finish-HotDRemoval 0
