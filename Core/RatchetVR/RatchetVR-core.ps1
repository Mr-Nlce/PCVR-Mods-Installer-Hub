# ============================================================
# Ratchet & Clank VR Installer (fan project by Rybread69)
# ============================================================
# A free Unreal Engine fan project that recreates worlds from
# the first four PS2 Ratchet & Clank games in first-person VR.
# Distributed as a large .rar via a Google Drive link from the
# itch.io page - no automated download is possible, so this
# installer opens the download page and the user drags the
# downloaded .rar into this window.
#
# Install layout (the .rar wraps a "RatchetVR" folder; we
# flatten it so the EXE sits at the game-root):
#   <install_root>\Ratchet VR\RatchetVR.exe  (+ Engine, MyProject3, ...)
#   default install_root: C:\Games  (fallback D:\Games, E:\Games)
#
# Nothing here is shipped inside the Hub - the user-supplied
# .rar (~8 GB) provides the entire game payload.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Ratchet & Clank VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Ratchet & Clank VR Installer" -ForegroundColor Cyan
    Write-Host " fan project by Rybread69 | free itch.io / Google Drive download" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# Extract with 7-Zip's NATIVE progress (accurate %), but redirect its
# stdout to a temp file so the noisy "NN - filename" part never reaches the
# console. We poll the file and print ONLY the percentage, cleanly. If no
# percent is readable yet, the elapsed timer still moves (never looks frozen).
function Invoke-SevenZipExtract {
    param([string]$SevenZip, [string]$Archive, [string]$Dest)
    $progFile = Join-Path ([System.IO.Path]::GetTempPath()) ("7zp_" + [Guid]::NewGuid().ToString("N") + ".log")
    $proc = Start-Process -FilePath $SevenZip `
        -ArgumentList "x","-y","-bso0","-bsp1","`"$Archive`"","-o`"$Dest`"" `
        -PassThru -NoNewWindow -RedirectStandardOutput $progFile
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $pct = 0
    while (-not $proc.HasExited) {
        Start-Sleep -Milliseconds 500
        try {
            $fs = [System.IO.File]::Open($progFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $sr = New-Object System.IO.StreamReader($fs)
            $txt = $sr.ReadToEnd()
            $sr.Close(); $fs.Close()
            $mm = [regex]::Matches($txt, '(\d+)%')
            if ($mm.Count -gt 0) { $pct = [int]$mm[$mm.Count - 1].Groups[1].Value }
        } catch { }
        $el = $sw.Elapsed.ToString('mm\:ss')
        Write-Host ("`r  Extracting... {0,3}%   {1} elapsed        " -f $pct, $el) -NoNewline -ForegroundColor Gray
    }
    Write-Host "`r  Extracting... 100%   done                        " -ForegroundColor Gray
    Remove-Item $progFile -Force -ErrorAction SilentlyContinue
    # A no-wait Start-Process -PassThru object can THROW on .ExitCode, which
    # would be caught upstream as a failure and re-open the download. Judge
    # success by whether files were actually produced instead; the caller
    # then re-validates by searching for the game EXE in $Dest.
    $produced = $false
    try { $produced = @(Get-ChildItem -LiteralPath $Dest -Force -ErrorAction SilentlyContinue).Count -gt 0 } catch { }
    if ($produced) { return 0 } else { return 1 }
}

$SCRIPT_DIR     = Split-Path -Parent $MyInvocation.MyCommand.Path
$DOWNLOAD_URL   = "https://drive.google.com/file/d/1WVHI0DPNIQgzd6hcJ5d1rFkdPZIheD88/view"
$EXPECTED_RAR   = "RatchetVR.rar"
$GAME_FOLDER    = "Ratchet VR"
$GAME_EXE       = "RatchetVR.exe"
# Preferred install roots in order; first writable wins.
$DEFAULT_ROOTS  = @("C:\Games", "D:\Games", "E:\Games")

Write-Header

Write-Host "  Ratchet & Clank VR is a free fan project by Rybread69 that" -ForegroundColor Gray
Write-Host "  recreates worlds from the first four PS2 Ratchet & Clank" -ForegroundColor Gray
Write-Host "  games in first-person VR. There is no combat yet - it" -ForegroundColor Gray
Write-Host "  currently plays like an interactive museum of classic" -ForegroundColor Gray
Write-Host "  Ratchet & Clank memories." -ForegroundColor Gray
Write-Host ""
Write-Host "  Download (Google Drive, ~8 GB):" -ForegroundColor Cyan
Write-Host "   -> $DOWNLOAD_URL" -ForegroundColor DarkGray
# Check the disk before the browser - an 8 GB archive is exactly the kind
# of thing that is already sitting in Downloads from a previous attempt.
$preFound = Find-PredownloadedFile -Patterns @("RatchetVR.rar","*Ratchet*VR*.rar","*Ratchet*.rar") -Label "the Ratchet & Clank VR download"
if (-not $preFound) {
    Pause-User "Press Enter to open the download in your browser..." | Out-Null
    try { Start-Process $DOWNLOAD_URL } catch {
        Write-Warn "Could not open the browser. Visit the URL above manually."
    }

    # Look again once the user is back - the first pass ran before the
    # download could possibly exist.
    Pause-User "Press Enter once the download has finished..." | Out-Null
    $preFound = Find-PredownloadedFile -Patterns @("RatchetVR.rar","*Ratchet*VR*.rar","*Ratchet*.rar") -Label "the Ratchet & Clank VR download" -PageAlreadyOpen
}

