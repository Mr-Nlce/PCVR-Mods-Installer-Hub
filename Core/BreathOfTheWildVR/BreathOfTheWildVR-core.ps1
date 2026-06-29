# ============================================================
#  Breath of the Wild VR (BetterVR) - assisted setup
#  Downloads Cemu 2.6 (verified) + the community graphic packs
#  + the BetterVR launcher into C:\Games\Breath of the Wild VR,
#  then walks you through the manual Cemu configuration.
#  You provide your own copy of BotW for the Wii U + your keys.
#  This installer ships no game files and no keys.
# ============================================================

$ErrorActionPreference = "Stop"

# Load installer-safety helpers (Invoke-SafeDownload, Expand-ArchiveOrFallback).
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

# ---- inline console helpers (each installer defines its own) ----
function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host "    Breath of the Wild VR  -  BetterVR assisted setup" -ForegroundColor White
    Write-Host "  ============================================================" -ForegroundColor Green
    Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "  --- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK   { param($text) Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host "  [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "  [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host "  [..] $text" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }
function Write-Box {
    param([string]$Heading, [string[]]$Lines, [string]$HeadColor="Yellow")
    Write-Host ""
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $HeadColor
    Write-Host ("  | " + $Heading.PadRight(56) + " |") -ForegroundColor $HeadColor
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $HeadColor
    foreach ($l in $Lines) { Write-Host "    $l" -ForegroundColor White }
    Write-Host ""
}

Write-Header

# ------------------------------------------------------------
# Intro - what this does + the prerequisite
# ------------------------------------------------------------
Write-Box -Heading "ABOUT THIS INSTALL - READ FIRST" -Lines @(
    "BetterVR adds a PC-VR mode to The Legend of Zelda: Breath",
    "of the Wild by hooking the Cemu Wii U emulator.",
    "",
    "This installer will:",
    "  - create C:\Games\Breath of the Wild VR",
    "  - download Cemu 2.6 (Windows, integrity-checked)",
    "  - pre-load the community graphic packs (incl. FPS++)",
    "  - download the BetterVR launcher next to Cemu.exe",
    "  - then guide you through the manual Cemu setup.",
    "",
    "YOU PROVIDE YOUR OWN copy of BotW for the Wii U plus your",
    "own Wii U keys. This installer ships NO game files and NO",
    "keys."
)
$go = (Read-Host "  Continue with the setup? (Y/N)").Trim()
if ($go -notmatch '^[Yy]') { Write-Info "Cancelled by user."; Pause-User "Press Enter to exit..."; exit 0 }

# ------------------------------------------------------------
# Pick a writable install root: C:\Games then D: then E:
# ------------------------------------------------------------
$installRoot = $null
foreach ($drive in @("C:", "D:", "E:")) {
    $gamesDir = Join-Path "$drive\" "Games"
    try {
        if (-not (Test-Path $gamesDir)) { New-Item -ItemType Directory -Path $gamesDir -Force | Out-Null }
        $probe = Join-Path $gamesDir ".pcvr_write_test"
        Set-Content -Path $probe -Value "x" -Encoding ASCII -Force
        Remove-Item $probe -Force
        $installRoot = Join-Path $gamesDir "Breath of the Wild VR"
        break
    } catch { continue }
}
if (-not $installRoot) {
    Write-Fail "Could not find a writable Games folder on C:, D: or E:."
    Write-Info "Create C:\Games yourself (writable), then run this installer again."
    Pause-User "Press Enter to exit..."
    exit 1
}
try { if (-not (Test-Path $installRoot)) { New-Item -ItemType Directory -Path $installRoot -Force | Out-Null } } catch {}
# 'portable' folder forces Cemu to keep its data here (Windows is non-portable by default now).
try { New-Item -ItemType Directory -Path (Join-Path $installRoot "portable") -Force | Out-Null } catch {}
Write-OK "Install folder: $installRoot"

$cemuExe = Join-Path $installRoot "Cemu.exe"

# ------------------------------------------------------------
# STEP 1: Download + verify + extract Cemu 2.6
# ------------------------------------------------------------
Write-Step 1 4 "Downloading the Cemu 2.6 emulator"

$CEMU_SHA256 = "a6bcc2bc42a362d10213819948f3152fae7d47f70067f25939b51d3ddcfb0896"
$cemuUrl     = "https://github.com/cemu-project/Cemu/releases/download/v2.6/cemu-2.6-windows-x64.zip"
$cemuZip     = Join-Path $installRoot "cemu-2.6-windows-x64.zip"

if (Test-Path $cemuExe) {
    Write-OK "Cemu.exe already present - skipping the Cemu download."
} else {
    Invoke-SafeDownload -Urls @($cemuUrl) -Destination $cemuZip -Label "Cemu 2.6 (Windows x64)" `
        -ManualUrl $cemuUrl `
        -Instructions "Download cemu-2.6-windows-x64.zip from the link, then place it at: $cemuZip" `
        -SkipMessage "Skipped Cemu download - you will have to add Cemu.exe to $installRoot yourself." | Out-Null

    if (Test-Path $cemuZip) {
        Write-Info "Verifying the download (SHA256)..."
        $ok = $false
        try {
            $h = (Get-FileHash -Path $cemuZip -Algorithm SHA256).Hash.ToLower()
            if ($h -eq $CEMU_SHA256) { $ok = $true; Write-OK "Integrity verified (SHA256 matches the known-good Cemu 2.6)." }
            else {
                Write-Warn "SHA256 MISMATCH - the downloaded file is NOT the expected Cemu 2.6!"
                Write-Host "       expected: $CEMU_SHA256" -ForegroundColor DarkGray
                Write-Host "       got:      $h" -ForegroundColor DarkGray
                $c = (Read-Host "  Continue anyway? (type YES to proceed)").Trim()
                if ($c -ceq "YES") { $ok = $true; Write-Warn "Continuing despite hash mismatch (your choice)." }
            }
        } catch { Write-Warn "Could not compute the hash: $($_.Exception.Message). Continuing without verification." ; $ok = $true }

        if (-not $ok) {
            Write-Fail "Stopped because the Cemu download failed integrity verification."
            try { Remove-Item $cemuZip -Force } catch {}
            Pause-User "Press Enter to exit..."
            exit 1
        }

        $tmp = Join-Path $installRoot "_cemu_tmp"
        try { if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force } } catch {}
        $ex = Expand-ArchiveOrFallback -ArchivePath $cemuZip -DestinationFolder $tmp -Label "Cemu 2.6" -AllowSkip $true
        if ([string]$ex -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }

        $cemuInner = Join-Path $tmp "Cemu_2.6"
        $srcRoot = if (Test-Path $cemuInner) { $cemuInner } else { $tmp }
        try {
            Get-ChildItem -Path $srcRoot -Force | ForEach-Object {
                $dest = Join-Path $installRoot $_.Name
                if (Test-Path $dest) { try { Remove-Item $dest -Recurse -Force } catch {} }
                Move-Item -Path $_.FullName -Destination $dest -Force
            }
            Write-OK "Cemu extracted into $installRoot"
        } catch { Write-Warn "Could not move all Cemu files: $($_.Exception.Message)" }
        try { Remove-Item $tmp -Recurse -Force } catch {}
        try { Remove-Item $cemuZip -Force } catch {}
        try { New-Item -ItemType Directory -Path (Join-Path $installRoot "portable") -Force | Out-Null } catch {}
    }
}

# ------------------------------------------------------------
# Pre-load the community graphic packs (so FPS++ is ready
# without the manual "Download Community Graphic Packs" click).
# Optional + non-fatal: Cemu's in-app downloader still works.
# ------------------------------------------------------------
$gpDir = Join-Path $installRoot "graphicPacks"
try { if (-not (Test-Path $gpDir)) { New-Item -ItemType Directory -Path $gpDir -Force | Out-Null } } catch {}
Write-Info "Pre-loading the community graphic packs (includes FPS++)..."
$gpUrls = New-Object System.Collections.Generic.List[string]
try {
    $gpRel = Invoke-RestMethod -Uri "https://api.github.com/repos/cemu-project/cemu_graphic_packs/releases/latest" `
            -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20
    $gpAsset = $gpRel.assets | Where-Object { $_.name -like "graphicPacks*.zip" } | Select-Object -First 1
    if (-not $gpAsset) { $gpAsset = $gpRel.assets | Select-Object -First 1 }
    if ($gpAsset -and $gpAsset.browser_download_url) { [void]$gpUrls.Add([string]$gpAsset.browser_download_url) }
} catch { Write-Info "Could not query the graphic-packs release - this step is optional." }

if ($gpUrls.Count -gt 0) {
    $gpZip = Join-Path $installRoot "_gp_tmp.zip"
    Invoke-SafeDownload -Urls $gpUrls -Destination $gpZip -Label "Cemu community graphic packs" `
        -ManualUrl "https://cemu-project.github.io/cemu_graphic_packs/" `
        -Instructions "Optional: download the graphic packs zip and extract its folders into: $gpDir" `
        -SkipMessage "Skipped - you can still click 'Download Community Graphic Packs' inside Cemu later." | Out-Null
    if (Test-Path $gpZip) {
        $gpTmp = Join-Path $installRoot "_gp_tmp"
        try { if (Test-Path $gpTmp) { Remove-Item $gpTmp -Recurse -Force } } catch {}
        $gpEx = Expand-ArchiveOrFallback -ArchivePath $gpZip -DestinationFolder $gpTmp -Label "graphic packs" -AllowSkip $true
        if ([string]$gpEx -ne "quit") {
            $gpSrc = $gpTmp
            $gpTopDirs = @(Get-ChildItem -Path $gpTmp -Directory -Force)
            $gpTopFiles = @(Get-ChildItem -Path $gpTmp -File -Force)
            if ($gpTopDirs.Count -eq 1 -and $gpTopFiles.Count -le 2) { $gpSrc = $gpTopDirs[0].FullName }
            try {
                Get-ChildItem -Path $gpSrc -Directory -Force | ForEach-Object {
                    $dest = Join-Path $gpDir $_.Name
                    if (Test-Path $dest) { try { Remove-Item $dest -Recurse -Force } catch {} }
                    Move-Item -Path $_.FullName -Destination $dest -Force
                }
                Write-OK "Community graphic packs pre-loaded (FPS++ is now available to enable)."
            } catch { Write-Warn "Could not place all graphic packs: $($_.Exception.Message)" }
        }
        try { Remove-Item $gpTmp -Recurse -Force } catch {}
        try { Remove-Item $gpZip -Force } catch {}
    }
} else {
    Write-Info "Skipping graphic-pack pre-load - use Cemu's 'Download Community Graphic Packs' button instead."
}

# ------------------------------------------------------------
# STEP 2: Download the BetterVR launcher next to Cemu.exe
# ------------------------------------------------------------
Write-Step 2 4 "Downloading the BetterVR launcher"

$launcherPath = Join-Path $installRoot "BetterVR_Launcher.exe"
$betterUrls = New-Object System.Collections.Generic.List[string]
try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/Crementif/BotW-BetterVR/releases/latest" `
            -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20
    $asset = $rel.assets | Where-Object { $_.name -eq "BetterVR_Launcher.exe" } | Select-Object -First 1
    if ($asset -and $asset.browser_download_url) { [void]$betterUrls.Add([string]$asset.browser_download_url) }
} catch { Write-Info "Could not query the latest release - using the pinned version." }
[void]$betterUrls.Add("https://github.com/Crementif/BotW-BetterVR/releases/download/0.9.15/BetterVR_Launcher.exe")

Invoke-SafeDownload -Urls $betterUrls -Destination $launcherPath -Label "BetterVR launcher" `
    -ManualUrl "https://github.com/Crementif/BotW-BetterVR/releases" `
    -Instructions "Download BetterVR_Launcher.exe from the Releases page (not the Source Code zip), then place it at: $launcherPath" `
    -SkipMessage "Skipped - download BetterVR_Launcher.exe yourself and place it next to Cemu.exe." | Out-Null

if (Test-Path $launcherPath) { Write-OK "BetterVR launcher is in place." }
else { Write-Warn "BetterVR launcher missing - add BetterVR_Launcher.exe to $installRoot before playing." }

# ------------------------------------------------------------
# STEP 3: Icon + desktop shortcut
# ------------------------------------------------------------
Write-Step 3 4 "Creating a desktop shortcut"

# BetterVR_Launcher.exe ships without an icon - give the shortcut a proper one.
$iconDest = Join-Path $installRoot "BotW_VR.ico"
try { Copy-Item -Path (Join-Path $PSScriptRoot "BotW_VR.ico") -Destination $iconDest -Force } catch {}

try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = Join-Path $desktop "Breath of the Wild VR.lnk"
    $target = if (Test-Path $launcherPath) { $launcherPath } else { $cemuExe }
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($lnk)
    $sc.TargetPath = $target
    $sc.WorkingDirectory = $installRoot
    if (Test-Path $iconDest) { $sc.IconLocation = $iconDest }
    $sc.Description = "Launch Breath of the Wild in VR (BetterVR + Cemu)"
    $sc.Save()
    Write-OK "Desktop shortcut created with custom icon."
} catch { Write-Warn "Could not create the desktop shortcut: $($_.Exception.Message)" }

# Record install path so the Hub flags this as VR Ready and can launch it.
try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $installRoot -Encoding UTF8 -Force } catch {}

# ------------------------------------------------------------
# STEP 4: Manual steps you still have to do (the important part)
# ------------------------------------------------------------
Write-Step 4 4 "Manual setup - follow these exactly"

# Open the install folder + start Cemu so you can add your game + keys.
Write-Info "Opening the install folder and starting Cemu so you can add your game..."
try { Start-Process explorer.exe -ArgumentList ('"' + $installRoot + '"') } catch {}
Start-Sleep -Seconds 2
try { if (Test-Path $cemuExe) { Start-Process -FilePath $cemuExe -WorkingDirectory $installRoot } } catch {}

Write-Box -Heading "A. YOUR GAME (you provide this)" -Lines @(
    "1. Add your own BotW dump for the Wii U + your Wii U keys.",
    "   Put your keys.txt into the portable folder:",
    "   $installRoot\portable",
    "2. In Cemu, add BotW so it shows up in the game list.",
    "3. BotW must be on a recent version - otherwise Cemu shows",
    "   an 'update' message. Install the update AND the DLC via:",
    "   Cemu menu -> File -> Install game title, update or DLC.",
    "   Update 1.5.0 and the DLC both work."
)
Pause-User "Press Enter once BotW shows up in Cemu (updated)..."

Write-Box -Heading "B. CEMU GENERAL SETTINGS" -Lines @(
    "- Cemu window title must say version 2.6 or newer.",
    "- Debug -> Accurate Barriers (Vulkan): DISABLE (performance).",
    "- Options -> General Settings -> Graphics tab:",
    "    Renderer = Vulkan, correct GPU selected, VSync = Off.",
    "- Community Graphic Packs are PRE-INSTALLED by this setup.",
    "  (Optional: Options -> Graphic Packs -> Download Community",
    "   Graphic Packs to refresh them to the newest versions.)"
)
Pause-User "Press Enter once Cemu's general settings are set..."

Write-Box -Heading "C. VR RUNTIME (OpenXR)" -Lines @(
    "- Connect your headset and start your streaming app.",
    "- Set the OpenXR runtime correctly:",
    "    Virtual Desktop: set its OpenXR runtime active.",
    "    SteamVR / ALVR / Quest Link: set SteamVR/Oculus runtime.",
    "- Meta Link's frame interpolation hurts here - ALVR, Virtual",
    "  Desktop or Steam Link are recommended for Quest."
)
Pause-User "Press Enter once your VR runtime is ready..."

Write-Box -Heading "D. ENABLE FPS++ (required, or it crashes)" -Lines @(
    "- Launch the game via BetterVR_Launcher.exe (the shortcut).",
    "- In Cemu: Options -> Graphic packs -> Breath of the Wild:",
    "    * Mods -> FPS++ = ENABLED  (game CRASHES without FPS++)",
    "- Recommended pack settings:",
    "    VR Resolution Multiplier: raise for sharpness (low GPU cost)",
    "    Anti-Aliasing: Nvidia FXAA, or None at 2x+ multiplier",
    "    FPS++ limit: 120 or 144 (runtime controls real VR fps)",
    "    Enhancements: anisotropic 16x, optional Clarity preset",
    "- Optional: download shader caches to avoid first-run stutter."
)

Write-Host ""
Write-Host "  Controls + settings are shown in-game: open the BetterVR menu" -ForegroundColor Gray
Write-Host "  by holding X on the left Touch controller (A on Index)." -ForegroundColor Gray
Write-Host ""
Write-OK "Setup complete. Start from the 'Breath of the Wild VR' desktop shortcut."
Write-Host ""
Write-Host "  Climb anything, cook questionable meals, and chase the next shrine on the horizon." -ForegroundColor Magenta

Pause-User "Press Enter to exit"
