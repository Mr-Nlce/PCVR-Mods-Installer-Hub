# ============================================================
# Banjo-Kazooie VR Installer (BanjoKazooie-VR by RaYRoD)
# ============================================================
# BanjoKazooie-VR is a native OpenXR VR build of Lighthouse, the
# Harbour Masters PC port of Banjo-Kazooie (N64, 1998). The whole
# game renders per eye with head tracking; the same exe runs flat
# when no headset answers (--vr / --novr force either way).
#
# The user supplies their own Banjo-Kazooie ROM (.z64). On first
# launch the extraction wizard reads it once and builds bk.o2r -
# nothing from Nintendo is downloaded or shipped.
#
# Install layout:
#   <install_root>\Banjo-Kazooie VR\Lighthouse.exe
#   default install_root: C:\Games (fallback D:\Games, E:\Games)
#
# The release ZIP is FLAT (Lighthouse.exe in the zip root).
# Expand-ArchiveToTarget also survives a future wrapper folder.
#
# The Hub tracks updates via the GitHub latest-release tag (the
# catalog's GithubRepo field); this installer records the EXACT
# tag_name in .installed_version so the two compare cleanly.
#
# NOTE ON THE GRAPHICS BACKEND: the exe forces the OpenGL backend
# itself when VR is requested (OpenXR binds to WGL) - there is no
# backend setting for the user to change.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Banjo-Kazooie VR Installer"

# ---- console helpers (each installer defines its own) -------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Banjo-Kazooie VR Installer" -ForegroundColor Cyan
    Write-Host " BanjoKazooie-VR by RaYRoD | your own N64 .z64 ROM required" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR         = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO               = "RaYRoD-TV/BanjoKazooie-VR"
$REPO_API           = "https://api.github.com/repos/$REPO/releases"
$RELEASES_PAGE      = "https://github.com/$REPO/releases"
# Last-known-good asset, used only if the GitHub API cannot be reached.
$GAME_FOLDER        = "Banjo-Kazooie VR"
$GAME_EXE           = "Lighthouse.exe"
$DEFAULT_ROOTS      = @("C:\Games", "D:\Games", "E:\Games")

# Resolve the newest release zip via the GitHub API. Returns
# @{ Url=...; Tag=... } or $null on any failure (rate limit / offline /
# shape change) - the caller then falls back to the pinned URL.

Write-Header

Write-Host "  Banjo-Kazooie (N64, 1998) in the headset: the whole game renders" -ForegroundColor Gray
Write-Host "  per eye with head tracking, built on Lighthouse, the Harbour" -ForegroundColor Gray
Write-Host "  Masters PC port. Four view modes - Third Person, First Person," -ForegroundColor Gray
Write-Host "  Diorama and Theater - and motion controllers mapped to the N64" -ForegroundColor Gray
Write-Host "  pad. No headset connected? The same exe runs the flat game." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    Banjo-Kazooie - US (NTSC) 1.0 .z64 ROM that you own." -ForegroundColor Yellow
Write-Host "  Nothing from Nintendo is downloaded or included - only the" -ForegroundColor Gray
Write-Host "  BanjoKazooie-VR app is fetched (from the official GitHub" -ForegroundColor Gray
Write-Host "  releases). The game reads the ROM locally and it never leaves" -ForegroundColor Gray
Write-Host "  your PC." -ForegroundColor Gray
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
        Write-Host "  Open it, pick Banjo-Kazooie and hit Play - it fetches the" -ForegroundColor White
        Write-Host "  official port and applies the VR patch itself." -ForegroundColor White
        Write-Host "  Start in VR in this Hub will open that app from now on." -ForegroundColor Gray
        Write-Host ""
        try { Start-Process -FilePath $mvrhExe -WorkingDirectory (Split-Path $mvrhExe -Parent) } catch {}
    }
Pause-User "Press Enter to exit."
    exit 0
