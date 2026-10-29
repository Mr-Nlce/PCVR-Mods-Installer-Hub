param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\PublisherVRSetup.ps1')
Invoke-PublisherVRUninstall -Key 'BloodWest' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed