param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\NewGameVRSetup.ps1')
Invoke-NewGameVRUninstall -Key 'Contracts' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
