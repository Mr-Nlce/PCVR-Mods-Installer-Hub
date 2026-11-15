$script:TTWRequirements = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'requirements.json') -Raw | ConvertFrom-Json

function Test-TTWFiles([string]$Root, [string[]]$Files) {
    if (-not $Root -or -not [IO.Directory]::Exists($Root)) { return $false }
    foreach ($file in $Files) {
        if (-not [IO.File]::Exists((Join-Path $Root $file))) { return $false }
    }
    return $true
}

function Test-TTWPatchedExe([string]$Game) {
    try {
        $reader = [IO.BinaryReader]::new([IO.File]::OpenRead((Join-Path $Game 'FalloutNV.exe')))
        try {
            if ($reader.ReadUInt16() -ne 0x5a4d) { return $false }
            $reader.BaseStream.Position = 60
            $offset = $reader.ReadUInt32()
            if ($offset -gt $reader.BaseStream.Length - 24) { return $false }
            $reader.BaseStream.Position = $offset
            if ($reader.ReadUInt32() -ne 0x4550 -or $reader.ReadUInt16() -ne 0x014c) { return $false }
            $reader.BaseStream.Position = $offset + 22
            return [bool]($reader.ReadUInt16() -band 0x20)
        } finally { $reader.Dispose() }
    } catch { return $false }
}

function Get-TTWActiveMods([string]$ModList, [string]$Mods) {
    if (-not [IO.File]::Exists($ModList) -or -not [IO.Directory]::Exists($Mods)) { return }
    foreach ($line in [IO.File]::ReadLines($ModList)) {
        if ($line -match '^\+([^\\/:*?"<>|]+)$' -and $Matches[1] -notin @('.', '..')) {
            $candidate = Join-Path $Mods $Matches[1]
            if ([IO.Directory]::Exists($candidate)) { $candidate }
        }
    }
}

function Test-TTWEffectiveFile([string[]]$Roots, [string]$File) {
    foreach ($root in $Roots) {
        if ([IO.File]::Exists((Join-Path $root $File))) { return $true }
    }
    return $false
}

function Get-TTWMo2Setting([string]$Config, [string]$Section, [string]$Key) {
    $sectionPattern = '(?im)^\[' + [regex]::Escape($Section) + '\][ \t]*\r?\n(?<body>(?:(?!^\[)[\s\S])*)'
    $body = [regex]::Match($Config,$sectionPattern).Groups['body'].Value
    $value = [regex]::Match($body,('(?im)^[ \t]*' + [regex]::Escape($Key) + '[ \t]*=([^\r\n]*)'))
    if ($value.Success) { return $value.Groups[1].Value.Trim().Trim('"') }
}

function Get-TTWIniGame([string]$Ini) {
    $path = Get-TTWMo2Setting ([IO.File]::ReadAllText($Ini)) 'General' 'gamePath'
    if (-not $path) { return }
    # MO2 stores the UTF-8 path as a QSettings QByteArray, escaping bytes and backslashes.
    if ($path.StartsWith('@ByteArray(') -and $path.EndsWith(')')) {
        $encoded = $path.Substring(11,$path.Length-12)
        $bytes = [Collections.Generic.List[byte]]::new()
        $parts = [regex]::Matches($encoded,'\\x([0-9a-fA-F]{1,2})|\\([\\"])|([^\\]+)')
        if (($parts | ForEach-Object Value) -join '' -cne $encoded) { return }
        foreach ($part in $parts) {
            if ($part.Groups[1].Success) { $bytes.Add([Convert]::ToByte($part.Groups[1].Value,16)) }
            elseif ($part.Groups[2].Success) { $bytes.Add([byte][char]$part.Groups[2].Value) }
            else { $bytes.AddRange([Text.Encoding]::UTF8.GetBytes($part.Value)) }
        }
        try { $path = [Text.UTF8Encoding]::new($false,$true).GetString($bytes.ToArray()) } catch { return }
    } else { $path = $path.Replace('\\','\') }
    if ([IO.Directory]::Exists($path)) { return (Get-Item -LiteralPath $path).FullName.TrimEnd('\') }
}

function Get-TTWInstalledState([string]$Root, [string]$Mode, [switch]$ForModUpdate) {
    try {
        if (-not (Test-TTWFiles $Root @('ttwvr-install.json','Start-TTWVR.cmd','Start-TTWVR.ps1','TTWVR-State.ps1','requirements.json'))) { return }
        $state = Get-Content -LiteralPath (Join-Path $Root 'ttwvr-install.json') -Raw | ConvertFrom-Json
        if ($state.schema -ne 1 -or $state.mode -cne $Mode -or $state.profileName -notmatch '^[^\\/:*?"<>|]+$' -or
            $state.profileName -in @('.','..') -or (Split-Path -Leaf $state.profile) -cne $state.profileName -or
            (Split-Path -Leaf $state.mo2) -ine 'ModOrganizer.exe' -or -not [IO.File]::Exists($state.mo2) -or
            -not [IO.File]::Exists($state.ini) -or (Get-TTWIniGame $state.ini) -ine $state.game.TrimEnd('\') -or
            -not (Test-TTWFiles $state.game $script:TTWRequirements.NewVegas) -or
            -not (Test-TTWFiles $state.game $script:TTWRequirements.xNVSE) -or -not (Test-TTWPatchedExe $state.game) -or
            [IO.File]::Exists((Join-Path $state.game 'd3d9.dll'))) { return }
        $modName = 'PCVR Hub TTWVR ' + $Mode
        $owned = Join-Path $state.mods $modName
        $active = @(Get-TTWActiveMods (Join-Path $state.profile 'modlist.txt') $state.mods)
        if ($active.Count -eq 0 -or $active[0] -ine $owned -or
            -not [IO.File]::Exists((Join-Path $owned '.pcvrhub_ttwvr_ownership.csv'))) { return }
        if (-not $ForModUpdate -and -not (Test-TTWFiles $owned $script:TTWRequirements.TTWVR)) { return }
        $effective = $active + (Join-Path $state.game 'Data')
        foreach ($plugin in $script:TTWRequirements.plugins) {
            if (-not (Test-TTWEffectiveFile $effective $plugin)) { return }
        }
        if ($Mode -eq 'Wastelands') {
            if (-not (Test-TTWFiles $state.fallout3 $script:TTWRequirements.Fallout3)) { return }
            foreach ($archive in $script:TTWRequirements.TTWData) {
                if (-not (Test-TTWEffectiveFile $effective $archive)) { return }
            }
            $enabled = [IO.File]::ReadAllLines((Join-Path $state.profile 'plugins.txt'))
            foreach ($plugin in $script:TTWRequirements.TTW) {
                if ($plugin -notin $enabled -and ('*' + $plugin) -notin $enabled) { return }
                if (-not (Test-TTWEffectiveFile $effective $plugin)) { return }
            }
        } elseif (Test-TTWEffectiveFile $effective 'TaleOfTwoWastelands.esm') { return }
        return $state
    } catch { return }
}
