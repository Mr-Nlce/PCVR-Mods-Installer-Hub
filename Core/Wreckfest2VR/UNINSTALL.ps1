param([switch]$HubConfirmed)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\NewGameVRSetup.ps1')
Invoke-NewGameVRUninstall -Key 'Wreckfest2' -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed
