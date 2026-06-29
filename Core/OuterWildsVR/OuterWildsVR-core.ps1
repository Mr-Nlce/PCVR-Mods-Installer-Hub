# ============================================================
#  Outer Wilds - NomaiVR Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "NomaiVR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_FOLDER  = "Outer Wilds"
$GAME_EXE     = "OuterWilds.exe"
$OWML_URL     = "https://github.com/ow-mods/owml/releases/download/2.15.5/OWML.zip"
$MOD_URL      = "https://github.com/Raicuparta/nomai-vr/releases/download/2.10.0/Raicuparta.NomaiVR.zip"
$INFO_URL     = "https://outerwildsmods.com/mods/nomaivr/"

function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Yellow; Write-Host "   Outer Wilds - NomaiVR Installer" -ForegroundColor Yellow; Write-Host "   OWML 2.15.5  +  NomaiVR 2.10.0 by Raicuparta" -ForegroundColor Gray; Write-Host "============================================================" -ForegroundColor Yellow; Write-Host "" }
function Write-Step   { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK     { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Warn   { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail   { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-Info   { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p=(Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
    }; return $null
}
function Get-SteamLibraries {
    param($sp); $libs=@($sp)
    $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
    if(Test-Path $vdf){ $c=Get-Content $vdf -Raw; [regex]::Matches($c,'"path"\s+"([^"]+)"') | ForEach-Object { $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
    return $libs
}

Write-Header

# STEP 1: Locate Outer Wilds
Write-Step 1 4 "Locating Outer Wilds"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_FOLDER -Title "Outer Wilds"
    }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath
$gamePath  = $null

if ($steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $c = Join-Path $lib "steamapps\common\$GAME_FOLDER"
        if (Test-Path $c) { $gamePath = $c; break }
    }
}

if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "753640" -SteamFolderNames @("Outer Wilds") -ProbeExe "OWML\OWML.Launcher.exe" -EpicNames @("Outer Wilds","OuterWilds") }
if ($gamePath) {
    Write-OK "Outer Wilds found: $gamePath"
} else {
    Write-Warn "Outer Wilds not found in Steam libraries automatically."
    Write-Host ""
    Write-Host "  Xbox / Game Pass users: please follow the manual setup guide first." -ForegroundColor Yellow
    Write-Host "  Guide: $INFO_URL" -ForegroundColor Cyan
    Write-Host ""
    $openGuide = Read-Host "  Open the Xbox/GamePass guide in browser? [Y/N]"
    if ($openGuide -match "^[yY]") { Start-Process $INFO_URL }
    Write-Host ""
    Write-Host "  Enter your Outer Wilds installation folder:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\Outer Wilds" -ForegroundColor Gray
    while (-not $gamePath) {
        $r = (Read-Host "  Path").Trim().Trim('"')
        if (Test-Path $r) { $gamePath = $r; Write-OK "Path set: $gamePath" }
        else { Write-Fail "Not found: $r" }
    }
}

# STEP 2: Download
Write-Step 2 4 "Downloading OWML + NomaiVR"

$tempDir = Join-Path $env:TEMP "OuterWildsVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Host "  Downloading OWML 2.15.5 ... " -NoNewline -ForegroundColor White
$owmlZip = Join-Path $tempDir "OWML.zip"
$r = Invoke-DownloadOrFallback -Url $OWML_URL -Destination $owmlZip `
        -Label "OWML v2.15.5" `
        -ManualUrl "https://github.com/ow-mods/owml/releases/tag/2.15.5" `
        -Instructions "Download 'OWML.zip' from the GitHub releases page. Place it at '$owmlZip' and choose Retry." `
        -SkipMessage "Skipped - OWML mod loader missing; NomaiVR will NOT load (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { Pause-User "Install cannot continue without OWML. Press Enter to exit..."; exit 1 }

Write-Host "  Downloading NomaiVR 2.10.0 ... " -NoNewline -ForegroundColor White
$modZip = Join-Path $tempDir "NomaiVR.zip"
$r = Invoke-DownloadOrFallback -Url $MOD_URL -Destination $modZip `
        -Label "NomaiVR v2.10.0" `
        -ManualUrl "https://github.com/Raicuparta/nomai-vr/releases/tag/2.10.0" `
        -Instructions "Download 'Raicuparta.NomaiVR.zip' from the GitHub releases page. Place it at '$modZip' and choose Retry." `
        -SkipMessage "Skipped - NomaiVR mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { Pause-User "Install cannot continue without NomaiVR. Press Enter to exit..."; exit 1 }

# STEP 3: Install OWML into its own subfolder inside the game directory
Write-Step 3 4 "Installing OWML"

# OWML lives in its own folder: <GameDir>\OWML\
$owmlPath = Join-Path $gamePath "OWML"
if (-not (Test-Path $owmlPath)) { New-Item -ItemType Directory -Path $owmlPath -Force | Out-Null }

Write-Host "  Extracting OWML to $owmlPath ... " -NoNewline -ForegroundColor White
$efb = Expand-ArchiveOrFallback -ArchivePath $owmlZip -DestinationFolder $owmlPath -Label "OWML" `
        -SkipMessage "Skipped - OWML was not extracted; NomaiVR will NOT load."
if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
    Write-Host "OK" -ForegroundColor Green
    Write-OK "OWML installed to: $owmlPath"
} else {
    Pause-User "OWML extraction skipped. Install cannot continue. Press Enter to exit..."; exit 1
}

# Write gamePath into OWML config so it knows where the game is
$owmlConfig = Join-Path $owmlPath "OWML.Config.json"
$defaultConfig = Join-Path $owmlPath "OWML.DefaultConfig.json"
$configFile = if (Test-Path $owmlConfig) { $owmlConfig } else { $defaultConfig }
try {
    $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
    $cfg.gamePath = $gamePath -replace '\\', '/'
    $cfg | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $owmlPath "OWML.Config.json") -Encoding UTF8
    Write-OK "OWML config written with game path: $gamePath"
} catch {
    Write-Warn "Could not auto-write OWML config: $_"
    Write-Info "You may need to set the game path manually in OWML.Config.json"
}

# Create Mods folder
$modsPath = Join-Path $owmlPath "Mods"
if (-not (Test-Path $modsPath)) { New-Item -ItemType Directory -Path $modsPath -Force | Out-Null }

# STEP 4: Install NomaiVR
Write-Step 4 4 "Installing NomaiVR"

$modTargetPath = Join-Path $modsPath "Raicuparta.NomaiVR"
if (-not (Test-Path $modTargetPath)) { New-Item -ItemType Directory -Path $modTargetPath -Force | Out-Null }

Write-Host "  Extracting NomaiVR to OWML\Mods\Raicuparta.NomaiVR ... " -NoNewline -ForegroundColor White
try {
    Expand-Archive -Path $modZip -DestinationPath $modTargetPath -Force
    Write-Host "OK" -ForegroundColor Green
    Write-OK "NomaiVR installed."
} catch {
    Write-Host "FAILED" -ForegroundColor Red; Write-Host "    $_" -ForegroundColor Gray
}

# Verify
$manifestCheck = Join-Path $modTargetPath "manifest.json"
if (Test-Path $manifestCheck) { Write-OK "manifest.json verified." }
else { Write-Warn "manifest.json not found - check $modTargetPath manually." }

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# Create Desktop shortcut to OWML.Launcher.exe
$owmlLauncher = Join-Path $owmlPath "OWML.Launcher.exe"
if (Test-Path $owmlLauncher) {
    try {
        $shell    = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut("$env:USERPROFILE\Desktop\Outer Wilds VR.lnk")
        $shortcut.TargetPath       = $owmlLauncher
        $shortcut.WorkingDirectory = $owmlPath
        $shortcut.Description      = "Outer Wilds VR (NomaiVR via OWML)"
        # Use the game's own exe icon
        $gameExePath = Join-Path $gamePath "OuterWilds.exe"
        if (Test-Path $gameExePath) { $shortcut.IconLocation = "$gameExePath,0" }
        $shortcut.Save()
        Write-OK "Desktop shortcut created: 'Outer Wilds VR'"
    } catch {
        Write-Warn "Could not create desktop shortcut: $_"
        Write-Info "Launch manually: $owmlLauncher"
    }
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# Done
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Launch via the desktop shortcut 'Outer Wilds VR'" -ForegroundColor Green
Write-Host "  or directly from:" -ForegroundColor White
Write-Host "  $owmlLauncher" -ForegroundColor Gray
Write-Host ""
Write-Host "  Do NOT launch Outer Wilds from Steam directly!" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."
Write-Host ""
Write-Host "  Full motion controls supported!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  The Hatchling sets out. Twenty-two minutes is plenty of time." -ForegroundColor Magenta
Write-Host ""
try { Start-Process explorer.exe "`"$owmlPath`"" } catch {}
Pause-User "Press Enter to exit."
