# ============================================================
# Mario Kart 64 VR - Installer (SpaghettiKart VR by RaYRoD)
# ============================================================
# Mario Kart 64 in PCVR, built on SpaghettiKart (the Mario Kart 64
# PC port). Headset on = sitting in the kart in stereo 3D with full
# head tracking; no headset = the same game runs flat.
#
# The user supplies their own Mario Kart 64 US .z64 ROM. Spaghettify
# itself asks for the ROM once on first launch - this installer only
# explains what is needed. No game ROM is downloaded or shipped.
#
# Update badge: the Hub compares the GitHub latest tag (GithubRepo in
# the catalog) against .installed_version, which this installer
# writes VERBATIM from tag_name.
#
# Optional step: the MK64 Reloaded HD texture pack by GhostlyDark
# (.o2r file into a mods folder next to Spaghettify.exe - loads as a
# mod, no rebuild needed).
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Mario Kart 64 VR Installer"
$ErrorActionPreference = "Stop"

$INSTALL_ROOT      = "C:\Games\Mario Kart 64 VR"
$GAME_EXE          = "Spaghettify.exe"
# HD texture pack (optional): MK64 Reloaded by GhostlyDark. Must be
# the .o2r asset; there are two SpaghettiKart variants (sk-4k and
# sk-hd) - we prefer 4k, matching the recommended build.
$HD_API_LATEST     = "https://api.github.com/repos/GhostlyDark/MK64-Reloaded/releases/latest"
$HD_RELEASES       = "https://github.com/GhostlyDark/MK64-Reloaded/releases/latest"
$HD_PINNED_URL     = "https://github.com/GhostlyDark/MK64-Reloaded/releases/download/v2026.04.03/mk64-reloaded-v2026.04.03-sk-4k.o2r"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host " Mario Kart 64 VR - Installer" -ForegroundColor Cyan
 Write-Host " SpaghettiKart VR by RaYRoD | Mario Kart 64 US ROM required" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Blue
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host " [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

Write-Header
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    Mario Kart 64 - US version, .z64 format, that you own." -ForegroundColor Yellow
Write-Host "    SHA-1: 579C48E211AE952530FFC8738709F078D5DD215E" -ForegroundColor Gray
Write-Host "    (.n64 dump? Convert it: https://hack64.net/tools/swapper.php)" -ForegroundColor Gray
Write-Host "  The game asks for the ROM ONCE on first launch; it is read" -ForegroundColor Gray
Write-Host "  locally and never leaves your PC. No ROM = nothing to install" -ForegroundColor Gray
Write-Host "  here will run, so have it ready." -ForegroundColor Gray

# -------------------------------------------------------
# STEP 1: Install location (update / reinstall handling)
# -------------------------------------------------------
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
        Write-Host "  Open it, pick Mario Kart 64 and hit Play - it fetches the" -ForegroundColor White
        Write-Host "  official port and applies the VR patch itself." -ForegroundColor White
        Write-Host "  Start in VR in this Hub will open that app from now on." -ForegroundColor Gray
        Write-Host ""
        try { Start-Process -FilePath $mvrhExe -WorkingDirectory (Split-Path $mvrhExe -Parent) } catch {}
    }
Pause-User "Press Enter to exit."
    exit 0
