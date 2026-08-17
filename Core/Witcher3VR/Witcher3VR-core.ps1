# ============================================================
# The Witcher 3 VR - Installer (Witcher3VR by tig3rmast3r)
# ============================================================
# Native VR for the DirectX 12 build of The Witcher 3: Wild Hunt
# (Next-Gen, Patch 4.04). Stereo rendering, 6DoF head look,
# crossbow HMD aiming, resizable HUD, optional first-person
# exploration view. Gamepad or mouse+keyboard - the mod has no
# motion-controller support and none is planned.
#
# The package is a flat merge into the GAME ROOT:
#   bin\x64_dx12\dxgi.dll                 <- the hook
#   bin\x64_dx12\openxr_loader.dll
#   bin\x64_dx12\Witcher3VRLauncher.exe   <- what the user starts
#   mods\modWitcher3VRStateBridge\...     <- game script mod
#   Witcher3VR\...                        <- docs + example ini
#
# DX12 ONLY: everything lives in the x64_dx12 branch, so the game
# has to be started as DirectX 12. The launcher itself is the
# launch route, which is why .launch_exe points at it.
#
# DX12 PROFILE PREREQUISITE: the launcher's "Configure Settings for
# VR" button edits the game's own DirectX 12 profile,
#   <Documents>\The Witcher 3\dx12user.settings
# THE GAME writes that file on its first DirectX 12 start - the mod
# never creates it. On a fresh install (or on a copy that was only ever
# started as DirectX 11) it is missing and every button in the launcher
# ends with "Could not open: ...\dx12user.settings", which looks like a
# broken mod install but is not. The installer therefore PROBES for the
# file and, when it is missing, says so as the first thing on the end
# screen. Documents can be redirected (OneDrive), so the path comes from
# [Environment]::GetFolderPath('MyDocuments'), never from
# %USERPROFILE%\Documents.
#
# Update badge: the repo publishes PRERELEASES only - verified,
# github.com/<repo>/releases/latest redirects to the releases
# overview instead of a tag. The catalog entry therefore carries
# GithubPrerelease = $true so the Hub reads the API instead of the
# web redirect, and this installer writes .installed_version
# VERBATIM from tag_name.
# ============================================================

. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "The Witcher 3 VR Installer"
$ErrorActionPreference = "Stop"

$STEAM_APPID       = "292030"
$GAME_STEAM_FOLDER = "The Witcher 3"
$REL_GAME_EXE      = "bin\x64_dx12\witcher3.exe"
$REL_MOD_FILE      = "bin\x64_dx12\dxgi.dll"
$REL_LAUNCHER      = "bin\x64_dx12\Witcher3VRLauncher.exe"
$GITHUB_REPO       = "tig3rmast3r/witcher3-vr"
$GITHUB_API_LIST   = "https://api.github.com/repos/$GITHUB_REPO/releases?per_page=1"
$GITHUB_RELEASES   = "https://github.com/$GITHUB_REPO/releases"
# Rueckfall NUR ohne Netz. 2026-08-13 von v0.9.0-alpha.1 auf v0.9.4
# gezogen - VIER Fassungen Rueckstand. Der Normalweg loest die
# neueste Vorabversion ohnehin live auf (das Repo hat NUR
# Prereleases, /releases/latest laeuft deshalb ins Leere).
$PINNED_TAG        = "v0.9.4"
$PINNED_URL        = "https://github.com/$GITHUB_REPO/releases/download/v0.9.4/Witcher3VR-v0.9.4-V1117.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " The Witcher 3 VR - Installer" -ForegroundColor Cyan
    Write-Host " Witcher3VR by tig3rmast3r | DirectX 12 build, Patch 4.04" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($text) Write-Host " [OK] $text"  -ForegroundColor Green }
function Write-Info { param($text) Write-Host " [..] $text"  -ForegroundColor Gray }
function Write-Warn { param($text) Write-Host " [!]  $text"  -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host " [X]  $text"  -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

# A Witcher 3 root is any folder holding bin\x64_dx12\witcher3.exe.
# That path exists in the Steam, Steam GOTY, GOG and Epic builds
# alike, so one probe covers every store.
function Test-W3Root {
    param([string]$Root)
    if (-not $Root) { return $false }
    try { return (Test-Path -LiteralPath ([System.IO.Path]::Combine($Root, $REL_GAME_EXE))) } catch { return $false }
}

# Where the game keeps its render profiles. Documents may be redirected
# to OneDrive, so ask Windows for the folder instead of assembling it.
function Get-W3ProfileState {
    $docs = $null
    try { $docs = [Environment]::GetFolderPath('MyDocuments') } catch {}
    if (-not $docs) { $docs = [System.IO.Path]::Combine($env:USERPROFILE, "Documents") }
    $dir = [System.IO.Path]::Combine($docs, "The Witcher 3")
    return [pscustomobject]@{
        Dx12Path = [System.IO.Path]::Combine($dir, "dx12user.settings")
        HasDx12  = (Test-Path -LiteralPath ([System.IO.Path]::Combine($dir, "dx12user.settings")))
        HasDx11  = (Test-Path -LiteralPath ([System.IO.Path]::Combine($dir, "user.settings")))
    }
}

Write-Header

Write-Host " Witcher3VR brings native stereo VR to the DirectX 12 build of" -ForegroundColor White
Write-Host " The Witcher 3, with 6DoF head look and crossbow HMD aiming." -ForegroundColor White
Write-Host " You play with a gamepad or mouse+keyboard - motion controllers" -ForegroundColor White
Write-Host " are not supported by the mod." -ForegroundColor White
Write-Host ""
Write-Host " Needs the Next-Gen version at Patch 4.04 or newer." -ForegroundColor Yellow
Write-Host " Alpha refers to validation - tested on few headsets so far." -ForegroundColor Yellow
Write-Host ""
Write-Host " The game must have been started as DirectX 12 at least once." -ForegroundColor Yellow
Write-Host " That first start creates the profile the VR launcher edits." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to start..." | Out-Null

# -------------------------------------------------------
# STEP 1: Locate the game (any store)
# -------------------------------------------------------
Write-Step 1 4 "Locating The Witcher 3"

$gamePath = $null

if (Get-Command Try-FindSteamGame -ErrorAction SilentlyContinue) {
    $gamePath = Try-FindSteamGame -Folder $GAME_STEAM_FOLDER -Title "The Witcher 3" -AppID $STEAM_APPID -ExeName $REL_GAME_EXE
}
if (-not $gamePath -and (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue)) {
    $gamePath = Find-SteamGameFolder -AppId $STEAM_APPID `
        -SteamFolderNames @("The Witcher 3", "The Witcher 3 Game of the Year Edition") `
        -ProbeExe $REL_GAME_EXE `
        -EpicNames @("TheWitcher3", "The Witcher 3")
}
# GOG / Epic / second-drive defaults. [IO.Path]::Combine plus a
# guarded Test-Path - never Join-Path over a drive that may not
# exist, it throws.
if (-not $gamePath) {
    $candidates = @()
    foreach ($d in @("C:", "D:", "E:")) {
        $candidates += "$d\GOG Games\The Witcher 3 Wild Hunt"
        $candidates += "$d\GOG Games\The Witcher 3 Wild Hunt GOTY"
        $candidates += "$d\Program Files\Epic Games\TheWitcher3"
        $candidates += "$d\Program Files (x86)\Epic Games\TheWitcher3"
    }
    foreach ($cand in $candidates) {
        if (Test-W3Root -Root $cand) { $gamePath = $cand; break }
    }
}
# Previously recorded install
if (-not $gamePath) {
    $rec = $null
    try { $rec = Get-Content -LiteralPath (Join-Path $PSScriptRoot ".installed_path") -ErrorAction Stop | Select-Object -First 1 } catch {}
    if ($rec) { $rec = $rec.Trim() }
    if (Test-W3Root -Root $rec) { $gamePath = $rec }
}
# Manual fallback (typed or drag & dropped folder)
while (-not $gamePath) {
    Write-Warn "Could not find the game automatically."
    Write-Host " Drag & drop your Witcher 3 GAME FOLDER onto this window - the" -ForegroundColor White
    Write-Host " one that contains the 'bin' folder - then press Enter." -ForegroundColor White
    Write-Host " Or press Enter on an empty line to exit." -ForegroundColor Gray
    $raw = (Read-Host " Game folder").Trim().Trim('"')
    if (-not $raw) { Write-Fail "No game folder - cannot continue."; Pause-User "Press Enter to exit." | Out-Null; exit 1 }
    if (Test-W3Root -Root $raw) { $gamePath = $raw }
    else { Write-Fail "That folder has no $REL_GAME_EXE inside." }
}
Write-OK "Found: $gamePath"
$null = Show-UpdateNoticeIfInstalled -TargetDir $gamePath -RelModFile $REL_MOD_FILE -Label "Witcher3VR"

# -------------------------------------------------------
# STEP 2: Get the release
# -------------------------------------------------------
Write-Step 2 4 "Getting the latest Witcher3VR release"

$dlUrl  = $null
$relTag = $null
# Prereleases only in this repo, so /releases/latest is useless here -
# the list endpoint returns the newest release of any kind first.
try {
    $resp = Invoke-RestMethod -Uri $GITHUB_API_LIST -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 8 -ErrorAction Stop
    $rel  = @($resp) | Select-Object -First 1
    if ($rel) {
        $relTag = [string]$rel.tag_name
        # The release also carries a -SHA256.txt next to the zip; take the zip.
        $asset = $rel.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
        if ($asset) { $dlUrl = [string]$asset.browser_download_url }
    }
    if ($relTag) { Write-Info "Latest release: $relTag" }
} catch {
    Write-Warn "GitHub could not be reached ($($_.Exception.Message))."
}
if (-not $dlUrl) {
    Write-Warn "Falling back to the pinned $PINNED_TAG build."
    $dlUrl  = $PINNED_URL
    $relTag = $PINNED_TAG
}

$zipPath = Join-Path $env:TEMP ("W3VR_" + [System.IO.Path]::GetRandomFileName() + ".zip")
if (-not (Invoke-DownloadOrFallback -Url $dlUrl -Destination $zipPath -Label "Witcher3VR" `
        -ManualUrl $GITHUB_RELEASES `
        -Instructions "Download the Witcher3VR-...zip (NOT the -SHA256.txt) from the Releases page, drop it into your Downloads folder and retry.")) {
    $manualZip = Get-ChildItem -Path (Join-Path $env:USERPROFILE "Downloads") -Filter "Witcher3VR*.zip" -ErrorAction SilentlyContinue |
                 Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($manualZip) {
        Write-OK "Found a manual download: $($manualZip.Name)"
        $zipPath = $manualZip.FullName
    } else {
        Write-Fail "No Witcher3VR package available - cannot continue."
        Pause-User "Press Enter to exit." | Out-Null; exit 1
    }
}

# -------------------------------------------------------
# STEP 3: Install into the game folder
# -------------------------------------------------------
Write-Step 3 4 "Installing into the game folder"

# The zip mirrors the game's own layout (bin\x64_dx12, mods,
# Witcher3VR), so it merges straight into the game root. Payload-
# verified extract: temp-extract, resolve the real payload root via
# the known mod file, merge, then verify dxgi.dll arrived.
$exRes = Expand-ArchiveToTarget -ArchivePath $zipPath -TargetDir $gamePath -RelModFile $REL_MOD_FILE -Label "Witcher3VR"
if (-not $exRes) {
    Write-Fail "Extraction failed."
    Pause-User "Press Enter to exit." | Out-Null; exit 1
}
if (Test-Path -LiteralPath ([System.IO.Path]::Combine($gamePath, $REL_MOD_FILE))) {
    Write-OK "Mod files in place ($REL_MOD_FILE)."
} else {
    Write-Fail "$REL_MOD_FILE missing after extraction - the package layout may have changed."
    Pause-User "Press Enter to exit." | Out-Null; exit 1
}
$launcherFull = [System.IO.Path]::Combine($gamePath, $REL_LAUNCHER)
if (Test-Path -LiteralPath $launcherFull) {
    Write-OK "Launcher in place (Witcher3VRLauncher.exe)."
} else {
    Write-Warn "Witcher3VRLauncher.exe not found - check the extracted files."
}
if ($zipPath -like (Join-Path $env:TEMP "*")) { try { Remove-Item -LiteralPath $zipPath -Force } catch {} }

# -------------------------------------------------------
# STEP 4: Hub markers + desktop shortcut
# -------------------------------------------------------
Write-Step 4 4 "Finishing setup"

try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
try { if ($relTag) { Set-Content -Path (Join-Path $PSScriptRoot ".installed_version") -Value $relTag -Encoding UTF8 -Force } } catch {}
if (Test-Path -LiteralPath $launcherFull) {
    try { Set-Content -Path (Join-Path $PSScriptRoot ".launch_exe") -Value $launcherFull -Encoding UTF8 -Force } catch {}
    # Witcher3VRLauncher.exe carries no icon resource, so the shortcut
    # would sit on the desktop as a blank default sheet. We ship our own
    # Witcher3_VR.ico (16/32/48/64) and copy it into the game folder, so
    # the shortcut keeps a stable icon path even if the Hub is moved -
    # same approach as Forza Horizon 5/6, BotW and Total Chaos.
    # Fallback chain: our icon -> the GAME exe next to the launcher in
    # bin\x64_dx12 -> the launcher itself. ",0" picks the first icon
    # resource of an exe, the hub-wide pattern.
    $iconArg = "$launcherFull,0"
    $gameExeFull = [System.IO.Path]::Combine($gamePath, $REL_GAME_EXE)
    if (Test-Path -LiteralPath $gameExeFull) { $iconArg = "$gameExeFull,0" }
    $iconDest = [System.IO.Path]::Combine($gamePath, "Witcher3_VR.ico")
    try {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot "Witcher3_VR.ico") -Destination $iconDest -Force -ErrorAction Stop
        if (Test-Path -LiteralPath $iconDest) { $iconArg = $iconDest }
    } catch {}
    try {
        [void](New-DesktopShortcut -ShortcutName "The Witcher 3 VR" `
            -TargetPath $launcherFull `
            -WorkingDir ([System.IO.Path]::GetDirectoryName($launcherFull)) `
            -IconPath $iconArg `
            -Description "Launch The Witcher 3 in VR (Witcher3VR launcher)")
        Write-OK "Desktop shortcut created: The Witcher 3 VR"
    } catch {}
}

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  The Witcher 3 VR is installed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
$w3prof = Get-W3ProfileState
if ($w3prof.HasDx12) {
    Write-OK "DirectX 12 profile found - the launcher can configure it."
    Write-Host ""
} else {
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "  |           DO THIS FIRST - START THE GAME ONCE            |" -ForegroundColor Yellow
    Write-Host "  +==========================================================+" -ForegroundColor Yellow
    Write-Host "   Your DirectX 12 profile does not exist yet:" -ForegroundColor White
    Write-Host "     $($w3prof.Dx12Path)" -ForegroundColor Gray
    if ($w3prof.HasDx11) {
        Write-Host "   Only the DirectX 11 profile is there - a DirectX 11 start" -ForegroundColor White
        Write-Host "   does not create the DirectX 12 one." -ForegroundColor White
    }
    Write-Host "   THE GAME writes this file, not the mod. Start The Witcher 3" -ForegroundColor White
    Write-Host "   normally, pick " -NoNewline -ForegroundColor White
    Write-Host " DirectX 12 " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " , wait for the main menu, then quit." -ForegroundColor White
    Write-Host "   Until then every button in the VR launcher answers" -ForegroundColor White
    Write-Host "   " -NoNewline -ForegroundColor White
    Write-Host " Could not open: ...\dx12user.settings " -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ""
}
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "  |            REQUIRED IN-GAME SETTINGS                     |" -ForegroundColor Yellow
Write-Host "  +==========================================================+" -ForegroundColor Yellow
Write-Host "   The launcher's " -NoNewline -ForegroundColor White
Write-Host " Configure Settings for VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
Write-Host " button applies" -ForegroundColor White
Write-Host "   all of these for you and backs up your profile first." -ForegroundColor White
Write-Host "   It rewrites the whole profile, so check your game language" -ForegroundColor White
Write-Host "   afterwards - this game's page in the Hub says how to set it back." -ForegroundColor White
Write-Host "   By hand it is:" -ForegroundColor White
Write-Host "     Ray tracing              " -NoNewline -ForegroundColor White
Write-Host " Off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     Screen Space Reflections " -NoNewline -ForegroundColor White
Write-Host " Off or Low " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     Motion blur              " -NoNewline -ForegroundColor White
Write-Host " Off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     VSync                    " -NoNewline -ForegroundColor White
Write-Host " Off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     Maximum FPS              " -NoNewline -ForegroundColor White
Write-Host " Unlimited " -ForegroundColor Black -BackgroundColor Yellow
Write-Host "     NVIDIA Reflex            " -NoNewline -ForegroundColor White
Write-Host " Off " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "   Windows HDR must be OFF too - with it on the headset shows a" -ForegroundColor White
Write-Host "   black screen. The game has no HDR toggle of its own:" -ForegroundColor White
Write-Host "   Windows Settings > System > Display > " -NoNewline -ForegroundColor White
Write-Host " HDR " -ForegroundColor Black -BackgroundColor Yellow
Write-Host ""
Write-Host "  Start with" -NoNewline -ForegroundColor White; Write-Host " Start in VR " -NoNewline -ForegroundColor Black -BackgroundColor Yellow; Write-Host "in the Hub, or the 'The Witcher 3 VR'" -ForegroundColor White
Write-Host "  desktop shortcut - both open the mod's launcher, where you pick" -ForegroundColor White
Write-Host "  the rendering mode and resolution, then start the game." -ForegroundColor White
Write-Host ""
Write-Host "  In-game: F9 recenters, F8 switches Standard/Near view, F10 is" -ForegroundColor Gray
Write-Host "  2D cinema, F11 the experimental first-person view. See this" -ForegroundColor Gray
Write-Host "  game's page in the Hub for the full layout." -ForegroundColor Gray
Write-Host ""
Write-Host "  Toss a coin to your Witcher - and stand in Velen yourself." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to close." | Out-Null
