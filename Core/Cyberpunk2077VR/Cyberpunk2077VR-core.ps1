# ============================================================
# Cyberpunk 2077 VR Installer
# ============================================================
# Installs CyberpunkVRPort (dariulone) - an OpenXR dxgi.dll VR proxy
# for Cyberpunk 2077 with 6-DoF motion-controlled VR hands (full-arm
# VRIK) and an in-headset F10 overlay. This is an IN-PLACE mod: it
# overlays files into the existing Steam/GOG Cyberpunk 2077 folder
# (bin\x64\... and red4ext\...). The full hands/HUD experience also
# needs two frameworks - RED4ext and Cyber Engine Tweaks (CET) - which
# this installer adds if they are not already present. Nothing is ever
# bundled; every component is downloaded at install time.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Cyberpunk 2077 VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME     = "CyberpunkVRPort v0.0.7"
$MOD_AUTHOR   = "dariulone"
$INFO_URL     = "https://github.com/dariulone/cyberpunk-vr-port"
$MOD_URL      = "https://github.com/dariulone/cyberpunk-vr-port/releases/download/0.0.7/CyberpunkVRPort-0.0.7.zip"
# Tag of the pinned fallback build above - recorded as the installed
# version when the live GitHub lookup can't be reached. Must match the
# release tag_name the Hub sees via /releases/latest (no leading "v").
$MOD_PINNED_TAG = "0.0.7"
$MOD_RELEASES = "https://github.com/dariulone/cyberpunk-vr-port/releases"
# Frameworks needed for the motion-controlled hands + VR HUD. Pinned to
# versions known to work with this mod build; only installed if missing.
$RED4EXT_URL  = "https://github.com/wopss/RED4ext/releases/download/v1.30.0/red4ext-1.30.0.zip"
$RED4EXT_REL  = "https://github.com/wopss/RED4ext/releases"
$CET_URL      = "https://github.com/maximegmd/CyberEngineTweaks/releases/download/v1.37.1/cet_1.37.1.zip"
$CET_REL      = "https://github.com/maximegmd/CyberEngineTweaks/releases"
$STEAM_FOLDER = "Cyberpunk 2077"
$CP_APPID     = "1091500"
$GAME_EXE_REL = "bin\x64\Cyberpunk2077.exe"
$MOD_MARKER   = "bin\x64\dxgi.dll"
$RED4EXT_MARK = "red4ext\RED4ext.dll"
$CET_MARK     = "bin\x64\plugins\cyber_engine_tweaks.asi"
$GOG_ROOTS = @(
    "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games",
    "HKLM:\SOFTWARE\GOG.com\Games"
)

# ---- Inline console helpers (per-installer; NOT shared) -----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  Cyberpunk 2077 VR Installer" -ForegroundColor Yellow
    Write-Host "  Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
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
# A valid Cyberpunk 2077 root is the folder that contains bin\x64\Cyberpunk2077.exe.
function Test-CP2077Root {
    param([string]$Root)
    if (-not $Root) { return $false }
    return (Test-Path (Join-Path $Root $GAME_EXE_REL))
}
# Merge-copy every file under $Src into $Dst, preserving the relative
# folder layout (creating folders as needed, overwriting existing files).
function Copy-Tree {
    param([string]$Src, [string]$Dst)
    $base = (Resolve-Path $Src).Path.TrimEnd('\')
    Get-ChildItem -Path $base -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $rel = $_.FullName.Substring($base.Length).TrimStart('\')
        $target = Join-Path $Dst $rel
        $tdir = Split-Path $target -Parent
        if ($tdir -and -not (Test-Path $tdir)) { New-Item -ItemType Directory -Path $tdir -Force | Out-Null }
        Copy-Item -Path $_.FullName -Destination $target -Force
    }
}

# Resolve the latest CyberpunkVRPort release straight from GitHub so each
# install pulls the newest build (the mod updates often). Uses the same
# endpoint the Hub's update check uses (/releases/latest) so the recorded
# version and the Hub's "Update" detection always agree. Returns
# @{ Url; Tag } or $null on any failure (rate limit, offline, no asset) -
# the caller then falls back to the pinned known-good build.
function Resolve-LatestModUrl {
    try {
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub"; "Accept" = "application/vnd.github+json" }
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/dariulone/cyberpunk-vr-port/releases/latest" -Headers $headers -TimeoutSec 20 -ErrorAction Stop
        if (-not $rel) { return $null }
        $asset = $rel.assets | Where-Object { $_.name -match '(?i)^CyberpunkVRPort.*\.zip$' } | Select-Object -First 1
        if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -match '(?i)\.zip$' } | Select-Object -First 1 }
        if ($asset -and $asset.browser_download_url) {
            return @{ Url = $asset.browser_download_url; Tag = $rel.tag_name }
        }
    } catch {}
    return $null
}

