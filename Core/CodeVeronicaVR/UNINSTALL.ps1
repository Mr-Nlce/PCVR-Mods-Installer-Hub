param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\OctoberNativeVRSetup.ps1')
Invoke-OctoberNativeUninstall -Key 'CodeVeronica' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
