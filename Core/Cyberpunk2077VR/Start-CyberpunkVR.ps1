param([string]$GameDirectory,[string]$RuntimeRoot,[switch]$PlanOnly,[switch]$FunctionsOnly)
$ErrorActionPreference='Stop'
if(-not $GameDirectory){$GameDirectory=Split-Path $PSScriptRoot -Parent}
$game=[IO.Path]::GetFullPath($GameDirectory).TrimEnd('\')
function Switch-CyberpunkSaveProfile {
    param([string]$SaveRoot,[ValidateSet('Current','Depot')][string]$Target)
    if(Get-Process -Name Cyberpunk2077 -ErrorAction SilentlyContinue){throw 'Close Cyberpunk 2077 before changing game versions.'}
    $parent=Split-Path $SaveRoot -Parent
    $profiles=Join-Path $parent 'PCVRHub-Cyberpunk-SaveProfiles'
    $marker=Join-Path $profiles 'active.txt'
    $active=if(Test-Path -LiteralPath $marker){(Get-Content -LiteralPath $marker -Raw).Trim()}else{'Current'}
    if($active -notin @('Current','Depot')){throw 'The save profile is unknown. Your saves were left untouched.'}
    if($active -eq $Target){return}
    $park=Join-Path $profiles $active;$restore=Join-Path $profiles $Target
    if(Test-Path -LiteralPath $park){throw 'A parked save profile already exists. Refusing to overwrite saves.'}
    [void][IO.Directory]::CreateDirectory($profiles)
    $moved=$false;$restored=$false
    try{
        if(Test-Path -LiteralPath $SaveRoot){
            if((Get-Item -LiteralPath $SaveRoot).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'A linked save folder needs manual handling. No saves were changed.'}
            # Whole-directory atomic rename retains every save and .bak file.
            [IO.Directory]::Move($SaveRoot,$park);$moved=$true
        }else{[void][IO.Directory]::CreateDirectory($park);$moved=$true}
        if(Test-Path -LiteralPath $restore){[IO.Directory]::Move($restore,$SaveRoot);$restored=$true}
        else{[void][IO.Directory]::CreateDirectory($SaveRoot)}
        [IO.File]::WriteAllText($marker+'.new',$Target)
        Move-Item -LiteralPath ($marker+'.new') -Destination $marker -Force
    }catch{
        if(Test-Path -LiteralPath ($marker+'.new') -PathType Leaf){[IO.File]::Delete($marker+'.new')}
        if($restored -and (Test-Path -LiteralPath $SaveRoot)){[IO.Directory]::Move($SaveRoot,$restore)}
        elseif((Test-Path -LiteralPath $SaveRoot) -and @(Get-ChildItem -LiteralPath $SaveRoot -Force).Count -eq 0){[IO.Directory]::Delete($SaveRoot,$false)}
        if($moved -and (Test-Path -LiteralPath $park) -and -not(Test-Path -LiteralPath $SaveRoot)){[IO.Directory]::Move($park,$SaveRoot)}
        throw
    }
}
function Get-CyberpunkSaveRoot {
    if($env:PCVR_HUB_TEST_MODE -eq '1'){
        $testRoot=$env:PCVR_CP_TEST_SAVE_ROOT
        if(-not $testRoot -or -not [IO.Path]::GetFullPath($testRoot).StartsWith([IO.Path]::GetTempPath(),[StringComparison]::OrdinalIgnoreCase)){throw 'An isolated Saved Games fixture is required.'}
        return $testRoot
    }
    if(-not('PCVRCyberpunkKnownFolder' -as [type])){
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class PCVRCyberpunkKnownFolder {
 [DllImport("shell32.dll")] public static extern int SHGetKnownFolderPath(ref Guid id,uint flags,IntPtr token,out IntPtr path);
}
'@
    }
    $id=[guid]'4C5C32FF-BB9D-43b0-B5B4-2D72E54EAAA4';$ptr=[IntPtr]::Zero
    try{
        $hr=[PCVRCyberpunkKnownFolder]::SHGetKnownFolderPath([ref]$id,0x4000,[IntPtr]::Zero,[ref]$ptr)
        if($hr -ne 0){throw 'Windows could not locate Saved Games. No save profile was changed.'}
        $folder=[Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
        if(-not $folder){throw 'Windows returned an empty Saved Games folder.'}
        return [IO.Path]::Combine($folder,'CD Projekt Red','Cyberpunk 2077')
    }finally{if($ptr -ne [IntPtr]::Zero){[Runtime.InteropServices.Marshal]::FreeCoTaskMem($ptr)}}
}

function Save-CyberpunkInitialSaveBackup {
    param([string]$SaveRoot)
    if(Get-Process -Name Cyberpunk2077 -ErrorAction SilentlyContinue){throw 'Close Cyberpunk 2077 before protecting or switching its save profiles.'}
    $profiles=Join-Path (Split-Path $SaveRoot -Parent) 'PCVRHub-Cyberpunk-SaveProfiles'
    $receipt=Join-Path $profiles 'initial-save-backup.json'
    if(Test-Path -LiteralPath $receipt -PathType Leaf){return}
    $active=Join-Path $profiles 'active.txt'
    $source=if((Test-Path -LiteralPath $active) -and (Get-Content -LiteralPath $active -Raw).Trim() -eq 'Depot'){Join-Path $profiles 'Current'}else{$SaveRoot}
    if(-not(Test-Path -LiteralPath $source -PathType Container)){return}
    $entries=@(Get-ChildItem -LiteralPath $source -Recurse -Force -ErrorAction Stop)
    if(@($entries|Where-Object {$_.Attributes -band [IO.FileAttributes]::ReparsePoint}).Count -or ((Get-Item -LiteralPath $source).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Linked save folders require a manual backup before changing builds. No saves were changed.'}
    $files=@($entries|Where-Object {-not $_.PSIsContainer})
    if(-not $files.Count){return}
    $backup=Join-Path $profiles ('Backups\before-first-current-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($backup)
    $base=[IO.Path]::GetFullPath($source).TrimEnd('\')
    foreach($file in $files){
        $rel=$file.FullName.Substring($base.Length+1);$target=Join-Path $backup $rel
        [void][IO.Directory]::CreateDirectory((Split-Path $target -Parent))
        [IO.File]::Copy($file.FullName,$target,$false)
        if((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash){throw 'The save safety copy did not verify. Your live saves were left unchanged; retry before starting.'}
    }
    @{Folder=$backup;Files=$files.Count;Source=$source;SaveVersion='unverified; do not assume 2.31 compatibility'}|ConvertTo-Json|Set-Content -LiteralPath ($receipt+'.new') -Encoding UTF8 -ErrorAction Stop
    Move-Item -LiteralPath ($receipt+'.new') -Destination $receipt -ErrorAction Stop
}
function Get-CyberpunkExternalLaunchProof {
    param([string]$Root,[string]$Version)
    . (Join-Path $PSScriptRoot '..\Modules\CyberpunkRoutes.ps1')
    $profile=if($Version -eq '2.31'){Get-CyberpunkDepotProfile}elseif($Version -eq '2.5'){Get-CyberpunkCurrentProfile}else{throw 'This VR port supports game 2.31 or 2.5. Locate the matching modded game copy.'}
    if($Version -eq '2.5'){
        # Publisher 0.1.9 README minima, distinct from the Hub's latest packages.
        $minimum=@('1.31.0','1.38.0','0.5.32','1.12.0','1.28.0','1.21.0')
        for($i=0;$i -lt $minimum.Count;$i++){$profile.Components[$i].Version=$minimum[$i]}
    }
    foreach($component in @($profile.Components)+@($profile.InputLoader)){
        foreach($rel in $component.RequiredFiles){
            $path=[IO.Path]::Combine($Root,$rel)
            if(-not [IO.File]::Exists($path) -or (Get-Item -LiteralPath $path).Length -eq 0){throw ('Required VR file is missing: '+$rel+'. Locate the complete modded game copy.')}
        }
        $binary=Get-CyberpunkBinaryVersion ([IO.Path]::Combine($Root,$component.Marker))
        if($binary -and (($Version -eq '2.31' -and $binary -ne $component.Version) -or ($Version -eq '2.5' -and [version]$binary -lt [version]$component.Version))){throw ($component.Name+' does not match game '+$Version+'. Your files were left unchanged.')}
    }
    return [pscustomobject]@{GameVersion=$Version;Dependencies=@($profile.Components|ForEach-Object{[pscustomobject]@{Name=$_.Name;Version=$_.Version}});InputLoader=[pscustomobject]@{RequiredFiles=$profile.InputLoader.RequiredFiles}}
}
if($FunctionsOnly){return}
try{
    $compatibilityHelper=Join-Path $PSScriptRoot 'CyberpunkStartupCompatibility.ps1'
    if(-not(Test-Path -LiteralPath $compatibilityHelper -PathType Leaf)){$compatibilityHelper=Join-Path $PSScriptRoot '..\Modules\CyberpunkStartupCompatibility.ps1'}
    . $compatibilityHelper
    if(Get-Process -Name Cyberpunk2077 -ErrorAction SilentlyContinue){throw 'Cyberpunk 2077 is already running. Close it before starting another copy.'}
    $route=if(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_cyberpunk_depot_231')){'Depot'}else{'Current'}
    $required=if($route -eq 'Depot'){'2.31'}else{'2.5'}
    $exe=Join-Path $game 'bin\x64\Cyberpunk2077.exe'
    $plugin=Join-Path $game 'red4ext\plugins\CyberpunkVR_Stereo\CyberpunkVR_Stereo.dll'
    if(-not(Test-Path -LiteralPath $exe) -or -not(Test-Path -LiteralPath $plugin)){throw 'The game or VR mod is missing. Run the matching installer, or switch back to VR mode.'}
    $v=[Diagnostics.FileVersionInfo]::GetVersionInfo($exe).ProductVersion
    $external=(-not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_cyberpunk_25_profile.json')) -and
               -not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_cyberpunk_231_profile.json')) -and
               -not(Test-Path -LiteralPath (Join-Path $game '.pcvrhub_cyberpunkvrport_ownership.csv')) -and $route -ne 'Depot')
    if($external){$required=([regex]::Match([string]$v,'^\d+\.\d+')).Value;$route='External'}
    if(([regex]::Match([string]$v,'^\d+\.\d+')).Value -ne $required){throw ('This '+$route+' VR setup needs game '+$required+'. Run the matching installer to check the game version.')}
    $startupProblems=@(Get-CyberpunkCurrentStartupProblems -GameRoot $game -GameVersion $required)
    if($startupProblems.Count){throw ($startupProblems -join "`r`n`r`n")}
    $profileName=if($route -eq 'Depot'){'.pcvrhub_cyberpunk_231_profile.json'}else{'.pcvrhub_cyberpunk_25_profile.json'}
    $proof=if($external){Get-CyberpunkExternalLaunchProof -Root $game -Version $required}else{Get-Content -LiteralPath (Join-Path $game $profileName) -Raw -ErrorAction Stop|ConvertFrom-Json}
    if($proof.GameVersion -ne $required){throw 'The VR compatibility profile belongs to a different game build. Repair this route.'}
    $frameworkPaths=@('red4ext\RED4ext.dll','bin\x64\plugins\cyber_engine_tweaks.asi','engine\tools\scc.exe','red4ext\plugins\TweakXL\TweakXL.dll','red4ext\plugins\ArchiveXL\ArchiveXL.dll','red4ext\plugins\Codeware\Codeware.dll')
    foreach($file in $frameworkPaths){if(-not(Test-Path -LiteralPath (Join-Path $game $file) -PathType Leaf)){throw 'A required VR framework is missing. Run Repair for this route.'}}
    if(@($proof.Dependencies).Count -ne $frameworkPaths.Count){throw 'The VR framework profile is incomplete. Repair this route.'}
    if(-not $proof.InputLoader){throw 'Input Loader has no verified version for this route. Run the matching installer.'}
    foreach($rel in $proof.InputLoader.RequiredFiles){if(-not(Test-Path -LiteralPath (Join-Path $game $rel) -PathType Leaf)){throw 'An Input Loader runtime file is missing. Run Repair for this route.'}}
    if(-not $external){
    $inputManifest=Join-Path $game $proof.InputLoader.Manifest
    $inputRow=@(Import-Csv -LiteralPath $inputManifest|Where-Object RelativePath -eq 'red4ext\plugins\input_loader\input_loader.dll')
    if($inputRow.Count -ne 1 -or (Get-FileHash -LiteralPath (Join-Path $game $inputRow[0].RelativePath)).Hash -ne $inputRow[0].InstalledSha256){throw 'Input Loader was changed outside this route. Run Repair before starting.'}
    }
    for($i=0;$i -lt $frameworkPaths.Count;$i++){
        $info=[Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $game $frameworkPaths[$i]))
        $binary=([regex]::Match([string]$info.ProductVersion,'\d+\.\d+\.\d+')).Value
        $expected=[string]$proof.Dependencies[$i].Version
        if($binary -and (($route -eq 'Depot' -and $binary -ne $expected) -or ($route -eq 'Current' -and [version]$binary -lt [version]$expected))){throw 'The installed frameworks no longer match this VR route. Run Repair.'}
    }
    if($PlanOnly){[pscustomobject]@{Route=$route;FilePath=$exe;WorkingDirectory=(Split-Path $exe -Parent);GameVersion=$required};return}
    if($external){
        # Adopt the user's working native installation without creating Hub
        # profiles, ownership, or switching any of its existing save folders.
        Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe -Parent) -ErrorAction Stop|Out-Null
        return
    }
    $saveRoot=Get-CyberpunkSaveRoot
    Save-CyberpunkInitialSaveBackup -SaveRoot $saveRoot
    $profiles=Join-Path (Split-Path $saveRoot -Parent) 'PCVRHub-Cyberpunk-SaveProfiles'
    $marker=Join-Path $profiles 'active.txt'
    $active=if(Test-Path -LiteralPath $marker){(Get-Content -LiteralPath $marker -Raw).Trim()}else{'Current'}
    if($active -ne $route){
        Add-Type -AssemblyName PresentationFramework
        $answer=[Windows.MessageBox]::Show('The Hub will keep separate save folders for Current 2.5 and Depot 2.31. Your existing saves are preserved in full. Depot starts with an empty profile the first time. Do not load a 2.5 save in 2.31. Disable Steam/GOG cross-platform cloud saves for both copies before switching. Have you disabled cloud saves and want to switch now?','Cyberpunk save profiles','YesNo','Warning')
        if($answer -ne 'Yes'){return}
        Switch-CyberpunkSaveProfile -SaveRoot $saveRoot -Target $route
    }
    if($route -eq 'Depot'){
        $idFile=Join-Path $game 'bin\x64\steam_appid.txt'
        if(-not(Test-Path -LiteralPath $idFile) -or [IO.File]::ReadAllText($idFile).Trim() -ne '1091500'){throw 'The Depot Steam app-id file is missing. Run its installer again.'}
        $env:SteamAppId='1091500';$env:SteamGameId='1091500'
    }
    Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe -Parent) -ErrorAction Stop|Out-Null
}catch{
    if($env:PCVR_HUB_TEST_MODE -eq '1'){throw}
    Add-Type -AssemblyName PresentationFramework
    [void][Windows.MessageBox]::Show($_.Exception.Message,'Cyberpunk VR','OK','Warning')
    exit 1
}
