# ============================================================
# Ready Or Not VR Installer
# Layers the free "Ready Or Not VRO Mod" (Virtual Reality Oasis
# & KITT) onto a copy of Ready Or Not. We ship ZERO game files.
# The mod is gated behind a Nexus Mods login, so it cannot be
# fetched automatically - the user downloads the file from Nexus
# and drags it in, and we drop the .pak into the game's Paks
# folder.
#
# TWO INSTALL TARGETS (DualMode, same pattern as Risk of Rain 2,
# Bendy and REPO):
#   [1] The Steam copy the user already owns - unchanged path.
#   [2] A SEPARATE build pulled from a pinned Steam depot into
#       C:\Games\Ready or Not VR, with a desktop shortcut.
#
# WHY THE DEPOT COPY IS DIFFERENT IN ONE IMPORTANT WAY: it lives
# outside the Steam library, so Steam's launch-options field and
# its DirectX dropdown do NOT apply to it. Everything Steam
# would have passed has to ride on the shortcut instead:
#   -dx11              <- what Steam's "DirectX 11" entry does
#   -usehmd -VRTweaks -VRMappings   <- what the mod needs
# The depot manifest is PINNED, so this build never auto-updates
# and the mod cannot be broken by a game patch. That pinned build
# is the CURRENT one, on Martin's call - it runs, so we build on it.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Ready Or Not VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME    = "Ready Or Not"
$GAME_EXE     = "ReadyOrNot.exe"
$STEAM_FOLDER = "Ready Or Not"
$PAKS_SUBDIR  = "ReadyOrNot\Content\Paks"
$PAK_NAME     = "pakchunk98-VR_OR_NOT_P.pak"
# Nur noch der Stamm des Namens - die vollstaendige Datei heisst bei
# jedem anders, weil Nexus Zaehler und Zufallskennung anhaengt. Nirgends
# mehr als "so heisst deine Datei" ausgeben; erkannt wird ueber Groesse
# und Inhalt (Find-RonModDownload / Test-RonModArchive).
$ZIP_NAME     = "pakchunk98-VR_OR_NOT_P ... .zip"
$APP_ID       = "1144200"
$NEXUS_URL    = "https://www.nexusmods.com/readyornot/mods/6914"
$NEXUS_FILES_URL = "$NEXUS_URL`?tab=files"
$DLSS_URL     = "https://github.com/beeradmoore/dlss-swapper/releases"
$DISCORD_URL  = "https://discord.gg/7wHGztfgjM"
$LAUNCH_OPTS  = "-usehmd -VRTweaks -VRMappings"
$LAUNCH_OPTS_AUTOVR = "$LAUNCH_OPTS -autoVR"

# ---- Depot build (install target [2]) ----------------------
# Pinned depot. Steam drops it into
# steamapps\content\app_<appid>\depot_<depotid>, which a later
# depot download would overwrite - so it gets MOVED to a stable
# folder of its own, away from the Steam library and out of any
# "Program Files" UAC territory.
$DEPOT_APPID    = "1144200"
$DEPOT_DEPOTID  = "1144201"
$DEPOT_MANIFEST = "6744259790683578909"
$DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"
$DEPOT_DEFAULT_PARENT = "C:\Games"
$DEPOT_TARGET_NAME    = "Ready or Not VR"
$DEPOT_DEFAULT_PATH   = Join-Path $DEPOT_DEFAULT_PARENT $DEPOT_TARGET_NAME
# Steam's DirectX 11 entry as a plain switch - the depot copy has
# no Steam dropdown to select it from.
$DX11_OPT             = "-dx11"
$DEPOT_LAUNCH_OPTS    = "$DX11_OPT $LAUNCH_OPTS"
$DEPOT_LAUNCH_AUTOVR  = "$DX11_OPT $LAUNCH_OPTS_AUTOVR"
$DEPOT_SHORTCUT_NAME  = "Ready or Not VR"

# The exact Nexus file people need. Nexus has no version API, so
# this is the only way to point at it - by date, size and version,
# which is what the Files page shows.
# Read from the real archive: the download is 281.9 MB and holds exactly
# one file, pakchunk98-VR_OR_NOT_P.pak, 299,048,886 bytes, built
# 2026-06-15 13:10. That build time is what the catalog carries as
# ModBuildStamp. Version 1031 is the CURRENT file - there is no 1016 on
# the page, not even under older versions.
# Kennzahlen der RICHTIGEN Datei, aus dem echten Archiv gelesen. Der
# Dateiname taugt NICHT zur Pruefung - Nexus haengt Zaehler und Zeit an
# ("pakchunk98-VR_OR_NOT_P 6914 1031 2026-06-15T10-17Z AHhotnRjo.zip"),
# und ein aehnlich benanntes Archiv aus dem Downloads-Ordner sieht genauso
# aus. Geprueft wird deshalb der INHALT: genau eine .pak mit diesem Namen
# und dieser Groesse.
$PAK_SIZE_1031    = 299048886
$MOD_ZIP_SIZE     = 295601160   # das Nexus-Zip selbst, Version 1031
$MOD_FILE_DATE    = "15 June 2026"
$MOD_FILE_SIZE    = "281.9 MB"
$MOD_FILE_VERSION = "1031"
# DLSS Swapper wird zur LAUFZEIT aufgeloest, nicht festgenagelt: Get-
# DlssSwapperUrl fragt die GitHub-API nach dem neuesten Release und
# nimmt den passenden Anhang. Die beiden Werte hier sind nur der
# Rueckfall, wenn die API nicht erreichbar oder rate-limited ist - sie
# muessen trotzdem mitgezogen werden, sonst laedt ein Rechner ohne
# API-Zugang etwas Altes.
$DLSS_PINNED_TAG    = "v1.2.5.0"
$DLSS_PINNED_VER    = "1.2.5.0"
$DLSS_INSTALLER_URL = "https://github.com/beeradmoore/dlss-swapper/releases/download/$DLSS_PINNED_TAG/DLSS.Swapper-$DLSS_PINNED_VER-installer.exe"
$DLSS_PORTABLE_URL  = "https://github.com/beeradmoore/dlss-swapper/releases/download/$DLSS_PINNED_TAG/DLSS.Swapper-$DLSS_PINNED_VER-portable.zip"
$TOOLS_DIR          = Join-Path $PSScriptRoot "..\Assets\Tools"
$DLSS_PORTABLE_DIR  = Join-Path $TOOLS_DIR "DLSS Swapper"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host " Ready Or Not VR Installer" -ForegroundColor Cyan
    Write-Host " Installs: VRO Mod by Virtual Reality Oasis & KITT" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}
function Write-Step { param($n,$t,$txt) Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [XX] $t" -ForegroundColor Red }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# Auto-detect the Steam copy of Ready Or Not across every Steam
# library (registry -> libraryfolders.vdf). Returns the game root
# (the folder holding ReadyOrNot.exe) or $null.
function Find-SteamRon {
    $steam = $null
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if ($p -and (Test-Path $p)) { $steam = $p; break } } catch {}
    }
    if (-not $steam) { return $null }
    $libs = @($steam)
    $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        try {
            foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $p = $m.Groups[1].Value -replace '\\\\', '\'
                if (Test-Path $p) { $libs += $p }
            }
        } catch {}
    }
    foreach ($lib in ($libs | Select-Object -Unique)) {
        $cand = Join-Path $lib "steamapps\common\$STEAM_FOLDER"
        if (Test-Path (Join-Path $cand $GAME_EXE)) { return $cand }
    }
    return $null
}

# Drag the Ready Or Not folder or ReadyOrNot.exe; resolve the game
# root (the folder containing ReadyOrNot.exe). Loops until valid or
# cancelled (empty input).
function Get-RonFolder {
    while ($true) {
        Write-Host ""
        Write-Host " Drag your Ready Or Not folder (or ReadyOrNot.exe) onto" -ForegroundColor White
        Write-Host " this window and press Enter." -ForegroundColor White
        Write-Host " (You can also type or paste the full path.)" -ForegroundColor Gray
        Write-Host " Leave empty and press Enter to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " Path"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path $p)) { Write-Warn "Path not found: $p"; continue }
        if (Test-Path $p -PathType Container) {
            if (Test-Path (Join-Path $p $GAME_EXE)) { return $p }
            Write-Warn "No $GAME_EXE in that folder. Drag the folder that contains it."
            continue
        }
        $dir = Split-Path -Parent $p
        if (Test-Path (Join-Path $dir $GAME_EXE)) { return $dir }
        Write-Warn "That file is not next to $GAME_EXE. Drag the Ready Or Not folder or $GAME_EXE."
    }
}

# Drag a downloaded file here. Accepts the listed extensions. Loops
# until a valid file is given or the user leaves it empty (skip).
function Get-DroppedFile {
    param([string]$Label, [string[]]$Exts)
    while ($true) {
        Write-Host ""
        Write-Host " Drag the downloaded $Label onto this window and press Enter," -ForegroundColor Yellow
        Write-Host " or leave empty to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " File"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path $p -PathType Leaf)) { Write-Warn "File not found: $p"; continue }
        $ext = [System.IO.Path]::GetExtension($p).ToLower()
        if ($Exts -and ($Exts -notcontains $ext)) {
            Write-Warn "That is a '$ext' file. Expected one of: $($Exts -join ', ')."
            continue
        }
        return $p
    }
}

# Neueste DLSS-Swapper-Datei von GitHub holen. $Kind ist "installer"
# oder "portable"; gesucht wird im neuesten Release der Anhang, dessen
# Name darauf endet. Kommt die API nicht durch, gibt die Funktion $null
# zurueck und der Aufrufer nimmt die gepinnte URL.
function Get-DlssSwapperUrl {
    param([ValidateSet("installer","portable")][string]$Kind)
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/beeradmoore/dlss-swapper/releases/latest" `
                 -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20
        $suffix = if ($Kind -eq "installer") { "-installer.exe" } else { "-portable.zip" }
        foreach ($a in $rel.assets) {
            if (($a.name -like "*DLSS*Swapper*") -and ($a.name -like "*$suffix")) {
                return @{ Url = [string]$a.browser_download_url; Name = [string]$a.name; Tag = [string]$rel.tag_name }
            }
        }
    } catch {}
    return $null
}

# Die Mod im Downloads- oder Desktop-Ordner finden, OHNE sich auf den
# Dateinamen zu verlassen: Nexus haengt Zaehler und Zufallskennung an
# ("pakchunk98-VR_OR_NOT_P 6914 1031 2026-06-15T10-17Z AHhotnRjo.zip").
# Zuerst die exakte Dateigroesse, dann Namensbruchstuecke - und jeder
# Kandidat wird anschliessend am INHALT geprueft.
function Find-RonModDownload {
    $folders = @()
    foreach ($f in @(
        (Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"),
        ([Environment]::GetFolderPath("Desktop"))
    )) { if ($f -and (Test-Path -LiteralPath $f)) { $folders += $f } }
    if ($folders.Count -eq 0) { return $null }

    $cands = @()
    foreach ($dir in $folders) {
        try {
            $cands += Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
                      Where-Object { $_.Extension -imatch '^\.(zip|pak)$' }
        } catch {}
    }
    if ($cands.Count -eq 0) { return $null }

    # Reihenfolge: exakte Groesse zuerst, dann Name, dann der Rest der Zips.
    $ranked = @()
    $ranked += $cands | Where-Object { $_.Length -eq $MOD_ZIP_SIZE -or $_.Length -eq $PAK_SIZE_1031 }
    $ranked += $cands | Where-Object { $_.Name -imatch 'VR_OR_NOT' -and $ranked -notcontains $_ }
    $ranked += $cands | Where-Object { $_.Name -imatch 'pakchunk98' -and $ranked -notcontains $_ }
    $ranked = $ranked | Select-Object -Unique

    foreach ($c in $ranked) {
        if ($c.Extension -ieq ".pak") {
            if (($c.Name -ieq $PAK_NAME) -and ($c.Length -eq $PAK_SIZE_1031)) {
                return @{ Path = $c.FullName; Verdict = "ok" }
            }
            continue
        }
        $v = Test-RonModArchive -Path $c.FullName
        if ($v -eq "ok")    { return @{ Path = $c.FullName; Verdict = "ok" } }
        if ($v -eq "other") { return @{ Path = $c.FullName; Verdict = "other" } }
    }
    return $null
}

# Ist das WIRKLICH die Mod-Datei? Geprueft wird der Inhalt, nicht der
# Name. Rueckgabe: "ok" (Name und Groesse stimmen), "other" (die pak ist
# drin, aber eine andere Groesse - anderer Build), "no" (keine passende
# pak im Archiv) oder "unknown" (Archiv nicht lesbar).
function Test-RonModArchive {
    param([string]$Path)
    try {
        $top = Get-ArchiveTopLevel -ArchivePath $Path
        if (-not $top.Ok) { return "unknown" }
        $hit = $null
        foreach ($e in $top.Entries) {
            if ((Split-Path -Leaf ([string]$e)) -ieq $PAK_NAME) { $hit = $e; break }
        }
        if (-not $hit) { return "no" }
    } catch { return "unknown" }
    # Groesse der pak IM Archiv lesen - nur .zip, alles andere bleibt
    # bei der Namenspruefung oben.
    if ($Path -match '(?i)\.zip$') {
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
            $za = [System.IO.Compression.ZipFile]::OpenRead($Path)
            try {
                foreach ($en in $za.Entries) {
                    if ($en.Name -ieq $PAK_NAME) {
                        if ($en.Length -eq $PAK_SIZE_1031) { return "ok" } else { return "other" }
                    }
                }
            } finally { $za.Dispose() }
        } catch { return "unknown" }
    }
    return "ok"
}

# Simple Y/N gate. Loops until the user types Y or N.
function Read-YesNo {
    param([string]$Prompt)
    while ($true) {
        Write-Host ""
        $a = (Read-Host " $Prompt [Y/N]").Trim().ToUpper()
        if ($a -eq "Y" -or $a -eq "YES") { return $true }
        if ($a -eq "N" -or $a -eq "NO")  { return $false }
        Write-Warn "Please type Y or N."
    }
}

# Two-way choice. Loops until the user types 1 or 2.
function Read-OneTwo {
    param([string]$Prompt)
    while ($true) {
        Write-Host ""
        $a = (Read-Host " $Prompt [1/2]").Trim()
        if ($a -eq "1") { return 1 }
        if ($a -eq "2") { return 2 }
        Write-Warn "Please type 1 or 2."
    }
}

# Best-effort check whether DLSS Swapper is already present. Returns
# "portable" / "installed" / $null. Used to skip a needless download.
function Test-DlssSwapperInstalled {
    if (Test-Path -LiteralPath "$DLSS_PORTABLE_DIR\DLSS Swapper.exe") { return "portable" }
    $cands = @(
        (Join-Path $env:LOCALAPPDATA "Programs\DLSS Swapper\DLSS Swapper.exe"),
        (Join-Path $env:LOCALAPPDATA "DLSS Swapper\DLSS Swapper.exe"),
        "C:\Program Files\DLSS Swapper\DLSS Swapper.exe",
        "C:\Program Files (x86)\DLSS Swapper\DLSS Swapper.exe",
        (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\DLSS Swapper.lnk"),
        (Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\DLSS Swapper\DLSS Swapper.lnk"),
        (Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\DLSS Swapper.lnk")
    )
    foreach ($c in $cands) { try { if (Test-Path $c) { return "installed" } } catch {} }
    return $null
}

# Create a desktop shortcut. Returns the .lnk path or $null on failure.

Write-Header

# ---- Which copy are we modding? ----
Write-Host " Ready Or Not VR can go into one of two places:" -ForegroundColor White
Write-Host ""
Write-Host "  [1] The Steam copy you already own." -ForegroundColor White
Write-Host "      Keeps everything in one install. The mod is switched on" -ForegroundColor Gray
Write-Host "      and off through Steam's launch options." -ForegroundColor Gray
Write-Host ""
Write-Host "  [2] A separate build from a pinned Steam depot." -ForegroundColor White
Write-Host "      Lands in $DEPOT_DEFAULT_PATH or a folder of your" -ForegroundColor Gray
Write-Host "      choice, with its own desktop shortcut. Leaves your Steam" -ForegroundColor Gray
Write-Host "      copy untouched, and cannot be changed by a game patch -" -ForegroundColor Gray
Write-Host "      the version is pinned." -ForegroundColor Gray
Write-Host ""
$installMode = Read-OneTwo "Choose 1 or 2"
$isDepot = ($installMode -eq 2)

# One step counter for both routes - the depot route has one step
# more, and hard-coded numbers would drift the moment either changes.
$STEP_TOTAL = if ($isDepot) { 6 } else { 5 }
$script:stepN = 0
function Next-Step { param([string]$Text) $script:stepN++; Write-Step $script:stepN $STEP_TOTAL $Text }

$gameDir = $null

if ($isDepot) {
    # ---- Depot route: pull the pinned build, then park it ----
    Next-Step "Downloading the pinned build from Steam"
    Write-Host "  Steam downloads one exact version of Ready Or Not for you." -ForegroundColor White
    Write-Host "  The Steam Console opens next; what to do there comes right after." -ForegroundColor White
    Write-Host ""
    $clipDepot = $false
    try { Set-Clipboard -Value $DEPOT_COMMAND; $clipDepot = $true } catch {}
    if ($clipDepot) { Write-OK "Command copied to your clipboard." } else { Write-Warn "Could not copy to the clipboard - the command is printed below." }
    if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "  (i) Virtual Desktop users: the Steam Console may not open" -ForegroundColor DarkGray
        Write-Host "      from inside a streaming session. If it does not, use" -ForegroundColor DarkGray
        Write-Host "      Steam's menu bar - View - Console." -ForegroundColor DarkGray
    }
    Pause-User "Press Enter to open the Steam Console..."

    # STEAM MUSS LAUFEN, sonst verschluckt der Protokoll-Handler die
    # Navigation: er startet Steam und die Konsole erscheint nie. Also
    # erst pruefen, notfalls Steam starten und ihm Zeit lassen.
    # steam.exe IMMER aufloesen, nicht nur wenn Steam gerade aus ist -
    # der Hinweis unten braucht den vollen Pfad in jedem Fall.
    $steamExe = $null
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try {
            $sp2 = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
            if ($sp2) { $c = Join-Path $sp2 "steam.exe"; if (Test-Path -LiteralPath $c) { $steamExe = $c; break } }
        } catch {}
    }
    $steamRunning = $false
    try { $steamRunning = [bool](Get-Process -Name "steam" -ErrorAction SilentlyContinue) } catch {}
    if (-not $steamRunning) {
        Write-Info "Steam is not running - starting it first."
        if ($steamExe) { try { Start-Process -FilePath $steamExe } catch {} }
        for ($i = 0; $i -lt 20; $i++) {
            Start-Sleep -Seconds 1
            try { if (Get-Process -Name "steam" -ErrorAction SilentlyContinue) { break } } catch {}
        }
        Start-Sleep -Seconds 3
    }

    # Zwei Protokoll-Adressen, weil je nach Client-Version nur eine
    # zieht: open/console ist die aeltere, nav/console die neuere.
    foreach ($u in @("steam://open/console", "steam://nav/console")) {
        try { Start-Process $u; Start-Sleep -Milliseconds 900 } catch {}
    }

    Write-Host ""
    Write-Host "  The command is on your clipboard - click into the console," -NoNewline -ForegroundColor White
    Write-Host ""
    Write-Host "  paste with " -NoNewline -ForegroundColor White
    Write-Host " Ctrl+V " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " and press " -NoNewline -ForegroundColor White
    Write-Host " Enter " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Write-Host "  It is about 40 GB, so it can take a while. Steam finishes with" -ForegroundColor White
    Write-Host "  this line - then come back here:" -ForegroundColor White
    Write-Host "    Depot download complete : ...\depot_$DEPOT_DEPOTID " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    # Nur fuer den Fall, dass die Zwischenablage nicht ging - deshalb grau
    # und unmarkiert. Beim normalen Weg tippt das niemand ab.
    Write-Host "  If the clipboard did not work, the command reads:" -ForegroundColor DarkGray
    Write-Host "    $DEPOT_COMMAND" -ForegroundColor DarkGray
    Write-Host ""
    # AB HIER NUR NOCH RUECKFALL - durchgehend DarkGray und ohne
    # Hervorhebung, damit es nicht wie eine Aufgabe aussieht. Es hat nur
    # Bedeutung, wenn die Konsole nicht aufgegangen ist.
    Write-Host "  If no console window opened:" -ForegroundColor DarkGray
    Write-Host "    Steam menu bar: View - Console. If there is no Console entry," -ForegroundColor DarkGray
    Write-Host "    close Steam and start it once with the -console switch:" -ForegroundColor DarkGray
    if ($steamExe -and (Test-Path -LiteralPath $steamExe)) {
        Write-Host "      \"$steamExe\" -console" -ForegroundColor DarkGray
    } else {
        Write-Host "      steam.exe -console" -ForegroundColor DarkGray
    }
    Write-Host "    Or skip the console: press Enter, say the folder was not" -ForegroundColor DarkGray
    Write-Host "    found, and the next step offers DepotDownloader instead." -ForegroundColor DarkGray
    Write-Host ""
    Pause-User "Press Enter once the depot download has finished..."

    # Where Steam put it. Registry first, then the shared resolver
    # (which also offers the DepotDownloader fallback).
    $steamInstallPath = $null
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if ($p -and (Test-Path $p)) { $steamInstallPath = $p; break } } catch {}
    }
    $depotPath = $null
    if ($steamInstallPath) {
        $autoPath = Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID"
        Write-Info "Expected depot folder: $autoPath"
        if (Test-Path $autoPath) { $depotPath = $autoPath; Write-OK "Depot folder found." }
        else { Write-Warn "Not at the expected location - the download may still be running." }
    } else {
        Write-Warn "Could not read the Steam path from the registry."
    }
    if (-not $depotPath) {
        $probe = @()
        if ($steamInstallPath) { $probe += (Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID") }
        $depotPath = Resolve-DepotPath -GameName $GAME_NAME -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probe -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
    }
    if (-not $depotPath) { Write-Fail "No depot folder - cannot continue."; Pause-User "Press Enter to exit..."; exit 1 }
    if (-not (Test-Path (Join-Path $depotPath $GAME_EXE))) {
        Write-Warn "$GAME_EXE is not in $depotPath - that may be the wrong folder."
    }

    # ---- Park it somewhere Steam will not overwrite ----
    Next-Step "Moving the build to $DEPOT_TARGET_NAME"
    # SAME WORDING AS EVERY OTHER DEPOT INSTALLER (Risk of Rain 2,
    # Ultrakill, Tormented Souls, PEAK). The user picks the folder; C:\Games
    # is only the recommendation, and the reason for it is spelled out.
    # Do not reword this - it is the one sentence people see across all of
    # them, and the extra reason here (a later depot download would land on
    # top of the old one) is in the comment above, not in the prompt.
    Write-Host "  Default install location: $DEPOT_DEFAULT_PATH" -ForegroundColor Gray
    Write-Host "  (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
    Write-Host "   library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
    Write-Host ""
    $answer = (Read-Host "  Press Enter to use default, or type a different full path").Trim().Trim('"')
    $targetPath = if ($answer) { $answer } else { $DEPOT_DEFAULT_PATH }
    $targetParent = Split-Path $targetPath -Parent
    if ($targetParent -and -not (Test-Path $targetParent)) {
        try { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
        catch { Write-Fail "Could not create $targetParent : $_"; Pause-User "Press Enter to exit..."; exit 1 }
    }
    if (Test-Path $targetPath) {
        Write-Warn "Something is already at $targetPath"
        Write-Host "    [Y] Delete it and carry on" -ForegroundColor White
        Write-Host "    [N] Keep it and stop here" -ForegroundColor Gray
        if (-not (Read-YesNo "Delete the existing folder?")) { Write-Info "Stopped - nothing changed."; Pause-User "Press Enter to exit..."; exit 0 }
        try { Remove-Item $targetPath -Recurse -Force -ErrorAction Stop }
        catch { Write-Fail "Could not delete it: $_"; Pause-User "Press Enter to exit..."; exit 1 }
    }
    try {
        $parentOfDepot = Split-Path $depotPath -Parent
        Move-Item -Path $depotPath -Destination $targetPath -ErrorAction Stop
        Write-OK "Build moved to: $targetPath"
        try {
            if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) { Remove-Item $parentOfDepot -Force }
        } catch {}
    } catch {
        Write-Fail "Move failed: $_"
        Write-Info "The files are still at: $depotPath"
        Pause-User "Press Enter to exit..."
        exit 1
    }
    # Outside the Steam library the game has no app id to read, so it
    # gets one next to the exe - otherwise Steamworks can bounce it
    # back to Steam or refuse to start.
    try { Set-Content -Path (Join-Path $targetPath "steam_appid.txt") -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force; Write-OK "steam_appid.txt written." }
    catch { Write-Warn "Could not write steam_appid.txt - if the game bounces to Steam, create it by hand with: $DEPOT_APPID" }
    # Ein eigener Ordner ist voellig in Ordnung: der Hub liest den
    # gewaehlten Pfad aus .installed_path (Get-DepotCandidatePaths), der
    # Katalogpfad ist nur der Vorschlag. Nichts weiter zu tun.
    $gameDir = $targetPath
} else {

# ---- Locate the Steam copy ----
Next-Step "Locating your Ready Or Not install"
$gameDir = Find-SteamRon
if (-not $gameDir) { $gameDir = Find-SteamGameFolder -AppId "1144200" -SteamFolderNames @("Ready Or Not") }
if ($gameDir) {
    Write-OK "Found via Steam: $gameDir"
} else {
    Write-Warn "Ready Or Not was not found automatically."
    Write-Host "  You need Ready Or Not installed on Steam (app $APP_ID)." -ForegroundColor White
    Write-Host "  Steam store / install:  https://store.steampowered.com/app/$APP_ID/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [O] Open the Steam install page   [P] Enter the game folder manually" -ForegroundColor White
    $pick = ""
    while ($pick -notin @("o","O","p","P")) { $pick = (Read-Host "  Choice (O/P)").Trim() }
    if ($pick -in @("o","O")) {
        try { Start-Process "steam://install/$APP_ID" } catch { try { Start-Process "https://store.steampowered.com/app/$APP_ID/" } catch {} }
        Pause-User "Install Ready Or Not, then press Enter to continue..."
        $gameDir = Find-SteamRon
    }
    if (-not $gameDir) { $gameDir = Get-RonFolder }
}
if (-not $gameDir) { Write-Info "No Ready Or Not folder - cancelled."; Pause-User "Press Enter to exit..."; exit 0 }
Write-OK "Ready Or Not folder: $gameDir"

}


$paksDir = Join-Path $gameDir $PAKS_SUBDIR
if (-not (Test-Path $paksDir)) {
    Write-Warn "Expected Paks folder not found:"
    Write-Host "      $paksDir" -ForegroundColor Gray
    Write-Host "      Creating it - if this is the wrong game folder, cancel and re-run." -ForegroundColor Gray
    try { New-Item -ItemType Directory -Force -Path $paksDir | Out-Null } catch { Write-Warn "Could not create the Paks folder." }
}

# ---- STEP 2: download the mod from Nexus ----
Next-Step "Downloading the VRO Mod from Nexus Mods"
Write-Host "  The mod is behind a free Nexus Mods login, so it cannot be" -ForegroundColor White
Write-Host "  downloaded automatically." -ForegroundColor White
Write-Host ""
Write-Host "  Pressing Enter opens the Files page - no need to copy or click:" -ForegroundColor Yellow
Write-Host "      (  $NEXUS_FILES_URL )" -ForegroundColor Gray
Write-Host ""
Write-Host "  1) Log in to Nexus Mods (free account)." -ForegroundColor White
Write-Host "  2) TAKE THE RIGHT FILE. The Files page lists more than one," -ForegroundColor Yellow
Write-Host "     and only this one matches the build we install:" -ForegroundColor Yellow
Write-Host ""
Write-Host "        Version    $MOD_FILE_VERSION " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        Uploaded   $MOD_FILE_DATE " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "        Size       $MOD_FILE_SIZE " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "     Use MANUAL DOWNLOAD. Nexus adds numbers of its own to the" -ForegroundColor White
Write-Host "     file name, so it arrives looking something like" -ForegroundColor White
Write-Host "        pakchunk98-VR_OR_NOT_P ... .zip" -ForegroundColor Gray
Write-Host "     The trailing numbers differ for everyone - that is normal." -ForegroundColor DarkGray
Write-Host "  3) Come back here. This window picks the file up from your" -ForegroundColor White
Write-Host "     Downloads folder by itself, or you drag it in." -ForegroundColor White
Pause-User "Press Enter to open the download page on Nexus Mods..." -Color Yellow
try { Start-Process $NEXUS_FILES_URL } catch { Write-Warn "Open manually: $NEXUS_FILES_URL" }
# No "downloaded?" pause here on purpose - the Get-DroppedFile prompt
# below already waits for an Enter once the file is dragged in.

# Accept the .zip (preferred) or the .pak directly if the user already
# extracted it. Both are fine.
# ZUERST SELBER SUCHEN. Der Dateiname taugt dafuer nicht, also gehen wir
# ueber die Groesse und pruefen jeden Kandidaten am Inhalt.
$auto = Find-RonModDownload
if ($auto) {
    Write-Host ""
    if ($auto.Verdict -eq "ok") {
        Write-OK "Found it in your Downloads folder:"
        Write-Host "    $(Split-Path -Leaf $auto.Path)" -ForegroundColor Gray
        Write-Host "    Verified: holds $PAK_NAME, version $MOD_FILE_VERSION." -ForegroundColor Gray
    } else {
        Write-Warn "Found a candidate, but it is not the build documented here:"
        Write-Host "    $(Split-Path -Leaf $auto.Path)" -ForegroundColor Gray
        Write-Host "    It holds $PAK_NAME in a different size - fine if the" -ForegroundColor White
        Write-Host "    modder shipped a newer file." -ForegroundColor White
    }
    if (Read-YesNo "Use this file?") { $preFound = $auto.Path } else { $preFound = $null }
} else {
    $preFound = $null
}

while ($true) {
    if ($preFound) { $drop = $preFound; $preFound = $null }
    else {
        $drop = Get-DroppedFile -Label "the Nexus download (pakchunk98-VR_OR_NOT_P ... .zip, or the .pak inside it)" -Exts @(".zip", ".pak")
    }
    if (-not $drop) { Write-Fail "No file provided - cannot install without the mod."; Pause-User "Press Enter to exit..."; exit 1 }

    # Eine losgelassene .pak wird an ihrer Groesse gemessen, ein Archiv an
    # seinem Inhalt. Der Dateiname zaehlt in keinem der beiden Faelle.
    if ([System.IO.Path]::GetExtension($drop).ToLower() -eq ".pak") {
        $pLen = 0
        try { $pLen = (Get-Item -LiteralPath $drop).Length } catch {}
        if ((Split-Path -Leaf $drop) -ine $PAK_NAME) {
            Write-Fail "That is not $PAK_NAME. The VR pak has exactly that name."
            continue
        }
        if ($pLen -ne $PAK_SIZE_1031) {
            Write-Warn "This pak is $pLen bytes; version $MOD_FILE_VERSION has $PAK_SIZE_1031."
            Write-Host "  Either a different build, or an incomplete download." -ForegroundColor White
            if (-not (Read-YesNo "Use it anyway?")) { continue }
        }
        Write-OK "Got the pak: $drop"
        break
    }

    $verdict = Test-RonModArchive -Path $drop
    if ($verdict -eq "ok") { Write-OK "Verified - the archive holds $PAK_NAME, version $MOD_FILE_VERSION."; break }
    if ($verdict -eq "unknown") { Write-Warn "Could not read the archive to check it - continuing."; break }
    if ($verdict -eq "no") {
        Write-Fail "Wrong file: this archive does not contain $PAK_NAME."
        Write-Host "  Nexus download names all look alike, so check what you dragged" -ForegroundColor White
        Write-Host "  in. Needed is the main file from the mod's Files page." -ForegroundColor White
        continue
    }
    # "other" - richtige pak, andere Groesse
    Write-Warn "The archive holds $PAK_NAME, but not the build documented here"
    Write-Host "  (expected $PAK_SIZE_1031 bytes for version $MOD_FILE_VERSION)." -ForegroundColor White
    Write-Host "  That is fine if the modder shipped a newer file." -ForegroundColor White
    if (Read-YesNo "Use it anyway?") { break }
}

# ---- STEP 3: install the .pak into the Paks folder ----
Next-Step "Installing the VR pak"
$destPak = Join-Path $paksDir $PAK_NAME
$installedOk = $false
$dropExt = [System.IO.Path]::GetExtension($drop).ToLower()

if ($dropExt -eq ".pak") {
    # User dragged the extracted .pak directly.
    try { Copy-Item -Path $drop -Destination $destPak -Force; $installedOk = $true } catch { Write-Warn "Could not copy the pak: $_" }
} else {
    # Extract the zip and find pakchunk98-VR_OR_NOT_P.pak inside it.
    $xtemp = Join-Path $env:TEMP ("ronvr_" + [System.IO.Path]::GetRandomFileName())
    try { New-Item -ItemType Directory -Force -Path $xtemp | Out-Null } catch {}
    try {
        Expand-Archive -Path $drop -DestinationPath $xtemp -Force
        # NUR die richtige .pak. Der frueher hier stehende Rueckfall "nimm
        # irgendeine .pak" war genau das Loch, durch das ein aehnlich
        # benanntes Archiv gerutscht waere - geprueft wurde vorher nichts.
        $pakHit = Get-ChildItem -Path $xtemp -Filter $PAK_NAME -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($pakHit) {
            Copy-Item -Path $pakHit.FullName -Destination $destPak -Force
            $installedOk = $true
        } else {
            Write-Warn "No .pak file found inside the archive."
        }
    } catch { Write-Warn "Could not extract the archive: $_" }
    try { Remove-Item $xtemp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}

if (-not $installedOk) {
    # Manual fallback: guide the user to drop the pak in by hand.
    Write-Warn "Automatic install did not complete."
    Write-Host "  Please place this file:" -ForegroundColor White
    Write-Host "      $PAK_NAME" -ForegroundColor Gray
    Write-Host "  into this folder:" -ForegroundColor White
    Write-Host "      $paksDir" -ForegroundColor Gray
    try { Start-Process $paksDir } catch {}
    Pause-User "Press Enter once the .pak is in the Paks folder..."
    if (Test-Path $destPak) { $installedOk = $true }
}

if ($installedOk -and (Test-Path $destPak)) {
    Write-OK "VR pak installed: $destPak"
} else {
    Write-Warn "Could not confirm the .pak in the Paks folder - the mod may not load."
}

# ---- Launch options (REQUIRED) ----
# Retail: they live in Steam's launch-options field. Depot: there is
# no such field, so they ride on the desktop shortcut instead - and
# that is also where -dx11 has to go, since Steam's DirectX dropdown
# does not reach outside the library.
if ($isDepot) {
Next-Step "Desktop shortcut with the required options"
$depotExe = Join-Path $gameDir $GAME_EXE
Write-Host "  Your copy sits outside Steam, so Steam's launch options and" -ForegroundColor White
Write-Host "  its DirectX dropdown do not apply. Everything the mod needs" -ForegroundColor White
Write-Host "  goes on the shortcut instead:" -ForegroundColor White
Write-Host ""
Write-Host "        $DEPOT_LAUNCH_OPTS" -ForegroundColor Green
Write-Host ""
$lnk = $null
if (Test-Path $depotExe) {
    $lnk = New-DesktopShortcut -TargetPath $depotExe -ShortcutName $DEPOT_SHORTCUT_NAME -WorkingDir $gameDir -Arguments $DEPOT_LAUNCH_OPTS -IconPath "$depotExe,0"
} else {
    Write-Warn "$GAME_EXE not found in $gameDir - cannot build the shortcut."
}
if ($lnk) {
    Write-OK "Desktop shortcut created: $DEPOT_SHORTCUT_NAME"
    Write-Info "It carries the options above - start the game from it, not from the exe."
} else {
    Write-Warn "No desktop shortcut. Start the game like this instead:"
    Write-Host "        \"$depotExe\" $DEPOT_LAUNCH_OPTS" -ForegroundColor Gray
    Write-Host "  Or use Start Depot on this game's page in the Hub, which" -ForegroundColor Gray
    Write-Host "  passes the same options." -ForegroundColor Gray
}
} else {
Next-Step "Steam launch options (required)"
Write-Host "  The mod only activates with the right Steam launch options." -ForegroundColor White
Write-Host ""
$clipOk = $false
try { Set-Clipboard -Value $LAUNCH_OPTS; $clipOk = $true } catch { $clipOk = $false }
if ($clipOk) {
    Write-OK "Launch options copied to your clipboard:"
} else {
    Write-Warn "Could not copy to clipboard - type these in by hand:"
}
Write-Host "        $LAUNCH_OPTS" -ForegroundColor Green
Write-Host ""
Write-Host "  In the Steam properties window (opening next):" -ForegroundColor White
Write-Host "   1) Set the 'selected launch option' dropdown to: DirectX 11" -ForegroundColor White
Write-Host "   2) Click the Launch Options field and paste with Ctrl+V" -ForegroundColor White
Write-Host ""
Write-Host "  Tip: paste, do not type - a stray space (like '- usehmd')" -ForegroundColor Gray
Write-Host "  stops VR from starting." -ForegroundColor Gray
Pause-User "Press Enter to open Steam properties for Ready Or Not..."
try { Start-Process "steam://gameproperties/$APP_ID" } catch { Write-Warn "Open Steam manually: right-click Ready Or Not -> Properties -> General." }
Pause-User "Press Enter once you have set DX11, pasted the options, and closed Steam properties..."
}

# ---- DLSS Swapper (optional) ----
Next-Step "DLSS Swapper (optional) and finishing up"
Write-Host "  On an NVIDIA GPU, swapping in a modern DLSS version gives a" -ForegroundColor White
Write-Host "  big performance and clarity boost. DLSS Swapper is a free tool" -ForegroundColor White
Write-Host "  that does this for you - as an install or a portable copy." -ForegroundColor White

$wantDlss = Read-YesNo "Set up DLSS Swapper now?"
if ($wantDlss) {
    $already = Test-DlssSwapperInstalled
    if ($already) {
        Write-OK "DLSS Swapper looks already present ($already) - skipping the download."
        if ($already -eq "portable") {
            try { Start-Process (Join-Path $DLSS_PORTABLE_DIR "DLSS Swapper.exe") } catch {}
        }
    } else {
        Write-Host ""
        Write-Host "  How would you like DLSS Swapper?" -ForegroundColor White
        Write-Host "   1) Install  - integrates into Windows; can self-update inside the app." -ForegroundColor White
        Write-Host "   2) Portable - no install; lives in the Hub Tools folder (no self-update)." -ForegroundColor White
        $mode = Read-OneTwo "Choose 1 or 2"
        if ($mode -eq 1) {
            $dl = Get-DlssSwapperUrl -Kind "installer"
            $instUrl  = if ($dl) { $dl.Url }  else { $DLSS_INSTALLER_URL }
            $instName = if ($dl) { $dl.Name } else { "DLSS.Swapper-$DLSS_PINNED_VER-installer.exe" }
            if ($dl) { Write-Info "Newest release: $($dl.Tag)" } else { Write-Info "GitHub not reachable - using the pinned $DLSS_PINNED_VER build." }
            $tmpInst = Join-Path $env:TEMP $instName
            $ok = Invoke-DownloadOrFallback -Url $instUrl -Destination $tmpInst -Label "DLSS Swapper installer" -ManualUrl $DLSS_URL
            if ($ok -and (Test-Path $tmpInst)) {
                Write-OK "Downloaded the installer. Starting it - pick your install location in the setup."
                try { Start-Process $tmpInst } catch { Write-Warn "Run it manually: $tmpInst" }
                Pause-User "Press Enter once the DLSS Swapper setup has finished..."
            } else {
                Write-Warn "Could not download automatically. Get it here: $DLSS_URL"
                try { Start-Process $DLSS_URL } catch {}
                Pause-User "Press Enter once you have installed DLSS Swapper..."
            }
        } else {
            $dl = Get-DlssSwapperUrl -Kind "portable"
            $portUrl  = if ($dl) { $dl.Url }  else { $DLSS_PORTABLE_URL }
            $portName = if ($dl) { $dl.Name } else { "DLSS.Swapper-$DLSS_PINNED_VER-portable.zip" }
            if ($dl) { Write-Info "Newest release: $($dl.Tag)" } else { Write-Info "GitHub not reachable - using the pinned $DLSS_PINNED_VER build." }
            $tmpZip = Join-Path $env:TEMP $portName
            $ok = Invoke-DownloadOrFallback -Url $portUrl -Destination $tmpZip -Label "DLSS Swapper (portable)" -ManualUrl $DLSS_URL
            if ($ok -and (Test-Path $tmpZip)) {
                try { if (-not (Test-Path $TOOLS_DIR)) { New-Item -ItemType Directory -Path $TOOLS_DIR -Force | Out-Null } } catch {}
                try { if (Test-Path $DLSS_PORTABLE_DIR) { Remove-Item $DLSS_PORTABLE_DIR -Recurse -Force -ErrorAction SilentlyContinue } } catch {}
                [void](Expand-ArchiveOrFallback -ArchivePath $tmpZip -DestinationFolder $DLSS_PORTABLE_DIR -Label "DLSS Swapper (portable)")
                $exe = $null
                try { $exe = (Get-ChildItem -Path $DLSS_PORTABLE_DIR -Recurse -Filter "DLSS Swapper.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName } catch {}
                if (-not $exe) { try { $exe = (Get-ChildItem -Path $DLSS_PORTABLE_DIR -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*DLSS*Swapper*" } | Select-Object -First 1).FullName } catch {} }
                if ($exe -and (Test-Path $exe)) {
                    $lnk = New-DesktopShortcut -TargetPath $exe -ShortcutName "DLSS Swapper" -WorkingDir (Split-Path $exe -Parent)
                    if ($lnk) { Write-OK "Desktop shortcut created: DLSS Swapper" } else { Write-Warn "Could not create a desktop shortcut - launch it from the Tools folder." }
                    Write-Info "Portable copy lives in: $DLSS_PORTABLE_DIR"
                    Write-Info "It is portable, so you can move or copy that folder anywhere."
                    try { Start-Process $exe } catch { Write-Warn "Start it manually: $exe" }
                } else {
                    Write-Warn "Extracted, but could not find DLSS Swapper.exe under $DLSS_PORTABLE_DIR"
                    try { Start-Process $DLSS_PORTABLE_DIR } catch {}
                }
                Pause-User "Press Enter once DLSS Swapper is open..."
            } else {
                Write-Warn "Could not download automatically. Get the portable zip here: $DLSS_URL"
                try { Start-Process $DLSS_URL } catch {}
                Pause-User "Press Enter once you have DLSS Swapper ready..."
            }
        }
    }
    Write-Host ""
    Write-Host ""
    if ($isDepot) {
        # Der Depot-Build liegt nicht in der Steam-Bibliothek, also findet
        # ihn die automatische Spielesuche des Swappers nicht. Er muss von
        # Hand ueber den Ordner hinzugefuegt werden.
        Write-Host "  +==========================================================+" -ForegroundColor Yellow
        Write-Host "  |  ADD THIS BUILD BY HAND - IT IS NOT FOUND AUTOMATICALLY  |" -ForegroundColor Yellow
        Write-Host "  +==========================================================+" -ForegroundColor Yellow
        Write-Host "  Your copy sits outside the Steam library, so DLSS Swapper" -ForegroundColor White
        Write-Host "  does not list it. In DLSS Swapper, top right: " -NoNewline -ForegroundColor White
        Write-Host " Add game " -ForegroundColor Black -BackgroundColor Yellow
        Write-Host "  and pick this folder:" -ForegroundColor White
        Write-Host "    $gameDir " -ForegroundColor Black -BackgroundColor Yellow
        Write-Host ""
    }
    Write-Host "  Then on the Ready Or Not tile: pick v310.4 or newer as the" -ForegroundColor White
    Write-Host "  DLSS version, and set the DLSS Preset to Preset J." -ForegroundColor White
    Write-Host ""
    Write-Host "  When that is set, close DLSS Swapper. The next settings are in" -ForegroundColor White
    Write-Host "  the game itself, not in the Swapper." -ForegroundColor White
    Pause-User "Press Enter once the DLSS version/preset is set and DLSS Swapper is closed..."
} else {
    Write-Info "Skipping DLSS Swapper. You can add it later for extra performance."
}

try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameDir -Encoding UTF8 -Force } catch {}

# ---- Recommended settings (performance is the big topic) ----
Write-Host ""
Write-Host "  Next, Ready Or Not will start so you can apply a few important" -ForegroundColor White
Write-Host "  settings. Here is what to set:" -ForegroundColor White
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  !! RECOMMENDED SETTINGS - DO THIS OR PERFORMANCE MAY TANK !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Ready Or Not is VERY demanding in VR. Set these in flat mode" -ForegroundColor White
Write-Host "  before going into VR:" -ForegroundColor White
Write-Host ""
Write-Host "  In-game settings:" -ForegroundColor White
Write-Host "   1) Graphics Preset: Medium" -ForegroundColor White
Write-Host "   2) Open Advanced Graphics Settings" -ForegroundColor White
Write-Host "   3) Scroll down to NVIDIA DLSS and drag the slider to Balanced" -ForegroundColor White
Write-Host "   4) Controller menu: set Aim Assist Strength to Off" -ForegroundColor White
Write-Host "   5) Press Apply." -ForegroundColor White
Write-Host ""
Write-Host "  In the headset / streaming app:" -ForegroundColor White
Write-Host "   - Keep Render Resolution at 1.0x (Meta Quest Link)" -ForegroundColor White
Write-Host "   - Lower the refresh rate to 72 Hz if you need more headroom" -ForegroundColor White
Write-Host "   - Set your default OpenXR runtime correctly (Meta Link / SteamVR)" -ForegroundColor White
Write-Host ""
Write-Host "  Still stuttering? Disable Discord and other overlays, turn off" -ForegroundColor Gray
Write-Host "  OpenXR Toolkit if used, and lower the preset another notch." -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow

# ---- Launch once in flat mode to apply the settings ----
Pause-User "Press Enter to start the game and apply these settings (this installer stays open)..." -Color Yellow
if ($isDepot) {
    # NIEMALS steam://rungameid im Depot-Zweig - das startet die STEAM-
    # Kopie, nicht den gerade eingerichteten Build. Genau das war zu sehen.
    $depotExeRun = Join-Path $gameDir $GAME_EXE
    if (Test-Path -LiteralPath $depotExeRun) {
        try { Start-Process -FilePath $depotExeRun -ArgumentList $DEPOT_LAUNCH_OPTS -WorkingDirectory $gameDir }
        catch { Write-Warn "Start it from the '$DEPOT_SHORTCUT_NAME' desktop shortcut instead." }
    } else {
        Write-Warn "$GAME_EXE not found in $gameDir - start it from the desktop shortcut."
    }
} else {
    try { Start-Process "steam://rungameid/$APP_ID" } catch { Write-Warn "Launch Ready Or Not from Steam manually." }
}
Write-Host ""
Write-Host "  The game starts in flat mode for this. Apply the settings above," -ForegroundColor White
Write-Host "  then close the game and come back here." -ForegroundColor White
Pause-User "Press Enter once you have applied the settings and closed the game..."

# ---- Choose how to enter VR ----
Write-Host ""
Write-Host "  Ready Or Not had to start in flat mode for the settings. Now" -ForegroundColor White
Write-Host "  pick how you want to enter VR:" -ForegroundColor White
Write-Host "   1) Manual    - press the U key in-game after the mission loads." -ForegroundColor White
Write-Host "   2) Automatic - drop into VR about 3 seconds after a mission loads." -ForegroundColor White
$vrChoice = Read-OneTwo "Choose 1 or 2"
if ($isDepot) {
    # Kein Steam-Feld fuer diese Kopie - die Wahl landet auf der
    # Verknuepfung, sonst waere sie wirkungslos.
    if ($vrChoice -eq 2) {
        $depotExeVr = Join-Path $gameDir $GAME_EXE
        $lnk2 = $null
        if (Test-Path -LiteralPath $depotExeVr) {
            $lnk2 = New-DesktopShortcut -TargetPath $depotExeVr -ShortcutName $DEPOT_SHORTCUT_NAME -WorkingDir $gameDir -Arguments $DEPOT_LAUNCH_AUTOVR -IconPath "$depotExeVr,0"
        }
        if ($lnk2) {
            Write-OK "Shortcut rewritten with automatic VR entry:"
            Write-Host "        $DEPOT_LAUNCH_AUTOVR" -ForegroundColor Green
        } else {
            Write-Warn "Could not rewrite the shortcut - add -autoVR to its target by hand."
        }
        Write-Info "Start Depot in the Hub keeps manual entry (press U)."
    } else {
        Write-OK "Manual it is - press U in-game after the mission loads to enter VR."
    }
} elseif ($vrChoice -eq 2) {
    $clip2 = $false
    try { Set-Clipboard -Value $LAUNCH_OPTS_AUTOVR; $clip2 = $true } catch { $clip2 = $false }
    if ($clip2) { Write-OK "New launch options copied to your clipboard:" } else { Write-Warn "Could not copy - type these in by hand:" }
    Write-Host "        $LAUNCH_OPTS_AUTOVR" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Steam properties opens next. Click the Launch Options field," -ForegroundColor White
    Write-Host "  select all (Ctrl+A) and paste (Ctrl+V) to replace the command." -ForegroundColor White
    Pause-User "Press Enter to open Steam properties for Ready Or Not..."
    try { Start-Process "steam://gameproperties/$APP_ID" } catch { Write-Warn "Open Steam manually: right-click Ready Or Not -> Properties -> General." }
    Pause-User "Press Enter once you have replaced the launch options and closed Steam properties..."
} else {
    Write-OK "Manual it is - press U in-game after the mission loads to enter VR."
}

# ---- Done ----
Write-Host ""
Write-Host " Setup complete." -ForegroundColor Green
Write-Host " When you play: start your VR runtime (Meta Quest Link or SteamVR)" -ForegroundColor White
if ($isDepot) {
Write-Host " first, then start the game from the '$DEPOT_SHORTCUT_NAME' desktop" -ForegroundColor White
Write-Host " shortcut, or with Start Depot on this game's page in the Hub." -ForegroundColor White
Write-Host " It starts in flat mode; VR comes with the U key, or on its own if" -ForegroundColor White
Write-Host " you picked automatic." -ForegroundColor White
Write-Host " This build is pinned and will not update, and your Steam copy of" -ForegroundColor White
Write-Host " Ready Or Not was not touched." -ForegroundColor White
} else {
Write-Host " first, then launch Ready Or Not from Steam in flat mode." -ForegroundColor White
}
Write-Host " Controller bindings and the full troubleshooting list are on the" -ForegroundColor White
Write-Host " game's description page in the Hub." -ForegroundColor White
Write-Host " Help and feedback: $DISCORD_URL" -ForegroundColor Gray
Write-Host ""
Write-Host " Stack up, breach with caution, and bring every officer home." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit"
