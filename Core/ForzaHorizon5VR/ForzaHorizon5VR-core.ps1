# ============================================================
# Forza Horizon 5 VR Installer
# lufz / VRMod (GitHub releases)    launcher: vrmod-launcher.exe
# VRMod supports Forza Horizon 5 and 6 from the same
# launcher. The launcher injects into the game; the mod files
# must NOT live in the game folder, so we extract to
# C:\Games\Forza Horizon 5 VR and launch from there.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Forza Horizon 5 VR Installer"
$ErrorActionPreference = "Stop"

$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")
$GAME_FOLDER   = "Forza Horizon 5 VR"
# lufz publishes on GitHub now, so the download is automatic. The releases
# are tagged as PRERELEASES, which is why the newest one is taken from
# /releases and never from /releases/latest - the latter skips them.
$VRMOD_REPO    = "oofz/vrmod-releases"
$VRMOD_API     = "https://api.github.com/repos/$VRMOD_REPO/releases"
$VRMOD_PAGE    = "https://github.com/$VRMOD_REPO/releases"
$ZIP_HINT      = "VRMod-v1_3_3.zip"
$LAUNCHER_NAME = "vrmod-launcher.exe"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Forza Horizon 5 VR Installer" -ForegroundColor Cyan
    Write-Host " lufz VRMod - downloaded automatically from GitHub" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [XX] $t" -ForegroundColor Red }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-WritableRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

# Drag-drop loop: the user drags the downloaded mod .zip onto the
# window. Accepts a dragged (quoted) path or a typed path; loops until
# a real .zip is given or the user cancels.
function Get-DraggedZip {
    param([string]$ExpectHint)
    while ($true) {
        Write-Host ""
        Write-Host " Drag the downloaded $ExpectHint onto this window and press Enter." -ForegroundColor Yellow
        Write-Host " (You can also type or paste the full path.)" -ForegroundColor Gray
        Write-Host " Leave empty and press Enter to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " Zip path"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path -LiteralPath $p)) { Write-Warn "Path not found: $p"; continue }
        if (Test-Path -LiteralPath $p -PathType Container) { Write-Warn "That is a folder. Drag the .zip file itself."; continue }
        if ([System.IO.Path]::GetExtension($p) -ne ".zip") { Write-Warn "That is not a .zip file."; continue }
        return $p
    }
}

Write-Header
Write-Host " This sets up the lufz VRMod for your EXISTING Forza Horizon 5" -ForegroundColor White
Write-Host " install (Steam / Microsoft Store / Game Pass). No game files" -ForegroundColor Gray
Write-Host " are bundled - you download the free community mod yourself and" -ForegroundColor Gray
Write-Host " drag the .zip onto this window; the Hub does the rest." -ForegroundColor Gray
Write-Host ""

# Newest release INCLUDING prereleases - that is what this project ships.
function Get-VRModRelease {
    try {
        $rels = Invoke-RestMethod -Uri $VRMOD_API -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
        $rel = $rels | Select-Object -First 1
        if (-not $rel) { return $null }
        $asset = $rel.assets | Where-Object { $_.name -like "*.zip" -and $_.name -notlike "*source*" } | Select-Object -First 1
        if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1 }
        if (-not $asset) { return $null }
        return [pscustomobject]@{ Tag = $rel.tag_name; Url = $asset.browser_download_url; Name = $asset.name }
    } catch { return $null }
}

