# Uninstall guide button - sits next to the Steam Theatre button
# at the end of the readme. Click reveals a numbered step-by-step
# tooltip explaining how to safely remove the VR mod and the
# game. Steps adapt based on whether the game uses Steam launch
# options (which the user has to clear manually - we can't do it
# from the Hub since Steam doesn't expose that API).
function global:Test-ShowDetailReinstallAction {
    param([bool]$IsExternal, [bool]$IsReady, [bool]$IsUpdate)
    # Entries in Easy External Installers are redirects, not Hub-owned
    # installations. Detection may still mark them ready, but the Hub has no
    # repair/reinstall transaction to offer for them.
    return (-not $IsExternal -and ($IsReady -or $IsUpdate))
}

function global:Show-ExePicker {
    # Small WinForms list dialog: the user confirms which .exe launches
    # the game in a located folder (used when the catalog LaunchExe is
    # absent / named differently). Returns the chosen full exe path or
    # $null. Input is an array of full exe paths.
    param(
        [string[]]$Exes,
        [string]$Title
    )
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Select the game exe for " + $Title
    $form.Width = 480
    $form.Height = 340
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Which file launches the game?"
    $lbl.SetBounds(12, 10, 440, 20)

    $list = New-Object System.Windows.Forms.ListBox
    $list.SetBounds(12, 36, 444, 212)
    foreach ($e in $Exes) { [void]$list.Items.Add((Split-Path -Leaf $e)) }
    if ($list.Items.Count -gt 0) { $list.SelectedIndex = 0 }

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "Use this"
    $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $ok.SetBounds(280, 258, 80, 30)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = "Cancel"
    $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancel.SetBounds(372, 258, 80, 30)

    $form.Controls.AddRange(@($lbl, $list, $ok, $cancel))
    $form.AcceptButton = $ok
    $form.CancelButton = $cancel

    $res = $form.ShowDialog()
    if ($res -eq [System.Windows.Forms.DialogResult]::OK -and $list.SelectedIndex -ge 0) {
        return $Exes[$list.SelectedIndex]
    }
    return $null
}

function global:New-ClearLocationButton {
    # Removes a user-located game's recorded path + launch override +
    # marker so the entry goes back to "not found" and the user can
    # locate it again from scratch. Correction path for user mistakes.
    param(
        $Game,
        [string]$AccentHex = "#888899"
    )
    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius    = [System.Windows.CornerRadius]::new(7)
    $btn.Padding         = [System.Windows.Thickness]::new(16, 10, 16, 10)
    $btn.Cursor          = [System.Windows.Input.Cursors]::Hand
    $btn.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161d")
    $btn.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $btn.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8a5560")

    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text       = "Clear"
    $t.FontSize   = 14
    $t.FontWeight = [System.Windows.FontWeights]::SemiBold
    $t.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#d2a0ad")
    $btn.Child    = $t

    $tip = New-Object System.Windows.Controls.ToolTip
    $tip.Content = "Forget the located folder for this game."
    $btn.ToolTip = $tip

    $btn.Add_MouseLeftButtonUp({
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $r = [System.Windows.Forms.MessageBox]::Show(
                ("Forget the saved location for " + $Game.Title + "?`r`n`r`nIt will go back to 'not found' until you locate it again."),
                "Clear location",
                [System.Windows.Forms.MessageBoxButtons]::YesNo)
            if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
            foreach ($f in @((Get-InstalledPathFile -Game $Game), (Get-LaunchOverrideFile -Game $Game), (Get-UserLocatedFile -Game $Game))) {
                if ($f -and (Test-Path $f)) { try { Remove-Item -Path $f -Force -ErrorAction SilentlyContinue } catch {} }
            }
            # The same values are mirrored under LocalAppData so a Hub update
            # does not forget custom locations. Clear both copies together;
            # otherwise Read-InstalledPath immediately resurrects the location
            # the user just asked us to forget.
            foreach ($stateName in @('installed_path', 'launch_exe', 'user_located')) {
                Reset-PersistentGameStateValue -Game $Game -Name $stateName
                $remaining = Read-PersistentGameStateValue -Game $Game -Name $stateName
                if ($remaining) { throw "The saved $stateName value could not be cleared." }
            }
            $global:PendingInstallTitle = $Game.Title
            Invoke-PostInstallRefreshSafely
            [System.Windows.Forms.MessageBox]::Show(
                ($Game.Title + " location cleared."),
                "Clear location") | Out-Null
        } catch {
            Write-HubActionFailure -Action ("Clear saved location for " + $Game.Title) -ErrorRecord $_
        }
    }.GetNewClosure())

    return $btn
}

# Read and update one conventional INI value without replacing the rest of
# the file. A few ports expose their official Flat / VR switch as a setting
# instead of a proxy rename; preserving comments and unrelated settings is
# essential because the file belongs to the game/mod, not to the Hub.
function global:Get-FlatVRIniValue {
    param([string]$Path, [string]$Section, [string]$Key)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $inside = $false
    try {
        foreach ($line in @(Get-Content -LiteralPath $Path -ErrorAction Stop)) {
            if ($line -match '^\s*\[([^\]]+)\]\s*$') {
                $inside = ($matches[1] -ieq $Section)
                continue
            }
            if ($inside -and $line -match ('^\s*' + [regex]::Escape($Key) + '\s*=\s*(.*?)\s*(?:[;#].*)?$')) {
                return $matches[1].Trim()
            }
        }
    } catch {}
    return $null
}

function global:Set-FlatVRIniValue {
    param([string]$Path, [string]$Section, [string]$Key, [string]$Value)
    if (-not $Path -or -not $Section -or -not $Key) { throw 'Incomplete INI switch configuration.' }
    $lines = @()
    if (Test-Path -LiteralPath $Path -PathType Leaf) { $lines = @(Get-Content -LiteralPath $Path -ErrorAction Stop) }
    $sectionStart = -1; $sectionEnd = $lines.Count; $keyIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\[([^\]]+)\]\s*$') {
            if ($sectionStart -ge 0) { $sectionEnd = $i; break }
            if ($matches[1] -ieq $Section) { $sectionStart = $i }
        } elseif ($sectionStart -ge 0 -and $lines[$i] -match ('^\s*' + [regex]::Escape($Key) + '\s*=')) {
            $keyIndex = $i
        }
    }
    if ($keyIndex -ge 0) {
        $lines[$keyIndex] = "$Key=$Value"
    } elseif ($sectionStart -ge 0) {
        $before = if ($sectionEnd -gt 0) { @($lines[0..($sectionEnd - 1)]) } else { @() }
        $after = if ($sectionEnd -lt $lines.Count) { @($lines[$sectionEnd..($lines.Count - 1)]) } else { @() }
        $lines = @($before) + "$Key=$Value" + @($after)
    } else {
        if ($lines.Count -gt 0 -and $lines[-1] -ne '') { $lines += '' }
        $lines += "[$Section]"
        $lines += "$Key=$Value"
    }
    $parent = [IO.Path]::GetDirectoryName($Path)
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { [void][IO.Directory]::CreateDirectory($parent) }
    [IO.File]::WriteAllLines($Path, [string[]]$lines, (New-Object Text.UTF8Encoding($false)))
}

# Resolve a BepInEx-winhttp game's folder and locate its winhttp proxy.
# Returns @{ Dir; Path; Active } (Active=$true VR on, $false flat, $null
# unknown) or $null if the folder can't be resolved. Shared by the
# Flat/VR switch button for both its initial state and its click toggle.
function global:Get-FlatVRProxyInfo {
    param($Game)
    $dir = $null
    $st = $global:gameStateMap[$Game.Title]
    if ($st -and $st.GameDir -and (Test-Path -LiteralPath $st.GameDir)) { $dir = $st.GameDir }
    if (-not $dir) {
        $mf = Get-InstalledPathFile -Game $Game
        if ($mf -and (Test-Path $mf)) {
            try { $rp = (Get-Content -LiteralPath $mf -Raw).Trim(); if ($rp -and (Test-Path -LiteralPath $rp)) { $dir = $rp } } catch {}
        }
    }
    if (-not $dir) { return $null }
    # Official INI switch. Missing file/key means the mod's default (VR on),
    # and the first click creates only the documented setting.
    if ($Game.FlatVRIniFile -and $Game.FlatVRIniSection -and $Game.FlatVRIniKey) {
        $iniPath = Join-Path $dir ([string]$Game.FlatVRIniFile)
        $flatValue = if ($null -ne $Game.FlatVRIniFlatValue) { [string]$Game.FlatVRIniFlatValue } else { '1' }
        $vrValue = if ($null -ne $Game.FlatVRIniVRValue) { [string]$Game.FlatVRIniVRValue } else { '0' }
        $value = Get-FlatVRIniValue -Path $iniPath -Section ([string]$Game.FlatVRIniSection) -Key ([string]$Game.FlatVRIniKey)
        return @{
            Dir=$dir; Path=$iniPath; Active=($value -ne $flatValue)
            Ini=@{ Path=$iniPath; Section=[string]$Game.FlatVRIniSection; Key=[string]$Game.FlatVRIniKey; VRValue=$vrValue; FlatValue=$flatValue }
            EnabledLeaf=[IO.Path]::GetFileName($iniPath); DisabledLeaf=[IO.Path]::GetFileName($iniPath)
        }
    }
    # Per-game override for the proxy file (e.g. Portal 2 uses
    # bin\openvr_api.dll <-> bin\openvr_api.dll-). Enabled = VR on.
    #
    # BOTH FIELDS MAY LIST SEVERAL CANDIDATES separated by "|", in matching
    # order. A game can have more than one possible proxy: BioShock ships
    # two VR mods with different injectors (dxgi.dll for BioVRDev,
    # xinput1_3.dll for balouza) and only the ACTIVE one is on disk, and
    # its folder differs between the Steam and the Epic build. The first
    # candidate that is actually there wins, so the switch always toggles
    # whichever mod is currently installed. A single name behaves exactly
    # as before - one candidate, same result.
    # FlatVRSwap: for mods that REWRITE a file instead of dropping a
    # proxy DLL next to it (Pathfinder: its VRPatcher writes OpenVR into
    # Kingmaker_Data\globalgamemanagers). Renaming does not work there -
    # the game needs the file. So it is swapped:
    #   <file>|<backup of the original>|<parking spot for the VR copy>
    # If the parking spot exists, FLAT is currently active.
    if ($Game.FlatVRSwap) {
        $sw = @(([string]$Game.FlatVRSwap) -split '\|' | Where-Object { $_ })
        if ($sw.Count -ge 3) {
            $live = Join-Path $dir $sw[0].Trim()
            $orig = Join-Path $dir $sw[1].Trim()
            $park = Join-Path $dir $sw[2].Trim()
            if (Test-Path -LiteralPath $live) {
                return @{ Dir=$dir; Path=$live; Active=(-not (Test-Path -LiteralPath $park));
                          Swap=@{ Live=$live; Orig=$orig; Park=$park; LiveRoot=$dir };
                          EnabledLeaf=(Split-Path -Leaf $live); DisabledLeaf=(Split-Path -Leaf $live) }
            }
        }
    }
    if ($Game.FlatVREnabled -and $Game.FlatVRDisabled) {
        $enList  = @(([string]$Game.FlatVREnabled)  -split '\|' | Where-Object { $_ })
        $disList = @(([string]$Game.FlatVRDisabled) -split '\|' | Where-Object { $_ })
        # Some render wrappers are a coordinated set rather than alternative
        # candidates. Black Mesa VR ships the same DXVK/OpenXR bridge at
        # three load boundaries; parking only the first would leave a mixed,
        # undefined mode. FlatVRAll makes the whole list one atomic group.
        if ($Game.FlatVRAll) {
            $pairs = New-Object 'System.Collections.Generic.List[object]'
            $enabledCount = 0; $disabledCount = 0; $missingCount = 0
            for ($gi = 0; $gi -lt $enList.Count; $gi++) {
                $enRel = $enList[$gi].Trim()
                $disRel = if ($gi -lt $disList.Count) { $disList[$gi].Trim() } else { "$enRel.pcvrhub-off" }
                $enFull = Join-Path $dir $enRel
                $disFull = Join-Path $dir $disRel
                $hasOn = Test-Path -LiteralPath $enFull -PathType Leaf
                $hasOff = Test-Path -LiteralPath $disFull -PathType Leaf
                if ($hasOn -and $hasOff) { return @{ Dir=$dir; Path=$enFull; Active=$null; GroupConflict=$true; Group=$pairs.ToArray(); EnabledLeaf=$enRel; DisabledLeaf=$disRel } }
                if ($hasOn) { $enabledCount++ } elseif ($hasOff) { $disabledCount++ } else { $missingCount++ }
                [void]$pairs.Add([pscustomobject]@{ Enabled=$enFull; Disabled=$disFull; EnabledRel=$enRel; DisabledRel=$disRel })
            }
            $active = if ($missingCount -eq 0 -and $enabledCount -eq $pairs.Count) { $true } elseif ($missingCount -eq 0 -and $disabledCount -eq $pairs.Count) { $false } else { $null }
            $firstPath = @($pairs | ForEach-Object { if (Test-Path -LiteralPath $_.Enabled) { $_.Enabled } elseif (Test-Path -LiteralPath $_.Disabled) { $_.Disabled } } | Select-Object -First 1)
            return @{ Dir=$dir; Path=$(if ($firstPath.Count) {$firstPath[0]} else {$null}); Active=$active; Group=$pairs.ToArray(); GroupMissing=$missingCount; EnabledLeaf=$enList[0]; DisabledLeaf=$disList[0] }
        }
        for ($fi = 0; $fi -lt $enList.Count; $fi++) {
            $enRel  = $enList[$fi].Trim()
            $disRel = if ($fi -lt $disList.Count) { $disList[$fi].Trim() } else { "$enRel-" }
            if (-not $enRel) { continue }
            $enFull  = Join-Path $dir $enRel
            $disFull = Join-Path $dir $disRel
            $enLeaf  = Split-Path -Leaf $enRel
            $disLeaf = Split-Path -Leaf $disRel
            # FlatVRDisabledWins: normally the enabled name is checked
            # first, because for a plain rename only one of the two can
            # exist. Some mods do NOT just rename - they park themselves
            # as .disabled AND put the game's own original file back under
            # the enabled name (Rebel Galaxy VR on the Epic build does
            # exactly that, restoring xinput1_3_original.dll). Then BOTH
            # names are on disk while the mod is OFF, the enabled-first
            # check reads that as VR-on, and the next toggle renames the
            # restored ORIGINAL over the parked mod - the mod is gone.
            # Where a game sets this flag the disabled marker decides:
            # if it is there, the mod is parked, full stop.
            if ($Game.FlatVRDisabledWins -and (Test-Path -LiteralPath $disFull)) {
                return @{ Dir=$dir; Path=$disFull; Active=$false; EnabledLeaf=$enLeaf; DisabledLeaf=$disLeaf }
            }
            if (Test-Path -LiteralPath $enFull)  { return @{ Dir=$dir; Path=$enFull;  Active=$true;  EnabledLeaf=$enLeaf; DisabledLeaf=$disLeaf } }
            if (Test-Path -LiteralPath $disFull) { return @{ Dir=$dir; Path=$disFull; Active=$false; EnabledLeaf=$enLeaf; DisabledLeaf=$disLeaf } }
        }
        # Nothing on disk - report the first pair so the button can still
        # label itself.
        $enLeaf0  = if ($enList.Count  -gt 0) { Split-Path -Leaf $enList[0].Trim() }  else { $null }
        $disLeaf0 = if ($disList.Count -gt 0) { Split-Path -Leaf $disList[0].Trim() } else { $null }
        return @{ Dir=$dir; Path=$null; Active=$null; EnabledLeaf=$enLeaf0; DisabledLeaf=$disLeaf0 }
    }
    # Default: BepInEx winhttp.dll proxy (game root first, then a shallow
    # search for subfolder mods like release\ or DLC\).
    foreach ($nm in @("winhttp.dll","winhttp_bak.dll")) {
        $p = Join-Path $dir $nm
        if (Test-Path -LiteralPath $p) { return @{ Dir=$dir; Path=$p; Active=($nm -eq "winhttp.dll"); EnabledLeaf="winhttp.dll"; DisabledLeaf="winhttp_bak.dll" } }
    }
    foreach ($nm in @("winhttp.dll","winhttp_bak.dll")) {
        try {
            $hit = Get-ChildItem -LiteralPath $dir -Filter $nm -Recurse -Depth 3 -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hit) { return @{ Dir=$dir; Path=$hit.FullName; Active=($nm -eq "winhttp.dll"); EnabledLeaf="winhttp.dll"; DisabledLeaf="winhttp_bak.dll" } }
        } catch {}
    }
    return @{ Dir=$dir; Path=$null; Active=$null; EnabledLeaf="winhttp.dll"; DisabledLeaf="winhttp_bak.dll" }
}

# Resolve the R.E.A.L. (Luke Ross) mod folder + its current VR/flat state.
# The mod files (RealRepo, dxgi.dll, RealConfig.bat, DISABLE_VR.bat) all
# live next to the game EXE - which may be the game root OR a subfolder
# (e.g. Elden Ring / Dark Souls III use Game\). RealConfig.bat is the
# reliable anchor: always present after install, never renamed by the
# toggle, and unique to the mod folder - so we locate the folder by it and
# stay correct whether the recorded path is the exe folder or the root.
# Active = VR on (RealRepo present); $false = flat (RealRepo_ present).
function global:Get-RealVRToggleInfo {
    param($Game)
    $base = $null
    $st = $global:gameStateMap[$Game.Title]
    if ($st -and $st.GameDir -and (Test-Path -LiteralPath $st.GameDir)) { $base = $st.GameDir }
    if (-not $base) { return $null }
    $modDir = $null
    # Fast path: the recorded folder already holds the mod (usual case -
    # .installed_path records the exe folder).
    foreach ($probe in @("RealConfig.bat","RealRepo","RealRepo_")) {
        # Lexical: library roots come from libraryfolders.vdf and can name a
        # drive that is gone. Join-Path resolves it and throws, which would
        # take down the scan instead of skipping one dead entry.
        if (Test-Path -LiteralPath (Join-HubPathLexical $base $probe)) { $modDir = $base; break }
    }
    # Fallback: recorded path is the game root; find RealConfig.bat below it.
    if (-not $modDir) {
        try {
            $hit = Get-ChildItem -LiteralPath $base -Filter "RealConfig.bat" -Recurse -Depth 3 -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hit) { $modDir = $hit.DirectoryName }
        } catch {}
    }
    if (-not $modDir) { return $null }
    $active = $null
    if (Test-Path -LiteralPath (Join-Path $modDir "RealRepo"))       { $active = $true }
    elseif (Test-Path -LiteralPath (Join-Path $modDir "RealRepo_"))  { $active = $false }
    return @{ Dir = $modDir; Active = $active }
}

# Flat / VR switch button - for BepInEx-winhttp mods, whose loader is a
# winhttp.dll proxy in (or under) the game folder. Renaming winhttp.dll
# to winhttp_bak.dll disables the mod (flat); renaming back re-enables VR.
# The button shows BOTH modes and paints the ACTIVE one in the gold
# VR-Ready colour, the other greyed, so the current state is always clear.
function global:New-FlatVRToggleButton {
    param(
        $Game,
        [string]$AccentHex = "#5aa0d0"
    )
    $goldHex = "#cdb77a"; $grayHex = "#767688"
    # R.E.A.L. (Luke Ross) mods toggle differently from BepInEx: they rename
    # the RealRepo folder (+ optional dxgi.dll) and re-run RealConfig on
    # re-enable, per the mod author's official DISABLE_VR steps.
    $isReal = ($Game.Bat -and ($Game.Bat -match 'LukeRossVR'))

    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius    = [System.Windows.CornerRadius]::new(7)
    $btn.Padding         = [System.Windows.Thickness]::new(16, 10, 16, 10)
    $btn.Cursor          = [System.Windows.Input.Cursors]::Hand
    $btn.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161d")
    $btn.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $btn.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4a7ea0")

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.FontSize   = 14
    $lbl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $vrRun = New-Object System.Windows.Documents.Run; $vrRun.Text = "VR"
    $sepRun = New-Object System.Windows.Documents.Run; $sepRun.Text = "  /  "
    $sepRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($grayHex)
    $flatRun = New-Object System.Windows.Documents.Run; $flatRun.Text = "Flat"
    [void]$lbl.Inlines.Add($vrRun); [void]$lbl.Inlines.Add($sepRun); [void]$lbl.Inlines.Add($flatRun)
    $btn.Child = $lbl
    $btn.Resources.Add("vrRun", $vrRun)
    $btn.Resources.Add("flatRun", $flatRun)

    # Initial paint from the current on-disk state.
    $goldB = [System.Windows.Media.BrushConverter]::new().ConvertFromString($goldHex)
    $grayB = [System.Windows.Media.BrushConverter]::new().ConvertFromString($grayHex)
    $info0 = if ($isReal) { Get-RealVRToggleInfo -Game $Game } else { Get-FlatVRProxyInfo -Game $Game }
    $vrOn0 = if ($info0) { $info0.Active } else { $null }
    if ($vrOn0 -eq $true) {
        $vrRun.Foreground = $goldB; $vrRun.FontWeight = [System.Windows.FontWeights]::Bold
        $flatRun.Foreground = $grayB; $flatRun.FontWeight = [System.Windows.FontWeights]::Normal
    } elseif ($vrOn0 -eq $false) {
        $flatRun.Foreground = $goldB; $flatRun.FontWeight = [System.Windows.FontWeights]::Bold
        $vrRun.Foreground = $grayB; $vrRun.FontWeight = [System.Windows.FontWeights]::Normal
    } else {
        $vrRun.Foreground = $grayB; $flatRun.Foreground = $grayB
    }

    $tip = New-Object System.Windows.Controls.ToolTip
    $tip.Content = if ($isReal) {
        "Switch this game between VR and flat the official R.E.A.L. way (renames RealRepo, re-runs RealConfig). The active mode is shown in gold. Close the game first."
    } elseif ($Game.FlatVRIniFile) {
        "Switch this game between VR and flat with the mod's official INI setting. The active mode is shown in gold. Close the game first."
    } elseif ($Game.FlatVREnabled) {
        "Switch this game between VR and flat by parking its configured VR loader. The active mode is shown in gold. Close the game first."
    } else {
        "Switch this game between VR and flat (renames winhttp.dll). The active mode is shown in gold. Close the game first."
    }
    $btn.ToolTip = $tip

    # No bespoke glow here any more - Add-StandardHover gives this button
    # the same sweep + glow as every other one, and takes the glow colour
    # from this button's own border, so the blue stays blue.

    $btn.Add_MouseLeftButtonUp({
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            # Do not rely on Windows denying a rename of a loaded DLL. Some
            # games share their proxy file permissively, which would let the
            # UI report a mode change while the running process still uses
            # the old one. Entries with an executable probe can be checked
            # explicitly before touching their loader.
            $processProbe = if ($Game.GameExe) { [string]$Game.GameExe } elseif ($Game.LaunchExe) { [string]$Game.LaunchExe } else { "" }
            if ($processProbe) {
                $processName = [IO.Path]::GetFileNameWithoutExtension($processProbe)
                if ($processName -and @(Get-Process -Name $processName -ErrorAction SilentlyContinue).Count -gt 0) {
                    [System.Windows.Forms.MessageBox]::Show(
                        ($Game.Title + " is running. Close it completely before changing between VR and flat mode."),
                        "Flat / VR Switch") | Out-Null
                    return
                }
            }
            $nowVR = $true
            $msg = ""
            if ($isReal) {
                # R.E.A.L. (Luke Ross) official toggle: disable = rename
                # RealRepo -> RealRepo_ and dxgi.dll -> dxgi_.dll; re-enable =
                # rename them back and re-run RealConfig.bat.
                $ri = Get-RealVRToggleInfo -Game $Game
                if (-not $ri -or -not $ri.Dir) {
                    [System.Windows.Forms.MessageBox]::Show(
                        ("Couldn't find " + $Game.Title + "'s R.E.A.L. folder (RealConfig.bat). Make sure it's installed and located, then try again."),
                        "Flat / VR Switch") | Out-Null
                    return
                }
                $dir = $ri.Dir
                if ($ri.Active) {
                    if (Test-Path -LiteralPath (Join-Path $dir "RealRepo")) {
                        Rename-Item -LiteralPath (Join-Path $dir "RealRepo") -NewName "RealRepo_" -Force -ErrorAction Stop
                    }
                    if (Test-Path -LiteralPath (Join-Path $dir "dxgi.dll")) {
                        Rename-Item -LiteralPath (Join-Path $dir "dxgi.dll") -NewName "dxgi_.dll" -Force -ErrorAction SilentlyContinue
                    }
                    $nowVR = $false
                    $msg = $Game.Title + " is now in FLAT mode (R.E.A.L. off). Launch the game normally to play without VR."
                } else {
                    if (Test-Path -LiteralPath (Join-Path $dir "RealRepo_")) {
                        Rename-Item -LiteralPath (Join-Path $dir "RealRepo_") -NewName "RealRepo" -Force -ErrorAction Stop
                    }
                    if (Test-Path -LiteralPath (Join-Path $dir "dxgi_.dll")) {
                        Rename-Item -LiteralPath (Join-Path $dir "dxgi_.dll") -NewName "dxgi.dll" -Force -ErrorAction SilentlyContinue
                    }
                    if (Test-Path -LiteralPath (Join-Path $dir "RealConfig.bat")) {
                        Start-Process "cmd.exe" -ArgumentList "/c RealConfig.bat" -WorkingDirectory $dir -ErrorAction SilentlyContinue
                    }
                    $nowVR = $true
                    $msg = $Game.Title + " is now in VR mode (R.E.A.L. on). RealConfig is re-running - start SteamVR, then launch."
                }
            } else {
            $info = Get-FlatVRProxyInfo -Game $Game
            if (-not $info) {
                [System.Windows.Forms.MessageBox]::Show(
                    ("Couldn't find " + $Game.Title + "'s folder. Make sure it's installed and located, then try again."),
                    "Flat / VR Switch") | Out-Null
                return
            }
            if ($info.Ini) {
                $newValue = if ($info.Active) { [string]$info.Ini.FlatValue } else { [string]$info.Ini.VRValue }
                Set-FlatVRIniValue -Path $info.Ini.Path -Section $info.Ini.Section -Key $info.Ini.Key -Value $newValue
                $nowVR = -not [bool]$info.Active
                if ($nowVR) { $msg = $Game.Title + " is now in VR mode." }
                else        { $msg = $Game.Title + " is now in FLAT mode." }
            } elseif (-not $info.Path) {
                $missingName = if ($Game.FlatVREnabled) { "configured VR loader" } else { "winhttp.dll" }
                [System.Windows.Forms.MessageBox]::Show(
                    ("Couldn't find the VR mod's " + $missingName + " for " + $Game.Title + ". Reinstall the mod, then try again."),
                    "Flat / VR Switch") | Out-Null
                return
            } else {
            $parent = Split-Path -Parent $info.Path
            if ($info.Group) {
                if ($info.GroupConflict) { throw 'Both active and parked copies of at least one VR loader exist. Reinstall the mod before switching modes.' }
                if ($info.GroupMissing) { throw 'One or more coordinated VR loaders are missing. Reinstall the mod before switching modes.' }
                $enableVR = -not ($info.Active -eq $true)
                $operations = New-Object 'System.Collections.Generic.List[object]'
                foreach ($pair in $info.Group) {
                    $source = if ($enableVR) { [string]$pair.Disabled } else { [string]$pair.Enabled }
                    $target = if ($enableVR) { [string]$pair.Enabled } else { [string]$pair.Disabled }
                    if ((Test-Path -LiteralPath $source -PathType Leaf) -and (Test-Path -LiteralPath $target)) { throw "Both sides of a VR loader switch exist: $([IO.Path]::GetFileName($source))" }
                    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "A coordinated VR loader is missing: $([IO.Path]::GetFileName($source))" }
                    [void]$operations.Add([pscustomobject]@{ Source=$source; Target=$target })
                }
                $completed = New-Object 'System.Collections.Generic.List[object]'
                try {
                    foreach ($operation in $operations) {
                        Rename-Item -LiteralPath $operation.Source -NewName ([IO.Path]::GetFileName($operation.Target)) -Force -ErrorAction Stop
                        [void]$completed.Add($operation)
                    }
                } catch {
                    for ($rollbackIndex = $completed.Count - 1; $rollbackIndex -ge 0; $rollbackIndex--) {
                        $operation = $completed[$rollbackIndex]
                        if (Test-Path -LiteralPath $operation.Target -PathType Leaf) {
                            Rename-Item -LiteralPath $operation.Target -NewName ([IO.Path]::GetFileName($operation.Source)) -Force -ErrorAction SilentlyContinue
                        }
                    }
                    throw
                }
                $nowVR = $enableVR
                if ($nowVR) { $msg = $Game.Title + ' is now in VR mode.' }
                else { $msg = $Game.Title + ' is now in FLAT mode (all VR loaders parked).' }
            } elseif ($info.Swap) {
                # Swapping. Take the BepInEx loader hook along as well,
                # so both halves match - otherwise the plugin loads
                # without a VR device or the other way round.
                $hookOn  = Join-Path $info.Swap.LiveRoot "winhttp.dll"
                $hookOff = Join-Path $info.Swap.LiveRoot "winhttp_bak.dll"
                if ($info.Active) {
                    Copy-Item -LiteralPath $info.Swap.Live -Destination $info.Swap.Park -Force -ErrorAction Stop
                    Copy-Item -LiteralPath $info.Swap.Orig -Destination $info.Swap.Live -Force -ErrorAction Stop
                    if (Test-Path -LiteralPath $hookOn) {
                        if (Test-Path -LiteralPath $hookOff) { Remove-Item -LiteralPath $hookOff -Force -ErrorAction SilentlyContinue }
                        Rename-Item -LiteralPath $hookOn -NewName "winhttp_bak.dll" -Force -ErrorAction SilentlyContinue
                    }
                    $nowVR = $false
                    $msg = $Game.Title + " is now in FLAT mode (VR mod off)."
                } else {
                    Copy-Item -LiteralPath $info.Swap.Park -Destination $info.Swap.Live -Force -ErrorAction Stop
                    Remove-Item -LiteralPath $info.Swap.Park -Force -ErrorAction SilentlyContinue
                    if (Test-Path -LiteralPath $hookOff) {
                        if (Test-Path -LiteralPath $hookOn) { Remove-Item -LiteralPath $hookOn -Force -ErrorAction SilentlyContinue }
                        Rename-Item -LiteralPath $hookOff -NewName "winhttp.dll" -Force -ErrorAction SilentlyContinue
                    }
                    $nowVR = $true
                    $msg = $Game.Title + " is now in VR mode (mod on)."
                }
            } elseif ($info.Active) {
                $bak = Join-Path $parent $info.DisabledLeaf
                if (Test-Path -LiteralPath $bak) { Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue }
                Rename-Item -LiteralPath $info.Path -NewName $info.DisabledLeaf -Force -ErrorAction Stop
                $nowVR = $false
                $msg = $Game.Title + " is now in FLAT mode (VR mod off)."
            } else {
                $tgt = Join-Path $parent $info.EnabledLeaf
                if (Test-Path -LiteralPath $tgt) { Remove-Item -LiteralPath $tgt -Force -ErrorAction SilentlyContinue }
                Rename-Item -LiteralPath $info.Path -NewName $info.EnabledLeaf -Force -ErrorAction Stop
                $nowVR = $true
                $msg = $Game.Title + " is now in VR mode (mod on)."
            }
            }
            }
            # Repaint the label so the active mode shows gold.
            $vr = $this.Resources.Item("vrRun"); $fl = $this.Resources.Item("flatRun")
            $gB = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cdb77a")
            $grB = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#767688")
            if ($vr -and $fl) {
                if ($nowVR) {
                    $vr.Foreground = $gB; $vr.FontWeight = [System.Windows.FontWeights]::Bold
                    $fl.Foreground = $grB; $fl.FontWeight = [System.Windows.FontWeights]::Normal
                } else {
                    $fl.Foreground = $gB; $fl.FontWeight = [System.Windows.FontWeights]::Bold
                    $vr.Foreground = $grB; $vr.FontWeight = [System.Windows.FontWeights]::Normal
                }
            }
            [System.Windows.Forms.MessageBox]::Show($msg, "Flat / VR Switch") | Out-Null
        } catch {
            try {
                [System.Windows.Forms.MessageBox]::Show(
                    ("Couldn't switch mode: " + $_.Exception.Message + "`r`n`r`nIf the game is running, close it first."),
                    "Flat / VR Switch") | Out-Null
            } catch {}
        }
    }.GetNewClosure())

    return $btn
}

function global:Start-AlternativeModInstaller {
    # One launch path for every alternative-mod installer. A choice is
    # optional: legacy split-install pages can preselect one package, while
    # scalable entries such as Forza Horizon 6 open the installer's own menu.
    # Both routes share the exact same logging and post-install refresh.
    param($Game, [string]$InstallerChoice = '')
    if (-not $Game -or -not $Game.Bat -or -not $global:scriptDir) {
        Write-HubActionFailure -Action 'Open VR mod installer' -Message 'This entry has no valid Hub installer configured.'
        return $false
    }
    $installerBat = Join-Path $global:scriptDir $Game.Bat
    if (-not (Test-Path -LiteralPath $installerBat -PathType Leaf)) {
        Write-HubActionFailure -Action ("Open " + $Game.Title + " installer") -Message ("The configured installer is missing: " + $installerBat)
        return $false
    }
    try {
        $launch = @{
            Game          = $Game
            BatPath       = $installerBat
            RequiresAdmin = [bool]$Game.RequiresAdmin
        }
        if ($InstallerChoice) { $launch.InstallerChoice = $InstallerChoice }
        $installerProc = Start-LoggedInstaller @launch
        if ($installerProc) {
            $global:PendingInstallTitle = $Game.Title
            $installerTimer = New-Object System.Windows.Threading.DispatcherTimer
            $installerTimer.Interval = [TimeSpan]::FromMilliseconds(750)
            $installerTimer.Tag = $installerProc
            $installerTimer.Add_Tick({
                param($s, $e)
                $proc = $s.Tag
                if (Test-InstallerRefreshReady -Process $proc) {
                    try { $s.Stop() } catch {}
                    Invoke-PostInstallRefreshSafely
                }
            })
            $installerTimer.Start()
        } else {
            try { Watch-InstallMarkerForRefresh -Game $Game } catch {}
        }
        return $true
    } catch {
        Write-HubActionFailure -Action ("Open " + $Game.Title + " installer") -ErrorRecord $_
        return $false
    }
}

function global:New-TwoModsButton {
    # A green "VR Ready"-style launch button for one of an alternative-mod
    # game's packages. Click routes to Start-GameInVR with the declared
    # ModA..ModH mode. Detail pages may expose more choices than a tile.
    param(
        $Game,
        [string]$Mode,
        [string]$Label,
        [string]$AccentHex = "#888899",
        [switch]$Installed
    )
    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius    = [System.Windows.CornerRadius]::new(7)
    $btn.Padding         = [System.Windows.Thickness]::new(16, 10, 16, 10)
    $btn.Cursor          = [System.Windows.Input.Cursors]::Hand
    # Keep a constant height: without this the button vertical-stretches
    # to the row and grows next to the (slightly taller) Reinstall pill.
    # Centering pins it to its own content height.
    $btn.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $btn.BorderThickness = [System.Windows.Thickness]::new(1.5)
    if ($Installed) {
        $btn.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
        $btn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fa873")
    } else {
        $btn.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161d")
        $btn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a47")
    }

    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text       = $Label
    $t.FontSize   = 14
    $t.FontWeight = [System.Windows.FontWeights]::SemiBold
    $t.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($(if ($Installed) { "#88dd99" } else { "#c2cad2" }))
    $btn.Child    = $t

    $btn.Add_MouseLeftButtonUp({
        try {
            if ($Mode -eq 'InstallerMenu') {
                [void](Start-AlternativeModInstaller -Game $Game)
            } else {
                Start-GameInVR -Game $Game -Mode $Mode
            }
        } catch {
            Write-HubActionFailure -Action ("Run " + $Game.Title + " action") -ErrorRecord $_
        }
    }.GetNewClosure())

    return $btn
}

