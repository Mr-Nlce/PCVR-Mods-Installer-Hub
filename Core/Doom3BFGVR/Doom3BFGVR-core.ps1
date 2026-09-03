# ============================================================
#  DOOM 3 BFG Edition - Fully Possessed VR Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "Doom 3 BFG VR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_NAME   = "DOOM 3 BFG Edition"
$GAME_EXE    = "Doom3BFG.exe"
$VR_EXE      = "Doom3BFGVR.exe"
# !!! THE MOD MOVED TO A NEW MAINTAINER (2026-08-29). NPi2Loup's Fully
# Possessed stopped at v0.021j; CommanderKeen83 carries it on with
# two-handed weapon gripping, dual shoulder holsters, off-hand terminal
# interaction and a fixed player-model clipping offset.
#
# !!! TWO KINDS OF ASSET, AND THE DIFFERENCE MATTERS:
#   FULL PACKAGE  ~340 MB, 561 files - the exe, the libraries AND the
#                 whole "Fully Possessed" data folder. Needed by anyone
#                 who has nothing yet.
#   UPDATE        ~29 MB, 14 files - exe and libraries only. Useless on
#                 its own; it goes on top of an existing install.
# Read from both archives, not guessed. The installer decides by NAME
# ("Full-Package") and by SIZE (a full build is far over 100 MB), so a
# renamed asset still lands in the right bucket.
$REPO         = "CommanderKeen83/DOOM-3-BFG-VR"
$RELEASES_URL = "https://github.com/CommanderKeen83/DOOM-3-BFG-VR/releases"
$FULL_MIN_BYTES = 104857600   # 100 MB
# Only the full package carries this - it is how we tell an existing
# install apart from a bare game folder.
$DATA_FOLDER  = "Fully Possessed"

