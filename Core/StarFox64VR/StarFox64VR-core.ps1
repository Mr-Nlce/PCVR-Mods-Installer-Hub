# ============================================================
# Star Fox 64 VR Installer (Star Fox 64 VR, by RaYRoD)
# ============================================================
# Star Fox 64 VR brings Star Fox 64 into VR, built on the Starship
# PC port. Same exe runs VR (headset connected) or flat (no headset).
# This installer downloads the latest Star Fox 64 VR release from GitHub
# and unpacks it to C:\Games\Star Fox 64 VR (or a folder you pick).
#
# The user supplies their own Star Fox 64 US .z64 ROM, placed as
# their Star Fox 64 US .z64 ROM, selected via a file picker on first
# launch. No game ROM is downloaded or shipped.
#
# Install layout:
#   <install_root>\Star Fox 64 VR\Starship.exe
#   default install_root: C:\Games (fallback D:\Games, E:\Games)
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Star Fox 64 VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Star Fox 64 VR Installer" -ForegroundColor Cyan
    Write-Host " Star Fox 64 VR by RaYRoD | Star Fox 64 US ROM required" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR        = Split-Path -Parent $MyInvocation.MyCommand.Path
$INFO_URL          = "https://github.com/RaYRoD-TV/StarFox64-VR"
# Last-known-good asset, used only if the GitHub API cannot be reached.
# (The API path above always prefers the newest release.)
$GAME_FOLDER       = "Star Fox 64 VR"
$GAME_EXE          = "Starship.exe"
$DEFAULT_ROOTS     = @("C:\Games", "D:\Games", "E:\Games")

# Resolve the newest Starship*.zip asset via the GitHub API. Returns the
# browser_download_url, or $null on any failure (rate limit / offline /
# shape change) - the caller then falls back to the known URL + manual link.

Write-Header

Write-Host "  Star Fox 64 VR brings Star Fox 64 into immersive VR, built on" -ForegroundColor Gray
Write-Host "  the Starship PC port. With a headset on, the game renders in" -ForegroundColor Gray
Write-Host "  VR and you can lean around and look into the world. With no" -ForegroundColor Gray
Write-Host "  headset it just runs as the normal flat game - same exe, it" -ForegroundColor Gray
Write-Host "  works out which one you want on its own. VR work by RaYRoD." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    Star Fox 64 - US (NTSC) .z64 ROM that you own." -ForegroundColor Yellow
Write-Host "  Nothing from Nintendo is downloaded or included - only the" -ForegroundColor Gray
Write-Host "  Star Fox 64 VR app is fetched (from the official GitHub releases)." -ForegroundColor Gray
Write-Host "  The game reads the ROM locally and it never leaves your PC." -ForegroundColor Gray
Write-Host ""
Write-Host "  Tested on Quest 3 and Pimax Dream Air, but it should run with" -ForegroundColor Gray
Write-Host "  any PCVR / OpenXR runtime." -ForegroundColor Gray
Pause-User "Press Enter to begin the installation or update..." | Out-Null

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
        Write-Host "  Open it, pick Star Fox 64 and hit Play - it fetches the" -ForegroundColor White
        Write-Host "  official port and applies the VR patch itself." -ForegroundColor White
        Write-Host "  Start in VR in this Hub will open that app from now on." -ForegroundColor Gray
        Write-Host ""
        try { Start-Process -FilePath $mvrhExe -WorkingDirectory (Split-Path $mvrhExe -Parent) } catch {}
    }
Pause-User "Press Enter to exit."
    exit 0
