# ============================================================
# Forza Horizon 6 VR Installer
# Three VR mods to choose from:
#   1) NALULUNA (free, ko-fi)        launcher: fh6vr.exe
#   2) lufz / VRMod (GitHub releases)  launcher: vrmod-launcher.exe
#   3) CheekyRender (GitHub releases) launcher: CheekyRender.exe
# All ship a separate launcher that injects into the game; the
# mod files must NOT live in the game folder, so we extract to
# C:\Games\Forza Horizon 6 VR and launch from there.
# ============================================================

param(
    [ValidateSet('','naluluna','lufz','cheeky')]
    [string]$Mod = ''
)

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Forza Horizon 6 VR Installer"
$ErrorActionPreference = "Stop"

$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")
$GAME_FOLDER   = "Forza Horizon 6 VR"
$KOFI_URL      = "https://ko-fi.com/s/03bdcc5fe9"
# lufz publishes on GitHub now. Releases are tagged as PRERELEASES, so the
# newest one comes from /releases and never from /releases/latest, which
# skips them. NALULUNA's mod stays on ko-fi and is unaffected.
$VRMOD_REPO    = "oofz/vrmod-releases"
$VRMOD_API     = "https://api.github.com/repos/$VRMOD_REPO/releases"
$VRMOD_PAGE    = "https://github.com/$VRMOD_REPO/releases"
$CHEEKY_REPO   = "ClarkCheekyKent/cheeky-render-releases"
$CHEEKY_API    = "https://api.github.com/repos/$CHEEKY_REPO/releases"
$CHEEKY_PAGE   = "https://github.com/$CHEEKY_REPO/releases"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Forza Horizon 6 VR Installer" -ForegroundColor Cyan
    Write-Host " Three community VR mods to choose from" -ForegroundColor Gray
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
        if (-not (Test-Path $p)) { Write-Warn "Path not found: $p"; continue }
        if (Test-Path $p -PathType Container) { Write-Warn "That is a folder. Drag the .zip file itself."; continue }
        if ([System.IO.Path]::GetExtension($p) -ne ".zip") { Write-Warn "That is not a .zip file."; continue }
        return $p
    }
}

Write-Header
Write-Host " This sets up a VR mod for your EXISTING Forza Horizon 6 install" -ForegroundColor White
Write-Host " (Steam / Microsoft Store / Game Pass). No game files are" -ForegroundColor Gray
Write-Host " bundled. GitHub releases download automatically; NALULUNA's" -ForegroundColor Gray
Write-Host " free ko-fi package is selected by drag and drop." -ForegroundColor Gray
Write-Host ""
Show-AntivirusNotice

# ---- STEP 1: choose the mod ----
Write-Step 1 6 "Choosing a VR mod"
Write-Host "  Which VR mod do you want to set up?" -ForegroundColor White
Write-Host ""
Write-Host "   [1] NALULUNA  - free on ko-fi  (recommended)" -ForegroundColor Green
Write-Host "   [2] lufz VRMod - free, downloaded automatically" -ForegroundColor White
Write-Host "   [3] CheekyRender - free early preview, auto-download" -ForegroundColor White
Write-Host ""
$choiceMap = @{ naluluna='1'; lufz='2'; cheeky='3' }
$modChoice = if ($Mod -and $choiceMap.ContainsKey($Mod.ToLowerInvariant())) { [string]$choiceMap[$Mod.ToLowerInvariant()] } else { "" }
while ($modChoice -notin @("1","2","3")) {
    $modChoice = (Read-Host "  Enter 1, 2 or 3 [default: 1]").Trim()
    if ($modChoice -eq "") { $modChoice = "1" }
    if ($modChoice -notin @("1","2","3")) { Write-Warn "Please type 1, 2 or 3." }
}
if ($modChoice -eq "1") {
    $modName      = "NALULUNA"
    $modSub       = "NALULUNA"
    $launcherName = "fh6vr.exe"
    $zipHint      = "fh6vr_<version>.zip"
} elseif ($modChoice -eq "2") {
    $modName      = "lufz VRMod"
    $modSub       = "lufz"
    $launcherName = "vrmod-launcher.exe"
    $zipHint      = "VRMod-v<version>.zip"
} else {
    $modName      = "CheekyRender"
    $modSub       = "CheekyRender"
    $launcherName = "CheekyRender.exe"
    $zipHint      = "CheekyRender-v<version>-win64.zip"
}
Write-OK "Selected: $modName"

# Newest published release INCLUDING prereleases. Both GitHub-fed authors
# currently publish their usable builds as prereleases, so /releases/latest
# would miss them entirely.
function Get-GithubModRelease {
    param([string]$ApiUrl, [string[]]$AssetPatterns)
    try {
        $rels = Invoke-RestMethod -Uri $ApiUrl -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
        foreach ($release in @($rels | Where-Object { -not $_.draft })) {
            foreach ($pattern in $AssetPatterns) {
                $asset = @($release.assets | Where-Object { $_.name -like $pattern -and $_.name -notlike "*source*" }) | Select-Object -First 1
                if ($asset) {
                    return [pscustomobject]@{
                        Tag = [string]$release.tag_name; Url = [string]$asset.browser_download_url
                        Name = [string]$asset.name; Prerelease = [bool]$release.prerelease
                    }
                }
            }
        }
        return $null
    } catch { return $null }
}

function Install-CheekyPayload {
    param([string]$ArchivePath, [string]$Destination)
    $stage = Join-Path $env:TEMP ("pcvrhub_cheeky_" + [Guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path $stage -Force | Out-Null
        $expanded = Expand-ArchiveOrFallback -ArchivePath $ArchivePath -DestinationFolder $stage -Label 'CheekyRender VR mod' `
            -SkipMessage 'Skipped - CheekyRender was not installed.'
        if ([string]$expanded -notin @('ok','manual')) { return [string]$expanded }
        $launcher = Get-ChildItem -LiteralPath $stage -Filter 'CheekyRender.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $launcher) { throw 'CheekyRender.exe is missing from the downloaded release.' }
        $payload = Split-Path -Parent $launcher.FullName
        foreach ($required in @('CheekyRender.exe','dxgi.dll','README.txt','host\xrfb-openxr-host.exe')) {
            if (-not (Test-Path -LiteralPath (Join-Path $payload $required) -PathType Leaf)) {
                throw "The CheekyRender release is incomplete: $required is missing."
            }
        }
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        # Copy the author's four owned payload items into one stable folder.
        # Generated profiles/settings are not in this list and survive updates.
        foreach ($leaf in @('CheekyRender.exe','dxgi.dll','README.txt','host')) {
            Copy-Item -LiteralPath (Join-Path $payload $leaf) -Destination $Destination -Recurse -Force
        }
        return 'ok'
    } finally {
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# ---- STEP 2: get the download ----
Write-Step 2 6 "Downloading the mod"
if ($modChoice -eq "1") {
    Write-Host "  NALULUNA's mod is FREE on ko-fi. On the page that opens:" -ForegroundColor White
    Write-Host "   - set the amount to 0 (or any tip you like) and download," -ForegroundColor Gray
    Write-Host "   - the file is named like '$zipHint' (newest version)." -ForegroundColor Gray
    try { Start-Process $KOFI_URL } catch { Write-Warn "Could not open the browser. Open manually: $KOFI_URL" }
    Write-Host ""
    Write-Host "  ko-fi page: $KOFI_URL" -ForegroundColor DarkGray
}

# ---- STEP 3: get the file ----
Write-Step 3 6 "Locating the downloaded zip"
$zipPath = $null
if ($modChoice -in @("2","3")) {
    # Both GitHub authors publish usable prereleases. Resolve the newest
    # non-draft release containing that mod's actual Windows payload.
    $dlWork = Join-Path $env:TEMP ("fh6vr_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
    New-Item -ItemType Directory -Path $dlWork -Force | Out-Null
    $rel = if ($modChoice -eq "2") {
        Get-GithubModRelease -ApiUrl $VRMOD_API -AssetPatterns @('VRMod-v*.zip','*VRMod*.zip')
    } else {
        Get-GithubModRelease -ApiUrl $CHEEKY_API -AssetPatterns @('CheekyRender-*-win64.zip','CheekyRender*.zip')
    }
    if ($rel) {
        $channel = if ($rel.Prerelease) { 'prerelease' } else { 'stable' }
        Write-Info "Newest $modName release: $($rel.Tag) [$channel] ($($rel.Name))"
        $target = Join-Path $dlWork $rel.Name
        $releasePage = if ($modChoice -eq "2") { $VRMOD_PAGE } else { $CHEEKY_PAGE }
        Invoke-SafeDownload -Urls @($rel.Url) -Destination $target -Label "$modName $($rel.Tag)" -ManualUrl $releasePage | Out-Null
        if (Test-Path -LiteralPath $target) { $zipPath = $target }
    }
    if (-not $zipPath) {
        $patterns = if ($modChoice -eq "2") { @("VRMod-v*.zip", "*VRMod*.zip") } else { @("CheekyRender-*-win64.zip", "CheekyRender*.zip") }
        $found = Find-PredownloadedFile -Patterns $patterns -Label "the $modName package"
        if ($found) { $zipPath = $found }
    }
    if (-not $zipPath) {
        Write-Warn "Automatic download did not work."
        Pause-User "Press Enter to open the releases page..."
        $releasePage = if ($modChoice -eq "2") { $VRMOD_PAGE } else { $CHEEKY_PAGE }
        try { Start-Process $releasePage } catch { Write-Warn "Open manually: $releasePage" }
    }
}
if (-not $zipPath) { $zipPath = Get-DraggedZip -ExpectHint $zipHint }
if (-not $zipPath) { Write-Info "No zip provided - cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
$zipLeaf = Split-Path -Leaf $zipPath
if ($modChoice -eq "1" -and $zipLeaf -notlike "fh6vr_*") {
    Write-Warn "Expected a 'fh6vr_*.zip' - continuing anyway with '$zipLeaf'."
} elseif ($modChoice -eq "2" -and $zipLeaf -notlike "VRMod-*") {
    Write-Warn "Expected a 'VRMod-*.zip' - continuing anyway with '$zipLeaf'."
} elseif ($modChoice -eq "3" -and $zipLeaf -notlike "CheekyRender-*") {
    Write-Warn "Expected a 'CheekyRender-*.zip' - continuing anyway with '$zipLeaf'."
}
Write-OK "Using: $zipLeaf"

# ---- STEP 4: choose location + extract ----
Write-Step 4 6 "Installing the mod files"
$defaultParent = $null
foreach ($r in $DEFAULT_ROOTS) { if (Test-WritableRoot -Root $r) { $defaultParent = [string]$r; break } }
if (-not $defaultParent) { $defaultParent = "C:\Games" }
$installRoot = Join-Path $defaultParent $GAME_FOLDER
# Each mod gets its OWN subfolder so installing several to compare
# them never lets one overwrite another launcher's files - notably the
# openxr_loader.dll.
$modFolder = Join-Path $installRoot $modSub
Write-Host "  Install location: $modFolder" -ForegroundColor Gray
Write-Host "  (Kept OUT of the game folder on purpose - the mod must not" -ForegroundColor DarkGray
Write-Host "   live inside Forza Horizon 6's own install folder.)" -ForegroundColor DarkGray
try { New-Item -ItemType Directory -Force -Path $modFolder | Out-Null } catch {}

$r = if ($modChoice -eq "3") {
    Install-CheekyPayload -ArchivePath $zipPath -Destination $modFolder
} else {
    Expand-ArchiveOrFallback -ArchivePath $zipPath -DestinationFolder $modFolder -Label "$modName VR mod" `
        -SkipMessage "Skipped - the mod files were NOT extracted. The install is incomplete."
}
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$r -eq "ok" -or [string]$r -eq "manual") { Write-OK "Mod files extracted to $modFolder" }
else { Write-Fail 'The archive was not installed; no Hub markers will be written.'; Pause-User "Press Enter to exit..."; exit 1 }

# ---- STEP 5: verify launcher + desktop shortcut ----
Write-Step 5 6 "Finishing setup"
$launcherPath = Join-Path $modFolder $launcherName
if (-not (Test-Path $launcherPath)) {
    # Fallback: the zip may have unpacked into a nested subfolder - search.
    $found = Get-ChildItem -Path $modFolder -Filter $launcherName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $launcherPath = $found.FullName; $modFolder = Split-Path -Parent $launcherPath }
}
if (Test-Path $launcherPath) {
    Write-OK "Launcher found: $launcherName"
} else {
    Write-Fail "$launcherName was not found under $modFolder. Setup cannot safely mark this mod installed."
    Pause-User "Press Enter to exit..."
    exit 1
}

