# Windows Downloads is a Known Folder, not a child guaranteed to live under
# UserProfile. Explorer's Location tab writes this GUID to User Shell Folders.
function global:Get-PCVRDownloadsFolder {
    [CmdletBinding()]
    param()

    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_TEST_DOWNLOADS_DIR) {
        $fixture = [IO.Path]::GetFullPath($env:PCVR_TEST_DOWNLOADS_DIR)
        $tempRoots = @([IO.Path]::GetTempPath())
        if ($env:LOCALAPPDATA) { $tempRoots += (Join-Path $env:LOCALAPPDATA 'Temp') }
        $insideTemp = $false
        foreach ($root in $tempRoots) {
            $prefix = [IO.Path]::GetFullPath($root).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
            if ($fixture.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { $insideTemp = $true; break }
        }
        if (-not $insideTemp -or
            -not (Test-Path -LiteralPath (Join-Path $fixture 'pcvr-downloads-fixture.txt') -PathType Leaf)) {
            throw 'Downloads test fixture must stay in an isolated temporary folder.'
        }
        return $fixture
    }

    $downloadsId = '{374DE290-123F-4565-9164-39C4925E467B}'
    $explorerKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
    foreach ($subkey in @('User Shell Folders','Shell Folders')) {
        try {
            $properties = Get-ItemProperty -Path (Join-Path $explorerKey $subkey) -Name $downloadsId -ErrorAction Stop
            $raw = [string]$properties.PSObject.Properties[$downloadsId].Value
            $expanded = [Environment]::ExpandEnvironmentVariables($raw.Trim().Trim('"'))
            if ($expanded -and [IO.Path]::IsPathRooted($expanded)) {
                # Keep the registered location even when its drive is offline.
                # Searching a different profile folder could pick the wrong ZIP.
                return [IO.Path]::GetFullPath($expanded)
            }
        } catch { }
    }
    $profile = [Environment]::GetFolderPath('UserProfile')
    if (-not $profile) { $profile = $env:USERPROFILE }
    if ($profile) { return [IO.Path]::GetFullPath((Join-Path $profile 'Downloads')) }
    return $null
}

# Installer downloads and extraction use TEMP/TMP in a separate wrapper
# process. Resolve a space fallback without changing the Hub or Windows user
# environment. Keep the probe tiny; real payload size is not known here.
function global:Get-PCVRInstallerVolumeFreeBytes {
    param([Parameter(Mandatory=$true)][string]$Path)
    try {
        $root = [IO.Path]::GetPathRoot([IO.Path]::GetFullPath($Path))
        if (-not $root) { return -1L }
        return [long]([IO.DriveInfo]::new($root).AvailableFreeSpace)
    } catch { return -1L }
}

function global:Test-PCVRInstallerTempWritable {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    $probe = Join-Path $Path ('pcvr-temp-probe-' + [Guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllText($probe, 'pcvr')
        return $true
    } catch { return $false }
    finally { try { if (Test-Path -LiteralPath $probe -PathType Leaf) { Remove-Item -LiteralPath $probe -Force -ErrorAction Stop } } catch {} }
}

function global:Select-PCVRInstallerTempBase {
    param(
        [Parameter(Mandatory=$true)][string]$PrimaryPath,
        [string]$DownloadsPath,
        [long]$MinimumFreeBytes = 4294967296L,
        [scriptblock]$FreeBytes = ${function:Get-PCVRInstallerVolumeFreeBytes},
        [scriptblock]$Writable = ${function:Test-PCVRInstallerTempWritable}
    )
    $primary = [IO.Path]::GetFullPath($PrimaryPath)
    $primaryFree = [long](& $FreeBytes $primary)
    $primaryWritable = [bool](& $Writable $primary)
    if ($primaryWritable -and $primaryFree -ge $MinimumFreeBytes) {
        return [pscustomobject]@{ NeedsFallback=$false; BasePath=$primary; PrimaryFreeBytes=$primaryFree; Reason='' }
    }
    $reason = if (-not $primaryWritable) { 'The current temporary folder is not writable.' }
              else { 'The current temporary drive has less than 4 GB free.' }
    if ($DownloadsPath) {
        try {
            $candidate = [IO.Path]::GetFullPath($DownloadsPath)
            $sameVolume = [string]::Equals([IO.Path]::GetPathRoot($primary),[IO.Path]::GetPathRoot($candidate),[StringComparison]::OrdinalIgnoreCase)
            $candidateFree = [long](& $FreeBytes $candidate)
            if ((-not $sameVolume -or -not $primaryWritable) -and $candidateFree -ge 536870912L -and
                ($candidateFree -gt $primaryFree -or -not $primaryWritable) -and [bool](& $Writable $candidate)) {
                return [pscustomobject]@{ NeedsFallback=$true; BasePath=$candidate; PrimaryFreeBytes=$primaryFree; Reason=$reason }
            }
        } catch {}
    }
    return [pscustomobject]@{ NeedsFallback=$true; BasePath=''; PrimaryFreeBytes=$primaryFree; Reason=$reason }
}

function global:New-PCVRInstallerTempSession {
    param([Parameter(Mandatory=$true)][string]$BasePath)
    if (-not (Test-PCVRInstallerTempWritable $BasePath)) { throw "Temporary fallback folder is not writable: $BasePath" }
    $parent = Join-Path ([IO.Path]::GetFullPath($BasePath)) 'PCVR Mods Hub Temp'
    [void][IO.Directory]::CreateDirectory($parent)
    $session = Join-Path $parent ('install-' + [Guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($session)
    return $session
}

function global:Remove-PCVRInstallerTempSession {
    param([string]$Path)
    if (-not $Path) { return }
    $full = [IO.Path]::GetFullPath($Path)
    $parent = Split-Path -Parent $full
    if ((Split-Path -Leaf $parent) -cne 'PCVR Mods Hub Temp' -or
        (Split-Path -Leaf $full) -cnotmatch '^install-[0-9a-f]{32}$') {
        throw 'Refusing to remove a folder outside the owned installer temp session.'
    }
    if (Test-Path -LiteralPath $full -PathType Container) {
        Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop
    }
    if (Test-Path -LiteralPath $parent -PathType Container -ErrorAction SilentlyContinue) {
        $remaining = @(Get-ChildItem -LiteralPath $parent -Force -ErrorAction Stop)
        if ($remaining.Count -eq 0) { Remove-Item -LiteralPath $parent -Force -ErrorAction Stop }
    }
}
