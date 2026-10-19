# ============================================================
# BannerFxExtra.ps1 - 95 new banner effects for the featured banners
# (ListBanner, LibBanner, OvBanner), each mapped to the catalog games
# it fits. Round 1: 55 effects, round 2: 40 more (marked below).
#
# BANNER SIZE: every effect is built for the real banner height
# (ListBanner S/M/L = 140/156/174 px, OvBanner as laid out) and is
# rebuilt automatically when that height changes, e.g. on an S/M/L
# switch. Width changes only re-position, no rebuild.
#
# HOW IT PLUGS IN (self-contained, one line in the module list):
#   - add "BannerFxExtra.ps1" to the module list in VRModHub.ps1, AFTER
#     "BannerGlass.ps1" (it needs Add-BannerEffect, Get-BannerFxFor and
#     Set-BannerEffect, which Window.ps1 loads).
#   - Add-BannerEffect is wrapped: the new effect names below are drawn
#     here, every other name goes to the original function unchanged.
#   - The existing featured-only Get-BannerFxFor path picks fitting round 2
#     alternatives 30% of the time. Round 1 keeps its earlier 40% chance.
#   - None of the new names is added to $global:BannerFxPool. Games that
#     are not in any list below keep the normal rotation only.
#   - FeaturedOnly: on any other banner (e.g. the detail-page side bands)
#     a new name is replaced by its existing fallback effect.
#   - With BannerGlass "Glow" the particle-type new effects are added to
#     $global:BannerGlassParticleFx, so they get lifted above the art and
#     get the neon glow like the existing particle effects.
#   - To remove: delete this file and its module-list line.
#
# CHECK ON WINDOWS (builds every effect once into a test banner and
# reports failures):
#   powershell -STA -NoProfile -Command ". '.\Core\Modules\BannerFxExtra.ps1'; Test-BannerFxExtra"
#
# EFFECTS AND THEIR GAMES (exact catalog titles; checked by BannerFxExtra.Tests.ps1):
#
#   fireflies    Fireflies (17)
#       Stardew Valley VR; Valheim VR; Firewatch VR; Witcher 3 VR; Skyrim VR; Ghost of Tsushima VR;
#       Outward DE VR; Dredge VR; Hollow Knight VR; Driftwood VR; Muck VR; Dinkum VR;
#       Kingdom Come: Deliverance VR; Kingdom Come: Deliverance II VR; Red Dead Redemption VR;
#       Legend of Zelda: Twilight Princess; Breath of the Wild VR
#   leaves       Autumn leaves (14)
#       Firewatch VR; Kingdom Come: Deliverance VR; Kingdom Come: Deliverance II VR; Witcher 3 VR;
#       Gothic II VR; Red Dead Redemption VR; theHunter: Call of the Wild VR; Far Cry 5 VR;
#       Days Gone VR; Life is Strange: BtS; Sons of the Forest; Assassin's Creed Valhalla VR;
#       Oblivion (2006); Big Walk VR
#   petals       Cherry blossoms (9)
#       Ghost of Tsushima VR; Kunitsu-Gami: Path of the Goddess VR; Onimusha 2 VR;
#       Ghostwire: Tokyo VR; Judgment VR; Shenmue I & II; Forza Horizon 6 VR;
#       Little Witch Nobeta VR; Street Fighter 6 VR
#   flowerwind   Flowers in the wind (10)
#       Flower VR; Breath of the Wild VR; Legend of Zelda: Ocarina of Time VR; Tinykin VR;
#       A Kingdom for Keflings VR; Alba VR; Grounded VR; Yooka-Laylee VR; Paperklay VR;
#       Pokemon Dramatic Shape VR
#   lightning    Lightning (16)
#       Quake VR; Quake 2 VR; Hexen VR; Hexen II VR; Heretic VR; Painkiller Black Edition;
#       Painkiller: Overdose VR; Mage Arena VR; Warhammer 40K: Darktide VR;
#       Warhammer 40K: Rogue Trader VR; Dark Souls III VR; Elden Ring; Elden Ring VR;
#       Titanfall 2 VR; Singularity VR; Unreal Revived
#   ash          Ash and embers (17)
#       Dark Souls Remastered; Dark Souls II VR; Dark Souls II: Scholar; Dark Souls III VR;
#       Elden Ring; Elden Ring VR; DOOM (2016) VR; Doom Eternal VR; DOOM Eternal VR - Motion;
#       Diablo II: Resurrected; Blade of Darkness VR; Lunacid VR; Total Chaos VR;
#       Metal: Hellsinger VR; ELDERBORN VR; Dragon's Dogma 2 VR; Devil May Cry 5 VR
#   fog          Drifting fog (19)
#       Silent Hill VR; Silent Hill 3 VR; Amnesia VR; Outlast VR; Outlast 2 VR;
#       Penumbra: Overture VR; Penumbra: Black Plague VR; Penumbra: Requiem VR; SOMA VR;
#       Tormented Souls VR; RE Village VR; RE Requiem VR; Alien: Isolation VR; The Dark Mod VR;
#       Thief (2014) VR; Unmourned VR; Hypogea VR; Paranoia Place VR; Idols of Ash VR
#   flashlight   Flashlight (17)
#       Outlast VR; Outlast 2 VR; Lethal Company VR; Content Warning VR; R.E.P.O. VR; GTFO VR;
#       Alien: Isolation VR; Resident Evil 7 VR; Resident Evil 2R VR; Resident Evil 3R VR;
#       Moros Protocol VR; Doom 3 BFG VR; Iron Lung VR; Amnesia VR; F.E.A.R. VR; Paranoia Place VR;
#       Selaco VR
#   tracers      Tracer fire (15)
#       Call of Duty 4 VR; Call of Duty: World at War VR; Battlefield 1942 VR; Arma 3 VR; NAM VR;
#       World War II GI VR; Escape from Tarkov VR; Ready Or Not VR; Ghost Recon Wildlands VR;
#       EARTH DEFENSE FORCE 6 VR; Crysis VR; Road to Vostok VR; Nuclear Option VR;
#       C&C Generals: Zero Hour; Metal Gear Solid V: The Phantom Pain VR
#   flak         Distant explosions (10)
#       Battlefield 1942 VR; Call of Duty: World at War VR; World War II GI VR; NAM VR; Arma 3 VR;
#       C&C Generals: Zero Hour; EARTH DEFENSE FORCE 6 VR; Nuclear Option VR; Red Faction VR;
#       Teardown VR
#   pixels       8-bit pixels (29)
#       Doom VR; Doom 2 VR; Wolfenstein 3D VR; Duke Nukem 3D VR; Heretic VR; Hexen VR; Blood VR;
#       Shadow Warrior VR; Redneck Rampage VR; PowerSlave / Exhumed VR; Strife VR;
#       Dusk HD (DLC) VR; ULTRAKILL VR; Quake VR; Super Mario 64 VR; Mario Kart 64 VR;
#       Banjo-Kazooie VR; GoldenEye 007 VR; Perfect Dark VR; Star Fox 64 VR; Diddy Kong Racing VR;
#       F-Zero X VR; Turok VR; Sonic Robo Blast 2 VR; Ring Racers VR; Daggerfall VR; Hytale VR;
#       Vivecraft; Echo Generation 2 VR
#   glitch       CRT and glitch (15)
#       Cyberpunk 2077; Cruelty Squad VR; Watch Dogs VR; Watch Dogs 2 VR; Watch Dogs Legion VR;
#       Deus Ex: Human Revolution - DC; Retrowave 2 VR; Cloudpunk VR; Cloudpunk: City of Ghosts VR;
#       Neon White VR; MiSide VR; Moros Protocol VR; Stanley Parable VR; Iron Lung VR;
#       Atomic Heart VR
#   neoncity     Neon city lights (14)
#       Cyberpunk 2077; Cloudpunk VR; Cloudpunk: City of Ghosts VR; Ghostwire: Tokyo VR;
#       Judgment VR; Bomb Rush Cyberfunk; Watch Dogs Legion VR; GTA Vice City VR;
#       Saints Row: The Third VR; Retrowave 2 VR; Grand Theft Auto V VR; GTA IV VR; Neon White VR;
#       Sayonara Wild Hearts
#   raindrops    Rain on glass (12)
#       Max Payne 2 VR; Cyberpunk 2077; Cloudpunk VR; Life is Strange: BtS; Days Gone VR;
#       Death Stranding VR; Silent Hill VR; F.E.A.R. VR; Watch Dogs VR; GTA IV VR;
#       Road to Vostok VR; Driftwood VR
#   lighttrails  Light trails (21)
#       Forza Horizon 5 VR; Forza Horizon 6 VR; Gran Turismo 2 PCVR; Horizon Chase Turbo;
#       TrackMania Nations Forever; TrackMania United Forever; Circuit Superstars VR;
#       New Star GP VR; Sunrise GP VR; Retrowave 2 VR; Star Racer VR; F-Zero X VR;
#       Star Wars Episode I Racer; Ring Racers VR; Mario Kart 64 VR; Mario Kart Wii VR;
#       Diddy Kong Racing VR; Moto Rush Reborn VR; Road Redemption VR; Grand Theft Auto V VR;
#       Decimate Drive VR
#   dust         Dust and gravel (13)
#       Richard Burns Rally VR; Art of Rally VR; SnowRunner VR; Descenders VR; StreetDog BMX VR;
#       Red Dead Redemption VR; Death Stranding VR; Road Redemption VR; Moto Rush Reborn VR;
#       Days Gone VR; Fallout 4 VR; Far Cry 6 VR; Metal Gear Solid V: The Phantom Pain VR
#   radiation    Radiation (12)
#       Fallout 4 VR; Anomaly VR; Anomaly GAMMA; Ashes 2063 VR; Road to Vostok VR;
#       7 Days to Die VR; Atomic Heart VR; Escape from Tarkov VR; Project Zomboid VR;
#       Black Mesa VR; Black Mesa Source VR; Half-Life VR
#   magic        Rune circle (23)
#       Hogwarts Legacy VR; Mage Arena VR; Little Witch Nobeta VR; Skyrim VR; Oblivion (2006);
#       Morrowind VR; Witcher 3 VR; Diablo II: Resurrected; Daggerfall VR; Arx Fatalis VR;
#       Gothic II VR; Final Fantasy XIV VR; Pathfinder: Kingmaker; Gloomhaven VR;
#       World of Warcraft VR; Dragon's Dogma 2 VR; Hexen VR; Hexen II VR;
#       Kunitsu-Gami: Path of the Goddess VR; Elden Ring VR; FF VII Remake VR; FF VII Rebirth VR;
#       Mirage Feathers VR
#   wisps        Ghost wisps (13)
#       Ghostwire: Tokyo VR; Hollow Knight VR; Hollow Knight Silksong; Dark Souls Remastered;
#       Lunacid VR; Ghosts n Goblins Resurrection VR; Idols of Ash VR; Unmourned VR;
#       Death Stranding VR; Paranoia Place VR; Silent Hill 3 VR; Onimusha 2 VR;
#       Blade of Darkness VR
#   confetti     Confetti (13)
#       Trombone Champ VR; Stanley Parable VR; Garry's Mod VR; R.E.P.O. VR; PEAK VR;
#       Content Warning VR; Tinykin VR; A Kingdom for Keflings VR; Mario Kart Wii VR;
#       Super Mario 3D World VR; Big Walk VR; Slyders VR; High Entropy: Challenges VR
#   birds        Bird flock (14)
#       Red Dead Redemption VR; Witcher 3 VR; Assassin's Creed Mirage VR;
#       Assassin's Creed Odyssey VR; Assassin's Creed Valhalla VR; Far Cry Primal VR;
#       Ghost of Tsushima VR; Kingdom Come: Deliverance VR; Kingdom Come: Deliverance II VR;
#       Days Gone VR; Mount & Blade II: Bannerlord VR; Horizon Zero Dawn VR; Firewatch VR;
#       theHunter: Call of the Wild VR
#   blizzard     Blizzard (11)
#       Skyrim VR; Far Cry 4 VR; SnowRunner VR; Subnautica: Below Zero; Death Stranding VR;
#       Valheim VR; theHunter: Call of the Wild VR; Dark Souls III VR; Witcher 3 VR; PEAK VR;
#       White Knuckle VR
#   frost        Frost crystals (6)
#       Skyrim VR; Subnautica: Below Zero; Far Cry 4 VR; SnowRunner VR; Valheim VR; PEAK VR
#   sandwind     Drifting sand (11)
#       Journey VR; Assassin's Creed Mirage VR; PowerSlave / Exhumed VR;
#       Indiana Jones: Great Circle VR; Uncharted: Legacy of Thieves VR; Tomb Raider 1 VR;
#       Star Wars Outlaws VR; Metal Gear Solid V: The Phantom Pain VR; Red Dead Redemption VR;
#       Borderlands GOTY Enhanced; Risk of Rain 2
#   blooddrips   Blood drips (19)
#       Blood VR; Painkiller Black Edition; Painkiller: Overdose VR; Killing Floor 2 VR;
#       Left 4 Dead 2 VR; DOOM (2016) VR; Doom Eternal VR; ULTRAKILL VR; Dusk HD (DLC) VR;
#       House of the Dead Remake VR; House of the Dead 2 Remake VR; The House of the Dead 2;
#       Resident Evil 2R VR; Resident Evil 4R VR; Dino Trauma VR; Cruelty Squad VR;
#       Shadow Warrior VR; Devil May Cry 5 VR; Total Chaos VR
#   caustics     Underwater caustics (9)
#       Subnautica VR; Subnautica: Below Zero; Another Crab's Treasure; BioShock Remastered;
#       BioShock 2 Remastered; Raft VR; How to Fish XR; Dredge VR; SOMA VR
#   fish         Fish school (8)
#       Subnautica VR; Subnautica: Below Zero; Dredge VR; How to Fish XR; Another Crab's Treasure;
#       Raft VR; Stardew Valley VR; BioShock 2 Remastered
#   orbits       Planet orbits (13)
#       Outer Wilds VR; Kerbal Space Program; Starfield VR; X4: Foundations VR; Rebel Galaxy VR;
#       Star Trucker VR; Mass Effect 1 LE VR; Mass Effect 2 LE VR; Mass Effect 3 LE VR;
#       Freespace 2 VR; Star Wars: X-Wing VR; Rogue Flight VR; Astrodogs VR
#   lasers       Laser fire (23)
#       Star Wars: X-Wing VR; Star Wars Outlaws VR; Jedi Knight: Jedi Outcast VR;
#       Jedi Knight: Jedi Academy VR; Star Fox 64 VR; Star Fox Enhanced PCVR; Rebel Galaxy VR;
#       Freespace 2 VR; X4: Foundations VR; Descent VR; Descent 2 VR; Rogue Flight VR; Halo CE VR;
#       Halo Master Chief Collection VR; Perfect Dark VR; Tribes 2 VR; Quake 3 VR; Unreal Revived;
#       Astrodogs VR; Panzer Dragoon Remake; Metroid Prime VR; Ratchet & Clank VR; High on Life VR
#   scan         Hologram scan (13)
#       Horizon Zero Dawn VR; Horizon Zero Dawn Remastered VR; Horizon Forbidden West VR;
#       Deus Ex: Human Revolution - DC; Watch Dogs 2 VR; Metroid Prime VR; Pragmata VR; Crysis VR;
#       Mass Effect 1 LE VR; Ghost Recon Wildlands VR; Atomic Heart VR;
#       Mega Man Star Force Legacy VR; Death Stranding VR
#   biolum       Bioluminescence (8)
#       Avatar: Frontiers of Pandora VR; Subnautica VR; Hollow Knight VR; Hollow Knight Silksong;
#       Grounded VR; Deep Rock Galactic VR; Lunistice VR; Mirage Feathers VR
#   hearts       Hearts (6)
#       MiSide VR; Stardew Valley VR; Life is Strange: BtS; Slime Rancher VR; Dinkum VR;
#       Tinykin VR
#   notes        Music notes (7)
#       Trombone Champ VR; Metal: Hellsinger VR; Sayonara Wild Hearts; Banjo-Kazooie VR;
#       Bomb Rush Cyberfunk; Echo Generation 2 VR; Retrowave 2 VR
#   bullettime   Bullet time (9)
#       Max Payne 2 VR; F.E.A.R. VR; Receiver VR; Receiver 2 VR; I Can Gun VR; Ready Or Not VR;
#       Neon White VR; Titanfall 2 VR; Virtua Cop 2 VR
#   void         Void tendrils (9)
#       Dishonored VR; Thief (2014) VR; The Dark Mod VR; Singularity VR; Prey (2006) VR;
#       BioShock Infinite VR; SOMA VR; Warhammer 40K: Darktide VR; Warhammer 40K: Rogue Trader VR
#   portals      Portal pair (3)
#       Portal 2 VR; Portal 2: Community Edition VR; Prey (2006) VR
#   teleport     Teleport vortex (6)
#       Half-Life VR; Black Mesa VR; Black Mesa Source VR; Half-Life 2 VR; HL2 VR Ep. One;
#       HL2 VR Ep. Two
#   webs         Spider webs (6)
#       Spider-Man Remastered VR; Spiderman Remastered; Spiderman 2 VR; Spiderman Miles Morales VR;
#       Grounded VR; Hollow Knight Silksong
#   coins        Gold coins (10)
#       Super Mario 3D World VR; Super Mario 64 VR; Mario Kart 64 VR; Mario Kart Wii VR;
#       Yooka-Laylee VR; Diddy Kong Racing VR; Gunfire Reborn; Borderlands GOTY Enhanced;
#       Risk of Rain 2; Lunistice VR
#   rings        Gold rings (3)
#       Sonic P-06 VR; Sonic Robo Blast 2 VR; Ring Racers VR
#   bolts        Bolts and nuts (5)
#       Ratchet & Clank VR; Scrap Mechanic VR; Shipbreaker VR; Techtonica VR; Teardown VR
#   gems         Gems (8)
#       Deep Rock Galactic VR; Vivecraft; Hytale VR; Techtonica VR; Muck VR; Dinkum VR;
#       Diablo II: Resurrected; Borderlands GOTY Enhanced
#   inkdrips     Ink drips (2)
#       Bendy VR; Mouse P.I. For Hire VR
#   halftone     Comic halftone (4)
#       XIII Remake VR; Borderlands GOTY Enhanced; Mouse P.I. For Hire VR; Bomb Rush Cyberfunk
#   graffiti     Paint splats (6)
#       Bomb Rush Cyberfunk; Skate Story VR; StreetDog BMX VR; Sayonara Wild Hearts; Paperklay VR;
#       Saints Row: The Third VR
#   waterspray   Water jet (2)
#       PowerWash Simulator VR; PowerWash Simulator 2 VR
#   clouds       Sea of clouds (8)
#       BioShock Infinite VR; Panzer Dragoon Remake; Nuclear Option VR; Rogue Flight VR;
#       Mirage Feathers VR; PEAK VR; Big Walk VR; Journey VR
#   eyes         Eyes in the dark (9)
#       Outlast VR; Amnesia VR; Lethal Company VR; Paranoia Place VR; My Friendly Neighborhood VR;
#       Iron Lung VR; Sons of the Forest; Stray VR; Bendy VR
#   steam        Steam bursts (8)
#       BioShock Remastered; BioShock 2 Remastered; BioShock Infinite VR; Dishonored VR;
#       Atomic Heart VR; Techtonica VR; Stray VR; Half-Life 2 VR
#   papers       Flying papers (5)
#       Apollo Justice: Ace Attorney Trilogy VR; Stanley Parable VR; Judgment VR;
#       Mouse P.I. For Hire VR; Life is Strange: BtS
#   starburst    Meteor shower (11)
#       Outer Wilds VR; Journey VR; Starfield VR; No One Lives Forever VR;
#       No One Lives Forever 2 VR; Kerbal Space Program; Sayonara Wild Hearts;
#       Final Fantasy XIV VR; FF VII Remake VR; FF VII Rebirth VR; The Witness
#   lensflare    Lens flare (9)
#       Mirror's Edge VR; Far Cry VR; Far Cry New Dawn VR; AWAY VR; Outbound VR;
#       Forza Horizon 5 VR; Far Cry 6 VR; GTA Vice City VR; Uncharted: Legacy of Thieves VR
#   tracker      Motion tracker (5)
#       Aliens versus Predator VR; Alien: Isolation VR; SiN Episodes: Emergence; GTFO VR;
#       Iron Lung VR
#   slashes      Blade slashes (10)
#       Monster Hunter Rise VR; Monster Hunter Stories 3 VR; Monster Hunter Wilds;
#       Devil May Cry 5 VR; Onimusha 2 VR; Ghost of Tsushima VR; Street Fighter 6 VR;
#       Dark Souls III VR; Blade of Darkness VR; Jedi Knight: Jedi Academy VR
#   spores       Spores in light (10)
#       TLOU Part I VR; TLOU Part II VR; Days Gone VR; 7 Days to Die VR; Project Zomboid VR;
#       Far Cry New Dawn VR; Sons of the Forest; Grounded VR; Indiana Jones: Great Circle VR;
#       The Witness
#
#   --- round 2 ---
#   aurora       Northern lights (12)
#       Skyrim VR; Valheim VR; Far Cry 4 VR; Subnautica: Below Zero; SnowRunner VR;
#       theHunter: Call of the Wild VR; Outer Wilds VR; Witcher 3 VR; Death Stranding VR;
#       Star Trucker VR; PEAK VR; Assassin's Creed Valhalla VR
#   grindsparks  Grinder sparks (13)
#       DOOM (2016) VR; Doom Eternal VR; Titanfall 2 VR; Teardown VR; Shipbreaker VR;
#       Red Faction VR; Scrap Mechanic VR; Cyberpunk 2077; Atomic Heart VR; Ratchet & Clank VR;
#       Techtonica VR; Deep Rock Galactic VR; Borderlands GOTY Enhanced
#   shieldhit    Shield impacts (12)
#       Halo CE VR; Halo Master Chief Collection VR; Crysis VR; Mass Effect 1 LE VR;
#       Mass Effect 2 LE VR; Mass Effect 3 LE VR; Titanfall 2 VR; Tribes 2 VR;
#       Star Wars: X-Wing VR; Freespace 2 VR; EARTH DEFENSE FORCE 6 VR; Warhammer 40K: Darktide VR
#   laserdot     Laser sights (14)
#       Ready Or Not VR; Escape from Tarkov VR; Arma 3 VR; Ghost Recon Wildlands VR;
#       Metal Gear Solid V: The Phantom Pain VR; GoldenEye 007 VR; Perfect Dark VR;
#       Deus Ex: Human Revolution - DC; Watch Dogs VR; Crysis VR; Max Payne 2 VR;
#       No One Lives Forever VR; No One Lives Forever 2 VR; Road to Vostok VR
#   ecg          Heartbeat monitor (15)
#       Outlast VR; Outlast 2 VR; Resident Evil 7 VR; Resident Evil 2R VR; Resident Evil 3R VR;
#       Resident Evil 4R VR; RE Village VR; RE Requiem VR; Amnesia VR; SOMA VR;
#       Alien: Isolation VR; Iron Lung VR; Lethal Company VR; Death Stranding VR; Silent Hill VR
#   hud          Visor HUD (16)
#       Titanfall 2 VR; Crysis VR; Halo CE VR; Halo Master Chief Collection VR; Metroid Prime VR;
#       Deus Ex: Human Revolution - DC; Nuclear Option VR; X4: Foundations VR; Starfield VR;
#       Mass Effect 1 LE VR; Cyberpunk 2077; Watch Dogs 2 VR; Ghost Recon Wildlands VR;
#       Metal Gear Solid V: The Phantom Pain VR; Star Wars: X-Wing VR; Rogue Flight VR
#   cracks       Glowing cracks (14)
#       Doom Eternal VR; DOOM Eternal VR - Motion; Diablo II: Resurrected; Dark Souls III VR;
#       Elden Ring; Elden Ring VR; Painkiller Black Edition; Painkiller: Overdose VR;
#       Metal: Hellsinger VR; Devil May Cry 5 VR; Blade of Darkness VR; Lunacid VR; Hexen VR;
#       Dark Souls II VR
#   candles      Candlelight (18)
#       Amnesia VR; Penumbra: Overture VR; Penumbra: Black Plague VR; Penumbra: Requiem VR;
#       Hogwarts Legacy VR; Thief (2014) VR; The Dark Mod VR; Dishonored VR; Dark Souls Remastered;
#       Arx Fatalis VR; Gothic II VR; Kingdom Come: Deliverance VR;
#       Kingdom Come: Deliverance II VR; Oblivion (2006); Morrowind VR; Daggerfall VR;
#       Tormented Souls VR; Little Witch Nobeta VR
#   blackhole    Black hole (12)
#       Outer Wilds VR; Starfield VR; Kerbal Space Program; X4: Foundations VR;
#       Mass Effect 1 LE VR; Mass Effect 2 LE VR; Mass Effect 3 LE VR; Freespace 2 VR;
#       Rebel Galaxy VR; Star Trucker VR; Astrodogs VR; Prey (2006) VR
#   fighters     Space fighters (14)
#       Star Wars: X-Wing VR; Star Wars Outlaws VR; X4: Foundations VR; Rebel Galaxy VR;
#       Freespace 2 VR; Star Trucker VR; Starfield VR; Star Fox 64 VR; Star Fox Enhanced PCVR;
#       Rogue Flight VR; Halo Master Chief Collection VR; Astrodogs VR; Descent VR; Descent 2 VR
#   contrails    Contrails (9)
#       Nuclear Option VR; Arma 3 VR; Battlefield 1942 VR; Rogue Flight VR; Grand Theft Auto V VR;
#       Far Cry 5 VR; Mirage Feathers VR; Call of Duty 4 VR;
#       Metal Gear Solid V: The Phantom Pain VR
#   puddles      Rain puddles (13)
#       Witcher 3 VR; Red Dead Redemption VR; Days Gone VR; Max Payne 2 VR; Cyberpunk 2077;
#       GTA IV VR; Silent Hill VR; Ghost of Tsushima VR; Kingdom Come: Deliverance VR;
#       Death Stranding VR; Life is Strange: BtS; Watch Dogs Legion VR; Road to Vostok VR
#   tumbleweed   Tumbleweed (6)
#       Red Dead Redemption VR; Borderlands GOTY Enhanced; Fallout 4 VR; Sunrise GP VR;
#       Risk of Rain 2; Redneck Rampage VR
#   bats         Bats (14)
#       RE Village VR; Hogwarts Legacy VR; Dark Souls Remastered; Diablo II: Resurrected; Blood VR;
#       Amnesia VR; Lunacid VR; Little Witch Nobeta VR; Ghosts n Goblins Resurrection VR;
#       Arx Fatalis VR; Heretic VR; Hexen VR; Tormented Souls VR; Witcher 3 VR
#   moths        Moths at the lamp (13)
#       Outlast VR; Silent Hill VR; Silent Hill 3 VR; Firewatch VR; Sons of the Forest;
#       Days Gone VR; TLOU Part I VR; TLOU Part II VR; Project Zomboid VR; 7 Days to Die VR;
#       Stray VR; Paranoia Place VR; The Dark Mod VR
#   jellyfish    Jellyfish (10)
#       Subnautica VR; Subnautica: Below Zero; Another Crab's Treasure; BioShock Remastered;
#       BioShock 2 Remastered; SOMA VR; Dredge VR; Raft VR; Avatar: Frontiers of Pandora VR;
#       How to Fish XR
#   kelp         Kelp forest (7)
#       Subnautica VR; Subnautica: Below Zero; Another Crab's Treasure; Raft VR; Dredge VR;
#       How to Fish XR; SOMA VR
#   flakes       Snow crystals (11)
#       Skyrim VR; Valheim VR; SnowRunner VR; Subnautica: Below Zero; Far Cry 4 VR;
#       theHunter: Call of the Wild VR; Witcher 3 VR; PEAK VR; Stardew Valley VR; Dinkum VR;
#       Kingdom Come: Deliverance II VR
#   spotlights   Stage spotlights (11)
#       Trombone Champ VR; Metal: Hellsinger VR; Sayonara Wild Hearts; Bomb Rush Cyberfunk;
#       Street Fighter 6 VR; GTA Vice City VR; Saints Row: The Third VR; Neon White VR;
#       Content Warning VR; R.E.P.O. VR; Retrowave 2 VR
#   fireworks    Fireworks (13)
#       Mario Kart 64 VR; Mario Kart Wii VR; Super Mario 3D World VR; Forza Horizon 5 VR;
#       Forza Horizon 6 VR; Trombone Champ VR; Stardew Valley VR; Saints Row: The Third VR;
#       Sonic P-06 VR; Kunitsu-Gami: Path of the Goddess VR; Ghost of Tsushima VR;
#       Diddy Kong Racing VR; A Kingdom for Keflings VR
#   balloons     Balloons (11)
#       Diddy Kong Racing VR; Mario Kart Wii VR; Tinykin VR; A Kingdom for Keflings VR;
#       Garry's Mod VR; Stardew Valley VR; Slime Rancher VR; Big Walk VR; PEAK VR; High on Life VR;
#       Super Mario 3D World VR
#   fairydust    Fairy dust (14)
#       Legend of Zelda: Ocarina of Time VR; Legend of Zelda: Twilight Princess;
#       Breath of the Wild VR; Hogwarts Legacy VR; Little Witch Nobeta VR;
#       Kunitsu-Gami: Path of the Goddess VR; Final Fantasy XIV VR; Yooka-Laylee VR;
#       Banjo-Kazooie VR; Super Mario 64 VR; Alba VR; Tinykin VR; Hollow Knight VR;
#       Mirage Feathers VR
#   paperplanes  Paper planes (8)
#       Paperklay VR; Stanley Parable VR; Tinykin VR; Life is Strange: BtS;
#       A Kingdom for Keflings VR; Big Walk VR; Apollo Justice: Ace Attorney Trilogy VR;
#       Firewatch VR
#   dice         Dice and cards (7)
#       Gloomhaven VR; Pathfinder: Kingmaker; Warhammer 40K: Rogue Trader VR; Echo Generation 2 VR;
#       Monster Hunter Stories 3 VR; Pokemon Dramatic Shape VR; Diablo II: Resurrected
#   gears        Clockwork gears (12)
#       BioShock Infinite VR; Dishonored VR; Thief (2014) VR; Techtonica VR; Scrap Mechanic VR;
#       Shipbreaker VR; Atomic Heart VR; The Witness; Stray VR; Ratchet & Clank VR; Portal 2 VR;
#       Arx Fatalis VR
#   helix        DNA helix (16)
#       Atomic Heart VR; BioShock Remastered; BioShock 2 Remastered; Singularity VR;
#       Resident Evil 7 VR; Resident Evil 2R VR; Resident Evil 3R VR; Resident Evil 4R VR;
#       RE Village VR; RE Requiem VR; SOMA VR; Black Mesa VR; Half-Life VR;
#       Deus Ex: Human Revolution - DC; Cruelty Squad VR; Prey (2006) VR
#   toxicgas     Toxic gas (13)
#       Anomaly VR; Anomaly GAMMA; Fallout 4 VR; Half-Life VR; Black Mesa VR; Black Mesa Source VR;
#       Left 4 Dead 2 VR; 7 Days to Die VR; Project Zomboid VR; TLOU Part I VR; TLOU Part II VR;
#       Ashes 2063 VR; GTFO VR
#   claws        Claw marks (13)
#       Left 4 Dead 2 VR; Killing Floor 2 VR; Dino Trauma VR; Turok VR; Far Cry Primal VR;
#       Monster Hunter Rise VR; Monster Hunter Wilds; Witcher 3 VR; Sons of the Forest;
#       7 Days to Die VR; Days Gone VR; Project Zomboid VR; Aliens versus Predator VR
#   glasscracks  Bullet holes (13)
#       Max Payne 2 VR; F.E.A.R. VR; Receiver VR; Receiver 2 VR; Ready Or Not VR;
#       Call of Duty 4 VR; GoldenEye 007 VR; Perfect Dark VR; House of the Dead Remake VR;
#       House of the Dead 2 Remake VR; Virtua Cop 2 VR; I Can Gun VR; Saints Row: The Third VR
#   footprints   Footprints (10)
#       Journey VR; Death Stranding VR; Big Walk VR; Firewatch VR; PEAK VR; Skyrim VR; The Witness;
#       Kingdom Come: Deliverance II VR; Outward DE VR; Driftwood VR
#   pawprints    Paw prints (6)
#       Stray VR; theHunter: Call of the Wild VR; Far Cry Primal VR; Grounded VR; Dinkum VR;
#       Slime Rancher VR
#   skybow       Rainbow (11)
#       Slime Rancher VR; Mario Kart 64 VR; Mario Kart Wii VR; Super Mario 3D World VR; Tinykin VR;
#       Flower VR; Lunistice VR; Yooka-Laylee VR; Ring Racers VR; Sonic Robo Blast 2 VR;
#       Sayonara Wild Hearts
#   lanterns     Sky lanterns (11)
#       Ghost of Tsushima VR; Kunitsu-Gami: Path of the Goddess VR; Onimusha 2 VR;
#       Final Fantasy XIV VR; Shenmue I & II; Little Witch Nobeta VR; Stardew Valley VR;
#       Hogwarts Legacy VR; Judgment VR; FF VII Rebirth VR; Mirage Feathers VR
#   arrows       Arrow volley (14)
#       Mount & Blade II: Bannerlord VR; Kingdom Come: Deliverance VR;
#       Kingdom Come: Deliverance II VR; Ghost of Tsushima VR; Assassin's Creed Odyssey VR;
#       Assassin's Creed Valhalla VR; Far Cry Primal VR; Horizon Zero Dawn VR;
#       Horizon Forbidden West VR; Dragon's Dogma 2 VR; Skyrim VR; Witcher 3 VR; Gothic II VR;
#       Horizon Zero Dawn Remastered VR
#   checkered    Checkered flag (14)
#       Forza Horizon 5 VR; Forza Horizon 6 VR; Gran Turismo 2 PCVR; TrackMania Nations Forever;
#       TrackMania United Forever; Circuit Superstars VR; New Star GP VR; Sunrise GP VR;
#       Horizon Chase Turbo; Moto Rush Reborn VR; Art of Rally VR; Richard Burns Rally VR;
#       Star Racer VR; F-Zero X VR
#   driftsmoke   Drift smoke (9)
#       Forza Horizon 5 VR; Forza Horizon 6 VR; Grand Theft Auto V VR; Road Redemption VR;
#       Decimate Drive VR; Retrowave 2 VR; GTA Vice City VR; Moto Rush Reborn VR;
#       Gran Turismo 2 PCVR
#   focuslines   Manga speed lines (12)
#       Street Fighter 6 VR; Devil May Cry 5 VR; Judgment VR; Ghostwire: Tokyo VR; Sonic P-06 VR;
#       Neon White VR; Kunitsu-Gami: Path of the Goddess VR; Little Witch Nobeta VR;
#       Pokemon Dramatic Shape VR; Mega Man Star Force Legacy VR; Monster Hunter Stories 3 VR;
#       Onimusha 2 VR
#   runes        Floating runes (14)
#       Valheim VR; Assassin's Creed Valhalla VR; Skyrim VR; Elden Ring; Elden Ring VR;
#       Dark Souls III VR; Witcher 3 VR; Gothic II VR; Diablo II: Resurrected; Hexen VR;
#       Final Fantasy XIV VR; Mage Arena VR; Arx Fatalis VR; Morrowind VR
#   jungle       Jungle fronds (13)
#       Far Cry VR; Far Cry 6 VR; Far Cry Primal VR; Crysis VR; Turok VR;
#       Uncharted: Legacy of Thieves VR; Avatar: Frontiers of Pandora VR; Horizon Zero Dawn VR;
#       Tomb Raider 1 VR; Indiana Jones: Great Circle VR; Dino Trauma VR; Grounded VR; Raft VR
#   skulls       Glowing skulls (14)
#       Doom VR; Doom 2 VR; DOOM (2016) VR; Painkiller Black Edition; Painkiller: Overdose VR;
#       Blood VR; Diablo II: Resurrected; Heretic VR; Hexen VR; Shadow Warrior VR;
#       Dusk HD (DLC) VR; ULTRAKILL VR; Metal: Hellsinger VR; Ghosts n Goblins Resurrection VR
# ============================================================

$global:HubBannerFxExtra = $true

$global:BannerFxExtraConfig = @{
    GameChance   = 0.40    # established round 1 chance
    Round2Chance = 0.30    # new alternatives when the game has a fitting effect
    FeaturedOnly = $true   # new effects only on ListBanner / LibBanner / OvBanner
    Reroll       = $true   # re-roll the featured banner effects once after loading
}

$global:BannerFxExtraFeatured = @('ListBanner', 'LibBanner', 'OvBanner')
$global:BannerFxExtraRound2 = @(
    'aurora','grindsparks','shieldhit','laserdot','ecg','hud','cracks','candles',
    'blackhole','fighters','contrails','puddles','tumbleweed','bats','moths',
    'jellyfish','kelp','flakes','spotlights','fireworks','balloons','fairydust',
    'paperplanes','dice','gears','helix','toxicgas','claws','glasscracks',
    'footprints','pawprints','skybow','lanterns','arrows','checkered',
    'driftsmoke','focuslines','runes','jungle','skulls'
)

# Effect used instead of a new one on non-featured banners.
$global:BannerFxExtraFallback = @{
    blizzard = 'snow'; frost = 'snow'; blooddrips = 'bloodrain'; inkdrips = 'rain'
    raindrops = 'rain'; fish = 'bubbles'; caustics = 'bubbles'; ash = 'embers'
    lasers = 'meteors'; starburst = 'meteors'; orbits = 'vortex'; magic = 'vortex'
    pixels = 'spark'; coins = 'spark'; rings = 'spark'; gems = 'twinkle'
    lighttrails = 'speed'; neoncity = 'bokeh'; fog = 'bokeh'; clouds = 'bokeh'
    aurora = 'nebula'; grindsparks = 'spark'; shieldhit = 'hex'; laserdot = 'twinkle'
    ecg = 'waves'; hud = 'circuit'; cracks = 'lava'; candles = 'embers'
    blackhole = 'vortex'; fighters = 'stars'; contrails = 'speed'; puddles = 'rain'
    jellyfish = 'bubblesdeep'; kelp = 'bubbles'; flakes = 'snow'; spotlights = 'rays'
    fireworks = 'spark'; balloons = 'bokehcandy'; fairydust = 'twinkle'; helix = 'network'
    toxicgas = 'blobtoxic'; glasscracks = 'shards'; skybow = 'bokehcandy'; lanterns = 'bokehember'
    checkered = 'stripes'; driftsmoke = 'bokeh'; focuslines = 'speed'; runes = 'twinkle'
    jungle = 'bokehmint'; skulls = 'embers'
}

# Particle-type new effects: lifted above the art with the BannerGlass
# Glow style (flat ones stay pale and below the art).
$global:BannerFxExtraParticle = @(
    'fireflies','leaves','petals','flowerwind','ash','pixels','confetti','starburst',
    'coins','rings','bolts','gems','hearts','notes','papers','blizzard','sandwind',
    'lasers','tracers','wisps','biolum','birds','fish','spores','lighttrails',
    'grindsparks','laserdot','fighters','bats','moths','jellyfish','flakes','fireworks',
    'balloons','fairydust','paperplanes','dice','arrows','lanterns','runes','skulls',
    'claws','glasscracks'
)

$global:BannerFxExtraNames = [ordered]@{
    'fireflies' = 'Fireflies'
    'leaves' = 'Autumn leaves'
    'petals' = 'Cherry blossoms'
    'flowerwind' = 'Flowers in the wind'
    'lightning' = 'Lightning'
    'ash' = 'Ash and embers'
    'fog' = 'Drifting fog'
    'flashlight' = 'Flashlight'
    'tracers' = 'Tracer fire'
    'flak' = 'Distant explosions'
    'pixels' = '8-bit pixels'
    'glitch' = 'CRT and glitch'
    'neoncity' = 'Neon city lights'
    'raindrops' = 'Rain on glass'
    'lighttrails' = 'Light trails'
    'dust' = 'Dust and gravel'
    'radiation' = 'Radiation'
    'magic' = 'Rune circle'
    'wisps' = 'Ghost wisps'
    'confetti' = 'Confetti'
    'birds' = 'Bird flock'
    'blizzard' = 'Blizzard'
    'frost' = 'Frost crystals'
    'sandwind' = 'Drifting sand'
    'blooddrips' = 'Blood drips'
    'caustics' = 'Underwater caustics'
    'fish' = 'Fish school'
    'orbits' = 'Planet orbits'
    'lasers' = 'Laser fire'
    'scan' = 'Hologram scan'
    'biolum' = 'Bioluminescence'
    'hearts' = 'Hearts'
    'notes' = 'Music notes'
    'bullettime' = 'Bullet time'
    'void' = 'Void tendrils'
    'portals' = 'Portal pair'
    'teleport' = 'Teleport vortex'
    'webs' = 'Spider webs'
    'coins' = 'Gold coins'
    'rings' = 'Gold rings'
    'bolts' = 'Bolts and nuts'
    'gems' = 'Gems'
    'inkdrips' = 'Ink drips'
    'halftone' = 'Comic halftone'
    'graffiti' = 'Paint splats'
    'waterspray' = 'Water jet'
    'clouds' = 'Sea of clouds'
    'eyes' = 'Eyes in the dark'
    'steam' = 'Steam bursts'
    'papers' = 'Flying papers'
    'starburst' = 'Meteor shower'
    'lensflare' = 'Lens flare'
    'tracker' = 'Motion tracker'
    'slashes' = 'Blade slashes'
    'spores' = 'Spores in light'
    'aurora' = 'Northern lights'
    'grindsparks' = 'Grinder sparks'
    'shieldhit' = 'Shield impacts'
    'laserdot' = 'Laser sights'
    'ecg' = 'Heartbeat monitor'
    'hud' = 'Visor HUD'
    'cracks' = 'Glowing cracks'
    'candles' = 'Candlelight'
    'blackhole' = 'Black hole'
    'fighters' = 'Space fighters'
    'contrails' = 'Contrails'
    'puddles' = 'Rain puddles'
    'tumbleweed' = 'Tumbleweed'
    'bats' = 'Bats'
    'moths' = 'Moths at the lamp'
    'jellyfish' = 'Jellyfish'
    'kelp' = 'Kelp forest'
    'flakes' = 'Snow crystals'
    'spotlights' = 'Stage spotlights'
    'fireworks' = 'Fireworks'
    'balloons' = 'Balloons'
    'fairydust' = 'Fairy dust'
    'paperplanes' = 'Paper planes'
    'dice' = 'Dice and cards'
    'gears' = 'Clockwork gears'
    'helix' = 'DNA helix'
    'toxicgas' = 'Toxic gas'
    'claws' = 'Claw marks'
    'glasscracks' = 'Bullet holes'
    'footprints' = 'Footprints'
    'pawprints' = 'Paw prints'
    'skybow' = 'Rainbow'
    'lanterns' = 'Sky lanterns'
    'arrows' = 'Arrow volley'
    'checkered' = 'Checkered flag'
    'driftsmoke' = 'Drift smoke'
    'focuslines' = 'Manga speed lines'
    'runes' = 'Floating runes'
    'jungle' = 'Jungle fronds'
    'skulls' = 'Glowing skulls'
}

$global:BannerFxExtraKind = @{
    'fireflies' = 'general'
    'leaves' = 'general'
    'petals' = 'general'
    'flowerwind' = 'general'
    'lightning' = 'general'
    'ash' = 'general'
    'fog' = 'general'
    'flashlight' = 'general'
    'tracers' = 'general'
    'flak' = 'general'
    'pixels' = 'general'
    'glitch' = 'general'
    'neoncity' = 'general'
    'raindrops' = 'general'
    'lighttrails' = 'general'
    'dust' = 'general'
    'radiation' = 'general'
    'magic' = 'general'
    'wisps' = 'general'
    'confetti' = 'general'
    'birds' = 'general'
    'blizzard' = 'general'
    'frost' = 'general'
    'sandwind' = 'general'
    'blooddrips' = 'general'
    'caustics' = 'general'
    'fish' = 'general'
    'orbits' = 'general'
    'lasers' = 'general'
    'scan' = 'general'
    'biolum' = 'general'
    'hearts' = 'general'
    'notes' = 'general'
    'bullettime' = 'general'
    'void' = 'general'
    'portals' = 'game'
    'teleport' = 'game'
    'webs' = 'game'
    'coins' = 'game'
    'rings' = 'game'
    'bolts' = 'game'
    'gems' = 'game'
    'inkdrips' = 'game'
    'halftone' = 'game'
    'graffiti' = 'game'
    'waterspray' = 'game'
    'clouds' = 'game'
    'eyes' = 'game'
    'steam' = 'game'
    'papers' = 'game'
    'starburst' = 'general'
    'lensflare' = 'general'
    'tracker' = 'game'
    'slashes' = 'general'
    'spores' = 'general'
    'aurora' = 'general'
    'grindsparks' = 'general'
    'shieldhit' = 'general'
    'laserdot' = 'general'
    'ecg' = 'general'
    'hud' = 'general'
    'cracks' = 'general'
    'candles' = 'general'
    'blackhole' = 'general'
    'fighters' = 'general'
    'contrails' = 'general'
    'puddles' = 'general'
    'tumbleweed' = 'game'
    'bats' = 'general'
    'moths' = 'general'
    'jellyfish' = 'general'
    'kelp' = 'general'
    'flakes' = 'general'
    'spotlights' = 'general'
    'fireworks' = 'general'
    'balloons' = 'general'
    'fairydust' = 'general'
    'paperplanes' = 'general'
    'dice' = 'game'
    'gears' = 'general'
    'helix' = 'general'
    'toxicgas' = 'general'
    'claws' = 'general'
    'glasscracks' = 'general'
    'footprints' = 'general'
    'pawprints' = 'game'
    'skybow' = 'general'
    'lanterns' = 'general'
    'arrows' = 'general'
    'checkered' = 'general'
    'driftsmoke' = 'general'
    'focuslines' = 'general'
    'runes' = 'general'
    'jungle' = 'general'
    'skulls' = 'general'
}

$global:BannerFxExtraGames = [ordered]@{
    'fireflies' = @(
        'Stardew Valley VR',
        'Valheim VR',
        'Firewatch VR',
        'Witcher 3 VR',
        'Skyrim VR',
        'Ghost of Tsushima VR',
        'Outward DE VR',
        'Dredge VR',
        'Hollow Knight VR',
        'Driftwood VR',
        'Muck VR',
        'Dinkum VR',
        'Kingdom Come: Deliverance VR',
        'Kingdom Come: Deliverance II VR',
        'Red Dead Redemption VR',
        'Legend of Zelda: Twilight Princess',
        'Breath of the Wild VR',
        'Alan Wake VR'
    )
    'leaves' = @(
        'Firewatch VR',
        'Kingdom Come: Deliverance VR',
        'Kingdom Come: Deliverance II VR',
        'Witcher 3 VR',
        'Gothic II VR',
        'Red Dead Redemption VR',
        'theHunter: Call of the Wild VR',
        'Far Cry 5 VR',
        'Days Gone VR',
        'Life is Strange: BtS',
        'Sons of the Forest',
        'Assassin''s Creed Valhalla VR',
        'Oblivion (2006)',
        'Big Walk VR',
        'Alan Wake VR'
    )
    'petals' = @(
        'Ghost of Tsushima VR',
        'Kunitsu-Gami: Path of the Goddess VR',
        'Onimusha 2 VR',
        'Ghostwire: Tokyo VR',
        'Judgment VR',
        'Shenmue I & II',
        'Forza Horizon 6 VR',
        'Little Witch Nobeta VR',
        'Street Fighter 6 VR'
    )
    'flowerwind' = @(
        'Flower VR',
        'Breath of the Wild VR',
        'Legend of Zelda: Ocarina of Time VR',
        'Tinykin VR',
        'A Kingdom for Keflings VR',
        'Alba VR',
        'Grounded VR',
        'Yooka-Laylee VR',
        'Paperklay VR',
        'Pokemon Dramatic Shape VR'
    )
    'lightning' = @(
        'Quake VR',
        'Quake 2 VR',
        'Hexen VR',
        'Hexen II VR',
        'Heretic VR',
        'Painkiller Black Edition',
        'Painkiller: Overdose VR',
        'Mage Arena VR',
        'Warhammer 40K: Darktide VR',
        'Warhammer 40K: Rogue Trader VR',
        'Dark Souls III VR',
        'Elden Ring',
        'Elden Ring VR',
        'Titanfall 2 VR',
        'Singularity VR',
        'Unreal Revived',
        'Alan Wake VR'
    )
    'ash' = @(
        'Dark Souls Remastered',
        'Dark Souls II VR',
        'Dark Souls II: Scholar',
        'Dark Souls III VR',
        'Elden Ring',
        'Elden Ring VR',
        'DOOM (2016) VR',
        'Doom Eternal VR',
        'DOOM Eternal VR - Motion',
        'Diablo II: Resurrected',
        'Blade of Darkness VR',
        'Lunacid VR',
        'Total Chaos VR',
        'Metal: Hellsinger VR',
        'ELDERBORN VR',
        'Dragon''s Dogma 2 VR',
        'Devil May Cry 5 VR'
    )
    'fog' = @(
        'Silent Hill VR',
        'Silent Hill 3 VR',
        'Amnesia VR',
        'Outlast VR',
        'Outlast 2 VR',
        'Penumbra: Overture VR',
        'Penumbra: Black Plague VR',
        'Penumbra: Requiem VR',
        'SOMA VR',
        'Tormented Souls VR',
        'RE Village VR',
        'RE Requiem VR',
        'Alien: Isolation VR',
        'The Dark Mod VR',
        'Thief (2014) VR',
        'Unmourned VR',
        'Hypogea VR',
        'Paranoia Place VR',
        'Idols of Ash VR',
        'Alan Wake VR'
    )
    'flashlight' = @(
        'Outlast VR',
        'Outlast 2 VR',
        'Lethal Company VR',
        'Content Warning VR',
        'R.E.P.O. VR',
        'GTFO VR',
        'Alien: Isolation VR',
        'Resident Evil 7 VR',
        'Resident Evil 2R VR',
        'Resident Evil 3R VR',
        'Moros Protocol VR',
        'Doom 3 BFG VR',
        'Iron Lung VR',
        'Amnesia VR',
        'F.E.A.R. VR',
        'Paranoia Place VR',
        'Selaco VR',
        'Alan Wake VR'
    )
    'tracers' = @(
        'Call of Duty 4 VR',
        'Call of Duty: World at War VR',
        'Battlefield 1942 VR',
        'Arma 3 VR',
        'NAM VR',
        'World War II GI VR',
        'Escape from Tarkov VR',
        'Ready Or Not VR',
        'Ghost Recon Wildlands VR',
        'EARTH DEFENSE FORCE 6 VR',
        'Crysis VR',
        'Road to Vostok VR',
        'Nuclear Option VR',
        'C&C Generals: Zero Hour',
        'Metal Gear Solid V: The Phantom Pain VR'
    )
    'flak' = @(
        'Battlefield 1942 VR',
        'Call of Duty: World at War VR',
        'World War II GI VR',
        'NAM VR',
        'Arma 3 VR',
        'C&C Generals: Zero Hour',
        'EARTH DEFENSE FORCE 6 VR',
        'Nuclear Option VR',
        'Red Faction VR',
        'Teardown VR'
    )
    'pixels' = @(
        'Doom VR',
        'Doom 2 VR',
        'Wolfenstein 3D VR',
        'Duke Nukem 3D VR',
        'Heretic VR',
        'Hexen VR',
        'Blood VR',
        'Shadow Warrior VR',
        'Redneck Rampage VR',
        'PowerSlave / Exhumed VR',
        'Strife VR',
        'Dusk HD (DLC) VR',
        'ULTRAKILL VR',
        'Quake VR',
        'Super Mario 64 VR',
        'Mario Kart 64 VR',
        'Banjo-Kazooie VR',
        'GoldenEye 007 VR',
        'Perfect Dark VR',
        'Star Fox 64 VR',
        'Diddy Kong Racing VR',
        'F-Zero X VR',
        'Turok VR',
        'Sonic Robo Blast 2 VR',
        'Ring Racers VR',
        'Daggerfall VR',
        'Hytale VR',
        'Vivecraft',
        'Echo Generation 2 VR'
    )
    'glitch' = @(
        'Cyberpunk 2077',
        'Cruelty Squad VR',
        'Watch Dogs VR',
        'Watch Dogs 2 VR',
        'Watch Dogs Legion VR',
        'Deus Ex: Human Revolution - DC',
        'Retrowave 2 VR',
        'Cloudpunk VR',
        'Cloudpunk: City of Ghosts VR',
        'Neon White VR',
        'MiSide VR',
        'Moros Protocol VR',
        'Stanley Parable VR',
        'Iron Lung VR',
        'Atomic Heart VR'
    )
    'neoncity' = @(
        'Cyberpunk 2077',
        'Cloudpunk VR',
        'Cloudpunk: City of Ghosts VR',
        'Ghostwire: Tokyo VR',
        'Judgment VR',
        'Bomb Rush Cyberfunk',
        'Watch Dogs Legion VR',
        'GTA Vice City VR',
        'Saints Row: The Third VR',
        'Retrowave 2 VR',
        'Grand Theft Auto V VR',
        'GTA IV VR',
        'Neon White VR',
        'Sayonara Wild Hearts'
    )
    'raindrops' = @(
        'Max Payne 2 VR',
        'Cyberpunk 2077',
        'Cloudpunk VR',
        'Life is Strange: BtS',
        'Days Gone VR',
        'Death Stranding VR',
        'Silent Hill VR',
        'F.E.A.R. VR',
        'Watch Dogs VR',
        'GTA IV VR',
        'Road to Vostok VR',
        'Driftwood VR',
        'Alan Wake VR'
    )
    'lighttrails' = @(
        'Forza Horizon 5 VR',
        'Forza Horizon 6 VR',
        'Gran Turismo 2 PCVR',
        'Horizon Chase Turbo',
        'TrackMania Nations Forever',
        'TrackMania United Forever',
        'Circuit Superstars VR',
        'New Star GP VR',
        'Sunrise GP VR',
        'Retrowave 2 VR',
        'Star Racer VR',
        'F-Zero X VR',
        'Star Wars Episode I Racer',
        'Ring Racers VR',
        'Mario Kart 64 VR',
        'Mario Kart Wii VR',
        'Diddy Kong Racing VR',
        'Moto Rush Reborn VR',
        'Road Redemption VR',
        'Grand Theft Auto V VR',
        'Decimate Drive VR'
    )
    'dust' = @(
        'Richard Burns Rally VR',
        'Art of Rally VR',
        'SnowRunner VR',
        'Descenders VR',
        'StreetDog BMX VR',
        'Red Dead Redemption VR',
        'Death Stranding VR',
        'Road Redemption VR',
        'Moto Rush Reborn VR',
        'Days Gone VR',
        'Fallout 4 VR',
        'Far Cry 6 VR',
        'Metal Gear Solid V: The Phantom Pain VR'
    )
    'radiation' = @(
        'Fallout 4 VR',
        'Anomaly VR',
        'Anomaly GAMMA',
        'Ashes 2063 VR',
        'Road to Vostok VR',
        '7 Days to Die VR',
        'Atomic Heart VR',
        'Escape from Tarkov VR',
        'Project Zomboid VR',
        'Black Mesa VR',
        'Black Mesa Source VR',
        'Half-Life VR'
    )
    'magic' = @(
        'Hogwarts Legacy VR',
        'Mage Arena VR',
        'Little Witch Nobeta VR',
        'Skyrim VR',
        'Oblivion (2006)',
        'Morrowind VR',
        'Witcher 3 VR',
        'Diablo II: Resurrected',
        'Daggerfall VR',
        'Arx Fatalis VR',
        'Gothic II VR',
        'Final Fantasy XIV VR',
        'Pathfinder: Kingmaker',
        'Gloomhaven VR',
        'World of Warcraft VR',
        'Dragon''s Dogma 2 VR',
        'Hexen VR',
        'Hexen II VR',
        'Kunitsu-Gami: Path of the Goddess VR',
        'Elden Ring VR',
        'FF VII Remake VR',
        'FF VII Rebirth VR',
        'Mirage Feathers VR'
    )
    'wisps' = @(
        'Ghostwire: Tokyo VR',
        'Hollow Knight VR',
        'Hollow Knight Silksong',
        'Dark Souls Remastered',
        'Lunacid VR',
        'Ghosts n Goblins Resurrection VR',
        'Idols of Ash VR',
        'Unmourned VR',
        'Death Stranding VR',
        'Paranoia Place VR',
        'Silent Hill 3 VR',
        'Onimusha 2 VR',
        'Blade of Darkness VR'
    )
    'confetti' = @(
        'Trombone Champ VR',
        'Stanley Parable VR',
        'Garry''s Mod VR',
        'R.E.P.O. VR',
        'PEAK VR',
        'Content Warning VR',
        'Tinykin VR',
        'A Kingdom for Keflings VR',
        'Mario Kart Wii VR',
        'Super Mario 3D World VR',
        'Big Walk VR',
        'Slyders VR',
        'High Entropy: Challenges VR'
    )
    'birds' = @(
        'Red Dead Redemption VR',
        'Witcher 3 VR',
        'Assassin''s Creed Mirage VR',
        'Assassin''s Creed Odyssey VR',
        'Assassin''s Creed Valhalla VR',
        'Far Cry Primal VR',
        'Ghost of Tsushima VR',
        'Kingdom Come: Deliverance VR',
        'Kingdom Come: Deliverance II VR',
        'Days Gone VR',
        'Mount & Blade II: Bannerlord VR',
        'Horizon Zero Dawn VR',
        'Firewatch VR',
        'theHunter: Call of the Wild VR'
    )
    'blizzard' = @(
        'Skyrim VR',
        'Far Cry 4 VR',
        'SnowRunner VR',
        'Subnautica: Below Zero',
        'Death Stranding VR',
        'Valheim VR',
        'theHunter: Call of the Wild VR',
        'Dark Souls III VR',
        'Witcher 3 VR',
        'PEAK VR',
        'White Knuckle VR'
    )
    'frost' = @(
        'Skyrim VR',
        'Subnautica: Below Zero',
        'Far Cry 4 VR',
        'SnowRunner VR',
        'Valheim VR',
        'PEAK VR'
    )
    'sandwind' = @(
        'Journey VR',
        'Assassin''s Creed Mirage VR',
        'PowerSlave / Exhumed VR',
        'Indiana Jones: Great Circle VR',
        'Uncharted: Legacy of Thieves VR',
        'Tomb Raider 1 VR',
        'Star Wars Outlaws VR',
        'Metal Gear Solid V: The Phantom Pain VR',
        'Red Dead Redemption VR',
        'Borderlands GOTY Enhanced',
        'Risk of Rain 2',
        'Spec Ops: The Line VR'
    )
    'blooddrips' = @(
        'Blood VR',
        'Painkiller Black Edition',
        'Painkiller: Overdose VR',
        'Killing Floor 2 VR',
        'Left 4 Dead 2 VR',
        'DOOM (2016) VR',
        'Doom Eternal VR',
        'ULTRAKILL VR',
        'Dusk HD (DLC) VR',
        'House of the Dead Remake VR',
        'House of the Dead 2 Remake VR',
        'The House of the Dead 2',
        'Resident Evil 2R VR',
        'Resident Evil 4R VR',
        'Dino Trauma VR',
        'Cruelty Squad VR',
        'Shadow Warrior VR',
        'Devil May Cry 5 VR',
        'Total Chaos VR'
    )
    'caustics' = @(
        'Subnautica VR',
        'Subnautica: Below Zero',
        'Another Crab''s Treasure',
        'BioShock Remastered',
        'BioShock 2 Remastered',
        'Raft VR',
        'How to Fish XR',
        'Dredge VR',
        'SOMA VR'
    )
    'fish' = @(
        'Subnautica VR',
        'Subnautica: Below Zero',
        'Dredge VR',
        'How to Fish XR',
        'Another Crab''s Treasure',
        'Raft VR',
        'Stardew Valley VR',
        'BioShock 2 Remastered'
    )
    'orbits' = @(
        'Outer Wilds VR',
        'Kerbal Space Program',
        'Starfield VR',
        'X4: Foundations VR',
        'Rebel Galaxy VR',
        'Star Trucker VR',
        'Mass Effect 1 LE VR',
        'Mass Effect 2 LE VR',
        'Mass Effect 3 LE VR',
        'Freespace 2 VR',
        'Star Wars: X-Wing VR',
        'Rogue Flight VR',
        'Astrodogs VR'
    )
    'lasers' = @(
        'Star Wars: X-Wing VR',
        'Star Wars Outlaws VR',
        'Jedi Knight: Jedi Outcast VR',
        'Jedi Knight: Jedi Academy VR',
        'Star Fox 64 VR',
        'Star Fox Enhanced PCVR',
        'Rebel Galaxy VR',
        'Freespace 2 VR',
        'X4: Foundations VR',
        'Descent VR',
        'Descent 2 VR',
        'Rogue Flight VR',
        'Halo CE VR',
        'Halo Master Chief Collection VR',
        'Perfect Dark VR',
        'Tribes 2 VR',
        'Quake 3 VR',
        'Unreal Revived',
        'Astrodogs VR',
        'Panzer Dragoon Remake',
        'Metroid Prime VR',
        'Ratchet & Clank VR',
        'High on Life VR'
    )
    'scan' = @(
        'Horizon Zero Dawn VR',
        'Horizon Zero Dawn Remastered VR',
        'Horizon Forbidden West VR',
        'Deus Ex: Human Revolution - DC',
        'Watch Dogs 2 VR',
        'Metroid Prime VR',
        'Pragmata VR',
        'Crysis VR',
        'Mass Effect 1 LE VR',
        'Ghost Recon Wildlands VR',
        'Atomic Heart VR',
        'Mega Man Star Force Legacy VR',
        'Death Stranding VR'
    )
    'biolum' = @(
        'Avatar: Frontiers of Pandora VR',
        'Subnautica VR',
        'Hollow Knight VR',
        'Hollow Knight Silksong',
        'Grounded VR',
        'Deep Rock Galactic VR',
        'Lunistice VR',
        'Mirage Feathers VR'
    )
    'hearts' = @(
        'MiSide VR',
        'Stardew Valley VR',
        'Life is Strange: BtS',
        'Slime Rancher VR',
        'Dinkum VR',
        'Tinykin VR'
    )
    'notes' = @(
        'Trombone Champ VR',
        'Metal: Hellsinger VR',
        'Sayonara Wild Hearts',
        'Banjo-Kazooie VR',
        'Bomb Rush Cyberfunk',
        'Echo Generation 2 VR',
        'Retrowave 2 VR'
    )
    'bullettime' = @(
        'Max Payne 2 VR',
        'F.E.A.R. VR',
        'Receiver VR',
        'Receiver 2 VR',
        'I Can Gun VR',
        'Ready Or Not VR',
        'Neon White VR',
        'Titanfall 2 VR',
        'Virtua Cop 2 VR'
    )
    'void' = @(
        'Dishonored VR',
        'Thief (2014) VR',
        'The Dark Mod VR',
        'Singularity VR',
        'Prey (2006) VR',
        'BioShock Infinite VR',
        'SOMA VR',
        'Warhammer 40K: Darktide VR',
        'Warhammer 40K: Rogue Trader VR'
    )
    'portals' = @(
        'Portal 2 VR',
        'Portal 2: Community Edition VR',
        'Prey (2006) VR'
    )
    'teleport' = @(
        'Half-Life VR',
        'Black Mesa VR',
        'Black Mesa Source VR',
        'Half-Life 2 VR',
        'HL2 VR Ep. One',
        'HL2 VR Ep. Two'
    )
    'webs' = @(
        'Spider-Man Remastered VR',
        'Spiderman Remastered',
        'Spiderman 2 VR',
        'Spiderman Miles Morales VR',
        'Grounded VR',
        'Hollow Knight Silksong'
    )
    'coins' = @(
        'Super Mario 3D World VR',
        'Super Mario 64 VR',
        'Mario Kart 64 VR',
        'Mario Kart Wii VR',
        'Yooka-Laylee VR',
        'Diddy Kong Racing VR',
        'Gunfire Reborn',
        'Borderlands GOTY Enhanced',
        'Risk of Rain 2',
        'Lunistice VR'
    )
    'rings' = @(
        'Sonic P-06 VR',
        'Sonic Robo Blast 2 VR',
        'Ring Racers VR'
    )
    'bolts' = @(
        'Ratchet & Clank VR',
        'Scrap Mechanic VR',
        'Shipbreaker VR',
        'Techtonica VR',
        'Teardown VR'
    )
    'gems' = @(
        'Deep Rock Galactic VR',
        'Vivecraft',
        'Hytale VR',
        'Techtonica VR',
        'Muck VR',
        'Dinkum VR',
        'Diablo II: Resurrected',
        'Borderlands GOTY Enhanced'
    )
    'inkdrips' = @(
        'Bendy VR',
        'Mouse P.I. For Hire VR'
    )
    'halftone' = @(
        'XIII Remake VR',
        'Borderlands GOTY Enhanced',
        'Mouse P.I. For Hire VR',
        'Bomb Rush Cyberfunk'
    )
    'graffiti' = @(
        'Bomb Rush Cyberfunk',
        'Skate Story VR',
        'StreetDog BMX VR',
        'Sayonara Wild Hearts',
        'Paperklay VR',
        'Saints Row: The Third VR'
    )
    'waterspray' = @(
        'PowerWash Simulator VR',
        'PowerWash Simulator 2 VR'
    )
    'clouds' = @(
        'BioShock Infinite VR',
        'Panzer Dragoon Remake',
        'Nuclear Option VR',
        'Rogue Flight VR',
        'Mirage Feathers VR',
        'PEAK VR',
        'Big Walk VR',
        'Journey VR'
    )
    'eyes' = @(
        'Outlast VR',
        'Amnesia VR',
        'Lethal Company VR',
        'Paranoia Place VR',
        'My Friendly Neighborhood VR',
        'Iron Lung VR',
        'Sons of the Forest',
        'Stray VR',
        'Bendy VR'
    )
    'steam' = @(
        'BioShock Remastered',
        'BioShock 2 Remastered',
        'BioShock Infinite VR',
        'Dishonored VR',
        'Atomic Heart VR',
        'Techtonica VR',
        'Stray VR',
        'Half-Life 2 VR'
    )
    'papers' = @(
        'Apollo Justice: Ace Attorney Trilogy VR',
        'Stanley Parable VR',
        'Judgment VR',
        'Mouse P.I. For Hire VR',
        'Life is Strange: BtS'
    )
    'starburst' = @(
        'Outer Wilds VR',
        'Journey VR',
        'Starfield VR',
        'No One Lives Forever VR',
        'No One Lives Forever 2 VR',
        'Kerbal Space Program',
        'Sayonara Wild Hearts',
        'Final Fantasy XIV VR',
        'FF VII Remake VR',
        'FF VII Rebirth VR',
        'The Witness'
    )
    'lensflare' = @(
        'Mirror''s Edge VR',
        'Far Cry VR',
        'Far Cry New Dawn VR',
        'AWAY VR',
        'Outbound VR',
        'Forza Horizon 5 VR',
        'Far Cry 6 VR',
        'GTA Vice City VR',
        'Uncharted: Legacy of Thieves VR'
    )
    'tracker' = @(
        'Aliens versus Predator VR',
        'Alien: Isolation VR',
        'SiN Episodes: Emergence',
        'GTFO VR',
        'Iron Lung VR'
    )
    'slashes' = @(
        'Monster Hunter Rise VR',
        'Monster Hunter Stories 3 VR',
        'Monster Hunter Wilds',
        'Devil May Cry 5 VR',
        'Onimusha 2 VR',
        'Ghost of Tsushima VR',
        'Street Fighter 6 VR',
        'Dark Souls III VR',
        'Blade of Darkness VR',
        'Jedi Knight: Jedi Academy VR'
    )
    'spores' = @(
        'TLOU Part I VR',
        'TLOU Part II VR',
        'Days Gone VR',
        '7 Days to Die VR',
        'Project Zomboid VR',
        'Far Cry New Dawn VR',
        'Sons of the Forest',
        'Grounded VR',
        'Indiana Jones: Great Circle VR',
        'The Witness'
    )
    'aurora' = @(
        'Skyrim VR',
        'Valheim VR',
        'Far Cry 4 VR',
        'Subnautica: Below Zero',
        'SnowRunner VR',
        'theHunter: Call of the Wild VR',
        'Outer Wilds VR',
        'Witcher 3 VR',
        'Death Stranding VR',
        'Star Trucker VR',
        'PEAK VR',
        'Assassin''s Creed Valhalla VR'
    )
    'grindsparks' = @(
        'DOOM (2016) VR',
        'Doom Eternal VR',
        'Titanfall 2 VR',
        'Teardown VR',
        'Shipbreaker VR',
        'Red Faction VR',
        'Scrap Mechanic VR',
        'Cyberpunk 2077',
        'Atomic Heart VR',
        'Ratchet & Clank VR',
        'Techtonica VR',
        'Deep Rock Galactic VR',
        'Borderlands GOTY Enhanced'
    )
    'shieldhit' = @(
        'Halo CE VR',
        'Halo Master Chief Collection VR',
        'Crysis VR',
        'Mass Effect 1 LE VR',
        'Mass Effect 2 LE VR',
        'Mass Effect 3 LE VR',
        'Titanfall 2 VR',
        'Tribes 2 VR',
        'Star Wars: X-Wing VR',
        'Freespace 2 VR',
        'EARTH DEFENSE FORCE 6 VR',
        'Warhammer 40K: Darktide VR'
    )
    'laserdot' = @(
        'Ready Or Not VR',
        'Escape from Tarkov VR',
        'Arma 3 VR',
        'Ghost Recon Wildlands VR',
        'Metal Gear Solid V: The Phantom Pain VR',
        'GoldenEye 007 VR',
        'Perfect Dark VR',
        'Deus Ex: Human Revolution - DC',
        'Watch Dogs VR',
        'Crysis VR',
        'Max Payne 2 VR',
        'No One Lives Forever VR',
        'No One Lives Forever 2 VR',
        'Road to Vostok VR'
    )
    'ecg' = @(
        'Outlast VR',
        'Outlast 2 VR',
        'Resident Evil 7 VR',
        'Resident Evil 2R VR',
        'Resident Evil 3R VR',
        'Resident Evil 4R VR',
        'RE Village VR',
        'RE Requiem VR',
        'Amnesia VR',
        'SOMA VR',
        'Alien: Isolation VR',
        'Iron Lung VR',
        'Lethal Company VR',
        'Death Stranding VR',
        'Silent Hill VR'
    )
    'hud' = @(
        'Titanfall 2 VR',
        'Crysis VR',
        'Halo CE VR',
        'Halo Master Chief Collection VR',
        'Metroid Prime VR',
        'Deus Ex: Human Revolution - DC',
        'Nuclear Option VR',
        'X4: Foundations VR',
        'Starfield VR',
        'Mass Effect 1 LE VR',
        'Cyberpunk 2077',
        'Watch Dogs 2 VR',
        'Ghost Recon Wildlands VR',
        'Metal Gear Solid V: The Phantom Pain VR',
        'Star Wars: X-Wing VR',
        'Rogue Flight VR'
    )
    'cracks' = @(
        'Doom Eternal VR',
        'DOOM Eternal VR - Motion',
        'Diablo II: Resurrected',
        'Dark Souls III VR',
        'Elden Ring',
        'Elden Ring VR',
        'Painkiller Black Edition',
        'Painkiller: Overdose VR',
        'Metal: Hellsinger VR',
        'Devil May Cry 5 VR',
        'Blade of Darkness VR',
        'Lunacid VR',
        'Hexen VR',
        'Dark Souls II VR'
    )
    'candles' = @(
        'Amnesia VR',
        'Penumbra: Overture VR',
        'Penumbra: Black Plague VR',
        'Penumbra: Requiem VR',
        'Hogwarts Legacy VR',
        'Thief (2014) VR',
        'The Dark Mod VR',
        'Dishonored VR',
        'Dark Souls Remastered',
        'Arx Fatalis VR',
        'Gothic II VR',
        'Kingdom Come: Deliverance VR',
        'Kingdom Come: Deliverance II VR',
        'Oblivion (2006)',
        'Morrowind VR',
        'Daggerfall VR',
        'Tormented Souls VR',
        'Little Witch Nobeta VR'
    )
    'blackhole' = @(
        'Outer Wilds VR',
        'Starfield VR',
        'Kerbal Space Program',
        'X4: Foundations VR',
        'Mass Effect 1 LE VR',
        'Mass Effect 2 LE VR',
        'Mass Effect 3 LE VR',
        'Freespace 2 VR',
        'Rebel Galaxy VR',
        'Star Trucker VR',
        'Astrodogs VR',
        'Prey (2006) VR'
    )
    'fighters' = @(
        'Star Wars: X-Wing VR',
        'Star Wars Outlaws VR',
        'X4: Foundations VR',
        'Rebel Galaxy VR',
        'Freespace 2 VR',
        'Star Trucker VR',
        'Starfield VR',
        'Star Fox 64 VR',
        'Star Fox Enhanced PCVR',
        'Rogue Flight VR',
        'Halo Master Chief Collection VR',
        'Astrodogs VR',
        'Descent VR',
        'Descent 2 VR'
    )
    'contrails' = @(
        'Nuclear Option VR',
        'Arma 3 VR',
        'Battlefield 1942 VR',
        'Rogue Flight VR',
        'Grand Theft Auto V VR',
        'Far Cry 5 VR',
        'Mirage Feathers VR',
        'Call of Duty 4 VR',
        'Metal Gear Solid V: The Phantom Pain VR'
    )
    'puddles' = @(
        'Witcher 3 VR',
        'Red Dead Redemption VR',
        'Days Gone VR',
        'Max Payne 2 VR',
        'Cyberpunk 2077',
        'GTA IV VR',
        'Silent Hill VR',
        'Ghost of Tsushima VR',
        'Kingdom Come: Deliverance VR',
        'Death Stranding VR',
        'Life is Strange: BtS',
        'Watch Dogs Legion VR',
        'Road to Vostok VR'
    )
    'tumbleweed' = @(
        'Red Dead Redemption VR',
        'Borderlands GOTY Enhanced',
        'Fallout 4 VR',
        'Sunrise GP VR',
        'Risk of Rain 2',
        'Redneck Rampage VR'
    )
    'bats' = @(
        'RE Village VR',
        'Hogwarts Legacy VR',
        'Dark Souls Remastered',
        'Diablo II: Resurrected',
        'Blood VR',
        'Amnesia VR',
        'Lunacid VR',
        'Little Witch Nobeta VR',
        'Ghosts n Goblins Resurrection VR',
        'Arx Fatalis VR',
        'Heretic VR',
        'Hexen VR',
        'Tormented Souls VR',
        'Witcher 3 VR'
    )
    'moths' = @(
        'Outlast VR',
        'Silent Hill VR',
        'Silent Hill 3 VR',
        'Firewatch VR',
        'Sons of the Forest',
        'Days Gone VR',
        'TLOU Part I VR',
        'TLOU Part II VR',
        'Project Zomboid VR',
        '7 Days to Die VR',
        'Stray VR',
        'Paranoia Place VR',
        'The Dark Mod VR'
    )
    'jellyfish' = @(
        'Subnautica VR',
        'Subnautica: Below Zero',
        'Another Crab''s Treasure',
        'BioShock Remastered',
        'BioShock 2 Remastered',
        'SOMA VR',
        'Dredge VR',
        'Raft VR',
        'Avatar: Frontiers of Pandora VR',
        'How to Fish XR'
    )
    'kelp' = @(
        'Subnautica VR',
        'Subnautica: Below Zero',
        'Another Crab''s Treasure',
        'Raft VR',
        'Dredge VR',
        'How to Fish XR',
        'SOMA VR'
    )
    'flakes' = @(
        'Skyrim VR',
        'Valheim VR',
        'SnowRunner VR',
        'Subnautica: Below Zero',
        'Far Cry 4 VR',
        'theHunter: Call of the Wild VR',
        'Witcher 3 VR',
        'PEAK VR',
        'Stardew Valley VR',
        'Dinkum VR',
        'Kingdom Come: Deliverance II VR'
    )
    'spotlights' = @(
        'Trombone Champ VR',
        'Metal: Hellsinger VR',
        'Sayonara Wild Hearts',
        'Bomb Rush Cyberfunk',
        'Street Fighter 6 VR',
        'GTA Vice City VR',
        'Saints Row: The Third VR',
        'Neon White VR',
        'Content Warning VR',
        'R.E.P.O. VR',
        'Retrowave 2 VR'
    )
    'fireworks' = @(
        'Mario Kart 64 VR',
        'Mario Kart Wii VR',
        'Super Mario 3D World VR',
        'Forza Horizon 5 VR',
        'Forza Horizon 6 VR',
        'Trombone Champ VR',
        'Stardew Valley VR',
        'Saints Row: The Third VR',
        'Sonic P-06 VR',
        'Kunitsu-Gami: Path of the Goddess VR',
        'Ghost of Tsushima VR',
        'Diddy Kong Racing VR',
        'A Kingdom for Keflings VR'
    )
    'balloons' = @(
        'Diddy Kong Racing VR',
        'Mario Kart Wii VR',
        'Tinykin VR',
        'A Kingdom for Keflings VR',
        'Garry''s Mod VR',
        'Stardew Valley VR',
        'Slime Rancher VR',
        'Big Walk VR',
        'PEAK VR',
        'High on Life VR',
        'Super Mario 3D World VR'
    )
    'fairydust' = @(
        'Legend of Zelda: Ocarina of Time VR',
        'Legend of Zelda: Twilight Princess',
        'Breath of the Wild VR',
        'Hogwarts Legacy VR',
        'Little Witch Nobeta VR',
        'Kunitsu-Gami: Path of the Goddess VR',
        'Final Fantasy XIV VR',
        'Yooka-Laylee VR',
        'Banjo-Kazooie VR',
        'Super Mario 64 VR',
        'Alba VR',
        'Tinykin VR',
        'Hollow Knight VR',
        'Mirage Feathers VR'
    )
    'paperplanes' = @(
        'Paperklay VR',
        'Stanley Parable VR',
        'Tinykin VR',
        'Life is Strange: BtS',
        'A Kingdom for Keflings VR',
        'Big Walk VR',
        'Apollo Justice: Ace Attorney Trilogy VR',
        'Firewatch VR'
    )
    'dice' = @(
        'Gloomhaven VR',
        'Pathfinder: Kingmaker',
        'Warhammer 40K: Rogue Trader VR',
        'Echo Generation 2 VR',
        'Monster Hunter Stories 3 VR',
        'Pokemon Dramatic Shape VR',
        'Diablo II: Resurrected'
    )
    'gears' = @(
        'BioShock Infinite VR',
        'Dishonored VR',
        'Thief (2014) VR',
        'Techtonica VR',
        'Scrap Mechanic VR',
        'Shipbreaker VR',
        'Atomic Heart VR',
        'The Witness',
        'Stray VR',
        'Ratchet & Clank VR',
        'Portal 2 VR',
        'Arx Fatalis VR'
    )
    'helix' = @(
        'Atomic Heart VR',
        'BioShock Remastered',
        'BioShock 2 Remastered',
        'Singularity VR',
        'Resident Evil 7 VR',
        'Resident Evil 2R VR',
        'Resident Evil 3R VR',
        'Resident Evil 4R VR',
        'RE Village VR',
        'RE Requiem VR',
        'SOMA VR',
        'Black Mesa VR',
        'Half-Life VR',
        'Deus Ex: Human Revolution - DC',
        'Cruelty Squad VR',
        'Prey (2006) VR'
    )
    'toxicgas' = @(
        'Anomaly VR',
        'Anomaly GAMMA',
        'Fallout 4 VR',
        'Half-Life VR',
        'Black Mesa VR',
        'Black Mesa Source VR',
        'Left 4 Dead 2 VR',
        '7 Days to Die VR',
        'Project Zomboid VR',
        'TLOU Part I VR',
        'TLOU Part II VR',
        'Ashes 2063 VR',
        'GTFO VR'
    )
    'claws' = @(
        'Left 4 Dead 2 VR',
        'Killing Floor 2 VR',
        'Dino Trauma VR',
        'Turok VR',
        'Far Cry Primal VR',
        'Monster Hunter Rise VR',
        'Monster Hunter Wilds',
        'Witcher 3 VR',
        'Sons of the Forest',
        '7 Days to Die VR',
        'Days Gone VR',
        'Project Zomboid VR',
        'Aliens versus Predator VR'
    )
    'glasscracks' = @(
        'Max Payne 2 VR',
        'F.E.A.R. VR',
        'Receiver VR',
        'Receiver 2 VR',
        'Ready Or Not VR',
        'Call of Duty 4 VR',
        'GoldenEye 007 VR',
        'Perfect Dark VR',
        'House of the Dead Remake VR',
        'House of the Dead 2 Remake VR',
        'Virtua Cop 2 VR',
        'I Can Gun VR',
        'Saints Row: The Third VR'
    )
    'footprints' = @(
        'Journey VR',
        'Death Stranding VR',
        'Big Walk VR',
        'Firewatch VR',
        'PEAK VR',
        'Skyrim VR',
        'The Witness',
        'Kingdom Come: Deliverance II VR',
        'Outward DE VR',
        'Driftwood VR'
    )
    'pawprints' = @(
        'Stray VR',
        'theHunter: Call of the Wild VR',
        'Far Cry Primal VR',
        'Grounded VR',
        'Dinkum VR',
        'Slime Rancher VR'
    )
    'skybow' = @(
        'Slime Rancher VR',
        'Mario Kart 64 VR',
        'Mario Kart Wii VR',
        'Super Mario 3D World VR',
        'Tinykin VR',
        'Flower VR',
        'Lunistice VR',
        'Yooka-Laylee VR',
        'Ring Racers VR',
        'Sonic Robo Blast 2 VR',
        'Sayonara Wild Hearts'
    )
    'lanterns' = @(
        'Ghost of Tsushima VR',
        'Kunitsu-Gami: Path of the Goddess VR',
        'Onimusha 2 VR',
        'Final Fantasy XIV VR',
        'Shenmue I & II',
        'Little Witch Nobeta VR',
        'Stardew Valley VR',
        'Hogwarts Legacy VR',
        'Judgment VR',
        'FF VII Rebirth VR',
        'Mirage Feathers VR'
    )
    'arrows' = @(
        'Mount & Blade II: Bannerlord VR',
        'Kingdom Come: Deliverance VR',
        'Kingdom Come: Deliverance II VR',
        'Ghost of Tsushima VR',
        'Assassin''s Creed Odyssey VR',
        'Assassin''s Creed Valhalla VR',
        'Far Cry Primal VR',
        'Horizon Zero Dawn VR',
        'Horizon Forbidden West VR',
        'Dragon''s Dogma 2 VR',
        'Skyrim VR',
        'Witcher 3 VR',
        'Gothic II VR',
        'Horizon Zero Dawn Remastered VR'
    )
    'checkered' = @(
        'Forza Horizon 5 VR',
        'Forza Horizon 6 VR',
        'Gran Turismo 2 PCVR',
        'TrackMania Nations Forever',
        'TrackMania United Forever',
        'Circuit Superstars VR',
        'New Star GP VR',
        'Sunrise GP VR',
        'Horizon Chase Turbo',
        'Moto Rush Reborn VR',
        'Art of Rally VR',
        'Richard Burns Rally VR',
        'Star Racer VR',
        'F-Zero X VR'
    )
    'driftsmoke' = @(
        'Forza Horizon 5 VR',
        'Forza Horizon 6 VR',
        'Grand Theft Auto V VR',
        'Road Redemption VR',
        'Decimate Drive VR',
        'Retrowave 2 VR',
        'GTA Vice City VR',
        'Moto Rush Reborn VR',
        'Gran Turismo 2 PCVR'
    )
    'focuslines' = @(
        'Street Fighter 6 VR',
        'Devil May Cry 5 VR',
        'Judgment VR',
        'Ghostwire: Tokyo VR',
        'Sonic P-06 VR',
        'Neon White VR',
        'Kunitsu-Gami: Path of the Goddess VR',
        'Little Witch Nobeta VR',
        'Pokemon Dramatic Shape VR',
        'Mega Man Star Force Legacy VR',
        'Monster Hunter Stories 3 VR',
        'Onimusha 2 VR'
    )
    'runes' = @(
        'Valheim VR',
        'Assassin''s Creed Valhalla VR',
        'Skyrim VR',
        'Elden Ring',
        'Elden Ring VR',
        'Dark Souls III VR',
        'Witcher 3 VR',
        'Gothic II VR',
        'Diablo II: Resurrected',
        'Hexen VR',
        'Final Fantasy XIV VR',
        'Mage Arena VR',
        'Arx Fatalis VR',
        'Morrowind VR'
    )
    'jungle' = @(
        'Far Cry VR',
        'Far Cry 6 VR',
        'Far Cry Primal VR',
        'Crysis VR',
        'Turok VR',
        'Uncharted: Legacy of Thieves VR',
        'Avatar: Frontiers of Pandora VR',
        'Horizon Zero Dawn VR',
        'Tomb Raider 1 VR',
        'Indiana Jones: Great Circle VR',
        'Dino Trauma VR',
        'Grounded VR',
        'Raft VR'
    )
    'skulls' = @(
        'Doom VR',
        'Doom 2 VR',
        'DOOM (2016) VR',
        'Painkiller Black Edition',
        'Painkiller: Overdose VR',
        'Blood VR',
        'Diablo II: Resurrected',
        'Heretic VR',
        'Hexen VR',
        'Shadow Warrior VR',
        'Dusk HD (DLC) VR',
        'ULTRAKILL VR',
        'Metal: Hellsinger VR',
        'Ghosts n Goblins Resurrection VR'
    )
}

# ------------------------------------------------------------
# Pure helpers (no WPF) - testable on any host
# ------------------------------------------------------------

# Catalog title -> list of fitting new effect names.
function global:Get-BannerFxExtraIndex {
    if ($global:BannerFxExtraIndex) { return $global:BannerFxExtraIndex }
    $idx = @{}
    foreach ($fx in $global:BannerFxExtraGames.Keys) {
        foreach ($title in $global:BannerFxExtraGames[$fx]) {
            if (-not $idx.ContainsKey($title)) { $idx[$title] = New-Object System.Collections.ArrayList }
            [void]$idx[$title].Add($fx)
        }
    }
    $global:BannerFxExtraIndex = $idx
    return $idx
}

function global:Get-BannerFxExtraFor {
    param($Game)
    if (-not $Game) { return @() }
    $idx = Get-BannerFxExtraIndex
    $t = [string]$Game.Title
    if ($t -and $idx.ContainsKey($t)) { return @($idx[$t]) }
    return @()
}

function global:Test-BannerFxExtraName {
    param([string]$Effect)
    return ($Effect -and $global:BannerFxExtraGames.Contains($Effect))
}

# Round 2 gets a separate 30% slice when it fits the game. Round 1 keeps
# its established 40% slice; all remaining rolls use the original pool.
function global:Select-BannerFxExtra {
    param($Game, [double]$Roll, [double]$Pick)
    $cands = @(Get-BannerFxExtraFor -Game $Game)
    if ($cands.Count -eq 0) { return $null }
    $round2 = @($cands | Where-Object { $global:BannerFxExtraRound2 -contains $_ })
    $round1 = @($cands | Where-Object { $global:BannerFxExtraRound2 -notcontains $_ })
    $chosen = @()
    if ($round2.Count -gt 0 -and $Roll -lt [double]$global:BannerFxExtraConfig.Round2Chance) {
        $chosen = $round2
    } elseif ($round1.Count -gt 0) {
        $start = if ($round2.Count -gt 0) { [double]$global:BannerFxExtraConfig.Round2Chance } else { 0.0 }
        if ($Roll -ge $start -and $Roll -lt ($start + [double]$global:BannerFxExtraConfig.GameChance)) { $chosen = $round1 }
    }
    if ($chosen.Count -eq 0) { return $null }
    $i = [Math]::Min($chosen.Count - 1, [int][Math]::Floor($Pick * $chosen.Count))
    return $chosen[$i]
}

function global:Resolve-BannerFxExtraFallback {
    param([string]$Effect)
    if ($global:BannerFxExtraFallback.ContainsKey($Effect)) { return $global:BannerFxExtraFallback[$Effect] }
    return 'motes'
}

# Keep the scanner's entry and exit distance fixed in pixels at every width.
function global:Get-BfxScanTravel {
    param([double]$Width)
    if ($Width -lt 20) { throw 'A measured banner width is required.' }
    $edge = 48.0
    return [pscustomobject]@{ From=(-$edge); To=($Width+$edge); Seconds=(($Width+2*$edge)/260.0) }
}


# Everything below needs WPF. On a host without it (tests, Linux pwsh)
# the data and pure helpers above stay available.
if (-not ('System.Windows.Media.Brush' -as [type])) { return }

# ------------------------------------------------------------
# WPF building blocks
# ------------------------------------------------------------
$global:BfxP = @{
    X  = [System.Windows.Media.TranslateTransform]::XProperty
    Y  = [System.Windows.Media.TranslateTransform]::YProperty
    SX = [System.Windows.Media.ScaleTransform]::ScaleXProperty
    SY = [System.Windows.Media.ScaleTransform]::ScaleYProperty
    A  = [System.Windows.Media.RotateTransform]::AngleProperty
    O  = [System.Windows.UIElement]::OpacityProperty
}

function global:New-BfxColor {
    param([string]$Hex, [double]$A = 1.0)
    $c = [System.Windows.Media.ColorConverter]::ConvertFromString($Hex)
    $al = [byte][Math]::Max(0, [Math]::Min(255, [int][Math]::Round($A * 255)))
    return [System.Windows.Media.Color]::FromArgb($al, $c.R, $c.G, $c.B)
}

function global:New-BfxBrush {
    param([string]$Hex, [double]$A = 1.0)
    $b = New-Object System.Windows.Media.SolidColorBrush (New-BfxColor $Hex $A)
    $b.Freeze()
    return $b
}

# Soft round light: bright core fading to transparent.
function global:New-BfxGlowBrush {
    param([string]$Hex, [double]$A = 1.0)
    $g = New-Object System.Windows.Media.RadialGradientBrush
    [void]$g.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BfxColor $Hex $A), 0.0))
    [void]$g.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BfxColor $Hex ($A * 0.45)), 0.35))
    [void]$g.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BfxColor $Hex 0.0), 1.0))
    $g.Freeze()
    return $g
}

# Linear gradient from @(offset, hex, alpha) triples; vertical unless -Horizontal.
function global:New-BfxLinear {
    param([object[]]$Stops, [switch]$Horizontal, [switch]$NoFreeze)
    $g = New-Object System.Windows.Media.LinearGradientBrush
    $g.StartPoint = [System.Windows.Point]::new(0, 0)
    $g.EndPoint = if ($Horizontal) { [System.Windows.Point]::new(1, 0) } else { [System.Windows.Point]::new(0, 1) }
    foreach ($s in $Stops) { [void]$g.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BfxColor $s[1] ([double]$s[2])), [double]$s[0])) }
    if (-not $NoFreeze) { $g.Freeze() }
    return $g
}

function global:New-BfxEllipse {
    param([double]$W, [double]$H, $Fill, $Stroke = $null, [double]$Thick = 0)
    $e = New-Object System.Windows.Shapes.Ellipse
    $e.Width = $W; $e.Height = $H; $e.IsHitTestVisible = $false
    if ($Fill) { $e.Fill = $Fill }
    if ($Stroke) { $e.Stroke = $Stroke; $e.StrokeThickness = $Thick }
    return $e
}

function global:New-BfxRect {
    param([double]$W, [double]$H, $Fill, [double]$Radius = 0)
    $r = New-Object System.Windows.Shapes.Rectangle
    $r.Width = $W; $r.Height = $H; $r.Fill = $Fill; $r.IsHitTestVisible = $false
    if ($Radius -gt 0) { $r.RadiusX = $Radius; $r.RadiusY = $Radius }
    return $r
}

# Glow element centred on its own position (size = diameter).
function global:New-BfxGlow {
    param([double]$Size, [string]$Hex, [double]$A = 1.0)
    $e = New-BfxEllipse $Size $Size (New-BfxGlowBrush $Hex $A)
    $e.Margin = [System.Windows.Thickness]::new(-$Size / 2, -$Size / 2, 0, 0)
    return $e
}

function global:New-BfxPoint { param([double]$X, [double]$Y) return [System.Windows.Point]::new($X, $Y) }

# StreamGeometry built in code (no culture-dependent path strings).
# $Draw gets the StreamGeometryContext.
function global:New-BfxGeo {
    param([scriptblock]$Draw, [switch]$EvenOdd)
    $g = New-Object System.Windows.Media.StreamGeometry
    if ($EvenOdd) { $g.FillRule = [System.Windows.Media.FillRule]::EvenOdd }
    $c = $g.Open()
    try { & $Draw $c } finally { $c.Close() }
    $g.Freeze()
    return $g
}

function global:New-BfxPath {
    param($Geometry, $Fill = $null, $Stroke = $null, [double]$Thick = 1)
    $p = New-Object System.Windows.Shapes.Path
    $p.Data = $Geometry; $p.IsHitTestVisible = $false
    if ($Fill) { $p.Fill = $Fill }
    if ($Stroke) { $p.Stroke = $Stroke; $p.StrokeThickness = $Thick; $p.StrokeStartLineCap = 'Round'; $p.StrokeEndLineCap = 'Round'; $p.StrokeLineJoin = 'Round' }
    return $p
}

# Scale -> Rotate -> Translate on one element, origin in its centre.
function global:Set-BfxTransforms {
    param($El, [double]$OX = 0.5, [double]$OY = 0.5)
    # Paths are drawn around (0,0): transform around that point, not
    # around the middle of their (partly negative) bounds.
    if ($El -is [System.Windows.Shapes.Path] -and -not $PSBoundParameters.ContainsKey('OX')) { $OX = 0; $OY = 0 }
    $s = New-Object System.Windows.Media.ScaleTransform 1, 1
    $r = New-Object System.Windows.Media.RotateTransform 0
    $t = New-Object System.Windows.Media.TranslateTransform 0, 0
    $g = New-Object System.Windows.Media.TransformGroup
    [void]$g.Children.Add($s); [void]$g.Children.Add($r); [void]$g.Children.Add($t)
    $El.RenderTransformOrigin = [System.Windows.Point]::new($OX, $OY)
    $El.RenderTransform = $g
    return [pscustomobject]@{ S = $s; R = $r; T = $t }
}

# Looping From->To animation. Phase 0..1 offsets the loop start.
function global:Start-BfxAnim {
    param($Target, $Prop, [double]$From, [double]$To, [double]$Sec, [double]$Phase = 0, [switch]$Reverse, [switch]$Ease)
    $a = New-Object System.Windows.Media.Animation.DoubleAnimation
    $a.From = $From; $a.To = $To
    $a.Duration = [System.Windows.Duration]::new([TimeSpan]::FromSeconds([Math]::Max(0.05, $Sec)))
    $a.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $a.AutoReverse = [bool]$Reverse
    if ($Ease) { $e = New-Object System.Windows.Media.Animation.SineEase; $e.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseInOut; $a.EasingFunction = $e }
    $cycle = if ($Reverse) { 2 * $Sec } else { $Sec }
    $a.BeginTime = [TimeSpan]::FromSeconds(-($Phase * $cycle))
    $Target.BeginAnimation($Prop, $a)
}

# Looping key-frame animation. $Keys = @(@(fraction 0..1, value), ...).
function global:Start-BfxKeys {
    param($Target, $Prop, [object[]]$Keys, [double]$Sec, [double]$Phase = 0, [switch]$Discrete)
    $a = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
    $a.Duration = [System.Windows.Duration]::new([TimeSpan]::FromSeconds([Math]::Max(0.05, $Sec)))
    $a.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    foreach ($k in $Keys) {
        $kt = [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds([double]$k[0] * $Sec))
        if ($Discrete) { [void]$a.KeyFrames.Add([System.Windows.Media.Animation.DiscreteDoubleKeyFrame]::new([double]$k[1], $kt)) }
        else { [void]$a.KeyFrames.Add([System.Windows.Media.Animation.LinearDoubleKeyFrame]::new([double]$k[1], $kt)) }
    }
    $a.BeginTime = [TimeSpan]::FromSeconds(-($Phase * $Sec))
    $Target.BeginAnimation($Prop, $a)
}

# A flash that is visible for $On (fraction of the period) once per
# period at offset $At, otherwise invisible.
function global:Start-BfxFlash {
    param($El, [double]$Sec, [double]$At, [double]$On, [double]$Peak = 1.0, [double]$Phase = 0)
    $a0 = [Math]::Max(0.0, [Math]::Min(0.97, $At)); $a1 = [Math]::Min(0.995, $a0 + 0.01); $a2 = [Math]::Min(0.999, $a0 + $On)
    Start-BfxKeys $El $global:BfxP.O @(@(0, 0), @($a0, 0), @($a1, $Peak), @($a2, 0), @(1, 0)) $Sec $Phase
}

# Stage = one effect canvas on a banner. Items placed by width fraction
# (Fx) or drifting horizontally at Speed px/s across the real width.
function global:New-BfxStage {
    param([string]$BannerName)
    $banner = $global:window.FindName($BannerName)
    if (-not $banner -or -not $banner.Child) { return $null }
    $grid = $banner.Child
    if ($grid -isnot [System.Windows.Controls.Grid]) { return $null }
    $canvas = New-Object System.Windows.Controls.Canvas
    $canvas.IsHitTestVisible = $false; $canvas.ClipToBounds = $true
    $canvas.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $canvas.VerticalAlignment = [System.Windows.VerticalAlignment]::Stretch
    # Remember who built this stage and for which height, so a banner
    # height change (list size S/M/L) can rebuild the effect to fit.
    $fn = $null; $builtH = 0.0
    try { $caller = (Get-PSCallStack)[1]; $fn = [string]$caller.Command; $builtH = [double]$caller.InvocationInfo.BoundParameters['BannerH'] } catch { }
    return [pscustomobject]@{ Grid = $grid; Canvas = $canvas; Items = (New-Object System.Collections.ArrayList); R = (New-Object System.Random); Extra = $null; Fn = $fn; BuiltH = $builtH; BannerName = $BannerName }
}

function global:Add-BfxItem {
    param($Stage, $El, [double]$Fx = -1, [double]$Top = [double]::NaN, [double]$Speed = 0, [double]$Phase = 0, [double]$Margin = 60, $T = $null, [double]$OffsetX = 0)
    if (-not [double]::IsNaN($Top)) { [System.Windows.Controls.Canvas]::SetTop($El, $Top) }
    [void]$Stage.Canvas.Children.Add($El)
    [void]$Stage.Items.Add([pscustomobject]@{ El = $El; Fx = $Fx; Speed = $Speed; Phase = $Phase; Margin = $Margin; T = $T; OffsetX = $OffsetX })
}

function global:Complete-BfxStage {
    param($Stage)
    $canvas = $Stage.Canvas; $items = $Stage.Items; $extra = $Stage.Extra
    $reflow = {
        $cw = $canvas.ActualWidth
        if ($cw -lt 20) { return }
        foreach ($it in $items) {
            if ($it.Speed -ne 0 -and $it.T) {
                [System.Windows.Controls.Canvas]::SetLeft($it.El, $it.OffsetX)
                $from = -$it.Margin; $to = $cw + $it.Margin
                if ($it.Speed -lt 0) { $tmp = $from; $from = $to; $to = $tmp }
                $dur = ($cw + 2 * $it.Margin) / [Math]::Abs($it.Speed)
                Start-BfxAnim $it.T $global:BfxP.X $from $to $dur $it.Phase
            } elseif ($it.Fx -ge 0) {
                [System.Windows.Controls.Canvas]::SetLeft($it.El, $it.Fx * $cw + $it.OffsetX)
            }
        }
        if ($extra) { & $extra $cw }
    }.GetNewClosure()
    $canvas.Add_SizeChanged($reflow)
    & $reflow
    # Height changed (S/M/L switch, window layout): build the same effect
    # again for the new height and swap it in at the same place.
    $refitState = [pscustomobject]@{
        Grid = $Stage.Grid; Canvas = $canvas; Function = $Stage.Fn
        BuiltH = $Stage.BuiltH; BannerName = $Stage.BannerName; Busy = $false
    }
    $refit = {
        param($sender, $e)
        if (-not $e.HeightChanged) { return }
        $current = $refitState
        $nh = $current.Canvas.ActualHeight
        if (-not $current.Function -or $nh -lt 20 -or [Math]::Abs($nh - $current.BuiltH) -lt 4) { return }
        if ($current.Busy -or -not $current.Grid.Children.Contains($current.Canvas)) { return }
        $current.Busy = $true
        $workState = $current
        $workHeight = $nh
        $work = {
            try {
                if (-not $workState.Grid.Children.Contains($workState.Canvas)) { return }
                $global:BfxReplace = $workState.Canvas
                & $workState.Function -BannerName $workState.BannerName -BannerH $workHeight
            } catch { } finally {
                $global:BfxReplace = $null
                $workState.Busy = $false
            }
            if (-not $workState.Grid.Children.Contains($workState.Canvas) -and
                (Get-Command Update-BannerGlassFxPlacement -ErrorAction SilentlyContinue)) {
                try { Update-BannerGlassFxPlacement -BannerName $workState.BannerName } catch { }
            }
        }.GetNewClosure()
        [void]$current.Canvas.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]$work)
    }.GetNewClosure()
    $canvas.Add_SizeChanged($refit)
    $canvas.Tag = 'BannerFx'
    $old = $global:BfxReplace
    if ($old -and $Stage.Grid.Children.Contains($old)) {
        $idx = $Stage.Grid.Children.IndexOf($old)
        $Stage.Grid.Children.Insert($idx, $canvas)
        $Stage.Grid.Children.Remove($old)
        if ($old.Effect) { $canvas.Effect = $old.Effect; $old.Effect = $null }
    } else {
        $idx = [Math]::Min(1, $Stage.Grid.Children.Count)
        $Stage.Grid.Children.Insert($idx, $canvas)
    }
}

# Pick one of the given values with the stage's random source.
function global:Get-BfxPick { param($Stage, [object[]]$From) return $From[$Stage.R.Next(0, $From.Count)] }
function global:Get-BfxRnd { param($Stage, [double]$Min = 0, [double]$Max = 1) return $Min + $Stage.R.NextDouble() * ($Max - $Min) }

# Small monospace label (HUD text).
function global:New-BfxText {
    param([string]$Text, [string]$Hex, [double]$A = 1.0, [double]$Size = 10)
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text; $tb.Foreground = (New-BfxBrush $Hex $A); $tb.FontSize = $Size; $tb.IsHitTestVisible = $false
    $tb.FontFamily = New-Object System.Windows.Media.FontFamily 'Consolas'
    return $tb
}

# Soft neon glow on one element.
function global:Set-BfxShadow {
    param($El, [string]$Hex, [double]$Blur = 10)
    $sh = New-Object System.Windows.Media.Effects.DropShadowEffect; $sh.Color = New-BfxColor $Hex; $sh.BlurRadius = $Blur; $sh.ShadowDepth = 0
    $El.Effect = $sh
}

# Place an element inside a group canvas.
function global:Set-BfxAt { param($El, [double]$X, [double]$Y) [System.Windows.Controls.Canvas]::SetLeft($El, $X); [System.Windows.Controls.Canvas]::SetTop($El, $Y); return $El }


# ------------------------------------------------------------
# Effects. Each one: Add-Bfx<Name> -BannerName -BannerH
# ------------------------------------------------------------

function global:Add-BfxFireflies {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 30; $i++) {
        $sz = Get-BfxRnd $S 12 26
        $g = New-Object System.Windows.Controls.Canvas
        $halo = New-BfxGlow $sz '#d8ff6a' 0.55; $core = New-BfxGlow 5 '#f4ffc0' 1.0
        [void]$g.Children.Add($halo); [void]$g.Children.Add($core)
        $tf = Set-BfxTransforms $g
        Start-BfxAnim $tf.T $global:BfxP.X (-(Get-BfxRnd $S 10 30)) (Get-BfxRnd $S 10 30) (Get-BfxRnd $S 4 9) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxAnim $tf.T $global:BfxP.Y (-(Get-BfxRnd $S 6 14)) (Get-BfxRnd $S 6 14) (Get-BfxRnd $S 3 7) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxKeys $g $global:BfxP.O @(@(0, 0.15), @(0.35, 1), @(0.6, 0.6), @(1, 0.15)) (Get-BfxRnd $S 2.5 5) (Get-BfxRnd $S)
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S) -Top (Get-BfxRnd $S ($H * 0.08) ($H * 0.92))
    }
    Complete-BfxStage $S
}

# Falling, tumbling flakes (leaves, petals, confetti, papers share this).
function global:Add-BfxFallers {
    param($S, [double]$H, [int]$Count, [scriptblock]$Make, [double]$FallMin, [double]$FallMax, [double]$DriftMin, [double]$DriftMax, [double]$SpinSec = 3, [switch]$Flip)
    for ($i = 0; $i -lt $Count; $i++) {
        $el = & $Make $i
        $tf = Set-BfxTransforms $el
        $fall = Get-BfxRnd $S $FallMin $FallMax
        Start-BfxAnim $tf.T $global:BfxP.Y (-20) ($H + 20) (($H + 40) / $fall) (Get-BfxRnd $S)
        Start-BfxAnim $tf.R $global:BfxP.A 0 (Get-BfxPick $S @(360, -360)) (Get-BfxRnd $S ($SpinSec * 0.6) ($SpinSec * 1.6)) (Get-BfxRnd $S)
        if ($Flip) { Start-BfxAnim $tf.S $global:BfxP.SY 1 0.15 (Get-BfxRnd $S 0.5 1.2) (Get-BfxRnd $S) -Reverse -Ease }
        $drift = Get-BfxRnd $S $DriftMin $DriftMax
        if ([Math]::Abs($drift) -gt 0.5) { Add-BfxItem $S $el -Top 0 -Speed $drift -Phase (Get-BfxRnd $S) -T $tf.T -Margin 30 }
        else { Add-BfxItem $S $el -Fx (Get-BfxRnd $S) -Top 0 }
    }
}

function global:Add-BfxLeaves {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }
    $vein = New-BfxBrush '#3c1908' 0.6
    Add-BfxFallers $S $BannerH 24 {
        $sz = Get-BfxRnd $S 6 11
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint (-$sz) 0), $true, $true); $c.QuadraticBezierTo((New-BfxPoint 0 (-$sz * 0.75)), (New-BfxPoint $sz 0), $true, $false); $c.QuadraticBezierTo((New-BfxPoint 0 ($sz * 0.75)), (New-BfxPoint (-$sz) 0), $true, $false) }.GetNewClosure()
        $p = New-BfxPath $geo (New-BfxBrush (Get-BfxPick $S @('#d9622b', '#e9a23b', '#b8401f', '#c98a2e')) 0.92) $vein 0.7
        $p
    }.GetNewClosure() 18 40 18 40 3 -Flip
    Complete-BfxStage $S
}

function global:Add-BfxPetals {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }
    $pink = New-BfxBrush '#ffb7d6' 0.82
    Add-BfxFallers $S $BannerH 42 {
        $sz = Get-BfxRnd $S 3 6
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 (-$sz)), $true, $true); $c.QuadraticBezierTo((New-BfxPoint $sz 0), (New-BfxPoint 0 $sz), $true, $false); $c.QuadraticBezierTo((New-BfxPoint (-$sz) 0), (New-BfxPoint 0 (-$sz)), $true, $false) }.GetNewClosure()
        New-BfxPath $geo $pink
    }.GetNewClosure() 6 12 20 52 4 -Flip
    Complete-BfxStage $S
}

function global:Add-BfxFlowerwind {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $cols = @('#ff6fa8', '#ffd24d', '#7fd8ff', '#ffffff', '#c07bff')
    for ($i = 0; $i -lt 56; $i++) {
        $sz = Get-BfxRnd $S 2.5 6
        $e = New-BfxEllipse ($sz * 2) $sz (New-BfxBrush (Get-BfxPick $S $cols) 0.9)
        $tf = Set-BfxTransforms $e
        Start-BfxAnim $tf.R $global:BfxP.A 0 360 (Get-BfxRnd $S 1.5 3) (Get-BfxRnd $S)
        Start-BfxAnim $tf.T $global:BfxP.Y (-$H * 0.3) ($H * 0.3) (Get-BfxRnd $S 2.5 4) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $e -Top (Get-BfxRnd $S ($H * 0.3) ($H * 0.7)) -Speed (Get-BfxRnd $S 70 120) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 20
    }
    Complete-BfxStage $S
}

function global:Add-BfxLightning {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $wash = New-BfxRect 4000 $H (New-BfxBrush '#aabeff' 0.16)
    Add-BfxItem $S $wash -Fx 0 -Top 0
    $flashes = @()
    for ($b = 0; $b -lt 4; $b++) {
        $geo = New-BfxGeo {
            param($c)
            $x = 0.0; $y = -4.0; $c.BeginFigure((New-BfxPoint $x $y), $false, $false)
            $branchAt = @()
            while ($y -lt $H + 4) { $x += (Get-BfxRnd $S -17 17); $y += (Get-BfxRnd $S 8 20); $c.LineTo((New-BfxPoint $x $y), $true, $true); if ((Get-BfxRnd $S) -lt 0.35) { $branchAt += , @($x, $y) } }
            foreach ($bp in $branchAt) { $bx = $bp[0]; $by = $bp[1]; $c.BeginFigure((New-BfxPoint $bx $by), $false, $false); for ($k = 0; $k -lt 3; $k++) { $bx += (Get-BfxRnd $S -8 18); $by += (Get-BfxRnd $S 6 14); $c.LineTo((New-BfxPoint $bx $by), $true, $true) } }
        }.GetNewClosure()
        $p = New-BfxPath $geo $null (New-BfxBrush '#d4deff' 1.0) 2
        $sh = New-Object System.Windows.Media.Effects.DropShadowEffect; $sh.Color = New-BfxColor '#8fb0ff'; $sh.BlurRadius = 14; $sh.ShadowDepth = 0; $p.Effect = $sh
        $per = Get-BfxRnd $S 6 11; $at = Get-BfxRnd $S 0.1 0.9
        Start-BfxKeys $p $global:BfxP.O @(@(0, 0), @($at, 0), @(($at + 0.004), 1), @(($at + 0.012), 0.3), @(($at + 0.018), 1), @(($at + 0.05), 0), @(1, 0)) $per
        Add-BfxItem $S $p -Fx (Get-BfxRnd $S 0.15 0.9) -Top 0
        $flashes += , @($per, $at)
    }
    # the wash flashes with the first bolt
    Start-BfxKeys $wash $global:BfxP.O @(@(0, 0), @($flashes[0][1], 0), @(($flashes[0][1] + 0.004), 1), @(($flashes[0][1] + 0.05), 0), @(1, 0)) $flashes[0][0]
    Complete-BfxStage $S
}

function global:Add-BfxAsh {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $grey = New-BfxBrush '#a0968f' 0.55
    for ($i = 0; $i -lt 38; $i++) {
        $sz = Get-BfxRnd $S 1 2.6
        $r = New-BfxRect $sz $sz $grey; $tf = Set-BfxTransforms $r
        Start-BfxAnim $tf.T $global:BfxP.Y (-6) ($H + 6) (Get-BfxRnd $S 8 18) (Get-BfxRnd $S)
        Add-BfxItem $S $r -Top 0 -Speed (Get-BfxRnd $S 3 9) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 10
    }
    for ($i = 0; $i -lt 16; $i++) {
        $g = New-Object System.Windows.Controls.Canvas
        [void]$g.Children.Add((New-BfxGlow 14 '#ff6a1a' 0.75)); [void]$g.Children.Add((New-BfxGlow 3.5 '#ffd08a' 1.0))
        $tf = Set-BfxTransforms $g
        Start-BfxAnim $tf.T $global:BfxP.Y ($H + 8) (-10) (Get-BfxRnd $S 3 7) (Get-BfxRnd $S)
        Start-BfxAnim $tf.T $global:BfxP.X (-8) 8 (Get-BfxRnd $S 0.8 1.6) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxKeys $g $global:BfxP.O @(@(0, 0.3), @(0.25, 1), @(0.5, 0.5), @(0.75, 1), @(1, 0.2)) (Get-BfxRnd $S 0.4 0.9) (Get-BfxRnd $S)
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S) -Top 0
    }
    Complete-BfxStage $S
}

function global:Add-BfxFog {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 16; $i++) {
        $r = Get-BfxRnd $S ($H * 0.8) ($H * 1.6); $layer = $i % 2
        $e = New-BfxEllipse ($r * 2.2) $r (New-BfxGlowBrush '#b9c0cc' $(if ($layer) { 0.17 } else { 0.11 }))
        $e.Margin = [System.Windows.Thickness]::new(-$r * 1.1, -$r / 2, 0, 0)
        $tf = Set-BfxTransforms $e
        $sp = (Get-BfxRnd $S 6 14) * $(if ($layer) { 1 } else { -1 })
        Add-BfxItem $S $e -Top (Get-BfxRnd $S ($H * 0.2) $H) -Speed $sp -Phase (Get-BfxRnd $S) -T $tf.T -Margin ($r * 1.2)
    }
    Complete-BfxStage $S
}

function global:Add-BfxFlashlight {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $beam = New-Object System.Windows.Controls.Canvas
    $cone = New-BfxEllipse ($H * 2.2) ($H * 1.8) (New-BfxGlowBrush '#fff2d2' 0.42)
    $cone.Margin = [System.Windows.Thickness]::new(-$H * 1.1, -$H * 0.9, 0, 0)
    [void]$beam.Children.Add($cone)
    for ($i = 0; $i -lt 22; $i++) { $d = New-BfxEllipse 1.8 1.8 (New-BfxBrush '#fff3d0' 0.8); [System.Windows.Controls.Canvas]::SetLeft($d, (Get-BfxRnd $S (-$H * 0.6) ($H * 0.6))); [System.Windows.Controls.Canvas]::SetTop($d, (Get-BfxRnd $S (-$H * 0.5) ($H * 0.5))); $dt = Set-BfxTransforms $d; Start-BfxAnim $dt.T $global:BfxP.Y -4 4 (Get-BfxRnd $S 2 4) (Get-BfxRnd $S) -Reverse -Ease; [void]$beam.Children.Add($d) }
    $tf = Set-BfxTransforms $beam
    Start-BfxAnim $tf.T $global:BfxP.Y (-$H * 0.25) ($H * 0.25) 3.7 0.2 -Reverse -Ease
    Start-BfxKeys $beam $global:BfxP.O @(@(0, 1), @(0.62, 1), @(0.63, 0.25), @(0.64, 1), @(0.66, 0.2), @(0.68, 1), @(1, 1)) 7.3
    Add-BfxItem $S $beam -Top ($H * 0.5)
    $S.Extra = { param($cw) [System.Windows.Controls.Canvas]::SetLeft($beam, 0); Start-BfxAnim $tf.T $global:BfxP.X ($cw * 0.25) ($cw * 0.85) 7 0.3 -Reverse -Ease }.GetNewClosure()
    Complete-BfxStage $S
}

# Short bright streak flying across (tracers, lasers).
function global:New-BfxStreak {
    param([double]$Len, [string]$Hex, [double]$Thick, [string]$GlowHex)
    $r = New-BfxRect $Len $Thick (New-BfxLinear @(@(0, $Hex, 0), @(1, $Hex, 1)) -Horizontal) ($Thick / 2)
    $sh = New-Object System.Windows.Media.Effects.DropShadowEffect; $sh.Color = New-BfxColor $GlowHex; $sh.BlurRadius = 8; $sh.ShadowDepth = 0; $r.Effect = $sh
    return $r
}

function global:Add-BfxTracers {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($v = 0; $v -lt 4; $v++) {
        $y = Get-BfxRnd $S ($H * 0.2) ($H * 0.85); $dir = Get-BfxPick $S @(1, -1); $ang = Get-BfxRnd $S -9 9; $per = Get-BfxRnd $S 1.6 3.2; $ph = Get-BfxRnd $S
        for ($k = 0; $k -lt 4; $k++) {
            $streak = New-BfxStreak 46 '#ffe696' 2 '#ffb040'
            $tf = Set-BfxTransforms $streak; $tf.R.Angle = $ang; if ($dir -lt 0) { $tf.S.ScaleX = -1 }
            Add-BfxItem $S $streak -Top ($y + $k * 1.5) -Speed (900 * $dir) -Phase ($ph + $k * 0.04) -T $tf.T -Margin 600
        }
    }
    for ($m = 0; $m -lt 5; $m++) { $f = New-BfxGlow 44 '#ffb347' 0.7; Start-BfxFlash $f (Get-BfxRnd $S 1.5 3.5) (Get-BfxRnd $S 0.1 0.9) 0.05; Add-BfxItem $S $f -Fx (Get-BfxRnd $S 0.1 0.95) -Top ($H * 0.86) }
    Complete-BfxStage $S
}

function global:Add-BfxFlak {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 7; $i++) {
        $per = Get-BfxRnd $S 4 8; $at = Get-BfxRnd $S 0.05 0.6; $sz = Get-BfxRnd $S 0.7 1.3
        $boom = New-BfxGlow (110 * $sz) '#ff8a2a' 0.8; $tb = Set-BfxTransforms $boom
        Start-BfxKeys $boom $global:BfxP.O @(@(0, 0), @($at, 0), @(($at + 0.01), 1), @(($at + 0.2), 0), @(1, 0)) $per
        Start-BfxKeys $tb.S $global:BfxP.SX @(@(0, 0.5), @($at, 0.5), @(($at + 0.2), 1.3), @(1, 1.3)) $per
        Start-BfxKeys $tb.S $global:BfxP.SY @(@(0, 0.5), @($at, 0.5), @(($at + 0.2), 1.3), @(1, 1.3)) $per
        $core = New-BfxGlow (30 * $sz) '#fff0c0' 1.0
        Start-BfxKeys $core $global:BfxP.O @(@(0, 0), @($at, 0), @(($at + 0.01), 1), @(($at + 0.08), 0), @(1, 0)) $per
        $smoke = New-BfxGlow (60 * $sz) '#6a625c' 0.35; $ts = Set-BfxTransforms $smoke
        Start-BfxKeys $smoke $global:BfxP.O @(@(0, 0), @($at, 0), @(($at + 0.1), 0.8), @(($at + 0.38), 0), @(1, 0)) $per
        Start-BfxKeys $ts.T $global:BfxP.Y @(@(0, 0), @($at, 0), @(($at + 0.38), (-$H * 0.45)), @(1, (-$H * 0.45))) $per
        $fx = Get-BfxRnd $S 0.05 0.95
        foreach ($el in @($smoke, $boom, $core)) { Add-BfxItem $S $el -Fx $fx -Top ($H * 0.95) }
    }
    Complete-BfxStage $S
}

function global:Add-BfxPixels {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $cols = @('#ff004d', '#ffa300', '#ffec27', '#00e436', '#29adff', '#ff77a8')
    $hi = New-BfxBrush '#ffffff' 0.35
    for ($i = 0; $i -lt 48; $i++) {
        $sz = Get-BfxPick $S @(3, 4, 6)
        $g = New-Object System.Windows.Controls.Canvas
        [void]$g.Children.Add((New-BfxRect $sz $sz (New-BfxBrush (Get-BfxPick $S $cols) 1.0))); [void]$g.Children.Add((New-BfxRect ($sz / 2) ($sz / 2) $hi))
        [System.Windows.Media.RenderOptions]::SetEdgeMode($g, [System.Windows.Media.EdgeMode]::Aliased)
        $tf = Set-BfxTransforms $g
        Start-BfxAnim $tf.T $global:BfxP.Y ($H + 8) (-8) (Get-BfxRnd $S 4 12) (Get-BfxRnd $S)
        Start-BfxKeys $g $global:BfxP.O @(@(0, 1), @(0.34, 0), @(0.67, 1)) (Get-BfxRnd $S 0.6 1.0) (Get-BfxRnd $S) -Discrete
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S) -Top 0
    }
    Complete-BfxStage $S
}

function global:Add-BfxGlitch {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    # scanlines: tiled 1 px line every 3 px
    $dg = New-Object System.Windows.Media.GeometryDrawing
    $dg.Brush = New-BfxBrush '#78dcff' 0.06
    $dg.Geometry = New-Object System.Windows.Media.RectangleGeometry ([System.Windows.Rect]::new(0, 0, 4, 1))
    $db = New-Object System.Windows.Media.DrawingBrush $dg
    $db.TileMode = [System.Windows.Media.TileMode]::Tile; $db.Stretch = [System.Windows.Media.Stretch]::None
    $db.Viewport = [System.Windows.Rect]::new(0, 0, 4, 3); $db.ViewportUnits = [System.Windows.Media.BrushMappingMode]::Absolute
    $db.Viewbox = [System.Windows.Rect]::new(0, 0, 4, 3); $db.ViewboxUnits = [System.Windows.Media.BrushMappingMode]::Absolute
    Add-BfxItem $S (New-BfxRect 4000 $H $db) -Fx 0 -Top 0
    $band = New-BfxRect 4000 24 (New-BfxBrush '#78dcff' 0.06); $tb = Set-BfxTransforms $band
    Start-BfxAnim $tb.T $global:BfxP.Y (-30) ($H + 30) 4 0
    Add-BfxItem $S $band -Fx 0 -Top 0
    for ($i = 0; $i -lt 9; $i++) {
        $w = Get-BfxRnd $S 60 280; $hh = Get-BfxRnd $S 2 10; $per = Get-BfxRnd $S 1.6 4; $at = Get-BfxRnd $S 0.05 0.9
        $g = New-Object System.Windows.Controls.Canvas
        $red = New-BfxRect $w $hh (New-BfxBrush '#ff285a' 0.55); [System.Windows.Controls.Canvas]::SetLeft($red, -3)
        $cy = New-BfxRect $w $hh (New-BfxBrush '#28f0ff' 0.55); [System.Windows.Controls.Canvas]::SetLeft($cy, 3)
        $wl = New-BfxRect ($w * 0.6) 1 (New-BfxBrush '#ffffff' 0.4); [System.Windows.Controls.Canvas]::SetTop($wl, $hh / 2)
        [void]$g.Children.Add($red); [void]$g.Children.Add($cy); [void]$g.Children.Add($wl)
        Start-BfxFlash $g $per $at 0.06
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S 0 0.8) -Top (Get-BfxRnd $S 0 ($H - $hh))
    }
    Complete-BfxStage $S
}

function global:Add-BfxNeoncity {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $cols = @('#ff3fa4', '#22e6ff', '#9a5cff', '#ffb020')
    for ($i = 0; $i -lt 28; $i++) {
        $g = New-BfxGlow (Get-BfxRnd $S 20 60) (Get-BfxPick $S $cols) 0.4; $tf = Set-BfxTransforms $g
        Add-BfxItem $S $g -Top (Get-BfxRnd $S 0 $H) -Speed (-(Get-BfxRnd $S 20 90)) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 40
    }
    for ($i = 0; $i -lt 6; $i++) {
        $col = Get-BfxPick $S @('#ff3fa4', '#22e6ff')
        $sign = New-BfxRect (Get-BfxRnd $S 20 44) 6 $null 2; $sign.Stroke = New-BfxBrush $col 1.0; $sign.StrokeThickness = 2
        $sh = New-Object System.Windows.Media.Effects.DropShadowEffect; $sh.Color = New-BfxColor $col; $sh.BlurRadius = 12; $sh.ShadowDepth = 0; $sign.Effect = $sh
        Start-BfxKeys $sign $global:BfxP.O @(@(0, 1), @(0.70, 1), @(0.71, 0.1), @(0.73, 1), @(0.75, 0.1), @(0.78, 1), @(1, 1)) (Get-BfxRnd $S 3 7) (Get-BfxRnd $S)
        $tf = Set-BfxTransforms $sign
        Add-BfxItem $S $sign -Top (Get-BfxRnd $S 6 ($H * 0.6)) -Speed (-12) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 60
    }
    Complete-BfxStage $S
}

function global:Add-BfxRaindrops {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $drop = New-BfxBrush '#a9c4e0' 0.35; $shine = New-BfxBrush '#ffffff' 0.5
    for ($i = 0; $i -lt 64; $i++) {
        $r = Get-BfxRnd $S 0.8 2.4; $g = New-Object System.Windows.Controls.Canvas
        [void]$g.Children.Add((New-BfxEllipse ($r * 2) ($r * 2) $drop)); $hl = New-BfxEllipse ($r * 0.8) ($r * 0.8) $shine; [System.Windows.Controls.Canvas]::SetLeft($hl, $r * 0.4); [System.Windows.Controls.Canvas]::SetTop($hl, $r * 0.4); [void]$g.Children.Add($hl)
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S) -Top (Get-BfxRnd $S 0 $H)
    }
    for ($i = 0; $i -lt 6; $i++) {
        $r = Get-BfxRnd $S 2 3.4; $g = New-Object System.Windows.Controls.Canvas
        $trail = New-BfxRect ($r * 0.8) ($H * 0.6) (New-BfxLinear @(@(0, '#b4cde6', 0), @(1, '#b4cde6', 0.3))) ($r * 0.4)
        [System.Windows.Controls.Canvas]::SetLeft($trail, $r * 0.6); [System.Windows.Controls.Canvas]::SetTop($trail, -$H * 0.6 + $r)
        [void]$g.Children.Add($trail); [void]$g.Children.Add((New-BfxEllipse ($r * 2) ($r * 2.2) (New-BfxBrush '#c6dcf2' 0.65)))
        $tf = Set-BfxTransforms $g
        Start-BfxAnim $tf.T $global:BfxP.Y (-$H * 0.1) ($H * 1.7) (Get-BfxRnd $S 3 6) (Get-BfxRnd $S)
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S) -Top 0
    }
    Complete-BfxStage $S
}

function global:Add-BfxLighttrails {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 14; $i++) {
        $col = if ($i % 3) { '#ff2a3a' } else { '#ffffff' }
        $len = Get-BfxRnd $S 120 380
        $streak = New-BfxStreak $len $col 2.2 $col
        $tf = Set-BfxTransforms $streak
        Add-BfxItem $S $streak -Top (Get-BfxRnd $S ($H * 0.25) ($H * 0.95)) -Speed (Get-BfxRnd $S 300 800) -Phase (Get-BfxRnd $S) -T $tf.T -Margin ($len + 20) -OffsetX (-$len)
    }
    Complete-BfxStage $S
}

function global:Add-BfxDust {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 10; $i++) {
        $c = New-BfxGlow (Get-BfxRnd $S 70 140) '#c8a46e' 0.28; $tf = Set-BfxTransforms $c
        $per = Get-BfxRnd $S 6 12
        Start-BfxKeys $tf.T $global:BfxP.Y @(@(0, 0), @(1, (-$H * 0.35))) $per (Get-BfxRnd $S)
        Start-BfxKeys $c $global:BfxP.O @(@(0, 0), @(0.15, 1), @(1, 0)) $per (Get-BfxRnd $S)
        Add-BfxItem $S $c -Top ($H * (Get-BfxRnd $S 0.7 1.1)) -Speed (Get-BfxRnd $S 18 40) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 80
    }
    $grain = New-BfxBrush '#d6b88c' 0.8
    for ($i = 0; $i -lt 44; $i++) {
        $sz = Get-BfxRnd $S 0.8 3; $r = New-BfxRect $sz $sz $grain; $tf = Set-BfxTransforms $r
        $per = Get-BfxRnd $S 1.2 3
        Start-BfxKeys $tf.T $global:BfxP.Y @(@(0, 0), @(0.5, (-$H * (Get-BfxRnd $S 0.3 0.8))), @(1, (-$H * 0.1))) $per (Get-BfxRnd $S)
        Start-BfxKeys $r $global:BfxP.O @(@(0, 0.9), @(1, 0)) $per (Get-BfxRnd $S)
        Add-BfxItem $S $r -Top $H -Speed (Get-BfxRnd $S 80 200) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 20
    }
    Complete-BfxStage $S
}

function global:Add-BfxRadiation {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $veil = New-BfxRect 260 $H (New-BfxLinear @(@(0, '#78ff5a', 0), @(0.5, '#78ff5a', 0.12), @(1, '#78ff5a', 0)) -Horizontal); $tv = Set-BfxTransforms $veil
    Add-BfxItem $S $veil -Top 0 -Speed 70 -Phase 0 -T $tv.T -Margin 260
    for ($i = 0; $i -lt 40; $i++) {
        $g = New-Object System.Windows.Controls.Canvas
        [void]$g.Children.Add((New-BfxGlow 12 '#8dff5c' 0.75)); [void]$g.Children.Add((New-BfxGlow 3.5 '#e4ffd0' 1.0))
        Start-BfxFlash $g (Get-BfxRnd $S 0.6 2.4) (Get-BfxRnd $S 0.05 0.9) 0.12
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S) -Top (Get-BfxRnd $S 0 $H)
    }
    Complete-BfxStage $S
}


function global:Add-BfxMagic {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $R1 = $H * 0.42
    $holder = New-Object System.Windows.Controls.Canvas
    $stroke = New-BfxBrush '#c8aaff' 0.75
    $glowFx = New-Object System.Windows.Media.Effects.DropShadowEffect; $glowFx.Color = New-BfxColor '#b98cff'; $glowFx.BlurRadius = 12; $glowFx.ShadowDepth = 0
    $holder.Effect = $glowFx
    $rings = @(@(1.0, 0.18, $true), @(0.78, -0.25, $true), @(0.5, 0.12, $false))
    foreach ($rg in $rings) {
        $rr = $R1 * $rg[0]; $runes = $rg[2]
        $geo = New-BfxGeo {
            param($c)
            $c.BeginFigure((New-BfxPoint $rr 0), $false, $true)
            $c.ArcTo((New-BfxPoint (-$rr) 0), [System.Windows.Size]::new($rr, $rr), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false)
            $c.ArcTo((New-BfxPoint $rr 0), [System.Windows.Size]::new($rr, $rr), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false)
            if ($runes) {
                for ($j = 0; $j -lt 12; $j++) {
                    $a = $j * [Math]::PI * 2 / 12; $ca = [Math]::Cos($a); $sa = [Math]::Sin($a); $d = $rr - 7
                    $pt = { param($u, $v) New-BfxPoint ($ca * ($d + $v) - $sa * $u) ($sa * ($d + $v) + $ca * $u) }
                    $c.BeginFigure((& $pt -3 -3), $false, $false); $c.LineTo((& $pt 0 3), $true, $false); $c.LineTo((& $pt 3 -3), $true, $false)
                    $c.BeginFigure((& $pt 0 3), $false, $false); $c.LineTo((& $pt 0 -4), $true, $false)
                }
            } else {
                for ($j = 0; $j -le 3; $j++) { $a = $j * [Math]::PI * 2 / 3 - [Math]::PI / 2; $p = New-BfxPoint ([Math]::Cos($a) * $rr) ([Math]::Sin($a) * $rr); if ($j -eq 0) { $c.BeginFigure($p, $false, $true) } else { $c.LineTo($p, $true, $false) } }
            }
        }.GetNewClosure()
        $path = New-BfxPath $geo $null $stroke 1.4
        $rot = New-Object System.Windows.Media.RotateTransform 0; $path.RenderTransform = $rot
        Start-BfxAnim $rot $global:BfxP.A 0 (360 * [Math]::Sign($rg[1])) (360 / ([Math]::Abs($rg[1]) * 57.3)) 0
        [void]$holder.Children.Add($path)
    }
    for ($i = 0; $i -lt 26; $i++) {
        $sp = New-Object System.Windows.Controls.Canvas; [void]$sp.Children.Add((New-BfxGlow 10 '#c9a6ff' 0.7)); [void]$sp.Children.Add((New-BfxGlow 3 '#ffffff' 1.0))
        $a = Get-BfxRnd $S 0 6.283; $rr = $R1 * (Get-BfxRnd $S 0.2 1)
        [System.Windows.Controls.Canvas]::SetLeft($sp, [Math]::Cos($a) * $rr); [System.Windows.Controls.Canvas]::SetTop($sp, [Math]::Sin($a) * $rr)
        $tf = Set-BfxTransforms $sp; $per = Get-BfxRnd $S 2 4
        Start-BfxAnim $tf.T $global:BfxP.Y 0 (-$H * 0.6) $per (Get-BfxRnd $S)
        Start-BfxKeys $sp $global:BfxP.O @(@(0, 0), @(0.15, 1), @(1, 0)) $per (Get-BfxRnd $S)
        [void]$holder.Children.Add($sp)
    }
    Add-BfxItem $S $holder -Fx 0.62 -Top ($H * 0.5)
    Complete-BfxStage $S
}

function global:Add-BfxWisps {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($w = 0; $w -lt 6; $w++) {
        $speed = Get-BfxRnd $S 40 80; $ph = Get-BfxRnd $S; $amp = Get-BfxRnd $S 10 25; $bob = Get-BfxRnd $S 1.6 2.6; $bph = Get-BfxRnd $S; $y = Get-BfxRnd $S ($H * 0.2) ($H * 0.8)
        for ($k = 0; $k -lt 10; $k++) {
            $sz = 22 - $k * 1.6
            $g = New-Object System.Windows.Controls.Canvas; [void]$g.Children.Add((New-BfxGlow $sz '#9fd8ff' (0.45 * (1 - $k / 10))))
            if ($k -eq 0) { [void]$g.Children.Add((New-BfxGlow 6 '#ffffff' 1.0)) }
            $tf = Set-BfxTransforms $g
            $lag = $k * 0.06
            Start-BfxAnim $tf.T $global:BfxP.Y (-$amp) $amp $bob (((($bph - $lag / (2 * $bob)) % 1) + 1) % 1) -Reverse -Ease
            Add-BfxItem $S $g -Top $y -Speed $speed -Phase $ph -T $tf.T -Margin 60 -OffsetX (-$k * 6)
        }
    }
    Complete-BfxStage $S
}

function global:Add-BfxConfetti {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }
    $cols = @('#ff3f6c', '#ffd23f', '#3fd0ff', '#7dff6a', '#c47dff')
    Add-BfxFallers $S $BannerH 64 { New-BfxRect 6 3 (New-BfxBrush (Get-BfxPick $S $cols) 1.0) }.GetNewClosure() 20 50 -12 12 1.6
    # flutter: flip the confetti around its long axis
    foreach ($it in $S.Items) { $g = $it.El.RenderTransform; if ($g -is [System.Windows.Media.TransformGroup]) { Start-BfxAnim $g.Children[0] $global:BfxP.SX 1 -1 (Get-BfxRnd $S 0.3 0.7) (Get-BfxRnd $S) -Reverse } }
    Complete-BfxStage $S
}

function global:Add-BfxBirds {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $ink = New-BfxBrush '#140c0a' 0.9
    $flock = New-Object System.Windows.Controls.Canvas
    for ($i = 0; $i -lt 16; $i++) {
        $sz = Get-BfxRnd $S 3 6
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint (-$sz * 1.4) (-$sz * 0.6)), $false, $false); $c.QuadraticBezierTo((New-BfxPoint (-$sz * 0.5) (-$sz * 0.3)), (New-BfxPoint 0 0), $true, $false); $c.QuadraticBezierTo((New-BfxPoint ($sz * 0.5) (-$sz * 0.3)), (New-BfxPoint ($sz * 1.4) (-$sz * 0.6)), $true, $false) }.GetNewClosure()
        $b = New-BfxPath $geo $null $ink 1.6
        $tf = Set-BfxTransforms $b
        Start-BfxAnim $tf.S $global:BfxP.SY 1 -0.6 (Get-BfxRnd $S 0.12 0.2) (Get-BfxRnd $S) -Reverse
        Start-BfxAnim $tf.T $global:BfxP.Y -6 6 (Get-BfxRnd $S 2 4) (Get-BfxRnd $S) -Reverse -Ease
        [System.Windows.Controls.Canvas]::SetLeft($b, -(Get-BfxRnd $S 0 150)); [System.Windows.Controls.Canvas]::SetTop($b, (Get-BfxRnd $S (-$H * 0.25) ($H * 0.25)))
        [void]$flock.Children.Add($b)
    }
    $tf = Set-BfxTransforms $flock
    Add-BfxItem $S $flock -Top ($H * 0.42) -Speed 45 -Phase (Get-BfxRnd $S) -T $tf.T -Margin 180
    Complete-BfxStage $S
}

function global:Add-BfxBlizzard {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 130; $i++) {
        $z = Get-BfxRnd $S
        $r = New-BfxRect (3 + $z * 6) (0.6 + $z * 1.6) (New-BfxBrush '#ebf5ff' (0.25 + $z * 0.6)) 1
        $tf = Set-BfxTransforms $r; $tf.R.Angle = 20
        $sp = 40 + $z * 140
        Start-BfxAnim $tf.T $global:BfxP.Y (-6) ($H + 6) (($H + 12) / ($sp * 0.45)) (Get-BfxRnd $S)
        Add-BfxItem $S $r -Top 0 -Speed $sp -Phase (Get-BfxRnd $S) -T $tf.T -Margin 20
    }
    Complete-BfxStage $S
}

function global:Add-BfxFrost {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $stroke = New-BfxBrush '#d2eeff' 0.75
    $sh = New-Object System.Windows.Media.Effects.DropShadowEffect; $sh.Color = New-BfxColor '#bfe6ff'; $sh.BlurRadius = 6; $sh.ShadowDepth = 0
    $corners = @(@(0, 0, 0.5, 0.0), @(0, $H, -0.5, 0.0), @(0, 0, ([Math]::PI - 0.5), 1.0), @(0, $H, ([Math]::PI + 0.5), 1.0))
    foreach ($cn in $corners) {
        # one Path per branch depth so the frost grows outwards over time
        $segs = @{}; for ($d = 0; $d -le 5; $d++) { $segs[$d] = New-Object System.Collections.ArrayList }
        $grow = $null
        $grow = {
            param($x, $y, $a, $len, $d)
            if ($d -gt 5 -or $len -lt 4) { return }
            $x2 = $x + [Math]::Cos($a) * $len; $y2 = $y + [Math]::Sin($a) * $len
            [void]$segs[$d].Add(@($x, $y, $x2, $y2))
            & $grow $x2 $y2 ($a + 0.5 + (Get-BfxRnd $S 0 0.3)) ($len * 0.68) ($d + 1)
            & $grow $x2 $y2 ($a - 0.5 - (Get-BfxRnd $S 0 0.3)) ($len * 0.68) ($d + 1)
            if ((Get-BfxRnd $S) -lt 0.6) { & $grow $x2 $y2 ($a + (Get-BfxRnd $S -0.15 0.15)) ($len * 0.75) ($d + 1) }
        }
        for ($k = -1; $k -le 1; $k++) { & $grow $cn[0] $cn[1] ($cn[2] + $k * 0.35) ($H * 0.32) 0 }
        $holder = New-Object System.Windows.Controls.Canvas; $holder.Effect = $sh
        for ($d = 0; $d -le 5; $d++) {
            $list = $segs[$d]; if ($list.Count -eq 0) { continue }
            $geo = New-BfxGeo { param($c) foreach ($sg in $list) { $c.BeginFigure((New-BfxPoint $sg[0] $sg[1]), $false, $false); $c.LineTo((New-BfxPoint $sg[2] $sg[3]), $true, $false) } }.GetNewClosure()
            $p = New-BfxPath $geo $null $stroke 1
            $t0 = 0.06 + $d * 0.09
            Start-BfxKeys $p $global:BfxP.O @(@(0, 0), @($t0, 0), @(($t0 + 0.08), 1), @(0.8, 1), @(0.98, 0), @(1, 0)) 10
            [void]$holder.Children.Add($p)
        }
        Add-BfxItem $S $holder -Fx $cn[3] -Top 0
    }
    Complete-BfxStage $S
}

function global:Add-BfxSandwind {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $sand = New-BfxBrush '#f0c88c' 0.65
    for ($i = 0; $i -lt 150; $i++) {
        $band = $S.R.Next(0, 4)
        $r = New-BfxRect 2.2 0.9 $sand; $tf = Set-BfxTransforms $r
        Start-BfxAnim $tf.T $global:BfxP.Y -8 8 (Get-BfxRnd $S 1.5 3) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $r -Top ($H * (0.22 + $band * 0.2) + (Get-BfxRnd $S -6 6)) -Speed (Get-BfxRnd $S 90 200) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 10
    }
    Complete-BfxStage $S
}

# Drips from the top edge with falling drops (blood and ink share this).
function global:Add-BfxDrips {
    param($S, [double]$H, [int]$Count, [string]$Hex, [string]$DropHex, [double]$WMin, [double]$WMax, [switch]$Shine, [switch]$Puddle)
    for ($i = 0; $i -lt $Count; $i++) {
        $wd = Get-BfxRnd $S $WMin $WMax; $max = Get-BfxRnd $S 25 ($H * 0.55); $per = Get-BfxRnd $S 6 12; $ph = Get-BfxRnd $S
        $g = New-Object System.Windows.Controls.Canvas
        $stem = New-BfxRect $wd $max (New-BfxBrush $Hex 1.0) ($wd / 2); [System.Windows.Controls.Canvas]::SetLeft($stem, -$wd / 2)
        $st = New-Object System.Windows.Media.ScaleTransform 1, 0.3; $stem.RenderTransform = $st; $stem.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0)
        Start-BfxKeys $st $global:BfxP.SY @(@(0, 0.3), @(0.85, 1), @(0.9, 0.62), @(1, 0.3)) $per $ph
        [void]$g.Children.Add($stem)
        if ($Shine) { $sh = New-BfxRect 1.5 ($max - 4) (New-BfxBrush '#ffffff' 0.18); [System.Windows.Controls.Canvas]::SetLeft($sh, -$wd * 0.3); [System.Windows.Controls.Canvas]::SetTop($sh, 2); $sh.RenderTransform = $st; $sh.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0); [void]$g.Children.Add($sh) }
        $drop = New-BfxEllipse ($wd * 1.4) ($wd * 2) (New-BfxBrush $DropHex 1.0); [System.Windows.Controls.Canvas]::SetLeft($drop, -$wd * 0.7)
        $dt = Set-BfxTransforms $drop
        Start-BfxKeys $dt.T $global:BfxP.Y @(@(0, $max * 0.9), @(0.85, $max * 0.9), @(1, ($H + 20))) $per $ph
        Start-BfxKeys $drop $global:BfxP.O @(@(0, 0), @(0.84, 0), @(0.85, 1), @(1, 1)) $per $ph
        [void]$g.Children.Add($drop)
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S 0.02 0.98) -Top 0
    }
    if ($Puddle) { $p = New-BfxEllipse 4000 20 (New-BfxBrush $Hex 1.0); Add-BfxItem $S $p -Fx 0 -Top ($H - 6) -OffsetX -1400 }
}

function global:Add-BfxBlooddrips {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }
    Add-BfxDrips $S $BannerH 12 '#8a0c12' '#a3101a' 2 6
    Complete-BfxStage $S
}

function global:Add-BfxInkdrips {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }
    Add-BfxDrips $S $BannerH 9 '#0c0a08' '#0c0a08' 6 16 -Shine -Puddle
    Complete-BfxStage $S
}

function global:Add-BfxCaustics {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 5; $i++) {
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 0), $true, $true); $c.LineTo((New-BfxPoint 30 0), $true, $false); $c.LineTo((New-BfxPoint 90 $H), $true, $false); $c.LineTo((New-BfxPoint 40 $H), $true, $false) }.GetNewClosure()
        $ray = New-BfxPath $geo (New-BfxLinear @(@(0, '#a0f0ff', 0.16), @(1, '#a0f0ff', 0)))
        $tf = Set-BfxTransforms $ray
        Start-BfxAnim $tf.T $global:BfxP.X -30 30 (Get-BfxRnd $S 5 9) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $ray -Fx (0.08 + $i * 0.21) -Top 0
    }
    $line = New-BfxBrush '#96f0ff' 0.3
    for ($i = 0; $i -lt 56; $i++) {
        $rw = Get-BfxRnd $S 22 36
        $geo = New-BfxGeo { param($c) for ($k = 0; $k -le 6; $k++) { $a = $k / 6 * 2 * [Math]::PI; $rr = 1 + 0.25 * [Math]::Sin($a * 3 + $k); $p = New-BfxPoint ([Math]::Cos($a) * $rw * $rr) ([Math]::Sin($a) * $rw * 0.45 * $rr); if ($k -eq 0) { $c.BeginFigure($p, $false, $true) } else { $c.LineTo($p, $true, $true) } } }.GetNewClosure()
        $cell = New-BfxPath $geo $null $line 1.2
        $tf = Set-BfxTransforms $cell
        Start-BfxAnim $tf.S $global:BfxP.SX 0.7 1.15 (Get-BfxRnd $S 1.8 3.2) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxAnim $tf.S $global:BfxP.SY 1.1 0.75 (Get-BfxRnd $S 1.8 3.2) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $cell -Fx (Get-BfxRnd $S) -Top (Get-BfxRnd $S 0 $H)
    }
    Complete-BfxStage $S
}

function global:Add-BfxFish {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $body = New-BfxBrush '#beebff' 0.75
    $school = New-Object System.Windows.Controls.Canvas
    for ($i = 0; $i -lt 38; $i++) {
        $sz = Get-BfxRnd $S 4 8
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint $sz 0), $true, $true); $c.QuadraticBezierTo((New-BfxPoint 0 (-$sz * 0.55)), (New-BfxPoint (-$sz * 0.8) 0), $true, $false); $c.LineTo((New-BfxPoint (-$sz * 1.6) (-$sz * 0.5)), $true, $false); $c.LineTo((New-BfxPoint (-$sz * 1.6) ($sz * 0.5)), $true, $false); $c.LineTo((New-BfxPoint (-$sz * 0.8) 0), $true, $false); $c.QuadraticBezierTo((New-BfxPoint 0 ($sz * 0.55)), (New-BfxPoint $sz 0), $true, $false) }.GetNewClosure()
        $f = New-BfxPath $geo $body
        $tf = Set-BfxTransforms $f
        Start-BfxAnim $tf.R $global:BfxP.A -12 12 (Get-BfxRnd $S 1.8 2.8) (Get-BfxRnd $S) -Reverse -Ease
        [System.Windows.Controls.Canvas]::SetLeft($f, -(Get-BfxRnd $S 0 220)); [System.Windows.Controls.Canvas]::SetTop($f, (Get-BfxRnd $S -25 25))
        [void]$school.Children.Add($f)
    }
    $tf = Set-BfxTransforms $school
    Start-BfxAnim $tf.T $global:BfxP.Y (-$H * 0.15) ($H * 0.15) 2.6 0 -Reverse -Ease
    Add-BfxItem $S $school -Top ($H * 0.5) -Speed 60 -Phase (Get-BfxRnd $S) -T $tf.T -Margin 240
    Complete-BfxStage $S
}

function global:Add-BfxOrbits {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 55; $i++) { $d = New-BfxEllipse 1.4 1.4 (New-BfxBrush '#ffffff' (Get-BfxRnd $S 0.3 0.7)); Add-BfxItem $S $d -Fx (Get-BfxRnd $S) -Top (Get-BfxRnd $S 0 $H) }
    $sys = New-Object System.Windows.Controls.Canvas
    [void]$sys.Children.Add((New-BfxGlow ($H * 0.55) '#ffcc66' 0.8)); [void]$sys.Children.Add((New-BfxGlow 14 '#fff3cc' 1.0))
    $dash = New-BfxBrush '#b4c8ff' 0.25
    $cols = @('#ffb36b', '#7fd0ff', '#c07bff', '#8dff9c', '#ff7a9a')
    $radii = @(0.18, 0.3, 0.45, 0.62, 0.8)
    for ($i = 0; $i -lt 5; $i++) {
        $rx = $H * 1.6 * $radii[$i]; $ry = $H * 0.42 * $radii[$i] * 1.0
        $orbit = New-BfxEllipse ($rx * 2) ($ry * 2) $null $dash 1; $orbit.StrokeDashArray = [System.Windows.Media.DoubleCollection]::new([double[]]@(2, 5))
        $orbit.Margin = [System.Windows.Thickness]::new(-$rx, -$ry, 0, 0); [void]$sys.Children.Add($orbit)
        # planet on a circle of radius rx, flattened to ry by a ScaleTransform on its own ring canvas
        $ring = New-Object System.Windows.Controls.Canvas
        $sz = Get-BfxRnd $S 4 9
        $pl = New-Object System.Windows.Controls.Canvas; [void]$pl.Children.Add((New-BfxGlow ($sz * 3) $cols[$i] 0.4)); [void]$pl.Children.Add((New-BfxGlow $sz $cols[$i] 1.0))
        [System.Windows.Controls.Canvas]::SetLeft($pl, $rx); [void]$ring.Children.Add($pl)
        $rot = New-Object System.Windows.Media.RotateTransform 0
        $sc = New-Object System.Windows.Media.ScaleTransform 1, ($ry / $rx)
        $tg = New-Object System.Windows.Media.TransformGroup; [void]$tg.Children.Add($rot); [void]$tg.Children.Add($sc); $ring.RenderTransform = $tg
        Start-BfxAnim $rot $global:BfxP.A 0 360 (6 * ($i + 1)) (Get-BfxRnd $S)
        [void]$sys.Children.Add($ring)
    }
    Add-BfxItem $S $sys -Fx 0.64 -Top ($H * 0.5)
    Complete-BfxStage $S
}

function global:Add-BfxLasers {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 45; $i++) { $d = New-BfxEllipse 1.4 1.4 (New-BfxBrush '#ffffff' 0.45); $tf = Set-BfxTransforms $d; Add-BfxItem $S $d -Top (Get-BfxRnd $S 0 $H) -Speed (-(Get-BfxRnd $S 10 30)) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 4 }
    for ($v = 0; $v -lt 7; $v++) {
        $col = Get-BfxPick $S @('#ff3b3b', '#4dff7a'); $dir = Get-BfxPick $S @(1, -1); $y = Get-BfxRnd $S ($H * 0.15) ($H * 0.85); $ang = Get-BfxRnd $S -12 12; $ph = Get-BfxRnd $S
        foreach ($o in @(0, 6)) {
            $streak = New-BfxStreak 26 $col 2.6 $col; $tf = Set-BfxTransforms $streak; $tf.R.Angle = $ang; if ($dir -lt 0) { $tf.S.ScaleX = -1 }
            Add-BfxItem $S $streak -Top ($y + $o) -Speed (700 * $dir) -Phase $ph -T $tf.T -Margin (Get-BfxRnd $S 300 900)
        }
    }
    for ($hit = 0; $hit -lt 4; $hit++) { $f = New-BfxGlow 46 (Get-BfxPick $S @('#ff3b3b', '#4dff7a')) 0.8; Start-BfxFlash $f (Get-BfxRnd $S 1.5 3.5) (Get-BfxRnd $S 0.1 0.9) 0.08; Add-BfxItem $S $f -Fx (Get-BfxRnd $S 0.3 0.85) -Top (Get-BfxRnd $S ($H * 0.2) ($H * 0.8)) }
    Complete-BfxStage $S
}


function global:Add-BfxScan {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    # triangle mesh over a wide field, revealed only around the scan line
    $field = 2600.0
    $pts = @{}
    $cols = [int]($field / 34) + 2; $rows = [int]($H / 30) + 2
    for ($cx = 0; $cx -lt $cols; $cx++) { for ($ry = 0; $ry -lt $rows; $ry++) { $pts["$cx,$ry"] = @(($cx * 34 + ($ry % 2) * 17 + (Get-BfxRnd $S -8 8)), ($ry * 30 + (Get-BfxRnd $S -5 5))) } }
    $geo = New-BfxGeo { param($c)
        for ($cx = 0; $cx -lt $cols - 1; $cx++) { for ($ry = 0; $ry -lt $rows - 1; $ry++) {
            $a = $pts["$cx,$ry"]; $b = $pts["$($cx + 1),$ry"]; $d = $pts["$cx,$($ry + 1)"]
            $c.BeginFigure((New-BfxPoint $a[0] $a[1]), $false, $true); $c.LineTo((New-BfxPoint $b[0] $b[1]), $true, $false); $c.LineTo((New-BfxPoint $d[0] $d[1]), $true, $false)
        } }
    }.GetNewClosure()
    $mesh = New-BfxPath $geo $null (New-BfxBrush '#968cff' 0.6) 0.8
    # mask: a bright band trailing the scan line, moved with the line
    $mask = New-Object System.Windows.Media.LinearGradientBrush
    $mask.StartPoint = [System.Windows.Point]::new(0, 0); $mask.EndPoint = [System.Windows.Point]::new(1, 0); $mask.MappingMode = [System.Windows.Media.BrushMappingMode]::Absolute
    $mask.StartPoint = [System.Windows.Point]::new(-220, 0); $mask.EndPoint = [System.Windows.Point]::new(0, 0)
    [void]$mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 0, 0, 0), 0))
    [void]$mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 0, 0, 0), 1))
    $mt = New-Object System.Windows.Media.TranslateTransform 0, 0; $mask.Transform = $mt
    $mesh.OpacityMask = $mask
    Add-BfxItem $S $mesh -Fx 0 -Top 0
    $line = New-Object System.Windows.Controls.Canvas
    $trail = New-BfxRect 44 $H (New-BfxLinear @(@(0, '#8c78ff', 0), @(1, '#b4aaff', 0.55)) -Horizontal); [System.Windows.Controls.Canvas]::SetLeft($trail, -44)
    [void]$line.Children.Add($trail); [void]$line.Children.Add((New-BfxRect 1.5 $H (New-BfxBrush '#dcd7ff' 0.9)))
    $lt = Set-BfxTransforms $line
    Add-BfxItem $S $line -Top 0
    $S.Extra = { param($cw)
        [System.Windows.Controls.Canvas]::SetLeft($line, 0)
        $travel = Get-BfxScanTravel -Width $cw
        Start-BfxAnim $lt.T $global:BfxP.X $travel.From $travel.To $travel.Seconds 0
        # gradient end follows the line: mask = 0 behind (x-220) .. 1 at the line, nothing ahead
        Start-BfxAnim $mt $global:BfxP.X $travel.From $travel.To $travel.Seconds 0
    }.GetNewClosure()
    # hide everything ahead of the line with a second stop pair
    [void]$mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(255, 0, 0, 0), 1.0))
    [void]$mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb(0, 0, 0, 0), 1.001))
    Complete-BfxStage $S
}

function global:Add-BfxBiolum {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 44; $i++) {
        $col = if ((Get-BfxRnd $S) -lt 0.7) { '#3fffe0' } else { '#b46bff' }
        $sz = Get-BfxRnd $S 1 2.5
        $g = New-Object System.Windows.Controls.Canvas; [void]$g.Children.Add((New-BfxGlow ($sz * 12) $col 0.6)); [void]$g.Children.Add((New-BfxGlow ($sz * 1.4) '#eafffb' 1.0))
        $tf = Set-BfxTransforms $g
        Start-BfxAnim $tf.T $global:BfxP.Y ($H + 10) (-10) (Get-BfxRnd $S 14 30) (Get-BfxRnd $S)
        Start-BfxAnim $tf.T $global:BfxP.X -8 8 (Get-BfxRnd $S 3 6) (Get-BfxRnd $S) -Reverse -Ease
        # heartbeat-like pulse
        Start-BfxKeys $g $global:BfxP.O @(@(0, 0.35), @(0.1, 1), @(0.22, 0.45), @(0.32, 0.9), @(0.5, 0.35), @(1, 0.35)) 2.86 (Get-BfxRnd $S 0 0.15)
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S) -Top 0
    }
    Complete-BfxStage $S
}

function global:Add-BfxHearts {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $pink = New-BfxBrush '#ff78b4' 0.85
    for ($i = 0; $i -lt 20; $i++) {
        $k = (Get-BfxRnd $S 4 10) / 10
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 (3 * $k)), $true, $true); $c.BezierTo((New-BfxPoint (-10 * $k) (-4 * $k)), (New-BfxPoint (-5 * $k) (-11 * $k)), (New-BfxPoint 0 (-5 * $k)), $true, $false); $c.BezierTo((New-BfxPoint (5 * $k) (-11 * $k)), (New-BfxPoint (10 * $k) (-4 * $k)), (New-BfxPoint 0 (3 * $k)), $true, $false) }.GetNewClosure()
        $p = New-BfxPath $geo $pink
        $tf = Set-BfxTransforms $p
        $per = Get-BfxRnd $S 5 10; $ph = Get-BfxRnd $S
        Start-BfxAnim $tf.T $global:BfxP.Y ($H + 12) (-12) $per $ph
        Start-BfxKeys $p $global:BfxP.O @(@(0, 1), @(0.6, 1), @(0.92, 0), @(1, 0)) $per $ph
        Start-BfxAnim $tf.R $global:BfxP.A -14 14 (Get-BfxRnd $S 0.8 1.4) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $p -Fx (Get-BfxRnd $S) -Top 0
    }
    Complete-BfxStage $S
}

function global:Add-BfxNotes {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $staff = New-BfxBrush '#c8beff' 0.14
    for ($l = 0; $l -lt 5; $l++) {
        $y0 = $H * 0.3 + $l * 12
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 $y0), $false, $false); for ($x = 12; $x -le 2600; $x += 12) { $c.LineTo((New-BfxPoint $x ($y0 + [Math]::Sin($x * 0.012) * 14)), $true, $true) } }.GetNewClosure()
        $line = New-BfxPath $geo $null $staff 1
        $lt = Set-BfxTransforms $line
        Start-BfxAnim $lt.T $global:BfxP.X 0 (-523.6) 10 0
        Add-BfxItem $S $line -Fx 0 -Top 0
    }
    $cols = @('#ffd24d', '#ff6fa8', '#7fd8ff')
    for ($i = 0; $i -lt 16; $i++) {
        $col = New-BfxBrush (Get-BfxPick $S $cols) 1.0; $flag = (Get-BfxRnd $S) -lt 0.5
        $g = New-Object System.Windows.Controls.Canvas
        $head = New-BfxEllipse 9 6.6 $col; $head.RenderTransform = New-Object System.Windows.Media.RotateTransform -22, 4.5, 3.3
        [System.Windows.Controls.Canvas]::SetLeft($head, -4.5); [System.Windows.Controls.Canvas]::SetTop($head, -3.3)
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 4 0), $false, $false); $c.LineTo((New-BfxPoint 4 -16), $true, $false); if ($flag) { $c.LineTo((New-BfxPoint 10 -12), $true, $false) } }.GetNewClosure()
        [void]$g.Children.Add($head); [void]$g.Children.Add((New-BfxPath $geo $null $col 1.6))
        $tf = Set-BfxTransforms $g
        Start-BfxKeys $tf.S $global:BfxP.SY @(@(0, 1), @(0.15, 1.18), @(0.4, 1), @(1, 1)) 0.555 (Get-BfxRnd $S)
        Start-BfxAnim $tf.T $global:BfxP.Y -6 6 (Get-BfxRnd $S 1.4 2.4) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $g -Top ($H * 0.3 + $S.R.Next(0, 5) * 12) -Speed (Get-BfxRnd $S 40 70) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 20
    }
    Complete-BfxStage $S
}

function global:Add-BfxBullettime {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $brass = New-BfxLinear @(@(0, '#7a5a2a', 1), @(0.6, '#e8c070', 1), @(1, '#fff0c8', 1)) -Horizontal
    for ($b = 0; $b -lt 3; $b++) {
        $g = New-Object System.Windows.Controls.Canvas
        for ($k = 1; $k -lt 9; $k++) {
            $r = 4 + $k * 2.2
            $ring = New-BfxEllipse ($r * 0.7) ($r * 2) $null (New-BfxBrush '#c8dcf0' (0.35 * (1 - $k / 9))) 1
            [System.Windows.Controls.Canvas]::SetLeft($ring, -$k * 22 - $r * 0.35); [System.Windows.Controls.Canvas]::SetTop($ring, -$r)
            $rt = Set-BfxTransforms $ring
            Start-BfxAnim $rt.S $global:BfxP.SY 0.9 1.1 (Get-BfxRnd $S 0.8 1.4) (Get-BfxRnd $S) -Reverse -Ease
            [void]$g.Children.Add($ring)
        }
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint -12 -3), $true, $true); $c.LineTo((New-BfxPoint 2 -3), $true, $false); $c.QuadraticBezierTo((New-BfxPoint 9 0), (New-BfxPoint 2 3), $true, $false); $c.LineTo((New-BfxPoint -12 3), $true, $false) }
        [void]$g.Children.Add((New-BfxPath $geo $brass))
        $tf = Set-BfxTransforms $g
        Add-BfxItem $S $g -Top ($H * (0.25 + $b * 0.25) + (Get-BfxRnd $S -10 10)) -Speed (Get-BfxRnd $S 50 80) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 220
    }
    Complete-BfxStage $S
}

function global:Add-BfxVoid {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($k = 0; $k -lt 7; $k++) {
        $side = $k % 2; $len = 220 * (Get-BfxRnd $S 0.9 1.6); $ph = Get-BfxRnd $S 0 6.28
        $arm = New-Object System.Windows.Controls.Canvas
        for ($i = 0; $i -lt 26; $i++) {
            $f = $i / 26; $x = $len * $f * $(if ($side) { -1 } else { 1 }); $y = [Math]::Sin($f * 6 + $ph) * 18 * $f
            $col = if ($i % 7) { '#3a1a5a' } else { '#8a4dff' }
            $gl = New-BfxGlow (32 * (1 - $f) + 8) $col $(if ($i % 7) { 0.38 } else { 0.55 })
            [System.Windows.Controls.Canvas]::SetLeft($gl, $x); [System.Windows.Controls.Canvas]::SetTop($gl, $y)
            [void]$arm.Children.Add($gl)
        }
        $tf = Set-BfxTransforms $arm 0 0
        Start-BfxAnim $tf.S $global:BfxP.SX 0.25 1 (Get-BfxRnd $S 4 8) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxAnim $tf.R $global:BfxP.A -6 6 (Get-BfxRnd $S 3 6) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $arm -Fx ([double]$side) -Top ($H * $k / 6)
    }
    Complete-BfxStage $S
}

function global:Add-BfxPortals {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $defs = @(@(0.18, '#2aa4ff'), @(0.82, '#ff8a1e'))
    foreach ($d in $defs) {
        $g = New-Object System.Windows.Controls.Canvas
        [void]$g.Children.Add((New-BfxGlow 70 $d[1] 0.25))
        for ($k = 0; $k -lt 3; $k++) {
            $w = 32 + $k * 6; $hh = $H * 0.72 + $k * 6
            $e = New-BfxEllipse $w $hh $null (New-BfxBrush $d[1] (0.9 - $k * 0.25)) (3 - $k)
            $e.Margin = [System.Windows.Thickness]::new(-$w / 2, -$hh / 2, 0, 0)
            [void]$g.Children.Add($e)
        }
        $sh = New-Object System.Windows.Media.Effects.DropShadowEffect; $sh.Color = New-BfxColor $d[1]; $sh.BlurRadius = 14; $sh.ShadowDepth = 0; $g.Effect = $sh
        $tf = Set-BfxTransforms $g
        Start-BfxAnim $tf.S $global:BfxP.SX 0.95 1.06 1.1 (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $g -Fx $d[0] -Top ($H * 0.5)
    }
    # cube: in at the blue portal, out of the orange one
    $cube = New-Object System.Windows.Controls.Canvas
    $body = New-BfxRect 14 14 (New-BfxBrush '#c9ccd2' 1.0); [System.Windows.Controls.Canvas]::SetLeft($body, -7); [System.Windows.Controls.Canvas]::SetTop($body, -7)
    $mark = New-BfxRect 8 8 $null; $mark.Stroke = New-BfxBrush '#6fd0ff' 1.0; $mark.StrokeThickness = 1.4; [System.Windows.Controls.Canvas]::SetLeft($mark, -4); [System.Windows.Controls.Canvas]::SetTop($mark, -4)
    [void]$cube.Children.Add($body); [void]$cube.Children.Add($mark)
    $ct = Set-BfxTransforms $cube
    Start-BfxAnim $ct.R $global:BfxP.A 0 360 2 0
    Add-BfxItem $S $cube -Top ($H * 0.5)
    $S.Extra = { param($cw)
        [System.Windows.Controls.Canvas]::SetLeft($cube, 0)
        $x0 = $cw * 0.18; $x1 = $cw * 0.82
        # leaves the orange portal, flies left into the blue one, and the loop
        # brings it straight back out of the orange one
        Start-BfxKeys $ct.T $global:BfxP.X @(@(0, ($x1 - 14)), @(1, ($x0 + 14))) 3.2 0
        Start-BfxKeys $ct.T $global:BfxP.Y @(@(0, 0), @(0.5, -18), @(1, 0)) 3.2 0
    }.GetNewClosure()
    Complete-BfxStage $S
}

function global:Add-BfxTeleport {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $g = New-Object System.Windows.Controls.Canvas
    $core = New-BfxGlow 160 '#7dff4d' 0.55; [void]$g.Children.Add($core)
    for ($i = 0; $i -lt 4; $i++) {
        $w = (20 + $i * 12) * 2; $hh = (8 + $i * 5) * 2
        $e = New-BfxEllipse $w $hh $null (New-BfxBrush '#a0ff78' 0.6) 1.4; $e.Margin = [System.Windows.Thickness]::new(-$w / 2, -$hh / 2, 0, 0)
        $rt = New-Object System.Windows.Media.RotateTransform 0; $e.RenderTransform = $rt; $e.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
        Start-BfxAnim $rt $global:BfxP.A 0 (360 * $(if ($i % 2) { 1 } else { -1 })) (Get-BfxRnd $S 2.5 4.5) 0
        [void]$g.Children.Add($e)
    }
    for ($i = 0; $i -lt 6; $i++) {
        $geo = New-BfxGeo { param($c) $a = Get-BfxRnd $S 0 6.28; $x = 0.0; $y = 0.0; $c.BeginFigure((New-BfxPoint 0 0), $false, $false); for ($j = 0; $j -lt 6; $j++) { $x += [Math]::Cos($a) * 10 + (Get-BfxRnd $S -5 5); $y += [Math]::Sin($a) * 6 + (Get-BfxRnd $S -4 4); $c.LineTo((New-BfxPoint $x $y), $true, $false) } }.GetNewClosure()
        $z = New-BfxPath $geo $null (New-BfxBrush '#d2ffbe' 0.85) 1.2
        Start-BfxFlash $z 4 (Get-BfxRnd $S 0.35 0.65) 0.04
        [void]$g.Children.Add($z)
    }
    $tf = Set-BfxTransforms $g
    $keys = @(@(0, 0.05), @(0.7, 1), @(1, 0.05))
    Start-BfxKeys $tf.S $global:BfxP.SX $keys 4; Start-BfxKeys $tf.S $global:BfxP.SY $keys 4
    Start-BfxKeys $g $global:BfxP.O @(@(0, 0.1), @(0.7, 1), @(1, 0.1)) 4
    Add-BfxItem $S $g -Fx 0.66 -Top ($H * 0.5)
    Complete-BfxStage $S
}

function global:Add-BfxWebs {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $silk = New-BfxBrush '#e1e8f5' 0.55
    foreach ($cn in @(@(0.0, 1, ($H * 0.75)), @(1.0, -1, ($H * 0.6)))) {
        $sx = $cn[1]; $rad = $cn[2]
        $geo = New-BfxGeo { param($c)
            $spokes = 7
            for ($i = 0; $i -le $spokes; $i++) { $a = ($i / $spokes) * [Math]::PI / 2; $c.BeginFigure((New-BfxPoint 0 0), $false, $false); $c.LineTo((New-BfxPoint ($sx * [Math]::Cos($a) * $rad) ([Math]::Sin($a) * $rad)), $true, $false) }
            for ($ringR = $rad * 0.18; $ringR -lt $rad; $ringR += $rad * 0.16) { for ($i = 0; $i -le $spokes; $i++) { $a = ($i / $spokes) * [Math]::PI / 2; $rr = $ringR * (0.94 + 0.06 * [Math]::Sin($i * 2)); $p = New-BfxPoint ($sx * [Math]::Cos($a) * $rr) ([Math]::Sin($a) * $rr); if ($i -eq 0) { $c.BeginFigure($p, $false, $false) } else { $c.LineTo($p, $true, $true) } } }
        }.GetNewClosure()
        $web = New-Object System.Windows.Controls.Canvas
        [void]$web.Children.Add((New-BfxPath $geo $null $silk 0.8))
        for ($i = 1; $i -lt 6; $i++) {
            $a = $i * 0.27; $rr = $rad * (0.3 + 0.12 * $i)
            $dew = New-BfxGlow 4 '#ffffff' 1.0; [System.Windows.Controls.Canvas]::SetLeft($dew, $sx * [Math]::Cos($a) * $rr); [System.Windows.Controls.Canvas]::SetTop($dew, [Math]::Sin($a) * $rr)
            Start-BfxAnim $dew $global:BfxP.O 0.3 1 (Get-BfxRnd $S 1.2 2.4) (Get-BfxRnd $S) -Reverse -Ease
            [void]$web.Children.Add($dew)
        }
        Add-BfxItem $S $web -Fx $cn[0] -Top 0
    }
    # web line: shoots out from the top, swings, fades
    $swing = New-Object System.Windows.Controls.Canvas
    $len = $H * 1.15
    $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 0), $false, $false); $c.QuadraticBezierTo((New-BfxPoint ($len * 0.45) ($len * 0.55)), (New-BfxPoint ($len * 0.9) ($len * 0.75)), $true, $false) }.GetNewClosure()
    $strand = New-BfxPath $geo $null (New-BfxBrush '#f0f5ff' 0.9) 1.6
    $sh = New-Object System.Windows.Media.Effects.DropShadowEffect; $sh.Color = New-BfxColor '#cfe0ff'; $sh.BlurRadius = 6; $sh.ShadowDepth = 0; $strand.Effect = $sh
    [void]$swing.Children.Add($strand)
    $tip = New-BfxGlow 6 '#ffffff' 1.0; [System.Windows.Controls.Canvas]::SetLeft($tip, $len * 0.9); [System.Windows.Controls.Canvas]::SetTop($tip, $len * 0.75); [void]$swing.Children.Add($tip)
    $tf = Set-BfxTransforms $swing 0 0
    Start-BfxKeys $tf.S $global:BfxP.SX @(@(0, 0.05), @(0.06, 1), @(1, 1)) 3.5
    Start-BfxKeys $tf.S $global:BfxP.SY @(@(0, 0.05), @(0.06, 1), @(1, 1)) 3.5
    Start-BfxKeys $tf.R $global:BfxP.A @(@(0, 0), @(0.1, -10), @(0.2, 8), @(0.3, -5), @(0.4, 3), @(0.55, 0), @(1, 0)) 3.5
    Start-BfxKeys $swing $global:BfxP.O @(@(0, 1), @(0.45, 1), @(0.56, 0), @(1, 0)) 3.5
    Add-BfxItem $S $swing -Fx 0.3 -Top 0
    Complete-BfxStage $S
}

function global:Add-BfxCoins {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $gold = New-Object System.Windows.Media.LinearGradientBrush; $gold.StartPoint = [System.Windows.Point]::new(0, 0); $gold.EndPoint = [System.Windows.Point]::new(1, 1)
    [void]$gold.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BfxColor '#fff2a0'), 0)); [void]$gold.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BfxColor '#ffc928'), 0.5)); [void]$gold.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BfxColor '#b07a08'), 1)); $gold.Freeze()
    $rim = New-BfxBrush '#8a5c04' 1.0
    for ($i = 0; $i -lt 12; $i++) {
        $g = New-Object System.Windows.Controls.Canvas
        $disc = New-BfxEllipse 18 18 $gold; [System.Windows.Controls.Canvas]::SetLeft($disc, -9); [System.Windows.Controls.Canvas]::SetTop($disc, -9)
        $inner = New-BfxEllipse 12 12 $null $rim 1.2; [System.Windows.Controls.Canvas]::SetLeft($inner, -6); [System.Windows.Controls.Canvas]::SetTop($inner, -6)
        [void]$g.Children.Add($disc); [void]$g.Children.Add($inner)
        $tf = Set-BfxTransforms $g
        Start-BfxAnim $tf.S $global:BfxP.SX 1 -1 (Get-BfxRnd $S 0.6 0.9) (Get-BfxRnd $S) -Reverse
        $jp = Get-BfxRnd $S 2.6 3.6
        Start-BfxKeys $tf.T $global:BfxP.Y @(@(0, 0), @(0.25, (-$H * 0.3)), @(0.5, 0), @(1, 0)) $jp (Get-BfxRnd $S)
        $flash = New-BfxGlow 30 '#fff4b0' 0.7; Start-BfxFlash $flash (Get-BfxRnd $S 1.5 3) (Get-BfxRnd $S) 0.08; [void]$g.Children.Add($flash)
        Add-BfxItem $S $g -Fx (($i + 0.5) / 12) -Top ($H * 0.62)
    }
    Complete-BfxStage $S
}

function global:Add-BfxRings {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $goldS = New-BfxBrush '#ffd02a' 1.0; $hiS = New-BfxBrush '#fff6b0' 1.0
    for ($i = 0; $i -lt 26; $i++) {
        $g = New-Object System.Windows.Controls.Canvas
        $ring = New-BfxEllipse 18 18 $null $goldS 3.4; [System.Windows.Controls.Canvas]::SetLeft($ring, -9); [System.Windows.Controls.Canvas]::SetTop($ring, -9)
        $sh = New-Object System.Windows.Media.Effects.DropShadowEffect; $sh.Color = New-BfxColor '#ffe066'; $sh.BlurRadius = 8; $sh.ShadowDepth = 0; $ring.Effect = $sh
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint -6 -5), $false, $false); $c.ArcTo((New-BfxPoint 2 -8), [System.Windows.Size]::new(8, 8), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false) }
        [void]$g.Children.Add($ring); [void]$g.Children.Add((New-BfxPath $geo $null $hiS 1))
        $tf = Set-BfxTransforms $g
        Start-BfxAnim $tf.S $global:BfxP.SX 1 0.15 (Get-BfxRnd $S 0.25 0.35) ($i * 0.13 % 1) -Reverse
        Start-BfxAnim $tf.T $global:BfxP.Y -5 5 1.4 ($i * 0.08 % 1) -Reverse -Ease
        # one row, evenly spaced: the same speed and phase step per ring
        Add-BfxItem $S $g -Top ($H * (0.4 + 0.18 * [Math]::Sin($i * 0.5))) -Speed 180 -Phase ($i / 26) -T $tf.T -Margin 30
    }
    Complete-BfxStage $S
}

function global:Add-BfxBolts {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $metal = New-Object System.Windows.Media.LinearGradientBrush; $metal.StartPoint = [System.Windows.Point]::new(0, 0); $metal.EndPoint = [System.Windows.Point]::new(1, 1)
    [void]$metal.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BfxColor '#f2f6fa'), 0)); [void]$metal.GradientStops.Add([System.Windows.Media.GradientStop]::new((New-BfxColor '#6a7480'), 1)); $metal.Freeze()
    $edge = New-BfxBrush '#3a424c' 1.0; $hole = New-BfxBrush '#1a1e24' 1.0
    for ($i = 0; $i -lt 22; $i++) {
        $kind = $S.R.Next(0, 3); $g = New-Object System.Windows.Controls.Canvas
        if ($kind -eq 0) {
            $geo = New-BfxGeo { param($c) for ($j = 0; $j -lt 6; $j++) { $p = New-BfxPoint ([Math]::Cos($j * [Math]::PI / 3) * 6) ([Math]::Sin($j * [Math]::PI / 3) * 6); if ($j -eq 0) { $c.BeginFigure($p, $true, $true) } else { $c.LineTo($p, $true, $false) } } }
            [void]$g.Children.Add((New-BfxPath $geo $metal $edge 0.8)); $hc = New-BfxEllipse 4.8 4.8 $hole; [System.Windows.Controls.Canvas]::SetLeft($hc, -2.4); [System.Windows.Controls.Canvas]::SetTop($hc, -2.4); [void]$g.Children.Add($hc)
        } elseif ($kind -eq 1) {
            $shaft = New-BfxRect 4 12 $metal; [System.Windows.Controls.Canvas]::SetLeft($shaft, -2); [System.Windows.Controls.Canvas]::SetTop($shaft, -6)
            $head = New-BfxRect 10 3 $metal; [System.Windows.Controls.Canvas]::SetLeft($head, -5); [System.Windows.Controls.Canvas]::SetTop($head, -8)
            [void]$g.Children.Add($shaft); [void]$g.Children.Add($head)
        } else {
            $geo = New-BfxGeo { param($c) for ($j = 0; $j -lt 16; $j++) { $rr = if ($j % 2) { 7 } else { 5.5 }; $p = New-BfxPoint ([Math]::Cos($j * [Math]::PI / 8) * $rr) ([Math]::Sin($j * [Math]::PI / 8) * $rr); if ($j -eq 0) { $c.BeginFigure($p, $true, $true) } else { $c.LineTo($p, $true, $false) } } }
            [void]$g.Children.Add((New-BfxPath $geo $metal $edge 0.8))
        }
        $tf = Set-BfxTransforms $g
        $per = Get-BfxRnd $S 1.8 3.2; $ph = Get-BfxRnd $S
        Start-BfxKeys $tf.T $global:BfxP.Y @(@(0, 12), @(0.5, (-$H * (Get-BfxRnd $S 0.6 0.95))), @(1, 12)) $per $ph
        Start-BfxKeys $tf.T $global:BfxP.X @(@(0, 0), @(1, (Get-BfxRnd $S -40 40))) $per $ph
        Start-BfxAnim $tf.R $global:BfxP.A 0 (Get-BfxPick $S @(360, -360)) (Get-BfxRnd $S 0.6 1.4) (Get-BfxRnd $S)
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S 0.03 0.97) -Top $H
    }
    Complete-BfxStage $S
}

function global:Add-BfxGems {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $cols = @('#3fd0ff', '#ff3f8a', '#7dff6a', '#ffd23f', '#b46bff')
    $facet = New-BfxBrush '#ffffff' 0.45; $spark = New-BfxBrush '#ffffff' 1.0
    for ($i = 0; $i -lt 12; $i++) {
        $sz = Get-BfxRnd $S 6 13
        $g = New-Object System.Windows.Controls.Canvas
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 (-$sz)), $true, $true); $c.LineTo((New-BfxPoint ($sz * 0.7) (-$sz * 0.3)), $true, $false); $c.LineTo((New-BfxPoint 0 $sz), $true, $false); $c.LineTo((New-BfxPoint (-$sz * 0.7) (-$sz * 0.3)), $true, $false) }.GetNewClosure()
        $top = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 (-$sz)), $true, $true); $c.LineTo((New-BfxPoint ($sz * 0.7) (-$sz * 0.3)), $true, $false); $c.LineTo((New-BfxPoint 0 (-$sz * 0.1)), $true, $false) }.GetNewClosure()
        $gem = New-Object System.Windows.Controls.Canvas
        [void]$gem.Children.Add((New-BfxPath $geo (New-BfxBrush (Get-BfxPick $S $cols) 0.85))); [void]$gem.Children.Add((New-BfxPath $top $facet))
        $gt = Set-BfxTransforms $gem
        Start-BfxAnim $gt.S $global:BfxP.SX 1.2 0.2 (Get-BfxRnd $S 2 4) (Get-BfxRnd $S) -Reverse -Ease
        [void]$g.Children.Add($gem)
        $cross = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint -9 0), $false, $false); $c.LineTo((New-BfxPoint 9 0), $true, $false); $c.BeginFigure((New-BfxPoint 0 -9), $false, $false); $c.LineTo((New-BfxPoint 0 9), $true, $false) }
        $star = New-BfxPath $cross $null $spark 1; [System.Windows.Controls.Canvas]::SetTop($star, -$sz * 0.4)
        Start-BfxFlash $star (Get-BfxRnd $S 2.5 5) (Get-BfxRnd $S) 0.08
        [void]$g.Children.Add($star)
        $tf = Set-BfxTransforms $g
        Start-BfxAnim $tf.T $global:BfxP.Y -6 6 (Get-BfxRnd $S 2 3.5) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S 0.05 0.95) -Top (Get-BfxRnd $S ($H * 0.2) ($H * 0.8))
    }
    Complete-BfxStage $S
}


function global:Add-BfxHalftone {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    # dot raster as a tiled brush, swept by a moving opacity mask
    $dg = New-Object System.Windows.Media.GeometryDrawing
    $dg.Brush = New-BfxBrush '#ffcf3f' 0.32
    $dg.Geometry = New-Object System.Windows.Media.EllipseGeometry ([System.Windows.Point]::new(5, 5)), 2.4, 2.4
    $db = New-Object System.Windows.Media.DrawingBrush $dg
    $db.TileMode = [System.Windows.Media.TileMode]::Tile; $db.Stretch = [System.Windows.Media.Stretch]::None
    $db.Viewport = [System.Windows.Rect]::new(0, 0, 10, 10); $db.ViewportUnits = [System.Windows.Media.BrushMappingMode]::Absolute
    $db.Viewbox = [System.Windows.Rect]::new(0, 0, 10, 10); $db.ViewboxUnits = [System.Windows.Media.BrushMappingMode]::Absolute
    $dots = New-BfxRect 2600 $H $db
    $mask = New-Object System.Windows.Media.LinearGradientBrush
    $mask.MappingMode = [System.Windows.Media.BrushMappingMode]::Absolute
    $mask.StartPoint = [System.Windows.Point]::new(0, 0); $mask.EndPoint = [System.Windows.Point]::new(420, 0)
    $mask.SpreadMethod = [System.Windows.Media.GradientSpreadMethod]::Repeat
    foreach ($st in @(@(0, 40), @(0.5, 255), @(1, 40))) { [void]$mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb([byte]$st[1], 0, 0, 0), [double]$st[0])) }
    $mt = New-Object System.Windows.Media.TranslateTransform 0, 0; $mask.Transform = $mt
    Start-BfxAnim $mt $global:BfxP.X 0 420 2.2 0
    $dots.OpacityMask = $mask
    Add-BfxItem $S $dots -Fx 0 -Top 0
    # action burst
    $burst = New-BfxGeo { param($c) for ($i = 0; $i -lt 24; $i++) { $a = $i * [Math]::PI * 2 / 24; $rr = if ($i % 2) { 22 } else { 40 }; $p = New-BfxPoint ([Math]::Cos($a) * $rr * 1.4) ([Math]::Sin($a) * $rr * 0.8); if ($i -eq 0) { $c.BeginFigure($p, $true, $true) } else { $c.LineTo($p, $true, $false) } } }
    $bp = New-BfxPath $burst (New-BfxBrush '#ffffff' 0.85) (New-BfxBrush '#14100a' 1.0) 2
    $bt = Set-BfxTransforms $bp
    $k = @(@(0, 0.6), @(0.35, 1.6), @(1, 1.6))
    Start-BfxKeys $bt.S $global:BfxP.SX $k 2.6; Start-BfxKeys $bt.S $global:BfxP.SY $k 2.6
    Start-BfxKeys $bp $global:BfxP.O @(@(0, 1), @(0.35, 0), @(1, 0)) 2.6
    Add-BfxItem $S $bp -Fx 0.7 -Top ($H * 0.5)
    Complete-BfxStage $S
}

function global:Add-BfxGraffiti {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $cols = @('#ff2a8a', '#2affd0', '#ffe02a', '#7a4dff', '#ff6a2a')
    for ($i = 0; $i -lt 9; $i++) {
        $col = New-BfxBrush (Get-BfxPick $S $cols) 0.85; $rad = Get-BfxRnd $S 10 22
        $g = New-Object System.Windows.Controls.Canvas
        $blob = New-BfxGeo { param($c) for ($j = 0; $j -lt 12; $j++) { $a = $j * [Math]::PI * 2 / 12; $rr = $rad * (0.8 + 0.3 * [Math]::Sin($j * 3.7)); $p = New-BfxPoint ([Math]::Cos($a) * $rr) ([Math]::Sin($a) * $rr); if ($j -eq 0) { $c.BeginFigure($p, $true, $true) } else { $c.LineTo($p, $true, $true) } } }.GetNewClosure()
        [void]$g.Children.Add((New-BfxPath $blob $col))
        for ($j = 0; $j -lt 14; $j++) { $a = Get-BfxRnd $S 0 6.28; $d = Get-BfxRnd $S ($rad + 4) ($rad + 30); $sz = Get-BfxRnd $S 2 6; $dot = New-BfxEllipse $sz $sz $col; [System.Windows.Controls.Canvas]::SetLeft($dot, [Math]::Cos($a) * $d - $sz / 2); [System.Windows.Controls.Canvas]::SetTop($dot, [Math]::Sin($a) * $d - $sz / 2); [void]$g.Children.Add($dot) }
        $run = New-BfxRect 3 30 $col 1.5; [System.Windows.Controls.Canvas]::SetLeft($run, -1.5); $rs = New-Object System.Windows.Media.ScaleTransform 1, 0; $run.RenderTransform = $rs; [void]$g.Children.Add($run)
        $per = Get-BfxRnd $S 4 7; $ph = Get-BfxRnd $S; $at = Get-BfxRnd $S 0 0.4
        $tf = Set-BfxTransforms $g
        $pop = @(@(0, 0), @($at, 0), @(($at + 0.03), 1), @(1, 1))
        Start-BfxKeys $tf.S $global:BfxP.SX $pop $per $ph; Start-BfxKeys $tf.S $global:BfxP.SY $pop $per $ph
        Start-BfxKeys $rs $global:BfxP.SY @(@(0, 0), @($at, 0), @(($at + 0.4), 1), @(1, 1)) $per $ph
        Start-BfxKeys $g $global:BfxP.O @(@(0, 0), @($at, 0), @(($at + 0.01), 1), @(($at + 0.45), 1), @(($at + 0.58), 0), @(1, 0)) $per $ph
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S 0.05 0.95) -Top (Get-BfxRnd $S ($H * 0.2) ($H * 0.8))
    }
    Complete-BfxStage $S
}

function global:Add-BfxWaterspray {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    Add-BfxItem $S (New-BfxRect 4000 $H (New-BfxBrush '#785a3c' 0.22)) -Fx 0 -Top 0
    # jet: a line from the top-left to the moving nozzle target
    $jet = New-Object System.Windows.Shapes.Line
    $jet.X1 = 30; $jet.Y1 = -10; $jet.Stroke = New-BfxBrush '#d2f0ff' 0.8; $jet.StrokeThickness = 2.5; $jet.IsHitTestVisible = $false
    Add-BfxItem $S $jet -Fx 0 -Top 0
    $spot = New-Object System.Windows.Controls.Canvas
    [void]$spot.Children.Add((New-BfxGlow 120 '#c8ebff' 0.35))
    for ($i = 0; $i -lt 26; $i++) {
        $dr = New-BfxEllipse 2.8 2.8 (New-BfxBrush '#dff4ff' 0.8); $dt = Set-BfxTransforms $dr
        $per = Get-BfxRnd $S 0.4 0.8; $ph = Get-BfxRnd $S; $vx = Get-BfxRnd $S -60 60; $up = Get-BfxRnd $S 15 45
        Start-BfxKeys $dt.T $global:BfxP.X @(@(0, 0), @(1, $vx)) $per $ph
        Start-BfxKeys $dt.T $global:BfxP.Y @(@(0, 0), @(0.4, (-$up)), @(1, ($H * 0.4))) $per $ph
        Start-BfxKeys $dr $global:BfxP.O @(@(0, 1), @(1, 0)) $per $ph
        [void]$spot.Children.Add($dr)
    }
    $tf = Set-BfxTransforms $spot
    Add-BfxItem $S $spot -Top 0
    $S.Extra = { param($cw)
        [System.Windows.Controls.Canvas]::SetLeft($spot, 0)
        $x0 = $cw * 0.12; $x1 = $cw * 0.88; $y0 = $H * 0.35; $y1 = $H * 0.75
        Start-BfxAnim $tf.T $global:BfxP.X $x0 $x1 3.9 0 -Reverse -Ease
        Start-BfxAnim $tf.T $global:BfxP.Y $y0 $y1 1.85 0 -Reverse -Ease
        Start-BfxAnim $jet ([System.Windows.Shapes.Line]::X2Property) $x0 $x1 3.9 0 -Reverse -Ease
        Start-BfxAnim $jet ([System.Windows.Shapes.Line]::Y2Property) $y0 $y1 1.85 0 -Reverse -Ease
    }.GetNewClosure()
    Complete-BfxStage $S
}

function global:Add-BfxClouds {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 22; $i++) {
        $layer = $i % 3; $rad = Get-BfxRnd $S 30 70
        $g = New-Object System.Windows.Controls.Canvas
        [void]$g.Children.Add((New-BfxGlow ($rad * 2.8) '#ffffff' (0.2 + $layer * 0.08)))
        $b2 = New-BfxGlow ($rad * 2) '#dfe8f5' (0.22 + $layer * 0.06); [System.Windows.Controls.Canvas]::SetLeft($b2, $rad * 0.5); [System.Windows.Controls.Canvas]::SetTop($b2, 6); [void]$g.Children.Add($b2)
        $tf = Set-BfxTransforms $g
        Add-BfxItem $S $g -Top ($H * (0.55 + $layer * 0.18)) -Speed (-(8 + $layer * 14)) -Phase (Get-BfxRnd $S) -T $tf.T -Margin ($rad * 1.6)
    }
    Complete-BfxStage $S
}

function global:Add-BfxEyes {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 7; $i++) {
        $col = if ((Get-BfxRnd $S) -lt 0.7) { '#ffe680' } else { '#ff4040' }
        $sz = Get-BfxRnd $S 1.6 3.2; $per = Get-BfxRnd $S 5 10; $ph = Get-BfxRnd $S
        $pair = New-Object System.Windows.Controls.Canvas
        foreach ($sd in @(-1, 1)) {
            $halo = New-BfxGlow ($sz * 12) $col 0.45; [System.Windows.Controls.Canvas]::SetLeft($halo, $sd * $sz * 4); [void]$pair.Children.Add($halo)
            $eye = New-BfxEllipse ($sz * 3.2) ($sz * 2) (New-BfxBrush $col 1.0); $eye.Margin = [System.Windows.Thickness]::new(-$sz * 1.6, -$sz, 0, 0)
            [System.Windows.Controls.Canvas]::SetLeft($eye, $sd * $sz * 4)
            $et = New-Object System.Windows.Media.ScaleTransform 1, 1; $eye.RenderTransform = $et; $eye.RenderTransformOrigin = [System.Windows.Point]::new(0.5, 0.5)
            Start-BfxKeys $et $global:BfxP.SY @(@(0, 0), @(0.03, 1), @(0.2, 1), @(0.215, 0.1), @(0.23, 1), @(0.42, 1), @(0.45, 0), @(1, 0)) $per $ph
            [void]$pair.Children.Add($eye)
        }
        Start-BfxKeys $pair $global:BfxP.O @(@(0, 0), @(0.03, 1), @(0.42, 1), @(0.45, 0), @(1, 0)) $per $ph
        Add-BfxItem $S $pair -Fx (Get-BfxRnd $S 0.03 0.97) -Top (Get-BfxRnd $S 15 ($H - 15))
    }
    Complete-BfxStage $S
}

function global:Add-BfxSteam {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($v = 0; $v -lt 4; $v++) {
        $per = Get-BfxRnd $S 2.8 4.5; $ph = Get-BfxRnd $S; $fx = Get-BfxRnd $S 0.08 0.92
        for ($i = 0; $i -lt 14; $i++) {
            $puff = New-BfxGlow (Get-BfxRnd $S 18 30) '#e8e2d8' 0.3; $tf = Set-BfxTransforms $puff
            $lag = $i * 0.012; $pp = ((($ph + $lag) % 1) + 1) % 1
            Start-BfxKeys $tf.T $global:BfxP.Y @(@(0, 0), @(0.6, (-$H * (Get-BfxRnd $S 0.6 0.95))), @(1, (-$H * 1.0))) $per $pp
            Start-BfxKeys $tf.T $global:BfxP.X @(@(0, 0), @(1, (Get-BfxRnd $S -30 30))) $per $pp
            $grow = @(@(0, 0.5), @(1, 2.4)); Start-BfxKeys $tf.S $global:BfxP.SX $grow $per $pp; Start-BfxKeys $tf.S $global:BfxP.SY $grow $per $pp
            Start-BfxKeys $puff $global:BfxP.O @(@(0, 0), @(0.05, 1), @(0.6, 0.4), @(0.75, 0), @(1, 0)) $per $pp
            Add-BfxItem $S $puff -Fx $fx -Top $H
        }
    }
    Complete-BfxStage $S
}

function global:Add-BfxPapers {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $paper = New-BfxBrush '#f0ece0' 0.92; $ink = New-BfxBrush '#50505a' 0.5
    for ($i = 0; $i -lt 12; $i++) {
        $g = New-Object System.Windows.Controls.Canvas
        $sheet = New-BfxRect 18 24 $paper; [System.Windows.Controls.Canvas]::SetLeft($sheet, -9); [System.Windows.Controls.Canvas]::SetTop($sheet, -12); [void]$g.Children.Add($sheet)
        for ($l = 0; $l -lt 6; $l++) { $ln = New-BfxRect $(if ($l -eq 0) { 8 } else { 12 }) 1 $ink; [System.Windows.Controls.Canvas]::SetLeft($ln, -6); [System.Windows.Controls.Canvas]::SetTop($ln, -8 + $l * 3.4); [void]$g.Children.Add($ln) }
        $tf = Set-BfxTransforms $g
        Start-BfxAnim $tf.T $global:BfxP.Y (-$H * 0.25) ($H * 0.25) (Get-BfxRnd $S 1.8 3) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxAnim $tf.R $global:BfxP.A -40 40 (Get-BfxRnd $S 1.4 2.4) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxAnim $tf.S $global:BfxP.SX 1.1 0.3 (Get-BfxRnd $S 0.8 1.4) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $g -Top (Get-BfxRnd $S ($H * 0.25) ($H * 0.75)) -Speed (Get-BfxRnd $S 30 70) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 30
    }
    Complete-BfxStage $S
}

function global:Add-BfxStarburst {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 26; $i++) {
        $len = Get-BfxRnd $S 20 60
        $g = New-Object System.Windows.Controls.Canvas
        $tail = New-BfxRect $len 1.4 (New-BfxLinear @(@(0, '#b4c8ff', 0), @(1, '#f0f5ff', 0.95)) -Horizontal) 0.7
        [System.Windows.Controls.Canvas]::SetLeft($tail, -$len); [void]$g.Children.Add($tail)
        $head = New-BfxGlow 5 '#ffffff' 1.0; [void]$g.Children.Add($head)
        $g.RenderTransform = $null
        $tf = Set-BfxTransforms $g 0 0; $tf.R.Angle = 26.6
        $sp = Get-BfxRnd $S 160 320
        Start-BfxAnim $tf.T $global:BfxP.Y (-$H * 0.6) ($H * 1.2) (($H * 1.8) / ($sp * 0.5)) (Get-BfxRnd $S)
        Add-BfxItem $S $g -Top 0 -Speed $sp -Phase (Get-BfxRnd $S) -T $tf.T -Margin 120
    }
    Complete-BfxStage $S
}

function global:Add-BfxLensflare {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $sun = New-Object System.Windows.Controls.Canvas
    [void]$sun.Children.Add((New-BfxGlow 180 '#fff2c8' 0.55)); [void]$sun.Children.Add((New-BfxGlow 40 '#ffffff' 0.95))
    $streak = New-BfxRect 900 2 (New-BfxLinear @(@(0, '#fff0c8', 0), @(0.5, '#fff0c8', 0.3), @(1, '#fff0c8', 0)) -Horizontal); [System.Windows.Controls.Canvas]::SetLeft($streak, -450); [System.Windows.Controls.Canvas]::SetTop($streak, -1); [void]$sun.Children.Add($streak)
    $st = Set-BfxTransforms $sun
    Start-BfxAnim $st.T $global:BfxP.X -40 40 14 0 -Reverse -Ease
    Start-BfxAnim $st.T $global:BfxP.Y -6 6 10 0 -Reverse -Ease
    Add-BfxItem $S $sun -Fx 0.84 -Top ($H * 0.22)
    $flares = @(@(0.5, 14, '#ffd27a'), @(0.9, 7, '#9fd8ff'), @(1.24, 22, '#c8a0ff'), @(1.7, 10, '#a0ffd0'), @(2.2, 30, '#ffb07a'))
    foreach ($fl in $flares) {
        $g = New-Object System.Windows.Controls.Canvas
        $ring = New-BfxEllipse ($fl[1] * 2) ($fl[1] * 2) (New-BfxGlowBrush $fl[2] 0.12) (New-BfxBrush $fl[2] 0.35) 1.5; $ring.Margin = [System.Windows.Thickness]::new(-$fl[1], -$fl[1], 0, 0); [void]$g.Children.Add($ring)
        $ft = Set-BfxTransforms $g
        # flares sit on the line from the sun towards the banner centre and move opposite to it
        Start-BfxAnim $ft.T $global:BfxP.X (40 * $fl[0]) (-40 * $fl[0]) 14 0 -Reverse -Ease
        Add-BfxItem $S $g -Fx (0.84 - 0.39 * $fl[0] / 1.1) -Top ($H * (0.22 + 0.33 * $fl[0] / 1.1))
    }
    Complete-BfxStage $S
}

function global:Add-BfxTracker {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $R0 = $H * 0.92
    $g = New-Object System.Windows.Controls.Canvas
    $grid = New-BfxBrush '#50ff8c' 0.22
    for ($k = 1; $k -le 4; $k++) {
        $rk = $R0 * $k / 4
        $arc = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint (-$rk) 0), $false, $false); $c.ArcTo((New-BfxPoint $rk 0), [System.Windows.Size]::new($rk, $rk), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false) }.GetNewClosure()
        [void]$g.Children.Add((New-BfxPath $arc $null $grid 1))
    }
    $ping = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint (-$R0) 0), $false, $false); $c.ArcTo((New-BfxPoint $R0 0), [System.Windows.Size]::new($R0, $R0), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false) }.GetNewClosure()
    $pp = New-BfxPath $ping $null (New-BfxBrush '#78ffaa' 0.8) 2
    $pt = Set-BfxTransforms $pp
    Start-BfxAnim $pt.S $global:BfxP.SX 0.02 1 1.6 0; Start-BfxAnim $pt.S $global:BfxP.SY 0.02 1 1.6 0
    Start-BfxAnim $pp $global:BfxP.O 0.9 0 1.6 0
    [void]$g.Children.Add($pp)
    for ($i = 0; $i -lt 6; $i++) {
        $a = Get-BfxRnd $S ([Math]::PI * 1.05) ([Math]::PI * 1.95); $d0 = $R0 * (Get-BfxRnd $S 0.5 1); $per = Get-BfxRnd $S 10 25
        $blip = New-Object System.Windows.Controls.Canvas; [void]$blip.Children.Add((New-BfxGlow 20 '#6aff9a' 0.5)); [void]$blip.Children.Add((New-BfxGlow 5 '#d8ffe4' 1.0))
        $bt = Set-BfxTransforms $blip
        $ph = Get-BfxRnd $S
        Start-BfxAnim $bt.T $global:BfxP.X ([Math]::Cos($a) * $d0) ([Math]::Cos($a) * 8) $per $ph
        Start-BfxAnim $bt.T $global:BfxP.Y ([Math]::Sin($a) * $d0) ([Math]::Sin($a) * 8) $per $ph
        Start-BfxKeys $blip $global:BfxP.O @(@(0, 1), @(0.6, 0.15), @(1, 0.15)) 1.6 0
        [void]$g.Children.Add($blip)
    }
    Add-BfxItem $S $g -Fx 0.66 -Top ($H * 0.98)
    Complete-BfxStage $S
}

function global:Add-BfxSlashes {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $cols = @('#ffffff', '#ffb070', '#9fd8ff')
    for ($i = 0; $i -lt 7; $i++) {
        $col = Get-BfxPick $S $cols; $rad = Get-BfxRnd $S 28 58; $per = Get-BfxRnd $S 2.5 5; $at = Get-BfxRnd $S 0 0.8
        $g = New-Object System.Windows.Controls.Canvas
        $arc = New-BfxGeo { param($c) $a0 = -1.2; $a1 = 1.0; $c.BeginFigure((New-BfxPoint ([Math]::Cos($a0) * $rad) ([Math]::Sin($a0) * $rad)), $true, $true); $c.ArcTo((New-BfxPoint ([Math]::Cos($a1) * $rad) ([Math]::Sin($a1) * $rad)), [System.Windows.Size]::new($rad, $rad), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false); $ri = $rad * 0.86; $c.ArcTo((New-BfxPoint ([Math]::Cos($a0) * $ri) ([Math]::Sin($a0) * $ri)), [System.Windows.Size]::new($ri, $ri), 0, $false, [System.Windows.Media.SweepDirection]::Counterclockwise, $true, $false) }.GetNewClosure()
        $blade = New-BfxPath $arc (New-BfxBrush $col 0.95)
        $sh = New-Object System.Windows.Media.Effects.DropShadowEffect; $sh.Color = New-BfxColor $col; $sh.BlurRadius = 14; $sh.ShadowDepth = 0; $blade.Effect = $sh
        [void]$g.Children.Add($blade)
        for ($j = 0; $j -lt 6; $j++) {
            $an = -1.2 + 2.2 * $j / 6; $sp = New-BfxGlow 4 $col 1.0; [System.Windows.Controls.Canvas]::SetLeft($sp, [Math]::Cos($an) * $rad); [System.Windows.Controls.Canvas]::SetTop($sp, [Math]::Sin($an) * $rad)
            $spt = Set-BfxTransforms $sp; $out = Get-BfxRnd $S 15 40
            Start-BfxKeys $spt.T $global:BfxP.X @(@(0, 0), @($at, 0), @([Math]::Min(1, $at + 0.15), ([Math]::Cos($an) * $out)), @(1, ([Math]::Cos($an) * $out))) $per
            Start-BfxKeys $spt.T $global:BfxP.Y @(@(0, 0), @($at, 0), @([Math]::Min(1, $at + 0.15), ([Math]::Sin($an) * $out)), @(1, ([Math]::Sin($an) * $out))) $per
            [void]$g.Children.Add($sp)
        }
        $tf = Set-BfxTransforms $g; $tf.R.Angle = Get-BfxRnd $S 0 360
        $grow = @(@(0, 0.4), @($at, 0.4), @(($at + 0.03), 1), @(1, 1))
        Start-BfxKeys $tf.S $global:BfxP.SX $grow $per; Start-BfxKeys $tf.S $global:BfxP.SY $grow $per
        Start-BfxKeys $g $global:BfxP.O @(@(0, 0), @($at, 0), @(($at + 0.01), 1), @(([Math]::Min(0.999, $at + 0.15)), 0), @(1, 0)) $per
        Add-BfxItem $S $g -Fx (Get-BfxRnd $S 0.15 0.92) -Top (Get-BfxRnd $S ($H * 0.3) ($H * 0.7))
    }
    Complete-BfxStage $S
}

function global:Add-BfxSpores {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 3; $i++) {
        $shaft = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 0), $true, $true); $c.LineTo((New-BfxPoint 50 0), $true, $false); $c.LineTo((New-BfxPoint -30 $H), $true, $false); $c.LineTo((New-BfxPoint -80 $H), $true, $false) }.GetNewClosure()
        $sp = New-BfxPath $shaft (New-BfxBrush '#fff0be' 0.07)
        Start-BfxAnim $sp $global:BfxP.O 0.6 1 (Get-BfxRnd $S 4 7) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $sp -Fx (0.3 + $i * 0.22) -Top 0
    }
    for ($i = 0; $i -lt 80; $i++) {
        $sz = Get-BfxRnd $S 1.2 3
        $d = New-BfxEllipse $sz $sz (New-BfxBrush '#fff0c0' 0.9); $tf = Set-BfxTransforms $d
        Start-BfxAnim $tf.T $global:BfxP.X -20 20 (Get-BfxRnd $S 6 12) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxAnim $tf.T $global:BfxP.Y -10 10 (Get-BfxRnd $S 5 10) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxAnim $d $global:BfxP.O 0.2 0.95 (Get-BfxRnd $S 2 5) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $d -Fx (Get-BfxRnd $S) -Top (Get-BfxRnd $S 0 $H)
    }
    Complete-BfxStage $S
}


# ------------------------------------------------------------
# Round 2 effects (part 1)
# ------------------------------------------------------------

function global:Add-BfxAurora {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 34; $i++) {
        $st = New-BfxEllipse 1.6 1.6 (New-BfxBrush '#ffffff' 0.8)
        Start-BfxAnim $st $global:BfxP.O 0.2 0.8 (Get-BfxRnd $S 1.5 4) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $st -Fx (Get-BfxRnd $S) -Top (Get-BfxRnd $S 0 ($H * 0.95))
    }
    $bands = @(@('#4dffb0', 0.22, 0.0), @('#7dffd0', 0.15, 1.7), @('#b47dff', 0.13, 3.1))
    foreach ($bd in $bands) {
        $col = $bd[0]; $al = $bd[1]; $ph = $bd[2]; $field = 3400.0
        $geo = New-BfxGeo { param($c)
            $c.BeginFigure((New-BfxPoint 0 ($H * 0.9)), $true, $true)
            for ($x = 0.0; $x -le $field; $x += 40) { $y = $H * (0.30 + 0.12 * [Math]::Sin($x * 0.006 + $ph) + 0.05 * [Math]::Sin($x * 0.02)); $c.LineTo((New-BfxPoint $x ($y - $H * (0.35 + 0.15 * [Math]::Sin($x * 0.01 + $ph)))), $true, $true) }
            $c.LineTo((New-BfxPoint $field ($H * 0.9)), $true, $false)
        }.GetNewClosure()
        $curtain = New-BfxPath $geo (New-BfxLinear @(@(0, $col, 0), @(0.45, $col, $al), @(0.75, $col, ($al * 0.6)), @(1, $col, 0)))
        $tf = Set-BfxTransforms $curtain
        Start-BfxAnim $tf.T $global:BfxP.X (-900) 0 (Get-BfxRnd $S 18 30) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxAnim $tf.S $global:BfxP.SY 0.85 1.1 (Get-BfxRnd $S 5 9) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxAnim $curtain $global:BfxP.O 0.6 1 (Get-BfxRnd $S 4 8) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $curtain -Fx 0 -Top 0
    }
    Complete-BfxStage $S
}

function global:Add-BfxGrindsparks {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $cycle = 9.0; $spots = @(0.28, 0.52, 0.76)
    for ($k = 0; $k -lt 3; $k++) {
        $grp = New-Object System.Windows.Controls.Canvas
        $src = New-BfxGlow 52 '#ffcc66' 0.85
        Start-BfxAnim $src $global:BfxP.O 0.6 1 0.12 (Get-BfxRnd $S) -Reverse
        [void]$grp.Children.Add($src)
        for ($i = 0; $i -lt 26; $i++) {
            $ang = - [Math]::PI * (Get-BfxRnd $S 0.55 0.95); $vel = Get-BfxRnd $S 180 420; $life = Get-BfxRnd $S 0.45 0.95
            $vx = [Math]::Cos($ang) * $vel; $vy = [Math]::Sin($ang) * $vel
            $spk = New-BfxRect 9 1.6 (New-BfxLinear @(@(0, '#ff8a30', 0), @(1, '#fff2c0', 1)) -Horizontal) 0.8
            $tf = Set-BfxTransforms $spk 0 0.5; $tf.R.Angle = $ang * 180 / [Math]::PI
            $kx = @(); $ky = @(); $ka = @()
            for ($n = 0; $n -le 5; $n++) { $u = $n / 5.0; $tt = $u * $life; $kx += , @($u, ($vx * $tt)); $ky += , @($u, ($vy * $tt + 260 * $tt * $tt)); $ka += , @($u, ([Math]::Atan2($vy + 520 * $tt, $vx) * 180 / [Math]::PI)) }
            $ph = Get-BfxRnd $S
            Start-BfxKeys $tf.T $global:BfxP.X $kx $life $ph; Start-BfxKeys $tf.T $global:BfxP.Y $ky $life $ph; Start-BfxKeys $tf.R $global:BfxP.A $ka $life $ph
            Start-BfxKeys $spk $global:BfxP.O @(@(0, 1), @(0.7, 0.8), @(1, 0)) $life $ph
            [void]$grp.Children.Add($spk)
        }
        $on0 = $k / 3.0; $on1 = [Math]::Min(0.999, $on0 + 0.333)
        Start-BfxKeys $grp $global:BfxP.O @(@(0, $(if ($k -eq 0) { 1 } else { 0 })), @([Math]::Max(0.001, $on0), $(if ($k -eq 0) { 1 } else { 0 })), @(($on0 + 0.002), 1), @($on1, 1), @([Math]::Min(1, $on1 + 0.0005), 0), @(1, $(if ($k -eq 2) { 1 } else { 0 }))) $cycle -Discrete
        Add-BfxItem $S $grp -Fx $spots[$k] -Top ($H * 0.96)
    }
    Complete-BfxStage $S
}

function global:Add-BfxShieldhit {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $cell = 13.0; $rad = 110.0
    $geo = New-BfxGeo { param($c)
        for ($gx = -9; $gx -le 9; $gx++) { for ($gy = -9; $gy -le 9; $gy++) {
            $cx = $gx * $cell * 1.5; $cy = $gy * $cell * 1.732 + ([Math]::Abs($gx) % 2) * $cell * 0.866
            if ([Math]::Sqrt($cx * $cx + $cy * $cy) -gt $rad) { continue }
            for ($n = 0; $n -le 6; $n++) { $an = $n * [Math]::PI / 3; $pt = New-BfxPoint ($cx + [Math]::Cos($an) * $cell * 0.95) ($cy + [Math]::Sin($an) * $cell * 0.95); if ($n -eq 0) { $c.BeginFigure($pt, $false, $true) } else { $c.LineTo($pt, $true, $true) } }
        } }
    }.GetNewClosure()
    for ($i = 0; $i -lt 4; $i++) {
        $grp = New-Object System.Windows.Controls.Canvas
        $hexes = New-BfxPath $geo $null (New-BfxBrush '#7cc8ff' 0.85) 1
        $ring = New-Object System.Windows.Media.RadialGradientBrush
        $ring.Center = [System.Windows.Point]::new(0.5, 0.5); $ring.GradientOrigin = $ring.Center
        foreach ($gs in @(@(0, 0), @(0.55, 0), @(0.8, 255), @(1, 0))) { [void]$ring.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb([byte]$gs[1], 0, 0, 0), $gs[0])) }
        $ring.Freeze(); $hexes.OpacityMask = $ring
        [void]$grp.Children.Add($hexes)
        [void]$grp.Children.Add((New-BfxGlow 60 '#a8e4ff' 0.9))
        $tf = Set-BfxTransforms $grp 0 0
        $per = Get-BfxRnd $S 2.2 3.6; $ph = Get-BfxRnd $S
        $grow = @(@(0, 0.15), @(0.3, 1.25), @(1, 1.25))
        Start-BfxKeys $tf.S $global:BfxP.SX $grow $per $ph; Start-BfxKeys $tf.S $global:BfxP.SY $grow $per $ph
        Start-BfxKeys $grp $global:BfxP.O @(@(0, 1), @(0.3, 0), @(1, 0)) $per $ph
        Add-BfxItem $S $grp -Fx (Get-BfxRnd $S 0.25 0.9) -Top (Get-BfxRnd $S ($H * 0.25) ($H * 0.75))
    }
    Complete-BfxStage $S
}

function global:Add-BfxLaserdot {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $dots = @()
    for ($i = 0; $i -lt 3; $i++) {
        $beam = New-Object System.Windows.Shapes.Line
        $beam.Stroke = New-BfxBrush '#ff3030' 0.22; $beam.StrokeThickness = 1; $beam.IsHitTestVisible = $false
        $beam.X1 = $(if ($i -eq 1) { 3000 } else { -10 }); $beam.Y1 = $(if ($i -eq 2) { $H + 10 } else { -10 })
        Add-BfxItem $S $beam -Fx 0 -Top 0
        $dot = New-Object System.Windows.Controls.Canvas
        [void]$dot.Children.Add((New-BfxGlow 30 '#ff2020' 0.85)); [void]$dot.Children.Add((New-BfxGlow 5 '#ffe0e0' 1.0))
        $tf = Set-BfxTransforms $dot
        Add-BfxItem $S $dot -Fx 0 -Top 0
        $pts = @(); for ($n = 0; $n -lt 6; $n++) { $pts += , @((Get-BfxRnd $S 0.15 0.92), (Get-BfxRnd $S ($H * 0.2) ($H * 0.8))) }
        $dots += , @($beam, $tf, $pts, (Get-BfxRnd $S 2.0 2.8), (Get-BfxRnd $S), $i)
    }
    $S.Extra = { param($cw)
        foreach ($d in $dots) {
            $beam = $d[0]; $tf = $d[1]; $pts = $d[2]; $hold = $d[3]; $per = $hold * $pts.Count
            if ($d[5] -eq 1) { $beam.X1 = $cw + 10 }
            $kx = @(); $ky = @()
            for ($n = 0; $n -le $pts.Count; $n++) {
                $p = $pts[$n % $pts.Count]; $u0 = $n / $pts.Count; $u1 = [Math]::Min(1, $u0 + 0.55 / $pts.Count)
                $kx += , @($u0, ($p[0] * $cw)); $ky += , @($u0, $p[1])
                if ($n -lt $pts.Count) { $kx += , @($u1, ($p[0] * $cw)); $ky += , @($u1, $p[1]) }
            }
            Start-BfxKeys $tf.T $global:BfxP.X $kx $per $d[4]; Start-BfxKeys $tf.T $global:BfxP.Y $ky $per $d[4]
            Start-BfxKeys $beam ([System.Windows.Shapes.Line]::X2Property) $kx $per $d[4]; Start-BfxKeys $beam ([System.Windows.Shapes.Line]::Y2Property) $ky $per $d[4]
        }
    }.GetNewClosure()
    Complete-BfxStage $S
}

function global:Add-BfxEcg {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $mid = $H * 0.55; $field = 4200.0
    $geo = New-BfxGeo { param($c)
        $c.BeginFigure((New-BfxPoint 0 $mid), $false, $false)
        $x = 0.0; $beat = 0
        while ($x -lt $field) {
            $per = $(if (($beat % 9) -ge 6) { 130.0 } else { 220.0 })
            foreach ($k in @(@(0.42, 0), @(0.44, (-0.38)), @(0.46, 0), @(0.48, 0.18), @(0.5, 0), @(0.6, 0), @(0.65, (-0.06)), @(0.7, 0), @(1.0, 0))) { $c.LineTo((New-BfxPoint ($x + $k[0] * $per) ($mid + $k[1] * $H)), $true, $true) }
            $x += $per; $beat++
        }
    }.GetNewClosure()
    $trace = New-BfxPath $geo $null (New-BfxBrush '#50ff96' 1.0) 1.8
    Set-BfxShadow $trace '#40ff90' 8
    $mask = New-Object System.Windows.Media.LinearGradientBrush
    $mask.MappingMode = [System.Windows.Media.BrushMappingMode]::Absolute
    $mask.StartPoint = [System.Windows.Point]::new(-420, 0); $mask.EndPoint = [System.Windows.Point]::new(0, 0)
    foreach ($gs in @(@(0, 0), @(0.999, 255), @(1.0, 0))) { [void]$mask.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromArgb([byte]$gs[1], 0, 0, 0), $gs[0])) }
    $mt = New-Object System.Windows.Media.TranslateTransform 0, 0; $mask.Transform = $mt
    $trace.OpacityMask = $mask
    Add-BfxItem $S $trace -Fx 0 -Top 0
    $S.Extra = { param($cw) Start-BfxAnim $mt $global:BfxP.X 0 ($cw + 420) (($cw + 420) / 260) 0 }.GetNewClosure()
    Complete-BfxStage $S
}

function global:Add-BfxHud {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $ink = New-BfxBrush '#78e6ff' 0.75
    $box = New-Object System.Windows.Controls.Canvas
    $geo = New-BfxGeo { param($c) foreach ($q in @(@(-1, -1), @(1, -1), @(-1, 1), @(1, 1))) { $c.BeginFigure((New-BfxPoint ($q[0] * 20) ($q[1] * 12)), $false, $false); $c.LineTo((New-BfxPoint ($q[0] * 20) ($q[1] * 20)), $true, $false); $c.LineTo((New-BfxPoint ($q[0] * 12) ($q[1] * 20)), $true, $false) } }
    $brk = New-BfxPath $geo $null $ink 1.3; [void]$box.Children.Add($brk)
    $bt = Set-BfxTransforms $brk
    Start-BfxKeys $bt.S $global:BfxP.SX @(@(0, 2), @(0.35, 1), @(1, 1)) 2.5; Start-BfxKeys $bt.S $global:BfxP.SY @(@(0, 2), @(0.35, 1), @(1, 1)) 2.5
    $lock = New-Object System.Windows.Controls.Canvas
    [void]$lock.Children.Add((Set-BfxAt (New-BfxEllipse 8 8 $null $ink 1.2) -4 -4))
    [void]$lock.Children.Add((Set-BfxAt (New-BfxText 'LOCK' '#78e6ff' 0.85 10) 22 -30))
    Start-BfxKeys $lock $global:BfxP.O @(@(0, 0), @(0.35, 0), @(0.36, 1), @(1, 1)) 2.5 -Discrete
    [void]$box.Children.Add($lock)
    $tf = Set-BfxTransforms $box 0 0
    Add-BfxItem $S $box -Fx 0 -Top 0
    $targets = @(); for ($n = 0; $n -lt 5; $n++) { $targets += , @((Get-BfxRnd $S 0.35 0.82), (Get-BfxRnd $S ($H * 0.3) ($H * 0.7))) }
    for ($n = 0; $n -lt 6; $n++) {
        $row = '{0:X4}  {1,3}' -f $S.R.Next(0, 65535), $S.R.Next(0, 360)
        $tb = New-BfxText $row '#78e6ff' 0.5 9
        Start-BfxKeys $tb $global:BfxP.O @(@(0, 1), @(0.48, 1), @(0.5, 0.3), @(0.52, 1), @(1, 1)) (Get-BfxRnd $S 1.2 3) (Get-BfxRnd $S) -Discrete
        Add-BfxItem $S $tb -Fx 1 -OffsetX (-96) -Top (10 + $n * 12)
    }
    $ticks = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint -70 0), $false, $false); $c.LineTo((New-BfxPoint 70 0), $true, $false); for ($k = -7; $k -le 7; $k++) { $c.BeginFigure((New-BfxPoint ($k * 10) 0), $false, $false); $c.LineTo((New-BfxPoint ($k * 10) $(if ($k % 3) { -4 } else { -8 })), $true, $false) } }
    $tk = New-BfxPath $ticks $null $ink 1; $tt = Set-BfxTransforms $tk
    Start-BfxAnim $tt.T $global:BfxP.X 0 (-10) 0.5
    Add-BfxItem $S $tk -Fx 0.5 -Top ($H - 10)
    $S.Extra = { param($cw)
        $kx = @(); $ky = @()
        for ($n = 0; $n -lt $targets.Count; $n++) { $kx += , @(($n / $targets.Count), ($targets[$n][0] * $cw)); $ky += , @(($n / $targets.Count), $targets[$n][1]) }
        Start-BfxKeys $tf.T $global:BfxP.X $kx (2.5 * $targets.Count) -Discrete; Start-BfxKeys $tf.T $global:BfxP.Y $ky (2.5 * $targets.Count) -Discrete
    }.GetNewClosure()
    Complete-BfxStage $S
}

function global:Add-BfxCracks {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($root = 0; $root -lt 6; $root++) {
        $segs = New-Object System.Collections.ArrayList
        $stack = New-Object System.Collections.Stack
        $stack.Push(@(0.0, 0.0, (- [Math]::PI / 2 + (Get-BfxRnd $S -0.5 0.5)), ($H * 0.6), 0))
        while ($stack.Count -gt 0) {
            $b = $stack.Pop(); $x = $b[0]; $y = $b[1]; $a = $b[2]; $len = $b[3]; $dep = $b[4]
            if ($dep -gt 3) { continue }
            $pts = @(, @($x, $y))
            for ($n = 0; $n -lt 5; $n++) { $a += (Get-BfxRnd $S -0.4 0.4); $x += [Math]::Cos($a) * $len / 5; $y += [Math]::Sin($a) * $len / 5; $pts += , @($x, $y) }
            [void]$segs.Add(@($dep, $pts))
            if ((Get-BfxRnd $S) -lt 0.7) { $stack.Push(@($x, $y, ($a - 0.6), ($len * 0.6), ($dep + 1))) }
            if ((Get-BfxRnd $S) -lt 0.7) { $stack.Push(@($x, $y, ($a + 0.6), ($len * 0.6), ($dep + 1))) }
        }
        $geo = New-BfxGeo { param($c) foreach ($sg in $segs) { $pp = $sg[1]; $c.BeginFigure((New-BfxPoint $pp[0][0] $pp[0][1]), $false, $false); for ($n = 1; $n -lt $pp.Count; $n++) { $c.LineTo((New-BfxPoint $pp[$n][0] $pp[$n][1]), $true, $true) } } }.GetNewClosure()
        $grp = New-Object System.Windows.Controls.Canvas
        [void]$grp.Children.Add((New-BfxPath $geo $null (New-BfxBrush '#ff5a14' 0.25) 5))
        [void]$grp.Children.Add((New-BfxPath $geo $null (New-BfxBrush '#ffaa3c' 0.85) 1.8))
        [void]$grp.Children.Add((New-BfxPath $geo $null (New-BfxBrush '#fff0b4' 0.95) 0.7))
        Start-BfxAnim $grp $global:BfxP.O 0.35 1 (Get-BfxRnd $S 2.4 4.5) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $grp -Fx (0.08 + $root * 0.17 + (Get-BfxRnd $S -0.03 0.03)) -Top ($H + 2)
    }
    Complete-BfxStage $S
}

function global:Add-BfxCandles {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $wax = New-BfxBrush '#e8dcc0' 0.9; $fire = New-BfxBrush '#ffbe5a' 0.95
    for ($i = 0; $i -lt 9; $i++) {
        $hh = Get-BfxRnd $S 14 30
        $grp = New-Object System.Windows.Controls.Canvas
        $halo = New-BfxGlow 140 '#ffb45a' 0.3; [void]$grp.Children.Add((Set-BfxAt $halo 0 (-$hh - 6)))
        Start-BfxKeys $halo $global:BfxP.O @(@(0, 0.8), @(0.2, 1), @(0.35, 0.75), @(0.55, 0.95), @(0.7, 0.7), @(1, 0.8)) (Get-BfxRnd $S 0.8 1.6) (Get-BfxRnd $S)
        [void]$grp.Children.Add((Set-BfxAt (New-BfxRect 6 $hh $wax) -3 (-$hh)))
        $flg = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint -3 0), $true, $true); $c.QuadraticBezierTo((New-BfxPoint -4 -8), (New-BfxPoint 0 -14), $true, $false); $c.QuadraticBezierTo((New-BfxPoint 4 -8), (New-BfxPoint 3 0), $true, $false) }
        $flame = New-BfxPath $flg $fire; [void]$grp.Children.Add((Set-BfxAt $flame 0 (-$hh)))
        $ft = Set-BfxTransforms $flame
        Start-BfxKeys $ft.S $global:BfxP.SY @(@(0, 1), @(0.25, 0.82), @(0.5, 1.08), @(0.75, 0.9), @(1, 1)) (Get-BfxRnd $S 0.3 0.6) (Get-BfxRnd $S)
        Start-BfxAnim $ft.R $global:BfxP.A -6 6 (Get-BfxRnd $S 0.6 1.2) (Get-BfxRnd $S) -Reverse -Ease
        [void]$grp.Children.Add((Set-BfxAt (New-BfxGlow 4 '#fff6d8' 1) 0 (-$hh - 4)))
        Add-BfxItem $S $grp -Fx ((($i + 0.5) / 9) + (Get-BfxRnd $S -0.02 0.02)) -Top ($H - 4)
    }
    Complete-BfxStage $S
}

function global:Add-BfxBlackhole {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 40; $i++) { Add-BfxItem $S (New-BfxEllipse 1.4 1.4 (New-BfxBrush '#ffffff' 0.5)) -Fx (Get-BfxRnd $S) -Top (Get-BfxRnd $S 0 $H) }
    $hole = New-Object System.Windows.Controls.Canvas
    [void]$hole.Children.Add((New-BfxGlow ($H * 2.2) '#ff9a3c' 0.25))
    $disc = New-Object System.Windows.Controls.Canvas
    $dt = Set-BfxTransforms $disc 0 0; $dt.S.ScaleY = 0.2
    for ($ringN = 0; $ringN -lt 5; $ringN++) {
        $spin = New-Object System.Windows.Controls.Canvas
        $rr = $H * (0.25 + $ringN * 0.2); $hot = 1 - $ringN / 5.0
        for ($n = 0; $n -lt 28; $n++) {
            $an = (Get-BfxRnd $S 0 (2 * [Math]::PI)); $rj = $rr * (Get-BfxRnd $S 0.9 1.1)
            $col = $(if ($hot -gt 0.6) { '#fff0c8' } else { '#ff9a4d' })
            [void]$spin.Children.Add((Set-BfxAt (New-BfxEllipse 2.2 6 (New-BfxBrush $col (0.4 + 0.6 * $hot))) ([Math]::Cos($an) * $rj) ([Math]::Sin($an) * $rj)))
        }
        $sp = Set-BfxTransforms $spin 0 0
        Start-BfxAnim $sp.R $global:BfxP.A 0 360 (18 + $ringN * 10) (Get-BfxRnd $S)
        [void]$disc.Children.Add($spin)
    }
    [void]$hole.Children.Add($disc)
    $core = New-BfxEllipse ($H * 0.34) ($H * 0.34) (New-BfxBrush '#000000' 1) (New-BfxBrush '#ffc878' 0.85) 1.5
    [void]$hole.Children.Add((Set-BfxAt $core (-$H * 0.17) (-$H * 0.17)))
    Add-BfxItem $S $hole -Fx 0.64 -Top ($H * 0.5)
    Complete-BfxStage $S
}

function global:New-BfxFighter {
    param([string]$Hull = '#c8d0dc', [string]$Engine = '#9fd8ff')
    $grp = New-Object System.Windows.Controls.Canvas
    [void]$grp.Children.Add((Set-BfxAt (New-BfxRect 34 3 (New-BfxLinear @(@(0, $Engine, 0), @(1, $Engine, 0.85)) -Horizontal) 1.5) -40 -1.5))
    $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 10 0), $true, $true); foreach ($q in @(@(-6, -3), @(-4, -9), @(-9, -9), @(-8, 0), @(-9, 9), @(-4, 9), @(-6, 3))) { $c.LineTo((New-BfxPoint $q[0] $q[1]), $true, $false) } }
    [void]$grp.Children.Add((New-BfxPath $geo (New-BfxBrush $Hull 1)))
    $eng = New-BfxGlow 12 $Engine 1; [void]$grp.Children.Add((Set-BfxAt $eng -7 0))
    Start-BfxAnim $eng $global:BfxP.O 0.6 1 0.08 0 -Reverse
    return $grp
}

function global:Add-BfxFighters {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 46; $i++) {
        $st = New-BfxEllipse 1.4 1.4 (New-BfxBrush '#ffffff' 0.45); $tf = Set-BfxTransforms $st
        Add-BfxItem $S $st -Top (Get-BfxRnd $S 0 $H) -Speed (-15) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 5
    }
    $form = New-Object System.Windows.Controls.Canvas
    foreach ($o in @(@(0, 0, 0), @(-34, -16, 0), @(-34, 16, 0), @(-68, -30, 1))) {
        $ship = New-BfxFighter; $st = Set-BfxTransforms $ship 0 0
        [void]$form.Children.Add((Set-BfxAt $ship $o[0] $o[1]))
        if ($o[2]) { Start-BfxAnim $st.T $global:BfxP.Y -25 25 1.6 0 -Reverse -Ease; Start-BfxAnim $st.R $global:BfxP.A 20 -20 1.6 0.25 -Reverse -Ease }
    }
    $ft = Set-BfxTransforms $form 0 0
    Add-BfxItem $S $form -Top ($H * 0.5) -Speed 120 -Phase (Get-BfxRnd $S) -T $ft.T -Margin 150
    Complete-BfxStage $S
}

function global:Add-BfxContrails {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 3; $i++) {
        $jet = New-Object System.Windows.Controls.Canvas
        $trail = New-BfxRect 520 10 (New-BfxLinear @(@(0, '#ffffff', 0), @(0.7, '#ffffff', 0.18), @(1, '#ffffff', 0.4)) -Horizontal) 5
        $bl = New-Object System.Windows.Media.Effects.BlurEffect; $bl.Radius = 6; $trail.Effect = $bl
        [void]$jet.Children.Add((Set-BfxAt $trail -526 -5))
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 6 0), $true, $true); $c.LineTo((New-BfxPoint -6 -2), $true, $false); $c.LineTo((New-BfxPoint -6 2), $true, $false) }
        [void]$jet.Children.Add((New-BfxPath $geo (New-BfxBrush '#e8eef4' 1)))
        $tf = Set-BfxTransforms $jet 0 0; $tf.R.Angle = Get-BfxRnd $S -6 6
        Add-BfxItem $S $jet -Top ($H * (0.2 + $i * 0.25)) -Speed (Get-BfxRnd $S 120 200) -Phase (Get-BfxRnd $S) -T $tf.T -Margin 560
    }
    Complete-BfxStage $S
}

function global:Add-BfxPuddles {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $drop = New-BfxBrush '#aac8e6' 0.35
    for ($i = 0; $i -lt 55; $i++) {
        $ln = New-BfxRect 1 9 $drop; $tf = Set-BfxTransforms $ln; $tf.R.Angle = 6
        Start-BfxAnim $tf.T $global:BfxP.Y (-12) ($H + 4) (($H + 16) / (Get-BfxRnd $S 300 500)) (Get-BfxRnd $S)
        Add-BfxItem $S $ln -Fx (Get-BfxRnd $S) -Top 0
    }
    $ripple = New-BfxBrush '#bed7f0' 0.6
    for ($i = 0; $i -lt 18; $i++) {
        $rp = New-BfxEllipse 44 13 $null $ripple 1; $rp.Margin = [System.Windows.Thickness]::new(-22, -6.5, 0, 0)
        $tf = Set-BfxTransforms $rp; $per = Get-BfxRnd $S 1.1 2.0; $ph = Get-BfxRnd $S
        Start-BfxKeys $tf.S $global:BfxP.SX @(@(0, 0.05), @(0.6, 1), @(1, 1)) $per $ph; Start-BfxKeys $tf.S $global:BfxP.SY @(@(0, 0.05), @(0.6, 1), @(1, 1)) $per $ph
        Start-BfxKeys $rp $global:BfxP.O @(@(0, 0.9), @(0.6, 0), @(1, 0)) $per $ph
        Add-BfxItem $S $rp -Fx (Get-BfxRnd $S) -Top ($H * (Get-BfxRnd $S 0.75 0.97))
    }
    Complete-BfxStage $S
}

function global:Add-BfxTumbleweed {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    foreach ($w in @(@(14, 70, 0.0), @(10, 50, 0.45))) {
        $rad = $w[0]
        $geo = New-BfxGeo { param($c)
            for ($n = 0; $n -lt 34; $n++) { $a = Get-BfxRnd $S 0 6.283; $b = $a + (Get-BfxRnd $S -1 1); $c.BeginFigure((New-BfxPoint ([Math]::Cos($a) * $rad) ([Math]::Sin($a) * $rad)), $false, $false); $c.QuadraticBezierTo((New-BfxPoint 0 0), (New-BfxPoint ([Math]::Cos($b) * $rad) ([Math]::Sin($b) * $rad)), $true, $false) }
            $c.BeginFigure((New-BfxPoint $rad 0), $false, $true); $c.ArcTo((New-BfxPoint (-$rad) 0), [System.Windows.Size]::new($rad, $rad), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false); $c.ArcTo((New-BfxPoint $rad 0), [System.Windows.Size]::new($rad, $rad), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false)
        }.GetNewClosure()
        $weed = New-BfxPath $geo $null (New-BfxBrush '#b48c50' 0.9) 1
        $rt = Set-BfxTransforms $weed
        Start-BfxAnim $rt.R $global:BfxP.A 0 360 (2 * [Math]::PI * $rad / $w[1]) 0
        $grp = New-Object System.Windows.Controls.Canvas; [void]$grp.Children.Add($weed)
        $tf = Set-BfxTransforms $grp 0 0; $bounce = 0.98
        $ky = @(); for ($n = 0; $n -le 8; $n++) { $u = $n / 8.0; $ky += , @($u, (-[Math]::Abs([Math]::Sin($u * [Math]::PI)) * $H * 0.35)) }
        Start-BfxKeys $tf.T $global:BfxP.Y $ky $bounce (Get-BfxRnd $S)
        $puff = New-BfxGlow 46 '#c8a46e' 0.35; Start-BfxKeys $puff $global:BfxP.O @(@(0, 1), @(0.15, 0), @(0.9, 0), @(1, 1)) $bounce
        $wrap = New-Object System.Windows.Controls.Canvas; [void]$wrap.Children.Add($grp); [void]$wrap.Children.Add((Set-BfxAt $puff 0 ($rad)))
        $wt = Set-BfxTransforms $wrap 0 0
        Add-BfxItem $S $wrap -Top ($H - $rad - 4) -Speed $w[1] -Phase $w[2] -T $wt.T -Margin 60
    }
    Complete-BfxStage $S
}

function global:Add-BfxBats {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    Add-BfxItem $S (New-BfxGlow ($H * 1.2) '#d8d0ff' 0.18) -Fx 0.8 -Top ($H * 0.3)
    $ink = New-BfxBrush '#0a0610' 1
    $flock = New-Object System.Windows.Controls.Canvas
    for ($i = 0; $i -lt 18; $i++) {
        $sz = Get-BfxRnd $S 4 8
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 0), $true, $true); $c.QuadraticBezierTo((New-BfxPoint (-$sz) (-$sz)), (New-BfxPoint (-$sz * 2) (-$sz * 0.3)), $true, $false); $c.QuadraticBezierTo((New-BfxPoint (-$sz * 1.2) ($sz * 0.2)), (New-BfxPoint 0 ($sz * 0.3)), $true, $false); $c.QuadraticBezierTo((New-BfxPoint ($sz * 1.2) ($sz * 0.2)), (New-BfxPoint ($sz * 2) (-$sz * 0.3)), $true, $false); $c.QuadraticBezierTo((New-BfxPoint $sz (-$sz)), (New-BfxPoint 0 0), $true, $false) }.GetNewClosure()
        $bat = New-BfxPath $geo $ink; $tf = Set-BfxTransforms $bat
        Start-BfxAnim $tf.S $global:BfxP.SY 1 -0.4 (Get-BfxRnd $S 0.12 0.18) (Get-BfxRnd $S) -Reverse
        Start-BfxAnim $tf.T $global:BfxP.X -12 12 (Get-BfxRnd $S 1.2 2) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxAnim $tf.T $global:BfxP.Y -10 10 (Get-BfxRnd $S 0.8 1.4) (Get-BfxRnd $S) -Reverse -Ease
        [void]$flock.Children.Add((Set-BfxAt $bat (- (Get-BfxRnd $S 0 200)) (Get-BfxRnd $S (-$H * 0.3) ($H * 0.3))))
    }
    $ft = Set-BfxTransforms $flock 0 0
    Add-BfxItem $S $flock -Top ($H * 0.45) -Speed 110 -Phase (Get-BfxRnd $S) -T $ft.T -Margin 230
    Complete-BfxStage $S
}

function global:Add-BfxMoths {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $ly = $H * 0.32
    $lamp = New-Object System.Windows.Controls.Canvas
    [void]$lamp.Children.Add((Set-BfxAt (New-BfxRect 1 ($ly - 6) (New-BfxBrush '#505050' 0.6)) 0 (-$ly)))
    $halo = New-BfxGlow ($H * 1.8) '#ffe8b0' 0.35; [void]$lamp.Children.Add($halo)
    Start-BfxKeys $halo $global:BfxP.O @(@(0, 1), @(0.3, 0.85), @(0.32, 1), @(0.7, 0.9), @(0.72, 0.7), @(0.74, 1), @(1, 1)) 2.3
    [void]$lamp.Children.Add((Set-BfxAt (New-BfxEllipse 10 10 (New-BfxBrush '#fff6d8' 1)) -5 -5))
    $wing = New-BfxBrush '#c8bea9' 0.85
    for ($i = 0; $i -lt 12; $i++) {
        $orb = New-Object System.Windows.Controls.Canvas; $ot = Set-BfxTransforms $orb 0 0
        $moth = New-Object System.Windows.Controls.Canvas
        [void]$moth.Children.Add((Set-BfxAt (New-BfxEllipse 5 3 $wing) -5 -1.5)); [void]$moth.Children.Add((Set-BfxAt (New-BfxEllipse 5 3 $wing) 0 -1.5))
        $mt = Set-BfxTransforms $moth 0 0
        Start-BfxAnim $mt.S $global:BfxP.SY 1 0.2 (Get-BfxRnd $S 0.04 0.07) (Get-BfxRnd $S) -Reverse
        $rr = Get-BfxRnd $S 14 60
        Start-BfxAnim $mt.T $global:BfxP.X ($rr * 0.6) ($rr * 1.2) (Get-BfxRnd $S 0.8 1.6) (Get-BfxRnd $S) -Reverse -Ease
        [void]$orb.Children.Add($moth)
        Start-BfxAnim $ot.R $global:BfxP.A 0 (Get-BfxPick $S @(360, -360)) (Get-BfxRnd $S 1.2 2.6) (Get-BfxRnd $S)
        $squash = New-Object System.Windows.Controls.Canvas; [void]$squash.Children.Add($orb)
        $sq = Set-BfxTransforms $squash 0 0; $sq.S.ScaleY = Get-BfxRnd $S 0.3 0.8; $sq.S.ScaleX = 1.5
        [void]$lamp.Children.Add($squash)
    }
    Add-BfxItem $S $lamp -Fx 0.62 -Top $ly
    Complete-BfxStage $S
}

function global:Add-BfxJellyfish {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 7; $i++) {
        $col = Get-BfxPick $S @('#ff8ad8', '#8adcff', '#b48aff'); $sz = Get-BfxRnd $S 8 18
        $grp = New-Object System.Windows.Controls.Canvas
        [void]$grp.Children.Add((New-BfxGlow ($sz * 6) $col 0.25))
        $tg = New-BfxGeo { param($c) for ($k = -2; $k -le 2; $k++) { $x0 = $k * $sz * 0.3; $c.BeginFigure((New-BfxPoint $x0 0), $false, $false); for ($n = 1; $n -lt 8; $n++) { $c.LineTo((New-BfxPoint ($x0 + [Math]::Sin($n * 0.9 + $k) * 3) ($n * $sz * 0.35)), $true, $true) } } }.GetNewClosure()
        $tent = New-BfxPath $tg $null (New-BfxBrush $col 0.5) 1; $tt = Set-BfxTransforms $tent
        Start-BfxAnim $tt.R $global:BfxP.A -6 6 (Get-BfxRnd $S 1.5 2.5) (Get-BfxRnd $S) -Reverse -Ease
        [void]$grp.Children.Add($tent)
        $bg = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint (-$sz) 0), $true, $true); $c.ArcTo((New-BfxPoint $sz 0), [System.Windows.Size]::new($sz, $sz * 0.7), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false) }.GetNewClosure()
        $bell = New-BfxPath $bg (New-BfxBrush $col 0.6); $bt = Set-BfxTransforms $bell
        $per = Get-BfxRnd $S 1.8 2.6; $ph = Get-BfxRnd $S
        Start-BfxAnim $bt.S $global:BfxP.SX 1 1.15 ($per / 2) $ph -Reverse -Ease; Start-BfxAnim $bt.S $global:BfxP.SY 1 0.8 ($per / 2) $ph -Reverse -Ease
        [void]$grp.Children.Add($bell)
        $tf = Set-BfxTransforms $grp 0 0
        Start-BfxAnim $tf.T $global:BfxP.Y ($H + 40) (-40 - $sz * 3) (($H + 80) / (Get-BfxRnd $S 8 18)) (Get-BfxRnd $S)
        Start-BfxAnim $tf.T $global:BfxP.X -10 10 (Get-BfxRnd $S 5 9) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $grp -Fx (Get-BfxRnd $S 0.05 0.95) -Top 0
    }
    Complete-BfxStage $S
}

function global:Add-BfxKelp {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 4; $i++) {
        $fl = New-BfxGlow 120 '#a0ffd8' 0.1; $tf = Set-BfxTransforms $fl
        Add-BfxItem $S $fl -Top ($H * 0.3) -Speed 20 -Phase ($i / 4.0) -T $tf.T -Margin 100
    }
    $stem = New-BfxBrush '#288c50' 0.8; $leaf = New-BfxBrush '#3caa64' 0.7
    for ($i = 0; $i -lt 16; $i++) {
        $len = $H * (Get-BfxRnd $S 0.55 1.1); $wd = Get-BfxRnd $S 3 7; $bend = Get-BfxRnd $S -10 10
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 0), $false, $false); $c.QuadraticBezierTo((New-BfxPoint $bend (-$len * 0.5)), (New-BfxPoint ($bend * 0.4) (-$len)), $true, $true) }.GetNewClosure()
        $grp = New-Object System.Windows.Controls.Canvas
        [void]$grp.Children.Add((New-BfxPath $geo $null $stem $wd))
        for ($n = 2; $n -lt 12; $n += 2) { $u = $n / 12.0; $lx = 2 * (1 - $u) * $u * $bend + $u * $u * $bend * 0.4; $lf = New-BfxEllipse 12 5 $leaf; $lt = Set-BfxTransforms $lf; $lt.R.Angle = Get-BfxPick $S @(-30, 30, 210, 150); [void]$grp.Children.Add((Set-BfxAt $lf ($lx - 2) (-$len * $u))) }
        $tf = Set-BfxTransforms $grp 0 0
        Start-BfxAnim $tf.R $global:BfxP.A -7 7 (Get-BfxRnd $S 3 5) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $grp -Fx (Get-BfxRnd $S) -Top ($H + 4)
    }
    Complete-BfxStage $S
}

function global:Add-BfxFlakes {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }
    $ice = New-BfxBrush '#e1f0ff' 0.85
    Add-BfxFallers $S $BannerH 22 {
        $sz = Get-BfxRnd $S 4 12
        $geo = New-BfxGeo { param($c) for ($n = 0; $n -lt 6; $n++) { $a = $n * [Math]::PI / 3; $ca = [Math]::Cos($a); $sa = [Math]::Sin($a)
            $c.BeginFigure((New-BfxPoint 0 0), $false, $false); $c.LineTo((New-BfxPoint ($ca * $sz) ($sa * $sz)), $true, $false)
            foreach ($sd in @(-0.5, 0.5)) { $c.BeginFigure((New-BfxPoint ($ca * $sz * 0.55) ($sa * $sz * 0.55)), $false, $false); $c.LineTo((New-BfxPoint ($ca * $sz * 0.75 - $sa * $sz * $sd * 0.5) ($sa * $sz * 0.75 + $ca * $sz * $sd * 0.5)), $true, $false) } } }.GetNewClosure()
        New-BfxPath $geo $null $ice 1
    }.GetNewClosure() 8 22 -10 10 12
    Complete-BfxStage $S
}

function global:Add-BfxSpotlights {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $len = $H * 1.7
    foreach ($b in @(@('#ff3fa4', 0.15), @('#3fd0ff', 0.4), @('#ffd23f', 0.62), @('#9a5cff', 0.86))) {
        $col = $b[0]
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 0), $true, $true); $c.LineTo((New-BfxPoint (-$len * 0.12) (-$len)), $true, $false); $c.LineTo((New-BfxPoint ($len * 0.12) (-$len)), $true, $false) }.GetNewClosure()
        $beam = New-BfxPath $geo (New-BfxLinear @(@(0, $col, 0), @(1, $col, 0.32)))
        $tf = Set-BfxTransforms $beam
        Start-BfxAnim $tf.R $global:BfxP.A -32 32 (Get-BfxRnd $S 3.5 6) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $beam -Fx $b[1] -Top ($H + 10)
        Add-BfxItem $S (New-BfxGlow 40 $col 0.8) -Fx $b[1] -Top $H
    }
    Complete-BfxStage $S
}

function global:Add-BfxFireworks {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 5; $i++) {
        $col = Get-BfxPick $S @('#ff4d6a', '#ffd24d', '#4dd0ff', '#7dff6a', '#c07bff')
        $per = Get-BfxRnd $S 2.6 4.2; $ph = Get-BfxRnd $S; $top = $H * (Get-BfxRnd $S 0.2 0.45)
        $rocket = New-BfxGlow 6 '#fff0c8' 1; $rt = Set-BfxTransforms $rocket
        Start-BfxKeys $rt.T $global:BfxP.Y @(@(0, ($H + 5)), @(0.22, $top), @(1, $top)) $per $ph
        Start-BfxKeys $rocket $global:BfxP.O @(@(0, 1), @(0.22, 1), @(0.221, 0), @(1, 0)) $per $ph
        Add-BfxItem $S $rocket -Fx (0.1 + $i * 0.19) -Top 0
        $burst = New-Object System.Windows.Controls.Canvas
        $fl = New-BfxGlow 80 $col 0.9; [void]$burst.Children.Add($fl)
        Start-BfxKeys $fl $global:BfxP.O @(@(0, 0), @(0.22, 0), @(0.225, 1), @(0.3, 0), @(1, 0)) $per $ph
        for ($n = 0; $n -lt 36; $n++) {
            $a = $n / 36.0 * 2 * [Math]::PI; $vel = Get-BfxRnd $S 34 58
            $sp = New-BfxEllipse 2.6 2.6 (New-BfxBrush $col 1); $st = Set-BfxTransforms $sp
            Start-BfxKeys $st.T $global:BfxP.X @(@(0, 0), @(0.22, 0), @(0.45, ([Math]::Cos($a) * $vel)), @(0.75, ([Math]::Cos($a) * $vel * 1.15)), @(1, 0)) $per $ph
            Start-BfxKeys $st.T $global:BfxP.Y @(@(0, 0), @(0.22, 0), @(0.45, ([Math]::Sin($a) * $vel)), @(0.75, ([Math]::Sin($a) * $vel * 1.15 + 22)), @(1, 0)) $per $ph
            Start-BfxKeys $sp $global:BfxP.O @(@(0, 0), @(0.22, 0), @(0.225, 1), @(0.6, 0.8), @(0.75, 0), @(1, 0)) $per $ph
            [void]$burst.Children.Add($sp)
        }
        Add-BfxItem $S $burst -Fx (0.1 + $i * 0.19) -Top $top
    }
    Complete-BfxStage $S
}


# ------------------------------------------------------------
# Round 2 effects (part 2)
# ------------------------------------------------------------

function global:Add-BfxBalloons {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $string = New-BfxBrush '#e6e6e6' 0.6; $shine = New-BfxBrush '#ffffff' 0.7
    for ($i = 0; $i -lt 12; $i++) {
        $col = Get-BfxPick $S @('#ff4d6a', '#ffd24d', '#4dd0ff', '#7dff6a', '#c07bff', '#ff9a3d'); $sz = Get-BfxRnd $S 9 15
        $grp = New-Object System.Windows.Controls.Canvas
        $sg = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 ($sz * 1.2)), $false, $false); $c.QuadraticBezierTo((New-BfxPoint (-6) ($sz * 2.2)), (New-BfxPoint 3 ($sz * 3.2)), $true, $false) }.GetNewClosure()
        [void]$grp.Children.Add((New-BfxPath $sg $null $string 0.8))
        $fill = New-BfxBrush $col 0.92
        [void]$grp.Children.Add((Set-BfxAt (New-BfxEllipse ($sz * 1.7) ($sz * 2.2) $fill) (-$sz * 0.85) (-$sz * 1.1)))
        $kg = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint -2 ($sz * 1.08)), $true, $true); $c.LineTo((New-BfxPoint 2 ($sz * 1.08)), $true, $false); $c.LineTo((New-BfxPoint 0 ($sz * 1.3)), $true, $false) }.GetNewClosure()
        [void]$grp.Children.Add((New-BfxPath $kg $fill))
        [void]$grp.Children.Add((Set-BfxAt (New-BfxEllipse ($sz * 0.36) ($sz * 0.36) $shine) (-$sz * 0.48) (-$sz * 0.63)))
        $tf = Set-BfxTransforms $grp 0 0
        Start-BfxAnim $tf.T $global:BfxP.Y ($H + $sz * 1.2) (-$sz * 3.5) (($H + $sz * 5) / (Get-BfxRnd $S 14 28)) (Get-BfxRnd $S)
        Start-BfxAnim $tf.R $global:BfxP.A -8 8 (Get-BfxRnd $S 2 3.5) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $grp -Fx (Get-BfxRnd $S 0.05 0.95) -Top 0
    }
    Complete-BfxStage $S
}

function global:Add-BfxFairydust {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $loopX = 9.0; $loopY = 3.3
    $items = @()
    for ($i = 0; $i -lt 34; $i++) {
        $lag = $i * 0.035
        if ($i -eq 0) { $el = New-Object System.Windows.Controls.Canvas; [void]$el.Children.Add((New-BfxGlow 46 '#e8f8ff' 0.7)); [void]$el.Children.Add((New-BfxGlow 7 '#ffffff' 1)) }
        else {
            $el = New-BfxGlow (Get-BfxRnd $S 3 6) (Get-BfxPick $S @('#fff6b0', '#b0f0ff', '#ffc0f0')) 1
            Start-BfxKeys $el $global:BfxP.O @(@(0, (1 - $i / 34.0)), @(0.5, (0.35 * (1 - $i / 34.0))), @(1, (1 - $i / 34.0))) (Get-BfxRnd $S 0.15 0.35) (Get-BfxRnd $S) -Discrete
        }
        $tf = Set-BfxTransforms $el 0 0
        $drop = $(if ($i -eq 0) { 0 } else { $i * 0.6 + (Get-BfxRnd $S -3 3) })
        $ky = @(); for ($n = 0; $n -le 16; $n++) { $u = $n / 16.0; $ky += , @($u, ($H * (0.5 + 0.3 * [Math]::Sin($u * 2 * [Math]::PI)) + $drop)) }
        Start-BfxKeys $tf.T $global:BfxP.Y $ky $loopY ((1 - $lag / $loopY) % 1)
        Add-BfxItem $S $el -Fx 0 -Top 0
        $items += , @($tf, $lag, (Get-BfxRnd $S -3 3))
    }
    $S.Extra = { param($cw)
        foreach ($it in $items) {
            $kx = @(); for ($n = 0; $n -le 24; $n++) { $u = $n / 24.0; $kx += , @($u, ($cw * (0.5 + 0.38 * [Math]::Sin($u * 2 * [Math]::PI)) + $it[2])) }
            Start-BfxKeys $it[0].T $global:BfxP.X $kx $loopX ((1 - $it[1] / $loopX) % 1)
        }
    }.GetNewClosure()
    Complete-BfxStage $S
}

function global:Add-BfxPaperplanes {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $top = New-BfxBrush '#f5f5f0' 0.95; $under = New-BfxBrush '#c8cdd7' 0.95
    $g1 = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 12 0), $true, $true); $c.LineTo((New-BfxPoint -10 -6), $true, $false); $c.LineTo((New-BfxPoint -6 0), $true, $false) }
    $g2 = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 12 0), $true, $true); $c.LineTo((New-BfxPoint -10 5), $true, $false); $c.LineTo((New-BfxPoint -6 0), $true, $false) }
    for ($i = 0; $i -lt 5; $i++) {
        $plane = New-Object System.Windows.Controls.Canvas
        [void]$plane.Children.Add((New-BfxPath $g1 $top)); [void]$plane.Children.Add((New-BfxPath $g2 $under))
        $pt = Set-BfxTransforms $plane 0 0
        $per = Get-BfxRnd $S 4 9; $ph = Get-BfxRnd $S; $amp = Get-BfxRnd $S 12 32
        Start-BfxAnim $pt.T $global:BfxP.Y (-$amp) $amp ($per / 2) $ph -Reverse -Ease
        Start-BfxAnim $pt.R $global:BfxP.A 14 -14 ($per / 2) $ph -Reverse -Ease
        $wrap = New-Object System.Windows.Controls.Canvas; [void]$wrap.Children.Add($plane); $wt = Set-BfxTransforms $wrap 0 0
        Add-BfxItem $S $wrap -Top ($H * (Get-BfxRnd $S 0.25 0.75)) -Speed (Get-BfxRnd $S 60 110) -Phase (Get-BfxRnd $S) -T $wt.T -Margin 60
    }
    Complete-BfxStage $S
}

function global:Add-BfxDice {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $bone = New-BfxBrush '#f4f0e8' 1; $edge = New-BfxBrush '#8a8070' 1; $pip = New-BfxBrush '#c0242a' 1; $paper = New-BfxBrush '#f8f4ea' 1; $rim = New-BfxBrush '#b8a888' 1
    $pips = @{ 1 = @(@(0, 0)); 2 = @(@(-3, -3), @(3, 3)); 3 = @(@(-3, -3), @(0, 0), @(3, 3)); 4 = @(@(-3, -3), @(3, -3), @(-3, 3), @(3, 3)); 5 = @(@(-3, -3), @(3, -3), @(0, 0), @(-3, 3), @(3, 3)); 6 = @(@(-3, -3), @(3, -3), @(-3, 0), @(3, 0), @(-3, 3), @(3, 3)) }
    for ($i = 0; $i -lt 12; $i++) {
        $grp = New-Object System.Windows.Controls.Canvas
        if ($i % 3) {
            $face = New-BfxRect 14 14 $bone 3; $face.Stroke = $edge; $face.StrokeThickness = 1; [void]$grp.Children.Add((Set-BfxAt $face -7 -7))
            foreach ($q in $pips[$S.R.Next(1, 7)]) { [void]$grp.Children.Add((Set-BfxAt (New-BfxEllipse 2.6 2.6 $pip) ($q[0] - 1.3) ($q[1] - 1.3))) }
        } else {
            $card = New-BfxRect 16 22 $paper 2; $card.Stroke = $rim; $card.StrokeThickness = 1; [void]$grp.Children.Add((Set-BfxAt $card -8 -11))
            $hg = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 4), $true, $true); $c.BezierTo((New-BfxPoint -6 -1), (New-BfxPoint -3 -5), (New-BfxPoint 0 -2), $true, $false); $c.BezierTo((New-BfxPoint 3 -5), (New-BfxPoint 6 -1), (New-BfxPoint 0 4), $true, $false) }
            [void]$grp.Children.Add((New-BfxPath $hg $pip))
        }
        $it = Set-BfxTransforms $grp 0 0
        Start-BfxAnim $it.R $global:BfxP.A 0 (Get-BfxPick $S @(360, -360)) (Get-BfxRnd $S 2.5 4.5) (Get-BfxRnd $S)
        if (-not ($i % 3)) { Start-BfxAnim $it.S $global:BfxP.SX 1 -1 (Get-BfxRnd $S 1.2 2) (Get-BfxRnd $S) -Reverse -Ease }
        Start-BfxAnim $it.T $global:BfxP.Y -12 12 (Get-BfxRnd $S 1.5 2.5) (Get-BfxRnd $S) -Reverse -Ease
        $wrap = New-Object System.Windows.Controls.Canvas; [void]$wrap.Children.Add($grp); $wt = Set-BfxTransforms $wrap 0 0
        Add-BfxItem $S $wrap -Top ($H * (Get-BfxRnd $S 0.2 0.8)) -Speed (Get-BfxRnd $S 30 70) -Phase (Get-BfxRnd $S) -T $wt.T -Margin 30
    }
    Complete-BfxStage $S
}

function global:Add-BfxGears {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $brass = New-BfxBrush '#be9650' 0.3; $line = New-BfxBrush '#e6be6e' 0.6
    # centre (x px from anchor, y), radius, teeth; neighbours mesh with the first gear
    $r0 = $H * 0.42
    $set = ,@(0, ($H * 0.55), $r0, 16, 1.0)
    foreach ($nb in @(@(-0.9, 0.26, 10), @(2.3, 0.3, 12), @(0.5, 0.2, 8))) {
        $rn = $H * $nb[1]; $dist = ($r0 + $rn) * 1.04; $an = $nb[0]
        $set += , @(([Math]::Cos($an) * $dist), ($H * 0.55 + [Math]::Sin($an) * $dist), $rn, $nb[2], (-16.0 / $nb[2]))
    }
    foreach ($gr in $set) {
        $rad = $gr[2]; $teeth = $gr[3]
        $geo = New-BfxGeo -EvenOdd { param($c)
            $nseg = $teeth * 4
            for ($n = 0; $n -le $nseg; $n++) { $a = $n / $nseg * 2 * [Math]::PI; $rr = $(if (($n % 4) -lt 2) { $rad * 1.16 } else { $rad }); $pt = New-BfxPoint ([Math]::Cos($a) * $rr) ([Math]::Sin($a) * $rr); if ($n -eq 0) { $c.BeginFigure($pt, $true, $true) } else { $c.LineTo($pt, $true, $true) } }
            $ri = $rad * 0.3; $c.BeginFigure((New-BfxPoint $ri 0), $true, $true); $c.ArcTo((New-BfxPoint (-$ri) 0), [System.Windows.Size]::new($ri, $ri), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false); $c.ArcTo((New-BfxPoint $ri 0), [System.Windows.Size]::new($ri, $ri), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false)
            for ($n = 0; $n -lt 4; $n++) { $a = $n * [Math]::PI / 2; $c.BeginFigure((New-BfxPoint ([Math]::Cos($a) * $ri) ([Math]::Sin($a) * $ri)), $false, $false); $c.LineTo((New-BfxPoint ([Math]::Cos($a) * $rad * 0.85) ([Math]::Sin($a) * $rad * 0.85)), $true, $false) }
        }.GetNewClosure()
        $gear = New-BfxPath $geo $brass $line 1.2
        $tf = Set-BfxTransforms $gear
        $direction = [double]$gr[4]
        $sec = 24.0 / [Math]::Abs($direction)
        Start-BfxAnim $tf.R $global:BfxP.A 0 ([Math]::Sign($direction) * 360) $sec 0
        Add-BfxItem $S $gear -Fx 0.62 -OffsetX $gr[0] -Top $gr[1]
    }
    Complete-BfxStage $S
}

function global:Add-BfxHelix {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $mid = $H * 0.5; $amp = $H * 0.3; $per = 4.0
    $blue = New-BfxBrush '#7dd0ff' 0.9; $violet = New-BfxBrush '#c07bff' 0.9
    for ($x = 0.0; $x -lt 2200; $x += 24) {
        $ph = (($x * 0.025) / (2 * [Math]::PI)) % 1
        $rung = New-BfxRect 1 ($amp * 2) (New-BfxBrush '#78b4ff' 0.3); $rt = Set-BfxTransforms $rung
        Start-BfxAnim $rt.S $global:BfxP.SY -1 1 ($per / 2) $ph -Reverse -Ease
        $at = ($x / 2200.0) % 1
        Start-BfxKeys $rung $global:BfxP.O @(@(0, 0.35), @($at, 0.35), @([Math]::Min(0.999, $at + 0.02), 1), @([Math]::Min(1, $at + 0.08), 0.35), @(1, 0.35)) 2.2
        Add-BfxItem $S $rung -Fx 0 -OffsetX $x -Top ($mid - $amp)
        foreach ($sd in @(@($blue, 0), @($violet, 0.5))) {
            $d = New-BfxEllipse 4.5 4.5 $sd[0]; $d.Margin = [System.Windows.Thickness]::new(-2.25, -2.25, 0, 0); $dt = Set-BfxTransforms $d
            Start-BfxAnim $dt.T $global:BfxP.Y (-$amp) $amp ($per / 2) (($ph + $sd[1]) % 1) -Reverse -Ease
            Start-BfxAnim $d $global:BfxP.O 0.25 1 ($per / 2) (($ph + $sd[1] + 0.25) % 1) -Reverse -Ease
            Add-BfxItem $S $d -Fx 0 -OffsetX $x -Top $mid
        }
    }
    Complete-BfxStage $S
}

