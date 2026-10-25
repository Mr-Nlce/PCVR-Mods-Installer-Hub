# Shared diagnostic lifecycle for release-candidate installers. This observes
# files; installation, rollback and success evidence remain owned by Foundation.
$script:PCVRTestReportModuleRoot = $PSScriptRoot

function global:ConvertTo-PCVRTestReportSafeText {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return '' }
    $safe = $Text
    $pairs = @(@($env:LOCALAPPDATA,'%LOCALAPPDATA%'),@($env:APPDATA,'%APPDATA%'),
        @($env:TEMP,'%TEMP%'),@($env:USERPROFILE,'%USERPROFILE%'))
    foreach ($pair in @($pairs | Sort-Object { ([string]$_[0]).Length } -Descending)) {
        $value = [string]$pair[0]
        if ($value.Length -gt 3) { $safe = [regex]::Replace($safe,[regex]::Escape($value.TrimEnd([char[]]'\/')),[string]$pair[1],'IgnoreCase') }
    }
    foreach ($pair in @(@($env:USERNAME,'%USERNAME%'),@($env:COMPUTERNAME,'%COMPUTERNAME%'),@($env:USERDOMAIN,'%USERDOMAIN%'))) {
        if ($pair[0]) { $safe = [regex]::Replace($safe,('(?<![\p{L}\p{N}_])'+[regex]::Escape([string]$pair[0])+'(?![\p{L}\p{N}_])'),[string]$pair[1],'IgnoreCase') }
    }
    return $safe
}

function global:Get-PCVRTestReportFileName {
    param([Parameter(Mandatory=$true)][string]$GameTitle)
    $slug = [regex]::Replace($GameTitle.ToLowerInvariant(),'[^a-z0-9]+','-').Trim('-')
    if (-not $slug) { $slug = 'game' }
    return ($slug + '-test-result.txt')
}

function global:Get-PCVRTestReportFolder {
    param([switch]$NoCreate)
    if ($env:PCVR_HUB_TEST_MODE -eq '1') {
        if (-not $env:PCVR_TEST_REPORT_DIR) { throw 'An isolated report folder is required for test reports.' }
        $folder = [IO.Path]::GetFullPath($env:PCVR_TEST_REPORT_DIR)
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
        if (-not $folder.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase)) { throw 'Test reports must stay inside the temporary fixture.' }
    } else { $folder = Join-Path (Split-Path -Parent $script:PCVRTestReportModuleRoot) 'Logs\Untested' }
    if (-not $NoCreate) { [void][IO.Directory]::CreateDirectory($folder) }
    return $folder
}

function global:Get-PCVRFolderSnapshot {
    param([Parameter(Mandatory=$true)][string]$Root)
    $full = [IO.Path]::GetFullPath($Root).TrimEnd([char[]]'\/')
    $files = @{}; $notes = [Collections.Generic.List[string]]::new()
    $queue = [Collections.Generic.Queue[string]]::new()
    $exists = [IO.Directory]::Exists($full)
    $hashBytes = 0L
    if ($exists) { $queue.Enqueue($full) }
    while ($queue.Count) {
        $dir = $queue.Dequeue()
        try { $items = [IO.DirectoryInfo]::new($dir).GetFileSystemInfos() }
        catch { $notes.Add('Unreadable folder: '+$dir); continue }
        foreach ($item in $items) {
            if ($files.Count -ge 100000) { $notes.Add('Inventory limit reached (100000 files); this inventory is incomplete.'); $queue.Clear(); break }
            $relative = $item.FullName.Substring($full.Length).TrimStart([char[]]'\/')
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                $notes.Add('Link not followed: '+$relative); continue
            }
            if ($item -is [IO.DirectoryInfo]) { $queue.Enqueue($item.FullName); continue }
            $hash = ''
            # Avoid rereading multi-GB game archives. Small-file fingerprints
            # supplement size/mtime, with a bounded 16 MB read budget per root.
            if ($item.Length -le 64KB -and $hashBytes + $item.Length -le 16MB) {
                try { $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256 -ErrorAction Stop).Hash; $hashBytes += $item.Length }
                catch { $notes.Add('Unreadable file: '+$relative) }
            }
            $files[$relative.ToLowerInvariant()] = [pscustomobject]@{
                Path=$relative; Length=[int64]$item.Length; WriteUtc=$item.LastWriteTimeUtc; Hash=$hash
            }
        }
    }
    return [pscustomobject]@{Root=$full; Exists=$exists; Files=$files; Notes=@($notes); TakenUtc=[DateTime]::UtcNow}
}

function global:Compare-PCVRFolderSnapshot {
    param([Parameter(Mandatory=$true)]$Before,[Parameter(Mandatory=$true)]$After)
    $added=[Collections.Generic.List[object]]::new(); $changed=[Collections.Generic.List[object]]::new(); $removed=[Collections.Generic.List[object]]::new()
    foreach ($key in $After.Files.Keys) {
        $now=$After.Files[$key]
        if (-not $Before.Files.ContainsKey($key)) { $added.Add($now); continue }
        $old=$Before.Files[$key]
        if ($old.Length -ne $now.Length -or $old.WriteUtc -ne $now.WriteUtc -or ($old.Hash -and $now.Hash -and $old.Hash -ne $now.Hash)) {
            $changed.Add([pscustomobject]@{Path=$now.Path; OldLength=$old.Length; Length=$now.Length})
        }
    }
    foreach ($key in $Before.Files.Keys) { if (-not $After.Files.ContainsKey($key)) { $removed.Add($Before.Files[$key]) } }
    return [pscustomobject]@{Added=@($added|Sort-Object Path);Changed=@($changed|Sort-Object Path);Removed=@($removed|Sort-Object Path)}
}

function global:Start-PCVRInstallerTestReport {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$InstallerId,
          [Parameter(Mandatory=$true)][string]$GameTitle,
          [Parameter(Mandatory=$true)][string]$ModName,
          [string]$FileStem='', [string]$InstallerFolder='')
    if ($FileStem -and $FileStem -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') { throw 'Invalid report file stem.' }
    # Establish report storage before the installer can alter the game.
    # A read-only Hub must fail here, rather than leave a candidate installed
    # without the evidence needed by its feedback button.
    $folder=Get-PCVRTestReportFolder
    $probe=Join-Path $folder ('.write-probe-'+[guid]::NewGuid().ToString('N'))
    $probeStream=$null
    try{$probeStream=[IO.File]::Open($probe,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)}
    finally{if($probeStream){$probeStream.Dispose()};if([IO.File]::Exists($probe)){[IO.File]::Delete($probe)}}
    $session=[pscustomobject]@{
        InstallerId=$InstallerId;GameTitle=$GameTitle;ModName=$ModName;FileStem=$FileStem
        GameDir='';Route='';ModVersion='';HubVersion='unknown';StartedUtc=[DateTime]::UtcNow
        Targets=[Collections.Generic.List[object]]::new();TranscriptPath='';OwnTranscript=$false
        Completed=$false;ReportPath='';LogNotice=''
    }
    if ($InstallerFolder) {
        try { $session.HubVersion=[IO.File]::ReadAllText((Join-Path $InstallerFolder '..\version.txt')).Trim() } catch {}
    }
    # Reuse the wrapper's live child-runspace transcript. Never stop it, start
    # nested transcripts or wait for the wrapper's post-exit log compaction.
    $live = Get-Variable -Name PCVRInstallerLiveLogPath -Scope Global -ErrorAction SilentlyContinue
    if ($live -and $live.Value) { $session.TranscriptPath=[string]$live.Value }
    else {
        $session.TranscriptPath=Join-Path ([IO.Path]::GetTempPath()) ('pcvr-tester-'+[guid]::NewGuid().ToString('N')+'.log')
        try { [void](Start-Transcript -LiteralPath $session.TranscriptPath -ErrorAction Stop);$session.OwnTranscript=$true }
        catch { $session.LogNotice='The installer transcript could not be started: '+$_.Exception.Message }
    }
    return $session
}

function global:Add-PCVRInstallerTestReportTarget {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Session,[Parameter(Mandatory=$true)][string]$Path,
          [string]$Role='VR mod files',[string]$GameDir='',[string]$Route='')
    if ($Session.Completed) { throw 'The test report is already complete.' }
    $full=[IO.Path]::GetFullPath($Path).TrimEnd([char[]]'\/')
    # Do not accidentally inventory a whole drive or an entire user profile.
    $forbidden=@([IO.Path]::GetPathRoot($full),$env:USERPROFILE,$env:LOCALAPPDATA,$env:APPDATA,[IO.Path]::GetTempPath())
    foreach($base in $forbidden){if($base -and $full -ieq $base.TrimEnd([char[]]'\/')){throw 'Test report targets must be specific game or VR mod folders.'}}
    if ($Session.Targets | Where-Object Path -eq $full) { return }
    if ($GameDir) { $Session.GameDir=[IO.Path]::GetFullPath($GameDir) }
    if ($Route) { $Session.Route=$Route }
    Write-Host ('  Recording the existing files in '+$full+'; this may take a few seconds.') -ForegroundColor Gray
    $before=Get-PCVRFolderSnapshot -Root $full
    $Session.Targets.Add([pscustomobject]@{Path=$full;Role=$Role;Before=$before})
    Write-Host ('  [OK] Before installation: '+$before.Files.Count+' files recorded.') -ForegroundColor Green
}

