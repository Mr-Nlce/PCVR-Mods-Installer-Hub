# Pokemon Dramatic Shape VR - governed standalone OpenXR installer.
# The publisher package contains no ROM. Red/Blue/Yellow, Crystal and
# Pokemon Pinball are imported by the application from copies the user owns.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Pokemon Dramatic Shape VR Installer'
$GAME_ID = 'pokemon-gen-1-vr'
$GAME_TITLE = 'Pokemon Dramatic Shape VR'
$REPO = 'prismaticShape/DramaticShapeVR'
$FALLBACK_TAG = 'v3.0.1'
$FALLBACK_ASSET = 'DramaticShapeVR-3.0.1-windows.zip'
$FALLBACK_URL = 'https://github.com/prismaticShape/DramaticShapeVR/releases/download/v3.0.1/DramaticShapeVR-3.0.1-windows.zip'
$RELEASES_URL = "https://github.com/$REPO/releases"
$DEFAULT_TARGET = 'C:\Games\Pokemon Dramatic Shape VR'
$IDENTITY = 'dramaticshapevr'
$VERSION_FILE = 'VERSION'
$QUIP = 'Kanto, Johto and a pinball table now fit in the same headset.'
$LEGACY_PORT_TAG = 'v0.2.56'
$LEGACY_PORT_ASSET = 'gen1recomp-0.2.56-windows.zip'
$LEGACY_PORT_URL = 'https://github.com/bryanthaboi/gen1recomp/releases/download/v0.2.56/gen1recomp-0.2.56-windows.zip'
$LEGACY_PORT_PAGE = 'https://github.com/bryanthaboi/gen1recomp/releases/tag/v0.2.56'
$LEGACY_DRAMATIC_TAG = 'v1.8.5'
$LEGACY_DRAMATIC_ASSET = 'DRAMATIC_SHAPE-1.8.5.zip'
$LEGACY_DRAMATIC_URL = 'https://github.com/scottcandy34/DramaticShapeVoxelMod-latest/releases/download/v1.8.5/DRAMATIC_SHAPE-1.8.5.zip'
$LEGACY_DRAMATIC_PAGE = 'https://github.com/scottcandy34/DramaticShapeVoxelMod-latest/releases/tag/v1.8.5'
$LEGACY_DRAMALESS_TAG = 'v1.6.4'
$LEGACY_DRAMALESS_ASSET = 'DRAMALESS_SHAPE_1-6-4-hotfix.zip'
$LEGACY_DRAMALESS_URL = 'https://github.com/artyrambles/DRAMALESS_SHAPE/releases/download/v1.6.4/DRAMALESS_SHAPE_1-6-4-hotfix.zip'
$LEGACY_DRAMALESS_PAGE = 'https://github.com/artyrambles/DRAMALESS_SHAPE/releases/tag/v1.6.4'
$LEGACY_DEFAULT_TARGET = 'C:\Games\Pokemon Gen 1 VR'
$LEGACY_PORT_REQUIRED = @('gen1recomp.exe','love.dll','lua51.dll','SDL2.dll','OpenAL32.dll')
$LEGACY_MOD_REQUIRED = @('main.lua','manifest.json','assets\vr\openxr_loader.dll')
$REQUIRED_RUNTIME = @(
    'DramaticShapeVR.exe','love.dll','lua51.dll','mpg123.dll','msvcp120.dll','msvcr120.dll',
    'OpenAL32.dll','SDL2.dll','openxr_loader.dll','README.txt',
    'voice\win-x64\onnxruntime.dll','voice\win-x64\onnxruntime_providers_shared.dll',
    'voice\win-x64\sherpa-onnx-c-api.dll'
)

$contract = New-PCVRInstallerContract -Id $GAME_ID -GameName $GAME_TITLE `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $RELEASES_URL -Routes @('Standalone') `
    -RequiredInstalledFileGroups @($REQUIRED_RUNTIME + @($VERSION_FILE,".pcvrhub_${IDENTITY}_ownership.csv"))
$legacyContract = New-PCVRInstallerContract -Id $GAME_ID -GameName 'Pokemon Gen 1 VR Legacy' `
    -Acquisition GitHub -AntivirusNotice -ReleasePageUrl $LEGACY_PORT_PAGE -Routes @('Legacy') `
    -RequiredInstalledFileGroups @($LEGACY_PORT_REQUIRED + @('.pcvrhub_voxelmod','.pcvrhub_gen1recomplegacy_ownership.csv'))

function Write-DramaticStep([int]$Number,[int]$Total,[string]$Text) {
    Write-Host ''; Write-Host "--- [$Number/$Total] $Text ---" -ForegroundColor Cyan; Write-Host ''
}
function Write-DramaticOK([string]$Text) { Write-Host "  [OK] $Text" -ForegroundColor Green }
function Write-DramaticWarn([string]$Text) { Write-Host "  [!!] $Text" -ForegroundColor Yellow }

