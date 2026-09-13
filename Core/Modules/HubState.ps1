# ============================================================
#  PCVR Mods Installer Hub - durable user state
# ============================================================
# One authoritative document normally lives below LocalAppData. Core\UserData
# holds its byte-for-byte recovery copy. If LocalAppData cannot be created or
# written, HubStateFallback.json becomes the temporary writable authority in
# Core\UserData. Its higher generation is promoted back to LocalAppData once
# that location works again; an ordinary recovery copy never overrides a valid
# LocalAppData document. Install manifests beside a game remain independent
# evidence of what is installed there.
#
# This module is dot-sourced by VRModHub.ps1 before every other module.  It is
# deliberately WPF-free so the regression suite can load it on its own.

$script:HubStateSchemaVersion = 2
$script:HubInstallManifestSchemaVersion = 1
$script:HubStateEnvelopeCache = $null
$script:HubStateEnvelopeCachePath = $null
$script:HubStateEnvelopeCacheLength = -1L
$script:HubStateEnvelopeCacheWriteTicks = -1L
$script:HubImageCacheMigrationChecked = $false
$script:HubVersionCacheMigrationChecked = $false
$script:HubUpdateInfoMigrationChecked = $false
$script:HubWritableDirectoryCache = @{}

function Get-HubLocalApplicationDataRoot {
    # A dedicated override keeps the unavailable/blocked LocalAppData route
    # deterministic in tests without changing the process profile.
    if (Get-Variable -Name HubLocalAppDataRootOverride -Scope Global -ErrorAction SilentlyContinue) {
        return [string]$global:HubLocalAppDataRootOverride
    }
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HUB_TEST_LOCALAPPDATA) {
        try { return [IO.Path]::GetFullPath([string]$env:PCVR_HUB_TEST_LOCALAPPDATA) } catch { return $null }
    }
    try { return [Environment]::GetFolderPath('LocalApplicationData') } catch { return $null }
}

function Get-HubStateRoot {
    if ($global:HubStateRootOverride) { return [string]$global:HubStateRootOverride }
    try {
        $local = Get-HubLocalApplicationDataRoot
        if ($local) { return [IO.Path]::Combine($local, 'PCVR Mods Installer Hub', 'State') }
    } catch {}
    return $null
}

function Get-HubStateFilePath {
    $root = Get-HubStateRoot
    if (-not $root) { return $null }
    return [IO.Path]::Combine($root, 'HubState.json')
}

function Get-HubPortableStateRoot {
    if ($global:HubPortableStateRootOverride) { return [string]$global:HubPortableStateRootOverride }
    $core = if ($global:scriptDir) { [string]$global:scriptDir } elseif ($script:scriptDir) { [string]$script:scriptDir } else { $null }
    if (-not $core) { return $null }
    try { return [IO.Path]::Combine($core, 'UserData') } catch { return $null }
}

function Get-PortableHubStateBackupPath {
    $root = Get-HubPortableStateRoot
    if (-not $root) { return $null }
    return [IO.Path]::Combine($root, 'HubStateBackup.json')
}

function Get-HubFallbackStateFilePath {
    $root = Get-HubPortableStateRoot
    if (-not $root) { return $null }
    return [IO.Path]::Combine($root, 'HubStateFallback.json')
}

function Get-LegacyHubPortableStateRoot {
    if ($global:HubLegacyPortableStateRootOverride) { return [string]$global:HubLegacyPortableStateRootOverride }
    $core = if ($global:scriptDir) { [string]$global:scriptDir } elseif ($script:scriptDir) { [string]$script:scriptDir } else { $null }
    if (-not $core) { return $null }
    try { return [IO.Path]::Combine((Split-Path -Parent $core), 'UserData') } catch { return $null }
}

function Get-LegacyPortableHubStateBackupPath {
    $root = Get-LegacyHubPortableStateRoot
    if (-not $root) { return $null }
    return [IO.Path]::Combine($root, 'HubStateBackup.json')
}

function Get-HubRuntimeRoot {
    if ($global:HubRuntimeRootOverride) { return [string]$global:HubRuntimeRootOverride }
    if ($global:HubStateRootOverride) { return [IO.Path]::Combine([string]$global:HubStateRootOverride, '_Runtime') }
    $candidates = @()
    try {
        $local = Get-HubLocalApplicationDataRoot
        if ($local) { $candidates += [IO.Path]::Combine($local, 'PCVR Mods Installer Hub') }
    } catch {}
    try {
        $portable = Get-HubPortableStateRoot
        if ($portable) { $candidates += [IO.Path]::Combine($portable, 'Runtime') }
    } catch {}
    foreach ($candidate in $candidates) {
        try {
            if (-not (Test-Path -LiteralPath $candidate -PathType Container)) {
                New-Item -ItemType Directory -Path $candidate -Force -ErrorAction Stop | Out-Null
            }
            if (Test-HubDirectoryWritableQuiet -Directory $candidate) { return $candidate }
        } catch {}
    }
    return $null
}

function Get-HubRuntimeCacheRoot {
    $root = Get-HubRuntimeRoot
    if (-not $root) { return $null }
    return [IO.Path]::Combine($root, 'Cache')
}

function Get-HubImageCacheRoot {
    $cache = Get-HubRuntimeCacheRoot
    if (-not $cache) { return $null }
    $target = [IO.Path]::Combine($cache, 'Images')
    try {
        if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Path $target -Force -ErrorAction Stop | Out-Null }
        # Read-only migration runs once per process. Old cache files stay where
        # they are and are copied only if the new cache lacks that name.
        if (-not $script:HubImageCacheMigrationChecked) {
            $script:HubImageCacheMigrationChecked = $true
            $core = if ($global:scriptDir) { [string]$global:scriptDir } elseif ($script:scriptDir) { [string]$script:scriptDir } else { $null }
            if ($core) {
                $legacy = [IO.Path]::Combine($core, 'Assets', 'cache')
                if (Test-Path -LiteralPath $legacy -PathType Container) {
                    foreach ($file in @(Get-ChildItem -LiteralPath $legacy -File -ErrorAction SilentlyContinue)) {
                        if ($file.Extension -notin @('.jpg', '.jpeg', '.png', '.json')) { continue }
                        $destination = [IO.Path]::Combine($target, $file.Name)
                        if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
                            Copy-Item -LiteralPath $file.FullName -Destination $destination -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
        }
    } catch { return $null }
    return $target
}

function Get-HubVersionCacheRoot {
    $cache = Get-HubRuntimeCacheRoot
    if (-not $cache) { return $null }
    $target = [IO.Path]::Combine($cache, 'Versions')
    try {
        if (-not (Test-Path -LiteralPath $target)) { New-Item -ItemType Directory -Path $target -Force -ErrorAction Stop | Out-Null }
        if (-not $script:HubVersionCacheMigrationChecked) {
            $script:HubVersionCacheMigrationChecked = $true
            $core = if ($global:scriptDir) { [string]$global:scriptDir } elseif ($script:scriptDir) { [string]$script:scriptDir } else { $null }
            if ($core) {
                foreach ($name in @('.gh_version_cache', '.web_version_cache', '.ts_version_cache')) {
                    $legacy = [IO.Path]::Combine($core, $name)
                    $destination = [IO.Path]::Combine($target, $name)
                    if ((Test-Path -LiteralPath $legacy -PathType Leaf) -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
                        Copy-Item -LiteralPath $legacy -Destination $destination -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    } catch { return $null }
    return $target
}

function Get-HubRuntimeLogsRoot {
    if ($global:HubRuntimeLogsRootOverride) { return [string]$global:HubRuntimeLogsRootOverride }
    $core = if ($global:scriptDir) { [string]$global:scriptDir } elseif ($script:scriptDir) { [string]$script:scriptDir } else { $null }
    if (-not $core) { return $null }
    return [IO.Path]::Combine($core, 'Logs')
}

function Get-HubUpdateInfoPath {
    $root = Get-HubRuntimeRoot
    if (-not $root) { return $null }
    $target = [IO.Path]::Combine($root, 'Update', 'update_available.json')
    try {
        $parent = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null }
        if (-not $script:HubUpdateInfoMigrationChecked) {
            $script:HubUpdateInfoMigrationChecked = $true
            $core = if ($global:scriptDir) { [string]$global:scriptDir } elseif ($script:scriptDir) { [string]$script:scriptDir } else { $null }
            $legacy = if ($core) { [IO.Path]::Combine($core, '.update_available') } else { $null }
            if ($legacy -and (Test-Path -LiteralPath $legacy -PathType Leaf) -and -not (Test-Path -LiteralPath $target -PathType Leaf)) {
                Copy-Item -LiteralPath $legacy -Destination $target -ErrorAction SilentlyContinue
            }
        }
    } catch { return $null }
    return $target
}

function ConvertTo-HubOrderedValue {
    param($Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [string] -or $Value -is [ValueType]) { return $Value }
    if ($Value -is [Collections.IDictionary]) {
        $ordered = [ordered]@{}
        foreach ($key in @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)) {
            $ordered[$key] = ConvertTo-HubOrderedValue $Value[$key]
        }
        return $ordered
    }
    if ($Value -is [Collections.IEnumerable]) {
        $items = @()
        foreach ($item in $Value) { $items += ,(ConvertTo-HubOrderedValue $item) }
        return $items
    }
    $props = @($Value.PSObject.Properties | Where-Object { $_.MemberType -match 'Property' } | Sort-Object Name)
    if ($Value -is [Management.Automation.PSCustomObject] -or $props.Count -gt 0) {
        $ordered = [ordered]@{}
        foreach ($prop in $props) { $ordered[$prop.Name] = ConvertTo-HubOrderedValue $prop.Value }
        return $ordered
    }
    return $Value
}

function Test-HubStateValueEqual {
    param($Left, $Right)
    try {
        $leftJson = (ConvertTo-HubOrderedValue $Left) | ConvertTo-Json -Depth 20 -Compress
        $rightJson = (ConvertTo-HubOrderedValue $Right) | ConvertTo-Json -Depth 20 -Compress
        return ([string]$leftJson -ceq [string]$rightJson)
    } catch { return $false }
}

function New-HubStateData {
    return [ordered]@{
        games = [ordered]@{}
        settings = [ordered]@{}
    }
}

function ConvertTo-HubJsonStringLiteral {
    param([AllowNull()][string]$Value, [switch]$EscapeHtml)
    if ($null -eq $Value) { return 'null' }
    $builder = New-Object Text.StringBuilder
    [void]$builder.Append('"')
    foreach ($character in $Value.ToCharArray()) {
        $number = [int]$character
        $escaped = $null
        switch ($number) {
            8  { $escaped = '\b' }
            9  { $escaped = '\t' }
            10 { $escaped = '\n' }
            12 { $escaped = '\f' }
            13 { $escaped = '\r' }
            34 { $escaped = '\"' }
            92 { $escaped = '\\' }
        }
        if ($null -ne $escaped) {
            [void]$builder.Append($escaped)
        } elseif ($number -lt 32 -or ($EscapeHtml -and $number -in @(38, 39, 60, 62))) {
            [void]$builder.Append(('\u{0:x4}' -f $number))
        } else {
            [void]$builder.Append($character)
        }
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}

# ConvertTo-Json changed its HTML-character escaping between Windows
# PowerShell 5.1 and PowerShell 7 (for example, an apostrophe is "\u0027" in
# 5.1 but remains an apostrophe in 7). A checksum made from that host-specific
# text can therefore look corrupt after the Hub is launched through a different
# PowerShell host. Build the small JSON subset used by Hub state ourselves so
# the same data always hashes to the same bytes on both runtimes.
function ConvertTo-HubCanonicalJson {
    param($Value, [switch]$EscapeHtml, [switch]$PreservePropertyOrder)
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [string] -or $Value -is [char]) {
        return (ConvertTo-HubJsonStringLiteral -Value ([string]$Value) -EscapeHtml:$EscapeHtml)
    }
    if ($Value -is [bool]) { return $(if ($Value) { 'true' } else { 'false' }) }
    if ($Value -is [DateTime]) {
        $utcText = $Value.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.FFFFFFF'Z'",[Globalization.CultureInfo]::InvariantCulture)
        return (ConvertTo-HubJsonStringLiteral -Value $utcText -EscapeHtml:$EscapeHtml)
    }
    if ($Value -is [DateTimeOffset]) {
        $utcText = $Value.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.FFFFFFF'Z'",[Globalization.CultureInfo]::InvariantCulture)
        return (ConvertTo-HubJsonStringLiteral -Value $utcText -EscapeHtml:$EscapeHtml)
    }
    if ($Value -is [Collections.IDictionary]) {
        $parts = New-Object System.Collections.ArrayList
        $keys = @($Value.Keys | ForEach-Object { [string]$_ })
        if (-not $PreservePropertyOrder) { [Array]::Sort($keys,[StringComparer]::Ordinal) }
        foreach ($key in $keys) {
            $name = ConvertTo-HubJsonStringLiteral -Value $key -EscapeHtml:$EscapeHtml
            $item = ConvertTo-HubCanonicalJson -Value $Value[$key] -EscapeHtml:$EscapeHtml -PreservePropertyOrder:$PreservePropertyOrder
            [void]$parts.Add($name + ':' + $item)
        }
        return '{' + ($parts -join ',') + '}'
    }
    if ($Value -is [Collections.IEnumerable]) {
        $parts = New-Object System.Collections.ArrayList
        foreach ($item in $Value) {
            [void]$parts.Add((ConvertTo-HubCanonicalJson -Value $item -EscapeHtml:$EscapeHtml -PreservePropertyOrder:$PreservePropertyOrder))
        }
        return '[' + ($parts -join ',') + ']'
    }

    $properties = @($Value.PSObject.Properties | Where-Object { $_.MemberType -match 'Property' })
    if ($Value -is [Management.Automation.PSCustomObject] -or $properties.Count -gt 0) {
        if (-not $PreservePropertyOrder) {
            $propertyMap = @{}
            foreach ($property in $properties) { $propertyMap[[string]$property.Name] = $property }
            $propertyNames = @($propertyMap.Keys | ForEach-Object { [string]$_ })
            [Array]::Sort($propertyNames,[StringComparer]::Ordinal)
            $properties = @($propertyNames | ForEach-Object { $propertyMap[$_] })
        }
        $parts = New-Object System.Collections.ArrayList
        foreach ($property in $properties) {
            $name = ConvertTo-HubJsonStringLiteral -Value ([string]$property.Name) -EscapeHtml:$EscapeHtml
            $item = ConvertTo-HubCanonicalJson -Value $property.Value -EscapeHtml:$EscapeHtml -PreservePropertyOrder:$PreservePropertyOrder
            [void]$parts.Add($name + ':' + $item)
        }
        return '{' + ($parts -join ',') + '}'
    }

    $typeCode = [Type]::GetTypeCode($Value.GetType())
    switch ($typeCode) {
        ([TypeCode]::Single)  { return ([single]$Value).ToString('R',[Globalization.CultureInfo]::InvariantCulture) }
        ([TypeCode]::Double)  { return ([double]$Value).ToString('R',[Globalization.CultureInfo]::InvariantCulture) }
        ([TypeCode]::Decimal) { return ([decimal]$Value).ToString([Globalization.CultureInfo]::InvariantCulture) }
        ([TypeCode]::Byte)    { return ([byte]$Value).ToString([Globalization.CultureInfo]::InvariantCulture) }
        ([TypeCode]::SByte)   { return ([sbyte]$Value).ToString([Globalization.CultureInfo]::InvariantCulture) }
        ([TypeCode]::Int16)   { return ([int16]$Value).ToString([Globalization.CultureInfo]::InvariantCulture) }
        ([TypeCode]::UInt16)  { return ([uint16]$Value).ToString([Globalization.CultureInfo]::InvariantCulture) }
        ([TypeCode]::Int32)   { return ([int32]$Value).ToString([Globalization.CultureInfo]::InvariantCulture) }
        ([TypeCode]::UInt32)  { return ([uint32]$Value).ToString([Globalization.CultureInfo]::InvariantCulture) }
        ([TypeCode]::Int64)   { return ([int64]$Value).ToString([Globalization.CultureInfo]::InvariantCulture) }
        ([TypeCode]::UInt64)  { return ([uint64]$Value).ToString([Globalization.CultureInfo]::InvariantCulture) }
    }

    $ordered = ConvertTo-HubOrderedValue $Value
    if (-not [object]::ReferenceEquals($ordered,$Value)) {
        return (ConvertTo-HubCanonicalJson -Value $ordered -EscapeHtml:$EscapeHtml -PreservePropertyOrder:$PreservePropertyOrder)
    }
    return (ConvertTo-HubJsonStringLiteral -Value ([string]$Value) -EscapeHtml:$EscapeHtml)
}

function Get-HubTextHash {
    param([string]$Text)
    $bytes = [Text.Encoding]::UTF8.GetBytes([string]$Text)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $hash = $sha.ComputeHash($bytes) } finally { $sha.Dispose() }
    return ([BitConverter]::ToString($hash).Replace('-', '').ToLowerInvariant())
}

function Get-HubStateDataHash {
    param($Data)
    $json = ConvertTo-HubCanonicalJson -Value $Data
    return (Get-HubTextHash -Text $json)
}

function Test-HubLegacyStateChecksum {
    param($Data, [string]$ExpectedChecksum)
    if ([string]::IsNullOrWhiteSpace($ExpectedChecksum)) { return $false }
    $expected = $ExpectedChecksum.Trim().ToLowerInvariant()
    $legacyTexts = New-Object System.Collections.ArrayList

    # Windows PowerShell 5.1 escaped HTML-sensitive characters. PowerShell 7
    # did not. Recreate both former representations so an existing state file
    # remains recoverable regardless of which host launches the new Hub first.
    [void]$legacyTexts.Add((ConvertTo-HubCanonicalJson -Value $Data -PreservePropertyOrder))
    [void]$legacyTexts.Add((ConvertTo-HubCanonicalJson -Value $Data -EscapeHtml -PreservePropertyOrder))
    try { [void]$legacyTexts.Add(($Data | ConvertTo-Json -Depth 20 -Compress)) } catch {}
    foreach ($text in @($legacyTexts | Select-Object -Unique)) {
        if ((Get-HubTextHash -Text ([string]$text)) -ceq $expected) { return $true }
    }
    return $false
}

function Test-HubDataChecksum {
    param($Data, [string]$ExpectedChecksum)
    if ([string]::IsNullOrWhiteSpace($ExpectedChecksum)) { return $false }
    $expected = $ExpectedChecksum.Trim().ToLowerInvariant()
    if ((Get-HubStateDataHash -Data $Data) -ceq $expected) { return $true }
    return (Test-HubLegacyStateChecksum -Data $Data -ExpectedChecksum $expected)
}

function New-HubStateEnvelopeText {
    param($Data, [long]$Generation)
    $normalized = ConvertTo-HubOrderedValue $Data
    $envelope = [ordered]@{
        schemaVersion = 2
        generation = $Generation
        writtenUtc = [DateTime]::UtcNow.ToString('o')
        checksum = Get-HubStateDataHash -Data $normalized
        data = $normalized
    }
    return ($envelope | ConvertTo-Json -Depth 20)
}

function Read-HubStateEnvelopeFile {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try {
        $parsed = (Get-Content -LiteralPath $Path -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
        if ([int]$parsed.schemaVersion -ne 2 -or $null -eq $parsed.data -or -not $parsed.checksum) { return $null }
        $rawData = $parsed.data
        $data = ConvertTo-HubOrderedValue $rawData
        $expected = ([string]$parsed.checksum).Trim().ToLowerInvariant()
        if (-not (Test-HubDataChecksum -Data $rawData -ExpectedChecksum $expected)) { return $null }
        return [pscustomobject]@{
            Generation = [long]$parsed.generation
            Data = $data
            SourcePath = $Path
        }
    } catch { return $null }
}

function Write-HubTextAtomic {
    param([string]$Path, [string]$Text, [switch]$KeepPrevious)
    if (-not $Path) { throw 'No state path was available.' }
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null }
    $temp = $Path + '.tmp.' + [Guid]::NewGuid().ToString('N')
    $swap = $Path + '.swap'
    $previous = $Path + '.previous'
    $enc = New-Object Text.UTF8Encoding $false
    try {
        [IO.File]::WriteAllText($temp, $Text, $enc)
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $backup = if ($KeepPrevious) { $previous } else { $swap }
            if (Test-Path -LiteralPath $backup -PathType Leaf) { Remove-Item -LiteralPath $backup -Force -ErrorAction Stop }
            [IO.File]::Replace($temp, $Path, $backup, $true)
            if (-not $KeepPrevious -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
                Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue
            }
        } else {
            [IO.File]::Move($temp, $Path)
        }
    } finally {
        if (Test-Path -LiteralPath $temp -PathType Leaf) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
    }
}

function Test-HubFilesByteIdentical {
    param([string]$LeftPath, [string]$RightPath)
    if (-not $LeftPath -or -not $RightPath) { return $false }
    if (-not (Test-Path -LiteralPath $LeftPath -PathType Leaf) -or -not (Test-Path -LiteralPath $RightPath -PathType Leaf)) { return $false }
    $leftStream = $null
    $rightStream = $null
    $sha = $null
    try {
        # Keep this hot state-sync path on System.IO. Get-Item can trigger
        # PowerShell module auto-loading here; on affected systems that adds
        # hundreds of milliseconds and a duplicate type-data error per game.
        $leftInfo = [IO.FileInfo]::new([IO.Path]::GetFullPath($LeftPath))
        $rightInfo = [IO.FileInfo]::new([IO.Path]::GetFullPath($RightPath))
        if (-not $leftInfo.Exists -or -not $rightInfo.Exists) { return $false }
        if ($leftInfo.Length -ne $rightInfo.Length) { return $false }
        $sha = [Security.Cryptography.SHA256]::Create()
        $leftStream = [IO.File]::OpenRead($LeftPath)
        $leftHash = [BitConverter]::ToString($sha.ComputeHash($leftStream))
        $leftStream.Dispose(); $leftStream = $null
        $rightStream = [IO.File]::OpenRead($RightPath)
        $rightHash = [BitConverter]::ToString($sha.ComputeHash($rightStream))
        return ($leftHash -ceq $rightHash)
    } catch {
        return $false
    } finally {
        if ($leftStream) { $leftStream.Dispose() }
        if ($rightStream) { $rightStream.Dispose() }
        if ($sha) { $sha.Dispose() }
    }
}

function Sync-HubPortableStateBackup {
    param([string]$PrimaryPath)
    $portable = Get-PortableHubStateBackupPath
    if (-not $PrimaryPath -or -not $portable) { return $false }
    $primaryEnvelope = Read-HubStateEnvelopeFile -Path $PrimaryPath
    if (-not $primaryEnvelope) { return $false }
    try {
        if (-not (Test-HubFilesByteIdentical -LeftPath $PrimaryPath -RightPath $portable)) {
            $text = [IO.File]::ReadAllText($PrimaryPath)
            Write-HubTextAtomic -Path $portable -Text $text
        }
        $portableEnvelope = Read-HubStateEnvelopeFile -Path $portable
        return [bool]($portableEnvelope -and
            $portableEnvelope.Generation -eq $primaryEnvelope.Generation -and
            (Test-HubFilesByteIdentical -LeftPath $PrimaryPath -RightPath $portable))
    } catch {
        return $false
    }
}

function Remove-LegacyPortableStateBackup {
    param([string]$PrimaryPath)
    $legacy = Get-LegacyPortableHubStateBackupPath
    $portable = Get-PortableHubStateBackupPath
    if (-not $legacy -or -not $portable -or -not (Test-Path -LiteralPath $legacy -PathType Leaf)) { return }
    try {
        if ([IO.Path]::GetFullPath($legacy) -ieq [IO.Path]::GetFullPath($portable)) { return }
        # Delete only the exact file created by older Hub builds, and only
        # after both current copies are valid and byte-identical. Unknown
        # files in the former root-level UserData folder are never touched.
        if (-not (Read-HubStateEnvelopeFile -Path $legacy)) { return }
        if (-not (Read-HubStateEnvelopeFile -Path $portable)) { return }
        if (-not (Test-HubFilesByteIdentical -LeftPath $PrimaryPath -RightPath $portable)) { return }
        Remove-Item -LiteralPath $legacy -Force -ErrorAction Stop
        $legacyRoot = Split-Path -Parent $legacy
        if ((Test-Path -LiteralPath $legacyRoot -PathType Container) -and
            @(Get-ChildItem -LiteralPath $legacyRoot -Force -ErrorAction Stop).Count -eq 0) {
            Remove-Item -LiteralPath $legacyRoot -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}

# Best-effort game-folder recovery must never surface an access-denied error or
# ask for elevation.  In particular, many older games live below Program Files
# and are readable by the Hub but not writable by a normal user.  A PowerShell
# try/catch still records a caught .NET WriteAllText exception in a transcript,
# so use a silent, disposable cmdlet write as the permission probe instead.
function Test-HubDirectoryWritableQuiet {
    param([string]$Directory)
    if ([string]::IsNullOrWhiteSpace($Directory)) { return $false }
    try {
        $full = [IO.Path]::GetFullPath($Directory)
        if ($script:HubWritableDirectoryCache.ContainsKey($full)) {
            return [bool]$script:HubWritableDirectoryCache[$full]
        }
        if (-not (Test-Path -LiteralPath $full -PathType Container)) {
            $script:HubWritableDirectoryCache[$full] = $false
            return $false
        }
        $probe = [IO.Path]::Combine($full, ('.pcvrhub-write-probe.' + [Guid]::NewGuid().ToString('N')))
        Set-Content -LiteralPath $probe -Value '' -NoNewline -Encoding Ascii -ErrorAction SilentlyContinue
        $writable = Test-Path -LiteralPath $probe -PathType Leaf
        if ($writable) { Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue }
        $script:HubWritableDirectoryCache[$full] = [bool]$writable
        return [bool]$writable
    } catch {
        return $false
    }
}

function Test-HubStateTargetWritableQuiet {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    try {
        $parent = Split-Path -Parent $Path
        if (-not $parent) { return $false }
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
        }
        return [bool](Test-HubDirectoryWritableQuiet -Directory $parent)
    } catch { return $false }
}

function Get-HubStateEnvelope {
    param([switch]$Fresh)
    $primary = Get-HubStateFilePath
    $fallback = Get-HubFallbackStateFilePath
    if (-not $primary -and -not $fallback) { return [pscustomobject]@{ Generation = 0L; Data = (New-HubStateData); SourcePath = $null } }
    if (-not $Fresh -and $script:HubStateEnvelopeCache -and $script:HubStateEnvelopeCachePath) {
        # The Hub reads many values during one installed-games scan. Re-reading
        # and checksum-validating the entire state document for every unchanged
        # value made a 120-game scan spend more than ten seconds here alone.
        # A cheap file metadata check keeps the in-memory envelope hot while
        # still noticing an installer/second Hub process that replaced the
        # canonical file behind us.
        try {
            # Use System.IO here, not Get-Item. Besides being substantially
            # cheaper in this hot path, it cannot trigger PowerShell module
            # auto-loading/type-data errors that Start-Transcript would record
            # once for every scanned tile on some Windows PowerShell hosts.
            $cacheInfo = [IO.FileInfo]::new($script:HubStateEnvelopeCachePath)
            if ($cacheInfo.Exists -and [long]$cacheInfo.Length -eq $script:HubStateEnvelopeCacheLength -and
                [long]$cacheInfo.LastWriteTimeUtc.Ticks -eq $script:HubStateEnvelopeCacheWriteTicks) {
                return $script:HubStateEnvelopeCache
            }
        } catch { }
    }

    $primaryEnvelope = if ($primary) { Read-HubStateEnvelopeFile -Path $primary } else { $null }
    $portableFallback = Read-HubStateEnvelopeFile -Path $fallback
    $envelope = $primaryEnvelope
    $recovered = $false
    # HubStateFallback is not an ordinary mirror: it is written only while
    # LocalAppData is unavailable. A newer generation there therefore wins
    # and must be promoted. The normal HubStateBackup remains recovery-only
    # and never overrides a valid LocalAppData document merely by generation.
    if ($primaryEnvelope -and $portableFallback -and $portableFallback.Generation -gt $primaryEnvelope.Generation) {
        $envelope = $portableFallback
        $recovered = $true
    } elseif (-not $envelope) {
        $portableRecovery = Read-HubStateEnvelopeFile -Path (Get-PortableHubStateBackupPath)
        $legacyPortableRecovery = Read-HubStateEnvelopeFile -Path (Get-LegacyPortableHubStateBackupPath)
        $previousRecovery = if ($primary) { Read-HubStateEnvelopeFile -Path ($primary + '.previous') } else { $null }
        $fallbackPrevious = if ($fallback) { Read-HubStateEnvelopeFile -Path ($fallback + '.previous') } else { $null }
        $envelope = @($portableFallback, $portableRecovery, $legacyPortableRecovery, $previousRecovery, $fallbackPrevious) |
            Where-Object { $null -ne $_ } |
            Sort-Object -Property Generation -Descending |
            Select-Object -First 1
        if ($envelope) { $recovered = $true }
    }
    if (-not $envelope) { $envelope = [pscustomobject]@{ Generation = 0L; Data = (New-HubStateData); SourcePath = $null } }

    # Recovery is one-way whenever LocalAppData is writable. If it is still
    # unavailable, keep using the verified portable source without raising an
    # error; the next process start will try the promotion again.
    if ($recovered -and $primary -and (Test-HubStateTargetWritableQuiet -Path $primary)) {
        try {
            $text = New-HubStateEnvelopeText -Data $envelope.Data -Generation $envelope.Generation
            Write-HubTextAtomic -Path $primary -Text $text -KeepPrevious
            $promoted = Read-HubStateEnvelopeFile -Path $primary
            if ($promoted -and $promoted.Generation -eq $envelope.Generation) { $envelope = $promoted }
        } catch {}
    }
    if ($envelope -and $envelope.SourcePath -and $primary -and $envelope.SourcePath -ceq $primary) {
        if (Sync-HubPortableStateBackup -PrimaryPath $primary) {
            Remove-LegacyPortableStateBackup -PrimaryPath $primary
            # Delete the temporary authority only after the canonical and
            # recovery copies are verified at least as new. Its previous-good
            # companion is then redundant as well.
            $fallbackEnvelope = Read-HubStateEnvelopeFile -Path $fallback
            if ($fallback -and (-not $fallbackEnvelope -or $fallbackEnvelope.Generation -le $envelope.Generation)) {
                Remove-Item -LiteralPath $fallback -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath ($fallback + '.previous') -Force -ErrorAction SilentlyContinue
            }
        }
    }
    $script:HubStateEnvelopeCache = $envelope
    $script:HubStateEnvelopeCachePath = if ($envelope -and $envelope.SourcePath) { [string]$envelope.SourcePath } else { $null }
    try {
        $cacheInfo = [IO.FileInfo]::new($script:HubStateEnvelopeCachePath)
        if (-not $cacheInfo.Exists) { throw 'Active state file is missing.' }
        $script:HubStateEnvelopeCacheLength = [long]$cacheInfo.Length
        $script:HubStateEnvelopeCacheWriteTicks = [long]$cacheInfo.LastWriteTimeUtc.Ticks
    } catch {
        $script:HubStateEnvelopeCacheLength = -1L
        $script:HubStateEnvelopeCacheWriteTicks = -1L
    }
    return $envelope
}

function Invoke-HubStateLock {
    param([scriptblock]$Action)
    $mutex = $null
    $held = $false
    try {
        $mutex = New-Object System.Threading.Mutex -ArgumentList $false, 'Local\PCVRModsInstallerHub_State_v2'
        try { $held = $mutex.WaitOne(10000) } catch [Threading.AbandonedMutexException] { $held = $true }
        if (-not $held) { throw 'The Hub state is busy.' }
        return (& $Action)
    } finally {
        if ($held -and $mutex) { try { $mutex.ReleaseMutex() } catch {} }
        if ($mutex) { $mutex.Dispose() }
    }
}

function Save-HubStateData {
    param($Data, [long]$Generation)
    $primary = Get-HubStateFilePath
    $fallback = Get-HubFallbackStateFilePath
    if (-not $primary -and -not $fallback) { return $false }
    $text = New-HubStateEnvelopeText -Data $Data -Generation $Generation
    $verified = $null
    $target = $null
    foreach ($candidate in @($primary, $fallback)) {
        if (-not $candidate -or ($target -and $candidate -ceq $target)) { continue }
        if (-not (Test-HubStateTargetWritableQuiet -Path $candidate)) { continue }
        try {
            Write-HubTextAtomic -Path $candidate -Text $text -KeepPrevious
            $candidateEnvelope = Read-HubStateEnvelopeFile -Path $candidate
            if ($candidateEnvelope -and $candidateEnvelope.Generation -eq $Generation) {
                $target = $candidate
                $verified = $candidateEnvelope
                break
            }
        } catch {}
    }
    if (-not $verified -or -not $target) { throw 'The new Hub state could not be written to LocalAppData or Core\UserData.' }

    # A successful LocalAppData commit refreshes the exact recovery copy and
    # retires any older temporary portable authority. A fallback commit is
    # already checksummed and keeps its own previous-good generation.
    if ($primary -and $target -ceq $primary -and (Sync-HubPortableStateBackup -PrimaryPath $primary)) {
        Remove-LegacyPortableStateBackup -PrimaryPath $primary
        $fallbackEnvelope = Read-HubStateEnvelopeFile -Path $fallback
        if ($fallback -and (-not $fallbackEnvelope -or $fallbackEnvelope.Generation -le $verified.Generation)) {
            Remove-Item -LiteralPath $fallback -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath ($fallback + '.previous') -Force -ErrorAction SilentlyContinue
        }
    }
    $script:HubStateEnvelopeCache = $verified
    $script:HubStateEnvelopeCachePath = $target
    try {
        $cacheInfo = [IO.FileInfo]::new($target)
        if (-not $cacheInfo.Exists) { throw 'Active state file is missing.' }
        $script:HubStateEnvelopeCacheLength = [long]$cacheInfo.Length
        $script:HubStateEnvelopeCacheWriteTicks = [long]$cacheInfo.LastWriteTimeUtc.Ticks
    } catch {
        $script:HubStateEnvelopeCacheLength = -1L
        $script:HubStateEnvelopeCacheWriteTicks = -1L
    }
    return $true
}

# A full installed-games scan may discover or repair many version values at
# once. Persisting each one separately would checksum, atomically replace and
# mirror the complete state document dozens of times. Batch only that scan's
# value mutations in memory, then merge them onto a fresh locked document and
# commit once. Other processes remain safe: their newer values are read under
# the mutex immediately before the merge, so the batch never overwrites an
# unrelated installer result with its old startup snapshot.
$script:HubStateBatchActive = $false
$script:HubStateBatchOverlay = $null
$script:HubStateBatchDeleted = New-Object object

function Start-HubStateBatch {
    if ($script:HubStateBatchActive) { throw 'A Hub state batch is already active.' }
    $script:HubStateBatchOverlay = @{}
    $script:HubStateBatchActive = $true
}

function Stop-HubStateBatch {
    $script:HubStateBatchActive = $false
    $script:HubStateBatchOverlay = $null
}

function Complete-HubStateBatch {
    if (-not $script:HubStateBatchActive) { return }
    $overlay = $script:HubStateBatchOverlay
    Stop-HubStateBatch
    if (-not $overlay -or $overlay.Count -eq 0) { return }

    Invoke-HubStateLock {
        $envelope = Get-HubStateEnvelope -Fresh
        $data = ConvertTo-HubOrderedValue $envelope.Data
        $changed = $false
        foreach ($id in @($overlay.Keys | Sort-Object)) {
            $pending = $overlay[$id]
            $pendingValues = $pending['Values']
            foreach ($name in @($pendingValues.Keys | Sort-Object)) {
                $value = $pendingValues[$name]
                if ([object]::ReferenceEquals($value,$script:HubStateBatchDeleted)) {
                    if ($data.games.Contains($id) -and $data.games[$id].values -and $data.games[$id].values.Contains($name)) {
                        $data.games[$id].values.Remove($name)
                        $changed = $true
                    }
                    continue
                }
                if (-not $data.games.Contains($id)) {
                    $data.games[$id] = [ordered]@{ title = [string]$pending['Title']; values = [ordered]@{} }
                }
                $record = $data.games[$id]
                if (-not $record.Contains('values') -or $null -eq $record.values) { $record.values = [ordered]@{} }
                $clean = [string]$value
                if (-not $record.values.Contains($name) -or ('' + $record.values[$name]) -cne $clean) {
                    $record.title = [string]$pending['Title']
                    $record.values[$name] = $clean
                    $changed = $true
                }
            }
        }
        if ($changed) { [void](Save-HubStateData -Data $data -Generation ($envelope.Generation + 1)) }
    } | Out-Null
}

function Get-HubGameStateId {
    param($Game)
    if (-not $Game) { return $null }
    # CatalogIndex assigns Id to every shipped tile. StateId/GameId remain
    # fallback aliases only for old fixtures or third-party catalog objects.
    foreach ($field in @('Id', 'StateId', 'GameId')) {
        $candidate = '' + $Game.$field
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            return (($candidate.Trim().ToLowerInvariant() -replace '[^a-z0-9._-]', '-') -replace '-+', '-').Trim('-')
        }
    }
    $steam = ('' + $Game.SteamId).Trim()
    if ($steam) { return 'steam-' + (($steam.ToLowerInvariant() -replace '[^a-z0-9._-]', '-') -replace '-+', '-') }
    $bat = ('' + $Game.Bat).Trim()
    if ($bat) {
        $parts = @($bat -split '[\\/]' | Where-Object { $_ })
        if ($parts.Count -gt 1) {
            $folder = (($parts[0].ToLowerInvariant() -replace '[^a-z0-9._-]', '-') -replace '-+', '-').Trim('-')
            if ($folder) {
                if ($folder -in @('lukerossvr', 'reframeworkvr', 'questzdoomshared')) {
                    $sharedTitle = ((('' + $Game.Title).Trim().ToLowerInvariant() -replace '[^a-z0-9._-]', '-') -replace '-+', '-').Trim('-')
                    if ($sharedTitle) { return 'installer-' + $folder + '-' + $sharedTitle }
                }
                return 'installer-' + $folder
            }
        }
    }
    $title = ('' + $Game.Title).Trim().ToLowerInvariant()
    if (-not $title) { return $null }
    return 'title-' + ((($title -replace '[^a-z0-9._-]', '-') -replace '-+', '-').Trim('-'))
}

function Get-LegacyPersistentGameStatePath {
    param($Game, [string]$Name)
    if (-not $Game -or -not $Game.Title -or -not $Name) { return $null }
    $root = Get-HubStateRoot
    if (-not $root) { return $null }
    $safeTitle = ([string]$Game.Title -replace '[^A-Za-z0-9]', '_').Trim('_')
    if (-not $safeTitle) { return $null }
    $key = if ($Game.SteamId) { ([string]$Game.SteamId) + '_' + $safeTitle } else { $safeTitle }
    return [IO.Path]::Combine($root, $key, ($Name + '.txt'))
}

function Get-PersistentGameStatePath {
    param($Game, [string]$Name)
    if (-not (Get-HubGameStateId -Game $Game) -or -not $Name) { return $null }
    return Get-HubStateFilePath
}

# Read only the current canonical/batched value.  This deliberately does NOT
# run either legacy importer below.  Writers need a side-effect-free snapshot:
# during a full scan, Read-PersistentGameStateValue may discover an old
# per-value file and call Write-PersistentGameStateValue to migrate it.  If the
# batched writer calls the migration-aware reader again, the pair recursively
# calls itself until PowerShell reports an invocation-depth overflow.  One old
# value could therefore add several scary TerminatingError records to an
# otherwise successful scan.
function Get-PersistentGameStateSnapshot {
    param($Game, [string]$Name)
    $id = Get-HubGameStateId -Game $Game
    if (-not $id -or -not $Name) {
        return [pscustomobject]@{ Found = $false; Value = $null }
    }
    if ($script:HubStateBatchActive -and $script:HubStateBatchOverlay -and $script:HubStateBatchOverlay.ContainsKey($id)) {
        $pendingValues = $script:HubStateBatchOverlay[$id]['Values']
        if ($pendingValues.ContainsKey($Name)) {
            $pendingValue = $pendingValues[$Name]
            if ([object]::ReferenceEquals($pendingValue,$script:HubStateBatchDeleted)) {
                return [pscustomobject]@{ Found = $true; Value = $null }
            }
            $text = ('' + $pendingValue).Trim()
            return [pscustomobject]@{ Found = $true; Value = $(if ($text) { $text } else { $null }) }
        }
    }
    $envelope = Get-HubStateEnvelope
    try {
        if ($envelope.Data.games.Contains($id)) {
            $record = $envelope.Data.games[$id]
            if ($record.values -and $record.values.Contains($Name)) {
                $value = ('' + $record.values[$Name]).Trim()
                return [pscustomobject]@{ Found = $true; Value = $(if ($value) { $value } else { $null }) }
            }
        }
    } catch {}
    return [pscustomobject]@{ Found = $false; Value = $null }
}

function Read-PersistentGameStateValue {
    param($Game, [string]$Name)
    $id = Get-HubGameStateId -Game $Game
    if (-not $id -or -not $Name) { return $null }
    $snapshot = Get-PersistentGameStateSnapshot -Game $Game -Name $Name
    if ($snapshot.Found) { return $snapshot.Value }

    # Lazy one-time import of the old LocalAppData per-value files.  The old
    # file remains untouched and becomes inert as soon as the canonical value
    # exists.
    $legacy = Get-LegacyPersistentGameStatePath -Game $Game -Name $Name
    if ($legacy -and (Test-Path -LiteralPath $legacy -PathType Leaf)) {
        try {
            $value = ('' + (Get-Content -LiteralPath $legacy -Raw -ErrorAction Stop)).Trim()
            if ($value) {
                Write-PersistentGameStateValue -Game $Game -Name $Name -Value $value
                return $value
            }
        } catch {}
    }
    if ($Name -eq 'user_located' -and (Get-Command Get-UserLocatedFile -ErrorAction SilentlyContinue)) {
        try {
            $hubLegacy = Get-UserLocatedFile -Game $Game
            if ($hubLegacy -and (Test-Path -LiteralPath $hubLegacy -PathType Leaf)) {
                $value = ('' + (Get-Content -LiteralPath $hubLegacy -Raw -ErrorAction Stop)).Trim()
                if ($value) {
                    Write-PersistentGameStateValue -Game $Game -Name $Name -Value $value
                    return $value
                }
            }
        } catch {}
    }
    return $null
}

function Write-PersistentGameStateValue {
    param($Game, [string]$Name, [string]$Value)
    $id = Get-HubGameStateId -Game $Game
    if (-not $id -or -not $Name -or [string]::IsNullOrWhiteSpace($Value)) { return }
    $clean = $Value.Trim()
    if ($script:HubStateBatchActive) {
        # Never use the migration-aware public reader here.  A legacy import
        # reaches this writer from that reader and would recurse indefinitely.
        $known = Get-PersistentGameStateSnapshot -Game $Game -Name $Name
        if ($known.Found -and (('' + $known.Value) -ceq $clean)) { return }
        if (-not $script:HubStateBatchOverlay.ContainsKey($id)) {
            $script:HubStateBatchOverlay[$id] = @{ Title=('' + $Game.Title); Values=@{} }
        }
        $script:HubStateBatchOverlay[$id]['Values'][$Name] = $clean
        return
    }
    # Fast settled-state path. Get-HubStateEnvelope validates the cached
    # document against the canonical file's current metadata, so this remains
    # safe when an installer or another Hub process changed state externally.
    # Only a genuinely different value enters the mutex + full checksum path.
    try {
        $known = Get-HubStateEnvelope
        if ($known.Data.games.Contains($id)) {
            $knownRecord = $known.Data.games[$id]
            if ($knownRecord.values -and $knownRecord.values.Contains($Name) -and
                ('' + $knownRecord.values[$Name]) -ceq $clean) { return }
        }
    } catch {}
    try {
        Invoke-HubStateLock {
            $envelope = Get-HubStateEnvelope -Fresh
            $data = ConvertTo-HubOrderedValue $envelope.Data
            if (-not $data.games.Contains($id)) {
                $data.games[$id] = [ordered]@{ title = ('' + $Game.Title); values = [ordered]@{} }
            }
            $record = $data.games[$id]
            if (-not $record.Contains('values') -or $null -eq $record.values) { $record.values = [ordered]@{} }
            if ($record.values.Contains($Name) -and ('' + $record.values[$Name]) -ceq $clean) { return }
            $record.title = '' + $Game.Title
            $record.values[$Name] = $clean
            [void](Save-HubStateData -Data $data -Generation ($envelope.Generation + 1))
        } | Out-Null
    } catch {}
}

function Reset-PersistentGameStateValue {
    param($Game, [string]$Name)
    $id = Get-HubGameStateId -Game $Game
    if (-not $id -or -not $Name) { return }
    if ($script:HubStateBatchActive) {
        if ($null -eq (Read-PersistentGameStateValue -Game $Game -Name $Name)) { return }
        if (-not $script:HubStateBatchOverlay.ContainsKey($id)) {
            $script:HubStateBatchOverlay[$id] = @{ Title=('' + $Game.Title); Values=@{} }
        }
        $script:HubStateBatchOverlay[$id]['Values'][$Name] = $script:HubStateBatchDeleted
        return
    }
    try {
        Invoke-HubStateLock {
            $envelope = Get-HubStateEnvelope -Fresh
            $data = ConvertTo-HubOrderedValue $envelope.Data
            if (-not $data.games.Contains($id)) { return }
            $record = $data.games[$id]
            if (-not $record.values -or -not $record.values.Contains($Name)) { return }
            $record.values.Remove($Name)
            [void](Save-HubStateData -Data $data -Generation ($envelope.Generation + 1))
        } | Out-Null
    } catch {}
}

function Read-PersistentHubSetting {
    param([string]$Key, $Default = $null)
    if (-not $Key) { return $Default }
    $envelope = Get-HubStateEnvelope
    try { if ($envelope.Data.settings.Contains($Key)) { return $envelope.Data.settings[$Key] } } catch {}

    # Import the old flat settings JSON one key at a time.  Values already in
    # the canonical file are never replaced by the legacy file.
    $core = if ($global:scriptDir) { [string]$global:scriptDir } elseif ($script:scriptDir) { [string]$script:scriptDir } else { $null }
    if ($core) {
        $legacy = [IO.Path]::Combine($core, '.hub-settings.json')
        if (Test-Path -LiteralPath $legacy -PathType Leaf) {
            try {
                $old = (Get-Content -LiteralPath $legacy -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
                $prop = $old.PSObject.Properties[$Key]
                if ($prop) {
                    Write-PersistentHubSetting -Key $Key -Value $prop.Value
                    return $prop.Value
                }
            } catch {}
        }
    }
    return $Default
}

function Write-PersistentHubSetting {
    param([string]$Key, $Value)
    if (-not $Key) { return }
    try {
        $known = Get-HubStateEnvelope
        if ($known.Data.settings.Contains($Key) -and
            (Test-HubStateValueEqual -Left $known.Data.settings[$Key] -Right $Value)) { return }
    } catch {}
    try {
        Invoke-HubStateLock {
            $envelope = Get-HubStateEnvelope -Fresh
            $data = ConvertTo-HubOrderedValue $envelope.Data
            if (-not $data.Contains('settings') -or $null -eq $data.settings) { $data.settings = [ordered]@{} }
            if ($data.settings.Contains($Key) -and (Test-HubStateValueEqual -Left $data.settings[$Key] -Right $Value)) { return }
            $data.settings[$Key] = $Value
            [void](Save-HubStateData -Data $data -Generation ($envelope.Generation + 1))
        } | Out-Null
    } catch {}
}

# Recently Played uses titles for display order but permanent per-game ignores
# use the catalog's stable state ID.  Keeping the mutations here makes the UI
# a consumer of one checksummed transaction instead of teaching each tile how
# to rewrite the durable state document.
function Test-HubRecentlyPlayedIgnored {
    param([string]$GameId)
    if ([string]::IsNullOrWhiteSpace($GameId)) { return $false }
    $ignored = @(Read-PersistentHubSetting -Key 'recentlyPlayedIgnoredGameIds' -Default @())
    return ($ignored -contains $GameId)
}

function Add-HubRecentlyPlayedGame {
    param([string]$Title, [string]$GameId)
    if ([string]::IsNullOrWhiteSpace($Title)) { return $false }
    if ($GameId -and (Test-HubRecentlyPlayedIgnored -GameId $GameId)) { return $false }

    $history = @(Read-PersistentHubSetting -Key 'playHistory' -Default @())
    $next = New-Object System.Collections.ArrayList
    [void]$next.Add($Title)
    foreach ($item in $history) {
        $clean = ('' + $item).Trim()
        if ($clean -and $clean -ne $Title) { [void]$next.Add($clean) }
    }
    while ($next.Count -gt 8) { $next.RemoveAt($next.Count - 1) }
    Write-PersistentHubSetting -Key 'playHistory' -Value $next
    return (@(Read-PersistentHubSetting -Key 'playHistory' -Default @()) | Select-Object -First 1) -eq $Title
}

function Remove-HubRecentlyPlayedGame {
    param([string]$Title, [string]$GameId, [switch]$AlwaysHide)
    if ([string]::IsNullOrWhiteSpace($Title)) { return $false }

    $history = @(Read-PersistentHubSetting -Key 'playHistory' -Default @())
    $next = New-Object System.Collections.ArrayList
    foreach ($item in $history) {
        $clean = ('' + $item).Trim()
        if ($clean -and $clean -ne $Title) { [void]$next.Add($clean) }
    }
    Write-PersistentHubSetting -Key 'playHistory' -Value $next

    if ($AlwaysHide -and -not [string]::IsNullOrWhiteSpace($GameId)) {
        $ignored = @(Read-PersistentHubSetting -Key 'recentlyPlayedIgnoredGameIds' -Default @())
        $ignoreNext = New-Object System.Collections.ArrayList
        foreach ($item in $ignored) {
            $clean = ('' + $item).Trim()
            if ($clean -and $ignoreNext -notcontains $clean) { [void]$ignoreNext.Add($clean) }
        }
        if ($ignoreNext -notcontains $GameId) { [void]$ignoreNext.Add($GameId) }
        Write-PersistentHubSetting -Key 'recentlyPlayedIgnoredGameIds' -Value $ignoreNext
    }

    $stillPresent = @(Read-PersistentHubSetting -Key 'playHistory' -Default @()) -contains $Title
    $ignoreConfirmed = (-not $AlwaysHide) -or (Test-HubRecentlyPlayedIgnored -GameId $GameId)
    return (-not $stillPresent -and $ignoreConfirmed)
}

function Get-HubInstallManifestPath {
    param([string]$GameDir)
    if ([string]::IsNullOrWhiteSpace($GameDir)) { return $null }
    return [IO.Path]::Combine($GameDir, '.pcvrhub.install.json')
}

function Get-HubModStateId {
    param($Game, [switch]$Second)
    $candidate = if ($Second) { '' + $Game.GithubRepoB } else { '' + $Game.GithubRepo }
    if (-not $candidate) { $candidate = if ($Second) { '' + $Game.ModB } else { '' + $Game.Mod } }
    if (-not $candidate) { $candidate = if ($Second) { 'secondary' } else { 'primary' } }
    $safe = (($candidate.Trim().ToLowerInvariant() -replace '[^a-z0-9._-]', '-') -replace '-+', '-').Trim('-')
    if (-not $safe) { $safe = if ($Second) { 'secondary' } else { 'primary' } }
    return $safe
}

function Read-HubInstallManifestVersion {
    param($Game, [string]$GameDir, [switch]$Second)
    $path = Get-HubInstallManifestPath -GameDir $GameDir
    if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try {
        $doc = (Get-Content -LiteralPath $path -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
        if ([int]$doc.schemaVersion -ne 1 -or -not $doc.data -or -not $doc.checksum) { return $null }
        if (-not (Test-HubDataChecksum -Data $doc.data -ExpectedChecksum ([string]$doc.checksum))) { return $null }
        $slot = if ($Second) { 'secondary' } else { 'primary' }
        $id = Get-HubModStateId -Game $Game -Second:$Second
        $match = $doc.data.mods.PSObject.Properties[$id]
        if (-not $match) {
            foreach ($prop in @($doc.data.mods.PSObject.Properties)) {
                if (('' + $prop.Value.slot) -eq $slot) { $match = $prop; break }
            }
        }
        if ($match -and $match.Value.version) { return ('' + $match.Value.version).Trim() }
    } catch {}
    return $null
}

function Write-HubInstallManifestVersion {
    param($Game, [string]$GameDir, [string]$Version, [switch]$Second)
    if (-not $Game -or -not $GameDir -or -not $Version) { return }
    $path = Get-HubInstallManifestPath -GameDir $GameDir
    $slot = if ($Second) { 'secondary' } else { 'primary' }
    $id = Get-HubModStateId -Game $Game -Second:$Second
    try {
        $mods = [ordered]@{}
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $old = (Get-Content -LiteralPath $path -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
            if ([int]$old.schemaVersion -eq 1 -and $old.data -and $old.checksum -and
                (Test-HubDataChecksum -Data $old.data -ExpectedChecksum ([string]$old.checksum))) {
                $existing = $old.data.mods.PSObject.Properties[$id]
                if ($existing -and (('' + $existing.Value.slot) -ceq $slot) -and
                    (('' + $existing.Value.version).Trim() -ceq $Version.Trim()) -and
                    (('' + $old.data.gameId) -ceq (Get-HubGameStateId -Game $Game))) {
                    return
                }
                $oldMods = ConvertTo-HubOrderedValue $old.data.mods
                foreach ($key in @($oldMods.Keys)) {
                    if (('' + $oldMods[$key].slot) -ne $slot) { $mods[$key] = $oldMods[$key] }
                }
            }
        }
        # Keep the audit timestamp stable across PowerShell editions. PowerShell
        # 7 deserializes ISO timestamps as DateTime and drops a trailing zero in
        # fractional seconds when serializing again. Because the manifest data
        # is checksummed, roughly one in ten otherwise-valid writes became
        # unreadable immediately after a JSON round-trip. Whole-second UTC is
        # still human-readable and serializes byte-for-byte on 5.1 and 7.x.
        $auditUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
        $mods[$id] = [ordered]@{ slot = $slot; version = $Version.Trim(); updatedUtc = $auditUtc }
        $data = [ordered]@{
            gameId = Get-HubGameStateId -Game $Game
            title = '' + $Game.Title
            mods = $mods
        }
        $doc = [ordered]@{
            schemaVersion = 1
            checksum = Get-HubStateDataHash -Data $data
            data = $data
        }
        if (-not (Test-HubDirectoryWritableQuiet -Directory (Split-Path -Parent $path))) { return }
        Write-HubTextAtomic -Path $path -Text ($doc | ConvertTo-Json -Depth 12) -KeepPrevious
    } catch {}
}

# Remove only one tracked mod version from the checksummed recovery manifest.
# This is deliberately slot-aware: a confirmed update of the primary mod must
# never erase valid recovery evidence for a second mod installed in the same
# game folder.  An empty, valid manifest is preferable to deleting the file;
# it records no stale version and avoids any broad/destructive file operation.
function Clear-HubInstallManifestVersion {
    param($Game, [string]$GameDir, [switch]$Second)
    if (-not $Game -or -not $GameDir) { return }
    $path = Get-HubInstallManifestPath -GameDir $GameDir
    if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { return }
    $slot = if ($Second) { 'secondary' } else { 'primary' }
    try {
        $old = (Get-Content -LiteralPath $path -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
        if ([int]$old.schemaVersion -ne 1 -or -not $old.data -or -not $old.checksum -or
            -not (Test-HubDataChecksum -Data $old.data -ExpectedChecksum ([string]$old.checksum))) { return }

        $mods = [ordered]@{}
        $removed = $false
        foreach ($prop in @($old.data.mods.PSObject.Properties)) {
            if (('' + $prop.Value.slot) -eq $slot) { $removed = $true; continue }
            $mods[$prop.Name] = ConvertTo-HubOrderedValue $prop.Value
        }
        if (-not $removed) { return }

        $data = [ordered]@{
            gameId = Get-HubGameStateId -Game $Game
            title = '' + $Game.Title
            mods = $mods
        }
        $doc = [ordered]@{
            schemaVersion = 1
            checksum = Get-HubStateDataHash -Data $data
            data = $data
        }
        if (-not (Test-HubDirectoryWritableQuiet -Directory (Split-Path -Parent $path))) { return }
        Write-HubTextAtomic -Path $path -Text ($doc | ConvertTo-Json -Depth 12) -KeepPrevious
    } catch {}
}
