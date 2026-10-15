param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause, [string]$DesktopRoot='')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
function Finish-RBR([int]$Code) { if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }; exit $Code }
function Test-RBRRoot([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'RichardBurnsRally_SSE.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root '.pcvrhub_rbrvr_ownership.csv') -PathType Leaf))
}
if (-not (Test-RBRRoot $GameRoot)) {
    try { $remembered=([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim().Trim('"'); if (Test-RBRRoot $remembered) { $GameRoot=$remembered } } catch {}
}
if (-not (Test-RBRRoot $GameRoot)) { Write-Host '  No Hub-owned RBRvr installation was found. Existing manual installs remain untouched.' -ForegroundColor Yellow; Finish-RBR 0 }
if (@(Get-Process -Name 'RichardBurnsRally_SSE' -ErrorAction SilentlyContinue).Count) { Write-Host '  Close Richard Burns Rally before removing RBRvr.' -ForegroundColor Red; Finish-RBR 1 }
if (-not $HubConfirmed) {
    $answer=([string](Read-Host "Remove Hub-owned RBRvr files from '$GameRoot'? Type REMOVE")).Trim()
    if ($answer -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-RBR 0 }
}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'rbrvr'
if (-not $result.Found) { throw 'The RBRvr ownership manifest disappeared before removal.' }
if (-not (Test-Path -LiteralPath (Join-Path $GameRoot 'Plugins\RBRvrConfig.dll') -PathType Leaf)) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try { if ([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -eq [IO.Path]::GetFullPath($GameRoot)) { Remove-Item -LiteralPath $receipt -Force } } catch {}
    }
    if (-not $DesktopRoot) { $DesktopRoot=[Environment]::GetFolderPath('Desktop') }
    $shortcut=Join-Path $DesktopRoot 'Richard Burns Rally VR.lnk'
    if (Test-Path -LiteralPath $shortcut -PathType Leaf) {
        try {
            $link=(New-Object -ComObject WScript.Shell).CreateShortcut($shortcut)
            if ([IO.Path]::GetFullPath($link.TargetPath) -eq [IO.Path]::GetFullPath((Join-Path $GameRoot 'RichardBurnsRally_SSE.exe'))) {
                Remove-Item -LiteralPath $shortcut -Force -ErrorAction Stop
            }
        } catch { Write-Host '  The desktop shortcut could not be checked; remove it manually if it still points to this game.' -ForegroundColor Yellow }
    }
}
Write-Host "  [OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
if ($result.Preserved -gt 0) { Write-Host '  Review the preserved edited files before removing them manually.' -ForegroundColor Yellow }
Write-Host '  The base game, saves and unrelated files remain in place.' -ForegroundColor Gray
Finish-RBR 0
