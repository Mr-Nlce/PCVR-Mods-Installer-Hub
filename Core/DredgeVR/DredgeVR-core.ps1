# ============================================================
#  DREDGE - VR Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "DREDGE VR Mod Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_NAME    = "DREDGE"
$GAME_EXE     = "DREDGE.exe"

$WINCH_URL    = "https://github.com/DREDGE-Mods/Winch/releases/download/v0.6.1/Winch.zip"
$DREDGEVR_URL = "https://github.com/xen-42/DredgeVR/releases/latest/download/xen.DredgeVR.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "   DREDGE - VR Mod Installer" -ForegroundColor Cyan
    Write-Host "   Winch v0.6.1  +  DredgeVR (latest)" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Write-Step {
    param($num, $total, $text)
    Write-Host ""
    Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
    Write-Host ""
}

function Write-OK   { param($text) Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host "  [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "  [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host "  [..] $text" -ForegroundColor Gray }

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try {
            $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
            if ($p -and (Test-Path $p)) { return $p }
        } catch {}
    }
    return $null
}

function Get-SteamLibraries {
    param($steamPath)
    $libraries = @($steamPath)
    $vdfPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
    if (Test-Path $vdfPath) {
        $content = Get-Content $vdfPath -Raw
        $found = [regex]::Matches($content, '"path"\s+"([^"]+)"')
        foreach ($m in $found) {
            $lib = $m.Groups[1].Value -replace '\\\\', '\'
            if (Test-Path $lib) { $libraries += $lib }
        }
    }
    return $libraries
}

function Find-GamePath {
    param($libraries)
    foreach ($lib in $libraries) {
        $candidate = Join-Path $lib "steamapps\common\$GAME_NAME"
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

# -------------------------------------------------------
# STEP 1: Locate DREDGE
# -------------------------------------------------------
Write-Header
Write-Step 1 3 "Locating DREDGE"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Dredge"
    }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath

if (-not $steamPath) {
    Write-Warn "Could not find Steam installation in registry."
    Write-Host "  Please enter your Steam installation path manually:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam" -ForegroundColor Gray
    while (-not $steamPath) {
        $rawInput = (Read-Host "  Steam path").Trim().Trim('"')
        if (Test-Path $rawInput) { $steamPath = $rawInput; Write-OK "Steam path set: $steamPath" }
        else { Write-Fail "Path not found: $rawInput" }
    }
}

$libraries = Get-SteamLibraries $steamPath
$gamePath  = Find-GamePath $libraries
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1562430" -SteamFolderNames @("DREDGE") -GogNames @("DREDGE","Dredge") -EpicNames @("DREDGE") }

if (-not $gamePath) {
    Write-Warn "DREDGE not found in Steam libraries automatically."
    Write-Host "  Please enter the DREDGE installation folder manually:" -ForegroundColor White
    Write-Host "  (The folder that contains DREDGE.exe)" -ForegroundColor Gray
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\DREDGE" -ForegroundColor Gray
    while (-not $gamePath) {
        $rawInput = (Read-Host "  Game path").Trim().Trim('"')
        if (Test-Path $rawInput) { $gamePath = $rawInput; Write-OK "Game path set: $gamePath" }
        else { Write-Fail "Path not found: $rawInput" }
    }
} else {
    Write-OK "DREDGE found: $gamePath"
}

if (Test-Path (Join-Path $gamePath $GAME_EXE)) { Write-OK "Game executable found: $GAME_EXE" }
else { Write-Warn "DREDGE.exe not found - folder may still be correct." }

# -------------------------------------------------------
# STEP 2: Install Winch + DredgeVR
# -------------------------------------------------------
Write-Step 2 3 "Installing Winch v0.6.1 + DredgeVR"

$tempDir = Join-Path $env:TEMP "DredgeVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$failed = @()

# --- Winch ---
# The mod manager installs Winch by putting ALL Release/ contents directly into the game root
$winchZip     = Join-Path $tempDir "Winch.zip"
$winchExtract = Join-Path $tempDir "Winch"
$r = Invoke-DownloadOrFallback -Url $WINCH_URL -Destination $winchZip `
        -Label "Winch mod loader v0.6.1" `
        -ManualUrl "https://github.com/DREDGE-Mods/Winch/releases/tag/v0.6.1" `
        -Instructions "Download 'Winch.zip' from the GitHub releases page. Place it at '$winchZip' and choose Retry." `
        -SkipMessage "Skipped - Winch mod loader missing; DredgeVR will NOT load (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "Winch" }

if (Test-Path $winchZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $winchZip -DestinationFolder $winchExtract -Label "Winch" `
            -SkipMessage "Skipped - Winch was not extracted; DredgeVR will NOT load."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            $winchRelease = Join-Path $winchExtract "Release"
            if (-not (Test-Path $winchRelease)) { $winchRelease = $winchExtract }

            Get-ChildItem -Path $winchRelease | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
            }

            if (Test-Path (Join-Path $gamePath "winhttp.dll")) { Write-OK "winhttp.dll verified." }
            else { Write-Warn "winhttp.dll not found." }
            if (Test-Path (Join-Path $gamePath "Winch.dll"))   { Write-OK "Winch.dll verified." }
            else { Write-Warn "Winch.dll not found." }
            Write-OK "Winch v0.6.1 installed!"
        } catch {
            Write-Host "FAILED to install Winch: $_" -ForegroundColor Red
            $failed += "Winch"
        }
    } else {
        $failed += "Winch"
    }
}

# --- DredgeVR ---
# The mod manager puts the entire ZIP contents into Mods/<ModGUID>/
# Winch handles the CopyToGame subfolder internally at runtime
$vrZip     = Join-Path $tempDir "DredgeVR.zip"
$vrExtract = Join-Path $tempDir "DredgeVR"
$modDir    = Join-Path $gamePath "Mods\xen.DredgeVR"
$r = Invoke-DownloadOrFallback -Url $DREDGEVR_URL -Destination $vrZip `
        -Label "DredgeVR (latest)" `
        -ManualUrl "https://github.com/xen-42/DredgeVR/releases/latest" `
        -Instructions "Download 'xen.DredgeVR.zip' from the latest GitHub release. Place it at '$vrZip' and choose Retry." `
        -SkipMessage "Skipped - DredgeVR mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "DredgeVR" }

if (Test-Path $vrZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $vrZip -DestinationFolder $vrExtract -Label "DredgeVR" `
            -SkipMessage "Skipped - DredgeVR was not extracted; install is incomplete."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            if (-not (Test-Path $modDir)) { New-Item -ItemType Directory -Path $modDir -Force | Out-Null }
            Get-ChildItem -Path $vrExtract | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $modDir -Recurse -Force
            }
            if (Test-Path (Join-Path $modDir "DredgeVR.dll"))  { Write-OK "DredgeVR.dll verified." }
            else { Write-Warn "DredgeVR.dll not found." }
            if (Test-Path (Join-Path $modDir "mod_meta.json")) { Write-OK "mod_meta.json verified." }
            else { Write-Warn "mod_meta.json not found." }
            Write-OK "DredgeVR installed!"
        } catch {
            Write-Host "FAILED to install DredgeVR: $_" -ForegroundColor Red
            $failed += "DredgeVR"
        }
    } else {
        $failed += "DredgeVR"
    }
}

