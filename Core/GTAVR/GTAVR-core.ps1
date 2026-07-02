# ============================================================
# Grand Theft Auto V VR Installer
# Layers Luke Ross's R.E.A.L. r7 VR mod onto an EXISTING,
# user-provided GTA V (Legacy) install on build 1.0.2245.0.
# We ship ZERO game files - the user must own and provide a
# working, launchable copy. The mod (.rar) is downloaded from
# Luke Ross's public GitHub release at install time.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Grand Theft Auto V VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME       = "Luke Ross R.E.A.L. r7"
$TARGET_VERSION = "1.0.2245.0"
$GAME_EXE       = "GTA5.exe"
$LAUNCH_EXE     = "PlayGTAV.exe"
$LR_R7_URL      = "https://github.com/LukeRoss00/gta5-real-mod/releases/download/r7/GTAV_REAL_mod_by_LukeRoss_r7.rar"
$LR_R7_FILE     = "GTAV_REAL_mod_by_LukeRoss_r7.rar"
$SEVENZIP_URL   = "https://www.7-zip.org/download.html"
$SEVENZIP_DL    = "https://7-zip.org/a/7z2501-x64.exe"
$KEY_FILE       = "RealVR.ini"   # root marker of the .rar; RealVR.asi is inside the asi\ subfolder
$MOTION_DRIVE_URL = "https://drive.google.com/file/d/1DiWVve3RK-FAD5awyo0RMHfe6nbZ8aBD/view"
$MOTION_FILES   = @("GTAVR.asi", "openvr_api.dll")

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " Grand Theft Auto V VR Installer" -ForegroundColor Cyan
    Write-Host " Luke Ross R.E.A.L. r7 - layered onto your own GTA V" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
}
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [XX] $t" -ForegroundColor Red }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Find-7Zip {
    # Registry first - the 7-Zip installer records its path here no
    # matter where it landed, so this catches installs the fixed
    # Program Files guesses miss.
    foreach ($key in @("HKLM:\SOFTWARE\7-Zip", "HKLM:\SOFTWARE\WOW6432Node\7-Zip", "HKCU:\SOFTWARE\7-Zip")) {
        try {
            $rp = (Get-ItemProperty -Path $key -ErrorAction Stop).Path
            if ($rp) { $exe = Join-Path $rp "7z.exe"; if (Test-Path $exe) { return $exe } }
        } catch {}
    }
    $candidates = @(
        "${env:ProgramFiles}\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
        "${env:LOCALAPPDATA}\Programs\7-Zip\7z.exe"
    )
    foreach ($p in $candidates) { if (Test-Path $p) { return $p } }
    $cmd = Get-Command "7z.exe" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

# Unpack a motion-overlay package (zip/rar/7z/folder, or a bare .asi/.dll)
# into $DestDir and return the folder to search. Downloads have no file
# extension, so type is sniffed from the leading magic bytes too.
function Expand-MotionPackage {
    param([string]$File, [string]$DestDir, $SevenZip)
    try { if (Test-Path $File -PathType Container) { return $File } } catch {}
    if (-not (Test-Path $File)) { return $null }
    $ext  = [System.IO.Path]::GetExtension($File).ToLower()
    $kind = ""
    if ($ext -in @(".zip", ".rar", ".7z", ".asi", ".dll")) {
        $kind = $ext.TrimStart(".")
    } else {
        try {
            $fs = [System.IO.File]::OpenRead($File); $buf = New-Object byte[] 6; [void]$fs.Read($buf, 0, 6); $fs.Close()
            if     ($buf[0] -eq 0x50 -and $buf[1] -eq 0x4B) { $kind = "zip" }
            elseif ($buf[0] -eq 0x52 -and $buf[1] -eq 0x61 -and $buf[2] -eq 0x72 -and $buf[3] -eq 0x21) { $kind = "rar" }
            elseif ($buf[0] -eq 0x37 -and $buf[1] -eq 0x7A) { $kind = "7z" }
        } catch {}
    }
    try {
        if ($kind -eq "zip") {
            $zp = $File
            if ($ext -ne ".zip") { $zp = "$File.zip"; Copy-Item $File $zp -Force }
            Expand-Archive -Path $zp -DestinationPath $DestDir -Force
            return $DestDir
        } elseif ($kind -eq "rar" -or $kind -eq "7z") {
            if ($SevenZip) { & $SevenZip x "$File" "-o$DestDir" -y | Out-Null; return $DestDir }
        } elseif ($kind -eq "asi" -or $kind -eq "dll") {
            Copy-Item $File -Destination $DestDir -Force; return $DestDir
        } else {
            if ($SevenZip) { & $SevenZip x "$File" "-o$DestDir" -y | Out-Null; return $DestDir }
        }
    } catch { Write-Warn "Could not open the package: $_" }
    return $null
}

