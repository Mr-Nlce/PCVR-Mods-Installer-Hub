# =============================================================
#  Silent Hill VR - uninstall
# =============================================================
# Everything this installer created lives in one folder of its own -
# nothing was written into another game. So removing it is simple, with
# one thing worth being careful about:
#
# YOUR DISC IMAGE IS IN THERE. "Silent Hill (USA).bin" sits in the
# build's gamedata folder, and it is YOURS - possibly the only copy you
# have ripped. It is offered for rescue before anything is deleted, and
# it is never removed without you seeing it happen.

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

function Write-OK   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "  [..] $m" -ForegroundColor Gray }
function Write-Warn { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [XX] $m" -ForegroundColor Red }
function Write-Do   { param($m) Write-Host "  [->] $m" -ForegroundColor Cyan }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$GAME_FOLDER  = "Silent Hill VR"
$MOD_EXE_REL  = "pc_port\build\SilentHillPC.exe"
$GAMEDATA_REL = "pc_port\build\gamedata"
$SHORTCUT     = "Silent Hill VR.lnk"

function Test-SilentHillUninstallRoot {
    param([string]$Path)
    if (-not $Path) { return $false }
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    if ((Split-Path $full -Leaf) -ne 'Silent Hill VR') { return $false }
    foreach ($relative in @('','pc_port','pc_port\build')) {
        $item = Get-Item -LiteralPath $(if ($relative) { Join-Path $full $relative } else { $full }) -Force -ErrorAction SilentlyContinue
        if (-not $item -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return $false }
    }
    return ((Test-Path -LiteralPath "$full\pc_port\build\SilentHillPC.exe" -PathType Leaf) -or (Test-Path -LiteralPath "$full\pc_port\build\openvr_api.dll" -PathType Leaf))
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Silent Hill VR - Uninstall" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""

# ---- Where is it? -------------------------------------------
$recorded = $null
try {
    $rp = Join-Path $PSScriptRoot ".installed_path"
    if (Test-Path -LiteralPath $rp) { $recorded = (Get-Content -LiteralPath $rp -Raw -ErrorAction Stop).Trim() }
} catch {}

$installRoot = $null
foreach ($cand in @(
    $recorded,
    "C:\Games\$GAME_FOLDER", "D:\Games\$GAME_FOLDER", "E:\Games\$GAME_FOLDER",
    (Join-Path $env:USERPROFILE "Games\$GAME_FOLDER")
)) {
    if ($cand -and (Test-Path -LiteralPath (Join-Path $cand $MOD_EXE_REL))) { $installRoot = $cand; break }
}
if (-not $installRoot) {
    Write-Warn "Could not find the install automatically."
    $installRoot = (Read-Host "  Paste the Silent Hill VR folder (or press Enter to exit)").Trim().Trim('"')
    if (-not $installRoot -or -not (Test-Path -LiteralPath $installRoot)) {
        Write-Info "Nothing was changed."
        Pause-User "Press Enter to exit."
        exit 0
    }
}
$installRoot = [IO.Path]::GetFullPath($installRoot).TrimEnd('\')
if (-not (Test-SilentHillUninstallRoot $installRoot)) { throw 'This is not a recognized Silent Hill VR installation. Nothing was deleted.' }
Write-OK "Found: $installRoot"

# ---- Running? -----------------------------------------------
$running = @(Get-Process -Name "SilentHillPC" -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) {
    Write-Warn "Silent Hill VR is running. Close it, then run this again."
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- Your own files first -----------------------------------
$gameData = Join-Path $installRoot $GAMEDATA_REL
$yours = @()
if (Test-Path -LiteralPath $gameData) {
    $yours = @(Get-ChildItem -LiteralPath $gameData -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Extension -match '(?i)\.(bin|cue|img|iso)$' })
}
Write-Host ""
if ($yours.Count -gt 0) {
    Write-Host "  YOUR OWN GAME DATA IS IN THIS FOLDER. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    foreach ($f in $yours) { Write-Host ("    {0}  ({1:N0} MB)" -f $f.Name, ($f.Length / 1MB)) -ForegroundColor White }
    Write-Host ""
    Write-Host "  This is your disc image, not the mod's. Rescue it before it goes." -ForegroundColor Gray
    Write-Host ""
    $keep = ""
    for ($k = 1; $k -le 20; $k++) {
        $keep = ("" + (Read-Host "  Open the folder so you can move it out first? [y/n]")).Trim().ToLower()
        if ($keep -in @("y","n","yes","no")) { break }
        Write-Host "  Please answer y or n." -ForegroundColor Yellow
    }
    if ($keep -in @("y","yes")) {
        try { Start-Process -FilePath explorer.exe -ArgumentList ('"' + $gameData + '"') } catch {}
        Pause-User "Press Enter once you have moved it somewhere safe..."
        $yours = @(Get-ChildItem -LiteralPath $gameData -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.Extension -match '(?i)\.(bin|cue|img|iso)$' })
        if ($yours.Count -gt 0) { Write-Warn "Still there: $($yours.Count) file(s). They will be deleted with the folder." }
        else { Write-OK "The folder is clear of your own files." }
    }
} else {
    Write-Info "No disc image found in the gamedata folder - nothing of yours to rescue."
}

# ---- Confirm ------------------------------------------------
Write-Host ""
Write-Host "  This removes:" -ForegroundColor White
Write-Host "    $installRoot" -ForegroundColor Gray
Write-Host "    the '$SHORTCUT' shortcut on your Desktop" -ForegroundColor Gray
Write-Host ""
Write-Host "  Nothing outside that folder is touched - this build never" -ForegroundColor Gray
Write-Host "  wrote into another game or into Windows." -ForegroundColor Gray
Write-Host ""

$sure = ("" + (Read-Host "  Type DELETE to confirm, anything else to cancel")).Trim()
if ($sure -cne "DELETE") {
    Write-Info "Not confirmed - nothing was changed."
    Pause-User "Press Enter to exit."
    exit 0
}

$removed = 0
try {
    Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction Stop
    Write-OK "Removed: $installRoot"
    $removed++
} catch {
    Write-Fail "Could not remove it: $($_.Exception.Message)"
    Write-Do "Close anything using the folder and delete it by hand."
    Pause-User 'Press Enter to exit; installation records were kept.'
    exit 1
}

$lnk = Join-Path ([Environment]::GetFolderPath("Desktop")) $SHORTCUT
if (Test-Path -LiteralPath $lnk) {
    try { Remove-Item -LiteralPath $lnk -Force -ErrorAction Stop; Write-OK "Removed the Desktop shortcut."; $removed++ }
    catch { Write-Warn "Could not remove the Desktop shortcut - delete it by hand." }
}
foreach ($rec in @(".installed_version", ".installed_path")) {
    $p = Join-Path $PSScriptRoot $rec
    if (Test-Path -LiteralPath $p) { try { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue } catch {} }
}

Write-Host ""
if ($removed -gt 0) { Write-OK "Silent Hill VR removed." } else { Write-Info "Nothing was left to remove." }
Write-Host ""
Pause-User "Press Enter to exit."
