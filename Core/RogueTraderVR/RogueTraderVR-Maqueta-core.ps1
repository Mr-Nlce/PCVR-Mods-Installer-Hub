$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'RogueTraderVR-Mode.ps1')
$repo='Beren5556/W40KRT_VR'
$releasePage='https://github.com/Beren5556/W40KRT_VR/releases'
$fallbackTag='v0.9.81-beta'
$fallbackAsset='W40KRT_VR-0.9.81-beta.zip'
$fallbackUrl="https://github.com/$repo/releases/download/$fallbackTag/$fallbackAsset"
$contract=New-PCVRInstallerContract -Id 'rogue-trader-maqueta-vr' -GameName 'Rogue Trader W40KRT_VR' -Acquisition GitHub `
    -ReleasePageUrl $releasePage -AntivirusNotice -RequiredInstalledFileGroups @('WH40KRT.exe')

function Test-RogueMaquetaSteamRoot([string]$Path) {
    if(-not $Path -or -not(Test-Path -LiteralPath (Join-Path $Path 'WH40KRT.exe') -PathType Leaf)){return $false}
    $common=Split-Path -Parent $Path
    if((Split-Path -Leaf $common) -ine 'common'){return $false}
    $steamapps=Split-Path -Parent $common
    if((Split-Path -Leaf $steamapps) -ine 'steamapps'){return $false}
    $manifest=Join-Path $steamapps 'appmanifest_2186680.acf'
    if(-not(Test-Path -LiteralPath $manifest -PathType Leaf)){return $false}
    $text=Get-Content -LiteralPath $manifest -Raw
    $install=[regex]::Match($text,'"installdir"\s+"([^"]+)"')
    return ($text -match '"appid"\s+"2186680"' -and $install.Success -and $install.Groups[1].Value -ieq (Split-Path -Leaf $Path))
}

function Get-RogueMaquetaGame {
    $record=Join-Path $PSScriptRoot '.installed_path_maqueta'
    if(Test-Path -LiteralPath $record){
        $known=(''+(Get-Content -LiteralPath $record -Raw)).Trim().Trim('"')
        if(Test-RogueMaquetaSteamRoot $known){return $known}
    }
    $found=Find-SteamGameFolder -AppId '2186680' -SteamFolderNames @('Warhammer 40,000 Rogue Trader') -ProbeExe 'WH40KRT.exe' -HubGameId 'warhammer-40k-rogue-trader-vr'
    if(Test-RogueMaquetaSteamRoot $found){return $found}
    $chosen=Get-GameFolderInteractive -GameName 'Warhammer 40K: Rogue Trader (Steam)' -ProbeFile 'WH40KRT.exe' -ManualUrl 'https://store.steampowered.com/app/2186680/'
    if(-not(Test-RogueMaquetaSteamRoot $chosen)){throw 'Select the Steam game folder containing WH40KRT.exe and a matching appmanifest_2186680.acf.'}
    [void](Save-HubRememberedGameFolder -GameId 'warhammer-40k-rogue-trader-vr' -Title 'Warhammer 40K: Rogue Trader VR' -GameDir $chosen -ProbeFiles @('WH40KRT.exe') -UserSelected)
    return $chosen
}

function Get-RogueMaquetaPackage([string]$Archive,[string]$Work) {
    $expanded=Join-Path $Work 'expanded'
    $result=Expand-ArchiveOrFallback -ArchivePath $Archive -DestinationFolder $expanded -Label 'W40KRT_VR publisher ZIP' -AllowSkip $false -QuietProgress
    if([string]$result -notin @('ok','manual','retry')){throw 'The publisher archive could not be opened.'}
    $packages=@(Get-ChildItem -LiteralPath $expanded -Filter 'package.json' -Recurse -File)
    foreach($candidate in $packages){
        $manifest=Get-Content -LiteralPath $candidate.FullName -Raw | ConvertFrom-Json
        if($manifest.Id -eq 'RTMaquetaXR' -and $manifest.Version -match '^\d+\.\d+\.\d+$'){
            $root=Split-Path -Parent $candidate.FullName
            foreach($required in @('scripts\Install.ps1','scripts\Uninstall.ps1','scripts\Portable.Common.ps1','RTMaquetaXR\Info.json','RTMaquetaXR\RTMaquetaXR.dll','RTMaquetaXR\W40KRT-VR-Launcher.exe','prerequisites\vc_redist.x64.exe')){
                if(-not(Test-Path -LiteralPath (Join-Path $root $required) -PathType Leaf)){throw "Publisher package is incomplete: $required"}
            }
            return [pscustomobject]@{Root=$root;Version=[string]$manifest.Version}
        }
    }
    throw 'No complete RTMaquetaXR publisher package was found in the ZIP.'
}

function Invoke-RoguePublisherInstall([string]$PackageRoot,[string]$Game,[string]$Work) {
    $exe=(Get-Command powershell.exe -ErrorAction Stop).Source
    $args='-NoLogo -NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $PackageRoot 'scripts\Install.ps1') + '" -GamePath "' + $Game + '"'
    # Keep the publisher's interactive backup/reset question visible. Evaluate
    # the actual child exit code: benign stderr from a native tool is not failure.
    $process=Start-Process -FilePath $exe -ArgumentList $args -Wait -PassThru -NoNewWindow
    if($null -eq $process.ExitCode -or $process.ExitCode -ne 0){throw "Publisher installer failed (exit code $($process.ExitCode)). Read its message above."}
}

function Invoke-RogueMaquetaInstaller {
    $work=$null;$profile=$null;$params=$null;$originalBytes=$null;$originalExists=$false
    $modFolder=$null;$profileBackup=$null;$modFolderExisted=$false;$backupReady=$false;$committed=$false;$keepWork=$false
    try {
        Clear-Host
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ' Warhammer 40K: Rogue Trader VR Installer' -ForegroundColor Cyan
        Write-Host ' W40KRT_VR by Beren5556 - motion controls and tabletop VR' -ForegroundColor Gray
        Write-Host ('=' * 60) -ForegroundColor Magenta
        Write-Host ''
        Write-Host ' Requires the publisher-validated Steam build, DirectX 11, Windows x64,' -ForegroundColor White
        Write-Host ' a supported OpenXR provider and connected motion controllers.' -ForegroundColor White
        Write-Host ' RTVR may stay installed. This setup disables it in Owlcat mod settings;' -ForegroundColor Yellow
        Write-Host ' either Hub Play choice activates its own mod before launch.' -ForegroundColor Yellow
        Write-Host ' The publisher installer may ask to back up and reset older Maqueta settings.' -ForegroundColor Yellow
        Show-AntivirusNotice -Compact
        if($env:PCVR_ROGUE_CHOICE_CONFIRMED -ne '1'){
            [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to begin...')
        }
        Write-Host ' [1/4] Find the Steam game and Owlcat profile' -ForegroundColor Cyan
        Write-Host ' ----------------------------------------' -ForegroundColor DarkGray
        $game=Get-RogueMaquetaGame
        if(Get-Process -Name WH40KRT -ErrorAction SilentlyContinue){throw 'Close Rogue Trader before installing.'}
        if(-not(Test-InstallerTargetWritable -TargetPath $game)){throw 'The game folder is not writable for its version receipt.'}
        $profile=Get-RogueTraderProfileRoot
        if(-not(Test-Path -LiteralPath $profile -PathType Container)){throw 'Start Rogue Trader once and close it to create the Owlcat mod profile.'}
        Write-Host ' [2/4] Download and inspect the tabletop release' -ForegroundColor Cyan
        Write-Host ' ----------------------------------------' -ForegroundColor DarkGray
        Write-Host ' The next step checks the official GitHub beta and downloads its ZIP.' -ForegroundColor White
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download W40KRT_VR...')
        $release=Resolve-GitHubReleaseAsset -Repo $repo -AssetPatterns @('(?i)^W40KRT[_-]VR(?:[-_.].*)?\.zip$') -IncludePrerelease $true `
            -SkipReleasesWithoutMatchingAsset -FallbackUrl $fallbackUrl -FallbackTag $fallbackTag -FallbackAssetName $fallbackAsset
        if(-not(Test-IsTrackableInstalledVersion ([string]$release.Tag))){throw 'No trackable GitHub release was found.'}
        $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_rogue_'+[Guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($work)
        $archive=Join-Path $work 'W40KRT_VR.zip'
        $download=Invoke-SafeDownload -Urls @([string]$release.Url) -Destination $archive -Label "W40KRT_VR $($release.Tag)" -ExpectedReleaseTag ([string]$release.Tag) -ManualUrl ([string]$release.PageUrl) -AllowSkip $false
        if($download -ne $true -and [string]$download -notin @('retry','manual')){throw 'W40KRT_VR download was not completed.'}
        $package=Get-RogueMaquetaPackage -Archive $archive -Work $work
        $params=Join-Path $profile 'Params.xml';$originalExists=Test-Path -LiteralPath $params -PathType Leaf
        if($originalExists){$originalBytes=[IO.File]::ReadAllBytes($params)}
        $modFolder=Join-Path $profile 'RTMaquetaXR'
        $modFolderExisted=Test-Path -LiteralPath $modFolder -PathType Container
        if($modFolderExisted){
            if(((Get-Item -LiteralPath $modFolder -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'RTMaquetaXR profile is a link; choose a regular profile folder before updating.'}
            $profileBackup=Join-Path $work 'profile-before'
            Copy-Item -LiteralPath $modFolder -Destination $profileBackup -Recurse -Force -ErrorAction Stop
        }
        $backupReady=$true
        Write-Host ' [3/4] Install the tabletop mod beside RTVR' -ForegroundColor Cyan
        Write-Host ' ----------------------------------------' -ForegroundColor DarkGray
        Set-RogueTraderModMode -Mode Maqueta -ProfileRoot $profile -AllowMissingSelected
        Invoke-RoguePublisherInstall -PackageRoot $package.Root -Game $game -Work $work
        foreach($required in @('RTMaquetaXR\Info.json','RTMaquetaXR\RTMaquetaXR.dll','RTMaquetaXR\RTMaquetaBridge.dll','RTMaquetaXR\W40KRT-VR-Launcher.exe','RTMaquetaXR\portable-install.json')){
            if(-not(Test-Path -LiteralPath (Join-Path $profile $required) -PathType Leaf)){throw "Required installed file is missing: $required"}
        }
        $receipt=Get-Content -LiteralPath (Join-Path $profile 'RTMaquetaXR\portable-install.json') -Raw | ConvertFrom-Json
        $info=Get-Content -LiteralPath (Join-Path $profile 'RTMaquetaXR\Info.json') -Raw | ConvertFrom-Json
        if($receipt.Id -ne 'RTMaquetaXR' -or [string]$receipt.Version -ne $package.Version -or $info.Id -ne 'RTMaquetaXR' -or [string]$info.Version -ne $package.Version){throw 'Publisher installation receipt or mod metadata does not match the release.'}
        if(-not(Confirm-PlacedFilesSurvive -Paths @((Join-Path $profile 'RTMaquetaXR\RTMaquetaXR.dll'),(Join-Path $profile 'RTMaquetaXR\W40KRT-VR-Launcher.exe')) -GameDir $game -NoClear)){throw 'Required W40KRT_VR files did not survive installation.'}
        $cached=Join-Path (Split-Path -Parent $profile) 'W40KRT_VR-package.zip';Copy-Item -LiteralPath $archive -Destination $cached -Force
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $game -Version ([string]$release.Tag) `
            -InstalledPathReceiptPaths @((Join-Path $PSScriptRoot '.installed_path_maqueta'),(Join-Path $PSScriptRoot '.installed_path')) -AdditionalVersionReceiptPaths @((Join-Path $game '.pcvrhub_rogue_maqueta_version')) -VersionSlot Secondary -Route Current)
        $committed=$true
        Write-Host ' [4/4] Finish and choose Tabletop in the Hub' -ForegroundColor Cyan
        Write-Host ' ----------------------------------------' -ForegroundColor DarkGray
        Write-Host ' W40KRT_VR installed. The RTVR files were kept separately.' -ForegroundColor Green
        Write-Host ' Start with the Maqueta Play choice after connecting the supported headset.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host ' Lay the Koronus Expanse across your command table.' -ForegroundColor Magenta
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
    } catch {
        $installError=$_
        if(-not $committed){
            try{
                if($backupReady -and $modFolder){
                    $profileFull=[IO.Path]::GetFullPath($profile).TrimEnd('\','/')
                    $modFull=[IO.Path]::GetFullPath($modFolder)
                    if(-not $modFull.StartsWith(($profileFull+[IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe Maqueta profile rollback path.'}
                    if(Test-Path -LiteralPath $modFolder){
                        if(((Get-Item -LiteralPath $modFolder -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'Maqueta profile became a link; automatic rollback stopped.'}
                        Remove-Item -LiteralPath $modFolder -Recurse -Force -ErrorAction Stop
                    }
                    if($modFolderExisted){Copy-Item -LiteralPath $profileBackup -Destination $modFolder -Recurse -Force -ErrorAction Stop}
                }
                if($params){
                    if($originalExists){[IO.File]::WriteAllBytes($params,[byte[]]$originalBytes)}
                    elseif(Test-Path -LiteralPath $params){Remove-Item -LiteralPath $params -Force -ErrorAction Stop}
                }
            }catch{
                $keepWork=$true
                throw "Rogue Trader install failed: $($installError.Exception.Message). Profile rollback also failed: $($_.Exception.Message). Backup: $profileBackup"
            }
        }
        throw $installError
    } finally {
        if(-not $keepWork -and $work -and (Test-Path -LiteralPath $work)){Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}
    }
}
if(((''+$env:PCVR_ROGUE_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-RogueMaquetaInstaller}
