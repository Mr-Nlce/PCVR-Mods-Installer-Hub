param([Alias('GameRoot')][string]$GameDir, [switch]$HubConfirmed, [switch]$NoPause)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
if (Get-Process -Name 'FalloutNV','ModOrganizer' -ErrorAction SilentlyContinue) { throw 'Close Fallout and Mod Organizer 2 before removing TTWVR.' }
$root = [IO.Path]::GetFullPath($GameDir)
$mode = Split-Path -Leaf $root
$expected = Join-Path $env:LOCALAPPDATA "PCVR Mods Installer Hub\TTWVR\$mode"
if ($mode -notin @('NewVegas','Wastelands') -or $root.TrimEnd('\') -ine $expected.TrimEnd('\')) { throw 'Choose the Hub-managed TTWVR installation folder.' }
$statePath = Join-Path $root 'ttwvr-install.json'
if (-not [IO.File]::Exists($statePath)) { throw 'The TTWVR installation record is missing.' }
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if ($state.schema -ne 1 -or $state.mode -cne $mode) { throw 'The selected route does not match its install record.' }
$name = 'PCVR Hub TTWVR ' + $mode
$owned = Join-Path $state.mods $name
$profile = Join-Path $state.profile 'modlist.txt'
if (-not $HubConfirmed) {
    Write-Host '  Removes the unchanged Hub-owned TTWVR files and deactivates their entry in the selected profile.'
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to remove TTWVR.')
}
[void](Uninstall-OwnedModPayload -GameRoot $owned -Identity 'ttwvr')
if ([IO.File]::Exists($profile)) {
    $nl = [Environment]::NewLine
    $lines = @([IO.File]::ReadAllLines($profile) | Where-Object { $_ -ine ('+' + $name) -and $_ -ine ('-' + $name) })
    Write-PCVRAtomicText -Path $profile -Value (($lines -join $nl) + $nl)
}
$stamp = if ($mode -eq 'NewVegas') { '.pcvrhub_version_b' } else { '.pcvrhub_version' }
$receipt = if ($mode -eq 'NewVegas') { Join-Path $PSScriptRoot '..\FNVVR\.installed_path_ttwvr' } else { Join-Path $PSScriptRoot '.installed_path' }
foreach ($file in @($statePath,(Join-Path $root $stamp))) {
    if ([IO.File]::Exists($file)) { Remove-Item -LiteralPath $file -Force }
}
if ([IO.File]::Exists($receipt) -and [IO.File]::ReadAllText($receipt).Trim() -ieq $root) { Remove-Item -LiteralPath $receipt -Force }
Write-Host '  [OK] TTWVR removed from the selected MO2 profile.' -ForegroundColor Green
