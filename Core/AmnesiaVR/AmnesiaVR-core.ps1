# -------------------------------------------------------
# Amnesia VR Mod Installer (Sclerosis remake)
# by CreaTeam - distributed via itch.io
#
# Walks the user through:
# 1. Opens itch.io download page in browser
# 2. User downloads Sclerosis_VR_v1.8.16.zip manually
# 3. Drag-and-drop ZIP into this window
# 4. Auto-locate Amnesia: The Dark Descent install folder
# 5. Extract mod files in place next to Amnesia.exe
# 6. Verify Sclerosis.exe exists post-install
#
# Sclerosis is a free fan-made VR remake of Amnesia: The
# Dark Descent built in Unity. It requires Amnesia: The
# Dark Descent on Steam (AppID 57300) to be installed.
# The mod ships its own engine (Unity) - Sclerosis.exe
# is the new launch target, NOT the original Amnesia.exe.
#
# Development status: the mod author halted development
# in 2024. v1.8.16 is the final shipping version.
# No auto-updater - we pin the version.
# -------------------------------------------------------


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")

$MOD_NAME = "Sclerosis (Amnesia VR Remake)"
$MOD_VERSION = "v1.8.16"
$MOD_AUTHOR = "CreaTeam"

$GAME_APPID = "57300"
$GAME_NAME = "Amnesia The Dark Descent"

# itch.io mod page - user downloads the ZIP from here.
# Direct download URL not extractable (itch token-protected).
$ITCH_PAGE_URL = "https://createam.itch.io/sclerosis-an-amnesia-vr-remake"
$EXPECTED_ZIP = "Sclerosis_VR_v1.8.16.zip"

# Optional HD texture pack (Nexus). 4x AI-upscaled textures - a single
# data.unity3d that REPLACES the one in Sclerosis_Data. Downloaded by the
# user from Nexus (login required), then dragged onto the window.
$HD_NEXUS_URL   = "https://www.nexusmods.com/amnesia/mods/31?tab=files"
$HD_EXPECTED_ZIP = "Sclerosis 4X AI Upscaled Textures 31 1.00*.zip"
$HD_INNER_FILE   = "data.unity3d"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Yellow
 Write-Host " Amnesia VR Mod Installer" -ForegroundColor Cyan
 Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Yellow
 Write-Host ""
}

function Write-Step {
 param([int]$Step, [int]$Total, [string]$Title)
 Write-Host ""
 Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
 Write-Host "----------------------------------------" -ForegroundColor DarkGray
}

function Write-OK { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m" -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# Extract a .zip with a live progress line (entry count + MB written), so a
# big archive (the ~3 GB HD pack) never looks frozen behind a static bar.
# Uses .NET ZipFile so it works without 7-Zip. Returns $true on success.
function Expand-ZipWithProgress {
    param([string]$ZipPath, [string]$Dest, [string]$Label = "files")
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    if (-not (Test-Path -LiteralPath $Dest)) { New-Item -ItemType Directory -Path $Dest -Force -ErrorAction Stop | Out-Null }
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $entries = $zip.Entries
        $totalBytes = 0L
        foreach ($e in $entries) { $totalBytes += $e.Length }
        if ($totalBytes -le 0) { $totalBytes = 1L }
        $doneBytes = 0L
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $lastDraw = -1000
        $buf = New-Object byte[] (4MB)
        $drawProgress = {
            param($db, $tb, $sw, $lbl)
            $pct    = [int](($db / $tb) * 100)
            $doneMB = [Math]::Round($db / 1MB, 0)
            $totMB  = [Math]::Round($tb / 1MB, 0)
            $el     = $sw.Elapsed.ToString('mm\:ss')
            Write-Host ("`r  Extracting $lbl... {0,3}%   {1}/{2} MB   {3} elapsed        " -f $pct, $doneMB, $totMB, $el) -NoNewline -ForegroundColor Gray
        }
        foreach ($e in $entries) {
            $target = Join-Path $Dest $e.FullName
            if ([string]::IsNullOrEmpty($e.Name)) {
                if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Path $target -Force -ErrorAction SilentlyContinue | Out-Null }
                continue
            }
            $parent = Split-Path -Parent $target
            if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force -ErrorAction SilentlyContinue | Out-Null }
            # Stream the entry in 4 MB blocks so the byte counter (and the
            # progress line) advances DURING a big file, not only after it.
            # This is what makes a single 3 GB data.unity3d show progress.
            $inStream = $e.Open()
            try {
                $outStream = [System.IO.File]::Create($target)
                try {
                    while (($read = $inStream.Read($buf, 0, $buf.Length)) -gt 0) {
                        $outStream.Write($buf, 0, $read)
                        $doneBytes += $read
                        if (($sw.ElapsedMilliseconds - $lastDraw) -ge 250) {
                            $lastDraw = $sw.ElapsedMilliseconds
                            & $drawProgress $doneBytes $totalBytes $sw $Label
                        }
                    }
                } finally { $outStream.Close() }
            } finally { $inStream.Close() }
            # Preserve the archive timestamp where possible.
            try { [System.IO.File]::SetLastWriteTime($target, $e.LastWriteTime.LocalDateTime) } catch {}
        }
        Write-Host ("`r  Extracting $Label... 100%   {0}/{0} MB   done          " -f ([Math]::Round($totalBytes / 1MB, 0))) -ForegroundColor Gray
        return $true
    } finally {
        $zip.Dispose()
    }
}

function Install-AmnesiaBaseArchive {
    param([string]$ArchivePath,[string]$GameRoot,[string]$ScriptDir)
    $stage = Join-Path $env:TEMP ('pcvr-amnesia-' + [guid]::NewGuid().ToString('N'))
    $payload = Join-Path $stage 'payload'
    $backupRoot = Join-Path $GameRoot ('.pcvrhub-amnesia-backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,6))
    $written = New-Object System.Collections.Generic.List[string]
    $backedUp = New-Object System.Collections.Generic.List[string]
    try {
        $check = Test-ZipArchiveEntrySafety -ArchivePath $ArchivePath -DestinationFolder $payload
        if (-not $check.Inspectable -or -not $check.Safe) { throw "The selected ZIP is unreadable or has an unsafe path: $($check.Entry)" }
        New-Item -ItemType Directory -Path $payload -Force -ErrorAction Stop | Out-Null
        Write-Info 'Extracting Sclerosis into a safe temporary folder. This can take several minutes.'
        [void](Expand-ZipWithProgress -ZipPath $ArchivePath -Dest $payload -Label 'Sclerosis')
        $required = @('Sclerosis.exe','GameAssembly.dll','UnityPlayer.dll','Sclerosis_Data\data.unity3d',
            'Sclerosis_Data\Plugins\x86_64\UnityOpenXR.dll')
        foreach ($relative in $required) {
            if (-not (Test-Path -LiteralPath (Join-Path $payload $relative) -PathType Leaf)) {
                throw "The archive is missing $relative. No game files were changed."
            }
        }
        if (Test-Path -LiteralPath (Join-Path $payload 'Amnesia.exe') -PathType Leaf) {
            throw 'The archive contains the original game executable. No game files were changed.'
        }
        $files = @(Get-ChildItem -LiteralPath $payload -Recurse -File -ErrorAction Stop)
        Write-Info 'Copying and verifying Sclerosis files. This can take several minutes.'
        try {
            foreach ($file in $files) {
                $relative = $file.FullName.Substring($payload.Length).TrimStart('\')
                $dest = Join-Path $GameRoot $relative
                if ($relative -like 'Sclerosis_custom_translation\*' -and (Test-Path -LiteralPath $dest -PathType Leaf)) { continue }
                if (Test-Path -LiteralPath $dest -PathType Container) { throw "A folder blocks the file: $relative" }
                $sourceHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
                if (Test-Path -LiteralPath $dest -PathType Leaf) {
                    if ((Get-Item -LiteralPath $dest).Length -eq $file.Length -and
                        (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash -eq $sourceHash) { continue }
                    $save = Join-Path $backupRoot $relative
                    New-Item -ItemType Directory -Path (Split-Path $save -Parent) -Force -ErrorAction Stop | Out-Null
                    Copy-Item -LiteralPath $dest -Destination $save -Force -ErrorAction Stop
                    [void]$backedUp.Add($relative)
                }
                New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force -ErrorAction Stop | Out-Null
                [void]$written.Add($relative)
                Copy-Item -LiteralPath $file.FullName -Destination $dest -Force -ErrorAction Stop
                if ($sourceHash -ne (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash) {
                    throw "Copy verification failed: $relative"
                }
            }
            $contract = New-PCVRInstallerContract -Id 'sclerosis' -GameName 'Amnesia VR' -Acquisition External `
                -Routes @('Current') -RequiredInstalledFileGroups $required
            [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $GameRoot -Version $MOD_VERSION `
                -InstalledPathReceiptPaths @((Join-Path $ScriptDir '.installed_path')))
        } catch {
            $failure = $_
            $rollbackErrors = New-Object System.Collections.Generic.List[string]
            for ($i = $written.Count - 1; $i -ge 0; $i--) {
                $relative = $written[$i]
                $dest = Join-Path $GameRoot $relative
                try {
                    if ($backedUp.Contains($relative)) { Copy-Item -LiteralPath (Join-Path $backupRoot $relative) -Destination $dest -Force -ErrorAction Stop }
                    elseif (Test-Path -LiteralPath $dest -PathType Leaf) { Remove-Item -LiteralPath $dest -Force -ErrorAction Stop }
                } catch { [void]$rollbackErrors.Add("$relative`: $($_.Exception.Message)") }
            }
            if ($rollbackErrors.Count) { throw "Sclerosis install failed: $failure. Rollback incomplete: $($rollbackErrors -join '; ')" }
            throw $failure
        }
        if ($backedUp.Count -gt 0) { Write-Info "Previous files were saved in $backupRoot" }
        Write-OK 'Sclerosis files and installed version verified.'
        return $true
    } finally {
        $tempPrefix = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
        if ([IO.Path]::GetFullPath($stage).StartsWith($tempPrefix,[StringComparison]::OrdinalIgnoreCase) -and
            (Split-Path $stage -Leaf) -match '^pcvr-amnesia-[0-9a-f]{32}$' -and (Test-Path -LiteralPath $stage)) {
            Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Download + install the optional HD texture pack into <SclDataDir>. Shared
# by the full install (step 4) and the "HD only" retrofit path. Returns
# $true when the HD data.unity3d was placed.
function Install-AmnesiaHDTextures {
    param([string]$SclDataDir, [string]$ScriptDir)
    if (-not (Test-Path -LiteralPath $SclDataDir)) {
        Write-Warn "Sclerosis_Data folder not found ($SclDataDir)."
        Write-Host "  The base mod may not be installed correctly - skipping HD pack." -ForegroundColor Yellow
        return $false
    }
    Write-Host "  A community 4x AI-upscaled texture pack (Nexus) replaces the" -ForegroundColor White
    Write-Host "  game's textures with sharper versions. Adds ~3 GB; an 8 GB+" -ForegroundColor Gray
    Write-Host "  VRAM GPU is recommended. Purely cosmetic." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  The Nexus page opens next (log in if needed; if it lists" -ForegroundColor White
    Write-Host "  'Sclerosis' as a requirement, that is fine - it is installed)." -ForegroundColor White
    Write-Host "  Grab the '4X AI Upscaled Textures' ZIP, then drag it here." -ForegroundColor White
    Pause-User "Press Enter to open the Nexus page in your browser..."
    try { Start-Process $HD_NEXUS_URL } catch { Write-Warn "Could not open the browser. Open manually: $HD_NEXUS_URL" }

    $hdZip = $null
    while (-not $hdZip) {
        Write-Host ""
        Write-Host "  Drag the downloaded HD texture ZIP onto this window and press Enter." -ForegroundColor Yellow
        Write-Host "  (Leave empty and press Enter to skip the HD pack.)" -ForegroundColor DarkGray
        $rawHd = Read-Host "  HD ZIP path"
        if ([string]::IsNullOrWhiteSpace($rawHd)) { Write-Info "Skipped the HD texture pack."; return $false }
        $ph = $rawHd.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path -LiteralPath $ph)) { Write-Warn "Path not found: $ph"; continue }
        if (Test-Path -LiteralPath $ph -PathType Container) { Write-Warn "That is a folder. Drag the .zip file itself."; continue }
        if ([System.IO.Path]::GetExtension($ph) -ne ".zip") { Write-Warn "That is not a .zip file."; continue }
        $hdZip = $ph
    }

    $hdTmp = Join-Path $env:TEMP ("SclerosisHD_" + [System.Guid]::NewGuid().ToString("N"))
    try {
        $hdSafety = Test-ZipArchiveEntrySafety -ArchivePath $hdZip -DestinationFolder $hdTmp
        if (-not $hdSafety.Inspectable -or -not $hdSafety.Safe) {
            Write-Warn "HD ZIP is unreadable or has an unsafe path: $($hdSafety.Entry)"
            return $false
        }
        New-Item -ItemType Directory -Path $hdTmp -Force -ErrorAction Stop | Out-Null
        Write-Info 'Extracting HD textures safely. This can take several minutes.'
        [void](Expand-ZipWithProgress -ZipPath $hdZip -Dest $hdTmp -Label 'HD textures')
        $hdData = Get-ChildItem -LiteralPath $hdTmp -Filter $HD_INNER_FILE -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $hdData) {
            Write-Warn "Could not find $HD_INNER_FILE inside the ZIP - skipping HD pack."
            return $false
        }
        $targetData = Join-Path $SclDataDir $HD_INNER_FILE
        $backup = $null
        if (Test-Path -LiteralPath $targetData) {
            $backup = Join-Path $SclDataDir ('.pcvrhub-hd-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,6) + '.unity3d')
            Copy-Item -LiteralPath $targetData -Destination $backup -Force -ErrorAction Stop
            if ((Get-FileHash -LiteralPath $targetData -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash) {
                Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue
                throw 'The original HD texture file could not be backed up intact.'
            }
            Write-OK "Backed up the previous textures: $backup"
        }
        Write-Info 'Copying and verifying the HD textures. This can take several minutes.'
        try {
            Copy-Item -LiteralPath $hdData.FullName -Destination $targetData -Force -ErrorAction Stop
            if ((Get-FileHash -LiteralPath $hdData.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $targetData -Algorithm SHA256).Hash) {
                throw 'HD texture copy verification failed.'
            }
        } catch {
            if ($backup -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
                Copy-Item -LiteralPath $backup -Destination $targetData -Force -ErrorAction Stop
            } elseif (Test-Path -LiteralPath $targetData -PathType Leaf) {
                Remove-Item -LiteralPath $targetData -Force -ErrorAction Stop
            }
            throw
        }
        Write-OK "HD textures installed (data.unity3d replaced in Sclerosis_Data)."
        Write-Host ""
        Write-Host "  IMPORTANT: In-game, set Texture Quality to ULTRA to see the" -ForegroundColor Yellow
        Write-Host "  upscaled textures." -ForegroundColor Yellow
        try { Set-Content -Path (Join-Path $ScriptDir ".hd_installed") -Value $targetData -Encoding UTF8 -Force } catch {}
        return $true
    } catch {
        Write-Warn "HD texture install failed: $($_.Exception.Message)"
        Write-Host "  You can install it manually later: replace data.unity3d in" -ForegroundColor Yellow
        Write-Host "  $SclDataDir with the one from the ZIP." -ForegroundColor Yellow
        return $false
    } finally {
        try { Remove-Item -LiteralPath $hdTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    }
}

function Get-SteamPath {
 foreach ($reg in @(
 "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
 "HKLM:\SOFTWARE\Valve\Steam",
 "HKCU:\SOFTWARE\Valve\Steam"
 )) {
 try {
 $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
 if ($p -and (Test-Path $p)) { return $p }
 } catch {}
 }
 return $null
}

function Get-SteamLibraryFolders {
 $steam = Get-SteamPath
 if (-not $steam) { return @() }
 $libs = @($steam)
 $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
 if (Test-Path $vdf) {
 $content = Get-Content $vdf -Raw
 $matches = [regex]::Matches($content, '"path"\s+"([^"]+)"')
 foreach ($m in $matches) {
 $path = $m.Groups[1].Value -replace '\\\\', '\'
 if (Test-Path $path) { $libs += $path }
 }
 }
 return $libs | Select-Object -Unique
}

function Find-AmnesiaGamePath {
 foreach ($lib in (Get-SteamLibraryFolders)) {
 $candidate = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path $candidate) {
 # Verify Amnesia.exe OR AmnesiaGW.exe exists - either
 # confirms a real Amnesia install. AmnesiaGW.exe is
 # the alternate-engine binary mentioned in the mod's
 # bundled HOW_TO_INSTALL.txt; we accept either as proof
 # the folder is a real game install (not just empty).
 $exe1 = Join-Path $candidate "Amnesia.exe"
 $exe2 = Join-Path $candidate "AmnesiaGW.exe"
 if ((Test-Path $exe1) -or (Test-Path $exe2)) {
 return $candidate
 }
 }
 }
 return $null
}

# -------------------------------------------------------
# STEP 0: Welcome + Itch.io page open
# -------------------------------------------------------
Write-Header
Write-Host "  Installs Sclerosis, a free fan-made VR remake of Amnesia: The" -ForegroundColor Gray
Write-Host "  Dark Descent (motion controls + room-scale). You need Amnesia:" -ForegroundColor Gray
Write-Host "  The Dark Descent owned and installed on Steam." -ForegroundColor Gray
Write-Host ""

# ---- Existing install? Offer HD-pack retrofit without a full reinstall.
# The base download is large (~916 MB); if the Sclerosis mod is already
# installed (Sclerosis.exe present), let the user just add the HD pack.
$existingGamePath = $null
try {
    $cand = Find-AmnesiaGamePath
    if (-not $cand) { $cand = Find-SteamGameFolder -AppId "57300" -SteamFolderNames @("Amnesia The Dark Descent") -ProbeExe "Sclerosis.exe" -GogNames @("Amnesia The Dark Descent") }
    if ($cand -and (Test-Path -LiteralPath (Join-Path $cand "Sclerosis.exe"))) {
        $existingGamePath = $cand
    }
} catch {}

if ($existingGamePath) {
    Write-Host "  An existing Sclerosis (Amnesia VR) install was found here:" -ForegroundColor Green
    Write-Host "    $existingGamePath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  What would you like to do?" -ForegroundColor White
    Write-Host "    [1] Add the HD texture pack only (no big re-download)" -ForegroundColor Yellow
    Write-Host "    [2] Reinstall everything from scratch" -ForegroundColor Yellow
    Write-Host ""
    $modeChoice = (Read-Host "  Choose 1 or 2").Trim()
    if ($modeChoice -eq "1") {
        Pause-User "Press Enter to start..."
        Write-Step 1 1 "Adding the HD texture pack"
        $sclData = Join-Path $existingGamePath "Sclerosis_Data"
        $ok = Install-AmnesiaHDTextures -SclDataDir $sclData -ScriptDir $PSScriptRoot
        if ($ok) {
            Write-Host ""
            Write-Host "  Done. Launch Amnesia VR from your existing shortcut as usual." -ForegroundColor White
            Write-Host ""
            Write-Host "  Tinderboxes lit. Mind still slipping. Welcome to the dark." -ForegroundColor Magenta
        } else {
            Write-Host ""
            Write-Host "  No changes made. You can re-run this any time." -ForegroundColor Gray
        }
        Write-Host ""
        Pause-User "Press Enter to close..."
        return
    }
    Write-Info "Continuing with a full reinstall."
    Write-Host ""
}
Write-Host "  The free mod downloads from itch.io - the page opens next; grab" -ForegroundColor White
Write-Host "  $EXPECTED_ZIP (~916 MB), then drag it onto this window." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to open the itch.io page in your browser..."
try { Start-Process $ITCH_PAGE_URL } catch {
    Write-Warn "Could not open browser. Open manually: $ITCH_PAGE_URL"
}

# -------------------------------------------------------
# STEP 1: Get the ZIP from the user
# -------------------------------------------------------
Write-Step 1 5 "Locate the downloaded ZIP"

$modZip = $null
while (-not $modZip) {
 Write-Host " Drag-and-drop the downloaded ZIP into this window," -ForegroundColor Yellow
 Write-Host " or paste/type its full path, then press Enter:" -ForegroundColor White
 $r = (Read-Host " ZIP path").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 if ($r -match '\.zip$') {
 $modZip = $r
 Write-OK "Archive located: $modZip"
 } else {
 Write-Fail "Path is not a ZIP archive: $r"
 }
 } else {
 Write-Fail "File not found: $r"
 }
}

# -------------------------------------------------------
# STEP 2: Locate the Amnesia install
# -------------------------------------------------------
Write-Step 2 5 "Locating Amnesia: The Dark Descent"

$gamePath = Find-AmnesiaGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "57300" -SteamFolderNames @("Amnesia The Dark Descent") -ProbeExe "Sclerosis.exe" -GogNames @("Amnesia The Dark Descent") }
if ($gamePath) {
 Write-OK "Found Amnesia at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Amnesia: The Dark Descent in any Steam library."
 Write-Host " Please paste the path to your Amnesia folder" -ForegroundColor White
 Write-Host " (the folder that contains Amnesia.exe), then press Enter:" -ForegroundColor White
 while (-not $gamePath) {
 $r = (Read-Host " Amnesia folder").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 $exe1 = Join-Path $r "Amnesia.exe"
 $exe2 = Join-Path $r "AmnesiaGW.exe"
 if ((Test-Path $exe1) -or (Test-Path $exe2)) {
 $gamePath = $r
 Write-OK "Confirmed Amnesia folder: $gamePath"
 } else {
 Write-Fail "No Amnesia.exe or AmnesiaGW.exe in: $r"
 }
 } else {
 Write-Fail "Folder not found: $r"
 }
 }
}

# -------------------------------------------------------
# STEP 3: Extract the mod into the Amnesia folder
# -------------------------------------------------------
Write-Step 3 5 "Installing mod files"
Write-Host " Extracting $EXPECTED_ZIP contents directly into:" -ForegroundColor Gray
Write-Host " $gamePath" -ForegroundColor DarkGray
Write-Host ""

try {
 [void](Install-AmnesiaBaseArchive -ArchivePath $modZip -GameRoot $gamePath -ScriptDir $PSScriptRoot)
} catch {
 Write-Fail "Sclerosis setup did not complete: $($_.Exception.Message)"
 Write-Host '  The previous files were restored where possible. Choose another ZIP and rerun setup.' -ForegroundColor Yellow
 Pause-User 'Press Enter to close without marking this install complete...'
 exit 1
}

# Verify Sclerosis.exe arrived
$sclerosisExe = Join-Path $gamePath "Sclerosis.exe"
if (Test-Path $sclerosisExe) {
 Write-OK "Sclerosis.exe present in game folder."
} else {
 Write-Warn "Sclerosis.exe not found after extraction."
 Write-Host " The ZIP may have had a different structure than expected." -ForegroundColor Yellow
 Write-Host " Check $gamePath for a subfolder and move Sclerosis.exe up." -ForegroundColor Yellow
}

# -------------------------------------------------------
# -------------------------------------------------------
# STEP 4: Optional HD texture pack (Nexus, 4x AI upscale)
# -------------------------------------------------------
Write-Step 4 5 "Optional: HD texture pack"
$hdChoice = Read-Host " Install the optional HD texture pack now? (Y/N)"
if ($hdChoice -match '^(y|yes|j|ja)$') {
    $sclDataDir = Join-Path $gamePath "Sclerosis_Data"
    Install-AmnesiaHDTextures -SclDataDir $sclDataDir -ScriptDir $PSScriptRoot | Out-Null
} else {
    Write-Info "Skipping the HD texture pack. You can re-run this installer to add it later."
}

# STEP 5: Desktop shortcut
# -------------------------------------------------------
Write-Step 5 5 "Creating Desktop Shortcut"

if (Test-Path $sclerosisExe) {
 try {
 $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Amnesia VR.lnk" -TargetPath $sclerosisExe -WorkingDir $gamePath -IconPath "$sclerosisExe,0"
 Write-OK "Desktop shortcut 'Amnesia VR' created."
 } catch {
 Write-Warn "Could not create shortcut: $_"
 Write-Info "Launch manually: $sclerosisExe"
 }
} else {
 Write-Warn "Skipping shortcut - Sclerosis.exe not found."
}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation complete." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Launch via the Hub: Start in VR -> runs Sclerosis.exe" -ForegroundColor White
Write-Host " Desktop shortcut: 'Amnesia VR' -> Sclerosis.exe" -ForegroundColor White
Write-Host ""
Write-Host " Tinderboxes lit. Mind still slipping. Welcome to the dark." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
