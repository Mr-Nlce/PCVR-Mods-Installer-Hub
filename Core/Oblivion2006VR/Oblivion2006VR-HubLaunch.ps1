param(
    [Parameter(Mandatory=$true)][string]$GameDirectory,
    [string]$RuntimeRoot=''
)

$ErrorActionPreference='Stop'
$Host.UI.RawUI.WindowTitle='Oblivion (2006) VR - Start in VR'

function Write-OBLaunchHeader {
    Clear-Host
    Write-Host ('='*60) -ForegroundColor Magenta
    Write-Host '  Oblivion (2006) VR - Start in VR' -ForegroundColor Cyan
    Write-Host ('='*60) -ForegroundColor Magenta
    Write-Host ''
}

function Start-OBSteamVR {
    if(Get-Process vrserver -ErrorAction SilentlyContinue){return}
    Write-Host '  Starting SteamVR, required by the OBVR OpenVR runtime...' -ForegroundColor White
    Start-Process 'steam://rungameid/250820'
    $deadline=(Get-Date).AddSeconds(30)
    while((Get-Date) -lt $deadline){
        if(Get-Process vrserver -ErrorAction SilentlyContinue){Start-Sleep -Milliseconds 900;return}
        Start-Sleep -Milliseconds 250
    }
    throw 'SteamVR did not become ready within 30 seconds.'
}

function Start-OBVRGame {
    param([string]$GameRoot)
    $loader=Join-Path $GameRoot 'obse_loader.exe'
    if(-not(Test-Path -LiteralPath $loader -PathType Leaf)){throw 'obse_loader.exe is missing. Reinstall OBVR before retrying.'}
    $before=@(Get-Process Oblivion -ErrorAction SilentlyContinue|ForEach-Object Id)
    Start-Process -FilePath $loader -WorkingDirectory $GameRoot
    $deadline=(Get-Date).AddSeconds(15)
    while((Get-Date) -lt $deadline){
        $game=@(Get-Process Oblivion -ErrorAction SilentlyContinue|Where-Object{$_.Id -notin $before})|Select-Object -First 1
        if($game){return $game}
        Start-Sleep -Milliseconds 250
    }
    throw 'obse_loader.exe did not start Oblivion within 15 seconds.'
}

function Invoke-OblivionVRHubLaunch {
    $root=[IO.Path]::GetFullPath($GameDirectory).TrimEnd('\','/')
    while($true){
        try{
            Write-OBLaunchHeader
            if(Get-Process Oblivion,obse_loader -ErrorAction SilentlyContinue){throw 'Oblivion is already running.'}
            Start-OBSteamVR
            [void](Start-OBVRGame -GameRoot $root)
            Write-Host '  [OK] Oblivion started through OBSE with SteamVR active.' -ForegroundColor Green
            Start-Sleep -Milliseconds 900
            return
        }catch{
            Write-Host ''
            Write-Host '  [XX] Oblivion VR could not be started.' -ForegroundColor Red
            Write-Host ('       '+($_.Exception.Message -replace '[\r\n]+',' ')) -ForegroundColor Yellow
            Write-Host ''
            Write-Host '  OBVR uses OpenVR and requires SteamVR. VDXR is not an' -ForegroundColor Gray
            Write-Host '  alternative runtime for this mod.' -ForegroundColor Gray
            Write-Host ''
            Write-Host '  [R] Retry the complete VR launch' -ForegroundColor Cyan
            Write-Host '  [F] Open the game folder' -ForegroundColor Cyan
            Write-Host '  [Q] Return without launching' -ForegroundColor Cyan
            while($true){
                $choice=([string](Read-Host 'Choice')).Trim().ToUpperInvariant()
                if($choice -eq 'R'){break}
                if($choice -eq 'F'){Start-Process explorer.exe -ArgumentList @($root);continue}
                if($choice -eq 'Q'){return}
                Write-Host '  Choose R, F or Q.' -ForegroundColor Yellow
            }
        }
    }
}

if(((''+$env:PCVR_OBVR_LAUNCH_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-OblivionVRHubLaunch}
