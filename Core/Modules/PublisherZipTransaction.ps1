# File-level rollback for new publisher ZIP installers. The ownership manifest
# remains the authority for update and uninstall; this snapshot covers a failed
# install before the new manifest and receipt can be committed.
function global:Save-PCVRPublisherZipSnapshot {
    param([string]$GameRoot,[string]$Stage,[string]$Identity,[string]$SnapshotRoot,[string[]]$ExtraPaths=@())
    [void][IO.Directory]::CreateDirectory($SnapshotRoot)
    $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $base = [IO.Path]::GetFullPath($Stage).TrimEnd([char[]]'\/')
    foreach ($file in @(Get-ChildItem -LiteralPath $Stage -File -Recurse -ErrorAction Stop)) {
        [void]$names.Add($file.FullName.Substring($base.Length+1).Replace('/','\'))
    }
    $manifestName = ".pcvrhub_${Identity}_ownership.csv"
    $manifest = Join-Path $GameRoot $manifestName
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        foreach ($row in @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)) {
            [void]$names.Add((Assert-PCVROwnedRelativePath -Relative ([string]$row.RelativePath)))
        }
    }
    [void]$names.Add($manifestName)
    [void]$names.Add('.pcvrhub_version')
    foreach ($extra in $ExtraPaths) { [void]$names.Add((Assert-PCVROwnedRelativePath -Relative $extra)) }
    $records = @()
    foreach ($name in $names) {
        $target = Join-OwnedRelativePath -Root $GameRoot -Relative $name
        $key = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($name)).Replace('/','_')
        $exists = Test-Path -LiteralPath $target -PathType Leaf
        $records += [pscustomobject]@{ Name=$name; Key=$key; Exists=$exists }
        if ($exists) { Copy-Item -LiteralPath $target -Destination (Join-Path $SnapshotRoot $key) -Force -ErrorAction Stop }
    }
    $backup = Join-Path $GameRoot ".pcvrhub_${Identity}_backup"
    $hadBackup = Test-Path -LiteralPath $backup -PathType Container
    if ($hadBackup) { Copy-Item -LiteralPath $backup -Destination (Join-Path $SnapshotRoot 'backup') -Recurse -Force -ErrorAction Stop }
    return [pscustomobject]@{ Root=$SnapshotRoot; Records=$records; Backup=$backup; HadBackup=$hadBackup }
}

function global:Restore-PCVRPublisherZipSnapshot {
    param([string]$GameRoot,$Snapshot)
    foreach ($record in $Snapshot.Records) {
        $target = Join-OwnedRelativePath -Root $GameRoot -Relative $record.Name
        if ($record.Exists) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
            Copy-Item -LiteralPath (Join-Path $Snapshot.Root $record.Key) -Destination $target -Force -ErrorAction Stop
        } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
            Remove-Item -LiteralPath $target -Force -ErrorAction Stop
        }
    }
    if (Test-Path -LiteralPath $Snapshot.Backup -PathType Container) {
        Remove-Item -LiteralPath $Snapshot.Backup -Recurse -Force -ErrorAction Stop
    }
    if ($Snapshot.HadBackup) {
        Copy-Item -LiteralPath (Join-Path $Snapshot.Root 'backup') -Destination $Snapshot.Backup -Recurse -Force -ErrorAction Stop
    }
}
