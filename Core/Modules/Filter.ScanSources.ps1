. (Join-Path $PSScriptRoot 'GitHubTransport.ps1')

# The old Luke Ross fallback walked a complete game tree once per marker.
# A literal, streaming walk checks the binary without following junctions.
function global:Test-ScanLukeRossMarker {
    param([string]$Root,[switch]$AllowDxgi)
    if (-not $Root -or -not [IO.Directory]::Exists($Root)) { return $false }
    $cache=$null;$key=$Root.TrimEnd([char[]]'\/')+'|'+[bool]$AllowDxgi
    if($global:HubScanEvidenceCache){
        if(-not $global:HubScanEvidenceCache.ContainsKey('LukeRoss')){$global:HubScanEvidenceCache.LukeRoss=@{}}
        $cache=$global:HubScanEvidenceCache.LukeRoss
        if($cache.ContainsKey($key)){return [bool]$cache[$key]}
    }
    $found=$false
    $pending=[Collections.Generic.Stack[IO.DirectoryInfo]]::new()
    $pending.Push([IO.DirectoryInfo]::new($Root))
    while($pending.Count -gt 0 -and -not $found){
        $dir=$pending.Pop()
        try{
            foreach($entry in $dir.EnumerateFileSystemInfos()){
                if(($entry.Attributes -band [IO.FileAttributes]::Directory) -ne 0){
                    if(($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0){$pending.Push([IO.DirectoryInfo]$entry)}
                }elseif(($entry.Name -eq 'RealVR64.dll' -or ($entry.Name -eq 'dxgi.dll' -and ($AllowDxgi -or [IO.Directory]::Exists((Join-Path $dir.FullName 'RealRepo'))))) -and (Test-PCVRPublisherBinary -Path $entry.FullName)){
                    $found=$true;break
                }
            }
        }catch{ } # An unreadable subtree never prevents checking its siblings.
    }
    if($null -ne $cache){$cache[$key]=$found}
    return $found
}

# Paint one card from its recorded scan state. Shared by Rebuild-Lookups
# (style switch, single-game refresh, post-install refresh) and by the lazy
# card builder (CardTile.Lazy.ps1), which calls it the moment a placeholder
# becomes a real card. A placeholder only takes the Tag: its visuals are
# painted when it is built.
function global:Restore-CardVisualState {
    param($Card, $Game, $State)
    $card = $Card; $g = $Game; $state = $State
    if (-not $card -or -not $g -or -not $g.Title -or -not $state) { return }
    if ($g.UntestedInstaller -and (Get-Command Update-UntestedFeedbackReminder -ErrorAction SilentlyContinue)) {
        Update-UntestedFeedbackReminder -Card $card -Game $g -State $state
    }
    if ($card.Resources.Contains('cardLazy')) { $card.Tag = $state.Tag; return }
    if ($state.State -notin @('ready','update')) { Reset-HubCardInstallHover -Card $card }
    $becameReady = $state.Tag -eq 'vrinstalled' -and [string]$card.Tag -eq 'vrupdate'
    if ($becameReady) { Reset-CardUpdateHoverForReady -Card $card }
    $card.Tag = $state.Tag
    $accH = if ($state.Accent) { $state.Accent } else { $card.Resources.Item("baseAccent") }
    if (-not $accH) { $accH = "#666677" }
    $btnTxt = $card.Resources.Item("btnText")
    $btnBrd = $card.Resources.Item("btnBorder")
    $card.Effect = $null

    switch ($state.State) {
        "import" { Set-CardStateVisual -Card $card -BtnTxt $btnTxt -BtnBrd $btnBrd -State 'import' }
        "update" {
            # Update state: unified blue (#2563eb), regardless of accent.
            $UPDATE_BLUE = "#2563eb"
            $card.Background = New-CardTintBrush -BaseHex "#16161a" -TintHex $UPDATE_BLUE -TopAlpha 0.22 -MidAlpha 0.05
            $aA = ConvertTo-MediaColor $UPDATE_BLUE; $aB = ConvertTo-MediaColor "#16161a"
            $card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(
                [byte]([Math]::Round($aA.R*0.40 + $aB.R*0.60)),
                [byte]([Math]::Round($aA.G*0.40 + $aB.G*0.60)),
                [byte]([Math]::Round($aA.B*0.40 + $aB.B*0.60))
            ))
            $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $glow.Color = $aA; $glow.BlurRadius = 16; $glow.ShadowDepth = 0; $glow.Opacity = 0.55
            $card.Effect = $glow
            if ($btnTxt) {
                $btnTxt.Text = "Update"
                $btnTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#b9ccf4")
            }
            if ($btnBrd) {
                $btnBrd.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($UPDATE_BLUE)
                $btnBrd.BorderThickness = [System.Windows.Thickness]::new(0)
            }
            # Cap matches the update theme: blue, visible.
            $cap = $card.Resources.Item("accentCap")
            if ($cap) {
                $cap.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($UPDATE_BLUE)
                $cap.Visibility = [System.Windows.Visibility]::Visible
            }
            # Refresh resources so hover tint matches the new
            # state. Without these the rebuilt card would
            # hover in its original accent color, not blue.
            $card.Resources.Remove("baseBgBrush") | Out-Null
            $card.Resources.Remove("baseBdBrush") | Out-Null
            $card.Resources.Add("baseBgBrush", $card.Background)
            $card.Resources.Add("baseBdBrush", $card.BorderBrush)
            $card.Resources.Remove("baseAccent") | Out-Null
            $card.Resources.Add("baseAccent", $UPDATE_BLUE)
        }
        "ready" {
            $card.Background = New-CardTintBrush -BaseHex "#16161a" -TintHex "#46a05a" -TopAlpha 0.10 -MidAlpha 0.02
            $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1d2e22")
            if ($btnTxt) {
                $btnTxt.Text = if ($g.ExternalVrStartApp -and $state.BtnText) { $state.BtnText } else { 'VR Ready' }
                $btnTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
            }
            $fblR = $card.Resources.Item("freeBtnLabel")
            if ($fblR) { $fblR.Visibility = [System.Windows.Visibility]::Collapsed }
            if ($btnBrd) {
                $btnBrd.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
                $btnBrd.BorderThickness = [System.Windows.Thickness]::new(1)
                $btnBrd.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
            }
            # VR Ready is complete - no "action pending"
            # signal; hide the cap. Without this, a card
            # repainted via Rebuild-Lookups (single-game
            # refresh, post-install refresh) would keep the
            # cap from its previous default state and show
            # an accent stripe alongside the green Ready
            # outline.
            $cap = $card.Resources.Item("accentCap")
            if ($cap) { $cap.Visibility = [System.Windows.Visibility]::Collapsed }
        }
        default {
            # "installed": game found, no VR mod yet - blue tint
            if ($state.Tag -eq "installed") {
                $conv3 = [System.Windows.Media.BrushConverter]::new()
                $card.Background  = New-CardTintBrush -BaseHex "#16161a" -TintHex "#46a05a" -TopAlpha 0.18 -MidAlpha 0.06
                $card.BorderBrush = $conv3.ConvertFromString("#2a5c38")
                $card.BorderThickness = [System.Windows.Thickness]::new(1)
                if ($btnTxt) {
                    if ($state.BtnText) { $btnTxt.Text = $state.BtnText }
                    $btnTxt.Foreground = $conv3.ConvertFromString("#66dd88")
                }
                if ($btnBrd) {
                    $btnBrd.Background      = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
                    $btnBrd.BorderThickness = [System.Windows.Thickness]::new(1)
                    $btnBrd.BorderBrush     = $conv3.ConvertFromString("#2a5c38")
                }
                # Cap in matching green to signal "action
                # available: install the VR mod".
                $cap = $card.Resources.Item("accentCap")
                if ($cap) {
                    $cap.Background = $conv3.ConvertFromString("#5cb344")
                    $cap.Visibility = [System.Windows.Visibility]::Visible
                }
            } else {
                if ($btnTxt -and $state.BtnText) { $btnTxt.Text = $state.BtnText }
                # Free games: restore the accent glow + reveal the
                # FREE label on the button (matches the scan's
                # free-state painting so filter switches don't drop
                # it).
                if ($state.Tag -eq "free") {
                    try {
                        $glowAccP = if ($state.Accent) { $state.Accent } else { $card.Resources.Item("baseAccent") }
                        $card.Effect = $null
                        $card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush (Get-GlowColor $glowAccP)
                        $card.BorderThickness = [System.Windows.Thickness]::new(1)
                        $fblP = $card.Resources.Item("freeBtnLabel")
                        if ($fblP) { $fblP.Visibility = [System.Windows.Visibility]::Visible }
                    } catch {}
                }
            }
        }
    }
    if (($g.TwoMods -or $g.DualMode) -and (Get-Command Update-AlternativeModSplit -ErrorAction SilentlyContinue)) {
        Update-AlternativeModSplit -Card $card
    }
    if ($state.State -eq 'update') {
        $reloadForUpdate = $card.Resources.Item('reloadPill')
        if ($reloadForUpdate) {
            $updateLayout = Get-CardUpdateActionLayout -State $state
            $reloadForUpdate.ToolTip = if ($updateLayout.PillAction -eq 'Update') {
                Get-UpdateActionLabel -Game $g -State $state -Fallback 'Update Mod'
            } else { 'Start in VR' }
        }
    }
    Sync-FrostedCardState -Card $card -BtnTxt $btnTxt -BtnBrd $btnBrd
    # Refresh stored brushes so hover reflects current state
    if ($card.Resources.Contains("baseBgBrush")) { $card.Resources.Remove("baseBgBrush") }
    if ($card.Resources.Contains("baseBdBrush")) { $card.Resources.Remove("baseBdBrush") }
    $card.Resources.Add("baseBgBrush", $card.Background)
    $card.Resources.Add("baseBdBrush", $card.BorderBrush)
    if ($becameReady -and $card.IsMouseOver -and $btnBrd) {
        # An installer may finish while the pointer remains on its tile.
        # Recreate the ready hover without requiring the user to move it.
        $hover = New-Object System.Windows.Input.MouseEventArgs([System.Windows.Input.Mouse]::PrimaryDevice, 0)
        $hover.RoutedEvent = [System.Windows.Input.Mouse]::MouseEnterEvent
        $btnBrd.RaiseEvent($hover)
    }
}

# Build a card->game lookup - wrapped in function so Scale can rebuild it
function global:Rebuild-Lookups {
    param([string[]]$Titles=@())
    $global:allCards    = @()
    $global:allGameData = @()
    foreach ($child in $ownList.Children)   { $global:allCards += $child }
    foreach ($child in $ownListGP.Children) { $global:allCards += $child }
    foreach ($child in $extList.Children)   { $global:allCards += $child }
    foreach ($child in $untestedList.Children) { $global:allCards += $child }
    foreach ($g in $ownGames)               { $global:allGameData += $g }
    foreach ($g in $ownGamesGP)             { $global:allGameData += $g }
    foreach ($g in $externalGames)          { $global:allGameData += $g }

    # Every real list card carries its own game object in Resources. Pairing a
    # visual child with a catalog entry by array position is invalid after a
    # reorder and used to shift every later state onto the wrong card whenever
    # one build failed. Failure placeholders carry the same resource contract,
    # so scan coverage remains complete without relying on parallel arrays.
    $global:cardGameMap = @{}
    foreach ($card in $global:allCards) {
        $cardGame = $null
        try {
            if ($card -and $card.Resources -and $card.Resources.Contains('gameData')) {
                $cardGame = $card.Resources.Item('gameData')
            }
        } catch {}
        if ($cardGame) { $global:cardGameMap[$card] = $cardGame }
    }

    # Restore visual state from gameStateMap onto new cards.
    # We don't store brushes in the map (they're tied to disposed
    # cards) - we store the accent + state name and rebuild brushes
    # here using the same helpers that initial card creation uses.
    if (($global:gameStateMap -and $global:gameStateMap.Count -gt 0) -or $Titles.Count -gt 0) {
        foreach ($card in @($global:cardGameMap.Keys)) {
            $g = $global:cardGameMap[$card]
            if (-not $g -or -not $g.Title -or ($Titles.Count -gt 0 -and $g.Title -notin $Titles)) { continue }
            $state = $global:gameStateMap[$g.Title]
            if (-not $state) { if ($Titles.Count -gt 0) { Reset-HubCardInstallState -Card $card -Game $g }; continue }
            Restore-CardVisualState -Card $card -Game $g -State $state
        }
    }
}
$global:gameStateMap = @{}  # title -> @{Tag; BgColor; BorderColor; BtnText; BtnColor}
Rebuild-Lookups

# Reusable scan logic. Used by:
#   - the Check Installed button click (PreviewMouseLeftButtonDown)
#   - the post-install auto-refresh (Invoke-PostInstallRefresh)
# Side-effects: rebuilds $global:gameStateMap, repaints all cards,
# and updates the status pill text.

# A few large games need stronger evidence than "this folder exists". Steam,
# Epic and Rockstar uninstall only their own files, so a directory containing
# third-party VR hooks can survive indefinitely. Catalog proof groups are AND
# conditions; alternatives inside one group are separated by |. Only the
# matched fixed files are measured, keeping every normal scan constant-time.
function global:Get-CatalogSteamAppIds {
    param($Game)
    # Called once per catalog entry on every scan: a plain loop instead of a
    # three-stage pipeline (same result, same order, de-duplicated).
    $ids = [System.Collections.Generic.List[string]]::new()
    foreach ($raw in (@($Game.SteamId) + @($Game.SteamIdAlt) + @($Game.OriginalGameAppIds))) {
        $id = ('' + $raw).Trim()
        if ($id -match '^\d+$' -and -not $ids.Contains($id)) { $ids.Add($id) }
    }
    return @($ids)
}

function global:Test-BaseGameInstallProof {
    param($Game, [string]$Root, [switch]$Uncached)
    if(-not $Uncached -and $Game -and $Root -and $global:HubScanEvidenceCache){
        $games=$global:HubScanEvidenceCache.Base
        if(-not $games.ContainsKey($Game)){$games.Add($Game,[Collections.Generic.Dictionary[string,bool]]::new([StringComparer]::Ordinal))}
        $roots=$games[$Game]
        if($roots.ContainsKey($Root)){$global:HubScanEvidenceCache.BaseHits++;return $roots[$Root]}
        $result=[bool](Test-BaseGameInstallProof -Game $Game -Root $Root -Uncached)
        $roots[$Root]=$result
        return $result
    }
    # These four catalog entries are external emulators/injectors, not a
    # licensed title. Their executable or an arbitrary selected directory
    # must never establish that any original game is installed.
    if ($Game.OriginalProofKind -eq 'ExternalTool') { return $false }
    if ($Game.TtwvrRequiresFallout3) {
        $labBoundary = if ($global:HubFileSystemLabRoot) {
            [IO.Path]::GetFullPath($global:HubFileSystemLabRoot).TrimEnd('\') + '\'
        }
        if ($labBoundary -and (-not $Root -or
            -not [IO.Path]::GetFullPath($Root).StartsWith($labBoundary,[StringComparison]::OrdinalIgnoreCase))) { return $false }
        if (Get-PCVRTTWVRState -Root $Root -Mode Wastelands) { return $true }
        $core = if ($global:HubHelpersCoreRoot) { [string]$global:HubHelpersCoreRoot } elseif ($script:scriptDir) { [string]$script:scriptDir }
        if (-not $core) { return $false }
        . (Join-Path $core 'TTWVR\TTWVR-State.ps1')
        if (-not (Test-TTWFiles $Root $script:TTWRequirements.NewVegas)) { return $false }
        $candidates = @(
            foreach ($library in @(Get-HubSteamLibraries)) {
                foreach ($name in @('Fallout 3 goty','Fallout 3')) { Join-Path $library "steamapps\common\$name" }
            }
            if (-not $labBoundary) {
                foreach ($key in @('HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout3','HKLM:\SOFTWARE\Bethesda Softworks\Fallout3')) {
                    (Get-ItemProperty -LiteralPath $key -Name 'Installed Path' -ErrorAction SilentlyContinue).'Installed Path'
                }
            }
            $receipt = Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\TTWVR\Wastelands\ttwvr-install.json'
            if ([IO.File]::Exists($receipt)) {
                try { (Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json).fallout3 } catch {}
            }
            if (Get-Command Read-PersistentGameStateValue -ErrorAction SilentlyContinue) {
                foreach ($key in @('user_located','base_game_path')) {
                    Read-PersistentGameStateValue -Game @{Id='fallout-3-vr';Title='Fallout 3 VR';Bat='Fallout3VR\START_INSTALLER.bat'} -Name $key
                }
            }
        )
        foreach ($path in $candidates) {
            if ($labBoundary -and (-not $path -or
                -not [IO.Path]::GetFullPath($path).StartsWith($labBoundary,[StringComparison]::OrdinalIgnoreCase))) { continue }
            if (Test-TTWFiles $path $script:TTWRequirements.Fallout3) { return $true }
        }
        return $false
    }
    if ($Game.OriginalGameProofSets) {
        return Test-PCVRGameInstallProof -Root $Root -FileSets $Game.OriginalGameProofSets -MinimumBytes ([long]$Game.BaseGameProofMinBytes)
    }


    # Plain loop instead of a pipeline: this runs several times per detected
    # game on every scan.
    $groups = @(foreach ($g in @($Game.BaseGameProofFiles)) { if (-not [string]::IsNullOrWhiteSpace([string]$g)) { $g } })
    # Most newer entries carry an explicit multi-file proof contract. Older
    # entries commonly declare only GameExe, though, and that executable is
    # still the authoritative base-game proof. Returning true merely because
    # BaseGameProofFiles was omitted let a Steam-uninstalled folder containing
    # only third-party VR files remain Installed / VR Ready / Update (Nuclear
    # Option was the reproduced case). Keep truly unconfigured legacy entries
    # on their established path behaviour, but never ignore a declared EXE.
    if ($groups.Count -eq 0 -and -not [string]::IsNullOrWhiteSpace([string]$Game.GameExe)) {
        $groups = @([string]$Game.GameExe)
    }
    if ($groups.Count -eq 0) { return $true }
    if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }

    [int64]$matchedBytes = 0
    $counted = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($group in $groups) {
        $groupMatched = $false
        foreach ($relative in (([string]$group) -split '\|')) {
            $relative = $relative.Trim()
            if (-not $relative) { continue }
            try {
                $candidate = Join-HubPathLexical $Root $relative
                if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
                # A placeholder or a file that vanished while being inspected
                # is not original-game evidence. This is a usability check,
                # not a historical size/hash allowlist.
                $file = Get-Item -LiteralPath $candidate -ErrorAction Stop
                if ([int64]$file.Length -le 0) { continue }
                $full = [IO.Path]::GetFullPath($candidate)
                if ($counted.Add($full)) { $matchedBytes += [int64]$file.Length }
                $groupMatched = $true
                break
            } catch {}
        }
        if (-not $groupMatched) { return $false }
    }

    [int64]$minimum = 0
    try { if ($Game.BaseGameProofMinBytes) { $minimum = [int64]$Game.BaseGameProofMinBytes } } catch {}
    return ($minimum -le 0 -or $matchedBytes -ge $minimum)
}

# ---------------------------------------------------------------
# REGISTRY DISCOVERY (scan priority 4)
#
# Catches installs that live under a folder name the catalog cannot
# know: disc/retail setups, renamed folders, "Deluxe Edition" bundles,
# a user-chosen library on another drive. Windows keeps their folders
# in the Uninstall registry (Get-HubUninstallInstallRoots, Helpers.ps1).
#
# Built ONCE per scan, then every catalog entry is a dictionary lookup:
#   - by folder name: the last segment of SteamFolder / FallbackPaths
#   - by proof file:  GameExe or a first-group BaseGameProofFiles name
#     that sits directly in the folder (e.g. CoDSP.exe)
# Only top-level file NAMES are listed per folder, and only names some
# catalog entry asks for are kept - no recursion, no file reads.
#
# A lookup hit is only a candidate. Find-RegistryInstallRoot accepts it
# solely through Test-BaseGameInstallProof, and only for entries that
# DECLARE a proof (BaseGameProofFiles or GameExe) - a registry folder
# never counts on its name alone.
# ---------------------------------------------------------------
function global:Get-RegistryDiscoveryKeys {
    param($Game)
    # Runs once per catalog entry per scan, so it stays on plain .NET string
    # calls: no pipeline, no scriptblock, no regex. Keys are lower-case;
    # duplicates are harmless (the lookup de-duplicates candidates).
    $folders = [System.Collections.Generic.List[string]]::new()
    $files   = [System.Collections.Generic.List[string]]::new()
    $relativeFiles = [System.Collections.Generic.List[string]]::new()
    $sep = [char[]]'\/'
    $names = [System.Collections.Generic.List[string]]::new()
    if ($Game.SteamFolder) { $names.Add([string]$Game.SteamFolder) }
    foreach ($fp in @($Game.FallbackPaths)) {
        $s = [string]$fp
        if (-not $s) { continue }
        # Depot copies, MS Store layouts and AppData probes never appear
        # as Uninstall folders in this shape - leave them to priority 3.
        if ($s.StartsWith('STEAM_CONTENT', [StringComparison]::OrdinalIgnoreCase) -or
            $s.StartsWith('STEAM_COMMON', [StringComparison]::OrdinalIgnoreCase) -or
            $s.StartsWith('XBOX:', [StringComparison]::OrdinalIgnoreCase) -or
            $s.StartsWith('APPDATA:', [StringComparison]::OrdinalIgnoreCase)) { continue }
        foreach ($pre in 'STEAM:', 'GOG:', 'EPIC:', 'UBI:') {
            if ($s.StartsWith($pre, [StringComparison]::OrdinalIgnoreCase)) { $s = $s.Substring($pre.Length); break }
        }
        $names.Add($s)
    }
    foreach ($n in $names) {
        $t = $n.Trim().TrimEnd($sep)
        if (-not $t) { continue }
        $leaf = $t.Substring($t.LastIndexOfAny($sep) + 1)
        if ($leaf -and -not ($leaf.Length -eq 2 -and $leaf[1] -eq ':')) { $folders.Add($leaf.ToLowerInvariant()) }
    }
    $proof = [System.Collections.Generic.List[string]]::new()
    if ($Game.GameExe) { $proof.Add([string]$Game.GameExe) }
    foreach ($grp in @($Game.BaseGameProofFiles)) {
        $g = [string]$grp
        if ([string]::IsNullOrWhiteSpace($g)) { continue }
        foreach ($alt in $g.Split('|')) { $proof.Add($alt) }
        break   # first declared group only
    }
    foreach ($f in $proof) {
        $f = $f.Trim()
        if ($f) {
            $files.Add(([IO.Path]::GetFileName($f)).ToLowerInvariant())
            if ($f.IndexOfAny($sep) -ge 0 -and -not [IO.Path]::IsPathRooted($f) -and $f -notmatch '(?:^|[\\/])\.\.(?:[\\/]|$)') { $relativeFiles.Add($f) }
        }
    }
    return @{ Folders = $folders; Files = $files; RelativeFiles=$relativeFiles }
}

function global:New-RegistryInstallIndex {
    param([string[]]$Roots, $Games, [hashtable]$DriveCache)
    if ($null -eq $DriveCache) { $DriveCache = @{} }
    $byFolder = @{}
    $byFile   = @{}
    $wanted = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $keysByTitle = @{}
    $fileIdentities=@{}
    $nestedWanted=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($g in @($Games)) {
        $gk = Get-RegistryDiscoveryKeys -Game $g
        if ($g.Title) { $keysByTitle[[string]$g.Title] = $gk }
        foreach ($f in $gk.Files) {
            [void]$wanted.Add($f)
            if(-not $fileIdentities.ContainsKey($f)){$fileIdentities[$f]=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)}
            $identity=if($g.SteamId){[string]$g.SteamId}elseif($g.SteamFolder){[string]$g.SteamFolder}else{[string]$g.Title}
            [void]$fileIdentities[$f].Add($identity)
        }
        foreach ($f in $gk.RelativeFiles) { [void]$nestedWanted.Add($f) }
    }
    # Nested proofs grouped by their first folder. A nested file can only
    # exist when that first folder exists, so each root lists its own
    # subfolders once and probes just the matching proofs - instead of one
    # File.Exists per root and nested proof (~70k probes for 277 roots,
    # about one second on Windows PowerShell). Same hits, fewer misses.
    $nestedByFirst=@{}
    $nestedAlways=[Collections.Generic.List[string]]::new()
    foreach ($relative in $nestedWanted) {
        $first=($relative -split '[\\/]',2)[0]
        if (-not $first -or $first -eq '.') { $nestedAlways.Add($relative); continue }
        $firstKey=$first.ToLowerInvariant()
        if (-not $nestedByFirst.ContainsKey($firstKey)) { $nestedByFirst[$firstKey]=[Collections.Generic.List[string]]::new() }
        $nestedByFirst[$firstKey].Add($relative)
    }
    $listed = 0
    foreach ($r in @($Roots | Select-Object -First 3000)) {
        $r = [string]$r
        if (-not $r -or $r.StartsWith('\\')) { continue }
        # A disconnected or empty drive must never stall the scan.
        if (-not (Test-ScanFallbackDriveReady -Path $r -Cache $DriveCache)) { continue }
        if (-not [IO.Directory]::Exists($r)) { continue }
        $leaf = ($r.TrimEnd([char[]]'\/') -split '[\\/]')[-1].ToLowerInvariant()
        if (-not $byFolder.ContainsKey($leaf)) { $byFolder[$leaf] = [System.Collections.Generic.List[string]]::new() }
        $byFolder[$leaf].Add($r)
        try {
            foreach ($file in [IO.Directory]::EnumerateFiles($r)) {
                $name = [IO.Path]::GetFileName($file)
                if (-not $wanted.Contains($name)) { continue }
                $k = $name.ToLowerInvariant()
                if (-not $byFile.ContainsKey($k)) { $byFile[$k] = [System.Collections.Generic.List[string]]::new() }
                $byFile[$k].Add($r)
            }
            $nestedCandidates=[Collections.Generic.List[string]]::new($nestedAlways)
            if ($nestedByFirst.Count -gt 0) {
                try {
                    foreach ($sub in [IO.Directory]::EnumerateDirectories($r)) {
                        $subKey=[IO.Path]::GetFileName($sub).ToLowerInvariant()
                        if ($nestedByFirst.ContainsKey($subKey)) { $nestedCandidates.AddRange($nestedByFirst[$subKey]) }
                    }
                } catch {
                    # Unlistable subfolders: probe every nested proof as before.
                    $nestedCandidates=[Collections.Generic.List[string]]::new($nestedWanted)
                }
            }
            foreach ($relative in $nestedCandidates) {
                if ([IO.File]::Exists([IO.Path]::Combine($r,$relative))) {
                    $k=[IO.Path]::GetFileName($relative).ToLowerInvariant()
                    if (-not $byFile.ContainsKey($k)) { $byFile[$k]=[Collections.Generic.List[string]]::new() }
                    if (-not $byFile[$k].Contains($r)) { $byFile[$k].Add($r) }
                }
            }
            $listed++
        } catch {}
    }
    return @{ ByFolder = $byFolder; ByFile = $byFile; Listed = $listed; KeysByTitle = $keysByTitle; AmbiguousFiles=@($fileIdentities.Keys|Where-Object {$fileIdentities[$_].Count -gt 1}) }
}

function global:Find-RegistryInstallRoot {
    param($Game, [hashtable]$Index)
    if (-not $Index) { return $null }
    $keys = if ($Index.KeysByTitle -and $Game.Title -and $Index.KeysByTitle.ContainsKey([string]$Game.Title)) { $Index.KeysByTitle[[string]$Game.Title] } else { Get-RegistryDiscoveryKeys -Game $Game }
    # Dictionary lookups first - for almost every entry nothing matches and
    # the function ends here without touching the disk.
    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($k in $keys.Folders) { $hit = $Index.ByFolder[[string]$k]; if ($hit) { foreach ($c in $hit) { if (-not $candidates.Contains($c)) { $candidates.Add($c) } } } }
    foreach ($k in $keys.Files)   { if($k -in $Index.AmbiguousFiles){continue}; $hit = $Index.ByFile[[string]$k];   if ($hit) { foreach ($c in $hit) { if (-not $candidates.Contains($c)) { $candidates.Add($c) } } } }
    if ($candidates.Count -eq 0) { return $null }
    # No declared proof -> no registry match. Test-BaseGameInstallProof
    # returns $true for proof-less legacy entries; that is fine for the
    # catalog's own exact paths, never for a foreign registry folder.
    $hasProof = -not [string]::IsNullOrWhiteSpace([string]$Game.GameExe)
    if (-not $hasProof) {
        foreach ($grp in @($Game.BaseGameProofFiles)) { if (-not [string]::IsNullOrWhiteSpace([string]$grp)) { $hasProof = $true; break } }
    }
    if (-not $hasProof) { return $null }
    foreach ($c in $candidates) {
        # DisplayIcon may name an EXE in bin/x64 instead of the game root.
        # Walk only these few ancestors; accept solely complete declared proof.
        $probe=$c
        for ($level=0;$level -lt 4 -and $probe;$level++) {
            if (Test-BaseGameInstallProof -Game $Game -Root $probe) { return $probe }
            $probe=[IO.Path]::GetDirectoryName($probe.TrimEnd([char[]]'\/'))
        }
    }
    return $null
}

function global:Get-PenumbraFrameworkInstalledVersion {
    param($Game,[string]$Root)
    if (-not $Game -or $Game.Id -notin @('penumbra-black-plague-vr','penumbra-requiem-vr') -or
        -not $Root -or -not (Test-BaseGameInstallProof -Game $Game -Root $Root) -or
        -not (Test-VrInstallEvidenceContract -Game $Game -Root $Root)) { return $null }
    try {
        $state=Get-Content -LiteralPath (Join-HubPathLexical $Root 'redist\PenumbraVR.BlackPlague.install.json') -Raw -ErrorAction Stop | ConvertFrom-Json
        $component=if ($Game.Id -eq 'penumbra-requiem-vr') { 'requiem' } else { 'black_plague' }
        $version=([string]$state.frameworkVersion).Trim() -replace '^v',''
        if (@($state.components) -contains $component -and (Test-IsTrackableInstalledVersion -Version $version)) { return $version }
    } catch {}
    return $null
}

function global:Get-UnrealRevivedInstalledVersion {
    param($Game,[string]$Root)
    if (-not $Game -or $Game.Id -ne 'unreal-revived-vr' -or -not $Root -or
        -not (Test-VrInstallEvidenceContract -Game $Game -Root $Root) -or
        -not (Test-BaseGameInstallProof -Game $Game -Root $Root)) { return $null }
    try {
        $exe=Join-Path $Root 'System64\UnrealRevivedVR.exe'
        $version=([string](Get-Item -LiteralPath $exe -ErrorAction Stop).VersionInfo.ProductVersion).Trim()
        if ($version -match '^\d+(?:\.\d+){1,3}$') { return $version }
    } catch {}
    return $null
}

# Standalone VR runtimes may be recorded as installed_path while their
# purchased game data live elsewhere. Reuse only a separately remembered
# path that still satisfies this game's base-file proof.
function global:Get-OriginalGameImportAction {
    param($Game,[string[]]$Roots=@(),[switch]$CandidatesOnly)
    if(-not $Game.RequiresRom -or -not $Game.OriginalImportModes){return $null}
    $candidates=[Collections.Generic.List[string]]::new()
    foreach($root in $Roots){if($root){$candidates.Add($root)}}
    if(-not $CandidatesOnly){
    foreach($name in @('installed_path','located_vr_root','mod_a_path','mod_b_path','installed_path_current','installed_path_legacy_depot')){
        try{$root=Read-PersistentGameStateValue -Game $Game -Name $name;if($root){$candidates.Add([string]$root)}}catch{}
    }
    foreach($root in @($Game.CurrentStandalonePaths)+@($Game.LegacyDepotPath)+@($Game.LegacyDepotFallbackPaths)+@($Game.FallbackPaths)){
        if($root -and [IO.Path]::IsPathRooted([string]$root)){$candidates.Add([string]$root)}
    }
    }
    # Only runtime evidence is relaxed for this explicitly separate action.
    # Its result cannot flow into GamePresent or a VR Ready presence probe.
    $runtimeGame=$Game.Clone();$runtimeGame.BaseGameProofFiles=@();$runtimeGame.OriginalGameProofSets=@();$runtimeGame.GameExe=''
    $runtimeGame.RequiresRom=$false;$runtimeGame.TwoModsSeparateBaseGame=$false;$runtimeGame.SeparateLauncherBaseGame=$false
    foreach($root in @($candidates|Select-Object -Unique)){
        try{
            if(-not [IO.Directory]::Exists($root)){continue}
            if($global:HubFileSystemLabRoot -and -not [IO.Path]::GetFullPath($root).StartsWith(([IO.Path]::GetFullPath($global:HubFileSystemLabRoot).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)){continue}
            foreach($mode in @($Game.OriginalImportModes)){
                $launch='';$arguments=[string]$Game.LaunchArgs;$complete=$false
                if($mode -match '^Mod[A-H]$' -and $Game.TwoMods){
                    $presence=Get-TwoModsPresence -Game $runtimeGame -FallbackRoot $root
                    $definition=@(Get-AlternativeModDefinitions -Game $Game|Where-Object Mode -eq $mode|Select-Object -First 1)
                    if($definition.Count -and [bool]$presence[($mode+'Present')] -and [string]$presence[($mode+'Root')] -ieq $root){
                        $d=$definition[0];$launch=if($d.Sub -and $d.Sub -ne '.' -and -not $d.RootLaunch){[IO.Path]::Combine([string]$d.Sub,[string]$d.Launch)}else{[string]$d.Launch}
                        $complete=$true
                    }
                }elseif($mode -in @('Current','LegacyDepot') -and $Game.DualMode){
                    $prefix=if($mode -eq 'Current'){'Current'}else{'LegacyDepot'}
                    $runtimeGame.CurrentStandalonePaths=@($root);$runtimeGame.LegacyDepotPath=$root;$runtimeGame.LegacyDepotFallbackPaths=@()
                    $presence=Get-DualModePresence -Game $runtimeGame -Libs @() -NoStateMigration
                    $key=if($mode -eq 'Current'){'Current'}else{'Legacy'}
                    $launch=[string]$Game[($prefix+'LaunchExe')]
                    $complete=[bool]($presence[($key+'Present')] -and [string]$presence[($key+'Dir')] -ieq $root)
                    if($Game[($prefix+'LaunchArgs')]){$arguments=[string]$Game[($prefix+'LaunchArgs')]}
                }elseif($mode -eq 'Default'){
                    $launch=[string]$Game.LaunchExe
                    $complete=(Test-VrInstallEvidenceContract -Game $runtimeGame -Root $root -Strict) -and (Test-RelativePathMarker -Root $root -Values @($Game.ModFile,$Game.ModFileAlt,$Game.ModFileAlt2))
                }
                if(-not $complete -or -not $launch -or [IO.Path]::IsPathRooted($launch) -or $launch -match '(^|[\\/])\.\.([\\/]|$)|[?*]'){continue}
                $file=[IO.Path]::Combine($root,$launch)
                if([IO.File]::Exists($file)){return [pscustomobject]@{Root=$root;File=$file;Arguments=$arguments;Mode=[string]$mode}}
            }
        }catch{}
    }
    return $null
}

function global:New-OriginalGameImportState {
    param($Action)
    return @{Tag='vrimport';State='import';BtnText='Import game';GameDir=[string]$Action.Root;OriginalImportPending=$true;BaseGamePresent=$false;ImportMode=[string]$Action.Mode}
}

function global:Get-RememberedStagedBaseGameRoot {
    param($Game,[string]$RuntimeRoot='')
    if (-not $Game -or -not ($Game.BaseGameProofFiles -or $Game.OriginalGameProofSets -or $Game.GameExe)) { return $null }
    foreach ($name in @('base_game_path','user_located')) {
        try {
            $candidate = Read-PersistentGameStateValue -Game $Game -Name $name
            if ($candidate -and (Test-BaseGameInstallProof -Game $Game -Root ([string]$candidate))) { return [string]$candidate }
        } catch {}
    }
    if (Get-Command Get-PCVRConfiguredOriginalGameRoot -ErrorAction SilentlyContinue) {
        $configured=Get-PCVRConfiguredOriginalGameRoot -GameId $Game.Id -RuntimeRoot $RuntimeRoot
        if ($configured) { return $configured }
    }
    if($Game.Id -eq 'hytale-vr' -and $env:APPDATA){
        $original=Join-Path $env:APPDATA 'Hytale\install\release\package\game\latest'
        if(Test-BaseGameInstallProof -Game $Game -Root $original){return $original}
    }
    # These publishers keep their licensed assets outside the VR runtime.
    # Their recorded source path is useful only while the original game-file
    # proof still exists; the launcher/config itself never proves the game.
    if($Game.Id -in @('c-c-generals-zero-hour','f-e-a-r-vr','black-mesa-source-vr')){
        $roots=@($RuntimeRoot)
        foreach($name in @('installed_path','located_vr_root')){try{$roots+=@(Read-PersistentGameStateValue -Game $Game -Name $name)}catch{}}
        try{$roots+=@(Resolve-VrInstallRoot $Game.VrInstallRoot)}catch{}
        foreach($runtime in @($roots|Where-Object {$_}|Select-Object -Unique)){
            try{
                if($global:HubFileSystemLabRoot -and -not [IO.Path]::GetFullPath($runtime).StartsWith(([IO.Path]::GetFullPath($global:HubFileSystemLabRoot).TrimEnd('\')+'\'),[StringComparison]::OrdinalIgnoreCase)){continue}
                if($Game.Id -eq 'black-mesa-source-vr'){
                    $ini=Get-Content -LiteralPath (Join-Path $runtime 'ModOrganizer.ini') -Raw -ErrorAction Stop
                    $match=[regex]::Match($ini,'(?im)^\s*gamePath\s*=\s*(?<path>[^\r\n]+)')
                    if($match.Success){
                        $candidate=$match.Groups['path'].Value.Trim()
                        if($candidate.StartsWith('@ByteArray(') -and $candidate.EndsWith(')')){$candidate=$candidate.Substring(11,$candidate.Length-12)}
                        $candidate=$candidate.Trim('"',"'")
                        if($candidate.StartsWith('\\')){continue}
                        $candidate=$candidate.Replace('\\','\').Replace('/','\')
                        if([IO.Path]::GetExtension($candidate) -ieq '.exe'){$candidate=[IO.Path]::GetDirectoryName($candidate)}
                        if(Test-BaseGameInstallProof -Game $Game -Root $candidate){return $candidate}
                    }
                    continue
                }
                $file=if($Game.Id -eq 'c-c-generals-zero-hour'){'generalsvr.json'}else{'deployment.json'}
                $key=if($Game.Id -eq 'c-c-generals-zero-hour'){'gamePath'}else{'retailRoot'}
                $json=Get-Content -LiteralPath (Join-Path $runtime $file) -Raw -ErrorAction Stop|ConvertFrom-Json -ErrorAction Stop
                $candidate=[string]$json.$key
                if($candidate -and (Test-BaseGameInstallProof -Game $Game -Root $candidate)){return $candidate}
            }catch{}
        }
    }
    return $null
}

# TwoMods presence probe - which of a two-mod entry's launchers are on
# disk, and where. Shared on purpose: the full scan AND the post-install
# refresh both need it. Before this existed the refresh wrote a minimal
# state entry without any TwoMods fields, so a freshly installed two-mod
# game showed a single button until the Hub was restarted.
function global:Get-RouteModMatrixPresence {
    param($Game, [string]$FallbackRoot, $Libs)
    $res = @{
        CurrentRoot=$null; DepotRoot=$null
        CurrentModAPresent=$false; CurrentModBPresent=$false
        DepotModAPresent=$false; DepotModBPresent=$false
        RouteUpdateTargets=@()
    }
    if (-not $Game -or -not $Game.RouteModMatrix -or -not $Game.DualMode -or -not $Game.TwoMods) { return $res }

    $samePath = {
        param([string]$A,[string]$B)
        if (-not $A -or -not $B) { return $false }
        try { return ([IO.Path]::GetFullPath($A).TrimEnd('\') -ieq [IO.Path]::GetFullPath($B).TrimEnd('\')) } catch { return ($A.TrimEnd('\') -ieq $B.TrimEnd('\')) }
    }
    $baseValid = {
        param([string]$Root)
        if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
        $proof = Get-Command Test-BaseGameInstallProof -ErrorAction SilentlyContinue
        if ($proof) { return [bool](Test-BaseGameInstallProof -Game $Game -Root $Root) }
        if ($Game.BaseGameProofFiles) {
            foreach ($rawGroup in @($Game.BaseGameProofFiles)) {
                $matched = $false
                foreach ($relative in (([string]$rawGroup) -split '\|')) {
                    if ($relative -and (Test-Path -LiteralPath (Join-Path $Root $relative.Trim()) -PathType Leaf)) { $matched=$true; break }
                }
                if (-not $matched) { return $false }
            }
            return $true
        }
        if ($Game.GameExe) { return [bool](Test-Path -LiteralPath (Join-Path $Root ([string]$Game.GameExe)) -PathType Leaf) }
        return $true
    }
    $slotPresent = {
        param([string]$Root,[string]$Slot)
        if (-not (& $baseValid $Root)) { return $false }
        $prefix = "Mod$Slot"
        $abs = Get-AlternativeModValue $Game "${prefix}ProbeAbs"
        $rel = Get-AlternativeModValue $Game "${prefix}ProbeFile"
        $marker = $false
        if ($abs) { $marker = Test-AbsolutePathMarker -Values $abs }
        if (-not $marker -and $rel) { $marker = Test-RelativePathMarker -Root $Root -Values $rel -RequirePe:([bool]$Game.ModFileMustBePe) }
        if (-not $marker) { return $false }
        $required = Get-AlternativeModValue $Game "${prefix}RequiredFile"
        if ($required -and -not (Test-RelativePathMarker -Root $Root -Values $required)) { return $false }
        $launcherOptional = [bool](Get-AlternativeModValue $Game "${prefix}RouteLauncherOptional")
        if (-not $launcherOptional) {
            $sub = Get-AlternativeModValue $Game "${prefix}Sub"
            $launch = Get-AlternativeModValue $Game "${prefix}Launch"
            if ($sub -and $launch -and -not (Test-Path -LiteralPath (Join-Path $Root (Join-Path ([string]$sub) ([string]$launch))) -PathType Leaf)) { return $false }
        }
        return $true
    }

    $depotCandidates = @()
    try { $depotCandidates = @(Get-DepotCandidatePaths -Game $Game) } catch {}
    foreach ($candidate in $depotCandidates) {
        if (& $baseValid ([string]$candidate)) { $res.DepotRoot = [IO.Path]::GetFullPath([string]$candidate); break }
    }

    if ((-not $global:HubFileSystemLabRoot) -and (-not $Libs -or $Libs.Count -eq 0)) {
        try { $Libs = @(Get-HubSteamLibraries) } catch { $Libs = @() }
    }
    $currentCandidates = New-Object System.Collections.Generic.List[string]
    if ($Game.SteamFolder) {
        foreach ($lib in @($Libs)) {
            if ([string]::IsNullOrWhiteSpace([string]$lib)) { continue }
            try {
                $candidate = Join-Path ([string]$lib) "steamapps\common\$($Game.SteamFolder)"
                if ((& $baseValid $candidate) -and -not (& $samePath $candidate $res.DepotRoot)) { [void]$currentCandidates.Add([IO.Path]::GetFullPath($candidate)) }
            } catch {}
        }
    }
    foreach ($candidate in @($FallbackRoot)) {
        if (-not $candidate -or -not (& $baseValid ([string]$candidate)) -or (& $samePath ([string]$candidate) $res.DepotRoot)) { continue }
        $full = try { [IO.Path]::GetFullPath([string]$candidate) } catch { [string]$candidate }
        if ($full -notin $currentCandidates) { [void]$currentCandidates.Add($full) }
    }
    foreach ($candidate in $currentCandidates) {
        $a = & $slotPresent $candidate 'A'; $b = & $slotPresent $candidate 'B'
        if (-not $res.CurrentRoot -or $a -or $b) {
            $res.CurrentRoot = $candidate
            $res.CurrentModAPresent = [bool]$a; $res.CurrentModBPresent = [bool]$b
        }
        if ($a -or $b) { break }
    }
    if ($res.DepotRoot) {
        $res.DepotModAPresent = [bool](& $slotPresent $res.DepotRoot 'A')
        $res.DepotModBPresent = [bool](& $slotPresent $res.DepotRoot 'B')
    }

    $updates = New-Object System.Collections.Generic.List[object]
    foreach ($route in @(
        @{ Name='Current'; Root=$res.CurrentRoot; A=$res.CurrentModAPresent; B=$res.CurrentModBPresent },
        @{ Name='Depot'; Root=$res.DepotRoot; A=$res.DepotModAPresent; B=$res.DepotModBPresent }
    )) {
        if (-not $route.Root) { continue }
        foreach ($slot in @('A','B')) {
            if (-not [bool]$route[$slot]) { continue }
            $requiredUpdate = Get-AlternativeModValue $Game "Mod${slot}UpdateRequiredFile"
            if ($requiredUpdate -and -not (Test-RelativePathMarker -Root ([string]$route.Root) -Values $requiredUpdate)) {
                [void]$updates.Add([pscustomobject]@{
                    Slot=$slot; Name=[string](Get-AlternativeModValue $Game "Mod${slot}Name")
                    Route=[string]$route.Name; Root=[string]$route.Root; RequiredFile=$requiredUpdate
                })
            }
        }
    }
    $res.RouteUpdateTargets = $updates.ToArray()
    return $res
}

function global:Test-ScanFallbackDriveReady {
    param([string]$Path,[hashtable]$Cache,[scriptblock]$DriveProbe=$null)
    if($null -eq $Cache){$Cache=@{}}
    $driveRoot=try{[IO.Path]::GetPathRoot($Path)}catch{$null}
    if(-not $driveRoot -or $driveRoot -notmatch '^[A-Za-z]:\\$'){return $true}
    $key=$driveRoot.ToUpperInvariant()
    if($Cache.ContainsKey($key)){return [bool]$Cache[$key]}
    $ready=$true
    try{
        if($DriveProbe){$ready=[bool](& $DriveProbe $driveRoot)}
        else{
            $info=[IO.DriveInfo]::new($driveRoot)
            $ready=$info.IsReady
        }
    }catch{$ready=$false}
    $Cache[$key]=[bool]$ready
    return [bool]$ready
}
function global:Get-ScanRdrInstalledProfileVersion {
    param([string]$Game,[string]$Mod)
    # Presence loads the publisher helpers inside its own function scope.
    # A fresh Hub must load them in this invocation as well; installer tests
    # that preloaded the whole profile module used to hide that boundary.
    $rdrCore=if($global:HubHelpersCoreRoot){[string]$global:HubHelpersCoreRoot}
             elseif($script:scriptDir){[string]$script:scriptDir}
             elseif($global:scriptDir){[string]$global:scriptDir}
             elseif($PSScriptRoot){Split-Path $PSScriptRoot -Parent}else{''}
    if(-not $rdrCore){throw 'The RDRVR scan module root is unavailable.'}
    . ([IO.Path]::Combine($rdrCore,'RDRVR','RDRVR-Profiles.ps1'))
    return Get-RdrInstalledProfileVersion -Game $Game -Mod $Mod
}
function global:Get-TwoModsPresence {
    param($Game, [string]$FallbackRoot,[string]$BaseGamePath='')
    $res = @{ APresent = $false; BPresent = $false; ADir = $null; BDir = $null; ARoot = $null; BRoot = $null; Root = $null }
    if (-not $Game -or -not $Game.TwoMods) { return $res }
    if ($Game.RouteModMatrix) {
        $matrix = Get-RouteModMatrixPresence -Game $Game -FallbackRoot $FallbackRoot
        foreach ($key in $matrix.Keys) { $res[$key] = $matrix[$key] }
        $res.APresent = [bool]($matrix.CurrentModAPresent -or $matrix.DepotModAPresent)
        $res.BPresent = [bool]($matrix.CurrentModBPresent -or $matrix.DepotModBPresent)
        $res.ModAPresent = $res.APresent; $res.ModBPresent = $res.BPresent
        $res.ARoot = if ($matrix.CurrentModAPresent) { $matrix.CurrentRoot } elseif ($matrix.DepotModAPresent) { $matrix.DepotRoot } else { $null }
        $res.BRoot = if ($matrix.CurrentModBPresent) { $matrix.CurrentRoot } elseif ($matrix.DepotModBPresent) { $matrix.DepotRoot } else { $null }
        $res.ModARoot = $res.ARoot; $res.ModBRoot = $res.BRoot
        $res.Root = if ($res.ARoot) { $res.ARoot } else { $res.BRoot }
        foreach ($slot in @('A','B')) {
            $root = $res["${slot}Root"]
            $sub = Get-AlternativeModValue $Game "Mod${slot}Sub"
            if ($root -and $sub) {
                $dir = Join-Path ([string]$root) ([string]$sub)
                if (Test-Path -LiteralPath $dir -PathType Container) { $res["${slot}Dir"]=$dir; $res["Mod${slot}Dir"]=$dir }
            }
        }
        return $res
    }
    $definitions = @(Get-AlternativeModDefinitions -Game $Game)
    foreach ($definition in $definitions) {
        $prefix = [string]$definition.Mode
        $slot = [string]$definition.Slot
        $res["${prefix}Present"] = $false
        $res["${prefix}Dir"] = $null
        $res["${prefix}Root"] = $null
        # Keep the established APresent/ADir/ARoot shape for existing tests
        # and call sites while the extensible state uses ModAPresent, etc.
        $res["${slot}Present"] = $false
        $res["${slot}Dir"] = $null
        $res["${slot}Root"] = $null
    }
    # Search every relevant root. Most TwoMods titles use one recorded
    # parent, while Elden Ring can have the current Steam build and a pinned
    # depot at the same time. Stopping at .installed_path made the other
    # build (and the mod inside it) invisible.
    $roots = New-Object System.Collections.ArrayList
    $rootScopes = @{}
    $normaliseRoot = {
        param([string]$Path)
        if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
        try { return ([IO.Path]::GetFullPath($Path).TrimEnd('\')).ToLowerInvariant() } catch { return $Path.TrimEnd('\').ToLowerInvariant() }
    }
    $addRoot = {
        param([string]$Path, [string]$Scope)
        if ([string]::IsNullOrWhiteSpace($Path)) { return }
        try {
            if($global:HubFileSystemLabRoot){
                $lab=[IO.Path]::GetFullPath($global:HubFileSystemLabRoot).TrimEnd([char[]]'\/')
                $candidate=[IO.Path]::GetFullPath($Path).TrimEnd([char[]]'\/')
                if($candidate -ine $lab -and -not $candidate.StartsWith($lab+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){return}
            }
            if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return }
            $key = & $normaliseRoot $Path
            foreach ($known in $roots) {
                if ((& $normaliseRoot ([string]$known)) -eq $key) {
                    if ($Scope) { $rootScopes[$key] = $Scope }
                    return
                }
            }
            [void]$roots.Add([IO.Path]::GetFullPath($Path))
            if ($Scope) { $rootScopes[$key] = $Scope }
        } catch {}
    }
    $ipf = Get-InstalledPathFile -Game $Game

    # Two independent mods may intentionally live in two independent roots.
    # Their dedicated records survive whichever installer happened to write
    # the shared legacy .installed_path last.
    $markerDir = if ($ipf) { Split-Path -Parent $ipf } else { $null }
    foreach ($definition in $definitions) {
        if (-not $definition.InstalledPathFile -or -not $markerDir) { continue }
        try {
            $recordFile = if ([IO.Path]::IsPathRooted([string]$definition.InstalledPathFile)) { [string]$definition.InstalledPathFile } else { Join-Path $markerDir ([string]$definition.InstalledPathFile) }
            if (-not (Test-Path -LiteralPath $recordFile -PathType Leaf)) { continue }
            $recorded = ([string](Get-Content -LiteralPath $recordFile -Raw -ErrorAction Stop)).Trim()
            $scope = if ($definition.ProbeScope) { [string]$definition.ProbeScope } else { [string]$definition.Slot }
            & $addRoot $recorded $scope
        } catch {}
    }
    # External dual launchers can be installed independently of the retail
    # game and of each other. Their canonical per-slot locations survive a
    # replacement of the Hub folder; the adjacent receipts remain recovery.
    if (($Game.TwoModsSeparateBaseGame -or $Game.TwoModsIndependentRoots) -and (Get-Command Read-PersistentGameStateValue -ErrorAction SilentlyContinue)) {
        foreach ($definition in $definitions) {
            try {
                $name = ('mod_' + ([string]$definition.Slot).ToLowerInvariant() + '_path')
                $saved = Read-PersistentGameStateValue -Game $Game -Name $name
                & $addRoot ([string]$saved) ([string]$definition.Slot)
            } catch {}
        }
    }
    # Canonical associations remain valid without a legacy adjacent receipt.
    try { & $addRoot (Read-InstalledPath -Game $Game) } catch {}
    & $addRoot $FallbackRoot
    if ($Game.VrInstallRoot) {
        try {
            $stageRoot = if (Get-Command Resolve-VrInstallRoot -ErrorAction SilentlyContinue) { Resolve-VrInstallRoot -Root ([string]$Game.VrInstallRoot) } else { [Environment]::ExpandEnvironmentVariables([string]$Game.VrInstallRoot) }
            & $addRoot $stageRoot
        } catch {}
    }
    if ($Game.TwoModsSeparateBaseGame) {
        foreach ($candidate in @($Game.DurableInstallRoots)) { & $addRoot ([string]$candidate) }
    }
    if ($Game.DualMode) {
        try { foreach ($candidate in (Get-DepotCandidatePaths -Game $Game)) { & $addRoot $candidate } } catch {}
    }
    foreach ($fallback in @($Game.FallbackPaths)) {
        # Keep native drive paths such as C:\Games; skip catalog resolver
        # prefixes such as STEAM:, XBOX: and GOG:.
        if ($fallback -and $fallback -notmatch '^[A-Za-z_]{2,}:') {
            if($null -eq $global:ScanFallbackDriveReadyCache){$global:ScanFallbackDriveReadyCache=@{}}
            if(-not(Test-ScanFallbackDriveReady -Path ([string]$fallback) -Cache $global:ScanFallbackDriveReadyCache)){continue}
            & $addRoot ([string]$fallback)
        }
    }
    if ($roots.Count -eq 0) { return $res }
    $res.Root = [string]$roots[0]

    # Launchers are launch paths, not installation evidence. A stale batch
    # file must never resurrect a deleted mod. When a slot declares a real
    # probe marker, that marker decides presence and the launcher only
    # supplies the directory for the Play button.
    $separateBaseValid = $false
    if ($Game.TwoModsSeparateBaseGame) {
        foreach ($candidate in @($BaseGamePath,$FallbackRoot, (Get-RememberedStagedBaseGameRoot -Game $Game -RuntimeRoot $FallbackRoot))) {
            if ($candidate -and (Test-BaseGameInstallProof -Game $Game -Root ([string]$candidate))) {
                $separateBaseValid = $true; break
            }
        }
    }
    foreach ($root in $roots) {
        # A real mod marker inside a leftover folder does not prove that the
        # base game it needs still exists. The command guard keeps this helper
        # independently testable; the ordered Filter facade always loads the
        # proof helper immediately before this function in production.
        $baseProof = Get-Command Test-BaseGameInstallProof -ErrorAction SilentlyContinue
        $originalPresent=if($baseProof){Test-BaseGameInstallProof -Game $Game -Root ([string]$root)}else{$true}
        if(-not $originalPresent -and $Game.RequiresRom){
            $configuredOriginal=Get-RememberedStagedBaseGameRoot -Game $Game -RuntimeRoot ([string]$root)
            $originalPresent=[bool]$configuredOriginal
        }
        $ttwvrReady = $Game.Id -eq 'fallout-new-vegas-vr' -and [bool](Get-PCVRTTWVRState -Root $root -Mode NewVegas)
        if (-not $originalPresent -and -not $ttwvrReady -and -not ($Game.TwoModsSeparateBaseGame -and $separateBaseValid)) { continue }
        $rootKey = & $normaliseRoot ([string]$root)
        $scope = if ($rootScopes.ContainsKey($rootKey)) { [string]$rootScopes[$rootKey] } else { $null }
        $rootDefinitions=$definitions
        $externalAtRoot=$null
        if(Get-Command Get-LocatedExternalVrContract -ErrorAction SilentlyContinue){$externalAtRoot=Get-LocatedExternalVrContract -Game $Game -Root $root -Requested:([bool]$Game._ExternalVrProbe)}
        if($externalAtRoot){$rootDefinitions=@(Get-AlternativeModDefinitions -Game $externalAtRoot)}
        foreach ($definition in $rootDefinitions) {
            $prefix = [string]$definition.Mode
            $hit = $null
            if ($definition.Sub -and ($definition.Launch -or $definition.LaunchAlt)) {
                $sub = Join-Path $root ([string]$definition.Sub)
                if (Test-Path -LiteralPath $sub -PathType Container) {
                    foreach ($launchName in @(@($definition.Launch,$definition.LaunchAlt) | Where-Object { $_ })) {
                        $hit = Get-ChildItem -LiteralPath $sub -File -Filter ([string]$launchName) -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($hit) { break }
                    }
                }
            }
            # A catalog opt-in retains old root-level launcher layouts while
            # current packages remain isolated below their named subfolder.
            if (-not $hit -and $definition.RootLaunch -and ($definition.Launch -or $definition.LaunchAlt)) {
                foreach ($launchName in @(@($definition.Launch,$definition.LaunchAlt) | Where-Object { $_ })) {
                    $rootLaunch = Join-Path $root ([string]$launchName)
                    if (Test-Path -LiteralPath $rootLaunch -PathType Leaf) { $hit = Get-Item -LiteralPath $rootLaunch; break }
                }
            }
            $absDeclared = [bool]$definition.ProbeAbs
            $absPresent = if ($absDeclared) { Test-AbsolutePathMarker -Values $definition.ProbeAbs } else { $false }
            $relPresent = Test-RelativePathMarker -Root $root -Values $definition.ProbeFile -RequirePe:([bool]$Game.ModFileMustBePe)
            if (-not $scope -and $definition.ProbeScope -and $relPresent) { $scope = [string]$definition.ProbeScope }
            if ($definition.ProbeScope -and $scope -and $scope -ine [string]$definition.ProbeScope) { $relPresent = $false }
            $probeDeclared = ($absDeclared -or [bool]$definition.ProbeFile)
            $presentHere = if ($probeDeclared) { ($absPresent -or $relPresent) } else { [bool]$hit }
            # Pragmata's old Hub and publisher/manual packages predate the
            # separate stores. Identify their active runtime independently;
            # a new HUD package must not masquerade as legacy just because
            # both use REFramework's common DLL names.
            $pragmataManual=$false
            if($Game.Id -eq 'pragmata-vr'){
                $liveHud=[IO.File]::Exists((Join-Path $root 'PragmataVR_README.txt'))
                $liveFiles=@('dinput8.dll','openxr_loader.dll')
                if($prefix -eq 'ModA'){$liveFiles+=@('PragmataVR_README.txt','PDAFWPlugin.dll')}
                $pragmataManual=[bool](($prefix -eq 'ModA' -or -not$liveHud) -and @($liveFiles|Where-Object{-not[IO.File]::Exists((Join-Path $root $_))}).Count -eq 0)
                if($pragmataManual){$presentHere=$true}
            }
            # Optional hard prerequisites are AND conditions, unlike the
            # alternative probe arrays above.
            if ($presentHere -and $definition.RequiredFile) {
                $presentHere = Test-RelativePathMarker -Root $root -Values $definition.RequiredFile
            }
            if ($presentHere -and $definition.RequiredGroups -and -not$pragmataManual) {
                foreach ($requiredGroup in @($definition.RequiredGroups)) {
                    if (-not (Test-RelativePathMarker -Root $root -Values $requiredGroup)) {
                        $presentHere = $false; break
                    }
                }
            }
            if ($presentHere -and $Game.Id -eq 'mass-effect-1-le-vr' -and $definition.Slot -eq 'A') {
                . (Join-Path (Split-Path $PSScriptRoot -Parent) 'MassEffect1VR\MEVR-State.ps1')
                $presentHere = [bool](Get-MEVRInstalledVersion $root)
            }
            if ($presentHere -and $Game.Id -eq 'fallout-new-vegas-vr' -and $definition.Slot -eq 'B') { $presentHere = $ttwvrReady }
            if ($presentHere -and $Game.TrilexGame -eq 'singularity') {
                $presentHere = if ($definition.Slot -eq 'B') {
                    [bool](Get-PCVRTrilexReceipt -Root $root -Game $Game.TrilexGame -Runtime $Game.TrilexHashProof)
                } else { -not [IO.File]::Exists((Join-Path $root 'Binaries\dinput8.dll')) }
            }
            if ($presentHere -and $definition.RequiredAbs) {
                foreach ($requiredAbsolute in @($definition.RequiredAbs)) {
                    if (-not (Test-AbsolutePathMarker -Values $requiredAbsolute)) { $presentHere = $false; break }
                }
            }
            if ($presentHere -and $Game.MaxPayne2DualLaunch -and -not $externalAtRoot) {
                try {
                    if (-not (Get-Command Test-MP2Slot -ErrorAction SilentlyContinue)) {
                        # The post-install worker copies function definitions into
                        # another runspace. There $PSScriptRoot is empty; the Hub
                        # supplies its Core root as scriptDir instead.
                        $mp2Core=if ($script:scriptDir) { [string]$script:scriptDir }
                                 elseif ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot }
                                 else { '' }
                        if (-not $mp2Core) { throw 'Max Payne 2 profile module root is unavailable.' }
                        . (Join-Path $mp2Core 'MaxPayne2VR\MaxPayne2VR-Dual.ps1')
                    }
                    $mpSlot=[string]$definition.Slot
                    $presentHere=($mpSlot -in @('A','B') -and
                        ((Test-MP2Slot -Game $root -Slot $mpSlot -Parked) -or
                         (Test-MP2Slot -Game $root -Slot $mpSlot)))
                } catch { $presentHere=$false }
            }
            if ($Game.RDRProfileLaunch) {
                try {
                    if(-not(Get-Command Test-RdrProfilePresence -ErrorAction SilentlyContinue)){
                        $rdrCore=if($script:scriptDir){[string]$script:scriptDir}elseif($PSScriptRoot){Split-Path $PSScriptRoot -Parent}else{''}
                        . (Join-Path $rdrCore 'RDRVR\RDRVR-Profiles.ps1')
                    }
                    $presentHere=Test-RdrProfilePresence -Game $root -Mod $(if($definition.Slot -eq 'A'){'main'}else{'fork'})
                }catch{$presentHere=$false}
            }
            if ($Game.GTA4ProfileLaunch) {
                try {
                    if(-not(Get-Command Test-GTA4ProfilePresence -ErrorAction SilentlyContinue)){
                        $gtaCore=if($script:scriptDir){[string]$script:scriptDir}elseif($PSScriptRoot){Split-Path $PSScriptRoot -Parent}else{''}
                        if(-not $gtaCore){throw 'GTA IV profile module root unavailable.'}
                        . (Join-Path $gtaCore 'Modules\GTA4VRProfiles.ps1')
                    }
                    $presentHere=Test-GTA4ProfilePresence -Root $root -Mod $(if($definition.Slot -eq 'A'){'bordplate'}else{'gamepad'})
                }catch{$presentHere=$false}
            }
            if($Game.TeardownDualLaunch){
                $presentHere=Test-PCVRTeardownProfile -GameRoot $root -Slot ([string]$definition.Slot)
            }
            if ($presentHere) {
                $res["${prefix}Present"] = $true
                if (-not $res["${prefix}Root"]) { $res["${prefix}Root"] = [string]$root }
                if (-not $res["${prefix}Dir"] -and $hit) { $res["${prefix}Dir"] = Split-Path -Parent $hit.FullName }
                $slot = [string]$definition.Slot
                $res["${slot}Present"] = $true
                if (-not $res["${slot}Root"]) { $res["${slot}Root"] = $res["${prefix}Root"] }
                if (-not $res["${slot}Dir"]) { $res["${slot}Dir"] = $res["${prefix}Dir"] }
            }
        }
    }
    return $res
}

# Some discontinued alternative builds remain safe to launch but must no
# longer be distributed. A catalog entry can map that installed legacy slot to
# its maintained successor. This is intentionally a presence transition, not a
# fabricated version comparison against a source that no longer exists:
# legacy present + successor absent = offer Update; both present = settled.
function global:Get-AlternativeMigrationUpdate {
    param($Game, $Presence)
    if (-not $Game -or -not $Game.TwoMods -or -not $Presence) { return $null }

    $fromSlot = ('' + $Game.AlternativeUpgradeFromSlot).Trim().ToUpperInvariant()
    $toSlot   = ('' + $Game.AlternativeUpgradeToSlot).Trim().ToUpperInvariant()
    if ($fromSlot -notmatch '^[A-H]$' -or $toSlot -notmatch '^[A-H]$' -or $fromSlot -eq $toSlot) { return $null }

    $fromPresent = [bool](Get-AlternativeModValue -Source $Presence -Name ("Mod${fromSlot}Present"))
    $toPresent   = [bool](Get-AlternativeModValue -Source $Presence -Name ("Mod${toSlot}Present"))
    if (-not $fromPresent -or $toPresent) { return $null }

    $definitions = @(Get-AlternativeModDefinitions -Game $Game)
    $fromDefinition = @($definitions | Where-Object Slot -eq $fromSlot | Select-Object -First 1)[0]
    $toDefinition   = @($definitions | Where-Object Slot -eq $toSlot   | Select-Object -First 1)[0]
    $fromName = if ($fromDefinition -and $fromDefinition.Name) { [string]$fromDefinition.Name } else { "Mod $fromSlot" }
    $toName   = if ($toDefinition -and $toDefinition.Name) { [string]$toDefinition.Name } else { "Mod $toSlot" }
    $evidence = ('' + $Game.AlternativeUpgradeEvidence).Trim()
    if (-not $evidence) { $evidence = "$fromName is installed; maintained successor $toName is available" }

    return [pscustomobject]@{
        FromSlot = $fromSlot
        ToSlot   = $toSlot
        FromName = $fromName
        ToName   = $toName
        Evidence = $evidence
    }
}

# Manual/authenticated sources such as Discord have no release API. A slot
# may therefore keep its old marker as valid installation evidence while a
# second, release-specific proof file determines whether that installed slot
# needs the Hub's Update treatment. Mods that are not installed never raise a
# badge, and another mod on the same tile cannot satisfy or trigger the test.
# Return the exact installed alternative slots whose reviewed-release proof
# is missing. The old boolean-only helper could paint a shared tile blue, but
# then threw away which mod actually needed attention. Keeping the slot lets
# an Update click route straight to the correct package instead of reopening
# an ambiguous multi-mod chooser.
function global:Get-AlternativeModsNeedingManualUpdate {
    param($Game, $Presence)
    $result = New-Object 'System.Collections.Generic.List[object]'
    if (-not $Game -or -not $Game.TwoMods -or -not $Presence) { return $result.ToArray() }
    # Missing Hub release-recipe stamps do not establish that an externally
    # installed mod is older. Keep its Play action without inventing a version
    # or requiring a reinstall merely to manufacture our bookkeeping.
    $unknownExternal=$false
    if(Get-Command Read-PersistentGameStateValue -ErrorAction SilentlyContinue){
        $location=Read-PersistentGameStateValue -Game $Game -Name 'user_located'
        if($location){
            $known=$false
            foreach($key in @('installed_version','installed_version_b','installed_version_c')){if(Read-PersistentGameStateValue -Game $Game -Name $key){$known=$true;break}}
            $unknownExternal=-not $known
        }
    }
    if($unknownExternal){return $result.ToArray()}

    if ($Game.RouteModMatrix -and $Presence.RouteUpdateTargets) {
        foreach ($target in @($Presence.RouteUpdateTargets)) {
            if($target.Root -and $target.RequiredFile -match '(?i)(^|[\\/])\.pcvrhub' -and (Get-Command Get-LocatedExternalVrContract -ErrorAction SilentlyContinue) -and (Get-LocatedExternalVrContract -Game $Game -Root $target.Root)){continue}
            if ($target.Root -and $target.RequiredFile -and
                -not (Test-RelativePathMarker -Root ([string]$target.Root) -Values $target.RequiredFile)) {
                [void]$result.Add($target)
            }
        }
        return $result.ToArray()
    }
    foreach ($slot in @('A','B','C','D','E','F','G','H')) {
        $required = Get-AlternativeModValue $Game ("Mod${slot}UpdateRequiredFile")
        if (-not $required) { continue }
        $present = [bool](Get-AlternativeModValue $Presence ("Mod${slot}Present"))
        $root = [string](Get-AlternativeModValue $Presence ("Mod${slot}Root"))
        if($present -and $root -and [string]$required -match '(?i)(^|[\\/])\.pcvrhub' -and (Get-Command Get-LocatedExternalVrContract -ErrorAction SilentlyContinue) -and (Get-LocatedExternalVrContract -Game $Game -Root $root)){continue}
        if ($present -and $root -and -not (Test-RelativePathMarker -Root $root -Values $required)) {
            [void]$result.Add([pscustomobject]@{
                Slot         = $slot
                Name         = [string](Get-AlternativeModValue $Game ("Mod${slot}Name"))
                RequiredFile = $required
                Root         = $root
            })
        }
    }
    return $result.ToArray()
}

function global:Test-AlternativeModNeedsManualUpdate {
    param($Game, $Presence)
    return (@(Get-AlternativeModsNeedingManualUpdate -Game $Game -Presence $Presence).Count -gt 0)
}

function global:Test-LegacyDepotRouteReady {
    param($Game,[string]$Root)
    if (-not $Game -or -not $Root -or -not $Game.LegacyDepotLaunchExe -or -not $Game.LegacyDepotModFile) { return $false }
    if (-not (Test-Path -LiteralPath (Join-Path $Root $Game.LegacyDepotLaunchExe) -PathType Leaf) -or
        -not (Test-Path -LiteralPath (Join-Path $Root $Game.LegacyDepotModFile) -PathType Leaf)) { return $false }
    if ($Game.Id -ne 'pokemon-gen-1-vr') { return $true }
    try {
        $marker=(Get-Content -LiteralPath (Join-Path $Root $Game.LegacyDepotModFile) -Raw -ErrorAction Stop).Trim()
        if ($marker -notmatch '^(DRAMATIC_SHAPE|DRAMALESS_SHAPE)\s+v?\d+\.\d+\.\d+\b') { return $false }
        $profileId=$Matches[1]
        $appData=(''+$env:APPDATA).Trim()
        if (-not $appData) { $appData=[Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData) }
        if (-not $appData) { return $false }
        $profileRoot=Join-Path (Join-Path $appData 'pokemon-love2d\mods') $profileId
        foreach($file in @('main.lua','manifest.json','assets\vr\openxr_loader.dll')) {
            if (-not (Test-Path -LiteralPath (Join-Path $profileRoot $file) -PathType Leaf)) { return $false }
        }
        return $true
    } catch { return $false }
}

function global:Test-DepotPinnedReceiptContract {
    param($Game,[string]$Root)
    if (-not $Game.DepotPinnedReceipt) { return $true }
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
    $pin = $Game.DepotPinnedReceipt
    if (-not $pin.Marker -or [IO.Path]::GetFileName([string]$pin.Marker) -ne [string]$pin.Marker) { return $false }
    $expected = "AppId=$($pin.AppId)`nDepotId=$($pin.DepotId)`nManifest=$($pin.Manifest)`nBuildId=$($pin.BuildId)`nMod=$($pin.Mod)"
    try {
        $marker = (Get-Content -LiteralPath (Join-Path $Root ([string]$pin.Marker)) -Raw -ErrorAction Stop).Trim()
        $appid = (Get-Content -LiteralPath (Join-Path $Root 'steam_appid.txt') -Raw -ErrorAction Stop).Trim()
        $version = (Get-Content -LiteralPath (Join-Path $Root '.pcvrhub_version') -Raw -ErrorAction Stop).Trim()
        return ($marker -eq $expected -and $appid -eq [string]$pin.AppId -and $version -eq [string]$pin.Mod)
    } catch { return $false }
}

# DualMode presence probe - are BOTH the pinned-depot build and a current
# Steam-library build modded? Shared for the same reason as the TwoMods
# probe above: the full scan and the post-install refresh must agree, or
# the split button disappears until the Hub is restarted.
# $Libs is optional - the scan already has its library list and passes it
# in; the refresh has none and lets the function look them up itself.
function global:Get-DualModePresence {
    param($Game, $Libs, [scriptblock]$DriveProbe=$null,[switch]$NoStateMigration,[string[]]$CurrentCandidatePaths=@())
    $res = @{
        BothPresent = $false
        MultiplePresent = $false
        RouteCount = 0
        AnyPresent = $false
        CurrentPresent = $false
        DepotPresent = $false
        LegacyPresent = $false
        CurrentDir = $null
        DepotDir = $null
        LegacyDir = $null
    }
    $rememberedCurrentCandidate=$null;try{if(Get-Command Read-InstalledPath -ErrorAction SilentlyContinue){$rememberedCurrentCandidate=Read-InstalledPath -Game $Game}}catch{}
    if(-not $rememberedCurrentCandidate){try{$rememberedCurrentCandidate=Read-PersistentGameStateValue -Game $Game -Name installed_path_current}catch{}}
    $hasRouteRoot = $Game -and ($Game.DepotPath -or $Game.CurrentStandalonePaths -or $Game.LegacyDepotPath -or $rememberedCurrentCandidate -or $CurrentCandidatePaths.Count)
    if (-not $Game -or -not $Game.DualMode -or -not $hasRouteRoot -or (-not $Game.ModFile -and -not $Game.TwoMods)) { return $res }
    if ($Game.RouteModMatrix) {
        $matrix = Get-RouteModMatrixPresence -Game $Game -FallbackRoot '' -Libs $Libs
        $res.CurrentPresent = [bool]($matrix.CurrentModAPresent -or $matrix.CurrentModBPresent)
        $res.DepotPresent = [bool]($matrix.DepotModAPresent -or $matrix.DepotModBPresent)
        $res.CurrentDir = $matrix.CurrentRoot; $res.DepotDir = $matrix.DepotRoot
        $res.BothPresent = [bool]($res.CurrentPresent -and $res.DepotPresent)
        $res.RouteCount = @($res.CurrentPresent,$res.DepotPresent | Where-Object { $_ }).Count
        $res.MultiplePresent = ($res.RouteCount -ge 2)
        $res.AnyPresent = [bool]($res.CurrentPresent -or $res.DepotPresent)
        foreach ($key in $matrix.Keys) { $res[$key] = $matrix[$key] }
        return $res
    }

    # The disposable installer lab must be hermetic. The ordinary scan filters
    # every candidate to Fake Games, but this shared DualMode helper also has
    # its own Steam-library probe. Without the same boundary it can adopt a
    # real modded Steam copy from the host and silently replace the fixture's
    # GameDir. Production never defines HubFileSystemLabRoot.
    $labSteamBoundary = $null
    if ($global:HubFileSystemLabRoot) {
        try { $labSteamBoundary = [IO.Path]::GetFullPath([string]$global:HubFileSystemLabRoot).TrimEnd('\') + '\' } catch {}
        if ($labSteamBoundary) {
            $Libs = @($Libs | Where-Object {
                try { [IO.Path]::GetFullPath([string]$_).StartsWith($labSteamBoundary,[StringComparison]::OrdinalIgnoreCase) }
                catch { $false }
            })
        } else {
            $Libs = @()
        }
    }
    # Most DualMode entries accept the same markers on both sides. A title
    # may explicitly narrow either side, though: PEAK must count only
    # Andrey04o's DLL for its recommended 2.1.a depot, never the legacy
    # AstienVR DLL living in a second pinned folder.
    $relList = @($Game.ModFile | Where-Object { $_ })
    if ($Game.ModFileAlt)  { $relList += $Game.ModFileAlt }
    if ($Game.ModFileAlt2) { $relList += $Game.ModFileAlt2 }
    $currentRelList = if ($Game.CurrentModFile) { @([string]$Game.CurrentModFile) } else { @($relList) }
    $depotRelList   = if ($Game.DepotModFile)   { @([string]$Game.DepotModFile) }   else { @($relList) }
    $currentRequiredList = @($Game.CurrentRequiredFile | Where-Object { $_ })
    $depotRequiredList   = @($Game.DepotRequiredFile | Where-Object { $_ })
    $legacyRequiredList  = @($Game.LegacyDepotRequiredFile | Where-Object { $_ })
    # Not just the catalog path: the user may pick the depot folder
    # freely, and the installer recorded the one that was chosen.
    $rootHasVr = {
        param([string]$Root, [string[]]$Markers, [string[]]$RequiredFiles, [string[]]$RouteBaseProofFiles, [bool]$CurrentRoute=$false)
        $driveCache = if ($global:ScanInProgress) { $global:ScanFallbackDriveReadyCache } else { @{} }
        $driveReady = $true
        if ($Root) {
            $driveGuard = Get-Command Test-ScanFallbackDriveReady -ErrorAction SilentlyContinue
            if ($driveGuard) { $driveReady = Test-ScanFallbackDriveReady -Path $Root -Cache $driveCache -DriveProbe $DriveProbe }
            elseif ($DriveProbe) { $driveReady = [bool](& $DriveProbe $Root) }
        }
        if (-not $Root -or -not $driveReady -or
            -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
        # A depot/current marker can outlive the base game just like an ordinary
        # ModFile. Route presence therefore uses the same base-game contract as
        # the main scan instead of allowing a dual-mode probe to resurrect a
        # stale folder after the general check rejected it.
        if($CurrentRoute){
            # Standalone scan callers need not load the optional Locate adapter.
            # Without it, retain the original strict marker/required-file contract.
            $externalCurrent=if($Game._ExternalVrProbe){$Game}elseif(Get-Command Get-LocatedExternalVrContract -ErrorAction SilentlyContinue){Get-LocatedExternalVrContract -Game $Game -Root $Root}else{$null}
            if($externalCurrent){
                $RequiredFiles=@($externalCurrent.CurrentRequiredFile)
                $Markers=if($externalCurrent.CurrentModFile){@([string]$externalCurrent.CurrentModFile)}else{@($externalCurrent.ModFile,$externalCurrent.ModFileAlt,$externalCurrent.ModFileAlt2|Where-Object {$_})}
                if(-not(Test-VrInstallEvidenceContract -Game $externalCurrent -Root $Root -Strict)){return $false}
            }
        }
        $originalValid=Test-BaseGameInstallProof -Game $Game -Root $Root
        if(-not $originalValid -and ($Game.RequiresRom -or $Game.SeparateLauncherBaseGame)){
            $originalRoot=$null
            if(Get-Command Get-RememberedStagedBaseGameRoot -ErrorAction SilentlyContinue){$originalRoot=Get-RememberedStagedBaseGameRoot -Game $Game -RuntimeRoot $Root}
            $originalValid=[bool]($originalRoot -and (Test-BaseGameInstallProof -Game $Game -Root $originalRoot))
        }
        if(-not $originalValid){return $false}
        if (@($RouteBaseProofFiles | Where-Object { $_ }).Count -gt 0) {
            foreach ($rawGroup in @($RouteBaseProofFiles | Where-Object { $_ })) {
                $matched = $false
                foreach ($relative in (([string]$rawGroup) -split '\|')) {
                    $relative = $relative.Trim()
                    if ($relative -and (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { $matched=$true; break }
                }
                if (-not $matched) { return $false }
            }
        }
        if ($Game.TwoMods) {
            $aMarker = $false; $bMarker = $false
            if ($Game.ModAProbeAbs) { $aMarker = Test-AbsolutePathMarker -Values $Game.ModAProbeAbs }
            if (-not $aMarker -and $Game.ModAProbeFile) { $aMarker = Test-RelativePathMarker -Root $Root -Values $Game.ModAProbeFile }
            if ($Game.ModBProbeAbs) { $bMarker = Test-AbsolutePathMarker -Values $Game.ModBProbeAbs }
            if (-not $bMarker -and $Game.ModBProbeFile) { $bMarker = Test-RelativePathMarker -Root $Root -Values $Game.ModBProbeFile }
            if ($aMarker -and $Game.ModARequiredFile) { $aMarker = Test-RelativePathMarker -Root $Root -Values $Game.ModARequiredFile }
            if ($bMarker -and $Game.ModBRequiredFile) { $bMarker = Test-RelativePathMarker -Root $Root -Values $Game.ModBRequiredFile }
            $common = ($Game.LaunchExe -and (Test-Path -LiteralPath (Join-Path $Root $Game.LaunchExe)))
            $aLaunch = ($Game.ModASub -and $Game.ModALaunch -and (Test-Path -LiteralPath (Join-Path $Root (Join-Path $Game.ModASub $Game.ModALaunch))))
            $bLaunch = ($Game.ModBSub -and $Game.ModBLaunch -and (Test-Path -LiteralPath (Join-Path $Root (Join-Path $Game.ModBSub $Game.ModBLaunch))))
            if ($Game.EldenRingDirectMotionLaunch) { return ($aMarker -or $bMarker) }
            return (($aMarker -and ($aLaunch -or $common)) -or ($bMarker -and ($bLaunch -or $common)))
        }
        $markerFound = $false
        foreach ($rel in $Markers) {
            if (Test-Path -LiteralPath (Join-Path $Root $rel)) { $markerFound = $true; break }
        }
        if (-not $markerFound) { return $false }
        foreach ($required in @($RequiredFiles | Where-Object { $_ })) {
            if (-not (Test-Path -LiteralPath (Join-Path $Root $required) -PathType Leaf)) { return $false }
        }
        if ($Game.VrInstallPythonRuntimeDir -and
            -not (Test-VrInstallEvidenceContract -Game $Game -Root $Root)) { return $false }
        return $true
    }

    $depotDir = $null
    if ($Game.DepotPath) {
        foreach ($cand in (Get-DepotCandidatePaths -Game $Game)) {
            if (@($Game.DepotForbiddenFiles | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $cand ([string]$_)) -PathType Leaf) }).Count) { continue }
            if ((& $rootHasVr $cand $depotRelList $depotRequiredList @($Game.DepotBaseGameProofFiles)) -and
                (Test-DepotPinnedReceiptContract -Game $Game -Root $cand)) { $depotDir = $cand }
            if ($depotDir) { break }
        }
    }
    if ($depotDir) {
        $res.DepotPresent = $true
        $res.DepotDir = $depotDir
    }

    # A few breaking-update titles deliberately keep a third, original
    # depot. It is a fully independent launch route: when it coexists with
    # Current or the recommended depot it may occupy one half of the compact
    # tile split. Require both its exact mod marker and launcher so a stale
    # folder or a different depot cannot impersonate it.
    if ($Game.LegacyDepotPath -and $Game.LegacyDepotModFile -and
        (Get-Command Get-LegacyDepotCandidatePaths -ErrorAction SilentlyContinue)) {
        foreach ($cand in (Get-LegacyDepotCandidatePaths -Game $Game)) {
            if (-not $cand -or -not (& $rootHasVr $cand @([string]$Game.LegacyDepotModFile) $legacyRequiredList @($Game.LegacyDepotBaseGameProofFiles))) { continue }
            if (-not (Test-LegacyDepotRouteReady -Game $Game -Root $cand)) { continue }
            $res.LegacyPresent = $true
            $res.LegacyDir = $cand
            if(-not $NoStateMigration){try { Write-PersistentGameStateValue -Game $Game -Name 'installed_path_legacy_depot' -Value $cand } catch {}}
            break
        }
    }

    # Standalone successors can coexist with an older standalone route. They
    # do not live in a Steam library, so probe their catalog/remembered roots
    # explicitly and keep their state separate from the legacy executable.
    if ($Game.CurrentStandalonePaths -or $rememberedCurrentCandidate -or $CurrentCandidatePaths.Count) {
        $currentCandidates=@($CurrentCandidatePaths);if(Get-Command Get-CurrentStandaloneCandidatePaths -ErrorAction SilentlyContinue){$currentCandidates+=@(Get-CurrentStandaloneCandidatePaths -Game $Game)}
        foreach ($cand in @($currentCandidates|Where-Object {$_}|Select-Object -Unique)) {
            if (-not $cand) { continue }
            if(-not $Game.CurrentStandalonePaths -and -not $CurrentCandidatePaths.Count -and $depotDir -and
                [IO.Path]::GetFullPath($depotDir).TrimEnd([char[]]'\/') -ieq [IO.Path]::GetFullPath($cand).TrimEnd([char[]]'\/')){
                $typedCurrent=$null;try{$typedCurrent=Read-PersistentGameStateValue -Game $Game -Name installed_path_current}catch{}
                if(-not $typedCurrent -or [IO.Path]::GetFullPath($typedCurrent).TrimEnd([char[]]'\/') -ine [IO.Path]::GetFullPath($cand).TrimEnd([char[]]'\/')){continue}
            }
            $historicalCurrentHit=$false
            $currentHit=& $rootHasVr $cand $currentRelList $currentRequiredList @($Game.CurrentBaseGameProofFiles) $true
            if(-not $currentHit -and $Game.CurrentLegacyModFile -and $Game.CurrentLegacyRequiredFile -and
                -not ($Game.CurrentLegacyExcludedFile -and (Test-Path -LiteralPath (Join-Path $cand $Game.CurrentLegacyExcludedFile)))){
                $historicalCurrentHit=& $rootHasVr $cand @($Game.CurrentLegacyModFile,$Game.CurrentLegacyModFileAlt | Where-Object {$_}) @($Game.CurrentLegacyRequiredFile) @($Game.CurrentBaseGameProofFiles)
                $currentHit=$historicalCurrentHit
            }
            if(-not $currentHit){continue}
            if (-not $historicalCurrentHit -and $Game.CurrentLaunchExe -and
                -not (Test-Path -LiteralPath (Join-Path $cand $Game.CurrentLaunchExe) -PathType Leaf)) { continue }
            $res.CurrentPresent = $true
            $res.CurrentDir = $cand
            if(-not $NoStateMigration){try { Write-PersistentGameStateValue -Game $Game -Name 'installed_path_current' -Value $cand } catch {}}
            break
        }
    }
    if (-not $Game.SteamFolder) {
        $res.BothPresent = [bool]($res.CurrentPresent -and $res.DepotPresent)
        $res.RouteCount = @($res.CurrentPresent, $res.DepotPresent, $res.LegacyPresent | Where-Object { $_ }).Count
        $res.MultiplePresent = ($res.RouteCount -ge 2)
        $res.AnyPresent = [bool]($res.CurrentPresent -or $res.DepotPresent -or $res.LegacyPresent)
        return $res
    }
    if ((-not $global:HubFileSystemLabRoot) -and (-not $Libs -or $Libs.Count -eq 0)) {
        $Libs = if (Get-Command Get-HubSteamLibraries -ErrorAction SilentlyContinue) {
            @(Get-HubSteamLibraries)
        } else { @() }
    }
    foreach ($lib in $Libs) {
        if($Game.CurrentPreferRememberedPath -and $res.CurrentPresent){break}
        $c = Join-Path $lib "steamapps\common\$($Game.SteamFolder)"
        if (-not (Test-Path -LiteralPath $c -PathType Container)) { continue }
        $currentHit = & $rootHasVr $c $currentRelList $currentRequiredList @($Game.CurrentBaseGameProofFiles) $true
        if (-not $currentHit -and $Game.CurrentLegacyModFile -and $Game.CurrentLegacyRequiredFile -and
            -not ($Game.CurrentLegacyExcludedFile -and (Test-Path -LiteralPath (Join-Path $c $Game.CurrentLegacyExcludedFile)))) {
            $currentHit = & $rootHasVr $c @($Game.CurrentLegacyModFile,$Game.CurrentLegacyModFileAlt | Where-Object {$_}) @($Game.CurrentLegacyRequiredFile) @($Game.CurrentBaseGameProofFiles)
        }
        if ($currentHit) {
            $res.CurrentPresent = $true
            $res.CurrentDir  = $c
            break
        }
    }
    $res.BothPresent = ($res.CurrentPresent -and $res.DepotPresent)
    $res.RouteCount = @($res.CurrentPresent, $res.DepotPresent, $res.LegacyPresent | Where-Object { $_ }).Count
    $res.MultiplePresent = ($res.RouteCount -ge 2)
    $res.AnyPresent = [bool]($res.CurrentPresent -or $res.DepotPresent -or $res.LegacyPresent)
    return $res
}

# Pick the root that actually proved a DualMode installation. This must never
# fall back to an unmodded Steam directory merely because ordinary game
# discovery found it first. Current remains the default when several variants
# coexist, followed by the recommended depot and finally the original legacy
# depot that is exposed only on the detail page.
function global:Get-DualModePreferredRoot {
    param($Presence)
    if (-not $Presence) { return $null }
    if ($Presence.CurrentPresent -and $Presence.CurrentDir) { return [string]$Presence.CurrentDir }
    if ($Presence.DepotPresent -and $Presence.DepotDir) { return [string]$Presence.DepotDir }
    if ($Presence.LegacyPresent -and $Presence.LegacyDir) { return [string]$Presence.LegacyDir }
    return $null
}

# Some installers let the user choose a stable GitHub release or the newest
# prerelease. Keep future update checks on the installed channel instead of
# silently moving a stable user to a test build (or hiding test-build updates).
function global:Get-GithubPrereleasePreference {
    param($Game, [string]$GameDir)
    $default = [bool]$Game.GithubPrerelease
    if (-not $Game -or -not $Game.GithubChannelChoice -or -not $Game.GithubChannelFile) { return $default }
    $roots = @()
    if ($GameDir) { $roots += $GameDir }
    try {
        $recorded = Read-InstalledPath -Game $Game
        if ($recorded -and $recorded -notin $roots) { $roots += $recorded }
    } catch {}
    foreach ($root in $roots) {
        try {
            $marker = Join-HubPathLexical $root $Game.GithubChannelFile
            if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { continue }
            $channel = (Get-Content -LiteralPath $marker -Raw -ErrorAction Stop).Trim().ToLowerInvariant()
            if ($channel -in @("prerelease","pre","preview","test")) { return $true }
            if ($channel -in @("stable","latest","release")) { return $false }
        } catch {}
    }
    return $default
}

# Online state for the scan's per-game version checks. Once the server
# is found unreachable we stop probing for the rest of the session; an
# explicit Check Installed click clears it to probe fresh again.
$global:HubScanOnlineDown = $false
$global:HubThunderstoreOnlineDown = $false

# Single bounded online GET for the scan's per-game version checks.
# Circuit breaker: once the server is unreachable we retry ONCE after
# a 3s wait; if that also fails we flip $global:HubScanOnlineDown and
# every later call returns $null immediately - so the scan can never
# grind on dozens of back-to-back timeouts. Returns the response or $null.
function global:Invoke-ScanWebGet {
    param([string]$Uri, [hashtable]$Headers)
    if ($global:HubScanOnlineDown) { return $null }
    if($Uri -match '^https://api\.github\.com/repos/[^/]+/[^/]+/(?:releases|commits)(?:[/?]|$)'){
        try{
            $data=Invoke-PCVRRestMethod -Uri $Uri -Headers $Headers -TimeoutSec 2 -ErrorAction Stop
            return [pscustomobject]@{Content=ConvertTo-Json -InputObject $data -Depth 20;StatusCode=200}
        }catch{
            # Keep the existing first-timeout budget. A quota/404 is local to
            # this source and never trips the scan-wide connectivity breaker.
            if($_.Exception.Message -match '(?i)timed?\s*out|timeout|Zeit.+(?:schreit|abgelaufen)|time budget exhausted'){$global:HubScanOnlineDown=$true}
            return $null
        }
    }
    try {
        if ($Headers) {
            return (Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 2 -Headers $Headers -EA Stop)
        } else {
            return (Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 2 -EA Stop)
        }
    } catch {
        # First miss: assume the server/network is unreachable and stop
        # ALL further online checks for the rest of the scan. No retry,
        # no sleep - a slow or dead server must never freeze the UI
        # thread. Worst case is one ~2s timeout for the whole scan.
        $global:HubScanOnlineDown = $true
        return $null
    }
}

# Thunderstore is an independent release source.  A GitHub/web timeout must
# never suppress it: that used to make every later Thunderstore tile silently
# skip its update check because Invoke-ScanWebGet shared one global breaker for
# every host.  Keep a small persistent package cache and a Thunderstore-only
# breaker instead.  On a transient failure the last known package record is
# returned, so update badges stay stable without holding the UI on repeated
# network timeouts.
function global:Get-ScanNightlyReleaseCached {
    param([string]$Repo)
    if(-not $Repo){return $null}
    if($null -eq $script:scanNightlyDisk){
        $script:scanNightlyDisk=@{}
        $root=Get-HubVersionCacheRoot
        $file=if($root){Join-Path $root '.nightly_version_cache'}else{''}
        if($file -and [IO.File]::Exists($file)){
            try{
                $data=[IO.File]::ReadAllText($file)|ConvertFrom-Json
                foreach($entry in $data.PSObject.Properties){
                    $assets=@{};foreach($asset in $entry.Value.Assets.PSObject.Properties){$assets[$asset.Name]=[string]$asset.Value}
                    $script:scanNightlyDisk[$entry.Name]=@{Tag=[string]$entry.Value.Tag;Assets=$assets;checked=[string]$entry.Value.checked}
                }
            }catch{}
        }
    }
    return $script:scanNightlyDisk[$Repo]
}

function global:Get-ThunderstorePackageCached {
    param([string]$Author, [string]$Package)
    if (-not $Author -or -not $Package) { return $null }

    $cacheKey = "$Author-$Package"
    $ttlHours = 1
    if ($null -eq $script:tsVerCache) {
        $script:tsVerCache = @{}
        $cacheRoot = Get-HubVersionCacheRoot
        $script:tsVerCacheFile = if ($cacheRoot) { Join-Path $cacheRoot '.ts_version_cache' } else { $null }
        if ($script:tsVerCacheFile -and (Test-Path -LiteralPath $script:tsVerCacheFile -PathType Leaf)) {
            try {
                $raw = Get-Content -LiteralPath $script:tsVerCacheFile -Raw -ErrorAction Stop | ConvertFrom-Json
                foreach ($p in $raw.PSObject.Properties) {
                    $script:tsVerCache[$p.Name] = @{
                        version      = [string]$p.Value.version
                        deprecated   = [bool]$p.Value.deprecated
                        checked      = [string]$p.Value.checked
                        date         = [string]$p.Value.date
                        download     = [string]$p.Value.download
                        dependencies = @($p.Value.dependencies | ForEach-Object { [string]$_ })
                    }
                }
            } catch {}
        }
    }

    $toResult = {
        param($Entry)
        if (-not $Entry -or -not $Entry.version) { return $null }
        return [pscustomobject]@{
            Version      = [string]$Entry.version
            Deprecated   = [bool]$Entry.deprecated
            Date         = [string]$Entry.date
            DownloadUrl  = [string]$Entry.download
            Dependencies = @($Entry.dependencies)
        }
    }

    $entry = $script:tsVerCache[$cacheKey]
    $now = [DateTime]::UtcNow
    if ($entry -and $entry.version -and $entry.checked) {
        try {
            $age = ($now - [DateTime]::Parse($entry.checked, $null, [Globalization.DateTimeStyles]::RoundtripKind)).TotalHours
            if ($age -lt $ttlHours) { return (& $toResult $entry) }
        } catch {}
    }

    if (-not $global:HubThunderstoreOnlineDown -and -not $global:HubVersionCacheOnly) {
        try {
            $uri = "https://thunderstore.io/api/experimental/package/$Author/$Package/"
            $data = Invoke-RestMethod -Uri $uri -Headers @{ 'User-Agent'='PCVR-Mods-Hub' } -TimeoutSec 3 -ErrorAction Stop
            if ($data -and $data.latest -and $data.latest.version_number) {
                $entry = @{
                    version      = [string]$data.latest.version_number
                    deprecated   = [bool]($data.is_deprecated -eq $true)
                    checked      = $now.ToString('o')
                    date         = [string]$data.latest.date_created
                    download     = [string]$data.latest.download_url
                    dependencies = @($data.latest.dependencies | ForEach-Object { [string]$_ })
                }
                $script:tsVerCache[$cacheKey] = $entry
                if ($script:tsVerCacheFile) {
                    try {
                        $obj = @{}
                        foreach ($k in $script:tsVerCache.Keys) { $obj[$k] = $script:tsVerCache[$k] }
                        ($obj | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $script:tsVerCacheFile -Encoding UTF8 -Force
                    } catch {}
                }
                return (& $toResult $entry)
            }
        } catch {
            # A missing package is local to that catalog entry; connection and
            # timeout failures trip only Thunderstore's breaker for this scan.
            if ($_.Exception.Message -notmatch '(?i)404|not found|nicht gefunden') {
                $global:HubThunderstoreOnlineDown = $true
            }
        }
    }

    if ($entry -and $entry.version) { return (& $toResult $entry) }
    return $null
}

# Read only the version proof that belongs to one physical Current route.
# The canonical installed_version value deliberately is not a fallback here:
# a depot installer may have written that shared value last, and using it for
# Current would once again merge two independent version spaces.
function global:Get-CurrentRouteVersionProof {
    param($Game, [string]$Root, [ValidateSet('Thunderstore','Release')][string]$Source = 'Release')
    if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $null }

    if ($Game.Id -eq 'bendy-vr') {
        $marker=Join-Path $Root '.pcvrhub_inkvr_version'
        if(Test-Path -LiteralPath $marker -PathType Leaf) {
            $value=[IO.File]::ReadAllText($marker).Trim()
            if(Test-IsTrackableInstalledVersion $value){return $value}
        }
        # A manually installed InkVR must not inherit the old Team Beef 1.2.2
        # stamp left in the same Steam folder. Read the actual plugin instead.
        $dll=Join-Path $Root 'BepInEx\plugins\InkVR\InkVR.dll'
        if(Test-Path -LiteralPath $dll -PathType Leaf) {
            $version=[Diagnostics.FileVersionInfo]::GetVersionInfo($dll).ProductVersion
            if($version -match '^(v?\d+(?:\.\d+)+)'){return $Matches[1]}
        }
        return $null
    }
    if ($Source -eq 'Thunderstore') {
        foreach ($key in @("$($Game.ThunderstoreAuthor)-$($Game.ThunderstorePackage)", "$($Game.ThunderstorePackage)")) {
            try {
                $marker = Join-Path $Root "BepInEx\.ts_versions\$key"
                if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { continue }
                $candidate = (Get-Content -LiteralPath $marker -Raw -ErrorAction Stop).Trim()
                if (Test-IsTrackableInstalledVersion -Version $candidate) { return $candidate }
            } catch {}
        }
        return $null
    }

    try {
        $proof = Read-InstalledVersionProof -Game $Game -GameDir $Root
        if (Test-IsTrackableInstalledVersion -Version $proof) { return ([string]$proof).Trim() }
    } catch {}
    try {
        $manifest = Read-HubInstallManifestVersion -Game $Game -GameDir $Root
        if (Test-IsTrackableInstalledVersion -Version $manifest) { return ([string]$manifest).Trim() }
    } catch {}
    try {
        $stamp = Read-VersionStampFile -Path (Get-GameStampPath -GameDir $Root)
        if (Test-IsTrackableInstalledVersion -Version $stamp) { return ([string]$stamp).Trim() }
    } catch {}
    return $null
}

# Resolve the route that may follow a moving online release. Current is the
# only moving side. A pinned Depot/Legacy installation remains VR Ready, but it
# must not impersonate Current merely because both once carried the same mod
# version. Consequently a depot-only installation advertises Current as an
# available update even when the pinned version number happens to equal the
# latest online number.
function global:Get-CurrentRouteInstallState {
    param(
        $Game, $Presence, [string]$GameDir, [string]$FallbackVersion,
        [ValidateSet('Thunderstore','Release')][string]$Source = 'Release'
    )

    $routeAware = [bool](($Game.CurrentRouteUpdate -or $Game.ThunderstoreCurrentRouteUpdate) -and $Game.DualMode -and $Presence)
    if (-not $routeAware) {
        return [pscustomobject]@{
            Version=$FallbackVersion; Route='Detected'; Root=$GameDir
            CurrentMissing=$false; LegacyOnly=$false; RouteSpecific=$false
            UnversionedCurrent=$false; UnversionedMaintained=$false
        }
    }

    if ($Presence.CurrentPresent -and $Presence.CurrentDir) {
        $root = [string]$Presence.CurrentDir
        $version = Get-CurrentRouteVersionProof -Game $Game -Root $root -Source $Source
        $unversioned = -not [bool]$version
        return [pscustomobject]@{
            Version=$version; Route='Current'; Root=$root
            CurrentMissing=$false; LegacyOnly=$false; RouteSpecific=$true
            UnversionedCurrent=$unversioned; UnversionedMaintained=$unversioned
        }
    }

    $route = if ($Presence.DepotPresent) { 'Depot' } elseif ($Presence.LegacyPresent) { 'Legacy' } else { 'Detected' }
    $root = if ($route -eq 'Depot') { $Presence.DepotDir } elseif ($route -eq 'Legacy') { $Presence.LegacyDir } else { $GameDir }
    $currentMissing = ($route -in @('Depot','Legacy'))
    return [pscustomobject]@{
        Version=$(if ($currentMissing) { $null } else { $FallbackVersion })
        Route=$route; Root=$root; CurrentMissing=$currentMissing
        LegacyOnly=($route -eq 'Legacy'); RouteSpecific=$currentMissing
        UnversionedCurrent=$false; UnversionedMaintained=$false
    }
}

# Compatibility name retained for tests and existing scan call sites.
function global:Get-ThunderstoreRouteInstallState {
    param($Game, $Presence, [string]$GameDir, [string]$FallbackVersion)
    return Get-CurrentRouteInstallState -Game $Game -Presence $Presence -GameDir $GameDir `
        -FallbackVersion $FallbackVersion -Source Thunderstore
}

function global:Get-CodebergLatestTagCached {
    # Like Get-GithubLatestTagCached, but for Codeberg. Codeberg runs on
    # FORGEJO and has the same API shape as Gitea:
    #   https://codeberg.org/api/v1/repos/<owner>/<repo>/releases?limit=1
    # The first element carries tag_name. Unlike GitHub there is no tight
    # 60/hour limit, so the API comes FIRST here and the RSS feed
    # (/releases.rss, also served by Forgejo) is only the fallback.
    #
    # A separate cache file .cb_version_cache, so Codeberg and GitHub keys
    # can never collide. Same TTL of six hours, same behaviour on errors:
    # the LAST known tag is returned, so the update state stays stable.
    param([string]$Repo, [switch]$IncludePrerelease)
    if (-not $Repo) { return $null }
    $cacheKey = if ($IncludePrerelease) { "$Repo#pre" } else { $Repo }
    $ttlHours = 6
    if ($null -eq $script:cbVerCache) {
        $script:cbVerCache = @{}
        $script:cbVerCacheFile = Join-Path $global:scriptDir ".cb_version_cache"
        if (Test-Path $script:cbVerCacheFile) {
            try {
                $raw = Get-Content $script:cbVerCacheFile -Raw | ConvertFrom-Json
                foreach ($p in $raw.PSObject.Properties) {
                    $script:cbVerCache[$p.Name] = @{ tag = [string]$p.Value.tag; checked = [string]$p.Value.checked }
                }
            } catch {}
        }
    }
    $entry = $script:cbVerCache[$cacheKey]
    $now = [DateTime]::UtcNow
    if ($entry -and $entry.tag -and $entry.checked) {
        try {
            $age = ($now - [DateTime]::Parse($entry.checked, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).TotalHours
            if ($age -lt $ttlHours) { return [string]$entry.tag }
        } catch {}
    }
    # The same guard as with GitHub: if an earlier online check failed in
    # THIS scan, the network is not touched again - otherwise timeouts
    # stack up into a long freeze of the interface.
    if ($global:HubScanOnlineDown -or $global:HubVersionCacheOnly) {
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
    $tag = $null
    try {
        $rel = Invoke-RestMethod -Uri "https://codeberg.org/api/v1/repos/$Repo/releases?limit=5" `
                   -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 3 -EA Stop 2>$null
        foreach ($r in @($rel)) {
            if ($r.draft) { continue }
            if ($r.prerelease -and -not $IncludePrerelease) { continue }
            if ($r.tag_name) { $tag = [string]$r.tag_name.Trim(); break }
        }
    } catch {
        Write-Host "[CodebergCheck] ${Repo}: API check failed ($($_.Exception.Message)) - trying the RSS feed"
    }
    if (-not $tag) {
        try {
            $rssResp = Invoke-WebRequest -Uri "https://codeberg.org/$Repo/releases.rss" `
                           -UseBasicParsing -TimeoutSec 3 `
                           -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" } -EA Stop
            $rss = [string]$rssResp.Content
            if ($rss) {
                # Forgejo puts the tag into the entry's <link> address:
                #   https://codeberg.org/<owner>/<repo>/releases/tag/<tag>
                $m = [regex]::Match($rss, [regex]::Escape($Repo) + '/releases/tag/([^<"&]+)')
                if ($m.Success) {
                    $t = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value).Trim()
                    if ($t) { $tag = $t }
                }
            }
        } catch {
            Write-Host "[CodebergCheck] ${Repo}: the RSS feed failed too ($($_.Exception.Message))"
            # Only a genuine connection failure may flip the scan-wide
            # switch - being rate limited means the host is reachable.
            if ($_.Exception.Message -notmatch "rate limit|403|forbidden") { $global:HubScanOnlineDown = $true }
        }
    }
    if ($tag) {
        $script:cbVerCache[$cacheKey] = @{ tag = $tag; checked = $now.ToString("o") }
        try {
            $obj = @{}
            foreach ($k in $script:cbVerCache.Keys) { $obj[$k] = $script:cbVerCache[$k] }
            ($obj | ConvertTo-Json) | Set-Content -Path $script:cbVerCacheFile -Encoding UTF8 -Force
        } catch {}
        return $tag
    }
    if ($entry -and $entry.tag) { return [string]$entry.tag }
    return $null
}

function global:Select-GithubReleaseTagWithAsset {
    param($Releases, [bool]$IncludePrerelease, [string[]]$RequiredAssetPatterns, [string]$AssetVersionPattern='')
    $patterns = @($RequiredAssetPatterns | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    if ($patterns.Count -eq 0) { return $null }
    foreach ($candidate in @($Releases | Sort-Object -Property published_at -Descending)) {
        $candidateTag = ([string]$candidate.tag_name).Trim()
        if ($candidate.draft -or (-not $IncludePrerelease -and $candidate.prerelease) -or
            -not $candidateTag -or $candidateTag -match '(?i)source|hub-patch|sdk|symbols|broken|diagnostic') { continue }
        foreach ($pattern in $patterns) {
            $assetMatches = @($candidate.assets | Where-Object { ([string]$_.name) -match $pattern -and $_.browser_download_url })
            if ($assetMatches.Count -eq 1) {
                if ($AssetVersionPattern) {
                    $match=[regex]::Match([string]$assetMatches[0].name,$AssetVersionPattern)
                    if ($match.Success -and $match.Groups.Count -gt 1 -and $match.Groups[1].Value -match '\d') { return [string]$match.Groups[1].Value }
                    continue
                }
                return $candidateTag
            }
        }
    }
    return $null
}

function global:Test-GithubReleaseIsNewer {
    param([string]$Repo,[string]$Installed,[string]$Online,[string]$TagOrder='',
        [string[]]$SupersededInstalledVersions=@(),[string]$ResetMinimumVersion='')
    if($TagOrder -ne 'published'){
        return Test-OnlineVersionIsNewer -Installed $Installed -Online $Online -SupersededInstalledVersions $SupersededInstalledVersions -ResetMinimumVersion $ResetMinimumVersion
    }
    if(-not $Installed -or -not $Online -or $Installed.Trim() -ieq $Online.Trim()){return $false}
    $dates=@()
    foreach($tag in @($Installed,$Online)){
        $key=$Repo+'#'+$tag
        if($null -eq $script:ghPublicationDates){
            $script:ghPublicationDates=@{}
            $root=if(Get-Command Get-HubVersionCacheRoot -ErrorAction SilentlyContinue){Get-HubVersionCacheRoot}else{$null}
            $script:ghPublicationDatesFile=if($root){Join-Path $root '.gh_publication_cache'}else{$null}
            if($script:ghPublicationDatesFile -and (Test-Path -LiteralPath $script:ghPublicationDatesFile)){
                try{ $raw=Get-Content -LiteralPath $script:ghPublicationDatesFile -Raw | ConvertFrom-Json;foreach($p in $raw.PSObject.Properties){$script:ghPublicationDates[$p.Name]=$p.Value} }catch{}
            }
        }
        $entry=$script:ghPublicationDates[$key];$date=[DateTimeOffset]::MinValue
        $valid=$entry -and [DateTimeOffset]::TryParse([string]$entry.published,[ref]$date)
        $fresh=$false
        if($valid){try{$fresh=([DateTimeOffset]::UtcNow-[DateTimeOffset]::Parse([string]$entry.checked)).TotalHours -lt 6}catch{}}
        if(-not $fresh -and -not $global:HubScanOnlineDown -and -not $global:HubVersionCacheOnly){
            try{
                $release=Invoke-PCVRRestMethod -Uri ('https://api.github.com/repos/'+$Repo+'/releases/tags/'+[uri]::EscapeDataString($tag)) -TimeoutSec 3
                $published=[DateTimeOffset]::MinValue
                if($release.tag_name -ceq $tag -and -not $release.draft -and [DateTimeOffset]::TryParse([string]$release.published_at,[ref]$published)){
                    $date=$published;$valid=$true
                    $script:ghPublicationDates[$key]=@{published=$date.ToUniversalTime().ToString('o');checked=[DateTimeOffset]::UtcNow.ToString('o')}
                    if($script:ghPublicationDatesFile){try{$script:ghPublicationDates | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $script:ghPublicationDatesFile -Encoding UTF8}catch{}}
                }
            }catch{}
        }
        if(-not $valid){return $false}
        $dates+=,$date
    }
    return $dates[1] -gt $dates[0]
}

function global:Get-GithubLatestTagCached {
    # Return the latest GitHub release tag for $Repo, cached on disk with a TTL
    # so repeated scans/restarts do not exhaust the 60/hour unauthenticated
    # GitHub API limit. On a rate-limit or transient error the LAST known tag is
    # returned (so the update state stays stable) and the shared online-down
    # flag is NOT tripped - a 403 means the host is reachable, just limited, and
    # must not kill the other checks (Alien Isolation web check, other repos).
    #
    # -IncludePrerelease: some mods only ship PRE-releases (e.g. Halo MCC VR is
    # an alpha). GitHub's /releases/latest redirect ignores prereleases, so for
    # those repos it 404s and we would never see an update. When this switch is
    # set we instead read the newest entry from the GitHub API /releases list
    # (which includes prereleases) and use its tag. Cached under a distinct key
    # so it never collides with a normal /latest lookup of the same repo.
    param([string]$Repo, [switch]$IncludePrerelease, [string[]]$RequiredAssetPatterns=@(), [string]$AssetVersionPattern='', [switch]$AssetTimestampVersion, [string]$TagOrder='')
    if (-not $Repo) { return $null }
    $assetPatterns = @($RequiredAssetPatterns | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    if (!$assetPatterns.Count) { $assetPatterns = @(Get-PCVRWindowsReleaseAssetPattern) }
    $cacheKey=Get-PCVRGithubVersionCacheKey -Repo $Repo -IncludePrerelease ([bool]$IncludePrerelease) -AssetPatterns $assetPatterns -AssetVersionPattern $AssetVersionPattern -AssetTimestampVersion ([bool]$AssetTimestampVersion) -TagOrder $TagOrder
    $ttlHours = 6
    if ($null -eq $script:ghVerCache) {
        $script:ghVerCache = @{}
        $cacheRoot = Get-HubVersionCacheRoot
        $script:ghVerCacheFile = if ($cacheRoot) { Join-Path $cacheRoot '.gh_version_cache' } else { $null }
        if ($script:ghVerCacheFile -and (Test-Path -LiteralPath $script:ghVerCacheFile -PathType Leaf)) {
            try {
                $raw = Get-Content -LiteralPath $script:ghVerCacheFile -Raw | ConvertFrom-Json
                foreach ($p in $raw.PSObject.Properties) {
                    $script:ghVerCache[$p.Name] = @{ tag = [string]$p.Value.tag; checked = [string]$p.Value.checked }
                }
            } catch {}
        }
    }
    $entry = $script:ghVerCache[$cacheKey]
    $now = [DateTime]::UtcNow
    if ($entry -and $entry.tag -and $entry.checked) {
        try {
            $age = ($now - [DateTime]::Parse($entry.checked, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).TotalHours
            if ($entry.tag -match '(?i)source|hub-patch|sdk|symbols|broken|diagnostic') {
                Write-Host "[GithubCheck] ${Repo}: cached tag '$($entry.tag)' is a source release - discarding it"
                $script:ghVerCache.Remove($cacheKey)
            } elseif ($age -lt $ttlHours) {
                return [string]$entry.tag
            }
        } catch {}
    }
    if ($global:HubScanOnlineDown -or $global:HubVersionCacheOnly) {
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
    if ($assetPatterns.Count -gt 0) {
        # The Hub badge and installer must identify the same publisher asset.
        # Scans use the bounded transport mode so a slow/offline GitHub check
        # cannot hold the UI for the full installer download time.
        try {
            if (-not (Get-Command Resolve-GitHubReleaseAsset -ErrorAction SilentlyContinue)) {
                . (Join-Path $PSScriptRoot 'GitHubTransport.ps1')


            }
            $resolved=Resolve-GitHubReleaseAsset -Repo $Repo -AssetPatterns $assetPatterns `
                -IncludePrerelease ([bool]$IncludePrerelease) -SkipReleasesWithoutMatchingAsset -ScanFast -TagOrder $TagOrder
            if ($resolved.Resolved) {
                $tag=[string]$resolved.Tag
                if($AssetTimestampVersion){
                    $tag=Get-PCVRGitHubSelectedAssetTimestamp -Release $resolved
                    if($tag -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$'){$tag=''}
                }
                if ($AssetVersionPattern) {
                    $assetMatch=[regex]::Match([string]$resolved.AssetName,$AssetVersionPattern)
                    $tag=if($assetMatch.Success -and $assetMatch.Groups.Count -gt 1 -and
                        $assetMatch.Groups[1].Value -match '\d') {[string]$assetMatch.Groups[1].Value}else{''}
                }
                if ($tag) {
                    $script:ghVerCache[$cacheKey] = @{ tag=$tag; checked=$now.ToString('o') }
                    if ($script:ghVerCacheFile) { try {
                        $obj=@{}
                        foreach ($k in $script:ghVerCache.Keys) { $obj[$k]=$script:ghVerCache[$k] }
                        ($obj | ConvertTo-Json) | Set-Content -LiteralPath $script:ghVerCacheFile -Encoding UTF8 -Force
                    } catch {} }
                    return $tag
                }
                Write-Host "[GithubCheck] ${Repo}: publisher asset does not provide the catalog version pattern"
            } else {
                Write-Host "[GithubCheck] ${Repo}: current installable asset not verified ($($resolved.Error))"
            }
        } catch {
            Write-Host "[GithubCheck] ${Repo}: release check failed ($($_.Exception.Message))"
        }
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
}

# Some maintained mods publish a mutable branch instead of GitHub Releases.
# Track the branch head by its committer timestamp, formatted as a normal
# numeric version so the Hub's existing genuine-newer comparison remains the
# single update rule. The value shares the six-hour GitHub disk cache but uses
# a distinct key and can never collide with a release tag.
function global:Get-GithubLatestCommitCached {
    param([string]$Repo, [string]$Branch = 'main')
    if (-not $Repo) { return $null }
    $cacheKey = "$Repo#commit:$Branch"
    $ttlHours = 6
    if ($null -eq $script:ghVerCache) {
        $script:ghVerCache = @{}
        $cacheRoot = Get-HubVersionCacheRoot
        $script:ghVerCacheFile = if ($cacheRoot) { Join-Path $cacheRoot '.gh_version_cache' } else { $null }
        if ($script:ghVerCacheFile -and (Test-Path -LiteralPath $script:ghVerCacheFile -PathType Leaf)) {
            try {
                $raw = Get-Content -LiteralPath $script:ghVerCacheFile -Raw | ConvertFrom-Json
                foreach ($p in $raw.PSObject.Properties) {
                    $script:ghVerCache[$p.Name] = @{ tag=[string]$p.Value.tag; checked=[string]$p.Value.checked }
                }
            } catch {}
        }
    }
    $entry = $script:ghVerCache[$cacheKey]
    $now = [DateTime]::UtcNow
    if ($entry -and $entry.tag -and $entry.checked) {
        try {
            $age = ($now - [DateTime]::Parse($entry.checked, $null, [Globalization.DateTimeStyles]::RoundtripKind)).TotalHours
            if ($age -lt $ttlHours) { return [string]$entry.tag }
        } catch {}
    }
    if ($global:HubScanOnlineDown -or $global:HubVersionCacheOnly) {
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
    try {
        $branchEscaped = [Uri]::EscapeDataString($Branch)
        $commit = Invoke-PCVRRestMethod -Uri "https://api.github.com/repos/$Repo/commits/$branchEscaped" `
            -Headers @{ 'User-Agent'='PCVR-Mods-Hub'; 'Accept'='application/vnd.github+json' } -TimeoutSec 3 -ErrorAction Stop
        $dateText = [string]$commit.commit.committer.date
        if (-not $dateText) { $dateText = [string]$commit.commit.author.date }
        if ($dateText) {
            $version = ([DateTime]::Parse($dateText, $null, [Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()).ToString('yyyy.MM.dd.HHmmss')
            $script:ghVerCache[$cacheKey] = @{ tag=$version; checked=$now.ToString('o') }
            if ($script:ghVerCacheFile) { try {
                $obj = @{}
                foreach ($k in $script:ghVerCache.Keys) { $obj[$k] = $script:ghVerCache[$k] }
                ($obj | ConvertTo-Json) | Set-Content -LiteralPath $script:ghVerCacheFile -Encoding UTF8 -Force
            } catch {} }
            return $version
        }
    } catch {
        Write-Host "[GithubCommitCheck] ${Repo}@${Branch}: $($_.Exception.Message)"
        if ($_.Exception.Message -notmatch 'rate limit|403|forbidden') { $global:HubScanOnlineDown = $true }
    }
    if ($entry -and $entry.tag) { return [string]$entry.tag }
    return $null
}

# Select the repository that belongs to the installed payload. GTA V can
# switch from the primary fork to Francisco's clean backup after an antivirus
# false positive. The choice is written beside the game as well as in the Hub,
# so a replacement Hub still compares the installed tag against the right
# release feed.
function global:Get-SelectedGithubRepo {
    param($Game, [string]$GameDir)
    if (-not $Game -or -not $Game.GithubRepo) { return $null }
    if (-not $Game.GithubRepoAlt) { return [string]$Game.GithubRepo }

    $source = $null
    if ($GameDir) {
        try {
            $gameSource = [IO.Path]::Combine($GameDir, ".pcvrhub_source")
            if (Test-Path -LiteralPath $gameSource -PathType Leaf) {
                $source = (Get-Content -LiteralPath $gameSource -Raw -ErrorAction Stop).Trim()
            }
        } catch {}
    }
    if (-not $source) {
        try {
            $pathFile = Get-InstalledPathFile -Game $Game
            if ($pathFile) {
                $hubSource = Join-Path (Split-Path -Parent $pathFile) ".vrv_source"
                if (Test-Path -LiteralPath $hubSource -PathType Leaf) {
                    $source = (Get-Content -LiteralPath $hubSource -Raw -ErrorAction Stop).Trim()
                }
            }
        } catch {}
    }
    if ($source -eq "francisco") { return [string]$Game.GithubRepoAlt }
    return [string]$Game.GithubRepo
}

function global:Get-GrandWebVersionFromText {
    param([string]$Text)
    if([string]::IsNullOrWhiteSpace($Text)){return ''}
    if($Text -match '(?i)Test Build\s+v?(\d+\.\d+\.\d+)'){return ('v'+$matches[1])}
    if($Text -match '(?im)\bGRAND[^\r\n<]{0,60}\bv?(\d+\.\d+\.\d+)'){return ('v'+$matches[1])}
    return ''
}
function global:Test-GrandInstalledVersionProof {
    param([string]$GameDir,[string]$Version)
    if(-not $GameDir -or -not $Version){return $false}
    $marker=Join-Path $GameDir '.pcvrhub_grand_version_evidence'
    $dll=Join-Path $GameDir 'XINPUT1_3.dll'
    if(-not(Test-Path -LiteralPath $marker -PathType Leaf) -or -not(Test-Path -LiteralPath $dll -PathType Leaf)){return $false}
    try{
        $lines=@([IO.File]::ReadAllLines($marker))
        if($lines.Count -ne 2 -or $lines[0].Trim() -ne $Version.Trim() -or $lines[1] -notmatch '^[A-Fa-f0-9]{64}$'){return $false}
        return ((Get-FileHash -LiteralPath $dll -Algorithm SHA256 -ErrorAction Stop).Hash -ieq $lines[1])
    }catch{return $false}
}
function global:Get-PublisherWebVersionFromText {
    param([string]$Text,[string]$VersionPattern,$VersionAliases)
    if(-not $Text -or -not $VersionPattern){return $null}
    $match=[regex]::Match($Text,$VersionPattern)
    if(-not $match.Success){return $null}
    $version=if($match.Groups['version'].Success){$match.Groups['version'].Value}else{$match.Groups[1].Value}
    if($VersionAliases){
        $mapped=if($VersionAliases -is [Collections.IDictionary]){$VersionAliases[$version]}else{$VersionAliases.PSObject.Properties[$version].Value}
        if(-not $mapped){return $null};$version=[string]$mapped
    }
    if(Test-IsTrackableInstalledVersion $version){return $version}
    return $null
}
function global:Get-WebVersionCached {
    # Return the published version string from a mod's own website (the GRAND
    # mod for Alien Isolation), cached on disk with the same 6h TTL as the
    # GitHub release checks so back-to-back scans skip the live page fetch -
    # the slowest single online check. No timeout is lowered, so a slow-but-
    # valid page is never cut short. On a fetch failure the last-known cached
    # value is returned, so the update state stays stable.
    param([string]$Url, [string]$Title, [string]$VersionPattern='', $VersionAliases=$null, [string]$TrilexGame='')
    if (-not $Url) { return $null }
    $ttlHours = 6
    if ($null -eq $script:webVerCache) {
        $script:webVerCache = @{}
        $cacheRoot = Get-HubVersionCacheRoot
        $script:webVerCacheFile = if ($cacheRoot) { Join-Path $cacheRoot ".web_version_cache" } else { $null }
        if ($script:webVerCacheFile -and (Test-Path -LiteralPath $script:webVerCacheFile -PathType Leaf)) {
            try {
                $raw = Get-Content -LiteralPath $script:webVerCacheFile -Raw | ConvertFrom-Json
                foreach ($wp in $raw.PSObject.Properties) {
                    $script:webVerCache[$wp.Name] = @{ ver = [string]$wp.Value.ver; checked = [string]$wp.Value.checked }
                }
            } catch {}
        }
    }
    $cacheKey = if ($TrilexGame) { "$Url#$TrilexGame" } else { $Url }
    $entry = $script:webVerCache[$cacheKey]
    $now = [DateTime]::UtcNow
    if ($entry -and $entry.ver -and $entry.checked) {
        try {
            $age = ($now - [DateTime]::Parse($entry.checked, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)).TotalHours
            if ($age -lt $ttlHours) { return [string]$entry.ver }
        } catch {}
    }
    # Respect the scan-wide circuit breaker (same rule as every online scan
    # check): if an earlier check this scan already failed, do NOT touch the
    # network again - return the last known version or null.
    if ($global:HubScanOnlineDown -or $global:HubVersionCacheOnly) {
        if ($entry -and $entry.ver) { return [string]$entry.ver }
        return $null
    }
    $wv = $null
    try {
        # The slow part of this check is the NETWORK (DNS + TLS + any http->https
        # ->www redirect hops + a slow server), NOT the page itself - parsing the
        # whole 72 KB page takes well under 1 ms. Invoke-WebRequest's -TimeoutSec
        # in Windows PowerShell 5.1 applies per-hop and does not bound DNS, so a
        # slow lookup or a multi-hop redirect could still stall the scan ~10s and
        # then succeed (hence "checked, no error" in the log).
        #
        # Fix: run the fetch on a background runspace and impose ONE hard total
        # time budget (6s) over the entire operation - DNS, connect, redirects
        # and body read included. If the budget is exceeded we abandon the call,
        # trip the scan-wide breaker, and fall back to the cached version. The
        # full page IS read (cheap), so no version string can ever be cut off.
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
        $fetchBudgetMs = 2000
        $ps = [PowerShell]::Create()
        [void]$ps.AddScript({
            param($u)
            try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
            $r = [System.Net.HttpWebRequest]::Create($u)
            $r.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
            $r.AllowAutoRedirect = $true
            $r.Timeout          = 2000
            $r.ReadWriteTimeout = 2000
            $resp = $r.GetResponse()
            try {
                $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
                try { return $sr.ReadToEnd() } finally { $sr.Close() }
            } finally { $resp.Close() }
        }).AddArgument($Url)
        $async = $ps.BeginInvoke()
        $wHtml = ""
        if ($async.AsyncWaitHandle.WaitOne($fetchBudgetMs)) {
            try {
                $res = $ps.EndInvoke($async)
                if ($res -and $res.Count -gt 0) { $wHtml = [string]$res[0] }
            } catch { throw }
            finally { $ps.Dispose() }
        } else {
            # Over budget: abandon the runspace (it dies with the process /
            # scan) and treat it exactly like a timeout.
            try { $ps.Stop() } catch {}
            try { $ps.Dispose() } catch {}
            throw [System.TimeoutException]::new("web version fetch exceeded ${fetchBudgetMs}ms budget")
        }
        if ($TrilexGame) {
            $wv=Get-PCVRTrilexSignedVersion -Envelope $wHtml -Game $TrilexGame
        } elseif ($VersionPattern) {
            $wv=Get-PublisherWebVersionFromText -Text $wHtml -VersionPattern $VersionPattern -VersionAliases $VersionAliases
        } else {
            $wv=Get-GrandWebVersionFromText -Text $wHtml
        }
        if ($wv) { Write-Host "[AICheck] $Title : web version = $wv" }
        else     { Write-Host ("[AICheck] $Title : page fetched ({0} chars) but no version matched" -f $wHtml.Length) }
    } catch {
        Write-Host "[AICheck] $Title : page fetch failed - $($_.Exception.Message)"
        # Timeout / unreachable -> trip the scan-wide breaker so the rest of
        # this scan skips the network instead of each eating another timeout.
        $global:HubScanOnlineDown = $true
        if ($entry -and $entry.ver) { return [string]$entry.ver }
        return $null
    }
    if ($wv) {
        $script:webVerCache[$cacheKey] = @{ ver = $wv; checked = $now.ToString("o") }
        if ($script:webVerCacheFile) { try {
            $obj = @{}
            foreach ($wk in $script:webVerCache.Keys) { $obj[$wk] = $script:webVerCache[$wk] }
            ($obj | ConvertTo-Json) | Set-Content -LiteralPath $script:webVerCacheFile -Encoding UTF8 -Force
        } catch {} }
        return $wv
    }
    if ($entry -and $entry.ver) { return [string]$entry.ver }
    return $null
}

function global:Invoke-RotatingOnlinePrewarm {
    # Warm the version cache for online-checkable games in a ROTATING order.
    # Problem this solves: a single persistently-slow repo sitting at a fixed
    # scan position would trip the circuit breaker FIRST every scan and starve
    # every other repo forever (they would never get cached). By rotating which
    # repo is attempted first each scan - offset kept in a tiny file so it
    # advances across sessions - every healthy repo eventually lands an early
    # slot, before the breaker trips, and caches itself for 6h (dropping off the
    # network). The breaker still caps the whole prewarm at ONE timeout, so this
    # never reintroduces the multi-minute freeze.
    try {
        $items = @()
        foreach ($g in $global:allGameData) {
            if ($g.GithubCommitRepo) {
                $items += , @{ K = 'ghcommit'; A = [string]$g.GithubCommitRepo; B = $(if ($g.GithubCommitBranch) { [string]$g.GithubCommitBranch } else { 'main' }) }
            }
            if ($g.GithubRepo) {
                $repo = Get-SelectedGithubRepo -Game $g
                $channelPrefs = if ($g.GithubChannelChoice) { @($false,$true) } else { @([bool]$g.GithubPrerelease) }
                foreach ($pref in $channelPrefs) { $items += , @{ K = "gh"; A = $repo; P = $pref; R = @($(if($g.GithubStoreAssetSuffix){@(Get-GameGithubReleaseAssetPatterns -Game $g)}else{@($g.GithubReleaseAssetPatterns)})); O=[string]$g.GithubTagOrder; V=[string]$g.GithubAssetVersionPattern; W=[bool]$g.GithubRepoRollingUpdate } }
                # A replacement Hub has not reconstructed GTA's Hub-local
                # source marker yet. Warm the alternate repo too; the later
                # game-side marker then selects the correct already-cached tag.
                if ($g.GithubRepoAlt -and $g.GithubRepoAlt -ne $repo) {
                    foreach ($pref in $channelPrefs) { $items += , @{ K = "gh"; A = $g.GithubRepoAlt; P = $pref; R = @($(if($g.GithubStoreAssetSuffix){@(Get-GameGithubReleaseAssetPatterns -Game $g)}else{@($g.GithubReleaseAssetPatterns)})); O=[string]$g.GithubTagOrder; V=[string]$g.GithubAssetVersionPattern; W=[bool]$g.GithubRepoRollingUpdate } }
                } elseif ($g.GithubRepoAlt -and $g.GithubRepo -ne $repo) {
                    foreach ($pref in $channelPrefs) { $items += , @{ K = "gh"; A = $g.GithubRepo; P = $pref; R = @($(if($g.GithubStoreAssetSuffix){@(Get-GameGithubReleaseAssetPatterns -Game $g)}else{@($g.GithubReleaseAssetPatterns)})); O=[string]$g.GithubTagOrder; V=[string]$g.GithubAssetVersionPattern; W=[bool]$g.GithubRepoRollingUpdate } }
                }
            }
            # A second repo is independent. It may be the only maintained
            # upstream on a two-mod entry (Halo MCC's original repo vanished),
            # and it may use a different stable/prerelease policy.
            if ($g.GithubRepoB) {
                $bPref = if ($null -ne $g.GithubRepoBPrerelease) { [bool]$g.GithubRepoBPrerelease } else { [bool]$g.GithubPrerelease }
                $items += , @{ K = "gh"; A = $g.GithubRepoB; P = $bPref; R = @($g.GithubRepoBReleaseAssetPatterns); W=[bool]$g.GithubRepoBRollingUpdate; O=[string]$g.GithubRepoBTagOrder }
            }
            if ($g.WebVersionUrl -and ((-not $g.GithubRepo -and -not $g.GithubRepoB) -or $g.GithubRepo -eq 'GrayHorizon-mod/Forza-Horizon-VR')) {
                $items += , @{ K = "web"; A = $g.WebVersionUrl; T = $g.Title; P = $g.WebVersionPattern; Aliases = $g.WebVersionAliases }
            }
        }
        if ($items.Count -eq 0) { return }
        $off = 0
        if ($items.Count -gt 1) {
            # Runtime rotation state is cache, never program content. Keeping
            # it below Core made an ordinary Scan Installed Games click dirty
            # the portable Hub and risked shipping one user's scan position in
            # a release ZIP. All volatile update state belongs in LocalAppData.
            $cacheRoot = Get-HubVersionCacheRoot
            $rotFile = if ($cacheRoot) { Join-Path $cacheRoot ".gh_check_rotation" } else { $null }
            if ($rotFile -and (Test-Path -LiteralPath $rotFile -PathType Leaf)) {
                try { $off = [int]((Get-Content -LiteralPath $rotFile -Raw -EA SilentlyContinue).Trim()) } catch { $off = 0 }
            }
            $off = (($off % $items.Count) + $items.Count) % $items.Count
            if ($rotFile) { try { Set-Content -LiteralPath $rotFile -Value ([string](($off + 1) % $items.Count)) -Encoding ASCII -Force } catch {} }
        }
        for ($i = 0; $i -lt $items.Count; $i++) {
            # Soft time budget: once the scan's deadline passes, stop probing
            # the network. Tripping the breaker makes the Cached getters below
            # return cache-only, so the remaining repos are skipped instantly
            # rather than each risking another slow fetch. They keep their
            # last-known cache and refresh on a future scan (rotation gives each
            # an early slot over time). This is what bounds the scan's online
            # phase to ~the budget instead of "sum of every slow host".
            if ($global:PrewarmDeadline -and ([DateTime]::UtcNow -gt $global:PrewarmDeadline)) {
                $global:HubScanOnlineDown = $true
                break
            }
            $it = $items[($off + $i) % $items.Count]
            try {
                if ($it.K -eq "gh") { [void](Get-GithubLatestTagCached -Repo $it.A -IncludePrerelease:([bool]$it.P) -RequiredAssetPatterns @($it.R) -TagOrder ([string]$it.O) -AssetVersionPattern ([string]$it.V) -AssetTimestampVersion:([bool]$it.W)) }
                elseif ($it.K -eq 'ghcommit') { [void](Get-GithubLatestCommitCached -Repo $it.A -Branch $it.B) }
                else { [void](Get-WebVersionCached -Url $it.A -Title $it.T -VersionPattern ([string]$it.P) -VersionAliases $it.Aliases) }
            } catch {}
        }
    } catch {}
}

# --- Scan UI lock -------------------------------------------------
# While a scan yields the UI thread back to WPF (see the pump inside
# Invoke-CheckInstalledScan), the window is alive - it paints and
# animates, but nothing in a half-finished scan should be interactive.
# Lock-ScanUi therefore switches BOTH input paths off:
#   - mouse:    IsHitTestVisible = $false on the window content
#   - keyboard: Preview blockers on the window (tunneling, so they run
#               before the search box or any shortcut sees the key -
#               typing in the search box mid-scan would tear down the
#               detail view and re-filter the very cards being scanned)
# Unlock-ScanUi reverses both and is safe to call when nothing is
# locked - it is used at scan end, in the self-heal path and in the
# click handler's crash catch.
#
# INTERACTIVE SCAN (default since 2026-10-31): the full lock made the Hub
# unusable for the whole scan (~10 s with 180 installed games). The scan
# now leaves mouse and keyboard on. Its pump hands the UI thread back every
# 100 ms, and every 33 ms while the user is actively scrolling, typing or
# clicking (Lock-ScanUi records that input). Safe because nothing a user
# can do mid-scan rebuilds the cards the scan walks: installers and
# uninstallers are separate processes whose refresh already waits for the
# scan, sorting/filtering only reorders/hides the same card objects, lazy
# cards build visible ones from gameStateMap, and the one rebuild
# (Switch-HubStyle) is deferred until the scan ends.
# PCVR_HUB_SCAN_LOCK=1 before starting the Hub restores the full lock.
function global:Test-HubScanInputLock {
    return ([string]$env:PCVR_HUB_SCAN_LOCK -eq '1')
}
function global:Get-GameGithubReleaseAssetPatterns {
    param($Game,[string]$GameDir='')
    if(-not $Game.GithubStoreAssetSuffix){return @($Game.GithubReleaseAssetPatterns)}
    if(-not $GameDir){$GameDir=[string]$Game.DetectedPath}
    if(-not $GameDir -and (Get-Command Read-InstalledPath -ErrorAction SilentlyContinue)){
        # Prewarming runs before this scan has produced GameDir. Reuse the
        # durable path so its cache key matches the later store-specific check.
        try{$GameDir=[string](Read-InstalledPath -Game $Game)}catch{}
    }
    $route=''
    if($GameDir){
        $marker=Join-Path $GameDir '.pcvrhub_deadspace2_store.txt'
        if(Test-Path -LiteralPath $marker -PathType Leaf){try{$route=[IO.File]::ReadAllText($marker).Trim()}catch{}}
        if(-not $route -and $GameDir -match '(?i)[\\/]steamapps[\\/]common[\\/]'){$route='Steam'}
        if(-not $route -and $GameDir -match '(?i)[\\/](EA Games|Origin Games)[\\/]'){$route='EA'}
    }
    if($route -in @('Steam','EA')){return @('(?i)^DS2PCVR-.+-'+$route.ToLowerInvariant()+'\.zip$')}
    return @($Game.GithubReleaseAssetPatterns)
}

function global:Lock-ScanUi {
    if (-not (Test-HubScanInputLock)) {
        $global:HubScanInteractive = $true
        $global:HubScanLastInputTicks = 0L
        try {
            if (-not $script:scanInputWatchOn -and $global:window) {
                if (-not $script:scanInputSeen) {
                    $script:scanInputSeen = @{
                        Move  = [System.Windows.Input.MouseEventHandler]{ param($s, $e) $global:HubScanLastInputTicks = [DateTime]::UtcNow.Ticks }
                        Down  = [System.Windows.Input.MouseButtonEventHandler]{ param($s, $e) $global:HubScanLastInputTicks = [DateTime]::UtcNow.Ticks }
                        Wheel = [System.Windows.Input.MouseWheelEventHandler]{ param($s, $e) $global:HubScanLastInputTicks = [DateTime]::UtcNow.Ticks }
                        Key   = [System.Windows.Input.KeyEventHandler]{ param($s, $e) $global:HubScanLastInputTicks = [DateTime]::UtcNow.Ticks }
                    }
                }
                $global:window.AddHandler([System.Windows.UIElement]::PreviewMouseMoveEvent,  $script:scanInputSeen.Move,  $true)
                $global:window.AddHandler([System.Windows.UIElement]::PreviewMouseDownEvent,  $script:scanInputSeen.Down,  $true)
                $global:window.AddHandler([System.Windows.UIElement]::PreviewMouseWheelEvent, $script:scanInputSeen.Wheel, $true)
                $global:window.AddHandler([System.Windows.UIElement]::PreviewKeyDownEvent,    $script:scanInputSeen.Key,   $true)
                $script:scanInputWatchOn = $true
            }
        } catch { $script:scanInputWatchOn = $false }
        return
    }
    $global:HubScanInteractive = $false
    try {
        $script:scanInputLock = $global:window.Content
        if ($script:scanInputLock) { $script:scanInputLock.IsHitTestVisible = $false }
    } catch { $script:scanInputLock = $null }
    try {
        if (-not $script:scanKeysLocked) {
            if (-not $script:scanKeyBlock) {
                $script:scanKeyBlock  = [System.Windows.Input.KeyEventHandler]{ param($s, $e) $e.Handled = $true }
                $script:scanTextBlock = [System.Windows.Input.TextCompositionEventHandler]{ param($s, $e) $e.Handled = $true }
            }
            $global:window.AddHandler([System.Windows.UIElement]::PreviewKeyDownEvent,   $script:scanKeyBlock,  $true)
            $global:window.AddHandler([System.Windows.UIElement]::PreviewTextInputEvent, $script:scanTextBlock, $true)
            $script:scanKeysLocked = $true
        }
    } catch { $script:scanKeysLocked = $false }
}

function global:Unlock-ScanUi {
    if ($script:scanInputWatchOn -and $script:scanInputSeen) {
        try { $global:window.RemoveHandler([System.Windows.UIElement]::PreviewMouseMoveEvent,  $script:scanInputSeen.Move)  } catch {}
        try { $global:window.RemoveHandler([System.Windows.UIElement]::PreviewMouseDownEvent,  $script:scanInputSeen.Down)  } catch {}
        try { $global:window.RemoveHandler([System.Windows.UIElement]::PreviewMouseWheelEvent, $script:scanInputSeen.Wheel) } catch {}
        try { $global:window.RemoveHandler([System.Windows.UIElement]::PreviewKeyDownEvent,    $script:scanInputSeen.Key)   } catch {}
    }
    $script:scanInputWatchOn = $false
    $global:HubScanInteractive = $false
    $global:HubScanLastInputTicks = 0L
    # A tile-style switch requested mid-scan runs once the scan has fully
    # finished (queued behind the scan's own epilogue).
    if ($global:HubStyleSwitchAfterScan) {
        $global:HubStyleSwitchAfterScan = $false
        try {
            [void]$global:window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{
                try { if (Get-Command Switch-HubStyle -ErrorAction SilentlyContinue) { Switch-HubStyle } } catch {}
            })
        } catch {}
    }
    try { if ($script:scanInputLock) { $script:scanInputLock.IsHitTestVisible = $true } } catch {}
    $script:scanInputLock = $null
    if ($script:scanKeysLocked) {
        try { $global:window.RemoveHandler([System.Windows.UIElement]::PreviewKeyDownEvent,   $script:scanKeyBlock)  } catch {}
        try { $global:window.RemoveHandler([System.Windows.UIElement]::PreviewTextInputEvent, $script:scanTextBlock) } catch {}
        $script:scanKeysLocked = $false
    }
}

# Reuse the full scan's immutable first-paint resources for a one-game clear.
function global:Reset-HubCardInstallHover {
    param($Card)
    if (-not $Card) { return }
    foreach($key in @('readyOrigText','updLabelRest','vrupdMorphed')) { if($Card.Resources.Contains($key)){[void]$Card.Resources.Remove($key)} }
    foreach($key in @('reloadPill','dualSplit')){$element=$Card.Resources.Item($key);if($element){$element.Visibility=[Windows.Visibility]::Collapsed}}
    $text=$Card.Resources.Item('btnText');if($text){$text.Visibility=[Windows.Visibility]::Visible}
    $button=$Card.Resources.Item('btnBorder')
    if($button){foreach($key in @('preHoverBrush','preHoverBdBrush','preHoverBdThick','preHoverTxtFg','preHoverTxtText','preHoverPillBg','preHoverPillBd','preHoverPillGlyphFg','preHoverPillGlyphTx')){if($button.Resources.Contains($key)){[void]$button.Resources.Remove($key)}}}
    $glyph=$Card.Resources.Item('reloadGlyph');if($glyph){$glyph.Text=[char]0x21BB;$glyph.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString('#88dd99');$glyph.Opacity=0.75}

}
function global:Reset-HubCardInstallState {
    param($Card,$Game)
    if (-not $Card -or -not $Game) { return }
    Reset-HubCardInstallHover -Card $Card
    $Card.Tag='';$Card.Effect=$null
    if ($Card.Resources.Contains('cardLazy')) { return }
    foreach($pair in @(@('originalBgBrush','baseBgBrush','Background'),@('originalBdBrush','baseBdBrush','BorderBrush'),@('originalAccent','baseAccent',''))) {
        $value=$Card.Resources.Item($pair[0]);if(-not $value){continue}
        if($pair[2]){$Card.($pair[2])=$value}
        if($Card.Resources.Contains($pair[1])){[void]$Card.Resources.Remove($pair[1])};$Card.Resources.Add($pair[1],$value)
    }
    $cap=$Card.Resources.Item('accentCap');$accent=$Card.Resources.Item('originalAccent')
    if($cap -and $accent){$cap.Background=[Windows.Media.BrushConverter]::new().ConvertFromString([string]$accent);$cap.Visibility=[Windows.Visibility]::Visible}
    $text=$Card.Resources.Item('btnText');$button=$Card.Resources.Item('btnBorder')
    if($text){$text.Text=if($Game.Bat){'Install'}elseif($Game.Type -eq 'steam'){'Open in Steam'}elseif($Game.Type -eq 'itch'){'Open on itch.io'}else{'Get Installer'};$text.Foreground=[Windows.Media.Brushes]::White}
    Sync-FrostedCardState -Card $Card -BtnTxt $text -BtnBrd $button
}
