# ============================================================
# Elden Ring VR - Motion Controls installer
# ============================================================
# One Hub entry, two motion-control mods, and two game-build targets:
#   Hotbite  - portable ModEngine 3 package under LOCALAPPDATA
#   ERVR     - ReShade add-on inside the selected Elden Ring copy
#   Current  - the live Steam build (1.17 is currently incompatible)
#   Depot    - a separate pinned 1.16.2 copy under C:\Games

param(
    [ValidateSet('','Hotbite','ERVR')][string]$Mod = ''
)

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "EldenRingDepot.ps1")
. (Join-Path $PSScriptRoot "EldenRingSettings.ps1")

$Host.UI.RawUI.WindowTitle = "Elden Ring VR (Motion Controls) Installer"
$ErrorActionPreference = "Stop"

function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  [$n/$t] $x" -ForegroundColor Cyan; Write-Host "  ----------------------------------------" -ForegroundColor DarkGray }
function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$NEXUS_URL   = "https://www.nexusmods.com/eldenring/mods/10659?tab=files"
$MOD_MARKER  = "mod\eldenring_vr.dll"
$VR_ROOT     = Join-Path $env:LOCALAPPDATA "Programs\Elden Ring VR Motion"
$STEAM_APPID = "1245620"
$GAME_PROBE  = "Game\eldenring.exe"

