# ============================================================
# Bendy and the Ink Machine - BendyVR Mod Installer
# ============================================================
# Two install paths:
#   Option 1 (RECOMMENDED): Steam Console depot download of the
#     mod-compatible build into C:\Games\Bendy VR, then the mod.
#     The current Steam build no longer starts with the mod
#     (Team Beef, June 2025), so this pinned build is the safe
#     choice.
#   Option 2: install the mod onto your CURRENT Steam copy. Use
#     only if you specifically want the current game version -
#     note the live Steam build may not launch with the mod.
# No auto-update: the depot manifest is pinned in this installer.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "BendyVR Installer"
$ErrorActionPreference = "Stop"

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------
$GAME_NAME   = "Bendy and the Ink Machine"
$GAME_FOLDER = "Bendy and the Ink Machine"
$GAME_EXE    = "Bendy and the Ink Machine.exe"
$MOD_URL     = "https://github.com/Team-Beef-Studios/BendyVR/releases/download/v.1.2.2/BendyVRInstall_1_22.rar"
$INFO_URL    = "https://github.com/Team-Beef-Studios/BendyVR"

# Steam depot - mod-compatible build, pinned manifest (no auto-update)
$DEPOT_APPID    = "622650"
$DEPOT_DEPOTID  = "622651"
$DEPOT_MANIFEST = "3657537186137230940"
$DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"

# Stable target for the depot build, kept off the Steam library
$DEFAULT_PARENT = "C:\Games"
$TARGET_NAME    = "Bendy VR"
$DEFAULT_PATH   = Join-Path $DEFAULT_PARENT $TARGET_NAME

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Yellow; Write-Host " Bendy and the Ink Machine - BendyVR Installer" -ForegroundColor Yellow; Write-Host " BendyVR v1.2.2 by Team Beef Studios" -ForegroundColor Gray; Write-Host "============================================================" -ForegroundColor Yellow; Write-Host "" }
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($x) Write-Host " [OK] $x" -ForegroundColor Green }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
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

# Shared: download the BendyVR .rar, extract it to a PERMANENT folder
# ($ModKeepDir = <game>\BendyVRInstall, inside the game folder - the
# mod's BepInEx core is linked by absolute path and the folder must be
# kept), then install the mod OURSELVES by copying Mod\CopyToGame\* into
# the game folder and writing doorstop_config.ini pointing at the kept
# BepInEx.Preloader.dll.
#
# We do NOT run TeamBeefInstaller.exe. Its only job is to copy the
# CopyToGame files and fix up the doorstop path - which it does by
# auto-detecting the Steam copy and writing absolute paths into temp.
# Doing it ourselves avoids the GUI, the drag-and-drop, and the
# deleted-temp-path bug entirely.
function Install-BendyMod {
    param(
        [string]$targetGamePath,
        [string]$ModKeepDir
    )

    # RAR download uses temp; only the EXTRACTED mod must be permanent.
    $tempDir = Join-Path $env:TEMP "BendyVRDownload_$([System.IO.Path]::GetRandomFileName())"
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $rarPath = Join-Path $tempDir "BendyVR.rar"

    # Permanent extraction target on the same drive as the game.
    if (-not $ModKeepDir) { $ModKeepDir = Join-Path $targetGamePath "BendyVRInstall" }
    if (Test-Path $ModKeepDir) {
        try { Remove-Item $ModKeepDir -Recurse -Force -ErrorAction Stop } catch {}
    }
    New-Item -ItemType Directory -Path $ModKeepDir -Force | Out-Null

    $dl = Invoke-DownloadOrFallback -Url $MOD_URL -Destination $rarPath `
            -Label "BendyVR v1.2.2" `
            -ManualUrl "$INFO_URL/releases" `
            -Instructions "Download the latest BendyVR release .rar from the GitHub page that just opened. Place it at '$rarPath' and choose Retry." `
            -SkipMessage "Skipped - the VR mod archive is missing; the mod will NOT be installed."

    # Extract the RAR with 7-Zip into the PERMANENT folder
    $sevenZip = Get-SevenZip
    if ($sevenZip -and (Test-Path $rarPath)) {
        Write-Host " Extracting with 7-Zip ... " -NoNewline -ForegroundColor White
        $result = Start-Process $sevenZip -ArgumentList "x `"$rarPath`" -o`"$ModKeepDir`" -y" -Wait -PassThru -WindowStyle Hidden
        if ($result.ExitCode -eq 0) {
            Write-Host "OK" -ForegroundColor Green
        } else {
            Write-Host "FAILED (exit code $($result.ExitCode))" -ForegroundColor Red
            $fb = Invoke-InstallerFallback -Action "BendyVR archive extraction" `
                -Instructions "Open '$rarPath' with 7-Zip or WinRAR and extract its contents into '$ModKeepDir'. Then choose Retry." `
                -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
                -SourceFolder (Split-Path "$rarPath" -Parent) -DestFolder "$ModKeepDir" -AllowSkip $true
            if ([string]$fb -eq "quit") { return $false }
        }
    } elseif (Test-Path $rarPath) {
        $fb = Invoke-InstallerFallback -Action "BendyVR archive extraction" `
            -Url "https://www.7-zip.org/" `
            -Instructions "BendyVR ships as a .rar archive. Install 7-Zip to extract '$rarPath' into '$ModKeepDir', then choose Retry." `
            -SkipMessage "Skipped - cannot extract the BendyVR archive; install is incomplete." `
            -SourceFolder (Split-Path "$rarPath" -Parent) -DestFolder "$ModKeepDir" -AllowSkip $true
        if ([string]$fb -eq "quit") { return $false }
    }

    # Locate Mod\CopyToGame inside the extracted folder. This holds the
    # files that belong in the game directory: winhttp.dll,
    # doorstop_config.ini, and Bendy..._Data\Plugins\*.dll (VR runtime).
    $copyToGame = Get-ChildItem -Path $ModKeepDir -Directory -Filter "CopyToGame" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\ModFiles\\' } | Select-Object -First 1
    if (-not $copyToGame) {
        $copyToGame = Get-ChildItem -Path $ModKeepDir -Directory -Filter "CopyToGame" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    }

    if (-not $copyToGame) {
        Write-Fail "Could not find the mod's CopyToGame folder in the archive."
        Write-Info "Opening the extracted folder so you can copy files manually."
        try { Start-Process explorer.exe "`"$ModKeepDir`"" } catch {}
        Pause-User "Press Enter to continue..."
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        return $false
    }

    Write-Host " Installing mod files into the game folder..." -NoNewline -ForegroundColor White
    try {
        Get-ChildItem -Path $copyToGame.FullName -Force | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $targetGamePath -Recurse -Force
        }
        Write-Host " OK" -ForegroundColor Green
        Write-OK "winhttp.dll, doorstop and VR plugins copied."
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        $fb = Invoke-InstallerFallback -Action "copy mod files into the game folder" `
            -Instructions "Copy everything inside '$($copyToGame.FullName)' into '$targetGamePath' (overwrite if asked). Then choose Skip to continue." `
            -SkipMessage "Skipped - mod files were NOT copied; VR will not load." `
            -SourceFolder $copyToGame.FullName -DestFolder $targetGamePath -AllowSkip $true
        if ([string]$fb -eq "quit") { try { Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue } catch {}; return $false }
    }

    # Write doorstop_config.ini in the game folder pointing at the kept
    # BepInEx.Preloader.dll. This is the whole ballgame: winhttp.dll
    # reads this path, and if it's wrong/missing the game starts FLAT.
    $preloader = Get-ChildItem -Path $ModKeepDir -Filter "BepInEx.Preloader.dll" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\Mod\\BepInEx\\core\\' } | Select-Object -First 1
    if (-not $preloader) {
        $preloader = Get-ChildItem -Path $ModKeepDir -Filter "BepInEx.Preloader.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    $doorstop = Join-Path $targetGamePath "doorstop_config.ini"
    if ($preloader) {
        try {
            $ini = @(
                "[UnityDoorstop]",
                "enabled=true",
                "targetAssembly=$($preloader.FullName)",
                "ignoreDisableSwitch=true"
            )
            Set-Content -Path $doorstop -Value $ini -Encoding ASCII -Force
            Write-OK "doorstop_config.ini points at: $($preloader.FullName)"
        } catch {
            Write-Warn "Could not write doorstop_config.ini: $_"
        }
    } else {
        Write-Warn "BepInEx.Preloader.dll not found in the mod folder - VR may not load."
    }

    # Clean up ONLY the download temp - keep $ModKeepDir (the mod needs it).
    try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    return $true
}

# Write steam_appid.txt next to the EXE so the depot copy starts
# without Steam prompting a reinstall.
function Write-SteamAppId {
    param([string]$gamePath)
    try {
        $f = Join-Path $gamePath "steam_appid.txt"
        Set-Content -Path $f -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force
        Write-OK "steam_appid.txt created (prevents Steam re-install prompt)."
    } catch {
        Write-Warn "Could not create steam_appid.txt: $_"
        Write-Host " If Steam prompts to reinstall Bendy, manually create a file" -ForegroundColor Gray
        Write-Host " called 'steam_appid.txt' next to the EXE containing: $DEPOT_APPID" -ForegroundColor Gray
    }
}

# ============================================================
# MENU
# ============================================================
Write-Header
Write-Host " The current Steam build of Bendy and the Ink Machine no" -ForegroundColor White
Write-Host " longer starts with this VR mod (Team Beef, June 2025)." -ForegroundColor White
Write-Host " Choose how to install:" -ForegroundColor White
Write-Host ""
# Check whether the depot install already exists at the default
# destination - annotate Option [1] so the user can see at a
# glance whether the recommended variant is already on disk.
$depotInstalledStatus = $null
$depotInstalledColor  = "Gray"
try {
    $depotTargetCheck = Join-Path "C:\Games" "Bendy VR"
    $depotExeCheck    = Join-Path $depotTargetCheck "Bendy and the Ink Machine.exe"
    if (Test-Path $depotExeCheck) {
        $depotInstalledStatus = " [installed at $depotTargetCheck]"
        $depotInstalledColor  = "Green"
    } else {
        $depotInstalledStatus = " [not yet installed]"
        $depotInstalledColor  = "Gray"
    }
} catch {}

Write-Host "  [1] RECOMMENDED - Depot version" -ForegroundColor Green
if ($depotInstalledStatus) { Write-Host "     $depotInstalledStatus" -ForegroundColor $depotInstalledColor }
Write-Host "      Downloads the mod-compatible build via Steam Console" -ForegroundColor Gray
Write-Host "      into C:\Games\Bendy VR, then installs the mod. Your" -ForegroundColor Gray
Write-Host "      retail Steam copy stays untouched." -ForegroundColor Gray
Write-Host ""
Write-Host "  [2] Current game version" -ForegroundColor Yellow
Write-Host "      Installs the mod onto your existing copy (Steam or" -ForegroundColor Gray
Write-Host "      Epic). Use only if you specifically want the current" -ForegroundColor Gray
Write-Host "      build - on Steam it may not launch in VR. If it" -ForegroundColor Gray
Write-Host "      doesn't work, re-run and pick option 1." -ForegroundColor Gray
Write-Host ""
$mode = ""
while ($mode -notin @("1","2")) { $mode = (Read-Host " Enter 1 or 2").Trim() }

# ============================================================
# OPTION 1 - DEPOT
# ============================================================
if ($mode -eq "1") {
    Write-Step 1 4 "Steam Depot Download"

    Write-Host " We'll download the mod-compatible build via Steam Console" -ForegroundColor White
    Write-Host " as a separate copy. Your retail install stays untouched." -ForegroundColor White
    Write-Host ""
    Write-Host " Here's what's about to happen:" -ForegroundColor Cyan
    Write-Host " 1) The Steam Console will open" -ForegroundColor White
    Write-Host " 2) The download command is already on your clipboard" -ForegroundColor White
    Write-Host " 3) Paste with Ctrl+V into the Console and hit Enter" -ForegroundColor Yellow
    Write-Host " 4) Wait for Steam to finish, then come back here" -ForegroundColor White
    Write-Host ""
    Write-Host " When Steam finishes it will show:" -ForegroundColor Gray
    Write-Host "   Depot download complete : ...\depot_$DEPOT_DEPOTID" -ForegroundColor Yellow
    Write-Host ""

    try { Set-Clipboard -Value $DEPOT_COMMAND } catch {}

    Write-Host " ============================================================" -ForegroundColor Yellow
    Write-Host " ACTION REQUIRED - Paste into Steam Console" -ForegroundColor Yellow
    Write-Host " ============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " [OK] Depot command copied to clipboard." -ForegroundColor Yellow
    Write-Host " Command: $DEPOT_COMMAND" -ForegroundColor Gray
    Write-Host ""
    if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
        Write-Host " (i) Virtual Desktop users: the Steam Console may not open" -ForegroundColor DarkGray
        Write-Host "     automatically from inside a VD streaming session. If it" -ForegroundColor DarkGray
        Write-Host "     doesn't, open it manually: Steam menu bar - View - Console," -ForegroundColor DarkGray
        Write-Host "     then paste-and-Enter. Alternatively, choose [3] in the" -ForegroundColor DarkGray
        Write-Host "     next menu to use the DepotDownloader fallback." -ForegroundColor DarkGray
        Write-Host ""
    }
    Pause-User "Press Enter to open the Steam Console..."
    Start-Process "steam://nav/console"
    Write-OK "Steam Console opening..."
    Write-Host ""
    Pause-User "Press Enter once the Steam depot download is complete..."

    # Locate depot
    Write-Host ""
    Write-Host " Looking for Steam installation..." -ForegroundColor White
    $steamInstallPath = Get-SteamPath
    $depotPath = $null
    if ($steamInstallPath) {
        $autoPath = Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID"
        Write-Info "Expected depot path: $autoPath"
        if ((Test-Path $autoPath) -and (Test-Path (Join-Path $autoPath $GAME_EXE))) { $depotPath = $autoPath; Write-OK "Depot folder found automatically!" }
        else { Write-Warn "Depot folder not found yet at the expected location." }
    } else {
        Write-Warn "Could not find Steam installation in registry."
    }
    if (-not $depotPath) {
        $probePaths = @()
        if ($steamInstallPath) { $probePaths += (Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID") }
        $depotPath = Resolve-DepotPath -GameName "Bendy and the Ink Machine" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
        if (-not $depotPath) { Write-Fail "No depot folder provided."; Pause-User "Press Enter to exit..."; exit 1 }
    }

    # Sanity check
    $depotExe = Join-Path $depotPath $GAME_EXE
    if (-not (Test-Path $depotExe)) {
        Write-Warn "'$GAME_EXE' not found inside the depot."
        Write-Host " Expected: $depotExe" -ForegroundColor Gray
        Write-Host " The download may be incomplete or the wrong manifest." -ForegroundColor Gray
        $c = ""; while ($c -notin @("y","Y","n","N")) { $c = (Read-Host " Continue anyway? (Y/N)").Trim() }
        if ($c -in @("n","N")) { Write-Info "Aborted by user."; Pause-User "Press Enter to exit..."; exit 0 }
    } else {
        Write-OK "$GAME_EXE confirmed in depot."
    }

    # Move + rename
    Write-Step 2 4 "Moving game to stable folder"
    $parentOfDepot = Split-Path $depotPath -Parent
    Write-Host " Default install location: $DEFAULT_PATH" -ForegroundColor Gray
    Write-Host " (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
    Write-Host "  library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
    Write-Host ""
    $userInput = (Read-Host " Press Enter to use default, or type a different full path").Trim().Trim('"')
    if (-not $userInput) { $targetPath = $DEFAULT_PATH } else { $targetPath = $userInput }

    $targetParent = Split-Path $targetPath -Parent
    if ($targetParent -and -not (Test-Path $targetParent)) {
        try { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
        catch { Write-Fail "Could not create parent folder $targetParent : $_"; Pause-User "Press Enter to exit..."; exit 1 }
    }

    if (Test-Path $targetPath) {
        Write-Warn "A folder already exists at $targetPath"
        Write-Host " [Y] Delete existing folder and proceed" -ForegroundColor White
        Write-Host " [N] Keep it, abort install" -ForegroundColor Gray
        $c = ""; while ($c -notin @("y","Y","n","N")) { $c = (Read-Host " Your choice (Y/N)").Trim() }
        if ($c -in @("n","N")) { Write-Info "Aborted by user."; Pause-User "Press Enter to exit..."; exit 0 }
        try { Remove-Item $targetPath -Recurse -Force -ErrorAction Stop }
        catch { Write-Fail "Could not delete: $_"; Pause-User "Press Enter to exit..."; exit 1 }
    }

    try {
        Move-Item -Path $depotPath -Destination $targetPath -ErrorAction Stop
        Write-OK "Game moved to: $targetPath"
    } catch {
        Write-Fail "Move failed: $_"
        Write-Info "The game files are still at: $depotPath"
        $fb = Invoke-InstallerFallback -Action "move depot files to install folder" `
            -Instructions "The game files are still at '$depotPath'. Manually move them to '$targetPath'. Then choose Retry." `
            -SkipMessage "Skipped - game files are still in the temp folder; you must move them before launching." `
            -DestFolder "$targetPath" -AllowSkip $true
        if ([string]$fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
        if ([string]$fb -eq "retry") { Pause-User "Please re-run the installer once resolved. Press Enter to exit..."; exit 1 }
    }

    try {
        if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
            Remove-Item $parentOfDepot -Force
        }
    } catch {}

    $gamePath = $targetPath
    $gameExePath = Join-Path $gamePath $GAME_EXE

    # Install the mod
    Write-Step 3 4 "Installing the VR mod"
    [void](Install-BendyMod -targetGamePath $gamePath -ModKeepDir (Join-Path $gamePath "BendyVRInstall"))

    # steam_appid.txt
    Write-SteamAppId -gamePath $gamePath

    # Record install path for the Hub
    try {
        $pathFile = Join-Path $PSScriptRoot ".installed_path"
        Set-Content -Path $pathFile -Value $gamePath -Encoding UTF8 -Force
    } catch {}

    # Summary + shortcut
    Write-Step 4 4 "All Done!"
    Write-Host " Your Bendy VR (depot) installation is ready." -ForegroundColor White
    Write-Host ""
    Write-Host " Game folder: $gamePath" -ForegroundColor Yellow
    Write-Host " Launch EXE: $gameExePath" -ForegroundColor Yellow
    Write-Host ""

    if (Test-Path $gameExePath) {
        try {
            $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Bendy VR.lnk" -TargetPath $gameExePath -WorkingDir $gamePath -IconPath "$gameExePath,0"
            Write-OK "Desktop shortcut 'Bendy VR' created."
        } catch {
            Write-Warn "Could not create shortcut: $_"
            Write-Host " Launch manually from: $gameExePath" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host " IMPORTANT notes before you play:" -ForegroundColor Cyan
    Write-Host " >> Start SteamVR BEFORE launching Bendy VR." -ForegroundColor Yellow
    Write-Host " >> Launch via the Bendy VR desktop shortcut or through" -ForegroundColor Yellow
    Write-Host "    the PCVR Mods Installer Hub -> Start in VR, NOT via Steam." -ForegroundColor Yellow
    Write-Host "    (Launching via Steam would run your retail version.)" -ForegroundColor Gray
    Write-Host " >> Motion controllers are required - this is not playable" -ForegroundColor Yellow
    Write-Host "    with a normal gamepad." -ForegroundColor Yellow
    Write-Host " >> In SteamVR Settings -> Dashboard, set 'Present Non-VR" -ForegroundColor Yellow
    Write-Host "    Applications on Theater Screen Upon Launch' -> OFF." -ForegroundColor Yellow
    Write-Host ""
    Write-Host " Dreams come to life. So does the ink." -ForegroundColor Magenta
    Write-Host ""
    Pause-User "Press Enter to exit."
    exit 0
}

# ============================================================
# OPTION 2 - CURRENT GAME VERSION
# ============================================================
Write-Step 1 3 "Locating $GAME_NAME"
Write-Host " [!] You picked the current game build. Note: the current" -ForegroundColor Yellow
Write-Host "     Steam build may not launch with the VR mod. If you own" -ForegroundColor Yellow
Write-Host "     it on Epic this may not apply. If it doesn't work, re-run" -ForegroundColor Yellow
Write-Host "     this installer and pick option 1 (depot)." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to continue..."

$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        # Cover Steam AND Epic - Bendy is sold on both stores (and was
        # a free Epic giveaway in late 2025, so many own it there).
        $det = Find-GameInstall -GameName "Bendy and the Ink Machine" `
            -Steam @{ Folder = $GAME_FOLDER; AppID = $DEPOT_APPID } `
            -Epic  @{ FolderName = $GAME_FOLDER; AppName = "Bendy and the Ink Machine" } `
            -ExeName $GAME_EXE
        if ($det.Found) {
            $gamePath = $det.Path
            Write-Info "Detected via $($det.Source)."
        }
    }
} catch {}

if (-not $gamePath) {
    $steamPath = Get-SteamPath
    if ($steamPath) {
        foreach ($lib in (Get-SteamLibraries $steamPath)) {
            $c = Join-Path $lib "steamapps\common\$GAME_FOLDER"
            if (Test-Path $c) { $gamePath = $c; break }
        }
    }
}
if ($gamePath) {
    Write-OK "Game found: $gamePath"
} else {
    Write-Warn "Game not found automatically (checked Steam and Epic)."
    Write-Host " Please enter the game installation folder:" -ForegroundColor White
    while (-not $gamePath) {
        $r=(Read-Host " Path").Trim().Trim('"')
        if(Test-Path $r){$gamePath=$r; Write-OK "Path set: $gamePath"} else{Write-Fail "Not found: $r"}
    }
}

Write-Step 2 3 "Installing the VR mod"
[void](Install-BendyMod -targetGamePath $gamePath -ModKeepDir (Join-Path $gamePath "BendyVRInstall"))

Write-Step 3 3 "Final notes"
Write-Host " BendyVR installation complete (current game version)." -ForegroundColor Green
Write-Host ""
Write-Host " - Start SteamVR before launching the game." -ForegroundColor White
Write-Host " - Full motion controls supported - controllers required." -ForegroundColor Green
Write-Host " - In SteamVR Settings -> Dashboard, set 'Present Non-VR" -ForegroundColor Yellow
Write-Host "   Applications on Theater Screen Upon Launch' -> OFF." -ForegroundColor Yellow
Write-Host " - If the game won't start in VR, re-run and pick option 1" -ForegroundColor Yellow
Write-Host "   (depot version) which uses the mod-compatible build." -ForegroundColor Yellow
Write-Host " - More info: $INFO_URL" -ForegroundColor Gray
Write-Host ""
Write-Host " Dreams come to life. So does the ink." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