# ---- STEP 1: get the download ----
Pause-User "Press Enter to start..."
Write-Step 1 5 "Downloading the mod"
$dlWork = Join-Path $env:TEMP ("vrmod_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $dlWork -Force | Out-Null
$zipPath = $null
$rel = Get-VRModRelease
if ($rel) {
    Write-Info "Newest VRMod release: $($rel.Tag) ($($rel.Name))"
    $target = Join-Path $dlWork $rel.Name
    Invoke-SafeDownload -Urls @($rel.Url) -Destination $target -Label "VRMod $($rel.Tag)" -ManualUrl $VRMOD_PAGE | Out-Null
    if (Test-Path -LiteralPath $target) { $zipPath = $target }
}
if (-not $zipPath) {
    $found = Find-PredownloadedFile -Patterns @("VRMod-v*.zip", "*VRMod*.zip") -Label "the VRMod package"
    if ($found) { $zipPath = $found }
}

# ---- STEP 2: browser + drag & drop, only if the download failed ----
Write-Step 2 5 "Locating the downloaded zip"
if (-not $zipPath) {
    Write-Warn "Automatic download did not work."
    Write-Host "  Opening the releases page - take the newest VRMod zip." -ForegroundColor Gray
    Pause-User "Press Enter to open the releases page..."
    try { Start-Process $VRMOD_PAGE } catch { Write-Warn "Open manually: $VRMOD_PAGE" }
    $zipPath = Get-DraggedZip -ExpectHint $ZIP_HINT
}
if (-not $zipPath) { Write-Info "No zip provided - cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
$zipLeaf = Split-Path -Leaf $zipPath
if ($zipLeaf -notlike "VRMod-*") {
    Write-Warn "Expected a 'VRMod-*.zip' - continuing anyway with '$zipLeaf'."
}
Write-OK "Using: $zipLeaf"

# ---- STEP 3: choose location + extract ----
Write-Step 3 5 "Installing the mod files"
$defaultParent = $null
foreach ($r in $DEFAULT_ROOTS) { if (Test-WritableRoot -Root $r) { $defaultParent = [string]$r; break } }
if (-not $defaultParent) { $defaultParent = "C:\Games" }
$installRoot = Join-Path $defaultParent $GAME_FOLDER
Write-Host "  Install location: $installRoot" -ForegroundColor Gray
Write-Host "  (Kept OUT of the game folder on purpose - the mod must not" -ForegroundColor DarkGray
Write-Host "   live inside Forza Horizon 5's own install folder.)" -ForegroundColor DarkGray
try { New-Item -ItemType Directory -Force -Path $installRoot | Out-Null } catch {}

$r = Expand-ArchiveOrFallback -ArchivePath $zipPath -DestinationFolder $installRoot -Label "lufz VRMod" `
        -SkipMessage "Skipped - the mod files were NOT extracted. The install is incomplete."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$r -eq "ok" -or [string]$r -eq "manual") { Write-OK "Mod files extracted to $installRoot" }

# ---- STEP 4: verify launcher + desktop shortcut ----
Write-Step 4 5 "Finishing setup"
$launcherPath = Join-Path $installRoot $LAUNCHER_NAME
if (-not (Test-Path $launcherPath)) {
    # Fallback: the zip may have unpacked into a nested subfolder - search.
    $found = Get-ChildItem -Path $installRoot -Filter $LAUNCHER_NAME -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $launcherPath = $found.FullName; $installRoot = Split-Path -Parent $launcherPath }
}
if (Test-Path $launcherPath) {
    Write-OK "Launcher found: $LAUNCHER_NAME"
} else {
    Write-Warn "$LAUNCHER_NAME not found under $installRoot - check the extracted files manually."
}

# Custom desktop-shortcut icon. Copy the bundled .ico into the install
# root so the shortcut keeps a stable icon path (mirrors the FH6
# installer). Falls back to the launcher's own icon if the copy fails.
$iconDest = Join-Path $installRoot "ForzaHorizon5_VR.ico"
try { Copy-Item -Path (Join-Path $PSScriptRoot "ForzaHorizon5_VR.ico") -Destination $iconDest -Force } catch {}

try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "Forza Horizon 5 VR.lnk"
    $sc = New-DesktopShortcut -LnkPath $lnk -TargetPath $launcherPath -WorkingDir $installRoot -IconPath $(if (Test-Path $iconDest) { $iconDest } else { $launcherPath }) -Description "Launch the Forza Horizon 5 VR mod (lufz VRMod)"
    Write-OK "Desktop shortcut created with custom icon: Forza Horizon 5 VR"
} catch {
    Write-Warn "Could not create the desktop shortcut. You can start $LAUNCHER_NAME from $installRoot."
}

# Record install path + launcher for the Hub. Single-mod game: the
# .launch_exe override makes "Start in VR" open vrmod-launcher.exe
# directly (unlike FH6, which keeps the two-mod choice instead).
# DOES THIS BUILD STILL COVER FORZA HORIZON 5? The launcher drives each
# game from a profile in profiles\. v1.3.3 shipped WITHOUT
# forza_horizon_5.json and lists only Forza Horizon 6 as supported, so a
# newer release can silently be an FH6-only build - and then Install and
# Play stay greyed out with no explanation. Say so plainly instead, and
# point at the older release that still has the profile. Checked, never
# guessed: the file is either there or it is not.
$fh5Profile = Join-Path $installRoot "profiles\forza_horizon_5.json"
if (-not (Test-Path -LiteralPath $fh5Profile)) {
    Write-Host ""
    Write-Warn "This VRMod build does NOT include a Forza Horizon 5 profile."
    Write-Host "  The launcher needs profiles\forza_horizon_5.json to drive FH5;" -ForegroundColor White
    Write-Host "  without it, Install VR Mod and Play in VR stay disabled for" -ForegroundColor White
    Write-Host "  this game. Newer builds have been focusing on Horizon 6." -ForegroundColor White
    Write-Host "  If FH5 is what you want, take an older release that still has" -ForegroundColor White
    Write-Host "  that profile:" -ForegroundColor White
    Write-Host "    $VRMOD_PAGE" -ForegroundColor Gray
    Write-Host ""
}

try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $installRoot -Encoding UTF8 -Force } catch {}
try { Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value $launcherPath -Encoding UTF8 -Force } catch {}

# Record the installed mod version so the Hub's update badge works
# (catalog pins the current lufz version; a mismatch shows Update).
# NORMALIZED without a leading "v" - the Hub compares against
# Get-ModVersionFromString output, which strips the v.
#
# PRIMARY source: the VERSION file lufz ships inside the zip. It is
# authoritative and survives a renamed zip, so it beats parsing the
# file name. Fall back to the zip name, then to the pinned release.
#
# (History: the 1.2.1 hotfixes reused the same zip name AND VERSION,
# so the Hub had to track them as 1.2.1b/1.2.1c. lufz moved to a real
# 1.2.3, so that workaround is retired - the zip is honest again.)
$lufzVer = "1.3.3"
$lufzVerFile = Join-Path $installRoot "VERSION"
$lufzVerFound = $false
if (Test-Path -LiteralPath $lufzVerFile) {
    try {
        $fv = (Get-Content -LiteralPath $lufzVerFile -TotalCount 1 -ErrorAction Stop | Select-Object -First 1)
        if ($fv) { $fv = $fv.Trim() }
        if ($fv -match '^\d+\.\d+') { $lufzVer = $fv; $lufzVerFound = $true }
    } catch {}
}
if (-not $lufzVerFound -and $zipLeaf -match '(?i)VRMod[-_]v?([0-9][0-9_.]*)') {
    $pv = $matches[1].Replace("_", ".").Trim(".")
    if ($pv -match '^\d+\.\d+') { $lufzVer = $pv }
}
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $lufzVer -Encoding ASCII -Force } catch {}

# ---- STEP 5: how to play ----
Write-Step 5 5 "How to play"
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " lufz VRMod - HOW TO PLAY" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " 1) Start from the desktop shortcut (or run vrmod-launcher.exe)." -ForegroundColor White
Write-Host " 2) Click '+ Add Game' and pick the game FOLDER, select the row," -ForegroundColor White
Write-Host "    then click 'Install VR Mod' (once per game install folder)." -ForegroundColor White
Write-Host "    On Game Pass pick " -NoNewline -ForegroundColor White
Write-Host " C:\XboxGames\Forza Horizon 5\Content " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " -" -ForegroundColor White
Write-Host "    Windows blocks opening the exe there. On Steam you can also" -ForegroundColor White
Write-Host "    use '+ Add .exe', or 'Auto-detect Running' if it is open." -ForegroundColor White
Write-Host " 3) Start SteamVR, then click 'Play in VR' - it launches the" -ForegroundColor White
Write-Host "    game, or enables the headset if it is already running" -ForegroundColor White
Write-Host "    (best from the main menu, garage, or while driving)." -ForegroundColor White
Write-Host ""
Write-Host " Settings: for OpenXR 6DoF turn HDR OFF and set in-game FOV to" -ForegroundColor Gray
Write-Host " maximum." -ForegroundColor Gray
Write-Host ""
Write-Host " Leave " -NoNewline -ForegroundColor White
Write-Host " Frame Generation " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " OFF - the mod author asks for that" -ForegroundColor White
Write-Host " with this version. It also clears out a few old config values" -ForegroundColor White
Write-Host " that could cause trouble - the rest of your tuning stays." -ForegroundColor White
Write-Host ""
Write-Host " Your VR mod is installed here (opening it now):" -ForegroundColor White
Write-Host "   $installRoot" -ForegroundColor Gray
Write-Host " Run it from this folder or the desktop shortcut - the launcher" -ForegroundColor Gray
Write-Host " connects to Forza Horizon 5 itself." -ForegroundColor Gray
try { Start-Process $installRoot } catch {}
# ---- Signoff ----
Write-Host ""
Write-Host " Viva Mexico - drop the roof, floor it, and chase that horizon." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
