@echo off
title PCVR Mods Installer Hub - Debug Console
color 0A
echo ============================================
echo   PCVR Mods Installer Hub - Debug Launcher
echo ============================================
echo.
echo   This window stays open if anything crashes.
echo   A copy of all output is also saved to:
echo   %USERPROFILE%\Desktop\pcvr-debug-log.txt
echo   (send that file if you need help)
echo.
echo ============================================
echo.
echo   [1]  VR Mod Hub (main GUI)
echo   [2]  7 Days to Die VR
echo   [3]  Alba VR
echo   [4]  Alien: Isolation VR
echo   [5]  Bendy VR
echo   [6]  Black Mesa Source VR
echo   [7]  Cloudpunk VR
echo   [8]  Cloudpunk: City of Ghosts VR
echo   [9]  Content Warning VR
echo   [10] Deep Rock Galactic VR
echo   [11] Descenders VR
echo   [12] Devil May Cry 5 VR
echo   [13] Doom 3 BFG VR
echo   [14] Dredge VR
echo   [15] Final Fantasy XIV VR
echo   [16] Garry's Mod VR
echo   [17] Gunfire Reborn VR
echo   [18] Hexen II VR
echo   [19] Left 4 Dead 2 VR
echo   [20] Lethal Company VR
echo   [21] Life is Strange: BtS VR
echo   [22] Luke Ross R.E.A.L. VR
echo   [23] Outer Wilds VR
echo   [24] Portal 2 VR
echo   [25] R.E.P.O. VR
echo   [26] Raft VR
echo   [27] Risk of Rain 2 VR
echo   [28] Road to Vostok VR
echo   [29] Slime Rancher VR
echo   [30] Starfield VR
echo   [31] Subnautica VR
echo   [32] Subnautica: Below Zero VR
echo   [33] ULTRAKILL VR
echo   [34] Valheim VR
echo   [35] Outward DE VR
echo   [36] Tormented Souls VR
echo   [37] REFramework VR (game selector)
echo   [38] Yooka-Laylee VR
echo   [39] Moto Rush Reborn VR
echo   [40] Slyders VR
echo   [41] Super Polygon Grand Prix VR
echo   [42] StreetDog BMX VR
echo   [43] Hypogea VR
echo   [44] Lunistice VR
echo   [45] Unmourned VR
echo   [46] Moros Protocol VR
echo   [47] Skate Story VR
echo   [48] Dusk HD (DLC) VR
echo   [49] Decimate Drive VR
echo   [50] Rogue Flight VR
echo   [51] Astrodogs VR
echo   [52] Star Racer VR
echo   [53] Hollow Knight Silksong
echo   [54] House of the Dead Remake VR
echo   [55] Paranoia Place VR
echo   [56] Paperklay VR
echo   [57] Dino Trauma VR
echo   [58] Sunrise GP VR
echo   [59] Horizon Chase Turbo
echo   [60] Road Redemption VR
echo   [61] Bomb Rush Cyberfunk
echo   [62] Mirage Feathers VR
echo   [63] Panzer Dragoon Remake
echo   [64] Sonic P-06 VR
echo   [65] Driftwood VR
echo   [66] Tinykin VR
echo   [67] Sayonara Wild Hearts
echo   [68] Another Crab's Treasure
echo   [69] Hollow Knight VR
echo   [70] Circuit Superstars VR
echo   [71] Art of Rally VR
echo   [72] Doom VR
echo   [73] Doom 2 VR
echo   [74] Heretic VR
echo   [75] Hexen VR
echo   [76] Strife VR
echo   [77] Techtonica VR
echo   [78] PEAK VR
echo   [79] GTFO VR
echo   [80] Amnesia VR
echo   [81] Anomaly VR
echo   [82] House of the Dead 2 Remake VR
echo   [83] Kerbal Space Program VR
echo   [84] World of Warcraft VR
echo   [85] Tomb Raider 1 VR
echo   [86] HL2VRU Unleashed (add-on)
echo   [87] Cruelty Squad VR
echo   [88] Selaco VR
echo   [89] Iron Lung VR
echo   [90] Quake VR
echo   [91] Penumbra: Overture VR
echo   [92] Receiver VR
echo   [93] Daggerfall VR
echo   [94] Quake 3 VR
echo   [95] Quake 2 VR
echo   [96] Cyberpunk 2077
echo   [97] The Dark Mod VR
echo   [98] I Can Gun VR
echo   [99] Metal Hellsinger VR
echo   [100] Breath of the Wild VR
echo   [101] Richard Burns Rally VR
echo   [102] Forza Horizon 6 VR
echo   [103] Grand Theft Auto V VR
echo   [104] No One Lives Forever 2 VR
echo   [105] Escape from Tarkov VR
echo   [106] Ready Or Not VR
echo   [107] Saints Row: The Third VR
echo   [108] Trombone Champ VR
echo   [109] Metroid Prime VR
echo   [110] Ashes 2063 VR
echo   [111] Total Chaos VR
echo   [112] Echo Generation 2 VR
echo   [113] Ratchet ^& Clank VR
echo   [114] Perfect Dark VR
echo   [115] Anomaly GAMMA
echo   [116] Mouse P.I. For Hire VR
echo   [117] New Star GP VR
echo   [118] Super Mario 64 VR
echo   [119] Star Fox 64 VR
echo   [120] Hytale VR
echo   [121] Forza Horizon 5 VR
echo   [122] Idols of Ash VR
echo   [123] Warhammer 40K: Rogue Trader VR
echo   [124] Sonic Robo Blast 2 VR
echo   [125] Mario Kart 64 VR
echo   [126] Assassin's Creed Valhalla VR
echo   [127] Assassin's Creed Mirage VR
echo   [128] Assassin's Creed Odyssey VR
echo   [129] Mass Effect 1 LE VR
echo   [130] Outbound VR
echo   [131] Halo 3 MCC VR
echo   [132] Ring Racers VR
echo   [133] Star Trucker VR
echo   [134] Painkiller Black Edition
echo.
set /p choice="Enter number (1-134): "
if "%choice%"=="1"  (set SCRIPT=%~dp0VRModHub.ps1)
if "%choice%"=="2"  (set SCRIPT=%~dp07DaysVR\7DaysVR-core.ps1)
if "%choice%"=="3"  (set SCRIPT=%~dp0AlbaVR\AlbaVR-core.ps1)
if "%choice%"=="4"  (set SCRIPT=%~dp0AlienIsolationVR\AlienIsolationVR-core.ps1)
if "%choice%"=="5"  (set SCRIPT=%~dp0BendyVR\BendyVR-core.ps1)
if "%choice%"=="6"  (set SCRIPT=%~dp0BMSVR\BMSVR-core.ps1)
if "%choice%"=="7"  (set SCRIPT=%~dp0CloudpunkVR\CloudpunkVR-core.ps1)
if "%choice%"=="8"  (set SCRIPT=%~dp0CloudpunkCOGVR\CloudpunkCOGVR-core.ps1)
if "%choice%"=="9"  (set SCRIPT=%~dp0ContentWarningVR\ContentWarningVR-core.ps1)
if "%choice%"=="10" (set SCRIPT=%~dp0DRGVRG\DRGVRG-core.ps1)
if "%choice%"=="11" (set SCRIPT=%~dp0DescendersVR\DescendersVR-core.ps1)
if "%choice%"=="12" (set SCRIPT=%~dp0DMC5VR\DMC5VR-core.ps1)
if "%choice%"=="13" (set SCRIPT=%~dp0Doom3BFGVR\Doom3BFGVR-core.ps1)
if "%choice%"=="14" (set SCRIPT=%~dp0DredgeVR\DredgeVR-core.ps1)
if "%choice%"=="15" (set SCRIPT=%~dp0FfxivVR\FfxivVR-core.ps1)
if "%choice%"=="16" (set SCRIPT=%~dp0GModVR\GModVR-core.ps1)
if "%choice%"=="17" (set SCRIPT=%~dp0GunfireReborn_VR\GFReborn-core.ps1)
if "%choice%"=="18" (set SCRIPT=%~dp0Hexen2VR\Hexen2VR-core.ps1)
if "%choice%"=="19" (set SCRIPT=%~dp0L4D2VR\L4D2VR-core.ps1)
if "%choice%"=="20" (set SCRIPT=%~dp0LethalCompanyVR\LCVR-core.ps1)
if "%choice%"=="21" (set SCRIPT=%~dp0DawnVR\DawnVR-core.ps1)
if "%choice%"=="22" (set SCRIPT=%~dp0LukeRossVR\LukeRossVR-core.ps1)
if "%choice%"=="23" (set SCRIPT=%~dp0OuterWildsVR\OuterWildsVR-core.ps1)
if "%choice%"=="24" (set SCRIPT=%~dp0Portal2VR\Portal2VR-core.ps1)
if "%choice%"=="25" (set SCRIPT=%~dp0RepoVR\RepoVR-core.ps1)
if "%choice%"=="26" (set SCRIPT=%~dp0RaftVR\RaftVR-core.ps1)
if "%choice%"=="27" (set SCRIPT=%~dp0RoR2_VR\Install_RoR2_VR.ps1)
if "%choice%"=="28" (set SCRIPT=%~dp0VostokVR\VostokVR-core.ps1)
if "%choice%"=="29" (set SCRIPT=%~dp0SlimeRancherVR\SRVR-core.ps1)
if "%choice%"=="30" (set SCRIPT=%~dp0StarfieldVR\StarfieldVR-core.ps1)
if "%choice%"=="31" (set SCRIPT=%~dp0SubnauticaVR\SubmersedVR-core.ps1)
if "%choice%"=="32" (set SCRIPT=%~dp0SubnauticaBZVR\SubmersedVR_BZ-core.ps1)
if "%choice%"=="33" (set SCRIPT=%~dp0UltrakillVR\UltrakillVR-core.ps1)
if "%choice%"=="34" (set SCRIPT=%~dp0ValheimVR\ValheimVR-core.ps1)
if "%choice%"=="35" (set SCRIPT=%~dp0OutwardVR\OutwardVR-core.ps1)
if "%choice%"=="36" (set SCRIPT=%~dp0TormentedSoulsVR\TormentedSoulsVR-core.ps1)
if "%choice%"=="37" (set SCRIPT=%~dp0REFrameworkVR\REFrameworkVR-core.ps1)
if "%choice%"=="38" (set SCRIPT=%~dp0YookaLayleeVR\YookaLayleeVR-core.ps1)
if "%choice%"=="39" (set SCRIPT=%~dp0MotoRushRebornVR\MotoRushRebornVR-core.ps1)
if "%choice%"=="40" (set SCRIPT=%~dp0SlydersVR\SlydersVR-core.ps1)
if "%choice%"=="41" (set SCRIPT=%~dp0SuperPolygonGrandPrixVR\SuperPolygonGrandPrixVR-core.ps1)
if "%choice%"=="42" (set SCRIPT=%~dp0StreetDogBMXVR\StreetDogBMXVR-core.ps1)
if "%choice%"=="43" (set SCRIPT=%~dp0HypogeaVR\HypogeaVR-core.ps1)
if "%choice%"=="44" (set SCRIPT=%~dp0LunisticeVR\LunisticeVR-core.ps1)
if "%choice%"=="45" (set SCRIPT=%~dp0UnmournedVR\UnmournedVR-core.ps1)
if "%choice%"=="46" (set SCRIPT=%~dp0MorosProtocolVR\MorosProtocolVR-core.ps1)
if "%choice%"=="47" (set SCRIPT=%~dp0SkateStoryVR\SkateStoryVR-core.ps1)
if "%choice%"=="48" (set SCRIPT=%~dp0DuskHDVR\DuskHDVR-core.ps1)
if "%choice%"=="49" (set SCRIPT=%~dp0DecimateDriveVR\DecimateDriveVR-core.ps1)
if "%choice%"=="50" (set SCRIPT=%~dp0RogueFlightVR\RogueFlightVR-core.ps1)
if "%choice%"=="51" (set SCRIPT=%~dp0AstrodogsVR\AstrodogsVR-core.ps1)
if "%choice%"=="52" (set SCRIPT=%~dp0StarRacerVR\StarRacerVR-core.ps1)
if "%choice%"=="53" (set SCRIPT=%~dp0HollowKnightSilksongVR\HollowKnightSilksongVR-core.ps1)
if "%choice%"=="54" (set SCRIPT=%~dp0HouseOfTheDeadRemakeVR\HouseOfTheDeadRemakeVR-core.ps1)
if "%choice%"=="55" (set SCRIPT=%~dp0ParanoiaPlaceVR\ParanoiaPlaceVR-core.ps1)
if "%choice%"=="56" (set SCRIPT=%~dp0PaperklayVR\PaperklayVR-core.ps1)
if "%choice%"=="57" (set SCRIPT=%~dp0DinoTraumaVR\DinoTraumaVR-core.ps1)
if "%choice%"=="58" (set SCRIPT=%~dp0SunriseGPVR\SunriseGPVR-core.ps1)
if "%choice%"=="59" (set SCRIPT=%~dp0HorizonChaseTurboVR\HorizonChaseTurboVR-core.ps1)
if "%choice%"=="60" (set SCRIPT=%~dp0RoadRedemptionVR\RoadRedemptionVR-core.ps1)
if "%choice%"=="61" (set SCRIPT=%~dp0BombRushCyberfunkVR\BombRushCyberfunkVR-core.ps1)
if "%choice%"=="62" (set SCRIPT=%~dp0MirageFeathersVR\MirageFeathersVR-core.ps1)
if "%choice%"=="63" (set SCRIPT=%~dp0PanzerDragoonRemakeVR\PanzerDragoonRemakeVR-core.ps1)
if "%choice%"=="64" (set SCRIPT=%~dp0SonicP06VR\SonicP06VR-core.ps1)
if "%choice%"=="65" (set SCRIPT=%~dp0DriftwoodVR\DriftwoodVR-core.ps1)
if "%choice%"=="66" (set SCRIPT=%~dp0TinykinVR\TinykinVR-core.ps1)
if "%choice%"=="67" (set SCRIPT=%~dp0SayonaraWildHeartsVR\SayonaraWildHeartsVR-core.ps1)
if "%choice%"=="68" (set SCRIPT=%~dp0AnotherCrabsTreasureVR\AnotherCrabsTreasureVR-core.ps1)
if "%choice%"=="69" (set SCRIPT=%~dp0HollowKnightVR\HollowKnightVR-core.ps1)
if "%choice%"=="70" (set SCRIPT=%~dp0CircuitSuperstarsVR\CircuitSuperstarsVR-core.ps1)
if "%choice%"=="71" (set SCRIPT=%~dp0ArtOfRallyVR\ArtOfRallyVR-core.ps1)
if "%choice%"=="72" (set SCRIPT=%~dp0DoomVR\DoomVR-core.ps1)
if "%choice%"=="73" (set SCRIPT=%~dp0Doom2VR\Doom2VR-core.ps1)
if "%choice%"=="74" (set SCRIPT=%~dp0HereticVR\HereticVR-core.ps1)
if "%choice%"=="75" (set SCRIPT=%~dp0HexenVR\HexenVR-core.ps1)
if "%choice%"=="76" (set SCRIPT=%~dp0StrifeVR\StrifeVR-core.ps1)
if "%choice%"=="77" (set SCRIPT=%~dp0TechtonicaVR\TechtonicaVR-core.ps1)
if "%choice%"=="78" (set SCRIPT=%~dp0PEAKVR\PEAKVR-core.ps1)
if "%choice%"=="79" (set SCRIPT=%~dp0GTFOVR\GTFOVR-core.ps1)
if "%choice%"=="80" (set SCRIPT=%~dp0AmnesiaVR\AmnesiaVR-core.ps1)
if "%choice%"=="81" (set SCRIPT=%~dp0AnomalyVR\AnomalyVR-core.ps1)
if "%choice%"=="82" (set SCRIPT=%~dp0HouseOfTheDead2RemakeVR\HouseOfTheDead2RemakeVR-core.ps1)
if "%choice%"=="83" (set SCRIPT=%~dp0KSPVR\KSPVR-core.ps1)
if "%choice%"=="84" (set SCRIPT=%~dp0WoVR\WoVR-core.ps1)
if "%choice%"=="85" (set SCRIPT=%~dp0TombRaiderVR\TombRaiderVR-core.ps1)
if "%choice%"=="86" (set SCRIPT=%~dp0HL2VRU\HL2VRU-core.ps1)
if "%choice%"=="87" (set SCRIPT=%~dp0CrueltySquadVR\CrueltySquadVR-core.ps1)
if "%choice%"=="88" (set SCRIPT=%~dp0SelacoVR\SelacoVR-core.ps1)
if "%choice%"=="89" (set SCRIPT=%~dp0IronLungVR\IronLungVR-core.ps1)
if "%choice%"=="90" (set SCRIPT=%~dp0QuakeVR\QuakeVR-core.ps1)
if "%choice%"=="91" (set SCRIPT=%~dp0PenumbraVR\PenumbraVR-core.ps1)
if "%choice%"=="92" (set SCRIPT=%~dp0ReceiverVR\ReceiverVR-core.ps1)
if "%choice%"=="93" (set SCRIPT=%~dp0DaggerfallUnityVR\DaggerfallUnityVR-core.ps1)
if "%choice%"=="94" (set SCRIPT=%~dp0Quake3VR\Quake3VR-core.ps1)
if "%choice%"=="95" (set SCRIPT=%~dp0Quake2VR\Quake2VR-core.ps1)
if "%choice%"=="96" (set SCRIPT=%~dp0Cyberpunk2077VR\Cyberpunk2077VR-core.ps1)
if "%choice%"=="97" (set SCRIPT=%~dp0TheDarkModVR\TheDarkModVR-core.ps1)
if "%choice%"=="98" (set SCRIPT=%~dp0ICanGunVR\ICanGunVR-core.ps1)
if "%choice%"=="99" (set SCRIPT=%~dp0MetalHellsingerVR\MetalHellsingerVR-core.ps1)
if "%choice%"=="100" (set SCRIPT=%~dp0BreathOfTheWildVR\BreathOfTheWildVR-core.ps1)
if "%choice%"=="101" (set SCRIPT=%~dp0RichardBurnsRallyVR\RichardBurnsRallyVR-core.ps1)
if "%choice%"=="102" (set SCRIPT=%~dp0ForzaHorizon6VR\ForzaHorizon6VR-core.ps1)
if "%choice%"=="103" (set SCRIPT=%~dp0GTAVR\GTAVR-core.ps1)
if "%choice%"=="104" (set SCRIPT=%~dp0NOLF2VR\NOLF2VR-core.ps1)
if "%choice%"=="105" (set SCRIPT=%~dp0SPTVR\SPTVR-core.ps1)
if "%choice%"=="106" (set SCRIPT=%~dp0ReadyOrNotVR\ReadyOrNotVR-core.ps1)
if "%choice%"=="107" (set SCRIPT=%~dp0SaintsRowTheThirdVR\SaintsRowTheThirdVR-core.ps1)
if "%choice%"=="108" (set SCRIPT=%~dp0TromboneChampVR\TromboneChampVR-core.ps1)
if "%choice%"=="109" (set SCRIPT=%~dp0MetroidPrimeVR\MetroidPrimeVR-core.ps1)
if "%choice%"=="110" (set SCRIPT=%~dp0Ashes2063VR\Ashes2063VR-core.ps1)
if "%choice%"=="111" (set SCRIPT=%~dp0TotalChaosVR\TotalChaosVR-core.ps1)
if "%choice%"=="112" (set SCRIPT=%~dp0EchoGeneration2VR\EchoGeneration2VR-core.ps1)
if "%choice%"=="113" (set SCRIPT=%~dp0RatchetVR\RatchetVR-core.ps1)
if "%choice%"=="114" (set SCRIPT=%~dp0PerfectDarkVR\PerfectDarkVR-core.ps1)
if "%choice%"=="115" (set SCRIPT=%~dp0AnomalyGammaVR\AnomalyGammaVR-core.ps1)
if "%choice%"=="116" (set SCRIPT=%~dp0MousePIVR\MousePIVR-core.ps1)
if "%choice%"=="117" (set SCRIPT=%~dp0NewStarGPVR\NewStarGPVR-core.ps1)
if "%choice%"=="118" (set SCRIPT=%~dp0SuperMario64VR\SuperMario64VR-core.ps1)
if "%choice%"=="119" (set SCRIPT=%~dp0StarFox64VR\StarFox64VR-core.ps1)
if "%choice%"=="120" (set SCRIPT=%~dp0HytaleVR\HytaleVR-core.ps1)
if "%choice%"=="121" (set SCRIPT=%~dp0ForzaHorizon5VR\ForzaHorizon5VR-core.ps1)
if "%choice%"=="122" (set SCRIPT=%~dp0IdolsOfAshVR\IdolsOfAshVR-core.ps1)
if "%choice%"=="123" (set SCRIPT=%~dp0RogueTraderVR\RogueTraderVR-core.ps1)
if "%choice%"=="124" (set SCRIPT=%~dp0SonicRoboBlast2VR\SonicRoboBlast2VR-core.ps1)
if "%choice%"=="125" (set SCRIPT=%~dp0MarioKart64VR\MarioKart64VR-core.ps1)
if "%choice%"=="126" (set SCRIPT=%~dp0ACValhallaVR\ACValhallaVR-core.ps1)
if "%choice%"=="127" (set SCRIPT=%~dp0ACMirageVR\ACMirageVR-core.ps1)
if "%choice%"=="128" (set SCRIPT=%~dp0ACOdysseyVR\ACOdysseyVR-core.ps1)
if "%choice%"=="129" (set SCRIPT=%~dp0MassEffect1VR\MassEffect1VR-core.ps1)
if "%choice%"=="130" (set SCRIPT=%~dp0OutboundVR\OutboundVR-core.ps1)
if "%choice%"=="131" (set SCRIPT=%~dp0Halo3MCCVR\Halo3MCCVR-core.ps1)
if "%choice%"=="132" (set SCRIPT=%~dp0RingRacersVR\RingRacersVR-core.ps1)
if "%choice%"=="133" (set SCRIPT=%~dp0StarTruckerVR\StarTruckerVR-core.ps1)
if "%choice%"=="134" (set SCRIPT=%~dp0PainkillerBlackVR\PainkillerBlackVR-core.ps1)
if not defined SCRIPT (echo Invalid choice. & pause & exit /b 1)

set LOGFILE=%USERPROFILE%\Desktop\pcvr-debug-log.txt

echo.
echo Script: %SCRIPT%
echo Log file: %LOGFILE%
echo.
echo ============================================
echo   OUTPUT BELOW - errors will stay visible
echo   ALSO saved to: %LOGFILE%
echo ============================================
echo.

REM Write a header to the log so the user knows what they're sending
> "%LOGFILE%" echo === PCVR Mods Installer Hub - Debug Log ===
>>"%LOGFILE%" echo Date: %DATE% %TIME%
>>"%LOGFILE%" echo Script: %SCRIPT%
>>"%LOGFILE%" echo User: %USERNAME%
>>"%LOGFILE%" echo Computer: %COMPUTERNAME%
>>"%LOGFILE%" echo OS: %OS%
>>"%LOGFILE%" echo ============================================
>>"%LOGFILE%" echo.

REM Run the script. Pipe ALL output (stdout + stderr) through tee-style
REM capture: shown on screen AND appended to the log file.
REM PowerShell's Tee-Object handles this in one pass.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { & '%SCRIPT%' 2>&1 | Tee-Object -FilePath '%LOGFILE%' -Append } catch { $msg = ''; $msg += [Environment]::NewLine; $msg += '==================' + [Environment]::NewLine; $msg += 'ERROR: ' + $_.Exception.Message + [Environment]::NewLine; $msg += $_.ScriptStackTrace + [Environment]::NewLine; $msg += '==================' + [Environment]::NewLine; Write-Host $msg -ForegroundColor Red; Add-Content -Path '%LOGFILE%' -Value $msg }"

echo.
>>"%LOGFILE%" echo.
>>"%LOGFILE%" echo === END OF LOG ===
echo ============================================
echo   DONE - window stays open for error review
echo.
echo   Log saved to: %LOGFILE%
echo   Send that file if you need help.
echo ============================================
pause
