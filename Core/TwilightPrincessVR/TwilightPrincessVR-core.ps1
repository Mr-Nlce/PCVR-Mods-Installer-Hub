# ============================================================
#  The Legend of Zelda: Twilight Princess VR - Dusklight VR
#  von JoeyAW
# ------------------------------------------------------------
#  EIGENSTAENDIG, wie Ocarina of Time VR: es gibt kein Spiel zum
#  Patchen. Der Port bringt eine eigene dusklight.exe mit, und der
#  Nutzer legt seinen EIGENEN Spielabzug daneben. Wir laden also
#  das Release, entpacken es an einen Ort seiner Wahl und legen
#  eine Verknuepfung an.
#
#  ZWEI DINGE, DIE DIESEN EINTRAG BESONDERS MACHEN:
#  1. DAS ARCHIV IST RIESIG - ueber 500 MB gepackt, rund 2 GB
#     entpackt. Der Autor liefert seinen KOMPLETTEN Bauordner mit
#     (_deps, CMakeFiles, .pdb, .lib, .obj). Zum Spielen braucht es
#     davon vielleicht 90 MB. Das sagen wir dem Nutzer vorher, damit
#     er nicht denkt, etwas sei schiefgelaufen.
#  2. DIE EXE LIEGT IN EINEM UNTERORDNER windows-msvc-relwithdebinfo,
#     nicht in der Wurzel des Archivs.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Twilight Princess VR Installer"
$ErrorActionPreference = "Stop"

# Die Ausgabehelfer bringt JEDER Installer selbst mit.
function Write-Step {
    param([int]$Step, [int]$Total, [string]$Title)
    Write-Host ""
    Write-Host "[$Step/$Total] $Title" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}
