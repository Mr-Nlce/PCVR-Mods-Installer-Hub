# ============================================================
# My Friendly Neighborhood - VR Mod Installer (MFNVR)
# ============================================================
# Mod: MFNVR by LeviGaming1248,
#      github.com/LeviGaming1248/MyFriendlyNeighborhoodVR
#      (the repo used to be called MFNVR; GitHub still redirects, but we
#       name the new one so nothing depends on that redirect)
#
# Everything below is taken from the release archive itself, not
# from the description. Layout, read from the build of 2026-08-10
# (wrapper "MFNVR-v0.2.0\", 42 entries, 1,488,219 bytes):
#
#   .doorstop_version                            (4.5.0)
#   doorstop_config.ini
#   winhttp.dll                                  BepInEx proxy
#   openxr_loader.dll
#   CHANGELOG.md / README.md / THIRD_PARTY_NOTICES.md
#   MANIFEST.sha256
#   licenses\...                                 BepInEx, OpenXR, Doorstop
#   BepInEx\core\...                             BepInEx 5.4.23.4
#   BepInEx\config\BepInEx.cfg
#   BepInEx\config\MFNVR.cfg
#   BepInEx\plugins\MFNVR.dll                    39.424 B, 16:45
#   BepInEx\plugins\MFNVRConfig.dll
#   BepInEx\plugins\MFNVRRenderBridge.dll
#   My Friendly Neighborhood_Data\Plugins\MFNOpenXR.dll
#
# MFNOpenXR.dll belongs in the _Data\Plugins folder and NOT at the game
# root - that is where Unity's Mono looks for native libraries. The
# payload mirrors the game tree, so it lands correctly by itself.
#
# THE WRAPPER NAME CHANGES with every build (formerly "MFNVR v0.10
# alpha\", now "MFNVR-v0.2.0\"), and the author has shipped the same
# build flat as well. The payload root is therefore RESOLVED through the
# marker doorstop_config.ini rather than assumed (archive rules R1/R2) -
# every layout installs correctly.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "My Friendly Neighborhood VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME     = "My Friendly Neighborhood"
$GAME_EXE      = "My Friendly Neighborhood.exe"
$STEAM_APP     = "1574260"
$SHORTCUT_NAME = "My Friendly Neighborhood VR"

$MOD_REPO      = "LeviGaming1248/MyFriendlyNeighborhoodVR"
$MOD_PAGE      = "https://github.com/LeviGaming1248/MyFriendlyNeighborhoodVR"
$RELEASES_PAGE = "https://github.com/LeviGaming1248/MyFriendlyNeighborhoodVR/releases"

# Marker that identifies the payload root INSIDE the archive: a file
# that sits at the top level of the mod, next to BepInEx\.
$PAYLOAD_MARKER = "doorstop_config.ini"
# Proof that the install really arrived (must not exist beforehand
# on a fresh install, and must change on an update).
$PROOF_FILE     = "BepInEx\plugins\MFNVR.dll"

# The author's own hand calibration ships in the archive. On a
# repeat run these must not overwrite what the user tuned.
$USER_CONFIGS = @(
    "BepInEx\config\MFNVR.cfg",
    "BepInEx\config\MFNVR.LeftHandCalibration.cfg",
    "BepInEx\config\MFNVR.LeftHandRotation.cfg",
    "BepInEx\config\BepInEx.cfg"
)

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " My Friendly Neighborhood - VR Mod Installer" -ForegroundColor Cyan
    Write-Host " MFNVR by LeviGaming1248 | motion controllers, 6DOF" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
# Read-Host is swallowed on purpose: this function is called from
# inside value-returning functions, and its input would otherwise
# become part of their return value.
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host | Out-Null }

# ---- intro ---------------------------------------------------
Write-Header
Write-Host "  Full 6DOF head tracking and motion controllers for My Friendly" -ForegroundColor White
Write-Host "  Neighborhood. Room-scale, tracked weapons, physical wrench." -ForegroundColor White
Write-Host ""
Write-Host "  This is an early alpha. One thing to know before you start:" -ForegroundColor White
Write-Host "   - The author states the mod was generated with AI and the code" -ForegroundColor Yellow
Write-Host "     has not been reviewed by a human." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Needed: the game on Steam, Epic or the Xbox app, and SteamVR or" -ForegroundColor Gray
Write-Host "  the Oculus app as your active OpenXR runtime." -ForegroundColor Gray
Pause-User "Press Enter to begin the installation or update..."

# ---- [1/4] locate the game -----------------------------------
Write-Step 1 4 "Finding My Friendly Neighborhood"

