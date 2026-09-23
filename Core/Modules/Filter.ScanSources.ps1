# Build a card->game lookup - wrapped in function so Scale can rebuild it
function global:Rebuild-Lookups {
    $global:allCards    = @()
    $global:allGameData = @()
    foreach ($child in $ownList.Children)   { $global:allCards += $child }
    foreach ($child in $ownListGP.Children) { $global:allCards += $child }
    foreach ($child in $extList.Children)   { $global:allCards += $child }
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
    if ($global:gameStateMap -and $global:gameStateMap.Count -gt 0) {
        foreach ($card in $global:cardGameMap.Keys) {
            $g = $global:cardGameMap[$card]
            if (-not $g.Title) { continue }
            $state = $global:gameStateMap[$g.Title]
            if (-not $state) { continue }
            $card.Tag = $state.Tag
            $accH = if ($state.Accent) { $state.Accent } else { $card.Resources.Item("baseAccent") }
            if (-not $accH) { $accH = "#666677" }
            $btnTxt = $card.Resources.Item("btnText")
            $btnBrd = $card.Resources.Item("btnBorder")
            $card.Effect = $null

            switch ($state.State) {
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
                        $btnTxt.Text = "VR Ready"
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
    return @(@($Game.SteamId) + @($Game.SteamIdAlt) |
        ForEach-Object { ('' + $_).Trim() } |
        Where-Object { $_ -match '^\d+$' } |
        Select-Object -Unique)
}

function global:Test-BaseGameInstallProof {
    param($Game, [string]$Root)

    $groups = @($Game.BaseGameProofFiles | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
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
    $counted = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($group in $groups) {
        $groupMatched = $false
        foreach ($relative in (([string]$group) -split '\|')) {
            $relative = $relative.Trim()
            if (-not $relative) { continue }
            try {
                $candidate = Join-HubPathLexical $Root $relative
                if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
                $groupMatched = $true
                $full = [IO.Path]::GetFullPath($candidate)
                if ($counted.Add($full)) { $matchedBytes += [int64](Get-Item -LiteralPath $candidate -ErrorAction Stop).Length }
                break
            } catch {}
        }
        if (-not $groupMatched) { return $false }
    }

    [int64]$minimum = 0
    try { if ($Game.BaseGameProofMinBytes) { $minimum = [int64]$Game.BaseGameProofMinBytes } } catch {}
    return ($minimum -le 0 -or $matchedBytes -ge $minimum)
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
        if (-not $marker -and $rel) { $marker = Test-RelativePathMarker -Root $Root -Values $rel }
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

function global:Get-TwoModsPresence {
    param($Game, [string]$FallbackRoot)
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
    if ($ipf -and (Test-Path -LiteralPath $ipf)) {
        try { & $addRoot (Read-InstalledPath -Game $Game) } catch {}
    }
    & $addRoot $FallbackRoot
    if ($Game.VrInstallRoot) {
        try {
            $stageRoot = if (Get-Command Resolve-VrInstallRoot -ErrorAction SilentlyContinue) { Resolve-VrInstallRoot -Root ([string]$Game.VrInstallRoot) } else { [Environment]::ExpandEnvironmentVariables([string]$Game.VrInstallRoot) }
            & $addRoot $stageRoot
        } catch {}
    }
    if ($Game.DualMode) {
        try { foreach ($candidate in (Get-DepotCandidatePaths -Game $Game)) { & $addRoot $candidate } } catch {}
    }
    foreach ($fallback in @($Game.FallbackPaths)) {
        # Keep native drive paths such as C:\Games; skip catalog resolver
        # prefixes such as STEAM:, XBOX: and GOG:.
        if ($fallback -and $fallback -notmatch '^[A-Za-z_]{2,}:') { & $addRoot ([string]$fallback) }
    }
    if ($roots.Count -eq 0) { return $res }
    $res.Root = [string]$roots[0]

    # Launchers are launch paths, not installation evidence. A stale batch
    # file must never resurrect a deleted mod. When a slot declares a real
    # probe marker, that marker decides presence and the launcher only
    # supplies the directory for the Play button.
    foreach ($root in $roots) {
        # A real mod marker inside a leftover folder does not prove that the
        # base game it needs still exists. The command guard keeps this helper
        # independently testable; the ordered Filter facade always loads the
        # proof helper immediately before this function in production.
        $baseProof = Get-Command Test-BaseGameInstallProof -ErrorAction SilentlyContinue
        if ($baseProof -and -not (Test-BaseGameInstallProof -Game $Game -Root ([string]$root))) { continue }
        $rootKey = & $normaliseRoot ([string]$root)
        $scope = if ($rootScopes.ContainsKey($rootKey)) { [string]$rootScopes[$rootKey] } else { $null }
        foreach ($definition in $definitions) {
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
            $relPresent = Test-RelativePathMarker -Root $root -Values $definition.ProbeFile
            if (-not $scope -and $definition.ProbeScope -and $relPresent) { $scope = [string]$definition.ProbeScope }
            if ($definition.ProbeScope -and $scope -and $scope -ine [string]$definition.ProbeScope) { $relPresent = $false }
            $probeDeclared = ($absDeclared -or [bool]$definition.ProbeFile)
            $presentHere = if ($probeDeclared) { ($absPresent -or $relPresent) } else { [bool]$hit }
            # Optional hard prerequisites are AND conditions, unlike the
            # alternative probe arrays above.
            if ($presentHere -and $definition.RequiredFile) {
                $presentHere = Test-RelativePathMarker -Root $root -Values $definition.RequiredFile
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
    if ($Game.RouteModMatrix -and $Presence.RouteUpdateTargets) {
        foreach ($target in @($Presence.RouteUpdateTargets)) {
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

# DualMode presence probe - are BOTH the pinned-depot build and a current
# Steam-library build modded? Shared for the same reason as the TwoMods
# probe above: the full scan and the post-install refresh must agree, or
# the split button disappears until the Hub is restarted.
# $Libs is optional - the scan already has its library list and passes it
# in; the refresh has none and lets the function look them up itself.
function global:Get-DualModePresence {
    param($Game, $Libs)
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
    $hasRouteRoot = $Game -and ($Game.DepotPath -or $Game.CurrentStandalonePaths -or $Game.LegacyDepotPath)
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
        param([string]$Root, [string[]]$Markers, [string[]]$RequiredFiles, [string[]]$RouteBaseProofFiles)
        if (-not $Root -or -not (Test-Path -LiteralPath $Root -PathType Container)) { return $false }
        # A depot/current marker can outlive the base game just like an ordinary
        # ModFile. Route presence therefore uses the same base-game contract as
        # the main scan instead of allowing a dual-mode probe to resurrect a
        # stale folder after the general check rejected it.
        if (@($RouteBaseProofFiles | Where-Object { $_ }).Count -gt 0) {
            foreach ($rawGroup in @($RouteBaseProofFiles | Where-Object { $_ })) {
                $matched = $false
                foreach ($relative in (([string]$rawGroup) -split '\|')) {
                    $relative = $relative.Trim()
                    if ($relative -and (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) { $matched=$true; break }
                }
                if (-not $matched) { return $false }
            }
        } else {
            $baseProof = Get-Command Test-BaseGameInstallProof -ErrorAction SilentlyContinue
            if ($baseProof -and -not (Test-BaseGameInstallProof -Game $Game -Root $Root)) { return $false }
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
        return $true
    }

    $depotDir = $null
    if ($Game.DepotPath) {
        foreach ($cand in (Get-DepotCandidatePaths -Game $Game)) {
            if (& $rootHasVr $cand $depotRelList $depotRequiredList @($Game.DepotBaseGameProofFiles)) { $depotDir = $cand }
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
            try { Write-PersistentGameStateValue -Game $Game -Name 'installed_path_legacy_depot' -Value $cand } catch {}
            break
        }
    }

    # Standalone successors can coexist with an older standalone route. They
    # do not live in a Steam library, so probe their catalog/remembered roots
    # explicitly and keep their state separate from the legacy executable.
    if ($Game.CurrentStandalonePaths -and (Get-Command Get-CurrentStandaloneCandidatePaths -ErrorAction SilentlyContinue)) {
        foreach ($cand in (Get-CurrentStandaloneCandidatePaths -Game $Game)) {
            if (-not $cand -or -not (& $rootHasVr $cand $currentRelList $currentRequiredList @($Game.CurrentBaseGameProofFiles))) { continue }
            if ($Game.CurrentLaunchExe -and
                -not (Test-Path -LiteralPath (Join-Path $cand $Game.CurrentLaunchExe) -PathType Leaf)) { continue }
            $res.CurrentPresent = $true
            $res.CurrentDir = $cand
            try { Write-PersistentGameStateValue -Game $Game -Name 'installed_path_current' -Value $cand } catch {}
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
        $c = Join-Path $lib "steamapps\common\$($Game.SteamFolder)"
        if (-not (Test-Path $c)) { continue }
        $currentHit = & $rootHasVr $c $currentRelList $currentRequiredList @($Game.CurrentBaseGameProofFiles)
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

    if (-not $global:HubThunderstoreOnlineDown) {
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
    param($Releases, [bool]$IncludePrerelease, [string[]]$RequiredAssetPatterns)
    $patterns = @($RequiredAssetPatterns | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    if ($patterns.Count -eq 0) { return $null }
    foreach ($candidate in @($Releases | Sort-Object -Property published_at -Descending)) {
        $candidateTag = ([string]$candidate.tag_name).Trim()
        if ($candidate.draft -or (-not $IncludePrerelease -and $candidate.prerelease) -or
            -not $candidateTag -or $candidateTag -match '(?i)source|hub-patch|sdk|symbols|broken|diagnostic') { continue }
        foreach ($pattern in $patterns) {
            $assetMatches = @($candidate.assets | Where-Object { ([string]$_.name) -match $pattern -and $_.browser_download_url })
            if ($assetMatches.Count -eq 1) { return $candidateTag }
        }
    }
    return $null
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
    param([string]$Repo, [switch]$IncludePrerelease, [string[]]$RequiredAssetPatterns=@())
    if (-not $Repo) { return $null }
    $assetPatterns = @($RequiredAssetPatterns | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    $assetKey = ''
    if ($assetPatterns.Count -gt 0) {
        $assetBytes = [Text.Encoding]::UTF8.GetBytes(($assetPatterns -join '|'))
        $assetKey = '#asset=' + [Convert]::ToBase64String($assetBytes).TrimEnd('=').Replace('/','_').Replace('+','-')
    }
    $cacheKey = if ($IncludePrerelease) { "$Repo#pre" } else { $Repo }
    $cacheKey += $assetKey
    $ttlHours = 6
    if ($null -eq $script:ghVerCache) {
        $script:ghVerCache = @{}
        $cacheRoot = Get-HubVersionCacheRoot
        $script:ghVerCacheFile = if ($cacheRoot) { Join-Path $cacheRoot ".gh_version_cache" } else { $null }
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
            # !!! A FRESH CACHE VALUE CAN BE A SOURCE TAG TOO !!!
            # The filter further down only applies when the code really
            # looks online. A value left behind by Prefetch-Versions.ps1
            # (or by an older run) is returned RIGHT HERE - before that
            # filter. So it is checked here as well, rather than trusting
            # the write path: cache files from before this change already
            # contain such tags.
            if ($entry.tag -match '(?i)source|hub-patch|sdk|symbols|broken|diagnostic') {
                Write-Host "[GithubCheck] ${Repo}: cached tag '$($entry.tag)' is a source release - discarding it"
                $script:ghVerCache.Remove($cacheKey)
            } elseif ($age -lt $ttlHours) {
                return [string]$entry.tag
            }
        } catch {}
    }
    # Respect the scan-wide circuit breaker: if an earlier online check in
    # THIS scan already failed/timed out, do NOT touch the network again -
    # fall straight back to the last known tag (or null). This is what stops
    # an unreachable github.com (firewall/DNS) from stacking a per-repo
    # connection timeout into a multi-minute UI-thread freeze on a first run
    # with an empty cache: the first miss trips the breaker, the rest skip.
    if ($global:HubScanOnlineDown -or $global:HubVersionCacheOnly) {
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
    # Some publishers post release notes before they upload the installable
    # binary. An opt-in asset contract tracks the newest release that really
    # carries exactly one matching publisher asset. It has its own cache key,
    # so a previous generic tag can never create a phantom Update badge.
    if ($assetPatterns.Count -gt 0) {
        try {
            $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases?per_page=20" `
                -Headers @{ 'User-Agent'='PCVR-Mods-Hub'; 'Accept'='application/vnd.github+json' } `
                -TimeoutSec 3 -ErrorAction Stop 2>$null
            $tag = Select-GithubReleaseTagWithAsset -Releases $releases -IncludePrerelease ([bool]$IncludePrerelease) -RequiredAssetPatterns $assetPatterns
            if ($tag) {
                $script:ghVerCache[$cacheKey] = @{ tag = $tag; checked = $now.ToString('o') }
                if ($script:ghVerCacheFile) { try {
                    $obj = @{}
                    foreach ($k in $script:ghVerCache.Keys) { $obj[$k] = $script:ghVerCache[$k] }
                    ($obj | ConvertTo-Json) | Set-Content -LiteralPath $script:ghVerCacheFile -Encoding UTF8 -Force
                } catch {} }
                return $tag
            }
            Write-Host "[GithubCheck] ${Repo}: no release currently carries the required installable asset"
            if ($entry -and $entry.tag) { return [string]$entry.tag }
            return $null
        } catch {
            Write-Host "[GithubCheck] ${Repo}: asset-aware API check failed ($($_.Exception.Message)) - using cached tag if present"
            if ($_.Exception.Message -notmatch 'rate limit|403|forbidden') { $global:HubScanOnlineDown = $true }
            if ($entry -and $entry.tag) { return [string]$entry.tag }
            return $null
        }
    }
    $tag = $null
    if ($IncludePrerelease) {
        # Prerelease-aware path, WEBSITE FIRST: <repo>/releases.atom is served by
        # github.com, not by the API, so it has NO 60/hour limit - and it lists
        # prereleases, newest first. Each entry carries the tag in its <id> as
        #   tag:github.com,2008:Repository/<repoId>/<tag>
        # Verified against four repos in this Hub, including prerelease-only
        # ones (witcher3-vr -> v0.9.0-alpha.1, fear-vr -> v1.0.0-beta.7) and
        # normal ones (anvilengine2vr -> v2.0.0.Public, REFramework-nightly).
        # The API stays as the fallback below.
        # Deliberately NOT via Invoke-ScanWebGet: that helper trips the
        # scan-wide online-down breaker on any failure, and a missing atom
        # feed must not kill the rest of the scan - the API fallback right
        # below still has a chance.
        try {
            $atomResp = Invoke-WebRequest -Uri "https://github.com/$Repo/releases.atom" `
                            -UseBasicParsing -TimeoutSec 3 `
                            -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" } -EA Stop
            $atom = [string]$atomResp.Content
            if ($atom) {
                foreach ($m in [regex]::Matches($atom, 'Repository/[0-9]+/([^<]+)')) {
                    $t = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value).Trim()
                    if ($t -and $t -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic') {
                        $tag = $t
                        break
                    }
                }
            }
        } catch {
            Write-Host "[GithubCheck] $Repo (prerelease) : atom feed failed ($($_.Exception.Message)) - trying the API"
        }
        if (-not $tag) {
          try {
            $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases?per_page=10" -Headers @{ "User-Agent" = "PCVR-Mods-Hub" } -TimeoutSec 2 -EA Stop 2>$null
            foreach ($candidate in @($rel)) {
                $candidateTag = [string]$candidate.tag_name
                if (-not $candidate.draft -and $candidateTag -and $candidateTag -notmatch '(?i)source|hub-patch|sdk|symbols|broken|diagnostic') {
                    $tag = $candidateTag.Trim()
                    break
                }
            }
        } catch {
            Write-Host "[GithubCheck] $Repo (prerelease) : API check failed ($($_.Exception.Message)) - using cached tag if present"
            # A 403 (rate limit) means the host is reachable - do NOT trip the
            # scan-wide breaker. Only a genuine connection failure should.
            if ($_.Exception.Message -notmatch "rate limit|403|forbidden") { $global:HubScanOnlineDown = $true }
            if ($entry -and $entry.tag) { return [string]$entry.tag }
            return $null
          }
        }
        if ($tag) {
            $script:ghVerCache[$cacheKey] = @{ tag = $tag; checked = $now.ToString("o") }
            if ($script:ghVerCacheFile) { try {
                $obj = @{}
                foreach ($k in $script:ghVerCache.Keys) { $obj[$k] = $script:ghVerCache[$k] }
                ($obj | ConvertTo-Json) | Set-Content -LiteralPath $script:ghVerCacheFile -Encoding UTF8 -Force
            } catch {} }
            return $tag
        }
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
    # Use the github.com /releases/latest REDIRECT (web, not the API). It 302s
    # to /releases/tag/<tag>, so the tag is in the final URL - and the website
    # is NOT bound by the 60/hour unauthenticated API limit that the api.github
    # endpoint enforces. HEAD only, so no page body is downloaded. 2>$null keeps
    # a rare transient error out of the Hub transcript.
    $tag = $null
    try {
        $resp = Invoke-WebRequest -Uri "https://github.com/$Repo/releases/latest" -Method Head -UseBasicParsing -TimeoutSec 2 -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" } -EA Stop 2>$null
        $final = ""
        # Windows PowerShell 5.1 exposes the final URL as BaseResponse.ResponseUri;
        # PowerShell 7 has no such property and uses RequestMessage.RequestUri
        # instead. Reading only the 5.1 name made this fail silently on 7.
        try { $final = [string]$resp.BaseResponse.ResponseUri.AbsoluteUri } catch {}
        if (-not $final) { try { $final = [string]$resp.BaseResponse.RequestMessage.RequestUri.AbsoluteUri } catch {} }
        if (-not $final -and $resp.Headers.Location) { $final = [string]$resp.Headers.Location }
        if ($final -match '/releases/tag/([^/?#]+)') { $tag = [System.Uri]::UnescapeDataString($matches[1]).Trim() }
        # !!! A SOURCE RELEASE IS NOT AN UPDATE !!!
        # "broken" and "diagnostic" joined the list on 2026-08-20:
        # pancreations published a prerelease tagged "broken_build" that
        # sat ABOVE the real Alpha 0.3.3 in the list, carried a Halo 4
        # diagnostic only, and is called broken by its own author. A tag
        # like that must never raise an Update badge.
        # RaYRoD-TV uploaded a release "hub-patch-2" to all of his VR
        # ports that contains source only. On Banjo it is marked as a
        # prerelease and drops out here anyway - on StarFox64-VR it is
        # NOT, there it is the official "latest". The tile would have
        # reported a nonexistent update.
        # Such tags are discarded; the last known state then stays and
        # the tile reports nothing.
        if ($tag -and ($tag -match '(?i)source|hub-patch|sdk|symbols|broken|diagnostic')) {
            Write-Host "[GithubCheck] ${Repo}: tag '$tag' looks like a source release - skipping it"
            $tag = $null
        }
    } catch {
        Write-Host "[GithubCheck] ${Repo}: web check failed ($($_.Exception.Message)) - using cached tag if present"
        # A timeout / connection failure means github.com is unreachable or
        # too slow. Trip the scan-wide breaker so the remaining repos this
        # scan skip the network instead of each eating another timeout.
        $global:HubScanOnlineDown = $true
        if ($entry -and $entry.tag) { return [string]$entry.tag }
        return $null
    }
    if ($tag) {
        $script:ghVerCache[$cacheKey] = @{ tag = $tag; checked = $now.ToString("o") }
        if ($script:ghVerCacheFile) { try {
            $obj = @{}
            foreach ($k in $script:ghVerCache.Keys) { $obj[$k] = $script:ghVerCache[$k] }
            ($obj | ConvertTo-Json) | Set-Content -LiteralPath $script:ghVerCacheFile -Encoding UTF8 -Force
        } catch {} }
        return $tag
    }
    if ($entry -and $entry.tag) { return [string]$entry.tag }
    return $null
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
        $commit = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/commits/$branchEscaped" `
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

function global:Get-WebVersionCached {
    # Return the published version string from a mod's own website (the GRAND
    # mod for Alien Isolation), cached on disk with the same 6h TTL as the
    # GitHub release checks so back-to-back scans skip the live page fetch -
    # the slowest single online check. No timeout is lowered, so a slow-but-
    # valid page is never cut short. On a fetch failure the last-known cached
    # value is returned, so the update state stays stable.
    param([string]$Url, [string]$Title)
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
    $entry = $script:webVerCache[$Url]
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
        if     ($wHtml -match 'Test Build\s+v?([0-9][0-9A-Za-z.\-]+)') { $wv = "v" + $matches[1] }
        elseif ($wHtml -match 'GRAND[^0-9<]{0,30}v?([0-9]+(?:\.[0-9]+)+[0-9A-Za-z\-]*)') { $wv = "v" + $matches[1] }
        elseif ($wHtml -match '\bv([0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z\-]*)') { $wv = "v" + $matches[1] }
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
        $script:webVerCache[$Url] = @{ ver = $wv; checked = $now.ToString("o") }
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
                foreach ($pref in $channelPrefs) { $items += , @{ K = "gh"; A = $repo; P = $pref; R = @($g.GithubReleaseAssetPatterns) } }
                # A replacement Hub has not reconstructed GTA's Hub-local
                # source marker yet. Warm the alternate repo too; the later
                # game-side marker then selects the correct already-cached tag.
                if ($g.GithubRepoAlt -and $g.GithubRepoAlt -ne $repo) {
                    foreach ($pref in $channelPrefs) { $items += , @{ K = "gh"; A = $g.GithubRepoAlt; P = $pref; R = @($g.GithubReleaseAssetPatterns) } }
                } elseif ($g.GithubRepoAlt -and $g.GithubRepo -ne $repo) {
                    foreach ($pref in $channelPrefs) { $items += , @{ K = "gh"; A = $g.GithubRepo; P = $pref; R = @($g.GithubReleaseAssetPatterns) } }
                }
            }
            # A second repo is independent. It may be the only maintained
            # upstream on a two-mod entry (Halo MCC's original repo vanished),
            # and it may use a different stable/prerelease policy.
            if ($g.GithubRepoB) {
                $bPref = if ($null -ne $g.GithubRepoBPrerelease) { [bool]$g.GithubRepoBPrerelease } else { [bool]$g.GithubPrerelease }
                $items += , @{ K = "gh"; A = $g.GithubRepoB; P = $bPref; R = @($g.GithubRepoBReleaseAssetPatterns) }
            }
            if (-not $g.GithubRepo -and -not $g.GithubRepoB -and $g.WebVersionUrl) {
                $items += , @{ K = "web"; A = $g.WebVersionUrl; T = $g.Title }
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
                if ($it.K -eq "gh") { [void](Get-GithubLatestTagCached -Repo $it.A -IncludePrerelease:([bool]$it.P) -RequiredAssetPatterns @($it.R)) }
                elseif ($it.K -eq 'ghcommit') { [void](Get-GithubLatestCommitCached -Repo $it.A -Branch $it.B) }
                else { [void](Get-WebVersionCached -Url $it.A -Title $it.T) }
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
function global:Lock-ScanUi {
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
    try { if ($script:scanInputLock) { $script:scanInputLock.IsHitTestVisible = $true } } catch {}
    $script:scanInputLock = $null
    if ($script:scanKeysLocked) {
        try { $global:window.RemoveHandler([System.Windows.UIElement]::PreviewKeyDownEvent,   $script:scanKeyBlock)  } catch {}
        try { $global:window.RemoveHandler([System.Windows.UIElement]::PreviewTextInputEvent, $script:scanTextBlock) } catch {}
        $script:scanKeysLocked = $false
    }
}