function global:Resolve-LocatedRoot {
    # Given a user-picked folder and a relative file (ModFile or
    # LaunchExe), return the folder that actually holds <root>\<RelFile>.
    # Many mods don't sit directly in the folder the user picks: the
    # file may be in a subfolder, an extra nesting level (e.g. Epic
    # "...\Cyberpunk 2077\Cyberpunk 2077\bin\..."), or the user may have
    # picked a subfolder of the real root. We check, in order:
    #   1. the picked folder directly,
    #   2. descendants (bounded depth) for <dir>\RelFile,
    #   3. up to two parent folders.
    # Returns the true root, or $null if the file isn't found anywhere.
    # Normalizing .installed_path to this root means the regular scan's
    # "Join-Path .installed_path ModFile" check keeps working unchanged.
    param([string]$Picked, [string]$RelFile, [int]$MaxDepth = 4)
    if ([string]::IsNullOrWhiteSpace($Picked) -or [string]::IsNullOrWhiteSpace($RelFile)) { return $null }
    # 1. Direct hit - the common, fast case.
    if (Test-Path -LiteralPath (Join-Path $Picked $RelFile)) { return $Picked }
    $suffix = "\" + $RelFile
    # 2. Bounded descendant search. Filter by the leaf file name so the
    #    recursion stays cheap, then confirm the FULL relative path
    #    matches (so a stray same-named file elsewhere can't match).
    try {
        $leaf = Split-Path -Leaf $RelFile
        $hits = Get-ChildItem -LiteralPath $Picked -Filter $leaf -Recurse -Depth $MaxDepth -File -ErrorAction SilentlyContinue
        foreach ($h in $hits) {
            if ($h.FullName.EndsWith($suffix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $root = $h.FullName.Substring(0, $h.FullName.Length - $suffix.Length)
                if (($root) -and (Test-Path -LiteralPath $root) -and (Test-Path (Join-Path $root $RelFile))) {
                    return $root
                }
            }
        }
    } catch {}
    # 3. Walk up to two parents (user picked a subfolder of the root).
    $up = $Picked
    for ($i = 0; $i -lt 2; $i++) {
        $up = Split-Path -Parent $up
        if ([string]::IsNullOrWhiteSpace($up)) { break }
        if (Test-Path (Join-Path $up $RelFile)) { return $up }
    }
    return $null
}

function global:New-LocateButton {
    # A user-pointed install locator. Shown on the detail page only when
    # Check Installed did not find the game. Opens a folder picker, checks
    # the ModFile is actually in the chosen folder, records the path via
    # Get-InstalledPathFile (the same file the scan reads + re-verifies),
    # then refreshes. Deleting the folder later still demotes correctly
    # because the scan re-checks the path + ModFile every run.
    param(
        $Game,
        [string]$AccentHex = "#888899",
        [string]$Label = "Locate Game"
    )

    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius     = [System.Windows.CornerRadius]::new(7)
    $btn.Padding          = [System.Windows.Thickness]::new(16, 10, 16, 10)
    $btn.Cursor           = [System.Windows.Input.Cursors]::Hand
    $btn.Background       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#16161d")
    $btn.BorderThickness  = [System.Windows.Thickness]::new(1.5)
    $btn.BorderBrush      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#50505f")

    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text       = $Label
    $t.FontSize   = 14
    $t.FontWeight = [System.Windows.FontWeights]::SemiBold
    $t.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c2cad2")
    $btn.Child    = $t

    $tip = New-Object System.Windows.Controls.ToolTip
    $tip.Content = "Choose its folder. The Hub checks known VR mod files first, then the game executable."
    $btn.ToolTip = $tip

    $btn.Add_MouseLeftButtonUp({
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
            if ($Game.TwoMods) {
                $locateModNames = @(Get-AlternativeModDefinitions -Game $Game | ForEach-Object { $_.Name })
                $locateModLabel = if ($locateModNames.Count) { $locateModNames -join ' / ' } else { 'one of its VR mods' }
                $dlg.Description = 'Select the "' + $Game.Title + '" game or package folder that holds ' + $locateModLabel + '.'
            } else {
                $dlg.Description = 'Select the folder that contains "' + $Game.Title + '" or its VR mod files.'
            }
            $dlg.ShowNewFolderButton = $false
            if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
            $picked = $dlg.SelectedPath
            if ([string]::IsNullOrWhiteSpace($picked) -or -not (Test-Path -LiteralPath $picked)) { return }

            # One label for all the messages below so the wording matches
            # the game type: alternative-mod titles name every known mod
            # instead of an awkward singular "its VR
            # mod", and the title's own "VR" isn't echoed twice.
            $modLabel = if ($Game.TwoMods) {
                $knownNames = @(Get-AlternativeModDefinitions -Game $Game | ForEach-Object { $_.Name })
                if ($knownNames.Count) { ($knownNames -join ' / ') + ' mod files' } else { 'VR mod files' }
            } else {
                "VR mod files"
            }
            # For the Plan B message we've only found the FLAT game install,
            # nothing VR yet - so drop the trailing " VR" from the Hub title
            # (e.g. "Forza Horizon 6 VR" -> "Forza Horizon 6") so we don't
            # imply a VR install exists at that point.
            $baseTitle = $Game.Title -replace ' VR$', ''

            # Two-tier detection with positive feedback either way:
            #   Plan A - the VR mod is here            -> VR Ready
            #   Plan B - only the game itself is here  -> installed (add mod later)
            # We only fall back to a confirm prompt if NEITHER is found.
            $modHit    = $false   # VR mod present (Plan A)
            $gameHit   = $false   # game itself present (Plan B)
            $chosenExe = $null    # launch target for the per-game override

            # ---- Plan A: is the VR mod here? ----
            # Resolve the real root: the ModFile may sit in a subfolder, an
            # extra nesting level, or one folder off. On a hit we normalize
            # $picked so the recorded .installed_path is exactly what the
            # scan re-checks later.
            if ($Game.ModFile) {
                $r = Resolve-LocatedRoot -Picked $picked -RelFile $Game.ModFile
                if ($r) { $modHit = $true; $picked = $r }
            }
            # Alternate payload generations are equally valid evidence. In
            # particular Halo MCC's Latest/Stable channel still uses
            # halo3xr.dll while the prerelease uses HaloMCCVR.dll.
            if (-not $modHit) {
                foreach ($alternateMarker in @($Game.ModFileAlt, $Game.ModFileAlt2)) {
                    if (-not $alternateMarker) { continue }
                    $r = Resolve-LocatedRoot -Picked $picked -RelFile $alternateMarker
                    if ($r) { $modHit = $true; $picked = $r; break }
                }
            }
            if (-not $modHit -and $Game.DoorstopTargetModFile -and (Test-DoorstopTargetModMarker -GameRoot $picked -TargetMarker $Game.DoorstopTargetModFile -LoaderFile $Game.DoorstopLoaderFile)) {
                $modHit = $true
            }
            # VrInstallRoot games keep the mod OUTSIDE the game folder
            # (%LocalAppData% etc.); check that root too. We do NOT move
            # $picked - it stays the game folder the user pointed at.
            if (-not $modHit -and $Game.VrInstallRoot -and $Game.ModFile) {
                $vrRoot = $Game.VrInstallRoot
                if     ($vrRoot -like "LOCALAPPDATA:*") { $vrRoot = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) ($vrRoot.Substring("LOCALAPPDATA:".Length)) }
                elseif ($vrRoot -like "APPDATA:*")      { $vrRoot = Join-Path ([Environment]::GetFolderPath("ApplicationData"))      ($vrRoot.Substring("APPDATA:".Length)) }
                elseif ($vrRoot -like "PROGRAMDATA:*")  { $vrRoot = Join-Path ([Environment]::GetFolderPath("CommonApplicationData")) ($vrRoot.Substring("PROGRAMDATA:".Length)) }
                elseif ($vrRoot -like "USERPROFILE:*")  { $vrRoot = Join-Path ([Environment]::GetFolderPath("UserProfile"))           ($vrRoot.Substring("USERPROFILE:".Length)) }
                if ($vrRoot -and (Test-Path -LiteralPath (Join-Path $vrRoot $Game.ModFile))) { $modHit = $true }
            }
            # Alternative-mod games have no single ModFile. Discover every
            # declared slot (A-H), not just the historic A/B pair, and prefer
            # its real probe marker over a launcher. This keeps Locate Game in
            # lockstep with the regular scanner when a third or later mod is
            # added. Be forgiving if the user picked the mod subfolder itself:
            # Resolve-LocatedRoot normalizes back to the shared package root.
            if ($Game.TwoMods) {
                $tmFound = $false
                foreach ($definition in @(Get-AlternativeModDefinitions -Game $Game)) {
                    $definitionRoot = $null
                    $markerPresent = $false
                    foreach ($rawMarker in @($definition.ProbeFile)) {
                        foreach ($marker in (([string]$rawMarker) -split '\|')) {
                            if ([string]::IsNullOrWhiteSpace($marker)) { continue }
                            $resolved = Resolve-LocatedRoot -Picked $picked -RelFile $marker.Trim()
                            if ($resolved) {
                                $definitionRoot = $resolved
                                $markerPresent = $true
                                break
                            }
                        }
                        if ($markerPresent) { break }
                    }
                    if (-not $markerPresent -and $definition.ProbeAbs) {
                        $markerPresent = Test-AbsolutePathMarker -Values $definition.ProbeAbs
                    }

                    $launchRel = $null
                    if ($definition.Launch) {
                        $launchRel = if ($definition.RootLaunch -or -not $definition.Sub -or $definition.Sub -eq '.') {
                            [string]$definition.Launch
                        } else {
                            Join-Path ([string]$definition.Sub) ([string]$definition.Launch)
                        }
                    }
                    $launchPresent = $false
                    if ($launchRel) {
                        $launchRoot = Resolve-LocatedRoot -Picked $picked -RelFile $launchRel
                        if ($launchRoot) {
                            $launchPresent = $true
                            if (-not $definitionRoot) { $definitionRoot = $launchRoot }
                        }
                    }

                    $probeDeclared = ([bool]$definition.ProbeFile -or [bool]$definition.ProbeAbs)
                    $presentHere = if ($probeDeclared) { $markerPresent } else { $launchPresent }
                    if ($presentHere -and $definition.RequiredFile -and $definitionRoot) {
                        $presentHere = Test-RelativePathMarker -Root $definitionRoot -Values $definition.RequiredFile
                    }
                    if ($presentHere) {
                        if ($definitionRoot) { $picked = $definitionRoot }
                        $tmFound = $true
                        break
                    }
                }
                if ($tmFound) { $modHit = $true }
            }

            # ---- Plan B: no VR mod -> is the game itself here? ----
            # Look for the actual GameExe first, then the VR LaunchExe. The
            # old path skipped GameExe completely, so a perfectly valid
            # alternate retail folder could fall through to the generic EXE
            # picker. A found GameExe proves the install but is only stored as
            # a launch override when the catalog has no different VR launcher.
            # Otherwise the later mod install remains free to add LaunchExe.
            # If neither exact name exists, scan for plausible root EXEs:
            # exactly one is accepted automatically, several let the user pick.
            if (-not $modHit) {
                $exactExeNames = New-Object System.Collections.ArrayList
                foreach ($declaredExe in @($Game.GameExe, $Game.LaunchExe)) {
                    if (-not $declaredExe) { continue }
                    if (@($exactExeNames | Where-Object { $_ -ieq [string]$declaredExe }).Count -eq 0) {
                        [void]$exactExeNames.Add([string]$declaredExe)
                    }
                }
                foreach ($declaredExe in $exactExeNames) {
                    $resolvedExeRoot = $null
                    if (Test-Path -LiteralPath (Join-Path $picked $declaredExe) -PathType Leaf) {
                        $resolvedExeRoot = $picked
                    } else {
                        $rg = Resolve-LocatedRoot -Picked $picked -RelFile $declaredExe
                        if ($rg) {
                            $resolvedExeRoot = $rg
                        }
                    }
                    if (-not $resolvedExeRoot) { continue }
                    $picked = $resolvedExeRoot
                    $gameHit = $true
                    $isDeclaredVrLauncher = ($Game.LaunchExe -and ([string]$declaredExe -ieq [string]$Game.LaunchExe))
                    $noDifferentVrLauncher = (-not $Game.LaunchExe -or ([string]$Game.GameExe -ieq [string]$Game.LaunchExe))
                    if (-not $Game.TwoMods -and -not $Game.VrInstallRoot -and ($isDeclaredVrLauncher -or $noDifferentVrLauncher)) {
                        $chosenExe = Join-Path $resolvedExeRoot $declaredExe
                    }
                    break
                }
                if (-not $gameHit) {
                    $exeCands = @()
                    try {
                        $exeCands = @(Get-ChildItem -LiteralPath $picked -Filter *.exe -File -ErrorAction SilentlyContinue |
                            Where-Object { $_.Name -notmatch '(?i)(crashhandler|crashreport|vc_redist|vcredist|dxsetup|directx|dotnet|notification_helper|unins|uninstall|_setup|installer|redist)' } |
                            Sort-Object Length -Descending |
                            Select-Object -ExpandProperty FullName)
                    } catch {}
                    $cand = $null
                    if ($exeCands.Count -eq 1) { $cand = $exeCands[0] }
                    elseif ($exeCands.Count -gt 1) { $cand = Show-ExePicker -Exes $exeCands -Title $Game.Title }
                    if ($cand) {
                        $gameHit = $true
                        if (-not $Game.TwoMods -and -not $Game.VrInstallRoot) { $chosenExe = $cand }
                    }
                }
            }

            # ---- Assign the VR launcher for the located install ----
            # When the mod is found (Plan A) Start-in-VR launches via the
            # recorded .installed_path + LaunchExe. That works directly
            # when the LaunchExe sits at the root (the common case). If it
            # instead lives in a subfolder, resolve it (no prompt) and
            # store it as the override so the right exe still runs. Plan B
            # already set $chosenExe from its scan/pick. TwoMods launch
            # per-mod and VrInstallRoot launch from their own root, so
            # both skip a single-exe override.
            if (-not $chosenExe -and $Game.LaunchExe -and -not $Game.TwoMods -and -not $Game.VrInstallRoot) {
                if (-not (Test-Path -LiteralPath (Join-Path $picked $Game.LaunchExe))) {
                    $rl = Resolve-LocatedRoot -Picked $picked -RelFile $Game.LaunchExe
                    if ($rl) { $chosenExe = Join-Path $rl $Game.LaunchExe }
                }
            }

            # A strict base-game proof outranks third-party VR files. GTA V
            # uses this to reject a tiny remnant folder after the actual game
            # was removed; such a folder must never be saved as installed.
            if (($modHit -or $gameHit) -and (Get-Command Test-BaseGameInstallProof -ErrorAction SilentlyContinue) -and
                -not (Test-BaseGameInstallProof -Game $Game -Root $picked)) {
                [System.Windows.Forms.MessageBox]::Show(
                    ('VR mod leftovers were found, but the required base-game files are missing in:' + "`r`n" + $picked + "`r`n`r`nReinstall or locate the complete game first."),
                    'Base game not installed') | Out-Null
                return
            }

            # ---- Last resort: nothing found at all ----
            # (VrInstallRoot titles are exempt - their base game folder
            # legitimately holds neither the mod nor the launcher.)
            if (-not $modHit -and -not $gameHit -and -not $Game.VrInstallRoot) {
                $ask = [System.Windows.Forms.MessageBox]::Show(
                    ('No ' + $modLabel + ' or game files found in:' + "`r`n" + $picked + "`r`n`r`nLink this folder anyway so " + $Game.Title + " shows as installed? You can add the VR mod later."),
                    "Locate Game",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo)
                if ($ask -ne [System.Windows.Forms.DialogResult]::Yes) { return }
            }

            if (-not (Get-HubGameStateId -Game $Game)) {
                [System.Windows.Forms.MessageBox]::Show("This title cannot store a located path.", "Locate Game") | Out-Null
                return
            }
            Write-PersistentGameStateValue -Game $Game -Name 'installed_path' -Value $picked
            $savedPath = Read-PersistentGameStateValue -Game $Game -Name 'installed_path'
            if ([string]$savedPath -cne [string]$picked) {
                throw 'The selected game folder could not be saved and verified.'
            }

            # Revive games (e.g. Quake 2 VR): "Start in VR" routes through
            # ReviveInjector.exe only when a ".revive_launch" marker sits
            # in the folder. The installer normally drops it, but a located
            # install may lack it. Write it - ONLY if absent, so we never
            # clobber an existing setup - pointing at the injector, exactly
            # like the installer (found path, else the documented default).
            # Safe for Oculus-direct users too: if no injector is found at
            # launch time the Revive route falls through to a direct start.
            if ($Game.Revive) {
                try {
                    $rvMarker = Join-Path $picked ".revive_launch"
                    if (-not (Test-Path -LiteralPath $rvMarker)) {
                        $rvInj = $null
                        $rvCands = @(
                            (Join-Path $env:ProgramFiles "Revive\ReviveInjector.exe"),
                            (Join-Path $env:ProgramFiles "Revive\Revive\ReviveInjector.exe")
                        )
                        $pf86 = ${env:ProgramFiles(x86)}
                        if ($pf86) { $rvCands += (Join-Path $pf86 "Revive\ReviveInjector.exe") }
                        foreach ($c in $rvCands) { if (Test-Path $c) { $rvInj = $c; break } }
                        if (-not $rvInj) { $rvInj = Join-Path $env:ProgramFiles "Revive\ReviveInjector.exe" }
                        Set-Content -Path $rvMarker -Value $rvInj -Encoding ASCII -Force
                    }
                } catch {}
            }

            # Store the launch override from the exe we found/picked in
            # Plan B (or a subfolder-resolved LaunchExe). TwoMods and
            # VrInstallRoot games are intentionally excluded - they launch
            # per-mod or from their own VR root, so a single-exe override
            # would be wrong - and $chosenExe is never set for them above.
            if ($chosenExe -and -not $Game.TwoMods -and -not $Game.VrInstallRoot) {
                Write-PersistentGameStateValue -Game $Game -Name 'launch_exe' -Value $chosenExe
                $savedLaunch = Read-PersistentGameStateValue -Game $Game -Name 'launch_exe'
                if ([string]$savedLaunch -cne [string]$chosenExe) {
                    throw 'The selected game executable could not be saved and verified.'
                }
            }

            # Mark this as user-located so the detail page offers
            # Re-locate / Clear instead of the one-shot Locate button.
            # This is canonical LocalAppData state; the only Hub-side copy is
            # the checksummed Core\UserData backup. Read it back before the UI
            # says Success; a failed durable write must never look completed.
            Write-PersistentGameStateValue -Game $Game -Name 'user_located' -Value $picked
            $savedLocated = Read-PersistentGameStateValue -Game $Game -Name 'user_located'
            if ([string]$savedLocated -cne [string]$picked) {
                throw 'The located-game recovery marker could not be saved and verified.'
            }

            # A LOCATED ENTRY MAY BE MISSING ITS LAUNCHER (2026-08-20).
            # Entries whose LaunchExe is a batch file the installer writes
            # can end up without it - located by hand, or installed before
            # that launcher existed. Saying so HERE, once and plainly, is
            # far better than letting "Start in VR" fail later.
            try {
                if ($Game.LaunchExe -and $Game.LaunchExe -like "*.bat" -and $Game.VrInstallRoot) {
                    $lr = $Game.VrInstallRoot
                    if     ($lr -like "LOCALAPPDATA:*") { $lr = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) ($lr.Substring("LOCALAPPDATA:".Length)) }
                    elseif ($lr -like "APPDATA:*")      { $lr = Join-Path ([Environment]::GetFolderPath("ApplicationData"))      ($lr.Substring("APPDATA:".Length)) }
                    elseif ($lr -like "PROGRAMDATA:*")  { $lr = Join-Path ([Environment]::GetFolderPath("CommonApplicationData")) ($lr.Substring("PROGRAMDATA:".Length)) }
                    elseif ($lr -like "USERPROFILE:*")  { $lr = Join-Path ([Environment]::GetFolderPath("UserProfile"))           ($lr.Substring("USERPROFILE:".Length)) }
                    if ((Test-Path -LiteralPath $lr) -and -not (Test-Path -LiteralPath (Join-Path $lr $Game.LaunchExe))) {
                        [System.Windows.Forms.MessageBox]::Show(
                            ($Game.Title + " is linked, but the file that starts it is not there yet." + "`r`n`r`nRun the installer once from this page. It writes that file and leaves everything else as it is."),
                            "One more step") | Out-Null
                    }
                }
            } catch {}
            $global:PendingInstallTitle = $Game.Title
            Invoke-PostInstallRefreshSafely

            if ($modHit) {
                $msg = "Success - " + $modLabel + " found for " + $Game.Title + "." + "`r`n`r`nLocation:`r`n" + $picked + "`r`n`r`nIt will now show as VR Ready."
            } elseif ($gameHit) {
                $msg = "Success - " + $baseTitle + " installation found." + "`r`n`r`nLocation:`r`n" + $picked + "`r`n`r`nIt will show as installed. Install the VR mod to make it VR Ready."
            } else {
                $msg = $Game.Title + " linked to:`r`n" + $picked + "`r`n`r`nNo " + $modLabel + " detected yet; it will show VR Ready once the VR mod is installed."
            }
            [System.Windows.Forms.MessageBox]::Show($msg, "Locate Game") | Out-Null
        } catch {
            Write-HubActionFailure -Action ("Locate " + $Game.Title) -ErrorRecord $_
        }
    }.GetNewClosure())

    return $btn
}

