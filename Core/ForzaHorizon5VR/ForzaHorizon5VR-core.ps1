# ============================================================
# Forza Horizon 5 VR Installer
# Two VR mods to choose from:
#   1) NALULUNA (free, ko-fi)          launcher: fh5vr.exe
#   2) lufz / VRMod (GitHub releases)  launcher: vrmod-launcher.exe
# Both use a separate launcher. Their packages live outside the
# retail game under C:\Games\Forza Horizon 5 VR so they can be
# installed side by side without bundling any mod in the Hub.
# ============================================================

param(
    [Alias('InstallerChoice')]
    [ValidateSet('','naluluna','lufz')]
    [string]$Mod = ''
)

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Forza Horizon 5 VR Installer"
$ErrorActionPreference = "Stop"

$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")
$GAME_FOLDER   = "Forza Horizon 5 VR"
$KOFI_URL      = "https://ko-fi.com/s/1724b05721"
# lufz publishes on GitHub. Releases are frequently prereleases, so use the
# releases feed rather than /releases/latest, which can skip the newest build.
$VRMOD_REPO    = "oofz/vrmod-releases"
$VRMOD_API     = "https://api.github.com/repos/$VRMOD_REPO/releases"
$VRMOD_PAGE    = "https://github.com/$VRMOD_REPO/releases"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Forza Horizon 5 VR Installer" -ForegroundColor Cyan
    Write-Host " Two community VR mods to choose from" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Test-WritableRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path -LiteralPath $Root)) { New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -LiteralPath $probe -Value "ok" -ErrorAction Stop
        Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

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

Write-Header
Write-Host " This sets up a VR mod for your EXISTING Forza Horizon 5" -ForegroundColor White
Write-Host " install (Steam / Microsoft Store / Game Pass). No game or" -ForegroundColor Gray
Write-Host " VR-mod files are bundled. Each mod gets its own external" -ForegroundColor Gray
Write-Host " folder, so both packages can remain installed." -ForegroundColor Gray
Write-Host ""

# ---- STEP 1: choose the mod ----
Write-Step 1 6 "Choosing a VR mod"
$modChoice = ""
if ($Mod) {
    $modChoice = if ($Mod -eq 'lufz') { '2' } else { '1' }
    $selectedByHub = if ($modChoice -eq '2') { 'lufz VRMod' } else { 'NALULUNA' }
    Write-Host "  UPDATE TARGET: $selectedByHub" -ForegroundColor Black -BackgroundColor Cyan
    Write-Host "  The Hub identified this exact installed mod as the update target." -ForegroundColor Gray
} else {
    Write-Host "  Which VR mod do you want to set up?" -ForegroundColor White
    Write-Host ""
    Write-Host "   [1] NALULUNA  - free on ko-fi" -ForegroundColor Green
    Write-Host "   [2] lufz VRMod - free, downloaded automatically" -ForegroundColor White
    Write-Host ""
    while ($modChoice -ne "1" -and $modChoice -ne "2") {
        $modChoice = (Read-Host "  Enter 1 or 2 [default: 1]").Trim()
        if ($modChoice -eq "") { $modChoice = "1" }
        if ($modChoice -ne "1" -and $modChoice -ne "2") { Write-Warn "Please type 1 or 2." }
    }
}
if ($modChoice -eq "1") {
    $modName      = "NALULUNA"
    $modSub       = "NALULUNA"
    $launcherName = "fh5vr.exe"
    $zipHint      = "fh5vr_<version>.zip"
} else {
    $modName      = "lufz VRMod"
    $modSub       = "lufz"
    $launcherName = "vrmod-launcher.exe"
    $zipHint      = "VRMod-v<version>.zip"
}
Write-OK "Selected: $modName"

# ---- STEP 2: get the download ----
Write-Step 2 6 "Downloading the mod"
if ($modChoice -eq "1") {
    Write-Host "  NALULUNA's mod is FREE on ko-fi. On the page that opens:" -ForegroundColor White
    Write-Host "   - set the amount to 0 (or any tip you like) and download," -ForegroundColor Gray
    Write-Host "   - take the newest file named like '$zipHint'." -ForegroundColor Gray
    try { Start-Process $KOFI_URL } catch { Write-Warn "Could not open the browser. Open manually: $KOFI_URL" }
    Write-Host ""
    Write-Host "  ko-fi page: $KOFI_URL" -ForegroundColor DarkGray
} else {
    Write-Info "The newest lufz release (including prereleases) will be downloaded automatically."
}

# ---- STEP 3: get the file ----
Write-Step 3 6 "Locating the downloaded zip"
$zipPath = $null
$rel = $null
if ($modChoice -eq "2") {
    $dlWork = Join-Path $env:TEMP ("vrmod_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
    New-Item -ItemType Directory -Path $dlWork -Force | Out-Null
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
    if (-not $zipPath) {
        Write-Warn "Automatic download did not work."
        Pause-User "Press Enter to open the releases page..."
        try { Start-Process $VRMOD_PAGE } catch { Write-Warn "Open manually: $VRMOD_PAGE" }
    }
}
if (-not $zipPath) { $zipPath = Get-DraggedZip -ExpectHint $zipHint }
if (-not $zipPath) { Write-Info "No zip provided - cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
$zipLeaf = Split-Path -Leaf $zipPath
if ($modChoice -eq "1" -and $zipLeaf -notlike "fh5vr_*") {
    Write-Warn "Expected an 'fh5vr_*.zip' - continuing anyway with '$zipLeaf'."
} elseif ($modChoice -eq "2" -and $zipLeaf -notlike "VRMod-*") {
    Write-Warn "Expected a 'VRMod-*.zip' - continuing anyway with '$zipLeaf'."
}
Write-OK "Using: $zipLeaf"

# ---- STEP 4: choose location + extract ----
Write-Step 4 6 "Installing the mod files"
$defaultParent = $null
foreach ($root in $DEFAULT_ROOTS) { if (Test-WritableRoot -Root $root) { $defaultParent = [string]$root; break } }
if (-not $defaultParent) { $defaultParent = "C:\Games" }
$installRoot = Join-Path $defaultParent $GAME_FOLDER
try { New-Item -ItemType Directory -Force -Path $installRoot | Out-Null } catch {}

# Fresh installs use one subfolder per mod. Existing FH5 lufz installs from
# older Hub builds lived directly in the parent folder; update those in place
# so settings and the already-deployed game profile are not stranded.
$modFolder = Join-Path $installRoot $modSub
if ($modChoice -eq "2" -and
    (Test-Path -LiteralPath (Join-Path $installRoot "vrmod-launcher.exe") -PathType Leaf) -and
    -not (Test-Path -LiteralPath (Join-Path $modFolder "vrmod-launcher.exe") -PathType Leaf)) {
    $modFolder = $installRoot
    Write-Info "Updating the existing lufz installation in its legacy location."
}
Write-Host "  Install location: $modFolder" -ForegroundColor Gray
Write-Host "  (Kept OUT of the retail game folder on purpose.)" -ForegroundColor DarkGray
try { New-Item -ItemType Directory -Force -Path $modFolder | Out-Null } catch {}

$expandResult = Expand-ArchiveOrFallback -ArchivePath $zipPath -DestinationFolder $modFolder -Label "$modName VR mod" `
        -SkipMessage "Skipped - the mod files were NOT extracted. The install is incomplete."
if ([string]$expandResult -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$expandResult -eq "ok" -or [string]$expandResult -eq "manual") { Write-OK "Mod files extracted to $modFolder" }

# ---- STEP 5: verify launcher + desktop shortcut ----
Write-Step 5 6 "Finishing setup"
$launcherPath = Join-Path $modFolder $launcherName
if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    $found = Get-ChildItem -LiteralPath $modFolder -Filter $launcherName -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $launcherPath = $found.FullName; $modFolder = Split-Path -Parent $launcherPath }
}
if (Test-Path -LiteralPath $launcherPath -PathType Leaf) {
    Write-OK "Launcher found: $launcherName"
} else {
    Write-Warn "$launcherName not found under $modFolder - check the extracted files manually."
}

$iconDest = Join-Path $installRoot "ForzaHorizon5_VR.ico"
try { Copy-Item -LiteralPath (Join-Path $PSScriptRoot "ForzaHorizon5_VR.ico") -Destination $iconDest -Force } catch {}
try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "Forza Horizon 5 VR.lnk"
    $sc = New-DesktopShortcut -LnkPath $lnk -TargetPath $launcherPath -WorkingDir $modFolder -IconPath $(if (Test-Path -LiteralPath $iconDest) { $iconDest } else { $launcherPath }) -Description "Launch the Forza Horizon 5 VR mod ($modName)"
    Write-OK "Desktop shortcut created with custom icon: Forza Horizon 5 VR"
} catch {
    Write-Warn "Could not create the desktop shortcut. You can start $launcherName from $modFolder."
}

# lufz needs a game profile. Validate the actual archive instead of assuming
# that every release still covers FH5.
if ($modChoice -eq "2") {
    $fh5Profile = Join-Path $modFolder "profiles\forza_horizon_5.json"
    if (-not (Test-Path -LiteralPath $fh5Profile -PathType Leaf)) {
        Write-Host ""
        Write-Warn "This VRMod build does NOT include a Forza Horizon 5 profile."
        Write-Host "  Without profiles\forza_horizon_5.json, Install VR Mod and" -ForegroundColor White
        Write-Host "  Play in VR stay disabled for this game. Check the release page:" -ForegroundColor White
        Write-Host "    $VRMOD_PAGE" -ForegroundColor Gray
    }
}

# Record the shared parent. TwoMods detection checks both subfolders and also
# understands the older root-level lufz layout. Never keep a stale fixed
# launcher override: it would bypass the Hub's split launch buttons.
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $installRoot -Encoding UTF8 -Force } catch {}
try { $ov = Join-Path $PSScriptRoot ".launch_exe"; if (Test-Path -LiteralPath $ov) { Remove-Item -LiteralPath $ov -Force -ErrorAction SilentlyContinue } } catch {}

# The Hub's automatic update badge tracks the lufz GitHub branch. NALULUNA is
# a manual ko-fi source and deliberately leaves this marker untouched.
if ($modChoice -eq "2") {
    $verFromTag = $null
    if ($rel -and $rel.Tag) {
        $m = [regex]::Match([string]$rel.Tag, '(\d+(?:\.\d+)+)')
        if ($m.Success) { $verFromTag = $m.Groups[1].Value }
    }
    $verFromName = $null
    if ($zipLeaf -match '(?i)VRMod[-_]v?([0-9][0-9_.]*)') {
        $cand = $matches[1].Replace("_", ".").Trim(".")
        if ($cand -match '^\d+(\.\d+)+$') { $verFromName = $cand }
    }
    $verFromFile = $null
    $lufzVerFile = Join-Path $modFolder "VERSION"
    if (Test-Path -LiteralPath $lufzVerFile -PathType Leaf) {
        try {
            $fv = (Get-Content -LiteralPath $lufzVerFile -TotalCount 1 -ErrorAction Stop | Select-Object -First 1)
            if ($fv) { $fv = $fv.Trim() }
            if ($fv -match '^(\d+(?:\.\d+)+)') { $verFromFile = $matches[1] }
        } catch {}
    }
    $lufzVer = $null
    foreach ($cand in @($verFromName, $verFromTag, $verFromFile)) {
        if ($cand) { $lufzVer = $cand; break }
    }
    $seen = @($verFromName, $verFromTag, $verFromFile) | Where-Object { $_ }
    $agree = (@($seen | Sort-Object -Unique).Count -le 1)
    if ($lufzVer) {
        if ($agree) { Write-OK "Installed version $lufzVer (confirmed by $($seen.Count) of 3 sources)." }
        else { Write-Warn ("Version sources disagree: name=$verFromName tag=$verFromTag file=$verFromFile - using $lufzVer.") }
        try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Value $lufzVer -Encoding ASCII -Force } catch {}
        Save-InstalledStamp -GameDir $installRoot -Version $lufzVer
    } else {
        Write-Warn "No version could be read - the Hub will seed it on the next scan."
        try { Remove-Item -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Force -ErrorAction SilentlyContinue } catch {}
    }
}

# ---- STEP 6: how to play ----
Write-Step 6 6 "How to play"
Write-Host "============================================================" -ForegroundColor Yellow
if ($modChoice -eq "1") {
    Write-Host " NALULUNA - HOW TO PLAY" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " 1) Launch with " -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host " in the Hub, the desktop" -ForegroundColor White
    Write-Host "    shortcut, or fh5vr.exe, then press 'Launch'." -ForegroundColor White
    Write-Host " 2) Once you are in a car, press Tab until cockpit view is" -ForegroundColor White
    Write-Host "    active. That is the view rendered in VR." -ForegroundColor White
    Write-Host " 3) Press both controller sticks, or Ctrl + Space, to recenter." -ForegroundColor White
    Write-Host ""
    Write-Host " Recommended: Meta Link at 72 Hz. Keep Sync FPS on and SteamVR" -ForegroundColor Gray
    Write-Host " closed. Disable OpenXR Toolkit, motion blur, DLSS and frame" -ForegroundColor Gray
    Write-Host " generation. On Game Pass also close overlay tools such as" -ForegroundColor Gray
    Write-Host " Afterburner / RivaTuner." -ForegroundColor Gray
    Write-Host ""
    Write-Host " This build targets Steam 1.688.109.0 and Microsoft Store /" -ForegroundColor Gray
    Write-Host " Game Pass 3.688.109.0. A later game update may need a new mod." -ForegroundColor Gray
} else {
    Write-Host " lufz VRMod - HOW TO PLAY" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " 1) Start from the Hub, desktop shortcut, or vrmod-launcher.exe." -ForegroundColor White
    Write-Host " 2) Click '+ Add Game', choose the game folder, select the row," -ForegroundColor White
    Write-Host "    then click 'Install VR Mod'. On Game Pass choose" -ForegroundColor White
    Write-Host "    " -NoNewline -ForegroundColor White
    Write-Host " C:\XboxGames\Forza Horizon 5\Content " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "    On Steam you can also use '+ Add .exe' or Auto-detect Running." -ForegroundColor White
    Write-Host " 3) Start your OpenXR runtime, then click 'Play in VR'." -ForegroundColor White
    Write-Host ""
    Write-Host " For OpenXR 6DoF turn HDR OFF, set in-game FOV to maximum and" -ForegroundColor Gray
    Write-Host " leave Frame Generation OFF." -ForegroundColor Gray
}
Write-Host ""
Write-Host " Your selected VR mod is installed here (opening it now):" -ForegroundColor White
Write-Host "   $modFolder" -ForegroundColor Gray
try { Start-Process $modFolder } catch {}
Write-Host ""
Write-Host " Viva Mexico - drop the roof, floor it, and chase that horizon." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
