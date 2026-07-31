# ============================================================
# Luke Ross R.E.A.L. VR Mod Installer
# ============================================================
param([string]$GameTitle = "")


# Load installer-safety helpers (Invoke-SafeDownload,
# Invoke-InstallerFallback, Get-GameFolderInteractive).
# These replace hard "exit 1" aborts with manual fallback prompts.
. (Join-Path $PSScriptRoot "..\Modules\InstallerSafety.ps1")

$Host.UI.RawUI.WindowTitle = "Luke Ross R.E.A.L. VR Installer"
$ErrorActionPreference = "Stop"

$DOWNLOAD_URL = "https://www.patreon.com/file?h=152405468&m=681279569"
$PATREON_URL = "https://www.patreon.com/posts/152405468"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
# The R.E.A.L. VR mod is ONE universal package that works for every Luke
# Ross game, so once the user has supplied it we keep it centrally in the
# Hub (Core\Assets\Tools\LR VR mod) and reuse it for all ~40 titles - no
# re-download or re-drop per game.
$LR_CACHE_DIR = Join-Path $SCRIPT_DIR "..\Assets\Tools\LR VR mod"
$REAL_VERSION = "v2606"
$LR_CACHE_ZIP = Join-Path $LR_CACHE_DIR ("REALVR_" + $REAL_VERSION + ".zip")
# Older builds cached the zip next to this script; used as a migration source.
$LEGACY_CACHED_ZIP = Join-Path $SCRIPT_DIR "REALVR_cached.zip"

