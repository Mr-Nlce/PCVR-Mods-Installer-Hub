param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'Tribes2VRElevatedOperations.ps1')

function Finish-TribesUninstall([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-TribesOwnedRoot([string]$Root) {
    return [bool]($Root -and
        (Test-Path -LiteralPath (Join-Path $Root 'GameData\Tribes2.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'GameData\.pcvrhub_tribes2vr_ownership.csv') -PathType Leaf))
}

if (-not (Test-TribesOwnedRoot $GameRoot)) {
    foreach ($candidate in @(
        $(try { ([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim() } catch { $null }),
        'C:\Dynamix\Tribes2','D:\Dynamix\Tribes2','E:\Dynamix\Tribes2'
    ) | Where-Object { $_ } | Select-Object -Unique) {
        if (Test-TribesOwnedRoot $candidate) { $GameRoot=(Get-Item -LiteralPath $candidate).FullName; break }
    }
}
if (-not (Test-TribesOwnedRoot $GameRoot)) { Write-Host '  No Hub-owned Tribes 2 VR installation was found.' -ForegroundColor Yellow; Finish-TribesUninstall 0 }
if (Get-Process -Name 'Tribes2','tribes2vr_launcher' -ErrorAction SilentlyContinue) { Write-Host '[X] Close Tribes 2 before removing the VR files.' -ForegroundColor Red; Finish-TribesUninstall 1 }
if (-not $HubConfirmed) {
    $confirm=(''+(Read-Host "Remove Hub-owned Tribes 2 VR files from '$GameRoot'? Type REMOVE")).Trim()
    if ($confirm -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-TribesUninstall 0 }
}

$dataRoot = Join-Path $GameRoot 'GameData'
if (Test-InstallerTargetWritable -TargetPath $dataRoot) {
    $result = Uninstall-OwnedModPayload -GameRoot $dataRoot -Identity 'tribes2vr'
} else {
    Write-Host '  Removing the Hub-owned files needs administrator rights.' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to request administrator rights and continue...')
    $result = Invoke-Tribes2VRElevatedOperation -Action Uninstall -GameRoot $GameRoot
}
if (-not $result.Found -and $null -ne $result.Found) { throw 'The ownership manifest disappeared before removal.' }
$preserved = [int]$result.Preserved
if ($preserved -eq 0) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try { if ([IO.Path]::GetFullPath(([IO.File]::ReadAllText($receipt)).Trim()) -eq [IO.Path]::GetFullPath($GameRoot)) { Remove-Item -LiteralPath $receipt -Force } } catch {}
    }
    try {
        $shortcut=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Tribes 2 VR.lnk'
        if (Test-Path -LiteralPath $shortcut -PathType Leaf) {
            $shell=New-Object -ComObject WScript.Shell; $link=$shell.CreateShortcut($shortcut)
            if ([IO.Path]::GetFullPath($link.TargetPath) -eq [IO.Path]::GetFullPath((Join-Path $dataRoot 'tribes2vr_launcher.exe'))) { Remove-Item -LiteralPath $shortcut -Force }
        }
    } catch {}
}
if ($preserved -gt 0) { Write-Host "  [!!] $preserved changed Hub-owned file(s) were preserved for safety." -ForegroundColor Yellow }
Write-Host "  [OK] Removed $([int]$result.Removed), restored $([int]$result.Restored), preserved $preserved." -ForegroundColor Green
Write-Host '  Tribes 2, TribesNEXT, profiles and unrelated GameData files remain installed.' -ForegroundColor Gray
Finish-TribesUninstall 0
