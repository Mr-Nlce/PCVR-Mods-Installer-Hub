# ============================================================
#  PEAK VR Installer (PEAK_VR by AstienVR)
# ============================================================
#
#  PEAK gets updated frequently and the VR mod stopped being
#  compatible with versions past 1.44.a. We pin the game to the
#  last known compatible Steam manifest using Steam Console's
#  download_depot command, then move the depot out of Steam's
#  reach into a stable folder so a future Steam update can't
#  blow the VR setup away.
#
#  Flow:
#    1) 7-Zip pre-flight + Steam Console download_depot for manifest
#       1663614006819171465 of App 3527290 / Depot 3527291 - that's
#       PEAK v1.44.a or the last known compatible build
#    2) Auto-detect the depot folder under steamapps\content\
#       and move it to C:\Games\PEAK VR (default, user can change)
#    3) Drop steam_appid.txt so the EXE can be launched directly
#    4) Auto-download PEAK_VR.zip from GitHub release v1.0.0
#       and extract into the pinned game folder
#    5) Drop kirigiri's PeakVersionBypass.dll into BepInEx\plugins\
#       so PEAK doesn't bail at the version check on launch
#    6) Run ViGEmBus_1.22.0_x64_x86_arm64.exe interactively -
#       Windows driver, requires UAC, can't be silent without
#       admin elevation
#    7) Desktop shortcut on PEAK.exe in the pinned folder
# ============================================================

$Host.UI.RawUI.WindowTitle = "PEAK VR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

# -------------------------------------------------------
#  Configuration
# -------------------------------------------------------
$MOD_NAME       = "PEAK_VR v1.0.0 (by AstienVR)"
$MOD_URL        = "https://github.com/AstienVR/PEAK_VR/releases/download/1.0.0/PEAK_VR.zip"
$GITHUB_URL     = "https://github.com/AstienVR/PEAK_VR"

# kirigiri's PeakVersionBypass: disables PEAK's online version check
# so the game can actually launch when pinned to an older manifest.
# Without this, PEAK refuses to enter the main menu, displays a
# "version outdated" prompt and locks you out of offline play.
# Hosted on Thunderstore; small DLL that goes into BepInEx\plugins.
$BYPASS_NAME    = "PeakVersionBypass v1.0.2 (by kirigiri)"
$BYPASS_URL     = "https://thunderstore.io/package/download/kirigiri/PeakVersionBypass/1.0.2/"
$BYPASS_PAGE    = "https://thunderstore.io/package/kirigiri/PeakVersionBypass/"
$BYPASS_DLL     = "PeakVersionBypass.dll"

# PEAK pinned to last mod-compatible manifest (game 1.44.a)
$DEPOT_APPID    = "3527290"
$DEPOT_DEPOTID  = "3527291"
$DEPOT_MANIFEST = "1663614006819171465"
$DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"

# Game executable inside the depot
$GAME_EXE       = "PEAK.exe"

# Target install folder
$DEFAULT_PATH   = "C:\Games\PEAK VR"

# ViGEmBus driver location after mod extract (the mod ships with it)
$VIGEM_REL_PATH = "BepInEx\redist\ViGEmBus_1.22.0_x64_x86_arm64.exe"

# -------------------------------------------------------
#  Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "   PEAK VR - Mod Installer" -ForegroundColor Cyan
    Write-Host "   Installs: $MOD_NAME" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($num, $total, $text)
    Write-Host ""
    Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
    Write-Host ""
}
function Write-OK   { param($text) Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host "  [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host "  [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "  [XX] $text" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Find-7Zip {
    foreach ($c in @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    )) { if (Test-Path $c) { return $c } }
    return $null
}

# -------------------------------------------------------
#  Pre-flight
# -------------------------------------------------------

# =======================================================
#  MODE SELECTION - two mods, two game builds
# =======================================================
# PEAK now has TWO VR mods, and they need DIFFERENT game builds:
#   [1] PeakVR by Andrey04o - for the CURRENT PEAK. Comes from
#       Thunderstore together with its four dependencies, and the
#       Hub can therefore auto-update it and see when it is
#       deprecated. Installs into the normal Steam copy.
#   [2] PEAK_VR by AstienVR - the original entry. Needs the pinned
#       Steam depot build 1.44.a in a separate folder. Left exactly
#       as it was.
# Everything below the "return" at the end of branch [1] is the
# untouched depot route.
$TS_MOD_AUTHOR  = "Andrey04o"
$TS_MOD_NAME    = "PeakVR"
# Dependency set exactly as PeakVR's own manifest.json lists it.
# Read out of Andrey04o-PeakVR-1.3.0.zip, not from the web page.
$TS_PACKAGES = @(
    @{ Key = "BepInEx-BepInExPack_PEAK";      Author = "BepInEx";      Name = "BepInExPack_PEAK"; Pinned = "5.4.75301"; Label = "BepInEx (PEAK pack)" }
    # !!! ABHAENGIGKEITEN VON PEAKLib_Core - DIE FEHLTEN !!!
    # PEAKLib_Core 1.7.2 fuehrt auf seiner Thunderstore-Seite selbst zwei
    # Pflichtabhaengigkeiten auf. Unsere Liste war aus PeakVRs manifest.json
    # abgeschrieben - und dort stehen nur die DIREKTEN Abhaengigkeiten, nicht
    # deren eigene. Sie stehen VOR PEAKLib_Core, damit sie zuerst liegen.
    @{ Key = "MonoDetour-MonoDetour_BepInEx_5"; Author = "MonoDetour"; Name = "MonoDetour_BepInEx_5"; Pinned = "0.6.7"; Label = "MonoDetour (BepInEx 5)" }
    @{ Key = "PEAKModding-SoftDependencyFix"; Author = "PEAKModding"; Name = "SoftDependencyFix";   Pinned = "1.0.0";     Label = "SoftDependencyFix" }
    @{ Key = "PEAKModding-PEAKLib_Core";      Author = "PEAKModding";  Name = "PEAKLib_Core";     Pinned = "1.7.2";     Label = "PEAKLib Core" }
    @{ Key = "PEAKModding-PEAKLib_UI";        Author = "PEAKModding";  Name = "PEAKLib_UI";       Pinned = "1.6.1";     Label = "PEAKLib UI" }
    @{ Key = "PEAKModding-ModConfig";         Author = "PEAKModding";  Name = "ModConfig";        Pinned = "1.6.0";     Label = "ModConfig" }
    @{ Key = "Andrey04o-PeakVR";              Author = "Andrey04o";    Name = "PeakVR";           Pinned = "1.3.0";     Label = "PeakVR" }
)

function Get-SteamPathP {
    foreach ($r in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p = (Get-ItemProperty -Path $r -ErrorAction Stop).InstallPath; if ($p -and (Test-Path $p)) { return $p } } catch {}
    }
    return $null
}
function Get-SteamLibrariesP { param($sp)
    $libs = @($sp)
    $vdf = Join-Path $sp "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
            $l = $_.Groups[1].Value -replace '\\\\','\'
            if (Test-Path $l) { $libs += $l }
        }
    }
    return $libs
}
function Get-TSInfo { param($author,$name)
    foreach ($u in @("https://thunderstore.io/api/experimental/package/$author/$name/")) {
        try {
            $d = (Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop).Content | ConvertFrom-Json
            return @{
                Version      = $d.latest.version_number
                DownloadUrl  = $d.latest.download_url
                Deprecated   = ($d.is_deprecated -eq $true)
                # Thunderstore nennt hier die Pflichtabhaengigkeiten als
                # Zeichenketten der Form "Namespace-Name-Version".
                Dependencies = @($d.latest.dependencies)
            }
        } catch { }
    }
    return $null
}
# ---------------------------------------------------------------
#  Resolve-TSDependencies - Abhaengigkeiten wirklich aufloesen
# ---------------------------------------------------------------
# WARUM ES DAS GIBT: die feste Liste oben stammt aus PeakVRs eigener
# manifest.json. Dort stehen aber nur die DIREKTEN Abhaengigkeiten -
# nicht das, was DIESE wiederum brauchen. Genau daran hat es gefehlt:
# PEAKLib_Core verlangt MonoDetour_BepInEx_5 und SoftDependencyFix,
# und beide wurden nie mitinstalliert.
#
# Thunderstore nennt zu jedem Paket seine Pflichtabhaengigkeiten als
# Zeichenketten "Namespace-Name-Version". Diese Funktion geht die Liste
# durch, fragt jedes Paket ab, haengt Unbekanntes hinten an und
# wiederholt das, bis nichts Neues mehr dazukommt - also auch ueber
# mehrere Ebenen.
#
# OHNE NETZ passiert nichts: dann bleibt es bei der festen Liste, und
# die enthaelt die bekannten Faelle bereits.
function Resolve-TSDependencies {
    param([array]$Packages)
    $list = @($Packages)
    $seen = @{}
    foreach ($p in $list) { $seen[$p.Key.ToLowerInvariant()] = $true }
    # Modloader nie als Abhaengigkeit nachziehen - BepInEx steht schon
    # als erster Eintrag in der Liste und wird gesondert behandelt.
    $skip = @("bepinex-bepinexpack_peak","bepinex-bepinexpack")

    $round = 0
    while ($round -lt 5) {
        $round++
        $added = 0
        foreach ($p in @($list)) {
            $info = Get-TSInfo -author $p.Author -name $p.Name
            if (-not $info -or -not $info.Dependencies) { continue }
            foreach ($dep in $info.Dependencies) {
                if (-not $dep) { continue }
                # "Namespace-Name-Version" von HINTEN trennen: der Name
                # darf selbst Bindestriche enthalten, die Version nicht.
                $parts = [string]$dep -split '-'
                if ($parts.Count -lt 3) { continue }
                $ver  = $parts[-1]
                $ns   = $parts[0]
                $name = ($parts[1..($parts.Count-2)]) -join '-'
                $key  = "$ns-$name"
                if ($skip -contains $key.ToLowerInvariant()) { continue }
                if ($seen.ContainsKey($key.ToLowerInvariant())) { continue }
                $seen[$key.ToLowerInvariant()] = $true
                $list += @{ Key = $key; Author = $ns; Name = $name; Pinned = $ver; Label = "$name (required by $($p.Name))" }
                $added++
                Write-Info "Additional requirement found: $ns-$name $ver"
            }
        }
        if ($added -eq 0) { break }
    }
    return $list
}

function Get-TSInstalledVersion { param($key,$gamePath)
    $f = Join-Path $gamePath "BepInEx\.ts_versions\$key"
    if (Test-Path -LiteralPath $f) { return (Get-Content -LiteralPath $f -Raw).Trim() }
    return $null
}
function Set-TSInstalledVersion { param($key,$version,$gamePath)
    $d = Join-Path $gamePath "BepInEx\.ts_versions"
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    Set-Content -LiteralPath (Join-Path $d $key) -Value $version -Encoding UTF8 -Force
}

# Thunderstore layout -> game folder. This is the part a blind
# extract-in-place gets wrong: a package's top level can be
#   BepInExPack_PEAK\   -> a wrapper, its CONTENT goes to the root
#   plugins\ patchers\  -> these belong under BepInEx\, NOT the root
# Verified against all five uploaded packages.
function Install-TSPackage { param($Zip,$Work,$GamePath,$Key)
    if (Test-Path -LiteralPath $Work) { Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $Work -Force | Out-Null
    Expand-Archive -LiteralPath $Zip -DestinationPath $Work -Force -ErrorAction Stop
    $meta = @("manifest.json","icon.png","README.md","CHANGELOG.md","LICENSE")
    $root = $Work
    # A single wrapper folder that is not itself a BepInEx layout dir.
    # -Force: .doorstop_version is a dot-file and would be skipped
    # without it on any host that treats those as hidden.
    $top = @(Get-ChildItem -LiteralPath $Work -Force | Where-Object { $_.Name -notin $meta })
    if ($top.Count -eq 1 -and $top[0].PSIsContainer -and $top[0].Name -notin @("BepInEx","plugins","patchers","monomod","core","config")) {
        $root = $top[0].FullName
    }
    $copied = 0
    foreach ($item in @(Get-ChildItem -LiteralPath $root -Force | Where-Object { $_.Name -notin $meta })) {
        if ($item.PSIsContainer -and $item.Name -in @("plugins","patchers","monomod","core","config")) {
            # BepInEx sub-tree: give each package its own folder so an
            # update can replace it and two packages never collide.
            $dest = Join-Path $GamePath ("BepInEx\" + $item.Name + "\" + $Key)
            if ($item.Name -in @("core","config")) { $dest = Join-Path $GamePath ("BepInEx\" + $item.Name) }
            if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
            # -Path, NOT -LiteralPath: with -LiteralPath the "*" is taken
            # literally and the copy fails with "cannot find path ...\*".
            Copy-Item -Path (Join-Path $item.FullName "*") -Destination $dest -Recurse -Force
            $copied += @(Get-ChildItem -LiteralPath $item.FullName -Recurse -File).Count
        } else {
            Copy-Item -LiteralPath $item.FullName -Destination $GamePath -Recurse -Force
            if ($item.PSIsContainer) { $copied += @(Get-ChildItem -LiteralPath $item.FullName -Recurse -File).Count } else { $copied++ }
        }
    }
    return $copied
}

Write-Header
Write-Host "  PEAK has TWO VR mods, and each needs a different build of the game." -ForegroundColor White
Write-Host ""

$tsLatest = Get-TSInfo -author $TS_MOD_AUTHOR -name $TS_MOD_NAME
Write-Host "  [1] Current PEAK" -NoNewline -ForegroundColor White
if ($tsLatest -and $tsLatest.Deprecated) {
    Write-Host "  - PeakVR by Andrey04o" -ForegroundColor Gray
    Write-Warn "This mod is marked DEPRECATED on Thunderstore."
} elseif ($tsLatest) {
    Write-Host "  - PeakVR by Andrey04o, v$($tsLatest.Version)" -ForegroundColor Gray
    Write-Host "       Auto-updating, installs into your normal Steam copy." -ForegroundColor Gray
} else {
    Write-Host "  - PeakVR by Andrey04o" -ForegroundColor Gray
    Write-Warn "Could not reach Thunderstore - the pinned versions will be used."
}
Write-Host ""
$depotHere = Test-Path -LiteralPath (Join-Path $DEFAULT_PATH $GAME_EXE)
Write-Host "  [2] Older PEAK 1.44.a" -NoNewline -ForegroundColor White
Write-Host "  - PEAK_VR by AstienVR" -ForegroundColor Gray
if ($depotHere) { Write-Host "       Already installed at $DEFAULT_PATH" -ForegroundColor Green }
else            { Write-Host "       Downloads a pinned Steam depot build into its own folder." -ForegroundColor Gray }
Write-Host ""
$peakMode = ""
while ($peakMode -notin @("1","2")) { $peakMode = (Read-Host "  Your choice (1 or 2)").Trim() }

if ($peakMode -eq "1") {
    Write-Step 1 3 "Finding your PEAK installation"
    $gamePath = $null
    $sp = Get-SteamPathP
    if ($sp) {
        foreach ($lib in (Get-SteamLibrariesP $sp)) {
            $c = Join-Path $lib "steamapps\common\PEAK"
            if (Test-Path -LiteralPath (Join-Path $c $GAME_EXE)) { $gamePath = $c; break }
        }
    }
    if (-not $gamePath) { $gamePath = Get-GameFolderInteractive -GameName "PEAK" -ProbeFile $GAME_EXE }
    if (-not $gamePath -or -not (Test-Path -LiteralPath (Join-Path $gamePath $GAME_EXE))) {
        Write-Fail "Could not find $GAME_EXE - nothing was installed."
        Pause-User "Press Enter to exit..." | Out-Null
        return
    }
    Write-OK "PEAK: $gamePath"

    Write-Step 2 3 "Installing PeakVR and its dependencies"
    $tmp = Join-Path $env:TEMP ("peakvr_" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    # Erst die Abhaengigkeiten aufloesen, dann installieren. Bringt das
    # Netz nichts, bleibt es bei der festen Liste.
    $TS_PACKAGES = Resolve-TSDependencies -Packages $TS_PACKAGES
    Write-OK "$($TS_PACKAGES.Count) package(s) to check."
    $allOk = $true
    foreach ($pkg in $TS_PACKAGES) {
        $ver = $pkg.Pinned
        $url = "https://thunderstore.io/package/download/$($pkg.Author)/$($pkg.Name)/$($pkg.Pinned)/"
        $info = Get-TSInfo -author $pkg.Author -name $pkg.Name
        if ($info -and $info.Version -and $info.DownloadUrl) { $ver = $info.Version; $url = $info.DownloadUrl }
        $have = Get-TSInstalledVersion -key $pkg.Key -gamePath $gamePath
        if ($have -eq $ver) { Write-OK "$($pkg.Label) $ver already installed."; continue }
        $zip = Join-Path $tmp ("$($pkg.Key).zip")
        Write-Info "$($pkg.Label) $ver ..."
        $ok = Invoke-SafeDownload -Urls @($url) -Destination $zip -Label $pkg.Label `
                  -ManualUrl "https://thunderstore.io/c/peak/p/$($pkg.Author)/$($pkg.Name)/" `
                  -Instructions "Download the ZIP for $($pkg.Label) from the Thunderstore page and drop it here."
        if (-not $ok -or -not (Test-Path -LiteralPath $zip)) { Write-Fail "$($pkg.Label) could not be downloaded."; $allOk = $false; break }
        try {
            $n = Install-TSPackage -Zip $zip -Work (Join-Path $tmp $pkg.Key) -GamePath $gamePath -Key $pkg.Key
            Write-OK "$($pkg.Label) $ver - $n file(s)."
            Set-TSInstalledVersion -key $pkg.Key -version $ver -gamePath $gamePath
        } catch {
            Write-Fail "$($pkg.Label) could not be installed: $($_.Exception.Message)"
            $allOk = $false; break
        }
    }
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

    # Proof, not a claim: the mod's own DLL has to be on disk.
    $proof = Join-Path $gamePath "BepInEx\plugins\Andrey04o-PeakVR\com.andrey04o.PeakVR.dll"
    if (-not $allOk -or -not (Test-Path -LiteralPath $proof)) {
        Write-Fail "PeakVR is not in place - the install is incomplete."
        Write-Info "Expected: $proof"
        Pause-User "Press Enter to exit..." | Out-Null
        return
    }
    Write-OK "PeakVR is installed."

    Write-Step 3 3 "Finishing up"
    try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
    try {
        $sc = New-DesktopShortcut -ShortcutName "PEAK VR" -TargetPath "steam://rungameid/$DEPOT_APPID" `
                  -WorkingDir $gamePath -Description "PEAK in VR (PeakVR)"
        if ($sc) { Write-OK "Desktop shortcut 'PEAK VR' created." }
    } catch { Write-Warn "Could not create the desktop shortcut: $($_.Exception.Message)" }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " PeakVR is installed!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  START: " -NoNewline -ForegroundColor Cyan; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or launch PEAK from Steam." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  IMAGE LOOKS BLURRY? In the game: Settings > Mod Settings >" -ForegroundColor Cyan
    Write-Host "  PEAK VR > VR GRAPHICS > " -NoNewline -ForegroundColor Cyan; Write-Host " MAKE IMAGE SHARPER = Enable " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Write-Host "  Extra frames: add the launch option " -NoNewline -ForegroundColor Gray; Write-Host "-force-d3d11" -NoNewline -ForegroundColor White; Write-Host " in Steam." -ForegroundColor Gray
    Write-Host "  You climb the way the base game does - this is not a" -ForegroundColor Gray
    Write-Host "  hand-over-hand climbing simulator." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Works in lobbies with flat players. Tested against PEAK 1.65.a." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  The mountain does not care that you can see it properly now." -ForegroundColor Magenta
    Write-Host ""
    Pause-User "Press Enter to exit." | Out-Null
    return
}

# =======================================================
#  From here on: the ORIGINAL depot route for PEAK_VR by
#  AstienVR, unchanged.
# =======================================================

Write-Header

$sevenZip = Find-7Zip
if (-not $sevenZip) {
    Write-Fail "7-Zip not installed."
    Write-Host ""
    Write-Host "  This installer needs 7-Zip's command-line tool. Install it:" -ForegroundColor Yellow
    Write-Host "    https://www.7-zip.org" -ForegroundColor White
    Pause-User "Press Enter to exit..."
    exit 1
}
Write-OK "7-Zip detected: $sevenZip"

Write-Host ""
Write-Host "  PEAK has been updated past version 1.44.a, which broke the VR mod." -ForegroundColor White
Write-Host "  This installer pins the game to the last mod-compatible Steam" -ForegroundColor White
Write-Host "  manifest in a separate folder so your normal Steam install isn't" -ForegroundColor White
Write-Host "  touched." -ForegroundColor White
Write-Host ""
Write-Host "  You'll need:" -ForegroundColor White
Write-Host "    - PEAK owned on Steam (App $DEPOT_APPID)" -ForegroundColor Gray
Write-Host "    - Steam running and logged in" -ForegroundColor Gray
Write-Host "    - About 4 GB free disk space" -ForegroundColor Gray
Write-Host "    - Admin rights for the ViGEmBus driver install (UAC prompt)" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to begin..."

# -------------------------------------------------------
#  STEP 1: Steam Console download_depot
# -------------------------------------------------------
Write-Step 1 7 "Download PEAK v1.44.a via Steam Console"

Write-Host "  Steam Console will be opened. The depot command is already" -ForegroundColor White
Write-Host "  copied to your clipboard - just paste (Ctrl+V) into the console" -ForegroundColor White
Write-Host "  input field and press Enter." -ForegroundColor White
Write-Host ""
Write-Host "  Command:" -ForegroundColor Gray
Write-Host "    $DEPOT_COMMAND" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Manifest $DEPOT_MANIFEST is PEAK v1.44.a (the last mod-compatible build)." -ForegroundColor Gray
Write-Host "  About 4 GB to download." -ForegroundColor Gray
Write-Host ""

try { Set-Clipboard -Value $DEPOT_COMMAND } catch {}

Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   ACTION REQUIRED - Paste into Steam Console" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [OK] Depot command copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Press Enter to open the Steam Console..." -ForegroundColor Yellow
Write-Host "  Then click the input field, paste (Ctrl+V) and hit Enter." -ForegroundColor Yellow
Write-Host ""
Write-Host ""
if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
    Write-Host "  (i) Virtual Desktop users: the Steam Console may not open" -ForegroundColor DarkGray
    Write-Host "      automatically from inside a VD streaming session. If it" -ForegroundColor DarkGray
    Write-Host "      doesn't, open it manually: Steam menu bar - View - Console," -ForegroundColor DarkGray
    Write-Host "      then paste-and-Enter. Alternatively, choose [3] in the" -ForegroundColor DarkGray
    Write-Host "      next menu to use the DepotDownloader fallback." -ForegroundColor DarkGray
    Write-Host ""
}
Pause-User "Press Enter to open the Steam Console..."
# Beide Protokoll-Adressen: je nach Steam-Version zieht nur eine.
foreach ($cu in @("steam://open/console", "steam://nav/console")) {
    try { Start-Process $cu; Start-Sleep -Milliseconds 900 } catch {}
}
Write-OK "Steam Console opening..."

Write-Host ""
Pause-User "Press Enter once the Steam depot download is complete..."

# -------------------------------------------------------
#  STEP 2: Locate + move depot to stable folder
# -------------------------------------------------------
Write-Step 2 7 "Locate depot and move to stable folder"

Write-Host "  Looking for Steam installation..." -ForegroundColor White

$steamInstallPath = $null
foreach ($reg in @(
    "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
    "HKLM:\SOFTWARE\Valve\Steam",
    "HKCU:\SOFTWARE\Valve\Steam"
)) {
    try {
        $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
        if ($p -and (Test-Path $p)) { $steamInstallPath = $p; break }
    } catch {}
}

$depotPath = $null

if ($steamInstallPath) {
    $autoPath = Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID"
    Write-Info "Expected depot path: $autoPath"
    if ((Test-Path $autoPath) -and (Test-Path (Join-Path $autoPath $GAME_EXE))) {
        $depotPath = $autoPath
        Write-OK "Depot folder found automatically!"
    } else {
        Write-Warn "Depot folder not found at expected location."
        Write-Host "  This usually means the download isn't finished yet," -ForegroundColor Gray
        Write-Host "  or Steam used a different path." -ForegroundColor Gray
    }
} else {
    Write-Warn "Could not find Steam installation in registry."
}

if (-not $depotPath) {
    $probePaths = @()
    if ($steamInstallPath) {
        $probePaths += (Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID")
    }
    $depotPath = Resolve-DepotPath -GameName "PEAK" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
    if (-not $depotPath) {
        Write-Fail "No depot folder provided."
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

# Sanity check: depot should contain the game exe
$depotExe = Join-Path $depotPath $GAME_EXE
if (-not (Test-Path $depotExe)) {
    Write-Warn "'$GAME_EXE' not found inside depot."
    Write-Host "  Expected: $depotExe" -ForegroundColor Gray
    Write-Host "  This usually means the download is incomplete or the wrong" -ForegroundColor Gray
    Write-Host "  manifest was downloaded. Install anyway?" -ForegroundColor White
    $choice = ""
    while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host "  Continue? (Y/N)").Trim() }
    if ($choice -in @("n","N")) {
        Write-Info "Aborted by user."
        Pause-User "Press Enter to exit..."
        exit 0
    }
} else {
    Write-OK "$GAME_EXE confirmed in depot."
}

# Pick target folder and move there
$parentOfDepot = Split-Path $depotPath -Parent  # ...\app_3527290

Write-Host ""
Write-Host "  Default install location: $DEFAULT_PATH" -ForegroundColor Gray
Write-Host "  (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
Write-Host "   library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
Write-Host ""
$userInput = (Read-Host "  Press Enter to use default, or type a different full path").Trim().Trim('"')
if (-not $userInput) {
    $targetPath = $DEFAULT_PATH
} else {
    $targetPath = $userInput
}

$targetParent = Split-Path $targetPath -Parent
if ($targetParent -and -not (Test-Path $targetParent)) {
    try { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
    catch { Write-Fail "Could not create parent folder $targetParent : $_"; Pause-User "Press Enter to exit..."; exit 1 }
}

Write-Host ""
Write-Host "  Current location:  $depotPath" -ForegroundColor Gray
Write-Host "  Moving to:         $targetPath" -ForegroundColor Gray
Write-Host ""
Write-Host "  Why? Steam may overwrite the app_$DEPOT_APPID folder during" -ForegroundColor Gray
Write-Host "  future depot downloads. Moving to a stable name keeps the" -ForegroundColor Gray
Write-Host "  VR install safe and separate from your retail PEAK." -ForegroundColor Gray
Write-Host ""

if (Test-Path $targetPath) {
    Write-Warn "A folder already exists at $targetPath"
    Write-Info "Merging the pinned build; saves, BepInEx configs/plugins and other additional files are preserved."
}

try {
    $null = Merge-DirectoryTreeVerified -Source $depotPath -Destination $targetPath -RemoveSource -Label "PEAK depot build"
    Write-OK "Game installed at: $targetPath"
} catch {
    Write-Fail "Merge failed: $_"
    Write-Info "The game files are still at: $depotPath"
    Pause-User "Press Enter to exit..."
    exit 1
}

# Clean up empty app_<id> folder
try {
    if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
        Remove-Item $parentOfDepot -Force
    }
} catch {}

$gamePath    = $targetPath
$gameExePath = Join-Path $gamePath $GAME_EXE

# -------------------------------------------------------
#  STEP 3: steam_appid.txt
# -------------------------------------------------------
Write-Step 3 7 "Drop steam_appid.txt"

# Without this, Steam may try to re-install or update PEAK whenever
# the user launches the EXE while Steam is running.
try {
    $steamAppIdFile = Join-Path $gamePath "steam_appid.txt"
    Set-Content -Path $steamAppIdFile -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force
    Write-OK "steam_appid.txt created (prevents Steam re-install prompt)."
} catch {
    Write-Warn "Could not create steam_appid.txt: $_"
    Write-Host "  Create a file called 'steam_appid.txt' next to PEAK.exe," -ForegroundColor Gray
    Write-Host "  containing only the number $DEPOT_APPID." -ForegroundColor Gray
}

# -------------------------------------------------------
#  STEP 4: Download + extract PEAK_VR mod
# -------------------------------------------------------
Write-Step 4 7 "Download PEAK_VR mod and apply"

$modTmp = Join-Path $env:TEMP "PEAKVRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $modTmp | Out-Null
$modZip = Join-Path $modTmp "PEAK_VR.zip"

$r = Invoke-DownloadOrFallback -Url $MOD_URL -Destination $modZip `
        -Label "PEAK VR mod v1.0.0" `
        -ManualUrl "https://github.com/AstienVR/PEAK_VR/releases/tag/1.0.0" `
        -Instructions "Download 'PEAK_VR.zip' from the GitHub releases page. Place it at '$modZip' and choose Retry." `
        -SkipMessage "Skipped - PEAK VR mod missing; install is incomplete (questionable result)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) { Pause-User "Install cannot continue without the VR mod. Press Enter to exit..."; exit 1 }

Write-Info "Extracting the mod into a staging folder..."
$modExtract = Join-Path $modTmp "extracted"
$efb = Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $modExtract -Label "PEAK_VR" `
        -SkipMessage "Skipped - PEAK_VR was not extracted; the VR mod will NOT load."
if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if ([string]$efb -ne "ok" -and [string]$efb -ne "manual") {
    Pause-User "Mod extraction skipped/failed. Install incomplete. Press Enter to exit..."
    exit 1
}
$modPayload = $modExtract
$modChildren = @(Get-ChildItem -Path $modExtract -Force -ErrorAction SilentlyContinue)
if ($modChildren.Count -eq 1 -and $modChildren[0].PSIsContainer) { $modPayload = $modChildren[0].FullName }
try {
    $null = Merge-DirectoryTreeVerified -Source $modPayload -Destination $gamePath -Label "PEAK_VR mod files" `
        -KeepExistingRelativePaths @("BepInEx\config")
    Write-OK "Mod files merged; existing BepInEx configuration was retained."
} catch {
    Write-Fail "Could not merge the mod files: $_"
    Pause-User "Press Enter to exit without deleting existing files..."
    exit 1
}

# Sanity check
$missing = @()
foreach ($f in @("winhttp.dll", $VIGEM_REL_PATH)) {
    if (-not (Test-Path (Join-Path $gamePath $f))) { $missing += $f }
}
if ($missing.Count -gt 0) {
    Write-Warn "Some expected mod files are missing: $($missing -join ', ')"
    Write-Warn "The mod may not function. Inspect $gamePath manually."
} else {
    Write-OK "Mod files in place (winhttp.dll, ViGEmBus installer present)."
}

try { Remove-Item -Path $modTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
# Correct two shipped config values
# -------------------------------------------------------
# The mod archive ships UnityVR_Bepinex.cfg with two settings that break
# controllers in practice:
#   fixControllerTracking = false  -> controller tracking dies on every
#                                     scene load; must be true
#   controllerType        = ps4    -> must be xbox360 for the emulated
#                                     gamepad to be recognised
# Both are rewritten in place, keeping the rest of the file untouched.
# Only the setting lines are matched (not the "# Default value:" comment
# lines above them), and each is verified after writing.
$vrCfg = Join-Path $gamePath "BepInEx\config\UnityVR_Bepinex.cfg"
if (Test-Path -LiteralPath $vrCfg) {
    try {
        $cfgRaw = Get-Content -LiteralPath $vrCfg -Raw -Encoding UTF8
        $before = $cfgRaw
        $cfgRaw = [regex]::Replace($cfgRaw, '(?m)^(\s*fixControllerTracking\s*=\s*).*$', '${1}true')
        $cfgRaw = [regex]::Replace($cfgRaw, '(?m)^(\s*controllerType\s*=\s*).*$', '${1}xbox360')
        if ($cfgRaw -ne $before) {
            Set-Content -LiteralPath $vrCfg -Value $cfgRaw -Encoding UTF8 -NoNewline -Force
        }
        $check = Get-Content -LiteralPath $vrCfg -Raw -Encoding UTF8
        $okTrack = $check -match '(?m)^\s*fixControllerTracking\s*=\s*true\s*$'
        $okType  = $check -match '(?m)^\s*controllerType\s*=\s*xbox360\s*$'
        if ($okTrack -and $okType) {
            Write-OK "VR config corrected (fixControllerTracking = true, controllerType = xbox360)."
        } else {
            Write-Warn "Could not confirm both config values. Open $vrCfg and set"
            Write-Warn "fixControllerTracking = true and controllerType = xbox360 manually."
        }
    } catch {
        Write-Warn "Could not edit $vrCfg ($_)."
        Write-Warn "Set fixControllerTracking = true and controllerType = xbox360 manually."
    }
} else {
    Write-Warn "UnityVR_Bepinex.cfg not found yet - it is created on first launch."
    Write-Warn "After the first start, set fixControllerTracking = true and"
    Write-Warn "controllerType = xbox360 in BepInEx\config\UnityVR_Bepinex.cfg."
}

# -------------------------------------------------------
#  STEP 5: Install PeakVersionBypass (kirigiri)
# -------------------------------------------------------
# PEAK refuses to enter the main menu when its client version doesn't
# match Steam's expected current version. Since we deliberately pinned
# to manifest 1.44.a, PEAK on launch shows an "update required" prompt
# and never reaches gameplay - not even offline. kirigiri's
# PeakVersionBypass is a tiny BepInEx plugin that silences that check.
Write-Step 5 7 "Install PeakVersionBypass (version-check bypass)"

$bypassTmp = Join-Path $env:TEMP "PeakVersionBypass_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $bypassTmp | Out-Null
$bypassZip = Join-Path $bypassTmp "PeakVersionBypass.zip"

Write-Info "Downloading $BYPASS_NAME ..."
$r = Invoke-DownloadOrFallback -Url $BYPASS_URL -Destination $bypassZip `
        -Label "PEAK Version Bypass" `
        -ManualUrl "$BYPASS_PAGE" `
        -Instructions "Download the latest PeakVersionBypass ZIP from the Thunderstore page. Place it at '$bypassZip' and choose Retry. Alternatively, extract '$BYPASS_DLL' into '$gamePath\BepInEx\plugins\' yourself and choose Skip." `
        -SkipMessage "Skipped - PEAK Version Bypass missing; PEAK will block at the version check (high impact)."
if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
if (-not ($r -is [bool] -and $r)) {
    Write-Warn "Bypass auto-download skipped. PEAK may block at version check."
    Pause-User "Press Enter once you've handled the bypass manually (or to continue without it)..."
}

# Extract only the DLL we need into the existing BepInEx\plugins folder
if (Test-Path $bypassZip) {
    $bypassExtract = Join-Path $bypassTmp "extract"
    try {
        $proc = Start-Process -FilePath $sevenZip -ArgumentList @(
            "x", "-y", "`"$bypassZip`"", "-o`"$bypassExtract`""
        ) -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -ne 0) { throw "7-Zip exit code $($proc.ExitCode)" }

        $bypassSrc = Join-Path $bypassExtract "BepInEx\plugins\$BYPASS_DLL"
        if (-not (Test-Path $bypassSrc)) {
            Write-Warn "$BYPASS_DLL not found in bypass ZIP after extract."
            Write-Warn "Skipping bypass install. PEAK will block at version check."
        } else {
            $bypassDst = Join-Path $gamePath "BepInEx\plugins\$BYPASS_DLL"
            $pluginsDir = Split-Path $bypassDst -Parent
            if (-not (Test-Path $pluginsDir)) {
                New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
            }
            Copy-Item -Path $bypassSrc -Destination $bypassDst -Force
            Write-OK "$BYPASS_DLL copied into BepInEx\plugins\."
        }
    } catch {
        Write-Warn "Bypass extract / copy failed: $_"
        Write-Warn "PEAK may block at the version check on launch."
    }
}

try { Remove-Item -Path $bypassTmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# -------------------------------------------------------
#  STEP 6: Install ViGEmBus driver
# -------------------------------------------------------
Write-Step 6 7 "Install ViGEmBus driver (gamepad emulation)"

$vigemExe = Join-Path $gamePath $VIGEM_REL_PATH
if (-not (Test-Path $vigemExe)) {
    Write-Warn "ViGEmBus installer not found at expected path:"
    Write-Warn "  $vigemExe"
    Write-Warn "Skipping driver install. You will need to install it manually."
    Write-Info "Download: https://github.com/nefarius/ViGEmBus/releases"
} else {
    # Detect an existing ViGEmBus install so users who already have it
    # (very common - it ships with many VR mods, Virtual Desktop,
    # DS4Windows, etc.) can just press Enter. Re-installing stays
    # available via V.
    $vigemPresent = $false
    try { $vigemPresent = Test-ViGEmBusInstalled } catch { $vigemPresent = $false }

    if ($vigemPresent) {
        Write-OK "ViGEmBus already detected on this PC."
        Write-Host ""
        Write-Host "  Press ENTER to continue to the next step (recommended)." -ForegroundColor White
        Write-Host "  If your VR controllers give you trouble, you can (re)install" -ForegroundColor Gray
        Write-Host "  it: type V then Enter." -ForegroundColor Gray
        $reinst = (Read-Host "  [Enter] skip / [V] reinstall").Trim()
        if ($reinst -in @("v","V")) {
            Write-Info "Launching ViGEmBus installer..."
            try {
                Start-Process -FilePath $vigemExe -Wait
                Write-OK "ViGEmBus setup finished."
            } catch {
                Write-Warn "ViGEmBus install threw: $_"
                Write-Warn "Run it manually from: $vigemExe"
            }
        } else {
            Write-Info "Keeping the existing ViGEmBus install."
        }
    } else {
        Write-Host "  PEAK_VR uses ViGEmBus to emulate an Xbox controller from your VR" -ForegroundColor White
        Write-Host "  controllers. The driver needs admin rights (UAC prompt)." -ForegroundColor White
        Write-Host ""
        Write-Host "  If ViGEmBus is ALREADY installed on your system, just close the" -ForegroundColor Cyan
        Write-Host "  setup window when it appears - no re-install needed." -ForegroundColor Cyan
        Write-Host ""
        $skip = (Read-Host "  Run ViGEmBus installer now? (Y/N)").Trim()
        if ($skip -in @("y","Y","")) {
            Write-Info "Launching ViGEmBus installer..."
            try {
                Start-Process -FilePath $vigemExe -Wait
                Write-OK "ViGEmBus setup finished."
                Write-Info "When PEAK launches you should hear a Windows 'device connected' sound -"
                Write-Info "that confirms the ViGEmBus driver is active."
            } catch {
                Write-Warn "ViGEmBus install threw: $_"
                Write-Warn "Run it manually from: $vigemExe"
            }
        } else {
            Write-Info "Skipped. Run later from: $vigemExe"
        }
    }
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# -------------------------------------------------------
#  STEP 7: Desktop shortcut
# -------------------------------------------------------
Write-Step 7 7 "Create desktop shortcut"

try {
    $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\PEAK VR.lnk" -TargetPath $gameExePath -WorkingDir $gamePath -IconPath "$gameExePath,0" -Arguments "-force-vulkan"
    Write-OK "Desktop shortcut 'PEAK VR' created (with -force-vulkan)."
} catch {
    Write-Warn "Could not create desktop shortcut: $_"
    Write-Host "  Launch manually from:" -ForegroundColor Gray
    Write-Host "  $gameExePath -force-vulkan" -ForegroundColor Yellow
}

# -------------------------------------------------------
#  Done
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Done. Before launching:" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  1. Steam client must be running (PEAK still needs Steam auth)" -ForegroundColor White
Write-Host "  2. Start SteamVR" -ForegroundColor White
Write-Host "  3. Launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the" -ForegroundColor White
Write-Host "     'PEAK VR' desktop shortcut" -ForegroundColor White
Write-Host ""
Write-Host "  The shortcut launches PEAK with -force-vulkan, which is the" -ForegroundColor Cyan
Write-Host "  author's recommended VR API combo (OpenVR + Vulkan). VR renders" -ForegroundColor Cyan
Write-Host "  to the headset; the flatscreen window may not show an image -" -ForegroundColor Cyan
Write-Host "  that's normal and not a bug." -ForegroundColor Cyan
Write-Host ""
Write-Host "  If VR doesn't render with -force-vulkan, the only other combo" -ForegroundColor Gray
Write-Host "  that works for some setups is OpenXR + D3D12:" -ForegroundColor Gray
Write-Host "    1) Edit BepInEx\config\UnityVR_Bepinex.cfg" -ForegroundColor Gray
Write-Host "    2) Change 'vrApi = OpenVR' to 'vrApi = OpenXR'" -ForegroundColor Gray
Write-Host "    3) Edit the shortcut: replace -force-vulkan with -force-d3d12" -ForegroundColor Gray
Write-Host ""
Write-Host "  Quick controls:" -ForegroundColor Cyan
Write-Host "    - VR controllers map as an Xbox gamepad" -ForegroundColor White
Write-Host "    - Click BOTH thumbsticks to recenter VR view" -ForegroundColor White
Write-Host "    - Hold left hand near your head: hotkey gesture mode" -ForegroundColor White
Write-Host "    - White laser = interact / pick / throw" -ForegroundColor White
Write-Host "    - Red laser   = aim (shootable items)" -ForegroundColor White
Write-Host ""
Write-Host "  Virtual Desktop users: in the headset's VD input settings," -ForegroundColor Yellow
Write-Host "  make sure NO gamepad emulation is checked (Gamepad / Dpad off)." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Full config guide, troubleshooting and known issues are on the" -ForegroundColor Gray
Write-Host "  PEAK VR description page in the Hub." -ForegroundColor Gray
Write-Host ""
Write-Host "  Reach the summit. Try not to fall. See you up top, Scout." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
exit 0