# EXE is found recursively inside Folder - Sub field kept for reference only
$GAMES = @(
 @{ Name = "Atomic Heart"; Folder = "Atomic Heart"; Sub = ""; Exe = "AtomicHeart-Win64-Shipping.exe"; AppId = 668580
 Settings = @(
 "Display Mode -> Windowed Fullscreen"
 "VSync -> Off | HDR -> Disabled | Frame Rate -> Unlimited"
 "Motion Blur -> Off | Film Grain -> Off | Chromatic Aberration -> Off"
 "All Ray Tracing -> Off"
 "Upscaling -> Off or DLSS (if performance allows)"
 )
 Flavor = "Soviet utopia gone red. The twins are watching."
 },
 @{ Name = "Avatar: Frontiers of Pandora"; Folder = "Avatar Frontiers of Pandora"; Sub = ""; Exe = "afop.exe"; AppId = 1802490
 Settings = @(
 "Window Mode -> Windowed | VSync -> Off | HDR -> Off"
 "Upscaler -> DLSS Performance | Frame Generation -> Off"
 "Motion Blur -> Off | Film Grain -> Off | Depth of Field -> Off"
 "Chromatic Aberration -> Off"
 "Camera Animation Intensity -> Low or Off | Center HUD -> On"
 )
 Flavor = "Pandora breathes. So do you. Hunt with the Na'vi."
 },
 @{ Name = "Dark Souls Remastered"; Folder = "DARK SOULS REMASTERED"; AltFolders = @("DARK SOULS REMASTERED"); Sub = ""; Exe = "DarkSoulsRemastered.exe"; AppId = 570940
 Settings = @(
 "Display Mode -> Windowed | VSync -> Off"
 "Anti-Aliasing -> On (only toggle available in this game)"
 "Online Mode -> Play Offline recommended (anti-cheat may flag mod)"
 "NOTE: Game is hard-capped at 60 FPS - this is normal"
 )
 Flavor = "Don't go hollow."
 },
 @{ Name = "Dark Souls II"; Folder = "Dark Souls II Scholar of the First Sin"; Sub = ""; Exe = "DarkSoulsII.exe"; AppId = 335300
 Settings = @(
 "Display Mode -> Windowed | VSync -> Off"
 "Anti-Aliasing -> Off (FXAA causes blur; disable entirely)"
 "Online Mode -> Play Offline recommended"
 "NOTE: Game is hard-capped at 60 FPS - this is normal"
 )
 Flavor = "Bearer of the curse, to Drangleic. Lose yourself, hollow."
 },
 @{ Name = "Dark Souls III"; Folder = "DARK SOULS III"; AltFolders = @("DARK SOULS III"); Sub = "Game"; Exe = "DarkSoulsIII.exe"; AppId = 374320
 Settings = @(
 "Display Mode -> Windowed"
 "VSync CANNOT be disabled in-game - open NVIDIA Control Panel instead:"
 " NVCP -> Manage 3D Settings -> Program Settings -> DarkSoulsIII.exe -> VSync = Off"
 "Motion Blur -> Off | Online Mode -> Offline required"
 "REQUIRED game version: v1.15.2 only - other versions will not work!"
 )
 Flavor = "Ashen one, hearest thou my voice still?"
 },
 @{ Name = "Death Stranding"; Folder = "Death Stranding Directors Cut"; AltFolders = @("Death Stranding Director's Cut"); Sub = ""; Exe = "ds.exe"; AppId = 1850570
 Settings = @(
 "Screen Mode -> Windowed | Aspect Ratio -> 16:9 | VSync -> Off"
 "Maximum Frame Rate -> 240 | DLSS -> Quality, Performance or Ultra Performance"
 "Depth of Field -> Off | Motion Blur -> Off"
 "Controller Auto-Aim -> Off"
 )
 Flavor = "Sam, the cargo, the BTs. Reconnect a broken America."
 },
 @{ Name = "Doom Eternal"; Folder = "DOOMEternal"; Sub = ""; Exe = "DOOMEternalx64vk.exe"; AppId = 782330
 Settings = @(
 "Window Mode -> Windowed | Aspect Ratio -> 16:9 | VSync -> Off | HDR -> Off"
 "Field of View -> 90 | HUD Scale -> Large | Present from Compute -> On"
 "Motion Blur -> Off (Quality Low) | Depth of Field -> Off | Resolution Scaling -> Off"
 "Film Grain -> 0 | Chromatic Aberration -> Off"
 "Aim Assist -> Off | Target Snapping -> Off"
 "DLSS -> Performance, Balanced or Quality | Frame Generation -> Off"
 )
 Flavor = "Slayer's back. Glory kill in 1:1. The hordes recoil."
 },
 @{ Name = "Doom: The Dark Ages"; Folder = "DOOM The Dark Ages"; Sub = ""; Exe = "DOOMTheDarkAges.exe"; AppId = 2239150
 Settings = @(
 "Window Mode -> Windowed | Aspect Ratio -> 16:9 | VSync -> Off"
 "Field of View -> 90 | HUD Scale -> 0.50 | Subtitles Scale -> 1.50"
 "Motion Blur -> Off | Depth of Field -> Off | Chromatic Aberration -> Off | Film Grain -> 0"
 "Environmental Screen Shake -> Off | Aim Assist -> Off"
 "Resolution Scaling -> Off | Reflections Quality -> Off or Low | Frame Generation -> Off"
 )
 Flavor = "Plate, mace, shield-saw. Medieval slaughter, Slayer-style."
 },
 @{ Name = "Elden Ring"; Folder = "ELDEN RING"; AltFolders = @("ELDEN RING"); Sub = "Game"; Exe = "eldenring.exe"; AppId = 1245620
 Settings = @(
 "Screen Mode -> Windowed"
 "Aspect Ratio -> 1:1 ONLY - mod forces square, do not change this"
 "Anti-Aliasing -> High (enables DLSS via ERSS-FG)"
 "Motion Blur -> Off | Depth of Field -> Off | Ray Tracing -> Disabled"
 "Online Mode -> Offline (EAC must be disabled for the mod to work)"
 )
 Flavor = "Become Elden Lord. The Lands Between are waiting."
 },
 @{ Name = "Far Cry 4"; Folder = "Far Cry 4"; Sub = ""; Exe = "FarCry4.exe"; AppId = 298110
 Settings = @(
 "Window Mode -> Windowed (NOT Borderless - zoom bug) | Aspect Ratio -> Auto"
 "VSync -> Off | Motion Blur -> Off | Aim Assist -> Off"
 "Anti-Aliasing -> SMAA (avoid TXAA - blurry in VR)"
 )
 Flavor = "Welcome to Kyrat. Pagan Min sends his regards."
 },
 @{ Name = "Far Cry 5"; Folder = "Far Cry 5"; Sub = ""; Exe = "FarCry5.exe"; AppId = 552520
 Settings = @(
 "Reticle Position -> Offset | Window Mode -> Borderless"
 "Aspect Ratio -> Native 16:9 | VSync -> Off | Frame Rate Lock -> Off"
 "Motion Blur -> Off | Aim Assist -> Off"
 )
 Flavor = "Hope County wasn't asking. The Father is listening."
 },
 @{ Name = "Far Cry 6"; Folder = "Far Cry 6"; Sub = ""; Exe = "FarCry6.exe"; AppId = 933420
 Settings = @(
 "Window Mode -> Borderless (different from other Far Cry games!)"
 "VSync -> Off | Frame Rate Lock -> Off | Motion Blur -> Off"
 "FOV -> 90 | Resolution Scale -> 1.0 (do not touch) | Anti-Aliasing -> TAA"
 "Advanced & Extended Features -> ALL Off (film grain, CA, depth of field)"
 )
 Flavor = "Yara is burning. Castillo's reign ends with you."
 },
 @{ Name = "Far Cry New Dawn"; Folder = "Far Cry New Dawn"; Sub = ""; Exe = "FarCryNewDawn.exe"; AppId = 703220
 Settings = @(
 "Reticle Position -> Offset | Window Mode -> Borderless"
 "Aspect Ratio -> Native 16:9 | VSync -> Off | Frame Rate Lock -> Off"
 "Motion Blur -> Off | Aiming Assists -> Off (re-check every launch)"
 )
 Flavor = "Post-apocalypse pastels. The Highwaymen are ready."
 },
 @{ Name = "Far Cry Primal"; Folder = "Far Cry Primal"; Sub = ""; Exe = "FCPrimal.exe"; AppId = 371970
 Settings = @(
 "Window Mode -> Windowed | Aspect Ratio -> 5:4 | VSync -> Off"
 "FOV Scaling -> 120"
 "Motion Blur -> Off"
 "Aim Assist -> Off | Melee Assist -> Off"
 )
 Flavor = "Fire. Beasts. Bone weapons. Tame the wild, Takkar."
 },
 @{ Name = "FF VII Remake"; Folder = "FINAL FANTASY VII REMAKE"; AltFolders = @("Final Fantasy VII Remake"); Sub = ""; Exe = "ff7remake_.exe"; AppId = 1462040
 Settings = @(
 "Window Mode -> Windowed Borderless | Frame Rate -> Uncapped"
 "Anti-Aliasing -> Keep TAA enabled (hair and materials rely on it)"
 "IMPORTANT: VSync, Motion Blur, Film Grain and DoF must be set via Engine.ini"
 "Path: Documents\My Games\FINAL FANTASY VII REMAKE\Saved\Config\WindowsNoEditor\Engine.ini"
 "Add under [/Script/Engine.RendererSettings]: r.VSync=0 r.MotionBlurQuality=0"
 "Also add: r.Tonemapper.GrainQuantization=0 r.DepthOfFieldQuality=0 r.SceneColorFringeQuality=0"
 )
 Flavor = "Cloud's sword in your hand. Midgar in your eyes."
 },
 @{ Name = "FF VII Rebirth"; Folder = "FINAL FANTASY VII REBIRTH"; AltFolders = @("Final Fantasy VII Rebirth"); Sub = ""; Exe = "ff7rebirth_.exe"; AppId = 2909400
 Settings = @(
 "Window Mode -> Windowed Borderless | Frame Rate -> Uncapped"
 "DLSS -> Quality or Performance | Frame Generation -> Off | Ray Reconstruction -> Off"
 "Ray Tracing -> Off"
 "IMPORTANT: VSync, Motion Blur and Film Grain must be set via Engine.ini"
 "Path: Documents\My Games\FINAL FANTASY VII REBIRTH\Saved\Config\Windows\Engine.ini"
 "Add under [/Script/Engine.RendererSettings]: r.VSync=0 r.MotionBlurQuality=0 t.MaxFPS=0"
 )
 Flavor = "Beyond Midgar at last. Destiny rewrites itself."
 },
 @{ Name = "Ghost of Tsushima"; Folder = "Ghost of Tsushima DIRECTORS CUT"; AltFolders = @("Ghost of Tsushima Director's Cut"); Sub = ""; Exe = "GhostOfTsushima.exe"; AppId = 2215430
 Settings = @(
 "CRITICAL: Disable HDR in Windows Display Settings - not just in-game!"
 "Window Mode -> Windowed (may need multiple restarts to apply) | Aspect Ratio -> 16:9"
 "VSync -> Off | HDR -> Off | Dynamic Resolution Scaling -> Off"
 "DLSS -> Performance | Frame Generation -> Off"
 "Motion Blur Strength -> 0 | Depth of Field -> Off"
 "TIP: Disable Steam overlay if game crashes on R.E.A.L. VR menu open"
 )
 Flavor = "Ride the gold. The Khan landed. Tsushima needs a Ghost."
 },
 @{ Name = "Ghostwire: Tokyo"; Folder = "GhostWire Tokyo"; Sub = ""; Exe = "GWT.exe"; AppId = 1475810
 Settings = @(
 "Window Mode -> Windowed or Borderless | VSync -> Off | HDR -> Off | Frame Rate -> Uncapped"
 "Upscaling -> DLSS recommended (game's built-in TAA is very blurry)"
 "Ray Tracing -> Off"
 "IMPORTANT: Motion Blur, CA and Film Grain must be set via Engine.ini"
 "Path: Documents\My Games\GhostWire Tokyo\Saved\Config\WindowsNoEditor\Engine.ini"
 "Add: r.MotionBlurQuality=0 r.SceneColorFringeQuality=0 r.Tonemapper.GrainQuantization=0 r.Tonemapper.Sharpen=0.8"
 )
 Flavor = "Tokyo, emptied. Spirits everywhere. Hand-weave the visible."
 },
 @{ Name = "Grounded"; Folder = "Grounded"; Sub = ""; Exe = "Maine-Win64-Shipping.exe"; AppId = 962130
 Settings = @(
 "Window Mode -> Windowed | VSync -> Off | HDR -> Off"
 "Motion Blur -> Off (if available) | Frame Rate -> Uncapped"
 "NOTE: Game is first-person natively - great VR fit"
 )
 Flavor = "Backyard, but bigger. That spider is the size of a car."
 },
 @{ Name = "High on Life"; Folder = "High On Life"; Sub = ""; Exe = "Oregon-Win64-Shipping.exe"; AppId = 1583230
 Settings = @(
 "Window Mode -> Windowed | VSync -> Off | HDR -> Off"
 "Motion Blur -> Off | Depth of Field -> Off | Film Grain -> Off"
 "Chromatic Aberration -> Off"
 "Graphics Quality -> All Very High | Frame Rate -> Uncapped"
 )
 Flavor = "Talking guns. Cosmic crime lords. Gleeful chaos."
 },
 @{ Name = "Hogwarts Legacy"; Folder = "Hogwarts Legacy"; Sub = ""; Exe = "HogwartsLegacy.exe"; AppId = 990080
 Settings = @(
 "Window Mode -> Windowed Fullscreen | VSync -> Off | HDR -> Off | Frame Rate -> Uncapped"
 "Upscale Type -> NVIDIA DLSS | All Ray Tracing -> Off"
 "Motion Blur -> Off | Fog / Sky / Foliage Quality -> Low | Shadow Quality -> Low"
 "IMPORTANT: Add r.VolumetricFog=0 to Engine.ini to fix broken fog in VR"
 "Path: AppData\Local\Hogwarts Legacy\Saved\Config\Windows\Engine.ini"
 "RTX 4090 users: rename sl.interposer.dll to sl.interposer_bak.dll in Streamline folder"
 )
 Flavor = "Hogwarts in 1:1. The Forbidden Forest is much closer now."
 },
 @{ Name = "Horizon Zero Dawn"; Folder = "Horizon Zero Dawn"; Sub = ""; Exe = "HorizonZeroDawn.exe"; AppId = 1151640
 Settings = @(
 "Display Mode -> Borderless | VSync -> Off | HDR -> Off"
 "Aspect Ratio -> 1:1 REQUIRED (set a square custom resolution)"
 "FOV -> 70 | Anti-Aliasing -> Camera Based"
 "Upscaling -> Off (no DLSS support; ghosting will occur if enabled)"
 "Motion Blur -> Off | FPS Limit -> Unlimited | Adaptive FPS -> 120"
 "TIP: If game boots to black screen press Alt+Enter to fix the window"
 )
 Flavor = "Aloy, Nora outcast. Hunt machines, unearth the old world."
 },
 @{ Name = "Horizon Zero Dawn Remastered"; Folder = "Horizon Zero Dawn Remastered"; AltFolders = @("Horizon Zero Dawn Complete Edition Remastered"); Sub = ""; Exe = "HorizonZeroDawnRemastered.exe"; AppId = 2561580
 Settings = @(
 "Aim Assist -> Off | Window Mode -> Windowed | Aspect Ratio -> Auto"
 "VSync -> Off | HDR -> Off | NVIDIA Reflex -> Off | Cinematics Letterboxing -> Off"
 "Upscale -> DLSS (Ultra Performance, Balanced or Quality) | Dynamic Resolution Scaling -> Off"
 "Motion Blur -> Off | Film Grain -> Off | Depth of Field -> Off | Chromatic Aberration -> Off"
 )
 Flavor = "Aloy stalks the machines. Sharper than ever."
 },
 @{ Name = "Horizon Forbidden West"; Folder = "Horizon Forbidden West Complete Edition"; Sub = ""; Exe = "HorizonForbiddenWest.exe"; AppId = 2420110
 Settings = @(
 "Window Mode -> Windowed or Borderless | VSync -> Off | HDR -> Off"
 "NVIDIA Reflex -> Off (causes choppy camera in VR)"
 "DLSS -> Performance or Quality | Frame Generation -> Off"
 "Dynamic Resolution Scaling -> Off"
 "Motion Blur -> Off | Film Grain -> Off | Chromatic Aberration -> Off"
 )
 Flavor = "West of everything. Tenakth, Quen, machine apocalypse."
 },
 @{ Name = "Indiana Jones: Great Circle"; Folder = "Indiana Jones and the Great Circle"; AltFolders = @("IndianaJonesAndTheGreatCircle"); Sub = ""; Exe = "TheGreatCircle.exe"; AppId = 2677660
 Settings = @(
 "Display Mode -> Windowed | Aspect Ratio -> 16:9 | VSync -> Off | HDR -> Off"
 "FPS Limit -> 1000 | FOV -> 90-110 | Picture Framing -> FullScreen"
 "Upscaling -> DLSS | Frame Generation -> Off | RT Indirect Illumination -> Off"
 "Motion Blur -> Off | Chromatic Aberration -> Off | Film Grain -> 0 | Depth of Field -> Off"
 "Accessibility -> Camera: Camera Stabilization -> ON"
 "Accessibility -> Camera: Screen Shake -> OFF"
 )
 Flavor = "It's not the years, it's the mileage. Whip in hand."
 },
 @{ Name = "Kingdom Come: Deliverance II"; Folder = "KingdomComeDeliverance2"; AltFolders = @("Kingdom Come Deliverance 2"); Sub = ""; Exe = "KingdomCome.exe"; AppId = 1771300
 Settings = @(
 "Window Mode -> Windowed | VSync -> Off"
 "Frame Rate -> Lock to 240 FPS"
 "Resolution Scaling -> DLSS 4 Transformer Quality"
 "Near Depth of Field -> Off | Motion Blur -> Off"
 "Graphics Quality -> All Ultra (adjust per GPU)"
 )
 Flavor = "Henry of Skalitz returns. Bohemia in the medieval dirt."
 },
 @{ Name = "Spiderman Remastered"; Folder = "Marvel's Spider-Man Remastered"; AltFolders = @("Marvels Spider-Man Remastered"); Sub = ""; Exe = "Spider-Man.exe"; AppId = 1817070
 Settings = @(
 "Window Mode -> Windowed"
 "CRITICAL: Do NOT change Resolution or Aspect Ratio - mod forces 1:1 itself"
 "Upscaling -> DLSS or DLAA | Dynamic Resolution Scaling -> Off | Frame Generation -> Off"
 "Motion Blur Strength -> 0 | FOV -> 0 | Film Grain Strength -> 0"
 "Depth of Field -> Off | Chromatic Aberration -> Off | Vignette -> Off"
 "TIP: Disable Steam overlay if game crashes when opening R.E.A.L. VR menu"
 )
 Flavor = "With great power... now swing through Manhattan."
 },
 @{ Name = "Spiderman Miles Morales"; Folder = "Marvel's Spider-Man Miles Morales"; AltFolders = @("Marvels Spider-Man Miles Morales"); Sub = ""; Exe = "MilesMorales.exe"; AppId = 1817190
 Settings = @(
 "Window Mode -> Windowed"
 "CRITICAL: Do NOT change Resolution or Aspect Ratio - mod forces 1:1 itself"
 "Upscaling -> DLSS or DLAA | Dynamic Resolution Scaling -> Off | Frame Generation -> Off"
 "Motion Blur Strength -> 0 | FOV -> 0 | Film Grain Strength -> 0"
 "Depth of Field -> Off | Chromatic Aberration -> Off | Vignette -> Off"
 )
 Flavor = "Brooklyn's hero. Venom blast in 1:1."
 },
 @{ Name = "Spiderman 2"; Folder = "Marvel's Spider-Man 2"; AltFolders = @("Marvels Spider-Man 2"); Sub = ""; Exe = "Spider-Man2.exe"; AppId = 2482550
 Settings = @(
 "Window Mode -> Windowed | Aspect Ratio -> Auto | VSync -> Off | HDR -> Off"
 "Upscale -> DLSS (set level) | Frame Generation -> Off | Dynamic Resolution Scaling -> Off"
 "Depth of Field -> Off | Bloom -> Off | Motion Blur -> 0 | FOV -> 0"
 "Weather Particle Quality -> Low | Chromatic Aberration -> Off"
 )
 Flavor = "Two Spiders. One city. Symbiote in the air."
 },
 @{ Name = "Star Wars Outlaws"; Folder = "Star Wars Outlaws"; Sub = ""; Exe = "Outlaws.exe"; AppId = 2184190
 Settings = @(
 "Window Mode -> Windowed | VSync -> Off | NVIDIA Reflex -> Off | Frame Generation -> Off"
 "Upscaler Type -> NVIDIA DLSS | Upscaler Mode -> Fixed"
 "View Angles (both sliders, Gameplay > Visual) -> 75"
 "Motion Blur ALL sliders -> 0 | Cinematic Lens -> Off | Film Grain -> Off"
 "Depth of Field -> Low | RTX Direct Lighting -> Off | Ray Tracing -> Off"
 )
 Flavor = "Outer Rim outlaw. Kay Vess, Nix, and the long con."
 },
 @{ Name = "Stray"; Folder = "Stray"; Sub = ""; Exe = "Stray-Win64-Shipping.exe"; AppId = 1888160
 Settings = @(
 "Window Mode -> Windowed or Borderless | VSync -> Off | HDR -> Off"
 "Motion Blur -> Off | Depth of Field -> Off (if available) | Film Grain -> Off"
 "Frame Rate -> Uncapped"
 )
 Flavor = "A cat. A robot city. The Outside calls."
 },
 @{ Name = "TLOU Part I"; Folder = "The Last of Us Part I"; Sub = ""; Exe = "tlou-i.exe"; AppId = 1888930
 Settings = @(
 "Display Mode -> Windowed | Aspect Ratio -> Auto | VSync -> Off | Frame Rate -> Unlocked"
 "Scaling Mode -> NVIDIA DLSS | Frame Generation -> Off"
 "FOV -> 0 (slider to minimum) | Motion Blur -> 0 | Chromatic Aberration -> 0"
 "Film Grain -> 0 | Lens Dirt -> 0 | Depth of Field -> Off | Image Based Lighting -> Off"
 "After install: in R.E.A.L. VR menu TLOU1 tab set HUD Offset Y -> 0.35"
 )
 Flavor = "Joel and Ellie. Cordyceps world. Smuggle her west."
 },
 @{ Name = "TLOU Part II"; Folder = "The Last of Us Part II Remastered"; Sub = ""; Exe = "tlou-ii.exe"; AppId = 2531310
 Settings = @(
 "Display Mode -> Windowed | Aspect Ratio -> Auto | VSync -> Off | Frame Rate Cap -> 360"
 "Scaling -> NVIDIA DLSS | Frame Generation -> Off"
 "Camera Assist -> Off | Aim Assist -> 0 | Lock-On Aim -> Off"
 "Motion Blur -> 0 | Depth of Field -> Off | Chromatic Aberration -> 0 | Film Grain -> 0"
 )
 Flavor = "Vengeance has a price. Pay it, or pass it on."
 },
 @{ Name = "Uncharted: Legacy of Thieves"; Folder = "Uncharted Legacy of Thieves Collection"; Sub = ""; Exe = "u4.exe"; AppId = 1659420
 Settings = @(
 "Window Mode -> Windowed | Aspect Ratio -> 16:9 | VSync -> Off"
 "DLSS -> Performance or Quality"
 "Motion Blur Intensity -> 0"
 "NOTE: Mod auto-disables most post-processing effects for this game"
 )
 Flavor = "Treasure, ruin, gunfights. Drake's journal, Chloe's smirk."
 },
 @{ Name = "Watch Dogs"; Folder = "Watch_Dogs"; Sub = ""; Exe = "watch_dogs.exe"; AppId = 243470
 Settings = @(
 "Window Mode -> Windowed | VSync -> Off"
 "Anti-Aliasing -> FXAA or SMAA (avoid heavy MSAA)"
 "Motion Blur -> Off | Depth of Field -> Off"
 "NOTE: No HDR, Film Grain or CA toggles exist in this game"
 )
 Flavor = "Chicago runs on ctOS. Hack it, Marcus."
 },
 @{ Name = "Watch Dogs 2"; Folder = "Watch_Dogs2"; Sub = ""; Exe = "WatchDogs2.exe"; AppId = 447040
 Settings = @(
 "Window Mode -> Windowed or Borderless | VSync -> Off | Frame Rate -> Uncapped"
 "Anti-Aliasing -> Temporal AA | DirectX -> DX11 recommended (more stable than DX12)"
 "Motion Blur -> Off | Depth of Field -> Off"
 "Steam launch option: add -eac_launcher (required to disable EAC for the mod)"
 )
 Flavor = "DedSec is recruiting. The Bay is your playground."
 },
 @{ Name = "Watch Dogs Legion"; Folder = "Watch Dogs Legion"; Sub = ""; Exe = "WatchDogsLegion.exe"; AppId = 775935
 Settings = @(
 "Aim Snap -> Off | Aim Magnetism -> Off"
 "Window Mode -> Windowed | VSync -> Off | FPS Limit -> Off | FOV -> 70"
 "DirectX -> DX11 recommended | DLSS -> Performance | Ray Tracing -> Off | Frame Generation -> Off"
 "Motion Blur -> Off | Depth of Field -> Off | HDR -> Off"
 "NOTE: BattlEye anti-cheat must be disabled before launching"
 )
 Flavor = "Resistance London. Recruit anyone. Become the city."
 }
)

