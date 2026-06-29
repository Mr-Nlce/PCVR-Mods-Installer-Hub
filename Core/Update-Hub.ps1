# ============================================================
#  PCVR Mods Installer Hub - Auto Updater
#  Called by Start PCVR Mods Hub.bat before launching the GUI.
#  Checks GitHub for a newer release, downloads + extracts if found.
# ============================================================

param(
    [switch]$Silent,         # Silent background check (no UI)
    [switch]$FromTemp        # Internal: indicates we're running from %TEMP% copy
)

# -------------------------------------------------------
#  CONFIG - set your GitHub repo here
# -------------------------------------------------------
$GITHUB_USER    = "Mr-Nlce"
$GITHUB_REPO    = "PCVR-Mods-Installer-Hub"
$API_URL        = "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/releases/latest"

# When running from temp, $PSScriptRoot points to %TEMP%, so we need
# the original install dir passed via env var.
if ($FromTemp -and $env:PCVR_HUB_INSTALL_DIR) {
    $installCoreDir = Join-Path $env:PCVR_HUB_INSTALL_DIR "Core"
    $rootDir        = $env:PCVR_HUB_INSTALL_DIR
} else {
    $installCoreDir = $PSScriptRoot
    $rootDir        = Split-Path -Parent $PSScriptRoot
}
$CURRENT_VERSION_FILE = Join-Path $installCoreDir "version.txt"

# -------------------------------------------------------
#  Read current local version
# -------------------------------------------------------
$currentVersion = "0.0.0"
if (Test-Path $CURRENT_VERSION_FILE) {
    $currentVersion = (Get-Content $CURRENT_VERSION_FILE -Raw).Trim()
}

# -------------------------------------------------------
#  Helper: compare semantic versions
# -------------------------------------------------------
function Compare-SemVer {
    param([string]$a, [string]$b)
    # Returns  1 if $b > $a, 0 if equal, -1 if $a > $b
    $pa = $a.TrimStart("v") -split "\." | ForEach-Object { [int]$_ }
    $pb = $b.TrimStart("v") -split "\." | ForEach-Object { [int]$_ }
    $len = [Math]::Max($pa.Count, $pb.Count)
    for ($i = 0; $i -lt $len; $i++) {
        $va = if ($i -lt $pa.Count) { $pa[$i] } else { 0 }
        $vb = if ($i -lt $pb.Count) { $pb[$i] } else { 0 }
        if ($vb -gt $va) { return 1 }
        if ($va -gt $vb) { return -1 }
    }
    return 0
}

# -------------------------------------------------------
#  Check GitHub for latest release
# -------------------------------------------------------
try {
    # TLS 1.2 for older Win10/PS 5.1
    [System.Net.ServicePointManager]::SecurityProtocol = `
        [System.Net.ServicePointManager]::SecurityProtocol -bor `
        [System.Net.SecurityProtocolType]::Tls12

    $response = Invoke-RestMethod -Uri $API_URL `
        -Headers @{ "User-Agent" = "PCVR-Mods-Hub-Updater" } `
        -TimeoutSec 8 `
        -ErrorAction Stop

    $latestVersion  = $response.tag_name          # e.g. "v0.1.1"
    $releaseNotes   = $response.body
    $releaseUrl     = $response.html_url

    $zipAsset    = $response.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
    $downloadUrl = if ($zipAsset) { $zipAsset.browser_download_url } else { $null }
}
catch {
    if (-not $Silent) {
        Write-Host "[Updater] Could not reach GitHub: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
    exit 0
}

# -------------------------------------------------------
#  Compare versions
# -------------------------------------------------------
$cmp = Compare-SemVer $currentVersion $latestVersion
if ($cmp -le 0) {
    if (-not $Silent) {
        Write-Host "[Updater] Already up to date ($currentVersion)." -ForegroundColor DarkGray
    }
    # Clean up stale update marker
    $stale = Join-Path $installCoreDir ".update_available"
    if (Test-Path $stale) { Remove-Item $stale -Force -ErrorAction SilentlyContinue }
    exit 0
}

# -------------------------------------------------------
#  Update available - write info file for the GUI to read
# -------------------------------------------------------
$updateInfoFile = Join-Path $installCoreDir ".update_available"
@{
    LatestVersion  = $latestVersion
    CurrentVersion = $currentVersion
    ReleaseUrl     = $releaseUrl
    DownloadUrl    = $downloadUrl
    ReleaseNotes   = ($releaseNotes -split "`n" | Select-Object -First 5) -join "`n"
} | ConvertTo-Json | Set-Content $updateInfoFile -Encoding UTF8

if ($Silent) {
    # GUI will pick up the info file and show the banner
    exit 0
}

# -------------------------------------------------------
#  Interactive mode: if we're NOT already running from temp,
#  re-launch ourselves from %TEMP% so we can overwrite
#  Update-Hub.ps1 safely during the install step.
# -------------------------------------------------------
if (-not $FromTemp) {
    $tempUpdater = Join-Path $env:TEMP "PCVRModsHub-Updater.ps1"
    Copy-Item -Path $PSCommandPath -Destination $tempUpdater -Force
    $env:PCVR_HUB_INSTALL_DIR = $rootDir
    Start-Process "powershell.exe" -ArgumentList `
        "-NoProfile", "-ExecutionPolicy", "Bypass", `
        "-File", "`"$tempUpdater`"", "-FromTemp"
    exit 0
}

# -------------------------------------------------------
#  Interactive mode (running from %TEMP%): show WPF dialog
# -------------------------------------------------------
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$dialogXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="PCVR Mods Hub - Update Available"
    Width="460" Height="320"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    Background="#0d0d0f">
    <Grid Margin="28">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,6">
            <TextBlock Text="Update Available " FontSize="17" FontWeight="Bold"
                       Foreground="White" FontFamily="Segoe UI"/>
            <Border Background="#1e3a1e" CornerRadius="4" Padding="7,2" VerticalAlignment="Center">
                <TextBlock x:Name="NewVersionLabel" FontSize="12" Foreground="#66cc66"
                           FontFamily="Segoe UI"/>
            </Border>
        </StackPanel>

        <TextBlock Grid.Row="1" x:Name="CurrentVersionLabel"
                   FontSize="11" Foreground="#555568" FontFamily="Segoe UI"
                   Margin="0,0,0,14"/>

        <Border Grid.Row="2" Background="#16161a" CornerRadius="6" Padding="12">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="NotesLabel" FontSize="11" Foreground="#aaaaaa"
                           FontFamily="Segoe UI" TextWrapping="Wrap"/>
            </ScrollViewer>
        </Border>

        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,14,0,0">
            <Border x:Name="SkipBtn" Background="#16161a" CornerRadius="6"
                    Padding="18,8" Margin="0,0,10,0" Cursor="Hand">
                <TextBlock Text="Skip" FontSize="12" Foreground="#777788"
                           FontFamily="Segoe UI"/>
            </Border>
            <Border x:Name="UpdateBtn" Background="#1e3a1e" CornerRadius="6"
                    Padding="18,8" Cursor="Hand">
                <TextBlock Text="Download &amp; Update" FontSize="12"
                           Foreground="#66cc66" FontWeight="SemiBold"
                           FontFamily="Segoe UI"/>
            </Border>
        </StackPanel>
    </Grid>
</Window>
"@

$reader  = [System.Xml.XmlReader]::Create([System.IO.StringReader]$dialogXaml)
$dlgWin  = [Windows.Markup.XamlReader]::Load($reader)

# Draw the same VR goggles icon used by the main Hub window, so the
# title bar and taskbar show our brand glyph instead of the default
# PowerShell icon. The .ico file looks too small at title-bar size;
# this programmatic 32x32 bitmap stays crisp and recognisable.
try {
    $iconSize = 32
    $iconCanvas = New-Object System.Windows.Controls.Canvas
    $iconCanvas.Width  = $iconSize
    $iconCanvas.Height = $iconSize
    $iconCanvas.Background = [System.Windows.Media.Brushes]::Transparent

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
    $dlgWin.Icon = $rtb
} catch { }

$dlgWin.FindName("NewVersionLabel").Text     = $latestVersion
$dlgWin.FindName("CurrentVersionLabel").Text = "You have $currentVersion installed"
$shortNotes = ($releaseNotes -split "`n" | Select-Object -First 14) -join "`n"
$dlgWin.FindName("NotesLabel").Text = if ($shortNotes) { $shortNotes } else { "No release notes provided." }

$script:doUpdate = $false

$dlgWin.FindName("SkipBtn").Add_MouseLeftButtonUp({ $dlgWin.Close() })
$dlgWin.FindName("UpdateBtn").Add_MouseEnter({
    $dlgWin.FindName("UpdateBtn").Background =
        [System.Windows.Media.BrushConverter]::new().ConvertFromString("#265226")
})
$dlgWin.FindName("UpdateBtn").Add_MouseLeave({
    $dlgWin.FindName("UpdateBtn").Background =
        [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1e3a1e")
})
$dlgWin.FindName("UpdateBtn").Add_MouseLeftButtonUp({
    $script:doUpdate = $true
    $dlgWin.Close()
})

$dlgWin.ShowDialog() | Out-Null

if (-not $script:doUpdate -or -not $downloadUrl) {
    exit 0
}

# -------------------------------------------------------
#  Perform the update
# -------------------------------------------------------
$tempZip     = Join-Path $env:TEMP "PCVRModsHub_update.zip"
$tempExtract = Join-Path $env:TEMP "PCVRModsHub_update_extract"
$installDir  = $rootDir
# Marks the point of no return: once the new files are in place and the new
# version is written, the update has SUCCEEDED. Anything after that (relaunch)
# must never surface as "Update failed".
$updateDone  = $false

# Relaunch helper - reused by both the success path and the failure-recovery
# path. Bypasses cmd.exe (avoids the intermittent 0xc0000142 DLL-init error)
# by launching powershell.exe directly on VRModHub.ps1, with retries and a
# .bat fallback. The working dir is pinned so no temp/deleted CWD is inherited.
# Returns $true if a relaunch was started.
function Invoke-HubRelaunch {
    $hubScript   = Join-Path $installCoreDir "VRModHub.ps1"
    $batLauncher = Join-Path $rootDir "Start PCVR Mods Hub.bat"
    $launched    = $false
    if (Test-Path $hubScript) {
        for ($t = 1; ($t -le 3) -and (-not $launched); $t++) {
            try {
                Start-Process "powershell.exe" `
                    -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$hubScript`"" `
                    -WorkingDirectory $rootDir -ErrorAction Stop | Out-Null
                $launched = $true
            } catch {
                Start-Sleep -Milliseconds 600
            }
        }
    }
    if ((-not $launched) -and (Test-Path $batLauncher)) {
        try {
            Start-Process "cmd.exe" -ArgumentList "/c", "`"$batLauncher`"" `
                -WorkingDirectory $rootDir -ErrorAction Stop | Out-Null
            $launched = $true
        } catch { }
    }
    return $launched
}

try {
    # --- Progress dialog ---
    $progressXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Updating..." Width="340" Height="120"
    WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
    Background="#0d0d0f">
    <StackPanel Margin="28,20">
        <TextBlock x:Name="ProgressLabel" Text="Downloading update..."
                   FontSize="12" Foreground="White" FontFamily="Segoe UI"
                   Margin="0,0,0,12"/>
        <ProgressBar x:Name="ProgressBar" Height="6" IsIndeterminate="True"
                     Background="#1e1e2a" Foreground="#66cc66"
                     BorderThickness="0"/>
    </StackPanel>
</Window>
"@
    $pReader   = [System.Xml.XmlReader]::Create([System.IO.StringReader]$progressXaml)
    $progWin   = [Windows.Markup.XamlReader]::Load($pReader)
    # Same VR goggles icon as the dialog window.
    try {
        $iconSize2 = 32
        $iconCanvas2 = New-Object System.Windows.Controls.Canvas
        $iconCanvas2.Width  = $iconSize2
        $iconCanvas2.Height = $iconSize2
        $iconCanvas2.Background = [System.Windows.Media.Brushes]::Transparent

        $goggles2 = New-Object System.Windows.Shapes.Path
        $goggles2.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
        $goggles2.StrokeThickness = 2.8
        $goggles2.Fill = [System.Windows.Media.Brushes]::Transparent
        $geom2 = [System.Windows.Media.Geometry]::Parse("M5,3 H27 Q30,3 30,6 V11 Q30,14 27,14 H21 Q19,14 18,12.5 L17,11 Q16,10 15,11 L14,12.5 Q13,14 11,14 H5 Q2,14 2,11 V6 Q2,3 5,3 Z")
        $goggles2.Data = $geom2
        [System.Windows.Controls.Canvas]::SetTop($goggles2, 7)
        $iconCanvas2.Children.Add($goggles2) | Out-Null

        $eyeColor2 = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#dd6600")
        $eyeL2 = New-Object System.Windows.Shapes.Ellipse
        $eyeL2.Width = 4; $eyeL2.Height = 4; $eyeL2.Fill = $eyeColor2
        [System.Windows.Controls.Canvas]::SetLeft($eyeL2, 7);  [System.Windows.Controls.Canvas]::SetTop($eyeL2, 14)
        $iconCanvas2.Children.Add($eyeL2) | Out-Null

        $eyeR2 = New-Object System.Windows.Shapes.Ellipse
        $eyeR2.Width = 4; $eyeR2.Height = 4; $eyeR2.Fill = $eyeColor2
        [System.Windows.Controls.Canvas]::SetLeft($eyeR2, 21); [System.Windows.Controls.Canvas]::SetTop($eyeR2, 14)
        $iconCanvas2.Children.Add($eyeR2) | Out-Null

        $iconCanvas2.Measure([System.Windows.Size]::new($iconSize2, $iconSize2))
        $iconCanvas2.Arrange([System.Windows.Rect]::new(0, 0, $iconSize2, $iconSize2))

        $rtb2 = New-Object System.Windows.Media.Imaging.RenderTargetBitmap (
            $iconSize2, $iconSize2, 96, 96,
            [System.Windows.Media.PixelFormats]::Pbgra32
        )
        $rtb2.Render($iconCanvas2)
        $progWin.Icon = $rtb2
    } catch { }
    $progLabel = $progWin.FindName("ProgressLabel")

    $progWin.Show()
    $progWin.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{})

    # Give the old GUI process time to fully exit (releases file handles)
    Start-Sleep -Milliseconds 1500

    # Step 1: Download
    $progLabel.Text = "Downloading $latestVersion..."
    $progWin.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{})
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing -ErrorAction Stop

    # Step 2: Extract to temp
    $progLabel.Text = "Extracting..."
    $progWin.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{})
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

    # Step 3: Locate extracted root
    $progLabel.Text = "Installing files..."
    $progWin.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{})

    # ZIP contains single top-level folder ("PCVR Mods Installer Hub")
    $extractedRoot = Get-ChildItem $tempExtract -Directory | Select-Object -First 1
    if (-not $extractedRoot) { $extractedRoot = Get-Item $tempExtract }

    # Robocopy:
    #   /E      - include subdirs (incl. empty)
    #   /NFL /NDL /NJH /NJS - quiet
    #   /R:2 /W:1 - 2 retries, 1s wait (handles transient file locks)
    #   /XF     - exclude files (simple names, not paths, are matched anywhere)
    # We preserve:
    #   version.txt           -> updater writes the new version explicitly below
    #   .shortcut_created     -> user preference flag (anywhere in tree)
    #   .update_available     -> will be deleted after update anyway
    $robocopyArgs = @(
        $extractedRoot.FullName,
        $installDir,
        "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/R:2", "/W:1",
        "/XF", "version.txt", ".shortcut_created", ".update_available", ".installed_version"
    )
    & robocopy @robocopyArgs | Out-Null
    # Robocopy exit codes 0-7 are success, 8+ are errors
    if ($LASTEXITCODE -ge 8) {
        throw "Robocopy failed with exit code $LASTEXITCODE"
    }

    # Step 4: Write new version number
    $newVer = $latestVersion.TrimStart("v")
    [System.IO.File]::WriteAllText(
        (Join-Path $installCoreDir "version.txt"),
        $newVer,
        (New-Object System.Text.UTF8Encoding $false)
    )

    # Step 5: Clean temp
    Remove-Item $tempZip    -Force -ErrorAction SilentlyContinue
    Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

    # Remove update marker
    Remove-Item (Join-Path $installCoreDir ".update_available") -Force -ErrorAction SilentlyContinue

    # Point of no return: files are in place and the version is written. From
    # here on, the update has succeeded no matter what the relaunch does.
    $updateDone = $true

    $progLabel.Text = "Done! Restarting..."
    $progWin.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{})
    Start-Sleep -Milliseconds 800
    try { $progWin.Close() } catch {}

    # Relaunch the hub (see Invoke-HubRelaunch above).
    if (-not (Invoke-HubRelaunch)) {
        [System.Windows.MessageBox]::Show(
            "Update installed successfully, but the Hub could not be relaunched automatically.`n`nPlease start it again from the 'VR Mods Hub' desktop shortcut.",
            "Update Complete",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
    }
    exit 0
}
catch {
    $errMsg = $_.Exception.Message
    try { $progWin.Close() } catch {}

    if ($updateDone) {
        # The update itself completed (new files in place, version written).
        # Only a post-install step hiccuped - restart the Hub and never report
        # this as a failed update.
        Invoke-HubRelaunch | Out-Null
        [System.Windows.MessageBox]::Show(
            "Update installed successfully, but the Hub could not be relaunched automatically.`n`nPlease start it again from the 'VR Mods Hub' desktop shortcut.",
            "Update Complete",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
        exit 0
    }

    # Genuine update failure (download / extract / copy). Roll back any partial
    # temp download, then FIRST FALLBACK: restart the Hub so the user has a
    # working app again. The .update_available marker still exists, so the Hub
    # shows the update banner and the user can simply retry. Only if the restart
    # itself fails do we fall back to a manual-update message.
    Remove-Item $tempZip     -Force -ErrorAction SilentlyContinue
    Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    if (Invoke-HubRelaunch) {
        [System.Windows.MessageBox]::Show(
            "The update could not be completed (network or file error) and was not applied.`n`nThe Hub has been restarted - you can try the update again from the banner, or update manually at:`n$releaseUrl",
            "Update Not Completed",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        ) | Out-Null
        exit 1
    }
    [System.Windows.MessageBox]::Show(
        "Update failed:`n$errMsg`n`nYou can update manually at:`n$releaseUrl",
        "Update Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Warning
    ) | Out-Null
    exit 1
}
