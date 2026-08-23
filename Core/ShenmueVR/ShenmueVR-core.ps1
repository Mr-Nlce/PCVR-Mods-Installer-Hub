# -------------------------------------------------------
# Shenmue I & II VR Mod Installer
# Shenmue_1_and_2_VR_mod by Tensai37 - hosted on CODEBERG
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
# WHAT THE SETUP CREATES, from a real before/after comparison of the
# game folder made on v1.1 - EXACTLY TEN files, nothing is removed and
# no existing file changes size.
#
# !!! v1.3 ADDS AN OpenVR / OpenXR CHOICE, so the runtime library
# !!! differs when OpenXR is picked (an OpenXR loader rather than
# openvr_api.dll). The list below has NOT been re-measured against 1.3.
# Detection therefore rests on ShenmueVR.ini, which is written either
# way - do not tighten the check onto openvr_api.dll.
#   sm1\XINPUT1_3.dll            412,672   (proxy DLL, loads the mod)
#   sm1\openvr_api.dll           837,272
#   sm1\ShenmueVR.ini                504   (the mod's settings)
#   sm2\XINPUT1_3.dll            436,224   (its own build per game!)
#   sm2\openvr_api.dll           837,272
#   sm2\ShenmueVR.ini                707
#   sm1\.ShenmueVR-installer-backup\Shenmue.exe.preinstall + state.ini
#   sm2\.ShenmueVR-installer-backup\Shenmue2.exe.preinstall + state.ini
#
# THE GAME EXE IS PATCHED IN PLACE, WITHOUT A SIZE CHANGE:
# Shenmue.exe is 11,651,072 bytes before and after - exactly like the
# .preinstall backup next to it. A size comparison is therefore NO
# use for detection here; only the new files reveal the install. The
# setup refuses unknown exe versions and requires Steam 1.07.
#
# FOLDER STRUCTURE: the author's instructions speak of a folder
# "SMLaunch" - that does NOT exist in a real install. The root holds
# SteamLauncher.exe, sm1\ and sm2\. That is what is searched for.
# -------------------------------------------------------

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Shenmue I & II VR Installer"

$MOD_NAME    = "ShenmueVR"
$MOD_AUTHOR  = "Tensai37"
$MOD_REPO    = "Tensai37/Shenmue_1_and_2_VR_mod"
$RELEASES    = "https://codeberg.org/$MOD_REPO/releases"

# Pinned build - the FALLBACK only. The address is resolved at run
# time from the newest Codeberg release (Get-ShenmueSetupUrl). Keep it
# current anyway: without network access something old would be
# downloaded forever.
$PINNED_VER  = "v1.3"
# For the header line only - what is downloaded is the newest release.
$MOD_VERSION = $PINNED_VER
$PINNED_URL  = "https://codeberg.org/$MOD_REPO/releases/download/$PINNED_VER/ShenmueVR-Setup-1.3.exe"

$GAME_APPID  = "758330"
$GAME_LAUNCH = "SteamLauncher.exe"
$SM1_EXE     = "sm1\Shenmue.exe"
$SM2_EXE     = "sm2\Shenmue2.exe"

# How the mod is detected as installed. Either one is enough - in the
# setup the user may well pick only ONE of the games.
# ShenmueVR.ini ON PURPOSE, not a runtime library: since v1.3 the user
# chooses OpenVR or OpenXR during setup, so what lands next to it
# differs. The ini is written either way.
$MOD_MARK_1  = "sm1\ShenmueVR.ini"
$MOD_MARK_2  = "sm2\ShenmueVR.ini"

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

# Fetch the newest setup from the Codeberg release. Codeberg runs on
# Forgejo; the API has the same shape as Gitea. The asset whose name
# ends in .exe is the one taken - not the version number, so a rename
# breaks nothing.
function Get-ShenmueSetupUrl {
    try {
        $rel = Invoke-RestMethod -Uri "https://codeberg.org/api/v1/repos/$MOD_REPO/releases?limit=5" `
                   -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20 -ErrorAction Stop
        foreach ($r in @($rel)) {
            if ($r.draft) { continue }
            foreach ($a in @($r.assets)) {
                if ($a.name -match '(?i)\.exe$') {
                    return @{ Url = [string]$a.browser_download_url; Name = [string]$a.name; Tag = [string]$r.tag_name }
                }
            }
        }
    } catch {}
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
Write-Host " A CONTROLLER IS REQUIRED. Since v1.3 your VR controllers work" -ForegroundColor White
Write-Host " too - but as a plain gamepad, with no motion tracking." -ForegroundColor White
Write-Host ""
Write-Host "  +==============================================================+" -ForegroundColor Yellow
Write-Host "  |  FRAME INTERPOLATION IS REQUIRED - 30 FPS IS THE BASELINE   |" -ForegroundColor Yellow
Write-Host "  +==============================================================+" -ForegroundColor Yellow
Write-Host "   Shenmue II stays at 30 throughout, and so does Shenmue I" -ForegroundColor White
Write-Host "   outside normal first-person play. A faster PC does not lift" -ForegroundColor White
Write-Host "   that cap. Turn on whichever your" -ForegroundColor White
Write-Host "   setup offers BEFORE you play:" -ForegroundColor White
Write-Host "     Quest over Link / Air Link  -> " -NoNewline -ForegroundColor Gray
Write-Host " Asynchronous Spacewarp (ASW) " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     Virtual Desktop             -> " -NoNewline -ForegroundColor Gray
Write-Host " Synchronous Spacewarp (SSW) " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     SteamVR headsets, PS VR2    -> " -NoNewline -ForegroundColor Gray
Write-Host " Motion Smoothing " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "   Without it the picture judders and the game can crash." -ForegroundColor White
Write-Host ""
# STILL REQUIRED IN v1.3 - the new boost does NOT replace it. The
# boost runs in normal first-person play only; cutscenes and
# third-person sequences stay at 30 FPS, and Shenmue II stays at 30
# throughout. Without saying so, "framerate boost" reads like the
# interpolation is no longer needed.
Write-Host "   v1.3 adds a framerate boost for Shenmue I, but you still need" -ForegroundColor White
Write-Host "   the above: it covers normal first-person play only. Cutscenes" -ForegroundColor White
Write-Host "   and third-person scenes stay at 30, and Shenmue II stays at 30" -ForegroundColor White
Write-Host "   throughout." -ForegroundColor White
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
        "C:\Program Files (x86)\Steam\steamapps\common\Shenmue I & II",
        "C:\XboxGames\Shenmue I & II\Content"
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
$setupUrl  = if ($rel) { $rel.Url }  else { $PINNED_URL }
$setupName = if ($rel) { $rel.Name } else { "ShenmueVR-Setup-1.3.exe" }
if ($rel) { Write-Info "Newest release on Codeberg: $($rel.Tag)" }
else      { Write-Info "Codeberg not reachable - using the pinned $PINNED_VER build." }

$setupPath = Join-Path $env:TEMP $setupName
$ok = Invoke-DownloadOrFallback -Url $setupUrl -Destination $setupPath `
        -Label "$MOD_NAME setup" -ManualUrl $RELEASES
if (-not $ok -or -not (Test-Path -LiteralPath $setupPath)) {
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
Write-Host "  The setup asks three things. Here is what to answer:" -ForegroundColor White
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
# THIRD QUESTION, NEW IN v1.3. It is not a matter of taste: the
# adaptive framerate boost for Shenmue I only exists on the OpenXR
# path. Picking OpenVR out of habit quietly gives that up, and nothing
# on screen would ever say so.
Write-Host "   3) OpenVR or OpenXR. " -NoNewline -ForegroundColor White
Write-Host " Pick OpenXR " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "      New in v1.3, and it is not just a runtime swap:" -ForegroundColor Gray
Write-Host "      the adaptive framerate boost for Shenmue I ONLY works" -ForegroundColor Gray
Write-Host "      on OpenXR. Choose OpenVR and you lose the boost" -ForegroundColor Gray
Write-Host "      without warning." -ForegroundColor Gray
Write-Host "      Choose OpenVR only if your headset gives you trouble" -ForegroundColor DarkGray
Write-Host "      with OpenXR." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Windows may warn about an unknown publisher. That is expected for" -ForegroundColor DarkGray
Write-Host "  an unsigned fan tool; the author has reported it to Microsoft." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  The setup makes its own backup of your game executables before" -ForegroundColor White
Write-Host "  patching them, in sm1\.ShenmueVR-installer-backup\ and the same" -ForegroundColor White
Write-Host "  under sm2. Leave those folders alone." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to launch the setup - UAC required..."

try {
    Start-Process -FilePath $setupPath -Wait -ErrorAction Stop
} catch {
    Write-Fail "Could not start the setup: $($_.Exception.Message)"
    Write-Host "  Run it by hand: $setupPath" -ForegroundColor Yellow
    Pause-User "Press Enter once you have finished the setup..."
}

# ---- Verify by the RESULT, not by the setup's exit code --------
$m1 = Test-Path -LiteralPath (Join-Path $gamePath $MOD_MARK_1)
$m2 = Test-Path -LiteralPath (Join-Path $gamePath $MOD_MARK_2)
Write-Host ""
if ($m1 -or $m2) {
    $which = @()
    if ($m1) { $which += "Shenmue I" }
    if ($m2) { $which += "Shenmue II" }
    Write-OK ("VR mod verified in the game folder for: " + ($which -join " and "))
    try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
    if ($rel) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $rel.Tag -Encoding UTF8 -Force } catch {} }
    # ALSO write the durable stamp next to the GAME (2026-08-20).
    # The line above lands inside the Hub folder and is gone as
    # soon as a new Hub build is dropped in; the scan then finds
    # no marker and seeds the CURRENT online tag, swallowing a
    # pending update. The game-side stamp survives that.
    Save-InstalledStamp -GameDir $gamePath -Version $rel
} else {
    Write-Warn "No ShenmueVR.ini found in sm1\ or sm2\ - the mod does not look installed."
    Write-Host "  Checked: $gamePath" -ForegroundColor Gray
    Write-Host "  If you cancelled the setup, run this installer again. If the" -ForegroundColor White
    Write-Host "  setup refused your game, it needs the Steam release, version" -ForegroundColor White
    Write-Host "  1.07 - it will not touch an executable it does not recognise." -ForegroundColor White
}

Write-Host ""
Write-Line
Write-Host " HOW TO START - the order matters" -ForegroundColor Cyan
Write-Line
Write-Host "  1. Connect the headset to the desktop." -ForegroundColor White
Write-Host "  2. Start Link / Air Link / Virtual Desktop / SteamVR." -ForegroundColor White
Write-Host "  3. Turn frame interpolation ON (ASW / SSW / Motion Smoothing)." -ForegroundColor White
Write-Host "  4. Launch Shenmue I or II as usual." -ForegroundColor White
Write-Host "  5. Once it is in VR, " -NoNewline -ForegroundColor White
Write-Host " click the game window on the desktop once " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     so it has input focus - otherwise the controller does nothing." -ForegroundColor White
Write-Host "  6. Put the headset back on and play with the controller." -ForegroundColor White
Write-Host ""
Write-Host " Holding the LEFT TRIGGER brings the game's own camera back for the" -ForegroundColor Gray
Write-Host " zoom and search functions; releasing it returns to first person." -ForegroundColor Gray
Write-Host ""
Write-Host " The sailors are a lie. The forklift is real." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
