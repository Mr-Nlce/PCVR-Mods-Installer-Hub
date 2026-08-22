# ============================================================
# Diddy Kong Racing VR Installer (DiddyKongRacing-VR by RaYRoD)
# ============================================================
# DiddyKongRacing-VR is a native OpenXR VR build of Golden Balloon,
# akratch's PC port of Diddy Kong Racing (N64, 1997). The whole game
# renders per eye with full head tracking; headset off, the same
# game runs flat.
#
# The user supplies their own ROM (US 1.1 or EU 1.1). RaYRoD-TV's
# own app asks for it once and remembers it - nothing from Nintendo
# is downloaded or shipped.
#
# THERE IS ONLY ONE ROUTE, and it is the same one the other RaYRoD
# entries take since 2026-08-18: his GitHub repo carries no builds
# ("No builds here, the hub is the one spot for all of it, source
# included"), so this installer fetches the Multiverse VR Hub, the
# user picks where it goes, and that exe is what "Start in VR"
# opens from then on. Install-MultiverseVRHub (InstallerSafety.ps1)
# does the download, verifies the SHA-256 out of the release note
# and writes nothing outside the chosen folder.
#
# Hence NO GithubRepo in the catalog and NO .installed_version:
# RaYRoD's app keeps itself up to date, so an update marker from
# us would be an empty promise.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Diddy Kong Racing VR Installer"

# ---- console helpers (each installer defines its own) -------
# DO NOT DELETE, even though they look unused here:
# Install-MultiverseVRHub in InstallerSafety.ps1 calls Write-OK and
# Write-Warn and needs them in the caller's scope.
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Diddy Kong Racing VR Installer" -ForegroundColor Cyan
    Write-Host " DiddyKongRacing-VR by RaYRoD | your own N64 ROM required" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

Write-Header

Write-Host "  Diddy Kong Racing (N64, 1997) in the headset: the whole game" -ForegroundColor Gray
Write-Host "  renders per eye with full head tracking, built on Golden" -ForegroundColor Gray
Write-Host "  Balloon, akratch's PC port. Four view modes - Third Person," -ForegroundColor Gray
Write-Host "  First Person, Diorama and Theater - and motion controllers" -ForegroundColor Gray
Write-Host "  mapped to the N64 pad. No headset connected? The same game" -ForegroundColor Gray
Write-Host "  runs flat." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    Diddy Kong Racing - US 1.1 or EU 1.1, a dump that you own." -ForegroundColor Yellow
Write-Host "  Nothing from Nintendo is downloaded or included. RaYRoD-TV's" -ForegroundColor Gray
Write-Host "  app asks for the ROM once and remembers it; it is read on your" -ForegroundColor Gray
Write-Host "  own PC and never leaves it." -ForegroundColor Gray
Pause-User "Press Enter to begin the installation or update..." | Out-Null

# ---- THE ONLY ROUTE: RaYRoD-TV's Multiverse VR Hub ------------
# His repo for this game carries NO releases - his README says it
# outright: "No builds here, the hub is the one spot for all of it,
# source included." A direct route via GitHub releases therefore
# cannot exist; there is only this one.
# WHY WE DECIDE THE LOCATION: his hub installs the games itself, to
# a place we would otherwise not know - we would know neither
# whether the game is installed nor what "Start in VR" should open.
# The user picks the folder, and exactly that exe is launched.
Write-Host ""
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " HOW THIS ONE IS INSTALLED" -ForegroundColor Cyan
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  RaYRoD-TV ships all of his VR ports through one small app of" -ForegroundColor White
Write-Host "  his own, the Multiverse VR Hub. There are no separate" -ForegroundColor White
Write-Host "  downloads any more - his words: the hub is the one spot for" -ForegroundColor White
Write-Host "  all of it." -ForegroundColor White
Write-Host ""
Write-Host "  So this installer fetches that app, you pick where it goes," -ForegroundColor White
Write-Host "  and Start in VR opens it from then on." -ForegroundColor White
Write-Host ""
$mvrhExe = Install-MultiverseVRHub
if ($mvrhExe) {
    # Start in VR points at HIS hub. We claim NOTHING about which
    # games live in there - we only bring the user back to the place
    # they started them from.
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value (Split-Path $mvrhExe -Parent) -Encoding UTF8 -Force } catch {}
    try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".launch_exe")     -Value $mvrhExe -Encoding UTF8 -Force } catch {}
    Write-Host ""
    Write-Host "  Open it, pick Diddy Kong Racing and hit Play - it fetches the" -ForegroundColor White
    Write-Host "  official Golden Balloon release, applies the VR patch itself" -ForegroundColor White
    Write-Host "  and asks for your ROM once." -ForegroundColor White
    Write-Host "  Start in VR in this Hub will open that app from now on." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  In the race: D-pad up cycles the four view modes, and the VR" -ForegroundColor Gray
    Write-Host "  options sit in the game's own pause menu - every knob moves" -ForegroundColor Gray
    Write-Host "  the world live, nothing needs a restart." -ForegroundColor Gray
    Write-Host "  See the README for the view modes, the VR menu and the cheats" -ForegroundColor Gray
    Write-Host "  page." -ForegroundColor Gray
    Write-Host ""
    try { Start-Process -FilePath $mvrhExe -WorkingDirectory (Split-Path $mvrhExe -Parent) } catch {}
}
Pause-User "Press Enter to exit."
exit 0
