param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot='')
$ErrorActionPreference='Stop'
if(-not(Test-Path -LiteralPath (Join-Path $GameDirectory 'DII_Beta.exe') -PathType Leaf)){throw 'Dementium II HD was not found in the saved game folder.'}
$uri='steam://run/217100//-force-opengl/'
if($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_ROUND8_LAUNCH_CAPTURE){
 $capture=[IO.Path]::GetFullPath($env:PCVR_ROUND8_LAUNCH_CAPTURE)
 if(-not $env:PCVR_ROUND8_TEST){throw 'Launch capture requires an isolated fixture configuration.'}
 $testConfig=Get-Content -LiteralPath $env:PCVR_ROUND8_TEST -Raw|ConvertFrom-Json
 $captureRoot=[IO.Path]::GetFullPath([string]$testConfig.Root).TrimEnd('\')+'\'
 if(-not $captureRoot.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath (Join-Path $captureRoot '.pcvrhub_round8_fixture')) -or -not $capture.StartsWith($captureRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'Launch capture escaped its isolated fixture.'}
[pscustomobject]@{File=$uri;WorkingDirectory=$GameDirectory}|ConvertTo-Json|Set-Content -LiteralPath $env:PCVR_ROUND8_LAUNCH_CAPTURE;exit 0}
Start-Process $uri -ErrorAction Stop
