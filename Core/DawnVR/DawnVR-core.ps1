# ============================================================
#  Life is Strange: Before the Storm - DawnVR Mod Installer
# ============================================================

$Host.UI.RawUI.WindowTitle = "Life is Strange: BtS - DawnVR Installer"
$ErrorActionPreference = "Stop"

# Load shared installer safety helpers
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$GAME_APPID      = "554620"
$GAME_NAME       = "Life Is Strange - Before the Storm"
$GAME_EXE        = "Life is Strange- Before the Storm.exe"
$GAME_EXE_ALT    = "Life is Strange - Before the Storm Remastered.exe"

$MELONLOADER_URL      = "https://github.com/LavaGang/MelonLoader/releases/download/v0.5.7/MelonLoader.x64.zip"
$DAWNVR_ORIGINAL_URL  = "https://github.com/TrevTV/DawnVR/releases/download/1.0.1/DawnVR_1.0.1_Original.zip"
$DAWNVR_REMASTER_URL  = "https://github.com/TrevTV/DawnVR/releases/download/1.0.1/DawnVR_1.0.1_Remaster.zip"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "   Life is Strange: Before the Storm - DawnVR Installer" -ForegroundColor Cyan
    Write-Host "   MelonLoader 0.5.7  +  DawnVR v1.0.1" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
}

function Write-Step {
    param($num, $total, $text)
    Write-Host ""
    Write-Host "--- [$num/$total] $text ---" -ForegroundColor Cyan
    Write-Host ""
}

function Write-OK   { param($text) Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Warn { param($text) Write-Host "  [!!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "  [XX] $text" -ForegroundColor Red }
function Write-Info { param($text) Write-Host "  [..] $text" -ForegroundColor Gray }

function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
    foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
        try {
            $p = (Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath
            if ($p -and (Test-Path $p)) { return $p }
        } catch {}
    }
    return $null
}

function Get-SteamLibraries {
    param($steamPath)
    $libraries = @($steamPath)
    $vdfPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
    if (Test-Path $vdfPath) {
        $content = Get-Content $vdfPath -Raw
        $found = [regex]::Matches($content, '"path"\s+"([^"]+)"')
        foreach ($m in $found) {
            $lib = $m.Groups[1].Value -replace '\\\\', '\'
            if (Test-Path $lib) { $libraries += $lib }
        }
    }
    return $libraries
}

function Find-GamePath {
    param($libraries)
    foreach ($lib in $libraries) {
        $candidate = Join-Path $lib "steamapps\common\$GAME_NAME"
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

function Find-GameExe {
    param($gamePath)
    $base     = Join-Path $gamePath $GAME_EXE
    $remaster = Join-Path $gamePath $GAME_EXE_ALT
    if (Test-Path $base)     { return $base }
    if (Test-Path $remaster) { return $remaster }
    $found = Get-ChildItem -Path $gamePath -Filter "Life is Strange*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { return $found.FullName }
    return $null
}

# -------------------------------------------------------
# STEP 1: Choose game edition
# -------------------------------------------------------
Write-Header
Write-Host " DawnVR by TrevTV adds VR support to Life is Strange: Before the" -ForegroundColor White
Write-Host " Storm (Original or Remastered). Bundles MelonLoader 0.5.7" -ForegroundColor White
Write-Host " (required - no other version works)." -ForegroundColor White
Write-Host "  Unsigned VR files can trigger antivirus warnings. If required files" -ForegroundColor Gray
Write-Host "  are missing, setup will stop and offer recovery without claiming why." -ForegroundColor Gray
Write-Host ""
Write-Step 1 4 "Choose Your Game Edition"

Write-Host "  DawnVR has separate versions for the Original and Remastered edition." -ForegroundColor White
Write-Host ""
Write-Host "  [1] Original (Life is Strange: Before the Storm)" -ForegroundColor White
Write-Host "  [2] Remastered (Life is Strange Remastered Collection)" -ForegroundColor White
Write-Host ""

$edition = ""
while ($edition -notin @("1","2")) {
    $edition = (Read-Host "  Enter 1 or 2").Trim()
    if ($edition -notin @("1","2")) { Write-Fail "Please enter 1 or 2." }
}

if ($edition -eq "1") {
    $DAWNVR_URL    = $DAWNVR_ORIGINAL_URL
    $EDITION_LABEL = "Original"
    Write-OK "Selected: Original edition"
} else {
    $DAWNVR_URL    = $DAWNVR_REMASTER_URL
    $EDITION_LABEL = "Remastered"
    Write-OK "Selected: Remastered edition"
}

# -------------------------------------------------------
# STEP 2: Locate the game
# -------------------------------------------------------
Write-Step 2 4 "Locating Life is Strange: Before the Storm"

# --- Try detection library (safe: falls through to legacy lookup on failure) ---
$gamePath = $null
try {
    $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
    if (Test-Path $__utilsPath) {
        . $__utilsPath
        $gamePath = Try-FindSteamGame -Folder $GAME_NAME -Title "Life is Strange: BtS"
    }
} catch {}
# --- End detection library attempt ---

$steamPath = Get-SteamPath
if (-not $gamePath -and $steamPath) {
    $libraries = Get-SteamLibraries $steamPath
    $gamePath = Find-GamePath $libraries
}
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "554620" -SteamFolderNames @("Life is Strange - Before the Storm") -GogNames @("Life is Strange Before the Storm") -EpicNames @("Life is Strange Before the Storm") }

$userSelectedGamePath = $false
if (-not $gamePath) {
    Write-Warn "Game not found in Steam libraries automatically."
    Write-Host "  Please enter the game installation folder path manually:" -ForegroundColor White
    Write-Host "  Example: C:\Program Files (x86)\Steam\steamapps\common\Life Is Strange - Before the Storm" -ForegroundColor Gray
    while (-not $gamePath) {
        $rawInput = (Read-Host "  Game path").Trim().Trim('"')
        if (Test-Path $rawInput) {
            $gamePath = $rawInput
            $userSelectedGamePath = $true
            Write-OK "Game path set: $gamePath"
        } else {
            Write-Fail "Path not found: $rawInput"
        }
    }
} else {
    Write-OK "Game found: $gamePath"
}

$requiredExe = if ($edition -eq '1') { $GAME_EXE } else { $GAME_EXE_ALT }
$gameExe = if (Test-Path -LiteralPath (Join-Path $gamePath $requiredExe) -PathType Leaf) { Join-Path $gamePath $requiredExe } else { $null }
if ($gameExe) {
    Write-OK "Game executable: $(Split-Path $gameExe -Leaf)"
} else {
    Write-Fail "The selected $EDITION_LABEL edition requires $requiredExe in the game folder."
    Pause-User "Press Enter to exit without changing the game."
    exit 1
}
if (-not (Save-HubRememberedGameFolder -GameId 'life-is-strange-bts' -Title 'Life is Strange: BtS' `
    -GameDir $gamePath -ProbeFiles @($requiredExe) -UserSelected:$userSelectedGamePath)) {
    Write-Warn 'The game folder could not be saved for the next Hub session; setup can continue in this window.'
}

# -------------------------------------------------------
# STEP 3: Download and inspect both packages before game changes
# -------------------------------------------------------
Write-Step 3 4 "Preparing MelonLoader and DawnVR"
Write-Host "  MelonLoader 0.5.7 and the $EDITION_LABEL DawnVR package are both required." -ForegroundColor Yellow
Pause-User "Press Enter to download both publisher packages..."

$tempDir = Join-Path $env:TEMP ("DawnVRInstaller_" + [Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($tempDir)
$mlZip = Join-Path $tempDir 'MelonLoader.zip'
$vrZip = Join-Path $tempDir 'DawnVR.zip'
$mlExtract = Join-Path $tempDir 'MelonLoaderExtract'
$vrExtract = Join-Path $tempDir 'DawnVRExtract'
$stage = Join-Path $tempDir 'Stage'
try {
    $mlDownload = Invoke-DownloadOrFallback -Url $MELONLOADER_URL -Destination $mlZip `
        -Label 'MelonLoader v0.5.7' `
        -ManualUrl 'https://github.com/LavaGang/MelonLoader/releases/tag/v0.5.7' `
        -Instructions "Download MelonLoader.x64.zip, then choose Retry or hand the file to recovery." `
        -SkipMessage 'MelonLoader is required; setup cannot complete without it.'
    if (-not ($mlDownload -is [bool] -and $mlDownload)) { throw 'MelonLoader download was not completed.' }
    $vrDownload = Invoke-DownloadOrFallback -Url $DAWNVR_URL -Destination $vrZip `
        -Label "DawnVR v1.0.1 ($EDITION_LABEL)" `
        -ManualUrl 'https://github.com/TrevTV/DawnVR/releases/tag/1.0.1' `
        -Instructions "Download the $EDITION_LABEL DawnVR 1.0.1 ZIP, then choose Retry or hand the file to recovery." `
        -SkipMessage 'DawnVR is required; setup cannot complete without it.'
    if (-not ($vrDownload -is [bool] -and $vrDownload)) { throw 'DawnVR download was not completed.' }

    foreach ($pair in @(@($mlZip,$mlExtract,'MelonLoader'),@($vrZip,$vrExtract,'DawnVR'))) {
        $safety = Test-ZipArchiveEntrySafety -ArchivePath $pair[0] -DestinationFolder $pair[1]
        if (-not $safety.Inspectable -or -not $safety.Safe -or $safety.EntryCount -eq 0) {
            throw "The selected $($pair[2]) archive is unreadable or unsafe."
        }
        $unpacked = Expand-ArchiveOrFallback -ArchivePath $pair[0] -DestinationFolder $pair[1] -Label $pair[2] `
            -SkipMessage "$($pair[2]) was not extracted."
        if ([string]$unpacked -notin @('ok','manual')) { throw "$($pair[2]) extraction was not completed." }
    }

    $mlRequired = @('version.dll','dobby.dll')
    $vrRequired = @('Mods\DawnVRMod.dll','Plugins\DawnVREnabler.dll',
        'Life is Strange - Before the Storm_Data\StreamingAssets\SteamVR\actions.json')
    foreach ($relative in $mlRequired) {
        if (-not (Test-Path -LiteralPath (Join-Path $mlExtract $relative) -PathType Leaf)) {
            throw "The selected MelonLoader archive lacks $relative."
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $mlExtract 'MelonLoader') -PathType Container) -or
        -not @(Get-ChildItem -LiteralPath (Join-Path $mlExtract 'MelonLoader') -Recurse -File).Count) {
        throw 'The selected MelonLoader archive lacks the loader runtime folder.'
    }
    foreach ($relative in $vrRequired) {
        if (-not (Test-Path -LiteralPath (Join-Path $vrExtract $relative) -PathType Leaf)) {
            throw "The selected $EDITION_LABEL DawnVR archive lacks $relative."
        }
    }

    [void][IO.Directory]::CreateDirectory($stage)
    foreach ($sourceRoot in @($mlExtract,$vrExtract)) {
        $prefix = [IO.Path]::GetFullPath($sourceRoot).TrimEnd([char[]]'\/')
        foreach ($file in @(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -ErrorAction Stop)) {
            $relative = $file.FullName.Substring($prefix.Length + 1)
            $destination = Join-Path $stage $relative
            if (Test-Path -LiteralPath $destination -PathType Leaf) {
                if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne
                    (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash) {
                    throw "The two publisher packages disagree on $relative."
                }
                continue
            }
            $parent = Split-Path -Parent $destination
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void][IO.Directory]::CreateDirectory($parent) }
            Copy-Item -LiteralPath $file.FullName -Destination $destination -ErrorAction Stop
        }
    }
    $required = $mlRequired + $vrRequired
    $hashes = Get-PCVRDropInSourceHashes -SourceRoot $stage -RequiredFiles $required

    # STEP 4: one verified transaction for both publisher packages.
    Write-Step 4 4 "Installing MelonLoader and DawnVR"
    . (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
    $contract = New-PCVRInstallerContract -Id 'dawn-vr' -GameName 'Life is Strange: Before the Storm' `
        -Acquisition GitHub -ReleasePageUrl 'https://github.com/TrevTV/DawnVR/releases/tag/1.0.1' `
        -RequiredInstalledFileGroups $required -AntivirusNotice
    $keep = @($hashes.Keys | Where-Object { $_ -match '(?i)\.(cfg|ini)$' })
    [void](Invoke-PCVRDropInInstall -SourceRoot $stage -GameRoot $gamePath -SourceHashes $hashes `
        -KeepExistingFiles $keep -Contract $contract -Version 'v1.0.1' `
        -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')))
    Write-OK "MelonLoader 0.5.7 and DawnVR v1.0.1 ($EDITION_LABEL) verified."
} catch {
    Write-Fail "Installation did not complete: $_"
    Write-Info 'No new success or version receipt was written. Check the error above before retrying.'
    Pause-User 'Press Enter to exit and use installer recovery.'
    exit 1
} finally {
    if (Test-Path -LiteralPath $tempDir) { Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
}

# -------------------------------------------------------
# DONE
# -------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Installation Summary" -ForegroundColor White
Write-Host ""
Write-Host "    [x] MelonLoader 0.5.7" -ForegroundColor Green
Write-Host "    [x] DawnVR v1.0.1 ($EDITION_LABEL)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Magenta

Write-Host ""
try { Set-Clipboard -Value "-vrmode OpenVR" -DeferManualFallback } catch {}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   ACTION REQUIRED - Steam Launch Options" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [OK] Launch parameter copied to clipboard." -ForegroundColor Yellow
Write-Host ""
Write-Host "  (-vrmode OpenVR  |  case-sensitive)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Press Enter to open Steam Launch Options..." -ForegroundColor Yellow
Write-Host "  Then paste (Ctrl+V) and close Properties." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter to open Steam Launch Options..."
Start-Process "steam://gameproperties/$GAME_APPID"
try { Set-Clipboard -Value "-vrmode OpenVR" -DeferManualFallback } catch {}
Show-PCVRClipboardManualFallback -Text "-vrmode OpenVR"

Pause-User "Press Enter once you have pasted the launch option and closed Properties..."

Write-Host ""
Write-Host "--- Important Notes ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  - First launch will take longer than usual." -ForegroundColor White
Write-Host "    MelonLoader configures itself on the first run." -ForegroundColor Gray
Write-Host ""
Write-Host "  - Launch SteamVR before the game to avoid it potentially" -ForegroundColor White
Write-Host "    starting sometimes out of focus." -ForegroundColor White
Write-Host ""
Write-Host "--- Disable Theatre Mode ---" -ForegroundColor Cyan
Write-Host ""
Write-Host "  In SteamVR Settings -> Dashboard:" -ForegroundColor White
Write-Host "  Set 'Present Non-VR Applications on Theater Screen Upon Launch' -> OFF" -ForegroundColor Gray
Write-Host ""
Pause-User "Press Enter to confirm you are aware of this setting..."
Write-Host ""
Write-Host "  - If you see an 'Initialization Error' on startup:" -ForegroundColor White
Write-Host "    Go into the game data folder and delete 'globalgamemanagers.bak'," -ForegroundColor Gray
Write-Host "    then restart the game." -ForegroundColor Gray
Write-Host ""
Write-Host "  - To temporarily disable VR: replace OpenVR with None" -ForegroundColor White
Write-Host "    in the Steam launch parameter." -ForegroundColor Gray
Write-Host ""
Write-Host "  The storm's still coming. Until then, every choice is yours, Chloe." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to open the game installation folder and exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
