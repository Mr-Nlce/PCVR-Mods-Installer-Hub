# Safe, game-side ownership manifests for small drop-in VR mods.
# The manifest records only files copied by the selected mod package. Shared
# loaders can be installed outside this helper and are therefore never removed.
function global:Join-OwnedRelativePath {
    param([Parameter(Mandatory=$true)][string]$Root,[Parameter(Mandatory=$true)][string]$Relative)
    $value=$Root
    foreach($part in @($Relative -split '[\\/]' | Where-Object { $_ })) { $value=Join-Path $value $part }
    return $value
}

function global:Install-OwnedModPayload {
    param(
        [Parameter(Mandatory=$true)][string]$SourceRoot,
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string]$Identity,
        [string[]]$IncludeRelativePrefixes = @(),
        [string[]]$SkipRelativePaths = @(),
        [string[]]$KeepExistingRelativePaths = @(),
        [switch]$AdoptIdenticalExisting
    )
    $manifest = Join-Path $GameRoot ".pcvrhub_${Identity}_ownership.csv"
    $backupRoot = Join-Path $GameRoot ".pcvrhub_${Identity}_backup"
    $old = @{}
    if (Test-Path -LiteralPath $manifest -PathType Leaf) {
        try { foreach ($row in @(Import-Csv -LiteralPath $manifest)) { $old[[string]$row.RelativePath] = $row } } catch {}
    }
    $skip = @($SkipRelativePaths | ForEach-Object { ([string]$_).Replace('/','\').Trim('\') })
    $include = @($IncludeRelativePrefixes | ForEach-Object { ([string]$_).Replace('/','\').Trim('\') })
    $keep = @($KeepExistingRelativePaths | ForEach-Object { ([string]$_).Replace('/','\').Trim('\') })
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($file in @(Get-ChildItem -LiteralPath $SourceRoot -Recurse -File -ErrorAction Stop)) {
        $sourceBase=[IO.Path]::GetFullPath($SourceRoot).TrimEnd([char[]]"\/")
        $relative = $file.FullName.Substring($sourceBase.Length + 1).Replace('/','\')
        if ($include.Count -gt 0) {
            $included = $false
            foreach ($prefix in $include) {
                if ($relative.Equals($prefix, [StringComparison]::OrdinalIgnoreCase) -or $relative.StartsWith($prefix + '\', [StringComparison]::OrdinalIgnoreCase)) { $included=$true; break }
            }
            if (-not $included) { continue }
        }
        if ($skip -contains $relative) { continue }
        $target = Join-OwnedRelativePath $GameRoot $relative
        if (($keep -contains $relative) -and (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
        $prior = $old[$relative]
        $hadOriginal = $false
        if ($prior) {
            $hadOriginal = ([string]$prior.HadOriginal -eq 'True')
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                $currentSha = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
                if ($prior.InstalledSha256 -and $currentSha -ne [string]$prior.InstalledSha256) {
                    throw "Refusing to overwrite a file changed after installation: $relative"
                }
            }
        } elseif (Test-Path -LiteralPath $target -PathType Leaf) {
            # A standalone build installed by an older Hub may predate ownership
            # manifests.  When its file is byte-identical to the freshly
            # downloaded official payload, adopt it as mod-owned instead of
            # backing the mod up as if it were an original game file.  This is
            # opt-in; normal game-folder installs retain the conservative rule.
            $identicalExisting = $false
            if ($AdoptIdenticalExisting) {
                try { $identicalExisting = ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash) } catch {}
            }
            if (-not $identicalExisting) {
                $hadOriginal = $true
                $backup = Join-OwnedRelativePath $backupRoot $relative
                $parent = Split-Path $backup -Parent
                if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
                Copy-Item -LiteralPath $target -Destination $backup -Force -ErrorAction Stop
            }
        }
        $parent = Split-Path $target -Parent
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force -ErrorAction Stop
        if ((Get-Item -LiteralPath $target).Length -ne $file.Length) { throw "Copy verification failed: $relative" }
        $rows.Add([pscustomobject]@{
            RelativePath=$relative
            HadOriginal=$hadOriginal
            InstalledSha256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        })
    }

    # Retire files dropped by a newer upstream package, but only when the
    # previous installed hash proves the destination is still ours.
    $newNames = @($rows | ForEach-Object RelativePath)
    foreach ($prior in $old.Values) {
        $relative = [string]$prior.RelativePath
        if ($newNames -contains $relative) { continue }
        $target = Join-OwnedRelativePath $GameRoot $relative
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
            $backup = Join-OwnedRelativePath $backupRoot $relative
            if (([string]$prior.HadOriginal -eq 'True') -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
                $parent=Split-Path $target -Parent
                if(-not(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}
                Copy-Item -LiteralPath $backup -Destination $target -Force -ErrorAction Stop
            }
            continue
        }
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne [string]$prior.InstalledSha256) {
            $rows.Add($prior); continue
        }
        $backup = Join-OwnedRelativePath $backupRoot $relative
        if (([string]$prior.HadOriginal -eq 'True') -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
            Copy-Item -LiteralPath $backup -Destination $target -Force -ErrorAction Stop
        } else {
            Remove-Item -LiteralPath $target -Force -ErrorAction Stop
        }
    }
    $tmp = "$manifest.new"
    $rows | Export-Csv -LiteralPath $tmp -NoTypeInformation -Encoding UTF8
    Move-Item -LiteralPath $tmp -Destination $manifest -Force
    return $manifest
}

function global:Uninstall-OwnedModPayload {
    param(
        [Parameter(Mandatory=$true)][string]$GameRoot,
        [Parameter(Mandatory=$true)][string]$Identity,
        [hashtable]$ParkedAlternates = @{}
    )
    $manifest = Join-Path $GameRoot ".pcvrhub_${Identity}_ownership.csv"
    $backupRoot = Join-Path $GameRoot ".pcvrhub_${Identity}_backup"
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { return [pscustomobject]@{Removed=0;Restored=0;Preserved=0;Found=$false} }
    $remaining = New-Object System.Collections.Generic.List[object]
    $removed=0; $restored=0; $preserved=0
    foreach ($row in @(Import-Csv -LiteralPath $manifest)) {
        $relative = [string]$row.RelativePath
        $target = Join-OwnedRelativePath $GameRoot $relative
        if (-not (Test-Path -LiteralPath $target -PathType Leaf) -and $ParkedAlternates.ContainsKey($relative)) {
            $parkedRelative = [string]$ParkedAlternates[$relative]
            $parked = Join-OwnedRelativePath $GameRoot $parkedRelative
            if (Test-Path -LiteralPath $parked -PathType Leaf) { $target=$parked }
        }
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
            $backup = Join-OwnedRelativePath $backupRoot $relative
            if (([string]$row.HadOriginal -eq 'True') -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
                $liveTarget=Join-OwnedRelativePath $GameRoot $relative
                $parent=Split-Path $liveTarget -Parent
                if(-not(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}
                Copy-Item -LiteralPath $backup -Destination $liveTarget -Force -ErrorAction Stop
                $restored++
            }
            continue
        }
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne [string]$row.InstalledSha256) {
            $remaining.Add($row); $preserved++; continue
        }
        $backup = Join-OwnedRelativePath $backupRoot $relative
        if (([string]$row.HadOriginal -eq 'True') -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
            $liveTarget=Join-OwnedRelativePath $GameRoot $relative
            Copy-Item -LiteralPath $backup -Destination $liveTarget -Force -ErrorAction Stop
            if ($target -ne $liveTarget) { Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue }
            $restored++
        } else {
            Remove-Item -LiteralPath $target -Force -ErrorAction Stop
            $removed++
        }
    }
    if ($remaining.Count -gt 0) {
        $remaining | Export-Csv -LiteralPath "$manifest.new" -NoTypeInformation -Encoding UTF8
        Move-Item -LiteralPath "$manifest.new" -Destination $manifest -Force
    } else {
        Remove-Item -LiteralPath $manifest -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $backupRoot) { Remove-Item -LiteralPath $backupRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }
    return [pscustomobject]@{Removed=$removed;Restored=$restored;Preserved=$preserved;Found=$true}
}
