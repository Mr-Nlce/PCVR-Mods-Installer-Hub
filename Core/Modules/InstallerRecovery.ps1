# ============================================================
# PCVR Mods Hub - universal installer recovery
# ============================================================
# This module is loaded by the installer wrapper and by both installer helper
# generations. It owns the last recovery surface: any installer failure which
# was not resolved locally arrives here and remains recoverable in the same
# window. There is deliberately no error-screen Exit/Q action. Closing the
# console window is still a user-controlled Windows action, but the Hub never
# recommends abandoning an unresolved installer failure.

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
        return (ConvertTo-PCVRCanonicalUserInput (''+$answer))
    }
    Set-Item -LiteralPath Function:\global:Read-Host -Value $body -Force
}

function global:Invoke-PCVRUniversalRecovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$FailureMessage,
        [string]$LogPath='',
        [string]$InstallerFolder='',
        [string]$DownloadsFolder='',
        [scriptblock]$ReadInput=$null,
        [scriptblock]$OpenLog=$null,
        [scriptblock]$OpenPath=$null
    )
    if(-not $DownloadsFolder){
        $DownloadsFolder=[IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'),'Downloads')
    }
    $read={param([string]$Prompt) if($ReadInput){& $ReadInput $Prompt}else{Read-Host $Prompt}}.GetNewClosure()
    $openFolder={
        param([string]$Path)
        if($OpenPath){& $OpenPath $Path|Out-Null}
        else{Start-Process explorer.exe -ArgumentList ('"'+$Path+'"') -ErrorAction Stop|Out-Null}
    }.GetNewClosure()

    while($true){
        Write-Host ''
        Write-Host '============================================================' -ForegroundColor Yellow
        Write-Host '  INSTALLER RECOVERY - nothing was marked complete' -ForegroundColor Yellow
        Write-Host '============================================================' -ForegroundColor Yellow
        Write-Host ''
        Write-Host ('  '+$FailureMessage) -ForegroundColor White
        $current=Get-PCVRRecoveryInput
        if($current){Write-Host ('  Manual handover ready: '+$current) -ForegroundColor Cyan}
        Write-Host ''
        Write-Host '  [R] Retry the complete installer in this window' -ForegroundColor Cyan
        Write-Host '  [D] Open Downloads, then drag a file or folder onto this window' -ForegroundColor Cyan
        Write-Host '  [L] Open the installer log' -ForegroundColor Cyan
        Write-Host '  [F] Open the installer folder' -ForegroundColor Cyan
        Write-Host '  [C] Clear the previous manual handover' -ForegroundColor Cyan
        Write-Host ''
        Write-Host '  Or drag/paste ANY downloaded file, game folder, install folder,' -ForegroundColor White
        Write-Host '  executable or archive path here. It is handed to the next retry.' -ForegroundColor White
        Write-Host '  If any recovery action fails, this screen stays open.' -ForegroundColor DarkGray
        Write-Host ''
        $raw=(''+(& $read '  Recovery choice or path')).Trim()
        $choice=$raw.ToUpperInvariant()
        try{
            if($choice -eq 'R'){
                return [pscustomobject]@{Action='retry';RecoveryInput=(Get-PCVRRecoveryInput);Source='retry'}
            }
            if($choice -eq 'D'){
                if(-not(Test-Path -LiteralPath $DownloadsFolder -PathType Container -ErrorAction SilentlyContinue)){
                    [void][IO.Directory]::CreateDirectory($DownloadsFolder)
                }
                & $openFolder $DownloadsFolder
                continue
            }
            if($choice -eq 'L'){
                if(-not $LogPath -or -not(Test-Path -LiteralPath $LogPath -PathType Leaf -ErrorAction SilentlyContinue)){
                    throw 'The installer log does not exist yet. Retry or provide a manual path.'
                }
                if($OpenLog){& $OpenLog $LogPath|Out-Null}else{Start-Process notepad.exe -ArgumentList ('"'+$LogPath+'"') -ErrorAction Stop|Out-Null}
                continue
            }
            if($choice -eq 'F'){
                if(-not $InstallerFolder -or -not(Test-Path -LiteralPath $InstallerFolder -PathType Container -ErrorAction SilentlyContinue)){
                    throw 'The installer folder is unavailable.'
                }
                & $openFolder $InstallerFolder
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
            Write-Host '  That is not an available recovery action or existing path.' -ForegroundColor Yellow
        }catch{
            Write-Host ('  Recovery action failed: '+$_.Exception.Message) -ForegroundColor Yellow
            Write-Host '  Nothing closed. Choose another action or provide a path.' -ForegroundColor DarkGray
        }
    }
}
