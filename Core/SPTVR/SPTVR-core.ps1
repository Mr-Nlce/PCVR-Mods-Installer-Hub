# -------------------------------------------------------
# Escape from Tarkov VR (SPT-VR) Mod Installer
# by cybensis (matsix) - distributed via GitHub
#
# SPT-VR layers onto a SinglePlayer Tarkov (SPT) install - a
# SEPARATE offline copy of Tarkov made by the SPT Installer.
# It is NEVER installed into your live / online EFT folder
# (doing so can get your account banned).
#
# This installer:
#   1. Asks whether an SPT install already exists
#      - YES: user drag-drops SPT.Launcher.exe onto the console
#        and we read the SPT root from its folder
#      - NO:  we download the official SPT Installer, place it in
#        C:\SPT VR\SPT and launch it, then continue once the user
#        confirms the SPT setup finished
#   2. Downloads the latest SPT-VR release ZIP from GitHub
#   3. Merges BepInEx + EscapeFromTarkov_Data into the SPT root
#   4. Writes a "Start SPT VR.bat" launcher (server -> wait -> launcher)
#   5. Creates a "SPT VR" desktop shortcut to that launcher
#
# Motion controllers required. SteamVR required.
# -------------------------------------------------------

# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Expand-ArchiveOrFallback). These
# replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$MOD_NAME    = "SPT-VR"
$MOD_VERSION = "v1.2.6"
$MOD_AUTHOR  = "cybensis"

$GAME_APPID  = "3932890"
$GAME_NAME   = "Escape from Tarkov"

# GitHub - public, no login required.
$GITHUB_REPO_URL    = "https://github.com/cybensis/SPT-VR"
$GITHUB_API_LATEST  = "https://api.github.com/repos/cybensis/SPT-VR/releases/latest"
$GITHUB_RELEASES    = "https://github.com/cybensis/SPT-VR/releases/latest"

# Official SPT Installer (waffle-lord). Primary direct host plus
# fallbacks so a single dead mirror never blocks setup.
$SPT_INSTALLER_URLS = @(
    "https://ligma.waffle-lord.net/SPTInstaller.exe",
    "https://github.com/waffle-lord/spt-installer/releases/latest/download/SPTInstaller.exe"
)
$SPT_INSTALLER_PAGE = "https://hub.sp-tarkov.com/files/file/1963-spt-installer/"

$MOD_DLL_REL = "BepInEx\plugins\sptvr\SPT-VR.dll"

# Microsoft runtimes the SPT *server* needs (it crashes on launch without
# them). The SPT Installer's own check can miss these. Direct links verified
# from the official Microsoft download pages.
$SERVER_RUNTIMES = @(
    @{ Name = ".NET Desktop Runtime 9.0.17 (x64)"; File = "windowsdesktop-runtime-9.0.17-win-x64.exe";
       Url = "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/9.0.17/windowsdesktop-runtime-9.0.17-win-x64.exe";
       Page = "https://dotnet.microsoft.com/en-us/download/dotnet/9.0"; Args = "/install /passive /norestart" }
    @{ Name = "ASP.NET Core Runtime 9.0.17 (x64)"; File = "aspnetcore-runtime-9.0.17-win-x64.exe";
       Url = "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/9.0.17/aspnetcore-runtime-9.0.17-win-x64.exe";
       Page = "https://dotnet.microsoft.com/en-us/download/dotnet/9.0"; Args = "/install /passive /norestart" }
    @{ Name = ".NET Framework 4.8.1"; File = "NDP481-x86-x64-AllOS-ENU.exe";
       Url = "https://go.microsoft.com/fwlink/?linkid=2203305";
       Page = "https://dotnet.microsoft.com/en-us/download/dotnet-framework/net481"; Args = "/passive /norestart" }
)

# -------------------------------------------------------
# Inline helpers (each installer defines its own)
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host " Escape from Tarkov VR Installer" -ForegroundColor Cyan
    Write-Host " $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}
function Write-Step {
    param([int]$Step, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}
function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [i] $m"  -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host "  [!] $m"  -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [X] $m"  -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# Clean a path that a user dragged onto the console (strips quotes,
# whitespace) and resolves a dropped .lnk shortcut to its target.
function Resolve-DroppedPath {
    param([string]$Raw)
    if (-not $Raw) { return $null }
    $p = $Raw.Trim().Trim('"').Trim()
    if (-not $p) { return $null }
    if ($p -match '\.lnk$' -and (Test-Path $p)) {
        try {
            $sh = New-Object -ComObject WScript.Shell
            $tgt = $sh.CreateShortcut($p).TargetPath
            if ($tgt) { $p = $tgt }
        } catch {}
    }
    return $p
}

# Given any dropped path (exe or folder), return the SPT root folder
# that actually contains SPT.Launcher.exe - checking the folder
# itself and a one-level "SPT" subfolder. Returns $null if none.
function Find-SptRoot {
    param([string]$AnyPath)
    # Return the SPT *game* root: the folder that holds the game files the
    # VR mod overlays (EscapeFromTarkov_Data + BepInEx). The launcher/server
    # (SPT.Launcher.exe / SPT.Server.exe) may live in the root OR in an "SPT"
    # subfolder - they are NOT the marker, because the mod's BepInEx must land
    # next to the EXISTING BepInEx, not next to the launcher.
    if (-not $AnyPath) { return $null }
    # Resolve a dropped file to its folder.
    $base = $AnyPath
    if (Test-Path $AnyPath) {
        $item = Get-Item $AnyPath -ErrorAction SilentlyContinue
        if ($item -and -not $item.PSIsContainer) { $base = Split-Path -Parent $item.FullName }
    }
    # Candidates in priority order: the folder itself, an "SPT" subfolder,
    # then one level up (covers launcher-in-subfolder / game-in-parent layouts).
    $cands = New-Object System.Collections.Generic.List[string]
    [void]$cands.Add($base)
    [void]$cands.Add((Join-Path $base "SPT"))
    $parent = Split-Path -Parent $base
    if ($parent) { [void]$cands.Add($parent) }
    # Game-root markers, strongest first. EscapeFromTarkov_Data is the data
    # folder the mod overlays and is the most reliable signal.
    foreach ($marker in @("EscapeFromTarkov_Data", "EscapeFromTarkov.exe")) {
        foreach ($c in $cands) {
            if ($c -and (Test-Path (Join-Path $c $marker))) { return $c }
        }
    }
    # Last resort: an existing BepInEx folder (but only if a game marker
    # wasn't found above, to avoid matching a stray/half-merged BepInEx).
    foreach ($c in $cands) {
        if ($c -and (Test-Path -LiteralPath "$c\BepInEx") -and (Test-Path -LiteralPath "$c\EscapeFromTarkov_Data")) { return $c }
    }
    return $null
}

# Option 2: (re)install the Microsoft runtimes the SPT server needs. Safe to
# run anytime - already-installed runtimes are skipped/repaired. Used when an
# existing SPT server crashes or won't start.
function Install-ServerRuntimes {
    Write-Host ""
    Write-Host " FIX SERVER ISSUES" -ForegroundColor Cyan
    Write-Host " -----------------" -ForegroundColor Cyan
    Write-Host "  Installs the Microsoft runtimes the SPT server needs:" -ForegroundColor White
    Write-Host "    - .NET 9 Desktop Runtime (x64)" -ForegroundColor Gray
    Write-Host "    - ASP.NET Core 9 Runtime (x64)" -ForegroundColor Gray
    Write-Host "    - .NET Framework 4.8.1" -ForegroundColor Gray
    Write-Host "  Already-installed ones are simply skipped - safe to run." -ForegroundColor Gray
    Write-Host "  Each shows a Windows UAC prompt - confirm it to proceed." -ForegroundColor White
    Pause-User "Press Enter to start the runtime installs..."

    $i = 0
    foreach ($rt in $SERVER_RUNTIMES) {
        $i++
        Write-Step $i $SERVER_RUNTIMES.Count "Installing $($rt.Name)"
        $dest = Join-Path $env:TEMP $rt.File
        $dl = Invoke-SafeDownload -Urls @($rt.Url) -Destination $dest `
            -Label $rt.Name `
            -ManualUrl $rt.Page `
            -Instructions "Download $($rt.File) from the Microsoft page and place it into '$env:TEMP', then choose Retry." `
            -SkipMessage "Skipped - $($rt.Name) was not installed."
        if ("$dl" -eq "quit") { Write-Warn "Aborted by user."; return }
        if (-not (Test-Path $dest)) { Write-Warn "$($rt.Name) not downloaded - skipping."; continue }

        Write-Host "  Running the installer (confirm the UAC prompt)..." -ForegroundColor White
        try {
            $p = Start-Process -FilePath $dest -ArgumentList $rt.Args -Verb RunAs -Wait -PassThru
            if ($p.ExitCode -eq 0)        { Write-OK "$($rt.Name) installed." }
            elseif ($p.ExitCode -eq 3010) { Write-OK "$($rt.Name) installed (reboot recommended later)." }
            elseif ($p.ExitCode -eq 1638) { Write-OK "$($rt.Name) already up to date." }
            else                          { Write-Warn "$($rt.Name) returned exit code $($p.ExitCode). If the server still fails, run $($rt.File) manually." }
        } catch {
            Write-Warn "Could not run $($rt.File) automatically (UAC declined?). Run it manually from: $dest"
        }
        try { Remove-Item $dest -Force -ErrorAction SilentlyContinue } catch {}
    }

    Write-Host ""
    Write-Host " Done. Start the SPT server (or the 'SPT VR' shortcut) - it" -ForegroundColor Green
    Write-Host " should stay running now." -ForegroundColor Green
}

# -------------------------------------------------------
# Intro + warnings
# -------------------------------------------------------
Write-Header
Write-Host " SPT-VR turns SinglePlayer Tarkov into a full motion-" -ForegroundColor White
Write-Host " controlled VR experience - via SteamVR." -ForegroundColor White
Write-Host ""
Write-Host " BEFORE YOU START:" -ForegroundColor Yellow
Write-Host " -----------------" -ForegroundColor Yellow
Write-Host "  - A working, up-to-date copy of Escape from Tarkov must" -ForegroundColor White
Write-Host "    be installed (Steam or BSG Launcher). The SPT Installer" -ForegroundColor White
Write-Host "    copies and down-patches those files - it does not touch" -ForegroundColor White
Write-Host "    or replace your live install." -ForegroundColor White
Write-Host "  - This is a very heavy mod - a high-end PC is expected" -ForegroundColor White
Write-Host "    (modern CPU, 16GB+ VRAM, 32GB+ RAM recommended)." -ForegroundColor White
Write-Host ""
Write-Host " The SPT server must run for the launcher to work, and it" -ForegroundColor Gray
Write-Host " needs three Microsoft runtimes (.NET 9 Desktop, ASP.NET Core" -ForegroundColor Gray
Write-Host " 9, .NET Framework 4.8.1). The SPT setup usually handles these," -ForegroundColor Gray
Write-Host " but its check can miss them - if your server later crashes or" -ForegroundColor Gray
Write-Host " won't start, run this again and pick option 2." -ForegroundColor Gray
Write-Host ""
Write-Host " What would you like to do?" -ForegroundColor White
Write-Host "   1) Start setup        - find/set up SPT and install the VR mod" -ForegroundColor Gray
Write-Host "   2) Fix server issues  - (re)install the Microsoft runtimes the" -ForegroundColor Gray
Write-Host "                           SPT server needs (for existing setups)" -ForegroundColor Gray
Write-Host ""
$choice = ""
while ($choice -notin @("1", "2")) {
    $choice = (Read-Host "  Choice (1/2, or Q to quit)").Trim()
    if ($choice -match '^[Qq]') { Write-Info "Cancelled by user."; Pause-User "Press Enter to exit."; exit 0 }
}
if ($choice -eq "2") {
    Install-ServerRuntimes
    Pause-User "Press Enter to exit."
    exit 0
}

# -------------------------------------------------------
# STEP 1: Locate (or set up) the SPT install
# -------------------------------------------------------
Write-Step 1 3 "Locating your SPT install"

$sptRoot = $null
$sptCreatedByUs = $false

Write-Host "  Do you already have a separate SPT install set up?" -ForegroundColor White
$haveSpt = (Read-Host "  (Y = yes, locate it / N = no, help me set it up)").Trim()

if ($haveSpt -match '^[Yy]') {
    # ---- Already set up: drag-and-drop SPT.Launcher.exe ----
    Write-Host ""
    Write-Host "  Drag SPT.Launcher.exe from your SPT folder onto this" -ForegroundColor White
    Write-Host "  window and press Enter (or paste the full path)." -ForegroundColor White
    Write-Host "  You can also drop the SPT folder itself." -ForegroundColor Gray
    Write-Host ""
    while (-not $sptRoot) {
        $dropped = Resolve-DroppedPath (Read-Host "  SPT.Launcher.exe or SPT folder")
        if (-not $dropped) { continue }
        $sptRoot = Find-SptRoot $dropped
        if ($sptRoot) {
            Write-OK "SPT install found: $sptRoot"
        } else {
            Write-Fail "No SPT install found at or near: $dropped"
            Write-Info "Point at your SPT folder (the one with EscapeFromTarkov_Data + BepInEx) or its SPT.Launcher.exe."
            $again = (Read-Host "  Try again? (Y/N)").Trim()
            if ($again -notmatch '^[Yy]') { break }
        }
    }
}

if (-not $sptRoot) {
    # ---- Not set up: help install SPT via the official SPT Installer ----
    $sptCreatedByUs = $true
    Write-Host ""
    Write-Info "We'll download the official SPT Installer and run it."
    Write-Host ""

    # Pick a writable base root: C:\Games\SPT VR then D: then E:
    $baseRoot = $null
    foreach ($drive in @("C:", "D:", "E:")) {
        $cand = Join-Path "$drive\Games" "SPT VR"
        try {
            if (-not (Test-Path $cand)) { New-Item -ItemType Directory -Path $cand -Force | Out-Null }
            $probe = Join-Path $cand ".pcvr_write_test"
            Set-Content -Path $probe -Value "x" -Encoding ASCII -Force
            Remove-Item $probe -Force
            $baseRoot = $cand
            break
        } catch { continue }
    }
    if (-not $baseRoot) {
        Write-Fail "Could not create a writable 'SPT VR' folder under C:\Games, D:\Games or E:\Games."
        Write-Info "Create C:\Games\SPT VR yourself (writable), then re-run this installer."
        Pause-User "Press Enter to exit."
        exit 1
    }
    # Install SPT directly into the base folder (no extra "SPT" subfolder).
    $sptTarget = $baseRoot
    Write-OK "SPT will be installed to: $sptTarget"

    # Download the SPT Installer into the SPT target folder.
    $sptInstallerExe = Join-Path $sptTarget "SPTInstaller.exe"
    Write-Host ""
    $dlRes = Invoke-SafeDownload -Urls $SPT_INSTALLER_URLS -Destination $sptInstallerExe `
        -Label "SPT Installer" `
        -ManualUrl $SPT_INSTALLER_PAGE `
        -Instructions "Download SPTInstaller.exe from the SPT hub and place it into '$sptTarget', then choose Retry." `
        -SkipMessage "Skipped - SPT Installer not downloaded; you'll need to set up SPT manually."

    if ($dlRes -eq $true -and (Test-Path $sptInstallerExe)) {
        Write-Host ""
        Write-Host "  Launching the SPT Installer..." -ForegroundColor Gray
        Write-Host "  Windows will first show a UAC prompt - confirm it to" -ForegroundColor White
        Write-Host "  let the SPT Installer open." -ForegroundColor White
        Write-Host "  Then, in the SPT Installer window:" -ForegroundColor White
        Write-Host "    - keep the install folder as: $sptTarget" -ForegroundColor Gray
        Write-Host "    - click 'Start Install' and wait for it to finish" -ForegroundColor Gray
        Write-Host ""
        try { Start-Process -FilePath $sptInstallerExe -WorkingDirectory $sptTarget } catch {
            Write-Warn "Could not auto-launch the SPT Installer. Run it manually from:"
            Write-Host "    $sptInstallerExe" -ForegroundColor DarkGray
        }
    } else {
        Write-Warn "SPT Installer was not downloaded automatically."
        Write-Host "  Get it from: $SPT_INSTALLER_PAGE" -ForegroundColor DarkGray
        Write-Host "  Save + run it, installing SPT into: $sptTarget" -ForegroundColor White
    }

    Pause-User "Finish the SPT setup, then press Enter to continue."

    # Detect the SPT root now that setup is (hopefully) done.
    $sptRoot = Find-SptRoot $baseRoot
    if (-not $sptRoot) { $sptRoot = Find-SptRoot $sptTarget }

    # Still not found - let the user point us at it manually.
    while (-not $sptRoot) {
        Write-Warn "Could not locate the SPT install under $baseRoot."
        Write-Host "  Drag SPT.Launcher.exe (or the SPT folder) onto this window" -ForegroundColor Yellow
        Write-Host "  and press Enter, or type 'skip' to abort." -ForegroundColor Gray
        $dropped = (Read-Host "  SPT.Launcher.exe / SPT folder").Trim()
        if ($dropped -match '^(skip|quit|exit)$') { break }
        $sptRoot = Find-SptRoot (Resolve-DroppedPath $dropped)
        if ($sptRoot) { Write-OK "SPT install found: $sptRoot" }
    }
    if (-not $sptRoot) {
        Write-Fail "No SPT install located - cannot continue."
        Write-Info "Run this installer again once SPT is set up."
        Pause-User "Press Enter to exit."
        exit 1
    }
}

# -------------------------------------------------------
# STEP 2: Download + install the SPT-VR mod
# -------------------------------------------------------
# --- Update-or-install choice (shared helper) ---
$InstallMode = Read-UpdateOrInstall -GameFolder $sptRoot -ModFile "BepInEx\plugins\sptvr\SPT-VR.dll"
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the mod files." }

Write-Step 2 3 "Downloading + installing SPT-VR"

# Resolve the latest release asset via the GitHub API (same approach
# the Hub auto-updater uses). Falls back to the releases page for a
# manual grab if the API is unreachable / rate-limited.
$modUrl = $null
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $rel = Invoke-RestMethod -Uri $GITHUB_API_LATEST -Headers @{ "User-Agent" = "VRModHub" } -ErrorAction Stop
    if ($rel -is [array]) { $rel = $rel | Where-Object { $_.assets.Count -gt 0 } | Select-Object -First 1 }
    $asset = $rel.assets | Where-Object { $_.name -match "\.zip$" } | Select-Object -First 1
    if ($asset) {
        $modUrl = $asset.browser_download_url
        Write-Info "Latest release: $($rel.tag_name)"
    }
} catch {
    Write-Warn "Could not query GitHub for the latest release (rate limit / offline)."
}

$modZip = Join-Path $env:TEMP ("SPTVR_" + [System.IO.Path]::GetRandomFileName() + ".zip")
$urlList = @()
if ($modUrl) { $urlList += $modUrl }

if ($urlList.Count -gt 0) {
    $mdl = Invoke-SafeDownload -Urls $urlList -Destination $modZip `
        -Label "SPT-VR $MOD_VERSION" `
        -ManualUrl $GITHUB_RELEASES `
        -Instructions "Download the SPT-VR release ZIP from the releases page and place it into '$([System.IO.Path]::GetDirectoryName($modZip))', then choose Retry." `
        -SkipMessage "Skipped - SPT-VR ZIP not downloaded; nothing was installed."
} else {
    # No asset URL resolved - go straight to manual fallback.
    $mdl = Invoke-InstallerFallback -Action "SPT-VR download" -Subject "SPT-VR $MOD_VERSION" `
        -Url $GITHUB_RELEASES `
        -Instructions "Download the latest SPT-VR ZIP from the releases page, then place it into '$([System.IO.Path]::GetDirectoryName($modZip))' (named exactly as below) and choose Retry." `
        -SkipMessage "Skipped - SPT-VR ZIP not downloaded; nothing was installed." `
        -DestFolder ([System.IO.Path]::GetDirectoryName($modZip))
}
if ($mdl -ne $true -and "$mdl" -ne "ok" -and "$mdl" -ne "retry" -and "$mdl" -ne "manual") {
    if ("$mdl" -eq "quit") { Pause-User "Press Enter to exit."; exit 1 }
    # skip: continue but warn (the user may copy files in manually)
}

if (-not (Test-Path $modZip) -or ((Get-Item $modZip -ErrorAction SilentlyContinue).Length -le 0)) {
    Write-Warn "SPT-VR ZIP is missing - cannot extract."
    Write-Info "Re-run the installer once the ZIP downloads, or extract it manually into:"
    Write-Host "    $sptRoot" -ForegroundColor DarkGray
    Pause-User "Press Enter to exit."
    exit 1
}

# Extract to a temp folder, then merge into the SPT root.
$tempExtract = Join-Path $env:TEMP ("SPTVR_" + [System.IO.Path]::GetRandomFileName())
try { New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null } catch {}

$exRes = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $tempExtract `
    -Label "SPT-VR" `
    -SkipMessage "Skipped - SPT-VR was not extracted; install is incomplete."
if ("$exRes" -eq "quit") { Pause-User "Press Enter to exit."; exit 1 }

# The release ZIP contains BepInEx\ and EscapeFromTarkov_Data\ at the
# top level. If a single wrapper folder is present instead, descend
# into it (unless that folder is BepInEx itself).
$srcRoot = $tempExtract
$rootEntries = @(Get-ChildItem -Path $tempExtract -ErrorAction SilentlyContinue)
if ($rootEntries.Count -eq 1 -and $rootEntries[0].PSIsContainer -and $rootEntries[0].Name -ne "BepInEx") {
    if (-not (Test-Path -LiteralPath "$tempExtract\BepInEx")) { $srcRoot = $rootEntries[0].FullName }
}

Write-Host "  Merging mod files into: $sptRoot" -ForegroundColor Gray
$copyOk = $true
try {
    Get-ChildItem -Path $srcRoot | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $sptRoot -Recurse -Force
    }
} catch {
    $copyOk = $false
    Write-Fail "Copy failed: $_"
    $fb = Invoke-InstallerFallback -Action "SPT-VR file copy" -Subject "SPT-VR files" `
        -Instructions "Open the extracted folder (path printed above) and merge BepInEx and EscapeFromTarkov_Data into '$sptRoot', then choose Retry." `
        -SourceFolder $srcRoot -DestFolder $sptRoot `
        -SkipMessage "Skipped - mod files were NOT merged; install is incomplete."
    if ("$fb" -eq "quit") { Pause-User "Press Enter to exit."; exit 1 }
}

# Clean up temp artefacts.
try { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue } catch {}
try { Remove-Item $modZip -Force -ErrorAction SilentlyContinue } catch {}

# Sanity check: the marker DLL must be present.
$modDll = Join-Path $sptRoot $MOD_DLL_REL
if (Test-Path $modDll) {
    Write-OK "SPT-VR.dll installed."
} else {
    Write-Warn "SPT-VR.dll not found at: $modDll"
    Write-Info "If you skipped the download, merge the ZIP's BepInEx + EscapeFromTarkov_Data into $sptRoot."
}

# -------------------------------------------------------
# STEP 3: Launcher script + desktop shortcut + records
# -------------------------------------------------------
Write-Step 3 3 "Creating launcher + desktop shortcut"

# Write the combined launcher: starts the SPT server (unless it's
# already running), waits for port 6969, then opens the SPT launcher.
# Placed in the SPT root so it sits next to SPT.Server/Launcher.exe.
$launcherBat = Join-Path $sptRoot "Start SPT VR.bat"
$launcherContent = @'
@echo off
setlocal EnableExtensions
title SPT VR

rem --- Resolve the SPT folder: exes next to this script, or in an "SPT" subfolder ---
set "HERE=%~dp0"
set "SPT_DIR=%HERE:~0,-1%"
if not exist "%SPT_DIR%\SPT.Server.exe" (
    if exist "%HERE%SPT\SPT.Server.exe" set "SPT_DIR=%HERE%SPT"
)
rem --- Run from the SPT folder so the launcher finds its files ---
cd /d "%SPT_DIR%"
set "SERVER_EXE=%SPT_DIR%\SPT.Server.exe"
set "LAUNCHER_EXE=%SPT_DIR%\SPT.Launcher.exe"

if not exist "%SERVER_EXE%" (
    echo SPT.Server.exe not found:
    echo "%SERVER_EXE%"
    echo.
    echo Launch SPT.Launcher.exe manually, or fix this script's SPT path.
    pause
    exit /b 1
)
if not exist "%LAUNCHER_EXE%" (
    echo SPT.Launcher.exe not found:
    echo "%LAUNCHER_EXE%"
    pause
    exit /b 1
)

rem --- If the SPT server is already running, skip starting it ---
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"try { $c=New-Object Net.Sockets.TcpClient; $a=$c.BeginConnect('127.0.0.1',6969,$null,$null); if($a.AsyncWaitHandle.WaitOne(800)){ $c.EndConnect($a); $c.Close(); exit 0 }; $c.Close(); exit 1 } catch { exit 1 }"
if not errorlevel 1 (
    echo SPT server already running - skipping server start.
    goto launch
)

echo Starting SPT server...
start "SPT Server" /D "%SPT_DIR%" "%SERVER_EXE%"
echo Waiting for SPT server on 127.0.0.1:6969 (up to 120s)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$deadline=(Get-Date).AddSeconds(120); while((Get-Date) -lt $deadline){ try { $client=New-Object Net.Sockets.TcpClient; $async=$client.BeginConnect('127.0.0.1',6969,$null,$null); if($async.AsyncWaitHandle.WaitOne(1000)){ $client.EndConnect($async); $client.Close(); exit 0 }; $client.Close() } catch {}; Start-Sleep -Seconds 1 }; exit 1"
if errorlevel 1 (
    echo SPT server did not become available within 120 seconds.
    echo Start SPT.Server.exe manually, wait for "Server has started", then run SPT.Launcher.exe.
    pause
    exit /b 1
)
timeout /t 2 /nobreak >nul

:launch
echo Starting SPT launcher...
start "SPT Launcher" /D "%SPT_DIR%" "%LAUNCHER_EXE%"
endlocal
exit /b 0
'@
try {
    Set-Content -Path $launcherBat -Value $launcherContent -Encoding ASCII -Force
    Write-OK "Launcher script written: $launcherBat"
} catch {
    Write-Warn "Could not write the launcher script: $_"
}

# Desktop shortcut "SPT VR" -> the launcher script.
try {
    $desktop  = [Environment]::GetFolderPath("Desktop")
    $lnkPath  = Join-Path $desktop "SPT VR.lnk"
    # The shortcut targets a .bat, which has no icon of its own - pull
    # the icon from SPT.Launcher.exe. Probe the SPT root and a one-level
    # "SPT" subfolder (mirrors the launcher script's folder logic).
    $iconExe = $null
    foreach ($cand in @((Join-Path $sptRoot "SPT.Launcher.exe"), (Join-Path $sptRoot "SPT\SPT.Launcher.exe"))) {
        if (Test-Path $cand) { $iconExe = $cand; break }
    }
    $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $launcherBat -WorkingDir $sptRoot -IconPath $(if ($iconExe) { "$iconExe,0" } else { "" }) -Description "Start Single Player Tarkov VR (server + launcher)"
    if (Test-Path $lnkPath) { Write-OK "Desktop shortcut created: SPT VR" }
} catch {
    Write-Warn "Could not create the desktop shortcut: $_"
}

# Record the install path so the Hub marks VR Ready + launches correctly.
try {
    Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $sptRoot -Encoding UTF8 -Force
} catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " HOW TO PLAY:" -ForegroundColor Yellow
Write-Host "  1. Start SteamVR and put your headset on." -ForegroundColor White
Write-Host "  2. Use the 'SPT VR' desktop shortcut (or 'Start in VR' in" -ForegroundColor White
Write-Host "     the Hub). It starts the SPT server, waits for it, then" -ForegroundColor White
Write-Host "     opens the SPT launcher." -ForegroundColor White
Write-Host "  3. In the SPT launcher, log in / register a profile and" -ForegroundColor White
Write-Host "     press Play." -ForegroundColor White
Write-Host ""
Write-Host " NOTES:" -ForegroundColor Gray
Write-Host "  - The SPT server must run while you play. The shortcut" -ForegroundColor Gray
Write-Host "    handles that for self-hosting. If you connect to a" -ForegroundColor Gray
Write-Host "    remote / headless Fika server, start SPT.Launcher.exe" -ForegroundColor Gray
Write-Host "    directly instead." -ForegroundColor Gray
Write-Host "  - In the Tarkov settings menu you'll find a VR tab for" -ForegroundColor Gray
Write-Host "    motion-sickness and comfort options." -ForegroundColor Gray
Write-Host "  - Controls: see this game's description page in the Hub." -ForegroundColor Gray
Write-Host ""
Write-Host " PERFORMANCE TROUBLE? (this is a heavy mod):" -ForegroundColor White
Write-Host "  - Graphics low/off except textures, shadows, aniso, LOD." -ForegroundColor Gray
Write-Host "  - AA off or FXAA only; on <=10GB VRAM enable Mip Streaming." -ForegroundColor Gray
Write-Host "  - Use an upscaler (DLSS / FSR3)." -ForegroundColor Gray
Write-Host "  - SteamVR: set Tarkov resolution to 100-150% (lower=faster)." -ForegroundColor Gray
Write-Host ""
Write-Host "  Pack light, aim true, and listen for footsteps in the dark." -ForegroundColor Magenta
Write-Host ""

# If we set SPT up from scratch, open its folder so the user can see
# exactly where it landed.
if ($sptCreatedByUs -and (Test-Path $sptRoot)) {
    Write-Host "  Opening your SPT folder: $sptRoot" -ForegroundColor Gray
    try { Start-Process explorer.exe $sptRoot } catch {}
}

Pause-User "Press Enter to exit."
