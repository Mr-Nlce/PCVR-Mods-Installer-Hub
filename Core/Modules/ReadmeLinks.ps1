# README links share the uninstall guide's scan gate and Explorer-only actions.
function global:ConvertTo-ReadmeWebAddress {
    param([string]$Address)
    if ($Address -match '[\x00-\x20]') { return $null }
    if ($Address -match '^www\.') { $Address = 'https://' + $Address }
    $uri = $null
    if ([Uri]::TryCreate($Address, [UriKind]::Absolute, [ref]$uri) -and $uri.Scheme -in @('http','https') -and $uri.Host) {
        return $uri.AbsoluteUri
    }
    return $null
}

function global:Get-ReadmeInlineSpans {
    param([string]$Text, [string]$Style = 'text', [switch]$Literal)
    # Balancing groups retain parentheses inside Markdown destinations.
    $markdown = '(?<markdown>(?<!!)\[(?<label>[^\]\r\n]+)\]\((?<destination>(?:[^()\r\n]|\((?<nest>)|\)(?<-nest>))*)(?(nest)(?!))\))'
    $web = '(?<autourl><(?<angle>(?:https?://|www\.)[^<>\r\n]+)>)|(?<url>(?<![\w@])(?:https?://|www\.)[^\s<>"''`]+)'
    $format = '(?<boldcode>\*\*`(?<bc>[^`\r\n]+)`\*\*)|(?<bold>\*\*(?<boldtext>(?:\*(?!\*)|[^*])+?)\*\*)|(?<code>`(?<codetext>[^`\r\n]+)`)|(?<pill>\[\[(?<key>[^\]\r\n]+)\]\])'
    $pattern = if ($Literal) { $web } else { "$format|$markdown|$web" }
    $position = 0
    foreach ($match in [regex]::Matches($Text, $pattern, 'IgnoreCase')) {
        if ($match.Index -gt $position) { @{ Kind=$Style; Text=$Text.Substring($position, $match.Index - $position) } }
        if ($match.Groups['boldcode'].Success) {
            Get-ReadmeInlineSpans -Text $match.Groups['bc'].Value -Style 'boldcode' -Literal
        } elseif ($match.Groups['bold'].Success) {
            Get-ReadmeInlineSpans -Text $match.Groups['boldtext'].Value -Style 'bold'
        } elseif ($match.Groups['code'].Success) {
            $codeStyle = if ($Style -eq 'bold') { 'boldcode' } else { 'code' }
            Get-ReadmeInlineSpans -Text $match.Groups['codetext'].Value -Style $codeStyle -Literal
        } elseif ($match.Groups['pill'].Success) {
            @{ Kind='pill'; Text=$match.Groups['key'].Value }
        } elseif ($match.Groups['markdown'].Success) {
            $label = $match.Groups['label'].Value
            $labelStyle = $Style
            if ($label -match '^\*\*`.*`\*\*$') { $labelStyle = 'boldcode' }
            elseif ($label -match '^`.*`$') { $labelStyle = 'code' }
            elseif ($label -match '^\*\*.*\*\*$') { $labelStyle = 'bold' }
            $label = $label -replace '\*\*|`', ''
            $address = $match.Groups['destination'].Value.Trim()
            # Optional Markdown title; angle brackets permit spaces in paths.
            $address = $address -replace '\s+["''][^"'']*["'']$', ''
            if ($address.StartsWith('<') -and $address.EndsWith('>')) { $address = $address.Substring(1, $address.Length - 2) }
            @{ Kind='destination'; Text=$label; Address=$address; Style=$labelStyle }
        } else {
            $raw = if ($match.Groups['autourl'].Success) { $match.Groups['angle'].Value } else { $match.Value }
            $address = $raw
            if (-not $match.Groups['autourl'].Success) {
                do {
                    $before = $address
                    $address = $address.TrimEnd('.', ',', ';', ':', '!')
                    foreach ($pair in @(@('(',')'), @('[',']'), @('{','}'))) {
                        while ($address.EndsWith($pair[1]) -and ([regex]::Matches($address, [regex]::Escape($pair[1])).Count -gt [regex]::Matches($address, [regex]::Escape($pair[0])).Count)) {
                            $address = $address.Substring(0, $address.Length - 1)
                        }
                    }
                } while ($before -cne $address)
            }
            $webAddress = ConvertTo-ReadmeWebAddress $address
            if ($webAddress) {
                @{ Kind='url'; Text=$address; Address=$webAddress; Style=$Style }
                if ($address.Length -lt $raw.Length) { @{ Kind=$Style; Text=$raw.Substring($address.Length) } }
            } else { @{ Kind=$Style; Text=$match.Value } }
        }
        $position = $match.Index + $match.Length
    }
    if ($position -lt $Text.Length) { @{ Kind=$Style; Text=$Text.Substring($position) } }
}

