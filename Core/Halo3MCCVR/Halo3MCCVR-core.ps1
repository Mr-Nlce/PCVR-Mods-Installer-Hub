# Halo MCC VR installer
#
# Installs the maintained MCCVR continuation by moistman42069. The Hub no
# longer offers the abandoned original builds as installation choices.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')

$Host.UI.RawUI.WindowTitle = 'Halo MCC VR Installer'
$MCC_APPID = '976730'
$MCC_STEAM_FOLDER = 'Halo The Master Chief Collection'
$MCC_BIN_DIR = 'MCC\Binaries\Win64'
$MCC_EXE_STEAM = 'MCC-Win64-Shipping.exe'
$MCC_EXE_STORE = 'MCCWinStore-Win64-Shipping.exe'
$CONTINUATION_REPO = 'moistman42069/MCCVR-Halo-Build'
$CONTINUATION_PAGE = "https://github.com/$CONTINUATION_REPO/releases"
$QUIP = 'Finish the fight - now from inside the visor.'

$CONTINUATION_PIN = [pscustomobject]@{
    Family='Community'; Channel='stable'; Tag='MCCVR-d77c9dd'; Name='HaloMCCVR-d77c9dd-WIP-Test.zip'
    Url='https://github.com/moistman42069/MCCVR-Halo-Build/releases/download/MCCVR-d77c9dd/HaloMCCVR-d77c9dd-WIP-Test.zip'
    Page=$CONTINUATION_PAGE; Folder='Halo_MCC_VR_community'; Marker='.pcvrhub-halomccvr-community'; Manifest='.pcvrhub-halomccvr-community-install.tsv'
    Shortcut='Halo MCC VR'
}

