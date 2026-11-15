$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'TTWVR-State.ps1')
$mode = Split-Path -Leaf $PSScriptRoot
$state = Get-TTWInstalledState $PSScriptRoot $mode
if (-not $state) { throw 'The TTWVR profile, game or runtime files are incomplete. Reopen setup to repair the route.' }
if (Get-Process -Name 'FalloutNV','ModOrganizer' -ErrorAction SilentlyContinue) { throw 'Close Fallout and Mod Organizer 2 before starting this profile.' }
$arguments = '-p "{0}" "{1}"' -f $state.profileName,(Join-Path $state.game 'FalloutNV.exe')
Start-Process -FilePath $state.mo2 -ArgumentList $arguments -WorkingDirectory (Split-Path -Parent $state.mo2)
