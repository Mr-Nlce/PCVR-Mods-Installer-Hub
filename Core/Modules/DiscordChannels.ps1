# ===============================================================
# Discord discussion and support channels
#
# This is the one maintenance surface for Discord links shown on game
# detail pages. Entries use the permanent CatalogIndex Id, never the title,
# Steam path, or array position. A game may have several records when
# separate VR mods have their own channels.
#
# RequiresJoin means that the Flat2VR server's Join Channels control (or
# server toggle) must be used before the linked area becomes visible.
# Download posts do not belong here; these links lead to discussion/info
# channels supplied for the corresponding games and mods.
# ===============================================================

$script:DiscordServerSpec = [ordered]@{
    Flat2VR = @{
        Name      = 'Flat2VR'
        InviteUrl = 'https://discord.gg/uAeQkYBM4n'
    }
    FarmerTrueVR = @{
        Name      = 'FarmerTrueVR'
        InviteUrl = 'https://discord.gg/G8zZBTGuhP'
    }
}

$script:DiscordChannelSpec = @(
    # Flat2VR discussion/support channels supplied for individual games.
    @{ Ids=@('muck-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1499941272771760239'; Label='Muck VR' }
    @{ Ids=@('silent-hill-3-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1539124350962114630'; Label='Silent Hill 3 VR' }
    @{ Ids=@('red-faction-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1539647804962771094'; Label='Red Faction VR' }
    @{ Ids=@('thehunter-call-of-the-wild-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1538534721414365274'; Label='theHunter VR' }
    @{ Ids=@('outlast-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1537851737728221284'; Label='Outlast VR' }
    @{ Ids=@('outward-de-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1107289188350574702'; Label='Outward VR' }
    @{ Ids=@('warhammer-40k-rogue-trader-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1526432666285510676'; Label='Rogue Trader VR' }
    @{ Ids=@('pokemon-gen-1-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1535704850090823690'; Label='Pokemon Dramatic Shape VR' }
    @{ Ids=@('sons-of-the-forest'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1472102733283725352'; Label='Sons of the Forest VR' }
    @{ Ids=@('forza-horizon-5-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1525532790408478902'; Label='Forza Horizon 5 VR' }
    @{ Ids=@('bioshock-remastered'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1530829951216128000'; Label='BioVRDev' }
    @{ Ids=@('f-e-a-r-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1530597650053726388'; Label='DR-89' }
    @{ Ids=@('sonic-robo-blast-2-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1527978192533721208'; Label='Sonic Robo Blast 2 VR' }
    @{ Ids=@('snowrunner-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1542980041061695598'; Label='SnowRunner VR' }
    @{ Ids=@('metroid-prime-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1517960537307087100'; Label='Metroid Prime VR' }
    @{ Ids=@('alien-isolation-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1363947657248378880'; Label='Alien Isolation VR' }
    @{ Ids=@('mass-effect-1-le-vr','mass-effect-2-le-vr','mass-effect-3-le-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1524781131939975291'; Label='Mass Effect Legendary Edition VR' }
    @{ Ids=@('shenmue-i-ii'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1534100594753540217'; Label='Shenmue I & II VR' }
    @{ Ids=@('star-wars-episode-i-racer'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1544020517009358888'; Label='Star Wars Episode I Racer VR' }
    @{ Ids=@('forza-horizon-6-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1509055901582233740'; Label='Forza Horizon 6 VR' }
    @{ Ids=@('black-mesa'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1539040989006532679'; Label='Black Mesa VR' }
    @{ Ids=@('borderlands-goty-enhanced'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1540481175251058800'; Label='Borderlands GOTY Enhanced VR' }
    @{ Ids=@('elden-ring-motion-controls'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1541200028498919474'; Label='Hotbite' }
    @{ Ids=@('legend-of-zelda-twilight-princess'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1538372373873688576'; Label='Twilight Princess VR' }
    @{ Ids=@('bioshock-remastered','bioshock-2-remastered','bioshock-infinite-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1531450321249767665'; Label='balouza' }
    @{ Ids=@('my-friendly-neighborhood-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1541878320675950592'; Label='My Friendly Neighborhood VR' }
    @{ Ids=@('f-e-a-r-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1534929606878953504'; Label='thefreemike' }
    @{ Ids=@('white-knuckle-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1543643530545860618'; Label='White Knuckle VR' }
    @{ Ids=@('dishonored-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1534840236415127713'; Label='Dishonored VR' }
    @{ Ids=@('legend-of-zelda-ocarina-of-time-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1530006561345503232'; Label='Ocarina of Time VR' }
    @{ Ids=@('silent-hill-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1542467982427693096'; Label='Silent Hill VR' }
    @{ Ids=@('tormented-souls-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1115608718835462245'; Label='Tormented Souls VR' }
    @{ Ids=@('singularity-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1535658310316068955'; Label='Singularity VR' }
    @{ Ids=@('diddy-kong-racing-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1539586547421151362'; Label='Diddy Kong Racing VR' }
    @{ Ids=@('penumbra-overture-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1540774759619629056'; Label='Penumbra Overture VR' }
    @{ Ids=@('gta-iv-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1531522874987515955'; Label='GTA IV VR' }
    @{ Ids=@('grand-theft-auto-v-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1545350924237668453'; Label='GTA V VR by DeployAbi' }
    @{ Ids=@('super-mario-64-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1527975455079010398'; Label='Super Mario 64 Coop VR' }
    @{ Ids=@('banjo-kazooie-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1533114243912564877'; Label='Banjo-Kazooie VR' }
    @{ Ids=@('garry-s-mod-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1255838995452002356'; Label="Garry's Mod VR" }
    @{ Ids=@('elden-ring-motion-controls'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1542483352068558888'; Label='Ilyamez' }
    @{ Ids=@('ultrakill-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1107290046664560832'; Label='ULTRAKILL VR' }
    @{ Ids=@('quake-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1543001517962043562'; Label='Team Beef port' }
    @{ Ids=@('virtua-cop-2-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1540815394850476232'; Label='Virtua Cop 2 VR' }
    @{ Ids=@('battlefield-1942-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1536768360707268628'; Label='Battlefield 1942 VR' }
    @{ Ids=@('rebel-galaxy-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1532145111486435500'; Label='Rebel Galaxy VR' }
    @{ Ids=@('outbound-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1528758034476564521'; Label='Outbound VR' }
    @{ Ids=@('art-of-rally-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1542927399409418280/1542927399409418280'; Label='Art of Rally VR' }
    @{ Ids=@('mario-kart-64-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1527976497682452480'; Label='Mario Kart 64 VR' }
    @{ Ids=@('f-zero-x-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1540018906981343372'; Label='F-Zero X VR' }
    @{ Ids=@('retrowave-2-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1541093763768782919'; Label='Retrowave 2 VR' }
    @{ Ids=@('road-to-vostok-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1491077636183556378'; Label='Road to Vostok VR' }
    @{ Ids=@('descenders-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1103720868183543911'; Label='Descenders VR' }
    @{ Ids=@('painkiller-black-edition'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1528869958266650634'; Label='Painkiller Black Edition VR' }
    @{ Ids=@('away-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1540002782797627392/1540002782797627392'; Label='AWAY VR' }
    @{ Ids=@('star-trucker-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1528826343838716007'; Label='Star Trucker VR' }
    @{ Ids=@('star-fox-64-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1527977588654477352'; Label='Star Fox 64 VR' }
    @{ Ids=@('selaco-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1285546972169769021'; Label='Selaco VR' }
    @{ Ids=@('ghost-recon-wildlands-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1536195845945303160'; Label='Ghost Recon Wildlands VR' }
    @{ Ids=@('halo-3-mcc-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1546190376405049415'; Label='Halo MCC VR' }
    @{ Ids=@('ring-racers-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1528689965897355335'; Label="Dr. Robotnik's Ring Racers VR" }
    @{ Ids=@('call-of-duty-4-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1532589749435502733'; Label='Call of Duty 4 VR' }
    @{ Ids=@('outlast-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1537923317858574366'; Label='Marauder' }
    @{ Ids=@('lunacid-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1301985284887547935'; Label='Lunacid VR' }
    @{ Ids=@('hexen-ii-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1475196426945298654'; Label='Hexen II VR' }
    @{ Ids=@('gta-vice-city-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1543693583696265236'; Label='GTA Vice City VR' }
    @{ Ids=@('dinkum-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1530706684094189608/1530706684094189608'; Label='Dinkum VR' }
    @{ Ids=@('mage-arena-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1530234827922608138/1530234827922608138'; Label='Mage Arena VR' }
    @{ Ids=@('hytale-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1522533413658169474'; Label='Hytale VR' }
    @{ Ids=@('r-e-p-o-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1435823786921300000'; Label='R.E.P.O. VR' }
    @{ Ids=@('nuclear-option-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1516789296802037911/1516789296802037911'; Label='Nuclear Option VR' }
    @{ Ids=@('the-witness'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1532163496899248198'; Label='The Witness VR' }
    @{ Ids=@('sin-episodes-emergence'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1546987501120651284'; Label='SiN Episodes VR' }
    @{ Ids=@('doom-2016-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1542807734456680528'; Label='DOOM (2016) VR' }
    @{ Ids=@('metal-gear-solid-v-the-phantom-pain-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1547585795395813618'; Label='Metal Gear Solid V VR' }
    @{ Ids=@('earth-defense-force-6-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1548208406408724510'; Label='EARTH DEFENSE FORCE 6 VR' }
    @{ Ids=@('titanfall-2-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1544402832093089833'; Label='Titanfall 2 VR' }
    @{ Ids=@('tribes-2-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1548700072697528461'; Label='Tribes 2 VR' }
    @{ Ids=@('mirrors-edge-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1535660675085631600'; Label="Mirror's Edge VR" }
    @{ Ids=@('thief-2014-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1550396410967490570'; Label='ThiefVR' }
    @{ Ids=@('oblivion-2006-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1547539304786436228'; Label='OBVR' }
    @{ Ids=@('kingdom-come-deliverance-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1547235772971749497'; Label='KCD1VR' }
    @{ Ids=@('deus-ex-human-revolution-directors-cut-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1548944616907087902'; Label='DeusExHRVR' }
    @{
        Ids=@('trackmania-nations-forever','trackmania-united-forever')
        Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1548223965460303892'; Label='TrackMania Forever OpenXR'
    }
    @{
        Ids=@('blood-vr','duke-nukem-3d-vr','nam-vr','powerslave-exhumed-vr','redneck-rampage-vr','shadow-warrior-vr','wwii-gi-vr')
        Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1547461710473072741'; Label='RazeXR PCVR'
    }

    # Flat2VR areas that have to be unlocked through Join Channels/toggle.
    @{ Ids=@('daggerfall-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1292258976062505052/1292570964374323220'; Label='Daggerfall VR'; RequiresJoin=$true }
    @{ Ids=@('deep-rock-galactic-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/981240725809287228/981560390586605640'; Label='Deep Rock Galactic VR'; RequiresJoin=$true }
    @{ Ids=@('skyrim-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1010914226107330600/1010915160480829491'; Label='Skyrim VR'; RequiresJoin=$true }
    @{ Ids=@('raft-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1009179539395575923/1009183283315216555'; Label='Raft VR'; RequiresJoin=$true }
    @{ Ids=@('life-is-strange-bts'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/981240631475187752/981566513985257492'; Label='Life is Strange: Before the Storm VR'; RequiresJoin=$true }
    @{ Ids=@('half-life-2-vr','hl2-vr-ep-one','hl2-vr-ep-two'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/981240567004557342/981564710468091944'; Label='Half-Life 2 VR and episodes'; RequiresJoin=$true }
    @{ Ids=@('kerbal-space-program'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1061330810915016714/1061331775848202401'; Label='Kerbal Space Program VR'; RequiresJoin=$true }
    @{ Ids=@('half-life-2-vr','hl2-vr-ep-one','hl2-vr-ep-two'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1165652366738079847/1373552599189422080'; Label='HL2 VR improvement mods'; RequiresJoin=$true }
    @{ Ids=@('subnautica-vr','subnautica-below-zero'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/978088247592890418/978088386252390440'; Label='Subnautica and Below Zero VR'; RequiresJoin=$true }
    @{ Ids=@('halo-ce-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1311395898147999805/1311397019750760478'; Label='Halo Combat Evolved VR'; RequiresJoin=$true }
    @{ Ids=@('valheim-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/978020535587987526/978021261202567168'; Label='Valheim VR'; RequiresJoin=$true }
    @{ Ids=@('risk-of-rain-2'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/978017782505545778/978018236576702494'; Label='Risk of Rain 2 VR'; RequiresJoin=$true }
    @{ Ids=@('gtfo-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/978019455449858149/978020092925345802'; Label='GTFO VR'; RequiresJoin=$true }
    @{ Ids=@('left-4-dead-2-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/980562263293448192/980563464537899138'; Label='Left 4 Dead 2 VR'; RequiresJoin=$true }
    @{ Ids=@('gunfire-reborn'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1041451569255809104/1041452240713555978'; Label='Gunfire Reborn VR'; RequiresJoin=$true }
    @{ Ids=@('breath-of-the-wild-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/978009041781551196/978009423404478565'; Label='Breath of the Wild VR'; RequiresJoin=$true }
    @{ Ids=@('slime-rancher-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1358516763104645293/1358518870561788064'; Label='Slime Rancher VR'; RequiresJoin=$true }
    @{ Ids=@('final-fantasy-xiv-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1038876000743862382/1038893143485063209'; Label='Final Fantasy XIV VR'; RequiresJoin=$true }
    @{ Ids=@('metal-hellsinger-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1066818316682936442/1066819881011531978'; Label='Metal Hellsinger VR'; RequiresJoin=$true }
    @{ Ids=@('bendy-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1060594834366279690/1060596229882523658'; Label='Bendy VR'; RequiresJoin=$true }
    @{ Ids=@('crysis-vr','far-cry-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1095014334553391184/1095015882285129728'; Label='Crysis and Far Cry VR'; RequiresJoin=$true }
    @{ Ids=@('7-days-to-die-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1100089669452038196/1100090578395463690'; Label='7 Days to Die VR'; RequiresJoin=$true }
    @{ Ids=@('amnesia-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1146447548245102652/1146450800118337576'; Label='Amnesia VR'; RequiresJoin=$true }
    @{ Ids=@('portal-2-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1152658951184334898/1152659332819853402'; Label='Portal 2 VR'; RequiresJoin=$true }
    @{ Ids=@('lethal-company-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1195797645713748059/1195798443608784908'; Label='Lethal Company VR'; RequiresJoin=$true }
    @{ Ids=@('content-warning-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1236717861653712896/1236719074449297429'; Label='Content Warning VR'; RequiresJoin=$true }
    @{ Ids=@('techtonica-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1218303876017426463/1218305404350758913'; Label='Techtonica VR'; RequiresJoin=$true }
    @{ Ids=@('world-of-warcraft-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1228183999650730065/1228193071804452938'; Label='World of Warcraft VR'; RequiresJoin=$true }

    # Regular Flat2VR channels supplied after the Join Channels group.
    @{ Ids=@('cyberpunk-2077'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1512549281825820672'; Label='Cyberpunk 2077 VR' }
    @{ Ids=@('witcher-3-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1527037966789251183'; Label='The Witcher 3 VR' }
    @{ Ids=@('how-to-fish-xr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1542977898967867519'; Label='How to Fish XR' }
    @{ Ids=@('elderborn-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1542935421649027152'; Label='ELDERBORN VR' }
    @{ Ids=@('gloomhaven-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1549192763680235590'; Label='Gloomhaven VR' }
    @{ Ids=@('prey-2006-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1549901041384947772'; Label='Prey (2006) VR' }
    @{ Ids=@('arma-3-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1536545209897193584'; Label='Arma 3 VR' }
    @{ Ids=@('escape-from-tarkov-vr'); Server='Flat2VR'; Url='https://discord.com/channels/747967102895390741/1234961174429306890'; Label='Tarkov VR' }
)

function global:Initialize-DiscordChannels {
    param([object[]]$Games)

    $errors = [System.Collections.Generic.List[string]]::new()
    $byId = @{}
    foreach ($game in @($Games)) {
        $id = [string]$game.Id
        if (-not $id) { continue }
        if ($byId.ContainsKey($id)) {
            $errors.Add("Duplicate catalog Id while applying Discord channels: $id")
        } else {
            $byId[$id] = $game
        }
    }

    $pending = [System.Collections.Generic.List[object]]::new()
    foreach ($record in @($script:DiscordChannelSpec)) { $pending.Add($record) }

    # Every RaYRoD title shares the Multiverse VR Hub support channel.
    foreach ($game in @($Games | Where-Object { [string]$_.Author -match '(?i)rayrod' })) {
        $pending.Add(@{
            Ids=@([string]$game.Id); Server='Flat2VR'
            Url='https://discord.com/channels/747967102895390741/1537574184186814564'
            Label='Multiverse VR Hub'
        })
    }

    # All Luke Ross game pages share the opt-in REAL VR channel.
    foreach ($game in @($Games | Where-Object { [string]$_.Author -match '(?i)luke ross' })) {
        $pending.Add(@{
            Ids=@([string]$game.Id); Server='Flat2VR'
            Url='https://discord.com/channels/747967102895390741/978088841145626674/978162091338919989'
            Label='Luke Ross REAL VR mods'; RequiresJoin=$true
        })
    }

    # Praydog REFramework games, including the external Resident Evil pages.
    foreach ($game in @($Games | Where-Object {
        ([string]$_.Bat -like 'REFrameworkVR*') -or
        (([string]$_.Author -match '(?i)praydog') -and ([string]$_.InfoUrl -match '(?i)biohazardvr\.com'))
    })) {
        $pending.Add(@{
            Ids=@([string]$game.Id); Server='Flat2VR'
            Url='https://discord.com/channels/747967102895390741/978021664975630426/978022091381170256'
            Label='Praydog REFramework VR'; RequiresJoin=$true
        })
    }

    # Raicuparta's games share one opt-in mod area.
    foreach ($game in @($Games | Where-Object { [string]$_.Author -match '(?i)raicuparta' })) {
        $pending.Add(@{
            Ids=@([string]$game.Id); Server='Flat2VR'
            Url='https://discord.com/channels/747967102895390741/981570202242285579/981774961666568202'
            Label='Raicuparta mods'; RequiresJoin=$true
        })
    }

    # mutars' AnvilEngine and Starfield mods share one opt-in area.
    foreach ($game in @($Games | Where-Object { [string]$_.Author -match '(?i)mutars' })) {
        $pending.Add(@{
            Ids=@([string]$game.Id); Server='Flat2VR'
            Url='https://discord.com/channels/747967102895390741/1294031824473034762/1294033689956581467'
            Label='mutars VR mods'; RequiresJoin=$true
        })
    }

    # FarmerTrueVR/Astienth pages already carry their exact channel URL in
    # InfoUrl. Reuse only those channel URLs; never turn a GitHub/download
    # address into an invented Discord destination.
    foreach ($game in @($Games | Where-Object {
        ([string]$_.Author -match '(?i)astien') -and
        ([string]$_.InfoUrl -match '^https://discord\.com/channels/1001138422972432597/')
    })) {
        $pending.Add(@{
            Ids=@([string]$game.Id); Server='FarmerTrueVR'
            Url=[string]$game.InfoUrl; Label=[string]$game.Title
        })
    }

    $linksById = @{}
    foreach ($record in @($pending)) {
        $serverKey = [string]$record.Server
        if (-not $script:DiscordServerSpec.Contains($serverKey)) {
            $errors.Add("Unknown Discord server key: $serverKey")
            continue
        }
        $url = [string]$record.Url
        if ($url -notmatch '^https://discord\.com/channels/\d+/\d+(?:/\d+)?$') {
            $errors.Add("Invalid Discord channel URL: $url")
            continue
        }
        foreach ($id in @($record.Ids)) {
            $id = [string]$id
            if (-not $byId.ContainsKey($id)) {
                $errors.Add("Discord channel references unknown catalog Id: $id")
                continue
            }
            if (-not $linksById.ContainsKey($id)) {
                $linksById[$id] = [System.Collections.Generic.List[object]]::new()
            }
            $duplicate = @($linksById[$id] | Where-Object {
                ([string]$_.Server -ceq $serverKey) -and ([string]$_.Url -ceq $url)
            }).Count -gt 0
            if (-not $duplicate) {
                $linksById[$id].Add([pscustomobject]@{
                    Server       = $serverKey
                    ServerName   = [string]$script:DiscordServerSpec[$serverKey].Name
                    InviteUrl    = [string]$script:DiscordServerSpec[$serverKey].InviteUrl
                    Url          = $url
                    Label        = [string]$record.Label
                    RequiresJoin = [bool]$record.RequiresJoin
                })
            }
        }
    }

    foreach ($id in @($linksById.Keys)) {
        $byId[$id]['DiscordLinks'] = @($linksById[$id])
    }
    $global:DiscordChannelErrors = @($errors)
    return ($errors.Count -eq 0)
}

function global:Get-GameDiscordSectionText {
    param($Game)

    # PowerShell's @($null) has Count 1. Filter missing/incomplete records
    # before testing Count, otherwise a game with no Discord mapping renders
    # an empty box (blank server, invite and URL).
    $links = @($Game.DiscordLinks | Where-Object {
        $_ -and ([string]$_.Server) -and ([string]$_.InviteUrl) -and ([string]$_.Url)
    })
    if ($links.Count -eq 0) { return $null }

    $lines = [System.Collections.Generic.List[string]]::new()
    $serverOrder = @($links | ForEach-Object { [string]$_.Server } | Select-Object -Unique)
    foreach ($serverKey in $serverOrder) {
        $serverLinks = @($links | Where-Object { [string]$_.Server -ceq $serverKey })
        if ($serverLinks.Count -eq 0) { continue }
        $serverName = [string]$serverLinks[0].ServerName
        $inviteUrl = [string]$serverLinks[0].InviteUrl

        if ($lines.Count -gt 0) { $lines.Add('') }
        if ($serverKey -eq 'FarmerTrueVR') {
            $lines.Add('Joining the **FarmerTrueVR Discord** is required.')
            $lines.Add("Join the server: $inviteUrl")
            $lines.Add('You can find the VR mod channel here:')
        } elseif (@($serverLinks | Where-Object RequiresJoin).Count -gt 0) {
            $lines.Add("Join the **$serverName Discord**: $inviteUrl")
            $lines.Add('In Discord, use **Join Channels** (or the server toggle) to unlock this area:')
        } else {
            $lines.Add('**Discord discussion and support channel**')
            $lines.Add("Join the $serverName Discord: $inviteUrl")
        }

        foreach ($link in $serverLinks) {
            $label = [string]$link.Label
            if (-not $label) { $label = [string]$Game.Title }
            $lines.Add("- **$label**: $([string]$link.Url)")
        }
    }
    return ($lines -join "`n")
}

$__discordGames = @($ownGames) + @($ownGamesGP) + @($externalGames)
$__discordChannelResult = Initialize-DiscordChannels -Games $__discordGames
Remove-Variable __discordGames -ErrorAction SilentlyContinue