# -------------------------------------------------------
# Resolve the live release version up front, so the header line and the
# final summary both show the exact build being installed (not the pinned
# fallback). The result is re-used in STEP 3 - only one GitHub call. The
# notice below is transient: Write-Header clears the screen right after.
# -------------------------------------------------------
Write-Host "  Checking latest CyberpunkVRPort version..." -ForegroundColor DarkGray
$latest = Resolve-LatestModUrl
$installedTag = $MOD_PINNED_TAG
if ($latest -and $latest.Tag) { $installedTag = $latest.Tag }
$MOD_NAME = "CyberpunkVRPort v$installedTag"

# -------------------------------------------------------
# STEP 1: Locate Cyberpunk 2077
# -------------------------------------------------------
Write-Header
Write-Step 1 4 "Locating Cyberpunk 2077"

$gameRoot = $null

$steamPath = Get-SteamPath
if ($steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $root = Join-Path $lib "steamapps\common\$STEAM_FOLDER"
        if (Test-CP2077Root $root) { $gameRoot = $root; Write-Info "Found via Steam: $gameRoot"; break }
    }
}

if (-not $gameRoot) { $gameRoot = Find-SteamGameFolder -AppId "1091500" -SteamFolderNames @("Cyberpunk 2077") -GogNames @("Cyberpunk 2077") -EpicNames @("Cyberpunk 2077") }
if (-not $gameRoot) {
    foreach ($reg in $GOG_ROOTS) {
        try {
            Get-ChildItem -Path $reg -ErrorAction Stop | ForEach-Object {
                if ($gameRoot) { return }
                try {
                    $gogPath = (Get-ItemProperty -Path $_.PSPath -ErrorAction Stop).path
                    if ($gogPath -and (Test-CP2077Root $gogPath)) { $gameRoot = $gogPath; Write-Info "Found via GOG: $gameRoot" }
                } catch {}
            }
        } catch {}
        if ($gameRoot) { break }
    }
    # Common GOG default if the registry scan missed it.
    if (-not $gameRoot) {
        $gogDefault = "C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077"
        if (Test-CP2077Root $gogDefault) { $gameRoot = $gogDefault; Write-Info "Found via GOG default path: $gameRoot" }
    }
}

if (-not $gameRoot) {
    Write-Warn "Cyberpunk 2077 was not found automatically."
    Write-Host "  You need Cyberpunk 2077 installed (Steam or GOG)." -ForegroundColor White
    Write-Host "  Steam store / install:  https://store.steampowered.com/app/$CP_APPID/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [O] Open the Steam install page   [P] Enter the game folder manually" -ForegroundColor White
    $pick = ""
    while ($pick -notin @("o","O","p","P")) { $pick = (Read-Host "  Choice (O/P)").Trim() }
    if ($pick -in @("o","O")) {
        try { Start-Process "steam://install/$CP_APPID" } catch { try { Start-Process "https://store.steampowered.com/app/$CP_APPID/" } catch {} }
        Pause-User "Install Cyberpunk 2077, then press Enter to continue..."
        if ($steamPath) {
            foreach ($lib in (Get-SteamLibraries $steamPath)) {
                $root = Join-Path $lib "steamapps\common\$STEAM_FOLDER"
                if (Test-CP2077Root $root) { $gameRoot = $root; Write-Info "Found: $gameRoot"; break }
            }
        }
    }
    while (-not $gameRoot) {
        Write-Host "  Enter the Cyberpunk 2077 folder (the one that holds bin\x64\Cyberpunk2077.exe):" -ForegroundColor White
        Write-Host "    Steam: C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077" -ForegroundColor Gray
        Write-Host "    GOG:   C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077" -ForegroundColor Gray
        $r = (Read-Host "  Path").Trim().Trim('"')
        if (Test-CP2077Root $r) { $gameRoot = $r; Write-Info "Path set: $gameRoot" }
        else { Write-Fail "Cyberpunk2077.exe not found under bin\x64 at: $r" }
    }
}

$tempDir = Join-Path $env:TEMP "CP2077VRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Download a zip (with mirrors + manual fallback) and overlay it into the
# game folder. Returns $true on success.
function Install-Component {
    param([string]$Label, [string[]]$Urls, [string]$ManualUrl, [string]$ManualName)
    $tmpZip = Join-Path $tempDir ("dl_" + [System.IO.Path]::GetRandomFileName() + ".zip")
    $null = Invoke-SafeDownload -Urls $Urls -Destination $tmpZip -Label $Label `
                -ManualUrl $ManualUrl `
                -Instructions "Download $ManualName from the page that opened and drop it into the opened folder, then choose Retry." `
                -SkipMessage "Skipped - $Label was NOT installed."
    if (-not (Test-Path $tmpZip)) { return $false }
    $exDir = Join-Path $tempDir ("ex_" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $exDir -Force | Out-Null
    $res = Expand-ArchiveOrFallback -ArchivePath $tmpZip -DestinationFolder $exDir -Label $Label `
               -SkipMessage "Skipped - $Label was NOT extracted."
    if ([string]$res -eq "quit") { return $false }
    try { Copy-Tree -Src $exDir -Dst $gameRoot } catch { Write-Fail "Copy failed: $($_.Exception.Message)"; return $false }
    return $true
}

# -------------------------------------------------------
# STEP 2: Frameworks (RED4ext + CET) - only if missing
# -------------------------------------------------------
Write-Step 2 4 "Frameworks (RED4ext + Cyber Engine Tweaks)"
Write-Host "  These power the motion-controlled hands and the VR HUD." -ForegroundColor Gray
Write-Host "  Installed only if you don't already have them." -ForegroundColor Gray
Write-Host ""

$red4extState = "present"
if (Test-Path (Join-Path $gameRoot $RED4EXT_MARK)) {
    Write-OK "RED4ext already present - keeping your install."
} else {
    Write-Host "  Installing RED4ext (v1.30.0) ..." -ForegroundColor White
    if (Install-Component -Label "RED4ext" -Urls @($RED4EXT_URL) -ManualUrl $RED4EXT_REL -ManualName "red4ext-1.30.0.zip") {
        Write-OK "RED4ext installed."; $red4extState = "installed"
    } else { Write-Warn "RED4ext was not installed - VR hands/HUD may not load (camera/stereo will still work)."; $red4extState = "missing" }
}

$cetState = "present"
if (Test-Path (Join-Path $gameRoot $CET_MARK)) {
    Write-OK "Cyber Engine Tweaks already present - keeping your install."
} else {
    Write-Host "  Installing Cyber Engine Tweaks (v1.37.1) ..." -ForegroundColor White
    if (Install-Component -Label "Cyber Engine Tweaks" -Urls @($CET_URL) -ManualUrl $CET_REL -ManualName "cet_1.37.1.zip") {
        Write-OK "Cyber Engine Tweaks installed."; $cetState = "installed"
    } else { Write-Warn "CET was not installed - VR hands/HUD may not load (camera/stereo will still work)."; $cetState = "missing" }
}

# -------------------------------------------------------
# STEP 3: CyberpunkVRPort (the VR mod itself) - latest release
# -------------------------------------------------------
Pause-User "Press Enter to start the installation..."

Write-Step 3 4 "Installing CyberpunkVRPort (latest release)"

Write-Info "Checking GitHub for the latest CyberpunkVRPort release..."
# $latest / $installedTag were already resolved up front (for the header
# line); re-use them here so there is only one GitHub call per run.
$modUrls = @()
if ($latest -and $latest.Url) {
    Write-OK "Latest release: $installedTag"
    $modUrls += $latest.Url
} else {
    Write-Warn "Could not query GitHub (rate limit or offline) - using the known build $MOD_PINNED_TAG."
}
# Always keep the known-good pinned build as a fallback behind the latest.
if ($modUrls -notcontains $MOD_URL) { $modUrls += $MOD_URL }

$modOk = Install-Component -Label "CyberpunkVRPort $installedTag" -Urls $modUrls -ManualUrl $MOD_RELEASES -ManualName "the latest CyberpunkVRPort .zip"
if ($modOk) {
    Write-OK "CyberpunkVRPort $installedTag installed into the game folder."
    # Record the installed release tag so the Hub can flip the card to
    # "Update" when GitHub publishes a newer release (same scheme as the
    # other GitHub-tracked mods). File lives next to this installer.
    try {
        [System.IO.File]::WriteAllText((Join-Path $PSScriptRoot ".installed_version"), $installedTag, (New-Object System.Text.UTF8Encoding $false))
    } catch {}
} else {
    if (Test-Path (Join-Path $gameRoot $MOD_MARKER)) {
        Write-Warn "Could not (re)install the VR mod, but a previous install is still present."
    } else {
        Write-Fail "The VR mod was not installed. Aborting."
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..."; exit 1
    }
}

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 4: Summary + first-launch notes
# -------------------------------------------------------
Write-Step 4 4 "All Done!"

$modPresent = Test-Path (Join-Path $gameRoot $MOD_MARKER)

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ($modPresent) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {} }

Write-Host "  Game folder: $gameRoot" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
if ($modPresent) { Write-Host "  [x] $MOD_NAME (dxgi.dll VR proxy + VR hands)" -ForegroundColor Green }
else { Write-Host "  [ ] VR mod missing" -ForegroundColor Red }
switch ($red4extState) {
    "present"   { Write-Host "  [x] RED4ext (already installed)" -ForegroundColor Green }
    "installed" { Write-Host "  [x] RED4ext" -ForegroundColor Green }
    default     { Write-Host "  [ ] RED4ext - hands/HUD will not load until added" -ForegroundColor Yellow }
}
switch ($cetState) {
    "present"   { Write-Host "  [x] Cyber Engine Tweaks (already installed)" -ForegroundColor Green }
    "installed" { Write-Host "  [x] Cyber Engine Tweaks" -ForegroundColor Green }
    default     { Write-Host "  [ ] Cyber Engine Tweaks - hands/HUD will not load until added" -ForegroundColor Yellow }
}
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Start your OpenXR runtime FIRST (Virtual Desktop / VDXR," -ForegroundColor White
Write-Host "     SteamVR, etc.) - before launching the game." -ForegroundColor White
Write-Host "  2. Launch Cyberpunk 2077 normally (Steam / GOG, or the Hub)." -ForegroundColor White
Write-Host "  3. In-game:  F10 = VR settings overlay,  F7 = recenter." -ForegroundColor White
Write-Host ""
Write-Host "  - For the SteamVR (OpenVR) path instead of native OpenXR, set" -ForegroundColor Gray
Write-Host "    xr_runtime=1 in bin\x64\vrport.ini and restart the game." -ForegroundColor Gray
Write-Host "  - Open the F10 overlay -> VRIK tab to start hand tracking and" -ForegroundColor Gray
Write-Host "    calibrate reach / height / elbow per hand." -ForegroundColor Gray
Write-Host "  - Log for bug reports: bin\x64\cyberpunkvrport.log" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to continue to the recommended settings..."
Clear-Host
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  !! RECOMMENDED SETTINGS - DO THIS OR PERFORMANCE MAY TANK !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Cyberpunk 2077 is VERY demanding in VR. On first launch the" -ForegroundColor White
Write-Host "  CyberpunkVRPort VR configuration window appears:" -ForegroundColor White
Write-Host ""
Write-Host "   - VR Runtime: pick yours. OpenXR (Virtual Desktop) suits most." -ForegroundColor White
Write-Host "   - Resolution: do NOT go too high. 2560 x 2560 fits most setups." -ForegroundColor White
Write-Host ""
Write-Host "  In-game graphics settings:" -ForegroundColor White
Write-Host "   - Quick Preset: Low  (Medium at most)" -ForegroundColor White
Write-Host "   - Resolution Scaling: Off" -ForegroundColor White
Write-Host "   - Turn OFF: Ray Tracing, Frame Generation, Film Grain," -ForegroundColor White
Write-Host "               Chromatic Aberration, Depth of Field, Lens Flare" -ForegroundColor White
Write-Host "   - Press Apply when done." -ForegroundColor White
Write-Host "   - Video: lower Gamma Correction a touch (it is a bit too bright)." -ForegroundColor White
Write-Host ""
Write-Host "  In the F10 VR menu:" -ForegroundColor White
Write-Host "   - Use Mono for now - AER has very poor performance." -ForegroundColor White
Write-Host "   - VRIK tab: enable hand tracking, adjust hand position." -ForegroundColor White
Write-Host "   - Hand overlay is on by default so you can line them up; once" -ForegroundColor White
Write-Host "     it fits, turn it off under General -> Enable Hand Overlay." -ForegroundColor White
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter once you've read the recommended settings..."
Write-Host ""
Write-Host "  Wake up, samurai. Night City won't burn itself down." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
try { Start-Process explorer.exe "`"$gameRoot\bin\x64`"" } catch {}
