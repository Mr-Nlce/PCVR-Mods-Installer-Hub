param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\KingEJUnityVRSetup.ps1')
Invoke-KingEJVRUninstall -Key 'Agent64' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
