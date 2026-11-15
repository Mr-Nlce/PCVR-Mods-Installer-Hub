param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

function Finish-DarktideUninstall([int]$Code) { if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }; exit $Code }
function Test-DarktideOwnedRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path 'binaries\Darktide.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path '.pcvrhub_darktidevr_ownership.csv') -PathType Leaf))
}
if (-not $GameRoot) {
    try { $GameRoot=(Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw -ErrorAction Stop).Trim() } catch { $GameRoot='' }
}
if (-not (Test-PCVRGameInstallProof -GameId 'warhammer-40k-darktide-vr' -Root $GameRoot)) {
    Write-Host '[!!] No supported current Darktide installation was selected. Nothing changed.' -ForegroundColor Yellow
    Finish-DarktideUninstall 1
}
if (-not (Test-DarktideOwnedRoot $GameRoot)) { Write-Host '[X] No Hub-owned DarktideVR installation was found. Nothing was guessed or deleted.' -ForegroundColor Red; Finish-DarktideUninstall 1 }
if (Get-Process -Name Darktide -ErrorAction SilentlyContinue) { Write-Host '[X] Close Darktide before removing VR mode.' -ForegroundColor Red; Finish-DarktideUninstall 1 }
if (-not $HubConfirmed) { if ((Read-Host "Remove Hub-owned DarktideVR files from '$GameRoot'? Type REMOVE").Trim() -cne 'REMOVE') { Write-Host 'Cancelled. Nothing changed.'; Finish-DarktideUninstall 0 } }
$modeScript=Join-Path $GameRoot 'mods\darktidevr\darktidevr-mode.ps1'
if (Test-Path -LiteralPath $modeScript -PathType Leaf) {
    $oldPreference=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        $global:LASTEXITCODE=$null
        $output=@(& powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $modeScript -Mode flat -GameRoot $GameRoot 2>&1)
        $modeExit=$global:LASTEXITCODE
    } finally { $ErrorActionPreference=$oldPreference }
    foreach ($line in $output) { Write-Host ('  '+[string]$line) -ForegroundColor Gray }
    if ($null -eq $modeExit -or $modeExit -ne 0) { Write-Host '[!!] Flat mode could not be restored. VR files were left in place.' -ForegroundColor Yellow; Finish-DarktideUninstall 1 }
}
$result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity 'darktidevr'
Write-Host "[OK] Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
Write-Host '[KEEP] Darktide Mod Loader and Darktide Mod Framework remain for other mods.' -ForegroundColor Gray
Write-Host '[KEEP] Flat/VR user settings and recovery data under LocalAppData remain.' -ForegroundColor Gray
if ($result.Preserved -eq 0 -and -not (Test-Path -LiteralPath (Join-Path $GameRoot '.pcvrhub_darktidevr_ownership.csv') -PathType Leaf)) {
    Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Force -ErrorAction SilentlyContinue
}
Finish-DarktideUninstall 0
