param([switch]$HubConfirmed)
. (Join-Path $PSScriptRoot '..\Modules\CodiesVRUninstall.ps1')
Invoke-CodiesVRUninstall -Key 'GridLegends' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed