# Elden Ring uses one account save location for both the current Steam build
# and the pinned 1.16.2 depot. This module exposes the existing verified save
# manager as a compact, clickable control on the game detail page.

$script:EldenRingSaveUiManager = Join-Path (Split-Path -Parent $PSScriptRoot) "EldenRingVR\EldenRingSaveManager.ps1"
if (-not (Get-Command Get-EldenRingSaveState -ErrorAction SilentlyContinue)) {
    . $script:EldenRingSaveUiManager
}
$script:EldenRingSettingsHelper = Join-Path (Split-Path -Parent $PSScriptRoot) "EldenRingVR\EldenRingSettings.ps1"
if (-not (Get-Command Set-EldenRingHotbite3D -ErrorAction SilentlyContinue)) {
    . $script:EldenRingSettingsHelper
}

function global:Show-EldenRingSaveMessage {
    param(
        [string]$Text,
        [string]$Title = "Elden Ring save set",
        [System.Windows.MessageBoxButton]$Buttons = [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]$Icon = [System.Windows.MessageBoxImage]::Information
    )
    try {
        if ($global:window) { return [System.Windows.MessageBox]::Show($global:window, $Text, $Title, $Buttons, $Icon) }
    } catch {}
    return [System.Windows.MessageBox]::Show($Text, $Title, $Buttons, $Icon)
}

function global:Select-EldenRingHubListChoice {
    param(
        [string]$Title,
        [string]$Prompt,
        [object[]]$Choices,
        [string[]]$Labels
    )
    $items = @($Choices)
    if ($items.Count -eq 0) { return $null }
    if ($items.Count -eq 1) { return $items[0] }

    $dialog = New-Object System.Windows.Window
    $dialog.Title = $Title
    $dialog.Width = 460
    $dialog.Height = 190
    $dialog.ResizeMode = [System.Windows.ResizeMode]::NoResize
    $dialog.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterOwner
    $dialog.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#101018")
    try { if ($global:window) { $dialog.Owner = $global:window } } catch {}

    $root = New-Object System.Windows.Controls.StackPanel
    $root.Margin = [System.Windows.Thickness]::new(18)
    $dialog.Content = $root

    $promptText = New-Object System.Windows.Controls.TextBlock
    $promptText.Text = $Prompt
    $promptText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $promptText.FontSize = 13
    $promptText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e0e0e8")
    $promptText.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $promptText.Margin = [System.Windows.Thickness]::new(0, 0, 0, 12)
    [void]$root.Children.Add($promptText)

    $combo = New-Object System.Windows.Controls.ComboBox
    $combo.Height = 30
    $combo.FontSize = 13
    for ($i = 0; $i -lt $items.Count; $i++) {
        $label = if ($i -lt $Labels.Count -and $Labels[$i]) { [string]$Labels[$i] } else { [string]$items[$i] }
        [void]$combo.Items.Add($label)
    }
    $combo.SelectedIndex = 0
    [void]$root.Children.Add($combo)

    $buttons = New-Object System.Windows.Controls.StackPanel
    $buttons.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $buttons.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $buttons.Margin = [System.Windows.Thickness]::new(0, 14, 0, 0)
    [void]$root.Children.Add($buttons)

    $ok = New-Object System.Windows.Controls.Button
    $ok.Content = "Use selected"
    $ok.MinWidth = 110
    $ok.Padding = [System.Windows.Thickness]::new(10, 5, 10, 5)
    $cancel = New-Object System.Windows.Controls.Button
    $cancel.Content = "Cancel"
    $cancel.MinWidth = 80
    $cancel.Margin = [System.Windows.Thickness]::new(8, 0, 0, 0)
    $cancel.Padding = [System.Windows.Thickness]::new(10, 5, 10, 5)
    [void]$buttons.Children.Add($ok)
    [void]$buttons.Children.Add($cancel)

    $selection = @{ Value = $null }
    $dialogCap = $dialog; $comboCap = $combo; $itemsCap = $items; $selectionCap = $selection
    $ok.Add_Click({
        if ($comboCap.SelectedIndex -ge 0) {
            $selectionCap.Value = $itemsCap[$comboCap.SelectedIndex]
            $dialogCap.DialogResult = $true
        }
    }.GetNewClosure())
    $cancel.Add_Click({ $dialogCap.DialogResult = $false }.GetNewClosure())
    [void]$dialog.ShowDialog()
    return $selection.Value
}

function global:Get-EldenRingHubSaveRoot {
    $appData = [Environment]::GetFolderPath("ApplicationData")
    if ([string]::IsNullOrWhiteSpace($appData)) { $appData = $env:APPDATA }
    if ([string]::IsNullOrWhiteSpace($appData)) { return $null }
    return (Join-Path $appData "EldenRing")
}

function global:Get-EldenRingHubSaveDirectory {
    param([switch]$Interactive)
    $root = Get-EldenRingHubSaveRoot
    if (-not $root) { return $null }
    $accounts = @(Get-EldenRingSaveAccountDirectories -SaveRoot $root)
    if ($accounts.Count -eq 0) { return $null }
    if ($accounts.Count -eq 1) { return $accounts[0].FullName }
    if (-not $Interactive) { return $null }
    $picked = Select-EldenRingHubListChoice `
        -Title "Elden Ring Steam account" `
        -Prompt "Choose the Steam account whose Elden Ring save set should be active." `
        -Choices $accounts `
        -Labels @($accounts | ForEach-Object { "Steam account " + $_.Name })
    if ($picked) { return $picked.FullName }
    return $null
}

function global:Update-EldenRingSaveControl {
    param($Controls, [string]$SaveDirectory = "")
    if (-not $Controls) { return }
    if (-not $SaveDirectory -and $Controls.SaveDirectory) { $SaveDirectory = [string]$Controls.SaveDirectory }
    if (-not $SaveDirectory) { $SaveDirectory = Get-EldenRingHubSaveDirectory }
    if ($SaveDirectory) { $Controls.SaveDirectory = $SaveDirectory }

    $active = ""
    $status = "Start the game once"
    if ($SaveDirectory -and (Test-Path -LiteralPath $SaveDirectory -PathType Container)) {
        $state = Get-EldenRingSaveState -SaveDirectory $SaveDirectory
        $active = Resolve-EldenRingActiveSaveBuild -State $state
        if ($active -eq "Unknown") { $status = "Choose the active set" }
        elseif ($active -eq "Current") { $status = "Active: Current" }
        elseif ($active -eq "Depot") { $status = "Active: Depot 1.16.2" }
        else { $status = "No save yet" }
    } else {
        $root = Get-EldenRingHubSaveRoot
        if ($root -and @(Get-EldenRingSaveAccountDirectories -SaveRoot $root).Count -gt 1) { $status = "Choose Steam account" }
    }

    $gold = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#d8b45a")
    $gray = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#8b8b99")
    $clear = [System.Windows.Media.Brushes]::Transparent
    $segments = @(
        [pscustomobject]@{ Part = $Controls.CurrentPart; Text = $Controls.CurrentText; Build = "Current" }
        [pscustomobject]@{ Part = $Controls.DepotPart; Text = $Controls.DepotText; Build = "Depot" }
    )
    foreach ($segment in $segments) {
        $isActive = ($active -eq $segment.Build)
        $segment.Part.Background = if ($isActive) { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#332b18") } else { $clear }
        $segment.Text.Foreground = if ($isActive) { $gold } else { $gray }
        $segment.Text.FontWeight = if ($isActive) { [System.Windows.FontWeights]::Bold } else { [System.Windows.FontWeights]::SemiBold }
    }
    $Controls.Status.Text = $status
    $Controls.Status.Foreground = if ($active -in @("Current","Depot")) { $gold } else { $gray }
    $Controls.Active = $active
}

function global:Invoke-EldenRingHubSaveSelection {
    param(
        [Parameter(Mandatory=$true)][ValidateSet("Current","Depot")][string]$TargetBuild,
        $Controls
    )
    if (@(Get-Process -Name "eldenring", "start_protected_game" -ErrorAction SilentlyContinue).Count -gt 0) {
        [void](Show-EldenRingSaveMessage -Text "Close Elden Ring completely before changing its save set." -Icon Warning)
        return
    }

    $saveRoot = Get-EldenRingHubSaveRoot
    if (-not $saveRoot -or -not (Test-Path -LiteralPath $saveRoot -PathType Container)) {
        [void](Show-EldenRingSaveMessage -Text "No Elden Ring save was found. Start the game once, close it, then try again." -Icon Warning)
        return
    }
    $saveDirectory = if ($Controls.SaveDirectory) { [string]$Controls.SaveDirectory } else { Get-EldenRingHubSaveDirectory -Interactive }
    if (-not $saveDirectory) { return }
    $Controls.SaveDirectory = $saveDirectory

    $state = Get-EldenRingSaveState -SaveDirectory $saveDirectory
    if ($state.CurrentFiles.Count -eq 0) {
        $legacy = @(Get-EldenRingLegacySaveSets -SaveDirectory $saveDirectory)
        $legacySuffix = ""
        if ($legacy.Count -gt 1) {
            $pickedLegacy = Select-EldenRingHubListChoice `
                -Title "Older Elden Ring save sets" `
                -Prompt "Choose which older protected save belongs to the current Steam build." `
                -Choices $legacy `
                -Labels @($legacy | ForEach-Object { $_.Suffix })
            if (-not $pickedLegacy) { return }
            $legacySuffix = [string]$pickedLegacy.Suffix
        } elseif ($legacy.Count -eq 1) {
            $legacySuffix = [string]$legacy[0].Suffix
        }
        if ($legacySuffix -and -not (Import-EldenRingLegacyCurrentSave -SaveDirectory $saveDirectory -NoPrompt -SelectedLegacySuffix $legacySuffix)) {
            [void](Show-EldenRingSaveMessage -Text "The older protected save could not be imported safely." -Icon Error)
            return
        }
    }

    $state = Get-EldenRingSaveState -SaveDirectory $saveDirectory
    $active = Resolve-EldenRingActiveSaveBuild -State $state
    $assume = ""
    if ($active -eq "Unknown" -and $state.LiveFiles.Count -gt 0) {
        $answer = Show-EldenRingSaveMessage `
            -Text "Which build created the save that is active now?`n`nYes  = Current Steam build`nNo   = Depot 1.16.2`nCancel = change nothing" `
            -Buttons YesNoCancel -Icon Question
        if ($answer -eq [System.Windows.MessageBoxResult]::Cancel) { return }
        $assume = if ($answer -eq [System.Windows.MessageBoxResult]::Yes) { "Current" } else { "Depot" }
        $active = $assume
    }
    if ($active -eq "Unknown") {
        [void](Show-EldenRingSaveMessage -Text "The active save set is ambiguous. Nothing was changed." -Icon Warning)
        return
    }

    if ($active -and $active -ne $TargetBuild) {
        $fromLabel = if ($active -eq "Depot") { "Depot 1.16.2" } else { "Current" }
        $toLabel = if ($TargetBuild -eq "Depot") { "Depot 1.16.2" } else { "Current" }
        $confirm = Show-EldenRingSaveMessage `
            -Text "Switch the active save from $fromLabel to $toLabel?`n`nThe Hub makes and verifies a dated safety backup first." `
            -Buttons YesNo -Icon Question
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
    }

    $result = Invoke-EldenRingSaveSwitch -SaveDirectory $saveDirectory -TargetBuild $TargetBuild -AssumeLiveBuild $assume -NoPrompt
    if (-not $result.Success) {
        [void](Show-EldenRingSaveMessage -Text ("The save set was not changed.`n`n" + $result.Reason) -Icon Error)
        Update-EldenRingSaveControl -Controls $Controls -SaveDirectory $saveDirectory
        return
    }
    Update-EldenRingSaveControl -Controls $Controls -SaveDirectory $saveDirectory
    $targetLabel = if ($TargetBuild -eq "Depot") { "Depot 1.16.2" } else { "Current" }
    $done = "$targetLabel is ready."
    if ($result.Backup) { $done += "`n`nA verified dated backup was created." }
    [void](Show-EldenRingSaveMessage -Text $done -Icon Information)
}

function global:Get-EldenRingHubGameRoots {
    param($Game)
    $items = New-Object System.Collections.ArrayList
    $seen = @{}
    $add = {
        param([string]$Label, [string]$Path)
        if ([string]::IsNullOrWhiteSpace($Path)) { return }
        try {
            $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
            if (-not (Test-Path -LiteralPath (Join-Path $full 'Game\eldenring.exe') -PathType Leaf)) { return }
            $key = $full.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { return }
            $seen[$key] = $true
            [void]$items.Add([pscustomobject]@{ Label=$Label; Path=$full })
        } catch {}
    }

    $state = $null
    try { if ($Game -and $global:gameStateMap) { $state = $global:gameStateMap[$Game.Title] } } catch {}
    if ($state) {
        & $add 'Current' ([string]$state.CurrentDir)
        & $add 'Depot 1.16.2' ([string]$state.DepotDir)
        & $add 'Detected build' ([string]$state.GameDir)
        & $add 'Hotbite build' ([string]$state.ModARoot)
        & $add 'ERVR build' ([string]$state.ModBRoot)
    }
    try { if ($Game -and (Get-Command Read-InstalledPath -ErrorAction SilentlyContinue)) { & $add 'Last selected build' (Read-InstalledPath -Game $Game) } } catch {}
    if ($Game -and $Game.DepotPath) { & $add 'Depot 1.16.2' ([string]$Game.DepotPath) }
    try {
        if (Get-Command Find-SteamGameFolder -ErrorAction SilentlyContinue) {
            & $add 'Current' (Find-SteamGameFolder -AppId 1245620 -SteamFolderNames @('ELDEN RING') -ProbeExe 'Game\eldenring.exe')
        }
    } catch {}
    return @($items)
}

function global:Get-EldenRingSettingsCandidates {
    param([ValidateSet('Hotbite','ERVR')][string]$Kind, $Game)
    if ($Kind -eq 'Hotbite') {
        $local = [Environment]::GetFolderPath('LocalApplicationData')
        if (-not $local) { return @() }
        $modRoot = Join-Path $local 'Programs\Elden Ring VR Motion\mod'
        $found = @()
        foreach ($definition in @(
            @{ Label='Hotbite display / tuning'; Purpose='Display'; File='ervr-tuning.cfg' },
            @{ Label='Hotbite input mapping'; Purpose='Input'; File='ervr.cfg' }
        )) {
            $path = Join-Path $modRoot $definition.File
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                $found += [pscustomobject]@{ Label=$definition.Label; Purpose=$definition.Purpose; Path=$path }
            }
        }
        return @($found)
    }
    $found = @()
    foreach ($root in @(Get-EldenRingHubGameRoots -Game $Game)) {
        $path = Join-Path $root.Path 'Game\ERVR\ERVR.ini'
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $found += [pscustomobject]@{ Label=$root.Label; Path=$path }
        }
    }
    return @($found | Sort-Object Path -Unique)
}

