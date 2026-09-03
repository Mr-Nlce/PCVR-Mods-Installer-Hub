# ============================================================
# Cyberpunk 2077 VR Installer
# ============================================================
# Installs CyberpunkVRPort (dariulone) - an OpenXR VR mod. Since 0.1.0 it
# is a RED4ext PLUGIN, not a dxgi.dll proxy any more
# for Cyberpunk 2077 with 6-DoF motion-controlled VR hands (full-arm
# VRIK) and an in-headset F10 overlay. This is an IN-PLACE mod: it
# overlays files into the existing Steam/GOG Cyberpunk 2077 folder
# (bin\x64\... and red4ext\...). The full hands/HUD experience also
# needs two frameworks - RED4ext and Cyber Engine Tweaks (CET) - which
# this installer adds if they are not already present. Nothing is ever
# bundled; every component is downloaded at install time.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Cyberpunk 2077 VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME     = "CyberpunkVRPort v0.1.6"
$MOD_AUTHOR   = "dariulone"
$INFO_URL     = "https://github.com/dariulone/cyberpunk-vr-port"
$MOD_URL      = "https://github.com/dariulone/cyberpunk-vr-port/releases/download/0.1.6/CyberpunkVRPort-0.1.6.zip"
# Tag of the pinned fallback build above - recorded as the installed
# version when the live GitHub lookup can't be reached. Must match the
# release tag_name the Hub sees via /releases/latest (no leading "v").
$MOD_PINNED_TAG = "0.1.6"
# The author's published sha256, checked against the supplied release ZIP.
# GitHub now exposes the same digest for live release assets; the pinned
# value remains the trusted fallback if that field is absent or offline.
$MOD_PINNED_SHA = "3ccc058303812fb5525192e666ea89950735abe3a6c436e4ff8422cc5ac761e0"
$MOD_RELEASES = "https://github.com/dariulone/cyberpunk-vr-port/releases"
# Frameworks needed for the motion-controlled hands + VR HUD. Pinned to
# versions known to work with this mod build; only installed if missing.
$RED4EXT_URL  = "https://github.com/wopss/RED4ext/releases/download/v1.30.0/red4ext-1.30.0.zip"
$RED4EXT_REL  = "https://github.com/wopss/RED4ext/releases"
$CET_URL      = "https://github.com/maximegmd/CyberEngineTweaks/releases/download/v1.37.1/cet_1.37.1.zip"
$CET_REL      = "https://github.com/maximegmd/CyberEngineTweaks/releases"

# The four frameworks CyberpunkVRPort 0.1.x additionally requires (its own
# INSTALL.txt lists them next to RED4ext and CET). All four are plain
# drop-into-the-game-root archives - layouts read from the real downloads.
#   Tag       : resolved live from the /releases/latest REDIRECT - no API,
#               so the 60-calls-per-hour limit cannot break this.
#   UrlPattern: how that release names its Windows asset. {v} = tag without
#               a leading "v", {tag} = tag as-is. Verified against the
#               current release of each project.
#   Pinned    : last-known-good URL, used if the pattern ever misses.
#   Marker    : the file that proves it is installed.
$FRAMEWORKS = @(
    @{ Name = "redscript"; Repo = "jac3km4/redscript"
       UrlPattern = "https://github.com/jac3km4/redscript/releases/download/{tag}/redscript-{tag}-windows.zip"
       Pinned = "https://github.com/jac3km4/redscript/releases/download/v0.5.31/redscript-v0.5.31-windows.zip"
       Marker = "engine\tools\scc.exe" },
    @{ Name = "TweakXL"; Repo = "psiberx/cp2077-tweak-xl"
       UrlPattern = "https://github.com/psiberx/cp2077-tweak-xl/releases/download/{tag}/TweakXL-{v}.zip"
       Pinned = "https://github.com/psiberx/cp2077-tweak-xl/releases/download/v1.11.4/TweakXL-1.11.4.zip"
       Marker = "red4ext\plugins\TweakXL\TweakXL.dll" },
    @{ Name = "ArchiveXL"; Repo = "psiberx/cp2077-archive-xl"
       UrlPattern = "https://github.com/psiberx/cp2077-archive-xl/releases/download/{tag}/ArchiveXL-{v}.zip"
       Pinned = "https://github.com/psiberx/cp2077-archive-xl/releases/download/v1.27.1/ArchiveXL-1.27.1.zip"
       Marker = "red4ext\plugins\ArchiveXL\ArchiveXL.dll" },
    @{ Name = "Codeware"; Repo = "psiberx/cp2077-codeware"
       UrlPattern = "https://github.com/psiberx/cp2077-codeware/releases/download/{tag}/Codeware-{v}.zip"
       Pinned = "https://github.com/psiberx/cp2077-codeware/releases/download/v1.20.3/Codeware-1.20.3.zip"
       Marker = "red4ext\plugins\Codeware\Codeware.dll" }
)
# ============================================================
#  THE NEXUS SIDE, AS A GRAPH - NOT A LIST
# ============================================================
#  Every entry here is on Nexus, so nothing can be downloaded
#  automatically. What CAN be automated is the thinking: which
#  ones does a given mod drag in, and in what order do they have
#  to go in. Requires is followed transitively, so picking one
#  mod pulls its whole chain - the user never has to work it out.
#
#  Markers are read from the real archives, not guessed.
#
#  Phase says WHEN:
#    "before" - must be in place BEFORE the VR mod, because the
#               VR mod REPLACES two of its files (r6\input\
#               HUDitor.xml and the HUDitor persistency.json).
#               Installed afterwards, HUDitor overwrites the VR
#               bindings and the F11 editor is gone.
#    "after"  - order does not matter, so they come last.
# ============================================================
$NEXUS_MODS = @(
    # ---- the HUDitor chain: optional, and it goes FIRST ----
    @{ Name = "HUDitor"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/3315?tab=files"
       RequiredVersion = "1.1.0"
       Marker = "r6\scripts\HUDitor\HUDWidgetsManager.reds"; Phase = "before"
       Requires = @("Input Loader", "Mod Settings")
       What = "moves and resizes the HUD widgets - the only way to get them where VR needs them" },
    @{ Name = "Input Loader"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/4575?tab=files"
       RequiredVersion = "0.2.3"
       Marker = "red4ext\plugins\input_loader\input_loader.dll"; Phase = "before"
       Requires = @()
       # The port ships input files, but 0.1.6's own INSTALL.txt explicitly
       # makes Input Loader optional with HUDitor: it is needed to merge the
       # supplied HUD layout/editor bindings, not to run the VR port itself.
       What = "merges r6\input\*.xml for HUDitor's supplied VR layout and F11 editor binding" },
    @{ Name = "Mod Settings"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/4885?tab=files"
       RequiredVersion = "0.2.21"
       Marker = "red4ext\plugins\mod_settings\mod_settings.dll"; Phase = "before"
       Requires = @()
       What = "the settings panel HUDitor puts its key binding in" },

    # ---- what the VR mod itself asks for ----
    @{ Name = "Visible Bullets"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/22251?tab=files"
       RequiredVersion = "2.31"
       Marker = "archive\pc\mod\Velocity.archive"; Phase = "after"
       Requires = @()
       What = "projectiles you can actually see in flight" },
    @{ Name = "Equipment-EX"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/6945?tab=files"
       RequiredVersion = "1.2.9"
       Marker = "archive\pc\mod\EquipmentEx.archive"; Phase = "after"
       Requires = @()
       What = "extra equipment slots" },
    @{ Name = "Visual Holsters"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/21936?tab=files"
       RequiredVersion = "1.2"
       Marker = "bin\x64\plugins\cyber_engine_tweaks\mods\VisualHolster"; Phase = "after"
       Requires = @("Equipment-EX")
       What = "the visible holster the hand-to-holster grip reaches for" },
    @{ Name = "Nova Optics"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/29190?tab=files"
       RequiredVersion = "1.3.3"
       Marker = "r6\scripts\NovaOptics\NovaOptics.reds"; Phase = "after"
       Requires = @()
       What = "reworked sights, which the collimated reflex shader draws into" },

    # ---- optional extras, each with its own chain ----
    @{ Name = "Military Pistol Holsters"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/18002?tab=files"
       RequiredVersion = "1.5"
       Marker = "archive\pc\mod\scorpion_military_dual_pistol_holsters.archive"; Phase = "after"
       Requires = @("Equipment-EX", "Visual Holsters", "Zenitex Core Dependency")
       Dlc = "Phantom Liberty"
       What = "pistol holsters on the hips, so the grip has something to reach for" },
    @{ Name = "Zenitex Core Dependency"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/16356?tab=files"
       RequiredVersion = "5.1.8"
       Marker = "archive\pc\mod\#_scorpion_zenitex_core_dependency.archive"; Phase = "after"
       Requires = @()
       What = "shared assets the Scorpion holsters are built on" },
    @{ Name = "Hip Katana"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/22071?tab=files"
       RequiredVersion = "1.4"
       Marker = "archive\pc\mod\s10_eqkatana.archive"; Phase = "after"
       # The set IS a visual holster - it needs Visual Holsters to show,
       # not just the shop it is sold in.
       Requires = @("Shinobi's Black Market", "Visual Holsters")
       What = "a katana on the hip with a visual holster" },
    @{ Name = "Shinobi's Black Market"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/24833?tab=files"
       RequiredVersion = "1.5"
       Marker = "archive\pc\mod\s10_gami_shop.archive"; Phase = "after"
       Requires = @("Virtual Atelier")
       What = "the store the katana set is sold in" },
    @{ Name = "VR UI Mods"; Url = "https://github.com/nben/Cyberpunk-UI-mods-for-VR"
       # NOT Nexus and NOT a release - a plain repository. GitHub serves
       # every repo's current state as a zip at this address, so unlike
       # everything else here it can simply be fetched. Verified against
       # the same file downloaded by hand: byte for byte identical.
       DirectUrl = "https://github.com/nben/Cyberpunk-UI-mods-for-VR/archive/refs/heads/main.zip"
       RequiredVersion = ""
       # ONLY WORTH OFFERING ALONGSIDE HUDITOR: these scripts move the HUD
       # elements HUDitor cannot reach. Without HUDitor a user would be
       # moving five stragglers and nothing else.
       OnlyWith = "HUDitor"
       # !!! THE ARCHIVE HAS NO r6\scripts IN IT. A repo zip contains the
       # five script folders at its root, so copying it the usual way
       # would drop ContactMove and friends straight into the game
       # folder, where redscript never looks. They go into r6\scripts.
       IntoSub = "r6\scripts"
       SkipNames = @("README.md")
       Marker = "r6\scripts\ScannerUIMove\Hacks.reds"; Phase = "after"
       Requires = @("HUDitor")
       What = "moves the HUD elements HUDitor cannot: scanner, quickhacks, contacts, texts, tooltips, tutorials" },
    @{ Name = "Virtual Atelier"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/2987?tab=files"
       RequiredVersion = "1.6.3"
       # Read from the real 1.6.3 archive, NOT guessed: the scripts live
       # in r6\scripts\virtual-atelier-full\, and the .archive is the
       # single file that is always there whatever the script layout does.
       Marker = "archive\pc\mod\VirtualAtelier.archive"; Phase = "after"
       Requires = @("Mod Settings")
       What = "the in-game shop framework the Black Market runs on" }
)

