param([string]$Mod='')
# ============================================================
# Bendy and the Ink Machine - BendyVR Mod Installer
# ============================================================
# Two independent install paths:
#   Option 1: InkVR on the current Steam IL2CPP build; latest stable.
#   Option 2: Team Beef on the pinned Mono depot; fixed v1.2.2.
# The obsolete Team Beef Current installation is no longer offered.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")
. (Join-Path $PSScriptRoot "..\Modules\InkVRSetup.ps1")

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
$DEFAULT_PATH   = Join-PathLexical $DEFAULT_PARENT $TARGET_NAME

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Yellow; Write-Host " Bendy and the Ink Machine - BendyVR Installer" -ForegroundColor Yellow; Write-Host " InkVR Current / Team Beef Depot" -ForegroundColor Gray; Write-Host "============================================================" -ForegroundColor Yellow; Write-Host "" }
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($x) Write-Host " [OK] $x" -ForegroundColor Green }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Write-Info { param($x) Write-Host "  $x" -ForegroundColor Gray }
function Pause-User { param($text = 'Press Enter to continue...', $Color = 'Yellow') [void](Wait-PCVRExplicitEnter -Message $text) }

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

    $dl = Invoke-DownloadOrFallback -Url $MOD_URL -Destination $rarPath `
            -Label "BendyVR v1.2.2" `
            -ManualUrl "$INFO_URL/releases/tag/v.1.2.2" `
            -Instructions "Download the pinned BendyVR v1.2.2 release .rar from the GitHub page that just opened. Place it at '$rarPath' and choose Retry." `
            -SkipMessage "Skipped - the VR mod archive is missing; the mod will NOT be installed."

    if (-not (Test-Path -LiteralPath $rarPath -PathType Leaf)) {
        Write-Fail 'The VR mod archive is missing. The existing installation was left alone.'
        try { Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        return $false
    }
    if (Test-Path -LiteralPath $ModKeepDir -PathType Container) {
        try { Remove-Item -LiteralPath $ModKeepDir -Recurse -Force -ErrorAction Stop } catch { Write-Fail "Could not replace the previous mod folder: $_"; return $false }
    }
    New-Item -ItemType Directory -Path $ModKeepDir -Force | Out-Null

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
        $null = Merge-DirectoryTreeVerified -Source $copyToGame.FullName -Destination $targetGamePath -Label "Bendy VR mod files" `
            -KeepExistingRelativePaths @("BepInEx\config")
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
    $requiredModFiles = @(
        (Join-Path $targetGamePath 'winhttp.dll'),
        (Join-Path $targetGamePath 'doorstop_config.ini'),
        (Join-Path $targetGamePath 'Bendy and the Ink Machine_Data\Plugins\openvr_api.dll'),
        (Join-Path $ModKeepDir 'BendyVRInstall\Mod\BepInEx\core\BepInEx.Preloader.dll'),
        (Join-Path $ModKeepDir 'BendyVRInstall\Mod\BepInEx\plugins\BendyVR_5.dll')
    )
    foreach ($requiredFile in $requiredModFiles) {
        if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
            Write-Fail "Required Bendy VR file missing: $requiredFile"
            return $false
        }
    }
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
Write-Host '  [1] RECOMMENDED - InkVR, current Steam game (auto-update)' -ForegroundColor Green
Write-Host '      Installs the modern OpenXR mod on your current Steam game.'
Write-Host '      Your separate Team Beef depot is kept.'
Write-Host ''
Write-Host '  [2] Team Beef - pinned Depot version' -ForegroundColor Yellow
Write-Host "      Default game folder: $DEFAULT_PATH (or choose another)."
Write-Host '      Original BendyVR 1.2.2; SteamVR; fixed game and mod versions.'
Write-Host ''
$mode = switch ($Mod) { 'Current' {'1'} 'Depot' {'2'} default {''} }
while ($mode -notin @('1','2')) { $mode=(Read-Host '  Enter 1 or 2').Trim() }
if ($mode -eq '1') {
    while ($true) {
        try { Invoke-InkVRSetup -InstallerFolder $PSScriptRoot; break }
        catch {
            $message='InkVR setup did not complete: '+$_.Exception.Message
            Write-Host $message -ForegroundColor Red
            if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'bendy-vr' -InstallerFolder $PSScriptRoot -RecoveryPageUrl 'https://github.com/StrikeZoneVR-hub/InkVR/releases')
        }
    }
    exit 0
}
Show-AntivirusNotice -Compact
Write-Host '  WMR + OASIS WILL PROBABLY NOT WORK with Team Beef.' -ForegroundColor Yellow
Write-Host '  Its skeletal finger tracking failed in the Reverb G2 test.'
Write-Host '  This warning concerns Team Beef, not the OpenXR InkVR route.'

# ============================================================
# OPTION 2 - TEAM BEEF DEPOT
# ============================================================
if ($mode -eq "2") {
    Pause-User "Press Enter to start..."
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

    try { Set-Clipboard -Value $DEPOT_COMMAND -DeferManualFallback } catch {}

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
# !!! LOOK BEFORE ASKING. Steam keeps a finished depot in
# steamapps\content, so a second run - or a run after a crash - already
# has the files. Prompting first and probing only afterwards sends the
# user to fetch gigabytes that are already on disk. Find-SteamDepotPath
# is cheap and touches nothing.
$script:PreFoundDepot = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE
if ($script:PreFoundDepot) {
    Write-OK "The depot is already downloaded: $script:PreFoundDepot"
    Write-Info "Skipping the download - nothing to fetch again."
}
if (-not $script:PreFoundDepot) {

    Pause-User "Press Enter to open the Steam Console..."
    [void](Open-PCVRSteamConsole)
    Show-PCVRClipboardManualFallback -Text $DEPOT_COMMAND
}
    if (-not $script:PreFoundDepot) { Write-OK "Steam Console confirmed visible." }
    Write-Host ""
    Pause-User "Press Enter once the Steam depot download is complete..."

    # Locate depot
    Write-Host ""
    Write-Host " Looking for Steam installation..." -ForegroundColor White
    $steamInstallPath = Get-SteamPath
    $probePaths = @(Get-SteamDepotProbePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -AdditionalSteamRoots @($steamInstallPath))
    $depotPath = Find-SteamDepotPath -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -GameExe $GAME_EXE -AdditionalSteamRoots @($steamInstallPath)
    if ($depotPath) { Write-OK "Depot folder found automatically: $depotPath" }
    else { Write-Warn "Depot folder not found yet in any Steam library." }
    if (-not $depotPath) {
        $depotPath = Resolve-DepotPath -GameName "Bendy and the Ink Machine" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
        if (-not $depotPath) { Write-Fail "No depot folder provided."; Pause-User "Press Enter to exit..."; exit 1 }
    }

    # Sanity check
    $depotExe = Join-PathLexical $depotPath $GAME_EXE
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
    $parentOfDepot = Get-PathParentLexical $depotPath
    Write-Host " (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
    Write-Host "  library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
    Write-Host ""
    $targetPath = Select-PCVRDepotInstallPath -DefaultPath $DEFAULT_PATH

    $targetParent = Get-PathParentLexical $targetPath
    if (-not (Test-InstallerTargetWritable -TargetPath $targetPath)) {
        Write-Fail "The target folder is not writable: $targetParent"
        Pause-User "Press Enter to exit..."; exit 1
    }

    if (Test-LiteralPathSafe -Path $targetPath -PathType Container) {
        Write-Warn "A folder already exists at $targetPath"
        Write-Info "The pinned build will be merged into it; saves, configs, mods and other additional files are preserved."
    }

    try {
        $null = Merge-DirectoryTreeVerified -Source $depotPath -Destination $targetPath -RemoveSource -Label "Bendy depot build"
        Write-OK "Game installed at: $targetPath"
    } catch {
        Write-Fail "Merge failed: $_"
        Write-Info "The game files are still at: $depotPath"
        $fb = Invoke-InstallerFallback -Action "merge depot files into the install folder" `
            -Instructions "Copy the contents of '$depotPath' into '$targetPath' without deleting additional destination files. Then choose Retry." `
            -SkipMessage "Skipped - the depot files were not merged into the target." `
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
    if (-not (Install-BendyMod -targetGamePath $gamePath -ModKeepDir (Join-Path $gamePath "BendyVRInstall"))) {
        Write-Fail 'The depot game was copied, but the VR mod was not installed. No VR-ready path was recorded.'
        Pause-User 'Press Enter to close.' | Out-Null
        exit 1
    }

    # steam_appid.txt
    Write-SteamAppId -gamePath $gamePath

    # Summary + shortcut
    Write-Step 4 4 "Finishing setup"
    Write-Host ""
    Write-Host " Game folder: $gamePath" -ForegroundColor Yellow
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

    # The Current route now uses live exact-version tracking. The fixed Depot
    # must commit its own fixed version too; a generic path alone is not success.
    $depotProof=@($GAME_EXE,'UnityPlayer.dll','Bendy and the Ink Machine_Data\Managed\Assembly-CSharp.dll','winhttp.dll','doorstop_config.ini','steam_appid.txt','Bendy and the Ink Machine_Data\Plugins\openvr_api.dll','BendyVRInstall\BendyVRInstall\Mod\BepInEx\core\BepInEx.Preloader.dll','BendyVRInstall\BendyVRInstall\Mod\BepInEx\plugins\BendyVR_5.dll')
    if(([IO.File]::ReadAllText((Join-Path $gamePath 'steam_appid.txt'))).Trim() -ne $DEPOT_APPID){throw 'The pinned Bendy depot has no correct steam_appid.txt. No success was recorded.'}
    $contract=New-PCVRInstallerContract -Id 'bendy-vr' -GameName 'Bendy VR' -Acquisition SteamDepot -PinnedDepot -AntivirusNotice -Routes @('Depot') -RequiredInstalledFileGroups $depotProof
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $gamePath -Version 'v1.2.2' -Route Depot -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path'),(Join-Path $PSScriptRoot '.installed_path_depot')))
    Write-Host ' Your Bendy VR (depot) installation is ready.' -ForegroundColor Green
    Write-Host ""
    Write-Host " IMPORTANT notes before you play:" -ForegroundColor Cyan
    Write-Host " >> Launch SteamVR before the game to avoid it potentially" -ForegroundColor Yellow
Write-Host "    starting sometimes out of focus." -ForegroundColor Yellow
    Write-Host " 1. Use Start in VR in the Hub (Team Beef Depot)." -ForegroundColor Yellow
    Write-Host "    Alternative: the Bendy VR desktop shortcut." -ForegroundColor Yellow
    Write-Host "    (Launching via Steam would run your retail version.)" -ForegroundColor Gray
    Write-Host " >> Motion controllers are required - this is not playable" -ForegroundColor Yellow
    Write-Host "    with a normal gamepad." -ForegroundColor Yellow
    Write-Host " >> In SteamVR Settings -> Dashboard, set 'Present Non-VR" -ForegroundColor Yellow
    Write-Host "    Applications on Theater Screen Upon Launch' -> OFF." -ForegroundColor Yellow
    Write-Host ""
    Write-Host " Dreams come to life. So does the ink." -ForegroundColor Magenta
    Write-Host ""
    Pause-User "Press Enter to close setup..."
    exit 0
}

