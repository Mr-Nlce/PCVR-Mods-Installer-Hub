# -------------------------------------------------------
# Own installers - alphabetical
# -------------------------------------------------------
$ownGames = @(
    @{
        Controls    = "MC"
        Title       = "7 Days to Die VR"
        SteamId     = "251570"
        Mod         = "7DaysVR (Alpha 21)"
        Pill        = "7D2DVR"
        Description = "Guided Nexus download."
        Author      = "7DaysVR Team"
        Bat         = "7DaysVR\START_INSTALLER.bat"
        Color       = "#0f1a0f"
        Accent      = "#55aa33"
        InfoUrl     = "https://docs.google.com/document/d/1gI9_EpF7ACiZu3bndAj1A5uGy0TKVUnfVfvTbHtWsPM/view?tab=t.0"
        ModFile     = "7DaysToDie_Data\Managed\UnityEngine.VRModule.dll"
        SteamFolder = "7 Days To Die"
        GameExe     = "7DaysToDie.exe"
        Tags=@("7 days", "7dtd", "7d2d", "7d2dvr", "zombies", "fps", "open world", "shooter", "survival")
    },
    @{
        Controls    = "MC"
        Title       = "Alien: Isolation VR"
        SteamId     = "214490"
        Mod         = "MotherVR + GRAND"
        WebVersionUrl = "https://www.alienisolationvr.com/"
        Description = "Steam version required."
        Author      = "(auto-updates) Nibre + JayP"
        Bat         = "AlienIsolationVR\START_INSTALLER.bat"
        Color       = "#1a0f00"
        Accent      = "#ff9900"
        InfoUrl     = "https://www.alienisolationvr.com/"
        ModFile     = "dxgi.dll"
        SteamFolder = "Alien Isolation"
        FallbackPaths=@("STEAM:Alien Isolation")
        # Installer applies a Windows 11 registry fix and bails
        # out if not elevated. The Hub triggers UAC for this one
        # game; all others launch normally.
        RequiresAdmin = $true
        Tags=@("alien isolation", "alien", "mothervr", "grand", "atmospheric", "horror", "stealth", "survival horror", "auto-updates")
    },
    @{
        Controls    = "MC"
        Title       = "Amnesia VR"
        SteamId     = "57300"
        Mod         = "Sclerosis v1.8.16"
        Description = "itch.io download required"
        Author      = "CreaTeam"
        Bat         = "AmnesiaVR\START_INSTALLER.bat"
        Color       = "#0a0a14"
        Accent      = "#aa7733"
        InfoUrl     = "https://createam.itch.io/sclerosis-an-amnesia-vr-remake"
        ModFile     = "Sclerosis.exe"
        LaunchExe   = "Sclerosis.exe"
        SteamFolder = "Amnesia The Dark Descent"
        FallbackPaths=@("GOG:Amnesia The Dark Descent")
        Tags=@("amnesia", "amnesia the dark descent", "sclerosis", "createam", "survival horror", "horror", "atmospheric", "psychological horror", "adventure")
    },
    @{
        Controls    = "MC"
        Title       = "Anomaly VR"
        SteamId     = ""
        PortraitUrl = "Assets/AnomalyVR_portrait.jpg"
        HeaderUrl   = "Assets/AnomalyVR_header.jpg"
        Mod         = "AoE VR (launcher updates)"
        Description = "Discord login, runtime choice"
        Author      = "Anomaly VR Team"
        Bat         = "AnomalyVR\START_INSTALLER.bat"
        Color       = "#1a1408"
        Accent      = "#88aa55"
        InfoUrl     = "https://discord.gg/kGhd7GvJ5F"
        ModFile     = "AoeVrLauncher.exe"
        ModFileAlt  = "JSGME.exe"
        LaunchExe   = "AoeVrLauncher.exe"
        SteamFolder = "Anomaly VR"
        FallbackPaths=@("C:\games\Anomaly VR", "D:\games\Anomaly VR", "E:\games\Anomaly VR", "C:\Games\Anomaly VR")
        Tags=@("stalker", "s.t.a.l.k.e.r.", "s.t.a.l.k.e.r. anomaly", "stalker anomaly", "anomaly", "chornobyl", "chernobyl", "x-ray engine", "fps", "shooter", "survival", "open world", "post-apocalyptic", "first-person", "fan game")
    },
    @{
        Controls    = "MC"
        Title       = "Anomaly GAMMA"
        SteamId     = ""
        PortraitUrl = "Assets/AnomalyGamma_portrait.jpg"
        HeaderUrl   = "Assets/AnomalyGamma_header.jpg"
        ScreenshotUrl = "Assets/AnomalyGamma_screenshot.jpg"
        Mod         = "GAMMA VR v0.3.1"
        Description = "Discord login, complete pack"
        Author      = "GAMMA VR Team"
        Bat         = "AnomalyGammaVR\START_INSTALLER.bat"
        Color       = "#0d140a"
        Accent      = "#6fa934"
        InfoUrl     = "https://discord.gg/kGhd7GvJ5F"
        ModFile     = "GAMMA VR.bat"
        LaunchExe   = "GAMMA VR.bat"
        SteamFolder = "Gamma VR"
        FallbackPaths=@("C:\Games\Gamma VR", "D:\Games\Gamma VR", "E:\Games\Gamma VR", "C:\games\Gamma VR")
        Quip        = "Into the Zone, stalker - GAMMA and all. The atom hums."
        Tags=@("stalker", "s.t.a.l.k.e.r.", "s.t.a.l.k.e.r. anomaly", "s.t.a.l.k.e.r. gamma", "stalker gamma", "gamma", "anomaly gamma", "anomaly", "chornobyl", "chernobyl", "x-ray engine", "survival", "fps", "open world", "shooter", "post-apocalyptic", "first-person", "crafting", "fan game", "modpack")
    },
    @{
        Controls    = "MC"
        Title       = "Ashes 2063 VR"
        SteamId     = ""
        PortraitUrl = "Assets/Ashes2063VR_portrait.jpg"
        HeaderUrl   = "Assets/Ashes2063VR_header.jpg"
        ScreenshotUrl = "Assets/Ashes2063VR_screenshot.jpg"
        Quip        = "Tune in to Spire Radio, scavenger - the wasteland is hungry tonight."
        Mod         = "gzdoomvr 4.13.2.2"
        Description = "GZDoom total conversion"
        Author      = "Vostyok / hh79"
        Bat         = "Ashes2063VR\START_INSTALLER.bat"
        Color       = "#1a0f06"
        Accent      = "#d4842a"
        InfoUrl     = "https://www.moddb.com/mods/ashes-2063"
        DownloadUrl = "https://www.moddb.com/mods/ashes-2063/downloads/ashes-stand-alone-version-101"
        ModFile     = "Play Ashes 2063 VR.bat"
        LaunchExe   = "Play Ashes 2063 VR.bat"
        StandaloneVR = $true
        SteamFolder = "Ashes 2063 VR"
        FallbackPaths=@("C:\Games\Ashes 2063 VR", "D:\Games\Ashes 2063 VR", "E:\Games\Ashes 2063 VR", "C:\games\Ashes 2063 VR")
        Tags=@("ashes", "ashes 2063", "gzdoom", "doom", "doom mod", "total conversion", "post-apocalyptic", "wasteland", "fps", "shooter", "boomer shooter", "fallout", "stalker", "retro", "free", "vostyok", "afterglow", "hard reset", "motion controls")
    },
    @{
        Controls    = "MC"
        Title       = "Bendy VR"
        SteamId     = "622650"
        Mod         = "BendyVR v1.2.2"
        Description = "Full VR with motion controls."
        Author      = "Team Beef Studios"
        Bat         = "BendyVR\START_INSTALLER.bat"
        Color       = "#1a0f00"
        Accent      = "#cc8800"
        InfoUrl     = "https://github.com/Team-Beef-Studios/BendyVR"
        ModFile     = "winhttp.dll"
        SteamFolder = "Bendy and the Ink Machine"
        LaunchExe   = "Bendy and the Ink Machine.exe"
        FallbackPaths = @(
            "C:\Games\Bendy VR",
            "STEAM:Bendy and the Ink Machine",
            "EPIC:Bendy and the Ink Machine",
            "EPIC:BendyAndTheInkMachine"
        )
        DepotInstall  = $true
        # DualMode: two installable variants - the mod on the current
        # Steam build (may not launch since the June 2025 game update),
        # AND a pinned-depot mod-compatible build under C:\Games\Bendy
        # VR. When both exist the Hub shows a 3-way split button. No
        # auto-update: the depot manifest is pinned in the installer.
        DualMode        = $true
        DepotPath       = "C:\Games\Bendy VR"
        DepotLaunchExe  = "Bendy and the Ink Machine.exe"
        DepotLaunchArgs = ""
        Tags=@("bendy", "ink machine", "team beef", "atmospheric", "horror", "puzzle", "comic")
    },
    @{
        Controls    = "MC"
        Title       = "Black Mesa Source VR"
        SteamId     = "362890"
        Mod         = "BMSVR Beta 2.0"
        Description = "HL2VR Ep.2 Mod"
        Author      = "Ashok"
        Bat         = "BMSVR\\START_INSTALLER.bat"
        Color       = "#0a1518"
        Accent      = "#33aacc"
        InfoUrl     = "https://www.nexusmods.com/halflife2episode2/mods/4"
        ModFile     = "ModOrganizer.exe"
        SteamFolder = "Black Mesa"
        # In-Hub launch: same setup as the desktop shortcut.
        # MO2 with the BMS profile launches the BMS campaign in
        # the Half-Life 2 VR engine.
        LaunchExe   = "ModOrganizer.exe"
        LaunchArgs  = '-p "Black Mesa Source VR" "Half-Life 2 VR"'
        # New default + legacy paths from older setups. Existence
        # of any = VR Ready.
        FallbackPaths = @(
            "C:\Games\Black Mesa VR",
            "C:\Games\BMSVR_Beta2"
        )
        DepotInstall  = $true
        Tags=@("black mesa", "bms", "half-life", "hl1", "ashok", "fps", "shooter", "story")
    },
    @{
        Controls    = "MC"
        Title       = "Breath of the Wild VR"
        Quip        = "Climb anything, cook questionable meals, and chase the next shrine on the horizon."
        Mod         = "BetterVR (auto-updates)"
        Description = "BotW Wii-U ROM required"
        Author      = "Crementif"
        Bat         = "BreathOfTheWildVR\START_INSTALLER.bat"
        Color       = "#1c2a1e"
        Accent      = "#7bb86a"
        SteamFolder = "Breath of the Wild VR"
        FallbackPaths=@("C:\Games\Breath of the Wild VR", "D:\Games\Breath of the Wild VR", "E:\Games\Breath of the Wild VR")
        PortraitUrl = "Assets/BreathOfTheWildVR_portrait.jpg"
        HeaderUrl   = "Assets/BreathOfTheWildVR_header.jpg"
        ScreenshotUrl = "Assets/BreathOfTheWildVR_screenshot.jpg"
        InfoUrl     = "https://github.com/Crementif/BotW-BetterVR"
        ModFile     = "BetterVR_Launcher.exe"
        LaunchExe   = "BetterVR_Launcher.exe"
        Tags        = @("breath of the wild", "botw", "zelda", "bettervr", "cemu", "wii u", "adventure", "open world", "action")
    },
    @{
        Controls    = "MC"
        Title       = "Content Warning VR"
        SteamId     = "2881650"
        Mod         = "CWVR (auto-updates)"
        Description = "Full VR, auto-updates."
        Author      = "DaXcess"
        Bat         = "ContentWarningVR\START_INSTALLER.bat"
        Color       = "#0a0a0a"
        Accent      = "#ff4444"
        InfoUrl     = "https://github.com/DaXcess/CWVR"
        ModFile     = "BepInEx\plugins\CWVR\CWVR.dll"
        SteamFolder = "Content Warning"
        LaunchExe   = "Content Warning.exe"
        FallbackPaths = @(
            "C:\Games\Content Warning VR",
            "STEAM_CONTENT\ContentWarning-VR"
        )
        DepotInstall  = $true
        ThunderstoreAuthor  = "DaXcess"
        ThunderstorePackage = "CWVR"
        # DualMode: this game has two installable variants - the
        # current Thunderstore-based mod (auto-updates) inside the
        # Steam library, AND a pinned-depot legacy install under
        # C:\Games\<Name> VR\. When both exist, the Hub shows a
        # 3-way split button (Start Current / Start Depot / Reinstall).
        DualMode        = $true
        DepotPath       = "C:\Games\Content Warning VR"
        DepotLaunchExe  = "Content Warning.exe"
        DepotLaunchArgs = ""
        Tags=@("content warning", "cwvr", "daxcess", "comedy", "coop", "horror")
    },
    @{
        Controls    = "MC"
        Title       = "Cruelty Squad VR"
        SteamId     = "1388770"
        Mod         = "CrueltySquadVR v1.3"
        Description = "Full VR with motion controls."
        Author      = "teddybear082"
        Bat         = "CrueltySquadVR\START_INSTALLER.bat"
        Color       = "#1a1f12"
        Accent      = "#8fbf3f"
        InfoUrl     = "https://github.com/teddybear082/CrueltySquadVR-Modloader"
        ModFile     = "openxr_loader.dll"
        SteamFolder = "Cruelty Squad"
        LaunchExe   = "crueltysquad.exe"
        FallbackPaths = @(
            "STEAM:Cruelty Squad"
        )
        Tags=@("cruelty squad", "crus", "teddybear082", "immersive sim", "shooter", "fps", "surreal", "horror")
    },
    @{
        Controls    = "MC"
        Title       = "Cyberpunk 2077"
        SteamId     = "1091500"
        Mod         = "CP_VRPort (auto-updates)"
        Description = "OpenXR, motion controls."
        Author      = "dariulone"
        Bat         = "Cyberpunk2077VR\START_INSTALLER.bat"
        Color       = "#0a0e12"
        Accent      = "#fcee0a"
        InfoUrl     = "https://github.com/dariulone/cyberpunk-vr-port"
        GitHubNightly = "dariulone/cyberpunk-vr-port"
        Quip        = "Wake up, samurai - Night City won't burn itself down."
        ModFile     = "bin\x64\dxgi.dll"
        SteamFolder = "Cyberpunk 2077"
        FallbackPaths = @(
            "STEAM:Cyberpunk 2077",
            "GOG:Cyberpunk 2077",
            "EPIC:Cyberpunk 2077"
        )
        Tags=@("cyberpunk 2077", "cyberpunk", "night city", "dariulone", "openxr", "red4ext", "cet", "rpg", "open world", "action", "fps", "shooter", "sci-fi")
    },
    @{
        Controls    = "MC"
        Title       = "Daggerfall VR"
        Quip        = "Six thousand dungeons, now wall to wall around you."
        SteamId     = "1812390"
        Mod         = "DF_Unity_VR v0.9.1"
        Description = "DF Unity, motion controls"
        Author      = "LokiusV"
        Bat         = "DaggerfallUnityVR\START_INSTALLER.bat"
        Color       = "#1a1308"
        Accent      = "#c89b3c"
        InfoUrl     = "https://www.nexusmods.com/daggerfallunity/mods/979"
        ModPageUrl  = "https://github.com/LokiusV/Daggerfall-Unity-VR"
        LaunchExe   = "DaggerfallUnity.exe"
        ModFile     = "BepInEx\plugins\DFUVR.dll"
        FallbackPaths = @(
            "C:\Games\Daggerfall Unity VR",
            "D:\Games\Daggerfall Unity VR",
            "E:\Games\Daggerfall Unity VR"
        )
        Tags=@("daggerfall", "dfuvr", "elder scrolls", "rpg", "open world", "adventure", "lokiusv", "bepinex", "dungeon")
    },
    @{
        Controls    = "MC"
        Title       = "Deep Rock Galactic VR"
        SteamId     = "548430"
        Mod         = "VRG v1.2.10"
        Pill        = "DRGVR"
        Description = "Full VR with motion controls."
        Author      = "Kosro, HerrFristi, Alch3m1st"
        Bat         = "DRGVRG\START_INSTALLER.bat"
        Color       = "#1a0f00"
        Accent      = "#ffcc22"
        InfoUrl     = "https://mod.io/g/drg/m/vrg"
        ModFile     = "FSD\Mods\vrg_logs.txt"
        SteamFolder = "Deep Rock Galactic"
        Tags=@("deep rock galactic", "drg", "drgvr", "vrg", "rock and stone", "coop", "fps", "sci-fi", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Doom VR"
        SteamId     = "2280"
        Mod         = "GZDoomVR v4.13.2.2"
        Description = "Full VR with motion controls."
        Author      = "hh79"
        Bat         = "DoomVR\START_INSTALLER.bat"
        Color       = "#1a0000"
        Accent      = "#dd3322"
        InfoUrl     = "https://github.com/hh79/gzdoomvr"
        ModFile     = "gzdoomvr.exe"
        VrInstallRoot   = "LOCALAPPDATA:GZDoomVR"
        VrInstallEvidence = @("wads\DOOM.WAD")
        LaunchExe   = "gzdoomvr.exe"
        LaunchArgs  = '-iwad "wads\DOOM.WAD" +vr_mode 10'
        SteamFolder = "Ultimate Doom"
        FallbackPaths = @("STEAM:DOOM", "STEAM:Ultimate Doom", "GOG:DOOM", "GOG:Doom", "GOG:DOOM (1993)")
        Tags=@("doom", "questzdoom", "fps", "boomer shooter", "id software", "retro", "classic")
    },
    @{
        Controls    = "MC"
        Title       = "Doom 2 VR"
        SteamId     = "2300"
        Mod         = "GZDoomVR v4.13.2.2"
        Description = "Full VR with motion controls."
        Author      = "hh79"
        Bat         = "Doom2VR\START_INSTALLER.bat"
        Color       = "#1a0000"
        Accent      = "#dd3322"
        InfoUrl     = "https://github.com/hh79/gzdoomvr"
        ModFile     = "gzdoomvr.exe"
        VrInstallRoot   = "LOCALAPPDATA:GZDoomVR"
        VrInstallEvidence = @("wads\DOOM2.WAD")
        LaunchExe   = "gzdoomvr.exe"
        LaunchArgs  = '-iwad "wads\DOOM2.WAD" +vr_mode 10'
        SteamFolder = "Doom 2"
        FallbackPaths = @("STEAM:DOOM II", "STEAM:Doom 2", "STEAM:Ultimate Doom", "STEAM:DOOM", "GOG:DOOM II", "GOG:Doom II", "GOG:Doom 2")
        Tags=@("doom", "doom 2", "questzdoom", "fps", "boomer shooter", "id software", "retro", "classic")
    },
    @{
        Controls    = "MC"
        Title       = "Doom 3 BFG VR"
        SteamId     = "208200"
        Pill        = "BFGFULLY_VR"
        Mod         = "Fully Possessed v0.021j"
        Description = "Full VR with motion controls."
        Author      = "NPi2Loup"
        Bat         = "Doom3BFGVR\START_INSTALLER.bat"
        Color       = "#1a0000"
        Accent      = "#cc2200"
        InfoUrl     = "https://github.com/NPi2Loup/DOOM-3-BFG-VR/blob/without-dualwelding/README.txt"
        ModFile     = "openvr_api.dll"
        SteamFolder = "DOOM 3 BFG Edition"
        FallbackPaths=@("GOG:DOOM 3 BFG Edition", "GOG:Doom 3 BFG")
        LaunchExe   = "Doom3BFGVR.exe"
        Tags=@("doom", "doom 3", "bfg", "fully possessed", "fps", "horror", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Dredge VR"
        SteamId     = "1562430"
        Mod         = "DredgeVR v0.4.2"
        Description = "Full VR with motion controls."
        Author      = "xen-42"
        Bat         = "DredgeVR\START_INSTALLER.bat"
        Color       = "#001a1a"
        Accent      = "#1a3d4a"
        InfoUrl     = "https://github.com/xen-42/DredgeVR"
        ModFile     = "winhttp.dll"
        SteamFolder = "DREDGE"
        FallbackPaths=@("GOG:DREDGE", "GOG:Dredge", "EPIC:DREDGE")
        Tags=@("dredge", "fishing", "atmospheric", "horror", "mystery")
    },
    @{
        Controls    = "MC"
        Title       = "Dusk HD (DLC) VR"
        SteamId     = "519860"
        Mod         = "UnityVR_DuskHD v1.0.0"
        Description = "Discord login, DLC needed"
        Author      = "Astienth"
        Bat         = "DuskHDVR\START_INSTALLER.bat"
        Color       = "#1a0a00"
        Accent      = "#cc6622"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1449484957671227555/1449484957671227555"
        ModFile     = "DLC\DUSK HD\BepInEx\plugins\UnityVR_DuskHD.dll"
        SteamFolder = "DUSK"
        FallbackPaths=@("GOG:DUSK")
        LaunchExe   = "Dusk.exe"
        Tags=@("dusk", "dusk hd", "fps", "shooter", "retro", "quake", "horror", "fast paced", "boomer shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Escape from Tarkov VR"
        Quip        = "Survive the raid, secure the loot, pray the extract stays open."
        SteamId     = "3932890"
        PortraitUrl = "Assets/SPTVR_portrait.jpg"
        HeaderUrl   = "Assets/SPTVR_header.jpg"
        Mod         = "SPT-VR (auto-updates)"
        GithubRepo  = "cybensis/SPT-VR"
        Description = "Single Player Tarkov (SPT)"
        Author      = "cybensis"
        Bat         = "SPTVR\START_INSTALLER.bat"
        Color       = "#13130d"
        Accent      = "#c2a25e"
        InfoUrl     = "https://github.com/cybensis/SPT-VR"
        ModPageUrl  = "https://github.com/cybensis/SPT-VR"
        DownloadUrl = "https://api.github.com/repos/cybensis/SPT-VR/releases/latest"
        ModFile     = "BepInEx\plugins\sptvr\SPT-VR.dll"
        LaunchExe   = "Start SPT VR.bat"
        SteamFolder = "Escape from Tarkov"
        VrInstallRoot = "C:\Games\SPT VR"
        FallbackPaths=@("C:\Games\SPT VR", "D:\Games\SPT VR", "E:\Games\SPT VR")
        Tags        = @("escape from tarkov", "tarkov", "eft", "spt", "single player tarkov", "sptarkov", "cybensis", "matsix", "fps", "shooter", "survival", "extraction", "tactical", "realistic", "looter", "flat2vr")
    },
    @{
        Controls    = "MC"
        Title       = "Final Fantasy XIV VR"
        SteamId     = "39210"
        Mod         = "FFXIV VR v0.0.62"
        Description = "Dalamud plugin, guided setup."
        Author      = "WesleyLuk90"
        Bat         = "FfxivVR\START_INSTALLER.bat"
        Color       = "#1a0a10"
        Accent      = "#3366cc"
        InfoUrl     = "https://github.com/WesleyLuk90/ffxiv-vr"
        SteamFolder = "FINAL FANTASY XIV Online"
        # The FFXIV VR mod runs through XIVLauncher (+ Dalamud plugin),
        # so the reliable, store-independent "installed" marker is
        # XIVLauncher.exe in its install folder (default is
        # %LocalAppData%\XIVLauncher\current). SteamFolder above only
        # serves to pass the scan gate; the launcher paths below resolve
        # the actual detection. If the launcher lives elsewhere the user
        # can point the Hub at it with "Locate Game".
        ModFile     = "XIVLauncher.exe"
        # Start in VR launches XIVLauncher (Priority-0 uses the
        # installer-recorded .installed_path = XIVLauncher folder),
        # NOT steam://39210 which would start the flat retail client.
        LaunchExe   = "XIVLauncher.exe"
        FallbackPaths = @(
            "$env:LOCALAPPDATA\XIVLauncher\current",
            "$env:LOCALAPPDATA\XIVLauncher",
            "$env:ProgramFiles\XIVLauncher",
            "${env:ProgramFiles(x86)}\XIVLauncher"
        )
        Tags=@("final fantasy", "ffxiv", "ff14", "fantasy", "mmo", "rpg")
    },
    @{
        Controls    = "MC"
        Title       = "Garry's Mod VR"
        SteamId     = "4000"
        Mod         = "VRMod x64 Ultimate"
        Pill        = "GMODVR"
        Description = "Workshop + modules, x64."
        Author      = "Abyss-c0re / Doom Slayer"
        Bat         = "GModVR\START_INSTALLER.bat"
        Color       = "#1a1410"
        Accent      = "#ff9933"
        InfoUrl     = "https://steamcommunity.com/sharedfiles/filedetails/?id=3442302711"
        ModFile     = "garrysmod\lua\bin\gmcl_vrmod_win64.dll"
        SteamFolder = "GarrysMod"
        Tags=@("garry", "gmod", "gmodvr", "garrys mod", "vrmod", "coop", "sandbox", "physics", "multiplayer")
    },
    @{
        Controls    = "BOTH"
        Title       = "Grand Theft Auto V VR"
        Quip        = "Pull off the heist, outrun the stars, and own the streets of Los Santos."
        SteamId     = "271590"
        Mod         = "R.E.A.L. + VRV (auto-updates)"
        GithubRepo  = "SanguShellz/GTA-VRV-Patcher"
        GithubRepoAlt = "FranciscoManzanilla/GTA-VRV-Patcher"
        Description = "GTA5 Legacy, not Enhanced"
        Author      = "Luke Ross / GTAVR"
        Bat         = "GTAVR\START_INSTALLER.bat"
        Color       = "#0c140a"
        Accent      = "#7cb342"
        InfoUrl     = "https://github.com/SanguShellz/GTA-VRV-Patcher"
        ModPageUrl  = "https://www.patreon.com/realvr"
        LaunchExe   = "PlayGTAV.exe"
        ModFile     = "RealVR.asi"
        SteamFolder = "Grand Theft Auto V"
        FallbackPaths = @("STEAM:Grand Theft Auto V", "EPIC:GTAV", "XBOX:Grand Theft Auto V", "C:\Program Files\Rockstar Games\Grand Theft Auto V")
        TwoMods     = $true
        ModAName    = "Gamepad"
        ModASub     = "VRLaunch"
        ModALaunch  = "GTA5 VR (Gamepad).bat"
        ModBName    = "Motion WIP"
        ModBSub     = "VRLaunch"
        ModBLaunch  = "GTA5 VR Motion (WIP).bat"
        ModBProbeFile = "GTAVR.asi"
        # You provide your own working GTA V (Legacy) on build 1.0.2245.0;
        # the installer layers Luke Ross R.E.A.L. r7 on top and records
        # .installed_path, so detection works like Richard Burns Rally.
        Tags        = @("grand theft auto", "gta", "gta v", "gta 5", "luke ross", "real", "open world", "action", "crime", "driving", "shooter", "sandbox")
    },
    @{
        Controls    = "MC"
        Title       = "GTFO VR"
        SteamId     = "493520"
        Mod         = "GTFO_VR 1.4.0 beta"
        Pill        = "GTFOVR"
        Description = "Discord login required"
        Author      = "DSprtn"
        Bat         = "GTFOVR\START_INSTALLER.bat"
        Color       = "#0a0a0a"
        Accent      = "#bb1122"
        InfoUrl     = "https://github.com/DSprtn/GTFO_VR_Plugin"
        ModFile     = "BepInEx\plugins\GTFO_VR.dll"
        SteamFolder = "GTFO"
        LaunchExe   = "GTFO.exe"
        Tags=@("gtfo", "10 chambers", "dsprtn", "coop", "horror", "shooter", "tactical", "fps", "multiplayer", "unity", "bepinex", "flat2vr")
    },
    @{
        Controls    = "MC"
        Title       = "Gunfire Reborn"
        SteamId     = "1217060"
        Mod         = "VRMod 1.0.9.1 + bHaptics"
        Pill        = "GFRVR"
        Description = "Full VR, Steam depot build"
        Author      = "PureDark + Astienth"
        Bat         = "GunfireReborn_VR\START_INSTALLER.bat"
        Color       = "#7a1a1a"
        Accent      = "#ff6b4d"
        InfoUrl     = "https://github.com/Astienth/gunfire-reborn-bhaptics/releases/tag/1.0.0"
        ModFile     = "BepInEx\plugins\PureDark.VRMod\VRMod.dll"
        SteamFolder = "Gunfire Reborn"
        # The VR build needs the -vrmode OpenVR argument; without
        # it the game launches in flat mode. The desktop shortcut
        # passes this; the Hub does the same when "Start in VR" is
        # used so users aren't dependent on the shortcut surviving.
        LaunchExe   = "Gunfire Reborn.exe"
        LaunchArgs  = "-vrmode OpenVR"
        # New default + legacy: older setups copied the depot into
        # steamapps\common\Gunfire Reborn (which Steam would later
        # overwrite). New setups use C:\Games\Gunfire Reborn VR.
        FallbackPaths=@("C:\Games\Gunfire Reborn VR", "EPIC:GunfireReborn", "XBOX:Gunfire Reborn", "GOG:Gunfire Reborn")
        DepotInstall  = $true
        Tags=@("gunfire", "gunfire reborn", "gfr", "gfrvr", "coop", "fps", "roguelite", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Heretic VR"
        SteamId     = "2390"
        Mod         = "GZDoomVR v4.13.2.2"
        Description = "Full VR with motion controls."
        Author      = "hh79"
        Bat         = "HereticVR\START_INSTALLER.bat"
        Color       = "#15001a"
        Accent      = "#aa3399"
        InfoUrl     = "https://github.com/hh79/gzdoomvr"
        ModFile     = "gzdoomvr.exe"
        VrInstallRoot   = "LOCALAPPDATA:GZDoomVR"
        VrInstallEvidence = @("wads\HERETIC.WAD")
        LaunchExe   = "gzdoomvr.exe"
        LaunchArgs  = '-iwad "wads\HERETIC.WAD" +vr_mode 10'
        SteamFolder = "Heretic Shadow of the Serpent Riders"
        FallbackPaths = @("STEAM:Heretic + Hexen", "STEAM:Heretic Shadow of the Serpent Riders", "STEAM:Heretic", "GOG:Heretic + Hexen", "GOG:Heretic Shadow of the Serpent Riders", "GOG:Heretic", "XBOX:Heretic + Hexen")
        Tags=@("heretic", "questzdoom", "fantasy", "fps", "raven", "boomer shooter", "retro", "classic")
    },
    @{
        Controls    = "MC"
        Title       = "Hexen VR"
        SteamId     = "2360"
        Mod         = "GZDoomVR v4.13.2.2"
        Description = "Full VR with motion controls."
        Author      = "hh79"
        Bat         = "HexenVR\START_INSTALLER.bat"
        Color       = "#15001a"
        Accent      = "#9933cc"
        InfoUrl     = "https://github.com/hh79/gzdoomvr"
        ModFile     = "gzdoomvr.exe"
        VrInstallRoot   = "LOCALAPPDATA:GZDoomVR"
        VrInstallEvidence = @("wads\HEXEN.WAD")
        LaunchExe   = "gzdoomvr.exe"
        LaunchArgs  = '-iwad "wads\HEXEN.WAD" +vr_mode 10'
        SteamFolder = "Hexen Beyond Heretic"
        FallbackPaths = @("STEAM:Heretic + Hexen", "STEAM:Hexen Beyond Heretic", "STEAM:Hexen", "GOG:Heretic + Hexen", "GOG:Hexen Beyond Heretic", "GOG:HeXen", "XBOX:Heretic + Hexen")
        Tags=@("hexen", "questzdoom", "fantasy", "fps", "raven", "boomer shooter", "retro", "classic")
    },
    @{
        Controls    = "MC"
        Title       = "Hexen II VR"
        SteamId     = "9060"
        Mod         = "VHexen2 v0.1.5-pc-alpha"
        Description = "OpenXR, motion controls."
        Author      = "alexdnax"
        Bat         = "Hexen2VR\START_INSTALLER.bat"
        Color       = "#1a0a00"
        Accent      = "#cc7722"
        InfoUrl     = "https://www.moddb.com/mods/hexen-ii-vr/downloads"
        ModFile     = "vhexen2-desktop.exe"
        SteamFolder = "Hexen 2"
        FallbackPaths = @("C:\games\Hexen II VR", "D:\games\Hexen II VR", "E:\games\Hexen II VR", "C:\Games\Hexen II VR", "STEAM:Hexen2-VR")
        LaunchExe   = "vhexen2-desktop.exe"
        Tags=@("hexen", "hexen2", "vhexen2", "action", "fantasy", "fps")
    },
    @{
        Controls    = "MC"
        Title       = "House of the Dead Remake VR"
        Pill        = "HOTDR_VR_1.0"
        SteamId     = "1694600"
        Mod         = "HOTDR_VR_1.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "HouseOfTheDeadRemakeVR\START_INSTALLER.bat"
        Color       = "#180808"
        Accent      = "#cc3333"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1391730397418881067/1391730397418881067"
        ModFile     = "BepInEx\plugins\TheHouseOfTheDead_VR.dll"
        SteamFolder = "The House of the Dead Remake"
        FallbackPaths=@("STEAM:THE HOUSE OF THE DEAD Remake", "STEAM:House of the Dead Remake", "STEAM:TheHouseOfTheDeadRemake", "GOG:THE HOUSE OF THE DEAD Remake", "GOG:House of the Dead Remake", "GOG:The House of the Dead - Remake", "GOG:The House of the Dead Remake")
        Tags=@("house of the dead", "hotd", "hotd remake", "astienth", "rail shooter", "on-rails", "shooter", "horror", "zombies", "arcade", "remake")
    },
    @{
        Controls    = "MC"
        Title       = "House of the Dead 2 Remake VR"
        Pill        = "HOTD2R_VR"
        SteamId     = "3376690"
        Mod         = "HOTD2R_VR"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "HouseOfTheDead2RemakeVR\START_INSTALLER.bat"
        Color       = "#180808"
        Accent      = "#cc3333"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1504155922572775554/1504155922572775554"
        ModFile     = "BepInEx\plugins\TheHouseOfTheDead2_VR.dll"
        SteamFolder = "THE HOUSE OF THE DEAD 2 Remake"
        FallbackPaths=@("STEAM:House of the Dead 2 Remake", "STEAM:TheHouseOfTheDead2Remake", "GOG:THE HOUSE OF THE DEAD 2 Remake", "GOG:House of the Dead 2 Remake")
        Tags=@("house of the dead 2", "hotd2", "hotd2 remake", "astienth", "rail shooter", "on-rails", "shooter", "horror", "zombies", "arcade", "remake", "sega")
    },
    @{
        Controls    = "MC"
        Title       = "Hytale VR"
        SteamId     = ""
        PortraitUrl = "Assets/Hytale_portrait.jpg"
        HeaderUrl   = "Assets/Hytale_header.jpg"
        ScreenshotUrl = "Assets/Hytale_screenshot.jpg"
        Quip        = "Block by block, a whole world wraps around you."
        Mod         = "HytaleVRInjector (auto-updates)"
        GithubRepo  = "heurazy/HytaleVRInjector-mod"
        Description = "Experimental, own Hytale copy"
        Author      = "heurazy"
        Bat         = "HytaleVR\START_INSTALLER.bat"
        Color       = "#0a1220"
        Accent      = "#3fb0f0"
        InfoUrl     = "https://github.com/heurazy/HytaleVRInjector-mod"
        DownloadUrl = "https://github.com/heurazy/HytaleVRInjector-mod/releases/latest"
        ModFile     = "hytale_camera_dashboard.exe"
        LaunchExe   = "Start Hytale VR.bat"
        SteamFolder = "Hytale VR"
        FallbackPaths=@("C:\Games\Hytale VR", "D:\Games\Hytale VR", "E:\Games\Hytale VR", "C:\games\Hytale VR", "APPDATA:Hytale\install\release\package\game\latest\Client\HytaleClient.exe")
        Tags=@("hytale", "hytale vr", "hytalevrinjector", "heurazy", "hypixel", "sandbox", "voxel", "block", "building", "crafting", "rpg", "adventure", "exploration", "open world", "fantasy", "multiplayer", "coop")
    },
    @{
        Controls    = "MC"
        Title       = "I Can Gun VR"
        SteamId     = ""
        PortraitUrl = "Assets/ICanGunVR_portrait.png"
        HeaderUrl   = "Assets/ICanGunVR_header.png"
        ScreenshotUrl = "Assets/ICanGunVR_screenshot.png"
        Quip        = "Operate every round by hand. Twelve documents, zero mercy."
        Mod         = "I Can Gun v4"
        Pill        = "ICG_VR"
        Description = "Free itch.io download"
        Author      = "Patrick Koenig"
        Bat         = "ICanGunVR\START_INSTALLER.bat"
        Color       = "#0a121f"
        Accent      = "#3a7fd6"
        InfoUrl     = "https://patrickkoenig.itch.io/i-can-gun"
        ModFile     = "ICG.exe"
        LaunchExe   = "ICG.exe"
        StandaloneVR = $true
        SteamFolder = "I Can Gun VR"
        FallbackPaths=@("C:\Games\I Can Gun VR", "D:\Games\I Can Gun VR", "E:\Games\I Can Gun VR", "C:\games\I Can Gun VR")
        Tags=@("i can gun", "icangun", "icg", "patrick koenig", "koenig", "receiver-like", "fps", "shooter", "action", "sim", "atmospheric", "guns", "tactical", "procedural", "indie", "free")
    },
    @{
        Controls    = "MC"
        Title       = "Iron Lung VR"
        Pill        = "IronLung_VR"
        SteamId     = ""
        PortraitUrl = "Assets/IronLungVR_portrait.jpg"
        HeaderUrl   = "Assets/IronLungVR_header.jpg"
        Mod         = "Iron Lung VR v1.2.0"
        Description = "itch.io download required"
        Author      = "Jack Randolph"
        Bat         = "IronLungVR\START_INSTALLER.bat"
        Color       = "#1a0808"
        Accent      = "#aa3333"
        InfoUrl     = "https://jackaapacka.itch.io/iron-lung-vr"
        ModFile     = "Iron Lung VR.exe"
        LaunchExe   = "Iron Lung VR.exe"
        SteamFolder = "Iron Lung VR"
        FallbackPaths=@("C:\Games\Iron Lung VR", "D:\Games\Iron Lung VR", "E:\Games\Iron Lung VR", "C:\games\Iron Lung VR")
        Tags=@("horror", "atmospheric", "underwater", "submersed", "indie", "first-person", "fan game", "narrative", "mystery", "submarine", "iron lung", "jack randolph", "david szymanski")
    },
    @{
        Controls    = "MC"
        Title       = "Kerbal Space Program"
        SteamId     = "220200"
        Mod         = "KerbalVR (auto-updates)"
        Description = "CKAN-driven setup. Native VR."
        Author      = "JonnyOThan / FirstPersonKSP"
        Bat         = "KSPVR\START_INSTALLER.bat"
        Color       = "#0a0e1a"
        Accent      = "#9acc44"
        InfoUrl     = "https://github.com/FirstPersonKSP/Kerbal-VR/wiki/Installation-Guide"
        ModFile     = "GameData\KerbalVR"
        SteamFolder = "Kerbal Space Program"
        GameExe     = "KSP_x64.exe"
        Tags=@("kerbal space program", "ksp", "kerbal", "space", "rocket", "rockets", "simulation", "sim", "sandbox", "physics", "orbit", "kerbalvr", "jonnyothan", "firstpersonksp", "flat2vr")
    },
    @{
        Controls    = "MC"
        Title       = "Left 4 Dead 2 VR"
        SteamId     = "550"
        Mod         = "L4D2VR (auto-updates)"
        Description = "Roomscale VR, guided setup."
        Author      = "keyou91"
        GitHubNightly = "keyou91/l4d2vr"
        RollingUpdate = $true
        RollingUpdateAsset = "L4D2VR.zip"
        Bat         = "L4D2VR\START_INSTALLER.bat"
        Color       = "#1a0808"
        Accent      = "#cc2222"
        InfoUrl     = "https://github.com/keyou91/l4d2vr"
        ModFile     = "openvr_api.dll"
        SteamFolder = "Left 4 Dead 2"
        Tags=@("l4d2", "left 4 dead", "left4dead", "coop", "fps", "horror", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Lethal Company VR"
        SteamId     = "1966720"
        Mod         = "LCVR (auto-updates)"
        Description = "Current or previous branch."
        Author      = "DaXcess"
        Bat         = "LethalCompanyVR\START_INSTALLER.bat"
        Color       = "#0a0a1a"
        Accent      = "#aacc22"
        InfoUrl     = "https://thunderstore.io/c/lethal-company/p/DaXcess/LethalCompanyVR/"
        ModFile     = "Lethal Company_Data\Managed\UnityEngine.VRModule.dll"
        SteamFolder = "Lethal Company"
        ThunderstoreAuthor  = "DaXcess"
        ThunderstorePackage = "LethalCompanyVR"
        Tags=@("lethal company", "lcvr", "comedy", "coop", "horror")
    },
    @{
        Controls    = "MC"
        Title       = "Life is Strange: BtS"
        SteamId     = "554620"
        Mod         = "DawnVR v1.0.1"
        Description = "Original + Remaster supported."
        Author      = "TrevTV"
        Bat         = "DawnVR\START_INSTALLER.bat"
        Color       = "#1a0a2e"
        Accent      = "#3388dd"
        InfoUrl     = "https://github.com/TrevTV/DawnVR"
        ModFile     = "Mods\DawnVRMod.dll"
        SteamFolder = "Life is Strange - Before the Storm"
        FallbackPaths=@("GOG:Life is Strange Before the Storm", "EPIC:Life is Strange Before the Storm")
        Tags=@("life is strange", "before the storm", "lis", "dawn", "narrative", "story", "walking sim")
    },
    @{
        Controls    = "MC"
        Title       = "Metal: Hellsinger VR"
        SteamId     = "1061910"
        Mod         = "HellsingerVR v0.9.0"
        Pill        = "HellsingerVR"
        Description = "Steam depot build"
        Author      = "LivingFray"
        Bat         = "MetalHellsingerVR\START_INSTALLER.bat"
        Color       = "#160404"
        Accent      = "#e0431f"
        InfoUrl     = "https://github.com/LivingFray/HellsingerVR"
        ModFile     = "BepInEx\plugins\HellsingerVR.dll"
        SteamFolder = "Metal Hellsinger"
        LaunchExe   = "Metal.exe"
        FallbackPaths = @("C:\Games\Metal Hellsinger VR", "D:\Games\Metal Hellsinger VR", "E:\Games\Metal Hellsinger VR")
        DepotInstall = $true
        Notice      = "An official VR version of Metal: Hellsinger now exists, with further improvements and performance optimizations over this community mod. If you want the most polished experience, get the official release on Steam. This Hub entry installs the free community HellsingerVR mod (by LivingFray) onto a pinned Steam depot build, for those who prefer the mod route."
        NoticeUrl   = "https://store.steampowered.com/app/2878270/Metal_Hellsinger_VR/"
        Quip        = "Shoot, dash and slaughter to the beat of metal."
        Tags=@("metal hellsinger", "metal: hellsinger", "hellsinger", "livingfray", "rhythm", "fps", "shooter", "action", "adventure", "horror", "demons", "hell", "metal", "depot", "bepinex")
    },
    @{
        Controls    = "MC"
        Title       = "Metroid Prime VR"
        SteamId     = ""
        PortraitUrl = "Assets/MetroidPrimeVR_portrait.jpg"
        HeaderUrl   = "Assets/MetroidPrimeVR_header.jpg"
        ScreenshotUrl = "Assets/MetroidPrimeVR_screenshot.jpg"
        Quip        = "Scan the unknown, lock on, and let the arm cannon do the talking."
        Mod         = "PrimedGun (auto-updates)"
        GithubRepo  = "Nobbie248/PrimedGun"
        Description = "GameCube ROM NTSC 1.0"
        Author      = "Nobbie"
        Bat         = "MetroidPrimeVR\START_INSTALLER.bat"
        Color       = "#1a0e06"
        Accent      = "#e8731c"
        InfoUrl     = "https://github.com/Nobbie248/PrimedGun"
        DownloadUrl = "https://github.com/Nobbie248/PrimedGun/releases/latest"
        ModFile     = "PrimedGun.exe"
        LaunchExe   = "PrimedGun.exe"
        StandaloneVR = $true
        SteamFolder = "Metroid Prime VR"
        FallbackPaths=@("C:\Games\Metroid Prime VR", "D:\Games\Metroid Prime VR", "E:\Games\Metroid Prime VR", "C:\games\Metroid Prime VR")
        Tags=@("adventure", "action", "metroidvania", "fps", "first-person", "exploration", "sci-fi", "retro", "metroid", "metroid prime", "prime", "samus", "samus aran", "nintendo", "gamecube", "dolphin", "redux", "primedgun", "nobbie", "6dof", "motion controls")
    },
    @{
        Controls    = "MC"
        Title       = "Moros Protocol VR"
        SteamId     = "1605250"
        Mod         = "MorosProtocol_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "MorosProtocolVR\START_INSTALLER.bat"
        Color       = "#0a0a1a"
        Accent      = "#cc3322"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1456423903177211925/1456423903177211925"
        ModFile     = "BepInEx\plugins\MorosProtocol_VR.dll"
        SteamFolder = "Moros Protocol"
        FallbackPaths=@("GOG:Moros Protocol")
        LaunchExe   = "Moros Protocol.exe"
        Tags=@("moros protocol", "astienth", "fps", "shooter", "roguelite", "rogue lite", "pixel art", "space", "action", "fast paced", "horror", "indie")
    },
    @{
        Controls    = "MC"
        Title       = "Mouse P.I. For Hire VR"
        SteamId     = "2416450"
        Mod         = "MousePI_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "MousePIVR\START_INSTALLER.bat"
        Color       = "#141210"
        Accent      = "#c9a24b"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1523984295633490031/1523984342077014069"
        ModFile     = "BepInEx\plugins\MousePI_VR.dll"
        SteamFolder = "MOUSE"
        FallbackPaths=@("STEAM:MOUSE", "STEAM:Mouse", "STEAM:MOUSE P.I. For Hire", "C:\XboxGames\MOUSE P.I. For Hire\Content", "XBOX:MOUSE P.I. For Hire")
        Tags=@("mouse", "mouse pi", "p.i.", "for hire", "jack pepper", "detective", "noir", "fps", "shooter", "boomer shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Outer Wilds VR"
        SteamId     = "753640"
        Mod         = "NomaiVR 2.10.0"
        Description = "Full VR with motion controls."
        Author      = "Raicuparta & Artum"
        Bat         = "OuterWildsVR\START_INSTALLER.bat"
        Color       = "#0a1a2e"
        Accent      = "#ffcc44"
        InfoUrl     = "https://outerwildsmods.com/mods/nomaivr/"
        ModFile     = "OuterWilds_Data\Managed\UnityEngine.VRModule.dll"
        SteamFolder = "Outer Wilds"
        FallbackPaths=@("EPIC:Outer Wilds", "EPIC:OuterWilds", "XBOX:Outer Wilds", "C:\Program Files\WindowsApps\AnnapurnaInteractive.OuterWilds_*_x64__c96c51jf6wkvm")
        LaunchExe   = "OWML\OWML.Launcher.exe"
        Tags=@("outer wilds", "nomai", "owml", "atmospheric", "exploration", "mystery", "puzzle")
    },
    @{
        Controls    = "MC"
        Title       = "Outward DE VR"
        SteamId     = "794260"
        Mod         = "OutwardVR v0.9.2"
        Description = "Full VR, Steam depot build."
        Author      = "cybensis"
        Bat         = "OutwardVR\START_INSTALLER.bat"
        Color       = "#2a1a0a"
        Accent      = "#4a6b3a"
        InfoUrl     = "https://github.com/cybensis/OutwardVR"
        ModFile     = "Outward_Defed\BepInEx\plugins\OutwardVR.dll"
        SteamFolder = "Outward"
        LaunchExe   = "Outward_Defed\Outward Definitive Edition.exe"
        # Default install path used by our setup. Existence of this
        # folder means the user ran our installer = VR Ready.
        FallbackPaths = @("C:\Games\Outward VR",
            "C:\Games\Outward-VR", "GOG:Outward", "GOG:Outward Definitive Edition")
        DepotInstall  = $true
        Tags=@("outward", "aurai", "fantasy", "open world", "rpg", "survival")
    },
    @{
        Controls    = "MC"
        Title       = "Panzer Dragoon Remake"
        Pill        = "PANZER_DR_VR"
        SteamId     = "1178880"
        Mod         = "PD Remake v1.0"
        Description = "bHaptics + Provolver support"
        Author      = "Astienth"
        Bat         = "PanzerDragoonRemakeVR\START_INSTALLER.bat"
        Color       = "#0a1018"
        Accent      = "#aa6644"
        InfoUrl     = "https://github.com/Astienth/Panzer_Dragoon_Remake_VR_bHaptics_Provolver"
        ModFile     = "BepInEx\plugins\PanzerDragoonRemakeVR.dll"
        SteamFolder = "Panzer Dragoon Remake"
        FallbackPaths=@("STEAM:PanzerDragoonRemake", "STEAM:Panzer Dragoon Remake Demo", "GOG:Panzer Dragoon Remake")
        Tags=@("panzer dragoon", "panzer dragoon remake", "astienth", "rail shooter", "shmup", "dragon", "sega", "saturn", "remake", "provolver", "protubevr", "bhaptics", "fantasy", "arcade")
    },
    @{
        Controls    = "MC"
        Title       = "PEAK VR"
        SteamId     = "3527290"
        Mod         = "PEAK_VR v1.0.0"
        Description = "Steam depot build 1.44a"
        Author      = "AstienVR"
        PortraitUrl = "Assets/PEAKVR_portrait.jpg"
        HeaderUrl   = "https://cdn.cloudflare.steamstatic.com/steam/apps/3527290/library_hero.jpg"
        Bat         = "PEAKVR\START_INSTALLER.bat"
        Color       = "#0a1a14"
        Accent      = "#3da876"
        InfoUrl     = "https://github.com/AstienVR/PEAK_VR"
        ModFile     = "BepInEx\plugins\PEAK_VR.dll"
        SteamFolder = "PEAK"
        LaunchExe   = "PEAK.exe"
        LaunchArgs  = "-force-vulkan"
        FallbackPaths = @(
            "C:\Games\PEAK VR",
            "C:\Games\PEAK-VR"
        )
        DepotInstall  = $true
        Tags=@("peak", "climbing", "coop", "multiplayer", "comedy", "survival", "scout", "mountain", "landfall", "astienvr", "astienth")
    },
    @{
        Controls    = "MC"
        Title       = "Penumbra: Overture VR"
        Quip        = "The deeper you go, the less the dark feels empty."
        SteamId     = "22180"
        Mod         = "Penumbra VR v0.1"
        Description = "Head + hand tracking mod"
        Author      = "simply-jos / newyork167"
        Bat         = "PenumbraVR\START_INSTALLER.bat"
        Color       = "#0d0b08"
        Accent      = "#b58a3a"
        InfoUrl     = "https://github.com/newyork167/penumbra_vr"
        SteamFolder = "Penumbra Overture"
        ModFile     = "redist\Penumbra_vr.exe"
        LaunchExe   = "redist\Penumbra_vr.exe"
        FallbackPaths = @(
            "C:\Games\Penumbra Overture VR",
            "D:\Games\Penumbra Overture VR",
            "E:\Games\Penumbra Overture VR",
            "GOG:Penumbra Overture"
        )
        DepotInstall  = $true
        Tags=@("penumbra", "overture", "horror", "survival", "frictional games", "adventure", "atmospheric", "newyork167", "simply-jos")
    },
    @{
        Controls    = "MC"
        Title       = "Perfect Dark VR"
        Pill        = "Perfect_DarkVR"
        SteamId     = ""
        PortraitUrl = "Assets/PerfectDarkVR_portrait.jpg"
        HeaderUrl   = "Assets/PerfectDarkVR_header.jpg"
        ScreenshotUrl = "Assets/PerfectDarkVR_screenshot.jpg"
        Quip        = "Joanna Dark goes hands-on - dataDyne never saw it coming."
        Mod         = "Perfect Dark VR (auto-updates)"
        GithubRepo  = "Alex-LeTux/perfect_dark_VR"
        Description = "NTSC v1.1 z64 ROM"
        Author      = "Alex-LeTux"
        Bat         = "PerfectDarkVR\START_INSTALLER.bat"
        Color       = "#050a18"
        Accent      = "#2f7dff"
        InfoUrl     = "https://github.com/Alex-LeTux/perfect_dark_VR"
        DownloadUrl = "https://github.com/Alex-LeTux/perfect_dark_VR/releases/latest"
        SupportUrl  = "https://ko-fi.com/alexletux"
        SupportText = "Alex-LeTux develops this VR fork. If you enjoy it, consider supporting them:"
        ModFile     = "pd.x86_64.exe"
        LaunchExe   = "pd.x86_64.exe"
        StandaloneVR = $true
        SteamFolder = "Perfect Dark VR"
        FallbackPaths=@("C:\Games\Perfect Dark VR", "D:\Games\Perfect Dark VR", "E:\Games\Perfect Dark VR", "C:\games\Perfect Dark VR")
        Tags=@("fps", "sci-fi", "stealth", "action", "shooter", "first-person", "classic", "retro", "spy", "perfect dark", "joanna dark", "rare", "n64", "nintendo", "decompilation", "port", "alex-letux", "motion controls")
    },
    @{
        Controls    = "MC"
        Title       = "Portal 2 VR"
        SteamId     = "620"
        Mod         = "Portal2VR (auto-updates)"
        GithubRepo  = "Spencer0187/portal2vr-roomscale"
        Description = "Motion controls, roomscale."
        Author      = "Spencer0187"
        Bat         = "Portal2VR\START_INSTALLER.bat"
        Color       = "#0a1a2a"
        Accent      = "#ff6600"
        InfoUrl     = "https://github.com/Spencer0187/portal2vr-roomscale"
        ModFile     = "VR\manifest.vrmanifest"
        SteamFolder = "Portal 2"
        Tags=@("portal2", "portal 2", "comedy", "puzzle", "story")
    },
    @{
        Controls    = "MC"
        Title       = "Quake VR"
        SteamId     = "2310"
        Mod         = "Quake VR v0.0.8.1"
        Description = "OpenVR, motion controls."
        Author      = "Vittorio Romeo"
        Bat         = "QuakeVR\START_INSTALLER.bat"
        Color       = "#0d0b08"
        Accent      = "#b5732e"
        InfoUrl     = "https://github.com/vittorioromeo/quakevr"
        ModFile     = "quakevr.exe"
        SteamFolder = "Quake"
        FallbackPaths = @("C:\games\Quake VR", "D:\games\Quake VR", "E:\games\Quake VR", "C:\Games\Quake VR")
        LaunchExe   = "quakevr.exe"
        Tags=@("quake", "quakevr", "vittorio romeo", "fps", "shooter", "horror", "retro", "id software", "lovecraft")
    },
    @{
        Controls    = "MC"
        Title       = "Quake 2 VR"
        SteamId     = "2320"
        Mod         = "Quake 2 VR v2.0.0"
        Description = "Oculus runtime, Revive."
        Author      = "Luke Groeninger"
        Bat         = "Quake2VR\START_INSTALLER.bat"
        Color       = "#0d0a06"
        Accent      = "#a8682c"
        InfoUrl     = "http://www.malcolm-s.net/q2vr/"
        Quip        = "Storm Stroggos - the railgun does the talking."
        ModFile     = "quake2vr.exe"
        SteamFolder = "Quake 2"
        FallbackPaths = @("C:\games\Quake 2 VR", "D:\games\Quake 2 VR", "E:\games\Quake 2 VR", "C:\Games\Quake 2 VR")
        LaunchExe   = "quake2vr.exe"
        Revive      = $true
        Tags=@("quake 2", "quake ii", "q2vr", "luke groeninger", "malcolm smith", "kmquake2", "id software", "fps", "shooter", "action")
    },
    @{
        Controls    = "MC"
        Title       = "Quake 3 VR"
        SteamId     = "2200"
        Mod         = "Quake 3 VR v1.0"
        Description = "OpenVR, motion controls."
        Author      = "RippeR37"
        Bat         = "Quake3VR\START_INSTALLER.bat"
        Color       = "#0a0c10"
        Accent      = "#e0742a"
        InfoUrl     = "https://ripper37.github.io/q3vr/"
        Quip        = "Welcome to the Arena - frag fast, climb to Xaero."
        ModFile     = "q3vr.exe"
        SteamFolder = "Quake 3 Arena"
        FallbackPaths = @("C:\games\Quake 3 VR", "D:\games\Quake 3 VR", "E:\games\Quake 3 VR", "C:\Games\Quake 3 VR")
        LaunchExe   = "q3vr.exe"
        Tags=@("quake 3", "quake iii", "quake 3 arena", "q3vr", "ripper37", "ioquake3", "arena", "fps", "shooter", "action")
    },
    @{
        Controls    = "MC"
        Title       = "R.E.P.O. VR"
        SteamId     = "3241660"
        Mod         = "RepoXR (auto-updates)"
        Description = "Full VR, auto-updates."
        Author      = "DaXcess"
        Bat         = "RepoVR\START_INSTALLER.bat"
        Color       = "#0a1a0a"
        Accent      = "#5577dd"
        InfoUrl     = "https://github.com/DaXcess/RepoXR"
        ModFile     = "BepInEx\plugins\RepoXR\RepoXR.dll"
        SteamFolder = "REPO"
        ThunderstoreAuthor  = "DaXcess"
        ThunderstorePackage = "RepoXR"
        # DualMode: this game has two installable variants - the
        # current Thunderstore-based mod (auto-updates) inside the
        # Steam library, AND a pinned-depot legacy install under
        # C:\Games\<Name> VR\. When both exist, the Hub shows a
        # 3-way split button (Start Current / Start Depot / Reinstall).
        DualMode        = $true
        DepotPath       = "C:\Games\REPO VR"
        DepotLaunchExe  = "REPO.exe"
        DepotLaunchArgs = "--repoxr-skip-checksum=1.1.2"
        Tags=@("repo", "repoxr", "daxcess", "comedy", "coop", "horror")
    },
    @{
        Controls    = "MC"
        Title       = "Raft VR"
        SteamId     = "648800"
        Mod         = "RaftVR v1.1.0"
        Description = "Requires older Steam branch."
        Author      = "DrBibop"
        Bat         = "RaftVR\START_INSTALLER.bat"
        Color       = "#001a2a"
        Accent      = "#0099cc"
        InfoUrl     = "https://www.raftmodding.com/mods/raftvr"
        ModFile     = "mods\RaftVR.rmod"
        SteamFolder = "Raft"
        FallbackPaths=@("EPIC:Raft")
        VrInstallRoot = "LOCALAPPDATA:RaftModLoader\current"
        LaunchExe   = "RaftModLoader.exe"
        Tags=@("raft", "raftvr", "coop", "exploration", "survival")
    },
    @{
        Controls    = "MC"
        Title       = "Ratchet & Clank VR"
        Pill        = "RatchetVR"
        SteamId     = ""
        PortraitUrl = "Assets/RatchetVR_portrait.jpg"
        HeaderUrl   = "Assets/RatchetVR_header.jpg"
        ScreenshotUrl = "Assets/RatchetVR_screenshot.jpg"
        Quip        = "Wrench up, Lombax - four classic worlds reborn, bolt by bolt."
        Mod         = "UE Fan Recreation"
        Description = "Free itch.io download"
        Author      = "Rybread69"
        Bat         = "RatchetVR\START_INSTALLER.bat"
        Color       = "#0a1224"
        Accent      = "#f0a020"
        InfoUrl     = "https://rybread69.itch.io/ratchet-and-clank-vr"
        ModFile     = "RatchetVR.exe"
        LaunchExe   = "RatchetVR.exe"
        StandaloneVR = $true
        SteamFolder = "Ratchet VR"
        FallbackPaths=@("C:\Games\Ratchet VR", "D:\Games\Ratchet VR", "E:\Games\Ratchet VR", "C:\games\Ratchet VR")
        Tags=@("ratchet", "clank", "ratchet and clank", "ratchet & clank", "ratchetvr", "rybread69", "rybread", "unreal engine", "fan game", "free", "platformer", "action", "adventure", "sci-fi", "space", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Ready Or Not VR"
        Quip        = "Stack up, breach with caution, and bring every officer home."
        SteamId     = "1144200"
        Mod         = "VRO Mod 1016"
        Description = "Nexus login required"
        Author      = "VR Oasis & KITT"
        Bat         = "ReadyOrNotVR\START_INSTALLER.bat"
        Color       = "#0b0e12"
        Accent      = "#c79a3e"
        InfoUrl     = "https://www.nexusmods.com/readyornot/mods/6914"
        ModFile     = "ReadyOrNot\Content\Paks\pakchunk98-VR_OR_NOT_P.pak"
        SteamFolder = "Ready Or Not"
        # No LaunchExe on purpose: the VR mod only activates with the
        # user's Steam launch options (-usehmd -VRTweaks -VRMappings on
        # DX11). With no LaunchExe the Hub launches via steam://rungameid,
        # so Steam applies those options. Detection uses SteamFolder +
        # ModFile (the pak), so it still flips to VR Ready correctly.
        Tags        = @("ready or not", "void interactive", "vro", "virtual reality oasis", "kitt", "tactical", "swat", "police", "breach", "shooter", "stealth", "realistic", "fps", "single player")
    },
    @{
        Controls    = "MC"
        Title       = "Receiver VR"
        Quip        = "One handgun. Eleven tapes. Every round counts."
        SteamId     = "234190"
        HideSteamButton = $true
        Mod         = "ReceiVR v1.01-beta23"
        Description = "Free standalone VR build"
        Author      = "ShadowBrian"
        Bat         = "ReceiverVR\START_INSTALLER.bat"
        Color       = "#0c0e10"
        Accent      = "#6f8fa6"
        InfoUrl     = "https://github.com/ShadowBrian/7DFPS"
        ModPageUrl  = "https://www.wolfire.com/receiver/"
        SteamFolder = "Receiver"
        LaunchExe   = "Receiver.exe"
        ModFile     = "UnityPlayer.dll"
        StandaloneVR = $true
        FallbackPaths = @(
            "C:\Games\Receiver VR",
            "D:\Games\Receiver VR",
            "E:\Games\Receiver VR"
        )
        Tags=@("receiver", "receivr", "wolfire", "shadowbrian", "shooter", "fps", "survival", "simulation", "7dfps", "guns")
    },
    @{
        Controls    = "MC"
        Title       = "Richard Burns Rally VR"
        Quip        = "Pace notes in your ear, gravel under the tyres, the next corner blind."
        Mod         = "RBRvr 1.6"
        Description = "Existing game install required"
        Author      = "Kegetys"
        Bat         = "RichardBurnsRallyVR\START_INSTALLER.bat"
        Color       = "#190a0a"
        Accent      = "#d23b30"
        InfoUrl     = "https://www.kegetys.fi/category/gaming/rbrmods/"
        ModPageUrl  = "https://www.kegetys.fi/category/gaming/rbrmods/"
        LaunchExe   = "RichardBurnsRally_SSE.exe"
        ModFile     = "Plugins\RBRvrConfig.dll"
        PortraitUrl = "Assets/RichardBurnsRallyVR_portrait.jpg"
        HeaderUrl   = "Assets/RichardBurnsRallyVR_header.jpg"
        ScreenshotUrl = "Assets/RichardBurnsRallyVR_screenshot.jpg"
        Tags=@("richard burns rally", "rbr", "rbrvr", "kegetys", "rally", "racing", "driving", "simulation", "sim")
    },
    @{
        Controls    = "MC"
        Title       = "Risk of Rain 2"
        SteamId     = "632360"
        Mod         = "VRMod 2.9.2"
        Pill        = "ROR2VR"
        Description = "Full VR, Steam depot build."
        Author      = "DrBibop"
        Bat         = "RoR2_VR\START_INSTALLER.bat"
        Color       = "#1a5c8a"
        Accent      = "#4db8ff"
        InfoUrl     = "https://github.com/DrBibop/RoR2VRMod"
        ModFile     = "BepInEx\plugins\VRMod.dll"
        SteamFolder = "Risk of Rain 2"
        LaunchExe   = "Risk of Rain 2.exe"
        # Depot install: VR mod files live in steamapps\content\
        # app_632360\depot_632361. Existence of this folder = VR Ready.
        FallbackPaths=@("C:\Games\Risk of Rain 2 VR",
            "STEAM_CONTENT\app_632360\depot_632361", "EPIC:RiskOfRain2", "GOG:Risk of Rain 2", "XBOX:Risk of Rain 2")
        DepotInstall  = $true
        Tags=@("ror2", "ror2vr", "ror", "risk of rain", "coop", "roguelite", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Road to Vostok VR"
        SteamId     = "1963610"
        Mod         = "VR Mod (auto-updates)"
        GithubRepo  = "Blah64/Vostok-VR-Mod"
        Pill        = "RTVVR"
        Description = "Full VR, holster system."
        Author      = "Blah64"
        Bat         = "VostokVR\START_INSTALLER.bat"
        Color       = "#0a1a0a"
        Accent      = "#44aa44"
        InfoUrl     = "https://github.com/Blah64/Vostok-VR-Mod"
        ModFile     = "mods\vr-mod.vmz"
        SteamFolder = "Road to Vostok"
        LaunchExe   = "launch_vr.bat"
        Tags=@("road to vostok", "vostok", "rtv", "rtvvr", "survival", "fps", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Saints Row: The Third VR"
        SteamId     = "55230"
        Mod         = "ZMenu VR"
        Description = "DX11 version, Mega download"
        Author      = "zolika1351"
        Bat         = "SaintsRowTheThirdVR\START_INSTALLER.bat"
        Color       = "#160a1f"
        Accent      = "#a64dff"
        InfoUrl     = "https://zolika1351.pages.dev/mods/sr3menu"
        ModFile     = "openvr_api.dll"
        SteamFolder = "Saints Row the Third"
        LaunchExe   = "SaintsRowTheThird_DX11.exe"
        FallbackPaths = @("STEAM:Saints Row the Third", "GOG:Saints Row 3")
        Tags=@("saints row", "saints row 3", "saints row the third", "sr3", "zolika", "zmenu", "open world", "action", "sandbox", "shooter", "third person")
    },
    @{
        Controls    = "MC"
        Title       = "Selaco VR"
        SteamId     = "1592280"
        Mod         = "SelacoVR 2.0"
        Description = "Requires older Steam branch."
        Author      = "emawind84"
        Bat         = "SelacoVR\START_INSTALLER.bat"
        Color       = "#0a1420"
        Accent      = "#39b6c8"
        InfoUrl     = "https://github.com/emawind84/SelacoVR/tree/selacovr2.0"
        ModFile     = "SelacoVR\Selaco.exe"
        SteamFolder = "Selaco"
        FallbackPaths = @("STEAM:Selaco")
        LaunchExe   = "SelacoVR\SelacoVR.bat"
        Tags=@("selaco", "selacovr", "gzdoom", "questzdoom", "fps", "boomer shooter", "retro")
    },
    @{
        Controls    = "MC"
        Title       = "Slime Rancher VR"
        SteamId     = "433340"
        Mod         = "SRVR (auto-updates)"
        GithubRepo  = "Atmudia/SRVR"
        Description = "Full VR with motion controls."
        Author      = "Atmudia"
        Bat         = "SlimeRancherVR\START_INSTALLER.bat"
        Color       = "#1a0a2e"
        Accent      = "#ff66cc"
        InfoUrl     = "https://github.com/Atmudia/SRVR"
        ModFile     = "SlimeRancher_Data\Managed\UnityEngine.VRModule.dll"
        SteamFolder = "Slime Rancher"
        FallbackPaths=@("GOG:Slime Rancher", "EPIC:SlimeRancher", "XBOX:Slime Rancher")
        Tags=@("slime rancher", "srvr", "atmospheric", "exploration", "survival")
    },
    @{
        Controls    = "MC"
        Title       = "Slyders VR"
        SteamId     = "2607870"
        Mod         = "Slyders_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "SlydersVR\START_INSTALLER.bat"
        Color       = "#1a0d20"
        Accent      = "#22ddcc"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1486098905622904852/1486098978297614587"
        ModFile     = "BepInEx\plugins\Slyders_VR.dll"
        SteamFolder = "Slyders"
        LaunchExe   = "Slyders.exe"
        Tags=@("slyders", "astienth", "roguelite", "bullet hell", "fps", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Strife VR"
        SteamId     = "317040"
        Mod         = "GZDoomVR v4.13.2.2"
        Description = "Full VR with motion controls."
        Author      = "hh79"
        Bat         = "StrifeVR\START_INSTALLER.bat"
        Color       = "#0a1500"
        Accent      = "#7aa033"
        InfoUrl     = "https://github.com/hh79/gzdoomvr"
        ModFile     = "gzdoomvr.exe"
        VrInstallRoot   = "LOCALAPPDATA:GZDoomVR"
        VrInstallEvidence = @("wads\strife1.wad")
        LaunchExe   = "gzdoomvr.exe"
        LaunchArgs  = '-iwad "wads\strife1.wad" +vr_mode 10'
        SteamFolder = "Strife"
        FallbackPaths = @("STEAM:Strife Veteran Edition", "GOG:The Original Strife Veteran Edition", "GOG:Strife")
        Tags=@("strife", "questzdoom", "fps", "rpg", "cyberpunk", "boomer shooter", "retro", "classic")
    },
    @{
        Controls    = "MC"
        Title       = "Subnautica VR"
        SteamId     = "264710"
        Mod         = "SubmersedVR (auto-updates)"
        GithubRepo  = "Okabintaro/SubmersedVR"
        Description = "Full VR with motion controls."
        Author      = "Okabintaro"
        Bat         = "SubnauticaVR\START_INSTALLER.bat"
        Color       = "#001520"
        Accent      = "#00aaff"
        InfoUrl     = "https://github.com/Okabintaro/SubmersedVR"
        ModFile     = "BepInEx\plugins\SubmersedVR.dll"
        SteamFolder = "Subnautica"
        FallbackPaths=@("EPIC:Subnautica", "XBOX:Subnautica")
        Tags=@("subnautica", "submersed", "exploration", "open world", "survival", "underwater")
    },
    @{
        Controls    = "MC"
        Title       = "Subnautica: Below Zero"
        SteamId     = "848450"
        Mod         = "Submersed (auto-updates)"
        GithubRepo  = "jbusfield/SubmersedVR_BZ"
        Description = "Full VR with motion controls."
        Author      = "jbusfield"
        Bat         = "SubnauticaBZVR\START_INSTALLER.bat"
        Color       = "#001a20"
        Accent      = "#00ccdd"
        InfoUrl     = "https://github.com/jbusfield/SubmersedVR_BZ"
        ModFile     = "SubnauticaZero_Data\Managed\UnityEngine.VRModule.dll"
        SteamFolder = "SubnauticaZero"
        FallbackPaths=@("EPIC:SubnauticaBelowZero", "EPIC:Subnautica Below Zero", "XBOX:Subnautica Below Zero", "STEAM:Subnautica Zero", "EPIC:Subnautica Zero", "GOG:Subnautica Zero")
        Tags=@("subnautica", "below zero", "submersed", "exploration", "open world", "survival", "underwater")
    },
    @{
        Controls    = "MC"
        Title       = "Techtonica VR"
        SteamId     = "1457320"
        Mod         = "TechtonicaVR v2.0.0"
        Description = "Full VR with motion controls."
        Author      = "3_141 (Xenira)"
        Bat         = "TechtonicaVR\START_INSTALLER.bat"
        Color       = "#0a1418"
        Accent      = "#3aa8c8"
        InfoUrl     = "https://github.com/Xenira/TechtonicaVR"
        ModFile     = "BepInEx\plugins\techtonica_vr\techtonica_vr.dll"
        SteamFolder = "Techtonica"
        Tags=@("techtonica", "factory", "automation", "builder", "survival", "crafting", "sci-fi", "underground", "open world", "early access")
    },
    @{
        Controls    = "MC"
        Title       = "Tomb Raider 1 VR"
        # Default SteamId = TR1 original (1996). The detect logic
        # below also accepts TR I-III Remastered (2024, AppID
        # 2478970) since SauronDesktop extracts assets from either.
        SteamId     = "224960"
        Mod         = "BeefRaiderXR v1.0.0"
        Description = "Team Beef OpenXR port"
        Author      = "Team Beef Studios"
        Bat         = "TombRaiderVR\START_INSTALLER.bat"
        GameExe     = "BeefRaiderXR.exe"
        Color       = "#1a0a05"
        Accent      = "#c47a2c"
        InfoUrl     = "https://github.com/Team-Beef-Studios/BeefRaiderXR"
        # SteamFolder = TR1 (1996) folder name verified via Steam
        # community forum + dosgamers.com guide ("Tomb Raider (I)"
        # with parentheses).
        SteamFolder = "Tomb Raider (I)"
        # Fallbacks cover the other supported source folders:
        #  - TR I-III Remastered on Steam (AppID 2478970,
        #    folder verified on steamcommunity.com/app/2478970)
        #  - TR1 on GOG (Galaxy default folder "Tomb Raider 1")
        #  - TR I-III Remastered on GOG (store-page name)
        FallbackPaths = @(
            "STEAM:Tomb Raider I-III Remastered",
            "GOG:Tomb Raider 1",
            "GOG:Tomb Raider I-III Remastered Starring Lara Croft"
        )
        # The VR port installs OUTSIDE the source game folder. The
        # BeefRaiderXR-1.0.0.7z archive extracts a
        # "BeefRaiderExtractionTool" folder containing SauronDesktop.exe;
        # SauronDesktop then creates a sibling "BeefRaiderXR" folder
        # with the actual game EXE. So default full path is:
        #   C:\games\Tomb Raider VR\BeefRaiderExtractionTool\BeefRaiderXR\BeefRaiderXR.exe
        # After install, .installed_path overrides this with the real
        # resolved location even if the user picked a custom path.
        VrInstallRoot = "C:\games\Tomb Raider VR\BeefRaiderExtractionTool\BeefRaiderXR"
        ModFile       = "BeefRaiderXR.exe"
        LaunchExe     = "BeefRaiderXR.exe"
        Tags        = @("tomb raider", "lara croft", "beefraiderxr", "team beef", "openlara", "xproger", "adventure", "action", "exploration", "platformer", "puzzle", "classic", "retro", "1996")
    },
    @{
        Controls    = "MC"
        Title       = "Tormented Souls VR"
        SteamId     = "1367590"
        Mod         = "TormentedSoulsVR v1.0.0"
        Description = "Full VR, Steam depot build."
        Author      = "cybensis"
        Bat         = "TormentedSoulsVR\START_INSTALLER.bat"
        Color       = "#2a0a0a"
        Accent      = "#5a1a1a"
        InfoUrl     = "https://github.com/cybensis/TormentedSoulsVR"
        ModFile     = "BepInEx\plugins\TormentedSoulsVR.dll"
        SteamFolder = "Tormented Souls"
        LaunchExe   = "TormentedSouls.exe"
        FallbackPaths=@("C:\Games\Tormented Souls VR",
            "STEAM_CONTENT\TormentedSouls-VR",
            "STEAM_COMMON\TormentedSouls-VR", "GOG:Tormented Souls", "EPIC:TormentedSouls")
        DepotInstall  = $true
        Tags=@("tormented", "souls", "caroline", "action", "fantasy", "rpg", "souls-like")
    },
    @{
        Controls    = "MC"
        Title       = "Total Chaos VR"
        SteamId     = ""
        PortraitUrl = "Assets/TotalChaosVR_portrait.jpg"
        HeaderUrl   = "Assets/TotalChaosVR_header.jpg"
        ScreenshotUrl = "Assets/TotalChaosVR_screenshot.jpg"
        Quip        = "Fort Oasis kept the lights off for a reason - don't make it personal."
        Mod         = "gzdoomvr (hh79)"
        Description = "GZDoom survival horror"
        Author      = "wadaholic / hh79"
        Bat         = "TotalChaosVR\START_INSTALLER.bat"
        Color       = "#3a1212"
        Accent      = "#d12a22"
        InfoUrl     = "https://www.moddb.com/mods/total-chaos"
        DownloadUrl = "https://www.moddb.com/mods/total-chaos/downloads/total-chaos-10"
        ModFile     = "Play Total Chaos VR.bat"
        LaunchExe   = "Play Total Chaos VR.bat"
        StandaloneVR = $true
        SteamFolder = "Total Chaos VR"
        FallbackPaths=@("C:\Games\Total Chaos VR", "D:\Games\Total Chaos VR", "E:\Games\Total Chaos VR", "C:\games\Total Chaos VR")
        Tags=@("total chaos", "fort oasis", "gzdoom", "doom", "doom mod", "total conversion", "survival horror", "horror", "survival", "atmospheric", "fps", "shooter", "wadaholic", "free", "retro")
    },
    @{
        Controls    = "MC"
        Title       = "Trombone Champ VR"
        SteamId     = "1059990"
        Mod         = "BaboonVR 0.3.0"
        Description = "Steam depot download"
        Author      = "Raicuparta"
        Notice      = "An official VR version of Trombone Champ now exists - Trombone Champ: Unflattened - a standalone release that is far more polished than this community mod. If you want the most polished experience, get the official version on Steam. This Hub entry installs the free community BaboonVR mod (by Raicuparta) onto a pinned Steam depot build, for those who prefer the mod route."
        NoticeUrl   = "https://store.steampowered.com/app/3151670/Trombone_Champ_Unflattened/"
        Bat         = "TromboneChampVR\START_INSTALLER.bat"
        Color       = "#1a1206"
        Accent      = "#e6b422"
        InfoUrl     = "https://raicuparta.itch.io/baboon-vr"
        ModFile     = "BepInEx\plugins\BaboonVr\com.raicuparta.baboon-vr.dll"
        SteamFolder = "TromboneChamp"
        LaunchExe   = "TromboneChamp.exe"
        FallbackPaths = @(
            "C:\Games\Trombone Champ VR",
            "C:\Games\Trombone-Champ-VR")
        DepotInstall  = $true
        Tags=@("rhythm", "music", "comedy", "multiplayer", "trombone", "champ", "baboonvr", "raicuparta", "holy wow", "meme", "arcade", "casual")
    },
    @{
        Controls    = "MC"
        Title       = "ULTRAKILL VR"
        Pill        = "VRTRAKILL"
        SteamId     = "1229490"
        Mod         = "VRTRAKILL_FRAUD v2.0.0"
        Description = "Full VR, Steam depot build."
        Author      = "Squaresweets"
        Bat         = "UltrakillVR\START_INSTALLER.bat"
        Color       = "#1a0000"
        Accent      = "#ff2222"
        InfoUrl     = "https://github.com/Squaresweets/VRTRAKILL_FRAUD"
        ModFile     = "BepInEx\plugins\VRTRAKILL\VRTRAKILL.dll"
        SteamFolder = "ULTRAKILL"
        LaunchExe   = "ULTRAKILL.exe"
        FallbackPaths = @("C:\Games\ULTRAKILL VR",
            "STEAM_CONTENT\ULTRAKILL-VR",
            "STEAM_COMMON\ULTRAKILL-VR", "GOG:ULTRAKILL")
        DepotInstall  = $true
        Tags=@("ultrakill", "vrtrakill", "fraud", "action", "fast paced", "fps", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Valheim VR"
        SteamId     = "892970"
        Mod         = "VHVR-Mod v0.9.21"
        Description = "Requires DX11, not Vulkan."
        Author      = "brandonmousseau"
        Bat         = "ValheimVR\START_INSTALLER.bat"
        Color       = "#1a2a1a"
        Accent      = "#66cc66"
        InfoUrl     = "https://www.nexusmods.com/valheim/mods/847"
        ModFile     = "valheim_Data\Managed\UnityEngine.VRModule.dll"
        SteamFolder = "Valheim"
        FallbackPaths=@("XBOX:Valheim")
        Tags        = @("vhvr", "survival", "crafting", "viking")
    },
    @{
        Controls    = "MC"
        Title       = "World of Warcraft VR"
        SteamId     = ""
        PortraitUrl = "Assets/WorldOfWarcraft_portrait.jpg"
        HeaderUrl   = "Assets/WorldOfWarcraft_header.jpg"
        Mod         = "WoVR v7"
        Description = "Discord login required"
        Author      = "Marulu"
        Bat         = "WoVR\START_INSTALLER.bat"
        Color       = "#0a1a14"
        Accent      = "#d4af37"
        InfoUrl     = "https://github.com/ProjectMimer/WoVR"
        ModFile     = "vr\config.txt"
        LaunchExe   = "Wow.exe"
        SteamFolder = "World of Warcraft"
        FallbackPaths=@("C:\Program Files (x86)\World of Warcraft", "C:\Program Files\World of Warcraft", "C:\World of Warcraft", "C:\Games\World of Warcraft", "D:\World of Warcraft", "D:\Games\World of Warcraft", "E:\World of Warcraft", "E:\Games\World of Warcraft")
        Tags        = @("world of warcraft", "wow", "wovr", "marulu", "mmo", "mmorpg", "rpg", "open world", "multiplayer", "coop", "adventure", "fantasy", "wotlk", "3.3.5a", "blizzard", "azeroth", "flat2vr")
    }
)

$ownGamesGP = @(
    @{ Controls="GP"; Title="Alba VR"; SteamId="1337010"; Mod="AlbaVR v1.0.0"; SteamFolder="Alba - A Wildlife Adventure"; FallbackPaths=@("GOG:ALBA A Wildlife Adventure", "GOG:Alba A Wildlife Adventure", "EPIC:Alba", "EPIC:Alba - A Wildlife Adventure"); Description="KB`&Mouse or Gamepad VR."; Author="wouterpleizier"; Bat="AlbaVR\START_INSTALLER.bat"; Color="#0a1a0a"; Accent="#5cc8e6"; InfoUrl="https://github.com/wouterpleizier/AlbaVR"; Tags=@("alba", "wildlife", "atmospheric", "exploration", "walking sim") ; ModFile="BepInEx\plugins\AlbaVR.dll" },
    @{ Controls="GP"; Title="Another Crab's Treasure"; Pill="ACT_VR"; SteamId="1887840"; Mod="AnotherCrabs v1.0"; SteamFolder="Another Crab's Treasure"; FallbackPaths=@("STEAM:Another Crabs Treasure", "STEAM:AnotherCrabsTreasure"); GameExe="AnotherCrabsTreasure.exe"; Description="Discord login, depth only"; Author="Astienth"; Bat="AnotherCrabsTreasureVR\START_INSTALLER.bat"; Color="#0a1418"; Accent="#33aacc"; InfoUrl="https://discord.com/channels/1001138422972432597/1262749418981949483/1262749418981949483"; Tags=@("another crabs treasure", "another crab's treasure", "anothercrabstreasure", "astienth", "aggro crab", "souls-like", "underwater", "indie", "action rpg", "3d platformer", "depth"); ModFile="BepInEx\plugins\UnityVR_AnotherCrabTreasure.dll" },
    @{ Controls="GP"; Title="Apollo Justice: Ace Attorney Trilogy VR"; Quip="Objection! The courtroom has never felt this real."; SteamId="2187220"; Mod="REF (auto-updates)"; SteamFolder="Apollo Justice Ace Attorney Trilogy"; FallbackPaths=@("STEAM:ApolloJustice", "GOG:Apollo Justice Ace Attorney Trilogy"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="GS456.exe"; Color="#1a0a0a"; Accent="#990033"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("apollo justice", "reframework", "praydog", "narrative", "puzzle", "story"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Art of Rally VR"; SteamId="550320"; Mod="ArtOfRally_VR v1.0.0"; SteamFolder="artofrally"; FallbackPaths=@("STEAM:Art of Rally", "STEAM:ArtOfRally", "GOG:art of rally", "EPIC:ArtOfRally"); Description="Discord login, experimental"; Author="Astienth"; Bat="ArtOfRallyVR\START_INSTALLER.bat"; Color="#180a0a"; Accent="#dd5544"; InfoUrl="https://discord.com/channels/1001138422972432597/1306503565698662462/1306503565698662462"; Tags=@("art of rally", "artofrally", "astienth", "funselektor", "rally", "racing", "top down", "stylized", "indie", "arcade", "cars", "depth"); ModFile="BepInEx\plugins\ArtOfRally_VR.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Astrodogs VR"
        SteamId     = "1301230"
        Mod         = "AstroDogs_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "AstrodogsVR\START_INSTALLER.bat"
        Color       = "#0a1828"
        Accent      = "#22aadd"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1424110040935043132/1424110255121367213"
        ModFile     = "BepInEx\plugins\AstroDogs_VR.dll"
        SteamFolder = "Astrodogs"
        FallbackPaths=@("STEAM:AstroDogs", "STEAM:astrodogs", "STEAM:Astrodogs Demo", "GOG:Astrodogs")
        Tags=@("astrodogs", "astienth", "star fox", "starfox", "dogs", "anime", "shooter", "space", "arcade", "indie", "colorful")
    },
    @{ Controls="GP"; Title="Atomic Heart VR"; Quip="Welcome to Facility 3826, Comrade. Mind the robots."; SteamId="668580";                 Mod="R.E.A.L."; SteamFolder="AtomicHeart"; FallbackPaths=@("STEAM:Atomic Heart"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc3344"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, atomic heart", "fps", "shooter", "story") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Avatar: Frontiers of Pandora VR"; Quip="Breathe Pandora's air. Hunt the skies with the Na'vi."; SteamId="2840770"; Mod="R.E.A.L."; SteamFolder="Avatar Frontiers of Pandora"; FallbackPaths=@("STEAM:AFOP"); Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#3a8aaa"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, avatar, pandora", "adventure", "open world", "story") ; ModFile="RealRepo\RealVR64.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Bomb Rush Cyberfunk"
        Pill        = "BombRush_VR"
        SteamId     = "1353230"
        Mod         = "BombRushCyberFunk_VR v1.0.0"
        Description = "First & third person"
        Author      = "Astienth"
        Bat         = "BombRushCyberfunkVR\START_INSTALLER.bat"
        Color       = "#180a08"
        Accent      = "#ff66cc"
        InfoUrl     = "https://github.com/AstienVR/Bomb_Rush_Cyberfunk_VR"
        ModFile     = "BepInEx\plugins\BombRushCyberFunk_VR.dll"
        SteamFolder = "Bomb Rush Cyberfunk"
        FallbackPaths=@("STEAM:BombRushCyberfunk", "STEAM:BombRushCyberFunk", "STEAM:Bomb Rush Cyberfunk Demo", "GOG:Bomb Rush Cyberfunk")
        Tags=@("bomb rush cyberfunk", "bombrushcyberfunk", "brc", "astienth", "team reptile", "jet set radio", "jsr", "skating", "graffiti", "parkour", "stylish", "indie", "action")
    },
    @{ Controls="GP"; Title="Circuit Superstars VR"; Pill="CIRCUITSUPER_VR"; SteamId="1097130"; Mod="CIRCUITSUPER_VR_1.0.0"; SteamFolder="Circuit Superstars"; FallbackPaths=@("STEAM:CircuitSuperstars"); Description="bHaptics support included"; Author="Astienth"; Bat="CircuitSuperstarsVR\START_INSTALLER.bat"; Color="#180a08"; Accent="#dd2255"; InfoUrl="https://github.com/Astienth/Circuit_Superstars_VR_bHaptics"; Tags=@("circuit superstars", "circuitsuperstars", "astienth", "racing", "arcade", "top down", "indie", "sports", "cartoon", "stylized", "bhaptics"); ModFile="BepInEx\plugins\CircuitSuperstars_VR.dll" },
    @{ Controls="GP"; Title="Cloudpunk VR"; SteamId="746850"; Mod="Cloudpunk VR v1.0.0"; SteamFolder="Cloudpunk"; FallbackPaths=@("GOG:Cloudpunk", "EPIC:Cloudpunk"); Description="Best option Gamepad VR."; Author="Astienth"; Bat="CloudpunkVR\START_INSTALLER.bat"; Color="#0a0a1a"; Accent="#cc44ff"; InfoUrl="https://github.com/Astienth/Cloudpunk-VR/releases"; Tags=@("cloudpunk", "astienth", "atmospheric", "cyberpunk", "exploration", "narrative"); ModFile="BepInEx\plugins\CloudpunkVR.dll" },
    @{ Controls="GP"; Title="Cloudpunk: City of Ghosts VR"; Pill="CLOUDP_COG_DLC"; SteamId="1536370"; Mod="CoG VR v1.0.0"; SteamFolder="Cloudpunk - City of Ghosts"; FallbackPaths=@("STEAM:Cloudpunk\City of Ghosts", "GOG:Cloudpunk", "EPIC:Cloudpunk"); Description="BepInEx VR mod"; Author="Astienth"; Bat="CloudpunkCOGVR\START_INSTALLER.bat"; Color="#0a0a1a"; Accent="#aa33dd"; InfoUrl="https://github.com/Astienth/Cloudpunk-VR/releases"; Tags=@("cloudpunk", "city of ghosts", "astienth", "atmospheric", "cyberpunk", "exploration", "narrative"); ModFile="BepInEx\plugins\CloudpunkVR_CityofGhosts.dll" },
    @{ Controls="GP"; Title="Dark Souls II VR"; Quip="Bearer of the curse, seek souls. Drangleic awaits."; SteamId="236430";                Mod="R.E.A.L."; SteamFolder="Dark Souls II Scholar of the First Sin"; FallbackPaths=@("STEAM:Dark Souls II"); GameExe="Game\DarkSoulsII.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#7a6a3c"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, dark souls, souls", "action", "fantasy", "rpg", "souls-like") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Dark Souls III VR"; Quip="Bonfire lit. Estus ready. The Lords await your link."; SteamId="374320";               Mod="R.E.A.L."; SteamFolder="DARK SOULS III"; GameExe="Game\DarkSoulsIII.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#8a4a22"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, dark souls, souls", "action", "fantasy", "rpg", "souls-like") ; ModFile="Game\RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Dark Souls Remastered"; Quip="Praise the sun - now you can raise your own hands to it."; SteamId="570940";        Mod="R.E.A.L."; SteamFolder="DARK SOULS REMASTERED"; GameExe="Dark Souls.exe"; Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#a07a3a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, dark souls, souls", "action", "fantasy", "rpg", "souls-like") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Death Stranding VR"; Quip="Reconnect a broken America, Sam. Mind the BTs."; SteamId="1850570";              Mod="R.E.A.L."; SteamFolder="DEATH STRANDING DIRECTORS CUT"; FallbackPaths=@("STEAM:Death Stranding", "STEAM:DEATH STRANDING DIRECTORS CUT"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#5a6a7a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, death stranding, kojima", "atmospheric", "story", "walking sim") ; ModFile="RealRepo\RealVR64.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Decimate Drive VR"
        SteamId     = "2427950"
        Mod         = "DecimateDrive_VR v1.0.0"
        Description = "Discord login, OpenXR"
        Author      = "Astienth"
        Bat         = "DecimateDriveVR\START_INSTALLER.bat"
        Color       = "#0a0a18"
        Accent      = "#aa2222"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1442488939050176583/1442488939050176583"
        ModFile     = "release\BepInEx\plugins\DecimateDrive_VR.dll"
        SteamFolder = "Decimate Drive"
        Tags=@("decimate drive", "astienth", "horror", "driving", "arcade", "indie", "fast paced")
    },
    @{ Controls="GP"; Title="Descenders VR"; Pill="DESCENDERS_VR"; SteamId="681280"; Mod="DescendersVRMod v1.0.5"; SteamFolder="Descenders"; FallbackPaths=@("EPIC:Descenders"); Description="KB`&Mouse or Gamepad VR."; Author="Holydh / kyanite-rock"; Bat="DescendersVR\START_INSTALLER.bat"; Color="#0a0f1a"; Accent="#5588dd"; InfoUrl="https://github.com/kyanite-rock/DescendersVRMod"; Tags=@("descenders", "downhill", "mountain bike", "mtb", "indie", "racing", "sports"); ModFile="BepInEx\plugins\DescendersVRmod.dll" },
    @{ Controls="GP"; Title="Devil May Cry 5 VR"; Quip="Son of Sparda, stay stylish. Hit that SSS rank."; SteamId="601150"; Mod="REF (auto-updates)"; SteamFolder="Devil May Cry 5"; FallbackPaths=@("STEAM:DevilMayCry5", "EPIC:Devil May Cry 5"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="DevilMayCry5.exe"; Color="#1a0000"; Accent="#cc2200"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("devil may cry", "reframework", "praydog", "action", "fast paced", "hack and slash", "stylish"); ModFile="openxr_loader.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Dino Trauma VR"
        SteamId     = "2149420"
        Mod         = "DinoTrauma_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "DinoTraumaVR\START_INSTALLER.bat"
        Color       = "#0a1808"
        Accent      = "#66cc33"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1362075882042167377/1362075882042167377"
        ModFile     = "BepInEx\plugins\DinoTrauma_VR.dll"
        SteamFolder = "Dino Trauma"
        FallbackPaths=@("STEAM:DinoTrauma", "STEAM:Dino Trauma Demo")
        Tags=@("dino trauma", "dinotrauma", "astienth", "dinosaurs", "fps", "retro", "psx", "boomer shooter", "dino crisis", "horror", "indie")
    },
    @{ Controls="GP"; Title="Doom Eternal VR"; Quip="Rip and tear through Hell itself, at arm's length."; SteamId="782330";                 Mod="R.E.A.L."; SteamFolder="DOOMEternal"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa1100"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, doom", "fps", "action", "fast-paced") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Doom: The Dark Ages"; Quip="Stand and fight, Slayer. The medieval war is yours."; SteamId="3017860";          Mod="R.E.A.L."; SteamFolder="DOOM The Dark Ages"; FallbackPaths=@("STEAM:DOOMTheDarkAges"); Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#7a1a12"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, doom", "fps", "action", "fantasy") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Dragon's Dogma 2 VR"; Quip="Grab the griffin. Climb the ogre. The Arisen rides again."; SteamId="2054970"; Mod="REF (auto-updates)"; SteamFolder="Dragon's Dogma 2"; FallbackPaths=@("STEAM:Dragons Dogma 2", "STEAM:DragonsDogma2", "EPIC:Dragon's Dogma 2"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="DD2.exe"; Color="#1a0f00"; Accent="#dd7700"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("dragon dogma 2", "reframework", "praydog", "action", "fantasy", "open world", "rpg"); ModFile="openxr_loader.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Driftwood VR"
        SteamId     = "2223700"
        Mod         = "Driftwood_VR v1.0"
        Description = "Full body lean controls"
        Author      = "Astienth"
        Bat         = "DriftwoodVR\START_INSTALLER.bat"
        Color       = "#0a1808"
        Accent      = "#cc8855"
        InfoUrl     = "https://github.com/Astienth/DriftWood_VR_bHaptics"
        ModFile     = "BepInEx\plugins\Driftwood_VR.dll"
        SteamFolder = "Driftwood"
        FallbackPaths=@("STEAM:Driftwood Demo")
        Tags=@("driftwood", "astienth", "longboard", "longboarding", "skating", "sloth", "downhill", "drifting", "sports", "indie", "cartoon", "stylized", "bhaptics")
    },
    @{ Controls="GP"; Title="Echo Generation 2 VR"; SteamId="1115990"; PortraitUrl="Assets/EchoGeneration2VR_portrait.jpg"; HeaderUrl="Assets/EchoGeneration2VR_header.jpg"; Mod="EchoGeneration2_VR v1.0.0"; Description="Discord login, OpenXR"; Author="Astienth"; Bat="EchoGeneration2VR\START_INSTALLER.bat"; Color="#120c22"; Accent="#8a5cff"; InfoUrl="https://discord.com/channels/1001138422972432597/1521547069804908565/1521547128973955296"; ModFile="BepInEx\plugins\EchoGeneration2_VR.dll"; SteamFolder="Echo Generation 2"; FallbackPaths=@("STEAM:Echo Generation 2", "C:\XboxGames\Echo Generation 2\Content", "D:\XboxGames\Echo Generation 2\Content", "XBOX:Echo Generation 2"); Tags=@("echo generation 2", "echo generation", "echogeneration2", "astienth", "rpg", "deckbuilding", "deckbuilder", "card game", "turn-based", "sci-fi", "space", "adventure", "story", "indie") },
    @{ Controls="GP"; Title="Elden Ring VR"; Quip="Rise, Tarnished, and stand life-size before the Erdtree."; SteamId="1245620";                   Mod="R.E.A.L."; SteamFolder="ELDEN RING"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#c89a3c"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, elden ring, fromsoftware, souls", "action", "fantasy", "open world", "rpg", "souls-like") ; ModFile="Game\RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Far Cry 4 VR"; Quip="Welcome to Kyrat. The Himalayas have never looked so close."; SteamId="298110";                    Mod="R.E.A.L."; SteamFolder="Far Cry 4"; GameExe="bin\FarCry4.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc4a22"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, far cry", "fps", "open world", "action") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Far Cry 5 VR"; Quip="Hope County needs a deputy. Step into the cult's backyard."; SteamId="552520";                    Mod="R.E.A.L."; SteamFolder="Far Cry 5"; GameExe="FarCry5.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa6633"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, far cry", "fps", "open world", "action") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Far Cry 6 VR"; Quip="Viva Libertad! Tear down the regime from inside the headset."; SteamId="2369390";                    Mod="R.E.A.L."; SteamFolder="Far Cry 6"; GameExe="bin\FarCry6.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#dd9933"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, far cry", "fps", "open world", "action") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Far Cry New Dawn VR"; Quip="After the collapse, the pink-and-neon apocalypse awaits."; SteamId="939960";             Mod="R.E.A.L."; SteamFolder="FarCryNewDawn"; FallbackPaths=@("STEAM:Far Cry New Dawn"); GameExe="bin\FarCryNewDawn.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc44aa"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, far cry", "fps", "open world", "post-apocalyptic") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Far Cry Primal VR"; Quip="Tame the beast. Hold the spear. The Stone Age, life-size."; SteamId="371660";               Mod="R.E.A.L."; SteamFolder="Far Cry Primal"; GameExe="bin\FCPrimal.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#8a4a1a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, far cry", "survival", "open world", "prehistoric") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="FF VII Rebirth VR"; Quip="The planet calls again. Cloud's journey, now around you."; SteamId="2909400";               Mod="R.E.A.L."; SteamFolder="FINAL FANTASY VII REBIRTH"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#33aa99"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, final fantasy, ff7", "fantasy", "mmo", "rpg") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="FF VII Remake VR"; Quip="Mako reactors, a buster sword, and all of Midgar."; SteamId="1462040";                Mod="R.E.A.L."; SteamFolder="FINAL FANTASY VII REMAKE INTERGRADE"; FallbackPaths=@("STEAM:FINAL FANTASY VII REMAKE"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#1f7a88"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, final fantasy, ff7", "fantasy", "mmo", "rpg") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Forza Horizon 6 VR"; Pill="FH6_VR"; Quip="Chase the horizon, feel every gear change, and let the festival roar."; SteamId="2483190"; PortraitUrl="Assets/ForzaHorizon6_portrait.jpg"; HeaderUrl="Assets/ForzaHorizon6_header.jpg"; Mod="lufz or NALULUNA"; Description="lufz or NALULUNA mod"; Author="NALULUNA / lufz"; Bat="ForzaHorizon6VR\START_INSTALLER.bat"; Color="#16101f"; Accent="#b454d4"; SteamFolder="ForzaHorizon6"; FallbackPaths=@("C:\XboxGames\Forza Horizon 6\Content", "XBOX:Forza Horizon 6"); TwoMods=$true; ModAName="NALULUNA"; ModASub="NALULUNA"; ModALaunch="fh6vr.exe"; ModBName="lufz"; ModBSub="lufz"; ModBLaunch="vrmod-launcher.exe"; InfoUrl="https://ko-fi.com/s/03bdcc5fe9"; Tags=@("forza horizon 6", "forza", "fh6", "naluluna", "lufz", "racing", "driving", "open world", "arcade racing", "sim", "simulation") },
    @{ Controls="GP"; Title="Ghost of Tsushima VR"; Quip="Stand on Tsushima's wind-swept fields. The Ghost rides."; SteamId="2215430";            Mod="R.E.A.L."; SteamFolder="Ghost of Tsushima DIRECTOR'S CUT"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa3333"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, ghost of tsushima", "action", "open world", "rpg", "story") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Ghosts n Goblins Resurrection VR"; Quip="Lose your armor in one hit - now in glorious 3D."; SteamId="1375400"; Mod="REF (auto-updates)"; SteamFolder="Ghosts n Goblins Resurrection"; FallbackPaths=@("STEAM:GhostsnGoblinsResurrection", "STEAM:Ghosts 'n Goblins Resurrection", "STEAM:Makaimura_GG_RE"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="makaimura_GG_RE.exe"; Color="#0a0a1a"; Accent="#7733aa"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("ghosts goblins", "reframework", "praydog", "fast paced", "platformer", "arcade", "retro"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Ghostwire: Tokyo VR"; Quip="Tokyo is empty. The spirits are not. Weave with your hands."; SteamId="1475810";             Mod="R.E.A.L."; SteamFolder="GhostWire- Tokyo"; FallbackPaths=@("STEAM:Ghostwire Tokyo", "STEAM:GhostwireTokyo", "EPIC:Ghostwire Tokyo"); GameExe="GWT.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc44aa"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, ghostwire", "action", "supernatural", "horror") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Grounded VR"; Quip="Shrunk to bug-size in the backyard. The spiders are huge."; SteamId="962130";                     Mod="R.E.A.L."; SteamFolder="Grounded"; FallbackPaths=@("XBOX:Grounded"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#7aaa33"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, grounded", "survival", "crafting", "co-op") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="High on Life VR"; Quip="Talking guns and bounty hunts - now they're really talking to you."; SteamId="1583230";                 Mod="R.E.A.L."; SteamFolder="High On Life"; FallbackPaths=@("STEAM:HighOnLife", "EPIC:HighOnLife", "XBOX:High On Life"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa44cc"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, high on life", "fps", "comedy", "sci-fi") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Hogwarts Legacy VR"; Quip="Wand at the ready. Walk the halls of Hogwarts yourself."; SteamId="990080";              Mod="R.E.A.L."; SteamFolder="Hogwarts Legacy"; FallbackPaths=@("EPIC:HogwartsLegacy"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#7a5a22"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, hogwarts, harry potter", "adventure", "fantasy", "rpg", "story") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="VRGP"; Title="Hollow Knight Silksong"; Pill="HOLLOWK_S_VR"; SteamId="1030300"; Mod="HollowK_S_VR_1.0.0"; SteamFolder="Hollow Knight Silksong"; FallbackPaths=@("STEAM:HollowKnightSilksong", "STEAM:Silksong", "GOG:Hollow Knight Silksong", "XBOX:Hollow Knight- Silksong"); Description="Discord login, depth only"; Author="Astienth"; Bat="HollowKnightSilksongVR\START_INSTALLER.bat"; Color="#0a0a18"; Accent="#aaccff"; InfoUrl="https://discord.com/channels/1001138422972432597/1414940597579419679/1414940597579419679"; Tags=@("hollow knight", "silksong", "hollowknight", "astienth", "metroidvania", "2d", "platformer", "souls-like", "hand-drawn", "indie", "depth"); ModFile="BepInEx\plugins\HollowKnightSilksong_VR.dll" },
    @{ Controls="GP"; Title="Hollow Knight VR"; SteamId="367520"; Mod="HollowKnight_VR v1.0.0"; SteamFolder="Hollow Knight"; FallbackPaths=@("STEAM:HollowKnight", "GOG:Hollow Knight", "XBOX:Hollow Knight"); Description="Discord login, depth only"; Author="Astienth"; Bat="HollowKnightVR\START_INSTALLER.bat"; Color="#080a14"; Accent="#88aacc"; InfoUrl="https://discord.com/channels/1001138422972432597/1254790696502693888/1254790696502693888"; Tags=@("hollow knight", "hollowknight", "astienth", "team cherry", "metroidvania", "2d", "platformer", "souls-like", "hand-drawn", "indie", "depth"); ModFile="BepInEx\plugins\HollowKnight_VR.dll" },
    @{ Controls="GP"; Title="Horizon Chase Turbo"; Pill="HORIZONCHASE_VR"; SteamId="389140"; Mod="HorizonChaseTurboVR v1.0.0"; SteamFolder="Horizon Chase Turbo"; FallbackPaths=@("STEAM:HorizonChaseTurbo", "STEAM:Horizon Chase Turbo Demo"); Description="Discord login, Steam or Epic"; Author="Astienth"; Bat="HorizonChaseTurboVR\START_INSTALLER.bat"; Color="#180a18"; Accent="#ff66aa"; InfoUrl="https://discord.com/channels/1001138422972432597/1362072336827814020/1362072336827814020"; Tags=@("horizon chase turbo", "horizonchaseturbo", "horizon chase", "astienth", "racing", "arcade", "retro", "top gear", "out run", "indie", "cartoon"); ModFile="BepInEx\plugins\HorizonChaseTurboVR.dll" },
    @{ Controls="GP"; Title="Horizon Forbidden West VR"; Quip="Beyond the frontier, the machines roam. Aloy's bow in hand."; SteamId="2420110";       Mod="R.E.A.L."; SteamFolder="Horizon Forbidden West"; FallbackPaths=@("STEAM:Horizon Forbidden West Complete Edition", "EPIC:HorizonForbiddenWestCompleteEdition", "EPIC:Horizon Forbidden West"); Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc6a22"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, horizon", "action", "open world", "rpg") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Horizon Zero Dawn VR"; Quip="Stand among the machines. Aloy's world, life-size."; SteamId="1151640";            Mod="R.E.A.L."; SteamFolder="Horizon Zero Dawn"; FallbackPaths=@("EPIC:HorizonZeroDawn", "GOG:Horizon Zero Dawn Complete Edition"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa5522"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, horizon", "action", "open world", "rpg") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Horizon Zero Dawn Remastered VR"; Quip="Aloy's world, remastered. The machines tower over you."; SteamId="2561580"; Mod="R.E.A.L."; SteamFolder="Horizon Zero Dawn Remastered"; Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc7733"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, horizon", "action", "open world", "rpg") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Hypogea VR"; SteamId="2980260"; Mod="Hypogea_VR v1.0.0"; SteamFolder="Hypogea"; FallbackPaths=@("STEAM:Hypogea Demo", "STEAM:HYPOGEA"); Description="Discord login required."; Author="Astienth"; Bat="HypogeaVR\START_INSTALLER.bat"; Color="#100818"; Accent="#aa66ee"; InfoUrl="https://discord.com/channels/1001138422972432597/1465600243939672115/1465600264210878691"; Tags=@("hypogea", "astienth", "atmospheric", "retro", "ps1", "platformer", "indie", "narrative", "exploration", "story"); ModFile="BepInEx\plugins\Hypogea_VR.dll" },
    @{ Controls="GP"; Title="Indiana Jones: Great Circle VR"; Quip="Fortune and glory, kid. The whip's in your hand now."; SteamId="2677660";  Mod="R.E.A.L."; SteamFolder="Indiana Jones and the Great Circle"; FallbackPaths=@("STEAM:The Great Circle", "XBOX:The Great Circle"); Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#b88846"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, indiana jones", "adventure", "action", "puzzle") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Kingdom Come: Deliverance II VR"; Quip="Jesus Christ be praised - medieval Bohemia, life-size."; SteamId="1771300"; Mod="R.E.A.L."; SteamFolder="KingdomComeDeliverance2"; Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#5a4a2a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, kingdom come", "rpg", "fantasy", "medieval", "realistic") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Kunitsu-Gami: Path of the Goddess VR"; Quip="Cleanse the defilement by day, defend the maiden by night."; SteamId="2510710"; Mod="REF (auto-updates)"; SteamFolder="KUNITSU-GAMI"; FallbackPaths=@("STEAM:Kunitsu-Gami", "STEAM:KunitsuGami", "STEAM:Kunitsu-Gami Path of the Goddess", "XBOX:Kunitsu-Gami- Path of the Goddess"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="KunitsuGami.exe"; Color="#1a0a00"; Accent="#cc2244"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("kunitsu-gami", "reframework", "praydog", "action", "rpg", "strategy", "japanese"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Lunistice VR"; SteamId="1701800"; Mod="Lunistice_VR v1.0.0"; SteamFolder="Lunistice"; FallbackPaths=@("STEAM:Lunistice Demo", "GOG:Lunistice"); Description="Discord login required."; Author="Astienth"; Bat="LunisticeVR\START_INSTALLER.bat"; Color="#1a0820"; Accent="#ff77cc"; InfoUrl="https://discord.com/channels/1001138422972432597/1465598630382669916/1465598630382669916"; Tags=@("lunistice", "astienth", "cute", "kawaii", "retro", "platformer", "indie", "fast paced", "anime"); ModFile="BepInEx\plugins\Lunistice_VR.dll" },
    @{ Controls="GP"; Title="Mega Man Star Force Legacy VR"; Quip="Transer online. EM Wave Change, Geo - ride on!"; SteamId="3500390"; PortraitUrl="Assets/MegaManStarForce_portrait.jpg"; HeaderUrl="Assets/MegaManStarForce_header.jpg"; Mod="REF (auto-updates)"; SteamFolder="Mega Man Star Force Legacy Collection"; FallbackPaths=@("STEAM:MMSFLEGACYCOLLECTION", "STEAM:MegaManStarForceLegacyCollection"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="STARFORCE.exe"; Color="#001a1a"; Accent="#00cccc"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("mega man star force", "reframework", "praydog", "action", "rpg", "jrpg"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Mirage Feathers VR"; SteamId="2719060"; Mod="MirageFeathers_VR v1.0.0"; SteamFolder="Mirage Feathers"; FallbackPaths=@("STEAM:MirageFeathers", "STEAM:Mirage Feathers Demo", "STEAM:MirageFeathersDemo"); Description="Discord login, Demo or Full"; Author="Astienth"; Bat="MirageFeathersVR\START_INSTALLER.bat"; Color="#180814"; Accent="#88ccdd"; InfoUrl="https://discord.com/channels/1001138422972432597/1325853693530079232/1325853693530079232"; Tags=@("mirage feathers", "miragefeathers", "astienth", "rail shooter", "shmup", "after burner", "space harrier", "hang on", "super scaler", "anime", "arcade", "indie"); ModFile="BepInEx\plugins\MirageFeathers_VR.dll" },
    @{ Controls="GP"; Title="Monster Hunter Rise VR"; Quip="Wirebug up, monster down. The hunt is yours."; SteamId="1446780"; Mod="REF (auto-updates)"; SteamFolder="MonsterHunterRise"; FallbackPaths=@("XBOX:Monster Hunter Rise"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="MonsterHunterRise.exe"; Color="#1a0a00"; Accent="#dd6600"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("monster hunter rise", "reframework", "praydog", "action", "coop", "rpg"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Monster Hunter Stories 3 VR"; Quip="Hatch the egg, ride the monstie. Forge your kinship."; SteamId="2852190"; PortraitUrl="Assets/MonsterHunterStories3_portrait.jpg"; HeaderUrl="Assets/MonsterHunterStories3_header.jpg"; Mod="REF (auto-updates)"; SteamFolder="MONSTER HUNTER STORIES 3"; FallbackPaths=@("STEAM:Monster Hunter Stories 3", "STEAM:MonsterHunterStories3", "STEAM:MONSTER_HUNTER_STORIES_3_TWISTED_REFLECTION"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="MHSTORIES3.exe"; Color="#0a1a0a"; Accent="#ee9933"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("monster hunter stories", "reframework", "praydog", "rpg", "story", "jrpg", "turn-based", "adventure"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Monster Hunter Wilds"; Quip="Track the herd across the wilds, hunter. Bring your blade."; SteamId="2246340"; Mod="REF (auto-updates)"; SteamFolder="MonsterHunterWilds"; Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="MonsterHunterWilds.exe"; Color="#1a0800"; Accent="#ff5500"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("monster hunter wilds", "reframework", "praydog", "action", "coop", "open world", "rpg"); ModFile="openxr_loader.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Moto Rush Reborn VR"
        Pill        = "MotoRush_R_VR"
        SteamId     = "2990060"
        Mod         = "MotoRushReborn_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "MotoRushRebornVR\START_INSTALLER.bat"
        Color       = "#1a1000"
        Accent      = "#dd2222"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1490989987708014672/1490990041382518785"
        ModFile     = "BepInEx\plugins\MotoRushReborn_VR.dll"
        SteamFolder = "Moto Rush Reborn"
        FallbackPaths=@("STEAM:MotoRushReborn", "STEAM:Moto Rush Reborn Demo")
        LaunchExe   = "Moto Rush Reborn.exe"
        Tags=@("moto rush reborn", "astienth", "racing", "sports", "fast paced", "indie")
    },
    @{ Controls="VRGP"; Title="New Star GP VR"; Quip="Lights out and away you go, champ - chase that checkered flag."; SteamId="2217580"; Mod="New_Star_GP_VR"; Description="Discord login required"; Author="Astienth"; Bat="NewStarGPVR\START_INSTALLER.bat"; Color="#12100f"; Accent="#e85d3d"; InfoUrl="https://discord.com/channels/1001138422972432597/1522836877101629490/1522836922676940812"; ModFile="release\BepInEx\plugins\New_Star_GP_VR.dll"; SteamFolder="New Star GP"; FallbackPaths=@("STEAM:New Star GP", "C:\XboxGames\New Star GP\Content", "XBOX:New Star GP"); Tags=@("new star gp", "nsgp", "new star games", "f1", "formula", "motorsport", "racing", "arcade", "sports") },
    @{ Controls="GP"; Title="No One Lives Forever 2 VR"; Pill="NOLF2-R3"; Quip="Slip into Cate Archer's shoes, outwit H.A.R.M., and make spycraft look effortless."; PortraitUrl="Assets/NOLF2_portrait.jpg"; HeaderUrl="Assets/NOLF2_header.jpg"; ScreenshotUrl="Assets/NOLF2_screenshot.jpg"; Mod="Release 3"; Description="NOLF2 1.3 EN required"; Author="Luke Ross"; Bat="NOLF2VR\START_INSTALLER.bat"; Color="#171109"; Accent="#e8923a"; LaunchExe="Lithtech.exe"; ModFile="VRlaunchcmds.txt"; InfoUrl="https://github.com/LukeRoss00/nolf2-real-mod"; ModPageUrl="https://www.patreon.com/realvr"; Tags=@("no one lives forever 2", "nolf2", "nolf", "cate archer", "spy", "stealth", "shooter", "fps", "retro", "adventure", "luke ross", "real") },
    @{ Controls="GP"; Title="Onimusha 2 VR"; Quip="Oni gauntlet ready. The demons of Sengoku await."; SteamId="3046600"; Mod="REF (auto-updates)"; SteamFolder="ONIMUSHA2"; FallbackPaths=@("STEAM:Onimusha 2", "STEAM:Onimusha2"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="Onimusha2.exe"; Color="#0a0a0a"; Accent="#cc6600"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("onimusha 2", "reframework", "praydog", "action", "story", "samurai", "horror"); ModFile="openxr_loader.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Paperklay VR"
        SteamId     = "1350720"
        Mod         = "Paperklay_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "PaperklayVR\START_INSTALLER.bat"
        Color       = "#0a1810"
        Accent      = "#ee9944"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1380447945215836261/1380447945215836261"
        ModFile     = "BepInEx\plugins\Paperklay_VR.dll"
        SteamFolder = "PaperKlay"
        FallbackPaths=@("STEAM:Paperklay", "STEAM:PaperKlay Demo")
        Tags=@("paperklay", "paper klay", "astienth", "platformer", "3d platformer", "banjo", "banjo-kazooie", "cute", "indie", "collectathon")
    },
    @{
        Controls    = "VRGP"
        Title       = "Paranoia Place VR"
        SteamId     = "1592290"
        Mod         = "Paranoia_Place_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "ParanoiaPlaceVR\START_INSTALLER.bat"
        Color       = "#180a18"
        Accent      = "#9933cc"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1391728936039485450/1391728936039485450"
        ModFile     = "BepInEx\plugins\Paranoia_Place_VR.dll"
        SteamFolder = "Paranoia Place"
        FallbackPaths=@("STEAM:ParanoiaPlace", "STEAM:Paranoia Place Demo")
        Tags=@("paranoia place", "paranoiaplace", "astienth", "horror", "psychological", "atmospheric", "story", "indie")
    },
    @{ Controls="GP"; Title="Pragmata VR"; Quip="Hack the moon. Hold her hand. Step into the unknown."; SteamId="3357650"; PortraitUrl="Assets/Pragmata_portrait.jpg"; HeaderUrl="Assets/Pragmata_header.jpg"; Mod="REF (auto-updates)"; SteamFolder="PRAGMATA"; FallbackPaths=@("STEAM:PRAGMATA"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="Pragmata.exe"; Color="#0a0a1a"; Accent="#dd5544"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("pragmata", "reframework", "praydog", "action", "sci-fi"); ModFile="openxr_loader.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Road Redemption VR"
        SteamId     = "300380"
        Mod         = "RoadRedemption_VR v1.0.0"
        Description = "Steam store version required"
        Author      = "Astienth"
        Bat         = "RoadRedemptionVR\START_INSTALLER.bat"
        Color       = "#1a0808"
        Accent      = "#dd4422"
        InfoUrl     = "https://github.com/AstienVR/Road_Redemption_VR_bHaptics"
        ModFile     = "BepInEx\plugins\RoadRedemption_VR.dll"
        SteamFolder = "Road Redemption"
        FallbackPaths=@("STEAM:RoadRedemption", "STEAM:Road Redemption Demo")
        Tags=@("road redemption", "roadredemption", "astienth", "road rash", "racing", "combat", "motorcycle", "fighting", "indie")
    },
    @{ Controls="VRGP"; Title="Rogue Flight VR"; SteamId="2784620"; Mod="RogueFlight_VR v1.0.0"; SteamFolder="Rogue Flight"; FallbackPaths=@("STEAM:RogueFlight", "STEAM:ROGUE FLIGHT", "STEAM:ROGUE_FLIGHT", "STEAM:Rogue Flight Demo"); Description="Discord login required."; Author="Astienth"; Bat="RogueFlightVR\START_INSTALLER.bat"; Color="#080820"; Accent="#66ccff"; InfoUrl="https://discord.com/channels/1001138422972432597/1443945389454528634/1443945389454528634"; Tags=@("rogue flight", "rogueflight", "astienth", "anime", "manga", "shooter", "space", "bullet hell", "fast paced", "arcade", "indie"); ModFile="BepInEx\plugins\RogueFlight_VR.dll" },
    @{ Controls="GP"; Title="Sayonara Wild Hearts"; Pill="SAYONARAWH_VR"; SteamId="1122720"; Mod="SayonaraWH_VR v1.0.0"; SteamFolder="Sayonara Wild Hearts"; FallbackPaths=@("STEAM:SayonaraWildHearts", "GOG:Sayonara Wild Hearts", "EPIC:Sayonara Wild Hearts", "EPIC:SayonaraWildHearts"); Description="Discord login, depth + bHaptics"; Author="Astienth"; Bat="SayonaraWildHeartsVR\START_INSTALLER.bat"; Color="#180a18"; Accent="#cc44aa"; InfoUrl="https://discord.com/channels/1001138422972432597/1253317358735327354/1253317358735327354"; Tags=@("sayonara wild hearts", "sayonarawildhearts", "astienth", "simogo", "annapurna", "music", "rhythm", "arcade", "casual", "stylized", "indie", "lgbtq", "atmospheric", "bhaptics"); ModFile="BepInEx\plugins\UnityVRPlugin_SayonaraWildHearts.dll" },
    @{ Controls="GP"; Title="Skate Story VR"; SteamId="1263240"; Mod="SkateStory_VR v1.0.0"; SteamFolder="Skate Story"; FallbackPaths=@("STEAM:SkateStory", "STEAM:Skate Story Demo", "GOG:Skate Story"); Description="Discord login, OpenVR"; Author="Astienth"; Bat="SkateStoryVR\START_INSTALLER.bat"; Color="#1a0a18"; Accent="#dd3344"; InfoUrl="https://discord.com/channels/1001138422972432597/1454427736327065655/1454427809203359774"; Tags=@("skate story", "skatestory", "astienth", "skate", "skateboarding", "sports", "stylized", "indie", "narrative"); ModFile="VRMod\SkateStoryVR.dll" },
    @{ Controls="GP"; Title="Sonic P-06 VR"; SteamId=""; PortraitUrl="Assets/SonicP06_portrait.jpg"; HeaderUrl="Assets/SonicP06_header.jpg"; Mod="Sonic_P-06_VR v1.0.0"; SteamFolder="Sonic P-06 VR"; FallbackPaths=@("C:\Games\Sonic P-06 VR", "C:\Games\Sonic P06 VR", "C:\Games\SonicP06VR", "D:\Games\Sonic P-06 VR", "E:\Games\Sonic P-06 VR"); Description="Fan game, Discord login."; Author="Astienth"; Bat="SonicP06VR\START_INSTALLER.bat"; Color="#0a1018"; Accent="#3399ff"; InfoUrl="https://discord.com/channels/1001138422972432597/1267088216456953907/1316306250354524221"; Tags=@("sonic", "sonic 06", "sonic p-06", "sonicp06", "project 06", "chaosx", "astienth", "fan game", "platformer", "free", "action"); ModFile="BepInEx\plugins\UnityVRPlugin.dll"; LaunchExe="Sonic the Hedgehog.exe" },
    @{ Controls="GP"; Title="Spiderman 2 VR"; Quip="Two suits, one city. Swing through New York yourself."; SteamId="2651280";                  Mod="R.E.A.L."; SteamFolder="Marvel's Spider-Man 2"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#3a55cc"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, spider-man 2, marvel", "action", "open world", "story") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Spiderman Miles Morales VR"; Quip="Take the leap, Miles. Harlem's skyline is yours."; SteamId="1817190";      Mod="R.E.A.L."; SteamFolder="Marvel's Spider-Man Miles Morales"; Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa2266"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, spider-man, miles morales, marvel", "action", "open world", "story") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Spiderman Remastered"; Quip="With great power... swing across New York yourself."; SteamId="1817070";         Mod="R.E.A.L."; SteamFolder="Marvel's Spider-Man Remastered"; Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc2233"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, spider-man, spiderman, marvel", "action", "open world", "story") ; ModFile="RealRepo\RealVR64.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Star Fox 64 VR"
        SteamId     = ""
        PortraitUrl = "Assets/StarFox64_portrait.jpg"
        HeaderUrl   = "Assets/StarFox64_header.jpg"
        ScreenshotUrl = "Assets/StarFox64_screenshot.jpg"
        Quip        = "Do a barrel roll, Fox - the Lylat System is counting on you."
        Mod         = "Starship VR (auto-updates)"
        GithubRepo  = "RaYRoD-TV/StarFox64-VR"
        Description = "US (NTSC) .z64 ROM required"
        Author      = "RaYRoD"
        Bat         = "StarFox64VR\START_INSTALLER.bat"
        Color       = "#0a1428"
        Accent      = "#4a7fc0"
        InfoUrl     = "https://github.com/RaYRoD-TV/StarFox64-VR"
        DownloadUrl = "https://github.com/RaYRoD-TV/StarFox64-VR/releases/latest"
        ModFile     = "Starship.exe"
        LaunchExe   = "Starship.exe"
        StandaloneVR = $true
        SteamFolder = "Star Fox 64 VR"
        FallbackPaths=@("C:\Games\Star Fox 64 VR", "D:\Games\Star Fox 64 VR", "E:\Games\Star Fox 64 VR", "C:\games\Star Fox 64 VR")
        Tags=@("star fox 64", "starfox 64", "star fox", "starfox", "arwing", "fox mccloud", "nintendo", "rayrod", "starship", "shooter", "arcade", "space", "rail shooter", "sci-fi", "motion controls")
    },
    @{
        Controls    = "VRGP"
        Title       = "Star Racer VR"
        SteamId     = "2626120"
        Mod         = "StarRacer_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "StarRacerVR\START_INSTALLER.bat"
        Color       = "#180a28"
        Accent      = "#ffcc22"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1424109526621360240/1424109638558679142"
        ModFile     = "BepInEx\plugins\StarRacer_VR.dll"
        SteamFolder = "Star Racer"
        FallbackPaths=@("STEAM:StarRacer", "STEAM:Star Racer Demo")
        Tags=@("star racer", "starracer", "astienth", "f-zero", "fzero", "racing", "arcade", "retro", "sci-fi", "indie")
    },
    @{ Controls="GP"; Title="Star Wars Outlaws VR"; Quip="Scoundrel's life in a galaxy far, far away - up close."; SteamId="2842040";            Mod="R.E.A.L."; SteamFolder="Star Wars Outlaws"; FallbackPaths=@("EPIC:StarWarsOutlaws", "UBI:Star Wars Outlaws"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc8844"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, star wars, outlaws", "open world", "action", "sci-fi") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Starfield VR"; SteamId="1716740"; Mod="starfield2vr v2.0.0"; SteamFolder="Starfield"; FallbackPaths=@("XBOX:Starfield", "C:\XboxGames\Starfield\Content", "EPIC:Starfield"); Description="KB&M or Gamepad VR"; Author="mutars"; Bat="StarfieldVR\START_INSTALLER.bat"; Color="#0a1020"; Accent="#4488dd"; InfoUrl="https://github.com/mutars/starfield2vr"; Tags=@("starfield", "bethesda", "space", "fps", "open world", "rpg", "sci-fi", "shooter") ; ModFile="dxgi.dll" },
    @{ Controls="GP"; Title="Stray VR"; Quip="Be the cat. Knock things off ledges in the neon depths."; SteamId="1332010";                        Mod="R.E.A.L."; SteamFolder="Stray"; FallbackPaths=@("EPIC:Stray"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc8833"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, stray, cat", "adventure", "exploration", "cyberpunk") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Street Fighter 6 VR"; Quip="Round one. Fight! Throw hands face to face."; SteamId="1364780"; Mod="REF (auto-updates)"; SteamFolder="Street Fighter 6"; Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="SF6.exe"; Color="#1a0000"; Accent="#ff2200"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("street fighter 6", "reframework", "praydog", "action", "fast paced", "fighting", "arcade", "competitive"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="StreetDog BMX VR"; SteamId="2707870"; Mod="StreetDogBMX_VR v1.0.0"; SteamFolder="Street Dog BMX"; FallbackPaths=@("STEAM:StreetDogBMX", "STEAM:Streetdog BMX", "STEAM:StreetDog BMX", "STEAM:Street Dog BMX Demo"); Description="Discord login required."; Author="Astienth"; Bat="StreetDogBMXVR\START_INSTALLER.bat"; Color="#1a0a08"; Accent="#ff7744"; InfoUrl="https://discord.com/channels/1001138422972432597/1481693413479944417/1481693511601357072"; Tags=@("streetdog bmx", "streetdog", "street dog", "astienth", "racing", "sports", "fast paced", "indie", "bmx", "cartoon"); ModFile="BepInEx\plugins\StreetDogBMX_VR.dll" },
    @{ Controls="GP"; Title="Sunrise GP VR"; SteamId="2670800"; Mod="SunriseGP_VR v1.0.0"; SteamFolder="Sunrise GP"; FallbackPaths=@("STEAM:SunriseGP", "STEAM:Sunrise GP Demo"); Description="Discord login required."; Author="Astienth"; Bat="SunriseGPVR\START_INSTALLER.bat"; Color="#180a08"; Accent="#ffaa66"; InfoUrl="https://discord.com/channels/1001138422972432597/1362074365952528494/1362074365952528494"; Tags=@("sunrise gp", "sunrisegp", "astienth", "racing", "cell shading", "cel-shaded", "arcade", "indie", "cartoon"); ModFile="BepInEx\plugins\SunriseGP_VR.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Super Mario 64 VR"
        SteamId     = ""
        PortraitUrl = "Assets/SuperMario64_portrait.jpg"
        HeaderUrl   = "Assets/SuperMario64_header.jpg"
        ScreenshotUrl = "Assets/SuperMario64_screenshot.jpg"
        Quip        = "Wahoo! Grab your cap and go bag every last star."
        Mod         = "sm64coopdx VR (auto-updates)"
        GithubRepo  = "RaYRoD-TV/sm64coopdx-vr"
        Description = "US (NTSC) .z64 ROM required"
        Author      = "RaYRoD"
        Bat         = "SuperMario64VR\START_INSTALLER.bat"
        Color       = "#0f2444"
        Accent      = "#e63b2e"
        InfoUrl     = "https://github.com/RaYRoD-TV/sm64coopdx-vr"
        DownloadUrl = "https://github.com/RaYRoD-TV/sm64coopdx-vr/releases/latest"
        ModFile     = "sm64coopdx.exe"
        LaunchExe   = "sm64coopdx.exe"
        StandaloneVR = $true
        SteamFolder = "Super Mario Coop VR"
        FallbackPaths=@("C:\Games\Super Mario Coop VR", "D:\Games\Super Mario Coop VR", "E:\Games\Super Mario Coop VR", "C:\games\Super Mario Coop VR")
        Tags=@("super mario 64", "sm64", "mario", "coopdx", "coop deluxe", "nintendo", "rayrod", "platformer", "coop", "adventure", "retro", "3d platformer", "motion controls")
    },
    @{ Controls="VRGP"; Title="Super Polygon Grand Prix VR"; Pill="SPGP_VR"; SteamId="2459860"; Mod="SPGP_VR_1.0"; SteamFolder="SP-GP Super Polygon Grand Prix"; FallbackPaths=@("STEAM:Super Polygon Grand Prix", "STEAM:SuperPolygonGrandPrix", "STEAM:SPGP", "STEAM:SP-GP Super Polygon Grand Prix Demo"); Description="Discord login required."; Author="Astienth"; Bat="SuperPolygonGrandPrixVR\START_INSTALLER.bat"; Color="#0a0a18"; Accent="#5588ff"; InfoUrl="https://discord.com/channels/1001138422972432597/1492448070862901308/1492448247090778173"; Tags=@("super polygon grand prix", "spgp", "spgp_vr", "astienth", "racing", "sports", "fast paced", "indie", "arcade", "virtua racing"); ModFile="BepInEx\plugins\SPGP_VR.dll" },
    @{ Controls="GP"; Title="The Dark Mod VR"; Mod="thedarkmodvr"; Description="Thief-like stealth, gamepad."; Author="Holger Frydrych"; Bat="TheDarkModVR\START_INSTALLER.bat"; Color="#0e0b07"; Accent="#c9a227"; InfoUrl="https://github.com/fholger/thedarkmodvr/wiki/Installation"; ModPageUrl="https://github.com/fholger/thedarkmodvr"; SupportUrl="https://ko-fi.com/fholger"; SupportText="fholger maintains these PC VR mods. If you enjoy them, consider supporting him:"; Quip="Stay to the shadows, taffer - the City has gone three-dimensional."; PortraitUrl="Assets/TheDarkModVR_portrait.png"; HeaderUrl="Assets/TheDarkModVR_header.png"; ScreenshotUrl="Assets/TheDarkModVR_screenshot.jpg"; LaunchExe="TheDarkModVRx64.exe"; ModFile="TheDarkModVRx64.exe"; SteamFolder="The Dark Mod VR"; FallbackPaths=@("C:\Games\The Dark Mod VR", "D:\Games\The Dark Mod VR", "E:\Games\The Dark Mod VR"); Tags=@("the dark mod", "dark mod", "darkmod", "tdm", "thief", "stealth", "frydrych", "fholger", "free", "open source", "gothic", "steampunk", "action", "adventure", "horror") },
    @{ Controls="GP"; Title="Tinykin VR"; SteamId="1599020"; Mod="TinykinVR v1.0.0"; SteamFolder="Tinykin"; FallbackPaths=@("STEAM:Tinykin Demo", "STEAM:TinykinDemo", "GOG:Tinykin"); Description="Discord login, depth only"; Author="Astienth"; Bat="TinykinVR\START_INSTALLER.bat"; Color="#0f180a"; Accent="#ff7733"; InfoUrl="https://discord.com/channels/1001138422972432597/1276919154678693908/1276919154678693908"; Tags=@("tinykin", "astienth", "tinybuild", "platformer", "3d platformer", "puzzle", "collectathon", "cute", "cartoon", "stylized", "indie", "story", "exploration", "depth"); ModFile="BepInEx\plugins\TinykinVR.dll" },
    @{ Controls="GP"; Title="TLOU Part I VR"; Quip="Joel and Ellie's road through a cordyceps America."; SteamId="1888930";                  Mod="R.E.A.L."; SteamFolder="The Last of Us Part I"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#5a7a3a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, last of us, tlou", "action", "survival", "story") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="TLOU Part II VR"; Quip="The cycle of revenge, told at arm's length. Brace yourself."; SteamId="2531310";                 Mod="R.E.A.L."; SteamFolder="The Last of Us Part II Remastered"; FallbackPaths=@("STEAM:The Last of Us Part II"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#3a6a3a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, last of us, tlou", "action", "survival", "story") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Uncharted: Legacy of Thieves VR"; Quip="Sic parvis magna. Nate's last climbs, life-size."; SteamId="1659420"; Mod="R.E.A.L."; SteamFolder="Uncharted Legacy of Thieves Collection"; FallbackPaths=@("EPIC:UnchartedLegacyOfThievesCollection", "EPIC:Uncharted Legacy of Thieves Collection"); Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#8a6a2a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, uncharted", "action", "adventure", "story") ; ModFile="RealRepo\RealVR64.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Unmourned VR"
        SteamId     = "3528970"
        Mod         = "Unmourned_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "UnmournedVR\START_INSTALLER.bat"
        Color       = "#180808"
        Accent      = "#cc3333"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1462781954570059990/1462781954570059990"
        ModFile     = "BepInEx\plugins\Unmourned_VR.dll"
        SteamFolder = "Unmourned"
        FallbackPaths=@("STEAM:Unmourned Demo")
        LaunchExe   = "Unmourned.exe"
        Tags=@("unmourned", "astienth", "horror", "story", "narrative", "atmospheric", "visage")
    },
    @{ Controls="GP"; Title="Watch Dogs VR"; Quip="Hack Chicago from the inside. The city's in your palm."; SteamId="243470"; PortraitUrl="Assets/WatchDogs1_portrait.jpg"; Mod="R.E.A.L."; SteamFolder="Watch_Dogs"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#3a7aaa"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, watch dogs", "open world", "hacking", "action") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Watch Dogs 2 VR"; Quip="DedSec needs you, Marcus. Hack all of San Francisco."; SteamId="447040";                 Mod="R.E.A.L."; SteamFolder="Watch_Dogs2"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#33aa6a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, watch dogs", "open world", "hacking", "action") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Watch Dogs Legion VR"; Quip="Recruit anyone. Take back a near-future London."; SteamId="2239550";            Mod="R.E.A.L."; SteamFolder="Watch Dogs Legion"; FallbackPaths=@("STEAM:WatchDogs_Legion"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc4488"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, watch dogs", "open world", "hacking", "sandbox") ; ModFile="RealRepo\RealVR64.dll" },
    @{ Controls="GP"; Title="Yooka-Laylee VR"; SteamId="360830"; Mod="VookaRaylee v0.3"; SteamFolder="YookaLaylee"; FallbackPaths=@("C:\Games\Yooka-Laylee VR", "STEAM_CONTENT\YookaLaylee-VR", "GOG:Yooka-Laylee"); DepotInstall=$true; DualMode=$true; DepotPath="C:\Games\Yooka-Laylee VR"; DepotLaunchExe="YookaLaylee64.exe"; DepotLaunchArgs=""; Description="Optional Steam depot version."; Author="Eusth"; Bat="YookaLayleeVR\START_INSTALLER.bat"; Color="#0a1a10"; Accent="#44cc88"; InfoUrl="https://github.com/Eusth/VookaRaylee"; Tags=@("yooka", "laylee", "vooka", "raylee", "platformer", "collectathon", "cartoon") ; ModFile="IPA.exe"; LaunchExe="YookaLaylee64.exe" }
)

# -------------------------------------------------------
# External installers - alphabetical (HL episodes under Half-Life)
# -------------------------------------------------------
$externalGames = @(
    @{
        Controls    = "MC"
        Title       = "Crysis VR"
        Quip        = "Maximum armor. Maximum immersion. Welcome to the island."
        SteamId     = "17300"
        Mod         = "Crysis VR Mod v1.1.1"
        Description = "by fholger"
        Author      = "fholger"
        SupportUrl  = "https://ko-fi.com/fholger"
        SupportText = "fholger maintains these PC VR mods. If you enjoy them, consider supporting him:"
        Url         = "https://github.com/fholger/crysis_vrmod"
        DownloadUrl = "https://api.github.com/repos/fholger/crysis_vrmod/releases/latest"
        Color       = "#0a1a0a"
        Accent      = "#00cc44"
        Type        = "external"
        ReadmeDir   = "CrysisVR"
        InfoUrl     = "https://github.com/fholger/crysis_vrmod"
        SteamFolder = "Crysis"
        FallbackPaths=@("GOG:Crysis", "GOG:Crysis Remastered", "EPIC:Crysis Remastered")
        ModFile     = "Bin64\CrysisVR.exe"
        Tags        = @("crysis", "fps", "action", "sci-fi")
    },
    @{
        Controls    = "BOTH"
        Title       = "Dolphin VR + ReduX"
        Quip        = "GameCube and Wii classics, reborn in stereoscopic 3D."
        ReadmeDir   = "DolphinVR"
        Mod         = "GameCube/Wii VR Emulator"
        Author      = "Dolphin VR team + iChris4"
        Description = "Discord login required"
        Url         = "https://discord.com/invite/GdmffzCTrh"
        DownloadUrl = "https://dolphinvr.wordpress.com/downloads/"
        # InfoUrl drives the "Install Mod" button -> downloads page.
        # ModPageUrl drives the "Mod Page" button -> Discord invite
        # (where the actual ReduX builds + community live).
        InfoUrl     = "https://dolphinvr.wordpress.com/downloads/"
        ModPageUrl  = "https://discord.com/invite/GdmffzCTrh"
        # No Steam page - bundled local images (Assets folder).
        PortraitUrl = "Assets/DolphinVR_portrait.jpg"
        HeaderUrl   = "Assets/DolphinVR_header.jpg"
        Color       = "#0a1424"
        Accent      = "#1a8cff"
        Type        = "external"
        Tags        = @("dolphin", "emulator", "gamecube", "wii", "nintendo", "redux", "xr", "platformer", "3d platformer", "collectathon", "cartoon", "adventure")
    },
    @{
        Controls    = "MC"
        Title       = "Far Cry VR"
        Quip        = "The island remembers. Now you're really on it."
        SteamId     = "13520"
        # 2004 title - Steam library_600x900 doesn't exist and the
        # default header.jpg is barely usable. Bundle both.
        PortraitUrl = "Assets/FarCry1_portrait.jpg"
        HeaderUrl   = "Assets/FarCry1_header.jpg"
        Mod         = "Far Cry VR Mod v1.1.0"
        Description = "by fholger"
        Author      = "fholger"
        SupportUrl  = "https://ko-fi.com/fholger"
        SupportText = "fholger maintains these PC VR mods. If you enjoy them, consider supporting him:"
        Url         = "https://github.com/fholger/farcry_vrmod"
        DownloadUrl = "https://api.github.com/repos/fholger/farcry_vrmod/releases/latest"
        InfoUrl     = "https://github.com/fholger/farcry_vrmod"
        Color       = "#2a1500"
        Accent      = "#ff9900"
        Type        = "external"
        ReadmeDir   = "FarCryVR"
        ModFile     = "FarCryVR.exe"
        SteamFolder = "FarCry"
        FallbackPaths=@("GOG:Far Cry", "UBI:Far Cry")
        Tags        = @("far cry", "farcry", "fps", "action", "tropical")
    },
    @{
        Controls    = "MC"
        Title       = "Fallout 4 VR"
        Pill        = "Wabbajack"
        SteamId     = "611660"
        Mod         = "Wabbajack Modlists"
        Description = "Essentials + London VR"
        Author      = "Wabbajack community"
        ImprovementTag = "+ VR improvement"
        Color       = "#2a1a0a"
        Accent      = "#8a72d8"
        Type        = "external"
        WabbajackUrl = "https://www.wabbajack.org/"
        InfoUrl     = "https://www.nexusmods.com/fallout4/mods/96013"
        ModButtons  = @(
            @{ Label = "VR Essentials"; Url = "https://www.nexusmods.com/fallout4/mods/96013" },
            @{ Label = "London VR";     Url = "https://www.nexusmods.com/fallout4london/mods/747" }
        )
        ReadmeDir   = "Fallout4VRWabbajack"
        SteamFolder = "Fallout 4 VR"
        Tags = @("fallout", "fallout 4", "fo4", "fo4vr", "wabbajack", "modlist", "essentials", "fallout london", "london", "fps", "rpg", "post-apocalyptic", "bethesda")
    },
    @{
        Controls    = "MC"
        Title       = "Firewatch VR"
        Pill        = "TwoForks_VR"
        Quip        = "Just you, a radio, and a Wyoming summer. Look alive, Henry."
        SteamId     = "383870"
        Mod         = "Two Forks VR v2.1.0"
        Description = "by Raicuparta on itch.io"
        Author      = "Raicuparta"
        SupportUrl  = "https://www.patreon.com/c/raivr/home"
        SupportText = "Raicuparta develops these VR mods. If you enjoy their work, consider supporting them:"
        Url         = "https://raicuparta.itch.io/two-forks-vr"
        ReadmeDir   = "FirewatchVR"
        InfoUrl     = "https://raicuparta.itch.io/two-forks-vr"
        Color       = "#2a1a00"
        Accent      = "#ff6600"
        Type        = "itch"
        SteamFolder = "Firewatch"
        ModFile     = "BepInEx\plugins\TwoForksVr.dll"
        LaunchExe   = "Firewatch.exe"
        FallbackPaths=@("GOG:Firewatch", "EPIC:Firewatch", "C:\Program Files\WindowsApps\CampoSanto.Firewatch_*_x64__1traspxf3h47a")
        Tags        = @("two forks vr", "fire watch", "adventure", "narrative", "exploration")
    },
    @{
        Controls    = "GP"
        Title       = "Freespace 2 VR"
        Quip        = "Subspace tears open, the Shivans return - the cockpit is yours."
        ReadmeDir   = "Freespace2VR"
        SteamId     = "273620"
        SteamFolder = "Freespace 2"
        # The VR-Ready signal is Knossos.NET itself (it runs a standalone,
        # VR-native library); the base FS2.exe only means the game is
        # present. So we detect Knossos.NET.exe in its default install
        # folder (%LocalAppData%\Knossos.NET). SteamFolder above only
        # passes the scan gate and drives the Steam button/images. If
        # Knossos lives elsewhere the user can point the Hub at it with
        # "Locate Game".
        FallbackPaths = @("$env:LOCALAPPDATA\Knossos.NET")
        Mod         = "FreeSpace Open"
        Description = "Set up via Knossos"
        Author      = "FreeSpace Open / Knossos"
        InfoUrl     = "https://github.com/KnossosNET/Knossos.NET"
        DownloadUrl = "https://github.com/KnossosNET/Knossos.NET/releases/latest"
        Url         = "https://github.com/KnossosNET/Knossos.NET"
        ModPageUrl  = "https://github.com/KnossosNET/Knossos.NET"
        Color       = "#0a1424"
        Accent      = "#3fa9d6"
        Type        = "external"
        ModFile     = "Knossos.NET.exe"
        # Start in VR launches Knossos.NET (resolved from the same
        # %LocalAppData%\Knossos.NET folder the scan detects), NOT
        # steam://273620 which would start the flat retail FreeSpace 2.
        LaunchExe   = "Knossos.NET.exe"
        Tags        = @("freespace 2", "freespace", "fs2", "knossos", "freespace open", "space", "space combat", "flight", "shooter", "sim", "simulation", "scifi")
    },
    @{
        Controls    = "MC"
        Title       = "Half-Life VR"
        Pill        = "HLVR"
        SteamId     = "1908720"
        ReadmeDir   = "HalfLifeVR"
        Mod         = "Standalone Mod on Steam"
        Description = "Owning Half-Life is required."
        Author      = "Max Vollmer"
        SupportUrl  = "https://ko-fi.com/maxmakesmods"
        SupportText = "Max Vollmer (Max Makes Mods) develops Half-Life VR. If you enjoy it, consider supporting him:"
        Url         = "https://store.steampowered.com/app/1908720/HalfLife_VR_Mod/"
        InfoUrl     = "https://store.steampowered.com/app/1908720/HalfLife_VR_Mod/"
        Color       = "#1a1a0a"
        Accent      = "#ff6600"
        Type        = "steam"
        SteamFolder = "Half-Life VR Mod"
        ModFile     = "HLVRConfig.exe"
        Tags=@("half-life", "hl1", "half life vr", "fps", "shooter", "story")
    },
    @{
        Controls    = "MC"
        Title       = "Half-Life 2 VR"
        SteamId     = "658920"
        ReadmeDir   = "HalfLife2VR"
        Mod         = "HL2VR Mod"
        Description = "Owning HL2 is required."
        Author      = "fholger"
        SupportUrl  = "https://ko-fi.com/fholger"
        SupportText = "fholger maintains these PC VR mods. If you enjoy them, consider supporting him:"
        Url         = "https://store.steampowered.com/app/658920/"
        InfoUrl     = "https://store.steampowered.com/app/658920/"
        ModPageUrl  = "https://halflife2vr.com/manual/"
        Color       = "#2a1a0a"
        Accent      = "#ff8c00"
        Type        = "steam"
        SteamFolder = "Half-Life 2 VR"
        ModFile     = "hl2vr.exe"
        AddonInstaller  = "HL2VRU\HL2VRU-core.ps1"
        AddonName       = "Unleashed"
        AddonMod        = "HL2VRU v0.0.7"
        AddonAuthor     = "Vittorio Romeo"
        AddonInfoUrl    = "https://github.com/vittorioromeo/HL2VRU"
        AddonSupportUrl = "https://ko-fi.com/vittorioromeo"
        Tags        = @("half life", "hl", "hl2", "fps", "story", "sci-fi")
    },
    @{
        Controls    = "MC"
        Title       = "HL2 VR Ep. One"
        SteamId     = "2177750"
        ReadmeDir   = "HL2VREpOne"
        Mod         = "HL2VR Episode One"
        Description = "Owning HL2 Ep.1 is required."
        Author      = "fholger"
        SupportUrl  = "https://ko-fi.com/fholger"
        SupportText = "fholger maintains these PC VR mods. If you enjoy them, consider supporting him:"
        Url         = "https://store.steampowered.com/app/2177750/"
        InfoUrl     = "https://store.steampowered.com/app/2177750/"
        Color       = "#2a1a0a"
        Accent      = "#ff8c00"
        Type        = "steam"
        SteamFolder = "Half-Life 2 VR"
        ModFile     = "ep1vr.exe"
        AddonInstaller  = "HL2VRU\HL2VRU-core.ps1"
        AddonName       = "Unleashed"
        AddonMod        = "HL2VRU v0.0.7"
        AddonAuthor     = "Vittorio Romeo"
        AddonInfoUrl    = "https://github.com/vittorioromeo/HL2VRU"
        AddonSupportUrl = "https://ko-fi.com/vittorioromeo"
        Tags=@("half life", "half-life", "hl", "hl2", "episode one", "ep1", "fps", "shooter", "story")
    },
    @{
        Controls    = "MC"
        Title       = "HL2 VR Ep. Two"
        SteamId     = "2177760"
        ReadmeDir   = "HL2VREpTwo"
        Mod         = "HL2VR Episode Two"
        Description = "Owning HL2 Ep.2 is required."
        Author      = "fholger"
        SupportUrl  = "https://ko-fi.com/fholger"
        SupportText = "fholger maintains these PC VR mods. If you enjoy them, consider supporting him:"
        Url         = "https://store.steampowered.com/app/2177760/"
        InfoUrl     = "https://store.steampowered.com/app/2177760/"
        Color       = "#2a1a0a"
        Accent      = "#ff8c00"
        Type        = "steam"
        SteamFolder = "Half-Life 2 VR"
        ModFile     = "ep2vr.exe"
        AddonInstaller  = "HL2VRU\HL2VRU-core.ps1"
        AddonName       = "Unleashed"
        AddonMod        = "HL2VRU v0.0.7"
        AddonAuthor     = "Vittorio Romeo"
        AddonInfoUrl    = "https://github.com/vittorioromeo/HL2VRU"
        AddonSupportUrl = "https://ko-fi.com/vittorioromeo"
        Tags=@("half life", "half-life", "hl", "hl2", "episode two", "ep2", "fps", "shooter", "story")
    },
    @{
        Controls    = "MC"
        Title       = "Halo CE VR"
        Quip        = "Reclaimer, the ring is yours to walk. Finish the fight in VR."
        # Targets the original 2003 retail PC Halo: Combat Evolved only -
        # it was never on Steam, so this entry has no SteamId. Bundled art
        # and a local Game Info entry cover the card and detail view.
        PortraitUrl = "Assets/HaloCE_portrait.jpg"
        HeaderUrl   = "Assets/HaloCE_header.jpg"
        ScreenshotUrl = "Assets/HaloCE_screenshot.jpg"
        ReadmeDir   = "HaloCEVR"
        Mod         = "HALOCEVR Installer"
        Description = "by LivingFray"
        Author      = "LivingFray"
        Color       = "#0a1a2a"
        Accent      = "#00aaff"
        Type        = "external"
        InfoUrl     = "https://elliewasteland.github.io/HALOCEVR-Installer/"
        Url         = "https://elliewasteland.github.io/HALOCEVR-Installer/"
        ModPageUrl  = "https://github.com/LivingFray/HaloCEVR"
        Tags        = @("halo", "ce", "combat evolved", "fps", "sci-fi", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Jedi Knight: Jedi Academy VR"
        Quip        = "Build your saber. Choose your path. The Force is yours."
        ReadmeDir   = "JediAcademyVR"
        SteamId     = "6020"
        # Bundled portrait - Steam library art for this 2003 title
        # is missing. Header falls back to Steam header.jpg.
        PortraitUrl = "Assets/JediAcademy_portrait.jpg"
        Mod         = "JKXR v1.1.28"
        Description = "Full VR port, motion controls."
        Author      = "Team Beef Studios"
        SupportUrl  = "https://www.patreon.com/c/teambeef/posts"
        SupportText = "Team Beef develops these VR ports. If you enjoy their work, consider supporting them:"
        DirectDownload = "https://github.com/Team-Beef-Studios/JKXR/releases/download/v1.1.28/JKXR_JKA_Setup.exe"
        Color       = "#0a0a1a"
        Accent      = "#4488ff"
        InfoUrl     = "https://github.com/Team-Beef-Studios/JKXR"
        ShowInfo    = $true
        ModFile     = "GameData\TeamBeefVR.bat"
        SteamFolder = "Jedi Academy"
        FallbackPaths=@("GOG:Star Wars Jedi Knight Jedi Academy", "GOG:Jedi Academy")
        Tags        = @("jedi knight", "jedi academy", "jkxr", "star wars", "action", "lightsaber", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Jedi Knight: Jedi Outcast VR"
        Quip        = "Kyle Katarn returns. The lightsaber feels different in hand."
        ReadmeDir   = "JediOutcastVR"
        SteamId     = "6030"
        # Both portrait and header are bundled - the 2002 title's
        # Steam library art is often missing or low quality.
        PortraitUrl = "Assets/JediOutcast_portrait.jpg"
        HeaderUrl   = "Assets/JediOutcast_header.jpg"
        Mod         = "JKXR v1.1.28"
        Description = "Full VR port, motion controls."
        Author      = "Team Beef Studios"
        SupportUrl  = "https://www.patreon.com/c/teambeef/posts"
        SupportText = "Team Beef develops these VR ports. If you enjoy their work, consider supporting them:"
        DirectDownload = "https://github.com/Team-Beef-Studios/JKXR/releases/download/v1.1.28/JKXR_JKO_Setup.exe"
        Color       = "#0a0a1a"
        Accent      = "#4488ff"
        InfoUrl     = "https://github.com/Team-Beef-Studios/JKXR"
        ShowInfo    = $true
        ModFile     = "GameData\TeamBeefVR.bat"
        SteamFolder = "Jedi Outcast"
        FallbackPaths=@("GOG:Star Wars Jedi Knight II Jedi Outcast", "GOG:Jedi Outcast")
        Tags        = @("jedi knight", "jedi outcast", "jkxr", "star wars", "action", "lightsaber", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Morrowind VR"
        Quip        = "Stand on the ashlands of Vvardenfell. N'wah, welcome."
        SteamId     = "22320"
        ReadmeDir   = "MorrowindVR"
        Mod         = "OpenMW-VR"
        Description = "by madsbuvi on GitHub"
        Author      = "madsbuvi"
        Url         = "https://github.com/madsbuvi/openmw/releases"
        Color       = "#1a1400"
        Accent      = "#7a6a3a"
        Type        = "external"
        InfoUrl     = "https://github.com/madsbuvi/openmw/releases"
        ModPageUrl  = "https://openmw-vr.readthedocs.io/en/latest/manuals/openmw-vr/"
        DownloadUrl = "https://api.github.com/repos/madsbuvi/openmw/releases"
        SteamFolder = "Morrowind"
        FallbackPaths=@("GOG:The Elder Scrolls III Morrowind GOTY", "GOG:Morrowind")
        Tags        = @("morrowind", "openmw", "elder scrolls", "rpg", "open world", "fantasy")
    },
    @{
        Controls    = "MC"
        Title       = "Neon White VR"
        Quip        = "Heaven runs on speed. Card the demons, beat the clock."
        SteamId     = "1533420"
        Mod         = "Heaven VR v23"
        Description = "by Raicuparta on itch.io"
        Author      = "Raicuparta"
        SupportUrl  = "https://www.patreon.com/c/raivr/home"
        SupportText = "Raicuparta develops these VR mods. If you enjoy their work, consider supporting them:"
        Url         = "https://raicuparta.itch.io/heaven-vr"
        ReadmeDir   = "NeonWhiteVR"
        InfoUrl     = "https://raicuparta.itch.io/heaven-vr"
        Color       = "#1a1a2e"
        Accent      = "#cc44ff"
        Type        = "itch"
        SteamFolder = "Neon White"
        ModFile     = "BepInEx\plugins\HeavenVr\com.raicuparta.heaven-vr.dll"
        LaunchExe   = "Neon White.exe"
        FallbackPaths=@("EPIC:Neon White", "EPIC:NeonWhite", "C:\Program Files\WindowsApps\AnnapurnaInteractive.NeonWhite_*_x64__c96c51jf6wkvm")
        Tags        = @("heaven vr", "neon", "fps", "platformer", "speedrun")
    },
    @{
        Controls    = "GP"
        Title       = "Nuclear Option VR"
        Quip        = "Arm the payload, bank hard, and rule the contested skies."
        SteamId     = "2168680"
        Mod         = "NOVR Installer"
        Description = "by InfernoSuperNova"
        Author      = "InfernoSuperNova"
        Url         = "https://github.com/InfernoSuperNova/novr"
        DownloadUrl = "https://github.com/InfernoSuperNova/novr/releases/latest"
        Color       = "#1a1205"
        Accent      = "#f0a830"
        Type        = "external"
        InfoUrl     = "https://github.com/InfernoSuperNova/novr"
        SteamFolder = "Nuclear Option"
        ModFile     = "BepInEx\plugins\NOVR\NOVR.dll"
        ReadmeDir   = "NuclearOptionVR"
        Tags        = @("nuclear option", "novr", "flight", "combat", "jets", "military", "action", "uuvr", "unity", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Portal 2: Community Edition VR"
        Quip        = "Bend space, chain the momentum, and lean into every test chamber."
        SteamId     = "440000"
        Mod         = "P2:CE"
        Description = "You must own Portal 2"
        Author      = "StrataSource"
        Url         = "https://store.steampowered.com/app/440000/Portal_2_Community_Edition/"
        InfoUrl     = "https://store.steampowered.com/app/440000/Portal_2_Community_Edition/"
        Color       = "#0a1622"
        Accent      = "#4aa3e0"
        Type        = "steam"
        SteamFolder = "Portal 2 Community Edition"
        ModFile     = "bin\win64\p2ce.exe"
        ReadmeDir   = "Portal2CEVR"
        Tags        = @("portal 2", "portal", "community edition", "p2ce", "puzzle", "physics", "first-person", "source", "valve")
    },
    @{
        Controls    = "MC"
        Title       = "Receiver 2 VR"
        Quip        = "Every chamber, every spring, every round - now in your hands."
        SteamId     = "1129310"
        Mod         = "VR Release Candidate"
        Description = "Official Steam VR beta branch"
        Author      = "Wolfire Games"
        Type        = "external"
        ButtonLabel = "Set Beta"
        HideModPageButton = $true
        ReadmeDir   = "Receiver2VR"
        DownloadUrl = "steam://gameproperties/1129310"
        InfoUrl     = "https://store.steampowered.com/app/1129310/Receiver_2/"
        Color       = "#0c0e10"
        Accent      = "#6f8fa6"
        SteamFolder = "Receiver 2"
        ModFile     = "Receiver2_Data\StreamingAssets\SteamVR\actions.json"
        FallbackPaths=@("STEAM:Receiver 2")
        Tags        = @("receiver 2", "receiver2", "wolfire", "shooter", "fps", "survival", "simulation", "guns", "beta branch", "vr_release_candidate")
    },
    @{
        Controls    = "MC"
        Title       = "Resident Evil 2R VR"
        Quip        = "Raccoon City has fallen. Reach for every bullet yourself."
        ReadmeDir   = "ResidentEvil2RVR"
        SteamId     = "883710"
        InfoUrl     = "https://www.biohazardvr.com/re2"
        Mod         = "REFramework VR"
        Description = "by praydog"
        Author      = "praydog"
        SupportUrl  = "https://www.patreon.com/c/praydog"
        SupportText = "praydog develops REFramework. If you enjoy his work, consider supporting him:"
        Url         = "https://mrsurvivor-installers.com/"
        Color       = "#1e2a22"
        Accent      = "#7a1a1a"
        Type        = "external"
        ModFile     = "dinput8.dll"
        SteamFolder = "RESIDENT EVIL 2  BIOHAZARD RE2"
        FallbackPaths=@("EPIC:Resident Evil 2", "STEAM:RESIDENT EVIL 2 (BIOHAZARD RE2)")
        Tags        = @("re2", "resident", "resident evil", "horror", "survival", "zombies")
    },
    @{
        Controls    = "MC"
        Title       = "Resident Evil 3R VR"
        Quip        = "Nemesis is hunting. There's no camera angle to hide behind now."
        ReadmeDir   = "ResidentEvil3RVR"
        SteamId     = "952060"
        InfoUrl     = "https://www.biohazardvr.com/re3"
        Mod         = "REFramework VR"
        Description = "by praydog"
        Author      = "praydog"
        SupportUrl  = "https://www.patreon.com/c/praydog"
        SupportText = "praydog develops REFramework. If you enjoy his work, consider supporting him:"
        Url         = "https://mrsurvivor-installers.com/"
        Color       = "#1e2a22"
        Accent      = "#7a1a1a"
        Type        = "external"
        ModFile     = "dinput8.dll"
        SteamFolder = "RESIDENT EVIL 3 BIOHAZARD RE3"
        FallbackPaths=@("EPIC:Resident Evil 3", "STEAM:RESIDENT EVIL 3")
        Tags        = @("re3", "resident", "resident evil", "horror", "survival", "action")
    },
    @{
        Controls    = "MC"
        Title       = "Resident Evil 4R VR"
        Quip        = "No straight answers, stranger. Just you, Leon, and the village."
        ReadmeDir   = "ResidentEvil4RVR"
        SteamId     = "2050650"
        InfoUrl     = "https://www.biohazardvr.com/re4"
        Mod         = "REFramework VR + Motion"
        Description = "by praydog + Talemann"
        Author      = "praydog + Talemann"
        SupportUrl  = "https://www.patreon.com/c/praydog"
        SupportText = "praydog develops REFramework. If you enjoy his work, consider supporting him:"
        Url         = "https://mrsurvivor-installers.com/"
        Color       = "#1e2a22"
        Accent      = "#7a1a1a"
        Type        = "external"
        ModFile     = "dinput8.dll"
        SteamFolder = "RESIDENT EVIL 4  BIOHAZARD RE4"
        FallbackPaths=@("EPIC:Resident Evil 4", "STEAM:RESIDENT EVIL 4")
        Tags        = @("re4", "resident", "resident evil", "action", "horror", "shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Resident Evil 7 VR"
        Quip        = "Welcome to the family. Try to keep your hands steady."
        ReadmeDir   = "ResidentEvil7VR"
        SteamId     = "418370"
        InfoUrl     = "https://www.biohazardvr.com/re7"
        Mod         = "REFramework VR"
        Description = "by praydog"
        Author      = "praydog"
        SupportUrl  = "https://www.patreon.com/c/praydog"
        SupportText = "praydog develops REFramework. If you enjoy his work, consider supporting him:"
        Url         = "https://mrsurvivor-installers.com/"
        Color       = "#1e2a22"
        Accent      = "#7a1a1a"
        Type        = "external"
        ModFile     = "dinput8.dll"
        SteamFolder = "RESIDENT EVIL 7 Biohazard"
        FallbackPaths=@("EPIC:Resident Evil 7 - Biohazard")
        Tags        = @("re7", "resident", "resident evil", "biohazard", "horror", "survival", "first-person")
    },
    @{
        Controls    = "MC"
        Title       = "RE Village VR"
        Quip        = "Tall lady, taller stakes. Hold the line, Ethan."
        ReadmeDir   = "REVillageVR"
        SteamId     = "1196590"
        InfoUrl     = "https://www.biohazardvr.com/re8"
        Mod         = "REFramework VR"
        Description = "by praydog"
        Author      = "praydog"
        SupportUrl  = "https://www.patreon.com/c/praydog"
        SupportText = "praydog develops REFramework. If you enjoy his work, consider supporting him:"
        Url         = "https://mrsurvivor-installers.com/"
        Color       = "#1e2a22"
        Accent      = "#7a1a1a"
        Type        = "external"
        ModFile     = "dinput8.dll"
        SteamFolder = "Resident Evil Village BIOHAZARD VILLAGE"
        FallbackPaths=@("EPIC:Resident Evil Village", "STEAM:Resident Evil Village (BIOHAZARD VILLAGE)")
        Tags        = @("re8", "resident", "resident evil", "village", "horror", "survival", "action")
    },
    @{
        Controls    = "MC"
        Title       = "RE Requiem VR"
        Quip        = "Raccoon City's ashes, close enough to touch."
        ReadmeDir   = "RERequiemVR"
        SteamId     = "3764200"
        SteamFolder = "RESIDENT EVIL requiem BIOHAZARD requiem"
        FallbackPaths=@("STEAM:RESIDENT EVIL requiem BIOHAZARD requiem")
        # Steam doesn't ship library_600x900 or a great header.jpg
        # for this 2026 release yet, so both are bundled.
        PortraitUrl = "Assets/RE_Requiem_portrait.jpg"
        HeaderUrl   = "Assets/RE_Requiem_header.jpg"
        InfoUrl     = "https://www.biohazardvr.com/re9"
        Mod         = "REFramework VR + Motion"
        Description = "by praydog + Talemann"
        Author      = "praydog + Talemann"
        SupportUrl  = "https://www.patreon.com/c/praydog"
        SupportText = "praydog develops REFramework. If you enjoy his work, consider supporting him:"
        Url         = "https://mrsurvivor-installers.com/"
        Color       = "#1e2a22"
        Accent      = "#7a1a1a"
        Type        = "external"
        ModFile     = "dinput8.dll"
        Tags        = @("re9", "resident", "resident evil", "requiem", "horror", "survival", "action")
    },
    @{
        Controls    = "GP"
        Title       = "Shipbreaker VR"
        Quip        = "Strip the hull, bank the salvage, mind the debt - just another shift in the yard."
        SteamId     = "1161580"
        Mod         = "Shipbreaker VR v1"
        Description = "by Raicuparta on itch.io"
        Author      = "Raicuparta"
        SupportUrl  = "https://www.patreon.com/c/raivr/home"
        SupportText = "Raicuparta develops these VR mods. If you enjoy their work, consider supporting them:"
        Url         = "https://raicuparta.itch.io/shipbreaker-vr"
        ReadmeDir   = "ShipbreakerVR"
        InfoUrl     = "https://raicuparta.itch.io/shipbreaker-vr"
        Color       = "#0f1830"
        Accent      = "#ef7d3a"
        Type        = "itch"
        SteamFolder = "Hardspace Shipbreaker"
        ModFile     = "BepInEx\plugins\ShipbreakerVr\ShipbreakerVr.dll"
        LaunchExe   = "Shipbreaker.exe"
        FallbackPaths=@("GOG:Hardspace Shipbreaker", "EPIC:HardspaceShipbreaker", "C:\Program Files\WindowsApps\FocusHomeInteractiveSA.HardspaceShipbreaker-PCVers_*_x64__4hny5m903y3g0")
        Tags        = @("shipbreaker vr", "hardspace", "hardspace shipbreaker", "shipbreaker", "simulation", "space", "physics")
    },
    @{
        Controls    = "MC"
        Title       = "Skyrim VR"
        Pill        = "Wabbajack"
        SteamId     = "611670"
        Mod         = "Wabbajack Modlist"
        Description = "Mad God Overhaul"
        Author      = "Wabbajack community"
        ImprovementTag = "+ VR improvement"
        Color       = "#0a1420"
        Accent      = "#8a72d8"
        Type        = "external"
        WabbajackUrl = "https://www.wabbajack.org/"
        InfoUrl     = "https://www.nexusmods.com/skyrimspecialedition/mods/107780"
        ModButtons  = @(
            @{ Label = "Mad God Overhaul"; Url = "https://www.nexusmods.com/skyrimspecialedition/mods/107780" }
        )
        ReadmeDir   = "SkyrimVRWabbajack"
        SteamFolder = "SkyrimVR"
        Tags = @("skyrim", "skyrim vr", "tes", "elder scrolls", "wabbajack", "modlist", "mad god overhaul", "mgo", "rpg", "fantasy", "bethesda", "open world")
    },
    @{
        Controls    = "MC"
        Title       = "Stanley Parable VR"
        Pill        = "StanleyVR"
        Quip        = "This is the story of a man named Stanley. And his headset."
        SteamId     = "1703340"
        Mod         = "VR Mod v0.4.0"
        Description = "by Raicuparta on itch.io"
        Author      = "Raicuparta"
        SupportUrl  = "https://www.patreon.com/c/raivr/home"
        SupportText = "Raicuparta develops these VR mods. If you enjoy their work, consider supporting them:"
        Url         = "https://raicuparta.itch.io/stanley-vr"
        ReadmeDir   = "StanleyParableVR"
        InfoUrl     = "https://raicuparta.itch.io/stanley-vr"
        Color       = "#1a1a1a"
        Accent      = "#dd6633"
        Type        = "itch"
        SteamFolder = "The Stanley Parable Ultra Deluxe"
        ModFile     = "BepInEx\plugins\StanleyVr\StanleyVr.dll"
        LaunchExe   = "The Stanley Parable Ultra Deluxe.exe"
        FallbackPaths=@("EPIC:TheStanleyParableUltraDeluxe", "GOG:The Stanley Parable Ultra Deluxe", "XBOX:The Stanley Parable- Ultra Deluxe")
        Tags        = @("stanley", "narrative", "comedy", "exploration")
    },
    @{
        Controls    = "GP"
        Title       = "Star Wars: X-Wing VR"
        Quip        = "Lock S-foils in attack position - the cockpit is yours in VR."
        ReadmeDir   = "XWingVR"
        SteamId     = "354430"
        # Bundled portrait - this 1998 title has a Steam header and
        # screenshots but no vertical library/portrait art, so we ship one.
        PortraitUrl = "Assets/XWing_portrait.jpg"
        SteamFolder = "STAR WARS X-Wing"
        FallbackPaths = @("GOG:Star Wars - X-Wing (1998)")
        Mod         = "XWVM"
        Description = "by the XWVM Team"
        Author      = "XWVM Team"
        Color       = "#0a0d18"
        Accent      = "#ff9a33"
        Type        = "external"
        InfoUrl     = "https://www.moddb.com/mods/xwvm/downloads"
        Url         = "https://www.moddb.com/mods/xwvm/downloads"
        ModPageUrl  = "https://www.moddb.com/mods/xwvm"
        ShowInfo    = $true
        Tags        = @("x-wing", "xwing", "xwvm", "star wars", "x-wing special edition", "x-wing vr", "space", "simulation", "sci-fi", "action", "shooter")
    },
    @{
        Controls    = "BOTH"
        Title       = "UEVR Deluxe"
        Quip        = "Thousands of Unreal Engine games, one step into VR."
        ReadmeDir   = "UEVRDeluxe"
        Mod         = "UE4/UE5 Easy Injector"
        Author      = "praydog + ODuis"
        Description = "by praydog + ODuis"
        Url         = "https://uevrdeluxe.org/"
        DownloadUrl = "https://api.github.com/repos/oduis/UEVRDeluxe/releases"
        InfoUrl     = "https://uevrdeluxe.org/"
        SupportUrl  = "https://www.patreon.com/c/praydog"
        SupportText = "praydog develops UEVR. If you enjoy his work, consider supporting him:"
        # No Steam page - bundled local images (Assets folder).
        PortraitUrl = "Assets/UEVR_portrait.jpg"
        HeaderUrl   = "Assets/UEVR_header.jpg"
        Color       = "#0a1a2a"
        Accent      = "#0088ff"
        Type        = "external"
        InjectorTag = $true
        Tags        = @("uevr", "unreal", "unreal engine", "ue4", "ue5", "praydog", "action", "adventure")
    },
    @{
        Controls    = "GP"
        Title       = "UUVR / Rai Pal"
        Quip        = "Every Unity game is a door. Rai Pal hands you the key."
        Mod         = "Rai Pal v0.19.2"
        Author      = "Raicuparta"
        Description = "Universal Unity VR Injector"
        Url         = "https://raicuparta.com/rai-pal/"
        DownloadUrl = "https://github.com/Raicuparta/rai-pal/releases/latest/download/RaiPal.exe"
        InfoUrl     = "https://raicuparta.com/rai-pal/"
        ModPageUrl  = "https://raicuparta.com/rai-pal/"
        SupportUrl  = "https://www.patreon.com/c/raivr/membership"
        SupportText = "Raicuparta develops UUVR and Rai Pal. If you enjoy his work, consider supporting him:"
        # No Steam page - bundled local images (Assets folder).
        PortraitUrl = "Assets/UUVR_portrait.jpg"
        HeaderUrl   = "Assets/UUVR_header.jpg"
        Color       = "#160a24"
        Accent      = "#8a4ff0"
        Type        = "external"
        ReadmeDir   = "UUVRRaiPal"
        InjectorTag = $true
        Tags        = @("uuvr", "rai pal", "raipal", "raicuparta", "unity", "injector", "universal", "uevr counterpart", "action", "adventure", "rpg")
    },
    @{
        Controls    = "MC"
        Title       = "Vivecraft"
        Quip        = "Blocks at arm's length. Mine, build, and swing in roomscale."
        Mod         = "Minecraft Java Edition VR mod"
        Author      = "jrbudda + Techjar"
        Description = "Requires Minecraft Java Edition"
        Url         = "https://www.vivecraft.org/"
        DownloadUrl = "https://www.vivecraft.org/downloads/"
        InfoUrl     = "https://www.vivecraft.org/downloads/"
        ModPageUrl  = "https://www.vivecraft.org/"
        # No Steam page - bundled local images (Assets folder).
        PortraitUrl = "Assets/Vivecraft_portrait.jpg"
        HeaderUrl   = "Assets/Vivecraft_header.jpg"
        Color       = "#0a2233"
        Accent      = "#29b6f6"
        Type        = "external"
        ReadmeDir   = "Vivecraft"
        Tags        = @("minecraft", "vivecraft", "sandbox", "survival", "crafting", "building", "mining", "multiplayer", "open world", "fan game", "java edition")
    }
)

# --- Luke Ross R.E.A.L. VR: single source of truth for the version -------
# Bump this ONE line per release (plus the download link + $REAL_VERSION in
# LukeRossVR-core.ps1). Every Luke Ross tile's Mod label is derived from it,
# so no per-game catalog edits are ever needed again.
$global:REALVR_NEWEST = "v2606"
foreach ($__lrg in $ownGamesGP) {
    if ($__lrg.Bat -like 'LukeRossVR*') { $__lrg.Mod = "R.E.A.L. $global:REALVR_NEWEST" }
}

