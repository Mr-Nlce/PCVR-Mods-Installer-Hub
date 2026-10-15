function Test-DishonoredMigrationRelative([string]$Relative) {
    return [bool]($Relative -and -not [IO.Path]::IsPathRooted($Relative) -and
        $Relative -notmatch '[:\x00-\x1F]' -and
        $Relative -notmatch '(^|[\\/])\.{1,2}([\\/]|$)' -and
        $Relative -notmatch '^[\\/]' -and $Relative -notmatch '[\\/]$')
}

function Invoke-DishonoredLegacyMigration {
    param([Parameter(Mandatory=$true)][string]$GameRoot,[switch]$RetainRollback)
    $manifest=Join-PathLexical $GameRoot '.pcvrhub-dishonored-install.tsv'
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { return $null }
    # The first Hub alpha wrote mode/path rows without a hash. Accept only
    # its known payload paths; every live file is copied to the legacy backup
    # before removal because an unhashed row cannot prove unchanged bytes.
    $twoColumnRemove=@('INSTALL.txt','setup_resolution.bat','Binaries\Win32\d3d9.dll',
        'Binaries\Win32\dishonored_vr.ini','Binaries\Win32\dxvk_d3d9.dll',
        'Binaries\Win32\dxvk_stereo.txt','Binaries\Win32\openvr_api.dll',
        'Binaries\Win32\steam_appid.txt')
    $twoColumnRestore=@('Black_266ms.bik','INTRO_LOC.bik','Legal.bik','LogoArkane.bik',
        'LogoBethesda.bik','UE3_logo.bik','ZenimaxLegal.bik','ZenimaxLegalFR.bik') |
        ForEach-Object { 'DishonoredGame\Movies\'+$_ }
    $twoColumnAllowed=@{}
    foreach ($relative in $twoColumnRemove) { $twoColumnAllowed['remove|'+$relative.ToLowerInvariant()]=$true }
    foreach ($relative in $twoColumnRestore) { $twoColumnAllowed['restore|'+$relative.ToLowerInvariant()]=$true }
    $entries=New-Object 'System.Collections.Generic.List[object]'
    $seen=@{}
    foreach ($line in @(Get-Content -LiteralPath $manifest -ErrorAction Stop)) {
        $parts=@($line -split "`t",3)
        $twoColumn=$parts.Count -eq 2
        if ($parts.Count -notin @(2,3) -or $parts[0] -notin @('restore','remove') -or
            -not (Test-DishonoredMigrationRelative $parts[1]) -or
            ($twoColumn -and -not $twoColumnAllowed.ContainsKey(($parts[0]+'|'+$parts[1]).ToLowerInvariant())) -or
            (-not $twoColumn -and $parts[2] -notmatch '^[A-Fa-f0-9]{64}$')) {
            throw 'The old Hub ownership list has an invalid entry. No migration files were changed.'
        }
        $relative=[string]$parts[1]
        $key=$relative.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { throw 'The old Hub ownership list repeats a file. No migration files were changed.' }
        $seen[$key]=$true
        $live=Join-PathLexical $GameRoot $relative
        $parked=if ($relative -ieq 'Binaries\Win32\d3d9.dll') { Join-PathLexical $GameRoot 'Binaries\Win32\d3d9.dll.flat' } else { $null }
        $target=if ($parked -and (Test-Path -LiteralPath $parked -PathType Leaf)) { $parked } else { $live }
        $backup="$live.hubbak"
        $exists=Test-Path -LiteralPath $target -PathType Leaf
        $hash=if ($exists) { (Get-FileHash -LiteralPath $target -Algorithm SHA256 -ErrorAction Stop).Hash } else { '' }
        $isOwned=$exists -and -not $twoColumn -and $hash -ieq $parts[2]
        if ($parts[0] -eq 'restore' -and -not (Test-Path -LiteralPath $backup -PathType Leaf)) {
            throw "Original backup is missing for $relative. No migration files were changed."
        }
        if ($parked -and (Test-Path -LiteralPath $parked -PathType Leaf) -and
            (Test-Path -LiteralPath $live -PathType Leaf) -and
            (Test-Path -LiteralPath $backup -PathType Leaf) -and
            (Get-FileHash -LiteralPath $live -Algorithm SHA256 -ErrorAction Stop).Hash -ine
                (Get-FileHash -LiteralPath $backup -Algorithm SHA256 -ErrorAction Stop).Hash) {
            throw "Another active d3d9.dll is present beside the parked old proxy. No migration files were changed."
        }
        $entries.Add([pscustomobject]@{Mode=$parts[0];Relative=$relative;Live=$live;Target=$target;
            Backup=$backup;Exists=$exists;IsOwned=$isOwned})
    }
    if ($entries.Count -eq 0) { throw 'The old Hub ownership list is empty. No migration files were changed.' }
    $snapshot=Join-Path ([IO.Path]::GetTempPath()) ('pcvr-dishonored-migration-'+[Guid]::NewGuid().ToString('N'))
    $preservedRoot=Join-PathLexical $GameRoot ('DishonoredVR-Legacy-Backup\'+[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,6))
    $paths=New-Object 'System.Collections.Generic.List[string]'
    foreach ($entry in $entries) { foreach ($path in @($entry.Live,$entry.Target,$entry.Backup)) { if (-not $paths.Contains($path)) { $paths.Add($path) } } }
    $paths.Add($manifest)
    $versionMarker=Join-PathLexical $GameRoot '.pcvrhub_version';$paths.Add($versionMarker)
    if ($RetainRollback) {
        # The publisher launcher runs after alpha migration. Keep a before
        # image of the files it may touch so a cancelled or failed update can
        # restore the previous working alpha instead of leaving mixed files.
        foreach ($relative in @(
            'Binaries\Win32\d3d9.dll.dvr-backup',
            'Binaries\Win32\dvr_steamvr32.dll',
            'Binaries\Win32\openvr_api.dll',
            'Binaries\Win32\dishonored_vr.ini',
            'Binaries\Win32\dishonored_vr_install.json',
            'Binaries\Win32\dxvk_d3d9.dll',
            'Binaries\Win32\dxvk_stereo.txt',
            'Binaries\Win32\disable_vr.txt'
        )) {
            $path=Join-PathLexical $GameRoot $relative
            if (-not $paths.Contains($path)) { $paths.Add($path) }
        }
    }
    $snapshots=New-Object 'System.Collections.Generic.List[object]'
    [void][IO.Directory]::CreateDirectory($snapshot)
    $completed=$false
    try {
        for ($i=0;$i -lt $paths.Count;$i++) {
            $path=$paths[$i];$exists=Test-Path -LiteralPath $path -PathType Leaf
            if ($exists) { Copy-Item -LiteralPath $path -Destination (Join-Path $snapshot ([string]$i)) -ErrorAction Stop }
            $snapshots.Add([pscustomobject]@{Path=$path;Exists=$exists;Copy=(Join-Path $snapshot ([string]$i))})
        }
        $preserved=0;$removed=0;$restored=0
        foreach ($entry in $entries) {
            if ($entry.Exists -and -not $entry.IsOwned) {
                $destination=Join-PathLexical $preservedRoot $entry.Relative
                [void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
                Copy-Item -LiteralPath $entry.Target -Destination $destination -ErrorAction Stop
                $preserved++
            }
            if ($entry.Mode -eq 'restore' -and (Test-Path -LiteralPath $entry.Backup -PathType Leaf)) {
                if (Test-Path -LiteralPath $entry.Target -PathType Leaf) { Remove-Item -LiteralPath $entry.Target -Force -ErrorAction Stop }
                Copy-Item -LiteralPath $entry.Backup -Destination $entry.Live -Force -ErrorAction Stop
                Remove-Item -LiteralPath $entry.Backup -Force -ErrorAction Stop
                $restored++
            } elseif ($entry.IsOwned -or ($entry.Exists -and $entry.Mode -eq 'remove')) {
                Remove-Item -LiteralPath $entry.Target -Force -ErrorAction Stop
                $removed++
            }
        }
        Remove-Item -LiteralPath $manifest -Force -ErrorAction Stop
        Remove-Item -LiteralPath $versionMarker -Force -ErrorAction SilentlyContinue
        $completed=$true
        return [pscustomobject]@{Removed=$removed;Restored=$restored;Preserved=$preserved;
            BackupFolder=$(if($preserved){$preservedRoot}else{''});
            RollbackFolder=$(if($RetainRollback){$snapshot}else{''});
            RollbackEntries=$(if($RetainRollback){$snapshots.ToArray()}else{@()})}
    } catch {
        $reason=$_.Exception.Message
        foreach ($item in $snapshots) {
            try {
                if ($item.Exists) {
                    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $item.Path))
                    Copy-Item -LiteralPath $item.Copy -Destination $item.Path -Force -ErrorAction Stop
                } elseif (Test-Path -LiteralPath $item.Path -PathType Leaf) {
                    Remove-Item -LiteralPath $item.Path -Force -ErrorAction Stop
                }
            } catch { throw "Legacy migration failed and rollback could not restore $($item.Path): $($_.Exception.Message)" }
        }
        throw "Legacy migration was rolled back: $reason"
    } finally {
        if (-not $RetainRollback -or -not $completed) {
            Remove-Item -LiteralPath $snapshot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Restore-DishonoredLegacyMigration {
    param([Parameter(Mandatory=$true)][object]$Migration)
    if (-not $Migration.RollbackFolder -or -not (Test-Path -LiteralPath $Migration.RollbackFolder -PathType Container)) {
        throw 'The legacy rollback snapshot is unavailable; no restore was attempted.'
    }
    foreach ($item in @($Migration.RollbackEntries)) {
        if ($item.Exists -and -not (Test-Path -LiteralPath $item.Copy -PathType Leaf)) {
            throw "Legacy rollback is missing a saved file: $($item.Path)"
        }
    }
    foreach ($item in @($Migration.RollbackEntries)) {
        if ($item.Exists) {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $item.Path))
            Copy-Item -LiteralPath $item.Copy -Destination $item.Path -Force -ErrorAction Stop
        } elseif (Test-Path -LiteralPath $item.Path -PathType Leaf) {
            Remove-Item -LiteralPath $item.Path -Force -ErrorAction Stop
        }
    }
    Remove-Item -LiteralPath $Migration.RollbackFolder -Recurse -Force -ErrorAction SilentlyContinue
}

function Complete-DishonoredLegacyMigration {
    param([Parameter(Mandatory=$true)][object]$Migration)
    if ($Migration.RollbackFolder) {
        Remove-Item -LiteralPath $Migration.RollbackFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}
