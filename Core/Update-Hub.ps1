# ============================================================
#  PCVR Mods Installer Hub - Auto Updater
#  Called silently by Start PCVR Mods Hub.bat after the GUI is visible.
#  Checks GitHub and writes an update marker for the live Hub banner.
# ============================================================

param(
    [switch]$Silent,
    [string]$ConfirmedVersion,
    [string]$ConfirmedDownloadUrl,
    [string]$LocalZip,
    [int]$HubOwnerPid,
    [switch]$NativeProgress,
    [int]$NativeWindowPid,
    [string]$NativeWindowPath
)

if ($NativeProgress) { [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false) }

$updaterStart = [Diagnostics.Stopwatch]::GetTimestamp()
$updaterStartUtc = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

# -------------------------------------------------------
#  CONFIG - set your GitHub repo here
# -------------------------------------------------------
$GITHUB_USER    = "Mr-Nlce"
$GITHUB_REPO    = "PCVR-Mods-Installer-Hub"
$API_URL        = "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/releases/latest"

if(-not(Get-Command Invoke-PCVRRestMethod -ErrorAction SilentlyContinue)){. (Join-Path $PSScriptRoot 'Modules\GitHubTransport.ps1')}

$installCoreDir = $PSScriptRoot
$rootDir        = Split-Path -Parent $PSScriptRoot
$CURRENT_VERSION_FILE = Join-Path $installCoreDir "version.txt"
$localStateRoot = [Environment]::GetFolderPath('LocalApplicationData')
if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_HUB_TEST_LOCALAPPDATA) {
    $fixtureRoot = Split-Path -Parent ([IO.Path]::GetFullPath($env:PCVR_HUB_TEST_LOCALAPPDATA))
    if (-not (Test-Path -LiteralPath (Join-Path $fixtureRoot '.pcvr-rust-fixture') -PathType Leaf)) {
        throw 'The updater test must use an isolated state directory.'
    }
    $localStateRoot = $env:PCVR_HUB_TEST_LOCALAPPDATA
}
$updateRuntimeDir = if ($localStateRoot) { Join-Path $localStateRoot 'PCVR Mods Installer Hub\Update' } else { $null }
$updateInfoFile = if ($updateRuntimeDir) { Join-Path $updateRuntimeDir 'update_available.json' } else { Join-Path $installCoreDir '.update_available' }
$performanceModule = Join-Path $PSScriptRoot 'Modules\HubPerformance.ps1'
if (Test-Path -LiteralPath $performanceModule -PathType Leaf) {
    . $performanceModule
    $performanceLog = New-PCVRPerformanceLog -LocalRoot $localStateRoot -Process update
}

function Write-UpdatePerformance([string]$Phase, [string]$Event, [long]$Since) {
    if ($performanceLog) {
        Write-PCVRPerformance -Log $performanceLog -Area $Phase -Event $Event -ElapsedMs (Get-PCVRPerformanceMs $Since)
    }
}

Write-UpdatePerformance 'hub_update' 'process_started' $updaterStart

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
$confirmed = -not [string]::IsNullOrWhiteSpace($ConfirmedVersion)
if ($confirmed) {
    if ($Silent -or $ConfirmedVersion -notmatch '^v?\d+(?:\.\d+){1,3}$' -or (Compare-SemVer $currentVersion $ConfirmedVersion) -le 0) {
        $requestError = 'The update must name a newer Hub release.'
    }
    $latestVersion = $ConfirmedVersion
    $releaseUrl = "https://github.com/$GITHUB_USER/$GITHUB_REPO/releases/tag/$latestVersion"
    $downloadUrl = $ConfirmedDownloadUrl
    if ($LocalZip) {
        if ($downloadUrl -or -not (Test-Path -LiteralPath $LocalZip -PathType Leaf)) {
            $requestError = 'Select one existing Hub release ZIP.'
        }
    } elseif ($downloadUrl -notmatch '^https://github\.com/Mr-Nlce/PCVR-Mods-Installer-Hub/releases/download/([^/?#]+)/([^/?#]+)$' -or
              [uri]::UnescapeDataString($Matches[1]) -cne $latestVersion -or
              [uri]::UnescapeDataString($Matches[2]) -notmatch '^PCVR[-_ .]*Mods[^/\\?#]*Hub[^/\\?#]*\.zip$') {
        $requestError = 'The update download does not match the selected official release.'
    }
    if (-not $requestError -and -not $LocalZip -and $fixtureRoot -and
        $env:PCVR_HUB_TEST_UPDATE_DOWNLOAD -match '^http://127\.0\.0\.1:\d+/PCVR-Mods-Hub\.zip$') {
        $downloadUrl = $env:PCVR_HUB_TEST_UPDATE_DOWNLOAD
    }
} else {
$releaseCheckStart = [Diagnostics.Stopwatch]::GetTimestamp()
try {
    # TLS 1.2 for older Win10/PS 5.1
    [System.Net.ServicePointManager]::SecurityProtocol = `
        [System.Net.ServicePointManager]::SecurityProtocol -bor `
        [System.Net.SecurityProtocolType]::Tls12

    $response = Invoke-PCVRRestMethod -Uri $API_URL `
        -Headers @{ "User-Agent" = "PCVR-Mods-Hub-Updater" } `
        -TimeoutSec 8 `
        -ErrorAction Stop

    $latestVersion  = $response.tag_name          # e.g. "v0.1.1"
    $releaseNotes   = $response.body
    $releaseUrl     = $response.html_url

    $zipAsset    = $response.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
    $downloadUrl = if ($zipAsset) { $zipAsset.browser_download_url } else { $null }
    Write-UpdatePerformance 'hub_update_release_check' 'completed' $releaseCheckStart
}
catch {
    Write-UpdatePerformance 'hub_update_release_check' 'failed' $releaseCheckStart
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
    $stale = $updateInfoFile
    if (Test-Path $stale) { Remove-Item $stale -Force -ErrorAction SilentlyContinue }
    exit 0
}

# -------------------------------------------------------
#  Update available - write info file for the GUI to read
# -------------------------------------------------------
if ($updateRuntimeDir -and -not (Test-Path -LiteralPath $updateRuntimeDir)) {
    New-Item -ItemType Directory -Path $updateRuntimeDir -Force -ErrorAction SilentlyContinue | Out-Null
}
@{
    LatestVersion  = $latestVersion
    CurrentVersion = $currentVersion
    ReleaseUrl     = $releaseUrl
    DownloadUrl    = $downloadUrl
    ReleaseNotes   = [string]$releaseNotes
} | ConvertTo-Json | Set-Content $updateInfoFile -Encoding UTF8

if ($Silent) {
    # GUI will pick up the info file and show the banner
    exit 0
}
}

# -------------------------------------------------------
#  Interactive mode: show WPF dialog
#  PowerShell reads the script before execution, so the updater can replace
#  this source file in place without launching a second temp-script process.
# -------------------------------------------------------
if (-not $NativeProgress) {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
}

if (-not $confirmed) {
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
$dlgWin.FindName("NotesLabel").Text = if ([string]::IsNullOrWhiteSpace($releaseNotes)) { "No release notes provided." } else { $releaseNotes }

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
}

# -------------------------------------------------------
#  Perform the update
# -------------------------------------------------------
$systemTempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
$tempParent  = $systemTempParent
if ($tempParent.Length -gt 70 -and $localStateRoot) {
    $localParent = [IO.Path]::GetFullPath($localStateRoot).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if ($localParent.Length -lt $tempParent.Length -and [IO.Directory]::Exists($localParent)) {
        $tempParent = $localParent
    }
}
$tempWork    = Join-Path $tempParent ('PCVRModsHub_update_' + [guid]::NewGuid().ToString('N'))
$tempZip     = Join-Path $tempWork 'release.zip'
$tempExtract = Join-Path $tempWork 'extracted'
$installDir  = $rootDir
# Marks the point of no return: once the new files are in place and the new
# version is written, the update has SUCCEEDED. Anything after that (relaunch)
# must never surface as "Update failed".
$updateDone  = $false
$reopenAfterNativeError = $false

function Remove-UpdateTemp {
    if (-not (Test-Path -LiteralPath $tempWork -PathType Container)) { return }
    $item = Get-Item -LiteralPath $tempWork -Force
    if ($item.FullName.StartsWith($tempParent, [StringComparison]::OrdinalIgnoreCase) -and
        $item.Name -match '^PCVRModsHub_update_[0-9a-f]{32}$' -and
        -not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        try {
            Invoke-UpdateWork -Arguments @($item.FullName) -Action {
                param($Path)
                [IO.Directory]::Delete($Path, $true)
            } | Out-Null
        } catch { }
    }
}

function Invoke-UpdateWork([scriptblock]$Action, [object[]]$Arguments) {
    if ($NativeProgress) {
        & $Action @Arguments
        return
    }
    $worker = [PowerShell]::Create()
    try {
        [void]$worker.AddScript($Action.ToString())
        foreach ($argument in $Arguments) { [void]$worker.AddArgument($argument) }
        $running = $worker.BeginInvoke()
        while (-not $running.AsyncWaitHandle.WaitOne(50)) {
            $progWin.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{})
        }
        $worker.EndInvoke($running)
    } finally { $worker.Dispose() }
}

function Write-NativeUpdateEvent([string]$Phase, [string]$Detail = '') {
    if ($NativeProgress) {
        [Console]::WriteLine("PCVR`t$Phase`t" + ($Detail -replace '[\r\n]+', ' '))
    }
}

function Set-UpdatePhase([string]$Phase, [string]$Text) {
    if ($progLabel) { $progLabel.Text = $Text }
    Write-NativeUpdateEvent $Phase
}

function Save-NativeRelease([string]$Url, [string]$Destination) {
    $ErrorActionPreference = 'Stop'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $request = [Net.HttpWebRequest]::Create($Url)
    $request.UserAgent = 'PCVR-Mods-Hub-Updater'
    $response = $request.GetResponse()
    try {
        $inputStream = $response.GetResponseStream()
        $output = [IO.File]::Create($Destination)
        try {
            $buffer = New-Object byte[] 131072
            [long]$received = 0
            $clock = [Diagnostics.Stopwatch]::StartNew()
            Write-NativeUpdateEvent 'bytes' "0/$($response.ContentLength)"
            while (($read = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $output.Write($buffer, 0, $read)
                $received += $read
                if ($clock.ElapsedMilliseconds -ge 200) {
                    Write-NativeUpdateEvent 'bytes' "$received/$($response.ContentLength)"
                    $clock.Restart()
                }
            }
            if ($response.ContentLength -ge 0 -and $received -ne $response.ContentLength) {
                throw 'The Hub ZIP download ended before all bytes arrived.'
            }
            Write-NativeUpdateEvent 'bytes' "$received/$($response.ContentLength)"
        } finally { $output.Dispose(); $inputStream.Dispose() }
    } finally { $response.Dispose() }
}

function Remove-NativeUpdateWindowCopy {
    if (-not $NativeProgress -or $NativeWindowPid -le 0 -or -not $NativeWindowPath) { return }
    try {
        $helper = Get-Item -LiteralPath $NativeWindowPath -ErrorAction Stop
        $folder = $helper.Directory
        if ($helper.Name -cne 'pcvr-hub.exe' -or $folder.Name -cnotmatch '^pcvr-hub-update-ui-\d+-\d+$' -or
            $folder.Parent.FullName.TrimEnd('\') -notin @($tempParent.TrimEnd('\'), $systemTempParent.TrimEnd('\')) -or
            ($helper.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
            ($folder.Attributes -band [IO.FileAttributes]::ReparsePoint)) { return }
        $window = Get-Process -Id $NativeWindowPid -ErrorAction SilentlyContinue
        if ($window) {
            try {
                if (-not $window.HasExited -and $window.Path -ine $helper.FullName) { return }
                $window.WaitForExit()
            } finally { $window.Dispose() }
        }
        [IO.File]::Delete($helper.FullName)
        [IO.Directory]::Delete($folder.FullName)
    } catch { }
}

# Relaunch helper - reused by both the success path and the failure-recovery
# path. Bypasses cmd.exe (avoids the intermittent 0xc0000142 DLL-init error)
# by launching powershell.exe directly on VRModHub.ps1, with retries and a
# .bat fallback. The working dir is pinned so no temp/deleted CWD is inherited.
# Returns $true if a relaunch was started.
function Test-HubOwner([Diagnostics.Process]$Process) {
    $ownerPath = $Process.Path
    if (-not $ownerPath) { return $false }
    $utils = [IO.Path]::GetFullPath((Join-Path $installCoreDir 'Utils'))
    $ownerPath = [IO.Path]::GetFullPath($ownerPath)
    $ownerDir = [IO.Path]::GetDirectoryName($ownerPath)
    if ($ownerDir -ine $utils) {
        try {
            if ([HubUpdateFiles]::ResolveDirectory($ownerDir) -ine [HubUpdateFiles]::ResolveDirectory($utils)) { return $false }
        } catch { return $false }
    }

    $installedExe = Join-Path $utils 'pcvr-hub.exe'
    if ([IO.Path]::GetFileName($ownerPath) -ieq 'pcvr-hub.exe') { return $true }
    # The native window runs a copy of the executable that requested the update.
    $reference = if ($NativeWindowPath) { $NativeWindowPath } else { $installedExe }
    if (-not [IO.File]::Exists($reference)) { return $false }
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $image = [IO.File]::OpenRead($ownerPath)
        try { $ownerHash = [Convert]::ToBase64String($sha.ComputeHash($image)) }
        finally { $image.Dispose() }
        $image = [IO.File]::OpenRead($reference)
        try { return $ownerHash -ceq [Convert]::ToBase64String($sha.ComputeHash($image)) }
        finally { $image.Dispose() }
    } finally { $sha.Dispose() }
}

function Invoke-HubRelaunch {
    if ($HubOwnerPid -gt 0) {
        $runningHub = Get-Process -Id $HubOwnerPid -ErrorAction SilentlyContinue
        if ($runningHub) {
            try {
                if (-not $runningHub.HasExited -and (Test-HubOwner $runningHub)) { return $true }
            } finally { $runningHub.Dispose() }
        }
    }
    $hubScript   = Join-Path $installCoreDir "VRModHub.ps1"
    $batLauncher = Join-Path $rootDir "Start PCVR Mods Hub.bat"
    $launched    = $false
    if ($updateDone -and $performanceLog) {
        $env:PCVR_HUB_UPDATE_TRACE_ID = $performanceLog.Id
        $env:PCVR_HUB_UPDATE_STARTED_MS = [string]$updaterStartUtc
    }

    # 1) The normal way the Hub is started. It sets up the environment the Hub
    #    expects, and it is what the desktop shortcut uses too.
    if (Test-Path -LiteralPath $batLauncher -PathType Leaf) {
        try {
            $cmd = Join-Path ([Environment]::SystemDirectory) 'cmd.exe'
            $startup = [Diagnostics.ProcessStartInfo]::new($cmd, '/d /v:off /s /c ""%PCVR_HUB_RESTART_LAUNCHER%""')
            $startup.WorkingDirectory = $rootDir
            $startup.UseShellExecute = $false
            $startup.CreateNoWindow = $true
            # Expand the literal path inside cmd's quotes. ShellExecute can
            # re-interpret path characters and leaves Terminal sessions behind.
            $startup.EnvironmentVariables['PCVR_HUB_RESTART_LAUNCHER'] = $batLauncher
            $process = [Diagnostics.Process]::Start($startup)
            if ($process) { $process.Dispose() }
            $launched = $true
        } catch { Write-Verbose $_.Exception.Message }
    }

    # 2) Only if that file is missing: call the script directly. One attempt -
    #    retrying a loader failure just produces another Windows error box.
    if ((-not $launched) -and (Test-Path -LiteralPath $hubScript -PathType Leaf)) {
        try {
            $startup = [Diagnostics.ProcessStartInfo]::new(
                (Join-Path $PSHOME 'powershell.exe'), "-NoProfile -ExecutionPolicy Bypass -File `"$hubScript`"")
            $startup.WorkingDirectory = $rootDir
            $startup.UseShellExecute = $false
            $startup.CreateNoWindow = $true
            $process = [Diagnostics.Process]::Start($startup)
            if ($process) { $process.Dispose() }
            $launched = $true
        } catch { Write-Verbose $_.Exception.Message }
    }
    return $launched
}

try {
    if (-not $NativeProgress) {
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
    }
    Write-UpdatePerformance 'hub_update' 'progress_window_rendered' $updaterStart
    if ($requestError) { throw $requestError }

    $implementation = Join-Path $installCoreDir 'Modules/HubUpdateFiles.cs'
    # The .NET Framework compiler also uses TEMP internally.
    $previousTemp = $env:TEMP
    $previousTmp = $env:TMP
    try {
        $env:TEMP = $tempParent
        $env:TMP = $tempParent
        Add-Type -LiteralPath $implementation -ErrorAction Stop
    } finally {
        $env:TEMP = $previousTemp
        $env:TMP = $previousTmp
    }
    $installDir = [HubUpdateFiles]::ResolveDirectory($installDir)
    $lockHash = [Security.Cryptography.SHA256]::Create()
    try { $lockKey = [BitConverter]::ToString($lockHash.ComputeHash([Text.Encoding]::UTF8.GetBytes($installDir.ToLowerInvariant()))).Replace('-', '') }
    finally { $lockHash.Dispose() }
    $updateMutex = [Threading.Mutex]::new($false, "Local\PCVRHubClassicUpdate_$lockKey")
    try { $ownsUpdate = $updateMutex.WaitOne(0) }
    catch [Threading.AbandonedMutexException] { $ownsUpdate = $true }
    if (-not $ownsUpdate) {
        Write-NativeUpdateEvent 'error' 'Another update is already running.'
        exit 1
    }

    [void][IO.Directory]::CreateDirectory($tempWork)
    $archivePath = $LocalZip
    if (-not $archivePath) {
        Set-UpdatePhase 'download' "Downloading $latestVersion..."
        Write-Output "Downloading $latestVersion..."
        $phaseStart = [Diagnostics.Stopwatch]::GetTimestamp()
        Write-UpdatePerformance 'hub_update_download' 'started' $phaseStart
        if ($NativeProgress) {
            Save-NativeRelease $downloadUrl $tempZip
        } else {
            Invoke-UpdateWork -Arguments @($downloadUrl, $tempZip) -Action {
                param($Url, $Destination)
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
            }
        }
        Write-UpdatePerformance 'hub_update_download' 'completed' $phaseStart
        $archivePath = $tempZip
    }

    Set-UpdatePhase 'extract' 'Extracting the release ZIP...'
    Write-Output 'Extracting the release ZIP...'
    $phaseStart = [Diagnostics.Stopwatch]::GetTimestamp()
    Write-UpdatePerformance 'hub_update_extract' 'started' $phaseStart
    Invoke-UpdateWork -Arguments @($archivePath, $tempExtract) -Action {
        param($Archive, $Destination)
        $ErrorActionPreference = 'Stop'
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [IO.Compression.ZipFile]::ExtractToDirectory($Archive, $Destination)
    }
    Write-UpdatePerformance 'hub_update_extract' 'completed' $phaseStart

    $phaseStart = [Diagnostics.Stopwatch]::GetTimestamp()
    $extractedRoot = Join-Path $tempExtract 'PCVR Mods Installer Hub'
    foreach ($required in @('Start PCVR Mods Hub.bat', 'Core/Modules/Catalog.ps1', 'Core/Modules/Catalog.json', 'Core/Utils/pcvr-hub.exe')) {
        if (-not (Test-Path -LiteralPath (Join-Path $extractedRoot $required) -PathType Leaf)) {
            throw 'The ZIP does not contain a complete Hub release.'
        }
    }
    $newVer = $latestVersion.TrimStart('v','V')
    try {
        $catalogText = [IO.File]::ReadAllText((Join-Path $extractedRoot 'Core/Modules/Catalog.json'))
        $catalog = ConvertFrom-Json -InputObject $catalogText -ErrorAction Stop
        if ($catalog.games -isnot [array]) { throw 'The games list is missing.' }
    } catch {
        throw 'The release ZIP contains an invalid Hub catalog. The installed files were kept.'
    }
    $archiveVersion = [IO.File]::ReadAllText((Join-Path $extractedRoot 'Core/version.txt')).Trim().TrimStart('v','V')
    if ($archiveVersion -cne $newVer) { throw 'The ZIP version does not match the selected Hub release.' }
    $exe = [IO.BinaryReader]::new([IO.File]::OpenRead((Join-Path $extractedRoot 'Core/Utils/pcvr-hub.exe')))
    try {
        if ($exe.BaseStream.Length -lt 64 -or $exe.ReadUInt16() -ne 0x5A4D) { throw 'The ZIP contains an invalid Hub executable.' }
        $exe.BaseStream.Position = 60
        $header = $exe.ReadUInt32()
        if ($header -gt ($exe.BaseStream.Length - 4)) { throw 'The ZIP contains an invalid Hub executable.' }
        $exe.BaseStream.Position = $header
        if ($exe.ReadUInt32() -ne 0x4550) { throw 'The ZIP contains an invalid Hub executable.' }
    } finally { $exe.Dispose() }
    Write-UpdatePerformance 'hub_update_validate' 'completed' $phaseStart

    if ($HubOwnerPid -gt 0) {
        $phaseStart = [Diagnostics.Stopwatch]::GetTimestamp()
        $owner = Get-Process -Id $HubOwnerPid -ErrorAction SilentlyContinue
        if ($owner) {
            try {
                if (-not $owner.HasExited -and -not (Test-HubOwner $owner)) {
                    throw 'The update was opened from a different Hub installation.'
                }
                Set-UpdatePhase 'wait' 'Waiting for the Hub to close...'
                while (-not $owner.WaitForExit(50)) {
                    if ($progWin) { $progWin.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{}) }
                }
            } finally { $owner.Dispose() }
        }
        Write-UpdatePerformance 'hub_update_wait_for_close' 'completed' $phaseStart
    }
    if ((Compare-SemVer ([IO.File]::ReadAllText($CURRENT_VERSION_FILE).Trim()) $latestVersion) -le 0) {
        throw 'A newer or equal Hub version is already installed.'
    }

    Set-UpdatePhase 'install' 'Installing files...'
    Write-Output 'Installing files...'
    $phaseStart = [Diagnostics.Stopwatch]::GetTimestamp()
    Write-UpdatePerformance 'hub_update_copy' 'started' $phaseStart

    Invoke-UpdateWork -Arguments @($extractedRoot, $installDir, $newVer) -Action {
        param($Source, $Destination, $Version)
        $ErrorActionPreference = 'Stop'
        [HubUpdateFiles]::Apply($Source, $Destination, $Version)
    }
    Write-UpdatePerformance 'hub_update_copy' 'completed' $phaseStart

    # Step 5: Clean temp
    $updateDone = $true
    Set-UpdatePhase 'finish' 'Finishing the update...'
    if ($progWin) { $progWin.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{}) }
    $phaseStart = [Diagnostics.Stopwatch]::GetTimestamp()
    Remove-UpdateTemp

    # Remove update marker
    Remove-Item -LiteralPath $updateInfoFile -Force -ErrorAction SilentlyContinue
    Write-UpdatePerformance 'hub_update_cleanup' 'completed' $phaseStart

    # Point of no return: files are in place and the version is written. From
    # here on, the update has succeeded no matter what the relaunch does.
    Set-UpdatePhase 'restart' 'Done! Restarting...'
    Write-Output 'Done! Restarting...'
    Write-UpdatePerformance 'hub_update' 'restart_requested' $updaterStart
    if ($progWin) { $progWin.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{}) }
    try { $progWin.Close() } catch {}

    # Relaunch the hub (see Invoke-HubRelaunch above).
    if (Invoke-HubRelaunch) {
        Write-NativeUpdateEvent 'complete'
    } elseif ($NativeProgress) {
        Write-NativeUpdateEvent 'error' 'The update is installed. Open the Hub again to finish.'
    } else {
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
    $needsFileRecovery = $errMsg -like '*The update could not restore every file.*'
    Write-UpdatePerformance 'hub_update' 'failed' $updaterStart
    try { $progWin.Close() } catch {}

    if ($NativeProgress) {
        if ($updateDone -and (Invoke-HubRelaunch)) {
            Write-NativeUpdateEvent 'complete'
            exit 0
        }
        Remove-UpdateTemp
        Write-NativeUpdateEvent 'error' $errMsg
        $reopenAfterNativeError = -not $updateDone -and -not $needsFileRecovery
        exit 1
    }

    if ($updateDone) {
        # The update itself completed (new files in place, version written).
        # Only a post-install step hiccuped - restart the Hub and never report
        # this as a failed update.
        # Only say something if the Hub really did NOT come back. This branch
        # used to show the box unconditionally, so a completed update with a
        # working restart still told the user to start the Hub by hand.
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

    # Genuine update failure (download / extract / copy). Roll back any partial
    # temp download, then FIRST FALLBACK: restart the Hub so the user has a
    # working app again. The .update_available marker still exists, so the Hub
    # shows the update banner and the user can simply retry. Only if the restart
    # itself fails do we fall back to a manual-update message.
    Remove-UpdateTemp
    Write-Error $errMsg -ErrorAction Continue
    if (-not $needsFileRecovery -and (Invoke-HubRelaunch)) {
        # No message box here. It fired on updates that had in fact gone
        # through, so it told users their update had failed when it had not.
        # The Hub is running again and the banner still shows if anything is
        # genuinely left to do - that is the honest signal.
        exit 1
    }
    [System.Windows.MessageBox]::Show(
        "Update failed:`n$errMsg`n`nYou can update manually at:`n$releaseUrl",
        "Update Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Warning
    ) | Out-Null
    exit 1
} finally {
    if ($ownsUpdate) { $updateMutex.ReleaseMutex() }
    if ($updateMutex) { $updateMutex.Dispose() }
    Remove-NativeUpdateWindowCopy
    if ($reopenAfterNativeError) {
        $env:PCVR_HUB_UPDATE_RECOVERY = '1'
        [void](Invoke-HubRelaunch)
    }
}
