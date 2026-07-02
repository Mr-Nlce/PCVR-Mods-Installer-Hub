# ============================================================
#  Slime Rancher - SRVR VR Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "Slime Rancher VR Mod Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_NAME = "Slime Rancher"
$GAME_EXE  = "SlimeRancher.exe"
$SRML_URL  = "https://github.com/SlimeRancherModding/SRML/releases/download/v0.2.1/SRMLInstaller_0.2.1c.zip"
$SRVR_URL  = "https://github.com/Atmudia/SRVR/releases/download/v1.1/SRVR.dll"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "   Slime Rancher - VR Mod Installer" -ForegroundColor Cyan
    Write-Host "   SRML v0.2.1  +  SRVR v1.1" -ForegroundColor Gray
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
# STEP 1: Locate Slime Rancher
# -------------------------------------------------------
Write-Header
Write-Step 1 4 "Locating Slime Rancher"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Slime Rancher"
    }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath
if (-not $steamPath) {
    Write-Warn "Could not find Steam in registry. Please enter your Steam path manually:"
    while (-not $steamPath) {
        $rawInput = (Read-Host "  Steam path").Trim().Trim('"')
        if (Test-Path $rawInput) { $steamPath = $rawInput; Write-OK "Steam path: $steamPath" }
        else { Write-Fail "Not found: $rawInput" }
    }
}

$libraries = Get-SteamLibraries $steamPath
$gamePath  = Find-GamePath $libraries
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "433340" -SteamFolderNames @("Slime Rancher") -GogNames @("Slime Rancher") -EpicNames @("SlimeRancher") }

if (-not $gamePath) {
    Write-Warn "Slime Rancher not found automatically."
    Write-Host "  Enter the folder containing SlimeRancher.exe:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\Slime Rancher" -ForegroundColor Gray
    while (-not $gamePath) {
        $rawInput = (Read-Host "  Game path").Trim().Trim('"')
        if (Test-Path $rawInput) { $gamePath = $rawInput; Write-OK "Game path: $gamePath" }
        else { Write-Fail "Not found: $rawInput" }
    }
} else {
    Write-OK "Slime Rancher found: $gamePath"
}

if (Test-Path (Join-Path $gamePath $GAME_EXE)) { Write-OK "SlimeRancher.exe verified." }
else { Write-Warn "SlimeRancher.exe not found - folder may still be correct." }

# -------------------------------------------------------
# STEP 2: Install SRML
# -------------------------------------------------------
# --- Update-or-install choice (shared helper) ---
$InstallMode = Read-UpdateOrInstall -GameFolder $gamePath -ModFile "SlimeRancher_Data\Managed\UnityEngine.VRModule.dll"
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the mod files." }

Write-Step 2 4 "Installing SRML v0.2.1"

$tempDir = Join-Path $env:TEMP "SRVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$failed = @()

$srmlFolder = Join-Path $gamePath "SRML"

$srmlZip = Join-Path $tempDir "SRML.zip"
$r = Invoke-DownloadOrFallback -Url $SRML_URL -Destination $srmlZip `
        -Label "SRML installer v0.2.1c" `
        -ManualUrl "https://github.com/SlimeRancherModding/SRML/releases/tag/v0.2.1" `
        -Instructions "Download 'SRMLInstaller_0.2.1c.zip' from the GitHub releases page. Place it at '$srmlZip' and choose Retry." `
        -SkipMessage "Skipped - SRML mod loader missing; SRVR will NOT load (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "SRML" }

if ((Test-Path $srmlZip) -and ("SRML" -notin $failed)) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $srmlZip -DestinationFolder $tempDir -Label "SRML" `
            -SkipMessage "Skipped - SRML was NOT extracted; SRVR will NOT load."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            # Find the installer exe in the extracted content
            $srmlExe = Get-ChildItem -Path $tempDir -Filter "SRMLInstaller.exe" -Recurse |
                       Select-Object -First 1

            if ($srmlExe) {
                # Copy to game folder so it auto-detects the game directory
                $srmlExeDest = Join-Path $gamePath "SRMLInstaller.exe"
                Copy-Item -Path $srmlExe.FullName -Destination $srmlExeDest -Force

                Write-Host ""
                Write-Host "  The SRML installer will now open." -ForegroundColor White
                Write-Host "  Follow the on-screen prompts to complete the installation." -ForegroundColor Gray
                Write-Host "  When done, close the installer window and come back here." -ForegroundColor Gray
                Write-Host ""
                Pause-User "Press Enter to launch the SRML installer..."

                $proc = Start-Process -FilePath $srmlExeDest -WorkingDirectory $gamePath -PassThru
                $proc.WaitForExit()

                try { Remove-Item $srmlExeDest -Force -ErrorAction SilentlyContinue } catch {}

                if (Test-Path $srmlFolder) {
                    Write-OK "SRML installed successfully!"
                } else {
                    Write-Warn "SRML folder not found after installer ran - may not have installed."
                    $failed += "SRML"
                }
            } else {
                Write-Fail "SRMLInstaller.exe not found in downloaded zip."
                $failed += "SRML"
            }
        } catch {
            Write-Host "FAILED to run SRML installer: $_" -ForegroundColor Red
            $failed += "SRML"
        }
    } else {
        $failed += "SRML"
    }
}

# -------------------------------------------------------
# STEP 3: Install SRVR.dll
# -------------------------------------------------------
Write-Step 3 4 "Installing SRVR v1.1"

$srmlModsDir = Join-Path $gamePath "SRML\Mods"
if (-not (Test-Path $srmlModsDir)) {
    Write-Warn "SRML\Mods folder not found - creating it."
    try { New-Item -ItemType Directory -Path $srmlModsDir -Force | Out-Null }
    catch { Write-Fail "Could not create SRML\Mods: $_"; $failed += "SRVR" }
}

if ("SRVR" -notin $failed) {
    $srvrDest = Join-Path $srmlModsDir "SRVR.dll"
    $r = Invoke-DownloadOrFallback -Url $SRVR_URL -Destination $srvrDest `
            -Label "SRVR v1.1 (SRVR.dll)" `
            -ManualUrl "https://github.com/Atmudia/SRVR/releases/tag/v1.1" `
            -Instructions "Download 'SRVR.dll' from the GitHub releases page. Place it at '$srvrDest' and choose Retry." `
            -SkipMessage "Skipped - SRVR mod missing; install is incomplete (questionable result)."
    if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ($r -eq $true) {
        Write-OK "SRVR.dll installed to SRML\Mods\"
    } else {
        $failed += "SRVR"
    }
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

# -------------------------------------------------------
# STEP 4: First-launch VR patch
# -------------------------------------------------------
Write-Step 4 4 "First Launch - VR Patch"

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   ACTION REQUIRED - First Launch VR Patch" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  CLOSE STEAMVR NOW before continuing." -ForegroundColor White
Write-Host ""
Write-Host "  Slime Rancher will launch flat (no VR) and self-patch:" -ForegroundColor White
Write-Host "    1) If asked about VR Playground DLC removal: accept it" -ForegroundColor White
Write-Host "    2) A console window patches the game - let it finish" -ForegroundColor White
Write-Host "    3) When asked to optimize for VR: choose NO" -ForegroundColor White
Write-Host "    4) Close Slime Rancher when done" -ForegroundColor White
Write-Host ""
Write-Host "  Press Enter to launch Slime Rancher for the VR patch..." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to launch Slime Rancher for the VR patch..."

Start-Process "steam://rungameid/433340"

Write-Host ""
Write-Host "  Slime Rancher is starting..." -ForegroundColor Gray
Write-Host "  Complete the patching process, then close the game and return here." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter once patching is done and you have closed Slime Rancher..."

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ("SRVR" -notin $failed) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {} }

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation Summary" -ForegroundColor White
Write-Host ""
if ("SRML" -notin $failed) { Write-Host "    [x] SRML v0.2.1" -ForegroundColor Green } else { Write-Host "    [ ] SRML v0.2.1  -- FAILED" -ForegroundColor Red }
if ("SRVR" -notin $failed) { Write-Host "    [x] SRVR v1.1" -ForegroundColor Green   } else { Write-Host "    [ ] SRVR v1.1    -- FAILED" -ForegroundColor Red }
Write-Host "============================================================" -ForegroundColor Magenta

Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."

Write-Host ""
Write-Host "--- How to Play in VR ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Start SteamVR." -ForegroundColor White
Write-Host "  2. Launch Slime Rancher via Steam." -ForegroundColor White
Write-Host "  3. The game detects your headset and starts SteamVR automatically" -ForegroundColor White
Write-Host "     from the second launch onwards." -ForegroundColor Gray
Write-Host ""
Write-Host "  To play without VR: add -novr to Steam Launch Options." -ForegroundColor White
Write-Host ""
Write-Host "--- VR Settings ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In-game: Options -> Other Tab" -ForegroundColor White
Write-Host "  Snap Turn, Turn Sensitivity, Distance Grab, Height Adjust" -ForegroundColor Gray
Write-Host ""
Write-Host "  Vacpack ready. The plorts won't wrangle themselves." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the Slime Rancher folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
