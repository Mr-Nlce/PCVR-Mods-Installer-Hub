$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$Host.UI.RawUI.WindowTitle = 'Dark Souls II VR Installer'
$script:DS2Id = 'dark-souls-ii-motion-vr'
$script:DS2FilesPage = 'https://www.nexusmods.com/darksouls2/mods/1745?tab=files'
$script:DS2Proof = @('Game\dinput8.dll','Game\DS2VR\openvr_api.dll','Game\DS2VR\input\actions.json',
    'Game\DS2VR\input\bindings_knuckles.json','Game\DS2VR\input\bindings_oculus_touch.json',
    'Game\DS2VR\input\bindings_vive_controller.json','Game\DS2VR\input\bindings_vive_cosmos_controller.json',
    'Game\DS2VR\input\bindings_holographic_controller.json','Game\nvngx_dlss.dll',
    'Game\DS2VR\amd_fidelityfx_dx12.dll','.pcvrhub_ds2vr_ownership.csv')
$script:DS2Ini = @('combat.ini','hands.ini','nr.ini','render.ini','ui.ini') | ForEach-Object { 'DS2VR\' + $_ }
$script:DS2Contract = New-PCVRInstallerContract -Id $script:DS2Id -GameName 'Dark Souls II VR' `
    -Acquisition Nexus -AntivirusNotice -ReleasePageUrl $script:DS2FilesPage `
    -RequiredInstalledFileGroups $script:DS2Proof
$script:DS2TestInput = if ($env:PCVR_DS2_TEST_NONINTERACTIVE -eq '1') { { param($message) '' } } else { $null }

function Wait-DS2([string]$Message) {
    [void](Wait-PCVRExplicitEnter -Message $Message -ReadInput $script:DS2TestInput)
}
function Test-DS2Game([string]$Root) {
    return [bool]($Root -and (Test-Path -LiteralPath (Join-Path $Root 'Game\DarkSoulsII.exe') -PathType Leaf))
}
function Get-DS2GameRoot {
    $fixture = ('' + $env:PCVR_DS2_TEST_GAME).Trim()
    if ($fixture) {
        if (-not (Test-DS2Game $fixture)) { throw 'The selected test folder has no Game\DarkSoulsII.exe.' }
        return (Get-Item -LiteralPath $fixture).FullName
    }
    $found = Find-SteamGameFolder -AppId '335300' -SteamFolderNames @('Dark Souls II Scholar of the First Sin') `
        -ProbeExe 'Game\DarkSoulsII.exe' -HubGameId $script:DS2Id
    if (Test-DS2Game $found) { return (Get-Item -LiteralPath $found).FullName }
    $manual = Get-GameFolderInteractive -GameName 'Dark Souls II Scholar of the First Sin' `
        -ProbeFile 'Game\DarkSoulsII.exe' -ManualUrl $script:DS2FilesPage
    if ($manual -and $manual -notin @('quit','skip') -and (Test-DS2Game $manual)) {
        return (Get-Item -LiteralPath $manual).FullName
    }
    return $null
}
function Get-DS2Archive {
    $fixture = ('' + $env:PCVR_DS2_TEST_ARCHIVE).Trim()
    if ($fixture) {
        if (-not (Test-Path -LiteralPath $fixture -PathType Leaf)) { throw 'The DS2VR fixture archive is missing.' }
        return (Get-Item -LiteralPath $fixture).FullName
    }
    $downloads = Get-PCVRDownloadsFolder
    $existing = if($downloads -and (Test-Path -LiteralPath $downloads -PathType Container)){
        @(Get-ChildItem -LiteralPath $downloads -Filter '*DS2VR*.zip' -File -ErrorAction SilentlyContinue)
    }else{@()}
    if($existing.Count){
        $selected = Find-DS2DownloadedArchive -Downloads $downloads
        if ($selected) { return $selected }
    }else{
        Write-Host '  Nexus requires a login. Choose Manual download on the Files page.' -ForegroundColor White
        Wait-DS2 'Press Enter to open the DS2VR Nexus Files page...'
        Start-Process $script:DS2FilesPage -ErrorAction Stop | Out-Null
        Write-Host '  Return after the manual ZIP download has finished.' -ForegroundColor White
        Wait-DS2 'Press Enter after the Nexus download is complete...'
        $selected = Find-DS2DownloadedArchive -Downloads $downloads
        if ($selected) { return $selected }
    }
    while ($true) {
        $path = ('' + (Read-Host '  Drag the downloaded ZIP here (empty cancels)')).Trim().Trim('"').Trim("'")
        if (-not $path) { throw 'Setup cancelled before changing game files.' }
        if ((Test-Path -LiteralPath $path -PathType Leaf) -and [IO.Path]::GetExtension($path) -ieq '.zip') {
            return (Get-Item -LiteralPath $path).FullName
        }
        Write-Host '  That ZIP path is not available.' -ForegroundColor Yellow
    }
}

function Find-DS2DownloadedArchive([string]$Downloads) {
    if (-not $Downloads -or -not(Test-Path -LiteralPath $Downloads -PathType Container)) { return $null }
    $candidate = Get-ChildItem -LiteralPath $Downloads -Filter '*DS2VR*.zip' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if (-not $candidate) { return $null }
    Write-Host "  Found in your registered Downloads folder: $($candidate.FullName)" -ForegroundColor Cyan
    $choice = ('' + (Read-Host '  Use this archive? [Y/N]')).Trim().ToUpperInvariant()
    if ($choice -in @('Y','YES')) { return $candidate.FullName }
    return $null
}
function New-DS2Stage([string]$Archive,[string]$Work) {
    $outer = Join-Path $Work 'extracted'
    $safe = Test-ZipArchiveEntrySafety -ArchivePath $Archive -DestinationFolder $outer
    if (-not $safe.Inspectable -or -not $safe.Safe -or $safe.EntryCount -lt 10) {
        throw 'The selected ZIP is unreadable, incomplete or contains an unsafe path.'
    }
    Write-Host '  [..] Extracting the VR package; this may take a minute...' -ForegroundColor Gray
    $result = Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $outer -Label 'DS2VR Nexus ZIP' -AllowSkip $false -QuietProgress
    if ([string]$result -ne 'ok') { throw 'The DS2VR ZIP was not extracted.' }
    $payload = Get-ExtractedPayloadRoot -ExtractDir $outer -RelModFile 'dinput8.dll'
    if (-not $payload) { throw 'No DS2VR dinput8.dll was found in the extracted ZIP.' }
    foreach ($rel in @('dinput8.dll','DS2VR\openvr_api.dll','DS2VR\input\actions.json','nvngx_dlss.dll',
        'DS2VR\amd_fidelityfx_dx12.dll','RELEASE-NOTES.md') + $script:DS2Ini + @(
        'DS2VR\input\bindings_knuckles.json','DS2VR\input\bindings_oculus_touch.json',
        'DS2VR\input\bindings_vive_controller.json','DS2VR\input\bindings_vive_cosmos_controller.json',
        'DS2VR\input\bindings_holographic_controller.json')) {
        if (-not (Test-Path -LiteralPath (Join-Path $payload $rel) -PathType Leaf)) {
            throw "The selected ZIP is missing $rel. Nothing was installed."
        }
    }
    $notes = Get-Content -LiteralPath (Join-Path $payload 'RELEASE-NOTES.md') -Raw
    $match = [regex]::Match($notes,'(?im)^#\s+DS2VR\s+(?<v>\d+(?:\.\d+){1,3})\s+release notes\b')
    if (-not $match.Success) { throw 'The publisher package contains no trackable DS2VR release version.' }
    $stage = Join-Path $Work 'stage\Game'
    [void][IO.Directory]::CreateDirectory($stage)
    Write-Host '  [..] Staging the complete publisher package; this may take some seconds...' -ForegroundColor Gray
    foreach ($item in @(Get-ChildItem -LiteralPath $payload -Force)) {
        Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $stage $item.Name) -Recurse -Force -ErrorAction Stop
    }
    return [pscustomobject]@{Root=(Join-Path $Work 'stage');Version=$match.Groups['v'].Value}
}
function Assert-DS2Collisions([string]$Game,[string]$Stage) {
    $gameDir = Join-Path $Game 'Game'
    $manifest = Join-Path $Game '.pcvrhub_ds2vr_ownership.csv'
    $owned = @{}
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        foreach ($row in @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)) {
            $rel = Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)
            $owned[$rel] = $true
        }
    }
    $hook = Join-Path $gameDir 'dinput8.dll'
    if ((Test-Path -LiteralPath $hook -PathType Leaf) -and -not $owned.ContainsKey('Game\dinput8.dll')) {
        $same = ((Get-FileHash -LiteralPath $hook -Algorithm SHA256).Hash -eq
            (Get-FileHash -LiteralPath (Join-Path $Stage 'Game\dinput8.dll') -Algorithm SHA256).Hash)
        if (-not $same) { throw 'Another mod owns Game\dinput8.dll. Remove or move that mod first; DS2VR will not overwrite it.' }
    }
    $shaders = @(Get-ChildItem -LiteralPath (Join-Path $Stage 'Game\shader\addon_shaders') -File -ErrorAction Stop)
    foreach ($shader in $shaders) {
        $relative = 'Game\shader\addon_shaders\' + $shader.Name
        $target = Join-Path $Game $relative
        if ((Test-Path -LiteralPath $target -PathType Leaf) -and -not $owned.ContainsKey($relative)) {
            throw "Existing shader $relative could be from an unsupported Lighting Engine build. Confirm DS2LE 0.9.51 and resolve it manually before installing."
        }
    }
}
function Save-DS2Snapshot([string]$Game,[string]$Stage,[string]$Work) {
    [void][IO.Directory]::CreateDirectory($Work)
    $manifest = Join-Path $Game '.pcvrhub_ds2vr_ownership.csv'
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -Recurse -File)) { $paths.Add($file.FullName.Substring($Stage.Length+1)) }
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        foreach ($row in @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)) {
            $paths.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)))
        }
    }
    foreach ($rel in @('.pcvrhub_ds2vr_ownership.csv','.pcvrhub_ds2vr_ownership.csv.new','.pcvrhub_version')) { $paths.Add($rel) }
    $records = @()
    foreach ($rel in @($paths | Select-Object -Unique)) {
        $source = Join-OwnedRelativePath -Root $Game -Relative $rel
        $exists = Test-Path -LiteralPath $source -PathType Leaf
        $records += [pscustomobject]@{Relative=$rel;Exists=$exists}
        if ($exists) {
            $backup = Join-OwnedRelativePath -Root (Join-Path $Work 'files') -Relative $rel
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $backup))
            Copy-Item -LiteralPath $source -Destination $backup -Force -ErrorAction Stop
        }
    }
    $ownedBackup = Join-Path $Game '.pcvrhub_ds2vr_backup'
    $hadBackup = Test-Path -LiteralPath $ownedBackup -PathType Container
    if ($hadBackup) { Copy-Item -LiteralPath $ownedBackup -Destination (Join-Path $Work 'ownership-backup') -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{Root=$Work;Records=$records;HadBackup=$hadBackup}
}
function Restore-DS2Snapshot([string]$Game,$Snapshot) {
    foreach ($row in @($Snapshot.Records)) {
        $target = Join-OwnedRelativePath -Root $Game -Relative ([string]$row.Relative)
        if ($row.Exists) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath (Join-OwnedRelativePath -Root (Join-Path $Snapshot.Root 'files') -Relative ([string]$row.Relative)) -Destination $target -Force -ErrorAction Stop
        } elseif (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction Stop }
    }
    $ownedBackup = Join-Path $Game '.pcvrhub_ds2vr_backup'
    if (Test-Path -LiteralPath $ownedBackup -PathType Container) { Remove-Item -LiteralPath $ownedBackup -Recurse -Force -ErrorAction Stop }
    if ($Snapshot.HadBackup) { Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'ownership-backup') -Destination $ownedBackup -Recurse -Force -ErrorAction Stop }
}
function Invoke-DS2Installer {
    $work=$null; $game=$null; $snapshot=$null; $changed=$false; $keepWork=$false
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host '  Dark Souls II: Scholar of the First Sin - DS2VR' -ForegroundColor Cyan
        Write-Host '  MixtapeRomeo / SteamVR motion controls' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host '  Only the current Windows 64-bit Steam Scholar build is supported.' -ForegroundColor White
        Write-Host '  Keep the game offline. SteamVR and both controllers are required.' -ForegroundColor White
        Write-Host '  The mod installs beside Game\DarkSoulsII.exe, not above Game.' -ForegroundColor White
        Write-Host '  Other dinput8.dll mods cannot be overwritten or combined blindly.' -ForegroundColor White
        Show-AntivirusNotice -Compact
        Wait-DS2 'Press Enter to locate Dark Souls II...'

        Write-Host ''; Write-Host '--- [1/5] Locate and check the Steam game ---' -ForegroundColor Cyan
        $game = Get-DS2GameRoot
        if (-not $game) { throw 'No valid Scholar of the First Sin game folder was selected.' }
        if (Get-Process -Name 'DarkSoulsII' -ErrorAction SilentlyContinue) { throw 'Close Dark Souls II before installing or updating DS2VR.' }
        if (-not (Test-InstallerTargetWritable -TargetPath (Join-Path $game 'Game'))) { throw 'The game Game folder is not writable.' }
        Write-Host "  [OK] Game\DarkSoulsII.exe found in $game" -ForegroundColor Green

        Write-Host ''; Write-Host '--- [2/5] Choose the Nexus download ---' -ForegroundColor Cyan
        $archive = Get-DS2Archive
        Write-Host "  [OK] Selected: $([IO.Path]::GetFileName($archive))" -ForegroundColor Green
        $tempChoice = Select-PCVRInstallerTempBase -PrimaryPath ([IO.Path]::GetTempPath()) -DownloadsPath (Get-PCVRDownloadsFolder) -MinimumFreeBytes 536870912L
        if (-not $tempChoice.BasePath) { throw 'Not enough writable temporary space. Free space on your temporary or Downloads drive and retry.' }
        $work = New-PCVRInstallerTempSession -BasePath $tempChoice.BasePath
        $stage = New-DS2Stage -Archive $archive -Work $work
        Write-Host "  [OK] Publisher package $($stage.Version) inspected." -ForegroundColor Green

        Write-Host ''; Write-Host '--- [3/5] Check collisions and protect the previous install ---' -ForegroundColor Cyan
        Assert-DS2Collisions -Game $game -Stage $stage.Root
        Write-Host '  [..] Saving a rollback snapshot; this may take some seconds...' -ForegroundColor Gray
        $snapshot = Save-DS2Snapshot -Game $game -Stage $stage.Root -Work (Join-Path $work 'rollback')
        Write-Host '  [OK] Existing files protected.' -ForegroundColor Green

        Write-Host ''; Write-Host '--- [4/5] Install the complete VR package ---' -ForegroundColor Cyan
        $changed = $true
        [void](Install-OwnedModPayload -SourceRoot $stage.Root -GameRoot $game -Identity 'ds2vr' `
            -KeepExistingRelativePaths @($script:DS2Ini | ForEach-Object { 'Game\' + $_ }) `
            -AdoptIdenticalExisting -ProgressLabel 'Installing DS2VR files')
        $watch = @($script:DS2Proof | ForEach-Object { Join-Path $game $_ })
        if (-not (Confirm-PlacedFilesSurvive -Paths $watch -GameDir $game -NoClear)) { throw 'Required DS2VR files disappeared after copying.' }
        $receipt = ('' + $env:PCVR_DS2_TEST_RECEIPT).Trim()
        if (-not $receipt) { $receipt = Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $script:DS2Contract -GameDir $game -Version $stage.Version `
            -InstalledPathReceiptPaths @($receipt) -Route Current)
        $changed = $false

        Write-Host ''; Write-Host '--- [5/5] Setup complete ---' -ForegroundColor Cyan
        Write-Host "  [OK] DS2VR $($stage.Version) installed. Existing DS2VR INIs were kept." -ForegroundColor Green
        Write-Host '  Start SteamVR, then launch Dark Souls II through Steam in offline mode.' -ForegroundColor White
        Write-Host '  Open Start in game and press both grips for the DS2VR settings panel.' -ForegroundColor White
        Write-Host ''
        Write-Host '  Seek souls, not a second dinput8.dll.' -ForegroundColor Magenta
        Wait-DS2 'Press Enter to close setup...'
    } catch {
        if ($changed -and $snapshot -and $game) {
            try { Restore-DS2Snapshot -Game $game -Snapshot $snapshot; Write-Host '  [!!] Previous DS2VR files restored.' -ForegroundColor Yellow }
            catch { $keepWork=$true; Write-Host "  [!!] Rollback needs review. Snapshot kept at $work. $($_.Exception.Message)" -ForegroundColor Red }
        }
        throw
    } finally {
        if ($work -and -not $keepWork) { try { Remove-PCVRInstallerTempSession -Path $work } catch {} }
    }
}
if ($env:PCVR_DS2_LIBRARY_ONLY -ne '1') { Invoke-DS2Installer }
