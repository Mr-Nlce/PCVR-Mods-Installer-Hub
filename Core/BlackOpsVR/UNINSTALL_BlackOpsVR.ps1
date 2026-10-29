param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\BlackOpsVRSetup.ps1')
Invoke-BO1VRUninstall -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