# Follow Requires transitively and hand back the whole chain, each entry
# once, PREREQUISITES FIRST. That is the whole point: the user picks one
# mod, and what it needs underneath comes with it in a usable order.
# ONE way of installing a Nexus mod, used by BOTH blocks below.
# Written after the HUDitor block was first built differently and
# Martin rightly called it out: every other download in this Hub opens
# ONE page, then takes the file from Downloads or from a drag onto the
# window. Doing it twice, two ways, in one installer is how a user
# stops trusting either.
function Install-NexusMod {
    param($Mod, [string]$GameRoot, [string]$TempDir)

    Write-Host ""
    Write-Host "  $($Mod.Name) - $($Mod.What)" -ForegroundColor White
    Write-Host "   $($Mod.Url) " -ForegroundColor Cyan
    if (@($Mod.Requires).Count -gt 0) {
        Write-Host ("   needs: " + (@($Mod.Requires) -join ", ") + " - offered above this one") -ForegroundColor DarkGray
    }
    if ($Mod.Dlc) {
        # Say it BEFORE the download, not after it fails to load.
        Write-Host ("   REQUIRES THE " + $Mod.Dlc.ToUpper() + " DLC - skip this one if you do not own it") -ForegroundColor Yellow
    }
    $ans = Pause-User "Press Enter to $(if ($Mod.DirectUrl) { 'fetch it' } else { 'open the page' }) (or type s to skip this one)..."
    # Exactly "s" or "skip" - NOT any word starting with s. Both
    # questions use the same test, so the same typing works in both.
    if ("$ans".Trim() -match '^(?i)s(kip)?$') { Write-Info "Skipped $($Mod.Name)."; return $false }

    # A REPOSITORY CAN JUST BE FETCHED. Nexus needs a login and a browser,
    # so those open a page - but a GitHub repo zip is a plain URL, and
    # making the user click through for it would be ceremony for nothing.
    $zip = $null
    if ($Mod.DirectUrl) {
        # Invoke-WebRequest does NOT create the folder it writes into, so
        # make sure it is there. Cheap, and it survives whatever else may
        # have removed it earlier in the run.
        if (-not (Test-Path -LiteralPath $TempDir)) {
            try { New-Item -ItemType Directory -Path $TempDir -Force | Out-Null } catch {}
        }
        $tmpZip = Join-Path $TempDir ("dl_" + [System.IO.Path]::GetRandomFileName() + ".zip")
        try {
            Write-Info "Downloading $($Mod.Name)..."
            Invoke-WebRequest -Uri $Mod.DirectUrl -OutFile $tmpZip -UseBasicParsing -ErrorAction Stop
            if ((Test-Path -LiteralPath $tmpZip) -and ((Get-Item -LiteralPath $tmpZip).Length -gt 0)) {
                $zip = $tmpZip
                Write-OK "Downloaded."
            }
        } catch { Write-Warn "Download failed: $($_.Exception.Message)" }
        if (-not $zip) {
            Write-Host "  Opening the page instead - download it and drop it here." -ForegroundColor Gray
            try { Start-Process $Mod.Url } catch { }
        }
    } else {
        try { Start-Process $Mod.Url } catch { }
    }

    # Downloads folder next - after a Nexus download the file is usually
    # right there, and picking it beats asking the user to go and find it.
    $dl  = Join-Path $env:USERPROFILE "Downloads"
    if (-not $zip -and (Test-Path -LiteralPath $dl)) {
        # THE NEXUS MOD ID IS THE RELIABLE KEY. Nexus puts it in every
        # file name, and it never changes. Matching on our DISPLAY name
        # fails whenever the author named the file differently -
        # "Shinobi's Black Market" ships as shinobi_shop_24833_..., so
        # the name match found nothing and the mod went uninstalled.
        $modId = ([regex]::Match([string]$Mod.Url, '/mods/(\d+)')).Groups[1].Value
        $key   = ($Mod.Name -replace '[^A-Za-z]', '')
        $files = @(Get-ChildItem -LiteralPath $dl -Filter "*.zip" -File -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending)

        $cand = $null
        if ($modId) {
            # The id sits between separators, so 24833 cannot match 2483 or 248330.
            $cand = $files | Where-Object { $_.Name -match ("(?<![0-9])" + [regex]::Escape($modId) + "(?![0-9])") } | Select-Object -First 1
        }
        if (-not $cand -and $key) {
            $cand = $files | Where-Object { ($_.Name -replace '[^A-Za-z]', '') -match "(?i)$key" } | Select-Object -First 1
        }
        if (-not $cand -and $Mod.Marker) {
            # Last resort: open them and look for the payload itself.
            $leaf = Split-Path -Leaf $Mod.Marker
            foreach ($f in $files) {
                if (Test-ArchiveContains -ArchivePath $f.FullName -Entry $leaf) { $cand = $f; break }
            }
        }
        if ($cand) {
            Write-OK "Found in Downloads: $($cand.Name)"
            $zip = $cand.FullName
        }
    }
    while (-not $zip) {
        $inp = (Read-Host "  Drag the $($Mod.Name) .zip here and press Enter (or type s to skip)").Trim().Trim('"')
        # "s" is the documented way out, the same as the question above.
        # An empty line still works too - someone who just hits Enter
        # here means the same thing, and refusing it would trap them.
        if (-not $inp -or $inp -match '^(?i)s(kip)?$') { break }
        if (Test-Path -LiteralPath $inp) { $zip = $inp } else { Write-Fail "Not found: $inp" }
    }
    if (-not $zip) { Write-Info "Skipped $($Mod.Name)."; return $false }

    $exDir = Join-Path $TempDir ("nx_" + [System.IO.Path]::GetRandomFileName())
    try {
        New-Item -ItemType Directory -Path $exDir -Force | Out-Null
        Expand-Archive -LiteralPath $zip -DestinationPath $exDir -Force -ErrorAction Stop
        # A Nexus ZIP may wrap everything in one folder.
        $root = Get-ExtractedPayloadRoot -ExtractDir $exDir -RelModFile $Mod.Marker -Markers @("bin","red4ext","r6","archive","engine","mods")

        # Loose files the mod ships for humans, not for the game.
        foreach ($sk in @($Mod.SkipNames)) {
            if (-not $sk) { continue }
            $skp = Join-Path $root $sk
            if (Test-Path -LiteralPath $skp) { Remove-Item -LiteralPath $skp -Force -ErrorAction SilentlyContinue }
        }

        # Most archives already carry their own bin\, r6\ and archive\
        # folders and land straight in the game root. One that does not
        # says where it belongs.
        $dst = $GameRoot
        if ($Mod.IntoSub) {
            $dst = Join-Path $GameRoot $Mod.IntoSub
            if (-not (Test-Path -LiteralPath $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }
        }
        # !!! THE ARCHIVE IS CHECKED BEFORE ANYTHING IS COPIED.
        # This used to run AFTER Copy-Tree, and looked for the marker in
        # the GAME folder - where an earlier install may have left one.
        # A wrong ZIP with the right mod id in its name therefore had its
        # payload merged into the game and was then reported as a success
        # it had nothing to do with. Now the EXTRACTED folder must carry
        # the marker itself, and nothing is copied until it does.
        $srcMarker = $Mod.Marker
        if ($Mod.IntoSub -and $srcMarker.StartsWith($Mod.IntoSub, [StringComparison]::OrdinalIgnoreCase)) {
            # The archive holds the payload WITHOUT the target subfolder.
            $srcMarker = $srcMarker.Substring($Mod.IntoSub.Length).TrimStart('\')
        }
        if (-not (Test-Path -LiteralPath (Join-Path $root $srcMarker))) {
            Write-Fail "$($Mod.Name): that archive does not contain $srcMarker"
            Write-Host "  Nothing was copied. Either it is the wrong file, or the mod" -ForegroundColor Gray
            Write-Host "  changed its layout - what the archive actually holds:" -ForegroundColor Gray
            foreach ($t in @(Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue | Select-Object -First 8)) {
                Write-Host "    $($t.Name)" -ForegroundColor DarkGray
            }
            return $false
        }

        Copy-Tree -Src $root -Dst $dst
        if (Test-Path (Join-Path $GameRoot $Mod.Marker)) { Write-OK "$($Mod.Name) installed."; return $true }
        # The archive had it and the copy did not land it - a permission
        # problem or a locked file, not a wrong download.
        Write-Fail "$($Mod.Name): copied, but $($Mod.Marker) is not in the game folder."
        return $false
    } catch {
        Write-Fail "$($Mod.Name) could not be installed: $($_.Exception.Message)"
        return $false
    }
}

function Get-NexusChain {
    param([string[]]$Names)
    $out = New-Object System.Collections.ArrayList
    $seen = @{}
    function Add-One {
        param([string]$n)
        if ($seen.ContainsKey($n)) { return }
        $seen[$n] = $true
        $m = $NEXUS_MODS | Where-Object { $_.Name -eq $n } | Select-Object -First 1
        if (-not $m) { return }
        foreach ($r in @($m.Requires)) { Add-One $r }   # needs first
        [void]$out.Add($m)
    }
    foreach ($n in $Names) { Add-One $n }
    return @($out)
}

$STEAM_FOLDER = "Cyberpunk 2077"
$CP_APPID     = "1091500"
$GAME_EXE_REL = "bin\x64\Cyberpunk2077.exe"
# Since 0.1.0 the mod loads through RED4ext instead of proxying dxgi.dll.
# This file is what proves the VR mod is installed.
$MOD_MARKER   = "red4ext\plugins\CyberpunkVR_Stereo\CyberpunkVR_Stereo.dll"
# A leftover dxgi.dll from an older CyberpunkVRPort or from R.E.A.L. VR must
# go: the mod's own INSTALL.txt says two VR paths fight over the same hooks.
$OLD_PROXY    = "bin\x64\dxgi.dll"
$RED4EXT_MARK = "red4ext\RED4ext.dll"
$CET_MARK     = "bin\x64\plugins\cyber_engine_tweaks.asi"
$GOG_ROOTS = @(
    "HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games",
    "HKLM:\SOFTWARE\GOG.com\Games"
)

# ---- Inline console helpers (per-installer; NOT shared) -----
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  Cyberpunk 2077 VR Installer" -ForegroundColor Yellow
    Write-Host "  Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Info { param($x) Write-Host "  [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host "  [XX] $x" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

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
# A valid Cyberpunk 2077 root is the folder that contains bin\x64\Cyberpunk2077.exe.
function Test-CP2077Root {
    param([string]$Root)
    if (-not $Root) { return $false }
    return (Test-Path (Join-Path $Root $GAME_EXE_REL))
}
# Merge-copy every file under $Src into $Dst, preserving the relative
# folder layout (creating folders as needed, overwriting existing files).
# FILES THE PORT REPLACES THAT ARE SOMEBODY ELSE'S WORK. The mod's own
# INSTALL.txt says outright that these two are REPLACED, and a HUD layout
# is something a user may have spent an evening arranging. Overwriting it
# with no way back is not ours to do, so the first time each is replaced
# a .pre-vr backup is kept beside it.
# ONLY THE FIRST TIME: a second run would otherwise overwrite the backup
# with the VR layout and destroy the very thing it preserves.
$script:BackupBeforeOverwrite = @(
    "bin\x64\plugins\cyber_engine_tweaks\mods\HUDitor\persistency.json",
    "r6\input\HUDitor.xml"
)

function Copy-Tree {
    param([string]$Src, [string]$Dst)
    $base = (Resolve-Path $Src).Path.TrimEnd('\')
    Get-ChildItem -Path $base -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $rel = $_.FullName.Substring($base.Length).TrimStart('\')
        $target = Join-Path $Dst $rel
        $tdir = Split-Path $target -Parent
        if ($tdir -and -not (Test-Path $tdir)) { New-Item -ItemType Directory -Path $tdir -Force | Out-Null }
        if (($script:BackupBeforeOverwrite -contains $rel) -and (Test-Path -LiteralPath $target)) {
            $bak = "$target.pre-vr"
            if (-not (Test-Path -LiteralPath $bak)) {
                try {
                    Copy-Item -LiteralPath $target -Destination $bak -Force -ErrorAction Stop
                    Write-Info "Kept your $rel as $(Split-Path -Leaf $bak)"
                } catch { Write-Warn "Could not back up $rel - it will be replaced." }
            }
        }
        Copy-Item -Path $_.FullName -Destination $target -Force
    }
}

# Resolve the latest CyberpunkVRPort release straight from GitHub so each
# install pulls the newest build (the mod updates often). Uses the same
# endpoint the Hub's update check uses (/releases/latest) so the recorded
# version and the Hub's "Update" detection always agree. Returns
# @{ Url; Tag; Sha } or $null on any failure (rate limit, offline, no asset) -
# the caller then falls back to the pinned known-good build.
function Resolve-LatestModUrl {
    try {
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
        $headers = @{ "User-Agent" = "PCVR-Mods-Hub"; "Accept" = "application/vnd.github+json" }
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/dariulone/cyberpunk-vr-port/releases/latest" -Headers $headers -TimeoutSec 20 -ErrorAction Stop
        if (-not $rel) { return $null }
        $asset = $rel.assets | Where-Object { $_.name -match '(?i)^CyberpunkVRPort.*\.zip$' } | Select-Object -First 1
        if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -match '(?i)\.zip$' } | Select-Object -First 1 }
        if ($asset -and $asset.browser_download_url) {
            $sha = ""
            if ($asset.digest -and ([string]$asset.digest) -match '^(?i)sha256:([0-9a-f]{64})$') { $sha = $Matches[1].ToLower() }
            return @{ Url = $asset.browser_download_url; Tag = $rel.tag_name; Sha = $sha }
        }
    } catch {}
    return $null
}

# -------------------------------------------------------
# Resolve the live release version up front, so the header line and the
# final summary both show the exact build being installed (not the pinned
# fallback). The result is re-used in STEP 3 - only one GitHub call. The
# notice below is transient: Write-Header clears the screen right after.
# -------------------------------------------------------
Write-Host "  Checking latest CyberpunkVRPort version..." -ForegroundColor DarkGray
$latest = Resolve-LatestModUrl
$installedTag = $MOD_PINNED_TAG
if ($latest -and $latest.Tag) { $installedTag = $latest.Tag }
$MOD_NAME = "CyberpunkVRPort v$installedTag"

# -------------------------------------------------------
# STEP 1: Locate Cyberpunk 2077
# -------------------------------------------------------
Write-Header


Write-Step 1 4 "Locating Cyberpunk 2077"

$gameRoot = $null

$steamPath = Get-SteamPath
if ($steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $root = Join-Path $lib "steamapps\common\$STEAM_FOLDER"
        if (Test-CP2077Root $root) { $gameRoot = $root; Write-Info "Found via Steam: $gameRoot"; break }
    }
}

if (-not $gameRoot) { $gameRoot = Find-SteamGameFolder -AppId "1091500" -SteamFolderNames @("Cyberpunk 2077") -GogNames @("Cyberpunk 2077") -EpicNames @("Cyberpunk 2077") }
if (-not $gameRoot) {
    foreach ($reg in $GOG_ROOTS) {
        try {
            Get-ChildItem -Path $reg -ErrorAction Stop | ForEach-Object {
                if ($gameRoot) { return }
                try {
                    $gogPath = (Get-ItemProperty -Path $_.PSPath -ErrorAction Stop).path
                    if ($gogPath -and (Test-CP2077Root $gogPath)) { $gameRoot = $gogPath; Write-Info "Found via GOG: $gameRoot" }
                } catch {}
            }
        } catch {}
        if ($gameRoot) { break }
    }
    # Common GOG default if the registry scan missed it.
    if (-not $gameRoot) {
        $gogDefault = "C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077"
        if (Test-CP2077Root $gogDefault) { $gameRoot = $gogDefault; Write-Info "Found via GOG default path: $gameRoot" }
    }
}

if (-not $gameRoot) {
    Write-Warn "Cyberpunk 2077 was not found automatically."
    Write-Host "  You need Cyberpunk 2077 installed (Steam or GOG)." -ForegroundColor White
    Write-Host "  Steam store / install:  https://store.steampowered.com/app/$CP_APPID/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [O] Open the Steam install page   [P] Enter the game folder manually" -ForegroundColor White
    $pick = ""
    while ($pick -notin @("o","O","p","P")) { $pick = (Read-Host "  Choice (O/P)").Trim() }
    if ($pick -in @("o","O")) {
        try { Start-Process "steam://install/$CP_APPID" } catch { try { Start-Process "https://store.steampowered.com/app/$CP_APPID/" } catch {} }
        Pause-User "Install Cyberpunk 2077, then press Enter to continue..."
        if ($steamPath) {
            foreach ($lib in (Get-SteamLibraries $steamPath)) {
                $root = Join-Path $lib "steamapps\common\$STEAM_FOLDER"
                if (Test-CP2077Root $root) { $gameRoot = $root; Write-Info "Found: $gameRoot"; break }
            }
        }
    }
    while (-not $gameRoot) {
        Write-Host "  Enter the Cyberpunk 2077 folder (the one that holds bin\x64\Cyberpunk2077.exe):" -ForegroundColor White
        Write-Host "    Steam: C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077" -ForegroundColor Gray
        Write-Host "    GOG:   C:\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077" -ForegroundColor Gray
        $r = (Read-Host "  Path").Trim().Trim('"')
        if (Test-CP2077Root $r) { $gameRoot = $r; Write-Info "Path set: $gameRoot" }
        else { Write-Fail "Cyberpunk2077.exe not found under bin\x64 at: $r" }
    }
}

$tempDir = Join-Path $env:TEMP "CP2077VRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Download a zip (with mirrors + manual fallback) and overlay it into the
# game folder. Returns $true on success.
function Install-Component {
    param([string]$Label, [string[]]$Urls, [string]$ManualUrl, [string]$ManualName, [string]$PayloadRelFile = "", [string]$ExpectedSha = "")
    $tmpZip = Join-Path $tempDir ("dl_" + [System.IO.Path]::GetRandomFileName() + ".zip")
    $null = Invoke-SafeDownload -Urls $Urls -Destination $tmpZip -Label $Label `
                -ManualUrl $ManualUrl `
                -Instructions "Download $ManualName from the page that opened and drop it into the opened folder, then choose Retry." `
                -SkipMessage "Skipped - $Label was NOT installed."
    if (-not (Test-Path $tmpZip)) { return $false }

    # A PUBLISHED HASH IS ONLY WORTH ANYTHING IF IT IS CHECKED. For a live
    # GitHub release this is the asset digest; for the offline fallback it
    # is the author's published digest recorded above.
    if ($ExpectedSha) {
        try {
            $got = (Get-FileHash -LiteralPath $tmpZip -Algorithm SHA256 -ErrorAction Stop).Hash
            if ($got -and ($got.ToLower() -ne $ExpectedSha.ToLower())) {
                Write-Fail "$Label : the download does not match the published checksum."
                Write-Host "    expected $ExpectedSha" -ForegroundColor DarkGray
                Write-Host "    got      $($got.ToLower())" -ForegroundColor DarkGray
                Write-Host "    Nothing was installed." -ForegroundColor Gray
                return $false
            }
            Write-OK "Checksum verified."
        } catch { Write-Warn "Could not check the checksum - carrying on." }
    }

    $exDir = Join-Path $tempDir ("ex_" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $exDir -Force | Out-Null
    $res = Expand-ArchiveOrFallback -ArchivePath $tmpZip -DestinationFolder $exDir -Label $Label `
               -SkipMessage "Skipped - $Label was NOT extracted."
    if ([string]$res -eq "quit" -or [string]$res -eq "skip") { return $false }
    # AND THE REAL TEST IS WHETHER ANYTHING CAME OUT. Only "quit" used to
    # count as failure, so a skipped extraction copied an EMPTY folder and
    # still reported the component installed. Checking the folder instead
    # of the return value cannot misfire, whatever the helper reports.
    if (-not (Get-ChildItem -LiteralPath $exDir -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)) {
        Write-Fail "$Label : nothing was extracted."
        return $false
    }
    # Layout-change-proof: locate the real payload level (a mod ZIP may
    # wrap everything in a top-level folder, e.g. CyberpunkVRPort-0.0.9\),
    # preferring the known mod file's relative path when provided.
    $payloadRoot = Get-ExtractedPayloadRoot -ExtractDir $exDir -RelModFile $PayloadRelFile -Markers @("bin","red4ext","r6","archive","engine","mods")
    # THE PAYLOAD HAS TO CONTAIN WHAT WE CAME FOR, checked BEFORE copying.
    # Otherwise a wrong archive is merged into the game folder and, if the
    # marker happens to be there already from an earlier install, reported
    # as a success it had nothing to do with.
    if ($PayloadRelFile -and -not (Test-Path -LiteralPath (Join-Path $payloadRoot $PayloadRelFile))) {
        Write-Fail "$Label : that archive does not contain $PayloadRelFile - nothing was copied."
        return $false
    }
    try { Copy-Tree -Src $payloadRoot -Dst $gameRoot } catch { Write-Fail "Copy failed: $($_.Exception.Message)"; return $false }
    if ($PayloadRelFile -and -not (Test-Path -LiteralPath (Join-Path $gameRoot $PayloadRelFile))) {
        Write-Fail "$Label : copied, but $PayloadRelFile is not in the game folder."
        return $false
    }
    return $true
}

# -------------------------------------------------------
# STEP 2: Frameworks (RED4ext + CET) - only if missing
# -------------------------------------------------------
# What version is the framework that is ALREADY there? Read it off the
# file itself - these are signed binaries and carry a file version.
function Get-InstalledFrameworkVersion {
    param([string]$Path)
    try {
        if (-not (Test-Path -LiteralPath $Path)) { return $null }
        $fv = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Path)
        foreach ($cand in @($fv.ProductVersion, $fv.FileVersion)) {
            if ($cand) {
                # "1.37.1.0" and "1.37.1+build" both reduce to 1.37.1
                $m = [regex]::Match(([string]$cand), '\d+(\.\d+)+')
                if ($m.Success) { return $m.Value }
            }
        }
    } catch {}
    return $null
}

