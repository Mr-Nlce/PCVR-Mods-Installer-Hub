param([string]$GameRoot='',[string]$StateRoot='',[switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
if (-not $StateRoot) { $StateRoot = $PSScriptRoot }
$manifestName = '.pcvrhub-outbound-install.tsv'
$backupName = '.pcvrhub-outbound-backup'

function Stop-OutboundUninstall([int]$Code=0) {
    if (-not $NoPause) { Write-Host ''; Read-Host '  Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-OutboundRoot([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $Path 'Outbound.exe') -PathType Leaf) -or
           (Test-Path -LiteralPath (Join-Path $Path $manifestName) -PathType Leaf) -or
           (Test-Path -LiteralPath (Join-Path $Path 'dxgi.dll') -PathType Leaf) -or
           (Test-Path -LiteralPath (Join-Path $Path 'dxgi.dll.aus') -PathType Leaf)
}
function Resolve-OutboundRoot([string]$Preferred,[string]$MarkerRoot) {
    if (Test-OutboundRoot $Preferred) { return [IO.Path]::GetFullPath($Preferred) }
    try { $saved=(Get-Content -LiteralPath (Join-Path $MarkerRoot '.installed_path') -Raw -ErrorAction Stop).Trim(); if (Test-OutboundRoot $saved) { return [IO.Path]::GetFullPath($saved) } } catch {}
    try { $found=Find-SteamGameFolder -AppId '2681030' -SteamFolderNames @('Outbound') -EpicNames @('Outbound') -ProbeExe 'Outbound.exe'; if (Test-OutboundRoot $found) { return [IO.Path]::GetFullPath($found) } } catch {}
    return $null
}
function Get-Sha([string]$Path) { try { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant() } catch { return '' } }

$GameRoot=Resolve-OutboundRoot -Preferred $GameRoot -MarkerRoot $StateRoot
if (-not $GameRoot) { Write-Host '  [!!] Outbound / OutboundVR was not found. Nothing was changed.' -ForegroundColor Yellow; Stop-OutboundUninstall 1 }
if (Get-Process -Name 'Outbound' -ErrorAction SilentlyContinue) { Write-Host '  [!!] Close Outbound before uninstalling the VR mod.' -ForegroundColor Yellow; Stop-OutboundUninstall 1 }
if (-not $HubConfirmed) { $answer=(Read-Host '  Type yes to remove OutboundVR (game, saves and unrelated mods stay)').Trim(); if ($answer -ne 'yes') { Stop-OutboundUninstall 0 } }

Write-Host '============================================================' -ForegroundColor Magenta
Write-Host ' Outbound VR - safe removal' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host "  Game: $GameRoot" -ForegroundColor Gray

$manifest=Join-Path $GameRoot $manifestName
$backupRoot=Join-Path $GameRoot $backupName
$removed=0; $restored=0; $kept=0
if (Test-Path -LiteralPath $manifest -PathType Leaf) {
    foreach ($line in @(Get-Content -LiteralPath $manifest -Encoding UTF8 | Select-Object -Skip 1)) {
        $p=$line -split "`t",4
        if ($p.Count -ne 4 -or -not $p[1]) { continue }
        $action=$p[0]; $rel=$p[1]; $installedSha=$p[2]; $backupRel=$p[3]
        $target=[IO.Path]::GetFullPath([IO.Path]::Combine($GameRoot,$rel))
        if (-not $target.StartsWith(([IO.Path]::GetFullPath($GameRoot).TrimEnd('\')+'\'),[StringComparison]::OrdinalIgnoreCase)) { $kept++; continue }
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            if ($installedSha -and (Get-Sha $target) -ne $installedSha) {
                Write-Host "  [!!] Kept changed file: $rel" -ForegroundColor Yellow; $kept++; continue
            }
            Remove-Item -LiteralPath $target -Force -ErrorAction Stop; $removed++
        }
        if ($action -eq 'restore' -and $backupRel) {
            $backup=[IO.Path]::Combine($backupRoot,$backupRel)
            if (Test-Path -LiteralPath $backup -PathType Leaf) {
                $parent=Split-Path -Parent $target; if (-not (Test-Path -LiteralPath $parent)) { [void](New-Item -ItemType Directory -Path $parent -Force) }
                Move-Item -LiteralPath $backup -Destination $target -Force -ErrorAction Stop; $restored++
            }
        }
    }
} else {
    # Legacy/manual 2.0.0 install without a Hub manifest: remove only the
    # inspected mod DLL when its bytes match. Shared OpenXR files stay.
    foreach ($leaf in @('dxgi.dll','dxgi.dll.aus')) {
        $target=Join-Path $GameRoot $leaf
        if ((Test-Path -LiteralPath $target -PathType Leaf) -and (Get-Sha $target) -eq '20bd0a5b6bc3570ae3a5a6271006d09f203e30c90e6021ef0192992673b03186') { Remove-Item -LiteralPath $target -Force; $removed++ }
    }
}

if ($kept -eq 0) {
    foreach ($meta in @($manifest,$backupRoot)) { if (Test-Path -LiteralPath $meta) { Remove-Item -LiteralPath $meta -Recurse -Force -ErrorAction SilentlyContinue } }
}
foreach ($marker in @('.installed_path','.installed_version')) { $p=Join-Path $StateRoot $marker; if (Test-Path -LiteralPath $p -PathType Leaf) { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue } }
$gameVersion=Join-Path $GameRoot '.pcvrhub_version'; if (Test-Path -LiteralPath $gameVersion -PathType Leaf) { Remove-Item -LiteralPath $gameVersion -Force -ErrorAction SilentlyContinue }

Write-Host "  [OK] Removed $removed installed file(s); restored $restored pre-existing file(s)." -ForegroundColor Green
if ($kept) { Write-Host "  [!!] $kept changed file(s) were preserved. The uninstall record remains for inspection." -ForegroundColor Yellow }
Write-Host '  [..] The game, saves, shared BepInEx and unrelated mods were preserved.' -ForegroundColor Gray
Stop-OutboundUninstall 0