function Get-EldenRingFolder {
    $p = $null
    try { $p = Find-SteamGameFolder -AppId $STEAM_APPID -SteamFolderNames @("ELDEN RING") -ProbeExe $GAME_PROBE } catch {}
    if (-not $p) {
        try { $p = Get-GameFolderInteractive -GameName "Elden Ring" -ExeName "eldenring.exe" } catch {}
    }
    return $p
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Elden Ring VR - Motion Controls" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
if (-not $Mod) {
    Write-Fail "No mod was selected by the Hub."
    Write-Info "Use Install Hotbite or Install ERVR on the Elden Ring detail page."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Selected in the Hub: $Mod"

$currentGame = Get-EldenRingFolder
if (Test-EldenRingRoot $currentGame) {
    Write-OK "Current Steam copy: $currentGame"
} else {
    $currentGame = ""
    Write-Warn "The current Steam installation was not found."
    Write-Info "You can still build the separate pinned depot if you own Elden Ring on Steam."
}

$target = Select-EldenRingBuildTarget -CurrentGameDir $currentGame
if (-not $target -or -not (Test-EldenRingRoot $target.GameDir)) {
    Write-Fail "No valid Elden Ring target was selected."
    Pause-User "Press Enter to exit."
    exit 1
}
$gameDir = [string]$target.GameDir
Write-OK "Install target: $gameDir ($($target.Label))"

if ($Mod -eq "ERVR") {
    $ervr = Join-Path $PSScriptRoot "EldenRingErvr.ps1"
    if (-not (Test-Path -LiteralPath $ervr)) {
        Write-Fail "The ERVR installer is missing: $ervr"
        Pause-User "Press Enter to exit."
        exit 1
    }
    & $ervr -GameDir $gameDir -BuildMode $target.Mode
    exit $LASTEXITCODE
}

# ---------------- Hotbite ----------------
Write-Host ""
Write-Host "  HOTBITE ALPHA WARNING " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  The author says it has only run on one Quest 3 / SteamVR" -ForegroundColor White
Write-Host "  machine. The Nexus page also warns that Elden Ring 1.17 broke" -ForegroundColor White
Write-Host "  the mod; the pinned 1.16.2 depot is the recommended target." -ForegroundColor White
Write-Host ""
Show-AntivirusNotice

Write-Step 1 3 "Getting Hotbite from Nexus"
Pause-User "Press Enter to open the Nexus files page..." | Out-Null
try { Start-Process $NEXUS_URL } catch { Write-Warn "Open manually: $NEXUS_URL" }
Pause-User "Press Enter once the ZIP is downloaded..." | Out-Null

$downloads = Join-Path ([Environment]::GetFolderPath('UserProfile')) "Downloads"
$zip = $null
foreach ($c in @(Get-ChildItem -LiteralPath $downloads -Filter "*.zip" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)) {
    if (Test-ArchiveContains -ArchivePath $c.FullName -Entry "eldenring_vr.dll") {
        Write-Host ""
        Write-Host "  A matching ZIP was found in Downloads:" -ForegroundColor White
        Write-Host "    $($c.FullName)" -ForegroundColor Cyan
        Write-Host "    $([Math]::Round($c.Length / 1MB, 2)) MB - modified $($c.LastWriteTime)" -ForegroundColor Gray
        $useFound = ""
        for ($ask = 1; $ask -le 20; $ask++) {
            $useFound = ("" + (Read-Host "  Use exactly this ZIP? [y/n]")).Trim().ToLower()
            if ($useFound -in @("y","yes","n","no")) { break }
            Write-Warn "Please answer y or n."
        }
        if ($useFound -in @("y","yes")) { $zip = $c.FullName }
        else { Write-Info "The Downloads ZIP was not selected; choose the file explicitly." }
        break
    }
}
if (-not $zip) {
    Write-Warn "No Hotbite archive has been confirmed."
    for ($try = 1; $try -le 10; $try++) {
        $raw = ("" + (Read-Host "  Drag the Hotbite ZIP here (empty cancels)")).Trim().Trim('"').Trim("'")
        if (-not $raw) { break }
        if ((Test-Path -LiteralPath $raw -PathType Leaf) -and (Test-ArchiveContains -ArchivePath $raw -Entry "eldenring_vr.dll")) {
            $zip = $raw; break
        }
        Write-Warn "That file is not the Hotbite archive."
    }
}
if (-not $zip) {
    Write-Fail "No valid Hotbite archive was supplied; nothing was installed."
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Archive: $(Split-Path -Leaf $zip)"

Write-Step 2 3 "Installing Hotbite"
$tmp = Join-Path $env:TEMP ("eldenring_hotbite_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$expanded = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $tmp -Label "Elden Ring VR by Hotbite"
if ([string]$expanded -eq "quit") {
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
$launcherProbe = Get-ChildItem -LiteralPath $tmp -Recurse -Filter "launch-eldenring-vr.bat" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $launcherProbe) {
    Write-Fail "launch-eldenring-vr.bat was not found in the archive."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
$srcRoot = $launcherProbe.DirectoryName
$tuningPath = Join-Path $VR_ROOT 'mod\ervr-tuning.cfg'
$existingTuning = $null
if (Test-Path -LiteralPath $tuningPath -PathType Leaf) {
    try { $existingTuning = [IO.File]::ReadAllBytes($tuningPath) } catch {}
}
try {
    if (-not (Test-Path -LiteralPath $VR_ROOT)) { New-Item -ItemType Directory -Path $VR_ROOT -Force | Out-Null }
    [void](Merge-DirectoryTreeVerified -Source $srcRoot -Destination $VR_ROOT -Label "Hotbite motion-control mod")
    if ($null -ne $existingTuning) {
        [IO.File]::WriteAllBytes($tuningPath, $existingTuning)
        Write-OK "Kept your existing Hotbite tuning settings."
    } else {
        $stereo = Set-EldenRingHotbite3D -Path $tuningPath -NoBackup
        if (-not $stereo.Success) { throw "Could not enable Hotbite 3D: $($stereo.Reason)" }
        Write-OK "Hotbite starts in stereo 3D."
    }
} catch {
    Write-Fail "Could not install Hotbite: $($_.Exception.Message)"
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

$hotDll = Join-Path $VR_ROOT $MOD_MARKER
if (-not (Test-Path -LiteralPath $hotDll)) {
    Write-Fail "Hotbite's eldenring_vr.dll did not arrive in $VR_ROOT"
    Pause-User "Press Enter to exit."
    exit 1
}
$hotSurvived = Confirm-PlacedFilesSurvive -Paths @($hotDll) -GameDir $VR_ROOT -ArchivePath $zip
if (-not $hotSurvived) {
    Write-Fail "Hotbite's DLL was removed or quarantined after installation."
    Pause-User "Press Enter to exit."
    exit 1
}

try {
    $hubLauncher = Write-EldenRingMotionLauncher -GameDir $gameDir
    Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force
    Write-OK "Registered the selected build with the Hub."
} catch {
    Write-Fail "Could not create the Hub launcher: $($_.Exception.Message)"
    Pause-User "Press Enter to exit."
    exit 1
}

try {
    $suffix = if ($target.Mode -eq "Depot") { "Depot 1.16.2" } else { "Current" }
    $lnk = Join-Path ([Environment]::GetFolderPath("Desktop")) "Elden Ring VR Motion ($suffix).lnk"
    [void](New-DesktopShortcut -LnkPath $lnk -TargetPath $hubLauncher -WorkingDir (Split-Path -Parent $hubLauncher) -Description "Elden Ring VR motion controls - $suffix")
    Write-OK "Desktop shortcut created."
} catch { Write-Warn "Could not create the desktop shortcut; launch from the Hub." }

Write-Step 3 3 "Finished"
Write-Host "  Installed Hotbite for: $gameDir" -ForegroundColor White
Write-Host "  Start SteamVR first, then use Start Current / Start Depot in" -ForegroundColor Gray
Write-Host "  the Hub (or the matching desktop shortcut)." -ForegroundColor Gray
Write-Host ""
Write-Host "  Display and input settings are directly available on the" -ForegroundColor Gray
Write-Host "  Elden Ring detail page: Hotbite 3D / Hotbite config." -ForegroundColor Cyan
Write-Host ""
Pause-User "Press Enter to exit."