# ---- Game version -------------------------------------------
# THE PORT IS BUILT AGAINST ONE GAME BUILD. Its engine offsets are
# addresses in a specific Cyberpunk2077.exe - on a different patch they
# point at whatever now lives there, which does not announce itself. It
# fails quietly, or crashes, and neither says why.
$REQUIRED_GAME_VERSION = "2.31"
$gameExePath = Join-Path $gameRoot $GAME_EXE_REL
$gameVer = Get-InstalledFrameworkVersion -Path $gameExePath
if ($gameVer) {
    # Compare only major.minor - the build digits move with hotfixes that
    # do not shift the offsets.
    $short = ([regex]::Match($gameVer, '^\d+\.\d+')).Value
    if ($short -eq $REQUIRED_GAME_VERSION) {
        Write-OK "Cyberpunk 2077 $gameVer - the version this port is built for."
    } else {
        Write-Host ""
        Write-Warn "YOUR GAME IS $gameVer - THIS PORT IS BUILT FOR $REQUIRED_GAME_VERSION."
        Write-Host "    The port hooks the engine at fixed addresses. On another patch" -ForegroundColor White
        Write-Host "    those addresses hold something else: expect it to do nothing, or" -ForegroundColor White
        Write-Host "    to crash, with no message telling you why." -ForegroundColor White
        Write-Host ""
        $vAns = ""
        for ($k = 1; $k -le 20; $k++) {
            $vAns = ("" + (Read-Host "  Install anyway? [y/n]")).Trim().ToLower()
            if ($vAns -in @("y","n","yes","no")) { break }
            Write-Host "  Please answer y or n." -ForegroundColor Yellow
        }
        if ($vAns -notin @("y","yes")) {
            Write-Info "Stopped - nothing was changed."
            Pause-User "Press Enter to exit."
            exit 0
        }
    }
} else {
    Write-Warn "Could not read the game's version - carrying on. This port needs $REQUIRED_GAME_VERSION."
}

