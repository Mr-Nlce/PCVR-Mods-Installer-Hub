# Prey (2006) VR - governed standalone OpenXR installer.
# The publisher runtime lives in a user-selectable portable folder. The seven
# required retail PK4 files are copied from the user's own patched Prey 1.4
# install and deliberately remain outside Hub ownership.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Prey (2006) VR Installer'
$APP_ID = '3970'
$REPO = 'GameOrDie007/Prey-2006-VR'
$FALLBACK_TAG = 'v1.0-pcvr'
$FALLBACK_ASSET = 'PreyVR-PCVR-1.0.zip'
$FALLBACK_URL = 'https://github.com/GameOrDie007/Prey-2006-VR/releases/download/v1.0-pcvr/PreyVR-PCVR-1.0.zip'
$RELEASES_URL = "https://github.com/$REPO/releases"
$DEFAULT_TARGET = 'C:\Games\PreyVR'
$IDENTITY = 'prey2006vr'
$GENERATED_IDENTITY = 'prey2006vrgenerated'
$READY_MARKER = '.pcvrhub_ready'
$ICON_NAME = 'Prey2006VR.ico'
$QUIP = 'The Sphere was never built for personal space.'
$REQUIRED_PAKS = @('pak000.pk4','pak001.pk4','pak002.pk4','pak003.pk4','pak004.pk4','pak005.pk4','pak006.pk4')
$REQUIRED_RUNTIME = @('PreyVR.exe','gamex86_64.dll','openxr_loader.dll','Play PreyVR.bat','tools\buildpk4.ps1','tools\pk4patch\manifest.json')
$REQUIRED_INSTALLED_RUNTIME = @($REQUIRED_RUNTIME + @($ICON_NAME))

$contract = New-PCVRInstallerContract -Id 'prey-2006-vr' -GameName 'Prey (2006) VR' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $RELEASES_URL `
    -Routes @('Standalone') `
    -RequiredInstalledFileGroups @($REQUIRED_INSTALLED_RUNTIME + ($REQUIRED_PAKS | ForEach-Object { "preybase\$_" }) + @(
        'preybase\vr_support.pk4', ".pcvrhub_${IDENTITY}_ownership.csv",
        ".pcvrhub_${GENERATED_IDENTITY}_ownership.csv", $READY_MARKER
    ))

function Write-PreyStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host ''
}
function Write-PreyOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-PreyInfo([string]$Text) { Write-Host "  $Text" -ForegroundColor Gray }
function Write-PreyWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function Resolve-PreySourcePath([string]$Path) {
    if (-not $Path) { return $null }
    try {
        $start=[IO.Path]::GetFullPath($Path.Trim().Trim('"').Trim("'"))
        if (-not (Test-Path -LiteralPath $start -PathType Container)) { return $null }
    } catch { return $null }

    $queue=[Collections.Queue]::new()
    $queue.Enqueue([pscustomobject]@{Path=$start;Depth=0})
    $visited=0
    while ($queue.Count -gt 0 -and $visited -lt 200) {
        $node=$queue.Dequeue(); $visited++
        foreach ($candidate in @((Join-Path $node.Path 'base'),$node.Path)) {
            $complete=$true
            foreach ($name in $REQUIRED_PAKS) {
                if (-not (Test-Path -LiteralPath (Join-Path $candidate $name) -PathType Leaf -ErrorAction SilentlyContinue)) { $complete=$false; break }
            }
            if ($complete) {
                $base=(Get-Item -LiteralPath $candidate).FullName
                $root=if ((Split-Path -Leaf $base) -ieq 'base') { Split-Path -Parent $base } else { $base }
                return [pscustomobject]@{ Root=[IO.Path]::GetFullPath($root); Base=[IO.Path]::GetFullPath($base) }
            }
        }
        if ([int]$node.Depth -ge 3) { continue }
        try {
            foreach ($child in @(Get-ChildItem -LiteralPath $node.Path -Directory -ErrorAction SilentlyContinue)) {
                $queue.Enqueue([pscustomobject]@{Path=$child.FullName;Depth=([int]$node.Depth+1)})
            }
        } catch {}
    }
    return $null
}