$survivalPaths = @($launcherPath)
if ($modChoice -eq '1') {
    $survivalPaths += @((Join-Path $modFolder 'fh6vrhook.dll'), (Join-Path $modFolder 'openxr_loader.dll'))
} elseif ($modChoice -eq '2') {
    $survivalPaths += @((Join-Path $modFolder 'dxgi.dll'), (Join-Path $modFolder 'openxr_loader.dll'), (Join-Path $modFolder 'vrmod_inject_dll.dll'))
} else {
    $survivalPaths += @((Join-Path $modFolder 'dxgi.dll'), (Join-Path $modFolder 'host\xrfb-openxr-host.exe'))
}
if (-not (Confirm-PlacedFilesSurvive -Paths $survivalPaths -GameDir $modFolder -ArchivePath $zipPath)) {
    Write-Fail 'Required VR files did not survive the antivirus check; no Hub markers will be written.'
    Pause-User 'Press Enter to exit...'
    exit 1
}

# Custom desktop-shortcut icon, shared by all mods. Copy the bundled
# .ico into the install root so the shortcut keeps a stable icon path
# (mirrors the BotW installer). Falls back to the launcher's own icon
# if the copy fails for any reason.
$iconDest = Join-Path $installRoot "ForzaHorizon6_VR.ico"
try { Copy-Item -Path (Join-Path $PSScriptRoot "ForzaHorizon6_VR.ico") -Destination $iconDest -Force } catch {}

