param([Parameter(Mandatory=$true)][string]$RuntimeRoot,[string]$GameDirectory)
$ErrorActionPreference='Stop'
try { & (Join-Path $PSScriptRoot '..\Modules\OctoberNativeVRLaunch.ps1') -RuntimeRoot $RuntimeRoot -Key 'GearsEDay' } catch {if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};Add-Type -AssemblyName System.Windows.Forms;[void][Windows.Forms.MessageBox]::Show($_.Exception.Message,'Gears of War: E-Day VR') }
