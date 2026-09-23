# ===============================================================
# Stable catalog index - the compact maintenance surface for all games.
#
# One line equals one Hub tile. Moving a line changes only the curated
# "Hub order"; the large game definitions in Catalog.ps1 never need to be
# moved. Id is the permanent identity used by sorting, durable state,
# transactions and install manifests. It must never be renamed after
# publication. Title must match Catalog.ps1, Released is the newest verified
# VR-mod release date, and Added is the first Hub release
# date. Unknown historical dates stay empty instead of being guessed.
#
# SAFETY: the index is applied only when every source title occurs exactly
# once, every id is unique, each category matches, and all dates are valid.
# On any mismatch the original Catalog.ps1 arrays remain intact. Tests make
# such a fallback a release blocker, while users can still open the Hub.
# ===============================================================

$script:CatalogIndexSpec = [ordered]@{
    Motion = @(
        @{ Id = '7-days-to-die-vr'; Title = '7 Days to Die VR'; Released = '2026-07-06'; Added = '' }
        @{ Id = 'alien-isolation-vr'; Title = 'Alien: Isolation VR'; Released = '2020-12-28'; Added = '' }
        @{ Id = 'amnesia-vr'; Title = 'Amnesia VR'; Released = ''; Added = '' }
        @{ Id = 'anomaly-vr'; Title = 'Anomaly VR'; Released = ''; Added = '' }
        @{ Id = 'anomaly-gamma'; Title = 'Anomaly GAMMA'; Released = '2026-08-03'; Added = '' }
        @{ Id = 'arma-3-vr'; Title = 'Arma 3 VR'; Released = '2026-08-29'; Added = '' }
        @{ Id = 'ashes-2063-vr'; Title = 'Ashes 2063 VR'; Released = '2025-01-26'; Added = '' }
        @{ Id = 'away-vr'; Title = 'AWAY VR'; Released = '2026-08-31'; Added = '' }
        @{ Id = 'battlefield-1942-vr'; Title = 'Battlefield 1942 VR'; Released = '2026-08-23'; Added = '' }
        @{ Id = 'bendy-vr'; Title = 'Bendy VR'; Released = '2024-07-13'; Added = '' }
        @{ Id = 'big-walk-vr'; Title = 'Big Walk VR'; Released = '2026-08-18'; Added = '' }
        @{ Id = 'bioshock-remastered'; Title = 'BioShock Remastered'; Released = '2026-09-10'; Added = '' }
        @{ Id = 'bioshock-2-remastered'; Title = 'BioShock 2 Remastered'; Released = '2026-09-10'; Added = '' }
        @{ Id = 'bioshock-infinite-vr'; Title = 'BioShock Infinite VR'; Released = '2026-09-10'; Added = '' }
        @{ Id = 'black-mesa'; Title = 'Black Mesa VR'; Released = '2026-09-08'; Added = '2026-09-06' }
        @{ Id = 'black-mesa-source-vr'; Title = 'Black Mesa Source VR'; Released = '2023-05-04'; Added = '' }
        @{ Id = 'blood-vr'; Title = 'Blood VR'; Released = '2026-09-10'; Added = '2026-09-11' }
        @{ Id = 'borderlands-goty-enhanced'; Title = 'Borderlands GOTY Enhanced'; Released = '2026-09-11'; Added = '2026-09-08' }
        @{ Id = 'breath-of-the-wild-vr'; Title = 'Breath of the Wild VR'; Released = '2026-08-24'; Added = '' }
        @{ Id = 'c-c-generals-zero-hour'; Title = 'C&C Generals: Zero Hour'; Released = '2026-08-12'; Added = '' }
        @{ Id = 'call-of-duty-4-vr'; Title = 'Call of Duty 4 VR'; Released = '2026-08-18'; Added = '' }
        @{ Id = 'call-of-duty-world-at-war-vr'; Title = 'Call of Duty: World at War VR'; Released = '2026-08-19'; Added = '' }
        @{ Id = 'content-warning-vr'; Title = 'Content Warning VR'; Released = '2025-11-19'; Added = '' }
        @{ Id = 'cruelty-squad-vr'; Title = 'Cruelty Squad VR'; Released = '2023-07-25'; Added = '' }
        @{ Id = 'cyberpunk-2077'; Title = 'Cyberpunk 2077'; Released = '2026-09-01'; Added = '' }
        @{ Id = 'daggerfall-vr'; Title = 'Daggerfall VR'; Released = '2025-10-05'; Added = '' }
        @{ Id = 'deep-rock-galactic-vr'; Title = 'Deep Rock Galactic VR'; Released = ''; Added = '' }
        @{ Id = 'deus-ex-human-revolution-directors-cut-vr'; Title = 'Deus Ex: Human Revolution - DC'; Released = '2026-09-14'; Added = '2026-09-18' }
        @{ Id = 'dishonored-vr'; Title = 'Dishonored VR'; Released = '2026-09-01'; Added = '2026-08-31' }
        @{ Id = 'doom-2016-vr'; Title = 'DOOM (2016) VR'; Released = '2026-09-13'; Added = '2026-09-12' }
        @{ Id = 'doom-vr'; Title = 'Doom VR'; Released = '2025-01-26'; Added = '' }
        @{ Id = 'doom-2-vr'; Title = 'Doom 2 VR'; Released = '2025-01-26'; Added = '' }
        @{ Id = 'doom-3-bfg-vr'; Title = 'Doom 3 BFG VR'; Released = '2026-08-30'; Added = '' }
        @{ Id = 'dredge-vr'; Title = 'Dredge VR'; Released = '2026-05-02'; Added = '' }
        @{ Id = 'duke-nukem-3d-vr'; Title = 'Duke Nukem 3D VR'; Released = '2026-09-10'; Added = '2026-09-11' }
        @{ Id = 'dusk-hd-dlc-vr'; Title = 'Dusk HD (DLC) VR'; Released = '2025-12-15'; Added = '' }
        @{ Id = 'earth-defense-force-6-vr'; Title = 'EARTH DEFENSE FORCE 6 VR'; Released = '2026-09-13'; Added = '2026-09-13' }
        @{ Id = 'elden-ring-motion-controls'; Title = 'Elden Ring VR'; Released = '2026-09-10'; Added = '2026-09-03' }
        @{ Id = 'elderborn-vr'; Title = 'ELDERBORN VR'; Released = '2026-08-28'; Added = '2026-09-15' }
        @{ Id = 'escape-from-tarkov-vr'; Title = 'Escape from Tarkov VR'; Released = '2026-06-23'; Added = '' }
        @{ Id = 'f-e-a-r-vr'; Title = 'F.E.A.R. VR'; Released = '2026-09-13'; Added = '' }
        @{ Id = 'final-fantasy-xiv-vr'; Title = 'Final Fantasy XIV VR'; Released = '2026-09-08'; Added = '' }
        @{ Id = 'garry-s-mod-vr'; Title = 'Garry''s Mod VR'; Released = '2026-03-10'; Added = '' }
        @{ Id = 'gloomhaven-vr'; Title = 'Gloomhaven VR'; Released = '2026-08-23'; Added = '2026-09-16' }
        @{ Id = 'goldeneye-007-vr'; Title = 'GoldenEye 007 VR'; Released = '2026-09-16'; Added = '2026-09-18' }
        @{ Id = 'grand-theft-auto-v-vr'; Title = 'Grand Theft Auto V VR'; Released = '2026-09-09'; Added = '' }
        @{ Id = 'gta-vice-city-vr'; Title = 'GTA Vice City VR'; Released = '2026-09-06'; Added = '' }
        @{ Id = 'gtfo-vr'; Title = 'GTFO VR'; Released = '2024-01-06'; Added = '' }
        @{ Id = 'gunfire-reborn'; Title = 'Gunfire Reborn'; Released = '2025-01-22'; Added = '' }
        @{ Id = 'halo-3-mcc-vr'; Title = 'Halo Master Chief Collection VR'; Released = '2026-09-09'; Added = '' }
        @{ Id = 'heretic-vr'; Title = 'Heretic VR'; Released = '2025-01-26'; Added = '' }
        @{ Id = 'hexen-vr'; Title = 'Hexen VR'; Released = '2025-01-26'; Added = '' }
        @{ Id = 'hexen-ii-vr'; Title = 'Hexen II VR'; Released = ''; Added = '' }
        @{ Id = 'how-to-fish-xr'; Title = 'How to Fish XR'; Released = '2026-09-07'; Added = '2026-09-07' }
        @{ Id = 'house-of-the-dead-remake-vr'; Title = 'House of the Dead Remake VR'; Released = '2026-08-07'; Added = '' }
        @{ Id = 'house-of-the-dead-2-remake-vr'; Title = 'House of the Dead 2 Remake VR'; Released = ''; Added = '' }
        @{ Id = 'hytale-vr'; Title = 'Hytale VR'; Released = '2026-08-24'; Added = '' }
        @{ Id = 'i-can-gun-vr'; Title = 'I Can Gun VR'; Released = ''; Added = '' }
        @{ Id = 'idols-of-ash-vr'; Title = 'Idols of Ash VR'; Released = '2026-05-07'; Added = '' }
        @{ Id = 'iron-lung-vr'; Title = 'Iron Lung VR'; Released = ''; Added = '' }
        @{ Id = 'kerbal-space-program'; Title = 'Kerbal Space Program'; Released = '2026-05-12'; Added = '' }
        @{ Id = 'left-4-dead-2-vr'; Title = 'Left 4 Dead 2 VR'; Released = '2026-08-13'; Added = '' }
        @{ Id = 'legend-of-zelda-ocarina-of-time-vr'; Title = 'Legend of Zelda: Ocarina of Time VR'; Released = '2026-08-13'; Added = '' }
        @{ Id = 'legend-of-zelda-twilight-princess'; Title = 'Legend of Zelda: Twilight Princess'; Released = '2026-09-05'; Added = '' }
        @{ Id = 'lethal-company-vr'; Title = 'Lethal Company VR'; Released = ''; Added = '' }
        @{ Id = 'life-is-strange-bts'; Title = 'Life is Strange: BtS'; Released = '2026-05-14'; Added = '' }
        @{ Id = 'lunacid-vr'; Title = 'Lunacid VR'; Released = ''; Added = '' }
        @{ Id = 'mage-arena-vr'; Title = 'Mage Arena VR'; Released = ''; Added = '' }
        @{ Id = 'max-payne-2-vr'; Title = 'Max Payne 2 VR'; Released = '2026-09-07'; Added = '2026-09-07' }
        @{ Id = 'metal-gear-solid-v-the-phantom-pain-vr'; Title = 'Metal Gear Solid V: The Phantom Pain VR'; Released = '2026-09-13'; Added = '2026-09-11' }
        @{ Id = 'metal-hellsinger-vr'; Title = 'Metal: Hellsinger VR'; Released = '2023-03-29'; Added = '' }
        @{ Id = 'metroid-prime-vr'; Title = 'Metroid Prime VR'; Released = '2026-09-10'; Added = '' }
        @{ Id = 'mirrors-edge-vr'; Title = "Mirror's Edge VR"; Released = '2026-09-19'; Added = '2026-09-20' }
        @{ Id = 'moros-protocol-vr'; Title = 'Moros Protocol VR'; Released = ''; Added = '' }
        @{ Id = 'mouse-p-i-for-hire-vr'; Title = 'Mouse P.I. For Hire VR'; Released = ''; Added = '' }
        @{ Id = 'my-friendly-neighborhood-vr'; Title = 'My Friendly Neighborhood VR'; Released = '2026-08-31'; Added = '' }
        @{ Id = 'nam-vr'; Title = 'NAM VR'; Released = '2026-09-10'; Added = '2026-09-11' }
        @{ Id = 'outer-wilds-vr'; Title = 'Outer Wilds VR'; Released = '2026-05-13'; Added = '' }
        @{ Id = 'outward-de-vr'; Title = 'Outward DE VR'; Released = '2023-05-23'; Added = '' }
        @{ Id = 'painkiller-black-edition'; Title = 'Painkiller Black Edition'; Released = '2026-09-07'; Added = '' }
        @{ Id = 'painkiller-overdose-vr'; Title = 'Painkiller: Overdose VR'; Released = '2026-09-19'; Added = '2026-09-20' }
        @{ Id = 'panzer-dragoon-remake'; Title = 'Panzer Dragoon Remake'; Released = '2026-08-06'; Added = '' }
        @{ Id = 'pathfinder-kingmaker'; Title = 'Pathfinder: Kingmaker'; Released = '2025-01-13'; Added = '' }
        @{ Id = 'peak-vr'; Title = 'PEAK VR'; Released = '2026-09-09'; Added = '' }
        @{ Id = 'penumbra-overture-vr'; Title = 'Penumbra: Overture VR'; Released = '2026-09-02'; Added = '' }
        @{ Id = 'perfect-dark-vr'; Title = 'Perfect Dark VR'; Released = '2026-08-19'; Added = '' }
        @{ Id = 'pokemon-gen-1-vr'; Title = 'Pokemon Dramatic Shape VR'; Released = '2026-09-21'; Added = '' }
        @{ Id = 'portal-2-vr'; Title = 'Portal 2 VR'; Released = '2026-02-19'; Added = '' }
        @{ Id = 'powerslave-exhumed-vr'; Title = 'PowerSlave / Exhumed VR'; Released = '2026-09-10'; Added = '2026-09-11' }
        @{ Id = 'powerwash-simulator-2-vr'; Title = 'PowerWash Simulator 2 VR'; Released = '2026-09-19'; Added = '2026-09-20' }
        @{ Id = 'prey-2006-vr'; Title = 'Prey (2006) VR'; Released = '2026-09-17'; Added = '2026-09-17' }
        @{ Id = 'quake-vr'; Title = 'Quake VR'; Released = '2026-09-10'; Added = '2026-09-03' }
        @{ Id = 'quake-2-vr'; Title = 'Quake 2 VR'; Released = '2026-09-07'; Added = '' }
        @{ Id = 'quake-3-vr'; Title = 'Quake 3 VR'; Released = '2026-02-07'; Added = '' }
        @{ Id = 'r-e-p-o-vr'; Title = 'R.E.P.O. VR'; Released = '2026-07-03'; Added = '' }
        @{ Id = 'raft-vr'; Title = 'Raft VR'; Released = ''; Added = '' }
        @{ Id = 'ratchet-clank-vr'; Title = 'Ratchet & Clank VR'; Released = ''; Added = '' }
        @{ Id = 'ready-or-not-vr'; Title = 'Ready Or Not VR'; Released = '2026-06-15'; Added = '' }
        @{ Id = 'receiver-vr'; Title = 'Receiver VR'; Released = '2020-06-26'; Added = '' }
        @{ Id = 'red-faction-vr'; Title = 'Red Faction VR'; Released = '2026-08-29'; Added = '' }
        @{ Id = 'redneck-rampage-vr'; Title = 'Redneck Rampage VR'; Released = '2026-09-10'; Added = '2026-09-11' }
        @{ Id = 'richard-burns-rally-vr'; Title = 'Richard Burns Rally VR'; Released = ''; Added = '' }
        @{ Id = 'risk-of-rain-2'; Title = 'Risk of Rain 2'; Released = '2026-09-10'; Added = '' }
        @{ Id = 'road-to-vostok-vr'; Title = 'Road to Vostok VR'; Released = '2026-08-14'; Added = '' }
        @{ Id = 'saints-row-the-third-vr'; Title = 'Saints Row: The Third VR'; Released = ''; Added = '' }
        @{ Id = 'scrap-mechanic-vr'; Title = 'Scrap Mechanic VR'; Released = '2026-09-02'; Added = '' }
        @{ Id = 'selaco-vr'; Title = 'Selaco VR'; Released = '2025-06-01'; Added = '' }
        @{ Id = 'shadow-warrior-vr'; Title = 'Shadow Warrior VR'; Released = '2026-09-10'; Added = '2026-09-11' }
        @{ Id = 'silent-hill-3-vr'; Title = 'Silent Hill 3 VR'; Released = '2026-09-12'; Added = '2026-09-03' }
        @{ Id = 'sin-episodes-emergence'; Title = 'SiN Episodes: Emergence'; Released = '2026-09-13'; Added = '2026-09-09' }
        @{ Id = 'singularity-vr'; Title = 'Singularity VR'; Released = '2026-08-19'; Added = '' }
        @{ Id = 'slime-rancher-vr'; Title = 'Slime Rancher VR'; Released = '2025-04-12'; Added = '' }
        @{ Id = 'slyders-vr'; Title = 'Slyders VR'; Released = ''; Added = '' }
        @{ Id = 'sons-of-the-forest'; Title = 'Sons of the Forest'; Released = '2026-08-24'; Added = '' }
        @{ Id = 'star-wars-episode-i-racer'; Title = 'Star Wars Episode I Racer'; Released = '2026-09-07'; Added = '2026-09-03' }
        @{ Id = 'stardew-valley-vr'; Title = 'Stardew Valley VR'; Released = '2026-08-22'; Added = '' }
        @{ Id = 'strife-vr'; Title = 'Strife VR'; Released = '2025-01-26'; Added = '' }
        @{ Id = 'subnautica-vr'; Title = 'Subnautica VR'; Released = '2026-05-26'; Added = '' }
        @{ Id = 'subnautica-below-zero'; Title = 'Subnautica: Below Zero'; Released = '2025-08-15'; Added = '' }
        @{ Id = 'techtonica-vr'; Title = 'Techtonica VR'; Released = '2024-05-03'; Added = '' }
        @{ Id = 'the-witness'; Title = 'The Witness'; Released = '2026-09-01'; Added = '2026-09-08' }
        @{ Id = 'titanfall-2-vr'; Title = 'Titanfall 2 VR'; Released = '2026-09-12'; Added = '2026-09-13' }
        @{ Id = 'tomb-raider-1-vr'; Title = 'Tomb Raider 1 VR'; Released = '2024-10-04'; Added = '' }
        @{ Id = 'tormented-souls-vr'; Title = 'Tormented Souls VR'; Released = '2023-06-06'; Added = '' }
        @{ Id = 'total-chaos-vr'; Title = 'Total Chaos VR'; Released = '2025-01-26'; Added = '' }
        @{ Id = 'trombone-champ-vr'; Title = 'Trombone Champ VR'; Released = ''; Added = '' }
        @{ Id = 'tribes-2-vr'; Title = 'Tribes 2 VR'; Released = '2026-09-15'; Added = '2026-09-18' }
        @{ Id = 'ultrakill-vr'; Title = 'ULTRAKILL VR'; Released = '2026-04-14'; Added = '' }
        @{ Id = 'valheim-vr'; Title = 'Valheim VR'; Released = '2026-09-11'; Added = '' }
        @{ Id = 'virtua-cop-2-vr'; Title = 'Virtua Cop 2 VR'; Released = '2026-09-02'; Added = '' }
        @{ Id = 'warhammer-40k-darktide-vr'; Title = 'Warhammer 40K: Darktide VR'; Released = '2026-09-13'; Added = '2026-09-13' }
        @{ Id = 'white-knuckle-vr'; Title = 'White Knuckle VR'; Released = '2026-09-02'; Added = '' }
        @{ Id = 'wolfenstein-3d-vr'; Title = 'Wolfenstein 3D VR'; Released = ''; Added = '' }
        @{ Id = 'wwii-gi-vr'; Title = 'World War II GI VR'; Released = '2026-09-10'; Added = '2026-09-11' }
        @{ Id = 'world-of-warcraft-vr'; Title = 'World of Warcraft VR'; Released = '2024-05-24'; Added = '' }
    )
    Gamepad = @(
        @{ Id = 'alba-vr'; Title = 'Alba VR'; Released = '2023-01-03'; Added = '' }
        @{ Id = 'another-crab-s-treasure'; Title = 'Another Crab''s Treasure'; Released = ''; Added = '' }
        @{ Id = 'apollo-justice-ace-attorney-trilogy-vr'; Title = 'Apollo Justice: Ace Attorney Trilogy VR'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'art-of-rally-vr'; Title = 'Art of Rally VR'; Released = ''; Added = '' }
        @{ Id = 'assassin-s-creed-mirage-vr'; Title = 'Assassin''s Creed Mirage VR'; Released = '2026-01-25'; Added = '' }
        @{ Id = 'assassin-s-creed-odyssey-vr'; Title = 'Assassin''s Creed Odyssey VR'; Released = '2026-01-25'; Added = '' }
        @{ Id = 'assassin-s-creed-valhalla-vr'; Title = 'Assassin''s Creed Valhalla VR'; Released = '2026-01-25'; Added = '' }
        @{ Id = 'astrodogs-vr'; Title = 'Astrodogs VR'; Released = ''; Added = '' }
        @{ Id = 'atomic-heart-vr'; Title = 'Atomic Heart VR'; Released = ''; Added = '' }
        @{ Id = 'avatar-frontiers-of-pandora-vr'; Title = 'Avatar: Frontiers of Pandora VR'; Released = ''; Added = '' }
        @{ Id = 'banjo-kazooie-vr'; Title = 'Banjo-Kazooie VR'; Released = '2026-08-20'; Added = '' }
        @{ Id = 'bomb-rush-cyberfunk'; Title = 'Bomb Rush Cyberfunk'; Released = '2025-01-24'; Added = '' }
        @{ Id = 'circuit-superstars-vr'; Title = 'Circuit Superstars VR'; Released = '2024-12-30'; Added = '' }
        @{ Id = 'cloudpunk-vr'; Title = 'Cloudpunk VR'; Released = '2025-04-20'; Added = '' }
        @{ Id = 'cloudpunk-city-of-ghosts-vr'; Title = 'Cloudpunk: City of Ghosts VR'; Released = '2025-04-20'; Added = '' }
        @{ Id = 'dark-souls-ii-vr'; Title = 'Dark Souls II VR'; Released = ''; Added = '' }
        @{ Id = 'dark-souls-iii-vr'; Title = 'Dark Souls III VR'; Released = ''; Added = '' }
        @{ Id = 'dark-souls-remastered'; Title = 'Dark Souls Remastered'; Released = ''; Added = '' }
        @{ Id = 'days-gone-vr'; Title = 'Days Gone VR'; Released = ''; Added = '' }
        @{ Id = 'death-stranding-vr'; Title = 'Death Stranding VR'; Released = ''; Added = '' }
        @{ Id = 'decimate-drive-vr'; Title = 'Decimate Drive VR'; Released = ''; Added = '' }
        @{ Id = 'descenders-vr'; Title = 'Descenders VR'; Released = '2026-08-11'; Added = '' }
        @{ Id = 'devil-may-cry-5-vr'; Title = 'Devil May Cry 5 VR'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'diddy-kong-racing-vr'; Title = 'Diddy Kong Racing VR'; Released = '2026-08-20'; Added = '' }
        @{ Id = 'dinkum-vr'; Title = 'Dinkum VR'; Released = '2026-07-26'; Added = '' }
        @{ Id = 'dino-trauma-vr'; Title = 'Dino Trauma VR'; Released = ''; Added = '' }
        @{ Id = 'doom-eternal-vr'; Title = 'Doom Eternal VR'; Released = ''; Added = '' }
        @{ Id = 'dragon-s-dogma-2-vr'; Title = 'Dragon''s Dogma 2 VR'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'driftwood-vr'; Title = 'Driftwood VR'; Released = '2024-10-15'; Added = '' }
        @{ Id = 'echo-generation-2-vr'; Title = 'Echo Generation 2 VR'; Released = ''; Added = '' }
        @{ Id = 'elden-ring-real-vr'; Title = 'Elden Ring'; Released = ''; Added = '' }
        @{ Id = 'f-zero-x-vr'; Title = 'F-Zero X VR'; Released = '2026-08-20'; Added = '' }
        @{ Id = 'far-cry-4-vr'; Title = 'Far Cry 4 VR'; Released = ''; Added = '' }
        @{ Id = 'far-cry-5-vr'; Title = 'Far Cry 5 VR'; Released = ''; Added = '' }
        @{ Id = 'far-cry-6-vr'; Title = 'Far Cry 6 VR'; Released = ''; Added = '' }
        @{ Id = 'far-cry-new-dawn-vr'; Title = 'Far Cry New Dawn VR'; Released = ''; Added = '' }
        @{ Id = 'far-cry-primal-vr'; Title = 'Far Cry Primal VR'; Released = ''; Added = '' }
        @{ Id = 'ff-vii-rebirth-vr'; Title = 'FF VII Rebirth VR'; Released = ''; Added = '' }
        @{ Id = 'ff-vii-remake-vr'; Title = 'FF VII Remake VR'; Released = ''; Added = '' }
        @{ Id = 'forza-horizon-5-vr'; Title = 'Forza Horizon 5 VR'; Released = '2026-09-08'; Added = '' }
        @{ Id = 'forza-horizon-6-vr'; Title = 'Forza Horizon 6 VR'; Released = '2026-09-08'; Added = '' }
        @{ Id = 'ghost-of-tsushima-vr'; Title = 'Ghost of Tsushima VR'; Released = ''; Added = '' }
        @{ Id = 'ghost-recon-wildlands-vr'; Title = 'Ghost Recon Wildlands VR'; Released = '2026-09-13'; Added = '' }
        @{ Id = 'ghosts-n-goblins-resurrection-vr'; Title = 'Ghosts n Goblins Resurrection VR'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'ghostwire-tokyo-vr'; Title = 'Ghostwire: Tokyo VR'; Released = ''; Added = '' }
        @{ Id = 'grounded-vr'; Title = 'Grounded VR'; Released = ''; Added = '' }
        @{ Id = 'gta-iv-vr'; Title = 'GTA IV VR'; Released = '2026-08-04'; Added = '' }
        @{ Id = 'high-on-life-vr'; Title = 'High on Life VR'; Released = ''; Added = '' }
        @{ Id = 'hogwarts-legacy-vr'; Title = 'Hogwarts Legacy VR'; Released = ''; Added = '' }
        @{ Id = 'hollow-knight-silksong'; Title = 'Hollow Knight Silksong'; Released = ''; Added = '' }
        @{ Id = 'hollow-knight-vr'; Title = 'Hollow Knight VR'; Released = ''; Added = '' }
        @{ Id = 'horizon-chase-turbo'; Title = 'Horizon Chase Turbo'; Released = '2025-04-16'; Added = '' }
        @{ Id = 'horizon-forbidden-west-vr'; Title = 'Horizon Forbidden West VR'; Released = ''; Added = '' }
        @{ Id = 'horizon-zero-dawn-vr'; Title = 'Horizon Zero Dawn VR'; Released = ''; Added = '' }
        @{ Id = 'horizon-zero-dawn-remastered-vr'; Title = 'Horizon Zero Dawn Remastered VR'; Released = ''; Added = '' }
        @{ Id = 'hypogea-vr'; Title = 'Hypogea VR'; Released = ''; Added = '' }
        @{ Id = 'indiana-jones-great-circle-vr'; Title = 'Indiana Jones: Great Circle VR'; Released = ''; Added = '' }
        @{ Id = 'kingdom-come-deliverance-vr'; Title = 'Kingdom Come: Deliverance VR'; Released = '2026-09-09'; Added = '2026-09-21' }
        @{ Id = 'kingdom-come-deliverance-ii-vr'; Title = 'Kingdom Come: Deliverance II VR'; Released = ''; Added = '' }
        @{ Id = 'kunitsu-gami-path-of-the-goddess-vr'; Title = 'Kunitsu-Gami: Path of the Goddess VR'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'lunistice-vr'; Title = 'Lunistice VR'; Released = '2026-01-30'; Added = '' }
        @{ Id = 'mario-kart-64-vr'; Title = 'Mario Kart 64 VR'; Released = '2026-08-20'; Added = '' }
        @{ Id = 'mass-effect-1-le-vr'; Title = 'Mass Effect 1 LE VR'; Released = ''; Added = '' }
        @{ Id = 'mass-effect-2-le-vr'; Title = 'Mass Effect 2 LE VR'; Released = ''; Added = '' }
        @{ Id = 'mass-effect-3-le-vr'; Title = 'Mass Effect 3 LE VR'; Released = ''; Added = '' }
        @{ Id = 'mega-man-star-force-legacy-vr'; Title = 'Mega Man Star Force Legacy VR'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'mirage-feathers-vr'; Title = 'Mirage Feathers VR'; Released = ''; Added = '' }
        @{ Id = 'monster-hunter-rise-vr'; Title = 'Monster Hunter Rise VR'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'monster-hunter-stories-3-vr'; Title = 'Monster Hunter Stories 3 VR'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'monster-hunter-wilds'; Title = 'Monster Hunter Wilds'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'moto-rush-reborn-vr'; Title = 'Moto Rush Reborn VR'; Released = ''; Added = '' }
        @{ Id = 'muck-vr'; Title = 'Muck VR'; Released = '2024-06-28'; Added = '2026-09-07' }
        @{ Id = 'new-star-gp-vr'; Title = 'New Star GP VR'; Released = ''; Added = '' }
        @{ Id = 'no-one-lives-forever-2-vr'; Title = 'No One Lives Forever 2 VR'; Released = '2018-02-13'; Added = '' }
        @{ Id = 'nuclear-option-vr'; Title = 'Nuclear Option VR'; Released = '2026-09-09'; Added = '2026-09-03' }
    @{ Id = 'oblivion-2006-vr'; Title = 'Oblivion (2006)'; Released = '2026-09-20'; Added = '2026-09-21' }
        @{ Id = 'onimusha-2-vr'; Title = 'Onimusha 2 VR'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'outbound-vr'; Title = 'Outbound VR'; Released = '2026-08-29'; Added = '' }
        @{ Id = 'outlast-vr'; Title = 'Outlast VR'; Released = '2026-08-25'; Added = '' }
        @{ Id = 'paperklay-vr'; Title = 'Paperklay VR'; Released = ''; Added = '' }
        @{ Id = 'paranoia-place-vr'; Title = 'Paranoia Place VR'; Released = ''; Added = '' }
        @{ Id = 'pragmata-vr'; Title = 'Pragmata VR'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'rebel-galaxy-vr'; Title = 'Rebel Galaxy VR'; Released = '2026-08-15'; Added = '' }
        @{ Id = 'retrowave-2-vr'; Title = 'Retrowave 2 VR'; Released = '2026-08-25'; Added = '' }
        @{ Id = 'ring-racers-vr'; Title = 'Ring Racers VR'; Released = '2026-08-20'; Added = '' }
        @{ Id = 'road-redemption-vr'; Title = 'Road Redemption VR'; Released = '2025-10-05'; Added = '' }
        @{ Id = 'rogue-flight-vr'; Title = 'Rogue Flight VR'; Released = ''; Added = '' }
        @{ Id = 'sayonara-wild-hearts'; Title = 'Sayonara Wild Hearts'; Released = ''; Added = '' }
        @{ Id = 'shenmue-i-ii'; Title = 'Shenmue I & II'; Released = ''; Added = '' }
        @{ Id = 'silent-hill-vr'; Title = 'Silent Hill VR'; Released = ''; Added = '2026-09-03' }
        @{ Id = 'skate-story-vr'; Title = 'Skate Story VR'; Released = ''; Added = '' }
        @{ Id = 'sonic-p-06-vr'; Title = 'Sonic P-06 VR'; Released = '2024-12-11'; Added = '' }
        @{ Id = 'sonic-robo-blast-2-vr'; Title = 'Sonic Robo Blast 2 VR'; Released = '2026-08-20'; Added = '' }
        @{ Id = 'snowrunner-vr'; Title = 'SnowRunner VR'; Released = '2026-09-02'; Added = '2026-09-09' }
        @{ Id = 'spiderman-2-vr'; Title = 'Spiderman 2 VR'; Released = ''; Added = '' }
        @{ Id = 'spiderman-miles-morales-vr'; Title = 'Spiderman Miles Morales VR'; Released = ''; Added = '' }
        @{ Id = 'spiderman-remastered'; Title = 'Spiderman Remastered'; Released = ''; Added = '' }
        @{ Id = 'star-fox-64-vr'; Title = 'Star Fox 64 VR'; Released = '2026-08-20'; Added = '' }
        @{ Id = 'star-racer-vr'; Title = 'Star Racer VR'; Released = ''; Added = '' }
        @{ Id = 'star-trucker-vr'; Title = 'Star Trucker VR'; Released = '2026-08-18'; Added = '' }
        @{ Id = 'star-wars-outlaws-vr'; Title = 'Star Wars Outlaws VR'; Released = ''; Added = '' }
        @{ Id = 'starfield-vr'; Title = 'Starfield VR'; Released = '2026-05-05'; Added = '' }
        @{ Id = 'stray-vr'; Title = 'Stray VR'; Released = ''; Added = '' }
        @{ Id = 'street-fighter-6-vr'; Title = 'Street Fighter 6 VR'; Released = '2026-09-12'; Added = '' }
        @{ Id = 'streetdog-bmx-vr'; Title = 'StreetDog BMX VR'; Released = ''; Added = '' }
        @{ Id = 'sunrise-gp-vr'; Title = 'Sunrise GP VR'; Released = ''; Added = '' }
        @{ Id = 'super-mario-64-vr'; Title = 'Super Mario 64 VR'; Released = '2026-08-20'; Added = '' }
        @{ Id = 'the-dark-mod-vr'; Title = 'The Dark Mod VR'; Released = '2022-05-23'; Added = '' }
        @{ Id = 'thehunter-call-of-the-wild-vr'; Title = 'theHunter: Call of the Wild VR'; Released = '2026-08-16'; Added = '' }
        @{ Id = 'thief-2014-vr'; Title = 'Thief (2014) VR'; Released = '2026-09-18'; Added = '2026-09-21' }
        @{ Id = 'tinykin-vr'; Title = 'Tinykin VR'; Released = ''; Added = '' }
        @{ Id = 'tlou-part-i-vr'; Title = 'TLOU Part I VR'; Released = ''; Added = '' }
        @{ Id = 'tlou-part-ii-vr'; Title = 'TLOU Part II VR'; Released = ''; Added = '' }
        @{ Id = 'trackmania-nations-forever'; Title = 'TrackMania Nations Forever'; Released = '2026-09-07'; Added = '2026-09-15' }
        @{ Id = 'trackmania-united-forever'; Title = 'TrackMania United Forever'; Released = '2026-09-07'; Added = '2026-09-15' }
        @{ Id = 'uncharted-legacy-of-thieves-vr'; Title = 'Uncharted: Legacy of Thieves VR'; Released = ''; Added = '' }
        @{ Id = 'unmourned-vr'; Title = 'Unmourned VR'; Released = ''; Added = '' }
        @{ Id = 'warhammer-40k-rogue-trader-vr'; Title = 'Warhammer 40K: Rogue Trader VR'; Released = ''; Added = '' }
        @{ Id = 'watch-dogs-vr'; Title = 'Watch Dogs VR'; Released = ''; Added = '' }
        @{ Id = 'watch-dogs-2-vr'; Title = 'Watch Dogs 2 VR'; Released = ''; Added = '' }
        @{ Id = 'watch-dogs-legion-vr'; Title = 'Watch Dogs Legion VR'; Released = ''; Added = '' }
        @{ Id = 'witcher-3-vr'; Title = 'Witcher 3 VR'; Released = '2026-09-08'; Added = '' }
        @{ Id = 'yooka-laylee-vr'; Title = 'Yooka-Laylee VR'; Released = '2017-04-18'; Added = '' }
    )
    External = @(
        @{ Id = 'crysis-vr'; Title = 'Crysis VR'; Released = '2026-02-04'; Added = '' }
        @{ Id = 'dolphin-vr-redux'; Title = 'Dolphin VR + ReduX'; Released = ''; Added = '' }
        @{ Id = 'fallout-4-vr'; Title = 'Fallout 4 VR'; Released = '2026-09-13'; Added = '' }
        @{ Id = 'far-cry-vr'; Title = 'Far Cry VR'; Released = '2023-11-21'; Added = '' }
        @{ Id = 'firewatch-vr'; Title = 'Firewatch VR'; Released = ''; Added = '' }
        @{ Id = 'freespace-2-vr'; Title = 'Freespace 2 VR'; Released = '2026-09-11'; Added = '' }
        @{ Id = 'half-life-vr'; Title = 'Half-Life VR'; Released = ''; Added = '' }
        @{ Id = 'half-life-2-vr'; Title = 'Half-Life 2 VR'; Released = ''; Added = '' }
        @{ Id = 'hl2-vr-ep-one'; Title = 'HL2 VR Ep. One'; Released = ''; Added = '' }
        @{ Id = 'hl2-vr-ep-two'; Title = 'HL2 VR Ep. Two'; Released = ''; Added = '' }
        @{ Id = 'halo-ce-vr'; Title = 'Halo CE VR'; Released = '2026-01-10'; Added = '' }
        @{ Id = 'jedi-knight-jedi-academy-vr'; Title = 'Jedi Knight: Jedi Academy VR'; Released = '2024-04-21'; Added = '' }
        @{ Id = 'jedi-knight-jedi-outcast-vr'; Title = 'Jedi Knight: Jedi Outcast VR'; Released = '2024-04-21'; Added = '' }
        @{ Id = 'morrowind-vr'; Title = 'Morrowind VR'; Released = '2026-05-30'; Added = '' }
        @{ Id = 'neon-white-vr'; Title = 'Neon White VR'; Released = ''; Added = '' }
        @{ Id = 'portal-2-community-edition-vr'; Title = 'Portal 2: Community Edition VR'; Released = ''; Added = '' }
        @{ Id = 'receiver-2-vr'; Title = 'Receiver 2 VR'; Released = ''; Added = '' }
        @{ Id = 'resident-evil-2r-vr'; Title = 'Resident Evil 2R VR'; Released = ''; Added = '' }
        @{ Id = 'resident-evil-3r-vr'; Title = 'Resident Evil 3R VR'; Released = ''; Added = '' }
        @{ Id = 'resident-evil-4r-vr'; Title = 'Resident Evil 4R VR'; Released = ''; Added = '' }
        @{ Id = 'resident-evil-7-vr'; Title = 'Resident Evil 7 VR'; Released = ''; Added = '' }
        @{ Id = 're-village-vr'; Title = 'RE Village VR'; Released = ''; Added = '' }
        @{ Id = 're-requiem-vr'; Title = 'RE Requiem VR'; Released = ''; Added = '' }
        @{ Id = 'shipbreaker-vr'; Title = 'Shipbreaker VR'; Released = ''; Added = '' }
        @{ Id = 'skyrim-vr'; Title = 'Skyrim VR'; Released = ''; Added = '' }
        @{ Id = 'stanley-parable-vr'; Title = 'Stanley Parable VR'; Released = ''; Added = '' }
        @{ Id = 'star-wars-x-wing-vr'; Title = 'Star Wars: X-Wing VR'; Released = ''; Added = '' }
        @{ Id = 'uevr-deluxe'; Title = 'UEVR Deluxe'; Released = '2026-08-16'; Added = '' }
        @{ Id = 'uuvr-rai-pal'; Title = 'UUVR / Rai Pal'; Released = '2026-07-16'; Added = '' }
        @{ Id = 'vivecraft'; Title = 'Vivecraft'; Released = ''; Added = '' }
    )
}