function Save-PreyLocatedSource([string]$Root) {
    if (-not $Root) { return }
    $stateModule=Join-Path $PSScriptRoot '..\Modules\HubState.ps1'
    if (-not (Test-Path -LiteralPath $stateModule -PathType Leaf)) { return }
    $coreRoot=Split-Path -Parent $PSScriptRoot
    try {
        & {
            param($ModulePath,$CorePath,$LocatedRoot)
            $previous=$global:scriptDir
            try {
                $global:scriptDir=$CorePath
                . $ModulePath
                $game=[pscustomobject]@{Id='prey-2006-vr';Title='Prey (2006) VR';SteamId='3970'}
                Write-PersistentGameStateValue -Game $game -Name 'user_located' -Value $LocatedRoot
            } finally { $global:scriptDir=$previous }
        } $stateModule $coreRoot $Root
    } catch {}
}

function Get-PreySource([scriptblock]$ReadInput=$null) {
    $candidates=[Collections.Generic.List[string]]::new()
    try {
        $found=Find-SteamGameFolder -AppId $APP_ID -SteamFolderNames @('Prey 2006','Prey') `
            -ProbeExe 'base\pak000.pk4' -GogNames @('Prey','Prey 2006') -HubGameId 'prey-2006-vr'
        if ($found) { $candidates.Add($found) }
    } catch {}
    foreach ($candidate in @(
        'C:\Program Files (x86)\Steam\steamapps\common\Prey 2006',
        'C:\Program Files\Steam\steamapps\common\Prey 2006',
        'C:\Program Files (x86)\GOG Galaxy\Games\Prey',
        'C:\GOG Games\Prey','C:\Program Files (x86)\Prey','C:\Program Files\Prey',
        'C:\Program Files (x86)\3D Realms\Prey','C:\Program Files (x86)\2K Games\Prey'
    )) { $candidates.Add($candidate) }
    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        $resolved=Resolve-PreySourcePath $candidate
        if ($resolved) { Save-PreyLocatedSource $resolved.Root; return $resolved }
    }

    Write-PreyWarn 'Prey (2006) patched to version 1.4 was not found automatically.'
    Write-Host '  Select its install folder or the base folder containing all seven' -ForegroundColor White
    Write-Host '  files from pak000.pk4 through pak006.pk4.' -ForegroundColor White
    Write-Host '  Steam and GOG already include 1.4; a retail-disc copy needs the patch.' -ForegroundColor Gray
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $raw=if ($ReadInput) { & $ReadInput 'Prey folder' } else { Read-Host '  Prey folder (drag/paste path, or Q to quit)' }
        $value=(''+$raw).Trim().Trim('"').Trim("'")
        if ($value -ieq 'Q') { return $null }
        $resolved=Resolve-PreySourcePath $value
        if ($resolved) { Save-PreyLocatedSource $resolved.Root; return $resolved }
        Write-PreyWarn 'That folder does not contain the complete patched Prey 1.4 data.'
    }
    throw 'No complete Prey 1.4 source was selected after 10 attempts.'
}

function Get-PreyRememberedTarget {
    $receipt=Join-Path $PSScriptRoot '.installed_path'
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try {
            $value=([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
            if ($value -and (Test-Path -LiteralPath (Join-Path $value 'PreyVR.exe') -PathType Leaf)) { return [IO.Path]::GetFullPath($value) }
        } catch {}
    }
    return $DEFAULT_TARGET
}

function Test-PreyTargetWritable([string]$Path) {
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) { [void][IO.Directory]::CreateDirectory($Path) }
        return [bool](Test-InstallerTargetWritable -TargetPath $Path)
    } catch { return $false }
}

function Select-PreyInstallFolder($Source,[scriptblock]$ReadInput=$null,[scriptblock]$WritableProbe=$null) {
    $suggested=Get-PreyRememberedTarget
    Write-Host "  Default: $suggested" -ForegroundColor White
    Write-Host '  Press Enter to use it, or type/paste another full folder path.' -ForegroundColor Gray
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $raw=if ($ReadInput) { & $ReadInput $suggested } else { Read-Host '  PreyVR install folder' }
        $value=(''+$raw).Trim().Trim('"').Trim("'")
        if (-not $value) { $value=$suggested }
        if ($value -ieq 'Q') { return $null }
        try {
            $target=[IO.Path]::GetFullPath($value).TrimEnd('\','/')
            if ($target -eq [IO.Path]::GetPathRoot($target).TrimEnd('\','/')) { throw 'A drive root is not an install folder.' }
            if ($target -ieq $Source.Root.TrimEnd('\','/') -or $target -ieq $Source.Base.TrimEnd('\','/')) { throw 'The standalone VR folder must differ from the original game folder.' }
            $writable=if ($WritableProbe) { [bool](& $WritableProbe $target) } else { Test-PreyTargetWritable $target }
            if (-not $writable) { throw 'The selected folder is not writable.' }
            return $target
        } catch { Write-PreyWarn $_.Exception.Message }
    }
    throw 'No writable PreyVR folder was selected after 10 attempts.'
}

function Get-PreyPayloadRoot([string]$ExtractRoot) {
    $candidates=@(Get-ChildItem -LiteralPath $ExtractRoot -Directory -Recurse -ErrorAction SilentlyContinue) + @((Get-Item -LiteralPath $ExtractRoot))
    foreach ($candidate in $candidates) {
        $root=$candidate.FullName; $valid=$true
        foreach ($relative in $REQUIRED_RUNTIME) {
            if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) { $valid=$false; break }
        }
        if ($valid) { return $root }
    }
    return $null
}

function Add-PreyHubAssetsToPayload([string]$Payload) {
    $iconSource=Join-Path $PSScriptRoot $ICON_NAME
    if (-not (Test-Path -LiteralPath $iconSource -PathType Leaf)) { throw "The bundled Prey shortcut icon is missing: $ICON_NAME" }
    $iconTarget=Join-Path $Payload $ICON_NAME
    Copy-Item -LiteralPath $iconSource -Destination $iconTarget -Force
    if (-not (Test-Path -LiteralPath $iconTarget -PathType Leaf) -or
        (Get-Item -LiteralPath $iconTarget).Length -ne (Get-Item -LiteralPath $iconSource).Length) {
        throw 'The bundled Prey shortcut icon could not be staged safely.'
    }
}

function Save-PreySnapshot([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $relatives=[Collections.Generic.List[string]]::new()
    $stageBase=[IO.Path]::GetFullPath($Stage).TrimEnd('\','/')
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File -ErrorAction Stop)) {
        $relatives.Add($file.FullName.Substring($stageBase.Length+1).Replace('/','\'))
    }
    foreach ($identity in @($IDENTITY,$GENERATED_IDENTITY)) {
        $manifest=Join-Path $GameRoot ".pcvrhub_${identity}_ownership.csv"
        if (Test-Path -LiteralPath $manifest -PathType Leaf) {
            try { foreach ($row in @(Import-Csv -LiteralPath $manifest)) { if ($row.RelativePath) { $relatives.Add([string]$row.RelativePath) } } } catch {}
        }
        $relatives.Add(".pcvrhub_${identity}_ownership.csv")
        $relatives.Add(".pcvrhub_${identity}_ownership.csv.new")
    }
    foreach ($extra in @('preybase\vr_support.pk4','.pcvrhub_version',$READY_MARKER)) { $relatives.Add($extra) }
    $records=@()
    foreach ($relative in @($relatives | Select-Object -Unique)) {
        $source=Join-Path $GameRoot $relative; $exists=Test-Path -LiteralPath $source -PathType Leaf
        $key=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($relative)).Replace('/','_')
        $records += [pscustomobject]@{Relative=$relative;Exists=$exists;Key=$key}
        if ($exists) { Copy-Item -LiteralPath $source -Destination (Join-Path $SnapshotRoot $key) -Force }
    }
    $backups=@{}
    foreach ($identity in @($IDENTITY,$GENERATED_IDENTITY)) {
        $path=Join-Path $GameRoot ".pcvrhub_${identity}_backup"
        $backups[$identity]=Test-Path -LiteralPath $path -PathType Container
        if ($backups[$identity]) { Copy-Item -LiteralPath $path -Destination (Join-Path $SnapshotRoot "backup-$identity") -Recurse -Force }
    }
    return [pscustomobject]@{Records=$records;Backups=$backups;Root=$SnapshotRoot}
}

function Restore-PreySnapshot([string]$GameRoot,$Snapshot,[string[]]$AddedPaks=@()) {
    foreach ($relative in @($AddedPaks)) { Remove-Item -LiteralPath (Join-Path $GameRoot $relative) -Force -ErrorAction SilentlyContinue }
    foreach ($record in @($Snapshot.Records)) {
        $target=Join-Path $GameRoot ([string]$record.Relative)
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
        if ($record.Exists) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath (Join-Path $Snapshot.Root ([string]$record.Key)) -Destination $target -Force
        }
    }
    foreach ($identity in @($IDENTITY,$GENERATED_IDENTITY)) {
        $path=Join-Path $GameRoot ".pcvrhub_${identity}_backup"
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue }
        if ($Snapshot.Backups[$identity]) { Copy-Item -LiteralPath (Join-Path $Snapshot.Root "backup-$identity") -Destination $path -Recurse -Force }
    }
}

function Copy-PreyOwnedData([string]$SourceBase,[string]$TargetRoot) {
    $dest=Join-Path $TargetRoot 'preybase'; [void][IO.Directory]::CreateDirectory($dest)
    $added=[Collections.Generic.List[string]]::new()
    foreach ($name in $REQUIRED_PAKS) {
        $source=Join-Path $SourceBase $name; $target=Join-Path $dest $name
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            if ((Get-Item -LiteralPath $target).Length -ne (Get-Item -LiteralPath $source).Length) {
                throw "Existing standalone data differs from the selected Prey copy: preybase\$name"
            }
            continue
        }
        Copy-Item -LiteralPath $source -Destination $target -Force
        if ((Get-Item -LiteralPath $target).Length -ne (Get-Item -LiteralPath $source).Length) { throw "Copy verification failed: preybase\$name" }
        $added.Add("preybase\$name")
    }
    return @($added)
}

function Invoke-PreyNativeTool {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string[]]$ArgumentList=@(),
        [Parameter(Mandatory=$true)][string]$FailureMessage
    )
    $resolvedPath=$null
    if (Test-Path -LiteralPath $FilePath -PathType Leaf) {
        $resolvedPath=(Get-Item -LiteralPath $FilePath -ErrorAction Stop).FullName
    } else {
        $command=Get-Command $FilePath -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) { $resolvedPath=$command.Source }
    }
    if (-not $resolvedPath) { throw "$FailureMessage (publisher tool was not found)." }

    $previousPreference=$ErrorActionPreference
    $nativeOutput=@(); $nativeExitCode=$null; $invocationFailure=$null
    try {
        # Keep publisher stdout/stderr out of this function's return stream.
        # Windows PowerShell 5 may surface native stderr as ErrorRecord objects,
        # even when the process succeeds, so only the process exit code decides.
        $ErrorActionPreference='Continue'
        $global:LASTEXITCODE=$null
        try {
            $nativeOutput=@(& $resolvedPath @ArgumentList 2>&1)
            $nativeExitCode=$global:LASTEXITCODE
        } catch {
            $invocationFailure=$_.Exception.Message
        }
    } finally {
        $ErrorActionPreference=$previousPreference
    }
    foreach ($entry in @($nativeOutput)) {
        $line=[string]$entry
        if (-not [string]::IsNullOrWhiteSpace($line)) { Write-PreyInfo $line.TrimEnd() }
    }
    if ($invocationFailure) { throw "$FailureMessage ($invocationFailure)" }
    if ($null -eq $nativeExitCode) { throw "$FailureMessage (publisher tool returned no exit code)." }
    if ([int]$nativeExitCode -ne 0) { throw "$FailureMessage (exit code $nativeExitCode)." }
    return $true
}

function Build-PreySupportPackage([string]$Payload,[string]$SourceBase,[string]$WorkRoot) {
    $stage=Join-Path $WorkRoot 'generated-stage'; [void][IO.Directory]::CreateDirectory((Join-Path $stage 'preybase'))
    $out=Join-Path $stage 'preybase\vr_support.pk4'
    $builder=Join-Path $Payload 'tools\buildpk4.ps1'
    $patch=Join-Path $Payload 'tools\pk4patch'
    [void](Invoke-PreyNativeTool -FilePath 'powershell.exe' -ArgumentList @(
        '-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$builder,
        '-PatchDir',$patch,'-PreyBase',$SourceBase,'-OutFile',$out
    ) -FailureMessage 'The publisher tool could not build vr_support.pk4 from this Prey 1.4 data')
    if (-not (Test-Path -LiteralPath $out -PathType Leaf) -or (Get-Item -LiteralPath $out).Length -le 0) {
        throw 'The publisher tool could not build vr_support.pk4 from this Prey 1.4 data.'
    }
    return [string]$stage
}

function global:Invoke-Prey2006VRInstaller {
    $work=$null; $target=$null; $snapshot=$null; $changesStarted=$false; $addedPaks=@(); $targetExisted=$true
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Prey (2006) VR - Installer' -ForegroundColor Cyan
        Write-Host '  Standalone OpenXR port by GameOrDie007 and lvonasek' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host '  Full campaign, room-scale movement and motion controls.' -ForegroundColor White
        Write-Host '  Your original Prey folder is never modified. The VR port and' -ForegroundColor White
        Write-Host "  copied game data go into a separate folder (default $DEFAULT_TARGET)." -ForegroundColor White
        Write-Host '  Prey 1.4 is required; Steam and GOG already include that patch.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start setup...')

        Write-PreyStep 1 5 'Locating your own Prey (2006) 1.4 data'
        $source=Get-PreySource
        if (-not $source) { throw 'Setup cancelled before any file was changed.' }
        Write-PreyOK "Complete game data found: $($source.Base)"

        Write-PreyStep 2 5 'Choosing the separate PreyVR folder'
        $target=Select-PreyInstallFolder -Source $source
        if (-not $target) { throw 'Setup cancelled before any file was changed.' }
        $targetExisted=Test-Path -LiteralPath $target -PathType Container
        if (-not $targetExisted) { [void][IO.Directory]::CreateDirectory($target) }
        if (-not (Test-InstallerTargetWritable -TargetPath $target)) { throw 'The selected PreyVR folder is not writable.' }
        if (Get-Process -Name 'PreyVR' -ErrorAction SilentlyContinue) { throw 'PreyVR is running. Close it completely and run setup again.' }
        Write-PreyOK "Standalone folder: $target"

        Write-PreyStep 3 5 'Downloading and validating the newest stable PCVR release'
        $release=Resolve-GitHubReleaseAsset -Repo $REPO -AssetPatterns @('(?i)^PreyVR-PCVR-.*\.zip$') `
            -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_ASSET
        $version=[string]$release.Tag
        if (-not (Test-IsTrackableInstalledVersion $version)) { throw 'The publisher release did not provide a trackable version tag.' }
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_prey2006_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work ([string]$release.AssetName)
        $got=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "PreyVR $version" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if (-not ($got -eq $true -or [string]$got -in @('retry','manual'))) { throw 'The official PreyVR archive was not downloaded.' }
        $extract=Join-Path $work 'extract'
        $expanded=Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'PreyVR PCVR release' -AllowSkip $false -QuietProgress
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The PreyVR archive could not be extracted.' }
        $payload=Get-PreyPayloadRoot $extract
        if (-not $payload) { throw 'The release is missing PreyVR.exe, OpenXR runtime or the publisher build tools.' }
        Add-PreyHubAssetsToPayload -Payload $payload
        $generatedStage=Build-PreySupportPackage -Payload $payload -SourceBase $source.Base -WorkRoot $work
        [IO.File]::WriteAllText((Join-Path $payload $READY_MARKER),$version,(New-Object Text.UTF8Encoding $false))
        Write-PreyOK "Functional release $version and generated support package verified."

        Write-PreyStep 4 5 'Installing runtime and copying your owned game data'
        $snapshot=Save-PreySnapshot -GameRoot $target -Stage $payload -SnapshotRoot (Join-Path $work 'snapshot')
        $changesStarted=$true
        [void](Install-OwnedModPayload -SourceRoot $payload -GameRoot $target -Identity $IDENTITY `
            -KeepExistingRelativePaths @('saves\preybase\preyconfig.cfg','saves\preybase\autoexec.cfg') -AdoptIdenticalExisting)
        $addedPaks=Copy-PreyOwnedData -SourceBase $source.Base -TargetRoot $target
        [void](Install-OwnedModPayload -SourceRoot $generatedStage -GameRoot $target -Identity $GENERATED_IDENTITY `
            -ReplaceChangedOwnedRelativePaths @('preybase\vr_support.pk4') -AdoptIdenticalExisting)
        $watch=@($REQUIRED_INSTALLED_RUNTIME + ($REQUIRED_PAKS | ForEach-Object { "preybase\$_" }) + @(
            'preybase\vr_support.pk4',".pcvrhub_${IDENTITY}_ownership.csv",
            ".pcvrhub_${GENERATED_IDENTITY}_ownership.csv",$READY_MARKER
        )) | ForEach-Object { Join-Path $target $_ }
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $target -NoClear)) { throw 'Required PreyVR files are missing after installation.' }
        Write-PreyOK 'Runtime, OpenXR loader, generated VR support and seven owned game-data files verified.'

        Write-PreyStep 5 5 'Committing path, version and launch state'
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $target -Version $version `
            -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path')) -Route 'Standalone')
        try { Write-PCVRAtomicText -Path (Join-Path $PSScriptRoot '.source_path') -Value $source.Root } catch {}
        try {
            [void](New-DesktopShortcut -ShortcutName 'Prey (2006) VR' -TargetPath (Join-Path $target 'Play PreyVR.bat') `
                -WorkingDir $target -IconPath (Join-Path $target $ICON_NAME) -Description 'Launch Prey (2006) in OpenXR VR')
            Write-PreyOK 'Desktop shortcut created.'
        } catch { Write-PreyWarn 'The installation is complete, but its optional desktop shortcut could not be created.' }
        $changesStarted=$false

        Write-Host ''; Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Prey (2006) VR is ready' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host "  Installed: PreyVR $version" -ForegroundColor White
        Write-Host "  Folder:    $target" -ForegroundColor White
        Write-Host '  Activate your OpenXR runtime, then use Start in VR or the desktop shortcut.' -ForegroundColor Yellow
        Write-Host '  Virtual Desktop with VDXR is publisher-tested. SteamVR can create a session,' -ForegroundColor Gray
        Write-Host '  but a full headset playthrough there is not yet publisher-confirmed.' -ForegroundColor Gray
        Write-Host '  Config, saves and qconsole.log stay inside this standalone folder.' -ForegroundColor Gray
        Write-Host ''; Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $target -and $snapshot) {
            try { Restore-PreySnapshot -GameRoot $target -Snapshot $snapshot -AddedPaks $addedPaks; Write-PreyWarn 'The previous PreyVR folder state was restored.' }
            catch { Write-PreyWarn ('Rollback also needs attention: '+$_.Exception.Message) }
        }
        if (-not $targetExisted -and $target -and (Test-Path -LiteralPath $target -PathType Container)) {
            try { if (@(Get-ChildItem -LiteralPath $target -Force -ErrorAction Stop).Count -eq 0) { Remove-Item -LiteralPath $target -Force } } catch {}
        }
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if (((''+$env:PCVR_PREY2006_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-Prey2006VRInstaller }
