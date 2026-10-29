$ErrorActionPreference='Stop'
$choice=[string]$env:PCVR_HUB_INSTALLER_CHOICE
if(-not $choice -and $env:PCVR_HUB_TEST_MODE -eq '1' -and -not $env:PCVR_ROUND8_TEST){$choice='icedomega13'}
if(-not $choice){
 Write-Host '============================================================' -ForegroundColor Cyan
 Write-Host '  The House of the Dead 2 - choose your VR mod' -ForegroundColor Cyan
 Write-Host '============================================================' -ForegroundColor Cyan
 Write-Host '  1. Icedomega13 HotD2VR - separate publisher-managed VR copy' -ForegroundColor Green
 Write-Host '  2. PC2VR by fjdiazt - independent vr folder in your original PC game' -ForegroundColor Cyan
 Write-Host '  Each option installs/updates only the selected mod. Both may coexist.' -ForegroundColor Yellow
 while($choice -notin @('icedomega13','pc2vr')){switch((Read-Host '  Choose 1 or 2 (Q cancels)').Trim()){'1'{$choice='icedomega13'}'2'{$choice='pc2vr'}'q'{exit 1}}}
}
if($choice -eq 'pc2vr'){& (Join-Path $PSScriptRoot '..\HotD2PC2VR\HotD2PC2VR-core.ps1')}
elseif($choice -eq 'icedomega13'){& (Join-Path $PSScriptRoot 'HotD2VR-core.ps1')}
else{throw 'Unknown HOTD2 VR mod selection.'}
