param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

function Finish-DoomUninstall([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
function Test-DoomModRoot([string]$Path) {
    if (-not $Path) { return $false }
    try {
        $full = [IO.Path]::GetFullPath($Path).TrimEnd('\','/')
        return ((Split-Path -Leaf $full) -eq 'DOOM 2016 VR' -and
            (Test-Path -LiteralPath (Join-Path $full '.pcvrhub_kharvox_ownership.csv') -PathType Leaf))
    } catch { return $false }
}

if (-not (Test-DoomModRoot $GameRoot)) {
    try {
        $recorded = (Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw -ErrorAction Stop).Trim()
        if (Test-DoomModRoot $recorded) { $GameRoot = $recorded }
    } catch {}
}
if (-not (Test-DoomModRoot $GameRoot)) {
    foreach ($candidate in @('C:\Games\DOOM 2016 VR','D:\Games\DOOM 2016 VR','E:\Games\DOOM 2016 VR')) {
        if (Test-DoomModRoot $candidate) { $GameRoot = $candidate; break }
    }
}
if (-not (Test-DoomModRoot $GameRoot)) {
    Write-Host '[X] No Hub-owned KHARVOX installation was found. Nothing was guessed or deleted.' -ForegroundColor Red
    Finish-DoomUninstall 1
}
if (Get-Process -Name @('KharvoxLauncher','DOOMx64','DOOMx64vk') -ErrorAction SilentlyContinue) {
    Write-Host '[X] Close KHARVOX and DOOM before removing the VR mod.' -ForegroundColor Red
    Finish-DoomUninstall 1
}
if (-not $HubConfirmed) {
    $answer = ('' + (Read-Host "Remove Hub-owned KHARVOX files from '$GameRoot'? Type REMOVE")).Trim()
    if ($answer -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-DoomUninstall 0 }
}
$result = Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'kharvox'
Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
Write-Host '[KEEP] Original DOOM files, saves and the game folder were never touched.' -ForegroundColor Gray
Write-Host '[KEEP] KHARVOX launcher settings in LocalAppData remain available for a reinstall.' -ForegroundColor Gray
if ($result.Preserved -eq 0 -and -not (Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_kharvox_ownership.csv') -PathType Leaf)) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Force -ErrorAction SilentlyContinue
    $desktop = ('' + $env:PCVR_DOOM2016_DESKTOP_ROOT).Trim()
    if (-not $desktop) { $desktop = [Environment]::GetFolderPath('Desktop') }
    if ($desktop) { Remove-Item -LiteralPath (Join-Path $desktop 'DOOM 2016 VR.lnk') -Force -ErrorAction SilentlyContinue }
}
Finish-DoomUninstall 0
