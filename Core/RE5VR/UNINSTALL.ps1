param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OctoberNativeVRSetup.ps1')
Invoke-OctoberNativeUninstall -Key 'RE5' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
