# =============================================================
#  Breath of the Wild VR - remove BetterVR (and optionally Cemu)
# =============================================================
# WHAT IS WHERE. This installer never touched a game folder: it built a
# self-contained setup under Games\Breath of the Wild VR, holding Cemu,
# the graphic packs and BetterVR_Launcher.exe side by side.
#
# So there are two very different things to remove, and they are asked
# for separately:
#   - BetterVR alone: the launcher and the BetterVR graphic packs. Cemu,
#     your Wii U game files, your saves and your other graphic packs all
#     stay. This is what you want after a bad update.
#   - The whole folder: Cemu included. THAT ALSO TAKES YOUR CEMU SAVES
#     if Cemu was set up as portable here, which this installer does -
#     so it is asked separately and never by accident.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

# Word for word the same as in BreathOfTheWildVR-core.ps1.
function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$LAUNCHER = "BetterVR_Launcher.exe"
$SHORTCUT = "Breath of the Wild VR.lnk"
$ICON     = "BotW_VR.ico"

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Breath of the Wild VR - Uninstall" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""

# ---- Where is it? -------------------------------------------
# The Hub records the folder; fall back to the default location the
# installer uses, then ask.
$installRoot = $null
# The installer writes the folder into .installed_path beside itself
# (BreathOfTheWildVR-core.ps1, near the end). Read it, do not guess.
$recorded = $null
try {
    $rp = Join-Path $PSScriptRoot ".installed_path"
    if (Test-Path -LiteralPath $rp) { $recorded = (Get-Content -LiteralPath $rp -Raw -ErrorAction Stop).Trim() }
} catch {}