# ---- 1. drag-and-drop the RAR -------------------------------
Write-Step 1 4 "Locate the downloaded RAR"
Write-Host "  Once $EXPECTED_RAR is on your disk, drop it here." -ForegroundColor Gray
Write-Host ""

$modRar = $preFound
$attempts = 0
while (-not $modRar) {
    $attempts++
    Write-Host "  Drag-and-drop the downloaded .rar into this window," -ForegroundColor Yellow
    Write-Host "  or paste / type its full path, then press Enter." -ForegroundColor White
    Write-Host "  (Press Enter on an empty line to skip this attempt.)" -ForegroundColor DarkGray
    $r = (Read-Host "  RAR path").Trim().Trim('"')
    if (-not $r) {
        if ($attempts -ge 5) {
            $fb = Invoke-InstallerFallback -Action "locate the Ratchet & Clank VR download" `
                -Subject "the Ratchet & Clank VR download (Google Drive)" `
                -Url $DOWNLOAD_URL `
                -Instructions "Open the Google Drive link, download '$EXPECTED_RAR' (~8 GB), then come back and drag it in. Choose Retry once the file is on disk." `
                -AllowSkip $false
            if ([string]$fb -eq "quit") {
                Write-Fail "Cannot continue without the download."
                Pause-User "Press Enter to exit..." | Out-Null
                exit 1
            }
            $attempts = 0
        }
        continue
    }
    if (-not (Test-Path $r)) { Write-Fail "File not found: $r"; continue }
    if ($r -notmatch '\.rar$') { Write-Fail "Path is not a .rar archive: $r"; continue }
    $modRar = [string]$r
    Write-OK "Archive located: $modRar"
}

# ---- 2. pick a writable install root ------------------------
Write-Step 2 4 "Choosing an install location"

function Test-WritableRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path $Root)) {
            New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null
        }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

