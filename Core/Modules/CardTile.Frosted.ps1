function global:New-GameCardFrosted {
    param($game, $isExternal, $window)
    $card = New-Object System.Windows.Controls.Border
    # Snap the entire card's layout to integer pixels. WPF renders
    # ClearType text blurry when an element lands on a sub-pixel X/Y,
    # which can happen anywhere the scaled ([int] * $sc) measurements
    # or nested panels (DockPanel/StackPanel) produce a non-integer
    # offset - the Daggerfall/Sonic "fuzzy title" symptom. Setting
    # this once on the card root makes it inherit to every child, so
    # we fix the whole class of blur at the source instead of patching
    # individual elements. It only rounds layout positions, not glyph
    # rasterization, so text keeps its normal weight.
    $card.UseLayoutRounding = $true
    # Cards are built ONCE at base size (1.0). The S/M/L size is applied
    # non-destructively via LayoutTransform in Apply-CardScale, so
    # changing size never rebuilds the list - it's instant and keeps the
    # current filter/visibility state.
    $sc = 1.0
    $card.Width  = [int](175 * $sc)
    $card.Height = [int](160 * $sc)
    $card.Margin = [System.Windows.Thickness]::new(0, 0, [int](12*$sc), [int](12*$sc))
    $card.CornerRadius = [System.Windows.CornerRadius]::new([int](8*$sc))

    # Accent color drives the card tint. Externals fall back to a
    # neutral gray-blue so the tinted look stays consistent.
    $accentHex = if ($game.Accent) { $game.Accent } elseif ($isExternal) { "#445566" } else { "#666677" }
    $card.Background = New-CardTintBrush -BaseHex "#0c0c10" -TintHex $accentHex -TopAlpha 0.10 -MidAlpha 0.02
    # Border picks up a darker variant of the tint so the card edge
    # also belongs to the family. We blend accent with base at ~22%.
    $bAcc  = ConvertTo-MediaColor $accentHex
    $bBase = ConvertTo-MediaColor "#0c0c10"
    $bMix  = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Round($bAcc.R*0.22 + $bBase.R*0.78)),
        [byte]([Math]::Round($bAcc.G*0.22 + $bBase.G*0.78)),
        [byte]([Math]::Round($bAcc.B*0.22 + $bBase.B*0.78))
    )
    $card.BorderThickness = [System.Windows.Thickness]::new(1)
    $card.BorderBrush = New-Object System.Windows.Media.SolidColorBrush $bMix
    $card.Cursor = [System.Windows.Input.Cursors]::Hand
    # Stash both for state-restore + hover handlers.
    # baseBgBrush/baseBdBrush get OVERWRITTEN by the update/ready
    # state painters so hover restores match the new state. The
    # "original" keys are immutable - they hold the colors the card
    # was first painted with, so the default branch (no install
    # detected) can revert cleanly even after multiple state cycles.
    foreach ($k in @("baseAccent","baseBgBrush","baseBdBrush","originalBgBrush","originalBdBrush","originalAccent")) {
        if ($card.Resources.Contains($k)) { $card.Resources.Remove($k) }
    }
    $card.Resources.Add("baseAccent",  $accentHex)
    $card.Resources.Add("baseBgBrush", $card.Background)
    $card.Resources.Add("baseBdBrush", $card.BorderBrush)
    $card.Resources.Add("originalBgBrush", $card.Background)
    $card.Resources.Add("originalBdBrush", $card.BorderBrush)
    $card.Resources.Add("originalAccent",  $accentHex)

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = [System.Windows.Thickness]::new([int](14*$sc))

    $r0 = New-Object System.Windows.Controls.RowDefinition; $r0.Height = [System.Windows.GridLength]::Auto
    $r1 = New-Object System.Windows.Controls.RowDefinition; $r1.Height = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $r2 = New-Object System.Windows.Controls.RowDefinition; $r2.Height = [System.Windows.GridLength]::Auto
    $grid.RowDefinitions.Add($r0)
    $grid.RowDefinitions.Add($r1)
    $grid.RowDefinitions.Add($r2)

    # Family pill: small accent-tinted label in the top-left of the
    # card. Replaces the previous 2px accent bar. Externals get a
    # neutral "External" label so they still get a pill at all.
    $famName = Get-ModFamily -Game $game -IsExternal $isExternal
    $famPill = New-Object System.Windows.Controls.Border
    $famPill.CornerRadius = [System.Windows.CornerRadius]::new([int](3*$sc))
    $famPill.Padding = [System.Windows.Thickness]::new([int](6*$sc), [int](2*$sc), [int](6*$sc), [int](2*$sc))
    $famPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $famPill.Margin = [System.Windows.Thickness]::new(0, 0, 0, [int](8*$sc))
    # Pill background: ~18% opacity of accent over base
    $famAcc = ConvertTo-MediaColor $accentHex
    $famBg  = ConvertTo-MediaColor "#16161a"
    $pillColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Round($famAcc.R*0.18 + $famBg.R*0.82)),
        [byte]([Math]::Round($famAcc.G*0.18 + $famBg.G*0.82)),
        [byte]([Math]::Round($famAcc.B*0.18 + $famBg.B*0.82))
    )
    $famPill.Background = New-Object System.Windows.Media.SolidColorBrush $pillColor
    # Pill text: lighter version of accent (mix accent with white at 50%)
    $famTxtColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Round($famAcc.R*0.5 + 255*0.5)),
        [byte]([Math]::Round($famAcc.G*0.5 + 255*0.5)),
        [byte]([Math]::Round($famAcc.B*0.5 + 255*0.5))
    )
    $famTxt = New-Object System.Windows.Controls.TextBlock
    $famTxt.Text = $famName.ToUpper()
    $famTxt.FontSize = [int](8*$sc)
    $famTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $famTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush $famTxtColor
    $famTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $famPill.Child = $famTxt
    # Cap the family badge so its right edge clears the top-right info pill
    # (it is colored + would bleed through the transparent pill). Card = 175*sc
    # wide, pill sits 8*sc from the card edge. VRGP/BOTH badges are the widest
    # (~80*sc), so their cap is tighter; single-glyph MC/GP pills leave more room.
    $famTxt.TextWrapping = [System.Windows.TextWrapping]::NoWrap
    $famPill.ClipToBounds = $true
    $__widePill = ($game.Controls -eq "VRGP" -or $game.Controls -eq "BOTH")
    $famPill.MaxWidth = if ($__widePill) { [int](68 * $sc) } else { [int](104 * $sc) }

    # Top stack holds pill + title group together in row 0
    $topStack = New-Object System.Windows.Controls.StackPanel
    $topStack.Orientation = [System.Windows.Controls.Orientation]::Vertical
    [System.Windows.Controls.Grid]::SetRow($topStack, 0)
    $topStack.Children.Add($famPill) | Out-Null
    $grid.Children.Add($topStack) | Out-Null
    # Stash family pill ref so the steam-preview manager can hide
    # it while the big image is shown (otherwise the pill covers
    # part of the artwork)
    $card.Resources.Add("famPill", $famPill)
    $isFreeGame = $global:FREE_GAME_TITLES -contains $game.Title
    $isWipGame  = $global:WIP_GAME_TITLES -contains $game.Title

    # Title stack (dot moved to overlay below i button)
    $titleStack = New-Object System.Windows.Controls.StackPanel
    $titleStack.Margin = [System.Windows.Thickness]::new(0, 0, 0, 0)
    $topStack.Children.Add($titleStack) | Out-Null

    $titleText = New-Object System.Windows.Controls.TextBlock
    # "Jedi Knight: Jedi Outcast VR" otherwise wraps with "VR" alone on
    # the second line. Glue "Outcast VR" together with a non-breaking
    # space so the break falls earlier ("...Jedi / Outcast VR"), matching
    # how the Academy tile reads. Scoped to this one title.
    $titleDisplay = $game.Title
    if ($titleDisplay -eq "Jedi Knight: Jedi Outcast VR") {
        $nbsp = [char]0x00A0
        $titleDisplay = "Jedi Knight: Jedi Outcast" + $nbsp + "VR"
    }
    elseif ($titleDisplay -in @("Assassin's Creed Valhalla VR",
                               "Assassin's Creed Odyssey VR",
                               "Assassin's Creed Mirage VR")) {
        # Same fix as the Jedi titles: "Assassin's Creed <Sub>" fits on
        # one line by a hair, so the wrap orphaned "VR" on line 2. Glue
        # "Assassin's Creed" AND "<Sub> VR" with non-breaking spaces so
        # the space between them is the ONLY break point left, giving
        # "Assassin's Creed" / "Mirage VR". Scoped to these titles.
        $nbsp = [char]0x00A0
        $sub = $titleDisplay.Substring("Assassin's Creed ".Length)
        $titleDisplay = "Assassin's" + $nbsp + "Creed " + $sub.Replace(" ", [string]$nbsp)
    }
    elseif ($titleDisplay -eq "Sonic Robo Blast 2 VR") {
        # Same NBSP idiom: force the break after "Sonic Robo" so the
        # tile reads "Sonic Robo" / "Blast 2 VR" instead of whatever
        # the greedy wrap happened to pick.
        $nbsp = [char]0x00A0
        $titleDisplay = "Sonic" + $nbsp + "Robo " + "Blast" + $nbsp + "2" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "No One Lives Forever 2 VR") {
        # Same fix: glue "Forever 2 VR" together with non-breaking spaces
        # so the wrap falls after "Lives" ("No One Lives" / "Forever 2 VR")
        # instead of orphaning "VR" on its own line. Scoped to this title.
        $nbsp = [char]0x00A0
        $titleDisplay = "No One Lives Forever" + $nbsp + "2" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Saints Row: The Third VR") {
        # Glue "The Third VR" together with non-breaking spaces so the only
        # break point left is after the colon ("Saints Row:" / "The Third VR")
        # instead of orphaning "VR" on its own line. Matches the Jedi titles.
        $nbsp = [char]0x00A0
        $titleDisplay = "Saints Row: The" + $nbsp + "Third" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Portal 2: Community Edition VR") {
        # Glue "Edition VR" together so "VR" never lands alone on line 2;
        # the title then wraps naturally to "Portal 2: Community" / "Edition VR".
        $nbsp = [char]0x00A0
        $titleDisplay = "Portal 2: Community Edition" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Horizon Forbidden West VR") {
        # Glue "West VR" together so the break falls after "Forbidden":
        # "Horizon Forbidden" / "West VR", matching the Jedi titles.
        $nbsp = [char]0x00A0
        $titleDisplay = "Horizon Forbidden West" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Panzer Dragoon Remake") {
        # Break after "Dragoon" and tag VR onto line 2: "Panzer Dragoon" / "Remake VR".
        $nbsp = [char]0x00A0
        $titleDisplay = "Panzer" + $nbsp + "Dragoon Remake" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Another Crab's Treasure") {
        # Break after "Crab's" and tag VR onto line 2: "Another Crab's" / "Treasure VR".
        $nbsp = [char]0x00A0
        $titleDisplay = "Another" + $nbsp + "Crab's Treasure" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Monster Hunter Rise VR") {
        # Break after "Hunter": "Monster Hunter" / "Rise VR".
        $nbsp = [char]0x00A0
        $titleDisplay = "Monster" + $nbsp + "Hunter Rise" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Monster Hunter Stories 3 VR") {
        # Break after "Hunter": "Monster Hunter" / "Stories 3 VR".
        $nbsp = [char]0x00A0
        $titleDisplay = "Monster" + $nbsp + "Hunter Stories" + $nbsp + "3" + $nbsp + "VR"
    }
    elseif ($titleDisplay -eq "Ratchet & Clank VR") {
        # Drop the trailing "VR" on the tile so the green FREE pill fits on
        # the title row. The full "Ratchet & Clank VR" stays everywhere else
        # (detail page, search, FREE list, tier map).
        $titleDisplay = "Ratchet & Clank"
    }
    elseif ($titleDisplay -eq "PowerSlave / Exhumed VR") {
        # The 20-character base title fills the tile's first line exactly.
        # Do not create a second line containing only the generic "VR" suffix;
        # the full catalog/detail title remains unchanged everywhere else.
        $titleDisplay = "PowerSlave / Exhumed"
    }
    $titleText.Text = $titleDisplay
    $titleText.FontSize = [int](13*$sc)
    # "Anomaly GAMMA" reads heavy because GAMMA is all-caps - drop it to
    # SemiBold so the all-caps word doesn't dominate the tile.
    $titleText.FontWeight = if ($game.Title -eq "Anomaly GAMMA") { [System.Windows.FontWeights]::SemiBold } else { [System.Windows.FontWeights]::Bold }
    $titleGrad = New-Object System.Windows.Media.LinearGradientBrush
    $titleGrad.StartPoint = [System.Windows.Point]::new(0, 0)
    $titleGrad.EndPoint   = [System.Windows.Point]::new(0, 1)
    $titleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(255,255,255), 0))) | Out-Null
    $titleGrad.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(168,176,186), 1))) | Out-Null
    $titleGrad.Freeze()
    $titleText.Foreground = $titleGrad
    $titleText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $titleText.TextWrapping = [System.Windows.TextWrapping]::Wrap
    # For free-to-play games, the title shares its row with a small
    # green "FREE" pill docked to the right. There's usually room here
    # because game titles aren't that long, and this keeps the family-
    # pill area at top clean. For paid games the title goes straight
    # into the titleStack as before.
    if ($isFreeGame) {
        $freePill = New-Object System.Windows.Controls.Border
        $freePill.CornerRadius = [System.Windows.CornerRadius]::new([int](2*$sc))
        $freePill.Padding = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
        $freePill.BorderThickness = [System.Windows.Thickness]::new(1)
        $freePill.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freePill.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(20, 52, 211, 153))
        $freePill.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $freePill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $freePill.Margin = [System.Windows.Thickness]::new([int](4*$sc), [int](1*$sc), 0, 0)
        $freeTxt = New-Object System.Windows.Controls.TextBlock
        $freeTxt.Text = "FREE"
        $freeTxt.FontSize = [int](8*$sc)
        $freeTxt.FontWeight = [System.Windows.FontWeights]::Bold
        $freeTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(52, 211, 153))
        $freeTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        # Lock the text box (vertical line box + centering) so the label
        # does not drift inside the pill when the tile re-lays out on hover
        # - same fix the ImprovementTag label uses.
        $freeTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $freeTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $freeTxt.TextAlignment = [System.Windows.TextAlignment]::Center
        $freeTxt.LineHeight = [double][int](10*$sc)
        $freeTxt.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
        $freePill.Child = $freeTxt
        $titleRow = New-Object System.Windows.Controls.DockPanel
        $titleRow.LastChildFill = $true
        $titleRow.UseLayoutRounding = $true
        $titleRow.SnapsToDevicePixels = $true
        [System.Windows.Controls.DockPanel]::SetDock($freePill, [System.Windows.Controls.Dock]::Right)
        $titleRow.Children.Add($freePill) | Out-Null
        # FREE and WIP are independent facts. A free game can still ship an
        # unfinished VR build, so dual-tag entries (currently Muck) display
        # both compact badges beside the title instead of FREE hiding WIP.
        if ($isWipGame) {
            $dualWipPill = New-Object System.Windows.Controls.Border
            $dualWipPill.CornerRadius = [System.Windows.CornerRadius]::new([int](2*$sc))
            $dualWipPill.Padding = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
            $dualWipPill.BorderThickness = [System.Windows.Thickness]::new(1)
            $dualWipPill.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(248, 113, 113))
            $dualWipPill.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(20, 248, 113, 113))
            $dualWipPill.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
            $dualWipPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
            $dualWipPill.Margin = [System.Windows.Thickness]::new([int](4*$sc), [int](1*$sc), 0, 0)
            $dualWipTxt = New-Object System.Windows.Controls.TextBlock
            $dualWipTxt.Text = "WIP"
            $dualWipTxt.FontSize = [int](8*$sc)
            $dualWipTxt.FontWeight = [System.Windows.FontWeights]::Bold
            $dualWipTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(248, 113, 113))
            $dualWipTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $dualWipTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $dualWipTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
            $dualWipTxt.TextAlignment = [System.Windows.TextAlignment]::Center
            $dualWipTxt.LineHeight = [double][int](10*$sc)
            $dualWipTxt.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
            $dualWipPill.Child = $dualWipTxt
            [System.Windows.Controls.DockPanel]::SetDock($dualWipPill, [System.Windows.Controls.Dock]::Right)
            $titleRow.Children.Add($dualWipPill) | Out-Null
        }
        $titleRow.Children.Add($titleText) | Out-Null
        $titleStack.Children.Add($titleRow) | Out-Null
    } elseif ($isWipGame) {
        # Same layout as the FREE pill, but a red "WIP" badge for mods
        # that run yet are still early / rough.
        $wipPill = New-Object System.Windows.Controls.Border
        $wipPill.CornerRadius = [System.Windows.CornerRadius]::new([int](2*$sc))
        $wipPill.Padding = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
        $wipPill.BorderThickness = [System.Windows.Thickness]::new(1)
        $wipPill.BorderBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(248, 113, 113))
        $wipPill.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(20, 248, 113, 113))
        $wipPill.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $wipPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $wipPill.Margin = [System.Windows.Thickness]::new([int](4*$sc), [int](1*$sc), 0, 0)
        $wipTxt = New-Object System.Windows.Controls.TextBlock
        $wipTxt.Text = "WIP"
        $wipTxt.FontSize = [int](8*$sc)
        $wipTxt.FontWeight = [System.Windows.FontWeights]::Bold
        $wipTxt.Foreground = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(248, 113, 113))
        $wipTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        # Lock the text box so the label does not drift inside the pill on
        # hover re-layout - same fix the ImprovementTag label uses.
        $wipTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $wipTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $wipTxt.TextAlignment = [System.Windows.TextAlignment]::Center
        $wipTxt.LineHeight = [double][int](10*$sc)
        $wipTxt.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
        $wipPill.Child = $wipTxt
        $titleRow = New-Object System.Windows.Controls.DockPanel
        $titleRow.LastChildFill = $true
        $titleRow.UseLayoutRounding = $true
        $titleRow.SnapsToDevicePixels = $true
        [System.Windows.Controls.DockPanel]::SetDock($wipPill, [System.Windows.Controls.Dock]::Right)
        $titleRow.Children.Add($wipPill) | Out-Null
        $titleRow.Children.Add($titleText) | Out-Null
        $titleStack.Children.Add($titleRow) | Out-Null
    } else {
        $titleStack.Children.Add($titleText) | Out-Null
    }

    # Auto-layout: measure the title's actual rendered width and use the
    # compact meta layout ONLY when the title would wrap to 2+ lines in
    # the available card width.
    #   1-line title: separate "Mod" line + "by Author" line below
    #   2-line title: single compact meta line "Mod . by Author"
    # No hardcoded game-name lists - the only thing that matters is whether
    # the title actually wraps, which depends on character widths ("Black
    # Mesa Source VR" fits, "Horizon Chase Turbo VR" doesn't even though
    # they're similar length).
    #
    # Available text width in the card: card content is ~158px wide at sc=1
    # after padding + cover-image space. Anything wider than that wraps.
    $titleTypeface = New-Object System.Windows.Media.Typeface(
        $titleText.FontFamily,
        [System.Windows.FontStyles]::Normal,
        [System.Windows.FontWeights]::Bold,
        [System.Windows.FontStretches]::Normal
    )
    $titleFormatted = New-Object System.Windows.Media.FormattedText(
        $titleDisplay,
        [System.Globalization.CultureInfo]::CurrentCulture,
        [System.Windows.FlowDirection]::LeftToRight,
        $titleTypeface,
        $titleText.FontSize,
        [System.Windows.Media.Brushes]::White,
        96
    )
    # Pixel cutoff = the width where WPF actually breaks the line. The
    # raw available width is ~158px but TextBlock wraps a bit earlier
    # because of word-boundary rounding. 145 catches titles like
    # "Panzer Dragoon Remake" that visually wrap to 2 lines but measure
    # under 158px in pure FormattedText. Tweak if new games show
    # mis-classified wrap behavior.
    $titleAvailWidth = [int](145 * $sc)
    $isLongTitle = ($titleFormatted.Width -gt $titleAvailWidth)
    # Tiles whose mod string already fills the meta line: drop the
    # ". by <Author>" tail so it stays on ONE line instead of being
    # ellipsised. A tile-space decision only - the detail page still
    # credits the creator, and the Author field stays intact for search.
    # MEASURED, NOT MAINTAINED: with a TWO-LINE title, mod name and
    # modder move into ONE shared line. If "<mod> . by <author>" does
    # not fit there, the author is cut off at the end - you then see
    # "... by R" or just "by". That must never happen: in that case the
    # author is dropped ENTIRELY.
    # The author stays in the catalog (for search) and remains on the
    # detail page - this is purely a space decision on the tile.
    # There used to be a hand-maintained title list here; it had to be
    # updated with every new entry and was forgotten.
    $hideTileAuthor = $false
    if ($isLongTitle -and $game.Mod -and $game.Author -and -not $game.ImprovementTag) {
        try {
            $metaProbe = New-Object System.Windows.Media.FormattedText(
                ($game.Mod + " . by " + $game.Author),
                [System.Globalization.CultureInfo]::CurrentCulture,
                [System.Windows.FlowDirection]::LeftToRight,
                $titleTypeface,
                $titleText.FontSize,
                [System.Windows.Media.Brushes]::White,
                96
            )
            if ($metaProbe.Width -gt $titleAvailWidth) { $hideTileAuthor = $true }
        } catch { }
    }
    # Scoped overrides: titles that visibly wrap to two lines but measure
    # UNDER the cutoff, so the width test alone puts them on the
    # short-title path - which gives them mod and author on SEPARATE
    # lines. Four lines (title x2 + mod + author) then push the
    # description into the Install button. Forcing the long-title path
    # merges mod + author into ONE line and the description moves up,
    # exactly like every other genuinely two-line title.
    # "Sonic Robo Blast 2 VR" measures narrower than "Panzer Dragoon
    # Remake" (the title the 145 cutoff was tuned for) and slips under it.
    if ($game.Title -in @("Sonic Robo Blast 2 VR")) { $isLongTitle = $true }

    if (-not $isLongTitle) {
        # Short title: keep the classic two-line meta block.
        $modText = New-Object System.Windows.Controls.TextBlock
        $modText.Text = $game.Mod
        # Long mod lines (two mod names plus "(auto-update)") overflow the
        # tile at the normal size. One step down keeps them inside and stays
        # legible. The cutoff sits ABOVE every string that fits today, so
        # only the genuinely too-long ones change - nothing that already
        # looked right is touched.
        $modText.FontSize = $(if ($game.Mod -and $game.Mod.Length -ge 31) { [int](9*$sc) } else { [int](10*$sc) })
        $modText.FontWeight = [System.Windows.FontWeights]::Medium
        $modText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($game.Accent)
        $modText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $modText.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
        $titleStack.Children.Add($modText) | Out-Null

        # Add-on banner: small blue "+ <AddonName> add-on" tag right
        # below the mod-version line. Shows whenever the catalog entry
        # has an AddonInstaller field (currently used for HL2VRU on
        # all three Half-Life 2 VR cards). The banner is a visual hint
        # only - the actual install button lives on the detail view.
        if ($game.AddonInstaller -and $game.AddonName) {
            $addonBanner = New-Object System.Windows.Controls.Border
            $addonBanner.Background     = [System.Windows.Media.Brushes]::Transparent
            $addonBanner.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5599ee")
            $addonBanner.BorderThickness = [System.Windows.Thickness]::new(1)
            $addonBanner.CornerRadius   = [System.Windows.CornerRadius]::new([int](2*$sc))
            $addonBanner.Padding        = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
            $addonBanner.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $addonBanner.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
            $addonBanner.Margin = [System.Windows.Thickness]::new(0, [int](3*$sc), 0, 0)
            $addonTxt = New-Object System.Windows.Controls.TextBlock
            $addonTxt.Text = "+ $($game.AddonName) add-on"
            $addonTxt.FontSize = [int](8*$sc)
            $addonTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
            $addonTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7ab5ff")
            $addonTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $addonTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $addonTxt.TextAlignment = [System.Windows.TextAlignment]::Left
            $addonTxt.LineHeight = [double][int](10*$sc)
            $addonTxt.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
            $addonBanner.Child = $addonTxt
            $titleStack.Children.Add($addonBanner) | Out-Null
            $card.Resources.Add("addonBanner", $addonBanner)
        } elseif ($game.ImprovementTag) {
            # Generic blue "improvement" tag (same look as the add-on
            # banner) for entries that are VR improvement modlists
            # rather than a single drop-in mod (e.g. Fallout 4 VR /
            # Skyrim VR via Wabbajack). Purely a visual hint.
            $impBanner = New-Object System.Windows.Controls.Border
            $impBanner.Background      = [System.Windows.Media.Brushes]::Transparent
            $impBanner.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5599ee")
            $impBanner.BorderThickness = [System.Windows.Thickness]::new(1)
            $impBanner.CornerRadius    = [System.Windows.CornerRadius]::new([int](2*$sc))
            $impBanner.Padding         = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
            $impBanner.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $impBanner.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
            $impBanner.Margin = [System.Windows.Thickness]::new(0, [int](3*$sc), 0, 0)
            $impTxt = New-Object System.Windows.Controls.TextBlock
            $impTxt.Text = $game.ImprovementTag
            $impTxt.FontSize = [int](8*$sc)
            $impTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
            $impTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7ab5ff")
            $impTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $impTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $impTxt.TextAlignment = [System.Windows.TextAlignment]::Left
            $impTxt.LineHeight = [double][int](10*$sc)
            $impTxt.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
            $impBanner.Child = $impTxt
            $titleStack.Children.Add($impBanner) | Out-Null
            $card.Resources.Add("addonBanner", $impBanner)
        }

        # ImprovementTag games: hide the modder name on the TILE so the
        # blue "+ ... mod" box can take that slot without breaking layout.
        # The author still shows on the detail page.
        if (-not $isExternal -and $game.Author -and -not $game.ImprovementTag) {
            $authorText = New-Object System.Windows.Controls.TextBlock
            # A very long modder name runs out of tile width at the normal
            # size. One point smaller makes it fit and is not noticeable next
            # to the other tiles. The threshold is deliberately high (28): at
            # 22 it would have quietly shrunk nine existing tiles as well -
            # only "Hochgeschwindigkeitsrennfahrer" (30) actually needs it.
            $authorText.FontSize = $(if (([string]$game.Author).Length -gt 28) { [int](8*$sc) } else { [int](9*$sc) })
            $authorText.FontWeight = [System.Windows.FontWeights]::Medium
            $authorText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $authorText.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
            $authGrey = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#555568")
            # The (auto-update) marker can sit on either side of the name and
            # the ORDER IS MEANINGFUL, so it is rendered where the catalog put
            # it - never reordered:
            #   "(auto-update) RaYRoD" -> "(auto-update) by RaYRoD"
            #      the whole entry auto-updates; marker leads.
            #   "lufz (auto-update)"   -> "by lufz (auto-update)"
            #      only ONE of the entry's mods auto-updates, so the marker has
            #      to sit next to that name to say WHICH one (Forza Horizon 6:
            #      lufz from GitHub, NALULUNA from ko-fi).
            #   "(auto-update)" alone  -> "(auto-update)"
            #      modders already named on the Mod line above; a bare "by"
            #      would just dangle.
            # The marker always takes the accent colour, the name stays grey.
            $auAccent = [System.Windows.Media.BrushConverter]::new().ConvertFromString($game.Accent)
            $auMarker = $null; $auName = [string]$game.Author; $auFirst = $false
            if ($game.Author -match '^\s*(\(auto-updates?\))\s*(.*)$') {
                $auMarker = [string]$matches[1]; $auName = ([string]$matches[2]).Trim(); $auFirst = $true
            } elseif ($game.Author -match '^\s*(.+?)\s*(\(auto-updates?\))\s*$') {
                $auMarker = [string]$matches[2]; $auName = ([string]$matches[1]).Trim(); $auFirst = $false
            }
            if ($auMarker) {
                if ($auFirst) {
                    $auRun = New-Object System.Windows.Documents.Run
                    $auRun.Text = $(if ($auName) { "$auMarker " } else { $auMarker })
                    $auRun.Foreground = $auAccent
                    [void]$authorText.Inlines.Add($auRun)
                }
                if ($auName) {
                    $byRun = New-Object System.Windows.Documents.Run
                    $byRun.Text = $(if ($auFirst) { "by $auName" } else { "by $auName " })
                    $byRun.Foreground = $authGrey
                    [void]$authorText.Inlines.Add($byRun)
                }
                if (-not $auFirst) {
                    $auRun2 = New-Object System.Windows.Documents.Run
                    $auRun2.Text = $auMarker
                    $auRun2.Foreground = $auAccent
                    [void]$authorText.Inlines.Add($auRun2)
                }
            } else {
                $authorText.Text = "by $($game.Author)"
                $authorText.Foreground = $authGrey
            }
            $titleStack.Children.Add($authorText) | Out-Null
            $card.Resources.Add("authorText", $authorText)
        } elseif ($isExternal) {
            # Externals (LR / REFramework family entries that go through
            # the external installer) don't have a separate Author field,
            # so the title stack would be shorter (title + mod only). Add
            # an invisible spacer line that mimics authorText's height so
            # the layout matches MC cards - and so the hover handler has
            # something to "hide" to make room under the preview image.
            # SKIP the spacer when the card already has an addonBanner
            # (HL2VR family) - the banner gives the hover handler
            # something to hide already, and the spacer would push the
            # Description down into the Install button.
            if (-not ($game.AddonInstaller -and $game.AddonName) -and -not $game.ImprovementTag) {
                $spacerText = New-Object System.Windows.Controls.TextBlock
                $spacerText.Text = " "
                $spacerText.FontSize = [int](9*$sc)
                $spacerText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
                $spacerText.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
                $titleStack.Children.Add($spacerText) | Out-Null
                $card.Resources.Add("authorText", $spacerText)
            }
        }
    } else {
        # Long title wraps to 2 lines on its own. To avoid the mod + author
        # block pushing the description and Install button off the card, we
        # collapse both into ONE small line: "Mod . by Author" with the mod
        # portion in the game's accent colour and the author tail in muted
        # grey. Uses an Inlines run so colours can split inside one TextBlock.
        $metaLine = New-Object System.Windows.Controls.TextBlock
        $metaLine.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $metaLine.FontSize = [int](9*$sc)
        $metaLine.FontWeight = [System.Windows.FontWeights]::Medium
        $metaLine.Margin = [System.Windows.Thickness]::new(0, [int](2*$sc), 0, 0)
        $metaLine.TextWrapping = [System.Windows.TextWrapping]::NoWrap
        $metaLine.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis

        if ($game.Mod -and -not $game.ImprovementTag) {
            $modRun = New-Object System.Windows.Documents.Run
            $modRun.Text = $game.Mod
            $modRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($game.Accent)
            [void]$metaLine.Inlines.Add($modRun)
        }
        if ($game.Mod -and $game.Author -and -not $game.ImprovementTag -and -not $hideTileAuthor) {
            $sepRun = New-Object System.Windows.Documents.Run
            $sepRun.Text = " . "
            $sepRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#444455")
            [void]$metaLine.Inlines.Add($sepRun)
        }
        # ImprovementTag games (and $hideTileAuthor titles): modder name
        # hidden on the tile (detail page keeps it).
        if ($game.Author -and -not $game.ImprovementTag -and -not $hideTileAuthor) {
            $authRun = New-Object System.Windows.Documents.Run
            # Same marker rule as the separate-line layout above - the ORDER
            # the catalog wrote is kept - but as ONE run: this compact line
            # is a single muted string, so there is no accent split here.
            if ($game.Author -match '^\s*(\(auto-updates?\))\s*(.*)$') {
                $acName = ([string]$matches[2]).Trim()
                $authRun.Text = $(if ($acName) { "$($matches[1]) by $acName" } else { [string]$matches[1] })
            } elseif ($game.Author -match '^\s*(.+?)\s*(\(auto-updates?\))\s*$') {
                $authRun.Text = "by $(([string]$matches[1]).Trim()) $($matches[2])"
            } else {
                $authRun.Text = "by $($game.Author)"
            }
            $authRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#888899")
            [void]$metaLine.Inlines.Add($authRun)
        }
        if ($metaLine.Inlines.Count -gt 0) {
            $titleStack.Children.Add($metaLine) | Out-Null
        }
        # The hover preview overlays this area. Stash the meta line so the
        # hover handler can hide it (avoids the image clipping the text).
        $card.Resources.Add("modText", $metaLine)
        # ImprovementTag on a LONG-title card: render the same blue
        # "+ ... mod" box the short-title path uses (the mod name above is
        # suppressed for these). Without this the tag never showed on long
        # titles like Ocarina of Time. Registered as addonBanner so the
        # hover preview hides it.
        if ($game.ImprovementTag -and -not $card.Resources.Contains("addonBanner")) {
            $impBanner = New-Object System.Windows.Controls.Border
            $impBanner.Background      = [System.Windows.Media.Brushes]::Transparent
            $impBanner.BorderBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5599ee")
            $impBanner.BorderThickness = [System.Windows.Thickness]::new(1)
            $impBanner.CornerRadius    = [System.Windows.CornerRadius]::new([int](2*$sc))
            $impBanner.Padding         = [System.Windows.Thickness]::new([int](5*$sc), [int](1*$sc), [int](5*$sc), [int](1*$sc))
            $impBanner.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $impBanner.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
            $impBanner.Margin = [System.Windows.Thickness]::new(0, [int](3*$sc), 0, 0)
            $impTxt = New-Object System.Windows.Controls.TextBlock
            $impTxt.Text = $game.ImprovementTag
            $impTxt.FontSize = [int](8*$sc)
            $impTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
            $impTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7ab5ff")
            $impTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $impTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $impTxt.TextAlignment = [System.Windows.TextAlignment]::Left
            $impTxt.LineHeight = [double][int](10*$sc)
            $impTxt.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
            $impBanner.Child = $impTxt
            $titleStack.Children.Add($impBanner) | Out-Null
            $card.Resources.Add("addonBanner", $impBanner)
        }
        # Long-title cards don't get a separate authorText - the author is
        # already part of $metaLine above. The hover handler tolerates a
        # missing authorText (early-returns on null).
    }


    # NOTE: $titleStack was already added to $topStack on line 1653,
    # which is already in $grid. Don't add it again - WPF only
    # permits one logical parent per element.

    # Description: forced to a single line with ellipsis. Long
    # descriptions or wrapping titles would otherwise push the
    # Install button out of the card. The full text remains
    # accessible via the auto-tooltip (only shown when truncated).
    $descText = New-Object System.Windows.Controls.TextBlock
    $descText.Text = $game.Description
    $descText.FontSize = [int](10*$sc)
    $descText.FontWeight = [System.Windows.FontWeights]::Medium
    $descText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#777788")
    $descText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $descText.TextWrapping  = [System.Windows.TextWrapping]::NoWrap
    $descText.TextTrimming  = [System.Windows.TextTrimming]::CharacterEllipsis
    $descText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    # When an addon banner is present (HL2VR family with HL2VRU),
    # Row 0 grows by the banner height (~14px). Description should
    # sit at the TOP of Row 1 with a small top-margin so it floats
    # just below the add-on tag and away from the Install button.
    if ($game.AddonInstaller -and $game.AddonName) {
        $descText.Margin = [System.Windows.Thickness]::new(0, [int](4*$sc), 0, 0)
    } else {
        $descText.Margin = [System.Windows.Thickness]::new(0, [int](6*$sc), 0, 0)
    }
    $descText.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    if ($game.Description) { $descText.ToolTip = $game.Description }
    [System.Windows.Controls.Grid]::SetRow($descText, 1)
    $grid.Children.Add($descText) | Out-Null

    # Button: solid accent color. Smart text-contrast: light accents
    # (high luminance, e.g. Alba green #88cc44) get dark text; dark
    # accents get white text. Threshold ~150 picks the right side
    # Install button - Option D layout. Slate background (sitting
    # between the card's bottom-gradient and pure black) keeps the
    # button calm and readable; a 3px accent-color cap on the left
    # signals "action pending" and preserves the card's color
    # identity without the full-bleed garishness. Cap color is the
    # game's accent; text is a soft warm-white tinted by accent
    # luminance for legibility.
    $btnAccentHex = Get-DampenedAccentHex $accentHex
    $btnAcc = ConvertTo-MediaColor $btnAccentHex
    # Slate fill: dark-but-tinted - takes meaningful color from
    # the game's accent so the button reads as part of the card,
    # not a generic grey strip. ~18% accent / 82% near-black,
    # which keeps strong colors (red, magenta) recognizable while
    # still being calm enough to read text on.
    $slateColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($btnAcc.R * 0.18 + 10))))),
        [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($btnAcc.G * 0.18 + 10))))),
        [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($btnAcc.B * 0.18 + 10)))))
    )
    $btnBorder = New-Object System.Windows.Controls.Border
    $btnBorder.CornerRadius = [System.Windows.CornerRadius]::new([int](4*$sc))
    $btnBorder.Background   = New-Object System.Windows.Media.SolidColorBrush $slateColor
    $btnBorder.BorderThickness = [System.Windows.Thickness]::new(0, 1, 0, 0)
    $btnBorder.BorderBrush  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#222230")
    $btnBorder.Padding = [System.Windows.Thickness]::new(0, [int](6*$sc), 0, [int](6*$sc))
    [System.Windows.Controls.Grid]::SetRow($btnBorder, 2)

    # Text color: warm-white tinted by the accent so each card's
    # button text picks up its card's color signature. ~30% accent
    # mix - enough to be visible (warm red on a red card, mint on
    # a green one) without losing readability.
    $textColor = [System.Windows.Media.Color]::FromRgb(
        [byte]([Math]::Min(255, [int]([Math]::Round(180 + $btnAcc.R * 0.30)))),
        [byte]([Math]::Min(255, [int]([Math]::Round(176 + $btnAcc.G * 0.30)))),
        [byte]([Math]::Min(255, [int]([Math]::Round(172 + $btnAcc.B * 0.30))))
    )
    $btnFgBrush = New-Object System.Windows.Media.SolidColorBrush $textColor

    $btnText = New-Object System.Windows.Controls.TextBlock
    $btnText.FontSize = [int](11*$sc)
    $btnText.FontWeight = [System.Windows.FontWeights]::SemiBold
    $btnText.Foreground = $btnFgBrush
    $btnText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $btnText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $btnText.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center

    if ($isExternal) {
        $btnText.Text = if ($game.ButtonLabel) { $game.ButtonLabel } else {
            switch ($game.Type) {
                "steam"    { "Open in Steam" }
                "itch"     { "Open on itch.io" }
                default    { "Get Installer" }
            }
        }
    } elseif ($game.DirectDownload) {
        $btnText.Text = "Install"
        $btnBorder.Opacity = 1.0
    } else {
        $batPath = Join-Path $scriptDir $game.Bat
        $batExists = Test-Path $batPath
        $btnText.Text = if ($batExists) { "Install" } else { "Not found" }
        $btnBorder.Opacity = if ($batExists) { 1.0 } else { 0.4 }
    }

    # Inner grid with the label centered and a reload-pill area
    # docked right. Pill is collapsed by default and only shown
    # when Check Installed flips the card into the VR Ready state.
    $btnInner = New-Object System.Windows.Controls.Grid
    $btnText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

    # Free games: "FREE" sits just before the "Install" label as one
    # centered unit (reads "FREE  Install"), in the game's accent (glow)
    # colour. A horizontal StackPanel keeps the pair centered no matter
    # the widths. FREE starts hidden - Check Installed reveals it once
    # the game is confirmed, and hides it again in the green VR-Ready
    # state (leaving just the centered "VR Ready" label). Stored as a
    # card resource for that toggle.
    $freeBtnLabel = $null
    if ($isFreeGame) {
        $freeAccCol = Get-GlowColor $accentHex
        $freeBtnLabel = New-Object System.Windows.Controls.TextBlock
        $freeBtnLabel.Text = "FREE"
        $freeBtnLabel.FontSize = [int](11*$sc)
        $freeBtnLabel.FontWeight = [System.Windows.FontWeights]::Bold
        $freeBtnLabel.Foreground = New-Object System.Windows.Media.SolidColorBrush $freeAccCol
        $freeBtnLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $freeBtnLabel.Margin = [System.Windows.Thickness]::new(0, 0, [int](8*$sc), 0)
        $freeBtnLabel.Visibility = [System.Windows.Visibility]::Collapsed
        try {
            $fglow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $fglow.Color = $freeAccCol
            $fglow.BlurRadius = 6
            $fglow.ShadowDepth = 0
            $fglow.Opacity = 0.7
            $freeBtnLabel.Effect = $fglow
        } catch {}

        $freeStack = New-Object System.Windows.Controls.StackPanel
        $freeStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $freeStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $freeStack.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
        $btnText.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
        $freeStack.Children.Add($freeBtnLabel) | Out-Null
        $freeStack.Children.Add($btnText) | Out-Null
        # Text rides ABOVE the glowing button (added to the shell below),
        # not inside it, so the button's glow can never blur the label.
        $btnTextLayer = $freeStack
    } else {
        $btnTextLayer = $btnText
    }

    # Accent cap on the left edge - 3px wide bar in the game's
    # accent color. Acts as the "action pending" signal in the
    # default Install state. Recolored on state transitions:
    # green when game is installed but not VR-modded, blue when
    # an update is available, hidden in the VR-Ready state.
    $accentCap = New-Object System.Windows.Controls.Border
    $accentCap.Width  = [int](5*$sc)
    $accentCap.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
    $accentCap.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    $accentCap.Background          = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accentHex)
    # Bleed through the button's inner padding (top/bottom) so the
    # cap touches the button edges without leaving slate gaps.
    $accentCap.Margin = [System.Windows.Thickness]::new(0, [int](-6*$sc), 0, [int](-6*$sc))
    $btnInner.Children.Add($accentCap) | Out-Null

    # Reload pill: small fixed-width strip on the right with a
    # subtle vertical divider on its left edge. Hidden until the
    # card flips to VR Ready (Tag = "vrinstalled"). Mouse clicks
    # on it set e.Handled = true so the card-level click handler
    # (which launches the game) doesn't also fire.
    $reloadPill = New-Object System.Windows.Controls.Border
    $reloadPill.Width = [int](28*$sc)
    $reloadPill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $reloadPill.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    $reloadPill.Background     = [System.Windows.Media.Brushes]::Transparent
    $reloadPill.BorderThickness = [System.Windows.Thickness]::new(1, 0, 0, 0)
    $reloadPill.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
    $reloadPill.Cursor         = [System.Windows.Input.Cursors]::Hand
    $reloadPill.Visibility     = [System.Windows.Visibility]::Collapsed
    $reloadPill.Margin         = [System.Windows.Thickness]::new(0, [int](-6*$sc), 0, [int](-6*$sc))
    $reloadGlyph = New-Object System.Windows.Controls.TextBlock
    $reloadGlyph.Text = [char]0x21BB
    $reloadGlyph.FontSize = [int](13*$sc)
    $reloadGlyph.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI Symbol")
    $reloadGlyph.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
    $reloadGlyph.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $reloadGlyph.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $reloadPill.Child = $reloadGlyph
    # Easy External Installer cards never own an install transaction. Keep the
    # object available to the shared state code, but never put its Reinstall
    # affordance into the visual tree.
    if (-not $isExternal) { $btnInner.Children.Add($reloadPill) | Out-Null }

    # Hover feedback for the reinstall arrow itself. The pill has no
    # hover of its own otherwise - covers every button type (VR Ready,
    # Update, DualMode) since each card has one pill. To stay clearly
    # visible WITHOUT wiping the vrupdate blue recoloring, we stash the
    # pill's CURRENT background on enter and restore exactly that on
    # leave (never a blind Transparent, which previously erased blue).
    $reloadGlyph.Opacity = 0.75
    $reloadPill.Add_MouseEnter({
        # Overlay-style hover: only brighten the glyph (matches the other
        # buttons); the pill keeps its own fill colour. Also un-brighten the
        # Update label - the cursor is on Play now, not on Update.
        $this.Child.Opacity = 1.0
        $owner = $this.Resources.Item("ownerCard")
        if ($owner -and $owner.Tag -eq "vrupdate") {
            $bt = $owner.Resources.Item("btnText")
            $rest = $owner.Resources.Item("updLabelRest")
            if ($bt -and $rest) { $bt.Foreground = $rest }
        }
        # VR Ready: cursor moved onto the reinstall pill - un-brighten the
        # "Start in VR" label so only the launch area reads as lit.
        if ($owner -and $owner.Tag -eq "vrinstalled") {
            $bt = $owner.Resources.Item("btnText")
            if ($bt) { $bt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cdb77a") }
        }
    })
    $reloadPill.Add_MouseLeave({
        if ($this.Resources.Contains("pillHovStash")) {
            $this.Background = $this.Resources.Item("pillHovStash")
            $this.Resources.Remove("pillHovStash") | Out-Null
        }
        $this.Child.Opacity = 0.75
        # Back on the Update button (off the pill): re-brighten Update.
        $owner = $this.Resources.Item("ownerCard")
        if ($owner -and $owner.Tag -eq "vrupdate") {
            $bb = $owner.Resources.Item("btnBorder")
            $bt = $owner.Resources.Item("btnText")
            if ($bb -and $bt -and $bb.IsMouseOver) { $bt.Foreground = [System.Windows.Media.Brushes]::White }
        }
        # VR Ready: back on the launch area (off the pill) - re-brighten.
        if ($owner -and $owner.Tag -eq "vrinstalled") {
            $bb = $owner.Resources.Item("btnBorder")
            $bt = $owner.Resources.Item("btnText")
            if ($bb -and $bt -and $bb.IsMouseOver) { $bt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ece0b5") }
        }
    })

    # DualMode split overlay - sits on top of $btnText for REPO VR /
    # Content Warning VR style games where both Mode 1 (current) and
    # Mode 2 (depot) are installed in parallel. Two side-by-side
    # buttons: "Current" (left) and "Depot" (right). Collapsed by
    # default; shown on hover only when Filter.ps1 marks the state as
    # DualMode. Reload pill sits to the right of these as usual.
    # Only games that can actually expose two launch choices need the split
    # subtree. Building its five WPF elements and six closure-backed handlers
    # for every one of the 250+ cards was a large, entirely hidden startup tax.
    $dualSplit = $null
    $dualCurrentBtn = $null
    $dualDepotBtn = $null
    $supportsSplit = [bool]($game.DualMode -or $game.TwoMods)
    if ($supportsSplit) {
    $dualSplit = New-Object System.Windows.Controls.Grid
    $dualSplit.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $dualSplit.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    # NO NEGATIVE TOP/BOTTOM ANY MORE. Those -6 cancelled out
    # $btnBorder.Padding back when the split lived INSIDE that
    # border. It now sits in $btnShell as a sibling of the border,
    # where there is no padding to cancel - so the -6 made the
    # split taller than the button: divider too long, hover area
    # overhanging. Zero matches the border exactly; the 28 on the
    # right still keeps the reload pill clear.
    $dualSplit.Margin              = [System.Windows.Thickness]::new(
        0, 0, [int](28*$sc), 0
    )
    $dualSplit.Visibility = [System.Windows.Visibility]::Collapsed
    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $col2 = New-Object System.Windows.Controls.ColumnDefinition
    $col2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $dualSplit.ColumnDefinitions.Add($col1) | Out-Null
    $dualSplit.ColumnDefinitions.Add($col2) | Out-Null

    $dualCurrentBtn = New-Object System.Windows.Controls.Border
    $dualCurrentBtn.Background     = [System.Windows.Media.Brushes]::Transparent
    $dualCurrentBtn.BorderThickness = [System.Windows.Thickness]::new(0, 0, 1, 0)
    $dualCurrentBtn.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
    $dualCurrentBtn.CornerRadius   = [System.Windows.CornerRadius]::new([int](4*$sc), 0, 0, [int](4*$sc))
    $dualCurrentBtn.Cursor         = [System.Windows.Input.Cursors]::Hand
    [System.Windows.Controls.Grid]::SetColumn($dualCurrentBtn, 0)
    $dualCurrentTxt = New-Object System.Windows.Controls.TextBlock
    $dualCurrentLabel = if ($game.TwoMods -and $game.ModAButtonLabel) { [string]$game.ModAButtonLabel } elseif ($game.TwoMods -and $game.ModAName) { [string]$game.ModAName } elseif ($game.CurrentButtonLabel) { [string]$game.CurrentButtonLabel } else { "Current" }
    $dualCurrentTxt.Text = ([char]0x25B6) + " " + $dualCurrentLabel
    $dualCurrentTxt.FontSize = $(if ($game.TwoMods) { if ($dualCurrentLabel.Length -gt 8) { 7.8 } else { 8.5 } } elseif ($dualCurrentLabel.Length -gt 8) { 9.5 } else { 11 })*$sc
    $dualCurrentTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $dualCurrentTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
    $dualCurrentTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $dualCurrentTxt.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $dualCurrentBtn.Child = $dualCurrentTxt
    $dualSplit.Children.Add($dualCurrentBtn) | Out-Null

    $dualDepotBtn = New-Object System.Windows.Controls.Border
    $dualDepotBtn.Background     = [System.Windows.Media.Brushes]::Transparent
    $dualDepotBtn.BorderThickness = [System.Windows.Thickness]::new(0)
    $dualDepotBtn.Cursor         = [System.Windows.Input.Cursors]::Hand
    [System.Windows.Controls.Grid]::SetColumn($dualDepotBtn, 1)
    $dualDepotTxt = New-Object System.Windows.Controls.TextBlock
    $dualDepotLabel = if ($game.TwoMods -and $game.ModBButtonLabel) { [string]$game.ModBButtonLabel } elseif ($game.TwoMods -and $game.ModBName) { [string]$game.ModBName } elseif ($game.DepotButtonLabel) { [string]$game.DepotButtonLabel } else { "Depot" }
    $dualDepotTxt.Text = ([char]0x25B6) + " " + $dualDepotLabel
    $dualDepotTxt.FontSize = $(if ($game.TwoMods) { if ($dualDepotLabel.Length -gt 8) { 7.8 } else { 8.5 } } elseif ($dualDepotLabel.Length -gt 8) { 9.5 } else { 11 })*$sc
    $dualDepotTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $dualDepotTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
    $dualDepotTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $dualDepotTxt.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $dualDepotBtn.Child = $dualDepotTxt
    $dualSplit.Children.Add($dualDepotBtn) | Out-Null
    }

    # !!! NOT INSIDE $btnInner. That border carries the neon halo,
    # and a DropShadowEffect rasterises its WHOLE subtree - so the
    # split labels ("balouza", "BioVRDev") were being blurred by the
    # glow, worst on hover where the halo is strongest and at the
    # 7.8pt the split uses. It goes into $btnShell instead, as a
    # sibling ABOVE the glowing border - exactly what the single
    # button label already does. Added further down, once
    # $btnShell exists.

    $btnBorder.Child = $btnInner
    # Neon button redesign (test): no accent cap, no glass frills -
    # vivid neon outline + halo + neon label text on a near-black fill.
    Add-NeonButtonFx -Button $btnBorder -Text $btnText -Cap $accentCap -AccentHex $accentHex -Sc $sc
    # Button shell: the glowing $btnBorder sits at the bottom; the label
    # rides ON TOP as a sibling with NO Effect. A DropShadowEffect only
    # rasterizes its OWN subtree, so a sibling label stays crisp while the
    # button keeps its halo. The label's vertical margin gives the button
    # its height (the border stretches to match). Hidden-on-dual-mode keeps
    # the slot, so the DualSplit overlay still shows underneath.
    $btnShell = New-Object System.Windows.Controls.Grid
    [System.Windows.Controls.Grid]::SetRow($btnShell, 2)
    $btnShell.Children.Add($btnBorder) | Out-Null
    if ($btnTextLayer) {
        $btnTextLayer.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $btnTextLayer.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
        $btnTextLayer.Margin = [System.Windows.Thickness]::new(0, [int](6*$sc), 0, [int](6*$sc))
        $btnTextLayer.IsHitTestVisible = $false
        $btnShell.Children.Add($btnTextLayer) | Out-Null
    }
    if ($dualSplit) { $btnShell.Children.Add($dualSplit) | Out-Null }
    $grid.Children.Add($btnShell) | Out-Null
    # Store btnText, reload pill, accent cap on card for later access by Check Installed
    if ($card.Resources.Contains("btnText")) { $card.Resources.Remove("btnText") }
    if ($card.Resources.Contains("btnBorder")) { $card.Resources.Remove("btnBorder") }
    if ($card.Resources.Contains("reloadPill")) { $card.Resources.Remove("reloadPill") }
    if ($card.Resources.Contains("reloadGlyph")) { $card.Resources.Remove("reloadGlyph") }
    if ($card.Resources.Contains("accentCap")) { $card.Resources.Remove("accentCap") }
    if ($card.Resources.Contains("dualSplit")) { $card.Resources.Remove("dualSplit") }
    if ($card.Resources.Contains("dualCurrentBtn")) { $card.Resources.Remove("dualCurrentBtn") }
    if ($card.Resources.Contains("dualDepotBtn")) { $card.Resources.Remove("dualDepotBtn") }
    if ($card.Resources.Contains("gameData")) { $card.Resources.Remove("gameData") }
    if ($card.Resources.Contains("cardScale")) { $card.Resources.Remove("cardScale") }
    $card.Resources.Add("btnText", $btnText)
    $card.Resources.Add("btnBorder", $btnBorder)
    if ($card.Resources.Contains("freeBtnLabel")) { $card.Resources.Remove("freeBtnLabel") }
    $card.Resources.Add("freeBtnLabel", $freeBtnLabel)
    $card.Resources.Add("reloadPill", $reloadPill)
    $card.Resources.Add("reloadGlyph", $reloadGlyph)
    $card.Resources.Add("accentCap", $accentCap)
    if ($dualSplit)      { $card.Resources.Add("dualSplit", $dualSplit) }
    if ($dualCurrentBtn) { $card.Resources.Add("dualCurrentBtn", $dualCurrentBtn) }
    if ($dualDepotBtn)   { $card.Resources.Add("dualDepotBtn", $dualDepotBtn) }
    $card.Resources.Add("gameData", $game)
    $card.Resources.Add("cardScale", [double]$sc)

    # DualMode split click handlers - route to Start-GameInVR with
    # the explicit Mode parameter. We stop event bubbling so the
    # card-level click handler doesn't also fire.
    if ($supportsSplit) {
    $dualCurrentBtn.Resources.Add("ownerCard", $card)
    $dualCurrentBtn.Add_MouseLeftButtonDown({
        param($s, $e)
        $owner = $this.Resources.Item("ownerCard")
        $g = $owner.Resources.Item("gameData")
        if ($g) {
            if (Get-Command Start-GameInVR -EA SilentlyContinue) {
                $mode = if ($this.Resources.Contains('launchMode')) { [string]$this.Resources.Item('launchMode') } elseif ($g.TwoMods) { 'ModA' } else { 'Current' }
                Start-GameInVR -Game $g -Mode $mode
            }
        }
        $e.Handled = $true
    }.GetNewClosure())
    $dualDepotBtn.Resources.Add("ownerCard", $card)
    $dualDepotBtn.Add_MouseLeftButtonDown({
        param($s, $e)
        $owner = $this.Resources.Item("ownerCard")
        $g = $owner.Resources.Item("gameData")
        if ($g) {
            if (Get-Command Start-GameInVR -EA SilentlyContinue) {
                $mode = if ($this.Resources.Contains('launchMode')) { [string]$this.Resources.Item('launchMode') } elseif ($g.TwoMods) { 'ModB' } else { 'Depot' }
                Start-GameInVR -Game $g -Mode $mode
            }
        }
        $e.Handled = $true
    }.GetNewClosure())
    # Tinted hover background on each split half so the user sees
    # which one they're about to click. Matches the green family.
    $dualCurrentBtn.Add_MouseEnter({
        $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
    }.GetNewClosure())
    $dualCurrentBtn.Add_MouseLeave({
        $this.Background = [System.Windows.Media.Brushes]::Transparent
    }.GetNewClosure())
    $dualDepotBtn.Add_MouseEnter({
        $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
    }.GetNewClosure())
    $dualDepotBtn.Add_MouseLeave({
        $this.Background = [System.Windows.Media.Brushes]::Transparent
    }.GetNewClosure())
    }

    # Inviting hover effect: a soft light-sweep gradient travels
    # diagonally across the button on MouseEnter. Subtle but draws
    # the eye. Only fires when the button is in default state
    # (not "VR Ready" outline style which has its own visual).
    $btnBorder.Resources.Add("accentHex", $accentHex)
    # Store the owning card directly - VisualTreeHelper walks were
    # unreliable (returned null in some render states) which caused
    # the skip-on-vrinstalled check to fail.
    $btnBorder.Resources.Add("ownerCard", $card)
    $reloadPill.Resources.Add("ownerCard", $card)
    # Brighten the "Update" label (arrow + text) ONLY while the cursor is
    # genuinely over the button and NOT over the Play pill. The card raises
    # this event synthetically with IsMouseOver still false, which we skip.
    $btnBorder.Add_MouseEnter({
        $owner = $this.Resources.Item("ownerCard")
        if ($owner -and $owner.Tag -eq "vrupdate" -and $this.IsMouseOver) {
            $rp = $owner.Resources.Item("reloadPill")
            if ($rp -and $rp.IsMouseOver) { return }
            # Crossing the button's right edge to reach the Play pill fires
            # this a hair before the pill's own hover - which flashed
            # "Update". If the cursor sits in the pill's band at the right
            # edge, it's heading to Play, so don't brighten Update.
            if ($rp) {
                try {
                    $pos = [System.Windows.Input.Mouse]::GetPosition($this)
                    if ($pos.X -ge ($this.ActualWidth - $rp.ActualWidth - 6)) { return }
                } catch {}
            }
            $bt = $owner.Resources.Item("btnText")
            if ($bt) { $bt.Foreground = [System.Windows.Media.Brushes]::White }
        }
    }.GetNewClosure())
    $btnBorder.Add_MouseLeave({
        $owner = $this.Resources.Item("ownerCard")
        if ($owner -and $owner.Tag -eq "vrupdate") {
            $bt = $owner.Resources.Item("btnText")
            $rest = $owner.Resources.Item("updLabelRest")
            if ($bt -and $rest) { $bt.Foreground = $rest }
        }
    }.GetNewClosure())
    $btnBorder.Add_MouseEnter({
        $owner = $this.Resources.Item("ownerCard")
        if ($owner -and $owner.Tag -eq "vrinstalled") {
            # DualMode (REPO VR / Content Warning VR with both modes
            # installed): show the Current | Depot split instead of
            # the single "Start in VR" label. Filter.ps1 sets
            # DualMode=$true on gameStateMap when it detects both an
            # in-Steam mod AND a C:\Games\...\ depot install.
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            $updateLayout = Get-CardUpdateActionLayout -State $st
            if ($updateLayout.SplitVisible) {
                $bt = $owner.Resources.Item("btnText")
                # Hidden (not Collapsed): keep the text's layout slot so
                # the button keeps its normal height; the split overlays.
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Hidden }
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Visible }
                # NOTE: do NOT return - we still want the reload pill
                # to show via the second handler below.
            } else {
                # Reveal "Start in VR" (fires on whole-tile hover via the
                # card raising this event, and on direct button hover). A
                # second handler reveals the Reinstall pill.
                $bt = $owner.Resources.Item("btnText")
                if ($bt -and -not $owner.Resources.Contains("readyOrigText")) {
                    $owner.Resources.Add("readyOrigText", $bt.Text)
                    $bt.Text = "Start in VR"
                }
                # On DIRECT button hover (NOT over the Reinstall pill next
                # to it), brighten the label to a lit pale gold - between the
                # VR Ready gold and white - as a ready-to-press cue. Same pill
                # guard the Update label uses, so only the launch area lights.
                if ($bt -and $this.IsMouseOver) {
                    $rp = $owner.Resources.Item("reloadPill")
                    $onPill = $false
                    if ($rp) {
                        if ($rp.IsMouseOver) { $onPill = $true }
                        else {
                            try {
                                $pos = [System.Windows.Input.Mouse]::GetPosition($this)
                                if ($pos.X -ge ($this.ActualWidth - $rp.ActualWidth - 6)) { $onPill = $true }
                            } catch {}
                        }
                    }
                    if (-not $onPill) {
                        $bt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ece0b5")
                    }
                }
            }
            return
        }
        # Update-state ownership is deliberately asymmetric:
        #   one visible launch choice -> large button stays Update, pill = Play
        #   two visible launch choices -> split halves are Play, pill = Update
        # Never swap the large single-mod Update action underneath the cursor.
        if ($owner -and $owner.Tag -eq "vrupdate") {
            # Guard against a second pass: the card-level MouseEnter
            # raises this handler so the morph fires on whole-tile
            # hover. Once morphed (flag set on the card), don't run
            # again - re-stashing the morphed state as 'original'
            # would corrupt the MouseLeave restore.
            if ($owner.Resources.Contains("vrupdMorphed")) { return }
            $owner.Resources.Add("vrupdMorphed", $true)
            # DualMode in update state: same 3-way split, but the
            # reload pill on the right keeps its blue "Update Mod"
            # tint (handled by the secondary hover handler below).
            # Update always targets the Current variant - Depot is
            # version-pinned and never updated.
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            if ($st -and (Test-ShowDualSplit $st)) {
                # Stash + clear the blue background so the split row
                # underneath reads cleanly. Leave + click restore use
                # the same stashed values.
                if ($this.Resources.Contains("preHoverBrush"))   { $this.Resources.Remove("preHoverBrush")   | Out-Null }
                if ($this.Resources.Contains("preHoverBdBrush")) { $this.Resources.Remove("preHoverBdBrush") | Out-Null }
                if ($this.Resources.Contains("preHoverBdThick")) { $this.Resources.Remove("preHoverBdThick") | Out-Null }
                $this.Resources.Add("preHoverBrush",   $this.Background)
                $this.Resources.Add("preHoverBdBrush", $this.BorderBrush)
                $this.Resources.Add("preHoverBdThick", $this.BorderThickness)
                # Match the VR-Ready outline style so the split row
                # has the same visual chrome as the ready-state hover.
                $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(40, 70, 160, 90))
                $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3d6e4a")
                $this.BorderThickness = [System.Windows.Thickness]::new(1)
                $bt = $owner.Resources.Item("btnText")
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Hidden }
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Visible }
                # Blue update pill on the right - Update is always
                # for Current. Stash original colours so MouseLeave
                # restores them.
                $rp = $owner.Resources.Item("reloadPill")
                $rg = $owner.Resources.Item("reloadGlyph")
                if ($rp -and $rg) {
                    if (-not $this.Resources.Contains("preHoverPillBg"))     { $this.Resources.Add("preHoverPillBg",     $rp.Background)   }
                    if (-not $this.Resources.Contains("preHoverPillBd"))     { $this.Resources.Add("preHoverPillBd",     $rp.BorderBrush)  }
                    if (-not $this.Resources.Contains("preHoverPillGlyphFg")){ $this.Resources.Add("preHoverPillGlyphFg",$rg.Foreground)  }
                    if (-not $this.Resources.Contains("preHoverPillGlyphTx")){ $this.Resources.Add("preHoverPillGlyphTx",$rg.Text)        }
                    $rp.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
                    $rp.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563eb")
                    $rg.Foreground  = [System.Windows.Media.Brushes]::White
                    $rg.Text        = [char]0x21BB
                    $rp.ToolTip     = Get-UpdateActionLabel -Game $g -State $st -Fallback 'Update Mod'
                    $rp.Visibility  = [System.Windows.Visibility]::Visible
                }
                return
            }
            # Single launch choice: do not morph or recolor the blue Update
            # button. Reveal only the compact green Play pill on its right.
            $rp = $owner.Resources.Item("reloadPill")
            $rg = $owner.Resources.Item("reloadGlyph")
            if ($rp -and $rg) {
                if (-not $this.Resources.Contains("preHoverPillBg"))      { $this.Resources.Add("preHoverPillBg",      $rp.Background)   }
                if (-not $this.Resources.Contains("preHoverPillBd"))      { $this.Resources.Add("preHoverPillBd",      $rp.BorderBrush)  }
                if (-not $this.Resources.Contains("preHoverPillGlyphFg")) { $this.Resources.Add("preHoverPillGlyphFg", $rg.Foreground)  }
                if (-not $this.Resources.Contains("preHoverPillGlyphTx")) { $this.Resources.Add("preHoverPillGlyphTx", $rg.Text)        }
                $rp.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161d18")
                $rp.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5fa873")
                $rg.Foreground  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#88dd99")
                $rg.Text        = [char]0x25B6
                $rp.ToolTip     = 'Start in VR'
                $rp.Visibility  = [System.Windows.Visibility]::Visible
            }
            return
        }
        # Default state hover: a diagonal sweep travels across the
        # slate background. Outer stops stay anchored at the slate
        # color so the button reverts cleanly when the band leaves
        # the [0,1] range; only the inner three stops animate. The
        # peak is the accent color at ~50% mix into the slate -
        # bright enough to read as a sweep without losing the
        # button's calm identity. Cap brighten plays on top.
        if ($this.Resources.Contains("preHoverBrush")) {
            $this.Resources.Remove("preHoverBrush") | Out-Null
        }
        $this.Resources.Add("preHoverBrush", $this.Background)

        $accH = $this.Resources.Item("accentHex")
        if (-not $accH) { return }
        $accCol = ConvertTo-MediaColor $accH

        # Anchor the sweep on the button's *current* fill, not on
        # a recomputed slate. This matters when the card has
        # transitioned to a different state (installed = green
        # outline; future states could be other colors): the sweep
        # should ride over whatever is there, not flash slate
        # underneath. The default Install state still gets the
        # slate look because that's literally what $this.Background
        # is in that case.
        $sweepBase = $null
        if ($this.Background -is [System.Windows.Media.SolidColorBrush]) {
            $sweepBase = $this.Background.Color
        } else {
            # Fallback: recreate slate from accent (only used if a
            # previous hover left a gradient mid-flight, very rare).
            $sweepBase = [System.Windows.Media.Color]::FromRgb(
                [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($accCol.R * 0.18 + 10))))),
                [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($accCol.G * 0.18 + 10))))),
                [byte]([Math]::Max(0, [Math]::Min(255, [int]([Math]::Round($accCol.B * 0.18 + 10)))))
            )
        }
        # Sweep peak: shift sweepBase 30% toward white. This works
        # for any anchor color - dark slate, green-outline, blue
        # update CTA - and reads as a uniform "shine across the
        # button" instead of a state-specific accent flash.
        $slateBase = $sweepBase
        $sweepPeak = [System.Windows.Media.Color]::FromArgb(
            $sweepBase.A,
            [byte]([Math]::Min(255, [int]([Math]::Round($sweepBase.R + (255 - $sweepBase.R) * 0.30)))),
            [byte]([Math]::Min(255, [int]([Math]::Round($sweepBase.G + (255 - $sweepBase.G) * 0.30)))),
            [byte]([Math]::Min(255, [int]([Math]::Round($sweepBase.B + (255 - $sweepBase.B) * 0.30))))
        )

        $brush = New-Object System.Windows.Media.LinearGradientBrush
        $brush.StartPoint = New-Object System.Windows.Point 0, 0
        $brush.EndPoint   = New-Object System.Windows.Point 1, 1
        $sOutA = New-Object System.Windows.Media.GradientStop $slateBase, 0.0
        $sLead = New-Object System.Windows.Media.GradientStop $slateBase, 0.0
        $sPeak = New-Object System.Windows.Media.GradientStop $sweepPeak, 0.0
        $sTail = New-Object System.Windows.Media.GradientStop $slateBase, 0.0
        $sOutB = New-Object System.Windows.Media.GradientStop $slateBase, 1.0
        $brush.GradientStops.Add($sOutA) | Out-Null
        $brush.GradientStops.Add($sLead) | Out-Null
        $brush.GradientStops.Add($sPeak) | Out-Null
        $brush.GradientStops.Add($sTail) | Out-Null
        $brush.GradientStops.Add($sOutB) | Out-Null
        $this.Background = $brush

        $dur = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(700))
        $aLead = New-Object System.Windows.Media.Animation.DoubleAnimation -0.35, 1.05, $dur
        $aPeak = New-Object System.Windows.Media.Animation.DoubleAnimation -0.20, 1.20, $dur
        $aTail = New-Object System.Windows.Media.Animation.DoubleAnimation -0.05, 1.35, $dur
        $sLead.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aLead)
        $sPeak.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aPeak)
        $sTail.BeginAnimation([System.Windows.Media.GradientStop]::OffsetProperty, $aTail)

        # Brighten the cap on top of the sweep - both effects
        # together: cap pulses, sweep travels.
        $cap = if ($owner) { $owner.Resources.Item("accentCap") } else { $null }
        if ($cap) {
            if (-not $this.Resources.Contains("preHoverCapBrush")) {
                $this.Resources.Add("preHoverCapBrush", $cap.Background)
            }
            $brightCap = [System.Windows.Media.Color]::FromRgb(
                [byte]([Math]::Min(255, [int]([Math]::Round($accCol.R + (255 - $accCol.R) * 0.30)))),
                [byte]([Math]::Min(255, [int]([Math]::Round($accCol.G + (255 - $accCol.G) * 0.30)))),
                [byte]([Math]::Min(255, [int]([Math]::Round($accCol.B + (255 - $accCol.B) * 0.30))))
            )
            $cap.Background = New-Object System.Windows.Media.SolidColorBrush $brightCap
        }
    })
    $btnBorder.Add_MouseLeave({
        # Return to whatever the button looked like before we hovered -
        # this might be the accent brush, the VR-Ready green, etc.
        # We captured it on MouseEnter so it's always current.
        # Skip entirely on VR-Ready/installed cards: MouseEnter also
        # skipped, so there's no preHoverBrush, and we must NOT
        # reset to accentHex - that would paint the green button
        # with the original (red/orange/yellow) accent color.
        $owner = $this.Resources.Item("ownerCard")
        if ($owner -and $owner.Tag -eq "vrinstalled") {
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            if ($st -and (Test-ShowDualSplit $st)) {
                # DualMode only: if the cursor is still over the card
                # (moved from button onto the split overlay on top of
                # it), don't tear down - otherwise button-leave/enter
                # oscillate at the boundary and the split flickers. The
                # card-level MouseLeave restores on true tile exit.
                if ($owner.IsMouseOver) { return }
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Collapsed }
                $bt = $owner.Resources.Item("btnText")
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Visible }
            } else {
                # Normal VR Ready: the "Start in VR" reveal now fires on
                # whole-tile hover, so keep it while the cursor is still
                # over the card; the card MouseLeave restores on true exit.
                $bt = $owner.Resources.Item("btnText")
                if ($bt) { $bt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#cdb77a") }
                if ($owner.IsMouseOver) { return }
                if ($bt -and $owner.Resources.Contains("readyOrigText")) {
                    $bt.Text = $owner.Resources.Item("readyOrigText")
                    $owner.Resources.Remove("readyOrigText") | Out-Null
                }
            }
            return
        }
        # vrupdate restore: undo the morph to green Start-in-VR.
        # We stashed the original button bg/border/text on hover,
        # so we just put them back. Match against the same Tag so
        # we don't accidentally apply this branch to a card whose
        # state changed mid-hover.
        if ($owner -and $owner.Tag -eq "vrupdate") {
            # If the cursor is still somewhere over the card (just moved
            # off the button onto the card body), keep the morph - the
            # card-level MouseLeave will restore when it truly leaves the
            # tile. Without this, moving button->card body would flicker
            # the button back to "Update" while still hovering the tile.
            if ($owner.IsMouseOver) { return }
            # Actually leaving the tile: clear the morph flag so the
            # next hover re-arms cleanly.
            if ($owner.Resources.Contains("vrupdMorphed")) {
                $owner.Resources.Remove("vrupdMorphed") | Out-Null
            }
            # DualMode: hide split + show btnText again. The bg/border
            # restore below still runs for normal vrupdate path so we
            # branch only on btnText handling.
            $g = $owner.Resources.Item("gameData")
            $st = $null
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
            }
            if ($st -and (Test-ShowDualSplit $st)) {
                $ds = $owner.Resources.Item("dualSplit")
                if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Collapsed }
                $bt = $owner.Resources.Item("btnText")
                if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Visible }
                # Restore bg/border (no btnText text/colour to undo in
                # DualMode - we only toggled visibility on it).
                $preBg  = $this.Resources.Item("preHoverBrush")
                $preBd  = $this.Resources.Item("preHoverBdBrush")
                $preBdT = $this.Resources.Item("preHoverBdThick")
                if ($preBg)  { $this.Background      = $preBg }
                if ($preBd)  { $this.BorderBrush     = $preBd }
                if ($preBdT) { $this.BorderThickness = $preBdT }
                # Restore + hide the blue update pill.
                $rp = $owner.Resources.Item("reloadPill")
                $rg = $owner.Resources.Item("reloadGlyph")
                if ($rp -and $rg) {
                    $prePillBg  = $this.Resources.Item("preHoverPillBg")
                    $prePillBd  = $this.Resources.Item("preHoverPillBd")
                    $prePillGFg = $this.Resources.Item("preHoverPillGlyphFg")
                    if ($prePillBg)  { $rp.Background  = $prePillBg }
                    if ($prePillBd)  { $rp.BorderBrush = $prePillBd }
                    if ($prePillGFg) { $rg.Foreground  = $prePillGFg }
                $prePillGTx = $this.Resources.Item("preHoverPillGlyphTx")
                if ($prePillGTx) { $rg.Text = $prePillGTx }
                    if ($this.Resources.Contains("preHoverPillBg"))      { $this.Resources.Remove("preHoverPillBg")      | Out-Null }
                    if ($this.Resources.Contains("preHoverPillBd"))      { $this.Resources.Remove("preHoverPillBd")      | Out-Null }
                    if ($this.Resources.Contains("preHoverPillGlyphFg")) { $this.Resources.Remove("preHoverPillGlyphFg") | Out-Null }
                if ($this.Resources.Contains("preHoverPillGlyphTx")) { $this.Resources.Remove("preHoverPillGlyphTx") | Out-Null }
                    $rp.Visibility = [System.Windows.Visibility]::Collapsed
                }
                return
            }
            $preBg     = $this.Resources.Item("preHoverBrush")
            $preBd     = $this.Resources.Item("preHoverBdBrush")
            $preBdT    = $this.Resources.Item("preHoverBdThick")
            $preTxtFg  = $this.Resources.Item("preHoverTxtFg")
            $preTxtTx  = $this.Resources.Item("preHoverTxtText")
            if ($preBg)  { $this.Background      = $preBg }
            if ($preBd)  { $this.BorderBrush     = $preBd }
            if ($preBdT) { $this.BorderThickness = $preBdT }
            $bt = $owner.Resources.Item("btnText")
            if ($bt) {
                if ($preTxtFg) { $bt.Foreground = $preTxtFg }
                if ($preTxtTx) { $bt.Text = $preTxtTx }
            }
            foreach ($stashName in @("preHoverTxtFg","preHoverTxtText")) {
                if ($this.Resources.Contains($stashName)) { $this.Resources.Remove($stashName) | Out-Null }
            }
            # (Update-label brightening on real button hover is handled by
            #  the dedicated btnBorder handlers, not from the tile hover.)
            # Restore + hide the blue update pill that MouseEnter
            # revealed for the non-DualMode vrupdate hover.
            $rp = $owner.Resources.Item("reloadPill")
            $rg = $owner.Resources.Item("reloadGlyph")
            if ($rp -and $rg) {
                $prePillBg  = $this.Resources.Item("preHoverPillBg")
                $prePillBd  = $this.Resources.Item("preHoverPillBd")
                $prePillGFg = $this.Resources.Item("preHoverPillGlyphFg")
                if ($prePillBg)  { $rp.Background  = $prePillBg }
                if ($prePillBd)  { $rp.BorderBrush = $prePillBd }
                if ($prePillGFg) { $rg.Foreground  = $prePillGFg }
                $prePillGTx = $this.Resources.Item("preHoverPillGlyphTx")
                if ($prePillGTx) { $rg.Text = $prePillGTx }
                if ($this.Resources.Contains("preHoverPillBg"))      { $this.Resources.Remove("preHoverPillBg")      | Out-Null }
                if ($this.Resources.Contains("preHoverPillBd"))      { $this.Resources.Remove("preHoverPillBd")      | Out-Null }
                if ($this.Resources.Contains("preHoverPillGlyphFg")) { $this.Resources.Remove("preHoverPillGlyphFg") | Out-Null }
                if ($this.Resources.Contains("preHoverPillGlyphTx")) { $this.Resources.Remove("preHoverPillGlyphTx") | Out-Null }
                $rp.Visibility = [System.Windows.Visibility]::Collapsed
            }
            return
        }
        $pre = $this.Resources.Item("preHoverBrush")
        if ($pre) {
            $this.Background = $pre
        } else {
            # Fallback if MouseEnter never stashed (e.g. animation was
            # interrupted): rebuild from the accent.
            $accH = $this.Resources.Item("accentHex")
            if ($accH) {
                $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accH)
            }
        }
        # Restore the cap to its pre-hover color
        $cap = if ($owner) { $owner.Resources.Item("accentCap") } else { $null }
        if ($cap) {
            $preCap = $this.Resources.Item("preHoverCapBrush")
            if ($preCap) {
                $cap.Background = $preCap
                $this.Resources.Remove("preHoverCapBrush") | Out-Null
            }
        }
    })
    # Info pill: a small horizontal capsule in the top-right of the
    # card, combining the controls dot (left half) and the "i" info
    # symbol (right half). The full pill is clickable -> opens the
    # InfoUrl - so the click target is large enough for VR pointers.
    # Hovering the dot half shows the controls tooltip.
    $hasInfo = [bool]$game.InfoUrl
    $hasDot  = [bool]$game.Controls

    if ($hasInfo -or $hasDot) {
        $pill = New-Object System.Windows.Controls.Border
        $pill.Height = [int](22*$sc)
        $pill.Background = [System.Windows.Media.Brushes]::Transparent
        $pill.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $pill.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
        $pill.Margin = [System.Windows.Thickness]::new(0, [int](8*$sc), [int](8*$sc), 0)
        if ($hasInfo) { $pill.Cursor = [System.Windows.Input.Cursors]::Hand }

        # Two layers so the hover glow never blurs the glyph + "i":
        # the rounded edge + glow live on $pillEdge (no text), the
        # content sits on top as a crisp sibling with no effect.
        $pillGrid = New-Object System.Windows.Controls.Grid
        $pill.Child = $pillGrid

        $pillEdge = New-Object System.Windows.Controls.Border
        $pillEdge.CornerRadius = [System.Windows.CornerRadius]::new([int](11*$sc))
        $pillEdge.Background = [System.Windows.Media.Brushes]::Transparent
        $pillEdge.BorderThickness = [System.Windows.Thickness]::new(1)
        $pillEdge.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#40404e")
        $pillGrid.Children.Add($pillEdge) | Out-Null

        $pillStack = New-Object System.Windows.Controls.StackPanel
        $pillStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $pillStack.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $pillStack.Margin = [System.Windows.Thickness]::new([int](7*$sc), 0, [int](8*$sc), 0)
        $pillGrid.Children.Add($pillStack) | Out-Null

        # Shared brush for the glyph + "i" so a hover can brighten both
        # at once (mutate one Color) - scoped to this pill only.
        $famTxtBrush = New-Object System.Windows.Media.SolidColorBrush $famTxtColor

        if ($hasDot) {
            $ctrlIcon = New-ControlTypeIcon -Controls $game.Controls -Sc $sc -Stroke $famTxtBrush
            $pillStack.Children.Add($ctrlIcon) | Out-Null
        }

        if ($hasInfo -and $hasDot) {
            # Thin separator between dot and "i"
            $sep = New-Object System.Windows.Controls.Border
            $sep.Width = 1
            $sep.Height = [int](11*$sc)
            $sep.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a4a")
            $sep.Margin = [System.Windows.Thickness]::new([int](7*$sc), 0, [int](7*$sc), 0)
            $sep.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $pillStack.Children.Add($sep) | Out-Null
        }

        if ($hasInfo) {
            $infoText = New-Object System.Windows.Controls.TextBlock
            $infoText.Text = "i"
            $infoText.FontSize = [int](12*$sc)
            $infoText.FontStyle = [System.Windows.FontStyles]::Italic
            $infoText.FontWeight = [System.Windows.FontWeights]::Bold
            $infoText.Foreground = $famTxtBrush
            $infoText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
            $infoText.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
            $infoText.Margin = [System.Windows.Thickness]::new(0, [int](-1*$sc), 0, 0)
            $pillStack.Children.Add($infoText) | Out-Null
            $pill.ToolTip = "Open mod page"

            # Hover: the pill lights up. The glyph + "i" brighten to a more
            # luminous accent (via their shared brush) and the text-free
            # edge layer gains a stronger family-hue glow - symbols stay
            # perfectly crisp while the pill clearly pops.
            $famTxtBright = [System.Windows.Media.Color]::FromRgb(
                [byte]([Math]::Round($famTxtColor.R*0.55 + 255*0.45)),
                [byte]([Math]::Round($famTxtColor.G*0.55 + 255*0.45)),
                [byte]([Math]::Round($famTxtColor.B*0.55 + 255*0.45)))
            $pillGlow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $pillGlow.Color = $famAcc
            $pillGlow.BlurRadius = [int](10*$sc)
            $pillGlow.ShadowDepth = 0
            $pillGlow.Opacity = 0.85
            $pillHoverBorder = New-Object System.Windows.Media.SolidColorBrush $famTxtBright
            $pillRestBorder  = $pillEdge.BorderBrush
            $pill.Add_MouseEnter({
                $famTxtBrush.Color = $famTxtBright
                $pillEdge.BorderBrush = $pillHoverBorder
                $pillEdge.Effect = $pillGlow
            }.GetNewClosure())
            $pill.Add_MouseLeave({
                $famTxtBrush.Color = $famTxtColor
                $pillEdge.BorderBrush = $pillRestBorder
                $pillEdge.Effect = $null
            }.GetNewClosure())

            $infoUrlCapture = $game.InfoUrl
            $pill.Add_PreviewMouseLeftButtonDown({
                param($s,$e)
                $e.Handled = $true
                Start-Process $infoUrlCapture
            }.GetNewClosure())
        }

        $overlay = New-Object System.Windows.Controls.Grid
        $overlay.Children.Add($grid) | Out-Null
        $overlay.Children.Add($pill) | Out-Null
        $card.Child = $overlay
        # Stash info pill so steam-preview can hide it during big image
        $card.Resources.Add("infoPill", $pill)
    } else {
        $overlay = New-Object System.Windows.Controls.Grid
        $overlay.Children.Add($grid) | Out-Null
        $card.Child = $overlay
    }

    # Frosted-glass redesign (test): elevation shadow + milky sheen +
    # glass bevel + glowing accent top bar. Additive overlay only -
    # everything above (text/size/handlers/hover) is untouched.
    Add-FrostedGlassTileFx -Card $card -Overlay $overlay -AccentHex $accentHex -Sc $sc

    # ---- Steam preview overlay (any card with a resolvable image) -----
    # A hidden top strip that the hover manager populates with the
    # Steam header image (or a custom HeaderUrl/PortraitUrl if set).
    $cardHeaderUrl = Get-GameImageUrl -Game $game -Kind "header"
    # Prefer the local disk cache if present (offline-capable).
    if ($game.SteamId -and -not $game.HeaderUrl) {
        $cachedCardHdr = Get-CachedImageUri -SteamId $game.SteamId -Kind "header"
        if ($cachedCardHdr) { $cardHeaderUrl = $cachedCardHdr }
    }
    if ($cardHeaderUrl) {
        # We store the resolved URL (not the raw SteamId) so the
        # preview manager doesn't need to know about overrides.
        # SteamId is also stored so the preview can fall back to
        # the Fastly CDN if Akamai 404s.
        $card.Resources.Add("previewHeaderUrl", $cardHeaderUrl)
        # Store SteamId only for games that actually use Steam artwork.
        # Cards with a bundled HeaderUrl (e.g. Halo CE, whose SteamId is
        # the unrelated MCC) get $null here so the hover's cache re-resolve
        # and fastly fallback never replace the bundled art with the wrong
        # game's Steam image.
        $card.Resources.Add("previewSteamId",   $(if ($game.HeaderUrl) { "" } else { $game.SteamId }))
        # Portrait fallback URL - mirrors the detail hero's chain so a
        # game whose header.jpg fails on BOTH CDNs still shows something
        # on hover (the detail page already falls back to portrait; the
        # hover banner used to have no portrait step and went blank).
        $card.Resources.Add("previewPortraitUrl", (Get-GameImageUrl -Game $game -Kind "portrait"))
        $card.Resources.Add("hasVideo",         [bool]$game.HasVideo)
    }

    # ---- Hot zone: click body -> Discover detail; hover -> preview ---
    # Transparent border covering the central body of the card,
    # excluding the pill area at the top and Install button at the
    # bottom. Click on this zone jumps to the Discover detail view.
    # Hovering arms the Steam-preview timer for SteamId cards.
    # Hot-zone covers the central body of the card. Top is 34px to
    # leave room for the family-pill area; bottom is 32px for the
    # install button. Right edge goes all the way - the small
    # "pill protection" zone below sits above this in the visual
    # tree to prevent the hover-preview from arming when the user
    # is heading toward the info pill.
    $hotZone = New-Object System.Windows.Controls.Border
    $hotZone.Background = [System.Windows.Media.Brushes]::Transparent
    $hotZone.IsHitTestVisible = $true
    $hotZone.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $hotZone.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    # Bottom margin must clear the install button so card-body
    # clicks (-> Description) never steal the button's hit-test,
    # but stay below the description text. 32*$sc was too low
    # (button-top stole by hotZone), 50*$sc was too high
    # (hotZone gave up half the description line). 41*$sc is the
    # midpoint that lands cleanly between the two.
    $hotZone.Margin = [System.Windows.Thickness]::new(0, [int](34*$sc), 0, [int](41*$sc))
    $hotZone.Cursor = [System.Windows.Input.Cursors]::Hand
    $hotZone.Tag = @{ Game = $game; Card = $card }

    # Activate the hover preview only on cards we have an image for.
    # We check the URL stash that was set up earlier in this function.
    if ($card.Resources.Contains("previewHeaderUrl")) {
        $hotZone.Add_MouseEnter({
            if (Test-CardHoverSuppressed) { return }
            $info = $this.Tag
            if (-not $info) { return }
            $global:HoverPendingCard = $info.Card
            if ($global:HoverTimer) { try { $global:HoverTimer.Stop() } catch { } }
            $global:HoverTimer = New-Object System.Windows.Threading.DispatcherTimer
            $global:HoverTimer.Interval = [TimeSpan]::FromMilliseconds($global:HoverDelayMs)
            $global:HoverTimer.Add_Tick({
                $global:HoverTimer.Stop()
                if ($global:HoverPendingCard) {
                    # Don't pop the preview if the cursor has already moved
                    # onto the Install button - popping it would shift the
                    # button down and turn the intended click into a
                    # description click.
                    $bb = $global:HoverPendingCard.Resources.Item("btnBorder")
                    if ($bb -and $bb.IsMouseOver) { $global:HoverPendingCard = $null; return }
                    Start-CardPreview -Card $global:HoverPendingCard
                    $global:HoverPendingCard = $null
                }
            })
            $global:HoverTimer.Start()
        })
    }

    # PreviewMouseLeftButtonDown (tunneling) so we fire BEFORE the
    # card's own MouseLeftButtonDown installer handler. Mark the
    # event handled so the installer never fires for body clicks.
    $hotZone.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        $info = $s.Tag
        if (-not $info -or -not $info.Game) { return }
        $e.Handled = $true
        # Fire the pulsing green border glow as immediate visual
        # confirmation. Show-DiscoverDetail can take a couple of
        # seconds on the first click of a session (Steam library
        # registry walk, header image fetch). Without this, the
        # user sees nothing happen and re-clicks.
        #
        # CRITICAL: Open-DiscoverDetailFromList is a heavy synchronous
        # call that hogs the UI thread for 1-3 seconds. If we call
        # it inline here, the animation is *started* but WPF never
        # gets to render a single frame of it - rendering only
        # resumes once the dispatcher unwinds. The visible result:
        # glow flashes when the detail view closes, sometimes the
        # green border gets stuck.
        # Fix: kick off the glow, then defer the heavy call to the
        # next dispatcher tick at Background priority. This lets
        # the Render pass (priority above Background but below
        # Normal) commit a handful of glow frames before the heavy
        # work begins. The user perceives instant feedback even
        # though the actual navigation happens ~16-32ms later.
        Start-CardClickGlowThenOpen -Card $info.Card -Game $info.Game
    })

    $overlay.Children.Add($hotZone) | Out-Null
    [System.Windows.Controls.Panel]::SetZIndex($hotZone, 5)
    $card.Resources.Add("hotZone", $hotZone)

    # Pill-protection zone: covers only the top-right corner where
    # the info pill sits, so mouse paths heading toward the pill
    # don't arm the hover-preview timer. Limited to roughly the
    # top third of the card height + a 50px wide right strip.
    # ZIndex order is: hotZone(5) < pillGuard(10) < pill(20).
    # That way pill clicks pass through pillGuard, but pillGuard
    # blocks hotZone from arming the hover timer in this corner.
    $pillGuard = New-Object System.Windows.Controls.Border
    $pillGuard.Background = [System.Windows.Media.Brushes]::Transparent
    $pillGuard.IsHitTestVisible = $true
    $pillGuard.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $pillGuard.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
    $pillGuard.Width  = [int](50*$sc)
    $pillGuard.Height = [int](40*$sc)
    # pillGuard is 40px tall but topShield only covers the top 34px, so
    # a 6px x 50px band under the info pill had pillGuard (Z=10) on top
    # of hotZone (Z=5) with NO click handler of its own - clicks there
    # bubbled to the card and hit the install fallback. Route them to
    # the detail page exactly like topShield does. The info pill sits at
    # Z=20 above this, so its own click still opens the info page.
    $pillGuard.Cursor = [System.Windows.Input.Cursors]::Hand
    $pillGuard.Tag = @{ Game = $game; Card = $card }
    $pillGuard.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        $info = $s.Tag
        if (-not $info -or -not $info.Game) { return }
        $e.Handled = $true
        Start-CardClickGlowThenOpen -Card $info.Card -Game $info.Game
    })
    $overlay.Children.Add($pillGuard) | Out-Null
    [System.Windows.Controls.Panel]::SetZIndex($pillGuard, 10)
    # If the info pill exists, lift it above the guard so clicks reach it.
    if ($card.Resources.Contains("infoPill")) {
        [System.Windows.Controls.Panel]::SetZIndex($card.Resources.Item("infoPill"), 20)
    }

    # Click shield over the top strip (family badge + info-pill row).
    # The hot zone leaves this strip out, and nothing else handles
    # clicks there, so they used to fall through to the card-level
    # installer (clicking near the family tag started an install).
    # Route those clicks to the detail page instead - only the
    # explicit Install button should install. The info pill (ZIndex
    # 20) stays above this shield so its own click still works, and
    # there is deliberately no MouseEnter here so the hover preview
    # is never armed from this strip.
    $topShield = New-Object System.Windows.Controls.Border
    $topShield.Background = [System.Windows.Media.Brushes]::Transparent
    $topShield.IsHitTestVisible = $true
    $topShield.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $topShield.VerticalAlignment   = [System.Windows.VerticalAlignment]::Top
    $topShield.Height = [int](34*$sc)
    $topShield.Cursor = [System.Windows.Input.Cursors]::Hand
    $topShield.Tag = @{ Game = $game; Card = $card }
    $topShield.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        $info = $s.Tag
        if (-not $info -or -not $info.Game) { return }
        $e.Handled = $true
        Start-CardClickGlowThenOpen -Card $info.Card -Game $info.Game
    })
    $overlay.Children.Add($topShield) | Out-Null
    [System.Windows.Controls.Panel]::SetZIndex($topShield, 11)
    # Keep the info pill above the new shield so its own click still fires.
    if ($card.Resources.Contains("infoPill")) {
        [System.Windows.Controls.Panel]::SetZIndex($card.Resources.Item("infoPill"), 20)
    }

    # ---- Hover lift (frosted tiles only) ---------------------------
    # No cursor-following (that read as distracting drift) and no skew
    # (that distorted). Just a small UNIFORM lift on hover: the card
    # scales up a touch, stays rectangular and centred. Yields to the
    # hover-preview - once that is active ($global:HoverActiveCard) the
    # preview owns the RenderTransform (1.4x + Steam art), so this lift
    # only shows in the brief window before the preview overlay appears.
    # Core System.Windows.Media types (real WPF). Not testable on Linux.
    $tiltScale = New-Object System.Windows.Media.ScaleTransform 1.0, 1.0
    $card.Add_MouseEnter({
        param($s, $e)
        if (Test-CardHoverSuppressed) { return }
        if ($global:HoverActiveCard) { return }   # preview owns the transform
        try {
            $tiltScale.ScaleX = 1.06; $tiltScale.ScaleY = 1.06
            $s.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
            $s.RenderTransform = $tiltScale
            # Ember sparks behind the text (TEST). Particles are separate
            # Ellipse elements on a Canvas placed BEHIND the text (ZIndex -1)
            # inside $grid - NO card DropShadowEffect, so the title stays
            # crisp (unlike the glow). Hover-only, this card only; MouseLeave
            # tears them down. ~6 = subtle. All core WPF types.
            if (-not $s.Resources.Contains("sparkCanvas")) {
                $cw = [double]$s.ActualWidth; $ch = [double]$s.ActualHeight
                if ($cw -gt 10 -and $ch -gt 10) {
                    $sCanvas = New-Object System.Windows.Controls.Canvas
                    $sCanvas.ClipToBounds = $true
                    $sCanvas.IsHitTestVisible = $false
                    [System.Windows.Controls.Grid]::SetRow($sCanvas, 0)
                    [System.Windows.Controls.Grid]::SetRowSpan($sCanvas, 3)
                    [System.Windows.Controls.Panel]::SetZIndex($sCanvas, -1)
                    $grid.Children.Add($sCanvas) | Out-Null
                    $s.Resources.Add("sparkCanvas", $sCanvas)
                    $rise = [Math]::Min(72.0, $ch - 18.0)
                    for ($si = 0; $si -lt 6; $si++) {
                        $sx  = Get-Random -Minimum 6 -Maximum ([int][Math]::Max(8, $cw - 6))
                        $dur = (Get-Random -Minimum 2800 -Maximum 4300) / 1000.0
                        $beg = (Get-Random -Minimum 0 -Maximum 2600) / 1000.0
                        $sz  = Get-Random -Minimum 3 -Maximum 5
                        $el = New-Object System.Windows.Shapes.Ellipse
                        $el.Width = $sz; $el.Height = $sz; $el.Opacity = 0.0
                        $rg = New-Object System.Windows.Media.RadialGradientBrush
                        $rg.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(255,255,190,120), 0.0))) | Out-Null
                        $rg.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(180,255,140,46), 0.55))) | Out-Null
                        $rg.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,255,120,30), 1.0))) | Out-Null
                        $el.Fill = $rg
                        $tt = New-Object System.Windows.Media.TranslateTransform 0, 0
                        $el.RenderTransform = $tt
                        [System.Windows.Controls.Canvas]::SetLeft($el, [double]$sx)
                        [System.Windows.Controls.Canvas]::SetTop($el, $ch - 14.0)
                        $sCanvas.Children.Add($el) | Out-Null
                        $yAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
                        $yAnim.From = 0.0; $yAnim.To = -$rise
                        $yAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromSeconds($dur))
                        $yAnim.BeginTime = [TimeSpan]::FromSeconds($beg)
                        $yAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                        $oAnim = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
                        $oAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromSeconds($dur))
                        $oAnim.BeginTime = [TimeSpan]::FromSeconds($beg)
                        $oAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                        $oAnim.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame (0.0, [System.Windows.Media.Animation.KeyTime]::FromPercent(0.0)))) | Out-Null
                        $oAnim.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame (0.85, [System.Windows.Media.Animation.KeyTime]::FromPercent(0.18)))) | Out-Null
                        $oAnim.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame (0.0, [System.Windows.Media.Animation.KeyTime]::FromPercent(1.0)))) | Out-Null
                        $el.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oAnim)
                        $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $yAnim)
                    }
                }
            }
        } catch { }
    }.GetNewClosure())
    $card.Add_MouseLeave({
        param($s, $e)
        try {
            if ($global:HoverActiveCard -ne $s) { $s.RenderTransform = $null }
            $tiltScale.ScaleX = 1.0; $tiltScale.ScaleY = 1.0
            # Hard cleanup of the spark particles so nothing "sticks".
            if ($s.Resources.Contains("sparkCanvas")) {
                $sCanvas = $s.Resources.Item("sparkCanvas")
                try {
                    foreach ($pEl in @($sCanvas.Children)) {
                        $pEl.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
                        if ($pEl.RenderTransform) {
                            $pEl.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $null)
                        }
                    }
                    $sCanvas.Children.Clear()
                    if ($grid.Children.Contains($sCanvas)) { $grid.Children.Remove($sCanvas) }
                } catch { }
                $s.Resources.Remove("sparkCanvas")
            }
        } catch { }
    }.GetNewClosure())
    # Hover: rebuild a slightly stronger tint gradient on enter, restore
    # the stored base brush on leave. Tag determines which accent / base
    # combination is currently in play (default / vrinstalled / vrupdate).
    $card.Add_MouseEnter({
        if (Test-CardHoverSuppressed) { return }
        $tag = $this.Tag
        $acc = $this.Resources.Item("baseAccent")
        if (-not $acc) { return }
        if ($tag -eq "vrinstalled") {
            # VR Ready: drop the permanent (frozen) top glow to the flat
            # base, then re-create it as a softly pulsing top-centre blob
            # via -TopGlow, so the original glow stays (a touch darker) and
            # breathes in phase with the left spot instead of the whole
            # lighting switching. MouseLeave restores the full radial glow.
            $this.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb([byte]12, [byte]12, [byte]16))
            Set-CardHoverSpotlights -Card $this -AccentHex "#46a05a" -TopGlow
            # Only DualMode cards (Current|Depot split) get the morph on
            # whole-tile enter - the split otherwise only shows on direct
            # button hover and flickers at the boundary. Normal VR Ready
            # cards keep their "Start in VR" swap on direct button hover
            # ONLY (raising it tile-wide felt wrong - user feedback).
            $g = $this.Resources.Item("gameData")
            $isDual = $false
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
                if ($st -and (Test-ShowDualSplit $st)) { $isDual = $true }
            }
            if ($true) {  # every VR-Ready card reveals on whole-tile hover now (was DualMode only)
                $bb = $this.Resources.Item("btnBorder")
                if ($bb) {
                    try {
                        $ev = New-Object System.Windows.Input.MouseEventArgs(
                            [System.Windows.Input.Mouse]::PrimaryDevice, 0)
                        $ev.RoutedEvent = [System.Windows.Input.Mouse]::MouseEnterEvent
                        $bb.RaiseEvent($ev)
                    } catch { }
                }
            }
        } elseif ($tag -eq "vrupdate") {
            Set-CardHoverSpotlights -Card $this -AccentHex $acc
            # Reveal the update-state companion action across the whole tile:
            # Play for a single launch choice, or the exact Update action when
            # the main button is a visible two-way launch split.
            $bb = $this.Resources.Item("btnBorder")
            if ($bb -and -not $this.Resources.Contains("vrupdMorphed")) {
                try {
                    $ev = New-Object System.Windows.Input.MouseEventArgs(
                        [System.Windows.Input.Mouse]::PrimaryDevice, 0)
                    $ev.RoutedEvent = [System.Windows.Input.Mouse]::MouseEnterEvent
                    $bb.RaiseEvent($ev)
                } catch { }
            }
        } else {
            Set-CardHoverSpotlights -Card $this -AccentHex $acc
        }
    })
    $card.Add_MouseLeave({
        Clear-CardHoverSpotlights -Card $this
        $stored = $this.Resources.Item("baseBgBrush")
        if ($stored) { $this.Background = $stored }
        # Whole-tile leave: restore the update companion / DualMode split via
        # the button's own MouseLeave (IsMouseOver is now false).
        $needLeave = $false
        if ($this.Tag -eq "vrupdate" -and $this.Resources.Contains("vrupdMorphed")) {
            $needLeave = $true
        } elseif ($this.Tag -eq "vrinstalled") {
            $g = $this.Resources.Item("gameData")
            if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                $st = $global:gameStateMap[$g.Title]
                $needLeave = $true  # every VR-Ready card reveals tile-wide now
            }
        }
        if ($needLeave) {
            $bb = $this.Resources.Item("btnBorder")
            if ($bb) {
                try {
                    $ev = New-Object System.Windows.Input.MouseEventArgs(
                        [System.Windows.Input.Mouse]::PrimaryDevice, 0)
                    $ev.RoutedEvent = [System.Windows.Input.Mouse]::MouseLeaveEvent
                    $bb.RaiseEvent($ev)
                } catch { }
            }
        }
        # Cancel any pending preview activation, tear down current
        if ($global:HoverTimer) { try { $global:HoverTimer.Stop() } catch { } }
        $global:HoverPendingCard = $null
        if ($global:HoverActiveCard -eq $this) { End-CardPreview }
    })

    # Click
    if ($isExternal) {
        $urlCapture         = $game.Url
        $typeCapture        = $game.Type
        $downloadCapture    = if ($game.DownloadUrl) { $game.DownloadUrl } else { $null }
        $infoUrlExtCapture  = if ($game.InfoUrl) { $game.InfoUrl } else { $null }
        $directDlCapture    = if ($game.DirectDownload) { $game.DirectDownload } else { $null }
        $gameCapture        = $game
        $cardCapture        = $card
        $card.Add_MouseLeftButtonDown({
            # VR Ready state: launch the game via Steam (or LaunchExe
            # if the entry has one). Same behaviour as non-external
            # vrinstalled cards - the card flips into "Start in VR"
            # mode and clicking should play, not reopen the mod page.
            if ($cardCapture.Tag -eq "vrinstalled") {
                Start-GameInVR -Game $gameCapture
                return
            }
            # Wabbajack-based entries: clicking just opens the
            # Wabbajack site. No download is triggered by us and
            # no Downloads folder needs opening - Wabbajack handles
            # everything itself once the user grabs it.
            if ($gameCapture.WabbajackUrl) {
                Start-Process $gameCapture.WabbajackUrl
                return
            }
            if ($directDlCapture) {
                Start-Process $directDlCapture
            } elseif ($typeCapture -ne "steam") {
                # Skip the Downloads-folder pre-open for entries
                # whose Url is just a Discord invite - no download
                # is actually triggered, so the explorer window
                # would just clutter the desktop. Also skip for
                # Vivecraft: vivecraft.org/downloads is several
                # clicks deep (pick a Minecraft version, then
                # Forge/Fabric, then the file) so the user won't
                # see the Downloads folder for a while.
                $isDiscordOnly = $urlCapture -and ($urlCapture -match "discord\.com|discord\.gg")
                $isVivecraft   = ($gameCapture.Title -eq "Vivecraft")
                # steam:// links (e.g. a beta-branch switch via
                # steam://gameproperties/<id>) don't download anything
                # to the Downloads folder - they just open Steam - so
                # opening Explorer would only clutter the desktop.
                $isSteamProtocol = $downloadCapture -and ($downloadCapture -match "^steam://")
                # Only pre-open the Downloads folder when we are actually
                # about to trigger a download (DownloadUrl set). Page-only
                # external entries - those that just open a mod/downloads
                # page in the browser for a manual grab (e.g. X-Wing VR /
                # XWVM) - have no DownloadUrl, so nothing lands in Downloads
                # and the explorer window would only clutter the desktop.
                if ($downloadCapture -and -not $isDiscordOnly -and -not $isVivecraft -and -not $isSteamProtocol) {
                    $downloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
                    try { Start-Process explorer.exe "`"$downloadsPath`"" } catch {}
                    Start-Sleep -Milliseconds 400
                }
                if ($downloadCapture) {
                    $resolvedUrl = $downloadCapture
                    # If it's a GitHub API URL, resolve the actual asset download URL
                    if ($downloadCapture -match "api.github.com") {
                        try {
                            $apiUrl = $downloadCapture
                            $response = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "VRModHub" } -TimeoutSec 8 -ErrorAction Stop
                            # If response is array (all releases), pick first (newest) with assets
                            if ($response -is [array]) {
                                $release = $response | Where-Object { $_.assets.Count -gt 0 } | Select-Object -First 1
                            } else {
                                $release = $response
                            }
                            $exeAsset = $release.assets | Where-Object { $_.name -match "\.(exe|zip)$" } | Select-Object -First 1
                            if ($exeAsset) { $resolvedUrl = $exeAsset.browser_download_url }
                        } catch {}
                    }
                    Start-Process $resolvedUrl
                }
            }
            # Open the catalog Url too - but for Vivecraft, skip this:
            # DownloadUrl already opened the downloads page above, and
            # opening Url after would push the homepage on top of it,
            # hiding the per-version download list the user actually
            # needs.
            if ($gameCapture.Title -ne "Vivecraft" -and $urlCapture) {
                Start-Process $urlCapture
            }
            # Info page is opened only via the i button, not automatically here
        }.GetNewClosure())
    } elseif ($game.DirectDownload) {
        $dlCapture = $game.DirectDownload
        $card.Add_MouseLeftButtonDown({
            Start-Process $dlCapture
        }.GetNewClosure())
    } else {
        $batPath = Join-Path $scriptDir $game.Bat
        if (Test-Path $batPath) {
            $batCapture    = $batPath
            $titleCapture  = $game.Title
            $folderCapture = if ($game.SteamFolder) { $game.SteamFolder } else { "" }
            $exeCapture    = if ($game.GameExe) { $game.GameExe } else { "" }
            # REFramework family marker is the shared launcher path,
            # NOT the mere presence of GameExe - several non-RE
            # entries (KSP, Another Crab's Treasure) carry a GameExe
            # for shortcut/launch purposes and must route to their
            # own START_INSTALLER.bat instead of REFrameworkVR-core.ps1.
            $isRefCapture  = ($game.Bat -like "REFrameworkVR\*")
            $gameCapture   = $game
            $cardCapture   = $card

            # Direct btnBorder click handler: catches Start-in-VR clicks
            # at the button itself, before they bubble to the card. On
            # Virtual Desktop, the first click after VR-Ready -> Start-
            # in-VR hover-morph could get swallowed because the visual
            # tree re-allocates mid-bubble. Handling at the source with
            # e.Handled = $true sidesteps that race. The card-level
            # handler below still runs for the body / install button.
            $btnBorder.Add_MouseLeftButtonDown({
                param($s, $e)
                if ($cardCapture.Tag -eq "vrinstalled") {
                    $e.Handled = $true
                    Start-GameInVR -Game $gameCapture
                    return
                }
            }.GetNewClosure())

            $card.Add_MouseLeftButtonDown({
                # VR Ready state: clicking the card launches the
                # game via Start-GameInVR (uses the recorded
                # install path + LaunchExe + LaunchArgs). Reinstall
                # is handled by the small reload pill on the right
                # of the button (which sets e.Handled = $true to
                # stop this card-level handler from firing).
                if ($cardCapture.Tag -eq "vrinstalled") {
                    Start-GameInVR -Game $gameCapture
                    return
                }
                # Update state follows the same explicit layout helper used by
                # the visual: a single main action installs; a split main action
                # launches (its child halves normally consume the click first).
                if ($cardCapture.Tag -eq "vrupdate") {
                    $stForCard = $null
                    if ($global:gameStateMap.ContainsKey($gameCapture.Title)) {
                        $stForCard = $global:gameStateMap[$gameCapture.Title]
                    }
                    $updateLayoutForCard = Get-CardUpdateActionLayout -State $stForCard
                    if ($updateLayoutForCard.MainAction -eq 'PlaySplit') {
                        # Resolve DualMode preference: if the card is
                        # dual-mode the primary action is "Current".
                        if ($stForCard -and $stForCard.DualMode) {
                            Start-GameInVR -Game $gameCapture -Mode "Current"
                        } else {
                            Start-GameInVR -Game $gameCapture
                        }
                        return
                    }
                    # Single-choice blue Update button: wipe the stored version
                    # so the next scan persists the newly installed release.
                    Clear-UpdateOkMarker -Game $gameCapture
                }
                # Launch the installer and capture the process so
                # we can refresh state when it exits. Same auto-
                # refresh polling pattern used in the detail view's
                # primary button - whichever surface launched the
                # installer wins.
                # Launch through the logging wrapper so the installer's console
                # output is saved to Logs\<Title>-<timestamp>.log. Branch logic
                # (LukeRoss / REFramework / standard) lives in one place now:
                # Start-LoggedInstaller (Helpers.ps1).
                $updateChoice = Get-InstallerChoiceForUpdate -Game $gameCapture
                $launchedProc = Start-LoggedInstaller -Game $gameCapture -BatPath $batCapture -RequiresAdmin:([bool]$gameCapture.RequiresAdmin) -InstallerChoice $updateChoice
                if ($launchedProc) {
                    $global:PendingInstallTitle = $titleCapture
                    try {
                        $timer = New-Object System.Windows.Threading.DispatcherTimer
                        $timer.Interval = [TimeSpan]::FromMilliseconds(750)
                        $timer.Tag = $launchedProc
                        $timer.Add_Tick({
                            param($s, $e)
                            $proc = $s.Tag
                            if (Test-InstallerRefreshReady -Process $proc) {
                                try { $s.Stop() } catch {}
                                Invoke-PostInstallRefreshSafely
                            }
                        })
                        $timer.Start()
                    } catch {}
                } else {
                    # No process handle came back (e.g. an elevation that hands
                    # us no object): watch this ONE game's install marker instead,
                    # so the list still updates without a whole-PC scan.
                    try { Watch-InstallMarkerForRefresh -Game $gameCapture } catch {}
                }
            }.GetNewClosure())

            # Reload pill click: triggers a reinstall, and marks
            # the event Handled so the card-level click (Start in
            # VR for VR Ready cards) does not also fire.
            $reloadPill.Add_MouseLeftButtonDown({
                param($s, $e)
                $e.Handled = $true
                # Update state has two intentional layouts. With one visible
                # launch choice this is the Play pill; with a visible split it
                # remains the installer for the exact stale mod.
                if ($cardCapture.Tag -eq "vrupdate") {
                    $updateStateForPill = $null
                    if ($global:gameStateMap.ContainsKey($gameCapture.Title)) {
                        $updateStateForPill = $global:gameStateMap[$gameCapture.Title]
                    }
                    $updateLayoutForPill = Get-CardUpdateActionLayout -State $updateStateForPill
                    if ($updateLayoutForPill.PillAction -eq 'Play') {
                        Start-GameInVR -Game $gameCapture
                        return
                    }
                }
                # Split update / normal reinstall: clear stored version so the
                # next Check-Installed scan persists the new version
                # after the installer runs. Matches the card-level
                # click handler's behaviour for the Update path.
                if ($cardCapture.Tag -eq "vrupdate") {
                    try { Clear-UpdateOkMarker -Game $gameCapture } catch { }
                }
                # Launch + capture the process so we can auto-refresh
                # this card's state when the installer exits (same
                # poll pattern as the card-body click). Without this
                # the card kept showing "Update" after an update.
                $updateChoice = Get-InstallerChoiceForUpdate -Game $gameCapture
                $plProc = Start-LoggedInstaller -Game $gameCapture -BatPath $batCapture -RequiresAdmin:([bool]$gameCapture.RequiresAdmin) -InstallerChoice $updateChoice
                if ($plProc) {
                    $global:PendingInstallTitle = $titleCapture
                    try {
                        $plTimer = New-Object System.Windows.Threading.DispatcherTimer
                        $plTimer.Interval = [TimeSpan]::FromMilliseconds(750)
                        $plTimer.Tag = $plProc
                        $plTimer.Add_Tick({
                            param($ts, $te)
                            $tp = $ts.Tag
                            if (Test-InstallerRefreshReady -Process $tp) {
                                try { $ts.Stop() } catch {}
                                Invoke-PostInstallRefreshSafely
                            }
                        })
                        $plTimer.Start()
                    } catch {}
                } else {
                    # No process handle came back (e.g. an elevation that hands
                    # us no object): watch this ONE game's install marker instead,
                    # so the list still updates without a whole-PC scan.
                    try { Watch-InstallMarkerForRefresh -Game $gameCapture } catch {}
                }
            }.GetNewClosure())

            # VR Ready hover: swap "VR Ready" -> "Start in VR" while
            # the cursor is over the button. The light-sweep effect
            # is already skipped for vrinstalled cards (see the
            # btnBorder MouseEnter handler above) so there's no
            # animation conflict.
            $btnBorder.Add_MouseEnter({
                $owner = $this.Resources.Item("ownerCard")
                if ($owner -and $owner.Tag -eq "vrinstalled") {
                    $g = $owner.Resources.Item("gameData")
                    $st = $null
                    if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                        $st = $global:gameStateMap[$g.Title]
                    }
                    if ($st -and (Test-ShowDualSplit $st)) {
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Hidden }
                        $ds = $owner.Resources.Item("dualSplit")
                        if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Visible }
                    } else {
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt -and -not $owner.Resources.Contains("readyOrigText")) {
                            $owner.Resources.Add("readyOrigText", $bt.Text)
                            $bt.Text = "Start in VR"
                        }
                    }
                    $rp = $owner.Resources.Item("reloadPill")
                    if ($rp) { $rp.Visibility = [System.Windows.Visibility]::Visible }
                }
            }.GetNewClosure())
            $btnBorder.Add_MouseLeave({
                $owner = $this.Resources.Item("ownerCard")
                if ($owner -and $owner.Tag -eq "vrinstalled") {
                    $g = $owner.Resources.Item("gameData")
                    $st = $null
                    if ($g -and $global:gameStateMap.ContainsKey($g.Title)) {
                        $st = $global:gameStateMap[$g.Title]
                    }
                    if ($st -and (Test-ShowDualSplit $st)) {
                        # DualMode only: keep the split while the cursor
                        # is still over the card (anti-flicker). Card
                        # MouseLeave restores on true tile exit.
                        if ($owner.IsMouseOver) { return }
                        $ds = $owner.Resources.Item("dualSplit")
                        if ($ds) { $ds.Visibility = [System.Windows.Visibility]::Collapsed }
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt) { $bt.Visibility = [System.Windows.Visibility]::Visible }
                        $rp = $owner.Resources.Item("reloadPill")
                        if ($rp) { $rp.Visibility = [System.Windows.Visibility]::Collapsed }
                    } else {
                        # Normal VR Ready: reveal fires tile-wide now, so
                        # keep "Start in VR" + the Reinstall pill while the
                        # cursor is over the card; card MouseLeave restores.
                        if ($owner.IsMouseOver) { return }
                        $bt = $owner.Resources.Item("btnText")
                        if ($bt -and $owner.Resources.Contains("readyOrigText")) {
                            $bt.Text = $owner.Resources.Item("readyOrigText")
                            $owner.Resources.Remove("readyOrigText") | Out-Null
                        }
                        $rp = $owner.Resources.Item("reloadPill")
                        if ($rp) { $rp.Visibility = [System.Windows.Visibility]::Collapsed }
                    }
                }
            }.GetNewClosure())
        }
    }

    return $card
}