# Drag the GTA V folder, GTA5.exe, or PlayGTAV.exe; resolve the
# game folder (the one containing GTA5.exe). Loops until valid or
# cancelled (empty input).
function Get-GtaFolder {
    while ($true) {
        Write-Host ""
        Write-Host " Drag your GTA V folder (or GTA5.exe / PlayGTAV.exe) onto" -ForegroundColor White
        Write-Host " this window and press Enter." -ForegroundColor White
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
        # A file was dragged - use its folder if GTA5.exe sits there.
        $dir = Split-Path -Parent $p
        if (Test-Path (Join-Path $dir $GAME_EXE)) { return $dir }
        Write-Warn "That file is not next to $GAME_EXE. Drag the GTA V folder or GTA5.exe."
    }
}

Write-Header
Write-Host " This layers the R.E.A.L. r7 VR mod onto your EXISTING," -ForegroundColor White
Write-Host " WORKING Grand Theft Auto V (Legacy) install." -ForegroundColor White
Write-Host ""
Write-Host " You PROVIDE YOUR OWN launchable copy of GTA V on build" -ForegroundColor Gray
Write-Host " $TARGET_VERSION. The current/latest game build does NOT" -ForegroundColor Gray
Write-Host " work with the mod. No game files are bundled or downloaded -" -ForegroundColor Gray
Write-Host " only the free Luke Ross mod is fetched at install time." -ForegroundColor Gray
Write-Host ""
Write-Host " NOT GTA V Enhanced (the 2025 release) - that is a different" -ForegroundColor Gray
Write-Host " game and is incompatible with this mod." -ForegroundColor Gray
Write-Host ""
$go = Read-Host " Continue? (Y/N)"
if ($go -notmatch '^(y|yes|j|ja)$') { Write-Info "Cancelled."; Pause-User "Press Enter to exit..."; exit 0 }

