param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

function Finish-PreyUninstall([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-PreyOwnedRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'PreyVR.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_prey2006vr_ownership.csv') -PathType Leaf))
}

if (-not (Test-PreyOwnedRoot $GameRoot)) {
    foreach ($candidate in @(
        $(try { ([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim() } catch { $null }),
        'C:\Games\PreyVR','D:\Games\PreyVR','E:\Games\PreyVR'
    ) | Where-Object { $_ } | Select-Object -Unique) {
        if (Test-PreyOwnedRoot $candidate) { $GameRoot=(Get-Item -LiteralPath $candidate).FullName; break }
    }
}
if (-not (Test-PreyOwnedRoot $GameRoot)) {
    Write-Host '  No Hub-owned PreyVR installation was found.' -ForegroundColor Yellow
    Finish-PreyUninstall 0
}
if (Get-Process -Name 'PreyVR' -ErrorAction SilentlyContinue) {
    Write-Host '[X] Close PreyVR before removing the runtime.' -ForegroundColor Red
    Finish-PreyUninstall 1
}
if (-not $HubConfirmed) {
    $confirm=(''+(Read-Host "Remove Hub-owned PreyVR runtime files from '$GameRoot'? Type REMOVE")).Trim()
    if ($confirm -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-PreyUninstall 0 }
}

$generated=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'prey2006vrgenerated'
$runtime=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'prey2006vr'
if (-not $runtime.Found) { throw 'The runtime ownership manifest disappeared before removal.' }
$preserved=[int]$generated.Preserved+[int]$runtime.Preserved
if ($preserved -eq 0) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try {
            $saved=([IO.File]::ReadAllText($receipt)).Trim()
            if ([IO.Path]::GetFullPath($saved) -eq [IO.Path]::GetFullPath($GameRoot)) { Remove-Item -LiteralPath $receipt -Force }
        } catch {}
    }
    try {
        $shortcut=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Prey (2006) VR.lnk'
        if (Test-Path -LiteralPath $shortcut -PathType Leaf) {
            $shell=New-Object -ComObject WScript.Shell; $link=$shell.CreateShortcut($shortcut)
            if ([IO.Path]::GetFullPath($link.TargetPath) -eq [IO.Path]::GetFullPath((Join-Path $GameRoot 'Play PreyVR.bat'))) { Remove-Item -LiteralPath $shortcut -Force }
        }
    } catch {}
}
if ($preserved -gt 0) { Write-Host "  [!!] $preserved changed Hub-owned file(s) were preserved for safety." -ForegroundColor Yellow }
Write-Host "  [OK] Removed $([int]$generated.Removed+[int]$runtime.Removed), restored $([int]$generated.Restored+[int]$runtime.Restored), preserved $preserved." -ForegroundColor Green
Write-Host '  Your seven retail PK4 files, saves, settings and unrelated files remain.' -ForegroundColor Gray
Write-Host '  Delete the standalone folder manually only when you no longer want those copies.' -ForegroundColor Gray
Finish-PreyUninstall 0
