param([switch]$HubConfirmed)
. (Join-Path $PSScriptRoot '..\Modules\CodiesVRUninstall.ps1')
Invoke-CodiesVRUninstall -Key 'Dirt4' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed