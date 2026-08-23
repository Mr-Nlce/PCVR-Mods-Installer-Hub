# -------------------------------------------------------
# Painkiller: Black Edition VR Mod Installer
# painkiller-vr-mod by FluorescentHallucinogen (OpenXR)
#
# Adds native OpenXR VR to the original Painkiller (People Can Fly).
# Tested with Painkiller: Black Edition on Steam + Quest 2 + Virtual
# Desktop; expected to work with other OpenXR headsets/runtimes.
#
# Install shape (differs from the merge-into-root mods):
# 1. Download the latest release ZIP from GitHub (auto-update aware).
# 2. Unpack; the payload is a /Bin folder with 4 files:
#    PainKiller.exe, Engine.dll, D3Dev.dll, openxr_loader.dll.
# 3. Locate the game (Steam / GOG); the game ROOT holds a Bin folder
#    with PainKiller.exe.
# 4. BACK UP the two original files the mod overwrites (PainKiller.exe,
#    Engine.dll) to *.vrbak once, so flat mode can be restored.
# 5. Copy the 4 mod files into <game>\Bin.
# 6. Enable VR: add "Cfg.VideoVR = true" to <game>\Bin\config.ini.
#
# The Hub tracks updates via the GitHub latest tag (GithubRepo in the
# catalog) vs .installed_version, written verbatim from tag_name here.
# -------------------------------------------------------

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Painkiller Black Edition VR Installer"

$MOD_AUTHOR = "FluorescentHallucinogen"
$GAME_APPID = "39530"
$GAME_NAME  = "Painkiller Black Edition"
$GAME_EXE   = "Bin\PainKiller.exe"

$GITHUB_API_LATEST = "https://api.github.com/repos/FluorescentHallucinogen/painkiller-vr-mod/releases/latest"
$GITHUB_RELEASES   = "https://github.com/FluorescentHallucinogen/painkiller-vr-mod/releases"

# The files the mod ships in /Bin. The first two OVERWRITE originals
# (so they get backed up); the last two are mod-only additions.
$MOD_BIN_FILES     = @("PainKiller.exe", "Engine.dll", "D3Dev.dll", "openxr_loader.dll")
$MOD_OVERWRITES    = @("PainKiller.exe", "Engine.dll")

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor DarkYellow
 Write-Host " Painkiller: Black Edition VR Mod Installer" -ForegroundColor Yellow
 Write-Host " OpenXR VR mod by $MOD_AUTHOR" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor DarkYellow
 Write-Host ""
}
function Write-Step { param([int]$Step, [int]$Total, [string]$Title) Write-Host ""; Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan; Write-Host "----------------------------------------" -ForegroundColor DarkGray }
function Write-OK   { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m" -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam", "HKLM:\SOFTWARE\Valve\Steam", "HKCU:\SOFTWARE\Valve\Steam")) {
 try { $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if ($p -and (Test-Path $p)) { return $p } } catch {}
 }
 return $null
}
function Get-SteamLibraries {
 param($SteamPath)
 $libs = @()
 if (-not $SteamPath) { return $libs }
 $libs += $SteamPath
 $vdf = Join-Path $SteamPath "steamapps\libraryfolders.vdf"
 if (Test-Path $vdf) {
 [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
 $l = $_.Groups[1].Value -replace '\\\\', '\'
 if (Test-Path $l) { $libs += $l }
 }
 }
 return ($libs | Select-Object -Unique)
}
function Find-PainkillerGamePath {
 # Steam libraries (folder name "Painkiller Black Edition")
 $sp = Get-SteamPath
 if ($sp) {
 foreach ($lib in (Get-SteamLibraries -SteamPath $sp)) {
 $candidate = "$lib\steamapps\common\Painkiller Black Edition"
 if (Test-Path -LiteralPath "$candidate\$GAME_EXE") { return $candidate }
 }
 }
 # GOG fallback ("Painkiller Black")
 foreach ($gg in @(
 "C:\GOG Games\Painkiller Black", "D:\GOG Games\Painkiller Black", "E:\GOG Games\Painkiller Black",
 "${env:ProgramFiles(x86)}\GOG Galaxy\Games\Painkiller Black",
 "${env:ProgramFiles}\GOG Galaxy\Games\Painkiller Black"
 )) {
 if (Test-Path -LiteralPath "$gg\$GAME_EXE") { return $gg }
 }
 return $null
}

# -------------------------------------------------------
# Intro
# -------------------------------------------------------
Write-Header
Write-Host " Painkiller VR adds native OpenXR VR with motion-controller aiming" -ForegroundColor White
Write-Host " to the original Painkiller. Needs Painkiller 1.64 (Black Edition" -ForegroundColor White
Write-Host " is the tested build) on Steam or GOG, and an OpenXR runtime." -ForegroundColor White
Write-Host ""
Write-Host " The mod replaces two game files in \Bin; this installer backs up" -ForegroundColor Gray
Write-Host " the originals (*.vrbak) so you can restore flat mode." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..."

# -------------------------------------------------------
# STEP 1: download the latest release from GitHub
# -------------------------------------------------------
Write-Step 1 4 "Downloading the latest release"

$dlUrl = $null
$relTag = $null
try {
 [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
 $rel = Invoke-RestMethod -Uri $GITHUB_API_LATEST -Headers @{ "User-Agent" = "VRModHub" } -ErrorAction Stop
 $asset = $rel.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
 if ($asset) {
 $dlUrl = $asset.browser_download_url
 $relTag = [string]$rel.tag_name
 Write-Info "Latest release: $relTag"
 }
} catch {
 Write-Warn "Could not query GitHub for the latest release (rate limit / offline)."
}

$tempExtract = Join-Path $env:TEMP "PainkillerVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempExtract | Out-Null
$modZip = $null

if ($dlUrl) {
 $zipPath = Join-Path $tempExtract "painkiller-vr-mod.zip"
 if (Invoke-DownloadOrFallback -Url $dlUrl -Destination $zipPath -Label "Painkiller VR mod ($relTag)" `
    -ManualUrl $GITHUB_RELEASES `
    -Instructions "Download the mod ZIP from the Releases page, then drop it into your Downloads folder and retry.") {
 $modZip = $zipPath
 }
}
# Fallback: a copy the user downloaded by hand
if (-not $modZip) {
 $manualZip = Get-ChildItem -Path (Join-Path $env:USERPROFILE "Downloads") -Filter "*painkiller*vr*.zip" -ErrorAction SilentlyContinue |
   Sort-Object LastWriteTime -Descending | Select-Object -First 1
 if ($manualZip) { Write-OK "Found a manual download: $($manualZip.Name)"; $modZip = $manualZip.FullName }
}
if (-not $modZip) {
 Write-Fail "No Painkiller VR mod ZIP available - cannot continue."
 try { Remove-Item $tempExtract -Recurse -Force -EA SilentlyContinue } catch {}
 Pause-User "Press Enter to exit."; exit 1
}

# -------------------------------------------------------
# STEP 2: unpack + find the Bin payload
# -------------------------------------------------------
Write-Step 2 4 "Unpacking"
$unpack = Join-Path $tempExtract "unpack"
New-Item -ItemType Directory -Path $unpack | Out-Null
$exRes = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $unpack -Label "Painkiller VR mod"
if (-not $exRes) { Write-Fail "Extraction failed."; try { Remove-Item $tempExtract -Recurse -Force -EA SilentlyContinue } catch {}; Pause-User "Press Enter to exit."; exit 1 }

# Find the folder that actually holds the mod's PainKiller.exe (the /Bin
# directory inside the archive, wherever it sits in the tree).
$srcExe = Get-ChildItem -LiteralPath $unpack -Recurse -Filter "PainKiller.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $srcExe) {
 Write-Fail "PainKiller.exe was not found inside the archive - the layout may have changed."
 Write-Info "Get it manually from: $GITHUB_RELEASES"
 try { Remove-Item $tempExtract -Recurse -Force -EA SilentlyContinue } catch {}
 Pause-User "Press Enter to exit."; exit 1
}
$srcBin = Split-Path -Parent $srcExe.FullName
Write-OK "Mod files ready."

# -------------------------------------------------------
# STEP 3: locate the game + its Bin folder
# -------------------------------------------------------
Write-Step 3 4 "Locating Painkiller"
$gamePath = Find-PainkillerGamePath
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId $GAME_APPID -SteamFolderNames @("Painkiller Black Edition") -GogNames @("Painkiller Black") -ProbeExe $GAME_EXE }
if ($gamePath) {
 Write-OK "Found Painkiller at: $gamePath"
} else {
 Write-Warn "Could not auto-locate Painkiller (Steam / GOG)."
 Write-Host " Paste the path to your Painkiller folder (the game ROOT that" -ForegroundColor White
 Write-Host " contains the Bin folder), then press Enter." -ForegroundColor White
 while (-not $gamePath) {
 $r = (Read-Host " Painkiller folder").Trim().Trim('"').Trim("'")
 if (-not $r) { continue }
 if (Test-Path -LiteralPath "$r\$GAME_EXE") { $gamePath = $r; Write-OK "Game folder set: $gamePath" }
 else { Write-Fail "That folder has no Bin\PainKiller.exe: $r" }
 }
}
$gameBin = Join-Path $gamePath "Bin"

# -------------------------------------------------------
# STEP 4: back up originals, copy mod files, enable VR
# -------------------------------------------------------
$null = Show-UpdateNoticeIfInstalled -TargetDir $gamePath -RelModFile "Bin\D3Dev.dll" -Label "Painkiller VR mod"
Write-Step 4 4 "Installing the mod"

# Back up the two originals the mod overwrites (once). If a .vrbak
# already exists we keep it - never overwrite a good backup with a
# modded file on a re-install.
foreach ($f in $MOD_OVERWRITES) {
 $orig = Join-Path $gameBin $f
 $bak  = "$orig.vrbak"
 if ((Test-Path -LiteralPath $orig) -and -not (Test-Path -LiteralPath $bak)) {
 try { Copy-Item -LiteralPath $orig -Destination $bak -Force -ErrorAction Stop; Write-Info "Backed up original $f -> $f.vrbak" } catch { Write-Warn "Could not back up $f : $($_.Exception.Message)" }
 }
}

