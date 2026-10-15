param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-Nomai([int]$Code) { if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }; exit $Code }
function Test-NomaiRoot([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'OuterWilds.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'OWML\Mods\Raicuparta.NomaiVR\.pcvrhub_nomaivr_ownership.csv') -PathType Leaf))
}
if (-not (Test-NomaiRoot $GameRoot)) {
    try { $remembered=([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"'); if (Test-NomaiRoot $remembered) { $GameRoot=$remembered } } catch {}
}
if (-not (Test-NomaiRoot $GameRoot)) { Write-Host '  No Hub-owned NomaiVR installation was found. Manual mods were left alone.' -ForegroundColor Yellow; Finish-Nomai 0 }
if (@(Get-Process -Name 'OuterWilds' -ErrorAction SilentlyContinue).Count) { Write-Host '  Close Outer Wilds before removing NomaiVR.' -ForegroundColor Red; Finish-Nomai 1 }
if (-not $HubConfirmed) {
    $answer=([string](Read-Host "Remove Hub-owned NomaiVR files from '$GameRoot'? Type REMOVE")).Trim()
    if ($answer -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-Nomai 0 }
}
$modRoot=Join-Path $GameRoot 'OWML\Mods\Raicuparta.NomaiVR'
$result=Uninstall-OwnedModPayload -GameRoot $modRoot -Identity 'nomaivr'
if (-not $result.Found) { throw 'The NomaiVR ownership record disappeared before removal.' }
if (-not (Test-Path -LiteralPath (Join-Path $modRoot 'NomaiVR.dll') -PathType Leaf)) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try { if ([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -eq [IO.Path]::GetFullPath($GameRoot)) { Remove-Item -LiteralPath $receipt -Force } } catch {}
    }
}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
if ($result.Preserved -gt 0) { Write-Host '  Review preserved edits in the NomaiVR folder before deleting them manually.' -ForegroundColor Yellow }
Write-Host '  OWML, other mods, the base game and saves remain in place.' -ForegroundColor Gray
Finish-Nomai 0
