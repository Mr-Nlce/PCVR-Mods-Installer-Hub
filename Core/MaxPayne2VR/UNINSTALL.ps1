param([ValidateSet('','evil','betotron')][string]$Mod='',[switch]$HubConfirmed,[switch]$NoPause)
$ErrorActionPreference='Stop'
Import-Module Microsoft.PowerShell.Utility -ErrorAction Stop
. (Join-Path $PSScriptRoot '..\Modules\InstallerSafety.ps1')
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot 'MaxPayne2VR-Dual.ps1')
. (Join-Path $PSScriptRoot 'MaxPayne2VR-Stage.ps1')

$game=$null
if($env:PCVR_MP2_SELECTED_GAME -and (Test-Path -LiteralPath (Join-Path $env:PCVR_MP2_SELECTED_GAME 'maxpayne2.exe') -PathType Leaf)){
    $game=[IO.Path]::GetFullPath($env:PCVR_MP2_SELECTED_GAME)
}elseif(Test-Path -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -PathType Leaf){
    $saved=(Get-Content -LiteralPath (Join-Path $PSScriptRoot '.installed_path') -Raw).Trim()
    if(Test-Path -LiteralPath (Join-Path $saved 'maxpayne2.exe') -PathType Leaf){$game=$saved}
}
if(-not $game){$game=Find-SteamGameFolder -AppId '12150' -SteamFolderNames @('Max Payne 2 The Fall of Max Payne','Max Payne 2') -ProbeExe 'MaxPayne2.exe' -GogNames @('Max Payne 2','Max Payne 2 The Fall of Max Payne')}
if(-not $game){throw 'Max Payne 2 was not found. Locate the installed game again.'}
Assert-MP2GameClosed
if(-not $Mod){
    Write-Host 'Remove one Max Payne 2 VR mod:' -ForegroundColor Cyan
    Write-Host '[1] MP2VR by evilSheep' -ForegroundColor White
    Write-Host '[2] MaxPayne2VR by betotron' -ForegroundColor White
    $answer=(Read-Host 'Choose 1, 2 or Q').Trim().ToLowerInvariant()
    if($answer -eq 'q'){exit 0}
    if($answer -notin @('1','2')){throw 'No mod was selected.'}
    $Mod=if($answer -eq '1'){'evil'}else{'betotron'}
}
$slot=if($Mod -eq 'evil'){'A'}else{'B'}
$other=if($slot -eq 'A'){'B'}else{'A'}
$v2Identity=if($slot -eq 'A'){'mp2evilruntime'}else{'mp2betotronruntime'}
$v2Profile=Join-Path (Get-MP2ProfileRoot $game) $slot
$v2Manifest=Join-Path $v2Profile ".pcvrhub_${v2Identity}_ownership.csv"
if(Test-Path -LiteralPath $v2Manifest -PathType Leaf) {
    if(-not(Test-MP2V2Slot -Game $game -Slot $slot -Parked)) { throw 'The selected stored VR profile is incomplete; no files were removed.' }
    if(-not $HubConfirmed -and (Read-Host "Type REMOVE to uninstall $Mod; the other mod stays installed") -ne 'REMOVE') { return }
    $modeFile=Get-MP2ModeFile $game
    $mode=if(Test-Path -LiteralPath $modeFile -PathType Leaf){(Get-Content -LiteralPath $modeFile -Raw).Trim()}else{'None'}
    if($mode -notin @('A','B','None')) { throw 'Unknown saved Max Payne 2 mode; no files were removed.' }
    $targetActive=($mode -eq $slot)
    if($targetActive -and -not(Test-MP2Slot -Game $game -Slot $slot)) {
        foreach($name in @($script:MP2SlotFiles.A+$script:MP2SlotFiles.B|Select-Object -Unique)) {
            $live=Join-Path $game $name
            if(-not(Test-Path -LiteralPath $live -PathType Leaf)) { continue }
            if(-not(Test-MP2KnownRuntimeFragment -Game $game -Slot $slot -Name $name)) {
                throw "The incomplete active mode contains an unknown $name; no files were removed."
            }
        }
    }
    $otherPresent=((Test-MP2Slot -Game $game -Slot $other -Parked) -or
                   (($mode -eq $other) -and (Test-MP2Slot -Game $game -Slot $other)))
    $stamp=Join-Path $game $(if($slot -eq 'A'){'.pcvrhub_maxpayne2_evil_version'}else{'.pcvrhub_maxpayne2_betotron_version'})
    $work=Join-Path ([IO.Path]::GetTempPath()) ('pcvr_mp2_remove_'+[guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($work)
    $paths=@($v2Profile,$stamp,$modeFile,(Get-MP2ActiveProofFile $game),(Join-Path (Get-MP2ProfileRoot $game) 'Base'),
        (Join-Path $game $(if($slot -eq 'A'){'.pcvrhub_version_b'}else{'.pcvrhub_version'})))
    $paths+=@($script:MP2SlotFiles.A+$script:MP2SlotFiles.B | Select-Object -Unique | ForEach-Object {Join-Path $game $_})
    if($slot -eq 'A') {
        $contentManifest=Join-Path $game '.pcvrhub_mp2evilcontent_ownership.csv'
        $paths+=@($contentManifest,(Join-Path $game '.pcvrhub_mp2evilcontent_backup'),(Join-Path $game 'MP2VR-Install\receipt.json'))
        if(Test-Path -LiteralPath $contentManifest -PathType Leaf) {
            $paths+=@(Import-Csv -LiteralPath $contentManifest | ForEach-Object {Join-Path $game ([string]$_.RelativePath)})
        }
    } else {
        $paths+=@((Join-Path $game '.pcvrhub_maxpayne2vr_ownership.csv'),(Join-Path $game '.pcvrhub_maxpayne2vr_backup'))
    }
    $snapshot=Save-MP2InstallSnapshot -Game $game -Paths $paths -Destination (Join-Path $work 'before')
    try {
        if($targetActive) {
            foreach($name in $script:MP2SlotFiles[$slot]) {
                $live=Join-Path $game $name
                if(Test-Path -LiteralPath $live -PathType Leaf) { Remove-Item -LiteralPath $live -Force -ErrorAction Stop }
            }
            Write-MP2Mode $game 'None'
            Remove-Item -LiteralPath (Get-MP2ActiveProofFile $game) -Force -ErrorAction SilentlyContinue
        }
        $profileResult=Uninstall-OwnedModPayload -GameRoot $v2Profile -Identity $v2Identity
        if(-not $profileResult.Found -or [int]$profileResult.Preserved -gt 0) { throw 'The stored runtime has changed; review its files before removing this mod.' }
        Remove-Item -LiteralPath (Join-Path $v2Profile 'version.txt') -Force -ErrorAction SilentlyContinue
        # The older Hub sometimes parked its own runtime before this profile
        # was updated. Remove only files still matching that older ownership.
        foreach($name in $script:MP2SlotFiles[$slot]) {
            $parked=Join-Path $v2Profile $name
            if(-not(Test-Path -LiteralPath $parked -PathType Leaf)) { continue }
            $known=$false
            if($slot -eq 'A') {
                $receipt=Get-MP2Receipt $game
                $entry=if($receipt){$receipt.files.PSObject.Properties[$name]}else{$null}
                $known=($entry -and $entry.Value.installed_sha256 -and
                    (Get-FileHash -LiteralPath $parked -Algorithm SHA256).Hash -ieq [string]$entry.Value.installed_sha256)
            } else {
                $oldManifest=Join-Path $game '.pcvrhub_maxpayne2vr_ownership.csv'
                if(Test-Path -LiteralPath $oldManifest -PathType Leaf) {
                    $row=@(Import-Csv -LiteralPath $oldManifest | Where-Object RelativePath -ieq $name | Select-Object -First 1)[0]
                    $known=($row -and $row.InstalledSha256 -and
                        (Get-FileHash -LiteralPath $parked -Algorithm SHA256).Hash -ieq [string]$row.InstalledSha256)
                }
            }
            if($known) { Remove-Item -LiteralPath $parked -Force -ErrorAction Stop }
        }
        if($slot -eq 'A') {
            $contentResult=Uninstall-OwnedModPayload -GameRoot $game -Identity mp2evilcontent
            if(-not $contentResult.Found -or [int]$contentResult.Preserved -gt 0) { throw 'Some MP2VR content has changed; it was not removed.' }
            $receipt=Get-MP2Receipt $game
            if($receipt -and $receipt.status -eq 'installed') {
                foreach($name in $script:MP2SlotFiles.A) {
                    $entry=$receipt.files.PSObject.Properties[$name]
                    if(-not $entry -or -not $entry.Value.original) { continue }
                    $relative=([string]$entry.Value.original).Replace('/','\')
                    if($relative -notmatch '^originals\\[a-fA-F0-9]{32}\\[^\\/]+$' -or [IO.Path]::GetFileName($relative) -ne $name) { throw "Old backup path for $name is invalid." }
                    $source=Join-Path (Join-Path $game 'MP2VR-Install') $relative
                    if(-not(Test-Path -LiteralPath $source -PathType Leaf) -or
                       (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ine [string]$entry.Value.original_sha256) { throw "Old backup for $name is missing or changed." }
                    $destination=if($targetActive){Join-Path $game $name}else{Join-Path (Join-Path (Get-MP2ProfileRoot $game) 'Base') $name}
                    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
                    if(Test-Path -LiteralPath $destination -PathType Leaf) {
                        if((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ine [string]$entry.Value.original_sha256) { throw "Original $name conflicts with an existing file." }
                    } else { Copy-Item -LiteralPath $source -Destination $destination -ErrorAction Stop }
                }
                $receipt.status='uninstalled'
                Write-PCVRAtomicText -Path (Join-Path $game 'MP2VR-Install\receipt.json') -Value ($receipt | ConvertTo-Json -Depth 20)
            }
        } else {
            $oldManifest=Join-Path $game '.pcvrhub_maxpayne2vr_ownership.csv'
            if(Test-Path -LiteralPath $oldManifest -PathType Leaf) {
                if($targetActive) {
                    $oldResult=Uninstall-OwnedModPayload -GameRoot $game -Identity maxpayne2vr
                    if([int]$oldResult.Preserved -gt 0) { throw 'Changed old MaxPayne2VR files need manual review.' }
                } else {
                    $backupRoot=Join-Path $game '.pcvrhub_maxpayne2vr_backup'
                    $base=Join-Path (Get-MP2ProfileRoot $game) 'Base'
                    foreach($row in @(Import-Csv -LiteralPath $oldManifest)) {
                        if([string]$row.HadOriginal -ne 'True') { continue }
                        $name=[string]$row.RelativePath
                        if($name -notin $script:MP2SlotFiles.B) { throw "Unexpected old ownership path: $name" }
                        $source=Join-Path $backupRoot $name
                        if(-not(Test-Path -LiteralPath $source -PathType Leaf)) { throw "Old original backup for $name is missing." }
                        [void][IO.Directory]::CreateDirectory($base)
                        $destination=Join-Path $base $name
                        if(Test-Path -LiteralPath $destination -PathType Leaf) {
                            if((Get-FileHash $destination -Algorithm SHA256).Hash -ne (Get-FileHash $source -Algorithm SHA256).Hash) { throw "Original $name conflicts with a saved file." }
                        } else { Copy-Item -LiteralPath $source -Destination $destination -ErrorAction Stop }
                    }
                    Remove-Item -LiteralPath $oldManifest -Force -ErrorAction Stop
                    if(Test-Path -LiteralPath $backupRoot -PathType Container) { Remove-Item -LiteralPath $backupRoot -Recurse -Force -ErrorAction Stop }
                }
            }
        }
        if($targetActive -and $otherPresent) { Save-MP2RestoredBaseFiles $game }
        if(-not $otherPresent -and $mode -in @($slot,'None')) { Restore-MP2BaseFiles $game }
        Remove-Item -LiteralPath $stamp -Force -ErrorAction Stop
        $genericStamp=Join-Path $game $(if($slot -eq 'A'){'.pcvrhub_version_b'}else{'.pcvrhub_version'})
        Remove-Item -LiteralPath $genericStamp -Force -ErrorAction SilentlyContinue
        if(-not $otherPresent) { Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.installed_version') -Force -ErrorAction SilentlyContinue }
        Write-Host "Removed $Mod. The other mod, if present, is ready for its own Hub Play button." -ForegroundColor Green
        Write-Host 'Saves and personal VR settings were kept.' -ForegroundColor Gray
        if(-not $NoPause){try{Read-Host 'Press Enter to exit'|Out-Null}catch{}}
        return
    } catch {
        $failure=$_
        try { Restore-MP2InstallSnapshot -Game $game -Entries $snapshot }
        catch { Write-Warning ('Max Payne 2 removal rollback needs repair: '+$_.Exception.Message) }
        throw $failure
    } finally {
        $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
        if([IO.Path]::GetFullPath($work).StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -and
           (Test-Path -LiteralPath $work -PathType Container)) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
$active=Get-MP2ActiveMode $game
if(-not(Test-MP2Slot -Game $game -Slot $slot -Parked:($active -ne $slot))){throw 'The selected VR mod is not fully installed; no files were removed.'}
if(-not $HubConfirmed){
    if((Read-Host "Type REMOVE to uninstall $Mod; the other mod stays installed") -ne 'REMOVE'){exit 0}
}
$otherPresent=Test-MP2Slot -Game $game -Slot $other -Parked:($active -ne $other)
if($active -ne $slot){Activate-MP2Mode -Game $game -Slot $slot}
if($slot -eq 'A'){
    $package=Join-Path $game 'MP2VR-Install'
    $python=Join-Path $package 'setup-files\python\python.exe'
    $tool=Join-Path $package 'setup-files\tools\release_install.py'
    if(-not(Test-Path -LiteralPath $python -PathType Leaf) -or -not(Test-Path -LiteralPath $tool -PathType Leaf)){
        throw 'The publisher uninstall runtime is missing. MP2VR files were retained.'
    }
    $old=$env:PYTHONDONTWRITEBYTECODE
    try{
        $env:PYTHONDONTWRITEBYTECODE='1'
        $args=@('-B',('"'+$tool+'"'),'uninstall','--game',('"'+$game+'"'),'--package',('"'+$package+'"'))
        $proc=Start-Process -FilePath $python -ArgumentList $args -WorkingDirectory $package -NoNewWindow -PassThru -Wait -ErrorAction Stop
        if($proc.ExitCode -ne 0){throw "Publisher uninstall failed (exit $($proc.ExitCode))."}
    }finally{$env:PYTHONDONTWRITEBYTECODE=$old}
    $receipt=Get-MP2Receipt $game
    if(-not $receipt -or $receipt.status -ne 'uninstalled'){throw 'The publisher did not confirm the removal.'}
    foreach($name in @($script:MP2SlotFiles.A)){
        if(@($receipt.preserved) -contains $name){throw "The publisher preserved a changed $name. Review that file before switching."}
    }
    Remove-Item -LiteralPath (Join-Path $game '.pcvrhub_maxpayne2_evil_version') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $game '.pcvrhub_version_b') -Force -ErrorAction SilentlyContinue
}else{
    $result=Uninstall-OwnedModPayload -GameRoot $game -Identity 'maxpayne2vr' -ParkedAlternates @{'winmm.dll'='winmm.dll.pcvrhub_off'}
    if(-not $result.Found -or [int]$result.Preserved -gt 0){throw 'Some MaxPayne2VR files were modified or could not be removed. Review them before switching.'}
    Remove-Item -LiteralPath (Join-Path $game '.pcvrhub_version') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $game '.pcvrhub_maxpayne2_betotron_version') -Force -ErrorAction SilentlyContinue
}
$profile=Join-Path (Get-MP2ProfileRoot $game) $slot
if(Test-Path -LiteralPath $profile -PathType Container){Remove-Item -LiteralPath $profile -Recurse -Force -ErrorAction Stop}
Write-MP2Mode $game 'None'
if($otherPresent){
    Save-MP2RestoredBaseFiles $game
    Activate-MP2Mode -Game $game -Slot $other
    Write-Host 'The other VR mod is still installed and now active.' -ForegroundColor Green
}else{
    Restore-MP2BaseFiles $game
    Remove-Item -LiteralPath (Get-MP2ModeFile $game) -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $PSScriptRoot '.installed_version') -Force -ErrorAction SilentlyContinue
    Write-Host 'No Max Payne 2 VR mod remains active. Original game files were restored.' -ForegroundColor Green
}
Write-Host 'Saves and personal VR settings were kept.' -ForegroundColor Gray
if(-not $NoPause){Read-Host 'Press Enter to exit'|Out-Null}
