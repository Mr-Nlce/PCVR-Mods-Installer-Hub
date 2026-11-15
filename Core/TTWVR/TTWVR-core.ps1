param([ValidateSet('NewVegas','Wastelands')][string]$Mode = 'Wastelands')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot '..\Modules\OwnedModFiles.ps1')
. (Join-Path $PSScriptRoot '..\Modules\PublisherZipTransaction.ps1')
. (Join-Path $PSScriptRoot 'TTWVR-State.ps1')

$script:TTWInvite = 'https://discord.gg/TrJyyZEds'
$script:TTWChannel = 'https://discord.com/channels/1570233209462194208/1570238629832564858'
$script:TTWPublisher = 'https://mod.pub/ttw/133/files'
$script:TTWConverterProof = @('TTW Install.exe','*.mpi')
$script:TTWConvertedMasters = @($script:TTWRequirements.TTW | Where-Object { $_ -ine 'YUPTTW.esm' })
$script:TTWConvertedFiles = $script:TTWConvertedMasters + @(
    'TaleOfTwoWastelands - Main.bsa','TaleOfTwoWastelands - Textures.bsa',
    'Fallout3 - Meshes.bsa','Fallout3 - Sound.bsa','Fallout3 - Textures.bsa'
)
$script:TTWYupProof = @('YUPTTW.esm') + @($script:TTWRequirements.TTWData)
$script:TTWFallout3Depot = @{ AppId='22370'; DepotId='22371'; ManifestId='2416786561786063548' }
$script:TTWDataArchives = @{
    NewVegas = @(
        'Update.bsa','Fallout - Meshes.bsa','Fallout - Misc.bsa','Fallout - Sound.bsa',
        'Fallout - Textures.bsa','Fallout - Textures2.bsa','Fallout - Voices1.bsa',
        'CaravanPack - Main.bsa','ClassicPack - Main.bsa','MercenaryPack - Main.bsa','TribalPack - Main.bsa',
        'DeadMoney - Main.bsa','DeadMoney - Sounds.bsa','HonestHearts - Main.bsa','HonestHearts - Sounds.bsa',
        'OldWorldBlues - Main.bsa','OldWorldBlues - Sounds.bsa','LonesomeRoad - Main.bsa','LonesomeRoad - Sounds.bsa',
        'GunRunnersArsenal - Main.bsa','GunRunnersArsenal - Sounds.bsa'
    )
    Fallout3 = @(
        'Fallout - Meshes.bsa','Fallout - Misc.bsa','Fallout - Sound.bsa','Fallout - Textures.bsa',
        'Fallout - MenuVoices.bsa','Fallout - Voices.bsa',
        'Anchorage - Main.bsa','Anchorage - Sounds.bsa','ThePitt - Main.bsa','ThePitt - Sounds.bsa',
        'BrokenSteel - Main.bsa','BrokenSteel - Sounds.bsa','PointLookout - Main.bsa','PointLookout - Sounds.bsa',
        'Zeta - Main.bsa','Zeta - Sounds.bsa'
    )
}

