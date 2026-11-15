$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\Mafia2VrSetup.ps1')
Invoke-Mafia2VrSetup -InstallerFolder $PSScriptRoot
