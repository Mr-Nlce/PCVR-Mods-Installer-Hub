# -------------------------------------------------------
# Battlefield 1942 VR (BFVR) Installer
# BFVR by JayBiggsGMG - github.com/JayBiggsGMG/BFVR-Battlefield-1942-VR-Mod
#
# DAS SPIEL IST NICHT MEHR ZU KAUFEN. Der Nutzer muss eine eigene,
# legal erworbene Fassung besitzen. Deshalb wird der Spielordner
# gesucht statt vorausgesetzt, und es gibt keinen Steam-Weg.
#
# ZWEI TEILE, UND DIE REIHENFOLGE ZAEHLT:
#  1) BF42++ 2.0 RC6 - Voraussetzung, NICHT in BFVR enthalten.
#     Drei Dateien neben BF1942.exe: bf42++.dll (414.208),
#     bf42++.exe (14.848), bf42++BlackScreen.exe (16.384).
#     MANCHE Community-Pakete bringen BF42++ schon als erkannte
#     dsound.dll mit - dann NICHT zusaetzlich kopieren.
#  2) BFVR selbst, ein INNO-SETUP 6.7.0 (BFVR-Setup-v1.0.1.exe).
#     Es legt einen Unterordner BFVR\ an und ersetzt BF1942.exe NICHT.
#
# WAS DAS SETUP ANLEGT, aus einem echten Vorher/Nachher-Vergleich
# belegt - 68 Dateien, ALLE unter BFVR\, nichts wird ersetzt und
# keine Bestandsdatei aendert ihre Groesse:
#   BFVR\BFVR.exe 1.188.352, BFVRClient.dll 2.101.248,
#   BFVRD3D8To9.dll 1.176.576, BFVRPresenter.exe 626.688,
#   UserConfig.txt 12.416 (die Einstellungen des NUTZERS),
#   runtime\openxr\win64\openxr_loader.dll 2.119.680,
#   assets\ (Menuegrafiken), docs\, licenses\,
#   unins000.exe + .dat (der eigene Deinstallierer).
#
# GESTARTET WIRD UEBER BFVR\BFVR.exe, nicht ueber BF1942.exe.
# -------------------------------------------------------

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Battlefield 1942 VR Installer"

$MOD_NAME   = "BFVR"
$MOD_AUTHOR = "JayBiggsGMG"
$MOD_REPO   = "JayBiggsGMG/BFVR-Battlefield-1942-VR-Mod"
$RELEASES   = "https://github.com/$MOD_REPO/releases"

# Gepinnte Fassung - nur der Rueckfall. Die Adresse kommt zur Laufzeit
# aus dem neuesten Release. Trotzdem bei jedem Release mitziehen.
$PINNED_VER = "v1.0.1"
# Nur fuer die Kopfzeile - die tatsaechlich geladene Fassung kommt aus
# dem neuesten Release und wird beim Herunterladen genannt.
$MOD_VERSION = $PINNED_VER
$PINNED_URL = "https://github.com/$MOD_REPO/releases/download/$PINNED_VER/BFVR-Setup-$PINNED_VER.exe"

$GAME_EXE   = "BF1942.exe"
$MOD_MARK   = "BFVR\BFVR.exe"

$BFPP_PAGE  = "https://www.moddb.com/games/battlefield-1942/addons/bf42plusplus-v2-0-rc6"
$BFPP_FILES = @("bf42++.dll", "bf42++.exe", "bf42++BlackScreen.exe")
$BFPP_SIZES = @{ "bf42++.dll" = 414208; "bf42++.exe" = 14848; "bf42++BlackScreen.exe" = 16384 }

function Write-Line { Write-Host ("-" * 60) -ForegroundColor DarkGray }
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
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

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

function Get-DroppedFile {
    param([string]$Label, [string[]]$Exts)
    while ($true) {
        Write-Host ""
        Write-Host " Drag $Label onto this window and press Enter," -ForegroundColor Yellow
        Write-Host " or leave empty to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " File"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Write-Warn "File not found: $p"; continue }
        $ext = [System.IO.Path]::GetExtension($p).ToLower()
        if ($Exts -and ($Exts -notcontains $ext)) {
            Write-Warn "That is a '$ext' file. Expected: $($Exts -join ', ')."
            continue
        }
        return $p
    }
}

# Ordner statt Datei - das Spiel liegt bei jedem woanders, weil es nicht
# mehr verkauft wird. Ein abgelegter ORDNER liefert in der Konsole
# denselben Pfadtext wie eine Datei.
function Get-DroppedFolder {
    param([string]$Label)
    while ($true) {
        Write-Host ""
        Write-Host " Drag $Label onto this window and press Enter," -ForegroundColor Yellow
        Write-Host " or leave empty to cancel." -ForegroundColor DarkGray
        $raw = Read-Host " Folder"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $p = $raw.Trim().Trim('"').Trim("'").Trim()
        if (Test-Path -LiteralPath $p -PathType Leaf) { $p = Split-Path -Parent $p }
        if (-not (Test-Path -LiteralPath $p -PathType Container)) { Write-Warn "Folder not found: $p"; continue }
        return $p
    }
}

# Neuestes BFVR-Setup vom Release holen. Gesucht wird der Anhang, dessen
# Name auf .exe endet - nicht die Versionsnummer, damit eine Umbenennung
# nichts bricht.
# ---------------------------------------------------------------
#  Set-RunAsAdminFlag - der Windows-Schalter "Als Administrator
#  ausfuehren", derselbe wie im Eigenschaften-Dialog unter
#  Kompatibilitaet.
# ---------------------------------------------------------------
# WARUM DAS NOETIG IST: liegt das Spiel unter Program Files, kann der
# BF42++-Loader seine DLL NICHT in den BF1942-Prozess schieben -
# Windows verbietet das, und man bekommt "Failed to inject
# 'bf42++.dll' into 'BF1942.exe'". Mit dem Schalter startet Windows
# die Exe von sich aus erhoeht; es kommt EINE UAC-Abfrage, danach
# laeuft es.
#
# DER SCHALTER BRAUCHT SELBST KEINE ADMINRECHTE: er steht unter
# HKCU (nur fuer den angemeldeten Benutzer), nicht unter HKLM.
#
# EIN VORHANDENER WERT WIRD NICHT UEBERSCHRIEBEN: dort koennen schon
# andere Kompatibilitaetsangaben stehen (z.B. WIN7RTM oder
# DISABLEDXMAXIMIZEDWINDOWEDMODE). RUNASADMIN wird nur ergaenzt.
function Set-RunAsAdminFlag {
    param([Parameter(Mandatory=$true)][string]$ExePath)
    $key = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
    try {
        if (-not (Test-Path $key)) { New-Item -Path $key -Force -ErrorAction Stop | Out-Null }
        $cur = $null
        try { $cur = (Get-ItemProperty -Path $key -Name $ExePath -ErrorAction Stop).$ExePath } catch {}
        if ($cur -and $cur -match "RUNASADMIN") { return "already" }
        $val = if ($cur) { ($cur.TrimEnd() + " RUNASADMIN") } else { "~ RUNASADMIN" }
        Set-ItemProperty -Path $key -Name $ExePath -Value $val -ErrorAction Stop
        return "set"
    } catch {
        return "failed: $($_.Exception.Message)"
    }
}

function Get-BfvrSetupUrl {
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$MOD_REPO/releases/latest" `
                   -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
        foreach ($a in @($rel.assets)) {
            if ($a.name -match '(?i)\.exe$') {
                return @{ Url = [string]$a.browser_download_url; Name = [string]$a.name; Tag = [string]$rel.tag_name }
            }
        }
    } catch {}
    return $null
}

# Liegt BF42++ schon? Entweder als eigene bf42++.dll oder als erkannter
# dsound.dll-Proxy eines Community-Pakets.
function Test-Bf42PlusPlus {
    param([string]$GameDir)
    $ownDll = Test-Path -LiteralPath (Join-Path $GameDir "bf42++.dll")
    $proxy  = Test-Path -LiteralPath (Join-Path $GameDir "dsound.dll")
    return @{ OwnDll = $ownDll; Proxy = $proxy }
}

Clear-Host
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Battlefield 1942 VR Mod Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Stereoscopic VR, tracked-controller aiming, VR menus and comfort" -ForegroundColor White
Write-Host " options for Battlefield 1942." -ForegroundColor White
Write-Host ""
Write-Host " YOU NEED YOUR OWN COPY OF THE GAME - Battlefield 1942 is no" -ForegroundColor White
Write-Host " longer sold anywhere." -ForegroundColor White
Write-Host ""
Write-Host " MULTIPLAYER: BFVR is a client-side mod. Use it only on servers" -ForegroundColor White
Write-Host " whose rules allow client mods. It does not bypass anti-cheat." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."

# -------------------------------------------------------
Write-Step 1 4 "Locating Battlefield 1942"
# -------------------------------------------------------
$gamePath = $null
foreach ($p in @(
    "C:\Program Files (x86)\EA Games\Battlefield 1942",
    "C:\Program Files (x86)\EA GAMES\Battlefield 1942",
    "C:\Program Files\EA Games\Battlefield 1942",
    "C:\Program Files\EA GAMES\Battlefield 1942",
    "C:\Games\Battlefield 1942",
    "D:\Games\Battlefield 1942",
    "C:\Battlefield 1942"
)) { if (Test-Path -LiteralPath (Join-Path $p $GAME_EXE)) { $gamePath = $p; break } }

if (-not $gamePath) {
    Write-Info "No Battlefield 1942 folder found in the usual places."
    Write-Host "  That is normal - the game is not sold any more, so it can sit" -ForegroundColor White
    Write-Host "  anywhere you unpacked it. Point the installer at the folder" -ForegroundColor White
    Write-Host "  that contains " -NoNewline -ForegroundColor White
    Write-Host " $GAME_EXE " -ForegroundColor Black -BackgroundColor Yellow
    $gamePath = Get-DroppedFolder -Label "your Battlefield 1942 folder (the one with $GAME_EXE)"
    if ($gamePath -and -not (Test-Path -LiteralPath (Join-Path $gamePath $GAME_EXE))) {
        Write-Warn "$GAME_EXE is not in that folder."
        $gamePath = $null
    }
}
if (-not $gamePath) {
    Write-Fail "Without the game folder there is nothing to install into."
    Pause-User "Press Enter to exit..."; exit 1
}
Write-OK "Game folder: $gamePath"

# Schreibrechte einmal still pruefen. Das Ergebnis wird hier NICHT
# ausgegeben - die Ansage gehoert genau an die Stelle, wo die
# UAC-Abfrage wirklich kommt, nicht als eigener Punkt weiter oben.
$needsAdmin = $false
try {
    $probe = Join-Path $gamePath ".pcvrhub_write_probe"
    Set-Content -LiteralPath $probe -Value "ok" -ErrorAction Stop
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
} catch { $needsAdmin = $true }
if ($needsAdmin) {
    # Kurz, und nur EINE Zeile: die meisten haben das Spiel laengst dort
    # liegen und werden es nicht mehr verschieben. Der Rechte-Schalter am
    # Ende des Installers loest es fuer sie; dieser Hinweis ist fuer die,
    # die neu installieren und die Wahl noch haben.
    Write-Info "Under Program Files, Windows needs extra rights - a folder like C:\Games\Battlefield 1942 avoids that. This installer handles it either way."
}