foreach ($cand in @(
    $recorded,
    'C:\Games\Breath of the Wild VR', 'D:\Games\Breath of the Wild VR', 'E:\Games\Breath of the Wild VR',
    (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Games\Breath of the Wild VR"),
    (Join-Path $env:USERPROFILE "Games\Breath of the Wild VR")
)) {
    if ($cand -and (Test-Path -LiteralPath (Join-Path $cand "Cemu.exe"))) { $installRoot = $cand; break }
    if ($cand -and (Test-Path -LiteralPath (Join-Path $cand $LAUNCHER)))  { $installRoot = $cand; break }
}
if (-not $installRoot) {
    Write-Warn "Could not find the setup automatically."
    $installRoot = (Read-Host "  Paste the folder that holds Cemu.exe (or press Enter to exit)").Trim().Trim('"')
    if (-not $installRoot -or -not (Test-Path -LiteralPath $installRoot)) {
        Write-Info "Nothing was changed."
        Pause-User "Press Enter to exit."
        exit 0
    }
}
$installRoot = [IO.Path]::GetFullPath($installRoot).TrimEnd('\')
$rootItem = Get-Item -LiteralPath $installRoot -Force
if ((Split-Path $installRoot -Leaf) -ne 'Breath of the Wild VR' -or ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
    -not ((Test-Path -LiteralPath "$installRoot\Cemu.exe" -PathType Leaf) -or (Test-Path -LiteralPath "$installRoot\$LAUNCHER" -PathType Leaf))) { throw 'Not a recognized BotW VR installation. Nothing was deleted.' }
Write-OK "Found: $installRoot"
Write-Host ""

# ---- Running? -----------------------------------------------
# Cemu holds the launcher's DLL open, so a delete would stop halfway and
# leave a folder that looks installed but is not.
$running = @(Get-Process -Name "Cemu", "BetterVR_Launcher" -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) {
    Write-Warn "Cemu or the BetterVR launcher is running. Close it, then run this again."
    Pause-User "Press Enter to exit."
    exit 1
}

Write-Host "  1. Remove BetterVR only" -ForegroundColor White
Write-Host "     The launcher and the BetterVR graphic packs. Cemu, your game" -ForegroundColor Gray
Write-Host "     files, your saves and other graphic packs stay." -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Remove everything" -ForegroundColor White
Write-Host "     The whole folder including Cemu. " -NoNewline -ForegroundColor Gray
Write-Host "This also deletes the Cemu " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "     saves kept in this folder, because it was set up portable." -ForegroundColor Gray
Write-Host ""

$pick = ""
for ($k = 1; $k -le 20; $k++) {
    $pick = ("" + (Read-Host "  Enter 1, 2, or c to cancel")).Trim().ToLower()
    if ($pick -in @("1","2","c")) { break }
    Write-Host "  Please answer 1, 2 or c." -ForegroundColor Yellow
}
if ($pick -notin @('1','2')) {
    Write-Info "Nothing was changed."
    Pause-User "Press Enter to exit."
    exit 0
}

$removed = 0

if ($pick -eq "2") {
    Write-Host ""
    $sure = ("" + (Read-Host "  This deletes $installRoot and everything in it. Type DELETE to confirm")).Trim()
    if ($sure -cne "DELETE") {
        Write-Info "Not confirmed - nothing was changed."
        Pause-User "Press Enter to exit."
        exit 0
    }
    try {
        Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction Stop
        Write-OK "Removed: $installRoot"
        $removed++
    } catch {
        Write-Fail "Could not remove it: $($_.Exception.Message)"
        Write-Host "  Close anything using the folder and delete it by hand." -ForegroundColor Gray
        Pause-User 'Press Enter to exit; installation records were kept.'
        exit 1
    }
} else {
    # BetterVR only: the launcher plus the packs it added. Everything
    # else in graphicPacks came from the community pack and stays.
    foreach ($f in @($LAUNCHER, "BetterVR_log.txt")) {
        $p = Join-Path $installRoot $f
        if (Test-Path -LiteralPath $p) {
            try { Remove-Item -LiteralPath $p -Force -ErrorAction Stop; Write-OK "Removed $f"; $removed++ }
            catch { Write-Warn "Could not remove $f" }
        }
    }
    $gpDir = Join-Path $installRoot "graphicPacks"
    if (Test-Path -LiteralPath $gpDir) {
        # Only the mod's own packs - matched by name, so the community
        # packs beside them are left alone.
        foreach ($pack in @(Get-ChildItem -LiteralPath $gpDir -Directory -ErrorAction SilentlyContinue |
                            Where-Object { $_.Name -match '(?i)bettervr' })) {
            try { Remove-Item -LiteralPath $pack.FullName -Recurse -Force -ErrorAction Stop; Write-OK "Removed graphic pack: $($pack.Name)"; $removed++ }
            catch { Write-Warn "Could not remove $($pack.Name)" }
        }
    }
    Write-Host ""
    Write-Info "Cemu, your game files and your saves were left untouched."
    if (Test-Path -LiteralPath (Join-Path $installRoot $LAUNCHER)) { throw 'BetterVR could not be removed; installation records were kept.' }
    $stamp = Join-Path $installRoot '.pcvrhub_version'
    if (Test-Path -LiteralPath $stamp) { Remove-Item -LiteralPath $stamp -Force }
}

# ---- Shortcut, icon, Hub records -----------------------------
$lnk = Join-Path ([Environment]::GetFolderPath("Desktop")) $SHORTCUT
if (Test-Path -LiteralPath $lnk) {
    try { Remove-Item -LiteralPath $lnk -Force -ErrorAction Stop; Write-OK "Removed the Desktop shortcut."; $removed++ }
    catch { Write-Warn "Could not remove the Desktop shortcut - delete it by hand." }
}
if ($pick -eq "1") {
    $ico = Join-Path $installRoot $ICON
    if (Test-Path -LiteralPath $ico) { try { Remove-Item -LiteralPath $ico -Force -ErrorAction SilentlyContinue } catch {} }
}
foreach ($rec in @(".installed_version", ".installed_path")) {
    $p = Join-Path $PSScriptRoot $rec
    if (Test-Path -LiteralPath $p) { try { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue } catch {} }
}

Write-Host ""
if ($removed -gt 0) { Write-OK "Done." } else { Write-Info "Nothing was left to remove." }
Write-Host ""
if ($pick -eq '1') {
    Write-Host '  Your Wii U game files and Cemu saves were kept.' -ForegroundColor Gray
} else {
    Write-Host '  The installation folder and everything inside it were removed.' -ForegroundColor Gray
    Write-Host '  Game files stored outside that folder were not changed.' -ForegroundColor Gray
}
Write-Host ""
Pause-User "Press Enter to exit."
