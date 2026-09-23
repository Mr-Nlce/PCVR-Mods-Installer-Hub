param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$IDENTITY='painkilleroverdosevr'
$receipt=Join-Path $PSScriptRoot '.installed_path'

function Finish-PKODUninstall([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-PKODOwnedRoot([string]$Path) {
    return [bool]($Path -and
        (Test-Path -LiteralPath (Join-Path $Path 'Bin\Overdose.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path ".pcvrhub_${IDENTITY}_ownership.csv") -PathType Leaf))
}

if (-not (Test-PKODOwnedRoot $GameRoot) -and (Test-Path -LiteralPath $receipt -PathType Leaf)) {
    try { $GameRoot=([IO.File]::ReadAllText($receipt)).Trim().Trim('"') } catch { $GameRoot='' }
}
if (-not (Test-PKODOwnedRoot $GameRoot)) {
    Write-Host '  No Hub-owned Painkiller: Overdose VR installation was found.' -ForegroundColor Yellow
    Finish-PKODUninstall 0
}
$GameRoot=(Get-Item -LiteralPath $GameRoot).FullName
if (Get-Process -Name 'Overdose','Painkiller - Overdose VR*' -ErrorAction SilentlyContinue) {
    Write-Host '  [XX] Close Painkiller: Overdose before removing VR mode.' -ForegroundColor Red
    Finish-PKODUninstall 1
}
if (-not $HubConfirmed) {
    $confirm=([string](Read-Host "Remove Hub-owned Painkiller: Overdose VR files from '$GameRoot'? Type REMOVE")).Trim()
    if ($confirm -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-PKODUninstall 0 }
}

$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $IDENTITY
if (-not $result.Found) { throw 'The ownership manifest disappeared before removal.' }
if ($result.Preserved -eq 0) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try {
            $saved=([IO.File]::ReadAllText($receipt)).Trim()
            if ([IO.Path]::GetFullPath($saved) -eq [IO.Path]::GetFullPath($GameRoot)) { Remove-Item -LiteralPath $receipt -Force }
        } catch {}
    }
}
if ($result.Preserved -gt 0) { Write-Host "  [!!] $($result.Preserved) changed Hub-owned file(s) were preserved for safety." -ForegroundColor Yellow }
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved)." -ForegroundColor Green
Write-Host '  The game, saves, settings, Bin and Data folders were not removed.' -ForegroundColor Gray
Write-Host '  Files previously deleted by the publisher launcher cannot be recreated here.' -ForegroundColor Gray
Finish-PKODUninstall 0

