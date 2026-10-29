function global:Get-PCVRUninstallInstallRoots {
    # Install folders Windows itself knows about: every "Programs and
    # Features" entry under ...\CurrentVersion\Uninstall (64-bit view,
    # 32-bit view, per-user). Read-only, through the .NET API like
    # Get-HubRegistryValueQuiet - a missing key is normal, never an error.
    #
    # Two values can name the folder:
    #   InstallLocation - the folder itself (often blank on old setups)
    #   DisplayIcon     - usually "<folder>\game.exe" or "...exe,0"; its
    #                     parent folder is used when it points at an .exe
    # UninstallString is deliberately NOT used: InstallShield points it at
    # its own cache folder, never at the game.
    #
    # Returns unique folder strings only. Nothing here is trusted as a game
    # location - the scan still requires the catalog's base-game proof files
    # inside a folder before it counts.
    # Shared read-only source for Hub and installer processes.
    if ($global:HubFileSystemLabRoot -or [string]$env:PCVR_HUB_TEST_MODE -eq '1' -or [string]$env:PCVR_HUB_REGISTRY_SCAN -eq '0') { return @() }
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { return @() }
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $out = New-Object System.Collections.Generic.List[string]
    $sub = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    foreach ($probe in @(
        @{ Hive = [Microsoft.Win32.RegistryHive]::LocalMachine; View = [Microsoft.Win32.RegistryView]::Registry64 },
        @{ Hive = [Microsoft.Win32.RegistryHive]::LocalMachine; View = [Microsoft.Win32.RegistryView]::Registry32 },
        @{ Hive = [Microsoft.Win32.RegistryHive]::CurrentUser;  View = [Microsoft.Win32.RegistryView]::Default }
    )) {
        $base = $null; $root = $null
        try {
            $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey($probe.Hive, $probe.View)
            $root = $base.OpenSubKey($sub, $false)
            if (-not $root) { continue }
            foreach ($name in $root.GetSubKeyNames()) {
                $entry = $null
                try {
                    $entry = $root.OpenSubKey($name, $false)
                    if (-not $entry) { continue }
                    $folders = @()
                    $loc = [string]$entry.GetValue('InstallLocation', $null)
                    if (-not [string]::IsNullOrWhiteSpace($loc)) { $folders += $loc }
                    $icon = [string]$entry.GetValue('DisplayIcon', $null)
                    if (-not [string]::IsNullOrWhiteSpace($icon)) {
                        $icon = ($icon -replace ',\s*-?\d+\s*$', '').Trim().Trim('"')
                        if ($icon -match '(?i)\.exe$') {
                            try { $folders += [IO.Path]::GetDirectoryName($icon) } catch {}
                        }
                    }
                    foreach ($f in $folders) {
                        $f = ([string]$f).Trim().Trim('"').TrimEnd([char[]]'\/')
                        if ($f -match '^[A-Za-z]:$') { continue }   # bare drive root is never a game folder
                        if ($f -notmatch '^[A-Za-z]:\\') { continue }
                        try { $drive=[IO.DriveInfo]::new([IO.Path]::GetPathRoot($f)); if (-not $drive.IsReady -or $drive.DriveType -eq [IO.DriveType]::Network) { continue } } catch { continue }
                        if ($seen.Add($f)) { $out.Add($f) }
                    }
                } catch {
                } finally { if ($entry) { $entry.Dispose() } }
            }
        } catch {
        } finally {
            if ($root) { $root.Dispose() }
            if ($base) { $base.Dispose() }
        }
    }
    return @($out)
}

