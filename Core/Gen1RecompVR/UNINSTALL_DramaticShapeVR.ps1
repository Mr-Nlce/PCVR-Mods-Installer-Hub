param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

function Finish-DramaticUninstall([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-DramaticOwnedRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'DramaticShapeVR.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_dramaticshapevr_ownership.csv') -PathType Leaf))
}

if (-not (Test-DramaticOwnedRoot $GameRoot)) {
    foreach ($candidate in @(
        $(try { ([IO.File]::ReadAllText((Join-Path $PSScriptRoot '.installed_path'))).Trim() } catch { $null }),
        'C:\Games\Pokemon Dramatic Shape VR','D:\Games\Pokemon Dramatic Shape VR','E:\Games\Pokemon Dramatic Shape VR'
    ) | Where-Object { $_ } | Select-Object -Unique) {
        if (Test-DramaticOwnedRoot $candidate) { $GameRoot=(Get-Item -LiteralPath $candidate).FullName; break }
    }
}
if (-not (Test-DramaticOwnedRoot $GameRoot)) {
    Write-Host '  No Hub-owned Pokemon Dramatic Shape VR installation was found.' -ForegroundColor Yellow
    Finish-DramaticUninstall 0
}
if (Get-Process -Name 'DramaticShapeVR' -ErrorAction SilentlyContinue) {
    Write-Host '[X] Close Dramatic Shape VR before removing the runtime.' -ForegroundColor Red
    Finish-DramaticUninstall 1
}
if (-not $HubConfirmed) {
    $confirm=(''+(Read-Host "Remove Hub-owned Dramatic Shape VR files from '$GameRoot'? Type REMOVE")).Trim()
    if ($confirm -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-DramaticUninstall 0 }
}

$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'dramaticshapevr'
if (-not $result.Found) { throw 'The runtime ownership manifest disappeared before removal.' }
if ([int]$result.Preserved -eq 0) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    foreach ($name in @('.installed_path','.launch_exe')) {
        $receipt=Join-Path $PSScriptRoot $name
        if (Test-Path -LiteralPath $receipt -PathType Leaf) {
            try {
                $saved=([IO.File]::ReadAllText($receipt)).Trim()
                if ($name -eq '.launch_exe') { $saved=Split-Path -Parent $saved }
                if ([IO.Path]::GetFullPath($saved) -eq [IO.Path]::GetFullPath($GameRoot)) { Remove-Item -LiteralPath $receipt -Force }
            } catch {}
        }
    }
    try {
        $shortcut=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Pokemon Dramatic Shape VR.lnk'
        if (Test-Path -LiteralPath $shortcut -PathType Leaf) {
            $shell=New-Object -ComObject WScript.Shell; $link=$shell.CreateShortcut($shortcut)
            if ([IO.Path]::GetFullPath($link.TargetPath) -eq [IO.Path]::GetFullPath((Join-Path $GameRoot 'DramaticShapeVR.exe'))) {
                Remove-Item -LiteralPath $shortcut -Force
            }
        }
    } catch {}
}
if ([int]$result.Preserved -gt 0) {
    Write-Host "  [!!] $([int]$result.Preserved) publisher-updated or otherwise changed file(s) were preserved for safety." -ForegroundColor Yellow
    Write-Host '  Check the dedicated folder and remove it manually if it contains no files you added.' -ForegroundColor Gray
}
Write-Host "  [OK] Removed $([int]$result.Removed), restored $([int]$result.Restored), preserved $([int]$result.Preserved)." -ForegroundColor Green
Write-Host '  ROM-derived data, saves, settings and screenshots in %APPDATA%\DramaticShapeVR were preserved.' -ForegroundColor Gray
Write-Host '  Older %APPDATA%\pokemon-love2d profiles were not touched.' -ForegroundColor Gray
Finish-DramaticUninstall 0
