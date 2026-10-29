# Local recovery for the six mandatory Cyberpunk runtime components.
. (Join-Path $PSScriptRoot 'CyberpunkCompatibility.ps1')
function Get-CyberpunkFrameworkDefinitions {
    foreach($component in (Get-CyberpunkRouteProfile).Components){
        @{Name=$component.Name;Marker=$component.Marker;Urls=@($component.Pinned);Page=$component.Page;Version=$component.Version;File=$component.File}
    }
}
function Read-CyberpunkRecoveryChoice([string]$Prompt,[scriptblock]$ReadInput){
    $answer=if($ReadInput){& $ReadInput $Prompt}else{Read-Host $Prompt}
    if($null -eq $answer -or (-not $ReadInput -and [Console]::IsInputRedirected -and (''+$answer).Length -eq 0)){
        throw [IO.EndOfStreamException]::new('Cyberpunk recovery requires console input; no input was available. Nothing was marked complete.')
    }
    return (''+$answer).Trim()
}
function Confirm-CyberpunkFrameworkFiles {
    param([string]$GameRoot,[scriptblock]$ReadInput=$null,[bool]$AllowRelocate=$true)
    $target=[IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
    $GameRoot=$target
    $definitions=@(Get-CyberpunkFrameworkDefinitions)
    while($true){
        $missing=@(Get-CyberpunkFixedRuntimeProblems -GameRoot $target)
        if($missing.Count -eq 0){return 'Ready'}
        Write-Host '';Write-Host '  REQUIRED FRAMEWORK FILES - RECOVERY' -ForegroundColor Black -BackgroundColor Yellow
        Write-Host ('  Copy destination AND verification folder: '+$target) -ForegroundColor Yellow
        foreach($relative in $missing){Write-Host ('  Needs repair: '+(Join-Path $target $relative)) -ForegroundColor Yellow}
        Write-Host '  Missing files do not establish an antivirus cause. A wrong path, copy failure or permissions are also possible.' -ForegroundColor White
        Write-Host '  No new VR installation or update was marked complete. This screen remains available.' -ForegroundColor White
        Write-Host '  [1] Check these files again (for example after restoring a file)' -ForegroundColor Green
        Write-Host '  [2] Install the compatible versions of frameworks needing repair' -ForegroundColor Cyan
        Write-Host '  [M] Open a missing framework release page and use its downloaded ZIP' -ForegroundColor Cyan
        Write-Host '  [F] Open the selected game folder' -ForegroundColor Cyan
        if($AllowRelocate){Write-Host '  [P] Locate a different game folder and restart setup there' -ForegroundColor Cyan}
        Write-Host '  [L] Open the installer log' -ForegroundColor Cyan
        $choice=(Read-CyberpunkRecoveryChoice '  Recovery choice' $ReadInput).ToUpperInvariant()
        if($choice -eq '1'){continue}
        try{
            if($choice -eq '2'){
                if(Test-CyberpunkGameRunning){Write-Host '  Close Cyberpunk 2077 before repairing files, then choose 2 again.' -ForegroundColor Yellow;continue}
                Write-Host ('  The missing components will be copied into: '+$target) -ForegroundColor Yellow
                [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download and repair the missing frameworks...')
                foreach($component in $definitions|Where-Object {$missing -contains $_.Marker}){
                    $urls=@($component.Urls)
                    if(Install-Component -Label $component.Name -Urls $urls -ManualUrl $component.Page -ManualName $component.File -PayloadRelFile $component.Marker){Write-Host ('  [OK] '+$component.Name+' required file verified.') -ForegroundColor Green}
                    else{Write-Host ('  '+$component.Name+' still needs attention. Recovery remains available.') -ForegroundColor Yellow}
                }
                continue
            }
            if($choice -eq 'F'){
                Write-Host ('  Open this exact copy/check destination in Explorer: '+$target) -ForegroundColor White
                [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the selected game folder...')
                Start-Process explorer.exe -ArgumentList ('"'+$target+'"')|Out-Null
                continue
            }
            if($choice -eq 'L'){
                $log=[string]$global:PCVRInstallerLiveLogPath
                if(-not $log -or -not(Test-Path -LiteralPath $log -PathType Leaf)){Write-Host '  No saved live log is available in this session. The file checks and paths remain visible above.' -ForegroundColor Yellow;continue}
                Write-Host ('  Installer log: '+$log) -ForegroundColor White
                [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the installer log...')
                Start-Process notepad.exe -ArgumentList ('"'+$log+'"')|Out-Null
                continue
            }
            if($choice -eq 'P'){
                if(-not $AllowRelocate){Write-Host '  VR files have already been copied. This recovery repairs the selected folder; changing it here would leave an incomplete installation behind.' -ForegroundColor Yellow;continue}
                Write-Host '  Drag/paste Cyberpunk2077.exe or the game folder. Setup will restart and check its version again.' -ForegroundColor White
                $picked=ConvertTo-PCVRCanonicalUserPath (Read-CyberpunkRecoveryChoice '  Game EXE or folder' $ReadInput)
                if(Test-Path -LiteralPath $picked -PathType Leaf){$picked=Split-Path $picked -Parent}
                $valid=$null
                for($level=0;$level -lt 4 -and $picked;$level++){
                    if(Test-CP2077Root $picked){$valid=[IO.Path]::GetFullPath($picked);break}
                    $picked=Split-Path $picked -Parent
                }
                if(-not $valid){Write-Host '  The selected folder has no bin\x64\Cyberpunk2077.exe. Nothing was changed; choose P again.' -ForegroundColor Yellow;continue}
                if(-not(Save-HubRememberedGameFolder -GameId 'cyberpunk-2077' -Title 'Cyberpunk 2077' -GameDir $valid -ProbeFiles @('bin\x64\Cyberpunk2077.exe') -UserSelected)){throw 'The corrected game folder could not be saved.'}
                [void](Set-PCVRRecoveryInput '')
                return 'Restart'
            }
            if($choice -eq 'M'){
                if(Test-CyberpunkGameRunning){Write-Host '  Close Cyberpunk 2077 before installing a framework ZIP.' -ForegroundColor Yellow;continue}
                $available=@($definitions|Where-Object {$missing -contains $_.Marker})
                for($index=0;$index -lt $available.Count;$index++){Write-Host ('  '+($index+1)+'. '+$available[$index].Name) -ForegroundColor Cyan}
                $number=Read-CyberpunkRecoveryChoice '  Which missing framework?' $ReadInput
                if($number -notmatch '^\d+$' -or [int]$number -lt 1 -or [int]$number -gt $available.Count){Write-Host '  Choose one of the listed numbers.' -ForegroundColor Yellow;continue}
                $component=$available[[int]$number-1]
                Write-Host ('  Download '+$component.File+' for the selected game version from the linked release.') -ForegroundColor Yellow
                [void](Open-PCVRPageAfterEnter -Url $component.Page -Message ('Press Enter to open the '+$component.Name+' release page...'))
                [void](Wait-PCVRExplicitEnter -Message 'After downloading the ZIP, press Enter to hand it to setup...')
                $archive=ConvertTo-PCVRCanonicalUserPath (Read-CyberpunkRecoveryChoice '  Drag/paste the downloaded framework ZIP' $ReadInput)
                if(-not(Test-Path -LiteralPath $archive -PathType Leaf)){Write-Host '  That downloaded file was not found. Recovery remains available.' -ForegroundColor Yellow;continue}
                [void](Install-Component -Label $component.Name -Urls @($component.Urls) -ManualUrl $component.Page -ManualName $component.File -PayloadRelFile $component.Marker -ManualArchive $archive)
                continue
            }
            Write-Host '  Choose 1, 2, M, F, P or L. The installer remains open.' -ForegroundColor Yellow
        }catch{
            if($_.Exception.GetBaseException() -is [IO.EndOfStreamException]){throw}
            Write-Host ('  Recovery action did not complete: '+$_.Exception.Message) -ForegroundColor Yellow
            Write-Host '  You can retry, choose another action or hand over a downloaded ZIP.' -ForegroundColor White
        }
    }
}
