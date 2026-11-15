param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OctoberNativeVRSetup.ps1')
Invoke-OctoberNativeUninstall -Key 'GearsEDay' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
