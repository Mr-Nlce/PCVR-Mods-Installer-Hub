# ============================================================
# Lethal Company - LCVR Installer
# ============================================================
#
# Option 1 (default): Current game version - downloads latest
# LCVR and dependencies from Thunderstore, auto-updates on
# subsequent runs.
#
# Option 2 (legacy): Older game version - uses the existing
# pinned setup with Steam branch switch to 'previous'.
# ============================================================


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Lethal Company VR Installer"
$ErrorActionPreference = "Stop"

$GAME_NAME = "Lethal Company"
$GAME_EXE = "Lethal Company.exe"
$STEAM_APP = "1966720"

$PACKAGES_CURRENT = @(
 @{ Author="BepInEx"; Name="BepInExPack"; FriendlyName="BepInEx" },
 @{ Author="Evaisa"; Name="FixPluginTypesSerialization"; FriendlyName="FixPluginTypesSerialization" },
 @{ Author="Hamunii"; Name="TypeLoadExceptionFixer"; FriendlyName="TypeLoadExceptionFixer" },
 @{ Author="DaXcess"; Name="LethalCompanyVR"; FriendlyName="LethalCompanyVR" }
)

$LEGACY_URLS = @{
 BepInEx = "https://thunderstore.io/package/download/BepInEx/BepInExPack/5.4.2100/"
 MonoDet = "https://thunderstore.io/package/download/MonoDetour/MonoDetour/0.7.13/"
 MonoDet5 = "https://thunderstore.io/package/download/MonoDetour/MonoDetour_BepInEx_5/0.7.13/"
 FPTS = "https://thunderstore.io/package/download/Evaisa/FixPluginTypesSerialization/1.1.4/"
 TLEF = "https://thunderstore.io/package/download/Hamunii/TypeLoadExceptionFixer/1.0.4/"
 LCVR = "https://thunderstore.io/package/download/DaXcess/LethalCompanyVR/1.4.6/"
}
$LEGACY_LCVR_VERSION = "1.4.6"

function Write-Header {
 Clear-Host
 Write-Host "============================================================" -ForegroundColor Magenta
 Write-Host " Lethal Company - LCVR VR Installer" -ForegroundColor Cyan
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
function Get-InstalledVersion { param($key,$gp)
 $f=Join-Path $gp "BepInEx\.ts_versions\$key"
 if(Test-Path $f){return (Get-Content $f -Raw).Trim()}; return $null
}
function Set-InstalledVersion { param($key,$ver,$gp)
 $d=Join-Path $gp "BepInEx\.ts_versions"
 if(-not(Test-Path $d)){New-Item -ItemType Directory -Path $d|Out-Null}
 Set-Content (Join-Path $d $key) $ver -Encoding UTF8
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
     return @{ Version=$d.latest.version_number; DownloadUrl=$d.latest.download_url }
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
        -Url "https://thunderstore.io/c/lethal-company/" `
        -Instructions "Find '$name' on the Thunderstore page that just opened, download the latest ZIP, place it at '$dest', then choose Retry." `
        -SkipMessage "Skipped - $name was not downloaded; install is incomplete (questionable result)." `
        -DestFolder (Split-Path "$dest" -Parent) `
        -AllowSkip $true
 if ([string]$r -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 return ((Test-Path $dest) -and ((Get-Item $dest).Length -gt 0))
}
function Expand-To { param($zip,$dir)
 if(Test-Path $dir){Remove-Item $dir -Recurse -Force}
 New-Item -ItemType Directory -Path $dir -Force|Out-Null
 Expand-Archive -Path $zip -DestinationPath $dir -Force
}

# -------------------------------------------------------
# STEP 1: Mode selection
# -------------------------------------------------------
Write-Header
Write-Host " LCVR by DaXcess adds full 6DOF VR with hand movement and motion" -ForegroundColor White
Write-Host " controls to Lethal Company. Plays fine in lobbies with non-VR players." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
# Check the dependencies of the dependencies. Our package list only
# knows the DIRECT level; Thunderstore knows what those packages require
# in turn. Changes nothing, only reports - see PEAK, where exactly this
# was missing.
try {
    $tsMissing = @(Test-ThunderstoreDependencies -PackageUrls @($LEGACY_URLS.Values))
    Show-ThunderstoreDependencyWarning -Missing $tsMissing
} catch {}

Write-Step 1 4 "Select Installation Mode"

# Check Thunderstore for deprecated status
$lcvrDeprecated = $false
$lcvrStatus = ""
$lcvrDeprecated = $false
$lcvrVersion = ""
foreach ($u in @("https://thunderstore.io/api/experimental/package/DaXcess/LethalCompanyVR/",
                 "https://web.archive.org/web/0/https://thunderstore.io/api/experimental/package/DaXcess/LethalCompanyVR/")) {
  try {
    $tsInfo = Invoke-WebRequest -Uri $u -UseBasicParsing -EA Stop
    $tsData = $tsInfo.Content | ConvertFrom-Json
    $lcvrDeprecated = $tsData.is_deprecated -eq $true
    $lcvrVersion = $tsData.latest.version_number
    if ($lcvrDeprecated) { $lcvrStatus = " [DEPRECATED]" } else { $lcvrStatus = " [OK - v$lcvrVersion]" }
    break
  } catch { }
}

if ($lcvrDeprecated) {
 Write-Host " [1] Current game version (auto-updates from Thunderstore)" -ForegroundColor White
 Write-Host " $lcvrStatus" -ForegroundColor Yellow
 Write-Host " Mod is deprecated - current game version may not work." -ForegroundColor Gray
} else {
 Write-Host " [1] Current game version (auto-updates from Thunderstore)" -ForegroundColor White
 Write-Host " $lcvrStatus" -ForegroundColor Green
}
Write-Host ""
# Check whether the legacy depot install already exists at the
# default destination - annotate Option [2] like Option [1].
$depotInstalledStatus = $null
$depotInstalledColor  = "Gray"
try {
 $depotTargetCheck = Join-Path "C:\Games" "Lethal Company VR"
 $depotExeCheck    = Join-Path $depotTargetCheck "Lethal Company.exe"
 if (Test-Path $depotExeCheck) {
   $depotInstalledStatus = " [installed at $depotTargetCheck]"
   $depotInstalledColor  = "Green"
 } else {
   $depotInstalledStatus = " [not yet installed]"
   $depotInstalledColor  = "Gray"
 }
} catch {}

Write-Host " [2] Older game version (pinned LCVR 1.4.6 / V73)" -ForegroundColor White
if ($depotInstalledStatus) { Write-Host " $depotInstalledStatus" -ForegroundColor $depotInstalledColor }
Write-Host " Use this if the current version above is marked as deprecated." -ForegroundColor White
Write-Host ""
$mode = ""
while ($mode -notin @("1","2")) { $mode = (Read-Host " Choice (1 or 2)").Trim() }
$useLegacy = ($mode -eq "2")

# -------------------------------------------------------
# STEP 2: Locate game
# -------------------------------------------------------
Write-Step 2 4 "Locating Lethal Company"

$gamePath = $null
$sp = Get-SteamPath
if ($sp) {
 foreach ($lib in (Get-SteamLibraries $sp)) {
 $c=Join-Path $lib "steamapps\common\$GAME_NAME"
 if(Test-Path (Join-Path $c $GAME_EXE)){$gamePath=$c; Write-Info "Found: $gamePath"; break}
 }
}
if (-not $gamePath) { $gamePath = Find-SteamGameFolder -AppId "1966720" -SteamFolderNames @("Lethal Company") }
if (-not $gamePath) {
 Write-Warn "Lethal Company not found automatically."
 Write-Host " Enter the game folder (containing Lethal Company.exe):" -ForegroundColor White
 while (-not $gamePath) {
 $r=(Read-Host " Path").Trim().Trim('"')
 if(Test-Path (Join-Path $r $GAME_EXE)){$gamePath=$r;Write-Info "Path set: $gamePath"}else{Write-Fail "Not found: $r"}
 }
}

$tmp = Join-Path $env:TEMP "LCVR_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tmp | Out-Null

# -------------------------------------------------------
# CURRENT VERSION
# -------------------------------------------------------
if (-not $useLegacy) {
 Write-Step 3 4 "Checking Thunderstore for latest versions"

 $packageInfos = @{}
 $toInstall = @()

 foreach ($pkg in $PACKAGES_CURRENT) {
 $key = "$($pkg.Author)-$($pkg.Name)"
 $installed = Get-InstalledVersion -key $key -gp $gamePath
 Write-Host " $($pkg.FriendlyName) ... " -NoNewline -ForegroundColor White
 $info = Get-TSPackageInfo -author $pkg.Author -name $pkg.Name
 if ($info) {
 $packageInfos[$key] = $info
 if ($installed -eq $info.Version) {
 Write-Host "up to date ($($info.Version))" -ForegroundColor Green
 } elseif ($installed) {
 Write-Host "update: $installed -> $($info.Version)" -ForegroundColor Yellow; $toInstall += $pkg
 } else {
 Write-Host "not installed ($($info.Version))" -ForegroundColor Cyan; $toInstall += $pkg
 }
 } else {
 Write-Host "could not check" -ForegroundColor Gray
 if (-not $installed) { $toInstall += $pkg }
 }
 }

 if ($toInstall.Count -eq 0) {
 Write-Host ""; Write-Host " [OK] All packages are up to date!" -ForegroundColor Green; Write-Host ""
 Pause-User "Press Enter to exit."
 try{Remove-Item $tmp -Recurse -Force -EA SilentlyContinue}catch{}; exit 0
 }

 Write-Host ""; Write-Host " $($toInstall.Count) package(s) to install/update." -ForegroundColor White
 Write-Step 4 4 "Installing"
 $failed = @()

 foreach ($pkg in $toInstall) {
 $key="$($pkg.Author)-$($pkg.Name)"; $info=$packageInfos[$key]
 if (-not $info) { $failed+=$pkg.FriendlyName; continue }
 if (-not (Get-Zip "$($pkg.FriendlyName) $($info.Version)" $info.DownloadUrl "$tmp\$key.zip")) { $failed+=$pkg.FriendlyName; continue }
 $ext="$tmp\$key"; Expand-To "$tmp\$key.zip" $ext
 $children=@(Get-ChildItem $ext | Where-Object { $_.Name -notin @("manifest.json","icon.png","README.md","CHANGELOG.md","LICENSE") })
 $payload=if($children.Count -eq 1 -and $children[0].PSIsContainer -and $children[0].Name -ne "BepInEx"){$children[0].FullName}else{$ext}
 $skip=@("manifest.json","icon.png","README.md","CHANGELOG.md","LICENSE")
 Get-ChildItem $payload|Where-Object{$_.Name -notin $skip}|ForEach-Object{Copy-Item $_.FullName $gamePath -Recurse -Force}
 Set-InstalledVersion -key $key -ver $info.Version -gp $gamePath
 Write-Info "$($pkg.FriendlyName) $($info.Version) installed."
 }

 $lcvrVersion = Get-InstalledVersion -key "DaXcess-LethalCompanyVR" -gp $gamePath

} else {
 # -------------------------------------------------------
 # LEGACY VERSION
 # -------------------------------------------------------
 Write-Step 3 4 "Installing pinned packages (LCVR 1.4.6 / V73)"
 $failed = @()

 if(Get-Zip "BepInEx 5.4.2100" $LEGACY_URLS.BepInEx "$tmp\bep.zip"){
 Expand-To "$tmp\bep.zip" "$tmp\bep"
 $inner=Get-ChildItem "$tmp\bep" -Directory -Recurse|Where-Object{Test-Path(Join-Path $_.FullName "winhttp.dll")}|Select-Object -First 1
 $src=if($inner){$inner.FullName}else{"$tmp\bep"}
 Get-ChildItem $src|Where-Object{$_.Name -notin @("icon.png","manifest.json","README.md","CHANGELOG.md","LICENSE")}|ForEach-Object{Copy-Item $_.FullName $gamePath -Recurse -Force}
 if(Test-Path(Join-Path $gamePath "winhttp.dll")){Write-Info "BepInEx OK."}else{$failed+="BepInEx"}
 }else{$failed+="BepInEx"}

 if(Get-Zip "MonoDetour 0.7.13" $LEGACY_URLS.MonoDet "$tmp\md.zip"){
 Expand-To "$tmp\md.zip" "$tmp\md"
 $dest=Join-Path $gamePath "BepInEx\core\MonoDetour-MonoDetour"; New-Item $dest -ItemType Directory -Force|Out-Null
 $src=if(Test-Path "$tmp\md\core"){"$tmp\md\core"}else{"$tmp\md"}
 Get-ChildItem $src -Filter "*.dll"|ForEach-Object{Copy-Item $_.FullName $dest -Force}
 Write-Info "MonoDetour OK."
 }else{$failed+="MonoDetour"}

 if(Get-Zip "MonoDetour_BepInEx_5 0.7.13" $LEGACY_URLS.MonoDet5 "$tmp\md5.zip"){
 Expand-To "$tmp\md5.zip" "$tmp\md5"
 if(Test-Path "$tmp\md5\core"){$dest=Join-Path $gamePath "BepInEx\core\MonoDetour-MonoDetour_BepInEx_5";New-Item $dest -ItemType Directory -Force|Out-Null;Get-ChildItem "$tmp\md5\core" -Filter "*.dll"|ForEach-Object{Copy-Item $_.FullName $dest -Force}}
 if(Test-Path "$tmp\md5\patchers"){$dest=Join-Path $gamePath "BepInEx\patchers\MonoDetour-MonoDetour_BepInEx_5";New-Item $dest -ItemType Directory -Force|Out-Null;Get-ChildItem "$tmp\md5\patchers" -Filter "*.dll"|ForEach-Object{Copy-Item $_.FullName $dest -Force}}
 Write-Info "MonoDetour_BepInEx_5 OK."
 }else{$failed+="MonoDetour_BepInEx_5"}

 if(Get-Zip "FixPluginTypesSerialization 1.1.4" $LEGACY_URLS.FPTS "$tmp\fpts.zip"){
 Expand-To "$tmp\fpts.zip" "$tmp\fpts"
 $dest=Join-Path $gamePath "BepInEx\patchers\Evaisa-FixPluginTypesSerialization\FixPluginTypesSerialization";New-Item $dest -ItemType Directory -Force|Out-Null
 Get-ChildItem "$tmp\fpts" -Filter "*.dll" -Recurse|ForEach-Object{Copy-Item $_.FullName $dest -Force}
 Write-Info "FixPluginTypesSerialization OK."
 }else{$failed+="FixPluginTypesSerialization"}

 if(Get-Zip "TypeLoadExceptionFixer 1.0.4" $LEGACY_URLS.TLEF "$tmp\tlef.zip"){
 Expand-To "$tmp\tlef.zip" "$tmp\tlef"
 $dest=Join-Path $gamePath "BepInEx\patchers\Hamunii-TypeLoadExceptionFixer";New-Item $dest -ItemType Directory -Force|Out-Null
 Get-ChildItem "$tmp\tlef" -Filter "*.dll" -Recurse|ForEach-Object{Copy-Item $_.FullName $dest -Force}
 Write-Info "TypeLoadExceptionFixer OK."
 }else{$failed+="TypeLoadExceptionFixer"}

 if(Get-Zip "LCVR 1.4.6" $LEGACY_URLS.LCVR "$tmp\lcvr.zip"){
 Expand-To "$tmp\lcvr.zip" "$tmp\lcvr"
 $bep="$tmp\lcvr\BepInEx"
 if(Test-Path $bep){
 $ps="$bep\patchers\LCVR";$pd=Join-Path $gamePath "BepInEx\patchers\DaXcess-LethalCompanyVR\LCVR"
 if(Test-Path $ps){New-Item $pd -ItemType Directory -Force|Out-Null;Copy-Item "$ps\*" $pd -Recurse -Force}
 $pls="$bep\plugins\LCVR";$pld=Join-Path $gamePath "BepInEx\plugins\DaXcess-LethalCompanyVR\LCVR"
 if(Test-Path $pls){New-Item $pld -ItemType Directory -Force|Out-Null;Copy-Item "$pls\*" $pld -Recurse -Force}
 if(Test-Path(Join-Path $pld "LCVR.dll")){Write-Info "LCVR OK."}else{$failed+="LCVR"}
 }else{$failed+="LCVR"}
 }else{$failed+="LCVR"}

 $lcvrVersion = $LEGACY_LCVR_VERSION

 Write-Host ""
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host " ACTION REQUIRED - Switch Steam Branch to 'previous'" -ForegroundColor Yellow
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host ""
 Write-Host " LCVR 1.4.6 requires Lethal Company V73 (previous branch)." -ForegroundColor White
 Write-Host ""
 Write-Host " 1) Go to the Betas tab" -ForegroundColor White
 Write-Host " 2) Under Beta Participation, select: previous" -ForegroundColor White
 Write-Host " 3) Wait for Steam to download, then close Properties" -ForegroundColor White
 Write-Host ""
 Write-Host " Press Enter to open Lethal Company properties in Steam..." -ForegroundColor Yellow
 Write-Host ""
 Pause-User "Press Enter to open Lethal Company properties in Steam..."
 Start-Process "steam://gameproperties/$STEAM_APP"
 Pause-User "Press Enter once you have switched to the previous branch..."
}

try{Remove-Item $tmp -Recurse -Force -EA SilentlyContinue}catch{}

# Launch option
if ($lcvrVersion) {
 $launchOpt = "--lcvr-skip-checksum=$lcvrVersion"
 try{Set-Clipboard -Value $launchOpt}catch{}
 Write-Host ""
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host " ACTION REQUIRED - Steam Launch Option" -ForegroundColor Yellow
 Write-Host " ============================================================" -ForegroundColor Yellow
 Write-Host ""
 Write-Host " [OK] Launch parameter copied to clipboard." -ForegroundColor Yellow
 Write-Host ""
 Write-Host " (--lcvr-skip-checksum=$lcvrVersion)" -ForegroundColor Gray
 Write-Host ""
 Write-Host " Press Enter to open Steam Launch Options..." -ForegroundColor Yellow
 Write-Host " Then paste (Ctrl+V) and close Properties." -ForegroundColor Yellow
 Write-Host ""
 Pause-User "Press Enter to open Steam Launch Options..."
 Start-Process "steam://gameproperties/$STEAM_APP"
 try{Set-Clipboard -Value $launchOpt}catch{}
 Pause-User "Press Enter once you have pasted the launch option and closed Properties..."
}

# Record install path for the post-install VR-Ready refresh (no full scan needed).
if ("LCVR" -notin $failed) { try { Set-Content -Path (Join-Path $PSScriptRoot ".installed_path") -Value $gamePath -Encoding UTF8 -Force } catch {} }

# Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
if ($useLegacy) {
 foreach ($m in @("BepInEx","MonoDetour","MonoDetour_BepInEx_5","FixPluginTypesSerialization","TypeLoadExceptionFixer","LCVR")) {
 if($m -notin $failed){Write-Host " [x] $m" -ForegroundColor Green}else{Write-Host " [ ] $m -- FAILED" -ForegroundColor Red}
 }
} else {
 foreach ($pkg in $PACKAGES_CURRENT) {
 $key="$($pkg.Author)-$($pkg.Name)"
 $v=Get-InstalledVersion -key $key -gp $gamePath
 if($v){Write-Host " [x] $($pkg.FriendlyName) $v" -ForegroundColor Green}else{Write-Host " [ ] $($pkg.FriendlyName) -- FAILED" -ForegroundColor Red}
 }
}
Write-Host ""
Write-Host " SteamVR Theatre Mode must be OFF:" -ForegroundColor Gray
Write-Host " SteamVR -> Settings -> Dashboard -> 'Present Non-VR Applications...' -> OFF" -ForegroundColor Gray
Write-Host ""
Write-Host " Quota incoming. Watch out for the Eyeless Dog!" -ForegroundColor Magenta
Write-Host ""
Pause-User "Press Enter to exit."
try { Start-Process explorer.exe "`"$gamePath`"" } catch {}