function Test-TTWProtectedGameFolder([string]$Path) {
    if (-not $Path) { return $false }
    $resolved = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    foreach ($root in @($env:ProgramFiles,${env:ProgramFiles(x86)},$env:ProgramW6432,$env:SystemRoot)) {
        if ($root -and ($resolved -ieq $root.TrimEnd('\') -or $resolved.StartsWith($root.TrimEnd('\') + '\',[StringComparison]::OrdinalIgnoreCase))) { return $true }
    }
    return $resolved -match '^[A-Za-z]:\\Program Files(?: \(x86\))?(?:\\|$)'
}

function Get-TTWConverterInputFiles([string]$Kind) {
    @($script:TTWRequirements.$Kind) + @($script:TTWDataArchives[$Kind] | ForEach-Object { 'Data/' + $_ }) | Select-Object -Unique
}

function Get-TTWMissingSourceFiles([string]$Root,[string[]]$Required) {
    foreach ($file in $Required) {
        if (-not $Root) { $file; continue }
        $path = Join-Path $Root $file
        if (-not [IO.File]::Exists($path) -or [IO.FileInfo]::new($path).Length -eq 0) { $file }
    }
}

function Get-TTWLooseGameFiles([string]$Root) {
    $base = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    $stockFolders = [ordered]@{
        'Data/Music' = @('.mp3')
        'Data/Shaders' = @('.sdp')
        'Data/Sound/songs' = @('.mp3')
        'Data/Video' = @('.bik')
    }
    foreach ($relative in $stockFolders.Keys) {
        $folder = Join-Path $base $relative
        if (-not [IO.Directory]::Exists($folder) -or ([IO.File]::GetAttributes($folder) -band [IO.FileAttributes]::ReparsePoint)) { continue }
        $folders = [Collections.Generic.Stack[string]]::new()
        $folders.Push($folder)
        while ($folders.Count) {
            foreach ($item in Get-ChildItem -LiteralPath $folders.Pop() -Attributes '!ReparsePoint') {
                if ($item.PSIsContainer) { $folders.Push($item.FullName) }
                elseif ($item.Length -gt 0 -and $item.Extension -in $stockFolders[$relative]) {
                    $item.FullName.Substring($base.Length+1).Replace('\','/')
                }
            }
        }
    }
}

function Get-TTWSourceIssue([string]$Kind,[string]$Path) {
    if ($Kind -eq 'Fallout3') {
        $master = Join-Path $Path 'Data\Fallout3.esm'
        if ([IO.File]::Exists($master)) {
            $reader = [IO.File]::OpenRead($master)
            try {
                $sample = [byte[]]::new([int][Math]::Min($reader.Length,1048576))
                $count = $reader.Read($sample,0,$sample.Length)
                $header = [Text.Encoding]::ASCII.GetString($sample,0,$count)
            } finally { $reader.Dispose() }
            if ($header.StartsWith('TES4',[StringComparison]::Ordinal) -and
                $header -cmatch '(?s)sSneakCaution\x00DATA..\[VORSICHT\]\x00' -and
                $header -cmatch '(?s)sSneakDetected\x00DATA..\[ERKANNT\]\x00') {
                return 'This copy contains German game data. TTW needs English Fallout 3 GOTY.'
            }
        }
    }
    $folder = [IO.DirectoryInfo]::new($Path)
    $copyMarker = Join-Path $Path '.pcvrhub_ttwvr_original'
    if ($Kind -eq 'NewVegas' -and [IO.File]::Exists($copyMarker)) {
        $original = [IO.File]::ReadAllText($copyMarker).Trim()
        if ([IO.Directory]::Exists($original)) { $folder = [IO.DirectoryInfo]::new($original) }
    }
    if (-not $folder.Parent -or $folder.Parent.Name -ine 'common' -or -not $folder.Parent.Parent -or
        $folder.Parent.Parent.Name -ine 'steamapps') { return }
    $appIds = if ($Kind -eq 'Fallout3') { @('22370') } else { @('22380','22490') }
    $manifest = foreach ($appId in $appIds) {
        $file = Join-Path $folder.Parent.Parent.FullName "appmanifest_$appId.acf"
        if ([IO.File]::Exists($file)) { $file; break }
    }
    if (-not $manifest) { return }
    $text = [IO.File]::ReadAllText($manifest)
    $installDir = [regex]::Match($text,'(?im)^\s*"installdir"\s*"([^"]+)"')
    if (-not $installDir.Success -or $installDir.Groups[1].Value -ine $folder.Name) { return }
    $mounted = [regex]::Match($text,'(?is)"MountedConfig"\s*\{([^}]+)\}')
    $config = if ($mounted.Success) { $mounted.Groups[1].Value } else { [regex]::Match($text,'(?is)"UserConfig"\s*\{([^}]+)\}').Groups[1].Value }
    $language = [regex]::Match($config,'(?i)"language"\s*"([^"]+)"')
    if ($language.Success -and $language.Groups[1].Value -ine 'english') {
        if ($Kind -eq 'Fallout3') { return "Steam installed the '$($language.Groups[1].Value)' game data. TTW needs English Fallout 3 GOTY." }
        return "Steam installed the '$($language.Groups[1].Value)' game data. Set this game's language to English in Steam Properties, wait for the download, then choose R."
    }
}

function Find-TTWFallout3Depot([string]$ManualPath,[switch]$Quiet) {
    $depot = $script:TTWFallout3Depot
    $candidates = if ($ManualPath) { $ManualPath } else { Get-SteamDepotProbePaths -AppId $depot.AppId -DepotId $depot.DepotId }
    $required = @(Get-TTWConverterInputFiles 'Fallout3')
    foreach ($path in $candidates) {
        if (-not [IO.Directory]::Exists($path)) { continue }
        $path = [IO.Path]::GetFullPath($path).TrimEnd('\')
        $missing = @(Get-TTWMissingSourceFiles $path $required)
        if ($missing.Count) {
            Write-Verbose "  Incomplete Fallout 3 download in $path. Missing: $($missing -join ', ')."
            if ($ManualPath -and -not $Quiet) { Write-Host '  That folder does not contain all the Fallout 3 GOTY files yet.' -ForegroundColor Yellow }
            continue
        }
        $issue = Get-TTWSourceIssue 'Fallout3' $path
        if ($issue) {
            if (-not $Quiet) { Write-Host "  $issue" -ForegroundColor Yellow }
            continue
        }
        return $path
    }
}

function Get-TTWFallout3ManagedDepot([string]$Root) {
    $remembered = Join-Path $Root 'fallout3-depot-path.txt'
    $path = if ([IO.File]::Exists($remembered)) { [IO.File]::ReadAllText($remembered).Trim() }
    if (-not $path -or -not [IO.Directory]::Exists($path) -or (Test-TTWProtectedGameFolder $path)) { return }
    Find-TTWFallout3Depot $path
}

function Get-TTWFallout3DepotCopy([string]$Source,[string]$Root) {
    Write-Host '  [OK] English Fallout 3 files found.' -ForegroundColor Green
    Write-Host "  Steam download: $Source" -ForegroundColor Gray
    $remembered = Join-Path $Root 'fallout3-depot-path.txt'
    if (-not (Test-TTWProtectedGameFolder $Source)) {
        Write-Host '  The Hub can use this folder directly.' -ForegroundColor Cyan
        Write-PCVRAtomicText -Path $remembered -Value $Source
        return $Source
    }
    $default = Join-Path $Root 'Fallout 3 English'
    $depot = $script:TTWFallout3Depot
    $receipt = "$($depot.AppId)/$($depot.DepotId)/$($depot.ManifestId)"
    $required = @(Get-TTWConverterInputFiles 'Fallout3')
    $files = @($required + @(Get-TTWLooseGameFiles $Source) | Select-Object -Unique)
    $needed = 0L
    foreach ($file in $files) { $needed += [IO.FileInfo]::new((Join-Path $Source $file)).Length }
    Write-Host ''
    Write-Host '  Choose where to save the English Fallout 3 copy' -ForegroundColor Cyan
    Write-Host '  TTW needs the files outside Program Files. The Steam download stays in place.'
    Write-Host ('  Space needed: {0:N2} GB' -f ($needed / 1GB))
    Write-Host "  Suggested folder: $default"
    Write-Host '  Press Enter for the suggestion. To use another empty folder, drop it here or paste its path.'
    while ($true) {
        $answer = Read-Host '  Save Fallout 3 copy to (Enter = suggested folder, Q = back)'
        if ($null -eq $answer -or $answer.Trim() -ieq 'Q') { return }
        $path = $answer.Trim().Trim('"').Trim("'")
        $custom = [bool]$path
        if (-not $path) { $path = $default }
        $stage = $null
        try {
            $path = Resolve-TTWGameCopyPath $path @($Source) $Root $default
            $marker = Join-Path $path '.pcvrhub_ttw_fo3_depot'
            if ([IO.File]::Exists($marker) -and [IO.File]::ReadAllText($marker) -ceq $receipt -and
                (Test-TTWFiles $path @('steam_appid.txt')) -and [IO.File]::ReadAllText((Join-Path $path 'steam_appid.txt')).Trim() -ceq $depot.AppId -and
                -not @(Get-TTWMissingSourceFiles $path $files).Count -and -not (Get-TTWSourceIssue 'Fallout3' $path)) {
                Write-PCVRAtomicText -Path $remembered -Value $path
                return $path
            }
            if (-not (Test-TTWEmptyGameCopyTarget $path)) { throw 'Choose an empty folder for the Fallout 3 copy.' }
            if ([IO.DriveInfo]::new([IO.Path]::GetPathRoot($path)).AvailableFreeSpace -lt $needed) { throw 'There is not enough space for the Fallout 3 copy on this drive.' }
            if ($custom) {
                Write-Host "  Save English Fallout 3 copy to: $path" -ForegroundColor Cyan
                [void](Wait-PCVRExplicitEnter -Message 'Press Enter to copy to this folder.')
                $null = Resolve-TTWGameCopyPath $path @($Source) $Root $default
                if (-not (Test-TTWEmptyGameCopyTarget $path)) { throw 'The destination is no longer empty.' }
            }
            Write-Host "  Copying English Fallout 3 files to: $path" -ForegroundColor Cyan
            Write-Host '  Large files can take a few minutes to copy.' -ForegroundColor Gray
            $parent = [IO.Path]::GetDirectoryName($path)
            $stageName = '.pcvrhub-ttw-fo3-copy-' + [guid]::NewGuid().ToString('N')
            $stagingPath = Join-Path $parent $stageName
            [void][IO.Directory]::CreateDirectory($stagingPath)
            $stage = $stagingPath
            for ($i = 0; $i -lt $files.Count; $i++) {
                $file = $files[$i]
                Write-Verbose "Copying Fallout 3 file $($i+1) of $($files.Count): $file"
                $target = Join-Path $stage $file
                [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
                $sourceFile = Join-Path $Source $file
                [IO.File]::Copy($sourceFile,$target,$false)
                if ([IO.FileInfo]::new($target).Length -ne [IO.FileInfo]::new($sourceFile).Length) {
                    throw "Copy incomplete: $file"
                }
            }
            if (@(Get-TTWMissingSourceFiles $stage $files).Count -or (Get-TTWSourceIssue 'Fallout3' $stage)) {
                throw 'The copied Fallout 3 source did not pass verification.'
            }
            Write-PCVRAtomicText -Path (Join-Path $stage 'steam_appid.txt') -Value $depot.AppId
            Write-PCVRAtomicText -Path (Join-Path $stage '.pcvrhub_ttw_fo3_depot') -Value $receipt
            $null = Resolve-TTWGameCopyPath $path @($Source) $Root $default
            if ([IO.Directory]::Exists($path)) { [IO.Directory]::Delete($path,$false) }
            [IO.Directory]::Move($stage,$path)
            Write-PCVRAtomicText -Path $remembered -Value $path
            Write-Host "  [OK] English Fallout 3 copy ready: $path" -ForegroundColor Green
            return $path
        } catch [IO.EndOfStreamException] { throw }
        catch { Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow }
        finally {
            if ($stage -and [IO.Directory]::Exists($stage) -and
                [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($stage)) -ieq $parent -and [IO.Path]::GetFileName($stage) -ceq $stageName) {
                Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Get-TTWFallout3Depot([string]$Root) {
    $depot = $script:TTWFallout3Depot
    $command = "download_depot $($depot.AppId) $($depot.DepotId) $($depot.ManifestId)"
    $found = Find-TTWFallout3Depot -Quiet
    if ($found) { return Get-TTWFallout3DepotCopy $found $Root }
    Write-Host ''
    Write-Host '  Download English Fallout 3 GOTY in Steam' -ForegroundColor Cyan
    Write-Host '  1. In Steam Console: paste the copied command with Ctrl+V, then press Enter.'
    Write-Host '  2. Wait for "Depot download complete". Return here and press Enter.'
    Write-Host '     The Hub finds the downloaded files automatically. If Steam denies access, choose Q.'
    $openConsole = $true
    while ($true) {
        if ($openConsole) {
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to copy the command and open Steam Console...')
            $global:PCVRLastClipboardWriteSucceeded = $false
            try { Set-Clipboard -Value $command -DeferManualFallback } catch {}
            if (-not (Open-PCVRSteamConsole -OpenOnly)) {
                Write-Host '  Steam Console could not open. Type O to retry or Q to go back.' -ForegroundColor Yellow
            }
            if (-not $global:PCVRLastClipboardWriteSucceeded) {
                Show-PCVRClipboardManualFallback -Text $command
            }
            $openConsole = $false
            try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
        }
        $answer = Read-Host '  Press Enter to find the Steam download (O = reopen Steam, Q = back)'
        if ($null -eq $answer) { return }
        $answer = $answer.Trim()
        if ($answer -ieq 'Q') { return }
        if ($answer -ieq 'O') { $openConsole = $true; continue }
        if ($answer) {
            Write-Host '  Wait for the download in Steam, then press Enter here.' -ForegroundColor Yellow
            continue
        }
        Write-Host '  Looking for the English Fallout 3 files in your Steam libraries...' -ForegroundColor Cyan
        $found = Find-TTWFallout3Depot -Quiet
        if ($found) { return Get-TTWFallout3DepotCopy $found $Root }
        while (-not $found) {
            Write-Host '  No complete download found. If Steam is still downloading, wait and press Enter again.' -ForegroundColor Yellow
            $answer = Read-Host '  Enter = search again, P = paste the folder shown in Steam, O = reopen Steam, Q = back'
            if ($null -eq $answer -or $answer.Trim() -ieq 'Q') { return }
            $answer = $answer.Trim()
            if ($answer -ieq 'O') { $openConsole = $true; break }
            if ($answer -ieq 'P') {
                Write-Host '  Use the folder printed after "Depot download complete" in Steam.' -ForegroundColor Cyan
                $manual = Read-Host '  Paste the Steam download folder (Enter = back)'
                if ($manual) {
                    $manual = $manual.Trim().Trim('"').Trim("'")
                    if ($manual -and [IO.Directory]::Exists($manual)) { $found = Find-TTWFallout3Depot $manual }
                    if (-not $found) { Write-Host '  That folder could not be used. Check the folder shown in Steam.' -ForegroundColor Yellow }
                }
            } elseif (-not $answer) {
                Write-Host '  Looking for the English Fallout 3 files in your Steam libraries...' -ForegroundColor Cyan
                $found = Find-TTWFallout3Depot -Quiet
            }
        }
        if ($found) { return Get-TTWFallout3DepotCopy $found $Root }
    }
}

function Get-TTWGame([string]$Kind, [string]$Preferred, [switch]$ForConversion, [string]$Root) {
    $isVegas = $Kind -eq 'NewVegas'
    $name = if ($isVegas) { 'Fallout: New Vegas Ultimate Edition' } else { 'Fallout 3 GOTY' }
    $exe = if ($isVegas) { 'FalloutNV.exe' } else { 'Fallout3.exe' }
    $gameId = if ($isVegas) { 'fallout-new-vegas-vr' } else { 'fallout-3-vr' }
    $appId = if ($isVegas) { '22380' } else { '22370' }
    $folderNames = if ($isVegas) { @('Fallout New Vegas') } else { @('Fallout 3 goty','Fallout 3') }
    $regKey = if ($isVegas) { 'FalloutNV' } else { 'Fallout3' }
    $required = if ($ForConversion) { @(Get-TTWConverterInputFiles $Kind) } else { $script:TTWRequirements.$Kind }
    $canUseDepot = $ForConversion -and $Kind -eq 'Fallout3' -and $Root
    $manual = ''
    $searchDepot = $true
    while ($true) {
        $candidates = if ($manual) { $manual } else {
            $Preferred
            Get-PCVRRememberedGameFolder -GameId $gameId -StateNames @('user_located','base_game_path','installed_path') -ProbeFiles @($exe)
            Find-SteamGameFolder -AppId $appId -SteamFolderNames $folderNames -ProbeExe $exe -HubGameId $gameId
            foreach ($prefix in @('HKLM:\SOFTWARE\WOW6432Node','HKLM:\SOFTWARE')) {
                (Get-ItemProperty -LiteralPath "$prefix\Bethesda Softworks\$regKey" -Name 'Installed Path' -ErrorAction SilentlyContinue).'Installed Path'
            }
        }
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $rejected = [Collections.Generic.List[string]]::new()
        foreach ($candidate in @($candidates | Where-Object { $_ })) {
            if ([IO.File]::Exists($candidate)) { $candidate = [IO.Path]::GetDirectoryName($candidate) }
            if (-not [IO.Directory]::Exists($candidate) -or -not [IO.File]::Exists((Join-Path $candidate $exe))) { continue }
            $candidate = (Get-Item -LiteralPath $candidate).FullName.TrimEnd('\','/')
            if (-not $seen.Add($candidate)) { continue }
            if ($canUseDepot -and $manual -and [IO.Path]::GetFileName($candidate) -ieq "depot_$($script:TTWFallout3Depot.DepotId)") {
                $depot = Find-TTWFallout3Depot $candidate
                if ($depot) {
                    $selected = Get-TTWFallout3DepotCopy $depot $Root
                    if ($selected) { return $selected }
                }
                continue
            }
            $missing = @(Get-TTWMissingSourceFiles $candidate $required)
            $issue = if ($ForConversion -and $Kind -eq 'Fallout3' -and (Test-TTWProtectedGameFolder $candidate)) {
                'Fallout 3 must be outside Program Files. Move it to another library, then choose R.'
            } elseif ($ForConversion -and -not $missing.Count) {
                try { Get-TTWSourceIssue $Kind $candidate }
                catch { "Could not read the game source: $($_.Exception.Message)" }
            }
            if (-not $missing.Count -and -not $issue) { return $candidate }
            $rejected.Add($candidate)
            if ($missing.Count) { $rejected.Add("Missing game files: $($missing -join ', '). Verify the game and its DLC in your store.") }
            if ($issue) { $rejected.Add($issue) }
        }
        if ($canUseDepot -and -not $manual -and $searchDepot) {
            $searchDepot = $false
            $managed = Get-TTWFallout3ManagedDepot $Root
            if ($managed) { return $managed }
            $depot = Find-TTWFallout3Depot
            if ($depot) {
                $selected = Get-TTWFallout3DepotCopy $depot $Root
                if ($selected) { return $selected }
            }
        }
        foreach ($line in $rejected) { Write-Host "  $line" -ForegroundColor Yellow }
        if ($manual -and -not $seen.Count) { Write-Host "  That path does not contain $exe. Choose the game folder." -ForegroundColor Yellow }
        if ($canUseDepot) {
            Write-Host '  D = download English files from Steam' -ForegroundColor Cyan
            Write-Host '  Already have English Fallout 3 GOTY? Drop its game folder here or paste its path.'
            $inputPath = Read-Host '  English Fallout 3 GOTY folder or D (R = rescan, Q = cancel)'
        } else {
            $inputPath = Read-Host "  Drop or paste English $name folder [R = rescan, Q = cancel]"
        }
        if ($null -eq $inputPath -or $inputPath.Trim() -ieq 'Q') { throw 'Game folder selection cancelled.' }
        if ($canUseDepot -and $inputPath.Trim() -ieq 'D') {
            $depot = Get-TTWFallout3Depot $Root
            if ($depot) { return $depot }
            $manual = ''
            continue
        }
        if ($inputPath.Trim() -ieq 'R') { $searchDepot = $true }
        $manual = if ($inputPath.Trim() -ine 'R') { $inputPath.Trim().Trim('"').Trim("'") }
    }
}

function Resolve-TTWGameCopyPath([string]$Path, [string[]]$OriginalGames, [string]$Root, [string]$Default) {
    if ($Path -notmatch '^[A-Za-z]:[\\/]') { throw 'Enter a full folder path, for example D:\VR Games\New Vegas TTWVR.' }
    $path = [IO.Path]::GetFullPath($Path).TrimEnd([char[]]'\/')
    $parent = [IO.Path]::GetDirectoryName($path)
    if (-not $parent -or (Test-TTWProtectedGameFolder $path) -or $path -match '(?i)[\\/]steamapps[\\/]common(?:[\\/]|$)') {
        throw 'Choose a separate folder below the drive root, outside Program Files, Windows and the Steam games folder.'
    }
    foreach ($segment in ($path.Substring(3) -split '\\')) {
        if ($segment -match '(?i)[. ]$|[<>:"|?*\x00-\x1f]|^(?:CON|PRN|AUX|NUL|(?:COM|LPT)[1-9\u00b9\u00b2\u00b3])(?:\.|$)') {
            throw 'The destination contains an invalid Windows folder name.'
        }
    }
    foreach ($protected in @($OriginalGames) + @($Root)) {
        if (-not $protected -or ($protected -ieq $Root -and $path -ieq $Default)) { continue }
        $protected = [IO.Path]::GetFullPath($protected).TrimEnd([char[]]'\/')
        if ($path -ieq $protected -or $path.StartsWith($protected + '\',[StringComparison]::OrdinalIgnoreCase) -or
            $protected.StartsWith($path + '\',[StringComparison]::OrdinalIgnoreCase)) {
            throw 'Choose a folder separate from the original games and the Hub profile.'
        }
    }
    $drive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($path))
    if (-not $drive.IsReady) { throw "Drive $($drive.Name) is not available." }
    for ($item = $path; $item; $item = [IO.Path]::GetDirectoryName($item)) {
        try { $attributes = [IO.File]::GetAttributes($item) }
        catch [IO.FileNotFoundException] { continue }
        catch [IO.DirectoryNotFoundException] { continue }
        if ($attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Choose a folder without junctions or links: $item" }
        if (-not ($attributes -band [IO.FileAttributes]::Directory)) { throw "This part of the path is a file: $item" }
    }
    return $path
}

function Test-TTWEmptyGameCopyTarget([string]$Path) {
    return (-not [IO.Directory]::Exists($Path) -or [IO.Directory]::GetFileSystemEntries($Path).Count -eq 0)
}

function New-TTWPrivateGame([string]$Game, [string]$Root, [string]$Fallout3) {
    $default = Join-Path $Root 'Game'
    $rememberedPath = Join-Path $Root 'game-copy-path.txt'
    $suggested = $default
    $markerName = '.pcvrhub_ttwvr_original'
    $proof = if ($Fallout3) { @(Get-TTWConverterInputFiles 'NewVegas') } else { $script:TTWRequirements.NewVegas }
    try {
        if ([IO.File]::Exists($rememberedPath)) {
            $previous = Resolve-TTWGameCopyPath ([IO.File]::ReadAllText($rememberedPath).Trim()) @($Game,$Fallout3) $Root $default
            if ([IO.File]::Exists((Join-Path $previous $markerName))) { $suggested = $previous }
        }
    } catch {} # A removed drive or stale path must never block the prompt.
    $files = @($script:TTWRequirements.NewVegas) + @(
        'FalloutNVLauncher.exe','Fallout_default.ini','binkw32.dll','steam_api.dll','libvorbis.dll',
        'libvorbisfile.dll','atimgpud.dll','GDFFalloutNV.dll','low.ini','medium.ini','high.ini','VeryHigh.ini',
        'Galaxy.dll','EOSSDK-Win32-Shipping.dll','Data/Update.bsa'
    )
    $loose = @(Get-TTWLooseGameFiles $Game)
    $files += $loose
    $names = @('Fallout','DeadMoney','HonestHearts','OldWorldBlues','LonesomeRoad','GunRunnersArsenal','CaravanPack','ClassicPack','MercenaryPack','TribalPack')
    foreach ($asset in Get-ChildItem -LiteralPath (Join-Path $Game 'Data') -File) {
        if ($asset.Extension -in @('.bsa','.nam') -and ($names -contains ($asset.BaseName -split ' - ',2)[0])) { $files += 'Data/' + $asset.Name }
    }
    $files = @($files | Select-Object -Unique | Where-Object { [IO.File]::Exists((Join-Path $Game $_)) })
    $missingSource = @(Get-TTWMissingSourceFiles $Game $proof)
    if ($missingSource.Count) { throw "The original New Vegas folder is incomplete. Missing: $($missingSource -join ', '). Verify the game files in your store and retry." }
    $needed = ($files | ForEach-Object { (Get-Item -LiteralPath (Join-Path $Game $_)).Length } | Measure-Object -Sum).Sum
    Write-Host '  Setup needs a clean, writable New Vegas folder outside Program Files. It can make a separate game copy.' -ForegroundColor Yellow
    Write-Host ('  The copy needs about {0:N1} GB plus 3 GB of free space for setup. Your original game, mods and saves stay in place.' -f ($needed / 1GB))
    while ($true) {
        Write-Host "  Suggested folder: $suggested"
        Write-Host '  Leave the input blank for the suggested folder, or type Q to cancel.'
        $choice = Read-Host '  Save New Vegas copy to (Enter = suggested folder, Q = cancel)'
        if ($null -eq $choice -or $choice.Trim() -ieq 'Q') { throw 'Game copy selection cancelled.' }
        $choice = $choice.Trim().Trim('"').Trim("'")
        if (-not $choice) { $choice = $suggested }
        $stage = $null
        try {
            $copy = Resolve-TTWGameCopyPath $choice @($Game,$Fallout3) $Root $default
            $marker = Join-Path $copy $markerName
            if ([IO.File]::Exists($marker) -and [IO.File]::ReadAllText($marker).Trim() -ieq $Game -and
                (Test-TTWFiles $copy $script:TTWRequirements.NewVegas) -and -not [IO.File]::Exists((Join-Path $copy 'd3d9.dll'))) {
                if (-not (Test-InstallerTargetWritable (Join-Path $copy '.pcvrhub_write_target'))) { throw 'The existing game copy is not writable.' }
                $missing = @(Get-TTWMissingSourceFiles $copy $proof)
                $repair = @((@($missing) + @('Data/Update.bsa','FalloutNVLauncher.exe') + $loose) | Select-Object -Unique | Where-Object {
                    $_ -in $files -and -not [IO.File]::Exists((Join-Path $copy $_))
                })
                if ($missing.Count -and @($missing | Where-Object { $_ -notin $repair }).Count) {
                    throw "The game copy has unreadable or empty files: $($missing -join ', '). Choose a new empty folder."
                }
                if ($repair.Count) {
                    $repairBytes = 0L
                    foreach ($file in $repair) { $repairBytes += [IO.FileInfo]::new((Join-Path $Game $file)).Length }
                    if ([IO.DriveInfo]::new([IO.Path]::GetPathRoot($copy)).AvailableFreeSpace -lt $repairBytes) { throw 'There is not enough space to repair this New Vegas copy.' }
                    Write-Host "  Repair the existing game copy: $copy" -ForegroundColor Cyan
                    Write-Host ('  Setup will restore {0} missing files ({1:N1} MB). Existing files are kept.' -f $repair.Count,($repairBytes / 1MB))
                    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to repair the private game copy.')
                    $null = Resolve-TTWGameCopyPath $copy @($Game,$Fallout3) $Root $default
                    if (-not [IO.File]::Exists($marker) -or [IO.File]::ReadAllText($marker).Trim() -ine $Game) { throw 'The selected folder no longer matches the original New Vegas installation.' }
                    Write-Host '  [..] Restoring missing original files.' -ForegroundColor Cyan
                    for ($i = 0; $i -lt $repair.Count; $i++) {
                        $file = $repair[$i]
                        if ($i -gt 0 -and $i % 20 -eq 0) { Write-Host "  [..] Restoring file $($i+1) of $($repair.Count)." -ForegroundColor Cyan }
                        $target = Join-Path $copy $file
                        $parentFolder = [IO.Path]::GetDirectoryName($target)
                        $null = Resolve-TTWGameCopyPath $parentFolder @($Game,$Fallout3) '' $default
                        [void][IO.Directory]::CreateDirectory($parentFolder)
                        if ([IO.File]::Exists($target)) { continue }
                        $temp = Join-Path $parentFolder ('.pcvrhub-repair-' + [guid]::NewGuid().ToString('N'))
                        try {
                            [IO.File]::Copy((Join-Path $Game $file),$temp)
                            [IO.File]::SetAttributes($temp,[IO.FileAttributes]::Normal)
                            [IO.File]::Move($temp,$target)
                        } finally { if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) } }
                    }
                }
                if (@(Get-TTWMissingSourceFiles $copy $proof).Count) { throw 'The repaired New Vegas copy is incomplete. Choose a new folder or retry.' }
                Write-Host "  [OK] Reusing the existing game copy: $copy" -ForegroundColor Green
            } else {
                if (-not (Test-TTWEmptyGameCopyTarget $copy)) { throw 'The folder is not empty and is not a verified copy of this installation. No files were replaced.' }
                $drive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($copy))
                if ($drive.AvailableFreeSpace -lt $needed + 3GB) { throw ('Drive {0} needs at least {1:N1} GB free for the copy and setup.' -f $drive.Name, (($needed + 3GB) / 1GB)) }
                Write-Host "  Copy from: $Game"
                Write-Host "  Copy to:   $copy"
                [void](Wait-PCVRExplicitEnter -Message 'Press Enter to create the private game copy.')
                $null = Resolve-TTWGameCopyPath $copy @($Game,$Fallout3) $Root $default
                if (-not (Test-TTWEmptyGameCopyTarget $copy)) { throw 'The destination is no longer empty. No files were replaced.' }
                $parent = [IO.Path]::GetDirectoryName($copy)
                $stageName = '.pcvrhub-ttwvr-copy-' + [guid]::NewGuid().ToString('N')
                $stagingPath = [IO.Path]::Combine($parent,$stageName)
                if (-not (Test-InstallerTargetWritable $stagingPath)) { throw 'The copy destination is not writable.' }
                [void][IO.Directory]::CreateDirectory($stagingPath)
                $stage = $stagingPath
                Write-Host '  [..] Copying original game files. This can take several minutes.' -ForegroundColor Cyan
                foreach ($file in $files) {
                    $target = Join-Path $stage $file
                    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
                    [IO.File]::Copy((Join-Path $Game $file),$target)
                    $attributes = [IO.File]::GetAttributes($target)
                    if ($attributes -band [IO.FileAttributes]::ReadOnly) {
                        [IO.File]::SetAttributes($target,($attributes -band (-bnot [IO.FileAttributes]::ReadOnly)))
                    }
                }
                if (@(Get-TTWMissingSourceFiles $stage $proof).Count) { throw 'The private game copy is incomplete.' }
                Write-PCVRAtomicText -Path (Join-Path $stage $markerName) -Value $Game
                $null = Resolve-TTWGameCopyPath $copy @($Game,$Fallout3) $Root $default
                if ([IO.Directory]::Exists($copy)) { [IO.Directory]::Delete($copy,$false) }
                [IO.Directory]::Move($stage,$copy)
                Write-Host "  [OK] Private game copy verified: $copy" -ForegroundColor Green
            }
        } catch [IO.EndOfStreamException] { throw }
        catch {
            Write-Host ('  ' + $_.Exception.Message + ' Choose another folder, retry, or type Q to cancel.') -ForegroundColor Yellow
            continue
        } finally {
            if ($stage -and [IO.Directory]::Exists($stage) -and
                [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($stage)) -ieq $parent -and [IO.Path]::GetFileName($stage) -ceq $stageName) {
                Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        try { Write-PCVRAtomicText -Path $rememberedPath -Value $copy }
        catch { Write-Host '  Setup can use this copy, but could not remember its location for next time.' -ForegroundColor Yellow }
        return $copy
    }
}

function Test-TTWPackageFiles([string]$Root, [string[]]$Proof) {
    if (-not [IO.Directory]::Exists($Root)) { return $false }
    foreach ($group in $Proof) {
        $found = $false
        foreach ($relative in $group.Split('|')) {
            $path = Join-Path $Root $relative
            if ($relative.Contains('*')) {
                $folder = Split-Path -Parent $path
                $found = [IO.Directory]::Exists($folder) -and [bool](Get-ChildItem -LiteralPath $folder -Filter (Split-Path -Leaf $path) -File | Select-Object -First 1)
            } else { $found = [IO.File]::Exists($path) }
            if ($found) { break }
        }
        if (-not $found) { return $false }
    }
    return $true
}

function Get-TTWArchiveLayout([string]$Archive, [string[]]$Proof, [hashtable]$Tools) {
    $extension = [IO.Path]::GetExtension($Archive)
    if ($extension -notin @('.zip','.7z','.rar') -or -not [IO.File]::Exists($Archive)) {
        throw 'Choose a complete ZIP, 7z or RAR archive.'
    }
    $entries = [Collections.Generic.List[object]]::new()
    if ($extension -ieq '.zip') {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
        try {
            foreach ($entry in $zip.Entries) {
                $attributes = $entry.ExternalAttributes
                if ((($attributes -shr 16) -band 0xf000) -eq 0xa000 -or ($attributes -band 0x400)) {
                    throw 'The archive contains a symbolic link or reparse point.'
                }
                $entries.Add(@{ Path=$entry.FullName; File=[bool]$entry.Name -and $entry.Length -gt 0 })
            }
        } finally { $zip.Dispose() }
    } else {
        if (-not $Tools.SevenZip) { $Tools.SevenZip = Get-SevenZip }
        if (-not $Tools.SevenZip) { throw '7-Zip is required to read this archive. Install it and retry.' }
        $escaped = '"' + $Archive + '"'
        $info = [Diagnostics.ProcessStartInfo]::new($Tools.SevenZip,"l -slt -ba -sccUTF-8 -p- -- $escaped")
        $info.UseShellExecute = $false
        $info.CreateNoWindow = $true
        $info.RedirectStandardOutput = $true
        $info.RedirectStandardError = $true
        $info.StandardOutputEncoding = [Text.Encoding]::UTF8
        $process = [Diagnostics.Process]::Start($info)
        try {
            $errors = $process.StandardError.ReadToEndAsync()
            $listing = $process.StandardOutput.ReadToEnd()
            $process.WaitForExit()
            if ($process.ExitCode -ne 0) { throw '7-Zip could not read the complete archive.' }
            $null = $errors.GetAwaiter().GetResult()
        } finally { $process.Dispose() }
        foreach ($block in ($listing -split '\r?\n\r?\n')) {
            $path = [regex]::Match($block, '(?m)^Path = ([^\r\n]+)')
            if (-not $path.Success) { continue }
            if ($block -match '(?im)^(?:Symbolic Link|Hard Link|Alternate Stream) = .+|^Attributes = .*\b[lL][rwx-]{9}|^Encrypted = \+') {
                throw 'The archive contains links, alternate streams or encrypted entries.'
            }
            $file = $block -match '(?m)^Size = [1-9]\d*\r?$' -and
                $block -notmatch '(?im)^Folder = \+|^Attributes = D'
            $entries.Add(@{ Path=$path.Groups[1].Value; File=$file })
        }
    }
    $paths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $directories = @{}
    foreach ($entry in $entries) {
        $path = Assert-PCVROwnedRelativePath -Relative $entry.Path.TrimEnd('\','/')
        if ($path -match '(?i)(?:^|\\)(?:CON|PRN|AUX|NUL|(?:COM|LPT)[1-9\u00b9\u00b2\u00b3])(?:\.|\\|$)|[. ](?:\\|$)|[<>"|?*]|\\\\') {
            throw "Unsafe filename in archive: $path"
        }
        if (-not $paths.Add($path)) { throw "Duplicate path in archive: $path" }
        if (-not $entry.File) { continue }
        $parent = [string][IO.Path]::GetDirectoryName($path)
        if (-not $directories.ContainsKey($parent)) {
            $directories[$parent] = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        }
        [void]$directories[$parent].Add([IO.Path]::GetFileName($path))
    }
    $roots = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($relative in $Proof[0].Replace('/','\').Split('|')) {
        $parent = [string][IO.Path]::GetDirectoryName($relative)
        $suffix = '\' + $parent
        $leaf = [IO.Path]::GetFileName($relative)
        foreach ($directory in $directories.Keys) {
            if ($parent -and $directory -ine $parent -and -not $directory.EndsWith($suffix,[StringComparison]::OrdinalIgnoreCase)) { continue }
            if ($leaf.Contains('*')) {
                if (-not @($directories[$directory] | Where-Object { $_ -like $leaf }).Count) { continue }
            } elseif (-not $directories[$directory].Contains($leaf)) { continue }
            if (-not $parent) { [void]$roots.Add($directory) }
            elseif ($directory -ieq $parent) { [void]$roots.Add('') }
            else { [void]$roots.Add($directory.Substring(0,$directory.Length - $suffix.Length)) }
        }
    }
    $validRoots = @(
        foreach ($root in $roots) {
            $prefix = if ($root) { $root + '\' } else { '' }
            $missing = $false
            foreach ($group in $Proof) {
                $found = $false
                foreach ($relative in $group.Replace('/','\').Split('|')) {
                    $path = $prefix + $relative
                    $parent = [string][IO.Path]::GetDirectoryName($path)
                    if (-not $directories.ContainsKey($parent)) { continue }
                    $leaf = [IO.Path]::GetFileName($path)
                    if ($leaf.Contains('*')) {
                        $found = [bool]@($directories[$parent] | Where-Object { $_ -like $leaf }).Count
                    } else { $found = $directories[$parent].Contains($leaf) }
                    if ($found) { break }
                }
                if (-not $found) { $missing = $true; break }
            }
            if (-not $missing) { $root }
        }
    )
    $isVr = @($paths | Where-Object { $_ -match '(?:^|\\)NVSE\\Plugins\\TTWVR\.dll$' }).Count -gt 0
    $isConverter = @($paths | Where-Object { $_ -match '(?:^|\\)TTW Install\.exe$' }).Count -gt 0
    $isYup = @($paths | Where-Object { $_ -match '(?:^|\\)YUPTTW\.esm$' }).Count -gt 0
    if ($isVr -and $Proof[0] -ine 'NVSE/Plugins/TTWVR.dll') {
        throw "This is the TTWVR mod from Discord. Keep it for the VR step. This step needs $($Proof -join ', ')."
    }
    if ($isConverter -and $Proof[0] -ine 'TTW Install.exe') {
        throw "This is the Tale of Two Wastelands converter from ModPub. This step needs $($Proof -join ', ')."
    }
    if ($isYup -and $Proof[0] -ine 'YUPTTW.esm') {
        throw "This archive contains YUPTTW game data. This step needs $($Proof -join ', ')."
    }
    if ($validRoots.Count -gt 1) { throw 'The archive contains more than one possible package folder. Choose the standalone publisher archive.' }
    if ($validRoots.Count -eq 0) {
        $requires = $Proof -join ', '
        throw "The selected archive is missing the files for this step: $requires."
    }
    return [pscustomobject]@{ Root=$validRoots[0]; SevenZip=$Tools.SevenZip; Zip=$extension -ieq '.zip' }
}

function Expand-TTWPackage([string]$Archive, [string]$Work, [string[]]$Proof, [hashtable]$Tools = @{}) {
    $layout = Get-TTWArchiveLayout $Archive $Proof $Tools
    $stage = Join-Path $Work ('p' + [guid]::NewGuid().ToString('N').Substring(0,8))
    Write-Host "  [..] Extracting $([IO.Path]::GetFileName($Archive)). Large archives can take a few minutes." -ForegroundColor Cyan
    if ($layout.Zip) {
        [IO.Compression.ZipFile]::ExtractToDirectory($Archive,$stage)
    } elseif (-not (Expand-7zWithProgress -SevenZip $layout.SevenZip -Archive $Archive -Dest $stage -Label ([IO.Path]::GetFileName($Archive)))) {
        throw 'Extraction failed. Choose the complete publisher archive or download it again.'
    }
    $root = if ($layout.Root) { Join-Path $stage $layout.Root } else { $stage }
    if (-not (Test-TTWPackageFiles $root $Proof)) { throw 'Required files are missing after extraction. Choose the complete publisher archive or download it again.' }
    Write-Host "  [OK] Verified $([IO.Path]::GetFileName($Archive))." -ForegroundColor Green
    return $root
}

function Find-TTWPackageCandidate([string[]]$Pattern, [string[]]$Proof, [string[]]$Folders, [hashtable]$Tools) {
    if (-not $Folders) { $Folders = @((Get-PCVRDownloadsFolder)) }
    $recovered = Get-PCVRRecoveryInput -PathType Leaf
    $candidates = @(
        foreach ($folder in $Folders) {
            if (-not $folder -or -not [IO.Directory]::Exists($folder)) { continue }
            foreach ($hint in $Pattern) {
                Get-ChildItem -LiteralPath $folder -Filter $hint -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Extension -in @('.zip','.7z','.rar') }
            }
        }
    )
    $paths = @($recovered) + @($candidates |
        Sort-Object LastWriteTimeUtc -Descending | Select-Object -ExpandProperty FullName)
    foreach ($candidate in ($paths | Where-Object { $_ } | Select-Object -Unique)) {
        try {
            $null = Get-TTWArchiveLayout $candidate $Proof $Tools
            return $candidate
        } catch {
            Write-Verbose "Skipping $([IO.Path]::GetFileName($candidate)): $($_.Exception.Message)"
        }
    }
}

function Get-TTWGitHubPackage([string]$Repo, [string]$Pattern, [string]$Work, [string[]]$Proof) {
    $env:PCVR_HUB_RECOVERY_PAGE = "https://github.com/$Repo/releases"
    Write-Host "  Checking $Repo and downloading the Windows archive. This may take a few minutes." -ForegroundColor Cyan
    $release = Resolve-GitHubReleaseAsset -Repo $Repo -IncludePrerelease $false -AssetPatterns @($Pattern) -SkipReleasesWithoutMatchingAsset
    if (-not $release.Resolved) { throw "The official $Repo Windows archive could not be resolved. Retry when GitHub is reachable." }
    $archive = Join-Path $Work ([IO.Path]::GetFileName(([uri]$release.Url).AbsolutePath))
    $ok = Invoke-SafeDownload -Urls @($release.Url) -Destination $archive -Label "$Repo $($release.Tag)" -ManualUrl "https://github.com/$Repo/releases" -AllowSkip $false -PlainProgress -FunctionalPayloadOnly -DisableGitHubAssetReresolution
    if (-not $ok) { throw "The $Repo download did not complete." }
    return Expand-TTWPackage $archive $Work $Proof
}

function Get-TTWManualPackage([string]$Label, [string]$Url, [string[]]$Pattern, [string]$Work, [string[]]$Proof, [string[]]$SearchFolders) {
    $env:PCVR_HUB_RECOVERY_PAGE = $Url
    $tools = @{}
    Write-Host "  Download this file: $Label." -ForegroundColor Cyan
    if ($Proof[0] -ieq 'TTW Install.exe') {
        Write-Host '  On ModPub under Main files, choose Tale of Two Wastelands. The file name starts with Tale of Two Wastelands.'
        Write-Host '  Keep TTWVR.zip from Discord for the later VR step. YUPTTW is a separate ModPub download.' -ForegroundColor Yellow
    } elseif ($Proof[0] -ieq 'YUPTTW.esm') {
        Write-Host '  On ModPub under Main files, select YUPTTW and choose Manual download. This is the patch loaded after the conversion.' -ForegroundColor Yellow
    }
    $site = if (([uri]$Url).Host -eq 'www.nexusmods.com') { 'Nexus Mods' } else { 'ModPub' }
    if ($site -eq 'Nexus Mods' -and $Proof[0] -ieq 'NVSE/Plugins/ttw_nvse.dll') {
        Write-Host '  Nexus calls this file TTWNVSE. The downloaded archive can be named ROOGNVSE.'
    }
    Write-Host '  Sign in if prompted. Find the named file, choose Manual Download and wait for the download to finish.'
    Write-Host '  Return here and drop the complete archive into the Hub, or press Enter to search Downloads.'
    Open-PCVRPageAfterEnter -Message "Press Enter to open $site for the manual download." -Url $Url
    try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
    $first = $true
    while ($true) {
        $prompt = if ($first) { '  Drop the downloaded archive or press Enter to search Downloads' } else { '  Drop the downloaded archive, R to search again, O to reopen, Q to cancel' }
        $inputPath = Read-Host $prompt
        if ($null -eq $inputPath -or $inputPath.Trim() -ieq 'Q') { throw "$Label download cancelled." }
        $first = $false
        $answer = $inputPath.Trim()
        $candidate = $null
        if ($answer -in @('','R')) {
            $candidate = Find-TTWPackageCandidate $Pattern $Proof $SearchFolders $tools
            if (-not $candidate) {
                Write-Host "  Downloads did not contain a verified archive for $Label." -ForegroundColor Yellow
                continue
            }
            Write-Host '  Choose No to drop a different archive.'
            $confirm = Read-Host "  Use $([IO.Path]::GetFileName($candidate))? [Y/N]"
            if ($null -eq $confirm -or $confirm.Trim() -ieq 'Q') { throw "$Label download cancelled." }
            if ($confirm.Trim() -ine 'Y') { continue }
        } elseif ($answer -ieq 'O') {
            Open-PCVRPageAfterEnter -Message "Press Enter to reopen $site for the manual download." -Url $Url
            continue
        } else {
            $candidate = ConvertTo-PCVRCanonicalUserPath $inputPath
        }
        if (-not [IO.File]::Exists($candidate)) {
            Write-Host '  Drop the complete ZIP, 7z or RAR archive here, or paste its full path.' -ForegroundColor Yellow
            continue
        }
        try { return Expand-TTWPackage $candidate $Work $Proof $tools }
        catch { Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow }
    }
}

function Get-TTWPortableProfile([string]$Organizer, [string]$Game, [string]$ExpectedProfile) {
    if (-not (Test-TTWFiles $Organizer @('ModOrganizer.exe','ModOrganizer.ini','portable.txt'))) { return }
    $ini = Join-Path $Organizer 'ModOrganizer.ini'
    $config = [IO.File]::ReadAllText($ini)
    $configured = Get-TTWIniGame $ini
    if (-not (Test-TTWFiles $configured $script:TTWRequirements.NewVegas)) { return }
    $configured = (Get-Item -LiteralPath $configured).FullName
    if ($Game -and $configured.TrimEnd('\') -ine $Game.TrimEnd('\')) { return }
    $custom = @{}
    foreach ($key in @('base_directory','mod_directory','profiles_directory')) {
        $line = [regex]::Match($config, "(?im)^$key\s*=\s*([^\r\n]+)")
        if ($line.Success) { $custom[$key] = $line.Groups[1].Value.Trim().Trim('"').Replace('\\','\') }
    }
    $base = if ($custom.base_directory) { $custom.base_directory } else { $Organizer }
    if (-not [IO.Path]::IsPathRooted($base)) { $base = Join-Path $Organizer $base }
    $mods = if ($custom.mod_directory) { $custom.mod_directory.Replace('%BASE_DIR%',$base) } else { Join-Path $base 'mods' }
    $profiles = if ($custom.profiles_directory) { $custom.profiles_directory.Replace('%BASE_DIR%',$base) } else { Join-Path $base 'profiles' }
    if (-not [IO.Path]::IsPathRooted($mods)) { $mods = Join-Path $base $mods }
    if (-not [IO.Path]::IsPathRooted($profiles)) { $profiles = Join-Path $base $profiles }
    $profile = if ($ExpectedProfile) { $ExpectedProfile } else { Join-Path $profiles 'Default' }
    if (-not [IO.File]::Exists((Join-Path $profile 'modlist.txt')) -or
        [IO.Path]::GetFullPath((Split-Path -Parent $profile)).TrimEnd('\') -ine [IO.Path]::GetFullPath($profiles).TrimEnd('\')) { return }
    return [ordered]@{ schema=1; mo2=(Join-Path $Organizer 'ModOrganizer.exe'); ini=$ini; mods=$mods; profile=$profile; profileName=(Split-Path -Leaf $profile); game=$configured }
}

function Set-TTWProfileMods([string]$ModList, [string[]]$Names) {
    $lines = [IO.File]::ReadAllLines($ModList)
    $rest = @($lines | Where-Object { $_.Length -lt 2 -or $_[0] -notin @('+','-') -or $_.Substring(1) -notin $Names })
    $header = @($rest | Where-Object { $_ -like '#*' })
    $body = @($rest | Where-Object { $_ -notlike '#*' })
    $active = @($Names | ForEach-Object { '+' + $_ })
    $nl = [Environment]::NewLine
    Write-PCVRAtomicText -Path $ModList -Value ((($header + $active + $body) -join $nl) + $nl)
}

function Install-TTWDependencies([string]$Game, [string]$Work, $Profile) {
    if (-not (Test-TTWFiles $Game $script:TTWRequirements.xNVSE)) {
        $nvse = Get-TTWGitHubPackage 'xNVSE/NVSE' '(?i)^nvse_\d+_\d+_\d+\.7z$' $Work $script:TTWRequirements.xNVSE
        Get-ChildItem -LiteralPath $nvse -Filter '*.pdb' -File | Remove-Item
        [void](Install-OwnedModPayload -SourceRoot $nvse -GameRoot $Game -Identity 'ttwvrnvse' -KeepExistingRelativePaths @('Data\NVSE\nvse_config.ini'))
    }
    if (-not (Test-TTWPatchedExe $Game)) {
        Write-Host "  The 4 GB patch must be applied in $Game."
        $choice = Read-Host '  Type E for Epic, S for Steam/GOG, Q to cancel'
        if ($choice -notin @('E','S')) { throw '4 GB patch selection cancelled.' }
        $patchExe = if ($choice -ieq 'E') { 'Patcher.exe' } else { 'FNVpatch.exe' }
        $url = if ($choice -ieq 'E') { 'https://www.nexusmods.com/newvegas/mods/81281?tab=files' } else { 'https://www.nexusmods.com/newvegas/mods/62552?tab=files' }
        $patchName = if ($choice -ieq 'E') { 'Main Files: Epic Games Patcher' } else { 'Main Files: 4GB Patcher' }
        $patch = Get-TTWManualPackage $patchName $url '*Patcher*' $Work @($patchExe)
        $patchTarget = Join-Path $Game $patchExe
        if ([IO.File]::Exists($patchTarget)) { throw "A patcher already exists at $patchTarget. Run it manually, then retry." }
        $patchFiles = @(Get-ChildItem -LiteralPath $patch -File -Recurse | Where-Object {
            $_.Extension -notin @('.txt','.md','.url','.pdf','.html') -and $_.FullName -ne (Join-Path $patch $patchExe)
        })
        $copies = @{}
        foreach ($entry in $patchFiles) {
            $relative = $entry.FullName.Substring($patch.Length).TrimStart('\','/')
            [void](Assert-PCVROwnedRelativePath -Relative $relative)
            $target = Join-Path $Game $relative
            if ([IO.File]::Exists($target)) {
                if ((Get-FileHash -LiteralPath $entry.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash) {
                    throw "The patcher needs $relative, but a different file is already there."
                }
            } else { $copies[$target] = $entry.FullName }
        }
        Write-Host '  The publisher patcher will open. Wait until it finishes and close its window.'
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to run the selected 4 GB patcher.')
        $gameExe = Join-Path $Game 'FalloutNV.exe'
        $before = [IO.File]::ReadAllBytes($gameExe)
        $temporaryFiles = [Collections.Generic.List[string]]::new()
        try {
            foreach ($target in $copies.Keys) {
                [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
                [IO.File]::Copy($copies[$target],$target,$false)
                $temporaryFiles.Add($target)
            }
            Copy-Item -LiteralPath (Join-Path $patch $patchExe) -Destination $patchTarget
            $temporaryFiles.Add($patchTarget)
            $process = Start-Process -FilePath $patchTarget -WorkingDirectory $Game -PassThru -Wait
            if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0 -or -not (Test-TTWPatchedExe $Game)) { throw 'The publisher patcher did not produce a verified 4 GB executable.' }
        } catch { [IO.File]::WriteAllBytes($gameExe,$before); throw }
        finally { foreach ($temporaryFile in $temporaryFiles) { [IO.File]::Delete($temporaryFile) } }
    }
    $deps = @(
        @{ Name='JIP LN NVSE Plugin'; Id=58277; Pattern='*JIP*'; File=$script:TTWRequirements.plugins[0] },
        @{ Name='JIP LN Settings INI'; Id=58277; Pattern='*JIP*INI*'; File=$script:TTWRequirements.plugins[1] },
        @{ Name='Stewie Tweaks'; Id=66347; Pattern='*Stewie*'; File=$script:TTWRequirements.plugins[2] },
        @{ Name='Engine Optimizations'; Id=80993; Pattern='*Optimi*'; File=$script:TTWRequirements.plugins[3] }
    )
    $existing = @(Get-TTWActiveMods (Join-Path $Profile.profile 'modlist.txt') $Profile.mods) + (Join-Path $Game 'Data')
    foreach ($dependency in $deps) {
        $name = 'PCVR Hub ' + $dependency.Name
        $target = Join-Path $Profile.mods $name
        if (Test-TTWFiles $target @($dependency.File)) { $name; continue }
        if (Test-TTWEffectiveFile $existing $dependency.File) { continue }
        $stage = Get-TTWManualPackage $dependency.Name "https://www.nexusmods.com/newvegas/mods/$($dependency.Id)?tab=files" $dependency.Pattern $Work @($dependency.File)
        [void][IO.Directory]::CreateDirectory($target)
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $target -Identity 'ttwvrdependency')
        $name
    }
}

function Install-TTWEssentials($Profile, [string]$Work) {
    $items = @(
        @{ Name='TTWNVSE'; Id=77415; Pattern=@('*ROOGNVSE*','*TTW*NVSE*','*-77415-*'); Proof='NVSE/Plugins/ttw_nvse.dll' },
        @{ Name='JohnnyGuitar NVSE'; Id=66927; Pattern='*JohnnyGuitar*'; Proof='NVSE/Plugins/*JohnnyGuitar*.dll' },
        @{ Name='JohnnyGuitar NVSE - All Tweaks Preset'; Id=86200; Pattern='*JohnnyGuitar*'; Proof='NVSE/Plugins/JohnnyGuitar.ini' },
        @{ Name='ShowOff NVSE'; Id=72541; Pattern='*ShowOff*'; Proof='NVSE/Plugins/ShowOffNVSE.dll' },
        @{ Name='ShowOff INI'; Id=72541; Pattern='*ShowOff*INI*'; Proof='NVSE/Plugins/ShowOffNVSE.ini|NVSE/Plugins/ShowOff.ini' },
        @{ Name='NVTF'; Id=66537; Pattern='*NVTF*'; Proof='NVSE/Plugins/NVTF.dll' },
        @{ Name='NVTF - INI'; Id=66537; Pattern='*NVTF*INI*'; Proof='NVSE/Plugins/NVTF.ini' },
        @{ Name='Fast Weapon Lag Fix'; Id=71973; Pattern='*Weapon*Lag*'; Proof='NVSE/Plugins/weapon_lag_fix.dll' },
        @{ Name='VATS Lag Fix'; Id=84823; Pattern='*VATS*Lag*'; Proof='NVSE/Plugins/*vats*lag*.dll' },
        @{ Name='ActorCause Save Bloat Fix'; Id=80666; Pattern='*ActorCause*'; Proof='NVSE/Plugins/ActorCauseSaveBloatFix.dll' },
        @{ Name='kNVSE'; Id=71336; Pattern='*kNVSE*'; Proof='NVSE/Plugins/kNVSE.dll' },
        @{ Name='UIO - User Interface Organizer'; Id=57174; Pattern='*UIO*'; Proof='NVSE/Plugins/ui_organizer.dll' },
        @{ Name='MLF'; Id=68714; Pattern='*MLF*'; Proof='NVSE/Plugins/*mod*limit*.dll|NVSE/Plugins/mlf.dll' },
        @{ Name='Crash Logger'; Id=82540; Pattern='*Crash*Log*'; Proof='NVSE/Plugins/*crash*log*.dll' },
        @{ Name='Improved Console'; Id=70801; Pattern='*Improved*Console*'; Proof='NVSE/Plugins/*improved*console*.dll' },
        @{ Name='Console Paste'; Id=65906; Pattern='*Console*Paste*'; Proof='NVSE/Plugins/nvse_console_clipboard.dll' }
    )
    $modlist = Join-Path $Profile.profile 'modlist.txt'
    $existing = @(Get-TTWActiveMods $modlist $Profile.mods) + (Join-Path $Profile.game 'Data')
    $activate = [Collections.Generic.List[string]]::new()
    foreach ($package in $items) {
        $name = 'PCVR Hub ' + $package.Name
        $target = Join-Path $Profile.mods $name
        if (Test-TTWPackageFiles $target @($package.Proof)) { $activate.Insert(0,$name); continue }
        if (@($existing | Where-Object { Test-TTWPackageFiles $_ @($package.Proof) }).Count) { continue }
        $fileGroup = if ($package.Name -eq 'ShowOff INI') { 'Optional Files' } else { 'Main Files' }
        $source = "https://www.nexusmods.com/newvegas/mods/$($package.Id)?tab=files"
        $stage = Get-TTWManualPackage "$fileGroup - $($package.Name)" $source $package.Pattern $Work @($package.Proof)
        [void][IO.Directory]::CreateDirectory($target)
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $target -Identity 'ttwvrdependency')
        $activate.Insert(0,$name)
    }
    $iniFile = 'NVSE/Plugins/nvse_stewie_tweaks.ini'
    $iniName = 'PCVR Hub Stewie Tweaks INI'
    $iniTarget = Join-Path $Profile.mods $iniName
    if (Test-TTWPackageFiles $iniTarget @($iniFile)) {
        $activate.Insert(0,$iniName)
    } elseif (-not @($existing | Where-Object { Test-TTWPackageFiles $_ @($iniFile) }).Count) {
        Write-Host '  Setup can download the recommended Stewie Tweaks settings from ModdingLinked.'
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download the Stewie Tweaks INI...')
        $stage = Get-TTWGitHubPackage 'ModdingLinked/Stewie-Tweaks-INIs' '(?i)^Stewie_Tweaks-VNV_INI\.7z$' $Work @($iniFile)
        [void][IO.Directory]::CreateDirectory($iniTarget)
        [void](Install-OwnedModPayload -SourceRoot $stage -GameRoot $iniTarget -Identity 'ttwvrdependency')
        $activate.Insert(0,$iniName)
    }
    return $activate.ToArray()
}

function Get-TTWVRStage([string]$Work, [scriptblock]$ReadInput, [scriptblock]$OpenUrl, [string[]]$SearchFolders) {
    $env:PCVR_HUB_RECOVERY_PAGE = $script:TTWChannel
    $stageRef = @{ Stage=$null }
    $proof = $script:TTWRequirements.TTWVR
    $tools = @{}
    $expand = ${function:Expand-TTWPackage}
    $search = ${function:Find-TTWPackageCandidate}
    $finder = { & $search 'TTWVR*.zip' $proof $SearchFolders $tools }.GetNewClosure()
    $validator = {
        param($file)
        $stageRef.Stage = & $expand $file $Work $proof $tools
        return [bool]$stageRef.Stage
    }.GetNewClosure()
    [void](Invoke-PCVRDiscordDownloadFlow -Label 'TTWVR' -InviteUrl $script:TTWInvite `
        -DownloadPostUrl $script:TTWChannel -FilePatterns @('TTWVR*.zip') -ConfirmFoundArchive -AcceptArchiveAtSearchPrompt `
        -DownloadChannelInstructions 'Scroll to the bottom of #announcements and download TTWVR.zip from the newest release.' `
        -ReadInput $ReadInput -OpenUrl $OpenUrl -FindCandidate $finder -ValidateCandidate $validator)
    return $stageRef.Stage
}

function Read-TTWVRReleaseVersion([scriptblock]$ReadInput, [string]$Stage) {
    $valid = '^v?\d+\.\d+\.\d+(?:[-.]?[A-Za-z][A-Za-z0-9.-]*)?$'
    if ($Stage) {
        $metadata = Join-Path $Stage 'meta.ini'
        if ([IO.File]::Exists($metadata) -and [IO.FileInfo]::new($metadata).Length -le 64KB) {
            try {
                $version = Get-TTWMo2Setting ([IO.File]::ReadAllText($metadata)) 'General' 'version'
                if ($version -match $valid) {
                    $version = 'v' + $version.TrimStart('v','V')
                    Write-Host "  [OK] Release version from the selected archive: $version" -ForegroundColor Green
                    return $version
                }
            } catch { Write-Verbose "Could not read the TTWVR archive version: $($_.Exception.Message)" }
        }
    }
    $prompt = 'Type the version from the Discord message for the selected archive (for example v1.1.5), or Q to cancel'
    while ($true) {
        $inputVersion = if ($ReadInput) { & $ReadInput $prompt } else { Read-Host "  $prompt" }
        if ($null -eq $inputVersion -or $inputVersion.Trim() -ieq 'Q') { throw 'Release version entry cancelled.' }
        $version = $inputVersion.Trim()
        if ($version -match $valid) { return $version }
        Write-Host '  Enter the release number printed in the Discord message for this download.' -ForegroundColor Yellow
    }
}

function Install-TTWVRProfile([string]$Mode, $Profile, [string]$Stage, [string]$Root, [string]$Work, [string[]]$Dependencies, [string]$Version, [switch]$ModOnly) {
    $id = if ($Mode -eq 'NewVegas') { 'fallout-new-vegas-vr' } else { 'a-tale-of-two-realities-vr' }
    $slot = if ($Mode -eq 'NewVegas') { 'Secondary' } else { 'Primary' }
    $route = if ($Mode -eq 'NewVegas') { 'ModB' } else { 'Current' }
    $modName = 'PCVR Hub TTWVR ' + $Mode
    $destination = Join-Path $Profile.mods $modName
    $modList = Join-Path $Profile.profile 'modlist.txt'
    if (Get-Process -Name 'ModOrganizer','FalloutNV','FalloutNVLauncher' -ErrorAction SilentlyContinue) { throw 'Close Mod Organizer 2 and Fallout: New Vegas before installing.' }
    if ($ModOnly) {
        $current = Get-TTWInstalledState $Root $Mode -ForModUpdate
        if (-not $current -or $current.profile -ine $Profile.profile -or $current.mods -ine $Profile.mods -or
            $current.mo2 -ine $Profile.mo2 -or $current.game -ine $Profile.game) {
            throw 'The saved Mod Organizer profile changed. Close MO2 and retry from the Hub.'
        }
    }
    foreach ($other in @(Get-TTWActiveMods $modList $Profile.mods)) {
        if ($other -ine $destination -and (Test-TTWFiles $other @('NVSE/Plugins/TTWVR.dll'))) { throw 'Disable the other TTWVR installation in this profile, then retry.' }
    }
    [void][IO.Directory]::CreateDirectory($Root)
    [void][IO.Directory]::CreateDirectory($destination)
    if (-not (Test-InstallerTargetWritable -TargetPath $destination)) { throw 'The selected MO2 mod folder is not writable.' }
    $stateFile = Join-Path $Root 'ttwvr-install.json'
    $oldList = [IO.File]::ReadAllBytes($modList)
    $oldState = if ([IO.File]::Exists($stateFile)) { ,[IO.File]::ReadAllBytes($stateFile) } else { $null }
    $snapshot = Save-PCVRPublisherZipSnapshot -GameRoot $destination -Stage $Stage -Identity 'ttwvr' -SnapshotRoot (Join-Path $Work 'rollback')
    try {
        Write-Host '  [..] Installing TTWVR in the selected MO2 profile.' -ForegroundColor Cyan
        [void](Install-OwnedModPayload -SourceRoot $Stage -GameRoot $destination -Identity 'ttwvr' -KeepExistingRelativePaths @('NVSE\Plugins\TTWVR\TTWVR.ini','NVSE\Plugins\TTWVR\TTWVR.state'))
        $paths = @($script:TTWRequirements.TTWVR | ForEach-Object { Join-Path $destination $_ })
        if (-not (Confirm-PlacedFilesSurvive -Paths $paths -GameDir $destination -NoClear)) { throw 'Required TTWVR files did not survive the copy check.' }
        if (-not $ModOnly) {
            Set-TTWProfileMods $modList (@($modName) + $Dependencies)
            foreach ($file in @('Start-TTWVR.cmd','Start-TTWVR.ps1','TTWVR-State.ps1','requirements.json')) {
                Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination (Join-Path $Root $file) -Force
            }
            $Profile.mode = $Mode
            Write-PCVRAtomicText -Path $stateFile -Value ($Profile | ConvertTo-Json -Compress)
        }
        if (-not (Get-TTWInstalledState $Root $Mode)) { throw 'The selected MO2 profile did not pass the game, dependency and activation checks.' }
        $contract = New-PCVRInstallerContract -Id $id -GameName 'A Tale of Two Realities' -Acquisition Discord -AntivirusNotice -DiscordInviteUrl $script:TTWInvite -DiscordDownloadUrl $script:TTWChannel -Routes @($route) -RequiredInstalledFileGroups @('ttwvr-install.json','Start-TTWVR.cmd','Start-TTWVR.ps1') -RequiredExternalFileGroups $paths
        $receipt = if ($Mode -eq 'NewVegas') { Join-Path $PSScriptRoot '..\FNVVR\.installed_path_ttwvr' } else { Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $contract -GameDir $Root -Version $Version -VersionSlot $slot -Route $route -InstalledPathReceiptPaths @($receipt))
    } catch {
        if (-not $ModOnly) {
            [IO.File]::WriteAllBytes($modList,$oldList)
            if ($null -ne $oldState) { [IO.File]::WriteAllBytes($stateFile,$oldState) }
            elseif ([IO.File]::Exists($stateFile)) { Remove-Item -LiteralPath $stateFile -Force }
        }
        Restore-PCVRPublisherZipSnapshot -GameRoot $destination -Snapshot $snapshot
        throw
    }
}

function Install-TTWOrganizer([string]$Organizer, [string]$Work) {
    $proof = @('ModOrganizer.exe','usvfs_x86.dll','plugins/game_falloutNV.dll')
    if (-not (Test-TTWFiles $Organizer $proof)) {
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to download portable Mod Organizer 2 from GitHub.')
        $package = Get-TTWGitHubPackage 'ModOrganizer2/modorganizer' '(?i)^Mod\.Organizer-\d+\.\d+\.\d+\.7z$' $Work $proof
        [void][IO.Directory]::CreateDirectory($Organizer)
        foreach ($file in Get-ChildItem -LiteralPath $package -Force) { Copy-Item -LiteralPath $file.FullName -Destination $Organizer -Recurse -Force }
    }
    $marker = Join-Path $Organizer 'portable.txt'
    if (-not [IO.File]::Exists($marker)) { [IO.File]::WriteAllText($marker,'') }
}

function Test-TTWVCRuntime([string]$Architecture) {
    foreach ($base in 'HKLM:\SOFTWARE','HKLM:\SOFTWARE\WOW6432Node') {
        $key = Get-ItemProperty "$base\Microsoft\VisualStudio\14.0\VC\Runtimes\$Architecture" -ErrorAction SilentlyContinue
        $version = $null
        if ($key -and $key.Installed -eq 1 -and [version]::TryParse(([string]$key.Version).TrimStart('v','V'),[ref]$version) -and
            $version -ge [version]'14.40.33810.0') { return $true }
    }
    return $false
}

function Install-TTWVCRuntimes([string]$Work) {
    foreach ($architecture in 'x86','x64') {
        if (Test-TTWVCRuntime $architecture) { continue }
        Write-Host "  Microsoft Visual C++ ($architecture) is required. Setup will download the Microsoft installer. Windows may ask for approval."
        [void](Wait-PCVRExplicitEnter -Message "Press Enter to install the Microsoft $architecture runtime...")
        $url = "https://aka.ms/vc14/vc_redist.$architecture.exe"
        $path = Join-Path $Work "vc_redist.$architecture.exe"
        $ok = Invoke-SafeDownload -Urls @($url) -Destination $path -Label "Microsoft Visual C++ $architecture" -ManualUrl $url -AllowSkip:$false -PlainProgress -FunctionalPayloadOnly
        if (-not $ok) { throw "The Microsoft $architecture runtime download did not complete." }
        Write-Host '  The Microsoft installer may take a few minutes.'
        $process = Start-Process -FilePath $path -ArgumentList '/install','/passive','/norestart' -Wait -PassThru
        if ($null -eq $process.ExitCode -or $process.ExitCode -notin @(0,3010) -or -not (Test-TTWVCRuntime $architecture)) {
            throw "Windows could not verify the $architecture runtime. Complete the Microsoft setup and retry."
        }
        if ($process.ExitCode -eq 3010) { Write-Host '  Windows requests a restart. Restart before the first game launch.' -ForegroundColor Yellow }
    }
}

function Set-TTWPluginOrder($Profile) {
    $order = @(
        'FalloutNV.esm','DeadMoney.esm','HonestHearts.esm','OldWorldBlues.esm','LonesomeRoad.esm','GunRunnersArsenal.esm',
        'Fallout3.esm','Anchorage.esm','ThePitt.esm','BrokenSteel.esm','PointLookout.esm','Zeta.esm',
        'CaravanPack.esm','ClassicPack.esm','MercenaryPack.esm','TribalPack.esm','TaleOfTwoWastelands.esm','YUPTTW.esm'
    )
    foreach ($name in 'plugins.txt','loadorder.txt') {
        $path = Join-Path $Profile.profile $name
        $lines = if ([IO.File]::Exists($path)) { [IO.File]::ReadAllLines($path) } else { @() }
        $current = @($lines | Where-Object { $_ -and $_ -notlike '#*' } | ForEach-Object { $_.TrimStart('*') } | Where-Object { $_ -in $order })
        if (($current -join '|') -ieq ($order -join '|')) { continue }
        $header = @($lines | Where-Object { $_ -like '#*' })
        $extra = @($lines | Where-Object { $_ -and $_ -notlike '#*' -and $_.TrimStart('*') -notin $order })
        Write-PCVRAtomicText -Path $path -Value (($header + $order + $extra) -join [Environment]::NewLine)
    }
}

function Get-TTWConversionProgress([string]$Root) {
    if (-not $Root) { return }
    $path = Join-Path $Root 'conversion-progress.json'
    if (-not [IO.File]::Exists($path)) { return }
    try {
        $saved = [IO.File]::ReadAllText($path) | ConvertFrom-Json
        if ($saved.schema -eq 1 -and $saved.game -and $saved.mo2 -and $saved.profile -and
            $saved.stage -in @('converter-open','output-needed','copying','conversion-ready','profile-ready')) { return $saved }
    } catch {
        Write-Verbose "Could not read TTW conversion progress: $($_.Exception.Message)"
    }
}

function Save-TTWConversionProgress([string]$Root, $Profile, [string]$Fallout3,
    [string]$Stage, [string]$Destination, [string]$Source) {
    if (-not $Root) { return }
    $record = [ordered]@{
        schema=1; stage=$Stage; game=$Profile.game; fallout3=$Fallout3; mo2=$Profile.mo2; profile=$Profile.profile
        destination=$Destination; source=$Source; timeUtc=[DateTime]::UtcNow.ToString('o')
    }
    Write-PCVRAtomicText -Path (Join-Path $Root 'conversion-progress.json') -Value ($record | ConvertTo-Json)
}

function Select-TTWConvertedOutput([string]$Suggested) {
    Write-Host '  Choose the folder that contains TaleOfTwoWastelands.esm and its BSA archives.' -ForegroundColor Cyan
    if ($Suggested) { Write-Host "  Last selected folder: $Suggested" }
    while ($true) {
        $prompt = if ($Suggested) { '  Drop or paste the folder (Enter = last folder, Q = stop)' } else { '  Drop or paste the folder (Q = stop)' }
        $answer = Read-Host $prompt
        if ($null -eq $answer -or $answer.Trim() -ieq 'Q') { throw 'TTW setup stopped. Existing converted files are kept. Retry setup to use them.' }
        $path = if ($answer.Trim()) { ConvertTo-PCVRCanonicalUserPath $answer } else { $Suggested }
        if ($path -and [IO.File]::Exists($path) -and [IO.Path]::GetFileName($path) -ieq 'TaleOfTwoWastelands.esm') {
            $path = [IO.Path]::GetDirectoryName($path)
        }
        if (-not $path -or -not [IO.Directory]::Exists($path)) {
            Write-Host '  That folder could not be opened. Choose the output folder created by the TTW converter.' -ForegroundColor Yellow
            continue
        }
        $missing = @(Get-TTWMissingSourceFiles $path $script:TTWConvertedFiles)
        if (-not $missing.Count) { return [IO.Path]::GetFullPath($path).TrimEnd('\') }
        Write-Host "  This folder has missing or empty TTW files: $($missing -join ', ')" -ForegroundColor Yellow
    }
}

function Get-TTWConversionFiles([string]$Root) {
    $pending = [Collections.Generic.Queue[string]]::new()
    $pending.Enqueue($Root)
    while ($pending.Count) {
        $folder = $pending.Dequeue()
        foreach ($entry in Get-ChildItem -LiteralPath $folder -Force) {
            if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "TTW output contains a junction or link: $($entry.FullName)" }
            if ($entry.PSIsContainer) { $pending.Enqueue($entry.FullName) } else { $entry }
        }
    }
}

function Import-TTWConvertedOutput($Profile, [string]$Fallout3, [string]$Root,
    [string]$Source, [string]$Destination) {
    foreach ($path in @($Source, (Split-Path -Parent $Destination))) {
        for ($item = $path; $item; $item = [IO.Path]::GetDirectoryName($item)) {
            if ([IO.Directory]::Exists($item) -and ([IO.File]::GetAttributes($item) -band [IO.FileAttributes]::ReparsePoint)) {
                throw "Use a TTW folder without junctions or links: $item"
            }
        }
    }
    foreach ($gamePath in @($Profile.game,$Fallout3)) {
        if (-not $gamePath) { continue }
        $base = [IO.Path]::GetFullPath($gamePath).TrimEnd('\')
        if ($Source -ieq $base -or $Source.StartsWith($base + '\',[StringComparison]::OrdinalIgnoreCase) -or
            $base.StartsWith($Source + '\',[StringComparison]::OrdinalIgnoreCase)) {
            throw 'Select the separate TTW output folder. The original game folder cannot be imported into MO2.'
        }
    }
    $parent = [IO.Path]::GetFullPath($Profile.mods).TrimEnd('\')
    if (('' + (Split-Path -Parent $Source)).TrimEnd('\') -ieq $parent) { return $Source }
    if ($Source -ieq $parent -or $Source.StartsWith($parent + '\',[StringComparison]::OrdinalIgnoreCase) -or
        $parent.StartsWith($Source + '\',[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Select the TTW output folder outside or directly inside the MO2 mods folder.'
    }
    $files = @(Get-TTWConversionFiles $Source)
    $size = ($files | Measure-Object Length -Sum).Sum
    Write-Host "  Verified converted TTW files in: $Source" -ForegroundColor Green
    Write-Host ("  Copy {0:N2} GiB into MO2: {1}" -f ($size / 1GB), $Destination) -ForegroundColor Cyan
    Write-Host '  The source stays in place. Larger files can take a few minutes to copy.'
    Save-TTWConversionProgress $Root $Profile $Fallout3 'copying' $Destination $Source
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to copy the converted files into MO2.')
    $stage = Join-Path $parent ('.pcvrhub-ttw-import-' + [guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($stage)
    try {
        $targetDrive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($stage))
        if ($targetDrive.AvailableFreeSpace -lt $size) { throw "There is not enough free space for TTW on $($targetDrive.Name)." }
        $copied = 0L
        foreach ($file in $files) {
            $relative = $file.FullName.Substring($Source.Length + 1)
            $target = Join-Path $stage $relative
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
            Write-Progress -Activity 'Copying converted TTW files into MO2' -Status $relative -PercentComplete ([int](100 * $copied / $size))
            [IO.File]::Copy($file.FullName, $target)
            if ([IO.FileInfo]::new($target).Length -ne $file.Length) { throw "The TTW copy is incomplete: $relative" }
            $copied += $file.Length
        }
        if (@(Get-TTWMissingSourceFiles $stage $script:TTWConvertedFiles).Count) { throw 'The TTW copy is missing required files.' }
        if ([IO.Directory]::Exists($Destination)) {
            # Remove only an empty directory created for the converter.
            [IO.Directory]::Delete($Destination, $false)
        }
        [IO.Directory]::Move($stage, $Destination)
    } finally {
        Write-Progress -Activity 'Copying converted TTW files into MO2' -Completed
        if ([IO.Directory]::Exists($stage) -and (Split-Path -Parent ([IO.Path]::GetFullPath($stage))) -ieq $parent) {
            Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    return $Destination
}

function Start-TTWConversion($Profile, [string]$Fallout3, [string]$Work, [string]$Root) {
    if ([IO.File]::Exists((Join-Path $Profile.game 'd3d9.dll'))) { throw 'Use a clean New Vegas folder without the FNVVR or DXVK wrapper for the TTW profile.' }
    $mods = Join-Path $Profile.profile 'modlist.txt'
    $active = @(Get-TTWActiveMods $mods $Profile.mods) + (Join-Path $Profile.game 'Data')
    $missing = @($script:TTWConvertedFiles | Where-Object {
        $file = $_
        -not @($active | Where-Object { -not @(Get-TTWMissingSourceFiles $_ @($file)).Count } | Select-Object -First 1).Count
    })
    $saved = Get-TTWConversionProgress $Root
    if ($saved -and ($saved.mo2 -ine $Profile.mo2 -or $saved.profile -ine $Profile.profile -or $saved.game -ine $Profile.game)) { $saved = $null }
    $destination = if ($saved) { $saved.destination }
    $source = if ($saved) { $saved.source }
    if ($missing.Count) {
        if (Get-Process -Name 'TTW Install' -ErrorAction SilentlyContinue) {
            throw 'The TTW converter is still running. Let it finish, close it, then retry this step.'
        }
        $destination = Join-Path $Profile.mods 'Tale of Two Wastelands'
        $completed = Get-ChildItem -LiteralPath $Profile.mods -Directory -Filter 'Tale of Two Wastelands*' -ErrorAction SilentlyContinue |
            Where-Object { -not @(Get-TTWMissingSourceFiles $_.FullName $script:TTWConvertedFiles).Count } |
            Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        if ($completed) {
            $destination = $completed.FullName
        } else {
            if ([IO.Directory]::Exists($destination) -and [IO.Directory]::GetFileSystemEntries($destination).Count) {
                $destination = Join-Path $Profile.mods ('Tale of Two Wastelands ' + [guid]::NewGuid().ToString('N').Substring(0,8))
            }
            $handover = Get-PCVRRecoveryInput -PathType Container
            $suggested = if ($handover) { $handover } elseif ($source) { $source }
            if ($Root) {
                Write-Host '  If the TTW converter finished earlier, use its existing output. This skips conversion.' -ForegroundColor Cyan
                do {
                    $choice = Read-Host '  D = use existing converted files, N = run the converter, Q = stop'
                    if ($null -eq $choice -or $choice.Trim() -ieq 'Q') { throw 'TTW setup stopped. Existing converted files are kept.' }
                    $choice = $choice.Trim()
                } until ($choice -in @('D','N'))
                if ($choice -eq 'D') {
                    $source = Select-TTWConvertedOutput $suggested
                    $destination = Import-TTWConvertedOutput $Profile $Fallout3 $Root $source $destination
                }
            }
        }
        if (@(Get-TTWMissingSourceFiles $destination $script:TTWConvertedFiles).Count) {
            foreach ($inputGame in @(@{Kind='Fallout3'; Path=$Fallout3},@{Kind='NewVegas'; Path=$Profile.game})) {
                if (Test-TTWProtectedGameFolder $inputGame.Path) { throw "Move the $($inputGame.Kind) installation outside Program Files or select a separate game folder: $($inputGame.Path)" }
                $unavailable = @(Get-TTWMissingSourceFiles $inputGame.Path @(Get-TTWConverterInputFiles $inputGame.Kind))
                if ($unavailable.Count) { throw "The TTW source folder $($inputGame.Path) is incomplete. Missing: $($unavailable -join ', ')." }
                $issue = Get-TTWSourceIssue $inputGame.Kind $inputGame.Path
                if ($issue) { throw $issue }
            }
            $publisher = Get-TTWManualPackage 'Main files - Tale of Two Wastelands (the full installer)' $script:TTWPublisher 'Tale of Two Wastelands*' $Work $script:TTWConverterProof
            [void][IO.Directory]::CreateDirectory($destination)
            Write-Host ''
            Write-Host '  Use these three folders in the Tale of Two Wastelands window.' -ForegroundColor Yellow
            Write-Host '  Steam paths may be filled in automatically. Replace them wherever they differ from the paths below.'
            Write-Host ''
            Write-Host '  1. Fallout 3 (use the English depot folder or its copy if setup selected one)' -ForegroundColor Cyan
            Write-Host "     $Fallout3"
            Write-Host ''
            Write-Host '  2. Fallout: New Vegas (use the separate game copy if setup created one)' -ForegroundColor Cyan
            Write-Host "     $($Profile.game)"
            Write-Host ''
            Write-Host '  3. Tale of Two Wastelands (destination for the converted files)' -ForegroundColor Cyan
            Write-Host "     $destination"
            Write-Host ''
            Write-Host '  Use Browse or paste the paths, then click Install. Audio conversion can take an hour or more.'
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the TTW installer (UAC: choose Yes).')
            Set-Clipboard -Value $Profile.game -DeferManualFallback
            if ($global:PCVRLastClipboardWriteSucceeded) {
                Write-Host '  New Vegas source copied. In the second field, select its current text and press Ctrl+V.' -ForegroundColor Green
            } else {
                Show-PCVRClipboardManualFallback -Text $Profile.game
            }
            $source = $destination
            Save-TTWConversionProgress $Root $Profile $Fallout3 'converter-open' $destination $source
            $process = Start-Process -FilePath (Join-Path $publisher 'TTW Install.exe') -WorkingDirectory $publisher -Verb RunAs -PassThru -Wait
            if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) {
                throw "The TTW converter stopped with exit code $($process.ExitCode). Check its output before starting a new conversion. Setup kept the destination: $destination"
            }
            if (@(Get-TTWMissingSourceFiles $destination $script:TTWConvertedFiles).Count) {
                Save-TTWConversionProgress $Root $Profile $Fallout3 'output-needed' $destination $source
                Write-Host "  The converter closed successfully, but its files were not found in $destination." -ForegroundColor Yellow
                $source = Select-TTWConvertedOutput ''
                if (-not (Test-TTWEmptyGameCopyTarget $destination)) {
                    $destination = Join-Path $Profile.mods ('Tale of Two Wastelands ' + [guid]::NewGuid().ToString('N').Substring(0,8))
                }
                $destination = Import-TTWConvertedOutput $Profile $Fallout3 $Root $source $destination
            }
        }
        Save-TTWConversionProgress $Root $Profile $Fallout3 'conversion-ready' $destination $source
        $modName = Split-Path -Leaf $destination
        Set-TTWProfileMods $mods @($modName)
        Write-Host "  [OK] TTW game data: $destination" -ForegroundColor Green
    }
    $patchName = 'PCVR Hub YUPTTW'
    $patchRoot = Join-Path $Profile.mods $patchName
    $activePatch = @($active | Where-Object {
        $_ -ine (Join-Path $Profile.game 'Data') -and
        (Test-TTWFiles $_ $script:TTWYupProof) -and -not (Test-TTWFiles $_ @('TaleOfTwoWastelands.esm'))
    }).Count
    if (-not $activePatch -and -not (Test-TTWFiles $patchRoot $script:TTWYupProof)) {
        $yup = Get-TTWManualPackage 'Main files - YUPTTW (the separate update)' $script:TTWPublisher '*YUPTTW*' $Work $script:TTWYupProof
        [void][IO.Directory]::CreateDirectory($patchRoot)
        [void](Install-OwnedModPayload -SourceRoot $yup -GameRoot $patchRoot -Identity 'ttwvrdependency')
    }
    if (-not $activePatch -and (Test-TTWFiles $patchRoot $script:TTWYupProof)) { Set-TTWProfileMods $mods @($patchName) }
    Set-TTWPluginOrder $Profile
    if ($destination -and -not @(Get-TTWMissingSourceFiles $destination $script:TTWConvertedFiles).Count) {
        Save-TTWConversionProgress $Root $Profile $Fallout3 'profile-ready' $destination $source
    }
    Write-Host '  [OK] Tale of Two Wastelands and YUPTTW are active in this profile.' -ForegroundColor Green
}

function Update-TTWStockMo2Executables([string]$Config,[string]$Game) {
    $section = [regex]::Match($Config,'(?im)^\[customExecutables\][ \t]*\r?\n(?<body>(?:(?!^\[)[\s\S])*)')
    if (-not $section.Success) { return $Config }

    $body = $section.Groups['body'].Value
    $folder = $Game.Replace('\','/')
    $stock = @{ 'New Vegas' = 'FalloutNV.exe'; 'Fallout Launcher' = 'FalloutNVLauncher.exe' }
    foreach ($entry in [regex]::Matches($body,'(?im)^(?<index>[1-9]\d*)\\title[ \t]*=(?<title>[^\r\n]*)')) {
        $index = $entry.Groups['index'].Value
        $title = $entry.Groups['title'].Value.Trim().Trim('"')
        $expected = $stock[$title]
        $binary = Get-TTWMo2Setting $Config 'customExecutables' "$index\binary"
        $binaryLeaf = ($binary -split '[\\/]')[-1]

        if ($expected -and (-not $binary -or $binaryLeaf -ieq $expected)) {
            if (@(Get-TTWMissingSourceFiles $Game @($expected)).Count) { continue }
            $fields = [ordered]@{ binary = "$folder/$expected"; workingDirectory = $folder }
        } elseif ($title -ieq 'Explore Virtual Folder' -and $binaryLeaf -ieq 'Explorer++.exe') {
            $argumentLine = [regex]::Match($body,('(?im)^' + $index + '\\arguments[ \t]*=(?<value>[^\r\n]*)'))
            $arguments = $argumentLine.Groups['value'].Value.Trim()
            # Only rewrite the stock argument, a single quoted Data folder on a local drive.
            if ($arguments -notmatch '^\\"[A-Za-z]:[\\/][^"]*[\\/]data\\"$') { continue }
            $fields = [ordered]@{ arguments = '\"' + $folder + '/Data\"' }
        } else { continue }

        foreach ($field in $fields.Keys) {
            $key = "$index\$field"
            $value = $fields[$field]
            # QSettings treats separators in an unquoted value as INI syntax.
            if ($value -match '[,;=]') { $value = '"' + $value + '"' }
            $pattern = '(?im)^(?<key>' + [regex]::Escape($key) + '[ \t]*=)[^\r\n]*'
            $line = [regex]::Match($body,$pattern)
            if ($line.Success) {
                $body = $body.Remove($line.Index,$line.Length).Insert($line.Index,$line.Groups['key'].Value + $value)
            } else {
                $body = $key + '=' + $value + [Environment]::NewLine + $body
            }
        }
    }
    $old = $section.Groups['body']
    return $Config.Remove($old.Index,$old.Length).Insert($old.Index,$body)
}

function Initialize-TTWPortableGame([string]$Organizer,[string]$Game) {
    if (-not (Test-TTWFiles $Game $script:TTWRequirements.NewVegas) -or [IO.File]::Exists((Join-Path $Game 'd3d9.dll'))) {
        throw 'The selected New Vegas folder is incomplete or still contains a D3D9 wrapper.'
    }
    $ini = Join-Path $Organizer 'ModOrganizer.ini'
    $config = if ([IO.File]::Exists($ini)) { [IO.File]::ReadAllText($ini) } else { '' }
    $originalConfig = $config
    $name = Get-TTWMo2Setting $config 'General' 'gameName'
    $configured = if ($config) { Get-TTWIniGame $ini }
    if ($name -and $name -ine 'New Vegas') { throw 'This portable MO2 instance manages another game. Its settings were left in place.' }
    if ($configured -and $configured -ine $Game) {
        Write-Host "  MO2 currently points to: $configured" -ForegroundColor Yellow
        Write-Host "  Selected New Vegas folder: $Game" -ForegroundColor Cyan
        $choice = Read-Host '  Enter Y to change the game folder for this Hub profile, or Q to cancel'
        if ($choice -ine 'Y') { throw 'MO2 game folder change cancelled.' }
    } elseif ($configured -and $name -and $configured -ieq $Game) {
        $config = Update-TTWStockMo2Executables $config $Game
        if ($config -cne $originalConfig) {
            if (Get-Process -Name 'ModOrganizer' -ErrorAction SilentlyContinue) { throw 'Close Mod Organizer 2 so setup can repair its saved New Vegas launcher paths.' }
            Write-PCVRAtomicText -Path $ini -Value $config
            Write-Host '  [OK] Updated the saved New Vegas program paths in MO2.' -ForegroundColor Green
        }
        return
    }

    # Write only the portable instance's game settings; preserve profiles and the other INI sections.
    $edition = if ([IO.File]::Exists((Join-Path $Game 'Galaxy.dll'))) { 'GOG' }
               elseif ([IO.File]::Exists((Join-Path $Game 'EOSSDK-Win32-Shipping.dll'))) { 'Epic Games' }
               else { 'Steam' }
    $general = '(?im)^\[General\][ \t]*(?:\r?\n|$)(?<body>(?:(?!^\[)[\s\S])*)'
    $section = [regex]::Match($config,$general)
    $rest = [regex]::Replace($section.Groups['body'].Value,'(?im)^[ \t]*(?:gameName|gamePath|game_edition)[ \t]*=[^\r\n]*(?:\r?\n|$)','')
    $gamePath = $Game.Replace('\','/')
    $newSection = "[General]`r`ngameName=New Vegas`r`ngamePath=`"$gamePath`"`r`ngame_edition=$edition`r`n" + $rest
    if ($section.Success) { $config = $config.Substring(0,$section.Index) + $newSection + $config.Substring($section.Index+$section.Length) }
    else { $config = $newSection + "`r`n" + $config }
    if (-not $configured -and -not $name -and -not [IO.Directory]::Exists((Join-Path $Organizer 'profiles\Default'))) {
        $settings = [regex]::Match($config,'(?im)^\[Settings\][ \t]*(?:\r?\n|$)')
        $defaults = ''
        if (-not (Get-TTWMo2Setting $config 'Settings' 'profile_local_inis')) { $defaults += "profile_local_inis=true`r`n" }
        if (-not (Get-TTWMo2Setting $config 'Settings' 'profile_local_saves')) { $defaults += "profile_local_saves=true`r`n" }
        if ($settings.Success) { $config = $config.Insert($settings.Index+$settings.Length,$defaults) }
        elseif ($defaults) { $config = $config.TrimEnd() + "`r`n`r`n[Settings]`r`n" + $defaults }
    }
    if (Get-Process -Name 'ModOrganizer' -ErrorAction SilentlyContinue) { throw 'Close Mod Organizer 2 so setup can save the selected New Vegas folder.' }
    $config = Update-TTWStockMo2Executables $config $Game
    Write-PCVRAtomicText -Path $ini -Value $config
    if ((Get-TTWIniGame $ini) -ine $Game) { throw 'Could not verify the New Vegas path in the portable MO2 settings.' }
}

function Test-TTWMo2ProfileOptions($Profile) {
    if (-not $Profile) { return $false }
    $ini = Join-Path $Profile.profile 'settings.ini'
    if (-not [IO.File]::Exists($ini)) { return $false }
    $settings = [IO.File]::ReadAllText($ini)
    return ((Get-TTWMo2Setting $settings 'General' 'LocalSettings') -ieq 'true' -and
            (Get-TTWMo2Setting $settings 'General' 'LocalSaves') -ieq 'true')
}

function Initialize-TTWDefaultProfileInis([string]$Organizer, [string]$Game, [string]$Documents = [Environment]::GetFolderPath('MyDocuments')) {
    $config = [IO.File]::ReadAllText((Join-Path $Organizer 'ModOrganizer.ini'))
    # Only touch the standard profile in the Hub's own portable instance.
    if ((Get-TTWMo2Setting $config 'Settings' 'base_directory') -or
        (Get-TTWMo2Setting $config 'Settings' 'profiles_directory')) { return }
    $profiles = Join-Path $Organizer 'profiles'
    $default = Join-Path $profiles 'Default'
    foreach ($folder in @($Organizer,$profiles,$default)) {
        if ([IO.Directory]::Exists($folder) -and ([IO.File]::GetAttributes($folder) -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'The portable MO2 profile uses a linked folder. Choose an ordinary folder before retrying.'
        }
    }

    $name = if ((Get-TTWMo2Setting $config 'General' 'game_edition') -ieq 'Epic Games') { 'FalloutNV_Epic' } else { 'FalloutNV' }
    $source = if ($Documents) { Join-Path $Documents "My Games/$name" }
    # MO2 normally copies these files from Documents when it creates Default,
    # carrying over the read-only bit. Seed just the two main INIs when both are available.
    $mainIni = if ($source) { Join-Path $source 'fallout.ini' }
    if (-not [IO.File]::Exists($mainIni)) { $mainIni = Join-Path $Game 'Fallout_default.ini' }
    $prefsIni = if ($source) { Join-Path $source 'falloutprefs.ini' }
    $seed = [IO.File]::Exists($mainIni) -and [IO.File]::Exists($prefsIni)
    foreach ($file in 'fallout.ini','falloutprefs.ini','falloutcustom.ini','GECKCustom.ini','GECKPrefs.ini') {
        $target = Join-Path $default $file
        if (-not [IO.File]::Exists($target) -and $seed) {
            $from = if ($file -ieq 'fallout.ini') { $mainIni } else { Join-Path $source $file }
            if ([IO.File]::Exists($from)) {
                [void][IO.Directory]::CreateDirectory($default)
                [IO.File]::Copy($from,$target)
            }
        }
        if (-not [IO.File]::Exists($target)) { continue }
        $attributes = [IO.File]::GetAttributes($target)
        if ($attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "The MO2 profile INI is a link: $target"
        }
        if ($attributes -band [IO.FileAttributes]::ReadOnly) {
            [IO.File]::SetAttributes($target,($attributes -band (-bnot [IO.FileAttributes]::ReadOnly)))
            Write-Host "  [OK] Profile INI made writable: $file" -ForegroundColor Green
        }
    }
}

function Invoke-TTWMo2([string]$Executable, [string]$Arguments) {
    # Start-Process -Wait assigns MO2 to a job. MO2 needs to break its game
    # processes out of that job and Windows rejects the launch with error 5.
    $process = Start-Process -FilePath $Executable -WorkingDirectory ([IO.Path]::GetDirectoryName($Executable)) -ArgumentList $Arguments -PassThru
    try {
        $process.WaitForExit()
        return $process.ExitCode
    } finally {
        $process.Dispose()
    }
}

function Get-TTWMo2LauncherEvidence([string]$Organizer, [string]$Game) {
    $logs = Join-Path $Organizer 'logs'
    try {
        $interface = [IO.File]::ReadAllText((Join-Path $logs 'mo_interface.log'))
        $starts = [regex]::Matches($interface,'(?m)^\[(\d{4}-\d{2}-\d{2}) (\d\d):(\d\d):(\d\d)\.\d{3} I\] starting Mod Organizer version [^\r\n]+')
        if (-not $starts.Count) { return }
        $start = $starts[$starts.Count - 1]
        $file = 'usvfs-{0}_{1}-{2}-{3}.log' -f $start.Groups[1].Value,$start.Groups[2].Value,$start.Groups[3].Value,$start.Groups[4].Value
        $evidence = @{
            Session = $start.Value
            Crashed = $interface.Substring($start.Index) -match '(?m)^\[[^\r\n]+ E\] ModOrganizer has crashed\b'
            LauncherStarted = $false
        }
        $trace = Join-Path $logs $file
        if ([IO.File]::Exists($trace)) {
            $launcher = [regex]::Escape((Join-Path $Game 'FalloutNVLauncher.exe'))
            $hooked = [regex]::Match([IO.File]::ReadAllText($trace),
                ('(?im)^inithooks called [^\r\n]+ in process ' + $launcher + ':(?<pid>\d+) \([^\r\n]*\r?\n(?:(?!^inithooks called )[^\r\n]*\r?\n)*?^inithooks in process \k<pid> successful\b'))
            $evidence.LauncherStarted = $hooked.Success
        }
        return $evidence
    } catch [IO.IOException] { return }
      catch [UnauthorizedAccessException] { return }
}

function Test-TTWLauncherProfile($Profile) {
    if (-not (Test-TTWMo2ProfileOptions $Profile)) { return $false }
    foreach ($name in 'fallout.ini','falloutprefs.ini') {
        $ini = [IO.FileInfo]::new((Join-Path $Profile.profile $name))
        if (-not $ini.Exists -or $ini.Length -eq 0) { return $false }
    }
    return $true
}

function Confirm-TTWMo2Launcher([string]$Organizer, [string]$Game, [string]$ReadyFile) {
    Write-Host '  Did the Fallout Launcher window open? Closing it with Exit or the window X is enough.' -ForegroundColor White
    while ($true) {
        $answer = Read-Host '  Y = launcher opened, R = reopen MO2, Q = cancel'
        switch (('' + $answer).Trim()) {
            'Y' {
                Initialize-TTWDefaultProfileInis $Organizer $Game
                Write-PCVRAtomicText -Path $ReadyFile -Value $Game
                return $true
            }
            'R' { return $false }
            'Q' { throw 'MO2 profile preparation cancelled.' }
        }
        if ($null -eq $answer) { throw [IO.EndOfStreamException]::new('Input ended while waiting for the Fallout Launcher confirmation.') }
        Write-Host '  Type Y, R, or Q and press Enter.' -ForegroundColor Yellow
    }
}

function Get-TTWNewPortableProfile([string]$Game,[string]$Root,[string]$Work) {
    $organizer = Join-Path $Root 'MO2'
    Install-TTWOrganizer $organizer $Work
    Initialize-TTWPortableGame $organizer $Game
    $existing = Get-TTWPortableProfile $organizer $Game ''
    $readyFile = Join-Path $Root 'mo2-launcher-checked.txt'
    if (Test-TTWLauncherProfile $existing) {
        if ([IO.File]::Exists($readyFile) -and [IO.File]::ReadAllText($readyFile) -ieq $Game) { return $existing }
        $lastRun = Get-TTWMo2LauncherEvidence $organizer $Game
        if ($lastRun.Crashed -and $lastRun.LauncherStarted) {
            Write-Host '  MO2 closed after starting the Fallout Launcher last time. The Default profile is saved.' -ForegroundColor Yellow
            if (Confirm-TTWMo2Launcher $organizer $Game $readyFile) { return $existing }
        }
    }
    if (@(Get-TTWMissingSourceFiles $Game @('FalloutNVLauncher.exe')).Count) {
        throw "FalloutNVLauncher.exe is missing from $Game. Verify Fallout: New Vegas in your store, then retry setup."
    }
    while ($true) {
        Write-Host ''
        Write-Host '  REQUIRED: Set up the New Vegas profile in Mod Organizer 2' -ForegroundColor Yellow
        Write-Host '  The Hub has already set the game folder:' -ForegroundColor Cyan
        Write-Host "    $Game"
        Write-Host '  1. First-run dialogs' -ForegroundColor Cyan
        Write-Host '     Category Setup: Do Nothing. Skip the tutorial and Nexus sign-in.' -ForegroundColor Green
        Write-Host '  2. Check the Default profile' -ForegroundColor Cyan
        Write-Host '     In the main window, select Default in the Profile list.' -ForegroundColor Green
        Write-Host '     Ctrl+P > Default > tick both boxes > Close.' -ForegroundColor Green
        Write-Host '       Use profile-specific Game INI Files' -ForegroundColor Green
        Write-Host '       Use profile-specific Save Games' -ForegroundColor Green
        Write-Host '  3. Start the game launcher from MO2' -ForegroundColor Cyan
        Write-Host '     Top-right list: Fallout Launcher > Run.' -ForegroundColor Green
        Write-Host '     If MO2 says INI file is read-only, click Clear the read-only flag (first option).' -ForegroundColor Yellow
        Write-Host '     Allow the write once restores the flag, so the dialog can return.' -ForegroundColor Yellow
        Write-Host '  4. Finish and return to the Hub' -ForegroundColor Cyan
        Write-Host '     Wait for the Fallout Launcher menu. If a hardware detection dialog appears, click OK.' -ForegroundColor Green
        Write-Host '     In the launcher, click Exit. This step only checks that the launcher opens.' -ForegroundColor Green
        Write-Host '     If MO2 is still open, close it. Back in the Hub, type Y and press Enter.' -ForegroundColor Green
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the portable Mod Organizer 2 instance...')
        if (Get-Process -Name 'ModOrganizer' -ErrorAction SilentlyContinue) { throw 'Close the other Mod Organizer 2 window, then retry.' }
        Initialize-TTWDefaultProfileInis $organizer $Game
        $before = Get-TTWMo2LauncherEvidence $organizer $Game
        $exitCode = Invoke-TTWMo2 (Join-Path $organizer 'ModOrganizer.exe') '-p Default'
        $profile = Get-TTWPortableProfile $organizer $Game ''
        if (-not $profile) {
            Write-Host "  MO2 did not save the Default profile for $Game. Reopen MO2 and check Settings > Paths > Managed Game." -ForegroundColor Yellow
        } elseif (-not (Test-TTWLauncherProfile $profile)) {
            Write-Host '  The Default profile needs both profile options and saved INI files. Reopen MO2 and check step 2.' -ForegroundColor Yellow
        } else {
            $after = Get-TTWMo2LauncherEvidence $organizer $Game
            $startedThisRun = $after.LauncherStarted -and $after.Session -cne $before.Session
            if ($null -ne $exitCode -and ($exitCode -eq 0 -or ($after.Crashed -and $startedThisRun))) {
                if ($exitCode -ne 0) {
                    Write-Host "  MO2 closed with code $exitCode after starting the Fallout Launcher. The Default profile is saved." -ForegroundColor Yellow
                }
                if (Confirm-TTWMo2Launcher $organizer $Game $readyFile) { return $profile }
                continue
            }
            Write-Host "  MO2 closed with code $exitCode. Its log did not confirm the Fallout Launcher started in this run." -ForegroundColor Yellow
        }
        while ($true) {
            $action = Read-Host '  R = reopen MO2, Q = cancel'
            if ($action -ieq 'R') { break }
            if ($action -ieq 'Q') { throw 'MO2 profile preparation cancelled.' }
            if ($null -eq $action) { throw [IO.EndOfStreamException]::new('Input ended before the MO2 retry choice.') }
            Write-Host '  Type R or Q and press Enter.' -ForegroundColor Yellow
        }
    }
}

function Set-TTWFirstRunDefaults($Profile) {
    $ini = Join-Path $Profile.profile 'FalloutCustom.ini'
    # A prepared profile can contain intentional custom settings. Seed only a new one.
    if ([IO.File]::Exists($ini) -and (Get-Item -LiteralPath $ini).Length -gt 0) { return }
    $settings = @(
        '[General]','SCharGenQuest=001FFFF8','SIntroMovie=','bPreemptivelyUnloadCells=1','iNumHWThreads=3',
        '[Audio]','bMultiThreadAudio=1','bUseAudioDebugInformation=0','iAudioCacheSize=16384','iMaxSizeForCachedSound=2048',
        '[BackgroundLoad]','bSelectivePurgeUnusedOnFastTravel=1','bBackgroundLoadLipFiles=1',
        '[Display]','iTexMipMapSkip=0','[BlurShaderHDR]','bDoHighDynamicRange=1','[BlurShader]','bUseBlurShader=0'
    )
    Write-PCVRAtomicText -Path $ini -Value ($settings -join [Environment]::NewLine)
}

function Confirm-TTWFlatProfile($Profile) {
    Write-Host '  This check starts the converted game without VR. At the main menu, exit the game.'
    while ($true) {
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start the flat TTW check...')
        $exe = Join-Path $Profile.game 'FalloutNV.exe'
        $arguments = '-p "' + $Profile.profileName + '" "' + $exe + '"'
        $exitCode = Invoke-TTWMo2 $Profile.mo2 $arguments
        $closedNormally = $null -ne $exitCode -and $exitCode -eq 0
        if (-not $closedNormally) { Write-Host "  The flat game check ended with MO2 exit code $exitCode." -ForegroundColor Yellow }
        while ($true) {
            $prompt = if ($closedNormally) { 'Y = reached the main menu, R = retry, Q = stop' } else { 'R = retry, Q = stop' }
            $choice = Read-Host "  $prompt"
            if ($null -eq $choice) { throw [IO.EndOfStreamException]::new('Input ended at the flat game check.') }
            $choice = $choice.Trim()
            if ($choice -ieq 'Y' -and $closedNormally) { return }
            if ($choice -ieq 'Q') { throw 'Stopped before installing VR.' }
            if ($choice -ieq 'R') { break }
        }
    }
}

function Get-TTWPreparedProfile([string]$Game, $Saved, [string]$Root, [string]$Work) {
    if ($Saved) {
        $profile = Get-TTWPortableProfile (Split-Path -Parent $Saved.mo2) $Game $Saved.profile
        if ($profile) {
            if ($profile.mo2 -ieq (Join-Path $Root 'MO2\ModOrganizer.exe')) {
                Initialize-TTWPortableGame (Split-Path -Parent $profile.mo2) $Game
            }
            return $profile
        }
    }
    while ($true) {
        $choice = Read-Host '  Enter = set up the Hub profile, P = choose an existing portable MO2 profile, Q = cancel'
        if ($null -eq $choice -or $choice.Trim() -ieq 'Q') { throw 'TTW profile selection cancelled.' }
        $choice = $choice.Trim()
        if (-not $choice -or $choice -ieq 'N') { return Get-TTWNewPortableProfile $Game $Root $Work }
        if ($choice -ieq 'P') { break }
    }
    while ($true) {
        $path = Read-Host '  Paste the TTW MO2 profile folder (contains modlist.txt), or Q to cancel'
        if (-not $path -or $path -ieq 'Q') { throw 'TTW profile selection cancelled.' }
        $path = $path.Trim().Trim('"').Trim("'")
        if ([IO.File]::Exists($path)) { $path = Split-Path -Parent $path }
        if (-not [IO.Directory]::Exists($path) -or -not [IO.File]::Exists((Join-Path $path 'modlist.txt'))) {
            Write-Host '  Choose the profile folder that contains modlist.txt.' -ForegroundColor Yellow
            continue
        }
        $path = (Get-Item -LiteralPath $path).FullName
        $organizer = Split-Path -Parent (Split-Path -Parent $path)
        if (-not $organizer -or -not [IO.File]::Exists((Join-Path $organizer 'ModOrganizer.exe'))) {
            $organizer = Read-Host '  Paste the portable MO2 folder containing ModOrganizer.exe, or Q to cancel'
            if (-not $organizer -or $organizer -ieq 'Q') { throw 'MO2 selection cancelled.' }
            $organizer = $organizer.Trim().Trim('"').Trim("'")
        }
        $profile = Get-TTWPortableProfile $organizer '' $path
        if (-not $profile) {
            Write-Host '  Select a portable MO2 profile that manages a complete New Vegas installation.' -ForegroundColor Yellow
            continue
        }
        if (Test-TTWProtectedGameFolder $profile.game) {
            Write-Host '  This profile uses New Vegas under Program Files. Choose a profile with a game folder outside it.' -ForegroundColor Yellow
            continue
        }
        if ([IO.File]::Exists((Join-Path $profile.game 'd3d9.dll')) -or -not (Test-InstallerTargetWritable (Join-Path $profile.game '.pcvrhub_write_target'))) {
            Write-Host '  Choose a profile with a writable New Vegas folder without a D3D9 wrapper.' -ForegroundColor Yellow
            continue
        }
        return $profile
    }
}

function Show-TTWVRSetupFinish {
    Write-Host '  Connect your headset, then select Start in VR in the Hub.' -ForegroundColor Green
    Write-Host '  On Quest with Virtual Desktop, turn on Forward Tracking Data under Streaming and use VDXR.'
    Write-Host '  In game, extend both arms straight forward and hold both triggers until they vibrate.'
    Write-Host ''
    Write-Host '  Two wastelands. One Pip-Boy. Try not to spend all your caps in one place.' -ForegroundColor Magenta
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup.')
}

function Update-TTWVRMod([string]$Mode, $Profile, [string]$Root, [string]$Work) {
    if (Get-Process -Name 'ModOrganizer','FalloutNV','FalloutNVLauncher' -ErrorAction SilentlyContinue) {
        throw 'Close Mod Organizer 2 and Fallout: New Vegas, then retry the TTWVR update.'
    }
    Write-Host ''
    Write-Host "  Update TTWVR only in MO2 profile: $($Profile.profileName)" -ForegroundColor Cyan
    Write-Host '  Setup reuses your game files, MO2 profile and installed requirements.'
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to update TTWVR only...')
    Write-Host ''
    Write-Host '  --- [1/2] Getting the TTWVR update from Discord ---' -ForegroundColor Cyan
    $stage = Get-TTWVRStage $Work
    if (-not $stage) { throw 'TTWVR update cancelled before any mod files were changed.' }
    $version = Read-TTWVRReleaseVersion -Stage $stage
    Write-Host ''
    Write-Host '  --- [2/2] Updating and verifying TTWVR ---' -ForegroundColor Cyan
    Install-TTWVRProfile $Mode $Profile $stage $Root $Work @() $version -ModOnly
    Write-Host "  [OK] TTWVR $version installed in the existing profile." -ForegroundColor Green
    Show-TTWVRSetupFinish
}

function Invoke-TTWVRSetup([string]$Mode) {
    $work = Join-Path ([IO.Path]::GetTempPath()) ('pcvr-ttwvr-' + [guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($work)
    try {
        $env:PCVR_HUB_RECOVERY_PAGE = $script:TTWChannel
        $root = Join-Path $env:LOCALAPPDATA "PCVR Mods Installer Hub\TTWVR\$Mode"
        $combined = $Mode -eq 'Wastelands'
        $setupTitle = if ($combined) { 'A Tale of Two Realities - Fallout 3 + New Vegas' } else { 'TTWVR - New Vegas only' }
        Write-Host "  $setupTitle" -ForegroundColor Cyan
        Write-Host '  Close Fallout and Mod Organizer 2 before continuing.'
        Show-AntivirusNotice -Compact
        $saved = Get-TTWInstalledState $root $Mode -ForModUpdate
        if ($saved) {
            Update-TTWVRMod $Mode $saved $root $work
            return
        }
        if ([IO.File]::Exists((Join-Path $root 'ttwvr-install.json'))) {
            Write-Host ''
            Write-Host '  The saved MO2 profile could not be verified for a TTWVR-only update.' -ForegroundColor Yellow
            Write-Host '  Check that the saved profile still points to the same game and its required mods are enabled.'
            $repair = Read-Host '  R = run full setup to repair the profile, Enter = cancel'
            if ($repair -ine 'R') { throw 'TTWVR update cancelled before changing the existing profile.' }
        }
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check your installed games...')
        Write-Host ''
        Write-Host '  --- [1/4] Checking original games ---' -ForegroundColor Cyan
        $conversion = if ($combined) { Get-TTWConversionProgress $root }
        $previous = if ($saved) { $saved } else { $conversion }
        if ($conversion -and -not $saved) {
            $message = switch ($conversion.stage) {
                'converter-open' { 'The converter was opened. Setup will check for its output.' }
                'output-needed' { 'The converter closed. Select its output folder to continue.' }
                'copying' { 'The previous import started. Setup can reuse the original converted files.' }
                'conversion-ready' { 'The converted files were verified. Setup will check them again before continuing with MO2.' }
                'profile-ready' { 'TTW data and load order were set up in MO2. Setup will check the files again before continuing.' }
            }
            Write-Host "  Previous TTW progress: $message" -ForegroundColor Cyan
            if ($conversion.destination) { Write-Host "  MO2 location: $($conversion.destination)" }
            if ($conversion.source -and $conversion.source -ine $conversion.destination) { Write-Host "  Converted files: $($conversion.source)" }
        }
        $game = Get-TTWGame 'NewVegas' $(if ($previous) { $previous.game }) -ForConversion:$combined
        Write-Host "  [OK] New Vegas source: $game" -ForegroundColor Green
        $fallout3 = if ($combined) { Get-TTWGame 'Fallout3' $(if ($previous) { $previous.fallout3 }) -ForConversion -Root $root }
        if ($fallout3) { Write-Host "  [OK] Fallout 3 source: $fallout3" -ForegroundColor Green }
        if (Get-Process -Name 'ModOrganizer','FalloutNV','FalloutNVLauncher' -ErrorAction SilentlyContinue) { throw 'Close MO2 and Fallout: New Vegas, then retry.' }
        if ((Test-TTWProtectedGameFolder $game) -or [IO.File]::Exists((Join-Path $game 'd3d9.dll')) -or
            -not (Test-InstallerTargetWritable -TargetPath (Join-Path $game '.pcvrhub_write_target'))) {
            Write-Host ''
            Write-Host '  New Vegas needs its own copy for TTWVR' -ForegroundColor Cyan
            $game = New-TTWPrivateGame $game $root $fallout3
            Write-Host "  New Vegas for TTWVR: $game" -ForegroundColor Cyan
        }
        if ($Mode -eq 'NewVegas' -and [IO.File]::Exists((Join-Path $game 'd3d9.dll'))) { throw 'Use a clean New Vegas root without the FNVVR or DXVK d3d9.dll wrapper.' }
        Write-Host ''
        Write-Host '  --- [2/4] Preparing the MO2 profile and prerequisites ---' -ForegroundColor Cyan
        Install-TTWVCRuntimes $work
        $dependencies = @()
        if ($Mode -eq 'NewVegas') {
            $profile = Get-TTWNewPortableProfile $game $root $work
        } else {
            $profile = Get-TTWPreparedProfile $game $previous $root $work
            $game = $profile.game
            if ([IO.File]::Exists((Join-Path $game 'd3d9.dll'))) { throw 'The selected TTW profile uses a New Vegas folder with a D3D9 wrapper. Choose a clean profile and game folder.' }
            Start-TTWConversion $profile $fallout3 $work $root
            $profile.fallout3 = $fallout3
        }
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check xNVSE and the required New Vegas mods.')
        $dependencies = @(Install-TTWDependencies $game $work $profile)
        if ($Mode -eq 'Wastelands') {
            $dependencies += @(Install-TTWEssentials $profile $work)
            Set-TTWFirstRunDefaults $profile
            if ($dependencies.Count) { Set-TTWProfileMods (Join-Path $profile.profile 'modlist.txt') $dependencies }
            $previousVr = @(Get-TTWActiveMods (Join-Path $profile.profile 'modlist.txt') $profile.mods |
                Where-Object { Test-TTWFiles $_ @('NVSE/Plugins/TTWVR.dll') }).Count
            if (-not $previousVr) { Confirm-TTWFlatProfile $profile }
        }
        Write-Host "  [OK] MO2 profile: $($profile.profileName)" -ForegroundColor Green
        Write-Host ''
        Write-Host '  --- [3/4] Getting the Discord package ---' -ForegroundColor Cyan
        $stage = Get-TTWVRStage $work
        $version = Read-TTWVRReleaseVersion -Stage $stage
        Write-Host ''
        Write-Host '  --- [4/4] Installing and verifying the VR mod ---' -ForegroundColor Cyan
        Install-TTWVRProfile $Mode $profile $stage $root $work $dependencies $version
        Show-TTWVRSetupFinish
    } catch {
        Write-Host ('  [XX] ' + $_.Exception.Message) -ForegroundColor Red
        if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
        # The outer Hub wrapper provides the retry prompt and re-enters this
        # route with the selected recovery file or folder.
        throw
    } finally {
        $tempPrefix = Join-Path ([IO.Path]::GetTempPath()) 'pcvr-ttwvr-'
        if ($work.StartsWith($tempPrefix,[StringComparison]::OrdinalIgnoreCase) -and [IO.Directory]::Exists($work)) {
            Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($env:PCVR_TTWVR_LIBRARY_ONLY -ne '1') { Invoke-TTWVRSetup $Mode }
