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

# The tag used when GitHub cannot be reached. Keep it in step with the
# fallback download URL further down - both read this one variable.
# 0.9.23 fixes the loading-screen crashes that 0.9.21/0.9.22 introduced
# (teleporting, dying, leaving a shrine) and adds "One Hit Per Swing".
$PINNED_TAG = "0.9.23"

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
    param([string]$Heading, [string[]]$Lines, [string]$HeadColor="Yellow", [string[]]$Footnote)
    Write-Host ""
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $HeadColor
    Write-Host ("  | " + $Heading.PadRight(56) + " |") -ForegroundColor $HeadColor
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $HeadColor
    foreach ($l in $Lines) { Write-Host "    $l" -ForegroundColor White }
    # A footnote in grey: still inside the box, but visibly secondary.
    # The antivirus note goes here - it concerns a minority of readers,
    # and in white it competed with the things everyone has to read.
    if ($Footnote) {
        Write-Host ""
        foreach ($l in $Footnote) { Write-Host "    $l" -ForegroundColor DarkGray }
    }
    Write-Host ""
}

function Install-BotWCemuArchive {
    param([string]$ArchivePath, [string]$InstallRoot, [string]$ExpectedHash)
    if ((Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256 -ErrorAction Stop).Hash -ne $ExpectedHash) { throw 'Cemu checksum mismatch. Download the official Cemu 2.6 archive again.' }
    $stage = Join-Path $InstallRoot ('.cemu-' + [Guid]::NewGuid().ToString('N'))
    try {
        $status = Expand-ArchiveOrFallback -ArchivePath $ArchivePath -DestinationFolder $stage -Label 'Cemu 2.6' -AllowSkip $false
        if ([string]$status -notin @('ok','manual')) { throw 'Cemu extraction was not completed.' }
        $source = Get-ExtractedPayloadRoot -ExtractDir $stage -RelModFile 'Cemu.exe'
        [void](Merge-DirectoryTreeVerified -Source $source -Destination $InstallRoot -Label 'Cemu files')
        if (-not (Confirm-PlacedFilesSurvive -Paths @((Join-Path $InstallRoot 'Cemu.exe')) -GameDir $InstallRoot -ArchivePath $ArchivePath)) { throw 'Cemu.exe is missing after recovery.' }
    } finally {
        if (Test-Path -LiteralPath $stage) {
            $resolved = (Resolve-Path -LiteralPath $stage).Path
            $prefix = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\') + '\.cemu-'
            if ($resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $resolved -Recurse -Force }
        }
    }
}

function Install-BetterVRLauncher {
    param([string]$InstallRoot, [string[]]$Urls)
    $stage = Join-Path $InstallRoot ('.bettervr-' + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($stage)
    $candidate = Join-Path $stage 'BetterVR_Launcher.exe'
    $destination = Join-Path $InstallRoot 'BetterVR_Launcher.exe'
    $previous = Join-Path $stage 'previous-launcher.exe'
    $keepStage = $false
    $info = @{}
    $download = {
        Invoke-SafeDownload -Urls $Urls -Destination $candidate -Label 'BetterVR launcher' -DownloadInfo $info -ManualUrl 'https://github.com/Crementif/BotW-BetterVR/releases' -Instructions "Place BetterVR_Launcher.exe at: $candidate"
    }
    try {
        $status = & $download
        if ([string]$status -in @('skip','quit')) { throw 'BetterVR download was cancelled.' }
        if (-not (Confirm-PlacedFilesSurvive -Paths @($candidate) -GameDir $InstallRoot -Recopy { & $download | Out-Null })) { throw 'BetterVR download did not survive recovery.' }
        $stream = [IO.File]::OpenRead($candidate)
        try { $valid = $stream.Length -gt 2 -and $stream.ReadByte() -eq 77 -and $stream.ReadByte() -eq 90 } finally { $stream.Dispose() }
        if (-not $valid) { throw 'The BetterVR download is not a Windows executable.' }
        if (Test-Path -LiteralPath $destination -PathType Leaf) { Copy-Item -LiteralPath $destination -Destination $previous -ErrorAction Stop }
        Copy-Item -LiteralPath $candidate -Destination $destination -Force -ErrorAction Stop
        if (-not (Confirm-PlacedFilesSurvive -Paths @($destination) -GameDir $InstallRoot -Recopy { Copy-Item -LiteralPath $candidate -Destination $destination -Force -ErrorAction Stop })) { throw 'BetterVR launcher is missing after recovery.' }
        if ($info.Url -match 'github\.com/Crementif/BotW-BetterVR/releases/download/([^/]+)/') { return [Uri]::UnescapeDataString($Matches[1]) }
        return ''
    } catch {
        $failure = $_
        if (Test-Path -LiteralPath $previous -PathType Leaf) {
            try { Copy-Item -LiteralPath $previous -Destination $destination -Force -ErrorAction Stop }
            catch { $keepStage = $true; Write-Warn "Previous launcher retained for recovery: $previous" }
        }
        throw $failure
    } finally {
        $resolved = (Resolve-Path -LiteralPath $stage).Path
        $prefix = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\') + '\.bettervr-'
        if (-not $keepStage -and $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}

Write-Header

# ------------------------------------------------------------
# Intro - what this does + the prerequisite
# ------------------------------------------------------------
# !!! THE LINES ARE BUILT FIRST, THEN PASSED IN.
# Writing "-Lines @( ... ) + (Get-...)" does NOT concatenate: the closing
# bracket ends the -Lines argument, and PowerShell reads the "+" as the
# next parameter - which lands on -HeadColor and throws
# "cannot convert + to System.ConsoleColor". Build the array in a
# variable, hand the variable over.
$introLines = @(
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
$introNote = @("ANTIVIRUS:") + (Get-AntivirusNoticeLines -Short)
Write-Box -Heading "ABOUT THIS INSTALL - READ FIRST" -Lines $introLines -Footnote $introNote
$go = (Read-Host "  Continue with the setup? (Y/N)").Trim()
if ($go -notmatch '^[Yy]') { Write-Info "Cancelled by user."; Pause-User "Press Enter to exit..."; exit 0 }

# ------------------------------------------------------------
# Pick a writable install root: C:\Games then D: then E:
# ------------------------------------------------------------
$installRoot = $null
$recorded = Join-Path $PSScriptRoot '.installed_path'
if (Test-Path -LiteralPath $recorded) {
    $existing = (Get-Content -LiteralPath $recorded -Raw).Trim()
    if ($existing -and ((Test-Path -LiteralPath "$existing\Cemu.exe") -or (Test-Path -LiteralPath "$existing\BetterVR_Launcher.exe"))) { $installRoot = $existing }
}
if (-not $installRoot) {
    foreach ($existing in @('C:\Games\Breath of the Wild VR','D:\Games\Breath of the Wild VR','E:\Games\Breath of the Wild VR')) {
        if ((Test-Path -LiteralPath "$existing\Cemu.exe") -or (Test-Path -LiteralPath "$existing\BetterVR_Launcher.exe")) { $installRoot = $existing; break }
    }
}
foreach ($drive in @("C:", "D:", "E:")) {
    if ($installRoot) { break }
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
# The antivirus notice is IN THE INTRO BOX above, not here: this
# installer opens with a full screen the user reads before saying yes,
# and five more lines under it would have been five lines too many. The
# wording is the same one every other installer shows - it comes from
# Get-AntivirusNoticeLines, so there is still only one text.
# This mod is the textbook case for it: the launcher injects itself into
# Cemu, and the author says outright that Defender flags it until
# Microsoft whitelists each new build.

Write-Step 1 4 "Downloading the Cemu 2.6 emulator"

$CEMU_SHA256 = "a6bcc2bc42a362d10213819948f3152fae7d47f70067f25939b51d3ddcfb0896"
$cemuUrl     = "https://github.com/cemu-project/Cemu/releases/download/v2.6/cemu-2.6-windows-x64.zip"
$cemuZip     = Join-Path $installRoot "cemu-2.6-windows-x64.zip"

if (Test-Path -LiteralPath $cemuExe -PathType Leaf) {
    Write-OK 'Existing Cemu.exe retained - check that its version is 2.6 or newer.'
} else {
    $download = Invoke-SafeDownload -Urls @($cemuUrl) -Destination $cemuZip -Label 'Cemu 2.6 (Windows x64)' -ManualUrl $cemuUrl -Instructions "Place the official Cemu 2.6 archive at: $cemuZip"
    if ([string]$download -in @('skip','quit') -or -not (Test-Path -LiteralPath $cemuZip -PathType Leaf)) { throw 'Cemu is required; setup was not completed.' }
    Install-BotWCemuArchive -ArchivePath $cemuZip -InstallRoot $installRoot -ExpectedHash $CEMU_SHA256
    Remove-Item -LiteralPath $cemuZip -Force
    Write-OK 'Cemu 2.6 installed and verified.'
}

# ------------------------------------------------------------

# Pre-load the community graphic packs (so FPS++ is ready
# without the manual "Download Community Graphic Packs" click).
# Optional + non-fatal: Cemu's in-app downloader still works.
# ------------------------------------------------------------
$gpDir = Join-Path $installRoot "graphicPacks"
$graphicPacksReady = $false
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
    $gpDownload = Invoke-SafeDownload -Urls $gpUrls -Destination $gpZip -Label "Cemu community graphic packs" `
        -ManualUrl "https://cemu-project.github.io/cemu_graphic_packs/" `
        -Instructions "Optional: download the graphic packs zip and extract its folders into: $gpDir" `
        -SkipMessage "Skipped - you can still click 'Download Community Graphic Packs' inside Cemu later."
    if ([string]$gpDownload -eq 'quit') { throw 'Setup cancelled during the graphic-pack download.' }
    if ([string]$gpDownload -ne 'skip' -and (Test-Path -LiteralPath $gpZip)) {
        $gpTmp = Join-Path $installRoot ('.graphicpacks-' + [Guid]::NewGuid().ToString('N'))
        $gpEx = Expand-ArchiveOrFallback -ArchivePath $gpZip -DestinationFolder $gpTmp -Label "graphic packs" -AllowSkip $true
        if ([string]$gpEx -eq 'quit') { throw 'Setup cancelled during graphic-pack extraction.' }
        if ([string]$gpEx -in @('ok','manual')) {
            $gpSrc = $gpTmp
            $gpTopDirs = @(Get-ChildItem -LiteralPath $gpTmp -Directory -Force)
            $gpTopFiles = @(Get-ChildItem -LiteralPath $gpTmp -File -Force)
            if ($gpTopDirs.Count -eq 1 -and $gpTopFiles.Count -le 2) { $gpSrc = $gpTopDirs[0].FullName }
            try {
                $null = Merge-DirectoryTreeVerified -Source $gpSrc -Destination $gpDir -Label "Cemu community graphic packs"
                Write-OK "Community graphic packs pre-loaded (FPS++ is now available to enable)."
                $graphicPacksReady = $true
            } catch { Write-Warn "Could not place all graphic packs: $($_.Exception.Message)" }
        }
        $gpPrefix = [IO.Path]::GetFullPath($installRoot).TrimEnd('\') + '\.graphicpacks-'
        if (-not [IO.Path]::GetFullPath($gpTmp).StartsWith($gpPrefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe graphic-pack staging path.' }
        try { Remove-Item -LiteralPath $gpTmp -Recurse -Force } catch {}
        try { Remove-Item -LiteralPath $gpZip -Force } catch {}
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
# Remember WHICH tag we are about to install, so it can be recorded next to
# the launcher afterwards - see the .bettervr_version note further down.
$installedTag = $PINNED_TAG
try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/Crementif/BotW-BetterVR/releases/latest" `
            -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 20
    $asset = $rel.assets | Where-Object { $_.name -eq "BetterVR_Launcher.exe" } | Select-Object -First 1
    if ($asset -and $asset.browser_download_url) {
        [void]$betterUrls.Add([string]$asset.browser_download_url)
        if ($rel.tag_name) { $installedTag = ([string]$rel.tag_name).Trim() }
    }
} catch { Write-Info "Could not query the latest release - using the pinned version." }
# Pinned fallback for when the GitHub API is unreachable or rate-limited.
# The API call above is the normal path and always brings the newest
# release, so this only has to be a build that works - but keep it
# current anyway, or an offline install lands on something old.
[void]$betterUrls.Add("https://github.com/Crementif/BotW-BetterVR/releases/download/$PINNED_TAG/BetterVR_Launcher.exe")

$installedTag = Install-BetterVRLauncher -InstallRoot $installRoot -Urls $betterUrls
if ($installedTag) {
    [void](Write-ModStamp -GameDir $installRoot -Version $installedTag)
    Save-InstalledStamp -GameDir $installRoot -Version $installedTag -HubDir $PSScriptRoot
    Write-OK "BetterVR launcher verified ($installedTag)."
} else {
    foreach ($record in @((Join-Path $installRoot '.pcvrhub_version'), (Join-Path $PSScriptRoot '.installed_version'))) {
        if (Test-Path -LiteralPath $record) { Remove-Item -LiteralPath $record -Force }
    }
    Write-Warn 'Launcher verified, but the manually supplied version is unknown; no version was guessed.'
}

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
     $sc = New-DesktopShortcut -LnkPath $lnk -TargetPath $target -WorkingDir $installRoot -IconPath $iconDest -Description "Launch Breath of the Wild in VR (BetterVR + Cemu)"
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
    $(if ($graphicPacksReady) { '- Community Graphic Packs were pre-loaded by this setup.' } else { '- Graphic packs were not pre-loaded: download them in Cemu.' }),
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
# ------------------------------------------------------------
#  Optional: a faster Cemu
# ------------------------------------------------------------
# The mod author measured up to 35% more frames in Breath of the Wild
# with the Cemu 2.7 test builds. This is OFFERED, never done for you:
# Cemu's own page says to use the normal release unless you have a
# reason not to, and these builds are explicitly untested.
#
# It is also not downloaded automatically. The address on that page
# carries a build number that changes every time, so fetching it would
# mean assembling a download address at runtime - the exact shape that
# had six virus scanners flagging this Hub once already. The page opens,
# and you drop the file in.
Write-Host ""
Write-Host "  OPTIONAL - a faster Cemu" -ForegroundColor White
Write-Host "  The mod author measures up to 35% more frames with the Cemu 2.7" -ForegroundColor Gray
Write-Host "  test builds. They are experimental: Cemu's own page recommends the" -ForegroundColor Gray
Write-Host "  normal release unless you have a reason otherwise. Your call." -ForegroundColor Gray
Write-Host ""
$wantCemu = ""
for ($k = 1; $k -le 20; $k++) {
    $wantCemu = ("" + (Read-Host "  Show me how? [y/n]")).Trim().ToLower()
    if ($wantCemu -in @("y","n","yes","no")) { break }
    Write-Host "  Please answer y or n." -ForegroundColor Yellow
}
if ($wantCemu -in @("y","yes")) {
    $dlFolder = Join-Path $env:USERPROFILE "Downloads"
    Write-Host ""
    Write-Host "  1. On the page that opens, take the " -NoNewline -ForegroundColor White
    Write-Host "cemu-bin-windows-x64" -NoNewline -ForegroundColor Cyan
    Write-Host " row" -ForegroundColor White
    Write-Host "     from the TOP block - that is the newest build." -ForegroundColor Gray
    Write-Host "  2. Open the downloaded cemu-bin-windows-x64.zip." -ForegroundColor White
    Write-Host "  3. Move the Cemu.exe out of it into your game folder," -ForegroundColor White
    Write-Host "     overwriting the old one (rename the old one first if you" -ForegroundColor White
    Write-Host "     want a way back)." -ForegroundColor White
    Write-Host ""
    Write-Host "  The file has to be called " -NoNewline -ForegroundColor Gray
    Write-Host "Cemu.exe" -NoNewline -ForegroundColor Cyan
    Write-Host " exactly - rename it if it is not." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Your Downloads folder:" -ForegroundColor White
    Write-Host "    $dlFolder" -ForegroundColor Cyan
    Write-Host "  Your game folder:" -ForegroundColor White
    Write-Host "    $installRoot" -ForegroundColor Cyan
    Write-Host ""
    Pause-User "Press Enter to open the Cemu builds page and both folders..."
    # Fixed address, no build number: the page, not a file.
    try { Start-Process "https://cemu.info/ActionBuilds.php" } catch {}
    Start-Sleep -Milliseconds 400
    try { if (Test-Path -LiteralPath $dlFolder)   { Start-Process explorer.exe $dlFolder } } catch {}
    try { if (Test-Path -LiteralPath $installRoot) { Start-Process explorer.exe $installRoot } } catch {}
    Write-Host ""
    Write-Host "  If it turns out worse, put your old Cemu.exe back - nothing" -ForegroundColor Gray
    Write-Host "  else in the folder changes." -ForegroundColor Gray
}

Write-Host ""
Write-OK "Setup complete. Start from the 'Breath of the Wild VR' desktop shortcut."
Write-Host ""
Write-Host "  Climb anything, cook questionable meals, and chase the next shrine on the horizon." -ForegroundColor Magenta

Pause-User "Press Enter to exit"