function global:Add-BfxToxicgas {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 18; $i++) {
        $sz = Get-BfxRnd $S 70 170
        $blob = New-BfxGlow $sz '#b8e040' 0.2; $tf = Set-BfxTransforms $blob
        Start-BfxAnim $tf.T $global:BfxP.Y -8 8 (Get-BfxRnd $S 4 8) (Get-BfxRnd $S) -Reverse -Ease
        Start-BfxAnim $tf.S $global:BfxP.SX 0.9 1.1 (Get-BfxRnd $S 3 6) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $blob -Top ($H * (Get-BfxRnd $S 0.5 1.1)) -Speed (Get-BfxRnd $S 4 14) -Phase (Get-BfxRnd $S) -T $tf.T -Margin ($sz / 2)
    }
    for ($i = 0; $i -lt 14; $i++) {
        $sp = New-BfxEllipse 2 2 (New-BfxBrush '#e8ff9a' 1)
        Start-BfxFlash $sp (Get-BfxRnd $S 1 2.5) (Get-BfxRnd $S 0.05 0.9) 0.2 0.6
        Add-BfxItem $S $sp -Fx (Get-BfxRnd $S) -Top ($H * (Get-BfxRnd $S 0.6 0.95))
    }
    Complete-BfxStage $S
}

function global:Add-BfxClaws {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 4; $i++) {
        $len = $H * (Get-BfxRnd $S 0.9 1.3)
        $geo = New-BfxGeo { param($c) for ($k = -1; $k -le 1; $k++) { $oy = $k * 12; $c.BeginFigure((New-BfxPoint 0 $oy), $false, $false); $c.QuadraticBezierTo((New-BfxPoint ($len / 2) ($oy + 6)), (New-BfxPoint $len $oy), $true, $false) } }.GetNewClosure()
        $grp = New-Object System.Windows.Controls.Canvas
        [void]$grp.Children.Add((New-BfxPath $geo $null (New-BfxBrush '#ff783c' 0.35) 7))
        [void]$grp.Children.Add((New-BfxPath $geo $null (New-BfxBrush '#ffdcb4' 1) 2))
        $tf = Set-BfxTransforms $grp 0 0; $tf.R.Angle = Get-BfxRnd $S 20 45
        $per = Get-BfxRnd $S 3 5.5; $ph = Get-BfxRnd $S; $at = Get-BfxRnd $S 0.05 0.6
        Start-BfxKeys $tf.S $global:BfxP.SX @(@(0, 0), @($at, 0), @(($at + 0.03), 1), @(1, 1)) $per $ph
        Start-BfxKeys $grp $global:BfxP.O @(@(0, 0), @($at, 0), @(($at + 0.005), 1), @(($at + 0.12), 1), @(($at + 0.35), 0), @(1, 0)) $per $ph
        Add-BfxItem $S $grp -Fx (Get-BfxRnd $S 0.2 0.75) -Top ($H * (Get-BfxRnd $S 0.0 0.3))
    }
    Complete-BfxStage $S
}

function global:Add-BfxGlasscracks {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $crack = New-BfxBrush '#dcebf5' 0.6
    for ($i = 0; $i -lt 6; $i++) {
        $rays = @(); for ($n = 0; $n -lt 9; $n++) { $rays += , @((Get-BfxRnd $S 0 6.283), (Get-BfxRnd $S 12 42)) }
        $geo = New-BfxGeo { param($c)
            foreach ($ry in $rays) { $c.BeginFigure((New-BfxPoint 0 0), $false, $false); $c.LineTo((New-BfxPoint ([Math]::Cos($ry[0]) * $ry[1] * 0.5 + 2) ([Math]::Sin($ry[0]) * $ry[1] * 0.5)), $true, $true); $c.LineTo((New-BfxPoint ([Math]::Cos($ry[0]) * $ry[1]) ([Math]::Sin($ry[0]) * $ry[1])), $true, $true) }
            $c.BeginFigure((New-BfxPoint 9 0), $false, $true); $c.ArcTo((New-BfxPoint -9 0), [System.Windows.Size]::new(9, 9), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false); $c.ArcTo((New-BfxPoint 9 0), [System.Windows.Size]::new(9, 9), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false)
        }.GetNewClosure()
        $grp = New-Object System.Windows.Controls.Canvas
        [void]$grp.Children.Add((New-BfxPath $geo $null $crack 0.8))
        [void]$grp.Children.Add((Set-BfxAt (New-BfxEllipse 5 5 (New-BfxBrush '#05070a' 1)) -2.5 -2.5))
        $tf = Set-BfxTransforms $grp 0 0
        $per = Get-BfxRnd $S 4.5 7; $ph = Get-BfxRnd $S
        Start-BfxKeys $tf.S $global:BfxP.SX @(@(0, 0.1), @(0.015, 1), @(1, 1)) $per $ph; Start-BfxKeys $tf.S $global:BfxP.SY @(@(0, 0.1), @(0.015, 1), @(1, 1)) $per $ph
        Start-BfxKeys $grp $global:BfxP.O @(@(0, 1), @(0.7, 1), @(0.9, 0), @(1, 0)) $per $ph
        Add-BfxItem $S $grp -Fx (Get-BfxRnd $S 0.15 0.9) -Top ($H * (Get-BfxRnd $S 0.2 0.8))
    }
    Complete-BfxStage $S
}

# A trail of prints appearing one after another across the banner.
function global:Add-BfxTrail {
    param($S, [double]$H, [int]$Count, [double]$Sec, [scriptblock]$Make, [double]$Zig, [double]$Wave = 0)
    for ($k = 0; $k -lt $Count; $k++) {
        $el = & $Make $k
        $at = [Math]::Max(0.001, $k / $Count); $end = $at + 0.5
        if ($end -le 1) { $keys = @(@(0, 0), @($at, 0), @(($at + 0.0005), 1), @($end, 0), @(1, 0)) }
        else { $v0 = 1 - (1 - $at) / 0.5; $keys = @(@(0, $v0), @(($end - 1), 0), @($at, 0), @(($at + 0.0005), 1), @(1, $v0)) }
        Start-BfxKeys $el $global:BfxP.O $keys $Sec
        $y = $H * 0.55 + $(if ($k % 2) { $Zig } else { - $Zig }) + [Math]::Sin($k * 0.4) * $Wave
        Add-BfxItem $S $el -Fx ((($k + 0.5) / $Count) * 0.96 + 0.02) -Top $y
    }
}

function global:Add-BfxFootprints {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }
    $mud = New-BfxBrush '#140e08' 0.8
    Add-BfxTrail $S $BannerH 26 11 {
        $grp = New-Object System.Windows.Controls.Canvas
        [void]$grp.Children.Add((Set-BfxAt (New-BfxEllipse 12 6.8 $mud) -6 -3.4)); [void]$grp.Children.Add((Set-BfxAt (New-BfxEllipse 6 5.2 $mud) -11 -2.6))
        $grp
    }.GetNewClosure() 9
    Complete-BfxStage $S
}

function global:Add-BfxPawprints {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }
    $pad = New-BfxBrush '#e6e6dc' 0.7
    Add-BfxTrail $S $BannerH 34 10 {
        $grp = New-Object System.Windows.Controls.Canvas
        [void]$grp.Children.Add((Set-BfxAt (New-BfxEllipse 8.4 7.2 $pad) -4.2 -3.6))
        foreach ($q in @(@(-4.5, -4.5), @(-1.5, -6.5), @(1.8, -6.5), @(4.8, -4.5))) { [void]$grp.Children.Add((Set-BfxAt (New-BfxEllipse 3 3.8 $pad) ($q[0] - 1.5) ($q[1] - 1.9))) }
        # toes point in walking direction (to the right)
        $pt = Set-BfxTransforms $grp 0 0; $pt.R.Angle = 90
        $grp
    }.GetNewClosure() 8 10
    Complete-BfxStage $S
}

function global:Add-BfxSkybow {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $grp = New-Object System.Windows.Controls.Canvas
    $r0 = $H * 1.1; $band = $H * 0.06
    $cols = @('#ff4d4d', '#ff9a3d', '#ffe04d', '#5de05d', '#4db8ff', '#7a5cff')
    for ($n = 0; $n -lt 6; $n++) {
        $rr = $r0 - $n * $band; $a0 = [Math]::PI * 1.08; $a1 = [Math]::PI * 1.92
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint ([Math]::Cos($a0) * $rr) ([Math]::Sin($a0) * $rr)), $false, $false); $c.ArcTo((New-BfxPoint ([Math]::Cos($a1) * $rr) ([Math]::Sin($a1) * $rr)), [System.Windows.Size]::new($rr, $rr), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false) }.GetNewClosure()
        [void]$grp.Children.Add((New-BfxPath $geo $null (New-BfxBrush $cols[$n] 0.3) ($band + 0.5)))
    }
    for ($n = 0; $n -lt 8; $n++) {
        $arm = New-Object System.Windows.Controls.Canvas
        [void]$arm.Children.Add((Set-BfxAt (New-BfxGlow 16 '#ffffff' 0.8) (-($r0 - ($n % 6) * $band)) 0))
        $at = Set-BfxTransforms $arm 0 0
        Start-BfxAnim $at.R $global:BfxP.A 15 165 7 ($n / 8.0)
        Start-BfxKeys $arm $global:BfxP.O @(@(0, 0), @(0.1, 1), @(0.9, 1), @(1, 0)) 7 ($n / 8.0)
        [void]$grp.Children.Add($arm)
    }
    Add-BfxItem $S $grp -Fx 0.6 -Top ($H * 1.35)
    Complete-BfxStage $S
}

function global:Add-BfxLanterns {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $paper = New-BfxBrush '#ffaa50' 0.9
    for ($i = 0; $i -lt 14; $i++) {
        $sz = Get-BfxRnd $S 6 12
        $grp = New-Object System.Windows.Controls.Canvas
        $halo = New-BfxGlow ($sz * 10) '#ffb04d' 0.35; [void]$grp.Children.Add($halo)
        Start-BfxKeys $halo $global:BfxP.O @(@(0, 1), @(0.3, 0.8), @(0.5, 1), @(0.8, 0.85), @(1, 1)) (Get-BfxRnd $S 0.6 1.2) (Get-BfxRnd $S)
        $geo = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint (-$sz * 0.6) (-$sz)), $true, $true); $c.LineTo((New-BfxPoint ($sz * 0.6) (-$sz)), $true, $false); $c.LineTo((New-BfxPoint ($sz * 0.8) ($sz * 0.7)), $true, $false); $c.LineTo((New-BfxPoint (-$sz * 0.8) ($sz * 0.7)), $true, $false) }.GetNewClosure()
        [void]$grp.Children.Add((New-BfxPath $geo $paper))
        [void]$grp.Children.Add((Set-BfxAt (New-BfxGlow ($sz * 0.6) '#fff4d0' 1) 0 ($sz * 0.5)))
        $tf = Set-BfxTransforms $grp 0 0
        $per = ($H + 40) / (Get-BfxRnd $S 6 16); $ph = Get-BfxRnd $S
        Start-BfxAnim $tf.T $global:BfxP.Y ($H + 20) -20 $per $ph
        Start-BfxAnim $tf.S $global:BfxP.SX 1 0.5 $per $ph; Start-BfxAnim $tf.S $global:BfxP.SY 1 0.5 $per $ph
        Start-BfxAnim $tf.T $global:BfxP.X -6 6 (Get-BfxRnd $S 3 6) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $grp -Fx (Get-BfxRnd $S 0.05 0.95) -Top 0
    }
    Complete-BfxStage $S
}

function global:Add-BfxArrows {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $shaft = New-BfxBrush '#d8c8a8' 1; $tipB = New-BfxBrush '#e8e8e8' 1; $flet = New-BfxBrush '#c84a3a' 1
    $per = 3.2; $volley = @()
    for ($i = 0; $i -lt 16; $i++) {
        $arrow = New-Object System.Windows.Controls.Canvas
        [void]$arrow.Children.Add((Set-BfxAt (New-BfxRect 24 1.2 $shaft) -14 -0.6))
        $tg = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 13 0), $true, $true); $c.LineTo((New-BfxPoint 8 -2.5), $true, $false); $c.LineTo((New-BfxPoint 8 2.5), $true, $false) }
        [void]$arrow.Children.Add((New-BfxPath $tg $tipB)); [void]$arrow.Children.Add((Set-BfxAt (New-BfxRect 4 5 $flet) -14 -2.5))
        $tf = Set-BfxTransforms $arrow 0 0
        $lag = Get-BfxRnd $S 0 0.2; $dy = Get-BfxRnd $S 0 18; $dx = Get-BfxRnd $S 0 140
        $ky = @(); for ($n = 0; $n -le 10; $n++) { $u = $n / 10.0; $ky += , @($u, ($H * 0.9 - [Math]::Sin($u * [Math]::PI) * $H * 0.75 + $dy)) }
        Start-BfxKeys $tf.T $global:BfxP.Y $ky ($per * 0.8) ((1 - $lag) % 1)
        Add-BfxItem $S $arrow -Fx 0 -Top 0
        $volley += , @($tf, $lag, $dx)
    }
    $S.Extra = { param($cw)
        foreach ($v in $volley) {
            $span = $cw + 200; $tf = $v[0]
            Start-BfxAnim $tf.T $global:BfxP.X (-60 - $v[2]) ($span - 60 - $v[2]) ($per * 0.8) ((1 - $v[1]) % 1)
            $ka = @(); for ($n = 0; $n -le 10; $n++) { $u = $n / 10.0; $ka += , @($u, ([Math]::Atan2(- [Math]::Cos($u * [Math]::PI) * $H * 0.75 * [Math]::PI, $span) * 180 / [Math]::PI)) }
            Start-BfxKeys $tf.R $global:BfxP.A $ka ($per * 0.8) ((1 - $v[1]) % 1)
        }
    }.GetNewClosure()
    Complete-BfxStage $S
}

function global:Add-BfxCheckered {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $cell = 12.0
    $dg = New-Object System.Windows.Media.DrawingGroup
    [void]$dg.Children.Add([System.Windows.Media.GeometryDrawing]::new((New-BfxBrush '#f0f0f0' 0.16), $null, [System.Windows.Media.RectangleGeometry]::new([System.Windows.Rect]::new(0, 0, $cell * 2, $cell * 2))))
    [void]$dg.Children.Add([System.Windows.Media.GeometryDrawing]::new((New-BfxBrush '#0a0a0c' 0.3), $null, [System.Windows.Media.RectangleGeometry]::new([System.Windows.Rect]::new(0, 0, $cell, $cell))))
    [void]$dg.Children.Add([System.Windows.Media.GeometryDrawing]::new((New-BfxBrush '#0a0a0c' 0.3), $null, [System.Windows.Media.RectangleGeometry]::new([System.Windows.Rect]::new($cell, $cell, $cell, $cell))))
    $tile = New-Object System.Windows.Media.DrawingBrush $dg
    $tile.TileMode = [System.Windows.Media.TileMode]::Tile; $tile.Stretch = [System.Windows.Media.Stretch]::None
    $tile.ViewportUnits = [System.Windows.Media.BrushMappingMode]::Absolute; $tile.Viewport = [System.Windows.Rect]::new(0, 0, $cell * 2, $cell * 2)
    $tile.Freeze()
    $flag = New-BfxRect 1600 ($H + 24) $tile
    $flag.OpacityMask = New-BfxLinear @(@(0, '#000000', 0), @(0.06, '#000000', 1), @(1, '#000000', 1)) -Horizontal
    $sk = New-Object System.Windows.Media.SkewTransform 0, 0
    $flag.RenderTransform = $sk
    Start-BfxAnim $sk ([System.Windows.Media.SkewTransform]::AngleYProperty) -2.5 2.5 1.6 0 -Reverse -Ease
    Add-BfxItem $S $flag -Fx 0.42 -Top -12
    $sheen = New-BfxRect 90 ($H + 20) (New-BfxLinear @(@(0, '#ffffff', 0), @(0.5, '#ffffff', 0.14), @(1, '#ffffff', 0)) -Horizontal)
    $st = Set-BfxTransforms $sheen
    Add-BfxItem $S $sheen -Top -10 -Speed 160 -T $st.T -Margin 100
    Complete-BfxStage $S
}

function global:Add-BfxDriftsmoke {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 22; $i++) {
        $puff = New-BfxGlow 40 '#e8e8f0' 0.14; $tf = Set-BfxTransforms $puff
        $life = Get-BfxRnd $S 1.8 2.6; $ph = Get-BfxRnd $S
        Start-BfxAnim $tf.T $global:BfxP.X (Get-BfxRnd $S -10 10) (- (Get-BfxRnd $S 140 260)) $life $ph
        Start-BfxAnim $tf.T $global:BfxP.Y 0 (- (Get-BfxRnd $S 40 90)) $life $ph
        Start-BfxAnim $tf.S $global:BfxP.SX 0.5 3.2 $life $ph; Start-BfxAnim $tf.S $global:BfxP.SY 0.5 3.2 $life $ph
        Start-BfxKeys $puff $global:BfxP.O @(@(0, 0), @(0.1, 1), @(1, 0)) $life $ph
        Add-BfxItem $S $puff -Fx 0.7 -OffsetX (Get-BfxRnd $S -20 20) -Top $H
    }
    foreach ($ox in @(-30, 30)) { Add-BfxItem $S (New-BfxGlow 28 '#ff2a3a' 0.9) -Fx 0.7 -OffsetX $ox -Top ($H - 8) }
    Complete-BfxStage $S
}

function global:Add-BfxFocuslines {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $burst = New-Object System.Windows.Controls.Canvas
    $ink = New-BfxBrush '#ffffff' 0.16
    for ($grpN = 0; $grpN -lt 3; $grpN++) {
        $wedges = @(); for ($n = 0; $n -lt 24; $n++) { $wedges += , @((Get-BfxRnd $S 0 6.283), (Get-BfxRnd $S 0.3 0.8), (Get-BfxRnd $S 1 3)) }
        $geo = New-BfxGeo { param($c) foreach ($wd in $wedges) { $rin = 260.0; $rout = $rin + 900 * $wd[1] * 0.4; $c.BeginFigure((New-BfxPoint ([Math]::Cos($wd[0]) * $rin) ([Math]::Sin($wd[0]) * $rin)), $true, $true); $c.LineTo((New-BfxPoint ([Math]::Cos($wd[0] + 0.01 * $wd[2]) * $rout) ([Math]::Sin($wd[0] + 0.01 * $wd[2]) * $rout)), $true, $false); $c.LineTo((New-BfxPoint ([Math]::Cos($wd[0] - 0.01 * $wd[2]) * $rout) ([Math]::Sin($wd[0] - 0.01 * $wd[2]) * $rout)), $true, $false) } }.GetNewClosure()
        $lines = New-BfxPath $geo $ink
        # slow soft cross-fade between the three line sets (no strobe)
        Start-BfxKeys $lines $global:BfxP.O @(@(0, 1), @(0.33, 1), @(0.5, 0.15), @(0.83, 0.15), @(1, 1)) 3.6 ($grpN / 3.0)
        [void]$burst.Children.Add($lines)
    }
    $tf = Set-BfxTransforms $burst 0 0; $tf.S.ScaleY = 0.5
    Start-BfxAnim $tf.S $global:BfxP.SX 0.95 1.05 4 0 -Reverse -Ease
    Add-BfxItem $S $burst -Fx 0.66 -Top ($H * 0.5)
    Complete-BfxStage $S
}

function global:Add-BfxRunes {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $glyphs = @(
        @(@(0, -1, 0, 1), @(0, -1, 0.6, -0.4)), @(@(0, -1, 0, 1), @(0, -0.2, 0.6, -0.8), @(0, 0.2, 0.6, 0.8)),
        @(@(-0.5, 1, 0, -1), @(0, -1, 0.5, 1), @(-0.3, 0.3, 0.3, 0.3)), @(@(0, -1, 0, 1), @(0, -1, 0.6, -0.4), @(0.6, -0.4, 0, 0.2)),
        @(@(-0.5, -1, 0.5, 1), @(0.5, -1, -0.5, 1)), @(@(0, -1, 0, 1), @(-0.5, -0.5, 0.5, 0.5)),
        @(@(-0.5, -1, -0.5, 1), @(0.5, -1, 0.5, 1), @(-0.5, -1, 0.5, 1)), @(@(0, -1, 0, 1), @(-0.6, -0.3, 0, -1), @(0.6, -0.3, 0, -1))
    )
    $ink = New-BfxBrush '#8cd2ff' 0.85
    for ($i = 0; $i -lt 16; $i++) {
        $sz = Get-BfxRnd $S 7 13; $gl = $glyphs[$S.R.Next(0, $glyphs.Count)]
        $geo = New-BfxGeo { param($c) foreach ($sg in $gl) { $c.BeginFigure((New-BfxPoint ($sg[0] * $sz) ($sg[1] * $sz)), $false, $false); $c.LineTo((New-BfxPoint ($sg[2] * $sz) ($sg[3] * $sz)), $true, $false) } }.GetNewClosure()
        $rune = New-BfxPath $geo $null $ink 1.6
        Set-BfxShadow $rune '#7fd0ff' 8
        $tf = Set-BfxTransforms $rune
        $per = ($H + 30) / (Get-BfxRnd $S 8 20); $ph = Get-BfxRnd $S
        Start-BfxAnim $tf.T $global:BfxP.Y ($H + 15) -15 $per $ph
        Start-BfxKeys $rune $global:BfxP.O @(@(0, 0), @(0.5, 1), @(1, 0)) $per $ph
        Start-BfxAnim $tf.T $global:BfxP.X -6 6 (Get-BfxRnd $S 6 11) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $rune -Fx (Get-BfxRnd $S 0.05 0.95) -Top 0
    }
    Complete-BfxStage $S
}

function global:Add-BfxJungle {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    for ($i = 0; $i -lt 6; $i++) {
        $fl = New-BfxGlow 60 '#e8ffb0' 0.14
        Start-BfxAnim $fl $global:BfxP.O 0.4 1 (Get-BfxRnd $S 2 4) (Get-BfxRnd $S) -Reverse -Ease
        $tf = Set-BfxTransforms $fl; Start-BfxAnim $tf.T $global:BfxP.X -20 20 (Get-BfxRnd $S 6 10) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $fl -Fx (0.2 + $i * 0.13) -Top ($H * (Get-BfxRnd $S 0.2 0.7))
    }
    $stem = New-BfxBrush '#143c1e' 0.95; $leafB = New-BfxBrush '#1e5a28' 0.85
    $len = $H * 0.95
    foreach ($fr in @(@(0, 0.1, 40, 1), @(0, 1.0, -34, 1), @(1, 0.05, 140, -1), @(1, 0.95, 209, -1))) {
        $geo = New-BfxGeo { param($c)
            $c.BeginFigure((New-BfxPoint 0 0), $false, $false); $c.QuadraticBezierTo((New-BfxPoint ($len * 0.6) ($len * -0.18)), (New-BfxPoint $len 0), $true, $false)
            for ($k = 1; $k -lt 14; $k++) { $u = $k / 14.0; $px = $len * $u; $py = -0.36 * $len * $u * (1 - $u); $lfl = $len * 0.35 * [Math]::Sin($u * [Math]::PI)
                foreach ($sd in @(-1, 1)) { $c.BeginFigure((New-BfxPoint $px $py), $false, $false); $c.LineTo((New-BfxPoint ($px + [Math]::Cos($sd * 1.1) * $lfl * 0.45) ($py + [Math]::Sin($sd * 1.1) * $lfl)), $true, $false) } }
        }.GetNewClosure()
        $grp = New-Object System.Windows.Controls.Canvas
        [void]$grp.Children.Add((New-BfxPath $geo $null $leafB 3)); [void]$grp.Children.Add((New-BfxPath $geo $null $stem 1.2))
        $tf = Set-BfxTransforms $grp 0 0; $tf.R.Angle = $fr[2]
        Start-BfxAnim $tf.R $global:BfxP.A ($fr[2] - 6) ($fr[2] + 6) (Get-BfxRnd $S 3 5) (Get-BfxRnd $S) -Reverse -Ease
        Add-BfxItem $S $grp -Fx $fr[0] -Top ($H * $fr[1])
    }
    Complete-BfxStage $S
}

function global:Add-BfxSkulls {
    param([string]$BannerName, [double]$BannerH)
    $S = New-BfxStage $BannerName; if (-not $S) { return }; $H = $BannerH
    $dark = New-BfxBrush '#14040a' 1
    for ($i = 0; $i -lt 6; $i++) {
        $sz = Get-BfxRnd $S 10 18
        $grp = New-Object System.Windows.Controls.Canvas
        [void]$grp.Children.Add((New-BfxGlow ($sz * 6) '#ff3a1a' 0.35))
        $geo = New-BfxGeo { param($c)
            $c.BeginFigure((New-BfxPoint (-$sz) 0), $true, $true); $c.ArcTo((New-BfxPoint $sz 0), [System.Windows.Size]::new($sz, $sz), 0, $false, [System.Windows.Media.SweepDirection]::Clockwise, $true, $false)
            foreach ($q in @(@(0.8, 0.6), @(0.4, 0.6), @(0.4, 0.9), @(-0.4, 0.9), @(-0.4, 0.6), @(-0.8, 0.6))) { $c.LineTo((New-BfxPoint ($q[0] * $sz) ($q[1] * $sz)), $true, $false) }
        }.GetNewClosure()
        [void]$grp.Children.Add((New-BfxPath $geo (New-BfxBrush '#ff7850' 0.8)))
        foreach ($ex in @(-0.38, 0.38)) { [void]$grp.Children.Add((Set-BfxAt (New-BfxEllipse ($sz * 0.48) ($sz * 0.56) $dark) (($ex - 0.24) * $sz) (-0.23 * $sz))) }
        $ng = New-BfxGeo { param($c) $c.BeginFigure((New-BfxPoint 0 ($sz * 0.3)), $true, $true); $c.LineTo((New-BfxPoint (-$sz * 0.1) ($sz * 0.5)), $true, $false); $c.LineTo((New-BfxPoint ($sz * 0.1) ($sz * 0.5)), $true, $false) }.GetNewClosure()
        [void]$grp.Children.Add((New-BfxPath $ng $dark))
        $tf = Set-BfxTransforms $grp 0 0
        $per = Get-BfxRnd $S 4 8; $ph = Get-BfxRnd $S
        Start-BfxAnim $tf.T $global:BfxP.Y 0 -14 $per $ph
        Start-BfxKeys $grp $global:BfxP.O @(@(0, 0), @(0.5, 1), @(1, 0)) $per $ph
        Add-BfxItem $S $grp -Fx (Get-BfxRnd $S 0.15 0.92) -Top ($H * (Get-BfxRnd $S 0.3 0.7))
    }
    Complete-BfxStage $S
}


# ------------------------------------------------------------
# Dispatcher: effect name -> function
# ------------------------------------------------------------
$global:BannerFxExtraFunctions = @{
    fireflies = 'Add-BfxFireflies'; leaves = 'Add-BfxLeaves'; petals = 'Add-BfxPetals'; flowerwind = 'Add-BfxFlowerwind'
    lightning = 'Add-BfxLightning'; ash = 'Add-BfxAsh'; fog = 'Add-BfxFog'; flashlight = 'Add-BfxFlashlight'
    tracers = 'Add-BfxTracers'; flak = 'Add-BfxFlak'; pixels = 'Add-BfxPixels'; glitch = 'Add-BfxGlitch'
    neoncity = 'Add-BfxNeoncity'; raindrops = 'Add-BfxRaindrops'; lighttrails = 'Add-BfxLighttrails'; dust = 'Add-BfxDust'
    radiation = 'Add-BfxRadiation'; magic = 'Add-BfxMagic'; wisps = 'Add-BfxWisps'; confetti = 'Add-BfxConfetti'
    birds = 'Add-BfxBirds'; blizzard = 'Add-BfxBlizzard'; frost = 'Add-BfxFrost'; sandwind = 'Add-BfxSandwind'
    blooddrips = 'Add-BfxBlooddrips'; caustics = 'Add-BfxCaustics'; fish = 'Add-BfxFish'; orbits = 'Add-BfxOrbits'
    lasers = 'Add-BfxLasers'; scan = 'Add-BfxScan'; biolum = 'Add-BfxBiolum'; hearts = 'Add-BfxHearts'
    notes = 'Add-BfxNotes'; bullettime = 'Add-BfxBullettime'; void = 'Add-BfxVoid'; portals = 'Add-BfxPortals'
    teleport = 'Add-BfxTeleport'; webs = 'Add-BfxWebs'; coins = 'Add-BfxCoins'; rings = 'Add-BfxRings'
    bolts = 'Add-BfxBolts'; gems = 'Add-BfxGems'; inkdrips = 'Add-BfxInkdrips'; halftone = 'Add-BfxHalftone'
    graffiti = 'Add-BfxGraffiti'; waterspray = 'Add-BfxWaterspray'; clouds = 'Add-BfxClouds'; eyes = 'Add-BfxEyes'
    steam = 'Add-BfxSteam'; papers = 'Add-BfxPapers'; starburst = 'Add-BfxStarburst'; lensflare = 'Add-BfxLensflare'
    tracker = 'Add-BfxTracker'; slashes = 'Add-BfxSlashes'; spores = 'Add-BfxSpores'
    # round 2
    aurora = 'Add-BfxAurora'; grindsparks = 'Add-BfxGrindsparks'; shieldhit = 'Add-BfxShieldhit'; laserdot = 'Add-BfxLaserdot'
    ecg = 'Add-BfxEcg'; hud = 'Add-BfxHud'; cracks = 'Add-BfxCracks'; candles = 'Add-BfxCandles'
    blackhole = 'Add-BfxBlackhole'; fighters = 'Add-BfxFighters'; contrails = 'Add-BfxContrails'; puddles = 'Add-BfxPuddles'
    tumbleweed = 'Add-BfxTumbleweed'; bats = 'Add-BfxBats'; moths = 'Add-BfxMoths'; jellyfish = 'Add-BfxJellyfish'
    kelp = 'Add-BfxKelp'; flakes = 'Add-BfxFlakes'; spotlights = 'Add-BfxSpotlights'; fireworks = 'Add-BfxFireworks'
    balloons = 'Add-BfxBalloons'; fairydust = 'Add-BfxFairydust'; paperplanes = 'Add-BfxPaperplanes'; dice = 'Add-BfxDice'
    gears = 'Add-BfxGears'; helix = 'Add-BfxHelix'; toxicgas = 'Add-BfxToxicgas'; claws = 'Add-BfxClaws'
    glasscracks = 'Add-BfxGlasscracks'; footprints = 'Add-BfxFootprints'; pawprints = 'Add-BfxPawprints'; skybow = 'Add-BfxSkybow'
    lanterns = 'Add-BfxLanterns'; arrows = 'Add-BfxArrows'; checkered = 'Add-BfxCheckered'; driftsmoke = 'Add-BfxDriftsmoke'
    focuslines = 'Add-BfxFocuslines'; runes = 'Add-BfxRunes'; jungle = 'Add-BfxJungle'; skulls = 'Add-BfxSkulls'
}

# Real height of a banner right now (Border height when it is not laid
# out yet), falling back to the height the hub passed in.
function global:Get-BfxBannerH {
    param([string]$BannerName, [double]$BannerH)
    try {
        $b = $global:window.FindName($BannerName)
        if ($b) {
            if ($b.ActualHeight -ge 20) { return [double]$b.ActualHeight }
            if (-not [double]::IsNaN($b.Height) -and $b.Height -ge 20) { return [double]$b.Height }
        }
    } catch { }
    return $BannerH
}

# Draw one new effect. Returns $true when the name was one of ours.
function global:Invoke-BannerFxExtra {
    param([string]$BannerName, [double]$BannerH, [string]$Effect)
    if (-not $global:BannerFxExtraFunctions.ContainsKey($Effect)) { return $false }
    try {
        & $global:BannerFxExtraFunctions[$Effect] -BannerName $BannerName -BannerH (Get-BfxBannerH $BannerName $BannerH)
    } catch {
        if (Get-Command Write-HubTiming -ErrorAction SilentlyContinue) {
            Write-HubTiming ("bannerfxextra: {0} on {1} failed: {2}" -f $Effect, $BannerName, $_.Exception.Message)
        }
    }
    return $true
}

# ------------------------------------------------------------
# Windows check: build every effect once into a test banner.
#   powershell -STA -NoProfile -Command ". '.\Core\Modules\BannerFxExtra.ps1'; Test-BannerFxExtra"
# ------------------------------------------------------------
function global:Test-BannerFxExtra {
    param([double]$Width = 1100, [double]$Height = 140)
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase -ErrorAction SilentlyContinue
    $saved = $global:window
    $fail = 0; $ok = 0
    try {
        foreach ($fx in $global:BannerFxExtraGames.Keys) {
            $grid = New-Object System.Windows.Controls.Grid
            [void]$grid.Children.Add((New-Object System.Windows.Shapes.Rectangle))
            $border = New-Object System.Windows.Controls.Border
            $border.Width = $Width; $border.Height = $Height; $border.Child = $grid
            $global:window = [pscustomobject]@{ B = $border }
            $global:window | Add-Member -MemberType ScriptMethod -Name FindName -Value { param($n) if ($n -eq 'TestBanner') { $this.B } else { $null } }
            $err = $null
            try {
                & $global:BannerFxExtraFunctions[$fx] -BannerName 'TestBanner' -BannerH $Height
                $border.Measure([System.Windows.Size]::new($Width, $Height)); $border.Arrange([System.Windows.Rect]::new(0, 0, $Width, $Height)); $border.UpdateLayout()
            } catch { $err = $_.Exception.Message }
            $layer = @($grid.Children | Where-Object { $_.Tag -eq 'BannerFx' }) | Select-Object -First 1
            $n = if ($layer) { $layer.Children.Count } else { 0 }
            # Exercise the real S, M and L banner heights on the same host.
            $refit = ''
            if (-not $err -and $layer) {
                try {
                    foreach ($nextHeight in @(156.0,174.0)) {
                        $border.Height = $nextHeight
                        $border.Measure([System.Windows.Size]::new($Width, $nextHeight))
                        $border.Arrange([System.Windows.Rect]::new(0, 0, $Width, $nextHeight))
                        $border.UpdateLayout()
                        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{ }, [System.Windows.Threading.DispatcherPriority]::ContextIdle)
                        $layers = @($grid.Children | Where-Object { $_.Tag -eq 'BannerFx' })
                        if ($layers.Count -ne 1) { $refit = "after resize to $nextHeight, $($layers.Count) effect layers"; break }
                        if ([object]::ReferenceEquals($layers[0], $layer)) { $refit = "not rebuilt after resize to $nextHeight"; break }
                        if ($layers[0].Children.Count -eq 0) { $refit = "rebuilt layer is empty at $nextHeight"; break }
                        $layer = $layers[0]
                    }
                } catch { $refit = 'resize: ' + $_.Exception.Message }
            }
            if ($err -or -not $layer -or $n -eq 0 -or $refit) { $fail++; Write-Host ("[FAIL] {0,-12} {1}" -f $fx, $(if ($err) { $err } elseif ($refit) { $refit } else { 'no effect layer / no elements' })) -ForegroundColor Red }
            else { $ok++; Write-Host ("[PASS] {0,-12} {1} elements, rebuilt for 156 and 174 px" -f $fx, $n) }
        }
    } finally { $global:window = $saved }
    Write-Host ("{0} passed, {1} failed" -f $ok, $fail)
    return [pscustomobject]@{ Passed = $ok; Failed = $fail }
}

# ------------------------------------------------------------
# Wiring
# ------------------------------------------------------------
try {
    if ($global:HubBannerFxExtra -and $global:window -and -not $global:BannerFxExtraWrapped) {
        $addFx = Get-Command Add-BannerEffect -CommandType Function -ErrorAction SilentlyContinue
        if ($addFx -and (Get-Command Set-BannerEffect -CommandType Function -ErrorAction SilentlyContinue)) {
            $global:BannerFxExtraInnerAdd = $addFx.ScriptBlock

            function global:Add-BannerEffect {
                param([string]$BannerName, [double]$BannerH, [string]$ColorHex, [string]$Effect)
                if (Test-BannerFxExtraName $Effect) {
                    $featured = $global:BannerFxExtraFeatured -contains $BannerName
                    if ($featured -or -not $global:BannerFxExtraConfig.FeaturedOnly) {
                        [void](Invoke-BannerFxExtra -BannerName $BannerName -BannerH $BannerH -Effect $Effect)
                        return
                    }
                    $Effect = Resolve-BannerFxExtraFallback $Effect
                    $PSBoundParameters['Effect'] = $Effect
                }
                & $global:BannerFxExtraInnerAdd @PSBoundParameters
            }

            $global:BannerFxExtraWrapped = $true

            # BannerGlass Glow: lift the particle-type new effects above the art.
            if ($global:BannerGlassParticleFx -and $global:BannerGlassParticleFx -match '^\^\((.*)\)$') {
                $global:BannerGlassParticleFx = '^(' + $Matches[1] + '|' + ($global:BannerFxExtraParticle -join '|') + ')'
            }

            # The featured banners got their first effect before this file
            # loaded - roll once more so the new effects can show at start.
            if ($global:BannerFxExtraConfig.Reroll -and (Get-Command Reshuffle-BannerEffects -ErrorAction SilentlyContinue)) {
                try { Reshuffle-BannerEffects } catch { }
            }
            if (Get-Command Write-HubTiming -ErrorAction SilentlyContinue) {
                Write-HubTiming ("bannerfxextra: ready, {0} effects, {1} games" -f $global:BannerFxExtraFunctions.Count, (Get-BannerFxExtraIndex).Count)
            }
        }
    }
} catch {
    try { Write-HubTiming ("bannerfxextra: disabled after error: {0}" -f $_.Exception.Message) } catch { }
}