# ---- STEP 1: locate the user's GTA V ----
Write-Step 1 6 "Locating your GTA V install"
$gtaDir = Get-GtaFolder
if (-not $gtaDir) { Write-Info "No folder provided - cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
Write-OK "GTA V folder: $gtaDir"

# Soft version check - warn but never block (the user owns the copy).
$gtaExe = Join-Path $gtaDir $GAME_EXE
$ver = $null
try { $ver = (Get-Item $gtaExe -ErrorAction Stop).VersionInfo.ProductVersion } catch {}
if (-not $ver) { try { $ver = (Get-Item $gtaExe -ErrorAction Stop).VersionInfo.FileVersion } catch {} }
if ($ver) {
    if ($ver.Trim() -eq $TARGET_VERSION) {
        Write-OK "Detected build $ver (matches the required $TARGET_VERSION)."
    } else {
        Write-Warn "Detected build $ver - the mod targets $TARGET_VERSION."
        Write-Host "      The mod may not work on this build. Continuing anyway." -ForegroundColor Gray
    }
} else {
    Write-Warn "Could not read the GTA5.exe version - continuing anyway."
}

# ---- STEP 2: 7-Zip (the mod ships as .rar) ----
Write-Step 2 6 "Checking for 7-Zip"
$sevenZip = Find-7Zip
$manualExtract = $false
if ($sevenZip) {
    Write-OK "7-Zip found: $sevenZip"
} else {
    Write-Warn "7-Zip not found - it is needed to extract the .rar mod"
    Write-Host "      (PowerShell cannot open .rar on its own)." -ForegroundColor Gray
    $ans = Read-Host "  Download and install 7-Zip automatically now? (Y/N)"
    if ($ans -match '^(y|yes|j|ja)$') {
        $inst = Join-Path $env:TEMP "7zip-setup.exe"
        $d = Invoke-DownloadOrFallback -Url $SEVENZIP_DL -Destination $inst -Label "7-Zip installer" `
                -ManualUrl $SEVENZIP_URL `
                -Instructions "Install 7-Zip from 7-zip.org, then re-run this installer." `
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
        Write-Warn "No 7-Zip available - the installer will guide a manual extract."
        try { Start-Process $SEVENZIP_URL } catch { Write-Warn "Open manually: $SEVENZIP_URL" }
        $manualExtract = $true
    }
}

# ---- STEP 3: download the mod ----
Write-Step 3 6 "Downloading $MOD_NAME"
$rar = Join-Path $env:TEMP $LR_R7_FILE
$dl = Invoke-DownloadOrFallback -Url $LR_R7_URL -Destination $rar -Label "$MOD_NAME (.rar)" `
        -ManualUrl $LR_R7_URL `
        -Instructions "Download $LR_R7_FILE manually, then drag it here when asked." `
        -SkipMessage "Skipped - without the mod .rar the install cannot continue."
if ([string]$dl -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$dl -eq "skip") { Write-Fail "No mod archive - aborting."; Pause-User "Press Enter to exit..."; exit 1 }
if (-not (Test-Path $rar)) {
    # Manual fallback: let the user point us at a .rar they downloaded.
    Write-Warn "Mod archive not found at $rar."
    while (-not (Test-Path $rar)) {
        $alt = (Read-Host " Drag the downloaded $LR_R7_FILE here (or empty to cancel)").Trim().Trim('"')
        if (-not $alt) { Write-Fail "No archive - aborting."; Pause-User "Press Enter to exit..."; exit 1 }
        if (Test-Path $alt) { $rar = $alt; break }
        Write-Warn "Not found: $alt"
    }
}
Write-OK "Mod archive ready."

# ---- STEP 4: extract the mod into the game folder ----
Write-Step 4 6 "Installing the mod into $gtaDir"
$installedOk = $false
if (-not $manualExtract -and $sevenZip) {
    $xtemp = Join-Path $env:TEMP ("gtavr_r7_" + [System.IO.Path]::GetRandomFileName())
    try { New-Item -ItemType Directory -Force -Path $xtemp | Out-Null } catch {}
    try {
        & $sevenZip x "$rar" "-o$xtemp" -y | Out-Null
        # The .rar may unpack flat OR inside a wrapper folder - anchor on
        # RealVR.ini (a root-level file in the .rar; RealVR.asi sits in the
        # asi\ subfolder) and copy that whole root into the game folder.
        $keyHit = Get-ChildItem -Path $xtemp -Filter $KEY_FILE -Recurse -ErrorAction SilentlyContinue | Sort-Object { $_.FullName.Length } | Select-Object -First 1
        if ($keyHit) {
            $modRoot = Split-Path -Parent $keyHit.FullName
            # Copy EVERY mod file (RealVR.asi, RealConfig.bat, RealRepo\,
            # ScriptHookV.dll, dinput8.dll, ...) into the game folder,
            # recreating subfolders and never aborting on a single item.
            $copied = 0
            foreach ($item in (Get-ChildItem -Path $modRoot -Recurse -Force -ErrorAction SilentlyContinue)) {
                $rel  = $item.FullName.Substring($modRoot.Length).TrimStart('\','/')
                if (-not $rel) { continue }
                $dest = Join-Path $gtaDir $rel
                try {
                    if ($item.PSIsContainer) {
                        if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
                    } else {
                        $destDir = Split-Path -Parent $dest
                        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
                        Copy-Item -Path $item.FullName -Destination $dest -Force
                        $copied++
                    }
                } catch { Write-Warn "Could not copy $rel" }
            }
            Write-Host "  Copied $copied mod files into the game folder." -ForegroundColor Gray
            if (Test-Path (Join-Path $gtaDir $KEY_FILE)) { $installedOk = $true }
        }
    } catch { Write-Warn "7-Zip extraction failed: $_" }
    try { Remove-Item $xtemp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}
if (-not $installedOk) {
    # Fallback path: 7-Zip missing or extraction failed - guide a
    # manual extract, then verify.
    Write-Host "  Please extract the contents of:" -ForegroundColor White
    Write-Host "    $rar" -ForegroundColor Gray
    Write-Host "  directly into your GTA V folder:" -ForegroundColor White
    Write-Host "    $gtaDir" -ForegroundColor Gray
    Write-Host "  (so that RealVR.ini, ScriptHookV.dll and the asi folder" -ForegroundColor White
    Write-Host "  end up next to $GAME_EXE)." -ForegroundColor White
    try { Start-Process (Split-Path -Parent $rar) } catch {}
    try { Start-Process $gtaDir } catch {}
    Pause-User "Press Enter once you have extracted the mod into the game folder..."
    if (Test-Path (Join-Path $gtaDir $KEY_FILE)) { $installedOk = $true }
}
if ($installedOk) {
    Write-OK "Mod installed - RealVR.ini is in place."
    if (Test-Path (Join-Path $gtaDir "asi\RealVR.asi")) {
        Write-OK "VR plugin in place - asi\RealVR.asi."
    } else {
        Write-Warn "asi\RealVR.asi is missing - make sure the WHOLE .rar was extracted (incl. the asi folder)."
    }
} else {
    Write-Warn "RealVR.ini not found in $gtaDir - the mod may not be installed correctly."
}

# RealVR.ini: prefer SteamVR/OpenVR (VRAPI = 2) so it works without
# the user editing the .ini by hand. Only touch an existing key.
$ini = Join-Path $gtaDir "RealVR.ini"
if (Test-Path $ini) {
    try {
        $lines = Get-Content $ini
        if ($lines -match '^\s*VRAPI\s*=') {
            $lines = $lines -replace '^\s*VRAPI\s*=.*', 'VRAPI=2'
            Set-Content -Path $ini -Value $lines -Encoding ASCII -Force
            Write-OK "Set VRAPI=2 (SteamVR / OpenVR) in RealVR.ini."
        }
    } catch { Write-Warn "Could not update RealVR.ini - set VRAPI=2 manually if needed." }
}

# RealConfig.bat (shipped inside the mod, now in the game folder) applies
# VR-compatible graphics settings. It must run with the game closed.
$realConfig = Join-Path $gtaDir "RealConfig.bat"
if (Test-Path $realConfig) {
    Write-Host ""
    Write-Host "  RealConfig.bat applies VR-compatible graphics settings." -ForegroundColor White
    Write-Host "  Before running it:" -ForegroundColor White
    Write-Host "    - GTA V must NOT be running." -ForegroundColor Gray
    Write-Host '    - Steam users: in the game Properties, uncheck' -ForegroundColor Gray
    Write-Host '      "Use Desktop Game Theatre while SteamVR is active".' -ForegroundColor Gray
    Write-Host "  It backs up settings.xml as settings_ori.xml and applies a" -ForegroundColor Gray
    Write-Host "  template. At the prompt pick Low / Medium / High for your PC." -ForegroundColor Gray
    Write-Host "  Do NOT set settings.xml to read-only afterwards." -ForegroundColor Gray
    Write-Host ""
    $rc = Read-Host "  Run RealConfig.bat now? (Y/N)"
    if ($rc -match '^(y|yes|j|ja)$') {
        try { Start-Process "cmd.exe" -ArgumentList "/c", "`"$realConfig`"" -WorkingDirectory $gtaDir -Wait } catch { Write-Warn "Could not run RealConfig.bat - run it manually from the game folder." }
    } else {
        Write-Info "Skipped - run RealConfig.bat from the game folder anytime (game closed)."
    }
}

# ---- STEP 5: optional motion controls (GTAVR overlay) ----
Write-Step 5 6 "Motion controls (optional)"
Write-Host "  R.E.A.L. is gamepad-based. The community GTAVR overlay adds" -ForegroundColor White
Write-Host "  motion controllers (hand-aimed weapons etc.) on top of it." -ForegroundColor White
Write-Host ""
$mc = Read-Host "  Add the GTAVR motion-controls overlay? (Y/N)"
if ($mc -match '^(y|yes|j|ja)$') {
    $mtemp = Join-Path $env:TEMP ("gtavr_mc_" + [System.IO.Path]::GetRandomFileName())
    try { New-Item -ItemType Directory -Force -Path $mtemp | Out-Null } catch {}
    # The package lives on Google Drive, which cannot be fetched
    # programmatically (the virus-scan interstitial blocks scripted
    # downloads). Open the download page so you can save it in your
    # browser, then drag the downloaded package back here.
    Write-Host "  Opening the GTAVR download page in your browser:" -ForegroundColor Gray
    Write-Host "      $MOTION_DRIVE_URL" -ForegroundColor Gray
    try { Start-Process $MOTION_DRIVE_URL } catch { Write-Warn "Open manually: $MOTION_DRIVE_URL" }
    $src = $null
    $pkg = $null
    while ($true) {
        $raw = (Read-Host "  Drag the downloaded GTAVR package (zip/rar/folder) here, or leave empty to skip").Trim().Trim('"').Trim("'").Trim()
        if (-not $raw) { break }
        if (Test-Path $raw) { $pkg = $raw; break }
        Write-Warn "Not found: $raw"
    }
    if ($pkg) { $src = Expand-MotionPackage -File $pkg -DestDir $mtemp -SevenZip $sevenZip }
    if ($src) {
        foreach ($f in $MOTION_FILES) {
            $hit = Get-ChildItem -Path $src -Filter $f -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hit) { try { Copy-Item $hit.FullName -Destination (Join-Path $gtaDir $f) -Force } catch {} }
        }
    }
    try { Remove-Item $mtemp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    if (Test-Path (Join-Path $gtaDir "GTAVR.asi")) {
        Write-OK "Motion controls installed - GTAVR.asi is in place."
    } else {
        Write-Warn "GTAVR.asi not found - motion controls not added. Gamepad still works."
    }
} else {
    Write-Info "Skipped motion controls - gamepad play is ready."
}

# ---- STEP 6: shortcut + records ----
Write-Step 6 6 "Finishing setup"
$launchPath = Join-Path $gtaDir $LAUNCH_EXE
if (-not (Test-Path $launchPath)) { $launchPath = $gtaExe }   # cracked/standalone copies may lack PlayGTAV.exe
try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "Grand Theft Auto V VR.lnk"
    $sc = New-DesktopShortcut -LnkPath $lnk -TargetPath $launchPath -WorkingDir $gtaDir -IconPath $launchPath
    Write-OK "Desktop shortcut created: Grand Theft Auto V VR"
} catch {
    Write-Warn "Could not create the desktop shortcut. Launch $LAUNCH_EXE from $gtaDir."
}
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gtaDir -Encoding UTF8 -Force } catch {}
try { Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value $launchPath -Encoding UTF8 -Force } catch {}
try { Remove-Item $rar -Force -ErrorAction SilentlyContinue } catch {}

# ---- How to play ----
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " HOW TO PLAY" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " 1) Start SteamVR first, then launch the game (desktop" -ForegroundColor White
Write-Host "    shortcut, or however you normally start GTA V)." -ForegroundColor White
Write-Host " 2) Use a gamepad, or motion controllers if you added GTAVR." -ForegroundColor White
Write-Host " 3) Quickly shake your head to recenter the view." -ForegroundColor White
Write-Host " 4) Hotkeys are off at start - press F11 to turn them on" -ForegroundColor White
Write-Host "    (full hotkey list is in README_GTAVR.md)." -ForegroundColor White
if (Test-Path (Join-Path $gtaDir "GTAVR.asi")) {
    Write-Host ""
    Write-Host " Motion controls (the GTAVR overlay you added):" -ForegroundColor White
    Write-Host "   - The game starts in R.E.A.L. head-aim mode." -ForegroundColor White
    Write-Host "   - NUMPAD 0 opens the GTAVR motion-controls overlay." -ForegroundColor White
    Write-Host "   - NUMPAD 8 activates motion controls." -ForegroundColor White
    Write-Host "   - Back to pure R.E.A.L.: press F11, then K (not 0)." -ForegroundColor Gray
}
Write-Host ""
Write-Host " Keep auto-updates OFF for GTA V so the build stays at" -ForegroundColor Gray
Write-Host " $TARGET_VERSION. If your build differs, you may need a" -ForegroundColor Gray
Write-Host " matching ScriptHookV.dll from Alexander Blade's page." -ForegroundColor Gray
Pause-User "Press Enter once you have read the steps above..."

Write-Host ""
Write-Host " Pull off the heist, outrun the stars, and own the streets of Los Santos." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
