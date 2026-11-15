@{
    Games = @{
        'mafia-ii-classic-vr' = @{
            AppIds=@('50130'); InstallerFolders=@('Mafia2ClassicVR')
            Files=@('pc\mafia2.exe','pc\sds\tables\tables.sds')
            FileSets=@(@{Files=@('pc\mafia2.exe','pc\sds\tables\tables.sds');RejectIfAllFiles=@('pc\Mafia II Definitive Edition.exe')})
        }
        'the-darkness-ii-vr' = @{
            AppIds=@('67370'); InstallerFolders=@('DarknessIIVR')
            Files=@('DarknessII.exe','Cache.Windows\H.Misc.cache')
            FileSets=@(@{Files=@('DarknessII.exe','Cache.Windows\H.Misc.cache')})
        }
        'tiny-tinas-wonderlands-vr' = @{
            AppIds=@('1286680'); InstallerFolders=@('WonderlandsVR')
            Files=@('OakGame\Binaries\Win64\Wonderlands.exe','OakGame\Content\Paks\pakchunk0-WindowsNoEditor.pak')
            FileSets=@(@{Files=@('OakGame\Binaries\Win64\Wonderlands.exe','OakGame\Content\Paks\pakchunk0-WindowsNoEditor.pak')})
        }
        'gothic-3-vr' = @{
            AppIds=@('39500'); InstallerFolders=@('Gothic3VR')
            Files=@('Gothic3.exe','Data\_compiledMesh.pak')
            FileSets=@(@{Files=@('Gothic3.exe','Data\_compiledMesh.pak')})
        }
        'dead-space-2008-vr' = @{
            AppIds = @('17470')
            Files = @('Dead Space.exe','global_assets\global_assets\ds_assets\char_str\corp\corcap_cct\corpse_captain.str','17470_install.vdf|goggame-1312818781.info')
            FileSets = @(
                @{ Files = @('Dead Space.exe','global_assets\global_assets\ds_assets\char_str\corp\corcap_cct\corpse_captain.str','17470_install.vdf') },
                @{ Files = @('Dead Space.exe','global_assets\global_assets\ds_assets\char_str\corp\corcap_cct\corpse_captain.str','goggame-1312818781.info') }
            )
        }
        'resident-evil-code-veronica-x-vr' = @{ InstallerFolders=@('CodeVeronicaVR'); Files=@(); ConfiguredRoots=@(@{Root='Runtime';File='save/recvx.ini';Format='INI';Section='';Key='iso';ValueType='File'},@{Root='Runtime';File='PCVR-Launcher/CodeVeronica-launch.json';Format='JSON';Key='Iso';ValueType='File'}); FileSets=@(@{Files=@();Containers=@(@{Directories=@('.');Patterns=@('*.iso');Format='PSX_DISC';Entries=@('file/SLUS_201.84','file/RDX_LNK.AFS')})}) }

        'gears-of-war-e-day-vr' = @{ AppIds=@('3010850'); InstallerFolders=@('GearsEDayVR'); Files=@('FairlightConcept\Binaries\Win64\GoWEDay-Steam.exe','FairlightConcept\Content\Paks\pakchunk0-Windows.ucas'); FileSets=@(@{Files=@('FairlightConcept\Binaries\Win64\GoWEDay-Steam.exe','FairlightConcept\Content\Paks\pakchunk0-Windows.ucas')}) }

        'resident-evil-5-vr' = @{ AppIds=@('21690'); InstallerFolders=@('RE5VR'); Files=@('re5dx9.exe','nativePC_MT\Image\Archive\CoreResource.arc'); FileSets=@(@{Files=@('re5dx9.exe','nativePC_MT\Image\Archive\CoreResource.arc')}) }

        'i-hate-this-place-vr' = @{ AppIds=@('2604490'); InstallerFolders=@('IHateThisPlaceVR'); Files=@('I Hate This Place.exe','I Hate This Place_Data\globalgamemanagers'); FileSets=@(@{Files=@('I Hate This Place.exe','I Hate This Place_Data\globalgamemanagers')}) }
        'agent-64-spies-never-die-vr' = @{ AppIds=@('1574480'); InstallerFolders=@('Agent64VR'); Files=@('Agent 64 Spies Never Die.exe','Agent 64 Spies Never Die_Data\globalgamemanagers'); FileSets=@(@{Files=@('Agent 64 Spies Never Die.exe','Agent 64 Spies Never Die_Data\globalgamemanagers')}) }
        '7-days-to-die-vr' = @{
            AppIds = @('251570')
            InstallerFolders = @('7DaysVR')
            Files = @('7DaysToDie.exe','7DaysToDie_Data\data.unity3d|7DaysToDie_Data\globalgamemanagers')
            FileSets = @(
                @{ Files = @('7DaysToDie.exe','7DaysToDie_Data\data.unity3d|7DaysToDie_Data\globalgamemanagers') }
            )
        }
        'a-kingdom-for-keflings-vr' = @{
            InstallerFolders = @('AKingdomForKeflingsVR')
            Files = @('A Kingdom for Keflings.exe','fsall/blockfiles/Full_Game.blk.bz2')
            FileSets = @(
                @{ Files = @('A Kingdom for Keflings.exe','fsall/blockfiles/Full_Game.blk.bz2') }
            )
        }
        'alien-isolation-vr' = @{
            AppIds = @('214490')
            InstallerFolders = @('AlienIsolationVR')
            Files = @('AI.exe','DATA\UI.PAK|DATA\GLOBAL\UI.PAK')
            FileSets = @(
                @{ Files = @('AI.exe','DATA\UI.PAK|DATA\GLOBAL\UI.PAK') }
            )
        }
        'aliens-versus-predator-vr' = @{
            AppIds = @('3730')
            InstallerFolders = @('AliensPredatorVR')
            Files = @('AvP.exe|AvP_Classic.exe|bin\AvP_Classic.exe|bin\_Crossplay\AvP_Classic.exe','avp_huds\alien.rif')
            FileSets = @(
                @{ Files = @('AvP.exe|AvP_Classic.exe|bin\AvP_Classic.exe|bin\_Crossplay\AvP_Classic.exe','avp_huds\alien.rif') }
            )
        }
        'aliens-versus-predator-2-vr' = @{
            InstallerFolders = @('AliensPredator2VR')
            Files = @('AVP2.exe','AVP2.rez')
            FileSets = @(
                @{ Files = @('AVP2.exe','AVP2.rez') }
            )
        }
        'amnesia-vr' = @{
            AppIds = @('57300')
            InstallerFolders = @('AmnesiaVR')
            Files = @('Amnesia.exe','maps\main\ch01\00_rainy_hall.map')
            FileSets = @(
                @{ Files = @('Amnesia.exe','maps\main\ch01\00_rainy_hall.map') }
            )
        }
        'among-the-sleep-vr' = @{
            AppIds = @('250620')
            InstallerFolders = @('AmongSleepVR')
            Files = @('Among the Sleep.exe','Among the Sleep_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Among the Sleep.exe','Among the Sleep_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'anomaly-vr' = @{
            InstallerFolders = @('AnomalyVR')
            Files = @('bin/AnomalyDX11.exe','db/configs/configs.db0')
            FileSets = @(
                @{ Files = @('bin/AnomalyDX11.exe','db/configs/configs.db0') }
            )
        }
        'anomaly-gamma' = @{
            InstallerFolders = @('AnomalyGammaVR')
            Files = @('STALKERVR_GAMMA/bin/AnomalyDX11.exe','STALKERVR_GAMMA/db/configs/configs.db0')
            FileSets = @(
                @{ Files = @('STALKERVR_GAMMA/bin/AnomalyDX11.exe','STALKERVR_GAMMA/db/configs/configs.db0') }
            )
        }
        'arma-3-vr' = @{
            AppIds = @('107410')
            InstallerFolders = @('Arma3VR')
            Files = @('arma3_x64.exe|arma3.exe','Addons\data_f.pbo')
            FileSets = @(
                @{ Files = @('arma3_x64.exe|arma3.exe','Addons\data_f.pbo') }
            )
        }
        'arx-fatalis-vr' = @{
            AppIds = @('1700')
            InstallerFolders = @('ArxFatalisVR')
            Files = @('data.pak','sfx.pak|sfx_default.pak')
            FileSets = @(
                @{ Files = @('data.pak','sfx.pak|sfx_default.pak') }
            )
        }
        'away-vr' = @{
            AppIds = @('573110')
            InstallerFolders = @('AwayVR')
            Files = @('Away.exe','Away_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Away.exe','Away_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'balatro-vr' = @{
            AppIds = @('2379780')
            InstallerFolders = @('BalatroVR')
            Files = @('Balatro.exe')
            FileSets = @(
                @{ Files = @('Balatro.exe'); Containers = @(@{ File = 'Balatro.exe'; Format = 'ZIP'; Entries = @('card.lua','resources/textures/1x/Jokers.png') }) }
            )
        }
        'battlefield-1942-vr' = @{
            InstallerFolders = @('BattlefieldVR')
            Files = @('BF1942.exe','Mods\bf1942\Archives\bf1942\Game.rfa')
            FileSets = @(
                @{ Files = @('BF1942.exe','Mods\bf1942\Archives\bf1942\Game.rfa') }
            )
        }
        'beyond-two-souls-vr' = @{
            AppIds = @('960990')
            InstallerFolders = @('BeyondTwoSoulsVR')
            Files = @('BeyondTwoSouls_Steam.exe|BeyondTwoSouls.exe','BigFile_PC.dat')
            FileSets = @(
                @{ Files = @('BeyondTwoSouls_Steam.exe','BigFile_PC.dat') }
                @{ Files = @('BeyondTwoSouls.exe','BigFile_PC.dat') }
            )
        }
        'bendy-vr' = @{
            AppIds = @('622650')
            InstallerFolders = @('BendyVR')
            Files = @('Bendy and the Ink Machine.exe','Bendy and the Ink Machine_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Bendy and the Ink Machine.exe','Bendy and the Ink Machine_Data\resources.assets') }
            )
        }
        'big-walk-vr' = @{
            AppIds = @('1478500')
            InstallerFolders = @('BigWalkVR')
            Files = @('Big Walk.exe','Big Walk_Data\data.unity3d')
            FileSets = @(
                @{ Files = @('Big Walk.exe','Big Walk_Data\data.unity3d') }
            )
        }
        'bioshock-remastered' = @{
            AppIds = @('409710')
            InstallerFolders = @('BioshockVR')
            Files = @('Build\Final\BioshockHD.exe|Build\FinalEpic\BioshockHD.exe','ContentBaked\pc\Maps\1-Medical.bsm')
            FileSets = @(
                @{ Files = @('Build\Final\BioshockHD.exe|Build\FinalEpic\BioshockHD.exe','ContentBaked\pc\Maps\1-Medical.bsm') }
            )
        }
        'bioshock-2-remastered' = @{
            AppIds = @('409720')
            InstallerFolders = @('Bioshock2VR')
            Files = @('Build\Final\Bioshock2HD.exe|Build\FinalEpic\Bioshock2HD.exe','ContentBaked\pc\Maps\WelcomeBack.bsm')
            FileSets = @(
                @{ Files = @('Build\Final\Bioshock2HD.exe|Build\FinalEpic\Bioshock2HD.exe','ContentBaked\pc\Maps\WelcomeBack.bsm') }
            )
        }
        'bioshock-infinite-vr' = @{
            AppIds = @('8870')
            InstallerFolders = @('BioshockInfiniteVR')
            Files = @('Binaries\Win32\BioShockInfinite.exe','XGame\CookedPCConsole_FR\Startup.xxx')
            FileSets = @(
                @{ Files = @('Binaries\Win32\BioShockInfinite.exe','XGame\CookedPCConsole_FR\Startup.xxx') }
            )
        }
        'black-white-vr' = @{
            InstallerFolders = @('BlackWhiteVR')
            Files = @('runblack.exe','Data\Landscape\Land1.lnd')
            FileSets = @(
                @{ Files = @('runblack.exe','Data\Landscape\Land1.lnd') }
            )
        }
        'black-mesa' = @{
            AppIds = @('362890')
            InstallerFolders = @('BlackMesaVR')
            Files = @('bms.exe','bms\bms_maps_dir.vpk')
            FileSets = @(
                @{ Files = @('bms.exe','bms\bms_maps_dir.vpk') }
            )
        }
        'black-mesa-source-vr' = @{
            InstallerFolders = @('BMSVR')
            Files = @('ep2/maps/ep2_outland_01.bsp','ep2/maps/ep2_outland_02.bsp')
            FileSets = @(
                @{ Files = @('ep2/maps/ep2_outland_01.bsp','ep2/maps/ep2_outland_02.bsp') }
            )
        }
        'blood-vr' = @{
            AppIds = @('299030')
            InstallerFolders = @('BloodRazeXR')
            Files = @('BLOOD.RFF|games\blood\BLOOD.RFF','SOUNDS.RFF|games\blood\SOUNDS.RFF')
            FileSets = @(
                @{ Files = @('BLOOD.RFF|games\blood\BLOOD.RFF','SOUNDS.RFF|games\blood\SOUNDS.RFF') }
            )
        }
        'blood-west-vr' = @{
            AppIds = @('1587130')
            InstallerFolders = @('BloodWestVR')
            Files = @('Blood West.exe','Blood West_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Blood West.exe','Blood West_Data\resources.assets') }
            )
        }
        'borderlands-goty-enhanced' = @{
            AppIds = @('729040')
            InstallerFolders = @('BorderlandsGOTYVR')
            Files = @('Binaries\Win64\BorderlandsGOTY.exe','WillowGame\CookedPC\Maps\Arid\Arid_P.umap')
            FileSets = @(
                @{ Files = @('Binaries\Win64\BorderlandsGOTY.exe','WillowGame\CookedPC\Maps\Arid\Arid_P.umap') }
            )
        }
        'brutal-legend-vr' = @{
            AppIds = @('225260')
            InstallerFolders = @('BrutalLegendVR')
            Files = @('BrutalLegend.exe','Win\Packs\00Startup.~p')
            FileSets = @(
                @{ Files = @('BrutalLegend.exe','Win\Packs\00Startup.~p') }
            )
        }
        'c-c-generals-zero-hour' = @{
            AppIds = @('2732960')
            InstallerFolders = @('GeneralsVR')
            Files = @('INIZH.big','MapsZH.big')
            FileSets = @(
                @{ Files = @('INIZH.big','MapsZH.big') }
            )
        }
        'call-of-duty-black-ops-vr' = @{
            AppIds = @('42700')
            InstallerFolders = @('BlackOpsVR')
            Files = @('BlackOps.exe','main\iw_00.iwd')
            FileSets = @(
                @{ Files = @('BlackOps.exe','main\iw_00.iwd') }
            )
        }
        'call-of-duty-2003-vr' = @{
            AppIds = @('2620')
            InstallerFolders = @('CallOfDuty2003VR')
            Files = @('CoDSP.exe','main\pak0.pk3')
            FileSets = @(
                @{ Files = @('CoDSP.exe','main\pak0.pk3') }
            )
        }
        'call-of-duty-4-vr' = @{
            AppIds = @('7940')
            InstallerFolders = @('CallOfDuty4VR')
            Files = @('iw3sp.exe|iw3mp.exe','main\iw_00.iwd')
            FileSets = @(
                @{ Files = @('iw3sp.exe|iw3mp.exe','main\iw_00.iwd') }
            )
        }
        'modern-warfare-2-campaign-remastered-vr' = @{
            InstallerFolders = @('MW2CampaignRemasteredVR')
            Files = @('MW2CR.exe','Data/data/data.000')
            FileSets = @(
                @{ Files = @('MW2CR.exe','Data/data/data.000') }
            )
        }
        'call-of-duty-united-offensive-vr' = @{
            AppIds = @('2640')
            InstallerFolders = @('CallOfDutyUOVR')
            Files = @('CoDUOSP.exe','uo\pakuo00.pk3')
            FileSets = @(
                @{ Files = @('CoDUOSP.exe','uo\pakuo00.pk3') }
            )
        }
        'call-of-duty-world-at-war-vr' = @{
            AppIds = @('10090')
            InstallerFolders = @('CallOfDutyWaWVR')
            Files = @('CoDWaW.exe','main\iw_00.iwd')
            FileSets = @(
                @{ Files = @('CoDWaW.exe','main\iw_00.iwd') }
            )
        }
        'call-of-juarez-vr' = @{
            AppIds = @('3020')
            InstallerFolders = @('CallOfJuarezVR')
            Files = @('CoJ.exe','Data0.pak')
            FileSets = @(
                @{ Files = @('CoJ.exe','Data0.pak') }
            )
        }
        'content-warning-vr' = @{
            AppIds = @('2881650')
            InstallerFolders = @('ContentWarningVR')
            Files = @('Content Warning.exe','Content Warning_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Content Warning.exe','Content Warning_Data\resources.assets') }
            )
        }
        'cruelty-squad-vr' = @{
            AppIds = @('1388770')
            InstallerFolders = @('CrueltySquadVR')
            Files = @('crueltysquad.exe|crueltysquad32.exe','crueltysquad.pck')
            FileSets = @(
                @{ Files = @('crueltysquad.exe|crueltysquad32.exe','crueltysquad.pck') }
            )
        }
        'cyberpunk-2077' = @{
            AppIds = @('1091500')
            InstallerFolders = @('Cyberpunk2077VR')
            Files = @('bin\x64\Cyberpunk2077.exe','archive\pc\content\basegame_1_engine.archive')
            FileSets = @(
                @{ Files = @('bin\x64\Cyberpunk2077.exe','archive\pc\content\basegame_1_engine.archive') }
            )
        }
        'daggerfall-vr' = @{
            AppIds = @('1812390')
            InstallerFolders = @('DaggerfallUnityVR')
            Files = @('DF/DAGGER/ARENA2/ARCH3D.BSA|DAGGER/ARENA2/ARCH3D.BSA|ARENA2/ARCH3D.BSA|ARCH3D.BSA','DF/DAGGER/ARENA2/BLOCKS.BSA|DAGGER/ARENA2/BLOCKS.BSA|ARENA2/BLOCKS.BSA|BLOCKS.BSA')
            ConfiguredRoots = @(@{ Root = 'UserProfile'; File = 'AppData/LocalLow/Daggerfall Workshop/Daggerfall Unity/settings.ini'; Format = 'INI'; Section = 'Daggerfall'; Key = 'MyDaggerfallPath' },@{ Root = 'UserProfile'; File = '.config/unity3d/Daggerfall Workshop/Daggerfall Unity/settings.ini'; Format = 'INI'; Section = 'Daggerfall'; Key = 'MyDaggerfallPath' },@{ Root = 'UserProfile'; File = 'Library/Application Support/Daggerfall Workshop/Daggerfall Unity/settings.ini'; Format = 'INI'; Section = 'Daggerfall'; Key = 'MyDaggerfallPath' })
            FileSets = @(
                @{ Files = @('DF/DAGGER/ARENA2/ARCH3D.BSA','DF/DAGGER/ARENA2/BLOCKS.BSA') }
                @{ Files = @('DAGGER/ARENA2/ARCH3D.BSA','DAGGER/ARENA2/BLOCKS.BSA') }
                @{ Files = @('ARENA2/ARCH3D.BSA','ARENA2/BLOCKS.BSA') }
                @{ Files = @('ARCH3D.BSA','BLOCKS.BSA') }
            )
        }
        'dark-souls-ii-motion-vr' = @{
            AppIds = @('335300')
            InstallerFolders = @('DS2VR')
            Files = @('Game\DarkSoulsII.exe','Game\GameDataEbl.bdt')
            FileSets = @(
                @{ Files = @('Game\DarkSoulsII.exe','Game\GameDataEbl.bdt') }
            )
        }
        'dead-space-2-vr' = @{
            AppIds = @('47780')
            InstallerFolders = @('DeadSpace2VR')
            Files = @('deadspace2.exe','DS2DAT6.DAT')
            FileSets = @(
                @{ Files = @('deadspace2.exe','DS2DAT6.DAT') }
            )
        }
        'dementium-ii-hd-vr' = @{
            AppIds = @('217100')
            InstallerFolders = @('DementiumIIHDVR')
            Files = @('DII_Beta.exe','DII_Beta_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('DII_Beta.exe','DII_Beta_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'descent-2-vr' = @{
            AppIds = @('273580')
            InstallerFolders = @('Descent2VR')
            Files = @('descent2.hog|descent2\descent2.hog','descent2.ham|descent2\descent2.ham')
            FileSets = @(
                @{ Files = @('descent2.hog','descent2.ham') }
                @{ Files = @('descent2\descent2.hog','descent2\descent2.ham') }
            )
        }
        'descent-vr' = @{
            AppIds = @('273570')
            InstallerFolders = @('DescentVR')
            Files = @('descent.hog|descent\descent.hog','descent.pig|descent\descent.pig')
            FileSets = @(
                @{ Files = @('descent.hog','descent.pig') }
                @{ Files = @('descent\descent.hog','descent\descent.pig') }
            )
        }
        'deep-rock-galactic-vr' = @{
            AppIds = @('548430')
            InstallerFolders = @('DRGVRG')
            Files = @('FSD\Binaries\Win64\FSD-Win64-Shipping.exe|FSD\Binaries\WinGDK\FSD-WinGDK-Shipping.exe','FSD\Content\Paks\FSD-WindowsNoEditor.pak|FSD\Content\Paks\FSD-WinGDK.pak')
            FileSets = @(
                @{ Files = @('FSD\Binaries\Win64\FSD-Win64-Shipping.exe','FSD\Content\Paks\FSD-WindowsNoEditor.pak') }
                @{ Files = @('FSD\Binaries\WinGDK\FSD-WinGDK-Shipping.exe','FSD\Content\Paks\FSD-WinGDK.pak') }
            )
        }
        'deus-ex-human-revolution-directors-cut-vr' = @{
            AppIds = @('238010')
            InstallerFolders = @('DeusExHRVR')
            Files = @('DXHRDC.exe','BIGFILE.000')
            FileSets = @(
                @{ Files = @('DXHRDC.exe','BIGFILE.000') }
            )
        }
        'diablo-ii-resurrected-vr' = @{
            AppIds = @('2536520')
            InstallerFolders = @('Diablo2ResurrectedVR')
            Files = @('D2R.exe','data\data\data.000|data\00-00000001.data')
            FileSets = @(
                @{ Files = @('D2R.exe','data\data\data.000|data\00-00000001.data') }
            )
        }
        'dishonored-vr' = @{
            AppIds = @('205100')
            InstallerFolders = @('DishonoredVR')
            Files = @('Binaries\Win32\Dishonored.exe','DishonoredGame\CookedPCConsole\DishonoredGame.upk')
            FileSets = @(
                @{ Files = @('Binaries\Win32\Dishonored.exe','DishonoredGame\CookedPCConsole\DishonoredGame.upk') }
            )
        }
        'dishonored-2-vr' = @{
            AppIds = @('403640')
            InstallerFolders = @('Dishonored2VR')
            Files = @('Dishonored2.exe','base\game1.resources')
            FileSets = @(
                @{ Files = @('Dishonored2.exe','base\game1.resources') }
            )
        }
        'dungeon-keeper-2-vr' = @{
            AppIds = @('2616460')
            InstallerFolders = @('DungeonKeeper2VR')
            Files = @('DKII-DX.exe|DKII.exe','Data\editor\Creatures.kwd')
            FileSets = @(
                @{ Files = @('DKII-DX.exe|DKII.exe','Data\editor\Creatures.kwd') }
            )
        }
        'doom-2016-vr' = @{
            AppIds = @('379720')
            InstallerFolders = @('Doom2016VR')
            Files = @('DOOMx64.exe|DOOMx64vk.exe','base\gameresources.resources')
            FileSets = @(
                @{ Files = @('DOOMx64.exe|DOOMx64vk.exe','base\gameresources.resources') }
            )
        }
        'doom-eternal-motion-vr' = @{
            AppIds = @('782330')
            InstallerFolders = @('DoomEternalMotion')
            Files = @('DOOMEternalx64vk.exe','base\gameresources.resources')
            FileSets = @(
                @{ Files = @('DOOMEternalx64vk.exe','base\gameresources.resources') }
            )
        }
        'doom-vr' = @{
            AppIds = @('2280')
            InstallerFolders = @('DoomVR')
            Files = @('DOOM.WAD|base/DOOM.WAD|base/wads/DOOM.WAD|base/classicwads/DOOM.WAD|rerelease/DOOM.WAD|rerelease/base/DOOM.WAD|classicwads/DOOM.WAD|wads/DOOM.WAD|base/doom/DOOM.WAD|base/doom2/DOOM.WAD|base/heretic/DOOM.WAD|base/hexen/DOOM.WAD|base/classic/DOOM.WAD')
            FileSets = @(
                @{ Files = @('DOOM.WAD|base/DOOM.WAD|base/wads/DOOM.WAD|base/classicwads/DOOM.WAD|rerelease/DOOM.WAD|rerelease/base/DOOM.WAD|classicwads/DOOM.WAD|wads/DOOM.WAD|base/doom/DOOM.WAD|base/doom2/DOOM.WAD|base/heretic/DOOM.WAD|base/hexen/DOOM.WAD|base/classic/DOOM.WAD'); Containers = @(@{ File = 'DOOM.WAD|base/DOOM.WAD|base/wads/DOOM.WAD|base/classicwads/DOOM.WAD|rerelease/DOOM.WAD|rerelease/base/DOOM.WAD|classicwads/DOOM.WAD|wads/DOOM.WAD|base/doom/DOOM.WAD|base/doom2/DOOM.WAD|base/heretic/DOOM.WAD|base/hexen/DOOM.WAD|base/classic/DOOM.WAD'; Format = 'WAD'; Entries = @('BFGGA0','PLAYPAL','PNAMES','TEXTURE1'); Maps = @('E1M1','E2M1','E3M1'); Excluded = @('FREEDOOM','FREEDM') }) }
            )
        }
        'doom-2-vr' = @{
            AppIds = @('2300')
            InstallerFolders = @('Doom2VR')
            Files = @('DOOM2.WAD|base/DOOM2.WAD|base/wads/DOOM2.WAD|base/classicwads/DOOM2.WAD|rerelease/DOOM2.WAD|rerelease/base/DOOM2.WAD|classicwads/DOOM2.WAD|wads/DOOM2.WAD|base/doom/DOOM2.WAD|base/doom2/DOOM2.WAD|base/heretic/DOOM2.WAD|base/hexen/DOOM2.WAD|base/classic/DOOM2.WAD')
            FileSets = @(
                @{ Files = @('DOOM2.WAD|base/DOOM2.WAD|base/wads/DOOM2.WAD|base/classicwads/DOOM2.WAD|rerelease/DOOM2.WAD|rerelease/base/DOOM2.WAD|classicwads/DOOM2.WAD|wads/DOOM2.WAD|base/doom/DOOM2.WAD|base/doom2/DOOM2.WAD|base/heretic/DOOM2.WAD|base/hexen/DOOM2.WAD|base/classic/DOOM2.WAD'); Containers = @(@{ File = 'DOOM2.WAD|base/DOOM2.WAD|base/wads/DOOM2.WAD|base/classicwads/DOOM2.WAD|rerelease/DOOM2.WAD|rerelease/base/DOOM2.WAD|classicwads/DOOM2.WAD|wads/DOOM2.WAD|base/doom/DOOM2.WAD|base/doom2/DOOM2.WAD|base/heretic/DOOM2.WAD|base/hexen/DOOM2.WAD|base/classic/DOOM2.WAD'; Format = 'WAD'; Entries = @('BFGGA0','PLAYPAL','PNAMES','TEXTURE1'); Maps = @('MAP01','MAP02','MAP30'); Excluded = @('FREEDOOM','FREEDM') }) }
            )
        }
        'doom-3-bfg-vr' = @{
            AppIds = @('208200')
            InstallerFolders = @('Doom3BFGVR')
            Files = @('Doom3BFG.exe','base\_common.resources')
            FileSets = @(
                @{ Files = @('Doom3BFG.exe','base\_common.resources') }
            )
        }
        'dredge-vr' = @{
            AppIds = @('1562430')
            InstallerFolders = @('DredgeVR')
            Files = @('DREDGE.exe','DREDGE_Data\resources.assets')
            FileSets = @(
                @{ Files = @('DREDGE.exe','DREDGE_Data\resources.assets') }
            )
        }
        'duke-nukem-3d-vr' = @{
            AppIds = @('434050')
            InstallerFolders = @('DukeNukem3DVR')
            Files = @('DUKE3D.GRP|gameroot/DUKE3D.GRP|bin/DUKE3D.GRP|games/duke/DUKE3D.GRP')
            FileSets = @(
                @{ Files = @('DUKE3D.GRP|gameroot/DUKE3D.GRP|bin/DUKE3D.GRP|games/duke/DUKE3D.GRP'); Containers = @(@{ File = 'DUKE3D.GRP|gameroot/DUKE3D.GRP|bin/DUKE3D.GRP|games/duke/DUKE3D.GRP'; Format = 'GRP'; Entries = @('E2L10.MAP','E3L10.MAP','GAME.CON') }) }
            )
        }
        'dusk-hd-dlc-vr' = @{
            AppIds = @('519860')
            InstallerFolders = @('DuskHDVR')
            Files = @('DLC/DUSK HD/Dusk.exe','DLC/DUSK HD/Dusk_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('DLC/DUSK HD/Dusk.exe','DLC/DUSK HD/Dusk_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'earth-defense-force-6-vr' = @{
            AppIds = @('2291060')
            InstallerFolders = @('EDF6VR')
            Files = @('EDF6.exe','Root.cpk')
            FileSets = @(
                @{ Files = @('EDF6.exe','Root.cpk') }
            )
        }
        'elden-ring-motion-controls' = @{
            AppIds = @('1245620')
            InstallerFolders = @('EldenRingVR')
            Files = @('Game\eldenring.exe','Game\Data0.bdt')
            FileSets = @(
                @{ Files = @('Game\eldenring.exe','Game\Data0.bdt') }
            )
        }
        'elderborn-vr' = @{
            AppIds = @('727850')
            InstallerFolders = @('ElderbornVR')
            Files = @('ELDERBORN.exe','ELDERBORN_Data\resources.assets')
            FileSets = @(
                @{ Files = @('ELDERBORN.exe','ELDERBORN_Data\resources.assets') }
            )
        }
        'enshrouded-vr' = @{
            AppIds = @('1203620')
            InstallerFolders = @('EnshroudedVR')
            Files = @('enshrouded.exe','enshrouded.kfc')
            FileSets = @(
                @{ Files = @('enshrouded.exe','enshrouded.kfc') }
            )
        }
        'escape-from-tarkov-vr' = @{
            AppIds = @('3932890')
            InstallerFolders = @('SPTVR')
            Files = @('EscapeFromTarkov.exe','EscapeFromTarkov_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('EscapeFromTarkov.exe','EscapeFromTarkov_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'f-e-a-r-vr' = @{
            AppIds = @('21090')
            InstallerFolders = @('FearVR')
            Files = @('FEAR.exe','FEARA.Arch00')
            FileSets = @(
                @{ Files = @('FEAR.exe','FEARA.Arch00') }
            )
        }
        'fallout-3-vr' = @{
            AppIds = @('22370')
            InstallerFolders = @('Fallout3VR')
            Files = @('Fallout3.exe','Data\Fallout3.esm')
            FileSets = @(
                @{ Files = @('Fallout3.exe','Data\Fallout3.esm') }
            )
        }
        'far-cry-2-vr' = @{
            AppIds = @('19900')
            InstallerFolders = @('FarCry2VR')
            Files = @('bin\FarCry2.exe','Data_Win32\worlds\worlds.dat')
            FileSets = @(
                @{ Files = @('bin\FarCry2.exe','Data_Win32\worlds\worlds.dat') }
            )
        }
        'fallout-new-vegas-vr' = @{
            AppIds = @('22380')
            InstallerFolders = @('FNVVR')
            Files = @('FalloutNV.exe','Data\Fallout - Meshes.bsa')
            FileSets = @(
                @{ Files = @('FalloutNV.exe','Data\Fallout - Meshes.bsa') }
            )
        }
        'final-fantasy-xiv-vr' = @{
            AppIds = @('39210')
            InstallerFolders = @('FfxivVR')
            Files = @('game/ffxiv_dx11.exe|ffxiv_dx11.exe','game/sqpack/ffxiv/000000.win32.index|sqpack/ffxiv/000000.win32.index','game/sqpack/ffxiv/000000.win32.dat0|sqpack/ffxiv/000000.win32.dat0')
            FileSets = @(
                @{ Files = @('game/ffxiv_dx11.exe','game/sqpack/ffxiv/000000.win32.index','game/sqpack/ffxiv/000000.win32.dat0') }
                @{ Files = @('ffxiv_dx11.exe','sqpack/ffxiv/000000.win32.index','sqpack/ffxiv/000000.win32.dat0') }
            )
        }
        'flower-vr' = @{
            AppIds = @('966330')
            InstallerFolders = @('FlowerVR')
            Files = @('Flower.exe','Flower.xme')
            FileSets = @(
                @{ Files = @('Flower.exe','Flower.xme') }
            )
        }
        'hitman-contracts-vr' = @{
            AppIds = @('247430')
            InstallerFolders = @('HitmanContractsVR')
            Files = @('HitmanContracts.exe','Scenes\C00-1\C00-1_MAIN.ZIP')
            FileSets = @(
                @{ Files = @('HitmanContracts.exe','Scenes\C00-1\C00-1_MAIN.ZIP') }
            )
        }
        'journey-vr' = @{
            AppIds = @('638230')
            InstallerFolders = @('JourneyVR')
            Files = @('Journey.exe','Journey.xme')
            FileSets = @(
                @{ Files = @('Journey.exe','Journey.xme') }
            )
        }
        'forsaken-vr' = @{
            AppIds = @('668980')
            InstallerFolders = @('ForsakenVR')
            Files = @('selkis_x64.exe|game/Data/levels/alpha/alpha.mxv|VR/game/Data/levels/alpha/alpha.mxv|Data/levels/alpha/alpha.mxv','ForsakenEX.kpf|game/Data/levels/mission.dat|VR/game/Data/levels/mission.dat|Data/levels/mission.dat')
            FileSets = @(
                @{ Files = @('selkis_x64.exe','ForsakenEX.kpf') }
                @{ Files = @('game/Data/levels/alpha/alpha.mxv','game/Data/levels/mission.dat') }
                @{ Files = @('VR/game/Data/levels/alpha/alpha.mxv','VR/game/Data/levels/mission.dat') }
                @{ Files = @('Data/levels/alpha/alpha.mxv','Data/levels/mission.dat') }
            )
        }
        'garry-s-mod-vr' = @{
            AppIds = @('4000')
            InstallerFolders = @('GModVR')
            Files = @('gmod.exe|hl2.exe','garrysmod/garrysmod_000.vpk','garrysmod/gamemodes/sandbox/gamemode/init.lua')
            FileSets = @(
                @{ Files = @('gmod.exe','garrysmod/garrysmod_000.vpk','garrysmod/gamemodes/sandbox/gamemode/init.lua') }
                @{ Files = @('hl2.exe','garrysmod/garrysmod_000.vpk','garrysmod/gamemodes/sandbox/gamemode/init.lua') }
            )
        }
        'gloomhaven-vr' = @{
            AppIds = @('780290')
            InstallerFolders = @('GloomhavenVR')
            Files = @('GH.exe','GH_Data\Managed\GH.Runtime.dll')
            FileSets = @(
                @{ Files = @('GH.exe','GH_Data\Managed\GH.Runtime.dll') }
            )
        }
        'goldeneye-007-vr' = @{
            InstallerFolders = @('GoldenEye007VR')
            Files = @('GevrRomStarter.exe','baserom.us.z64','baserom.z64')
            FileSets = @(
                @{ Files = @(); Containers = @(@{ Directories = @('.','roms','data'); Patterns = @('*.z64','*.v64','*.n64'); Format = 'N64'; Entries = @('title/GOLDENEYE','cartridge/NGEE|cartridge/NGEP|cartridge/NGEJ') }) }
            )
        }
        'gothic-ii-vr' = @{
            AppIds = @('39510')
            InstallerFolders = @('GothicIIVR')
            Files = @('system\Gothic2.exe','Data\Textures.vdf')
            FileSets = @(
                @{ Files = @('system\Gothic2.exe','Data\Textures.vdf') }
            )
        }
        'grand-theft-auto-v-vr' = @{
            AppIds = @('271590')
            InstallerFolders = @('GTAVR')
            Files = @('GTA5.exe','x64a.rpf')
            FileSets = @(
                @{ Files = @('GTA5.exe','x64a.rpf') }
            )
        }
        'gta-iv-vr' = @{
            AppIds = @('12210')
            InstallerFolders = @('GTA4VR')
            Files = @('GTAIV.exe|GTAIV\GTAIV.exe','pc\models\cdimages\vehicles.img|GTAIV\pc\models\cdimages\vehicles.img')
            FileSets = @(
                @{ Files = @('GTAIV.exe','pc\models\cdimages\vehicles.img') }
                @{ Files = @('GTAIV\GTAIV.exe','GTAIV\pc\models\cdimages\vehicles.img') }
            )
        }
        'gta-vice-city-vr' = @{
            AppIds = @('12110')
            InstallerFolders = @('ViceCityVR')
            Files = @('gta-vc.exe','models\gta3.img')
            FileSets = @(
                @{ Files = @('gta-vc.exe','models\gta3.img') }
            )
        }
        'gtfo-vr' = @{
            AppIds = @('493520')
            InstallerFolders = @('GTFOVR')
            Files = @('GTFO.exe','GTFO_Data\resources.assets')
            FileSets = @(
                @{ Files = @('GTFO.exe','GTFO_Data\resources.assets') }
            )
        }
        'gunfire-reborn' = @{
            AppIds = @('1217060')
            InstallerFolders = @('GunfireReborn_VR')
            Files = @('Gunfire Reborn.exe','Gunfire Reborn_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Gunfire Reborn.exe','Gunfire Reborn_Data\resources.assets') }
            )
        }
        'halo-3-mcc-vr' = @{
            AppIds = @('976730')
            InstallerFolders = @('Halo3MCCVR')
            Files = @('MCC/Binaries/Win64/MCC-Win64-Shipping.exe|MCC/Binaries/Win64/MCCWinStore-Win64-Shipping.exe|MCC/Binaries/Win64/MCC-Win64-Shipping-WinStore.exe','MCC/Content/Paks/MCC-WindowsNoEditor.pak')
            FileSets = @(
                @{ Files = @('MCC/Binaries/Win64/MCC-Win64-Shipping.exe','MCC/Content/Paks/MCC-WindowsNoEditor.pak') }
                @{ Files = @('MCC/Binaries/Win64/MCCWinStore-Win64-Shipping.exe','MCC/Content/Paks/MCC-WindowsNoEditor.pak') }
                @{ Files = @('MCC/Binaries/Win64/MCC-Win64-Shipping-WinStore.exe','MCC/Content/Paks/MCC-WindowsNoEditor.pak') }
            )
        }
        'heretic-vr' = @{
            AppIds = @('2390')
            InstallerFolders = @('HereticVR')
            Files = @('HERETIC.WAD|base/HERETIC.WAD|base/wads/HERETIC.WAD|base/classicwads/HERETIC.WAD|rerelease/HERETIC.WAD|rerelease/base/HERETIC.WAD|classicwads/HERETIC.WAD|wads/HERETIC.WAD|base/doom/HERETIC.WAD|base/doom2/HERETIC.WAD|base/heretic/HERETIC.WAD|base/hexen/HERETIC.WAD|base/classic/HERETIC.WAD')
            FileSets = @(
                @{ Files = @('HERETIC.WAD|base/HERETIC.WAD|base/wads/HERETIC.WAD|base/classicwads/HERETIC.WAD|rerelease/HERETIC.WAD|rerelease/base/HERETIC.WAD|classicwads/HERETIC.WAD|wads/HERETIC.WAD|base/doom/HERETIC.WAD|base/doom2/HERETIC.WAD|base/heretic/HERETIC.WAD|base/hexen/HERETIC.WAD|base/classic/HERETIC.WAD'); Containers = @(@{ File = 'HERETIC.WAD|base/HERETIC.WAD|base/wads/HERETIC.WAD|base/classicwads/HERETIC.WAD|rerelease/HERETIC.WAD|rerelease/base/HERETIC.WAD|classicwads/HERETIC.WAD|wads/HERETIC.WAD|base/doom/HERETIC.WAD|base/doom2/HERETIC.WAD|base/heretic/HERETIC.WAD|base/hexen/HERETIC.WAD|base/classic/HERETIC.WAD'; Format = 'WAD'; Entries = @('TITLE','MUS_E1M1'); Maps = @('E1M1','E2M1'); Excluded = @('FREEDOOM','FREEDM') }) }
            )
        }
        'hexen-vr' = @{
            AppIds = @('2360')
            InstallerFolders = @('HexenVR')
            Files = @('HEXEN.WAD|base/HEXEN.WAD|base/wads/HEXEN.WAD|base/classicwads/HEXEN.WAD|rerelease/HEXEN.WAD|rerelease/base/HEXEN.WAD|classicwads/HEXEN.WAD|wads/HEXEN.WAD|base/doom/HEXEN.WAD|base/doom2/HEXEN.WAD|base/heretic/HEXEN.WAD|base/hexen/HEXEN.WAD|base/classic/HEXEN.WAD')
            FileSets = @(
                @{ Files = @('HEXEN.WAD|base/HEXEN.WAD|base/wads/HEXEN.WAD|base/classicwads/HEXEN.WAD|rerelease/HEXEN.WAD|rerelease/base/HEXEN.WAD|classicwads/HEXEN.WAD|wads/HEXEN.WAD|base/doom/HEXEN.WAD|base/doom2/HEXEN.WAD|base/heretic/HEXEN.WAD|base/hexen/HEXEN.WAD|base/classic/HEXEN.WAD'); Containers = @(@{ File = 'HEXEN.WAD|base/HEXEN.WAD|base/wads/HEXEN.WAD|base/classicwads/HEXEN.WAD|rerelease/HEXEN.WAD|rerelease/base/HEXEN.WAD|classicwads/HEXEN.WAD|wads/HEXEN.WAD|base/doom/HEXEN.WAD|base/doom2/HEXEN.WAD|base/heretic/HEXEN.WAD|base/hexen/HEXEN.WAD|base/classic/HEXEN.WAD'; Format = 'WAD'; Entries = @('TITLE','WINNOWR'); Maps = @('MAP01','MAP40'); Excluded = @('FREEDOOM','FREEDM') }) }
            )
        }
        'hexen-ii-vr' = @{
            AppIds = @('9060')
            InstallerFolders = @('Hexen2VR')
            Files = @('data1\pak0.pak','data1\pak1.pak')
            FileSets = @(
                @{ Files = @('data1\pak0.pak','data1\pak1.pak'); Containers = @(@{File='data1\pak0.pak';Format='PAK';Entries=@('models/paladin.mdl','maps/demo1.bsp')},@{File='data1\pak1.pak';Format='PAK';Entries=@('models/necro.mdl','maps/eidolon.bsp')}) }
            )
        }
        'high-entropy-challenges-vr' = @{
            AppIds = @('1389630')
            InstallerFolders = @('HighEntropyVR')
            Files = @('HighEntropy.exe','HighEntropy_Data\resources.assets')
            FileSets = @(
                @{ Files = @('HighEntropy.exe','HighEntropy_Data\resources.assets') }
            )
        }
        'hitman-blood-money-vr' = @{
            AppIds = @('6860')
            InstallerFolders = @('HitmanBloodMoneyVR')
            Files = @('HitmanBloodMoney.exe','Scenes\M00\M00_main.ZIP')
            FileSets = @(
                @{ Files = @('HitmanBloodMoney.exe','Scenes\M00\M00_main.ZIP') }
            )
        }
        'how-to-fish-xr' = @{
            AppIds = @('4001890')
            InstallerFolders = @('HowToFishXR')
            Files = @('How to Fish/How to Fish.exe|How to Fish.exe','How to Fish/How to Fish_Data/Managed/Assembly-CSharp.dll|How to Fish_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('How to Fish/How to Fish.exe','How to Fish/How to Fish_Data/Managed/Assembly-CSharp.dll') }
                @{ Files = @('How to Fish.exe','How to Fish_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'house-of-the-dead-remake-vr' = @{
            AppIds = @('1694600')
            InstallerFolders = @('HouseOfTheDeadRemakeVR')
            Files = @('The House of the Dead Remake.exe','The House of the Dead Remake_Data\resources.assets')
            FileSets = @(
                @{ Files = @('The House of the Dead Remake.exe','The House of the Dead Remake_Data\resources.assets') }
            )
        }
        'house-of-the-dead-2-remake-vr' = @{
            AppIds = @('3376690')
            InstallerFolders = @('HouseOfTheDead2RemakeVR')
            Files = @('THE HOUSE OF THE DEAD 2 Remake.exe','THE HOUSE OF THE DEAD 2 Remake_Data\resources.assets')
            FileSets = @(
                @{ Files = @('THE HOUSE OF THE DEAD 2 Remake.exe','THE HOUSE OF THE DEAD 2 Remake_Data\resources.assets') }
            )
        }
        'ratchet-clank-1-vr' = @{
            InstallerFolders = @('RatchetClank1VR')
            Files = @('data/levels/01/core_data.bin','data/levels/01/gameplay_ntsc.bin')
            FileSets = @(
                @{ Files = @('data/levels/01/core_data.bin','data/levels/01/gameplay_ntsc.bin') }
            )
        }
        'house-of-the-dead-2-original-vr' = @{
            InstallerFolders = @('HotD2VR')
            Files = @('Hod2.exe|working/pcvr/game/Hod2.exe','pol/bg_adv00.bin|working/pcvr/game/pol/bg_adv00.bin','pol/b6boss1z.bin|working/pcvr/game/pol/b6boss1z.bin')
            FileSets = @(
                @{ Files = @('Hod2.exe','pol/bg_adv00.bin','pol/b6boss1z.bin') }
                @{ Files = @('working/pcvr/game/Hod2.exe','working/pcvr/game/pol/bg_adv00.bin','working/pcvr/game/pol/b6boss1z.bin') }
            )
        }
        'hytale-vr' = @{
            InstallerFolders = @('HytaleVR')
            Files = @('Client/HytaleClient.exe','Assets.zip')
            FileSets = @(
                @{ Files = @('Client/HytaleClient.exe','Assets.zip') }
            )
        }
        'idols-of-ash-vr' = @{
            AppIds = @('4450800')
            InstallerFolders = @('IdolsOfAshVR')
            Files = @('idols_of_ash.exe','idols_of_ash.pck')
            FileSets = @(
                @{ Files = @('idols_of_ash.exe','idols_of_ash.pck') }
            )
        }
        'judgment-vr' = @{
            AppIds = @('2058180')
            InstallerFolders = @('JudgmentVR')
            Files = @('runtime/media/Judgment.exe','runtime/media/data/hact_judge/jh80000_murase1.par')
            FileSets = @(
                @{ Files = @('runtime/media/Judgment.exe','runtime/media/data/hact_judge/jh80000_murase1.par') }
            )
        }
        'kerbal-space-program' = @{
            AppIds = @('220200')
            InstallerFolders = @('KSPVR')
            Files = @('KSP_x64.exe','KSP_x64_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('KSP_x64.exe','KSP_x64_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'killing-floor-2-vr' = @{
            AppIds = @('232090')
            InstallerFolders = @('KillingFloor2VR')
            Files = @('Binaries\Win64\KFGame.exe','KFGame\BrewedPC\KFGame.u')
            FileSets = @(
                @{ Files = @('Binaries\Win64\KFGame.exe','KFGame\BrewedPC\KFGame.u') }
            )
        }
        'left-4-dead-2-vr' = @{
            AppIds = @('550')
            InstallerFolders = @('L4D2VR')
            Files = @('left4dead2.exe','left4dead2\pak01_000.vpk')
            FileSets = @(
                @{ Files = @('left4dead2.exe','left4dead2\pak01_000.vpk') }
            )
        }
        'lethal-company-vr' = @{
            AppIds = @('1966720')
            InstallerFolders = @('LethalCompanyVR')
            Files = @('Lethal Company.exe','Lethal Company_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Lethal Company.exe','Lethal Company_Data\resources.assets') }
            )
        }
        'life-is-strange-bts' = @{
            AppIds = @('554620','1265930')
            InstallerFolders = @('DawnVR')
            Files = @('Life is Strange - Before the Storm.exe','Life is Strange - Before the Storm_Data/resources.assets')
            FileSets = @(
                @{ Files = @('Life is Strange - Before the Storm.exe','Life is Strange - Before the Storm_Data/resources.assets') }
            )
        }
        'little-witch-nobeta-vr' = @{
            AppIds = @('1049890')
            InstallerFolders = @('LittleWitchNobetaVR')
            Files = @('LittleWitchNobeta.exe','LittleWitchNobeta_Data\resources.assets')
            FileSets = @(
                @{ Files = @('LittleWitchNobeta.exe','LittleWitchNobeta_Data\resources.assets') }
            )
        }
        'lunacid-vr' = @{
            AppIds = @('1745510')
            InstallerFolders = @('LunacidVR')
            Files = @('LUNACID.exe','LUNACID_Data\resources.assets')
            FileSets = @(
                @{ Files = @('LUNACID.exe','LUNACID_Data\resources.assets') }
            )
        }
        'mage-arena-vr' = @{
            AppIds = @('3716600')
            InstallerFolders = @('MageArenaVR')
            Files = @('MageArena.exe','MageArena_Data\resources.assets')
            FileSets = @(
                @{ Files = @('MageArena.exe','MageArena_Data\resources.assets') }
            )
        }
        'mario-kart-wii-vr' = @{
            InstallerFolders = @('WiiCompiledVR')
            Files = @('GameAssets/DATA/files/Race/Course/koopa_course.szs|DATA/files/Race/Course/koopa_course.szs|files/Race/Course/koopa_course.szs','GameAssets/DATA/files/Race/Course/boardcross_course.szs|DATA/files/Race/Course/boardcross_course.szs|files/Race/Course/boardcross_course.szs','GameAssets/DATA/sys/fst.bin|DATA/sys/fst.bin|sys/fst.bin')
            FileSets = @(
                @{ Files = @('GameAssets/DATA/files/Race/Course/koopa_course.szs','GameAssets/DATA/files/Race/Course/boardcross_course.szs','GameAssets/DATA/sys/fst.bin') }
                @{ Files = @('DATA/files/Race/Course/koopa_course.szs','DATA/files/Race/Course/boardcross_course.szs','DATA/sys/fst.bin') }
                @{ Files = @('files/Race/Course/koopa_course.szs','files/Race/Course/boardcross_course.szs','sys/fst.bin') }
            )
        }
        'max-payne-2-vr' = @{
            AppIds = @('12150')
            InstallerFolders = @('MaxPayne2VR')
            Files = @('MaxPayne2.exe','MP2_Data.ras')
            FileSets = @(
                @{ Files = @('MaxPayne2.exe','MP2_Data.ras') }
            )
        }
        'metal-gear-solid-v-the-phantom-pain-vr' = @{
            AppIds = @('287700')
            InstallerFolders = @('MGS5VR')
            Files = @('mgsvtpp.exe','master/chunk0.dat')
            FileSets = @(
                @{ Files = @('mgsvtpp.exe','master/chunk0.dat') }
            )
        }
        'metal-hellsinger-vr' = @{
            AppIds = @('1061910')
            InstallerFolders = @('MetalHellsingerVR')
            Files = @('Metal.exe','Metal_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Metal.exe','Metal_Data\resources.assets') }
            )
        }
        'mirrors-edge-vr' = @{
            AppIds = @('17410')
            InstallerFolders = @('MirrorsEdgeVR')
            Files = @('Binaries\MirrorsEdge.exe','TdGame\CookedPC\TdGame.u')
            FileSets = @(
                @{ Files = @('Binaries\MirrorsEdge.exe','TdGame\CookedPC\TdGame.u') }
            )
        }
        'miside-vr' = @{
            AppIds = @('2527500')
            InstallerFolders = @('MiSideVR')
            Files = @('MiSideFull.exe','MiSideFull_Data\resources.assets')
            FileSets = @(
                @{ Files = @('MiSideFull.exe','MiSideFull_Data\resources.assets') }
            )
        }
        'no-one-lives-forever-vr' = @{
            InstallerFolders = @('NOLF1VR')
            Files = @('NOLF.REZ','NOLF2.REZ')
            FileSets = @(
                @{ Files = @('NOLF.REZ','NOLF2.REZ') }
            )
        }
        'bannerlord-vr' = @{
            AppIds = @('261550')
            InstallerFolders = @('BannerlordVR')
            Files = @('bin\Win64_Shipping_Client\TaleWorlds.MountAndBlade.dll','bin\Win64_Shipping_Client\TaleWorlds.CampaignSystem.dll')
            FileSets = @(
                @{ Files = @('bin\Win64_Shipping_Client\TaleWorlds.MountAndBlade.dll','bin\Win64_Shipping_Client\TaleWorlds.CampaignSystem.dll') }
            )
        }
        'moros-protocol-vr' = @{
            AppIds = @('1605250')
            InstallerFolders = @('MorosProtocolVR')
            Files = @('Moros Protocol.exe','Moros Protocol_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Moros Protocol.exe','Moros Protocol_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'mouse-p-i-for-hire-vr' = @{
            AppIds = @('2416450')
            InstallerFolders = @('MousePIVR')
            Files = @('MOUSE.exe','MOUSE_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('MOUSE.exe','MOUSE_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'my-friendly-neighborhood-vr' = @{
            AppIds = @('1574260')
            InstallerFolders = @('MFNVR')
            Files = @('My Friendly Neighborhood.exe','My Friendly Neighborhood_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('My Friendly Neighborhood.exe','My Friendly Neighborhood_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'nam-vr' = @{
            AppIds = @('329650')
            InstallerFolders = @('NAMVR')
            Files = @('NAM/NAM.GRP|NAM.GRP|games/nam/NAM.GRP','NAM/NAM.RTS|NAM.RTS|games/nam/NAM.RTS')
            FileSets = @(
                @{ Files = @('NAM/NAM.GRP','NAM/NAM.RTS') }
                @{ Files = @('NAM.GRP','NAM.RTS') }
                @{ Files = @('games/nam/NAM.GRP','games/nam/NAM.RTS') }
            )
        }
        'outer-wilds-vr' = @{
            AppIds = @('753640')
            InstallerFolders = @('OuterWildsVR')
            Files = @('OuterWilds.exe','OuterWilds_Data\resources.assets')
            FileSets = @(
                @{ Files = @('OuterWilds.exe','OuterWilds_Data\resources.assets') }
            )
        }
        'outward-de-vr' = @{
            AppIds = @('794260')
            InstallerFolders = @('OutwardVR')
            Files = @('Outward_Defed/Outward Definitive Edition.exe|Outward Definitive Edition.exe','Outward_Defed/GameAssembly.dll|Outward_Defed/Outward Definitive Edition_Data/Managed/Assembly-CSharp.dll|GameAssembly.dll|Outward Definitive Edition_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Outward_Defed/Outward Definitive Edition.exe','Outward_Defed/GameAssembly.dll') }
                @{ Files = @('Outward_Defed/Outward Definitive Edition.exe','Outward_Defed/Outward Definitive Edition_Data/Managed/Assembly-CSharp.dll') }
                @{ Files = @('Outward Definitive Edition.exe','GameAssembly.dll') }
                @{ Files = @('Outward Definitive Edition.exe','Outward Definitive Edition_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'painkiller-black-edition' = @{
            AppIds = @('39530')
            InstallerFolders = @('PainkillerBlackVR')
            Files = @('Bin\Painkiller.exe','Data\Maps.pak')
            FileSets = @(
                @{ Files = @('Bin\Painkiller.exe','Data\Maps.pak') }
            )
        }
        'painkiller-overdose-vr' = @{
            AppIds = @('3270')
            InstallerFolders = @('PainkillerOverdoseVR')
            Files = @('Bin\Overdose.exe','Data\MapsSingle.pak')
            FileSets = @(
                @{ Files = @('Bin\Overdose.exe','Data\MapsSingle.pak') }
            )
        }
        'panzer-dragoon-remake' = @{
            AppIds = @('1178880')
            InstallerFolders = @('PanzerDragoonRemakeVR')
            Files = @('Panzer Dragoon Remake.exe','Panzer Dragoon Remake_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Panzer Dragoon Remake.exe','Panzer Dragoon Remake_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'pathfinder-kingmaker' = @{
            AppIds = @('640820')
            InstallerFolders = @('PathfinderKingmakerVR')
            Files = @('Kingmaker.exe','Kingmaker_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Kingmaker.exe','Kingmaker_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'peak-vr' = @{
            AppIds = @('3527290')
            InstallerFolders = @('PEAKVR')
            Files = @('PEAK.exe','PEAK_Data\resources.assets')
            FileSets = @(
                @{ Files = @('PEAK.exe','PEAK_Data\resources.assets') }
            )
        }
        'penumbra-black-plague-vr' = @{
            AppIds = @('22120')
            InstallerFolders = @('PenumbraBlackPlagueVR')
            Files = @('redist/maps/level01_cells.dae|maps/level01_cells.dae','redist/maps/level02_vents.dae|maps/level02_vents.dae')
            FileSets = @(
                @{ Files = @('redist/maps/level01_cells.dae','redist/maps/level02_vents.dae') }
                @{ Files = @('maps/level01_cells.dae','maps/level02_vents.dae') }
            )
        }
        'penumbra-overture-vr' = @{
            AppIds = @('22180')
            InstallerFolders = @('PenumbraVR')
            Files = @('redist/maps/level00_01_boat_cabin.dae|maps/level00_01_boat_cabin.dae','redist/maps/level01_01_outside.dae|maps/level01_01_outside.dae')
            FileSets = @(
                @{ Files = @('redist/maps/level00_01_boat_cabin.dae','redist/maps/level01_01_outside.dae') }
                @{ Files = @('maps/level00_01_boat_cabin.dae','maps/level01_01_outside.dae') }
            )
        }
        'penumbra-requiem-vr' = @{
            AppIds = @('22140')
            InstallerFolders = @('PenumbraRequiemVR')
            Files = @('redist/expansion01/maps/level01.dae|expansion01/maps/level01.dae','redist/expansion01/maps/requiem_global_script.hps|expansion01/maps/requiem_global_script.hps')
            FileSets = @(
                @{ Files = @('redist/expansion01/maps/level01.dae','redist/expansion01/maps/requiem_global_script.hps') }
                @{ Files = @('expansion01/maps/level01.dae','expansion01/maps/requiem_global_script.hps') }
            )
        }
        'pokemon-gen-1-vr' = @{
            InstallerFolders = @('Gen1RecompVR')
            Files = @()
            ConfiguredRoots = @(@{ Root = 'Runtime'; File = '.'; Format = 'Directory' },@{ Root = 'AppData'; File = 'DramaticShapeVR'; Format = 'Directory'; RuntimeFiles = @('DramaticShapeVR.exe') },@{ Root = 'AppData'; File = 'pokemon-love2d'; Format = 'Directory'; RuntimeFiles = @('gen1recomp.exe') })
            FileSets = @(
                @{ Files = @('yellow/data/generated/maps.lua','yellow/assets/generated/battle/front/pikachu.png') }
                @{ Files = @('red/data/generated/maps.lua','red/assets/generated/battle/front/pikachu.png') }
                @{ Files = @('blue/data/generated/maps.lua','blue/assets/generated/battle/front/pikachu.png') }
                @{ Files = @('gold/data/generated/maps.lua','gold/assets/generated/battle/front/pikachu.png') }
                @{ Files = @('silver/data/generated/maps.lua','silver/assets/generated/battle/front/pikachu.png') }
                @{ Files = @('crystal/data/generated/maps.lua','crystal/assets/generated/battle/front/pikachu.png') }
                @{ Files = @('data/generated/maps.lua','assets/generated/battle/front/pikachu.png') }
                @{ Files = @(); Containers = @(@{ File = 'pinball/game-v1.pak'; Format = 'DRAMATIC_PINBALL'; Entries = @('original-rom','red-board','blue-board') }) }
            )
        }
        'portal-2-vr' = @{
            AppIds = @('620')
            InstallerFolders = @('Portal2VR')
            Files = @('portal2.exe','portal2\pak01_000.vpk')
            FileSets = @(
                @{ Files = @('portal2.exe','portal2\pak01_000.vpk') }
            )
        }
        'powerslave-exhumed-vr' = @{
            AppIds = @('1260020')
            InstallerFolders = @('PowerSlaveRazeXR')
            Files = @('PWRSLAVE/STUFF.DAT|STUFF.DAT|games/exhumed/STUFF.DAT')
            FileSets = @(
                @{ Files = @('PWRSLAVE/STUFF.DAT|STUFF.DAT|games/exhumed/STUFF.DAT'); Containers = @(@{ File = 'PWRSLAVE/STUFF.DAT|STUFF.DAT|games/exhumed/STUFF.DAT'; Format = 'GRP'; Entries = @('LEV1.MAP','LEV2.MAP','LEV20.MAP') }) }
            )
        }
        'powerwash-simulator-vr' = @{
            AppIds = @('1290000')
            InstallerFolders = @('PowerWashSimulator1VR')
            Files = @('PowerWashSimulator.exe','GameAssembly.dll')
            FileSets = @(
                @{ Files = @('PowerWashSimulator.exe','GameAssembly.dll') }
            )
        }
        'powerwash-simulator-2-vr' = @{
            AppIds = @('2968420')
            InstallerFolders = @('PowerWashSimulator2VR')
            Files = @('PowerWash Simulator 2.exe','GameAssembly.dll')
            FileSets = @(
                @{ Files = @('PowerWash Simulator 2.exe','GameAssembly.dll') }
            )
        }
        'prey-2006-vr' = @{
            AppIds = @('3970')
            InstallerFolders = @('Prey2006VR')
            Files = @('base/pak000.pk4|pak000.pk4','base/pak002.pk4|pak002.pk4')
            FileSets = @(
                @{ Files = @('base/pak000.pk4','base/pak002.pk4'); Containers = @(@{ File = 'base/pak000.pk4'; Format = 'ZIP'; Entries = @('def/characters_girlfriend.def','def/characters_grandfather.def') },@{ File = 'base/pak002.pk4'; Format = 'ZIP'; Entries = @('models/characters/girlfriend/girlfriend.md5mesh','models/characters/grandfather/grandfather.md5mesh') }) }
                @{ Files = @('pak000.pk4','pak002.pk4'); Containers = @(@{ File = 'pak000.pk4'; Format = 'ZIP'; Entries = @('def/characters_girlfriend.def','def/characters_grandfather.def') },@{ File = 'pak002.pk4'; Format = 'ZIP'; Entries = @('models/characters/girlfriend/girlfriend.md5mesh','models/characters/grandfather/grandfather.md5mesh') }) }
            )
        }
        'project-zomboid-vr' = @{
            AppIds = @('108600')
            InstallerFolders = @('ProjectZomboidVR')
            Files = @('projectzomboid.jar|zombie\GameWindow.class','media\maps\Muldraugh, KY\objects.lua')
            FileSets = @(
                @{ Files = @('projectzomboid.jar|zombie\GameWindow.class','media\maps\Muldraugh, KY\objects.lua') }
            )
        }
        'quake-vr' = @{
            AppIds = @('2310')
            InstallerFolders = @('QuakeVR')
            Files = @('id1/pak0.pak|rerelease/id1/pak0.pak|pak0.pak')
            FileSets = @(
                @{ Files = @('id1/pak0.pak','id1/pak1.pak'); Containers = @(@{ File = 'id1/pak0.pak'; Format = 'PAK'; Entries = @('maps/start.bsp','maps/e1m1.bsp') },@{ File = 'id1/pak1.pak'; Format = 'PAK'; Entries = @('maps/e2m1.bsp','maps/e4m1.bsp') }) }
                @{ Files = @('pak0.pak','pak1.pak'); Containers = @(@{ File = 'pak0.pak'; Format = 'PAK'; Entries = @('maps/start.bsp','maps/e1m1.bsp') },@{ File = 'pak1.pak'; Format = 'PAK'; Entries = @('maps/e2m1.bsp','maps/e4m1.bsp') }) }
                @{ Files = @('rerelease/id1/pak0.pak'); Containers = @(@{ File = 'rerelease/id1/pak0.pak'; Format = 'PAK'; Entries = @('maps/start.bsp','maps/e1m1.bsp','maps/e2m1.bsp','maps/e4m1.bsp') }) }
                @{ Files = @('id1/pak0.pak'); Containers = @(@{ File = 'id1/pak0.pak'; Format = 'PAK'; Entries = @('maps/start.bsp','maps/e1m1.bsp','maps/e2m1.bsp','maps/e4m1.bsp') }) }
                @{ Files = @('pak0.pak'); Containers = @(@{ File = 'pak0.pak'; Format = 'PAK'; Entries = @('maps/start.bsp','maps/e1m1.bsp','maps/e2m1.bsp','maps/e4m1.bsp') }) }
            )
        }
        'quake-2-vr' = @{
            AppIds = @('2320')
            InstallerFolders = @('Quake2VR')
            Files = @('baseq2/pak0.pak|rerelease/baseq2/pak0.pak|pak0.pak')
            FileSets = @(
                @{ Files = @('baseq2/pak0.pak|rerelease/baseq2/pak0.pak|pak0.pak'); Containers = @(@{ File = 'baseq2/pak0.pak|rerelease/baseq2/pak0.pak|pak0.pak'; Format = 'PAK'; Entries = @('maps/base1.bsp','maps/bunk1.bsp','models/weapons/v_blast/tris.md2') }) }
            )
        }
        'quake-3-vr' = @{
            AppIds = @('2200')
            InstallerFolders = @('Quake3VR')
            Files = @('baseq3/pak0.pk3|pak0.pk3')
            FileSets = @(
                @{ Files = @('baseq3/pak0.pk3|pak0.pk3'); Containers = @(@{ File = 'baseq3/pak0.pk3|pak0.pk3'; Format = 'ZIP'; Entries = @('maps/q3dm0.bsp','maps/q3dm19.bsp') }) }
            )
        }
        'r-e-p-o-vr' = @{
            AppIds = @('3241660')
            InstallerFolders = @('RepoVR')
            Files = @('REPO.exe','REPO_Data\resources.assets')
            FileSets = @(
                @{ Files = @('REPO.exe','REPO_Data\resources.assets') }
            )
        }
        'raft-vr' = @{
            AppIds = @('648800')
            InstallerFolders = @('RaftVR')
            Files = @('Raft.exe','Raft_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Raft.exe','Raft_Data\resources.assets') }
            )
        }
        'ready-or-not-vr' = @{
            AppIds = @('1144200')
            InstallerFolders = @('ReadyOrNotVR')
            Files = @('ReadyOrNot/Binaries/Win64/ReadyOrNotSteam-Win64-Shipping.exe|ReadyOrNot/Binaries/Win64/ReadyOrNot-Win64-Shipping.exe','ReadyOrNot/Content/Paks/pakchunk0-Windows.pak|ReadyOrNot/Content/Paks/pakchunk0-WindowsNoEditor.pak')
            FileSets = @(
                @{ Files = @('ReadyOrNot/Binaries/Win64/ReadyOrNotSteam-Win64-Shipping.exe','ReadyOrNot/Content/Paks/pakchunk0-Windows.pak') }
                @{ Files = @('ReadyOrNot/Binaries/Win64/ReadyOrNot-Win64-Shipping.exe','ReadyOrNot/Content/Paks/pakchunk0-Windows.pak') }
                @{ Files = @('ReadyOrNot/Binaries/Win64/ReadyOrNot-Win64-Shipping.exe','ReadyOrNot/Content/Paks/pakchunk0-WindowsNoEditor.pak') }
            )
        }
        'receiver-vr' = @{
            AppIds = @('234190')
            InstallerFolders = @('ReceiverVR')
            Files = @('Receiver.exe','Receiver_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Receiver.exe','Receiver_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'red-dead-redemption-vr' = @{
            AppIds = @('2668510')
            InstallerFolders = @('RDRVR')
            Files = @('RDR.exe','game\redemption\territory_swall\armadillo.rpf')
            FileSets = @(
                @{ Files = @('RDR.exe','game\redemption\territory_swall\armadillo.rpf') }
            )
        }
        'red-faction-vr' = @{
            AppIds = @('20530')
            InstallerFolders = @('RedFactionVR')
            Files = @('RF.exe','levels1.vpp')
            FileSets = @(
                @{ Files = @('RF.exe','levels1.vpp') }
            )
        }
        'redneck-rampage-vr' = @{
            AppIds = @('565550')
            InstallerFolders = @('RedneckRampageVR')
            Files = @('Redneck/REDNECK.GRP|REDNECK.GRP|AGAIN/REDNECK.GRP|Redneck/AGAIN/REDNECK.GRP|games/rampage/REDNECK.GRP|games/ridesagain/REDNECK.GRP')
            FileSets = @(
                @{ Files = @('Redneck/REDNECK.GRP|REDNECK.GRP|AGAIN/REDNECK.GRP|Redneck/AGAIN/REDNECK.GRP|games/rampage/REDNECK.GRP|games/ridesagain/REDNECK.GRP'); Containers = @(@{ File = 'Redneck/REDNECK.GRP|REDNECK.GRP|AGAIN/REDNECK.GRP|Redneck/AGAIN/REDNECK.GRP|games/rampage/REDNECK.GRP|games/ridesagain/REDNECK.GRP'; Format = 'GRP'; Entries = @('BUBBA.CON','LEONARD.CON','E1L1.MAP') }) }
            )
        }
        'return-to-castle-wolfenstein-vr' = @{
            AppIds = @('9010')
            InstallerFolders = @('RealRTCWXR')
            Files = @('Main\pak0.pk3','Main\sp_pak1.pk3')
            FileSets = @(
                @{ Files = @('Main\pak0.pk3','Main\sp_pak1.pk3') }
            )
        }
        'richard-burns-rally-vr' = @{
            InstallerFolders = @('RichardBurnsRallyVR')
            Files = @('RichardBurnsRally_SSE.exe|RichardBurnsRally_NoSSE.exe','physics.rbz')
            FileSets = @(
                @{ Files = @('RichardBurnsRally_SSE.exe','physics.rbz') }
                @{ Files = @('RichardBurnsRally_NoSSE.exe','physics.rbz') }
            )
        }
        'risk-of-rain-2' = @{
            AppIds = @('632360')
            InstallerFolders = @('RoR2_VR')
            Files = @('Risk of Rain 2.exe','Risk of Rain 2_Data\Managed\RoR2.dll')
            FileSets = @(
                @{ Files = @('Risk of Rain 2.exe','Risk of Rain 2_Data\Managed\RoR2.dll') }
            )
        }
        'road-to-vostok-vr' = @{
            AppIds = @('1963610')
            InstallerFolders = @('VostokVR')
            Files = @('RTV.exe','RTV.pck')
            FileSets = @(
                @{ Files = @('RTV.exe','RTV.pck') }
            )
        }
        'rustler-vr' = @{
            AppIds = @('844260')
            InstallerFolders = @('RustlerVR')
            Files = @('Rustler.exe','Rustler_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Rustler.exe','Rustler_Data\resources.assets') }
            )
        }
        'saints-row-the-third-vr' = @{
            AppIds = @('55230')
            InstallerFolders = @('SaintsRowTheThirdVR')
            Files = @('SaintsRowTheThird.exe|SaintsRowTheThird_DX11.exe','packfiles/pc/cache/sr3_city_0.vpp_pc')
            FileSets = @(
                @{ Files = @('SaintsRowTheThird.exe','packfiles/pc/cache/sr3_city_0.vpp_pc') }
                @{ Files = @('SaintsRowTheThird_DX11.exe','packfiles/pc/cache/sr3_city_0.vpp_pc') }
            )
        }
        'scrap-mechanic-vr' = @{
            AppIds = @('387990')
            InstallerFolders = @('ScrapMechanicVR')
            Files = @('Release/ScrapMechanic.exe','Data/Character/Char_Male/Animations/Thirdperson/Spudgun/ani_char_male_spudgun_idle.dae')
            FileSets = @(
                @{ Files = @('Release/ScrapMechanic.exe','Data/Character/Char_Male/Animations/Thirdperson/Spudgun/ani_char_male_spudgun_idle.dae') }
            )
        }
        'selaco-vr' = @{
            AppIds = @('1592280')
            InstallerFolders = @('SelacoVR')
            Files = @('Selaco.ipk3')
            FileSets = @(
                @{ Files = @('Selaco.ipk3'); Containers = @(@{ File = 'Selaco.ipk3'; Format = 'ZIP'; Entries = @('ACTORS/AI/AI_Controllers/SelacoEnemy.zsc','MAPS/SE_01A.wad','MAPS/SE_05A.wad') }) }
            )
        }
        'shadow-warrior-vr' = @{
            AppIds = @('225160')
            InstallerFolders = @('ShadowWarriorRazeXR')
            Files = @('SW.GRP|gameroot/SW.GRP|bin/SW.GRP|games/shadowwarrior/SW.GRP')
            FileSets = @(
                @{ Files = @('SW.GRP|gameroot/SW.GRP|bin/SW.GRP|games/shadowwarrior/SW.GRP'); Containers = @(@{ File = 'SW.GRP|gameroot/SW.GRP|bin/SW.GRP|games/shadowwarrior/SW.GRP'; Format = 'GRP'; Entries = @('$BOAT.MAP','$YAMATO.MAP') }) }
            )
        }
        'silent-hill-3-vr' = @{
            InstallerFolders = @('SilentHill3VR')
            Files = @('sh3.exe','data/chrpl.arc')
            FileSets = @(
                @{ Files = @('sh3.exe','data/chrpl.arc') }
            )
        }
        'sin-episodes-emergence' = @{
            AppIds = @('1300')
            InstallerFolders = @('SinEpisodesVR')
            Files = @('SinEpisodes.exe','SE1/bin/server.dll')
            FileSets = @(
                @{ Files = @('SinEpisodes.exe','SE1/bin/server.dll') }
            )
        }
        'singularity-vr' = @{
            AppIds = @('42670')
            InstallerFolders = @('SingularityVR')
            Files = @('Binaries\Singularity.exe','RvGame\CookedPC\RvGame.xxx')
            FileSets = @(
                @{ Files = @('Binaries\Singularity.exe','RvGame\CookedPC\RvGame.xxx') }
            )
        }
        'slime-rancher-vr' = @{
            AppIds = @('433340')
            InstallerFolders = @('SlimeRancherVR')
            Files = @('SlimeRancher.exe','SlimeRancher_Data\resources.assets')
            FileSets = @(
                @{ Files = @('SlimeRancher.exe','SlimeRancher_Data\resources.assets') }
            )
        }
        'slyders-vr' = @{
            AppIds = @('2607870')
            InstallerFolders = @('SlydersVR')
            Files = @('Slyders.exe','Slyders_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Slyders.exe','Slyders_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'sons-of-the-forest' = @{
            AppIds = @('1326470')
            InstallerFolders = @('SonsVR')
            Files = @('SonsOfTheForest.exe','SonsOfTheForest_Data\resources.assets')
            FileSets = @(
                @{ Files = @('SonsOfTheForest.exe','SonsOfTheForest_Data\resources.assets') }
            )
        }
        'soma-vr' = @{
            AppIds = @('282140')
            InstallerFolders = @('SomaVR')
            Files = @('Soma.exe','combos/oceanbottom/02_01_elevator/02_01_elevator.cmb')
            FileSets = @(
                @{ Files = @('Soma.exe','combos/oceanbottom/02_01_elevator/02_01_elevator.cmb') }
            )
        }
        'spec-ops-the-line-vr' = @{
            AppIds = @('50300')
            InstallerFolders = @('SpecOpsTheLineVR')
            Files = @('Binaries\Win32\SpecOpsTheLine.exe','SRGame\CookedPCConsole\SRGame.upk')
            FileSets = @(
                @{ Files = @('Binaries\Win32\SpecOpsTheLine.exe','SRGame\CookedPCConsole\SRGame.upk') }
            )
        }
        'spiderman-remastered-spidy-vr' = @{
            AppIds = @('1817070')
            InstallerFolders = @('SpidyVR')
            Files = @('Spider-Man.exe','asset_archive\g00s000')
            FileSets = @(
                @{ Files = @('Spider-Man.exe','asset_archive\g00s000') }
            )
        }
        'star-wars-episode-i-racer' = @{
            AppIds = @('808910')
            InstallerFolders = @('StarWarsEpisodeIRacerVR')
            Files = @('SWEP1RCR.EXE','data\lev01\out_modelblock.bin')
            FileSets = @(
                @{ Files = @('SWEP1RCR.EXE','data\lev01\out_modelblock.bin') }
            )
        }
        'stardew-valley-vr' = @{
            AppIds = @('413150')
            InstallerFolders = @('StardewValleyVR')
            Files = @('Stardew Valley.exe','Content\Maps\Farm.xnb')
            FileSets = @(
                @{ Files = @('Stardew Valley.exe','Content\Maps\Farm.xnb') }
            )
        }
        'strife-vr' = @{
            AppIds = @('317040')
            InstallerFolders = @('StrifeVR')
            Files = @('strife1.wad|base/strife1.wad|wads/strife1.wad|classicwads/strife1.wad|DOS/C/STRIFE/strife1.wad|base/doom/strife1.wad|base/doom2/strife1.wad|base/heretic/strife1.wad|base/hexen/strife1.wad|base/classic/strife1.wad|rerelease/base/strife1.wad')
            FileSets = @(
                @{ Files = @('strife1.wad|base/strife1.wad|wads/strife1.wad|classicwads/strife1.wad|DOS/C/STRIFE/strife1.wad|base/doom/strife1.wad|base/doom2/strife1.wad|base/heretic/strife1.wad|base/hexen/strife1.wad|base/classic/strife1.wad|rerelease/base/strife1.wad'); Containers = @(@{ File = 'strife1.wad|base/strife1.wad|wads/strife1.wad|classicwads/strife1.wad|DOS/C/STRIFE/strife1.wad|base/doom/strife1.wad|base/doom2/strife1.wad|base/heretic/strife1.wad|base/hexen/strife1.wad|base/classic/strife1.wad|rerelease/base/strife1.wad'; Format = 'WAD'; Entries = @('ENDSTRF'); Maps = @('MAP01','MAP33') }) }
            )
        }
        'subnautica-vr' = @{
            AppIds = @('264710')
            InstallerFolders = @('SubnauticaVR')
            Files = @('Subnautica.exe|Subnautica32.exe','Subnautica_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Subnautica.exe|Subnautica32.exe','Subnautica_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'subnautica-below-zero' = @{
            AppIds = @('848450')
            InstallerFolders = @('SubnauticaBZVR')
            Files = @('SubnauticaZero.exe|Subnautica32.exe','SubnauticaZero_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('SubnauticaZero.exe|Subnautica32.exe','SubnauticaZero_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'super-mario-3d-world-vr' = @{
            InstallerFolders = @('SuperMario3DWorldVR')
            Files = @('code/RedCarpet.rpx','content/ObjectData/Mario.szs','content/StageData/TitleDemo00StageMap1.szs')
            FileSets = @(
                @{ Files = @('code/RedCarpet.rpx','content/ObjectData/Mario.szs','content/StageData/TitleDemo00StageMap1.szs') }
            )
        }
        'teardown-vr' = @{
            AppIds = @('1167630')
            InstallerFolders = @('TeardownVR')
            Files = @('teardown.exe','data\game.lua')
            FileSets = @(
                @{ Files = @('teardown.exe','data\game.lua') }
            )
        }
        'techtonica-vr' = @{
            AppIds = @('1457320')
            InstallerFolders = @('TechtonicaVR')
            Files = @('Techtonica.exe','Techtonica_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Techtonica.exe','Techtonica_Data\resources.assets') }
            )
        }
        'the-witness' = @{
            AppIds = @('210970')
            InstallerFolders = @('TheWitnessVR')
            Files = @('witness64_d3d11.exe|witness_d3d11.exe','data-pc.zip')
            FileSets = @(
                @{ Files = @('witness64_d3d11.exe','data-pc.zip') }
                @{ Files = @('witness_d3d11.exe','data-pc.zip') }
            )
        }
        'titanfall-2-vr' = @{
            AppIds = @('1237970')
            InstallerFolders = @('Titanfall2VR')
            Files = @('Titanfall2.exe','vpk\client_sp_training.bsp.pak000_000.vpk')
            FileSets = @(
                @{ Files = @('Titanfall2.exe','vpk\client_sp_training.bsp.pak000_000.vpk') }
            )
        }
        'tomb-raider-1-vr' = @{
            AppIds = @('224960','2478970')
            InstallerFolders = @('TombRaiderVR')
            Files = @('TOMBRAID/tomb.exe|DATA/LEVEL1.PHD|1/DATA/LEVEL1.PHD|BeefRaiderExtractionTool/BeefRaiderXR/DATA/LEVEL1.PHD','GAME.GOG|DATA/LEVEL2.PHD|1/DATA/LEVEL2.PHD|BeefRaiderExtractionTool/BeefRaiderXR/DATA/LEVEL2.PHD')
            FileSets = @(
                @{ Files = @('TOMBRAID/tomb.exe','GAME.GOG') }
                @{ Files = @('DATA/LEVEL1.PHD','DATA/LEVEL2.PHD') }
                @{ Files = @('1/DATA/LEVEL1.PHD','1/DATA/LEVEL2.PHD') }
                @{ Files = @('BeefRaiderExtractionTool/BeefRaiderXR/DATA/LEVEL1.PHD','BeefRaiderExtractionTool/BeefRaiderXR/DATA/LEVEL2.PHD') }
            )
        }
        'tomb-raider-legend-vr' = @{
            AppIds = @('7000')
            InstallerFolders = @('TombRaiderLegendVR')
            Files = @('trl.exe','bigfile.000')
            FileSets = @(
                @{ Files = @('trl.exe','bigfile.000') }
            )
        }
        'tormented-souls-vr' = @{
            AppIds = @('1367590')
            InstallerFolders = @('TormentedSoulsVR')
            Files = @('TormentedSouls.exe','GameAssembly.dll|TormentedSouls_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('TormentedSouls.exe','GameAssembly.dll') }
                @{ Files = @('TormentedSouls.exe','TormentedSouls_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'trombone-champ-vr' = @{
            AppIds = @('1059990')
            InstallerFolders = @('TromboneChampVR')
            Files = @('TromboneChamp.exe','TromboneChamp_Data\resources.assets')
            FileSets = @(
                @{ Files = @('TromboneChamp.exe','TromboneChamp_Data\resources.assets') }
            )
        }
        'tribes-2-vr' = @{
            InstallerFolders = @('Tribes2VR')
            Files = @('GameData/Tribes2.exe|Tribes2.exe','GameData/base/scripts.vl2|base/scripts.vl2','GameData/base/missions.vl2|base/missions.vl2')
            FileSets = @(
                @{ Files = @('GameData/Tribes2.exe','GameData/base/scripts.vl2','GameData/base/missions.vl2') }
                @{ Files = @('Tribes2.exe','base/scripts.vl2','base/missions.vl2') }
            )
        }
        'turok-vr' = @{
            AppIds = @('405820')
            InstallerFolders = @('TurokVR')
            Files = @('sobek_Shipping_Steam_x64.exe|sobek_Shipping_Galaxy_x64.exe|sobek.exe','game.kpf')
            FileSets = @(
                @{ Files = @('sobek_Shipping_Steam_x64.exe|sobek_Shipping_Galaxy_x64.exe|sobek.exe','game.kpf') }
            )
        }
        'ultrakill-vr' = @{
            AppIds = @('1229490')
            InstallerFolders = @('UltrakillVR')
            Files = @('ULTRAKILL.exe','ULTRAKILL_Data\resources.assets')
            FileSets = @(
                @{ Files = @('ULTRAKILL.exe','ULTRAKILL_Data\resources.assets') }
            )
        }
        'unreal-revived-vr' = @{
            InstallerFolders = @('UnrealRevivedVR')
            Files = @('Maps/Dig.unr','Maps/Chizra.unr')
            FileSets = @(
                @{ Files = @('Maps/Dig.unr','Maps/Chizra.unr') }
            )
        }
        'valheim-vr' = @{
            AppIds = @('892970')
            InstallerFolders = @('ValheimVR')
            Files = @('valheim.exe','valheim_Data\Managed\assembly_valheim.dll')
            FileSets = @(
                @{ Files = @('valheim.exe','valheim_Data\Managed\assembly_valheim.dll') }
            )
        }
        'vampire-bloodlines-vr' = @{
            AppIds = @('2600')
            InstallerFolders = @('VTMBVR')
            Files = @('vampire.exe','Vampire\pack000.vpk')
            FileSets = @(
                @{ Files = @('vampire.exe','Vampire\pack000.vpk') }
            )
        }
        'vampire-hunters-vr' = @{
            AppIds = @('2206270')
            InstallerFolders = @('VampireHuntersVR')
            Files = @('Vampire Hunters.exe','Vampire Hunters_Data/resources.assets')
            FileSets = @(
                @{ Files = @('Vampire Hunters.exe','Vampire Hunters_Data/resources.assets') }
            )
        }
        'virtua-cop-2-vr' = @{
            InstallerFolders = @('VirtuaCop2VR')
            Files = @('PPJ2DD.EXE|PPJ2DD_nocd.exe|PROJECT/PPJ2DD.EXE|PROJECT/PPJ2DD_nocd.exe','PG_STG1.DLL|PROJECT/PG_STG1.DLL')
            FileSets = @(
                @{ Files = @('PPJ2DD.EXE','PG_STG1.DLL') }
                @{ Files = @('PPJ2DD_nocd.exe','PG_STG1.DLL') }
                @{ Files = @('PROJECT/PPJ2DD.EXE','PROJECT/PG_STG1.DLL') }
                @{ Files = @('PROJECT/PPJ2DD_nocd.exe','PROJECT/PG_STG1.DLL') }
            )
        }
        'warhammer-40k-darktide-vr' = @{
            AppIds = @('1361210')
            InstallerFolders = @('DarktideVR')
            Files = @('binaries/Darktide.exe','bundle/bundle_database.data')
            FileSets = @(
                @{ Files = @('binaries/Darktide.exe','bundle/bundle_database.data'); RejectIfAllFiles = @('.pcvrhub_darktide_depot_25681127|.pcvrhub_darktide_depot_24735202|.pcvrhub_darktide_depot_stack|.pcvrhub_darktide_depot_staging_25681127') }
            )
        }
        'warhammer-40k-rogue-trader-vr' = @{
            AppIds = @('2186680')
            InstallerFolders = @('RogueTraderVR')
            Files = @('WH40KRT.exe','WH40KRT_Data/Managed/Code.dll')
            FileSets = @(
                @{ Files = @('WH40KRT.exe','WH40KRT_Data/Managed/Code.dll') }
            )
        }
        'white-knuckle-vr' = @{
            AppIds = @('3195790')
            InstallerFolders = @('WhiteKnuckleVR')
            Files = @('White Knuckle.exe','White Knuckle_Data\resources.assets')
            FileSets = @(
                @{ Files = @('White Knuckle.exe','White Knuckle_Data\resources.assets') }
            )
        }
        'wolfenstein-3d-vr' = @{
            AppIds = @('2270')
            InstallerFolders = @('Wolfenstein3DVR')
            Files = @('VSWAP.WL6|VSWAP.WL3|VSWAP.WL1|base/VSWAP.WL6|base/VSWAP.WL3|base/VSWAP.WL1|games/WL6/VSWAP.WL6|games/WL3/VSWAP.WL3|games/WL1/VSWAP.WL1','GAMEMAPS.WL6|GAMEMAPS.WL3|GAMEMAPS.WL1|base/GAMEMAPS.WL6|base/GAMEMAPS.WL3|base/GAMEMAPS.WL1|games/WL6/GAMEMAPS.WL6|games/WL3/GAMEMAPS.WL3|games/WL1/GAMEMAPS.WL1')
            FileSets = @(
                @{ Files = @('VSWAP.WL6','GAMEMAPS.WL6') }
                @{ Files = @('VSWAP.WL3','GAMEMAPS.WL3') }
                @{ Files = @('VSWAP.WL1','GAMEMAPS.WL1') }
                @{ Files = @('base/VSWAP.WL6','base/GAMEMAPS.WL6') }
                @{ Files = @('base/VSWAP.WL3','base/GAMEMAPS.WL3') }
                @{ Files = @('base/VSWAP.WL1','base/GAMEMAPS.WL1') }
                @{ Files = @('games/WL6/VSWAP.WL6','games/WL6/GAMEMAPS.WL6') }
                @{ Files = @('games/WL3/VSWAP.WL3','games/WL3/GAMEMAPS.WL3') }
                @{ Files = @('games/WL1/VSWAP.WL1','games/WL1/GAMEMAPS.WL1') }
            )
        }
        'wwii-gi-vr' = @{
            AppIds = @('376750')
            InstallerFolders = @('WW2GIVR')
            Files = @('WW2GI/WW2GI.GRP|WW2GI.GRP|games/ww2gi/WW2GI.GRP')
            FileSets = @(
                @{ Files = @('WW2GI/WW2GI.GRP|WW2GI.GRP|games/ww2gi/WW2GI.GRP'); Containers = @(@{ File = 'WW2GI/WW2GI.GRP|WW2GI.GRP|games/ww2gi/WW2GI.GRP'; Format = 'GRP'; Entries = @('XDEFS.CON','E4L8.MAP') }) }
            )
        }
        'world-of-warcraft-vr' = @{
            InstallerFolders = @('WoVR')
            Files = @('Wow.exe','Data/common.MPQ','Data/lichking.MPQ')
            FileSets = @(
                @{ Files = @('Wow.exe','Data/common.MPQ','Data/lichking.MPQ') }
            )
        }
        'xiii-remake-vr' = @{
            AppIds = @('1154790')
            InstallerFolders = @('XIIIVR')
            Files = @('XIII.exe','XIII_Data\resources.assets')
            FileSets = @(
                @{ Files = @('XIII.exe','XIII_Data\resources.assets') }
            )
        }
        'alba-vr' = @{
            AppIds = @('1337010')
            InstallerFolders = @('AlbaVR')
            Files = @('Alba.exe','Alba_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Alba.exe','Alba_Data\resources.assets') }
            )
        }
        'alan-wake-vr' = @{
            AppIds = @('108710')
            InstallerFolders = @('AlanWakeVR')
            Files = @('AlanWake.exe','data\ep999-000.rmdp')
            FileSets = @(
                @{ Files = @('AlanWake.exe','data\ep999-000.rmdp') }
            )
        }
        'another-crab-s-treasure' = @{
            AppIds = @('1887840')
            InstallerFolders = @('AnotherCrabsTreasureVR')
            Files = @('AnotherCrabsTreasure.exe','AnotherCrabsTreasure_Data\resources.assets')
            FileSets = @(
                @{ Files = @('AnotherCrabsTreasure.exe','AnotherCrabsTreasure_Data\resources.assets') }
            )
        }
        'apollo-justice-ace-attorney-trilogy-vr' = @{
            AppIds = @('2187220')
            InstallerFolders = @('REFrameworkVR')
            Files = @('GS456.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('GS456.exe','re_chunk_000.pak') }
            )
        }
        'art-of-rally-vr' = @{
            AppIds = @('550320')
            InstallerFolders = @('ArtOfRallyVR')
            Files = @('artofrally.exe','artofrally_Data\resources.assets')
            FileSets = @(
                @{ Files = @('artofrally.exe','artofrally_Data\resources.assets') }
            )
        }
        'assassin-s-creed-mirage-vr' = @{
            AppIds = @('3035570')
            InstallerFolders = @('ACMirageVR')
            Files = @('ACMirage.exe|ACMirage_plus.exe','DataPC.forge')
            FileSets = @(
                @{ Files = @('ACMirage.exe|ACMirage_plus.exe','DataPC.forge') }
            )
        }
        'assassin-s-creed-odyssey-vr' = @{
            AppIds = @('812140')
            InstallerFolders = @('ACOdysseyVR')
            Files = @('ACOdyssey.exe|ACOdyssey_plus.exe','DataPC.forge')
            FileSets = @(
                @{ Files = @('ACOdyssey.exe|ACOdyssey_plus.exe','DataPC.forge') }
            )
        }
        'assassin-s-creed-valhalla-vr' = @{
            AppIds = @('2208920')
            InstallerFolders = @('ACValhallaVR')
            Files = @('ACValhalla.exe|ACValhalla_Plus.exe','DataPC.forge')
            FileSets = @(
                @{ Files = @('ACValhalla.exe|ACValhalla_Plus.exe','DataPC.forge') }
            )
        }
        'astrodogs-vr' = @{
            AppIds = @('1301230')
            InstallerFolders = @('AstrodogsVR')
            Files = @('astrodogs.exe','astrodogs_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('astrodogs.exe','astrodogs_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'atomic-heart-vr' = @{
            AppIds = @('668580')
            InstallerFolders = @('LukeRossVR')
            Files = @('AtomicHeart/Binaries/Win64/AtomicHeart-Win64-Shipping.exe|AtomicHeart/Binaries/WinGDK/AtomicHeart-WinGDK-Shipping.exe','AtomicHeart/Content/Paks/pakchunk0-WindowsNoEditor.pak')
            FileSets = @(
                @{ Files = @('AtomicHeart/Binaries/Win64/AtomicHeart-Win64-Shipping.exe','AtomicHeart/Content/Paks/pakchunk0-WindowsNoEditor.pak') }
                @{ Files = @('AtomicHeart/Binaries/WinGDK/AtomicHeart-WinGDK-Shipping.exe','AtomicHeart/Content/Paks/pakchunk0-WindowsNoEditor.pak') }
            )
        }
        'avatar-frontiers-of-pandora-vr' = @{
            AppIds = @('2840770')
            InstallerFolders = @('LukeRossVR')
            Files = @('afop.exe','rogue\sdf\pc\data\sdf-A-0000.sdfdata')
            FileSets = @(
                @{ Files = @('afop.exe','rogue\sdf\pc\data\sdf-A-0000.sdfdata') }
            )
        }
        'blade-of-darkness-vr' = @{
            AppIds = @('1710170')
            InstallerFolders = @('BladeOfDarknessVR')
            Files = @('bin/bin/Blade.exe','AnmPak/Dwf.dat')
            FileSets = @(
                @{ Files = @('bin/bin/Blade.exe','AnmPak/Dwf.dat') }
            )
        }
        'blur-vr' = @{
            AppIds = @('42640')
            InstallerFolders = @('BlurVR')
            Files = @('Blur.exe','cache\gamedata.pak')
            FileSets = @(
                @{ Files = @('Blur.exe','cache\gamedata.pak') }
            )
        }
        'bomb-rush-cyberfunk' = @{
            AppIds = @('1353230')
            InstallerFolders = @('BombRushCyberfunkVR')
            Files = @('Bomb Rush Cyberfunk.exe','Bomb Rush Cyberfunk_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Bomb Rush Cyberfunk.exe','Bomb Rush Cyberfunk_Data\resources.assets') }
            )
        }
        'circuit-superstars-vr' = @{
            AppIds = @('1097130')
            InstallerFolders = @('CircuitSuperstarsVR')
            Files = @('circuit-superstars.exe','circuit-superstars_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('circuit-superstars.exe','circuit-superstars_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'cloudpunk-vr' = @{
            AppIds = @('746850')
            InstallerFolders = @('CloudpunkVR')
            Files = @('Cloudpunk.exe','Cloudpunk_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Cloudpunk.exe','Cloudpunk_Data\resources.assets') }
            )
        }
        'cloudpunk-city-of-ghosts-vr' = @{
            AppIds = @('1536370','746850')
            SteamSubdir = 'City of Ghosts'
            InstallerFolders = @('CloudpunkCOGVR')
            Files = @('Cloudpunk - City of Ghosts.exe','Cloudpunk - City of Ghosts_Data/resources.assets')
            FileSets = @(
                @{ Files = @('Cloudpunk - City of Ghosts.exe','Cloudpunk - City of Ghosts_Data/resources.assets') }
            )
        }
        'dark-souls-ii-vr' = @{
            AppIds = @('335300')
            InstallerFolders = @('LukeRossVR')
            Files = @('Game/DarkSoulsII.exe','Game/GameDataEbl.bdt')
            FileSets = @(
                @{ Files = @('Game/DarkSoulsII.exe','Game/GameDataEbl.bdt') }
            )
        }
        'dark-souls-iii-vr' = @{
            AppIds = @('374320')
            InstallerFolders = @('LukeRossVR')
            Files = @('Game\DarkSoulsIII.exe','Game\Data1.bdt')
            FileSets = @(
                @{ Files = @('Game\DarkSoulsIII.exe','Game\Data1.bdt') }
            )
        }
        'dark-souls-remastered' = @{
            AppIds = @('570940')
            InstallerFolders = @('LukeRossVR')
            Files = @('DarkSoulsRemastered.exe','map\MapStudio\m10_00_00_00.msb')
            FileSets = @(
                @{ Files = @('DarkSoulsRemastered.exe','map\MapStudio\m10_00_00_00.msb') }
            )
        }
        'days-gone-vr' = @{
            AppIds = @('1259420')
            InstallerFolders = @('LukeRossVR')
            Files = @('BendGame\Binaries\Win64\DaysGone.exe','BendGame\Content\Paks\BendGame-WindowsNoEditor.pak')
            FileSets = @(
                @{ Files = @('BendGame\Binaries\Win64\DaysGone.exe','BendGame\Content\Paks\BendGame-WindowsNoEditor.pak') }
            )
        }
        'death-stranding-vr' = @{
            AppIds = @('1850570')
            InstallerFolders = @('LukeRossVR')
            Files = @('ds.exe','Movies/movies.mpk')
            FileSets = @(
                @{ Files = @('ds.exe','Movies/movies.mpk') }
            )
        }
        'decimate-drive-vr' = @{
            AppIds = @('2427950')
            InstallerFolders = @('DecimateDriveVR')
            Files = @('release/Decimate Drive.exe','release/Decimate Drive_Data/level1','release/Decimate Drive_Data/level2')
            FileSets = @(
                @{ Files = @('release/Decimate Drive.exe','release/Decimate Drive_Data/level1','release/Decimate Drive_Data/level2') }
            )
        }
        'descenders-vr' = @{
            AppIds = @('681280')
            InstallerFolders = @('DescendersVR')
            Files = @('Descenders.exe','Descenders_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Descenders.exe','Descenders_Data\resources.assets') }
            )
        }
        'devil-may-cry-5-vr' = @{
            AppIds = @('601150')
            InstallerFolders = @('REFrameworkVR')
            Files = @('DevilMayCry5.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('DevilMayCry5.exe','re_chunk_000.pak') }
            )
        }
        'dinkum-vr' = @{
            AppIds = @('1062520')
            InstallerFolders = @('DinkumVR')
            Files = @('Dinkum.exe','Dinkum_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Dinkum.exe','Dinkum_Data\resources.assets') }
            )
        }
        'dino-trauma-vr' = @{
            AppIds = @('2149420')
            InstallerFolders = @('DinoTraumaVR')
            Files = @('Dino Trauma.exe','Dino Trauma_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Dino Trauma.exe','Dino Trauma_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'doom-eternal-vr' = @{
            AppIds = @('782330')
            InstallerFolders = @('LukeRossVR')
            Files = @('DOOMEternalx64vk.exe','base\gameresources.resources')
            FileSets = @(
                @{ Files = @('DOOMEternalx64vk.exe','base\gameresources.resources') }
            )
        }
        'dragon-s-dogma-2-vr' = @{
            AppIds = @('2054970')
            InstallerFolders = @('REFrameworkVR')
            Files = @('DD2.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('DD2.exe','re_chunk_000.pak') }
            )
        }
        'driftwood-vr' = @{
            AppIds = @('2223700')
            InstallerFolders = @('DriftwoodVR')
            Files = @('Driftwood.exe','Driftwood_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Driftwood.exe','Driftwood_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'echo-generation-2-vr' = @{
            AppIds = @('1115990')
            InstallerFolders = @('EchoGeneration2VR')
            Files = @('Echo Generation 2.exe','Echo Generation 2_Data/globalgamemanagers')
            FileSets = @(
                @{ Files = @('Echo Generation 2.exe','Echo Generation 2_Data/globalgamemanagers') }
            )
        }
        'elden-ring-real-vr' = @{
            AppIds = @('1245620')
            InstallerFolders = @('EldenRingRealVR')
            Files = @('Game\eldenring.exe','Game\Data0.bdt')
            FileSets = @(
                @{ Files = @('Game\eldenring.exe','Game\Data0.bdt') }
            )
        }
        'far-cry-4-vr' = @{
            AppIds = @('298110')
            InstallerFolders = @('LukeRossVR')
            Files = @('bin\FarCry4.exe','data_win32\common.dat')
            FileSets = @(
                @{ Files = @('bin\FarCry4.exe','data_win32\common.dat') }
            )
        }
        'far-cry-5-vr' = @{
            AppIds = @('552520')
            InstallerFolders = @('LukeRossVR')
            Files = @('bin\FarCry5.exe','data_final\pc\common.dat')
            FileSets = @(
                @{ Files = @('bin\FarCry5.exe','data_final\pc\common.dat') }
            )
        }
        'far-cry-6-vr' = @{
            AppIds = @('2369390')
            InstallerFolders = @('LukeRossVR')
            Files = @('bin\FarCry6.exe','data_final\pc\common.dat')
            FileSets = @(
                @{ Files = @('bin\FarCry6.exe','data_final\pc\common.dat') }
            )
        }
        'far-cry-new-dawn-vr' = @{
            AppIds = @('939960')
            InstallerFolders = @('LukeRossVR')
            Files = @('bin\FarCryNewDawn.exe','data_final\pc\common.dat')
            FileSets = @(
                @{ Files = @('bin\FarCryNewDawn.exe','data_final\pc\common.dat') }
            )
        }
        'far-cry-primal-vr' = @{
            AppIds = @('371660')
            InstallerFolders = @('LukeRossVR')
            Files = @('bin\FCPrimal.exe','data_win32\common.dat')
            FileSets = @(
                @{ Files = @('bin\FCPrimal.exe','data_win32\common.dat') }
            )
        }
        'ff-vii-rebirth-vr' = @{
            AppIds = @('2909400')
            InstallerFolders = @('LukeRossVR')
            Files = @('End\Binaries\Win64\ff7rebirth_.exe','End\Content\Paks\pakchunk0-WindowsNoEditor.ucas')
            FileSets = @(
                @{ Files = @('End\Binaries\Win64\ff7rebirth_.exe','End\Content\Paks\pakchunk0-WindowsNoEditor.ucas') }
            )
        }
        'ff-vii-remake-vr' = @{
            AppIds = @('1462040')
            InstallerFolders = @('LukeRossVR')
            Files = @('End\Binaries\Win64\ff7remake_.exe','End\Content\Paks\pakchunk0-WindowsNoEditor.pak')
            FileSets = @(
                @{ Files = @('End\Binaries\Win64\ff7remake_.exe','End\Content\Paks\pakchunk0-WindowsNoEditor.pak') }
            )
        }
        'ff7-remake-intergrade-vr' = @{
            AppIds = @('1462040')
            InstallerFolders = @('FF7RemakeVR')
            Files = @('End/Binaries/Win64/ff7remake_.exe|End/Binaries/WinGDK/ff7remake.exe','End/Content/Paks/pakchunk0-WindowsNoEditor.pak')
            FileSets = @(
                @{ Files = @('End/Binaries/Win64/ff7remake_.exe','End/Content/Paks/pakchunk0-WindowsNoEditor.pak') }
                @{ Files = @('End/Binaries/WinGDK/ff7remake.exe','End/Content/Paks/pakchunk0-WindowsNoEditor.pak') }
            )
        }
        'grid-2019-vr' = @{
            AppIds = @('703860')
            InstallerFolders = @('Grid2019VR')
            Files = @('Grid_dx12.exe','asset_groups/animation_package/scenes/incardriver/2017/incardriver.erp')
            FileSets = @(
                @{ Files = @('Grid_dx12.exe','asset_groups/animation_package/scenes/incardriver/2017/incardriver.erp') }
            )
        }
        'grid-legends-vr' = @{
            AppIds = @('1307710')
            InstallerFolders = @('GridLegendsVR')
            Files = @('GridLegends.exe','asset_groups/animation_package/scenes/incardriver/2017/incardriver.erp')
            FileSets = @(
                @{ Files = @('GridLegends.exe','asset_groups/animation_package/scenes/incardriver/2017/incardriver.erp') }
            )
        }
        'dirt-4-vr' = @{
            AppIds = @('421020')
            InstallerFolders = @('Dirt4VR')
            Files = @('dirt4.exe','game.nefs')
            FileSets = @(
                @{ Files = @('dirt4.exe','game.nefs') }
            )
        }
        'forza-horizon-4-grayhorizon-vr' = @{
            AppIds = @('1293830')
            InstallerFolders = @('GrayHorizonFH4')
            Files = @('ForzaHorizon4.exe','media/stripped/gamedbRC.slt')
            FileSets = @(
                @{ Files = @('ForzaHorizon4.exe','media/stripped/gamedbRC.slt') }
            )
        }
        'forza-horizon-5-grayhorizon-vr' = @{
            AppIds = @('1551360')
            InstallerFolders = @('GrayHorizonFH5')
            Files = @('ForzaHorizon5.exe','media/Audio/AudioBanks.xml')
            FileSets = @(
                @{ Files = @('ForzaHorizon5.exe','media/Audio/AudioBanks.xml') }
            )
        }
        'forza-horizon-6-grayhorizon-vr' = @{
            AppIds = @('2483190')
            InstallerFolders = @('GrayHorizonFH6')
            Files = @('ForzaHorizon6.exe','media/Audio/AudioBanks.xml')
            FileSets = @(
                @{ Files = @('ForzaHorizon6.exe','media/Audio/AudioBanks.xml') }
            )
        }
        'forza-horizon-5-vr' = @{
            AppIds = @('1551360')
            InstallerFolders = @('ForzaHorizon5VR')
            Files = @('ForzaHorizon5.exe','media/Audio/AudioBanks.xml')
            FileSets = @(
                @{ Files = @('ForzaHorizon5.exe','media/Audio/AudioBanks.xml') }
            )
        }
        'forza-horizon-6-vr' = @{
            AppIds = @('2483190')
            InstallerFolders = @('ForzaHorizon6VR')
            Files = @('ForzaHorizon6.exe','media/Audio/AudioBanks.xml')
            FileSets = @(
                @{ Files = @('ForzaHorizon6.exe','media/Audio/AudioBanks.xml') }
            )
        }
        'ghost-of-tsushima-vr' = @{
            AppIds = @('2215430')
            InstallerFolders = @('LukeRossVR')
            Files = @('GhostOfTsushima.exe','cache_pc/psarc/gapack_meshes.psarc')
            FileSets = @(
                @{ Files = @('GhostOfTsushima.exe','cache_pc/psarc/gapack_meshes.psarc') }
            )
        }
        'ghost-recon-wildlands-vr' = @{
            AppIds = @('460930')
            InstallerFolders = @('GhostReconWildlandsVR')
            Files = @('GRW.exe','DataPC_GRN_WorldMap.forge')
            FileSets = @(
                @{ Files = @('GRW.exe','DataPC_GRN_WorldMap.forge') }
            )
        }
        'ghosts-n-goblins-resurrection-vr' = @{
            AppIds = @('1375400')
            InstallerFolders = @('REFrameworkVR')
            Files = @('makaimura_GG_RE.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('makaimura_GG_RE.exe','re_chunk_000.pak') }
            )
        }
        'ghostwire-tokyo-vr' = @{
            AppIds = @('1475810')
            InstallerFolders = @('LukeRossVR')
            Files = @('Snowfall\Binaries\Win64\GWT.exe','Snowfall\Content\Paks\Snowfall-WindowsNoEditor.pak')
            FileSets = @(
                @{ Files = @('Snowfall\Binaries\Win64\GWT.exe','Snowfall\Content\Paks\Snowfall-WindowsNoEditor.pak') }
            )
        }
        'grounded-vr' = @{
            AppIds = @('962130')
            InstallerFolders = @('LukeRossVR')
            Files = @('Maine\Binaries\Win64\Maine-Win64-Shipping.exe|Maine\Binaries\WinGDK\Maine-WinGDK-Shipping.exe','Maine\Content\Paks\pakchunk0-WindowsNoEditor.ucas|Maine\Content\Paks\Maine-WinGDK.pak')
            FileSets = @(
                @{ Files = @('Maine\Binaries\Win64\Maine-Win64-Shipping.exe','Maine\Content\Paks\pakchunk0-WindowsNoEditor.ucas') }
                @{ Files = @('Maine\Binaries\WinGDK\Maine-WinGDK-Shipping.exe','Maine\Content\Paks\Maine-WinGDK.pak') }
            )
        }
        'high-on-life-vr' = @{
            AppIds = @('1583230')
            InstallerFolders = @('LukeRossVR')
            Files = @('Oregon\Binaries\Win64\Oregon-Win64-Shipping.exe|Oregon\Binaries\WinGDK\Oregon-WinGDK-Shipping.exe','Oregon\Content\Paks\Oregon-WindowsNoEditor.pak|Oregon\Content\Paks\Oregon-WinGDK.pak')
            FileSets = @(
                @{ Files = @('Oregon\Binaries\Win64\Oregon-Win64-Shipping.exe','Oregon\Content\Paks\Oregon-WindowsNoEditor.pak') }
                @{ Files = @('Oregon\Binaries\WinGDK\Oregon-WinGDK-Shipping.exe','Oregon\Content\Paks\Oregon-WinGDK.pak') }
            )
        }
        'hogwarts-legacy-vr' = @{
            AppIds = @('990080')
            InstallerFolders = @('LukeRossVR')
            Files = @('Phoenix\Binaries\Win64\HogwartsLegacy.exe','Phoenix\Content\Paks\pakchunk0-WindowsNoEditor.ucas')
            FileSets = @(
                @{ Files = @('Phoenix\Binaries\Win64\HogwartsLegacy.exe','Phoenix\Content\Paks\pakchunk0-WindowsNoEditor.ucas') }
            )
        }
        'hollow-knight-silksong' = @{
            AppIds = @('1030300')
            InstallerFolders = @('HollowKnightSilksongVR')
            Files = @('Hollow Knight Silksong.exe','Hollow Knight Silksong_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Hollow Knight Silksong.exe','Hollow Knight Silksong_Data\resources.assets') }
            )
        }
        'hollow-knight-vr' = @{
            AppIds = @('367520')
            InstallerFolders = @('HollowKnightVR')
            Files = @('hollow_knight.exe','hollow_knight_Data\resources.assets')
            FileSets = @(
                @{ Files = @('hollow_knight.exe','hollow_knight_Data\resources.assets') }
            )
        }
        'horizon-chase-turbo' = @{
            AppIds = @('389140')
            InstallerFolders = @('HorizonChaseTurboVR')
            Files = @('HorizonChase.exe','HorizonChase_Data\resources.assets')
            FileSets = @(
                @{ Files = @('HorizonChase.exe','HorizonChase_Data\resources.assets') }
            )
        }
        'horizon-forbidden-west-vr' = @{
            AppIds = @('2420110')
            InstallerFolders = @('LukeRossVR')
            Files = @('HorizonForbiddenWest.exe','LocalCacheWinGame\package\package.00.00.core')
            FileSets = @(
                @{ Files = @('HorizonForbiddenWest.exe','LocalCacheWinGame\package\package.00.00.core') }
            )
        }
        'horizon-zero-dawn-vr' = @{
            AppIds = @('1151640')
            InstallerFolders = @('LukeRossVR')
            Files = @('HorizonZeroDawn.exe','Packed_DX12\Initial.bin')
            FileSets = @(
                @{ Files = @('HorizonZeroDawn.exe','Packed_DX12\Initial.bin') }
            )
        }
        'horizon-zero-dawn-remastered-vr' = @{
            AppIds = @('2561580')
            InstallerFolders = @('LukeRossVR')
            Files = @('HorizonZeroDawnRemastered.exe','LocalCacheDX12\package\package.00.00.core')
            FileSets = @(
                @{ Files = @('HorizonZeroDawnRemastered.exe','LocalCacheDX12\package\package.00.00.core') }
            )
        }
        'hypogea-vr' = @{
            AppIds = @('2980260')
            InstallerFolders = @('HypogeaVR')
            Files = @('Hypogea.exe','Hypogea_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Hypogea.exe','Hypogea_Data\resources.assets') }
            )
        }
        'indiana-jones-great-circle-vr' = @{
            AppIds = @('2677660')
            InstallerFolders = @('LukeRossVR')
            Files = @('TheGreatCircle.exe','base/game/relic/college/college_night_pc.resources')
            FileSets = @(
                @{ Files = @('TheGreatCircle.exe','base/game/relic/college/college_night_pc.resources') }
            )
        }
        'kingdom-come-deliverance-vr' = @{
            AppIds = @('379430')
            InstallerFolders = @('KCD1VR')
            Files = @('Bin/Win64/KingdomCome.exe|Bin/Win64MasterMasterEpicPGO/KingdomCome.exe','Bin/Win64/WHGame.dll|Bin/Win64MasterMasterEpicPGO/WHGame.dll','Data/Levels/rataje/level.pak')
            FileSets = @(
                @{ Files = @('Bin/Win64/KingdomCome.exe','Bin/Win64/WHGame.dll','Data/Levels/rataje/level.pak') }
                @{ Files = @('Bin/Win64MasterMasterEpicPGO/KingdomCome.exe','Bin/Win64MasterMasterEpicPGO/WHGame.dll','Data/Levels/rataje/level.pak') }
            )
        }
        'kingdom-come-deliverance-ii-vr' = @{
            AppIds = @('1771300')
            InstallerFolders = @('LukeRossVR')
            Files = @('Bin/Win64MasterMasterSteamPGO/KingdomCome.exe|Bin/Win64MasterMasterEpicPGO/KingdomCome.exe|Bin/Win64MasterMasterGogPGO/KingdomCome.exe|KingdomCome.exe','Bin/Win64MasterMasterSteamPGO/WHGame.dll|Bin/Win64MasterMasterEpicPGO/WHGame.dll|Bin/Win64MasterMasterGogPGO/WHGame.dll|WHGame.dll','Data/Levels/trosecko/level.pak')
            FileSets = @(
                @{ Files = @('Bin/Win64MasterMasterSteamPGO/KingdomCome.exe','Bin/Win64MasterMasterSteamPGO/WHGame.dll','Data/Levels/trosecko/level.pak') }
                @{ Files = @('Bin/Win64MasterMasterEpicPGO/KingdomCome.exe','Bin/Win64MasterMasterEpicPGO/WHGame.dll','Data/Levels/trosecko/level.pak') }
                @{ Files = @('Bin/Win64MasterMasterGogPGO/KingdomCome.exe','Bin/Win64MasterMasterGogPGO/WHGame.dll','Data/Levels/trosecko/level.pak') }
                @{ Files = @('KingdomCome.exe','WHGame.dll','Data/Levels/trosecko/level.pak') }
            )
        }
        'kunitsu-gami-path-of-the-goddess-vr' = @{
            AppIds = @('2510710')
            InstallerFolders = @('REFrameworkVR')
            Files = @('KunitsuGami.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('KunitsuGami.exe','re_chunk_000.pak') }
            )
        }
        'lunistice-vr' = @{
            AppIds = @('1701800')
            InstallerFolders = @('LunisticeVR')
            Files = @('Lunistice.exe','Lunistice_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Lunistice.exe','Lunistice_Data\resources.assets') }
            )
        }
        'mass-effect-1-le-vr' = @{
            AppIds = @('1328670')
            InstallerFolders = @('MassEffect1VR')
            Files = @('Game/ME1/Binaries/Win64/MassEffect1.exe','Game/ME1/BioGame/CookedPCConsole/SFXGame.pcc')
            FileSets = @(
                @{ Files = @('Game/ME1/Binaries/Win64/MassEffect1.exe','Game/ME1/BioGame/CookedPCConsole/SFXGame.pcc') }
            )
        }
        'mass-effect-2-le-vr' = @{
            AppIds = @('1328670')
            InstallerFolders = @('MassEffect2VR')
            Files = @('Game/ME2/Binaries/Win64/MassEffect2.exe','Game/ME2/BioGame/CookedPCConsole/SFXGame.pcc')
            FileSets = @(
                @{ Files = @('Game/ME2/Binaries/Win64/MassEffect2.exe','Game/ME2/BioGame/CookedPCConsole/SFXGame.pcc') }
            )
        }
        'mass-effect-3-le-vr' = @{
            AppIds = @('1328670')
            InstallerFolders = @('MassEffect3VR')
            Files = @('Game/ME3/Binaries/Win64/MassEffect3.exe','Game/ME3/BioGame/CookedPCConsole/SFXGame.pcc')
            FileSets = @(
                @{ Files = @('Game/ME3/Binaries/Win64/MassEffect3.exe','Game/ME3/BioGame/CookedPCConsole/SFXGame.pcc') }
            )
        }
        'mega-man-star-force-legacy-vr' = @{
            AppIds = @('3500390')
            InstallerFolders = @('REFrameworkVR')
            Files = @('MEGAMAN_STARFORCE_Legacy_Collection.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('MEGAMAN_STARFORCE_Legacy_Collection.exe','re_chunk_000.pak') }
            )
        }
        'mirage-feathers-vr' = @{
            AppIds = @('2719060')
            InstallerFolders = @('MirageFeathersVR')
            Files = @('Mirage Feathers.exe','Mirage Feathers_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Mirage Feathers.exe','Mirage Feathers_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'mirrors-edge-catalyst-vr' = @{
            AppIds = @('1233570')
            InstallerFolders = @('MirrorsEdgeCatalystVR')
            Files = @('MirrorsEdgeCatalyst.exe','Data/Win32/gameconfigurations/defaultinstallpackage/cas_01.cas')
            FileSets = @(
                @{ Files = @('MirrorsEdgeCatalyst.exe','Data/Win32/gameconfigurations/defaultinstallpackage/cas_01.cas') }
            )
        }
        'monster-hunter-rise-vr' = @{
            AppIds = @('1446780')
            InstallerFolders = @('REFrameworkVR')
            Files = @('MonsterHunterRise.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('MonsterHunterRise.exe','re_chunk_000.pak') }
            )
        }
        'monster-hunter-stories-3-vr' = @{
            AppIds = @('2852190')
            InstallerFolders = @('REFrameworkVR')
            Files = @('MONSTER_HUNTER_STORIES_3_TWISTED_REFLECTION.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('MONSTER_HUNTER_STORIES_3_TWISTED_REFLECTION.exe','re_chunk_000.pak') }
            )
        }
        'monster-hunter-wilds' = @{
            AppIds = @('2246340')
            InstallerFolders = @('REFrameworkVR')
            Files = @('MonsterHunterWilds.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('MonsterHunterWilds.exe','re_chunk_000.pak') }
            )
        }
        'moto-rush-reborn-vr' = @{
            AppIds = @('2990060')
            InstallerFolders = @('MotoRushRebornVR')
            Files = @('Moto Rush Reborn.exe','Moto Rush Reborn_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Moto Rush Reborn.exe','Moto Rush Reborn_Data\resources.assets') }
            )
        }
        'muck-vr' = @{
            AppIds = @('1625450')
            InstallerFolders = @('MuckVR')
            Files = @('Muck.exe','Muck_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Muck.exe','Muck_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'new-star-gp-vr' = @{
            AppIds = @('2217580')
            InstallerFolders = @('NewStarGPVR')
            Files = @('release\NSGP.exe','release\NSGP_Data\resources.assets')
            FileSets = @(
                @{ Files = @('release\NSGP.exe','release\NSGP_Data\resources.assets') }
            )
        }
        'no-one-lives-forever-2-vr' = @{
            InstallerFolders = @('NOLF2VR')
            Files = @('NOLF2.exe','GAME.REZ','GAME2.REZ')
            FileSets = @(
                @{ Files = @('NOLF2.exe','GAME.REZ','GAME2.REZ') }
            )
        }
        'nuclear-option-vr' = @{
            AppIds = @('2168680')
            InstallerFolders = @('NuclearOptionVR')
            Files = @('NuclearOption.exe','NuclearOption_Data\resources.assets')
            FileSets = @(
                @{ Files = @('NuclearOption.exe','NuclearOption_Data\resources.assets') }
            )
        }
        'oblivion-2006-vr' = @{
            AppIds = @('22330')
            InstallerFolders = @('Oblivion2006VR')
            Files = @('Oblivion.exe','Data\Oblivion.esm')
            FileSets = @(
                @{ Files = @('Oblivion.exe','Data\Oblivion.esm') }
            )
        }
        'onimusha-2-vr' = @{
            AppIds = @('3046600')
            InstallerFolders = @('REFrameworkVR')
            Files = @('Onimusha2.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('Onimusha2.exe','re_chunk_000.pak') }
            )
        }
        'outbound-vr' = @{
            AppIds = @('2681030')
            InstallerFolders = @('OutboundVR')
            Files = @('Outbound.exe','Outbound_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Outbound.exe','Outbound_Data\resources.assets') }
            )
        }
        'outlast-vr' = @{
            AppIds = @('238320')
            InstallerFolders = @('OutlastVR')
            Files = @('Binaries\Win64\OLGame.exe|Binaries\Win32\OLGame.exe','OLGame\CookedPCConsole\OLGame.upk')
            FileSets = @(
                @{ Files = @('Binaries\Win64\OLGame.exe|Binaries\Win32\OLGame.exe','OLGame\CookedPCConsole\OLGame.upk') }
            )
        }
        'outlast-2-vr' = @{
            AppIds = @('414700')
            InstallerFolders = @('Outlast2VR')
            Files = @('Binaries\Win64\Outlast2.exe','OLGame\CookedPCConsole\OLGame.upk')
            FileSets = @(
                @{ Files = @('Binaries\Win64\Outlast2.exe','OLGame\CookedPCConsole\OLGame.upk') }
            )
        }
        'paperklay-vr' = @{
            AppIds = @('1350720')
            InstallerFolders = @('PaperklayVR')
            Files = @('PaperKlay.exe','PaperKlay_Data\resources.assets')
            FileSets = @(
                @{ Files = @('PaperKlay.exe','PaperKlay_Data\resources.assets') }
            )
        }
        'paranoia-place-vr' = @{
            AppIds = @('1592290')
            InstallerFolders = @('ParanoiaPlaceVR')
            Files = @('Paranoia Place.exe','Paranoia Place_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Paranoia Place.exe','Paranoia Place_Data\resources.assets') }
            )
        }
        'pragmata-vr' = @{
            AppIds = @('3357650')
            InstallerFolders = @('REFrameworkVR')
            Files = @('PRAGMATA.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('PRAGMATA.exe','re_chunk_000.pak') }
            )
        }
        'rebel-galaxy-vr' = @{
            AppIds = @('290300')
            InstallerFolders = @('RebelGalaxyVR')
            Files = @('RebelGalaxySteam.exe|RebelGalaxyGOG.exe|RebelGalaxy.exe','PAKS\DATA.PAK')
            FileSets = @(
                @{ Files = @('RebelGalaxySteam.exe|RebelGalaxyGOG.exe|RebelGalaxy.exe','PAKS\DATA.PAK') }
            )
        }
        'retrowave-2-vr' = @{
            AppIds = @('3331000')
            InstallerFolders = @('Retrowave2VR')
            Files = @('Retrowave 2.exe','Retrowave 2_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Retrowave 2.exe','Retrowave 2_Data\resources.assets') }
            )
        }
        'road-redemption-vr' = @{
            AppIds = @('300380')
            InstallerFolders = @('RoadRedemptionVR')
            Files = @('RoadRedemption.exe|Road Redemption Alpha/RoadRedemption.exe','RoadRedemption_Data/Managed/Assembly-CSharp.dll|Road Redemption Alpha/RoadRedemption_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('RoadRedemption.exe','RoadRedemption_Data/Managed/Assembly-CSharp.dll') }
                @{ Files = @('Road Redemption Alpha/RoadRedemption.exe','Road Redemption Alpha/RoadRedemption_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'rogue-flight-vr' = @{
            AppIds = @('2784620')
            InstallerFolders = @('RogueFlightVR')
            Files = @('RogueFlight.exe','RogueFlight_Data/resources.assets')
            FileSets = @(
                @{ Files = @('RogueFlight.exe','RogueFlight_Data/resources.assets') }
            )
        }
        'sayonara-wild-hearts' = @{
            AppIds = @('1122720')
            InstallerFolders = @('SayonaraWildHeartsVR')
            Files = @('Sayonara Wild Hearts.exe','Sayonara Wild Hearts_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Sayonara Wild Hearts.exe','Sayonara Wild Hearts_Data\resources.assets') }
            )
        }
        'shenmue-i-ii' = @{
            AppIds = @('758330')
            InstallerFolders = @('ShenmueVR')
            Files = @('sm1/Shenmue.exe|sm2/Shenmue2.exe|Shenmue/sm1/Shenmue.exe|Shenmue II/sm2/Shenmue2.exe|Shenmue.exe|Shenmue2.exe','sm1/archives/dx11/data/disk_5be2c578.tac|sm2/archives/dx11/data/disk_5be2c4e2.tac|Shenmue/sm1/archives/dx11/data/disk_5be2c578.tac|Shenmue II/sm2/archives/dx11/data/disk_5be2c4e2.tac|archives/dx11/data/disk_5be2c578.tac|archives/dx11/data/disk_5be2c4e2.tac','sm1/archives/dx11/data/disk_5be2c578.tad|sm2/archives/dx11/data/disk_5be2c4e2.tad|Shenmue/sm1/archives/dx11/data/disk_5be2c578.tad|Shenmue II/sm2/archives/dx11/data/disk_5be2c4e2.tad|archives/dx11/data/disk_5be2c578.tad|archives/dx11/data/disk_5be2c4e2.tad')
            FileSets = @(
                @{ Files = @('sm1/Shenmue.exe'); ArchivePairs = @(@{ Directory = 'sm1/archives/dx11/data'; StemPattern = '^disk_[0-9a-f]{8}$'; DataExtension = '.tac'; IndexExtension = '.tad' }) }
                @{ Files = @('sm2/Shenmue2.exe'); ArchivePairs = @(@{ Directory = 'sm2/archives/dx11/data'; StemPattern = '^disk_[0-9a-f]{8}$'; DataExtension = '.tac'; IndexExtension = '.tad' }) }
                @{ Files = @('Shenmue/sm1/Shenmue.exe'); ArchivePairs = @(@{ Directory = 'Shenmue/sm1/archives/dx11/data'; StemPattern = '^disk_[0-9a-f]{8}$'; DataExtension = '.tac'; IndexExtension = '.tad' }) }
                @{ Files = @('Shenmue II/sm2/Shenmue2.exe'); ArchivePairs = @(@{ Directory = 'Shenmue II/sm2/archives/dx11/data'; StemPattern = '^disk_[0-9a-f]{8}$'; DataExtension = '.tac'; IndexExtension = '.tad' }) }
                @{ Files = @('Shenmue.exe'); ArchivePairs = @(@{ Directory = 'archives/dx11/data'; StemPattern = '^disk_[0-9a-f]{8}$'; DataExtension = '.tac'; IndexExtension = '.tad' }) }
                @{ Files = @('Shenmue2.exe'); ArchivePairs = @(@{ Directory = 'archives/dx11/data'; StemPattern = '^disk_[0-9a-f]{8}$'; DataExtension = '.tac'; IndexExtension = '.tad' }) }
            )
        }
        'skate-story-vr' = @{
            AppIds = @('1263240')
            InstallerFolders = @('SkateStoryVR')
            Files = @('SkateStory.exe','SkateStory_Data\Managed\Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('SkateStory.exe','SkateStory_Data\Managed\Assembly-CSharp.dll') }
            )
        }
        'sonic-p-06-vr' = @{
            InstallerFolders = @('SonicP06VR')
            Files = @('Sonic the Hedgehog.exe','Sonic the Hedgehog_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Sonic the Hedgehog.exe','Sonic the Hedgehog_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'snowrunner-vr' = @{
            AppIds = @('1465360')
            InstallerFolders = @('SnowRunnerVR')
            Files = @('Sources\Bin\SnowRunner.exe','preload\paks\client\initial.pak')
            FileSets = @(
                @{ Files = @('Sources\Bin\SnowRunner.exe','preload\paks\client\initial.pak') }
            )
        }
        'spiderman-2-vr' = @{
            AppIds = @('2651280')
            InstallerFolders = @('LukeRossVR')
            Files = @('Spider-Man2.exe|SpiderMan2.exe','d\model_hero')
            FileSets = @(
                @{ Files = @('Spider-Man2.exe|SpiderMan2.exe','d\model_hero') }
            )
        }
        'spiderman-miles-morales-vr' = @{
            AppIds = @('1817190')
            InstallerFolders = @('LukeRossVR')
            Files = @('MilesMorales.exe','asset_archive\g00s000')
            FileSets = @(
                @{ Files = @('MilesMorales.exe','asset_archive\g00s000') }
            )
        }
        'spiderman-remastered' = @{
            AppIds = @('1817070')
            InstallerFolders = @('LukeRossVR')
            Files = @('Spider-Man.exe','asset_archive\g00s000')
            FileSets = @(
                @{ Files = @('Spider-Man.exe','asset_archive\g00s000') }
            )
        }
        'star-racer-vr' = @{
            AppIds = @('2626120')
            InstallerFolders = @('StarRacerVR')
            Files = @('StarRacer\Star Racer.exe','StarRacer\Star Racer_Data\resources.assets')
            FileSets = @(
                @{ Files = @('StarRacer\Star Racer.exe','StarRacer\Star Racer_Data\resources.assets') }
            )
        }
        'star-trucker-vr' = @{
            AppIds = @('2380050')
            InstallerFolders = @('StarTruckerVR')
            Files = @('Star Trucker.exe','Star Trucker_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Star Trucker.exe','Star Trucker_Data\resources.assets') }
            )
        }
        'star-wars-outlaws-vr' = @{
            AppIds = @('2842040')
            InstallerFolders = @('LukeRossVR')
            Files = @('Outlaws.exe','helix\sdf\pc\data\sdf-A-0000.sdfdata')
            FileSets = @(
                @{ Files = @('Outlaws.exe','helix\sdf\pc\data\sdf-A-0000.sdfdata') }
            )
        }
        'starfield-vr' = @{
            AppIds = @('1716740')
            InstallerFolders = @('StarfieldVR')
            Files = @('Starfield.exe','Data\Starfield.esm')
            FileSets = @(
                @{ Files = @('Starfield.exe','Data\Starfield.esm') }
            )
        }
        'stray-vr' = @{
            AppIds = @('1332010')
            InstallerFolders = @('LukeRossVR')
            Files = @('Hk_project\Binaries\Win64\Stray-Win64-Shipping.exe','Hk_project\Content\Paks\Hk_project-WindowsNoEditor.pak')
            FileSets = @(
                @{ Files = @('Hk_project\Binaries\Win64\Stray-Win64-Shipping.exe','Hk_project\Content\Paks\Hk_project-WindowsNoEditor.pak') }
            )
        }
        'street-fighter-6-vr' = @{
            AppIds = @('1364780')
            InstallerFolders = @('REFrameworkVR')
            Files = @('StreetFighter6.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('StreetFighter6.exe','re_chunk_000.pak') }
            )
        }
        'streetdog-bmx-vr' = @{
            AppIds = @('2707870')
            InstallerFolders = @('StreetDogBMXVR')
            Files = @('streetdogbmx.exe','streetdogbmx_Data\resources.assets')
            FileSets = @(
                @{ Files = @('streetdogbmx.exe','streetdogbmx_Data\resources.assets') }
            )
        }
        'sunrise-gp-vr' = @{
            AppIds = @('2670800')
            InstallerFolders = @('SunriseGPVR')
            Files = @('Sunrise GP.exe','Sunrise GP_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Sunrise GP.exe','Sunrise GP_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'thehunter-call-of-the-wild-vr' = @{
            AppIds = @('518790')
            InstallerFolders = @('TheHunterCotWVR')
            Files = @('theHunterCotW_F.exe','archives_win64\game0.arc')
            FileSets = @(
                @{ Files = @('theHunterCotW_F.exe','archives_win64\game0.arc') }
            )
        }
        'thief-2014-vr' = @{
            AppIds = @('239160')
            InstallerFolders = @('Thief2014VR')
            Files = @('binaries\win64\shipping-thiefgame.exe|binaries\win32\shipping-thiefgame.exe|Binaries2\Win64\Shipping-ThiefGame.exe','ThiefGame\CookedPCNG\ThiefGame.u')
            FileSets = @(
                @{ Files = @('binaries\win64\shipping-thiefgame.exe|binaries\win32\shipping-thiefgame.exe|Binaries2\Win64\Shipping-ThiefGame.exe','ThiefGame\CookedPCNG\ThiefGame.u') }
            )
        }
        'tinykin-vr' = @{
            AppIds = @('1599020')
            InstallerFolders = @('TinykinVR')
            Files = @('Tinykin.exe','Tinykin_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Tinykin.exe','Tinykin_Data\resources.assets') }
            )
        }
        'tlou-part-i-vr' = @{
            AppIds = @('1888930')
            InstallerFolders = @('LukeRossVR')
            Files = @('tlou-i.exe','build\pc\main\sp-common.psarc')
            FileSets = @(
                @{ Files = @('tlou-i.exe','build\pc\main\sp-common.psarc') }
            )
        }
        'tlou-part-ii-vr' = @{
            AppIds = @('2531310')
            InstallerFolders = @('LukeRossVR')
            Files = @('tlou-ii.exe|tlou-ii-l.exe|t2r-steam-final-pgo-lto.exe|t2r-epic-final-pgo-lto.exe','build/pc/main/sp-common.psarc','build/pc/main/world-ellie-flashback-museum.psarc')
            FileSets = @(
                @{ Files = @('tlou-ii.exe','build/pc/main/sp-common.psarc','build/pc/main/world-ellie-flashback-museum.psarc') }
                @{ Files = @('tlou-ii-l.exe','build/pc/main/sp-common.psarc','build/pc/main/world-ellie-flashback-museum.psarc') }
                @{ Files = @('t2r-steam-final-pgo-lto.exe','build/pc/main/sp-common.psarc','build/pc/main/world-ellie-flashback-museum.psarc') }
                @{ Files = @('t2r-epic-final-pgo-lto.exe','build/pc/main/sp-common.psarc','build/pc/main/world-ellie-flashback-museum.psarc') }
            )
        }
        'trackmania-nations-forever' = @{
            AppIds = @('11020')
            InstallerFolders = @('TrackManiaNationsForeverVR')
            Files = @('TmForever.exe','Packs/Stadium.pak')
            FileSets = @(
                @{ Files = @('TmForever.exe','Packs/Stadium.pak'); RejectIfAllFiles = @('Packs/Alpine.pak','Packs/Speed.pak') }
            )
        }
        'trackmania-united-forever' = @{
            AppIds = @('7200')
            InstallerFolders = @('TrackManiaUnitedForeverVR')
            Files = @('TmForever.exe','Packs/Alpine.pak','Packs/Speed.pak')
            FileSets = @(
                @{ Files = @('TmForever.exe','Packs/Alpine.pak','Packs/Speed.pak') }
            )
        }
        'uncharted-legacy-of-thieves-vr' = @{
            AppIds = @('1659420')
            InstallerFolders = @('LukeRossVR')
            Files = @('u4.exe','Uncharted4_data\build\pc\uncharted4\boot1.psarc')
            FileSets = @(
                @{ Files = @('u4.exe','Uncharted4_data\build\pc\uncharted4\boot1.psarc') }
            )
        }
        'unmourned-vr' = @{
            AppIds = @('3528970')
            InstallerFolders = @('UnmournedVR')
            Files = @('Unmourned.exe','Unmourned_Data\data.unity3d')
            FileSets = @(
                @{ Files = @('Unmourned.exe','Unmourned_Data\data.unity3d') }
            )
        }
        'watch-dogs-vr' = @{
            AppIds = @('243470')
            InstallerFolders = @('LukeRossVR')
            Files = @('bin\watch_dogs.exe','data_win64\worlds\windy_city\windy_city.dat')
            FileSets = @(
                @{ Files = @('bin\watch_dogs.exe','data_win64\worlds\windy_city\windy_city.dat') }
            )
        }
        'watch-dogs-2-vr' = @{
            AppIds = @('447040')
            InstallerFolders = @('LukeRossVR')
            Files = @('bin\WatchDogs2.exe','data_win64\worlds\san_francisco\san_francisco.dat')
            FileSets = @(
                @{ Files = @('bin\WatchDogs2.exe','data_win64\worlds\san_francisco\san_francisco.dat') }
            )
        }
        'watch-dogs-legion-vr' = @{
            AppIds = @('2239550')
            InstallerFolders = @('LukeRossVR')
            Files = @('bin\WatchDogsLegion.exe','data_win64\worlds\london\london.dat')
            FileSets = @(
                @{ Files = @('bin\WatchDogsLegion.exe','data_win64\worlds\london\london.dat') }
            )
        }
        'witcher-3-vr' = @{
            AppIds = @('292030')
            InstallerFolders = @('Witcher3VR')
            Files = @('bin\x64_dx12\witcher3.exe|bin\x64\witcher3.exe','content\content0\bundles\xml.bundle')
            FileSets = @(
                @{ Files = @('bin\x64_dx12\witcher3.exe|bin\x64\witcher3.exe','content\content0\bundles\xml.bundle') }
            )
        }
        'wreckfest-2-vr' = @{
            AppIds = @('1203190')
            InstallerFolders = @('Wreckfest2VR')
            Files = @('Wreckfest2.exe','data\vehicle\car01\art\body.vhcl')
            FileSets = @(
                @{ Files = @('Wreckfest2.exe','data\vehicle\car01\art\body.vhcl') }
            )
        }
        'wreckfest-vr' = @{
            AppIds = @('228380')
            InstallerFolders = @('WreckfestVR')
            Files = @('Wreckfest_x64.exe|Wreckfest.exe','data\vehicle\01_american\art\body.vhcl')
            FileSets = @(
                @{ Files = @('Wreckfest_x64.exe|Wreckfest.exe','data\vehicle\01_american\art\body.vhcl') }
            )
        }
        'x4-foundations-vr' = @{
            AppIds = @('392160')
            InstallerFolders = @('X4VR')
            Files = @('X4.exe','01.dat')
            FileSets = @(
                @{ Files = @('X4.exe','01.dat') }
            )
        }
        'yooka-laylee-vr' = @{
            AppIds = @('360830')
            InstallerFolders = @('YookaLayleeVR')
            Files = @('YookaLaylee64.exe','YookaLaylee64_Data\resources.assets')
            FileSets = @(
                @{ Files = @('YookaLaylee64.exe','YookaLaylee64_Data\resources.assets') }
            )
        }
        'crysis-vr' = @{
            AppIds = @('17300')
            Files = @('Bin32/Crysis.exe|Bin64/Crysis.exe','Game/Objects.pak')
            FileSets = @(
                @{ Files = @('Bin32/Crysis.exe','Game/Objects.pak') }
                @{ Files = @('Bin64/Crysis.exe','Game/Objects.pak') }
            )
        }
        'fallout-4-vr' = @{
            AppIds = @('611660')
            Files = @('Fallout4VR.exe','Data\Fallout4.esm')
            FileSets = @(
                @{ Files = @('Fallout4VR.exe','Data\Fallout4.esm') }
            )
        }
        'far-cry-vr' = @{
            AppIds = @('13520')
            Files = @('Bin32/FarCry.exe','FCData/Objects.pak')
            FileSets = @(
                @{ Files = @('Bin32/FarCry.exe','FCData/Objects.pak') }
            )
        }
        'firewatch-vr' = @{
            AppIds = @('383870')
            Files = @('Firewatch.exe','Firewatch_Data/Managed/Assembly-CSharp.dll')
            FileSets = @(
                @{ Files = @('Firewatch.exe','Firewatch_Data/Managed/Assembly-CSharp.dll') }
            )
        }
        'freespace-2-vr' = @{
            AppIds = @('273620')
            Files = @('root_fs2.vp|data\root_fs2.vp','sparky_fs2.vp|data\sparky_fs2.vp')
            FileSets = @(
                @{ Files = @('root_fs2.vp','sparky_fs2.vp') }
                @{ Files = @('data\root_fs2.vp','data\sparky_fs2.vp') }
            )
        }
        'half-life-vr' = @{
            AppIds = @('1908720')
            Files = @('valve/maps/c1a0.bsp','valve/maps/c4a1.bsp','valve/dlls/hl.dll')
            FileSets = @(
                @{ Files = @('valve/maps/c1a0.bsp','valve/maps/c4a1.bsp','valve/dlls/hl.dll') }
            )
        }
        'half-life-2-vr' = @{
            AppIds = @('658920')
            Files = @('hl2/maps/d1_trainstation_01.bsp','hl2/maps/d1_canals_01.bsp')
            FileSets = @(
                @{ Files = @('hl2/maps/d1_trainstation_01.bsp','hl2/maps/d1_canals_01.bsp') }
            )
        }
        'hl2-vr-ep-one' = @{
            AppIds = @('2177750')
            Files = @('episodic/maps/ep1_citadel_00.bsp','episodic/maps/ep1_c17_00.bsp')
            FileSets = @(
                @{ Files = @('episodic/maps/ep1_citadel_00.bsp','episodic/maps/ep1_c17_00.bsp') }
            )
        }
        'hl2-vr-ep-two' = @{
            AppIds = @('2177760')
            Files = @('ep2/maps/ep2_outland_01.bsp','ep2/maps/ep2_outland_02.bsp')
            FileSets = @(
                @{ Files = @('ep2/maps/ep2_outland_01.bsp','ep2/maps/ep2_outland_02.bsp') }
            )
        }
        'jedi-knight-jedi-academy-vr' = @{
            AppIds = @('6020')
            Files = @('GameData/jasp.exe|jasp.exe|GameData/base/assets0.pk3|base/assets0.pk3','GameData/base/assets1.pk3|base/assets1.pk3')
            FileSets = @(
                @{ Files = @('GameData/base/assets0.pk3','GameData/base/assets1.pk3'); Containers = @(@{ File = 'GameData/base/assets0.pk3|GameData/base/assets1.pk3'; Format = 'ZIP'; Entries = @('maps/academy1.bsp','maps/t1_fatal.bsp') }) }
                @{ Files = @('base/assets0.pk3','base/assets1.pk3'); Containers = @(@{ File = 'base/assets0.pk3|base/assets1.pk3'; Format = 'ZIP'; Entries = @('maps/academy1.bsp','maps/t1_fatal.bsp') }) }
            )
        }
        'jedi-knight-jedi-outcast-vr' = @{
            AppIds = @('6030')
            Files = @('GameData/jk2sp.exe|jk2sp.exe|GameData/base/assets0.pk3|base/assets0.pk3','GameData/base/assets1.pk3|base/assets1.pk3')
            FileSets = @(
                @{ Files = @('GameData/base/assets0.pk3','GameData/base/assets1.pk3'); Containers = @(@{ File = 'GameData/base/assets0.pk3|GameData/base/assets1.pk3'; Format = 'ZIP'; Entries = @('maps/kejim_post.bsp','maps/bespin_streets.bsp') }) }
                @{ Files = @('base/assets0.pk3','base/assets1.pk3'); Containers = @(@{ File = 'base/assets0.pk3|base/assets1.pk3'; Format = 'ZIP'; Entries = @('maps/kejim_post.bsp','maps/bespin_streets.bsp') }) }
            )
        }
        'morrowind-vr' = @{
            AppIds = @('22320')
            Files = @('Morrowind.esm|Data Files\Morrowind.esm','Morrowind.bsa|Data Files\Morrowind.bsa')
            FileSets = @(
                @{ Files = @('Morrowind.esm','Morrowind.bsa') }
                @{ Files = @('Data Files\Morrowind.esm','Data Files\Morrowind.bsa') }
            )
        }
        'neon-white-vr' = @{
            AppIds = @('1533420')
            Files = @('Neon White.exe','Neon White_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Neon White.exe','Neon White_Data\resources.assets') }
            )
        }
        'portal-2-community-edition-vr' = @{
            AppIds = @('440000')
            Files = @('bin/win64/p2ce.exe','p2ce/bin/win64/server.dll')
            FileSets = @(
                @{ Files = @('bin/win64/p2ce.exe','p2ce/bin/win64/server.dll') }
            )
        }
        'receiver-2-vr' = @{
            AppIds = @('1129310')
            Files = @('Receiver2.exe','Receiver2_Data/resources.assets')
            FileSets = @(
                @{ Files = @('Receiver2.exe','Receiver2_Data/resources.assets') }
            )
        }
        'resident-evil-2r-vr' = @{
            AppIds = @('883710')
            Files = @('re2.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('re2.exe','re_chunk_000.pak') }
            )
        }
        'resident-evil-3r-vr' = @{
            AppIds = @('952060')
            Files = @('re3.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('re3.exe','re_chunk_000.pak') }
            )
        }
        'resident-evil-4r-vr' = @{
            AppIds = @('2050650')
            Files = @('re4.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('re4.exe','re_chunk_000.pak') }
            )
        }
        'resident-evil-7-vr' = @{
            AppIds = @('418370')
            Files = @('re7.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('re7.exe','re_chunk_000.pak') }
            )
        }
        're-village-vr' = @{
            AppIds = @('1196590')
            Files = @('re8.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('re8.exe','re_chunk_000.pak') }
            )
        }
        're-requiem-vr' = @{
            AppIds = @('3764200')
            Files = @('re9.exe','re_chunk_000.pak')
            FileSets = @(
                @{ Files = @('re9.exe','re_chunk_000.pak') }
            )
        }
        'shipbreaker-vr' = @{
            AppIds = @('1161580')
            Files = @('Shipbreaker.exe','Shipbreaker_Data\resources.assets')
            FileSets = @(
                @{ Files = @('Shipbreaker.exe','Shipbreaker_Data\resources.assets') }
            )
        }
        'skyrim-vr' = @{
            AppIds = @('611670')
            Files = @('SkyrimVR.exe','Data\Skyrim.esm')
            FileSets = @(
                @{ Files = @('SkyrimVR.exe','Data\Skyrim.esm') }
            )
        }
        'stanley-parable-vr' = @{
            AppIds = @('1703340')
            Files = @('The Stanley Parable Ultra Deluxe.exe','The Stanley Parable Ultra Deluxe_Data\resources.assets')
            FileSets = @(
                @{ Files = @('The Stanley Parable Ultra Deluxe.exe','The Stanley Parable Ultra Deluxe_Data\resources.assets') }
            )
        }
        'star-wars-x-wing-vr' = @{
            AppIds = @('354430')
            Files = @('classic/XWING.EXE|collectors_cd/BWING.EXE|remastered/XWING95.EXE|XWING.EXE|BWING.EXE|XWING95.EXE','classic/FLIGHT.OVL|collectors_cd/BFLIGHT.OVL|remastered/X-Wing Data/CP640/XWING12.LFD|FLIGHT.OVL|BFLIGHT.OVL|X-Wing Data/CP640/XWING12.LFD')
            FileSets = @(
                @{ Files = @('classic/XWING.EXE','classic/FLIGHT.OVL') }
                @{ Files = @('collectors_cd/BWING.EXE','collectors_cd/BFLIGHT.OVL') }
                @{ Files = @('remastered/XWING95.EXE','remastered/X-Wing Data/CP640/XWING12.LFD') }
                @{ Files = @('XWING.EXE','FLIGHT.OVL') }
                @{ Files = @('BWING.EXE','BFLIGHT.OVL') }
                @{ Files = @('XWING95.EXE','X-Wing Data/CP640/XWING12.LFD') }
            )
        }
        'iron-lung-vr' = @{
            InstallerFolders = @('IronLungVR')
            Files = @('Iron Lung VR.exe','Iron Lung VR_Data/level1','Iron Lung VR_Data/level2')
            FileSets = @(
                @{ Files = @('Iron Lung VR.exe','Iron Lung VR_Data/level1','Iron Lung VR_Data/level2') }
            )
        }
        'ring-racers-vr' = @{
            InstallerFolders = @('RingRacersVR')
            Files = @('data/maps.pk3','data/textures_OriginalZones.pk3','data/chars.pk3')
            FileSets = @(
                @{ Files = @('data/maps.pk3','data/textures_OriginalZones.pk3','data/chars.pk3') }
            )
        }
        'sonic-robo-blast-2-vr' = @{
            InstallerFolders = @('SonicRoboBlast2VR')
            Files = @('srb2.pk3','zones.pk3','characters.pk3')
            FileSets = @(
                @{ Files = @('srb2.pk3','zones.pk3','characters.pk3') }
            )
        }
        'the-dark-mod-vr' = @{
            InstallerFolders = @('TheDarkModVR')
            Files = @('tdm_base01.pk4','tdm_models01.pk4')
            FileSets = @(
                @{ Files = @('tdm_base01.pk4','tdm_models01.pk4') }
            )
        }
        'banjo-kazooie-vr' = @{
            InstallerFolders = @('BanjoKazooieVR')
            Files = @('bk.o2r')
            FileSets = @(
                @{ Files = @('bk.o2r'); Containers = @(@{ File = 'bk.o2r'; Format = 'ZIP'; Entries = @('assets/anim/ASSET_6A_MUMBO_SLEEP','assets/anim/ASSET_6B_MUMBO_WAKEUP') }) }
            )
        }
        'mario-kart-64-vr' = @{
            InstallerFolders = @('MarioKart64VR')
            Files = @('mk64.o2r')
            FileSets = @(
                @{ Files = @('mk64.o2r'); Containers = @(@{ File = 'mk64.o2r'; Format = 'ZIP'; Entries = @('models/ceremony_data/silver_trophy_dl','models/tracks/bowsers_castle/bowsers_castle_data/d_course_bowsers_castle_dl_0') }) }
            )
        }
        'i-can-gun-vr' = @{
            InstallerFolders = @('ICanGunVR')
            Files = @('ICG.exe','ICG_Data/globalgamemanagers','ICG_Data/level1')
            FileSets = @(
                @{ Files = @('ICG.exe','ICG_Data/globalgamemanagers','ICG_Data/level1') }
            )
        }
        'ashes-2063-vr' = @{
            InstallerFolders = @('Ashes2063VR')
            Files = @('Resources/Ashes2063Enriched2_23.pk3')
            FileSets = @(
                @{ Files = @('Resources/Ashes2063Enriched2_23.pk3'); Containers = @(@{ File = 'Resources/Ashes2063Enriched2_23.pk3'; Format = 'ZIP'; Entries = @('Actors/PLAYER/Tesla79.txt','maps/MAP01.wad','maps/MAP02.wad') }) }
            )
        }
        'total-chaos-vr' = @{
            InstallerFolders = @('TotalChaosVR')
            Files = @('gamedata/totalchaos.pk3')
            FileSets = @(
                @{ Files = @('gamedata/totalchaos.pk3'); Containers = @(@{ File = 'gamedata/totalchaos.pk3'; Format = 'ZIP'; Entries = @('MAPS/ARRIVAL.wad','MAPS/DECAY.wad') }) }
            )
        }
        'perfect-dark-vr' = @{
            InstallerFolders = @('PerfectDarkVR')
            Files = @('data/pd.ntsc-final.z64|data/pd.pal-final.z64|data/pd.jpn-final.z64')
            FileSets = @(
                @{ Files = @('data/pd.ntsc-final.z64|data/pd.pal-final.z64|data/pd.jpn-final.z64'); Containers = @(@{ File = 'data/pd.ntsc-final.z64|data/pd.pal-final.z64|data/pd.jpn-final.z64'; Format = 'N64'; Entries = @('title/Perfect Dark','cartridge/NPDE|cartridge/NPDP|cartridge/NPDJ') }) }
            )
        }
        'star-fox-64-vr' = @{
            InstallerFolders = @('StarFox64VR')
            Files = @('sf64.o2r')
            FileSets = @(
                @{ Files = @('sf64.o2r'); Containers = @(@{ File = 'sf64.o2r'; Format = 'ZIP'; Entries = @('ast_corneria/aCoWaterfallDL','ast_aquas/aAqBacoonHitbox') }) }
            )
        }
        'f-zero-x-vr' = @{
            InstallerFolders = @('FZeroXVR')
            Files = @('fzerox.o2r|assets/extracted/generic.o2r')
            FileSets = @(
                @{ Files = @('fzerox.o2r|assets/extracted/generic.o2r'); Containers = @(@{ File = 'fzerox.o2r|assets/extracted/generic.o2r'; Format = 'ZIP'; Entries = @('machine_models/D_9000000','machine_models/D_9000A08') }) }
            )
        }
        'ratchet-clank-vr' = @{
            InstallerFolders = @('RatchetVR')
            Files = @('RatchetVR.exe','MyProject3/Binaries/Win64/MyProject3-Win64-Shipping.exe','MyProject3/Content/Paks/MyProject3-WindowsNoEditor.pak')
            FileSets = @(
                @{ Files = @('RatchetVR.exe','MyProject3/Binaries/Win64/MyProject3-Win64-Shipping.exe','MyProject3/Content/Paks/MyProject3-WindowsNoEditor.pak') }
            )
        }
        'diddy-kong-racing-vr' = @{
            InstallerFolders = @('DiddyKongRacingVR')
            Files = @('GoldenBalloon.exe','baserom.us.v80.z64','baserom.pal.v80.z64')
            ConfiguredRoots = @(@{ Root = 'AppData'; File = 'mdkr64/mdkr64/mdkr64_app.ini'; Format = 'INI'; Section = ''; Key = 'rom_path'; ValueType = 'File'; Escape = 'Backslash' },@{ Root = 'Runtime'; File = 'mdkr64_app.ini'; Format = 'INI'; Section = ''; Key = 'rom_path'; ValueType = 'File'; Escape = 'Backslash' })
            FileSets = @(
                @{ Files = @(); Containers = @(@{ Directories = @('.','roms','data'); Patterns = @('*.z64','*.v64','*.n64'); Format = 'N64'; Entries = @('title/Diddy Kong Racing','cartridge/NDYE|cartridge/NDYP|cartridge/NDYJ') }) }
            )
        }
        'halo-ce-vr' = @{
            InstallerFolders = @('HaloCEVR')
            Files = @('halo.exe','maps/a10.map','maps/a30.map')
            FileSets = @(
                @{ Files = @('halo.exe','maps/a10.map','maps/a30.map') }
            )
        }
        'super-mario-64-vr' = @{
            InstallerFolders = @('SuperMario64VR')
            Files = @('sm64coopdx.exe','baserom.us.z64','baserom.z64')
            FileSets = @(
                @{ Files = @(); Containers = @(@{ Directories = @('.','roms','data'); Patterns = @('*.z64','*.v64','*.n64'); Format = 'N64'; Entries = @('title/SUPER MARIO 64','cartridge/NSME|cartridge/NSMP|cartridge/NSMJ') }) }
            )
        }
        'metroid-prime-vr' = @{
            InstallerFolders = @('MetroidPrimeVR')
            Files = @('ROM/Metroid Prime.iso','ROM/Metroid Prime.rvz')
            ConfiguredRoots = @(@{ Root = 'Runtime'; File = 'user/primedgun_launcher.ini'; Format = 'INI'; Section = 'General'; Key = 'selected_disc'; ValueType = 'File' },@{ Root = 'Runtime'; File = 'User/Config/Dolphin.ini'; Format = 'INI'; Section = 'General'; Key = 'ISOPath0' })
            FileSets = @(
                @{ Files = @(); Containers = @(@{ Directories = @('.','ROM','roms','game'); Patterns = @('*.iso','*.gcm','*.nkit','*.rvz','*.wia','*.ciso','*.wbfs','*.gcz'); Format = 'NINTENDO_DISC'; Entries = @('title/Metroid Prime','disc/GM8E01|disc/GM8P01|disc/GM8J01') }) }
            )
        }
        'dolphin-vr-redux' = @{ Kind = 'ExternalTool'; Files = @(); FileSets = @() }
        'rpcs3-vr' = @{ Kind = 'ExternalTool'; Files = @(); FileSets = @() }
        'uevr-deluxe' = @{ Kind = 'ExternalTool'; Files = @(); FileSets = @() }
        'uuvr-rai-pal' = @{ Kind = 'ExternalTool'; Files = @(); FileSets = @() }
        'star-fox-enhanced-vr' = @{
            InstallerFolders = @('StarFoxEnhancedVR')
            Files = @('Starfox-Assets.BIN')
            FileSets = @(
                @{ Files = @('Starfox-Assets.BIN'); Containers = @(@{ File = 'Starfox-Assets.BIN'; Format = 'STARFOX_BUNDLE'; Entries = @('original-rom','starfox-ex-rom') }) }
            )
        }
        'legend-of-zelda-ocarina-of-time-vr' = @{
            InstallerFolders = @('OcarinaOfTimeVR')
            Files = @('oot.otr|oot-mq.otr|oot.o2r|oot-mq.o2r')
            FileSets = @(
                @{ Files = @('oot.otr|oot-mq.otr'); Containers = @(@{ File = 'oot.otr|oot-mq.otr'; Format = 'MPQ'; Entries = @('objects/object_link_boy/gLinkAdultSkel','objects/object_link_child/gLinkChildSkel') }) }
                @{ Files = @('oot.o2r|oot-mq.o2r'); Containers = @(@{ File = 'oot.o2r|oot-mq.o2r'; Format = 'ZIP'; Entries = @('objects/object_link_boy/gLinkAdultSkel','objects/object_link_child/gLinkChildSkel') }) }
            )
        }
        'gran-turismo-2-pcvr' = @{
            InstallerFolders = @('GT2PCVR')
            Files = @('simulation/disc.raw2352')
            FileSets = @(
                @{ Files = @(); Containers = @(@{ Directories = @('.','simulation','arcade'); Patterns = @('*.bin','*.iso','*.raw2352'); Format = 'PSX_DISC'; Entries = @('file/GT2.VOL','file/GT2.OVL') }) }
            )
        }
        'silent-hill-vr' = @{
            InstallerFolders = @('SilentHillVR')
            Files = @('pc_port/build/gamedata/Silent Hill (USA).bin')
            FileSets = @(
                @{ Files = @(); Containers = @(@{ Directories = @('.','gamedata','pc_port/build/gamedata'); Patterns = @('*.bin','*.iso','*.raw2352'); Format = 'PSX_DISC'; Entries = @('file/SILENT','file/HILL') }) }
            )
        }
        'vivecraft' = @{
            InstallerFolders = @('Vivecraft')
            Files = @()
            FileSets = @(
                @{ Files = @(); Containers = @(@{ Directories = @('.'); ChildDirectories = @('versions'); Patterns = @('*.jar'); Format = 'ZIP'; Entries = @('assets/minecraft/textures/block/stone.png|assets/minecraft/textures/blocks/stone.png','assets/minecraft/textures/entity/creeper/creeper.png') }) }
            )
        }
        'breath-of-the-wild-vr' = @{
            InstallerFolders = @('BreathOfTheWildVR')
            Files = @()
            FileSets = @(
                @{ Files = @(); Containers = @(@{ Directories = @('.','game','games','roms'); Patterns = @('*.wud','*.wux'); Format = 'WIIU_DISC'; Entries = @('product/WUP-P-ALZE|product/WUP-P-ALZP|product/WUP-P-ALZJ','volume/WIIU-DISC') }) }
                @{ Files = @('code/U-King.rpx','content/Pack/Bootup.pack'); XmlValues = @(@{ File = 'code/app.xml'; XPath = '/app/title_id'; Values = @('00050000101c9300','00050000101c9400','00050000101c9500') }) }
            )
        }
        'legend-of-zelda-twilight-princess' = @{
            InstallerFolders = @('TwilightPrincessVR')
            Files = @()
            ConfiguredRoots = @(@{ Root = 'AppData'; File = 'TwilitRealm/Dusklight/config.json'; Format = 'JSON'; Key = 'backend.isoPath'; ValueType = 'File' })
            FileSets = @(
                @{ Files = @(); Containers = @(@{ Directories = @('.','roms','ROM','game'); Patterns = @('*.iso','*.gcm','*.nkit','*.rvz','*.wia','*.ciso','*.wbfs','*.gcz'); Format = 'NINTENDO_DISC'; Entries = @('disc/GZ2E01|disc/GZ2P01|disc/GZ2J01','system/gamecube') }) }
            )
        }
    }
}
