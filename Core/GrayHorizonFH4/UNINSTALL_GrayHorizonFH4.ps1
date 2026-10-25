param([switch]$HubConfirmed)
. (Join-Path $PSScriptRoot '..\Modules\GrayHorizonUninstall.ps1')
Invoke-GrayHorizonUninstall -Number 4 -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed

