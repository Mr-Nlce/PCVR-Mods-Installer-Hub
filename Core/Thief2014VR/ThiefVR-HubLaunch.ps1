param([Parameter(Mandatory=$true)][string]$GameDirectory,[string]$RuntimeRoot='')

$ErrorActionPreference='Stop'
$Host.UI.RawUI.WindowTitle='Thief (2014) VR Launcher'
$script:ThiefVRRuntimeRoot=if($RuntimeRoot){[IO.Path]::GetFullPath($RuntimeRoot).TrimEnd('\','/')}elseif(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'configure-stereo.ps1') -PathType Leaf){$PSScriptRoot}else{Join-Path ([IO.Path]::GetFullPath($GameDirectory).TrimEnd('\','/')) 'ThiefVR-HubLauncher'}

function Write-ThiefVRLaunchHeader {
    Clear-Host
    Write-Host ('='*60) -ForegroundColor Magenta
    Write-Host '  Thief (2014) VR - Start in VR' -ForegroundColor Cyan
    Write-Host ('='*60) -ForegroundColor Magenta
    Write-Host ''
}

function Get-ThiefVRDisplayCachePath {
    $root=(''+$env:PCVR_THIEFVR_CACHE_ROOT).Trim()
    if(-not $root){$root=Join-Path $env:LOCALAPPDATA 'PCVR Mods Installer Hub\LauncherState'}
    Join-Path $root 'thief-2014-vr-display.json'
}

function Test-ThiefVRDisplay($Display) {
    if(-not $Display){return $false}
    $w=0;$h=0;$hz=0.0
    [bool]([int]::TryParse((''+$Display.width),[ref]$w) -and
        [int]::TryParse((''+$Display.height),[ref]$h) -and
        [double]::TryParse((''+$Display.refreshHz),[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$hz) -and
        $w -ge 640 -and $w -le 16384 -and $h -ge 480 -and $h -le 8192 -and $hz -ge 0 -and $hz -le 1000)
}

function Read-ThiefVRDisplayCache {
    $path=Get-ThiefVRDisplayCachePath
    if(-not(Test-Path -LiteralPath $path -PathType Leaf)){return $null}
    try{$value=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json;if(Test-ThiefVRDisplay $value){return $value}}catch{}
    return $null
}

function Save-ThiefVRDisplayCache($Display) {
    if(-not(Test-ThiefVRDisplay $Display)){return}
    $path=Get-ThiefVRDisplayCachePath;$dir=Split-Path -Parent $path
    [void][IO.Directory]::CreateDirectory($dir)
    $temp=$path+'.new'
    [IO.File]::WriteAllText($temp,([ordered]@{width=[int]$Display.width;height=[int]$Display.height;refreshHz=[double]$Display.refreshHz}|ConvertTo-Json -Compress),[Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temp -Destination $path -Force
}

function Invoke-ThiefVRNativeCapture([string]$FilePath,[string]$Arguments,[string]$WorkingDirectory,$EnvironmentValues) {
    $psi=New-Object Diagnostics.ProcessStartInfo
    $psi.FileName=$FilePath;$psi.Arguments=$Arguments;$psi.WorkingDirectory=$WorkingDirectory
    $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    if($EnvironmentValues){foreach($key in $EnvironmentValues.Keys){$psi.EnvironmentVariables[$key]=[string]$EnvironmentValues[$key]}}
    $process=New-Object Diagnostics.Process;$process.StartInfo=$psi
    if(-not $process.Start()){throw "Could not start $([IO.Path]::GetFileName($FilePath))."}
    $stdout=$process.StandardOutput.ReadToEnd();$stderr=$process.StandardError.ReadToEnd();$process.WaitForExit()
    [pscustomobject]@{ExitCode=$process.ExitCode;StdOut=$stdout;StdErr=$stderr}
}

function Invoke-ThiefVRDisplayProbe([string]$Tool,[string]$WorkingDirectory) {
    if((''+$env:PCVR_THIEFVR_TEST_DISPLAY) -match '^(\d+)x(\d+)(?:@([0-9.]+))?$'){
        $hz=if($matches[3]){[double]::Parse($matches[3],[Globalization.CultureInfo]::InvariantCulture)}else{72.0}
        return [pscustomobject]@{Success=$true;Display=[pscustomobject]@{width=[int]$matches[1];height=[int]$matches[2];refreshHz=$hz};Error=''}
    }
    try{
        $result=Invoke-ThiefVRNativeCapture -FilePath $Tool -Arguments '' -WorkingDirectory $WorkingDirectory -EnvironmentValues $null
        if($result.ExitCode -eq 0){try{$display=$result.StdOut|ConvertFrom-Json;if(Test-ThiefVRDisplay $display){return [pscustomobject]@{Success=$true;Display=$display;Error=''}}}catch{}}
        $detail=($result.StdErr+' '+$result.StdOut).Trim()
        if(-not $detail){$detail="Headset display query returned exit code $($result.ExitCode)."}
        return [pscustomobject]@{Success=$false;Display=$null;Error=$detail}
    }catch{return [pscustomobject]@{Success=$false;Display=$null;Error=$_.Exception.Message}}
}

function Read-ThiefVRManualDisplay {
    $presets=@(
        [pscustomobject]@{Name='Meta Quest 3';Width=2064;Height=2208},
        [pscustomobject]@{Name='Meta Quest 2 / Quest 3S';Width=1832;Height=1920},
        [pscustomobject]@{Name='Valve Index';Width=1440;Height=1600},
        [pscustomobject]@{Name='HTC Vive';Width=1080;Height=1200},
        [pscustomobject]@{Name='HTC Vive Pro / Pro Eye';Width=1440;Height=1600},
        [pscustomobject]@{Name='HTC Vive Pro 2';Width=2448;Height=2448},
        [pscustomobject]@{Name='HP Reverb G2';Width=2160;Height=2160},
        [pscustomobject]@{Name='Pico 4';Width=2160;Height=2160},
        [pscustomobject]@{Name='PlayStation VR2 on PC';Width=2000;Height=2040},
        [pscustomobject]@{Name='Pimax Crystal';Width=2880;Height=2880}
    )
    while($true){
        Write-Host ''
        Write-Host '  Choose a per-eye headset preset:' -ForegroundColor White
        for($i=0;$i -lt $presets.Count;$i++){Write-Host ("  [{0,2}] {1,-29} {2} x {3}" -f ($i+1),$presets[$i].Name,$presets[$i].Width,$presets[$i].Height) -ForegroundColor Cyan}
        Write-Host '  [M] Enter the exact per-eye runtime size manually' -ForegroundColor Cyan
        Write-Host '  [B] Back to connection recovery' -ForegroundColor Cyan
        $choice=([string](Read-Host 'Choice')).Trim().ToUpperInvariant()
        if($choice -eq 'B'){return $null}
        if($choice -eq 'M'){
            $w=0;$h=0
            [void][int]::TryParse((Read-Host 'Exact per-eye width'),[ref]$w);[void][int]::TryParse((Read-Host 'Exact per-eye height'),[ref]$h)
            if($w -ge 640 -and $w -le 16384 -and $h -ge 480 -and $h -le 8192){return [pscustomobject]@{width=$w;height=$h;refreshHz=0.0}}
            Write-Host '  Enter numeric per-eye values from 640 x 480 to 16384 x 8192.' -ForegroundColor Yellow;continue
        }
        $number=0
        if([int]::TryParse($choice,[ref]$number) -and $number -ge 1 -and $number -le $presets.Count){$p=$presets[$number-1];return [pscustomobject]@{width=$p.Width;height=$p.Height;refreshHz=0.0}}
        Write-Host '  Choose 1-10, M or B.' -ForegroundColor Yellow
    }
}

function Resolve-ThiefVRDisplay([string]$Tool,[string]$WorkingDirectory) {
    while($true){
        $probe=Invoke-ThiefVRDisplayProbe -Tool $Tool -WorkingDirectory $WorkingDirectory
        if($probe.Success){Save-ThiefVRDisplayCache $probe.Display;Write-Host ("  [OK] Headset: {0} x {1} per eye at {2:N1} Hz" -f $probe.Display.width,$probe.Display.height,$probe.Display.refreshHz) -ForegroundColor Green;return $probe.Display}
        $cached=Read-ThiefVRDisplayCache
        Write-Host ''
        Write-Host '  [!!] The active OpenXR runtime did not report a connected headset.' -ForegroundColor Yellow
        Write-Host '       Connect and wake the headset before retrying.' -ForegroundColor Yellow
        if($probe.Error){Write-Host ('       '+($probe.Error -replace '[\r\n]+',' ')) -ForegroundColor DarkGray}
        Write-Host ''
        if($cached){Write-Host ("  [L] Use last successful size: {0} x {1} per eye" -f $cached.width,$cached.height) -ForegroundColor Cyan}
        Write-Host '  [R] Retry the live headset query' -ForegroundColor Cyan
        Write-Host '  [M] Choose a headset preset or enter an exact size' -ForegroundColor Cyan
        Write-Host '  [Q] Return without launching the game' -ForegroundColor Cyan
        $choice=([string](Read-Host 'Choice')).Trim().ToUpperInvariant()
        if($choice -eq 'L' -and $cached){return $cached}
        if($choice -eq 'R'){continue}
        if($choice -eq 'M'){$manual=Read-ThiefVRManualDisplay;if($manual){Save-ThiefVRDisplayCache $manual;return $manual};continue}
        if($choice -eq 'Q'){return $null}
        Write-Host '  Choose a listed recovery action.' -ForegroundColor Yellow
    }
}

function Start-ThiefVR([string]$Directory,$Display) {
    $configure=Join-Path $script:ThiefVRRuntimeRoot 'configure-stereo.ps1';$launcher=Join-Path $script:ThiefVRRuntimeRoot 'dist\ThiefVRLauncher.exe'
    & $configure -GameDirectory $Directory -EyeWidth ([int]$Display.width) -EyeHeight ([int]$Display.height)
    $hz=[int][Math]::Round(([double]$Display.refreshHz)*1000)
    $environment=@{THIEFVR_EYE_WIDTH=[int]$Display.width;THIEFVR_EYE_HEIGHT=[int]$Display.height;THIEFVR_REFRESH_MILLIHZ=$hz}
    $argument='"'+$Directory.Replace('"','\"')+'"'
    $result=Invoke-ThiefVRNativeCapture -FilePath $launcher -Arguments $argument -WorkingDirectory $Directory -EnvironmentValues $environment
    if($result.StdOut.Trim()){Write-Host ('  '+($result.StdOut.Trim() -replace '[\r\n]+',' ')) -ForegroundColor Gray}
    if($result.ExitCode -ne 0){$detail=($result.StdErr+' '+$result.StdOut).Trim();if(-not $detail){$detail="ThiefVRLauncher.exe returned exit code $($result.ExitCode)."};throw $detail}
}

function Invoke-ThiefVRHubLaunch {
    $directory=[IO.Path]::GetFullPath($GameDirectory).TrimEnd('\','/')
    while($true){
        try{
            Write-ThiefVRLaunchHeader
            if(Get-Process Shipping-ThiefGame -ErrorAction SilentlyContinue){throw 'Thief is already running. Close it before retrying.'}
            if(-not(Test-Path -LiteralPath (Join-Path $directory 'Shipping-ThiefGame.exe') -PathType Leaf)){throw "Shipping-ThiefGame.exe is missing from $directory"}
            $query=Join-Path $script:ThiefVRRuntimeRoot 'dist\tools\ThiefVRDisplay.exe'
            $display=Resolve-ThiefVRDisplay -Tool $query -WorkingDirectory $directory
            if(-not $display){return}
            Write-Host '';Write-Host '  Preparing native stereo and launching Thief...' -ForegroundColor White
            Start-ThiefVR -Directory $directory -Display $display
            Write-Host '  [OK] Thief was launched through the required VR bootstrap.' -ForegroundColor Green
            Start-Sleep -Milliseconds 1200
            return
        }catch{
            Write-Host '';Write-Host '  [XX] Thief VR could not be launched.' -ForegroundColor Red
            Write-Host ('       '+($_.Exception.Message -replace '[\r\n]+',' ')) -ForegroundColor Yellow
            Write-Host '';Write-Host '  [R] Retry the complete VR launch' -ForegroundColor Cyan
            Write-Host '  [F] Open the 64-bit game folder' -ForegroundColor Cyan
            Write-Host '  [Q] Return without launching' -ForegroundColor Cyan
            while($true){$choice=([string](Read-Host 'Choice')).Trim().ToUpperInvariant();if($choice -eq 'R'){break};if($choice -eq 'F'){Start-Process explorer.exe -ArgumentList @($directory);continue};if($choice -eq 'Q'){return};Write-Host '  Choose R, F or Q.' -ForegroundColor Yellow}
        }
    }
}

if(((''+$env:PCVR_THIEFVR_LAUNCH_LIBRARY_ONLY).Trim()) -ne '1'){Invoke-ThiefVRHubLaunch}
