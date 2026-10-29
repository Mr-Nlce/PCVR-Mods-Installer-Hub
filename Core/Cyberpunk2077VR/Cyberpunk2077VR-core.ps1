param([ValidateSet('','Current','Depot')][string]$Route='')
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
. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")

. (Join-Path $PSScriptRoot "..\Modules\CyberpunkFrameworkRecovery.ps1")
. (Join-Path $PSScriptRoot "..\Modules\CyberpunkRoutes.ps1")
. (Join-Path $PSScriptRoot "..\Modules\PublisherZipTransaction.ps1")
$ErrorActionPreference='Stop'
if(-not $env:PCVR_HUB_GAME_ID){$env:PCVR_HUB_GAME_ID='cyberpunk-2077'}
while($true){
 try{
  & {
   $tempDir=$null;$script:CyberpunkVrSnapshot=$null;$script:CyberpunkCommitted=$false;$script:CyberpunkLastFailure='';$script:CyberpunkRecoveryPage='https://github.com/dariulone/cyberpunk-vr-port/releases'
   try{
$Host.UI.RawUI.WindowTitle = "Cyberpunk 2077 VR Installer"
$ErrorActionPreference = "Stop"

$MOD_NAME     = "CyberpunkVRPort 0.1.8 (fixed for game 2.31)"
$MOD_AUTHOR   = "dariulone"
$INFO_URL     = "https://github.com/dariulone/cyberpunk-vr-port"
$MOD_RELEASES = "https://github.com/dariulone/cyberpunk-vr-port/releases/tag/0.1.8"
# One fixed game-specific profile; no latest-framework lookup on this route.
$compatibility = Get-CyberpunkRouteProfile
$RED4EXT_URL = $compatibility.Components[0].Pinned
$RED4EXT_REL = $compatibility.Components[0].Page
$CET_URL = $compatibility.Components[1].Pinned
$CET_REL = $compatibility.Components[1].Page
$FRAMEWORKS = @($compatibility.Components | Select-Object -Skip 2)
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
       What = "required for the VR scanner HUD editor's Right Shift binding" },
    @{ Name = "More Occluders (Scripted)"; Url = "https://www.nexusmods.com/cyberpunk2077/mods/33136?tab=files"
       RequiredVersion = "0.3"
       Marker = "r6\scripts\MoreOccluders.reds"; Phase = "before"
       Requires = @()
       FilenamePattern = '(?i)More[ _-]?Occluders.*Scripted.*33136.*0[._-]3'
       What = "the separate Scripted v0.3 file requested by CyberpunkVRPort; do not select ArchiveXL v0.4" },
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
    param($Mod, [string]$GameRoot, [string]$TempDir, [switch]$Required)

    if($Mod.Name -eq 'Mod Settings' -and (Get-CyberpunkRouteProfile).GameVersion -eq '2.5'){
        return Install-CyberpunkCurrentModSettings -GameRoot $GameRoot -Required:$Required
    }

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
    if($Required){Pause-User "Press Enter to open the $($Mod.Name) download page...";$ans=''}
    else{$ans=Read-Host "Press Enter to open the optional $($Mod.Name) page, or S to skip"}
    # Exactly "s" or "skip" - NOT any word starting with s. Both
    # questions use the same test, so the same typing works in both.
    if ("$ans".Trim() -match '^(?i)s(kip)?$') {
        if (-not $Required) { Write-Info "Skipped $($Mod.Name)."; return $false }
        Write-Warn "$($Mod.Name) is required; choose the correct archive to continue."
    }

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
            Invoke-PCVRWebRequest -Uri $Mod.DirectUrl -OutFile $tmpZip -UseBasicParsing -ErrorAction Stop
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

    if(-not $Mod.DirectUrl -or -not $zip){[void](Wait-PCVRExplicitEnter -Message 'After downloading the file, press Enter to check Downloads...')}
    # Downloads folder next - after a Nexus download the file is usually
    # right there, and picking it beats asking the user to go and find it.
    $dl  = Get-PCVRDownloadsFolder
    if (-not $zip -and (Test-Path -LiteralPath $dl)) {
        # THE NEXUS MOD ID IS THE RELIABLE KEY. Nexus puts it in every
        # file name, and it never changes. Matching on our DISPLAY name
        # fails whenever the author named the file differently -
        # "Shinobi's Black Market" ships as shinobi_shop_24833_..., so
        # the name match found nothing and the mod went uninstalled.
        $modId = ([regex]::Match([string]$Mod.Url, '/mods/(\d+)')).Groups[1].Value
        $key   = ($Mod.Name -replace '[^A-Za-z]', '')
        $files = @(Get-ChildItem -LiteralPath $dl -File -ErrorAction SilentlyContinue |
                   Where-Object { [IO.Path]::GetExtension($_.Name).ToLowerInvariant() -in @('.zip', '.rar', '.7z') } |
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
    $rejectedArchives = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    while ($true) {
    while (-not $zip) {
        $inp = ([string](Read-Host "  Drag the $($Mod.Name) archive here, or press Enter to check Downloads again$(if (-not $Required) { ' (s to skip)' })")).Trim().Trim('"')
        if ($inp -match '^(?i)s(kip)?$') {
            if (-not $Required) { Write-Info "Skipped $($Mod.Name)."; return $false }
            Write-Warn "$($Mod.Name) is required. Download its correct archive or drag it here."
            if ([Console]::IsInputRedirected) { return $false }
            continue
        }
        if (-not $inp) {
            # Enter means the download has finished. Recheck the registered
            # Downloads folder; it must never silently mean Skip.
            $fresh = @(Get-ChildItem -LiteralPath $dl -File -ErrorAction SilentlyContinue |
                Where-Object { [IO.Path]::GetExtension($_.Name).ToLowerInvariant() -in @('.zip','.rar','.7z') -and
                    -not $rejectedArchives.Contains($_.FullName) } |
                Sort-Object LastWriteTime -Descending)
            $id = ([regex]::Match([string]$Mod.Url, '/mods/(\d+)')).Groups[1].Value
            if ($id) { $fresh = @($fresh | Where-Object { $_.Name -match ("(?<![0-9])" + [regex]::Escape($id) + "(?![0-9])") }) }
            if ($fresh.Count) { $zip = $fresh[0].FullName; Write-OK "Found in Downloads: $($fresh[0].Name)" }
            else { Write-Warn "The $($Mod.Name) archive is not in Downloads yet. Download it or drag the correct file here." }
            if (-not $zip -and [Console]::IsInputRedirected) { return $false }
            continue
        }
        if (Test-Path -LiteralPath $inp) { $zip = $inp } else { Write-Fail "Not found: $inp" }
    }
    if ([IO.Path]::GetExtension($zip).ToLowerInvariant() -in @('.rar','.7z') -and -not (Get-SevenZip -Required)) {
        Write-Warn "7-Zip is required to open this archive. Install it, then use the same file again."
        $zip = $null
        continue
    }

    $exDir = Join-Path $TempDir ("nx_" + [System.IO.Path]::GetRandomFileName())
    try {
        New-Item -ItemType Directory -Path $exDir -Force | Out-Null
        $extractResult = Expand-ArchiveOrFallback -ArchivePath $zip -DestinationFolder $exDir -Label $Mod.Name -AllowSkip (-not $Required)
        if ([string]$extractResult -in @('skip', 'quit')) { return $false }
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
            Write-Warn "Choose the $($Mod.Name) archive and try again."
            [void]$rejectedArchives.Add($zip)
            $zip = $null
            continue
        }

        Copy-Tree -Src $root -Dst $dst
        if (Test-Path (Join-Path $GameRoot $Mod.Marker)) { Write-OK "$($Mod.Name) installed."; return $true }
        # The archive had it and the copy did not land it - a permission
        # problem or a locked file, not a wrong download.
        Write-Fail "$($Mod.Name): copied, but $($Mod.Marker) is not in the game folder."
        return $false
    } catch {
        Write-Fail "$($Mod.Name) could not be installed: $($_.Exception.Message)"
        Write-Warn "Choose another $($Mod.Name) archive and try again."
        [void]$rejectedArchives.Add($zip)
        $zip = $null
        continue
    } finally {
        if (Test-Path -LiteralPath $exDir -PathType Container) {
            Remove-Item -LiteralPath $exDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
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
$MOD_REQUIRED = @(
    $MOD_MARKER,
    'archive\pc\mod\cyberpunkvrport.archive',
    'r6\input\CyberpunkVRPort_ScannerHud.xml',
    'bin\x64\plugins\cyber_engine_tweaks\mods\CyberpunkVRPort_Stereo\init.lua'
)
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
    Show-AntivirusNotice -Compact
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($x) Write-Host "  [OK] $x" -ForegroundColor Green }
function Write-Info { param($x) Write-Host "  $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host "  [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) $script:CyberpunkLastFailure=[string]$x;Write-Host "  [XX] $x" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") [void](Wait-PCVRExplicitEnter -Message $text) }

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
    return (Test-Path -LiteralPath (Join-Path $Root $GAME_EXE_REL) -PathType Leaf)
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
    $base = (Resolve-Path -LiteralPath $Src -ErrorAction Stop).Path.TrimEnd('\')
    $files = @(Get-ChildItem -LiteralPath $base -Recurse -File -Force -ErrorAction Stop)
    if ($files.Count -eq 0) { throw 'The extracted package has no files to copy.' }
    foreach ($source in $files) {
        $rel = $source.FullName.Substring($base.Length).TrimStart('\')
        $target = Join-Path $Dst $rel
        $tdir = Split-Path $target -Parent
        if ($tdir -and -not (Test-Path -LiteralPath $tdir -PathType Container)) { New-Item -ItemType Directory -Path $tdir -Force | Out-Null }
        if (($script:BackupBeforeOverwrite -contains $rel) -and (Test-Path -LiteralPath $target)) {
            $bak = "$target.pre-vr"
            if (-not (Test-Path -LiteralPath $bak)) {
                try {
                    Copy-Item -LiteralPath $target -Destination $bak -Force -ErrorAction Stop
                    Write-Info "Kept your $rel as $(Split-Path -Leaf $bak)"
                } catch { throw "Could not back up $rel; it was not replaced: $($_.Exception.Message)" }
            }
        }
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force -ErrorAction Stop
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Copied file is missing at its destination: $target" }
    }
}

# Frozen game-specific release. A later 2.5 port needs a different setup.
function Resolve-LatestModUrl {
    $profile=Get-CyberpunkRouteProfile
    return @{Url=$profile.ModUrl;Tag=$profile.ModVersion}
}

# -------------------------------------------------------
# Display the same fixed release that all download/recovery paths use.
if(-not $Route){
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Yellow
    Write-Host '  Cyberpunk 2077 VR Installer' -ForegroundColor Yellow
    Write-Host '============================================================' -ForegroundColor Yellow
    Write-Host '  Install, update or repair your selected VR version.' -ForegroundColor White
    Write-Host '  Current uses your normal game folder; Depot installs a separate copy.' -ForegroundColor White
    Write-Host ''
    Write-Host '  [1] RECOMMENDED - Current game 2.5 (automatic mod updates)' -ForegroundColor Green
    Write-Host '      Choose this to update an existing normal-game VR installation.' -ForegroundColor Gray
    Write-Host '  [2] Separate Depot 2.31 (fixed game, mod and frameworks)' -ForegroundColor White
    Write-Host '      Keeps game 2.31 and its compatible VR files in their own folder.' -ForegroundColor Gray
    Write-Host ''
    do{$choice=(''+(Read-Host '  Choose 1 or 2 (Enter = Current)')).Trim()}while($choice -notin @('','1','2'))
    $Route=if($choice -eq '2'){'Depot'}else{'Current'}
}
$script:CyberpunkActiveProfile=if($Route -eq 'Current'){Get-CyberpunkCurrentProfile}else{Get-CyberpunkDepotProfile}
$compatibility=Get-CyberpunkRouteProfile
if($Route -eq 'Current'){
 $MOD_REQUIRED+=@('archive\pc\mod\cyberpunkvrport.archive.xl','r6\scripts\CyberpunkVRPort_EngineStereo\vrport_engine_stereo_menu.reds','r6\scripts\CyberpunkVRPort_DualWield\vrport_dual_wield.reds','r6\scripts\CyberpunkVRPort_Menu\vrport_menu_journal.reds','bin\x64\plugins\cyber_engine_tweaks\mods\CyberpunkVRPort_Menu\init.lua')
}
$MOD_NAME='CyberpunkVRPort '+$compatibility.ModVersion+' / game '+$compatibility.GameVersion
$script:CyberpunkRecoveryPage=$compatibility.ModPage
if($Route -eq 'Current'){
    $NEXUS_MODS=@($NEXUS_MODS|Where-Object {$_.Name -notin @('HUDitor','VR UI Mods','Visible Bullets','More Occluders (Scripted)')})
    foreach($mod in $NEXUS_MODS|Where-Object Name -eq 'Mod Settings'){$mod.Phase='after';$mod.What='compatible settings support for optional mods on game 2.5'}
}else{
    $NEXUS_MODS=@($NEXUS_MODS|Where-Object {$_.Name -eq 'More Occluders (Scripted)'})
}

if($Route -eq 'Current'){Write-Host '  Preparing Cyberpunk VR for the current game 2.5...' -ForegroundColor DarkGray}else{
Write-Host "  Preparing the fixed Cyberpunk 2.31 VR release..." -ForegroundColor DarkGray
}
$latest = Resolve-LatestModUrl
$installedTag = if ($latest -and $latest.Tag) { [string]$latest.Tag } else { '' }
if ($installedTag) {
    $displayTag = if ($installedTag -match '^[vV]\d') { $installedTag } else { "v$installedTag" }
    $MOD_NAME = "CyberpunkVRPort $displayTag"
}

# -------------------------------------------------------
# STEP 1: Locate Cyberpunk 2077
# -------------------------------------------------------
Write-Header


Write-Step 1 4 "Locating Cyberpunk 2077"

if($Route -eq 'Depot'){
    $gameRoot=Resolve-CyberpunkDepotRoot -HubFolder $PSScriptRoot
}else{
$gameRoot=Get-CyberpunkRememberedCurrentRoot
if(-not $gameRoot){$gameRoot = Find-SteamGameFolder -AppId "1091500" -SteamFolderNames @("Cyberpunk 2077") -GogNames @("Cyberpunk 2077") -EpicNames @("Cyberpunk 2077") -HubGameId "cyberpunk-2077"}
if($gameRoot -and (Test-CyberpunkPinnedRoot $gameRoot)){$gameRoot=$null}

$steamPath = Get-SteamPath
if (-not $gameRoot -and $steamPath) {
    foreach ($lib in (Get-SteamLibraries $steamPath)) {
        $root = Join-Path $lib "steamapps\common\$STEAM_FOLDER"
        if (Test-CP2077Root $root) { $gameRoot = $root; Write-Info "Found via Steam: $gameRoot"; break }
    }
}

if (-not $gameRoot) { $gameRoot = Find-SteamGameFolder -AppId "1091500" -SteamFolderNames @("Cyberpunk 2077") -GogNames @("Cyberpunk 2077") -EpicNames @("Cyberpunk 2077") -HubGameId "cyberpunk-2077" }
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

}

$tempDir = Join-Path $env:TEMP "CP2077VRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Download a zip (with mirrors + manual fallback) and overlay it into the
# game folder. Returns $true on success.
function Install-Component {
    param([string]$Label, [string[]]$Urls, [string]$ManualUrl, [string]$ManualName, [string]$PayloadRelFile = "", [string]$ExpectedTag = "", [string]$ManualArchive = "")
    $tmpZip = Join-Path $tempDir ("dl_" + [System.IO.Path]::GetRandomFileName() + ".zip")
    $downloadInfo = @{}
    $script:CyberpunkRecoveryPage=$ManualUrl
    Write-Information -MessageData ("Component target [$Label]: " + [IO.Path]::GetFullPath($gameRoot)) -InformationAction SilentlyContinue
    if($ManualArchive){
        if(-not(Test-DownloadedPayload -Path $ManualArchive -IntendedPath $tmpZip)){Write-Fail 'The handed-over framework is not a usable, safe archive.';return $false}
        Copy-Item -LiteralPath $ManualArchive -Destination $tmpZip -Force -ErrorAction Stop
        $downloadInfo.SourcePath=$ManualArchive;$downloadResult='retry'
    }else{
    $downloadResult = Invoke-SafeDownload -Urls $Urls -Destination $tmpZip -Label $Label `
                -ManualUrl $ManualUrl `
                -Instructions "Download $ManualName from the page that opened and drop it into the opened folder, then choose Retry." `
                -SkipMessage "Skipped - $Label was NOT installed." -DownloadInfo $downloadInfo -DisableGitHubAssetReresolution -FunctionalPayloadOnly -PlainProgress
    }
    if (-not (Test-Path -LiteralPath $tmpZip -PathType Leaf)) { return $false }
    if ($Label -like 'CyberpunkVRPort *') { $script:LastCyberpunkPortTag = (Get-CyberpunkRouteProfile).ModVersion }

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
    if ($PayloadRelFile -and -not (Test-Path -LiteralPath (Join-Path $payloadRoot $PayloadRelFile) -PathType Leaf)) {
        Write-Fail "$Label : that archive does not contain $PayloadRelFile - nothing was copied."
        return $false
    }
    if ($Label -like 'CyberpunkVRPort *') {
        $installNote=Join-Path $payloadRoot 'INSTALL.txt'
        if(Test-Path -LiteralPath $installNote -PathType Leaf){
            $note=Get-Content -LiteralPath $installNote -Raw
            $packageGame=([regex]::Match($note,'(?im)^\s*Cyberpunk\s+2077\s+(\d+\.\d+)')).Groups[1].Value
            if($packageGame -and $packageGame -ne (Get-CyberpunkRouteProfile).GameVersion){Write-Fail ('This VR package requires game '+$packageGame+', but the selected route uses '+(Get-CyberpunkRouteProfile).GameVersion+'. Nothing was copied. Use the matching release or choose the other route.');return $false}
            $actual=([regex]::Match($note,'(?m)^CyberpunkVRPort\s+(\d+\.\d+\.\d+)')).Groups[1].Value
            if($actual){
                $script:LastCyberpunkPortTag=$actual
                if($Route -eq 'Current' -and [version]$actual -lt [version]'0.1.9'){Write-Fail 'This older VR package is not compatible with Current game 2.5. Use Current 0.1.9 or newer, or choose Depot for the older release. Nothing was copied.';return $false}
                if($Route -eq 'Depot' -and $actual -ne $compatibility.ModVersion){Write-Fail 'This VR build belongs to another game route. Use the pinned Depot release.';return $false}
                if($Route -eq 'Current'){$compatibility.ModVersion=$actual}
            }
        }
        foreach ($relative in $MOD_REQUIRED) {
            if (-not (Test-Path -LiteralPath (Join-Path $payloadRoot $relative) -PathType Leaf)) {
                Write-Fail "$Label : release payload is missing $relative - nothing was copied."
                return $false
            }
        }
    }
    try {
        $routeProfile=Get-CyberpunkRouteProfile
        $fixed=@((@($routeProfile.Components)+@($routeProfile.InputLoader)+@($routeProfile.ModSettings)) | Where-Object {$_ -and $_.Marker -eq $PayloadRelFile})
        if($fixed.Count){Install-CyberpunkFixedPayload -SourceRoot $payloadRoot -GameRoot $gameRoot -Component $fixed[0]}
        else{
            $identity='cyberpunkvrport'
            $keep=@(Get-CyberpunkPortPreservedSettings -SourceRoot $payloadRoot)
            $script:CyberpunkVrSnapshot=Save-PCVRPublisherZipSnapshot -GameRoot $gameRoot -Stage $payloadRoot -Identity $identity -SnapshotRoot (Join-Path $tempDir 'vr-rollback') -ExtraPaths @('.pcvrhub_cyberpunk_25_profile.json','.pcvrhub_cyberpunk_231_profile.json',($MOD_MARKER+'.pcvrhub_off'))
            $portTarget=[string]$gameRoot;$portSource=[string]$payloadRoot;$portKeep=@($keep);$portHub=[string]$PSScriptRoot
            $copyPort={ Initialize-CyberpunkLegacyOwnership -GameRoot $portTarget -HubFolder $portHub; [void](Install-OwnedModPayload -SourceRoot $portSource -GameRoot $portTarget -Identity $identity -KeepExistingRelativePaths $portKeep -ProgressLabel 'Installing Cyberpunk VR files') }.GetNewClosure()
            & $copyPort
            foreach($rel in $MOD_REQUIRED){$path=Join-Path $gameRoot $rel;Write-PCVRFileCheckResult -Path $path -Present (Test-Path -LiteralPath $path -PathType Leaf) -Phase 'immediately-after-copy'}
            if(-not(Confirm-PlacedFilesSurvive -Paths @($MOD_REQUIRED|ForEach-Object {Join-Path $gameRoot $_}) -GameDir $gameRoot -Recopy $copyPort -NoClear)){throw 'Required VR files are missing. The previous files will be restored; recovery remains available.'}
            foreach($rel in $MOD_REQUIRED){$path=Join-Path $gameRoot $rel;Write-PCVRFileCheckResult -Path $path -Present (Test-Path -LiteralPath $path -PathType Leaf) -Phase 'after-observation'}
        }
    } catch { Write-Fail "Copy failed: $($_.Exception.Message)"; return $false }
    if ($PayloadRelFile -and -not (Test-Path -LiteralPath (Join-Path $gameRoot $PayloadRelFile) -PathType Leaf)) {
        Write-Fail "$Label : copied, but $PayloadRelFile is not in the game folder."
        return $false
    }
    if ($PayloadRelFile) { Write-Information -MessageData ("File check [$Label]: " + (Join-Path $gameRoot $PayloadRelFile) + " is present after copying.") -InformationAction SilentlyContinue }
    if ($Label -like 'CyberpunkVRPort *') {
        foreach ($relative in $MOD_REQUIRED) {
            if (-not (Test-Path -LiteralPath (Join-Path $gameRoot $relative) -PathType Leaf)) {
                Write-Fail "$Label : copied, but $relative is missing from the game folder."
                return $false
            }
        }
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

function Test-CyberpunkSteamInstall {
    param([string]$GameRoot)
    try {
        $folder = Get-Item -LiteralPath $GameRoot -ErrorAction Stop
        if ($folder.Parent.Name -ne 'common' -or $folder.Parent.Parent.Name -ne 'steamapps') { return $false }
        $manifest = Join-Path $folder.Parent.Parent.FullName 'appmanifest_1091500.acf'
        $text = Get-Content -LiteralPath $manifest -Raw -ErrorAction Stop
        $installDir = [regex]::Match($text, '"installdir"\s+"([^"]+)"').Groups[1].Value
        return ($text -match '"appid"\s+"1091500"' -and $installDir -eq $folder.Name)
    } catch { return $false }
}

function Install-CyberpunkCurrentModSettings {
    param([string]$GameRoot,[switch]$Required)
    $profile=Get-CyberpunkRouteProfile
    if($profile.GameVersion -ne '2.5'){throw 'Current Mod Settings must never be installed in the frozen 2.31 Depot.'}
    $component=Get-CyberpunkModSettingsProfile
    $present=Test-Path -LiteralPath (Join-Path $GameRoot $component.Marker) -PathType Leaf
    if(-not $Required -and -not $present){
        Write-Host '  Mod Settings is needed by this optional mod. Setup can download the compatible version from GitHub.' -ForegroundColor White
        $answer=(''+(Read-Host '  Press Enter to install Mod Settings, or S to skip')).Trim()
        if($answer -match '^(?i)s(kip)?$'){return $false}
    }
    $script:CyberpunkRecoveryPage=$component.Page
    if(-not $profile.UseKnownReleases){$component=Get-CyberpunkModSettingsWithRecovery}
    $profile.ModSettings=$component
    $state=Get-CyberpunkFixedComponentState -GameRoot $GameRoot -Component $component
    if(-not $global:RepairMode -and $state -eq 'compatible'){
        Write-OK ('Mod Settings '+$component.Version+' is compatible with game 2.5.')
        return $true
    }
    Write-Host '  Updating Mod Settings for game 2.5. Existing files are backed up; your settings are kept.' -ForegroundColor White
    if(-not(Install-Component -Label $component.Name -Urls @($component.Pinned) -ManualUrl $component.Page -ManualName $component.File -PayloadRelFile $component.Marker)){throw 'Mod Settings was not updated. Retry or supply its official game-2.5 release ZIP.'}
    Write-OK ('Mod Settings '+$component.Version+' installed for game 2.5.')
    return $true
}

function Test-CyberpunkSupportedVersion {
    param([string]$Version, [string]$RequiredVersion = (Get-CyberpunkRouteProfile).GameVersion)
    return (([regex]::Match($Version, '^\d+\.\d+')).Value -eq $RequiredVersion)
}

function Test-CyberpunkGameRunning {
    return [bool](Get-Process -Name 'Cyberpunk2077' -ErrorAction SilentlyContinue)
}

function Open-Cyberpunk231Properties {
    Write-Host ''
    Write-Host '  SWITCH TO THE VR-SUPPORTED GAME VERSION' -ForegroundColor Black -BackgroundColor Yellow
    Write-Host '  1. In Steam Properties, click Game versions & betas (Spielversionen und Betas).' -ForegroundColor Yellow
    Write-Host '  2. Scroll to the TOP of the version list.' -ForegroundColor Yellow
    Write-Host '  3. Select: PUBLIC DEFAULT VERSION (top entry), not 2_31_old.' -ForegroundColor Black -BackgroundColor Yellow
    Write-Host '  4. Wait until Steam has finished downloading the selected version.' -ForegroundColor Yellow
    Write-Host '  Keep Cyberpunk 2077 closed. Return here when the download is complete.' -ForegroundColor White
    try {
        Open-PCVRPageAfterEnter -Message 'Press Enter to open Cyberpunk 2077 Steam Properties.' -Url 'steam://gameproperties/1091500'
    } catch {
        Write-Warn 'Steam Properties could not be opened. In Steam, right-click Cyberpunk 2077 > Properties.'
    }
    [void](Wait-PCVRExplicitEnter -Message 'After Steam finishes downloading the default version, press Enter to check the installed game version.')
}

function Confirm-CyberpunkGameVersion {
    param([string]$GameRoot, [string]$RequiredVersion = (Get-CyberpunkRouteProfile).GameVersion)
    $exe = Join-Path $GameRoot 'bin\x64\Cyberpunk2077.exe'
    $version = Get-InstalledFrameworkVersion -Path $exe
    if (-not $version) {
        Write-Warn "Could not read the game's version. This route needs $RequiredVersion; verify the game, then Retry."
        return $false
    }
    if (Test-CyberpunkSupportedVersion -Version $version -RequiredVersion $RequiredVersion) {
        Write-OK "Cyberpunk 2077 $version - the version this port is built for."
        return $true
    }
    Write-Host ''
    Write-Warn "YOUR GAME IS $version - THIS VR PORT REQUIRES $RequiredVersion."
    Write-Host '  The VR mod may not start on another game version.' -ForegroundColor Yellow
    if($Route -eq 'Depot'){Write-Warn 'The separate depot must contain game 2.31. Retry its pinned download; the normal Steam branch is unchanged.';return $false}
    $steam = Test-CyberpunkSteamInstall -GameRoot $GameRoot
    if (-not $steam) {
        Write-Host '  The Steam branch switch is available only for a confirmed Steam installation.' -ForegroundColor Gray
        Write-Host ('  Update this copy to '+$RequiredVersion+' in its own store, then choose Retry. No VR files were changed.') -ForegroundColor Yellow
        return $false
    }
    Write-Host '  [1] RECOMMENDED - Switch to the public default version (2.5)' -ForegroundColor Green
    Write-Host '  [2] Keep the installed game version and stop Setup' -ForegroundColor White
    $choice = ''
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        $choice = ('' + (Read-Host 'Choice [1/2, Enter = stop]')).Trim()
        if ($choice -in @('','1','2')) { break }
        Write-Warn 'Please choose 1 or 2.'
    }

    if ($choice -ne '1') { return $false }
    $openProperties = $true
    while ($true) {
        if (Test-CyberpunkGameRunning) {
            Write-Warn 'Close Cyberpunk 2077 before changing or checking its game version. No VR files were changed.'
            $answer = ('' + (Read-Host 'After closing the game: [R] Retry, [Q] Stop')).Trim()
            if ($answer -ieq 'r') { continue }
            return $false
        }
        if ($openProperties) { Open-Cyberpunk231Properties }
        # Read the EXE again, never the prior warning or the selected Steam label.
        $version = Get-InstalledFrameworkVersion -Path $exe
        if (Test-CyberpunkGameRunning) {
            Write-Warn 'Cyberpunk 2077 is running. Close it before continuing Setup.'
            $openProperties = $false
            continue
        }
        if (Test-CyberpunkSupportedVersion -Version ('' + $version) -RequiredVersion $RequiredVersion) {
            Write-OK "Cyberpunk 2077 $version confirmed. Continuing VR Setup."
            return $true
        }
        $shown = if ($version) { $version } else { 'unreadable / Steam update not finished' }
        Write-Warn "Patch $RequiredVersion is not installed yet. Detected: $shown. No VR files were changed."
        Write-Host '  [R] Recheck after the download  [O] Open Steam Properties again  [Q] Stop' -ForegroundColor Yellow
        $answer = ('' + (Read-Host 'Choice [R/O/Q, Enter = stop]')).Trim()
        if ($answer -ieq 'o') { $openProperties = $true }
        elseif ($answer -ieq 'r') { $openProperties = $false }
        else { return $false }
    }
}

# ---- Game version -------------------------------------------
# THE PORT IS BUILT AGAINST ONE GAME BUILD. Its engine offsets are
# addresses in a specific Cyberpunk2077.exe - on a different patch they
# point at whatever now lives there, which does not announce itself. It
# fails quietly, or crashes, and neither says why.
$REQUIRED_GAME_VERSION = $compatibility.GameVersion
if($Route -eq 'Current' -and (Test-CyberpunkPinnedRoot $gameRoot)){throw 'Current cannot update the separate pinned Depot. Choose the regular Steam, GOG or Epic game folder in recovery.'}
if (-not (Confirm-CyberpunkGameVersion -GameRoot $gameRoot -RequiredVersion $REQUIRED_GAME_VERSION)) {
    Write-Info 'Stopped - no VR files were changed.'
    Pause-User 'Press Enter to exit.'
    exit 0
}

if(Test-CyberpunkGameRunning){throw 'Close Cyberpunk 2077 before installing or repairing the VR mod, then choose Retry.'}
if(-not(Test-InstallerTargetWritable -TargetPath (Join-Path $gameRoot '.pcvrhub_write_target'))){throw ('Cannot write to the selected game folder: '+$gameRoot+'. Check permissions, then Retry.')}
$script:CyberpunkWasFlat=Test-Path -LiteralPath (Join-Path $gameRoot ($MOD_MARKER+'.pcvrhub_off')) -PathType Leaf
if($Route -eq 'Current' -and -not(Save-HubRememberedGameFolder -GameId 'cyberpunk-2077' -Title 'Cyberpunk 2077' -GameDir $gameRoot -StateName 'installed_path_current' -ProbeFiles @('bin\x64\Cyberpunk2077.exe','archive\pc\content\basegame_1_engine.archive','r6\cache\final.redscripts'))){throw 'The Current game folder could not be remembered. Choose Retry; no VR files were changed.'}
if($Route -eq 'Depot' -and -not(Save-HubRememberedGameFolder -GameId 'cyberpunk-2077' -Title 'Cyberpunk 2077' -GameDir $gameRoot -StateName 'installed_path_depot' -ProbeFiles @('bin\x64\Cyberpunk2077.exe','archive\pc\content\basegame_1_engine.archive','r6\cache\final.redscripts'))){throw 'The Depot game folder could not be remembered. Choose Retry; no VR files were changed.'}
if($Route -eq 'Current'){
    . (Join-Path $PSScriptRoot 'Start-CyberpunkVR.ps1') -GameDirectory $gameRoot -FunctionsOnly
    Write-Host '  Protecting existing saves with a one-time verified backup...' -ForegroundColor Cyan
    Save-CyberpunkInitialSaveBackup -SaveRoot (Get-CyberpunkSaveRoot)
}

# The update notice belongs BEFORE the question, not after it: it is
# part of what the user is deciding about. Its result also decides
# whether the prompt says "installation" or "installation / Update".
$__modPresent = Test-Path (Join-Path $gameRoot $MOD_MARKER)
if($Route -eq 'Depot'){Write-Host '  Depot 2.31 is fully fixed. Auto-update is off.' -ForegroundColor Yellow}else{Write-Host '  Current uses game 2.5 and the latest stable VR mod and frameworks.' -ForegroundColor Yellow;Write-Host '  Previously switched to 2_31_old? Select the public default version when prompted.' -ForegroundColor White}
Write-Host '  FIRST VR START: the mod applies VR graphics, controls, HUD and comfort settings.' -ForegroundColor Yellow
Write-Host '  Your settings are backed up. Language, audio, difficulty and saved games are kept.' -ForegroundColor White
if($Route -eq 'Current'){Write-Host '  Use an up-to-date GPU driver for game 2.5.' -ForegroundColor White}
if($Route -eq 'Current'){
    Write-Host '  Existing Mod Settings will be updated for 2.5; its old files and your settings are kept.' -ForegroundColor White
    Write-Host '  The incompatible More Occluders Scripted 0.3 will be backed up and disabled on 2.5.' -ForegroundColor Yellow
    Write-Host '  The separate 2.31 Depot keeps its compatible script.' -ForegroundColor Gray
}

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
    Write-Host ("  again, using the compatible framework versions for game "+$compatibility.GameVersion+". Takes longer.") -ForegroundColor Gray
    Write-Host ""
}

if($Route -eq 'Current'){
    Write-Host '  Checking the latest VR mod and required components on GitHub...' -ForegroundColor Cyan
    Write-Host '  This may take a minute. Downloads start after the check.' -ForegroundColor Gray
    $script:CyberpunkActiveProfile=Get-CyberpunkCurrentProfileWithRecovery
    $compatibility=Get-CyberpunkRouteProfile
    $MOD_NAME='CyberpunkVRPort '+$compatibility.ModVersion+' / game '+$compatibility.GameVersion
}
Write-Step 2 4 "Frameworks (RED4ext + Cyber Engine Tweaks)"
Write-Host ('  Installing frameworks compatible with game '+$compatibility.GameVersion+'.') -ForegroundColor White
Write-Host '  Missing, newer or unverified versions are replaced after a backup.' -ForegroundColor Yellow
Write-Host '  Your mod settings, other mods and saves are kept.' -ForegroundColor Gray

function Get-MissingCyberpunkRuntimeFiles {
    param([string]$GameRoot)
    $required = @($RED4EXT_MARK, $CET_MARK) + @($FRAMEWORKS | ForEach-Object { [string]$_.Marker })
    foreach ($relative in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $GameRoot $relative) -PathType Leaf)) {
            Write-Output $relative
        }
    }
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

$fwStates = @{}
foreach ($fw in $compatibility.Components) {
    $state=Get-CyberpunkFixedComponentState -GameRoot $gameRoot -Component $fw
    if(-not $global:RepairMode -and $state -eq 'compatible'){
        Write-OK "$($fw.Name) $($fw.Version) - compatible with game $($compatibility.GameVersion)."
        $fwStates[$fw.Name]='present'
        continue
    }
    Write-Host ("  {0}: {1}. Installing compatible version {2}." -f $fw.Name,$state,$fw.Version) -ForegroundColor White
    if(Install-Component -Label $fw.Name -Urls @($fw.Pinned) -ManualUrl $fw.Page -ManualName $fw.File -PayloadRelFile $fw.Marker){
        Write-OK "$($fw.Name) $($fw.Version) installed for game $($compatibility.GameVersion)."
        $fwStates[$fw.Name]='installed'
    }else{$fwStates[$fw.Name]='missing'}
}
$red4extState=$fwStates['RED4ext']
$cetState=$fwStates['Cyber Engine Tweaks']

$inputLoader=$compatibility.InputLoader
if($global:RepairMode -or (Get-CyberpunkFixedComponentState -GameRoot $gameRoot -Component $inputLoader) -ne 'compatible'){
    if(-not(Install-Component -Label 'Input Loader' -Urls @($inputLoader.Pinned) -ManualUrl $inputLoader.Page -ManualName $inputLoader.File -PayloadRelFile $inputLoader.Marker)){throw 'Input Loader was not installed. Choose Retry or hand over the matching release ZIP.'}
    Write-OK ('Input Loader '+$inputLoader.Version+' installed for game '+$compatibility.GameVersion+'.')
}else{Write-OK ('Input Loader '+$inputLoader.Version+' is already compatible.')}
if($Route -eq 'Current'){
    if(Test-Path -LiteralPath (Join-Path $gameRoot 'red4ext\plugins\mod_settings\mod_settings.dll') -PathType Leaf){
        [void](Install-CyberpunkCurrentModSettings -GameRoot $gameRoot -Required)
    }
    [void](Move-CyberpunkIncompatibleOccluders -GameRoot $gameRoot)
}

$missingRuntime = @(Get-MissingCyberpunkRuntimeFiles -GameRoot $gameRoot)
if ($missingRuntime.Count -or @(Get-CyberpunkFixedRuntimeProblems $gameRoot).Count) {
    $frameworkStatus=Confirm-CyberpunkFrameworkFiles -GameRoot $gameRoot
    if($frameworkStatus -eq 'Restart'){
        $restart=[InvalidOperationException]::new('The game location was corrected; restarting setup.')
        $restart.Data['PCVRRestart']=$true;throw $restart
    }
}
foreach($component in $compatibility.Components){
    if($fwStates[$component.Name] -eq 'missing' -and (Get-CyberpunkFixedComponentState $gameRoot $component) -eq 'compatible'){$fwStates[$component.Name]='installed'}
}
$red4extState=$fwStates['RED4ext']
$cetState=$fwStates['Cyber Engine Tweaks']

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
$requiredNexus = if($Route -eq 'Depot'){@(Get-NexusChain -Names @("More Occluders (Scripted)"))}else{@()}
if($Route -eq 'Depot'){
Write-Host ""
Write-Host " Required Nexus components for CyberpunkVRPort" -ForegroundColor Cyan
Write-Host " More Occluders (Scripted v0.3) must be present" -ForegroundColor White
Write-Host " before the VR mod is copied. Select the Scripted file on Nexus," -ForegroundColor White
Write-Host " not its ArchiveXL v0.4 main file." -ForegroundColor Yellow
}
foreach ($m in $requiredNexus) {
    if (-not $global:RepairMode -and (Test-Path -LiteralPath (Join-Path $gameRoot $m.Marker) -PathType Leaf)) {
        Write-OK "$($m.Name) is already present."
        continue
    }
    if (-not (Install-NexusMod -Mod $m -GameRoot $gameRoot -TempDir $tempDir -Required)) {
        Write-Fail "$($m.Name) is required. The VR mod was not installed."
    Pause-User "Press Enter for recovery options..."
        throw [InvalidOperationException]::new($(if($script:CyberpunkLastFailure){$script:CyberpunkLastFailure}else{'Cyberpunk setup did not complete; retry or use manual recovery.'}))
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

Write-Info ("Installing CyberpunkVRPort "+$compatibility.ModVersion+" for game "+$compatibility.GameVersion+".")
$modUrls = @((Get-CyberpunkRouteProfile).ModUrl)
$installedTag = (Get-CyberpunkRouteProfile).ModVersion
$MOD_RELEASES = (Get-CyberpunkRouteProfile).ModPage
$modOk = Install-Component -Label "CyberpunkVRPort $installedTag" -Urls $modUrls -ManualUrl $MOD_RELEASES -ManualName ("CyberpunkVRPort-"+$installedTag+".zip") -PayloadRelFile $MOD_MARKER -ExpectedTag $installedTag
if($modOk -and $script:LastCyberpunkPortTag){$installedTag=[string]$script:LastCyberpunkPortTag}
if ($modOk -and -not $installedTag) {
    $installedTag = [string]$script:LastCyberpunkPortTag
    $displayTag = if ($installedTag -match '^[vV]\d') { $installedTag } else { "v$installedTag" }
    $MOD_NAME = "CyberpunkVRPort $displayTag"
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
    # The 0.1.7 publisher removed these older port files. Keep them outside
    # the loadable CET/redscript paths so an update cannot run both versions.
    $legacyPaths = @(
        'r6\scripts\CyberpunkVRPort_LootUi\vrport_loot_ui.reds',
        'r6\scripts\CyberpunkVRPort_SettingsGuard\vrport_settings_guard.reds',
        'bin\x64\plugins\cyber_engine_tweaks\mods\CyberpunkVRPort_QuickBoot'
    )
    if ([version]$installedTag.TrimStart('v','V') -ge [version]'0.1.8') {
        $legacyPaths += @(
            'archive\pc\mod\VRCigarette.archive.xl',
            'archive\pc\mod\vrport_basketball.archive',
            'archive\pc\mod\vrport_mag.archive'
        )
    }
    foreach ($relative in $legacyPaths) {
        $oldPath = Join-Path $gameRoot $relative
        if (-not (Test-Path -LiteralPath $oldPath)) { continue }
        try {
            $backupPath = Join-Path (Join-Path $gameRoot '.pcvrhub_cyberpunkvrport_legacy_backup') $relative
            if (Test-Path -LiteralPath $backupPath) { $backupPath += '.' + [guid]::NewGuid().ToString('N') }
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $backupPath))
            Move-Item -LiteralPath $oldPath -Destination $backupPath -ErrorAction Stop
            Write-OK "Parked obsolete port path: $relative"
        } catch {
            Write-Fail "Could not park obsolete ${relative}: $($_.Exception.Message)"
    Pause-User "Press Enter for recovery options..."
            throw [InvalidOperationException]::new($(if($script:CyberpunkLastFailure){$script:CyberpunkLastFailure}else{'Cyberpunk setup did not complete; retry or use manual recovery.'}))
        }
    }
    foreach ($relative in $MOD_REQUIRED) {
        if (-not (Test-Path -LiteralPath (Join-Path $gameRoot $relative) -PathType Leaf)) {
            Write-Fail "Required port file is missing after installation: $relative"
    Pause-User "Press Enter for recovery options..."
            throw [InvalidOperationException]::new($(if($script:CyberpunkLastFailure){$script:CyberpunkLastFailure}else{'Cyberpunk setup did not complete; retry or use manual recovery.'}))
        }
    }
    foreach ($m in $requiredNexus) {
        if (-not (Test-Path -LiteralPath (Join-Path $gameRoot $m.Marker) -PathType Leaf)) {
            Write-Fail "Required dependency is missing after installation: $($m.Name)"
    Pause-User "Press Enter for recovery options..."
            throw [InvalidOperationException]::new($(if($script:CyberpunkLastFailure){$script:CyberpunkLastFailure}else{'Cyberpunk setup did not complete; retry or use manual recovery.'}))
        }
    }
    $missingRuntime = @(Get-MissingCyberpunkRuntimeFiles -GameRoot $gameRoot)
    if ($missingRuntime.Count -or @(Get-CyberpunkFixedRuntimeProblems $gameRoot).Count) { [void](Confirm-CyberpunkFrameworkFiles -GameRoot $gameRoot -AllowRelocate $false) }
    Save-CyberpunkCompatibilityReceipt -GameRoot $gameRoot
    if($Route -eq 'Current'){Move-CyberpunkRetiredUi -GameRoot $gameRoot}
    Install-CyberpunkRouteLauncher -GameRoot $gameRoot -Route $Route -HubFolder $PSScriptRoot
    if($Route -eq 'Depot'){
        foreach($relative in @('steam_appid.txt','bin\x64\steam_appid.txt')){[IO.File]::WriteAllText((Join-Path $gameRoot $relative),'1091500',[Text.Encoding]::ASCII)}
        $record=@{AppId='1091500';DepotId='1091501';Manifest='4104611899910011352';BuildId='19939064';Mod='0.1.8'}
        $pinText="AppId=1091500`nDepotId=1091501`nManifest=4104611899910011352`nBuildId=19939064`nMod=0.1.8"
        [IO.File]::WriteAllText((Join-Path $gameRoot '.pcvrhub_cyberpunk_depot_231'),$pinText)
    }else{

    }
    $proof=@($GAME_EXE_REL,'archive\pc\content\basegame_1_engine.archive','r6\cache\final.redscripts')+@($MOD_REQUIRED)+@($requiredNexus|ForEach-Object Marker)+@($compatibility.Components|ForEach-Object RequiredFiles)+@($inputLoader.RequiredFiles)+@('PCVR-Cyberpunk\Start VR.vbs','PCVR-Cyberpunk\Start-CyberpunkVR.ps1','.pcvrhub_cyberpunkvrport_ownership.csv')
    if($Route -eq 'Current' -and (Test-Path -LiteralPath (Join-Path $gameRoot 'red4ext\plugins\mod_settings\mod_settings.dll') -PathType Leaf)){$proof+=@($compatibility.ModSettings.RequiredFiles)}
    if($Route -eq 'Depot'){$proof+=@('steam_appid.txt','bin\x64\steam_appid.txt')}
    $contract=New-PCVRInstallerContract -Id 'cyberpunk-2077' -GameName 'Cyberpunk 2077 VR' -Acquisition GitHub -RequiredInstalledFileGroups $proof -Routes @('Current','Depot') -ReleasePageUrl $MOD_RELEASES -AntivirusNotice
    $pathReceipt=Join-Path $PSScriptRoot $(if($Route -eq 'Depot'){'.installed_path_depot'}else{'.installed_path'})
    $pathReceipts=@($pathReceipt)
    if($Route -eq 'Current'){$pathReceipts+=Join-Path $PSScriptRoot '.installed_path_current'}
    if($script:CyberpunkWasFlat){
        $active=Join-Path $gameRoot $MOD_MARKER;$parked=$active+'.pcvrhub_off'
        if(Test-Path -LiteralPath $parked){
            $backup=Join-Path $gameRoot ('.pcvrhub_cyberpunk_retired\flat-plugin-'+[guid]::NewGuid().ToString('N'))
            [void][IO.Directory]::CreateDirectory((Split-Path $backup -Parent));Move-Item -LiteralPath $parked -Destination $backup
        }
        Move-Item -LiteralPath $active -Destination $parked
        Write-OK 'Your Flat mode selection has been kept. Use the Hub Flat / VR switch when ready.'
    }

    $contract.RequiredInstalledFileGroups=@($contract.RequiredInstalledFileGroups|ForEach-Object {if($_ -eq $MOD_MARKER){$MOD_MARKER+'|'+$MOD_MARKER+'.pcvrhub_off'}else{$_}})
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $gameRoot -Version $installedTag -InstalledPathReceiptPaths $pathReceipts -Route $Route)
    $script:CyberpunkCommitted=$true
    # Foundation already wrote the exact game version and typed transaction.
    # The legacy stamp helper would replace that stronger receipt and lose
    # the selected route, payload proof and contract identity.
    if($Route -eq 'Depot'){[IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_version_depot'),$installedTag)}

} else {
    if (Test-Path (Join-Path $gameRoot $MOD_MARKER)) {
        Write-Warn "The selected VR update was not installed. Your previous VR mod is still present."
    } else {
        Write-Fail "The VR mod was not installed."
    }
    # A remaining old plugin must never turn a rejected download into a
    # successful update receipt or reach the normal installation summary.
    Pause-User "Press Enter for recovery options..."
    throw [InvalidOperationException]::new($(if($script:CyberpunkLastFailure){$script:CyberpunkLastFailure}else{'Cyberpunk setup did not complete; retry or use manual recovery.'}))
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

$modPresent = (Test-Path (Join-Path $gameRoot $MOD_MARKER)) -or (Test-Path (Join-Path $gameRoot ($MOD_MARKER+'.pcvrhub_off')))

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ($modPresent -and $Route -eq 'Current') { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {} }

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
Write-Host "  1. Use Start in VR in the Hub." -ForegroundColor White
Write-Host "     Connect your headset and start its OpenXR runtime first." -ForegroundColor White
$shortcutName=if($Route -eq 'Depot'){'Cyberpunk 2077 VR 2.31'}else{'Cyberpunk 2077 VR'}
Write-Host ("  2. Alternatively, use "+$shortcutName+" on your Desktop.") -ForegroundColor White
Write-Host '     These launchers keep Current and Depot save profiles separate.' -ForegroundColor Gray
Write-Host "  3. In-game:  F10 or Insert = VR settings overlay,  F7 = recenter." -ForegroundColor White
Write-Host ""
Write-Host "  - Open the F10 overlay -> VRIK tab to start hand tracking and" -ForegroundColor Gray
Write-Host "    calibrate reach / height / elbow per hand." -ForegroundColor Gray
Write-Host "  - On its first run, the mod backs up your settings before applying" -ForegroundColor Gray
Write-Host "    its VR preset. Language, audio, difficulty and saves are kept." -ForegroundColor Gray
Write-Host "    Your later changes in the game's menus remain in effect." -ForegroundColor Gray
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
# The protected Hub/Desktop route checks the selected game build and
# switches complete save profiles before starting that same game copy.
Write-Host "  1. Use Start in VR in the Hub." -ForegroundColor Green
Write-Host "  Alternative: use the matching Cyberpunk desktop shortcut." -ForegroundColor White
Write-Host "  Your OpenXR runtime has to be running BEFORE it." -ForegroundColor Gray
Write-Host ""
# The one and only cleanup: everything that needed the temp folder -
# the frameworks, the VR mod, the Nexus mods and the repo download -
# is done by now.
try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Write-Host "  Wake up, samurai. Night City won't burn itself down." -ForegroundColor Magenta
Pause-User "Press Enter to close setup..."
   }finally{
    if(-not $script:CyberpunkCommitted -and $script:CyberpunkVrSnapshot){
        Restore-PCVRPublisherZipSnapshot -GameRoot $gameRoot -Snapshot $script:CyberpunkVrSnapshot
        foreach($rel in $MOD_REQUIRED){$path=Join-Path $gameRoot $rel;Write-PCVRFileCheckResult -Path $path -Present (Test-Path -LiteralPath $path -PathType Leaf) -Phase 'after-rollback'}
    }
    if($tempDir -and (Test-Path -LiteralPath $tempDir -PathType Container)){
     $full=[IO.Path]::GetFullPath($tempDir);$prefix=[IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')+'\'
     if($full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($full).StartsWith('CP2077VRInstaller_')){Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction SilentlyContinue}
    }
   }
  }
  break
 }catch{
  if($_.Exception.Data['PCVRRestart']){continue}
  if($_.Exception.GetBaseException() -is [IO.EndOfStreamException]){throw}
  $message='Cyberpunk 2077 VR setup did not complete: '+$_.Exception.Message
  Write-Host $message -ForegroundColor Red
  [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -GameId 'cyberpunk-2077' -InstallerFolder $PSScriptRoot -LogPath ([string]$global:PCVRInstallerLiveLogPath) -RecoveryPageUrl $script:CyberpunkRecoveryPage)
 }
}
