# =============================================================
# Elden Ring build selection + pinned 1.16.2 depot copy
# =============================================================
# Patch 1.17 currently breaks the Elden Ring VR mods. The safe route is a
# SEPARATE 1.16.2 copy under C:\Games, exactly like Bendy / Ready Or Not:
# Steam's current install stays untouched and the Hub can launch either copy.

$script:EldenRingAppId = "1245620"
$script:EldenRingDepotDefault = "C:\Games\Elden Ring VR"
$script:EldenRingBuildLabel = "1.16.2 (build 22984413)"
$script:EldenRingBuildMarker = ".pcvrhub-eldenring-build"
$script:EldenRingMotionLauncher = "VRLaunch\Elden Ring VR (Motion Controls).bat"
$script:EldenRingHotbiteLauncher = "VRLaunch\Elden Ring VR (Hotbite).bat"
$script:EldenRingErvrLauncher = "VRLaunch\Elden Ring VR (ERVR).bat"
$script:EldenRingGamepadLauncher = "VRLaunch\Elden Ring VR (Gamepad).bat"

. (Join-Path $PSScriptRoot "EldenRingSaveManager.ps1")

# Can we actually create and write there? Creating the folder is part
# of the test - "the parent exists" says nothing about permission.
function global:Test-EldenRingTargetWritable {
    param([string]$Parent)
    if (-not $Parent -or -not (Test-NativeFileSystemPath $Parent)) { return $false }
    try {
        if (-not (Test-LiteralPathSafe -Path $Parent -PathType Container)) { New-Item -ItemType Directory -Path $Parent -Force -ErrorAction Stop | Out-Null }
        $probe = Join-PathLexical $Parent ".pcvrhub_write_probe"
        Set-Content -LiteralPath $probe -Value "ok" -ErrorAction Stop
        Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

function global:Test-EldenRingRoot {
    param([string]$Path)
    if (-not $Path) { return $false }
    try { return (Test-LiteralPathSafe -Path (Join-PathLexical $Path "Game\eldenring.exe") -PathType Leaf) }
    catch { return $false }
}

function global:Get-EldenRingDepotProbePaths {
    param([string]$DepotId)
    return @(Get-SteamDepotProbePaths -AppId $script:EldenRingAppId -DepotId $DepotId)
}

function global:Install-EldenRingDepotCopy {
    param(
        [string]$CurrentGameDir = "",
        [string]$TargetPath = $script:EldenRingDepotDefault
    )

    if (($CurrentGameDir -and -not (Test-NativeFileSystemPath $CurrentGameDir)) -or -not (Test-NativeFileSystemPath $TargetPath)) {
        Write-Fail "The current and target paths must use the filesystem syntax of this operating system."
        return $null
    }
    $currentFull = $null
    try {
        if ($CurrentGameDir) { $currentFull = [System.IO.Path]::GetFullPath($CurrentGameDir).TrimEnd([char[]]"\/") }
        $targetFull = [System.IO.Path]::GetFullPath($TargetPath).TrimEnd([char[]]"\/")
    } catch {
        Write-Fail "The current or target game path is invalid: $($_.Exception.Message)"
        return $null
    }
    if ($currentFull -and $currentFull.Equals($targetFull, [StringComparison]::OrdinalIgnoreCase)) {
        Write-Fail "The depot target must be separate from the live Steam installation."
        return $null
    }

    if ((Test-EldenRingRoot $TargetPath) -and
        (Test-Path -LiteralPath (Join-PathLexical $TargetPath $script:EldenRingBuildMarker))) {
        $have = ""
        try { $have = (Get-Content -LiteralPath (Join-PathLexical $TargetPath $script:EldenRingBuildMarker) -Raw).Trim() } catch {}
        Write-Host ""
        Write-OK "A pinned Elden Ring copy is already installed at $TargetPath"
        if ($have) { Write-Info "Recorded build: $have" }
        $reuse = ""
        for ($k = 1; $k -le 20; $k++) {
            $reuse = ("" + (Read-Host "  Use this existing depot copy? [y/n]")).Trim().ToLower()
            if ($reuse -in @("y","n","yes","no")) { break }
            Write-Warn "Please answer y or n."
        }
        if ($reuse -in @("y","yes")) { return $TargetPath }
    }

    # Prove the destination is usable BEFORE any depot download starts.
    # The target itself is left untouched until every depot is present.
    $parent = Get-PathParentLexical $TargetPath
    if (-not (Test-EldenRingTargetWritable -Parent $parent)) {
        Write-Warn "Cannot write to $parent"
        Write-Host "  The pinned copy needs its own folder OUTSIDE your Steam" -ForegroundColor White
        Write-Host "  library - Steam would otherwise manage it and patch it." -ForegroundColor Gray
        Write-Host ""
        $alt = (Read-Host "  Where should it go? (e.g. D:\Games)").Trim().Trim('"')
        if (-not $alt) {
            Write-Fail "No folder given - nothing was downloaded or copied."
            return $null
        }
        if ($alt -match '(?i)\\steamapps\\') {
            Write-Fail "That is inside a Steam library - pick a folder Steam does not manage."
            return $null
        }
        if (-not (Test-EldenRingTargetWritable -Parent $alt)) {
            Write-Fail "Cannot write to $alt either - nothing was downloaded or copied."
            return $null
        }
        $TargetPath = Join-PathLexical $alt (Get-PathLeafLexical $TargetPath)
        $parent = $alt
        try { $targetFull = [System.IO.Path]::GetFullPath($TargetPath).TrimEnd([char[]]"\/") }
        catch { Write-Fail "The target path is invalid: $($_.Exception.Message)"; return $null }
        Write-OK "Using: $TargetPath"
    }
    if ($currentFull -and $currentFull.Equals($targetFull, [StringComparison]::OrdinalIgnoreCase)) {
        Write-Fail "The depot target must be separate from the live Steam installation."
        return $null
    }

    Write-Host ""
    Write-Host "  PINNED DEPOT COPY - $script:EldenRingBuildLabel " -NoNewline -ForegroundColor Black -BackgroundColor Cyan
    Write-Host ""
    Write-Host ""
    Write-Host "  The two required Steam depots total about 50 GB. They are" -ForegroundColor White
    Write-Host "  assembled in $TargetPath; your live Steam copy is never" -ForegroundColor White
    Write-Host "  overwritten, downgraded or deleted." -ForegroundColor White
    Write-Host ""

    $depots = @(
        @{ Id="1245621"; Manifest="8620480158702245750"; What="game data"; Probe="Game\Data0.bdt" },
        @{ Id="1245624"; Manifest="5079239473805799861"; What="eldenring.exe"; Probe="Game\eldenring.exe" }
    )

    # Shadow of the Erdtree is a separate licensed depot. Include it only
    # when the current install proves the user owns/installed it.
    $hasDlc = $false
    if ($CurrentGameDir) {
        $hasDlc = (Test-Path -LiteralPath (Join-PathLexical $CurrentGameDir "Game\DLC.bdt")) -or
                  (Test-Path -LiteralPath (Join-PathLexical $CurrentGameDir "Game\DLC.bhd"))
    } else {
        Write-Host ""
        Write-Info "No current install is available to detect Shadow of the Erdtree."
        $dlcPick = ""
        for ($k = 1; $k -le 20; $k++) {
            $dlcPick = ("" + (Read-Host "  Do you own the Shadow of the Erdtree DLC and want its depot included? [y/n]")).Trim().ToLower()
            if ($dlcPick -in @("y","yes","n","no")) { break }
            Write-Warn "Please answer y or n."
        }
        $hasDlc = $dlcPick -in @("y","yes")
    }
    if ($hasDlc) {
        $depots += @{ Id="2778580"; Manifest="1674424364022381183"; What="Shadow of the Erdtree DLC"; Probe="Game\DLC.bdt" }
        Write-Info "Shadow of the Erdtree detected; its unchanged DLC depot will be included."
    }

    $downloaded = @()
    foreach ($d in $depots) {
        $cmd = "download_depot $script:EldenRingAppId $($d.Id) $($d.Manifest)"
        Write-Host ""
        Write-Host "  DEPOT $($downloaded.Count + 1) OF $($depots.Count): $($d.What) " -NoNewline -ForegroundColor Black -BackgroundColor Cyan
        Write-Host ""
        # !!! LOOK BEFORE ASKING. The download is 50 GB and Steam keeps
        # it in steamapps\content after a run. If a previous attempt got
        # that far - or crashed afterwards, which is exactly what
        # happened here - the files are still on disk. Asking for the
        # download first and only probing afterwards meant being told to
        # fetch 50 GB that were already sitting there.
        $found = $null
        foreach ($cand in (Get-EldenRingDepotProbePaths -DepotId $d.Id)) {
            if (Test-LiteralPathSafe -Path (Join-PathLexical $cand $d.Probe) -PathType Leaf) { $found = $cand; break }
        }
        if ($found) {
            Write-OK "Depot $($d.Id) is already downloaded: $found"
            Write-Info "Skipping the download - nothing to fetch again."
            $downloaded += ,@{ Path=$found; Label=$d.What }
            continue
        }

        Write-Host ""
        try { Set-Clipboard -Value $cmd; Write-Info "Command copied to the clipboard." } catch {}
        Write-Host "    $cmd" -ForegroundColor Cyan
        Write-Host ""
        Pause-User "Press Enter to open the Steam Console..." | Out-Null
        foreach ($u in @("steam://open/console", "steam://nav/console")) {
            try { Start-Process $u; Start-Sleep -Milliseconds 900 } catch {}
        }
        Write-Host "  Paste the command, press Enter, and wait for Steam to say" -ForegroundColor White
        Write-Host "  'Depot download complete'." -ForegroundColor White
        Pause-User "Press Enter once this depot is complete..." | Out-Null

        $found = $null
        foreach ($cand in (Get-EldenRingDepotProbePaths -DepotId $d.Id)) {
            if (Test-LiteralPathSafe -Path (Join-PathLexical $cand $d.Probe) -PathType Leaf) { $found = $cand; break }
        }
        if (-not $found) {
            $found = Resolve-DepotPath -GameName "Elden Ring $($d.What)" `
                -DepotCommand $cmd -GameExe $d.Probe `
                -ProbePaths (Get-EldenRingDepotProbePaths -DepotId $d.Id) `
                -AppId $script:EldenRingAppId -DepotId $d.Id -Manifest $d.Manifest
        }
        if (-not $found) {
            Write-Fail "Depot $($d.Id) was not found. Nothing was copied into the target."
            return $null
        }
        Write-OK "Found depot $($d.Id): $found"
        $downloaded += ,@{ Path=$found; Label=$d.What }
    }

    try {
        if (Test-Path -LiteralPath $TargetPath) {
            # A refused reuse or an unmarked/partial target must not be merged
            # blindly: files removed by a game update would survive and could
            # corrupt the pinned build. Preserve it by rename, then assemble a
            # clean target. Nothing is deleted.
            $backup = "$TargetPath.previous-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([Guid]::NewGuid().ToString('N').Substring(0,6))"
            Move-Item -LiteralPath $TargetPath -Destination $backup -ErrorAction Stop
            Write-Info "Existing target preserved as: $backup"
        }
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
        }
        foreach ($item in $downloaded) {
            [void](Merge-DirectoryTreeVerified -Source $item.Path -Destination $TargetPath -RemoveSource -Label "Elden Ring $($item.Label) depot")
        }
    } catch {
        Write-Fail "Could not assemble the depot copy: $($_.Exception.Message)"
        return $null
    }

    if (-not (Test-EldenRingRoot $TargetPath)) {
        Write-Fail "The depot copy is incomplete: Game\eldenring.exe is missing."
        return $null
    }
    try {
        Set-Content -LiteralPath (Join-PathLexical $TargetPath "steam_appid.txt") -Value $script:EldenRingAppId -Encoding ASCII -NoNewline -Force
        Set-Content -LiteralPath (Join-PathLexical $TargetPath "Game\steam_appid.txt") -Value $script:EldenRingAppId -Encoding ASCII -NoNewline -Force
        Set-Content -LiteralPath (Join-PathLexical $TargetPath $script:EldenRingBuildMarker) -Value $script:EldenRingBuildLabel -Encoding ASCII -NoNewline -Force
    } catch { Write-Warn "The build marker could not be written: $($_.Exception.Message)" }
    Write-OK "Pinned copy ready: $TargetPath"
    return $TargetPath
}

function global:Backup-EldenRingSave {
    # The same manager powers SWITCH_SAVE.bat. The old installer used a
    # separate .before-vr timestamp convention which the switch could not
    # restore. One naming scheme now handles the initial depot preparation
    # and every later current/depot change, including legacy migration.
    try {
        $root = Join-PathLexical $env:APPDATA "EldenRing"
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { return $true }
        if (@(Get-Process -Name "eldenring", "start_protected_game" -ErrorAction SilentlyContinue).Count -gt 0) {
            Write-Fail "Elden Ring is running. Close it before preparing the depot save."
            return $false
        }
        $saveDir = Select-EldenRingSaveAccountDirectory -SaveRoot $root
        if (-not $saveDir) {
            # A root with no numeric account folder means the game has not
            # produced a usable save yet, so there is nothing unsafe to move.
            if (@(Get-EldenRingSaveAccountDirectories -SaveRoot $root).Count -eq 0) { return $true }
            Write-Warn "No Steam account save folder was selected."
            return $false
        }
        $result = Invoke-EldenRingSaveSwitch -SaveDirectory $saveDir -TargetBuild Depot `
                    -AssumeLiveBuild Current -RequireConfirmation
        if (-not $result.Success) {
            Write-Warn "The depot save was not prepared: $($result.Reason)"
            return $false
        }
        if ($result.Changed) { Write-OK "The current-build save is parked; the depot save slot is active." }
        else { Write-Info $result.Reason }
        if ($result.Backup) { Write-OK "Verified safety copy: $($result.Backup)" }
        Write-Host ""
        Write-Host "  TURN STEAM CLOUD OFF FOR ELDEN RING " -NoNewline -ForegroundColor Black -BackgroundColor Red
        Write-Host ""
        Write-Host "  Use SWITCH_SAVE.bat whenever you change between the current" -ForegroundColor White
        Write-Host "  build and the pinned 1.16.2 build." -ForegroundColor White
        return $true
    } catch {
        Write-Warn "Could not move the save: $($_.Exception.Message)"
        Write-Do "Run SWITCH_SAVE.bat after closing Elden Ring."
        return $false
    }
}

function global:Select-EldenRingBuildTarget {
    param(
        [string]$CurrentGameDir = "",
        [string]$DepotPath = $script:EldenRingDepotDefault
    )
    Write-Host ""
    Write-Host "  Which Elden Ring build should receive the VR mod?" -ForegroundColor White
    Write-Host ""
    if (Test-EldenRingRoot $CurrentGameDir) {
        Write-Host "   [1] Current Steam version" -ForegroundColor Yellow
        Write-Host "       Uses the live Steam copy. Patch 1.17 currently breaks" -ForegroundColor Gray
        Write-Host "       these VR mods; choose this only for a future compatible update." -ForegroundColor Gray
    } else {
        Write-Host "   [1] Current Steam version [not installed]" -ForegroundColor DarkGray
        Write-Host "       Install Elden Ring through Steam before choosing this target." -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "   [2] Depot $script:EldenRingBuildLabel - RECOMMENDED" -ForegroundColor Green
    Write-Host "       Builds a separate copy at $DepotPath." -ForegroundColor Gray
    Write-Host "       Steam's current install remains untouched." -ForegroundColor Gray
    if (Test-EldenRingRoot $DepotPath) { Write-Host "       [already installed]" -ForegroundColor Green }
    Write-Host ""
    $pick = ""
    for ($k = 1; $k -le 20; $k++) {
        $pick = ("" + (Read-Host "  Enter 1 or 2")).Trim()
        if ($pick -eq "2" -or ($pick -eq "1" -and (Test-EldenRingRoot $CurrentGameDir))) { break }
        if ($pick -eq "1") { Write-Warn "The current Steam build is not installed; choose 2 for the depot."; continue }
        Write-Warn "Please answer 1 or 2."
    }
    if ($pick -notin @("1","2")) { return $null }
    if ($pick -eq "1") {
        return @{ GameDir=$CurrentGameDir; Mode="Current"; Label="current Steam version" }
    }
    # !!! ONE SAVE FILE FOR BOTH BUILDS. Elden Ring keeps its save in
    # %APPDATA%\EldenRing\<steamid>\ER0000.sl2 - not in the game folder -
    # so the pinned 1.16.2 copy reads the SAME file the current 1.17
    # build wrote. And 1.17 saves do not load on 1.16.2: the game refuses
    # save data from a newer version. Nothing to do with Steam being
    # online or offline, and no installer can separate them.
    #
    # Prepare the shared save BEFORE the depot build or either motion mod
    # can run. Refusal or an ambiguous/colliding set aborts safely instead
    # of installing a launcher which is guaranteed to hit the version error.
    if (-not (Backup-EldenRingSave)) {
        Write-Fail "The shared Elden Ring save was not prepared; depot setup stopped."
        return $null
    }

    $depot = Install-EldenRingDepotCopy -CurrentGameDir $CurrentGameDir -TargetPath $DepotPath
    if (-not $depot) { return $null }
    return @{ GameDir=$depot; Mode="Depot"; Label=$script:EldenRingBuildLabel }
}

function global:Write-EldenRingMotionLauncher {
    param([Parameter(Mandatory=$true)][string]$GameDir)
    $launchPath = Join-PathLexical $GameDir $script:EldenRingMotionLauncher
    $launchDir = Get-PathParentLexical $launchPath
    if (-not (Test-Path -LiteralPath $launchDir)) { New-Item -ItemType Directory -Path $launchDir -Force | Out-Null }
    # !!! NEVER A CHOOSER. This launcher used to ask "Press H for Hotbite
    # or E for ERVR" in a console window. That is exactly wrong: the user
    # already told the Hub what to start by clicking one side of the
    # split button, and being asked again - with a keypress, in a black
    # window - is an insult to that click. Start in VR means start.
    #
    # It now picks silently: ERVR if it is there, otherwise Hotbite. The
    # per-mod launchers beside it are what the split button uses anyway;
    # this one only exists for a desktop shortcut outside the Hub.
    $body = @'
@echo off
setlocal
set "ER_ROOT=%~dp0.."
set "HOT_ROOT=%LOCALAPPDATA%\Programs\Elden Ring VR Motion"
if exist "%ER_ROOT%\Game\ERVR\ERVR.dll" goto ervr
if exist "%HOT_ROOT%\mod\eldenring_vr.dll" goto hotbite
echo No Elden Ring motion-control mod was found for this build.
pause
exit /b 1
:hotbite
cd /d "%HOT_ROOT%"
if exist "%HOT_ROOT%\me3\bin\me3.exe" (
  start "" "%HOT_ROOT%\me3\bin\me3.exe" launch --game eldenring --exe "%ER_ROOT%\Game\eldenring.exe" --profile "%HOT_ROOT%\eldenring-vr.me3"
) else (
  echo ModEngine 3 is missing from %HOT_ROOT%.
  pause
)
exit /b
:ervr
cd /d "%ER_ROOT%\Game"
start "" "eldenring.exe"
exit /b
'@
    Set-Content -LiteralPath $launchPath -Value $body -Encoding ASCII -Force

    # Dedicated launchers are what the Hub's normal TwoMods cards use for
    # their Hotbite | ERVR split. The old implementation wrote only the
    # chooser above, so the catalog's two launcher markers could never both
    # exist. Write one dedicated launcher for each REAL installed mod and
    # remove its stale counterpart when the real DLL is gone.
    $hotPath = Join-PathLexical $GameDir $script:EldenRingHotbiteLauncher
    $ervrPath = Join-PathLexical $GameDir $script:EldenRingErvrLauncher
    $hotLocal = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
    $hotMarker = Join-Path $hotLocal "Programs\Elden Ring VR Motion\mod\eldenring_vr.dll"
    $ervrMarker = Join-PathLexical $GameDir "Game\ERVR\ERVR.dll"
    if (Test-Path -LiteralPath $hotMarker -PathType Leaf) {
        $hotBody = @'
@echo off
setlocal
set "ER_ROOT=%~dp0.."
set "HOT_ROOT=%LOCALAPPDATA%\Programs\Elden Ring VR Motion"
if not exist "%HOT_ROOT%\mod\eldenring_vr.dll" (
  echo Hotbite is not installed in %HOT_ROOT%.
  pause
  exit /b 1
)
if not exist "%HOT_ROOT%\me3\bin\me3.exe" (
  echo ModEngine 3 is missing from %HOT_ROOT%.
  pause
  exit /b 1
)
cd /d "%HOT_ROOT%"
start "" "%HOT_ROOT%\me3\bin\me3.exe" launch --game eldenring --exe "%ER_ROOT%\Game\eldenring.exe" --profile "%HOT_ROOT%\eldenring-vr.me3"
'@
        Set-Content -LiteralPath $hotPath -Value $hotBody -Encoding ASCII -Force
    } elseif (Test-Path -LiteralPath $hotPath) {
        Remove-Item -LiteralPath $hotPath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $ervrMarker -PathType Leaf) {
        $ervrBody = @'
@echo off
setlocal
set "ER_ROOT=%~dp0.."
if not exist "%ER_ROOT%\Game\ERVR\ERVR.dll" (
  echo ERVR is not installed in this Elden Ring build.
  pause
  exit /b 1
)
cd /d "%ER_ROOT%\Game"
start "" "eldenring.exe"
'@
        Set-Content -LiteralPath $ervrPath -Value $ervrBody -Encoding ASCII -Force
    } elseif (Test-Path -LiteralPath $ervrPath) {
        Remove-Item -LiteralPath $ervrPath -Force -ErrorAction SilentlyContinue
    }
    return $launchPath
}

function global:Write-EldenRingGamepadLauncher {
    param([Parameter(Mandatory=$true)][string]$GameDir)
    $launchPath = Join-PathLexical $GameDir $script:EldenRingGamepadLauncher
    $launchDir = Get-PathParentLexical $launchPath
    if (-not (Test-Path -LiteralPath $launchDir)) { New-Item -ItemType Directory -Path $launchDir -Force | Out-Null }
    $body = @'
@echo off
setlocal
set "ER_ROOT=%~dp0.."
cd /d "%ER_ROOT%\Game"
if not exist "%ER_ROOT%\Game\start_protected_game.exe" (
  echo start_protected_game.exe was not found.
  pause
  exit /b 1
)
start "" "start_protected_game.exe"
'@
    Set-Content -LiteralPath $launchPath -Value $body -Encoding ASCII -Force
    return $launchPath
}
