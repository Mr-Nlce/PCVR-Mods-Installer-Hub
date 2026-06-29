# ============================================================
#  Life is Strange: Before the Storm - DawnVR Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "Life is Strange: BtS - DawnVR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_APPID      = "554620"
$GAME_NAME       = "Life Is Strange - Before the Storm"
$GAME_EXE        = "Life is Strange- Before the Storm.exe"
$GAME_EXE_ALT    = "Life is Strange - Before the Storm Remastered.exe"

$MELONLOADER_URL      = "https://github.com/LavaGang/MelonLoader/releases/download/v0.5.7/MelonLoader.x64.zip"
$DAWNVR_ORIGINAL_URL  = "https://github.com/TrevTV/DawnVR/releases/download/1.0.1/DawnVR_1.0.1_Original.zip"
$DAWNVR_REMASTER_URL  = "https://github.com/TrevTV/DawnVR/releases/download/1.0.1/DawnVR_1.0.1_Remaster.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "   Life is Strange: Before the Storm - DawnVR Installer" -ForegroundColor Cyan
    Write-Host "   MelonLoader 0.5.7  +  DawnVR v1.0.1" -ForegroundColor Gray
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

function Find-GameExe {
    param($gamePath)
    $base     = Join-Path $gamePath $GAME_EXE
    $remaster = Join-Path $gamePath $GAME_EXE_ALT
    if (Test-Path $base)     { return $base }
    if (Test-Path $remaster) { return $remaster }
    $found = Get-ChildItem -Path $gamePath -Filter "Life is Strange*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { return $found.FullName }
    return $null
}

# -------------------------------------------------------
# STEP 1: Choose game edition
# -------------------------------------------------------
Write-Header
Write-Step 1 4 "Choose Your Game Edition"

Write-Host "  DawnVR has separate versions for the Original and Remastered edition." -ForegroundColor White
Write-Host ""
Write-Host "  [1] Original (Life is Strange: Before the Storm)" -ForegroundColor White
Write-Host "  [2] Remastered (Life is Strange Remastered Collection)" -ForegroundColor White
Write-Host ""

$edition = ""
while ($edition -notin @("1","2")) {
    $edition = (Read-Host "  Enter 1 or 2").Trim()
    if ($edition -notin @("1","2")) { Write-Fail "Please enter 1 or 2." }
}

if ($edition -eq "1") {
    $DAWNVR_URL    = $DAWNVR_ORIGINAL_URL
    $EDITION_LABEL = "Original"
    Write-OK "Selected: Original edition"
} else {
    $DAWNVR_URL    = $DAWNVR_REMASTER_URL
    $EDITION_LABEL = "Remastered"
    Write-OK "Selected: Remastered edition"
}

# -------------------------------------------------------
# STEP 2: Locate the game
# -------------------------------------------------------
Write-Step 2 4 "Locating Life is Strange: Before the Storm"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Life is Strange: BtS"
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
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "554620" -SteamFolderNames @("Life is Strange - Before the Storm") -GogNames @("Life is Strange Before the Storm") -EpicNames @("Life is Strange Before the Storm") }

if (-not $gamePath) {
    Write-Warn "Game not found in Steam libraries automatically."
    Write-Host "  Please enter the game installation folder path manually:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\Life Is Strange - Before the Storm" -ForegroundColor Gray
    while (-not $gamePath) {
        $rawInput = (Read-Host "  Game path").Trim().Trim('"')
        if (Test-Path $rawInput) {
            $gamePath = $rawInput
            Write-OK "Game path set: $gamePath"
        } else {
            Write-Fail "Path not found: $rawInput"
        }
    }
} else {
    Write-OK "Game found: $gamePath"
}

$gameExe = Find-GameExe $gamePath
if ($gameExe) {
    Write-OK "Game executable: $(Split-Path $gameExe -Leaf)"
} else {
    Write-Warn "Could not find game executable automatically."
    Write-Host "  Please enter the full path to the game's .exe file:" -ForegroundColor White
    while (-not $gameExe) {
        $rawInput = (Read-Host "  Game exe path").Trim().Trim('"')
        if (Test-Path $rawInput) {
            $gameExe = $rawInput
            Write-OK "Game exe set: $gameExe"
        } else {
            Write-Fail "File not found: $rawInput"
        }
    }
}

# -------------------------------------------------------
# STEP 3: Install MelonLoader 0.5.7
# -------------------------------------------------------
Write-Step 3 4 "Installing MelonLoader 0.5.7"

Write-Host "  IMPORTANT: Only MelonLoader 0.5.7 is supported by DawnVR." -ForegroundColor Yellow
Write-Host "  Other versions will NOT work." -ForegroundColor Yellow
Write-Host ""

$mlFolder   = Join-Path $gamePath "MelonLoader"
$versionDll = Join-Path $gamePath "version.dll"
if ((Test-Path $mlFolder) -and (Test-Path $versionDll)) {
    Write-Warn "MelonLoader already exists - replacing with 0.5.7."
}

$tempDir = Join-Path $env:TEMP "DawnVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$failed = @()

