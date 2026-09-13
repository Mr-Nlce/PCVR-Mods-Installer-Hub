param([ValidateSet('pcvr','legacy')][string]$Mod='pcvr',[switch]$HubConfirmed)
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
$ErrorActionPreference = 'Stop'
$identity = if ($Mod -eq 'pcvr') { 'quake2pcvr' } else { 'q2vrlegacy' }
$pathName = if ($Mod -eq 'pcvr') { '.installed_path_pcvr' } else { '.installed_path' }
$pathFile = Join-Path $PSScriptRoot $pathName
$root = $null
if (Test-Path -LiteralPath $pathFile) { try { $root = ([IO.File]::ReadAllText($pathFile)).Trim() } catch {} }
if (-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) {
    foreach ($candidate in $(if ($Mod -eq 'pcvr') { @('C:\Games\Quake II PCVR','D:\Games\Quake II PCVR','E:\Games\Quake II PCVR') } else { @('C:\Games\Quake 2 VR','D:\Games\Quake 2 VR','E:\Games\Quake 2 VR') })) {
        if (Test-Path -LiteralPath $candidate -PathType Container) { $root = $candidate; break }
    }
}
if (-not $root) { throw 'The selected standalone Quake II VR folder was not found.' }
if (-not $HubConfirmed -and (Read-Host "Type REMOVE to uninstall $Mod") -ne 'REMOVE') { exit 0 }
$result = Uninstall-OwnedModPayload -GameRoot $root -Identity $identity
if (-not $result.Found) { throw 'No Hub ownership record was found. No unverified legacy file was removed; reinstall this option once to adopt matching official files safely.' }
if ($Mod -eq 'pcvr') {
    foreach ($name in @('Play Quake II VR.bat','Play The Reckoning VR.bat','Play Ground Zero VR.bat','.pcvrhub_ready','.pcvrhub_version','.pcvrhub.install.json')) { Remove-Item -LiteralPath (Join-Path $root $name) -Force -ErrorAction SilentlyContinue }
    foreach ($name in @('Quake 2 OpenXR VR.lnk','Quake 2 The Reckoning VR.lnk','Quake 2 Ground Zero VR.lnk')) { Remove-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('Desktop')) $name) -Force -ErrorAction SilentlyContinue }
} else {
    Remove-Item -LiteralPath (Join-Path $root '.revive_launch') -Force -ErrorAction SilentlyContinue
    foreach ($name in @('Quake 2 VR.lnk','Quake II VR - The Reckoning.lnk','Quake II VR - Ground Zero.lnk')) { Remove-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('Desktop')) $name) -Force -ErrorAction SilentlyContinue }
}
Remove-Item -LiteralPath $pathFile -Force -ErrorAction SilentlyContinue
Write-Host "Removed $($result.Removed), restored $($result.Restored), preserved $($result.Preserved) changed file(s)." -ForegroundColor Green
Write-Host 'Copied PAKs, music, saves, screenshots and user configuration remain in the standalone folder.' -ForegroundColor Gray
Read-Host 'Press Enter to exit' | Out-Null