function Write-OK   { param($m) Write-Host " [OK] $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host " [i] $m"  -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host " [!] $m"  -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host " [X] $m"  -ForegroundColor Red }
function Pause-User {
    param($text = "Press Enter to continue...")
    Write-Host ""
    Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow
    Read-Host
}
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

# Use the Hub's clean native 7-Zip percentage display for both large
# Twilight Princess archives. Resolve 7-Zip only once; if the user declines
# it or the progress extraction fails, keep the established safe fallback.
$script:TwilightSevenZipChecked = $false
$script:TwilightSevenZip = $null
function Expand-TwilightArchive {
    param(
        [Parameter(Mandatory=$true)][string]$Archive,
        [Parameter(Mandatory=$true)][string]$Destination,
        [Parameter(Mandatory=$true)][string]$Label
    )
    if (-not $script:TwilightSevenZipChecked) {
        $script:TwilightSevenZipChecked = $true
        $script:TwilightSevenZip = Get-SevenZip
    }
    if ($script:TwilightSevenZip) {
        if (Expand-7zWithProgress -SevenZip $script:TwilightSevenZip -Archive $Archive -Dest $Destination -Label $Label) {
            return "ok"
        }
        Write-Warn "The progress extraction failed - trying the safe fallback."
    }
    return (Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $Destination -Label $Label)
}

$MOD_NAME    = "Dusklight VR"
$MOD_AUTHOR  = "JoeyAW"
$REPO        = "JoeyAW/dusklight-vr"
$RELEASES    = "https://github.com/$REPO/releases"
$ASSET       = "Dusklight-VR-Windows-x64.zip"
$BUILD_SUB   = "windows-msvc-relwithdebinfo"
$GAME_EXE    = "dusklight.exe"
$DEFAULT_DIR = "C:\Games\Twilight Princess VR"
$TEX_PAGE    = "https://www.henrikomagnifico.com/zelda-twilight-princess-4k"
# Der Texturordner liegt NICHT im Installationsordner, sondern unter
# %APPDATA% - das ist die haeufigste Verwechslung bei diesem Paket.
$TEX_DIR     = Join-Path $env:APPDATA "TwilitRealm\Dusklight\texture_replacements"

# ---- Kopf -----------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " The Legend of Zelda: Twilight Princess VR" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Twilight Princess in stereoscopic VR with tracked hands -" -ForegroundColor White
Write-Host "  swing the sword, bash with the shield, aim with your right" -ForegroundColor White
Write-Host "  hand. You can drop to flatscreen any time for the parts you" -ForegroundColor White
Write-Host "  would rather not play in a headset." -ForegroundColor White
Write-Host ""
Write-Host "  YOU SUPPLY THE GAME. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  This port ships no game data at all. You need your own dump" -ForegroundColor White
Write-Host "  of the GameCube release as .iso or .rvz - other versions are" -ForegroundColor White
Write-Host "  not supported yet." -ForegroundColor White
Write-Host ""
Write-Host "  Tested on Quest 2 and 3; other headsets are untested. Needs a" -ForegroundColor Gray
Write-Host "  D3D12-capable GPU, Windows only. Virtual Desktop with VDXR is" -ForegroundColor Gray
Write-Host "  the author's recommendation for performance." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Ort waehlen -------------------------------------------
Write-Step 1 5 "Choosing where it goes"
Write-Host ""
Write-Host "  This is a standalone build - it does not go into any existing" -ForegroundColor White
Write-Host "  game folder. Pick a place with room to spare." -ForegroundColor White
Write-Host ""
Write-Host "    Default: $DEFAULT_DIR" -ForegroundColor Cyan
Write-Host ""
$dir = ""
try { $dir = (Read-Host "  Folder (Enter for the default)").Trim().Trim('"') } catch {}
if (-not $dir) { $dir = $DEFAULT_DIR }
try { New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null }
catch {
    Write-Fail "Could not create $dir - $($_.Exception.Message)"
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Install folder: $dir"

# ---- 2. Herunterladen -----------------------------------------
Write-Step 2 5 "Downloading $MOD_NAME"
Write-Host ""
Write-Host "  HEADS UP - THIS IS A BIG ONE. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Over 500 MB to download and around 2 GB once unpacked. That" -ForegroundColor White
Write-Host "  is not a mistake: the author ships his whole build folder," -ForegroundColor White
Write-Host "  compiler leftovers and all. The game itself is a fraction of" -ForegroundColor White
Write-Host "  it. Nothing is wrong if it takes a while." -ForegroundColor White
Write-Host ""

$tmp = Join-Path $env:TEMP ("dusklight_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$zip = Join-Path $tmp $ASSET

$url = "https://github.com/$REPO/releases/latest/download/$ASSET"
$tag = "latest"
try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" `
               -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
    if (Test-IsPayloadRelease -Release $rel) {
        $pick = Select-PayloadAsset -Assets $rel.assets -PlatformPattern '(?i)windows|x64' -MinBytes 10000000
        if ($pick -and $pick.browser_download_url) {
            $url = [string]$pick.browser_download_url
            $tag = [string]$rel.tag_name
        }
    }
    Write-OK "Release: $tag"
} catch { Write-Warn "GitHub could not be reached - trying the direct link." }

# Vorhandene Datei auf der Platte zuerst - bei dieser Groesse ein
# echter Zeitgewinn, wenn der Nutzer sie schon geladen hat.
$have = Find-PredownloadedFile -Patterns @("Dusklight-VR-Windows*.zip", "*Dusklight*VR*.zip") -Label "the Dusklight VR release"
if ($have -and (Test-Path -LiteralPath $have)) {
    $zip = $have
} else {
    Invoke-SafeDownload -Urls @($url) -Destination $zip -Label "$MOD_NAME $tag" `
        -ManualUrl $RELEASES `
        -Instructions "Download $ASSET from the releases page, save it as '$zip', then choose Retry."
}
if (-not (Test-Path -LiteralPath $zip)) {
    Write-Fail "No archive - nothing was changed."
    try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}

# ---- 3. Entpacken ---------------------------------------------
Write-Step 3 5 "Unpacking"
Write-Host "  This takes a few minutes - it is a lot of small files." -ForegroundColor Gray
[void](Expand-TwilightArchive -Archive $zip -Destination $dir -Label $MOD_NAME)

# Die Exe liegt in windows-msvc-relwithdebinfo, nicht in der Wurzel -
# aber ueber den ganzen Baum suchen, falls der Autor das aendert.
$exe = Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction SilentlyContinue |
       Where-Object { $_.Name -ieq $GAME_EXE } | Select-Object -First 1
if (-not $exe) {
    Write-Fail "No $GAME_EXE below $dir - the install did not complete."
    Write-Host "  Expected it in: $dir\$BUILD_SUB\" -ForegroundColor Yellow
    try { if ($zip -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Ready: $($exe.FullName)"
try { if ($zip -like "$tmp*") { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } } catch {}

# ---- 4. Verknuepfung und Merker -------------------------------
Write-Step 4 5 "Finishing up"
$exeDir = Split-Path $exe.FullName -Parent
try {
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "Twilight Princess VR.lnk"))
    $lnk.TargetPath = $exe.FullName
    $lnk.WorkingDirectory = $exeDir
    $lnk.Save()
    Write-OK "Desktop shortcut created."
} catch { Write-Warn "Could not create the desktop shortcut." }

# Merker fuer den Hub - in den INSTALLERORDNER.
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $dir -Encoding UTF8 -Force } catch {}
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".launch_exe")     -Value $exe.FullName -Encoding UTF8 -Force } catch {}

# ---- 5. 4K-Texturpaket (freiwillig) ---------------------------
# Von Henriko Magnifico. Liegt auf MediaFire - eine Adresse, die wir
# NICHT selbst laden koennen (Weiterleitung ueber eine Downloadseite).
# Also: Seite oeffnen, warten, danach in den Downloads suchen.
Write-Step 5 5 "Optional: the 4K texture pack"
Write-Host ""
Write-Host "  Henriko Magnifico's pack redraws the game's textures at 4K." -ForegroundColor White
Write-Host "  It works with Dusklight and is switched on inside the game." -ForegroundColor White
Write-Host ""
Write-Host "  ANOTHER BIG ONE - about 5 GB unpacked. " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Purely cosmetic; the game runs fine without it." -ForegroundColor Gray
Write-Host ""
if (Read-YesNo "  Set up the 4K texture pack as well?") {
    $texPatterns = @("ZTP*4K*.zip", "*Twilight*4K*.zip", "*HenrikosTP4K*.zip")
    $texZip = Find-PredownloadedFile -Patterns $texPatterns -Label "the 4K texture pack"
    if (-not $texZip) {
        Write-Host ""
        Write-Host "  The pack is hosted on the author's site, so it cannot be" -ForegroundColor White
        Write-Host "  fetched from here - the page opens and you download it" -ForegroundColor White
        Write-Host "  there. EXPECT THIS TO TAKE A WHILE." -ForegroundColor White
        Write-Host ""
        Pause-User "Press Enter to open the download page..." | Out-Null
        try { Start-Process $TEX_PAGE } catch { Write-Warn "Open manually: $TEX_PAGE" }
        Write-Host ""
        Write-Host "  Grab the newest 'ZTP 4K ... (4K, PC Edition)' file, then" -ForegroundColor White
        Write-Host "  come back here. Leave it in your Downloads folder or drag" -ForegroundColor White
        Write-Host "  it onto this window." -ForegroundColor White
        Pause-User "Press Enter once the download has finished..." | Out-Null
        $texZip = Find-PredownloadedFile -Patterns $texPatterns -Label "the 4K texture pack" -PageAlreadyOpen
    }
    if ($texZip -and (Test-Path -LiteralPath $texZip)) {
        Write-Host ""
        Write-Host "  Unpacking - this one takes several minutes." -ForegroundColor Gray
        $textureLocation = Join-Path $TEX_DIR "HenrikosTP4K_..."
        try {
            New-Item -ItemType Directory -Path $TEX_DIR -Force -ErrorAction Stop | Out-Null
            [void](Expand-TwilightArchive -Archive $texZip -Destination $TEX_DIR -Label "4K texture pack")
            # IMPORTANT: Dusklight expects the pack's own HenrikosTP4K...
            # folder to remain directly below texture_replacements. Do not
            # flatten it or move its province folders one level upwards.
            $packFolder = Get-ChildItem -LiteralPath $TEX_DIR -Directory -Force -ErrorAction SilentlyContinue |
                          Where-Object { $_.Name -like "HenrikosTP4K*" } |
                          Sort-Object LastWriteTime -Descending |
                          Select-Object -First 1
            if ($packFolder) {
                $dds = @(Get-ChildItem -LiteralPath $packFolder.FullName -Recurse -Filter "*.dds" -File -ErrorAction SilentlyContinue)
                if ($dds.Count -gt 0) { Write-OK "$($dds.Count) textures kept inside '$($packFolder.Name)'." }
                else { Write-Warn "No .dds files found inside $($packFolder.FullName) - check the archive by hand." }
                $textureLocation = $packFolder.FullName
            } else {
                Write-Warn "The required HenrikosTP4K folder was not found below $TEX_DIR."
            }
        } catch { Write-Warn "Could not unpack it: $($_.Exception.Message)" }
        Write-Host ""
        Write-Host "  They live here, NOT in the install folder:" -ForegroundColor White
        Write-Host "   $textureLocation " -ForegroundColor Black -BackgroundColor Yellow
        Write-Host "  Keep the HenrikosTP4K folder itself - do not move its contents out." -ForegroundColor Gray
        Write-Host ""
        Write-Host "  ONE SWITCH LEFT, INSIDE THE GAME:" -ForegroundColor Yellow
        Write-Host "  Settings > Video > turn " -NoNewline -ForegroundColor White
        Write-Host " Use Texture Pack " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
        Write-Host " on." -ForegroundColor White
        Write-Host "  Without that the textures sit there and do nothing." -ForegroundColor Gray
    } else {
        Write-Info "Skipped - you can run this installer again later."
    }
} else {
    Write-Info "Skipped."
}

