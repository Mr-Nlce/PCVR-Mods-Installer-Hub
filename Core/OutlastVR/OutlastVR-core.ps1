# ============================================================
#  Outlast VR - Halcyon (dhalcyon)
# ------------------------------------------------------------
#  DIE MOD BRINGT IHREN EIGENEN INSTALLER MIT: Outlast-VR.bat.
#  Der MUSS aus dem Spielordner heraus laufen - er prueft selbst,
#  ob OLGame.exe daneben liegt, und bricht sonst ab. Wir kopieren
#  also die vier Dateien nach Binaries\Win64 und starten die Bat
#  DORT. Sie uebernimmt danach den Rest, unter anderem die
#  Konfiguration unter Dokumente\My Games\Outlast.
#
#  DER DOWNLOAD LIEGT HINTER PATREON und braucht eine Anmeldung -
#  wir koennen ihn nicht selbst holen. Deshalb derselbe Weg wie bei
#  den Nexus-Eintraegen: erst auf der Platte nachsehen, sonst die
#  Seite oeffnen und den Nutzer die Datei ablegen lassen.
#
#  ZIELORDNER IST Binaries\Win64, NICHT der Spielordner selbst -
#  das ist die haeufigste Verwechslung bei diesem Spiel.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Outlast VR Installer"
$ErrorActionPreference = "Stop"

# Die Ausgabehelfer bringt JEDER Installer selbst mit - sie stehen NICHT
# in InstallerSafety.ps1.
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

$GAME_NAME   = "Outlast"
$APP_ID      = "238320"
$GAME_EXE    = "OLGame.exe"
$BIN_SUB     = "Binaries\Win64"
$MOD_NAME    = "Outlast VR"
$MOD_AUTHOR  = "Halcyon"
$MOD_VERSION = "August 2026"
$MOD_BAT     = "Outlast-VR.bat"
$MOD_FILES   = @("Outlast-VR.bat", "d3d9.dll", "openxr_loader.dll", "outlastvr.ini")
$POST_URL    = "https://www.patreon.com/dhalcyon/posts/nowhere-to-hide-165840706"
$FILE_URL    = "https://www.patreon.com/file?h=165840706&m=712144361"
$GRAIN_URL   = "https://www.nexusmods.com/outlast/mods/65?tab=files"
$TFC_URL     = "https://www.nexusmods.com/site/mods/588?tab=files"
$DOTNET6_URL = "https://aka.ms/dotnet/6.0/windowsdesktop-runtime-win-x64.exe"

