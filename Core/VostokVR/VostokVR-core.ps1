# ============================================================
# Road to Vostok - VR Mod Installer v1.3.5
# ============================================================
#
# Installs the Road to Vostok VR Mod by Blah64.
# Requires Metro Mod Loader to be installed first.
# Downloads vr-mod-full.zip and extracts into the game folder.
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Road to Vostok VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "Road to Vostok"
$GAME_EXE = "RTV.exe"
$STEAM_APP = "1939830"
$MOD_URL = "https://github.com/Blah64/Vostok-VR-Mod/releases/download/v1.3.5/vr-mod-full.zip"
$MOD_NAME = "Road to Vostok VR Mod v1.3.5"
$INFO_URL = "https://github.com/Blah64/Vostok-VR-Mod"
$MML_URL = "https://modworkshop.net/mod/55623"
$MML_DL_URL = "https://storage.modworkshop.net/mods/files/55623_220962_qNbtcJXGDmIQkp9Q2rTz9Vv80E0KPBrXQpuE4hl2.zip?filename=MetroModLoader3-1-0.zip"

function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Green
 Write-Host " Road to Vostok - VR Mod Installer" -ForegroundColor Cyan
 Write-Host " $MOD_NAME by Blah64" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Green
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($r in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try { $p=(Get-ItemProperty -Path $r -EA Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
 }; return $null
}
function Get-SteamLibraries { param($sp)
 $libs=@($sp); $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
 if(Test-Path $vdf){ [regex]::Matches((Get-Content $vdf -Raw),'"path"\s+"([^"]+)"') | ForEach-Object {
 $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
 return $libs
}

# -------------------------------------------------------
# STEP 1: Check Metro Mod Loader
# -------------------------------------------------------
Write-Header
Write-Step 1 3 "Checking Requirements"

Write-Host " Road to Vostok VR requires Metro Mod Loader (MML)." -ForegroundColor White
Write-Host " MML must be installed before the VR mod will work." -ForegroundColor White
Write-Host ""

# Check for MML in common game folder locations
$sp = Get-SteamPath
$gamePath = $null
if ($sp) {
 foreach ($lib in (Get-SteamLibraries $sp)) {
 $c = Join-Path $lib "steamapps\common\$GAME_NAME"
 if (Test-Path (Join-Path $c $GAME_EXE)) { $gamePath = $c; Write-Info "Game found: $gamePath"; break }
 }
}
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1963610" -SteamFolderNames @("Road to Vostok") -ProbeExe "launch_vr.bat" }
if (-not $gamePath) {
 Write-Warn "Road to Vostok not found automatically."
 Write-Host " Enter the game folder:" -ForegroundColor White
 while (-not $gamePath) {
 $r=(Read-Host " Path").Trim().Trim('"')
 if(Test-Path(Join-Path $r $GAME_EXE)){$gamePath=$r;Write-Info "Path set: $gamePath"}else{Write-Fail "Not found: $r"}
 }
}

$tmp = Join-Path $env:TEMP "VostokVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tmp | Out-Null

$mmlCheck = Join-Path $gamePath "mods"
if (Test-Path $mmlCheck) {
 Write-Info "Metro Mod Loader already installed."
} else {
 Write-Host " Metro Mod Loader not found - installing automatically..." -ForegroundColor White
 Write-Host ""
 $mmlZip = Join-Path $tmp "MetroModLoader.zip"
 $mmlExtract = Join-Path $tmp "MML"

 # Multi-source download. GitHub releases is the stable upstream
 # source (the same files the ModWorkshop CDN serves), with the
 # ModWorkshop hash-CDN as a backup. Invoke-SafeDownload appends
 # a web.archive mirror automatically for GitHub URLs.
 $mmlSources = @(
   "https://github.com/ametrocavich/vostok-mod-loader/releases/download/v3.1.0/MetroModLoader3-1-0.zip",
   $MML_DL_URL
 )
 $r = Invoke-SafeDownload -Urls $mmlSources -Destination $mmlZip `
        -Label "Metro Mod Loader v3.1.0" `
        -ManualUrl "https://github.com/ametrocavich/vostok-mod-loader/releases" `
        -Instructions "Download the latest Metro Mod Loader release ZIP from the GitHub releases page that just opened in your browser. Place it at '$mmlZip' and choose Retry." `
        -SkipMessage "Skipped - the Vostok mod loader was not installed; the VR mod will not load (questionable result)."
 if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$r -eq "skip") {
   Write-Warn "Continuing without Metro Mod Loader."
 } elseif ([string]$r -eq "retry") {
   # User dropped the file manually - check it exists
   if (-not (Test-Path $mmlZip)) {
     Pause-User "Still no MML zip at $mmlZip. Press Enter to exit..."; exit 1
   }
 }

 # If we have the zip, extract + install
 if (Test-Path $mmlZip) {
   Write-Host " Extracting Metro Mod Loader ... " -NoNewline -ForegroundColor White
   try {
     Expand-Archive -Path $mmlZip -DestinationPath $mmlExtract -Force
     Write-Host "OK" -ForegroundColor Green
     # Both override.cfg and modloader.gd go into the game folder (res:// = game root)
     foreach ($f in @("override.cfg", "modloader.gd")) {
       $src = Join-Path $mmlExtract $f
       if (Test-Path $src) { Copy-Item $src $gamePath -Force }
     }
     New-Item -ItemType Directory -Path (Join-Path $gamePath "mods") -Force | Out-Null
     Write-Info "Metro Mod Loader installed."
   } catch {
     Write-Host "FAILED" -ForegroundColor Red
     $__fb = Invoke-InstallerFallback -Action "Metro Mod Loader extraction" `
       -Instructions "Open '$mmlZip' with 7-Zip or Windows Explorer, extract its contents, and copy override.cfg + modloader.gd into '$gamePath'. Then choose Retry." `
       -SkipMessage "Skipped - the mod loader is not installed; the VR mod will not run (questionable result)." `
       -SourceFolder (Split-Path "$mmlZip" -Parent) `
       -DestFolder "$gamePath" `
       -AllowSkip $true
     if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
     if ([string]$__fb -eq "retry") {
       # Check if user copied the files manually
       if ((Test-Path (Join-Path $gamePath "modloader.gd")) -and (Test-Path (Join-Path $gamePath "override.cfg"))) {
         New-Item -ItemType Directory -Path (Join-Path $gamePath "mods") -Force | Out-Null
         Write-OK "Manual install detected - continuing."
       } else {
         Pause-User "Still no modloader.gd + override.cfg in $gamePath. Press Enter to exit..."; exit 1
       }
     }
   }
 }
}


# -------------------------------------------------------
# STEP 2: Download and install VR mod
# -------------------------------------------------------
# --- Update-or-install choice (shared helper) ---
$InstallMode = Read-UpdateOrInstall -GameFolder $gamePath -ModFile "mods\vr-mod.vmz"
if ($InstallMode -eq "cancel") { Pause-User "Press Enter to exit."; exit 0 }
if ($InstallMode -eq "update") { Write-Info "Update mode - re-downloading the latest version and replacing the mod files." }

Write-Step 2 3 "Downloading $MOD_NAME"
$modZip = Join-Path $tmp "vr-mod-full.zip"

Write-Host " Downloading VR mod ... " -NoNewline -ForegroundColor White
try {
 Invoke-WebRequest -Uri $MOD_URL -OutFile $modZip -UseBasicParsing -EA Stop
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Download failed: $_"
 Write-Host " Download manually from: $INFO_URL/releases" -ForegroundColor Yellow
 Write-Host " Extract into: $gamePath" -ForegroundColor Yellow
 $__fb = Invoke-InstallerFallback -Action "VR mod download" `
 -Url "https://github.com/Blah64/Vostok-VR-Mod/releases" `
 -Instructions "Download the mod ZIP manually from $INFO_URL/releases and extract its contents into $gamePath, then choose Skip to continue." `
 -SkipMessage "Skipped - the VR mod files were NOT installed; if you copied them manually the rest of this installer can continue." `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # Re-check is not possible here without knowing local state.
 # If the user fixed the issue, the next pass through the
 # installer will succeed. Exit cleanly so they can re-run.
 Pause-User "Please re-run the installer once the issue is resolved. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

Write-Step 3 3 "Installing"

Write-Host " Extracting VR mod files ... " -NoNewline -ForegroundColor White
try {
 $modExtract = Join-Path $tmp "vostok_mod"
 Expand-Archive -Path $modZip -DestinationPath $modExtract -Force

 # Copy everything directly to game folder preserving structure
 # launch_vr.bat expects: VR Mod\bin\rtv_vr_injector.exe, mods\vr-mod.vmz,
 # rtv_vr_bootstrap.dll and librtv_vr_mod.windows.x86_64.dll in root
 Get-ChildItem -Path $modExtract | ForEach-Object {
 Copy-Item $_.FullName $gamePath -Recurse -Force
 }

 # override.cfg from VR Mod\resources must go into game root (not subfolder)
 $vrOverride = Join-Path $modExtract "VR Mod" | Join-Path -ChildPath "resources" | Join-Path -ChildPath "override.cfg"
 if (Test-Path $vrOverride) { Copy-Item $vrOverride $gamePath -Force }
 Write-Host "OK" -ForegroundColor Green
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Fail "Extraction failed: $_"
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$modZip' with 7-Zip or Windows Explorer, and extract its contents into '$modExtract'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder (Split-Path "$modZip" -Parent) `
 -DestFolder "$modExtract" `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # User claims they extracted manually. Re-run extract logic
 # by exiting and forcing re-run (we don't know which archive
 # variable this catch belongs to without context).
 Pause-User "We will exit so you can re-run with the fixed environment. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

try { Remove-Item $tmp -Recurse -Force -EA SilentlyContinue } catch {}

# Verify key files
$launchBat = Join-Path $gamePath "launch_vr.bat"
$vmzFile = Join-Path $gamePath "mods\vr-mod.vmz"
$allGood = (Test-Path $launchBat) -and (Test-Path $vmzFile)

# Record install path for the post-install VR-Ready refresh (no full scan needed).
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}

# Desktop shortcut
$shortcutCreated = $false
if (Test-Path $launchBat) {
 try {
 $sc = New-DesktopShortcut -LnkPath "$env:USERPROFILE\Desktop\Road to Vostok VR.lnk" -TargetPath $launchBat -WorkingDir $gamePath -IconPath "$(Join-Path $gamePath 'RTV.exe'),0"
 $shortcutCreated = $true
 } catch {}
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Green
if (Test-Path $launchBat) { Write-Host " [x] launch_vr.bat" -ForegroundColor Green }
else { Write-Host " [ ] launch_vr.bat -- MISSING" -ForegroundColor Red }
if (Test-Path $vmzFile) { Write-Host " [x] mods\vr-mod.vmz" -ForegroundColor Green }
else { Write-Host " [ ] mods\vr-mod.vmz -- MISSING" -ForegroundColor Red }
if ($shortcutCreated) { Write-Host " [x] Desktop shortcut 'Road to Vostok VR' created." -ForegroundColor Green }
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " !! FIRST LAUNCH - READ THIS NOW !!" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " 1) Start SteamVR before launching the game" -ForegroundColor White
Write-Host " 2) Launch only via 'Road to Vostok VR' desktop shortcut" -ForegroundColor White
Write-Host " Do NOT use Steam's Play button directly" -ForegroundColor Gray
Write-Host " 3) It starts with a black screen in headset, switch to desktop viewer" -ForegroundColor White
Write-Host " and press 'Launch with mods (Restart)'" -ForegroundColor White
Write-Host "===================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Tip: F8 in-game opens VR settings (weapon grip, watch HUD, etc.)" -ForegroundColor Gray
Write-Host "" -ForegroundColor Green
Write-Host "Dead reckoning never felt this real." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