function global:Select-EldenRingSettingsCandidate {
    param([ValidateSet('Hotbite','ERVR')][string]$Kind, $Game, [string]$Purpose='')
    $choices = @(Get-EldenRingSettingsCandidates -Kind $Kind -Game $Game)
    if ($Purpose) { $choices = @($choices | Where-Object { $_.Purpose -eq $Purpose }) }
    if ($choices.Count -eq 0) {
        [void](Show-EldenRingSaveMessage -Text "$Kind settings were not found. Install the mod first, then run Check Installed." -Title 'Elden Ring VR settings' -Icon Warning)
        return $null
    }
    if ($choices.Count -eq 1) { return $choices[0] }
    return Select-EldenRingHubListChoice `
        -Title 'Elden Ring VR settings' `
        -Prompt 'Choose which installed Elden Ring build you want to configure.' `
        -Choices $choices `
        -Labels @($choices | ForEach-Object { $_.Label + ' — ' + $_.Path })
}

function global:Open-EldenRingSettingsFile {
    param([ValidateSet('Hotbite','ERVR')][string]$Kind, $Game)
    $picked = Select-EldenRingSettingsCandidate -Kind $Kind -Game $Game
    if (-not $picked) { return }
    try {
        Start-Process -FilePath 'notepad.exe' -ArgumentList ('"' + $picked.Path + '"') | Out-Null
    } catch {
        [void](Show-EldenRingSaveMessage -Text ("Could not open the settings file.`n`n" + $_.Exception.Message) -Title 'Elden Ring VR settings' -Icon Error)
    }
}

function global:Set-EldenRingHub3DMode {
    param([ValidateSet('Hotbite','ERVR')][string]$Kind, $Game)
    $purpose = if ($Kind -eq 'Hotbite') { 'Display' } else { '' }
    $picked = Select-EldenRingSettingsCandidate -Kind $Kind -Game $Game -Purpose $purpose
    if (-not $picked) { return }
    $result = if ($Kind -eq 'Hotbite') {
        Set-EldenRingHotbite3D -Path $picked.Path
    } else {
        Set-EldenRingErvrFull3D -Path $picked.Path
    }
    if (-not $result.Success) {
        [void](Show-EldenRingSaveMessage -Text ("The 3D setting was not changed.`n`n" + $result.Reason) -Title 'Elden Ring VR display mode' -Icon Error)
        return
    }
    $label = if ($Kind -eq 'Hotbite') { 'Hotbite stereo 3D is enabled.' } else { 'ERVR Full 3D is enabled.' }
    if ($result.Backup) { $label += "`n`nThe previous settings file was backed up." }
    if ($Kind -eq 'ERVR') { $label += "`n`nRestart Elden Ring if it is already running." }
    [void](Show-EldenRingSaveMessage -Text $label -Title 'Elden Ring VR display mode' -Icon Information)
}

function global:Invoke-EldenRingDirectMotionLaunch {
    param(
        [Parameter(Mandatory=$true)][ValidateSet('Hotbite','ERVR')][string]$Kind,
        [Parameter(Mandatory=$true)][string]$GameDir
    )
    try {
        $gameExe = Join-Path $GameDir 'Game\eldenring.exe'
        if (-not (Test-Path -LiteralPath $gameExe -PathType Leaf)) { return $false }
        if ($Kind -eq 'ERVR') {
            if (-not (Test-Path -LiteralPath (Join-Path $GameDir 'Game\ERVR\ERVR.dll') -PathType Leaf)) { return $false }
            Start-Process -FilePath $gameExe -WorkingDirectory (Split-Path -Parent $gameExe) | Out-Null
            return $true
        }

        $hotRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Programs\Elden Ring VR Motion'
        $hotDll = Join-Path $hotRoot 'mod\eldenring_vr.dll'
        $me3 = Join-Path $hotRoot 'me3\bin\me3.exe'
        $profile = Join-Path $hotRoot 'eldenring-vr.me3'
        if (-not (Test-Path -LiteralPath $hotDll -PathType Leaf) -or
            -not (Test-Path -LiteralPath $me3 -PathType Leaf) -or
            -not (Test-Path -LiteralPath $profile -PathType Leaf)) { return $false }
        $psi = New-Object Diagnostics.ProcessStartInfo
        $psi.FileName = $me3
        $psi.WorkingDirectory = $hotRoot
        $psi.Arguments = 'launch --game eldenring --exe "' + $gameExe + '" --profile "' + $profile + '"'
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        [void][Diagnostics.Process]::Start($psi)
        return $true
    } catch { return $false }
}

function global:New-EldenRingMiniAction {
    param([string]$Text, [scriptblock]$Action, [string]$ToolTip='')
    $part = New-Object System.Windows.Controls.Border
    $part.CornerRadius = [System.Windows.CornerRadius]::new(5)
    $part.Padding = [System.Windows.Thickness]::new(9, 5, 9, 5)
    $part.Margin = [System.Windows.Thickness]::new(2, 0, 2, 0)
    $part.Cursor = [System.Windows.Input.Cursors]::Hand
    $part.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#1c1c25')
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = $Text
    $label.FontFamily = [System.Windows.Media.FontFamily]::new('Segoe UI')
    $label.FontSize = 12
    $label.FontWeight = [System.Windows.FontWeights]::SemiBold
    $label.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#c7c7d0')
    $part.Child = $label
    if ($ToolTip) { $part.ToolTip = $ToolTip }
    $part.Add_MouseLeftButtonUp($Action)
    $part.Add_MouseEnter({ $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#30303b') })
    $part.Add_MouseLeave({ $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#1c1c25') })
    return $part
}

function global:New-EldenRingSettingsControl {
    param($Game)
    $outer = New-Object System.Windows.Controls.Border
    $outer.CornerRadius = [System.Windows.CornerRadius]::new(7)
    $outer.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#13131a')
    $outer.BorderThickness = [System.Windows.Thickness]::new(1)
    $outer.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#343440')
    $outer.Padding = [System.Windows.Thickness]::new(12, 7, 12, 7)
    $row = New-Object System.Windows.Controls.StackPanel
    $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $row.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $outer.Child = $row

    foreach ($definition in @(
        @{ Label='VR MODE'; Dim=$true },
        @{ Label='Hotbite 3D'; Tip='Set global.vr_mono = 0 in Hotbite settings.'; Action={ Set-EldenRingHub3DMode -Kind Hotbite -Game $Game }.GetNewClosure() },
        @{ Label='ERVR Full 3D'; Tip='Set StereoMode=full in the selected ERVR installation.'; Action={ Set-EldenRingHub3DMode -Kind ERVR -Game $Game }.GetNewClosure() },
        @{ Label='EDIT'; Dim=$true },
        @{ Label='Hotbite config'; Tip='Choose Hotbite display/tuning or input mapping and open it in Notepad.'; Action={ Open-EldenRingSettingsFile -Kind Hotbite -Game $Game }.GetNewClosure() },
        @{ Label='ERVR config'; Tip='Open ERVR.ini for the selected Current or Depot installation.'; Action={ Open-EldenRingSettingsFile -Kind ERVR -Game $Game }.GetNewClosure() }
    )) {
        if ($definition.Dim) {
            $caption = New-Object System.Windows.Controls.TextBlock
            $caption.Text = $definition.Label
            $caption.FontSize = 10
            $caption.FontWeight = [System.Windows.FontWeights]::Bold
            $caption.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#737382')
            $caption.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $caption.Margin = [System.Windows.Thickness]::new($(if ($definition.Label -eq 'EDIT') { 12 } else { 0 }), 0, 8, 0)
            [void]$row.Children.Add($caption)
        } else {
            [void]$row.Children.Add((New-EldenRingMiniAction -Text $definition.Label -Action $definition.Action -ToolTip $definition.Tip))
        }
    }
    return $outer
}

function global:New-EldenRingSaveBuildControl {
    param($Game, [string]$AccentHex = "#d8b45a")
    $outer = New-Object System.Windows.Controls.Border
    $outer.CornerRadius = [System.Windows.CornerRadius]::new(7)
    $outer.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#13131a")
    $outer.BorderThickness = [System.Windows.Thickness]::new(1)
    $outer.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#343440")
    $outer.Padding = [System.Windows.Thickness]::new(12, 8, 12, 8)

    $row = New-Object System.Windows.Controls.StackPanel
    $row.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $row.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $outer.Child = $row

    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "SAVE SET"
    $label.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $label.FontSize = 10
    $label.FontWeight = [System.Windows.FontWeights]::Bold
    $label.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#737382")
    $label.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $label.Margin = [System.Windows.Thickness]::new(0, 0, 12, 0)
    [void]$row.Children.Add($label)

    $currentPart = New-Object System.Windows.Controls.Border
    $currentPart.CornerRadius = [System.Windows.CornerRadius]::new(5)
    $currentPart.Padding = [System.Windows.Thickness]::new(10, 5, 10, 5)
    $currentPart.Cursor = [System.Windows.Input.Cursors]::Hand
    $currentText = New-Object System.Windows.Controls.TextBlock
    $currentText.Text = "Current"
    $currentText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $currentText.FontSize = 13
    $currentPart.Child = $currentText
    [void]$row.Children.Add($currentPart)

    $separator = New-Object System.Windows.Controls.TextBlock
    $separator.Text = "/"
    $separator.FontSize = 13
    $separator.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#555562")
    $separator.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $separator.Margin = [System.Windows.Thickness]::new(4, 0, 4, 0)
    [void]$row.Children.Add($separator)

    $depotPart = New-Object System.Windows.Controls.Border
    $depotPart.CornerRadius = [System.Windows.CornerRadius]::new(5)
    $depotPart.Padding = [System.Windows.Thickness]::new(10, 5, 10, 5)
    $depotPart.Cursor = [System.Windows.Input.Cursors]::Hand
    $depotText = New-Object System.Windows.Controls.TextBlock
    $depotText.Text = "Depot 1.16.2"
    $depotText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $depotText.FontSize = 13
    $depotPart.Child = $depotText
    [void]$row.Children.Add($depotPart)

    $status = New-Object System.Windows.Controls.TextBlock
    $status.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $status.FontSize = 12
    $status.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $status.Margin = [System.Windows.Thickness]::new(14, 0, 0, 0)
    [void]$row.Children.Add($status)

    $controls = @{
        Root=$outer; CurrentPart=$currentPart; CurrentText=$currentText
        DepotPart=$depotPart; DepotText=$depotText; Status=$status
        SaveDirectory=""; Active=""
    }
    $controlsCap = $controls
    $currentPart.Add_MouseLeftButtonUp({ Invoke-EldenRingHubSaveSelection -TargetBuild Current -Controls $controlsCap }.GetNewClosure())
    $depotPart.Add_MouseLeftButtonUp({ Invoke-EldenRingHubSaveSelection -TargetBuild Depot -Controls $controlsCap }.GetNewClosure())
    foreach ($segment in @($currentPart, $depotPart)) {
        $segment.Add_MouseEnter({ $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a34") })
        $segment.Add_MouseLeave({ Update-EldenRingSaveControl -Controls $controlsCap }.GetNewClosure())
    }
    $outer.ToolTip = "Choose which Elden Ring build owns the live save. The Hub verifies a dated backup before every real switch. Close the game first."
    Update-EldenRingSaveControl -Controls $controls
    return $outer
}