function Write-Header {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ' Halo MCC VR Installer' -ForegroundColor Cyan
    Write-Host ' Installs: Halo MCC VR by moistman42069' -ForegroundColor Gray
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ''
}
function Write-Step { param([int]$Number,[int]$Total,[string]$Text) Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-OK   { param([string]$Text) Write-Host " [OK] $Text" -ForegroundColor Green }
function Write-Info { param([string]$Text) Write-Host " [..] $Text" -ForegroundColor Gray }
function Write-Warn { param([string]$Text) Write-Host " [!!] $Text" -ForegroundColor Yellow }
function Write-Fail { param([string]$Text) Write-Host " [X]  $Text" -ForegroundColor Red }
function Pause-User { param([string]$Text='Press Enter to continue...') Write-Host ''; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }
function Read-YesNo {
    param([string]$Prompt)
    while ($true) {
        Write-Host ''
        $answer = ('' + (Read-Host " $Prompt [Y/N]")).Trim().ToUpperInvariant()
        if ($answer -in @('Y','YES')) { return $true }
        if ($answer -in @('N','NO'))  { return $false }
        Write-Warn 'Please type Y or N.'
    }
}

function Test-MCCRoot([string]$Root) {
    if (-not $Root) { return $false }
    $bin = Join-Path $Root $MCC_BIN_DIR
    return [bool]((Test-Path -LiteralPath (Join-Path $bin $MCC_EXE_STEAM) -PathType Leaf) -or
                  (Test-Path -LiteralPath (Join-Path $bin $MCC_EXE_STORE) -PathType Leaf))
}

function Find-MCCRoot {
    $found = $null
    try { $found = Find-SteamGameFolder -AppId $MCC_APPID -SteamFolderNames @($MCC_STEAM_FOLDER) -ProbeExe (Join-Path $MCC_BIN_DIR $MCC_EXE_STEAM) } catch {}
    if (Test-MCCRoot $found) { return $found }
    try {
        $recorded = (Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw -ErrorAction Stop).Trim()
        if (Test-MCCRoot $recorded) { return $recorded }
    } catch {}
    foreach ($drive in @('C:','D:','E:','F:')) {
        foreach ($relative in @('XboxGames\Halo- The Master Chief Collection\Content','XboxGames\Halo The Master Chief Collection\Content')) {
            $candidate = Join-Path $drive $relative
            if (Test-MCCRoot $candidate) { return $candidate }
        }
    }
    foreach ($candidate in @('C:\Program Files\ModifiableWindowsApps\Halo- TheMasterChiefCollection','C:\Program Files\ModifiableWindowsApps\Halo The Master Chief Collection')) {
        if (Test-MCCRoot $candidate) { return $candidate }
    }
    return $null
}

function Test-MCCVRBuild([string]$Root,[string]$Folder) {
    if (-not (Test-MCCRoot $Root) -or [string]::IsNullOrWhiteSpace($Folder)) { return $false }
    $modRoot = Join-Path $Root $Folder
    if (-not (Test-Path -LiteralPath $modRoot -PathType Container)) { return $false }
    $runtimePresent = (Test-Path -LiteralPath (Join-Path $modRoot 'HaloMCCVR.dll') -PathType Leaf) -or
                      (Test-Path -LiteralPath (Join-Path $modRoot 'halo3xr.dll') -PathType Leaf)
    $launcherPresent = (Test-Path -LiteralPath (Join-Path $modRoot 'HaloMCCVRLauncher.exe') -PathType Leaf) -or
                       (Test-Path -LiteralPath (Join-Path $modRoot 'halo3xr_launcher.exe') -PathType Leaf)
    return [bool]($runtimePresent -and $launcherPresent)
}

function Test-LegacyOnlyMCCVRInstall([string]$Root) {
    return [bool]((Test-MCCVRBuild -Root $Root -Folder 'Halo_MCC_VR') -and
                  -not (Test-MCCVRBuild -Root $Root -Folder 'Halo_MCC_VR_community'))
}

function Get-MCCRootInteractive {
    $root = Find-MCCRoot
    while (-not (Test-MCCRoot $root)) {
        Write-Warn 'Halo: The Master Chief Collection was not found automatically.'
        Write-Host ' Drag the MCC game folder into this window and press Enter.' -ForegroundColor White
        Write-Host " It must contain $MCC_BIN_DIR and the Steam or Store executable." -ForegroundColor Gray
        Write-Host ' Leave the line empty to cancel.' -ForegroundColor DarkGray
        $raw = ('' + (Read-Host ' MCC folder')).Trim().Trim('"')
        if (-not $raw) { return $null }
        if (Test-MCCRoot $raw) { $root = (Get-Item -LiteralPath $raw).FullName }
        else { Write-Fail 'That is not an MCC installation root.' }
    }
    return $root
}

function Get-ArchiveInputFolders {
    try {
        $workspace = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        return @((Join-Path $workspace 'Archive Input\Halo MCC VR'))
    } catch { return @() }
}

function Get-LatestContinuationRelease {
    try {
        $releases = @(Invoke-RestMethod -Uri "https://api.github.com/repos/$CONTINUATION_REPO/releases?per_page=20" -Headers @{'User-Agent'='PCVR-Mods-Hub'} -TimeoutSec 25 -ErrorAction Stop)
        foreach ($release in $releases) {
            if ($release.draft) { continue }
            $asset = @($release.assets | Where-Object {
                $_.name -match '(?i)^HaloMCCVR.*\.zip$' -and $_.name -notmatch '(?i)source|symbols|debug'
            } | Select-Object -First 1)[0]
            if (-not $asset) { continue }
            return [pscustomobject]@{
                Family='Community'; Channel=$(if ($release.prerelease) {'prerelease'} else {'stable'})
                Tag=[string]$release.tag_name; Name=[string]$asset.name
                Url=[string]$asset.browser_download_url; Page=$CONTINUATION_PAGE
                Folder='Halo_MCC_VR_community'; Marker='.pcvrhub-halomccvr-community'
                Manifest='.pcvrhub-halomccvr-community-install.tsv'; Shortcut='Halo MCC VR'
            }
        }
    } catch { Write-Warn 'The continuation release lookup failed; using the last known playable release URL.' }
    return $CONTINUATION_PIN
}

function Get-ReleaseArchive([object]$Release,[string]$Destination) {
    $findArgs = @{
        Patterns=@([string]$Release.Name)
        ExtraFolders=(Get-ArchiveInputFolders); Label=("Halo MCC VR " + [string]$Release.Tag)
    }
    $found = Find-PredownloadedFile @findArgs
    if ($found) {
        Copy-Item -LiteralPath $found -Destination $Destination -Force
    } else {
        $downloadArgs = @{
            Urls=@([string]$Release.Url); Destination=$Destination
            Label=("Halo MCC VR " + [string]$Release.Tag)
            ManualUrl=[string]$Release.Page
            Instructions="Download the playable build ZIP named '$($Release.Name)', then choose Retry. Do not select a source ZIP."
        }
        $null = Invoke-SafeDownload @downloadArgs
        if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) { return $null }
    }
    return $Destination
}