# The update notice belongs BEFORE the question, not after it: it is
# part of what the user is deciding about. Its result also decides
# whether the prompt says "installation" or "installation / Update".
$__modPresent = Test-Path (Join-Path $gameRoot $MOD_MARKER)
$null = Show-UpdateNoticeIfInstalled -TargetDir $gameRoot -RelModFile $MOD_MARKER -Label "CyberpunkVRPort"

# ---- Normal run, or repair? -----------------------------------
# WHY REPAIR EXISTS: someone who installed months ago may be sitting on
# framework and Nexus mods that have since moved on. Most of those carry
# no readable version at all - a .archive or a .reds file simply does not
# have one - so the installer CANNOT tell whether they are current. It
# would happily skip every one of them as "already present" and leave the
# setup broken in a way nobody can see.
#
# Repair sidesteps the whole question: it stops treating anything as
# already done and offers every piece again. Slower, and the honest way
# out when the state on disk cannot be inspected.
Write-Host ""
Write-Host " >>> Press Enter to start the installation$(if ($__modPresent) { ' / Update' }) " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     or press R and Enter for Repair, in case of issues" -ForegroundColor DarkGray
Write-Host ""
$global:RepairMode = $false
# Read-Host ALWAYS prints its argument followed by a colon. Passing "  "
# put a bare "  :" on its own line under the two lines above, which read
# like the installer had stopped with nothing left to say. A short label
# gives the colon something to belong to.
$__ans = ("" + (Read-Host "     Enter or R")).Trim()
if ($__ans -match '^(?i)r') {
    $global:RepairMode = $true
    Write-Host ""
    Write-Host "  REPAIR: nothing is treated as already installed. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
    Write-Host "  Every framework, every mod and the VR mod itself are offered" -ForegroundColor White
    Write-Host "  again, so whatever is on disk ends up current. Takes longer." -ForegroundColor Gray
    Write-Host ""
}

