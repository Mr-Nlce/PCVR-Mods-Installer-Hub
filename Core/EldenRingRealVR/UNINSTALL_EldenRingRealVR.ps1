# Elden Ring VR (Gamepad / R.E.A.L.) uninstaller - Current and Depot aware.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path (Split-Path -Parent $PSScriptRoot) "EldenRingVR\EldenRingDepot.ps1")
function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Pause-User { param($t="Press Enter to continue...") Write-Host ""; Write-Host " >>> $t " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$realFiles = @("dxgi.dll","RealVR64.dll","openvr_api.dll","cudart64_12.dll","RealVR.ini")
$realDirs = @("RealRepo","RealRepo_")
$launcherRel = "VRLaunch\Elden Ring VR (Gamepad).bat"
$roots = @()
try {
    $live = Find-SteamGameFolder -AppId 1245620 -SteamFolderNames @("ELDEN RING") -ProbeExe "Game\eldenring.exe"
    if (Test-EldenRingRoot $live) { $roots += [pscustomobject]@{ Label="Current"; Path=$live } }
} catch {}
$depot = "C:\Games\Elden Ring VR"
if ((Test-EldenRingRoot $depot) -and ($roots.Path -notcontains $depot)) { $roots += [pscustomobject]@{ Label="Depot 1.16.2"; Path=$depot } }
try {
    $record = (Get-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Raw -ErrorAction Stop).Trim()
    if ((Test-EldenRingRoot $record) -and ($roots.Path -notcontains $record)) { $roots += [pscustomobject]@{ Label="Recorded"; Path=$record } }
} catch {}
$installed = @($roots | Where-Object {
    (Test-Path -LiteralPath (Join-Path $_.Path $launcherRel)) -or
    (Test-Path -LiteralPath (Join-Path $_.Path "Game\RealRepo\RealVR64.dll")) -or
    (Test-Path -LiteralPath (Join-Path $_.Path "Game\RealRepo_\RealVR64.dll"))
})

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Elden Ring VR - remove Gamepad R.E.A.L." -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
if ($installed.Count -eq 0) { Write-Info "R.E.A.L. was not found in Current or Depot."; Pause-User "Press Enter to exit."; exit 0 }
Write-Host ""
for ($i=0; $i -lt $installed.Count; $i++) { Write-Host "  [$($i+1)] $($installed[$i].Label) - $($installed[$i].Path)" -ForegroundColor White }
if ($installed.Count -gt 1) { Write-Host "  [a] All listed builds" -ForegroundColor White }
$pick = if ($installed.Count -eq 1) { "1" } else { (Read-Host "  Remove from which build?").Trim().ToLower() }
$targets = if ($pick -eq "a") { $installed } else {
    $idx=0
    if ([int]::TryParse($pick,[ref]$idx) -and $idx -ge 1 -and $idx -le $installed.Count) { @($installed[$idx-1]) } else { @() }
}
if ($targets.Count -eq 0) { Write-Info "Nothing was changed."; Pause-User "Press Enter to exit."; exit 0 }
if ((Read-Host "  Confirm removal? [y/n]").Trim().ToLower() -notin @("y","yes")) { Write-Info "Nothing was changed."; Pause-User "Press Enter to exit."; exit 0 }
if (Get-Process -Name "eldenring","start_protected_game" -ErrorAction SilentlyContinue) { Write-Warn "Elden Ring is running. Close it and retry."; Pause-User "Press Enter to exit."; exit 1 }

foreach ($r in $targets) {
    $game = Join-Path $r.Path "Game"
    $ervrHere = Test-Path -LiteralPath (Join-Path $game "ERVR\ERVR.dll")
    foreach ($f in $realFiles) {
        if ($f -eq "dxgi.dll" -and $ervrHere) { Write-Warn "Kept $($r.Label) Game\dxgi.dll because ERVR is present."; continue }
        $p = Join-Path $game $f
        if (Test-Path -LiteralPath $p) { try { Remove-Item -LiteralPath $p -Force; Write-OK "Removed $($r.Label) Game\$f" } catch { Write-Warn "Could not remove $p" } }
    }
    foreach ($d in $realDirs) {
        $p = Join-Path $game $d
        if (Test-Path -LiteralPath $p) { try { Remove-Item -LiteralPath $p -Recurse -Force; Write-OK "Removed $($r.Label) Game\$d" } catch { Write-Warn "Could not remove $p" } }
    }
    $launcher = Join-Path $r.Path $launcherRel
    if (Test-Path -LiteralPath $launcher) { try { Remove-Item -LiteralPath $launcher -Force } catch {} }
    $suffix = if ($r.Path -ieq $depot) { "Depot 1.16.2" } else { "Current" }
    $shortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "Elden Ring VR Gamepad ($suffix).lnk"
    if (Test-Path -LiteralPath $shortcut) { try { Remove-Item -LiteralPath $shortcut -Force } catch {} }
}
foreach ($rec in @(".installed_version",".installed_path")) {
    $p = Join-Path $PSScriptRoot $rec
    if (Test-Path -LiteralPath $p) { try { Remove-Item -LiteralPath $p -Force } catch {} }
}
Write-Host ""
Write-OK "Gamepad removal finished. Elden Ring and the motion mods were preserved."
Pause-User "Press Enter to exit."