function Repair-DramaticPcvrTouchDispatch([string]$ExecutablePath) {
    if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) { throw 'DramaticShapeVR.exe is missing.' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $bytes=[IO.File]::ReadAllBytes($ExecutablePath)
    $eocd=-1
    for($i=$bytes.Length-22;$i -ge 0;$i--){
        if($bytes[$i]-eq 0x50 -and $bytes[$i+1]-eq 0x4b -and $bytes[$i+2]-eq 0x05 -and $bytes[$i+3]-eq 0x06){$eocd=$i;break}
    }
    if($eocd -lt 0){throw 'The publisher executable contains no readable LÖVE package.'}
    $centralSize=[BitConverter]::ToUInt32($bytes,$eocd+12)
    $centralOffset=[BitConverter]::ToUInt32($bytes,$eocd+16)
    $prefixLength=[int64]$eocd-[int64]$centralSize-[int64]$centralOffset
    if($prefixLength -le 0 -or $prefixLength -ge $bytes.Length){throw 'The publisher LÖVE package boundary is invalid.'}
    $zipPath=$ExecutablePath+'.pcvr-touchfix.zip'
    $newExe=$ExecutablePath+'.pcvr-touchfix.exe'
    $backupExe=$ExecutablePath+'.pcvr-touchfix.backup'
    try{
        $zipBytes=New-Object byte[] ($bytes.Length-$prefixLength)
        [Array]::Copy($bytes,$prefixLength,$zipBytes,0,$zipBytes.Length)
        [IO.File]::WriteAllBytes($zipPath,$zipBytes)
        $archive=[IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Update)
        try{
            $entry=$archive.GetEntry('main.lua')
            if(-not $entry){throw 'The publisher LÖVE package contains no main.lua.'}
            $reader=New-Object IO.StreamReader($entry.Open())
            try{$main=$reader.ReadToEnd()}finally{$reader.Dispose()}
            $changedMethods=@()
            foreach($method in @('touchpressed','touchmoved','touchreleased')){
                $unsafe="    return Importer:$method(id, x, y, dx, dy, pressure)"
                $safe="    if Importer.$method then return Importer:$method(id, x, y, dx, dy, pressure) end"
                if($main.Contains($safe)){continue}
                if($main.Contains($unsafe)){
                    $main=$main.Replace($unsafe,$safe)
                    $changedMethods+= $method
                }
            }
            if($changedMethods.Count -eq 0){return [pscustomobject]@{Changed=$false;Verified=$true;PatchedMethods=@()}}
            $entry.Delete()
            $entry=$archive.CreateEntry('main.lua',[IO.Compression.CompressionLevel]::Optimal)
            $writer=New-Object IO.StreamWriter($entry.Open(),(New-Object Text.UTF8Encoding($false)))
            try{$writer.Write($main)}finally{$writer.Dispose()}
        }finally{$archive.Dispose()}
        $output=[IO.File]::Open($newExe,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try{
            $output.Write($bytes,0,[int]$prefixLength)
            $input=[IO.File]::OpenRead($zipPath)
            try{$input.CopyTo($output)}finally{$input.Dispose()}
        }finally{$output.Dispose()}
        [IO.File]::Replace($newExe,$ExecutablePath,$backupExe,$true)
        return [pscustomobject]@{Changed=$true;Verified=$true;PatchedMethods=$changedMethods}
    }finally{
        Remove-Item -LiteralPath $zipPath,$newExe,$backupExe -Force -ErrorAction SilentlyContinue
    }
}

function Select-PokemonInstallerRoute([scriptblock]$ReadInput=$null) {
    Write-Host '  Choose the installation route:' -ForegroundColor White
    Write-Host '    [1] Dramatic Shape VR 3.x - newest standalone app (recommended)' -ForegroundColor Green
    Write-Host '    [2] Legacy Gen1Recomp VR - pinned classic two-part setup' -ForegroundColor White
    Write-Host ''
    while ($true) {
        $raw = if ($ReadInput) { & $ReadInput } else { Read-Host '  Route [1]' }
        $choice = (''+$raw).Trim()
        if (-not $choice -or $choice -eq '1') { return 'Current' }
        if ($choice -eq '2') { return 'Legacy' }
        Write-DramaticWarn 'Type 1 or 2. Press Enter for the recommended current route.'
    }
}

function Select-LegacyPokemonProfile([scriptblock]$ReadInput=$null) {
    Write-Host '  Choose the pinned legacy VR profile:' -ForegroundColor White
    Write-Host "    [1] Dramatic Shape $LEGACY_DRAMATIC_TAG - full original feature set" -ForegroundColor Green
    Write-Host "    [2] Dramaless Shape $LEGACY_DRAMALESS_TAG - leaner legacy fork" -ForegroundColor White
    Write-Host '  Newer releases are not substituted: they removed or changed this VR path.' -ForegroundColor Gray
    while ($true) {
        $raw = if ($ReadInput) { & $ReadInput } else { Read-Host '  Legacy profile [1]' }
        $choice = (''+$raw).Trim()
        if (-not $choice -or $choice -eq '1') {
            return [pscustomobject]@{ Id='DRAMATIC_SHAPE'; Label='Dramatic Shape'; Tag=$LEGACY_DRAMATIC_TAG; Asset=$LEGACY_DRAMATIC_ASSET; Url=$LEGACY_DRAMATIC_URL; Page=$LEGACY_DRAMATIC_PAGE; OtherId='DRAMALESS_SHAPE' }
        }
        if ($choice -eq '2') {
            return [pscustomobject]@{ Id='DRAMALESS_SHAPE'; Label='Dramaless Shape'; Tag=$LEGACY_DRAMALESS_TAG; Asset=$LEGACY_DRAMALESS_ASSET; Url=$LEGACY_DRAMALESS_URL; Page=$LEGACY_DRAMALESS_PAGE; OtherId='DRAMATIC_SHAPE' }
        }
        Write-DramaticWarn 'Type 1 or 2. Press Enter for the full Dramatic Shape profile.'
    }
}

function Get-DramaticRememberedTarget {
    $durable = Get-PCVRRememberedGameFolder -GameId $GAME_ID -ProbeFiles @('DramaticShapeVR.exe','openxr_loader.dll')
    if ($durable) { return $durable }
    foreach ($receiptName in @('.installed_path_current','.installed_path')) {
      $receipt = Join-Path $PSScriptRoot $receiptName
      if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try {
            $value = ([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
            if ($value -and (Test-Path -LiteralPath (Join-Path $value 'DramaticShapeVR.exe') -PathType Leaf) -and
                (Test-Path -LiteralPath (Join-Path $value 'openxr_loader.dll') -PathType Leaf)) {
                return [IO.Path]::GetFullPath($value)
            }
        } catch {}
      }
    }
    return $DEFAULT_TARGET
}

function Save-DramaticLegacyRouteReceipt {
    $candidates = [Collections.Generic.List[string]]::new()
    $oldReceipt = Join-Path $PSScriptRoot '.installed_path'
    if (Test-Path -LiteralPath $oldReceipt -PathType Leaf) {
        try { $candidates.Add(([IO.File]::ReadAllText($oldReceipt)).Trim().Trim('"')) } catch {}
    }
    try {
        $durable = Get-PCVRRememberedGameFolder -GameId $GAME_ID -ProbeFiles @('gen1recomp.exe','.pcvrhub_voxelmod')
        if ($durable) { $candidates.Add($durable) }
    } catch {}
    foreach ($path in @('C:\Games\Pokemon Gen 1 VR','D:\Games\Pokemon Gen 1 VR','E:\Games\Pokemon Gen 1 VR')) {
        $candidates.Add($path)
    }
    foreach ($candidate in @($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        try {
            $full = [IO.Path]::GetFullPath($candidate).TrimEnd('\','/')
            if ((Test-Path -LiteralPath (Join-Path $full 'gen1recomp.exe') -PathType Leaf) -and
                (Test-Path -LiteralPath (Join-Path $full '.pcvrhub_voxelmod') -PathType Leaf)) {
                Write-PCVRAtomicText -Path (Join-Path $PSScriptRoot '.installed_path_legacy_depot') -Value $full
                return $full
            }
        } catch {}
    }
    return $null
}

function Test-DramaticTargetWritable([string]$Path) {
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) { [void][IO.Directory]::CreateDirectory($Path) }
        return [bool](Test-InstallerTargetWritable -TargetPath $Path)
    } catch { return $false }
}

function Select-DramaticInstallFolder([scriptblock]$ReadInput=$null,[scriptblock]$WritableProbe=$null) {
    $suggested = Get-DramaticRememberedTarget
    Write-Host "  Default: $suggested" -ForegroundColor White
    Write-Host '  Press Enter to use it, or type/paste another full folder path.' -ForegroundColor Gray
    for ($attempt=1; $attempt -le 10; $attempt++) {
        $raw = if ($ReadInput) { & $ReadInput $suggested } else { Read-Host '  Dramatic Shape VR install folder' }
        $value = (''+$raw).Trim().Trim('"').Trim("'")
        if (-not $value) { $value = $suggested }
        if ($value -ieq 'Q') { return $null }
        try {
            $target = [IO.Path]::GetFullPath($value).TrimEnd('\','/')
            if ($target -eq [IO.Path]::GetPathRoot($target).TrimEnd('\','/')) { throw 'A drive root is not an install folder.' }
            $writable = if ($WritableProbe) { [bool](& $WritableProbe $target) } else { Test-DramaticTargetWritable $target }
            if (-not $writable) { throw 'The selected folder is not writable.' }
            return $target
        } catch { Write-DramaticWarn $_.Exception.Message }
    }
    throw 'No writable Dramatic Shape VR folder was selected after 10 attempts.'
}

function Get-LegacyRememberedTarget {
    $receipt = Join-Path $PSScriptRoot '.installed_path_legacy_depot'
    if (Test-Path -LiteralPath $receipt -PathType Leaf) {
        try {
            $value = ([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
            if ($value -and (Test-Path -LiteralPath (Join-Path $value 'gen1recomp.exe') -PathType Leaf)) {
                return [IO.Path]::GetFullPath($value)
            }
        } catch {}
    }
    try {
        $durable = Get-PCVRRememberedGameFolder -GameId $GAME_ID -ProbeFiles @('gen1recomp.exe','.pcvrhub_voxelmod')
        if ($durable) { return $durable }
    } catch {}
    foreach ($candidate in @($LEGACY_DEFAULT_TARGET,'D:\Games\Pokemon Gen 1 VR','E:\Games\Pokemon Gen 1 VR')) {
        if (Test-Path -LiteralPath (Join-Path $candidate 'gen1recomp.exe') -PathType Leaf) { return $candidate }
    }
    return $LEGACY_DEFAULT_TARGET
}

function Select-LegacyInstallFolder([scriptblock]$ReadInput=$null,[scriptblock]$WritableProbe=$null) {
    $suggested = Get-LegacyRememberedTarget
    Write-Host "  Default: $suggested" -ForegroundColor White
    Write-Host '  Press Enter to use it, or type/paste another complete install folder.' -ForegroundColor Gray
    while ($true) {
        $raw = if ($ReadInput) { & $ReadInput $suggested } else { Read-Host '  Pokemon Gen 1 VR legacy folder' }
        $value = (''+$raw).Trim().Trim('"').Trim("'")
        if (-not $value) { $value = $suggested }
        if ($value -ieq 'Q') { return $null }
        try {
            $target = [IO.Path]::GetFullPath($value).TrimEnd('\','/')
            if ($target -eq [IO.Path]::GetPathRoot($target).TrimEnd('\','/')) { throw 'A drive root is not an install folder.' }
            $writable = if ($WritableProbe) { [bool](& $WritableProbe $target) } else { Test-DramaticTargetWritable $target }
            if (-not $writable) { throw 'The selected folder is not writable.' }
            return $target
        } catch { Write-DramaticWarn $_.Exception.Message }
    }
}

function Get-LegacyPayloadRoot([string]$ExtractRoot,[string[]]$RequiredFiles) {
    $candidates = @((Get-Item -LiteralPath $ExtractRoot)) +
        @(Get-ChildItem -LiteralPath $ExtractRoot -Directory -Recurse -ErrorAction SilentlyContinue)
    foreach ($candidate in $candidates) {
        $root = $candidate.FullName
        $valid = $true
        foreach ($relative in $RequiredFiles) {
            if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) { $valid=$false; break }
        }
        if ($valid) { return $root }
    }
    return $null
}

function Test-LegacyModManifest([string]$PayloadRoot,[string]$ExpectedId,[string]$ExpectedVersion) {
    try {
        $manifest = Get-Content -LiteralPath (Join-Path $PayloadRoot 'manifest.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $id = (''+$manifest.id).Trim()
        $version = (''+$manifest.version).Trim().TrimStart('v','V')
        $gameRange = (''+$manifest.game_version).Trim()
        return ($id -ceq $ExpectedId -and $version -eq $ExpectedVersion.TrimStart('v','V') -and $gameRange -match '<\s*2\.0\.0')
    } catch { return $false }
}

function Get-DramaticPayloadRoot([string]$ExtractRoot) {
    $candidates = @((Get-Item -LiteralPath $ExtractRoot)) +
        @(Get-ChildItem -LiteralPath $ExtractRoot -Directory -Recurse -ErrorAction SilentlyContinue)
    foreach ($candidate in $candidates) {
        $root = $candidate.FullName
        $valid = $true
        foreach ($relative in $REQUIRED_RUNTIME) {
            if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) { $valid=$false; break }
        }
        if ($valid) { return $root }
    }
    return $null
}

function Test-DramaticPayloadHasNoRom([string]$PayloadRoot) {
    return @(Get-ChildItem -LiteralPath $PayloadRoot -Recurse -File -ErrorAction Stop |
        Where-Object Extension -match '(?i)^\.(gb|gbc|gba|rom)$').Count -eq 0
}

function Save-DramaticSnapshot([string]$GameRoot,[string]$Stage,[string]$SnapshotRoot,[string]$SnapshotIdentity=$IDENTITY) {
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $relatives = [Collections.Generic.List[string]]::new()
    $stageBase = [IO.Path]::GetFullPath($Stage).TrimEnd('\','/')
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File -ErrorAction Stop)) {
        $relatives.Add($file.FullName.Substring($stageBase.Length+1).Replace('/','\'))
    }
    $manifest = Join-Path $GameRoot ".pcvrhub_${SnapshotIdentity}_ownership.csv"
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        try { foreach ($row in @(Import-Csv -LiteralPath $manifest)) { if ($row.RelativePath) { $relatives.Add([string]$row.RelativePath) } } } catch {}
    }
    foreach ($extra in @(".pcvrhub_${SnapshotIdentity}_ownership.csv",".pcvrhub_${SnapshotIdentity}_ownership.csv.new",'.pcvrhub_version','.pcvrhub_version_b','.pcvrhub_voxelmod')) { $relatives.Add($extra) }
    $records = @()
    foreach ($relative in @($relatives | Select-Object -Unique)) {
        $source = Join-Path $GameRoot $relative
        $exists = Test-Path -LiteralPath $source -PathType Leaf
        $key = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($relative)).Replace('/','_')
        $records += [pscustomobject]@{ Relative=$relative; Exists=$exists; Key=$key }
        if ($exists) { Copy-Item -LiteralPath $source -Destination (Join-Path $SnapshotRoot $key) -Force }
    }
    $backup = Join-Path $GameRoot ".pcvrhub_${SnapshotIdentity}_backup"
    $backupExists = Test-Path -LiteralPath $backup -PathType Container
    if ($backupExists) { Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'backup') -Recurse -Force }
    return [pscustomobject]@{ Records=$records; BackupExists=$backupExists; Root=$SnapshotRoot; Identity=$SnapshotIdentity }
}

function Restore-DramaticSnapshot([string]$GameRoot,$Snapshot) {
    foreach ($record in @($Snapshot.Records)) {
        $target = Join-Path $GameRoot ([string]$record.Relative)
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
        if ($record.Exists) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath (Join-Path $Snapshot.Root ([string]$record.Key)) -Destination $target -Force
        }
    }
    $snapshotIdentity = if ($Snapshot.Identity) { [string]$Snapshot.Identity } else { $IDENTITY }
    $backup = Join-Path $GameRoot ".pcvrhub_${snapshotIdentity}_backup"
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue }
    if ($Snapshot.BackupExists) { Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'backup') -Destination $backup -Recurse -Force }
}

function Install-DramaticOwnedPayload {
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string]$SourceRoot,
        [Parameter(Mandatory=$true)][string]$Version,
        [Parameter(Mandatory=$true)][string[]]$InstalledPathReceipt
    )
    $stageFiles = @(Get-ChildItem -LiteralPath $SourceRoot -Recurse -File -ErrorAction Stop)
    $stageBase = [IO.Path]::GetFullPath($SourceRoot).TrimEnd('\','/')
    $replace = @($stageFiles | ForEach-Object { $_.FullName.Substring($stageBase.Length+1).Replace('/','\') })
    foreach ($relative in @($REQUIRED_RUNTIME + @($VERSION_FILE))) {
        if (-not (Test-Path -LiteralPath (Join-Path $SourceRoot $relative) -PathType Leaf)) { throw "Install stage is incomplete: $relative" }
    }
    if (-not (Test-DramaticPayloadHasNoRom $SourceRoot)) { throw 'The publisher package unexpectedly contains a game ROM and was rejected.' }
    [void](Install-OwnedModPayload -SourceRoot $SourceRoot -GameRoot $GameRoot -Identity $IDENTITY `
        -ReplaceChangedOwnedRelativePaths $replace -AdoptIdenticalExisting -ProgressLabel 'Installing Dramatic Shape VR')
    $watch = @($replace + ".pcvrhub_${IDENTITY}_ownership.csv") | ForEach-Object { Join-Path $GameRoot $_ }
    if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $GameRoot -NoClear)) { throw 'Required Dramatic Shape VR files are missing after installation.' }
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $GameRoot -Version $Version `
        -InstalledPathReceiptPaths @($InstalledPathReceipt) -AdditionalVersionReceiptPaths @((Join-Path $GameRoot $VERSION_FILE)) -Route 'Standalone')
}

function Move-LegacyConflictingProfile([string]$ModsRoot,[string]$DisabledRoot,[string]$OtherId) {
    $moves = [Collections.Generic.List[object]]::new()
    if (-not (Test-Path -LiteralPath $ModsRoot -PathType Container)) { return @() }
    [void][IO.Directory]::CreateDirectory($DisabledRoot)
    try {
        foreach ($directory in @(Get-ChildItem -LiteralPath $ModsRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "$OtherId*" })) {
            $destination = Join-Path $DisabledRoot $directory.Name
            if (Test-Path -LiteralPath $destination) { $destination += '-hub-' + [Guid]::NewGuid().ToString('N') }
            Move-Item -LiteralPath $directory.FullName -Destination $destination -ErrorAction Stop
            $moves.Add([pscustomobject]@{ Source=$directory.FullName; Destination=$destination })
            Write-DramaticOK "Disabled conflicting legacy profile without deleting it: $($directory.Name)"
        }
    } catch {
        Restore-LegacyProfileMoves -Moves @($moves)
        throw
    }
    return @($moves)
}

function Restore-LegacyProfileMoves($Moves) {
    foreach ($move in @($Moves)) {
        try {
            if ((Test-Path -LiteralPath $move.Destination -PathType Container) -and -not (Test-Path -LiteralPath $move.Source)) {
                Move-Item -LiteralPath $move.Destination -Destination $move.Source -ErrorAction Stop
            }
        } catch { Write-DramaticWarn "Could not restore the parked legacy profile: $($move.Destination)" }
    }
}

function Install-LegacyPokemonPayload {
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string]$PortRoot,
        [Parameter(Mandatory=$true)][string]$ModRoot,
        [Parameter(Mandatory=$true)]$Profile,
        [Parameter(Mandatory=$true)][string]$ModsRoot,
        [string]$InstalledPathReceipt=(Join-Path $PSScriptRoot '.installed_path_legacy_depot')
    )
    foreach ($relative in $LEGACY_PORT_REQUIRED) {
        if (-not (Test-Path -LiteralPath (Join-Path $PortRoot $relative) -PathType Leaf)) { throw "Legacy port stage is incomplete: $relative" }
    }
    foreach ($relative in $LEGACY_MOD_REQUIRED) {
        if (-not (Test-Path -LiteralPath (Join-Path $ModRoot $relative) -PathType Leaf)) { throw "Legacy VR profile stage is incomplete: $relative" }
    }
    if (-not (Test-LegacyModManifest -PayloadRoot $ModRoot -ExpectedId $Profile.Id -ExpectedVersion $Profile.Tag)) {
        throw "The selected archive is not the pinned $($Profile.Id) $($Profile.Tag) VR profile."
    }
    if (-not (Test-DramaticPayloadHasNoRom $PortRoot) -or -not (Test-DramaticPayloadHasNoRom $ModRoot)) {
        throw 'A publisher package unexpectedly contains a game ROM and was rejected.'
    }

    [void](Install-OwnedModPayload -SourceRoot $PortRoot -GameRoot $GameRoot -Identity 'gen1recomplegacy' `
        -AdoptIdenticalExisting -ProgressLabel 'Installing pinned Gen1Recomp')
    $profileDir = Join-Path $ModsRoot ([string]$Profile.Id)
    [void][IO.Directory]::CreateDirectory($profileDir)
    [void](Install-OwnedModPayload -SourceRoot $ModRoot -GameRoot $profileDir -Identity 'pokemonlegacyvoxel' `
        -AdoptIdenticalExisting -ProgressLabel "Installing $($Profile.Label)")

    $proof = @($LEGACY_PORT_REQUIRED | ForEach-Object { Join-Path $GameRoot $_ }) +
        @($LEGACY_MOD_REQUIRED | ForEach-Object { Join-Path $profileDir $_ }) +
        @((Join-Path $GameRoot '.pcvrhub_gen1recomplegacy_ownership.csv'),(Join-Path $profileDir '.pcvrhub_pokemonlegacyvoxel_ownership.csv'))
    if (-not (Confirm-PlacedFilesSurvive -Paths $proof -GameDir $GameRoot -NoClear)) {
        throw 'Required Gen1Recomp or legacy VR-profile files are missing after installation.'
    }

    $markerValue = "$($Profile.Id) $($Profile.Tag); Gen1Recomp $LEGACY_PORT_TAG"
    Write-PCVRAtomicText -Path (Join-Path $GameRoot '.pcvrhub_voxelmod') -Value $markerValue
    [void](Complete-PCVRInstallTransaction -Contract $legacyContract -GameDir $GameRoot -Version ([string]$Profile.Tag) `
        -InstalledPathReceiptPaths @($InstalledPathReceipt) -VersionSlot Secondary -Route 'Legacy')
}

function Invoke-LegacyPokemonRoute {
    $work=$null; $target=$null; $gameSnapshot=$null; $modSnapshot=$null; $profileMoves=@(); $changesStarted=$false; $targetExisted=$true
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Pokemon Gen 1 VR - Legacy Installer' -ForegroundColor Cyan
        Write-Host '  Gen1Recomp plus a pinned Dramatic Shape VR profile' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host '  This route is kept for people who prefer or already use the classic setup.' -ForegroundColor White
        Write-Host '  It supports a canonical US Red, Blue or Yellow ROM that you own.' -ForegroundColor Yellow
        Write-Host '  No ROM or Nintendo game data is included or downloaded.' -ForegroundColor Yellow
        $profile = Select-LegacyPokemonProfile
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the pinned legacy components...')

        Write-DramaticStep 1 5 'Choosing the legacy Gen1Recomp folder'
        $target = Select-LegacyInstallFolder
        if (-not $target) { throw 'Setup cancelled before any file was changed.' }
        $targetExisted = Test-Path -LiteralPath $target -PathType Container
        if (-not $targetExisted) { [void][IO.Directory]::CreateDirectory($target) }
        if (-not (Test-InstallerTargetWritable -TargetPath $target)) { throw 'The selected folder is not writable.' }
        if (Get-Process -Name 'gen1recomp' -ErrorAction SilentlyContinue) { throw 'Gen1Recomp is running. Close it completely and retry.' }
        Write-DramaticOK "Legacy folder: $target"

        Write-DramaticStep 2 5 'Downloading the pinned Gen1Recomp port'
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_pokemon_legacy_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $portArchive = Join-Path $work $LEGACY_PORT_ASSET
        $gotPort = Invoke-SafeDownload -Urls @($LEGACY_PORT_URL) -Destination $portArchive -Label "Gen1Recomp $LEGACY_PORT_TAG" -ManualUrl $LEGACY_PORT_PAGE -AllowSkip $false
        if (-not ($gotPort -eq $true -or [string]$gotPort -in @('retry','manual'))) { throw 'The official pinned Gen1Recomp archive was not downloaded.' }
        $portExtract = Join-Path $work 'port'
        $portExpanded = Expand-ArchiveOrFallback -ArchivePath $portArchive -DestinationFolder $portExtract -Label "Gen1Recomp $LEGACY_PORT_TAG" -AllowSkip $false -QuietProgress
        if ([string]$portExpanded -notin @('ok','manual','retry')) { throw 'The Gen1Recomp archive could not be extracted.' }
        $portPayload = Get-LegacyPayloadRoot -ExtractRoot $portExtract -RequiredFiles $LEGACY_PORT_REQUIRED
        if (-not $portPayload) { throw 'The archive has no usable Gen1Recomp Windows payload. Choose Retry or hand over the correct publisher ZIP.' }
        if (-not (Test-DramaticPayloadHasNoRom $portPayload)) { throw 'The publisher port unexpectedly contains a game ROM and was rejected.' }
        Write-DramaticOK "Gen1Recomp $LEGACY_PORT_TAG functional files verified."

        Write-DramaticStep 3 5 "Downloading $($profile.Label) $($profile.Tag)"
        $modArchive = Join-Path $work ([string]$profile.Asset)
        $gotMod = Invoke-SafeDownload -Urls @([string]$profile.Url) -Destination $modArchive -Label "$($profile.Label) $($profile.Tag)" -ManualUrl ([string]$profile.Page) -AllowSkip $false
        if (-not ($gotMod -eq $true -or [string]$gotMod -in @('retry','manual'))) { throw 'The pinned legacy VR-profile archive was not downloaded.' }
        $modExtract = Join-Path $work 'mod'
        $modExpanded = Expand-ArchiveOrFallback -ArchivePath $modArchive -DestinationFolder $modExtract -Label "$($profile.Label) $($profile.Tag)" -AllowSkip $false -QuietProgress
        if ([string]$modExpanded -notin @('ok','manual','retry')) { throw 'The legacy VR-profile archive could not be extracted.' }
        $modPayload = Get-LegacyPayloadRoot -ExtractRoot $modExtract -RequiredFiles $LEGACY_MOD_REQUIRED
        if (-not $modPayload -or -not (Test-LegacyModManifest -PayloadRoot $modPayload -ExpectedId $profile.Id -ExpectedVersion $profile.Tag)) {
            throw 'The archive has no matching pinned VR profile. Choose Retry or hand over the correct publisher ZIP.'
        }
        Write-DramaticOK "$($profile.Id) $($profile.Tag) and its OpenXR loader verified."

        Write-DramaticStep 4 5 'Installing both legacy components recoverably'
        $appData = (''+$env:APPDATA).Trim()
        if (-not $appData) { $appData = [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData) }
        if (-not $appData) { throw 'The Windows roaming AppData folder could not be resolved.' }
        $modsRoot = Join-Path $appData 'pokemon-love2d\mods'
        $disabledRoot = Join-Path $appData 'pokemon-love2d\mods-disabled'
        [void][IO.Directory]::CreateDirectory($modsRoot)
        $profileDir = Join-Path $modsRoot ([string]$profile.Id)
        $gameSnapshot = Save-DramaticSnapshot -GameRoot $target -Stage $portPayload -SnapshotRoot (Join-Path $work 'game-snapshot') -SnapshotIdentity 'gen1recomplegacy'
        [void][IO.Directory]::CreateDirectory($profileDir)
        $modSnapshot = Save-DramaticSnapshot -GameRoot $profileDir -Stage $modPayload -SnapshotRoot (Join-Path $work 'mod-snapshot') -SnapshotIdentity 'pokemonlegacyvoxel'
        $changesStarted = $true
        $profileMoves = @(Move-LegacyConflictingProfile -ModsRoot $modsRoot -DisabledRoot $disabledRoot -OtherId ([string]$profile.OtherId))
        Install-LegacyPokemonPayload -GameRoot $target -PortRoot $portPayload -ModRoot $modPayload -Profile $profile -ModsRoot $modsRoot
        if (-not (Save-HubRememberedGameFolder -GameId $GAME_ID -Title 'Pokemon Gen 1 VR Legacy' -GameDir $target `
            -ProbeFiles @('gen1recomp.exe','.pcvrhub_voxelmod') -UserSelected)) {
            Write-DramaticWarn 'The route receipt was written, but the shared path cache could not be refreshed.'
        }
        Write-DramaticOK 'Port, selected VR profile, OpenXR loader, ownership and route receipts verified.'

        Write-DramaticStep 5 5 'Creating the legacy desktop shortcut'
        try {
            [void](New-DesktopShortcut -ShortcutName 'Pokemon Gen 1 VR Legacy' -TargetPath (Join-Path $target 'gen1recomp.exe') `
                -WorkingDir $target -IconPath (Join-Path $target 'gen1recomp.exe') -Description 'Launch the pinned Gen1Recomp VR route')
            Write-DramaticOK 'Legacy desktop shortcut created.'
        } catch { Write-DramaticWarn 'The installation is complete, but its optional desktop shortcut could not be created.' }
        $changesStarted = $false

        Write-Host ''; Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Pokemon Gen 1 VR Legacy is ready' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host "  Installed: Gen1Recomp $LEGACY_PORT_TAG + $($profile.Label) $($profile.Tag)" -ForegroundColor White
        Write-Host "  Folder:    $target" -ForegroundColor White
        Write-Host '  Use Start Legacy Gen 1 on the game page.' -ForegroundColor Yellow
        Write-Host '  Import your own supported ROM when Gen1Recomp asks for it.' -ForegroundColor Yellow
        Write-Host '  The other legacy profile was preserved under mods-disabled.' -ForegroundColor Gray
        Write-Host ''; Write-Host '  The old route still knows the road to Kanto.' -ForegroundColor Magenta; Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted) {
            try { if ($target -and $gameSnapshot) { Restore-DramaticSnapshot -GameRoot $target -Snapshot $gameSnapshot } } catch { Write-DramaticWarn ('Game rollback needs attention: '+$_.Exception.Message) }
            try {
                if ($modSnapshot) {
                    $appData = if (((''+$env:APPDATA).Trim())) { (''+$env:APPDATA).Trim() } else { [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData) }
                    Restore-DramaticSnapshot -GameRoot (Join-Path (Join-Path $appData 'pokemon-love2d\mods') ([string]$profile.Id)) -Snapshot $modSnapshot
                }
            } catch { Write-DramaticWarn ('Profile rollback needs attention: '+$_.Exception.Message) }
            Restore-LegacyProfileMoves -Moves $profileMoves
            Write-DramaticWarn 'The previous legacy game and profile state was restored.'
        }
        if (-not $targetExisted -and $target -and (Test-Path -LiteralPath $target -PathType Container)) {
            try { if (@(Get-ChildItem -LiteralPath $target -Force -ErrorAction Stop).Count -eq 0) { Remove-Item -LiteralPath $target -Force } } catch {}
        }
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Invoke-DramaticShapeCurrentRoute {
    $work=$null; $target=$null; $snapshot=$null; $changesStarted=$false; $targetExisted=$true
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Pokemon Dramatic Shape VR - Installer' -ForegroundColor Cyan
        Write-Host '  Red / Blue / Yellow, Crystal and Pokemon Pinball in OpenXR' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host '  This installs the new standalone Dramatic Shape VR application.' -ForegroundColor White
        Write-Host '  It replaces the old two-part Gen1Recomp route as the recommended setup.' -ForegroundColor White
        Write-Host '  Existing old Gen1 folders and profiles are not changed or removed.' -ForegroundColor Gray
        Write-Host '  You provide legally owned ROMs from inside the application:' -ForegroundColor Yellow
        Write-Host '  US Red, Blue or Yellow; US Crystal; or Pokemon Pinball (U).' -ForegroundColor Yellow
        Write-Host '  Gen 2 currently means Crystal only. Gold and Silver are not supported.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the newest standalone release...')

        Write-DramaticStep 1 4 'Choosing the standalone Dramatic Shape VR folder'
        $legacyRoute = Save-DramaticLegacyRouteReceipt
        if ($legacyRoute) { Write-DramaticOK "Existing legacy Gen1Recomp VR route kept: $legacyRoute" }
        $target = Select-DramaticInstallFolder
        if (-not $target) { throw 'Setup cancelled before any file was changed.' }
        $targetExisted = Test-Path -LiteralPath $target -PathType Container
        if (-not $targetExisted) { [void][IO.Directory]::CreateDirectory($target) }
        if (-not (Test-InstallerTargetWritable -TargetPath $target)) { throw 'The selected folder is not writable.' }
        if (Get-Process -Name 'DramaticShapeVR' -ErrorAction SilentlyContinue) { throw 'Dramatic Shape VR is running. Close it completely and retry.' }
        Write-DramaticOK "Standalone folder: $target"

        Write-DramaticStep 2 4 'Downloading and validating the newest stable Windows release'
        $release = Resolve-GitHubReleaseAsset -Repo $REPO -AssetPatterns @('(?i)^DramaticShapeVR-[0-9][^/]*-windows\.zip$') `
            -FallbackUrl $FALLBACK_URL -FallbackTag $FALLBACK_TAG -FallbackAssetName $FALLBACK_ASSET -SkipReleasesWithoutMatchingAsset
        $version = [string]$release.Tag
        if (-not (Test-IsTrackableInstalledVersion $version)) { throw 'The publisher release did not provide a trackable version tag.' }
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr_dramaticshape_'+[Guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($work)
        $archive = Join-Path $work ([string]$release.AssetName)
        $got = Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "Dramatic Shape VR $version" -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if (-not ($got -eq $true -or [string]$got -in @('retry','manual'))) { throw 'The official Dramatic Shape VR archive was not downloaded.' }
        $extract = Join-Path $work 'extract'
        $expanded = Expand-ArchiveOrFallback -ArchivePath $archive -DestinationFolder $extract -Label 'official Dramatic Shape VR Windows release' -AllowSkip $false -QuietProgress
        if ([string]$expanded -notin @('ok','manual','retry')) { throw 'The Dramatic Shape VR archive could not be extracted.' }
        $payload = Get-DramaticPayloadRoot $extract
        if (-not $payload) { throw 'The release is missing DramaticShapeVR.exe, OpenXR, voice runtime or another required publisher file.' }
        if (-not (Test-DramaticPayloadHasNoRom $payload)) { throw 'The publisher package unexpectedly contains a game ROM and was rejected.' }
        $touchFix=Repair-DramaticPcvrTouchDispatch -ExecutablePath (Join-Path $payload 'DramaticShapeVR.exe')
        if(-not $touchFix.Verified){throw 'The PCVR launcher touch fix could not be verified.'}
        Write-PCVRAtomicText -Path (Join-Path $payload $VERSION_FILE) -Value ($version.TrimStart('v','V'))
        Write-DramaticOK "Official $version Windows runtime verified; the PCVR launcher touch crash is guarded and no ROM is present."

        Write-DramaticStep 3 4 'Installing the standalone OpenXR runtime recoverably'
        $snapshot = Save-DramaticSnapshot -GameRoot $target -Stage $payload -SnapshotRoot (Join-Path $work 'snapshot')
        $changesStarted = $true
        Install-DramaticOwnedPayload -GameRoot $target -SourceRoot $payload -Version $version `
            -InstalledPathReceipt @((Join-Path $PSScriptRoot '.installed_path'),(Join-Path $PSScriptRoot '.installed_path_current'))
        try { Write-PCVRAtomicText -Path (Join-Path $PSScriptRoot '.launch_exe') -Value (Join-Path $target 'DramaticShapeVR.exe') } catch {}
        if (-not (Save-HubRememberedGameFolder -GameId $GAME_ID -Title $GAME_TITLE -GameDir $target `
            -ProbeFiles @('DramaticShapeVR.exe','openxr_loader.dll') -UserSelected)) {
            Write-DramaticWarn 'The portable path receipt was written, but the shared path cache could not be refreshed.'
        }
        Write-DramaticOK 'Executable, OpenXR loader, voice runtime, ownership and version evidence verified.'

        Write-DramaticStep 4 4 'Creating the desktop shortcut'
        try {
            [void](New-DesktopShortcut -ShortcutName 'Pokemon Dramatic Shape VR' -TargetPath (Join-Path $target 'DramaticShapeVR.exe') `
                -WorkingDir $target -IconPath (Join-Path $target 'DramaticShapeVR.exe') -Description 'Launch Pokemon Dramatic Shape in OpenXR VR')
            Write-DramaticOK 'Desktop shortcut created.'
        } catch { Write-DramaticWarn 'The installation is complete, but its optional desktop shortcut could not be created.' }
        $changesStarted = $false

        Write-Host ''; Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Pokemon Dramatic Shape VR is ready' -ForegroundColor Green
        Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
        Write-Host "  Installed: Dramatic Shape VR $version" -ForegroundColor White
        Write-Host "  Folder:    $target" -ForegroundColor White
        Write-Host '  1. Make your preferred OpenXR runtime active.' -ForegroundColor Yellow
        Write-Host '  2. Use Start in VR in the Hub, then import a ROM you own.' -ForegroundColor Yellow
        Write-Host '  The launcher keeps ROM-derived data and saves in %APPDATA%\DramaticShapeVR.' -ForegroundColor Gray
        Write-Host '  Its UPDATES control can also install later publisher releases in place.' -ForegroundColor Gray
        Write-Host '  Crystal outdoor areas can be demanding; lower CULL RADIUS if needed.' -ForegroundColor Gray
        Write-Host ''; Write-Host "  $QUIP" -ForegroundColor Magenta; Write-Host ''
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        if ($changesStarted -and $target -and $snapshot) {
            try { Restore-DramaticSnapshot -GameRoot $target -Snapshot $snapshot; Write-DramaticWarn 'The previous Dramatic Shape VR folder state was restored.' }
            catch { Write-DramaticWarn ('Rollback also needs attention: '+$_.Exception.Message) }
        }
        if (-not $targetExisted -and $target -and (Test-Path -LiteralPath $target -PathType Container)) {
            try { if (@(Get-ChildItem -LiteralPath $target -Force -ErrorAction Stop).Count -eq 0) { Remove-Item -LiteralPath $target -Force } } catch {}
        }
        throw
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function global:Invoke-DramaticShapeVRInstaller {
    Clear-Host
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  Pokemon VR Installer' -ForegroundColor Cyan
    Write-Host '  Current standalone route or pinned Gen1Recomp legacy route' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta; Write-Host ''
    $route = Select-PokemonInstallerRoute
    if ($route -eq 'Legacy') { Invoke-LegacyPokemonRoute }
    else { Invoke-DramaticShapeCurrentRoute }
}

if (((''+$env:PCVR_DRAMATIC_SHAPE_LIBRARY_ONLY).Trim()) -ne '1') { Invoke-DramaticShapeVRInstaller }
