# ============================================================
# R.E.P.O. - RepoXR VR Mod Installer
# ============================================================
#
# Option 1: Current game version - downloads latest RepoXR
# and dependencies from Thunderstore, auto-updates on
# subsequent runs.
#
# Option 2: Older game version - uses a pinned Steam depot
# build with RepoXR 1.1.2.
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "R.E.P.O. VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "REPO"
$GAME_EXE = "REPO.exe"
$STEAM_APP = "3241660"
$TS_COMMUNITY = "repo"

$PACKAGES_CURRENT = @(
 @{ Author="BepInEx"; Name="BepInExPack"; FriendlyName="BepInEx" },
 @{ Author="DaXcess"; Name="FixPluginTypesSerialization"; FriendlyName="FixPluginTypesSerialization" },
 @{ Author="DaXcess"; Name="RepoXR"; FriendlyName="RepoXR" }
)

$DEPOT_APPID = "3241660"
$DEPOT_DEPOTID = "3241661"
$DEPOT_MANIFEST = "180069324351455863"
$DEPOT_COMMAND = "download_depot $DEPOT_APPID $DEPOT_DEPOTID $DEPOT_MANIFEST"
$TARGET_NAME = "REPO VR"
$DEFAULT_PARENT = "C:\Games"
$DEFAULT_PATH = Join-Path $DEFAULT_PARENT $TARGET_NAME

$LEGACY_URLS = @{
 BepInEx = "https://thunderstore.io/package/download/BepInEx/BepInExPack/5.4.2304/"
 FPTS = "https://thunderstore.io/package/download/DaXcess/FixPluginTypesSerialization/1.1.0/"
 RepoXR = "https://thunderstore.io/package/download/DaXcess/RepoXR/1.1.2/"
}
$LEGACY_REPOXR_VERSION = "1.1.2"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " R.E.P.O. - RepoXR VR Mod Installer" -ForegroundColor Cyan
 Write-Host " by DaXcess | via Thunderstore" -ForegroundColor Gray
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host ""
}
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($r in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try { $p=(Get-ItemProperty -Path $r -EA Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
 }; return $null
}
function Get-SteamLibraries { param($sp)
 $libs=@($sp); $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
 if(Test-Path $vdf){ [regex]::Matches((Get-Content $vdf -Raw),'"path"\s+"([^"]+)"') | ForEach-Object {
 $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
 return $libs
}
function Get-InstalledVersion { param($packageName,$gamePath)
 $f=Join-Path $gamePath "BepInEx\.ts_versions\$packageName"
 if(Test-Path $f){return (Get-Content $f -Raw).Trim()}; return $null
}
function Set-InstalledVersion { param($packageName,$version,$gamePath)
 $d=Join-Path $gamePath "BepInEx\.ts_versions"
 if(-not(Test-Path $d)){New-Item -ItemType Directory -Path $d|Out-Null}
 Set-Content (Join-Path $d $packageName) $version -Encoding UTF8
}
function Get-TSPackageInfo { param($author,$name)
 $apiUrls = @(
   "https://thunderstore.io/api/experimental/package/$author/$name/",
   "https://web.archive.org/web/0/https://thunderstore.io/api/experimental/package/$author/$name/"
 )
 foreach ($u in $apiUrls) {
   try {
     $r = Invoke-WebRequest -Uri $u -UseBasicParsing -EA Stop
     $d = $r.Content | ConvertFrom-Json
     return @{ Version=$d.latest.version_number; DownloadUrl=$d.latest.download_url; Deprecated=$d.is_deprecated }
   } catch { }
 }
 return $null
}
function Get-Zip { param($name,$url,$dest)
 $sources = @($url, "https://web.archive.org/web/0/$url")
 foreach ($u in $sources) {
   Write-Host " Downloading $name from $u ... " -NoNewline -ForegroundColor White
   try {
     Invoke-WebRequest -Uri $u -OutFile $dest -UseBasicParsing -EA Stop
     Write-Host "OK" -ForegroundColor Green
     return $true
   } catch {
     Write-Host "FAILED" -ForegroundColor Red
   }
 }
 $r = Invoke-InstallerFallback `
        -Action "$name download" `
        -Url "https://thunderstore.io/c/repo/" `
        -Instructions "Find '$name' on the Thunderstore page that just opened, download the latest ZIP, place it at '$dest', then choose Retry." `
        -SkipMessage "Skipped - $name was not downloaded; install is incomplete (questionable result)." `
        -DestFolder (Split-Path "$dest" -Parent) `
        -AllowSkip $true
 if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 return ((Test-Path $dest) -and ((Get-Item $dest).Length -gt 0))
}
function Install-Pkg { param($zip,$dest,$gamePath)
 Expand-Archive -Path $zip -DestinationPath $dest -Force
 $skip=@("manifest.json","icon.png","README.md","CHANGELOG.md","LICENSE")
 $top=@(Get-ChildItem $dest|Where-Object{$_.Name -notin $skip})
 $payload=if($top.Count -eq 1 -and $top[0].PSIsContainer -and $top[0].Name -ne "BepInEx"){$top[0].FullName}else{$dest}
 Get-ChildItem $payload|Where-Object{$_.Name -notin $skip}|ForEach-Object{Copy-Item $_.FullName $gamePath -Recurse -Force}
}

# -------------------------------------------------------
# STEP 1: Mode selection
# -------------------------------------------------------
Write-Header
Write-Step 1 4 "Select Installation Mode"

$repoXRDeprecated = $false
$repoXRStatus = ""
try {
 $tsInfo = Get-TSPackageInfo -author "DaXcess" -name "RepoXR"
 if ($tsInfo) {
 $repoXRDeprecated = $tsInfo.Deprecated -eq $true
 if ($repoXRDeprecated) { $repoXRStatus = " [DEPRECATED]" } else { $repoXRStatus = " [OK - v$($tsInfo.Version)]" }
 }
} catch {}

if ($repoXRDeprecated) {
 Write-Host " [1] Current game version (auto-updates from Thunderstore)" -ForegroundColor White
 Write-Host " $repoXRStatus" -ForegroundColor Red
} else {
 Write-Host " [1] Current game version (auto-updates from Thunderstore)" -ForegroundColor White
 if ($repoXRStatus) { Write-Host " $repoXRStatus" -ForegroundColor Green }
}
Write-Host ""
# Check whether the legacy depot install already exists at the
# default destination - if so, annotate Option [2] like Option [1]
# already is, so the user can see at a glance which variant is
# present on disk.
$depotInstalledStatus = $null
$depotInstalledColor  = "Gray"
try {
 $depotTargetCheck = Join-Path "C:\Games" "REPO VR"
 $depotExeCheck    = Join-Path $depotTargetCheck "REPO.exe"
 if (Test-Path $depotExeCheck) {
   $depotInstalledStatus = " [installed at $depotTargetCheck]"
   $depotInstalledColor  = "Green"
 } else {
   $depotInstalledStatus = " [not yet installed]"
   $depotInstalledColor  = "Gray"
 }
} catch {}

Write-Host " [2] Older game version (pinned depot / RepoXR 1.1.2)" -ForegroundColor White
if ($depotInstalledStatus) { Write-Host " $depotInstalledStatus" -ForegroundColor $depotInstalledColor }
Write-Host " Use this if the current version above is marked as deprecated." -ForegroundColor White
Write-Host ""
$mode = ""
while ($mode -notin @("1","2")) { $mode = (Read-Host " Choice (1 or 2)").Trim() }
$useLegacy = ($mode -eq "2")

# -------------------------------------------------------
# CURRENT VERSION
# -------------------------------------------------------
if (-not $useLegacy) {

 Write-Step 2 4 "Locating R.E.P.O."
 $gamePath = $null
 $sp = Get-SteamPath
 if ($sp) {
 foreach ($lib in (Get-SteamLibraries $sp)) {
 $c=Join-Path $lib "steamapps\common\$GAME_NAME"
 if(Test-Path(Join-Path $c $GAME_EXE)){$gamePath=$c;Write-Info "Found: $gamePath";break}
 }
 }
 if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "3241660" -SteamFolderNames @("REPO") }
 if (-not $gamePath) {
 Write-Warn "R.E.P.O. not found automatically."
 Write-Host " Enter the game folder:" -ForegroundColor White
 while (-not $gamePath) {
 $r=(Read-Host " Path").Trim().Trim('"')
 if(Test-Path(Join-Path $r $GAME_EXE)){$gamePath=$r;Write-Info "Path set: $gamePath"}else{Write-Fail "REPO.exe not found: $r"}
 }
 }

 Write-Step 3 4 "Checking Thunderstore for latest versions"
 $packageInfos=@{}; $toInstall=@()
 foreach ($pkg in $PACKAGES_CURRENT) {
 $key="$($pkg.Author)-$($pkg.Name)"
 $installed=Get-InstalledVersion -packageName $key -gamePath $gamePath
 Write-Host " $($pkg.FriendlyName) ... " -NoNewline -ForegroundColor White
 $info=Get-TSPackageInfo -author $pkg.Author -name $pkg.Name
 if ($info) {
 $packageInfos[$key]=$info
 if($installed -eq $info.Version){Write-Host "up to date ($($info.Version))" -ForegroundColor Green}
 elseif($installed){Write-Host "update: $installed -> $($info.Version)" -ForegroundColor Yellow;$toInstall+=$pkg}
 else{Write-Host "not installed ($($info.Version))" -ForegroundColor Cyan;$toInstall+=$pkg}
 } else {
 Write-Host "could not check" -ForegroundColor Gray
 if(-not $installed){$toInstall+=$pkg}
 }
 }

 if ($toInstall.Count -eq 0) {
 Write-Host ""; Write-Host " [OK] All packages are up to date!" -ForegroundColor Green; Write-Host ""
 Pause-User "Press Enter to exit."; exit 0
 }

 Write-Host ""; Write-Host " $($toInstall.Count) package(s) to install/update." -ForegroundColor White
 Write-Step 4 4 "Installing"
 $tmp=Join-Path $env:TEMP "RepoVRInstaller_$([System.IO.Path]::GetRandomFileName())"
 New-Item -ItemType Directory -Path $tmp|Out-Null
 $failed=@()
 foreach ($pkg in $toInstall) {
 $key="$($pkg.Author)-$($pkg.Name)"; $info=$packageInfos[$key]
 if(-not $info){$failed+=$pkg.FriendlyName;continue}
 $zipDest="$tmp\$key.zip"
 if(-not(Get-Zip "$($pkg.FriendlyName) $($info.Version)" $info.DownloadUrl $zipDest)){$failed+=$pkg.FriendlyName;continue}
 Install-Pkg $zipDest "$tmp\$key" $gamePath
 Set-InstalledVersion -packageName $key -version $info.Version -gamePath $gamePath
 Write-Info "$($pkg.FriendlyName) $($info.Version) installed."
 }
 try{Remove-Item $tmp -Recurse -Force -EA SilentlyContinue}catch{}
 try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
 $repoXRVersion = Get-InstalledVersion -packageName "DaXcess-RepoXR" -gamePath $gamePath

} else {

 # -------------------------------------------------------
 # LEGACY VERSION - Steam depot
 # -------------------------------------------------------
 Write-Step 2 4 "Steam Depot Download"

 Write-Host " RepoXR 1.1.2 requires a specific older version of R.E.P.O." -ForegroundColor White
 Write-Host " We download it as a separate copy - your retail install stays untouched." -ForegroundColor White
 Write-Host ""
 try { Set-Clipboard -Value $DEPOT_COMMAND } catch {}

 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host " ACTION REQUIRED - Paste into Steam Console" -ForegroundColor Yellow
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host ""
 Write-Host " [OK] Depot command copied to clipboard." -ForegroundColor Yellow
 Write-Host ""
 Write-Host " Press Enter to open the Steam Console..." -ForegroundColor Yellow
 Write-Host " Then click the input field, paste (Ctrl+V) and hit Enter." -ForegroundColor Yellow
 Write-Host ""
 Write-Host ""
 if (Get-Process -Name 'VirtualDesktop.Streamer','VirtualDesktop.Server' -ErrorAction SilentlyContinue) {
 Write-Host " (i) Virtual Desktop users: the Steam Console may not open" -ForegroundColor DarkGray
 Write-Host "     automatically from inside a VD streaming session. If it" -ForegroundColor DarkGray
 Write-Host "     doesn't, open it manually: Steam menu bar - View - Console," -ForegroundColor DarkGray
 Write-Host "     then paste-and-Enter. Alternatively, choose [3] in the" -ForegroundColor DarkGray
 Write-Host "     next menu to use the DepotDownloader fallback." -ForegroundColor DarkGray
 Write-Host ""
 }
 Pause-User "Press Enter to open the Steam Console..."
 Start-Process "steam://nav/console"
 Pause-User "Press Enter once the Steam depot download is complete..."

 $sp = Get-SteamPath
 $depotPath = $null
 $probePaths = @()
 foreach ($lib in (Get-SteamLibraries $sp)) {
 $auto=Join-Path $lib "steamapps\content\app_$DEPOT_APPID\depot_$DEPOT_DEPOTID"
 $probePaths += $auto
 if(Test-Path $auto){$depotPath=$auto;Write-Info "Depot found: $depotPath";break}
 }
 if (-not $depotPath) {
 $depotPath = Resolve-DepotPath -GameName "R.E.P.O." -DepotCommand $DEPOT_COMMAND -GameExe $GAME_EXE -ProbePaths $probePaths -AppId $DEPOT_APPID -DepotId $DEPOT_DEPOTID -Manifest $DEPOT_MANIFEST
 if (-not $depotPath) {
 Write-Fail "No depot folder provided."
 Pause-User "Press Enter to exit..."
 exit 1
 }
 }

 Write-Step 3 4 "Moving to stable folder"

 Write-Host " Default install location: $DEFAULT_PATH" -ForegroundColor Gray
 Write-Host " (Recommended. C:\games\ keeps the install off the Steam" -ForegroundColor DarkGray
 Write-Host "  library and away from any 'Program Files' UAC weirdness.)" -ForegroundColor DarkGray
 Write-Host ""
 $userInput = (Read-Host " Press Enter to use default, or type a different full path").Trim().Trim('"')
 if (-not $userInput) {
 $targetPath = $DEFAULT_PATH
 } else {
 $targetPath = $userInput
 }

 $targetParent = Split-Path $targetPath -Parent
 if ($targetParent -and -not (Test-Path $targetParent)) {
 try { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
 catch { Write-Fail "Could not create parent folder $targetParent : $_"; Pause-User "Press Enter to exit..."; exit 1 }
 }

 if (Test-Path $targetPath) {
 Write-Warn "Folder already exists: $targetPath"
 Write-Host " [Y] Delete and reinstall [N] Abort" -ForegroundColor White
 $ch=""; while($ch -notin @("y","Y","n","N")){$ch=(Read-Host " Choice").Trim()}
 if($ch -in @("n","N")){Pause-User "Press Enter to exit...";exit 0}
 Remove-Item $targetPath -Recurse -Force
 }
 Move-Item -Path $depotPath -Destination $targetPath -EA Stop
 Write-Info "Moved to: $targetPath"
 try{$pd=Split-Path $depotPath -Parent;if((Get-ChildItem $pd -Force|Measure-Object).Count -eq 0){Remove-Item $pd -Force}}catch{}
 $gamePath = $targetPath

 # MANDATORY: steam_appid.txt next to the EXE. Without this, Steam
 # intercepts the EXE launch and prompts to install the game.
 try { Set-Content -Path (Join-Path $gamePath "steam_appid.txt") -Value $DEPOT_APPID -Encoding ASCII -NoNewline -Force } catch {}

 Write-Step 4 4 "Installing RepoXR 1.1.2"
 $tmp=Join-Path $env:TEMP "RepoVRInstaller_$([System.IO.Path]::GetRandomFileName())"
 New-Item -ItemType Directory -Path $tmp|Out-Null
 $failed=@()

 if(Get-Zip "BepInEx 5.4.2304" $LEGACY_URLS.BepInEx "$tmp\bep.zip"){
 Install-Pkg "$tmp\bep.zip" "$tmp\bep" $gamePath
 if(Test-Path(Join-Path $gamePath "winhttp.dll")){Write-Info "BepInEx OK."}else{$failed+="BepInEx"}
 }else{$failed+="BepInEx"}

 if(Get-Zip "FixPluginTypesSerialization 1.1.0" $LEGACY_URLS.FPTS "$tmp\fpts.zip"){
 Install-Pkg "$tmp\fpts.zip" "$tmp\fpts" $gamePath
 Write-Info "FixPluginTypesSerialization OK."
 }else{$failed+="FixPluginTypesSerialization"}

 if(Get-Zip "RepoXR 1.1.2" $LEGACY_URLS.RepoXR "$tmp\repo.zip"){
 Install-Pkg "$tmp\repo.zip" "$tmp\repo" $gamePath
 if(Test-Path(Join-Path $gamePath "BepInEx\plugins\RepoXR\RepoXR.dll")){Write-Info "RepoXR OK."}else{$failed+="RepoXR"}
 }else{$failed+="RepoXR"}

 try{Remove-Item $tmp -Recurse -Force -EA SilentlyContinue}catch{}
 try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {}
 $repoXRVersion = $LEGACY_REPOXR_VERSION

 # Desktop shortcut for Mode 2 - same pattern as other DepotInstall
 # games. We launch REPO.exe directly from C:\Games\REPO VR\ with
 # the checksum-skip launch arg baked in, so the user doesn't need
 # to set a Steam launch option (which would apply to the retail
 # install in steamapps\common\REPO instead of this legacy depot).
 $repoExe = Join-Path $gamePath $GAME_EXE
 if (Test-Path $repoExe) {
 try {
 $desktopPath = [Environment]::GetFolderPath("Desktop")
 $wsh = New-Object -ComObject WScript.Shell
 $sc = $wsh.CreateShortcut((Join-Path $desktopPath "REPO VR.lnk"))
 $sc.TargetPath = $repoExe
 $sc.WorkingDirectory = $gamePath
 $sc.Arguments = "--repoxr-skip-checksum=$LEGACY_REPOXR_VERSION"
 $sc.Description = "R.E.P.O. VR (RepoXR 1.1.2 legacy build)"
 $sc.IconLocation = "$repoExe,0"
 $sc.Save()
 Write-Info "Desktop shortcut created: REPO VR"
 } catch {
 Write-Warn "Could not create shortcut: $_"
 }
 }
}

# Launch option - only for Mode 1 (current Steam-native install).
# Mode 2 already has a desktop shortcut with the launch arg baked in,
# so the user doesn't need to set a Steam launch option.
if (-not $useLegacy -and $repoXRVersion) {
 $launchOpt = "--repoxr-skip-checksum=$repoXRVersion"
 try{Set-Clipboard -Value $launchOpt}catch{}
 Write-Host ""
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host " ACTION REQUIRED - Steam Launch Option" -ForegroundColor Yellow
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host ""
 Write-Host " [OK] Launch parameter copied to clipboard." -ForegroundColor Yellow
 Write-Host ""
 Write-Host " (--repoxr-skip-checksum=$repoXRVersion)" -ForegroundColor Gray
 Write-Host ""
 Write-Host " Press Enter to open Steam Launch Options..." -ForegroundColor Yellow
 Write-Host " Then paste (Ctrl+V) and close Properties." -ForegroundColor Yellow
 Write-Host ""
 Pause-User "Press Enter to open Steam Launch Options..."
 Start-Process "steam://gameproperties/$STEAM_APP"
 try{Set-Clipboard -Value $launchOpt}catch{}
 Pause-User "Press Enter once you have pasted the launch option and closed Properties..."
}

# Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
if ($useLegacy) {
 foreach ($m in @("BepInEx","FixPluginTypesSerialization","RepoXR")) {
 if($m -notin $failed){Write-Host " [x] $m" -ForegroundColor Green}
 else{Write-Host " [ ] $m -- FAILED" -ForegroundColor Red}
 }
} else {
 foreach ($pkg in $PACKAGES_CURRENT) {
 $key="$($pkg.Author)-$($pkg.Name)"
 $v=Get-InstalledVersion -packageName $key -gamePath $gamePath
 if($v){Write-Host " [x] $($pkg.FriendlyName) $v" -ForegroundColor Green}
 else{Write-Host " [ ] $($pkg.FriendlyName) -- FAILED" -ForegroundColor Red}
 }
}
Write-Host ""
Write-Host " Start SteamVR before launching R.E.P.O." -ForegroundColor White
Write-Host " Launch the game via Steam normally." -ForegroundColor White
Write-Host ""
Write-Host " Issues: https://github.com/DaXcess/RepoXR" -ForegroundColor Gray
Write-Host ""
Write-Host " Ready to extract valuables. In VR." -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
