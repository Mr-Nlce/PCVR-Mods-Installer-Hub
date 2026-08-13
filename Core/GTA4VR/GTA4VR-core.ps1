# ============================================================
# GTA IV VR - Installer (gtaiv-dxvk-vr by Hochgeschwindigkeitsrennfahrer)
# ============================================================
# WIP VR glue for GTA IV Complete Edition: stock DXVK 3.0.2 as
# d3d9.dll + the project's Win32 ASI + OpenVR. SteamVR ONLY - there is
# no OpenXR path. Head tracking and stereo submit work; motion
# controller hands do not exist yet, a gamepad is the input.
#
# The release ships the contents of a "drop-into-GTAIV" folder that is
# merged PER FILE into the game's GTAIV subfolder (the one holding
# GTAIV.exe) - no own install folder, no C:\Games.
#
# TWO ASSETS ON THE RELEASE, and their difference is tiny: both hold
# the same ASI, the same DXVK and the same FusionFix payload. Verified
# by unpacking both - the only differences are a shipped
# commandline.txt vs the RC2 notes file, and the value in
# gtaiv_dxvk_vr.ipd.
#
# STAND v0.9.09-hud4 (2026-08): der Installer SCHREIBT KEINE Einstellungen
# mehr. Frueher fragte er nach "AER" oder "Other stereo" und setzte danach
# ipd/stereoscale/fpfov aus den damaligen Release-Notes. Das Paket bringt
# seine Einstellungsdateien inzwischen selbst und abgestimmt mit
# (Modus 909, vres 2048, fpfov 90 90 90) - eigene Werte hineinzuschreiben
# wuerde sie nur verschlechtern. Er zeigt jetzt nur noch, was da liegt.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "GTA IV VR Installer"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " GTA IV VR Installer" -ForegroundColor Cyan
    Write-Host " gtaiv-dxvk-vr | Complete Edition | SteamVR | gamepad" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR  = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO        = "Hochgeschwindigkeitsrennfahrer/Grand-Theft-Auto-IV-VR-Mod"
$REPO_API    = "https://api.github.com/repos/$REPO/releases"
$RELEASE_PAGE= "https://github.com/$REPO/releases"
$APP_ID      = "12210"
$GAME_EXE    = "GTAIV.exe"
$MOD_ASI     = "gtaiv_dxvk_vr.asi"
$PAYLOAD_DIR = "drop-into-GTAIV"

# Store layouts. The mod files go into the GTAIV SUBFOLDER of these.
$CANDIDATE_ROOTS = @(
    "C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto IV",
    "C:\Program Files\Rockstar Games\Grand Theft Auto IV",
    "C:\Program Files (x86)\Rockstar Games\Grand Theft Auto IV"
)

function Get-LatestGtaIvVr {
    try {
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub" }
        $rels = Invoke-RestMethod -Uri "$REPO_API`?per_page=5" -Headers $headers -TimeoutSec 25 -ErrorAction Stop
        foreach ($rel in @($rels)) {
            # Only the .zip asset - the second asset on this release carries
            # a non-archive extension and holds the same payload anyway.
            $zips = @($rel.assets | Where-Object { $_.name -match '(?i)\.zip$' })
            if ($zips.Count -gt 0) {
                $pick = $zips | Where-Object { $_.name -match '(?i)(gtaiv|dxvk|vr)' } | Select-Object -First 1
                if (-not $pick) { $pick = $zips[0] }
                return @{ Url = [string]$pick.browser_download_url; Tag = [string]$rel.tag_name; Name = [string]$pick.name }
            }
        }
    } catch { }
    return $null
}

# Find <game>\GTAIV, the folder that actually holds GTAIV.exe.
function Find-GtaIvFolder {
    $roots = New-Object System.Collections.Generic.List[string]
    try {
        # Signature checked in InstallerSafety.ps1: -SteamFolderNames (array),
        # -Subdir and -ProbeExe. -FolderName does not exist.
        $steam = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("Grand Theft Auto IV") -ProbeExe "GTAIV\$GAME_EXE"
        if ($steam) { [void]$roots.Add([string]$steam) }
    } catch { }
    foreach ($c in $CANDIDATE_ROOTS) { [void]$roots.Add($c) }
    foreach ($r in $roots) {
        if (-not $r) { continue }
        foreach ($sub in @("GTAIV", "")) {
            $cand = if ($sub) { "$r\$sub" } else { $r }
            if (Test-Path -LiteralPath "$cand\$GAME_EXE") { return $cand }
        }
    }
    return $null
}

Write-Header
Write-Host "  Liberty City with head tracking and real stereo depth, built on" -ForegroundColor Gray
Write-Host "  stock DXVK and OpenVR. Experimental head aiming while aiming down" -ForegroundColor Gray
Write-Host "  sights. This is an early proof of concept, not a finished port:" -ForegroundColor Gray
Write-Host "  no motion controller hands, you play it on a gamepad." -ForegroundColor Gray
Write-Host ""
Write-Host "  Needed: GTA IV COMPLETE EDITION and SteamVR." -ForegroundColor White
Write-Host "  There is no OpenXR path - SteamVR has to be running." -ForegroundColor Gray
Pause-User "Press Enter to start the installation..." | Out-Null

# ---- 1. locate the game -------------------------------------
Write-Step 1 4 "Locating GTA IV"

$gtaDir = Find-GtaIvFolder
if ($gtaDir) { Write-OK "Found: $gtaDir" }
else {
    Write-Warn "GTA IV was not found automatically."
    Write-Host "  Drag your GTAIV folder here (the one with $GAME_EXE) and press Enter." -ForegroundColor White
    Write-Host "  Steam example:" -ForegroundColor Gray
    Write-Host "    C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto IV\GTAIV" -ForegroundColor Gray
    while (-not $gtaDir) {
        $r = (Read-Host "  Folder").Trim().Trim('"')
        if (-not $r) { Write-Fail "Nothing entered."; continue }
        if (Test-Path -LiteralPath "$r\$GAME_EXE") { $gtaDir = $r }
        elseif (Test-Path -LiteralPath "$r\GTAIV\$GAME_EXE") { $gtaDir = "$r\GTAIV" }
        else { Write-Fail "$GAME_EXE not found in: $r" }
    }
    Write-OK "Using: $gtaDir"
}

# ---- 2. download --------------------------------------------
Write-Step 2 4 "Downloading gtaiv-dxvk-vr"

$tmp = Join-Path $env:TEMP ("gtaivvr_" + [Guid]::NewGuid().ToString("N"))
try { New-Item -ItemType Directory -Path $tmp -Force -ErrorAction Stop | Out-Null }
catch { Write-Fail "Could not create a temp folder: $_"; Pause-User "Press Enter to exit..." | Out-Null; exit 1 }
$zipDest = Join-Path $tmp "gtaiv_dxvk_vr.zip"

$urls = New-Object System.Collections.Generic.List[string]
$relTag = $null
Write-Info "Resolving the newest release ..."
$latest = Get-LatestGtaIvVr
if ($latest) {
    Write-OK "Release: $($latest.Tag)  ($($latest.Name))"
    $relTag = [string]$latest.Tag
    [void]$urls.Add([string]$latest.Url)
} else {
    Write-Warn "GitHub API not reachable - you will be pointed at the releases page."
}

Invoke-SafeDownload -Urls $urls -Destination $zipDest -Label "gtaiv-dxvk-vr" `
    -ManualUrl $RELEASE_PAGE `
    -Instructions "Download the gtaiv-dxvk-vr .zip from the releases page, save it as '$zipDest', then choose Retry." `
    -SkipMessage "" | Out-Null

while (-not (Test-Path -LiteralPath $zipDest)) {
    Write-Fail "The archive is not present at: $zipDest"
    $fb = Invoke-InstallerFallback -Action "download gtaiv-dxvk-vr" `
        -Subject "the gtaiv-dxvk-vr release archive" -Url $RELEASE_PAGE -DestFile $zipDest `
        -Instructions "Download the .zip from the releases page, save it as '$zipDest', then choose Retry. You can also paste the full path to an already-downloaded archive." `
        -AllowSkip $false
    if ([string]$fb -eq "quit") {
        try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null; exit 1
    }
}
Write-OK "Archive ready."

# ---- 3. merge into the game folder --------------------------
Write-Step 3 4 "Installing into $gtaDir"

$exDir = Join-Path $tmp "x"
try {
    New-Item -ItemType Directory -Path $exDir -Force -ErrorAction Stop | Out-Null
    Expand-Archive -LiteralPath $zipDest -DestinationPath $exDir -Force -ErrorAction Stop
} catch {
    Write-Fail "Unpacking failed: $($_.Exception.Message)"
    try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."; exit 1
}

# The payload lives in drop-into-GTAIV; search for it instead of
# assuming the archive's top level never changes.
$payload = $null
$cand = Join-Path $exDir $PAYLOAD_DIR
if (Test-Path -LiteralPath $cand) { $payload = $cand }
if (-not $payload) {
    $hit = Get-ChildItem -LiteralPath $exDir -Directory -Recurse -Depth 3 -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -ieq $PAYLOAD_DIR } | Select-Object -First 1
    if ($hit) { $payload = $hit.FullName }
}
if (-not $payload) {
    $hit = Get-ChildItem -LiteralPath $exDir -File -Recurse -Depth 3 -Filter $MOD_ASI -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $payload = Split-Path -Parent $hit.FullName }
}
if (-not $payload) {
    Write-Fail "Could not find the mod files inside the archive."
    Write-Info "Expected a '$PAYLOAD_DIR' folder holding $MOD_ASI."
    try { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."; exit 1
}

# Back up the stock files this pack replaces, once. The pack brings its
# own .stock-302 / .bak copies of some of them, but a d3d9.dll from an
# earlier mod install would otherwise be gone for good.
foreach ($f in @("d3d9.dll", "dinput8.dll")) {
    $orig = Join-Path $gtaDir $f
    $bak  = "$orig.vrbak"
    if ((Test-Path -LiteralPath $orig) -and -not (Test-Path -LiteralPath $bak)) {
        try { Copy-Item -LiteralPath $orig -Destination $bak -Force; Write-Info "Backed up $f -> $f.vrbak" } catch {}
    }
}

Write-Info "Merging the mod files into the game folder ..."
$copyFail = $null
try {
    Get-ChildItem -LiteralPath $payload -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $gtaDir -Recurse -Force -ErrorAction Stop
    }
} catch { $copyFail = $_.Exception.Message }

if ($copyFail) {
    # Program Files needs elevation - retry the whole merge elevated.
    Write-Warn "Copying needs administrator rights here. Asking for them ..."
    $ps = "Get-ChildItem -LiteralPath '$payload' -Force | ForEach-Object { Copy-Item -LiteralPath `$_.FullName -Destination '$gtaDir' -Recurse -Force }"
    try {
        Start-Process powershell -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-Command",$ps) -Verb RunAs -Wait -ErrorAction Stop
    } catch { }
}

if (-not (Test-Path -LiteralPath (Join-Path $gtaDir $MOD_ASI))) {
    Write-Fail "$MOD_ASI is not in the game folder - the install did not complete."
    Write-Host "  Copy everything from this folder into $gtaDir yourself:" -ForegroundColor Gray
    Write-Host "    $payload" -ForegroundColor Cyan
    try { Start-Process $payload } catch {}
    try { Start-Process $gtaDir } catch {}
    Pause-User "Press Enter once the files are copied..." | Out-Null
}
if (Test-Path -LiteralPath (Join-Path $gtaDir $MOD_ASI)) { Write-OK "Mod files are in place." }

# ---- 4. was das Paket selbst mitbringt --------------------------
Write-Step 4 4 "Checking the settings the pack shipped"

