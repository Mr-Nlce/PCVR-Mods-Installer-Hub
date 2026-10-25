param([switch]$HubConfirmed)
. (Join-Path $PSScriptRoot '..\Modules\CodiesVRUninstall.ps1')
Invoke-CodiesVRUninstall -Key 'Grid2019' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed