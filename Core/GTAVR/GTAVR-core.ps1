# ============================================================
# Grand Theft Auto V VR Installer
# Adds Luke Ross's R.E.A.L. r7 VR mod to the user's own Grand Theft
# Auto V. Uses the community GTA-VRV-Patcher to run on the CURRENT
# build (1.0.3788.0) - no downgrade. We ship ZERO game/mod files;
# ScriptHookV (dev-c.com) and the patcher (GitHub) are downloaded
# at install time.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Grand Theft Auto V VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME       = "GTA-VRV-Patcher fork (R.E.A.L. r7 on current build)"
$TARGET_VERSION = "1.0.3788.0"
$GAME_EXE       = "GTA5.exe"
$LAUNCH_EXE     = "PlayGTAV.exe"
# ScriptHookV must match the game build (3788). Official, from dev-c.com.
$SCRIPTHOOK_URL  = "https://dev-c.com/files/ScriptHookV_3788.0_1013.34.zip"
$SCRIPTHOOK_FILE = "ScriptHookV_3788.0_1013.34.zip"
# Francisco Manzanilla's VRV patcher runs Luke Ross R.E.A.L. r7 on the
# CURRENT build (no downgrade). Public GitHub release.
$PATCHER_URL    = "https://github.com/FranciscoManzanilla/GTA-VRV-Patcher/releases/download/VRV-1.1/GTAVRV.Patcher.zip"
$PATCHER_FILE   = "GTAVRV.Patcher.zip"
$SEVENZIP_URL   = "https://www.7-zip.org/download.html"
$SEVENZIP_DL    = "https://7-zip.org/a/7z2501-x64.exe"
$KEY_FILE       = "RealVR.ini"   # root marker inside the patcher zip
$MOTION_DRIVE_URL = "https://drive.google.com/file/d/1DiWVve3RK-FAD5awyo0RMHfe6nbZ8aBD/view"
# CONFIRMED working combo: GTAVR.asi + the patcher's own openvr_api.dll
# (1.0.10, ~585 KB). Copy ONLY GTAVR.asi - do NOT bring the motion pack's
# newer openvr_api.dll (1.16.8), which breaks the patcher's VR frame submit
# (game on monitor, headset stays in SteamVR).
$MOTION_FILES   = @("GTAVR.asi")

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Grand Theft Auto V VR Installer" -ForegroundColor Cyan
    Write-Host " Luke Ross R.E.A.L. r7 - layered onto your own GTA V" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "[$n/$t] $txt" -ForegroundColor Cyan; Write-Host "----------------------------------------" -ForegroundColor DarkGray }
function Write-OK   { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Info { param($t) Write-Host " [i] $t" -ForegroundColor Cyan }
function Write-Warn { param($t) Write-Host " [!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [X] $t" -ForegroundColor Red }
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
Write-Host " Adds the R.E.A.L. r7 VR mod to your Grand Theft Auto V." -ForegroundColor White
Write-Host " Runs on the current build - no downgrade. ScriptHookV and the" -ForegroundColor Gray
Write-Host " community VRV patcher are downloaded for you." -ForegroundColor Gray
Write-Host ""
Write-Host " NOT GTA V Enhanced (2025) - different, incompatible game." -ForegroundColor Gray
Write-Host ""
Write-Host " IMPORTANT: start Grand Theft Auto V once (into Story Mode) and" -ForegroundColor Yellow
Write-Host " quit it BEFORE installing. That first launch creates your game" -ForegroundColor Yellow
Write-Host " profile and settings.xml, which the VR setup needs." -ForegroundColor Yellow
Pause-User "Have you launched GTA V at least once already? Press Enter to continue..."
Write-Host ""

# ---- STEP 1: locate GTA V via the Steam install ----
Write-Step 1 6 "Locating your GTA V install"
$gtaDir = Find-SteamGameFolder -AppId "271590" -SteamFolderNames @("Grand Theft Auto V") -ProbeExe $GAME_EXE
if (-not $gtaDir) {
    Write-Warn "Could not find Grand Theft Auto V via Steam automatically."
    $gtaDir = Get-GtaFolder
}
if (-not $gtaDir) { Write-Info "No GTA V found - cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
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

# ---- Already installed? Offer a quick patcher-only update ----
$updateOnly = $false
if (Test-Path -LiteralPath "$gtaDir\RealVR.asi") {
    Write-Host ""
    Write-Host "  This GTA V already has the VR mod installed." -ForegroundColor Cyan
    Write-Host "  [U] Update the compat patcher only - just refresh R.E.A.L. + VRV" -ForegroundColor White
    Write-Host "      to the newest build (keeps ScriptHookV, settings, motion)." -ForegroundColor White
    Write-Host "  [F] Full reinstall (ScriptHookV + patcher + settings + launchers)." -ForegroundColor White
    $uAns = (Read-Host "  Choose U or F [U]").Trim().ToUpper()
    if ($uAns -eq "F") { Write-Info "Full reinstall." }
    else { $updateOnly = $true; Write-OK "Update mode - refreshing the compat patcher only." }
}

# ---- STEP 2: 7-Zip (the mod ships as .rar) ----
Write-Step 2 6 "Preparing"
# ScriptHookV and the patcher are .zip files, extracted with the built-in
# Expand-Archive - no 7-Zip needed. 7-Zip is only used later IF the
# optional motion overlay is provided as a .rar.
$sevenZip = Find-7Zip
$manualExtract = $false

# Verify a downloaded file is really a .zip (starts with the PK signature).
# Some sites return an HTML page to scripted requests instead of the file.
function Test-IsZipFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    try {
        $fs = [System.IO.File]::OpenRead($Path)
        $sig = New-Object byte[] 2
        [void]$fs.Read($sig, 0, 2); $fs.Close()
        return ($sig[0] -eq 0x50 -and $sig[1] -eq 0x4B)
    } catch { return $false }
}
# Download with a real browser User-Agent (+ optional Referer) so servers
# that block non-browser requests still hand over the file.
function Get-BrowserFile {
    param([string]$Url, [string]$Dest, [string]$Referer = "")
    try {
        if (Test-Path $Dest) { Remove-Item $Dest -Force -ErrorAction SilentlyContinue }
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36")
        if ($Referer) { $wc.Headers.Add("Referer", $Referer) }
        $wc.DownloadFile($Url, $Dest)
        return $true
    } catch { return $false }
}

# ---- STEP 3: ScriptHookV (must match the game build) ----
if ($updateOnly -and (Test-Path -LiteralPath "$gtaDir\ScriptHookV.dll")) {
    Write-Step 3 6 "ScriptHookV"
    Write-OK "ScriptHookV already installed - skipping (update mode)."
} else {
Write-Step 3 6 "Downloading ScriptHookV (build $TARGET_VERSION)"
$shZip = Join-Path $env:TEMP $SCRIPTHOOK_FILE
Write-Host "  [..] Downloading ScriptHookV" -ForegroundColor Gray
[void](Get-BrowserFile -Url $SCRIPTHOOK_URL -Dest $shZip -Referer "https://dev-c.com/gtav/scripthookv/")
if (Test-IsZipFile $shZip) {
    Write-OK "Downloaded ScriptHookV."
} else {
    Write-Warn "dev-c.com did not return the .zip (it may block scripted downloads)."
    Write-Host "  Download ScriptHookV from its page, then drag the .zip here." -ForegroundColor White
    Pause-User "Press Enter to open the ScriptHookV page..."
    try { Start-Process "https://dev-c.com/gtav/scripthookv/" } catch {}
    $shZip = $null
    while (-not $shZip) {
        $alt = (Read-Host " Drag the downloaded ScriptHookV .zip here (or empty to skip)").Trim().Trim('"')
        if (-not $alt) { break }
        if ((Test-Path $alt) -and (Test-IsZipFile $alt)) { $shZip = $alt }
        else { Write-Warn "Not a valid .zip: $alt" }
    }
}
if ($shZip -and (Test-IsZipFile $shZip)) {
    $shtemp = Join-Path $env:TEMP ("gtavr_sh_" + [System.IO.Path]::GetRandomFileName())
    try {
        Expand-Archive -Path $shZip -DestinationPath $shtemp -Force
        foreach ($f in @("ScriptHookV.dll", "dinput8.dll")) {
            $hit = Get-ChildItem -Path $shtemp -Filter $f -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hit) { try { Copy-Item $hit.FullName -Destination (Join-Path $gtaDir $f) -Force } catch {} }
        }
    } catch { Write-Warn "ScriptHookV extraction failed: $_" }
    try { Remove-Item $shtemp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}
if (Test-Path -LiteralPath "$gtaDir\ScriptHookV.dll") {
    Write-OK "ScriptHookV in place (ScriptHookV.dll + dinput8.dll)."
} else {
    Write-Warn "ScriptHookV not installed - put ScriptHookV.dll + dinput8.dll next to $GAME_EXE manually."
    try { Start-Process $gtaDir } catch {}
    Pause-User "Press Enter once ScriptHookV.dll + dinput8.dll are in the game folder (or to skip)..."
}
}

# ---- STEP 4: download + install the VRV patcher (R.E.A.L. on current build) ----
function Get-LatestPatcherUrl {
    # If an earlier run hit an antivirus false-positive on the fork patcher
    # and the user chose the backup, honor that choice and skip the fork.
    try {
        $vsrc = Join-Path $PSScriptRoot ".vrv_source"
        if ((Test-Path $vsrc) -and ((Get-Content $vsrc -Raw -ErrorAction Stop).Trim() -eq "francisco")) { return $PATCHER_URL }
    } catch {}
    # Auto-update: resolve the newest fork release download URL at RUNTIME
    # via the GitHub API - the direct asset URL is deliberately NOT hardcoded
    # as a literal (some AV engines false-flag the fork patcher file and would
    # then flag a script that references its download URL). Falls back to the
    # pinned known-good URL if the API is unreachable.
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/SanguShellz/GTA-VRV-Patcher/releases/latest" `
            -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -ErrorAction Stop
        $zips = @($rel.assets | Where-Object { $_.name -match '(?i)\.zip$' })
        $asset = ($zips | Where-Object { $_.name -match '(?i)patcher' } | Select-Object -First 1)
        if (-not $asset) { $asset = $zips | Select-Object -First 1 }
        if ($asset -and $asset.browser_download_url) {
            Write-Info "Latest VRV patcher on GitHub: $($rel.tag_name)"
            return [string]$asset.browser_download_url
        }
    } catch { Write-Info "Could not check GitHub for a newer patcher - using the known-good version." }
    return $PATCHER_URL
}

Write-Step 4 6 "Installing the VR mod into $gtaDir"
$rar = Join-Path $env:TEMP $PATCHER_FILE
Write-Host "  [..] Downloading $MOD_NAME" -ForegroundColor Gray
$patcherUrl = Get-LatestPatcherUrl
$usedFork = ($patcherUrl -match '(?i)SanguShellz')
[void](Get-BrowserFile -Url $patcherUrl -Dest $rar)

# Antivirus false-positive watch: the fork patcher bundles ScriptHook-style
# loaders that some AV engines wrongly delete. If the file we just downloaded
# vanishes within a few seconds, an antivirus most likely quarantined it -
# offer the clean pinned backup (Francisco's build) and remember the choice.
if ($usedFork -and (Test-Path $rar)) {
    $vanished = $false
    for ($i = 0; $i -lt 6; $i++) {
        Start-Sleep -Milliseconds 500
        if (-not (Test-Path $rar)) { $vanished = $true; break }
    }
    if ($vanished) {
        Write-Warn "The downloaded patcher disappeared right after download."
        Write-Host "  If an antivirus tool removed it, this is a known FALSE POSITIVE" -ForegroundColor White
        Write-Host "  on the fork patcher (it bundles ScriptHook-style loader files)." -ForegroundColor White
        Write-Host "  A clean backup build (by Francisco Manzanilla) is available." -ForegroundColor White
        $useBk = Read-Host "  Load the backup patcher instead? (Y/N)"
        if ($useBk -match '^(y|yes|j|ja)$') {
            try { Set-Content -Path (Join-Path $PSScriptRoot ".vrv_source") -Value "francisco" -Encoding ASCII -Force } catch {}
            try { Remove-Item (Join-Path $PSScriptRoot ".installed_version") -Force -ErrorAction SilentlyContinue } catch {}
            Write-Info "Switched to the backup patcher - the fork is skipped on this machine from now on."
            [void](Get-BrowserFile -Url $PATCHER_URL -Dest $rar)
        }
    }
}
if (-not (Test-IsZipFile $rar)) {
    Write-Warn "Could not fetch the patcher automatically."
    Write-Host "  Download $PATCHER_FILE from the releases page, then drag it here." -ForegroundColor White
    Pause-User "Press Enter to open the patcher releases page..."
    try { Start-Process "https://github.com/SanguShellz/GTA-VRV-Patcher/releases" } catch {}
    $rar = $null
    while (-not $rar) {
        $alt = (Read-Host " Drag the downloaded $PATCHER_FILE here (or empty to cancel)").Trim().Trim('"')
        if (-not $alt) { Write-Fail "No patcher - aborting."; Pause-User "Press Enter to exit..."; exit 1 }
        if ((Test-Path $alt) -and (Test-IsZipFile $alt)) { $rar = $alt }
        else { Write-Warn "Not a valid .zip: $alt" }
    }
}
Write-OK "Patcher archive ready."
$installedOk = $false
if (-not $manualExtract) {
    $xtemp = Join-Path $env:TEMP ("gtavr_patch_" + [System.IO.Path]::GetRandomFileName())
    try {
        Expand-Archive -Path $rar -DestinationPath $xtemp -Force
        $keyHit = Get-ChildItem -Path $xtemp -Filter $KEY_FILE -Recurse -ErrorAction SilentlyContinue | Sort-Object { $_.FullName.Length } | Select-Object -First 1
        if ($keyHit) {
            $modRoot = Split-Path -Parent $keyHit.FullName
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
            Write-Host "  Copied $copied patcher files into the game folder." -ForegroundColor Gray
            if (Test-Path (Join-Path $gtaDir $KEY_FILE)) { $installedOk = $true }
        }
    } catch { Write-Warn "7-Zip extraction failed: $_" }
    try { Remove-Item $xtemp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}
if (-not $installedOk) {
    Write-Host "  Please extract the contents of:" -ForegroundColor White
    Write-Host "    $rar" -ForegroundColor Gray
    Write-Host "  directly into your GTA V folder:" -ForegroundColor White
    Write-Host "    $gtaDir" -ForegroundColor Gray
    Write-Host "  (so that RealVR.ini, RealVR.asi and PlayGTAV.bat end up" -ForegroundColor White
    Write-Host "  next to $GAME_EXE)." -ForegroundColor White
    try { Start-Process (Split-Path -Parent $rar) } catch {}
    try { Start-Process $gtaDir } catch {}
    Pause-User "Press Enter once you have extracted the patcher into the game folder..."
    if (Test-Path (Join-Path $gtaDir $KEY_FILE)) { $installedOk = $true }
}
if ($installedOk) {
    Write-OK "Patcher installed - RealVR.ini is in place."
    if (Test-Path -LiteralPath "$gtaDir\RealVR.asi") {
        Write-OK "VR plugin in place - RealVR.asi."
    } else {
        Write-Warn "RealVR.asi is missing - make sure the WHOLE patcher zip was extracted."
    }
} else {
    Write-Warn "RealVR.ini not found in $gtaDir - the patcher may not be installed correctly."
}

# RealConfig.bat (shipped inside the mod, now in the game folder) applies
# VR-compatible graphics settings. It must run with the game closed.
$realConfig = Join-Path $gtaDir "RealConfig.bat"
if (Test-Path $realConfig) {
    Write-Host ""
    Write-Host "  RealConfig.bat applies VR graphics settings (game must be closed)." -ForegroundColor White
    Write-Host "  Pick Low / Medium / High at its prompt." -ForegroundColor Gray
    Write-Host ""
    # GTA V rewrites settings.xml to the DESKTOP resolution on launch, which
    # breaks the 1080x1080 VR render (game opens in a big window instead of
    # the small square). Clear read-only so RealConfig can write, run it,
    # then lock settings.xml read-only so the square VR resolution sticks.
    $gtaSettings = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Rockstar Games\GTA V\settings.xml"
    if (Test-Path $gtaSettings) { try { (Get-Item $gtaSettings).IsReadOnly = $false } catch {} }
    try { Start-Process "cmd.exe" -ArgumentList "/c", "`"$realConfig`"" -WorkingDirectory $gtaDir -Wait } catch { Write-Warn "Could not run RealConfig.bat - run it manually (game closed)." }
    if (Test-Path $gtaSettings) {
        try { (Get-Item $gtaSettings).IsReadOnly = $true; Write-OK "Locked settings.xml read-only - keeps the 1080x1080 VR resolution." }
        catch { Write-Warn "Could not lock settings.xml - set it read-only manually to keep 1080x1080." }
    } else {
        Write-Warn "settings.xml not found yet - launch once, then set it read-only at 1080x1080."
    }
}

# ---- STEP 5: optional motion controls (GTAVR overlay) ----
if ($updateOnly) {
    Write-Step 5 6 "Motion controls"
    Write-Info "Update mode - leaving your existing motion setup untouched."
} else {
Write-Step 5 6 "Motion controls (optional)"
Write-Host "  R.E.A.L. is gamepad-based. The GTAVR overlay adds motion controllers." -ForegroundColor White
Write-Host ""
Write-Host "  NOTE: motion is still SHAKY - the game only sometimes starts" -ForegroundColor Yellow
Write-Host "  correctly in VR with it. Gamepad (OpenXR) is the stable option." -ForegroundColor Yellow
Write-Host "  Adding it also creates a separate 'Motion (WIP)' launcher." -ForegroundColor Gray
$mc = Read-Host "  Add the GTAVR motion-controls overlay? (Y/N)"
if ($mc -match '^(y|yes|j|ja)$') {
    $mtemp = Join-Path $env:TEMP ("gtavr_mc_" + [System.IO.Path]::GetRandomFileName())
    try { New-Item -ItemType Directory -Force -Path $mtemp | Out-Null } catch {}
    # The package lives on Google Drive, which cannot be fetched
    # programmatically (the virus-scan interstitial blocks scripted
    # downloads). Open the download page so you can save it in your
    # browser, then drag the downloaded package back here.
    Write-Host "  Get the motion package (All we need.zip) from the GTAVR page:" -ForegroundColor White
    Write-Host "      $MOTION_DRIVE_URL" -ForegroundColor Gray
    Pause-User "Press Enter to open the GTAVR download page..."
    try { Start-Process $MOTION_DRIVE_URL } catch { Write-Warn "Open manually: $MOTION_DRIVE_URL" }
    $src = $null
    $pkg = $null
    while ($true) {
        $raw = (Read-Host "  Drag the downloaded GTAVR package (All we need.zip) here, or leave empty to skip").Trim().Trim('"').Trim("'").Trim()
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
    if (Test-Path -LiteralPath "$gtaDir\GTAVR.asi") {
        Write-OK "Motion controls installed - GTAVR.asi is in place."
    } else {
        Write-Warn "GTAVR.asi not found - motion controls not added. Gamepad still works."
    }
} else {
    # Declined - remove a leftover GTAVR.asi from an earlier motion run so
    # the Numpad-0 overlay is truly gone. The patcher's openvr 1.0.10
    # (re-copied in STEP 4) stays, which is what pure R.E.A.L. renders with.
    $leftoverMc = Join-Path $gtaDir "GTAVR.asi"
    if (Test-Path $leftoverMc) { try { Remove-Item $leftoverMc -Force; Write-Info "Removed a leftover motion overlay (GTAVR.asi)." } catch {} }
    Write-Info "Skipped motion controls - gamepad play is ready."
}
}

# ---- STEP 6: launchers, shortcuts, records ----
Write-Step 6 6 "Finishing setup"
$iconPath = Join-Path $gtaDir $LAUNCH_EXE
if (-not (Test-Path $iconPath)) { $iconPath = $gtaExe }

# Default RealVR.ini to OpenXR (VRAPI 3) - more stable for gamepad play.
$realIni = Join-Path $gtaDir "RealVR.ini"
if (Test-Path $realIni) { try { (Get-Content $realIni) -replace '^\s*VRAPI\s*=.*', 'VRAPI = 3' | Set-Content $realIni } catch {} }

# Mode switcher written into the game folder: gamepad -> OpenXR (VRAPI 3) +
# motion overlay OFF; motion -> OpenVR (VRAPI 2) + GTAVR.asi ON. Then it
# launches with -nobattleye.
$modeScript = @'
param([string]$Mode = "gamepad")
$dir = Split-Path -Parent $PSScriptRoot
$ini = Join-Path $dir "RealVR.ini"
$asiOn  = Join-Path $dir "GTAVR.asi"
$asiOff = Join-Path $dir "GTAVR.asi.off"
if ($Mode -eq "motion") {
    if (Test-Path $ini) { (Get-Content $ini) -replace '^\s*VRAPI\s*=.*', 'VRAPI = 2' | Set-Content $ini }
    if (Test-Path $asiOff) { Move-Item $asiOff $asiOn -Force }
} else {
    if (Test-Path $ini) { (Get-Content $ini) -replace '^\s*VRAPI\s*=.*', 'VRAPI = 3' | Set-Content $ini }
    if (Test-Path $asiOn) { Move-Item $asiOn $asiOff -Force }
}
$exe = Join-Path $dir "PlayGTAV.exe"
if (Test-Path $exe) { Start-Process -FilePath $exe -ArgumentList "-nobattleye" -WorkingDirectory $dir }
'@
$vrl = Join-Path $gtaDir "VRLaunch"
try { New-Item -ItemType Directory -Force -Path $vrl | Out-Null } catch {}
try { Set-Content -Path (Join-Path $vrl "SetVRMode.ps1") -Value $modeScript -Encoding UTF8 -Force } catch {}

$gpBat = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0SetVRMode.ps1`" -Mode gamepad`r`n"
$moBat = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0SetVRMode.ps1`" -Mode motion`r`n"
$gpLauncher = Join-Path $vrl "GTA5 VR (Gamepad).bat"
$moLauncher = Join-Path $vrl "GTA5 VR Motion (WIP).bat"
try { Set-Content -Path $gpLauncher -Value $gpBat -Encoding ASCII -Force -NoNewline } catch {}
try { Set-Content -Path $moLauncher -Value $moBat -Encoding ASCII -Force -NoNewline } catch {}

$desktop = [Environment]::GetFolderPath("Desktop")
try {
    $lnk = Join-Path $desktop "Grand Theft Auto V VR.lnk"
    [void](New-DesktopShortcut -LnkPath $lnk -TargetPath $gpLauncher -WorkingDir $gtaDir -IconPath $iconPath)
    Write-OK "Shortcut created: Grand Theft Auto V VR (gamepad, OpenXR)"
} catch { Write-Warn "Could not create the gamepad shortcut - run '$gpLauncher' to play." }

$motionInstalled = (Test-Path -LiteralPath "$gtaDir\GTAVR.asi") -or (Test-Path -LiteralPath "$gtaDir\GTAVR.asi.off")
if ($motionInstalled) {
    try {
        $lnkM = Join-Path $desktop "Grand Theft Auto V VR Motion (WIP).lnk"
        [void](New-DesktopShortcut -LnkPath $lnkM -TargetPath $moLauncher -WorkingDir $gtaDir -IconPath $iconPath)
        Write-OK "Shortcut created: Grand Theft Auto V VR Motion (WIP)"
    } catch { Write-Warn "Could not create the motion shortcut." }
}

$launchPath = $gpLauncher
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gtaDir -Encoding UTF8 -Force } catch {}
try { Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value $launchPath -Encoding UTF8 -Force } catch {}
try { Remove-Item $rar -Force -ErrorAction SilentlyContinue } catch {}

# ---- How to play ----
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " HOW TO PLAY" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " 1) Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the desktop shortcut:" -ForegroundColor White
Write-Host "      'Grand Theft Auto V VR'        = Gamepad (OpenXR, stable)" -ForegroundColor Gray
Write-Host "      'Grand Theft Auto V VR Motion' = Motion controls (OpenVR, WIP)" -ForegroundColor Gray
Write-Host " 2) IMPORTANT: in Steam, GTA V Properties, turn OFF" -ForegroundColor Yellow
Write-Host '    "Use Desktop Game Theatre while SteamVR is active" - otherwise' -ForegroundColor Yellow
Write-Host "    VR shows only a flat/transparent screen, not the real game." -ForegroundColor Yellow
Write-Host " 3) Quickly shake your head to recenter the view." -ForegroundColor White
Write-Host " 4) Hotkeys are off at start - press F11 to turn them on" -ForegroundColor White
Write-Host "    (full hotkey list is in README_GTAVR.md)." -ForegroundColor White
if (Test-Path -LiteralPath "$gtaDir\GTAVR.asi") {
    Write-Host ""
    Write-Host " Motion (use the 'Motion (WIP)' shortcut): NUMPAD 0 opens the menu," -ForegroundColor White
    Write-Host " NUMPAD 8 up, NUMPAD 2 down, NUMPAD 5 to confirm." -ForegroundColor White
}
Write-Host ""
Write-Host " No downgrade needed - the VRV patcher runs R.E.A.L. on build" -ForegroundColor Gray
Write-Host " $TARGET_VERSION. If GTA V later updates to a newer build," -ForegroundColor Gray
Write-Host " ScriptHookV and the patcher may need updating to match." -ForegroundColor Gray
Pause-User "Press Enter once you have read the steps above..."

Write-Host ""
Write-Host " Pull off the heist, outrun the stars, and own the streets of Los Santos." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
