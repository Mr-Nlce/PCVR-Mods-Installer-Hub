param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\PublisherVRSetup.ps1')
Invoke-PublisherVRUninstall -Key 'Balatro' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed