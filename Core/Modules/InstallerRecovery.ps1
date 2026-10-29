# ============================================================
# PCVR Mods Hub - universal installer recovery
# ============================================================
# This module is loaded by the installer wrapper and by both installer helper
# generations. It owns the last recovery surface: any installer failure which
# was not resolved locally arrives here and remains recoverable in the same
# window. There is deliberately no error-screen Exit/Q action. Closing the
# console window is still a user-controlled Windows action, but the Hub never
# recommends abandoning an unresolved installer failure.

if (-not (Get-Command Get-PCVRDownloadsFolder -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'KnownFolders.ps1')
}

function global:ConvertTo-PCVRCanonicalUserInput {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return $Value }
    $raw=(''+$Value).Trim()
    $unquoted=$raw.Trim('"').Trim("'").Trim()
    if($unquoted -match '^(?<drive>[A-Za-z]):$'){
        return ($Matches.drive.ToUpperInvariant()+':\')
    }
    if($unquoted -match '^(?<drive>[A-Za-z]):(?<tail>[^\\/].+)$'){
        return ($Matches.drive.ToUpperInvariant()+':\'+$Matches.tail.TrimStart([char[]]@([char]92,[char]47)))
    }
    return $Value
}

function global:ConvertTo-PCVRCanonicalUserPath {
    param([Parameter(Mandatory=$true)][string]$Path)
    $value=(''+(ConvertTo-PCVRCanonicalUserInput $Path)).Trim().Trim('"').Trim("'").Trim()
    if(-not $value){return ''}
    $value=[Environment]::ExpandEnvironmentVariables($value)
    try{return [IO.Path]::GetFullPath($value)}catch{return $value}
}

function global:Set-PCVRRecoveryInput {
    param([AllowEmptyString()][string]$Path='')
    if([string]::IsNullOrWhiteSpace($Path)){
        Remove-Item Env:PCVR_HUB_RECOVERY_INPUT -ErrorAction SilentlyContinue
        return ''
    }
    $resolved=ConvertTo-PCVRCanonicalUserPath $Path
    $env:PCVR_HUB_RECOVERY_INPUT=$resolved
    return $resolved
}

function global:Get-PCVRRecoveryInput {
    param([ValidateSet('Any','Leaf','Container')][string]$PathType='Any')
    $raw=(''+$env:PCVR_HUB_RECOVERY_INPUT).Trim()
    if(-not $raw){return $null}
    $path=ConvertTo-PCVRCanonicalUserPath $raw
    $exists=switch($PathType){
        'Leaf' {Test-Path -LiteralPath $path -PathType Leaf -ErrorAction SilentlyContinue}
        'Container' {Test-Path -LiteralPath $path -PathType Container -ErrorAction SilentlyContinue}
        default {Test-Path -LiteralPath $path -ErrorAction SilentlyContinue}
    }
    if($exists){
        try{return (Get-Item -LiteralPath $path -Force -ErrorAction Stop).FullName}catch{return $path}
    }
    return $null
}

function global:Resolve-PCVRRecoveryEntryPoint {
    param([string]$Path)
    if(-not $Path){return $null}
    $resolved=ConvertTo-PCVRCanonicalUserPath $Path
    if(Test-Path -LiteralPath $resolved -PathType Leaf -ErrorAction SilentlyContinue){
        $extension=[IO.Path]::GetExtension($resolved)
        if($extension -in @('.bat','.ps1')){
            return [pscustomobject]@{Path=(Get-Item -LiteralPath $resolved -Force).FullName;Kind=$(if($extension -eq '.ps1'){'Direct'}else{'Bat'})}
        }
        return $null
    }
    if(-not(Test-Path -LiteralPath $resolved -PathType Container -ErrorAction SilentlyContinue)){return $null}
    $start=Join-Path $resolved 'START_INSTALLER.bat'
    if(Test-Path -LiteralPath $start -PathType Leaf -ErrorAction SilentlyContinue){
        return [pscustomobject]@{Path=(Get-Item -LiteralPath $start -Force).FullName;Kind='Bat'}
    }
    $scripts=@(Get-ChildItem -LiteralPath $resolved -File -ErrorAction SilentlyContinue|Where-Object{$_.Name -match '(?i)(-core|^install_).*\.ps1$'}|Sort-Object Name)
    if($scripts.Count -eq 1){return [pscustomobject]@{Path=$scripts[0].FullName;Kind='Direct'}}
    return $null
}

function global:Enable-PCVRReadHostPathGuard {
    # Install only inside the child installer runspace. Exact bare-drive input
    # is unambiguous there and must never retain PowerShell's hidden per-drive
    # current-directory semantics.
    $body={
        param([Parameter(Position=0)][string]$Prompt)
        $answer=if($PSBoundParameters.ContainsKey('Prompt')){
            Microsoft.PowerShell.Utility\Read-Host -Prompt $Prompt
        }else{
            Microsoft.PowerShell.Utility\Read-Host
        }
        if ($null -eq $answer) { return $null }
        return (ConvertTo-PCVRCanonicalUserInput (''+$answer))
    }
    Set-Item -LiteralPath Function:\global:Read-Host -Value $body -Force
}

function global:Get-PCVRRecoveryCatalogInfo {
    param([string]$GameId,[string]$CoreRoot)
    if (-not $GameId -or -not $CoreRoot) { return $null }
    $catalogPath=Join-Path $CoreRoot 'Modules\Catalog.ps1'
    if(-not(Test-Path -LiteralPath $catalogPath -PathType Leaf)){return $null}
    try {
        $game=& {
            param($Path,$Id)
            . $Path
            @(@($ownGames)+@($ownGamesGP)+@($externalGames)) |
                Where-Object { $_.Id -eq $Id } | Select-Object -First 1
        } $catalogPath $GameId
        if(-not $game -or $game.GithubRepoB){return $null}
        $repo=(''+$game.GithubRepo).Trim()
        if($repo -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'){return $null}
        return [pscustomobject]@{PageUrl=('https://github.com/'+$repo+'/releases');AssetPatterns=@($game.GithubReleaseAssetPatterns|Where-Object{$_})}
    } catch { return $null }
}

function global:Get-PCVRRecoveryCatalogPage {
    param([string]$GameId,[string]$CoreRoot)
    $info=Get-PCVRRecoveryCatalogInfo -GameId $GameId -CoreRoot $CoreRoot
    if($info){return $info.PageUrl}
    return ''
}

function global:Get-PCVRRecoverySuggestion {
    param([string]$GameId,[string]$FailureMessage)
    $message=''+$FailureMessage
    switch($GameId){
        'borderlands-goty-enhanced' {
            if($message -match 'Required game configuration is missing\.'){
                return [pscustomobject]@{Label='Start Borderlands GOTY Enhanced flat to create its configuration';Url='steam://rungameid/729040';After='Reach the main menu, close the game, then press Enter to retry setup.'}
            }
        }
        'warhammer-40k-rogue-trader-vr' {
            if($message -match 'Start Rogue Trader once and close it to create the Owlcat mod profile\.'){
                return [pscustomobject]@{Label='Start Rogue Trader flat to create its Owlcat mod profile';Url='steam://rungameid/2186680';After='Reach the main menu, close the game, then press Enter to retry setup.'}
            }
        }
    }
    if($message -match '^Steam was not found\. Run Steam once, then start this installer again\.'){
        return [pscustomobject]@{Label='Open the official Steam page to install or start Steam';Url='https://store.steampowered.com/about/';After='Install Steam or start the installed client once, then press Enter to retry setup.'}
    }
    return $null
}

function global:Get-PCVRRecoveryMatchingDownloads {
    param([string]$DownloadsFolder,[string[]]$AssetPatterns)
    if(-not $DownloadsFolder -or -not(Test-Path -LiteralPath $DownloadsFolder -PathType Container)){return @()}
    if(-not $AssetPatterns -or $AssetPatterns.Count -eq 0){return @()}
    return @(Get-ChildItem -LiteralPath $DownloadsFolder -File -ErrorAction SilentlyContinue |
        Where-Object { $file=$_; $file.Length -gt 0 -and $file.Name -notmatch '(?i)\.(crdownload|part|tmp|opdownload)$' -and
            @($AssetPatterns|Where-Object{$_ -and $file.Name -match $_}).Count -gt 0 } |
        Sort-Object LastWriteTimeUtc -Descending)
}

function global:Invoke-PCVRUniversalRecovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$FailureMessage,
        [string]$LogPath='',
        [string]$InstallerFolder='',
        [string]$DownloadsFolder='',
        [string]$RecoveryPageUrl='',
        [string]$GameId='',
        [scriptblock]$ReadInput=$null,
        [scriptblock]$OpenLog=$null,
        [scriptblock]$OpenPath=$null,
        [scriptblock]$OpenPage=$null,
        [scriptblock]$LaunchGame=$null
    )
    if(-not $DownloadsFolder){
        $DownloadsFolder=Get-PCVRDownloadsFolder
    }
    if(-not $GameId){$GameId=(''+$env:PCVR_HUB_GAME_ID).Trim()}
    $catalogInfo=if($GameId){Get-PCVRRecoveryCatalogInfo -GameId $GameId -CoreRoot (Split-Path -Parent $PSScriptRoot)}else{$null}
    if(-not $RecoveryPageUrl -and $catalogInfo){$RecoveryPageUrl=$catalogInfo.PageUrl}
    $assetPatterns=@()
    if($catalogInfo -and $RecoveryPageUrl.StartsWith($catalogInfo.PageUrl,[StringComparison]::OrdinalIgnoreCase)){$assetPatterns=@($catalogInfo.AssetPatterns)}
    $read={param([string]$Prompt) if($ReadInput){& $ReadInput $Prompt}else{Read-Host $Prompt}}.GetNewClosure()
    $openFolder={
        param([string]$Path)
        if($OpenPath){& $OpenPath $Path|Out-Null}
        else{Start-Process explorer.exe -ArgumentList ('"'+$Path+'"') -ErrorAction Stop|Out-Null}
    }.GetNewClosure()
    $pageAvailable=[bool]($RecoveryPageUrl -match '^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/releases(?:/.*)?$')
    $downloadFailure=[bool]($FailureMessage -match '(?i)(?:could not be (?:resolved|downloaded|checked|verified|acquired)|download (?:failed|was not completed|did not complete)|(?:was|were) not downloaded|GitHub (?:unavailable|could not be reached)|current .*release .*not (?:found|resolved|verified|available)|No (?:current|usable|official) .* (?:release|publisher Setup) .* (?:found|available)|HTTP (?:403|404|429|5\d\d))')
    $suggestion=Get-PCVRRecoverySuggestion -GameId $GameId -FailureMessage $FailureMessage

    # Render the recovery page once per failed attempt. Reprinting it for an
    # empty Enter, a log/folder action, or a bad path filled the console with
    # identical pages while the installer was still waiting for input.
        Write-Host ''
        Write-Host '============================================================' -ForegroundColor Yellow
        Write-Host '  INSTALLER RECOVERY - nothing was marked complete' -ForegroundColor Yellow
        Write-Host '============================================================' -ForegroundColor Yellow
        Write-Host ''
        if($GameId -eq 'dead-space-2-vr' -and $FailureMessage -match '(?i)Close SteamVR before installing'){
            Write-Host '  CLOSE STEAMVR BEFORE INSTALLING  ' -ForegroundColor Black -BackgroundColor Yellow
            Write-Host '  Close the SteamVR application, then choose R below to retry.' -ForegroundColor Yellow
            Write-Host '  Steam itself can stay open.' -ForegroundColor Yellow
            Write-Host '  Start SteamVR again after installation, before playing in VR.' -ForegroundColor White
        }else{
            Write-Host ('  '+$FailureMessage) -ForegroundColor White
        }
        $current=Get-PCVRRecoveryInput
        if($current){Write-Host ('  Manual handover ready: '+$current) -ForegroundColor Cyan}
        Write-Host ''
        if($suggestion){Write-Host ('  [1] '+$suggestion.Label) -ForegroundColor Green}
        elseif($downloadFailure -and $pageAvailable){Write-Host '  [1] Open the official release page, then check Downloads' -ForegroundColor Green}
        Write-Host '  [R] Retry the complete installer in this window' -ForegroundColor Cyan
        if($pageAvailable){
            Write-Host '  [O] Open the current publisher release page' -ForegroundColor Cyan
        }
        Write-Host '  [D] Open Downloads, then drag a file or folder onto this window' -ForegroundColor Cyan
        Write-Host '  [L] Open the installer log' -ForegroundColor Cyan
        Write-Host '  [F] Open the installer folder' -ForegroundColor Cyan
        Write-Host '  [C] Clear the previous manual handover' -ForegroundColor Cyan
        Write-Host ''
        Write-Host '  Or drag/paste ANY downloaded file, game folder, install folder,' -ForegroundColor White
        Write-Host '  executable or archive path here. It is handed to the next retry.' -ForegroundColor White
        Write-Host '  If any recovery action fails, this screen stays open.' -ForegroundColor DarkGray
        Write-Host ''
    while($true){
        $answer=& $read '  Recovery choice or path'
        if($null -eq $answer -or (-not $ReadInput -and [Console]::IsInputRedirected -and (''+$answer).Length -eq 0)){
            throw [IO.EndOfStreamException]::new('Recovery needs interactive console input; no input was available.')
        }
        $raw=(''+$answer).Trim()
        $choice=$raw.ToUpperInvariant()
        try{
            if($choice -eq 'R'){
                return [pscustomobject]@{Action='retry';RecoveryInput=(Get-PCVRRecoveryInput);Source='retry'}
            }
            if($choice -eq '1' -and $suggestion){
                Write-Host ('  '+$suggestion.After) -ForegroundColor White
                if($LaunchGame){& $LaunchGame $suggestion.Url|Out-Null}
                else{Start-Process $suggestion.Url -ErrorAction Stop|Out-Null}
                if(-not $ReadInput){try{$Host.UI.RawUI.FlushInputBuffer()}catch{}}
                while($true){
                    $after=& $read '  When the step is complete, press Enter to retry setup'
                    if($null -eq $after){throw [IO.EndOfStreamException]::new('Recovery needs interactive console input.')}
                    if((''+$after).Length -eq 0){break}
                    Write-Host '  Complete the step, then press Enter without typing anything.' -ForegroundColor Yellow
                }
                return [pscustomobject]@{Action='retry';RecoveryInput=(Get-PCVRRecoveryInput);Source='first-run'}
            }
            if($choice -eq 'O' -and $pageAvailable){
                if($OpenPage){& $OpenPage $RecoveryPageUrl|Out-Null}
                else{Start-Process $RecoveryPageUrl -ErrorAction Stop|Out-Null}
                Write-Host '  Download the publisher file, then drag it here or paste its full path.' -ForegroundColor Cyan
                continue
            }
            if($choice -eq '1' -and $downloadFailure -and $pageAvailable){
                if($OpenPage){& $OpenPage $RecoveryPageUrl|Out-Null}
                else{Start-Process $RecoveryPageUrl -ErrorAction Stop|Out-Null}
                Write-Host '  Download the current publisher file on that page.' -ForegroundColor Cyan
                if(-not $ReadInput){try{$Host.UI.RawUI.FlushInputBuffer()}catch{}}
                $ready=& $read '  When the download is finished, press Enter to check Downloads'
                if($null -eq $ready){throw [IO.EndOfStreamException]::new('Recovery needs interactive console input.')}
                if((''+$ready).Length -ne 0){
                    Write-Host '  Press Enter without typing anything to check Downloads.' -ForegroundColor Yellow
                    continue
                }
                $choices=@(Get-PCVRRecoveryMatchingDownloads -DownloadsFolder $DownloadsFolder -AssetPatterns $assetPatterns)
                if($choices.Count -ne 1){
                    if($choices.Count -gt 1){Write-Host '  Several matching files are in Downloads. Drag/paste the current publisher file path here.' -ForegroundColor Yellow}
                    else{Write-Host '  No unambiguous matching file found in Downloads. Drag/paste the publisher file path here.' -ForegroundColor Yellow}
                    Write-Host '  Use O to open the release page again if needed.' -ForegroundColor Cyan
                    continue
                }
                $selected=$choices[0].FullName
                Write-Host ('  Found: '+$selected) -ForegroundColor Cyan
                $confirm=& $read '  Use this file for the next installer attempt? Y/N'
                if((''+$confirm).Trim() -match '^(?i:y|yes)$'){
                    $resolved=Set-PCVRRecoveryInput $selected
                    return [pscustomobject]@{Action='retry';RecoveryInput=$resolved;Source='download'}
                }
                Write-Host '  File not selected. Use O to reopen the page or drag/paste a path.' -ForegroundColor Yellow
                continue
            }
            if($choice -eq 'D'){
                if(-not(Test-Path -LiteralPath $DownloadsFolder -PathType Container -ErrorAction SilentlyContinue)){
                    [void][IO.Directory]::CreateDirectory($DownloadsFolder)
                }
                & $openFolder $DownloadsFolder
                Write-Host '  Downloads opened. Paste a file or folder path here when ready.' -ForegroundColor Cyan
                continue
            }
            if($choice -eq 'L'){
                if(-not $LogPath -or -not(Test-Path -LiteralPath $LogPath -PathType Leaf -ErrorAction SilentlyContinue)){
                    throw 'The installer log does not exist yet. Retry or provide a manual path.'
                }
                if($OpenLog){& $OpenLog $LogPath|Out-Null}else{Start-Process notepad.exe -ArgumentList ('"'+$LogPath+'"') -ErrorAction Stop|Out-Null}
                Write-Host '  Log opened. Enter R to retry or provide a path.' -ForegroundColor Cyan
                continue
            }
            if($choice -eq 'F'){
                if(-not $InstallerFolder -or -not(Test-Path -LiteralPath $InstallerFolder -PathType Container -ErrorAction SilentlyContinue)){
                    throw 'The installer folder is unavailable.'
                }
                & $openFolder $InstallerFolder
                Write-Host '  Installer folder opened. Enter R to retry or provide a path.' -ForegroundColor Cyan
                continue
            }
            if($choice -eq 'C'){
                [void](Set-PCVRRecoveryInput '')
                Write-Host '  [OK] Previous manual handover cleared.' -ForegroundColor Green
                continue
            }
            if($raw){
                $candidate=ConvertTo-PCVRCanonicalUserPath $raw
                if(Test-Path -LiteralPath $candidate -ErrorAction SilentlyContinue){
                    $resolved=Set-PCVRRecoveryInput $candidate
                    Write-Host ('  [OK] Manual handover accepted: '+$resolved) -ForegroundColor Green
                    return [pscustomobject]@{Action='retry';RecoveryInput=$resolved;Source='manual'}
                }
            }
            if($raw){Write-Host '  That is not an available recovery action or existing path.' -ForegroundColor Yellow}
            else{Write-Host '  Enter R to retry, or paste an existing file or folder path.' -ForegroundColor Yellow}
        }catch{
            if($_.Exception.GetBaseException() -is [IO.EndOfStreamException]){throw}
            Write-Host ('  Recovery action failed: '+$_.Exception.Message) -ForegroundColor Yellow
            Write-Host '  Nothing closed. Choose another action or provide a path.' -ForegroundColor DarkGray
        }
    }
}