# ---------------------------------------------------------------
#  Resolve-UninstallExe / New-UninstallNowButton
# ---------------------------------------------------------------
#  A SECOND button beside the uninstall guide, for the handful of
#  mods that ship an uninstaller of their own. Added 2026-08-20.
#
#  DELIBERATELY NARROW. The Hub never deletes anything itself here:
#  it starts what the mod author wrote, and nothing else. No file
#  lists, no .hubbak restores, no touching Steam launch options.
#  With 247 games, a wrongly emptied game folder is the one
#  mistake that cannot be taken back - so the automatic route only
#  exists where the author already solved it.
#
#  TWO CONDITIONS, BOTH REQUIRED, and the second one is the point:
#    1. the entry carries UninstallExe
#    2. that file is REALLY on disk right now
#  So the button cannot point at nothing - not on an uninstalled
#  game, not on a depot copy somewhere else, not after a half
#  finished removal. Everything without the field behaves exactly
#  as before.
#
#  THE PATH IS RESOLVED AGAINST THE INSTALL ROOT, not blindly
#  against the Steam folder: Battlefield 1942 keeps its uninstaller
#  in BFVR\, and World at War installs into its own program folder
#  entirely. Order: the path the installer recorded, then
#  VrInstallRoot, then the game folder.
function global:Resolve-UninstallActions {
    param($Game)

    if (-not $Game.UninstallExe) { return @() }
    $relativePaths = @($Game.UninstallExe | Where-Object { $_ })
    $labels = @($Game.UninstallLabel)
    $probes = @($Game.UninstallProbeFile)
    $targets = if ($Game.UninstallTargetMod) {
        @($Game.UninstallTargetMod)
    } elseif ($Game.UninstallTargetRoute) {
        @($Game.UninstallTargetRoute)
    } else {
        @()
    }
    $arguments = @($Game.UninstallArguments)
    $restrictToTargetRoots = @($Game.UninstallRestrictToDetectedMod)
    $requireProbes = @($Game.UninstallRequireProbe)

    $roots = @()
    # 1. The folder the scan resolved for this game - the same source
    #    the rest of the detail page uses.
    $st = $null
    try {
        $st = $global:gameStateMap[$Game.Title]
        if ($st -and $st.GameDir) { $roots += [string]$st.GameDir }
        foreach ($stateDir in @($st.CurrentDir, $st.DepotDir, $st.ModADir, $st.ModBDir, $st.ModCDir, $st.ModDDir, $st.ModEDir, $st.ModFDir, $st.ModGDir, $st.ModHDir)) {
            if ($stateDir) { $roots += [string]$stateDir }
        }
    } catch {}
    # 2. What the installer itself recorded, read straight from
    #    <Core>\<BatFolder>\.installed_path. Not via a helper: the one
    #    that reads this file lives in VRModHub.ps1 and is not global,
    #    so it is not reliably in scope here.
    try {
        if ($Game.Bat) {
            $batDir = ([string]$Game.Bat).Split('\')[0]
            $marker = "$global:scriptDir\$batDir\.installed_path"
            if (Test-Path -LiteralPath $marker) {
                $v = (Get-Content -LiteralPath $marker -Raw -ErrorAction SilentlyContinue)
                if ($v) { $roots += $v.Trim() }
            }
        }
    } catch {}
    # 3. A mod that installs into a place of its own. The catalog
    #    writes these with a prefix (LOCALAPPDATA: / APPDATA: /
    #    PROGRAMDATA:) - expanded exactly as Filter.ps1 does, so both
    #    read the same folder. World at War lives entirely under
    #    %LocalAppData%\Programs\World War VR, for instance.
    if ($Game.VrInstallRoot) {
        try {
            $vr = [string]$Game.VrInstallRoot
            if ($vr -like "LOCALAPPDATA:*") {
                $vr = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) ($vr.Substring("LOCALAPPDATA:".Length))
            } elseif ($vr -like "APPDATA:*") {
                $vr = Join-Path ([Environment]::GetFolderPath("ApplicationData")) ($vr.Substring("APPDATA:".Length))
            } elseif ($vr -like "PROGRAMDATA:*") {
                $vr = Join-Path ([Environment]::GetFolderPath("CommonApplicationData")) ($vr.Substring("PROGRAMDATA:".Length))
            }
            $roots += $vr
        } catch {}
    }

    # 4. The Hub's OWN installer folder. Some mods leave nothing in the
    #    game to uninstall - they live in a folder of their own - so the
    #    remover ships beside the installer instead. Without this root a
    #    Hub-side uninstaller could never be found.
    try {
        if ($Game.Bat) {
            $batDir2 = ([string]$Game.Bat).Split('\')[0]
            $roots += "$global:scriptDir\$batDir2"
        }
    } catch {}

    $actions = New-Object 'System.Collections.Generic.List[object]'
    $seen = @{}
    for ($index = 0; $index -lt $relativePaths.Count; $index++) {
        $rel = [string]$relativePaths[$index]
        if (-not $rel -or $rel -notmatch '(?i)\.(exe|bat|cmd)$') { continue }
        $label = if ($index -lt $labels.Count -and $labels[$index]) { [string]$labels[$index] } else { 'Uninstall now' }
        $probe = if ($index -lt $probes.Count -and $probes[$index]) { [string]$probes[$index] } elseif ($probes.Count -eq 1) { [string]$probes[0] } else { $null }
        $target = if ($index -lt $targets.Count -and $targets[$index]) { [string]$targets[$index] } else { $null }
        $argument = if ($index -lt $arguments.Count -and $arguments[$index]) { [string]$arguments[$index] } else { $null }
        $restrict = if ($index -lt $restrictToTargetRoots.Count) { [bool]$restrictToTargetRoots[$index] } elseif ($restrictToTargetRoots.Count -eq 1) { [bool]$restrictToTargetRoots[0] } else { $false }
        $requireProbe = if ($index -lt $requireProbes.Count) { [bool]$requireProbes[$index] } elseif ($requireProbes.Count -eq 1) { [bool]$requireProbes[0] } else { $false }
        $searchRoots = $roots
        if ($restrict -and $target -eq 'ModA') { $searchRoots = @($st.ModADir | Where-Object { $_ }) }
        if ($restrict -and $target -eq 'ModB') { $searchRoots = @($st.ModBDir | Where-Object { $_ }) }
        if ($restrict -and $target -match '^Mod[C-H]$') { $searchRoots = @((Get-AlternativeModValue $st ("${target}Dir")) | Where-Object { $_ }) }
        if ($restrict -and $target -eq 'Current') { $searchRoots = @($st.CurrentDir | Where-Object { $_ }) }
        if ($restrict -and $target -eq 'Depot') { $searchRoots = @($st.DepotDir | Where-Object { $_ }) }
        if ($restrict -and $target -eq 'LegacyDepot') {
            try { $searchRoots = @(Get-LegacyDepotCandidatePaths -Game $Game | Where-Object { $_ }) } catch { $searchRoots = @() }
        }
        if ($requireProbe) {
            $probePresent = $false
            foreach ($probeRoot in $searchRoots) {
                if (-not $probeRoot) { continue }
                foreach ($oneProbe in @($probe -split '\|')) {
                    if ($oneProbe -and (Test-Path -LiteralPath "$(([string]$probeRoot).TrimEnd('\'))\$oneProbe")) { $probePresent = $true; break }
                }
                if ($probePresent) { break }
            }
            if (-not $probePresent) { continue }
        }
        foreach ($r in $searchRoots) {
            if (-not $r) { continue }
            # String concatenation, not Join-Path: a dead drive letter
            # would make Join-Path throw (hub-wide rule).
            $full = "$($r.TrimEnd('\'))\$rel"
            $actionKey = $full + "`n" + $argument
            if ((Test-Path -LiteralPath $full -PathType Leaf) -and -not $seen.ContainsKey($actionKey)) {
                $seen[$actionKey] = $true
                [void]$actions.Add([pscustomobject]@{
                    Path=$full; Label=$label; ProbeFile=$probe
                    TargetMod=$target; Arguments=$argument
                })
                break
            }
        }
    }
    return $actions.ToArray()
}

# Backwards-compatible scalar helper used by installer-flow tests and any
# older call site. The detail page itself consumes every resolved action.
function global:Resolve-UninstallExe {
    param($Game)
    $actions = @(Resolve-UninstallActions -Game $Game)
    if ($actions.Count) { return [string]$actions[0].Path }
    return $null
}

# Build the state shown before a two-mod removal. This is deliberately a pure
# helper: the same data drives the dialog and the regression tests, so a tile
# can never claim that a missing remover is available.
function global:Get-TwoModUninstallChoices {
    param($Game, [object[]]$Actions, $State = $null)

    if (-not $State) {
        try { $State = $global:gameStateMap[$Game.Title] } catch {}
    }
    $result = New-Object 'System.Collections.Generic.List[object]'
    foreach ($definition in @(Get-AlternativeModDefinitions -Game $Game -State $State)) {
        $mode = [string]$definition.Mode
        $name = [string]$definition.Name
        $installed = [bool]$definition.Present
        $action = @($Actions | Where-Object { $_.TargetMod -eq $mode } | Select-Object -First 1)
        $oneAction = if ($action.Count) { $action[0] } else { $null }
        $removable = [bool]($installed -and $oneAction)
        $status = if ($removable) {
            'INSTALLED - can remove now'
        } elseif ($installed) {
            'INSTALLED - no verified automatic uninstaller found'
        } else {
            'not detected'
        }
        [void]$result.Add([pscustomobject]@{
            Mode=$mode; Name=$name; Installed=$installed
            Removable=$removable; Status=$status; Action=$oneAction
        })
    }
    return $result.ToArray()
}

function global:Select-TwoModUninstallAction {
    param($Game, [object[]]$Choices)

    $a = @($Choices | Where-Object Mode -eq 'ModA' | Select-Object -First 1)[0]
    $b = @($Choices | Where-Object Mode -eq 'ModB' | Select-Object -First 1)[0]
    $c = @($Choices | Where-Object Mode -eq 'ModC' | Select-Object -First 1)[0]
    $lines = @(
        "Choose which VR mod to remove from $($Game.Title):",
        '',
        "A - $($a.Name): $($a.Status)",
        "B - $($b.Name): $($b.Status)",
        ''
    )
    if ($c) { $lines = @($lines[0], $lines[1], $lines[2], $lines[3], "C - $($c.Name): $($c.Status)", '') }
    $removable = @($Choices | Where-Object Removable)
    if ($Choices.Count -gt 2 -and $removable.Count -gt 0) {
        # MessageBox cannot label three choices. A small native WPF chooser
        # says exactly what each button removes and never overloads Yes/No.
        $window = New-Object System.Windows.Window
        $window.Title = 'Uninstall VR mod'
        $window.Width = 470; $window.SizeToContent = [System.Windows.SizeToContent]::Height
        $window.ResizeMode = [System.Windows.ResizeMode]::NoResize
        $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterOwner
        try { if ($global:window) { $window.Owner = $global:window } } catch {}
        $window.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#15171a')
        $panel = New-Object System.Windows.Controls.StackPanel
        $panel.Margin = [System.Windows.Thickness]::new(18)
        $heading = New-Object System.Windows.Controls.TextBlock
        $heading.Text = "Choose which VR mod to remove from $($Game.Title):"
        $heading.FontSize = 14; $heading.FontWeight = [System.Windows.FontWeights]::SemiBold
        $heading.Foreground = [System.Windows.Media.Brushes]::White
        $heading.Margin = [System.Windows.Thickness]::new(0,0,0,12)
        $panel.Children.Add($heading) | Out-Null
        $script:selectedAlternativeUninstall = $null
        foreach ($choice in $Choices) {
            $button = New-Object System.Windows.Controls.Button
            $button.Content = "$($choice.Name) - $($choice.Status)"
            $button.Tag = $choice
            $button.HorizontalContentAlignment = [System.Windows.HorizontalAlignment]::Left
            $button.Padding = [System.Windows.Thickness]::new(10,7,10,7)
            $button.Margin = [System.Windows.Thickness]::new(0,0,0,7)
            $button.IsEnabled = [bool]$choice.Removable
            $button.Add_Click({
                $script:selectedAlternativeUninstall = $this.Tag.Action
                $window.DialogResult = $true
                $window.Close()
            }.GetNewClosure())
            $panel.Children.Add($button) | Out-Null
        }
        $cancel = New-Object System.Windows.Controls.Button
        $cancel.Content = 'Cancel'; $cancel.IsCancel = $true
        $cancel.Padding = [System.Windows.Thickness]::new(10,7,10,7)
        $cancel.Margin = [System.Windows.Thickness]::new(0,5,0,0)
        $panel.Children.Add($cancel) | Out-Null
        $window.Content = $panel
        [void]$window.ShowDialog()
        return $script:selectedAlternativeUninstall
    }
    if ($removable.Count -eq 2) {
        $lines += "Yes removes A - $($a.Name).`nNo removes B - $($b.Name).`nCancel changes nothing."
        $answer = [System.Windows.MessageBox]::Show(
            ($lines -join "`n"), 'Uninstall VR mod',
            [System.Windows.MessageBoxButton]::YesNoCancel,
            [System.Windows.MessageBoxImage]::Question)
        if ($answer -eq [System.Windows.MessageBoxResult]::Yes) { return $a.Action }
        if ($answer -eq [System.Windows.MessageBoxResult]::No)  { return $b.Action }
        return $null
    }
    if ($removable.Count -eq 1) {
        $only = $removable[0]
        $lines += "OK removes $($only.Name).`nCancel changes nothing."
        $answer = [System.Windows.MessageBox]::Show(
            ($lines -join "`n"), 'Uninstall VR mod',
            [System.Windows.MessageBoxButton]::OKCancel,
            [System.Windows.MessageBoxImage]::Question)
        if ($answer -eq [System.Windows.MessageBoxResult]::OK) { return $only.Action }
    }
    return $null
}

function global:Invoke-ResolvedUninstallAction {
    param($Game, $Action)

    if (-not $Action -or -not $Action.Path) { return }
    try {
        $startArgs = @{
            FilePath=[string]$Action.Path
            WorkingDirectory=(Split-Path ([string]$Action.Path) -Parent)
            PassThru=$true; Wait=$true; ErrorAction='Stop'
        }
        if ($Action.Arguments) { $startArgs.ArgumentList = [string]$Action.Arguments }
        $null = Start-Process @startArgs
    } catch {
        [System.Windows.MessageBox]::Show(
            "Could not start the uninstaller:`n$($_.Exception.Message)",
            'Uninstall', [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    # Exactly the same scope-respecting refresh used after an installer:
    # a user who already ran Scan games gets a coherent full re-scan;
    # otherwise only the game whose uninstaller just closed is rechecked.
    # Cancellation is safe too: the recheck simply finds the marker again.
    $global:PendingInstallTitle = $Game.Title
    Invoke-PostInstallRefreshSafely
}

function global:New-UninstallNowButton {
    param(
        $Game,
        [string]$ExePath,
        [string]$Label = 'Uninstall now',
        [string]$ProbeFile = $null,
        [string]$Arguments = $null,
        [object[]]$Choices = $null,
        [string]$AccentHex = "#e07a63"
    )

    $accent = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)

    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius  = [System.Windows.CornerRadius]::new(4)
    $btn.Padding       = [System.Windows.Thickness]::new(10, 6, 10, 6)
    $btn.Margin        = [System.Windows.Thickness]::new(8, 8, 0, 0)
    $btn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    # NO fixed height on purpose. The guide button beside it and the
    # Steam Theatre button both measure themselves, and pinning a number
    # here once made all three SHRINK - padding 6+6, border 1.5*2 and a
    # 12pt line come to about 31 px, not the 29 that was pinned.
    # Both buttons carry the same padding, border, icon box and font
    # size, so left to measure themselves they come out identical.
    $btn.Cursor = [System.Windows.Input.Cursors]::Hand
    # Slightly stronger than the guide beside it: the guide stays the
    # quiet default, this one is the shortcut.
    $fill = [System.Windows.Media.Color]::FromArgb([byte]46, $accent.Color.R, $accent.Color.G, $accent.Color.B)
    $btn.Background = New-Object System.Windows.Media.SolidColorBrush $fill
    $bord = [System.Windows.Media.Color]::FromArgb([byte]200, $accent.Color.R, $accent.Color.G, $accent.Color.B)
    $btn.BorderBrush     = New-Object System.Windows.Media.SolidColorBrush $bord
    $btn.BorderThickness = [System.Windows.Thickness]::new(1.5)
    # A REAL hover panel, built like the guide's: the plain string
    # tooltip it had before barely showed, so beside a button that
    # opens a full panel this one looked like it did nothing on hover.
    $tt = New-Object System.Windows.Controls.ToolTip
    $tt.Background = [System.Windows.Media.Brushes]::Transparent
    $tt.BorderThickness = [System.Windows.Thickness]::new(0)
    $tt.Padding = [System.Windows.Thickness]::new(0)
    $ttOuter = New-Object System.Windows.Controls.Border
    $ttOuter.Background   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#15171a")
    $ttOuter.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $ttOuter.Padding      = [System.Windows.Thickness]::new(8)
    $ttInner = New-Object System.Windows.Controls.Border
    $ttInner.Background   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1f2227")
    $ttInner.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $ttInner.Padding      = [System.Windows.Thickness]::new(14, 12, 14, 12)
    $ttInner.MinWidth = 300; $ttInner.MaxWidth = 420
    $ttStack = New-Object System.Windows.Controls.StackPanel
    $ttHead = New-Object System.Windows.Controls.TextBlock
    $ttHead.Text = if ($Choices) { 'Choose which installed VR mod to remove' } else { 'Run the uninstaller that came with the mod' }
    $ttHead.FontSize = 13
    $ttHead.FontWeight = [System.Windows.FontWeights]::SemiBold
    $ttHead.Foreground = [System.Windows.Media.Brushes]::White
    $ttHead.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $ttHead.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    $ttStack.Children.Add($ttHead) | Out-Null
    $ttBody = New-Object System.Windows.Controls.TextBlock
    $ttBody.Text = if ($Choices) { 'The Hub first shows every mod, its installed state and which verified remover is available. You then choose one; Cancel changes nothing.' } else { 'It removes what it installed and nothing else. Your saves are not touched, and the Hub checks afterwards whether the mod is really gone.' }
    $ttBody.FontSize = 12
    $ttBody.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#b9bdc4")
    $ttBody.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $ttBody.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $ttBody.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    $ttStack.Children.Add($ttBody) | Out-Null
    $ttPath = New-Object System.Windows.Controls.TextBlock
    $ttPath.Text = if ($Choices) {
        (@($Choices | ForEach-Object { "$($_.Name): $($_.Status)" }) -join "`n")
    } else { $ExePath }
    $ttPath.FontSize = 11
    $ttPath.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $ttPath.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9fd8b0")
    $ttPath.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $ttStack.Children.Add($ttPath) | Out-Null

    # UAC LINE, ONLY FOR AN .exe. The Inno uninstallers (Sons of the
    # Forest, Battlefield 1942, World at War) carry a manifest asking
    # for administrator rights, so Windows raises its prompt the moment
    # they start - and an unexpected UAC dialog looks like something
    # went wrong. A .bat uninstaller like AWAY VR's does not ask, so
    # saying it there would be wrong.
    if ($ExePath -match '(?i)\.exe$') {
        $ttUac = New-Object System.Windows.Controls.TextBlock
        $ttUac.Text = "Windows will ask for administrator rights - that prompt comes from the uninstaller itself."
        $ttUac.FontSize = 12
        $ttUac.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e0b060")
        $ttUac.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $ttUac.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $ttUac.Margin = [System.Windows.Thickness]::new(0, 8, 0, 0)
        $ttStack.Children.Add($ttUac) | Out-Null
    }

    $ttInner.Child = $ttStack
    $ttOuter.Child = $ttInner
    $tt.Content = $ttOuter
    $btn.ToolTip = $tt
    [System.Windows.Controls.ToolTipService]::SetInitialShowDelay($btn, 200)
    [System.Windows.Controls.ToolTipService]::SetShowDuration($btn, 600000)
    # The panel is closed again on leave, exactly as the guide button
    # does it - without this a panel opened by hover can stay behind
    # when the pointer moves on.
    $ttRef = $tt
    $btn.Add_MouseLeave({
        try { if ($ttRef.IsOpen) { $ttRef.IsOpen = $false } } catch { }
    }.GetNewClosure())

    $row = New-Object System.Windows.Controls.StackPanel
    $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal

    # Play triangle in a 13x13 box - the SAME box size the guide
    # button uses for its trash can. Without it the icon is only 10 px
    # tall, the whole row sits lower, and the button reads as smaller
    # than its neighbour even though padding and font match exactly.
    $iconBox = New-Object System.Windows.Controls.Grid
    $iconBox.Width = 13; $iconBox.Height = 13
    $iconBox.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $iconBox.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
    $tri = New-Object System.Windows.Shapes.Polygon
    $tri.Points = New-Object System.Windows.Media.PointCollection
    $tri.Points.Add((New-Object System.Windows.Point(0, 0)))   | Out-Null
    $tri.Points.Add((New-Object System.Windows.Point(10, 5.5))) | Out-Null
    $tri.Points.Add((New-Object System.Windows.Point(0, 11)))  | Out-Null
    $tri.Fill = New-Object System.Windows.Media.SolidColorBrush $accent.Color
    $tri.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $tri.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $iconBox.Children.Add($tri) | Out-Null
    $row.Children.Add($iconBox) | Out-Null

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = $Label
    $lbl.FontSize = 12
    $lbl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $lblColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Min(255, $accent.Color.R + 30)),
        [byte]([Math]::Min(255, $accent.Color.G + 30)),
        [byte]([Math]::Min(255, $accent.Color.B + 30))
    )
    $lbl.Foreground = New-Object System.Windows.Media.SolidColorBrush $lblColor
    $lbl.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $row.Children.Add($lbl) | Out-Null
    $btn.Child = $row

    # SAME hover as the guide and theatre buttons beside it: 16 elements
    # in this file use Add-StandardHover, and it draws the lit ring plus
    # the sweep. Add-SoftHover, which stood here before, only recolours
    # TextBlocks - on a bordered pill it does nothing visible, which is
    # why this button felt dead on hover next to its neighbours.
    Add-StandardHover -Border $btn

    $gameTitle = [string]$Game.Title
    $modFileRel = [string]$Game.ModFile
    $probeRel   = if ($ProbeFile) { [string]$ProbeFile } elseif ($Game.UninstallProbeFile -and @($Game.UninstallProbeFile).Count -eq 1) { [string](@($Game.UninstallProbeFile)[0]) } else { $modFileRel }
    $singleAction = [pscustomobject]@{ Path=$ExePath; Label=$Label; ProbeFile=$probeRel; Arguments=$Arguments }
    $choicesCapture = $Choices
    $gameCapture = $Game

    $btn.Add_MouseLeftButtonUp({
        # NO CONFIRMATION DIALOG HERE. It used to repeat, word for word,
        # what the hover panel on this button already says - including
        # the full path. A second window that says the same thing twice
        # is not a safeguard, it is noise, and people learn to click it
        # away. The panel explains, the click decides.
        # The uninstallers themselves still ask: the Inno ones open with
        # their own "are you sure" prompt.
        $chosen = if ($choicesCapture) { Select-TwoModUninstallAction -Game $gameCapture -Choices $choicesCapture } else { $singleAction }
        if ($chosen) { Invoke-ResolvedUninstallAction -Game $gameCapture -Action $chosen }
    # .GetNewClosure() IS REQUIRED HERE, and its absence is why the
    # button reported "the argument cannot be bound to Path because it
    # is NULL". $exeCapture, $gameTitle and $probeRel are LOCAL to this
    # function; without the closure the handler runs later with none of
    # them set. Both neighbouring buttons capture both their handlers
    # the same way - a handler that reads a function-local variable
    # must close over it.
    }.GetNewClosure())

    return $btn
}

function global:New-UninstallGuideButton {
    param(
        $Game,
        [string]$AccentHex = "#cc6655",
        [Parameter(Mandatory=$true)][System.Windows.Controls.StackPanel]$HostPanel
    )

    $accent = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)

    $guideSize = $global:DetailTextSizes[$global:DetailSize]
    if (-not $guideSize) { $guideSize = $global:DetailTextSizes['M'] }

    # Heuristic: which games need a "clear Steam launch options"
    # step? Detected by the mod family / install pattern rather
    # than a per-game flag. Covers:
    #   - Luke Ross R.E.A.L. VR (37 titles, -eac_launcher)
    #   - Subnautica / Below Zero (SubmersedVR, -vrmode openvr)
    #   - Descenders, Dawn (-vrmode OpenVR)
    #   - Deep Rock Galactic (-overridenohmd -dx11)
    #   - Garry's Mod (autoexec config)
    #   - Lethal Company (custom launch line)
    $hasSteamArgs = $false
    if ($Game.Mod) {
        $m = $Game.Mod
        if ($m -match "R\.E\.A\.L\. VR") { $hasSteamArgs = $true }
        if ($m -match "SubmersedVR")     { $hasSteamArgs = $true }
        if ($m -match "DescendersVR")    { $hasSteamArgs = $true }
        if ($m -match "DawnVR")          { $hasSteamArgs = $true }
        if ($m -match "DRG[ -]?VRG")     { $hasSteamArgs = $true }
        if ($m -match "GModVR")          { $hasSteamArgs = $true }
        if ($m -match "LCVR")            { $hasSteamArgs = $true }
    }
    $isSteam = (-not $Game.Type -or $Game.Type -eq "steam")

    # Is this a self-contained C:\Games install rather than an in-place mod?
    # Quake builds and the depot titles install into their own folder under
    # C:\Games - they are NOT registered in Steam, so the "uninstall via
    # Steam" advice is wrong for them. To remove one you just delete the
    # folder; the original game (if owned) is never touched. Detected by a
    # C:\Games path in DepotPath or FallbackPaths.
    $standaloneFolderPath = $null
    if ($Game.DepotPath -and ($Game.DepotPath -match '[A-Za-z]:\\games\\')) {
        $standaloneFolderPath = $Game.DepotPath
    }
    if (-not $standaloneFolderPath -and $Game.FallbackPaths) {
        foreach ($fp in $Game.FallbackPaths) {
            if ($fp -match '^[A-Za-z]:\\games\\') { $standaloneFolderPath = $fp; break }
        }
    }
    $isStandaloneFolder = [bool]$standaloneFolderPath

    # User-provided games: the Hub layers a mod onto a copy of the game
    # that the user already owns and supplied. It never installed the
    # base game, so "uninstall via Steam" is wrong - to undo, you remove
    # the mod files from your own game folder. GTA V and NOLF2 each have
    # their own dedicated installer for this.
    $isGtaVr = ($Game.Title -eq "Grand Theft Auto V VR")
    $isNolf2 = ($Game.Title -eq "No One Lives Forever 2 VR")
    $isUserProvidedMod = ($isGtaVr -or $isNolf2)

    $tipOuter = New-Object System.Windows.Controls.Border
    $tipOuter.Background      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a1a24")
    $tipOuter.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
    $tipOuter.BorderThickness = [System.Windows.Thickness]::new(1)
    $tipOuter.CornerRadius    = [System.Windows.CornerRadius]::new(6)
    $tipOuter.Padding         = [System.Windows.Thickness]::new(8)
    $tipOuter.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $tipOuter.Tag = 'uninstall-guide'
    $guideMaxW = 720
    try {
        $guideHostWidth = if ($global:discoverDetail -and $global:discoverDetail.ActualWidth -gt 0) { $global:discoverDetail.ActualWidth } elseif ($global:window -and $global:window.ActualWidth -gt 0) { $global:window.ActualWidth } else { 0 }
        if ($guideHostWidth -gt 0) {
            $guideMaxW = [int]($guideHostWidth * 0.78)
            if ($guideMaxW -lt 720)  { $guideMaxW = 720 }
            if ($guideMaxW -gt 1040) { $guideMaxW = 1040 }
        }
    } catch {}
    $tipOuter.MaxWidth = $guideMaxW
    if ($null -ne $global:DetailWidthBlocks) { [void]$global:DetailWidthBlocks.Add($tipOuter) }

    $tipInner = New-Object System.Windows.Controls.Border
    $tipInner.Background   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1f2227")
    $tipInner.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $tipInner.Padding      = [System.Windows.Thickness]::new(14, 12, 14, 12)

    $tipStack = New-Object System.Windows.Controls.StackPanel
    $tipInner.Child = $tipStack

    # Header
    $tipHeader = New-Object System.Windows.Controls.TextBlock
    $tipHeader.Text = if ($isStandaloneFolder) { "How to remove this VR build" } else { "How to safely remove the VR mod" }
    $tipHeader.FontSize = [int]$guideSize.Font + 1
    $tipHeader.Tag = 'heading'
    $tipHeader.TextWrapping = 'Wrap'
    if ($null -ne $global:DetailReadmeTextBlocks) { [void]$global:DetailReadmeTextBlocks.Add($tipHeader) }
    $tipHeader.FontWeight = [System.Windows.FontWeights]::SemiBold
    $tipHeader.Foreground = [System.Windows.Media.Brushes]::White
    $tipHeader.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $tipHeader.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
    $tipStack.Children.Add($tipHeader) | Out-Null

    # Every path now goes through the safe guide builder. Its fallback removes
    # only verified mod markers and explicitly refuses to uninstall the base
    # game or delete the whole game folder. Catalog-specific guides still win,
    # except for legacy shared-loader boilerplate that could erase other mods.
    $steps = @(Get-SafeUninstallSteps -Game $Game -HasSteamArgs $hasSteamArgs -StandaloneFolderPath $standaloneFolderPath)

    $guideHint = New-Object System.Windows.Controls.TextBlock
    $guideHint.FontSize = $guideSize.Font
    $guideHint.LineHeight = $guideSize.LineHeight
    $guideHint.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#b8b8c7')
    $guideHint.TextWrapping = 'Wrap'
    $guideHint.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
    [void]$tipStack.Children.Add($guideHint)
    $guideShortcuts = New-Object System.Windows.Controls.TextBlock
    $guideShortcuts.FontSize = $guideSize.Font
    $guideShortcuts.LineHeight = $guideSize.LineHeight
    $guideShortcuts.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#b8b8c7')
    $guideShortcuts.TextWrapping = 'Wrap'
    $guideShortcuts.Margin = [System.Windows.Thickness]::new(0, 0, 0, 14)
    [void]$tipStack.Children.Add($guideShortcuts)
    if ($null -ne $global:DetailReadmeTextBlocks) {
        [void]$global:DetailReadmeTextBlocks.Add($guideHint)
        [void]$global:DetailReadmeTextBlocks.Add($guideShortcuts)
    }

    # Put the exact source used for version-specific removal instructions in
    # the guide itself. This is deliberately a web link, not a guessed local
    # path or a destructive action.
    $guideSourceUrl = Get-UninstallSourceUrl $Game
    if ($guideSourceUrl) {
        $guideSource = New-Object System.Windows.Controls.TextBlock
        $guideSource.FontSize = $guideSize.Font
        $guideSource.LineHeight = $guideSize.LineHeight
        $guideSource.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#b8b8c7')
        $guideSource.TextWrapping = 'Wrap'
        $guideSource.Margin = [System.Windows.Thickness]::new(0, 0, 0, 14)
        [void]$guideSource.Inlines.Add([System.Windows.Documents.Run]::new('Current author instructions: '))
        $sourceRun = [System.Windows.Documents.Run]::new('Open the linked mod page')
        $sourceLink = [System.Windows.Documents.Hyperlink]::new($sourceRun)
        $sourceLink.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
        $sourceLink.TextDecorations = [System.Windows.TextDecorations]::Underline
        $sourceUrlCapture = [string]$guideSourceUrl
        $sourceLink.ToolTip = $sourceUrlCapture
        $sourceLink.Add_Click({ try { Start-Process $sourceUrlCapture } catch {} }.GetNewClosure())
        [void]$guideSource.Inlines.Add($sourceLink)
        [void]$tipStack.Children.Add($guideSource)
        if ($null -ne $global:DetailReadmeTextBlocks) { [void]$global:DetailReadmeTextBlocks.Add($guideSource) }
    }
    $guideTextBlocks = New-Object 'System.Collections.Generic.List[object]'
    $stepIdx = 1
    foreach ($s in $steps) {
        $row = New-Object System.Windows.Controls.DockPanel
        $row.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)

        $num = New-Object System.Windows.Controls.Border
        $num.MinWidth = 24
        $num.Padding = [System.Windows.Thickness]::new(5, 0, 5, 0)
        [System.Windows.Controls.DockPanel]::SetDock($num, 'Left')
        $num.CornerRadius = [System.Windows.CornerRadius]::new(10)
        $num.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(60, $accent.Color.R, $accent.Color.G, $accent.Color.B))
        $num.Margin = [System.Windows.Thickness]::new(0, 0, 10, 0)
        $num.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $numTxt = New-Object System.Windows.Controls.TextBlock
        $numTxt.Text = "$stepIdx"
        $numTxt.FontSize = [int]$guideSize.Font - 2
        $numTxt.LineHeight = $guideSize.LineHeight
        $numTxt.Tag = 'guide-number'
        if ($null -ne $global:DetailReadmeTextBlocks) { [void]$global:DetailReadmeTextBlocks.Add($numTxt) }
        $numTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $numTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
        $numTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $numTxt.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
        $numTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $num.Child = $numTxt
        $row.Children.Add($num) | Out-Null

        $stepTxt = New-Object System.Windows.Controls.TextBlock
        $stepTxt.Text = $s
        $stepTxt.FontSize = $guideSize.Font
        $stepTxt.LineHeight = $guideSize.LineHeight
        $stepTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cccccc")
        $stepTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $stepTxt.TextWrapping = [System.Windows.TextWrapping]::Wrap
        [void]$guideTextBlocks.Add($stepTxt)
        if ($null -ne $global:DetailReadmeTextBlocks) { [void]$global:DetailReadmeTextBlocks.Add($stepTxt) }
        $row.Children.Add($stepTxt) | Out-Null

        $tipStack.Children.Add($row) | Out-Null
        $stepIdx++
    }

    # Footer removed - the steps stand on their own.

    $tipOuter.Child = $tipInner

    # The clickable button itself - same visual rhythm as the
    # Steam Theatre button (info icon + label, accent-tinted bg).
    $btn = New-Object System.Windows.Controls.Border
    $btn.CornerRadius  = [System.Windows.CornerRadius]::new(4)
    $btn.Padding       = [System.Windows.Thickness]::new(10, 6, 10, 6)
    $btn.Margin        = [System.Windows.Thickness]::new(0, 8, 0, 0)
    $btn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $btn.Cursor = [System.Windows.Input.Cursors]::Hand
    $tintFill = [System.Windows.Media.Color]::FromArgb([byte]30, $accent.Color.R, $accent.Color.G, $accent.Color.B)
    $btn.Background = New-Object System.Windows.Media.SolidColorBrush $tintFill
    $tintBorder = [System.Windows.Media.Color]::FromArgb([byte]160, $accent.Color.R, $accent.Color.G, $accent.Color.B)
    $btn.BorderBrush     = New-Object System.Windows.Media.SolidColorBrush $tintBorder
    $btn.BorderThickness = [System.Windows.Thickness]::new(1.5)

    $labelColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Min(255, $accent.Color.R + 30)),
        [byte]([Math]::Min(255, $accent.Color.G + 30)),
        [byte]([Math]::Min(255, $accent.Color.B + 30))
    )
    $labelBrush = New-Object System.Windows.Media.SolidColorBrush $labelColor

    $btnContent = New-Object System.Windows.Controls.StackPanel
    $btnContent.Orientation = [System.Windows.Controls.Orientation]::Horizontal

    # Trash-can icon - simple geometry: short top bar (lid) + body box
    $iconBox = New-Object System.Windows.Controls.Grid
    $iconBox.Width = 13; $iconBox.Height = 13
    $iconBox.Margin = [System.Windows.Thickness]::new(0, 0, 6, 0)
    $iconBox.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $iconLid = New-Object System.Windows.Shapes.Rectangle
    $iconLid.Width = 11; $iconLid.Height = 1.5
    $iconLid.Fill = $labelBrush
    $iconLid.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $iconLid.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    $iconLid.Margin = [System.Windows.Thickness]::new(0, 1, 0, 0)
    $iconBox.Children.Add($iconLid) | Out-Null
    $iconBody = New-Object System.Windows.Shapes.Rectangle
    $iconBody.Width = 8; $iconBody.Height = 9
    $iconBody.Stroke = $labelBrush
    $iconBody.StrokeThickness = 1.2
    $iconBody.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $iconBody.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
    $iconBox.Children.Add($iconBody) | Out-Null
    $btnContent.Children.Add($iconBox) | Out-Null

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Text = "Uninstall Guide"
    $lbl.FontSize = 12
    $lbl.FontWeight = [System.Windows.FontWeights]::Medium
    $lbl.Foreground = $labelBrush
    $lbl.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $lbl.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $btnContent.Children.Add($lbl) | Out-Null
    $btn.Child = $btnContent

    $chevron = New-Object System.Windows.Controls.TextBlock
    $chevron.Text = [char]0x25BE
    $chevron.Foreground = $labelBrush
    $chevron.FontSize = 14
    $chevron.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
    [void]$btnContent.Children.Add($chevron)
    $btn.Focusable = $true
    [System.Windows.Automation.AutomationProperties]::SetName($btn, 'Uninstall Guide, collapsed')

    $panelHost = New-Object System.Windows.Controls.Border
    $panelHost.Margin = [System.Windows.Thickness]::new(0, 8, 0, 14)
    $panelHost.Visibility = 'Collapsed'
    $panelHost.Child = $tipOuter
    [void]$HostPanel.Children.Add($panelHost)
    $guide = [pscustomobject]@{
        Game = $Game; Steps = $steps; TextBlocks = $guideTextBlocks
        Panel = $panelHost; Hint = $guideHint; Shortcuts = $guideShortcuts
    }
    $global:DetailUninstallGuide = $guide
    Update-UninstallGuideLinks -Guide $guide
    $toggle = {
        if ($guide.Panel.Visibility -eq 'Visible') {
            $guide.Panel.Visibility = 'Collapsed'
            $chevron.Text = [char]0x25BE
            [System.Windows.Automation.AutomationProperties]::SetName($btn, 'Uninstall Guide, collapsed')
        } else {
            $guide.Panel.Visibility = 'Visible'
            $chevron.Text = [char]0x25B4
            [System.Windows.Automation.AutomationProperties]::SetName($btn, 'Uninstall Guide, expanded')
            Update-UninstallGuideLinks -Guide $guide
        }
    }.GetNewClosure()
    $btn.Add_MouseLeftButtonUp({
        param($sender, $eventArgs)
        & $toggle
        $eventArgs.Handled = $true
    }.GetNewClosure())
    $btn.Add_KeyDown({
        param($sender, $eventArgs)
        if ($eventArgs.Key -in @([System.Windows.Input.Key]::Return, [System.Windows.Input.Key]::Space)) {
            & $toggle
            $eventArgs.Handled = $true
        }
    }.GetNewClosure())

    Add-StandardHover -Border $btn
    return $btn
}
