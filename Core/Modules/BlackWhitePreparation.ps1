# Guided prerequisites and permission handoff for the original Black & White.
function Initialize-BlackWhiteConsole {
    param([object]$RawUI=$Host.UI.RawUI)
    try {
        $RawUI.BackgroundColor='Black'
        $RawUI.ForegroundColor='Gray'
        Clear-Host
    } catch {}
}
function Write-BlackWhiteSafeTranscript([string]$Source,[string]$Destination) {
    . (Join-Path $PSScriptRoot 'InstallerTestReport.ps1')
    $text=ConvertTo-PCVRTestReportSafeText (Read-PCVRTestReportTranscript -Path $Source)
    [IO.File]::WriteAllText($Destination,$text,[Text.UTF8Encoding]::new($false))
}
function Get-BlackWhitePatchSteps {
    @(
        @{Version='1.10';File='Black_White_Patch_v1.100.exe';Page='https://www.bwgame.net/downloads/v1-1-patch.129/'},
        @{Version='1.20';File='black_white_patch_v1_20.exe';Page='https://www.bwgame.net/downloads/v1-2-patch.130/'},
        @{Version='1.42';File='BWFanPatchInstaller.exe';Page='https://www.bwgame.net/downloads/black-white-unofficial-patch-v1-42.1418/'}
    )
}
function Test-BlackWhiteAdministrator {
    $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Invoke-BlackWhitePatchProcess([string]$File) {
    $process=Start-Process -FilePath $File -Verb RunAs -Wait -PassThru
    if($null -eq $process -or $null -eq $process.ExitCode -or [int]$process.ExitCode -ne 0){
        throw ('Patch Setup did not finish successfully (exit '+$process.ExitCode+'). No VR files were installed.')
    }
}
function Install-BlackWhitePatches([string]$Game,$Test=$null) {
    if(Test-Path -LiteralPath (Join-Path $Game 'readme-patch-v142.txt') -PathType Leaf){return}
    Write-Host '  Install these in order: 1.10 -> 1.20 -> 1.42. Select the same game folder in every Setup.' -ForegroundColor Yellow
    Write-Host ('  Game folder: '+$Game) -ForegroundColor Yellow
    Write-Host '  If a step was already completed, choose 2 to keep it. Never install 1.30.' -ForegroundColor Yellow
    $session=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
    try{
        foreach($patch in @(Get-BlackWhitePatchSteps)){
            Write-Host '';Write-Host ('  PATCH '+$patch.Version) -ForegroundColor Black -BackgroundColor Yellow
            Write-Host '  1. Download and install this patch (recommended if missing)' -ForegroundColor Green
            Write-Host '  2. This patch is already installed; continue to the next step' -ForegroundColor White
            if($Test){$choice='1'}else{do{$choice=(''+(Read-Host '  Choose 1 or 2 (Enter = 1)')).Trim()}until($choice -in @('','1','2'))}
            if($choice -eq '2'){continue}
            $setup=Join-Path $session $patch.File
            [void](Wait-PCVRExplicitEnter -Message ('Press Enter to download Patch '+$patch.Version+' (Setup may require UAC)...'))
            if($Test){
                $source=[IO.Path]::GetFullPath([string]$Test.Patches.($patch.Version))
                if(-not $source.StartsWith(([IO.Path]::GetFullPath($Test.Root).TrimEnd('\')+'\'),[StringComparison]::OrdinalIgnoreCase)){throw 'Patch fixture escaped its isolated root.'}
                Copy-Item -LiteralPath $source -Destination $setup
            }else{[void](Invoke-SafeDownload -Urls @($patch.Page+'download') -Destination $setup -Label ('Black & White Patch '+$patch.Version) -ManualUrl $patch.Page -AllowSkip $false -PlainProgress)}
            # Technical EXE validation only; no historical identity/size gate.
            $stream=[IO.File]::OpenRead($setup)
            try{if($stream.ReadByte() -ne 77 -or $stream.ReadByte() -ne 90){throw 'The patch download is not a Windows Setup EXE. Use its official page or hand over the downloaded EXE in recovery.'}}finally{$stream.Dispose()}
            Write-Host ('  In Setup select: '+$Game) -ForegroundColor Yellow
            Write-Host '  Complete installation and close Setup before returning here. Windows may request administrator approval.' -ForegroundColor Yellow
            [void](Wait-PCVRExplicitEnter -Message ('Press Enter to open and install Patch '+$patch.Version+' (possible UAC)...'))
            if($Test){Invoke-Round8Native -File $setup -Arguments @(('"'+$Game+'"'),$patch.Version)}else{Invoke-BlackWhitePatchProcess -File $setup}
            [void](Wait-PCVRExplicitEnter -Message ('After Patch '+$patch.Version+' has finished in the shown game folder, press Enter to continue...'))
        }
        if(-not(Test-Path -LiteralPath (Join-Path $Game 'readme-patch-v142.txt') -PathType Leaf)){
            throw ('Patch 1.42 was not found in '+$Game+'. Check the target folder in patch Setup, then Retry. No VR files were installed.')
        }
        Write-Host '  [OK] Patch 1.42 files found. VR publisher Setup will validate the exact game build.' -ForegroundColor Green
    }finally{Remove-PCVRInstallerTempSession -Path $session}
}
function Invoke-BlackWhitePermissionHandoff([string]$Game,[string]$InstallerFolder,[switch]$Uninstall) {
    if(Test-InstallerTargetWritable -TargetPath $Game){return $false}
    if(Test-BlackWhiteAdministrator){throw ('The game folder is still not writable with administrator permission: '+$Game+'. Check folder access or a read-only drive, then Retry.')}
    Write-Host '';Write-Host '  ADMINISTRATOR APPROVAL REQUIRED' -ForegroundColor Black -BackgroundColor Yellow
    Write-Host ('  Windows protects this game folder: '+$Game) -ForegroundColor Yellow
    Write-Host '  Continue this Black & White setup with UAC so it can install, back up and restore files there.' -ForegroundColor Yellow
    Write-Host '  Your folder permissions will not be changed. Keep this window open until setup finishes.' -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to continue Black & White setup with administrator approval...')
    $session=New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
    try{
        $context=Join-Path $session 'blackwhite-context.json'
        $result=Join-Path $session 'blackwhite-result.json'
        $desktop=if($global:BlackWhiteDesktopOverride){$global:BlackWhiteDesktopOverride}else{[Environment]::GetFolderPath('Desktop')}
        . (Join-Path $PSScriptRoot 'HubState.ps1')
        $portable=Get-HubPortableStateRoot
        if(-not $portable){$portable=Join-Path (Split-Path $InstallerFolder -Parent) 'UserData'}
        $logRoot=Join-Path (Split-Path (Get-HubStateRoot) -Parent) 'Logs'
        [void][IO.Directory]::CreateDirectory($logRoot)
        $childLog=Join-Path $logRoot ('BlackWhite-admin-'+[guid]::NewGuid().ToString('N')+'.log')
        $request=@{Game=$Game;Desktop=$desktop;StateRoot=(Get-HubStateRoot);PortableRoot=$portable;Local=$env:LOCALAPPDATA;Roaming=$env:APPDATA;UserProfile=$env:USERPROFILE;Status=$env:PCVR_HUB_INSTALL_STATUS_PATH;RunId=$env:PCVR_HUB_INSTALL_RUN_ID;Result=$result;Log=$childLog;RuntimeRoot=(Get-HubRuntimeRoot);Downloads=(Get-PCVRDownloadsFolder);Uninstall=[bool]$Uninstall}
        [IO.File]::WriteAllText($context,($request|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
        $core=Join-Path $InstallerFolder 'BlackWhiteVR-core.ps1'
        $process=Start-Process -FilePath (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$core+'"'),'-ElevatedContext',('"'+$context+'"')) -Wait -PassThru
        if($null -eq $process -or $null -eq $process.ExitCode -or [int]$process.ExitCode -ne 0 -or -not(Test-Path -LiteralPath $result -PathType Leaf)){throw 'Administrator setup was cancelled or did not complete. Retry to reopen it; nothing was marked complete.'}
        $completed=Get-Content -LiteralPath $result -Raw|ConvertFrom-Json
        if($completed.Game -cne $Game -or $completed.Success -ne $true){throw 'Administrator setup did not confirm this game folder.'}
        if(-not $Uninstall){
            foreach($name in @((Get-Round8VRProfile 'BlackWhite').Required)+@('.pcvrhub_version')){
                if(-not(Test-Path -LiteralPath (Join-Path $Game $name) -PathType Leaf)){throw ('Administrator setup is missing a required installed file: '+$name)}
            }
            if(-not(Test-IsTrackableInstalledVersion ([IO.File]::ReadAllText((Join-Path $Game '.pcvrhub_version')).Trim()))){throw 'Administrator setup has no installed version.'}
        }
        return $true
    }finally{
        # Preserve the elevated transcript in the initiating installer's log.
        if($childLog -and (Test-Path -LiteralPath $childLog -PathType Leaf)){
            $logPath=$global:PCVRInstallerLiveLogPath
            if($logPath){try{[IO.File]::AppendAllText($logPath,[IO.File]::ReadAllText($childLog))}catch{}}
        }
        Remove-PCVRInstallerTempSession -Path $session
    }
}