function global:Read-PCVRTestReportTranscript {
    param([string]$Path)
    if (-not $Path -or -not [IO.File]::Exists($Path)) { return '(Installer log unavailable.)' }
    $stream=$null;$reader=$null
    try {
        $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
        $truncated=$stream.Length -gt 8MB
        if($truncated){[void]$stream.Seek(-8MB,[IO.SeekOrigin]::End)}
        $reader=[IO.StreamReader]::new($stream,[Text.UTF8Encoding]::new($false),$true)
        if($truncated){[void]$reader.ReadLine()}
        $result=[Text.StringBuilder]::new();$block=$false
        if($truncated){[void]$result.AppendLine('(Installer log exceeded 8 MB; showing its latest 8 MB.)')}
        while($null -ne ($line=$reader.ReadLine())) {
            if($line.Trim() -match '^\*{10,}$'){$block=-not $block;continue}
            if($block){continue}
            [void]$result.AppendLine($line)
        }
        return $result.ToString()
    } catch { return '(Installer log could not be read: '+$_.Exception.Message+')' }
    finally {if($reader){$reader.Dispose()}elseif($stream){$stream.Dispose()}}
}

function global:Complete-PCVRInstallerTestReport {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Session,
          [Parameter(Mandatory=$true)][ValidateSet('Success','Failed','Cancelled')][string]$Outcome,
          [string]$FailureMessage='',[string]$ModVersion='')
    if($Session.Completed){return $Session.ReportPath}
    if($Session.OwnTranscript){[void](Stop-Transcript -ErrorAction SilentlyContinue);$Session.OwnTranscript=$false}
    $Session.ModVersion=$ModVersion
    $text=[Text.StringBuilder]::new()
    $limits=@{Inventory=$false;Truncated=$false}
    $line={
        param([string]$Value)
        if($limits.Inventory -and $text.Length -gt 12MB){
            if(-not $limits.Truncated){[void]$text.AppendLine('INVENTORY OUTPUT LIMIT REACHED: remaining inventory lines omitted; log follows.');$limits.Truncated=$true}
            return
        }
        [void]$text.AppendLine($Value)
    }
    & $line 'PCVR MODS HUB - UNTESTED INSTALLER TEST RESULT'
    & $line ('Game: '+$Session.GameTitle)
    & $line ('VR mod: '+$Session.ModName+' '+$ModVersion)
    & $line ('Installer ID: '+$Session.InstallerId)
    & $line ('Hub version: '+$Session.HubVersion)
    & $line ('Started (UTC): '+$Session.StartedUtc.ToString('o'))
    & $line ('Installer result: '+$Outcome.ToUpperInvariant())
    & $line 'This is an installer result. VR gameplay still needs the tester feedback below.'
    if($FailureMessage){& $line ('Error: '+$FailureMessage)}
    & $line ('Game folder: '+$Session.GameDir)
    & $line ('Store / route: '+$Session.Route)
    & $line ('Windows: '+[Environment]::OSVersion.VersionString)
    & $line ('PowerShell: '+$PSVersionTable.PSVersion)
    & $line ''
    & $line 'TESTER FEEDBACK (fill in before sharing)'
    & $line 'Headset and connection / OpenXR runtime:'
    & $line 'Did Start in VR work?'
    & $line 'Head tracking and controls:'
    & $line 'Time played and problems / steps to reproduce:'
    & $line 'Overall result (works / works with issues / does not work):'
    & $line ''
    & $line 'FILE INVENTORIES AND CHANGES'
    $limits.Inventory=$true
    & $line 'No file contents are included. Differences use file size, UTC modification time and bounded small-file hashes.'
    if(-not $Session.Targets.Count){& $line 'No destination was established; installation stopped before a target could be scanned.'}
    foreach($target in $Session.Targets){
        $after=Get-PCVRFolderSnapshot -Root $target.Path
        $diff=Compare-PCVRFolderSnapshot -Before $target.Before -After $after
        & $line ('TARGET: '+$target.Role+' | '+$target.Path)
        & $line ('Before: '+$target.Before.Files.Count+' files; after: '+$after.Files.Count+' files')
        & $line 'DIFFERENCES (+ added, ~ changed, - removed)'
        foreach($file in $diff.Added){& $line ('+ '+$file.Path+' ['+$file.Length+' bytes]')}
        foreach($file in $diff.Changed){& $line ('~ '+$file.Path+' ['+$file.OldLength+' -> '+$file.Length+' bytes]')}
        foreach($file in $diff.Removed){& $line ('- '+$file.Path+' ['+$file.Length+' bytes]')}
        foreach($pair in @(@('BEFORE',$target.Before),@('AFTER',$after))){
            & $line ('ALL FILES '+$pair[0]+' INSTALL')
            if(-not $pair[1].Exists){& $line '(folder did not exist at this checkpoint)'}
            foreach($file in @($pair[1].Files.Values|Sort-Object Path)){
                & $line ($file.Path+' | '+$file.Length+' bytes | '+$file.WriteUtc.ToString('o')+$(if($file.Hash){' | sha256 '+$file.Hash}else{''}))
            }
            foreach($note in $pair[1].Notes){& $line ('Inventory note: '+$note)}
        }
        & $line ''
    }
    $limits.Inventory=$false
    & $line 'INSTALLER LOG (through this report checkpoint)'
    if($Session.LogNotice){& $line $Session.LogNotice}
    & $line (Read-PCVRTestReportTranscript -Path $Session.TranscriptPath)
    $safe=ConvertTo-PCVRTestReportSafeText -Text $text.ToString()
    $folder=Get-PCVRTestReportFolder
    $name=if($Session.FileStem){$Session.FileStem+'-test-result.txt'}else{Get-PCVRTestReportFileName $Session.GameTitle}
    $base=[IO.Path]::GetFileNameWithoutExtension($name);$number=1
    # CreateNew prevents retries from replacing a tester's annotated report.
    while($true){
        $leaf=if($number -eq 1){$name}else{$base+'-'+$number+'.txt'}
        $path=Join-Path $folder $leaf
        try{$output=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);break}
        catch [IO.IOException]{if([IO.File]::Exists($path)){$number++;continue};throw}
    }
    try{$writer=[IO.StreamWriter]::new($output,[Text.UTF8Encoding]::new($true));$writer.Write($safe)}
    finally{if($writer){$writer.Dispose()}else{$output.Dispose()}}
    $Session.Completed=$true;$Session.ReportPath=$path
    if($Session.TranscriptPath -and -not (Get-Variable PCVRInstallerLiveLogPath -Scope Global -ErrorAction SilentlyContinue)){
        Remove-Item -LiteralPath $Session.TranscriptPath -Force -ErrorAction SilentlyContinue
    }
    return $path
}

