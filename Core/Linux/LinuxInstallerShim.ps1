# Linux only: loaded by Run-Installer.ps1 into the installer runspace when
# PowerShell runs on Linux. Windows never loads this file.
#
# Installers create desktop shortcuts with New-Object -ComObject WScript.Shell.
# COM does not exist on Linux, so this returns a small stand-in with the same
# CreateShortcut()/Save() surface. Save() writes a freedesktop .desktop file
# next to the requested .lnk path (usually the desktop) and into the
# application menu. It starts the target through the Hub's Proton launcher
# (pcvr-hub --proton-run), exactly like "Start in VR".

function global:ConvertTo-PcvrDesktopExecArg {
    param([string]$Value)
    # freedesktop Exec quoting: "..."; a literal backslash is \\\\ (string
    # escape, then quoting escape), " ` $ get one backslash, % becomes %%.
    '"' + (($Value.Replace('\', '\\\\') -replace '(["`$])', '\$1').Replace('%', '%%')) + '"'
}

function global:New-PcvrLinuxShortcut {
    param([string]$LinkPath)
    $shortcut = [pscustomobject]@{
        FullName = $LinkPath; TargetPath = ''; Arguments = ''; WorkingDirectory = ''
        IconLocation = ''; Description = ''; WindowStyle = 1; Hotkey = ''
    }
    $shortcut | Add-Member -MemberType ScriptMethod -Name Save -Value {
        $name = [IO.Path]::GetFileNameWithoutExtension($this.FullName)
        $target = ([string]$this.TargetPath).Replace('\', '/')
        $cwd = ([string]$this.WorkingDirectory).Replace('\', '/')
        if (-not $cwd -and $target) { $cwd = [IO.Path]::GetDirectoryName($target) }
        if ($target -match '(?i)\.(exe|bat|cmd)$') {
            if (-not $env:PCVR_HUB_EXE) { throw 'Desktop shortcut: the Hub did not provide its Proton launcher (PCVR_HUB_EXE).' }
            $exec = (ConvertTo-PcvrDesktopExecArg $env:PCVR_HUB_EXE) + ' --proton-run ' + (ConvertTo-PcvrDesktopExecArg $target) + ' ' + (ConvertTo-PcvrDesktopExecArg $cwd) + ' ' + (ConvertTo-PcvrDesktopExecArg ([string]$this.Arguments))
        } else {
            $exec = 'xdg-open ' + (ConvertTo-PcvrDesktopExecArg $target)
        }
        $icon = ([string]$this.IconLocation -replace ',\s*-?\d+$', '').Replace('\', '/')
        $lines = @('[Desktop Entry]', 'Type=Application', ('Name=' + $name), ('Exec=' + $exec), 'Terminal=false', 'Categories=Game;')
        if ($cwd) { $lines += ('Path=' + $cwd) }
        if ($this.Description) { $lines += ('Comment=' + ([string]$this.Description -replace '[\r\n]+', ' ')) }
        if ($icon -and [IO.File]::Exists($icon) -and $icon -match '(?i)\.(png|svg|xpm)$') { $lines += ('Icon=' + $icon) }
        $text = ($lines -join "`n") + "`n"
        $folder = [IO.Path]::GetDirectoryName(([string]$this.FullName).Replace('\', '/'))
        $file = $name -replace '[^\w .-]', '_'
        $apps = Join-Path ($(if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { Join-Path $HOME '.local/share' })) 'applications'
        foreach ($dir in @($folder, $apps)) {
            if (-not $dir) { continue }
            [void][IO.Directory]::CreateDirectory($dir)
            $path = Join-Path $dir ('pcvr-' + $file + '.desktop')
            [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
            try { [IO.File]::SetUnixFileMode($path, [IO.UnixFileMode]'UserRead,UserWrite,UserExecute,GroupRead,GroupExecute,OtherRead,OtherExecute') } catch { }
        }
    }
    $shortcut
}

function global:New-Object {
    [CmdletBinding(DefaultParameterSetName = 'Net')]
    param(
        [Parameter(ParameterSetName = 'Net', Mandatory = $true, Position = 0)][string]$TypeName,
        [Parameter(ParameterSetName = 'Net', Position = 1)][Alias('Args')][object[]]$ArgumentList,
        [Parameter(ParameterSetName = 'Com', Mandatory = $true)][string]$ComObject,
        [Parameter(ParameterSetName = 'Com')][switch]$Strict,
        [System.Collections.IDictionary]$Property
    )
    if ($PSCmdlet.ParameterSetName -eq 'Com' -and $ComObject -ieq 'WScript.Shell') {
        $shell = [pscustomobject]@{ Kind = 'PcvrLinuxShell' }
        $shell | Add-Member -MemberType ScriptMethod -Name CreateShortcut -Value { param($p) New-PcvrLinuxShortcut -LinkPath ([string]$p) }
        return $shell
    }
    Microsoft.PowerShell.Utility\New-Object @PSBoundParameters
}

# Programs the installer starts (setup EXEs, cmd.exe /c x.bat, explorer, ...):
# the Hub's process shim routes them through Proton or xdg-open. The Hub
# writes it and passes its path in PCVR_LINUX_SHIM.
if ($env:PCVR_LINUX_SHIM -and (Test-Path -LiteralPath $env:PCVR_LINUX_SHIM)) { . $env:PCVR_LINUX_SHIM }