$gameRoot = $null
try {
    $gameRoot = Find-SteamGameFolder -AppId $STEAM_APP `
                    -SteamFolderNames @("My Friendly Neighborhood") `
                    -ProbeExe $GAME_EXE `
                    -EpicNames @("MyFriendlyNeighborhood", "My Friendly Neighborhood")
} catch { $gameRoot = $null }

if (-not $gameRoot) {
    # Xbox app / Game Pass keeps the game one level down in Content\.
    foreach ($xb in @("C:\XboxGames\My Friendly Neighborhood\Content",
                      "D:\XboxGames\My Friendly Neighborhood\Content",
                      "E:\XboxGames\My Friendly Neighborhood\Content")) {
        if (Test-Path -LiteralPath (Join-Path $xb $GAME_EXE)) { $gameRoot = $xb; break }
    }
}
if (-not $gameRoot) {
    $gameRoot = Get-GameFolderInteractive -GameName $GAME_NAME -ProbeFile $GAME_EXE
}
if (-not $gameRoot -or -not (Test-Path -LiteralPath (Join-Path $gameRoot $GAME_EXE))) {
    Write-Fail "Could not find $GAME_EXE - nothing was installed."
    Pause-User "Press Enter to exit."
    return
}
Write-OK "Game folder: $gameRoot"

$proofPath   = Join-Path $gameRoot $PROOF_FILE
$hadMod      = Test-Path -LiteralPath $proofPath
$proofBefore = $null
if ($hadMod) {
    try { $proofBefore = (Get-Item -LiteralPath $proofPath).LastWriteTimeUtc } catch {}
    Write-Info "MFNVR is already installed here - this run updates it."
}

# ---- [2/4] fetch the current release -------------------------
Write-Step 2 4 "Downloading the current MFNVR release"

$dlDir = Join-Path $env:TEMP ("mfnvr_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $dlDir -Force | Out-Null
$zipPath = Join-Path $dlDir "MFNVR.zip"

# GitHub's API lists ONLY uploaded assets - the automatic "Source
# code" archives are not part of assets[], so a .zip from there is
# always a real build. The author currently uploads the same build
# twice (flat and wrapped); either one is fine because the payload
# root is resolved below.
$assetUrl = $null
$relTag   = ""
try {
    $api = Invoke-RestMethod -Uri "https://api.github.com/repos/$MOD_REPO/releases/latest" `
                             -Headers @{ "User-Agent" = "PCVRModsHub" } -TimeoutSec 25
    $relTag = [string]$api.tag_name
    $cand = @($api.assets | Where-Object { $_.name -match '(?i)\.zip$' })
    if ($cand.Count -gt 0) { $assetUrl = [string]($cand[0].browser_download_url) }
    if ($relTag) { Write-Info "Latest release: $relTag" }
} catch {
    Write-Warn "Could not ask GitHub for the latest release: $($_.Exception.Message)"
}

