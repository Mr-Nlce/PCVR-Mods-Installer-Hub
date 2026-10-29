param([string]$GameDirectory)
$ErrorActionPreference='Stop'
if(-not $GameDirectory){$GameDirectory=Split-Path $PSScriptRoot -Parent}
try{
 if(Get-Process -Name Cyberpunk2077 -ErrorAction SilentlyContinue){throw 'Close Cyberpunk 2077, then retry Uninstall.'}
 $helpers=Join-Path $PSScriptRoot 'OwnedModFiles.ps1'
 if(-not(Test-Path -LiteralPath $helpers)){$helpers=Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1'}
 . $helpers
 Write-Host '  Remove the VR mod from this game copy? Your saves, settings and other game copy are kept.' -ForegroundColor Yellow
 Write-Host '  If Depot saves are active, the launcher restores your separate Current save profile first.' -ForegroundColor White
 if((''+(Read-Host '  Type REMOVE to continue')).Trim() -cne 'REMOVE'){return}
 . (Join-Path $PSScriptRoot 'Start-CyberpunkVR.ps1') -GameDirectory $GameDirectory -FunctionsOnly
 $saveRoot=Get-CyberpunkSaveRoot
 Switch-CyberpunkSaveProfile -SaveRoot $saveRoot -Target Current
 $plugin='red4ext\plugins\CyberpunkVR_Stereo\CyberpunkVR_Stereo.dll'
 $alternates=@{};$alternates[$plugin]=$plugin+'.pcvrhub_off';$alternates[$plugin+'.pcvrhub_off']=$plugin
 [void](Uninstall-OwnedModPayload -GameRoot $GameDirectory -Identity 'cyberpunkvrport' -ParkedAlternates $alternates)
 foreach($rel in @('.pcvrhub_cyberpunk_25_profile.json','.pcvrhub_cyberpunk_231_profile.json','.pcvrhub_version')){
  $p=Join-Path $GameDirectory $rel;if(Test-Path -LiteralPath $p -PathType Leaf){[IO.File]::Delete($p)}
 }
 $desktop=[Environment]::GetFolderPath('DesktopDirectory')
 if($env:PCVR_HUB_TEST_MODE -eq '1'){$desktop=$env:PCVR_CYBERPUNK_TEST_DESKTOP}
 if($desktop){
  $shell=New-Object -ComObject WScript.Shell
  foreach($name in @('Cyberpunk 2077 VR','Cyberpunk 2077 VR 2.31')){
   $link=Join-Path $desktop ($name+'.lnk')
   if(-not(Test-Path -LiteralPath $link -PathType Leaf)){continue}
   $shortcut=$shell.CreateShortcut($link)
   if($shortcut.Arguments -eq ('"'+(Join-Path $GameDirectory 'PCVR-Cyberpunk\Start VR.vbs')+'"') -and [IO.Path]::GetFileName($shortcut.TargetPath) -ieq 'wscript.exe'){[IO.File]::Delete($link)}
  }
 }
 # Frameworks are shared with other mods and remain installed. The launcher
 # and save manager remain usable for restoring the other save profile.
 Write-Host '  [OK] VR files removed or originals restored. User-modified files were kept.' -ForegroundColor Green
 Write-Host '  Shared frameworks, game files and separate save profiles were kept.' -ForegroundColor White
 [void](Read-Host 'Press Enter to close')
}catch{
 Write-Host $_.Exception.Message -ForegroundColor Yellow
 [void](Read-Host 'Uninstall did not complete. Press Enter to close, then retry')
 exit 1
}