$installRoot = $null
foreach ($r in $DEFAULT_ROOTS) {
    if (Test-WritableRoot -Root $r) { $installRoot = [string]$r; break }
}
if (-not $installRoot) {
    Write-Warn "None of the default roots (C:\Games, D:\Games, E:\Games) is writable."
    Write-Host "  Enter a folder where the game should be installed (will create '$GAME_FOLDER' inside)." -ForegroundColor White
    while (-not $installRoot) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
Write-OK "Install root: $installRoot"
$gameRoot = Join-Path $installRoot $GAME_FOLDER

# If an old install exists, offer overwrite.
if (Test-Path (Join-Path $gameRoot $GAME_EXE)) {
    Write-Warn "An existing Ratchet & Clank VR install was found at: $gameRoot"
    Write-Host "  Press Enter to overwrite it, or close this window to abort." -ForegroundColor Gray
    Pause-User "Press Enter to overwrite..." | Out-Null
}

# ---- 3. extract the RAR -------------------------------------
Write-Step 3 4 "Extracting Ratchet & Clank VR (this can take a while - ~8 GB)"

# The download is a .rar, so 7-Zip is REQUIRED. Get-SevenZip probes
# the standard locations and auto-installs 7-Zip if the user agrees.
$sevenZip = Get-SevenZip
if ($sevenZip) { Write-OK "7-Zip ready: $sevenZip" }
else { Write-Warn "7-Zip not available - will fall back to a manual extract prompt." }

# Extract to a temp folder under the install root (same volume =
# fast move later), then move the real game folder (the one holding
# RatchetVR.exe) into <gameRoot>, flattening the wrapping folder.
$tmp = Join-Path $installRoot "_ratchet_extract_tmp"
$extractOk = $false
while (-not $extractOk) {
    try {
        if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
        if ($sevenZip) {
            $ec = Invoke-SevenZipExtract -SevenZip $sevenZip -Archive $modRar -Dest $tmp
            if ($ec -eq 0) { $extractOk = $true }
            else { throw "7-Zip exited with code $ec" }
        } else {
            $fbx = Expand-ArchiveOrFallback -ArchivePath $modRar -DestinationFolder $tmp -Label "Ratchet & Clank VR" -AllowSkip $false
            if ([string]$fbx -eq "ok") { $extractOk = $true }
            elseif ([string]$fbx -eq "quit") {
                try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                Pause-User "Press Enter to exit..." | Out-Null
                exit 1
            }
        }
    } catch {
        Write-Fail "Could not extract the .rar: $_"
        $fb = Invoke-InstallerFallback -Action "extract the Ratchet & Clank VR .rar" `
            -Subject "the downloaded $EXPECTED_RAR" `
            -Url $DOWNLOAD_URL `
            -Instructions "The .rar may be incomplete or corrupted, or 7-Zip could not run. Re-download '$EXPECTED_RAR' (or extract it yourself into '$tmp'), then choose Retry. If you have a fresh copy at a different path, drag it in now." `
            -AllowSkip $false
        if ([string]$fb -eq "quit") {
            try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        Write-Host "  Drag in the .rar again (or press Enter to retry the same file)." -ForegroundColor White
        $again = (Read-Host "  RAR path").Trim().Trim('"')
        if ($again -and (Test-Path $again) -and ($again -match '\.rar$')) { $modRar = [string]$again }
    }
}

# Find the EXE inside the extracted tree to locate the real game folder.
$exeItem = Get-ChildItem -Path $tmp -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
while (-not $exeItem) {
    Write-Fail "'$GAME_EXE' not found in the extracted files."
    $fb = Invoke-InstallerFallback -Action "find $GAME_EXE in the download" `
        -Subject "the Ratchet & Clank VR download" `
        -Url $DOWNLOAD_URL `
        -Instructions "The .rar did not contain $GAME_EXE - it may be the wrong file or an incomplete download. Make sure you grabbed '$EXPECTED_RAR' from the Google Drive link, then choose Retry to re-extract." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
    Write-Host "  Drag in the correct .rar, then press Enter." -ForegroundColor White
    $again = (Read-Host "  RAR path").Trim().Trim('"')
    if ($again -and (Test-Path $again) -and ($again -match '\.rar$')) {
        $modRar = [string]$again
        try {
            if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
            New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null
            if ($sevenZip) {
                Invoke-SevenZipExtract -SevenZip $sevenZip -Archive $modRar -Dest $tmp | Out-Null
            } else {
                Expand-ArchiveOrFallback -ArchivePath $modRar -DestinationFolder $tmp -Label "Ratchet & Clank VR" -AllowSkip $false | Out-Null
            }
        } catch { Write-Fail "Re-extract failed: $_" }
    }
    $exeItem = Get-ChildItem -Path $tmp -Filter $GAME_EXE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
$extractedDir = Split-Path -Parent $exeItem.FullName

# Wipe any prior install, then move the extracted files into place.
$placedOk = $false
while (-not $placedOk) {
    try {
        if (Test-Path $gameRoot) { Remove-Item $gameRoot -Recurse -Force -ErrorAction Stop }
        New-Item -ItemType Directory -Path $gameRoot -Force -ErrorAction Stop | Out-Null
        $null = Get-ChildItem -Path $extractedDir -Force | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $gameRoot -Force -ErrorAction Stop
        }
        $placedOk = $true
    } catch {
        Write-Fail "Could not place the game files: $_"
        $fb = Invoke-InstallerFallback -Action "copy the game files into place" `
            -Instructions "Copy the contents of '$extractedDir' into '$gameRoot' (so that $GAME_EXE sits at its root). Then choose Retry, or Skip to finish manually." `
            -SourceFolder "$extractedDir" `
            -DestFolder "$gameRoot" `
            -AllowSkip $true
        if ([string]$fb -eq "quit") {
            try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            Pause-User "Press Enter to exit..." | Out-Null
            exit 1
        }
        if ([string]$fb -eq "skip") { break }
    }
}
try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
Write-OK "Game installed at: $gameRoot"

# ---- 4. desktop shortcut ------------------------------------
Write-Step 4 4 "Creating a desktop shortcut"
$exePath = Join-Path $gameRoot $GAME_EXE
if (-not (Test-Path $exePath)) {
    Write-Warn "Game EXE not found after install - shortcut skipped."
    Write-Host "  Open '$gameRoot' and confirm $GAME_EXE is there; if it sits in a" -ForegroundColor Gray
    Write-Host "  subfolder, move its contents up one level." -ForegroundColor Gray
} else {
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $lnkPath = Join-Path $desktop "Ratchet VR.lnk"
        $sc = New-DesktopShortcut -LnkPath $lnkPath -TargetPath $exePath -WorkingDir $gameRoot -IconPath $exePath
        Write-OK "Desktop shortcut created: Ratchet VR"
    } catch {
        Write-Warn "Could not create the desktop shortcut: $_"
        Write-Host "  You can launch the game manually with:" -ForegroundColor Gray
        Write-Host "    $exePath" -ForegroundColor Cyan
    }
}

# Record the install path so the Hub's "VR Installed" check finds it.
try {
    $marker = Join-Path $SCRIPT_DIR ".installed_path"
    Set-Content -Path $marker -Value $gameRoot -Force -ErrorAction Stop
} catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Ratchet & Clank VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Start your VR runtime first, then launch from the Hub with" -ForegroundColor White
Write-Host "  the" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "button. You can also use the 'Ratchet VR'" -ForegroundColor White
Write-Host "  desktop shortcut." -ForegroundColor White
Write-Host ""
Write-Host "  Tip: this is an early, growing fan project - there is no" -ForegroundColor Gray
Write-Host "  combat yet, so enjoy it as an explorable tour of the classic" -ForegroundColor Gray
Write-Host "  worlds. Smash crates, collect Bolts and try the gadgets." -ForegroundColor Gray
Write-Host ""

Write-Host "  Wrench up, Lombax - four classic worlds reborn, bolt by bolt." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