# --- Write mod_list.json ---
# CRITICAL: Winch reads this file to know which mods are enabled.
# Without it, no mods load even if all files are in place.
# The mod manager writes this automatically after installing each mod.
Write-Host "  Writing mod_list.json ... " -NoNewline -ForegroundColor White
$modListPath = Join-Path $gamePath "mod_list.json"
$modListContent = '{
  "hacktix.winch": true,
  "xen.DredgeVR": true
}'
try {
    Set-Content -Path $modListPath -Value $modListContent -Encoding UTF8
    Write-Host "OK" -ForegroundColor Green
    Write-OK "mod_list.json written - both mods enabled."
} catch {
    Write-Host "FAILED" -ForegroundColor Red
    Write-Warn "Could not write mod_list.json: $_"
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

# -------------------------------------------------------
# STEP 3: Verify
# -------------------------------------------------------
Write-Step 3 3 "Verifying Installation"

$modDir = Join-Path $gamePath "Mods\xen.DredgeVR"

$checks = @{
    "winhttp.dll"                      = Join-Path $gamePath "winhttp.dll"
    "Winch.dll"                        = Join-Path $gamePath "Winch.dll"
    "doorstop_config.ini"              = Join-Path $gamePath "doorstop_config.ini"
    "mod_list.json"                    = Join-Path $gamePath "mod_list.json"
    "Mods\xen.DredgeVR\DredgeVR.dll"  = Join-Path $modDir "DredgeVR.dll"
    "Mods\xen.DredgeVR\mod_meta.json" = Join-Path $modDir "mod_meta.json"
    "Mods\xen.DredgeVR\CopyToGame"    = Join-Path $modDir "CopyToGame"
}

foreach ($name in $checks.Keys) {
    if (Test-Path $checks[$name]) { Write-OK $name }
    else { Write-Warn "Not found: $name" }
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ("DredgeVR" -notin $failed) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {} }

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation Summary" -ForegroundColor White
Write-Host ""
if ("Winch"    -notin $failed) { Write-Host "    [x] Winch v0.6.1" -ForegroundColor Green     } else { Write-Host "    [ ] Winch v0.6.1  -- FAILED" -ForegroundColor Red }
if ("DredgeVR" -notin $failed) { Write-Host "    [x] DredgeVR (latest)" -ForegroundColor Green } else { Write-Host "    [ ] DredgeVR      -- FAILED" -ForegroundColor Red }
Write-Host "    [x] mod_list.json (mods enabled)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta

Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."

Write-Host ""
Write-Host "--- Important Notes ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  - Launch DREDGE normally via Steam." -ForegroundColor White
Write-Host "    SteamVR will start automatically." -ForegroundColor Gray
Write-Host ""
Write-Host "  - Built-in bindings for Oculus and Valve Index." -ForegroundColor White
Write-Host "    Other controllers may need manual SteamVR binding setup." -ForegroundColor Gray
Write-Host ""
Write-Host "  - Known issue: ocean and ice shaders are not perfect in VR" -ForegroundColor White
Write-Host "    (depth buffer limitation - does not affect gameplay)." -ForegroundColor Gray
Write-Host ""
Write-Host "  More info: https://dredgemods.com/mods/dredge_vr/" -ForegroundColor Gray
Write-Host ""
Write-Host "  Trim the sails. Don't fish after dark." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the DREDGE installation folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
