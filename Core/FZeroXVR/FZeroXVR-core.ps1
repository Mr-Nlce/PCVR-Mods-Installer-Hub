# ============================================================
# F-Zero X VR Installer (FZeroX-VR by RaYRoD)
# ============================================================
# FZeroX-VR is a VR build of G-Diffuser, Zorkats' native PC port
# of F-Zero X (N64, 1998). 6DoF, Quest Touch support and two
# camera modes on the right stick.
#
# The user supplies their own ROM: an unmodified 16 MiB US Rev 0
# dump. RaYRoD-TV's own app asks for it once and the game sets
# itself up from there - nothing from Nintendo is downloaded or
# shipped.
#
# THERE IS ONLY ONE ROUTE, same as every other RaYRoD entry: his
# repo carries no builds ("No builds here, the hub is the one spot
# for all of it, source included"), so this installer fetches the
# Multiverse VR Hub, the user picks where it goes, and that exe is
# what "Start in VR" opens from then on. Install-MultiverseVRHub
# (InstallerSafety.ps1) downloads it, verifies the SHA-256 out of
# the release note and writes nothing outside the chosen folder.
#
# Hence NO GithubRepo in the catalog and NO .installed_version:
# RaYRoD's app keeps itself up to date, so an update marker from
# us would be an empty promise.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "F-Zero X VR Installer"

# ---- console helpers (each installer defines its own) -------
# DO NOT DELETE, even though they look unused here:
# Install-MultiverseVRHub in InstallerSafety.ps1 calls Write-OK and
# Write-Warn and needs them in the caller's scope.
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " F-Zero X VR Installer" -ForegroundColor Cyan
    Write-Host " FZeroX-VR by RaYRoD | your own N64 ROM required" -ForegroundColor Gray
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

Write-Host "  F-Zero X (N64, 1998) in the headset: real stereo at 900 km/h" -ForegroundColor Gray
Write-Host "  with 6DoF head tracking and the whole circuit drawn out to the" -ForegroundColor Gray
Write-Host "  horizon, built on G-Diffuser, Zorkats' native PC port. Quest" -ForegroundColor Gray
Write-Host "  Touch is supported, and the right stick switches between the" -ForegroundColor Gray
Write-Host "  two camera modes." -ForegroundColor Gray
Write-Host ""
Write-Host "  YOU MUST PROVIDE YOUR OWN GAME ROM:" -ForegroundColor White
Write-Host "    F-Zero X - unmodified 16 MiB US Rev 0, a dump that you own." -ForegroundColor Yellow
Write-Host "  Other regions, other revisions and ROM hacks are not supported" -ForegroundColor Gray
Write-Host "  and may not work. Nothing from Nintendo is downloaded or" -ForegroundColor Gray
Write-Host "  included - RaYRoD-TV's app asks for the ROM once and the game" -ForegroundColor Gray
Write-Host "  sets itself up from there, on your own PC." -ForegroundColor Gray
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
    Write-Host "  Open it, pick F-Zero X and hit Play - it fetches the official" -ForegroundColor White
    Write-Host "  G-Diffuser release, applies the VR patch itself and asks for" -ForegroundColor White
    Write-Host "  your ROM once." -ForegroundColor White
    Write-Host "  Start in VR in this Hub will open that app from now on." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  In the race: the right stick switches the two camera modes," -ForegroundColor Gray
    Write-Host "  and the VR settings menu moves the world live while you drag" -ForegroundColor Gray
    Write-Host "  a slider - nothing needs a restart." -ForegroundColor Gray
    Write-Host "  See the README for the ROM details and the camera modes." -ForegroundColor Gray
    Write-Host ""
    try { Start-Process -FilePath $mvrhExe -WorkingDirectory (Split-Path $mvrhExe -Parent) } catch {}
}
Pause-User "Press Enter to exit."
exit 0
