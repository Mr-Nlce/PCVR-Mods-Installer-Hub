# ============================================================
# No One Lives Forever 2 VR Installer
# Layers Luke Ross's R.E.A.L. r3 VR mod onto an EXISTING,
# user-provided NOLF2 (English v1.3) install. The game is not
# sold in any store, so the user must own and provide a working
# copy. We ship ZERO game files - the mod (.rar) is downloaded
# from Luke Ross's public GitHub release at install time.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "No One Lives Forever 2 VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME    = "Luke Ross R.E.A.L. Release 3"
$GAME_EXE    = "NOLF2.exe"        # base-game marker used to locate the install
$LAUNCH_EXE  = "Lithtech.exe"     # the mod's launcher (overwrites the stock one)
$MOD_MARKER  = "VRlaunchcmds.txt" # root file added by the mod = VR installed
$BASE_URL    = "https://github.com/LukeRoss00/nolf2-real-mod/releases/download/r3/"
$LANGS = @{
    "EN" = "NOLF2_REAL_mod_by_LukeRoss_r3.rar"
    "DE" = "NOLF2_REAL_mod_by_LukeRoss_r3_DE.rar"
    "ES" = "NOLF2_REAL_mod_by_LukeRoss_r3_ES.rar"
    "FR" = "NOLF2_REAL_mod_by_LukeRoss_r3_FR.rar"
    "IT" = "NOLF2_REAL_mod_by_LukeRoss_r3_IT.rar"
}
$SEVENZIP_URL = "https://www.7-zip.org/download.html"
$SEVENZIP_DL  = "https://7-zip.org/a/7z2501-x64.exe"
# Official NOLF2 v1.3 patch (the R.E.A.L. mod requires English v1.3).
$V13_PATCH_URL = "https://archive.org/download/nolf2-update_1x3/nolf2-update_1x3.exe"
# Files worth backing up before the mod overwrites them (per the official ReadMe).
$BACKUP_ITEMS = @("autoexec.cfg", "Lithtech.exe", "LTMsg.dll", "SndDrv.dll", "Profiles")

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host " No One Lives Forever 2 VR Installer" -ForegroundColor Cyan
    Write-Host " Luke Ross R.E.A.L. Release 3" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [XX] $t" -ForegroundColor Red }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Find-7Zip {
    foreach ($key in @("HKLM:\SOFTWARE\7-Zip", "HKLM:\SOFTWARE\WOW6432Node\7-Zip", "HKCU:\SOFTWARE\7-Zip")) {
        try {
            $rp = (Get-ItemProperty -Path $key -ErrorAction Stop).Path
            if ($rp) { $exe = Join-Path $rp "7z.exe"; if (Test-Path $exe) { return $exe } }
        } catch {}
    }
    foreach ($p in @("${env:ProgramFiles}\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe", "${env:LOCALAPPDATA}\Programs\7-Zip\7z.exe")) {
        if (Test-Path $p) { return $p }
    }
    $cmd = Get-Command "7z.exe" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Find-WinRar {
    # WinRAR/UnRAR can also extract .rar. Either WinRAR.exe or UnRAR.exe
    # accepts the same "x -y archive dest\" command form.
    foreach ($p in @(
        "${env:ProgramFiles}\WinRAR\WinRAR.exe", "${env:ProgramFiles(x86)}\WinRAR\WinRAR.exe",
        "${env:ProgramFiles}\WinRAR\UnRAR.exe",  "${env:ProgramFiles(x86)}\WinRAR\UnRAR.exe")) {
        if (Test-Path $p) { return $p }
    }
    foreach ($n in @("WinRAR.exe", "UnRAR.exe")) {
        $c = Get-Command $n -ErrorAction SilentlyContinue
        if ($c) { return $c.Source }
    }
    return $null
}

