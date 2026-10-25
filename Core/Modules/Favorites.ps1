# Persistent, game-ID based favorites. A favorite is independent of the
# installation state and remains valid for games that are not installed.
$global:FavoriteGameIds = @(
    Get-HubSetting -Key 'favoriteGameIds' -Default @() |
        ForEach-Object { [string]$_ } | Where-Object { $_ } | Select-Object -Unique
)
$script:FavoritePink = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#ff5b91')
$script:FavoriteOutline = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#bd396a')
$script:FavoriteCoreDir = Split-Path -Parent $PSScriptRoot
$script:FavoritePendingSave = $null
$script:FavoriteSaveWorker = $null
$script:FavoriteSaveTimer = $null

# State writes can wait on the shared state mutex and copy the recovery file.
# Keep both operations off the WPF thread; a timer coalesces rapid toggles and
# only one worker may write at a time, so an older click cannot win a race.
function global:Queue-FavoriteSave {
    $script:FavoritePendingSave = @($global:FavoriteGameIds)
    if (-not $script:FavoriteSaveTimer) {
        $script:FavoriteSaveTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $script:FavoriteSaveTimer.Interval = [TimeSpan]::FromMilliseconds(80)
        $script:FavoriteSaveTimer.Add_Tick({ Start-PendingFavoriteSave })
    }
    $script:FavoriteSaveTimer.Start()
}

function global:Start-PendingFavoriteSave {
    if ($script:FavoriteSaveWorker) {
        if (-not $script:FavoriteSaveWorker.Handle.IsCompleted) { return }
        try { [void]$script:FavoriteSaveWorker.PS.EndInvoke($script:FavoriteSaveWorker.Handle) } catch { }
        $script:FavoriteSaveWorker.PS.Dispose()
        $script:FavoriteSaveWorker = $null
    }
    if ($null -eq $script:FavoritePendingSave) { $script:FavoriteSaveTimer.Stop(); return }
    $ids = @($script:FavoritePendingSave)
    $script:FavoritePendingSave = $null
    $core = if ($global:scriptDir) { [string]$global:scriptDir } else { $script:FavoriteCoreDir }
    $stateModule = Join-Path $core 'Modules\HubState.ps1'
    $worker = [PowerShell]::Create()
    [void]$worker.AddScript({
        param($modulePath, $coreDir, $stateRoot, $portableRoot, $legacyRoot, $runtimeRoot, $favoriteIds)
        $global:scriptDir = $coreDir
        if ($stateRoot) { $global:HubStateRootOverride = $stateRoot }
        if ($portableRoot) { $global:HubPortableStateRootOverride = $portableRoot }
        if ($legacyRoot) { $global:HubLegacyPortableStateRootOverride = $legacyRoot }
        if ($runtimeRoot) { $global:HubRuntimeRootOverride = $runtimeRoot }
        . $modulePath
        Write-PersistentHubSetting -Key 'favoriteGameIds' -Value @($favoriteIds)
    }).AddArgument($stateModule).AddArgument($core).
        AddArgument($global:HubStateRootOverride).AddArgument($global:HubPortableStateRootOverride).
        AddArgument($global:HubLegacyPortableStateRootOverride).AddArgument($global:HubRuntimeRootOverride).
        AddArgument([string[]]$ids)
    try {
        $script:FavoriteSaveWorker = [pscustomobject]@{ PS = $worker; Handle = $worker.BeginInvoke() }
    } catch {
        $worker.Dispose()
        $script:FavoritePendingSave = $ids
    }
}

function global:Complete-FavoriteSave {
    if ($script:FavoriteSaveTimer) { $script:FavoriteSaveTimer.Stop() }
    if ($script:FavoriteSaveWorker) {
        try { [void]$script:FavoriteSaveWorker.PS.EndInvoke($script:FavoriteSaveWorker.Handle) } catch { }
        $script:FavoriteSaveWorker.PS.Dispose()
        $script:FavoriteSaveWorker = $null
    }
    # The window has already closed. Commit only a still-pending click here;
    # always writing our whole snapshot on close could overwrite a change
    # saved by another open Hub instance.
    if ($null -ne $script:FavoritePendingSave) {
        Write-PersistentHubSetting -Key 'favoriteGameIds' -Value @($script:FavoritePendingSave)
    }
    $script:FavoritePendingSave = $null
}

function global:Test-GameFavorite {
    param($Game)
    return [bool]($Game -and $Game.Id -and (@($global:FavoriteGameIds) -contains [string]$Game.Id))
}

function global:Set-GameFavorite {
    param($Game, [bool]$Favorite)
    if (-not $Game -or -not $Game.Id) { return $false }
    $id = [string]$Game.Id
    $wasFavorite = Test-GameFavorite -Game $Game
    if ($wasFavorite -eq $Favorite) { return $Favorite }
    if ($Favorite) { $global:FavoriteGameIds = @($global:FavoriteGameIds) + $id }
    else { $global:FavoriteGameIds = @($global:FavoriteGameIds | Where-Object { $_ -ne $id }) }
    Queue-FavoriteSave
    # Repainting every visible card before the click returns delays the first
    # rendered frame. The clicked card gets its animation immediately below.
    if ($global:window) {
        $syncId = $id
        [void]$global:window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background,
            [action]({ Sync-FavoriteVisuals -GameId $syncId }.GetNewClosure()))
    }
    if ($global:CatalogSortMode -eq 'favorites' -and (Get-Command Apply-CatalogSort -ErrorAction SilentlyContinue)) {
        # Let the click animation finish before the card moves in the list.
        if (Get-Command Invoke-DeferredAction -ErrorAction SilentlyContinue) {
            Invoke-DeferredAction -DelayMs 870 -Action { Apply-CatalogSort -Scope All -SkipFilter }
        } else { Apply-CatalogSort -Scope All -SkipFilter }
    }
    return $Favorite
}

function global:Update-FavoriteCardVisual {
    param($Card)
    if (-not $Card -or -not $Card.Resources) { return }
    $game = $null
    try { $game = $Card.Resources.Item('gameData') } catch { }
    if (-not $game) { return }
    $favorite = Test-GameFavorite -Game $game
    $glyph = $null
    try { $glyph = $Card.Resources.Item('favoriteGlyph') } catch { }
    if ($glyph) {
        $glyph.Text = if ($favorite) { [string][char]0x2665 } else { 'i' }
        $glyph.FontStyle = if ($favorite) { [System.Windows.FontStyles]::Normal } else { [System.Windows.FontStyles]::Italic }
        $glyph.Foreground = if ($favorite) { $script:FavoritePink } else { $Card.Resources.Item('favoriteRestBrush') }
    }
    $edge = $null
    try { $edge = $Card.Resources.Item('favoritePillEdge') } catch { }
    if ($edge) { $edge.BorderBrush = if ($favorite) { $script:FavoriteOutline } else { $Card.Resources.Item('favoriteRestBorder') } }
}

function global:Update-FavoritePortraitVisual {
    param($Tile)
    if (-not $Tile -or -not $Tile.Resources) { return }
    $heart = $null; $game = $null
    try { $heart = $Tile.Resources.Item('favoritePortraitHeart'); $game = $Tile.Resources.Item('game') } catch { }
    if ($heart) {
        $heart.Visibility = if (Test-GameFavorite -Game $game) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    }
}

function global:Sync-FavoriteVisuals {
    param([string]$GameId)
    if (-not $global:window) { return }
    foreach ($name in @('OwnGameList', 'OwnGameListGP', 'ExternalGameList', 'UntestedGameList')) {
        $panel = $global:window.FindName($name)
        if (-not $panel) { continue }
        foreach ($card in @($panel.Children)) {
            $game = $null
            try { $game = $card.Resources.Item('gameData') } catch { }
            if ($game -and [string]$game.Id -eq $GameId) { Update-FavoriteCardVisual -Card $card }
        }
    }
    if ($global:discoverPanel) {
        foreach ($tile in @($global:discoverPanel.Children)) {
            $game = $null
            try { $game = $tile.Resources.Item('game') } catch { }
            if ($game -and [string]$game.Id -eq $GameId) { Update-FavoritePortraitVisual -Tile $tile }
        }
    }
    if ($global:FavoriteDetailGame -and [string]$global:FavoriteDetailGame.Id -eq $GameId) {
        Update-FavoriteDetailVisual
    }
    # An unfavorited card must leave an active favorites search after its
    # short heart animation, without forcing a full filter on every click.
    $search = $global:window.FindName('SearchBox')
    if ($search -and ([string]$search.Text).Trim().ToLowerInvariant() -in @('favorite', 'favorites')) {
        if (Get-Command Invoke-DeferredAction -ErrorAction SilentlyContinue) {
            Invoke-DeferredAction -DelayMs 280 -Action { Apply-Filter }
        } elseif (Get-Command Apply-Filter -ErrorAction SilentlyContinue) { Apply-Filter }
    }
}

function global:Update-FavoriteDetailVisual {
    if (-not $global:FavoriteDetailButton -or -not $global:FavoriteDetailGame) { return }
    $favorite = Test-GameFavorite -Game $global:FavoriteDetailGame
    $global:FavoriteDetailButton.BorderBrush = if ($favorite) { $script:FavoritePink } else { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#474753') }
    $global:FavoriteDetailButton.Background = if ($favorite) { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#32141f') } else { [System.Windows.Media.Brushes]::Transparent }
    $global:FavoriteDetailButton.ToolTip = if ($favorite) { 'Remove from favorites' } else { 'Mark as favorite' }
    $global:FavoriteDetailButton.Child.Text = if ($favorite) { [string][char]0x2665 } else { [string][char]0x2661 }
    $global:FavoriteDetailButton.Child.Foreground = if ($favorite) { $script:FavoritePink } else { [System.Windows.Media.BrushConverter]::new().ConvertFromString('#c4c7d1') }
}

function global:Start-FavoritePulse {
    param($Element)
    if (-not $Element) { return }
    $scale = [System.Windows.Media.ScaleTransform]::new(1, 1)
    $Element.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
    $Element.RenderTransform = $scale
    $grow = [System.Windows.Media.Animation.DoubleAnimation]::new(1, 1.28, [TimeSpan]::FromMilliseconds(150))
    $grow.AutoReverse = $true
    $grow.EasingFunction = [System.Windows.Media.Animation.CubicEase]::new()
    $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $grow)
    $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $grow)
}

function global:Start-FavoriteCardAnimation {
    param($Card, [System.Windows.Point]$Origin, [bool]$Favorite)
    if (-not $Card -or -not $Card.Child -or -not ($Card.Child -is [System.Windows.Controls.Grid])) { return }
    $overlay = $Card.Child
    $edge = $null
    try { $edge = $Card.Resources.Item('favoritePillEdge') } catch { }
    $glyph = $null
    try { $glyph = $Card.Resources.Item('favoriteGlyph') } catch { }
    if (-not $Favorite) {
        if ($glyph) {
            $glyph.Text = [string][char]0x2665
            $shrink = [System.Windows.Media.ScaleTransform]::new(1, 1)
            $glyph.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
            $glyph.RenderTransform = $shrink
            $leave = [System.Windows.Media.Animation.DoubleAnimation]::new(1, 0, [TimeSpan]::FromMilliseconds(220))
            $shrink.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $leave)
            $shrink.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $leave)
            $restore = [System.Windows.Threading.DispatcherTimer]::new()
            $restore.Interval = [TimeSpan]::FromMilliseconds(225)
            $restore.Add_Tick({ $restore.Stop(); Update-FavoriteCardVisual -Card $Card; $glyph.RenderTransform = $null }.GetNewClosure())
            $restore.Start()
        }
        return
    }

    # The destination remains an i until the flying heart lands.
    if ($glyph) { $glyph.Text = 'i' }
    $priorEffect = $Card.Effect
    $cardGlow = [System.Windows.Media.Effects.DropShadowEffect]::new()
    $cardGlow.Color = [System.Windows.Media.Color]::FromRgb(255, 65, 121)
    $cardGlow.ShadowDepth = 0; $cardGlow.BlurRadius = 16; $cardGlow.Opacity = 0.68
    $Card.Effect = $cardGlow

    # Variant C of the supplied example: a heart flies from the right-click
    # point into the info capsule while a short pink sheen crosses the tile.
    $fx = [System.Windows.Controls.Canvas]::new()
    $fx.IsHitTestVisible = $false
    $fx.ClipToBounds = $false
    [System.Windows.Controls.Panel]::SetZIndex($fx, 30)
    [void]$overlay.Children.Add($fx)
    $heart = [System.Windows.Controls.TextBlock]::new()
    $heart.Text = [string][char]0x2665
    $heart.FontFamily = [System.Windows.Media.FontFamily]::new('Segoe UI Symbol')
    $heart.FontSize = 31
    $heart.Foreground = $script:FavoritePink
    $shadow = [System.Windows.Media.Effects.DropShadowEffect]::new()
    $shadow.Color = [System.Windows.Media.Color]::FromRgb(255, 65, 121)
    $shadow.ShadowDepth = 0; $shadow.BlurRadius = 15; $shadow.Opacity = 0.85
    $heart.Effect = $shadow
    [System.Windows.Controls.Canvas]::SetLeft($heart, $Origin.X - 15)
    [System.Windows.Controls.Canvas]::SetTop($heart, $Origin.Y - 17)
    [void]$fx.Children.Add($heart)
    $destination = [System.Windows.Point]::new($Card.ActualWidth - 22, 19)
    if ($edge) { try { $destination = $edge.TranslatePoint([System.Windows.Point]::new($edge.ActualWidth / 2, $edge.ActualHeight / 2), $Card) } catch { } }
    $popScale = [System.Windows.Media.ScaleTransform]::new(0, 0)
    $move = [System.Windows.Media.TranslateTransform]::new()
    $transforms = [System.Windows.Media.TransformGroup]::new()
    [void]$transforms.Children.Add($popScale)
    [void]$transforms.Children.Add($move)
    $heart.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
    $heart.RenderTransform = $transforms
    $pop = [System.Windows.Media.Animation.DoubleAnimation]::new(0, 1, [TimeSpan]::FromMilliseconds(190))
    $pop.EasingFunction = [System.Windows.Media.Animation.BackEase]::new()
    $popScale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $pop)
    $popScale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $pop)
    $duration = [TimeSpan]::FromMilliseconds(360)
    $x = [System.Windows.Media.Animation.DoubleAnimation]::new(0, $destination.X - $Origin.X, $duration)
    $x.BeginTime = [TimeSpan]::FromMilliseconds(200)
    $x.EasingFunction = [System.Windows.Media.Animation.CubicEase]::new()
    $y = [System.Windows.Media.Animation.DoubleAnimation]::new(0, $destination.Y - $Origin.Y, $duration)
    $y.BeginTime = [TimeSpan]::FromMilliseconds(200)
    $y.EasingFunction = [System.Windows.Media.Animation.BackEase]::new()
    $move.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $x)
    $move.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $y)

    $ring = [System.Windows.Shapes.Ellipse]::new()
    $ring.Width = 20; $ring.Height = 20
    $ring.StrokeThickness = 2
    $ring.Stroke = $script:FavoritePink
    [System.Windows.Controls.Canvas]::SetLeft($ring, $Origin.X - 10)
    [System.Windows.Controls.Canvas]::SetTop($ring, $Origin.Y - 10)
    [void]$fx.Children.Add($ring)
    $ringGrow = [System.Windows.Media.Animation.DoubleAnimation]::new(20, 56, [TimeSpan]::FromMilliseconds(270))
    $ringFade = [System.Windows.Media.Animation.DoubleAnimation]::new(1, 0, [TimeSpan]::FromMilliseconds(270))
    $ringOffsetX = [System.Windows.Media.Animation.DoubleAnimation]::new($Origin.X - 10, $Origin.X - 28, [TimeSpan]::FromMilliseconds(270))
    $ringOffsetY = [System.Windows.Media.Animation.DoubleAnimation]::new($Origin.Y - 10, $Origin.Y - 28, [TimeSpan]::FromMilliseconds(270))
    $ring.BeginAnimation([System.Windows.FrameworkElement]::WidthProperty, $ringGrow)
    $ring.BeginAnimation([System.Windows.FrameworkElement]::HeightProperty, $ringGrow)
    $ring.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $ringFade)
    $ring.BeginAnimation([System.Windows.Controls.Canvas]::LeftProperty, $ringOffsetX)
    $ring.BeginAnimation([System.Windows.Controls.Canvas]::TopProperty, $ringOffsetY)

    $sheen = [System.Windows.Shapes.Rectangle]::new()
    $sheen.Width = 52; $sheen.Height = [Math]::Max(160, $Card.ActualHeight)
    $sheen.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#44ff83ac')
    $sheen.RenderTransform = [System.Windows.Media.SkewTransform]::new(-16, 0)
    [System.Windows.Controls.Canvas]::SetLeft($sheen, -65)
    [void]$fx.Children.Insert(0, $sheen)
    $swipe = [System.Windows.Media.Animation.DoubleAnimation]::new(-65, [Math]::Max(175, $Card.ActualWidth) + 55, [TimeSpan]::FromMilliseconds(650))
    $sheen.BeginAnimation([System.Windows.Controls.Canvas]::LeftProperty, $swipe)
    $pulse = [System.Windows.Threading.DispatcherTimer]::new()
    $pulse.Interval = [TimeSpan]::FromMilliseconds(700)
    $pulse.Add_Tick({
        $pulse.Stop()
        if ($overlay.Children.Contains($fx)) { [void]$overlay.Children.Remove($fx) }
        if ([object]::ReferenceEquals($Card.Effect, $cardGlow)) { $Card.Effect = $priorEffect }
        Update-FavoriteCardVisual -Card $Card
        Start-FavoritePulse -Element $glyph
    }.GetNewClosure())
    $pulse.Start()
}

function global:Register-FavoriteCard {
    param($Card, $Game)
    if (-not $Card -or -not $Game) { return }
    Update-FavoriteCardVisual -Card $Card
    if ($Card.Resources.Contains('favoriteRegistered')) { return }
    $Card.Resources.Add('favoriteRegistered', $true)
    $Card.Add_PreviewMouseRightButtonDown({
        param($sender, $eventArgs)
        $eventArgs.Handled = $true
        $game = $sender.Resources.Item('gameData')
        if (-not $game) { return }
        $origin = $eventArgs.GetPosition($sender)
        $favorite = Set-GameFavorite -Game $game -Favorite (-not (Test-GameFavorite -Game $game))
        Start-FavoriteCardAnimation -Card $sender -Origin $origin -Favorite $favorite
    })
}
