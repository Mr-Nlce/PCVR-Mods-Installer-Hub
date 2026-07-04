# ============================================================
# Cruelty Squad - VR Modloader Installer
# ============================================================
# Installs teddybear082's CrueltySquadVR Modloader (v1.3-Stable),
# a fork of crustyrashky & disco0's flatscreen modloader. Godot
# OpenXR based, full motion controls.
#
# Flow:
#   1. Download + extract crus-vr-modloader into the game folder
#   2. Run install_modloader.bat (patches the .pck via godotpcktool,
#      copies OpenXR DLLs + override.cfg next to the EXE, backs up
#      the original .pck)
#   3. User launches the game once to create the mods folder
#   4. Copy cs-vr-mod-vr-files + cs-vr-mod-xr-tools into the mods folder
#   5. (Optional) install the Stutter Fix and Text-to-Speech add-ons
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Cruelty Squad VR Installer"
$ErrorActionPreference = "Stop"

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------
$GAME_NAME    = "Cruelty Squad"
$GAME_FOLDER  = "Cruelty Squad"
$GAME_EXE     = "crueltysquad.exe"
$APPID        = "1388770"

$MODLOADER_URL = "https://github.com/teddybear082/CrueltySquadVR-Modloader/releases/download/v.1.3-release-crueltysquad-vr-mod/crus-vr-modloader.zip"
$INFO_URL      = "https://github.com/teddybear082/CrueltySquadVR-Modloader"

# Add-ons (Godot mods - mod.json + mod.zip). MediaFire direct links
# can rot, so we try the direct link then fall back to the page +
# drag-and-drop.
$STUTTER_DIRECT = "https://www.mediafire.com/file/wrqn5lfk6pvc4yn/Stutter_Fix.zip/file"
$STUTTER_PAGE   = "https://www.mediafire.com/file/wrqn5lfk6pvc4yn/Stutter_Fix.zip/file"
$TTS_DIRECT     = "https://www.mediafire.com/file/2s78xwd9g8nen1q/crus-text-to-speech.zip/file"
$TTS_PAGE       = "https://www.mediafire.com/file/2s78xwd9g8nen1q/crus-text-to-speech.zip/file"

# Godot per-user mods folder
$MODS_DIR = Join-Path $env:APPDATA "Godot\app_userdata\Cruelty Squad\mods"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host " Cruelty Squad - VR Modloader Installer" -ForegroundColor Green; Write-Host " CrueltySquadVR Modloader v1.3-Stable by teddybear082" -ForegroundColor Gray; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "" }
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

# Download an add-on .zip: try the direct link, then fall back to the
# MediaFire page + drag-and-drop. Returns the path to the zip or $null.
function Get-AddonZip {
    param([string]$Name, [string]$DirectUrl, [string]$PageUrl, [string]$Dest)
    # MediaFire direct links don't work for automated download, so we
    # skip auto-download entirely: open the page and let the user grab
    # the file by hand.
    Write-Host " Opening the MediaFire page for $Name in your browser ..." -ForegroundColor White
    try { Start-Process $PageUrl } catch {
        Write-Warn "Could not open the browser. Download manually from:"
        Write-Host "   $PageUrl" -ForegroundColor Gray
    }
    Write-Host " On that page, click the green Download button to save" -ForegroundColor White
    Write-Host " '$Name.zip'." -ForegroundColor White
    Write-Host ""
    $manual = Read-Host " Drag the downloaded zip here (or paste its full path), or leave it empty and just press Enter to skip"
    $manual = $manual.Trim().Trim('"')
    if (-not $manual) {
        Write-Info "Skipped - $Name will not be installed."
        return $null
    }
    if (-not (Test-Path $manual)) {
        Write-Warn "That path doesn't exist - skipping $Name."
        return $null
    }
    # Sanity: a real zip starts with 'PK'.
    try {
        $fs = [System.IO.File]::OpenRead($manual)
        $b0 = $fs.ReadByte(); $b1 = $fs.ReadByte(); $fs.Close()
        if ($b0 -ne 0x50 -or $b1 -ne 0x4B) {
            Write-Warn "That file isn't a valid zip - skipping $Name."
            return $null
        }
    } catch {
        Write-Warn "Could not read that file - skipping $Name."
        return $null
    }
    try { Copy-Item $manual $Dest -Force } catch { return $null }
    Write-OK "$Name zip accepted."
    return $Dest
}

# Install a Godot add-on zip into the mods folder. These zips contain a
# top-level folder (e.g. "Stutter Fix\") with mod.json + mod.zip.
function Install-Addon {
    param([string]$ZipPath, [string]$Label)
    if (-not $ZipPath -or -not (Test-Path $ZipPath)) { return $false }
    $tmp = Join-Path $env:TEMP "CSVRAddon_$([System.IO.Path]::GetRandomFileName())"
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        Expand-Archive -Path $ZipPath -DestinationPath $tmp -Force
        # Copy each top-level folder from the zip into the mods dir.
        Get-ChildItem -Path $tmp -Directory | ForEach-Object {
            $target = Join-Path $MODS_DIR $_.Name
            if (Test-Path $target) { Remove-Item $target -Recurse -Force -ErrorAction SilentlyContinue }
            Copy-Item $_.FullName -Destination $MODS_DIR -Recurse -Force
        }
        # If the zip had files at its root (no folder), copy them too.
        Get-ChildItem -Path $tmp -File | ForEach-Object { Copy-Item $_.FullName -Destination $MODS_DIR -Force }
        Write-OK "$Label installed to the mods folder."
        $result = $true
    } catch {
        Write-Warn "Could not install $Label : $_"
        $fb = Invoke-InstallerFallback -Action "install $Label" `
            -Instructions "Extract '$ZipPath' and copy its mod folder into '$MODS_DIR'. Then choose Skip to continue." `
            -SkipMessage "Skipped - $Label was not installed." `
            -SourceFolder (Split-Path $ZipPath -Parent) -DestFolder $MODS_DIR -AllowSkip $true
        $result = $false
    }
    try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    return $result
}

# ============================================================
# START
# ============================================================
Write-Header
Write-Host " EPILEPSY / SEIZURE WARNING:" -ForegroundColor Yellow
Write-Host " Cruelty Squad VR has fast-moving textures, flashing images" -ForegroundColor White
Write-Host " and intense visual effects. If you have epilepsy, you should" -ForegroundColor White
Write-Host " NOT play this VR mod." -ForegroundColor White
Write-Host ""
Write-Host " Only use this mod on a legitimately purchased copy. Back up" -ForegroundColor Gray
Write-Host " your Cruelty Squad SAVES before continuing." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to acknowledge and continue..."

# -------------------------------------------------------
# Locate the game
# -------------------------------------------------------
Write-Step 1 5 "Locating $GAME_NAME"
$gamePath = $null
$steamPath = Get-SteamPath
if ($steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $c = Join-Path $lib "steamapps\common\$GAME_FOLDER"
        if (Test-Path (Join-Path $c $GAME_EXE)) { $gamePath = $c; break }
    }
}
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1388770" -SteamFolderNames @("Cruelty Squad") -ProbeExe "crueltysquad.exe" }
if ($gamePath) {
    Write-OK "Game found: $gamePath"
} else {
    Write-Warn "Game not found automatically."
    Write-Host " Enter the folder containing crueltysquad.exe:" -ForegroundColor White
    while (-not $gamePath) {
        $r = (Read-Host " Path").Trim().Trim('"')
        if (Test-Path (Join-Path $r $GAME_EXE)) { $gamePath = $r; Write-OK "Path set: $gamePath" }
        else { Write-Fail "crueltysquad.exe not found in: $r" }
    }
}

Write-Host ""
Write-Host " IMPORTANT first-run note:" -ForegroundColor Cyan
Write-Host " If you have never run Cruelty Squad, or have used other mods," -ForegroundColor White
Write-Host " start from a CLEAN install: verify game files in Steam first" -ForegroundColor White
Write-Host " (right-click -> Properties -> Local Files -> Verify), and run" -ForegroundColor White
Write-Host " the game once unmodded so its folders are created." -ForegroundColor White
Write-Host ""
Write-Host " VR runtime: if you use WMR, Virtual Desktop or ALVR, set your" -ForegroundColor White
Write-Host " OpenXR runtime to SteamVR (VD users can also use VDXR). Turn" -ForegroundColor White
Write-Host " OFF OpenXR Toolkit if you have it, or the game will crash." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter once your game is in a clean state..."

# -------------------------------------------------------
# Download + extract the modloader into the game folder
# -------------------------------------------------------
Write-Step 2 5 "Installing the VR modloader"
$tempDir = Join-Path $env:TEMP "CSVRModloader_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$mlZip = Join-Path $tempDir "crus-vr-modloader.zip"

$dl = Invoke-DownloadOrFallback -Url $MODLOADER_URL -Destination $mlZip `
        -Label "CrueltySquadVR Modloader v1.3" `
        -ManualUrl "$INFO_URL/releases" `
        -Instructions "Download 'crus-vr-modloader.zip' from the GitHub releases page that just opened. Place it at '$mlZip' and choose Retry." `
        -SkipMessage "Skipped - the modloader is required; the mod cannot be installed without it."

# Extract into the game folder so we get <GAME_DIR>\crus-vr-modloader\
if (Test-Path $mlZip) {
    Write-Host " Extracting modloader into the game folder ... " -NoNewline -ForegroundColor White
    try {
        # Remove a stale copy so we never end up with nested folders.
        $mlTarget = Join-Path $gamePath "crus-vr-modloader"
        if (Test-Path $mlTarget) { Remove-Item $mlTarget -Recurse -Force -ErrorAction SilentlyContinue }
        Expand-Archive -Path $mlZip -DestinationPath $gamePath -Force
        Write-Host "OK" -ForegroundColor Green
    } catch {
        Write-Host "FAILED" -ForegroundColor Red
        $fb = Invoke-InstallerFallback -Action "extract the modloader" `
            -Instructions "Extract '$mlZip' so that a single 'crus-vr-modloader' folder sits next to crueltysquad.exe in '$gamePath'. Then choose Retry." `
            -SkipMessage "Skipped - modloader not extracted; cannot continue." `
            -SourceFolder $tempDir -DestFolder $gamePath -AllowSkip $true
        if ([string]$fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    }
}

$mlFolder = Join-Path $gamePath "crus-vr-modloader"
$mlBat    = Join-Path $mlFolder "install_modloader.bat"
if (-not (Test-Path $mlBat)) {
    Write-Warn "install_modloader.bat not found in $mlFolder"
    Write-Info "The archive may have extracted into a nested folder."
    [void](Invoke-InstallerFallback -Action "place the modloader correctly" `
        -Subject "the crus-vr-modloader folder" `
        -Instructions "Make sure a single 'crus-vr-modloader' folder (containing install_modloader.bat) sits directly next to crueltysquad.exe in '$gamePath' - not nested inside a second 'crus-vr-modloader' folder. Then choose Retry." `
        -SkipMessage "Skipped - without the modloader the VR mod cannot be installed. You can re-run this installer once the folder is in place." `
        -SourceFolder $tempDir -DestFolder $gamePath -AllowSkip $true `
        -RetryCheck { Test-Path (Join-Path (Join-Path $gamePath "crus-vr-modloader") "install_modloader.bat") })
    if (-not (Test-Path $mlBat)) {
        Write-Info "Modloader not in place - stopping here. Re-run when ready."
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

Write-Host ""
Write-Host " Running the modloader installer. A PowerShell window will" -ForegroundColor White
Write-Host " open and patch the game. If Windows Defender prompts you," -ForegroundColor White
Write-Host " choose Run / Keep." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to run install_modloader.bat..."
try {
    Start-Process -FilePath $mlBat -WorkingDirectory $mlFolder -Wait
    Write-OK "Modloader installer finished."
} catch {
    Write-Warn "Could not launch install_modloader.bat: $_"
    Write-Host " Open '$mlFolder' and run install_modloader.bat manually." -ForegroundColor Gray
    Pause-User "Press Enter once it has finished..."
}

# Verify the loader copied its files next to the EXE
$loaderOk = (Test-Path (Join-Path $gamePath "override.cfg")) -and `
            (Test-Path (Join-Path $gamePath "openxr_loader.dll"))
if ($loaderOk) { Write-OK "Modloader files detected next to crueltysquad.exe." }
else { Write-Warn "override.cfg / openxr_loader.dll not detected - the loader step may not have completed." }

# -------------------------------------------------------
# First launch to create the mods folder
# -------------------------------------------------------
Write-Step 3 5 "Creating the mods folder"
Write-Host " Now launch Cruelty Squad ONCE so it creates its mods folder." -ForegroundColor White
Write-Host " It may show errors the first time (missing XR-tools asset) -" -ForegroundColor Yellow
Write-Host " that's expected. Let it open, then close it after about 10s" -ForegroundColor White
Write-Host " (otherwise it will crash on its own), then come back here." -ForegroundColor White
Write-Host " The console will print some errors - that's normal. Just" -ForegroundColor Yellow
Write-Host " press Enter to continue afterwards." -ForegroundColor Yellow
Write-Host ""
$launchExe = Join-Path $gamePath $GAME_EXE
$c = ""
while ($c -notin @("y","Y","n","N")) { $c = (Read-Host " Launch the game now? (Y/N)").Trim() }
if ($c -in @("y","Y")) {
    try { Start-Process -FilePath $launchExe -WorkingDirectory $gamePath } catch { Write-Warn "Could not launch: $_" }
    Write-Host ""
    Write-Host " Wait for the game to open (or crash), then close it." -ForegroundColor White
    Pause-User "Press Enter once the game has been launched and closed..."
} else {
    Write-Info "Launch the game once yourself before the mod will work."
}

if (-not (Test-Path $MODS_DIR)) {
    Write-Warn "Mods folder not found yet at:"
    Write-Host "   $MODS_DIR" -ForegroundColor Gray
    Write-Host " The game must run once to create it. You can run it now," -ForegroundColor White
    Write-Host " then return here." -ForegroundColor White
    Pause-User "Press Enter to re-check for the mods folder..."
    if (-not (Test-Path $MODS_DIR)) {
        try { New-Item -ItemType Directory -Path $MODS_DIR -Force | Out-Null; Write-Info "Created the mods folder manually." } catch {}
    }
}
if (Test-Path $MODS_DIR) { Write-OK "Mods folder ready: $MODS_DIR" }

# -------------------------------------------------------
# Copy the VR mod folders into the mods folder
# -------------------------------------------------------
Write-Step 4 5 "Installing the VR mod files"
$vrFiles = Join-Path $mlFolder "cs-vr-mod-vr-files"
$xrTools = Join-Path $mlFolder "cs-vr-mod-xr-tools"
$copied = $true
foreach ($src in @($vrFiles, $xrTools)) {
    if (Test-Path $src) {
        $name = Split-Path $src -Leaf
        $dst = Join-Path $MODS_DIR $name
        try {
            if (Test-Path $dst) { Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue }
            Copy-Item $src -Destination $MODS_DIR -Recurse -Force
            Write-OK "$name copied to the mods folder."
        } catch {
            Write-Warn "Could not copy $name : $_"
            $copied = $false
        }
    } else {
        Write-Warn "$([System.IO.Path]::GetFileName($src)) not found in the modloader folder."
        $copied = $false
    }
}
if (-not $copied) {
    $fb = Invoke-InstallerFallback -Action "copy the VR mod folders" `
        -Instructions "Copy 'cs-vr-mod-vr-files' and 'cs-vr-mod-xr-tools' from '$mlFolder' into '$MODS_DIR'. Then choose Skip to continue." `
        -SkipMessage "Skipped - VR mod folders not copied; VR will not load until they are." `
        -SourceFolder $mlFolder -DestFolder $MODS_DIR -AllowSkip $true
}

# -------------------------------------------------------
# Optional add-ons
# -------------------------------------------------------
Write-Step 5 5 "Recommended add-ons (optional)"
Write-Host " The mod author recommends two extra mods:" -ForegroundColor White
Write-Host "  - Stutter Fix (DX): smooths the shader stutter when you turn" -ForegroundColor Gray
Write-Host "  - Text-to-Speech (teddybear082): reads NPC dialogue aloud so" -ForegroundColor Gray
Write-Host "    you don't have to read it from the VR hand menu" -ForegroundColor Gray
Write-Host ""
Write-Host " These are hosted on MediaFire. The automatic download does not" -ForegroundColor Gray
Write-Host " work, so you'll download each one by hand from the page that" -ForegroundColor Gray
Write-Host " opens in your browser." -ForegroundColor Gray
Write-Host ""
$wantAddons = ""
while ($wantAddons -notin @("y","Y","n","N")) { $wantAddons = (Read-Host " Install the recommended add-ons now? (Y/N)").Trim() }

if ($wantAddons -in @("y","Y")) {
    Write-Host ""
    Write-Host " --- Add-on 1 of 2: Stutter Fix ---" -ForegroundColor Cyan
    $sfZip = Join-Path $tempDir "Stutter_Fix.zip"
    $z = Get-AddonZip -Name "Stutter Fix" -DirectUrl $STUTTER_DIRECT -PageUrl $STUTTER_PAGE -Dest $sfZip
    [void](Install-Addon -ZipPath $z -Label "Stutter Fix")

    Write-Host ""
    Write-Host " Stutter Fix step done. Next up is the second add-on" -ForegroundColor White
    Write-Host " (Text-to-Speech). Its MediaFire page will open in your" -ForegroundColor White
    Write-Host " browser when you continue." -ForegroundColor White
    Pause-User "Press Enter to continue to add-on 2 of 2..."

    Write-Host ""
    Write-Host " --- Add-on 2 of 2: Text-to-Speech ---" -ForegroundColor Cyan
    $ttsZip = Join-Path $tempDir "crus-text-to-speech.zip"
    $z = Get-AddonZip -Name "Text-to-Speech" -DirectUrl $TTS_DIRECT -PageUrl $TTS_PAGE -Dest $ttsZip
    [void](Install-Addon -ZipPath $z -Label "Text-to-Speech")
} else {
    Write-Info "Skipping add-ons. You can re-run this installer to add them later."
}

# Record install path for the Hub
try {
    $pathFile = Join-Path $PSScriptRoot ".installed_path"
    Set-Content -Path $pathFile -Value $gamePath -Encoding UTF8 -Force
} catch {}

# Clean up temp
try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Cruelty Squad VR installation complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " To play:" -ForegroundColor White
Write-Host " - Put on your VR headset and start SteamVR" -ForegroundColor White
Write-Host " - Launch crueltysquad.exe (via the Hub's Start in VR or Steam)" -ForegroundColor White
Write-Host " - If it crashes to desktop the first time, run it again -" -ForegroundColor Yellow
Write-Host "   sometimes it takes up to FOUR launches for everything to" -ForegroundColor Yellow
Write-Host "   take effect. More than that means something is wrong." -ForegroundColor Yellow
Write-Host ""
Write-Host " There is no teleport locomotion. If you get motion sick, the" -ForegroundColor Gray
Write-Host " VRocker app can help with stick-based walking." -ForegroundColor Gray
Write-Host ""
Write-Host " The drillustrator says: stocks are up, and so are you." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
