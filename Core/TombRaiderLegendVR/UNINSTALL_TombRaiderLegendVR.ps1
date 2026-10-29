param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\Round8VRSetup.ps1')
Invoke-Round8VRUninstall -Key 'TombLegend' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
