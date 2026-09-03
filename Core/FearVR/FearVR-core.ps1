# ============================================================
# F.E.A.R. VR Installer (fear-vr by DR-89)
# ============================================================
# Downloads the latest release (pre-releases included) from
# github.com/DR-89/fear-vr, unpacks it to the chosen mod folder,
# and runs the mod's own installer with explicit paths.
#
# The mod needs the official F.E.A.R. Public Tools 1.08 (it copies
# five proprietary engine modules from there). Installing Public
# Tools is fiddly - it wants a Monolith registry value flipped from
# 10 to 8 first - so this installer detects it and, if missing,
# walks you through installing it, doing the registry dance for you.
#
# Nothing is bundled inside the Hub. Retail F.E.A.R. is never
# written to by the mod's installer.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "F.E.A.R. VR Installer"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " F.E.A.R. VR Installer" -ForegroundColor Cyan
    Write-Host " fear-vr by DR-89 | open beta (GitHub)" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

$SCRIPT_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path
$REPO         = "DR-89/fear-vr"
$API_RELEASES = "https://api.github.com/repos/$REPO/releases"
$RELEASES_URL = "https://github.com/$REPO/releases"
# The mod's own default is %USERPROFILE%\FearVR, but that is an awkward
# place to find - and it needs a Defender exclusion, so it has to be a path
# the user can actually locate. Chosen below, Hub convention: C:\Games.
$GAME_FOLDER  = "FEAR VR"
$DEFAULT_ROOTS = @("C:\Games", "D:\Games", "E:\Games")
$OLD_INSTALL_DIR = Join-Path $env:USERPROFILE "FearVR"
$INSTALL_DIR  = $null
$EXPECTED_ZIP = "fearvr"

# HD Textures for F.E.A.R. & Extraction Point, by Rivarez. The VR mod's
# author lists it as a required companion, and it is a 5.06 GB download
# behind a ModDB page - so it cannot be fetched automatically.
# Verified on the ModDB file page: filename, size and the fact that the
# archive contains a GUI installer the user drives themselves.
$HD_PAGE     = "https://www.moddb.com/downloads/fear-hd-textures-v202"
$HD_RAR      = "HDTextures4FEAR_XP_v2.0.2.rar"
$HD_SIZE     = "5.06 GB"
$HD_VERSION  = "v2.0.2"
# Kept inside the mod folder after installing, so the pack can be removed
# later without hunting down the 5 GB archive again.
$HD_UNINSTALLER_NAME = "FEAR_HDTextures.exe"
# Copy of the untouched FEAR.exe, taken before the texture pack patches it.
# Putting it back is the whole undo: the mod only accepts the stock exe or the
# HD-patched one, and the pack's own uninstaller leaves a third variant behind.
$HD_EXE_BACKUP_NAME  = "FEAR.exe.pre-hd.bak"

# Public Tools facts (verified against a real 1.08 install):
$PT_ROOT    = "C:\Program Files (x86)\Sierra\FEAR Public Tools"
$PT_GAME    = Join-Path $PT_ROOT "Dev\Runtime\Game"
$PT_MODULES = @("GameClient.dll","GameServer.dll","ClientFx.fxd","FEAR.dep","FEARMod.Arch00s")
$PT_EXE_REL = "extras\fear_publictools_108.exe"
$REG_KEY    = "HKLM:\SOFTWARE\WOW6432Node\Monolith Productions\FEAR\1.00.0000"
# Note on disk describing what 'Patch' looked like before we touched it.
# It survives a crash, a killed admin window and a closed installer, so the
# value can always be put back - the Hub guarantees the restore instead of
# telling the user to go edit the registry.
$PT_PENDING = Join-Path $SCRIPT_DIR ".patch_restore"

function Save-PatchState {
    try {
        $rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\WOW6432Node\Monolith Productions\FEAR\1.00.0000", $false)
        if (-not $rk) { return }
        $v = $rk.GetValue("Patch", $null)
        $k = if ($null -ne $v) { [string]$rk.GetValueKind("Patch") } else { "None" }
        $rk.Close()
        $line = "{0}|{1}" -f $k, $(if ($null -ne $v) { [string]$v } else { "" })
        Set-Content -LiteralPath $PT_PENDING -Value $line -Encoding UTF8 -Force
    } catch {}
}