# -------------------------------------------------------
Write-Step 2 4 "BF42++ 2.0 RC6 - the prerequisite"
# -------------------------------------------------------
$bfpp = Test-Bf42PlusPlus -GameDir $gamePath
if ($bfpp.Proxy -and -not $bfpp.OwnDll) {
    Write-OK "This package already ships BF42++ as a dsound.dll proxy."
    Write-Host "  Do NOT add a second copy - BFVR uses the bundled one." -ForegroundColor Gray
} elseif ($bfpp.OwnDll) {
    Write-OK "bf42++.dll is already in the game folder."
    if ($bfpp.Proxy) {
        Write-Warn "A dsound.dll proxy is ALSO present."
        Write-Host "  BFVR 1.0.1 handles that - it uses the bundled proxy and" -ForegroundColor White
        Write-Host "  ignores the extra bf42++.dll for that launch." -ForegroundColor White
    }
} else {
    Write-Warn "BF42++ is not in the game folder. BFVR cannot run without it."
    Write-Host ""
    Write-Host "  1) The ModDB page opens next. Click the red " -NoNewline -ForegroundColor White
    Write-Host " DOWNLOAD NOW " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " button" -ForegroundColor White
    Write-Host "     (about 209 KB) and wait for the file to finish." -ForegroundColor White
    Write-Host "  2) Come back here - this window picks it up from your" -ForegroundColor White
    Write-Host "     Downloads folder by itself, or you drag it in." -ForegroundColor White
    Pause-User "Press Enter to open the BF42++ page..."
    try { Start-Process $BFPP_PAGE } catch { Write-Warn "Open manually: $BFPP_PAGE" }

    $arch = Find-PredownloadedFile -Patterns @("BF42PLUSPLUS*RC6*.7z", "BF42PLUSPLUS*RC6*.zip", "*BF42PLUSPLUS*") -Label "the BF42++ archive"
    if (-not $arch) { $arch = Get-DroppedFile -Label "the BF42++ archive (BF42PLUSPLUS-v2.0-RC6.7z)" -Exts @(".7z", ".zip") }
    if (-not $arch) {
        Write-Fail "No BF42++ archive provided - BFVR will not start without it."
        if (-not (Read-YesNo "Continue anyway and install BFVR only?")) { Pause-User "Press Enter to exit..."; exit 1 }
    } else {
        $tmp = Join-Path $env:TEMP ("bfpp_" + [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null

        # DAS ARCHIV IST EIN .7z, UND POWERSHELL KANN DAS NICHT VON SICH AUS.
        # Expand-ArchiveOrFallback versucht 7-Zip und faellt sonst auf
        # Expand-Archive zurueck - das kann NUR .zip. Ohne installiertes
        # 7-Zip wurde deshalb gar nichts entpackt, der innere Ordner blieb
        # leer und alle drei Dateien fehlten. Get-SevenZip holt 7-Zip bei
        # Bedarf nach (fragt vorher), damit der .7z-Weg ueberhaupt geht.
        if ($arch -match '(?i)\.7z$') {
            $sz = Get-SevenZip
            if (-not $sz) {
                Write-Warn "Without 7-Zip the .7z archive cannot be opened here."
                Write-Host "  Unpack it yourself and drop the inner ZIP or the three" -ForegroundColor White
                Write-Host "  bf42++ files next to $GAME_EXE, then run this again." -ForegroundColor White
            }
        }
        $exRes = Expand-ArchiveOrFallback -ArchivePath $arch -DestinationFolder $tmp -Label "BF42++"

        # ZWEITE EBENE: im .7z liegt BF42PLUSPLUS-v2.0-RC6-Install.zip, und
        # ERST DARIN stecken die drei Dateien. Wird das uebersehen, meldet
        # der Installer alle drei als fehlend - genau das ist passiert.
        $searchRoot = $tmp
        foreach ($round in 1..2) {
            $hit = Get-ChildItem -LiteralPath $searchRoot -Recurse -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -ieq "bf42++.dll" } | Select-Object -First 1
            if ($hit) { break }
            $inner = Get-ChildItem -LiteralPath $searchRoot -Recurse -File -ErrorAction SilentlyContinue |
                     Where-Object { $_.Extension -imatch '^\.(zip|7z)$' } | Select-Object -First 1
            if (-not $inner) { break }
            $nested = Join-Path $tmp ("inner" + $round)
            New-Item -ItemType Directory -Path $nested -Force | Out-Null
            Write-Info "Opening $($inner.Name) ..."
            [void](Expand-ArchiveOrFallback -ArchivePath $inner.FullName -DestinationFolder $nested -Label "BF42++ install files")
            $searchRoot = $nested
        }
        # !!! UEBER DEN GANZEN ENTPACKBAUM SUCHEN, NICHT NUR UNTER $searchRoot,
        # UND OHNE -Filter. Zwei Gruende, beide real aufgetreten:
        # (a) -Filter geht an die Windows-Dateisuche und behandelt den
        #     Namen als DOS-Muster - bei "bf42++.dll" hat das nicht
        #     zuverlaessig getroffen. Ein Namensvergleich in PowerShell
        #     ist eindeutig.
        # (b) wo die Dateien nach zwei Entpackstufen genau landen, haengt
        #     vom Entpacker ab. Der ganze Temp-Baum wird ohnehin gleich
        #     geloescht - also einmal komplett durchsuchen und fertig.
        if ($needsAdmin) {
            Pause-User "Press Enter to copy BF42++ into the game folder - UAC required..."
        }
        $allFiles = @(Get-ChildItem -LiteralPath $tmp -Recurse -File -Force -ErrorAction SilentlyContinue)
        $sources = @()
        $copyFail = $false
        foreach ($f in $BFPP_FILES) {
            $hit = $allFiles | Where-Object { $_.Name -ieq $f } | Select-Object -First 1
            if (-not $hit) { continue }
            $sources += $hit.FullName
            try { Copy-Item -LiteralPath $hit.FullName -Destination (Join-Path $gamePath $f) -Force -ErrorAction Stop }
            catch { $copyFail = $true }
        }

        # PROGRAM FILES BRAUCHT ADMINRECHTE. Genau dort liegt das Spiel bei
        # vielen (C:\Program Files (x86)\EA Games\Battlefield 1942), und der
        # Hub laeuft ohne erhoehte Rechte - das Kopieren scheitert dann mit
        # "Zugriff verweigert". Der Hub macht das an anderer Stelle laengst
        # so: den Kopierschritt EINMAL erhoeht wiederholen. Gleiche Form wie
        # im GTA-IV-Installer.
        if ($copyFail -and $sources.Count -gt 0) {
            Write-Warn "Copying into that folder needs administrator rights. Asking for them ..."
            Write-Host "  A UAC prompt will appear now." -ForegroundColor Gray
            $srcList = ($sources | ForEach-Object { "'" + $_ + "'" }) -join ","
            $ps = "foreach (`$s in @($srcList)) { Copy-Item -LiteralPath `$s -Destination '$gamePath' -Force }"
            try {
                Start-Process powershell -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-Command",$ps) -Verb RunAs -Wait -ErrorAction Stop
            } catch {
                Write-Warn "The elevated copy was declined or failed."
            }
        }
        # Falls etwas fehlt: BEVOR der Temp-Baum weg ist, aufschreiben was
        # tatsaechlich darin lag. Ohne das raet man beim naechsten Bericht
        # wieder - genau das ist hier schon zweimal passiert.
        $foundNames = @($allFiles | ForEach-Object { $_.Name })
        try { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}

        # Am ZIEL pruefen, nicht am Kopierbefehl - Groessen gegen die
        # belegten Werte halten.
        $bad = @()
        foreach ($f in $BFPP_FILES) {
            $dst = Join-Path $gamePath $f
            if (-not (Test-Path -LiteralPath $dst)) { $bad += "$f (missing)"; continue }
            $len = (Get-Item -LiteralPath $dst).Length
            if ($len -ne $BFPP_SIZES[$f]) { $bad += "$f ($len bytes, expected $($BFPP_SIZES[$f]))" }
        }
        if ($bad.Count -eq 0) {
            Write-OK "BF42++ in place and verified (3 files)."
        } else {
            Write-Warn "BF42++ is not complete:"
            foreach ($b in $bad) { Write-Host "   $b" -ForegroundColor Yellow }
            if ($foundNames.Count -gt 0) {
                Write-Host "  The archive did unpack - these files were in it:" -ForegroundColor Gray
                foreach ($n in ($foundNames | Select-Object -Unique | Select-Object -First 12)) {
                    Write-Host "     $n" -ForegroundColor DarkGray
                }
                if ($foundNames.Count -gt 12) { Write-Host "     ... and $($foundNames.Count - 12) more" -ForegroundColor DarkGray }
            } else {
                Write-Host "  Nothing was unpacked at all - the archive could not be opened." -ForegroundColor Gray
            }
            Write-Host "  Unpack the archive by hand and put bf42++.dll, bf42++.exe" -ForegroundColor White
            Write-Host "  and bf42++BlackScreen.exe next to $GAME_EXE." -ForegroundColor White
            if ($gamePath -like "*Program Files*") {
                Write-Host "  That folder is under Program Files, so Windows will ask for" -ForegroundColor White
                Write-Host "  administrator rights when you paste the files - say yes." -ForegroundColor White
            }
            Pause-User "Press Enter once you have done that..."
        }
    }
}

# -------------------------------------------------------
Write-Step 3 4 "Downloading BFVR"
# -------------------------------------------------------
$rel = Get-BfvrSetupUrl
$setupUrl  = if ($rel) { $rel.Url }  else { $PINNED_URL }
$setupName = if ($rel) { $rel.Name } else { "BFVR-Setup-$PINNED_VER.exe" }
if ($rel) { Write-Info "Newest release: $($rel.Tag)" }
else      { Write-Info "GitHub not reachable - using the pinned $PINNED_VER build." }

$setupPath = Join-Path $env:TEMP $setupName
$ok = Invoke-DownloadOrFallback -Url $setupUrl -Destination $setupPath -Label "BFVR setup" -ManualUrl $RELEASES
if (-not $ok -or -not (Test-Path -LiteralPath $setupPath)) {
    Write-Fail "The BFVR setup was not downloaded."
    Pause-User "Press Enter to exit..."; exit 1
}
Write-OK "Downloaded: $setupName"

# -------------------------------------------------------
Write-Step 4 4 "Running the BFVR setup"
# -------------------------------------------------------
$clip = $false
try { Set-Clipboard -Value $gamePath; $clip = $true } catch {}
Write-Host ""
Write-Host "  The setup looks for your Battlefield 1942 folder." -ForegroundColor White
Write-Host "  Usually it is found and set already." -ForegroundColor White
if ($clip) {
    Write-Host "  If not, it is also on your clipboard - paste with " -NoNewline -ForegroundColor White
    Write-Host " Ctrl+V " -ForegroundColor Black -BackgroundColor Yellow
}
Write-Host "     $gamePath " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  It creates a BFVR\ subfolder there. Your $GAME_EXE is NOT" -ForegroundColor White
Write-Host "  replaced and no game file is changed." -ForegroundColor White
Write-Host ""
Write-Host "  Windows may say 'Unknown publisher'. The installer is unsigned on" -ForegroundColor DarkGray
Write-Host "  purpose, and BFVR has to load a DLL into an old game process -" -ForegroundColor DarkGray
Write-Host "  antivirus tools are wary of that technique. Do not switch your" -ForegroundColor DarkGray
Write-Host "  antivirus off; allow this one file if you are asked." -ForegroundColor DarkGray
Pause-User "Press Enter to launch the setup - UAC required..."

try { Start-Process -FilePath $setupPath -Wait -ErrorAction Stop }
catch {
    Write-Fail "Could not start the setup: $($_.Exception.Message)"
    Write-Host "  Run it by hand: $setupPath" -ForegroundColor Yellow
    Pause-User "Press Enter once you have finished the setup..."
}

# ---- Am ERGEBNIS pruefen ----
$modFull = Join-Path $gamePath $MOD_MARK
Write-Host ""
if (Test-Path -LiteralPath $modFull) {
    Write-OK "BFVR verified: $MOD_MARK"
    try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
    try { Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value $modFull -Encoding UTF8 -Force } catch {}
    if ($rel) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $rel.Tag -Encoding UTF8 -Force } catch {} }
} else {
    Write-Warn "BFVR\BFVR.exe is not there - the mod does not look installed."
    Write-Host "  Checked: $gamePath" -ForegroundColor Gray
    Write-Host "  If you cancelled the setup or pointed it somewhere else, run" -ForegroundColor White
    Write-Host "  this installer again." -ForegroundColor White
}

# ---- Der Rechte-Schalter, wenn das Spiel unter Program Files liegt ----
# Ohne ihn scheitert der BF42++-Loader mit "Failed to inject
# 'bf42++.dll' into 'BF1942.exe'" - Windows laesst einen Prozess ohne
# erhoehte Rechte nicht in einen erhoehten hineinschreiben. Wird NUR
# gefragt, wenn die Schreibprobe vorhin durchgefallen ist.
if ($needsAdmin) {
    $exeList = @()
    if (Test-Path -LiteralPath $modFull) { $exeList += $modFull }
    $bfppExe = Join-Path $gamePath "bf42++.exe"
    if (Test-Path -LiteralPath $bfppExe) { $exeList += $bfppExe }

    if ($exeList.Count -gt 0) {
        Write-Host ""
        Write-Line
        Write-Host " ONE THING LEFT - or the mod will not load" -ForegroundColor Cyan
        Write-Line
        Write-Host "  Your game sits under Program Files. Windows will not let" -ForegroundColor White
        Write-Host "  BF42++ load itself into the game from there, and you would" -ForegroundColor White
        Write-Host "  get this every time:" -ForegroundColor White
        Write-Host "     Failed to inject 'bf42++.dll' into 'BF1942.exe'" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  The fix is Windows' own 'Run as administrator' setting on" -ForegroundColor White
        Write-Host "  these files:" -ForegroundColor White
        foreach ($e in $exeList) { Write-Host "     $(Split-Path $e -Leaf)" -ForegroundColor Gray }
        Write-Host ""
        Write-Host "  It only applies to your own Windows account and changes" -ForegroundColor Gray
        Write-Host "  nothing about the game itself. You can undo it any time in" -ForegroundColor Gray
        Write-Host "  the file's Properties - Compatibility tab." -ForegroundColor Gray

        if (Read-YesNo "Set that now?") {
            $done = @(); $failed = @()
            foreach ($e in $exeList) {
                $r = Set-RunAsAdminFlag -ExePath $e
                if ($r -eq "set" -or $r -eq "already") { $done += (Split-Path $e -Leaf) } else { $failed += "$(Split-Path $e -Leaf) ($r)" }
            }
            if ($done.Count -gt 0) { Write-OK ("Set for: " + ($done -join ", ")) }
            if ($failed.Count -gt 0) {
                Write-Warn "Could not set it for:"
                foreach ($f in $failed) { Write-Host "   $f" -ForegroundColor Yellow }
                Write-Host "  Do it by hand: right-click the file - Properties -" -ForegroundColor White
                Write-Host "  Compatibility - tick 'Run this program as an administrator'." -ForegroundColor White
            } else {
                Write-Host "  From now on Windows asks once with a UAC prompt when you" -ForegroundColor White
                Write-Host "  start the game. Say yes, and it runs." -ForegroundColor White
            }
        } else {
            Write-Info "Left alone. If BF42++ cannot inject, set it by hand:"
            Write-Host "  right-click the file - Properties - Compatibility -" -ForegroundColor White
            Write-Host "  tick 'Run this program as an administrator'." -ForegroundColor White
        }
    }
}

Write-Host ""
Write-Line
Write-Host " HOW TO START - the order matters" -ForegroundColor Cyan
Write-Line
Write-Host "  1. Connect the headset and start its OpenXR software FIRST" -ForegroundColor White
Write-Host "     (Meta Quest Link, SteamVR, or Virtual Desktop with VDXR)." -ForegroundColor White
Write-Host "  2. Start the game via " -NoNewline -ForegroundColor White
Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " in the Hub, or" -ForegroundColor White
Write-Host "     BFVR\BFVR.exe in the game folder - NOT BF1942.exe." -ForegroundColor White
Write-Host "  3. Pick a map in Battlefield 1942's normal menus." -ForegroundColor White
Write-Host "  4. Quit through the game's own menus when you are done." -ForegroundColor White
Write-Host ""
Write-Host " Mouse and keyboard keep working, menus included." -ForegroundColor Gray
Write-Host " Hold right A for the Quick Menu; the VR Settings panel with" -ForegroundColor Gray
Write-Host " seated/standing, turning, comfort vignette and the graphics" -ForegroundColor Gray
Write-Host " options sits in its strip. Hold right B for 2.5 s to recenter." -ForegroundColor Gray
Write-Host ""
Write-Host " Settings live in BFVR\UserConfig.txt next to BFVR.exe. Delete it" -ForegroundColor Gray
Write-Host " with BFVR closed and a clean default file is written on the next" -ForegroundColor Gray
Write-Host " start." -ForegroundColor Gray
Write-Host ""
Write-Host " Someone already took the plane. They always do." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