$mlZip     = Join-Path $tempDir "MelonLoader.zip"
$mlExtract = Join-Path $tempDir "MelonLoader"
$r = Invoke-DownloadOrFallback -Url $MELONLOADER_URL -Destination $mlZip `
        -Label "MelonLoader v0.5.7" `
        -ManualUrl "https://github.com/LavaGang/MelonLoader/releases/tag/v0.5.7" `
        -Instructions "Download 'MelonLoader.x64.zip' from the GitHub releases page. Place it at '$mlZip' and choose Retry." `
        -SkipMessage "Skipped - MelonLoader missing; DawnVR will NOT load (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "MelonLoader" }

if (Test-Path $mlZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $mlZip -DestinationFolder $mlExtract -Label "MelonLoader" `
            -SkipMessage "Skipped - MelonLoader was NOT extracted; DawnVR will NOT load."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            if (Test-Path $mlFolder) {
                Remove-Item $mlFolder -Recurse -Force
                Write-OK "Removed old MelonLoader folder."
            }

            $mlFolderSrc = Join-Path $mlExtract "MelonLoader"
            if (Test-Path $mlFolderSrc) {
                Copy-Item -Path $mlFolderSrc -Destination $gamePath -Recurse -Force
                Write-OK "MelonLoader folder installed."
            }

            foreach ($dll in @("version.dll", "dobby.dll")) {
                $src = Join-Path $mlExtract $dll
                if (Test-Path $src) {
                    Copy-Item -Path $src -Destination $gamePath -Force
                    Write-OK "$dll installed."
                }
            }
            Write-OK "MelonLoader 0.5.7 installed successfully!"
        } catch {
            Write-Host "FAILED to install MelonLoader: $_" -ForegroundColor Red
            $failed += "MelonLoader"
        }
    } else {
        $failed += "MelonLoader"
    }
}

# -------------------------------------------------------
# STEP 4: Install DawnVR
# -------------------------------------------------------
Write-Step 4 4 "Installing DawnVR v1.0.1 ($EDITION_LABEL)"

$vrZip     = Join-Path $tempDir "DawnVR.zip"
$vrExtract = Join-Path $tempDir "DawnVR"
$r = Invoke-DownloadOrFallback -Url $DAWNVR_URL -Destination $vrZip `
        -Label "DawnVR v1.0.1 ($EDITION_LABEL)" `
        -ManualUrl "https://github.com/TrevTV/DawnVR/releases/tag/1.0.1" `
        -Instructions "Download the correct DawnVR_1.0.1 zip ($EDITION_LABEL variant) from the GitHub releases page. Place it at '$vrZip' and choose Retry." `
        -SkipMessage "Skipped - DawnVR mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { $failed += "DawnVR" }

if (Test-Path $vrZip) {
    $efb = Expand-ArchiveOrFallback -ArchivePath $vrZip -DestinationFolder $vrExtract -Label "DawnVR" `
            -SkipMessage "Skipped - DawnVR was NOT extracted; install is incomplete."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -eq "ok" -or [string]$efb -eq "manual") {
        try {
            Get-ChildItem -Path $vrExtract | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
            }
            Write-OK "DawnVR v1.0.1 ($EDITION_LABEL) installed!"
        } catch {
            Write-Host "FAILED to install DawnVR: $_" -ForegroundColor Red
            $failed += "DawnVR"
        }
    } else {
        $failed += "DawnVR"
    }
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ("DawnVR" -notin $failed) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {} }

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation Summary" -ForegroundColor White
Write-Host ""
if ("MelonLoader" -notin $failed) { Write-Host "    [x] MelonLoader 0.5.7" -ForegroundColor Green    } else { Write-Host "    [ ] MelonLoader 0.5.7  -- FAILED, install manually" -ForegroundColor Red }
if ("DawnVR"      -notin $failed) { Write-Host "    [x] DawnVR v1.0.1 ($EDITION_LABEL)" -ForegroundColor Green } else { Write-Host "    [ ] DawnVR v1.0.1      -- FAILED, install manually" -ForegroundColor Red }
Write-Host "============================================================" -ForegroundColor Magenta

Write-Host ""
try { Set-Clipboard -Value "-vrmode OpenVR" } catch {}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   ACTION REQUIRED - Steam Launch Options" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [OK] Launch parameter copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host "  (-vrmode OpenVR  |  case-sensitive)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Press Enter to open Steam Launch Options..." -ForegroundColor Yellow
Write-Host "  Then paste (Ctrl+V) and close Properties." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to open Steam Launch Options..."
Start-Process "steam://gameproperties/$GAME_APPID"
try { Set-Clipboard -Value "-vrmode OpenVR" } catch {}

Pause-User "Press Enter once you have pasted the launch option and closed Properties..."

Write-Host ""
Write-Host "--- Important Notes ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  - First launch will take longer than usual." -ForegroundColor White
Write-Host "    MelonLoader configures itself on the first run." -ForegroundColor Gray
Write-Host ""
Write-Host "  - Make sure SteamVR is running BEFORE launching the game." -ForegroundColor White
Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."
Write-Host ""
Write-Host "  - If you see an 'Initialization Error' on startup:" -ForegroundColor White
Write-Host "    Go into the game data folder and delete 'globalgamemanagers.bak'," -ForegroundColor Gray
Write-Host "    then restart the game." -ForegroundColor Gray
Write-Host ""
Write-Host "  - To temporarily disable VR: replace OpenVR with None" -ForegroundColor White
Write-Host "    in the Steam launch parameter." -ForegroundColor Gray
Write-Host ""
Write-Host "  The storm's still coming. Until then, every choice is yours, Chloe." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the game installation folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
