param([Parameter(Mandatory=$true)][string]$RequestFile)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')

$IDENTITY = 'tribes2vr'
$resultPath = ''
$copyAttempted = $false
$required = @()

function Test-WorkerGameRoot([string]$Root) {
    return [bool]($Root -and
        (Test-Path -LiteralPath (Join-Path $Root 'GameData\Tribes2.exe') -PathType Leaf) -and
        ((Test-Path -LiteralPath (Join-Path $Root 'GameData\uninstall_TribesNEXT.exe') -PathType Leaf) -or
         (Test-Path -LiteralPath (Join-Path $Root 'GameData\console_client_patches.cs') -PathType Leaf)))
}

function Restore-WorkerSnapshot([string]$GameRoot,[string]$SnapshotRoot) {
    $recordsPath = Join-Path $SnapshotRoot 'records.csv'
    if (-not (Test-Path -LiteralPath $recordsPath -PathType Leaf)) { throw 'The rollback record is missing.' }
    foreach ($record in @(Import-Csv -LiteralPath $recordsPath)) {
        $relative = [string]$record.Relative
        if (-not $relative -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') { throw 'The rollback record contains an unsafe path.' }
        $target = Join-Path $GameRoot $relative
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction Stop }
        if ([string]$record.Existed -eq 'True') {
            $source = Join-Path (Join-Path $SnapshotRoot 'files') $relative
            if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Rollback data is missing: $relative" }
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop
        }
    }
    $backup = Join-Path $GameRoot 'GameData\.pcvrhub_tribes2vr_backup'
    if (Test-Path -LiteralPath $backup -PathType Container) { Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop }
    $savedBackup = Join-Path $SnapshotRoot 'ownership-backup'
    if (Test-Path -LiteralPath $savedBackup -PathType Container) { Copy-Item -LiteralPath $savedBackup -Destination $backup -Recurse -Force -ErrorAction Stop }
}

try {
    if (-not (Test-Path -LiteralPath $RequestFile -PathType Leaf)) { throw 'The elevation request is missing.' }
    $request = Get-Content -LiteralPath $RequestFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $resultPath = [IO.Path]::GetFullPath([string]$request.ResultPath)
    $action = [string]$request.Action
    if ($action -notin @('Install','Restore','Uninstall')) { throw 'The elevation request is not a supported Tribes 2 VR operation.' }
    $gameRoot = [IO.Path]::GetFullPath([string]$request.GameRoot)

    if ($action -eq 'Restore') {
        Restore-WorkerSnapshot -GameRoot $gameRoot -SnapshotRoot ([IO.Path]::GetFullPath([string]$request.SnapshotRoot))
        $result = [ordered]@{ Success=$true; Removed=0; Restored=0; Preserved=0 }
    } elseif ($action -eq 'Uninstall') {
        $dataRoot = Join-Path $gameRoot 'GameData'
        $removed = Uninstall-OwnedModPayload -GameRoot $dataRoot -Identity $IDENTITY
        if (-not $removed.Found) { throw 'The Tribes 2 VR ownership manifest is missing.' }
        $result = [ordered]@{ Success=$true; Removed=$removed.Removed; Restored=$removed.Restored; Preserved=$removed.Preserved }
    } else {
        if (-not (Test-WorkerGameRoot $gameRoot)) { throw 'The requested folder has no patched Tribes 2 installation.' }
        $sourceRoot = [IO.Path]::GetFullPath([string]$request.SourceRoot)
        $version = [string]$request.Version
        $relative = @('tribes2vr_launcher.exe','tribes2vr.dll','tribes2vr.ini','openvr_api.dll','Tribes2VR.ico')
        foreach ($name in $relative) {
            if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $name) -PathType Leaf)) { throw "The staged package is missing $name." }
        }
        $dataRoot = Join-Path $gameRoot 'GameData'
        $required = @($relative | ForEach-Object { Join-Path $dataRoot $_ }) + @(Join-Path $dataRoot '.pcvrhub_tribes2vr_ownership.csv')
        $copyAttempted = $true
        [void](Install-OwnedModPayload -SourceRoot $sourceRoot -GameRoot $dataRoot -Identity $IDENTITY -KeepExistingRelativePaths @('tribes2vr.ini') -AdoptIdenticalExisting)
        Start-Sleep -Seconds 3
        $missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
        if ($missing.Count) {
            $result = [ordered]@{ Success=$false; FailureKind='MissingAfterCopy'; Error='Required files are missing after the elevated copy check.'; MissingPaths=@($missing) }
            [IO.File]::WriteAllText($resultPath,($result | ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding $false))
            exit 2
        }
        $contract = New-PCVRInstallerContract -Id 'tribes-2-vr' -GameName 'Tribes 2 VR' -Acquisition Discord -AntivirusNotice `
            -DiscordInviteUrl 'https://discord.gg/uAeQkYBM4n' `
            -DiscordDownloadUrl 'https://discord.com/channels/747967102895390741/1548700072697528461/1548700072697528461' `
            -ReleasePageUrl 'https://discord.com/channels/747967102895390741/1548700072697528461' `
            -RequiredInstalledFileGroups @(
                'GameData\Tribes2.exe','GameData\uninstall_TribesNEXT.exe|GameData\console_client_patches.cs',
                'GameData\tribes2vr_launcher.exe','GameData\tribes2vr.dll','GameData\tribes2vr.ini',
                'GameData\openvr_api.dll','GameData\Tribes2VR.ico','GameData\.pcvrhub_tribes2vr_ownership.csv'
            )
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $gameRoot -Version $version `
            -InstalledPathReceiptPaths @([IO.Path]::GetFullPath([string]$request.InstalledPathReceipt)) -Route 'Current')
        $result = [ordered]@{ Success=$true; Removed=0; Restored=0; Preserved=0 }
    }
    [IO.File]::WriteAllText($resultPath,($result | ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding $false))
    exit 0
} catch {
    if ($resultPath) {
        if ($copyAttempted -and $required.Count) {
            $missingAfterCopy = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf -ErrorAction SilentlyContinue) })
            if ($missingAfterCopy.Count) {
                try { [IO.File]::WriteAllText($resultPath,([ordered]@{Success=$false;FailureKind='MissingAfterCopy';Error='Required files are missing during or after the elevated copy check.';MissingPaths=@($missingAfterCopy)} | ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding $false)) } catch {}
                exit 2
            }
        }
        try { [IO.File]::WriteAllText($resultPath,([ordered]@{Success=$false;Error=$_.Exception.Message} | ConvertTo-Json -Compress),(New-Object Text.UTF8Encoding $false)) } catch {}
    }
    exit 1
}
