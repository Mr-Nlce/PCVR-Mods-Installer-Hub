# Project Zomboid VR keeps its three Workshop packages outside the game folder.
# This title-specific proof is shared by its installer and the Hub scanner.
function Get-PZVRWorkshopRoot([string]$GameRoot) {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PZ_TEST_WORKSHOP_ROOT) {
        return $env:PCVR_PZ_TEST_WORKSHOP_ROOT
    }
    if ($global:HubFileSystemLabRoot) { return $null }
    $normal = [IO.Path]::GetFullPath($GameRoot).TrimEnd([char[]]'\/')
    if ($normal -notmatch '(?i)^(?<apps>.+[\\/]steamapps)[\\/]common[\\/][^\\/]+$') { return $null }
    return (Join-Path $Matches.apps 'workshop\content\108600')
}

function Get-PZVRApprovalPath {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PZ_TEST_APPROVALS) {
        return $env:PCVR_PZ_TEST_APPROVALS
    }
    if ($global:HubFileSystemLabRoot) { return $null }
    return (Join-Path $env:USERPROFILE '.zombie_buddy\mod_approvals.json')
}

function Get-PZVRVersionPath {
    if ($env:PCVR_HUB_TEST_MODE -eq '1' -and $env:PCVR_PZ_TEST_VERSION_FILE) {
        return $env:PCVR_PZ_TEST_VERSION_FILE
    }
    if ($global:HubFileSystemLabRoot) { return $null }
    return (Join-Path $env:USERPROFILE 'Zomboid\version.txt')
}

function Get-PZVRExternalEvidence([string]$GameRoot) {
    if (-not $GameRoot -or -not (Test-Path -LiteralPath $GameRoot -PathType Container)) { return $null }
    $workshop = Get-PZVRWorkshopRoot $GameRoot
    $approvals = Get-PZVRApprovalPath
    $versionPath = Get-PZVRVersionPath
    if (-not $workshop -or -not $approvals -or -not $versionPath) { return $null }
    $files = @{
        ZbNative = Join-Path $workshop '3619862853\mods\ZombieBuddy\libs\zbNative.dll'
        ZbJar = Join-Path $workshop '3619862853\mods\ZombieBuddy\libs\ZombieBuddy.jar'
        ViewInfo = Join-Path $workshop '3809306528\mods\Viewpoint\common\mod.info'
        ViewJar = Join-Path $workshop '3809306528\mods\Viewpoint\42\media\java\client\Viewpoint.jar'
        PzInfo = Join-Path $workshop '3816830877\mods\PZVR\42\mod.info'
        PzJar = Join-Path $workshop '3816830877\mods\PZVR\42\media\java\client\PZVR.jar'
    }
    foreach ($path in $files.Values) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    }
    foreach ($name in @('ProjectZomboid64.exe','steam_api64.dll','zbNative.dll','ZombieBuddy.jar','ProjectZomboid64.json','ProjectZomboid64.bat')) {
        if (-not (Test-Path -LiteralPath (Join-Path $GameRoot $name) -PathType Leaf)) { return $null }
    }
    if (-not (Test-Path -LiteralPath $approvals -PathType Leaf) -or
        -not (Test-Path -LiteralPath $versionPath -PathType Leaf)) { return $null }
    try {
        $gameVersion = [IO.File]::ReadAllText($versionPath)
        $pzInfo = [IO.File]::ReadAllText($files.PzInfo)
        $viewInfo = [IO.File]::ReadAllText($files.ViewInfo)
        if ($gameVersion -notmatch '^42\.21(?:\.|\s)' -or
            $pzInfo -notmatch '(?m)^versionMin=42\.21\s*$' -or
            $pzInfo -notmatch '(?m)^versionMax=42\.21\s*$' -or
            $pzInfo -notmatch '(?m)^modversion=(?<version>[0-9]+(?:\.[0-9]+)+)\s*$' -or
            $viewInfo -notmatch '(?m)^modversion=0\.1\.6\.1\s*$') { return $null }
        $modVersion = [regex]::Match($pzInfo,'(?m)^modversion=(?<version>[0-9]+(?:\.[0-9]+)+)\s*$').Groups['version'].Value
        $json = [IO.File]::ReadAllText((Join-Path $GameRoot 'ProjectZomboid64.json'))
        $bat = [IO.File]::ReadAllText((Join-Path $GameRoot 'ProjectZomboid64.bat'))
        if ($json -notmatch '(?i)-agentlib:zbNative' -or $bat -notmatch '(?i)-agentlib:zbNative') { return $null }
        if ((Get-FileHash -LiteralPath (Join-Path $GameRoot 'zbNative.dll') -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $files.ZbNative -Algorithm SHA256).Hash) { return $null }
        if ((Get-FileHash -LiteralPath (Join-Path $GameRoot 'ZombieBuddy.jar') -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $files.ZbJar -Algorithm SHA256).Hash) { return $null }
        $approved = Get-Content -LiteralPath $approvals -Raw | ConvertFrom-Json
        $viewHash = (Get-FileHash -LiteralPath $files.ViewJar -Algorithm SHA256).Hash.ToLowerInvariant()
        $pzHash = (Get-FileHash -LiteralPath $files.PzJar -Algorithm SHA256).Hash.ToLowerInvariant()
        foreach ($needed in @(@{Id='Viewpoint';Hash=$viewHash},@{Id='PZVR';Hash=$pzHash})) {
            $row = @($approved.mods | Where-Object {
                $_.id -ieq $needed.Id -and $_.decision -eq $true -and $_.jar_hash -eq $needed.Hash
            })
            if ($row.Count -ne 1) { return $null }
        }
        return [pscustomobject]@{ Version=$modVersion; Workshop=$workshop; PzJar=$files.PzJar;
            PzHash=$pzHash; ViewHash=$viewHash; Game=$GameRoot }
    } catch { return $null }
}
