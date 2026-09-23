param([string]$RequestFile='')

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$script:DeusExExpectedExeSha256 = '8266B6B4A5BF25F2F4E8DE068AA3720F6289C962BB1C2BB70A7B1C111BA510A1'
$script:DeusExHighCoreExeSha256 = 'B883591D023650B91C5C8D052C299AE23FE050DB66A221192035C3A9542D7F28'
$script:DeusExHighCoreOffset = 864613
$script:DeusExHighCoreOriginalBytes = [byte[]](0xE8,0x46,0xF0,0xFF,0xFF)
$script:DeusExHighCorePatchedBytes = [byte[]](0x90,0x90,0x90,0x90,0x90)
$script:DeusExIdentity = 'deusexhrvr'
$script:DeusExRegistryPath = 'HKCU:\Software\Eidos\Deus Ex: HRDC\Graphics'
$script:DeusExRegistryReceipt = '.pcvrhub_deusexhrvr_registry.json'
$script:DeusExRequiredPayload = @('d3d11.dll','atidxx32.dll','atiadlxy.dll','DeusExHRVR\DeusExHRVRHost.exe')
$script:DeusExHighCoreMarker = '.pcvrhub_deusexhrvr_highcore'
$script:DeusExRegistryChanges = [ordered]@{ EnableDirectX11=1; StereoMode=1; EnableVSync=0; AntiAliasingMode=0 }

function global:Test-DeusExSupportedExecutable {
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [string]$ExpectedSha256=$script:DeusExExpectedExeSha256,
        [string]$ExpectedPatchedSha256=$script:DeusExHighCoreExeSha256
    )
    $exe=Join-Path $GameRoot 'DXHRDC.exe'
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { return $false }
    try {
        $hash=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
        return [bool]($hash -eq $ExpectedSha256 -or ($ExpectedPatchedSha256 -and $hash -eq $ExpectedPatchedSha256))
    } catch { return $false }
}

function global:New-DeusExHighCoreExecutable {
    param(
        [Parameter(Mandatory=$true)][string]$SourceExe,
        [Parameter(Mandatory=$true)][string]$DestinationExe,
        [string]$ExpectedOriginalSha256=$script:DeusExExpectedExeSha256,
        [string]$ExpectedPatchedSha256=$script:DeusExHighCoreExeSha256,
        [int]$PatchOffset=$script:DeusExHighCoreOffset,
        [byte[]]$OriginalBytes=$script:DeusExHighCoreOriginalBytes,
        [byte[]]$PatchedBytes=$script:DeusExHighCorePatchedBytes
    )
    if (-not (Test-Path -LiteralPath $SourceExe -PathType Leaf)) { throw 'DXHRDC.exe is missing.' }
    $sourceHash=(Get-FileHash -LiteralPath $SourceExe -Algorithm SHA256).Hash
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $DestinationExe))
    if ($sourceHash -eq $ExpectedPatchedSha256) {
        Copy-Item -LiteralPath $SourceExe -Destination $DestinationExe -Force -ErrorAction Stop
        return $ExpectedPatchedSha256
    }
    if ($sourceHash -ne $ExpectedOriginalSha256) { throw 'DXHRDC.exe is not the supported Steam Director''s Cut 2.0.66.0 build.' }
    $bytes=[IO.File]::ReadAllBytes($SourceExe)
    if ($PatchOffset -lt 0 -or ($PatchOffset + $OriginalBytes.Length) -gt $bytes.Length -or $OriginalBytes.Length -ne $PatchedBytes.Length) {
        throw 'The high-core compatibility patch range is invalid for this executable.'
    }
    for ($index=0; $index -lt $OriginalBytes.Length; $index++) {
        if ($bytes[$PatchOffset+$index] -ne $OriginalBytes[$index]) { throw 'The expected high-core patch bytes were not found; DXHRDC.exe was not changed.' }
    }
    for ($index=0; $index -lt $PatchedBytes.Length; $index++) { $bytes[$PatchOffset+$index]=$PatchedBytes[$index] }
    [IO.File]::WriteAllBytes($DestinationExe,$bytes)
    $patchedHash=(Get-FileHash -LiteralPath $DestinationExe -Algorithm SHA256).Hash
    if ($patchedHash -ne $ExpectedPatchedSha256) { Remove-Item -LiteralPath $DestinationExe -Force -ErrorAction SilentlyContinue; throw 'The high-core compatibility patch did not produce the reviewed executable.' }
    return $patchedHash
}

function global:Get-DeusExRegistryState {
    param([ValidateSet('Windows','Fixture')][string]$Backend='Windows',[string]$FixturePath='')
    if ($Backend -eq 'Fixture') {
        if ($FixturePath -and (Test-Path -LiteralPath $FixturePath -PathType Leaf)) {
            return (Get-Content -LiteralPath $FixturePath -Raw | ConvertFrom-Json)
        }
        return [pscustomobject]@{ KeyExisted=$false; Settings=@() }
    }
    $keyExists=Test-Path -LiteralPath $script:DeusExRegistryPath
    $item=if ($keyExists) { Get-Item -LiteralPath $script:DeusExRegistryPath -ErrorAction Stop } else { $null }
    $settings=@()
    foreach ($name in $script:DeusExRegistryChanges.Keys) {
        $exists=[bool]($item -and ($item.GetValueNames() -contains $name))
        $settings += [pscustomobject]@{ Name=$name; Existed=$exists; Value=$(if ($exists) { [int]$item.GetValue($name) } else { $null }) }
    }
    return [pscustomobject]@{ KeyExisted=[bool]$keyExists; Settings=$settings }
}

function global:Set-DeusExRegistryState {
    param($State,[ValidateSet('Windows','Fixture')][string]$Backend='Windows',[string]$FixturePath='')
    if ($Backend -eq 'Fixture') {
        if (-not $FixturePath) { throw 'Fixture registry state requires a file path.' }
        [IO.File]::WriteAllText($FixturePath,($State | ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding $false))
        return
    }
    if (-not (Test-Path -LiteralPath $script:DeusExRegistryPath)) { [void](New-Item -Path $script:DeusExRegistryPath -Force) }
    foreach ($setting in @($State.Settings)) {
        $name=[string]$setting.Name
        if ($name -notin $script:DeusExRegistryChanges.Keys) { throw "Unexpected Deus Ex registry setting: $name" }
        if ([bool]$setting.Existed) {
            [void](New-ItemProperty -LiteralPath $script:DeusExRegistryPath -Name $name -Value ([int]$setting.Value) -PropertyType DWord -Force)
        } else {
            Remove-ItemProperty -LiteralPath $script:DeusExRegistryPath -Name $name -ErrorAction SilentlyContinue
        }
    }
    if (-not [bool]$State.KeyExisted) {
        try {
            $remaining=@((Get-Item -LiteralPath $script:DeusExRegistryPath -ErrorAction Stop).GetValueNames())
            if ($remaining.Count -eq 0) { Remove-Item -LiteralPath $script:DeusExRegistryPath -Force -ErrorAction SilentlyContinue }
        } catch {}
    }
}

function global:Enable-DeusExVrGraphics {
    param([ValidateSet('Windows','Fixture')][string]$Backend='Windows',[string]$FixturePath='')
    $state=Get-DeusExRegistryState -Backend $Backend -FixturePath $FixturePath
    $byName=@{}
    foreach ($entry in @($state.Settings)) { $byName[[string]$entry.Name]=$entry }
    foreach ($name in $script:DeusExRegistryChanges.Keys) {
        $byName[$name]=[pscustomobject]@{Name=$name;Existed=$true;Value=[int]$script:DeusExRegistryChanges[$name]}
    }
    $state.Settings=@($byName.Values)
    $state.KeyExisted=$true
    Set-DeusExRegistryState -State $state -Backend $Backend -FixturePath $FixturePath
}

