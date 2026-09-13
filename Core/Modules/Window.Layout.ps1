# -------------------------------------------------------
# Build XAML window
# -------------------------------------------------------
$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="PCVR Mods Installer Hub"
    Width="1120" Height="720" MinWidth="500" MinHeight="400"
    WindowStartupLocation="CenterScreen"
    ResizeMode="CanResize"
    Background="#0f0f12">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Sticky Header + Search -->
        <!-- No bottom border here on purpose: the FilterBar below
             carries its own bottom divider, and stacking two
             hairlines makes the band feel boxed-in. -->
        <Border x:Name="HeaderBorder" Grid.Row="0" Background="#0d0d0f" Padding="28,20,28,14" Panel.ZIndex="40">
            <Grid x:Name="HeaderGrid">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition x:Name="HeaderSearchColumn" Width="165"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Orientation="Horizontal">
                    <StackPanel>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <!-- VR Headset glyph -->
                        <Canvas x:Name="HeaderVrIcon" Width="32" Height="17" Margin="0,2,10,0" VerticalAlignment="Center"
                                Background="Transparent" Cursor="Hand" ToolTip="Switch style">
                            <Canvas.Effect>
                                <DropShadowEffect Color="#dd6600" BlurRadius="9" ShadowDepth="0" Opacity="0.6"/>
                            </Canvas.Effect>
                            <Path Stroke="#dd6600" StrokeThickness="1.5" Fill="Transparent"
                                  Data="M5,3 H27 Q30,3 30,6 V11 Q30,14 27,14 H21 Q19,14 18,12.5 L17,11 Q16,10 15,11 L14,12.5 Q13,14 11,14 H5 Q2,14 2,11 V6 Q2,3 5,3 Z"/>
                            <Ellipse Canvas.Left="7"  Canvas.Top="7" Width="3" Height="3" Fill="#dd6600"/>
                            <Ellipse Canvas.Left="22" Canvas.Top="7" Width="3" Height="3" Fill="#dd6600"/>
                        </Canvas>
                        <Grid x:Name="HeaderTitleGrid" VerticalAlignment="Center">
                            <!-- Glow layer: a hidden-color clone carrying only the
                                 DropShadow. It is NOT the element that scales on hover,
                                 so the glow stays crisp during the hover-grow. -->
                            <TextBlock x:Name="HeaderHubTitleGlow" Text="PCVR Mods Installer Hub"
                                       FontSize="22" FontWeight="Bold"
                                       Foreground="#3a8add" FontFamily="Segoe UI"
                                       IsHitTestVisible="False">
                                <TextBlock.Effect>
                                    <DropShadowEffect Color="#3a8add" BlurRadius="16"
                                                      ShadowDepth="0" Opacity="0.45"/>
                                </TextBlock.Effect>
                            </TextBlock>
                            <TextBlock x:Name="HeaderHubTitle" Text="PCVR Mods Installer Hub"
                                       FontSize="22" FontWeight="Bold"
                                       Foreground="White" FontFamily="Segoe UI"/>
                        </Grid>
                        <Border x:Name="VersionBadge" Background="#1e1e2a" CornerRadius="4"
                                Margin="10,4,0,0" Padding="6,2,6,2"
                                VerticalAlignment="Center">
                            <TextBlock x:Name="VersionLabel" Text="v0.1.0"
                                       FontSize="10" Foreground="#555568"
                                       FontFamily="Segoe UI"/>
                        </Border>
                    </StackPanel>
                    <TextBlock x:Name="HeaderTagline" Text="Install n!ce VR mods for your PC games"
                               FontSize="11" FontWeight="Medium" Foreground="#555568"
                               FontFamily="Segoe UI" Margin="42,2,0,0"
                               HorizontalAlignment="Left"/>
                    <!-- Update Banner (hidden by default) -->
                    <!-- Background stays #1a2e1a: Show-UpdateBanner swaps it on
                         hover and would overwrite anything else. The banner is
                         made to stand out through SIZE, a lit border and a soft
                         green glow instead - none of which the handler touches.
                         "Click to update" was #555568, grey on green and
                         practically invisible; it is bright now. -->
                    <Border x:Name="UpdateBanner" Background="#1a2e1a" CornerRadius="5"
                            Padding="12,8" Margin="0,7,0,0"
                            BorderThickness="1.2" BorderBrush="#5fe08a"
                            Visibility="Collapsed" Cursor="Hand">
                        <Border.Effect>
                            <DropShadowEffect Color="#4ade80" BlurRadius="13"
                                              ShadowDepth="0" Opacity="0.85"/>
                        </Border.Effect>
                        <StackPanel Orientation="Horizontal">
                            <Border Width="7" Height="7" CornerRadius="3.5"
                                    Background="#8bff8b" Margin="0,0,7,0"
                                    VerticalAlignment="Center"/>
                            <TextBlock x:Name="UpdateBannerText"
                                       FontSize="11.5" FontWeight="SemiBold" Foreground="#c8ffc8"
                                       FontFamily="Segoe UI" VerticalAlignment="Center"/>
                            <TextBlock Text=" - Click to update"
                                       FontSize="11.5" FontWeight="SemiBold" Foreground="#8bff8b"
                                       FontFamily="Segoe UI" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Border>
                    </StackPanel>
                    <StackPanel x:Name="TopScanSlot" Orientation="Horizontal" VerticalAlignment="Center" Margin="44,0,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <!-- Library/Discover switch (formerly the
                         6-dot picker). Now a rounded square with a
                         4-tile apps glyph, sitting in the glass
                         family so it reads as part of the same
                         interactive vocabulary as the S/M/L pills.
                         Active state and hover-glow are driven from
                         code (Update-DiscoverBtnState in
                         DiscoverInit.ps1 and Add-GlowHover-style
                         in DiscoverInit.ps1) - this XAML defines
                         only the resting look. -->
                    <Border Background="#16161a" CornerRadius="8"
                            Width="34" Height="34"
                            BorderThickness="1" BorderBrush="#3a3a48"
                            VerticalAlignment="Center" Margin="0,0,10,0"
                            Cursor="Hand" x:Name="DiscoverBtn"
                            ToolTip="Open library / discover view">
                        <!-- 4-tile apps icon - rounded-corner
                             squares arranged 2x2. Stroke=None,
                             solid Fill so they read clearly on
                             both the dark resting bg and the
                             brighter active bg. -->
                        <Grid Width="14" Height="14"
                              HorizontalAlignment="Center"
                              VerticalAlignment="Center">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="3"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="3"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Rectangle Grid.Row="0" Grid.Column="0"
                                       Fill="#aaaaaa" RadiusX="1" RadiusY="1"/>
                            <Rectangle Grid.Row="0" Grid.Column="2"
                                       Fill="#aaaaaa" RadiusX="1" RadiusY="1"/>
                            <Rectangle Grid.Row="2" Grid.Column="0"
                                       Fill="#aaaaaa" RadiusX="1" RadiusY="1"/>
                            <Rectangle Grid.Row="2" Grid.Column="2"
                                       Fill="#aaaaaa" RadiusX="1" RadiusY="1"/>
                        </Grid>
                    </Border>
                    <!-- Help & Feedback overflow menu. Replaces the former
                         circular "i" Discord button; the Discord invite now
                         lives inside the dropdown alongside Suggest / Report.
                         A Popup is used on purpose so the menu renders on its
                         own visual layer ABOVE the banner and mod list - it is
                         never clipped by them and never pushes them around. -->
                    <Border Background="#16161a" CornerRadius="8"
                            Width="34" Height="34"
                            BorderThickness="1" BorderBrush="#3a3a48"
                            VerticalAlignment="Center" Margin="0,0,10,0"
                            Cursor="Hand" x:Name="MenuBtn"
                            ToolTip="Help &amp; feedback">
                        <StackPanel x:Name="MenuDots" Orientation="Vertical"
                                    HorizontalAlignment="Center"
                                    VerticalAlignment="Center">
                            <Ellipse Width="3.5" Height="3.5" Fill="#aaaaaa" Margin="0,0,0,2.5"/>
                            <Ellipse Width="3.5" Height="3.5" Fill="#aaaaaa" Margin="0,0,0,2.5"/>
                            <Ellipse Width="3.5" Height="3.5" Fill="#aaaaaa"/>
                        </StackPanel>
                    </Border>
                    <!-- Help & Feedback menu now lives in MenuOverlay at the
                         root Grid (see end of XAML), so it overlays all content
                         in a single visual tree and cannot leak clicks to the
                         banner/cards behind it the way a Popup did. -->

                </StackPanel>
                <!-- One global order control for every game collection: list,
                     Library portraits and Explore rows. It is deliberately
                     beside Search rather than inside a category bar so its
                     scope is unambiguous. -->
                <Border x:Name="OrderPill" Grid.Column="2" Background="#16161a" CornerRadius="6"
                        Width="144" Height="34" Margin="0,0,10,0"
                        BorderThickness="1" BorderBrush="#2a2a35"
                        VerticalAlignment="Center" Cursor="Hand"
                        ToolTip="Sort every game list">
                    <Grid Margin="10,0,8,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="6"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock x:Name="OrderPrefix" Text="ORDER" FontSize="9" FontWeight="SemiBold"
                                   Foreground="#3a8add" FontFamily="Segoe UI"
                                   VerticalAlignment="Center"/>
                        <TextBlock x:Name="OrderLabel" Grid.Column="2" Text="Alphabetical"
                                   FontSize="11" Foreground="#d8dee3" FontFamily="Segoe UI"
                                   TextTrimming="CharacterEllipsis" VerticalAlignment="Center"/>
                        <Path x:Name="OrderChevron" Grid.Column="3" Margin="6,1,0,0"
                              Width="8" Height="6" Stroke="#888899" StrokeThickness="1.4"
                              StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                              StrokeLineJoin="Round" VerticalAlignment="Center"
                              Data="M 0,1 L 4,5 L 8,1"/>
                    </Grid>
                </Border>
                <Border x:Name="SearchPill" Grid.Column="3" Background="#16161a" CornerRadius="6"
                        BorderThickness="1" BorderBrush="#2a2a35"
                        VerticalAlignment="Center">
                    <!-- The TextBox fills the whole pill so any click on
                         the search field focuses the input. The
                         "Search" placeholder sits on top (hit-test
                         disabled) and is hidden once the user types. -->
                    <Grid>
                        <TextBox x:Name="SearchBox"
                                 Background="Transparent" BorderThickness="0"
                                 Foreground="White" FontSize="12"
                                 FontFamily="Segoe UI" CaretBrush="White"
                                 Padding="10,8,10,8" VerticalContentAlignment="Center"/>
                        <TextBlock x:Name="SearchPlaceholder" Text="Search"
                                   FontSize="11" Foreground="#555568"
                                   FontFamily="Segoe UI"
                                   Margin="11,0,0,0" VerticalAlignment="Center"
                                   IsHitTestVisible="False"/>
                        <!-- Search hint. It hangs BELOW the pill on its own
                             visual layer (negative bottom margin + no height
                             of its own), so showing and hiding it never
                             moves the header or the bar underneath. Two
                             states share the spot: the examples line, and -
                             once a modder exclusion is typed - the offer to
                             hide that modder for good. -->
                        <Grid x:Name="SearchHintHost" VerticalAlignment="Bottom"
                              Margin="2,0,0,-19" Height="16"
                              Visibility="Collapsed" Panel.ZIndex="50">
                            <TextBlock x:Name="SearchHint"
                                       Text="e.g.  cyberpunk  &#183;  praydog  &#183;  roomscale  &#183;  free -horror -praydog"
                                       FontSize="10" Foreground="#555568"
                                       FontFamily="Segoe UI"
                                       IsHitTestVisible="False"/>
                            <StackPanel x:Name="SearchHidePanel" Orientation="Horizontal"
                                        Visibility="Collapsed">
                                <!-- Focusable=False is what makes this work at all:
                                     clicking a focusable CheckBox pulls keyboard
                                     focus out of the search box on MOUSE DOWN,
                                     LostKeyboardFocus collapses this panel, and
                                     the mouse-up never lands on it - so no Click
                                     ever fires and nothing is saved. Unfocusable,
                                     the search box keeps focus and the click
                                     completes. -->
                                <CheckBox x:Name="SearchHideChk" VerticalAlignment="Center"
                                          Foreground="#8a8a9a" FontSize="10"
                                          FontFamily="Segoe UI" Cursor="Hand"
                                          Focusable="False"/>
                                <TextBlock x:Name="SearchHideText" Text=""
                                           FontSize="10" Foreground="#8a8a9a"
                                           FontFamily="Segoe UI"
                                           VerticalAlignment="Center"
                                           Visibility="Collapsed"
                                           IsHitTestVisible="False"/>
                            </StackPanel>
                        </Grid>
                    </Grid>
                </Border>
            </Grid>
        </Border>

        <!-- Filter Buttons -->
        <!-- Solid #0d0d0f background with a hairline bottom border:
             the FilterBar must read as a distinct strip below the
             header, otherwise content scrolling up under it looks
             like it dissolves into nothing. The TOP divider (above
             the bar, attached to the header) is removed instead -
             one separator is enough; with two the band feels boxed-in. -->
        <Border Grid.Row="1" x:Name="FilterBar" Background="#0d0d0f" Padding="28,0,28,12"
                BorderThickness="0,0,0,1" BorderBrush="#1a1a22">
            <DockPanel LastChildFill="False">
                <StackPanel x:Name="ScaleStack" Orientation="Horizontal" DockPanel.Dock="Right" VerticalAlignment="Center">
                    <!-- S/M/L size switcher. Matches the new glass
                         pill family: 30x28px (was 26x22), FontSize
                         12 (was 10), translucent background and
                         soft border so it sits in the same visual
                         language as the filter pills. The active
                         state is driven from Helpers.ps1 - it sets
                         a brighter Background and stronger
                         BorderBrush on the picked button. -->
                    <Border x:Name="ScaleS" Background="#09ffffff" CornerRadius="6"
                            BorderThickness="1" BorderBrush="#0fffffff"
                            Width="30" Height="28" Cursor="Hand" Margin="0,0,5,0"
                            ToolTip="Small cards">
                        <TextBlock Text="S" FontSize="12" FontWeight="Bold"
                                   Foreground="#aaaaaa" FontFamily="Segoe UI"
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <Border x:Name="ScaleM" Background="#09ffffff" CornerRadius="6"
                            BorderThickness="1" BorderBrush="#0fffffff"
                            Width="30" Height="28" Cursor="Hand" Margin="0,0,5,0"
                            ToolTip="Medium cards">
                        <TextBlock Text="M" FontSize="12" FontWeight="Bold"
                                   Foreground="#aaaaaa" FontFamily="Segoe UI"
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <Border x:Name="ScaleL" Background="#09ffffff" CornerRadius="6"
                            BorderThickness="1" BorderBrush="#0fffffff"
                            Width="30" Height="28" Cursor="Hand"
                            ToolTip="Large cards">
                        <TextBlock Text="L" FontSize="12" FontWeight="Bold"
                                   Foreground="#aaaaaa" FontFamily="Segoe UI"
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                </StackPanel>
                <StackPanel Orientation="Horizontal" DockPanel.Dock="Left">
                <!-- Filter pills: glassmorphic style. Padding 13,6 +
                     FontSize 12 (was 12,5 + 11) gives a subtle size
                     bump that reads more premium without forcing
                     line breaks. CornerRadius 6 matches the softer
                     glass feel. Background stays at the glass base
                     in every state - active vs inactive is signaled
                     purely by BorderBrush: a colored accent border
                     means active, a near-transparent white border
                     means inactive. See Set-FilterStyle. -->
                <!-- Header back arrow: a small chevron that mirrors the
                     in-page Back button. Hidden on the library/home view,
                     grey (but clickable) on detail/explore pages, and it
                     lights up white as the in-page Back button scrolls
                     away. The 24px box + 18px right margin (= 42px, the
                     width of the VR icon + gap above) shifts "All" right
                     so it starts under the "P" of PCVR. See
                     Update-HeaderBackArrow / Invoke-HeaderBack. -->
                <Border x:Name="HeaderBackBtn" Width="24" Height="24" Margin="0,0,18,0"
                        CornerRadius="6" BorderThickness="1" BorderBrush="#12ffffff"
                        Background="#09ffffff" Cursor="Hand" VerticalAlignment="Center"
                        Visibility="Visible" ToolTip="Back">
                    <Path x:Name="HeaderBackArrow" Data="M 7,0 L 0,6 L 7,12"
                          Stroke="#555560" StrokeThickness="2"
                          StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                          StrokeLineJoin="Round"
                          HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <TextBlock Text="TYPE" FontSize="11" FontWeight="SemiBold" Foreground="#6f6f7a"
                           FontFamily="Segoe UI" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <!-- Type pills use three real layers instead of a WPF Effect:
                     a faint outer ring, the opaque button, and a crisp outline
                     above everything. This keeps the lit edge intact without
                     rasterizing the whole pill into a round shadow bitmap. -->
                <Grid Margin="0,0,7,0">
                    <Border x:Name="FilterAllGlowRing" Margin="-1" CornerRadius="7"
                            BorderThickness="2" BorderBrush="#80ffeeb0"
                            IsHitTestVisible="False"/>
                    <Border x:Name="FilterAll" CornerRadius="6" Padding="15,9"
                            BorderThickness="1" BorderBrush="Transparent"
                            Background="#000000" Cursor="Hand">
                        <TextBlock Text="All" FontSize="13" FontWeight="SemiBold"
                                   Foreground="White" FontFamily="Segoe UI"/>
                    </Border>
                    <Border x:Name="FilterAllRing" CornerRadius="6"
                            BorderThickness="1" BorderBrush="#ffeeb0"
                            Background="Transparent" IsHitTestVisible="False"
                            Panel.ZIndex="10"/>
                </Grid>
                <Grid Margin="0,0,7,0">
                    <Border x:Name="FilterMCGlowRing" Margin="-1" CornerRadius="7"
                            BorderThickness="2" BorderBrush="#80ffeeb0"
                            Visibility="Collapsed" IsHitTestVisible="False"/>
                    <Border x:Name="FilterMC" CornerRadius="6" Padding="15,9"
                            BorderThickness="1" BorderBrush="Transparent"
                            Background="#000000" Cursor="Hand">
                        <!-- Motion Controls: kept as a single line on
                             purpose; if it wraps the pill grows much
                             taller than its neighbours and the bar
                             looks broken. WPF wraps TextBlock by
                             default when its parent has limited width,
                             so we leave it unconstrained and rely on
                             the bar's MinWidth to keep things sane. -->
                        <StackPanel Orientation="Horizontal">
                            <Viewbox Width="14" Height="14" Margin="0,0,7,0" VerticalAlignment="Center">
                                <Path Data="M7.7 8.2A4.3 2.2 0 1 1 16.3 8.2A4.3 2.2 0 1 1 7.7 8.2Z M12 9.8C10.8 9.8 10.2 10.9 10.3 12.1L10.9 17.6C11 18.8 11.2 19.4 12 19.4C12.8 19.4 13 18.8 13.1 17.6L13.7 12.1C13.8 10.9 13.2 9.8 12 9.8Z M11.1 11A0.9 0.9 0 1 1 12.9 11A0.9 0.9 0 1 1 11.1 11Z" Stroke="#44cc66" StrokeThickness="1.9" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="{x:Null}"/>
                            </Viewbox>
                            <TextBlock Text="Motion Controls" FontSize="13" FontWeight="SemiBold"
                                       Foreground="#aaaaaa" FontFamily="Segoe UI"
                                       TextWrapping="NoWrap"/>
                        </StackPanel>
                    </Border>
                    <Border x:Name="FilterMCRing" CornerRadius="6"
                            BorderThickness="1" BorderBrush="#0fffffff"
                            Background="Transparent" IsHitTestVisible="False"
                            Panel.ZIndex="10"/>
                </Grid>
                <Grid>
                    <Border x:Name="FilterGPGlowRing" Margin="-1" CornerRadius="7"
                            BorderThickness="2" BorderBrush="#80ffeeb0"
                            Visibility="Collapsed" IsHitTestVisible="False"/>
                    <Border x:Name="FilterGP" CornerRadius="6" Padding="15,9"
                            BorderThickness="1" BorderBrush="Transparent"
                            Background="#000000" Cursor="Hand">
                        <StackPanel Orientation="Horizontal">
                            <Viewbox Width="18" Height="18" Margin="11,0,10,0" VerticalAlignment="Center">
                                <Path Data="M8 8.7C5.3 8.7 3.9 10.7 3.3 13.8C2.9 16.1 4 17.6 5.7 17.6C7 17.6 7.6 16.5 8.5 16.1L15.5 16.1C16.4 16.5 17 17.6 18.3 17.6C20 17.6 21.1 16.1 20.7 13.8C20.1 10.7 18.7 8.7 16 8.7Z M6.4 11.6L6.4 14 M5.2 12.8L7.6 12.8 M14.7 11.7A1 1 0 1 1 16.7 11.7A1 1 0 1 1 14.7 11.7Z M16.5 13.3A1 1 0 1 1 18.5 13.3A1 1 0 1 1 16.5 13.3Z" Stroke="#dd6600" StrokeThickness="1.9" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="{x:Null}"/>
                            </Viewbox>
                            <TextBlock Text="Gamepad" FontSize="13" FontWeight="SemiBold"
                                       Foreground="#aaaaaa" FontFamily="Segoe UI"
                                       TextWrapping="NoWrap"/>
                        </StackPanel>
                    </Border>
                    <Border x:Name="FilterGPRing" CornerRadius="6"
                            BorderThickness="1" BorderBrush="#0fffffff"
                            Background="Transparent" IsHitTestVisible="False"
                            Panel.ZIndex="10"/>
                </Grid>
                <!-- Installed + VR Ready share a transparent hover group.
                     Background="Transparent" makes the gap between the two
                     pills hit-testable, so resting the cursor between them
                     counts as hovering the group (no dead zone) and the
                     VR Ready reveal does not collapse prematurely. -->
                <TextBlock x:Name="StateLabel" Text="STATE" FontSize="11" FontWeight="SemiBold" Foreground="#6f6f7a"
                           FontFamily="Segoe UI" VerticalAlignment="Center" Margin="7,0,8,0"/>
                <StackPanel x:Name="InstalledFilterGroup" Orientation="Horizontal"
                            Margin="0,0,0,0" Background="Transparent" Visibility="Collapsed">
                <Border x:Name="FilterInstalled" CornerRadius="6" Padding="15,9"
                        BorderThickness="1" BorderBrush="#0fffffff"
                        Background="#000000" Cursor="Hand"
                        ToolTip="Games on your PC that don't have the VR mod installed yet">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="Needs Mod" FontSize="13" FontWeight="SemiBold"
                                   Foreground="#aaaaaa" FontFamily="Segoe UI"
                                   TextWrapping="NoWrap"/>
                    </StackPanel>
                </Border>
                <Border x:Name="FilterVRReady" CornerRadius="6" Padding="15,9" Margin="6,0,0,0"
                        BorderThickness="1" BorderBrush="#0fffffff" Visibility="Collapsed"
                        Background="#000000" Cursor="Hand"
                        ToolTip="Show only games whose VR mod is installed and ready">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="VR Ready" FontSize="13" FontWeight="SemiBold"
                                   Foreground="#aaaaaa" FontFamily="Segoe UI"
                                   TextWrapping="NoWrap"/>
                    </StackPanel>
                </Border>
                <!-- Updates: a third pill, DELIBERATELY outside the
                     anchor/partner swap of the two above. Those two
                     exchange each other in and out; hanging a third one
                     into that interplay would have broken it.
                     This one is simply visible once a scan has run AND
                     there is something to update at all - otherwise it
                     stays collapsed and takes up no space.
                     Visibility and styling are handled by
                     Set-InstallFilterMode. -->
                <Border x:Name="FilterUpdate" CornerRadius="6" Padding="15,9" Margin="6,0,0,0"
                        BorderThickness="1" BorderBrush="#0fffffff" Visibility="Collapsed"
                        Background="#000000" Cursor="Hand"
                        ToolTip="Show only installed mods that have a newer version">
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <TextBlock Text="Updates" FontSize="13" FontWeight="SemiBold"
                                   Foreground="#aaaaaa" FontFamily="Segoe UI"
                                   TextWrapping="NoWrap" VerticalAlignment="Center"/>
                        <!-- The number in a badge of its own: MinWidth 20 keeps it
                             round with one digit; CornerRadius 10 plus the
                             inner padding grows it into an ellipse at two digits.
                             Colours are set by Set-InstallFilterMode - the number
                             is on screen in the DESELECTED state too, hence a
                             restrained, semi-transparent blue there. -->
                        <Border x:Name="FilterUpdateBadge" CornerRadius="10"
                                MinWidth="20" Height="20" Margin="9,0,0,0"
                                Padding="7,0" Background="#1F60A5FA"
                                VerticalAlignment="Center">
                            <TextBlock x:Name="FilterUpdateCount" Text="0" FontSize="12"
                                       FontWeight="SemiBold" Foreground="#8FB6DD"
                                       FontFamily="Segoe UI" TextWrapping="NoWrap"
                                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </StackPanel>
                </Border>
                </StackPanel>
                <!-- No divider here on purpose: the glowing counter
                     button separates itself visually from the
                     filter pills already, and a literal divider
                     line breaks the seamless glass flow we want. -->
                <StackPanel x:Name="CheckInstalledHoverGroup"
                            Orientation="Horizontal"
                            Background="Transparent"
                            Margin="7,0,0,0">
                    <!-- Eye-catcher counter button. Same padding as
                         filter pills (so it doesn't shove the bar
                         wider), gets visual weight from:
                          - DropShadowEffect green halo (set in
                            Filter.ps1 init)
                          - bright #5fff8f numbers (FontSize 13 vs
                            12 on the surrounding pills)
                          - periodic shimmer sweep (Storyboard)
                         Three TextBlocks for the post-scan state
                         ("47 installed | 42 VR ready") so we can
                         style numbers separately. Pre-scan state
                         shows only CheckInstalledText with
                         "Check Installed" - the others get hidden
                         until Invoke-CheckInstalledScan runs. -->
                    <!-- Wrapper Grid lets us float the shimmer-
                         disable overlay above the counter button
                         without affecting layout (the buttons share
                         the same cell, overlay sits on top via
                         z-order). Same idiom as the Banner and
                         RecentlyPlayed hover-close overlays. -->
                    <Grid x:Name="CheckInstalledHost">
                    <Border x:Name="CheckInstalledBtn" CornerRadius="6" Padding="15,9"
                            BorderThickness="2" BorderBrush="#b35fff8f"
                            Background="#034ade80" Cursor="Hand"
                            ClipToBounds="True">
                        <Grid>
                            <!-- Shimmer overlay covering the full
                                 button surface, not just the text
                                 area. The negative Margin matches
                                 the parent's Padding=13,6 so the
                                 shimmer extends edge-to-edge inside
                                 the button border. ClipToBounds on
                                 the parent CheckInstalledBtn keeps
                                 the sweep tidy at the rounded edges.
                                 VerticalAlignment=Stretch is essen-
                                 tial - without it the border has
                                 zero height and renders nothing.
                                 Initial Visibility=Collapsed: the
                                 shimmer is the eye-catcher for the
                                 "X installed | Y VR ready" state
                                 only. The pre-scan "Check Installed"
                                 state stays calm; Invoke-Check-
                                 InstalledScan promotes it to Visible
                                 when the counter takes over. -->
                            <Border x:Name="CheckInstalledShimmer"
                                    Width="80"
                                    HorizontalAlignment="Left"
                                    VerticalAlignment="Stretch"
                                    Margin="-15,-9,-15,-9"
                                    Visibility="Collapsed"
                                    IsHitTestVisible="False">
                                <Border.RenderTransform>
                                    <TranslateTransform x:Name="CheckInstalledShimmerXf" X="-100"/>
                                </Border.RenderTransform>
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0.5" EndPoint="1,0.5">
                                        <GradientStop Color="#005fff8f" Offset="0.0"/>
                                        <GradientStop Color="#605fff8f" Offset="0.5"/>
                                        <GradientStop Color="#005fff8f" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                            </Border>
                            <!-- HorizontalAlignment=Center: on a RE-scan the
                                 content shrinks to "Scanning..." while
                                 the button still holds the width of "X on PC, Y VR Ready".
                                 Left-aligned, the short text clung to the edge of an
                                 otherwise empty-looking row. -->
                            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                                <!-- Pre-scan text. Hidden once a
                                     scan completes; replaced by
                                     the count block to its right.
                                     Bright off-white (#e8f5ec) for
                                     readability + just a touch of
                                     green so it still feels like
                                     part of the green counter
                                     family. Pure green-on-green
                                     was washed out; pure white
                                     looked disconnected. -->
                                <Viewbox Width="13" Height="13" Margin="0,0,7,0" VerticalAlignment="Center">
                                    <Path Data="M4.5 10A5.5 5.5 0 1 1 15.5 10A5.5 5.5 0 1 1 4.5 10Z M13.9 13.9L19 19" Stroke="#e8f5ec" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="{x:Null}"/>
                                </Viewbox>
                                <TextBlock x:Name="CheckInstalledText" Text="Scan installed games"
                                           FontSize="12" FontWeight="SemiBold"
                                           Foreground="#e8f5ec" FontFamily="Segoe UI"
                                           VerticalAlignment="Center"
                                           TextWrapping="NoWrap"/>
                                <!-- A second magnifier, visible ONLY while scanning.
                                     It frames "Scanning..." and fills the width the
                                     counter otherwise needs. Collapsed outside of a
                                     scan, so that "Scan installed games" and the finished
                                     counter look exactly as they did before. -->
                                <Viewbox x:Name="CheckInstalledMagRight" Width="13" Height="13"
                                         Margin="7,0,0,0" VerticalAlignment="Center"
                                         Visibility="Collapsed">
                                    <Path Data="M4.5 10A5.5 5.5 0 1 1 15.5 10A5.5 5.5 0 1 1 4.5 10Z M13.9 13.9L19 19" Stroke="#ffcc44" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="{x:Null}"/>
                                </Viewbox>
                                <!-- Post-scan count block. Stays
                                     Collapsed until the scan runs. -->
                                <StackPanel x:Name="CheckInstalledCount"
                                            Orientation="Horizontal"
                                            VerticalAlignment="Center"
                                            Visibility="Collapsed">
                                    <TextBlock x:Name="CheckInstalledCountInst"
                                               FontSize="13" FontWeight="ExtraBold"
                                               Foreground="#5fff8f" FontFamily="Segoe UI"
                                               VerticalAlignment="Center"
                                               TextWrapping="NoWrap"/>
                                    <TextBlock Text=" on PC"
                                               FontSize="12" FontWeight="SemiBold"
                                               Foreground="#e8f5ec" FontFamily="Segoe UI"
                                               VerticalAlignment="Center"
                                               TextWrapping="NoWrap"/>
                                    <TextBlock x:Name="CheckInstalledCountSep"
                                               Text="  |  " FontSize="12" FontWeight="SemiBold"
                                               Foreground="#5aa880" FontFamily="Segoe UI"
                                               Opacity="0.4"
                                               VerticalAlignment="Center"
                                               TextWrapping="NoWrap"/>
                                    <Path x:Name="CheckInstalledReadyIcon"
                                          Data="M 0,0 L 7,4 L 0,8 Z" Fill="#5fff8f"
                                          Margin="0,0,5,0" VerticalAlignment="Center"/>
                                    <TextBlock x:Name="CheckInstalledCountReady"
                                               FontSize="13" FontWeight="ExtraBold"
                                               Foreground="#5fff8f" FontFamily="Segoe UI"
                                               VerticalAlignment="Center"
                                               TextWrapping="NoWrap"/>
                                    <TextBlock Text=" VR Ready"
                                               FontSize="12" FontWeight="SemiBold"
                                               Foreground="#fcefb0" FontFamily="Segoe UI"
                                               VerticalAlignment="Center"
                                               TextWrapping="NoWrap"/>
                                </StackPanel>
                            </StackPanel>
                        </Grid>
                    </Border>
                    <!-- Shimmer-disable hover overlay. Floats just
                         above and slightly to the right of the
                         counter so it doesn't cover any text. Two
                         small chips: "Disable shimmer" (session-
                         only) and "Always Disable" (persists to
                         hub-settings via shimmerDisabled). Shows
                         up only when the user has dwelled on the
                         counter for ~5 seconds AND the counter is
                         in its post-scan state - we never tease
                         this on "Check Installed" because the
                         shimmer isn't running yet there. See
                         Setup-CounterShimmerOptOut in Filter.ps1. -->
                    <StackPanel x:Name="ShimmerDisableOverlay"
                                Orientation="Horizontal"
                                HorizontalAlignment="Right"
                                VerticalAlignment="Top"
                                Margin="0,-12,-8,0"
                                Visibility="Collapsed"
                                Panel.ZIndex="20">
                        <Border x:Name="ShimmerDisableBtn"
                                Background="#1e1e2a" CornerRadius="3"
                                BorderThickness="1" BorderBrush="#3a3a48"
                                Padding="6,2" Margin="0,0,4,0" Cursor="Hand"
                                ToolTip="Hide the shimmer effect for this session">
                            <TextBlock Text="Disable shimmer"
                                       FontSize="10" FontWeight="SemiBold"
                                       Foreground="#aaaaaa" FontFamily="Segoe UI"/>
                        </Border>
                        <Border x:Name="ShimmerAlwaysDisableBtn"
                                Background="#1e1e2a" CornerRadius="3"
                                BorderThickness="1" BorderBrush="#3a3a48"
                                Padding="6,2" Cursor="Hand"
                                ToolTip="Never show the shimmer effect again">
                            <TextBlock Text="Always Disable"
                                       FontSize="10" FontWeight="SemiBold"
                                       Foreground="#aaaaaa" FontFamily="Segoe UI"/>
                        </Border>
                    </StackPanel>
                    </Grid>
                    <!-- Reveal-on-hover companion toggle. Click flips
                         a persisted flag and shows a check mark. -->
                    <Border x:Name="CheckOnStartupBtn" CornerRadius="6" Padding="11,7"
                            Background="#000000" Cursor="Hand"
                            BorderThickness="1" BorderBrush="#0fffffff"
                            Margin="7,0,0,0"
                            Visibility="Hidden">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Path x:Name="CheckOnStartupCheck"
                                  Data="M 0,4 L 3,7 L 8,1"
                                  Stroke="#5aa880" StrokeThickness="2"
                                  StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                                  StrokeLineJoin="Round" Fill="Transparent"
                                  VerticalAlignment="Center"
                                  Margin="0,0,6,0"
                                  Visibility="Collapsed"/>
                            <TextBlock x:Name="CheckOnStartupText"
                                       Text="Scan on Startup"
                                       FontSize="13" FontWeight="SemiBold"
                                       Foreground="#9aa6a0" FontFamily="Segoe UI"
                                       VerticalAlignment="Center" TextWrapping="NoWrap"/>
                        </StackPanel>
                    </Border>
                </StackPanel>
                </StackPanel>
            </DockPanel>
        </Border>

        <!-- Scrollable Content -->
        <ScrollViewer Grid.Row="2" x:Name="ListScroll" VerticalScrollBarVisibility="Auto">
            <Border>
                <Border.Background>
                    <!-- CachingHint: without it WPF re-tessellates this 24x24
                         pattern across the whole viewport on EVERY frame, and
                         it is the background BEHIND a scrolling list - so it
                         redraws for every pixel of movement. Cached, it is
                         rasterised once and blitted. -->
                    <DrawingBrush TileMode="Tile" Viewport="0,0,24,24" ViewportUnits="Absolute"
                                  RenderOptions.CachingHint="Cache"
                                  RenderOptions.CacheInvalidationThresholdMinimum="0.5"
                                  RenderOptions.CacheInvalidationThresholdMaximum="2.0">
                        <DrawingBrush.Drawing>
                            <DrawingGroup>
                                <GeometryDrawing Brush="#0f0f12">
                                    <GeometryDrawing.Geometry>
                                        <RectangleGeometry Rect="0,0,24,24"/>
                                    </GeometryDrawing.Geometry>
                                </GeometryDrawing>
                                <GeometryDrawing Brush="#222230">
                                    <GeometryDrawing.Geometry>
                                        <EllipseGeometry Center="12,12" RadiusX="0.9" RadiusY="0.9"/>
                                    </GeometryDrawing.Geometry>
                                </GeometryDrawing>
                            </DrawingGroup>
                        </DrawingBrush.Drawing>
                    </DrawingBrush>
                </Border.Background>
            <StackPanel Margin="28,20,28,24">

                <!-- Featured banner: random game header art with
                     Show + Explore actions. Full art stays visible
                     thanks to Stretch=Uniform anchored right. -->
                <Border x:Name="ListBanner" Height="140" CornerRadius="8"
                        Margin="0,0,0,22" Background="#0f0f15"
                        BorderThickness="1" BorderBrush="#2a2a35"
                        ClipToBounds="True">
                    <Grid>
                        <Rectangle x:Name="ListBannerBg" Fill="#0f0f15"
                                   IsHitTestVisible="False"
                                   HorizontalAlignment="Stretch" VerticalAlignment="Stretch"/>
                        <Image x:Name="ListBannerImage" Stretch="Uniform"
                               HorizontalAlignment="Right" VerticalAlignment="Center"/>
                        <Rectangle x:Name="ListBannerFade" HorizontalAlignment="Stretch" VerticalAlignment="Stretch"
                                   IsHitTestVisible="False">
                            <Rectangle.Fill>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                    <GradientStop Color="#F00F0F15" Offset="0.0"/>
                                    <GradientStop Color="#C00F0F15" Offset="0.35"/>
                                    <GradientStop Color="#000F0F15" Offset="0.75"/>
                                </LinearGradientBrush>
                            </Rectangle.Fill>
                        </Rectangle>

                        <Grid x:Name="ListBannerTitleGrid" Margin="22,16,22,16">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <StackPanel Grid.Row="0" VerticalAlignment="Top">
                                <StackPanel Orientation="Horizontal" Margin="0,0,0,4">
                                    <Ellipse x:Name="ListBannerCtrlDot"
                                             Width="7" Height="7" Fill="#dd6600"
                                             VerticalAlignment="Center"
                                             Margin="0,0,7,0"/>
                                    <TextBlock x:Name="ListBannerKicker"
                                               Text="FEATURED VR MOD"
                                               FontSize="10" FontWeight="SemiBold"
                                               Foreground="#dd6600" FontFamily="Segoe UI"/>
                                </StackPanel>
                                <TextBlock x:Name="ListBannerTitle"
                                           Text="..." FontSize="22" FontWeight="SemiBold"
                                           Foreground="White" FontFamily="Segoe UI"
                                           TextWrapping="NoWrap" TextTrimming="None"
                                           MaxWidth="380" HorizontalAlignment="Left"/>
                                <TextBlock x:Name="ListBannerSubtitle"
                                           Text="..." FontSize="11"
                                           Foreground="#bbbbbb" FontFamily="Segoe UI"
                                           Margin="0,4,0,0"
                                           TextWrapping="NoWrap" TextTrimming="CharacterEllipsis"
                                           MaxWidth="380" HorizontalAlignment="Left"/>
                            </StackPanel>

                            <StackPanel Grid.Row="1" Orientation="Horizontal"
                                        VerticalAlignment="Bottom">
                                <Border x:Name="ListBannerShowBtn"
                                        Background="Transparent" CornerRadius="4"
                                        BorderThickness="2" BorderBrush="#bfa845"
                                        Padding="14,7" Margin="0,0,8,0" Cursor="Hand">
                                    <TextBlock x:Name="ListBannerShowBtnText" Text="Show"
                                               FontSize="11" FontWeight="Bold"
                                               Foreground="#bfa845" FontFamily="Segoe UI"/>
                                </Border>
                                <Border x:Name="ListBannerExploreBtn"
                                        Background="Transparent" CornerRadius="4"
                                        BorderThickness="1.5" BorderBrush="#dd6600"
                                        Padding="14,7" Cursor="Hand">
                                    <StackPanel Orientation="Horizontal">
                                        <TextBlock x:Name="ListBannerExploreBtnText" Text="Explore all games"
                                                   FontSize="11" FontWeight="Bold"
                                                   Foreground="#dd6600" FontFamily="Segoe UI"/>
                                        <TextBlock x:Name="ListBannerExploreBtnArrow" Text="  &#x203A;"
                                                   FontSize="13" FontWeight="SemiBold"
                                                   Foreground="#dd6600" FontFamily="Segoe UI"/>
                                    </StackPanel>
                                </Border>
                            </StackPanel>
                        </Grid>

                        <!-- Hover-close overlay: appears top-right
                             after dwelling on the banner image for
                             a few seconds. Lets the user close the
                             banner once or disable it permanently. -->
                        <StackPanel x:Name="ListBannerCloseOverlay"
                                    Orientation="Horizontal"
                                    HorizontalAlignment="Right"
                                    VerticalAlignment="Top"
                                    Margin="0,10,10,0"
                                    Visibility="Collapsed">
                            <Border x:Name="ListBannerCloseBtn"
                                    Background="#1a1a22" CornerRadius="3"
                                    BorderThickness="1" BorderBrush="#3a3a48"
                                    Padding="9,4" Margin="0,0,6,0" Cursor="Hand">
                                <TextBlock Text="Close"
                                           FontSize="10" FontWeight="SemiBold"
                                           Foreground="#cccccc" FontFamily="Segoe UI"/>
                            </Border>
                            <Border x:Name="ListBannerDisableBtn"
                                    Background="#1a1a22" CornerRadius="3"
                                    BorderThickness="1" BorderBrush="#3a3a48"
                                    Padding="9,4" Cursor="Hand">
                                <TextBlock Text="Always disable"
                                           FontSize="10" FontWeight="SemiBold"
                                           Foreground="#cccccc" FontFamily="Segoe UI"/>
                            </Border>
                        </StackPanel>
                    </Grid>
                </Border>

                <!-- Section: Recently Played -->
                <!-- Sits between the Featured banner and the Custom
                     Installers list. Holds up to 8 small portrait
                     tiles representing recently launched VR games -
                     direct one-click "Start in VR". Auto-hidden if
                     empty (fresh install) or if the user dismissed
                     it via the hover-overlay's "Always disable".
                     Clicking the header collapses the tile list -
                     same idiom as the other section headers.   -->
                <StackPanel x:Name="RecentlyPlayedSection" Margin="0,0,0,18"
                            Visibility="Collapsed">
                    <Grid Margin="0,0,0,10" x:Name="RecentlyPlayedHeaderHost">
                        <StackPanel x:Name="RecentlyPlayedHeader"
                                    Orientation="Horizontal" HorizontalAlignment="Left"
                                    Cursor="Hand">
                            <Border CornerRadius="11" Background="#0dffffff"
                                    BorderThickness="1" BorderBrush="#22ffffff" Padding="10,6">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                    <Path Data="M 0,0 L 11,7 L 0,14 Z" Fill="#3fb6c8" Width="11" Height="14" Stretch="Uniform" Margin="0,1,11,0" VerticalAlignment="Center"/>
                                    <TextBlock Text="Recently Played" x:Name="RecentlyPlayedTitle"
                                               FontSize="13" FontWeight="SemiBold"
                                               Foreground="White" FontFamily="Segoe UI" VerticalAlignment="Center"/>
                                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="20,0,0,0">
                                        <Path Data="M 0,0 L 0,16 L 4.5,12 L 7,18 L 9.5,17 L 7,11.2 L 11,11 Z"
                                              Fill="#ffffff" Stroke="#222222" StrokeThickness="0.8"
                                              StrokeLineJoin="Round"
                                              Width="11" Height="15" Stretch="Uniform"
                                              VerticalAlignment="Center" Margin="0,0,7,0"/>
                                        <TextBlock Text="to launch in VR" x:Name="RecentlyPlayedSub"
                                                   FontSize="11" FontWeight="Medium" Foreground="#c7a13a"
                                                   FontFamily="Segoe UI" VerticalAlignment="Center"/>
                                    </StackPanel>
                                </StackPanel>
                            </Border>
                        </StackPanel>
                        <!-- Hover-close overlay: appears ~5s after the
                             user hovers the header. Same idiom as the
                             featured-banner overlay. Close = hide for
                             session, Always disable = persist via
                             the durable Hub state. -->
                        <StackPanel x:Name="RecentlyPlayedCloseOverlay"
                                    Orientation="Horizontal"
                                    HorizontalAlignment="Right"
                                    VerticalAlignment="Center"
                                    Visibility="Collapsed">
                            <Border x:Name="RecentlyPlayedCloseBtn"
                                    Background="#1a1a22" CornerRadius="3"
                                    BorderThickness="1" BorderBrush="#3a3a48"
                                    Padding="9,4" Margin="0,0,6,0" Cursor="Hand">
                                <TextBlock Text="Close"
                                           FontSize="10" FontWeight="SemiBold"
                                           Foreground="#cccccc" FontFamily="Segoe UI"/>
                            </Border>
                            <Border x:Name="RecentlyPlayedDisableBtn"
                                    Background="#1a1a22" CornerRadius="3"
                                    BorderThickness="1" BorderBrush="#3a3a48"
                                    Padding="9,4" Cursor="Hand">
                                <TextBlock Text="Always disable"
                                           FontSize="10" FontWeight="SemiBold"
                                           Foreground="#cccccc" FontFamily="Segoe UI"/>
                            </Border>
                        </StackPanel>
                    </Grid>
                    <WrapPanel x:Name="RecentlyPlayedList" Orientation="Horizontal"
                               HorizontalAlignment="Center"/>
                </StackPanel>

                <!-- Section: Custom Installers - Motion Controls -->
                <StackPanel Orientation="Horizontal" Margin="0,20,0,10"
                            x:Name="HeaderMC" Cursor="Hand" HorizontalAlignment="Left">
                    <Border CornerRadius="11" Background="#0dffffff"
                            BorderThickness="1" BorderBrush="#22ffffff" Padding="10,6">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Path Stroke="#44cc66" StrokeThickness="1.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round"
                                  Stretch="Uniform" Width="14" Height="14" Margin="0,0,10,0" VerticalAlignment="Center"
                                  Data="M13,2 L6.5,13 L11,13 L10,22 L17.5,10 L12.5,10 Z"/>
                            <TextBlock Text="Custom Installers" x:Name="HeaderMCTitle"
                                       FontSize="13" FontWeight="SemiBold"
                                       Foreground="White" FontFamily="Segoe UI" VerticalAlignment="Center"/>
                            <Viewbox Width="14" Height="14" Margin="11,0,7,0" VerticalAlignment="Center">
                            <Path Data="M7.7 8.2A4.3 2.2 0 1 1 16.3 8.2A4.3 2.2 0 1 1 7.7 8.2Z M12 9.8C10.8 9.8 10.2 10.9 10.3 12.1L10.9 17.6C11 18.8 11.2 19.4 12 19.4C12.8 19.4 13 18.8 13.1 17.6L13.7 12.1C13.8 10.9 13.2 9.8 12 9.8Z M11.1 11A0.9 0.9 0 1 1 12.9 11A0.9 0.9 0 1 1 11.1 11Z" Stroke="#44cc66" StrokeThickness="1.9" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="{x:Null}"/>
                        </Viewbox>
                            <TextBlock Text="Motion Controls" x:Name="HeaderMCKind"
                                       FontSize="13" FontWeight="Medium"
                                       Foreground="#44cc66" FontFamily="Segoe UI" VerticalAlignment="Center" Margin="0,0,0,0"/>
                            <TextBlock x:Name="HeaderMCSub" Text=""
                                       FontSize="11" FontWeight="Medium" Foreground="#7a7a86"
                                       FontFamily="Segoe UI" VerticalAlignment="Center" Margin="9,0,0,0"/>
                        </StackPanel>
                    </Border>
                </StackPanel>
                <WrapPanel x:Name="OwnGameList" Margin="0,22,0,30"
                           HorizontalAlignment="Center"/>

                <!-- Divider -->
                <Border Height="1" Background="#1e1e26" Margin="0,0,0,24" x:Name="DividerMC"/>

                <!-- Section: Custom Installers - Gamepad -->
                <StackPanel Orientation="Horizontal" Margin="0,0,0,10"
                            x:Name="HeaderGP" Cursor="Hand" HorizontalAlignment="Left">
                    <Border CornerRadius="11" Background="#0dffffff"
                            BorderThickness="1" BorderBrush="#22ffffff" Padding="10,6">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Path Stroke="#dd6600" StrokeThickness="1.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round"
                                  Stretch="Uniform" Width="14" Height="14" Margin="0,0,10,0" VerticalAlignment="Center"
                                  Data="M13,2 L6.5,13 L11,13 L10,22 L17.5,10 L12.5,10 Z"/>
                            <TextBlock Text="Custom Installers" x:Name="HeaderGPTitle"
                                       FontSize="13" FontWeight="SemiBold"
                                       Foreground="White" FontFamily="Segoe UI" VerticalAlignment="Center"/>
                            <Viewbox x:Name="HeaderGPMotionIcon" Width="16" Height="16" Margin="11,0,0,0" VerticalAlignment="Center" Visibility="Collapsed">
                                <Path Data="M7.7 8.2A4.3 2.2 0 1 1 16.3 8.2A4.3 2.2 0 1 1 7.7 8.2Z M12 9.8C10.8 9.8 10.2 10.9 10.3 12.1L10.9 17.6C11 18.8 11.2 19.4 12 19.4C12.8 19.4 13 18.8 13.1 17.6L13.7 12.1C13.8 10.9 13.2 9.8 12 9.8Z M11.1 11A0.9 0.9 0 1 1 12.9 11A0.9 0.9 0 1 1 11.1 11Z" Stroke="#44cc66" StrokeThickness="1.9" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="{x:Null}"/>
                            </Viewbox>
                            <TextBlock x:Name="HeaderGPEq" Text="=" Visibility="Collapsed" FontSize="14" FontWeight="Bold" Foreground="White" FontFamily="Segoe UI" VerticalAlignment="Center" Margin="5,0,5,0"/>
                            <Viewbox x:Name="HeaderGPGamepadIcon" Width="18" Height="18" Margin="11,0,7,0" VerticalAlignment="Center">
                            <Path Data="M8 8.7C5.3 8.7 3.9 10.7 3.3 13.8C2.9 16.1 4 17.6 5.7 17.6C7 17.6 7.6 16.5 8.5 16.1L15.5 16.1C16.4 16.5 17 17.6 18.3 17.6C20 17.6 21.1 16.1 20.7 13.8C20.1 10.7 18.7 8.7 16 8.7Z M6.4 11.6L6.4 14 M5.2 12.8L7.6 12.8 M14.7 11.7A1 1 0 1 1 16.7 11.7A1 1 0 1 1 14.7 11.7Z M16.5 13.3A1 1 0 1 1 18.5 13.3A1 1 0 1 1 16.5 13.3Z" Stroke="#dd6600" StrokeThickness="1.9" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Fill="{x:Null}"/>
                        </Viewbox>
                            <TextBlock Text="Gamepad controls" x:Name="HeaderGPKind"
                                       FontSize="13" FontWeight="Medium"
                                       Foreground="#dd6600" FontFamily="Segoe UI" VerticalAlignment="Center" Margin="0,0,0,0"/>
                            <TextBlock x:Name="HeaderGPSub" Text=""
                                       FontSize="11" FontWeight="Medium" Foreground="#7a7a86"
                                       FontFamily="Segoe UI" VerticalAlignment="Center" Margin="9,0,0,0"/>
                        </StackPanel>
                    </Border>
                </StackPanel>
                <WrapPanel x:Name="OwnGameListGP" Margin="0,22,0,30"
                           HorizontalAlignment="Center"/>

                <!-- Divider -->
                <Border Height="1" Background="#1e1e26" Margin="0,0,0,24" x:Name="DividerGP"/>

                <!-- Section: External Installers -->
                <StackPanel Orientation="Horizontal" Margin="0,0,0,10"
                            x:Name="HeaderExt" Cursor="Hand" HorizontalAlignment="Left">
                    <Border CornerRadius="11" Background="#0dffffff"
                            BorderThickness="1" BorderBrush="#22ffffff" Padding="10,6">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Path Data="M1,4 L1,11 L8,11 L8,6 M6,1 L11,1 L11,6 M11,1 L6,6"
                                  Stroke="#6fa8ff" StrokeThickness="1.5" StrokeStartLineCap="Round"
                                  StrokeEndLineCap="Round" Margin="0,0,10,0" VerticalAlignment="Center"/>
                            <TextBlock Text="Easy External Installers" x:Name="HeaderExtTitle"
                                       FontSize="13" FontWeight="SemiBold"
                                       Foreground="White" FontFamily="Segoe UI" VerticalAlignment="Center"/>
                            <Viewbox Width="14" Height="14" Margin="11,0,7,0" VerticalAlignment="Center">
                            <Path Data="M1,6 L11,6 M7,2 L11,6 L7,10"
                                  Stroke="#6fa8ff" StrokeThickness="1.5" StrokeStartLineCap="Round"
                                  StrokeEndLineCap="Round" StrokeLineJoin="Round"/>
                            </Viewbox>
                            <TextBlock Text="Leads to existing installers" x:Name="HeaderExtKind"
                                       FontSize="13" FontWeight="Medium"
                                       Foreground="#6fa8ff" FontFamily="Segoe UI" VerticalAlignment="Center" Margin="0,0,0,0"/>
                            <TextBlock x:Name="HeaderExtSub" Text=""
                                       FontSize="11" FontWeight="Medium" Foreground="#7a7a86"
                                       FontFamily="Segoe UI" VerticalAlignment="Center" Margin="9,0,0,0"/>
                        </StackPanel>
                    </Border>
                </StackPanel>
                <WrapPanel x:Name="ExternalGameList" Margin="0,22,0,0"
                           HorizontalAlignment="Center"/>

            </StackPanel>
            </Border>
        </ScrollViewer>

        <!-- Discover view: parallel to the list scroll viewer.
             Hidden by default; the toggle button in the header swaps
             between this and the list. -->
        <Grid Grid.Row="2" x:Name="DiscoverHost" Visibility="Collapsed">
            <Grid.Background>
                <!-- Same reasoning as the list background above: cached, or
                     it re-tiles the whole viewport on every scrolled pixel. -->
                <DrawingBrush TileMode="Tile" Viewport="0,0,24,24" ViewportUnits="Absolute"
                              RenderOptions.CachingHint="Cache"
                              RenderOptions.CacheInvalidationThresholdMinimum="0.5"
                              RenderOptions.CacheInvalidationThresholdMaximum="2.0">
                    <DrawingBrush.Drawing>
                        <DrawingGroup>
                            <GeometryDrawing Brush="#0f0f12">
                                <GeometryDrawing.Geometry>
                                    <RectangleGeometry Rect="0,0,24,24"/>
                                </GeometryDrawing.Geometry>
                            </GeometryDrawing>
                            <GeometryDrawing Brush="#222230">
                                <GeometryDrawing.Geometry>
                                    <EllipseGeometry Center="12,12" RadiusX="0.9" RadiusY="0.9"/>
                                </GeometryDrawing.Geometry>
                            </GeometryDrawing>
                        </DrawingGroup>
                    </DrawingBrush.Drawing>
                </DrawingBrush>
            </Grid.Background>

            <ScrollViewer x:Name="DiscoverTilesScroll"
                          VerticalScrollBarVisibility="Auto"
                          HorizontalScrollBarVisibility="Disabled">
                <StackPanel Margin="28,20,28,24">

                    <!-- Featured banner above the portrait grid.
                         Stretches to the full row width; the WrapPanel
                         below stays centered as before. -->
                    <Border x:Name="LibBanner" Height="140" CornerRadius="8"
                            Margin="0,0,0,22" Background="#0f0f15"
                            BorderThickness="1" BorderBrush="#2a2a35"
                            HorizontalAlignment="Stretch"
                            ClipToBounds="True">
                        <Grid>
                            <Rectangle x:Name="LibBannerBg" Fill="#0f0f15"
                                       IsHitTestVisible="False"
                                       HorizontalAlignment="Stretch" VerticalAlignment="Stretch"/>
                            <Image x:Name="LibBannerImage" Stretch="Uniform"
                                   HorizontalAlignment="Right" VerticalAlignment="Center"/>
                            <Rectangle x:Name="LibBannerFade" HorizontalAlignment="Stretch" VerticalAlignment="Stretch"
                                       IsHitTestVisible="False">
                                <Rectangle.Fill>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                        <GradientStop Color="#F00F0F15" Offset="0.0"/>
                                        <GradientStop Color="#C00F0F15" Offset="0.35"/>
                                        <GradientStop Color="#000F0F15" Offset="0.75"/>
                                    </LinearGradientBrush>
                                </Rectangle.Fill>
                            </Rectangle>

                            <Grid x:Name="LibBannerInnerGrid" Margin="22,16,22,16">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>

                                <StackPanel Grid.Row="0" VerticalAlignment="Top">
                                    <StackPanel Orientation="Horizontal" Margin="0,0,0,4">
                                        <Ellipse x:Name="LibBannerCtrlDot"
                                                 Width="7" Height="7" Fill="#dd6600"
                                                 VerticalAlignment="Center"
                                                 Margin="0,0,7,0"/>
                                        <TextBlock x:Name="LibBannerKicker"
                                                   Text="FEATURED VR MOD"
                                                   FontSize="10" FontWeight="SemiBold"
                                                   Foreground="#dd6600" FontFamily="Segoe UI"/>
                                    </StackPanel>
                                    <TextBlock x:Name="LibBannerTitle"
                                               Text="..." FontSize="22" FontWeight="SemiBold"
                                               Foreground="White" FontFamily="Segoe UI"
                                               TextWrapping="NoWrap" TextTrimming="None"
                                               MaxWidth="380" HorizontalAlignment="Left"/>
                                    <TextBlock x:Name="LibBannerSubtitle"
                                               Text="..." FontSize="11"
                                               Foreground="#bbbbbb" FontFamily="Segoe UI"
                                               Margin="0,4,0,0"
                                               TextWrapping="NoWrap" TextTrimming="CharacterEllipsis"
                                               MaxWidth="380" HorizontalAlignment="Left"/>
                                </StackPanel>

                                <StackPanel Grid.Row="1" Orientation="Horizontal"
                                            VerticalAlignment="Bottom">
                                    <Border x:Name="LibBannerShowBtn"
                                            Background="Transparent" CornerRadius="4"
                                            BorderThickness="2" BorderBrush="#bfa845"
                                            Padding="14,7" Margin="0,0,8,0" Cursor="Hand">
                                        <TextBlock Text="Show" x:Name="LibBannerShowBtnText"
                                                   FontSize="11" FontWeight="Bold"
                                                   Foreground="#bfa845" FontFamily="Segoe UI"/>
                                    </Border>
                                    <Border x:Name="LibBannerExploreBtn"
                                            Background="Transparent" CornerRadius="4"
                                            BorderThickness="1.5" BorderBrush="#dd6600"
                                            Padding="14,7" Cursor="Hand">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock Text="Explore all games" x:Name="LibBannerExploreBtnText"
                                                       FontSize="11" FontWeight="Bold"
                                                       Foreground="#dd6600" FontFamily="Segoe UI"/>
                                            <TextBlock Text="  &#x203A;" x:Name="LibBannerExploreBtnArrow"
                                                       FontSize="13" FontWeight="SemiBold"
                                                       Foreground="#dd6600" FontFamily="Segoe UI"/>
                                        </StackPanel>
                                    </Border>
                                </StackPanel>
                            </Grid>

                            <!-- Hover-close overlay (top-right). -->
                            <StackPanel x:Name="LibBannerCloseOverlay"
                                        Orientation="Horizontal"
                                        HorizontalAlignment="Right"
                                        VerticalAlignment="Top"
                                        Margin="0,10,10,0"
                                        Visibility="Collapsed">
                                <Border x:Name="LibBannerCloseBtn"
                                        Background="#1a1a22" CornerRadius="3"
                                        BorderThickness="1" BorderBrush="#3a3a48"
                                        Padding="9,4" Margin="0,0,6,0" Cursor="Hand">
                                    <TextBlock Text="Close"
                                               FontSize="10" FontWeight="SemiBold"
                                               Foreground="#cccccc" FontFamily="Segoe UI"/>
                                </Border>
                                <Border x:Name="LibBannerDisableBtn"
                                        Background="#1a1a22" CornerRadius="3"
                                        BorderThickness="1" BorderBrush="#3a3a48"
                                        Padding="9,4" Cursor="Hand">
                                    <TextBlock Text="Always disable"
                                               FontSize="10" FontWeight="SemiBold"
                                               Foreground="#cccccc" FontFamily="Segoe UI"/>
                                </Border>
                            </StackPanel>
                        </Grid>
                    </Border>

                    <!-- Portrait tile grid - stays centered as before. -->
                    <WrapPanel x:Name="DiscoverTilesPanel"
                               Orientation="Horizontal"
                               HorizontalAlignment="Center"/>
                </StackPanel>
            </ScrollViewer>

            <ScrollViewer x:Name="DiscoverDetailScroll"
                          VerticalScrollBarVisibility="Auto"
                          HorizontalScrollBarVisibility="Disabled"
                          Visibility="Collapsed">
                <Grid x:Name="DiscoverDetailHost" Margin="28,20,28,24"/>
            </ScrollViewer>

            <!-- Discover Overview: separate page reachable from the
                 library banner's Explore button. Banner + filters +
                 horizontally-scrollable genre rows. Sibling to
                 tiles + detail; the back button returns to library. -->
            <ScrollViewer x:Name="DiscoverOverviewScroll"
                          VerticalScrollBarVisibility="Auto"
                          HorizontalScrollBarVisibility="Disabled"
                          Visibility="Collapsed">
                <StackPanel Margin="28,20,28,24">

                    <!-- Banner with integrated back button (top-left).
                         Larger height so the back button sits inside
                         without crowding the title. The image takes
                         the right half so it stays prominent. -->
                    <Border x:Name="OvBanner" Height="200" CornerRadius="8"
                            Margin="0,0,0,18" Background="#0f0f15"
                            BorderThickness="1" BorderBrush="#2a2a35"
                            ClipToBounds="True">
                        <Grid>
                            <Rectangle x:Name="OvBannerBg" Fill="#0f0f15"
                                       IsHitTestVisible="False"
                                       HorizontalAlignment="Stretch" VerticalAlignment="Stretch"/>
                            <Image x:Name="OvBannerImage" Stretch="Uniform"
                                   HorizontalAlignment="Right" VerticalAlignment="Center"/>
                            <Rectangle x:Name="OvBannerFade" HorizontalAlignment="Stretch" VerticalAlignment="Stretch"
                                       IsHitTestVisible="False">
                                <Rectangle.Fill>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                        <GradientStop Color="#F00F0F15" Offset="0.0"/>
                                        <GradientStop Color="#E60F0F15" Offset="0.12"/>
                                        <GradientStop Color="#CC0F0F15" Offset="0.24"/>
                                        <GradientStop Color="#A60F0F15" Offset="0.36"/>
                                        <GradientStop Color="#7A0F0F15" Offset="0.48"/>
                                        <GradientStop Color="#4E0F0F15" Offset="0.60"/>
                                        <GradientStop Color="#260F0F15" Offset="0.72"/>
                                        <GradientStop Color="#000F0F15" Offset="0.85"/>
                                    </LinearGradientBrush>
                                </Rectangle.Fill>
                            </Rectangle>

                            <!-- Back button - sits inside the banner top-left
                                 so the page doesn't feel split into stripes. -->
                            <Border x:Name="OverviewBackBtn" CornerRadius="6"
                                    Background="Transparent"
                                    BorderThickness="1" BorderBrush="#3a3a48"
                                    Padding="11,6,15,6"
                                    HorizontalAlignment="Left" VerticalAlignment="Top"
                                    Margin="14,14,0,0" Cursor="Hand">
                                <StackPanel Orientation="Horizontal">
                                    <Path Data="M 6,0 L 0,5 L 6,10"
                                          Stroke="#cccccc" StrokeThickness="1.8"
                                          StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                                          StrokeLineJoin="Round" Fill="Transparent"
                                          VerticalAlignment="Center" Margin="0,0,8,0"/>
                                    <TextBlock x:Name="OverviewBackBtnText"
                                               Text="Back to library"
                                               FontSize="11" FontWeight="SemiBold"
                                               Foreground="#cccccc" FontFamily="Segoe UI"
                                               VerticalAlignment="Center"/>
                                </StackPanel>
                            </Border>

                            <!-- Title block - shifted down to make room for
                                 the back button overlay. -->
                            <Grid x:Name="OvBannerTitleGrid" Margin="22,68,22,16">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>

                                <StackPanel Grid.Row="0" VerticalAlignment="Top">
                                    <StackPanel Orientation="Horizontal" Margin="0,0,0,4">
                                        <Ellipse x:Name="OvBannerCtrlDot"
                                                 Width="7" Height="7" Fill="#dd6600"
                                                 VerticalAlignment="Center"
                                                 Margin="0,0,7,0"/>
                                        <TextBlock x:Name="OvBannerKicker"
                                                   Text="FEATURED PICK"
                                                   FontSize="10" FontWeight="SemiBold"
                                                   Foreground="#dd6600" FontFamily="Segoe UI"/>
                                    </StackPanel>
                                    <TextBlock x:Name="OvBannerTitle"
                                               Text="..." FontSize="24" FontWeight="SemiBold"
                                               Foreground="White" FontFamily="Segoe UI"
                                               TextWrapping="NoWrap" TextTrimming="None"
                                               MaxWidth="400" HorizontalAlignment="Left"/>
                                    <TextBlock x:Name="OvBannerSubtitle"
                                               Text="..." FontSize="11"
                                               Foreground="#bbbbbb" FontFamily="Segoe UI"
                                               Margin="0,5,0,0"
                                               TextWrapping="NoWrap" TextTrimming="CharacterEllipsis"
                                               MaxWidth="400" HorizontalAlignment="Left"/>
                                </StackPanel>

                                <StackPanel Grid.Row="1" Orientation="Horizontal"
                                            VerticalAlignment="Bottom">
                                    <Border x:Name="OvBannerShowBtn"
                                            Background="Transparent" CornerRadius="4"
                                            BorderThickness="2" BorderBrush="#bfa845"
                                            Padding="14,7" Margin="0,0,8,0" Cursor="Hand">
                                        <TextBlock x:Name="OvBannerShowBtnText" Text="View this mod"
                                                   FontSize="11" FontWeight="Bold"
                                                   Foreground="#bfa845" FontFamily="Segoe UI"/>
                                    </Border>
                                    <Border x:Name="OvBannerShuffleBtn"
                                            Background="Transparent" CornerRadius="4"
                                            BorderThickness="1.5" BorderBrush="#dd6600"
                                            Padding="12,7" Cursor="Hand">
                                        <TextBlock x:Name="OvBannerShuffleBtnText" Text="Shuffle"
                                                   FontSize="11" FontWeight="Bold"
                                                   Foreground="#dd6600" FontFamily="Segoe UI"/>
                                    </Border>
                                </StackPanel>
                            </Grid>
                        </Grid>
                    </Border>

                    <!-- Genre filter: bigger, bolder pills with colored
                         left accent bar - feels more like a feature
                         than a control. Label sits in the same small
                         pill-box as the PC POWER mode toggle below
                         so the two section headers read as paired
                         elements (one static, one clickable). -->
                    <Border x:Name="OvGenreHeader" Margin="0,0,0,8"
                            CornerRadius="5" Padding="8,5,8,5"
                            HorizontalAlignment="Left"
                            Background="#0d0d12"
                            BorderThickness="1" BorderBrush="#22222e">
                        <TextBlock Text="GENRE" FontSize="10" FontWeight="SemiBold"
                                   Foreground="#666677" FontFamily="Segoe UI"
                                   VerticalAlignment="Center"/>
                    </Border>
                    <WrapPanel x:Name="OvGenreFilter" Margin="0,0,0,14"
                               HorizontalAlignment="Left" MaxWidth="780"/>

                    <!-- Power-Filter mode toggle. Click the pill to
                         switch between Cumulative ("Your PC" - shows
                         everything up to this tier) and Exact ("only
                         games of this specific tier"). The mode name
                         is part of the label so the user sees at a
                         glance which mode is currently active. The
                         actual tier pills below this header are
                         unchanged and behave the same way - only
                         their semantic interpretation changes
                         depending on the active mode. -->
                    <Border x:Name="OvPowerModeToggle" Margin="0,0,0,8"
                            CornerRadius="5" Padding="8,5,8,5"
                            HorizontalAlignment="Left"
                            Background="#0d0d12"
                            BorderThickness="1" BorderBrush="#22222e"
                            Cursor="Hand"
                            ToolTip="Click to toggle between Your PC (cumulative) and Exact Tier (filter by specific tier)">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="PC POWER" FontSize="10" FontWeight="SemiBold"
                                       Foreground="#666677" FontFamily="Segoe UI"
                                       VerticalAlignment="Center"/>
                            <TextBlock Text=" &#183; " FontSize="10" FontWeight="SemiBold"
                                       Foreground="#444452" FontFamily="Segoe UI"
                                       VerticalAlignment="Center"/>
                            <TextBlock x:Name="OvPowerModeLabel" Text="Your PC"
                                       FontSize="11" FontWeight="Bold"
                                       Foreground="#ffaa66" FontFamily="Segoe UI"
                                       VerticalAlignment="Center"/>
                            <Path Margin="6,2,0,0" Width="8" Height="6"
                                  Stroke="#888899" StrokeThickness="1.4"
                                  StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                                  StrokeLineJoin="Round"
                                  VerticalAlignment="Center"
                                  Data="M 0,1 L 4,5 L 8,1"/>
                        </StackPanel>
                    </Border>
                    <WrapPanel x:Name="OvPowerFilter" Margin="0,0,0,28"
                               HorizontalAlignment="Left"/>

                    <StackPanel x:Name="OvGenreRows"/>
                </StackPanel>
            </ScrollViewer>
        </Grid>

        <!-- Global game-order overlay. Existing tile controls are reparented
             in-place when an option changes; no cards are rebuilt and their
             install state, events and image caches therefore survive. -->
        <Grid x:Name="OrderOverlay" Grid.Row="0" Grid.RowSpan="3"
              Panel.ZIndex="998" Visibility="Collapsed">
            <Border x:Name="OrderScrim" Background="#01000000"/>
            <Border Background="#16161a" CornerRadius="8"
                    BorderThickness="1" BorderBrush="#3a3a48"
                    Padding="6" Margin="0,60,203,0"
                    HorizontalAlignment="Right" VerticalAlignment="Top">
                <StackPanel Width="230">
                    <TextBlock Text="SORT EVERY GAME LIST" FontSize="10"
                               Foreground="#555568" FontFamily="Segoe UI"
                               Margin="8,6,0,4"/>
                    <Border x:Name="OrderChoiceHub" Background="Transparent"
                            CornerRadius="7" Padding="8,8" Cursor="Hand">
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                            <StackPanel>
                                <TextBlock Text="Alphabetical" FontSize="13" Foreground="#d8dee3" FontFamily="Segoe UI"/>
                                <TextBlock Text="A-Z, with game series in order" FontSize="11" Foreground="#6a6a7e" FontFamily="Segoe UI" Margin="0,2,0,0"/>
                            </StackPanel>
                            <Ellipse x:Name="OrderDotHub" Grid.Column="1" Width="8" Height="8"
                                     Fill="#3a8add" Margin="10,0,3,0" VerticalAlignment="Center"/>
                        </Grid>
                    </Border>
                    <Border x:Name="OrderChoiceRelease" Background="Transparent"
                            CornerRadius="7" Padding="8,8" Cursor="Hand">
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                            <StackPanel>
                                <TextBlock Text="VR mod release" FontSize="13" Foreground="#d8dee3" FontFamily="Segoe UI"/>
                                <TextBlock Text="Newest verified release first" FontSize="11" Foreground="#6a6a7e" FontFamily="Segoe UI" Margin="0,2,0,0"/>
                            </StackPanel>
                            <Ellipse x:Name="OrderDotRelease" Grid.Column="1" Width="8" Height="8"
                                     Fill="#3a8add" Margin="10,0,3,0" VerticalAlignment="Center" Visibility="Collapsed"/>
                        </Grid>
                    </Border>
                    <Border x:Name="OrderChoiceAdded" Background="Transparent"
                            CornerRadius="7" Padding="8,8" Cursor="Hand">
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                            <StackPanel>
                                <TextBlock Text="Added to Hub" FontSize="13" Foreground="#d8dee3" FontFamily="Segoe UI"/>
                                <TextBlock Text="Newest Hub additions first" FontSize="11" Foreground="#6a6a7e" FontFamily="Segoe UI" Margin="0,2,0,0"/>
                            </StackPanel>
                            <Ellipse x:Name="OrderDotAdded" Grid.Column="1" Width="8" Height="8"
                                     Fill="#3a8add" Margin="10,0,3,0" VerticalAlignment="Center" Visibility="Collapsed"/>
                        </Grid>
                    </Border>
                    <TextBlock Text="Unknown dates keep their alphabetical order."
                               FontSize="10" Foreground="#555568" FontFamily="Segoe UI"
                               Margin="8,6,8,6" TextWrapping="Wrap"/>
                </StackPanel>
            </Border>
        </Grid>

        <!-- Help & Feedback menu overlay (in-window, not a Popup). Spans all
             rows and sits on top (ZIndex). The scrim is near-transparent but
             hit-testable, so a click outside the menu closes it and goes
             nowhere else. The menu and the banner/cards are separate branches
             of one visual tree, so a click on the menu can never route to them. -->
        <Grid x:Name="MenuOverlay" Grid.Row="0" Grid.RowSpan="3"
              Panel.ZIndex="999" Visibility="Collapsed">
            <Border x:Name="MenuScrim" Background="#01000000"/>
            <Border Background="#16161a" CornerRadius="8"
                    BorderThickness="1" BorderBrush="#3a3a48"
                    Padding="6" Margin="0,60,200,0"
                    HorizontalAlignment="Right" VerticalAlignment="Top">
                <StackPanel Width="224">
                    <TextBlock Text="HELP &amp; FEEDBACK" FontSize="10"
                               Foreground="#555568" FontFamily="Segoe UI"
                               Margin="8,6,0,4"/>
                    <Border x:Name="MiSuggest" Background="Transparent"
                            CornerRadius="7" Padding="8,9" Cursor="Hand">
                        <StackPanel Orientation="Horizontal">
                            <Ellipse Width="8" Height="8" Fill="#dd6600"
                                     VerticalAlignment="Center" Margin="2,0,11,0"/>
                            <StackPanel>
                                <TextBlock Text="Suggest a VR mod" FontSize="13"
                                           Foreground="#d8dee3" FontFamily="Segoe UI"/>
                                <TextBlock Text="Opens a short GitHub form" FontSize="11"
                                           Foreground="#6a6a7e" FontFamily="Segoe UI"
                                           Margin="0,2,0,0"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>
                    <Border x:Name="MiReport" Background="Transparent"
                            CornerRadius="7" Padding="8,9" Cursor="Hand">
                        <StackPanel Orientation="Horizontal">
                            <Ellipse Width="8" Height="8" Fill="#d8923a"
                                     VerticalAlignment="Center" Margin="2,0,11,0"/>
                            <StackPanel>
                                <TextBlock Text="Logs &amp; report a problem" FontSize="13"
                                           Foreground="#d8dee3" FontFamily="Segoe UI"/>
                                <TextBlock Text="Opens the latest log and report form" FontSize="11"
                                           Foreground="#6a6a7e" FontFamily="Segoe UI"
                                           Margin="0,2,0,0"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>
                    <Border x:Name="MiDiscord" Background="Transparent"
                            CornerRadius="7" Padding="8,9" Cursor="Hand">
                        <StackPanel Orientation="Horizontal">
                            <Ellipse Width="8" Height="8" Fill="#5865F2"
                                     VerticalAlignment="Center" Margin="2,0,11,0"/>
                            <StackPanel>
                                <TextBlock Text="Join our Discord" FontSize="13"
                                           Foreground="#d8dee3" FontFamily="Segoe UI"/>
                                <TextBlock Text="Flat2VR modding community" FontSize="11"
                                           Foreground="#6a6a7e" FontFamily="Segoe UI"
                                           Margin="0,2,0,0"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>
                    <Border x:Name="MiStyle" Background="Transparent"
                            CornerRadius="7" Padding="8,9" Cursor="Hand">
                        <StackPanel Orientation="Horizontal">
                            <Ellipse Width="8" Height="8" Fill="#3a8add"
                                     VerticalAlignment="Center" Margin="2,0,11,0"/>
                            <StackPanel>
                                <TextBlock Text="Switch Hub Style" FontSize="13"
                                           Foreground="#d8dee3" FontFamily="Segoe UI"/>
                                <TextBlock Text="Toggle frosted / classic tiles" FontSize="11"
                                           Foreground="#6a6a7e" FontFamily="Segoe UI"
                                           Margin="0,2,0,0"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>
                    <Border x:Name="MiShortcut" Background="Transparent"
                            CornerRadius="7" Padding="8,9" Cursor="Hand">
                        <StackPanel Orientation="Horizontal">
                            <Ellipse x:Name="MiShortcutDot" Width="8" Height="8" Fill="#4ac07a"
                                     VerticalAlignment="Center" Margin="2,0,11,0"/>
                            <StackPanel>
                                <TextBlock Text="Desktop Shortcut" FontSize="13"
                                           Foreground="#d8dee3" FontFamily="Segoe UI"/>
                                <TextBlock x:Name="MiShortcutSub" Text="Currently on - click to turn off" FontSize="11"
                                           Foreground="#6a6a7e" FontFamily="Segoe UI"
                                           Margin="0,2,0,0"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>
                    <Border BorderThickness="0,1,0,0" BorderBrush="#26262e"
                            Margin="6,4,6,0" Padding="2,8,2,4">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="&#9432;" FontSize="12"
                                       Foreground="#6a6a7e" Margin="0,0,7,0"
                                       VerticalAlignment="Top"/>
                            <TextBlock Text="UEVR / Universal Unreal Engine VR games aren't listed - they're covered by the UEVR Deluxe entry in the Hub."
                                       FontSize="11" Foreground="#6a6a7e"
                                       FontFamily="Segoe UI" TextWrapping="Wrap"
                                       Width="190"/>
                        </StackPanel>
                    </Border>
                </StackPanel>
            </Border>
        </Grid>
    </Grid>
</Window>
"@

$reader    = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window    = [Windows.Markup.XamlReader]::Load($reader)
$global:window = $window

# Keep the global Order + Search controls usable down to the supported
# 500px window minimum. The full product name yields to "PCVR Hub" first;
# only at very narrow widths does the branding disappear completely. Search
# and ordering always remain visible and never overlap each other.
function global:Update-HubHeaderResponsiveLayout {
    if (-not $global:window) { return }
    $width = [double]$global:window.ActualWidth
    if ($width -le 0) { $width = [double]$global:window.Width }
    $compact = ($width -lt 780)
    $narrow = ($width -lt 620)

    $title = $global:window.FindName('HeaderHubTitle')
    $glow = $global:window.FindName('HeaderHubTitleGlow')
    $titleGrid = $global:window.FindName('HeaderTitleGrid')
    $vrIcon = $global:window.FindName('HeaderVrIcon')
    $version = $global:window.FindName('VersionBadge')
    $tagline = $global:window.FindName('HeaderTagline')
    $order = $global:window.FindName('OrderPill')
    $prefix = $global:window.FindName('OrderPrefix')
    $searchColumn = $global:window.FindName('HeaderSearchColumn')
    $header = $global:window.FindName('HeaderBorder')
    $scanSlot = $global:window.FindName('TopScanSlot')

    $caption = if ($compact) { 'PCVR Hub' } else { 'PCVR Mods Installer Hub' }
    if ($title) { $title.Text = $caption }
    if ($glow) { $glow.Text = $caption }
    if ($titleGrid) {
        $titleGrid.Visibility = if ($narrow) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    }
    if ($vrIcon) {
        $vrIcon.Visibility = if ($narrow) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    }
    if ($version) {
        $version.Visibility = if ($compact) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    }
    if ($tagline) {
        $tagline.Visibility = if ($compact) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    }
    if ($prefix) {
        $prefix.Visibility = if ($narrow) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    }
    if ($order) { $order.Width = if ($narrow) { 112 } else { 144 } }
    if ($searchColumn) { $searchColumn.Width = [System.Windows.GridLength]::new($(if ($narrow) { 115 } else { 165 })) }
    if ($header) {
        $header.Padding = if ($narrow) {
            [System.Windows.Thickness]::new(14, 20, 14, 14)
        } else {
            [System.Windows.Thickness]::new(28, 20, 28, 14)
        }
    }
    if ($scanSlot) {
        $scanSlot.Margin = if ($narrow) {
            [System.Windows.Thickness]::new(0)
        } else {
            [System.Windows.Thickness]::new(44, 0, 0, 0)
        }
    }
}
$window.Add_SizeChanged({ Update-HubHeaderResponsiveLayout })
$window.Add_Loaded({ Update-HubHeaderResponsiveLayout })

# Restore saved window geometry (Width/Height/Left/Top/Maximized) -
# user resizes/moves get persisted on close (Add_Closing handler in
# Startup.ps1). Hooked into SourceInitialized: that event fires
# after the window handle exists but BEFORE the first layout pass
# and ShowDialog's CenterScreen auto-position. Setting these
# properties immediately after XamlReader.Load is unreliable
# because the XAML's WindowStartupLocation=CenterScreen gets
# re-applied at ShowDialog time and clobbers Left/Top.
$window.Add_SourceInitialized({
    # Restore saved window geometry. SourceInitialized fires after
    # the window handle exists but BEFORE first layout/show, so
    # Manual placement here correctly overrides the XAML's
    # WindowStartupLocation=CenterScreen.
    if (-not (Get-Command Get-HubSetting -ErrorAction SilentlyContinue)) { return }
    try {
        $savedMaximized = [string](Get-HubSetting -Key "winMaximized" -Default "")
        $rawW = Get-HubSetting -Key "winWidth"  -Default $null
        $rawH = Get-HubSetting -Key "winHeight" -Default $null
        $rawL = Get-HubSetting -Key "winLeft"   -Default $null
        $rawT = Get-HubSetting -Key "winTop"    -Default $null

        function _coerceDouble($v) {
            if ($null -eq $v) { return $null }
            if ($v -is [double] -or $v -is [int] -or $v -is [long]) { return [double]$v }
            $s = [string]$v
            if ($s -eq "") { return $null }
            try {
                return [double]::Parse($s, [System.Globalization.CultureInfo]::InvariantCulture)
            } catch {
                try { return [double]$v } catch { return $null }
            }
        }
        $savedW = _coerceDouble $rawW
        $savedH = _coerceDouble $rawH
        $savedL = _coerceDouble $rawL
        $savedT = _coerceDouble $rawT

        if ($savedW -and $savedW -ge 500) { $window.Width  = $savedW }
        if ($savedH -and $savedH -ge 400) { $window.Height = $savedH }

        if ($savedL -ne $null -and $savedT -ne $null) {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            $onScreen = $false
            try {
                foreach ($scr in [System.Windows.Forms.Screen]::AllScreens) {
                    $wa = $scr.WorkingArea
                    if ($savedL -ge ($wa.X - 50)        -and
                        $savedT -ge $wa.Y               -and
                        $savedL -lt ($wa.X + $wa.Width  - 100) -and
                        $savedT -lt ($wa.Y + $wa.Height - 50)) {
                        $onScreen = $true; break
                    }
                }
            } catch { }
            if ($onScreen) {
                $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::Manual
                $window.Left = $savedL
                $window.Top  = $savedT
            }
        }

        if ($savedMaximized -eq "True" -or $savedMaximized -eq "true") {
            $window.WindowState = [System.Windows.WindowState]::Maximized
        }
    } catch { }
})

# Tell Windows this is its own app so the taskbar uses our icon
# instead of grouping under powershell.exe (which gives the blue
# PS square). Must happen before the window is created.
#
# We define the shell32 P/Invoke via Reflection.Emit, NOT Add-Type.
# Add-Type -MemberDefinition runs csc and writes a fresh temp DLL to
# disk on every launch; Windows then verifies that new DLL over the
# network (Authenticode CTL / Defender cloud), which can stall ~15s on
# a slow/blocked connection and was freezing startup. A dynamic
# in-memory assembly has no disk DLL and no csc step - nothing to
# verify, no network wait - so we set the id synchronously here, early,
# and keep the correct taskbar icon.
try {
    $aidName = New-Object System.Reflection.AssemblyName "PCVRHubAppId"
    $aidAsm  = [System.AppDomain]::CurrentDomain.DefineDynamicAssembly(
                   $aidName, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
    $aidMod  = $aidAsm.DefineDynamicModule("PCVRHubAppIdMod")
    $aidType = $aidMod.DefineType("Win32_AppId", [System.Reflection.TypeAttributes]::Public)
    $aidM    = $aidType.DefinePInvokeMethod(
                   "SetCurrentProcessExplicitAppUserModelID",
                   "shell32.dll",
                   ([System.Reflection.MethodAttributes]::Public -bor [System.Reflection.MethodAttributes]::Static),
                   [System.Reflection.CallingConventions]::Standard,
                   [int],
                   @([string]),
                   [System.Runtime.InteropServices.CallingConvention]::StdCall,
                   [System.Runtime.InteropServices.CharSet]::Unicode)
    $aidM.SetImplementationFlags(
        ($aidM.GetMethodImplementationFlags() -bor [System.Reflection.MethodImplAttributes]::PreserveSig))
    $aidReady = $aidType.CreateType()
    [void]$aidReady.GetMethod("SetCurrentProcessExplicitAppUserModelID").Invoke(
        $null, @("MrNIce.PCVRModsHub.$HUB_VERSION"))
} catch {}

# Set the title-bar icon. Without this WPF inherits the host
# process icon (powershell.exe blue square). We draw the VR
# goggles glyph (same shape as in the header) to a bitmap so it
# stays recognisable even at 16x16 - the ICO renders as a blob
# at title-bar size.
try {
    $iconSize = 32
    $iconCanvas = New-Object System.Windows.Controls.Canvas
    $iconCanvas.Width  = $iconSize
    $iconCanvas.Height = $iconSize
    $iconCanvas.Background = [System.Windows.Media.Brushes]::Transparent

    # Goggles outline - scaled & centered on a 32x32 canvas.
    # Source path uses a 32x17 viewbox; we shift down 7px so the
    # goggles sit centered vertically.
    $goggles = New-Object System.Windows.Shapes.Path
    $goggles.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    $goggles.StrokeThickness = 2.8
    $goggles.Fill = [System.Windows.Media.Brushes]::Transparent
    $geom = [System.Windows.Media.Geometry]::Parse("M5,3 H27 Q30,3 30,6 V11 Q30,14 27,14 H21 Q19,14 18,12.5 L17,11 Q16,10 15,11 L14,12.5 Q13,14 11,14 H5 Q2,14 2,11 V6 Q2,3 5,3 Z")
    $goggles.Data = $geom
    [System.Windows.Controls.Canvas]::SetTop($goggles, 7)
    $iconCanvas.Children.Add($goggles) | Out-Null

    $eyeColor = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
    $eyeL = New-Object System.Windows.Shapes.Ellipse
    $eyeL.Width = 4; $eyeL.Height = 4; $eyeL.Fill = $eyeColor
    [System.Windows.Controls.Canvas]::SetLeft($eyeL, 7);  [System.Windows.Controls.Canvas]::SetTop($eyeL, 14)
    $iconCanvas.Children.Add($eyeL) | Out-Null

    $eyeR = New-Object System.Windows.Shapes.Ellipse
    $eyeR.Width = 4; $eyeR.Height = 4; $eyeR.Fill = $eyeColor
    [System.Windows.Controls.Canvas]::SetLeft($eyeR, 21); [System.Windows.Controls.Canvas]::SetTop($eyeR, 14)
    $iconCanvas.Children.Add($eyeR) | Out-Null

    $iconCanvas.Measure([System.Windows.Size]::new($iconSize, $iconSize))
    $iconCanvas.Arrange([System.Windows.Rect]::new(0, 0, $iconSize, $iconSize))

    $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap (
        $iconSize, $iconSize, 96, 96,
        [System.Windows.Media.PixelFormats]::Pbgra32
    )
    $rtb.Render($iconCanvas)
    $window.Icon = $rtb

    # Mirror the goggles icon onto this process's console window (titlebar)
    # AND pin the console's taskbar button to the Hub AppUserModelID, so the
    # taskbar shows the goggles there too instead of the default PowerShell
    # icon. Cosmetic, best-effort; never blocks startup and never changes
    # the window's visibility (so DEBUG.bat's visible console is unaffected).
    try {
        Add-Type -AssemblyName System.Drawing
        if (-not ('ConWin.Native' -as [type])) {
            Add-Type -Namespace ConWin -Name Native -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern System.IntPtr GetConsoleWindow();
[DllImport("user32.dll")]   public static extern System.IntPtr SendMessage(System.IntPtr hWnd, uint Msg, System.IntPtr wParam, System.IntPtr lParam);
'@
        }
        $hCon = [ConWin.Native]::GetConsoleWindow()
        if ($hCon -ne [System.IntPtr]::Zero) {
            $pngEnc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
            $pngEnc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb))
            $ms = New-Object System.IO.MemoryStream
            $pngEnc.Save($ms); $ms.Position = 0
            $gbmp  = New-Object System.Drawing.Bitmap $ms
            $hIcon = $gbmp.GetHicon()
            $WM_SETICON = 0x80
            [ConWin.Native]::SendMessage($hCon, $WM_SETICON, [System.IntPtr]1, $hIcon) | Out-Null
            [ConWin.Native]::SendMessage($hCon, $WM_SETICON, [System.IntPtr]0, $hIcon) | Out-Null
            $ms.Dispose()

            # Taskbar: give the console window the same AppUserModelID as the
            # Hub window (set process-wide above) via its property store, so
            # the taskbar groups it under the goggles icon, not PowerShell.
            try {
                if (-not ('PCVRWinAppId' -as [type])) {
                    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class PCVRWinAppId {
    [StructLayout(LayoutKind.Sequential)]
    public struct PropertyKey { public Guid fmtid; public uint pid; }
    [StructLayout(LayoutKind.Explicit)]
    public struct PropVariant { [FieldOffset(0)] public ushort vt; [FieldOffset(8)] public IntPtr p; }
    [ComImport, Guid("886d8eeb-8cf2-4446-8d02-cdba1dbdcf99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IPropertyStore {
        int GetCount(out uint c);
        int GetAt(uint i, out PropertyKey k);
        int GetValue(ref PropertyKey k, out PropVariant v);
        int SetValue(ref PropertyKey k, ref PropVariant v);
        int Commit();
    }
    [DllImport("shell32.dll")] static extern int SHGetPropertyStoreForWindow(IntPtr h, ref Guid riid, out IPropertyStore ps);
    [DllImport("ole32.dll")]   static extern int PropVariantClear(ref PropVariant pv);
    public static void Set(IntPtr hwnd, string appId) {
        Guid iid = typeof(IPropertyStore).GUID;
        IPropertyStore ps;
        if (SHGetPropertyStoreForWindow(hwnd, ref iid, out ps) != 0 || ps == null) { return; }
        PropertyKey key = new PropertyKey();
        key.fmtid = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3");
        key.pid = 5;
        PropVariant pv = new PropVariant();
        pv.vt = 31;
        pv.p = Marshal.StringToCoTaskMemUni(appId);
        ps.SetValue(ref key, ref pv);
        ps.Commit();
        PropVariantClear(ref pv);
        Marshal.ReleaseComObject(ps);
    }
}
'@
                }
                [PCVRWinAppId]::Set($hCon, "MrNIce.PCVRModsHub.$HUB_VERSION")
            } catch {}
        }
    } catch {}
} catch {}
