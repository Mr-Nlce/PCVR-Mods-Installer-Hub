param([switch]$HubConfirmed,[ValidateSet('Native','Legacy')][string]$Variant='Native')
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\MetroidPrimeNativeSetup.ps1')
Invoke-MetroidNativeUninstall -InstallerFolder $PSScriptRoot -HubConfirmed:$HubConfirmed -Variant $Variant
