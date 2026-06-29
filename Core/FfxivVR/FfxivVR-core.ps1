# ============================================================
# Final Fantasy XIV - FFXIV VR Plugin Installer
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "FFXIV VR Installer"
$ErrorActionPreference = "Stop"

$XIVLAUNCHER_URL = "https://github.com/goatcorp/FFXIVQuickLauncher/releases/download/7.0.20/XIVLauncher-win-Setup.exe"
$REPO_URL = "https://raw.githubusercontent.com/WesleyLuk90/ffxiv-vr/refs/heads/master/PluginRepo/pluginmaster.json"

function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Final Fantasy XIV - FFXIV VR Plugin Installer" -ForegroundColor Cyan
 Write-Host " FFXIV VR v0.0.62 via XIVLauncher / Dalamud" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}
function Write-Step { param($n,$t,$txt)
 Write-Host ""; Write-Host "--- [$n/$t] $txt ---" -ForegroundColor Cyan; Write-Host ""
}
function Write-OK { param($t) Write-Host " [OK] $t" -ForegroundColor Green }
function Write-Warn { param($t) Write-Host " [!!] $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host " [XX] $t" -ForegroundColor Red }
function Write-Info { param($t) Write-Host " [..] $t" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Find-XIVLauncher {
 $candidates = @(
 (Join-Path $env:LOCALAPPDATA "XIVLauncher\current\XIVLauncher.exe"),
 (Join-Path $env:LOCALAPPDATA "XIVLauncher\XIVLauncher.exe"),
 (Join-Path $env:PROGRAMFILES "XIVLauncher\XIVLauncher.exe"),
 "${env:ProgramFiles(x86)}\XIVLauncher\XIVLauncher.exe"
 )
 foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
 return $null
}

# Locate the FFXIV install root. Two distributions are common:
# the Steam version (in steamapps\common\FINAL FANTASY XIV Online)
# and the standalone Square Enix launcher version (in
# Program Files\SquareEnix\FINAL FANTASY XIV - A Realm Reborn).
# Both have boot\ffxivboot.exe at the same relative location, so
# checking for that file is the most reliable identifier.
function Find-FFXIVGamePath {
 # Direct default paths (Square Enix standalone)
 $candidates = @(
 "${env:ProgramFiles(x86)}\SquareEnix\FINAL FANTASY XIV - A Realm Reborn",
 "${env:ProgramFiles}\SquareEnix\FINAL FANTASY XIV - A Realm Reborn"
 )

 # Steam libraries: read from registry + libraryfolders.vdf
 $steamPath = $null
 foreach ($reg in @(
 "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
 "HKLM:\SOFTWARE\Valve\Steam",
 "HKCU:\SOFTWARE\Valve\Steam"
 )) {
 try {
 $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
 if ($p -and (Test-Path $p)) { $steamPath = $p; break }
 } catch {}
 }
 if ($steamPath) {
 $libs = @($steamPath)
 $vdf = Join-Path $steamPath "steamapps\libraryfolders.vdf"
 if (Test-Path $vdf) {
 [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object {
 $l = $_.Groups[1].Value -replace '\\\\', '\'
 if (Test-Path $l) { $libs += $l }
 }
 }
 foreach ($lib in $libs) {
 $candidates += (Join-Path $lib "steamapps\common\FINAL FANTASY XIV Online")
 }
 }

 # First candidate that contains boot\ffxivboot.exe wins.
 foreach ($c in $candidates) {
 if (Test-Path (Join-Path $c "boot\ffxivboot.exe")) { return $c }
 }
 return $null
}

Write-Header

# ---- STEP 1: XIVLauncher ----
Write-Step 1 3 "Checking XIVLauncher"

$xlPath = Find-XIVLauncher

if ($xlPath) {
 Write-OK "XIVLauncher found: $xlPath"
} else {
 Write-Warn "XIVLauncher not found. Downloading now..."
 $setupExe = Join-Path $env:TEMP "XIVLauncher-Setup.exe"
 try {
 Write-Host " Downloading XIVLauncher Setup ... " -NoNewline -ForegroundColor White
 Invoke-WebRequest -Uri $XIVLAUNCHER_URL -OutFile $setupExe -UseBasicParsing -EA Stop
 Write-Host "OK" -ForegroundColor Green
 } catch {
 Write-Fail "Download failed: $_"
 Write-Host " The Warrior of Light... in VR. A realm reborn!" -ForegroundColor Green
 Write-Host ""
 $__fb = Invoke-InstallerFallback -Action "XIVLauncher download" `
 -Url "https://goatcorp.github.io" `
 -Instructions "Download XIVLauncher manually from https://goatcorp.github.io and install it, then retry." `
 -SkipMessage "Skipped - cannot install FFXIV VR without XIVLauncher." `
 -AllowSkip $false
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

 Write-Host ""
 Write-Host " The XIVLauncher setup window will open now." -ForegroundColor Yellow
 Write-Host " Complete the installation, then come back here." -ForegroundColor Yellow

 Start-Process $setupExe
 Remove-Item $setupExe -Force -EA SilentlyContinue
 Pause-User "Press Enter once XIVLauncher is installed..."

 $xlPath = Find-XIVLauncher
 if ($xlPath) {
 Write-OK "XIVLauncher found: $xlPath"
 } else {
 Write-Warn "Could not find XIVLauncher automatically."
 Write-Info "Default: C:\Users\$env:USERNAME\AppData\Local\XIVLauncher\current\XIVLauncher.exe"
 $custom = (Read-Host " Enter path manually (or press Enter to skip)").Trim().Trim('"')
 if ($custom -and (Test-Path $custom)) { $xlPath = $custom; Write-OK "Found: $xlPath" }
 }
}

# ---- STEP 2: Auto-write custom repo to dalamudConfig.json ----
Write-Step 2 3 "Registering Custom Plugin Repository"

$xlData = Join-Path $env:APPDATA "XIVLauncher"
$repoConfigPath = Join-Path $xlData "dalamudConfig.json"

if (Test-Path $repoConfigPath) {
 try {
 $config = Get-Content $repoConfigPath -Raw | ConvertFrom-Json
 $repos = @()
 if ($config.ThirdRepoList) { $repos = @($config.ThirdRepoList) }
 $alreadyAdded = $repos | Where-Object { $_.Url -eq $REPO_URL }
 if ($alreadyAdded) {
 Write-OK "Custom repo already registered."
 } else {
 $newRepo = [PSCustomObject]@{ Url = $REPO_URL; IsEnabled = $true }
 $repos = $repos + $newRepo
 $config | Add-Member -Force -NotePropertyName "ThirdRepoList" -NotePropertyValue $repos
 $config | ConvertTo-Json -Depth 10 | Set-Content $repoConfigPath -Encoding UTF8
 Write-OK "Custom repo registered in dalamudConfig.json."
 }
 } catch {
 Write-Warn "Could not auto-write config: $_"
 Write-Info "You will add the repo URL manually in-game (see steps below)."
 }
} else {
 Write-Warn "dalamudConfig.json not found."
 Write-Info "XIVLauncher must be started and Dalamud enabled at least once first."
 Write-Info "You will add the repo URL manually in-game (see steps below)."
}

# ---- STEP 3: In-game setup guide ----
Write-Step 3 3 "In-Game Setup Guide"

Write-Host ""
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host " ACTION REQUIRED - In-Game Setup (follow every step)" -ForegroundColor Yellow
Write-Host " ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " Start FFXIV via XIVLauncher now, then follow these steps:" -ForegroundColor White
Write-Host ""

try { Set-Clipboard -Value "/xlplugins" } catch {}
Write-Host " [OK] /xlplugins copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host " 1. Log into FFXIV via XIVLauncher." -ForegroundColor White
Write-Host ""
Write-Host " 2. In the chat field, paste and send: /xlplugins" -ForegroundColor White
Write-Host " (already in your clipboard - press Ctrl+V)" -ForegroundColor Gray
Write-Host " This opens the Dalamud Plugin Installer." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter once the Plugin Installer is open..."

Write-Host ""
Write-Host " 3. Click the Settings gear icon in the Plugin Installer." -ForegroundColor White
Write-Host ""
Write-Host " 4. Enable: 'Wait for plugins before the game is loaded'" -ForegroundColor Yellow
Write-Host " (check this box - required for VR to initialize correctly)" -ForegroundColor Gray
Write-Host ""
Write-Host " 5. Open the 'Experimental' tab." -ForegroundColor White
Write-Host ""

# Now copy the repo URL
try { Set-Clipboard -Value $REPO_URL } catch {}
Write-Host " [OK] Plugin repo URL copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host " 6. Click into the empty URL field (row 1) and paste (Ctrl+V):" -ForegroundColor White
Write-Host " $REPO_URL" -ForegroundColor Cyan
Write-Host ""
Write-Host " 7. Check the 'Enabled' checkbox next to the URL." -ForegroundColor White
Write-Host ""
Write-Host " 8. Click the Save icon (bottom right)." -ForegroundColor White
Write-Host ""
Write-Host " 9. Click 'Refresh' (bottom left)." -ForegroundColor White
Write-Host ""
Write-Host " 10. Go to 'All Plugins' and search for: FFXIV VR" -ForegroundColor White
Write-Host ""
Write-Host " 11. Click FFXIV VR -> Install v0.0.62." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter once FFXIV VR is installed..."

Write-Host ""
Write-Host " 12. Before restarting, configure VR settings:" -ForegroundColor White
Write-Host ""
Write-Host " In the chat field, type: /vr" -ForegroundColor Yellow
Write-Host " This opens the FFXIV VR settings panel." -ForegroundColor Gray
Write-Host ""
Write-Host " Recommended: enable 'Start in VR automatically'" -ForegroundColor White
Write-Host " so VR launches every time without needing /vr start." -ForegroundColor Gray
Write-Host " Configure any other VR settings to your preference now." -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter once you have configured VR settings..."

Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host " In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host " Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."

# Write a small marker file in the FFXIV game root so the Hub
# can recognize this install as VR Ready on subsequent scans.
# Without it the Hub only sees the game installed (no DLL to
# probe - the VR mod runs out-of-process via Dalamud).
$ffxivRoot = Find-FFXIVGamePath
# The Hub detects FFXIV VR by XIVLauncher.exe (what actually runs the
# Dalamud VR plugin), so record the XIVLauncher folder for the
# post-install VR-Ready refresh. Fall back to the game root only if the
# launcher path is somehow unknown.
$recordRoot = $null
if ($xlPath -and (Test-Path $xlPath)) { $recordRoot = (Split-Path -Parent $xlPath) }
elseif ($ffxivRoot) { $recordRoot = $ffxivRoot }
if ($recordRoot) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $recordRoot -Encoding UTF8 -Force } catch {} }
if ($ffxivRoot) {
 $marker = Join-Path $ffxivRoot "vr-installed.txt"
 try {
 Set-Content -Path $marker -Value "FFXIV VR v0.0.62 installed via Hub on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Encoding UTF8 -Force
 Write-OK "Wrote VR marker: $marker"
 } catch {
 Write-Warn "Could not write VR marker file: $_"
 }
} else {
 Write-Warn "FFXIV install folder not found - VR marker file skipped."
 Write-Info "The Hub will still detect the install once the game is launched once."
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host " 13. Restart FFXIV." -ForegroundColor White
Write-Host " VR will start automatically on launch." -ForegroundColor Gray
Write-Host ""
Write-Host " If not: type /vr start in the chat field." -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Hydaelyn calls. The realm is reborn - rise, Warrior of Light." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