# Puts 'Patch' back to the recorded state. Elevates once if it really has to.
# $true = the registry now matches what was recorded (or nothing was pending).
function Restore-PatchState {
    if (-not (Test-Path -LiteralPath $PT_PENDING)) { return $true }
    $rec = ""
    try { $rec = (Get-Content -LiteralPath $PT_PENDING -Raw -ErrorAction Stop).Trim() } catch { return $true }
    if (-not $rec) { try { Remove-Item -LiteralPath $PT_PENDING -Force -EA SilentlyContinue } catch {}; return $true }
    $parts = $rec.Split("|")
    $kind  = $parts[0]
    $val   = if ($parts.Count -gt 1) { $parts[1] } else { "" }

    $cur = $null
    try { $cur = (Get-ItemProperty -Path $REG_KEY -Name Patch -ErrorAction Stop).Patch } catch { $cur = $null }
    $isBack = if ($kind -eq "None") { $null -eq $cur } else { "$cur" -eq "$val" }
    if ($isBack) { try { Remove-Item -LiteralPath $PT_PENDING -Force -EA SilentlyContinue } catch {}; return $true }

    Write-Info "Putting the Monolith registry value back the way it was..."
    $fix = Join-Path $env:TEMP ("fearvr_fix_" + [Guid]::NewGuid().ToString("N").Substring(0,8) + ".ps1")
    $body = @'
param([string]$Kind,[string]$Value)
$key = "HKLM:\SOFTWARE\WOW6432Node\Monolith Productions\FEAR\1.00.0000"
try {
    if ($Kind -eq "None") { Remove-ItemProperty -Path $key -Name Patch -Force -ErrorAction SilentlyContinue }
    elseif ($Kind -eq "String" -or $Kind -eq "ExpandString") { Set-ItemProperty -Path $key -Name Patch -Value $Value -Force }
    else { Set-ItemProperty -Path $key -Name Patch -Value ([int]$Value) -Type DWord -Force }
} catch {}
'@
    Set-Content -LiteralPath $fix -Value $body -Encoding UTF8 -Force
    try {
        Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList @(
            "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$fix`"","-Kind","`"$kind`"","-Value","`"$val`""
        ) | Out-Null
    } catch {}
    Remove-Item -LiteralPath $fix -Force -EA SilentlyContinue

    $cur = $null
    try { $cur = (Get-ItemProperty -Path $REG_KEY -Name Patch -ErrorAction Stop).Patch } catch { $cur = $null }
    $isBack = if ($kind -eq "None") { $null -eq $cur } else { "$cur" -eq "$val" }
    if ($isBack) {
        try { Remove-Item -LiteralPath $PT_PENDING -Force -EA SilentlyContinue } catch {}
        Write-OK "Registry value restored."
        return $true
    }
    return $false
}

# ---- Steam + retail helpers ---------------------------------
function Get-SteamPath {
    foreach ($r in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try { $p=(Get-ItemProperty -Path $r -EA Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
    }
    return $null
}
function Get-SteamLibraries {
    param($sp)
    $libs = New-Object System.Collections.Generic.List[string]
    if (-not $sp) { return $libs }
    $libs.Add($sp)
    $vdf = Join-Path $sp "steamapps\libraryfolders.vdf"
    if (Test-Path $vdf) {
        try { foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s*"([^"]+)"')) {
            $p = $m.Groups[1].Value -replace '\\\\','\'; if ($p -and (Test-Path -LiteralPath $p)) { $libs.Add($p) } } } catch {}
    }
    return $libs
}
function Find-FearSteam {
    # DR-89 supports the Steam Ultimate Shooter Edition only. Never allow
    # the first chooser option to silently pick a GOG/retail copy.
    foreach ($lib in (Get-SteamLibraries (Get-SteamPath))) {
        foreach ($nm in @("FEAR Ultimate Shooter Edition","F.E.A.R. - Ultimate Shooter Edition","F.E.A.R. Ultimate Shooter Edition","FEAR","F.E.A.R.")) {
            $c = Join-Path $lib "steamapps\common\$nm"
            if (Test-Path -LiteralPath (Join-Path $c "FEAR.exe")) { return $c }
        }
    }
    return $null
}
function Find-FearGogForChooser {
    # Mirrors the dedicated GOG installer's probe so the chooser can show
    # useful status without changing that installer's behavior.
    foreach ($root in @("C:\GOG Games", "D:\GOG Games", "E:\GOG Games",
                        "C:\Program Files (x86)\GOG Galaxy\Games",
                        "C:\Program Files\GOG Galaxy\Games")) {
        foreach ($folder in @("F.E.A.R. Platinum Collection", "FEAR Platinum Collection",
                              "F.E.A.R. Platinum", "FEAR")) {
            $c = $root.TrimEnd([char[]]"\/") + "\" + $folder
            if (Test-Path -LiteralPath ($c + "\FEAR.exe")) { return $c }
        }
    }
    return $null
}
function Test-FearVrMarker {
    param(
        [string[]]$RecordFiles,
        [string[]]$FallbackRoots,
        [string[]]$RelativeMarkers
    )
    # A path record is only a lead; the mod-owned payload file is the
    # evidence. This also upgrades older installs that only have the shared
    # legacy .installed_path record without confusing the two VR mods.
    $roots = New-Object System.Collections.Generic.List[string]
    foreach ($recordFile in @($RecordFiles)) {
        if (-not $recordFile -or -not (Test-Path -LiteralPath $recordFile -PathType Leaf)) { continue }
        try {
            $recorded = ([string](Get-Content -LiteralPath $recordFile -Raw -ErrorAction Stop)).Trim()
            if ($recorded) { [void]$roots.Add($recorded) }
        } catch {}
    }
    foreach ($root in @($FallbackRoots)) {
        if ($root) { [void]$roots.Add([string]$root) }
    }
    $separator = [string][IO.Path]::DirectorySeparatorChar
    foreach ($root in @($roots | Select-Object -Unique)) {
        if (-not $root) { continue }
        foreach ($marker in @($RelativeMarkers)) {
            if (-not $marker) { continue }
            try {
                $nativeMarker = ([string]$marker).Replace('\', $separator).Replace('/', $separator)
                $candidate = [IO.Path]::Combine([string]$root, $nativeMarker)
                if ([IO.File]::Exists($candidate)) { return $true }
            } catch {}
        }
    }
    return $false
}
# True when a folder holds all five Public Tools modules.
function Test-PtGameFolder {
    param([string]$Dir)
    if ([string]::IsNullOrWhiteSpace($Dir)) { return $false }
    if (-not (Test-Path -LiteralPath $Dir)) { return $false }
    foreach ($m in $PT_MODULES) { if (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($Dir, $m)))) { return $false } }
    return $true
}

# Public Tools does NOT always land in the same place - different builds
# and installers use Sierra\, Monolith Productions\ or a bare folder, and
# the modules sit under Dev\Runtime\Game, Runtime\Game or Game. Rather
# than pin one path (and wrongly claim "not installed" when it IS there,
# pushing the user through the registry step for nothing), probe the known
# combinations and remember whichever one hits.
function Find-PublicToolsGame {
    $names = @(
        "Sierra\FEAR Public Tools",
        "Monolith Productions\FEAR Public Tools",
        "FEAR Public Tools",
        "F.E.A.R. Public Tools"
    )
    # Build the parent list from folders that REALLY exist. Join-Path raises
    # a DriveNotFound error on a drive letter that isn't mounted (a literal
    # "D:\Games" in this list is what broke this step), so nothing is ever
    # composed from a guessed drive, and every Join-Path is guarded.
    $parents = New-Object System.Collections.Generic.List[string]
    foreach ($p in @(${env:ProgramFiles(x86)}, $env:ProgramFiles)) {
        if ($p -and (Test-Path -LiteralPath $p)) { [void]$parents.Add([string]$p) }
    }
    try {
        foreach ($d in @(Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
            $rootDrive = [string]$d.Root
            if (-not $rootDrive) { continue }
            if ($rootDrive -notmatch '^[A-Za-z]:\\$') { continue }
            foreach ($sub in @("Program Files (x86)", "Program Files", "Games")) {
                $cand = $rootDrive + $sub
                if (Test-Path -LiteralPath $cand) { [void]$parents.Add($cand) }
            }
        }
    } catch {}
    $parentList = @($parents | Select-Object -Unique)

    $suffixes = @("Dev\Runtime\Game", "Runtime\Game", "Game", "")
    foreach ($parent in $parentList) {
        foreach ($n in $names) {
            # [IO.Path]::Combine is plain .NET string work - unlike Join-Path
            # it never touches the PowerShell drive provider, so a path on a
            # drive that isn't mounted can't raise DriveNotFound (which is a
            # NON-terminating error, i.e. try/catch does not even swallow it).
            $rootDir = $null
            try { $rootDir = [System.IO.Path]::Combine($parent, $n) } catch { continue }
            if ([string]::IsNullOrWhiteSpace($rootDir)) { continue }
            if (-not (Test-Path -LiteralPath $rootDir)) { continue }
            foreach ($s in $suffixes) {
                $game = $null
                try { $game = if ($s) { [System.IO.Path]::Combine($rootDir, $s) } else { $rootDir } } catch { continue }
                if ([string]::IsNullOrWhiteSpace($game)) { continue }
                if (Test-PtGameFolder -Dir $game) { return $game }
            }
        }
    }
    return $null
}

function Test-PublicTools {
    $hit = $null
    try { $hit = Find-PublicToolsGame } catch { $hit = $null }
    if ($hit) { $script:PT_GAME = $hit; return $true }
    return $false
}

Write-Header

$fearSteamRoot = Find-FearSteam
$fearGogRoot = Find-FearGogForChooser
$legacyPathRecord = Join-Path $SCRIPT_DIR ".installed_path"
$fearSteamModAdded = Test-FearVrMarker `
    -RecordFiles @((Join-Path $SCRIPT_DIR ".installed_path_dr89"), $legacyPathRecord) `
    -FallbackRoots @($fearSteamRoot, "C:\Games\$GAME_FOLDER", "D:\Games\$GAME_FOLDER", "E:\Games\$GAME_FOLDER", $OLD_INSTALL_DIR) `
    -RelativeMarkers @("bin\x64\fearvr-host.exe", "FEARVR\bin\x64\fearvr-host.exe")
$fearGogModAdded = Test-FearVrMarker `
    -RecordFiles @((Join-Path $SCRIPT_DIR ".installed_path_gog"), $legacyPathRecord) `
    -FallbackRoots @($fearGogRoot) `
    -RelativeMarkers @("fearvr_bridge.dll")

# =============================================================
#  Which build?
# =============================================================
# !!! TWO MODS, TWO GAME EDITIONS. DR-89's build targets the Steam
# Ultimate Shooter Edition; thefreemike's targets the GOG Platinum
# Collection and supports nothing else. They are separate projects by
# separate authors, not two settings of one thing.
Write-Host ""
Write-Host "  Two VR mods exist for F.E.A.R., one per game edition:" -ForegroundColor White
Write-Host ""
Write-Host "   [1] DR-89 " -NoNewline -ForegroundColor Cyan
Write-Host "- for the STEAM Ultimate Shooter Edition" -ForegroundColor White
Write-Host "       Open source, downloaded automatically from GitHub." -ForegroundColor Gray
if ($fearSteamRoot) {
    if ($fearSteamModAdded) {
        Write-Host "       GAME INSTALLED (STEAM) - VR MOD WAS ADDED" -ForegroundColor Green
    } else {
        Write-Host "       GAME INSTALLED (STEAM) - VR MOD CAN BE ADDED" -ForegroundColor Green
    }
    Write-Host "       $fearSteamRoot" -ForegroundColor DarkGreen
} else {
    Write-Host "       Steam game not detected" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "   [2] thefreemike " -NoNewline -ForegroundColor Cyan
Write-Host "- for the GOG Platinum Collection" -ForegroundColor White
Write-Host "       Body holsters, physical pickups, two-handed props." -ForegroundColor Gray
Write-Host "       Private beta, handed out in his Discord - you download it" -ForegroundColor Gray
Write-Host "       yourself and drag it in." -ForegroundColor Gray
if ($fearGogRoot) {
    if ($fearGogModAdded) {
        Write-Host "       GAME INSTALLED (GOG) - VR MOD WAS ADDED" -ForegroundColor Green
    } else {
        Write-Host "       GAME INSTALLED (GOG) - VR MOD CAN BE ADDED" -ForegroundColor Green
    }
    Write-Host "       $fearGogRoot" -ForegroundColor DarkGreen
} else {
    Write-Host "       GOG game not detected" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "  Pick the one that matches the copy you own." -ForegroundColor DarkGray
Write-Host ""
$fearPick = ""
for ($k = 1; $k -le 20; $k++) {
    $fearPick = ("" + (Read-Host "  Enter 1 or 2")).Trim()
    if ($fearPick -in @("1","2")) { break }
    Write-Host "  Please answer 1 or 2." -ForegroundColor Yellow
}
if ($fearPick -eq "2") {
    $gogScript = Join-Path $PSScriptRoot "FearVR-Gog.ps1"
    if (-not (Test-Path -LiteralPath $gogScript)) {
        Write-Host "  The GOG installer is missing: $gogScript" -ForegroundColor Red
        Pause-User "Press Enter to exit."
        exit 1
    }
    & $gogScript
    exit 0
}
Write-Host "  F.E.A.R. VR is an open-source OpenXR mod for the single-player" -ForegroundColor Gray
Write-Host "  base game of F.E.A.R. 1.08: native stereo rendering, full motion" -ForegroundColor Gray
Write-Host "  controls, slow-mo, a hand flashlight and a VR settings page." -ForegroundColor Gray
Write-Host "  Confirmed on Quest 3 with SteamVR and VirtualDesktopXR." -ForegroundColor Gray
Write-Host ""
Write-Host "  This is an early open beta built with heavy AI assistance." -ForegroundColor Yellow
Write-Host ""
Show-AntivirusNotice
Pause-User "Press Enter to begin (or close this window to cancel)..." | Out-Null

# ---- 1. locate retail F.E.A.R. ------------------------------
Write-Step 1 5 "Finding your F.E.A.R. installation"
$retailRoot = if ($fearSteamRoot) { $fearSteamRoot } else { Find-FearSteam }
if (-not $retailRoot) {
    Write-Fail "Could not find the Steam Ultimate Shooter Edition."
    Write-Host "  Install F.E.A.R. 1.08 (Ultimate Shooter Edition) in Steam, then run" -ForegroundColor Gray
    Write-Host "  this again. If it's on an unusual drive, make sure FEAR.exe is" -ForegroundColor Gray
    Write-Host "  present in the game folder." -ForegroundColor Gray
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}
Write-OK "Found F.E.A.R. at: $retailRoot"

# ---- where the mod itself goes -------------------------------
function Test-WritableRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path $Root)) {
            New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null
        }
        $probe = Join-Path $Root ".pcvrhub_write_probe"
        Set-Content -Path $probe -Value "ok" -ErrorAction Stop
        Remove-Item $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

# An existing install decides everything below: we reuse its folder instead
# of asking again, and only then can we offer to undo the texture pack.
$existingDir = $null
$recordedFile = Join-Path $SCRIPT_DIR ".installed_path"
if (Test-Path -LiteralPath $recordedFile) {
    try {
        $rp = (Get-Content -LiteralPath $recordedFile -Raw -ErrorAction Stop).Trim()
        if ($rp -and (Test-Path -LiteralPath (Join-Path $rp "deployment.json"))) { $existingDir = $rp }
    } catch {}
}
if (-not $existingDir) {
    $guess = Join-Path "C:\Games" $GAME_FOLDER
    if (Test-Path -LiteralPath (Join-Path $guess "deployment.json")) { $existingDir = $guess }
}

if ($existingDir) {
    $INSTALL_DIR = $existingDir
    Write-OK "Existing install found: $INSTALL_DIR"
} else {

Write-Host ""
Write-Host "  The mod installs into its own folder, separate from the game." -ForegroundColor White
Write-Host "  Default location: C:\Games\$GAME_FOLDER" -ForegroundColor White
Write-Host "  C:\Games needs no admin rights, so there's no Windows UAC prompt." -ForegroundColor Gray
Write-Host "  Press Enter to accept it, or type a different folder to install into" -ForegroundColor Gray
Write-Host "  (the '$GAME_FOLDER' folder is created inside whatever you choose)." -ForegroundColor Gray
$chosen = (Read-Host "  Install root [C:\Games]").Trim().Trim('"')

$installRoot = $null
if ($chosen) {
    if (Test-WritableRoot -Root $chosen) { $installRoot = [string]$chosen }
    else { Write-Fail "Not writable: $chosen - falling back to the defaults." }
}
if (-not $installRoot) {
    foreach ($r in $DEFAULT_ROOTS) {
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r; break }
    }
}
if (-not $installRoot) {
    Write-Warn "None of C:\Games, D:\Games, E:\Games is writable."
    Write-Host "  Enter a folder where the mod should be installed." -ForegroundColor White
    while (-not $installRoot) {
        $r = (Read-Host "  Install root").Trim().Trim('"')
        if (-not $r) { continue }
        if (Test-WritableRoot -Root $r) { $installRoot = [string]$r }
        else { Write-Fail "Not writable: $r (try a non-Program-Files location, or run as admin)" }
    }
}
$INSTALL_DIR = Join-Path $installRoot $GAME_FOLDER
Write-OK "Mod folder: $INSTALL_DIR"

}

# ---- what kind of install ------------------------------------
# The HD texture pack patches FEAR.exe and breaks the game on some systems
# (Steam application load error). Defender exclusions do not help. So this
# is a plain choice, made before anything is downloaded.
# Finds the texture pack's own installer, which doubles as its uninstaller.
# Tier 1 is the copy this installer keeps; older installs predate that, so
# tiers 2 and 3 look where the download would still be, and tier 4 asks.
function Find-HDUninstaller {
    $c = Join-Path $INSTALL_DIR $HD_UNINSTALLER_NAME
    if (Test-Path -LiteralPath $c) { return [string]$c }
    $dl = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"
    foreach ($dir in @($dl, ([Environment]::GetFolderPath("Desktop")))) {
        if (-not $dir -or -not (Test-Path -LiteralPath $dir)) { continue }
        try {
            $hit = Get-ChildItem -LiteralPath $dir -Filter $HD_UNINSTALLER_NAME -File -Recurse -Depth 3 -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($hit) { return [string]$hit.FullName }
        } catch {}
    }
    return $null
}

# Option 3 is offered whenever the VR mod is installed - NOT only when the
# uninstaller happens to sit in the mod folder. Installs made before the
# Hub started keeping that copy would otherwise never see the way out.
$hdUninstaller = Find-HDUninstaller
$canUndoHD = [bool]$existingDir

$wantHD    = $false
$undoHD    = $false

Write-Host ""
Write-Host "  +==========================================================+" -ForegroundColor Cyan
Write-Host "  |                   CHOOSE YOUR INSTALL                    |" -ForegroundColor Cyan
Write-Host "  +==========================================================+" -ForegroundColor Cyan
Write-Host "   [1] Original game" -ForegroundColor White
Write-Host "   [2] Original game + HD texture mod ($HD_SIZE download)" -ForegroundColor White
if ($canUndoHD) {
Write-Host "   [3] Remove the HD texture mod" -ForegroundColor White
}
Write-Host ""
$valid = if ($canUndoHD) { @("1","2","3") } else { @("1","2") }
$choice = ""
while ($choice -notin $valid) { $choice = (Read-Host ("  Your choice [" + ($valid -join "/") + "]")).Trim() }

if ($choice -eq "2") {
    $wantHD = $true
    Write-Host ""
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "  |                   GOOD TO KNOW                           |" -ForegroundColor Yellow
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "  You can remove the textures again at any time: run this" -ForegroundColor White
    Write-Host "  installer from the Hub and pick " -NoNewline -ForegroundColor White
    Write-Host " Remove the HD texture mod " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Pause-User "Press Enter to continue..." | Out-Null
} elseif ($choice -eq "3") {
    $undoHD = $true
}

# ---- 2. HD textures (optional) ------------------------------
Write-Step 2 5 "HD Textures $HD_VERSION by Rivarez"

if ($undoHD) {
    Write-Host "  The texture pack's own installer removes it again." -ForegroundColor White
    Write-Host ""
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "  |            WHAT TO DO IN THE WINDOW THAT OPENS           |" -ForegroundColor Yellow
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "   1) Click " -NoNewline -ForegroundColor White
    Write-Host " Uninstall " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " and wait until it is done." -ForegroundColor White
    Write-Host "   2) Close that window." -ForegroundColor White
    Write-Host "  Then the VR mod is installed again automatically." -ForegroundColor White
    if (-not $hdUninstaller) {
        Write-Warn "The texture pack's installer is not on this machine any more."
        Write-Host "  It is called $HD_UNINSTALLER_NAME and sits inside the archive you" -ForegroundColor Gray
        Write-Host "  downloaded from ModDB. Extract the archive and drag the file onto" -ForegroundColor Gray
        Write-Host "  this window, or paste its full path." -ForegroundColor Gray
        Write-Host "  (Press Enter on an empty line to skip removing the textures.)" -ForegroundColor DarkGray
        while (-not $hdUninstaller) {
            $r = (Read-Host "  Path to $HD_UNINSTALLER_NAME").Trim().Trim('"').Trim("'")
            if (-not $r) { break }
            if (-not (Test-Path -LiteralPath $r)) { Write-Fail "File not found: $r"; continue }
            if ($r -notmatch '\.exe$')          { Write-Fail "Not an .exe: $r";     continue }
            $hdUninstaller = [string]$r
        }
    }

    if (-not $hdUninstaller) {
        Write-Warn "Continuing without removing the textures."
        Write-Host "  Steam users can also restore the original game files:" -ForegroundColor Gray
        Write-Host "  right-click F.E.A.R. in Steam > Properties > Installed Files >" -ForegroundColor Gray
        Write-Host "  Verify integrity of game files." -ForegroundColor Gray
        Pause-User "Press Enter to continue..." | Out-Null
    } else {
    Pause-User "Press Enter to open it..." | Out-Null
    try {
        Start-Process -FilePath $hdUninstaller -WorkingDirectory (Split-Path -Parent $hdUninstaller) -Wait
        Write-OK "Texture pack removed."
        try { Remove-Item -LiteralPath $hdUninstaller -Force -ErrorAction SilentlyContinue } catch {}

        # Put the saved exe back. The pack's uninstaller leaves a variant the
        # mod does not accept, so this copy is what actually restores the game.
        $exeBackup = Join-Path $INSTALL_DIR $HD_EXE_BACKUP_NAME
        $targetExe = Join-Path $retailRoot "FEAR.exe"
        if (Test-Path -LiteralPath $exeBackup) {
            try {
                Copy-Item -LiteralPath $exeBackup -Destination $targetExe -Force -ErrorAction Stop
                Write-OK "Restored the original FEAR.exe."
                try { Remove-Item -LiteralPath $exeBackup -Force -ErrorAction SilentlyContinue } catch {}
            } catch {
                Write-Fail "Could not restore FEAR.exe: $($_.Exception.Message)"
                Write-Host "  Copy it back by hand:" -ForegroundColor Gray
                Write-Host "    from $exeBackup" -ForegroundColor Gray
                Write-Host "    to   $targetExe" -ForegroundColor Gray
                Pause-User "Press Enter once that is done..." | Out-Null
            }
        } else {
            # No backup - the textures were installed by an older build.
            Write-Warn "No saved copy of FEAR.exe found (older install)."
            Write-Host ""
            Write-Host "  +==========================================================+" -ForegroundColor Yellow
            Write-Host "  |        FEAR.exe MUST BE RESTORED BY HAND                 |" -ForegroundColor Yellow
            Write-Host "  +==========================================================+" -ForegroundColor Yellow
            if ($retailRoot -match '(?i)steamapps') {
                Write-Host "   1) Delete this file:" -ForegroundColor White
                Write-Host "      $targetExe" -ForegroundColor Black -BackgroundColor Yellow
                Write-Host "   2) In Steam: F.E.A.R. > Properties > Installed Files >" -ForegroundColor White
                Write-Host "      " -NoNewline -ForegroundColor White
                Write-Host " Verify integrity of game files " -ForegroundColor Black -BackgroundColor Yellow
                Write-Host "      Deleting it first is what forces a fresh copy." -ForegroundColor Gray
                try { Start-Process "steam://validate/21090" } catch {}
            } else {
                Write-Host "   Reinstall F.E.A.R. so FEAR.exe is the original file." -ForegroundColor White
            }
            Write-Host ""
            Pause-User "Press Enter once FEAR.exe is restored..." | Out-Null
        }
    } catch {
        Write-Fail "Could not start it: $($_.Exception.Message)"
        Write-Host "  Run it yourself: $hdUninstaller" -ForegroundColor Gray
        Pause-User "Press Enter once you are done..." | Out-Null
    }
    }
} elseif (-not $wantHD) {
    Write-Info "Skipped on your request."
} else {
    # 7-Zip FIRST, before the 5 GB download: the pack ships as a .rar, which
    # Windows and Expand-Archive cannot open. Get-SevenZip probes the usual
    # locations and, if nothing is there, offers to fetch and install it
    # silently. Better to settle this now than after a long download.
    Write-Info "Checking for 7-Zip (needed to unpack the .rar)..."
    $sevenZip = Get-SevenZip
    if ($sevenZip) {
        Write-OK "7-Zip ready: $sevenZip"
    } else {
        Write-Warn "No 7-Zip available - the Hub cannot unpack the .rar for you."
        Write-Host "  You can still do it by hand: download the pack, extract it with" -ForegroundColor Gray
        Write-Host "  any tool that reads .rar, and run FEAR_HDTextures.exe inside." -ForegroundColor Gray
        Write-Host "  Point it at: $retailRoot" -ForegroundColor Gray
        Write-Host ""
        $goOn = (Read-Host "  Continue with the HD textures anyway? [Y/N]").Trim().ToUpper()
        if ($goOn -notin @("Y","YES","")) {
            $wantHD = $false
            Write-Info "Skipping the HD textures - installing the VR mod only."
        }
    }
}

if ($wantHD) {
    Write-Host "  Pressing Enter opens the ModDB download page - no need to copy" -ForegroundColor Yellow
    Write-Host "  or click anything here:" -ForegroundColor Yellow
    Write-Host "     $HD_PAGE" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Download '$HD_RAR' ($HD_SIZE), then come" -ForegroundColor White
    Write-Host "  back here. The installer looks in your Downloads folder, or" -ForegroundColor White
    Write-Host "  you can drag the file onto this window." -ForegroundColor White
    # Check the disk BEFORE the browser. Nobody should be sent off to
    # re-download 5 GB that is already sitting in their Downloads folder.
    $hdArchive = Find-PredownloadedFile `
        -Patterns @("*HDTextures*FEAR*.rar","HDTextures4FEAR*.rar","*HDTextures*.rar") `
        -Label "the HD texture pack"

    if (-not $hdArchive) {
        Pause-User "Press Enter to open the download page..." | Out-Null
        try { Start-Process $HD_PAGE } catch { Write-Warn "Open manually: $HD_PAGE" }

        # Look again once the user is back - the first pass ran before the
        # download could possibly exist. 5 GB takes a while, so this pause
        # may sit here for a long time; that is fine.
        Pause-User "Press Enter once the download has finished..." | Out-Null
        $hdArchive = Find-PredownloadedFile `
            -Patterns @("*HDTextures*FEAR*.rar","HDTextures4FEAR*.rar","*HDTextures*.rar") `
            -Label "the HD texture pack" -PageAlreadyOpen
    }

    if (-not $hdArchive) {
        Write-Host ""
        $tries = 0
        while (-not $hdArchive) {
            $tries++
            Write-Host "  Drag-and-drop the downloaded archive into this window," -ForegroundColor Yellow
            Write-Host "  or paste / type its full path, then press Enter." -ForegroundColor White
            Write-Host "  (Press Enter on an empty line to skip the HD textures.)" -ForegroundColor DarkGray
            $r = (Read-Host "  Archive path").Trim().Trim('"').Trim("'")
            if (-not $r) {
                Write-Warn "Continuing without the HD textures - you can run this installer again later."
                break
            }
            if (-not (Test-Path -LiteralPath $r)) { Write-Fail "File not found: $r"; continue }
            if ($r -notmatch '\.(rar|zip|7z)$') { Write-Fail "Not a .rar/.zip/.7z archive: $r"; continue }
            $hdArchive = [string]$r
            Write-OK "Archive located: $hdArchive"
        }
    }

    if ($hdArchive) {
        if (-not $sevenZip) {
            Write-Host "  Unpack '$hdArchive' yourself, run FEAR_HDTextures.exe inside it," -ForegroundColor Gray
            Write-Host "  and point it at: $retailRoot" -ForegroundColor Gray
            Pause-User "Press Enter once you are done (or to continue without it)..." | Out-Null
        } else {
            # Extract OUTSIDE the game folder on purpose: users have reported the
            # texture installer stalling with no progress bar when it is run from
            # inside the F.E.A.R. directory. A separate folder avoids that.
            $hdTemp = Join-Path $env:TEMP ("FearHD_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
            New-Item -ItemType Directory -Path $hdTemp -Force | Out-Null

            # ~5 GB unpacked - check there is room before starting a long job.
            try {
                $tempDrive = [System.IO.Path]::GetPathRoot($hdTemp)
                $free = (Get-PSDrive -Name $tempDrive.Substring(0,1) -ErrorAction Stop).Free
                if ($free -lt 6GB) {
                    Write-Warn ("Only {0} GB free on {1} - the pack needs about 6 GB while unpacking." -f [math]::Round($free/1GB,1), $tempDrive)
                    Write-Host "  Free some space, or press Enter to try anyway." -ForegroundColor Gray
                    Pause-User "Press Enter to continue..." | Out-Null
                }
            } catch {}

            Write-Host ""
            Write-Info "Unpacking $HD_SIZE - this takes a few minutes."
            $unpacked = $false
            try { $unpacked = Expand-7zWithProgress -SevenZip $sevenZip -Archive $hdArchive -Dest $hdTemp -Label "HD textures" } catch { $unpacked = $false }

            # Archive layout: FEAR_HDTextures.exe sits at the root next to an
            # "HDTextures" folder holding everything it uses. So the exe must be
            # run from ITS OWN folder, and the folder has to come along.
            # Detection, in order: the exe that has an HDTextures folder beside
            # it, then the exe by name, then the largest .exe as a last resort.
            $hdExe = $null
            if ($unpacked) {
                $allExe = @(Get-ChildItem -LiteralPath $hdTemp -Filter "*.exe" -Recurse -File -ErrorAction SilentlyContinue)
                $hdExe = $allExe | Where-Object {
                            Test-Path -LiteralPath (Join-Path $_.DirectoryName "HDTextures")
                         } | Select-Object -First 1
                if (-not $hdExe) { $hdExe = $allExe | Where-Object { $_.Name -ieq "FEAR_HDTextures.exe" } | Select-Object -First 1 }
                if (-not $hdExe) { $hdExe = $allExe | Sort-Object Length -Descending | Select-Object -First 1 }
            }

            if (-not $hdExe) {
                Write-Fail "Could not find the texture installer inside the archive."
                Write-Host "  Unpack '$hdArchive' by hand and run FEAR_HDTextures.exe inside it," -ForegroundColor Gray
                Write-Host "  pointing it at: $retailRoot" -ForegroundColor Gray
                Pause-User "Press Enter to continue..." | Out-Null
            } else {
                Write-OK "Texture installer found: $($hdExe.Name)"
                Write-Host ""
                Write-Host "  +==========================================================+" -ForegroundColor Yellow
                Write-Host "  |          WHAT TO DO IN THE TEXTURE INSTALLER             |" -ForegroundColor Yellow
                Write-Host "  +==========================================================+" -ForegroundColor Yellow
                # The path is already on the clipboard, so nobody has to retype
                # it into the texture installer's field.
                $pathCopied = $false
                try { Set-Clipboard -Value $retailRoot -ErrorAction Stop; $pathCopied = $true } catch {}
                Write-Host "   1) Point it at the folder that holds FEAR.exe:" -ForegroundColor White
                Write-Host "      $retailRoot" -ForegroundColor Black -BackgroundColor Yellow
                if ($pathCopied) {
                    # Its field starts out empty - that is normal, not a fault.
                    # Say what to DO, so nobody hunts for a problem.
                    Write-Host "      Its field starts out empty. The path above is already on" -ForegroundColor White
                    Write-Host "      your clipboard: click into the field and press " -NoNewline -ForegroundColor White
                    Write-Host " Ctrl + V " -ForegroundColor Black -BackgroundColor Yellow
                }
                if ($retailRoot -match '(?i)steamapps') {
                    Write-Host "   2) Your copy is from Steam. The Steam option is the one on" -ForegroundColor White
                    Write-Host "      the " -NoNewline -ForegroundColor White
                    Write-Host " RIGHT " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
                    Write-Host " and it is NOT preselected." -ForegroundColor White
                    Write-Host "      Click its text so the eye marker moves over to it." -ForegroundColor White
                } else {
                    Write-Host "   2) Your copy is not from Steam. Pick the non-Steam option -" -ForegroundColor White
                    Write-Host "      that is the one on the " -NoNewline -ForegroundColor White
                    Write-Host " LEFT " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
                    Write-Host " ." -ForegroundColor White
                }
                Write-Host "   3) Only then click Install, and wait for it to finish." -ForegroundColor White
                Pause-User "Press Enter to start the texture installer..." | Out-Null

                # Back up the untouched exe first - this is what makes the
                # undo exact. Never overwrite an existing backup: it would
                # replace the good copy with an already-patched one.
                $exeBackup = Join-Path $INSTALL_DIR $HD_EXE_BACKUP_NAME
                try {
                    if (-not (Test-Path -LiteralPath $INSTALL_DIR)) {
                        New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
                    }
                    $srcExe = Join-Path $retailRoot "FEAR.exe"
                    if ((Test-Path -LiteralPath $srcExe) -and -not (Test-Path -LiteralPath $exeBackup)) {
                        Copy-Item -LiteralPath $srcExe -Destination $exeBackup -Force -ErrorAction Stop
                        Write-OK "Saved a copy of FEAR.exe for undoing this later."
                    }
                } catch { Write-Warn "Could not back up FEAR.exe: $($_.Exception.Message)" }

                try {
                    Start-Process -FilePath $hdExe.FullName -WorkingDirectory $hdExe.DirectoryName -Wait
                    Write-OK "Texture installer closed."
                    # Keep the uninstaller so the pack can be removed later
                    # without re-downloading 5 GB. The mod folder survives.
                    try {
                        if (-not (Test-Path -LiteralPath $INSTALL_DIR)) {
                            New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
                        }
                        Copy-Item -LiteralPath $hdExe.FullName `
                                  -Destination (Join-Path $INSTALL_DIR $HD_UNINSTALLER_NAME) -Force -ErrorAction Stop
                    } catch {}
                } catch {
                    Write-Fail "Could not start it: $($_.Exception.Message)"
                    Write-Host "  Run it yourself: $($hdExe.FullName)" -ForegroundColor Gray
                    Pause-User "Press Enter once you are done..." | Out-Null
                }

                # -- start the game once so it settles with the new textures
                Write-Host ""
                Write-Host "  +==========================================================+" -ForegroundColor Yellow
                Write-Host "  |              ONE RUN BEFORE THE VR MOD                   |" -ForegroundColor Yellow
                Write-Host "  +==========================================================+" -ForegroundColor Yellow
                Write-Host "   F.E.A.R. is started once now so it comes up with the new" -ForegroundColor White
                Write-Host "   textures in place. " -NoNewline -ForegroundColor White
                Write-Host " Quit at the main menu " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
                Write-Host " - you do" -ForegroundColor White
                Write-Host "   not need to play anything." -ForegroundColor White
                Pause-User "Press Enter to start F.E.A.R. once..." | Out-Null

                $started = $false
                $fearExe = Join-Path $retailRoot "FEAR.exe"
                if ($retailRoot -match '(?i)steamapps') {
                    try { Start-Process "steam://rungameid/21090"; $started = $true } catch {}
                }
                if (-not $started -and (Test-Path -LiteralPath $fearExe)) {
                    try { Start-Process -FilePath $fearExe -WorkingDirectory $retailRoot; $started = $true } catch {}
                }
                if (-not $started) {
                    Write-Warn "Could not start F.E.A.R. automatically - please start and quit it yourself."
                }
                Pause-User "Press Enter once F.E.A.R. is closed again..." | Out-Null
            }

            # 5 GB of unpacked textures - do not leave them in TEMP.
            Write-Info "Cleaning up the unpacked files..."
            try { Remove-Item -LiteralPath $hdTemp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
}