function global:Resolve-ReadmeAbbreviatedPath {
    param([string]$Raw, $Context)
    # An ellipsis omits installation-specific parents, not arbitrary path
    # components. Anchor examples to a known install root or game folder name.
    $path = $Raw.Replace('/', '\') -replace '^(?:\.{3}|\u2026)\\', ''
    $path = $path.TrimEnd('\')
    $hits = @{}
    foreach ($root in $Context.Roots) {
        $relative = $path
        $parts = $root.TrimEnd('\').Split('\')
        $anchored = $false
        for ($i = 1; $i -lt $parts.Count; $i++) {
            $anchor = $parts[$i..($parts.Count - 1)] -join '\'
            if ($path -eq $anchor -or $path.StartsWith($anchor + '\', [StringComparison]::OrdinalIgnoreCase)) {
                $relative = $path.Substring($anchor.Length).TrimStart('\')
                $anchored = $true
                break
            }
        }
        if (-not $anchored -and $root -eq $Context.GameDir) {
            $names = @($Context.Game.SteamFolder, (Split-Path $root -Leaf))
            foreach ($fallback in $Context.Game.FallbackPaths) {
                $names += Split-Path ($fallback -replace '^(?:STEAM|EPIC|GOG):', '') -Leaf
            }
            $example = $path -replace '^steamapps\\common\\', ''
            foreach ($name in $names) {
                if ($name -and ($example -eq $name -or $example.StartsWith($name + '\', [StringComparison]::OrdinalIgnoreCase))) {
                    $relative = $example.Substring($name.Length).TrimStart('\')
                    break
                }
            }
        }
        $hit = Resolve-StepFolder -Raw $(if ($relative) { $relative } else { '.' }) -GameDir $root
        if ($hit) { $hits[$hit.Path] = $hit }
    }
    if ($hits.Count -eq 1) { return @($hits.Values)[0] }
    return $null
}

function global:Resolve-ReadmePath {
    param([string]$Raw, $Session, [switch]$DocumentLink)
    if (-not $Session.Context -or -not $Raw) { return $null }
    $path = $Raw.Trim()
    if ($path -match '^file:') {
        $uri = $null
        if (-not [Uri]::TryCreate($path, [UriKind]::Absolute, [ref]$uri) -or -not $uri.IsFile -or $uri.IsUnc) { return $null }
        $path = $uri.LocalPath
    } elseif ($path -match '^\w+:' -and $path -notmatch '^[A-Za-z]:[\\/]') { return $null }
    # Decode Markdown URL escapes, without treating ordinary '%' variables as URLs.
    if ($DocumentLink) { $path = [Uri]::UnescapeDataString($path) }
    if ($path -match '^(?:\.{3}[\\/]|\u2026[\\/]|steamapps[\\/]common[\\/])') {
        return Resolve-ReadmeAbbreviatedPath -Raw $path -Context $Session.Context
    }
    if ($DocumentLink -and $Session.BaseDir -and -not [IO.Path]::IsPathRooted($path) -and $path -notmatch '%') {
        try {
            $candidate = [IO.Path]::GetFullPath((Join-Path $Session.BaseDir $path))
            $documentRoot = [IO.Path]::GetFullPath((Split-Path $Session.BaseDir -Parent)).TrimEnd('\') + '\'
            if ($candidate.StartsWith($documentRoot, [StringComparison]::OrdinalIgnoreCase)) {
                $hit = Resolve-StepFolder -Raw $candidate
                if ($hit) { return $hit }
            }
        } catch {}
    }
    # "Downloads" on its own means the folder itself - readmes say "in your
    # Downloads folder" - so unlike Documents this also matches without a
    # trailing separator.
    if ($path -match '^Downloads([\\/]|$)' -and $Session.DownloadsRoot) {
        $rest = $path.Substring(9).TrimStart('\','/')
        $hit = if ($rest) { Resolve-StepFolder -Raw $rest -GameDir $Session.DownloadsRoot }
               else { Resolve-StepFolder -Raw $Session.DownloadsRoot }
        if ($hit) { return $hit }
    }
    $documentsPath = $path -match '^Documents[\\/]'
    if (-not $documentsPath -and $Session.Targets.ContainsKey($path)) { return $Session.Targets[$path] }
    # Do not undo the index's ambiguity check by probing only the top-level
    # roots here: that could prefer a parked copy over the active binary's file.
    if ($path -notmatch '[\\/%]' -and $Session.AmbiguousTargets.ContainsKey($path)) { return $null }
    $hits = @{}
    if ($documentsPath -and $Session.DocumentsRoot) {
        # Windows' known folder also follows OneDrive/custom redirection. Do
        # not manufacture C:\Users\<name>\Documents from the profile name.
        $hit = Resolve-StepFolder -Raw $path.Substring(10) -GameDir $Session.DocumentsRoot
        if ($hit) { $hits[$hit.Path] = $hit }
    }
    foreach ($root in $Session.Context.Roots) {
        $hit = Resolve-StepFolder -Raw $path -GameDir $root
        # A final-component wildcard means 'open the containing folder', never
        # execute/select a guessed file. Require at least one matching child.
        if (-not $hit -and $path -match '[*?]' -and $path -notmatch '[<>]') {
            $clean = $path.TrimEnd('\','/')
            $parent = Split-Path $clean -Parent
            $leaf = Split-Path $clean -Leaf
            if ($parent -notmatch '[*?]' -and $leaf -match '[*?]') {
                $parentHit = Resolve-StepFolder -Raw $(if ($parent) { $parent } else { '.' }) -GameDir $root
                if ($parentHit -and -not $parentHit.Select) {
                    $namePattern = '^' + [regex]::Escape($leaf).Replace('\*','.*').Replace('\?','.') + '$'
                    $children = @(Get-ChildItem -LiteralPath $parentHit.Folder -Force -ErrorAction SilentlyContinue | Where-Object {
                        $_.Name -match $namePattern -and ($path -notmatch '[\\/]$' -or $_.PSIsContainer)
                    })
                    if ($children.Count) { $hit = $parentHit }
                }
            }
        }
        if ($hit) { $hits[$hit.Path] = $hit }
    }
    if ($hits.Count -eq 1) { return @($hits.Values)[0] }
    return $null
}

function global:Get-ReadmePathPrefix {
    param([string]$Text, $Session)
    $candidates = @($Text.TrimEnd())
    foreach ($space in @([regex]::Matches($Text, '\s+') | Sort-Object Index -Descending)) {
        $candidates += $Text.Substring(0, $space.Index)
    }
    foreach ($candidate in $candidates) {
        foreach ($clean in @($candidate.TrimEnd('.'), $candidate.TrimEnd('.', ')', ']', ':'))) {
            $hit = Resolve-ReadmePath -Raw $clean -Session $Session
            if ($hit) { return @{ Text=$clean; Target=$hit } }
        }
    }
    return $null
}

function global:Update-ReadmeLinkSession {
    param($Session)
    $Session.Context = Get-UninstallGuideContext $Session.Game
    $Session.AmbiguousTargets = @{}
    $Session.Targets = Get-UninstallGuideTargets -Context $Session.Context -Steps $Session.Texts -Ambiguous $Session.AmbiguousTargets
    # These can refer to another app/mod or a manager's UI, not the game root.
    foreach ($label in @('install folder', 'Show folder')) { $Session.Targets.Remove($label) }
    if ($Session.Context) {
        foreach ($span in @(Get-ReadmeInlineSpans ($Session.Texts -join "`n"))) {
            if ($span.Kind -notin @('code','boldcode')) { continue }
            $hit = Resolve-ReadmePath -Raw $span.Text -Session $Session
            if ($hit) { $Session.Targets[$span.Text] = $hit }
            elseif ($span.Text -match '^Documents[\\/]') { $Session.Targets.Remove($span.Text) }
        }
        # Include whole example paths with spaces, including indented blocks
        # and prose. Longest aliases win over individual directory names.
        $examplePattern = '(?<![\w.\\/])(?:\.{3}[\\/]|\u2026[\\/]|steamapps[\\/]common[\\/])[^\r\n`"''<>|,;]+'
        foreach ($match in [regex]::Matches(($Session.Texts -join "`n"), $examplePattern, 'IgnoreCase')) {
            $prefix = Get-ReadmePathPrefix -Text $match.Value -Session $Session
            if ($prefix) { $Session.Targets[$prefix.Text] = $prefix.Target }
        }
    }
    $Session.Pattern = if ($Session.Targets.Count) { (@($Session.Targets.Keys | Sort-Object Length -Descending | ForEach-Object { Get-GuideAliasPattern $_ }) -join '|') } else { $null }
}

# Windows has no SpecialFolder entry for Downloads - it is a Known
# Folder, and users do move it. The registry entry is the real answer;
# the profile path is only the fallback when that read fails.
function global:Get-ReadmeDownloadsRoot {
    try {
        $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
        $raw = (Get-ItemProperty -Path $key -Name '{374DE290-123F-4565-9164-39C4925E467B}' -ErrorAction Stop).'{374DE290-123F-4565-9164-39C4925E467B}'
        if ($raw) {
            $expanded = [Environment]::ExpandEnvironmentVariables($raw)
            if ($expanded -and (Test-Path -LiteralPath $expanded)) { return $expanded }
        }
    } catch {}
    $fallback = Join-Path $env:USERPROFILE 'Downloads'
    if (Test-Path -LiteralPath $fallback) { return $fallback }
    return $null
}

function global:New-ReadmeLinkSession {
    param($Game, [string[]]$Texts, [string]$BaseDir)
    $session = [pscustomobject]@{
        Game=$Game; Texts=$Texts; BaseDir=$BaseDir; Context=$null; Targets=@{}; AmbiguousTargets=@{}; Pattern=$null
        DocumentsRoot=[Environment]::GetFolderPath('MyDocuments')
        DownloadsRoot=(Get-ReadmeDownloadsRoot)
        Blocks=(New-Object 'System.Collections.Generic.List[object]')
    }
    Update-ReadmeLinkSession $session
    if ($null -ne $global:DetailReadmeLinkSessions) { [void]$global:DetailReadmeLinkSessions.Add($session) }
    return $session
}

function global:Get-ReadmeNonPathRanges {
    param([string]$Text)
    # Names used throughout the bundled READMEs. They describe software, not
    # filesystem locations. Explicit paths and named folders are still usable.
    $names = @(
        'Unreal(?:\s+Engine)?', 'UE[345]', 'Unity(?:\s+Mod\s+Manager)?',
        'Strata\s+Source', 'Source(?:\s*2)?(?:[- ]engine)?', 'RE\s+Engine',
        'AnvilNext', 'X-Ray', 'id\s+Tech', 'Godot', 'LithTech', 'HPL[12]',
        'GZDoomVR', 'GZDoom', 'ZDoom', 'QuestZDoom', 'OpenJK', 'OpenMW(?:\s+VR)?',
        'FreeSpace\s+Open', 'SRB2', 'L[O\u00d6]VE',
        'Virtual\s+Desktop(?:\s+Streamer)?', 'SteamVR', 'Steam\s+Link', 'Steam',
        'Quest\s+Link', 'Air\s+Link', 'Oculus(?:\s+Debug\s+Tool)?', 'Meta(?:\s+Quest\s+Link)?',
        'Windows\s+Mixed\s+Reality', 'WMR', 'ALVR', 'VDXR', 'Varjo\s+Base',
        'OpenXR(?:\s+Toolkit)?', 'OpenVR', 'OpenComposite', 'ReShade',
        'BepInEx(?:Pack)?', 'MelonLoader', 'REFramework', 'UEVR(?:\s+(?:Deluxe|Classic))?',
        'UUVR', 'Rai\s*Pal', 'Cyber\s+Engine\s+Tweaks', 'CET', 'RED4ext',
        'ViGEm(?:Bus)?', 'SMAPI', 'Generic\s+Mod\s+Config\s+Menu',
        'Mod\s+Organizer(?:\s*2)?', 'MO2', 'Wabbajack', 'DepotDownloader',
        'Cemu', 'Dolphin(?:\s+VR)?', '7-Zip', 'Windows\s+Defender',
        '\.NET\s+Desktop\s+Runtime', 'Config\s+Tool', 'Desktop\s+Game\s+Theat(?:er|re)'
    )
    $pattern = '(?<placeholder><[^>\r\n]+>)|(?<![\w])(?:' + ($names -join '|') + ')(?:\s+v?\d+(?:\.\d+)*(?:[ab]\d+)?)?(?:[- ]engine)?(?![\w])'
    return [regex]::Matches($Text, $pattern, 'IgnoreCase')
}

function global:Get-ReadmeMentionTarget {
    param([string]$Alias, [string]$Style, [string]$Text, [int]$Index, $Session, $NonPathRanges, $ContextTargets)
    $hit = if ($ContextTargets -and $ContextTargets.ContainsKey($Alias)) { $ContextTargets[$Alias] } else { $Session.Targets[$Alias] }
    if (-not $hit) { return $null }
    $before = $Text.Substring(0, $Index)
    $after = $Text.Substring($Index + $Alias.Length)
    $folderCue = $after -match '^\s+(?:folders?|director(?:y|ies)|subfolders?)\b' -or $before -match '\b(?:folder|directory)\s+(?:(?:named|called)\s+)?$'
    $codeAction = $Style -in @('code','boldcode') -and $before -match '\b(?:delete|remove|rename|copy|copies|move|open)\s+(?:the\s+)?$'
    foreach ($phrase in $NonPathRanges) {
        if ($Index -ge $phrase.Index -and $Index + $Alias.Length -le $phrase.Index + $phrase.Length) {
            if ($phrase.Groups['placeholder'].Success) { return $null }
            if ($Index -ne $phrase.Index -or $Alias.Length -ne $phrase.Length -or -not ($folderCue -or $codeAction)) { return $null }
        }
    }
    # Literal paths/files take precedence over their component names.
    if ($hit.Select -or $Alias -match '[\\/%]') { return $hit }
    if ($Alias -eq 'desktop' -and $after -match '^\s+(?:mirror|mode|view|runtime)\b') { return $null }
    if ($Alias -eq 'engine' -and $after -match '^\s+(?:level|version|runtime)\b') { return $null }
    $literal = $Style -in @('code','boldcode') -or $folderCue
    if ($Alias -eq 'binaries') {
        if ($literal) { return Resolve-StepFolder -Raw $Alias -GameDir $Session.Context.GameDir }
        $location = [regex]::Match($after, '^\s+(?:(?:live|are(?:\s+(?:kept|located))?)\s+)?(?:in|under|inside|at)\s*:?\s*(?<path>[^\r\n,;]+)', 'IgnoreCase')
        if ($location.Success -and $location.Groups['path'].Value -match '[\\/]') {
            # A nearby stated location overrides the current game's default.
            # A missing location may describe another game; do not redirect it.
            $prefix = Get-ReadmePathPrefix -Text $location.Groups['path'].Value -Session $Session
            if ($prefix) { return $prefix.Target }
            return $null
        }
        # "Binaries download" and "licensed binaries" are not folder names.
        # The README must state the intended location, not silently guess it
        # from whichever executable or mod happened to be detected.
        return $null
    }
    if ($literal -or $hit.Path -eq $Session.Context.GameDir -or $Alias -match '[_.@+-]') { return $hit }
    if ($before -match '["'']$' -and $after -match '^["'']') { return $hit }
    if ($before -match '\b(?:open|browse|locate|check|delete|remove|rename|inside|under|into|from|in)\s+(?:(?:the|your|its)\s+)?$') { return $hit }
    if ($Alias -eq 'desktop' -and ($after -match '^\s+shortcut\b' -or $before -match '\b(?:on|to|from)\s+(?:the|your|Windows)\s+$')) { return $hit }
    return $null
}

function global:Get-ReadmeContextTargets {
    param($Spans, $Session, [string]$Text, $NonPathRanges)
    $targets = @{}
    if (-not $Session.Context -or $Text -notmatch '\b(?:in|inside|from|under|at|folders?|director(?:y|ies)|next to|alongside|beside)\b') { return $targets }
    # A filename can be ambiguous across the whole README (installed defaults
    # versus personal settings, or two mods' identically named logs). Use only
    # an explicitly stated location in this paragraph/cell, never proximity
    # to an unrelated section elsewhere in the document.
    $extension = '\.(?:ini|cfg|conf|config|settings|log|txt|jsonc?|toml|ya?ml|xml)(?:\.(?:bak|old|backup|previous|\d+))?'
    if ($Text -notmatch $extension) { return $targets }
    $names = @{}
    $locations = @{}
    $offset = 0
    foreach ($span in $Spans) {
        $spanOffset = $offset
        $offset += $span.Text.Length
        if ($span.Kind -notin @('text','bold','code','boldcode')) { continue }
        if ($span.Kind -in @('code','boldcode') -and $span.Text -match ('^[\w][\w .@+-]*' + $extension + '$')) {
            $names[$span.Text] = $true
        } else {
            $filePattern = '(?<![\w.%+@/\\-])[\w][\w.@+-]*' + $extension + '(?![\w%+@/\\-]|\.[\w])'
            foreach ($match in [regex]::Matches($span.Text, $filePattern, 'IgnoreCase')) { $names[$match.Value] = $true }
        }
        if ($Session.Pattern) {
            foreach ($match in [regex]::Matches($span.Text, $Session.Pattern, 'IgnoreCase')) {
                $hit = Get-ReadmeMentionTarget -Alias $match.Value -Style $span.Kind -Text $Text -Index ($spanOffset + $match.Index) -Session $Session -NonPathRanges $NonPathRanges
                if (-not $hit) { continue }
                $isLocation = -not $hit.Select -and ($match.Value -match '[\\/%]' -or $span.Kind -in @('code','boldcode') -or $match.Value -eq 'game folder')
                $isNeighbor = $hit.Select -and (
                    ($match.Value -match '\.exe$' -and $Text -match '\b(?:next to|alongside|beside)\b') -or
                    ($match.Value -match '[\\/%]' -and $Text -match '\b(?:same|that)\s+(?:folder|directory)\b'))
                if ($isLocation -or $isNeighbor) { $locations[$hit.Folder.TrimEnd('\')] = $hit.Folder }
            }
        }
        # Remember missing explicit directories too: a missing user config
        # must not silently open a same-named shipped default in another root.
        if ($span.Kind -in @('code','boldcode') -and $span.Text -match '^[^=;<>\r\n]+[\\/]' -and $span.Text -notmatch '^\w+://') {
            $leaf = Split-Path $span.Text.TrimEnd('\','/') -Leaf
            if ($span.Text -match '[\\/]$' -or $leaf -notmatch '\.') {
                $hit = Resolve-ReadmePath -Raw $span.Text -Session $Session
                if (-not $hit) { $locations['missing:' + $span.Text.TrimEnd('\','/')] = $null }
            }
        }
    }
    # Two possible folders are still ambiguous. Explicit full paths keep
    # working, but no directory is chosen arbitrarily for a bare filename.
    if ($locations.Count -ne 1 -or -not $names.Count) { return $targets }
    $folder = @($locations.Values)[0]
    foreach ($name in $names.Keys) {
        $hit = if ($folder) { Resolve-StepFolder -Raw $name -GameDir $folder } else { $null }
        $targets[$name] = if ($hit -and $hit.Select) { $hit } else { $null }
    }
    return $targets
}

function global:Add-ReadmePathSpans {
    param($Spans, $Session)
    $visibleText = ($Spans | ForEach-Object { $_.Text }) -join ''
    $nonPathRanges = @(Get-ReadmeNonPathRanges $visibleText)
    $contextTargets = Get-ReadmeContextTargets -Spans $Spans -Session $Session -Text $visibleText -NonPathRanges $nonPathRanges
    $pattern = $Session.Pattern
    if ($contextTargets.Count) {
        $aliases = @($Session.Targets.Keys) + @($contextTargets.Keys)
        $pattern = (@($aliases | Sort-Object -Unique | Sort-Object Length -Descending | ForEach-Object { Get-GuideAliasPattern $_ }) -join '|')
    }
    $offset = 0
    foreach ($span in $Spans) {
        $spanOffset = $offset
        $offset += $span.Text.Length
        if ($span.Kind -eq 'destination') {
            $address = ConvertTo-ReadmeWebAddress $span.Address
            $hit = if (-not $address -and $Session) { Resolve-ReadmePath -Raw $span.Address -Session $Session -DocumentLink } else { $null }
            if ($address) { @{ Kind='url'; Text=$span.Text; Address=$address; Style=$span.Style } }
            elseif ($hit) { @{ Kind='local'; Text=$span.Text; Target=$hit; Style=$span.Style } }
            else { @{ Kind=$span.Style; Text=$span.Text } }
            continue
        }
        if ($span.Kind -notin @('text','bold','code','boldcode') -or -not $pattern) { $span; continue }
        $position = 0
        foreach ($match in [regex]::Matches($span.Text, $pattern, 'IgnoreCase')) {
            $hit = Get-ReadmeMentionTarget -Alias $match.Value -Style $span.Kind -Text $visibleText -Index ($spanOffset + $match.Index) -Session $Session -NonPathRanges $nonPathRanges -ContextTargets $contextTargets
            if (-not $hit) { continue }
            if ($match.Index -gt $position) { @{ Kind=$span.Kind; Text=$span.Text.Substring($position, $match.Index - $position) } }
            @{ Kind='local'; Text=$match.Value; Target=$hit; Style=$span.Kind }
            $position = $match.Index + $match.Length
        }
        if ($position -lt $span.Text.Length) { @{ Kind=$span.Kind; Text=$span.Text.Substring($position) } }
    }
}

function global:New-ReadmeWebLink {
    param([string]$Text, [string]$Address)
    $link = New-Object System.Windows.Documents.Hyperlink
    [void]$link.Inlines.Add([System.Windows.Documents.Run]::new($Text))
    $link.NavigateUri = [Uri]$Address
    $link.ToolTip = $Address
    $link.Cursor = [System.Windows.Input.Cursors]::Hand
    $link.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#6cb6ff')
    $link.TextDecorations = $null
    $link.Add_Click({
        param($sender, $eventArgs)
        $eventArgs.Handled = $true
        $safeAddress = ConvertTo-ReadmeWebAddress $Address
        if (-not $safeAddress) { return }
        try { Start-Process -FilePath $safeAddress -ErrorAction Stop | Out-Null }
        catch { [void][System.Windows.MessageBox]::Show($_.Exception.Message, 'Open link', 'OK', 'Warning') }
    }.GetNewClosure())
    $link.Add_MouseEnter({ $this.TextDecorations = [System.Windows.TextDecorations]::Underline })
    $link.Add_MouseLeave({ $this.TextDecorations = $null })
    return $link
}

function global:Update-DetailReadmeLinks {
    foreach ($session in $global:DetailReadmeLinkSessions) {
        if (-not $session) { continue }
        Update-ReadmeLinkSession $session
        foreach ($block in $session.Blocks) {
            Set-TextBlockWithLinks -TextBlock $block.Control -Text $block.Text -AccentHex $block.Accent -BaseFont $block.Control.FontSize -LinkSession $session -Literal:$block.Literal -NoRegister
        }
    }
}