function Get-PayloadRoot([string]$ExtractRoot) {
    $dll = Get-ChildItem -LiteralPath $ExtractRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -in @('HaloMCCVR.dll','halo3xr.dll') } | Select-Object -First 1
    if (-not $dll -or $dll.Length -lt 2) { return $null }
    $root = $dll.DirectoryName
    $launcher = if ($dll.Name -eq 'halo3xr.dll') { 'halo3xr_launcher.exe' } else { 'HaloMCCVRLauncher.exe' }
    $launcherPath = Join-Path $root $launcher
    $configPath = Join-Path $root 'halomccvr.cfg'
    if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf) -or (Get-Item -LiteralPath $launcherPath).Length -lt 2) { return $null }
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf) -or (Get-Item -LiteralPath $configPath).Length -lt 1) { return $null }

    # Release notes, manifests and supplementary document names change often.
    # They are useful evidence but are not runtime requirements. The matching
    # DLL, launcher and config are required to run a playable MCCVR package;
    # source/diagnostic assets are already excluded
    # by Get-LatestContinuationRelease before download.
    return $root
}

function Get-RelativeFiles([string]$Root) {
    $prefix = $Root.TrimEnd('\')
    return @(Get-ChildItem -LiteralPath $Root -Recurse -File | ForEach-Object {
        [pscustomobject]@{ File=$_; Relative=$_.FullName.Substring($prefix.Length).TrimStart('\') }
    })
}

function Save-OwnershipManifest([string]$Path,[object[]]$Rows) {
    $tab = [char]9
    $lines = @("Action$($tab)RelativePath$($tab)InstalledSha256")
    foreach ($row in @($Rows | Sort-Object RelativePath)) {
        $lines += "$($row.Action)$($tab)$($row.RelativePath)$($tab)$($row.InstalledSha256)"
    }
    [IO.File]::WriteAllLines($Path,[string[]]$lines,(New-Object Text.UTF8Encoding($false)))
}

function Install-Payload([string]$PayloadRoot,[string]$MccRoot,[object]$Release,[string]$WorkRoot) {
    $modDir = Join-Path $MccRoot ([string]$Release.Folder)
    New-Item -ItemType Directory -Path $modDir -Force | Out-Null
    $payloadFiles = Get-RelativeFiles $PayloadRoot
    $launcher = if (@($payloadFiles | Where-Object { $_.Relative -eq 'HaloMCCVRLauncher.exe' }).Count) { 'HaloMCCVRLauncher.exe' } else { 'halo3xr_launcher.exe' }

    $affected = New-Object 'System.Collections.Generic.List[string]'
    foreach ($entry in $payloadFiles) { if (-not $affected.Contains([string]$entry.Relative)) { [void]$affected.Add([string]$entry.Relative) } }
    foreach ($known in @('HaloMCCVR.dll','HaloMCCVRLauncher.exe','halo3xr.dll','halo3xr_launcher.exe',[string]$Release.Marker,[string]$Release.Manifest)) {
        if (-not $affected.Contains($known)) { [void]$affected.Add($known) }
    }
    $rollback = Join-Path $WorkRoot 'rollback'
    New-Item -ItemType Directory -Path $rollback -Force | Out-Null
    foreach ($relative in $affected) {
        $source = Join-Path $modDir $relative
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { continue }
        $backup = Join-Path $rollback $relative
        $parent = Split-Path -Parent $backup
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $source -Destination $backup -Force
    }

    $configRelative = 'halomccvr.cfg'
    $oldConfigRollback = Join-Path $rollback $configRelative
    $newConfigSource = Join-Path $PayloadRoot $configRelative
    $savePreviousConfig = $false
    if ((Test-Path -LiteralPath $oldConfigRollback -PathType Leaf) -and (Test-Path -LiteralPath $newConfigSource -PathType Leaf)) {
        $savePreviousConfig = ((Get-FileHash -LiteralPath $oldConfigRollback -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $newConfigSource -Algorithm SHA256).Hash)
    }

    try {
        foreach ($entry in $payloadFiles) {
            $destination = Join-Path $modDir ([string]$entry.Relative)
            $parent = Split-Path -Parent $destination
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Copy-Item -LiteralPath $entry.File.FullName -Destination $destination -Force
        }

        $launcherPath = Join-Path $modDir $launcher
        if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) { throw "Installed launcher is missing: $launcher" }
        [IO.File]::WriteAllText((Join-Path $modDir ([string]$Release.Marker)),([string]$Release.Tag),(New-Object Text.UTF8Encoding($false)))

        $dllName = if ($launcher -eq 'HaloMCCVRLauncher.exe') { 'HaloMCCVR.dll' } else { 'halo3xr.dll' }
        $watch = @((Join-Path $modDir $dllName),$launcherPath)
        $copyRoot = $PayloadRoot
        $copyLauncher = $launcher
        $copyDll = $dllName
        $recover = {
            foreach ($name in @($copyDll,$copyLauncher)) {
                $from = Join-Path $copyRoot $name
                $to = Join-Path $modDir $name
                if ((Test-Path -LiteralPath $from -PathType Leaf) -and -not (Test-Path -LiteralPath $to -PathType Leaf)) { Copy-Item -LiteralPath $from -Destination $to -Force }
            }
        }.GetNewClosure()
        $survivedAntivirusCheck = Confirm-PlacedFilesSurvive -Paths $watch -GameDir $MccRoot -Recopy $recover
        if (-not $survivedAntivirusCheck) { throw 'The installed binaries did not survive the antivirus check.' }

        $rows = New-Object 'System.Collections.Generic.List[object]'
        foreach ($entry in $payloadFiles) {
            $installed = Join-Path $modDir ([string]$entry.Relative)
            if (-not (Test-Path -LiteralPath $installed -PathType Leaf)) { continue }
            $action = if ($entry.Relative -ieq 'halomccvr.cfg') { 'preserve' } else { 'remove' }
            [void]$rows.Add([pscustomobject]@{ Action=$action; RelativePath=[string]$entry.Relative; InstalledSha256=(Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash })
        }
        foreach ($extra in @([string]$Release.Marker)) {
            $installed = Join-Path $modDir $extra
            [void]$rows.Add([pscustomobject]@{ Action='remove'; RelativePath=$extra; InstalledSha256=(Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash })
        }
        Save-OwnershipManifest -Path (Join-Path $modDir ([string]$Release.Manifest)) -Rows $rows.ToArray()

        $desktop = [Environment]::GetFolderPath('Desktop')
        $shortcut = Join-Path $desktop ([string]$Release.Shortcut + '.lnk')
        $mayWrite = $true
        if (Test-Path -LiteralPath $shortcut -PathType Leaf) {
            try {
                $existing = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcut)
                if ($existing.TargetPath -ine $launcherPath) { $mayWrite=$false; Write-Warn "Kept an unrelated desktop shortcut named '$($Release.Shortcut)'." }
            } catch { $mayWrite=$false }
        }
        if ($mayWrite) {
            $bin = Join-Path $MccRoot $MCC_BIN_DIR
            $icon = if (Test-Path -LiteralPath (Join-Path $bin $MCC_EXE_STEAM)) { Join-Path $bin $MCC_EXE_STEAM } else { Join-Path $bin $MCC_EXE_STORE }
            if (New-DesktopShortcut -LnkPath $shortcut -TargetPath $launcherPath -WorkingDir $modDir -IconPath "$icon,0" -Description ("Launch " + [string]$Release.Shortcut + ' without anti-cheat')) { Write-OK "Desktop shortcut created: $($Release.Shortcut)" }
        }
        # Older Hub builds used a longer Community shortcut name. Remove it
        # only when its target proves that it belongs to this exact install.
        $legacyShortcut = Join-Path $desktop 'Halo MCC Community VR.lnk'
        if ($legacyShortcut -ne $shortcut -and (Test-Path -LiteralPath $legacyShortcut -PathType Leaf)) {
            try {
                $legacy = (New-Object -ComObject WScript.Shell).CreateShortcut($legacyShortcut)
                if ($legacy.TargetPath -ieq $launcherPath) {
                    Remove-Item -LiteralPath $legacyShortcut -Force
                    Write-Info 'Replaced the former Halo MCC Community VR shortcut.'
                }
            } catch { Write-Warn 'The former desktop shortcut could not be verified and was kept.' }
        }

        if ($savePreviousConfig) {
            $configBackupDir = Join-Path $modDir '.pcvrhub-backups'
            New-Item -ItemType Directory -Path $configBackupDir -Force | Out-Null
            $stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmssfff')
            $configBackup = Join-Path $configBackupDir ("halomccvr-$stamp.cfg.bak")
            Copy-Item -LiteralPath $oldConfigRollback -Destination $configBackup -Force
            Write-OK "Previous personal config saved: $configBackup"
        }
        return $modDir
    } catch {
        foreach ($relative in $affected) {
            $target = Join-Path $modDir $relative
            $backup = Join-Path $rollback $relative
            if (Test-Path -LiteralPath $backup -PathType Leaf) {
                $parent = Split-Path -Parent $target
                if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
                Copy-Item -LiteralPath $backup -Destination $target -Force
            } else {
                Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
            }
        }
        throw
    }
}

$work = $null
try {
    Write-Header
    Write-Host ' Installs the maintained Halo MCC VR build. On updates, the previous' -ForegroundColor White
    Write-Host ' personal config is backed up before the release config is installed.' -ForegroundColor White
    Write-Host ''
    Write-Warn 'Always launch without anti-cheat. Never use the mod in matchmaking.'
    Write-Info 'Start MCC flat once first and finish the Microsoft account sign-in.'
    Show-AntivirusNotice
    $startupMccPath = Find-MCCRoot
    if (Test-LegacyOnlyMCCVRInstall -Root $startupMccPath) {
        Write-Host ''
        Write-Host ' LEGACY HALO MCC VR INSTALL DETECTED' -ForegroundColor Yellow
        Write-Host ' You still have an older Halo MCC VR mod.' -ForegroundColor White
        Write-Host ' That version is no longer maintained in its original form.' -ForegroundColor White
        Write-Host ' Other modders now continue the project, support more campaigns,' -ForegroundColor White
        Write-Host ' and follow their own development priorities.' -ForegroundColor White
        Write-Host ' The maintained build installs beside it. Your older build stays' -ForegroundColor Green
        Write-Host ' untouched and remains available as Legacy in the Hub.' -ForegroundColor Green
        if (-not (Read-YesNo 'Install the maintained Halo MCC VR version now?')) {
            Write-Info 'Setup cancelled. No files were changed.'
            return
        }
    } else {
        Pause-User 'Press Enter to proceed with setup...' | Out-Null
    }

    $release = Get-LatestContinuationRelease
    Write-Step 1 4 'Getting the latest release'
    $work = Join-Path $env:TEMP ('pcvr_halomccvr_' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $archive = Get-ReleaseArchive -Release $release -Destination (Join-Path $work ([string]$release.Name))
    if (-not $archive) { throw 'The selected archive is unavailable. No files were changed.' }

    Write-Step 2 4 'Extracting and checking the package'
    $extract = Join-Path $work 'payload'
    $expanded = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'Halo MCC VR archive' -AllowSkip $false
    if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The archive was not extracted.' }
    $payload = Get-PayloadRoot -ExtractRoot $extract
    if (-not $payload) { throw 'The package layout is incomplete or is a source/diagnostic archive.' }
    $count = @(Get-ChildItem -LiteralPath $payload -Recurse -File).Count
    Write-OK "Playable MCCVR runtime validated ($count packaged files)."

    Write-Step 3 4 'Locating Halo: The Master Chief Collection'
    $mccPath = if (Test-MCCRoot $startupMccPath) { $startupMccPath } else { Get-MCCRootInteractive }
    if (-not $mccPath) { throw 'Setup was cancelled before the game was changed.' }
    if (@(Get-Process -Name 'MCC-Win64-Shipping','MCCWinStore-Win64-Shipping' -ErrorAction SilentlyContinue).Count) { throw 'MCC is running. Close it completely and run setup again.' }
    Write-OK "Found: $mccPath"

    Write-Step 4 4 'Installing Halo MCC VR safely'
    $installedDir = Install-Payload -PayloadRoot $payload -MccRoot $mccPath -Release $release -WorkRoot $work
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path'),$mccPath,(New-Object Text.UTF8Encoding($false)))
    Save-InstalledStamp -GameDir $mccPath -Version ([string]$release.Tag) -HubDir $PSScriptRoot
    [IO.File]::WriteAllText((Join-Path $installedDir '.pcvrhub-channel'),([string]$release.Channel),(New-Object Text.UTF8Encoding($false)))
    Write-OK "Halo MCC VR installed in $installedDir"

    Write-Host ''
    Write-Host ' HOW TO PLAY' -ForegroundColor Cyan
    Write-Host ' Start SteamVR with SteamVR as the active OpenXR runtime.' -ForegroundColor White
    Write-Host ' Then use Start in VR in the Hub or the matching desktop shortcut.' -ForegroundColor White
    Write-Host ' Open F1 in game for VR settings. Launch only with anti-cheat off.' -ForegroundColor Gray
    Write-Host ''
    Write-Warn 'Halo 2 AI perception/aim can malfunction in this release.'
    Write-Info 'World collision and Physical melee are experimental and disabled by default.'
    Write-Info 'Physical melee currently requires World collision to remain enabled.'
    Write-Host ''
    Write-Host " $QUIP" -ForegroundColor Magenta
} catch {
    Write-Host ''
    Write-Fail $_.Exception.Message
    throw
} finally {
    if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
Pause-User 'Press Enter to exit...' | Out-Null