# Copy the 4 mod files into <game>\Bin.
try {
 foreach ($f in $MOD_BIN_FILES) {
 $src = Join-Path $srcBin $f
 if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination (Join-Path $gameBin $f) -Force -ErrorAction Stop }
 else { Write-Warn "Mod file missing from archive: $f" }
 }
 Write-OK "Mod files copied into $gameBin"
} catch {
 Write-Fail "Copy failed: $($_.Exception.Message)"
 $__fb = Invoke-InstallerFallback -Action "file copy into the game Bin folder" `
   -Instructions "Copy the *.exe and *.dll files from '$srcBin' into '$gameBin', overwriting when asked. Then choose Skip." `
   -SkipMessage "Skipped - mod files were NOT copied; install is incomplete." `
   -SourceFolder "$srcBin" -DestFolder "$gameBin" -AllowSkip $true
 if ([string]$__fb -eq "quit") { try { Remove-Item $tempExtract -Recurse -Force -EA SilentlyContinue } catch {}; Pause-User "Press Enter to exit."; exit 1 }
}

# Enable VR in config.ini: ensure a line "Cfg.VideoVR = true" exists.
# Idempotent - if a Cfg.VideoVR line is already there, normalise it to
# true; otherwise append it. Create the file if it's missing.
try {
 $cfg = Join-Path $gameBin "config.ini"
 if (Test-Path -LiteralPath $cfg) {
 $lines = Get-Content -LiteralPath $cfg
 if ($lines -match '^\s*Cfg\.VideoVR\s*=') {
 $lines = $lines -replace '^\s*Cfg\.VideoVR\s*=.*', 'Cfg.VideoVR = true'
 Set-Content -LiteralPath $cfg -Value $lines -Encoding UTF8 -Force
 } else {
 Add-Content -LiteralPath $cfg -Value "Cfg.VideoVR = true" -Encoding UTF8
 }
 } else {
 Set-Content -LiteralPath $cfg -Value "Cfg.VideoVR = true" -Encoding UTF8 -Force
 }
 Write-OK "VR enabled in config.ini (Cfg.VideoVR = true)."
} catch {
 Write-Warn "Could not edit config.ini automatically. Add this line to <game>\Bin\config.ini yourself:"
 Write-Host "     Cfg.VideoVR = true" -ForegroundColor White
}

# Sanity check
if (Test-Path -LiteralPath (Join-Path $gameBin "openxr_loader.dll")) { Write-OK "openxr_loader.dll present in Bin." }
else { Write-Warn "openxr_loader.dll missing from Bin - the mod may not load." }

# Record markers for the Hub (VR Ready + update badge + launch route).
# .launch_exe points "Start in VR" at the modded Bin\PainKiller.exe
# directly, for EVERY store. The game has a Steam AppId, but launching
# via steam://rungameid fails on a GOG copy ("no licenses"), and the
# mod replaces PainKiller.exe in-place on both stores, so the direct
# exe is the correct launch route wherever it's installed.
try {
 Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force
 if ($relTag) { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $relTag -Encoding UTF8 -Force }
 # ALSO write the durable stamp next to the GAME (2026-08-20).
 # The line above lands inside the Hub folder and is gone as
 # soon as a new Hub build is dropped in; the scan then finds
 # no marker and seeds the CURRENT online tag, swallowing a
 # pending update. The game-side stamp survives that.
 Save-InstalledStamp -GameDir $gamePath -Version $relTag
 Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value ([System.IO.Path]::Combine($gamePath, "Bin", "PainKiller.exe")) -Encoding UTF8 -Force
} catch {}

try { Remove-Item $tempExtract -Recurse -Force -EA SilentlyContinue } catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor DarkRed
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor DarkRed
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |              IMPORTANT IN-GAME SETTING                |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Painkiller defaults to a very low resolution. Raise it or the" -ForegroundColor White
Write-Host "  VR image looks blurry:" -ForegroundColor White
Write-Host ""
Write-Host "   In the main menu or in-game press " -NoNewline -ForegroundColor White; Write-Host " Y " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host " for Options," -ForegroundColor White
Write-Host "   open " -NoNewline -ForegroundColor White; Write-Host " Video " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host ", and set the resolution (top row) higher." -ForegroundColor White
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host " Set your OpenXR runtime (Virtual Desktop VDXR is the tested one)," -ForegroundColor White
Write-Host " put your headset on, then launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or" -ForegroundColor White
Write-Host " the desktop shortcut. Motion controllers aim; this game's page" -ForegroundColor White
Write-Host " in the Hub has" -ForegroundColor White
Write-Host " the full control map." -ForegroundColor White
Write-Host ""
Write-Host " To go back to flat: restore PainKiller.exe.vrbak and Engine.dll" -ForegroundColor Gray
Write-Host " .vrbak in \Bin (or set Cfg.VideoVR = false in config.ini)." -ForegroundColor Gray
Write-Host ""
Write-Host " Welcome to Purgatory - now in stereo." -ForegroundColor Cyan
Write-Host ""
Pause-User "Press Enter to exit."