# ---- Kopf -----------------------------------------------------
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host " Outlast VR - Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host ""
Write-Host "  Stereo rendering, full head tracking and VR cutscenes for" -ForegroundColor White
Write-Host "  Outlast. Gamepad in hand - this is not a motion-control mod." -ForegroundColor White
Write-Host ""
Write-Host "  One thing before you start:" -ForegroundColor White
Write-Host "   - " -NoNewline -ForegroundColor White
Write-Host " RUN OUTLAST ONCE NORMALLY FIRST " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     The game creates its settings files on that first launch," -ForegroundColor White
Write-Host "     and the mod's own installer needs them to be there." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# ---- 1. Spiel finden ------------------------------------------
Write-Step 1 5 "Locating $GAME_NAME"
$gameRoot = Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @("Outlast") -ProbeExe "$BIN_SUB\$GAME_EXE"
if (-not $gameRoot) {
    # GOG und Epic legen dieselbe Struktur an, nur woanders.
    foreach ($c in @("C:\GOG Games\Outlast",
                     "C:\Program Files (x86)\GOG Galaxy\Games\Outlast",
                     "C:\Program Files\Epic Games\Outlast",
                     "C:\Program Files (x86)\Epic Games\Outlast")) {
        if (Test-Path -LiteralPath (Join-Path $c "$BIN_SUB\$GAME_EXE")) { $gameRoot = $c; break }
    }
}
if (-not $gameRoot) {
    Write-Warn "Could not find $GAME_NAME automatically."
    Write-Host "  Point me at the folder that CONTAINS Binaries\, for example:" -ForegroundColor White
    Write-Host "     C:\Program Files (x86)\Steam\steamapps\common\Outlast" -ForegroundColor Gray
    $gameRoot = (Read-Host "  Game folder").Trim().Trim('"')
}
$binDir = Join-Path $gameRoot $BIN_SUB
if (-not (Test-Path -LiteralPath (Join-Path $binDir $GAME_EXE))) {
    Write-Fail "No $GAME_EXE under $BIN_SUB - stopping rather than guessing."
    Write-Host "  Expected: $binDir\$GAME_EXE" -ForegroundColor Yellow
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Game folder: $gameRoot"
Write-OK "Mod files go into: $binDir"

# Schreibrechte still pruefen - die Ansage kommt dort, wo sie gilt.
$needsAdmin = $false
try {
    $probe = Join-Path $binDir ".pcvrhub_write_probe"
    Set-Content -LiteralPath $probe -Value "ok" -ErrorAction Stop
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
} catch { $needsAdmin = $true }

# ---- 2. Archiv besorgen ---------------------------------------
Write-Step 2 5 "The download"
Write-Host ""
# !!! PATREON-DATEILINKS SIND OEFFENTLICH - WIR KOENNEN SIE HOLEN !!!
# Eine Adresse der Form patreon.com/file?h=...&m=... braucht KEINE
# Anmeldung und ist unabhaengig vom Konto abrufbar. Der Luke-Ross-
# Installer laedt seine Mod seit jeher genau so (Zeile 448 dort).
# Deshalb wird hier NICHT nach einer Handablage gefragt, sondern
# direkt geladen - die Suche auf der Platte ist nur der Rueckfall,
# falls die Datei schon da liegt oder das Netz streikt.
$patterns = @("*Outlast*VR*.zip", "*OutlastVR*.zip", "*Outlast*.zip")
$modZip = Find-PredownloadedFile -Patterns $patterns -Label "the Outlast VR mod"
if (-not $modZip) {
    $tmpDl = Join-Path $env:TEMP ("outlastvr_dl_" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmpDl -Force | Out-Null
    $dest = Join-Path $tmpDl "Outlast-VR.zip"
    Invoke-SafeDownload -Urls @($FILE_URL) -Destination $dest -Label "$MOD_NAME" `
        -ManualUrl $POST_URL `
        -Instructions "Download the Outlast VR ZIP from the Patreon post, save it as '$dest', then choose Retry."
    if (Test-Path -LiteralPath $dest) { $modZip = $dest }
}
if (-not $modZip -or -not (Test-Path -LiteralPath $modZip)) {
    Write-Fail "No archive found - nothing was changed."
    Write-Host "  Download it from:" -ForegroundColor White
    Write-Host "     $POST_URL" -ForegroundColor Cyan
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "Using: $modZip"

# ---- 3. Dateien an ihren Platz --------------------------------
Write-Step 3 5 "Copying the files next to $GAME_EXE"

$tmp = Join-Path $env:TEMP ("outlastvr_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
[void](Expand-ArchiveOrFallback -ArchivePath $modZip -DestinationFolder $tmp -Label $MOD_NAME)

# Die Dateien koennen flach oder in einem Wrapper-Ordner liegen - deshalb
# ueber den GANZEN Baum nach der bekannten Bat suchen, nicht auf einer
# festen Ebene.
$allFiles = @(Get-ChildItem -LiteralPath $tmp -Recurse -File -Force -ErrorAction SilentlyContinue)
if ($needsAdmin) {
    Pause-User "Press Enter to copy the files into the game folder - UAC required..." | Out-Null
}
$sources = @(); $copyFailed = $false
foreach ($f in $MOD_FILES) {
    $hit = $allFiles | Where-Object { $_.Name -ieq $f } | Select-Object -First 1
    if (-not $hit) { continue }
    $sources += $hit.FullName
    try { Copy-Item -LiteralPath $hit.FullName -Destination (Join-Path $binDir $f) -Force -ErrorAction Stop }
    catch { $copyFailed = $true }
}
if ($copyFailed -and $sources.Count -gt 0) {
    Write-Warn "Copying into that folder needs administrator rights. Asking for them ..."
    $srcList = ($sources | ForEach-Object { "'" + $_ + "'" }) -join ","
    $ps = "foreach (`$s in @($srcList)) { Copy-Item -LiteralPath `$s -Destination '$binDir' -Force }"
    try { Start-Process powershell -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-Command",$ps) -Verb RunAs -Wait -ErrorAction Stop }
    catch { Write-Warn "The elevated copy was declined or failed." }
}

$missing = @()
foreach ($f in $MOD_FILES) { if (-not (Test-Path -LiteralPath (Join-Path $binDir $f))) { $missing += $f } }
try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

if ($missing.Count -gt 0) {
    Write-Fail "These files did not arrive:"
    foreach ($m in $missing) { Write-Host "   $m" -ForegroundColor Yellow }
    Write-Host "  Copy them by hand into:" -ForegroundColor White
    Write-Host "     $binDir" -ForegroundColor Yellow
    Pause-User "Press Enter to exit."
    exit 1
}
Write-OK "All four files are in place."

# ---- 4. Der Installer der Mod ---------------------------------
Write-Step 4 5 "Running the mod's own installer"
Write-Host ""
Write-Host "  $MOD_BAT does the actual setup, and it has to run from the" -ForegroundColor White
Write-Host "  game folder - which is where it now sits. It also writes to" -ForegroundColor White
Write-Host "  Outlast's config under your Documents folder." -ForegroundColor White
Write-Host ""
Write-Host "  Make sure Outlast is CLOSED - the script checks and refuses" -ForegroundColor White
Write-Host "  to run otherwise." -ForegroundColor White
Write-Host ""
$batPath = Join-Path $binDir $MOD_BAT
Pause-User "Press Enter to run $MOD_BAT..." | Out-Null
try {
    Start-Process -FilePath $batPath -WorkingDirectory $binDir -Wait -ErrorAction Stop
    Write-OK "$MOD_BAT finished."
} catch {
    Write-Warn "Could not start it: $($_.Exception.Message)"
    Write-Host "  Run it yourself from: $binDir" -ForegroundColor Yellow
}

# Merker fuer den Hub - in den INSTALLERORDNER, nicht in den Spielordner.
try { Set-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -Value $gameRoot -Encoding UTF8 -Force } catch {}

# ---- 5. Filmkorn entfernen (freiwillig) -----------------------
# !!! DIESER ZUSATZMOD LAESST SICH NICHT DURCH KOPIEREN INSTALLIEREN !!!
# Nachgezaehlt: das Archiv enthaelt SIEBEN Dateien und KEINE EINZIGE
# davon gehoert ins Spiel - es sind GameProfile.xml, ObjectDescriptors
# und ein TexturePack, also ANWEISUNGEN FUER EIN PATCH-WERKZEUG. Laut
# GameProfile.xml aendert es die .upk-Pakete unter OLGame\CookedPCConsole.
# Ohne dieses Werkzeug gibt es NICHTS zu kopieren, und wir tun auch
# nicht so. Was wir tun koennen: die Datei besorgen und sie dorthin
# legen, wo der Nutzer sie findet.
$grainRemoved = $false
Write-Step 5 5 "Optional: remove the film grain"
Write-Host ""
Write-Host "  Outlast has film grain baked in - it is the game, not the mod." -ForegroundColor White
Write-Host "  A Nexus mod removes it without touching the other post effects." -ForegroundColor White
Write-Host "" 
Write-Host "  Purely cosmetic - VR works fine without it. It takes about five" -ForegroundColor Gray
Write-Host "  minutes: two downloads, then three clicks in a small tool that" -ForegroundColor Gray
Write-Host "  this installer opens and walks you through." -ForegroundColor Gray
Write-Host ""
if (Read-YesNo "  Fetch the film-grain mod as well?") {
    # Gegenstueck zur Ueberschrift der zweiten Haelfte weiter unten -
    # sonst sieht nur die zweite wie ein eigener Abschnitt aus.
    Write-Host ""
    Write-Host " ============================================================" -ForegroundColor Magenta
    Write-Host "  FIRST HALF - getting the two downloads" -ForegroundColor Cyan
    Write-Host " ============================================================" -ForegroundColor Magenta
    $fgPatterns = @("*Remove*Film*Grain*.zip", "*FilmGrain*.zip")
    $fgZip = Find-PredownloadedFile -Patterns $fgPatterns -Label "the film-grain mod"
    if (-not $fgZip) {
        Pause-User "Press Enter to open the Nexus page..." | Out-Null
        try { Start-Process $GRAIN_URL } catch { Write-Warn "Open manually: $GRAIN_URL" }
        Pause-User "Press Enter once the download has finished..." | Out-Null
        $fgZip = Find-PredownloadedFile -Patterns $fgPatterns -Label "the film-grain mod" -PageAlreadyOpen
    }
    if ($fgZip -and (Test-Path -LiteralPath $fgZip)) {
        # Neben das Spiel legen - NICHT hinein, es gehoert ja nicht dorthin.
        $fgDir = Join-Path $gameRoot "_FilmGrainMod"
        try {
            New-Item -ItemType Directory -Path $fgDir -Force -ErrorAction Stop | Out-Null
            [void](Expand-ArchiveOrFallback -ArchivePath $fgZip -DestinationFolder $fgDir -Label "film-grain mod")
            # Im Archiv liegt ein Unterordner mit der GameProfile.xml - und
            # GENAU DEN will das Werkzeug haben, nicht den darueber.
            $gp = Get-ChildItem -LiteralPath $fgDir -Recurse -File -Force -ErrorAction SilentlyContinue |
                  Where-Object { $_.Name -ieq "GameProfile.xml" } | Select-Object -First 1
            if ($gp) { $fgDir = $gp.DirectoryName }
            Write-OK "Mod folder ready: $fgDir"
        } catch { Write-Warn "Could not unpack it: $($_.Exception.Message)" }

        # ---- Das Werkzeug besorgen ------------------------------------
        # !!! DER TEXT ALLEIN NUTZT NIEMANDEM - er scrollt weg, bevor man
        # ihn braucht. Also holen wir das Werkzeug auch, legen es neben den
        # Mod-Ordner und starten es. Die drei Schritte stehen dann direkt
        # ueber dem laufenden Fenster.
        # !!! DIESER UEBERGANG GING IM DOWNLOADRAUSCHEN UNTER !!!
        # Der Nutzer hat gerade zwei Fragen zu Downloads beantwortet und
        # sieht lauter [OK]-Zeilen. Ein weisser Absatz dazwischen faellt
        # nicht auf - hier faengt aber ein EIGENER Abschnitt an. Also
        # dieselbe Ueberschrift wie bei den Schritten weiter unten.
        Write-Host ""
        Write-Host ""
        Write-Host " ============================================================" -ForegroundColor Magenta
        Write-Host "  NOW THE SECOND HALF - a small tool does the actual work" -ForegroundColor Cyan
        Write-Host " ============================================================" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "  What you just downloaded is NOT copied into the game. It is" -ForegroundColor White
        Write-Host "  a texture pack, and a tool has to patch it into Outlast's" -ForegroundColor White
        Write-Host "  own packages. That tool is free, and this installer fetches" -ForegroundColor White
        Write-Host "  it, opens it and walks you through three clicks." -ForegroundColor White
        Write-Host ""
        Write-Host "     TFC Installer for UE2-UE3" -ForegroundColor Cyan
        Write-Host ""
        $tfcPatterns = @("*TFC*Installer*.zip", "*TFCInstaller*.zip")
        $tfcZip = Find-PredownloadedFile -Patterns $tfcPatterns -Label "the TFC Installer"
        if (-not $tfcZip) {
            Pause-User "Press Enter to open its download page..." | Out-Null
            try { Start-Process $TFC_URL } catch { Write-Warn "Open manually: $TFC_URL" }
            Write-Host ""
            Write-Host "  Grab the file under Main files, then come back here." -ForegroundColor White
            Pause-User "Press Enter once the download has finished..." | Out-Null
            $tfcZip = Find-PredownloadedFile -Patterns $tfcPatterns -Label "the TFC Installer" -PageAlreadyOpen
        }

        $tfcExe = $null
        if ($tfcZip -and (Test-Path -LiteralPath $tfcZip)) {
            $tfcDir = Join-Path $gameRoot "_FilmGrainMod\TFCInstaller"
            try {
                New-Item -ItemType Directory -Path $tfcDir -Force -ErrorAction Stop | Out-Null
                [void](Expand-ArchiveOrFallback -ArchivePath $tfcZip -DestinationFolder $tfcDir -Label "TFC Installer")
                $hit = Get-ChildItem -LiteralPath $tfcDir -Recurse -File -Force -ErrorAction SilentlyContinue |
                       Where-Object { $_.Name -ieq "TFCInstaller.exe" } | Select-Object -First 1
                if ($hit) { $tfcExe = $hit.FullName; Write-OK "Tool ready: $tfcExe" }
                else { Write-Warn "No TFCInstaller.exe inside that archive." }
            } catch { Write-Warn "Could not unpack the tool: $($_.Exception.Message)" }
        }

        if ($tfcExe) {
            # ---- ZUERST STARTEN, DANN FUEHREN -------------------------
            # Frueher standen hier alle drei Schritte auf einmal, und
            # danach kam erst der Start - bis der Nutzer sie brauchte,
            # waren sie weggescrollt. Jetzt: Werkzeug oeffnen, pruefen ob
            # es laeuft, und DANN je EIN Schritt mit eigener Enter-Schranke
            # und dem passenden Pfad in der Zwischenablage.
            Write-Host ""
            Write-Host "  The tool opens now. Leave this window where it is -" -ForegroundColor White
            Write-Host "  it will walk you through three steps, one at a time." -ForegroundColor White
            Pause-User "Press Enter to open the tool..." | Out-Null
            try { Start-Process -FilePath $tfcExe -WorkingDirectory (Split-Path $tfcExe -Parent) } catch {
                Write-Warn "Could not start it: $($_.Exception.Message)"
            }

            # ---- Laeuft es ueberhaupt? --------------------------------
            Write-Host ""
            Write-Host "  Did a window open?" -ForegroundColor White
            Write-Host "     Enter        yes - carry on" -ForegroundColor Gray
            Write-Host "     I  + Enter   no, nothing happened" -ForegroundColor Gray
            $ans = ""
            try { $ans = (Read-Host "  Your answer").Trim().ToUpper() } catch {}
            if ($ans -eq "I") {
                # Das Werkzeug nennt .Net 6 in seiner eigenen
                # Requirements.txt. Fehlt sie, kommt WEDER Fenster NOCH
                # Fehlermeldung - deshalb ist die Frage oben der einzige
                # verlaessliche Weg, das zu erkennen.
                Write-Host ""
                Write-Host "  Then the .NET Desktop Runtime 6 is missing - the tool" -ForegroundColor White
                Write-Host "  needs it and says so in its own requirements. Without it" -ForegroundColor White
                Write-Host "  nothing appears at all, not even an error." -ForegroundColor White
                Write-Host ""
                $rtDir = Join-Path $env:TEMP ("dotnet6_" + [System.IO.Path]::GetRandomFileName())
                New-Item -ItemType Directory -Path $rtDir -Force | Out-Null
                $rtExe = Join-Path $rtDir "windowsdesktop-runtime-6-win-x64.exe"
                Invoke-SafeDownload -Urls @($DOTNET6_URL) -Destination $rtExe -Label ".NET Desktop Runtime 6" `
                    -ManualUrl $DOTNET6_URL `
                    -Instructions "Download the .NET Desktop Runtime 6 (x64) installer, save it as '$rtExe', then choose Retry."
                if (Test-Path -LiteralPath $rtExe) {
                    Pause-User "Press Enter to install it - UAC required..." | Out-Null
                    try { Start-Process -FilePath $rtExe -Wait -Verb RunAs -ErrorAction Stop; Write-OK "Runtime installed." }
                    catch { Write-Warn "The install was declined or failed: $($_.Exception.Message)" }
                    Pause-User "Press Enter to open the tool again..." | Out-Null
                    try { Start-Process -FilePath $tfcExe -WorkingDirectory (Split-Path $tfcExe -Parent) } catch {
                        Write-Warn "Still could not start it. Run it by hand: $tfcExe"
                    }
                }
                try { Remove-Item -LiteralPath $rtDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            }

            # ---- Schritt 1 von 3 --------------------------------------
            try { Set-Clipboard -Value $gameRoot } catch {}
            Write-Host ""
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " STEP 1 of 3 - the Game folder" -ForegroundColor Cyan
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  In the tool:" -ForegroundColor White
            Write-Host "   a) click the " -NoNewline -ForegroundColor White
            Write-Host " Game folder " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host " button" -ForegroundColor White
            Write-Host "   b) click into the LOWER text field" -ForegroundColor White
            Write-Host "   c) Ctrl+V, press " -NoNewline -ForegroundColor White
            Write-Host " Select Folder " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Write-Host "  This path is on your clipboard now:" -ForegroundColor White
            Write-Host ""
            Write-Host "   $gameRoot " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Pause-User "Done? Press Enter for step 2..." | Out-Null

            # ---- Schritt 2 von 3 --------------------------------------
            try { Set-Clipboard -Value $fgDir } catch {}
            Write-Host ""
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " STEP 2 of 3 - the Mod folder" -ForegroundColor Cyan
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "   a) click the " -NoNewline -ForegroundColor White
            Write-Host " Mod folder " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host " button" -ForegroundColor White
            Write-Host "   b) click into the same LOWER text field" -ForegroundColor White
            Write-Host "   c) Ctrl+V, press " -NoNewline -ForegroundColor White
            Write-Host " Select Folder " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Write-Host "  This path is on your clipboard now:" -ForegroundColor White
            Write-Host ""
            Write-Host "   $fgDir " -ForegroundColor Black -BackgroundColor Yellow
            Write-Host ""
            Pause-User "Done? Press Enter for step 3..." | Out-Null

            # ---- Schritt 3 von 3 --------------------------------------
            Write-Host ""
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host " STEP 3 of 3 - apply it" -ForegroundColor Cyan
            Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  Click " -NoNewline -ForegroundColor White
            Write-Host " Update Outlast + DLCs " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host " and wait." -ForegroundColor White
            Write-Host "  It just skips the DLCs if they are not installed." -ForegroundColor Gray
            Write-Host ""
            Write-Host "  It copies your original packages aside first, inside the" -ForegroundColor Gray
            Write-Host "  game folder. Restore Backup in the same tool puts them" -ForegroundColor Gray
            Write-Host "  back, so nothing here is permanent." -ForegroundColor Gray
            Write-Host ""
            Write-Host "  When it says it finished, CLOSE the tool - you do not need" -ForegroundColor White
            Write-Host "  it again unless you want to undo this." -ForegroundColor White
            Write-Host ""
            Pause-User "Closed it? Press Enter to finish..." | Out-Null
            Write-OK "Film grain removed. Start the game and see."
            # Merken, damit der Schlusstext weiter unten nicht behauptet,
            # das Korn sei noch da.
            $grainRemoved = $true
        } else {
            Write-Info "Without the tool the files just sit there - they are here when you want them:"
            Write-Host "     $fgDir" -ForegroundColor Yellow
            Write-Host "  Get the tool at: $TFC_URL" -ForegroundColor Cyan
        }

    } else {
        Write-Info "Skipped - nothing was changed."
    }
} else {
    Write-Info "Skipped. You can run this installer again later."
}

Write-Host ""
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " IN THE GAME" -ForegroundColor Cyan
Write-Host " ------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Press Insert to open the menu, then the VR tab - tune Eye" -ForegroundColor White
Write-Host "  Separation and Convergence until it sits right for you." -ForegroundColor White
Write-Host "  Turn motion blur OFF in Outlast's own settings." -ForegroundColor White
Write-Host ""
Write-Host "  One thing the author names himself, so it does not surprise" -ForegroundColor Gray
Write-Host "  you: light flares can pass through walls. Harmless, and not" -ForegroundColor Gray
Write-Host "  fixed yet." -ForegroundColor Gray
Write-Host ""
if ($grainRemoved) {
    Write-Host "  Outlast has film grain baked in - but you just removed it" -ForegroundColor Gray
    Write-Host "  with the Remove Film Grain mod, so that one is handled." -ForegroundColor Gray
} else {
    Write-Host "  Outlast also has film grain baked in. Run this installer" -ForegroundColor Gray
    Write-Host "  again if you want to remove it - it is the last step." -ForegroundColor Gray
}
Write-Host ""
Write-Host "  You are not armed. You never were. Now you can look behind you." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