Write-Step 2 4 "Frameworks (RED4ext + Cyber Engine Tweaks)"
Write-Host "  These power the motion-controlled hands and the VR HUD." -ForegroundColor Gray
Write-Host "  Installed only if you don't already have them." -ForegroundColor Gray
Write-Host ""

$red4extState = "present"
if (-not $global:RepairMode -and (Test-Path (Join-Path $gameRoot $RED4EXT_MARK))) {
    Write-OK "RED4ext already present - keeping your install."
} else {
    Write-Host "  Installing RED4ext (v1.30.0) ..." -ForegroundColor White
    if (Install-Component -Label "RED4ext" -Urls @($RED4EXT_URL) -ManualUrl $RED4EXT_REL -ManualName "red4ext-1.30.0.zip") {
        Write-OK "RED4ext installed."; $red4extState = "installed"
    } else { Write-Warn "RED4ext was not installed - VR hands/HUD may not load (camera/stereo will still work)."; $red4extState = "missing" }
}

$cetState = "present"
if (-not $global:RepairMode -and (Test-Path (Join-Path $gameRoot $CET_MARK))) {
    Write-OK "Cyber Engine Tweaks already present - keeping your install."
} else {
    Write-Host "  Installing Cyber Engine Tweaks (v1.37.1) ..." -ForegroundColor White
    if (Install-Component -Label "Cyber Engine Tweaks" -Urls @($CET_URL) -ManualUrl $CET_REL -ManualName "cet_1.37.1.zip") {
        Write-OK "Cyber Engine Tweaks installed."; $cetState = "installed"
    } else { Write-Warn "CET was not installed - VR hands/HUD may not load (camera/stereo will still work)."; $cetState = "missing" }
}

# The four frameworks the mod additionally needs since 0.1.x. Each is only
# fetched when its marker file is missing, so a machine that already has a
# modded Cyberpunk downloads nothing here.
#
# The tag comes from the /releases/latest REDIRECT, not from the GitHub API:
# the redirect has no hourly limit, so a busy API cannot leave the user with
# a half-installed setup. The pinned URL stays behind it as a fallback, and
# behind that the normal manual route of Install-Component.
function Get-LatestTagByRedirect {
    param([string]$Repo)
    try {
        $url = "https://github.com/$Repo/releases/latest"
        $req = [System.Net.HttpWebRequest]::Create($url)
        $req.Method = "HEAD"
        $req.AllowAutoRedirect = $false
        $req.UserAgent = "PCVR-Mods-Hub"
        $req.Timeout = 15000
        $resp = $req.GetResponse()
        $loc  = $resp.Headers["Location"]
        $resp.Close()
        if ($loc -and $loc -match '/tag/(.+)$') { return $Matches[1] }
    } catch { }
    return $null
}

# A plain numeric comparison, kept LOCAL on purpose: the Hub's full
# Test-OnlineVersionIsNewer lives in Helpers.ps1, which no installer
# loads - pulling a whole module in for one comparison would be worse
# than these ten lines. Both sides here are dotted release numbers
# (1.37.1 against v1.38.0), so nothing more is needed.
# HOW FAR BEHIND IS TOO FAR? Nexus shows which version is current, but
# never says from which one a mod breaks. So a single release behind is
# not worth nagging about - it usually still works. Two or more is where
# a dependency chain starts to fall apart, and that is what gets flagged.
# Compares the LAST numeric part; a jump in an earlier part (1.2.x to
# 1.3.x) always counts.
function Test-FarEnoughBehind {
    param([string]$Installed, [string]$Required, [int]$Slack = 2)
    if (-not $Installed -or -not $Required) { return $false }
    $a = ([regex]::Match($Installed, '\d+(\.\d+)*')).Value
    $b = ([regex]::Match(($Required -replace '^[vV]', ''), '\d+(\.\d+)*')).Value
    if (-not $a -or -not $b) { return $false }
    $pa = @($a -split '\.' | ForEach-Object { [int]$_ })
    $pb = @($b -split '\.' | ForEach-Object { [int]$_ })
    $n = [Math]::Max($pa.Count, $pb.Count)
    for ($i = 0; $i -lt $n; $i++) {
        $x = if ($i -lt $pa.Count) { $pa[$i] } else { 0 }
        $y = if ($i -lt $pb.Count) { $pb[$i] } else { 0 }
        if ($y -gt $x) {
            # An earlier part moved - always far enough.
            if ($i -lt $n - 1) { return $true }
            return (($y - $x) -ge $Slack)
        }
        if ($y -lt $x) { return $false }
    }
    return $false
}

