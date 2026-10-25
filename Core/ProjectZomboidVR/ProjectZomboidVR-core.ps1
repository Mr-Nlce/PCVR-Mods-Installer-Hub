$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\Modules\InstallerFoundation.ps1')
. (Join-Path $PSScriptRoot 'PZEvidence.ps1')
$Host.UI.RawUI.WindowTitle = 'Project Zomboid VR Installer'
$script:PZId = 'project-zomboid-vr'
$script:PZWorkshopPage = 'https://steamcommunity.com/sharedfiles/filedetails/?id=3816830877'
$script:ZBReleasePage = 'https://github.com/zed-0xff/ZombieBuddy/releases/tag/windows_installer_4.3'
$script:PZContract = New-PCVRInstallerContract -Id $script:PZId -GameName 'Project Zomboid VR' `
    -Acquisition External -AntivirusNotice -ReleasePageUrl $script:PZWorkshopPage `
    -RequiredInstalledFileGroups @('ProjectZomboid64.exe','steam_api64.dll','zbNative.dll',
        'ZombieBuddy.jar','ProjectZomboid64.json','ProjectZomboid64.bat','.pcvrhub_pzvr_activation.json')

function Test-PZVRGame([string]$Root) {
    return [bool]($Root -and
        (Test-Path -LiteralPath (Join-Path $Root 'ProjectZomboid64.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'steam_api64.dll') -PathType Leaf))
}
function Get-PZVRGame {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PZ_TEST_GAME) {
        if (Test-PZVRGame $env:PCVR_PZ_TEST_GAME) { return [IO.Path]::GetFullPath($env:PCVR_PZ_TEST_GAME) }
        throw 'The isolated Project Zomboid game fixture is incomplete.'
    }
    $found = $null
    try { $found = Find-SteamGameFolder -AppId '108600' -SteamFolderNames @('ProjectZomboid') `
        -ProbeExe 'ProjectZomboid64.exe' -HubGameId $script:PZId } catch {}
    if (Test-PZVRGame $found) { return [IO.Path]::GetFullPath($found) }
    $default = 'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid'
    if (Test-PZVRGame $default) { return $default }
    $picked = Get-GameFolderInteractive -GameName 'Project Zomboid' `
        -ProbeFile 'ProjectZomboid64.exe' -ManualUrl 'https://store.steampowered.com/app/108600/'
    if (Test-PZVRGame $picked) { return [IO.Path]::GetFullPath($picked) }
    throw 'Choose the Steam Project Zomboid folder with ProjectZomboid64.exe and steam_api64.dll.'
}
function Test-PZVRWorkshopFiles([string]$GameRoot) {
    $workshop = Get-PZVRWorkshopRoot $GameRoot
    if (-not $workshop) { return $false }
    foreach ($file in @('3619862853\mods\ZombieBuddy\libs\zbNative.dll',
        '3619862853\mods\ZombieBuddy\libs\ZombieBuddy.jar',
        '3809306528\mods\Viewpoint\42\media\java\client\Viewpoint.jar',
        '3816830877\mods\PZVR\42\media\java\client\PZVR.jar')) {
        if (-not (Test-Path -LiteralPath (Join-Path $workshop $file) -PathType Leaf)) { return $false }
    }
    return $true
}
function Wait-PZVRWorkshop([string]$GameRoot) {
    if (Test-PZVRWorkshopFiles $GameRoot) { return }
    Write-Host '  Subscribe to PZVR and both required Workshop items: ZombieBuddy and Project Viewpoint.' -ForegroundColor White
    Write-Host '  On the PZVR page, click the blue Subscribe to all button.' -ForegroundColor Green
    Write-Host '  Steam then downloads all three Workshop packages.' -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to open the PZVR Workshop page...')
    if ($env:PCVR_HUB_TEST_MODE -ne '1') { Start-Process $script:PZWorkshopPage }
    while (-not (Test-PZVRWorkshopFiles $GameRoot)) {
        [void](Wait-PCVRExplicitEnter -Message 'After the Workshop download finishes, press Enter to check all three mods...')
        if (Test-PZVRWorkshopFiles $GameRoot) { break }
        Write-Host '  At least one Workshop package has not arrived yet.' -ForegroundColor Yellow
        $choice = ('' + (Read-Host 'Press Enter to check again, O to reopen the page, or Q to cancel')).Trim()
        if ($choice -ieq 'Q') { throw 'Workshop files are incomplete; nothing was marked installed.' }
        if ($choice -ieq 'O') {
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to reopen the PZVR Workshop page...')
            if ($env:PCVR_HUB_TEST_MODE -ne '1') { Start-Process $script:PZWorkshopPage }
        }
    }
}
function Test-PZVRAgent([string]$GameRoot) {
    $workshop = Get-PZVRWorkshopRoot $GameRoot
    if (-not $workshop) { return $false }
    foreach ($name in @('zbNative.dll','ZombieBuddy.jar')) {
        $source = Join-Path $workshop ('3619862853\mods\ZombieBuddy\libs\' + $name)
        $target = Join-Path $GameRoot $name
        if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or
            -not (Test-Path -LiteralPath $target -PathType Leaf) -or
            (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash) { return $false }
    }
    foreach ($name in @('ProjectZomboid64.json','ProjectZomboid64.bat')) {
        if ((Get-Content -LiteralPath (Join-Path $GameRoot $name) -Raw) -notmatch '(?i)-agentlib:zbNative') { return $false }
    }
    return $true
}
function Wait-PZVRAgent([string]$GameRoot) {
    if (Test-PZVRAgent $GameRoot) { return }
    Write-Host '  ZombieBuddy needs its separate Windows installer once.' -ForegroundColor White
    Write-Host '  The publisher setup will ask for Install, Both, and Continue.' -ForegroundColor White
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to check and download the ZombieBuddy Windows installer...')
    $session = New-PCVRInstallerTempSession -BasePath ([IO.Path]::GetTempPath())
    try {
        $download = Join-Path $session 'ZombieBuddyInstaller.exe'
        [string[]]$urls = @('https://github.com/zed-0xff/ZombieBuddy/releases/download/windows_installer_4.3/ZombieBuddyInstaller_v4.3.exe')
        $result = Invoke-SafeDownload -Urls $urls -Destination $download `
            -Label 'ZombieBuddy Windows installer' -ManualUrl $script:ZBReleasePage `
            -ExpectedReleaseTag 'windows_installer_4.3' -AllowSkip $false
        if ($result -ne $true -and [string]$result -ne 'retry') {
            throw 'The ZombieBuddy Windows installer was not downloaded or selected.'
        }
        while (-not (Test-PZVRAgent $GameRoot)) {
            Write-Host ''
            Write-Host '  IN THE ZOMBIEBUDDY SETUP:' -ForegroundColor Yellow
            Write-Host '    1) Press 1 - Install ZombieBuddy.' -ForegroundColor Green
            Write-Host '    2) Press 1 - Both launch modes.' -ForegroundColor Green
            Write-Host '    3) Press y - Continue with the listed changes.' -ForegroundColor Green
            Write-Host '  If asked, exit Steam completely; then press Enter in its setup.' -ForegroundColor Yellow
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to run the downloaded ZombieBuddy Setup...')
            if ($env:PCVR_HUB_TEST_MODE -ne '1') {
                $process = Start-Process -FilePath $download -Wait -PassThru
                if ($process.ExitCode -ne 0) {
                    Write-Host "  Publisher Setup exited with code $($process.ExitCode)." -ForegroundColor Yellow
                }
            }
            if (Test-PZVRAgent $GameRoot) { break }
            Write-Host '  ZombieBuddy is not fully installed yet. Its setup must patch both launch modes.' -ForegroundColor Yellow
            $choice = ('' + (Read-Host 'Press Enter to retry Setup, or Q to cancel')).Trim()
            if ($choice -ieq 'Q') { throw 'ZombieBuddy is incomplete; nothing was marked installed.' }
        }
    } finally {
        if (Test-Path -LiteralPath $session -PathType Container) {
            Remove-Item -LiteralPath $session -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
function Get-PZVRLogPath {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PZ_TEST_LOG) { return $env:PCVR_PZ_TEST_LOG }
    return (Join-Path $env:USERPROFILE 'Zomboid\console.txt')
}
function Test-PZVRLoaded([string]$GameRoot, $Evidence) {
    $log = Get-PZVRLogPath
    if (-not (Test-Path -LiteralPath $log -PathType Leaf)) { return $false }
    if ((Get-Item -LiteralPath $log).LastWriteTimeUtc -lt [DateTime]::UtcNow.AddDays(-1)) { return $false }
    $content = Get-Content -LiteralPath $log -Raw
    return [bool]($content -match '\[Viewpoint\] loaded' -and
        $content -match '\[PZVR\] PZVR loaded; backend=openxr' -and
        $content.Contains($Evidence.PzHash))
}
function Invoke-PZVRInstaller {
    Clear-Host
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host '  Project Zomboid VR - Installer' -ForegroundColor Cyan
    Write-Host '  PZVR, Project Viewpoint and ZombieBuddy' -ForegroundColor Gray
    Write-Host ('=' * 60) -ForegroundColor Magenta
    Write-Host ''
    Write-Host '  Steam Build 42.21 is required. The three mods come from Steam Workshop.' -ForegroundColor White
    Write-Host '  ZombieBuddy needs a separate one-time Windows setup.' -ForegroundColor White
    Show-AntivirusNotice -Compact
    [void](Wait-PCVRExplicitEnter -Message 'After reading this, press Enter to locate Project Zomboid...')
    $game = Get-PZVRGame
    Write-Host "  Game: $game" -ForegroundColor Green
    $agentWasInstalled = Test-PZVRAgent $game
    $workshopEvidence = Get-PZVRExternalEvidence -GameRoot $game -AllowPzApprovalMismatch
    $oldMarkerPath = Join-Path $game '.pcvrhub_pzvr_activation.json'
    $oldMarker = $null
    if ($workshopEvidence -and (Test-Path -LiteralPath $oldMarkerPath -PathType Leaf)) {
        try { $oldMarker = Get-Content -LiteralPath $oldMarkerPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
    }
    $workshopUpdate = $false
    if ($agentWasInstalled -and $oldMarker -and $workshopEvidence) {
        try {
            $workshopUpdate = [bool]($oldMarker.version -and $oldMarker.pzJarSha256 -and
                $oldMarker.pzJarSha256 -ne $workshopEvidence.PzHash -and
                [version]$workshopEvidence.Version -ge [version]$oldMarker.version)
        } catch { $workshopUpdate = $false }
    }
    if ($workshopUpdate) {
        Write-Host "  Steam Workshop updated PZVR from $($oldMarker.version) to $($workshopEvidence.Version)." -ForegroundColor Yellow
    }
    Wait-PZVRWorkshop $game
    Wait-PZVRAgent $game
    $alreadyVerifiedUpdate = $false
    if ($workshopUpdate) {
        $current = Get-PZVRExternalEvidence -GameRoot $game
        $alreadyVerifiedUpdate = [bool]($current -and (Test-PZVRLoaded -GameRoot $game -Evidence $current))
        if ($alreadyVerifiedUpdate) {
            Write-Host '  The new Workshop files were already approved and loaded on a recent game start.' -ForegroundColor Green
        } else {
            Write-Host ''
            Write-Host '  WORKSHOP UPDATE: APPROVE THE CHANGED JAVA MODS' -ForegroundColor Yellow
            Write-Host '  Steam installs this update through Workshop. Keep Steam running.' -ForegroundColor White
            Write-Host '  1) On game start, allow PZVR and Viewpoint if ZombieBuddy asks again.' -ForegroundColor Green
            Write-Host '  2) Select Save decisions to disk, then click OK.' -ForegroundColor Green
            Write-Host '     Trust author is unavailable for unsigned mods.' -ForegroundColor Gray
        }
    } else {
        Write-Host ''
        Write-Host '  PROJECT ZOMBOID: ACTIVATE THE VR MODS' -ForegroundColor Yellow
        Write-Host '  1) Open Mods in the main menu. Enable ZombieBuddy, Viewpoint and PZVR.' -ForegroundColor Green
        Write-Host '  2) Confirm any activation window with OK; restart the game if requested.' -ForegroundColor Green
        Write-Host '  3) In ZombieBuddy approval, Allow Viewpoint and PZVR, then click OK.' -ForegroundColor Green
        Write-Host '  4) Select Save decisions to disk to remember the approvals.' -ForegroundColor Green
        Write-Host '     Trust author is unavailable for unsigned mods.' -ForegroundColor Gray
        Write-Host '  Keep the first game session flat. Do not press Start VR yet.' -ForegroundColor Yellow
    }
    if (-not $alreadyVerifiedUpdate) {
        if (-not $agentWasInstalled) {
            [void](Wait-PCVRExplicitEnter -Message 'Press Enter to reopen Steam after ZombieBuddy Setup...')
            if($env:PCVR_HUB_TEST_MODE -eq '1'){
                if($env:PCVR_PZ_TEST_ACTIONS){Add-Content -LiteralPath $env:PCVR_PZ_TEST_ACTIONS -Value 'open:steam://open/main'}
            }else{try{Start-Process 'steam://open/main' -ErrorAction Stop|Out-Null}catch{Write-Host ' Open Steam from your Start menu.' -ForegroundColor Yellow}}
        }
        [void](Wait-PCVRExplicitEnter -Message 'Press Enter to start Project Zomboid through Steam...')
        if($env:PCVR_HUB_TEST_MODE -eq '1'){
            if($env:PCVR_PZ_TEST_ACTIONS){Add-Content -LiteralPath $env:PCVR_PZ_TEST_ACTIONS -Value 'open:steam://rungameid/108600'}
        }else{try{Start-Process 'steam://rungameid/108600' -ErrorAction Stop|Out-Null}catch{Write-Host ' Start Project Zomboid from your Steam Library.' -ForegroundColor Yellow}}
    }
    if (-not $workshopUpdate) {
        Write-Host ''
        Write-Host '  FIRST PERSON SETUP - STAY IN FLAT MODE' -ForegroundColor Yellow
        Write-Host '  1) Start a NEW single-player game on the desktop. Do not press Start VR.' -ForegroundColor Green
        Write-Host '  2) When the first-person configuration window appears, click its Restart button.' -ForegroundColor Green
        Write-Host '  3) Start a flat single-player game again and finish the Viewpoint setup.' -ForegroundColor Green
        Write-Host '  4) Check that the top left lists PZVR and Viewpoint.' -ForegroundColor Green
        Write-Host '  5) Only then press Start VR at the top right to enter VR.' -ForegroundColor Cyan
    }
    while ($true) {
        if (-not $alreadyVerifiedUpdate) {
            $checkMessage = if ($workshopUpdate) { 'After approving the changed mods, press Enter to check the game log...' } else {
                'After the flat first-person setup and restart, press Enter to check the mods and game log...'
            }
            [void](Wait-PCVRExplicitEnter -Message $checkMessage)
        }
        $evidence = Get-PZVRExternalEvidence -GameRoot $game
        $loaded = $evidence -and (Test-PZVRLoaded -GameRoot $game -Evidence $evidence)
        if ($loaded) {
            if ($workshopUpdate) { break }
            if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PZ_TEST_CONFIRMED -eq '1') { break }
            if ((Read-Host 'Did the Start VR button appear at the top right? Y/N').Trim() -match '^(?i)y(?:es)?$') { break }
            Write-Host '  Start VR was not confirmed. No installation has been marked complete.' -ForegroundColor Yellow
        } else {
            $pendingWorkshop = Get-PZVRPendingWorkshopUpdate -GameRoot $game
            if ($pendingWorkshop) {
                Write-Host '  The new Workshop PZVR JAR is not yet approved in ZombieBuddy.' -ForegroundColor Yellow
                Write-Host '  Start the game again, Allow PZVR in the approval window, and save the decision.' -ForegroundColor White
            } else {
                Write-Host '  The current game build, Java approvals or loaded PZVR log is incomplete.' -ForegroundColor Yellow
            }
            if ($workshopUpdate) {
                Write-Host '  Launch the game, allow changed Java mods, save decisions to disk and click OK.' -ForegroundColor White
            } else {
                Write-Host '  Enable all three mods, Allow Viewpoint and PZVR, finish the flat Viewpoint setup, then check Start VR.' -ForegroundColor White
            }
        }
        if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw 'The isolated PZVR fixture did not produce complete activation evidence.' }
        $choice = ('' + (Read-Host 'Press Enter to check again, or Q to cancel')).Trim()
        if ($choice -ieq 'Q') { throw 'PZVR activation is incomplete; nothing was marked installed.' }
    }
    $marker = Join-Path $game '.pcvrhub_pzvr_activation.json'
    $before = if (Test-Path -LiteralPath $marker -PathType Leaf) { [IO.File]::ReadAllBytes($marker) } else { $null }
    try {
        $proof = [ordered]@{schema=1;version=$evidence.Version;pzJarSha256=$evidence.PzHash;
            viewpointJarSha256=$evidence.ViewHash;verifiedAtUtc=[DateTime]::UtcNow.ToString('o')}
        Write-PCVRAtomicText -Path $marker -Value ($proof | ConvertTo-Json -Compress)
        $receipt = if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PZ_TEST_RECEIPT) {
            $env:PCVR_PZ_TEST_RECEIPT
        } else { Join-Path $PSScriptRoot '.installed_path' }
        [void](Complete-PCVRInstallTransaction -Contract $script:PZContract -GameDir $game `
            -Version $evidence.Version -InstalledPathReceiptPaths @($receipt) -Route Workshop)
    } catch {
        if ($null -eq $before) { Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue }
        else { [IO.File]::WriteAllBytes($marker,[byte[]]$before) }
        throw
    }
    Write-Host '  1. Use Start in VR in the Hub. In the game menu, press Start VR.' -ForegroundColor Yellow
    Write-Host '  Alternative: start Project Zomboid from Steam, then press Start VR in its game menu.' -ForegroundColor White
    Write-Host ''
    Write-Host '  Survive another day, this time from inside the world.' -ForegroundColor Magenta
    [void](Wait-PCVRExplicitEnter -Message 'Press Enter to close setup...')
}
if ($env:PCVR_PZ_LIBRARY_ONLY -ne '1') {
    while ($true) {
        try { Invoke-PZVRInstaller; break }
        catch {
            $message = "Project Zomboid VR setup did not complete: $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            if ($env:PCVR_HUB_TEST_MODE -eq '1') { throw }
            [void](Invoke-PCVRUniversalRecovery -FailureMessage $message -InstallerFolder $PSScriptRoot)
        }
    }
}
