# ============================================================
# S.T.A.L.K.E.R. GAMMA VR v0.3.5 (Anomaly Gamma)
# ============================================================
# The current official package is supplied through the Anomaly VR Discord.
# A small update is valid only for a proven v0.3.4 installation. Every other
# state uses the complete v0.3.5 package. The implementation is deliberately
# library-testable; set PCVR_ANOMALYGAMMA_LIBRARY_ONLY=1 before dot-sourcing.
# ============================================================

. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')

$script:GammaCurrentVersion = '0.3.5'
$script:GammaFolderName = 'Gamma VR'
$script:GammaPreferredFolderName = 'GammaVR'
$script:GammaLaunchFile = 'GAMMA VR.bat'
$script:GammaInviteUrl = 'https://discord.gg/kGhd7GvJ5F'
$script:GammaDownloadPostUrl = 'https://discord.com/channels/1495664880311734313/1511657141990199356/1552472577023156304'
$script:QBitTorrentUrl = 'https://www.qbittorrent.org/download'
$script:GammaUpdatePayloadGroups = @(
    'GAMMA VR.bat',
    'profiles\GAMMA VR v0.3.5 - AOEVR v0.5.0\modlist.txt',
    'profiles\GAMMA VR v0.3.5 - AOEVR v0.5.0 - NITROYUASH\modlist.txt',
    'mods\Wearable Devices Armor Swap Crash Guard v1.1 by HEKPOTEXHAPb\meta.ini',
    'mods\Wearable Devices PDA Messages v7.4.4 - VR Version realzelda414\meta.ini',
    'mods\WearableDevices 0.8.10 by Sulik, Jeremussy, Wiarubane\meta.ini',
    'mods\WearableDevices 0.8.10 VR fixes v5 by NITROYUASH, Marsy\meta.ini',
    'mods\GAMMA VR Inventory Actions and Fixes v2.3 - NITROYUASH\gamedata\scripts\vr_2d_actions.script',
    'mods\VR More Actions v9 - NITROYUASH\gamedata\scripts\vr_anomaly_new_inputs.script',
    'mods\Z.H.O.P.A. v2.3\meta.ini'
)
$script:GammaBasePayloadGroups = @('ModOrganizer.exe','STALKERVR_GAMMA\bin\AnomalyDX11.exe')
$script:GammaContract = New-PCVRInstallerContract -Id 'anomaly-gamma' -GameName 'Anomaly GAMMA VR' `
    -Acquisition Discord -Routes @('CurrentFull','UpdateFrom0.3.4') `
    -DiscordInviteUrl $script:GammaInviteUrl -DiscordDownloadUrl $script:GammaDownloadPostUrl -AntivirusNotice `
    -RequiredInstalledFileGroups @($script:GammaUpdatePayloadGroups + $script:GammaBasePayloadGroups + @('mods\GAMMA VR Manual Reload Project v5 by killua._.107\meta.ini'))

function Write-GammaHeader {
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host '  S.T.A.L.K.E.R. GAMMA VR Installer' -ForegroundColor Cyan
    Write-Host '  Current package v0.3.5 - Wearable Devices PDA gestures' -ForegroundColor Gray
    Write-Host '============================================================' -ForegroundColor Magenta
}

function Write-GammaStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''
    Write-Host ("--- [{0}/{1}] {2} ---" -f $Number,$Total,$Text) -ForegroundColor Cyan
    Write-Host '------------------------------------------------------------' -ForegroundColor DarkGray
}

function Write-GammaOk([string]$Text) { Write-Host "[OK] $Text" -ForegroundColor Green }
function Write-GammaInfo([string]$Text) { Write-Host "[..] $Text" -ForegroundColor Gray }
function global:Write-GammaWarn([string]$Text) { Write-Host "[!!] $Text" -ForegroundColor Yellow }

function Get-GammaInstalledVersion([string]$InstallPath) {
    if (-not $InstallPath -or -not (Test-Path -LiteralPath ([IO.Path]::Combine($InstallPath,$script:GammaLaunchFile)) -PathType Leaf -ErrorAction SilentlyContinue)) { return '' }
    foreach ($stampName in @('gamma_vr_version.txt','.pcvrhub_version')) {
        $stamp = Join-Path $InstallPath $stampName
        if (Test-Path -LiteralPath $stamp -PathType Leaf -ErrorAction SilentlyContinue) {
            try {
                $value = (Get-Content -LiteralPath $stamp -Raw -ErrorAction Stop).Trim()
                if ($value -match '(?i)(?:^|[^0-9])v?(0\.3\.[0-9]+[a-z]?)(?:$|[^0-9])') { return $matches[1] }
            } catch {}
        }
    }
    $profiles = Join-Path $InstallPath 'profiles'
    if (Test-Path -LiteralPath $profiles -PathType Container -ErrorAction SilentlyContinue) {
        $versions = @(Get-ChildItem -LiteralPath $profiles -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -match '(?i)GAMMA VR v(0\.3\.[0-9]+[a-z]?)') { $matches[1] }
        })
        if ($versions -contains '0.3.5') { return '0.3.5' }
        if ($versions -contains '0.3.4') { return '0.3.4' }
        if ($versions -contains '0.3.3') { return '0.3.3' }
        if ($versions.Count -gt 0) { return [string]$versions[0] }
    }
    return 'unknown'
}

function Get-GammaKnownInstallPath {
    $candidates = New-Object System.Collections.Generic.List[string]
    try {
        $located = Get-HubLocatedGameFolder -GameId 'anomaly-gamma' -ProbeFiles @($script:GammaLaunchFile)
        if ($located) { [void]$candidates.Add($located) }
    } catch {}
    $receipt = Join-Path $PSScriptRoot '.installed_path'
    if (Test-Path -LiteralPath $receipt -PathType Leaf -ErrorAction SilentlyContinue) {
        try {
            $recorded = (Get-Content -LiteralPath $receipt -Raw -ErrorAction Stop).Trim().Trim('"')
            if ($recorded) { [void]$candidates.Add($recorded) }
        } catch {}
    }
    foreach ($root in @('C:\Games','D:\Games','E:\Games')) {
        [void]$candidates.Add([IO.Path]::Combine($root,$script:GammaPreferredFolderName))
        [void]$candidates.Add([IO.Path]::Combine($root,$script:GammaFolderName))
    }
    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        if (Test-Path -LiteralPath ([IO.Path]::Combine($candidate,$script:GammaLaunchFile)) -PathType Leaf -ErrorAction SilentlyContinue) {
            return [IO.Path]::GetFullPath($candidate)
        }
    }
    return ''
}

function Resolve-GammaInstallPath([string]$InputPath,[string]$DefaultPath) {
    $value = ('' + $InputPath).Trim().Trim('"').Trim("'")
    if (-not $value) { $value = $DefaultPath }
    if (-not $value) { $value = 'C:\Games\GammaVR' }
    $full = [IO.Path]::GetFullPath($value)
    if ((Split-Path $full -Leaf) -in @($script:GammaFolderName,$script:GammaPreferredFolderName,'GAMMA_VR') -or
        (Test-Path -LiteralPath ([IO.Path]::Combine($full,$script:GammaLaunchFile)) -PathType Leaf -ErrorAction SilentlyContinue)) {
        return $full.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
    }
    return ([IO.Path]::Combine($full,$script:GammaPreferredFolderName)).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
}

function Test-GammaWritableParent([string]$InstallPath) {
    try {
        $parent = Split-Path -Parent ([IO.Path]::GetFullPath($InstallPath))
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void][IO.Directory]::CreateDirectory($parent) }
        $probe = Join-Path $parent ('.pcvr-gamma-write-' + [Guid]::NewGuid().ToString('N') + '.tmp')
        [IO.File]::WriteAllText($probe,'ok',(New-Object Text.UTF8Encoding $false))
        Remove-Item -LiteralPath $probe -Force -ErrorAction Stop
        return $true
    } catch { return $false }
}

function Test-GammaUpdateBase([string]$InstallPath) {
    if ((Get-GammaInstalledVersion -InstallPath $InstallPath) -ne '0.3.4') { return $false }
    foreach ($relative in @('GAMMA VR.bat','ModOrganizer.exe','STALKERVR_GAMMA\bin\AnomalyDX11.exe',
                            'mods\GAMMA VR Manual Reload Project v5 by killua._.107\meta.ini')) {
        if (-not (Test-Path -LiteralPath (Join-Path $InstallPath $relative) -PathType Leaf)) { return $false }
    }
    foreach ($profile in @('GAMMA VR v0.3.4 - AOEVR v0.5.0','GAMMA VR v0.3.4 - AOEVR v0.5.0 - NITROYUASH')) {
        if (Test-Path -LiteralPath (Join-Path $InstallPath "profiles\$profile\modlist.txt") -PathType Leaf) { return $true }
    }
    return $false
}

function Get-GammaPayloadGroups([ValidateSet('CurrentFull','UpdateFrom0.3.4')][string]$Route) {
    if ($Route -eq 'CurrentFull') { return @($script:GammaUpdatePayloadGroups + $script:GammaBasePayloadGroups + @('mods\GAMMA VR Manual Reload Project v5 by killua._.107\meta.ini')) }
    return @($script:GammaUpdatePayloadGroups)
}

function global:Test-GammaArchive {
    param(
        [Parameter(Mandatory=$true)][string]$ArchivePath,
        [Parameter(Mandatory=$true)][ValidateSet('CurrentFull','UpdateFrom0.3.4')][string]$Route,
        [Parameter(Mandatory=$true)][string]$SevenZip,
        [switch]$Quiet
    )
    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf -ErrorAction SilentlyContinue)) { return $false }
    $layout = Get-ArchiveTopLevel -ArchivePath $ArchivePath -SevenZip $SevenZip
    if (-not $layout.Ok -or @($layout.Entries).Count -eq 0) {
        if (-not $Quiet) { Write-GammaWarn 'The file is not a completed, readable archive yet. If it is downloading through a torrent, let it finish first.' }
        return $false
    }
    $entries = @($layout.Entries | ForEach-Object { ('' + $_).Replace('/','\') })
    foreach ($entry in $entries) {
        $parts = @($entry -split '\\' | Where-Object { $_ })
        if ([IO.Path]::IsPathRooted($entry) -or $entry -match ':' -or $parts -contains '..') {
            if (-not $Quiet) { Write-GammaWarn "Unsafe archive path rejected: $entry" }
            return $false
        }
    }
    $has = {
        param([string]$Suffix)
        $needle = $Suffix.Replace('/','\')
        return @($entries | Where-Object { $_ -ieq $needle -or $_.EndsWith(('\' + $needle),[StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
    }
    foreach ($group in @(Get-GammaPayloadGroups -Route $Route)) {
        if (-not (& $has $group)) {
            if (-not $Quiet) { Write-GammaWarn "The $Route archive is missing a required v0.3.5 payload file: $group" }
            return $false
        }
    }
    return $true
}

function Get-GammaPayloadRoot([string]$ExtractRoot) {
    $root = Get-ExtractedPayloadRoot -ExtractDir $ExtractRoot -RelModFile $script:GammaLaunchFile
    if (-not $root -or -not (Test-Path -LiteralPath (Join-Path $root $script:GammaLaunchFile) -PathType Leaf)) { throw 'The extracted GAMMA VR payload root could not be found.' }
    return [IO.Path]::GetFullPath($root)
}

function Assert-GammaPathInside([string]$Path,[string]$Root,[switch]$AllowRoot) {
    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
    if (($AllowRoot -and $fullPath.Equals($fullRoot,[StringComparison]::OrdinalIgnoreCase)) -or $fullPath.StartsWith(($fullRoot + [IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)) { return $true }
    throw "Path escapes its transaction root: $Path"
}

function Get-GammaNativePath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if ($full.StartsWith('\\?\')) { return $full }
    if ($full.StartsWith('\\')) { return '\\?\UNC\' + $full.Substring(2) }
    return '\\?\' + $full
}

function Copy-GammaFile([string]$Source,[string]$Destination) {
    $parent = Split-Path -Parent $Destination
    [void][IO.Directory]::CreateDirectory((Get-GammaNativePath $parent))
    [IO.File]::Copy((Get-GammaNativePath $Source),(Get-GammaNativePath $Destination),$true)
}

function Test-GammaFile([string]$Path) {
    return [IO.File]::Exists((Get-GammaNativePath $Path))
}

function Remove-GammaFile([string]$Path) {
    [IO.File]::Delete((Get-GammaNativePath $Path))
}

function Install-GammaFullPayload {
    param([Parameter(Mandatory=$true)][string]$PayloadRoot,[Parameter(Mandatory=$true)][string]$InstallPath)
    $gamesRoot = Split-Path -Parent $InstallPath
    [void](Assert-GammaPathInside -Path $PayloadRoot -Root $gamesRoot)
    [void](Assert-GammaPathInside -Path $InstallPath -Root $gamesRoot)
    $backupPath = ''
    if (Test-Path -LiteralPath $InstallPath -PathType Container) {
        $backupBase = Join-Path $gamesRoot '.pcvrhub-backups\Anomaly Gamma'
        [void][IO.Directory]::CreateDirectory($backupBase)
        $backupPath = Join-Path $backupBase ((Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8) + '-before-v0.3.5')
        Move-Item -LiteralPath $InstallPath -Destination $backupPath -ErrorAction Stop
    }
    try {
        Move-Item -LiteralPath $PayloadRoot -Destination $InstallPath -ErrorAction Stop
        return [pscustomobject]@{ BackupPath=$backupPath; Rollback={
            if (Test-Path -LiteralPath $InstallPath -PathType Container) { Remove-Item -LiteralPath $InstallPath -Recurse -Force -ErrorAction SilentlyContinue }
            if ($backupPath -and (Test-Path -LiteralPath $backupPath -PathType Container)) { Move-Item -LiteralPath $backupPath -Destination $InstallPath -ErrorAction SilentlyContinue }
        }.GetNewClosure() }
    } catch {
        if ($backupPath -and -not (Test-Path -LiteralPath $InstallPath) -and (Test-Path -LiteralPath $backupPath -PathType Container)) { Move-Item -LiteralPath $backupPath -Destination $InstallPath -ErrorAction SilentlyContinue }
        throw
    }
}

function Install-GammaUpdatePayload {
    param([Parameter(Mandatory=$true)][string]$PayloadRoot,[Parameter(Mandatory=$true)][string]$InstallPath)
    if (-not (Test-GammaUpdateBase -InstallPath $InstallPath)) { throw 'A complete v0.3.4 base installation is required for this small update.' }
    $backupRoot = Join-Path $InstallPath ('.pcvrhub_gamma_backups\v0.3.4-before-v0.3.5-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    [void][IO.Directory]::CreateDirectory($backupRoot)
    $records = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($source in @(Get-ChildItem -LiteralPath $PayloadRoot -Recurse -File -Force -ErrorAction Stop)) {
            $relative = $source.FullName.Substring($PayloadRoot.Length).TrimStart('\','/')
            $target = Join-Path $InstallPath $relative
            [void](Assert-GammaPathInside -Path $target -Root $InstallPath)
            $hadOriginal = Test-GammaFile $target
            if ($hadOriginal) {
                $backupFile = Join-Path $backupRoot $relative
                Copy-GammaFile -Source $target -Destination $backupFile
            }
            [void]$records.Add([pscustomobject]@{ Path=$relative; HadOriginal=[bool]$hadOriginal })
            Copy-GammaFile -Source $source.FullName -Destination $target
        }
        $manifestPath = Join-Path $backupRoot 'ownership-manifest.json'
        Write-PCVRAtomicText -Path $manifestPath -Value ($records.ToArray() | ConvertTo-Json -Depth 3)
        $nativePath = {
            param([string]$Path)
            $full = [IO.Path]::GetFullPath($Path)
            if ($full.StartsWith('\\?\')) { return $full }
            if ($full.StartsWith('\\')) { return '\\?\UNC\' + $full.Substring(2) }
            return '\\?\' + $full
        }.GetNewClosure()
        $rollback = {
            foreach ($record in $records.ToArray()) {
                $target = Join-Path $InstallPath ([string]$record.Path)
                $backupFile = Join-Path $backupRoot ([string]$record.Path)
                $nativeTarget = & $nativePath $target
                $nativeBackup = & $nativePath $backupFile
                if ([bool]$record.HadOriginal -and [IO.File]::Exists($nativeBackup)) {
                    [void][IO.Directory]::CreateDirectory((& $nativePath (Split-Path -Parent $target)))
                    [IO.File]::Copy($nativeBackup,$nativeTarget,$true)
                } elseif ([IO.File]::Exists($nativeTarget)) { [IO.File]::Delete($nativeTarget) }
            }
        }.GetNewClosure()
        return [pscustomobject]@{ BackupPath=$backupRoot; Rollback=$rollback; FileCount=$records.Count }
    } catch {
        foreach ($record in $records.ToArray()) {
            $target = Join-Path $InstallPath ([string]$record.Path)
            $backupFile = Join-Path $backupRoot ([string]$record.Path)
            if ([bool]$record.HadOriginal -and (Test-GammaFile $backupFile)) { Copy-GammaFile -Source $backupFile -Destination $target }
            elseif (Test-GammaFile $target) { Remove-GammaFile $target }
        }
        throw
    }
}

function Move-GammaShaderCachesToBackup {
    param([Parameter(Mandatory=$true)][string]$InstallPath,[Parameter(Mandatory=$true)][string]$BackupRoot)
    $moves = New-Object System.Collections.Generic.List[object]
    $shaderCache = Join-Path $InstallPath 'STALKERVR_GAMMA\appdata\shaders_cache'
    foreach ($cache in @(Get-Item -LiteralPath $shaderCache -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer })) {
        [void](Assert-GammaPathInside -Path $cache.FullName -Root $InstallPath)
        $destinationRoot = Join-Path $BackupRoot 'removed-shader-cache'
        [void][IO.Directory]::CreateDirectory($destinationRoot)
        $destination = Join-Path $destinationRoot ([Guid]::NewGuid().ToString('N'))
        Move-Item -LiteralPath $cache.FullName -Destination $destination -ErrorAction Stop
        [void]$moves.Add([pscustomobject]@{ Original=$cache.FullName; Backup=$destination })
    }
    return $moves.ToArray()
}

function Set-GammaEnglishLanguage([string]$InstallPath) {
    $localization = Join-Path $InstallPath 'overwrite\gamedata\configs\localization.ltx'
    if (-not (Test-Path -LiteralPath $localization -PathType Leaf)) { return $false }
    $encoding = [Text.Encoding]::GetEncoding(28591)
    $text = $encoding.GetString([IO.File]::ReadAllBytes($localization))
    $updated = $text -replace '(?m)^(\s*language\s*=\s*)rus\b','${1}eng'
    [IO.File]::WriteAllBytes($localization,$encoding.GetBytes($updated))
    return $true
}

if ($env:PCVR_ANOMALYGAMMA_LIBRARY_ONLY -eq '1') { return }

$installCommitted = $false
$exitCode = 0
try {
    Write-GammaHeader
    Write-Host '  GAMMA VR v0.3.5 moves PDA messages to the Promin wrist display' -ForegroundColor White
    Write-Host '  and adds touch and Up/Down gestures for its screens and messages.' -ForegroundColor White
    Write-Host '  The complete standalone package needs at least 110 GB free.' -ForegroundColor Yellow
    Write-Host '  It may currently be offered as a torrent. qBittorrent is the recommended' -ForegroundColor Gray
    Write-Host '  free, open-source, ad-free client: https://www.qbittorrent.org/download' -ForegroundColor Gray
    Write-Host '  Only a complete v0.3.4 install can use the small v0.3.5 update.' -ForegroundColor Gray
    Show-AntivirusNotice -Compact
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start setup.')

    Write-GammaStep 1 5 'Choosing and checking the install folder'
    $knownPath = Get-GammaKnownInstallPath
    $defaultPath = if ($knownPath) { $knownPath } else { 'C:\Games\GammaVR' }
    Write-Host "  Press Enter for: $defaultPath" -ForegroundColor White
    Write-Host '  Or enter the existing Gamma VR folder / a Games root without spaces.' -ForegroundColor Gray
    $enteredPath = Read-Host '  Install path'
    $installPath = Resolve-GammaInstallPath -InputPath $enteredPath -DefaultPath $defaultPath
    if (-not (Test-GammaWritableParent -InstallPath $installPath)) { throw "The install parent is not writable: $(Split-Path -Parent $installPath)" }
    $installedVersion = Get-GammaInstalledVersion -InstallPath $installPath
    $hasInstall = Test-Path -LiteralPath (Join-Path $installPath $script:GammaLaunchFile) -PathType Leaf
    if ($hasInstall) { Write-GammaOk "Found GAMMA VR $installedVersion at $installPath" }
    else { Write-GammaInfo "The complete package will be installed at $installPath" }

    $route = 'CurrentFull'
    if ($installedVersion -eq '0.3.4' -and (Test-GammaUpdateBase -InstallPath $installPath)) {
        Write-Host ''
        Write-Host '  [1] Update v0.3.4 to v0.3.5 (recommended)' -ForegroundColor Green
        Write-Host '  [2] Replace it with the complete v0.3.5 package' -ForegroundColor Gray
        $choice = (Read-Host '  Press Enter for 1, or type 2').Trim()
        if (-not $choice -or $choice -eq '1') { $route = 'UpdateFrom0.3.4' }
        elseif ($choice -ne '2') { throw 'Setup stopped because no valid route was selected.' }
    } elseif ($hasInstall) {
        Write-GammaWarn $(if ($installedVersion -eq '0.3.5') { 'v0.3.5 is already recorded; a repair needs the complete package.' } else { "Only a complete v0.3.4 base can use the small update. The detected '$installedVersion' installation needs the complete package." })
    }

    if ($route -eq 'CurrentFull') {
        Write-Host ''
        Write-Host '  Download from the official Discord post. If it offers only a .torrent,' -ForegroundColor White
        Write-Host '  use qBittorrent to finish STALKER GAMMA VR v0.3.5.7z first.' -ForegroundColor Gray
        $qbitChoice = (Read-Host '  Press Enter to continue, or type Q to open the official qBittorrent page').Trim()
        if ($qbitChoice -match '^(?i)q$') {
            Start-Process $script:QBitTorrentUrl -ErrorAction Stop | Out-Null
            [void](Wait-PCVRExplicitEnter -Message 'After installing qBittorrent, press Enter to continue to Discord.')
        } elseif ($qbitChoice) { throw 'Setup stopped because no valid choice was selected.' }
    }

    Write-GammaStep 2 5 'Getting the official GAMMA VR v0.3.5 package'
    $sevenZip = Get-SevenZip -Required
    if (-not $sevenZip) { throw '7-Zip is required to read and extract the GAMMA VR package.' }
    $patterns = if ($route -eq 'UpdateFrom0.3.4') { @('UPDATE FROM v0.3.4 to v0.3.5.7z','*UPDATE*0.3.4*0.3.5*.7z') } else { @('STALKER GAMMA VR v0.3.5.7z','*STALKER*GAMMA*VR*v0.3.5*.7z') }
    $routeForValidator = $route
    $sevenZipForValidator = $sevenZip
    $validator = { param($path) Test-GammaArchive -ArchivePath $path -Route $routeForValidator -SevenZip $sevenZipForValidator }.GetNewClosure()
    $archive = Invoke-PCVRDiscordDownloadFlow -Label 'GAMMA VR v0.3.5' -InviteUrl $script:GammaInviteUrl `
        -DownloadPostUrl $script:GammaDownloadPostUrl -FilePatterns $patterns `
        -SourceDescription 'provided through the official Anomaly VR Discord post' -ValidateCandidate $validator
    if (-not $archive) { throw 'Setup was cancelled before a usable archive was supplied.' }
    while ($true) {
        Write-Host "  Selected: $archive" -ForegroundColor White
        $selection = ([string](Read-Host '  Use this file? [Y]es, [P]aste another file path, [C]ancel')).Trim().ToUpperInvariant()
        if ($selection -eq 'Y') { break }
        if ($selection -eq 'C') { throw 'Setup was cancelled before installation.' }
        if ($selection -eq 'P') {
            $manual = ([string](Read-Host '  Full path to the downloaded 7z file')).Trim().Trim('"')
            if ($manual -and (Test-GammaArchive -ArchivePath $manual -Route $route -SevenZip $sevenZip)) { $archive = [IO.Path]::GetFullPath($manual); continue }
            Write-GammaWarn 'That file is not a readable package for the selected route.'
        }
    }
    Write-GammaOk "Readable $route package selected: $(Split-Path $archive -Leaf)"

    Write-GammaStep 3 5 'Staging and verifying the package before installation'
    $gamesRoot = Split-Path -Parent $installPath
    $stageRoot = Join-Path $gamesRoot ('.pcvr-gamma-stage-' + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($stageRoot)
    if (-not (Expand-7zWithProgress -SevenZip $sevenZip -Archive $archive -Dest $stageRoot -Label 'GAMMA VR v0.3.5')) { throw '7-Zip could not extract the selected archive.' }
    $payloadRoot = Get-GammaPayloadRoot -ExtractRoot $stageRoot
    if (-not (Test-GammaArchive -ArchivePath $archive -Route $route -SevenZip $sevenZip -Quiet)) { throw 'The staged package no longer matches the selected installation route.' }
    foreach ($group in @(Get-GammaPayloadGroups -Route $route)) {
        $found = $false
        foreach ($relative in @(($group -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
            if (Test-Path -LiteralPath (Join-Path $payloadRoot $relative) -PathType Leaf) { $found = $true; break }
        }
        if (-not $found) { throw "The staged package is incomplete: $group" }
    }
    Write-GammaOk 'The staged v0.3.5 payload and safe archive paths were verified.'

    Write-GammaStep 4 5 $(if ($route -eq 'UpdateFrom0.3.4') { 'Applying the recoverable v0.3.4 to v0.3.5 update' } else { 'Installing the complete recoverable v0.3.5 package' })
    $installResult = if ($route -eq 'UpdateFrom0.3.4') { Install-GammaUpdatePayload -PayloadRoot $payloadRoot -InstallPath $installPath } else { Install-GammaFullPayload -PayloadRoot $payloadRoot -InstallPath $installPath }
    try {
        if ($route -eq 'UpdateFrom0.3.4') {
            $cacheMoves = @(Move-GammaShaderCachesToBackup -InstallPath $installPath -BackupRoot $installResult.BackupPath)
            if ($cacheMoves.Count -gt 0) {
                $payloadRollback = $installResult.Rollback
                $cacheMovesForRollback = $cacheMoves
                $installResult.Rollback = {
                    & $payloadRollback
                    foreach ($cacheMove in $cacheMovesForRollback) {
                        if (Test-Path -LiteralPath $cacheMove.Backup -PathType Container) {
                            $parent = Split-Path -Parent $cacheMove.Original
                            if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void][IO.Directory]::CreateDirectory($parent) }
                            Move-Item -LiteralPath $cacheMove.Backup -Destination $cacheMove.Original -ErrorAction SilentlyContinue
                        }
                    }
                }.GetNewClosure()
            }
            Write-GammaOk $(if ($cacheMoves.Count -gt 0) { "Moved $($cacheMoves.Count) obsolete shader cache folder(s) into the recovery backup." } else { 'No obsolete shader cache folder was present.' })
        }
        [void](Complete-PCVRInstallTransaction -Contract $script:GammaContract -GameDir $installPath -Version $script:GammaCurrentVersion `
            -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) `
            -AdditionalVersionReceiptPaths @((Join-Path $installPath 'gamma_vr_version.txt')) -Route $route)
        $installCommitted = $true
    } catch {
        if ($installResult -and $installResult.Rollback) { & $installResult.Rollback }
        throw
    }
    if ($installResult.BackupPath) { Write-GammaInfo "Previous files remain recoverable at: $($installResult.BackupPath)" }
    if (Set-GammaEnglishLanguage -InstallPath $installPath) { Write-GammaOk 'Language set to English without changing the file encoding.' }

    $iconSource = Join-Path $PSScriptRoot 'GammaVR.ico'
    $iconDest = Join-Path $installPath 'GammaVR.ico'
    if (Test-Path -LiteralPath $iconSource -PathType Leaf) { Copy-Item -LiteralPath $iconSource -Destination $iconDest -Force -ErrorAction SilentlyContinue }
    $desktop = [Environment]::GetFolderPath('Desktop')
    if ($desktop) {
        try {
            $launchPath = Join-Path $installPath $script:GammaLaunchFile
            [void](New-DesktopShortcut -LnkPath (Join-Path $desktop 'Anomaly Gamma.lnk') -TargetPath $launchPath -WorkingDir $installPath -IconPath $(if (Test-Path -LiteralPath $iconDest) { $iconDest } else { "$launchPath,0" }))
            Write-GammaOk 'Desktop shortcut created or refreshed.'
        } catch { Write-GammaWarn 'The desktop shortcut could not be created; use GAMMA VR.bat or Start in VR.' }
    }

    if (Test-Path -LiteralPath $stageRoot -PathType Container) { Remove-Item -LiteralPath $stageRoot -Recurse -Force -ErrorAction SilentlyContinue }

    Write-GammaStep 5 5 'First launch after v0.3.5'
    Write-Host '  The official instructions require GAMMA VR.bat to run at least once.' -ForegroundColor White
    Write-Host '  It regenerates ModOrganizer.ini for the v0.3.5 profile.' -ForegroundColor White
    Write-Host '  A black headset for 10-15 seconds during startup/loading is normal.' -ForegroundColor Gray
    do {
        $launchChoice = (Read-Host '  Press Enter to launch now, or type C to run it yourself later').Trim()
        if ($launchChoice -and $launchChoice -ine 'C') {
            Write-GammaWarn 'Choose Enter to launch or C to run it later.'
        }
    } while ($launchChoice -and $launchChoice -ine 'C')
    if (-not $launchChoice) {
        Start-Process -FilePath (Join-Path $installPath $script:GammaLaunchFile) -WorkingDirectory $installPath -ErrorAction Stop | Out-Null
        Write-GammaOk 'GAMMA VR.bat started.'
    } else {
        Write-GammaWarn 'GAMMA VR.bat was not started by setup. Run it once before playing.'
    }

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host '  GAMMA VR v0.3.5 files are installed and recorded.' -ForegroundColor Green
    Write-Host '  Promin messages and gestures are included; first run is required.' -ForegroundColor Gray
    Write-Host '============================================================' -ForegroundColor Magenta
} catch {
    $exitCode = 1
    Write-Host ''
    Write-GammaWarn ("Setup stopped safely: " + $_.Exception.Message)
    if ($installCommitted) {
        Write-Host '  The v0.3.5 files were recorded. Run GAMMA VR.bat manually to finish its required first launch.' -ForegroundColor Gray
    } else {
        Write-Host '  No successful v0.3.5 receipt was written for an incomplete install.' -ForegroundColor Gray
    }
} finally {
    Write-Host ''
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close the installer.')
}
if ($exitCode -ne 0) { exit $exitCode }
