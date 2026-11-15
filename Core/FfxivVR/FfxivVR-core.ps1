# ============================================================
# Final Fantasy XIV - FFXIV VR Plugin Installer
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")
. (Join-Path $PSScriptRoot "..\Modules\InstallerFoundation.ps1")
. (Join-Path $PSScriptRoot "..\Modules\FfxivPluginProof.ps1")

$Host.UI.RawUI.WindowTitle = "FFXIV VR Installer"
$ErrorActionPreference = "Stop"

$XIVLAUNCHER_URL = "https://github.com/goatcorp/FFXIVQuickLauncher/releases/download/7.0.20/XIVLauncher-win-Setup.exe"
$REPO_URL = "https://raw.githubusercontent.com/WesleyLuk90/ffxiv-vr/refs/heads/master/PluginRepo/pluginmaster.json"

function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Final Fantasy XIV - FFXIV VR Plugin Installer" -ForegroundColor Cyan
 Write-Host " FFXIV VR via XIVLauncher / Dalamud" -ForegroundColor Gray
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
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") [void](Wait-PCVRExplicitEnter -Message $text) }

function Invoke-FFxivLauncherSetup {
    param([Parameter(Mandatory=$true)][string]$Path,[string]$Arguments='')
    Write-Host 'The XIVLauncher setup window will open. Complete setup before returning here.' -ForegroundColor Yellow
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open XIVLauncher setup...')
    $start=@{FilePath=$Path;Wait=$true;PassThru=$true;NoNewWindow=$true}
    if($Arguments){$start.ArgumentList=$Arguments}
    $process=Start-Process @start
    if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){
        throw "XIVLauncher setup did not finish successfully (exit $($process.ExitCode)). The downloaded setup was kept for retry: $Path"
    }
}

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
 $saved=Get-PCVRRememberedGameFolder -GameId 'final-fantasy-xiv-vr' -StateNames @('base_game_path','user_located')
 if($saved -and (Test-PCVRGameInstallProof -GameId 'final-fantasy-xiv-vr' -Root $saved)){return $saved}
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
 if (Test-Path -LiteralPath "$c\boot\ffxivboot.exe") { if (Test-PCVRGameInstallProof -GameId 'final-fantasy-xiv-vr' -Root $c) { return $c } }
 }
 return $null
}

Write-Header

# ---- STEP 1: XIVLauncher ----
Write-Host " FFXIV VR by WesleyLuk90 - a VR plugin for Final Fantasy XIV, installed" -ForegroundColor White
Write-Host " through XIVLauncher and Dalamud. Gamepad controls." -ForegroundColor White
Show-AntivirusNotice -Compact
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 3 "Checking XIVLauncher"

$xlPath = Find-XIVLauncher

if ($xlPath) {
 Write-OK "XIVLauncher found: $xlPath"
} else {
 Write-Warn "XIVLauncher not found. Downloading now..."
 $setupExe = Join-Path $env:TEMP "XIVLauncher-Setup.exe"
 try {
 Write-Host " Downloading XIVLauncher Setup ... " -NoNewline -ForegroundColor White
 Invoke-PCVRWebRequest -Uri $XIVLAUNCHER_URL -OutFile $setupExe -UseBasicParsing -EA Stop
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

 Invoke-FFxivLauncherSetup -Path $setupExe
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

if ((Test-Path -LiteralPath $repoConfigPath) -and -not (Get-Process -Name XIVLauncher,ffxiv,ffxiv_dx11 -ErrorAction SilentlyContinue)) {
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
 Write-Host 'The Hub will add this repository to the closed launcher config and keep a backup.' -ForegroundColor White
 [void](Wait-PCVRExplicitEnter -Message 'Press Enter to register the repository...')
 $json=$config|ConvertTo-Json -Depth 100 -WarningAction Stop
 $backup=$repoConfigPath+'.pcvrhub-'+[guid]::NewGuid().ToString('N')+'.bak'
 Copy-Item -LiteralPath $repoConfigPath -Destination $backup -ErrorAction Stop
 Write-PCVRAtomicText -Path $repoConfigPath -Value $json
 Write-OK "Custom repo registered in dalamudConfig.json."
 }
 } catch {
 Write-Warn "Could not auto-write config: $_"
 Write-Info "You will add the repo URL manually in-game (see steps below)."
 }
} else {
 Write-Warn "The launcher config is missing or XIVLauncher / FFXIV is running; automatic editing was skipped."
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
Write-Host " 11. Click FFXIV VR -> Install the newest version." -ForegroundColor White
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

# XIVLauncher by itself is not the VR mod. Dalamud stores plugins outside
# the game and launcher folders, so verify the actual plugin before writing
# either the Hub path receipt or the game-side recovery marker.
$pluginDll = $null;$pluginVersion='';$pluginEvidence=@()
$selected=@(Get-PCVRFfxivPluginProof)
if($selected.Count){$pluginDll=$selected[0].Dll;$pluginVersion=[string]$selected[0].Version;$pluginEvidence=@($selected[0].Files)}
if (-not $pluginDll) {
    Write-Fail "A complete versioned FFXIV VR plugin was not found in Dalamud's installedPlugins folder."
    Write-Host "  Finish the plugin installation in /xlplugins, then run this setup again." -ForegroundColor Yellow
    Pause-User "Press Enter to exit; VR Ready was not recorded."
    exit 1
}
Write-OK "Dalamud VR plugin verified: $($pluginDll.FullName)"

# The base game, launcher and Dalamud plugin occupy separate roots.
# Record the actual plugin version only after all three proofs exist.
$ffxivRoot = Find-FFXIVGamePath
# The Hub detects FFXIV VR by XIVLauncher.exe (what actually runs the
# Dalamud VR plugin), so record the XIVLauncher folder for the
# post-install VR-Ready refresh. Fall back to the game root only if the
# launcher path is somehow unknown.
$recordRoot = $null
if ($xlPath -and (Test-Path $xlPath)) { $recordRoot = (Split-Path -Parent $xlPath) }
elseif ($ffxivRoot) { $recordRoot = $ffxivRoot }
if(-not $ffxivRoot -or -not(Test-PCVRGameInstallProof -GameId 'final-fantasy-xiv-vr' -Root $ffxivRoot)){throw 'The original FFXIV game could not be verified. Select its original game folder in the Hub; no VR-ready receipt was written.'}
if(-not $recordRoot -or -not [IO.File]::Exists((Join-Path $recordRoot 'XIVLauncher.exe'))){throw 'The XIVLauncher launch target is missing; no VR-ready receipt was written.'}
if(-not(Save-HubRememberedGameFolder -GameId 'final-fantasy-xiv-vr' -Title 'Final Fantasy XIV VR' -GameDir $ffxivRoot -StateName 'base_game_path')){throw 'The verified original game path could not be saved.'}
$contract=New-PCVRInstallerContract -Id 'final-fantasy-xiv-vr' -GameName 'FFXIV VR' -Acquisition External -AntivirusNotice -RequiredInstalledFileGroups @('XIVLauncher.exe') -RequiredExternalFileGroups $pluginEvidence
[void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $recordRoot -Version $pluginVersion -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -InstalledVersionReceiptPaths @((Join-Path $PSScriptRoot '.installed_version')))

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host " 1. Use Start in VR in the Hub. It opens XIVLauncher." -ForegroundColor White
Write-Host " Restart FFXIV through XIVLauncher after installing the plugin." -ForegroundColor Gray
Write-Host ""
Write-Host " If not: type /vr start in the chat field." -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Hydaelyn calls. The realm is reborn - rise, Warrior of Light." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