function Write-Header { Clear-Host; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host " Luke Ross R.E.A.L. VR Mod Installer" -ForegroundColor Magenta; Write-Host " Gamepad VR for 37 AAA games" -ForegroundColor Gray; Write-Host "============================================================" -ForegroundColor Magenta; Write-Host "" }
function Write-Step { param($n,$t,$x) Write-Host ""; Write-Host "--- [$n/$t] $x ---" -ForegroundColor Cyan; Write-Host "" }
function Write-OK { param($x) Write-Host " [OK] $x" -ForegroundColor Green }
function Write-Warn { param($x) Write-Host " [!!] $x" -ForegroundColor Yellow }
function Write-Fail { param($x) Write-Host " [XX] $x" -ForegroundColor Red }
function Write-Info { param($x) Write-Host " [..] $x" -ForegroundColor Gray }
function Pause-User { param($text = "Press Enter to continue...", $Color = "Yellow") Write-Host ""; Write-Host " >>> $text " -ForegroundColor Black -BackgroundColor Yellow; Read-Host }

function Get-SteamPath {
 foreach ($reg in @("HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam","HKCU:\SOFTWARE\Valve\Steam")) {
 try { $p=(Get-ItemProperty -Path $reg -ErrorAction Stop).InstallPath; if($p -and (Test-Path $p)){return $p} } catch {}
 }; return $null
}
function Get-SteamLibraries {
 param($sp); $libs=@($sp)
 $vdf=Join-Path $sp "steamapps\libraryfolders.vdf"
 if(Test-Path $vdf){ $c=Get-Content $vdf -Raw; [regex]::Matches($c,'"path"\s+"([^"]+)"') | ForEach-Object { $l=$_.Groups[1].Value -replace '\\\\','\'; if(Test-Path $l){$libs+=$l} } }
 return $libs
}

Write-Header

# True only if the file really begins with the ZIP magic bytes "PK". Guards
# against a silent auto-download that returns an HTML login/"post not found"
# page with HTTP 200 - without this, that page would be saved as REALVR.zip,
# cached, and then break extraction on this AND every future Luke Ross install.
function Test-IsZip {
    param([string]$Path)
    try {
        $fs = [System.IO.File]::OpenRead($Path)
        try {
            $b = New-Object byte[] 2
            $n = $fs.Read($b, 0, 2)
            return ($n -eq 2 -and $b[0] -eq 0x50 -and $b[1] -eq 0x4B)
        } finally { $fs.Close() }
    } catch { return $false }
}

# STEP 1: Obtain the R.E.A.L. VR mod (cached centrally, reused for all games)
Write-Host " Luke Ross R.E.A.L. VR brings AAA games into stereoscopic 6DoF VR." -ForegroundColor White
Write-Host " Gamepad controls. Requires an active R.E.A.L. Patreon subscription." -ForegroundColor White
Write-Host ""
Pause-User "Press Enter to start..."
Write-Step 1 4 "R.E.A.L. VR Mod"

# Ensure the central Hub cache folder exists.
try { if (-not (Test-Path $LR_CACHE_DIR)) { New-Item -ItemType Directory -Path $LR_CACHE_DIR -Force | Out-Null } } catch {}

$zipPath = $null
if (Test-Path $LR_CACHE_ZIP) {
 Write-OK "Using the R.E.A.L. VR mod already saved in the Hub - no download needed."
 $zipPath = $LR_CACHE_ZIP
} else {
 Write-Host " The R.E.A.L. VR mod is a single package that works for ALL Luke Ross" -ForegroundColor White
 Write-Host " games. Once you provide it the Hub keeps it and reuses it for every" -ForegroundColor White
 Write-Host " future Luke Ross install - you only do this once." -ForegroundColor White
 Write-Host ""
 Write-Host " Trying an automatic download first ... " -NoNewline -ForegroundColor White
 $autoOk = $false
 try {
 $ProgressPreference = 'SilentlyContinue'
 Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $LR_CACHE_ZIP -UseBasicParsing -ErrorAction Stop
 if ((Test-Path $LR_CACHE_ZIP) -and ((Get-Item $LR_CACHE_ZIP).Length -gt 0) -and (Test-IsZip $LR_CACHE_ZIP)) { $autoOk = $true }
 } catch { $autoOk = $false }
 if ($autoOk) {
 Write-Host "OK" -ForegroundColor Green
 Write-OK "Downloaded and saved to the Hub cache for all future installs."
 $zipPath = $LR_CACHE_ZIP
 } else {
 Write-Host "not available" -ForegroundColor Yellow
 try { Remove-Item $LR_CACHE_ZIP -Force -ErrorAction SilentlyContinue } catch {}
 Write-Host " Patreon needs you logged in, so grab it in your browser:" -ForegroundColor Gray
 Write-Host " 1. The Patreon post opens now (log in if needed)." -ForegroundColor Gray
 Write-Host " 2. Download the R.E.A.L. VR archive (.zip)." -ForegroundColor Gray
 Write-Host " 3. Drag the downloaded .zip into THIS window (or paste its path)." -ForegroundColor Gray
 Write-Host " -> $PATREON_URL" -ForegroundColor DarkGray
 Pause-User "Press Enter to open the Patreon post..."
 try { Start-Process $PATREON_URL } catch { Write-Warn "Could not open the browser. Visit the URL above manually." }
 Write-Host ""

 # Peek at the Downloads folder for an already-downloaded archive.
 $dropped = $null
 $dlFolder = $null
 try {
 $shKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
 $v = (Get-ItemProperty -Path $shKey -Name "{374DE290-123F-4565-9164-39C4925E467B}" -ErrorAction Stop)."{374DE290-123F-4565-9164-39C4925E467B}"
 if ($v) { $v = [Environment]::ExpandEnvironmentVariables($v); if (Test-Path $v) { $dlFolder = $v } }
 } catch {}
 if (-not $dlFolder) { $dlFolder = Join-Path $env:USERPROFILE "Downloads" }
 if (Test-Path $dlFolder) {
 $cand = Get-ChildItem -Path $dlFolder -Filter "*.zip" -ErrorAction SilentlyContinue |
 Where-Object { $_.Name -match '(?i)real|lrvr|luke' } |
 Sort-Object LastWriteTime -Descending | Select-Object -First 1
 if ($cand) {
 Write-Host " Found a likely R.E.A.L. VR archive in Downloads: $($cand.Name)" -ForegroundColor Green
 $useIt = (Read-Host " Use it? (Y/N)").Trim()
 if ($useIt -match '^(y|Y)') { $dropped = $cand.FullName }
 }
 }

 while (-not $dropped) {
 Write-Host " Drag-and-drop the downloaded ZIP into this window," -ForegroundColor Yellow
 Write-Host " or paste/type its full path, then press Enter:" -ForegroundColor White
 $r = (Read-Host " ZIP path").Trim().Trim('"')
 if (-not $r) { continue }
 if (Test-Path $r) {
 if ($r -match '\.zip$') { $dropped = $r }
 else { Write-Fail "Please provide the .zip you downloaded from Patreon: $r" }
 } else { Write-Fail "File not found: $r" }
 }

 # Save into the Hub cache so every future Luke Ross install reuses it.
 try {
 Copy-Item -Path $dropped -Destination $LR_CACHE_ZIP -Force
 Write-OK "Saved to the Hub cache - future Luke Ross installs will reuse it."
 $zipPath = $LR_CACHE_ZIP
 } catch {
 Write-Warn "Could not copy into the Hub cache: $($_.Exception.Message)"
 Write-Info "Using the file in place for this install."
 $zipPath = $dropped
 }
 }
}
if (-not $zipPath -or -not (Test-Path $zipPath)) {
 Write-Fail "No R.E.A.L. VR mod archive available. Aborting."
 Pause-User "Press Enter to exit..."; exit 1
}

# STEP 2: Select game and locate install folder
Write-Step 2 4 "Select Game & Locate Install"

$selectedGame = $null
if ($GameTitle -ne "") {
 # The hub now passes titles with a trailing " VR" suffix (e.g.
 # "Atomic Heart VR") to mark the card as a VR mod. The internal
 # game list below was authored with original names ("Atomic Heart").
 # Strip both prefix ("LR: ") and suffix (" VR") before matching.
 $clean = $GameTitle -replace "^LR: ","" -replace " VR$",""
 $selectedGame = $GAMES | Where-Object { $_.Name -eq $clean } | Select-Object -First 1
 if ($selectedGame) { Write-OK "Game: $($selectedGame.Name)" }
}
if (-not $selectedGame) {
 Write-Host " Which game?" -ForegroundColor White; Write-Host ""
 for ($i=0; $i -lt $GAMES.Count; $i++) { Write-Host " [$(($i+1).ToString().PadLeft(2))] $($GAMES[$i].Name)" -ForegroundColor White }
 Write-Host ""
 while (-not $selectedGame) {
 $inp=(Read-Host " Enter number").Trim(); $idx=[int]$inp-1
 if($idx -ge 0 -and $idx -lt $GAMES.Count){ $selectedGame=$GAMES[$idx]; Write-OK "Selected: $($selectedGame.Name)" }
 else { Write-Fail "Invalid number." }
 }
}

# Locate the game across all stores (Steam / Epic / Ubisoft / Gamepass)
# via the detection library. Falls through to legacy Steam-only lookup on failure.
$steamGamePath = $null
$detectedSource = $null # "Steam", "Epic", "Ubisoft", "Gamepass", or $null

try {
 $__utilsPath = Join-Path $PSScriptRoot "..\Utils\GameDetection.ps1"
 if (Test-Path $__utilsPath) {
 . $__utilsPath

 # Build hashtables for every store we support. The library tries them in
 # priority order (Steam first) and we can inspect the Candidates list to
 # decide what to do if multiple stores have the game installed.
 $detParams = @{
 GameName = $selectedGame.Name
 ExeName = $selectedGame.Exe
 Steam = @{ Folder = $selectedGame.Folder; AppID = "$($selectedGame.AppId)" }
 Epic = @{ FolderName = $selectedGame.Folder; ExeName = $selectedGame.Exe }
 Ubisoft = @{ FolderName = $selectedGame.Folder; ExeName = $selectedGame.Exe }
 EAApp = @{ FolderName = $selectedGame.Folder; ExeName = $selectedGame.Exe }
 Gamepass = @{ Folder = $selectedGame.Folder; ContentSubfolder = $true }
 }

 $det = Find-GameInstall @detParams

 if ($det.Candidates.Count -gt 1) {
 Write-Host ""
 Write-Host " Multiple $($selectedGame.Name) installs detected:" -ForegroundColor White
 Write-Host ""
 for ($i = 0; $i -lt $det.Candidates.Count; $i++) {
 $c = $det.Candidates[$i]
 Write-Host " [$($i+1)] $($c.Source)" -ForegroundColor Yellow
 Write-Host " $($c.Path)" -ForegroundColor Gray
 }
 Write-Host ""
 $pick = ""
 while (-not ($pick -as [int]) -or [int]$pick -lt 1 -or [int]$pick -gt $det.Candidates.Count) {
 $pick = (Read-Host " Your choice (1-$($det.Candidates.Count))").Trim()
 }
 $chosen = $det.Candidates[[int]$pick - 1]
 $steamGamePath = $chosen.Path
 $detectedSource = switch -Wildcard ($chosen.Source) {
 "Steam*" { "Steam"; break }
 "Gamepass*" { "Gamepass"; break }
 "Epic" { "Epic"; break }
 "Ubisoft" { "Ubisoft"; break }
 "EA" { "EA"; break }
 default { "Other" }
 }
 Write-OK "Using $detectedSource install: $steamGamePath"
 }
 elseif ($det.Found) {
 $steamGamePath = $det.Path
 $detectedSource = switch -Wildcard ($det.Source) {
 "Steam*" { "Steam"; break }
 "Gamepass*" { "Gamepass"; break }
 "Epic" { "Epic"; break }
 "Ubisoft" { "Ubisoft"; break }
 "EA" { "EA"; break }
 default { "Other" }
 }
 Write-OK "$($selectedGame.Name) found via ${detectedSource}: $steamGamePath"
 }
 }
} catch {
 Write-Info "Detection library failed, falling back to legacy Steam lookup."
}

# Legacy Steam-only fallback (unchanged behaviour for users with Steam installs)
if (-not $steamGamePath) {
 $steamPath = Get-SteamPath
 if ($steamPath) {
 foreach ($lib in (Get-SteamLibraries $steamPath)) {
 # Try primary folder, then any alt folders
 $foldersToTry = @($selectedGame.Folder)
 if ($selectedGame.AltFolders) { $foldersToTry += $selectedGame.AltFolders }
 foreach ($folder in $foldersToTry) {
 $c = Join-Path $lib "steamapps\common\$folder"
 if (Test-Path $c) { $steamGamePath = $c; $detectedSource = "Steam"; break }
 }
 if ($steamGamePath) { break }
 }
 }
}

if (-not $steamGamePath) {
 Write-Warn "Game not found automatically in any store."
 Write-Host " Enter the game folder (Steam, Epic, Ubisoft, or Game Pass install):" -ForegroundColor White
 Write-Host " Example Steam path: ...steamapps\common\$($selectedGame.Folder)" -ForegroundColor Gray
 while (-not $steamGamePath) {
 $r=(Read-Host " Path").Trim().Trim('"')
 if(Test-Path $r){
 $steamGamePath = $r
 $detectedSource = "Manual"
 Write-OK "Path set: $steamGamePath"
 } else {
 Write-Fail "Not found: $r"
 }
 }
}

# Find the EXE recursively inside the Steam game folder - handles sub-folders like bin\, Game\, etc.
$exeFound = Get-ChildItem -Path $steamGamePath -Filter $selectedGame.Exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

$installPath = if ($exeFound) {
 Write-OK "EXE found: $($exeFound.FullName)"
 $exeFound.DirectoryName
} else {
 Write-Warn "EXE '$($selectedGame.Exe)' not found in: $steamGamePath"
 Write-Info "Falling back to game root folder - continuing anyway."
 $steamGamePath
}
Write-OK "Install target: $installPath"

# STEP 3: Show required in-game settings, then launch game once for config creation
Write-Step 3 4 "Required In-Game Settings"

Write-Host " Set these options inside $($selectedGame.Name) before using the VR mod:" -ForegroundColor White
Write-Host ""
foreach ($line in $selectedGame.Settings) {
 Write-Host " >> $line" -ForegroundColor Yellow
}
Write-Host ""
Write-Host " The game will now launch so you can apply these settings." -ForegroundColor White
Write-Host " -> Configure the settings above, then CLOSE the game to continue." -ForegroundColor Green
Write-Host ""
Pause-User "Press Enter to launch $($selectedGame.Name) now..."

# Launch via Steam URL when the game came from Steam, otherwise launch the
# EXE directly. This avoids steam:// failing for Epic / Ubisoft / Game Pass
# installs where the Steam AppID is not registered.
if ($detectedSource -eq "Steam") {
 $steamUrl = "steam://rungameid/$($selectedGame.AppId)"
 Write-Info "Opening game via Steam: $steamUrl"
 Start-Process $steamUrl
} else {
 $launchExe = $null
 if ($exeFound) { $launchExe = $exeFound.FullName }
 else {
 # Re-search to find the exe under the chosen folder
 $hit = Get-ChildItem -Path $installPath -Filter $selectedGame.Exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
 if ($hit) { $launchExe = $hit.FullName }
 }
 if ($launchExe) {
 Write-Info "Launching directly: $launchExe"
 try { Start-Process -FilePath $launchExe -WorkingDirectory (Split-Path $launchExe -Parent) }
 catch { Write-Warn "Could not auto-launch the game. Please start $($selectedGame.Name) manually now." }
 } else {
 Write-Warn "Could not find the game EXE to auto-launch."
 Write-Host " Please start $($selectedGame.Name) manually via your store/launcher." -ForegroundColor Yellow
 }
}
Write-Host ""
$launchLabel = switch ($detectedSource) {
 "Steam" { "Steam" }
 "Gamepass" { "Xbox Game Pass" }
 "Epic" { "the Epic Games Launcher" }
 "Ubisoft" { "Ubisoft Connect" }
 "EA" { "the EA App" }
 default { "the store/launcher" }
}
Write-Host " $launchLabel is launching $($selectedGame.Name)." -ForegroundColor Yellow
Write-Host " Apply the settings listed above, then CLOSE the game." -ForegroundColor Yellow
Write-Host ""
Pause-User "Press Enter here AFTER you have closed the game. R.E.A.L VR mod installation will start - UAC required."
Write-OK "Continuing with mod installation."

# STEP 4: Extract and configure
Write-Step 4 4 "Installing"

Write-Host " Extracting mod files ... " -NoNewline -ForegroundColor White
try {
 Expand-Archive -Path $zipPath -DestinationPath $installPath -Force
 Write-Host "OK" -ForegroundColor Green
 Write-OK "Files extracted to: $installPath"
} catch {
 Write-Host "FAILED" -ForegroundColor Red
 Write-Host " $_" -ForegroundColor Gray
 $__fb = Invoke-InstallerFallback -Action "mod archive extraction" `
 -Instructions "Open '$zipPath' with 7-Zip or Windows Explorer, and extract its contents into '$installPath'. Then choose Retry." `
 -SkipMessage "Skipped - mod files were NOT extracted; install is incomplete." `
 -SourceFolder "$zipPath" `
 -DestFolder "$installPath" `
 -AllowSkip $true
 if ([string]$__fb -eq "quit") { Pause-User "Press Enter to exit..."; exit 1 }
 if ([string]$__fb -eq "retry") {
 # User claims they extracted manually. Re-run extract logic
 # by exiting and forcing re-run (we don't know which archive
 # variable this catch belongs to without context).
 Pause-User "We will exit so you can re-run with the fixed environment. Press Enter to exit..."
 exit 1
 }
 # User chose Skip - continue at own risk
}

# Persist the install location so the hub's post-install refresh
# can flip THIS title to "VR Ready" without needing a full scan,
# and so future scans pick it up even when the game lives outside
# a standard Steam library (e.g. Epic, GOG, manual installs).
# Multi-game installers like Luke Ross share one folder across
# many titles, so we key the file by safe-title to avoid
# overwriting other games' records.
try {
    $safeName = ($GameTitle -replace '[^A-Za-z0-9]', '_')
    if (-not $safeName) { $safeName = "default" }
    Set-Content -Path (Join-Path $PSScriptRoot ".installed_path_$safeName") -Value $installPath -Encoding UTF8 -Force
    Set-Content -Path (Join-Path $PSScriptRoot ".real_version_$safeName") -Value $REAL_VERSION -Encoding UTF8 -Force
    # Also record the version INSIDE the mod's install folder, so ANY Hub -
    # even a fresh one that never installed it - reads the right version and
    # doesn't wrongly show "Update". The Hub-local marker stays as a fallback.
    try { Set-Content -Path (Join-Path $installPath ".real_vr_version") -Value $REAL_VERSION -Encoding UTF8 -Force } catch {}
} catch {}

$configBat = Join-Path $installPath "RealConfig.bat"
if (Test-Path $configBat) {
 Write-Host ""
 Write-Host " Running RealConfig.bat..." -ForegroundColor White
 Start-Process "cmd.exe" -ArgumentList "/c RealConfig.bat" -WorkingDirectory $installPath -Wait
 Write-OK "RealConfig complete."
} else {
 Write-Warn "RealConfig.bat not found in install folder."
}

# Create DISABLE_VR.bat in the game folder
$disableVrBat = Join-Path $installPath "DISABLE_VR.bat"
$disableVrContent = @'
@echo off
title R.E.A.L. VR - Disable / Re-enable VR

echo ============================================================
echo R.E.A.L. VR - Disable / Re-enable VR
echo ============================================================
echo.
echo Choose an option:
echo.
echo [1] DISABLE VR (renames RealRepo and dxgi.dll so mod does not attach)
echo [2] RE-ENABLE VR (restores renamed files and re-runs RealConfig)
echo [0] Exit
echo.
set /p choice=Enter number: 

if "%choice%"=="1" goto disable
if "%choice%"=="2" goto reenable
goto end

:disable
echo.
if exist "RealRepo" (
 ren "RealRepo" "RealRepo_"
 echo [OK] RealRepo renamed to RealRepo_
) else (
 echo [..] RealRepo not found - already disabled or not installed
)
if exist "dxgi.dll" (
 ren "dxgi.dll" "dxgi_.dll"
 echo [OK] dxgi.dll renamed to dxgi_.dll
) else (
 echo [..] dxgi.dll not found - skipping
)
echo.
echo VR is now DISABLED. Launch the game normally to play without VR.
echo Run this script again and choose [2] to re-enable VR.
echo.
pause
goto end

:reenable
echo.
if exist "RealRepo_" (
 ren "RealRepo_" "RealRepo"
 echo [OK] RealRepo_ restored to RealRepo
) else (
 echo [!!] RealRepo_ not found - VR may already be enabled
)
if exist "dxgi_.dll" (
 ren "dxgi_.dll" "dxgi.dll"
 echo [OK] dxgi_.dll restored to dxgi.dll
) else (
 echo [..] dxgi_.dll not found - skipping
)
echo.
echo Running RealConfig to re-register the mod...
if exist "RealConfig.bat" (
 call RealConfig.bat
 echo [OK] RealConfig done.
) else (
 echo [!!] RealConfig.bat not found - run it manually from the game folder.
)
echo.
echo VR is RE-ENABLED. Start SteamVR and then launch the game.
echo.
pause
goto end

:end
'@
Set-Content -Path $disableVrBat -Value $disableVrContent -Encoding ASCII
Write-OK "Created: DISABLE_VR.bat"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host " Done! $($selectedGame.Name) is ready for VR." -ForegroundColor Green
Write-Host ""
Write-Host " - Start SteamVR before launching the game." -ForegroundColor White
Write-Host " - Use a gamepad - R.E.A.L. VR does not support motion controls." -ForegroundColor Yellow
Write-Host " - Press PAUSE in-game to open the R.E.A.L. VR menu." -ForegroundColor White
Write-Host " - Aim for stable 60fps - adjust graphics settings accordingly." -ForegroundColor White
Write-Host "" 
Write-Host " Problems? Run DISABLE_VR.bat in the game folder to toggle VR on/off." -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
if ($selectedGame.Flavor) {
 Write-Host " $($selectedGame.Flavor)" -ForegroundColor Magenta
 Write-Host ""
}
Write-Host " If you enjoy R.E.A.L. VR, please support Luke Ross!" -ForegroundColor Green
Write-Host " https://www.patreon.com/realvr" -ForegroundColor Yellow
Write-Host ""
try { Start-Process explorer.exe "`"$installPath`"" } catch {}
Pause-User "Press Enter to exit."