function ConvertTo-CatalogIndexDate {
    param([AllowNull()]$Value)
    $text = ([string]$Value).Trim()
    if (-not $text) { return $null }
    try {
        return [DateTime]::ParseExact(
            $text,
            'yyyy-MM-dd',
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::None)
    } catch {
        return $null
    }
}

function Initialize-CatalogIndex {
    param(
        [object[]]$Motion,
        [object[]]$Gamepad,
        [object[]]$External
    )

    $sourceGroups = [ordered]@{
        Motion   = @($Motion)
        Gamepad  = @($Gamepad)
        External = @($External)
    }
    $sourceByTitle = @{}
    $sourceGroupByTitle = @{}
    $errors = [System.Collections.Generic.List[string]]::new()

    foreach ($groupName in $sourceGroups.Keys) {
        foreach ($game in $sourceGroups[$groupName]) {
            $title = ([string]$game.Title).Trim()
            if (-not $title) {
                $errors.Add("$groupName contains a game without a title.")
                continue
            }
            if ($sourceByTitle.ContainsKey($title)) {
                $errors.Add("Duplicate catalog title: $title")
                continue
            }
            $sourceByTitle[$title] = $game
            $sourceGroupByTitle[$title] = $groupName
        }
    }

    $seenIds = @{}
    $seenTitles = @{}
    foreach ($groupName in $script:CatalogIndexSpec.Keys) {
        foreach ($record in $script:CatalogIndexSpec[$groupName]) {
            $id = ([string]$record.Id).Trim()
            $title = ([string]$record.Title).Trim()
            if ($id -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
                $errors.Add("Invalid stable id '$id' for '$title'.")
            } elseif ($seenIds.ContainsKey($id)) {
                $errors.Add("Duplicate stable id: $id")
            } else {
                $seenIds[$id] = $true
            }
            if (-not $title) {
                $errors.Add("Empty title in $groupName index.")
            } elseif ($seenTitles.ContainsKey($title)) {
                $errors.Add("Duplicate index title: $title")
            } else {
                $seenTitles[$title] = $true
            }
            if (-not $sourceByTitle.ContainsKey($title)) {
                $errors.Add("Index title is missing from Catalog.ps1: $title")
            } elseif ($sourceGroupByTitle[$title] -ne $groupName) {
                $errors.Add("'$title' is indexed as $groupName but defined as $($sourceGroupByTitle[$title]).")
            }
            foreach ($field in @('Released', 'Added')) {
                $stamp = ([string]$record[$field]).Trim()
                if ($stamp -and -not (ConvertTo-CatalogIndexDate $stamp)) {
                    $errors.Add("Invalid $field date '$stamp' for '$title'; use yyyy-MM-dd.")
                }
            }
        }
    }
    foreach ($title in $sourceByTitle.Keys) {
        if (-not $seenTitles.ContainsKey($title)) {
            $errors.Add("Catalog title is missing from CatalogIndex.ps1: $title")
        }
    }

    $global:CatalogIndexErrors = @($errors)
    if ($errors.Count -gt 0) {
        $global:CatalogIndexValid = $false
        Write-Warning ("Catalog index rejected; original order kept. " + ($errors -join ' | '))
        return $null
    }

    $resolved = [ordered]@{ Motion = @(); Gamepad = @(); External = @() }
    $global:CatalogGameById = @{}
    $global:CatalogGameByTitle = @{}
    $globalOrder = 0

    foreach ($groupName in $script:CatalogIndexSpec.Keys) {
        $groupOrder = 0
        foreach ($record in $script:CatalogIndexSpec[$groupName]) {
            $game = $sourceByTitle[[string]$record.Title]
            $released = ConvertTo-CatalogIndexDate $record.Released
            $added = ConvertTo-CatalogIndexDate $record.Added

            $game.Id = [string]$record.Id
            $game.CatalogGroup = $groupName
            $game.CatalogOrder = $globalOrder
            $game.CatalogGroupOrder = $groupOrder
            # Retire the old ambiguous field at runtime. Catalog release dates
            # are for sorting only; update detection must use an exact version,
            # reviewed build stamp, version file or structural proof.
            if ($game -is [System.Collections.IDictionary] -and $game.Contains('ModReleasedAt')) {
                [void]$game.Remove('ModReleasedAt')
            }
            $game.ModReleasedDate = $released
            $game.HubAddedDate = $added
            if ($record.Added) { $game.HubAddedAt = [string]$record.Added }

            $resolved[$groupName] += $game
            $global:CatalogGameById[$game.Id] = $game
            $global:CatalogGameByTitle[$game.Title] = $game
            $globalOrder++
            $groupOrder++
        }
    }

    $global:CatalogIndexValid = $true
    [pscustomobject]@{
        Motion   = @($resolved.Motion)
        Gamepad  = @($resolved.Gamepad)
        External = @($resolved.External)
    }
}

$__catalogIndexResult = Initialize-CatalogIndex -Motion $ownGames -Gamepad $ownGamesGP -External $externalGames
if ($__catalogIndexResult) {
    $ownGames = @($__catalogIndexResult.Motion)
    $ownGamesGP = @($__catalogIndexResult.Gamepad)
    $externalGames = @($__catalogIndexResult.External)
}
Remove-Variable __catalogIndexResult -ErrorAction SilentlyContinue