# ---- 3. F.E.A.R. Public Tools 1.08 --------------------------
Write-Step 3 5 "Checking for F.E.A.R. Public Tools 1.08"

# A previous run may have died between changing the value and restoring it.
# Clear that debt first - silent when there is nothing pending.
[void](Restore-PatchState)

if (Test-PublicTools) {
    Write-OK "Public Tools 1.08 found: $PT_GAME"
} else {
    Write-Warn "Public Tools 1.08 is not installed - the mod needs it."

    $ptExe = Join-Path $retailRoot $PT_EXE_REL
    if (-not (Test-Path -LiteralPath $ptExe)) {
        $literal = "C:\Program Files (x86)\Steam\steamapps\common\FEAR Ultimate Shooter Edition\$PT_EXE_REL"
        if (Test-Path -LiteralPath $literal) { $ptExe = $literal }
    }

    if (-not (Test-Path -LiteralPath $ptExe)) {
        Write-Fail "The Public Tools installer 'fear_publictools_108.exe' was not found."
        Write-Host "  It normally lives in your F.E.A.R. folder under 'extras\'." -ForegroundColor Gray
        Write-Host "  Expected: $ptExe" -ForegroundColor DarkGray
        Write-Host "  Install Public Tools 1.08 manually, then run this again." -ForegroundColor Gray
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }

    Write-Host ""
    Write-Host " >>> Needs admin: approve the UAC prompt, then click through the " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " >>> Public Tools installer with its default options.            " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " >>> License agreement: scroll to the bottom to enable Accept.    " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " >>> Takes a while. Everything else runs and closes by itself.   " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    $go = ""
    while ($go -notin @("y","Y","n","N")) { $go = (Read-Host "  Install Public Tools 1.08 now? Requires admin (UAC) (Y/N)").Trim() }
    if ($go -in @("n","N")) {
        Write-Info "Skipped. The mod can't be installed without Public Tools."
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }

    # The Public Tools installer refuses to run while the Monolith
    # registry value 'Patch' reads 10 (what the 1.08 build sets); it wants
    # 8. We flip it, run the installer, then put it straight back.
    #
    # Rules for this step, learned the hard way after it failed in the
    # field:
    #  * NEVER create the key or the value when they are missing. A
    #    fabricated, half-empty key makes the installer bail instantly -
    #    it reads more than just 'Patch' - which looks to the user like
    #    "the installer just closes".
    #  * Preserve the value's ORIGINAL type. Forcing a DWord over a
    #    REG_SZ breaks the installer's read the same way.
    #  * Wait on the installer PROCESS, never on the user pressing Enter
    #    in an elevated window they may never even see. Restoring the
    #    value too early kills the installer mid-check.
    $regReady = $false
    try { $regReady = [bool](Get-Item -LiteralPath $REG_KEY -ErrorAction Stop) } catch { $regReady = $false }

    if (-not $regReady) {
        Write-Warn "The Monolith registry entry for F.E.A.R. wasn't found."
        Write-Host "  Without it the automatic step can't run safely, so please run" -ForegroundColor Gray
        Write-Host "  Public Tools yourself - it only takes a minute:" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   1. Run: $ptExe" -ForegroundColor White
        Write-Host "   2. Click through it with the DEFAULT options." -ForegroundColor White
        Write-Host "   3. Start this installer again." -ForegroundColor White
        Write-Host ""
        $open = (Read-Host "  Open the folder that contains it now? (Y/N)").Trim()
        if ($open -in @("y","Y")) { try { Start-Process explorer.exe "/select,`"$ptExe`"" } catch {} }
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }

    # One elevated helper does the whole dance in a single UAC prompt and
    # closes on its own: set 8 -> run installer -> wait for it -> restore.
    $helper = Join-Path $env:TEMP ("fearvr_pt_" + [Guid]::NewGuid().ToString("N").Substring(0,8) + ".ps1")
    $helperBody = @'
param([string]$Exe)
$ErrorActionPreference = "Continue"
$key    = "HKLM:\SOFTWARE\WOW6432Node\Monolith Productions\FEAR\1.00.0000"
$sub    = "SOFTWARE\WOW6432Node\Monolith Productions\FEAR\1.00.0000"
$name   = "Patch"

# Read the current value AND its type, so we can put back exactly what
# was there - including putting back nothing if there was nothing.
$hadValue = $false
$origVal  = $null
$origKind = "DWord"
try {
    $rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($sub, $false)
    if ($rk) {
        $origVal = $rk.GetValue($name, $null)
        if ($null -ne $origVal) { $hadValue = $true; $origKind = [string]$rk.GetValueKind($name) }
        $rk.Close()
    }
} catch {}

Write-Host ""
Write-Host "  Temporarily setting Monolith 'Patch' to 8 so the installer runs..." -ForegroundColor Cyan
try {
    if ($origKind -eq "String" -or $origKind -eq "ExpandString") {
        Set-ItemProperty -Path $key -Name $name -Value "8" -Force
    } else {
        Set-ItemProperty -Path $key -Name $name -Value 8 -Type DWord -Force
    }
} catch {
    Write-Host "  Could not change the registry value: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "  Starting the F.E.A.R. Public Tools installer." -ForegroundColor Cyan
Write-Host ""
Write-Host "  On the license agreement: scroll all the way down." -NoNewline -ForegroundColor White
Write-Host " " -NoNewline
Write-Host " Accept only unlocks at the bottom " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "  Click through it with the DEFAULT options." -ForegroundColor Yellow
Write-Host ""
Write-Host "  THIS CAN TAKE A WHILE. This window stays open and waits for the" -ForegroundColor Yellow
Write-Host "  installer to finish - it is NOT frozen. A spinner below shows it" -ForegroundColor Yellow
Write-Host "  is still working. Do not close either window." -ForegroundColor Yellow
Write-Host ""
$leaf = [System.IO.Path]::GetFileNameWithoutExtension($Exe)
$dir  = Split-Path -Parent $Exe
$proc = $null
try {
    $proc = Start-Process -FilePath $Exe -WorkingDirectory $dir -PassThru
} catch {
    Write-Host "  Could not start the installer: $($_.Exception.Message)" -ForegroundColor Red
}
# Wait with a visible spinner instead of a dead-looking pause. Some setup
# packages hand off to a second process and return at once, so we also
# watch for anything still running under that name before restoring.
$frames   = @("|","/","-","\")
$i        = 0
$started  = Get-Date
$deadline = $started.AddMinutes(30)
while ((Get-Date) -lt $deadline) {
    $running = $false
    try { if ($proc -and -not $proc.HasExited) { $running = $true } } catch {}
    if (-not $running) {
        $still = @(Get-Process -Name $leaf -ErrorAction SilentlyContinue)
        if ($still.Count -gt 0) { $running = $true }
    }
    if (-not $running) { break }
    $mins = [int]((Get-Date) - $started).TotalMinutes
    Write-Host ("`r  " + $frames[$i % 4] + " Waiting for the Public Tools installer to finish... (" + $mins + " min)   ") -NoNewline -ForegroundColor Cyan
    $i++
    Start-Sleep -Milliseconds 400
}
Write-Host ("`r  Public Tools installer has finished.                                  ") -ForegroundColor Green

Write-Host "  Restoring the registry value..." -ForegroundColor Cyan
try {
    if ($hadValue) {
        if ($origKind -eq "String" -or $origKind -eq "ExpandString") {
            Set-ItemProperty -Path $key -Name $name -Value ([string]$origVal) -Force
        } else {
            Set-ItemProperty -Path $key -Name $name -Value ([int]$origVal) -Type DWord -Force
        }
    } else {
        Remove-ItemProperty -Path $key -Name $name -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  Done - the registry is back the way it was." -ForegroundColor Green
} catch {
    Write-Host "  Could not restore the value: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Please set 'Patch' back to 10 by hand under:" -ForegroundColor Yellow
    Write-Host "  HKLM\SOFTWARE\WOW6432Node\Monolith Productions\FEAR\1.00.0000" -ForegroundColor Yellow
    Start-Sleep -Seconds 8
}
Start-Sleep -Seconds 2
'@
    Set-Content -Path $helper -Value $helperBody -Encoding UTF8 -Force

    # Write down the exact current state first. From here on the Hub is
    # responsible for putting it back - the note on disk means even a crash
    # or a killed admin window can't leave the value changed.
    Save-PatchState

    Write-Host ""
    Write-Info "Opening an elevated window (approve the UAC prompt). It closes by itself."
    try {
        Start-Process powershell -Verb RunAs -Wait -ArgumentList @(
            "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$helper`"","-Exe","`"$ptExe`""
        ) | Out-Null
    } catch {
        Write-Warn "The elevated step was cancelled or failed: $($_.Exception.Message)"
    }
    Remove-Item $helper -Force -ErrorAction SilentlyContinue

    # The admin window can be killed or closed mid-way. Don't just report
    # that - put the value back. Restore-PatchState is silent when the
    # helper already did its job, and elevates once more only if it didn't.
    if (-not (Restore-PatchState)) {
        Write-Warn "Could not put the registry value back automatically."
        Write-Host "  It is retried the next time this installer runs." -ForegroundColor Gray
    }

    if (Test-PublicTools) {
        Write-OK "Public Tools 1.08 is now installed."
    } else {
        Write-Fail "Public Tools still isn't detected at $PT_GAME."
        Write-Host "  If you installed it somewhere else, that's fine - but this mod" -ForegroundColor Gray
        Write-Host "  expects the default location. Re-run the Public Tools installer" -ForegroundColor Gray
        Write-Host "  with the default path, then run this again." -ForegroundColor Gray
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
}

# ---- 4. download + unpack the mod ---------------------------
Write-Step 4 5 "Getting the latest F.E.A.R. VR release"
$work    = Join-Path $env:TEMP ("fearvr_dl_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $work -Force | Out-Null
$zipPath = Join-Path $work "fearvr-release.zip"
$relTag  = $null
$gotZip  = $false

try {
    Write-Info "Querying GitHub for the newest release (pre-releases included)..."
    $rels = Invoke-RestMethod -Uri $API_RELEASES -Headers @{ "User-Agent" = "VRModHub" } -ErrorAction Stop
    $rel  = $rels | Select-Object -First 1
    if ($rel) {
        $relTag = [string]$rel.tag_name
        $asset  = $rel.assets | Where-Object { $_.name -like "*.zip" -and $_.name -like "*$EXPECTED_ZIP*" } | Select-Object -First 1
        if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1 }
        if ($asset) {
            Write-Info "Release $relTag - downloading $($asset.name)"
            $ok = Invoke-SafeDownload -Urls @($asset.browser_download_url) -Destination $zipPath `
                    -Label "F.E.A.R. VR $relTag" -ManualUrl $RELEASES_URL `
                    -Instructions "Download the .zip asset from the newest release, then drag it in."
            if ($ok -and (Test-Path $zipPath)) { $gotZip = $true }
        } else { Write-Warn "The newest release has no .zip asset." }
    }
} catch { Write-Warn "Could not reach the GitHub API: $($_.Exception.Message)" }

if (-not $gotZip) {
    Write-Host ""
    Write-Host "  Falling back to a local file." -ForegroundColor Yellow
    $dl = Join-Path $env:USERPROFILE "Downloads"
    $hit = $null
    if (Test-Path -LiteralPath $dl) {
        $hit = Get-ChildItem -LiteralPath $dl -Filter "fearvr*.zip" -File -EA SilentlyContinue |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
        # The author renames the archive between builds, so fall back to a
        # looser match before giving up and asking for a drag-and-drop.
        if (-not $hit) {
            $hit = Get-ChildItem -LiteralPath $dl -Filter "*.zip" -File -EA SilentlyContinue |
                   Where-Object { $_.Name -match '(?i)f\.?e\.?a\.?r\.?.*vr|vr.*f\.?e\.?a\.?r' } |
                   Sort-Object LastWriteTime -Descending | Select-Object -First 1
        }
    }
    if ($hit) {
        Write-OK "Found in Downloads: $($hit.FullName)"
        $keep = (Read-Host "  Use this file? Press Enter to accept, or type N to pick another").Trim()
        if ($keep -notin @("n","N")) { Copy-Item -LiteralPath $hit.FullName -Destination $zipPath -Force; $gotZip = $true }
    }
    while (-not $gotZip) {
        Write-Host "  Open the releases page, download the .zip, then drag it here" -ForegroundColor Yellow
        Write-Host "  (or paste its full path). Enter on an empty line opens the page." -ForegroundColor White
        $r = (Read-Host "  ZIP path").Trim().Trim('"')
        if (-not $r) { try { Start-Process $RELEASES_URL } catch {}; continue }
        if (-not (Test-Path $r)) { Write-Fail "File not found: $r"; continue }
        if ($r -notmatch '\.zip$') { Write-Fail "Not a ZIP: $r"; continue }
        Copy-Item -LiteralPath $r -Destination $zipPath -Force
        $gotZip = $true
    }
}

# Unpack flat to the install dir. Release files are overwritten, while all
# additional local files and subfolders are kept.
try {
    if (-not (Test-Path -LiteralPath $INSTALL_DIR)) { New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null }
    Expand-Archive -Path $zipPath -DestinationPath $INSTALL_DIR -Force -ErrorAction Stop
} catch {
    Write-Fail "Could not unpack the release: $($_.Exception.Message)"
    try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}
    Pause-User "Press Enter to exit..." | Out-Null
    exit 1
}

$installScript = Join-Path $INSTALL_DIR "tools\install.ps1"
if (-not (Test-Path -LiteralPath $installScript)) {
    $hit = Get-ChildItem -LiteralPath $INSTALL_DIR -Filter "install.ps1" -Recurse -Depth 3 -File -EA SilentlyContinue |
           Where-Object { $_.FullName -like "*\tools\install.ps1" } | Select-Object -First 1
    if ($hit) {
        $pkgRoot = Split-Path -Parent (Split-Path -Parent $hit.FullName)
        if ($pkgRoot -and ($pkgRoot -ne $INSTALL_DIR)) {
            Get-ChildItem -LiteralPath $pkgRoot -Force | ForEach-Object {
                Move-Item -LiteralPath $_.FullName -Destination $INSTALL_DIR -Force -EA SilentlyContinue }
        }
        $installScript = Join-Path $INSTALL_DIR "tools\install.ps1"
    }
}
# ---------------------------------------------------------------
# This mod reorganises its package between builds. Rather than
# depending on one fixed script name, decide from what the archive
# ACTUALLY contains. Every known shape is handled, and an unknown one
# ends in a readable message instead of "wrong file?".
#   A) tools\install.ps1                 - the classic package
#   B) FEARVR\tools\prepare-overlay.ps1  - the overlay package (beta.8+):
#      extract over the game folder, then prepare it in place
#   C) neither, but launchers are there  - pure drag & drop, nothing to run
# ---------------------------------------------------------------
$overlayPrep = $null
if (-not (Test-Path -LiteralPath $installScript)) {
    $hitPrep = Get-ChildItem -LiteralPath $INSTALL_DIR -Filter "prepare-overlay.ps1" -Recurse -Depth 4 -File -EA SilentlyContinue |
               Select-Object -First 1
    if ($hitPrep) { $overlayPrep = $hitPrep.FullName }
}

if ($overlayPrep) {
    Write-Info "Overlay package detected - installing next to FEAR.exe."

    # The mod's own README is explicit: a plain extraction overwrites a
    # third-party d3d9.dll (ReShade, dgVoodoo, fix wrappers) WITHOUT a
    # backup. Their graphical installer chains it as
    # d3d9.fearvr-upstream.dll - do the same instead of destroying it.
    $existingD3D9 = Join-Path $retailRoot "d3d9.dll"
    $chained      = Join-Path $retailRoot "d3d9.fearvr-upstream.dll"
    if ((Test-Path -LiteralPath $existingD3D9) -and -not (Test-Path -LiteralPath $chained)) {
        $isOurs = $false
        try { $isOurs = ((Get-Item -LiteralPath $existingD3D9).VersionInfo.FileDescription -match '(?i)fearvr') } catch {}
        if (-not $isOurs) {
            try {
                Move-Item -LiteralPath $existingD3D9 -Destination $chained -Force -ErrorAction Stop
                Write-OK "Kept your existing d3d9.dll as d3d9.fearvr-upstream.dll"
            } catch { Write-Warn "Could not back up the existing d3d9.dll: $($_.Exception.Message)" }
        }
    }

    # Move the extracted overlay into the game folder.
    $overlayRoot = Split-Path -Parent (Split-Path -Parent $overlayPrep)   # ...\FEARVR
    $pkgRoot     = Split-Path -Parent $overlayRoot                        # archive root
    try {
        Get-ChildItem -LiteralPath $pkgRoot -Force | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $retailRoot -Recurse -Force -ErrorAction Stop
        }
    } catch {
        Write-Fail "Could not copy the overlay into the game folder: $($_.Exception.Message)"
        Pause-User "Press Enter to exit..." | Out-Null; exit 1
    }

    # From here the overlay IS the install: rebind so every later step
    # (staging, success check, play.ps1, shortcut) points at it.
    $INSTALL_DIR   = Join-Path $retailRoot "FEARVR"
    $installScript = Join-Path $INSTALL_DIR "tools\prepare-overlay.ps1"
    $script:UseOverlayPrep = $true
    Write-OK "Overlay installed to $INSTALL_DIR"
}
elseif (-not (Test-Path -LiteralPath $installScript)) {
    $launchers = @(Get-ChildItem -LiteralPath $INSTALL_DIR -Filter "*.cmd" -Recurse -Depth 3 -File -EA SilentlyContinue)
    Write-Fail "This release has neither tools\install.ps1 nor tools\prepare-overlay.ps1."
    if ($launchers.Count -gt 0) {
        Write-Info "It looks like a drag & drop package - copy its contents next to FEAR.exe yourself:"
        Write-Host "    from: $INSTALL_DIR" -ForegroundColor Cyan
        Write-Host "    to:   $retailRoot" -ForegroundColor Cyan
        try { Start-Process $INSTALL_DIR } catch {}
        try { Start-Process $retailRoot } catch {}
    } else {
        Write-Info "Check the release page - the package layout changed again."
    }
    # Do NOT dead-end here. The mod itself documents plain extraction into
    # the game folder as a valid install, so copy it there and carry on -
    # a layout we do not recognise still ends up installed.
    Write-Info "Installing it the documented way instead: copying everything next to FEAR.exe."
    try {
        Get-ChildItem -LiteralPath $INSTALL_DIR -Force | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $retailRoot -Recurse -Force -ErrorAction Stop
        }
        $maybeOverlay = Join-Path $retailRoot "FEARVR"
        if (Test-Path -LiteralPath $maybeOverlay) { $INSTALL_DIR = $maybeOverlay } else { $INSTALL_DIR = $retailRoot }
        $script:NoPrepScript = $true
        Write-OK "Copied into $retailRoot"
    } catch {
        Write-Fail "Could not copy the package into the game folder: $($_.Exception.Message)"
        Pause-User "Press Enter to exit..." | Out-Null; exit 1
    }
}
else { Write-OK "Unpacked to $INSTALL_DIR" }

# ---- 5. stage the mod (mod installer, explicit paths) -------
Write-Step 5 5 "Staging the mod against your F.E.A.R. install"

# The mod accepts exactly the hashes listed in its own package: stock 1.08 and
# 1.08 + HD textures. Anything else makes its launcher throw "unknown variant"
# AFTER a seemingly successful install. Check it here, while we can still say
# something useful, instead of letting the game fail at launch.
try {
    $relCfg = Join-Path $INSTALL_DIR "tools\_fearvr-release.ps1"
    $fearExe = Join-Path $retailRoot "FEAR.exe"
    if ((Test-Path -LiteralPath $relCfg) -and (Test-Path -LiteralPath $fearExe)) {
        $knownHashes = @{}
        $cfgText = Get-Content -Raw -LiteralPath $relCfg -ErrorAction Stop
        foreach ($m in [regex]::Matches($cfgText, "'([0-9A-Fa-f]{64})'\s*=\s*(?:\r?\n\s*)?'([^']+)'")) {
            $knownHashes[$m.Groups[1].Value.ToUpper()] = $m.Groups[2].Value
        }
        if ($knownHashes.Count -gt 0) {
            $exeHash = (Get-FileHash -LiteralPath $fearExe -Algorithm SHA256).Hash.ToUpper()
            if ($knownHashes.ContainsKey($exeHash)) {
                Write-OK ("FEAR.exe recognised: " + $knownHashes[$exeHash])
            } else {
                Write-Warn "FEAR.exe is not one of the builds this mod accepts."
                Write-Host "  Your FEAR.exe: $exeHash" -ForegroundColor Gray
                Write-Host "  Accepted builds:" -ForegroundColor Gray
                foreach ($k in $knownHashes.Keys) { Write-Host ("    " + $knownHashes[$k]) -ForegroundColor Gray }
                Write-Host ""
                Write-Host "  +==========================================================+" -ForegroundColor Yellow
                Write-Host "  |        FEAR.exe MUST BE RESTORED FIRST                   |" -ForegroundColor Yellow
                Write-Host "  +==========================================================+" -ForegroundColor Yellow
                Write-Host "   Installing now would succeed and the game would still" -ForegroundColor White
                Write-Host "   refuse to start. Restore the file:" -ForegroundColor White
                if ($retailRoot -match '(?i)steamapps') {
                    Write-Host "   1) Delete this file:" -ForegroundColor White
                    Write-Host "      $fearExe" -ForegroundColor Black -BackgroundColor Yellow
                    Write-Host "   2) In Steam: F.E.A.R. > Properties > Installed Files >" -ForegroundColor White
                    Write-Host "      " -NoNewline -ForegroundColor White
                    Write-Host " Verify integrity of game files " -ForegroundColor Black -BackgroundColor Yellow
                    Write-Host "      Deleting it first forces Steam to fetch a fresh copy -" -ForegroundColor Gray
                    Write-Host "      verifying alone sometimes keeps the patched file." -ForegroundColor Gray
                } else {
                    Write-Host "   Reinstall F.E.A.R. so FEAR.exe is the original file." -ForegroundColor White
                }
                Write-Host ""
                Pause-User "Press Enter once FEAR.exe is restored (I will check again)..." | Out-Null
                try {
                    $exeHash2 = (Get-FileHash -LiteralPath $fearExe -Algorithm SHA256).Hash.ToUpper()
                    if ($knownHashes.ContainsKey($exeHash2)) {
                        Write-OK ("FEAR.exe recognised: " + $knownHashes[$exeHash2])
                    } else {
                        Write-Warn "Still not a recognised build - the mod will refuse to start."
                        Write-Host "  Continuing anyway so nothing is left half-done." -ForegroundColor Gray
                    }
                } catch {}
            }
        }
    }
} catch {}
Write-Info "Verifying retail files and copying the Public Tools modules..."

# The mod's own installer is a foreign script that changes between builds:
# it may prompt, stall, or fail in its own language. So it runs as a SEPARATE
# process with its output captured to a log and a hard time limit - it can
# never hang this installer, and when it fails we can show why instead of
# guessing.
$MOD_LOG = Join-Path $INSTALL_DIR "hub-modinstall.log"
$MOD_ERR = Join-Path $INSTALL_DIR "hub-modinstall.err.log"

function Test-ModStaged {
    if (-not (Test-Path -LiteralPath (Join-Path $INSTALL_DIR "deployment.json"))) { return $false }
    # deployment.json alone isn't proof - the payload has to be there too.
    if (-not (Test-Path -LiteralPath (Join-Path $INSTALL_DIR "bin\x64\fearvr-host.exe"))) { return $false }
    return $true
}

function Invoke-ModInstaller {
    param([int]$TimeoutMinutes = 15)
    foreach ($f in @($MOD_LOG, $MOD_ERR)) { try { Remove-Item -LiteralPath $f -Force -EA SilentlyContinue } catch {} }
    $psArgs = @(
        "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$installScript`""
    )
    # Read the foreign script's own param block and pass ONLY what it
    # declares. Names come and go between builds (-NonInteractive vanished
    # with the overlay package); an unknown one aborts the whole script.
    $declared = ""
    try { $declared = Get-Content -Raw -LiteralPath $installScript -ErrorAction Stop } catch {}
    $wanted = @{
        "InstallDir"      = $INSTALL_DIR
        "RetailRoot"      = $retailRoot
        "PublicToolsGame" = $PT_GAME
    }
    foreach ($k in @("InstallDir","RetailRoot","PublicToolsGame")) {
        if (-not $declared -or $declared -match ("\`$" + $k + "\b")) {
            $psArgs += "-$k"; $psArgs += "`"$($wanted[$k])`""
        }
    }
    foreach ($sw in @("NonInteractive","Force")) {
        if ($declared -match ("\`$" + $sw + "\b")) { $psArgs += "-$sw" }
    }
    # -Clean forces the mod to re-baseline from scratch (its own userdata is
    # kept). Without it the mod does an "Update" and keeps the previous
    # deployment.json - including the recorded hash of the game exe. After the
    # HD texture pack is added or removed that exe changes, the recorded hash
    # no longer matches, and the mod's launcher refuses to start.
    # -Clean only exists from beta.3 on - beta.1/2 abort on it, and the
    # overlay script does not know it either. Same rule as every other
    # switch: pass it only when the script declares it.
    if (($undoHD -or $wantHD) -and ($declared -match '\$Clean\b')) { $psArgs += "-Clean" }
    $proc = $null
    try {
        $proc = Start-Process "powershell.exe" -ArgumentList $psArgs -PassThru -WindowStyle Hidden `
                    -RedirectStandardOutput $MOD_LOG -RedirectStandardError $MOD_ERR
    } catch {
        Write-Fail "Could not start the mod installer: $($_.Exception.Message)"
        return $false
    }
    if (-not $proc) { Write-Fail "Could not start the mod installer."; return $false }

    $frames = @("|","/","-","\")
    $i = 0
    $started = Get-Date
    $deadline = $started.AddMinutes($TimeoutMinutes)
    while (-not $proc.HasExited) {
        if ((Get-Date) -gt $deadline) {
            Write-Host ""
            Write-Warn "The mod installer exceeded $TimeoutMinutes minutes - stopping it."
            try { $proc.Kill() } catch {}
            try { $proc.WaitForExit(5000) | Out-Null } catch {}
            return $false
        }
        $secs = [int]((Get-Date) - $started).TotalSeconds
        Write-Host ("`r  " + $frames[$i % 4] + " Staging... ($secs s)   ") -NoNewline -ForegroundColor Cyan
        $i++
        Start-Sleep -Milliseconds 300
    }
    Write-Host ("`r                                        ") -NoNewline
    Write-Host ("`r") -NoNewline
    return (Test-ModStaged)
}

$modOk = Test-ModStaged
$attempt = 0
while (-not $modOk) {
    $attempt++
    $modOk = Invoke-ModInstaller
    if ($modOk) { break }

    Write-Fail "Staging did not complete (attempt $attempt)."
    # Surface the last few lines of the mod's own log - that is where the
    # real reason lives (wrong FEAR.exe hash, missing module, blocked file).
    foreach ($lg in @($MOD_ERR, $MOD_LOG)) {
        if (Test-Path -LiteralPath $lg) {
            $tail = @(Get-Content -LiteralPath $lg -Tail 6 -EA SilentlyContinue | Where-Object { $_.Trim() })
            if ($tail.Count -gt 0) {
                Write-Host "  Last lines from the mod installer:" -ForegroundColor Gray
                foreach ($l in $tail) { Write-Host ("    " + $l) -ForegroundColor DarkGray }
                break
            }
        }
    }
    Write-Host "  Most common cause: a modified or non-1.08 FEAR.exe - the mod checks" -ForegroundColor Gray
    Write-Host "  its hash and refuses to touch anything that doesn't match. Verifying" -ForegroundColor Gray
    Write-Host "  the game files in Steam usually fixes it." -ForegroundColor Gray
    Write-Host "  Full log: $MOD_LOG" -ForegroundColor DarkGray
    Write-Host ""
    $choice = ""
    while ($choice -notin @("r","R","l","L","x","X")) {
        $choice = (Read-Host "  [R] retry   [L] open the log   [X] give up").Trim()
        if ($choice -in @("l","L")) {
            try { Start-Process notepad.exe $MOD_LOG } catch {}
            $choice = ""
        }
    }
    if ($choice -in @("x","X")) {
        try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..." | Out-Null
        exit 1
    }
}
Write-OK "Mod staged successfully."

# ---- launch bat + Hub markers -------------------------------
$launchBat = Join-Path $INSTALL_DIR "Start FEAR VR.bat"
# If play.ps1 refuses to start (most often a changed FEAR.exe), the console
# would close instantly and the user sees nothing at all. Keep the window
# open on failure so the reason is readable.
# The overlay generation's play.ps1 needs BOTH the mod folder and the game
# folder - the mod's own "Start F.E.A.R. VR.cmd" passes -InstallDir AND
# -RetailRoot. Passing only -InstallDir made it exit immediately: a black
# console for a fraction of a second and nothing else.
$playArgs = "-InstallDir `"$INSTALL_DIR`""
if ($script:UseOverlayPrep -or ($INSTALL_DIR -ne $retailRoot -and (Test-Path -LiteralPath (Join-Path $retailRoot "FEAR.exe")))) {
    $playArgs += " -RetailRoot `"$retailRoot`""
}
$batBody = @(
    "@echo off",
    ("powershell -NoProfile -ExecutionPolicy Bypass -File `"" + (Join-Path $INSTALL_DIR "tools\play.ps1") + "`" " + $playArgs),
    "if errorlevel 1 (",
    "  echo.",
    "  echo F.E.A.R. VR did not start. The reason is above.",
    "  echo If the game files changed, run the F.E.A.R. installer in the Hub again.",
    "  pause",
    ")"
) -join "`r`n"
try { Set-Content -Path $launchBat -Value $batBody -Encoding ASCII -Force } catch {}

try {
    Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $INSTALL_DIR -Encoding UTF8 -Force
    Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path_dr89") -Value $INSTALL_DIR -Encoding UTF8 -Force
} catch {}
if (Test-Path -LiteralPath $launchBat) {
    try { Set-Content -Path (Join-Path $SCRIPT_DIR ".launch_exe") -Value $launchBat -Encoding UTF8 -Force } catch {}
    # The classic install.ps1 wrote "F.E.A.R. VR.lnk" to the desktop itself,
    # so the Hub deliberately stayed out of it. The OVERLAY package has no
    # install.ps1 and prepare-overlay.ps1 creates no shortcut at all - a fresh
    # install would end up with none, and anyone coming from the old layout
    # keeps a shortcut pointing at the starter in the old folder, which dies
    # instantly. So on the overlay route the Hub writes it, with the same
    # name, which replaces a stale one instead of adding a second icon.
    if ($script:UseOverlayPrep) {
        try {
            $lnk = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\F.E.A.R. VR.lnk" `
                     -TargetPath $launchBat -WorkingDir $INSTALL_DIR -IconPath (Join-Path $retailRoot "FEAR.exe")
            if ($lnk) { Write-OK "Desktop shortcut 'F.E.A.R. VR' points at the new launcher." }
        } catch { Write-Warn "Could not write the desktop shortcut - start the game from the Hub." }
    }
}
if ($relTag) {
    try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $relTag -Encoding UTF8 -Force } catch {}
    # Also next to the GAME (2026-08-20). The line above lives INSIDE the
    # Hub folder and is gone the moment a new Hub build is dropped in -
    # the next scan then finds no marker and seeds the CURRENT tag, which
    # silently swallows a pending update. The game-side stamp survives.
    try { Save-InstalledStamp -GameDir $installRoot -Version $relTag -HubDir $SCRIPT_DIR } catch {}
}

