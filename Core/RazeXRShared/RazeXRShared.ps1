# ============================================================
# RazeXR PCVR - shared installer for seven Build-engine games
# ============================================================

$script:RazeSharedRoot = $PSScriptRoot
$script:RazeRepo = 'GameOrDie007/RazeXR-PCVR'
$script:RazeReleasesUrl = 'https://github.com/GameOrDie007/RazeXR-PCVR/releases'
$script:RazeFallbackTag = 'v1.0'
$script:RazeFallbackUrl = 'https://github.com/GameOrDie007/RazeXR-PCVR/releases/download/v1.0/RazeXR-PCVR.zip'
$script:RazeDefaultRoot = 'C:\Games\RazeXR PCVR'
$script:RazeCoreRoot = Split-Path -Parent $script:RazeSharedRoot
if (-not (Get-Command Install-OwnedModPayload -ErrorAction SilentlyContinue)) {
    . (Join-Path $script:RazeCoreRoot 'Modules\OwnedModFiles.ps1')
}

function Write-RazeStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''
    Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan
    Write-Host ''
}
function Write-RazeInfo([string]$Text) { Write-Host "  [..] $Text" -ForegroundColor Gray }
function Write-RazeOK([string]$Text)   { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-RazeWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }
function Pause-Raze([string]$Text='Press Enter to continue...') {
    [void](Wait-PCVRExplicitEnter -Message $Text)
}

function Get-RazeGameDefinition([string]$Family) {
    $definitions = @{
        duke = @{
            Family='duke'; Display='Duke Nukem 3D'; HubId='duke-nukem-3d-vr'; Shortcut='Duke Nukem 3D VR'
            IconFile='DukeNukem3D_VR.ico'
            Quip='Come get some, now with both hands in virtual reality.'
            SteamAppIds=@('434050','225140'); SteamFolders=@('Duke Nukem 3D Twentieth Anniversary World Tour','Duke Nukem 3D')
            GogNames=@('Duke Nukem 3D'); ExtraRoots=@('C:\ZOOM PLATFORM\Gearbox Software\Duke Nukem 3D - Atomic Edition')
            DataFolders=@('duke'); Markers=@('games\duke\DUKE3D.GRP')
            LauncherInclude='(?i)^Duke Nukem 3D.* VR\.bat$'
            LauncherExclude='(?i)(Duke it out|Caribbean|Nuclear Winter|Duke!ZONE|Penthouse)'
        }
        blood = @{
            Family='blood'; Display='Blood'; HubId='blood-vr'; Shortcut='Blood VR'
            IconFile='Blood_VR.ico'
            Quip='Caleb is back, and the cult has nowhere left to hide.'
            SteamAppIds=@('299030'); SteamFolders=@('One Unit Whole Blood'); GogNames=@('One Unit Whole Blood'); ExtraRoots=@()
            DataFolders=@('blood'); Markers=@('games\blood\BLOOD.RFF')
            LauncherInclude='(?i)^BLOOD.* VR\.bat$'; LauncherExclude='(?i)Cryptic Passage'
        }
        shadowwarrior = @{
            Family='shadowwarrior'; Display='Shadow Warrior'; HubId='shadow-warrior-vr'; Shortcut='Shadow Warrior VR'
            IconFile='ShadowWarrior_VR.ico'
            Quip='Lo Wang brings the sword, you bring the hands.'
            SteamAppIds=@('225160','238070'); SteamFolders=@('Shadow Warrior Classic','Shadow Warrior Original')
            GogNames=@('Shadow Warrior Classic Redux','Shadow Warrior Classic Complete'); ExtraRoots=@()
            DataFolders=@('shadowwarrior'); Markers=@('games\shadowwarrior\SW.GRP')
            LauncherInclude='(?i)^Shadow Warrior.* VR\.bat$'; LauncherExclude='(?i)(Wanton Destruction|Twin Dragon)'
        }
        redneck = @{
            Family='redneck'; Display='Redneck Rampage'; HubId='redneck-rampage-vr'; Shortcut='Redneck Rampage VR'
            IconFile='RedneckRampage_VR.ico'
            Quip='The back roads just became a full-scale virtual reality firefight.'
            SteamAppIds=@('565550','580940'); SteamFolders=@('Redneck Rampage','Redneck Rampage Rides Again')
            GogNames=@('Redneck Rampage Collection'); ExtraRoots=@()
            DataFolders=@('rampage','ridesagain'); Markers=@('games\rampage\REDNECK.GRP','games\ridesagain\REDNECK.GRP')
            LauncherInclude='(?i)^Redneck Rampage.* VR\.bat$'; LauncherExclude='(?i)Route 66'
        }
        nam = @{
            Family='nam'; Display='NAM'; HubId='nam-vr'; Shortcut='NAM VR'
            IconFile='NAM_VR.ico'
            Quip='The Build engine heads into the jungle with tracked weapons.'
            SteamAppIds=@('329650'); SteamFolders=@('Nam','NAM'); GogNames=@('NAM'); ExtraRoots=@()
            DataFolders=@('nam'); Markers=@('games\nam\NAM.GRP')
            LauncherInclude='(?i)^(NAM|NAPALM).* VR\.bat$'; LauncherExclude='a^'
        }
        ww2gi = @{
            Family='ww2gi'; Display='World War II GI'; HubId='wwii-gi-vr'; Shortcut='World War II GI VR'
            IconFile='WW2GI_VR.ico'
            Quip='The Build engine storms the front with tracked weapons.'
            SteamAppIds=@('376750'); SteamFolders=@('World War II GI'); GogNames=@('World War II GI'); ExtraRoots=@()
            DataFolders=@('ww2gi'); Markers=@('games\ww2gi\WW2GI.GRP')
            LauncherInclude='(?i)^WWII GI.* VR\.bat$'; LauncherExclude='(?i)Platoon Leader'
        }
        exhumed = @{
            Family='exhumed'; Display='PowerSlave / Exhumed'; HubId='powerslave-exhumed-vr'; Shortcut='PowerSlave - Exhumed VR'
            IconFile='PowerSlave_Exhumed_VR.ico'
            Quip='Ancient ruins and alien gods rise around you in true stereo.'
            SteamAppIds=@('1260020'); SteamFolders=@('PowerslaveCE','PowerSlave DOS Classic Edition')
            GogNames=@('Powerslave'); ExtraRoots=@()
            DataFolders=@('exhumed'); Markers=@('games\exhumed\STUFF.DAT')
            LauncherInclude='(?i)^(PowerSlave|Exhumed).* VR\.bat$'; LauncherExclude='a^'
        }
    }
    $key = ('' + $Family).Trim().ToLowerInvariant()
    if (-not $definitions.ContainsKey($key)) { throw "Unknown RazeXR game family: $Family" }
    return $definitions[$key]
}

