# Black Mesa VR - safe stable-channel installer.
# Downloads are acquired at run time. No VR-mod archive is bundled with the Hub.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')

$Host.UI.RawUI.WindowTitle = 'Black Mesa VR Installer'
$APP_ID = '362890'
$GAME_EXE = 'bms.exe'
$MOD_NAME = 'Black Mesa VR'
$MOD_AUTHOR = 'Hochgeschwindigkeitsrennfahrer'
$REPO = 'Hochgeschwindigkeitsrennfahrer/black-mesa-vr'
$RELEASES_URL = "https://github.com/$REPO/releases"
$PIN_TAG = 'hl2vr-hud-controls-2026-09-06'
$PIN_NAME = 'Black-Mesa-VR-drop-in.zip'
$PIN_URL = "https://github.com/$REPO/releases/download/$PIN_TAG/$PIN_NAME"
$MANIFEST_NAME = '.pcvrhub-blackmesavr-install.tsv'
$BACKUP_NAME = '.pcvrhub-blackmesavr-backup'
$SHORTCUT_STATE = '.pcvrhub-blackmesavr-shortcuts.tsv'
$AUTOEXEC_REL = 'bms\cfg\autoexec.cfg'
$LOADERS = @('d3d9.dll','bin\d3d9.dll','bin\thirdparty\dxvk-windows-x86\d3d9.dll')
$LAUNCH_ARGS = '-heapsize 524288 -processheap -high -novid -windowed -oldgameui'
$QUIP = 'The resonance cascade was an accident. The crowbar swings are entirely deliberate.'

function Write-Header {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ' Black Mesa VR - Installer' -ForegroundColor Cyan
    Write-Host " Installs: $MOD_NAME by $MOD_AUTHOR" -ForegroundColor Gray
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ''
}
function Write-Step { param([int]$Number,[int]$Total,[string]$Text) Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host '' }
function Write-OK   { param([string]$Text) Write-Host " [OK] $Text" -ForegroundColor Green }
function Write-Info { param([string]$Text) Write-Host " [..] $Text" -ForegroundColor Gray }
function Write-Warn { param([string]$Text) Write-Host " [!]  $Text" -ForegroundColor Yellow }
function Write-Fail { param([string]$Text) Write-Host " [X]  $Text" -ForegroundColor Red }
function Pause-User { param([string]$Text='Press Enter to continue...') Write-Host ''; Write-Host " >>> $Text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamInstall {
    foreach ($reg in @('HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','HKLM:\SOFTWARE\Valve\Steam','HKCU:\SOFTWARE\Valve\Steam')) {
        try {
            if (-not (Test-Path -LiteralPath $reg)) { continue }
            $p = Get-ItemProperty -LiteralPath $reg -ErrorAction Stop
            foreach ($candidate in @($p.InstallPath,$p.SteamPath)) {
                if ($candidate -and (Test-Path -LiteralPath (Join-Path ([string]$candidate) 'steam.exe') -PathType Leaf)) { return ([string]$candidate) }
            }
        } catch {}
    }
    foreach ($candidate in @("${env:ProgramFiles(x86)}\Steam","${env:ProgramFiles}\Steam",'C:\Steam')) {
        if ($candidate -and (Test-Path -LiteralPath (Join-Path $candidate 'steam.exe') -PathType Leaf)) { return $candidate }
    }
    return $null
}

function Get-SteamLibraries([string]$SteamRoot) {
    $libraries = @($SteamRoot)
    $vdf = Join-Path $SteamRoot 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf -PathType Leaf) {
        try {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $path = $m.Groups[1].Value -replace '\\\\','\'
                if ($path) { $libraries += $path }
            }
        } catch {}
    }
    return @($libraries | Where-Object { $_ } | Select-Object -Unique)
}

function Test-GameRoot([string]$Path) {
    return [bool]($Path -and (Test-Path -LiteralPath (Join-Path $Path $GAME_EXE) -PathType Leaf))
}

function Find-GameRoot([string[]]$Libraries) {
    try {
        $recorded = (Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw).Trim()
        if (Test-GameRoot $recorded) { return $recorded }
    } catch {}
    foreach ($lib in $Libraries) {
        $candidate = "$($lib.TrimEnd('\'))\steamapps\common\Black Mesa"
        if (Test-GameRoot $candidate) { return $candidate }
    }
    return $null
}

function Get-ArchiveInputFolders {
    try {
        $workspace = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        return @(
            (Join-Path $workspace 'Archive Input\Black Mesa VR'),
            (Join-Path $workspace "Archive Input\Black Mesa VR\$PIN_TAG")
        )
    } catch { return @() }
}

function Get-LatestRelease {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" -Headers @{'User-Agent'='PCVR-Mods-Hub'} -TimeoutSec 25 -ErrorAction Stop
        if (-not $release.draft -and -not $release.prerelease) {
        $asset = @($release.assets | Where-Object {
            [string]$_.browser_download_url -and [string]$_.name -match '(?i)\.zip$'
        } | Sort-Object @{Expression={ if ([string]$_.name -match '(?i)(black.*mesa.*vr|drop.?in)') { 0 } else { 1 } }} | Select-Object -First 1)[0]
            if ($asset) {
                return [pscustomobject]@{ Tag=[string]$release.tag_name; Name=[string]$asset.name; Url=[string]$asset.browser_download_url }
            }
        }
    } catch { Write-Warn 'GitHub release lookup failed; using the last known stable asset URL.' }
    return [pscustomobject]@{ Tag=$PIN_TAG; Name=$PIN_NAME; Url=$PIN_URL }
}

function Get-ReleaseArchive([string]$Destination,$Release) {
    $found = Find-PredownloadedFile -Patterns @([string]$Release.Name) `
        -ExtraFolders (Get-ArchiveInputFolders) -Label "Black Mesa VR $($Release.Tag)"
    if ($found) { Copy-Item -LiteralPath $found -Destination $Destination -Force; return $Destination }
    if (-not (Invoke-SafeDownload -Urls @([string]$Release.Url) -Destination $Destination -Label "Black Mesa VR $($Release.Tag)" `
        -ManualUrl $RELEASES_URL)) { return $null }
    return $Destination
}

function Read-Manifest([string]$Path) {
    $map = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $map }
    try {
        foreach ($row in @((Get-Content -LiteralPath $Path -Raw) | ConvertFrom-Csv -Delimiter "`t")) {
            if ($row.RelativePath) { $map[[string]$row.RelativePath] = $row }
        }
    } catch {}
    return $map
}

function Save-Manifest([string]$Path,[hashtable]$Rows) {
    $lines = @("Component`tAction`tRelativePath`tInstalledSha256")
    foreach ($key in @($Rows.Keys | Sort-Object)) {
        $r = $Rows[$key]
        $lines += "$($r.Component)`t$($r.Action)`t$($r.RelativePath)`t$($r.InstalledSha256)"
    }
    [IO.File]::WriteAllLines($Path,[string[]]$lines,(New-Object Text.UTF8Encoding($false)))
}

function Install-Component([string]$Name,[string]$PayloadRoot,[string]$GameRoot,[hashtable]$Rows,[string[]]$KeepFiles=@()) {
    $backupRoot = Join-Path (Join-Path $GameRoot $BACKUP_NAME) 'original'
    $newPaths = New-Object 'System.Collections.Generic.List[string]'
    $prefix = $PayloadRoot.TrimEnd('\')
    foreach ($file in @(Get-ChildItem -LiteralPath $PayloadRoot -Recurse -File)) {
        $relative = $file.FullName.Substring($prefix.Length).TrimStart('\')
        [void]$newPaths.Add($relative)
        $destination = Join-Path $GameRoot $relative
        $parent = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        $keep = [bool]($KeepFiles | Where-Object { $_ -ieq $relative } | Select-Object -First 1)
        $old = if ($Rows.ContainsKey($relative)) { $Rows[$relative] } else { $null }
        $action = if ($old) { [string]$old.Action } else { 'remove' }
        if ($keep -and (Test-Path -LiteralPath $destination -PathType Leaf)) {
            $Rows[$relative] = [pscustomobject]@{ Component=$Name; Action='keep'; RelativePath=$relative; InstalledSha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash }
            Write-Info "Kept your existing setting: $relative"
            continue
        }
        if (-not $old -and (Test-Path -LiteralPath $destination -PathType Leaf)) {
            $backup = Join-Path $backupRoot $relative
            $backupParent = Split-Path -Parent $backup
            if (-not (Test-Path -LiteralPath $backupParent)) { New-Item -ItemType Directory -Path $backupParent -Force | Out-Null }
            Copy-Item -LiteralPath $destination -Destination $backup -Force
            $action = 'restore'
        } elseif ($old -and (Test-Path -LiteralPath $destination -PathType Leaf) -and [string]$old.Action -ne 'keep') {
            $currentHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
            if ($old.InstalledSha256 -and $currentHash -ne [string]$old.InstalledSha256) {
                $conflict = Join-Path (Join-Path $GameRoot '.pcvrhub-blackmesavr-conflicts') ($relative + '.' + (Get-Date -Format 'yyyyMMddHHmmss'))
                $conflictParent = Split-Path -Parent $conflict
                if (-not (Test-Path -LiteralPath $conflictParent)) { New-Item -ItemType Directory -Path $conflictParent -Force | Out-Null }
                Copy-Item -LiteralPath $destination -Destination $conflict -Force
                Write-Warn "Preserved a changed file before updating: $relative"
            }
        }
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
        $Rows[$relative] = [pscustomobject]@{ Component=$Name; Action=$(if ($keep) {'keep'} else {$action}); RelativePath=$relative; InstalledSha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash }
    }
    foreach ($key in @($Rows.Keys)) {
        $row = $Rows[$key]
        if ([string]$row.Component -ne $Name -or $newPaths.Contains([string]$key)) { continue }
        $target = Join-Path $GameRoot ([string]$key)
        if ([string]$row.Action -eq 'keep') { $Rows.Remove($key); continue }
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne [string]$row.InstalledSha256) { Write-Warn "Kept changed retired file: $key"; continue }
            if ([string]$row.Action -eq 'restore') {
                $backup = Join-Path $backupRoot ([string]$key)
                if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) { Write-Warn "Kept retired file because its original backup is missing: $key"; continue }
                Copy-Item -LiteralPath $backup -Destination $target -Force
            } else { Remove-Item -LiteralPath $target -Force }
        }
        $Rows.Remove($key)
    }
}

function Enable-LoadersForUpdate([string]$GameRoot) {
    $wasFlat = $false
    foreach ($relative in $LOADERS) {
        $on = Join-Path $GameRoot $relative
        $off = "$on.pcvrhub-off"
        if ((Test-Path -LiteralPath $on) -and (Test-Path -LiteralPath $off)) { throw "Both active and parked copies exist: $relative" }
        if (Test-Path -LiteralPath $off -PathType Leaf) {
            $wasFlat = $true
            Rename-Item -LiteralPath $off -NewName ([IO.Path]::GetFileName($on)) -Force
        }
    }
    return $wasFlat
}

function Disable-Loaders([string]$GameRoot) {
    foreach ($relative in $LOADERS) {
        $on = Join-Path $GameRoot $relative
        $off = "$on.pcvrhub-off"
        if (Test-Path -LiteralPath $on -PathType Leaf) {
            if (Test-Path -LiteralPath $off) { throw "Cannot preserve flat mode because the parking target already exists: $relative.pcvrhub-off" }
            Rename-Item -LiteralPath $on -NewName ([IO.Path]::GetFileName($off)) -Force
        }
    }
}

function Ensure-Autoexec([string]$GameRoot,[hashtable]$Rows) {
    $path = Join-Path $GameRoot $AUTOEXEC_REL
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $existed = Test-Path -LiteralPath $path -PathType Leaf
    $lines = if ($existed) { @(Get-Content -LiteralPath $path) } else { @() }
    if (-not @($lines | Where-Object { $_ -match '^\s*exec\s+bmvr\s*$' }).Count) {
        if ($lines.Count -and $lines[-1] -ne '') { $lines += '' }
        $lines += 'exec bmvr'
        [IO.File]::WriteAllLines($path,[string[]]$lines,(New-Object Text.UTF8Encoding($false)))
    }
    $previous = if ($Rows.ContainsKey($AUTOEXEC_REL)) { $Rows[$AUTOEXEC_REL] } else { $null }
    $action = if ($previous -and [string]$previous.Action -in @('remove-line','remove-file-if-only-line')) { [string]$previous.Action } elseif ($existed) { 'remove-line' } else { 'remove-file-if-only-line' }
    $Rows[$AUTOEXEC_REL] = [pscustomobject]@{ Component='Autoexec'; Action=$action; RelativePath=$AUTOEXEC_REL; InstalledSha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
}

function Install-LaunchLinks([string]$GameRoot,[string]$SteamRoot,[hashtable]$Rows,[string]$StageRoot) {
    $steamExe = Join-Path $SteamRoot 'steam.exe'
    $gameExe = Join-Path $GameRoot $GAME_EXE
    $linkRoot = Join-Path $StageRoot 'VRLaunch'
    New-Item -ItemType Directory -Path $linkRoot -Force | Out-Null
    $definitions = @(
        [pscustomobject]@{ Name='Black Mesa VR'; Args="-applaunch $APP_ID $LAUNCH_ARGS"; BlueShift=$false },
        [pscustomobject]@{ Name='Black Mesa Blue Shift VR'; Args="-applaunch $APP_ID $LAUNCH_ARGS -game bshift"; BlueShift=$true }
    )
    foreach ($def in $definitions) {
        $link = Join-Path $linkRoot ($def.Name + '.lnk')
        if (-not (New-DesktopShortcut -LnkPath $link -TargetPath $steamExe -WorkingDir $GameRoot -IconPath "$gameExe,0" -Arguments $def.Args -Description ("Launch " + $def.Name + ' through Steam'))) { throw "Could not create $($def.Name) launch link." }
    }
    Install-Component -Name 'LaunchTools' -PayloadRoot $StageRoot -GameRoot $GameRoot -Rows $Rows

    $statePath = Join-Path $GameRoot $SHORTCUT_STATE
    $oldState = @{}
    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        try { foreach ($row in @((Get-Content -LiteralPath $statePath -Raw) | ConvertFrom-Csv -Delimiter "`t")) { $oldState[[string]$row.Name] = $row } } catch {}
    }
    $stateLines = @("Name`tAction`tTarget`tArguments")
    $desktop = [Environment]::GetFolderPath('Desktop')
    foreach ($def in $definitions) {
        if ($def.BlueShift -and -not (Test-Path -LiteralPath (Join-Path $GameRoot 'bshift\gameinfo.txt') -PathType Leaf)) { continue }
        $desktopLink = Join-Path $desktop ($def.Name + '.lnk')
        $action = if ($oldState.ContainsKey($def.Name)) { [string]$oldState[$def.Name].Action } elseif (Test-Path -LiteralPath $desktopLink -PathType Leaf) { 'restore' } else { 'remove' }
        if (-not $oldState.ContainsKey($def.Name) -and $action -eq 'restore') {
            $backup = Join-Path (Join-Path $GameRoot $BACKUP_NAME) ('desktop-' + ($def.Name -replace '[^A-Za-z0-9]','_') + '.lnk')
            $backupParent = Split-Path -Parent $backup
            if (-not (Test-Path -LiteralPath $backupParent)) { New-Item -ItemType Directory -Path $backupParent -Force | Out-Null }
            Copy-Item -LiteralPath $desktopLink -Destination $backup -Force
        }
        if (-not (New-DesktopShortcut -LnkPath $desktopLink -TargetPath $steamExe -WorkingDir $GameRoot -IconPath "$gameExe,0" -Arguments $def.Args -Description ("Launch " + $def.Name + ' through Steam'))) { throw "Could not create the $($def.Name) desktop shortcut." }
        $stateLines += "$($def.Name)`t$action`t$steamExe`t$($def.Args)"
        Write-OK "Desktop shortcut created: $($def.Name)"
    }
    [IO.File]::WriteAllLines($statePath,[string[]]$stateLines,(New-Object Text.UTF8Encoding($false)))
}