# Verify the launch route instead of assuming it. If the bat or the marker
# is missing, the Hub falls back to steam://rungameid - which starts F.E.A.R.
# FLAT. Better to say so here than to let "Start in VR" quietly open the
# desktop game.
$routeOk = $false
try {
    $markerFile = Join-Path $SCRIPT_DIR ".launch_exe"
    if ((Test-Path -LiteralPath $launchBat) -and (Test-Path -LiteralPath $markerFile)) {
        $marked = (Get-Content -LiteralPath $markerFile -Raw -ErrorAction Stop).Trim()
        $routeOk = ($marked -and (Test-Path -LiteralPath $marked))
    }
} catch { $routeOk = $false }
if ($routeOk) {
    Write-OK "'Start in VR' will run: $launchBat"
} else {
    Write-Warn "The Hub's 'Start in VR' could not be wired up."
    Write-Host "  Launch F.E.A.R. VR from the desktop shortcut the mod created," -ForegroundColor Gray
    Write-Host "  or run this file directly:" -ForegroundColor Gray
    Write-Host "  $launchBat" -ForegroundColor Gray
}
# LAST STEP BEFORE THE WORK FOLDER GOES. F.E.A.R. has several install
# routes and $INSTALL_DIR only settles at the end, so the check belongs
# here - and the archive is still in $work, which the line below removes.
# The folder to exclude is where the mod lives, which for the overlay
# route is inside the game and otherwise its own folder.
if ($INSTALL_DIR -and (Test-Path -LiteralPath $INSTALL_DIR)) {
    # Watch archive-owned VR files, not the Public Tools source modules.
    # Filtering with Test-Path here would hide a file that the scanner had
    # already removed before this line was reached.
    $avFilesOk = Confirm-PlacedFilesSurvive `
        -Paths @((Join-Path $INSTALL_DIR "bin\x64\fearvr-host.exe"), (Join-Path $INSTALL_DIR "tools\play.ps1")) `
        -GameDir $INSTALL_DIR `
        -ArchivePath $zipPath
    if (-not $avFilesOk) {
        try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}
        Write-Fail "F.E.A.R. VR could not be restored after the antivirus check."
        Pause-User "Press Enter to exit, then run the installer again." | Out-Null
        exit 1
    }
}

try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  F.E.A.R. VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
if ((Test-Path -LiteralPath $OLD_INSTALL_DIR) -and ($OLD_INSTALL_DIR -ne $INSTALL_DIR)) {
    Write-Host ""
    Write-Host "  An older install of this mod is still in your user profile:" -ForegroundColor White
    Write-Host "    $OLD_INSTALL_DIR" -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "  Leaving it there makes the Hub report F.E.A.R. as VR Ready even" -ForegroundColor White
    Write-Host "  when it is not." -ForegroundColor White
    Write-Info "It is kept to avoid removing saves, settings, or other local files."
    Write-Host "  After backing it up, you can remove it manually if it is no longer needed." -ForegroundColor Gray
    Write-Host ""
}

Write-Host "  Start your OpenXR runtime (SteamVR or Virtual Desktop) and put" -ForegroundColor White
Write-Host "  the headset on, then launch with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub or the" -ForegroundColor White
Write-Host "  'F.E.A.R. VR' desktop shortcut." -ForegroundColor White
Write-Host ""
Write-Host "  In-game: F9 recenters, F8 toggles stereo, and the ESC menu has a" -ForegroundColor Gray
Write-Host "  'VR SETTINGS' page. The full control layout is on this game's" -ForegroundColor Gray
Write-Host "  page in the Hub." -ForegroundColor Gray
Write-Host ""
Write-Host "  Yellow box around your weapon? Hold BOTH GRIPS + B for the VR" -ForegroundColor White
Write-Host "  panel, tab Collide, switch 'Show collision box' off." -ForegroundColor White
Write-Host ""
Write-Host "  The mod auto-updates: the Hub flags new beta releases as they land." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Point-man, the signal's clean. Slow it down and move." -ForegroundColor Magenta
Pause-User "Press Enter to exit" | Out-Null