# !!! HIER WURDEN FRUEHER EIGENE WERTE HINEINGESCHRIEBEN - DAS IST SEIT
# v0.9.09-hud4 FALSCH UND WURDE ENTFERNT !!!
# Der Installer fragte nach "AER" oder "Other stereo" und schrieb danach
# ipd = 1 bzw. ipd 6 / stereoscale 130 / fpfov 110 110 110 in den
# Spielordner. Diese Zahlen stammten aus den Release-Notes einer FRUEHEREN
# Fassung. Das Paket bringt seine Einstellungsdateien inzwischen SELBST mit
# und ab Werk abgestimmt (Modus 909, vres 2048, fpfov 90 90 90) - unsere
# Werte haetten sie ueberschrieben und die Mod schlechter gemacht.
# Jetzt wird NICHTS mehr geschrieben, nur noch gezeigt, was da liegt.
$sidecars = @("gtaiv_dxvk_vr.stereo", "gtaiv_dxvk_vr.vres", "gtaiv_dxvk_vr.ipd",
              "gtaiv_dxvk_vr.stereoscale", "gtaiv_dxvk_vr.fpfov", "gtaiv_dxvk_vr.buildid")
Write-Host "  The pack ships its own settings, already tuned. Nothing is" -ForegroundColor Gray
Write-Host "  overwritten here - this is what came with your download:" -ForegroundColor Gray
Write-Host ""
foreach ($sc in $sidecars) {
    $scPath = Join-Path $gtaDir $sc
    if (Test-Path -LiteralPath $scPath) {
        $val = ""
        try { $val = ((Get-Content -LiteralPath $scPath -Raw -ErrorAction Stop) -replace '[^\x20-\x7E]', '').Trim() } catch {}
        Write-Host ("     {0,-30} {1}" -f $sc, $val) -ForegroundColor White
    }
}
Write-Host ""
Write-Host "  All of them are plain text next to $GAME_EXE - edit with Notepad" -ForegroundColor Gray
Write-Host "  and restart. In the headset: F3 opens the VR menu, F5 cycles the" -ForegroundColor Gray
Write-Host "  eye resolution, F6 stereo scale, F8 IPD, F9 recenters, F10 sets" -ForegroundColor Gray
Write-Host "  the seated baseline." -ForegroundColor Gray
Write-Host ""
Write-Host "  Two things the pack expects:" -ForegroundColor White
Write-Host "   - FusionFix graphics: DirectX 9, NOT its Vulkan path" -ForegroundColor White
Write-Host "   - FirstPerson.asi OFF (rename it to FirstPerson.asi.off if you" -ForegroundColor White
Write-Host "     have it) - this mod owns the camera and FOV path" -ForegroundColor White
Write-Host ""
$qs = Join-Path $gtaDir "QUICK-START.bat"
if (Test-Path -LiteralPath $qs) {
    Write-OK "QUICK-START.bat is in place - it starts SteamVR and then the game."
} else {
    Write-Info "No QUICK-START.bat in the pack - start SteamVR first, then the game."
}

try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gtaDir -Encoding UTF8 -Force } catch {}
try { if ($relTag) { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $relTag -Encoding UTF8 -Force } } catch {}

# -------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " GTA IV VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |            REQUIRED IN-GAME SETTING                  |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""
Write-Host "   FusionFix graphics options: DirectX 9 (NOT Vulkan) " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Start SteamVR before the game to avoid it potentially starting" -ForegroundColor Gray
Write-Host "  sometimes out of focus." -ForegroundColor Gray
Write-Host ""
Write-Host "  HOW TO PLAY:" -ForegroundColor Cyan
Write-Host "    Launch with" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or start GTA IV through" -ForegroundColor Gray
Write-Host "    Steam. Play it on a gamepad - there are no VR hands." -ForegroundColor Gray
Write-Host ""
Write-Host "  IN GAME:" -ForegroundColor Cyan
Write-Host "    F3 or gamepad Back  VR menu        F9 or R3  recenter" -ForegroundColor Gray
Write-Host "    F4  cycle stereo profiles          F5  eye resolution" -ForegroundColor Gray
Write-Host ""
Write-Host "  To play flat for a while, use the Flat / VR switch on the game's" -ForegroundColor DarkGray
Write-Host "  page in the Hub. Config files are covered in the README." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Liberty City, at eye level. Niko never had it this real." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
