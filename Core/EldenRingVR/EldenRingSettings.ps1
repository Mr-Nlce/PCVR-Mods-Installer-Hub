# Shared, non-UI Elden Ring VR settings helpers. The Hub uses these for its
# clickable 3D actions; the installers use the same code for useful defaults.

function global:Set-EldenRingTextSetting {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$KeyPattern,
        [Parameter(Mandatory=$true)][string]$Value,
        [switch]$NoBackup
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{ Success=$false; Changed=$false; Reason="Settings file not found"; Backup=$null }
    }
    try {
        $text = [IO.File]::ReadAllText($Path)
        $rx = [regex]::new(('^(?<prefix>\s*' + $KeyPattern + '\s*=\s*)[^\r\n;#]*'), [Text.RegularExpressions.RegexOptions]::Multiline)
        $match = $rx.Match($text)
        if (-not $match.Success) {
            return [pscustomobject]@{ Success=$false; Changed=$false; Reason="Setting was not found"; Backup=$null }
        }
        $replacement = $match.Groups['prefix'].Value + $Value
        $updated = $text.Substring(0, $match.Index) + $replacement + $text.Substring($match.Index + $match.Length)
        if ($updated -ceq $text) {
            return [pscustomobject]@{ Success=$true; Changed=$false; Reason="Already set"; Backup=$null }
        }

        $backup = $null
        if (-not $NoBackup) {
            $backup = $Path + '.pcvrhub-before-3d-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,6)
        }
        $temp = $Path + '.pcvrhub-edit-' + [Guid]::NewGuid().ToString('N')
        try {
            [IO.File]::WriteAllText($temp, $updated, (New-Object Text.UTF8Encoding $false))
            if (-not $NoBackup) {
                [IO.File]::Replace($temp, $Path, $backup, $true)
            } else {
                Copy-Item -LiteralPath $temp -Destination $Path -Force -ErrorAction Stop
                Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
            }
        } finally {
            if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
        }
        return [pscustomobject]@{ Success=$true; Changed=$true; Reason="Updated"; Backup=$backup }
    } catch {
        return [pscustomobject]@{ Success=$false; Changed=$false; Reason=$_.Exception.Message; Backup=$null }
    }
}

function global:Set-EldenRingHotbite3D {
    param([Parameter(Mandatory=$true)][string]$Path, [switch]$NoBackup)
    return Set-EldenRingTextSetting -Path $Path -KeyPattern 'global\.vr_mono' -Value '0' -NoBackup:$NoBackup
}

function global:Set-EldenRingErvrFull3D {
    param([Parameter(Mandatory=$true)][string]$Path, [switch]$NoBackup)
    return Set-EldenRingTextSetting -Path $Path -KeyPattern 'StereoMode' -Value 'full' -NoBackup:$NoBackup
}
