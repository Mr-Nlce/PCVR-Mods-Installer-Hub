# ============================================================
# Richard Burns Rally - RBRvr Installer
# ============================================================

# Load installer-safety helpers (Invoke-DownloadOrFallback,
# Invoke-InstallerFallback, Expand-ArchiveOrFallback). These replace
# hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Richard Burns Rally VR Installer"
$ErrorActionPreference = "Stop"

$MOD_URL      = "https://junk.kegetys.fi/RBRvr16.zip"
$MOD_INFO_URL = "https://www.kegetys.fi/category/gaming/rbrmods/"
$GAME_EXE     = "RichardBurnsRally_SSE.exe"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Richard Burns Rally - RBRvr Installer" -ForegroundColor Cyan
    Write-Host " OpenVR / OpenXR mod by Kegetys" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$txt)
    Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host ""
}
function Write-OK   { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [XX] $t" -ForegroundColor Red }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# ---- Resolve the user's existing RBR install by the game EXE ----
# RBR is not sold on Steam/GOG/Epic - the user owns/installs it
# themselves - so we ask them to drag the game EXE onto this window to
# learn the exact install folder. Loops until a valid EXE is given or
# the user cancels.
function Get-RbrExePath {
    while ($true) {
        Write-Host ""
        Write-Host " Drag your $GAME_EXE onto this window and press Enter." -ForegroundColor Yellow
        Write-Host " (You can also type or paste the full path.)" -ForegroundColor Gray
        Write-Host " Leave empty and press Enter to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " Path"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path $p)) { Write-Warn "Path not found: $p"; continue }
        # Dragged the folder instead of the EXE? Look inside it.
        if (Test-Path $p -PathType Container) {
            $cand = Join-Path $p $GAME_EXE
            if (Test-Path $cand) { return $cand }
            Write-Warn "No $GAME_EXE in that folder. Drag the EXE itself."
            continue
        }
        if ((Split-Path -Leaf $p) -ieq $GAME_EXE) { return $p }
        # Wrong file but maybe the right folder next to it.
        $sib = Join-Path (Split-Path -Parent $p) $GAME_EXE
        if (Test-Path $sib) { return $sib }
        Write-Warn "That is not $GAME_EXE. Please drag the game's $GAME_EXE."
    }
}

Write-Header
Write-Host " This installs the RBRvr mod (OpenVR support) into your" -ForegroundColor White
Write-Host " EXISTING Richard Burns Rally installation." -ForegroundColor White
Write-Host ""
Write-Host " You PROVIDE YOUR OWN copy of Richard Burns Rally - this" -ForegroundColor Gray
Write-Host " installer downloads NO game files, only the free community" -ForegroundColor Gray
Write-Host " VR mod from kegetys.fi and copies it next to your game EXE." -ForegroundColor Gray
Write-Host ""
$go = Read-Host " Continue? (Y/N)"
if ($go -notmatch '^(y|yes|j|ja)$') { Write-Info "Cancelled."; Pause-User "Press Enter to exit..."; exit 0 }

# ---- STEP 1: locate the game ----
Write-Step 1 4 "Locating Richard Burns Rally"
$rbrExe = Get-RbrExePath
if (-not $rbrExe) { Write-Info "No game EXE provided - cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
$rbrDir = Split-Path -Parent $rbrExe
Write-OK "Game folder: $rbrDir"

# ---- STEP 2: download the VR mod ----
Write-Step 2 4 "Downloading the RBRvr mod"
$tempDir = Join-Path $env:TEMP ("rbrvr_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
try { New-Item -ItemType Directory -Force -Path $tempDir | Out-Null } catch {}
$modZip = Join-Path $tempDir "RBRvr16.zip"
$r = Invoke-DownloadOrFallback -Url $MOD_URL -Destination $modZip `
        -Label "RBRvr mod" `
        -ManualUrl $MOD_INFO_URL `
        -Instructions "Download 'RBRvr16.zip' from the kegetys.fi RBR mods page that just opened. Place it at '$modZip' and choose Retry." `
        -SkipMessage "Skipped - the RBRvr mod was not downloaded; the install is incomplete."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }

# ---- STEP 3: extract into the game folder ----
Write-Step 3 4 "Installing the mod files"
if (Test-Path $modZip) {
    $r = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $rbrDir -Label "RBRvr mod" `
            -SkipMessage "Skipped - the mod files were NOT extracted into the game folder."
    if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$r -eq "ok" -or [string]$r -eq "manual") { Write-OK "Mod files copied into the game folder." }
} else {
    Write-Warn "Mod archive not present - skipping extraction."
}

# Verify the VR-specific plugin landed.
$probe = Join-Path $rbrDir "Plugins\RBRvrConfig.dll"
if (Test-Path $probe) { Write-OK "RBRvr plugin verified." }
else { Write-Warn "RBRvrConfig.dll not found - check $rbrDir\Plugins\ manually (you can re-run with the correct game folder)." }

# ---- STEP 4: desktop shortcut ----
Write-Step 4 4 "Creating desktop shortcut"
try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "Richard Burns Rally VR.lnk"
    $sc = New-DesktopShortcut -LnkPath $lnk -TargetPath $rbrExe -WorkingDir $rbrDir -IconPath $rbrExe
    Write-OK "Desktop shortcut created: Richard Burns Rally VR"
} catch {
    Write-Warn "Could not create the desktop shortcut. You can start the game from $rbrExe."
}

# Record the install path for the Hub's VR-Ready detection.
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $rbrDir -Encoding UTF8 -Force } catch {}

# ---- Activation instructions (must stay visible) ----
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " ALMOST DONE - HOW TO PLAY AND ENABLE MOTION CONTROLLERS" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " 1) Start the game (" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, your headset," -ForegroundColor White
Write-Host "    or the new desktop" -ForegroundColor White
Write-Host "    shortcut). It is in the headset from the main menu on." -ForegroundColor White
Write-Host ""
Write-Host " 2) To use your motion controllers for steering, go to:" -ForegroundColor White
Write-Host "    Options -> Plugins -> RBRvr Configuration -> Vivedrive" -ForegroundColor White
Write-Host "    Press the RIGHT arrow key, then Enter, then leave" -ForegroundColor White
Write-Host "    the menu." -ForegroundColor White
Write-Host ""
Write-Host " 3) Render scale defaults to 200%. If you also raise the" -ForegroundColor Gray
Write-Host "    SteamVR pixel density you may hit performance limits;" -ForegroundColor Gray
Write-Host "    adjust render scale in-game or in rbrvr.cfg." -ForegroundColor Gray
Write-Host "    Windshield hider toggle: numpad asterisk (*)." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter once you have read the steps above..."

# ---- Signoff ----
Write-Host ""
Write-Host " Trust the pace notes, commit to the corner, and keep it pinned on the gravel." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
