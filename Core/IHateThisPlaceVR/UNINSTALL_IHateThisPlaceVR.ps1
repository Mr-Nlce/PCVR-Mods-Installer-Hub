param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\KingEJUnityVRSetup.ps1')
Invoke-KingEJVRUninstall -Key 'IHateThisPlace' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
