# ============================================================
#  PCVR Mods Installer Hub
# ============================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Captured as early as possible: used to record the real load time
# (process start -> window first rendered) to %TEMP% so the launcher
# splash can pace its progress bar against the last run's duration.
$global:HubLoadStart = [DateTime]::UtcNow

# PowerShell 5.1 defaults to TLS 1.0/1.1 which Steam CDN (and most
# modern HTTPS endpoints) no longer accept. Without this, BitmapImage
# downloads from cdn.akamai.steamstatic.com silently fail for some
# games and the hero image stays blank. Set before any network access.
try {
    [System.Net.ServicePointManager]::SecurityProtocol = `
        [System.Net.SecurityProtocolType]::Tls12 -bor `
        [System.Net.SecurityProtocolType]::Tls11 -bor `
        [System.Net.SecurityProtocolType]::Tls
} catch { }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:scriptDir = $scriptDir
$global:scriptDir = $scriptDir   # global mirror for global: functions (cache helpers)
$rootDir   = Split-Path -Parent $scriptDir   # Hub root (one level up from Core\)

# Path to the installer log wrapper (used by Start-LoggedInstaller).
$global:RunInstallerPath = Join-Path $scriptDir "Run-Installer.ps1"

# Session log: capture the Hub's own console output to Logs\Hub-<timestamp>.log.
# Start-Transcript writes live, so the file survives a crash. Best-effort and
# never blocks startup. Logs live in Core\Logs (the installer wrapper uses the
# same folder), keeping the Hub's top folder clean; robocopy /E in
# Update-Hub.ps1 leaves the folder untouched.
try {
    $logsDir = Join-Path $scriptDir "Logs"
    if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
    # -File: without it a DIRECTORY called something.log would come back
    # from the filter and get handed to Remove-Item. Cheap guard, and the
    # rule everywhere now is that a delete only ever sees a file.
    Get-ChildItem $logsDir -Filter *.log -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -Skip 30 |
        Remove-Item -Force -ErrorAction SilentlyContinue
    $hubLog = Join-Path $logsDir ("Hub-{0}.log" -f (Get-Date -Format "yyyy-MM-dd_HH-mm-ss"))
    Start-Transcript -Path $hubLog -Force -ErrorAction SilentlyContinue | Out-Null
} catch {}

# -------------------------------------------------------
# Startup timing (diagnostic, opt-in).
# Enable by creating an empty file '.timing' in the Hub root
# (next to PCVRModsHub.bat). When present, phase timestamps are
# appended to %TEMP%\PCVRHub_startup.log so we can see where the
# startup time goes. No file is written to the Hub itself
# (state-file ship guard - rule #2 / audit #15).
# -------------------------------------------------------
$global:HubTiming = @{ Enabled = $false; Start = $null; Log = $null }
try {
    $timingFlag = Join-Path $rootDir ".timing"
    if (Test-Path $timingFlag) {
        $global:HubTiming.Enabled = $true
        $global:HubTiming.Start = [DateTime]::UtcNow
        $global:HubTiming.Log = Join-Path $env:TEMP "PCVRHub_startup.log"
        $banner = "===== PCVR Hub startup $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') v$HUB_VERSION ====="
        Add-Content -Path $global:HubTiming.Log -Value "" -ErrorAction SilentlyContinue
        Add-Content -Path $global:HubTiming.Log -Value $banner -ErrorAction SilentlyContinue
    }
} catch { }
function global:Write-HubTiming {
    param([string]$Phase)
    if (-not $global:HubTiming.Enabled) { return }
    try {
        $ms = [int]([DateTime]::UtcNow - $global:HubTiming.Start).TotalMilliseconds
        $line = ("{0,7} ms  {1}" -f $ms, $Phase)
        Add-Content -Path $global:HubTiming.Log -Value $line -ErrorAction SilentlyContinue
    } catch { }
}
Write-HubTiming "boot: after assembly load + scriptDir"

# -------------------------------------------------------
# Version & Update check
# -------------------------------------------------------
$HUB_VERSION = "0.8.5.9"

$updateInfoFile  = Join-Path $scriptDir ".update_available"
$script:updateInfo = $null
if (Test-Path $updateInfoFile) {
    try { $script:updateInfo = Get-Content $updateInfoFile -Raw | ConvertFrom-Json } catch {}
}

# -------------------------------------------------------
# Mod version tracking helpers
# -------------------------------------------------------
# Parse a version number out of a Mod display string, e.g.
#   "L4D2VR v0.6.4"           -> "0.6.4"
#   "R.E.A.L. VR v2603.10.1"  -> "2603.10.1"
#   "NomaiVR 2.10.0"          -> "2.10.0"
#   "Fully Possessed v0.021j" -> "0.021j"
# Returns $null if no version-looking token is found.
function Get-ModVersionFromString {
    param([string]$ModString)
    if (-not $ModString) { return $null }
    $m = [regex]::Match($ModString, '\bv?(\d+\.\d+(?:\.\d+)*[a-zA-Z]?)', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

# Given a $game hash, return full path to its .installed_version file.
# Derived from the Bat field: "L4D2VR\START_INSTALLER.bat" -> Core\L4D2VR\.installed_version
# Returns $null if game has no Bat or Bat is malformed.
function Get-InstalledVersionPath {
    param($Game)
    if (-not $Game -or -not $Game.Bat) { return $null }
    $modFolder = Split-Path -Parent $Game.Bat
    if (-not $modFolder) { return $null }
    # Multi-game installers (LukeRossVR, REFrameworkVR, QuestZDoomShared)
    # share one Bat folder across many titles. Key the version file by title
    # so each game tracks its own installed build (mirrors Get-InstalledPathFile);
    # otherwise updating one REFramework game would mark all of them current.
    $isMulti = ($modFolder -ieq 'LukeRossVR' -or $modFolder -ieq 'REFrameworkVR' -or $modFolder -ieq 'QuestZDoomShared')
    if ($isMulti) {
        $safe = ($Game.Title -replace '[^A-Za-z0-9]', '_')
        return (Join-Path $script:scriptDir (Join-Path $modFolder ".installed_version_$safe"))
    }
    return (Join-Path $script:scriptDir (Join-Path $modFolder ".installed_version"))
}

# Given a $game hash, return full path to its .installed_path file.
# Some installers (Outward, Tormented Souls) put the game in a custom
# location the user chose, so we can't guess where to detect the mod.
# If this file exists and points to a real folder, that folder wins
# over any SteamFolder / FallbackPaths heuristic.
function Get-InstalledPathFile {
    param($Game)
    if (-not $Game) { return $null }
    if (-not $Game.Bat) {
        # Bat-less entries (external tools / games the user installs
        # themselves) have no installer folder. Store any user-located
        # path in a shared runtime "Located" folder keyed by title so the
        # "Locate install" button works and the scan can re-verify it.
        if (-not $Game.Title) { return $null }
        $safeL = ($Game.Title -replace '[^A-Za-z0-9]', '_')
        return (Join-Path $script:scriptDir (Join-Path "Located" (".installed_path_" + $safeL)))
    }
    $modFolder = Split-Path -Parent $Game.Bat
    if (-not $modFolder) { return $null }
    # Multi-game installers (LukeRossVR, REFrameworkVR, QuestZDoomShared)
    # all share one Bat folder across many titles. A single .installed_path
    # file would be overwritten on every install. Key the file by title.
    $isMulti = ($modFolder -ieq 'LukeRossVR' -or $modFolder -ieq 'REFrameworkVR' -or $modFolder -ieq 'QuestZDoomShared')
    if ($isMulti) {
        $safe = ($Game.Title -replace '[^A-Za-z0-9]', '_')
        return (Join-Path $script:scriptDir (Join-Path $modFolder ".installed_path_$safe"))
    }
    # GZDoom family (Doom / Doom 2 / Heretic / Hexen / Strife): their catalog
    # Bat folder is per-game (DoomVR, HereticVR, ...), but the actual installer
    # is the SHARED QuestZDoomShared, which writes its marker to
    # QuestZDoomShared\.installed_path_<title>. Without this the Hub looked in
    # the wrong folder and the tile never flipped to VR Ready after install.
    if ($modFolder -imatch '^(DoomVR|Doom2VR|HereticVR|HexenVR|StrifeVR)$') {
        $safe = ($Game.Title -replace '[^A-Za-z0-9]', '_')
        return (Join-Path $script:scriptDir (Join-Path 'QuestZDoomShared' ".installed_path_$safe"))
    }
    return (Join-Path $script:scriptDir (Join-Path $modFolder ".installed_path"))
}

# Read the recorded install path. Returns $null if file missing, empty,
# or pointing to a folder that no longer exists.
function Read-InstalledPath {
    param($Game)
    $path = Get-InstalledPathFile -Game $Game
    if (-not $path -or -not (Test-Path $path)) { return $null }
    $v = (Get-Content $path -Raw -ErrorAction SilentlyContinue)
    if ($null -eq $v) { return $null }
    $v = $v.Trim()
    if ([string]::IsNullOrWhiteSpace($v)) { return $null }
    if (-not (Test-Path $v)) { return $null }
    return $v
}

# WO LIEGT DER DEPOT-BUILD WIRKLICH?
# Das Katalogfeld DepotPath ist ein FESTER Vorschlag (C:\Games\<Spiel> VR),
# aber der Installer laesst den Nutzer den Ordner frei waehlen - und
# schreibt den gewaehlten in .installed_path. Wer woanders installiert,
# war fuer den Hub bisher unsichtbar: sowohl der Start-Depot-Knopf als
# auch die Erkennung des geteilten Buttons sahen nur im Katalogpfad nach.
# Also beide Quellen befragen, den Katalogpfad zuerst.
# Der aufgezeichnete Pfad zaehlt NUR, wenn er nicht unter steamapps\common
# liegt - dort steht die normale Steam-Kopie, und die ist der andere Teil
# eines DualMode-Eintrags, nicht der Depot-Build.
function Get-DepotCandidatePaths {
    param($Game)
    $out = @()
    if ($Game.DepotPath) { $out += [string]$Game.DepotPath }
    try {
        $rec = Read-InstalledPath -Game $Game
        # Trennzeichen-unabhaengig, damit die Pruefung nicht an einem
        # Schraegstrich vorbeilaeuft.
        if ($rec -and ($rec -notmatch '(?i)steamapps[\\/]+common') -and ($out -notcontains $rec)) { $out += $rec }
    } catch {}
    return $out
}

# The "Locate Game" exe-picker can record the exact exe that launches
# a user-located install (e.g. a differently named exe from another
# store). Stored next to .installed_path as .launch_exe, holding the
# full exe path. Start-GameInVR prefers it over everything else.
function Get-LaunchOverrideFile {
    param($Game)
    $base = Get-InstalledPathFile -Game $Game
    if (-not $base) { return $null }
    return ($base -replace [regex]::Escape('.installed_path'), '.launch_exe')
}

function Read-LaunchOverride {
    param($Game)
    $p = Get-LaunchOverrideFile -Game $Game
    if (-not $p -or -not (Test-Path $p)) { return $null }
    $v = (Get-Content $p -Raw -ErrorAction SilentlyContinue)
    if ($null -eq $v) { return $null }
    $v = $v.Trim()
    if ([string]::IsNullOrWhiteSpace($v)) { return $null }
    if (-not (Test-Path $v)) { return $null }
    return $v
}

# Marker written by "Locate Game" so the detail page knows this entry
# was located by the user (not by an installer / Steam). Lets us swap
# the one-shot "Locate Game" button for "Re-locate Game" + "Clear" so
# user mistakes (wrong folder / wrong exe) stay correctable.
function Get-UserLocatedFile {
    param($Game)
    $base = Get-InstalledPathFile -Game $Game
    if (-not $base) { return $null }
    return ($base -replace [regex]::Escape('.installed_path'), '.user_located')
}

# ============================================================
#  WHERE THE INSTALLED VERSION IS RECORDED
# ============================================================
# The tracked version used to live ONLY in the Hub's own folder
# (Core\<Game>\.installed_version). That is a bad place for it: the
# Hub is a thing people replace. The built-in updater is careful
# (robocopy, no /MIR, .installed_version in /XF), but anyone who
# unpacks a fresh Hub over a new folder - or moves to another PC,
# or reinstalls the Hub by hand - loses every marker at once. The
# next scan then finds no version, SEEDS it with whatever is current
# online, and every outdated mod silently counts as up to date. No
# Update badge, ever, and nothing looks broken.
#
# So the marker now lives WITH THE MOD, in the game folder, under one
# name for every game. That file survives any Hub replacement, and it
# is the same fact the Hub needs: which build is on this disk. The
# Hub-local copy is still written as a mirror, so nothing that reads
# it directly breaks, and it still answers when a game folder is not
# resolvable at that moment.
#
# Reading order is deliberate: game folder first, Hub folder second.
# The game folder is the ground truth; the Hub copy is a cache.
# Path of the in-game marker. $Second is the B slot for entries that
# track TWO mods in one tile (BioShock), mirroring the Hub-local
# .installed_version / _b pair.
#
# THE NAME IS A LITERAL IN HERE, deliberately. An earlier draft read it
# from a $global set at module load. When that global was empty for any
# reason the name became "", Join-Path handed back THE GAME FOLDER
# ITSELF - and back then this path was handed to a delete. The literal
# cannot be unset, and the guard below refuses any result that is not
# strictly below $GameDir. Nothing in this file deletes any more (see
# Reset-InstalledVersion), so that class of accident is gone at the
# root rather than merely guarded against.
# InstallerSafety.ps1 carries the same literal for Write-ModStamp,
# because installers run in their own process and never load this file.
# The two must stay in step.
function Get-GameStampPath {
    param([string]$GameDir, [switch]$Second)
    if ([string]::IsNullOrWhiteSpace($GameDir)) { return $null }
    $n = ".pcvrhub_version"
    if ($Second) { $n = "$n" + "_b" }
    $full = Join-Path $GameDir $n
    # Never hand back the folder itself.
    if ([string]::IsNullOrWhiteSpace($full)) { return $null }
    if ((Split-Path -Leaf $full) -notlike ".pcvrhub_version*") { return $null }
    return $full
}

function Read-VersionStampFile {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        # -Raw returns $null for an EMPTY file, and $null -replace yields an
        # ARRAY - .Trim() on that throws. Cast first, or an empty marker
        # silently kills the whole check.
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        $v = ([string]$raw -replace '[^\x20-\x7E]', '').Trim()
        if ([string]::IsNullOrWhiteSpace($v)) { return $null }
        return $v
    } catch { return $null }
}

# Read installed version for a game. Game folder wins over the Hub copy.
# Returns $null if neither has a usable value.
function Read-InstalledVersion {
    param($Game, [string]$GameDir)
    $stamp = Get-GameStampPath -GameDir $GameDir
    $v = Read-VersionStampFile -Path $stamp
    if ($v) { return $v }
    return (Read-VersionStampFile -Path (Get-InstalledVersionPath -Game $Game))
}

# Write installed version for a game - into the game folder AND the Hub
# copy. Passing no $GameDir keeps the old behaviour (Hub copy only), so
# a caller that has not resolved a folder yet still works.
function Write-InstalledVersion {
    param($Game, [string]$Version, [string]$GameDir)
    if ([string]::IsNullOrWhiteSpace($Version)) { return }
    $val = $Version.Trim()
    $enc = New-Object System.Text.UTF8Encoding $false
    foreach ($target in @(
        (Get-GameStampPath -GameDir $GameDir),
        (Get-InstalledVersionPath -Game $Game)
    )) {
        if (-not $target) { continue }
        # NICHT SCHREIBEN, WENN SCHON DASSELBE DRINSTEHT. Einer der
        # Aufrufer im Scan meldet "ist aktuell" und schreibt dabei
        # denselben Wert - ohne diese Bremse wuerde bei jedem Scan eine
        # Datei im SPIELORDNER neu geschrieben, nur um sich selbst zu
        # bestaetigen. Im eingeschwungenen Zustand faellt jetzt gar kein
        # Schreibvorgang mehr an.
        $same = $false
        try {
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                $cur = Get-Content -LiteralPath $target -Raw -ErrorAction Stop
                if ((([string]$cur -replace '[^\x20-\x7E]', '').Trim()) -eq $val) { $same = $true }
            }
        } catch {}
        if ($same) { continue }
        try { [System.IO.File]::WriteAllText($target, $val, $enc) } catch {}
    }
}

# Second tracked version, for entries that carry TWO independent mods in
# one catalog tile (BioShock: balouza and BioVRDev). Same folder, distinct
# file, so each mod's release can be tracked on its own.
function Get-InstalledVersionPathB {
    param($Game)
    $p = Get-InstalledVersionPath -Game $Game
    if (-not $p) { return $null }
    return ($p + "_b")
}

# Remove installed version file (used when user clicks Update). The second
# marker goes with it - otherwise a two-mod entry would keep a stale
# version for mod B and show Update forever after an install.
# Mark the tracked version as UNKNOWN after a completed (re)install, so
# the next scan fills it in with whatever is current online.
#
# THIS DOES NOT DELETE ANYTHING, ON PURPOSE. It used to, and that was
# wrong twice over. First, a delete is a bigger operation than the job
# needs: the job is "this value is stale", and emptying a file says that
# just as well. Second, a delete is the one operation whose blast radius
# depends entirely on the path being right - get the path wrong by one
# empty string and you are removing a directory instead of a marker.
# Overwriting cannot do that: the worst a wrong path can do here is
# create or blank a stray 0-byte file, which the next scan overwrites.
#
# An empty marker reads back as $null (see Read-VersionStampFile), which
# is exactly the "no version recorded" state the scan already handles.
# Files that do not exist are left alone - no new files are created.
function Reset-InstalledVersion {
    param($Game, [string]$GameDir)
    $enc = New-Object System.Text.UTF8Encoding $false
    foreach ($path in @(
        (Get-InstalledVersionPath  -Game $Game),
        (Get-InstalledVersionPathB -Game $Game),
        (Get-GameStampPath -GameDir $GameDir),
        (Get-GameStampPath -GameDir $GameDir -Second)
    )) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            try { [System.IO.File]::WriteAllText($path, "", $enc) } catch {}
        }
    }
}

# Path to the per-game ".update_ok" marker the installer wrapper drops
# next to .installed_version when its core ran to completion. A cancel
# inside the core calls 'exit' first, so the marker is absent on cancel.
function Get-UpdateOkMarkerPath {
    param($Game)
    $vp = Get-InstalledVersionPath -Game $Game
    if (-not $vp) { return $null }
    return (Join-Path (Split-Path -Parent $vp) ".update_ok")
}

# Clear a stale completion marker before launching an update installer,
# so only a freshly completed run can clear the tracked version.
# This one stays a delete: it is a PRESENCE flag - "the installer core
# finished" - and a flag you cannot remove is not a flag. It lives in the
# Hub's own Core\<Game>\ folder under a fixed literal name, so no path
# here can ever point at user data. -PathType Leaf all the same.
function Clear-UpdateOkMarker {
    param($Game)
    $mk = Get-UpdateOkMarkerPath -Game $Game
    if ($mk -and (Test-Path -LiteralPath $mk -PathType Leaf)) {
        Remove-Item -LiteralPath $mk -Force -ErrorAction SilentlyContinue
    }
}

# -------------------------------------------------------
# Module loader. The Hub used to live in a single 10k-line
# VRModHub.ps1; it is now split into focused modules under
# .\Modules\. Order matters - each module assumes the prior
# ones have already defined their helpers, $window, globals
# etc. Do not reorder without checking dependencies.
# -------------------------------------------------------
# HIER, VOR DEM LADEN DER MODULE. Startup.ps1 ist das LETZTE Modul in
# der Schleife unten und ruft darin $window.ShowDialog() auf - alles,
# was NACH der Schleife steht, laeuft erst beim Schliessen des Fensters.
# Die Reparatur muss vor dem ersten Scan greifen, also vor die Schleife.
# -------------------------------------------------------
#  EINMALIGE REPARATUR: falscher Versionsmarker fuer BotW
#  WEGWERFCODE - EINGEBAUT 2026-08-10, RAUS AB HUB 0.8.6.x
# -------------------------------------------------------
# EIN ausgeliefertes Bundle enthielt versehentlich
# Core\BreathOfTheWildVR\.installed_version mit dem Inhalt "1.0" -
# hineingeschrieben beim Bauen, nicht von einer Installation. Der Scan
# vergleicht diesen Wert gegen den GitHub-Tag von BetterVR (0.9.x) und
# zeigt deshalb dauerhaft eine Update-Kachel, die nicht verschwindet.
#
# WARUM EIN NEUES BUNDLE ALLEIN NICHT REICHT: der Updater kopiert mit
# robocopy und hat .installed_version in der Ausschlussliste (/XF), damit
# echte Nutzerdaten ueberleben. Die falsche Datei bleibt also auch nach
# einem Hub-Update liegen und muss aktiv geleert werden.
#
# ES BLEIBT NICHTS ZURUECK. Kein Merker, keine neue Datei im Hub-Ordner:
# der Block braucht keinen, weil er sich SELBST entwaffnet. Nach dem
# Leeren steht dort nicht mehr "1.0", und der naechste Scan schreibt den
# echten Tag hinein - die Bedingung trifft also nie wieder zu. Ein
# frueherer Entwurf legte dafuer .repair_botw_marker an; das war
# unnoetiger Muell in einem Ordner, aus dem Updates nie etwas entfernen.
#
# GELEERT, NICHT GELOESCHT, und nur bei genau diesem Inhalt.
# HIER, VOR DEM LADEN DER MODULE: Startup.ps1 ist das LETZTE Modul in der
# Schleife unten und ruft darin $window.ShowDialog() auf - alles, was
# NACH der Schleife steht, laeuft erst beim Schliessen des Fensters.
try {
    $badMarker = Join-Path $scriptDir "BreathOfTheWildVR\.installed_version"
    if (Test-Path -LiteralPath $badMarker -PathType Leaf) {
        # -ErrorAction Stop, NICHT SilentlyContinue: ein fehlgeschlagenes
        # LESEN (Datei gesperrt, Virenscanner, Rechte) darf nicht als
        # "Inhalt ist nicht 1.0" durchgehen. Es landet im catch, und der
        # naechste Start versucht es erneut.
        $cur = Get-Content -LiteralPath $badMarker -Raw -ErrorAction Stop
        if ((([string]$cur -replace '[^\x20-\x7E]', '').Trim()) -eq "1.0") {
            [System.IO.File]::WriteAllText($badMarker, "", (New-Object System.Text.UTF8Encoding $false))
        }
    }
} catch {}

$modulesDir = Join-Path $scriptDir "Modules"
foreach ($mod in @(
    "Catalog.ps1",
    "BannerColors.ps1",
    "Helpers.ps1",
    "CardTile.ps1",
    "Window.ps1",
    "ScanSpinner.ps1",
    "DiscoverInit.ps1",
    "DetailView.ps1",
    "OverviewPage.ps1",
    "BannerOvFilters.ps1",
    "Filter.ps1",
    "Startup.ps1"
)) {
    . (Join-Path $modulesDir $mod)
    Write-HubTiming ("module loaded: {0}" -f $mod)
}
