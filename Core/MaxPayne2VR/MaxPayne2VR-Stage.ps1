# Prepare evilSheep's exact publisher payload without writing a shared loader
# into the live game. This uses the publisher's asset generator on the user's
# own installed files, then the Hub's existing profile store receives the stage.
function New-MP2EvilStage {
    param(
        [Parameter(Mandatory=$true)][string]$Game,
        [Parameter(Mandatory=$true)][string]$Package,
        [Parameter(Mandatory=$true)][string]$Stage
    )
    $python=Join-Path $Package 'setup-files\python\python.exe'
    $generator=Join-Path $Package 'setup-files\tools\compile_local_assets.py'
    $bridge=Join-Path $Package 'setup-files\mp2vr-local-assets.exe'
    $payload=Join-Path $Package 'setup-files\payload'
    $manifest=Join-Path $Package 'setup-files\payload.json'
    foreach($path in @($python,$generator,$bridge,$manifest)) {
        if(-not(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Publisher package is missing $([IO.Path]::GetFileName($path))." }
    }
    if(Test-Path -LiteralPath $Stage) {
        if(@(Get-ChildItem -LiteralPath $Stage -Force -ErrorAction Stop).Count) { throw 'The Max Payne 2 staging folder must be empty.' }
    } else { [void][IO.Directory]::CreateDirectory($Stage) }
    $document=Get-Content -LiteralPath $manifest -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if($document.schema -ne 1 -or -not $document.install_files) { throw 'The publisher payload manifest is invalid.' }
    foreach($name in @($document.install_files)) {
        if([IO.Path]::GetFileName([string]$name) -ne [string]$name -or [string]$name -match '[:\\/]') { throw 'The publisher payload contains an unsafe file name.' }
        if(-not(Test-Path -LiteralPath (Join-Path $payload ([string]$name)) -PathType Leaf)) { throw "The publisher payload is missing $name." }
    }
    $old=$env:PYTHONDONTWRITEBYTECODE
    $launcher=Join-Path (Split-Path -Parent $Stage) ('mp2vr-generate-'+[guid]::NewGuid().ToString('N')+'.py')
    $stdout=Join-Path (Split-Path -Parent $Stage) 'asset-generator-out.txt'
    $stderr=Join-Path (Split-Path -Parent $Stage) 'asset-generator-error.txt'
    try {
        $env:PYTHONDONTWRITEBYTECODE='1'
        [IO.File]::WriteAllText($launcher,"import sys`nsys.path.insert(0, sys.argv[1])`nfrom compile_local_assets import generate`nfrom calibration_defaults import write_calibration_defaults`ngenerate(sys.argv[2], sys.argv[3], sys.argv[4])`nwrite_calibration_defaults(sys.argv[3])`n",(New-Object Text.UTF8Encoding $false))
        $args=@('-B',('"'+$launcher+'"'),('"'+(Split-Path -Parent $generator)+'"'),('"'+$Game+'"'),('"'+$Stage+'"'),('"'+$bridge+'"'))
        $process=Start-Process -FilePath $python -ArgumentList $args -WorkingDirectory $Package -NoNewWindow -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru -Wait -ErrorAction Stop
        if($null -eq $process.ExitCode -or $process.ExitCode -ne 0) {
            if(Test-Path -LiteralPath $stderr -PathType Leaf) { Get-Content -LiteralPath $stderr -Tail 20 | Write-Host -ForegroundColor Yellow }
            if(Test-Path -LiteralPath $stdout -PathType Leaf) { Get-Content -LiteralPath $stdout -Tail 8 | Write-Host -ForegroundColor Yellow }
            throw "The publisher asset generator failed (exit $($process.ExitCode))."
        }
        Write-Host '  [OK] Publisher game assets generated locally.' -ForegroundColor Green
    } finally { $env:PYTHONDONTWRITEBYTECODE=$old; if(Test-Path -LiteralPath $launcher){Remove-Item -LiteralPath $launcher -Force -ErrorAction SilentlyContinue} }
    foreach($name in @($document.install_files)) {
        Copy-Item -LiteralPath (Join-Path $payload ([string]$name)) -Destination (Join-Path $Stage ([string]$name)) -Force -ErrorAction Stop
    }
    foreach($name in @('d3d8.dll','dinput.dll','maxpayne2vr.asi','Max Payne 2 VR.exe','maxpayne2vr_assets.bin','MP2VR_FirstPerson.mp2m')) {
        if(-not(Test-Path -LiteralPath (Join-Path $Stage $name) -PathType Leaf)) { throw "The prepared publisher profile is missing $name." }
    }
    return $Stage
}

function New-MP2BetotronStage {
    param(
        [Parameter(Mandatory=$true)][string]$Extract,
        [Parameter(Mandatory=$true)][string]$Stage
    )
    $mod=Get-ChildItem -LiteralPath $Extract -Directory -Recurse -ErrorAction Stop |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'winmm.dll') -PathType Leaf } |
        Select-Object -First 1 -ExpandProperty FullName
    if(-not $mod) { throw 'The betotron archive has no mod folder with winmm.dll.' }
    if(Test-Path -LiteralPath $Stage) {
        if(@(Get-ChildItem -LiteralPath $Stage -Force -ErrorAction Stop).Count) { throw 'The betotron staging folder must be empty.' }
    } else { [void][IO.Directory]::CreateDirectory($Stage) }
    foreach($name in @('d3d8.dll','d3d9.dll','winmm.dll','dxvk.conf','MaxPayne2VR.ini')) {
        $source=Join-Path $mod $name
        if(-not(Test-Path -LiteralPath $source -PathType Leaf)) { throw "The betotron package is missing $name." }
        Copy-Item -LiteralPath $source -Destination (Join-Path $Stage $name) -ErrorAction Stop
    }
    return $Stage
}

function Test-MP2PersonalSetting([string]$Name) {
    return ($Name -in @('maxpayne2vr_settings.ini','maxpayne2vr_wrist.ini','MaxPayne2VR.ini') -or
        ($Name -match '^maxpayne2vr_.*\.bin$' -and $Name -ine 'maxpayne2vr_assets.bin'))
}

function New-MP2EvilContentStage {
    param([string]$Prepared,[string]$Content)
    [void][IO.Directory]::CreateDirectory($Content)
    foreach($file in @(Get-ChildItem -LiteralPath $Prepared -File -ErrorAction Stop)) {
        if($file.Name -in $script:MP2SlotFiles.A -or (Test-MP2PersonalSetting $file.Name)) { continue }
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $Content $file.Name) -ErrorAction Stop
    }
    return $Content
}

function Save-MP2InstallSnapshot {
    param([string]$Game,[string[]]$Paths,[string]$Destination)
    $gameRoot=[IO.Path]::GetFullPath($Game).TrimEnd('\')+'\'
    [void][IO.Directory]::CreateDirectory($Destination)
    $entries=New-Object System.Collections.Generic.List[object]
    $seen=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach($path in $Paths) {
        $full=[IO.Path]::GetFullPath($path)
        if(-not $full.StartsWith($gameRoot,[StringComparison]::OrdinalIgnoreCase)) { throw "Snapshot path is outside Max Payne 2: $full" }
        if(-not $seen.Add($full)) { continue }
        $exists=Test-Path -LiteralPath $full
        $copy=Join-Path $Destination ([string]$entries.Count)
        $isDirectory=$exists -and (Test-Path -LiteralPath $full -PathType Container)
        if($exists) { Copy-Item -LiteralPath $full -Destination $copy -Recurse -Force -ErrorAction Stop }
        $entries.Add([pscustomobject]@{Path=$full;Copy=$copy;Exists=$exists;Directory=$isDirectory})
    }
    return ,$entries.ToArray()
}

function Restore-MP2InstallSnapshot {
    param([string]$Game,[object[]]$Entries)
    $gameRoot=[IO.Path]::GetFullPath($Game).TrimEnd('\')+'\'
    foreach($entry in $Entries) {
        $full=[IO.Path]::GetFullPath([string]$entry.Path)
        if(-not $full.StartsWith($gameRoot,[StringComparison]::OrdinalIgnoreCase)) { throw "Rollback path is outside Max Payne 2: $full" }
        if(Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop }
        if($entry.Exists) {
            $parent=Split-Path -Parent $full
            [void][IO.Directory]::CreateDirectory($parent)
            Copy-Item -LiteralPath ([string]$entry.Copy) -Destination $full -Recurse -Force -ErrorAction Stop
        }
    }
}

function Initialize-MP2EvilContentOwnership {
    param([string]$Game)
    $manifest=Join-Path $Game '.pcvrhub_mp2evilcontent_ownership.csv'
    if(Test-Path -LiteralPath $manifest -PathType Leaf) { return }
    $receipt=Get-MP2Receipt $Game
    if(-not $receipt -or $receipt.status -ne 'installed') { return }
    $backupRoot=Join-Path $Game '.pcvrhub_mp2evilcontent_backup'
    $management=Join-Path $Game 'MP2VR-Install'
    $rows=New-Object System.Collections.Generic.List[object]
    foreach($property in @($receipt.files.PSObject.Properties)) {
        $name=[string]$property.Name
        if($name -in $script:MP2SlotFiles.A -or (Test-MP2PersonalSetting $name)) { continue }
        if([IO.Path]::GetFileName($name) -ne $name -or $name -match '[:\\/]') { throw 'The old publisher receipt contains an unsafe file name.' }
        $record=$property.Value
        if(-not $record.installed_sha256) { throw "The old publisher receipt lacks a hash for $name." }
        $target=Join-Path $Game $name
        if(Test-Path -LiteralPath $target -PathType Leaf) {
            if((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ine [string]$record.installed_sha256) {
                throw "The old MP2VR file $name was changed. Its data was left untouched."
            }
        }
        $hadOriginal=[bool]$record.original
        if($hadOriginal) {
            $relative=([string]$record.original).Replace('/','\')
            if($relative -notmatch '^originals\\[a-fA-F0-9]{32}\\[^\\/]+$' -or
                [IO.Path]::GetFileName($relative) -ne $name) { throw "The old backup path for $name is invalid." }
            $source=Join-Path $management $relative
            if(-not(Test-Path -LiteralPath $source -PathType Leaf) -or
                (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ine [string]$record.original_sha256) {
                throw "The old original backup for $name is missing or changed."
            }
            [void][IO.Directory]::CreateDirectory($backupRoot)
            Copy-Item -LiteralPath $source -Destination (Join-Path $backupRoot $name) -Force -ErrorAction Stop
        }
        $rows.Add([pscustomobject]@{RelativePath=$name;HadOriginal=$hadOriginal;InstalledSha256=[string]$record.installed_sha256})
    }
    if($rows.Count) {
        $rows | Export-Csv -LiteralPath ($manifest+'.new') -NoTypeInformation -Encoding UTF8
        Move-Item -LiteralPath ($manifest+'.new') -Destination $manifest -Force -ErrorAction Stop
    }
}
