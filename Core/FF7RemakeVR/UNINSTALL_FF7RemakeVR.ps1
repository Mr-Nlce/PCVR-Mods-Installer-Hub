param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\Round8VRSetup.ps1')
Invoke-Round8VRUninstall -Key 'FF7' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
