# ============================================================
#  Call of Duty 4 VR - Installer (KisakCOD VR by jplakon)
# ============================================================
#  Single-player OpenXR VR conversion of the ORIGINAL 2007 COD4:
#  stereo rendering, 6DoF head tracking, motion-controller aiming,
#  physical scopes, VR-placed HUD. Built on KisakCOD (SwagSoftware).
#
#  THE PACKAGE IS AN OVERLAY, not a plugin: every file goes straight
#  into the COD4 folder next to iw3sp.exe. It ships its own engine
#  build (KisakCOD-sp.exe) plus the DLLs the engine needs, and it
#  contains NO game data - maps, fastfiles and iw3sp.exe must come
#  from the user's own legitimate install.
#
#  COLLISIONS ARE EXPECTED: mss32.dll, binkw32.dll, steam_api.dll and
#  the whole miles\ folder already exist in a normal COD4 install. Any
#  file we overwrite is copied to <name>.hubbak first, once, so the
#  flat game can be put back by hand.
#
#  LAUNCHING: the game is started by Launch-KisakCOD-VR.bat, which
#  AS OF v0.10.0-beta.12 (2026-08-13): the package now ships
#  KisakCOD-VR-Configurator.exe - a graphical front end with presets
#  (Tested Quest 3, Performance, Comfort Snap, Smooth Turn, Seated,
#  Minimal HUD) and Save & Launch. Profiles live under LocalAppData and
#  therefore survive package updates. The batch launcher stays and uses
#  the last saved profile. The ZIP is complete; no earlier beta is
#  needed.
#  loads VR-Settings.bat and then runs KisakCOD-sp.exe with a long
#  list of console variables. Starting KisakCOD-sp.exe directly skips
#  all of that, and steam://rungameid does not start the VR build - so the
#  catalog points LaunchExe at the .bat and the installer also puts a
#  desktop shortcut to it.
#
#  RELEASES: the repo publishes PRERELEASES (v0.9.0-beta.1 is one), so
#  the newest release is resolved through /releases and NOT through
#  /releases/latest, which skips prereleases entirely.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Call of Duty 4 VR Installer"

$MOD_NAME   = "KisakCOD VR"
$MOD_AUTHOR = "jplakon"

$GAME_APPID = "7940"
$GAME_EXE   = "iw3sp.exe"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

$REPO          = "jplakon/CallOfDuty4_VR"
$RELEASES_API  = "https://api.github.com/repos/$REPO/releases"
$RELEASES_URL  = "https://github.com/$REPO/releases"
$PROJECT_URL   = "https://github.com/$REPO"

$MOD_EXE     = "KisakCOD-sp.exe"
$LAUNCH_BAT  = "Launch-KisakCOD-VR.bat"
$SETTINGS_BAT= "VR-Settings.bat"
# Since v0.10.0-beta.7 a graphical configurator ships in the package. It
# is the intended way to change settings; VR-Settings.bat remains beside
# it and the batch launcher uses the last saved profile.
$CONFIG_EXE  = "KisakCOD-VR-Configurator.exe"
# Since v0.10.0-beta.12 an input mapper ships ADDITIONALLY (822,784 B).
# The configurator sets VR and graphics, the mapper sets the key
# bindings - two separate tools.
$INPUT_EXE   = "KisakCOD-VR-Input-Mapper.exe"
# A copy of the EXISTING VR-Settings.bat before it is overwritten.
$SETTINGS_PREV = "VR-Settings.bat.hubprev"
$ICON_FILE   = "CallOfDuty4_VR.ico"

# The build links against the DEBUG D3DX9 (d3dx9d_43.dll, note the "d"),
# not the shipping d3dx9_43.dll. Microsoft does NOT put debug D3DX in the
# DirectX End-User Runtime and explicitly does not allow shipping it, so
# no game, no DirectX installer and no Windows update ever places it -
# the game just dies with "d3dx9d_43.dll not found".
# It IS available from Microsoft directly: the Microsoft.DXSDK.D3DX NuGet
# package carries the debug DLLs, and a .nupkg is a plain ZIP. That is an
# official Microsoft source and needs no login, so the Hub can fetch it.
# Renaming d3dx9_43.dll does NOT work - different exports.
$D3DX_DEBUG_DLL = "d3dx9d_43.dll"
$D3DX_NUPKG_URL = "https://www.nuget.org/api/v2/package/Microsoft.DXSDK.D3DX/9.29.952.8"
$D3DX_IN_PKG    = "build/native/debug/bin/x86/D3DX9d_43.dll"
$D3DX_MANUAL_URL= "https://www.dllme.com/dll/files/d3dx9d_43"

function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " Call of Duty 4 VR - Installer" -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param([int]$n, [int]$t, [string]$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($text) Write-Host " [OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host " [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host " [!]  $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [X]  $text" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# A COD4 folder is one that holds iw3sp.exe - the single-player exe the
# mod's launcher checks for too.
function Test-CodRoot {
    param([string]$Root)
    if (-not $Root) { return $false }
    try {
        if (-not (Test-Path -LiteralPath $Root)) { return $false }
        return (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $GAME_EXE)))
    } catch { return $false }
}

# Newest release INCLUDING prereleases. /releases/latest would skip
# v0.9.0-beta.1 and every future beta, which is what this project ships.
function Get-NewestRelease {
    try {
        $rels = Invoke-RestMethod -Uri $RELEASES_API -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 25 -ErrorAction Stop
        $rel = $rels | Select-Object -First 1
        if (-not $rel) { return $null }
        # THE PORTABLE ZIP IS AND STAYS THE NORMAL ROUTE. The author now
        # also publishes a guided Windows Setup and calls it the
        # recommended download, but both are built from the SAME
        # deterministic payload - and the zip needs no installer, no
        # elevation and raises no unsigned-publisher warning.
        # The .sha256 sidecars end in .sha256, so they never match here.
        $asset = $rel.assets | Where-Object { $_.name -like "*.zip" -and $_.name -notlike "*source*" } | Select-Object -First 1

        # ORDER MATTERS: a real package, then the Setup, and only then
        # any leftover zip. The "any zip" line used to sit directly under
        # the first one and happily picked source-code.zip - a source
        # archive is NOT an install, so the author's own installer is the
        # better answer when the package is missing.

        # FALLBACK, and ONLY if that release carries no zip at all
        # (2026-08-20): should the author ever drop the portable package,
        # the Setup.exe keeps this entry working instead of dead-ending.
        # Kind is carried out so the caller can ask before running an
        # installer that will raise a UAC prompt.
        if ($asset) {
            return [pscustomobject]@{ Tag = $rel.tag_name; Url = $asset.browser_download_url; Name = $asset.name; Pre = [bool]$rel.prerelease; Kind = "zip" }
        }
        $setup = $rel.assets | Where-Object { $_.name -like "*Setup*.exe" -and $_.name -notlike "*.sha256" } | Select-Object -First 1
        if (-not $setup) { $setup = $rel.assets | Where-Object { $_.name -like "*.exe" -and $_.name -notlike "*.sha256" } | Select-Object -First 1 }
        if ($setup) {
            return [pscustomobject]@{ Tag = $rel.tag_name; Url = $setup.browser_download_url; Name = $setup.name; Pre = [bool]$rel.prerelease; Kind = "setup" }
        }
        # Last resort: any zip at all, source archives included. Better
        # than nothing, and the user still sees the name before it runs.
        $any = $rel.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
        if ($any) {
            return [pscustomobject]@{ Tag = $rel.tag_name; Url = $any.browser_download_url; Name = $any.name; Pre = [bool]$rel.prerelease; Kind = "zip" }
        }
        return $null
    } catch { return $null }
}

Write-Header
Write-Host " KisakCOD VR turns the ORIGINAL 2007 Call of Duty 4 into a" -ForegroundColor White
Write-Host " single-player VR game: stereo rendering, 6DoF head tracking," -ForegroundColor White
Write-Host " motion-controller aiming and real, physical sniper scopes." -ForegroundColor White
Write-Host ""
Write-Host " You need the 2007 original - Modern Warfare Remastered will" -ForegroundColor Yellow
Write-Host " not work. Start the flat game once before installing." -ForegroundColor Yellow
Write-Host ""
Write-Host " The mod ships no game data. Maps and fastfiles stay yours." -ForegroundColor Gray
Show-AntivirusNotice
Pause-User "Press Enter to start..." | Out-Null

# -------------------------------------------------------
#  STEP 1: locate Call of Duty 4
# -------------------------------------------------------
Write-Step 1 5 "Locating Call of Duty 4 (2007)"

$gamePath = $null
if (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue) {
    $gamePath = Find-SteamGameFolder -AppId $GAME_APPID `
        -SteamFolderNames @("Call of Duty 4", "Call of Duty 4 - Modern Warfare", "CallOfDuty4") `
        -ProbeExe $GAME_EXE
    if ($gamePath -and -not (Test-CodRoot -Root $gamePath)) { $gamePath = $null }
}
if (-not $gamePath) {
    $candidates = @()
    foreach ($d in @("C:", "D:", "E:")) {
        foreach ($n in @("Call of Duty 4", "Call of Duty 4 - Modern Warfare", "CallOfDuty4")) {
            $candidates += "$d\Program Files (x86)\Activision\$n"
            $candidates += "$d\Program Files\Activision\$n"
            $candidates += "$d\Games\$n"
            $candidates += "$d\$n"
        }
    }
    foreach ($c in $candidates) { if (Test-CodRoot -Root $c) { $gamePath = $c; break } }
}
if (-not $gamePath) {
    $rec = $null
    try { $rec = Get-Content -LiteralPath (Join-Path $SCRIPT_DIR ".installed_path") -ErrorAction Stop | Select-Object -First 1 } catch {}
    if ($rec) { $rec = $rec.Trim() }
    if (Test-CodRoot -Root $rec) { $gamePath = $rec }
}
while (-not $gamePath) {
    Write-Warn "Could not find Call of Duty 4 automatically."
    Write-Host " Drag & drop the COD4 GAME FOLDER onto this window - the one" -ForegroundColor White
    Write-Host " that contains $GAME_EXE - then press Enter." -ForegroundColor White
    Write-Host " In Steam: right-click the game > Manage > Browse local files." -ForegroundColor Gray
    Write-Host " Or press Enter on an empty line to exit." -ForegroundColor Gray
    $raw = (Read-Host " Game folder").Trim().Trim('"').Trim("'")
    if (-not $raw) { Write-Fail "No game folder - cannot continue."; Pause-User "Press Enter to exit." | Out-Null; exit 1 }
    if (Test-CodRoot -Root $raw) { $gamePath = $raw }
    else { Write-Fail "$GAME_EXE is not in that folder." }
}
Write-OK "Found: $gamePath"
$null = Show-UpdateNoticeIfInstalled -TargetDir $gamePath -RelModFile $MOD_EXE -Label "KisakCOD VR"

# -------------------------------------------------------
#  STEP 2: fetch the newest release (prereleases included)
# -------------------------------------------------------
Write-Step 2 5 "Downloading $MOD_NAME"

$work = Join-Path $env:TEMP ("kisakcodvr_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $work -Force | Out-Null
$zipPath = Join-Path $work "KisakCOD-VR.zip"
$relTag  = $null

$rel = Get-NewestRelease
$useSetup = $false
if ($rel) {
    $relTag = $rel.Tag
    if ($rel.Pre) { Write-Info "Newest release is a beta: $($rel.Tag)" } else { Write-Info "Newest release: $($rel.Tag)" }

    if ([string]$rel.Kind -eq "setup") {
        # No portable zip in this release - ask before going the
        # installer route, because it is a different kind of thing: it
        # writes by itself and Windows will ask for administrator
        # rights.
        Write-Host ""
        Write-Warn "This release carries NO portable zip - only the author's Setup."
        Write-Host "  Found: $($rel.Name)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  The Hub normally unpacks the portable package itself. His" -ForegroundColor White
        Write-Host "  Setup instead installs on its own, and:" -ForegroundColor White
        Write-Host "   - Windows WILL ask for administrator rights (UAC)." -ForegroundColor Yellow
        Write-Host "   - It is not code-signed, so Windows may say Unknown Publisher." -ForegroundColor Yellow
        Write-Host "   - It finds Steam itself and offers a Browse fallback." -ForegroundColor Gray
        Write-Host "   - It backs up every file it replaces and restores them on" -ForegroundColor Gray
        Write-Host "     uninstall; your saves and settings are left alone." -ForegroundColor Gray
        Write-Host ""
        $ans = ""
        for ($i = 1; $i -le 20; $i++) {
            $ans = ("" + (Read-Host "  Use the author's Setup? [y/n]")).Trim().ToLower()
            if ($ans -in @("y","n","yes","no")) { break }
            Write-Host "  Please answer y or n." -ForegroundColor Yellow
        }
        if ($ans -in @("y","yes")) {
            $setupPath = Join-Path $work $rel.Name
            Invoke-SafeDownload -Urls @($rel.Url) -Destination $setupPath -Label "$MOD_NAME $($rel.Tag) Setup" -ManualUrl $RELEASES_URL | Out-Null
            if (Test-Path -LiteralPath $setupPath) {
                Write-Info "Starting the author's Setup - answer its prompts, then come back here."
                try {
                    $sp = Start-Process -FilePath $setupPath -PassThru -Wait -ErrorAction Stop
                    Write-Info "Setup closed (exit code $($sp.ExitCode))."
                    $useSetup = $true
                } catch {
                    Write-Fail "Could not start it: $($_.Exception.Message)"
                }
            }
        } else {
            Write-Info "Skipped. You can still drop a zip in by hand below."
        }
    } else {
        Invoke-SafeDownload -Urls @($rel.Url) -Destination $zipPath -Label "$MOD_NAME $($rel.Tag)" -ManualUrl $RELEASES_URL | Out-Null
    }
}
if (-not $useSetup -and -not (Test-Path -LiteralPath $zipPath)) {
    $found = Find-PredownloadedFile -Patterns @("*KisakCOD*VR*.zip", "*KisakCOD*.zip", "*CallOfDuty4*VR*.zip") -Label "the KisakCOD VR package"
    if ($found) { Copy-Item -LiteralPath $found -Destination $zipPath -Force }
}
# When the author's Setup ran, there is no zip to unpack - it has already
# written into the game folder itself. Insisting on one here would send
# the user hunting for a file that does not exist.
while (-not $useSetup -and -not (Test-Path -LiteralPath $zipPath)) {
    Write-Warn "Automatic download did not work."
    Pause-User "Press Enter to open the releases page..." | Out-Null
    try { Start-Process $RELEASES_URL } catch { Write-Warn "Open manually: $RELEASES_URL" }
    $raw = (Read-Host " Drag the downloaded ZIP here (empty to exit)").Trim().Trim('"').Trim("'")
    if (-not $raw) { Write-Fail "Nothing to install."; Pause-User "Press Enter to exit." | Out-Null; exit 1 }
    if (Test-Path -LiteralPath $raw) { Copy-Item -LiteralPath $raw -Destination $zipPath -Force }
    else { Write-Fail "File not found: $raw" }
}

# -------------------------------------------------------
#  STEP 3: overlay the package onto the game folder
# -------------------------------------------------------
Write-Step 3 5 "Installing into the game folder"

$extract = Join-Path $work "extracted"
New-Item -ItemType Directory -Path $extract -Force | Out-Null
if ($useSetup) {
    # The Setup already put the files in place. Verify the result on disk
    # rather than the exit code - the user may have cancelled it, or
    # pointed it at a different copy of the game.
    Write-Info "The author's Setup did the copying - checking the game folder."
    if (Test-Path -LiteralPath (Join-Path $gameDir $MOD_EXE)) {
        Write-OK "$MOD_EXE is in place: $gameDir"
    } else {
        Write-Fail "$MOD_EXE is not in the game folder - the Setup may have been cancelled,"
        Write-Host "  or it installed into a different copy of the game." -ForegroundColor White
        Pause-User "Press Enter to exit."
        exit 1
    }
}
try {
    if (-not $useSetup) { Expand-Archive -LiteralPath $zipPath -DestinationPath $extract -Force -ErrorAction Stop }
} catch {
    Write-Fail "Could not extract the archive: $($_.Exception.Message)"
    $fb = Invoke-InstallerFallback -Action "extracting the mod archive" `
        -Instructions "Open '$zipPath' and extract everything into '$extract'. Then choose Retry." `
        -SkipMessage "Skipped - nothing was installed." `
        -SourceFolder (Split-Path -Parent $zipPath) -DestFolder $extract -AllowSkip $true
    if ([string]$fb -eq "quit") { Pause-User "Press Enter to exit." | Out-Null; exit 1 }
}

# The payload root is wherever KisakCOD-sp.exe sits - immune to a
# wrapper folder or a renamed one.
$srcRoot = $extract
$hit = $null
try { $hit = Get-ChildItem -LiteralPath $extract -Filter $MOD_EXE -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1 } catch {}
if ($hit) { $srcRoot = $hit.DirectoryName }
else {
    Write-Fail "$MOD_EXE was not in the archive - wrong file, or the package layout changed."
    Pause-User "Press Enter to exit." | Out-Null; exit 1
}
Write-Info "Payload: $srcRoot"

# Copy everything, backing up each file we would overwrite exactly once.
# The COD4 install already owns mss32.dll, binkw32.dll, steam_api.dll and
# miles\ - those are the ones that matter.
# A DEDICATED BACKUP OF VR-Settings.bat, ON EVERY RUN.
# The loop below only backs a file up when NO .hubbak exists yet - so on
# a second run (moving from beta.6 to beta.7) a hand-edited
# VR-Settings.bat would have been overwritten without a backup. That is
# exactly what the release notes warn about ("keep a copy so it can be
# imported"). Hence a copy here that EVERY run writes fresh.
$settingsDest = [System.IO.Path]::Combine($gamePath, $SETTINGS_BAT)
$settingsSaved = $false
if (Test-Path -LiteralPath $settingsDest) {
    try {
        Copy-Item -LiteralPath $settingsDest -Destination ([System.IO.Path]::Combine($gamePath, $SETTINGS_PREV)) -Force -ErrorAction Stop
        $settingsSaved = $true
    } catch {}
}

$copied = 0; $backed = 0; $failed = @()
Get-ChildItem -LiteralPath $srcRoot -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($srcRoot.Length).TrimStart('\')
    $dest = [System.IO.Path]::Combine($gamePath, $rel)
    $destDir = [System.IO.Path]::GetDirectoryName($dest)
    try {
        if ($destDir -and -not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        if ((Test-Path -LiteralPath $dest) -and -not (Test-Path -LiteralPath "$dest.hubbak")) {
            Copy-Item -LiteralPath $dest -Destination "$dest.hubbak" -Force -ErrorAction SilentlyContinue
            $backed++
        }
        Copy-Item -LiteralPath $_.FullName -Destination $dest -Force -ErrorAction Stop
        $copied++
    } catch { $failed += $rel }
}

$need = @($MOD_EXE, $LAUNCH_BAT, $SETTINGS_BAT)
$missing = @()
foreach ($n in $need) { if (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($gamePath, $n)))) { $missing += $n } }
if ($missing.Count -gt 0) {
    Write-Fail "Missing after copy: $($missing -join ', ')"
    Write-Warn "Extract the ZIP into $gamePath by hand, next to $GAME_EXE."
    if ($failed.Count -gt 0) { Write-Host "  Failed files: $($failed -join ', ')" -ForegroundColor Gray }
    try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}
    Pause-User "Press Enter to exit." | Out-Null
    exit 1
}
Write-OK "$copied files installed, $backed original file(s) kept as .hubbak"

# A scanner often sweeps a moment after the write; the work folder still
# holds the archive here, so recovery can unpack it again inside the
# game folder.
$avFilesOk = Confirm-PlacedFilesSurvive `
    -Paths @([System.IO.Path]::Combine($gamePath, $MOD_EXE)) `
    -GameDir $gamePath `
    -ArchivePath $zipPath
if (-not $avFilesOk) {
    try { Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Write-Fail "The VR mod could not be restored after the antivirus check."
    Pause-User "Press Enter to exit, then run the installer again."
    exit 1
}
if ($settingsSaved) { Write-Info "Your previous $SETTINGS_BAT was saved as $SETTINGS_PREV - the configurator can import it." }
$configFull = [System.IO.Path]::Combine($gamePath, $CONFIG_EXE)
if (-not (Test-Path -LiteralPath $configFull)) {
    Write-Info "No $CONFIG_EXE in this package - tune $SETTINGS_BAT in a text editor instead."
}
if ($failed.Count -gt 0) { Write-Warn "Could not write: $($failed -join ', ')" }

# -------------------------------------------------------
#  STEP 4: launcher shortcut
# -------------------------------------------------------
Write-Step 4 5 "DirectX debug library ($D3DX_DEBUG_DLL)"

# Already there? Next to the exe wins; Windows also finds it in System32
# (64-bit Windows keeps 32-bit DLLs in SysWOW64, and GetFolderPath
# 'System' returns the right one for this 32-bit-looking lookup, so both
# are probed explicitly).
$d3dxDest = [System.IO.Path]::Combine($gamePath, $D3DX_DEBUG_DLL)
$d3dxHave = (Test-Path -LiteralPath $d3dxDest)
if (-not $d3dxHave) {
    foreach ($sysDir in @([System.IO.Path]::Combine($env:WINDIR, "SysWOW64"), [System.IO.Path]::Combine($env:WINDIR, "System32"))) {
        if (Test-Path -LiteralPath ([System.IO.Path]::Combine($sysDir, $D3DX_DEBUG_DLL))) { $d3dxHave = $true; break }
    }
}

if ($d3dxHave) {
    Write-OK "$D3DX_DEBUG_DLL is already on this system."
} else {
    Write-Host " The game needs $D3DX_DEBUG_DLL - the DEBUG build of Microsoft's" -ForegroundColor White
    Write-Host " D3DX9. Windows never ships it and the DirectX installer does not" -ForegroundColor White
    Write-Host " contain it, so without this the game closes with a system error." -ForegroundColor White
    Write-Host " Renaming d3dx9_43.dll does NOT work - it is a different library." -ForegroundColor Gray
    Write-Host ""
    Write-Info "Fetching it from Microsoft's own NuGet package..."

    $pkgTmp = Join-Path $env:TEMP ("d3dx_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
    New-Item -ItemType Directory -Path $pkgTmp -Force | Out-Null
    $nupkg = Join-Path $pkgTmp "dxsdk.zip"
    $gotD3dx = $false
    try {
        Invoke-WebRequest -Uri $D3DX_NUPKG_URL -OutFile $nupkg -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
    } catch { }
    if (Test-Path -LiteralPath $nupkg) {
        # A .nupkg is a ZIP. Pull the one entry we need instead of
        # unpacking 9 MB of headers and libraries.
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
            $arc = [System.IO.Compression.ZipFile]::OpenRead($nupkg)
            try {
                $entry = $arc.Entries | Where-Object { $_.FullName -ieq $D3DX_IN_PKG } | Select-Object -First 1
                if (-not $entry) { $entry = $arc.Entries | Where-Object { $_.Name -ieq $D3DX_DEBUG_DLL -and $_.FullName -match '(?i)debug.*x86' } | Select-Object -First 1 }
                if ($entry) {
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $d3dxDest, $true)
                    $gotD3dx = (Test-Path -LiteralPath $d3dxDest)
                }
            } finally { $arc.Dispose() }
        } catch { }
    }
    try { Remove-Item $pkgTmp -Recurse -Force -EA SilentlyContinue } catch {}

    # Downloads folder next - the user may already have fetched it, either
    # as a bare DLL or inside a ZIP.
    if (-not $gotD3dx) {
        $dlDir = Join-Path $env:USERPROFILE "Downloads"
        foreach ($probe in @($dlDir, [Environment]::GetFolderPath('Desktop'))) {
            if ($gotD3dx -or -not $probe -or -not (Test-Path -LiteralPath $probe)) { continue }
            $bare = Get-ChildItem -LiteralPath $probe -Filter $D3DX_DEBUG_DLL -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($bare) {
                try { Copy-Item -LiteralPath $bare.FullName -Destination $d3dxDest -Force -ErrorAction Stop; $gotD3dx = $true } catch {}
                continue
            }
            $zips = Get-ChildItem -LiteralPath $probe -Filter "*.zip" -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match '(?i)d3dx9d' } | Sort-Object LastWriteTime -Descending
            foreach ($z in $zips) {
                if ($gotD3dx) { break }
                try {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                    $a2 = [System.IO.Compression.ZipFile]::OpenRead($z.FullName)
                    try {
                        $e2 = $a2.Entries | Where-Object { $_.Name -ieq $D3DX_DEBUG_DLL } | Select-Object -First 1
                        if ($e2) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e2, $d3dxDest, $true); $gotD3dx = (Test-Path -LiteralPath $d3dxDest) }
                    } finally { $a2.Dispose() }
                } catch { }
            }
        }
        if ($gotD3dx) { Write-Info "Taken from your Downloads/Desktop folder." }
    }

    # Manual last resort: open a page that hosts the file and accept a
    # dropped DLL or ZIP.
    while (-not $gotD3dx) {
        Write-Warn "Could not fetch $D3DX_DEBUG_DLL automatically."
        Write-Host " You can download it by hand - the file is the same one either way:" -ForegroundColor White
        Write-Host "   $D3DX_MANUAL_URL" -ForegroundColor Gray
        Write-Host " Third-party download sites are worth a moment of care; the copy" -ForegroundColor Gray
        Write-Host " inside Microsoft's NuGet package above is the signed original." -ForegroundColor Gray
        Pause-User "Press Enter to open the download page (or skip below)..." | Out-Null
        try { Start-Process $D3DX_MANUAL_URL } catch { Write-Warn "Open manually: $D3DX_MANUAL_URL" }
        Write-Host ""
        $raw = (Read-Host " Drag the downloaded DLL or ZIP here (empty = skip)").Trim().Trim('"').Trim("'")
        if (-not $raw) { break }
        if (-not (Test-Path -LiteralPath $raw)) { Write-Fail "File not found: $raw"; continue }
        if ($raw -match '(?i)\.zip$') {
            try {
                Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
                $a3 = [System.IO.Compression.ZipFile]::OpenRead($raw)
                try {
                    $e3 = $a3.Entries | Where-Object { $_.Name -ieq $D3DX_DEBUG_DLL } | Select-Object -First 1
                    if ($e3) { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e3, $d3dxDest, $true); $gotD3dx = (Test-Path -LiteralPath $d3dxDest) }
                    else { Write-Fail "No $D3DX_DEBUG_DLL inside that archive." }
                } finally { $a3.Dispose() }
            } catch { Write-Fail "Could not read that archive: $($_.Exception.Message)" }
        } elseif ($raw -match '(?i)\.dll$') {
            try { Copy-Item -LiteralPath $raw -Destination $d3dxDest -Force -ErrorAction Stop; $gotD3dx = $true }
            catch { Write-Fail "Could not copy it: $($_.Exception.Message)" }
        } else {
            Write-Fail "That is neither a .dll nor a .zip."
        }
    }

    if ($gotD3dx) {
        Write-OK "$D3DX_DEBUG_DLL is in place."
    } else {
        Write-Warn "Skipped - the game will NOT start until $D3DX_DEBUG_DLL sits"
        Write-Host "  next to $GAME_EXE in $gamePath" -ForegroundColor Yellow
    }
}

Write-Step 5 5 "Desktop shortcut"

$launchFull = [System.IO.Path]::Combine($gamePath, $LAUNCH_BAT)
# The .bat carries no icon of its own, so the Hub's own COD4 VR icon is
# copied next to the game and used - stable path even if the Hub folder
# moves later. Same approach as Forza Horizon, BotW and Total Chaos.
$iconArg = $null
try {
    $iconSrc = Join-Path $PSScriptRoot $ICON_FILE
    $iconDst = [System.IO.Path]::Combine($gamePath, $ICON_FILE)
    if (Test-Path -LiteralPath $iconSrc) {
        Copy-Item -LiteralPath $iconSrc -Destination $iconDst -Force -ErrorAction Stop
        if (Test-Path -LiteralPath $iconDst) { $iconArg = $iconDst }
    }
} catch {}
if (-not $iconArg) { $iconArg = ([System.IO.Path]::Combine($gamePath, $GAME_EXE)) + ",0" }

try {
    [void](New-DesktopShortcut -ShortcutName "Call of Duty 4 VR" `
        -TargetPath $launchFull `
        -WorkingDir $gamePath `
        -IconPath $iconArg `
        -Description "Launch Call of Duty 4 in VR (KisakCOD VR)")
    Write-OK "Desktop shortcut created: Call of Duty 4 VR"
} catch { Write-Warn "Could not create the desktop shortcut." }

try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
if ($relTag) { try { Set-Content -Path (Join-Path $SCRIPT_DIR ".installed_version") -Value $relTag -Encoding UTF8 -Force } catch {} }
if ($relTag) { Save-InstalledStamp -GameDir $gamePath -Version $relTag -HubDir $SCRIPT_DIR }
try { Set-Content -Path (Join-Path $SCRIPT_DIR ".launch_exe") -Value $launchFull -Encoding UTF8 -Force } catch {}
try { Remove-Item $work -Recurse -Force -EA SilentlyContinue } catch {}

# -------------------------------------------------------
#  DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Call of Duty 4 VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "  |            START IT THE RIGHT WAY                        |" -ForegroundColor Yellow
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "   Start your OpenXR runtime FIRST, then launch with" -ForegroundColor White
Write-Host "   " -NoNewline -ForegroundColor White
Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " in the Hub or the new desktop shortcut." -ForegroundColor White
Write-Host "   Starting the game from Steam does not start the VR build -" -ForegroundColor White
Write-Host "   it only comes up through $LAUNCH_BAT" -ForegroundColor White
Write-Host ""
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "  |            TWO THINGS TO KNOW                            |" -ForegroundColor Yellow
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "   Death From Above is not supported and has to be skipped -" -ForegroundColor White
Write-Host "   it looks unlocked, but do not pick it. Open the console and" -ForegroundColor White
Write-Host "   run " -NoNewline -ForegroundColor White
Write-Host " /spmap bog_b " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " to continue with War Pig." -ForegroundColor White
Write-Host "   New Game starts at Crew Expendable on purpose: the F.N.G." -ForegroundColor White
Write-Host "   training mission performs badly in VR." -ForegroundColor White
Write-Host ""
if (Test-Path -LiteralPath ([System.IO.Path]::Combine($gamePath, $CONFIG_EXE))) {
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "  |            SET IT UP IN THE CONFIGURATOR                 |" -ForegroundColor Yellow
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "   In the game folder, run " -NoNewline -ForegroundColor White
Write-Host " $CONFIG_EXE " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Pick a preset - Tested Quest 3, Performance, Comfort Snap," -ForegroundColor White
Write-Host "   Smooth Turn, Seated or Minimal HUD - then Save & Launch." -ForegroundColor White
Write-Host "   Turning, HUD and compass, weapon and hand fit, belt and" -ForegroundColor White
Write-Host "   grenade calibration, reload style and scope alignment are all" -ForegroundColor White
Write-Host "   in there, with previews and a check before saving." -ForegroundColor White
Write-Host "   Your profile lives outside the game folder, so the next" -ForegroundColor Gray
Write-Host "   package update keeps it." -ForegroundColor Gray
if (Test-Path -LiteralPath ([System.IO.Path]::Combine($gamePath, $INPUT_EXE))) {
Write-Host "" -ForegroundColor White
Write-Host "   For the BUTTONS there is a second tool next to it:" -ForegroundColor White
Write-Host " $INPUT_EXE " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   The configurator handles VR and graphics, the input mapper" -ForegroundColor Gray
Write-Host "   handles the controller layout - two separate programs." -ForegroundColor Gray
}
if ($settingsSaved) {
Write-Host "   Had you hand-edited $SETTINGS_BAT? It is saved as" -ForegroundColor Gray
Write-Host "   $SETTINGS_PREV - import it in the configurator." -ForegroundColor Gray
}
Write-Host ""
}
Write-Host "  Start with a preset. If it stutters, drop the render mode in" -ForegroundColor Gray
Write-Host "  the configurator - the default is built for a Quest 3 on a" -ForegroundColor Gray
Write-Host "  strong GPU. $SETTINGS_BAT stays in the game folder as the" -ForegroundColor Gray
Write-Host "  plain-text fallback; fully restart the game after editing it." -ForegroundColor Gray
Write-Host ""
Write-Host "  Aim with your hands, shoulder the rifle, and go loud." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to close." | Out-Null