$haveZip = $false
if ($assetUrl) {
    $haveZip = Invoke-SafeDownload -Urls @($assetUrl) -Destination $zipPath -Label "MFNVR" `
                   -ManualUrl $RELEASES_PAGE `
                   -Instructions "Download the MFNVR .zip from the releases page, then drag it onto this window."
}
if (-not $haveZip) {
    $pre = Find-PredownloadedFile -Patterns @("MFN*VR*.zip", "MFNVR*.zip", "*MFN*alpha*.zip") -Label "the MFNVR release"
    if (-not $pre) {
        Write-Host ""
        Write-Host "  Enter opens the releases page. Download the .zip, then come" -ForegroundColor White
        Write-Host "  back here." -ForegroundColor White
        Write-Host "  $RELEASES_PAGE" -ForegroundColor Gray
        Pause-User "Press Enter to open the releases page..."
        try { Start-Process $RELEASES_PAGE } catch { Write-Warn "Open this yourself: $RELEASES_PAGE" }
        Pause-User "Press Enter once the download has finished..."
        $pre = Find-PredownloadedFile -Patterns @("MFN*VR*.zip", "MFNVR*.zip", "*MFN*alpha*.zip") -Label "the MFNVR release" -PageAlreadyOpen
    }
    while (-not $pre) {
        Write-Host ""
        Write-Host "  Drag the downloaded ZIP onto this window, or paste its full" -ForegroundColor Yellow
        Write-Host "  path, then press Enter (empty cancels):" -ForegroundColor White
        $inp = (Read-Host "  ZIP path").Trim().Trim('"').Trim("'")
        if (-not $inp) { break }
        if ((Test-Path -LiteralPath $inp) -and ($inp -match '(?i)\.zip$')) { $pre = $inp }
        else { Write-Warn "Not a .zip file that exists: $inp" }
    }
    if (-not $pre) {
        Write-Fail "No archive to install - nothing was changed."
        try { Remove-Item -LiteralPath $dlDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit."
        return
    }
    Copy-Item -LiteralPath $pre -Destination $zipPath -Force
    $haveZip = $true
}
Write-OK "Archive ready."

# ---- [3/4] look inside, then install -------------------------
Write-Step 3 4 "Installing into the game folder"

# R1: read the layout BEFORE unpacking. The author ships the same
# build flat and wrapped, so the layout is never assumed.
$layout = Get-ArchiveTopLevel -ArchivePath $zipPath
if ($layout -and $layout.Ok) {
    $inArc = @($layout.Entries | Where-Object { (Split-Path $_ -Leaf) -ieq $PAYLOAD_MARKER } | Select-Object -First 1)
    if ($inArc.Count -gt 0) {
        $pfx = Split-Path $inArc[0] -Parent
        if ($pfx) { Write-Info "Archive wraps the mod in '$pfx' - it will be unwrapped." }
        else      { Write-Info "Archive is flat." }
    } else {
        Write-Warn "'$PAYLOAD_MARKER' is not in this archive - it may be the wrong file."
    }
} else {
    Write-Warn "Could not read the archive listing - the layout is checked after unpacking."
}

$exDir = Join-Path $dlDir "unpacked"
try {
    Expand-Archive -LiteralPath $zipPath -DestinationPath $exDir -Force -ErrorAction Stop
} catch {
    Write-Fail "Could not unpack the archive: $($_.Exception.Message)"
    try { Remove-Item -LiteralPath $dlDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    return
}

# Keep the user's own tuning. The archive carries the author's hand
# calibration; on a repeat run those files stay as the user left them.
if ($hadMod) {
    $kept = 0
    foreach ($rel in $USER_CONFIGS) {
        if (-not (Test-Path -LiteralPath (Join-Path $gameRoot $rel))) { continue }
        $inNew = Get-ChildItem -LiteralPath $exDir -Recurse -File -Filter (Split-Path $rel -Leaf) -ErrorAction SilentlyContinue
        foreach ($f in $inNew) { try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop; $kept++ } catch {} }
    }
    if ($kept -gt 0) { Write-Info "Kept your existing config and hand calibration ($kept file(s))." }
}

# R2: the destination is decided by the marker, not by guessing.
$place = Move-PayloadIntoPlace -SearchRoot $exDir -TargetDir $gameRoot -Marker $PAYLOAD_MARKER
if (-not $place.Ok) {
    Write-Fail "The mod files were not delivered: $($place.Message)"
    # R4: say where things actually are.
    $stray = @(Get-ChildItem -LiteralPath $exDir -Recurse -Filter $PAYLOAD_MARKER -File -ErrorAction SilentlyContinue)
    foreach ($s in $stray) { Write-Info "Unpacked files are here: $(Split-Path $s.FullName -Parent)" }
    Write-Info "Copy their contents into: $gameRoot"
    try { Remove-Item -LiteralPath $dlDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    return
}
Write-OK "$($place.Moved) file(s) copied into the game folder."

# R3: proof must be something that was not already there.
$installed = $false
if (Test-Path -LiteralPath $proofPath) {
    if (-not $hadMod) {
        $installed = $true
    } else {
        $now = $null
        try { $now = (Get-Item -LiteralPath $proofPath).LastWriteTimeUtc } catch {}
        if ($now -and $proofBefore -and $now -ne $proofBefore) { $installed = $true }
        elseif ($place.Moved -gt 0) { $installed = $true }
    }
}
try { Remove-Item -LiteralPath $dlDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

if (-not $installed) {
    Write-Fail "$PROOF_FILE did not change - the install did not take."
    Pause-User "Press Enter to exit."
    return
}
Write-OK "MFNVR is in place."

# ---- [4/4] shortcut and marker -------------------------------
# R5: state markers are written only now, after the proof passed.
Write-Step 4 4 "Finishing up"

try {
    Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameRoot -Encoding UTF8 -Force
} catch {}

$launchTarget = Join-Path $gameRoot $GAME_EXE
if ($gameRoot -match '(?i)steamapps\\common') { $launchTarget = "steam://rungameid/$STEAM_APP" }
try {
    $sc = New-DesktopShortcut -ShortcutName $SHORTCUT_NAME -TargetPath $launchTarget `
              -WorkingDir $gameRoot -IconPath (Join-Path $gameRoot $GAME_EXE) `
              -Description "My Friendly Neighborhood in VR (MFNVR)"
    if ($sc) { Write-OK "Desktop shortcut '$SHORTCUT_NAME' created." }
} catch { Write-Warn "Could not create the desktop shortcut: $($_.Exception.Message)" }

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  BEFORE YOU START:" -ForegroundColor Cyan
Write-Host "   - Make SteamVR or the Oculus app your active OpenXR runtime." -ForegroundColor Gray
Write-Host "   - In the game's options set " -NoNewline -ForegroundColor Gray; Write-Host " Field of View to about 100 " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  START:" -NoNewline -ForegroundColor Cyan; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the new desktop shortcut." -ForegroundColor Cyan
Write-Host "  Put the headset on once the game is running." -ForegroundColor Gray
Write-Host ""
Write-Host "  New in the August 2026 build: physical weapon switching (right" -ForegroundColor Gray
Write-Host "  hand at the hip or behind the shoulder), the files tab by holding" -ForegroundColor Gray
Write-Host "  your hand behind your head, and much better performance. The" -ForegroundColor Gray
Write-Host "  toolbox works now." -ForegroundColor Gray
Write-Host ""
Write-Host "  Ricky is still on the air, and he still wants you to stay." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
