param([string]$GameRoot='', [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
$env:PCVR_ALANWAKE_LIBRARY_ONLY = '1'
. (Join-Path $PSScriptRoot 'AlanWakeVR-core.ps1')

function Finish-AwRemoval([int]$Code) {
    if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to exit' | Out-Null }
    exit $Code
}
try {
    $receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_ALANWAKE_TEST_RECEIPT) {
        $env:PCVR_ALANWAKE_TEST_RECEIPT
    } else { Join-Path $PSScriptRoot '.installed_path' }
    if (-not $GameRoot -and (Test-Path -LiteralPath $receipt -PathType Leaf)) {
        $GameRoot = ([IO.File]::ReadAllText($receipt)).Trim().Trim('"')
    }
    if (-not $GameRoot) { throw 'No Hub-owned Alan Wake VR folder was recorded.' }
    $root = [IO.Path]::GetFullPath($GameRoot)
    if ($env:PCVR_HUB_TEST_MODE -eq '1') { [void](Assert-AwFixture $root) }
    if (-not (Test-Path -LiteralPath (Join-Path $root 'AlanWake.exe') -PathType Leaf)) { throw 'The original Alan Wake game folder is missing.' }
    $manifestPath = Join-Path $root $script:AwManifestName
    $backup = Join-Path $root $script:AwBackupName
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf) -or -not (Test-Path -LiteralPath $backup -PathType Container)) {
        throw 'The Hub ownership record or original-file backup is missing. Nothing was removed.'
    }
    if (Get-Process -Name 'AlanWake' -ErrorAction SilentlyContinue) { throw 'Close Alan Wake before removing VR mode.' }
    $record = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($record.Identity -ne 'alanwakevr') { throw 'The ownership record belongs to another installation.' }
    foreach ($row in @($record.Files)) {
        if ($row.Name -notin $script:AwFiles) { throw 'The ownership record contains an unexpected path.' }
        if ((Get-AwHash (Join-Path $root $row.Name)) -ne [string]$row.AfterHash) {
            throw "$($row.Name) changed after installation. It was preserved; review it before removing the VR mod."
        }
        if ($row.HadBefore -and -not (Test-Path -LiteralPath (Join-Path $backup $row.Name) -PathType Leaf)) {
            throw "The original $($row.Name) backup is missing. Nothing was removed."
        }
    }
    if (-not $HubConfirmed -and (Read-Host "Remove Hub-owned Alan Wake VR from '$root'? Type REMOVE") -cne 'REMOVE') {
        Write-Host 'Cancelled. Nothing changed.'
        Finish-AwRemoval 0
    }
    $work = New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
    $snapshot = Save-AwRollback -Game $root -Work $work
    try {
        $publisherUninstaller = Join-Path $root 'Uninstall_AlanWakeVR.exe'
        if (-not (Test-Path -LiteralPath $publisherUninstaller -PathType Leaf)) { throw 'Publisher uninstaller is missing.' }
        if ($env:PCVR_HUB_TEST_MODE -ne '1') {
            Write-Host '  The publisher uninstaller may request Windows administrator approval.' -ForegroundColor Yellow
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the Alan Wake VR publisher uninstaller...')
        }
        $startArgs = @{FilePath=$publisherUninstaller;Wait=$true;PassThru=$true;ErrorAction='Stop'}
        if ($env:PCVR_HUB_TEST_MODE -eq '1') { $startArgs.WindowStyle='Hidden' }
        $process = Start-Process @startArgs
        if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "Publisher uninstaller ended with exit code $($process.ExitCode)." }
        foreach ($row in @($record.Files)) {
            $target = Join-Path $root $row.Name
            if ($row.HadBefore) { Copy-Item -LiteralPath (Join-Path $backup $row.Name) -Destination $target -Force -ErrorAction Stop }
            elseif (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force -ErrorAction Stop }
        }
        Remove-Item -LiteralPath $manifestPath -Force -ErrorAction Stop
        Remove-Item -LiteralPath (Join-Path $root '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
        if ((Test-Path -LiteralPath $receipt -PathType Leaf) -and ([IO.File]::ReadAllText($receipt)).Trim().Trim('"') -ieq $root) {
            Remove-Item -LiteralPath $receipt -Force -ErrorAction Stop
        }
        Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction Stop
    } catch {
        $failure = $_.Exception.Message
        try { Restore-AwRollback -Game $root -Snapshot $snapshot }
        catch { throw "$failure Rollback needs attention: $($_.Exception.Message)" }
        throw $failure
    } finally { try { Remove-PCVRInstallerTempSession -Path $work } catch { } }
    Write-Host '  [OK] Hub-owned Alan Wake VR files removed; original files restored.' -ForegroundColor Green
    Write-Host '  Alan Wake, saves and unrelated files remain.' -ForegroundColor Gray
    Finish-AwRemoval 0
} catch {
    Write-Host "  [X] $($_.Exception.Message)" -ForegroundColor Red
    Finish-AwRemoval 1
}