function Test-FrameworkOutdated {
    param([string]$Installed, [string]$Online)
    if (-not $Installed -or -not $Online) { return $false }
    $a = ([regex]::Match($Installed, '\d+(\.\d+)*')).Value
    $b = ([regex]::Match(($Online -replace '^[vV]', ''), '\d+(\.\d+)*')).Value
    if (-not $a -or -not $b) { return $false }
    $pa = @($a -split '\.' | ForEach-Object { [int]$_ })
    $pb = @($b -split '\.' | ForEach-Object { [int]$_ })
    for ($i = 0; $i -lt [Math]::Max($pa.Count, $pb.Count); $i++) {
        $x = if ($i -lt $pa.Count) { $pa[$i] } else { 0 }
        $y = if ($i -lt $pb.Count) { $pb[$i] } else { 0 }
        if ($y -gt $x) { return $true }
        if ($y -lt $x) { return $false }
    }
    return $false
}


$fwStates = @{}
foreach ($fw in $FRAMEWORKS) {
    # In repair mode nothing counts as done - fall through and reinstall.
    if (-not $global:RepairMode -and (Test-Path (Join-Path $gameRoot $fw.Marker))) {
        # !!! PRESENT IS NOT THE SAME AS CURRENT (2026-08-24). These
        # frameworks depend on each other BY VERSION - the VR mod needs
        # Codeware 1.20+, CET and RED4ext have to match the game patch.
        # Keeping an old build silently is how "everything is installed
        # and nothing works" happens. So: if it is older than what is
        # published, say so and offer the update.
        $haveVer = Get-InstalledFrameworkVersion -Path (Join-Path $gameRoot $fw.Marker)
        $liveTag = Get-LatestTagByRedirect -Repo $fw.Repo
        $outdated = $false
        if ($haveVer -and $liveTag) {
            try { $outdated = Test-FrameworkOutdated -Installed $haveVer -Online $liveTag } catch {}
        }
        if ($outdated) {
            Write-Warn "$($fw.Name) $haveVer is installed, but $liveTag is out."
            Write-Host "  These frameworks depend on each other by version - an old" -ForegroundColor Gray
            Write-Host "  one is a common reason the VR mod's scripts do not load." -ForegroundColor Gray
            Write-Host ""
            $upd = ""
            for ($k = 1; $k -le 20; $k++) {
                $upd = ("" + (Read-Host "  Update $($fw.Name) to $liveTag now? [y/n]")).Trim().ToLower()
                if ($upd -in @("y","n","yes","no")) { break }
                Write-Host "  Please answer y or n." -ForegroundColor Yellow
            }
            if ($upd -in @("y","yes")) {
                # SAME REASONING AS THE VR MOD BELOW: the live URL alone,
                # so a fallback to the pinned build cannot be reported as
                # the live version. Only the live one is tried here - the
                # pinned build is already what is on disk.
                $uurls = @(($fw.UrlPattern -replace '\{tag\}', $liveTag -replace '\{v\}', $liveTag.TrimStart("v")))
                if (Install-Component -Label "$($fw.Name) $liveTag" -Urls $uurls -ManualUrl "https://github.com/$($fw.Repo)/releases" -ManualName "the latest $($fw.Name) .zip") {
                    Write-OK "$($fw.Name) updated to $liveTag."
                    $fwStates[$fw.Name] = "installed"
                    continue
                }
                Write-Warn "$($fw.Name) could not be updated - keeping $haveVer."
            }
        } else {
            $vtxt = if ($haveVer) { " ($haveVer)" } else { "" }
            Write-OK "$($fw.Name)$vtxt already present - keeping your install."
        }
        $fwStates[$fw.Name] = "present"
        continue
    }
    $urls = @()
    $tag  = Get-LatestTagByRedirect -Repo $fw.Repo
    if ($tag) {
        $ver = $tag.TrimStart("v")
        $urls += ($fw.UrlPattern -replace '\{tag\}', $tag -replace '\{v\}', $ver)
        Write-Host "  Installing $($fw.Name) ($tag) ..." -ForegroundColor White
    } else {
        Write-Host "  Installing $($fw.Name) (known build - GitHub not reachable) ..." -ForegroundColor White
    }
    if ($urls -notcontains $fw.Pinned) { $urls += $fw.Pinned }
    if (Install-Component -Label $fw.Name -Urls $urls -ManualUrl "https://github.com/$($fw.Repo)/releases" -ManualName "the latest $($fw.Name) .zip") {
        Write-OK "$($fw.Name) installed."
        $fwStates[$fw.Name] = "installed"
    } else {
        Write-Warn "$($fw.Name) was not installed - the VR mod's scripts will not load without it."
        $fwStates[$fw.Name] = "missing"
    }
}

# -------------------------------------------------------
# STEP 2b: HUDitor - OPTIONAL, and it has to happen NOW
# -------------------------------------------------------
#  !!! THE ORDER IS NOT A PREFERENCE HERE. The VR mod ships its
#  own r6\input\HUDitor.xml and HUDitor's persistency.json and
#  REPLACES both. Install HUDitor afterwards and it writes its
#  files back over them: the F11 editor binding is gone and the
#  VR HUD layout is lost. So it is offered here, before the VR
#  mod, or not at all this run.
# -------------------------------------------------------
$hudChain = Get-NexusChain -Names @("HUDitor")
$hudMissing = @($hudChain | Where-Object { $global:RepairMode -or -not (Test-Path (Join-Path $gameRoot $_.Marker)) })

if ($hudMissing.Count -gt 0) {
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
    Write-Host " HUDitor - optional, and it has to go in NOW" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Moves the HUD into view. The VR mod overwrites its files," -ForegroundColor Gray
    Write-Host "  so installed afterwards it stops working." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  For each one the page opens; download the file and drop it here." -ForegroundColor Gray
    Write-Host "  Type s and Enter to skip one." -ForegroundColor Gray

    foreach ($m in $hudMissing) {
        [void](Install-NexusMod -Mod $m -GameRoot $gameRoot -TempDir $tempDir)
    }
}

# -------------------------------------------------------
# STEP 3: CyberpunkVRPort (the VR mod itself) - latest release
# -------------------------------------------------------
Write-Host " CyberpunkVRPort by dariulone - a RED4ext plugin that puts Cyberpunk" -ForegroundColor White
Write-Host " 2077 in VR: real stereo, 6DoF hands (full-arm VRIK) and head tracking." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start the installation..."

Write-Step 3 4 "Installing CyberpunkVRPort (latest release)"

# A dxgi.dll in bin\x64 is either an OLD CyberpunkVRPort (pre-0.1.0, when the
# mod still proxied dxgi) or R.E.A.L. VR. Either way it hooks the same engine
# entry points as the new plugin, and the mod's own INSTALL.txt says the two
# fight over them. Move it aside instead of deleting - it is not our file.
$oldProxyPath = Join-Path $gameRoot $OLD_PROXY
$script:ParkedProxy = $null
if (Test-Path -LiteralPath $oldProxyPath) {
    # NOT NECESSARILY AN OLD VR PROXY. Anything can be a dxgi.dll -
    # ReShade and other wrappers use the same filename - so say what is
    # happening rather than assert what the file is. It is moved because
    # two things owning that name fight over the same hooks, whatever the
    # other one is.
    Write-Warn "A dxgi.dll is in bin\x64 - an old VR proxy, ReShade or another wrapper."
    Write-Host "    Only one thing can own that filename, so it is moved aside." -ForegroundColor Gray
    $stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
    $parked = "$oldProxyPath.disabled-$stamp"
    try {
        Move-Item -LiteralPath $oldProxyPath -Destination $parked -Force -ErrorAction Stop
        # Remembered so it can be put back if the install then fails -
        # otherwise a failed download leaves the user's ReShade disabled
        # and nothing to show for it.
        $script:ParkedProxy = @{ From = $parked; To = $oldProxyPath }
        Write-OK "Moved aside: dxgi.dll.disabled-$stamp (rename it back to undo)"
    } catch {
        Write-Fail "Could not move it: $($_.Exception.Message)"
        Write-Host "    Move bin\x64\dxgi.dll out of the folder yourself, then run this again." -ForegroundColor Yellow
        Pause-User "Press Enter to continue anyway..."
    }
}

