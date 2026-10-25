param([switch]$HubConfirmed)
. (Join-Path $PSScriptRoot '..\Modules\GrayHorizonUninstall.ps1')
Invoke-GrayHorizonUninstall -Number 5 -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed

