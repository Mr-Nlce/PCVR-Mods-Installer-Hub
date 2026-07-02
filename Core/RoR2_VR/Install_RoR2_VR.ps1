# ============================================================
#  Risk of Rain 2 - VR Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "RoR2 VR Mod Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers (Invoke-DownloadOrFallback,
# Expand-ArchiveOrFallback, Invoke-InstallerFallback)
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

# -------------------------------------------------------
# Mod list - exact pinned versions
# -------------------------------------------------------
$MODS = @(
    @{ Author="bbepis";        Name="BepInExPack";                Version="5.4.2115"; Type="bepinex"  },
    @{ Author="RiskofThunder"; Name="RoR2BepInExPack";            Version="1.16.0";   Type="bepinex"  },
    @{ Author="RiskofThunder"; Name="BepInEx_GUI";                Version="3.0.1";    Type="plugins"  },
    @{ Author="RiskofThunder"; Name="FixPluginTypesSerialization"; Version="1.0.3";    Type="patchers" },
    @{ Author="RiskofThunder"; Name="HookGenPatcher";             Version="1.2.3";    Type="patchers" },
    @{ Author="DrBibop";       Name="VRMod";                      Version="2.9.2";    Type="plugins"  }
)

# Steam Depot details
$DEPOT_APPID    = "632360"
$DEPOT_DEPOTID  = "632361"
$DEPOT_MANIFEST = "9058106608706845920"
$DEPOT_COMMAND  = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"

# Final stable install location - moved out of steamapps\content
# so Steam can't overwrite it on a future depot download.
$DEFAULT_PARENT = "C:\Games"
$TARGET_NAME    = "Risk of Rain 2 VR"
$DEFAULT_PATH   = Join-Path $DEFAULT_PARENT $TARGET_NAME
$GAME_EXE       = "Risk of Rain 2.exe"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host "   Risk of Rain 2 - VR Mod Installer" -ForegroundColor Cyan
    Write-Host "   Installs: VRMod 2.9.2 + all dependencies" -ForegroundColor Gray
    Write-Host "=============================================" -ForegroundColor Magenta
    Write-Host ""
}

function Write-Step {
    param($num, $total, $text)
    Write-Host ""
    Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
    Write-Host ""
}

function Write-OK   { param($text) Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host "  [..] $text" -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host "  [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "  [XX] $text" -ForegroundColor Red }

function Pause-User {
    param($text = "Press Enter to continue...")
    Write-Host ""
    Write-Host "  $text" -ForegroundColor White
    Read-Host "  "
}

# -------------------------------------------------------
# STEP 1: Steam Depot Download
# -------------------------------------------------------
Write-Header
Write-Step 1 3 "Steam Depot Download"

Write-Host "  We need to download a specific older version of Risk of Rain 2 via Steam." -ForegroundColor White
Write-Host ""
Write-Host "  Here's what's about to happen:" -ForegroundColor Cyan
Write-Host "    1) The Steam Console will open automatically" -ForegroundColor White
Write-Host "    2) The download command is already copied to your clipboard" -ForegroundColor White
Write-Host "    3) Paste with Ctrl+V into the Steam Console and hit Enter" -ForegroundColor Yellow
Write-Host "    4) Wait for Steam to finish, then come back here" -ForegroundColor White
Write-Host ""
Write-Host "  When Steam finishes it will show:" -ForegroundColor Gray
Write-Host "    Depot download complete : ...\depot_632361" -ForegroundColor Yellow
Write-Host ""

try { Set-Clipboard -Value $DEPOT_COMMAND } catch {}

Write-Host ""
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
Start-Process "steam://nav/console"
Write-OK "Steam Console opening..."

Write-Host ""
Pause-User "Press Enter once the Steam depot download is complete..."

# -------------------------------------------------------
# Auto-detect depot path from Steam registry
# -------------------------------------------------------
Write-Host ""
Write-Host "  Looking for Steam installation..." -ForegroundColor White

$steamInstallPath = $null
$steamRegPaths = @(
    "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
    "HKLM:\SOFTWARE\Valve\Steam",
    "HKCU:\SOFTWARE\Valve\Steam"
)
foreach ($reg in $steamRegPaths) {
    try {
        $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
        if ($p -and (Test-Path $p)) { $steamInstallPath = $p; break }
    } catch {}
}

$depotPath = $null

if ($steamInstallPath) {
    $autoPath = Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID"
    Write-Info "Expected depot path: $autoPath"
    if (Test-Path $autoPath) {
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

# Fallback: ask user
if (-not $depotPath) {
    $probePaths = @()
    if ($steamInstallPath) {
        $probePaths += (Join-Path $steamInstallPath "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID")
    }
    $depotPath = Resolve-DepotPath -GameName "Risk of Rain 2" -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
    if (-not $depotPath) {
        Write-Fail "No depot folder provided."
        Pause-User "Press Enter to exit..."
        exit 1
    }
}

# -------------------------------------------------------
# STEP 1.5: Move depot to stable folder
# -------------------------------------------------------
# The depot is delivered into steamapps\content\app_<id>\depot_<id>
# which Steam may overwrite during a future depot download. Move
# it to a stable, separate folder under C:\Games\ so the VR
# install survives Steam updates and stays separate from the
# retail RoR2 install.
Write-Step 2 4 "Moving game to stable folder"

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

if (Test-Path $targetPath) {
    Write-Warn "A folder already exists at $targetPath"
    Write-Host "    [Y] Delete existing folder and proceed" -ForegroundColor White
    Write-Host "    [N] Keep it, abort install" -ForegroundColor Gray
    $choice = ""
    while ($choice -notin @("y","Y","n","N")) { $choice = (Read-Host "  Your choice (Y/N)").Trim() }
    if ($choice -in @("n","N")) {
        Write-Info "Aborted by user."
        Pause-User "Press Enter to exit..."
        exit 0
    }
    try { Remove-Item $targetPath -Recurse -Force -ErrorAction Stop }
    catch { Write-Fail "Could not delete: $_"; Pause-User "Press Enter to exit..."; exit 1 }
}

try {
    $parentOfDepot = Split-Path $depotPath -Parent
    Move-Item -Path $depotPath -Destination $targetPath -ErrorAction Stop
    Write-OK "Game moved to: $targetPath"
    # Clean up empty app_<id> folder
    try {
        if ((Get-ChildItem $parentOfDepot -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
            Remove-Item $parentOfDepot -Force
        }
    } catch {}
} catch {
    Write-Fail "Move failed: $_"
    Write-Info "The game files are still at: $depotPath"
    Pause-User "Press Enter to exit..."
    exit 1
}

$gamePath = $targetPath

# -------------------------------------------------------
# STEP 2: Download and install mods into the stable folder
# -------------------------------------------------------
Write-Step 3 4 "Installing Mods"

$tempDir = Join-Path $env:TEMP "RoR2VRInstaller_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tempDir | Out-Null

$failed = @()

foreach ($mod in $MODS) {
    $author  = $mod.Author
    $name    = $mod.Name
    $version = $mod.Version
    $type    = $mod.Type

    Write-Host "  Downloading $name $version ... " -NoNewline -ForegroundColor White

    $url        = "https://thunderstore.io/package/download/$author/$name/$version/"
    $zipFile    = Join-Path $tempDir "$name-$version.zip"
    $extractDir = Join-Path $tempDir "$name-$version"

    $r = Invoke-DownloadOrFallback -Url $url -Destination $zipFile `
            -Label "$name $version" `
            -ManualUrl "https://thunderstore.io/c/risk-of-rain-2/p/$author/$name/" `
            -Instructions "Find '$name' version $version on the Thunderstore page, download the ZIP, place it at '$zipFile', then choose Retry." `
            -SkipMessage "Skipped - $name $version was not downloaded (questionable result)."
    if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if (-not ($r -is [bool] -and $r)) {
        $failed += $name
        continue
    }

    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    $efb = Expand-ArchiveOrFallback -ArchivePath $zipFile -DestinationFolder $extractDir -Label "$name $version" `
            -SkipMessage "Skipped - $name was not extracted (questionable result)."
    if ([string]$efb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    if ([string]$efb -ne "ok" -and [string]$efb -ne "manual") {
        $failed += $name
        continue
    }

    $ignore = @("manifest.json", "README.md", "icon.png", "CHANGELOG.md", "changelog.txt")

    try {
        switch ($type) {

            "bepinex" {
                # BepInExPack has an extra BepInExPack/ wrapper folder - copy its contents to game root
                $packSubdir = Join-Path $extractDir "BepInExPack"
                if (Test-Path $packSubdir) {
                    # Copy everything inside BepInExPack/ directly to game root
                    # This places winhttp.dll and BepInEx/ correctly
                    Get-ChildItem -Path $packSubdir | ForEach-Object {
                        Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
                    }
                } else {
                    # Other bepinex type mods (RoR2BepInExPack) - copy straight to game root
                    Get-ChildItem -Path $extractDir | Where-Object { $_.Name -notin $ignore } | ForEach-Object {
                        Copy-Item -Path $_.FullName -Destination $gamePath -Recurse -Force
                    }
                }
            }

            { $_ -in "plugins", "patchers" } {
                $bepinexInZip = Join-Path $extractDir "BepInEx"
                if (Test-Path $bepinexInZip) {
                    # Mod ships with BepInEx/ folder structure - merge into game root
                    Copy-Item -Path $bepinexInZip -Destination $gamePath -Recurse -Force
                } else {
                    # Mod ships plugins/ and patchers/ folders directly (e.g. VRMod)
                    # Copy their contents straight into BepInEx/plugins/ and BepInEx/patchers/
                    foreach ($subfolder in @("plugins", "patchers")) {
                        $src = Join-Path $extractDir $subfolder
                        if (Test-Path $src) {
                            $dst = Join-Path $gamePath "BepInEx\$subfolder"
                            if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst | Out-Null }
                            Get-ChildItem -Path $src | ForEach-Object {
                                Copy-Item -Path $_.FullName -Destination $dst -Recurse -Force
                            }
                        }
                    }
                }
            }
        }
        Write-Host "OK" -ForegroundColor Green
    } catch {
        Write-Host "INSTALL FAILED" -ForegroundColor Red
        Write-Host "    $_" -ForegroundColor Gray
        $failed += $name
    }
}

try { Remove-Item $tempDir -Recurse -Force } catch {}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Warn "The following mods failed and need manual installation from thunderstore.io:"
    foreach ($f in $failed) { Write-Host "    - $f" -ForegroundColor Red }
}

# -------------------------------------------------------
# STEP 3: Done
# -------------------------------------------------------
Write-Step 3 3 "All Done!"

Write-Host "  Your complete RoR2 VR installation is ready at:" -ForegroundColor White
Write-Host "  $depotPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Installed mods:" -ForegroundColor White
foreach ($mod in $MODS) {
    if ($mod.Name -notin $failed) {
        Write-Host "    [x] $($mod.Name) $($mod.Version)" -ForegroundColor Green
    } else {
        Write-Host "    [ ] $($mod.Name) $($mod.Version)  <-- FAILED, install manually" -ForegroundColor Red
    }
}
Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."

Write-Host ""
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "  Next steps:" -ForegroundColor White
Write-Host ""
Write-Host "  Game installed at: $gamePath" -ForegroundColor Gray
Write-Host ""
Write-Host "  IMPORTANT: Do NOT launch via Steam!" -ForegroundColor Yellow
Write-Host "  Use the desktop shortcut 'Risk of Rain 2 VR'." -ForegroundColor Yellow
Write-Host "  (Launching via Steam would run your retail flat version)" -ForegroundColor Gray
Write-Host ""
Write-Host "  BepInEx and VRMod load automatically." -ForegroundColor Gray
Write-Host "  SteamVR will launch alongside the game." -ForegroundColor Gray
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host ""

# Create desktop shortcut to RoR2 exe
$ror2Exe = Join-Path $gamePath $GAME_EXE
try { Set-Content -Path (Join-Path $gamePath "steam_appid.txt") -Value "632360" -Encoding ASCII -NoNewline -Force } catch {}
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

if (Test-Path $ror2Exe) {
    try {
        $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Risk of Rain 2 VR.lnk" -TargetPath $ror2Exe -WorkingDir $gamePath -IconPath "$ror2Exe,0"
        Write-OK "Desktop shortcut 'Risk of Rain 2 VR' created."
    } catch {
        Write-Warn "Could not create shortcut: $_"
    }
} else {
    Write-Info "$GAME_EXE not found - create a shortcut manually."
}

Write-Host ""
Write-Host "  Opening installation folder..." -ForegroundColor Gray
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}

Write-Host "  Seek and destroy. It's raining again!" -ForegroundColor Green
  Write-Host ""
  Pause-User "Press Enter to exit."
