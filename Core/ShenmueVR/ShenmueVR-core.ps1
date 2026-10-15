# -------------------------------------------------------
# Shenmue I & II VR Mod Installer
# ShenmueVR by Tensai37 - current publisher releases on GitHub
#
# SPECIAL CASE: the mod does NOT come as a zip but as an INNO SETUP
# PROGRAM (ShenmueVR-Setup-<version>.exe, Inno 6.7.0).
# The user has to click through that setup THEMSELVES - it asks for
# the game folder and lets them pick Shenmue I, II or both.
# We download it, check the game folder, put the path on the
# clipboard and start the setup. Afterwards we verify by the RESULT
# whether the mod is really in place.
#
# WHY NOT SILENTLY IN THE BACKGROUND: Inno supports /SILENT /DIR= -
# but the "Shenmue I / II / both" choice is made of components whose
# internal names we do not know. A silent run could therefore patch
# the wrong game. Interactive is the honest option here.
#
# v2.0 is a new install contract: OpenXR and motion controls are automatic,
# other mods in selected sm1/sm2 folders are removed, and Setup creates no
# backup. The publisher README requires a user-created backup beforehand.
# The mod detection remains ShenmueVR.ini in the selected game folder.
# -------------------------------------------------------

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Shenmue I & II VR Installer"

$MOD_NAME    = "ShenmueVR"
$MOD_AUTHOR  = "Tensai37"
$MOD_REPO    = "Tensai30/ShenmueVR-Downloads"
$RELEASES    = "https://github.com/$MOD_REPO/releases"

# Pinned build - the FALLBACK only. The address is resolved at run
# time from the newest stable GitHub release (Get-ShenmueSetupUrl). Keep it
# current anyway: without network access something old would be
# downloaded forever.
$PINNED_VER  = "v2.0"
# For the header line only - what is downloaded is the newest release.
$MOD_VERSION = $PINNED_VER
$PINNED_URL  = "https://github.com/Tensai30/ShenmueVR-Downloads/releases/download/v2.0/ShenmueVR-Setup-2.0.exe"

$GAME_APPID  = "758330"
$GAME_LAUNCH = "SteamLauncher.exe"
$SM1_EXE     = "sm1\Shenmue.exe"
$SM2_EXE     = "sm2\Shenmue2.exe"

# How the mod is detected as installed. Either one is enough - in the
# setup the user may well pick only ONE of the games.
# ShenmueVR.ini ON PURPOSE, not a runtime library: since v1.3 the user
# installed it. The adapter called openvr_api.dll belongs to the
# publisher's OpenXR package and must not be mistaken for an OpenVR choice.
$MOD_MARK_1  = "sm1\ShenmueVR.ini"
$MOD_MARK_2  = "sm2\ShenmueVR.ini"

function Test-ShenmueV2Payload {
    param([string]$GamePath, [string]$GameFolder)
    if ([string]::IsNullOrWhiteSpace($GamePath) -or $GameFolder -notin @('sm1','sm2')) { return $false }
    foreach ($relative in @('ShenmueVR.ini','openvr_api.dll','ShenmueVRHands.dll','ShenmueVRInput\actions.json')) {
        if (-not (Test-Path -LiteralPath (Join-Path (Join-Path $GamePath $GameFolder) $relative) -PathType Leaf)) { return $false }
    }
    return $true
}

function Test-ShenmuePinnedFallbackSafe {
    param([string]$GamePath, [string]$InstallerPath, [string]$PinnedVersion)
    $pin = $null
    if (-not [version]::TryParse($PinnedVersion.TrimStart('v','V'), [ref]$pin)) { return $false }
    foreach ($marker in @((Join-Path $GamePath '.pcvrhub_version'), (Join-Path $InstallerPath '.installed_version'))) {
        if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { continue }
        $saved = [string](Get-Content -LiteralPath $marker -TotalCount 1 -ErrorAction SilentlyContinue)
        $saved = $saved.Trim()
        $installed = $null
        if ([version]::TryParse($saved.TrimStart('v','V'), [ref]$installed) -and $installed -gt $pin) { return $false }
    }
    return $true
}

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

# Fetch the newest stable Setup from the publisher GitHub releases. Match
# both tag and filename so a stale attachment cannot inherit a new version.
function Get-ShenmueSetupUrl {
    param([object]$Releases=$null)
    if ($null -eq $Releases) {
        try {
            $Releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$MOD_REPO/releases?per_page=15" `
                -Headers @{ 'User-Agent'='PCVR-Mods-Hub' } -TimeoutSec 20 -ErrorAction Stop
        } catch { return $null }
    }
    foreach ($r in @($Releases)) {
        if ($r.draft -or $r.prerelease -or [string]$r.tag_name -notmatch '(?i)^v?([0-9]+(?:\.[0-9]+){1,3})$') { continue }
        $version = $Matches[1]
        foreach ($a in @($r.assets)) {
            $name = [string]$a.name
            $url = [string]$a.browser_download_url
            if ($name -notmatch '(?i)^ShenmueVR-Setup-([0-9]+(?:\.[0-9]+){1,3})\.exe$' -or $Matches[1] -ne $version) { continue }
            if ($url -notmatch '(?i)^https://github\.com/Tensai30/ShenmueVR-Downloads/releases/download/[^/]+/ShenmueVR-Setup-([0-9]+(?:\.[0-9]+){1,3})\.exe$' -or $Matches[1] -ne $version) { continue }
            return @{ Url=$url; Name=$name; Tag=[string]$r.tag_name }
        }
        # A newer release without its matching Setup must stop the installer.
        # Never walk down to an older asset and stamp that as current.
        return @{ Unsupported=$true; Tag=[string]$r.tag_name }
    }
    return $null
}

Clear-Host
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Shenmue I & II VR Mod Installer" -ForegroundColor Cyan
Write-Host " Installs: $MOD_NAME $MOD_VERSION by $MOD_AUTHOR" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host " Stereoscopic VR and a first-person view for the Steam release" -ForegroundColor White
Write-Host " of Shenmue I & II." -ForegroundColor White
Write-Host ""
Write-Host " OpenXR and motion controls are enabled automatically in v2.0." -ForegroundColor White
Write-Host " Tracked hands, fighting gestures and physical turning are included." -ForegroundColor White
Write-Host ""
Write-Host " v2.0 has its own interpolation up to 120 FPS. Start with external" -ForegroundColor White
Write-Host " ASW / SSW / Motion Smoothing disabled." -ForegroundColor White
Write-Host ""
Write-Host " IMPORTANT: Setup removes other mods from the Shenmue I and/or II" -ForegroundColor Yellow
Write-Host " folders that you select. It does not create a backup. Back up" -ForegroundColor Yellow
Write-Host " your game folder before continuing if you want to preserve them." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to start..."

# -------------------------------------------------------
Write-Step 1 3 "Locating Shenmue I & II"
# -------------------------------------------------------
$gamePath = Find-SteamGameFolder -AppId $GAME_APPID `
                -SteamFolderNames @("Shenmue I & II", "SMLaunch") `
                -ProbeExe $GAME_LAUNCH
if (-not $gamePath) {
    $probe = @(
        "C:\Program Files (x86)\Steam\steamapps\common\Shenmue I & II"
    )
    foreach ($p in $probe) { if (Test-Path (Join-Path $p $SM1_EXE)) { $gamePath = $p; break } }
}
if (-not $gamePath) {
    Write-Fail "Could not find the Shenmue I & II folder automatically."
    $fb = Invoke-InstallerFallback -Action "locate Shenmue I & II" `
            -Subject "the game folder" `
            -Instructions "Open Steam, right-click Shenmue I & II, Manage - Browse local files. That folder holds SteamLauncher.exe with sm1\ and sm2\ next to it. Then choose Retry." `
            -AllowSkip $false
    if ([string]$fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
    $gamePath = Find-SteamGameFolder -AppId $GAME_APPID -SteamFolderNames @("Shenmue I & II") -ProbeExe $GAME_LAUNCH
    if (-not $gamePath) { Write-Fail "Still not found - cannot continue."; Pause-User "Press Enter to exit..."; exit 1 }
}
Write-OK "Game folder: $gamePath"
$has1 = Test-Path -LiteralPath (Join-Path $gamePath $SM1_EXE)
$has2 = Test-Path -LiteralPath (Join-Path $gamePath $SM2_EXE)
Write-Info ("Shenmue I: " + $(if ($has1) { "found" } else { "NOT found" }) + "   Shenmue II: " + $(if ($has2) { "found" } else { "NOT found" }))
if (-not ($has1 -or $has2)) {
    Write-Fail "Neither sm1\Shenmue.exe nor sm2\Shenmue2.exe is in that folder."
    Pause-User "Press Enter to exit..."; exit 1
}

# -------------------------------------------------------
Write-Step 2 3 "Downloading the mod setup"
# -------------------------------------------------------
$rel = Get-ShenmueSetupUrl
if ($rel -and $rel.Unsupported) {
    Write-Fail "The newest publisher release $($rel.Tag) has no matching Setup EXE."
    Write-Info "Check the release page; an older Setup will not be installed in its place."
    Pause-User "Press Enter to exit..."; exit 1
}
if (-not $rel -and -not (Test-ShenmuePinnedFallbackSafe -GamePath $gamePath -InstallerPath $PSScriptRoot -PinnedVersion $PINNED_VER)) {
    Write-Fail "Cannot check the current release. Your installed version is newer than the reviewed fallback $PINNED_VER."
    Write-Info "Retry when GitHub is available so an older Setup is not installed over it."
    Pause-User "Press Enter to exit..."; exit 1
}
$setupUrl  = if ($rel) { $rel.Url }  else { $PINNED_URL }
$setupName = if ($rel) { $rel.Name } else { "ShenmueVR-Setup-2.0.exe" }
if ($rel) { Write-Info "Newest stable release on GitHub: $($rel.Tag)" }
else      { Write-Info "GitHub release lookup unavailable - using the pinned $PINNED_VER build." }

$setupPath = Join-Path $env:TEMP $setupName
$downloadInfo = @{}
$ok = Invoke-SafeDownload -Urls @($setupUrl) -Destination $setupPath `
        -Label "$MOD_NAME setup" -ManualUrl $RELEASES -AllowSkip $false -DownloadInfo $downloadInfo
if (-not (Test-Path -LiteralPath $setupPath) -or
    -not (($ok -eq $true -and [string]$downloadInfo.Url -eq [string]$setupUrl) -or
          ([string]$ok -eq 'retry' -and $downloadInfo.SourcePath -and
           [IO.Path]::GetFileName([string]$downloadInfo.SourcePath) -eq $setupName))) {
    Write-Fail "The setup was not downloaded."
    Pause-User "Press Enter to exit..."; exit 1
}
Write-OK "Downloaded: $setupName"

# -------------------------------------------------------
Write-Step 3 3 "Running the mod's own setup"
# -------------------------------------------------------
$clip = $false
try { Set-Clipboard -Value $gamePath; $clip = $true } catch {}
Write-Host ""
Write-Host "  In the publisher Setup:" -ForegroundColor White
Write-Host ""
Write-Host "   1) The setup looks for your Shenmue folder." -ForegroundColor White
Write-Host "      Usually it is found and set already." -ForegroundColor White
if ($clip) {
    Write-Host "      If not, it is also on your clipboard - paste with " -NoNewline -ForegroundColor White
    Write-Host " Ctrl+V " -ForegroundColor Black -BackgroundColor Yellow
}
Write-Host "      $gamePath " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "   2) Which games to patch. Pick what you own:" -ForegroundColor White
Write-Host ("      Shenmue I  " + $(if ($has1) { "- present" } else { "- NOT in this folder, leave unticked" })) -ForegroundColor Gray
Write-Host ("      Shenmue II " + $(if ($has2) { "- present" } else { "- NOT in this folder, leave unticked" })) -ForegroundColor Gray
Write-Host ""
Write-Host "  Windows may warn about an unknown publisher. That is expected for" -ForegroundColor DarkGray
Write-Host "  an unsigned fan tool; the author has reported it to Microsoft." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Setup removes other mods in the selected sm1/sm2 folders." -ForegroundColor Yellow
Write-Host "  It does not create an automatic backup. Back up your game folder" -ForegroundColor Yellow
Write-Host "  yourself before proceeding; older backups cannot restore removed mods." -ForegroundColor Yellow
Write-Host ""
do { $backupAnswer = (Read-Host '  Have you backed up what you want to keep? [Y/N]').Trim().ToUpperInvariant() } while ($backupAnswer -notin @('Y','N'))
if ($backupAnswer -ne 'Y') { Write-Warn 'Setup not started. Your game folder was not changed by the Hub.'; Pause-User 'Press Enter to exit...'; exit 1 }
Pause-User "Press Enter to launch the setup - UAC required..."

try {
    $setupProcess = Start-Process -FilePath $setupPath -Wait -PassThru -ErrorAction Stop
    if (-not $setupProcess -or $setupProcess.ExitCode -ne 0) {
        throw "Publisher setup exited with code $($setupProcess.ExitCode)."
    }
} catch {
    Write-Fail "The publisher setup did not complete: $($_.Exception.Message)"
    Write-Host "  Run it by hand if needed, then run this Hub installer again to verify it." -ForegroundColor Yellow
    Pause-User "Press Enter to exit..."
    exit 1
}

# ---- Verify by the RESULT, not by the setup's exit code --------
$m1 = Test-ShenmueV2Payload -GamePath $gamePath -GameFolder 'sm1'
$m2 = Test-ShenmueV2Payload -GamePath $gamePath -GameFolder 'sm2'
Write-Host ""
if ($m1 -or $m2) {
    $which = @()
    if ($m1) { $which += "Shenmue I" }
    if ($m2) { $which += "Shenmue II" }
    Write-OK ("VR mod verified in the game folder for: " + ($which -join " and "))
    try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
    $shenmueInstalledVersion = if ($rel -and $rel.Tag) { $rel.Tag } else { $PINNED_VER }
    if (Test-IsTrackableInstalledVersion -Version $shenmueInstalledVersion) {
        try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $shenmueInstalledVersion -Encoding UTF8 -Force } catch {}
    }
    # ALSO write the durable stamp next to the GAME (2026-08-20).
    # The line above lands inside the Hub folder and is gone as
    # soon as a new Hub build is dropped in; the scan then finds
    # no marker and seeds the CURRENT online tag, swallowing a
    # pending update. The game-side stamp survives that.
    Save-InstalledStamp -GameDir $gamePath -Version $shenmueInstalledVersion
} else {
    Write-Warn "The selected game's complete ShenmueVR 2.0 payload was not found."
    Write-Host "  Checked: $gamePath" -ForegroundColor Gray
    Write-Host "  If you cancelled the setup, run this installer again. If the" -ForegroundColor White
    Write-Host "  setup refused your game, it needs the Steam release, version" -ForegroundColor White
    Write-Host "  1.07 - it will not touch an executable it does not recognise." -ForegroundColor White
    Pause-User "Press Enter to exit..."
    exit 1
}

Write-Host ""
Write-Line
Write-Host " HOW TO START - the order matters" -ForegroundColor Cyan
Write-Line
Write-Host "  1. Connect the headset to the desktop." -ForegroundColor White
Write-Host "  2. Start Link / Air Link / Virtual Desktop / SteamVR." -ForegroundColor White
Write-Host "  3. Start with external ASW / SSW / Motion Smoothing OFF." -ForegroundColor White
Write-Host "  4. Launch Shenmue I or II as usual." -ForegroundColor White
Write-Host "  5. Once it is in VR, " -NoNewline -ForegroundColor White
Write-Host " click the game window on the desktop once " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     so it has input focus - otherwise the controller does nothing." -ForegroundColor White
Write-Host "  6. Put the headset back on and play with tracked hands." -ForegroundColor White
Write-Host ""
Write-Host " Holding the LEFT TRIGGER brings the game's own camera back for the" -ForegroundColor Gray
Write-Host " zoom and search functions; releasing it returns to first person." -ForegroundColor Gray
Write-Host ""
Write-Host " The sailors are a lie. The forklift is real." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
