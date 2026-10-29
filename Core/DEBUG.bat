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
echo   [41] Nuclear Option VR
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
echo   [131] Halo Master Chief Collection VR
echo   [132] Ring Racers VR
echo   [133] Star Trucker VR
echo   [134] Painkiller Black Edition
echo   [135] GTA Vice City VR
echo   [136] Legend of Zelda: Ocarina of Time VR
echo   [137] Mage Arena VR
echo   [138] Scrap Mechanic VR
echo   [139] Wolfenstein 3D VR
echo   [140] F.E.A.R. VR
echo   [141] Dinkum VR
echo   [142] Stardew Valley VR
echo   [143] BioShock Remastered
echo   [144] Lunacid VR
echo   [145] Witcher 3 VR
echo   [146] Rebel Galaxy VR
echo   [147] Call of Duty 4 VR
echo   [148] Ghost Recon Wildlands VR
echo   [149] Banjo-Kazooie VR
echo   [150] Mass Effect 2 LE VR
echo   [151] Pokemon Dramatic Shape VR
echo   [152] GTA IV VR
echo   [153] BioShock 2 Remastered
echo   [154] My Friendly Neighborhood VR
echo   [155] Big Walk VR
echo   [156] Diddy Kong Racing VR
echo   [157] Arma 3 VR
echo   [158] Battlefield 1942 VR
echo   [159] BioShock Infinite VR
echo   [160] C^&C Generals: Zero Hour
echo   [161] Call of Duty: World at War VR
echo   [162] Legend of Zelda: Twilight Princess
echo   [163] Pathfinder: Kingmaker
echo   [164] Outlast VR
echo   [165] Shenmue I ^& II
echo   [166] theHunter: Call of the Wild VR
echo   [167] F-Zero X VR
echo   [168] Singularity VR
echo   [169] Red Faction VR
echo   [170] AWAY VR
echo   [171] Sons of the Forest
echo   [172] White Knuckle VR
echo   [173] Virtua Cop 2 VR
echo   [174] Mass Effect 3 LE VR
echo   [175] Retrowave 2 VR
echo   [176] Elden Ring VR (Motion Controls)
echo   [177] Silent Hill VR
echo   [178] Elden Ring (Gamepad)
echo   [179] Dishonored VR
echo   [180] Star Wars Episode I Racer
echo   [181] Silent Hill 3 VR
echo   [182] Black Mesa VR
echo   [183] How to Fish XR
echo   [184] Max Payne 2 VR
echo   [185] Muck VR
echo   [186] Borderlands GOTY Enhanced
echo   [187] The Witness
echo   [188] SiN Episodes: Emergence
echo   [189] SnowRunner VR
echo   [190] Blood VR
echo   [191] Duke Nukem 3D VR
echo   [192] Shadow Warrior VR
echo   [193] Redneck Rampage VR
echo   [194] NAM VR
echo   [195] World War II GI VR
echo   [196] PowerSlave / Exhumed VR
echo   [197] Metal Gear Solid V VR
echo   [198] DOOM (2016) VR
echo   [199] Warhammer 40K: Darktide VR
echo   [200] EARTH DEFENSE FORCE 6 VR
echo   [201] Titanfall 2 VR
echo   [202] TrackMania Nations Forever
echo   [203] TrackMania United Forever
echo   [204] ELDERBORN VR
echo   [205] Gloomhaven VR
echo   [206] Prey (2006) VR
echo   [207] Tribes 2 VR
echo   [208] Deus Ex Human Revolution Director's Cut VR
echo   [209] GoldenEye 007 VR
echo   [210] Painkiller: Overdose VR
echo   [211] PowerWash Simulator 2 VR
echo   [212] Mirror's Edge VR
echo   [213] Thief (2014) VR
echo   [214] Oblivion (2006)
echo   [215] Kingdom Come: Deliverance VR
echo   [216] Mount ^& Blade II: Bannerlord VR
echo   [217] Turok VR
echo   [218] Gothic II VR
echo   [219] Outlast 2 VR
echo   [220] Unreal Revived
echo   [221] Little Witch Nobeta VR
echo   [222] X4: Foundations VR
echo   [223] Flower VR
echo   [224] Blade of Darkness VR
echo   [225] High Entropy: Challenges VR
echo   [226] Aliens versus Predator VR
echo   [227] MiSide VR
echo   [228] DOOM Eternal VR - Motion
echo   [229] No One Lives Forever VR
echo   [230] Super Mario 3D World VR
echo   [231] Star Fox Enhanced PCVR
echo   [232] SOMA VR
echo   [233] Gran Turismo 2 PCVR
echo   [234] Mario Kart Wii VR
echo   [235] A Kingdom for Keflings VR
echo   [236] PowerWash Simulator VR
echo   [237] Judgment VR
echo   [238] Diablo II: Resurrected VR
echo   [239] Dark Souls II: Scholar VR
echo   [240] The House of the Dead 2 (Original) VR
echo   [241] Descent VR
echo   [242] Descent 2 VR
echo   [243] Spider-Man Remastered - Spidy VR
echo   [244] Red Dead Redemption VR
echo   [245] Arx Fatalis VR
echo   [246] XIII Remake VR
echo   [247] Return to Castle Wolfenstein VR
echo   [248] Penumbra: Black Plague VR
echo   [249] Penumbra: Requiem VR
echo   [250] Killing Floor 2 VR
echo   [251] Forsaken VR
echo   [252] Beyond: Two Souls VR
echo   [253] Fallout 3 VR
echo   [254] Fallout: New Vegas VR
echo   [255] Teardown VR
echo   [256] Journey VR
echo   [257] Project Zomboid VR
echo   [258] Spec Ops: The Line VR
echo   [259] Alan Wake VR
echo   [260] Rustler VR
echo   [261] Brutal Legend VR
echo   [262] Call of Juarez VR
echo   [263] Mirror's Edge Catalyst VR
echo   [264] Dungeon Keeper 2 VR
echo   [265] Call of Duty (2003) VR
echo   [266] Modern Warfare 2 Campaign Remastered VR
echo   [267] Enshrouded VR
echo   [268] Bloodlines VR
echo   [269] Vampire Hunters VR
echo   [270] Hitman Blood Money VR
echo   [271] Far Cry 2 VR
echo   [272] Dishonored 2 VR
echo   [273] Forza Horizon 4 VR - GrayHorizon
echo   [274] Forza Horizon 5 VR - GrayHorizon
echo   [275] Forza Horizon 6 VR - GrayHorizon
echo   [276] GRID (2019) VR
echo   [277] GRID Legends VR
echo   [278] DiRT 4 VR
echo.
echo   [279] Dead Space 2 VR
echo   [280] Balatro VR
echo   [281] Blood West VR
echo   [282] Black and White VR
echo   [283] Dementium II HD VR
echo   [284] Tomb Raider Legend VR
echo   [285] Final Fantasy VII Remake Intergrade VR
echo   [286] HOTD2 PC2VR (second mod)
echo   [287] Call of Duty Black Ops VR
echo   [288] Among the Sleep VR
echo   [289] Call of Duty United Offensive VR
echo   [290] Ratchet ^& Clank 1 VR
echo   [291] Blur VR
echo   [292] Hitman: Contracts VR
echo   [293] Wreckfest VR
echo   [295] Aliens versus Predator 2 VR
echo   [294] Wreckfest 2 VR
set /p choice="Enter number (1-295): "
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
if "%choice%"=="41" (set SCRIPT=%~dp0NuclearOptionVR\NuclearOptionVR-core.ps1)
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
if "%choice%"=="103" (set SCRIPT=%~dp0GTAVR\GTAVR-router.ps1)
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
if "%choice%"=="123" (set SCRIPT=%~dp0RogueTraderVR\RogueTraderVR-router.ps1)
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
if "%choice%"=="135" (set SCRIPT=%~dp0ViceCityVR\ViceCityVR-core.ps1)
if "%choice%"=="136" (set SCRIPT=%~dp0OcarinaOfTimeVR\OcarinaOfTimeVR-core.ps1)
if "%choice%"=="137" (set SCRIPT=%~dp0MageArenaVR\MageArenaVR-core.ps1)
if "%choice%"=="138" (set SCRIPT=%~dp0ScrapMechanicVR\ScrapMechanicVR-core.ps1)
if "%choice%"=="139" (set SCRIPT=%~dp0Wolfenstein3DVR\Wolfenstein3DVR-core.ps1)
if "%choice%"=="140" (set SCRIPT=%~dp0FearVR\FearVR-core.ps1)
if "%choice%"=="141" (set SCRIPT=%~dp0DinkumVR\DinkumVR-core.ps1)
if "%choice%"=="142" (set SCRIPT=%~dp0StardewValleyVR\StardewValleyVR-core.ps1)
if "%choice%"=="143" (set SCRIPT=%~dp0BioshockVR\BioshockVR-core.ps1)
if "%choice%"=="144" (set SCRIPT=%~dp0LunacidVR\LunacidVR-core.ps1)
if "%choice%"=="145" (set SCRIPT=%~dp0Witcher3VR\Witcher3VR-core.ps1)
if "%choice%"=="146" (set SCRIPT=%~dp0RebelGalaxyVR\RebelGalaxyVR-core.ps1)
if "%choice%"=="147" (set SCRIPT=%~dp0CallOfDuty4VR\CallOfDuty4VR-core.ps1)
if "%choice%"=="148" (set SCRIPT=%~dp0GhostReconWildlandsVR\GhostReconWildlandsVR-core.ps1)
if "%choice%"=="149" (set SCRIPT=%~dp0BanjoKazooieVR\BanjoKazooieVR-core.ps1)
if "%choice%"=="150" (set SCRIPT=%~dp0MassEffect2VR\MassEffect2VR-core.ps1)
if "%choice%"=="151" (set SCRIPT=%~dp0Gen1RecompVR\Gen1RecompVR-core.ps1)
if "%choice%"=="152" (set SCRIPT=%~dp0GTA4VR\GTA4VR-core.ps1)
if "%choice%"=="153" (set SCRIPT=%~dp0Bioshock2VR\Bioshock2VR-core.ps1)
if "%choice%"=="154" (set SCRIPT=%~dp0MFNVR\MFNVR-core.ps1)
if "%choice%"=="155" (set SCRIPT=%~dp0BigWalkVR\BigWalkVR-core.ps1)
if "%choice%"=="156" (set SCRIPT=%~dp0DiddyKongRacingVR\DiddyKongRacingVR-core.ps1)
if "%choice%"=="157" (set SCRIPT=%~dp0Arma3VR\Arma3VR-core.ps1)
if "%choice%"=="158" (set SCRIPT=%~dp0BattlefieldVR\BattlefieldVR-core.ps1)
if "%choice%"=="159" (set SCRIPT=%~dp0BioshockInfiniteVR\BioshockInfiniteVR-core.ps1)
if "%choice%"=="160" (set SCRIPT=%~dp0GeneralsVR\GeneralsVR-core.ps1)
if "%choice%"=="161" (set SCRIPT=%~dp0CallOfDutyWaWVR\CallOfDutyWaWVR-core.ps1)
if "%choice%"=="162" (set SCRIPT=%~dp0TwilightPrincessVR\TwilightPrincessVR-core.ps1)
if "%choice%"=="163" (set SCRIPT=%~dp0PathfinderKingmakerVR\PathfinderKingmakerVR-core.ps1)
if "%choice%"=="164" (set SCRIPT=%~dp0OutlastVR\OutlastVR-core.ps1)
if "%choice%"=="165" (set SCRIPT=%~dp0ShenmueVR\ShenmueVR-core.ps1)
if "%choice%"=="166" (set SCRIPT=%~dp0TheHunterCotWVR\TheHunterCotWVR-core.ps1)
if "%choice%"=="167" (set SCRIPT=%~dp0FZeroXVR\FZeroXVR-core.ps1)
if "%choice%"=="168" (set SCRIPT=%~dp0SingularityVR\SingularityVR-core.ps1)
if "%choice%"=="169" (set SCRIPT=%~dp0RedFactionVR\RedFactionVR-core.ps1)
if "%choice%"=="170" (set SCRIPT=%~dp0AwayVR\AwayVR-core.ps1)
if "%choice%"=="171" (set SCRIPT=%~dp0SonsVR\SonsVR-core.ps1)
if "%choice%"=="172" (set SCRIPT=%~dp0WhiteKnuckleVR\WhiteKnuckleVR-core.ps1)
if "%choice%"=="173" (set SCRIPT=%~dp0VirtuaCop2VR\VirtuaCop2VR-core.ps1)
if "%choice%"=="174" (set SCRIPT=%~dp0MassEffect3VR\MassEffect3VR-core.ps1)
if "%choice%"=="175" (set SCRIPT=%~dp0Retrowave2VR\Retrowave2VR-core.ps1)
if "%choice%"=="176" (set SCRIPT=%~dp0EldenRingVR\EldenRingVR-core.ps1)
if "%choice%"=="177" (set SCRIPT=%~dp0SilentHillVR\SilentHillVR-core.ps1)
if "%choice%"=="178" (set SCRIPT=%~dp0EldenRingRealVR\EldenRingRealVR-core.ps1)
if "%choice%"=="179" (set SCRIPT=%~dp0DishonoredVR\DishonoredVR-core.ps1)
if "%choice%"=="180" (set SCRIPT=%~dp0StarWarsEpisodeIRacerVR\StarWarsEpisodeIRacerVR-core.ps1)
if "%choice%"=="181" (set SCRIPT=%~dp0SilentHill3VR\SilentHill3VR-core.ps1)
if "%choice%"=="182" (set SCRIPT=%~dp0BlackMesaVR\BlackMesaVR-core.ps1)
if "%choice%"=="183" (set SCRIPT=%~dp0HowToFishXR\HowToFishXR-core.ps1)
if "%choice%"=="184" (set SCRIPT=%~dp0MaxPayne2VR\MaxPayne2VR-core.ps1)
if "%choice%"=="185" (set SCRIPT=%~dp0MuckVR\MuckVR-core.ps1)
if "%choice%"=="186" (set SCRIPT=%~dp0BorderlandsGOTYVR\BorderlandsGOTYVR-core.ps1)
if "%choice%"=="187" (set SCRIPT=%~dp0TheWitnessVR\TheWitnessVR-core.ps1)
if "%choice%"=="188" (set SCRIPT=%~dp0SinEpisodesVR\SinEpisodesVR-core.ps1)
if "%choice%"=="189" (set SCRIPT=%~dp0SnowRunnerVR\SnowRunnerVR-core.ps1)
if "%choice%"=="190" (set SCRIPT=%~dp0BloodRazeXR\BloodRazeXR-core.ps1)
if "%choice%"=="191" (set SCRIPT=%~dp0DukeNukem3DVR\DukeNukem3DVR-core.ps1)
if "%choice%"=="192" (set SCRIPT=%~dp0ShadowWarriorRazeXR\ShadowWarriorRazeXR-core.ps1)
if "%choice%"=="193" (set SCRIPT=%~dp0RedneckRampageVR\RedneckRampageVR-core.ps1)
if "%choice%"=="194" (set SCRIPT=%~dp0NAMVR\NAMVR-core.ps1)
if "%choice%"=="195" (set SCRIPT=%~dp0WW2GIVR\WW2GIVR-core.ps1)
if "%choice%"=="196" (set SCRIPT=%~dp0PowerSlaveRazeXR\PowerSlaveRazeXR-core.ps1)
if "%choice%"=="197" (set SCRIPT=%~dp0MGS5VR\MGS5VR-core.ps1)
if "%choice%"=="198" (set SCRIPT=%~dp0Doom2016VR\Doom2016VR-core.ps1)
if "%choice%"=="199" (set SCRIPT=%~dp0DarktideVR\DarktideVR-core.ps1)
if "%choice%"=="200" (set SCRIPT=%~dp0EDF6VR\EDF6VR-core.ps1)
if "%choice%"=="201" (set SCRIPT=%~dp0Titanfall2VR\Titanfall2VR-core.ps1)
if "%choice%"=="202" (set SCRIPT=%~dp0TrackManiaNationsForeverVR\TrackManiaNationsForeverVR-core.ps1)
if "%choice%"=="203" (set SCRIPT=%~dp0TrackManiaUnitedForeverVR\TrackManiaUnitedForeverVR-core.ps1)
if "%choice%"=="204" (set SCRIPT=%~dp0ElderbornVR\ElderbornVR-core.ps1)
if "%choice%"=="205" (set SCRIPT=%~dp0GloomhavenVR\GloomhavenVR-core.ps1)
if "%choice%"=="206" (set SCRIPT=%~dp0Prey2006VR\Prey2006VR-core.ps1)
if "%choice%"=="207" (set SCRIPT=%~dp0Tribes2VR\Tribes2VR-core.ps1)
if "%choice%"=="208" (set SCRIPT=%~dp0DeusExHRVR\DeusExHRVR-core.ps1)
if "%choice%"=="209" (set SCRIPT=%~dp0GoldenEye007VR\GoldenEye007VR-core.ps1)
if "%choice%"=="210" (set SCRIPT=%~dp0PainkillerOverdoseVR\PainkillerOverdoseVR-core.ps1)
if "%choice%"=="211" (set SCRIPT=%~dp0PowerWashSimulator2VR\PowerWashSimulator2VR-core.ps1)
if "%choice%"=="212" (set SCRIPT=%~dp0MirrorsEdgeVR\MirrorsEdgeVR-core.ps1)
if "%choice%"=="213" (set SCRIPT=%~dp0Thief2014VR\Thief2014VR-core.ps1)
if "%choice%"=="214" (set SCRIPT=%~dp0Oblivion2006VR\Oblivion2006VR-core.ps1)
if "%choice%"=="215" (set SCRIPT=%~dp0KCD1VR\KCD1VR-core.ps1)
if "%choice%"=="216" (set SCRIPT=%~dp0BannerlordVR\BannerlordVR-core.ps1)
if "%choice%"=="217" (set SCRIPT=%~dp0TurokVR\TurokVR-core.ps1)
if "%choice%"=="218" (set SCRIPT=%~dp0GothicIIVR\GothicIIVR-core.ps1)
if "%choice%"=="219" (set SCRIPT=%~dp0Outlast2VR\Outlast2VR-core.ps1)
if "%choice%"=="220" (set SCRIPT=%~dp0UnrealRevivedVR\UnrealRevivedVR-core.ps1)
if "%choice%"=="221" (set SCRIPT=%~dp0LittleWitchNobetaVR\LittleWitchNobetaVR-core.ps1)
if "%choice%"=="222" (set SCRIPT=%~dp0X4VR\X4VR-core.ps1)
if "%choice%"=="223" (set SCRIPT=%~dp0FlowerVR\FlowerVR-core.ps1)
if "%choice%"=="224" (set SCRIPT=%~dp0BladeOfDarknessVR\BladeOfDarknessVR-core.ps1)
if "%choice%"=="225" (set SCRIPT=%~dp0HighEntropyVR\HighEntropyVR-core.ps1)
if "%choice%"=="226" (set SCRIPT=%~dp0AliensPredatorVR\AliensPredatorVR-core.ps1)
if "%choice%"=="227" (set SCRIPT=%~dp0MiSideVR\MiSideVR-core.ps1)
if "%choice%"=="228" (set SCRIPT=%~dp0DoomEternalMotion\DoomEternalMotion-core.ps1)
if "%choice%"=="229" (set SCRIPT=%~dp0NOLF1VR\NOLF1VR-core.ps1)
if "%choice%"=="230" (set SCRIPT=%~dp0SuperMario3DWorldVR\SuperMario3DWorldVR-core.ps1)
if "%choice%"=="231" (set SCRIPT=%~dp0StarFoxEnhancedVR\StarFoxEnhancedVR-core.ps1)
if "%choice%"=="232" (set SCRIPT=%~dp0SomaVR\SomaVR-core.ps1)
if "%choice%"=="233" (set SCRIPT=%~dp0GT2PCVR\GT2PCVR-core.ps1)
if "%choice%"=="234" (set SCRIPT=%~dp0WiiCompiledVR\WiiCompiledVR-core.ps1)
if "%choice%"=="235" (set SCRIPT=%~dp0AKingdomForKeflingsVR\AKingdomForKeflingsVR-core.ps1)
if "%choice%"=="236" (set SCRIPT=%~dp0PowerWashSimulator1VR\PowerWashSimulator1VR-core.ps1)
if "%choice%"=="237" (set SCRIPT=%~dp0JudgmentVR\JudgmentVR-core.ps1)
if "%choice%"=="238" (set SCRIPT=%~dp0Diablo2ResurrectedVR\Diablo2ResurrectedVR-core.ps1)
if "%choice%"=="239" (set SCRIPT=%~dp0DS2VR\DS2VR-core.ps1)
if "%choice%"=="240" (set SCRIPT=%~dp0HotD2VR\HotD2VR-core.ps1)
if "%choice%"=="241" (set SCRIPT=%~dp0DescentVR\DescentVR-core.ps1)
if "%choice%"=="242" (set SCRIPT=%~dp0Descent2VR\Descent2VR-core.ps1)
if "%choice%"=="243" (set SCRIPT=%~dp0SpidyVR\SpidyVR-core.ps1)
if "%choice%"=="244" (set SCRIPT=%~dp0RDRVR\RDRVR-core.ps1)
if "%choice%"=="245" (set SCRIPT=%~dp0ArxFatalisVR\ArxFatalisVR-core.ps1)
if "%choice%"=="246" (set SCRIPT=%~dp0XIIIVR\XIIIVR-core.ps1)
if "%choice%"=="247" (set SCRIPT=%~dp0RealRTCWXR\RealRTCWXR-core.ps1)
if "%choice%"=="248" (set SCRIPT=%~dp0PenumbraBlackPlagueVR\PenumbraBlackPlagueVR-core.ps1)
if "%choice%"=="249" (set SCRIPT=%~dp0PenumbraRequiemVR\PenumbraRequiemVR-core.ps1)
if "%choice%"=="250" (set SCRIPT=%~dp0KillingFloor2VR\KillingFloor2VR-core.ps1)
if "%choice%"=="251" (set SCRIPT=%~dp0ForsakenVR\ForsakenVR-core.ps1)
if "%choice%"=="252" (set SCRIPT=%~dp0BeyondTwoSoulsVR\BeyondTwoSoulsVR-core.ps1)
if "%choice%"=="253" (set SCRIPT=%~dp0Fallout3VR\Fallout3VR-core.ps1)
if "%choice%"=="254" (set SCRIPT=%~dp0FNVVR\FNVVR-core.ps1)
if "%choice%"=="255" (set SCRIPT=%~dp0TeardownVR\TeardownVR-core.ps1)
if "%choice%"=="256" (set SCRIPT=%~dp0JourneyVR\JourneyVR-core.ps1)
if "%choice%"=="257" (set SCRIPT=%~dp0ProjectZomboidVR\ProjectZomboidVR-core.ps1)
if "%choice%"=="258" (set SCRIPT=%~dp0SpecOpsTheLineVR\SpecOpsTheLineVR-core.ps1)
if "%choice%"=="259" (set SCRIPT=%~dp0AlanWakeVR\AlanWakeVR-core.ps1)
if "%choice%"=="260" (set SCRIPT=%~dp0RustlerVR\RustlerVR-core.ps1)
if "%choice%"=="261" (set SCRIPT=%~dp0BrutalLegendVR\BrutalLegendVR-core.ps1)
if "%choice%"=="262" (set SCRIPT=%~dp0CallOfJuarezVR\CallOfJuarezVR-core.ps1)
if "%choice%"=="263" (set SCRIPT=%~dp0MirrorsEdgeCatalystVR\MirrorsEdgeCatalystVR-core.ps1)
if "%choice%"=="264" (set SCRIPT=%~dp0DungeonKeeper2VR\DungeonKeeper2VR-core.ps1)
if "%choice%"=="265" (set SCRIPT=%~dp0CallOfDuty2003VR\CallOfDuty2003VR-core.ps1)
if "%choice%"=="266" (set SCRIPT=%~dp0MW2CampaignRemasteredVR\MW2CampaignRemasteredVR-core.ps1)
if "%choice%"=="267" (set SCRIPT=%~dp0EnshroudedVR\EnshroudedVR-core.ps1)
if "%choice%"=="268" (set SCRIPT=%~dp0VTMBVR\VTMBVR-core.ps1)
if "%choice%"=="269" (set SCRIPT=%~dp0VampireHuntersVR\VampireHuntersVR-core.ps1)
if "%choice%"=="270" (set SCRIPT=%~dp0HitmanBloodMoneyVR\HitmanBloodMoneyVR-core.ps1)
if "%choice%"=="271" (set SCRIPT=%~dp0FarCry2VR\FarCry2VR-core.ps1)
if "%choice%"=="272" (set SCRIPT=%~dp0Dishonored2VR\Dishonored2VR-core.ps1)
if "%choice%"=="273" (set SCRIPT=%~dp0GrayHorizonFH4\GrayHorizonFH4-core.ps1)
if "%choice%"=="274" (set SCRIPT=%~dp0GrayHorizonFH5\GrayHorizonFH5-core.ps1)
if "%choice%"=="275" (set SCRIPT=%~dp0GrayHorizonFH6\GrayHorizonFH6-core.ps1)
if "%choice%"=="276" (set SCRIPT=%~dp0Grid2019VR\Grid2019VR-core.ps1)
if "%choice%"=="277" (set SCRIPT=%~dp0GridLegendsVR\GridLegendsVR-core.ps1)
if "%choice%"=="278" (set SCRIPT=%~dp0Dirt4VR\Dirt4VR-core.ps1)
if "%choice%"=="279" (set SCRIPT=%~dp0DeadSpace2VR\DeadSpace2VR-core.ps1)
if "%choice%"=="280" (set SCRIPT=%~dp0BalatroVR\BalatroVR-core.ps1)
if "%choice%"=="281" (set SCRIPT=%~dp0BloodWestVR\BloodWestVR-core.ps1)
if "%choice%"=="282" (set SCRIPT=%~dp0BlackWhiteVR\BlackWhiteVR-core.ps1)
if "%choice%"=="283" (set SCRIPT=%~dp0DementiumIIHDVR\DementiumIIHDVR-core.ps1)
if "%choice%"=="284" (set SCRIPT=%~dp0TombRaiderLegendVR\TombRaiderLegendVR-core.ps1)
if "%choice%"=="285" (set SCRIPT=%~dp0FF7RemakeVR\FF7RemakeVR-core.ps1)
if "%choice%"=="286" (set SCRIPT=%~dp0HotD2PC2VR\HotD2PC2VR-core.ps1)
if "%choice%"=="287" (set SCRIPT=%~dp0BlackOpsVR\BlackOpsVR-core.ps1)
if "%choice%"=="288" (set SCRIPT=%~dp0AmongSleepVR\AmongSleepVR-core.ps1)
if "%choice%"=="289" (set SCRIPT=%~dp0CallOfDutyUOVR\CallOfDutyUOVR-core.ps1)


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

if "%choice%"=="290"  (set SCRIPT=%~dp0RatchetClank1VR\RatchetClank1VR-core.ps1)
if "%choice%"=="291"  (set SCRIPT=%~dp0BlurVR\BlurVR-core.ps1)
if "%choice%"=="292"  (set SCRIPT=%~dp0HitmanContractsVR\HitmanContractsVR-core.ps1)
if "%choice%"=="293"  (set SCRIPT=%~dp0WreckfestVR\WreckfestVR-core.ps1)
if "%choice%"=="294"  (set SCRIPT=%~dp0Wreckfest2VR\Wreckfest2VR-core.ps1)
if "%choice%"=="295"  (set SCRIPT=%~dp0AliensPredator2VR\AliensPredator2VR-core.ps1)
if not defined SCRIPT (echo Invalid choice. & pause & exit /b 1)

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
