# ============================================================
#  Valheim - VHVR-Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "Valheim VR Mod Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_APPID   = "892970"
$GAME_NAME    = "Valheim"
$GAME_EXE     = "valheim.exe"

# BepInExPack Valheim (Thunderstore direct download)
$BEPINEX_URL  = "https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2333/"

# vhvr-mod v0.9.21 (GitHub release)
$VHVR_URL     = "https://github.com/brandonmousseau/vhvr-mod/releases/download/v0.9.21/vhvr-0.9.21.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "   Valheim - VR Mod Installer" -ForegroundColor Cyan
    Write-Host "   BepInExPack Valheim 5.4.2333  +  VHVR-Mod v0.9.21" -ForegroundColor Gray
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
# STEP 1: Locate Valheim
# -------------------------------------------------------
Write-Header
Write-Step 1 3 "Locating Valheim"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Valheim"
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
        if (Test-Path $rawInput) {
            $steamPath = $rawInput
            Write-OK "Steam path set: $steamPath"
        } else {
            Write-Fail "Path not found: $rawInput"
        }
    }
}

$libraries = Get-SteamLibraries $steamPath
$gamePath  = Find-GamePath $libraries
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "892970" -SteamFolderNames @("Valheim") }

if (-not $gamePath) {
    Write-Warn "Valheim not found in Steam libraries automatically."
    Write-Host "  Please enter the Valheim installation folder path manually:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\Valheim" -ForegroundColor Gray
    while (-not $gamePath) {
        $rawInput = (Read-Host "  Valheim path").Trim().Trim('"')
        if (Test-Path $rawInput) {
            $gamePath = $rawInput
            Write-OK "Valheim path set: $gamePath"
        } else {
            Write-Fail "Path not found: $rawInput"
        }
    }
} else {
    Write-OK "Valheim found: $gamePath"
}

$gameExe = Join-Path $gamePath $GAME_EXE
if (Test-Path $gameExe) {
    Write-OK "Game executable found: $GAME_EXE"
} else {
    Write-Warn "Could not find valheim.exe - folder may still be correct."
}

# -------------------------------------------------------
# STEP 2: Install BepInExPack Valheim
# -------------------------------------------------------
Write-Step 2 3 "Installing BepInExPack Valheim"

$tempDir = Join-Path $env:TEMP "ValheimVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$failed  = @()

$bepinexFolder = Join-Path $gamePath "BepInEx"
$winhttpDll    = Join-Path $gamePath "winhttp.dll"
if ((Test-Path $bepinexFolder) -and (Test-Path $winhttpDll)) {
    Write-Warn "BepInEx is already installed - replacing with correct version (5.4.2333)."
    Write-Host ""
}

Write-Host "  Downloading BepInExPack Valheim 5.4.2333 ... " -NoNewline -ForegroundColor White
$bepZip     = Join-Path $tempDir "BepInExPack.zip"
$bepZip     = Join-Path $tempDir "BepInExPack.zip"
$bepExtract = Join-Path $tempDir "BepInExPack"
$r = Invoke-DownloadOrFallback -Url $BEPINEX_URL -Destination $bepZip `
        -Label "BepInExPack Valheim 5.4.2333" `
        -ManualUrl "https://thunderstore.io/c/valheim/p/denikson/BepInExPack_Valheim/" `
        -Instructions "Download the latest BepInExPack_Valheim ZIP from the Thunderstore page. Place it at '$bepZip' and choose Retry." `
        -SkipMessage "Skipped - BepInExPack missing; VHVR will NOT load (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "BepInExPack" }

if (Test-Path $bepZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $bepZip -DestinationFolder $bepExtract -Label "BepInExPack" `
            -SkipMessage "Skipped - BepInExPack was NOT extracted; VHVR will NOT load."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            $innerFolder = Join-Path $bepExtract "BepInExPack_Valheim"
            if (-not (Test-Path $innerFolder)) { $innerFolder = $bepExtract }

            Get-ChildItem -Path $innerFolder | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
            }
            Write-OK "BepInExPack Valheim installed!"
        } catch {
            Write-Host "FAILED to install BepInExPack: $_" -ForegroundColor Red
            $failed += "BepInExPack"
        }
    } else {
        $failed += "BepInExPack"
    }
}

# -------------------------------------------------------
# STEP 3: Install vhvr-mod
# -------------------------------------------------------
Write-Step 3 3 "Installing VHVR-Mod v0.9.21"

$vrZip     = Join-Path $tempDir "vhvr.zip"
$vrExtract = Join-Path $tempDir "vhvr"
$r = Invoke-DownloadOrFallback -Url $VHVR_URL -Destination $vrZip `
        -Label "Valheim VR (VHVR) v0.9.21" `
        -ManualUrl "https://github.com/brandonmousseau/vhvr-mod/releases/tag/v0.9.21" `
        -Instructions "Download 'vhvr-0.9.21.zip' from the GitHub releases page. Place it at '$vrZip' and choose Retry." `
        -SkipMessage "Skipped - VHVR mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "VHVR-Mod" }

if (Test-Path $vrZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $vrZip -DestinationFolder $vrExtract -Label "VHVR-Mod" `
            -SkipMessage "Skipped - VHVR was NOT extracted; install is incomplete."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            # Ensure BepInEx/plugins exists (created by BepInEx on first run, but we need it now)
            $pluginsPath = Join-Path $gamePath "BepInEx\plugins"
            if (-not (Test-Path $pluginsPath)) {
                New-Item -ItemType Directory -Path $pluginsPath -Force | Out-Null
                Write-OK "Created BepInEx\plugins folder."
            }

            # Merge the full zip contents into the game folder (zip contains BepInEx\ tree)
            Get-ChildItem -Path $vrExtract | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
            }

            # Verify DLL landed correctly
            $dllCheck = Join-Path $gamePath "BepInEx\plugins\ValheimVRMod.dll"
            if (Test-Path $dllCheck) {
                Write-OK "ValheimVRMod.dll verified in BepInEx\plugins."
            } else {
                Write-Warn "ValheimVRMod.dll not at expected path - searching zip..."
                $foundDll = Get-ChildItem -Path $vrExtract -Recurse -Filter "ValheimVRMod.dll" | Select-Object -First 1
                if ($foundDll) {
                    Copy-Item -Path $foundDll.FullName -Destination $pluginsPath -Force
                    Write-OK "ValheimVRMod.dll placed manually into BepInEx\plugins."
                } else {
                    Write-Warn "Could not locate ValheimVRMod.dll - please install manually."
                }
            }
            Write-OK "VHVR-Mod v0.9.21 installed!"
        } catch {
            Write-Host "FAILED to install VHVR-Mod: $_" -ForegroundColor Red
            $failed += "VHVR-Mod"
        }
    } else {
        $failed += "VHVR-Mod"
    }
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ("VHVR-Mod" -notin $failed) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {} }

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation Summary" -ForegroundColor White
Write-Host ""
if ("BepInExPack" -notin $failed) { Write-Host "    [x] BepInExPack Valheim 5.4.2333" -ForegroundColor Green } else { Write-Host "    [ ] BepInExPack Valheim  -- FAILED, install manually" -ForegroundColor Red }
if ("VHVR-Mod"   -notin $failed) { Write-Host "    [x] VHVR-Mod v0.9.21" -ForegroundColor Green             } else { Write-Host "    [ ] VHVR-Mod v0.9.21     -- FAILED, install manually" -ForegroundColor Red }
Write-Host "============================================================" -ForegroundColor Magenta

Write-Host ""
Write-Host "--- CRITICAL: Disable Vulkan ---" -ForegroundColor Yellow
Write-Host ""
Write-Host "  VHVR does NOT support Vulkan. You MUST use DX11." -ForegroundColor Yellow
Write-Host "  When launching Valheim, always choose:" -ForegroundColor White
Write-Host "    'Play Valheim'  (NOT 'Play Valheim (Vulkan)')" -ForegroundColor Green
Write-Host ""
try { Set-Clipboard -Value "-force-d3d11" } catch {}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   ACTION REQUIRED - Steam Launch Option" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [OK] Launch parameter copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host "  (-force-d3d11  |  VHVR requires DX11, not Vulkan)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Press Enter to open Steam Launch Options..." -ForegroundColor Yellow
Write-Host "  Then paste (Ctrl+V) and close Properties." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to open Valheim properties in Steam..."
Start-Process "steam://gameproperties/$GAME_APPID"
try { Set-Clipboard -Value "-force-d3d11" } catch {}
Pause-User "Press Enter once you have set -force-d3d11 in Launch Options..."

Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."

Write-Host ""
Write-Host "--- Important Notes ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  - Start SteamVR BEFORE launching Valheim." -ForegroundColor White
Write-Host ""
Write-Host "  - First launch takes longer - BepInEx configures itself." -ForegroundColor White
Write-Host ""
Write-Host "  - On first launch, go to Settings -> Graphics and disable:" -ForegroundColor White
Write-Host "    Bloom, Anti-Aliasing, Motion Blur" -ForegroundColor Gray
Write-Host "    (These cause issues in VR)" -ForegroundColor Gray
Write-Host ""
Write-Host "  - Press HOME key to recenter HMD tracking." -ForegroundColor White
Write-Host ""
Write-Host "  - DO NOT update Valheim via Steam - it may break the mod." -ForegroundColor Yellow
Write-Host "    Right-click Valheim -> Properties -> Updates ->" -ForegroundColor Gray
Write-Host "    'Only update when I launch it'" -ForegroundColor Gray
Write-Host ""
Write-Host "  Odin is watching. Swing that axe in VR!" -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the Valheim installation folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
