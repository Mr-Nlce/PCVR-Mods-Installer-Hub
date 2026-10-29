param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\Round8VRSetup.ps1')
Invoke-Round8VRUninstall -Key 'HotD2PC2VR' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