function Get-RazeWrapperFolder([string]$Family) {
    return @{
        duke='DukeNukem3DVR'; blood='BloodRazeXR'; shadowwarrior='ShadowWarriorRazeXR'
        redneck='RedneckRampageVR'; nam='NAMVR'; ww2gi='WW2GIVR'; exhumed='PowerSlaveRazeXR'
    }[(Get-RazeGameDefinition $Family).Family]
}

function New-RazeInstallerContract([string]$Family) {
    $definition = Get-RazeGameDefinition $Family
    return New-PCVRInstallerContract -Id ([string]$definition.HubId) -GameName ([string]$definition.Display) `
        -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $script:RazeReleasesUrl `
        -RequiredInstalledFileGroups @(
            'raze.exe',
            'openxr_loader.dll',
            'assets\vrweapons_models.pk3',
            'assets\vrweapons.pk3',
            (@($definition.Markers) -join '|'),
            ('PCVRHub Launchers\' + $definition.Family + '.bat'),
            '.pcvrhub_razexrengine_ownership.csv'
        )
}

function Test-RazeGameData([string]$InstallRoot,$Definition) {
    foreach ($relative in @($Definition.Markers)) {
        if (Test-Path -LiteralPath (Join-Path $InstallRoot $relative) -PathType Leaf) { return $true }
    }
    return $false
}

function Read-RazeInstallScope($Definition,[scriptblock]$ReadChoice) {
    if (-not $ReadChoice) { $ReadChoice = { param($Prompt) Read-Host $Prompt } }
    Write-Host ''
    Write-Host '  Choose what this setup should prepare:' -ForegroundColor Yellow
    Write-Host "  [1] Only $($Definition.Display) - this game" -ForegroundColor Yellow
    Write-Host '  [2] All compatible detected games' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Both choices leave every original game installation unchanged.' -ForegroundColor Gray
    Write-Host '  Flat games still start normally from Steam, GOG or their EXE.' -ForegroundColor Gray
    Write-Host '  VR uses separate launchers in the portable RazeXR folder.' -ForegroundColor Gray
    Write-Host '  Existing RazeXR games are never removed by either choice.' -ForegroundColor Gray
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $choice = ('' + (& $ReadChoice '  Select 1 or 2')).Trim()
        if ($choice -eq '1') { return 'selected' }
        if ($choice -eq '2') { return 'all' }
        Write-RazeWarn 'Please enter 1 or 2.'
    }
    throw 'No valid installation scope was selected after 10 attempts.'
}

function Get-RazeOwnedGameRoot($Definition,[string]$InstallRoot='') {
    $located = Get-HubLocatedGameFolder -GameId ([string]$Definition.HubId)
    if ($located) { return $located }
    foreach ($appId in @($Definition.SteamAppIds)) {
        $found = Find-SteamGameFolder -AppId ([string]$appId) `
            -SteamFolderNames @($Definition.SteamFolders) -GogNames @($Definition.GogNames) `
            -HubGameId ([string]$Definition.HubId)
        if ($found) { return $found }
    }
    foreach ($candidate in @($Definition.ExtraRoots)) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Container)) { return $candidate }
    }
    if ($InstallRoot -and (Test-RazeGameData -InstallRoot $InstallRoot -Definition $Definition)) { return $InstallRoot }
    return $null
}

function Read-RazeOwnedGameRoot($Definition) {
    Write-RazeWarn "$($Definition.Display) data was not found automatically."
    Write-Host '  Paste the game folder you own. The official setup searches it' -ForegroundColor White
    Write-Host '  recursively and copies only compatible original game data.' -ForegroundColor White
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $candidate = ('' + (Read-Host '  Game folder')).Trim().Trim('"').Trim("'")
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Container)) { return $candidate }
        Write-RazeWarn 'That folder does not exist. Paste the full game folder path.'
    }
    throw 'No existing game folder was supplied after 10 attempts.'
}

function Get-RazePreferredLauncher([string]$InstallRoot,$Definition) {
    $launcherRoot = Join-Path $InstallRoot 'launchers'
    if (-not (Test-Path -LiteralPath $launcherRoot -PathType Container)) { return $null }
    $matches = @(Get-ChildItem -LiteralPath $launcherRoot -File -Filter '*.bat' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $Definition.LauncherInclude -and $_.Name -notmatch $Definition.LauncherExclude })
    if ($Definition.Family -eq 'duke') {
        $preferred = @($matches | Where-Object { $_.Name -match '(?i)World Tour' } | Select-Object -First 1)
        if ($preferred.Count) { return $preferred[0] }
        $preferred = @($matches | Where-Object { $_.Name -match '(?i)Atomic' } | Select-Object -First 1)
        if ($preferred.Count) { return $preferred[0] }
    }
    if ($Definition.Family -eq 'redneck') {
        $preferred = @($matches | Where-Object { $_.Name -notmatch '(?i)Rides Again' } | Select-Object -First 1)
        if ($preferred.Count) { return $preferred[0] }
    }
    return @($matches | Sort-Object Name | Select-Object -First 1)[0]
}

function Write-RazeBatch([string]$Path,[string[]]$Lines) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void][IO.Directory]::CreateDirectory($parent) }
    [IO.File]::WriteAllLines($Path,$Lines,(New-Object Text.ASCIIEncoding))
}

