param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\PublisherVRSetup.ps1')
Invoke-PublisherVRUninstall -Key 'DeadSpace2' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed