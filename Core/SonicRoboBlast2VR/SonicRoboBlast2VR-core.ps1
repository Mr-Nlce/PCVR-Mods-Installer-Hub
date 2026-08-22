# ============================================================
# Sonic Robo Blast 2 VR - Full Game Installer (SRB2-VR)
# ============================================================
# SRB2-VR by RaYRoD-TV: a native OpenXR port of Sonic Robo Blast 2,
# forked from the CURRENT official release (STJr/SRB2 2.2.15). Runs
# on any conformant OpenXR runtime (SteamVR, Virtual Desktop VDXR,
# Meta, Pimax). Full VR controller support via the OpenXR action
# system; a regular gamepad and mouse/keyboard still work too.
#
# This is a FULL free fan game: the release bundle ships the game
# plus all its freely distributed 2.2.15 assets. One download,
# unzip, play - headset on = VR, headset off = regular SRB2.
#
# The Hub tracks updates via the GitHub latest-release tag (the
# catalog's GithubRepo field); this installer records the EXACT
# tag_name in .installed_version so the two always compare cleanly.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Sonic Robo Blast 2 VR Installer"
$ErrorActionPreference = "Stop"

$INSTALL_ROOT      = "C:\Games\Sonic Robo Blast 2 VR"
$GAME_EXE          = "srb2win.exe"
# Pinned direct link as a network fallback if the API is rate-limited.
$ASSET_NAME        = "SRB2-VR-full-win64.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host " Sonic Robo Blast 2 VR - Full Game Installer" -ForegroundColor Cyan
 Write-Host " SRB2-VR (OpenXR) by RaYRoD-TV - game by Sonic Team Junior" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host ""
}

function Write-Step {
 param($num, $total, $text)
 Write-Host ""
 Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
 Write-Host ""
}

function Write-OK { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }

function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

Write-Header

# -------------------------------------------------------
# STEP 1: Install location (update / reinstall handling)
# -------------------------------------------------------
Write-Host " SRB2-VR (OpenXR) by RaYRoD-TV - the free fan platformer Sonic Robo" -ForegroundColor White
Write-Host " Blast 2 in VR. This installs the full standalone game." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."

# ---- THE ONLY ROUTE: RaYRoD-TV's Multiverse VR Hub ------------
# On 2026-08-18 RaYRoD-TV wiped the releases from ALL six of his VR
# port repos. His README says it outright: "Nothing to download here
# anymore, no PC builds & no Quest builds. The hub is the one place
# it all lives now." A direct route via GitHub releases CANNOT work
# any more and has been removed - a choice between a dead route and a
# living one would be no choice at all.
# WHY WE DECIDE THE LOCATION: his hub installs the games itself, to
# a place we would not otherwise know - we would know neither whether
# the game is installed nor what "Start in VR" should open.
# The user picks the folder, and exactly that exe is launched.
Write-Host ""
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " HOW THIS ONE IS INSTALLED" -ForegroundColor Cyan
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  RaYRoD-TV ships all of his VR ports through one small app of" -ForegroundColor White
Write-Host "  his own, the Multiverse VR Hub. There are no separate" -ForegroundColor White
Write-Host "  downloads any more - his words: the hub is the one place it" -ForegroundColor White
Write-Host "  all lives now." -ForegroundColor White
Write-Host ""
Write-Host "  So this installer fetches that app, you pick where it goes," -ForegroundColor White
Write-Host "  and Start in VR opens it from then on." -ForegroundColor White
Write-Host ""
$mvrhExe = Install-MultiverseVRHub
    if ($mvrhExe) {
        # Start in VR points at HIS hub. We claim NOTHING about
        # which games live in there - we only bring the user back to the
        # place they started them from.
        try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value (Split-Path $mvrhExe -Parent) -Encoding UTF8 -Force } catch {}
        try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".launch_exe")     -Value $mvrhExe -Encoding UTF8 -Force } catch {}
        Write-Host ""
        Write-Host "  Open it, pick Sonic Robo Blast 2 and hit Play - it fetches the" -ForegroundColor White
        Write-Host "  official port and applies the VR patch itself." -ForegroundColor White
        Write-Host "  Start in VR in this Hub will open that app from now on." -ForegroundColor Gray
        Write-Host ""
        try { Start-Process -FilePath $mvrhExe -WorkingDirectory (Split-Path $mvrhExe -Parent) } catch {}
    }
Pause-User "Press Enter to exit."
    exit 0