Write-Host ""
Write-Host " ============================================================" -ForegroundColor Magenta
Write-Host "  NOW YOUR OWN COPY OF THE GAME" -ForegroundColor Cyan
Write-Host " ============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Dusklight ships no game data. Dump your own GameCube disc" -ForegroundColor White
Write-Host "  and point the launcher at the .iso or .rvz when it asks." -ForegroundColor White
Write-Host "  Dolphin's wiki explains dumping; nodtool or Dolphin can turn" -ForegroundColor White
Write-Host "  an .iso into the smaller .rvz." -ForegroundColor White
Write-Host ""
Write-Host "  To play: start your VR software FIRST, then run the shortcut." -ForegroundColor White
Write-Host "  A window opens on your desktop - press Enter there or click" -ForegroundColor White
Write-Host "  Play to start the game. Nothing appears in the headset before" -ForegroundColor White
Write-Host "  that." -ForegroundColor White
Write-Host ""
Write-Host "  Worth knowing, straight from the author:" -ForegroundColor Gray
Write-Host "   - Cutscenes are broken in VR by design of the engine -" -ForegroundColor Gray
Write-Host "     watch them in flatscreen." -ForegroundColor Gray
Write-Host "   - Wolf Link sections stay in third person." -ForegroundColor Gray
Write-Host "   - After a loading screen, stand still for about 3 seconds" -ForegroundColor Gray
Write-Host "     until the hearts and map appear - that settles the camera" -ForegroundColor Gray
Write-Host "     height." -ForegroundColor Gray
Write-Host ""
Write-Host "  Twilight and light, and you between them - with a sword." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