function global:Restore-DeusExSnapshot {
    param([Parameter(Mandatory=$true)][string]$GameRoot,[Parameter(Mandatory=$true)][string]$SnapshotRoot,[ValidateSet('Windows','Fixture')][string]$RegistryBackend='Windows',[string]$FixtureRegistryPath='')
    $recordsPath=Join-Path $SnapshotRoot 'records.csv'
    if (-not (Test-Path -LiteralPath $recordsPath -PathType Leaf)) { throw 'The Deus Ex rollback record is missing.' }
    foreach ($record in @(Import-Csv -LiteralPath $recordsPath)) {
        $relative=[string]$record.Relative
        if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') { throw 'The Deus Ex rollback record contains an unsafe path.' }
        $target=Join-Path $GameRoot $relative
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction Stop }
        if ([string]$record.Existed -eq 'True') {
            $source=Join-Path (Join-Path $SnapshotRoot 'files') $relative
            if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Rollback data is missing: $relative" }
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop
        }
    }
    $backup=Join-Path $GameRoot ".pcvrhub_${script:DeusExIdentity}_backup"
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop }
    $savedBackup=Join-Path $SnapshotRoot 'ownership-backup'
    if (Test-Path -LiteralPath $savedBackup -PathType Container) { Copy-Item -LiteralPath $savedBackup -Destination $backup -Recurse -Force -ErrorAction Stop }
    $registryState=Get-Content -LiteralPath (Join-Path $SnapshotRoot 'registry-current.json') -Raw | ConvertFrom-Json
    Set-DeusExRegistryState -State $registryState -Backend $RegistryBackend -FixturePath $FixtureRegistryPath
}

function global:Install-DeusExVrOwnedPayload {
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string]$SourceRoot,
        [Parameter(Mandatory=$true)][string]$Version,
        [Parameter(Mandatory=$true)][string]$InstalledPathReceipt,
        [string]$ExpectedExeSha256=$script:DeusExExpectedExeSha256,
        [string]$ExpectedPatchedExeSha256=$script:DeusExHighCoreExeSha256,
        [ValidateSet('Windows','Fixture')][string]$RegistryBackend='Windows',
        [string]$FixtureRegistryPath=''
    )
    if (-not (Test-DeusExSupportedExecutable -GameRoot $GameRoot -ExpectedSha256 $ExpectedExeSha256 -ExpectedPatchedSha256 $ExpectedPatchedExeSha256)) { throw 'Only the Steam Director''s Cut 2.0.66.0 executable supported by this prerelease can be modified.' }
    if (Get-Process -Name 'DXHRDC','DeusExHRVRHost' -ErrorAction SilentlyContinue) { throw 'Deus Ex or its VR host is running. Close it completely and retry.' }
    foreach ($relative in @($script:DeusExRequiredPayload + @('DXHRDC.exe',$script:DeusExHighCoreMarker,'DeusExHRVR.ini'))) {
        if (-not (Test-Path -LiteralPath (Join-Path $SourceRoot $relative) -PathType Leaf)) { throw "The staged release is missing $relative." }
    }

    $registryReceipt=Join-Path $GameRoot $script:DeusExRegistryReceipt
    if (-not (Test-Path -LiteralPath $registryReceipt -PathType Leaf)) {
        $original=Get-DeusExRegistryState -Backend $RegistryBackend -FixturePath $FixtureRegistryPath
        [IO.File]::WriteAllText($registryReceipt,($original | ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding $false))
    }
    [void](Install-OwnedModPayload -SourceRoot $SourceRoot -GameRoot $GameRoot -Identity $script:DeusExIdentity `
        -SkipRelativePaths @('DeusExHRVR.ini') -AdoptIdenticalExisting)
    $configTarget=Join-Path $GameRoot 'DeusExHRVR.ini'
    if (-not (Test-Path -LiteralPath $configTarget -PathType Leaf)) { Copy-Item -LiteralPath (Join-Path $SourceRoot 'DeusExHRVR.ini') -Destination $configTarget -Force -ErrorAction Stop }
    Enable-DeusExVrGraphics -Backend $RegistryBackend -FixturePath $FixtureRegistryPath

    $required=@($script:DeusExRequiredPayload | ForEach-Object { Join-Path $GameRoot $_ }) + @(
        (Join-Path $GameRoot 'DXHRDC.exe'),(Join-Path $GameRoot $script:DeusExHighCoreMarker),
        $configTarget,(Join-Path $GameRoot ".pcvrhub_${script:DeusExIdentity}_ownership.csv"),$registryReceipt
    )
    Start-Sleep -Seconds $(if ($RegistryBackend -eq 'Fixture') { 0 } else { 3 })
    $missing=@($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
    if ($missing.Count) { return [pscustomobject]@{Success=$false;FailureKind='MissingAfterCopy';Error='Required Deus Ex HR VR files are missing after the copy check.';MissingPaths=@($missing)} }

    $contract=New-PCVRInstallerContract -Id 'deus-ex-human-revolution-directors-cut-vr' -GameName 'Deus Ex: Human Revolution Director''s Cut VR' `
        -Acquisition GitHub -AntivirusNotice -ReleasePageUrl 'https://github.com/farmerarmor/DeusExHRVR/releases' `
        -RequiredInstalledFileGroups @(
            'DXHRDC.exe','d3d11.dll','atidxx32.dll','atiadlxy.dll','DeusExHRVR\DeusExHRVRHost.exe',
            'DeusExHRVR.ini','.pcvrhub_deusexhrvr_highcore','.pcvrhub_deusexhrvr_ownership.csv','.pcvrhub_deusexhrvr_registry.json'
        )
    [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $GameRoot -Version $Version `
        -InstalledPathReceiptPaths @($InstalledPathReceipt) -Route Current)
    return [pscustomobject]@{Success=$true;FailureKind='';Error='';MissingPaths=@()}
}

