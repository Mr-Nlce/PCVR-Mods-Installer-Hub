# ============================================================
# The Dark Mod VR - Guided Installer
# ============================================================
# The Dark Mod uses its OWN GUI installer (tdm_installer.exe) to fetch
# the game and any custom build. The VR mod (by Holger Frydrych) is a
# CUSTOM version: base "release210" + a custom manifest URL hosted off
# the official server. That custom-version + manifest-URL selection has
# no documented command-line / unattended path (the installer actively
# distrusts non-official manifest URLs and shows two confirmations), so
# it cannot be driven fully headless.
#
# What this installer automates around the official GUI:
#   1. Picks/creates a writable install folder (C:\Games\The Dark Mod VR)
#      and drops tdm_installer.exe INTO it, so the install path is set.
#   2. Copies the VR manifest URL to the clipboard for a one-tap paste.
#   3. Launches the TDM installer and shows the exact clicks to make.
#   4. After the install: writes a sample gamepad config (so the pad
#      works - TDM ships none), creates a desktop shortcut to the VR exe.
# Nothing is bundled; tdm_installer.exe is downloaded at install time.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "The Dark Mod VR Installer"
$ErrorActionPreference = "Stop"

$GAME_TITLE        = "The Dark Mod VR"
$INSTALLER_ZIP_URL = "https://update.thedarkmod.com/zipsync/tdm_installer.exe.zip"
$INSTALLER_PAGE    = "https://www.thedarkmod.com/downloads/"
$VR_MANIFEST_URL   = "http://tdm.frydrych.org/releases/vr/manifest.iniz"
$BASE_VERSION      = "release210"
$VR_EXE            = "TheDarkModVRx64.exe"
$INFO_URL          = "https://github.com/fholger/thedarkmodvr/wiki/Installation"
$FOLDER_NAME       = "The Dark Mod VR"
$ROOT_CANDIDATES   = @("C:\Games", "D:\Games", "E:\Games")

# ---- Inline console helpers (per-installer; NOT shared) -----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  The Dark Mod VR - Guided Installer" -ForegroundColor Yellow
    Write-Host "  Free, open-source stealth game | VR mod by Holger Frydrych" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# True if we can create + write a file under $Root (creates $Root if needed).
function Test-WritableRoot {
    param([string]$Root)
    try {
        if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Path $Root -Force -EA Stop | Out-Null }
        $probe = Join-Path $Root ".pcvr_write_test"
        Set-Content -Path $probe -Value "x" -EA Stop
        Remove-Item $probe -Force -EA SilentlyContinue
        return $true
    } catch { return $false }
}

Write-Header
Write-Host " The Dark Mod is a free, standalone, open-source stealth game." -ForegroundColor Gray
Write-Host " This sets up the VR version (custom build via the TDM installer)." -ForegroundColor Gray
Write-Host ""
Write-Host " Heads-up: the final step opens The Dark Mod's own installer." -ForegroundColor White
Write-Host " You will make 4 quick choices there - this tool prepares" -ForegroundColor White
Write-Host " everything and shows you exactly what to click." -ForegroundColor White
Pause-User "Press Enter to begin..."

# -------------------------------------------------------
# STEP 1: Choose + create the install folder
# -------------------------------------------------------
Write-Step 1 5 "Install location"

# Pick the first writable Games root; fall back across drives.
$baseRoot = $null
foreach ($cand in $ROOT_CANDIDATES) {
    if (Test-WritableRoot $cand) { $baseRoot = $cand; break }
}
if (-not $baseRoot) {
    Write-Warn "None of C:\Games, D:\Games, E:\Games is writable."
    $baseRoot = $null
}

$defaultPath = if ($baseRoot) { Join-Path $baseRoot $FOLDER_NAME } else { $null }

if ($defaultPath) {
    Write-Host " Default location (do NOT use Program Files - TDM needs write access):" -ForegroundColor Gray
    Write-Host " $defaultPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Press Enter to use this. To pick a different folder, type any key first, then Enter." -ForegroundColor Yellow
    $choice = (Read-Host " Your choice").Trim()
} else {
    # No writable default root found - go straight to the custom path prompt.
    $choice = "x"
}

if (-not $choice) {
    $gamePath = $defaultPath
} else {
    $gamePath = $null
    while (-not $gamePath) {
        Write-Host ""
        Write-Host " Enter a full path in a folder you own (e.g. D:\Games\The Dark Mod VR)." -ForegroundColor Gray
        Write-Host " Avoid C:\Program Files - the game needs write access there." -ForegroundColor Gray
        $r = (Read-Host " Full path for the game folder").Trim().Trim('"')
        if ($r) { $gamePath = $r }
    }
}

# Create the leaf folder now, so tdm_installer.exe lands in it and the
# install path is pre-set in the GUI.
try {
    if (-not (Test-Path $gamePath)) { New-Item -ItemType Directory -Path $gamePath -Force -EA Stop | Out-Null }
    Write-OK "Game folder ready: $gamePath"
} catch {
    Write-Fail "Could not create folder: $($_.Exception.Message)"
    $fb = Invoke-InstallerFallback -Action "install folder creation" `
            -Instructions "Create '$gamePath' manually (right-click in Explorer -> New folder) in a location you have write access to, then choose Retry." `
            -SkipMessage "Skipped - without a folder the install cannot continue." `
            -AllowSkip $false
    if ([string]$fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    try {
        if (-not (Test-Path $gamePath)) { New-Item -ItemType Directory -Path $gamePath -Force -EA Stop | Out-Null }
        Write-OK "Game folder ready: $gamePath"
    } catch {
        Pause-User "Still cannot create the folder. Pick a different path and re-run. Press Enter to exit..."
        exit 1
    }
}

# -------------------------------------------------------
# STEP 2: Download the TDM installer + place it in the folder
# -------------------------------------------------------
Write-Step 2 5 "Download The Dark Mod installer"

$tmp = Join-Path $env:TEMP "TheDarkModVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zipPath = Join-Path $tmp "tdm_installer.exe.zip"
$installerExe = Join-Path $gamePath "tdm_installer.exe"

$haveInstaller = $false
if (Test-Path $installerExe) {
    Write-OK "tdm_installer.exe is already in the folder - reusing it."
    $haveInstaller = $true
}

if (-not $haveInstaller) {
    $dl = Invoke-DownloadOrFallback -Url $INSTALLER_ZIP_URL -Destination $zipPath `
            -Label "tdm_installer.exe.zip" `
            -ManualUrl $INSTALLER_PAGE `
            -Instructions "Download the Windows 'tdm_installer' from the page that just opened, then place tdm_installer.exe.zip at '$zipPath' and choose Retry." `
            -SkipMessage "Skipped - the TDM installer was not downloaded."
    if ([string]$dl -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }

    if ($dl -is [bool] -and $dl) {
        # Extract the exe straight into the game folder.
        $efb = Expand-ArchiveOrFallback -ArchivePath $zipPath -DestinationFolder $gamePath `
                -Label "tdm_installer.exe extraction" `
                -SkipMessage "Skipped - tdm_installer.exe was not extracted."
        if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
        if (Test-Path $installerExe) { $haveInstaller = $true }
    }
}

# If the download/extract route didn't yield the exe, let the user drop it in.
if (-not $haveInstaller) {
    Write-Warn "tdm_installer.exe is not in the folder yet."
    $fb = Invoke-InstallerFallback -Action "place tdm_installer.exe" `
            -Url $INSTALLER_PAGE `
            -Instructions "Download the Windows tdm_installer from the page that just opened, then copy tdm_installer.exe into '$gamePath' and choose Retry." `
            -SkipMessage "Skipped - cannot continue without tdm_installer.exe." `
            -DestFolder $gamePath `
            -AllowSkip $false
    if ([string]$fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if (Test-Path $installerExe) {
        $haveInstaller = $true
    } else {
        Pause-User "tdm_installer.exe still not found in $gamePath. Press Enter to exit..."
        exit 1
    }
}
Write-OK "Installer placed: $installerExe"
try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}

# -------------------------------------------------------
# STEP 3: Copy the manifest URL + launch the TDM installer
# -------------------------------------------------------
Write-Step 3 5 "Run the TDM installer (custom VR version)"

# Put the VR manifest URL on the clipboard for a one-tap paste (like copying
# Steam launch options). The URL is mentioned exactly ONCE - inside step 4,
# where it is actually used. The steps are framed as a bold box so they read
# as THE thing to follow.
$clipOk = $false
try { Set-Clipboard -Value $VR_MANIFEST_URL -EA Stop; $clipOk = $true } catch {}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "    DO THESE STEPS IN THE TDM INSTALLER WINDOW" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "   1) Install directory should already be:" -ForegroundColor Gray
Write-Host "      $gamePath" -ForegroundColor Cyan
Write-Host "      (if not, click Browse and pick that folder)" -ForegroundColor Gray
Write-Host "   2) Tick the box '" -NoNewline -ForegroundColor Gray; Write-Host "Get custom version" -NoNewline -ForegroundColor Green; Write-Host "', then click Next." -ForegroundColor Gray
Write-Host "   3) In the version tree, select '" -NoNewline -ForegroundColor Gray; Write-Host "$BASE_VERSION" -NoNewline -ForegroundColor Green; Write-Host "' as the base." -ForegroundColor Gray
if ($clipOk) {
    Write-Host "   4) " -NoNewline -ForegroundColor Gray; Write-Host "[OK]" -NoNewline -ForegroundColor Green; Write-Host " Manifest URL copied to your clipboard ( " -NoNewline -ForegroundColor Gray; Write-Host $VR_MANIFEST_URL -NoNewline -ForegroundColor Cyan; Write-Host " )" -ForegroundColor Gray
    Write-Host "        Click into '" -NoNewline -ForegroundColor Gray; Write-Host "Custom manifest URL" -NoNewline -ForegroundColor Green; Write-Host "', press " -NoNewline -ForegroundColor Gray; Write-Host "Ctrl+V" -NoNewline -ForegroundColor Green; Write-Host " to paste, then click Next." -ForegroundColor Gray
} else {
    Write-Host "   4) " -NoNewline -ForegroundColor Gray; Write-Host "[!!]" -NoNewline -ForegroundColor Yellow; Write-Host " Clipboard blocked - copy this URL: " -NoNewline -ForegroundColor Gray; Write-Host $VR_MANIFEST_URL -ForegroundColor Cyan
    Write-Host "        Click into '" -NoNewline -ForegroundColor Gray; Write-Host "Custom manifest URL" -NoNewline -ForegroundColor Green; Write-Host "', paste it (" -NoNewline -ForegroundColor Gray; Write-Host "Ctrl+V" -NoNewline -ForegroundColor Green; Write-Host "), then click Next." -ForegroundColor Gray
}
Write-Host "   5) Confirm the non-official-build warning with " -NoNewline -ForegroundColor Gray; Write-Host "Continue" -NoNewline -ForegroundColor Green; Write-Host "," -ForegroundColor Gray
Write-Host "      then confirm the download summary with " -NoNewline -ForegroundColor Gray; Write-Host "Start" -NoNewline -ForegroundColor Green; Write-Host ". Let it finish." -ForegroundColor Gray
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Keep this window open - come back here once TDM has finished." -ForegroundColor DarkGray
Pause-User "Press Enter to LAUNCH the TDM installer now..."

$launched = $false
try {
    Start-Process -FilePath $installerExe -WorkingDirectory $gamePath
    $launched = $true
    Write-OK "TDM installer launched from $gamePath"
} catch {
    Write-Fail "Could not launch the installer: $($_.Exception.Message)"
}
if (-not $launched) {
    $fb = Invoke-InstallerFallback -Action "launch tdm_installer.exe" `
            -Instructions "Open '$gamePath' in Explorer and double-click tdm_installer.exe yourself, then come back. Choose Retry once it is running." `
            -SkipMessage "Skipped launching - you can still run tdm_installer.exe from the folder by hand." `
            -DestFolder $gamePath `
            -AllowSkip $true
    if ([string]$fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
}

Write-Host ""
Write-Warn "Finish the install in the TDM window first."
Pause-User "When The Dark Mod has finished installing, press Enter here..."

# -------------------------------------------------------
# STEP 4: Post-install - locate the VR exe, gamepad cfg, shortcut
# -------------------------------------------------------
Write-Step 4 5 "Finishing touches"

# The VR build's launcher. If the user installed somewhere else in the
# GUI, ask for that path so the shortcut + gamepad cfg land correctly.
$vrExePath = Join-Path $gamePath $VR_EXE
if (-not (Test-Path $vrExePath)) {
    Write-Warn "$VR_EXE not found in $gamePath."
    Write-Host "  If you chose a different install folder in the TDM installer," -ForegroundColor Gray
    Write-Host "  enter its full path now (or leave blank to skip the shortcut)." -ForegroundColor Gray
    $alt = (Read-Host " Install folder path").Trim().Trim('"')
    if ($alt -and (Test-Path (Join-Path $alt $VR_EXE))) {
        $gamePath = $alt
        $vrExePath = Join-Path $gamePath $VR_EXE
        Write-OK "Found $VR_EXE in $gamePath"
    } else {
        Write-Warn "Skipping shortcut + gamepad config (VR exe not located)."
    }
}

if (Test-Path $vrExePath) {
    # Sample gamepad config - TDM ships NO default pad layout, so without
    # this file the controller does nothing. Verbatim sample from the VR
    # mod docs; written only if the user has none (never overwrites).
    $padCfg = Join-Path $gamePath "DarkmodPadbinds.cfg"
    if (Test-Path $padCfg) {
        Write-Info "Existing DarkmodPadbinds.cfg found - keeping yours."
    } else {
        $padContent = @'
// DarkmodPadbinds.cfg - gamepad button mappings

// MODIFIER KEY
bindPadButton MODIFIER PAD_L2

// ATTACK
bindPadButton MOD_PRESS PAD_R2 "_attack"
bindPadButton MOD_PRESS PAD_R1 "_parry"
bindPadButton PRESS PAD_X "_attack"

// WEAPONS
bindPadButton MOD_LONG_PRESS PAD_UP "_weapon0"
bindPadButton MOD_PRESS PAD_UP "_weapon_next"
bindPadButton MOD_PRESS PAD_DOWN "_weapon_prev"
bindPadButton MOD_PRESS PAD_LEFT "_weapon1"
bindPadButton MOD_LONG_PRESS PAD_LEFT "_weapon2"
bindPadButton MOD_PRESS PAD_RIGHT "_weapon3"
bindPadButton MOD_LONG_PRESS PAD_RIGHT "_weapon4"

// MOVEMENT / INTERACTION
bindPadButton PRESS PAD_A "_jump"
bindPadButton PRESS PAD_B "_crouch"
bindPadButton LONG_PRESS PAD_B "_mantle"
bindPadButton PRESS PAD_L1 "_lean_left"
bindPadButton PRESS PAD_R1 "_lean_right"
bindPadButton PRESS PAD_L3 "_speed"
bindPadButton PRESS PAD_R2 "_frob"

// INVENTORY
bindPadButton PRESS PAD_Y "_inventory_use"
bindPadButton LONG_PRESS PAD_Y "_inventory_grid"
bindPadButton PRESS PAD_UP "_inventory_prev"
bindPadButton PRESS PAD_DOWN "_inventory_next"
// cycle keys
bindPadButton PRESS PAD_LEFT "inventory_cycle_group '#str_02392'"
// cycle picks
bindPadButton PRESS PAD_RIGHT "inventory_cycle_group '#str_02389'"
bindPadButton LONG_PRESS PAD_UP "inventory_hotkey ''"
bindPadButton LONG_PRESS PAD_DOWN "_inventory_drop"
// spyglass
bindPadButton LONG_PRESS PAD_R3 "inventory_use '#str_02396'"
// lantern
bindPadButton MOD_LONG_PRESS PAD_R3 "inventory_use '#str_02395'"

// MISC
bindPadButton PRESS PAD_BACK "_objectives"
bindPadButton LONG_PRESS PAD_BACK "savegame quick"
bindPadButton PRESS PAD_START "escape"
'@
        try {
            Set-Content -Path $padCfg -Value $padContent -Encoding ASCII -EA Stop
            Write-OK "Wrote sample gamepad config (DarkmodPadbinds.cfg) - edit it any time."
        } catch {
            Write-Warn "Could not write the gamepad config: $($_.Exception.Message)"
            Write-Host "  You can create '$padCfg' yourself later (see the VR wiki)." -ForegroundColor Gray
        }
    }

    # Desktop shortcut to the VR launcher.
    try {
        $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\$GAME_TITLE.lnk" -TargetPath $vrExePath -WorkingDir $gamePath -IconPath "$vrExePath,0"
        Write-OK "Desktop shortcut '$GAME_TITLE' created."
    } catch {
        Write-Warn "Could not create the shortcut: $($_.Exception.Message)"
        Write-Host "  Make one manually pointing to: $vrExePath" -ForegroundColor Gray
    }
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
# STEP 5: Summary
# -------------------------------------------------------
Write-Step 5 5 "Done"
Clear-Host
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " The Dark Mod VR - Setup Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Folder : $gamePath" -ForegroundColor White
Write-Host "  Launch :" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the desktop shortcut ($VR_EXE)" -ForegroundColor White
Write-Host ""
Write-Host "  Before you play:" -ForegroundColor White
Write-Host "   - Start SteamVR / your VR runtime first, then launch the game." -ForegroundColor Gray
Write-Host "   - If the menu overlay is missing or your head is in a wall," -ForegroundColor Gray
Write-Host "     reset your seated position (SteamVR: 'reset seated position';" -ForegroundColor Gray
Write-Host "     Oculus: recenter view)." -ForegroundColor Gray
Write-Host "   - Gamepad: the bindings live in DarkmodPadbinds.cfg (LT = modifier)." -ForegroundColor Gray
Write-Host ""
Write-Host "  More info: $INFO_URL" -ForegroundColor Gray
Write-Host ""
Write-Host "  Stay to the shadows, taffer - the City is watching." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
