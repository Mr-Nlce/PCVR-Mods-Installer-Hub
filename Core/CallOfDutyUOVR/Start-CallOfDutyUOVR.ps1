param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot)
& (Join-Path $PSScriptRoot '..\CallOfDuty2003VR\Start-CallOfDuty2003VR.ps1') -GameDirectory $GameDirectory -RuntimeRoot $RuntimeRoot -Game UO