function global:Uninstall-DeusExVrOwnedPayload {
    param([Parameter(Mandatory=$true)][string]$GameRoot,[ValidateSet('Windows','Fixture')][string]$RegistryBackend='Windows',[string]$FixtureRegistryPath='')
    $result=Uninstall-OwnedModPayload -GameRoot $GameRoot -Identity $script:DeusExIdentity
    if (-not $result.Found) { throw 'The Deus Ex HR VR ownership manifest is missing.' }
    if ([int]$result.Preserved -eq 0) {
        $receipt=Join-Path $GameRoot $script:DeusExRegistryReceipt
        if (Test-Path -LiteralPath $receipt -PathType Leaf) {
            $original=Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
            Set-DeusExRegistryState -State $original -Backend $RegistryBackend -FixturePath $FixtureRegistryPath
            Remove-Item -LiteralPath $receipt -Force -ErrorAction Stop
        }
        Remove-Item -LiteralPath (Join-Path $GameRoot '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    }
    return $result
}

if ($RequestFile) {
    $resultPath=''
    try {
        if (-not (Test-Path -LiteralPath $RequestFile -PathType Leaf)) { throw 'The elevation request is missing.' }
        $request=Get-Content -LiteralPath $RequestFile -Raw | ConvertFrom-Json
        $resultPath=[IO.Path]::GetFullPath([string]$request.ResultPath)
        $action=[string]$request.Action
        $gameRoot=[IO.Path]::GetFullPath([string]$request.GameRoot)
        if ($action -eq 'Install') {
            $result=Install-DeusExVrOwnedPayload -GameRoot $gameRoot -SourceRoot ([IO.Path]::GetFullPath([string]$request.SourceRoot)) `
                -Version ([string]$request.Version) -InstalledPathReceipt ([IO.Path]::GetFullPath([string]$request.InstalledPathReceipt))
        } elseif ($action -eq 'Restore') {
            Restore-DeusExSnapshot -GameRoot $gameRoot -SnapshotRoot ([IO.Path]::GetFullPath([string]$request.SnapshotRoot))
            $result=[pscustomobject]@{Success=$true;Removed=0;Restored=0;Preserved=0}
        } elseif ($action -eq 'Uninstall') {
            $result=Uninstall-DeusExVrOwnedPayload -GameRoot $gameRoot
            $result | Add-Member -NotePropertyName Success -NotePropertyValue $true
        } else { throw 'The elevation request is not a supported Deus Ex HR VR operation.' }
        [IO.File]::WriteAllText($resultPath,($result | ConvertTo-Json -Depth 5 -Compress),(New-Object Text.UTF8Encoding $false))
        exit $(if ($result.FailureKind -eq 'MissingAfterCopy') { 2 } else { 0 })
    } catch {
        if ($resultPath) {
            try { [IO.File]::WriteAllText($resultPath,([ordered]@{Success=$false;Error=$_.Exception.Message} | ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding $false)) } catch {}
        }
        exit 1
    }
}