$work = $null
$gamePath = $null
$restoreFlat = $false
try {
    Write-Header
    Write-Host ' This setup installs the current stable GitHub release into' -ForegroundColor White
    Write-Host ' the Steam version of Black Mesa and starts it through Steam.' -ForegroundColor White
    Write-Host ' If Black Mesa: Blue Shift is installed, the Hub also enables' -ForegroundColor Gray
    Write-Host ' its own start button and desktop shortcut.' -ForegroundColor Gray
    Write-Host ''
    Write-Host ' Close Black Mesa before continuing. Existing VR settings and' -ForegroundColor Yellow
    Write-Host ' replaced files are preserved for updates and safe removal.' -ForegroundColor Yellow
    Show-AntivirusNotice -Compact
    Pause-User 'Press Enter to proceed with setup...' | Out-Null

    Write-Step 1 5 'Locating Steam and Black Mesa'
    $steamRoot = Get-SteamInstall
    if (-not $steamRoot) { throw 'Steam was not found. Run Steam once, then start this installer again.' }
    $gamePath = Find-GameRoot (Get-SteamLibraries $steamRoot)
    if (-not (Test-GameRoot $gamePath)) {
        $picked = Get-GameFolderInteractive -GameName 'Black Mesa' -ProbeFile $GAME_EXE -ManualUrl 'https://store.steampowered.com/app/362890/Black_Mesa/'
        if ($picked -in @('quit','skip') -or -not (Test-GameRoot $picked)) { throw 'Setup cancelled before any game file was changed.' }
        $gamePath = (Get-Item -LiteralPath $picked).FullName
    }
    if (@(Get-Process -Name 'bms' -ErrorAction SilentlyContinue).Count) { throw 'Black Mesa is running. Close it completely and run setup again.' }
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.installed_path'),$gamePath,(New-Object Text.UTF8Encoding($false)))
    Write-OK "Found: $gamePath"

    Write-Step 2 5 'Getting the current stable VR release'
    $release = Get-LatestRelease
    Write-Info "Stable release: $($release.Tag)"
    $work = Join-Path $env:TEMP ('pcvr_blackmesa_' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $archive = Get-ReleaseArchive -Destination (Join-Path $work ([string]$release.Name)) -Release $release
    if (-not $archive) { throw 'Could not acquire the Black Mesa VR release.' }

    Write-Step 3 5 'Validating and extracting the release'
    $extract = Join-Path $work 'payload'
    $result = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'Black Mesa VR archive' -AllowSkip $false
    if ([string]$result -notin @('ok','manual','retry')) { throw 'The VR archive was not extracted.' }
    $payload = Get-ExtractedPayloadRoot -ExtractDir $extract -RelModFile 'BMVR_README.txt'
    foreach ($required in @('BMVR_README.txt','d3d9.dll','bin\d3d9.dll','bin\thirdparty\dxvk-windows-x86\d3d9.dll','VR\openxr_helper64\OpenXRHelper64.exe','VR\config.txt','bms\cfg\bmvr.cfg')) {
        if (-not (Test-Path -LiteralPath (Join-Path $payload $required))) { throw "Release is incomplete: missing $required" }
    }
    $fileCount = @(Get-ChildItem -LiteralPath $payload -Recurse -File).Count
    if ($fileCount -lt 20 -or $fileCount -gt 60) { throw "Unexpected release layout ($fileCount files)." }
    Write-OK "$fileCount release files validated."

    Write-Step 4 5 'Installing Black Mesa VR safely'
    $manifestPath = Join-Path $gamePath $MANIFEST_NAME
    $rows = Read-Manifest $manifestPath
    $restoreFlat = Enable-LoadersForUpdate $gamePath
    Install-Component -Name 'VR' -PayloadRoot $payload -GameRoot $gamePath -Rows $rows -KeepFiles @('VR\config.txt','VR\viewmodel_offsets.txt')
    Ensure-Autoexec -GameRoot $gamePath -Rows $rows
    $launchStage = Join-Path $work 'launch-tools'
    New-Item -ItemType Directory -Path $launchStage -Force | Out-Null
    Install-LaunchLinks -GameRoot $gamePath -SteamRoot $steamRoot -Rows $rows -StageRoot $launchStage
    Save-Manifest -Path $manifestPath -Rows $rows

    Write-Step 5 5 'Verifying the installed files'
    foreach ($required in @('VR\openxr_helper64\OpenXRHelper64.exe','bms\cfg\bmvr.cfg','VRLaunch\Black Mesa VR.lnk','VRLaunch\Black Mesa Blue Shift VR.lnk')) {
        if (-not (Test-Path -LiteralPath (Join-Path $gamePath $required) -PathType Leaf)) { throw "Installation verification failed: $required is missing." }
    }
    $binaryRelatives = @(Get-ChildItem -LiteralPath $payload -Recurse -File | Where-Object Extension -in @('.dll','.exe') | ForEach-Object { $_.FullName.Substring($payload.TrimEnd('\').Length).TrimStart('\') })
    $watchPaths = @($binaryRelatives | ForEach-Object { Join-Path $gamePath $_ })
    $archiveForRecovery = $archive
    $gameForRecovery = $gamePath
    $binaryRelativesForRecovery = @($binaryRelatives)
    $recoverBinaries = {
        $recoveryRoot = Join-Path $env:TEMP ('pcvr_blackmesa_recovery_' + [Guid]::NewGuid().ToString('N'))
        try {
            New-Item -ItemType Directory -Path $recoveryRoot -Force | Out-Null
            Expand-Archive -LiteralPath $archiveForRecovery -DestinationPath $recoveryRoot -Force
            $recoveryPayload = Get-ExtractedPayloadRoot -ExtractDir $recoveryRoot -RelModFile 'BMVR_README.txt'
            foreach ($relative in $binaryRelativesForRecovery) {
                $source = Join-Path $recoveryPayload $relative
                $target = Join-Path $gameForRecovery $relative
                if (-not (Test-Path -LiteralPath $target -PathType Leaf) -and (Test-Path -LiteralPath $source -PathType Leaf)) {
                    $parent = Split-Path -Parent $target
                    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
                    Copy-Item -LiteralPath $source -Destination $target -Force
                }
            }
        } finally {
            if (Test-Path -LiteralPath $recoveryRoot) { Remove-Item -LiteralPath $recoveryRoot -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }.GetNewClosure()
    if (-not (Confirm-PlacedFilesSurvive -Paths $watchPaths -GameDir $gamePath -Recopy $recoverBinaries)) { throw 'One or more required VR binaries did not survive the antivirus check.' }
    Save-InstalledStamp -GameDir $gamePath -Version ([string]$release.Tag) -HubDir $PSScriptRoot
    if ($restoreFlat) { Disable-Loaders $gamePath; $restoreFlat = $false; Write-Info 'Your previous Flat mode was preserved.' }
    Write-OK "Black Mesa VR $($release.Tag) installed."
    if (Test-Path -LiteralPath (Join-Path $gamePath 'bshift\gameinfo.txt') -PathType Leaf) { Write-OK 'Black Mesa: Blue Shift detected; its start option is ready.' }
    else { Write-Info 'Blue Shift was not detected. Install it and rerun setup to add its desktop shortcut.' }

    Write-Host ''
    Write-Host ' STARTING THE GAME' -ForegroundColor Cyan
    Write-Host ' Use Start in VR in the Hub, Steam, or the desktop shortcut.' -ForegroundColor White
    Write-Host ' Virtual Desktop: select VDXR. Meta Link uses the Oculus' -ForegroundColor Gray
    Write-Host ' OpenXR runtime. Do not run two OpenXR compositors together.' -ForegroundColor Gray
    Write-Host ''
    Write-Host " $QUIP" -ForegroundColor Magenta
} catch {
    Write-Host ''
    Write-Fail $_.Exception.Message
    throw
} finally {
    if ($restoreFlat -and $gamePath) { try { Disable-Loaders $gamePath } catch { Write-Warn 'Setup could not restore every parked loader; use the Hub Flat / VR switch after reviewing the files.' } }
    if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
Pause-User 'Press Enter to exit...' | Out-Null