function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "   DOOM 3 BFG Edition - Fully Possessed VR Installer" -ForegroundColor Magenta; Write-Host "   maintained by CommanderKeen83 - two-handed weapons" -ForegroundColor Gray; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "" }
function Write-Step   { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK     { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Warn   { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail   { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-Info   { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Do     { param($x) Write-Host "  [->] $x" -ForegroundColor Cyan }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# Builds an ordered install plan from every release, rather than assuming the
# newest ZIP is self-contained. A fresh install always starts with the newest
# full package, then applies only a same-release or newer small update. An
# existing complete base needs only the newest payload (a small update wins
# when the release happens to publish both forms).
function Get-Doom3BfgReleasePlan {
    param($Releases, [bool]$HasExistingBase, [long]$FullMinBytes = 104857600)
    $assets = @()
    $releaseIndex = -1
    foreach ($release in @($Releases)) {
        $releaseIndex++
        if ($release.draft) { continue }
        foreach ($asset in @($release.assets)) {
            $name = [string]$asset.name
            if ($name -notmatch '(?i)\.zip$' -or $name -match '(?i)source.?code') { continue }
            $isFull = ($name -match '(?i)full.?package') -or ([long]$asset.size -ge $FullMinBytes)
            $assets += [PSCustomObject]@{
                Url = [string]$asset.browser_download_url
                Name = $name
                Tag = [string]$release.tag_name
                Size = [long]$asset.size
                IsFull = [bool]$isFull
                ReleaseIndex = $releaseIndex
            }
        }
    }
    if ($assets.Count -eq 0) { return [PSCustomObject]@{ Plan=@(); Full=$null; Update=$null } }

    $newestReleaseIndex = ($assets | Measure-Object -Property ReleaseIndex -Minimum).Minimum
    $newestReleaseAssets = @($assets | Where-Object { $_.ReleaseIndex -eq $newestReleaseIndex })
    $newestPayload = $newestReleaseAssets | Where-Object { -not $_.IsFull } | Select-Object -First 1
    if (-not $newestPayload) { $newestPayload = $newestReleaseAssets | Where-Object { $_.IsFull } | Select-Object -First 1 }
    if ($HasExistingBase) {
        return [PSCustomObject]@{ Plan=@($newestPayload); Full=($assets | Where-Object IsFull | Select-Object -First 1); Update=($(if ($newestPayload -and -not $newestPayload.IsFull) { $newestPayload } else { $null })) }
    }

    $full = $assets | Where-Object IsFull | Select-Object -First 1
    if (-not $full) { return [PSCustomObject]@{ Plan=@(); Full=$null; Update=$null } }
    $update = $assets | Where-Object { -not $_.IsFull -and $_.ReleaseIndex -le $full.ReleaseIndex } | Select-Object -First 1
    $plan = @($full)
    if ($update) { $plan += $update }
    return [PSCustomObject]@{ Plan=$plan; Full=$full; Update=$update }
}

# Applies the player-model clipping correction to shipped defaults and to any
# already-created per-user config. Missing keys are appended, so a hand-edited
# or older config cannot silently escape the fix. The first original is kept.
function Set-Doom3BfgClippingOffsets {
    param([string[]]$Paths)
    $fixed = 0
    foreach ($cfgPath in @($Paths)) {
        if (-not $cfgPath -or -not (Test-Path -LiteralPath $cfgPath -PathType Leaf)) { continue }
        try {
            $lines = @(Get-Content -LiteralPath $cfgPath -ErrorAction Stop)
            $changed = $false; $foundX = $false; $foundZ = $false
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^\s*set\s+vr_nodalX(?:\s|$)') {
                    $foundX = $true
                    if ($lines[$i] -ne 'set vr_nodalX "-11"') { $lines[$i] = 'set vr_nodalX "-11"'; $changed = $true }
                } elseif ($lines[$i] -match '^\s*set\s+vr_nodalZ(?:\s|$)') {
                    $foundZ = $true
                    if ($lines[$i] -ne 'set vr_nodalZ "-5"') { $lines[$i] = 'set vr_nodalZ "-5"'; $changed = $true }
                }
            }
            if (-not $foundX) { $lines += 'set vr_nodalX "-11"'; $changed = $true }
            if (-not $foundZ) { $lines += 'set vr_nodalZ "-5"'; $changed = $true }
            if ($changed) {
                $backup = $cfgPath + ".pre-vrfix"
                if (-not (Test-Path -LiteralPath $backup)) { Copy-Item -LiteralPath $cfgPath -Destination $backup -ErrorAction Stop }
                Set-Content -LiteralPath $cfgPath -Value $lines -Encoding ASCII -Force
                $fixed++
            }
        } catch { Write-Warn "Could not adjust $([IO.Path]::GetFileName($cfgPath)): $($_.Exception.Message)" }
    }
    return $fixed
}

function Get-SteamPath {
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p=(Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
    }; return $null
}
function Get-SteamLibraries {
    param($sp); $libs=@($sp)
    $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
    if(Test-Path $vdf){ $c=Get-Content $vdf -Raw; [regex]::Matches($c,'"path"\s+"([^"]+)"') | ForEach-Object { $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
    return $libs
}

Write-Header

# STEP 1: Locate DOOM 3 BFG Edition
Write-Host " Fully Possessed, maintained by CommanderKeen83 - native VR with" -ForegroundColor White
Write-Host " two-handed weapons and motion controls for" -ForegroundColor White
Write-Host " DOOM 3 BFG Edition." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 3 "Locating DOOM 3 BFG Edition"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Doom 3 BFG"
    }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath
if (-not $gamePath -and $steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $c = Join-Path $lib "steamapps\common\$GAME_NAME"
        if (Test-Path $c) { $gamePath = $c; break }
    }
}
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "208200" -SteamFolderNames @("DOOM 3 BFG Edition") -ProbeExe "Doom3BFGVR.exe" -GogNames @("DOOM 3 BFG Edition","Doom 3 BFG") }
if ($gamePath) {
    Write-OK "DOOM 3 BFG Edition found: $gamePath"
} else {
    Write-Warn "DOOM 3 BFG Edition not found in Steam libraries automatically."
    Write-Host "  Please enter the game installation folder:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\DOOM 3 BFG Edition" -ForegroundColor Gray
    while (-not $gamePath) {
        $r=(Read-Host "  Path").Trim().Trim('"')
        if(Test-Path $r){$gamePath=$r; Write-OK "Path set: $gamePath"} else{Write-Fail "Not found: $r"}
    }
}

# STEP 2: Download and install
Write-Step 2 3 "Getting Doom 3 BFG VR"

# ---- Which assets do we need? --------------------------------
# Existing install? The data folder is the honest test: the update
# archives do not contain it, so a folder with only Doom3BFGVR.exe is
# still an install, but one without the data folder is not.
$hasData = Test-Path -LiteralPath (Join-PathLexical $gamePath $DATA_FOLDER)
$hasExe  = Test-Path -LiteralPath (Join-PathLexical $gamePath $VR_EXE)
$alreadyInstalled = ($hasData -and $hasExe)

$releaseData = $null
try {
    $releaseData = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases" `
                -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25
} catch {
    Write-Warn "Could not read the releases list: $($_.Exception.Message)"
}

# What actually gets downloaded:
#  - nothing installed  -> the full package, then a newer update on top
#  - already installed  -> the newest asset alone
$resolvedPlan = Get-Doom3BfgReleasePlan -Releases $releaseData -HasExistingBase $alreadyInstalled -FullMinBytes $FULL_MIN_BYTES
$plan = @($resolvedPlan.Plan)
if ($alreadyInstalled) {
    Write-Info "Doom 3 BFG VR is already installed - updating it."
} else {
    Write-Info "No VR install found - fetching the full package."
}
if ($plan.Count -eq 0) {
    Write-Fail "No usable download found on the releases page."
    Write-Do "Get it by hand: $RELEASES_URL"
    Pause-User "Press Enter to exit."
    exit 1
}
foreach ($step in $plan) {
    $kind = if (($step.Name -match '(?i)full.?package') -or ($step.Size -ge $FULL_MIN_BYTES)) { "full package" } else { "update" }
    Write-OK ("{0}: {1} ({2:N0} MB)" -f $kind, $step.Name, ($step.Size / 1MB))
}

$tempDir = Join-Path $env:TEMP "Doom3BFGVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null
$stepNo = 0
foreach ($step in $plan) {
    $stepNo++
    $vrZip = Join-PathLexical $tempDir ("d3bfgvr_$stepNo.zip")
    $mb = [int]($step.Size / 1MB)
    Write-Host ("  Downloading {0} (~{1} MB) ... " -f $step.Name, $mb) -NoNewline -ForegroundColor White
    $r = Invoke-DownloadOrFallback -Url $step.Url -Destination $vrZip `
            -Label ("Doom 3 BFG VR " + $step.Tag) `
            -ManualUrl $RELEASES_URL `
            -Instructions ("Download '" + $step.Name + "' from the releases page. Place it at '" + $vrZip + "' and choose Retry.") `
            -SkipMessage "Skipped - the mod files were not downloaded; the install is incomplete."
    if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if (-not ($r -is [bool] -and $r)) { Pause-User "Install cannot continue without the mod files. Press Enter to exit..."; exit 1 }

    Write-Host "  Extracting into the game folder ... " -NoNewline -ForegroundColor White
    try {
        Expand-Archive -Path $vrZip -DestinationPath $gamePath -Force
        Write-Host "OK" -ForegroundColor Green
    } catch {
        Write-Host "FAILED" -ForegroundColor Red
        Write-Host "    $_" -ForegroundColor Gray
        Pause-User "Press Enter to exit."; exit 1
    }
    try { Remove-Item -LiteralPath $vrZip -Force -ErrorAction SilentlyContinue } catch {}
}

# Verify key files
$vrExePath = Join-Path $gamePath $VR_EXE
if (Test-Path $vrExePath) { Write-OK "$VR_EXE verified." }
else {
    Write-Fail "$VR_EXE was not installed. The archive was incomplete or wrong."
    try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

$fpFolder = Join-Path $gamePath "Fully Possessed"
if (Test-Path $fpFolder) { Write-OK "'Fully Possessed' mod folder verified." }
else {
    Write-Fail "'Fully Possessed' is missing. A small update cannot be installed without the full package."
    try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
$defaultCfgPaths = @(
    (Join-PathLexical $fpFolder "vr_openvr_default.cfg"),
    (Join-PathLexical $fpFolder "vr_oculus_default.cfg")
)
$missingDefaults = @($defaultCfgPaths | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missingDefaults.Count) {
    Write-Fail "The full package is incomplete: required default VR config files are missing."
    foreach ($missingCfg in $missingDefaults) { Write-Info ([IO.Path]::GetFileName($missingCfg)) }
    try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- The player-model clipping fix ---------------------------
# !!! 1.1.0 SHIPS THE RIGHT VALUES, AN OLD INSTALL DOES NOT. The new
# release sets vr_nodalX -11 and vr_nodalZ -5 in its default configs -
# read from the archive, both files, both lines. But anyone updating
# over an older install still has the OLD numbers on disk, and that is
# the camera clipping into the marine's chest when you look down.
#
# So the two lines are rewritten either way. Only those two: everything
# else in the file is left exactly as it is, and the original is kept
# beside it before anything changes.
$savedCfgRoot = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Saved Games\id Software\DOOM 3 BFG\Fully Possessed"
$cfgFixed = Set-Doom3BfgClippingOffsets -Paths @(
    $defaultCfgPaths[0],
    $defaultCfgPaths[1],
    (Join-PathLexical $savedCfgRoot "vr_openvr.cfg"),
    (Join-PathLexical $savedCfgRoot "vr_oculus.cfg")
)
if ($cfgFixed -gt 0) { Write-OK "Clipping fix applied to $cfgFixed config file(s); originals kept as .pre-vrfix" }
else { Write-Info "Clipping offsets were already correct - nothing to change." }

# Record the install path so the Hub flips this game to "VR Ready"
# right after the installer runs, even when the user never pressed
# Check Installed (the post-install single-game refresh reads this).
try {
    Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force
    $installedTag = [string]$plan[$plan.Count - 1].Tag
    if ($installedTag) {
        Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $installedTag -Encoding UTF8 -Force
        Set-Content -Path (Join-PathLexical $gamePath ".pcvrhub_version") -Value $installedTag -Encoding UTF8 -Force
    }
} catch {}

try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# STEP 3: Desktop shortcut
Write-Step 3 3 "Creating Desktop Shortcut"

try {
     $origExe = Join-Path $gamePath $GAME_EXE
     $shortcut = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Doom 3 BFG VR.lnk" -TargetPath $vrExePath -WorkingDir $gamePath -IconPath $(if (Test-Path $origExe) { "$origExe,0" } else { "$vrExePath,0" }) -Description "DOOM 3 BFG VR - Fully Possessed"
    Write-OK "Desktop shortcut 'Doom 3 BFG VR' created."
} catch {
    Write-Warn "Could not create shortcut: $_"
    Write-Info "Launch manually: $vrExePath"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the 'Doom 3 BFG VR'" -ForegroundColor White
Write-Host "  shortcut on your Desktop." -ForegroundColor White
Write-Host "  Do NOT launch via Steam - use Doom3BFGVR.exe directly!" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."
Write-Host ""
Write-Host "--- Notes ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  - Only DOOM 3 BFG Edition is supported (not Classic Doom 3)." -ForegroundColor White
Write-Host "  - Settings saved in: %UserProfile%\Saved Games\id Software\DOOM 3 BFG\Fully Possessed\" -ForegroundColor Gray
Write-Host "  - VR options: in-game menu, or edit vr_openvr.cfg / vr_oculus.cfg there." -ForegroundColor Gray
Write-Host "  - If body turn feels sluggish, add:  set vr_deadzoneYaw ""0""  to vr_openvr.cfg" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  The Mars facility breathes wrong. Trust your flashlight." -ForegroundColor Magenta
Write-Host ""
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
Pause-User "Press Enter to exit."
