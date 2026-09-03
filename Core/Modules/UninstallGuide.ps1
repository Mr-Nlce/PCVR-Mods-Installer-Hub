# Explorer shortcuts for the uninstall guide. These helpers never run or delete
# a referenced file; even an .exe or .bat is only selected in its parent folder.

function global:Get-UninstallSourceUrl {
    param($Game)
    foreach ($candidate in @($Game.ModPageUrl, $Game.InfoUrl, $Game.DownloadUrl)) {
        if ($candidate -and ([string]$candidate -match '^https?://')) { return [string]$candidate }
    }
    return $null
}

# Safe-by-default guide builder. A missing per-game guide must NEVER turn into
# "uninstall the base game and delete its folder". That old fallback destroyed
# unrelated files, other mods and occasionally a user-supplied game copy.
#
# Exact catalog guides still win, except for the old repeated BepInEx/MelonLoader
# boilerplate. Those instructions deleted entire shared loader folders and are
# replaced here with the verified VR marker plus a warning about shared files.
function global:Get-SafeUninstallSteps {
    param(
        $Game,
        [bool]$HasSteamArgs = $false,
        [string]$StandaloneFolderPath = $null
    )

    $explicit = @($Game.UninstallSteps | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    $explicitText = $explicit -join ' '
    $legacySharedLoaderGuide = $explicitText -match '(?i)(delete\s+(?:the\s+)?(?:whole\s+)?[''"]?BepInEx|delete\s+winhttp\.dll\s+and\s+the\s+BepInEx\s+folder|delete\s+Mods\\,\s+UserLibs\\,\s+MelonLoader)'
    if ($explicit.Count -gt 0 -and -not $legacySharedLoaderGuide) { return $explicit }

    $markers = New-Object 'System.Collections.Generic.List[string]'
    foreach ($field in @('ModFile','ModFileAlt','ModFileAlt2','ModAProbeFile','ModBProbeFile','FlatVREnabled','FlatVRDisabled')) {
        foreach ($raw in @($Game.$field)) {
            foreach ($part in @(([string]$raw) -split '\|')) {
                $clean = $part.Trim()
                if ($clean -and -not $markers.Contains($clean)) { [void]$markers.Add($clean) }
            }
        }
    }
    $markerText = if ($markers.Count) { (($markers | ForEach-Object { "'$_'" }) -join ', ') } else { $null }
    $isBepInEx = ($markers | Where-Object { $_ -match '(?i)(^|\\)BepInEx\\' } | Select-Object -First 1) -or $explicitText -match '(?i)BepInEx'
    $isMelon = ($markers | Where-Object { $_ -match '(?i)(^|\\)Mods\\.*\.dll$' } | Select-Object -First 1) -or $explicitText -match '(?i)MelonLoader'
    $isReal = ($Game.Bat -and ([string]$Game.Bat -like 'LukeRossVR*')) -or $Game.Mod -match 'R\.E\.A\.L\.'
    $isRaiManager = ($Game.Type -eq 'itch' -and (Get-UninstallSourceUrl $Game) -match '(?i)raicuparta')
    $steps = New-Object 'System.Collections.Generic.List[string]'

    [void]$steps.Add("Close $($Game.Title) and its launcher before changing files.")
    if ($HasSteamArgs) {
        [void]$steps.Add('Clear only the VR mod arguments from Steam Launch Options. Keep unrelated arguments you added yourself.')
    }

    if ($Game.UninstallExe) {
        [void]$steps.Add("Use 'Uninstall now' beside this guide when it is available. The button only appears after the Hub has found an actual uninstaller file on disk.")
    }

    if ($isRaiManager) {
        [void]$steps.Add('Reopen the same RaiManager.exe used for installation, or click Open in the itch.io app, and choose its Uninstall option. This is the removal method published by the mod author.')
        [void]$steps.Add('The Hub does not guess where a downloaded RaiManager.exe was saved, so it will not show an automatic button for an unlocated copy.')
        [void]$steps.Add('Do not uninstall the base game and do not delete its installation folder.')
        return $steps.ToArray()
    }

    if ($isReal) {
        [void]$steps.Add("For temporary flat play, use the Flat / VR switch on this page. It parks RealRepo and the injector reversibly; it does not remove the game.")
        if ($markerText) { [void]$steps.Add("The Hub detects this installation through $markerText. Treat these as markers, not as permission to delete their parent game folders.") }
        [void]$steps.Add("For a full removal, use the file list supplied with the installed R.E.A.L. package. Remove only Luke Ross files and restore any package-created *_ori or backup file; shared injectors such as dxgi.dll may belong to ReShade or another mod.")
        [void]$steps.Add('Never uninstall the base game or delete the whole game folder just to remove R.E.A.L. VR.')
        return $steps.ToArray()
    }

    if ($isBepInEx) {
        [void]$steps.Add('For temporary flat play, use the Flat / VR switch on this page. It parks the VR loader or plugin and is fully reversible.')
        if ($markerText) { [void]$steps.Add("Remove only the VR-specific plugin path or parked counterpart that applies to this install: $markerText.") }
        [void]$steps.Add("Do not delete the whole BepInEx folder, Plugins folder, config folder, or winhttp.dll while another mod may use them. Those are shared loader components, not proof that every file belongs to this VR mod.")
        [void]$steps.Add('For a completely clean loader removal, compare the installed files with the package on the linked mod page and remove only matching package files. A store file check can restore changed game files, but it does not reliably remove added mod files.')
        return $steps.ToArray()
    }

    if ($isMelon) {
        if ($markerText) { [void]$steps.Add("Remove only the VR mod assembly or parked counterpart that applies to this install: $markerText.") }
        [void]$steps.Add("Keep the shared Mods, Plugins and UserData folders if they contain anything else. Do not delete another mod's files or configuration.")
        [void]$steps.Add('Only if no other mod uses MelonLoader, its official manual removal is version.dll plus the MelonLoader folder. Back up UserData first; removing the loader is optional after the VR assembly is gone.')
        return $steps.ToArray()
    }

    if ($StandaloneFolderPath -or $Game.StandaloneVR) {
        $dedicated = if ($StandaloneFolderPath) { $StandaloneFolderPath } else { 'the dedicated VR install folder shown by the Hub' }
        [void]$steps.Add("This entry uses a separate VR build. Before removing '$dedicated', back up saves, settings, game dumps, ROMs and any other files you supplied or created there.")
        [void]$steps.Add('Use Open game folder and verify that it is the dedicated VR copy, not your normal Steam, GOG, Epic or original game folder.')
        [void]$steps.Add('Only after that check, remove the dedicated VR folder and its shortcut. Never delete the original game or source dump.')
        return $steps.ToArray()
    }

    if ($Game.Title -eq 'Grand Theft Auto V VR') {
        [void]$steps.Add("Remove only the R.E.A.L. files from the copy you modded: RealVR.ini, the 'asi' folder, ScriptHookV.dll, dinput8.dll, RealConfig.bat and RealRepo; GTAVR.asi and openvr_api.dll apply only if you added motion controls.")
        [void]$steps.Add('If RealConfig created settings_ori.xml, restore it as settings.xml. Do not uninstall GTA V and do not delete the whole game folder.')
        return $steps.ToArray()
    }
    if ($Game.Title -eq 'No One Lives Forever 2 VR') {
        [void]$steps.Add("Restore only the files saved in '_backup_pre_REAL', then remove VR.rez, VRlaunchcmds.txt and NOLF2Revive. Keep the retail game and personal saves.")
        [void]$steps.Add('Do not delete the whole NOLF2 folder. Use its normal Windows uninstaller only if you intend to remove the base game too.')
        return $steps.ToArray()
    }

    if ($markerText) {
        [void]$steps.Add("The Hub verifies the VR installation with $markerText. This identifies the mod but is not automatically a complete removal list.")
    }
    [void]$steps.Add('Open the linked mod page below and compare its current package or author removal section with the files in your game folder. Remove only files confirmed to belong to this VR mod.')
    [void]$steps.Add('If the mod replaced an original game file and supplied no backup or uninstaller, preserve your settings and use the store launcher repair/verify command. Verification restores original files but may leave added mod files behind.')
    [void]$steps.Add('Never uninstall the base game or delete the whole game folder just to remove a VR mod.')
    return $steps.ToArray()
}

function global:Get-UninstallGuideContext {
    param($Game)
    if (-not $global:InstalledScanCompleted -or $global:ScanInProgress -or $global:ScanQueued) { return $null }
    if (-not $Game -or -not $global:gameStateMap) { return $null }
    if ($global:InstalledScanFailedGames -and $global:InstalledScanFailedGames.ContainsKey($Game.Title)) { return $null }
    $state = $global:gameStateMap[$Game.Title]
    if (-not $state -or $state.State -notin @('ready', 'update')) { return $null }
    $gameDir = [string]$state.GameDir
    if (-not $gameDir -or -not (Test-Path -LiteralPath $gameDir -PathType Container)) { return $null }
    $roots = New-Object 'System.Collections.Generic.List[string]'
    [void]$roots.Add([IO.Path]::GetFullPath($gameDir))
    foreach ($dir in @($state.CurrentDir, $state.DepotDir, $state.ModADir, $state.ModBDir)) {
        if ($dir -and (Test-Path -LiteralPath $dir -PathType Container)) {
            $full = [IO.Path]::GetFullPath($dir)
            if (-not $roots.Contains($full)) { [void]$roots.Add($full) }
        }
    }
    if ($Game.VrInstallRoot) {
        $vrRoot = Resolve-VrInstallRoot $Game.VrInstallRoot
        if ($vrRoot -and (Test-Path -LiteralPath $vrRoot -PathType Container) -and -not $roots.Contains($vrRoot)) {
            [void]$roots.Add($vrRoot)
        }
    }
    return [pscustomobject]@{ Game = $Game; GameDir = $roots[0]; Roots = $roots.ToArray() }
}

function global:Resolve-StepFolder {
    param([string]$Raw, [string]$GameDir)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }
    $path = [Environment]::ExpandEnvironmentVariables($Raw.Trim().Trim('"', "'", '`'))
    # Do not interpret providers, unresolved variables, wildcards or URLs.
    if ($path -match '[%*?<>|"\x00-\x1f]' -or $path -match '^\w+://') { return $null }
    try {
        if ($path -match '^[A-Za-z]:[\\/]' -or $path -match '^\\\\[^\\]+\\[^\\]+') {
            $full = [IO.Path]::GetFullPath($path)
        } else {
            if (-not $GameDir -or $path -match '^[/\\]|:') { return $null }
            $root = [IO.Path]::GetFullPath($GameDir).TrimEnd('\')
            $full = [IO.Path]::GetFullPath("$root\$path")
            if (-not $full.StartsWith("$root\", [StringComparison]::OrdinalIgnoreCase) -and $full -ne $root) { return $null }
        }
        # !!! ASK .NET FIRST, AND ONLY THEN Get-Item. Every word in a
        # readme that looks path-shaped is probed here - "Start in VR",
        # "Optional", "Expand-Archive", a URL fragment - and almost all of
        # them do not exist. Get-Item -ErrorAction Stop turns each miss
        # into a terminating error; the catch below swallows it, but
        # Start-Transcript writes it to the install log anyway, and the
        # log filled up with dozens of "path cannot be found" entries
        # from ordinary prose.
        #
        # File.Exists and Directory.Exists return false for a missing OR
        # malformed path and never throw, so a miss costs nothing and
        # logs nothing. Get-Item now only ever runs on something real.
        if (-not ([IO.File]::Exists($full) -or [IO.Directory]::Exists($full))) { return $null }
        $item = Get-Item -LiteralPath $full -Force -ErrorAction Stop
        if ($item -isnot [IO.FileSystemInfo]) { return $null }
        # Get-Item can retain a directory's trailing separator. The same
        # folder must not become two competing candidates in the alias index.
        $itemPath = $item.FullName
        if ($item.PSIsContainer -and $itemPath.Length -gt [IO.Path]::GetPathRoot($itemPath).Length) { $itemPath = $itemPath.TrimEnd('\') }
        return [pscustomobject]@{
            Path = $itemPath
            Folder = $(if ($item.PSIsContainer) { $itemPath } else { $item.DirectoryName })
            Select = $(if ($item.PSIsContainer) { $null } else { $item.FullName })
        }
    } catch { return $null }
}

function global:Get-GuideAliasPattern {
    param([string]$Alias)
    # Permit sentence punctuation, but never match a fragment of a different
    # filename/path (dxgi.dll must not also match dxgi.dll.hubbak).
    return '(?<![\w.%+@/\\-])' + [regex]::Escape($Alias) + '(?![\w%+@/\\-]|\.[\w])'
}

function global:Get-UninstallGuideTargets {
    param($Context, [string[]]$Steps, [hashtable]$Ambiguous)
    $aliases = @{}
    if (-not $Context) { return $aliases }
    $text = $Steps -join "`n"
    $roots = New-Object 'System.Collections.Generic.List[string]'
    $seen = @{}
    $addRoot = {
        param([string]$Path)
        if ($Path -and -not $seen.ContainsKey($Path) -and $roots.Count -lt 64 -and (Test-Path -LiteralPath $Path -PathType Container)) {
            $seen[$Path] = $true
            [void]$roots.Add($Path)
        }
    }
    $addAlias = {
        param([string]$Alias, $Hit)
        if (-not $Alias -or -not $Hit -or -not [regex]::IsMatch($text, (Get-GuideAliasPattern $Alias), 'IgnoreCase')) { return }
        if (-not $aliases.ContainsKey($Alias)) { $aliases[$Alias] = @{} }
        $aliases[$Alias][$Hit.Path.TrimEnd('\')] = $Hit
    }
    foreach ($root in $Context.Roots) { & $addRoot $root }

    # Known binary/plugin locations supply context for bare names in subsequent
    # steps. No recursive search of the game or the user's drives is performed.
    foreach ($root in $Context.Roots) {
        foreach ($key in @('ModFile','ModFileAlt','ModFileAlt2','ModBProbeFile','GameExe','LaunchExe','UninstallExe','FlatVREnabled','FlatVRDisabled')) {
            foreach ($rel in @(([string]$Context.Game[$key]) -split '\|')) {
                if (-not $rel -or [IO.Path]::IsPathRooted($rel)) { continue }
                $parent = Split-Path $rel -Parent
                while ($parent) {
                    $hit = Resolve-StepFolder -Raw $parent -GameDir $root
                    if ($hit -and -not $hit.Select) { & $addRoot $hit.Folder }
                    $parent = Split-Path $parent -Parent
                }
            }
        }
    }

    # Explicit quoted paths and absolute/environment paths can contain spaces.
    # Try complete word prefixes, longest first, to separate a path from prose.
    $pathPattern = '(?<quote>[''"`])(?<quoted>[^''"`\r\n]+)\k<quote>|(?<path>(?:%[A-Za-z_][A-Za-z_0-9]*%|[A-Za-z]:\\|\\\\)[^,;''"`\r\n]*|[\w@#+.-]+[\\/][^\s,;''"`]+)'
    foreach ($match in [regex]::Matches($text, $pathPattern)) {
        $raw = if ($match.Groups['quoted'].Success) { $match.Groups['quoted'].Value } else { $match.Groups['path'].Value }
        $candidates = New-Object 'System.Collections.Generic.List[string]'
        [void]$candidates.Add($raw.TrimEnd())
        foreach ($space in @([regex]::Matches($raw, '\s+') | Sort-Object Index -Descending)) {
            [void]$candidates.Add($raw.Substring(0, $space.Index))
        }
        foreach ($candidate in $candidates) {
            # Win32 silently ignores a trailing dot when opening a directory;
            # keep the sentence's full stop outside the clickable path.
            $candidate = $candidate.TrimEnd('.')
            # Try the literal name first: parentheses/brackets may be filename
            # characters. Only then strip punctuation belonging to the sentence.
            $found = $false
            foreach ($clean in @($candidate, $candidate.TrimEnd('.', ')', ']', ':'))) {
                foreach ($root in @($roots.ToArray())) {
                    $hit = Resolve-StepFolder -Raw $clean -GameDir $root
                    if ($hit) {
                        & $addAlias $clean $hit
                        & $addRoot $hit.Folder
                        $found = $true
                    }
                }
                if ($found) { break }
            }
            if ($found) { break }
        }
    }

    # Inspect only the immediate children of known/referenced directories. An
    # explicitly mentioned child directory may contribute its own children.
    # This also finds extensionless files, @mod folders and names with spaces.
    for ($index = 0; $index -lt $roots.Count; $index++) {
        $root = $roots[$index]
        $items = @((Get-Item -LiteralPath $root -Force -ErrorAction SilentlyContinue))
        $items += @(Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue)
        foreach ($item in $items) {
            if (-not $item) { continue }
            $hit = [pscustomobject]@{
                Path = $item.FullName
                Folder = $(if ($item.PSIsContainer) { $item.FullName } else { $item.DirectoryName })
                Select = $(if ($item.PSIsContainer) { $null } else { $item.FullName })
            }
            $names = @($item.Name, $item.FullName)
            foreach ($base in $Context.Roots) {
                $prefix = $base.TrimEnd('\') + '\'
                if ($item.FullName.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                    $relative = $item.FullName.Substring($prefix.Length)
                    $names += $relative
                    $names += ((Split-Path $base -Leaf) + '\' + $relative)
                    $names += $relative.Replace('\', '/')
                }
            }
            $mentioned = $false
            foreach ($name in $names) {
                if ([regex]::IsMatch($text, (Get-GuideAliasPattern $name), 'IgnoreCase')) {
                    & $addAlias $name $hit
                    $mentioned = $true
                }
                if ($item.PSIsContainer) {
                    & $addAlias ($name + '\') $hit
                    if ([regex]::IsMatch($text, (Get-GuideAliasPattern ($name + '\')), 'IgnoreCase')) { $mentioned = $true }
                }
            }
            if ($mentioned -and $item.PSIsContainer -and -not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { & $addRoot $item.FullName }
        }
    }
    $targets = @{}
    foreach ($alias in $aliases.Keys) {
        # Multiple real files with the same name: show full-path links only.
        if ($aliases[$alias].Count -eq 1) { $targets[$alias] = @($aliases[$alias].Values)[0] }
        elseif ($null -ne $Ambiguous) { $Ambiguous[$alias] = $true }
    }
    $gameTarget = Resolve-StepFolder -Raw $Context.GameDir
    foreach ($label in @('game folder', "game's install folder", 'install folder', 'Browse local files', 'Show local files', 'Show folder')) {
        $targets[$label] = $gameTarget
    }
    if ($text -match '(?i)\bdesktop\b') {
        $desktop = Resolve-StepFolder -Raw ([Environment]::GetFolderPath('DesktopDirectory'))
        if ($desktop) { $targets['desktop'] = $desktop }
    }
    return $targets
}

function global:Open-UninstallGuideTarget {
    param($Game, $Target)
    if (-not (Get-UninstallGuideContext $Game) -or -not $Target) { return }
    try {
        if (-not (Test-Path -LiteralPath $Target.Folder -PathType Container)) { throw 'This folder no longer exists. Run Scan games to refresh the detected installation.' }
        $argument = '"' + $Target.Folder + '"'
        if ($Target.Select -and (Test-Path -LiteralPath $Target.Select -PathType Leaf)) {
            $argument = '/select,"' + $Target.Select + '"'
        }
        Start-Process -FilePath 'explorer.exe' -ArgumentList $argument -ErrorAction Stop | Out-Null
    } catch {
        [void][System.Windows.MessageBox]::Show($_.Exception.Message, 'Open folder', 'OK', 'Warning')
    }
}

function global:New-UninstallGuideLink {
    param([string]$Text, $Target, $Game, [string]$AccentHex = '#e99583')
    $link = New-Object System.Windows.Documents.Hyperlink
    [void]$link.Inlines.Add([System.Windows.Documents.Run]::new($Text))
    $link.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
    $link.ToolTip = if ($Target.Select) { "Show in Explorer: $($Target.Select)" } else { "Open folder: $($Target.Folder)" }
    $link.Add_Click({
        param($sender, $eventArgs)
        Open-UninstallGuideTarget -Game $Game -Target $Target
        $eventArgs.Handled = $true
    }.GetNewClosure())
    return $link
}

function global:Set-StepTextWithFolderLinks {
    param([System.Windows.Controls.TextBlock]$TextBlock, [string]$Text, $Targets, $Game, [string]$AccentHex = '#e99583')
    $TextBlock.Inlines.Clear()
    if (-not $Text) { return }
    if (-not $Targets -or -not $Targets.Count) { $TextBlock.Text = $Text; return }
    $patterns = @($Targets.Keys | Sort-Object Length -Descending | ForEach-Object { Get-GuideAliasPattern $_ })
    $position = 0
    foreach ($match in [regex]::Matches($Text, ($patterns -join '|'), 'IgnoreCase')) {
        if ($match.Index -gt $position) { [void]$TextBlock.Inlines.Add([System.Windows.Documents.Run]::new($Text.Substring($position, $match.Index - $position))) }
        [void]$TextBlock.Inlines.Add((New-UninstallGuideLink -Text $match.Value -Target $Targets[$match.Value] -Game $Game -AccentHex $AccentHex))
        $position = $match.Index + $match.Length
    }
    if ($position -lt $Text.Length) { [void]$TextBlock.Inlines.Add([System.Windows.Documents.Run]::new($Text.Substring($position))) }
}

function global:Update-UninstallGuideLinks {
    param($Guide = $global:DetailUninstallGuide)
    if (-not $Guide) { return }
    $context = Get-UninstallGuideContext $Guide.Game
    $Guide.Shortcuts.Inlines.Clear()
    if ($context) {
        $target = Resolve-StepFolder -Raw $context.GameDir
        $label = if (($Guide.Steps -join ' ') -match '(?i)Browse local files|Show local files|Show folder') { 'Alternative: open game folder here' } else { 'Open game folder' }
        [void]$Guide.Shortcuts.Inlines.Add((New-UninstallGuideLink -Text $label -Target $target -Game $Guide.Game))
        if ($Guide.Game.VrInstallRoot) {
            $modFolder = Resolve-StepFolder -Raw (Resolve-VrInstallRoot $Guide.Game.VrInstallRoot)
            if ($modFolder -and $modFolder.Folder -ne $context.GameDir) {
                [void]$Guide.Shortcuts.Inlines.Add([System.Windows.Documents.Run]::new('   |   '))
                [void]$Guide.Shortcuts.Inlines.Add((New-UninstallGuideLink -Text 'Open VR mod folder' -Target $modFolder -Game $Guide.Game))
            }
        }
        $Guide.Hint.Text = 'Click a folder to open it, or a file to select it in Explorer. The guide stays open while you switch windows.'
    } else {
        $Guide.Hint.Text = if (-not $global:InstalledScanCompleted) { 'Run Scan games to enable folder links for an installed game with a detected VR mod.' } else { 'Folder links require a completed Scan games check with both the game and its VR mod installed.' }
    }
    $Guide.Shortcuts.Visibility = if ($context) { 'Visible' } else { 'Collapsed' }
    # The expensive part is lazy; unopened guides do not enumerate directories.
    $targets = if ($Guide.Panel.Visibility -eq 'Visible') { Get-UninstallGuideTargets -Context $context -Steps $Guide.Steps } else { @{} }
    for ($i = 0; $i -lt $Guide.Steps.Count; $i++) {
        Set-StepTextWithFolderLinks -TextBlock $Guide.TextBlocks[$i] -Text $Guide.Steps[$i] -Targets $targets -Game $Guide.Game
    }
}