Write-Info "Checking GitHub for the latest CyberpunkVRPort release..."
# $latest / $installedTag were already resolved up front (for the header
# line); re-use them here so there is only one GitHub call per run.
$modUrls = @()
if ($latest -and $latest.Url) {
    Write-OK "Latest release: $installedTag"
    $modUrls += $latest.Url
} else {
    Write-Warn "Could not query GitHub (rate limit or offline) - using the known build $MOD_PINNED_TAG."
    # !!! WITHOUT THIS THE ARRAY STAYS EMPTY and Invoke-SafeDownload's
    # mandatory -Urls gets @() - a parameter binding error on PowerShell
    # 5.1, so the fallback that this branch exists for is never reached.
    $modUrls += $MOD_URL
    $installedTag = $MOD_PINNED_TAG
}
# !!! THE FALLBACK IS TRIED SEPARATELY, ON PURPOSE.
# Handing both URLs to one call meant that when the LATEST download failed
# and the pinned build installed instead, the run still recorded the
# latest tag as installed - so the tile showed no update, for a build the
# user does not actually have. Two calls, and the tag follows whichever
# one really landed.
$liveSha = if ($latest -and $latest.Sha) { [string]$latest.Sha } else { "" }
$modOk = Install-Component -Label "CyberpunkVRPort $installedTag" -Urls $modUrls -ManualUrl $MOD_RELEASES -ManualName "the latest CyberpunkVRPort .zip" -PayloadRelFile $MOD_MARKER -ExpectedSha $liveSha
if (-not $modOk -and ($modUrls -notcontains $MOD_URL)) {
    Write-Warn "The $installedTag download did not work - falling back to the known build $MOD_PINNED_TAG."
    $modOk = Install-Component -Label "CyberpunkVRPort $MOD_PINNED_TAG" -Urls @($MOD_URL) -ManualUrl $MOD_RELEASES -ManualName "the CyberpunkVRPort .zip" -PayloadRelFile $MOD_MARKER -ExpectedSha $MOD_PINNED_SHA
    # The version recorded from here on is the one on disk, not the one
    # we hoped for - otherwise the real update would never be offered.
    if ($modOk) {
        $installedTag = $MOD_PINNED_TAG
        # The summary line reads this, so it has to move too.
        $MOD_NAME     = "CyberpunkVRPort v$MOD_PINNED_TAG"
    }
}

# ROLLBACK: nothing was installed, so put the file back exactly as it was.
if (-not $modOk -and $script:ParkedProxy) {
    try {
        Move-Item -LiteralPath $script:ParkedProxy.From -Destination $script:ParkedProxy.To -Force -ErrorAction Stop
        Write-OK "Nothing was installed - your dxgi.dll has been put back."
        $script:ParkedProxy = $null
    } catch { Write-Warn "Could not restore dxgi.dll - it is at $($script:ParkedProxy.From)" }
}
if ($modOk) {
    Write-OK "CyberpunkVRPort $installedTag installed into the game folder."

    # !!! REMOVE THE OLD SECOND PLUGIN (2026-08-20). CyberpunkVR_Hands.dll
    # no longer exists - its code moved INTO CyberpunkVR_Stereo.dll. But
    # RED4ext loads EVERY dll it finds under red4ext\plugins, so a copy
    # left over from an earlier install loads as a second plugin, both
    # detour the same address, and the game dies with a fault at
    # FFFFFFFFFFFFFFFF. Extracting the new build over the old one does
    # NOT remove it, so this is on us.
    # THE .dll ITSELF IS RENAMED, NOT ITS FOLDER. Renaming the folder to
    # ...\.old does NOT help: RED4ext walks EVERY subfolder of
    # red4ext\plugins and loads every *.dll it finds, whatever the folder
    # is called. Only the file extension takes it out of that scan.
    # (Found by actually running this against a rebuilt folder - the
    # folder-rename version left the dll perfectly loadable.)
    $oldHands = "$($gameRoot.TrimEnd('\'))\red4ext\plugins\CyberpunkVR_Hands"
    if (Test-Path -LiteralPath $oldHands) {
        $handsDlls = @(Get-ChildItem -LiteralPath $oldHands -Filter "*.dll" -Recurse -ErrorAction SilentlyContinue)
        foreach ($hd in $handsDlls) {
            try {
                $parked = $hd.FullName + ".old"
                if (Test-Path -LiteralPath $parked) { Remove-Item -LiteralPath $parked -Force -ErrorAction Stop }
                Rename-Item -LiteralPath $hd.FullName -NewName ($hd.Name + ".old") -Force -ErrorAction Stop
                Write-OK "Parked the old plugin $($hd.Name) - leaving it would crash the game."
            } catch {
                Write-Warn "An old CyberpunkVR_Hands plugin is still loadable and MUST go:"
                Write-Host "  $($hd.FullName)" -ForegroundColor Yellow
                Write-Host "  Its code is inside CyberpunkVR_Stereo.dll now. Two plugins hooking" -ForegroundColor Gray
                Write-Host "  the same address crash the game on launch." -ForegroundColor Gray
            }
        }
    }

    # Same trap one level down: RED4ext reads every .dll in the plugin's
    # own folder too, so a renamed backup beside the real build loads as
    # a second copy of the SAME plugin.
    $stereoDir = "$($gameRoot.TrimEnd('\'))\red4ext\plugins\CyberpunkVR_Stereo"
    try {
        $strays = @(Get-ChildItem -LiteralPath $stereoDir -Filter "*.dll" -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -ne "CyberpunkVR_Stereo.dll" })
        foreach ($sd in $strays) {
            try {
                Rename-Item -LiteralPath $sd.FullName -NewName ($sd.Name + ".old") -Force -ErrorAction Stop
                Write-OK "Parked a stray plugin copy: $($sd.Name)"
            } catch {
                Write-Warn "Remove $($sd.FullName) by hand - RED4ext would load it as a second copy."
            }
        }
    } catch {}
    # Record the installed release tag so the Hub can flip the card to
    # "Update" when GitHub publishes a newer release (same scheme as the
    # other GitHub-tracked mods). File lives next to this installer.
    try {
        [System.IO.File]::WriteAllText((Join-Path $PSScriptRoot ".installed_version"), $installedTag, (New-Object System.Text.UTF8Encoding $false))
    } catch {}
    Save-InstalledStamp -GameDir $gameRoot -Version $installedTag -HubDir $PSScriptRoot
} else {
    if (Test-Path (Join-Path $gameRoot $MOD_MARKER)) {
        Write-Warn "Could not (re)install the VR mod, but a previous install is still present."
    } else {
        Write-Fail "The VR mod was not installed. Aborting."
        try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Pause-User "Press Enter to exit..."; exit 1
    }
}

# NOT CLEANED UP HERE. Step 3b downloads and unpacks into the very same
# folder, and wiping it at this point left Invoke-WebRequest writing to a
# path that no longer existed - "Ein Teil des Pfades ... konnte nicht
# gefunden werden". The cleanup happens once, at the very end.

# -------------------------------------------------------
# STEP 3b: recommended mods
# -------------------------------------------------------
# NO ATTRIBUTION IN THE WORDING. Some of these the mod author asks for,
# some are what those in turn need, and one came from a user - working
# out which is which is not the reader's problem, and getting it wrong
# in the text is worse than leaving it out. The Hub recommends them; if
# you do not want one, skip it.
# -------------------------------------------------------
# These live on Nexus, so the Hub cannot fetch them - Nexus needs a login and
# hands out no direct links. The installer therefore does the part it can:
# open the right page, wait, and take the ZIP either from the Downloads
# folder or dropped onto the window. Each one is skippable with Enter, and
# anything already installed is not offered at all.

