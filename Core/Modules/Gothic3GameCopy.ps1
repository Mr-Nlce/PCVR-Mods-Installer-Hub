# Keep the publisher's patch target separate from the original game.
function ConvertTo-Gothic3Folder([string]$InputPath,[switch]$AllowGameExe) {
    $path = [Environment]::ExpandEnvironmentVariables($InputPath.Trim().Trim('"').Trim("'"))
    if ($path -notmatch '^(?:[A-Za-z]:[\\/]|\\\\[^?.\\][^\\]*\\[^\\]+\\)') {
        throw 'Enter a full game folder path.'
    }
    $path = [IO.Path]::GetFullPath($path).TrimEnd([char[]]'\/')
    if ($AllowGameExe -and [IO.File]::Exists($path) -and [IO.Path]::GetFileName($path) -ieq 'Gothic3.exe') {
        $path = [IO.Path]::GetDirectoryName($path)
    }
    if (-not $path -or -not [IO.Path]::GetDirectoryName($path)) { throw 'Choose a game folder below the drive or share root.' }
    return $path
}

function Assert-Gothic3OrdinaryPaths([string]$Root,[switch]$IncludeContents) {
    $path = $Root
    while ($path) {
        if (([IO.Directory]::Exists($path) -or [IO.File]::Exists($path)) -and
            ([IO.File]::GetAttributes($path) -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Choose a physical folder. This path contains a junction or link: $path"
        }
        $path = [IO.Path]::GetDirectoryName($path)
    }
    if (-not $IncludeContents) { return }
    $pending = [Collections.Generic.Stack[string]]::new()
    $pending.Push($Root)
    while ($pending.Count) {
        foreach ($entry in [IO.Directory]::EnumerateFileSystemEntries($pending.Pop())) {
            $attributes = [IO.File]::GetAttributes($entry)
            if ($attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Use a game folder without linked files or directories: $entry"
            }
            if ($attributes -band [IO.FileAttributes]::Directory) { $pending.Push($entry) }
        }
    }
}

function Assert-Gothic3SeparateFolder([string]$Target,[string]$Original) {
    if ($Target -match '(?i)[\\/]steamapps[\\/]common(?:[\\/]|$)|[\\/](?:GOG Games|GOG Galaxy[\\/]Games)[\\/]Gothic 3(?:[\\/]|$)' -or
        ($Original -and ($Target -ieq $Original -or
            $Target.StartsWith($Original + '\',[StringComparison]::OrdinalIgnoreCase) -or
            $Original.StartsWith($Target + '\',[StringComparison]::OrdinalIgnoreCase)))) {
        throw 'Choose a separate folder outside the original game and the Steam library.'
    }
    Assert-Gothic3OrdinaryPaths $Target
}

function Copy-Gothic3BaseGame($Game,[string]$Original,[string]$Target) {
    Assert-Gothic3SeparateFolder $Target $Original
    if ([IO.File]::Exists($Target) -or
        ([IO.Directory]::Exists($Target) -and [IO.Directory]::GetFileSystemEntries($Target).Count)) {
        throw 'Choose a new or empty destination. Use option 2 if you already have a copy.'
    }
    if (Get-Process -Name $Game.Processes -ErrorAction SilentlyContinue) {
        throw 'Close Gothic 3 and its VR launcher before copying the game.'
    }
    Assert-Gothic3OrdinaryPaths $Original -IncludeContents
    $parent = [IO.Path]::GetDirectoryName($Target)
    $stage = [IO.Path]::Combine($parent,('.pcvr-gothic-copy-' + [guid]::NewGuid().ToString('N')))
    if (-not (Test-InstallerTargetWritable -TargetPath $stage)) { throw 'The copy destination is not writable.' }
    [void][IO.Directory]::CreateDirectory($stage)
    try {
        Write-Host '  Copying Gothic 3. This can take a few minutes.' -ForegroundColor Cyan
        $PSNativeCommandUseErrorActionPreference = $false
        $previousNativeExit = $global:LASTEXITCODE
        try {
            & robocopy.exe $Original $stage /E /COPY:DAT /DCOPY:DAT /XJ /R:1 /W:1 /NFL /NDL /NP /NJH /XF '.pcvrhub_*' | ForEach-Object {
                if ($_ -and $_.Trim()) { Write-Host $_ }
            }
            $code = $LASTEXITCODE
        } finally {
            # Robocopy reports a successful copy as 1. Its result belongs to
            # this step; the wrapper reads LASTEXITCODE as the whole core's exit.
            $global:LASTEXITCODE = $previousNativeExit
        }
        if ($code -ge 8 -or -not (Test-PCVRGameInstallProof -GameId $Game.Id -Root $stage)) {
            throw "The Gothic 3 copy could not be verified (Robocopy code $code). Check available space and access, then retry."
        }
        Assert-Gothic3OrdinaryPaths $stage -IncludeContents
        Assert-Gothic3SeparateFolder $Target $Original
        if ([IO.Directory]::Exists($Target)) { [IO.Directory]::Delete($Target,$false) }
        [IO.Directory]::Move($stage,$Target)
    } finally {
        if ([IO.Directory]::Exists($stage) -and [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($stage)) -ieq $parent) {
            Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "  Verified Gothic 3 copy: $Target" -ForegroundColor Green
}

function Select-Gothic3PublisherFolder($Game) {
    $original = Find-SteamGameFolder -AppId $Game.App -SteamFolderNames @($Game.SteamFolder) -GogNames $Game.GogNames -ProbeExe $Game.Base[0] -HubGameId $Game.Id -SkipRemembered
    if ($original) {
        $original = ConvertTo-Gothic3Folder $original
        if (Get-PCVRGothic3Version $original) { $original = $null }
    }
    $standard = 'C:\Games\Gothic 3 VR'
    $depotParent = Get-PCVRLastCustomDepotParent
    $suggested = if ($depotParent) { [IO.Path]::Combine($depotParent,'Gothic 3 VR') } else { $standard }
    $prepared = Get-PCVRRememberedGameFolder -GameId $Game.Id -StateNames @('gothic_copy_path') -ProbeFiles $Game.Base
    $saved = Get-PCVRRememberedGameFolder -GameId $Game.Id -StateNames @('installed_path','user_located') -ProbeFiles $Game.Base
    $handover = Get-PCVRRecoveryInput
    $gameHandover = $handover -and ([IO.Directory]::Exists($handover) -or [IO.Path]::GetFileName($handover) -ieq 'Gothic3.exe')
    $existing = $null
    $candidates = @($prepared,$saved,$suggested,$standard)
    if ($gameHandover) { $candidates = @($handover) + $candidates }
    foreach ($candidate in $candidates | Where-Object { $_ } | Select-Object -Unique) {
        try {
            $path = ConvertTo-Gothic3Folder $candidate -AllowGameExe
            Assert-Gothic3SeparateFolder $path $original
            if (Test-PCVRGameInstallProof -GameId $Game.Id -Root $path) { $existing = $path; break }
        } catch { }
    }

    :chooseFolder while ($true) {
        if ($original) { Write-Host "  Original Gothic 3 found: $original" -ForegroundColor Cyan }
        Write-Host '  [1] Copy the original game into a separate VR folder'
        Write-Host '  [2] Use an existing copy by dropping or pasting Gothic3.exe'
        Write-Host '  [Q] Cancel'
        $default = if ($existing) { '2' } else { '1' }
        $choice = Read-Host "  Choose 1 or 2 [Enter = $default]"
        if ($null -eq $choice -or $choice.Trim() -ieq 'Q') { return }
        if (-not $choice.Trim()) { $choice = $default }
        try {
            switch ($choice.Trim()) {
                '1' {
                    $source = $original
                    if (-not $source) {
                        $inputPath = Read-Host '  Drop or paste the original Gothic3.exe (Q returns to the menu)'
                        if (-not $inputPath -or $inputPath.Trim() -ieq 'Q') { continue chooseFolder }
                        $source = ConvertTo-Gothic3Folder $inputPath -AllowGameExe
                    }
                    if (-not (Test-PCVRGameInstallProof -GameId $Game.Id -Root $source) -or (Get-PCVRGothic3Version $source)) {
                        throw 'Choose the original Gothic 3 Classic game folder with its game data.'
                    }
                    Write-Host "  Default VR folder: $standard" -ForegroundColor Gray
                    if ($depotParent) { Write-Host "  Your previous depot location: $suggested" -ForegroundColor Cyan }
                    $destination = Read-Host "  Enter keeps $suggested, or type a full destination path (Q returns)"
                    if ($null -eq $destination -or $destination.Trim() -ieq 'Q') { continue chooseFolder }
                    $target = if ($destination.Trim()) { ConvertTo-Gothic3Folder $destination } else { ConvertTo-Gothic3Folder $suggested }
                    Assert-Gothic3SeparateFolder $target $source
                    Write-Host "  Copy from: $source"
                    Write-Host "  Copy to:   $target"
                    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to copy Gothic 3 to this folder...')
                    Copy-Gothic3BaseGame $Game $source $target
                }
                '2' {
                    $prompt = if ($existing) { "  Enter keeps $existing, or drop/paste another Gothic3.exe (Q returns)" }
                              else { '  Drop or paste Gothic3.exe from the separate copy (Q returns)' }
                    $inputPath = Read-Host $prompt
                    if ($null -eq $inputPath -or $inputPath.Trim() -ieq 'Q' -or (-not $inputPath.Trim() -and -not $existing)) { continue chooseFolder }
                    $target = if ($inputPath.Trim()) { ConvertTo-Gothic3Folder $inputPath -AllowGameExe } else { $existing }
                    Assert-Gothic3SeparateFolder $target $original
                    if (-not (Test-PCVRGameInstallProof -GameId $Game.Id -Root $target)) {
                        throw 'The separate copy needs Gothic3.exe and the original game data.'
                    }
                    Assert-Gothic3OrdinaryPaths $target -IncludeContents
                }
                default { continue chooseFolder }
            }
            if ($gameHandover) { [void](Set-PCVRRecoveryInput '') }
            [void](Save-HubRememberedGameFolder -GameId $Game.Id -Title $Game.Title -GameDir $target -ProbeFiles $Game.Base -StateName 'gothic_copy_path')
            return $target
        } catch {
            Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}
