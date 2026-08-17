# -------------------------------------------------------
# BioShock Remastered VR Mod Installer - TWO mods, one game
#
#   A) BioVRDev  - github.com/BioVRDev/Bioshock-Remastered-VR
#      dxgi.dll, BioshockVR.dll, BioshockVR.ini, both OpenXR loaders and
#      Setup.bat (1.0.3 - hiess vorher FirstTimeSetup.bat). dxgi.dll ist
#      der Injektor; Setup.bat waehlt die Laufzeit und schreibt
#      resolution/FOV/windowed into Bioshock.ini before the game can
#      overwrite them again.
#   B) balouza   - github.com/mohamad-balouza/bioshock-vr
#      xinput1_3.dll (injector) + bioshockvr.dll, plus a preset folder.
#      Motion controllers, F10 overlay, settings in %LOCALAPPDATA%\BioshockVR.
#
# WHY THIS IS NOT A NORMAL TWO-MOD SETUP: both mods drop their files into
# the SAME folder (Build\Final), and their payload DLLs are called
# BioshockVR.dll and bioshockvr.dll - the SAME name on Windows, which is
# case-insensitive. They physically cannot sit in that folder together;
# one would overwrite the other. So each mod is kept in its own store
# under Build\Final\_vrmods\, and only the ACTIVE one has its files lying
# next to the exe. Switching = copy the wanted store back, remove the
# other mod's known files. Nothing is ever deleted that is not in a store.
#
# The two .bat files in Build\Final\VRLaunch\ do exactly that switch and
# then start the game through Steam (BioshockHD.exe cannot be started
# directly - it wants to come up through Steam). Those bats are also what
# the Hub tile detects per mod (catalog: ModALaunch / ModBLaunch).
# -------------------------------------------------------

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "BioShock Remastered VR Installer"

$GAME_APPID = "409710"
$GAME_EXE   = "BioshockHD.exe"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

$REPO_A         = "BioVRDev/Bioshock-Remastered-VR"
$RELEASES_API_A = "https://api.github.com/repos/$REPO_A/releases/latest"
$RELEASES_URL_A = "https://github.com/$REPO_A/releases"

$REPO_B         = "mohamad-balouza/bioshock-vr"
$RELEASES_API_B = "https://api.github.com/repos/$REPO_B/releases/latest"
$RELEASES_URL_B = "https://github.com/$REPO_B/releases"

$NEXUS_CUTSCENES = "https://www.nexusmods.com/bioshock/mods/81?tab=files"

# What each mod owns. Everything listed here is copied into the game
# folder when that mod is active and removed again when the other one
# takes over - so these lists are also the switch's delete lists.
# !!! DATEIBESTAND KOMPLETT GEAENDERT IN 1.0.3 - GEGEN DAS ECHTE ZIP GEPRUEFT !!!
# Frueher: dxgi.dll, BioshockVR.dll, BioshockVR.ini, openxr_loader.dll und
# FirstTimeSetup.bat. Von den fuenf gibt es ZWEI nicht mehr:
#   openxr_loader.dll  -> das Paket bringt jetzt BEIDE Laufzeiten unter
#                         eigenen Namen mit (openxr_loader_standard.dll und
#                         openxr_loader_steam.dll). Setup.bat kopiert die
#                         gewaehlte auf den Namen, den die Mod laedt - deshalb
#                         steht openxr_loader.dll weiter in der Liste: sie
#                         ENTSTEHT beim Setup und muss beim Umschalten mit.
#   FirstTimeSetup.bat -> heisst jetzt Setup.bat, dazu Uninstall.bat und
#                         logs\CollectLogs.bat.
$FILES_A = @(
    "dxgi.dll", "BioshockVR.dll", "BioshockVR.ini",
    "openvr_api.dll", "openxr_loader_standard.dll", "openxr_loader_steam.dll",
    "openxr_loader.dll",
    "Setup.bat", "Uninstall.bat", "README.txt", "changelog.txt",
    "logs\CollectLogs.bat"
)
$FILES_B = @("xinput1_3.dll", "bioshockvr.dll", "bvr_steamvr32.dll", "openvr_api.dll")

$STORE_REL  = "_vrmods"
$SUB_A      = "biovrdev"
$SUB_B      = "balouza"
$LAUNCH_REL = "VRLaunch"
$BAT_A      = "BioShock VR (BioVRDev).bat"
$BAT_B      = "BioShock VR (balouza).bat"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " BioShock Remastered VR Installer" -ForegroundColor Cyan
    Write-Host " Two VR mods to choose from - BioVRDev and balouza" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param([int]$Step, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}
function Write-OK   { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m" -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if ($p -and (Test-Path $p)) { return $p } } catch {}
    }
    return $null
}

# Returns the folder that actually holds BioshockHD.exe. Steam and GOG use
# Build\Final, Epic uses Build\FinalEpic - so the exe is searched for rather
# than assumed.
function Get-BuildFolder {
    param([string]$GameRoot)
    foreach ($sub in @("Build\Final", "Build\FinalEpic")) {
        $c = [System.IO.Path]::Combine($GameRoot, $sub)
        if (Test-Path -LiteralPath ([System.IO.Path]::Combine($c, $GAME_EXE))) { return $c }
    }
    return $null
}

function Find-BioshockRoot {
    $steam = Get-SteamPath
    $libs = @()
    if ($steam) {
        $libs += $steam
        $vdf = [System.IO.Path]::Combine($steam, "steamapps\libraryfolders.vdf")
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s*"([^"]+)"')) {
                $libs += $m.Groups[1].Value -replace '\\\\', '\'
            }
        }
    }
    foreach ($lib in $libs) {
        $c = [System.IO.Path]::Combine($lib, "steamapps\common\BioShock Remastered")
        if (Get-BuildFolder -GameRoot $c) { return $c }
    }
    foreach ($c in @("C:\GOG Games\BioShock Remastered",
                     "C:\Program Files (x86)\GOG Galaxy\Games\BioShock Remastered",
                     "C:\Program Files\Epic Games\BioShockRemastered")) {
        if (Get-BuildFolder -GameRoot $c) { return $c }
    }
    return $null
}

# Expand-Archive chokes on archives that store backslashes as path
# separators - the balouza release does exactly that for its preset\
# folder. Falls back to reading the entries by hand with the separator
# normalised, so one odd entry cannot fail the whole install.
function Expand-ZipSafe {
    param([string]$Zip, [string]$Dest)
    try {
        Expand-Archive -LiteralPath $Zip -DestinationPath $Dest -Force -ErrorAction Stop
        return $true
    } catch { }
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $arc = [System.IO.Compression.ZipFile]::OpenRead($Zip)
        try {
            foreach ($e in $arc.Entries) {
                if (-not $e.Name) { continue }
                $rel = ($e.FullName -replace '\\', '/')
                $out = [System.IO.Path]::Combine($Dest, ($rel -replace '/', '\'))
                $dir = [System.IO.Path]::GetDirectoryName($out)
                if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $out, $true)
            }
        } finally { $arc.Dispose() }
        return $true
    } catch {
        Write-Fail "Could not extract the archive: $($_.Exception.Message)"
        return $false
    }
}

# Gets the latest release zip of a repo into $ZipPath. Returns the tag.
function Get-ModRelease {
    param([string]$Api, [string]$PageUrl, [string]$ZipPath, [string]$Label, [string]$NameHint)
    $tag = $null
    try {
        $rel = Invoke-RestMethod -Uri $Api -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -ErrorAction Stop
        $tag = $rel.tag_name
        $asset = $rel.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
        if ($asset) {
            Write-Info "$Label release $tag - downloading $($asset.name)"
            Invoke-SafeDownload -Urls @($asset.browser_download_url) -Destination $ZipPath `
                -Label "$Label $tag" -ManualUrl $PageUrl | Out-Null
        }
    } catch { }
    if (Test-Path -LiteralPath $ZipPath) { return $tag }

    $dl = Join-Path $env:USERPROFILE "Downloads"
    if (Test-Path -LiteralPath $dl) {
        $hit = Get-ChildItem -LiteralPath $dl -Filter "*.zip" -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -match $NameHint } |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($hit) {
            Write-Host "  Found in Downloads: $($hit.Name)" -ForegroundColor Cyan
            $use = (Read-Host "  Use this file? Press Enter to accept, or type N").Trim()
            if ($use -notin @("n","N")) { Copy-Item -LiteralPath $hit.FullName -Destination $ZipPath -Force; return $tag }
        }
    }
    Write-Warn "Automatic download of the $Label files did not work."
    Pause-User "Press Enter to open its releases page..." | Out-Null
    try { Start-Process $PageUrl } catch {}
    while ($true) {
        $r = (Read-Host "  Drag the downloaded ZIP here (empty to skip this mod)").Trim().Trim('"').Trim("'")
        if (-not $r) { return $null }
        if (-not (Test-Path -LiteralPath $r)) { Write-Fail "File not found: $r"; continue }
        Copy-Item -LiteralPath $r -Destination $ZipPath -Force
        return $tag
    }
}

# Fills a mod's store folder from an extracted release.
function Fill-Store {
    param([string]$Extract, [string]$StoreDir, [string[]]$Files, [switch]$WithPreset)
    if (-not (Test-Path -LiteralPath $StoreDir)) { New-Item -ItemType Directory -Path $StoreDir -Force | Out-Null }
    $got = @(); $miss = @()
    foreach ($f in $Files) {
        $hit = Get-ChildItem -LiteralPath $Extract -Filter $f -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $hit) { $miss += $f; continue }
        try { Copy-Item -LiteralPath $hit.FullName -Destination ([System.IO.Path]::Combine($StoreDir, $f)) -Force -ErrorAction Stop; $got += $f }
        catch { $miss += $f }
    }
    if ($WithPreset) {
        # The bundled calibration travels with the store, not into the game
        # folder - it belongs in %LOCALAPPDATA%\BioshockVR and only if the
        # user wants it. The README explains that.
        # SINCE v0.7.0 THE ZIP CARRIES TWO CALIBRATIONS: preset-bs1\ for this
        # game and preset-bs2\ for BioShock 2, with the SAME file names
        # (vrpreset.ini, weapons.ini, HOW-TO-USE.txt). A plain recursive
        # search with "first hit wins" could therefore drop BioShock 2's
        # tuning into BioShock 1's store. Prefer a bs1 folder, and only fall
        # back to a loose file when no bs1 folder exists (older releases had
        # the presets in "preset\" or at the root).
        foreach ($p in @("vrpreset.ini","hands.ini","weapons.ini","HOW-TO-USE.txt","README.txt")) {
            $all = @(Get-ChildItem -LiteralPath $Extract -Filter $p -Recurse -File -ErrorAction SilentlyContinue)
            if ($all.Count -eq 0) { continue }
            $hit = $all | Where-Object { $_.DirectoryName -match '(?i)preset[-_]?bs1' } | Select-Object -First 1
            if (-not $hit) { $hit = $all | Where-Object { $_.DirectoryName -notmatch '(?i)bs2' } | Select-Object -First 1 }
            if (-not $hit) { continue }
            try { Copy-Item -LiteralPath $hit.FullName -Destination ([System.IO.Path]::Combine($StoreDir, $p)) -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
    return [pscustomobject]@{ Copied = $got; Missing = $miss }
}

# ADOPTS AN OLDER HUB INSTALL. Until now the Hub only ever offered
# BioVRDev, and it copied those files loose into Build\Final - there was
# no store. Anyone with such an install who now picks balouza would be
# left with dxgi.dll, BioshockVR.ini, openxr_loader.dll and
# Setup.bat still lying next to the exe: dxgi.dll is BioVRDev's
# injector, so the old mod would keep loading alongside the new one.
# (BioshockVR.dll is the one file that would be handled anyway - balouza's
# bioshockvr.dll overwrites it, same name on Windows.)
#
# So before anything is activated, loose mod files that are NOT yet in a
# store get copied into their store. That does two things at once: the
# switch's delete guard - "only remove what can be put back" - now covers
# them, and the old install stays fully restorable through the launcher.
# THE MARKER MATTERS: the two mods share the payload name
# BioshockVR.dll / bioshockvr.dll, so "is bioshockvr.dll lying there?"
# cannot tell whose it is. Each mod is therefore recognised by the file
# only IT ships - dxgi.dll for BioVRDev, xinput1_3.dll for balouza - and
# nothing is adopted unless that marker is present. Without this an old
# BioVRDev payload would be filed as balouza's.
# Returns the names it took in.
function Import-LegacyInstall {
    param([string]$BuildDir, [string]$StoreDir, [string[]]$Files, [string]$Marker)
    $taken = @()
    if ($Marker -and -not (Test-Path -LiteralPath ([System.IO.Path]::Combine($BuildDir, $Marker)))) { return $taken }
    foreach ($f in $Files) {
        $loose = [System.IO.Path]::Combine($BuildDir, $f)
        if (-not (Test-Path -LiteralPath $loose)) { continue }
        $inStore = [System.IO.Path]::Combine($StoreDir, $f)
        if (Test-Path -LiteralPath $inStore) { continue }   # store wins - it is the newer copy
        if (-not (Test-Path -LiteralPath $StoreDir)) { New-Item -ItemType Directory -Path $StoreDir -Force | Out-Null }
        try { Copy-Item -LiteralPath $loose -Destination $inStore -Force -ErrorAction Stop; $taken += $f } catch {}
    }
    return $taken
}

# Copies a store into the game folder and removes the OTHER mod's files.
# A pre-existing foreign file is backed up once as .hubbak before it is
# overwritten, exactly as this installer has always done.
function Set-ActiveMod {
    param([string]$BuildDir, [string]$StoreDir, [string[]]$Files, [string[]]$OtherFiles, [string]$OtherStore)
    foreach ($f in $OtherFiles) {
        if ($Files -contains $f) { continue }
        $victim = [System.IO.Path]::Combine($BuildDir, $f)
        if (-not (Test-Path -LiteralPath $victim)) { continue }
        if (-not $OtherStore) { continue }
        $keep = [System.IO.Path]::Combine($OtherStore, $f)
        # NUR LOESCHEN, WAS SICH ZURUECKLEGEN LAESST. Liegt die Datei noch
        # nicht im Lager der anderen Mod, wird sie ZUERST DORTHIN GESICHERT
        # und danach entfernt.
        # WARUM DAS NOETIG WURDE: seit BioVRDev 1.0.3 entsteht
        # openxr_loader.dll erst BEIM SETUP - sie ist in keinem Archiv und
        # kam deshalb nie ins Lager. Ohne diese Sicherung griff die alte
        # Sperre, die Datei blieb beim Umschalten liegen, und balouza lief
        # mit einem fremden OpenXR-Loader daneben.
        if (-not (Test-Path -LiteralPath $keep)) {
            try {
                $keepDir = Split-Path -Parent $keep
                if ($keepDir -and -not (Test-Path -LiteralPath $keepDir)) {
                    New-Item -ItemType Directory -Path $keepDir -Force -ErrorAction SilentlyContinue | Out-Null
                }
                Copy-Item -LiteralPath $victim -Destination $keep -Force -ErrorAction Stop
            } catch { continue }   # nicht sicherbar -> auch nicht loeschen
        }
        try { Remove-Item -LiteralPath $victim -Force -ErrorAction Stop } catch {}
    }
    $ok = $true
    $failed = @()
    foreach ($f in $Files) {
        $src = [System.IO.Path]::Combine($StoreDir, $f)
        if (-not (Test-Path -LiteralPath $src)) { continue }
        $dest = [System.IO.Path]::Combine($BuildDir, $f)
        try {
            # .hubbak means "the file YOU had before the Hub touched it".
            # It must never be made from the OTHER mod's file: BioshockVR.dll
            # and bioshockvr.dll are the same name on Windows, so without
            # this guard every switch parked a 3 MB copy of the other mod's
            # payload as BioshockVR.dll.hubbak - junk that also lied about
            # what it was. -contains is case-insensitive, which is exactly
            # what catches the collision.
            $isOtherModsFile = ($OtherFiles -contains $f)
            if ((Test-Path -LiteralPath $dest) -and -not $isOtherModsFile -and -not (Test-Path -LiteralPath "$dest.hubbak")) {
                Copy-Item -LiteralPath $dest -Destination "$dest.hubbak" -Force -ErrorAction SilentlyContinue
            }
            # Seit 1.0.3 steht auch eine Datei in einem UNTERORDNER
            # (logs\CollectLogs.bat). Copy-Item legt den nicht selbst an.
            $destDir = Split-Path -Parent $dest
            if ($destDir -and -not (Test-Path -LiteralPath $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force -ErrorAction SilentlyContinue | Out-Null
            }
            Copy-Item -LiteralPath $src -Destination $dest -Force -ErrorAction Stop
        } catch { $ok = $false; $failed += $f }
    }
    if ($failed.Count -gt 0) {
        Write-Fail "Could not write: $($failed -join ', ')"
        Write-Warn "That usually means the game is still running. Close it and run this installer again."
    }
    return $ok
}

# -------------------------------------------------------
# Intro + mod choice
# -------------------------------------------------------
# One screen, one keypress. The old version had a "Press Enter to
# start" gate and THEN the same three options on the next screen -
# two stops for one decision. Typing a number and pressing Enter is
# the same gate and gets the reading done in one place.
Write-Header
Write-Host " There are TWO VR mods for BioShock Remastered. They use the same" -ForegroundColor White
Write-Host " files in the same folder, so only ONE can be active at a time." -ForegroundColor White
Write-Host ""
Write-Host "   [1] balouza    " -NoNewline -ForegroundColor Cyan
Write-Host "motion-controller aim with a laser, weapons" -ForegroundColor White
Write-Host "                  in one hand and plasmids in the other, per-weapon" -ForegroundColor Gray
Write-Host "                  aim profiles, swing-to-melee, physical scopes," -ForegroundColor Gray
Write-Host "                  floating HUD panel, snap turn, cutscene handling," -ForegroundColor Gray
Write-Host "                  and an in-headset F10 overlay for live tuning." -ForegroundColor Gray
Write-Host "                  Settings live in %LOCALAPPDATA%\BioshockVR." -ForegroundColor Gray
Write-Host ""
Write-Host "   [2] BioVRDev   " -NoNewline -ForegroundColor Cyan
Write-Host "stereo 3D, head tracking, motion controllers" -ForegroundColor White
Write-Host "                  with the weapon following your hand. Starts with" -ForegroundColor Gray
Write-Host "                  the game - no overlay, no launcher, nothing to" -ForegroundColor Gray
Write-Host "                  calibrate. Settings in BioshockVR.ini." -ForegroundColor Gray
Write-Host ""
Write-Host "   [3] Both       " -NoNewline -ForegroundColor Cyan
Write-Host "installs both and lets you switch between them." -ForegroundColor White
Write-Host ""
Write-Host " Both are free and both come straight from GitHub." -ForegroundColor Gray
Write-Host ""
$choice = ""
while ($choice -notin @("1","2","3")) { $choice = (Read-Host "  Your choice (1/2/3)").Trim() }
$wantA = ($choice -in @("2","3"))
$wantB = ($choice -in @("1","3"))

# -------------------------------------------------------
# STEP 2: locate the game
# -------------------------------------------------------
Write-Step 1 4 "Locating BioShock Remastered"
$gameRoot = Find-BioshockRoot
if (-not $gameRoot) {
    $gameRoot = Find-SteamGameFolder -AppId $GAME_APPID -SteamFolderNames @("BioShock Remastered") -ProbeExe "Build\Final\$GAME_EXE"
}
if (-not $gameRoot) {
    Write-Warn "Could not find BioShock Remastered automatically."
    Write-Host "  Paste the game's main folder (the one containing Build)." -ForegroundColor White
    while (-not $gameRoot) {
        $r = (Read-Host "  BioShock Remastered folder").Trim().Trim('"').Trim("'")
        if (-not $r) { continue }
        if (-not (Test-Path -LiteralPath $r)) { Write-Fail "Folder not found: $r"; continue }
        if (-not (Get-BuildFolder -GameRoot $r)) {
            Write-Fail "That folder does not contain $GAME_EXE (expected under Build\Final)."
            continue
        }
        $gameRoot = $r
    }
}
$buildDir = Get-BuildFolder -GameRoot $gameRoot
if (-not $buildDir) {
    Write-Fail "Found the game folder, but not $GAME_EXE inside it."
    Write-Host "  Expected under Build\Final (or Build\FinalEpic on Epic)." -ForegroundColor Gray
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
Write-OK "Found: $buildDir"

# NOTHING may be copied while the game holds its DLLs open: Windows keeps
# a loaded DLL locked, the copy fails, and the folder is left half
# switched - one mod's injector with the other mod's payload. That is a
# crash on the next launch, and it looks random because it depends on
# whether the game happened to be running.
while ($true) {
    $bs = $null
    try { $bs = Get-Process -Name "BioshockHD" -ErrorAction SilentlyContinue } catch {}
    if (-not $bs) { break }
    Write-Warn "BioShock is running. Close the game completely, then continue."
    Pause-User "Press Enter once BioShock is closed..." | Out-Null
}

$storeRoot = [System.IO.Path]::Combine($buildDir, $STORE_REL)
$storeA    = [System.IO.Path]::Combine($storeRoot, $SUB_A)
$storeB    = [System.IO.Path]::Combine($storeRoot, $SUB_B)

# Take over anything an earlier Hub version installed loose in this folder
# before the store existed. Without this a BioVRDev install from before
# would keep its dxgi.dll injector next to balouza's - two VR mods loading
# into the same game.
$adoptedA = Import-LegacyInstall -BuildDir $buildDir -StoreDir $storeA -Files $FILES_A -Marker "dxgi.dll"
$adoptedB = Import-LegacyInstall -BuildDir $buildDir -StoreDir $storeB -Files $FILES_B -Marker "xinput1_3.dll"
if ($adoptedA.Count -gt 0) { Write-Info "Found an existing BioVRDev install here - kept it: $($adoptedA -join ', ')" }
if ($adoptedB.Count -gt 0) { Write-Info "Found existing balouza files here - kept them: $($adoptedB -join ', ')" }

# -------------------------------------------------------
# STEP 3: download + fill the stores
# -------------------------------------------------------
Write-Step 2 4 "Downloading the VR mod files"

$work = Join-Path $env:TEMP ("bioshockvr_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $work -Force | Out-Null
$tagA = $null; $tagB = $null
$haveA = $false; $haveB = $false

if ($wantA) {
    $zipA = Join-Path $work "biovrdev.zip"
    $tagA = Get-ModRelease -Api $RELEASES_API_A -PageUrl $RELEASES_URL_A -ZipPath $zipA -Label "BioVRDev" -NameHint '(?i)bioshock'
    if (Test-Path -LiteralPath $zipA) {
        $exA = Join-Path $work "exA"; New-Item -ItemType Directory -Path $exA -Force | Out-Null
        if (Expand-ZipSafe -Zip $zipA -Dest $exA) {
            $res = Fill-Store -Extract $exA -StoreDir $storeA -Files $FILES_A
            if (($res.Copied -contains "BioshockVR.dll") -and ($res.Copied -contains "dxgi.dll")) {
                $haveA = $true
                Write-OK "BioVRDev files ready: $($res.Copied -join ', ')"
                if ($res.Missing.Count -gt 0) { Write-Warn "Not in this release: $($res.Missing -join ', ')" }
            } else {
                Write-Fail "BioVRDev's core files were not in the archive."
            }
        }
    }
}
if ($wantB) {
    $zipB = Join-Path $work "balouza.zip"
    $tagB = Get-ModRelease -Api $RELEASES_API_B -PageUrl $RELEASES_URL_B -ZipPath $zipB -Label "balouza" -NameHint '(?i)bioshock'
    if (Test-Path -LiteralPath $zipB) {
        $exB = Join-Path $work "exB"; New-Item -ItemType Directory -Path $exB -Force | Out-Null
        if (Expand-ZipSafe -Zip $zipB -Dest $exB) {
            $res = Fill-Store -Extract $exB -StoreDir $storeB -Files $FILES_B -WithPreset
            if ($res.Missing.Count -eq 0) {
                $haveB = $true
                Write-OK "balouza files ready: $($res.Copied -join ', ')"
            } else {
                Write-Fail "balouza's files were not in the archive: missing $($res.Missing -join ', ')"
            }
        }
    }
}

# A store filled by an earlier run still counts, so adding the second mod
# later or re-running the installer works without a fresh download.
if (-not $haveA -and (Test-Path -LiteralPath ([System.IO.Path]::Combine($storeA, "dxgi.dll")))) { $haveA = $true }
if (-not $haveB -and (Test-Path -LiteralPath ([System.IO.Path]::Combine($storeB, "xinput1_3.dll")))) { $haveB = $true }

if (-not $haveA -and -not $haveB) {
    Write-Fail "Nothing was installed."
    try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}

# -------------------------------------------------------
# STEP 4: activate one + write the switch launchers
# -------------------------------------------------------
Write-Step 3 4 "Activating the mod"

# The choice from step 1 wins. Only "both" leaves the question open - if
# someone picked balouza while an old BioVRDev install was adopted above,
# they still get balouza, and the old one just stays switchable.
$activeName = $null
if ($choice -eq "3" -and $haveA -and $haveB) {
    Write-Host "  Both mods are on disk. Which one should be active now?" -ForegroundColor White
    Write-Host "   [1] balouza    [2] BioVRDev" -ForegroundColor White
    $a = ""
    while ($a -notin @("1","2")) { $a = (Read-Host "  Active mod (1/2)").Trim() }
    if ($a -eq "1") { $activeName = "balouza" } else { $activeName = "BioVRDev" }
} elseif ($choice -eq "1" -and $haveB) { $activeName = "balouza" }
elseif ($choice -eq "2" -and $haveA) { $activeName = "BioVRDev" }
elseif ($haveB) { $activeName = "balouza" } else { $activeName = "BioVRDev" }

if ($activeName -eq "balouza") {
    $null = Set-ActiveMod -BuildDir $buildDir -StoreDir $storeB -Files $FILES_B -OtherFiles $FILES_A -OtherStore $storeA
} else {
    $null = Set-ActiveMod -BuildDir $buildDir -StoreDir $storeA -Files $FILES_A -OtherFiles $FILES_B -OtherStore $storeB
}
Write-OK "Active mod: $activeName"

# The launcher bats. One per installed mod, always written - the Hub tile
# detects each mod by its bat, and with only one mod installed the bat is
# simply a normal start. Pure CMD, ASCII only, quoted paths.
$launchDir = [System.IO.Path]::Combine($buildDir, $LAUNCH_REL)
if (-not (Test-Path -LiteralPath $launchDir)) { New-Item -ItemType Directory -Path $launchDir -Force | Out-Null }

function Write-LauncherBat {
    param([string]$Path, [string]$Title, [string]$BuildDir, [string]$StoreDir, [string[]]$Files, [string]$OtherStore, [string[]]$OtherFiles)
    $lines = @()
    $lines += "@echo off"
    $lines += "title $Title"
    $lines += "rem Written by the PCVR Mods Installer Hub."
    $lines += "rem Makes this mod the active one, then starts BioShock through Steam."
    $lines += "setlocal"
    $lines += "set ""BUILD=$BuildDir"""
    $lines += "set ""MINE=$StoreDir"""
    $lines += "set ""OTHER=$OtherStore"""
    # THE GAME MUST BE CLOSED. A loaded DLL is locked by Windows, so the
    # copy below fails, and the folder is left with one mod's injector
    # next to the other mod's payload - which crashes on the next launch.
    # Silently ignoring that is what made switching feel randomly broken,
    # so the switch stops here instead of starting a broken game.
    $lines += "tasklist /FI ""IMAGENAME eq $GAME_EXE"" 2>nul | find /I ""$GAME_EXE"" >nul"
    $lines += "if not errorlevel 1 ("
    $lines += "  echo BioShock is still running. Close the game, then run this again."
    $lines += "  pause"
    $lines += "  exit /b 1"
    $lines += ")"
    foreach ($f in $OtherFiles) {
        if ($Files -contains $f) { continue }
        $lines += "if exist ""%OTHER%\$f"" if exist ""%BUILD%\$f"" del ""%BUILD%\$f"" >nul 2>&1"
        # ...including a copy the Flat/VR button had switched off. Left
        # behind, that stale twin makes the folder ambiguous about which
        # mod is really there.
        $lines += "if exist ""%BUILD%\$f-"" del ""%BUILD%\$f-"" >nul 2>&1"
    }
    # Our own injector may be sitting there disabled (Flat mode). We are
    # about to write the live file, so the disabled twin is stale.
    foreach ($f in $Files) {
        $lines += "if exist ""%BUILD%\$f-"" del ""%BUILD%\$f-"" >nul 2>&1"
    }
    # EVERY copy is checked. A half-finished switch must never reach the
    # game: if one file cannot be written we say so and stop, rather than
    # launching a mixed set of files.
    foreach ($f in $Files) {
        $lines += "if exist ""%MINE%\$f"" ("
        $lines += "  copy /y ""%MINE%\$f"" ""%BUILD%\$f"" >nul"
        $lines += "  if errorlevel 1 ("
        $lines += "    echo Could not write $f - the switch is incomplete."
        $lines += "    echo Close everything using the game folder and run this again."
        $lines += "    pause"
        $lines += "    exit /b 1"
        $lines += "  )"
        $lines += ")"
    }
    $lines += "start """" ""steam://rungameid/$GAME_APPID"""
    $lines += "endlocal"
    Set-Content -LiteralPath $Path -Value $lines -Encoding ASCII -Force
}

# ONLY WITH BOTH MODS. With a single mod there is nothing to switch
# between, so no launchers are written - and the Hub tile then shows the
# normal start instead of two mod buttons (catalog: TwoModsRequireBoth).
# Leftovers from an earlier "both" install are removed, otherwise the tile
# would keep offering a switch to a mod that is no longer there.
if ($haveA -and $haveB) {
    Write-LauncherBat -Path ([System.IO.Path]::Combine($launchDir, $BAT_A)) -Title "BioShock VR - BioVRDev" `
        -BuildDir $buildDir -StoreDir $storeA -Files $FILES_A -OtherStore $storeB -OtherFiles $FILES_B
    Write-LauncherBat -Path ([System.IO.Path]::Combine($launchDir, $BAT_B)) -Title "BioShock VR - balouza" `
        -BuildDir $buildDir -StoreDir $storeB -Files $FILES_B -OtherStore $storeA -OtherFiles $FILES_A
    Write-OK "Switch launchers written to $LAUNCH_REL"
} else {
    foreach ($stale in @($BAT_A, $BAT_B)) {
        $sp = [System.IO.Path]::Combine($launchDir, $stale)
        if (Test-Path -LiteralPath $sp) { try { Remove-Item -LiteralPath $sp -Force -ErrorAction Stop } catch {} }
    }
    Write-Info "Only one mod installed - no switch launchers needed."
}

# BioVRDev's one-time setup - only meaningful while BioVRDev is active,
# because it writes the resolution and FOV that mod needs.
if ($activeName -eq "BioVRDev") {
    # HEISST SEIT 1.0.3 Setup.bat (vorher FirstTimeSetup.bat) UND MUSS ALS
    # ADMINISTRATOR LAUFEN - der Autor schreibt das ausdruecklich in die
    # Anleitung. Ohne diesen Lauf startet das Spiel gar nicht erst in VR:
    # das Paket bringt BEIDE OpenXR-Laufzeiten unter eigenen Namen mit, und
    # erst Setup kopiert die passende auf den Namen, den die Mod laedt.
    # Zusaetzlich setzt es Aufloesung und FOV, die ohne es fuer VR falsch sind.
    # ---- EINE ALTE openxr_loader.dll MUSS WEG, SONST BRICHT SETUP AB ----
    # NACHGEWIESEN, nicht vermutet: Setup.bat arbeitet mit RENAMES ("These
    # are RENAMES, not copies"). Es erwartet genau zwei Loader-Dateien und
    # vergleicht eine vorhandene openxr_loader.dll per :sameas mit den
    # beiden mitgelieferten. Eine openxr_loader.dll aus einer AELTEREN
    # BioVRDev-Fassung ist mit keiner von beiden identisch - Setup landet
    # dann in :loaderambiguous und bricht ab mit "all three loader names
    # exist, but the live DLL matches neither saved DLL ... Re-extract the
    # two clean loader DLLs and run Setup again."
    #
    # Die Datei kommt NICHT im Zip von 1.0.3 vor, wird also von der
    # Installation NICHT ueberschrieben. Sie muss weg, damit Setup den
    # sauberen Ausgangszustand vorfindet.
    #
    # NUR DIESE EINE DATEI, und nur wenn sie WEDER dem einen NOCH dem
    # anderen mitgelieferten Loader entspricht - ist sie identisch, hat
    # Setup selbst sie angelegt und sie bleibt.
    if ($activeName -eq "BioVRDev") {
        $live = [System.IO.Path]::Combine($buildDir, "openxr_loader.dll")
        $std  = [System.IO.Path]::Combine($buildDir, "openxr_loader_standard.dll")
        $shim = [System.IO.Path]::Combine($buildDir, "openxr_loader_steam.dll")
        if ((Test-Path -LiteralPath $live) -and (Test-Path -LiteralPath $std) -and (Test-Path -LiteralPath $shim)) {
            try {
                $lLen = (Get-Item -LiteralPath $live).Length
                $matches = ($lLen -eq (Get-Item -LiteralPath $std).Length) -or ($lLen -eq (Get-Item -LiteralPath $shim).Length)
                if (-not $matches) {
                    Write-Info "Removing an openxr_loader.dll left over from an older BioVRDev build."
                    Write-Host "  Setup cannot tell which loader it is and would stop. Both" -ForegroundColor Gray
                    Write-Host "  current loaders are in place, so it is safe to drop." -ForegroundColor Gray
                    Remove-Item -LiteralPath $live -Force -ErrorAction Stop
                }
            } catch { Write-Warn "Could not remove the old openxr_loader.dll: $($_.Exception.Message)" }
        }
    }

    $setup = [System.IO.Path]::Combine($buildDir, "Setup.bat")
    if (Test-Path -LiteralPath $setup) {
        Write-Host ""
        Write-Host "  Setup asks which headset and which runtime you use and installs" -ForegroundColor Gray
        Write-Host "  the matching OpenXR loader. It also writes the resolution and FOV" -ForegroundColor Gray
        Write-Host "  the mod needs - BioShock rewrites its own config on exit, so a" -ForegroundColor Gray
        Write-Host "  fresh install can never keep them. Your Bioshock.ini is backed up." -ForegroundColor Gray
        Write-Host ""
        Write-Host "  THE GAME WILL NOT START IN VR UNTIL THIS HAS RUN." -ForegroundColor Yellow
        Write-Host "  Run it again later if you change headset or runtime." -ForegroundColor Gray
        Write-Host ""
        Write-Host " >>> Make sure BioShock is CLOSED, then let the setup run.        " -ForegroundColor Black -BackgroundColor Yellow
        Write-Host ""
        Pause-User "Press Enter to run Setup.bat - UAC required..." | Out-Null
        $ranSetup = $false
        try {
            # -Verb RunAs: die Anleitung des Autors sagt "Right click Setup.bat
            # and choose Run as administrator".
            Start-Process -FilePath $setup -WorkingDirectory $buildDir -Verb RunAs -Wait -ErrorAction Stop
            $ranSetup = $true
            Write-OK "Setup finished."
        } catch {
            Write-Fail "Could not run it: $($_.Exception.Message)"
            Write-Host "  Run Setup.bat yourself in $buildDir - right-click," -ForegroundColor Yellow
            Write-Host "  Run as administrator. Without it the game starts flat." -ForegroundColor Yellow
        }
        # Am ERGEBNIS pruefen: Setup legt den geladenen Loader unter dem
        # Namen an, den die Mod erwartet.
        if ($ranSetup) {
            $loader = [System.IO.Path]::Combine($buildDir, "openxr_loader.dll")
            if (Test-Path -LiteralPath $loader) {
                Write-OK "OpenXR loader in place ($([math]::Round((Get-Item -LiteralPath $loader).Length/1KB)) KB)."
            } else {
                Write-Warn "Setup ran but openxr_loader.dll is not there."
                Write-Host "  If you picked the SteamVR shim it may use another name -" -ForegroundColor Gray
                Write-Host "  check Setup's own output. Otherwise run Setup.bat again." -ForegroundColor Gray
            }
        }
    } else {
        Write-Warn "Setup.bat is not in $buildDir - the mod cannot configure itself."
        Write-Host "  Without it the game will not start in VR. Re-run this installer." -ForegroundColor Yellow
    }
}

# -------------------------------------------------------
# STEP 5: Fullscreen Cutscenes (optional, BioVRDev only)
# -------------------------------------------------------
Write-Step 4 4 "Fullscreen cutscenes (optional)"
if ($activeName -eq "balouza") {
    Write-Info "balouza hides the cutscene black bars itself - nothing to do here."
} else {
    Write-Host "  BioShock's cutscenes play with black bars top and bottom, which" -ForegroundColor Gray
    Write-Host "  stay visible on the VR screen. This community mod removes them." -ForegroundColor Gray
    Write-Host ""
    $wantCut = ""
    while ($wantCut -notin @("y","Y","n","N")) { $wantCut = (Read-Host "  Install the fullscreen cutscenes mod? (Y/N)").Trim() }

    if ($wantCut -in @("y","Y")) {
        $flashDir = [System.IO.Path]::Combine($gameRoot, "ContentBaked", "pc", "FlashMovies")
        if (-not (Test-Path -LiteralPath $flashDir)) {
            Write-Warn "Could not find ContentBaked\pc\FlashMovies - skipping."
        } else {
            Pause-User "Press Enter to open the Nexus download page..." | Out-Null
            try { Start-Process $NEXUS_CUTSCENES } catch { Write-Warn "Open manually: $NEXUS_CUTSCENES" }

            $dl = Join-Path $env:USERPROFILE "Downloads"
            $cutArc = $null
            while (-not $cutArc) {
                $hit = $null
                if (Test-Path -LiteralPath $dl) {
                    $hit = Get-ChildItem -LiteralPath $dl -File -ErrorAction SilentlyContinue |
                           Where-Object { $_.Extension -match '(?i)\.(rar|zip|7z)$' -and $_.Name -match '(?i)cutscene' } |
                           Sort-Object LastWriteTime -Descending | Select-Object -First 1
                }
                if ($hit) {
                    Write-Host "  Found in Downloads: $($hit.Name)" -ForegroundColor Cyan
                    $use = (Read-Host "  Use this file? Press Enter to accept, or type N").Trim()
                    if ($use -notin @("n","N")) { $cutArc = $hit.FullName; break }
                }
                $r = (Read-Host "  Drag the downloaded archive here (empty to skip)").Trim().Trim('"').Trim("'")
                if (-not $r) { break }
                if (Test-Path -LiteralPath $r) { $cutArc = $r } else { Write-Fail "File not found: $r" }
            }

            if ($cutArc) {
                $cutTmp = Join-Path $env:TEMP ("bscut_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
                New-Item -ItemType Directory -Path $cutTmp -Force | Out-Null
                # The download is a .rar, which Expand-Archive cannot read - 7-Zip can.
                $sevenZip = $null
                try { $sevenZip = Get-SevenZip } catch {}
                $ok = $false
                if ($sevenZip) { try { & $sevenZip x "-o$cutTmp" $cutArc -y *> $null; $ok = $true } catch {} }
                if (-not $ok) { try { Expand-Archive -LiteralPath $cutArc -DestinationPath $cutTmp -Force -ErrorAction Stop; $ok = $true } catch {} }

                $swfs = @()
                if ($ok) { $swfs = @(Get-ChildItem -LiteralPath $cutTmp -Filter "HUDPC.swf" -Recurse -File -ErrorAction SilentlyContinue) }
                if ($swfs.Count -eq 0) {
                    Write-Fail "No HUDPC.swf found inside the archive - skipping."
                } else {
                    # The archive ships a plain version and one combined with the
                    # Deep Pockets HUD mod. Only the plain one is wanted here.
                    $chosen = $swfs | Where-Object { $_.FullName -match '(?i)vanilla' } | Select-Object -First 1
                    if (-not $chosen) { $chosen = $swfs | Where-Object { $_.FullName -notmatch '(?i)deep\s*pockets' } | Select-Object -First 1 }
                    if (-not $chosen) { $chosen = $swfs[0] }
                    $dest = Join-Path $flashDir "HUDPC.swf"
                    try {
                        if ((Test-Path -LiteralPath $dest) -and -not (Test-Path -LiteralPath "$dest.hubbak")) {
                            Copy-Item -LiteralPath $dest -Destination "$dest.hubbak" -Force -ErrorAction SilentlyContinue
                        }
                        Copy-Item -LiteralPath $chosen.FullName -Destination $dest -Force -ErrorAction Stop
                        Write-OK "Fullscreen cutscenes installed."
                        Write-Host "  Note: this replaces the game's HUD file, so it removes any" -ForegroundColor DarkGray
                        Write-Host "  other HUD mod. The original is kept as HUDPC.swf.hubbak" -ForegroundColor DarkGray
                    } catch { Write-Fail "Could not copy HUDPC.swf: $($_.Exception.Message)" }
                }
                try { Remove-Item $cutTmp -Recurse -Force -EA SilentlyContinue } catch {}
            } else { Write-Info "Skipped." }
        }
    }
}

try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}
# Each mod tracks its own release, so there are TWO version markers and
# each holds a BARE TAG and nothing else - the Hub compares them 1:1
# against the newest tag of that mod's repo. A label like
# "balouza v0.6.0" could never equal a tag and the tile would show
# "Update" forever.
#   .installed_version    -> balouza  (catalog GithubRepo)
#   .installed_version_b  -> BioVRDev (catalog GithubRepoB)
# A mod that was not (re)installed now keeps whatever it had; a missing
# file is seeded by the next scan, so no wrong version is ever claimed.
if ($haveB -and $tagB) {
    try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $tagB -Encoding UTF8 -Force } catch {}
}
if ($haveA -and $tagA) {
    try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version_b") -Value $tagA -Encoding UTF8 -Force } catch {}
}
try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}

# -------------------------------------------------------
# Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete - $activeName is active" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

if ($haveA -and $haveB) {
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "  |           YOU HAVE BOTH - READ THIS ONCE                 |" -ForegroundColor Yellow
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "   Both mods put their files in the same folder and their main" -ForegroundColor White
    Write-Host "   DLLs even share a name, so only ONE can be active at a time." -ForegroundColor White
    Write-Host "   Both are parked in " -NoNewline -ForegroundColor White
    Write-Host " $STORE_REL " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " and swapped in as needed." -ForegroundColor White
    Write-Host ""
    Write-Host "   To switch, use the two buttons on this game's Hub page, or" -ForegroundColor White
    Write-Host "   the two .bat files in " -NoNewline -ForegroundColor White
    Write-Host " $LAUNCH_REL " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "   Each one swaps the files and starts the game via Steam." -ForegroundColor White
    Write-Host "   Close the game before switching." -ForegroundColor White
    Write-Host ""
    Write-Host "   Both keep their own settings, so your tuning survives a swap." -ForegroundColor White
    Write-Host ""
}

Write-Host " What to do now:" -ForegroundColor White
Write-Host "   1) Start your OpenXR runtime and put the headset on." -ForegroundColor Gray
if ($activeName -eq "balouza") {
    Write-Host "   2) Set the game's resolution to roughly SQUARE, e.g. 2700x2700 -" -ForegroundColor Gray
    Write-Host "      a 16:9 image wastes most of its width in a headset." -ForegroundColor Gray
    Write-Host "   3) Launch through Steam, load into the game, press F10 and" -ForegroundColor Gray
    Write-Host "      click VR PRESET 1. No restart needed." -ForegroundColor Gray
    Write-Host ""
    Write-Host " balouza keeps its settings in %LOCALAPPDATA%\BioshockVR." -ForegroundColor Gray
    Write-Host " The shipped defaults are already a full calibration; the" -ForegroundColor Gray
    Write-Host " author's preset files sit in $STORE_REL if you want them." -ForegroundColor Gray
} else {
    Write-Host "   2) Launch with" -NoNewline -ForegroundColor Gray; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or from Steam -" -ForegroundColor Gray
    Write-Host "      no injector, no launcher." -ForegroundColor Gray
    Write-Host "   3) Play with motion controllers; the weapon follows your hand." -ForegroundColor Gray
    Write-Host ""
    Write-Host " Re-run the setup only if you change ResolutionX, ResolutionY or" -ForegroundColor Gray
    Write-Host " GameFovDegrees in BioshockVR.ini." -ForegroundColor Gray
}
Write-Host ""
Write-Host " itsloopyo's head-tracking mod cannot run next to either of these -" -ForegroundColor Gray
Write-Host " it uses the same injection file. Remove its xinput1_3.dll first." -ForegroundColor Gray
Write-Host ""
Write-Host "  Would you kindly put the headset on and descend into Rapture." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit." | Out-Null