function Write-RazeHubLaunchers([string]$InstallRoot) {
    $hubLaunchers = Join-Path $InstallRoot 'PCVRHub Launchers'
    [void][IO.Directory]::CreateDirectory($hubLaunchers)
    Copy-Item -LiteralPath (Join-Path $script:RazeSharedRoot 'RazeXR-Uninstall.ps1') `
        -Destination (Join-Path $InstallRoot 'PCVRHub-Uninstall.ps1') -Force -ErrorAction Stop

    $written = @{}
    foreach ($family in @('duke','blood','shadowwarrior','redneck','nam','ww2gi','exhumed')) {
        $definition = Get-RazeGameDefinition $family
        if (-not (Test-RazeGameData -InstallRoot $InstallRoot -Definition $definition)) { continue }
        $source = Get-RazePreferredLauncher -InstallRoot $InstallRoot -Definition $definition
        $stable = Join-Path $hubLaunchers ($family + '.bat')
        if ($source) {
            $relativeSource = 'launchers\' + $source.Name
            Write-RazeBatch -Path $stable -Lines @(
                '@echo off','setlocal','cd /d "%~dp0.."',
                ('call "%~dp0..\' + $relativeSource + '"'),
                'set "RAZE_EXIT=%ERRORLEVEL%"','endlocal & exit /b %RAZE_EXIT%'
            )
            $written[$family] = $stable
        } elseif (Test-Path -LiteralPath $stable -PathType Leaf) {
            # Preserve a previously generated, working stable launcher if a
            # later engine pass could not regenerate its author launcher.
            $written[$family] = $stable
        }

        $uninstall = Join-Path $hubLaunchers ("Uninstall $family VR.bat")
        Write-RazeBatch -Path $uninstall -Lines @(
            '@echo off','setlocal',
            ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\PCVRHub-Uninstall.ps1" -Family "' + $family + '" %*'),
            'set "RAZE_EXIT=%ERRORLEVEL%"','endlocal & exit /b %RAZE_EXIT%'
        )
    }
    return $written
}

function Install-RazeDesktopShortcuts {
    param(
        [Parameter(Mandatory=$true)][string]$InstallRoot,
        [Parameter(Mandatory=$true)][hashtable]$Launchers,
        [Parameter(Mandatory=$true)][string[]]$Families,
        [string]$DesktopRoot = '',
        [string]$IconRoot = $script:RazeSharedRoot
    )
    if (-not $DesktopRoot) {
        $DesktopRoot = if ($env:PCVR_RAZEXR_DESKTOP_ROOT) {
            [string]$env:PCVR_RAZEXR_DESKTOP_ROOT
        } else {
            [Environment]::GetFolderPath('Desktop')
        }
    }
    if ($DesktopRoot -and -not (Test-Path -LiteralPath $DesktopRoot -PathType Container)) {
        [void][IO.Directory]::CreateDirectory($DesktopRoot)
    }

    $created = @{}
    foreach ($family in @('duke','blood','shadowwarrior','redneck','nam','ww2gi','exhumed')) {
        if ($family -notin @($Families) -or -not $Launchers.ContainsKey($family)) { continue }
        $launcher = [string]$Launchers[$family]
        if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) { continue }
        $definition = Get-RazeGameDefinition $family
        $iconSource = Join-Path $IconRoot ([string]$definition.IconFile)
        $iconTarget = Join-Path $InstallRoot ([string]$definition.IconFile)
        $iconPath = (Join-Path $InstallRoot 'raze.exe') + ',0'
        if (Test-Path -LiteralPath $iconSource -PathType Leaf) {
            try {
                Copy-Item -LiteralPath $iconSource -Destination $iconTarget -Force -ErrorAction Stop
                if (Test-Path -LiteralPath $iconTarget -PathType Leaf) { $iconPath = $iconTarget }
            } catch {
                Write-RazeWarn "Could not copy the individual $($definition.Display) shortcut icon; using the RazeXR icon."
            }
        } else {
            Write-RazeWarn "The individual $($definition.Display) shortcut icon is missing; using the RazeXR icon."
        }
        if (-not $DesktopRoot) { continue }
        $link = New-DesktopShortcut -LnkPath (Join-Path $DesktopRoot ($definition.Shortcut + '.lnk')) `
            -TargetPath $launcher -WorkingDir $InstallRoot -IconPath $iconPath `
            -Description "$($definition.Display) through RazeXR PCVR"
        if ($link) { $created[$family] = [string]$link }
        else { Write-RazeWarn "Could not create the $($definition.Shortcut) desktop shortcut." }
    }
    return $created
}

function Get-RazeInstallRoot {
    $root = if ($env:PCVR_RAZEXR_INSTALL_ROOT) { [string]$env:PCVR_RAZEXR_INSTALL_ROOT } else { $script:RazeDefaultRoot }
    if (Test-InstallerTargetWritable -TargetPath $root) { return $root }
    Write-RazeWarn "The standard portable folder is not writable: $root"
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $candidate = ('' + (Read-Host '  Paste another full folder path')).Trim().Trim('"').Trim("'")
        if ($candidate -and (Test-InstallerTargetWritable -TargetPath $candidate)) { return $candidate }
        Write-RazeWarn 'That folder cannot be used. Choose an existing writable drive or folder.'
    }
    throw 'No writable RazeXR installation folder was supplied after 10 attempts.'
}

function Install-RazeEnginePayload([string]$PayloadRoot,[string]$InstallRoot) {
    if (-not (Test-Path -LiteralPath $InstallRoot -PathType Container)) { [void][IO.Directory]::CreateDirectory($InstallRoot) }
    # raze_portable.ini is player state. The first installation receives the
    # release default; later engine updates never replace it.
    $configSource = Join-Path $PayloadRoot 'raze_portable.ini'
    $configTarget = Join-Path $InstallRoot 'raze_portable.ini'
    if (-not (Test-Path -LiteralPath $configTarget -PathType Leaf) -and (Test-Path -LiteralPath $configSource -PathType Leaf)) {
        Copy-Item -LiteralPath $configSource -Destination $configTarget -Force -ErrorAction Stop
    }
    return Install-OwnedModPayload -SourceRoot $PayloadRoot -GameRoot $InstallRoot `
        -Identity 'razexrengine' -SkipRelativePaths @('raze_portable.ini') -AdoptIdenticalExisting
}

function Save-RazeEngineSnapshot([string]$InstallRoot,[string]$SnapshotRoot,[string]$PayloadRoot='') {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $manifest = Join-Path $InstallRoot '.pcvrhub_razexrengine_ownership.csv'
    $backup = Join-Path $InstallRoot '.pcvrhub_razexrengine_backup'
    $relativePaths = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    # Player configuration is deliberately not engine-owned, but a brand-new
    # default is still part of this transaction and must disappear on rollback.
    [void]$relativePaths.Add('raze_portable.ini')
    # setup.ps1 generates this pack from assets\vrweapons_models.pk3. It is not
    # present in the downloaded payload, so include it explicitly in the
    # transaction snapshot: a failed update restores an older generated pack,
    # while a failed first install removes the newly generated one.
    [void]$relativePaths.Add('assets\vrweapons.pk3')
    if ($PayloadRoot -and (Test-Path -LiteralPath $PayloadRoot -PathType Container)) {
        $payloadBase = [IO.Path]::GetFullPath($PayloadRoot).TrimEnd([char[]]'\/')
        foreach ($file in @(Get-ChildItem -LiteralPath $PayloadRoot -Recurse -File -ErrorAction Stop)) {
            [void]$relativePaths.Add($file.FullName.Substring($payloadBase.Length + 1).Replace('/','\'))
        }
    }
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        foreach ($row in @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)) {
            if ($row.RelativePath) { [void]$relativePaths.Add([string]$row.RelativePath) }
        }
    }
    $records = @()
    foreach ($relative in @($relativePaths)) {
        $source = Join-OwnedRelativePath $InstallRoot $relative
        $exists = Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{ Relative=$relative; Exists=$exists }
        if ($exists) {
            $target = Join-OwnedRelativePath (Join-Path $SnapshotRoot 'files') $relative
            $parent = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void][IO.Directory]::CreateDirectory($parent) }
            Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop
        }
    }
    $manifestExists = Test-Path -LiteralPath $manifest -PathType Leaf
    if ($manifestExists) { Copy-Item -LiteralPath $manifest -Destination (Join-Path $SnapshotRoot 'ownership.csv') -Force -ErrorAction Stop }
    $backupExists = Test-Path -LiteralPath $backup -PathType Container
    if ($backupExists) { Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'ownership-backup') -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{
        Records=$records; ManifestExists=$manifestExists; BackupExists=$backupExists
        SnapshotRoot=$SnapshotRoot
    }
}

function Restore-RazeEngineSnapshot([string]$InstallRoot,$Snapshot) {
    $currentManifest = Join-Path $InstallRoot '.pcvrhub_razexrengine_ownership.csv'
    $currentRows = @()
    if (Test-Path -LiteralPath $currentManifest -PathType Leaf) {
        try { $currentRows = @(Import-Csv -LiteralPath $currentManifest -ErrorAction Stop) } catch {}
    }
    $known = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($row in @($Snapshot.Records)) { if ($row.Relative) { [void]$known.Add([string]$row.Relative) } }
    foreach ($row in $currentRows) { if ($row.RelativePath) { [void]$known.Add([string]$row.RelativePath) } }
    foreach ($relative in @($known)) {
        $target = Join-OwnedRelativePath $InstallRoot $relative
        $record = @($Snapshot.Records | Where-Object { ([string]$_.Relative).Equals($relative,[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1)
        $existed = [bool]($record.Count -and $record[0].Exists)
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
        if ($existed) {
            $source = Join-OwnedRelativePath (Join-Path $Snapshot.SnapshotRoot 'files') $relative
            $parent = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void][IO.Directory]::CreateDirectory($parent) }
            Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $InstallRoot '.pcvrhub_razexrengine_backup'
    if (Test-Path -LiteralPath $currentManifest -PathType Leaf) { Remove-Item -LiteralPath $currentManifest -Force -ErrorAction SilentlyContinue }
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue }
    if ($Snapshot.ManifestExists) { Copy-Item -LiteralPath (Join-Path $Snapshot.SnapshotRoot 'ownership.csv') -Destination $currentManifest -Force -ErrorAction Stop }
    if ($Snapshot.BackupExists) { Copy-Item -LiteralPath (Join-Path $Snapshot.SnapshotRoot 'ownership-backup') -Destination $backup -Recurse -Force -ErrorAction Stop }
}

function Invoke-RazeAuthorSetup([string]$InstallRoot,[string]$ExtraRoot='',[switch]$ExclusiveRoot) {
    $setup = Join-Path $InstallRoot 'setup.ps1'
    if (-not (Test-Path -LiteralPath $setup -PathType Leaf)) { throw 'The official setup.ps1 is missing after extraction.' }
    $runSetup = $setup
    $temporarySetup = $null
    try {
        if ($ExclusiveRoot) {
            if (-not $ExtraRoot -or -not (Test-Path -LiteralPath $ExtraRoot -PathType Container)) {
                throw 'Selected-only setup requires an existing owned-game folder.'
            }
            $text = [IO.File]::ReadAllText($setup)
            $anchorPattern = '(?m)^if \(\$Root\) \{ AddRoot \$Root \}\s*$'
            $matches = [regex]::Matches($text,$anchorPattern)
            if ($matches.Count -ne 1) {
                throw 'The current official setup cannot be safely limited to one game. Choose the all-compatible option or report this release.'
            }
            $replacement = "if (`$Root) {`r`n    `$roots.Clear()`r`n    AddRoot `$Root`r`n}"
            $patched = [regex]::Replace($text,$anchorPattern,$replacement,1)
            $temporarySetup = Join-Path $InstallRoot ('setup.pcvrhub-selected-' + [Guid]::NewGuid().ToString('N') + '.ps1')
            [IO.File]::WriteAllText($temporarySetup,$patched,(New-Object Text.UTF8Encoding $false))
            $runSetup = $temporarySetup
        }
        $arguments = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$runSetup)
        if ($ExtraRoot) { $arguments += @('-Root',$ExtraRoot) }
        # Consume the technical child-process report without forwarding it to
        # either the host or this function's success pipeline.  Forwarding it
        # floods the user-facing installer; leaving it on the pipeline delays
        # formatting until after the final Enter-to-close prompt.
        $authorOutput = @(& powershell.exe @arguments 2>&1 | ForEach-Object { [string]$_ })
        $authorExitCode = $LASTEXITCODE
        if ($authorExitCode -ne 0) {
            $diagnostic = @($authorOutput | Select-Object -Last 12) -join [Environment]::NewLine
            if ($diagnostic) { throw "The official RazeXR setup returned exit code $authorExitCode.`n$diagnostic" }
            throw "The official RazeXR setup returned exit code $authorExitCode."
        }
    } finally {
        if ($temporarySetup -and (Test-Path -LiteralPath $temporarySetup -PathType Leaf)) {
            Remove-Item -LiteralPath $temporarySetup -Force -ErrorAction SilentlyContinue
        }
    }
}

function Complete-RazeDetectedFamilies {
    param(
        [Parameter(Mandatory=$true)][string]$InstallRoot,
        [Parameter(Mandatory=$true)][string]$Version,
        [Parameter(Mandatory=$true)][string]$FocusFamily,
        [Parameter(Mandatory=$true)][hashtable]$Launchers,
        [string]$CoreRoot = $script:RazeCoreRoot
    )
    $focus = (Get-RazeGameDefinition $FocusFamily).Family
    $oldStatus = $env:PCVR_HUB_INSTALL_STATUS_PATH
    try {
        foreach ($family in @($Launchers.Keys | Sort-Object | Where-Object { $_ -ne $focus })) {
            $env:PCVR_HUB_INSTALL_STATUS_PATH = ''
            $wrapper = Join-Path $CoreRoot (Get-RazeWrapperFolder $family)
            if (-not (Test-Path -LiteralPath $wrapper -PathType Container)) { [void][IO.Directory]::CreateDirectory($wrapper) }
            $contract = New-RazeInstallerContract $family
            [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $InstallRoot -Version $Version `
                -InstalledPathReceiptPaths @((Join-Path $wrapper '.installed_path')) -Route Current)
        }
        $env:PCVR_HUB_INSTALL_STATUS_PATH = $oldStatus
        $focusWrapper = Join-Path $CoreRoot (Get-RazeWrapperFolder $focus)
        if (-not (Test-Path -LiteralPath $focusWrapper -PathType Container)) { [void][IO.Directory]::CreateDirectory($focusWrapper) }
        $focusContract = New-RazeInstallerContract $focus
        [void](Complete-PCVRInstallTransaction -Contract $focusContract -GameDir $InstallRoot -Version $Version `
            -InstalledPathReceiptPaths @((Join-Path $focusWrapper '.installed_path')) -Route Current)
    } finally {
        $env:PCVR_HUB_INSTALL_STATUS_PATH = $oldStatus
    }
}

function Install-RazeXRGame([string]$Family) {
    $definition = Get-RazeGameDefinition $Family
    $work = $null
    $installRoot = $null
    $engineSnapshot = $null
    $engineChanged = $false
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host "  $($definition.Display) VR - Installer" -ForegroundColor Cyan
        Write-Host '  Installs: RazeXR PCVR by Game Or Die' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  RazeXR is one portable VR engine for seven classic games.' -ForegroundColor White
        Write-Host '  This route copies only game data you already own and adds' -ForegroundColor White
        Write-Host '  true stereo VR, motion controls and voxel hand weapons.' -ForegroundColor White
        Write-Host '  You can prepare only this game or every compatible game' -ForegroundColor Gray
        Write-Host '  that the official setup detects on this PC.' -ForegroundColor Gray
        Show-AntivirusNotice -Compact
        $installScope = Read-RazeInstallScope -Definition $definition

        Write-RazeStep 1 5 'Preparing the portable RazeXR folder'
        $installRoot = Get-RazeInstallRoot
        Write-RazeOK "Install folder: $installRoot"

        Write-RazeStep 2 5 'Getting the current stable GitHub release'
        $release = Resolve-GitHubReleaseAsset -Repo $script:RazeRepo `
            -AssetPatterns @('(?i)^RazeXR-PCVR\.zip$') `
            -FallbackUrl $script:RazeFallbackUrl -FallbackTag $script:RazeFallbackTag -FallbackAssetName 'RazeXR-PCVR.zip'
        Write-RazeInfo "Stable release: $($release.Tag)"
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_razexr_' + [Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive = Join-Path $work 'RazeXR-PCVR.zip'
        $downloaded = Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive `
            -Label "RazeXR PCVR $($release.Tag)" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if (-not ($downloaded -eq $true -or [string]$downloaded -in @('retry','manual'))) { throw 'The RazeXR release was not downloaded.' }

        Write-RazeStep 3 5 'Installing or updating the shared VR engine'
        $extract = Join-Path $work 'release'
        $expanded = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'RazeXR PCVR release' -AllowSkip $false
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The RazeXR archive could not be extracted.' }
        $razeExe = Get-ChildItem -LiteralPath $extract -File -Filter 'raze.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $razeExe) { throw 'The downloaded ZIP contains no RazeXR executable, so nothing was installed.' }
        $payload = $razeExe.DirectoryName
        foreach ($required in @('raze.exe','openxr_loader.dll','openal32.dll','setup.ps1','assets\vrweapons_models.pk3')) {
            if (-not (Test-Path -LiteralPath (Join-Path $payload $required) -PathType Leaf)) {
                throw "The current release is missing a functional RazeXR file: $required"
            }
        }
        $engineSnapshot = Save-RazeEngineSnapshot -InstallRoot $installRoot -SnapshotRoot (Join-Path $work 'engine-rollback') -PayloadRoot $payload
        $engineChanged = $true
        [void](Install-RazeEnginePayload -PayloadRoot $payload -InstallRoot $installRoot)
        $watch = @('raze.exe','openxr_loader.dll','openal32.dll','assets\vrweapons_models.pk3') | ForEach-Object { Join-Path $installRoot $_ }
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $installRoot -ArchivePath $archive)) {
            throw 'One or more RazeXR files did not survive the antivirus recovery check.'
        }
        Write-RazeOK 'Shared RazeXR engine and voxel hand weapons are present.'

        Write-RazeStep 4 5 'Finding owned game data and writing launchers'
        Write-Host '  This step can take a few minutes.' -ForegroundColor Yellow
        Write-Host '  RazeXR now scans and copies owned data, downloads optional' -ForegroundColor Gray
        Write-Host '  public asset packs and writes the separate VR launchers.' -ForegroundColor Gray
        Write-Host '  Please wait; the next status line appears when this work is finished.' -ForegroundColor Gray
        Write-Host ''
        $located = Get-RazeOwnedGameRoot -Definition $definition -InstallRoot $installRoot
        if ($installScope -eq 'selected') {
            if (-not $located) { $located = Read-RazeOwnedGameRoot -Definition $definition }
            Write-RazeInfo "Selected-only scope: importing $($definition.Display), not scanning other installed games."
            Invoke-RazeAuthorSetup -InstallRoot $installRoot -ExtraRoot $located -ExclusiveRoot
        } else {
            Write-RazeInfo 'All-compatible scope: scanning normal Steam, GOG and manual game locations.'
            Invoke-RazeAuthorSetup -InstallRoot $installRoot -ExtraRoot $located
        }
        if (-not (Test-RazeGameData -InstallRoot $installRoot -Definition $definition)) {
            $supplied = Read-RazeOwnedGameRoot -Definition $definition
            if ($installScope -eq 'selected') {
                Invoke-RazeAuthorSetup -InstallRoot $installRoot -ExtraRoot $supplied -ExclusiveRoot
            } else {
                Invoke-RazeAuthorSetup -InstallRoot $installRoot -ExtraRoot $supplied
            }
        }
        if (-not (Test-RazeGameData -InstallRoot $installRoot -Definition $definition)) {
            throw "$($definition.Display) compatible data was still not found. The original game installation was left unchanged."
        }
        $generatedWeaponPack = Join-Path $installRoot 'assets\vrweapons.pk3'
        if (-not (Test-Path -LiteralPath $generatedWeaponPack -PathType Leaf)) {
            throw 'The official RazeXR setup did not build assets\vrweapons.pk3, so the VR engine was not committed.'
        }
        $launchers = Write-RazeHubLaunchers -InstallRoot $installRoot
        if (-not $launchers.ContainsKey($definition.Family) -or -not (Test-Path -LiteralPath $launchers[$definition.Family] -PathType Leaf)) {
            throw "RazeXR found the game data but did not create a $($definition.Display) launcher. See setup.log in the RazeXR folder."
        }
        Write-RazeOK "$($definition.Display) data and launcher verified."

        Write-RazeStep 5 5 'Finishing the Hub connection'
        Complete-RazeDetectedFamilies -InstallRoot $installRoot -Version ([string]$release.Tag) `
            -FocusFamily ([string]$definition.Family) -Launchers $launchers
        $engineChanged = $false
        $shortcutFamilies = if ($installScope -eq 'all') { @($launchers.Keys) } else { @([string]$definition.Family) }
        $shortcuts = Install-RazeDesktopShortcuts -InstallRoot $installRoot -Launchers $launchers -Families $shortcutFamilies
        foreach ($shortcutFamily in @('duke','blood','shadowwarrior','redneck','nam','ww2gi','exhumed')) {
            if ($shortcuts.ContainsKey($shortcutFamily)) {
                Write-RazeOK "Desktop shortcut: $((Get-RazeGameDefinition $shortcutFamily).Shortcut)"
            }
        }
        Write-RazeOK "RazeXR $($release.Tag) is ready for $($definition.Display)."
        Write-Host ''
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Setup complete.' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Start Virtual Desktop, SteamVR or your OpenXR runtime first,' -ForegroundColor White
        Write-Host '  then use Start in VR in the Hub or the desktop shortcut.' -ForegroundColor White
        Write-Host '  RazeXR settings, saves and logs remain inside its portable folder.' -ForegroundColor Gray
        Write-Host '  Your original Steam or GOG installation remains unchanged and' -ForegroundColor Gray
        Write-Host '  starts flat normally; VR runs from the separate RazeXR folder.' -ForegroundColor Gray
        if ($installScope -eq 'all') {
            Write-Host "  Prepared VR launchers: $($launchers.Count) compatible game route(s)." -ForegroundColor Gray
        } else {
            Write-Host "  This run imported only $($definition.Display); existing RazeXR games remain available." -ForegroundColor Gray
        }
        Write-Host ''
        Write-Host "  $($definition.Quip)" -ForegroundColor Magenta
        Write-Host ''
        Pause-Raze 'Press Enter to close setup...'
    } catch {
        if ($engineChanged -and $installRoot -and $engineSnapshot) {
            try { Restore-RazeEngineSnapshot -InstallRoot $installRoot -Snapshot $engineSnapshot; Write-RazeWarn 'The previous shared-engine files were restored.' }
            catch { Write-RazeWarn "Automatic engine rollback needs review: $($_.Exception.Message)" }
        }
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
