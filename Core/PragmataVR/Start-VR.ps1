param([Parameter(Mandatory=$true)][string]$GameDirectory,[ValidateSet('modern','legacy')][string]$Mod='modern')
$ErrorActionPreference='Stop'
try{. (Join-Path $PSScriptRoot 'Pragmata-Profiles.ps1');Invoke-PragmataPlay -Game $GameDirectory -Mod $Mod}
catch{if($env:PCVR_HUB_TEST_MODE -eq '1'){throw};Add-Type -AssemblyName System.Windows.Forms;[void][Windows.Forms.MessageBox]::Show($_.Exception.Message,'Pragmata VR')}
