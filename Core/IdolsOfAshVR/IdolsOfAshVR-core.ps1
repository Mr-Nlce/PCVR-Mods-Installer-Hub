# ============================================================
# Idols of Ash VR Installer
# LXE97 / UGVR-IdolsOfAsh (Universal Godot VR Injector fork)
# https://github.com/LXE97/UGVR-IdolsOfAsh
# The mod extracts INTO the game folder (next to
# idols_of_ash.exe): xr_injector\, XRConfigs\, override.cfg.
# OpenXR with motion controls incl. the grappling hook.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Idols of Ash VR Installer"
$ErrorActionPreference = "Stop"

$REPO_URL   = "https://github.com/LXE97/UGVR-IdolsOfAsh"
$MOD_ZIP    = "https://github.com/LXE97/UGVR-IdolsOfAsh/releases/download/v2.1.0/UGVR-IdolsOfAsh-v2.1.0.zip"
$GAME_EXE   = "idols_of_ash.exe"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Idols of Ash VR Installer" -ForegroundColor Cyan
    Write-Host " UGVR Injector by LXE97 - OpenXR with motion controls" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [XX] $t" -ForegroundColor Red }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

Write-Header
Write-Host " This installs the UGVR Injector mod into your EXISTING Idols" -ForegroundColor White
Write-Host " of Ash install (Steam or itch.io). The free mod is downloaded" -ForegroundColor Gray
Write-Host " from the modder's GitHub. Works with game versions 1.30-1.32." -ForegroundColor Gray
Write-Host ""

# ---- STEP 1: find the game ----
Pause-User "Press Enter to start..."
Write-Step 1 4 "Finding Idols of Ash"
$gameDir = $null
$candidates = @()
# Steam (all library folders via the shared helper) ...
try {
    $sf = Find-SteamGameFolder -AppId "4450800" -SteamFolderNames @("IdolsOfAsh") -ProbeExe $GAME_EXE
    if ($sf) { $candidates += $sf }
} catch {}
$candidates += "C:\Program Files (x86)\Steam\steamapps\common\IdolsOfAsh"
# ... and the itch.io app install location.
try {
    $apRoot = [Environment]::GetFolderPath("ApplicationData")
    $candidates += (Join-Path $apRoot "itch\apps\idols-of-ash")
} catch {}
foreach ($c in $candidates) {
    if ($c -and (Test-Path -LiteralPath (Join-Path $c $GAME_EXE))) { $gameDir = $c; break }
}
if ($gameDir) {
    Write-OK "Found: $gameDir"
} else {
    Write-Warn "Could not auto-detect the game (Steam / itch app paths checked)."
    Write-Host "  Drag your Idols of Ash FOLDER (the one with $GAME_EXE) onto" -ForegroundColor White
    Write-Host "  this window and press Enter." -ForegroundColor White
    while (-not $gameDir) {
        $raw = Read-Host "  Game folder (empty to cancel)"
        if ([string]::IsNullOrWhiteSpace($raw)) { Write-Info "Cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
        $pth = $raw.Trim().Trim('"').Trim("'")
        if ((Test-Path -LiteralPath $pth) -and (Test-Path -LiteralPath (Join-Path $pth $GAME_EXE))) {
            $gameDir = $pth
        } else {
            Write-Warn "No $GAME_EXE in that folder - try again."
        }
    }
    Write-OK "Using: $gameDir"
$null = Show-UpdateNoticeIfInstalled -TargetDir $gameDir -RelModFile "xr_injector\xr_injector.gd" -Label "UGVR Injector"
}

# ---- STEP 2: protect an existing override.cfg ----
Write-Step 2 4 "Checking for other mods"
$ovr = Join-Path $gameDir "override.cfg"
$hadOverride = Test-Path -LiteralPath $ovr
if ($hadOverride) {
    # The mod zip ships its own override.cfg and extracting would clobber
    # a config another mod created. Keep a backup and tell the user how
    # to merge (autoload_prepend section) afterwards.
    try {
        Copy-Item -LiteralPath $ovr -Destination (Join-Path $gameDir "override.cfg.pre-ugvr.backup") -Force
        Write-Warn "An override.cfg already exists (another mod?)."
        Write-Host "  Saved a backup: override.cfg.pre-ugvr.backup" -ForegroundColor Gray
        Write-Host "  If you use other mods, merge their autoload lines into the" -ForegroundColor Gray
        Write-Host "  new override.cfg after this install (see the README)." -ForegroundColor Gray
        Pause-User "Press Enter to continue with the install..."
    } catch {
        Write-Warn "Could not back up override.cfg - continuing; merge manually if needed."
    }
} else {
    Write-OK "No existing override.cfg - clean install."
}

# ---- STEP 3: download + extract into the game folder ----
Write-Step 3 4 "Downloading and installing the mod"
$tmpZip = Join-Path $env:TEMP "UGVR-IdolsOfAsh.zip"
$r = Invoke-SafeDownload -Urls @($MOD_ZIP) -Destination $tmpZip -Label "UGVR Injector" `
        -ManualUrl "$REPO_URL/releases/latest" `
        -SkipMessage "Skipped - the mod was NOT downloaded. Nothing was changed."
# Invoke-SafeDownload returns $true on success (NOT "ok") and the
# fallback verbs otherwise - only quit/skip end the flow, anything
# else means the file is there. Belt and braces: verify the zip on
# disk before extracting.
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$r -eq "skip") { Write-Warn "Skipped - nothing was changed."; Pause-User "Press Enter to exit..."; exit 0 }
if (-not (Test-Path -LiteralPath $tmpZip)) {
    Write-Fail "Download finished without a file at $tmpZip - cannot continue."
    Pause-User "Press Enter to exit..."; exit 1
}

# Payload-verified extract (releases/LATEST - layout can change any day).
$r2 = Expand-ArchiveToTarget -ArchivePath $tmpZip -TargetDir $gameDir -RelModFile "xr_injector\xr_injector.gd" -Label "UGVR Injector" `
        -SkipMessage "Skipped - the mod files were NOT extracted."
if ([string]$r2 -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
try { Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue } catch {}

if (Test-Path -LiteralPath (Join-Path $gameDir "xr_injector\xr_injector.gd")) {
    Write-OK "Mod files in place (xr_injector, XRConfigs, override.cfg)."
} else {
    Write-Warn "xr_injector folder not found after extraction - check $gameDir manually."
}
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}

# ---- STEP 4: how to play ----
Write-Step 4 4 "How to play"
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " UGVR Injector - HOW TO PLAY" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " 1) Connect your headset AND controllers - they must be awake" -ForegroundColor White
Write-Host "    BEFORE the game starts." -ForegroundColor White
Write-Host " 2) Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or normally" -ForegroundColor White
Write-Host "    (Steam / itch / game exe)." -ForegroundColor White
Write-Host "    The injector loads by itself - no launcher, no extra step." -ForegroundColor White
Write-Host ""
Write-Host " Nice to know:" -ForegroundColor Gray
Write-Host " - Grappling hook works with the motion controllers (grip to" -ForegroundColor Gray
Write-Host "   throw, joystick click to ascend/descend the rope)." -ForegroundColor Gray
Write-Host " - Compass: hold the right controller palm-up at shoulder" -ForegroundColor Gray
Write-Host "   height; Interact toggles it, Sprint switches its mode." -ForegroundColor Gray
Write-Host " - Height calibration: hold the right controller over your" -ForegroundColor Gray
Write-Host "   head and click the joystick (again to reset)." -ForegroundColor Gray
Write-Host " - All settings live in the XRConfigs folder (world scale," -ForegroundColor Gray
Write-Host "   hand models, haptics - see the README on the game page)." -ForegroundColor Gray
Write-Host ""
Write-Host " To turn the headset mode off: put a ; in front of the" -ForegroundColor Gray
Write-Host " XRInjector line in override.cfg. To remove the mod, delete" -ForegroundColor Gray
Write-Host " the xr_injector folder." -ForegroundColor Gray
# ---- Signoff ----
Write-Host ""
Write-Host " Sling the hook, swing the ash - the idols are waiting." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