function global:Test-PCVRUntestedInstaller {
    param([string]$InstallerId,[string]$CatalogPath='')
    if(-not $InstallerId){return $false}
    if(-not $CatalogPath){$CatalogPath=Join-Path $script:PCVRTestReportModuleRoot 'Catalog.ps1'}
    if(-not [IO.File]::Exists($CatalogPath)){return $false}
    try {
        $candidate=& {
            param($Path,$Id)
            . $Path
            @(@($ownGames)+@($ownGamesGP)+@($externalGames))|Where-Object Id -eq $Id|Select-Object -First 1
        } $CatalogPath $InstallerId
        return [bool]($candidate -and $candidate.UntestedInstaller)
    }catch{return $false}
}

function global:Show-PCVRUntestedThanks {
    param([string]$InstallerId)
    if(Test-PCVRUntestedInstaller -InstallerId $InstallerId){
        Write-Host '  Thanks for testing! Your support is appreciated!' -ForegroundColor Yellow
    }
}

function global:Show-PCVRInstallerTestReportResult {
    param([Parameter(Mandatory=$true)][string]$ReportPath)
    Write-Host ''
    Write-Host '  TEST RESULT SAVED IN HUB: Core\Logs\Untested' -ForegroundColor Cyan
    Write-Host ('  '+[IO.Path]::GetFileName($ReportPath)) -ForegroundColor White
    Write-Host '  Contains file lists before/after installation and the installer log.' -ForegroundColor Gray
    Write-Host '  Play a few minutes in VR, then use Provide feedback in the Hub.' -ForegroundColor White
    Write-Host '  It opens the GitHub form and this folder. Drag the TXT into Installer log.' -ForegroundColor Gray
    Write-Host '  Review the report for private information before sharing.' -ForegroundColor Gray
    # The current catalog flag is the approval authority. A saved report never
    # keeps tester-only gratitude active after a title is promoted.
    $reader=$null
    try {
        $reader=[IO.StreamReader]::new($ReportPath,[Text.Encoding]::UTF8,$true)
        $id='';$outcome=''
        for($i=0;$i -lt 12 -and -not $reader.EndOfStream;$i++){
            $line=$reader.ReadLine()
            if($line.StartsWith('Installer ID: ')){$id=$line.Substring(14)}
            if($line.StartsWith('Installer result: ')){$outcome=$line.Substring(18)}
        }
        if($outcome -eq 'SUCCESS'){Show-PCVRUntestedThanks -InstallerId $id}
    }finally{if($reader){$reader.Dispose()}}
}
