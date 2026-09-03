param(
    [ValidateSet('','Hotbite','ERVR')]
    [string]$Mod = '',
    [switch]$HubConfirmed,
    [switch]$NoPause
)

# Elden Ring VR (Motion Controls) uninstaller
# Handles Hotbite's shared portable folder plus ERVR in either/both build copies.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "EldenRingDepot.ps1")

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Pause-User { param($t="Press Enter to continue...") if ($NoPause) { return }; Write-Host ""; Write-Host " >>> $t " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$hotRoot = Join-Path $env:LOCALAPPDATA "Programs\Elden Ring VR Motion"
$launcherRels = @(
    "VRLaunch\Elden Ring VR (Motion Controls).bat",
    "VRLaunch\Elden Ring VR (Hotbite).bat",
    "VRLaunch\Elden Ring VR (ERVR).bat"
)
$ervrFiles = @("dxgi.dll","dinput8.dll","ReShade.ini")
$roots = @()
try {
    $live = Find-SteamGameFolder -AppId 1245620 -SteamFolderNames @("ELDEN RING") -ProbeExe "Game\eldenring.exe"
    if (Test-EldenRingRoot $live) { $roots += [pscustomobject]@{ Label="Current"; Path=$live } }
} catch {}
$depot = "C:\Games\Elden Ring VR"
if ((Test-EldenRingRoot $depot) -and ($roots.Path -notcontains $depot)) {
    $roots += [pscustomobject]@{ Label="Depot 1.16.2"; Path=$depot }
}
try {
    $record = (Get-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Raw -ErrorAction Stop).Trim()
    if ((Test-EldenRingRoot $record) -and ($roots.Path -notcontains $record)) {
        $roots += [pscustomobject]@{ Label="Recorded"; Path=$record }
    }
} catch {}

$ervrRoots = @($roots | Where-Object {
    (Test-Path -LiteralPath (Join-Path $_.Path "Game\ERVR\ERVR.dll")) -or
    (Test-Path -LiteralPath (Join-Path $_.Path "Game\.pcvrhub-ervr-backup\manifest.txt"))
})
$hotHere = Test-Path -LiteralPath (Join-Path $hotRoot "mod\eldenring_vr.dll")

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Elden Ring VR - remove Motion Controls" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
if (-not $hotHere -and $ervrRoots.Count -eq 0) {
    Write-Info "Neither Hotbite nor ERVR was found."
    Pause-User "Press Enter to exit."
    exit 0
}
if ($hotHere) { Write-Host "  [1] Hotbite (shared by Current and Depot launchers)" -ForegroundColor White }
if ($ervrRoots.Count -gt 0) {
    Write-Host "  [2] ERVR in:" -ForegroundColor White
    foreach ($r in $ervrRoots) { Write-Host "      $($r.Label): $($r.Path)" -ForegroundColor Gray }
}
Write-Host ""
$choice = if ($Mod -eq 'Hotbite') { '1' }
          elseif ($Mod -eq 'ERVR') { '2' }
          elseif ($hotHere -and $ervrRoots.Count -gt 0) { (Read-Host "  Remove 1, 2, b=both, c=cancel").Trim().ToLower() }
          elseif ($hotHere) { "1" } else { "2" }
if ($choice -notin @("1","2","b")) { Write-Info "Nothing was changed."; Pause-User "Press Enter to exit."; exit 0 }
if (-not $HubConfirmed -and (Read-Host "  Confirm removal? [y/n]").Trim().ToLower() -notin @("y","yes")) {
    Write-Info "Nothing was changed."; Pause-User "Press Enter to exit."; exit 0
}
if (Get-Process -Name "eldenring","start_protected_game" -ErrorAction SilentlyContinue) {
    Write-Warn "Elden Ring is running. Close it completely and run this again."
    Pause-User "Press Enter to exit."
    exit 1
}

$removeHot = $choice -in @("1","b")
$removeErvr = $choice -in @("2","b")
$selectedErvrRoots = $ervrRoots
if ($removeErvr -and $ervrRoots.Count -gt 1) {
    Write-Host ""
    for ($i=0; $i -lt $ervrRoots.Count; $i++) { Write-Host "  [$($i+1)] $($ervrRoots[$i].Label) - $($ervrRoots[$i].Path)" -ForegroundColor Gray }
    Write-Host "  [a] All listed builds" -ForegroundColor Gray
    $rp = (Read-Host "  Remove ERVR from which build?").Trim().ToLower()
    if ($rp -ne "a") {
        $idx = 0
        if ([int]::TryParse($rp, [ref]$idx) -and $idx -ge 1 -and $idx -le $ervrRoots.Count) { $selectedErvrRoots = @($ervrRoots[$idx-1]) }
        else { Write-Warn "Invalid selection; ERVR was not removed."; $selectedErvrRoots = @() }
    }
}

if ($removeErvr) {
    foreach ($r in $selectedErvrRoots) {
        $game = Join-Path $r.Path "Game"
        $realHere = (Test-Path -LiteralPath (Join-Path $game "RealRepo\RealVR64.dll")) -or
                    (Test-Path -LiteralPath (Join-Path $game "RealRepo_\RealVR64.dll"))
        $backupDir = Join-Path $game ".pcvrhub-ervr-backup"
        $backupManifest = Join-Path $backupDir "manifest.txt"
        $ownership = @{}
        if (Test-Path -LiteralPath $backupManifest -PathType Leaf) {
            try {
                foreach ($line in (Get-Content -LiteralPath $backupManifest -ErrorAction Stop)) {
                    if ($line -match '^([^=]+)=(restore|remove|keep)$') { $ownership[$matches[1]] = $matches[2] }
                }
            } catch {}
        }
        foreach ($f in $ervrFiles) {
            if ($f -eq "dxgi.dll" -and $realHere) {
                Write-Warn "Kept $($r.Label) Game\dxgi.dll because R.E.A.L. is also present."
                continue
            }
            $p = Join-Path $game $f
            $mode = if ($ownership.ContainsKey($f)) { [string]$ownership[$f] } else { "remove" }
            try {
                if ($mode -eq "restore" -and (Test-Path -LiteralPath (Join-Path $backupDir $f) -PathType Leaf)) {
                    Copy-Item -LiteralPath (Join-Path $backupDir $f) -Destination $p -Force -ErrorAction Stop
                    Write-OK "Restored the pre-ERVR $($r.Label) Game\$f"
                } elseif ($mode -eq "keep") {
                    Write-Info "Kept the pre-existing $($r.Label) Game\$f"
                } elseif (Test-Path -LiteralPath $p) {
                    Remove-Item -LiteralPath $p -Force -ErrorAction Stop
                    Write-OK "Removed $($r.Label) Game\$f"
                }
            } catch { Write-Warn "Could not clean $p" }
        }
        $dir = Join-Path $game "ERVR"
        if (Test-Path -LiteralPath $dir) { try { Remove-Item -LiteralPath $dir -Recurse -Force; Write-OK "Removed ERVR from $($r.Label)" } catch { Write-Warn "Could not remove $dir" } }
        if (Test-Path -LiteralPath $backupDir) { try { Remove-Item -LiteralPath $backupDir -Recurse -Force } catch { Write-Warn "Could not remove $backupDir" } }
    }
}
if ($removeHot -and (Test-Path -LiteralPath $hotRoot)) {
    try { Remove-Item -LiteralPath $hotRoot -Recurse -Force; Write-OK "Removed Hotbite: $hotRoot" } catch { Write-Warn "Could not remove $hotRoot" }
}

# Keep the common launcher wherever at least one motion mod still works.
foreach ($r in $roots) {
    $hasErvr = Test-Path -LiteralPath (Join-Path $r.Path "Game\ERVR\ERVR.dll")
    $hasHot = Test-Path -LiteralPath (Join-Path $hotRoot "mod\eldenring_vr.dll")
    if ($hasErvr -or $hasHot) {
        try {
            $keptLauncher = Write-EldenRingMotionLauncher -GameDir $r.Path
            $suffix = if ($r.Path -ieq $depot) { "Depot 1.16.2" } else { "Current" }
            $lnkPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Elden Ring VR Motion ($suffix).lnk"
            [void](New-DesktopShortcut -LnkPath $lnkPath -TargetPath $keptLauncher -WorkingDir (Split-Path -Parent $keptLauncher) -Description "Elden Ring VR motion controls - $suffix")
        } catch {}
    } else {
        foreach ($launcherRel in $launcherRels) {
            $launcher = Join-Path $r.Path $launcherRel
            if (Test-Path -LiteralPath $launcher) { try { Remove-Item -LiteralPath $launcher -Force } catch {} }
        }
        $suffix = if ($r.Path -ieq $depot) { "Depot 1.16.2" } else { "Current" }
        $lnkPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Elden Ring VR Motion ($suffix).lnk"
        if (Test-Path -LiteralPath $lnkPath) { try { Remove-Item -LiteralPath $lnkPath -Force } catch {} }
        $vrLaunchDir = Join-Path $r.Path "VRLaunch"
        if (Test-Path -LiteralPath $vrLaunchDir -PathType Container) {
            try { if (@(Get-ChildItem -LiteralPath $vrLaunchDir -Force).Count -eq 0) { Remove-Item -LiteralPath $vrLaunchDir -Force } } catch {}
        }
    }
}
# If the game/depot folder disappeared before uninstall, it is not in $roots,
# but its build-specific desktop shortcut can still exist. Once no motion mod
# remains anywhere we know about, remove both exact shortcut names as well.
$anyErvrLeft = @($roots | Where-Object { Test-Path -LiteralPath (Join-Path $_.Path "Game\ERVR\ERVR.dll") }).Count -gt 0
$anyHotLeft = Test-Path -LiteralPath (Join-Path $hotRoot "mod\eldenring_vr.dll")
if (-not $anyErvrLeft -and -not $anyHotLeft) {
    foreach ($suffix in @("Current","Depot 1.16.2")) {
        $lnkPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Elden Ring VR Motion ($suffix).lnk"
        if (Test-Path -LiteralPath $lnkPath) { try { Remove-Item -LiteralPath $lnkPath -Force } catch {} }
    }
}
if (-not $anyErvrLeft -and -not $anyHotLeft) {
    foreach ($rec in @(".installed_version",".installed_path")) {
        $p = Join-Path $PSScriptRoot $rec
        if (Test-Path -LiteralPath $p) { try { Remove-Item -LiteralPath $p -Force } catch {} }
    }
}
Write-Host ""
Write-OK "Motion-control removal finished. Current/depot game copies were preserved."
Pause-User "Press Enter to exit."
