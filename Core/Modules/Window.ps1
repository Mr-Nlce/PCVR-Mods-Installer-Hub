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
        <Border Grid.Row="0" Background="#0d0d0f" Padding="28,20,28,14">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="165"/>
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
                        <Grid VerticalAlignment="Center">
                            <!-- Glow layer: a hidden-color clone carrying only the
                                 DropShadow. It is NOT the element that scales on hover,
                                 so the glow stays crisp during the hover-grow. -->
                            <TextBlock Text="PCVR Mods Installer Hub"
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
                    <Border x:Name="UpdateBanner" Background="#1a2e1a" CornerRadius="5"
                            Padding="10,5" Margin="0,6,0,0"
                            Visibility="Collapsed" Cursor="Hand">
                        <StackPanel Orientation="Horizontal">
                            <Border Width="6" Height="6" CornerRadius="3"
                                    Background="#66cc66" Margin="0,0,7,0"
                                    VerticalAlignment="Center"/>
                            <TextBlock x:Name="UpdateBannerText"
                                       FontSize="11" Foreground="#88dd88"
                                       FontFamily="Segoe UI" VerticalAlignment="Center"/>
                            <TextBlock Text=" - Click to update"
                                       FontSize="11" Foreground="#555568"
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
                <Border Grid.Column="2" Background="#16161a" CornerRadius="6"
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
                <Border x:Name="FilterAll" CornerRadius="6" Padding="15,9" Margin="0,0,7,0"
                        BorderThickness="1" BorderBrush="#5566aa"
                        Background="#000000" Cursor="Hand">
                    <TextBlock Text="All" FontSize="13" FontWeight="SemiBold"
                               Foreground="White" FontFamily="Segoe UI"/>
                </Border>
                <Border x:Name="FilterMC" CornerRadius="6" Padding="15,9" Margin="0,0,7,0"
                        BorderThickness="1" BorderBrush="#0fffffff"
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
                <Border x:Name="FilterGP" CornerRadius="6" Padding="15,9"
                        BorderThickness="1" BorderBrush="#0fffffff"
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
                            <StackPanel Orientation="Horizontal">
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
                                <TextBlock x:Name="CheckInstalledText" Text="Scan games"
                                           FontSize="12" FontWeight="SemiBold"
                                           Foreground="#e8f5ec" FontFamily="Segoe UI"
                                           VerticalAlignment="Center"
                                           TextWrapping="NoWrap"/>
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
                                    <Path Data="M 0,0 L 7,4 L 0,8 Z" Fill="#5fff8f"
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
                    <DrawingBrush TileMode="Tile" Viewport="0,0,24,24" ViewportUnits="Absolute">
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
                             .hub-settings.json. -->
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
                            <TextBlock Text="External Installers" x:Name="HeaderExtTitle"
                                       FontSize="13" FontWeight="SemiBold"
                                       Foreground="White" FontFamily="Segoe UI" VerticalAlignment="Center"/>
                            <TextBlock x:Name="HeaderExtCount" Text=""
                                       FontSize="11" FontWeight="Medium" Foreground="#7a7a86"
                                       FontFamily="Segoe UI" VerticalAlignment="Center" Margin="11,0,0,0"/>
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
                <DrawingBrush TileMode="Tile" Viewport="0,0,24,24" ViewportUnits="Absolute">
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
                                <TextBlock Text="Report a problem" FontSize="13"
                                           Foreground="#d8dee3" FontFamily="Segoe UI"/>
                                <TextBlock Text="Grabs your latest log automatically" FontSize="11"
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

# Wire up version label and update banner
$updateBanner     = $window.FindName("UpdateBanner")
$updateBannerText = $window.FindName("UpdateBannerText")
$versionLabel     = $window.FindName("VersionLabel")
$versionBadge     = $window.FindName("VersionBadge")
$headerVrIcon     = $window.FindName("HeaderVrIcon")
$headerHubTitle   = $window.FindName("HeaderHubTitle")
$headerTagline    = $window.FindName("HeaderTagline")

# Apply the subtle white -> light-grey vertical gradient (matching the
# card tiles and detail-page title) to the header logo text and the
# three game banner titles. Done programmatically so the XAML stays
# lean and the look stays in sync across the app.
function global:Set-TitleGradient {
    param($Element)
    if (-not $Element) { return }
    try {
        $g = New-Object System.Windows.Media.LinearGradientBrush
        $g.StartPoint = [System.Windows.Point]::new(0, 0)
        $g.EndPoint   = [System.Windows.Point]::new(0, 1)
        $g.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(255,255,255), 0))) | Out-Null
        $g.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromRgb(216,222,227), 1))) | Out-Null
        $g.Freeze()
        $Element.Foreground = $g
    } catch { }
}
Set-TitleGradient $headerHubTitle
Set-TitleGradient ($window.FindName("ListBannerTitle"))
Set-TitleGradient ($window.FindName("LibBannerTitle"))
Set-TitleGradient ($window.FindName("OvBannerTitle"))

# -------------------------------------------------------
# Explore banner: subtle slow-scrolling starfield eye-catcher.
# Built entirely in code and fully wrapped so any failure leaves
# the banner untouched (never breaks the window). Stars are laid
# out over 2x the banner height and the layer scrolls up by exactly
# one banner height on a Forever loop, so the wrap is seamless.
# -------------------------------------------------------
function global:Add-BannerStarfield {
    param([string]$BannerName, [double]$BannerH, [string]$StarColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }

        # Span the field far wider than the default banner so it still
        # fills the whole width when the window is maximized (the banner
        # stretches; the Border clips the overflow). Density is kept
        # constant (~1 star per 26px), so it looks the same at any size.
        $fieldW = 2600.0
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.Opacity = 0.7
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch

        # Deterministic field (seeded) so it looks identical every launch.
        $rand  = New-Object System.Random 1337
        $brush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($StarColorHex))
        $brush.Freeze()
        $starCount = [int]($fieldW / 26.0)
        for ($k = 0; $k -lt $starCount; $k++) {
            $x  = $rand.NextDouble() * $fieldW
            $y  = $rand.NextDouble() * $BannerH
            $sz = 1.2 + ($rand.NextDouble() * 1.6)
            $op = 0.30 + ($rand.NextDouble() * 0.60)
            foreach ($copy in 0, 1) {
                $e = New-Object System.Windows.Shapes.Ellipse
                $e.Width  = $sz
                $e.Height = $sz
                $e.Fill   = $brush
                $e.Opacity = $op
                [System.Windows.Controls.Canvas]::SetLeft($e, $x)
                [System.Windows.Controls.Canvas]::SetTop($e, $y + ($copy * $BannerH))
                [void]$canvas.Children.Add($e)
            }
        }

        $tt = New-Object System.Windows.Media.TranslateTransform
        $canvas.RenderTransform = $tt
        $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
        $anim.From = 0.0
        $anim.To   = -$BannerH
        $anim.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(23.04))
        $anim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $anim)

        # Insert the field BELOW the header image (just above the solid
        # background), so the image itself overlays the stars on the right -
        # pixel-perfect, no masking guesswork - exactly the way the buttons
        # and title overlay them. The dark fade gradient sitting above still
        # blends the image's edge, and the stars read through it across the
        # open left/middle of the banner.
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}
function global:Add-BannerOrbs {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cols = @("#34d399","#3a8add","#f0d860","#5fff8f","#36e0e0")
        $rand = New-Object System.Random
        $nOrb = 4 + $rand.Next(0, 7)
        $orbInfo = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $nOrb; $i++) {
            # Cycle the palette so several colours are always present.
            $col = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$i % $cols.Count])
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new($col, 0.0)) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $col.R, $col.G, $col.B), 1.0)) | Out-Null
            $orb = New-Object System.Windows.Shapes.Ellipse
            $size = 95.0 + ($rand.NextDouble() * 80.0)
            $orb.Width = $size; $orb.Height = $size
            $orb.Fill = $rg
            $orb.Opacity = 0.4 + ($rand.NextDouble() * 0.2)
            $blur = New-Object System.Windows.Media.Effects.BlurEffect
            $blur.Radius = 22
            $orb.Effect = $blur
            $tt = New-Object System.Windows.Media.TranslateTransform
            $orb.RenderTransform = $tt
            $dur = 6.0 + ($rand.NextDouble() * 5.0)
            # Gentle drift (small amplitude so orbs stay in view, don't wander out).
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(14 + $rand.NextDouble() * 12); $ax.To = (14 + $rand.NextDouble() * 14)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = -(8 + $rand.NextDouble() * 8); $ay.To = (8 + $rand.NextDouble() * 10)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur * 0.8))
            $ay.AutoReverse = $true
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ay.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            [void]$canvas.Children.Add($orb)
            # Even horizontal slot (with a little jitter) + a centred vertical band,
            # stored as fractions so we can re-place on resize.
            $fx = ($i + 0.5) / $nOrb + (($rand.NextDouble() - 0.5) * 0.06)
            $fy = 0.18 + $rand.NextDouble() * 0.34
            [void]$orbInfo.Add([pscustomobject]@{ el = $orb; sz = $size; fx = $fx; fy = $fy })
        }
        # The stretched canvas's ActualWidth IS the visible width; spread the orbs
        # across it (and re-spread on resize) so the count/colours look consistent
        # instead of mostly landing off-screen.
        $reflow = {
            $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            $ch = $canvas.ActualHeight; if ($ch -lt 20) { $ch = $BannerH }
            foreach ($o in $orbInfo) {
                [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2))
                [System.Windows.Controls.Canvas]::SetTop($o.el, ($o.fy * $ch) - ($o.sz / 2))
            }
        }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow)
        & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSynthGrid {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $refW = 1000.0
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.Width = $refW; $canvas.Height = $BannerH
        $canvas.ClipToBounds = $true
        $horizon = $BannerH * 0.34
        $cx = $refW / 2.0
        $cyan = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString("#36e0e0")); $cyan.Opacity = 0.45; $cyan.Freeze()
        $mag  = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString("#c850ff")); $mag.Opacity = 0.40; $mag.Freeze()
        # Horizon glow (centered).
        $gcol = [System.Windows.Media.ColorConverter]::ConvertFromString("#ff5fbd")
        $glow = New-Object System.Windows.Shapes.Ellipse
        $glow.Width = $refW * 0.8; $glow.Height = $BannerH * 1.0
        $gg = New-Object System.Windows.Media.RadialGradientBrush
        $gg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(80, $gcol.R, $gcol.G, $gcol.B), 0.0)) | Out-Null
        $gg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $gcol.R, $gcol.G, $gcol.B), 1.0)) | Out-Null
        $glow.Fill = $gg
        [System.Windows.Controls.Canvas]::SetLeft($glow, $cx - ($refW * 0.4))
        [System.Windows.Controls.Canvas]::SetTop($glow, $horizon - ($BannerH * 0.5))
        [void]$canvas.Children.Add($glow)
        # Converging vertical lines fanning from the centered vanishing point
        # out to (and past) both edges.
        for ($vx = -1000; $vx -le 1000; $vx += 50) {
            $ln = New-Object System.Windows.Shapes.Line
            $ln.X1 = $cx; $ln.Y1 = $horizon
            $ln.X2 = $cx + $vx; $ln.Y2 = $BannerH
            $ln.Stroke = $mag; $ln.StrokeThickness = 1
            [void]$canvas.Children.Add($ln)
        }
        # Static bright horizon line.
        $hl = New-Object System.Windows.Shapes.Line
        $hl.X1 = 0; $hl.X2 = $refW; $hl.Y1 = $horizon; $hl.Y2 = $horizon
        $hl.Stroke = $cyan; $hl.StrokeThickness = 1.4
        [void]$canvas.Children.Add($hl)
        # Floor: evenly spaced horizontal lines, periodic scroll down (seamless
        # because the lines repeat exactly every $spacing).
        $span = $BannerH - $horizon
        $spacing = $span / 7.0
        $floor = New-Object System.Windows.Controls.Canvas
        for ($r = -1; $r -le 8; $r++) {
            $yy = $horizon + ($spacing * $r)
            $ln = New-Object System.Windows.Shapes.Line
            $ln.X1 = 0; $ln.X2 = $refW; $ln.Y1 = $yy; $ln.Y2 = $yy
            $ln.Stroke = $cyan; $ln.StrokeThickness = 1
            [void]$floor.Children.Add($ln)
        }
        $tt = New-Object System.Windows.Media.TranslateTransform
        $floor.RenderTransform = $tt
        $an = New-Object System.Windows.Media.Animation.DoubleAnimation
        $an.From = 0.0; $an.To = $spacing
        $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(1.6))
        $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $an)
        [void]$canvas.Children.Add($floor)
        # A Canvas does NOT scale its coordinate space to its size, so wrap the
        # fixed reference-width design in a Viewbox that stretches to fill the
        # whole banner at any window width (vanishing point stays centered).
        $vb = New-Object System.Windows.Controls.Viewbox
        $vb.Stretch = [System.Windows.Media.Stretch]::Fill
        $vb.IsHitTestVisible = $false
        $vb.Child = $canvas
        $vb.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $vb)
    } catch { }
}

function global:Add-BannerCircuit {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $h = $BannerH
        # Traces as Polylines (no path-string parsing, no fragile path animation
        # API -> robust + locale-safe). "Data" flows along them via an animated
        # StrokeDashOffset. Waypoints span the full width and height.
        $routes = @(
            @(-20, ($h*0.12), 400, ($h*0.12), 460, ($h*0.48), 1000, ($h*0.48), 1060, ($h*0.10), 1700, ($h*0.10), 1760, ($h*0.55), 2620, ($h*0.55)),
            @(-20, ($h*0.86), 260, ($h*0.86), 320, ($h*0.50), 760, ($h*0.50), 820, ($h*0.90), 1320, ($h*0.90), 1380, ($h*0.52), 1900, ($h*0.52), 1960, ($h*0.88), 2620, ($h*0.88)),
            @(-20, ($h*0.30), 600, ($h*0.30), 660, ($h*0.70), 1200, ($h*0.70), 1260, ($h*0.26), 1860, ($h*0.26), 1920, ($h*0.72), 2620, ($h*0.72))
        )
        $traceCols = @("#34d399","#36e0e0")
        $rand = New-Object System.Random
        $ci = 0
        foreach ($r in $routes) {
            $tb = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($traceCols[$ci % $traceCols.Count])); $tb.Opacity = 0.55
            $pl = New-Object System.Windows.Shapes.Polyline
            $pts = New-Object System.Windows.Media.PointCollection
            for ($i = 0; $i -lt $r.Count; $i += 2) {
                $pts.Add([System.Windows.Point]::new([double]$r[$i], [double]$r[$i + 1])) | Out-Null
            }
            $pl.Points = $pts
            $pl.Stroke = $tb
            $pl.StrokeThickness = 1.6
            $pl.Fill = $null
            $dash = New-Object System.Windows.Media.DoubleCollection
            $dash.Add(2.0); $dash.Add(7.0)
            $pl.StrokeDashArray = $dash
            $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $anim.From = 0; $anim.To = -18
            $anim.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(1.1 + $rand.NextDouble() * 0.9))
            $anim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $pl.BeginAnimation([System.Windows.Shapes.Shape]::StrokeDashOffsetProperty, $anim)
            [void]$canvas.Children.Add($pl)
            $ci++
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerNetwork {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $fieldW = 1600.0
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $n = 14; $maxD = 150.0
        $rand = New-Object System.Random
        $nodeBrush = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString("#5fff8f")); $nodeBrush.Freeze()
        $nodes = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $n; $i++) {
            $e = New-Object System.Windows.Shapes.Ellipse
            $e.Width = 3.4; $e.Height = 3.4; $e.Fill = $nodeBrush
            $node = [pscustomobject]@{ x = $rand.NextDouble() * $fieldW; y = $rand.NextDouble() * $BannerH; vx = ($rand.NextDouble() - 0.5) * 28; vy = ($rand.NextDouble() - 0.5) * 28; el = $e }
            [System.Windows.Controls.Canvas]::SetLeft($e, $node.x)
            [System.Windows.Controls.Canvas]::SetTop($e, $node.y)
            [void]$canvas.Children.Add($e)
            [void]$nodes.Add($node)
        }
        $lines = New-Object System.Collections.ArrayList
        for ($a = 0; $a -lt $n; $a++) {
            for ($b = $a + 1; $b -lt $n; $b++) {
                $ln = New-Object System.Windows.Shapes.Line
                $ln.StrokeThickness = 1
                $ln.Stroke = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(0, 52, 211, 153))
                [void]$canvas.Children.Insert(0, $ln)
                [void]$lines.Add([pscustomobject]@{ a = $a; b = $b; el = $ln })
            }
        }
        $state = [pscustomobject]@{ nodes = $nodes; lines = $lines; w = $fieldW; h = $BannerH; maxD = $maxD; last = [DateTime]::Now }
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(33)
        $timer.Add_Tick({
            try {
                $now = [DateTime]::Now; $dt = ($now - $state.last).TotalSeconds; if ($dt -gt 0.1) { $dt = 0.1 }; $state.last = $now
                foreach ($nd in $state.nodes) {
                    $nd.x += $nd.vx * $dt; $nd.y += $nd.vy * $dt
                    if ($nd.x -lt 0) { $nd.x = 0; $nd.vx = -$nd.vx } elseif ($nd.x -gt $state.w) { $nd.x = $state.w; $nd.vx = -$nd.vx }
                    if ($nd.y -lt 0) { $nd.y = 0; $nd.vy = -$nd.vy } elseif ($nd.y -gt $state.h) { $nd.y = $state.h; $nd.vy = -$nd.vy }
                    [System.Windows.Controls.Canvas]::SetLeft($nd.el, $nd.x)
                    [System.Windows.Controls.Canvas]::SetTop($nd.el, $nd.y)
                }
                foreach ($lp in $state.lines) {
                    $na = $state.nodes[$lp.a]; $nb = $state.nodes[$lp.b]
                    $dx = $na.x - $nb.x; $dy = $na.y - $nb.y; $dist = [Math]::Sqrt($dx * $dx + $dy * $dy)
                    if ($dist -lt $state.maxD) {
                        $lp.el.X1 = $na.x; $lp.el.Y1 = $na.y; $lp.el.X2 = $nb.x; $lp.el.Y2 = $nb.y
                        $al = [byte](150 * (1 - ($dist / $state.maxD)))
                        $lp.el.Stroke.Color = [System.Windows.Media.Color]::FromArgb($al, 52, 211, 153)
                    } else {
                        $lp.el.Stroke.Color = [System.Windows.Media.Color]::FromArgb(0, 52, 211, 153)
                    }
                }
            } catch { }
        }.GetNewClosure())
        $timer.Start()
        if (-not $global:BannerTimers) { $global:BannerTimers = New-Object System.Collections.ArrayList }
        [void]$global:BannerTimers.Add($timer)
        # Remember this banner's network timer by name. The network effect is
        # the only one driven by a polled DispatcherTimer; re-rolling a banner
        # to a different effect detaches its canvas but leaves that timer
        # ticking, so the timed rotation needs to stop it by name first.
        if (-not $global:BannerNetTimers) { $global:BannerNetTimers = @{} }
        $global:BannerNetTimers[$BannerName] = $timer
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerHex {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $fieldW = 2600.0
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $cols = @("#34d399","#36e0e0","#5fff8f")
        $outline = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromArgb(46, 52, 211, 153)); $outline.Freeze()
        $w = 30.0; $hgt = 26.0
        $cells = New-Object System.Collections.ArrayList
        # Row levels scale with the banner height so taller banners (M/L)
        # get more rows and fill top-to-bottom instead of leaving the
        # lower third empty. ~4 hexes per row level, spread across width.
        $rowLevels = [Math]::Max(3, [int][Math]::Round($BannerH / 48.0))
        $nHex = 4 * $rowLevels
        for ($i = 0; $i -lt $nHex; $i++) {
            $poly = New-Object System.Windows.Shapes.Polygon
            $pts = New-Object System.Windows.Media.PointCollection
            $pts.Add([System.Windows.Point]::new($w * 0.25, 0)) | Out-Null
            $pts.Add([System.Windows.Point]::new($w * 0.75, 0)) | Out-Null
            $pts.Add([System.Windows.Point]::new($w, $hgt * 0.5)) | Out-Null
            $pts.Add([System.Windows.Point]::new($w * 0.75, $hgt)) | Out-Null
            $pts.Add([System.Windows.Point]::new($w * 0.25, $hgt)) | Out-Null
            $pts.Add([System.Windows.Point]::new(0, $hgt * 0.5)) | Out-Null
            $poly.Points = $pts
            $poly.Stroke = $outline; $poly.StrokeThickness = 1
            $cc = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$rand.Next($cols.Count)])
            $fillB = [System.Windows.Media.SolidColorBrush]::new($cc); $fillB.Opacity = 0
            $poly.Fill = $fillB
            [System.Windows.Controls.Canvas]::SetTop($poly, 6 + ($i % $rowLevels) * (($BannerH - 38) / [Math]::Max(1, $rowLevels - 1)))
            $pa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $pa.From = 0; $pa.To = 0.5
            $pa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(2.6 + $rand.NextDouble() * 2.5))
            $pa.AutoReverse = $true
            $pa.BeginTime = [TimeSpan]::FromSeconds($rand.NextDouble() * 4.0)
            $pa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $fillB.BeginAnimation([System.Windows.Media.SolidColorBrush]::OpacityProperty, $pa)
            [void]$canvas.Children.Add($poly)
            [void]$cells.Add($poly)
        }
        # The canvas stretches to the banner, so its ActualWidth IS the visible
        # width. Spread the cells evenly across it (and re-spread on resize) so
        # they always fill the banner instead of scattering off-screen.
        $reflow = {
            $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            for ($j = 0; $j -lt $cells.Count; $j++) {
                $fx = (($j + 0.5) / $cells.Count) * ($cw - 30)
                [System.Windows.Controls.Canvas]::SetLeft($cells[$j], $fx)
            }
        }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow)
        & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerEmbers {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $fieldW = 2600.0
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $count = [int]($fieldW / 55.0)
        for ($i = 0; $i -lt $count; $i++) {
            $em = New-Object System.Windows.Shapes.Ellipse
            $sz = 1.4 + $rand.NextDouble() * 2.2
            $em.Width = $sz; $em.Height = $sz
            $ec = [System.Windows.Media.Color]::FromArgb(255, 255, [byte](180 + $rand.Next(40)), [byte](90 + $rand.Next(60)))
            $em.Fill = [System.Windows.Media.SolidColorBrush]::new($ec)
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 2.0
            $em.Effect = $bl
            [System.Windows.Controls.Canvas]::SetLeft($em, $rand.NextDouble() * $fieldW)
            [System.Windows.Controls.Canvas]::SetTop($em, 0)
            $tt = New-Object System.Windows.Media.TranslateTransform
            $em.RenderTransform = $tt
            $dur = 5.0 + $rand.NextDouble() * 5.0
            $ya = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ya.From = $BannerH + 8; $ya.To = -8
            $ya.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            # Negative begin time: at t=0 each ember is already partway up its
            # rise (phase-distributed across the height) instead of resting at
            # translateY=0 (which sat them all at the top until their turn).
            $ya.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $ya.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ya)
            $xa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $xa.From = -(4 + $rand.NextDouble() * 6); $xa.To = (4 + $rand.NextDouble() * 8)
            $xa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(1.5 + $rand.NextDouble() * 2.0))
            $xa.AutoReverse = $true
            $xa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $xa.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $xa)
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $oa.From = 0.2; $oa.To = 0.95
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(0.8 + $rand.NextDouble() * 1.2))
            $oa.AutoReverse = $true
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $em.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            [void]$canvas.Children.Add($em)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

# Parallax starfield: multiple depth layers drifting LEFT at different speeds
# and star sizes for a sense of depth. Each layer tiles its pattern across
# 2*period and translates by -period, so the loop is seamless.
function global:Add-BannerParallax {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName)
        if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child
        if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $col = [System.Windows.Media.ColorConverter]::ConvertFromString($ColorHex)
        $period = 1400.0
        $rand = New-Object System.Random
        $layers = @(
            @{ n = 70; sz = 0.9; op = 0.45; dur = 60.0 },
            @{ n = 55; sz = 1.4; op = 0.70; dur = 38.0 },
            @{ n = 36; sz = 2.1; op = 1.00; dur = 24.0 }
        )
        foreach ($L in $layers) {
            $layer = New-Object System.Windows.Controls.Canvas
            for ($i = 0; $i -lt $L.n; $i++) {
                $x = $rand.NextDouble() * $period
                $y = $rand.NextDouble() * $BannerH
                $o = $L.op * (0.5 + $rand.NextDouble() * 0.5)
                foreach ($copy in 0, 1) {
                    $st = New-Object System.Windows.Shapes.Ellipse
                    $st.Width = $L.sz; $st.Height = $L.sz
                    $st.Fill = [System.Windows.Media.SolidColorBrush]::new($col)
                    $st.Opacity = $o
                    [System.Windows.Controls.Canvas]::SetLeft($st, $x + ($copy * $period))
                    [System.Windows.Controls.Canvas]::SetTop($st, $y)
                    [void]$layer.Children.Add($st)
                }
            }
            $tt = New-Object System.Windows.Media.TranslateTransform
            $layer.RenderTransform = $tt
            $an = New-Object System.Windows.Media.Animation.DoubleAnimation
            $an.From = 0.0; $an.To = -$period
            $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($L.dur))
            $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
            [void]$canvas.Children.Add($layer)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count)
        $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerNebula {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cols = @("#c850ff","#3a8add","#36e0e0")
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 3; $i++) {
            $col = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$i])
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new($col, 0.0)) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $col.R, $col.G, $col.B), 1.0)) | Out-Null
            $blob = New-Object System.Windows.Shapes.Ellipse
            $sz = $BannerH * 2.4
            $blob.Width = $sz; $blob.Height = $sz; $blob.Fill = $rg; $blob.Opacity = 0.5
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 40; $blob.Effect = $bl
            $tt = New-Object System.Windows.Media.TranslateTransform
            $blob.RenderTransform = $tt
            $dur = 18.0 + $rand.NextDouble() * 10.0
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(40 + $rand.NextDouble() * 40); $ax.To = (40 + $rand.NextDouble() * 50)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = -(20 + $rand.NextDouble() * 20); $ay.To = (20 + $rand.NextDouble() * 24)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur * 0.9)); $ay.AutoReverse = $true
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ay.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            [System.Windows.Controls.Canvas]::SetTop($blob, ($BannerH / 2) - ($sz / 2))
            [void]$canvas.Children.Add($blob)
            [void]$info.Add([pscustomobject]@{ el = $blob; sz = $sz; fx = (($i + 0.5) / 3.0) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerMeteors {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        for ($i = 0; $i -lt 7; $i++) {
            $rect = New-Object System.Windows.Shapes.Rectangle
            $rect.Width = 150; $rect.Height = 2; $rect.RadiusX = 1; $rect.RadiusY = 1
            $lg = New-Object System.Windows.Media.LinearGradientBrush
            $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(1, 0)
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 200, 235, 255), 0.0)) | Out-Null
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 255, 255, 255), 1.0)) | Out-Null
            $rect.Fill = $lg
            $gl = New-Object System.Windows.Media.Effects.DropShadowEffect; $gl.Color = [System.Windows.Media.Color]::FromRgb(143, 208, 255); $gl.BlurRadius = 6; $gl.ShadowDepth = 0; $gl.Opacity = 0.9; $rect.Effect = $gl
            $rect.CacheMode = New-Object System.Windows.Media.BitmapCache
            # Descend across the WHOLE banner width: scale the drop to the
            # banner height (instead of a fixed ~515px that dove out the bottom
            # in the first third and left the meteors stuck bottom-left). The
            # tail tilt is derived from the same vector so it stays aligned.
            $xRange = 2920.0
            $yDelta = [Math]::Max(50.0, $BannerH * 1.2)
            $angleDeg = [Math]::Atan2($yDelta, $xRange) * 180.0 / [Math]::PI
            $tg = New-Object System.Windows.Media.TransformGroup
            $tg.Children.Add([System.Windows.Media.RotateTransform]::new($angleDeg)) | Out-Null
            $tt = New-Object System.Windows.Media.TranslateTransform
            $tg.Children.Add($tt) | Out-Null
            $rect.RenderTransform = $tg
            [System.Windows.Controls.Canvas]::SetTop($rect, -($BannerH * 0.15) + $rand.NextDouble() * ([Math]::Max(40.0, $BannerH * 0.55)))
            [System.Windows.Controls.Canvas]::SetLeft($rect, 0)
            $dur = 10.8 + $rand.NextDouble() * 7.2
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -320; $ax.To = 2600
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = 0; $ay.To = $yDelta
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ay.BeginTime = $ax.BeginTime
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            [void]$canvas.Children.Add($rect)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSonar {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $origins = @(@{ fx = 0.26; fy = 0.6; col = "#34d399" }, @{ fx = 0.72; fy = 0.42; col = "#36e0e0" })
        $info = New-Object System.Collections.ArrayList
        foreach ($o in $origins) {
            $col = [System.Windows.Media.ColorConverter]::ConvertFromString($o.col)
            for ($k = 0; $k -lt 3; $k++) {
                $ring = New-Object System.Windows.Shapes.Ellipse
                $ring.Width = 24; $ring.Height = 24
                $ring.Stroke = [System.Windows.Media.SolidColorBrush]::new($col); $ring.StrokeThickness = 1.5; $ring.Fill = $null
                $ring.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
                $st = [System.Windows.Media.ScaleTransform]::new(0.2, 0.2)
                $ring.RenderTransform = $st
                $period = 7.0; $bt = [TimeSpan]::FromSeconds($k * ($period / 3.0))
                $sa = New-Object System.Windows.Media.Animation.DoubleAnimation
                $sa.From = 0.2; $sa.To = 11
                $sa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($period)); $sa.BeginTime = $bt
                $sa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $sa)
                $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $sa)
                $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
                $oa.From = 0.7; $oa.To = 0.0
                $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($period)); $oa.BeginTime = $bt
                $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                $ring.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
                [System.Windows.Controls.Canvas]::SetTop($ring, ($o.fy * $BannerH) - 12)
                [void]$canvas.Children.Add($ring)
                [void]$info.Add([pscustomobject]@{ el = $ring; fx = $o.fx })
            }
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($r in $info) { [System.Windows.Controls.Canvas]::SetLeft($r.el, ($r.fx * $cw) - 12) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerMotes {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $moteBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(190, 215, 230)); $moteBrush.Freeze()
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 42; $i++) {
            $d = New-Object System.Windows.Shapes.Ellipse
            $s = 0.8 + $rand.NextDouble() * 1.6
            $d.Width = $s; $d.Height = $s; $d.Fill = $moteBrush
            $tt = New-Object System.Windows.Media.TranslateTransform
            $d.RenderTransform = $tt
            $dx = 6 + $rand.NextDouble() * 8; $dy = 6 + $rand.NextDouble() * 8
            $durx = 5.0 + $rand.NextDouble() * 6.0; $dury = 5.0 + $rand.NextDouble() * 6.0
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -$dx; $ax.To = $dx
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($durx)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $durx))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = -$dy; $ay.To = $dy
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dury)); $ay.AutoReverse = $true
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ay.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dury))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $oa.From = 0.15; $oa.To = 0.6
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(1.5 + $rand.NextDouble() * 2.5)); $oa.AutoReverse = $true
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $oa.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * 3.0))
            $d.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            [System.Windows.Controls.Canvas]::SetTop($d, $rand.NextDouble() * $BannerH)
            [void]$canvas.Children.Add($d)
            [void]$info.Add([pscustomobject]@{ el = $d; fx = $rand.NextDouble() })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($m in $info) { [System.Windows.Controls.Canvas]::SetLeft($m.el, $m.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerEqualizer {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $n = 28
        $base = [System.Windows.Media.ColorConverter]::ConvertFromString($ColorHex)
        $baseDark = [System.Windows.Media.Color]::FromRgb([byte]($base.R * 0.55), [byte]($base.G * 0.55), [byte]($base.B * 0.55))
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $n; $i++) {
            $barCol  = $base
            $barDark = $baseDark
            $bar = New-Object System.Windows.Shapes.Rectangle
            $bar.RadiusX = 2; $bar.RadiusY = 2; $bar.Height = $BannerH; $bar.Opacity = 0.1
            $lg = New-Object System.Windows.Media.LinearGradientBrush
            $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(0, 1)
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($barCol, 0.0)) | Out-Null
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($barDark, 1.0)) | Out-Null
            $bar.Fill = $lg
            $bar.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 1.0)
            $stf = [System.Windows.Media.ScaleTransform]::new(1, 0.3)
            $bar.RenderTransform = $stf
            [System.Windows.Controls.Canvas]::SetTop($bar, 0)
            $dur = 3.4 + $rand.NextDouble() * 3.0
            $sa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $sa.From = 0.15 + $rand.NextDouble() * 0.25; $sa.To = 0.7 + $rand.NextDouble() * 0.3
            $sa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur)); $sa.AutoReverse = $true
            $sa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $sa.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $sa.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $stf.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $sa)
            [void]$canvas.Children.Add($bar)
            [void]$info.Add([pscustomobject]@{ el = $bar })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            $ch = $canvas.ActualHeight
            $bw = $cw / $info.Count
            for ($j = 0; $j -lt $info.Count; $j++) { $info[$j].el.Width = $bw * 0.7; $info[$j].el.Height = $ch; [System.Windows.Controls.Canvas]::SetLeft($info[$j].el, ($j * $bw) + ($bw * 0.15)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSpeed {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cyan = [System.Windows.Media.ColorConverter]::ConvertFromString("#36e0e0")
        $rand = New-Object System.Random
        for ($i = 0; $i -lt 7; $i++) {
            $rect = New-Object System.Windows.Shapes.Rectangle
            $rect.Height = 1.5; $rect.Width = 90 + $rand.NextDouble() * 130; $rect.RadiusX = 1; $rect.RadiusY = 1
            $lg = New-Object System.Windows.Media.LinearGradientBrush
            $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(1, 0)
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $cyan.R, $cyan.G, $cyan.B), 0.0)) | Out-Null
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(230, $cyan.R, $cyan.G, $cyan.B), 1.0)) | Out-Null
            $rect.Fill = $lg
            $tt = New-Object System.Windows.Media.TranslateTransform
            $rect.RenderTransform = $tt
            [System.Windows.Controls.Canvas]::SetTop($rect, (0.08 + $rand.NextDouble() * 0.84) * $BannerH)
            [System.Windows.Controls.Canvas]::SetLeft($rect, 0)
            $dur = 6.0 + $rand.NextDouble() * 6.0
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -260; $ax.To = 2600
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            [void]$canvas.Children.Add($rect)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerFlow {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rect = New-Object System.Windows.Shapes.Rectangle
        $rect.Height = $BannerH
        $lg = New-Object System.Windows.Media.LinearGradientBrush
        $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(1, 0)
        $lg.SpreadMethod = [System.Windows.Media.GradientSpreadMethod]::Repeat
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.ColorConverter]::ConvertFromString("#16d0a0"), 0.0)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.ColorConverter]::ConvertFromString("#2ab0ff"), 0.34)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.ColorConverter]::ConvertFromString("#9a5cff"), 0.67)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.ColorConverter]::ConvertFromString("#16d0a0"), 1.0)) | Out-Null
        $rt = New-Object System.Windows.Media.TranslateTransform
        $lg.RelativeTransform = $rt
        $rect.Fill = $lg
        # Semi-transparent wash so it layers as a moving colour flow OVER the
        # banner (art + scrim) instead of a dark band hidden underneath.
        $rect.Opacity = 0.40
        # Fade the wash out toward the RIGHT so it stays on the left+middle
        # (title area) and never covers the right-aligned game art. Full to
        # ~0.42, gone by ~0.60 - safely clear of the art on any banner width.
        $mask = New-Object System.Windows.Media.LinearGradientBrush
        $mask.StartPoint = [System.Windows.Point]::new(0, 0); $mask.EndPoint = [System.Windows.Point]::new(1, 0)
        $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 255, 255, 255), 0.0)) | Out-Null
        $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 255, 255, 255), 0.42)) | Out-Null
        $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 255, 255, 255), 0.60)) | Out-Null
        $rect.OpacityMask = $mask
        $an = New-Object System.Windows.Media.Animation.DoubleAnimation
        $an.From = 0.0; $an.To = 1.0
        $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(18.0))
        $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $rt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
        [System.Windows.Controls.Canvas]::SetTop($rect, 0); [System.Windows.Controls.Canvas]::SetLeft($rect, 0)
        [void]$canvas.Children.Add($rect)
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }; $rect.Width = $cw; $rect.Height = $canvas.ActualHeight }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        # Flow is a translucent wash: add it ON TOP (above art + scrim) so the
        # moving colour is actually visible, unlike the particle effects which
        # sit under the art. Canvas IsHitTestVisible=false keeps clicks working.
        [void]$grid.Children.Add($canvas)
    } catch { }
}

function global:Add-BannerPlasma {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $palette = @("#34d399","#36e0e0","#3a8add","#c850ff")
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 3; $i++) {
            $start = [System.Windows.Media.ColorConverter]::ConvertFromString($palette[$i % $palette.Count])
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $stop0 = [System.Windows.Media.GradientStop]::new($start, 0.0)
            $rg.GradientStops.Add($stop0) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 0, 0, 0), 1.0)) | Out-Null
            $blob = New-Object System.Windows.Shapes.Ellipse
            $sz = $BannerH * 1.9
            $blob.Width = $sz; $blob.Height = $sz; $blob.Fill = $rg; $blob.Opacity = 0.6
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 36; $blob.Effect = $bl
            $tt = New-Object System.Windows.Media.TranslateTransform
            $blob.RenderTransform = $tt
            $dur = 12.0 + $rand.NextDouble() * 6.0
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(40 + $rand.NextDouble() * 40); $ax.To = (40 + $rand.NextDouble() * 50)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ca = New-Object System.Windows.Media.Animation.ColorAnimationUsingKeyFrames
            $hueDur = 14.0 + $rand.NextDouble() * 6.0
            $ca.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($hueDur))
            for ($k = 0; $k -lt $palette.Count; $k++) {
                $c = [System.Windows.Media.ColorConverter]::ConvertFromString($palette[($i + $k) % $palette.Count])
                $kt = [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($hueDur * ($k / [double]$palette.Count)))
                $ca.KeyFrames.Add([System.Windows.Media.Animation.LinearColorKeyFrame]::new($c, $kt)) | Out-Null
            }
            $endkt = [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($hueDur))
            $ca.KeyFrames.Add([System.Windows.Media.Animation.LinearColorKeyFrame]::new($start, $endkt)) | Out-Null
            $ca.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $stop0.BeginAnimation([System.Windows.Media.GradientStop]::ColorProperty, $ca)
            [System.Windows.Controls.Canvas]::SetTop($blob, ($BannerH / 2) - ($sz / 2))
            [void]$canvas.Children.Add($blob)
            [void]$info.Add([pscustomobject]@{ el = $blob; sz = $sz; fx = (($i + 0.5) / 3.0) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerBlobs {
    param([string]$BannerName, [double]$BannerH, [string[]]$Palette)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $palette = $Palette
        if (-not $palette -or $palette.Count -lt 2) { $palette = @("#34d399","#36e0e0","#3a8add","#c850ff") }
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 3; $i++) {
            $start = [System.Windows.Media.ColorConverter]::ConvertFromString($palette[$i % $palette.Count])
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $stop0 = [System.Windows.Media.GradientStop]::new($start, 0.0)
            $rg.GradientStops.Add($stop0) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 0, 0, 0), 1.0)) | Out-Null
            $blob = New-Object System.Windows.Shapes.Ellipse
            $sz = $BannerH * 1.9
            $blob.Width = $sz; $blob.Height = $sz; $blob.Fill = $rg; $blob.Opacity = 0.6
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 36; $blob.Effect = $bl
            $tt = New-Object System.Windows.Media.TranslateTransform
            $blob.RenderTransform = $tt
            $dur = 12.0 + $rand.NextDouble() * 6.0
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(40 + $rand.NextDouble() * 40); $ax.To = (40 + $rand.NextDouble() * 50)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ca = New-Object System.Windows.Media.Animation.ColorAnimationUsingKeyFrames
            $hueDur = 14.0 + $rand.NextDouble() * 6.0
            $ca.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($hueDur))
            for ($k = 0; $k -lt $palette.Count; $k++) {
                $c = [System.Windows.Media.ColorConverter]::ConvertFromString($palette[($i + $k) % $palette.Count])
                $kt = [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($hueDur * ($k / [double]$palette.Count)))
                $ca.KeyFrames.Add([System.Windows.Media.Animation.LinearColorKeyFrame]::new($c, $kt)) | Out-Null
            }
            $endkt = [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($hueDur))
            $ca.KeyFrames.Add([System.Windows.Media.Animation.LinearColorKeyFrame]::new($start, $endkt)) | Out-Null
            $ca.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $stop0.BeginAnimation([System.Windows.Media.GradientStop]::ColorProperty, $ca)
            [System.Windows.Controls.Canvas]::SetTop($blob, ($BannerH / 2) - ($sz / 2))
            [void]$canvas.Children.Add($blob)
            [void]$info.Add([pscustomobject]@{ el = $blob; sz = $sz; fx = (($i + 0.5) / 3.0) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerStripes {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rect = New-Object System.Windows.Shapes.Rectangle
        $rect.Height = $BannerH
        $cFaint = [System.Windows.Media.Color]::FromArgb(20, 52, 211, 153)
        $cClear = [System.Windows.Media.Color]::FromArgb(0, 52, 211, 153)
        $lg = New-Object System.Windows.Media.LinearGradientBrush
        $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(0.08, 0.08)
        $lg.SpreadMethod = [System.Windows.Media.GradientSpreadMethod]::Repeat
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($cFaint, 0.0)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($cFaint, 0.49)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($cClear, 0.5)) | Out-Null
        $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new($cClear, 1.0)) | Out-Null
        $rt = New-Object System.Windows.Media.TranslateTransform
        $lg.RelativeTransform = $rt
        $rect.Fill = $lg
        $anx = New-Object System.Windows.Media.Animation.DoubleAnimation
        $anx.From = 0.0; $anx.To = 0.08
        $anx.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(6.0))
        $anx.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $rt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $anx)
        $any = New-Object System.Windows.Media.Animation.DoubleAnimation
        $any.From = 0.0; $any.To = 0.08
        $any.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(6.0))
        $any.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $rt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $any)
        [System.Windows.Controls.Canvas]::SetTop($rect, 0); [System.Windows.Controls.Canvas]::SetLeft($rect, 0)
        [void]$canvas.Children.Add($rect)
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }; $rect.Width = $cw; $rect.Height = $canvas.ActualHeight }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerTwinkle {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $dotBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(80, 230, 200)); $dotBrush.Freeze()
        $gap = 40.0; $fieldW = 2000.0
        $cols = [int]($fieldW / $gap)
        $rows = [int]($BannerH / $gap) + 1
        for ($r = 0; $r -lt $rows; $r++) {
            for ($c = 0; $c -lt $cols; $c++) {
                $d = New-Object System.Windows.Shapes.Ellipse
                $d.Width = 3.2; $d.Height = 3.2; $d.Fill = $dotBrush; $d.Opacity = 0
                [System.Windows.Controls.Canvas]::SetLeft($d, $c * $gap + ($gap / 2))
                [System.Windows.Controls.Canvas]::SetTop($d, $r * $gap + ($gap / 2))
                $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
                $oa.From = 0; $oa.To = 0.7
                $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(2.2)); $oa.AutoReverse = $true
                $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                $oa.BeginTime = [TimeSpan]::FromSeconds((($c + $r) % 12) * 0.18)
                $d.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
                [void]$canvas.Children.Add($d)
            }
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerRain {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $col = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(150, 195, 225)); $col.Freeze()
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 70; $i++) {
            $len = 8 + $rand.NextDouble() * 12
            $drop = New-Object System.Windows.Shapes.Rectangle
            $drop.Width = 1; $drop.Height = $len; $drop.RadiusX = 0.5; $drop.RadiusY = 0.5
            $drop.Fill = $col; $drop.Opacity = 0.1 + $rand.NextDouble() * 0.25
            $tt = New-Object System.Windows.Media.TranslateTransform
            $drop.RenderTransform = $tt
            [System.Windows.Controls.Canvas]::SetTop($drop, -$len)
            $dur = (1.4 + $rand.NextDouble() * 1.2)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = 0; $ay.To = ($BannerH + $len + 4)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            [void]$canvas.Children.Add($drop)
            [void]$info.Add([pscustomobject]@{ el = $drop; fx = $rand.NextDouble() })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($d in $info) { [System.Windows.Controls.Canvas]::SetLeft($d.el, $d.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerBokeh {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex, [string[]]$Palette)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cols = if ($Palette -and $Palette.Count -ge 2) { $Palette } else { @("#36e0e0","#3a8add","#c850ff","#34d399") }
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 10; $i++) {
            $c = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$i % $cols.Count])
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new($c, 0.0)) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $c.R, $c.G, $c.B), 1.0)) | Out-Null
            $sz = 34 + $rand.NextDouble() * 60
            $e = New-Object System.Windows.Shapes.Ellipse
            $e.Width = $sz; $e.Height = $sz; $e.Fill = $rg; $e.Opacity = 0.5
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 6 + $rand.NextDouble() * 14; $e.Effect = $bl
            $tt = New-Object System.Windows.Media.TranslateTransform
            $e.RenderTransform = $tt
            $durx = 9 + $rand.NextDouble() * 10
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(10 + $rand.NextDouble() * 14); $ax.To = (10 + $rand.NextDouble() * 14)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($durx)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $durx))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = -(6 + $rand.NextDouble() * 10); $ay.To = (6 + $rand.NextDouble() * 10)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($durx * 0.85)); $ay.AutoReverse = $true
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ay.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $durx))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $oa.From = 0.25; $oa.To = 0.65
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(5 + $rand.NextDouble() * 5)); $oa.AutoReverse = $true
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $oa.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * 5))
            $e.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            [System.Windows.Controls.Canvas]::SetTop($e, ((0.18 + $rand.NextDouble() * 0.64) * $BannerH) - ($sz / 2))
            [void]$canvas.Children.Add($e)
            [void]$info.Add([pscustomobject]@{ el = $e; sz = $sz; fx = (0.06 + $rand.NextDouble() * 0.88) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerShards {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cols = @("#36e0e0","#c850ff","#34d399","#3a8add")
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 40; $i++) {
            $s = 3 + $rand.NextDouble() * 4
            $poly = New-Object System.Windows.Shapes.Polygon
            $pts = New-Object System.Windows.Media.PointCollection
            $pts.Add([System.Windows.Point]::new(0, -$s)) | Out-Null
            $pts.Add([System.Windows.Point]::new($s, $s)) | Out-Null
            $pts.Add([System.Windows.Point]::new(-$s, $s)) | Out-Null
            $poly.Points = $pts
            $cc = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$i % $cols.Count])
            $poly.Fill = [System.Windows.Media.SolidColorBrush]::new($cc); $poly.Opacity = 0.2 + $rand.NextDouble() * 0.4
            $poly.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
            $tg = New-Object System.Windows.Media.TransformGroup
            $rot = [System.Windows.Media.RotateTransform]::new(0)
            $tt = New-Object System.Windows.Media.TranslateTransform
            $tg.Children.Add($rot) | Out-Null; $tg.Children.Add($tt) | Out-Null
            $poly.RenderTransform = $tg
            $rdur = 8 + $rand.NextDouble() * 10
            $ra = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ra.From = 0; $ra.To = 360
            $ra.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($rdur))
            $ra.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ra.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $rdur))
            $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $ra)
            $ddur = 6 + $rand.NextDouble() * 5
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -6; $ax.To = 6
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($ddur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $ddur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = -6; $ay.To = 6
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($ddur * 1.1)); $ay.AutoReverse = $true
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ay.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $ddur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            [System.Windows.Controls.Canvas]::SetTop($poly, $rand.NextDouble() * $BannerH)
            [void]$canvas.Children.Add($poly)
            [void]$info.Add([pscustomobject]@{ el = $poly; fx = $rand.NextDouble() })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, $o.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerWaves {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $lines = @(
            @{ r = 54; g = 224; b = 224; amp = 10; off = 0.50; wl = 240.0; dur = 9.0;  dir = -1 },
            @{ r = 52; g = 211; b = 153; amp = 7;  off = 0.62; wl = 180.0; dur = 7.0;  dir = 1 },
            @{ r = 58; g = 138; b = 221; amp = 13; off = 0.42; wl = 300.0; dur = 12.0; dir = -1 }
        )
        foreach ($L in $lines) {
            $poly = New-Object System.Windows.Shapes.Polyline
            $poly.Stroke = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(130, [byte]$L.r, [byte]$L.g, [byte]$L.b))
            $poly.StrokeThickness = 1.5
            $pts = New-Object System.Windows.Media.PointCollection
            $baseY = $L.off * $BannerH
            for ($x = 0; $x -le 2600; $x += 8) {
                $y = $baseY + $L.amp * [Math]::Sin(2 * [Math]::PI * $x / $L.wl)
                $pts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            $poly.Points = $pts
            $tt = New-Object System.Windows.Media.TranslateTransform
            $poly.RenderTransform = $tt
            $an = New-Object System.Windows.Media.Animation.DoubleAnimation
            $an.From = 0; $an.To = ($L.dir * $L.wl)
            $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($L.dur))
            $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
            [void]$canvas.Children.Add($poly)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerRays {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cols = @("#36e0e0","#34d399","#3a8add")
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 5; $i++) {
            $c = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$i % $cols.Count])
            $w = 40 + $rand.NextDouble() * 70
            $rect = New-Object System.Windows.Shapes.Rectangle
            $rect.Width = $w; $rect.Height = ($BannerH * 1.8)
            $lg = New-Object System.Windows.Media.LinearGradientBrush
            $lg.StartPoint = [System.Windows.Point]::new(0, 0); $lg.EndPoint = [System.Windows.Point]::new(1, 0)
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $c.R, $c.G, $c.B), 0.0)) | Out-Null
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(85, $c.R, $c.G, $c.B), 0.5)) | Out-Null
            $lg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $c.R, $c.G, $c.B), 1.0)) | Out-Null
            $rect.Fill = $lg
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 6; $rect.Effect = $bl
            $tg = New-Object System.Windows.Media.TransformGroup
            $tg.Children.Add([System.Windows.Media.RotateTransform]::new(16)) | Out-Null
            $tt = New-Object System.Windows.Media.TranslateTransform
            $tg.Children.Add($tt) | Out-Null
            $rect.RenderTransform = $tg
            [System.Windows.Controls.Canvas]::SetTop($rect, -($BannerH * 0.4))
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $oa.From = 0.25; $oa.To = 0.7
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(8 + $rand.NextDouble() * 6)); $oa.AutoReverse = $true
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $oa.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * 8))
            $rect.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            $dxdur = 9 + $rand.NextDouble() * 5
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -10; $ax.To = 10
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dxdur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dxdur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            [void]$canvas.Children.Add($rect)
            [void]$info.Add([pscustomobject]@{ el = $rect; w = $w; fx = (($i + 0.5) / 5.0) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.w / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerLava {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $cols = @("#dd6600","#ff7a3c","#ffb152")
        $rand = New-Object System.Random
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 3; $i++) {
            $c = [System.Windows.Media.ColorConverter]::ConvertFromString($cols[$i % $cols.Count])
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new($c, 0.0)) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $c.R, $c.G, $c.B), 1.0)) | Out-Null
            $sz = $BannerH * 0.95
            $e = New-Object System.Windows.Shapes.Ellipse
            $e.Width = $sz; $e.Height = $sz; $e.Fill = $rg; $e.Opacity = 0.6
            $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 14; $e.Effect = $bl
            $e.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
            $tg = New-Object System.Windows.Media.TransformGroup
            $sct = [System.Windows.Media.ScaleTransform]::new(1, 1)
            $tt = New-Object System.Windows.Media.TranslateTransform
            $tg.Children.Add($sct) | Out-Null; $tg.Children.Add($tt) | Out-Null
            $e.RenderTransform = $tg
            $sxd = 11 + $rand.NextDouble() * 5
            $sx = New-Object System.Windows.Media.Animation.DoubleAnimation
            $sx.From = 0.85; $sx.To = 1.15
            $sx.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($sxd)); $sx.AutoReverse = $true
            $sx.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $sx.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $sx.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $sxd))
            $sct.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $sx)
            $syd = 13 + $rand.NextDouble() * 5
            $sy = New-Object System.Windows.Media.Animation.DoubleAnimation
            $sy.From = 1.12; $sy.To = 0.88
            $sy.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($syd)); $sy.AutoReverse = $true
            $sy.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $sy.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $sy.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $syd))
            $sct.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $sy)
            $tyd = 14 + $rand.NextDouble() * 6
            $ty = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ty.From = -($BannerH * 0.12); $ty.To = ($BannerH * 0.12)
            $ty.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($tyd)); $ty.AutoReverse = $true
            $ty.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ty.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ty.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $tyd))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ty)
            [System.Windows.Controls.Canvas]::SetTop($e, ($BannerH / 2) - ($sz / 2))
            [void]$canvas.Children.Add($e)
            [void]$info.Add([pscustomobject]@{ el = $e; sz = $sz; fx = (($i + 0.5) / 3.0) })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($o.sz / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerTopo {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $ribbons = @(
            @{ r = 125; g = 211; b = 252; off = 0.42; amp = 14; w = 26; wl = 300.0; dur = 10.0; dir = -1 },
            @{ r = 59;  g = 130; b = 246; off = 0.55; amp = 18; w = 30; wl = 380.0; dur = 13.0; dir = 1 },
            @{ r = 94;  g = 234; b = 212; off = 0.66; amp = 11; w = 22; wl = 240.0; dur = 8.0;  dir = -1 }
        )
        foreach ($rb in $ribbons) {
            $baseY = $rb.off * $BannerH
            # Extend each ribbon well PAST both banner edges instead of
            # starting at x=0. A ribbon that drifts right (dir = +1) used to
            # move its left edge inward, uncovering a blank gap on the left
            # that grew until the loop wrapped - looking like the band got
            # shorter and then snapped back. The wave is periodic in wl and the
            # translate is exactly one wl, so with this overhang on both sides
            # the scroll stays seamless: full width at all times, no visible
            # jump.
            $x0 = -500; $x1 = 3200
            $fig = New-Object System.Windows.Media.PathFigure
            $fig.StartPoint = [System.Windows.Point]::new($x0, $baseY)
            $polyPts = New-Object System.Windows.Media.PointCollection
            for ($x = $x0; $x -le $x1; $x += 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl)
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            for ($x = $x1; $x -ge $x0; $x -= 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl) + $rb.w
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            $polySeg = New-Object System.Windows.Media.PolyLineSegment
            $polySeg.Points = $polyPts
            $fig.Segments.Add($polySeg) | Out-Null; $fig.IsClosed = $true
            $geo = New-Object System.Windows.Media.PathGeometry
            $geo.Figures.Add($fig) | Out-Null
            $path = New-Object System.Windows.Shapes.Path
            $path.Data = $geo
            $path.Fill = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(70, [byte]$rb.r, [byte]$rb.g, [byte]$rb.b))
            $tt = New-Object System.Windows.Media.TranslateTransform
            $path.RenderTransform = $tt
            $an = New-Object System.Windows.Media.Animation.DoubleAnimation
            $an.From = 0; $an.To = ($rb.dir * $rb.wl)
            $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($rb.dur))
            $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
            [void]$canvas.Children.Add($path)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerVortex {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $dotBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(120, 210, 255)); $dotBrush.Freeze()
        $n = 90; $maxR = $BannerH * 0.42
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $n; $i++) {
            $theta = $i * 0.5
            $radd = ($i / ($n - 1.0)) * $maxR
            $sz = 0.8 + $rand.NextDouble() * 1.4
            $dot = New-Object System.Windows.Shapes.Ellipse
            $dot.Width = $sz; $dot.Height = $sz; $dot.Fill = $dotBrush; $dot.Opacity = 0.15 + $rand.NextDouble() * 0.4
            [void]$canvas.Children.Add($dot)
            [void]$info.Add([pscustomobject]@{ el = $dot; th = $theta; rad = $radd; sz = $sz })
        }
        $rot = [System.Windows.Media.RotateTransform]::new(0)
        $canvas.RenderTransform = $rot
        $ra = New-Object System.Windows.Media.Animation.DoubleAnimation
        $ra.From = 0; $ra.To = 360
        $ra.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(22.0))
        $ra.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $ra)
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            $cx = $cw / 2; $cy = $BannerH / 2; $rot.CenterX = $cx; $rot.CenterY = $cy
            foreach ($o in $info) {
                [System.Windows.Controls.Canvas]::SetLeft($o.el, $cx + [Math]::Cos($o.th) * $o.rad * 1.8 - ($o.sz / 2))
                [System.Windows.Controls.Canvas]::SetTop($o.el, $cy + [Math]::Sin($o.th) * $o.rad - ($o.sz / 2))
            } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSnow {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $flake = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(225, 240, 250)); $flake.Freeze()
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 50; $i++) {
            $d = 2 + $rand.NextDouble() * 3
            $e = New-Object System.Windows.Shapes.Ellipse
            $e.Width = $d; $e.Height = $d; $e.Fill = $flake; $e.Opacity = 0.3 + $rand.NextDouble() * 0.5
            $tt = New-Object System.Windows.Media.TranslateTransform
            $e.RenderTransform = $tt
            [System.Windows.Controls.Canvas]::SetTop($e, -3)
            $ydur = 6 + $rand.NextDouble() * 5
            # Fall the full L-size distance regardless of the current banner
            # height (smaller sizes just clip the bottom). Duration scales with
            # it so the speed stays identical - no resize handling, stays smooth.
            $fall = [Math]::Max($BannerH, 224.0) + 6
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = 0; $ay.To = $fall
            # Actual fall duration (scales with $fall so speed stays constant
            # across banner sizes). Seed the negative BeginTime from the SAME
            # duration so flakes start spread over the WHOLE fall - otherwise
            # they only fill the top portion at t=0 and fall as one clump.
            $actualDur = $ydur * $fall / ($BannerH + 6)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($actualDur))
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $actualDur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            $xdur = 3 + $rand.NextDouble() * 2
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(4 + $rand.NextDouble() * 8); $ax.To = (4 + $rand.NextDouble() * 8)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($xdur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $xdur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            [void]$canvas.Children.Add($e)
            [void]$info.Add([pscustomobject]@{ el = $e; fx = $rand.NextDouble() })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, $o.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerBreathe {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $specs = @(
            @{ col = "#34d399"; fx = 0.5; fy = 0.5;  dur = 7.0; phase = 0.0 },
            @{ col = "#3a8add"; fx = 0.2; fy = 1.05; dur = 9.0; phase = 1.5 }
        )
        $info = New-Object System.Collections.ArrayList
        foreach ($s in $specs) {
            $c = [System.Windows.Media.ColorConverter]::ConvertFromString($s.col)
            $rg = New-Object System.Windows.Media.RadialGradientBrush
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(85, $c.R, $c.G, $c.B), 0.0)) | Out-Null
            $rg.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, $c.R, $c.G, $c.B), 1.0)) | Out-Null
            $e = New-Object System.Windows.Shapes.Ellipse
            $e.Fill = $rg
            $e.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
            $st = [System.Windows.Media.ScaleTransform]::new(1, 1)
            $e.RenderTransform = $st
            $sc = New-Object System.Windows.Media.Animation.DoubleAnimation
            $sc.From = 1.0; $sc.To = 1.12
            $sc.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($s.dur)); $sc.AutoReverse = $true
            $sc.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $sc.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $sc.BeginTime = [TimeSpan]::FromSeconds(-$s.phase)
            $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $sc)
            $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $sc)
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $oa.From = 0.25; $oa.To = 0.7
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($s.dur)); $oa.AutoReverse = $true
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $oa.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $oa.BeginTime = [TimeSpan]::FromSeconds(-$s.phase)
            $e.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            [void]$canvas.Children.Add($e)
            [void]$info.Add([pscustomobject]@{ el = $e; fx = $s.fx; fy = $s.fy })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            $size = ([Math]::Max($cw, $BannerH)) * 1.4
            foreach ($o in $info) { $o.el.Width = $size; $o.el.Height = $size
                [System.Windows.Controls.Canvas]::SetLeft($o.el, ($o.fx * $cw) - ($size / 2))
                [System.Windows.Controls.Canvas]::SetTop($o.el, ($o.fy * $BannerH) - ($size / 2)) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerMatrix {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $glyphs = "01<>=*+-/#$%&?XY".ToCharArray()
        $fs = 13.0; $spacing = 20.0; $stripH = $BannerH + 60.0
        $lines = [int]($stripH / $fs) + 1
        $nCols = [int](1600 / $spacing)
        $fam = New-Object System.Windows.Media.FontFamily("Consolas")
        for ($c = 0; $c -lt $nCols; $c++) {
            $sb = New-Object System.Text.StringBuilder
            for ($l = 0; $l -lt $lines; $l++) {
                [void]$sb.Append($glyphs[$rand.Next(0, $glyphs.Length)])
                if ($l -lt ($lines - 1)) { [void]$sb.Append("`n") }
            }
            $tb = New-Object System.Windows.Controls.TextBlock
            $tb.Text = $sb.ToString(); $tb.FontFamily = $fam; $tb.FontSize = $fs
            $tb.LineHeight = $fs; $tb.LineStackingStrategy = [System.Windows.LineStackingStrategy]::BlockLineHeight
            $tb.TextAlignment = [System.Windows.TextAlignment]::Center
            $tb.Foreground = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(52, 211, 153))
            $mask = New-Object System.Windows.Media.LinearGradientBrush
            $mask.StartPoint = [System.Windows.Point]::new(0, 0); $mask.EndPoint = [System.Windows.Point]::new(0, 1)
            $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 255, 255, 255), 0.0)) | Out-Null
            $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 255, 255, 255), 0.85)) | Out-Null
            $mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 255, 255, 255), 1.0)) | Out-Null
            $tb.OpacityMask = $mask; $tb.Opacity = 0.85
            $tt = New-Object System.Windows.Media.TranslateTransform
            $tb.RenderTransform = $tt
            [System.Windows.Controls.Canvas]::SetLeft($tb, $c * $spacing)
            [System.Windows.Controls.Canvas]::SetTop($tb, -$stripH)
            $dur = (2.5 + $rand.NextDouble() * 2.0) * 1.3333
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = 0; $ay.To = ($stripH + $BannerH)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            [void]$canvas.Children.Add($tb)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerHyper {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $brush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(190, 220, 255)); $brush.Freeze()
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 90; $i++) {
            $streak = New-Object System.Windows.Shapes.Rectangle
            $streak.Width = 10; $streak.Height = 2.6; $streak.Fill = $brush; $streak.RadiusX = 1; $streak.RadiusY = 1
            $tg = New-Object System.Windows.Media.TransformGroup
            $sx = [System.Windows.Media.ScaleTransform]::new(1, 1)
            $tt = New-Object System.Windows.Media.TranslateTransform
            $rotd = $rand.NextDouble() * 360.0
            $tg.Children.Add($sx) | Out-Null; $tg.Children.Add($tt) | Out-Null
            $tg.Children.Add([System.Windows.Media.RotateTransform]::new($rotd)) | Out-Null
            $streak.RenderTransform = $tg
            $dur = (1.4 + $rand.NextDouble() * 1.2) * 2.0
            $bt = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
            $at = New-Object System.Windows.Media.Animation.DoubleAnimation
            $at.From = 0; $at.To = 1400
            $at.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $at.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $at.BeginTime = $bt
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $at)
            $asx = New-Object System.Windows.Media.Animation.DoubleAnimation
            $asx.From = 0.5; $asx.To = 14
            $asx.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $asx.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $asx.BeginTime = $bt
            $sx.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $asx)
            $ao = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ao.From = 0.0; $ao.To = 0.9
            $ao.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ao.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ao.BeginTime = $bt
            $streak.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $ao)
            [void]$canvas.Children.Add($streak)
            [void]$info.Add($streak)
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($s in $info) { [System.Windows.Controls.Canvas]::SetLeft($s, $cw / 2); [System.Windows.Controls.Canvas]::SetTop($s, $BannerH / 2) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerTunnel {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $stroke = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(80, 200, 255)); $stroke.Freeze()
        $n = 10; $maxR = $BannerH * 0.95
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $n; $i++) {
            $hex = New-Object System.Windows.Shapes.Polygon
            $pts = New-Object System.Windows.Media.PointCollection
            for ($k = 0; $k -lt 6; $k++) {
                $a = $k * [Math]::PI / 3.0
                $pts.Add([System.Windows.Point]::new([Math]::Cos($a) * 1.7 * $maxR, [Math]::Sin($a) * $maxR)) | Out-Null
            }
            $hex.Points = $pts; $hex.Stroke = $stroke; $hex.StrokeThickness = 2.0; $hex.Fill = $null
            $st = [System.Windows.Media.ScaleTransform]::new(0.12, 0.12)
            $hex.RenderTransform = $st
            $dur = 16.0
            $bt = [TimeSpan]::FromSeconds(-(($i / [double]$n) * $dur))
            $sa = New-Object System.Windows.Media.Animation.DoubleAnimation
            $sa.From = 0.12; $sa.To = 1.0
            $sa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $sa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $sa.BeginTime = $bt
            $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $sa)
            $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $sa)
            $oa = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
            $oa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $oa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $oa.BeginTime = $bt
            $oa.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(0)))) | Out-Null
            $oa.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.85, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.15)))) | Out-Null
            $oa.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.85, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.78)))) | Out-Null
            $oa.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur)))) | Out-Null
            $hex.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $oa)
            [void]$canvas.Children.Add($hex)
            [void]$info.Add($hex)
        }
        $rot = [System.Windows.Media.RotateTransform]::new(0)
        $canvas.RenderTransform = $rot
        $ra = New-Object System.Windows.Media.Animation.DoubleAnimation
        $ra.From = 0; $ra.To = 360
        $ra.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(60.0))
        $ra.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $ra)
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            $cx = $cw / 2; $cy = $BannerH / 2; $rot.CenterX = $cx; $rot.CenterY = $cy
            foreach ($h in $info) { [System.Windows.Controls.Canvas]::SetLeft($h, $cx); [System.Windows.Controls.Canvas]::SetTop($h, $cy) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerKaleido {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $ribbons = @(
            @{ r = 245; g = 166; b = 35; off = 0.42; amp = 14; w = 26; wl = 300.0; dur = 10.0; dir = -1 },
            @{ r = 244; g = 114; b = 182; off = 0.55; amp = 18; w = 30; wl = 380.0; dur = 13.0; dir = 1 },
            @{ r = 251; g = 113; b = 133; off = 0.66; amp = 11; w = 22; wl = 240.0; dur = 8.0;  dir = -1 }
        )
        foreach ($rb in $ribbons) {
            $baseY = $rb.off * $BannerH
            # Extend each ribbon well PAST both banner edges instead of
            # starting at x=0. A ribbon that drifts right (dir = +1) used to
            # move its left edge inward, uncovering a blank gap on the left
            # that grew until the loop wrapped - looking like the band got
            # shorter and then snapped back. The wave is periodic in wl and the
            # translate is exactly one wl, so with this overhang on both sides
            # the scroll stays seamless: full width at all times, no visible
            # jump.
            $x0 = -500; $x1 = 3200
            $fig = New-Object System.Windows.Media.PathFigure
            $fig.StartPoint = [System.Windows.Point]::new($x0, $baseY)
            $polyPts = New-Object System.Windows.Media.PointCollection
            for ($x = $x0; $x -le $x1; $x += 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl)
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            for ($x = $x1; $x -ge $x0; $x -= 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl) + $rb.w
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            $polySeg = New-Object System.Windows.Media.PolyLineSegment
            $polySeg.Points = $polyPts
            $fig.Segments.Add($polySeg) | Out-Null; $fig.IsClosed = $true
            $geo = New-Object System.Windows.Media.PathGeometry
            $geo.Figures.Add($fig) | Out-Null
            $path = New-Object System.Windows.Shapes.Path
            $path.Data = $geo
            $path.Fill = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(70, [byte]$rb.r, [byte]$rb.g, [byte]$rb.b))
            $tt = New-Object System.Windows.Media.TranslateTransform
            $path.RenderTransform = $tt
            $an = New-Object System.Windows.Media.Animation.DoubleAnimation
            $an.From = 0; $an.To = ($rb.dir * $rb.wl)
            $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($rb.dur))
            $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
            [void]$canvas.Children.Add($path)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerComet {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $br = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(120, 220, 255)); $br.Freeze()
        $brHead = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(225, 245, 255)); $brHead.Freeze()
        $nTrail = 36; $delta = 1.3
        $dur = 6.0 * 1.3333
        $orbit = New-Object System.Windows.Controls.Canvas
        $orbit.IsHitTestVisible = $false
        $orbit.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
        $squish = [System.Windows.Media.ScaleTransform]::new(1, 1)
        $orbit.RenderTransform = $squish
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $nTrail; $i++) {
            $frac = $i / ($nTrail - 1.0)
            $d = 2.0 + (1 - $frac) * 11.0
            $dot = New-Object System.Windows.Shapes.Ellipse
            $dot.Width = $d; $dot.Height = $d
            $dot.Fill = if ($i -le 1) { $brHead } else { $br }
            $dot.Opacity = [Math]::Pow((1 - $frac), 1.4) * 0.8 + 0.04
            if ($i -eq 0) {
                # Glowing head ball: bright core + soft halo.
                $gl = New-Object System.Windows.Media.Effects.BlurEffect; $gl.Radius = 10; $dot.Effect = $gl; $dot.Opacity = 1.0
            } elseif ($i -le 3) {
                # A couple of near-head dots glow too so the ball reads as luminous, not a hard disc.
                $gl2 = New-Object System.Windows.Media.Effects.BlurEffect; $gl2.Radius = 4; $dot.Effect = $gl2
            }
            $rot = [System.Windows.Media.RotateTransform]::new(0)
            $dot.RenderTransform = $rot
            $start = -($i * $delta)
            $ra = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ra.From = $start; $ra.To = ($start + 360)
            $ra.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
            $ra.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $ra)
            [void]$orbit.Children.Add($dot)
            [void]$info.Add([pscustomobject]@{ el = $dot; rot = $rot; d = $d })
        }
        [void]$canvas.Children.Add($orbit)
        $reflow = { $cw = $canvas.ActualWidth; $ch = $canvas.ActualHeight
            if ($cw -lt 20) { return }
            if ($ch -lt 20) { $ch = $BannerH }
            $Rx = $cw * 0.34; $Ry = $ch * 0.30
            $orbit.Width = $cw; $orbit.Height = $ch
            if ($Rx -gt 0) { $squish.ScaleY = $Ry / $Rx }
            foreach ($o in $info) {
                [System.Windows.Controls.Canvas]::SetLeft($o.el, ($cw / 2) + $Rx - ($o.d / 2))
                [System.Windows.Controls.Canvas]::SetTop($o.el, ($ch / 2) - ($o.d / 2))
                $o.rot.CenterX = ($o.d / 2) - $Rx
                $o.rot.CenterY = ($o.d / 2)
            } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSpark {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $nEmit = 10; $perEmit = 7
        $info = New-Object System.Collections.ArrayList
        for ($e = 0; $e -lt $nEmit; $e++) {
            $fx = ($e + 0.5) / $nEmit
            $isBottom = (($e % 2) -eq 0)
            $emitY = if ($isBottom) { $BannerH * 0.90 } else { $BannerH * 0.10 }
            for ($s = 0; $s -lt $perEmit; $s++) {
                $sp = New-Object System.Windows.Shapes.Ellipse
                $sp.Width = 2.2; $sp.Height = 2.2
                $warm = if ($rand.NextDouble() -lt 0.5) { [System.Windows.Media.Color]::FromRgb(255, 200, 120) } else { [System.Windows.Media.Color]::FromRgb(255, 150, 80) }
                $sp.Fill = [System.Windows.Media.SolidColorBrush]::new($warm)
                $tt = New-Object System.Windows.Media.TranslateTransform
                $sp.RenderTransform = $tt
                [System.Windows.Controls.Canvas]::SetTop($sp, $emitY)
                $dur = 1.2 + $rand.NextDouble() * 1.0
                $sbt = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $dur))
                $vx = ($rand.NextDouble() - 0.5) * 280
                $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
                $ax.From = 0; $ax.To = $vx
                $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
                $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.BeginTime = $sbt
                $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
                $ay = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
                $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
                $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ay.BeginTime = $sbt
                $eUp = New-Object System.Windows.Media.Animation.QuadraticEase; $eUp.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
                $eDn = New-Object System.Windows.Media.Animation.QuadraticEase; $eDn.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseIn
                if ($isBottom) {
                    $peak = -(($BannerH * 0.45) + $rand.NextDouble() * ($BannerH * 0.40))
                    $ay.KeyFrames.Add([System.Windows.Media.Animation.EasingDoubleKeyFrame]::new($peak, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.40)), $eUp)) | Out-Null
                    $ay.KeyFrames.Add([System.Windows.Media.Animation.EasingDoubleKeyFrame]::new(($peak * 0.45), [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur)), $eDn)) | Out-Null
                } else {
                    $pop  = -(($BannerH * 0.05) + $rand.NextDouble() * ($BannerH * 0.10))
                    $fall =  (($BannerH * 0.55) + $rand.NextDouble() * ($BannerH * 0.30))
                    $ay.KeyFrames.Add([System.Windows.Media.Animation.EasingDoubleKeyFrame]::new($pop, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.25)), $eUp)) | Out-Null
                    $ay.KeyFrames.Add([System.Windows.Media.Animation.EasingDoubleKeyFrame]::new($fall, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur)), $eDn)) | Out-Null
                }
                $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
                $op = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
                $op.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($dur))
                $op.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $op.BeginTime = $sbt
                $op.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(0)))) | Out-Null
                $op.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(1.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.06)))) | Out-Null
                $op.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(1.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur * 0.55)))) | Out-Null
                $op.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new(0.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds($dur)))) | Out-Null
                $sp.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $op)
                [void]$canvas.Children.Add($sp)
                [void]$info.Add([pscustomobject]@{ el = $sp; fx = $fx })
            }
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, $o.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerField {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $seg = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(102, 52, 211, 153)); $seg.Freeze()
        $spacing = 32.0
        $build = {
            $cw = $canvas.ActualWidth; $ch = $canvas.ActualHeight
            if ($cw -lt 20 -or $ch -lt 20) { return }
            $canvas.Children.Clear()
            $cols = [int]([Math]::Ceiling($cw / $spacing)) + 1
            $rows = [int]([Math]::Ceiling($ch / $spacing)) + 1
            for ($r = 0; $r -lt $rows; $r++) {
                for ($c = 0; $c -lt $cols; $c++) {
                    $tick = New-Object System.Windows.Shapes.Rectangle
                    $tick.Width = 14; $tick.Height = 1.2; $tick.Fill = $seg
                    $tick.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
                    $rot = [System.Windows.Media.RotateTransform]::new(0)
                    $tick.RenderTransform = $rot
                    [System.Windows.Controls.Canvas]::SetLeft($tick, $c * $spacing - 7)
                    [System.Windows.Controls.Canvas]::SetTop($tick, $r * $spacing)
                    $base = (($c + $r) * 20) % 360
                    $aa = New-Object System.Windows.Media.Animation.DoubleAnimation
                    $aa.From = ($base - 40); $aa.To = ($base + 40)
                    $aa.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(6.0)); $aa.AutoReverse = $true
                    $aa.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $aa.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
                    $aa.BeginTime = [TimeSpan]::FromSeconds(-((($c + $r) % 8) * 0.4))
                    $rot.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $aa)
                    [void]$canvas.Children.Add($tick)
                }
            }
        }.GetNewClosure()
        $canvas.Add_SizeChanged($build); & $build
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerSilk {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $ribbons = @(
            @{ r = 54;  g = 224; b = 224; off = 0.42; amp = 14; w = 26; wl = 300.0; dur = 10.0; dir = -1 },
            @{ r = 200; g = 80;  b = 255; off = 0.55; amp = 18; w = 30; wl = 380.0; dur = 13.0; dir = 1 },
            @{ r = 52;  g = 211; b = 153; off = 0.66; amp = 11; w = 22; wl = 240.0; dur = 8.0;  dir = -1 }
        )
        foreach ($rb in $ribbons) {
            $baseY = $rb.off * $BannerH
            # Extend each ribbon well PAST both banner edges instead of
            # starting at x=0. A ribbon that drifts right (dir = +1) used to
            # move its left edge inward, uncovering a blank gap on the left
            # that grew until the loop wrapped - looking like the band got
            # shorter and then snapped back. The wave is periodic in wl and the
            # translate is exactly one wl, so with this overhang on both sides
            # the scroll stays seamless: full width at all times, no visible
            # jump.
            $x0 = -500; $x1 = 3200
            $fig = New-Object System.Windows.Media.PathFigure
            $fig.StartPoint = [System.Windows.Point]::new($x0, $baseY)
            $polyPts = New-Object System.Windows.Media.PointCollection
            for ($x = $x0; $x -le $x1; $x += 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl)
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            for ($x = $x1; $x -ge $x0; $x -= 10) {
                $y = $baseY + $rb.amp * [Math]::Sin(2 * [Math]::PI * $x / $rb.wl) + $rb.w
                $polyPts.Add([System.Windows.Point]::new($x, $y)) | Out-Null
            }
            $polySeg = New-Object System.Windows.Media.PolyLineSegment
            $polySeg.Points = $polyPts
            $fig.Segments.Add($polySeg) | Out-Null; $fig.IsClosed = $true
            $geo = New-Object System.Windows.Media.PathGeometry
            $geo.Figures.Add($fig) | Out-Null
            $path = New-Object System.Windows.Shapes.Path
            $path.Data = $geo
            $path.Fill = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(70, [byte]$rb.r, [byte]$rb.g, [byte]$rb.b))
            $tt = New-Object System.Windows.Media.TranslateTransform
            $path.RenderTransform = $tt
            $an = New-Object System.Windows.Media.Animation.DoubleAnimation
            $an.From = 0; $an.To = ($rb.dir * $rb.wl)
            $an.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($rb.dur))
            $an.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $an)
            [void]$canvas.Children.Add($path)
        }
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

function global:Add-BannerBubbles {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex)
    try {
        $banner = $global:window.FindName($BannerName); if (-not $banner -or -not $banner.Child) { return }
        $grid = $banner.Child; if ($grid -isnot [System.Windows.Controls.Grid]) { return }
        $canvas = New-Object System.Windows.Controls.Canvas
        $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
        $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $canvas.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
        $rand = New-Object System.Random
        $ringBr = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(150, 225, 235)); $ringBr.Freeze()
        $hlBr = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(220, 250, 255)); $hlBr.Freeze()
        $info = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt 42; $i++) {
            $rr = 4 + $rand.NextDouble() * 8; $d = $rr * 2
            $bc = New-Object System.Windows.Controls.Canvas
            $bc.Width = $d; $bc.Height = $d; $bc.IsHitTestVisible = $false; $bc.Opacity = 0.3 + $rand.NextDouble() * 0.3
            $ring = New-Object System.Windows.Shapes.Ellipse
            $ring.Width = $d; $ring.Height = $d; $ring.Stroke = $ringBr; $ring.StrokeThickness = 1.2; $ring.Fill = $null
            [System.Windows.Controls.Canvas]::SetLeft($ring, 0); [System.Windows.Controls.Canvas]::SetTop($ring, 0)
            $hl = New-Object System.Windows.Shapes.Ellipse
            $hl.Width = ($d * 0.26); $hl.Height = ($d * 0.26); $hl.Fill = $hlBr
            [System.Windows.Controls.Canvas]::SetLeft($hl, $d * 0.22); [System.Windows.Controls.Canvas]::SetTop($hl, $d * 0.2)
            [void]$bc.Children.Add($ring); [void]$bc.Children.Add($hl)
            $tt = New-Object System.Windows.Media.TranslateTransform
            $bc.RenderTransform = $tt
            [System.Windows.Controls.Canvas]::SetTop($bc, $BannerH + 10)
            $ydur = 7 + $rand.NextDouble() * 5
            $ay = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ay.From = 0; $ay.To = -($BannerH + 20 + $d)
            $ay.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($ydur))
            $ay.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $ay.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $ydur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $ay)
            $xdur = 3 + $rand.NextDouble() * 2
            $ax = New-Object System.Windows.Media.Animation.DoubleAnimation
            $ax.From = -(5 + $rand.NextDouble() * 6); $ax.To = (5 + $rand.NextDouble() * 6)
            $ax.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($xdur)); $ax.AutoReverse = $true
            $ax.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever; $ax.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
            $ax.BeginTime = [TimeSpan]::FromSeconds(-($rand.NextDouble() * $xdur))
            $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $ax)
            [void]$canvas.Children.Add($bc)
            [void]$info.Add([pscustomobject]@{ el = $bc; fx = $rand.NextDouble() })
        }
        $reflow = { $cw = $canvas.ActualWidth; if ($cw -lt 20) { return }
            foreach ($o in $info) { [System.Windows.Controls.Canvas]::SetLeft($o.el, $o.fx * $cw) } }.GetNewClosure()
        $canvas.Add_SizeChanged($reflow); & $reflow
        $canvas.Tag = "BannerFx"
        $idx = [Math]::Min(1, $grid.Children.Count); $grid.Children.Insert($idx, $canvas)
    } catch { }
}

# Dispatcher: route a banner to one of the animated effects.
function global:Add-BannerEffect {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex, [string]$Effect)
    switch ($Effect) {
        "parallax" { Add-BannerParallax  -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "nebula"    { Add-BannerNebula    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "meteors"   { Add-BannerMeteors   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "sonar"     { Add-BannerSonar     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "motes"     { Add-BannerMotes     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "equalizer" { Add-BannerEqualizer -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "speed"     { Add-BannerSpeed     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "flow"      { Add-BannerFlow      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "plasma"    { Add-BannerPlasma    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "blobsunset" { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#ff7a4d","#ffb020","#ff4d80","#ff9a3d") }
        "blobcandy"  { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#ff5fa2","#a45cff","#36d0e0","#ff8fd0") }
        "blobocean"  { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#16d0a0","#2ab0ff","#4de0d0","#3a8add") }
        "blobember"  { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#ff4d2e","#ff8a1e","#ffd24d","#e0341e") }
        "blobtoxic"  { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#8aff3a","#34e07a","#c8ff2e","#2ee0a0") }
        "blobice"    { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#8ad8ff","#4db8ff","#a0e8ff","#5de0e0") }
        "blobviolet" { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#c850ff","#8a5cff","#ff5fd0","#6a4dff") }
        "blobmidnight" { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#3a5cff","#6a4dff","#2a8aff","#4d5cff") }
        "blobamber"    { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#ffb020","#2ab0ff","#ffd24d","#3a8add") }
        "blobrose"     { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#ff5f8a","#ff8fb0","#ff4d6a","#ffa0c0") }
        "blobforest"   { Add-BannerBlobs -BannerName $BannerName -BannerH $BannerH -Palette @("#34d399","#a0e04d","#2ab08a","#c8ff6a") }
        "stripes"   { Add-BannerStripes   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "twinkle"   { Add-BannerTwinkle   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "rain"      { Add-BannerRain      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "bokeh"     { Add-BannerBokeh     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "bokehsunset" { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#ff7a4d","#ffb020","#ff4d80","#ff9a3d") }
        "bokehcandy"  { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#ff5fa2","#a45cff","#36d0e0","#ff8fd0") }
        "bokehember"  { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#ff4d2e","#ff8a1e","#ffd24d","#e0341e") }
        "bokehtoxic"  { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#8aff3a","#34e07a","#c8ff2e","#2ee0a0") }
        "bokehviolet" { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#c850ff","#8a5cff","#ff5fd0","#6a4dff") }
        "bokehmidnight" { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#3a5cff","#6a4dff","#2a8aff","#4d5cff") }
        "bokehgold"     { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#ffcf4d","#8a5cff","#ffe08a","#6a4dff") }
        "bokehmint"     { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#4de0c0","#8affd0","#2ec0a0","#a0ffe0") }
        "bokehcoral"    { Add-BannerBokeh -BannerName $BannerName -BannerH $BannerH -Palette @("#ff6a4d","#ff9a3d","#ffd24d","#ff4d7a") }
        "shards"    { Add-BannerShards    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "waves"     { Add-BannerWaves     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "rays"      { Add-BannerRays      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "lava"      { Add-BannerLava      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "topo"      { Add-BannerTopo      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "vortex"    { Add-BannerVortex    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "snow"      { Add-BannerSnow      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "breathe"   { Add-BannerBreathe   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "matrix"    { Add-BannerMatrix    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "hyper"     { Add-BannerHyper     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "tunnel"    { Add-BannerTunnel    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "kaleido"   { Add-BannerKaleido   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "comet"     { Add-BannerComet     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "spark"     { Add-BannerSpark     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "field"     { Add-BannerField     -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "silk"      { Add-BannerSilk      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "bubbles"   { Add-BannerBubbles   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "orbs"    { Add-BannerOrbs      -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "synth"   { Add-BannerSynthGrid -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "circuit" { Add-BannerCircuit   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "network" { Add-BannerNetwork   -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "hex"     { Add-BannerHex       -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        "embers"  { Add-BannerEmbers    -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex }
        default   { Add-BannerStarfield -BannerName $BannerName -BannerH $BannerH -StarColorHex $ColorHex }
    }
}

# Replace whatever effect a banner currently has with a fresh one. Removes
# any previously added effect layer (tagged "BannerFx") first.
function global:Set-BannerEffect {
    param([string]$BannerName, [double]$BannerH, [string]$ColorHex, [string]$Effect)
    $banner = $global:window.FindName($BannerName)
    if ($banner -and ($banner.Child -is [System.Windows.Controls.Grid])) {
        $g = $banner.Child
        for ($i = $g.Children.Count - 1; $i -ge 0; $i--) {
            $ch = $g.Children[$i]
            if ($ch -and $ch.Tag -eq "BannerFx") { $g.Children.RemoveAt($i) }
        }
    }
    Add-BannerEffect -BannerName $BannerName -BannerH $BannerH -ColorHex $ColorHex -Effect $Effect
}

# Re-roll the per-banner effects (used on Explore shuffle). Picks are random,
# so an effect can occasionally stay. Stops old network timers first so they
# don't keep ticking on removed canvases.
function global:Reshuffle-BannerEffects {
    try {
        if ($global:BannerTimers) {
            foreach ($t in $global:BannerTimers) { try { $t.Stop() } catch { } }
            $global:BannerTimers.Clear()
        }
        Set-BannerEffect -BannerName "OvBanner"   -BannerH 200 -ColorHex "#FFFFFF" -Effect (Get-BannerFxFor -Game $global:OvBannerGame)
        Set-BannerEffect -BannerName "ListBanner" -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:ListBannerGame)
        Set-BannerEffect -BannerName "LibBanner"  -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:LibBannerGame)
    } catch { }
}

# Stop and forget a banner's network-effect timer (if it has one) so a
# re-roll doesn't leave it ticking on a detached canvas.
function global:Stop-BannerNetTimer {
    param([string]$BannerName)
    if (-not $global:BannerNetTimers) { return }
    $t = $global:BannerNetTimers[$BannerName]
    if ($t) {
        try { $t.Stop() } catch { }
        if ($global:BannerTimers) { try { $global:BannerTimers.Remove($t) } catch { } }
        $global:BannerNetTimers.Remove($BannerName) | Out-Null
    }
}

# Timed rotation for the two VR-mod-list banners ONLY (Steam portrait
# list + library tiles). Picks a new featured game and a fresh random
# effect for each - the same pair of moves the Explore Shuffle button
# makes - but never touches the Explore banner, which has its own
# Shuffle. Skips a banner the user has disabled.
function global:Invoke-ListLibBannerRotation {
    $listDisabled = [bool](Get-HubSetting -Key "bannerListDisabled" -Default $false)
    $libDisabled  = [bool](Get-HubSetting -Key "bannerLibDisabled"  -Default $false)
    if (-not $listDisabled -and (Get-Command Set-ListBanner -ErrorAction SilentlyContinue)) {
        try {
            Set-ListBanner
            Stop-BannerNetTimer "ListBanner"
            Set-BannerEffect -BannerName "ListBanner" -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:ListBannerGame)
        } catch { }
    }
    if (-not $libDisabled -and (Get-Command Set-LibBanner -ErrorAction SilentlyContinue)) {
        try {
            Set-LibBanner
            Stop-BannerNetTimer "LibBanner"
            Set-BannerEffect -BannerName "LibBanner" -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:LibBannerGame)
        } catch { }
    }
}

# General banner-effect pool. The neon synth-grid road is deliberately
# NOT in here: it is the one theme-specific effect, so it only appears
# for futuristic / techy games via Get-BannerFxFor (below). Every other
# effect is fair game for any banner.
$global:BannerFxPool = @("stars","parallax","orbs","circuit","network","hex","embers","nebula","meteors","sonar","motes","equalizer","speed","plasma","blobsunset","blobcandy","blobocean","blobember","blobtoxic","blobice","blobviolet","blobmidnight","blobamber","blobrose","blobforest","stripes","twinkle","rain","bokeh","bokehsunset","bokehcandy","bokehember","bokehtoxic","bokehviolet","bokehmidnight","bokehgold","bokehmint","bokehcoral","shards","waves","rays","lava","topo","vortex","snow","breathe","matrix","hyper","tunnel","kaleido","comet","spark","field","silk","bubbles")

# Titles eligible for the synth-grid even if their tags carry no
# futuristic marker (explicit opt-in).
$global:FuturisticBannerTitles = @(
    "Dolphin VR + ReduX"
)

# Tags that mark a game as modern / futuristic / techy enough for the
# neon synth-grid road to fit.
$global:FuturisticBannerTags = @(
    "cyberpunk", "sci-fi", "scifi", "sci fi", "neon", "futuristic",
    "synthwave", "retrowave", "outrun", "cyber", "techno", "dystopian"
)

# True when a game reads as futuristic / techy (explicit title or any
# futuristic tag). Gates the synth-grid effect.
function global:Test-FuturisticGame {
    param($Game)
    if (-not $Game) { return $false }
    if ($Game.Title -and ($global:FuturisticBannerTitles -contains $Game.Title)) { return $true }
    if ($Game.Tags) {
        foreach ($t in $Game.Tags) {
            $tl = ("$t").ToLower()
            foreach ($f in $global:FuturisticBannerTags) {
                if ($tl -eq $f -or $tl.Contains($f)) { return $true }
            }
        }
    }
    return $false
}

# Titles eligible for the bright rainbow "flow" wash even if their tags
# carry no colourful marker (explicit opt-in). Flow's garish teal/blue/
# purple only fits comic-like or vividly colourful games - never dark ones
# (Doom, Quake, etc.). Add titles here to let flow appear on them.
$global:ColorfulBannerTitles = @(
    "Cruelty Squad VR",
    "R.E.P.O. VR",
    "Sonic P-06 VR",
    "Astrodogs VR",
    "Bomb Rush Cyberfunk",
    "Life is Strange: BtS",
    "Paperklay VR",
    "PEAK VR",
    "Slime Rancher VR",
    "Trombone Champ VR",
    "Alba VR",
    "StreetDog BMX VR",
    "Super Polygon Grand Prix VR"
)

# Tags that mark a game as comic / cartoon / vividly colourful enough for
# the flow wash to fit.
$global:ColorfulBannerTags = @(
    "comic", "cartoon", "cartoony", "cel-shaded", "cel shaded", "toon",
    "colorful", "colourful", "vibrant", "stylized", "stylised",
    "psychedelic", "arcade", "cute", "whimsical"
)

# Titles explicitly BARRED from the flow wash even if a tag would match -
# e.g. Bendy is tagged "comic" but is black-and-white, so the rainbow flow
# does not fit. Add titles here to keep flow off them.
$global:ColorfulBannerExclude = @(
    "Bendy VR"
)

# True when a game reads as comic-like / vividly colourful (explicit title
# or any colourful tag). Gates the flow wash.
function global:Test-ColorfulGame {
    param($Game)
    if (-not $Game) { return $false }
    if ($Game.Title -and ($global:ColorfulBannerExclude -contains $Game.Title)) { return $false }
    if ($Game.Title -and ($global:ColorfulBannerTitles -contains $Game.Title)) { return $true }
    if ($Game.Tags) {
        foreach ($t in $Game.Tags) {
            $tl = ("$t").ToLower()
            foreach ($f in $global:ColorfulBannerTags) {
                if ($tl -eq $f -or $tl.Contains($f)) { return $true }
            }
        }
    }
    return $false
}

# Pick one banner effect for a banner showing $Game. The synth-grid is
# only added as a candidate (so it CAN come up, never guaranteed) when
# the game reads as futuristic; a null game falls back to the general
# pool (no synth).
function global:Get-BannerFxFor {
    param($Game)
    $pool = @($global:BannerFxPool)
    if (Test-FuturisticGame -Game $Game) { $pool += "synth" }
    if (Test-ColorfulGame    -Game $Game) { $pool += "flow" }
    return ($pool | Get-Random)
}

Set-BannerEffect -BannerName "OvBanner"   -BannerH 200 -ColorHex "#FFFFFF" -Effect (Get-BannerFxFor -Game $global:OvBannerGame)
Set-BannerEffect -BannerName "ListBanner" -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:ListBannerGame)
Set-BannerEffect -BannerName "LibBanner"  -BannerH 140 -ColorHex "#ffcf8c" -Effect (Get-BannerFxFor -Game $global:LibBannerGame)

function global:Add-BannerDotPulse {
    # Give the control-type dot before "featured mod" a slow, subtle pulse with
    # a soft glow that peaks at maximum size - a small eye-catcher. Uses a
    # RenderTransform (render-time, no layout reflow, so the text never shifts).
    # The glow COLOUR is set per featured game in Set-BannerForGame; here we
    # only build the (colour-independent) scale + blur animations once.
    param([string]$DotName)
    try {
        $dot = $global:window.FindName($DotName)
        if (-not $dot) { return }
        $dot.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
        $st = New-Object System.Windows.Media.ScaleTransform 1.0, 1.0
        $dot.RenderTransform = $st

        $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
        $glow.ShadowDepth = 0
        $glow.BlurRadius  = 0
        $glow.Opacity     = 0.85
        $glow.Color       = [System.Windows.Media.Colors]::White   # retinted per game
        $dot.Effect = $glow

        $ease = New-Object System.Windows.Media.Animation.SineEase
        $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseInOut
        $dur = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(1700))

        $scaleAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
        $scaleAnim.From = 1.0
        $scaleAnim.To   = 0.7
        $scaleAnim.Duration = $dur
        $scaleAnim.AutoReverse = $true
        $scaleAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $scaleAnim.EasingFunction = $ease
        $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $scaleAnim)
        $st.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $scaleAnim)

        # Glow rides the SAME timing, inverted: full at rest (normal size) and
        # gone at the small end - so the dot clearly "breathes" inward, glowing
        # at full size, then dips to a small plain dot and back.
        $glowAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
        $glowAnim.From = 8.0
        $glowAnim.To   = 0.0
        $glowAnim.Duration = $dur
        $glowAnim.AutoReverse = $true
        $glowAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $glowAnim.EasingFunction = $ease
        $glow.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::BlurRadiusProperty, $glowAnim)
    } catch { }
}
Add-BannerDotPulse "ListBannerCtrlDot"
Add-BannerDotPulse "LibBannerCtrlDot"
Add-BannerDotPulse "OvBannerCtrlDot"

if ($versionLabel) { $versionLabel.Text = "v$HUB_VERSION" }

# Header hover-grow: version badge, VR headset glyph, and the
# "Install n!ce VR mods..." tagline all subtly scale up on hover,
# matching the motion language used by the list banner and tag
# chips. Pure visual flourish - no click action attached.
function global:Add-HeaderHoverGrow {
    param($Element, [double]$Scale = 1.08)
    if (-not $Element) { return }
    $Element.RenderTransformOrigin = New-Object System.Windows.Point 0.5, 0.5
    $scaleCapture = $Scale
    $elemCapture  = $Element
    $elemCapture.Add_MouseEnter({
        $s = New-Object System.Windows.Media.ScaleTransform $scaleCapture, $scaleCapture
        $elemCapture.RenderTransform = $s
    }.GetNewClosure())
    $elemCapture.Add_MouseLeave({
        $elemCapture.RenderTransform = $null
    }.GetNewClosure())
}
Add-HeaderHoverGrow -Element $versionBadge   -Scale 1.10
Add-HeaderHoverGrow -Element $headerVrIcon   -Scale 1.15
Add-HeaderHoverGrow -Element $headerHubTitle -Scale 1.04
Add-HeaderHoverGrow -Element $headerTagline  -Scale 1.04

# Populate and reveal the "Update X available" banner. Factored into a
# global function (instead of an inline block that ran once at load time)
# so a background update check that finishes AFTER the window is already
# open can call it to reveal the banner live in the SAME session - the
# Hub loads and is usable immediately, then this little banner lights up
# quietly once the check is done. Idempotent: the hover/click handlers are
# wired only once (guarded by a flag); repeat calls just refresh the text
# and keep the banner visible. Elements are re-resolved via FindName so the
# function works when called later from a timer tick (outside module scope).
$global:UpdateBannerWired = $false
function global:Show-UpdateBanner {
    param($Info)
    if (-not $Info -or -not $Info.LatestVersion) { return }
    $banner     = $global:window.FindName("UpdateBanner")
    $bannerText = $global:window.FindName("UpdateBannerText")
    if (-not $banner -or -not $bannerText) { return }
    $bannerText.Text   = "Update $($Info.LatestVersion) available"
    $banner.Visibility = [System.Windows.Visibility]::Visible
    if (-not $global:UpdateBannerWired) {
        $global:UpdateBannerWired = $true
        $banner.Add_MouseEnter({
            $b = $global:window.FindName("UpdateBanner")
            if ($b) { $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#234a23") }
        })
        $banner.Add_MouseLeave({
            $b = $global:window.FindName("UpdateBanner")
            if ($b) { $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a2e1a") }
        })
        $banner.Add_PreviewMouseLeftButtonDown({
            $updaterPath = Join-Path $global:scriptDir "Update-Hub.ps1"
            Start-Process "powershell.exe" -ArgumentList `
                "-NoProfile -ExecutionPolicy Bypass -File `"$updaterPath`""
            $global:window.Close()
        })
    }
}

# A marker left by a previous run (genuine update not yet applied) reveals
# the banner immediately on startup. A marker written by THIS session's
# background check is picked up live by the poll in Startup.ps1.
if ($script:updateInfo) { Show-UpdateBanner -Info $script:updateInfo }

$ownList     = $window.FindName("OwnGameList")
$ownListGP   = $window.FindName("OwnGameListGP")
$extList     = $window.FindName("ExternalGameList")

$headerMC  = $window.FindName("HeaderMC")
$headerGP  = $window.FindName("HeaderGP")
$headerExt = $window.FindName("HeaderExt")
$dividerMC = $window.FindName("DividerMC")
$dividerGP = $window.FindName("DividerGP")

$headerMC.Add_PreviewMouseLeftButtonDown({
    $ownList.Visibility = if ($ownList.Visibility -eq [System.Windows.Visibility]::Visible) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    $dividerMC.Visibility = $ownList.Visibility
}.GetNewClosure())
$headerGP.Add_PreviewMouseLeftButtonDown({
    $ownListGP.Visibility = if ($ownListGP.Visibility -eq [System.Windows.Visibility]::Visible) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
    $dividerGP.Visibility = $ownListGP.Visibility
}.GetNewClosure())
$headerExt.Add_PreviewMouseLeftButtonDown({
    $extList.Visibility = if ($extList.Visibility -eq [System.Windows.Visibility]::Visible) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }
}.GetNewClosure())

# Load the saved scale BEFORE the initial card-build so cards
# are constructed at the right size on the first pass. Previously
# the cards were built with default SCALE=1.0 here, then Apply-Scale
# rebuilt them ALL again later when a saved 1.5/2.0 was found -
# doubling the startup time at M and L.
if (Get-Command Get-HubSetting -ErrorAction SilentlyContinue) {
    try {
        $savedScaleEarly = Get-HubSetting -Key "scaleList" -Default 1.0
        if ($savedScaleEarly -is [string]) {
            try { $savedScaleEarly = [double]$savedScaleEarly } catch { $savedScaleEarly = 1.0 }
        }
        if ($savedScaleEarly -in @(1.0, 1.5, 2.0)) {
            $global:SCALE = $savedScaleEarly
        }
    } catch { }
}

# Active tile style, loaded before the card-build loop so New-GameCard
# dispatches to the right renderer on the first pass. 'frosted' is the
# default redesign; 'classic' is the original flat tiles. Flipped (and
# persisted) by the Switch Hub Style menu item + the header VR-glasses
# click, which then rebuild the cards.
$global:hubStyle = [string](Get-HubSetting -Key "hubStyle" -Default "frosted")
if ($global:hubStyle -ne "classic") { $global:hubStyle = "frosted" }

foreach ($game in $ownGames) {
    try   { $ownList.Children.Add((New-GameCard $game $false $window)) | Out-Null }
    catch { try { Write-Host "  [card-build] skipped '$($game.Title)': $_" -ForegroundColor DarkYellow } catch {}; $ownList.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
}
foreach ($game in $ownGamesGP) {
    try   { $ownListGP.Children.Add((New-GameCard $game $false $window)) | Out-Null }
    catch { try { Write-Host "  [card-build] skipped '$($game.Title)': $_" -ForegroundColor DarkYellow } catch {}; $ownListGP.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
}
foreach ($game in $externalGames) {
    try   { $extList.Children.Add((New-GameCard $game $true  $window)) | Out-Null }
    catch { try { Write-Host "  [card-build] skipped '$($game.Title)': $_" -ForegroundColor DarkYellow } catch {}; $extList.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
}

# Section-header mod counts (Custom Installers split by control type + External).
try {
    $hmcSub = $window.FindName("HeaderMCSub"); if ($hmcSub) { $hmcSub.Text = "$(@($ownGames).Count) mods" }
    $global:HubGPCount   = @($ownGamesGP).Count
    $global:HubVRGPCount = @($ownGamesGP | Where-Object { $_.Controls -eq "VRGP" }).Count
    $hgpSub = $window.FindName("HeaderGPSub"); if ($hgpSub) { $hgpSub.Text = "$(@($ownGamesGP).Count) mods" }
    $hexC   = $window.FindName("HeaderExtCount"); if ($hexC) { $hexC.Text = "$(@($externalGames).Count) mods" }
} catch {}

# Scale S / M / L buttons
$scaleSBtn = $window.FindName("ScaleS")
$scaleMBtn = $window.FindName("ScaleM")
$scaleLBtn = $window.FindName("ScaleL")

# Soft hover on the size selector - same reasoning as the filter
# pills above. The active button has an accent border; hover gets
# only a background brighten so the two states stay distinguishable.
Add-SoftHover -Border $scaleSBtn
Add-SoftHover -Border $scaleMBtn
Add-SoftHover -Border $scaleLBtn

function global:Set-ScaleActive { param($active)
    foreach ($btn in @($scaleSBtn, $scaleMBtn, $scaleLBtn)) {
        # Inactive: glass base bg + soft glass border. Identical to
        # the inactive state of the filter pills - the row reads as
        # one visual family.
        $btn.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#09ffffff")
        $btn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0fffffff")
        ($btn.Child).Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#aaaaaa")
        # Drop the SoftHover stash so a pending MouseLeave can't
        # undo what we just set (see Add-SoftHover comments).
        if ($btn.Resources.Contains("shBg")) { $btn.Resources.Remove("shBg") | Out-Null }
        if ($btn.Child -and $btn.Child.Resources.Contains("shFg")) {
            $btn.Child.Resources.Remove("shFg") | Out-Null
        }
        # Also drop the old Add-GlowHover stash key in case anything
        # else still touches it - defensive, costs nothing.
        if ($btn.Child -and $btn.Child.Resources.Contains("ghFg")) {
            $btn.Child.Resources.Remove("ghFg") | Out-Null
        }
    }
    # Active: keep glass background, signal selection via a neutral
    # accent border + white text. Same active-look pattern as the
    # filter pills, so the whole bar reads consistently.
    $active.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#09ffffff")
    $active.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5566aa")
    ($active.Child).Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#ffffff")
}

# Apply the gentle S/M/L card curve to the EXISTING cards via
# LayoutTransform - no Clear()/New-GameCard rebuild, so switching size
# is instant (previously a ~4-5s full rebuild) and the filter state
# (card visibility) is preserved. The S/M/L *level* stays 1.0/1.5/2.0
# everywhere else (buttons, persistence, headers, Recently Played);
# only the card body uses the gentle 1.0/1.2/1.4 curve. Headers and the
# ListBanner are NOT cards (they live outside these panels) and are
# scaled separately by their FontSize maps, so they never double-scale.
function global:Apply-CardScale {
    $cardScale = switch ($global:SCALE) {
        1.5     { 1.15 }
        2.0     { 1.3 }
        default { 1.0 }
    }
    foreach ($panel in @($ownList, $ownListGP, $extList)) {
        if (-not $panel) { continue }
        foreach ($card in $panel.Children) {
            if (-not $card) { continue }
            if ($cardScale -eq 1.0) {
                $card.LayoutTransform = $null
            } else {
                $card.LayoutTransform = New-Object System.Windows.Media.ScaleTransform $cardScale, $cardScale
            }
        }
    }
}

# ------------------------------------------------------------
# Switch the tile style at runtime. Flips $global:hubStyle, persists
# it to .hub-settings.json, then tears down + rebuilds all three card
# lists with the other renderer (New-GameCard dispatches on the flag),
# re-applies the S/M/L scale, and re-runs Rebuild-Lookups so install
# states + the card->game map are restored onto the fresh cards.
# Mirrors the initial build loop. WPF rendering is not verifiable on
# Linux - the switch logic is, the look is tuned by-eye on Windows.
# ------------------------------------------------------------
function global:Switch-HubStyle {
    $global:hubStyle = if ($global:hubStyle -eq 'classic') { 'frosted' } else { 'classic' }
    if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
        Set-HubSetting -Key "hubStyle" -Value $global:hubStyle
    }
    foreach ($p in @($ownList, $ownListGP, $extList)) { if ($p) { $p.Children.Clear() } }
    foreach ($game in $ownGames) {
        try   { $ownList.Children.Add((New-GameCard $game $false $global:window)) | Out-Null }
        catch { $ownList.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
    }
    foreach ($game in $ownGamesGP) {
        try   { $ownListGP.Children.Add((New-GameCard $game $false $global:window)) | Out-Null }
        catch { $ownListGP.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
    }
    foreach ($game in $externalGames) {
        try   { $extList.Children.Add((New-GameCard $game $true $global:window)) | Out-Null }
        catch { $extList.Children.Add((New-Object System.Windows.Controls.Border)) | Out-Null }
    }
    if (Get-Command Apply-CardScale     -ErrorAction SilentlyContinue) { Apply-CardScale }
    if (Get-Command Rebuild-Lookups     -ErrorAction SilentlyContinue) { Rebuild-Lookups }
    if (Get-Command Build-RecentlyPlayed -ErrorAction SilentlyContinue) { Build-RecentlyPlayed }
}

# Scale the list-view featured banner (ListBanner) to the list S/M/L
# scale (1.0/1.5/2.0): height, text and layout spacing together. Kept
# separate from Apply-Scale so startup can scale the banner without a
# full card rebuild. Normal (1.0) = the XAML defaults (height 140,
# title 22, sub 11, kicker 10, grid top-margin 16, button pad 14/7,
# button font 11).
function global:Set-ListBannerScale { param($sc)
    $lb = switch ($sc) {
        1.0     { @{ H = 140; Title = 22; Sub = 11; Kicker = 10; Top = 16; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
        1.5     { @{ H = 156; Title = 25; Sub = 12; Kicker = 11; Top = 20; BtnFont = 12; BtnPadX = 16; BtnPadY = 8 } }
        2.0     { @{ H = 174; Title = 28; Sub = 13; Kicker = 12; Top = 24; BtnFont = 13; BtnPadX = 18; BtnPadY = 9 } }
        default { @{ H = 140; Title = 22; Sub = 11; Kicker = 10; Top = 16; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
    }
    if (-not $global:window) { return }
    $lbB = $global:window.FindName("ListBanner")
    if ($lbB) { $lbB.Height = $lb.H }
    $lbT = $global:window.FindName("ListBannerTitle")
    if ($lbT) { $lbT.FontSize = $lb.Title }
    $lbS = $global:window.FindName("ListBannerSubtitle")
    if ($lbS) { $lbS.FontSize = $lb.Sub }
    $lbK = $global:window.FindName("ListBannerKicker")
    if ($lbK) { $lbK.FontSize = $lb.Kicker }
    $lbG = $global:window.FindName("ListBannerTitleGrid")
    if ($lbG) { $lbG.Margin = [System.Windows.Thickness]::new(22, $lb.Top, 22, 16) }
    $lbPad = [System.Windows.Thickness]::new($lb.BtnPadX, $lb.BtnPadY, $lb.BtnPadX, $lb.BtnPadY)
    $lbShow = $global:window.FindName("ListBannerShowBtn")
    if ($lbShow) { $lbShow.Padding = $lbPad }
    $lbExp = $global:window.FindName("ListBannerExploreBtn")
    if ($lbExp) { $lbExp.Padding = $lbPad }
    $lbShowTxt = $global:window.FindName("ListBannerShowBtnText")
    if ($lbShowTxt) { $lbShowTxt.FontSize = $lb.BtnFont }
    $lbExpTxt = $global:window.FindName("ListBannerExploreBtnText")
    if ($lbExpTxt) { $lbExpTxt.FontSize = $lb.BtnFont }
    $lbExpArr = $global:window.FindName("ListBannerExploreBtnArrow")
    if ($lbExpArr) { $lbExpArr.FontSize = $lb.BtnFont + 2 }
    # Re-fit the showing banner to the new font size without shuffling
    # the featured game (no-op if the refit helper isn't loaded yet,
    # e.g. during early startup - the sizes above still apply).
    if (Get-Command Refresh-ListBannerSameGame -ErrorAction SilentlyContinue) {
        try { Refresh-ListBannerSameGame } catch { }
    }
}

function global:Set-HeaderFontScale { param($sc)
    # Section-header (Custom Installers MC/GP, External, Recently Played)
    # point sizes per list scale. Pulled out of Apply-Scale so it can run
    # at STARTUP too - otherwise L/M headers keep their XAML default size
    # until the user toggles S/M/L once.
    $hdr = switch ($sc) {
        1.0     { @{ Title = 12; Sub = 10 } }
        1.5     { @{ Title = 14; Sub = 11 } }
        2.0     { @{ Title = 17; Sub = 13 } }
        default { @{ Title = 14; Sub = 11 } }
    }
    if ($global:window) {
        foreach ($n in @("HeaderMCTitle","HeaderGPTitle","HeaderExtTitle","RecentlyPlayedTitle","HeaderMCKind","HeaderGPKind")) {
            $t = $global:window.FindName($n); if ($t) { $t.FontSize = $hdr.Title }
        }
        foreach ($n in @("HeaderMCSub","HeaderGPSub","HeaderExtSub","RecentlyPlayedSub","HeaderExtCount")) {
            $t = $global:window.FindName($n); if ($t) { $t.FontSize = $hdr.Sub }
        }
    }
}

function global:Apply-Scale { param($sc, $activeBtn)
    $global:SCALE = $sc
    # The active-button glow is already set by On-ScaleClick before this
    # runs, so we don't re-set it here.
    # Transform-scale the existing cards instead of rebuilding them.
    Apply-CardScale
    # Recently Played row scales with S/M/L too - rebuild after so its
    # tile size matches the active scale (only a handful of tiles).
    if (Get-Command Build-RecentlyPlayed -ErrorAction SilentlyContinue) {
        Build-RecentlyPlayed
    }
    # Persist the user's choice so it survives a hub restart.
    if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
        Set-HubSetting -Key "scaleList" -Value $sc
    }
    # Scale the three category section headers (Custom Installers
    # MC / GP, External Installers) with the list scale so the whole
    # view grows together, not just the cards. Map the 1.0/1.5/2.0
    # scale factors to sensible header point sizes.
    Set-HeaderFontScale $sc
    # Scale the list-view featured banner (ListBanner) to match.
    Set-ListBannerScale $sc
}

# Per-view size settings - each view (List/Library/Explore/Detail)
# has its own S/M/L choice, persisted to .hub-settings.json so the
# user's preference per area survives restart.
#
# - List view  (old VR-mod list, card tiles): $global:SCALE (1.0/1.5/2.0)
# - Library    (Steam-style portrait list):   $global:LibrarySize  S/M/L
# - Explore    (horizontal genre rows):       $global:ExploreSize  S/M/L
# - Detail     (description page font size):  $global:DetailSize   S/M/L
#
# DiscoverTileSize still exists as a shim that mirrors whichever
# sub-view is currently visible (Library or Explore) so existing
# tile-building code keeps working unchanged.
$global:LibrarySize = "L"
$global:ExploreSize = "M"
$global:DetailSize  = "M"
if (Get-Command Get-HubSetting -ErrorAction SilentlyContinue) {
    $global:LibrarySize = [string](Get-HubSetting -Key "sizeLibrary" -Default "L")
    $global:ExploreSize = [string](Get-HubSetting -Key "sizeExplore" -Default "M")
    $global:DetailSize  = [string](Get-HubSetting -Key "sizeDetail"  -Default "M")
    # List view also gets persisted - keep this in sync with
    # Apply-Scale's Set-HubSetting call above.
    $savedScale = Get-HubSetting -Key "scaleList" -Default 1.0
    if ($savedScale -is [string]) {
        try { $savedScale = [double]$savedScale } catch { $savedScale = 1.0 }
    }
    if ($savedScale -in @(1.0, 1.5, 2.0)) {
        $global:SCALE = $savedScale
    }
}
$global:DiscoverTileSize    = $global:LibrarySize  # initial shim
$global:DiscoverTileSizes   = @{
    "S" = @{ W = 220; H = 330 }
    "M" = @{ W = 250; H = 375 }
    "L" = @{ W = 275; H = 413 }
}

# Overview tile sizes for the horizontal genre rows. Smaller
# than Library since they sit in a packed row, not a grid.
$global:OverviewTileSizes = @{
    "S" = @{ W = 140; H = 210 }
    "M" = @{ W = 175; H = 260 }
    "L" = @{ W = 215; H = 320 }
}

# Detail-view text sizing: maps S/M/L to font size + line height.
# Drives the Steam description AND the README (set-up) body text.
$global:DetailTextSizes = @{
    "S" = @{ Font = 12; LineHeight = 18 }
    "M" = @{ Font = 14; LineHeight = 21 }
    "L" = @{ Font = 16; LineHeight = 24 }
}

# Apply Library size (Steam-style portrait list). Updates the
# live tile widths/heights immediately.
function global:Apply-LibrarySize { param($sizeKey)
    if (-not $global:DiscoverTileSizes.ContainsKey($sizeKey)) { return }
    $global:LibrarySize = $sizeKey
    $global:DiscoverTileSize = $sizeKey  # keep shim in sync
    $dim = $global:DiscoverTileSizes[$sizeKey]
    if ($global:discoverPanel -and $global:DiscoverTilesBuilt) {
        foreach ($tile in $global:discoverPanel.Children) {
            $tile.Width  = $dim.W
            $tile.Height = $dim.H
        }
    }
    # The library featured banner (LibBanner) is XAML with fixed sizes
    # and was the only one of the three banners not tracking S/M/L.
    # Scale it the same gentle way as the List and Explore banners -
    # height, text and layout spacing together - so the whole banner
    # grows with the portrait tiles. S = the XAML defaults (height 140,
    # title 22, sub 11, kicker 10, grid top-margin 16, button pad 14/7,
    # button font 11).
    $lb = switch ($sizeKey) {
        "S"     { @{ H = 140; Title = 22; Sub = 11; Kicker = 10; Top = 16; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
        "M"     { @{ H = 156; Title = 25; Sub = 12; Kicker = 11; Top = 20; BtnFont = 12; BtnPadX = 16; BtnPadY = 8 } }
        "L"     { @{ H = 174; Title = 28; Sub = 13; Kicker = 12; Top = 24; BtnFont = 13; BtnPadX = 18; BtnPadY = 9 } }
        default { @{ H = 140; Title = 22; Sub = 11; Kicker = 10; Top = 16; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
    }
    if ($global:window) {
        $lbB = $global:window.FindName("LibBanner")
        if ($lbB) { $lbB.Height = $lb.H }
        $lbT = $global:window.FindName("LibBannerTitle")
        if ($lbT) { $lbT.FontSize = $lb.Title }
        $lbS = $global:window.FindName("LibBannerSubtitle")
        if ($lbS) { $lbS.FontSize = $lb.Sub }
        $lbK = $global:window.FindName("LibBannerKicker")
        if ($lbK) { $lbK.FontSize = $lb.Kicker }
        $lbG = $global:window.FindName("LibBannerInnerGrid")
        if ($lbG) { $lbG.Margin = [System.Windows.Thickness]::new(22, $lb.Top, 22, 16) }
        $lbPad = [System.Windows.Thickness]::new($lb.BtnPadX, $lb.BtnPadY, $lb.BtnPadX, $lb.BtnPadY)
        $lbShow = $global:window.FindName("LibBannerShowBtn")
        if ($lbShow) { $lbShow.Padding = $lbPad }
        $lbExp = $global:window.FindName("LibBannerExploreBtn")
        if ($lbExp) { $lbExp.Padding = $lbPad }
        $lbShowTxt = $global:window.FindName("LibBannerShowBtnText")
        if ($lbShowTxt) { $lbShowTxt.FontSize = $lb.BtnFont }
        $lbExpTxt = $global:window.FindName("LibBannerExploreBtnText")
        if ($lbExpTxt) { $lbExpTxt.FontSize = $lb.BtnFont }
        $lbExpArr = $global:window.FindName("LibBannerExploreBtnArrow")
        if ($lbExpArr) { $lbExpArr.FontSize = $lb.BtnFont + 2 }
        # Re-fit the showing banner to the new font size without
        # shuffling the featured game.
        if (Get-Command Refresh-LibBannerSameGame -ErrorAction SilentlyContinue) {
            try { Refresh-LibBannerSameGame } catch { }
        }
    }
    if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
        Set-HubSetting -Key "sizeLibrary" -Value $sizeKey
    }
}

# Apply Explore size (horizontal genre rows). Same idea.
function global:Apply-ExploreSize { param($sizeKey)
    if (-not $global:OverviewTileSizes.ContainsKey($sizeKey)) { return }
    $global:ExploreSize = $sizeKey
    $global:DiscoverTileSize = $sizeKey  # keep shim in sync
    $ovDim = $global:OverviewTileSizes[$sizeKey]
    if (-not $ovDim) { return }
    if ($global:OverviewBuilt -and $global:OvGenreRowsPanel) {
        foreach ($row in $global:OvGenreRowsPanel.Children) {
            $tilesPanel = $row.Resources.Item("tilesPanel")
            if ($tilesPanel) {
                foreach ($tile in $tilesPanel.Children) {
                    $tile.Width  = $ovDim.W
                    $tile.Height = $ovDim.H
                }
            }
        }
    }
    if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
        Set-HubSetting -Key "sizeExplore" -Value $sizeKey
    }
    # The featured Explore banner is XAML with fixed sizes, so it
    # doesn't move with the genre tiles on its own. Scale its height,
    # text AND layout spacing together with S/M/L so the whole banner
    # grows as one piece - if only the fonts moved, the genre line
    # would drift toward (S) or away from (L) the buttons, since the
    # title block is top-anchored and the buttons are bottom-anchored.
    # M = the XAML defaults (height 200, title 24, sub 11, kicker 10,
    # grid top-margin 68, button pad 14/7, button font 11).
    $banner = switch ($sizeKey) {
        "S"     { @{ H = 184; Title = 21; Sub = 11;   Kicker = 9;  Top = 62; BtnFont = 11; BtnPadX = 12; BtnPadY = 6 } }
        "M"     { @{ H = 200; Title = 24; Sub = 11;   Kicker = 10; Top = 70; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
        "L"     { @{ H = 224; Title = 27; Sub = 12.5; Kicker = 11; Top = 82; BtnFont = 12; BtnPadX = 16; BtnPadY = 8 } }
        default { @{ H = 200; Title = 24; Sub = 11;   Kicker = 10; Top = 70; BtnFont = 11; BtnPadX = 14; BtnPadY = 7 } }
    }
    if ($global:window) {
        $ob = $global:window.FindName("OvBanner")
        if ($ob) { $ob.Height = $banner.H }
        $obt = $global:window.FindName("OvBannerTitle")
        if ($obt) { $obt.FontSize = $banner.Title }
        $obs = $global:window.FindName("OvBannerSubtitle")
        if ($obs) { $obs.FontSize = $banner.Sub }
        $obk = $global:window.FindName("OvBannerKicker")
        if ($obk) { $obk.FontSize = $banner.Kicker }
        # Title-grid top margin grows with banner height so the title
        # block stays vertically centred between the back button and
        # the action buttons instead of drifting.
        $obg = $global:window.FindName("OvBannerTitleGrid")
        if ($obg) { $obg.Margin = [System.Windows.Thickness]::new(22, $banner.Top, 22, 16) }
        # Action buttons scale with the text so they don't look tiny at
        # L or oversized at S.
        $btnPad = [System.Windows.Thickness]::new($banner.BtnPadX, $banner.BtnPadY, $banner.BtnPadX, $banner.BtnPadY)
        $showBtn = $global:window.FindName("OvBannerShowBtn")
        if ($showBtn) { $showBtn.Padding = $btnPad }
        $shufBtn = $global:window.FindName("OvBannerShuffleBtn")
        if ($shufBtn) { $shufBtn.Padding = $btnPad }
        $showTxt = $global:window.FindName("OvBannerShowBtnText")
        if ($showTxt) { $showTxt.FontSize = $banner.BtnFont }
        $shufTxt = $global:window.FindName("OvBannerShuffleBtnText")
        if ($shufTxt) { $shufTxt.FontSize = $banner.BtnFont }
        # Re-fit the current banner so its title re-truncates against
        # the new font size / width - WITHOUT shuffling to a new game
        # (size change should not change which mod is featured).
        if ($global:OverviewBuilt -and (Get-Command Refresh-OvBannerSameGame -ErrorAction SilentlyContinue)) {
            try { Refresh-OvBannerSameGame } catch { }
        }
    }
    # Genre + power filter buttons scale with Explore S/M/L too. They're
    # cheap (a dozen chips) so rebuild them at the new size, then restore
    # the active genre/power selection that the rebuild reset to ALL.
    if ($global:OverviewBuilt) {
        if (Get-Command Build-OvGenreFilter -ErrorAction SilentlyContinue) {
            Build-OvGenreFilter
            if ($global:OvGenreFilterPanel -and (Get-Command Update-OvFilterChips -ErrorAction SilentlyContinue)) {
                $gk = if ($global:OvActiveGenre) { $global:OvActiveGenre } else { "ALL" }
                Update-OvFilterChips -ChipPanel $global:OvGenreFilterPanel -ActiveKey $gk
            }
        }
        if (Get-Command Build-OvPowerFilter -ErrorAction SilentlyContinue) {
            Build-OvPowerFilter
            if ($global:OvPowerFilterPanel -and (Get-Command Update-OvFilterChips -ErrorAction SilentlyContinue)) {
                $pk = if ($global:OvActivePower) { $global:OvActivePower } else { "ALL" }
                Update-OvFilterChips -ChipPanel $global:OvPowerFilterPanel -ActiveKey $pk
            }
        }
        if (Get-Command Apply-OvPowerModeToggleStyle -ErrorAction SilentlyContinue) {
            Apply-OvPowerModeToggleStyle
        }
    }
}
function global:Apply-DetailSize { param($sizeKey)
    if (-not $global:DetailTextSizes.ContainsKey($sizeKey)) { return }
    $global:DetailSize = $sizeKey
    $cfg = $global:DetailTextSizes[$sizeKey]
    if ($global:DetailDescTxt) {
        $global:DetailDescTxt.FontSize   = $cfg.Font
        $global:DetailDescTxt.LineHeight = $cfg.LineHeight
    }
    if ($global:DetailReadmeTextBlocks) {
        foreach ($tb in $global:DetailReadmeTextBlocks) {
            if ($tb) {
                if ($tb.Tag -eq "heading") {
                    # Section headings sit one point above body and
                    # scale together with it.
                    $tb.FontSize = [int]$cfg.Font + 1
                } else {
                    $tb.FontSize   = $cfg.Font
                    $tb.LineHeight = $cfg.LineHeight
                }
                # Button pills are InlineUIContainers embedded in the
                # text runs. Their Border/TextBlock have fixed pixel
                # sizes set at render time, so a plain FontSize bump on
                # the parent TextBlock leaves them behind. Walk the
                # inlines, find the pill containers, and rescale their
                # geometry from the new body font using the SAME ratios
                # the renderer uses (base*0.75 font, *1.214 height, etc.)
                # so a live S/M/L toggle keeps pills matched to the text.
                try {
                    $pillBase = if ($tb.Tag -eq "heading") { [int]$cfg.Font + 1 } else { $cfg.Font }
                    foreach ($inl in @($tb.Inlines)) {
                        if ($inl -is [System.Windows.Documents.InlineUIContainer]) {
                            $brd = $inl.Child
                            if ($brd -is [System.Windows.Controls.Border]) {
                                $brd.Height       = [int][math]::Round($pillBase * 1.214)
                                $padX             = [int][math]::Round($pillBase * 0.43)
                                $brd.Padding      = [System.Windows.Thickness]::new($padX, 1, $padX, 1)
                                $brd.CornerRadius = [System.Windows.CornerRadius]::new([math]::Round($pillBase * 0.571, 1))
                                $inner = $brd.Child
                                if ($inner -is [System.Windows.Controls.TextBlock]) {
                                    $inner.FontSize   = [math]::Round($pillBase * 0.75, 1)
                                    $inner.LineHeight = [int][math]::Round($pillBase * 0.929)
                                }
                            }
                        }
                    }
                } catch { }
            }
        }
    }
    if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
        Set-HubSetting -Key "sizeDetail" -Value $sizeKey
    }
}

# Compatibility shim: callers using the old function name still
# work (they target Library by default since that was the old
# discover view).
function global:Apply-DiscoverTileSize { param($sizeKey)
    Apply-LibrarySize $sizeKey
}

# Identify which of the four views is currently visible so the
# S/M/L click + sync routes to the right setting.
function global:Get-CurrentView {
    if ($global:discoverHost -and $global:discoverHost.Visibility -eq [System.Windows.Visibility]::Visible) {
        if ($global:discoverDetail -and $global:discoverDetail.Visibility -eq [System.Windows.Visibility]::Visible) {
            return "Detail"
        }
        if ($global:discoverOverview -and $global:discoverOverview.Visibility -eq [System.Windows.Visibility]::Visible) {
            return "Explore"
        }
        return "Library"
    }
    return "List"
}

# Sync the S/M/L button state to whatever the *active* mode's
# size currently is. Called on mode switches so the active
# button reflects reality.
function global:Sync-ScaleButtonsToMode {
    # When discoverHost isn't built yet (very early in startup),
    # treat as List view - Get-CurrentView would otherwise return
    # "List" by default but the early bail-out used to skip the
    # whole function, which left the S button un-highlighted on
    # startup if the user had S saved. M/L still worked because
    # Apply-Scale highlighted them directly on rebuild.
    $view = if ($global:discoverHost) { Get-CurrentView } else { "List" }
    $key = switch ($view) {
        "Detail"  { $global:DetailSize }
        "Explore" { $global:ExploreSize }
        "Library" { $global:LibrarySize }
        default {
            switch ($global:SCALE) {
                1.0 { "S" }
                1.5 { "M" }
                2.0 { "L" }
                default { "S" }
            }
        }
    }
    switch ($key) {
        "S" { Set-ScaleActive $scaleSBtn }
        "M" { Set-ScaleActive $scaleMBtn }
        "L" { Set-ScaleActive $scaleLBtn }
        default { Set-ScaleActive $scaleSBtn }
    }
}

# Per-view S/M/L click: routes to whichever Apply-* corresponds to
# the visible view, so each view keeps its own independent size.
function global:On-ScaleClick { param($listScale, $discoverSize, $activeBtn)
    # Set the active-button glow FIRST so the user gets instant visual
    # confirmation of their click. The card rebuild below can take ~2s
    # for the full list at a new size; if we ran it inline the UI thread
    # would be blocked and the glow would only paint AFTER the rebuild
    # finished (looking like the button didn't respond). So we set the
    # glow, then defer the heavy work by one dispatcher cycle at
    # Background priority - the glow paints immediately, the rebuild
    # runs right after.
    Set-ScaleActive $activeBtn
    $view = Get-CurrentView
    $doResize = {
        switch ($view) {
            "Detail"  { Apply-DetailSize  $discoverSize }
            "Explore" { Apply-ExploreSize $discoverSize }
            "Library" { Apply-LibrarySize $discoverSize }
            default   { Apply-Scale $listScale $activeBtn }
        }
    }.GetNewClosure()
    if ($global:window) {
        $global:window.Dispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [action]$doResize
        ) | Out-Null
    } else {
        & $doResize
    }
}

# Apply persisted sizes to whatever's already built on startup,
# so the user's saved preferences are reflected from frame 1.
# Apply-LibrarySize runs unconditionally: its tile loop is self-
# guarded (only resizes tiles once built), but the featured banner
# must be scaled to the saved size right away - otherwise it shows
# at the XAML default until the user toggles S/M/L once.
Apply-LibrarySize $global:LibrarySize
if ($global:OverviewBuilt)      { Apply-ExploreSize $global:ExploreSize }
# List cards are built at base size above; apply the saved S/M/L
# scale via LayoutTransform (instant, no rebuild) and highlight the
# matching button.
Apply-CardScale
# Scale the list banner to the saved size too - Apply-CardScale only
# handles the cards, so without this the banner stays at the XAML
# default until the user toggles S/M/L once.
Set-ListBannerScale $global:SCALE
if ($global:SCALE -ne 1.0) {
    $initialScaleBtn = switch ($global:SCALE) {
        1.5 { $scaleMBtn }
        2.0 { $scaleLBtn }
        default { $scaleSBtn }
    }
    Set-ScaleActive $initialScaleBtn
}

Sync-ScaleButtonsToMode
if (Get-Command Set-HeaderFontScale -ErrorAction SilentlyContinue) { Set-HeaderFontScale $global:SCALE }
if (Get-Command Restore-FilterPills -ErrorAction SilentlyContinue) { Restore-FilterPills }
$scaleSBtn.Add_PreviewMouseLeftButtonDown({ On-ScaleClick 1.0 "S" $scaleSBtn }.GetNewClosure())
$scaleMBtn.Add_PreviewMouseLeftButtonDown({ On-ScaleClick 1.5 "M" $scaleMBtn }.GetNewClosure())
$scaleLBtn.Add_PreviewMouseLeftButtonDown({ On-ScaleClick 2.0 "L" $scaleLBtn }.GetNewClosure())

# ---------------------------------------------------------------
# Recently Played - small tile row sitting between the Featured
# banner and the Custom Installers section in the Library list.
# Test version: shows the first 5 currently-installed VR games.
# Once we wire start-tracking into Start-GameInVR, this will be
# replaced by the actual play-history (most-recent-first), still
# capped at 5 tiles.
# ---------------------------------------------------------------
$recentSection      = $window.FindName("RecentlyPlayedSection")
$recentList         = $window.FindName("RecentlyPlayedList")
$recentHeader       = $window.FindName("RecentlyPlayedHeader")
$recentHeaderHost   = $window.FindName("RecentlyPlayedHeaderHost")
$recentCloseOverlay = $window.FindName("RecentlyPlayedCloseOverlay")
$recentCloseBtn     = $window.FindName("RecentlyPlayedCloseBtn")
$recentDisableBtn   = $window.FindName("RecentlyPlayedDisableBtn")

function global:Build-RecentlyPlayed {
    if (-not $recentList) { return }

    # Toggle: user dismissed the section permanently via the
    # hover-overlay's "Always disable" button. Setting persists
    # across sessions.
    $hidden = [bool](Get-HubSetting -Key "recentlyPlayedHidden" -Default $false)
    if ($hidden) {
        $recentList.Children.Clear()
        $script:recentBuiltSig = $null
        if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Collapsed }
        return
    }

    # Pick the 5 most recently launched games from play history.
    # If the user hasn't launched anything yet, the section stays
    # hidden - that matches the header's "Click to launch in VR -
    # last 5 games shown" promise. Showing test entries before any
    # launch would mislead the user into thinking they had played
    # games they hadn't.
    $candidates = @()
    try {
        $history = Get-HubSetting -Key "playHistory" -Default @()
        if ($history -and $history.Count -gt 0) {
            $byTitle = @{}
            foreach ($g in @($ownGames + $ownGamesGP + $externalGames)) {
                if ($g.Title) { $byTitle[$g.Title] = $g }
            }
            foreach ($title in $history) {
                if ($candidates.Count -ge 5) { break }
                if ($byTitle.ContainsKey($title)) {
                    $candidates += $byTitle[$title]
                }
            }
        }
    } catch { }

    if ($candidates.Count -eq 0) {
        $recentList.Children.Clear()
        $script:recentBuiltSig = $null
        if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Collapsed }
        return
    }

    # Idempotency guard: Check Installed / Check on Startup calls
    # Build-RecentlyPlayed after every scan to "keep the row in
    # sync", but the row's contents only depend on playHistory +
    # the candidate titles - the scan doesn't change either. Wiping
    # and rebuilding the tiles when nothing has changed makes the
    # portrait images flicker. So we cache a signature of the last
    # built tile order and bail out early if it matches.
    $sig = (($candidates | ForEach-Object { $_.Title }) -join "`n") + "|scale=$($global:SCALE)"
    if ($script:recentBuiltSig -eq $sig -and $recentList.Children.Count -gt 0) {
        # Already rendering the same tiles. Just ensure visibility
        # state is correct in case it was collapsed/hidden before.
        if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Visible }
        $collapsed = [bool](Get-HubSetting -Key "recentlyPlayedCollapsed" -Default $false)
        if ($recentList) {
            $recentList.Visibility = if ($collapsed) {
                [System.Windows.Visibility]::Collapsed
            } else {
                [System.Windows.Visibility]::Visible
            }
        }
        return
    }
    # Signature differs (or first build) - do a full rebuild.
    $recentList.Children.Clear()
    $script:recentBuiltSig = $sig

    # Tile size scales with the active SCALE so S/M/L acts on this
    # row too. Base 90x128 at SCALE 1.0 - that's a comfortable
    # hand-sized tile that stays out of the way of the main list.
    # Base bumped +1/5 over the original 90x128 so even S reads a bit
    # larger; M and L then grow +1/3 per step on top of this base.
    $baseW = 108
    $baseH = 154
    $sc = $global:SCALE
    if (-not $sc) { $sc = 1.0 }
    # Recently Played tiles grow gently: +1/3 per step (S -> M -> L),
    # not the full list scale, so the row stays compact.
    $rpFactor = switch ($sc) {
        1.5     { 4.0 / 3.0 }                    # M: +1/3 over S
        2.0     { (4.0 / 3.0) * (4.0 / 3.0) }    # L: +1/3 over M
        default { 1.0 }                          # S
    }
    $tileW = [int]($baseW * $rpFactor)
    $tileH = [int]($baseH * $rpFactor)

    foreach ($g in $candidates) {
        $tile = New-Object System.Windows.Controls.Border
        $tile.Width  = $tileW
        $tile.Height = $tileH
        $tile.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $tile.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
        $tile.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1a1a22")
        $tile.BorderThickness = [System.Windows.Thickness]::new(1)
        $tile.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
        $tile.Cursor = [System.Windows.Input.Cursors]::Hand
        $tile.ClipToBounds = $true

        $tileGrid = New-Object System.Windows.Controls.Grid

        # Portrait artwork - use Steam library_600x900 if SteamId
        # is set, custom Asset image otherwise. Fallback to dark
        # background if neither resolves.
        # IMPORTANT: load asynchronously (no OnLoad cache option) so
        # 5x Steam-CDN HTTPS downloads do not block Hub startup. The
        # tile shows its dark background immediately and the portrait
        # fades in when WPF finishes streaming it. CacheOption.OnLoad
        # would force a synchronous download on the UI thread and
        # roughly double startup time when the Recently Played row
        # is visible.
        $portraitUrl = Get-GameImageUrl -Game $g -Kind "portrait"
        if ($portraitUrl) {
            try {
                $img = New-Object System.Windows.Controls.Image
                $img.Stretch = [System.Windows.Media.Stretch]::UniformToFill
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit()
                $bmp.UriSource = ([System.Uri]$portraitUrl)
                $bmp.CreateOptions = [System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreImageCache
                # No CacheOption -> default streams asynchronously.
                $bmp.EndInit()
                $img.Source = $bmp
                $tileGrid.Children.Add($img) | Out-Null
            } catch { }
        }

        # Bottom gradient overlay for title legibility.
        $titleBg = New-Object System.Windows.Shapes.Rectangle
        $titleBg.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
        $titleBg.Height = 36
        $gradStops = New-Object System.Windows.Media.GradientStopCollection
        $gradStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,0,0,0), 0))) | Out-Null
        $gradStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(220,0,0,0), 1))) | Out-Null
        $titleBg.Fill = New-Object System.Windows.Media.LinearGradientBrush $gradStops, ([System.Windows.Point]::new(0,0)), ([System.Windows.Point]::new(0,1))
        $tileGrid.Children.Add($titleBg) | Out-Null

        # Title text (truncated with ellipsis if too long).
        $titleTxt = New-Object System.Windows.Controls.TextBlock
        $titleTxt.Text = $g.Title
        $titleTxt.FontSize = [Math]::Max(9, [int](9 * $sc))
        $titleTxt.FontWeight = [System.Windows.FontWeights]::SemiBold
        $titleTxt.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $titleTxt.Foreground = [System.Windows.Media.Brushes]::White
        $titleTxt.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis
        $titleTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
        $titleTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $titleTxt.TextAlignment = [System.Windows.TextAlignment]::Center
        $titleTxt.Margin = [System.Windows.Thickness]::new(4, 0, 4, 6)
        $tileGrid.Children.Add($titleTxt) | Out-Null

        $tile.Child = $tileGrid

        # Hover: subtle accent border lift (matches the Library
        # card hover idiom but in a more compact way).
        $accent = if ($g.Accent) { $g.Accent } else { "#666677" }
        $tile.Add_MouseEnter({
            $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accent)
        }.GetNewClosure())
        $tile.Add_MouseLeave({
            $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a35")
        }.GetNewClosure())

        # Click - direct Start-GameInVR per Martin's spec. No
        # detail-view detour: the tile is a one-tap launcher.
        $gameRef = $g
        $tile.Add_PreviewMouseLeftButtonDown({
            Start-GameInVR -Game $gameRef
        }.GetNewClosure())

        $recentList.Children.Add($tile) | Out-Null
    }

    if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Visible }

    # Honor a persisted collapsed-state. The Hide link (right side
    # of the header) handles "permanently hide the whole section";
    # the header-click toggles just the tile list. Both states
    # survive Hub restarts via .hub-settings.json.
    $collapsed = [bool](Get-HubSetting -Key "recentlyPlayedCollapsed" -Default $false)
    if ($recentList) {
        $recentList.Visibility = if ($collapsed) {
            [System.Windows.Visibility]::Collapsed
        } else {
            [System.Windows.Visibility]::Visible
        }
    }
}

if ($recentSection -and $recentHeaderHost -and $recentCloseOverlay -and $recentCloseBtn -and $recentDisableBtn) {
    # Hover-overlay pattern matching the featured banner: 5 seconds
    # of hover on the header reveals Close + Always disable. Close
    # hides this session only; Always disable persists to
    # .hub-settings.json so the section stays gone on restart.
    # Hover target is the header host only (not the tile list) so
    # users can still mouse-over tiles to launch without triggering
    # the overlay.

    # 5-second show timer on hover, 800ms hide timer on leave.
    $rpShowTimer = New-Object System.Windows.Threading.DispatcherTimer
    $rpShowTimer.Interval = [TimeSpan]::FromSeconds(5)
    $rpHideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $rpHideTimer.Interval = [TimeSpan]::FromMilliseconds(800)

    $rpShowTimer.Add_Tick({
        $rpShowTimer.Stop()
        $recentCloseOverlay.Visibility = [System.Windows.Visibility]::Visible
    }.GetNewClosure())
    $rpHideTimer.Add_Tick({
        $rpHideTimer.Stop()
        $recentCloseOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    }.GetNewClosure())

    $recentHeaderHost.Add_MouseEnter({
        $rpHideTimer.Stop()
        if ($recentCloseOverlay.Visibility -ne [System.Windows.Visibility]::Visible) {
            $rpShowTimer.Stop()
            $rpShowTimer.Start()
        }
    }.GetNewClosure())
    $recentHeaderHost.Add_MouseLeave({
        $rpShowTimer.Stop()
        if ($recentCloseOverlay.Visibility -eq [System.Windows.Visibility]::Visible) {
            $rpHideTimer.Stop()
            $rpHideTimer.Start()
        }
    }.GetNewClosure())

    # Close = hide the section for this session (no persist).
    $recentCloseBtn.Add_MouseLeftButtonUp({
        if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Collapsed }
    }.GetNewClosure())
    $recentCloseBtn.Add_MouseEnter({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") })
    $recentCloseBtn.Add_MouseLeave({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48") })

    # Always disable = hide + persist.
    $recentDisableBtn.Add_MouseLeftButtonUp({
        if ($recentSection) { $recentSection.Visibility = [System.Windows.Visibility]::Collapsed }
        if (Get-Command Set-HubSetting -ErrorAction SilentlyContinue) {
            Set-HubSetting -Key "recentlyPlayedHidden" -Value $true
        }
    }.GetNewClosure())
    $recentDisableBtn.Add_MouseEnter({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600") })
    $recentDisableBtn.Add_MouseLeave({ $this.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3a3a48") })
}

if ($recentHeader) {
    # Click-toggle: collapse the tile list. Same idiom as the
    # Custom Installers / Game Pass / Custom Setups headers.
    # Distinct from the hover-overlay (Close / Always disable) -
    # that one hides the whole section; this one just folds the
    # tile list up and the user can unfold it again.
    $recentHeader.Add_PreviewMouseLeftButtonDown({
        if (-not $recentList) { return }
        $vis = if ($recentList.Visibility -eq [System.Windows.Visibility]::Visible) {
            [System.Windows.Visibility]::Collapsed
        } else {
            [System.Windows.Visibility]::Visible
        }
        $recentList.Visibility = $vis
        Set-HubSetting -Key "recentlyPlayedCollapsed" -Value ($vis -eq [System.Windows.Visibility]::Collapsed)
    })
}

# Search
$searchBox   = $window.FindName("SearchBox")
# Help & Feedback menu - rendered as an in-window overlay (MenuOverlay in the
# root Grid), NOT a Popup. A Popup delivered each click to BOTH itself and the
# content behind it (the banner). The overlay keeps everything in one visual
# tree: the scrim swallows outside clicks, and the menu lives in a different
# branch than the banner/cards, so a menu click can never route to them. All
# three items are wired: Suggest and Report open GitHub issue forms, Discord
# opens the invite.
$global:menuBtn     = $window.FindName("MenuBtn")
$global:menuDots    = $window.FindName("MenuDots")
$global:menuOverlay = $window.FindName("MenuOverlay")
$global:menuScrim   = $window.FindName("MenuScrim")

# Shared brushes (one instance reused across handlers - fine in WPF).
$bc = [System.Windows.Media.BrushConverter]::new()
$global:brBtnRest   = $bc.ConvertFromString("#16161a")
$global:brBtnBorder = $bc.ConvertFromString("#3a3a48")
$global:brBlue      = $bc.ConvertFromString("#3a8add")
$global:brDotRest   = $bc.ConvertFromString("#aaaaaa")
$global:brWhite     = [System.Windows.Media.Brushes]::White

# "Active" look = blue border + white dots. Used for both hover and open.
function global:Set-MenuBtnActive {
    param([bool]$Active)
    $global:menuBtn.BorderBrush = if ($Active) { $global:brBlue } else { $global:brBtnBorder }
    foreach ($d in $global:menuDots.Children) {
        $d.Fill = if ($Active) { $global:brWhite } else { $global:brDotRest }
    }
}
function global:Test-HubMenuOpen {
    return ($global:menuOverlay.Visibility -eq [System.Windows.Visibility]::Visible)
}
function global:Open-HubMenu {
    $global:menuOverlay.Visibility = [System.Windows.Visibility]::Visible
    $global:menuBtn.Background = $global:brBtnRest
    Set-MenuBtnActive -Active $true
}
function global:Close-HubMenu {
    $global:menuOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    $global:menuBtn.Background = $global:brBtnRest
    Set-MenuBtnActive -Active ($global:menuBtn.IsMouseOver)
}

# Trigger hover: dots white + border blue. Leave falls back to the open state.
$global:menuBtn.Add_MouseEnter({ Set-MenuBtnActive -Active $true })
$global:menuBtn.Add_MouseLeave({ Set-MenuBtnActive -Active (Test-HubMenuOpen) })
# Click the trigger: toggle the overlay. Handled so nothing else reacts.
$global:menuBtn.Add_PreviewMouseLeftButtonDown({ param($s, $e)
    $e.Handled = $true
    if (Test-HubMenuOpen) { Close-HubMenu } else { Open-HubMenu }
    # Click FX: a quick brightness pulse that fades back to the rest colour.
    # Its own animated brush (so it doesn't disturb the shared rest brush) and
    # an animation that repaints itself - no reliance on a mouse-up, which the
    # open menu's scrim would otherwise swallow.
    $pulse = New-Object System.Windows.Media.SolidColorBrush (
        [System.Windows.Media.Color][System.Windows.Media.ColorConverter]::ConvertFromString("#16161a"))
    $this.Background = $pulse
    $anim = New-Object System.Windows.Media.Animation.ColorAnimation
    $anim.From     = [System.Windows.Media.Color][System.Windows.Media.ColorConverter]::ConvertFromString("#3a3a52")
    $anim.To       = [System.Windows.Media.Color][System.Windows.Media.ColorConverter]::ConvertFromString("#16161a")
    $anim.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(220))
    $pulse.BeginAnimation([System.Windows.Media.SolidColorBrush]::ColorProperty, $anim)
})

# Scrim: any click outside the menu closes it and goes nowhere else.
$global:menuScrim.Add_MouseLeftButtonDown({ param($s, $e)
    $e.Handled = $true
    Close-HubMenu
})
# Scrolling dismisses the menu too.
$global:menuOverlay.Add_PreviewMouseWheel({ param($s, $e) Close-HubMenu })

# Menu item hover (shared look). MouseLeave always restores Transparent.
$menuItemEnter = { $this.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1e1e2a") }
$menuItemLeave = { $this.Background = [System.Windows.Media.Brushes]::Transparent }

$miSuggest = $window.FindName("MiSuggest")
$miReport  = $window.FindName("MiReport")
$miDiscord = $window.FindName("MiDiscord")

$miSuggest.Add_MouseEnter($menuItemEnter); $miSuggest.Add_MouseLeave($menuItemLeave)
$miReport.Add_MouseEnter($menuItemEnter);  $miReport.Add_MouseLeave($menuItemLeave)
$miDiscord.Add_MouseEnter($menuItemEnter); $miDiscord.Add_MouseLeave($menuItemLeave)

# Item click: mark handled, then close, then run the action.
$miSuggest.Add_MouseLeftButtonUp({ param($s, $e)
    $e.Handled = $true
    Close-HubMenu
    # Opens the GitHub "VR mod suggestion" issue form. Renders as a form
    # once the issue templates are committed to the repo.
    Start-Process "https://github.com/Mr-Nlce/PCVR-Mods-Installer-Hub/issues/new?template=mod-suggestion.yml"
})
$miReport.Add_MouseLeftButtonUp({ param($s, $e)
    $e.Handled = $true
    Close-HubMenu
    # Open the Logs folder with the newest log preselected, so the user can
    # drag it straight into the bug report that opens next.
    try {
        $logsDir = Join-Path $global:scriptDir "Logs"
        if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
        $newest = Get-ChildItem $logsDir -Filter *.log -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($newest) { Start-Process explorer.exe "/select,`"$($newest.FullName)`"" }
        else         { Start-Process explorer.exe $logsDir }
    } catch {}
    # Opens the GitHub bug-report issue form. Renders as a form once the
    # issue templates are committed to the repo.
    Start-Process "https://github.com/Mr-Nlce/PCVR-Mods-Installer-Hub/issues/new?template=bug-report.yml"
})
# Discord keeps the existing, already-verified invite.
$miDiscord.Add_MouseLeftButtonUp({ param($s, $e)
    $e.Handled = $true
    Close-HubMenu
    Start-Process "https://discord.gg/uAeQkYBM4n"
})

# Switch Hub Style: flip frosted <-> classic tiles (persisted) and
# rebuild the card lists. Same hover treatment as the other items.
$miStyle = $window.FindName("MiStyle")
if ($miStyle) {
    $miStyle.Add_MouseEnter($menuItemEnter); $miStyle.Add_MouseLeave($menuItemLeave)
    $miStyle.Add_MouseLeftButtonUp({ param($s, $e)
        $e.Handled = $true
        Close-HubMenu
        if (Get-Command Switch-HubStyle -ErrorAction SilentlyContinue) { Switch-HubStyle }
    })
}

# Clicking the header VR-glasses glyph also flips the tile style
# (tooltip "Switch style" set in XAML). Same action as the menu item.
if ($headerVrIcon) {
    $headerVrIcon.Add_MouseLeftButtonUp({ param($s, $e)
        $e.Handled = $true
        if (Get-Command Switch-HubStyle -ErrorAction SilentlyContinue) { Switch-HubStyle }
    })
}

