param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

function Finish-GoldenEyeUninstall([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-GoldenEyeOwnedRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'Start-GEVR.bat') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_goldeneye007vr_ownership.csv') -PathType Leaf))
}

if (-not (Test-GoldenEyeOwnedRoot $GameRoot)) {
    foreach ($candidate in @(
        $(try { ([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim() } catch { $null }),
        'C:\Games\GoldenEye 007 VR','D:\Games\GoldenEye 007 VR','E:\Games\GoldenEye 007 VR'
    ) | Where-Object { $_ } | Select-Object -Unique) {
        if (Test-GoldenEyeOwnedRoot $candidate) { $GameRoot=(Get-Item -LiteralPath $candidate).FullName; break }
    }
}
if (-not (Test-GoldenEyeOwnedRoot $GameRoot)) {
    Write-Host '  No Hub-owned GoldenEye 007 VR installation was found.' -ForegroundColor Yellow
    Finish-GoldenEyeUninstall 0
}
if (Get-Process -Name 'goldeneye','GevrRomStarter','gevr_prepare' -ErrorAction SilentlyContinue) {
    Write-Host '[X] Close GoldenEye 007 VR before removing the runtime.' -ForegroundColor Red
    Finish-GoldenEyeUninstall 1
}
if (-not $HubConfirmed) {
    $confirm=(''+(Read-Host "Remove Hub-owned GEVR runtime files from '$GameRoot'? Type REMOVE")).Trim()
    if ($confirm -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-GoldenEyeUninstall 0 }
}

$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'goldeneye007vr'
if (-not $result.Found) { throw 'The runtime ownership manifest disappeared before removal.' }
if ([int]$result.Preserved -eq 0) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try {
            $saved=([IO.File]::ReadAllText($receipt)).Trim()
            if ([IO.Path]::GetFullPath($saved) -eq [IO.Path]::GetFullPath($GameRoot)) { Remove-Item -LiteralPath $receipt -Force }
        } catch {}
    }
    try {
        $shortcut=Join-Path ([Environment]::GetFolderPath('Desktop')) 'GoldenEye 007 VR.lnk'
        if (Test-Path -LiteralPath $shortcut -PathType Leaf) {
            $shell=New-Object -ComObject WScript.Shell; $link=$shell.CreateShortcut($shortcut)
            if ([IO.Path]::GetFullPath($link.TargetPath) -in @(
                [IO.Path]::GetFullPath((Join-Path $GameRoot 'Start-GEVR-Hub.bat')),
                [IO.Path]::GetFullPath((Join-Path $GameRoot 'Start-GEVR.bat'))
            )) { Remove-Item -LiteralPath $shortcut -Force }
        }
    } catch {}
}
if ([int]$result.Preserved -gt 0) { Write-Host "  [!!] $([int]$result.Preserved) changed Hub-owned file(s) were preserved for safety." -ForegroundColor Yellow }
Write-Host "  [OK] Removed $([int]$result.Removed), restored $([int]$result.Restored), preserved $([int]$result.Preserved)." -ForegroundColor Green
Write-Host '  Your ROM, LocalAppData cache, saves and unrelated files were not removed.' -ForegroundColor Gray
Finish-GoldenEyeUninstall 0