# Extract a .rar into $DestDir with whichever extractor we have.
function Extract-Rar {
    param([string]$Rar, [string]$DestDir, $SevenZip, $WinRar)
    try {
        if ($SevenZip) { & $SevenZip x "$Rar" "-o$DestDir" -y | Out-Null; return $true }
        if ($WinRar)   { & $WinRar x -y "$Rar" "$DestDir\" | Out-Null; return $true }
    } catch { Write-Warn "Extraction failed: $_" }
    return $false
}

# Is the Oculus PC runtime present? Revive (embedded in this mod) needs
# it to bridge Oculus calls to SteamVR on non-Oculus headsets.
function Test-OculusRuntime {
    foreach ($key in @("HKLM:\SOFTWARE\WOW6432Node\Oculus VR, LLC\Oculus", "HKLM:\SOFTWARE\Oculus VR, LLC\Oculus")) {
        try { $b = (Get-ItemProperty -Path $key -ErrorAction Stop).Base; if ($b -and (Test-Path $b)) { return $true } } catch {}
    }
    try { if (Get-Service -Name "OVRService" -ErrorAction SilentlyContinue) { return $true } } catch {}
    foreach ($p in @("${env:ProgramW6432}\Oculus\Support\oculus-runtime\OVRServer_x64.exe", "${env:ProgramFiles}\Oculus\Support\oculus-runtime\OVRServer_x64.exe", "${env:ProgramFiles(x86)}\Oculus\Support\oculus-runtime\OVRServer_x64.exe")) {
        if (Test-Path $p) { return $true }
    }
    return $false
}

# Set the mod's +VRRevive flag in VRlaunchcmds.txt (0 = native Oculus,
# 1 = force the embedded Revive for SteamVR). The mod's own ReadMe says
# to add this at the end of the file, so we drop any old line and append.
function Set-VRReviveFlag {
    param([string]$GameDir, [int]$Value)
    $f = Join-Path $GameDir "VRlaunchcmds.txt"
    if (-not (Test-Path $f)) { return $false }
    try {
        $lines = @(Get-Content $f -ErrorAction Stop) | Where-Object { $_ -notmatch '(?i)^\s*\+VRRevive\b' }
        $lines += "+VRRevive $Value"
        Set-Content -Path $f -Value $lines -Encoding ASCII -Force
        return $true
    } catch { return $false }
}

# Drag the NOLF2 folder or NOLF2.exe; resolve the game folder (the one
# containing NOLF2.exe). Auto-detects the common retail install paths
# first, then falls back to asking. Loops until valid or cancelled.
function Get-Nolf2Folder {
    $stdPaths = @(
        "${env:ProgramFiles(x86)}\Fox\No One Lives Forever 2",
        "${env:ProgramFiles}\Fox\No One Lives Forever 2",
        "C:\Program Files (x86)\Fox\No One Lives Forever 2",
        "C:\Program Files\Fox\No One Lives Forever 2",
        "C:\GOG Games\No One Lives Forever 2",
        "C:\Games\No One Lives Forever 2",
        "C:\Games\NOLF2"
    )
    foreach ($sp in $stdPaths) {
        if ((Test-Path $sp) -and (Test-Path (Join-Path $sp $GAME_EXE))) {
            Write-Host ""
            Write-Host " Found a No One Lives Forever 2 install at:" -ForegroundColor White
            Write-Host "   $sp" -ForegroundColor Gray
            $useIt = Read-Host " Use this folder? (Y/N)"
            if ($useIt -match '^(y|yes|j|ja)$') { return $sp }
            break
        }
    }
    while ($true) {
        Write-Host ""
        Write-Host " Drag your No One Lives Forever 2 folder (or NOLF2.exe)" -ForegroundColor White
        Write-Host " onto this window and press Enter." -ForegroundColor White
        Write-Host " (You can also type or paste the full path.)" -ForegroundColor Gray
        Write-Host " Leave empty and press Enter to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " Path"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path $p)) { Write-Warn "Path not found: $p"; continue }
        if (Test-Path $p -PathType Container) {
            if (Test-Path (Join-Path $p $GAME_EXE)) { return $p }
            Write-Warn "No $GAME_EXE in that folder. Drag the folder that contains it."
            continue
        }
        # A file was dropped - use its folder if NOLF2.exe lives there.
        $dir = Split-Path -Parent $p
        if (Test-Path (Join-Path $dir $GAME_EXE)) { return $dir }
        Write-Warn "Could not find $GAME_EXE next to that file."
    }
}

Write-Header
Write-Host " This installs Luke Ross's R.E.A.L. VR mod into your OWN copy" -ForegroundColor White
Write-Host " of No One Lives Forever 2 (English, patched to v1.3)." -ForegroundColor White
Write-Host ""
Write-Host " - The game is not sold in any store, so you must already own" -ForegroundColor Gray
Write-Host "   and provide a working install." -ForegroundColor Gray
Write-Host " - Install NOLF2 somewhere you have full write access (e.g." -ForegroundColor Gray
Write-Host "   C:\Games\NOLF2), NOT inside Program Files." -ForegroundColor Gray
Write-Host " - Do NOT use the Widescreen Patch or any other NOLF2 mods -" -ForegroundColor Gray
Write-Host "   they conflict with the VR conversion." -ForegroundColor Gray
Write-Host ""
$go = Read-Host " Continue? (Y/N)"
if ($go -notmatch '^(y|yes|j|ja)$') { Write-Info "Cancelled."; Pause-User "Press Enter to exit..."; exit 0 }

# ---- STEP 1: choose the VR menu language ----
Write-Step 1 8 "Choosing the VR menu language"
Write-Host "  The mod's VR options/menus come in several languages." -ForegroundColor White
Write-Host "    [Enter] = English (default)" -ForegroundColor Gray
Write-Host "    DE = German   ES = Spanish   FR = French   IT = Italian" -ForegroundColor Gray
$langIn = (Read-Host "  Language (just press Enter for English)").Trim().ToUpper()
if (-not $langIn) { $langIn = "EN" }
if (-not $LANGS.ContainsKey($langIn)) { Write-Warn "Unknown code '$langIn' - using English."; $langIn = "EN" }
$rarName = $LANGS[$langIn]
$rarUrl  = $BASE_URL + $rarName
Write-OK "Selected: $langIn  ($rarName)"
if ($langIn -ne "EN") {
    Write-Warn "Localized build selected. You must also own the matching $langIn"
    Write-Host "      version of the original game AND the 1.3 patch, otherwise" -ForegroundColor Gray
    Write-Host "      voices and textures will still be in English." -ForegroundColor Gray
}

# ---- STEP 2: locate the user's NOLF2 ----
Write-Step 2 8 "Locating your NOLF2 install"
$gameDir = Get-Nolf2Folder
if (-not $gameDir) { Write-Info "No folder provided - cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
Write-OK "NOLF2 folder: $gameDir"
# Soft writability check - warn but never block.
try {
    $probe = Join-Path $gameDir ".pcvrhub_write_test"
    Set-Content -Path $probe -Value "x" -ErrorAction Stop
    Remove-Item $probe -Force -ErrorAction SilentlyContinue
} catch {
    Write-Warn "This folder may be read-only (Program Files?). If the install"
    Write-Host "      fails, move NOLF2 to e.g. C:\Games\NOLF2 and re-run." -ForegroundColor Gray
}

# ---- STEP 3: ensure the game is patched to v1.3 ----
Write-Step 3 8 "Checking the game patch (v1.3 required)"
Write-Host "  The R.E.A.L. mod requires NOLF2 English v1.3." -ForegroundColor White
Write-Host ""
Write-Host "  Not sure which version you have? If in doubt, press N to" -ForegroundColor Gray
Write-Host "  be safe. Running the patcher on an already-updated game" -ForegroundColor Gray
Write-Host "  may just report an error, which is harmless." -ForegroundColor Gray
Write-Host ""
$patched = (Read-Host "  Is your NOLF2 already on v1.3? (Y/N)").Trim()
if ($patched -notmatch '^(y|yes|j|ja)$') {
    Write-Info "Downloading the official v1.3 patch..."
    $v13 = Join-Path $env:TEMP "nolf2-update_1x3.exe"
    $dlp = Invoke-DownloadOrFallback -Url $V13_PATCH_URL -Destination $v13 -Label "NOLF2 v1.3 patch" `
            -ManualUrl $V13_PATCH_URL `
            -Instructions "Download nolf2-update_1x3.exe manually and run it against your NOLF2 install, then return here." `
            -SkipMessage "Skipped - the mod needs v1.3; the install may fail on an unpatched game."
    if ([string]$dlp -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if (Test-Path $v13) {
        Write-OK "Patch downloaded."
        Write-Host "  Launching the v1.3 patcher. Windows will show a UAC" -ForegroundColor White
        Write-Host "  prompt - confirm it to allow the patch to install." -ForegroundColor White
        Write-Host "  In the patcher window, point it at your NOLF2 folder" -ForegroundColor White
        Write-Host "  ($gameDir) and finish the update." -ForegroundColor White
        try { Start-Process -FilePath $v13 } catch { Write-Warn "Could not auto-launch the patcher. Run it manually: $v13" }
        Pause-User "Press Enter once the v1.3 update has finished..."
        try { Remove-Item $v13 -Force -ErrorAction SilentlyContinue } catch {}
    } else {
        Write-Warn "Patch not downloaded. Get it here and apply it before continuing:"
        Write-Host "      $V13_PATCH_URL" -ForegroundColor DarkGray
        Pause-User "Press Enter once your game is on v1.3..."
    }
} else {
    Write-OK "Game already on v1.3."
}

# ---- STEP 4: extractor for the .rar (7-Zip or WinRAR) ----
Write-Step 4 8 "Checking for 7-Zip / WinRAR"
$sevenZip = Find-7Zip
$winRar   = Find-WinRar
$manualExtract = $false
if ($sevenZip) {
    Write-OK "7-Zip found: $sevenZip"
} elseif ($winRar) {
    Write-OK "WinRAR found: $winRar"
} else {
    Write-Warn "No .rar extractor found (the mod ships as a .rar and"
    Write-Host "      PowerShell cannot open .rar on its own)." -ForegroundColor Gray
    $ans = Read-Host "  Download and install 7-Zip automatically now? (Y/N)"
    if ($ans -match '^(y|yes|j|ja)$') {
        $inst = Join-Path $env:TEMP "7zip-setup.exe"
        $d = Invoke-DownloadOrFallback -Url $SEVENZIP_DL -Destination $inst -Label "7-Zip installer" `
                -ManualUrl $SEVENZIP_URL `
                -Instructions "Install 7-Zip (or WinRAR) yourself, then re-run this installer." `
                -SkipMessage "Skipped - will guide a manual extract instead."
        if ([string]$d -eq "ok" -and (Test-Path $inst)) {
            Write-Host "  Installing 7-Zip silently (you may see a Windows security prompt)..." -ForegroundColor Gray
            try { Start-Process -FilePath $inst -ArgumentList "/S" -Verb RunAs -Wait } catch { Write-Warn "7-Zip install was cancelled or failed." }
            try { Remove-Item $inst -Force -ErrorAction SilentlyContinue } catch {}
            $sevenZip = Find-7Zip
        }
    }
    if ($sevenZip) {
        Write-OK "7-Zip ready: $sevenZip"
    } else {
        Write-Warn "No extractor available - the installer will guide a manual extract."
        try { Start-Process $SEVENZIP_URL } catch { Write-Warn "Open manually: $SEVENZIP_URL" }
        $manualExtract = $true
    }
}

# ---- STEP 5: download the mod (.rar) ----
Write-Step 5 8 "Downloading $MOD_NAME ($langIn)"
$rar = Join-Path $env:TEMP $rarName
$dl = Invoke-DownloadOrFallback -Url $rarUrl -Destination $rar -Label "$MOD_NAME (.rar)" `
        -ManualUrl $rarUrl `
        -Instructions "Download $rarName manually, then drag it here when asked." `
        -SkipMessage "Skipped - without the mod .rar the install cannot continue."
if ([string]$dl -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not (Test-Path $rar)) {
    Write-Warn "Mod archive not found at $rar."
    while (-not (Test-Path $rar)) {
        $alt = (Read-Host " Drag the downloaded $rarName here (or empty to cancel)").Trim().Trim('"').Trim("'").Trim()
        if (-not $alt) { Write-Fail "No archive - aborting."; Pause-User "Press Enter to exit..."; exit 1 }
        if (Test-Path $alt) { $rar = $alt; break }
        Write-Warn "Not found: $alt"
    }
}
Write-OK "Mod archive ready."

# ---- STEP 6: install the mod into the game folder ----
Write-Step 6 8 "Installing the mod into $gameDir"

# Safety: back up the files the mod will overwrite (saves are untouched,
# but the stock Player profile options get reset). Best-effort, never aborts.
$backupDir = Join-Path $gameDir "_backup_pre_REAL"
try {
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Force -Path $backupDir | Out-Null }
    foreach ($it in $BACKUP_ITEMS) {
        $srcIt = Join-Path $gameDir $it
        $dstIt = Join-Path $backupDir $it
        if ((Test-Path $srcIt) -and -not (Test-Path $dstIt)) {
            try { Copy-Item $srcIt $dstIt -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
    Write-Info "Backed up original files to: $backupDir"
} catch {}

$installedOk = $false
if (-not $manualExtract -and ($sevenZip -or $winRar)) {
    $xtemp = Join-Path $env:TEMP ("nolf2_r3_" + [System.IO.Path]::GetRandomFileName())
    try { New-Item -ItemType Directory -Force -Path $xtemp | Out-Null } catch {}
    if (Extract-Rar -Rar $rar -DestDir $xtemp -SevenZip $sevenZip -WinRar $winRar) {
        # The .rar unpacks flat (files at root) but anchor on the mod
        # marker in case a wrapper folder appears, then copy that whole
        # root into the game folder, recreating subfolders (NOLF2Revive\,
        # Profiles\) and never aborting on a single item.
        $keyHit = Get-ChildItem -Path $xtemp -Filter $MOD_MARKER -Recurse -ErrorAction SilentlyContinue | Sort-Object { $_.FullName.Length } | Select-Object -First 1
        if ($keyHit) {
            $modRoot = Split-Path -Parent $keyHit.FullName
            $copied = 0
            foreach ($item in (Get-ChildItem -Path $modRoot -Recurse -Force -ErrorAction SilentlyContinue)) {
                $rel = $item.FullName.Substring($modRoot.Length).TrimStart('\','/')
                if (-not $rel) { continue }
                $dest = Join-Path $gameDir $rel
                try {
                    if ($item.PSIsContainer) {
                        if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
                    } else {
                        $destParent = Split-Path -Parent $dest
                        if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Force -Path $destParent | Out-Null }
                        Copy-Item -Path $item.FullName -Destination $dest -Force
                        $copied++
                    }
                } catch { Write-Warn "Could not copy $rel" }
            }
            Write-Host "  Copied $copied mod files into the game folder." -ForegroundColor Gray
            if (Test-Path (Join-Path $gameDir $MOD_MARKER)) { $installedOk = $true }
        } else {
            Write-Warn "Could not find $MOD_MARKER inside the archive."
        }
    }
    try { Remove-Item $xtemp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}
if (-not $installedOk) {
    # Fallback: guide a manual extract straight into the game folder.
    Write-Host "  Please extract the CONTENTS of:" -ForegroundColor White
    Write-Host "    $rar" -ForegroundColor Gray
    Write-Host "  directly into your NOLF2 folder, confirming overwrite:" -ForegroundColor White
    Write-Host "    $gameDir" -ForegroundColor Gray
    Write-Host "  (so that $MOD_MARKER and VR.rez end up next to $GAME_EXE)." -ForegroundColor Gray
    try { Start-Process (Split-Path -Parent $rar) } catch {}
    try { Start-Process $gameDir } catch {}
    Pause-User "Press Enter once you have extracted the mod into the game folder..."
    if (Test-Path (Join-Path $gameDir $MOD_MARKER)) { $installedOk = $true }
}
if ($installedOk) {
    Write-OK "Mod installed - $MOD_MARKER is in place."
    if (Test-Path -LiteralPath "$gameDir\VR.rez") { Write-OK "VR content in place - VR.rez." }
    else { Write-Warn "VR.rez is missing - make sure the WHOLE .rar was extracted." }
} else {
    Write-Warn "$MOD_MARKER not found in $gameDir - the mod may not be installed correctly."
}

# ---- STEP 7: headset / VR runtime (Revive is embedded in the mod) ----
Write-Step 7 8 "Headset & VR runtime"
Write-Host "  This mod targets the Oculus runtime. For non-Oculus headsets it" -ForegroundColor White
Write-Host "  uses the Revive layer that is ALREADY bundled inside the mod" -ForegroundColor White
Write-Host "  (the NOLF2Revive folder) - nothing extra to install for Revive." -ForegroundColor White
Write-Host ""
Write-Host "    [1] Meta / Oculus (Rift, or Quest via Link / Air Link)" -ForegroundColor Gray
Write-Host "        -> runs natively on the Oculus runtime" -ForegroundColor DarkGray
Write-Host "    [2] SteamVR headset (Valve Index, HTC Vive, Pico, WMR, or" -ForegroundColor Gray
Write-Host "        Quest over Virtual Desktop / Steam Link) -> uses Revive" -ForegroundColor DarkGray
Write-Host ""
$headset = ""
while ($headset -notin @("1","2")) { $headset = (Read-Host "  Choice (1/2)").Trim() }
if ($headset -eq "1") {
    if (Set-VRReviveFlag -GameDir $gameDir -Value 0) { Write-OK "Set native Oculus mode (+VRRevive 0)." }
    else { Write-Warn "Could not edit VRlaunchcmds.txt - the mod will auto-detect your headset." }
} else {
    if (Set-VRReviveFlag -GameDir $gameDir -Value 1) { Write-OK "Set Revive mode for SteamVR (+VRRevive 1)." }
    else { Write-Warn "Could not edit VRlaunchcmds.txt - add the line '+VRRevive 1' to it by hand." }
    # Revive (embedded) needs the Oculus PC runtime present to work.
    if (Test-OculusRuntime) {
        Write-OK "Oculus runtime detected - Revive has what it needs."
    } else {
        Write-Warn "The Oculus PC runtime was NOT found. The embedded Revive needs it"
        Write-Host "      (you can skip the first-time setup; no Oculus account required)." -ForegroundColor Gray
        $OCULUS_SETUP = "https://www.meta.com/quest/setup/"
        Write-Host "      Opening the Meta/Oculus PC software page: $OCULUS_SETUP" -ForegroundColor Gray
        try { Start-Process $OCULUS_SETUP } catch { Write-Warn "Open manually: $OCULUS_SETUP" }
    }
}

# ---- STEP 8: shortcut + records ----
Write-Step 8 8 "Finishing setup"
$launchPath = Join-Path $gameDir $LAUNCH_EXE
if (-not (Test-Path $launchPath)) { $launchPath = Join-Path $gameDir $GAME_EXE }  # fall back to the stock launcher
try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "No One Lives Forever 2 VR.lnk"
    $sc = New-DesktopShortcut -LnkPath $lnk -TargetPath $launchPath -WorkingDir $gameDir -IconPath $launchPath
    Write-OK "Desktop shortcut created: No One Lives Forever 2 VR"
} catch {
    Write-Warn "Could not create the desktop shortcut. Launch $LAUNCH_EXE from $gameDir."
}
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}
try { Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value $launchPath -Encoding UTF8 -Force } catch {}
try { Remove-Item $rar -Force -ErrorAction SilentlyContinue } catch {}

# ---- How to play ----
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " HOW TO PLAY" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " 1) Start SteamVR first (Rift users can skip this)." -ForegroundColor White
Write-Host " 2) Launch with 'Start in VR' in the Hub, or the" -ForegroundColor White
Write-Host "    'No One Lives Forever 2 VR' desktop" -ForegroundColor White
Write-Host "    shortcut (it runs Lithtech.exe)." -ForegroundColor White
Write-Host " 3) Switch on your Xbox controller BEFORE launching - it must" -ForegroundColor White
Write-Host "    be connected (steady, non-blinking light) or it won't be" -ForegroundColor White
Write-Host "    recognised. Mouse + keyboard also work at a desk." -ForegroundColor White
Write-Host " 4) Touch/Vive controllers are NOT supported (too few buttons)." -ForegroundColor Gray
Write-Host ""
Write-Host " - Leave the resolution at the mod's default 1280x960." -ForegroundColor Gray
Write-Host " - Headset mode was set for you (+VRRevive in VRlaunchcmds.txt)." -ForegroundColor Gray
Write-Host "   Non-Oculus headsets use the embedded Revive, which needs the" -ForegroundColor Gray
Write-Host "   Oculus runtime installed (no Oculus account required)." -ForegroundColor Gray
Write-Host " - Tweak VRSuperSampling (1.0-2.0) in VRlaunchcmds.txt for" -ForegroundColor Gray
Write-Host "   sharpness; keep VR.rez last in that file." -ForegroundColor Gray
Write-Host " - The full controller map and options are on this game's" -ForegroundColor Gray
Write-Host "   description page in the Hub." -ForegroundColor Gray

# Luke Ross support
Write-Host ""
Write-Host " Like the mod? Support Luke Ross: https://www.patreon.com/realvr" -ForegroundColor White

Write-Host ""
Write-Host " Slip into Cate Archer's shoes, outwit H.A.R.M., and make spycraft look effortless." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
