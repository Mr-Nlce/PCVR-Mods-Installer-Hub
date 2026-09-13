param(
    [Parameter(Mandatory=$true)][ValidateSet('duke','blood','shadowwarrior','redneck','nam','ww2gi','exhumed')][string]$Family,
    [switch]$HubConfirmed,
    [switch]$NoPause
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$spec = @{
    duke=@{Name='Duke Nukem 3D';Dirs=@('duke');Patterns=@('Duke Nukem 3D* VR.bat');Icon='DukeNukem3D_VR.ico'}
    blood=@{Name='Blood';Dirs=@('blood');Patterns=@('BLOOD* VR.bat');Icon='Blood_VR.ico'}
    shadowwarrior=@{Name='Shadow Warrior';Dirs=@('shadowwarrior');Patterns=@('Shadow Warrior* VR.bat');Icon='ShadowWarrior_VR.ico'}
    redneck=@{Name='Redneck Rampage';Dirs=@('rampage','ridesagain');Patterns=@('Redneck Rampage* VR.bat');Icon='RedneckRampage_VR.ico'}
    nam=@{Name='NAM';Dirs=@('nam');Patterns=@('NAM* VR.bat','NAPALM* VR.bat');Icon='NAM_VR.ico'}
    ww2gi=@{Name='World War II GI';Dirs=@('ww2gi');Patterns=@('WWII GI* VR.bat','Platoon Leader* VR.bat');Icon='WW2GI_VR.ico'}
    exhumed=@{Name='PowerSlave / Exhumed';Dirs=@('exhumed');Patterns=@('PowerSlave* VR.bat','Exhumed* VR.bat');Icon='PowerSlave_Exhumed_VR.ico'}
}[$Family]
Clear-Host
Write-Host ('=' * 60) -ForegroundColor Magenta
Write-Host "  Remove $($spec.Name) from RazeXR" -ForegroundColor Cyan
Write-Host ('=' * 60) -ForegroundColor Magenta
Write-Host ''
Write-Host '  The shared RazeXR engine and every other installed game stay.' -ForegroundColor White
Write-Host '  This game data is moved into a dated Recovery folder instead' -ForegroundColor White
Write-Host '  of being deleted. Your original store installation is untouched.' -ForegroundColor White
if (-not $HubConfirmed) {
    Write-Host ''
    Write-Host ' >>> Press Enter to continue, or close this window to cancel. ' -ForegroundColor Black -BackgroundColor Yellow
    Read-Host | Out-Null
}
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$recovery = Join-Path $root "PCVRHub Recovery\$Family-$stamp"
[void][IO.Directory]::CreateDirectory($recovery)
foreach ($dir in @($spec.Dirs)) {
    $source = Join-Path $root "games\$dir"
    if (Test-Path -LiteralPath $source -PathType Container) {
        Move-Item -LiteralPath $source -Destination (Join-Path $recovery $dir) -Force -ErrorAction Stop
    }
}
$launcherDir = Join-Path $root 'launchers'
foreach ($pattern in @($spec.Patterns)) {
    foreach ($file in @(Get-ChildItem -LiteralPath $launcherDir -File -Filter $pattern -ErrorAction SilentlyContinue)) {
        Move-Item -LiteralPath $file.FullName -Destination (Join-Path $recovery $file.Name) -Force -ErrorAction SilentlyContinue
    }
}
$stable = Join-Path $root "PCVRHub Launchers\$Family.bat"
if (Test-Path -LiteralPath $stable -PathType Leaf) { Remove-Item -LiteralPath $stable -Force -ErrorAction SilentlyContinue }
$icon = Join-Path $root $spec.Icon
if (Test-Path -LiteralPath $icon -PathType Leaf) {
    Move-Item -LiteralPath $icon -Destination (Join-Path $recovery $spec.Icon) -Force -ErrorAction SilentlyContinue
}
$shortcutName = if ($Family -eq 'exhumed') { 'PowerSlave - Exhumed VR.lnk' } else { "$($spec.Name) VR.lnk" }
$desktop = if ($env:PCVR_RAZEXR_DESKTOP_ROOT) { [string]$env:PCVR_RAZEXR_DESKTOP_ROOT } else { [Environment]::GetFolderPath('Desktop') }
if ($desktop) {
    $shortcut = Join-Path $desktop $shortcutName
    if (Test-Path -LiteralPath $shortcut -PathType Leaf) { Remove-Item -LiteralPath $shortcut -Force -ErrorAction SilentlyContinue }
}
Write-Host ''
Write-Host "  [OK] $($spec.Name) was removed from the active RazeXR library." -ForegroundColor Green
Write-Host "  Recovery copy: $recovery" -ForegroundColor Gray
if (-not $NoPause) {
    Write-Host ''
    Write-Host '  Press Enter to close.' -ForegroundColor White
    Read-Host | Out-Null
}