# Run the "after" set through the graph so anything a mod NEEDS comes
# first. Offering Military Pistol Holsters before Equipment-EX and Zenitex
# would be offering something that cannot work yet - the user should not
# have to know that, the order should just be right.
# A mod carrying OnlyWith is pointless on its own - it is dropped unless
# its partner is actually on disk. The VR UI scripts only move what
# HUDitor cannot reach, so without HUDitor they would be five stragglers
# and nothing else.
$afterNames = @()
foreach ($nm in @($NEXUS_MODS | Where-Object { $_.Phase -eq "after" })) {
    if ($nm.OnlyWith) {
        $partner = $NEXUS_MODS | Where-Object { $_.Name -eq $nm.OnlyWith } | Select-Object -First 1
        if (-not $partner -or -not (Test-Path (Join-Path $gameRoot $partner.Marker))) { continue }
    }
    $afterNames += $nm.Name
}
# !!! DROP ANYTHING THAT BELONGS BEFORE THE VR MOD.
# Get-NexusChain follows Requires transitively, and "VR UI Mods" requires
# HUDitor - so HUDitor, and with it Input Loader and Mod Settings, were
# being pulled into the AFTER phase and offered a second time. Installed
# there they write HUDitor.xml and persistency.json back over the VR
# mod's, which is exactly the breakage the pre-VR block exists to
# prevent. In repair mode it happened on every single run.
# They are still installed - just in the earlier block, where they belong.
$EXTRA_MODS = @(Get-NexusChain -Names $afterNames | Where-Object { $_.Phase -ne "before" })

# WHAT IS ALREADY THERE, SAID OUT LOUD. The frameworks list themselves
# above; the optional mods did not, so a second run looked as if nothing
# had happened. Where a mod ships a DLL its version can be read and
# compared against the version this VR mod expects; the .archive and
# .reds mods carry no version, so they are listed as present and no
# claim is made about them.
$presentExtras = @($EXTRA_MODS | Where-Object { Test-Path (Join-Path $gameRoot $_.Marker) })
$needUpdate = @()
if ($presentExtras.Count -gt 0) {
    Write-Host ""
    Write-Host "  Already installed:" -ForegroundColor White
    foreach ($px in $presentExtras) {
        $mp = Join-Path $gameRoot $px.Marker
        $have = $null
        if ($px.Marker -match '\.dll$') { $have = Get-InstalledFrameworkVersion -Path $mp }
        if ($have -and $px.RequiredVersion -and (Test-FarEnoughBehind -Installed $have -Required $px.RequiredVersion)) {
            Write-Host ("   - {0} ({1}) - NEEDS UPDATE, this mod expects {2}" -f $px.Name, $have, $px.RequiredVersion) -ForegroundColor Yellow
            $needUpdate += $px
        } elseif ($have) {
            Write-Host ("   - {0} ({1})" -f $px.Name, $have) -ForegroundColor Green
        } else {
            Write-Host ("   - {0}" -f $px.Name) -ForegroundColor Green
        }
    }
}

# Anything that needs updating is offered again alongside what is
# missing - one list, one pass, no second round to remember.
$missingExtras = @($EXTRA_MODS | Where-Object { $global:RepairMode -or -not (Test-Path (Join-Path $gameRoot $_.Marker)) })
if ($needUpdate.Count -gt 0) { $missingExtras = @($missingExtras) + @($needUpdate) }
if ($missingExtras.Count -gt 0) {
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
    Write-Host " Recommended extra mods" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  $($missingExtras.Count) recommended mods. All on Nexus, so none can be" -ForegroundColor Gray
    Write-Host "  fetched automatically." -ForegroundColor Gray
    Write-Host "  For each one the page opens; download the file and drop it here." -ForegroundColor Gray
    Write-Host "  Type s and Enter to skip one." -ForegroundColor Gray

    foreach ($ex in $missingExtras) {
        [void](Install-NexusMod -Mod $ex -GameRoot $gameRoot -TempDir $tempDir)
    }
}

# -------------------------------------------------------
# STEP 4: Summary + first-launch notes
# -------------------------------------------------------
Write-Step 4 4 "All Done!"

$modPresent = Test-Path (Join-Path $gameRoot $MOD_MARKER)

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ($modPresent) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {} }

Write-Host "  Game folder: $gameRoot" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
if ($modPresent) { Write-Host "  [x] $MOD_NAME (RED4ext plugin + VR hands)" -ForegroundColor Green }
else { Write-Host "  [ ] VR mod missing" -ForegroundColor Red }
switch ($red4extState) {
    "present"   { Write-Host "  [x] RED4ext (already installed)" -ForegroundColor Green }
    "installed" { Write-Host "  [x] RED4ext" -ForegroundColor Green }
    default     { Write-Host "  [ ] RED4ext - hands/HUD will not load until added" -ForegroundColor Yellow }
}
switch ($cetState) {
    "present"   { Write-Host "  [x] Cyber Engine Tweaks (already installed)" -ForegroundColor Green }
    "installed" { Write-Host "  [x] Cyber Engine Tweaks" -ForegroundColor Green }
    default     { Write-Host "  [ ] Cyber Engine Tweaks - hands/HUD will not load until added" -ForegroundColor Yellow }
}
foreach ($fw in $FRAMEWORKS) {
    switch ($fwStates[$fw.Name]) {
        "present"   { Write-Host "  [x] $($fw.Name) (already installed)" -ForegroundColor Green }
        "installed" { Write-Host "  [x] $($fw.Name)" -ForegroundColor Green }
        default     { Write-Host "  [ ] $($fw.Name) - the VR mod's scripts need it" -ForegroundColor Yellow }
    }
}
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Start your OpenXR runtime FIRST (Virtual Desktop / VDXR," -ForegroundColor White
Write-Host "     SteamVR, etc.) - before launching the game." -ForegroundColor White
Write-Host "  2. Launch Cyberpunk 2077 normally (Steam / GOG, or the Hub)." -ForegroundColor White
Write-Host "  3. In-game:  F10 or Insert = VR settings overlay,  F7 = recenter." -ForegroundColor White
Write-Host ""
Write-Host "  - Open the F10 overlay -> VRIK tab to start hand tracking and" -ForegroundColor Gray
Write-Host "    calibrate reach / height / elbow per hand." -ForegroundColor Gray
Write-Host "  - On the first launch the mod swaps in its own tuned Cyberpunk" -ForegroundColor Gray
Write-Host "    settings and saves yours as UserSettings.pre-vr-<date>-<time>.json." -ForegroundColor Gray
Write-Host "    It does this once only; later changes in the game's menus stick." -ForegroundColor Gray
Write-Host "  - Log for bug reports: bin\x64\cyberpunkvrport.log" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to continue to the recommended settings..."
Clear-Host
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  !! RECOMMENDED SETTINGS - DO THIS OR PERFORMANCE MAY TANK !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Cyberpunk 2077 is VERY demanding in VR. On first launch the" -ForegroundColor White
Write-Host "  CyberpunkVRPort VR configuration window appears:" -ForegroundColor White
Write-Host ""
Write-Host "   - Resolution: do NOT go too high. 2560 x 2560 fits most setups." -ForegroundColor White
Write-Host "   - Leave the DEBUG tick-box OFF - it arms every diagnostic probe" -ForegroundColor White
Write-Host "     and costs frame time plus a very large log." -ForegroundColor White
Write-Host ""
Write-Host "  In-game graphics settings:" -ForegroundColor White
Write-Host "   - Quick Preset: Low  (Medium at most)" -ForegroundColor White
Write-Host "   - Resolution Scaling: Off" -ForegroundColor White
Write-Host "   - Turn OFF: Ray Tracing, Frame Generation, Film Grain," -ForegroundColor White
Write-Host "               Chromatic Aberration, Depth of Field, Lens Flare" -ForegroundColor White
Write-Host "   - Press Apply when done." -ForegroundColor White
Write-Host "   - Video: lower Gamma Correction a touch (it is a bit too bright)." -ForegroundColor White
Write-Host ""
Write-Host "  In the F10 VR menu (General, Controls, Stereo, VRIK):" -ForegroundColor White
Write-Host "   - VRIK tab: start hand tracking and calibrate reach, height," -ForegroundColor White
Write-Host "     elbow and wrist offset." -ForegroundColor White
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Wake up, samurai. Night City won't burn itself down." -ForegroundColor Magenta
Write-Host ""
# NO FOLDER IS OPENED HERE. The game is started the way it always was -
# from Steam or GOG - and the RED4ext plugin loads with it. Opening
# bin\x64 only invited launching the exe directly, which starts the game
# outside its launcher.
Write-Host "  Start the game as you always do, from Steam or GOG." -ForegroundColor White
Write-Host "  Your OpenXR runtime has to be running BEFORE it." -ForegroundColor Gray
Write-Host ""
# The one and only cleanup: everything that needed the temp folder -
# the frameworks, the VR mod, the Nexus mods and the repo download -
# is done by now.
try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Pause-User "Press Enter once you've read the settings above to finish..."
