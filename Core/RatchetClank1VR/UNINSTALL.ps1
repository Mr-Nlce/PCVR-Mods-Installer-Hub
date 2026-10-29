param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\NewGameVRSetup.ps1')
Invoke-NewGameVRUninstall -Key 'Ratchet1' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