try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "Forza Horizon 6 VR.lnk"
     $sc = New-DesktopShortcut -LnkPath $lnk -TargetPath $launcherPath -WorkingDir $modFolder -IconPath $(if (Test-Path $iconDest) { $iconDest } else { $launcherPath }) -Description "Launch the Forza Horizon 6 VR mod ($modName)"
    Write-OK "Desktop shortcut created with custom icon: Forza Horizon 6 VR"
} catch {
    Write-Warn "Could not create the desktop shortcut. You can start $launcherName from $modFolder."
}

# Record the PARENT install path. The Hub's alternative-mod detection then
# checks NALULUNA / lufz / CheekyRender below it: VR Ready if any launcher
# is present, with at most two compact tile choices and every choice on the
# detail page.
# We deliberately do NOT write a .launch_exe override here - that would
# short-circuit the two-mod choice and always launch one fixed mod.
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $installRoot -Encoding UTF8 -Force } catch {}
# Clean up any stale single-launcher override from an older install.
try { $ov = Join-Path $PSScriptRoot ".launch_exe"; if (Test-Path $ov) { Remove-Item $ov -Force -ErrorAction SilentlyContinue } } catch {}

# lufz installs: record the installed mod version so the Hub's update badge
# clears after an update (catalog pins the current lufz version; a mismatch
# shows Update). NORMALIZED without a leading "v" - the Hub compares against
# Get-ModVersionFromString output, which strips the v (writing "v1.2.3"
# would flag it out-of-date forever).
# NALULUNA installs deliberately do NOT touch this file: it tracks the
# lufz build, and overwriting it here would wipe a pending lufz update.
if ($modChoice -eq "2") {
    # PRIMARY source: the VERSION file lufz ships inside the zip -
    # authoritative and survives a renamed zip. Fall back to the zip
    # name, then to the pinned release. Note $modFolder, not
    # $installRoot: the lufz build lives in its own subfolder here.
    #
    # (History: the 1.2.1 hotfixes reused the same zip name AND VERSION,
    # so the Hub tracked them as 1.2.1b/1.2.1c. lufz moved to a real
    # 1.2.3, so that workaround is retired - the zip is honest again.)
    # ---- The installed version, from THREE sources that must agree ----
    # Same mod, same publisher, same well-behaved shape as on the
    # Horizon 5 entry: tag v1.3.19, asset VRMod-v1.3.19.zip, VERSION
    # file 1.3.19. Read all three, cross-check, and write plain digits -
    # that is exactly what the tile compares against.
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
    if (Test-Path -LiteralPath $lufzVerFile) {
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
        if ($agree) {
            Write-OK "Installed version $lufzVer (confirmed by $($seen.Count) of 3 sources)."
        } else {
            Write-Warn ("Version sources disagree: name=$verFromName tag=$verFromTag file=$verFromFile - using $lufzVer.")
        }
        try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $lufzVer -Encoding ASCII -Force } catch {}
        # ALSO write the durable stamp next to the GAME (2026-08-20).
        # The line above lands inside the Hub folder and is gone as
        # soon as a new Hub build is dropped in; the scan then finds
        # no marker and seeds the CURRENT online tag, swallowing a
        # pending update. The game-side stamp survives that.
        Save-InstalledStamp -GameDir $installRoot -Version $lufzVer
    } else {
        Write-Warn "No version could be read - the Hub will seed it on the next scan."
        try { Remove-Item -LiteralPath (Join-Path $PSScriptRoot ".installed_version") -Force -ErrorAction SilentlyContinue } catch {}
    }
} elseif ($modChoice -eq "3") {
    # CheekyRender has no VERSION file, so preserve the exact release tag
    # resolved from GitHub (or recover it from a manually supplied filename).
    $cheekyVersion = if ($rel -and $rel.Tag) { [string]$rel.Tag } else { $null }
    if (-not $cheekyVersion -and $zipLeaf -match '(?i)CheekyRender-v?(.+?)-win64\.zip$') {
        $cheekyVersion = [string]$matches[1]
    }
    if ($cheekyVersion) {
        try { Set-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_version_b') -Value $cheekyVersion -Encoding UTF8 -Force } catch {}
        try { Set-Content -LiteralPath (Join-Path $installRoot '.pcvrhub_version_b') -Value $cheekyVersion -Encoding UTF8 -Force } catch {}
        Write-OK "Installed CheekyRender release $cheekyVersion."
    } else {
        Write-Warn 'The release tag could not be recorded; the next scan will establish the current baseline.'
    }
}

# ---- STEP 6: how to play ----
Write-Step 6 6 "How to play"
Write-Host "============================================================" -ForegroundColor Yellow
if ($modChoice -eq "1") {
    Write-Host " NALULUNA - HOW TO PLAY" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " 1) Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, the desktop" -ForegroundColor White
    Write-Host "    shortcut, or fh6vr.exe in the NALULUNA folder:" -ForegroundColor White
    Write-Host "    $modFolder" -ForegroundColor Gray
    Write-Host "    then press the 'Launch' button to start Forza Horizon 6." -ForegroundColor White
    Write-Host " 2) Once you are in a car, press Tab a few times to switch" -ForegroundColor White
    Write-Host "    to cockpit view - that view is shown in the headset." -ForegroundColor White
    Write-Host " 3) Ctrl + Space recenters the headset." -ForegroundColor White
    Write-Host ""
    Write-Host " Settings: lower graphics, V-Sync OFF, frame rate unlimited," -ForegroundColor Gray
    Write-Host " motion blur / DLSS / frame generation OFF. DIBR mode is the" -ForegroundColor Gray
    Write-Host " smoothest starting point." -ForegroundColor Gray
    Write-Host ""
    Write-Host " Can't see the in-car UI (map, speedometer, etc.)? In Settings >" -ForegroundColor Gray
    Write-Host " HUD & Gameplay, set 'HUD Safe Frame Vertical' to 25 (far right)." -ForegroundColor Gray
} elseif ($modChoice -eq "2") {
    Write-Host " lufz VRMod - HOW TO PLAY" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " 1) Start from the desktop shortcut (or run vrmod-launcher.exe)." -ForegroundColor White
    Write-Host " 2) Click '+ Add Game' and pick the game FOLDER, then click" -ForegroundColor White
    Write-Host "    'Install VR Mod'. On Game Pass pick" -ForegroundColor White
    Write-Host "    " -NoNewline -ForegroundColor White
    Write-Host " C:\XboxGames\Forza Horizon 6\Content " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "    - Windows blocks opening the exe there. On Steam you can" -ForegroundColor White
    Write-Host "    also use '+ Add .exe', or 'Auto-detect Running'." -ForegroundColor White
    Write-Host " 3) Start SteamVR, launch the game (" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub" -ForegroundColor White
Write-Host "    or your store), then click 'Play in VR'" -ForegroundColor White
    Write-Host "    once you reach the main menu, garage, or are driving." -ForegroundColor White
    Write-Host ""
    Write-Host " Settings: for OpenXR 6DoF turn HDR OFF and set in-game FOV to" -ForegroundColor Gray
    Write-Host " maximum." -ForegroundColor Gray
    Write-Host ""
    Write-Host " Leave " -NoNewline -ForegroundColor White
    Write-Host " Frame Generation " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " OFF - the mod author asks for" -ForegroundColor White
    Write-Host " that with this version. It also clears out a few old config" -ForegroundColor White
    Write-Host " values that could cause trouble - the rest of your tuning" -ForegroundColor White
    Write-Host " stays." -ForegroundColor White
} else {
    Write-Host " CheekyRender - HOW TO PLAY" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " 1) Prepare your headset and preferred OpenXR runtime." -ForegroundColor White
    Write-Host " 2) Start CheekyRender from" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub." -ForegroundColor White
    Write-Host "    Select the FH6 install if it was not detected, then use" -ForegroundColor White
    Write-Host "    'Start VR + FH6'." -ForegroundColor White
    Write-Host " 3) On first launch and after every update, follow the hook scan:" -ForegroundColor White
    Write-Host "    Driver Camera, Far Chase Camera, then pause/unpause 5 times." -ForegroundColor White
    Write-Host " 4) When the launcher says the profile was updated, restart the" -ForegroundColor White
    Write-Host "    game. The next launch should say 'generated profile active'." -ForegroundColor White
    Write-Host ""
    Write-Host " Start with Mono for performance (no stereo depth), or use" -ForegroundColor Gray
    Write-Host " AFR-Half / AFR full rate for stereo. Unlock the frame rate," -ForegroundColor Gray
    Write-Host " turn V-Sync off, and keep the complete host folder together." -ForegroundColor Gray
    Write-Host ""
    Write-Host " Early preview: tested by the author on Quest 3 + Virtual" -ForegroundColor Yellow
    Write-Host " Desktop + Game Pass. Other combinations are not validated yet." -ForegroundColor Yellow
}
Write-Host ""
Write-Host " Your VR mod is installed here (opening it now):" -ForegroundColor White
Write-Host "   $modFolder" -ForegroundColor Gray
Write-Host " Run it from this folder or the desktop shortcut - the launcher" -ForegroundColor Gray
Write-Host " connects to Forza Horizon 6 itself." -ForegroundColor Gray
Write-Host " Only one mod's dxgi.dll can be active. Before changing mods," -ForegroundColor Yellow
Write-Host " use the current launcher's Uninstall action, then start the other." -ForegroundColor Yellow
try { Start-Process $modFolder } catch {}
# ---- Signoff ----
Write-Host ""
Write-Host " Chase the horizon, feel every gear change, and let the festival roar." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
