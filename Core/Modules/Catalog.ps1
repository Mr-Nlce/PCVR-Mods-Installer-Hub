# -------------------------------------------------------
# Own installers - alphabetical
# -------------------------------------------------------
$ownGames = @(
    @{
        Controls    = "MC"
        Title       = "7 Days to Die VR"; Roomscale=$true
        SteamId     = "251570"
        VideoUrl    = "https://www.youtube.com/watch?v=u81Rl4pgPnE"
        ModReleasedAt = "2026-07-06"
        Mod         = "7DaysVR v4.1.0.227"
        Pill        = "7D2DVR"
        Description = "Guided Nexus download."
        Author      = "7DaysVR Team"
        Bat         = "7DaysVR\START_INSTALLER.bat"
        Color       = "#0f1a0f"
        Accent      = "#55aa33"
        InfoUrl     = "https://docs.google.com/document/d/1gI9_EpF7ACiZu3bndAj1A5uGy0TKVUnfVfvTbHtWsPM/view?tab=t.0"
        # !!! GEAENDERT 2026-08-13 - DIE ALTE DATEI GIBT ES IN DER
        # INSTALLATION GAR NICHT !!! Frueher stand hier
        # 7DaysToDie_Data\Managed\UnityEngine.VRModule.dll. In Martins
        # echter Dateiliste einer laufenden 7DVR-4.1.0.227-Installation
        # kommt sie NICHT vor - dort liegen unter Managed\ nur
        # netstandard.dll und Valve.Newtonsoft.Json.dll, die VR-DLLs
        # stecken im Unterordner "7DVR Extra DLLs".
        # Die Mod selbst ist eindeutig an ihrer eigenen Datei zu erkennen.
        ModFile     = "BepInEx\plugins\7DaysVR.dll"
        SteamFolder = "7 Days To Die"
        GameExe     = "7DaysToDie.exe"
        Tags=@("7 days", "7dtd", "7d2d", "7d2dvr", "zombies", "fps", "open world", "shooter", "survival")
    },
    @{
        Controls    = "MC"
        Title       = "Alien: Isolation VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=0Hl_FipDY9s"
        SteamId     = "214490"
        Mod         = "MotherVR + GRAND"
        WebVersionUrl = "https://www.alienisolationvr.com/"
        Description = "Steam version required."
        Author      = "(auto-update) Nibre + JayP"
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
        Title       = "Amnesia VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=bhpnBbaMDmo"
        SteamId     = "57300"
        Mod         = "Sclerosis v1.8.16"
        ImprovementTag = "+ HD textures mod"
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
        VideoUrl    = "https://www.youtube.com/watch?v=LhODMRyRGpk"
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
        Tags=@("stalker", "s.t.a.l.k.e.r.", "s.t.a.l.k.e.r. anomaly", "stalker anomaly", "anomaly", "chornobyl", "chernobyl", "x-ray engine", "fps", "shooter", "survival", "open world", "post-apocalyptic", "first-person", "fan game", "free")
    },
    @{
        Controls    = "MC"
        Title       = "Anomaly GAMMA"
        VideoUrl    = "https://www.youtube.com/watch?v=i396q2RRyKs"
        SteamId     = ""
        PortraitUrl = "Assets/AnomalyGamma_portrait.jpg"
        HeaderUrl   = "Assets/AnomalyGamma_header.jpg"
        ScreenshotUrl = "Assets/AnomalyGamma_screenshot.jpg"
        Mod         = "GAMMA VR v0.3.2c"
        # No version marker exists for this one: the pack comes from Discord
        # as a 100+ GB .7z, so there is nothing to compare a tag against. The
        # date the v0.3.2 pack was published works instead - the check reads
        # the age of the installed GAMMA VR.bat (with a 7-day grace, so a
        # fresh install of the new pack never flags itself).
        ModReleasedAt = "2026-08-03"
        # Written by the installer into the game folder - authoritative, so
        # the date guess above only applies to installs made before this.
        ModVersionFile = "gamma_vr_version.txt"
        ModVersion     = "0.3.2c"
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
        Tags=@("stalker", "s.t.a.l.k.e.r.", "s.t.a.l.k.e.r. anomaly", "s.t.a.l.k.e.r. gamma", "stalker gamma", "gamma", "anomaly gamma", "anomaly", "chornobyl", "chernobyl", "x-ray engine", "survival", "fps", "open world", "shooter", "post-apocalyptic", "first-person", "crafting", "fan game", "modpack", "free")
    },
    @{
        Controls    = "MC"
        Title       = "Arma 3 VR"
        Quip        = "Someone already took the high ground. It is always the sniper."
        SteamId     = "107410"
        Mod         = "A3VR Hybrid (auto-update)"
        GithubRepo  = "gborgogno/a3vr-arma3"
        Description = "VERY EARLY ALPHA, OpenXR"
        Author      = "gborgogno"
        Bat         = "Arma3VR\START_INSTALLER.bat"
        Color       = "#151b18"
        Accent      = "#9ea76b"
        InfoUrl     = "https://github.com/gborgogno/a3vr-arma3"
        ModPageUrl  = "https://github.com/gborgogno/a3vr-arma3"
        DownloadUrl = "https://github.com/gborgogno/a3vr-arma3/releases"
        ModFile     = "@A3VR_Hybrid\A3VRHybridCore_x64.dll"
        GameExe     = "arma3_x64.exe"
        SteamFolder = "Arma 3"
        Notice      = "Early community alpha: this is a hybrid OpenXR bridge, not a native VR port. Both eyes currently receive the same comfort-mono image, and BattlEye must remain disabled."
        UninstallSteps = @(
            "Disable 'A3VR - Arma 3 Hybrid VR' in the official Arma 3 Launcher.",
            "Delete the '@A3VR_Hybrid' folder from your Arma 3 game folder if you installed the GitHub version.",
            "If you used the Workshop version, unsubscribe from it in Steam instead.",
            "The launcher backs up the Arma configuration and player profile before changing them; restore those backup copies if you also want to undo its FOV and graphics changes."
        )
        Tags=@("arma", "arma 3", "a3vr", "openxr", "military", "simulation", "tactical", "shooter", "fps", "sandbox", "multiplayer", "motion controls", "early access", "wip")
    },
    @{
        Controls    = "MC"
        Title       = "Ashes 2063 VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=29DQWu_0XKI"
        ImprovementTag = "+ 3D ammo + props mod"
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
        # Volle Motion Controls: getracktes Zielen, Zweihandgriff, Quick Menu
        # per Zeigen. Maus und Tastatur bleiben zusaetzlich nutzbar.
        Controls    = "MC"
        Title       = "Battlefield 1942 VR"
        VideoUrl    = "https://www.youtube.com/watch?v=htv_u67kUKw"
        Quip        = "Someone already took the plane. They always do."
        Mod         = "BFVR (auto-update)"
        Description = "You need your own copy"
        Author      = "JayBiggsGMG"
        Bat         = "BattlefieldVR\START_INSTALLER.bat"
        Color       = "#2b2a20"
        Accent      = "#c8a24a"
        PortraitUrl = "Assets/BattlefieldVR_portrait.jpg"
        HeaderUrl   = "Assets/BattlefieldVR_header.jpg"
        ScreenshotUrl = "Assets/BattlefieldVR_screenshot.jpg"
        InfoUrl     = "https://github.com/JayBiggsGMG/BFVR-Battlefield-1942-VR-Mod"
        ModPageUrl  = "https://github.com/JayBiggsGMG/BFVR-Battlefield-1942-VR-Mod"
        DownloadUrl = "https://github.com/JayBiggsGMG/BFVR-Battlefield-1942-VR-Mod/releases"
        GithubRepo  = "JayBiggsGMG/BFVR-Battlefield-1942-VR-Mod"
        # KEIN SteamId: das Spiel wird nirgends mehr verkauft. Der Nutzer
        # muss eine eigene Fassung besitzen, und die liegt bei jedem
        # woanders - der Installer sucht die ueblichen Orte ab und laesst
        # den Ordner sonst ablegen.
        SteamId     = ""
        # !!! SteamFolder MUSS GESETZT SEIN, AUCH OHNE STEAM-FASSUNG !!!
        # Der Scan baut in Prioritaet 2 den Pfad steamapps\common\<SteamFolder>.
        # Ist das Feld LEER, entsteht daraus der Sammelordner selbst - der
        # existiert immer, der Scan haelt das Spiel fuer gefunden und setzt
        # den Spielordner auf steamapps\common. Danach wird die Moddatei
        # dort gesucht, nie gefunden, und die Fallback-Pfade kommen gar
        # nicht mehr dran. Genau so wie bei Sonic P-06 VR gehandhabt.
        SteamFolder = "Battlefield 1942"
        ModFile     = "BFVR\BFVR.exe"
        LaunchExe   = "BFVR\BFVR.exe"
        # Gestartet wird AUSSCHLIESSLICH ueber BFVR.exe. Es gibt keinen
        # Steam-Eintrag, auf den ausgewichen werden koennte, und BF1942.exe
        # direkt zu starten gibt das flache Spiel.
        NeverSteamLaunch = $true
        # Martins eigene Installation liegt unter "EA Games" mit KLEINEM g -
        # Windows selbst ist da gleichgueltig, PowerShells -LiteralPath bei
        # manchen Vergleichen nicht. Beide Schreibweisen stehen deshalb drin.
        FallbackPaths = @(
            "C:\Program Files (x86)\EA Games\Battlefield 1942",
            "C:\Program Files (x86)\EA GAMES\Battlefield 1942",
            "C:\Program Files\EA Games\Battlefield 1942",
            "C:\Program Files\EA GAMES\Battlefield 1942",
            "C:\Games\Battlefield 1942",
            "D:\Games\Battlefield 1942",
            "C:\Battlefield 1942"
        )
        # KURZ HALTEN. Die Warnbox nennt NUR das, was jemanden vom Kauf
        # oder vom Loslegen abhaelt - alles Weitere (BF42++, Startweg ueber
        # BFVR.exe, Mehrspieler-Regeln) steht im README in eigenen
        # Abschnitten und muss hier nicht wiederholt werden.
        Notice      = "Battlefield 1942 is no longer sold anywhere - you need your own copy."
        NoticeUrl   = "https://steamcommunity.com/sharedfiles/filedetails/?id=2721068159"
        NoticeUrlLabel = "You can find helpful information in the Community Guide"
        UninstallSteps = @(
            "Close Battlefield 1942 and BFVR.",
            "Run the mod's own uninstaller: Battlefield 1942\BFVR\unins000.exe. It removes the BFVR folder it created.",
            "Everything BFVR installed lives in that one BFVR\ subfolder - no game file was ever replaced, so there is nothing to restore.",
            "BF42++ is a separate prerequisite, not part of BFVR. Leave bf42++.dll, bf42++.exe and bf42++BlackScreen.exe in place if you still want it, or delete those three files to remove it as well.",
            "Your VR settings were in BFVR\UserConfig.txt and go with the folder.",
            "If the installer set 'Run as administrator' for BFVR.exe or bf42++.exe (it offers that when the game sits under Program Files), undo it in the file's Properties - Compatibility tab, or it stays for that account."
        )
        Tags        = @("battlefield", "1942", "world war 2", "shooter", "fps", "vehicles", "tanks", "aircraft", "multiplayer", "classic")
    },
    @{
        Controls    = "MC"
        Title       = "Bendy VR"
        VideoUrl    = "https://youtu.be/FjC5Rnk_cOs?t=3633"
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
        Title       = "Big Walk VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=ULF3DVYfH5c"
        Quip        = "Two lads, one long walk, and now you are actually in it."
        SteamId     = "1478500"
        Mod         = "Big Walk VR"
        Description = "Co-op, solo via add-on"
        Author      = "CircuitLord"
        Bat         = "BigWalkVR\START_INSTALLER.bat"
        Color       = "#1d2a1f"
        Accent      = "#8ec06c"
        InfoUrl     = "https://github.com/CircuitLord/BigWalkVRInstaller"
        ModFile     = "Mods\BigWalkVR.dll"
        ModFileAlt  = "BigWalkVRInstaller.exe"
        LaunchExeAlt= "BigWalkVRInstaller.exe"
        GameExe     = "Big Walk.exe"
        SteamFolder = "Big Walk"
        Tags=@("big walk", "bigwalk", "house house", "circuitlord", "adventure", "exploration", "walking sim", "coop", "multiplayer", "atmospheric")
    },
    @{
        Controls    = "MC"
        Title       = "BioShock Remastered"
        Quip        = "Would you kindly put the headset on and descend into Rapture."
        SteamId     = "409710"
        VideoUrl    = "https://www.youtube.com/watch?v=LbP9ddrvbWw"
        Mod         = "balouza, BioVRDev (auto-update)"
        # BOTH MODS ARE TRACKED SEPARATELY. Each repo is only checked when
        # that mod is really parked on disk, so a balouza release cannot
        # raise an Update badge on a BioVRDev-only install and the other
        # way round; with both installed, either one can. The presence
        # probes list the Steam and the Epic layout, separated by "|".
        # (GithubRepoAlt is deliberately NOT used here - that field only
        # switches repos when a .vrv_source file containing "francisco"
        # exists, which is GTA5's AV-fallback mechanism.)
        GithubRepo  = "mohamad-balouza/bioshock-vr"
        GithubRepoPresenceFile  = "Build\Final\_vrmods\balouza\xinput1_3.dll|Build\FinalEpic\_vrmods\balouza\xinput1_3.dll"
        GithubRepoB = "BioVRDev/Bioshock-Remastered-VR"
        GithubRepoBPresenceFile = "Build\Final\_vrmods\biovrdev\dxgi.dll|Build\FinalEpic\_vrmods\biovrdev\dxgi.dll"
        Description = "Two mods, switchable"
        ImprovementTag = "+ fullscreen cutscenes"
        Author      = "balouza / BioVRDev"
        Bat         = "BioshockVR\START_INSTALLER.bat"
        Color       = "#0a1418"
        Accent      = "#39a9bd"
        InfoUrl     = "https://github.com/mohamad-balouza/bioshock-vr"
        ModPageUrl  = "https://github.com/mohamad-balouza/bioshock-vr"
        DownloadUrl = "https://github.com/mohamad-balouza/bioshock-vr/releases"
        # TWO MODS, ONE FOLDER. Both drop their files into Build\Final and
        # their payload DLLs are BioshockVR.dll vs bioshockvr.dll - the same
        # name on Windows. They cannot coexist there, so the installer parks
        # each one in Build\Final\_vrmods\<mod> and copies only the ACTIVE
        # set next to the exe. The two switch launchers it writes into
        # Build\Final\VRLaunch are what these ModALaunch/ModBLaunch fields
        # detect - one bat per installed mod, so the tile knows which mods
        # are on disk even when only one of them is. ModASub/ModBSub are
        # "Build" because Epic uses Build\FinalEpic; the search is recursive.
        TwoMods       = $true
        # The two mods cannot coexist in the game folder, so the Play
        # buttons and the switch are only offered once BOTH are really
        # installed - and the installer only writes the two launchers in
        # that case. This flag also disables the file-probe fallback in
        # Filter.ps1, which cannot tell these two mods apart (their
        # payloads are BioshockVR.dll and bioshockvr.dll - the same name
        # on Windows).
        TwoModsRequireBoth = $true
        ModAName      = "balouza"
        ModASub       = "Build"
        ModALaunch    = "BioShock VR (balouza).bat"
        ModBName      = "BioVRDev"
        ModBSub       = "Build"
        ModBLaunch    = "BioShock VR (BioVRDev).bat"
        ModBProbeFile = "Build\Final\dxgi.dll"
        ModFile     = "Build\Final\BioshockVR.dll"
        ModFileAlt  = "Build\FinalEpic\BioshockVR.dll"
        # No LaunchExe on purpose: starting BioshockHD.exe directly doesn't
        # work - the game wants to come up through Steam. Without the field
        # the Hub uses steam://rungameid, which is what actually launches it.
        # Detection still works through SteamFolder + ModFile.
        # Whichever mod is active owns the injector, and the folder differs
        # between the Steam and the Epic build - so all four candidates are
        # listed and the first one on disk wins. dxgi.dll = BioVRDev,
        # xinput1_3.dll = balouza.
        FlatVREnabled  = "Build\Final\dxgi.dll|Build\Final\xinput1_3.dll|Build\FinalEpic\dxgi.dll|Build\FinalEpic\xinput1_3.dll"
        FlatVRDisabled = "Build\Final\dxgi.dll-|Build\Final\xinput1_3.dll-|Build\FinalEpic\dxgi.dll-|Build\FinalEpic\xinput1_3.dll-"
        SteamFolder = "BioShock Remastered"
        FallbackPaths=@("C:\GOG Games\BioShock Remastered",
                        "C:\Program Files (x86)\GOG Galaxy\Games\BioShock Remastered",
                        "C:\Program Files\Epic Games\BioShockRemastered")
        UninstallSteps = @(
            "Open your BioShock Remastered folder and go into Build\Final (Build\FinalEpic on Epic).",
            "Delete whichever of these are there - they are the active mod: dxgi.dll, BioshockVR.dll, BioshockVR.ini, openxr_loader.dll and FirstTimeSetup.bat (BioVRDev), xinput1_3.dll, bioshockvr.dll, bvr_steamvr32.dll and openvr_api.dll (balouza). The game is flat again.",
            "Delete the _vrmods folder (it holds the parked copy of each mod) and the VRLaunch folder (the two switch launchers).",
            "The setup backed your Bioshock.ini up before changing it; restore that copy if you want the original video settings back. Any file the Hub overwrote was kept next to it as <name>.hubbak.",
            "balouza also keeps its own settings in %LOCALAPPDATA%\BioshockVR - delete that folder to remove them.",
            "Did you take the fullscreen cutscenes option? Then ContentBaked\pc\FlashMovies\HUDPC.swf was replaced - rename HUDPC.swf.hubbak back over it to restore the original HUD."
        )
        Tags        = @("bioshock", "rapture", "fps", "shooter", "action", "horror", "story", "adventure", "atmospheric", "immersive", "plasmids", "remastered", "openxr", "biovrdev", "balouza", "motion controllers")
    },
    @{
        Controls    = "MC"
        Title       = "BioShock 2 Remastered"
        Quip        = "Rapture never asked you to look away. Now you cannot."
        SteamId     = "409720"
        VideoUrl    = "https://youtu.be/eLE85Yua2TI?t=152"
        Mod         = "bioshock-vr (auto-update)"
        GithubRepo  = "mohamad-balouza/bioshock-vr"
        Description = "Remastered, square res"
        Author      = "balouza"
        Bat         = "Bioshock2VR\START_INSTALLER.bat"
        Color       = "#0a1418"
        Accent      = "#39a9bd"
        InfoUrl     = "https://github.com/mohamad-balouza/bioshock-vr"
        ModPageUrl  = "https://github.com/mohamad-balouza/bioshock-vr"
        DownloadUrl = "https://github.com/mohamad-balouza/bioshock-vr/releases"
        SteamFolder = "BioShock 2 Remastered"
        FallbackPaths=@("C:\GOG Games\BioShock 2 Remastered", "C:\Program Files (x86)\GOG Galaxy\Games\BioShock 2 Remastered", "C:\Program Files\Epic Games\BioShock2Remastered", "EPIC:BioShock2Remastered")
        # The injector next to the game exe. Steam and GOG use Build\Final,
        # Epic ships its binaries in Build\FinalEpic - hence the alt.
        ModFile     = "Build\Final\xinput1_3.dll"
        ModFileAlt  = "Build\FinalEpic\xinput1_3.dll"
        GameExe     = "Build\Final\Bioshock2HD.exe"
        UninstallSteps = @(
            "Delete 'xinput1_3.dll', 'bioshockvr.dll', 'bvr_steamvr32.dll' and 'openvr_api.dll' from the game's Build\Final folder - Build\FinalEpic on Epic. The base game is left untouched.",
            "If the installer parked another mod's injector, rename that file back."
        )
        Tags=@("bioshock", "bioshock 2", "rapture", "subject delta", "big daddy", "2k", "balouza", "shooter", "action", "horror", "story", "openxr")
    },
    @{
        Controls    = "MC"
        Title       = "BioShock Infinite VR"
        Quip        = "Bring us the girl. Look up while you do it."
        SteamId     = "8870"
        # !!! DAS ALTE VIDEO WAR VON BIOSHOCK 2 UEBERNOMMEN !!!
        # Von Infinite gibt es noch KEIN VR-Mod-Gameplay, deshalb zeigt
        # der Streifen bewusst nur normales Spielmaterial - und die
        # Beschriftung sagt "Watch gameplay", nicht "Watch VR gameplay".
        VideoUrl    = "https://youtu.be/Cq-XVUgy4uY?t=17"
        VideoLabel  = "Watch gameplay"
        Mod         = "bioshock-vr (auto-update)"
        GithubRepo  = "mohamad-balouza/bioshock-vr"
        Description = "Early access, heavier"
        Author      = "balouza"
        Bat         = "BioshockInfiniteVR\START_INSTALLER.bat"
        Color       = "#101a24"
        Accent      = "#d8b26a"
        InfoUrl     = "https://github.com/mohamad-balouza/bioshock-vr"
        ModPageUrl  = "https://github.com/mohamad-balouza/bioshock-vr"
        DownloadUrl = "https://github.com/mohamad-balouza/bioshock-vr/releases"
        SteamFolder = "BioShock Infinite"
        FallbackPaths=@("C:\GOG Games\BioShock Infinite", "C:\Program Files (x86)\GOG Galaxy\Games\BioShock Infinite", "EPIC:BioShockInfinite", "EPIC:BioshockInfiniteCompleteEdition", "C:\Program Files\Epic Games\BioshockInfiniteCompleteEdition", "C:\Program Files (x86)\Epic Games\BioshockInfiniteCompleteEdition")
        # !!! NICHT Build\Final WIE BEI BIOSHOCK 1 UND 2 !!!
        # Infinite laeuft auf der Unreal Engine 3 und legt seine
        # Binaerdateien unter Binaries\Win32 ab. Der Mod-Autor schreibt
        # das ausdruecklich dazu, weil es die haeufigste Verwechslung ist.
        # Deshalb gibt es hier auch KEIN ModFileAlt - alle Laeden nutzen
        # denselben Pfad.
        ModFile     = "Binaries\Win32\xinput1_3.dll"
        GameExe     = "Binaries\Win32\BioShockInfinite.exe"
        Notice      = "Early access: playable and comfortable from the start of the game through the early city, which is the range the author tested. Later chapters, the Skyline and the DLCs have not had a VR pass yet. Infinite is also heavier in VR than the two remasters - if it judders, lower the game resolution in the F10 overlay first (keep it roughly square), then your streaming quality."
        UninstallSteps = @(
            "Delete 'xinput1_3.dll', 'bioshockvr.dll', 'bvr_steamvr32.dll' and 'openvr_api.dll' from the game's Binaries\Win32 folder - NOT Build\Final, Infinite keeps its binaries elsewhere. The base game is left untouched.",
            "If the installer parked another mod's injector, rename that file back.",
            "Your VR tuning lives outside the game folder in %LOCALAPPDATA%\BioshockVR\bsi\ - delete that folder too if you want a clean slate."
        )
        Tags=@("bioshock", "bioshock infinite", "columbia", "booker", "elizabeth", "2k", "irrational", "balouza", "shooter", "action", "story", "openxr")
    },
    @{
        Controls    = "MC"
        Title       = "Black Mesa Source VR"
        VideoUrl    = "https://www.youtube.com/watch?v=YWEzatOqQq0"
        SteamId     = "362890"
        ModReleasedAt = "2023-05-04"
        Mod         = "BMSVR Beta 2.0"
        Description = "HL2VR Ep.2 Mod"
        Author      = "Ashok"
        Bat         = "BMSVR\START_INSTALLER.bat"
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
        Title       = "Breath of the Wild VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=vNaQNg2h_Kk"
        Quip        = "Climb anything, cook questionable meals, and chase the next shrine on the horizon."
        Mod         = "BetterVR (auto-update)"
        GithubRepo  = "Crementif/BotW-BetterVR"
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
        # Die Mod ist AUSSCHLIESSLICH fuer Zero Hour - der Autor schreibt
        # "I'm turning Command & Conquer: Generals - Zero Hour into a VR
        # game", verlangt eine Zero-Hour-Installation, und seine Exe heisst
        # generalszhv.exe (zh = Zero Hour). Der Titel sagt das jetzt auch.
        # Die Suche nach "command and conquer" oder "command & conquer"
        # findet ihn weiterhin - beide Schreibweisen stehen in den Tags,
        # und die Suche prueft Titel UND Tags mit Contains.
        Title       = "C&C Generals: Zero Hour"
        Quip        = "Sir, the war table is ready. Mind the tanks near your boots."
        # !!! 2229870 IST DAS GRUNDSPIEL, NICHT ZERO HOUR !!! Die Mod ist
        # fuer Zero Hour, und das hat auf Steam die eigene Kennung
        # 2732960 (store.steampowered.com/app/2732960). Mit der
        # falschen Kennung sucht der Scan das falsche Spiel.
        SteamId     = "2732960"
        SteamFolder = "Command & Conquer Generals - Zero Hour"
        VideoUrl    = "https://v.redd.it/uiaj4g2jgkdh1/CMAF_1080.mp4?source=fallback"
        Mod         = "GeneralsVR (self-updating)"
        Description = "Alpha, Zero Hour required"
        Author      = "Gonzorro"
        Bat         = "GeneralsVR\START_INSTALLER.bat"
        Color       = "#1e2417"
        Accent      = "#c8a03c"
        InfoUrl     = "https://github.com/Gonzorro/GeneralsVR"
        ModPageUrl  = "https://github.com/Gonzorro/GeneralsVR"
        DownloadUrl = "https://github.com/Gonzorro/GeneralsVR/releases"
        GithubRepo  = "Gonzorro/GeneralsVR"
        GithubPrerelease = $true
        # !!! DIE MOD LIEGT NICHT IM SPIELORDNER !!! Sie fasst Zero Hour
        # nie an und lebt komplett in %LOCALAPPDATA%\GeneralsVR - deshalb
        # VrInstallRoot, genau wie bei den GZDoom-Eintraegen. ModFile ist
        # dann relativ zu diesem Ordner, nicht zum Spiel.
        VrInstallRoot = "LOCALAPPDATA:GeneralsVR"
        ModFile     = "Data\generalszhv.exe"
        LaunchExe   = "START-GeneralsVR.cmd"
        # Zero Hour gibt es in vielen Ausgaben, und der Starter der Mod
        # findet sie selbst - diese Pfade helfen nur unserem Scan.
        # Der erste Eintrag zeigte auf das GRUNDSPIEL Generals - falsch.
        # Alle Pfade hier meinen Zero Hour.
        FallbackPaths=@("STEAM:Command & Conquer Generals - Zero Hour", "C:\Program Files\EA Games\Command and Conquer Generals Zero Hour", "C:\Program Files (x86)\Origin Games\Command & Conquer Generals Zero Hour", "C:\Program Files (x86)\EA Games\Command & Conquer Generals Zero Hour", "C:\Program Files (x86)\EA Games\Command & Conquer The First Decade\Command & Conquer(tm) Generals Zero Hour", "GOG:Command and Conquer Generals Zero Hour")
        Notice      = "Early alpha - skirmish plays end to end, but expect rough edges. Quest 3 over Quest Link is the only tested headset; others are untested. The headset stays dark in the menus, which is normal - only the battlefield is rendered, so start a skirmish before you go looking for the picture."
        UninstallSteps = @(
            "Your Zero Hour install was never touched - there is nothing to undo there.",
            "Delete the folder %LOCALAPPDATA%\GeneralsVR. That is the whole mod, including the game build, your VR settings and the Debug logs.",
            "Delete the GeneralsVR shortcut from your desktop.",
            "Or let the mod do it: run GeneralsVR.ps1 -Uninstall from that folder before you delete it.",
            "The setup wrote a few registry entries the game engine needs. The uninstall switch above removes them; deleting the folder by hand leaves them, which is harmless."
        )
        Tags=@("command and conquer", "command & conquer", "c&c", "cnc", "generals", "zero hour", "zerohour", "rts", "strategy", "ea", "gonzorro", "openxr", "dxvk", "war table", "alpha", "wip")
    },
    @{
        Controls    = "MC"
        Title       = "Call of Duty 4 VR"
        VideoUrl    = "https://youtu.be/NlR_JheVXCk?t=96"
        Quip        = "Aim with your hands, shoulder the rifle, and go loud."
        SteamId     = "7940"
        Mod         = "KisakCOD VR (auto-update)"
        # The project ships BETAS - v0.9.0-beta.1 is the first public one -
        # so both the update badge and the installer resolve the newest
        # release through /releases, never /releases/latest.
        GithubRepo  = "jplakon/CallOfDuty4_VR"
        GithubPrerelease = $true
        Description = "Original 2007 COD4 only"
        Author      = "jplakon"
        Bat         = "CallOfDuty4VR\START_INSTALLER.bat"
        Color       = "#0d1108"
        Accent      = "#6fbf3a"
        InfoUrl     = "https://github.com/jplakon/CallOfDuty4_VR"
        ModPageUrl  = "https://github.com/jplakon/CallOfDuty4_VR"
        DownloadUrl = "https://github.com/jplakon/CallOfDuty4_VR/releases"
        # The VR build ONLY comes up through its own launcher bat: it loads
        # VR-Settings.bat and then starts KisakCOD-sp.exe with a long list
        # of console variables. steam://rungameid would start the FLAT game,
        # so LaunchExe points at the bat and the installer also writes a
        # desktop shortcut to it.
        LaunchExe   = "Launch-KisakCOD-VR.bat"
        ModFile     = "KisakCOD-sp.exe"
        SteamFolder = "Call of Duty 4"
        # Retail/DVD installs land under Activision with the long folder
        # name; Steam uses the short one under steamapps\common.
        FallbackPaths=@("STEAM:Call of Duty 4", "STEAM:Call of Duty 4 - Modern Warfare",
                        "C:\Program Files (x86)\Activision\Call of Duty 4 - Modern Warfare",
                        "D:\Program Files (x86)\Activision\Call of Duty 4 - Modern Warfare",
                        "C:\Program Files (x86)\Activision\Call of Duty 4",
                        "D:\Program Files (x86)\Activision\Call of Duty 4")
        UninstallSteps = @(
            "Close the game and open your Call of Duty 4 folder - the one with iw3sp.exe.",
            "Delete the files the mod added: KisakCOD-sp.exe, KisakCOD-VR-Configurator.exe, Launch-KisakCOD-VR.bat, Launch-KisakCOD-VR-Diagnostics.bat, Collect-KisakCOD-VR-Crash-Report.bat and .ps1, VR-Settings.bat (and VR-Settings.bat.hubprev if it is there), CallOfDuty4_VR.ico, README-FIRST.txt, INSTALL.txt, CONTROLS.txt, KNOWN-ISSUES.txt, CHANGELOG.txt, BUILD-INFO.txt, SHA256SUMS.txt, SOURCE.txt, THIRD-PARTY-NOTICES.txt, LICENSE-GPLv3.txt and the licenses folder.",
            "Your configurator profile is NOT in the game folder - it lives under %LOCALAPPDATA%. Delete it there only if you want your VR settings gone as well.",
            "The mod overwrote a few files the game already had - mss32.dll, binkw32.dll, steam_api.dll and the miles folder. Each original was kept next to it as <n>.hubbak: delete the new file and rename the .hubbak copy back to restore the flat game exactly.",
            "Delete the 'Call of Duty 4 VR' desktop shortcut.",
            "If the installer placed d3dx9d_43.dll in the game folder, you can delete that too - the flat game never needed it.",
            "Nothing else is touched - your maps, fastfiles and saves are untouched, and the flat game keeps working the whole time."
        )
        Tags        = @("call of duty", "cod", "cod4", "modern warfare", "kisakcod", "jplakon", "fps", "shooter", "action", "war", "military", "campaign", "story", "singleplayer")
    },
    @{
        Controls    = "MC"
        Title       = "Content Warning VR"
        VideoUrl    = "https://www.youtube.com/watch?v=tab39pQWAFE"
        SteamId     = "2881650"
        Mod         = "CWVR (auto-update)"
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
        VideoUrl    = "https://www.youtube.com/watch?v=IGjFWqW7v08"
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
        VideoUrl    = "https://www.youtube.com/watch?v=XkzaBRPJoQE"
        SteamId     = "1091500"
        Mod         = "CP_VRPort (auto-update)"
        Description = "OpenXR, motion controls."
        Author      = "dariulone"
        Bat         = "Cyberpunk2077VR\START_INSTALLER.bat"
        UninstallSteps = @(
            "Delete the folders the mod added: red4ext\plugins\CyberpunkVR_Stereo\, red4ext\plugins\CyberpunkVR_Hands\, bin\x64\plugins\cyber_engine_tweaks\mods\CyberpunkVRPort_*\ and r6\scripts\CyberpunkVRPort_*\.",
            "Leave the frameworks (RED4ext, Cyber Engine Tweaks, redscript) in place if other mods use them.",
            "The base game is left untouched."
        )
        Color       = "#0a0e12"
        Accent      = "#fcee0a"
        InfoUrl     = "https://github.com/dariulone/cyberpunk-vr-port"
        GitHubNightly = "dariulone/cyberpunk-vr-port"
        Quip        = "Wake up, samurai - Night City won't burn itself down."
        # Since CyberpunkVRPort 0.1.0 the mod is a RED4ext plugin, not a
        # dxgi.dll proxy - dxgi.dll is gone from the package entirely, so
        # the old marker would never be found again.
        ModFile     = "red4ext\plugins\CyberpunkVR_Stereo\CyberpunkVR_Stereo.dll"
        # Everyone who installed a pre-0.1.0 build through the Hub still has
        # the old dxgi.dll proxy and none of the new files. ModFileAlt keeps
        # those installs recognised as VR Ready instead of dropping them back
        # to "Needs Mod", and ModLegacyFile turns them into an Update - old
        # marker present, new marker missing = outdated by definition.
        ModFileAlt    = "bin\x64\dxgi.dll"
        ModLegacyFile = "bin\x64\dxgi.dll"
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
        # Der Steam-Ordner des ORIGINALSPIELS, aus dem Daggerfall Unity
        # seine Daten zieht - nicht der Ordner der VR-Installation. Von
        # Martin genannt: C:\Program Files (x86)\Steam\steamapps\common\
        # The Elder Scrolls Daggerfall (SteamId 1812390).
        SteamFolder = "The Elder Scrolls Daggerfall"; Roomscale=$true
        VideoUrl    = "https://youtu.be/kssQ8SPzNMM?t=198"
        ModReleasedAt = "2025-05-24"
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
        Tags=@("daggerfall", "dfuvr", "elder scrolls", "rpg", "open world", "adventure", "lokiusv", "bepinex", "dungeon", "free")
    },
    @{
        Controls    = "MC"
        Title       = "Deep Rock Galactic VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/llngmaHmLk8?t=269"
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
        Title       = "Doom VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=Idk9sOPqfYc"
        ImprovementTag = "+ 3D weapons mod"
        SteamId     = "2280"
        Mod         = "GZDoomVR (auto-update)"
        GithubRepo  = "hh79/gzdoomvr"
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
        Title       = "Doom 2 VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=G8mWcEkE-0I"
        ImprovementTag = "+ 3D weapons mod"
        SteamId     = "2300"
        Mod         = "GZDoomVR (auto-update)"
        GithubRepo  = "hh79/gzdoomvr"
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
        Title       = "Doom 3 BFG VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/mQamxzJkYgU?t=6"
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
        VideoUrl    = "https://www.youtube.com/watch?v=i-T8kYhSpo4"
        SteamId     = "1562430"
        Mod         = "DredgeVR (auto-update)"
        GithubRepo  = "xen-42/DredgeVR"
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
        Title       = "Dusk HD (DLC) VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=yuwHKbb4vX8"
        SteamId     = "519860"
        Mod         = "UnityVR_DuskHD v1.0.0"
        Description = "Discord login, DLC needed"
        Author      = "Astienth"
        Bat         = "DuskHDVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "For a full uninstall, delete the renamed file plus 'BepInEx\' and 'winhttp_bak.dll' from the DLC folder.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#1a0a00"
        Accent      = "#cc6622"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1449484957671227555/1449484957671227555"
        ModFile     = "DLC\DUSK HD\BepInEx\plugins\UnityVR_DuskHD.dll"
        SteamFolder = "DUSK"
        FallbackPaths=@("GOG:DUSK")
        LaunchExe   = "DLC\DUSK HD\Dusk.exe"
        Tags=@("dusk", "dusk hd", "fps", "shooter", "retro", "quake", "horror", "fast paced", "boomer shooter")
    },
    @{
        Controls    = "MC"
        Title       = "Escape from Tarkov VR"
        VideoUrl    = "https://www.youtube.com/watch?v=lUgDG8ogoxs"
        Quip        = "Survive the raid, secure the loot, pray the extract stays open."
        SteamId     = "3932890"
        PortraitUrl = "Assets/SPTVR_portrait.jpg"
        HeaderUrl   = "Assets/SPTVR_header.jpg"
        Mod         = "SPT-VR (auto-update)"
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
        Title       = "F.E.A.R. VR"
        VideoUrl    = "https://www.youtube.com/watch?v=hxmHXL412vQ"
        Quip        = "Slow-mo firefights and Alma's whispers, now in stereoscopic VR."
        SteamId     = "21090"
        PortraitUrl = "Assets/FearVR_portrait.jpg"
        HeaderUrl   = "Assets/FearVR_header.jpg"
        ScreenshotUrl = "Assets/FearVR_screenshot.jpg"
        Mod         = "F.E.A.R. VR (auto-update)"
        GithubRepo  = "DR-89/fear-vr"
        GithubPrerelease = $true
        Description = "OpenXR, Public Tools 1.08"
        ImprovementTag = "+ HD textures mod"
        Notice      = "Be aware this is an early WIP version yet. Issues are expected at this point."
        Author      = "DR-89"
        Bat         = "FearVR\START_INSTALLER.bat"
        Color       = "#140d0d"
        Accent      = "#b01818"
        InfoUrl     = "https://github.com/DR-89/fear-vr"
        ModPageUrl  = "https://github.com/DR-89/fear-vr"
        DownloadUrl = "https://github.com/DR-89/fear-vr/releases"
        ModFile     = "bin\x64\fearvr-host.exe"
        # Since beta.8 the mod lives INSIDE the game folder, one level deeper:
        # <game>\FEARVR\bin\x64\... The old layout sat in its own install
        # folder, where ModFile above matches from its root. Whichever anchor
        # the scan uses, one of the two has to hit - otherwise an overlay
        # install reads as "game installed, no VR mod".
        ModFileAlt  = "FEARVR\bin\x64\fearvr-host.exe"
        # Every install made before beta.8 carries the mod's old install
        # script; the overlay package has no install.ps1 at all. The host exe
        # is in both, so only this file tells the two generations apart -
        # anyone still on the old layout gets an Update badge.
        ModOutdatedFile = "tools\install.ps1"
        # The starter inside the game folder, checked BEFORE any recorded
        # path: C:\...\FEAR Ultimate Shooter Edition\FEARVR\Start FEAR VR.bat
        LaunchExeAlt = "FEARVR\Start FEAR VR.bat"
        LaunchExe   = "Start FEAR VR.bat"
        NeverSteamLaunch = $true
        VrInstallRoot = "C:\Games\FEAR VR"
        VrManifest        = "deployment.json"
        VrManifestPathKey = "runtimeExe"
        SteamFolder = "FEAR Ultimate Shooter Edition"
        FallbackPaths=@("GOG:F.E.A.R. Platinum Collection",
                        "C:\Program Files (x86)\GOG Galaxy\Games\F.E.A.R. Platinum Collection",
                        "C:\Program Files\Sierra\FEAR")
        UninstallSteps = @(
            "Open the F.E.A.R. VR folder (default C:\Games\FEAR VR) in a terminal.",
            "Run 'powershell -ExecutionPolicy Bypass -File tools\uninstall.ps1 -Apply'. It removes the staged mod, restores SteamVR's theater setting, and leaves your retail F.E.A.R. untouched.",
            "Your saves live in the stage's userdata and are kept unless you add -IncludeUserData.",
            "The mod's uninstall script removes the desktop shortcut too. Note the mod folder (C:\Games\FEAR VR by default) is independent of your F.E.A.R. install - uninstalling the game alone leaves it behind.",
            "If you installed the HD textures: run their installer again and click Uninstall - it lives in the archive you downloaded from ModDB."
        )
        Tags        = @("fear", "f.e.a.r.", "first encounter assault recon", "horror", "fps", "shooter", "action", "slow-mo", "alma", "monolith", "lithtech", "psychological horror", "wip", "beta", "openxr")
    },
    @{
        Controls    = "MC"
        Title       = "Final Fantasy XIV VR"
        VideoUrl    = "https://www.youtube.com/watch?v=H9Lx7n7zFBo"
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
        VideoUrl    = "https://www.youtube.com/watch?v=aem6Sefzqao"
        SteamId     = "4000"
        Mod         = "VRMod (auto-update)"
        GithubRepo  = "Abyss-c0re/vrmod-module-master"
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
        VideoUrl    = "https://youtu.be/T2LoOFt9hiY?t=202"
        Quip        = "Pull off the heist, outrun the stars, and own the streets of Los Santos."
        SteamId     = "271590"
        Mod         = "R.E.A.L. + VRV (auto-update)"
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
        Title       = "GTA Vice City VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=UAr7gVAs1Lk"
        SteamId     = "12110"
        Quip        = "Rise through the pastel-soaked 80s and take the whole coast."
        Mod         = "Vice City VR (auto-update)"
        Description = "2003 original required"
        Author      = "#yevhen4817"
        ImprovementTag = "+ HD Model Pack"
        GithubRepo  = "dubrovskiy-yevhen-stakelogic/vice-city-vr"
        Bat         = "ViceCityVR\START_INSTALLER.bat"
        Color       = "#1b0d2b"
        Accent      = "#ff4d9e"
        InfoUrl     = "https://github.com/dubrovskiy-yevhen-stakelogic/vice-city-vr"
        DownloadUrl = "https://github.com/dubrovskiy-yevhen-stakelogic/vice-city-vr/releases"
        # reVC.exe is a full reimplementation of the game executable and
        # sits next to gta-vc.exe, which is never modified. "Start in VR"
        # must run reVC.exe - steam://rungameid would start the flat game.
        LaunchExe   = "reVC.exe"
        ModFile     = "reVC.exe"
        SteamFolder = "Grand Theft Auto Vice City"
        FallbackPaths = @("STEAM:Grand Theft Auto Vice City", "C:\Program Files\Rockstar Games\Grand Theft Auto Vice City", "C:\Program Files (x86)\Rockstar Games\Grand Theft Auto Vice City")
        UninstallSteps = @(
            "Open your Vice City game folder.",
            "Delete the files the Vice City VR archive supplied, plus 'models\vrhands'.",
            "If you installed the optional HD Model Pack, do NOT delete the game's whole 'models' folder. The pack merged files from modelsets\modern\models and modelsets\modern\txd into the game's 'models' and 'txd' folders.",
            "For every original file the HD pack replaced, the installer kept a <name>.hubbak beside it. Delete the HD replacement and rename its .hubbak copy back. Files added only by the pack can be identified from the same ZIP and deleted individually.",
            "The original executable is not changed, so Vice City keeps working in flat mode."
        )
        Tags        = @("grand theft auto", "gta", "vice city", "revc", "open world", "action", "crime", "driving", "shooter", "sandbox", "retro")
    },
    @{
        Controls    = "MC"
        Title       = "GTFO VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/live/GrhYB_AP1J8?t=1336"
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
        Title       = "Gunfire Reborn"; Roomscale=$true
        VideoUrl    = "https://youtu.be/TQTKvaMpzOE?t=411"
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
        Title       = "Halo 3 MCC VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=Hjppvu5vmZg"
        SteamId     = "976730"
        Quip        = "Finish the fight - now from inside the visor."
        Mod         = "Halo MCC VR (auto-update)"
        Description = "Halo 3 + ODST + Reach"
        Author      = "pancreations"
        GithubRepo  = "pancreations/Halo-MCC-VR"
        GithubPrerelease = $true
        Bat         = "Halo3MCCVR\START_INSTALLER.bat"
        Color       = "#0a1420"
        Accent      = "#4a90c8"
        InfoUrl     = "https://github.com/pancreations/Halo-MCC-VR/releases"
        DownloadUrl = "https://github.com/pancreations/Halo-MCC-VR/releases"
        # The mod installs into a "Halo_MCC_VR" subfolder of the MCC
        # game dir (renamed from "halo3xr" in alpha 0.1.1). The installer
        # records the real MCC path in .installed_path, and ModFile points
        # at the actual mod dll so a fresh Hub verifies the real file on
        # disk (not just a marker). LaunchExe points at the mod's own
        # launcher (anti-cheat-off VR mode) inside Halo_MCC_VR, so
        # "Start in VR" runs the mod, not the unmodded MCC via Steam.
        ModFile     = "Halo_MCC_VR\halo3xr.dll"
        LaunchExe   = "Halo_MCC_VR\halo3xr_launcher.exe"
        SteamFolder = "Halo The Master Chief Collection"
        FallbackPaths=@("STEAM:Halo The Master Chief Collection", "C:\XboxGames\Halo- The Master Chief Collection\Content", "D:\XboxGames\Halo- The Master Chief Collection\Content", "C:\Program Files\ModifiableWindowsApps\Halo- TheMasterChiefCollection", "XBOX:Halo- The Master Chief Collection")
        UninstallSteps = @(
            "Close MCC completely.",
            "Delete the 'Halo_MCC_VR' folder inside your MCC install - no MCC game files were changed, so MCC keeps working normally.",
            "Delete the 'Halo 3 MCC VR' desktop shortcut if the installer created one."
        )
        Tags=@("halo", "halo 3", "halo mcc", "master chief collection", "mcc", "pancreations", "fps", "shooter", "sci-fi", "action", "campaign", "motion controls", "6dof", "openxr")
    },
    @{
        Controls    = "MC"
        Title       = "Heretic VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=JpX6CRyRG1I"
        ImprovementTag = "+ 3D weapons mod"
        SteamId     = "2390"
        Mod         = "GZDoomVR (auto-update)"
        GithubRepo  = "hh79/gzdoomvr"
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
        Title       = "Hexen VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/jvjSAUrV1YQ?t=127"
        ImprovementTag = "+ 3D weapons mod"
        SteamId     = "2360"
        Mod         = "GZDoomVR (auto-update)"
        GithubRepo  = "hh79/gzdoomvr"
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
        Title       = "Hexen II VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/wKyfjeuv46o?t=7"
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
        VideoUrl    = "https://www.youtube.com/watch?v=zvD1lvuK_zA"
        Pill        = "HOTDR_VR_1.0"
        SteamId     = "1694600"
        Mod         = "HOTDR_VR_1.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "HouseOfTheDeadRemakeVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#180808"
        Accent      = "#cc3333"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1391730397418881067/1391730397418881067"; DownloadUrl="https://discord.com/channels/1001138422972432597/1391730397418881067/1535371792041115658"
        ModFile     = "BepInEx\plugins\TheHouseOfTheDead_VR.dll"
        # Wie bei Teil 2: die Ueberarbeitung kam als EIGENE Zusatzdateien.
        # Neu im Archiv sind HOTD1_SourceCameraFluidWeaponAuto.dll (39.936 B)
        # und HOTD1_AmmoMetricFrameLab.dll (53.760 B), beide 2026-08-07 -
        # die Haupt-DLL ist mit 139.264 B vom 2026-05-14 UNVERAENDERT.
        # Ohne Merker wuerde eine bestehende Installation nichts davon
        # mitbekommen. Geprueft wird die Kamera-/Waffendatei, weil sie das
        # Spielgefuehl betrifft; die zweite kommt im selben Paket mit.
        ModRequiredFile = "BepInEx\plugins\HOTD1_SourceCameraFluidWeaponAuto.dll"
        SteamFolder = "The House of the Dead Remake"
        FallbackPaths=@("STEAM:THE HOUSE OF THE DEAD Remake", "STEAM:House of the Dead Remake", "STEAM:TheHouseOfTheDeadRemake", "GOG:THE HOUSE OF THE DEAD Remake", "GOG:House of the Dead Remake", "GOG:The House of the Dead - Remake", "GOG:The House of the Dead Remake")
        Tags=@("house of the dead", "hotd", "hotd remake", "astienth", "rail shooter", "on-rails", "shooter", "horror", "zombies", "arcade", "remake")
    },
    @{
        Controls    = "MC"
        Title       = "House of the Dead 2 Remake VR"
        VideoUrl    = "https://youtu.be/WGaMB5IKQxs?t=243"
        Pill        = "HOTD2R_VR"
        SteamId     = "3376690"
        Mod         = "HOTD2R_VR"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "HouseOfTheDead2RemakeVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back. The mod stays on disk and is not removed.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#180808"
        Accent      = "#cc3333"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1504155922572775554/1504155922572775554"; DownloadUrl="https://discord.com/channels/1001138422972432597/1504155922572775554/1534909633393856512"
        ModFile     = "BepInEx\plugins\TheHouseOfTheDead2_VR.dll"
        # Die FPS-Korrektur kam als EIGENE Zusatzdatei im aufgefrischten
        # Archiv (HOTD2_SourceCameraFluidShooting.dll, 29.184 B, 2026-08-05).
        # Die Haupt-DLL ist dabei unveraendert geblieben, also merkt eine
        # bestehende Installation ohne diesen Merker nichts vom Update.
        ModRequiredFile = "BepInEx\plugins\HOTD2_SourceCameraFluidShooting.dll"
        SteamFolder = "THE HOUSE OF THE DEAD 2 Remake"
        FallbackPaths=@("STEAM:House of the Dead 2 Remake", "STEAM:TheHouseOfTheDead2Remake", "GOG:THE HOUSE OF THE DEAD 2 Remake", "GOG:House of the Dead 2 Remake")
        Tags=@("house of the dead 2", "hotd2", "hotd2 remake", "astienth", "rail shooter", "on-rails", "shooter", "horror", "zombies", "arcade", "remake", "sega")
    },
    @{
        Controls    = "MC"
        Title       = "Hytale VR"
        VideoUrl    = "https://packaged-media.redd.it/dfqjfl7xnrdh1/pb/m2-res_1080p.mp4?m=DASHPlaylist.mpd&var=sgpssan&v=1&e=1785114000&s=04ac52900a5b818d8c0d27510ab55f63a41316b4"
        SteamId     = ""
        PortraitUrl = "Assets/Hytale_portrait.jpg"
        HeaderUrl   = "Assets/Hytale_header.jpg"
        ScreenshotUrl = "Assets/Hytale_screenshot.jpg"
        Quip        = "Block by block, a whole world wraps around you."
        Mod         = "HytaleVR (auto-update)"
        GithubRepo  = "heurazy/HytaleVRInjector-mod"
        Description = "Own Hytale copy required"
        Author      = "heurazy"
        Bat         = "HytaleVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "Delete the 'Hytale VR' folder (default 'C:\Games\Hytale VR') and the desktop shortcut.",
            "The game itself is untouched - it lives in the Hytale Launcher's own location."
        )
        Color       = "#0a1220"
        Accent      = "#3fb0f0"
        InfoUrl     = "https://github.com/heurazy/HytaleVRInjector-mod"
        DownloadUrl = "https://github.com/heurazy/HytaleVRInjector-mod/releases/latest"
        ModFile     = "hytale_camera_dashboard.exe"
        ModFileAlt  = "Start Hytale VR.bat"
        LaunchExe   = "Start Hytale VR.bat"
        SteamFolder = "Hytale VR"
        FallbackPaths=@("C:\Games\Hytale VR", "D:\Games\Hytale VR", "E:\Games\Hytale VR", "C:\games\Hytale VR", "APPDATA:Hytale\install\release\package\game\latest\Client\HytaleClient.exe")
        Tags=@("hytale", "hytale vr", "hytalevrinjector", "heurazy", "hypixel", "sandbox", "voxel", "block", "building", "crafting", "rpg", "adventure", "exploration", "open world", "fantasy", "multiplayer", "coop")
    },
    @{
        Controls    = "MC"
        Title       = "I Can Gun VR"
        VideoUrl    = "https://www.youtube.com/watch?v=zeM9SnnDqvc"
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
        Title       = "Idols of Ash VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=Bn_Zd-X5rGw"
        SteamId     = "4450800"
        PortraitUrl = "Assets/IdolsOfAsh_portrait.jpg"
        HeaderUrl   = "Assets/IdolsOfAsh_header.jpg"
        GithubRepo  = "LXE97/UGVR-IdolsOfAsh"
        Quip        = "Sling the hook, swing the ash - the idols are waiting."
        Mod         = "IoA UGVR (auto-update)"
        Pill        = "IOA_VR"
        Description = "OpenXR, motion controls."
        Author      = "LXE97"
        Bat         = "IdolsOfAshVR\START_INSTALLER.bat"
        Color       = "#120c08"
        Accent      = "#e0762e"
        InfoUrl     = "https://github.com/LXE97/UGVR-IdolsOfAsh"
        ModFile     = "xr_injector\xr_injector.gd"
        SteamFolder = "IdolsOfAsh"
        FallbackPaths=@("STEAM:IdolsOfAsh", "APPDATA:itch\apps\idols-of-ash\idols_of_ash.exe")
        Tags=@("idols of ash", "idols", "grappling hook", "lxe97", "ugvr", "godot", "action", "adventure", "platformer", "atmospheric", "dark fantasy", "souls-like", "indie")
    },
    @{
        Controls    = "MC"
        Title       = "Iron Lung VR"
        VideoUrl    = "https://www.youtube.com/watch?v=jjFUMY_Rjfo"
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
        Tags=@("horror", "atmospheric", "underwater", "submersed", "indie", "first-person", "fan game", "narrative", "mystery", "submarine", "iron lung", "jack randolph", "david szymanski", "free")
    },
    @{
        Controls    = "MC"
        Title       = "Kerbal Space Program"
        VideoUrl    = "https://www.youtube.com/watch?v=peWifvCFzTM"
        SteamId     = "220200"
        Mod         = "KerbalVR (auto-update)"
        GithubRepo  = "FirstPersonKSP/Kerbal-VR"
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
        Title       = "Left 4 Dead 2 VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=JgIraTVFOfI"
        SteamId     = "550"
        Mod         = "L4D2VR (auto-update)"
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
        Title       = "Legend of Zelda: Ocarina of Time VR"
        VideoUrl    = "https://www.youtube.com/watch?v=bGmsg82v29k"
        Quip        = "The Hero of Time answers Hyrule's call once more."
        SteamId     = ""
        PortraitUrl = "Assets/OcarinaOfTimeVR_portrait.jpg"
        HeaderUrl   = "Assets/OcarinaOfTimeVR_header.jpg"
        ScreenshotUrl = "Assets/OcarinaOfTimeVR_screenshot.jpg"
        Mod         = "Shipwright-VR"
        Pill        = "Shipwright-VR"
        ImprovementTag = "+ HD textures + 3D backgrounds"
        Description = "N64 ROM required"
        Author      = "ShinyWindow"
        Bat         = "OcarinaOfTimeVR\START_INSTALLER.bat"
        Color       = "#0f1d10"
        Accent      = "#d8b13c"
        InfoUrl     = "https://github.com/ShinyWindow/Shipwright-VR"
        ModPageUrl  = "https://github.com/ShinyWindow/Shipwright-VR"
        DownloadUrl = "https://github.com/ShinyWindow/Shipwright-VR/releases"
        # Background update check: the Hub compares the GitHub latest
        # tag against .installed_version (written verbatim by the
        # installer), so the tile flips to Update on a new release.
        GithubRepo  = "ShinyWindow/Shipwright-VR"
        # OpenVR mod on Ship of Harkinian: soh.exe IS the game and the
        # mod in one - launched directly, never via Steam.
        ModFile     = "soh.exe"
        LaunchExe   = "soh.exe"
        SteamFolder = "Ocarina of Time VR"
        FallbackPaths=@("C:\Games\Ocarina of Time VR", "D:\Games\Ocarina of Time VR", "E:\Games\Ocarina of Time VR")
        Tags        = @("zelda", "legend of zelda", "ocarina of time", "oot", "link", "hyrule", "ship of harkinian", "soh", "shipwright", "nintendo 64", "n64", "action", "adventure", "fantasy", "exploration", "retro")
    },
    @{
        Controls    = "MC"
        Title       = "Legend of Zelda: Twilight Princess"
        Quip        = "Twilight and light, and you between them - with a sword."
        VideoUrl    = "https://www.youtube.com/watch?v=ioJsbBGZ0Cs"
        Mod         = "Dusklight VR (auto-update)"
        GithubRepo  = "JoeyAW/dusklight-vr"
        Description = "GameCube dump required"
        Author      = "JoeyAW"
        ImprovementTag = "+ 4K texture pack"
        Bat         = "TwilightPrincessVR\START_INSTALLER.bat"
        HeaderUrl     = "Assets/TwilightPrincessVR_header.jpg"
        PortraitUrl   = "Assets/TwilightPrincessVR_portrait.jpg"
        ScreenshotUrl = "Assets/TwilightPrincessVR_screenshot.jpg"
        Color       = "#141a24"
        Accent      = "#6fa8c9"
        InfoUrl     = "https://github.com/JoeyAW/dusklight-vr"
        ModPageUrl  = "https://github.com/JoeyAW/dusklight-vr"
        DownloadUrl = "https://github.com/JoeyAW/dusklight-vr/releases"
        # EIGENSTAENDIG wie Ocarina of Time VR - es gibt kein Spiel zum
        # Patchen. Die Exe liegt in einem Unterordner des Archivs, nicht
        # in der Wurzel: windows-msvc-relwithdebinfo\dusklight.exe.
        SteamFolder = "Twilight Princess VR"
        ModFile     = "windows-msvc-relwithdebinfo\dusklight.exe"
        LaunchExe   = "windows-msvc-relwithdebinfo\dusklight.exe"
        FallbackPaths=@("C:\Games\Twilight Princess VR", "D:\Games\Twilight Princess VR", "E:\Games\Twilight Princess VR")
        Notice      = "You supply the game: this port ships no game data and needs your own dump of the GameCube release as .iso or .rvz. The download is over 500 MB and unpacks to about 2 GB, because the author ships his whole build folder. Tested on Quest 2 and 3 only; cutscenes are best watched in flatscreen."
        NoticeUrl   = "https://discord.gg/CxQJ9PjnjA"
        NoticeUrlLabel = "Discord for bugs and help"
        UninstallSteps = @(
            "Delete the folder you installed it into - everything lives there, including your settings. Nothing was added anywhere else.",
            "Delete the 'Twilight Princess VR' shortcut from your desktop.",
            "Your own game dump is your file and is untouched - keep it wherever you put it."
        )
        Tags=@("zelda", "legend of zelda", "twilight princess", "link", "midna", "hyrule", "dusklight", "joeyaw", "gamecube", "nintendo", "action", "adventure", "fantasy", "exploration", "wip")
    },
    @{
        Controls    = "MC"
        Title       = "Lethal Company VR"
        VideoUrl    = "https://www.youtube.com/watch?v=nrLkksXZVAo"
        SteamId     = "1966720"
        Mod         = "LCVR (auto-update)"
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
        VideoUrl    = "https://www.youtube.com/watch?v=Jveom7RoU3E"
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
        Title       = "Lunacid VR"
        Quip        = "Descend the Great Well with a blade in your own hand."
        SteamId     = "1745510"
        VideoUrl    = "https://youtu.be/ZH_rlknZaBk?t=2365"
        Mod         = "Lunacid VR v0.7.3"
        Description = "SteamVR only, Nexus download"
        Author      = "Tesseract"
        Bat         = "LunacidVR\START_INSTALLER.bat"
        Color       = "#0b0a16"
        Accent      = "#9d8fd8"
        InfoUrl     = "https://www.nexusmods.com/lunacid/mods/23"
        ModPageUrl  = "https://www.nexusmods.com/lunacid/mods/23"
        DownloadUrl = "https://www.nexusmods.com/lunacid/mods/23?tab=files"
        ModFile     = "BepInEx\plugins\LUNACID VR\LUNACIDVR.dll"
        # No LaunchExe on purpose: Lunacid is a Steam-only release, so the
        # Hub's steam://rungameid route is the one that always works and
        # brings Steam up with it. Detection runs on SteamFolder + ModFile.
        SteamFolder = "Lunacid"
        UninstallSteps = @(
            "Open your Lunacid folder and delete BepInEx\plugins\LUNACID VR\LUNACIDVR.dll - the game is flat again.",
            "The installer backed up every game file it replaced as <name>.hubbak; restore those to get the folder exactly as it was.",
            "BepInEx itself can stay - other Lunacid mods need it."
        )
        Tags=@("lunacid", "dungeon crawler", "dark fantasy", "rpg", "souls-like", "horror", "atmospheric", "exploration", "first person", "retro", "psx", "kings field", "moon", "magic", "steamvr", "tesseract")
    },
    @{
        Controls    = "MC"
        Title       = "Mage Arena VR"
        VideoUrl    = "https://www.youtube.com/watch?v=MBElDKZgTYU"
        VideoLabel  = "Watch gameplay"
        SteamId     = "3716600"
        PortraitUrl = "Assets/MageArenaVR_portrait.jpg"
        HeaderUrl   = "Assets/MageArenaVR_header.jpg"
        Mod         = "MA VR (auto-update)"
        Description = "SteamVR required, Co-op"
        Author      = "J_axon"
        Bat         = "MageArenaVR\START_INSTALLER.bat"
        Color       = "#1a1030"
        Accent      = "#8b6ce8"
        InfoUrl     = "https://thunderstore.io/c/mage-arena/p/J_axon/MAVR/"
        ModPageUrl  = "https://thunderstore.io/c/mage-arena/p/J_axon/MAVR/"
        DownloadUrl = "https://thunderstore.io/package/download/J_axon/MAVR/1.0.0/"
        # Thunderstore auto-update: the Hub compares latest.version_number
        # from the API against BepInEx\.ts_versions\J_axon-MAVR, which the
        # installer writes after every successful install.
        ThunderstoreAuthor  = "J_axon"
        ThunderstorePackage = "MAVR"
        # BepInEx 5 plugin - the mod also ships a preloader patcher, so
        # BepInEx 6 cannot load it.
        ModFile     = "BepInEx\plugins\MageArenaVR\MageArenaVR.dll"
        SteamFolder = "Mage Arena"
        LaunchExe   = "MageArena.exe"
        FallbackPaths = @("STEAM:Mage Arena")
        UninstallSteps = @(
            "Open your Mage Arena game folder.",
            "Delete 'BepInEx\plugins\MageArenaVR\' and 'BepInEx\patchers\MageArenaVR\'.",
            "To remove BepInEx itself too, delete 'winhttp.dll' and the whole 'BepInEx' folder.",
            "The base game is untouched and keeps working in flat mode."
        )
        Tags        = @("mage arena", "mavr", "j_axon", "magic", "spells", "wizard", "pvp", "multiplayer", "coop", "arena", "fantasy", "comedy")
    },
    @{
        Controls    = "MC"
        Title       = "Metal: Hellsinger VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=tsowpUxGI9s"
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
        VideoUrl    = "https://www.youtube.com/watch?v=BqSIr_sC7LI"
        SteamId     = ""
        PortraitUrl = "Assets/MetroidPrimeVR_portrait.jpg"
        HeaderUrl   = "Assets/MetroidPrimeVR_header.jpg"
        ScreenshotUrl = "Assets/MetroidPrimeVR_screenshot.jpg"
        Quip        = "Scan the unknown, lock on, and let the arm cannon do the talking."
        Mod         = "PrimedGun (auto-update)"
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
        VideoUrl    = "https://www.youtube.com/watch?v=Zom0zmwPwk0"
        SteamId     = "1605250"
        Mod         = "MorosProtocol_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "MorosProtocolVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "Delete the renamed file plus 'BepInEx\' and 'winhttp_bak.dll' for a full uninstall.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
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
        VideoUrl    = "https://www.youtube.com/watch?v=zhWjw3mT46o"
        SteamId     = "2416450"
        Mod         = "MousePI_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "MousePIVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "Delete the renamed file plus 'BepInEx\' and 'winhttp_bak.dll' for a full uninstall.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#141210"
        Accent      = "#c9a24b"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1523984295633490031/1523984342077014069"; DownloadUrl="https://discord.com/channels/1001138422972432597/1523984295633490031/1528716538314756278"
        ModFile     = "BepInEx\plugins\MousePI_VR.dll"
        # Die ueberarbeitete Fassung (Controller-Vibration, behobene
        # Sticks, Nachlade- und Trittgeste, korrigiertes Schwimmen) hat
        # KEINE neue Datei mitgebracht - nur die Haupt-DLL ist neuer
        # (151.040 B, 2026-07-20). Deshalb hier ein Zeitstempel statt
        # einer Pflichtdatei: ist die installierte DLL aelter, meldet
        # die Kachel ein Update.
        ModBuildStamp = "2026-07-20 00:00"
        SteamFolder = "MOUSE"
        FallbackPaths=@("STEAM:MOUSE", "STEAM:Mouse", "STEAM:MOUSE P.I. For Hire", "C:\XboxGames\MOUSE P.I. For Hire\Content", "XBOX:MOUSE P.I. For Hire")
        Tags=@("mouse", "mouse pi", "p.i.", "for hire", "jack pepper", "detective", "noir", "fps", "shooter", "boomer shooter")
    },
    @{
        Controls    = "MC"
        Title       = "My Friendly Neighborhood VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=ZYPMCYqO4bA"
        Quip        = "Ricky is still on the air, and he still wants you to stay."
        SteamId     = "1574260"
        Mod         = "MFNVR (auto-update)"
        Description = "Set field of view to ~100"
        Author      = "LeviGaming1248"
        Bat         = "MFNVR\START_INSTALLER.bat"
        Color       = "#1b1210"
        Accent      = "#c8452e"
        InfoUrl     = "https://github.com/LeviGaming1248/MyFriendlyNeighborhoodVR"
        # Repo UMBENANNT: LeviGaming1248/MFNVR leitet auf
        # MyFriendlyNeighborhoodVR um. GitHub folgt der Umleitung noch, aber
        # der neue Name steht direkt hier, damit es nicht an dem Tag bricht,
        # an dem die Umleitung wegfaellt. Dort gibt es ein stabiles Release
        # (v0.2.0), die Prerelease-Flagge braucht dieser Eintrag also nicht.
        GithubRepo  = "LeviGaming1248/MyFriendlyNeighborhoodVR"
        ModFile     = "BepInEx\plugins\MFNVR.dll"
        # DER AUTOR ERSETZT DEN ANHANG, OHNE DEN TAG ZU AENDERN. Am
        # 2026-08-10 kam ein deutlich neuer Build - Werkzeugkiste, grosse
        # Leistungsverbesserungen, Kamera in Zwischensequenzen, physisches
        # Waffenwechseln - und das Release heisst weiterhin v0.2.0 mit dem
        # Anhang MFNVR-v0.2.0.zip. Der Tag-Vergleich gegen GitHub kann das
        # also NICHT sehen. ModBuildStamp ist der Zeitstempel, den
        # BepInEx\plugins\MFNVR.dll IM Archiv traegt (39.424 Bytes) und den
        # das Entpacken erhaelt - jede Installation dieses Builds liest
        # denselben Wert, jeder aeltere liest frueher. BEI JEDEM NEUEN
        # BUILD MITZIEHEN, auch wenn der Tag gleich bleibt.
        ModBuildStamp = "2026-08-10 16:45"
        GameExe     = "My Friendly Neighborhood.exe"
        SteamFolder = "My Friendly Neighborhood"
        FallbackPaths=@("EPIC:MyFriendlyNeighborhood", "EPIC:My Friendly Neighborhood", "XBOX:My Friendly Neighborhood", "C:\XboxGames\My Friendly Neighborhood\Content")
        Tags=@("my friendly neighborhood", "mfn", "mfnvr", "levigaming1248", "horror", "survival", "shooter", "action", "puppets", "atmospheric")
    },
    @{
        Controls    = "MC"
        Title       = "Outer Wilds VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/H931NNLw8z4?t=132"
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
        VideoUrl    = "https://youtu.be/ugs3_d3pyoU?t=229"
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
        Title       = "Painkiller Black Edition"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=RfNqYTfipaA"
        Quip        = "Purgatory's finest arsenal, now at the end of your own hands."
        SteamId     = "39530"
        Mod         = "PainkillerVR (auto-update)"
        Description = "Motion controls."
        Author      = "FluorescentHallucinogen"
        Bat         = "PainkillerBlackVR\START_INSTALLER.bat"
        Color       = "#160808"
        Accent      = "#b52a24"
        InfoUrl     = "https://github.com/FluorescentHallucinogen/painkiller-vr-mod"
        # Update badge: the Hub compares the GitHub latest tag against
        # .installed_version (written verbatim from tag_name by the
        # installer), so the tile flips to Update on a new release.
        GithubRepo  = "FluorescentHallucinogen/painkiller-vr-mod"
        ModFile     = "Bin\openxr_loader.dll"
        SteamFolder = "Painkiller Black Edition"
        FallbackPaths=@("STEAM:Painkiller Black Edition", "GOG:Painkiller Black", "C:\GOG Games\Painkiller Black")
        Tags=@("painkiller", "black edition", "people can fly", "fluorescenthallucinogen", "fps", "shooter", "action", "horror", "retro", "fast paced")
    },
    @{
        Controls    = "MC"
        Title       = "Panzer Dragoon Remake"
        VideoUrl    = "https://www.youtube.com/watch?v=tIqKJ3-vjHU"
        Pill        = "PANZER_DR_VR"
        SteamId     = "1178880"
        Mod         = "PD Remake v1.0"
        Description = "bHaptics + Provolver support"
        Author      = "Astienth"
        Bat         = "PanzerDragoonRemakeVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#0a1018"
        Accent      = "#aa6644"
        InfoUrl     = "https://github.com/Astienth/Panzer_Dragoon_Remake_VR_bHaptics_Provolver"
        ModFile     = "BepInEx\plugins\PanzerDragoonRemakeVR.dll"
        # !!! DER AUTOR HAT DAS ARCHIV AM 2026-08-06 UNTER DEMSELBEN TAG (1.0)
        # AUSGETAUSCHT - DIE VERSIONSNUMMER AENDERT SICH ALSO NICHT !!!
        # Neu darin: BepInEx\patchers\PDRReflectionFix.Patcher.dll (15.360 B)
        # und eine ueberarbeitete Lizenzdatei. Die eigentliche Mod-DLL ist
        # unveraendert (796.672 B, 2025-01-23).
        # Ohne diese Zeile wuerde niemand, der vorher installiert hat, je von
        # dem Patcher erfahren: die Kachel zeigt "VR Ready" und die Moddatei
        # liegt ja da. Der Merker greift genau dort - Mod vorhanden, neue
        # Pflichtdatei fehlt -> Update.
        ModRequiredFile = "BepInEx\patchers\PDRReflectionFix.Patcher.dll"
        SteamFolder = "Panzer Dragoon Remake"
        FallbackPaths=@("STEAM:PanzerDragoonRemake", "STEAM:Panzer Dragoon Remake Demo", "GOG:Panzer Dragoon Remake")
        Tags=@("panzer dragoon", "panzer dragoon remake", "astienth", "rail shooter", "shmup", "dragon", "sega", "saturn", "remake", "provolver", "protubevr", "bhaptics", "fantasy", "arcade")
    },
    @{
        Controls    = "MC"
        Title       = "PEAK VR"
        VideoUrl    = "https://www.youtube.com/watch?v=AUKrEF7mNB4"
        SteamId     = "3527290"
        Mod         = "PeakVR (auto-update) + Depot"
        Description = "Coop climbing, 2 mods"
        Author      = "Andrey04o / AstienVR"
        PortraitUrl = "Assets/PEAKVR_portrait.jpg"
        HeaderUrl   = "https://cdn.cloudflare.steamstatic.com/steam/apps/3527290/library_hero.jpg"
        Bat         = "PEAKVR\START_INSTALLER.bat"
        Color       = "#0a1a14"
        Accent      = "#3da876"
        InfoUrl     = "https://thunderstore.io/c/peak/p/Andrey04o/PeakVR/"
        # ModFile is the CURRENT mod (PeakVR by Andrey04o) inside the
        # normal Steam copy - that is what the installer writes and what
        # the auto-update tracks. ModFileAlt is the OLD mod (PEAK_VR by
        # AstienVR), which only ever exists in the pinned depot build.
        ModFile     = "BepInEx\plugins\Andrey04o-PeakVR\com.andrey04o.PeakVR.dll"
        # Wer PeakVR VOR dem 2026-08-13 ueber den Hub installiert hat, dem
        # fehlen zwei Pflichtpakete (MonoDetour_BepInEx_5, SoftDependencyFix) -
        # unsere Paketliste kannte sie nicht. Die Version der Hauptmod hat sich
        # dadurch NICHT geaendert, es gaebe also kein Update-Zeichen.
        # Diese Merkerdatei schreibt der Installer selbst beim Installieren von
        # SoftDependencyFix. Fehlt sie, ist die Installation unvollstaendig und
        # der Hub zeigt "Update".
        ModRequiredFile = "BepInEx\.ts_versions\PEAKModding-SoftDependencyFix"
        ModFileAlt  = "BepInEx\plugins\PEAK_VR.dll"
        SteamFolder = "PEAK"
        # The depot build sits outside the Steam library, so without this
        # the scan never looks there at all - the entry had no
        # FallbackPaths whatsoever. Depot folder first, same as Bendy.
        FallbackPaths = @("C:\Games\PEAK VR", "STEAM:PEAK")
        ThunderstoreAuthor  = "Andrey04o"
        ThunderstorePackage = "PeakVR"
        # DualMode: two mods that need two different game builds. The
        # current one lives in the Steam library and auto-updates from
        # Thunderstore; the older PEAK_VR needs the pinned depot build
        # 1.44.a in its own folder. With both on disk the Hub shows the
        # 3-way split button (Start Current / Start Depot / Reinstall).
        # This is the same shape R.E.P.O. VR uses - NOT TwoMods, which
        # is for two mods inside ONE install.
        DualMode        = $true
        DepotPath       = "C:\Games\PEAK VR"
        DepotLaunchExe  = "PEAK.exe"
        DepotLaunchArgs = "-force-vulkan"
        Tags=@("peak", "peakvr", "climbing", "coop", "multiplayer", "comedy", "survival", "scout", "mountain", "landfall", "andrey04o", "astienvr", "astienth")
    },
    @{
        Controls    = "MC"
        Title       = "Penumbra: Overture VR"
        VideoUrl    = "https://www.youtube.com/watch?v=FCbwW119lAw"
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
        VideoUrl    = "https://youtu.be/APpDgSHR-b0?t=145"
        Pill        = "Perfect_DarkVR"
        SteamId     = ""
        PortraitUrl = "Assets/PerfectDarkVR_portrait.jpg"
        HeaderUrl   = "Assets/PerfectDarkVR_header.jpg"
        ScreenshotUrl = "Assets/PerfectDarkVR_screenshot.jpg"
        Quip        = "Joanna Dark goes hands-on - dataDyne never saw it coming."
        Mod         = "PerfectDarkVR (auto-update)"
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
        Title       = "Portal 2 VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/OnFCTqKJP80?t=73"
        SteamId     = "620"
        Mod         = "Portal2VR (auto-update)"
        GithubRepo  = "Spencer0187/portal2vr-roomscale"
        Description = "Motion controls, roomscale."
        Author      = "Spencer0187"
        Bat         = "Portal2VR\START_INSTALLER.bat"
        Color       = "#0a1a2a"
        Accent      = "#ff6600"
        InfoUrl     = "https://github.com/Spencer0187/portal2vr-roomscale"
        ModFile     = "VR\manifest.vrmanifest"
        SteamFolder = "Portal 2"
        FlatVREnabled  = "bin\openvr_api.dll"
        FlatVRDisabled = "bin\openvr_api.dll-"
        Tags=@("portal2", "portal 2", "comedy", "puzzle", "story")
    },
    @{
        Controls    = "MC"
        Title       = "Quake VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=lAlJubb64g0"
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
        VideoUrl    = "https://www.youtube.com/watch?v=Zl7a98MBgus"
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
        Title       = "Quake 3 VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=8tOLAvJST3Y"
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
        VideoUrl    = "https://www.youtube.com/watch?v=FXFoHlLpzG0"
        SteamId     = "3241660"
        Mod         = "RepoXR (auto-update)"
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
        VideoUrl    = "https://www.youtube.com/watch?v=iwnL873U1n0"
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
        VideoUrl    = "https://www.youtube.com/watch?v=BsZ1-oqZszE"
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
        VideoUrl    = "https://www.youtube.com/watch?v=uHYr8ICPzRo"
        ModReleasedAt = "2026-06-15"
        # Exact update check. The .pak carries the modder's build time
        # inside the Nexus zip (2026-06-15 13:10, 299,048,886 bytes) and
        # extraction keeps it, so every install of file 1031 reads the same
        # stamp no matter when it was installed, and any older VRO pak reads
        # earlier. ModReleasedAt above cannot manage that on its own - it
        # falls back on the install moment and has a 7-day grace. Bump this
        # whenever a newer pak goes up.
        ModBuildStamp = "2026-06-15 13:10"
        Quip        = "Stack up, breach with caution, and bring every officer home."
        SteamId     = "1144200"
        Mod         = "VRO Mod 1031"
        Description = "Nexus login required"
        Author      = "VR Oasis & KITT"
        Bat         = "ReadyOrNotVR\START_INSTALLER.bat"
        Color       = "#0b0e12"
        Accent      = "#c79a3e"
        InfoUrl     = "https://www.nexusmods.com/readyornot/mods/6914"
        ModFile     = "ReadyOrNot\Content\Paks\pakchunk98-VR_OR_NOT_P.pak"
        SteamFolder = "Ready Or Not"
        # DualMode: two installable variants - the mod on the Steam copy
        # the user already owns, AND a pinned-depot build of its own under
        # C:\Games\Ready or Not VR. When both exist the Hub shows a 3-way
        # split button. No auto-update: the manifest is pinned in the
        # installer.
        DepotInstall    = $true
        DualMode        = $true
        DepotPath       = "C:\Games\Ready or Not VR"
        DepotLaunchExe  = "ReadyOrNot.exe"
        # Outside the Steam library there is no launch-options field and no
        # DirectX dropdown, so BOTH have to be passed here. -dx11 is what
        # Steam's "DirectX 11" entry does for this game; the other three are
        # what the VR mod needs. Manual VR entry (press U in-game) - the
        # installer can put -autoVR on the desktop shortcut, but this button
        # stays on the plain set.
        DepotLaunchArgs = "-dx11 -usehmd -VRTweaks -VRMappings"
        FallbackPaths   = @("STEAM:Ready Or Not", "C:\Games\Ready or Not VR")
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
        VideoUrl    = "https://youtu.be/J_JQUEJV5kQ?t=85"
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
        Tags=@("receiver", "receivr", "wolfire", "shadowbrian", "shooter", "fps", "survival", "simulation", "7dfps", "guns", "free")
    },
    @{
        Controls    = "MC"
        Title       = "Richard Burns Rally VR"
        SteamFolder = "Richard Burns Rally"
        VideoUrl    = "https://youtu.be/i8Y4nFo5OxA?t=69"
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
        VideoUrl    = "https://youtu.be/wV1_MFR_JfI?t=263"
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
        VideoUrl    = "https://www.youtube.com/watch?v=PrXRmBkOxF0"
        SteamId     = "1963610"
        Mod         = "VR Mod (auto-update)"
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
        VideoUrl    = "https://youtu.be/0i5ciO0tsEc?t=154"
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
    # WIEDER AKTIV. Der Eintrag lag ausgeklammert, "bis eine Mod-Version zu
    # einem beschaffbaren Spielbuild passt" - genau das ist jetzt der Fall:
    # der Installer laedt ueber das Depot GENAU Build 22163681, gegen den
    # die Mod v1.17.0 gebaut ist. Vorher stand dort das Manifest des
    # NEUESTEN Builds, deshalb lief es bei uns nicht.
    @{
        Controls    = "MC"
        Title       = "Scrap Mechanic VR"; Roomscale=$true
        Quip        = "Build it, then climb inside and grab the wrench yourself."
        SteamId     = "387990"
        # KEIN AUTO-UPDATE. Die Mod ist an Steam-Build 22163681 gebunden,
        # den der Installer per Depot holt. Eine kuenftige Mod-Version wird
        # sehr wahrscheinlich einen ANDEREN Build verlangen - dann muessen
        # Manifest und Mod zusammen angefasst werden, nicht die Mod allein.
        # Deshalb ist die Version hier festgeschrieben und GithubRepo ist
        # bewusst NICHT gesetzt: kein Online-Check, keine Update-Kachel,
        # die zu einem Stand fuehrt, der auf diesem Build nicht laeuft.
        Mod         = "Native VR v1.17.0"
        Description = "Steam depot build required"
        Author      = "21Suspect"
        Bat         = "ScrapMechanicVR\START_INSTALLER.bat"
        Color       = "#101a2e"
        Accent      = "#f0a022"
        InfoUrl     = "https://github.com/21Suspect/Scrap-Mechanic-Native-VR"
        ModPageUrl  = "https://github.com/21Suspect/Scrap-Mechanic-Native-VR"
        DownloadUrl = "https://github.com/21Suspect/Scrap-Mechanic-Native-VR/releases/latest"
        # Our installer downloads a known release tag and records it in
        # .installed_version, so the update badge runs off a real value.
        # Manual install (no exe patcher): the installer copies the mod's
        # payload into the game folder and writes the launch bat below,
        # which runs Start-NativeVR.ps1 - it sets $env:SteamAppId and
        # starts the OpenXR runtime, then the game. That bat is the launch
        # target; launching the flat exe gives "SteamAPI Init failed".
        # VR-Ready detection uses ModFile above (in the detected folder).
        ModFile     = "Release\scrap_native_vr.addon64"
        SteamFolder = "Scrap Mechanic"
        LaunchExe   = "NativeVR\Start Scrap Mechanic VR.bat"
        # Das Spiel kommt NUR ueber diese Bat in VR hoch: sie setzt die
        # Steam-App-Id und startet die OpenXR-Runtime. Und die Depot-Kopie
        # liegt gar nicht in der Steam-Bibliothek - steam://rungameid wuerde
        # die RETAIL-Kopie flach starten. Also lieber sagen, dass der
        # Starter fehlt, als still das falsche Spiel oeffnen.
        NeverSteamLaunch = $true
        # KEIN VideoLabel: der Standard ist "Watch VR gameplay", und genau das
        # ist es hier. Das Feld setzt man nur bei Eintraegen, deren einziges
        # Material FLACHES Gameplay ist.
        VideoUrl    = "https://www.youtube.com/watch?v=jzslO2oT12I"
        FallbackPaths = @("STEAM:Scrap Mechanic", "C:\Games\Scrap Mechanic VR", "D:\Games\Scrap Mechanic VR", "E:\Games\Scrap Mechanic VR")
        # Der Eintrag hatte KEINE Deinstallationsliste. Wichtig hier, weil
        # die Nutzlast nicht nur Dateien HINZUFUEGT, sondern acht
        # Original-Lua-Skripte des Spiels UEBERSCHREIBT - und zwar ohne
        # .hubbak-Sicherung, weil sie per robocopy /E ueber den Spielbaum
        # gelegt werden. Loeschen der neuen Dateien genuegt also nicht.
        # Die Deinstallation ist hier kurz, WEIL es nur den Depot-Weg gibt:
        # der Hub legt eine SEPARATE Spielkopie an und arbeitet nur in der.
        # Alles, was die Mod anfasst - auch die neun ersetzten Lua-Skripte -
        # liegt in diesem einen Ordner. Loeschen genuegt, es gibt nichts
        # zurueckzusetzen und keine Integritaetspruefung anzustossen.
        UninstallSteps = @(
            "Close the game.",
            "Delete the folder the Hub installed into - C:\Games\Scrap Mechanic VR, or wherever you pointed it. That folder holds nothing but the separate game copy and the VR files.",
            "Delete the 'Scrap Mechanic VR' desktop shortcut.",
            "Your normal Steam copy of Scrap Mechanic was never modified, so there is nothing to undo there - no file verification, no restoring scripts. Worlds and blueprints are stored outside the game folder and are unaffected."
        )
        Tags        = @("scrap mechanic", "building", "sandbox", "survival", "crafting", "vehicles", "creative", "physics", "openxr", "quest")
    },
    @{
        Controls    = "MC"
        Title       = "Selaco VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=23aJdITsezE"
        VideoLabel  = "Watch gameplay"
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
        VideoUrl    = "https://www.youtube.com/watch?v=wvYcMAlmI40"
        SteamId     = "433340"
        Mod         = "SRVR (auto-update)"
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
        VideoUrl    = "https://www.youtube.com/watch?v=bS3k4UF4zaw"
        SteamId     = "2607870"
        Mod         = "Slyders_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "SlydersVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "Delete the renamed file plus 'BepInEx\' and 'winhttp_bak.dll' for a full uninstall.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
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
        Title       = "Stardew Valley VR"
        Quip        = "Tend the farm in first person, then swing the scythe with your own arm."
        SteamId     = "413150"
        VideoUrl    = "https://youtu.be/Bv7ZgCPmLt8"
        Mod         = "Stardew3D VR"
        Description = "Nexus downloads required"
        Author      = "GingasVR"
        SupportUrl  = "https://www.patreon.com/c/gingasvr/membership"
        SupportText = "GingasVR develops this mod. If you enjoy it, consider supporting them:"
        Bat         = "StardewValleyVR\START_INSTALLER.bat"
        Color       = "#101a10"
        Accent      = "#7cb342"
        InfoUrl     = "https://www.nexusmods.com/stardewvalley/mods/49812"
        ModPageUrl  = "https://www.nexusmods.com/stardewvalley/mods/49812"
        DownloadUrl = "https://www.nexusmods.com/stardewvalley/mods/49812?tab=files"
        ModFile     = "Mods\Stardew3D\Stardew3D.dll"
        LaunchExe   = "StardewModdingAPI.exe"
        SteamFolder = "Stardew Valley"
        FallbackPaths=@("C:\GOG Games\Stardew Valley",
                        "C:\Program Files (x86)\GOG Galaxy\Games\Stardew Valley",
                        "C:\XboxGames\Stardew Valley\Content",
                        "C:\Program Files\ModifiableWindowsApps\Stardew Valley")
        UninstallSteps = @(
            "Open your Stardew Valley folder and go into Mods.",
            "Delete the 'Stardew3D' folder - the game goes straight back to 2D.",
            "SMAPI and Generic Mod Config Menu can stay; other mods need them."
        )
        Tags        = @("stardew valley", "stardew", "farming", "simulation", "rpg", "life sim", "cozy", "sandbox", "fishing", "mining", "crafting", "coop", "multiplayer", "pixel", "gingasvr", "smapi", "wip")
    },
    @{
        Controls    = "MC"
        Title       = "Strife VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/iItiDXfzIXc?t=258"
        VideoLabel  = "Watch gameplay"
        ImprovementTag = "+ 3D weapons mod"
        SteamId     = "317040"
        Mod         = "GZDoomVR (auto-update)"
        GithubRepo  = "hh79/gzdoomvr"
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
        VideoUrl    = "https://youtu.be/XAJC4XRomSA?t=34"
        SteamId     = "264710"
        Mod         = "SubmersedVR (auto-update)"
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
        VideoUrl    = "https://youtu.be/ABv9LFxQPSE?t=461"
        SteamId     = "848450"
        Mod         = "Submersed (auto-update)"
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
        VideoUrl    = "https://www.youtube.com/watch?v=0NpHeqOV6uw"
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
        Title       = "Tomb Raider 1 VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=SD8TSiUA6Jw"
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
        VideoUrl    = "https://www.youtube.com/watch?v=U2GRZOlcKgY"
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
        Title       = "Total Chaos VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/Y_faIycnKGU?t=219"
        VideoLabel  = "Watch gameplay"
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
        VideoUrl    = "https://www.youtube.com/watch?v=p2Wkt6sAHDo"
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
        Title       = "ULTRAKILL VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/7f2uciU6NuI?t=46"
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
        Title       = "Valheim VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=6iUkPug6QV4"
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
        Title       = "Wolfenstein 3D VR"
        VideoUrl    = "https://youtu.be/1X4_tKKYkYA?t=96"
        Quip        = "Storm Castle Wolfenstein in true stereoscopic 3D."
        SteamId     = "2270"
        Mod         = "WolfSharp VR"
        Description = "Free itch.io download"
        Author      = "Ben McLean"
        Bat         = "Wolfenstein3DVR\START_INSTALLER.bat"
        Color       = "#1a1410"
        Accent      = "#b23a2e"
        InfoUrl     = "https://benmclean.itch.io/wolfsharp"
        ModPageUrl  = "https://benmclean.itch.io/wolfsharp"
        DownloadUrl = "https://benmclean.itch.io/wolfsharp"
        ModFile     = "BenMcLean.Wolf3D.VR.exe"
        LaunchExe   = "BenMcLean.Wolf3D.VR.exe"
        # Detect the BASE game (Wolfenstein 3D, App 2270) so the tile
        # shows it as present and offers "Install VR Mod". SteamFolder
        # catches the Steam copy; the store fallbacks catch GOG / Xbox /
        # Bethesda. The VR mod (WolfSharp) installs to C:\Games\Wolfenstein
        # 3D - its .installed_path marker + ModFile there flip the tile to
        # VR Ready. The flat game is DOSBox; launch goes via .launch_exe.
        SteamFolder = "Wolfenstein 3D"
        FallbackPaths=@("GOG:Wolfenstein 3D", "XBOX:Wolfenstein 3D",
                        "C:\Program Files (x86)\Bethesda.net Launcher\games\Wolfenstein 3D",
                        "C:\Games\Wolfenstein 3D", "D:\Games\Wolfenstein 3D", "E:\Games\Wolfenstein 3D")
        Tags        = @("wolfenstein", "wolf3d", "wolfsharp", "fps", "shooter", "action", "retro", "classic", "boomer shooter", "id software", "apogee", "1992", "openxr")
    },
    @{
        Controls    = "MC"
        Title       = "World of Warcraft VR"
        VideoUrl    = "https://www.youtube.com/watch?v=mTSoR9WUCr4"
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
    @{ Controls="GP"; Title="Alba VR"; VideoUrl="https://www.youtube.com/watch?v=24XYvVYDqC0"; SteamId="1337010"; Mod="AlbaVR v1.0.0"; SteamFolder="Alba - A Wildlife Adventure"; FallbackPaths=@("GOG:ALBA A Wildlife Adventure", "GOG:Alba A Wildlife Adventure", "EPIC:Alba", "EPIC:Alba - A Wildlife Adventure"); Description="KB`&Mouse or Gamepad VR."; Author="wouterpleizier"; Bat="AlbaVR\START_INSTALLER.bat"; Color="#0a1a0a"; Accent="#5cc8e6"; InfoUrl="https://github.com/wouterpleizier/AlbaVR"; Tags=@("alba", "wildlife", "atmospheric", "exploration", "walking sim") ; ModFile="BepInEx\plugins\AlbaVR.dll" },
    @{ Controls="GP"; Title="Another Crab's Treasure"; VideoUrl="https://www.youtube.com/live/KG6cs-MLR9g?t=4469"; Pill="ACT_VR"; SteamId="1887840"; Mod="AnotherCrabs v1.0"; SteamFolder="Another Crab's Treasure"; FallbackPaths=@("STEAM:Another Crabs Treasure", "STEAM:AnotherCrabsTreasure"); GameExe="AnotherCrabsTreasure.exe"; Description="Discord login, depth only"; Author="Astienth"; Bat="AnotherCrabsTreasureVR\START_INSTALLER.bat"; Color="#0a1418"; Accent="#33aacc"; InfoUrl="https://discord.com/channels/1001138422972432597/1262749418981949483/1262749418981949483"; Tags=@("another crabs treasure", "another crab's treasure", "anothercrabstreasure", "astienth", "aggro crab", "souls-like", "underwater", "indie", "action rpg", "3d platformer", "depth"); ModFile="BepInEx\plugins\UnityVR_AnotherCrabTreasure.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="Apollo Justice: Ace Attorney Trilogy VR"; VideoUrl="https://youtu.be/m31oG_CUQsc?t=2782"; VideoLabel="Watch gameplay"; Quip="Objection! The courtroom has never felt this real."; SteamId="2187220"; Mod="REF (auto-update)"; SteamFolder="Apollo Justice Ace Attorney Trilogy"; FallbackPaths=@("STEAM:ApolloJustice", "GOG:Apollo Justice Ace Attorney Trilogy"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="GS456.exe"; Color="#1a0a0a"; Accent="#990033"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("apollo justice", "reframework", "praydog", "narrative", "puzzle", "story"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Art of Rally VR"; VideoUrl="https://youtu.be/-yxQp4tgNdM?t=15"; SteamId="550320"; Mod="ArtOfRally_VR v1.0.0"; SteamFolder="artofrally"; FallbackPaths=@("STEAM:Art of Rally", "STEAM:ArtOfRally", "GOG:art of rally", "EPIC:ArtOfRally"); Description="Discord login, experimental"; Author="Astienth"; Bat="ArtOfRallyVR\START_INSTALLER.bat"; Color="#180a0a"; Accent="#dd5544"; InfoUrl="https://discord.com/channels/1001138422972432597/1306503565698662462/1306503565698662462"; DownloadUrl="https://discord.com/channels/1001138422972432597/1306503565698662462/1520491407280832652"; Tags=@("art of rally", "artofrally", "astienth", "funselektor", "rally", "racing", "top down", "stylized", "indie", "arcade", "cars", "depth"); ModFile="BepInEx\plugins\ArtOfRally_VR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{
        Controls    = "GP"
        Title       = "Assassin's Creed Mirage VR"
        VideoUrl    = "https://www.youtube.com/watch?v=mKoQzCx4Gq8"
        SteamId     = "3035570"
        Quip        = "Nothing is true, everything is permitted. Welcome to Baghdad."
        Mod         = "AnvilEngine2VR (auto-update)"
        GithubRepo  = "mutars/anvilengine2vr"
        Description = "OpenXR or OpenVR choice"
        Author      = "mutars"
        Bat         = "ACMirageVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "Delete dxgi.dll (and openvr_api.dll, if present) from the game folder.",
            "Nothing else is touched."
        )
        Color       = "#151008"
        Accent      = "#d8a03c"
        InfoUrl     = "https://github.com/mutars/anvilengine2vr"
        ModPageUrl  = "https://github.com/mutars/anvilengine2vr"
        DownloadUrl = "https://github.com/mutars/anvilengine2vr/releases/latest"
        GameExe     = "ACMirage.exe"
        SteamFolder = "Assassin's Creed Mirage"
        FallbackPaths=@("C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games\Assassin's Creed Mirage", "C:\Program Files\Epic Games\AssassinsCreedMirage", "EPIC:AssassinsCreedMirage", "EPIC:Assassin's Creed Mirage")
        ModFile     = "dxgi.dll"
        Tags=@("assassins creed mirage", "assassin's creed", "ac mirage", "mirage", "basim", "baghdad", "anvilengine2vr", "mutars", "ubisoft", "action", "adventure", "stealth", "parkour", "story")
    },
    @{
        Controls    = "GP"
        Title       = "Assassin's Creed Odyssey VR"
        VideoUrl    = "https://www.youtube.com/live/vOmzz2Fwd_g?t=376"
        SteamId     = "812140"
        Quip        = "Malaka! From Kephallonia to Olympus, the eagle soars."
        Mod         = "AnvilEngine2VR (auto-update)"
        GithubRepo  = "mutars/anvilengine2vr"
        Description = "OpenXR or OpenVR choice"
        Author      = "mutars"
        Bat         = "ACOdysseyVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "Delete dxgi.dll (and openvr_api.dll, if present) from the game folder.",
            "Nothing else is touched."
        )
        Color       = "#0a1622"
        Accent      = "#e07b39"
        InfoUrl     = "https://github.com/mutars/anvilengine2vr"
        ModPageUrl  = "https://github.com/mutars/anvilengine2vr"
        DownloadUrl = "https://github.com/mutars/anvilengine2vr/releases/latest"
        GameExe     = "ACOdyssey.exe"
        SteamFolder = "Assassins Creed Odyssey"
        FallbackPaths=@("C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games\Assassin's Creed Odyssey", "C:\Program Files\Epic Games\AssassinsCreedOdyssey", "EPIC:AssassinsCreedOdyssey", "EPIC:Assassin's Creed Odyssey")
        ModFile     = "dxgi.dll"
        Tags=@("assassins creed odyssey", "assassin's creed", "ac odyssey", "odyssey", "kassandra", "alexios", "sparta", "greece", "anvilengine2vr", "mutars", "ubisoft", "action", "adventure", "rpg", "open world", "stealth")
    },
    @{
        Controls    = "GP"
        Title       = "Assassin's Creed Valhalla VR"
        VideoUrl    = "https://www.youtube.com/watch?v=_6qsvu8dlTU"
        SteamId     = "2208920"
        Quip        = "Skol! Raid England the way Odin intended."
        Mod         = "AnvilEngine2VR (auto-update)"
        GithubRepo  = "mutars/anvilengine2vr"
        Description = "OpenXR or OpenVR choice"
        Author      = "mutars"
        Bat         = "ACValhallaVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "Delete dxgi.dll (and openvr_api.dll, if present) from the game folder.",
            "Nothing else is touched."
        )
        Color       = "#0c1218"
        Accent      = "#cf4a2e"
        InfoUrl     = "https://github.com/mutars/anvilengine2vr"
        ModPageUrl  = "https://github.com/mutars/anvilengine2vr"
        DownloadUrl = "https://github.com/mutars/anvilengine2vr/releases/latest"
        GameExe     = "ACValhalla.exe"
        SteamFolder = "Assassin's Creed Valhalla"
        FallbackPaths=@("C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games\Assassin's Creed Valhalla", "C:\Program Files\Epic Games\AssassinsCreedValhalla", "EPIC:AssassinsCreedValhalla", "EPIC:Assassin's Creed Valhalla")
        ModFile     = "dxgi.dll"
        Tags=@("assassins creed valhalla", "assassin's creed", "ac valhalla", "valhalla", "eivor", "anvilengine2vr", "mutars", "ubisoft", "vikings", "action", "adventure", "rpg", "open world", "stealth")
    },
    @{
        Controls    = "VRGP"
        Title       = "Astrodogs VR"
        VideoUrl    = "https://www.youtube.com/watch?v=fg-lf7yRPrQ"
        SteamId     = "1301230"
        Mod         = "AstroDogs_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "AstrodogsVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#0a1828"
        Accent      = "#22aadd"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1424110040935043132/1424110255121367213"
        ModFile     = "BepInEx\plugins\AstroDogs_VR.dll"
        SteamFolder = "Astrodogs"
        FallbackPaths=@("STEAM:AstroDogs", "STEAM:astrodogs", "STEAM:Astrodogs Demo", "GOG:Astrodogs")
        Tags=@("astrodogs", "astienth", "star fox", "starfox", "dogs", "anime", "shooter", "space", "arcade", "indie", "colorful")
    },
    @{ Controls="GP"; Title="Atomic Heart VR"; VideoUrl="https://www.youtube.com/watch?v=ZW66XATBJ_g"; Quip="Welcome to Facility 3826, Comrade. Mind the robots."; SteamId="668580";                 Mod="R.E.A.L."; SteamFolder="AtomicHeart"; FallbackPaths=@("STEAM:Atomic Heart"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc3344"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, atomic heart", "fps", "shooter", "story") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Avatar: Frontiers of Pandora VR"; VideoUrl="https://www.youtube.com/watch?v=cUelil7M4fU"; Quip="Breathe Pandora's air. Hunt the skies with the Na'vi."; SteamId="2840770"; Mod="R.E.A.L."; SteamFolder="Avatar Frontiers of Pandora"; FallbackPaths=@("STEAM:AFOP"); Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#3a8aaa"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, avatar, pandora", "adventure", "open world", "story") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Banjo-Kazooie VR"
        # The clip is FLAT gameplay, not a VR capture - VideoLabel renames
        # the strip so it does not promise VR footage it never shows.
        VideoUrl    = "https://youtu.be/sst0clZ6g0Q?t=48"
        VideoLabel  = "Watch gameplay"
        SteamId     = ""
        PortraitUrl = "Assets/BanjoKazooieVR_portrait.jpg"
        HeaderUrl   = "Assets/BanjoKazooieVR_header.jpg"
        ScreenshotUrl = "Assets/BanjoKazooieVR_screenshot.jpg"
        Quip        = "Grab your bird and go. Gruntilda's tower won't climb itself."
        Mod         = "Lighthouse VR (auto-update)"
        GithubRepo  = "RaYRoD-TV/BanjoKazooie-VR"
        Description = "US (NTSC) 1.0 .z64 ROM"
        Author      = "RaYRoD"
        Bat         = "BanjoKazooieVR\START_INSTALLER.bat"
        Color       = "#123a6b"
        Accent      = "#f2b823"
        InfoUrl     = "https://github.com/RaYRoD-TV/BanjoKazooie-VR"
        ModPageUrl  = "https://github.com/RaYRoD-TV/BanjoKazooie-VR"
        DownloadUrl = "https://github.com/RaYRoD-TV/BanjoKazooie-VR/releases"
        ModFile     = "Lighthouse.exe"
        LaunchExe   = "Lighthouse.exe"
        StandaloneVR = $true
        SteamFolder = "Banjo-Kazooie VR"
        FallbackPaths=@("C:\Games\Banjo-Kazooie VR", "D:\Games\Banjo-Kazooie VR", "E:\Games\Banjo-Kazooie VR")
        Tags=@("banjo-kazooie", "banjo kazooie", "banjo", "kazooie", "gruntilda", "jiggy", "lighthouse", "harbour masters", "rare", "nintendo", "nintendo 64", "n64", "rayrod", "platformer", "adventure", "action", "exploration", "collectathon", "retro", "openxr")
    },
    @{
        Controls    = "VRGP"
        Title       = "Bomb Rush Cyberfunk"
        VideoUrl    = "https://youtu.be/tFEMHEWBiWs?t=21"
        Pill        = "BombRush_VR"
        SteamId     = "1353230"
        Mod         = "BombRushCyberFunk_VR v1.0.0"
        Description = "First & third person"
        Author      = "Astienth"
        Bat         = "BombRushCyberfunkVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#180a08"
        Accent      = "#ff66cc"
        InfoUrl     = "https://github.com/AstienVR/Bomb_Rush_Cyberfunk_VR"
        ModFile     = "BepInEx\plugins\BombRushCyberFunk_VR.dll"
        SteamFolder = "Bomb Rush Cyberfunk"
        FallbackPaths=@("STEAM:BombRushCyberfunk", "STEAM:BombRushCyberFunk", "STEAM:Bomb Rush Cyberfunk Demo", "GOG:Bomb Rush Cyberfunk")
        Tags=@("bomb rush cyberfunk", "bombrushcyberfunk", "brc", "astienth", "team reptile", "jet set radio", "jsr", "skating", "graffiti", "parkour", "stylish", "indie", "action")
    },
    @{ Controls="GP"; Title="Circuit Superstars VR"; VideoUrl="https://www.youtube.com/watch?v=ZRt0-P-c4vU"; Pill="CIRCUITSUPER_VR"; SteamId="1097130"; Mod="CIRCUITSUPER_VR_1.0.0"; SteamFolder="Circuit Superstars"; FallbackPaths=@("STEAM:CircuitSuperstars"); Description="bHaptics support included"; Author="Astienth"; Bat="CircuitSuperstarsVR\START_INSTALLER.bat"; Color="#180a08"; Accent="#dd2255"; InfoUrl="https://github.com/Astienth/Circuit_Superstars_VR_bHaptics"; Tags=@("circuit superstars", "circuitsuperstars", "astienth", "racing", "arcade", "top down", "indie", "sports", "cartoon", "stylized", "bhaptics"); ModFile="BepInEx\plugins\CircuitSuperstars_VR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="Cloudpunk VR"; VideoUrl="https://www.youtube.com/watch?v=aW_UTxKZjRs"; SteamId="746850"; Mod="Cloudpunk VR v1.0.0"; SteamFolder="Cloudpunk"; FallbackPaths=@("GOG:Cloudpunk", "EPIC:Cloudpunk"); Description="Best option Gamepad VR."; Author="Astienth"; Bat="CloudpunkVR\START_INSTALLER.bat"; Color="#0a0a1a"; Accent="#cc44ff"; InfoUrl="https://github.com/Astienth/Cloudpunk-VR/releases"; Tags=@("cloudpunk", "astienth", "atmospheric", "cyberpunk", "exploration", "narrative"); ModFile="BepInEx\plugins\CloudpunkVR.dll" },
    @{ Controls="GP"; Title="Cloudpunk: City of Ghosts VR"; VideoUrl="https://www.youtube.com/watch?v=H2M6MkWgGqI"; VideoLabel="Watch gameplay"; Pill="CLOUDP_COG_DLC"; SteamId="1536370"; Mod="CoG VR v1.0.0"; SteamFolder="Cloudpunk - City of Ghosts"; FallbackPaths=@("STEAM:Cloudpunk\City of Ghosts", "GOG:Cloudpunk", "EPIC:Cloudpunk"); Description="BepInEx VR mod"; Author="Astienth"; Bat="CloudpunkCOGVR\START_INSTALLER.bat"; Color="#0a0a1a"; Accent="#aa33dd"; InfoUrl="https://github.com/Astienth/Cloudpunk-VR/releases"; Tags=@("cloudpunk", "city of ghosts", "astienth", "atmospheric", "cyberpunk", "exploration", "narrative"); ModFile="BepInEx\plugins\CloudpunkVR_CityofGhosts.dll" },
    @{ Controls="GP"; Title="Dark Souls II VR"; VideoUrl="https://www.youtube.com/watch?v=XChyB_UAltY"; Quip="Bearer of the curse, seek souls. Drangleic awaits."; SteamId="236430";                Mod="R.E.A.L."; SteamFolder="Dark Souls II Scholar of the First Sin"; FallbackPaths=@("STEAM:Dark Souls II"); GameExe="Game\DarkSoulsII.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#7a6a3c"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, dark souls, souls", "action", "fantasy", "rpg", "souls-like") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Dark Souls III VR"; VideoUrl="https://youtu.be/TKNWjx6OHh0?t=152"; Quip="Bonfire lit. Estus ready. The Lords await your link."; SteamId="374320";               Mod="R.E.A.L."; SteamFolder="DARK SOULS III"; GameExe="Game\DarkSoulsIII.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#8a4a22"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, dark souls, souls", "action", "fantasy", "rpg", "souls-like") ; ModFile="Game\RealRepo\RealVR64.dll"; ModFileAlt="Game\RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Dark Souls Remastered"; VideoUrl="https://youtu.be/6aaQqSZXyTY?t=39"; Quip="Praise the sun - now you can raise your own hands to it."; SteamId="570940";        Mod="R.E.A.L."; SteamFolder="DARK SOULS REMASTERED"; GameExe="Dark Souls.exe"; Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#a07a3a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, dark souls, souls", "action", "fantasy", "rpg", "souls-like") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Days Gone VR"; VideoUrl="https://youtu.be/Lsdkpj7XJp0?t=90"; Quip="Ride the broken road. The horde is right behind you."; SteamId="1259420"; Mod="R.E.A.L."; SteamFolder="Days Gone"; FallbackPaths=@("GOG:Days Gone", "EPIC:DaysGone"); GameExe="BendGame\Binaries\Win64\DaysGone.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#a5713f"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, days gone", "open world", "survival", "action", "post-apocalyptic") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Death Stranding VR"; VideoUrl="https://youtu.be/8-pWfJcRbow?t=72"; Quip="Reconnect a broken America, Sam. Mind the BTs."; SteamId="1850570";              Mod="R.E.A.L."; SteamFolder="DEATH STRANDING DIRECTORS CUT"; FallbackPaths=@("STEAM:Death Stranding", "STEAM:DEATH STRANDING DIRECTORS CUT"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#5a6a7a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, death stranding, kojima", "atmospheric", "story", "walking sim") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Decimate Drive VR"
        VideoUrl    = "https://www.youtube.com/watch?v=xMb_L3zPgng"
        SteamId     = "2427950"
        Mod         = "DecimateDrive_VR v1.0.0"
        Description = "Discord login, OpenXR"
        Author      = "Astienth"
        Bat         = "DecimateDriveVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "For a full uninstall, delete the renamed file plus 'BepInEx\' and 'winhttp_bak.dll' from the 'release\' folder.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#0a0a18"
        Accent      = "#aa2222"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1442488939050176583/1442488939050176583"
        ModFile     = "release\BepInEx\plugins\DecimateDrive_VR.dll"
        SteamFolder = "Decimate Drive"
        Tags=@("decimate drive", "astienth", "horror", "driving", "arcade", "indie", "fast paced")
    },
    @{ Controls="GP"; Title="Descenders VR"; VideoUrl="https://www.youtube.com/watch?v=tn_c77QIJ9Q"; Pill="DESCENDERS_VR"; SteamId="681280"; Mod="DescendersVRMod (auto-update)"
        # AUTO-UPDATE NEU (2026-08-13). Vorher gab es KEINES: der Installer
        # hatte eine feste Adresse auf v1.0.5, und der Katalog kein
        # Update-Feld. Nach langer Pause kam v1.0.6 - niemand haette es
        # erfahren. Die Tags heissen descenders_vr_mod_vX.Y.Z.
        GithubRepo  = "kyanite-rock/DescendersVRMod"; SteamFolder="Descenders"; FallbackPaths=@("EPIC:Descenders"); Description="KB`&Mouse or Gamepad VR."; Author="Holydh / kyanite-rock"; Bat="DescendersVR\START_INSTALLER.bat"; Color="#0a0f1a"; Accent="#5588dd"; InfoUrl="https://github.com/kyanite-rock/DescendersVRMod"; Tags=@("descenders", "downhill", "mountain bike", "mtb", "indie", "racing", "sports"); ModFile="BepInEx\plugins\DescendersVRmod.dll" },
    @{ Controls="GP"; Title="Devil May Cry 5 VR"; VideoUrl="https://youtu.be/oY7eJfpDqr4?t=292"; Quip="Son of Sparda, stay stylish. Hit that SSS rank."; SteamId="601150"; Mod="REF (auto-update)"; SteamFolder="Devil May Cry 5"; FallbackPaths=@("STEAM:DevilMayCry5", "EPIC:Devil May Cry 5"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="DevilMayCry5.exe"; Color="#1a0000"; Accent="#cc2200"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("devil may cry", "reframework", "praydog", "action", "fast paced", "hack and slash", "stylish"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Dinkum VR"; Quip="Farm, fish and mine your patch of the Aussie outback, now in stereoscopic VR."; SteamId="1062520"; VideoUrl="https://youtu.be/YebR5go9hGw"; VideoLabel="Watch gameplay"; Mod="DinkumVR v1.0.0"; ModReleasedAt="2026-07-25"; Description="Nexus download required"; Author="Destroyjevski"; Bat="DinkumVR\START_INSTALLER.bat"; Color="#171009"; Accent="#e0902e"; InfoUrl="https://www.nexusmods.com/dinkum/mods/440"; DownloadUrl="https://www.nexusmods.com/dinkum/mods/440?tab=files"; ModFile="BepInEx\plugins\DinkumVR\DinkumVR.dll"; ModFileAlt="BepInEx\plugins\DinkumVR\DinkumVR.dll.disabled"; FlatVREnabled="BepInEx\plugins\DinkumVR\DinkumVR.dll"; FlatVRDisabled="BepInEx\plugins\DinkumVR\DinkumVR.dll.disabled"; SteamFolder="Dinkum"; Tags=@("dinkum", "farming", "simulation", "survival", "crafting", "fishing", "mining", "sandbox", "open world", "cozy", "island", "destroyjevski") },
    @{
        Controls    = "VRGP"
        Title       = "Dino Trauma VR"
        VideoUrl    = "https://www.youtube.com/watch?v=eqyCmdH77Lk"
        SteamId     = "2149420"
        Mod         = "DinoTrauma_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "DinoTraumaVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#0a1808"
        Accent      = "#66cc33"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1362075882042167377/1362075882042167377"
        ModFile     = "BepInEx\plugins\DinoTrauma_VR.dll"
        SteamFolder = "Dino Trauma"
        FallbackPaths=@("STEAM:DinoTrauma", "STEAM:Dino Trauma Demo")
        Tags=@("dino trauma", "dinotrauma", "astienth", "dinosaurs", "fps", "retro", "psx", "boomer shooter", "dino crisis", "horror", "indie")
    },
    @{ Controls="GP"; Title="Doom Eternal VR"; VideoUrl="https://www.youtube.com/watch?v=h8S3eSsCnjY"; Quip="Rip and tear through Hell itself, at arm's length."; SteamId="782330";                 Mod="R.E.A.L."; SteamFolder="DOOMEternal"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa1100"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, doom", "fps", "action", "fast-paced") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Dragon's Dogma 2 VR"; VideoUrl="https://youtu.be/vEDxr7BiEnI?t=197"; Quip="Grab the griffin. Climb the ogre. The Arisen rides again."; SteamId="2054970"; Mod="REF (auto-update)"; SteamFolder="Dragon's Dogma 2"; FallbackPaths=@("STEAM:Dragons Dogma 2", "STEAM:DragonsDogma2", "EPIC:Dragon's Dogma 2"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="DD2.exe"; Color="#1a0f00"; Accent="#dd7700"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("dragon dogma 2", "reframework", "praydog", "action", "fantasy", "open world", "rpg"); ModFile="openxr_loader.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Driftwood VR"
        VideoUrl    = "https://www.youtube.com/watch?v=5Q13RYYmCfg"
        SteamId     = "2223700"
        Mod         = "Driftwood_VR v1.0"
        Description = "Full body lean controls"
        Author      = "Astienth"
        Bat         = "DriftwoodVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#0a1808"
        Accent      = "#cc8855"
        InfoUrl     = "https://github.com/Astienth/DriftWood_VR_bHaptics"
        ModFile     = "BepInEx\plugins\Driftwood_VR.dll"
        SteamFolder = "Driftwood"
        FallbackPaths=@("STEAM:Driftwood Demo")
        Tags=@("driftwood", "astienth", "longboard", "longboarding", "skating", "sloth", "downhill", "drifting", "sports", "indie", "cartoon", "stylized", "bhaptics")
    },
    @{ Controls="GP"; Title="Echo Generation 2 VR"; VideoUrl="https://youtu.be/ybrAhkNBnnw?t=299"; VideoLabel="Watch gameplay"; SteamId="1115990"; PortraitUrl="Assets/EchoGeneration2VR_portrait.jpg"; HeaderUrl="Assets/EchoGeneration2VR_header.jpg"; Mod="EchoGeneration2_VR v1.0.0"; Description="Discord login, OpenXR"; Author="Astienth"; Bat="EchoGeneration2VR\START_INSTALLER.bat"; Color="#120c22"; Accent="#8a5cff"; InfoUrl="https://discord.com/channels/1001138422972432597/1521547069804908565/1521547128973955296"; ModFile="BepInEx\plugins\EchoGeneration2_VR.dll"; SteamFolder="Echo Generation 2"; FallbackPaths=@("STEAM:Echo Generation 2", "C:\XboxGames\Echo Generation 2\Content", "D:\XboxGames\Echo Generation 2\Content", "XBOX:Echo Generation 2"); Tags=@("echo generation 2", "echo generation", "echogeneration2", "astienth", "rpg", "deckbuilding", "deckbuilder", "card game", "turn-based", "sci-fi", "space", "adventure", "story", "indie"); UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "For a full uninstall, delete the renamed file plus the 'BepInEx\' folder.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="Elden Ring VR"; VideoUrl="https://www.youtube.com/watch?v=n69V9sGFzjE"; Quip="Rise, Tarnished, and stand life-size before the Erdtree."; SteamId="1245620";                   Mod="R.E.A.L."; SteamFolder="ELDEN RING"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#c89a3c"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, elden ring, fromsoftware, souls", "action", "fantasy", "open world", "rpg", "souls-like") ; ModFile="Game\RealRepo\RealVR64.dll"; ModFileAlt="Game\RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Far Cry 4 VR"; VideoUrl="https://www.youtube.com/watch?v=p4EYaeZhOx4"; Quip="Welcome to Kyrat. The Himalayas have never looked so close."; SteamId="298110";                    Mod="R.E.A.L."; SteamFolder="Far Cry 4"; GameExe="bin\FarCry4.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc4a22"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, far cry", "fps", "open world", "action") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Far Cry 5 VR"; VideoUrl="https://www.youtube.com/watch?v=VPN1wppEkB8"; Quip="Hope County needs a deputy. Step into the cult's backyard."; SteamId="552520";                    Mod="R.E.A.L."; SteamFolder="Far Cry 5"; GameExe="FarCry5.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa6633"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, far cry", "fps", "open world", "action") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Far Cry 6 VR"; VideoUrl="https://youtu.be/OR6BJ2q3rrk?t=464"; Quip="Viva Libertad! Tear down the regime from inside the headset."; SteamId="2369390";                    Mod="R.E.A.L."; SteamFolder="Far Cry 6"; GameExe="bin\FarCry6.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#dd9933"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, far cry", "fps", "open world", "action") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Far Cry New Dawn VR"; VideoUrl="https://www.youtube.com/watch?v=FTJ9SZr6UTU"; Quip="After the collapse, the pink-and-neon apocalypse awaits."; SteamId="939960";             Mod="R.E.A.L."; SteamFolder="FarCryNewDawn"; FallbackPaths=@("STEAM:Far Cry New Dawn"); GameExe="bin\FarCryNewDawn.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc44aa"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, far cry", "fps", "open world", "post-apocalyptic") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Far Cry Primal VR"; VideoUrl="https://www.youtube.com/watch?v=Ithr5auywNI"; Quip="Tame the beast. Hold the spear. The Stone Age, life-size."; SteamId="371660";               Mod="R.E.A.L."; SteamFolder="Far Cry Primal"; GameExe="bin\FCPrimal.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#8a4a1a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, far cry", "survival", "open world", "prehistoric") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="FF VII Rebirth VR"; VideoUrl="https://youtu.be/WwJYlCZmQM0?t=23"; VideoLabel="Watch gameplay"; Quip="The planet calls again. Cloud's journey, now around you."; SteamId="2909400";               Mod="R.E.A.L."; SteamFolder="FINAL FANTASY VII REBIRTH"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#33aa99"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, final fantasy, ff7", "fantasy", "mmo", "rpg") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="FF VII Remake VR"; VideoUrl="https://www.youtube.com/watch?v=fEGt4aB-YMM"; Quip="Mako reactors, a buster sword, and all of Midgar."; SteamId="1462040";                Mod="R.E.A.L."; SteamFolder="FINAL FANTASY VII REMAKE INTERGRADE"; FallbackPaths=@("STEAM:FINAL FANTASY VII REMAKE"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#1f7a88"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, final fantasy, ff7", "fantasy", "mmo", "rpg") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Forza Horizon 5 VR"; VideoUrl="https://youtu.be/n-07s0oObI8?t=76"; VideoLabel="Watch gameplay"; Pill="FH5_VR"; Quip="Viva Mexico - drop the roof, floor it, and chase that horizon."; SteamId="1551360"; Mod="VRMod (auto-update)"; GithubRepo="oofz/vrmod-releases"; GithubPrerelease=$true; Description="OpenXR, 6DoF"; Author="lufz"; Bat="ForzaHorizon5VR\START_INSTALLER.bat"; Color="#1f0f16"; Accent="#ff2d78"; ModFile="vrmod-launcher.exe"; SteamFolder="ForzaHorizon5"; FallbackPaths=@("STEAM:ForzaHorizon5", "C:\XboxGames\Forza Horizon 5\Content", "XBOX:Forza Horizon 5"); InfoUrl="https://github.com/oofz/vrmod-releases/releases"; Tags=@("forza horizon 5", "forza", "fh5", "lufz", "vrmod", "racing", "driving", "open world", "mexico", "arcade racing", "sim", "simulation"); UninstallSteps=@("Delete 'C:\Games\Forza Horizon 5 VR' and the desktop shortcut.", "Verify the game files afterwards if you used Install VR Mod on the game folder (Steam: right-click the game > Properties > Installed Files > Verify; Xbox app: three-dot menu > Manage > Files > Verify and repair).") },
    @{ Controls="GP"; Title="Forza Horizon 6 VR"; VideoUrl="https://youtu.be/q1Xudpmnk6M?t=147"; Pill="FH6_VR"; Quip="Chase the horizon, feel every gear change, and let the festival roar."; SteamId="2483190"; PortraitUrl="Assets/ForzaHorizon6_portrait.jpg"; HeaderUrl="Assets/ForzaHorizon6_header.jpg"; Mod="NALULUNA or lufz VRMod"; GithubRepo="oofz/vrmod-releases"; GithubPrerelease=$true; NoVersionSeed=$true; Description="6DoF, cockpit view"; Author="lufz (auto-update)"; Bat="ForzaHorizon6VR\START_INSTALLER.bat"; Color="#16101f"; Accent="#b454d4"; SteamFolder="ForzaHorizon6"; FallbackPaths=@("C:\XboxGames\Forza Horizon 6\Content", "XBOX:Forza Horizon 6"); TwoMods=$true; ModAName="NALULUNA"; ModASub="NALULUNA"; ModALaunch="fh6vr.exe"; ModBName="lufz"; ModBSub="lufz"; ModBLaunch="vrmod-launcher.exe"; InfoUrl="https://ko-fi.com/s/03bdcc5fe9"; Tags=@("forza horizon 6", "forza", "fh6", "naluluna", "lufz", "racing", "driving", "open world", "arcade racing", "sim", "simulation") },
    @{ Controls="GP"; Title="Ghost of Tsushima VR"; VideoUrl="https://www.youtube.com/watch?v=L7NIei0xkEs"; Quip="Stand on Tsushima's wind-swept fields. The Ghost rides."; SteamId="2215430";            Mod="R.E.A.L."; SteamFolder="Ghost of Tsushima DIRECTOR'S CUT"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa3333"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, ghost of tsushima", "action", "open world", "rpg", "story") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{
        # VRGP, not GP: the mod turns the Touch controllers into an
        # EMULATED GAMEPAD (sticks, triggers, grips, buttons). No physical pad
        # is needed - but it is not motion control, and the author insists it
        # must not be described as such.
        Controls    = "VRGP"
        Title       = "Ghost Recon Wildlands VR"
        # Real VR footage exists now, so the strip says "Watch VR gameplay"
        # again - no VideoLabel override here.
        VideoUrl    = "https://www.youtube.com/watch?v=223zZ8ysFcw"
        Quip        = "Sync up, Ghosts - Bolivia in stereo."
        SteamId     = "460930"
        Mod         = "GRW-XR (auto-update)"
        # Every build so far is an alpha, so the newest release has to be
        # taken including prereleases - /releases/latest would skip them.
        GithubRepo  = "Firejumper93/GhostReconWildlandsVR"
        GithubPrerelease = $true
        Description = "Alpha, no motion controls"
        Author      = "Firejumper93"
        Notice      = "This mod is an ALPHA and not a complete VR experience yet. Full stereo, head tracking, a fullscreen view, 4K internal rendering, head aim and working scopes are in - but there are NO real motion controls: the Touch controllers act as an emulated gamepad, with head aim and hand markers as the only tracked layers. Currently BROKEN by the August 2026 game patch: hiding your head in first person, so you may see hair or a helmet from inside - the author calls it the top priority for the next release. Keep the game's new FSR upscaling OFF with this mod. Treat it as a preview, not as a finished way to play. IMPORTANT: the game runs Easy Anti-Cheat for multiplayer - solo campaign only, never co-op, PvP or matchmaking, and offline mode is recommended."
        Bat         = "GhostReconWildlandsVR\START_INSTALLER.bat"
        Color       = "#0d1206"
        Accent      = "#9ab545"
        InfoUrl     = "https://github.com/Firejumper93/GhostReconWildlandsVR"
        ModPageUrl  = "https://github.com/Firejumper93/GhostReconWildlandsVR"
        DownloadUrl = "https://github.com/Firejumper93/GhostReconWildlandsVR/releases"
        # A dxgi.dll search-order proxy next to GRW.exe - no launcher, the
        # game starts through Steam as always and the mod loads itself.
        # Renaming dxgi.dll is the mod's own documented off switch, so the
        # Hub's Flat/VR button uses exactly that pair.
        ModFile        = "dxgi.dll"
        ModFileAlt     = "dxgi.dll.off"
        FlatVREnabled  = "dxgi.dll"
        FlatVRDisabled = "dxgi.dll.off"
        SteamFolder = "Wildlands"
        # SEIT v0.7.0-alpha AUCH UBISOFT CONNECT. Der Vorbehalt von 0.5.0
        # ("nur Steam, andere Laeden sind eine andere Exe") ist weg: nach
        # Ubisofts August-2026-Patch liefern Steam und Ubisoft Connect die
        # BYTE-GLEICHE GRW.exe, eine Adresstabelle deckt beide. Epic bleibt
        # draussen - dazu sagt der Autor nichts.
        FallbackPaths=@("STEAM:Wildlands", "UBI:Tom Clancy's Ghost Recon Wildlands")
        UninstallSteps = @(
            "Close the game.",
            "Only want to play flat for a while? Do NOT uninstall - use the Flat / VR switch on this page, which renames dxgi.dll for you.",
            "Open the Ghost Recon Wildlands folder (the one with GRW.exe) and delete dxgi.dll, dxgi_real.dll, openxr_loader.dll and cfg_gui.exe.",
            "Delete the GRWVR folder - it holds the mod's log files and your grwxr.cfg tuning.",
            "If a file called dxgi.dll.hubbak is there, it is the dxgi.dll you had before (ReShade or a similar wrapper): rename it back to dxgi.dll.",
            "No game file was ever modified, so the flat game is untouched and needs no verify or reinstall."
        )
        Tags        = @("ghost recon", "wildlands", "grw", "firejumper93", "openxr", "shooter", "fps", "action", "tactical", "military", "open world", "third person", "stealth", "ubisoft")
    },
    @{ Controls="GP"; Title="Ghosts n Goblins Resurrection VR"; VideoUrl="https://youtu.be/5sgmy9nJqZY?t=4402"; VideoLabel="Watch gameplay"; Quip="Lose your armor in one hit - now in glorious 3D."; SteamId="1375400"; Mod="REF (auto-update)"; SteamFolder="Ghosts n Goblins Resurrection"; FallbackPaths=@("STEAM:GhostsnGoblinsResurrection", "STEAM:Ghosts 'n Goblins Resurrection", "STEAM:Makaimura_GG_RE"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="makaimura_GG_RE.exe"; Color="#0a0a1a"; Accent="#7733aa"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("ghosts goblins", "reframework", "praydog", "fast paced", "platformer", "arcade", "retro"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Ghostwire: Tokyo VR"; VideoUrl="https://youtu.be/jwMUMGtPpwU?t=89"; Quip="Tokyo is empty. The spirits are not. Weave with your hands."; SteamId="1475810";             Mod="R.E.A.L."; SteamFolder="GhostWire- Tokyo"; FallbackPaths=@("STEAM:Ghostwire Tokyo", "STEAM:GhostwireTokyo", "EPIC:Ghostwire Tokyo"); GameExe="GWT.exe"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc44aa"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, ghostwire", "action", "supernatural", "horror") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Grounded VR"; VideoUrl="https://www.youtube.com/watch?v=4A5yO10xSHs"; Quip="Shrunk to bug-size in the backyard. The spiders are huge."; SteamId="962130";                     Mod="R.E.A.L."; SteamFolder="Grounded"; FallbackPaths=@("XBOX:Grounded"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#7aaa33"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, grounded", "survival", "crafting", "co-op") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{
        Controls    = "GP"
        Title       = "GTA IV VR"
        VideoUrl    = "https://youtu.be/JkVdSyDpg78"
        SteamId     = "12210"
        Quip        = "Liberty City, at eye level. Niko never had it this real."
        Mod         = "gtaiv-dxvk-vr (auto-update)"
        GithubRepo  = "Hochgeschwindigkeitsrennfahrer/Grand-Theft-Auto-IV-VR-Mod"
        Description = "Complete Edition, SteamVR"
        Author      = "Hochgeschwindigkeitsrennfahrer"
        Bat         = "GTA4VR\START_INSTALLER.bat"
        Color       = "#101820"
        Accent      = "#c9852f"
        InfoUrl     = "https://github.com/Hochgeschwindigkeitsrennfahrer/Grand-Theft-Auto-IV-VR-Mod"
        ModPageUrl  = "https://github.com/Hochgeschwindigkeitsrennfahrer/Grand-Theft-Auto-IV-VR-Mod"
        DownloadUrl = "https://github.com/Hochgeschwindigkeitsrennfahrer/Grand-Theft-Auto-IV-VR-Mod/releases"
        SteamFolder = "Grand Theft Auto IV"
        FallbackPaths=@("C:\Program Files\Rockstar Games\Grand Theft Auto IV", "C:\Program Files (x86)\Rockstar Games\Grand Theft Auto IV")
        ModFile     = "GTAIV\gtaiv_dxvk_vr.asi"
        ModFileAlt  = "gtaiv_dxvk_vr.asi"
        FlatVREnabled  = "GTAIV\gtaiv_dxvk_vr.asi|gtaiv_dxvk_vr.asi"
        FlatVRDisabled = "GTAIV\gtaiv_dxvk_vr.asi.off|gtaiv_dxvk_vr.asi.off"
        UninstallSteps = @(
            "Only want to play flat for a while? Do NOT uninstall - use the Flat / VR switch on this page.",
            "To remove the mod, restore d3d9.dll.vrbak and dinput8.dll.vrbak over the mod's versions in the GTAIV folder, and delete gtaiv_dxvk_vr.asi."
        )
        Tags=@("gta", "gta 4", "gta iv", "grand theft auto", "liberty city", "niko bellic", "rockstar", "dxvk", "open world", "action", "shooter", "driving", "story")
    },
    @{ Controls="GP"; Title="High on Life VR"; VideoUrl="https://www.youtube.com/watch?v=Yzn5Rf_vwLc"; Quip="Talking guns and bounty hunts - now they're really talking to you."; SteamId="1583230";                 Mod="R.E.A.L."; SteamFolder="High On Life"; FallbackPaths=@("STEAM:HighOnLife", "EPIC:HighOnLife", "XBOX:High On Life"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa44cc"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, high on life", "fps", "comedy", "sci-fi") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Hogwarts Legacy VR"; VideoUrl="https://www.youtube.com/watch?v=CT9WPSiKHzA"; Quip="Wand at the ready. Walk the halls of Hogwarts yourself."; SteamId="990080";              Mod="R.E.A.L."; SteamFolder="Hogwarts Legacy"; FallbackPaths=@("EPIC:HogwartsLegacy"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#7a5a22"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, hogwarts, harry potter", "adventure", "fantasy", "rpg", "story") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    # TWO MODS, ONE PLUGINS FOLDER. Astienth's mod adds parallax depth
    # between the sprite layers; SadMonsterParty's Flat to VR puts the
    # flat picture on several floating OpenVR overlay planes. Both are
    # BepInEx plugins in BepInEx\plugins and would fight over the
    # screen, so the installer parks the inactive one as <name>.dll.off
    # and - once BOTH are on disk - writes one switch launcher per mod
    # into <game>\VRLaunch. Those two bats are what ModALaunch/ModBLaunch
    # detect, and they are what the split Play button starts.
    # TwoModsRequireBoth: with a single mod there is nothing to switch
    # between, so the tile keeps the normal start until both are there.
    @{ Controls="VRGP"; Title="Hollow Knight Silksong"; VideoUrl="https://www.youtube.com/watch?v=gmR53WcH2iY"; Pill="HOLLOWK_S_VR"; Quip="Climb high, Hornet. The Citadel waits."; SteamId="1030300"; Mod="Astienth + Flat to VR"; SteamFolder="Hollow Knight Silksong"; FallbackPaths=@("STEAM:HollowKnightSilksong", "STEAM:Silksong", "GOG:Hollow Knight Silksong", "XBOX:Hollow Knight- Silksong"); Description="Two mods, Nexus, Discord"; Author="Astienth / SadMonsterParty"; Bat="HollowKnightSilksongVR\START_INSTALLER.bat"; Color="#0a0a18"; Accent="#aaccff"; InfoUrl="https://discord.com/channels/1001138422972432597/1414940597579419679/1414940597579419679"; ModPageUrl="https://www.nexusmods.com/hollowknightsilksong/mods/942"; TwoMods=$true; TwoModsRequireBoth=$true; ModAName="Astienth"; ModASub="VRLaunch"; ModALaunch="Silksong VR (Astienth).bat"; ModBName="Flat to VR"; ModBSub="VRLaunch"; ModBLaunch="Silksong VR (Flat to VR).bat"; Tags=@("hollow knight", "silksong", "hollowknight", "astienth", "sadmonsterparty", "flat to vr", "metroidvania", "2d", "platformer", "souls-like", "hand-drawn", "indie", "depth"); ModFile="BepInEx\plugins\HollowKnightSilksong_VR.dll"; ModFileAlt="BepInEx\plugins\SilksongFlatToVR4.dll" },
    @{ Controls="GP"; Title="Hollow Knight VR"; VideoUrl="https://www.youtube.com/watch?v=6b_GGwASDWo"; SteamId="367520"; Mod="HollowKnight_VR v1.0.0"; SteamFolder="Hollow Knight"; FallbackPaths=@("STEAM:HollowKnight", "GOG:Hollow Knight", "XBOX:Hollow Knight"); Description="Discord login, depth only"; Author="Astienth"; Bat="HollowKnightVR\START_INSTALLER.bat"; Color="#080a14"; Accent="#88aacc"; InfoUrl="https://discord.com/channels/1001138422972432597/1254790696502693888/1254790696502693888"; DownloadUrl="https://discord.com/channels/1001138422972432597/1254790696502693888/1508878766166773821"; Tags=@("hollow knight", "hollowknight", "astienth", "team cherry", "metroidvania", "2d", "platformer", "souls-like", "hand-drawn", "indie", "depth"); ModFile="BepInEx\plugins\HollowKnight_VR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "Delete the renamed file plus 'BepInEx\\' and 'winhttp_bak.dll' for a full uninstall.", "If you installed the mod into a copy of the game folder, you can also just delete the copy entirely.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="Horizon Chase Turbo"; VideoUrl="https://www.youtube.com/watch?v=Ejqe96bjVy0"; Pill="HORIZONCHASE_VR"; SteamId="389140"; Mod="HorizonChaseTurboVR v1.0.0"; SteamFolder="Horizon Chase Turbo"; FallbackPaths=@("STEAM:HorizonChaseTurbo", "STEAM:Horizon Chase Turbo Demo", "EPIC:HorizonChaseTurbo", "EPIC:Horizon Chase Turbo", "C:\Program Files\Epic Games\HorizonChaseTurbo", "C:\Program Files (x86)\Epic Games\HorizonChaseTurbo"); Description="Discord login, Steam or Epic"; Author="Astienth"; Bat="HorizonChaseTurboVR\START_INSTALLER.bat"; Color="#180a18"; Accent="#ff66aa"; InfoUrl="https://discord.com/channels/1001138422972432597/1362072336827814020/1362072336827814020"; DownloadUrl="https://discord.com/channels/1001138422972432597/1362072336827814020/1362073443733864508"; Tags=@("horizon chase turbo", "horizonchaseturbo", "horizon chase", "astienth", "racing", "arcade", "retro", "top gear", "out run", "indie", "cartoon"); ModFile="BepInEx\plugins\HorizonChaseTurboVR.dll"; UninstallSteps=@("Important: this mod uses a Doorstop loader, not the usual 'winhttp.dll' proxy that the other Astienth mods use.", "To disable it, rename or delete 'doorstop_config.ini' in the game root folder.", "The mod stops loading; BepInEx and the plugin DLL can stay on disk.", "If you want to fully clean up, also delete the 'BepInEx\' folder and the 'doorstop_config.ini' file.") },
    @{ Controls="GP"; Title="Horizon Forbidden West VR"; VideoUrl="https://www.youtube.com/live/WLWVzzLe1BY?t=555"; Quip="Beyond the frontier, the machines roam. Aloy's bow in hand."; SteamId="2420110";       Mod="R.E.A.L."; SteamFolder="Horizon Forbidden West"; FallbackPaths=@("STEAM:Horizon Forbidden West Complete Edition", "EPIC:HorizonForbiddenWestCompleteEdition", "EPIC:Horizon Forbidden West"); Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc6a22"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, horizon", "action", "open world", "rpg") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Horizon Zero Dawn VR"; VideoUrl="https://youtu.be/NxCKFVs7dpQ?t=92"; Quip="Stand among the machines. Aloy's world, life-size."; SteamId="1151640";            Mod="R.E.A.L."; SteamFolder="Horizon Zero Dawn"; FallbackPaths=@("EPIC:HorizonZeroDawn", "GOG:Horizon Zero Dawn Complete Edition"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa5522"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, horizon", "action", "open world", "rpg") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Horizon Zero Dawn Remastered VR"; VideoUrl="https://www.youtube.com/live/8_CNr418TMg?t=748"; Quip="Aloy's world, remastered. The machines tower over you."; SteamId="2561580"; Mod="R.E.A.L."; SteamFolder="Horizon Zero Dawn Remastered"; Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc7733"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, horizon", "action", "open world", "rpg") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Hypogea VR"; VideoUrl="https://www.youtube.com/watch?v=eUZdcHg2riI"; SteamId="2980260"; Mod="Hypogea_VR v1.0.0"; SteamFolder="Hypogea"; FallbackPaths=@("STEAM:Hypogea Demo", "STEAM:HYPOGEA"); Description="Discord login required."; Author="Astienth"; Bat="HypogeaVR\START_INSTALLER.bat"; Color="#100818"; Accent="#aa66ee"; InfoUrl="https://discord.com/channels/1001138422972432597/1465600243939672115/1465600264210878691"; Tags=@("hypogea", "astienth", "atmospheric", "retro", "ps1", "platformer", "indie", "narrative", "exploration", "story"); ModFile="BepInEx\plugins\Hypogea_VR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "Delete the renamed file plus 'BepInEx\' and 'winhttp_bak.dll' for a full uninstall.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="Indiana Jones: Great Circle VR"; VideoUrl="https://www.youtube.com/watch?v=IpzWP3u84lM"; Quip="Fortune and glory, kid. The whip's in your hand now."; SteamId="2677660";  Mod="R.E.A.L."; SteamFolder="Indiana Jones and the Great Circle"; FallbackPaths=@("STEAM:The Great Circle", "XBOX:The Great Circle"); Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#b88846"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, indiana jones", "adventure", "action", "puzzle") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Kingdom Come: Deliverance II VR"; VideoUrl="https://www.youtube.com/watch?v=mZYRtwL7iXk"; Quip="Jesus Christ be praised - medieval Bohemia, life-size."; SteamId="1771300"; Mod="R.E.A.L."; SteamFolder="KingdomComeDeliverance2"; Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#5a4a2a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, kingdom come", "rpg", "fantasy", "medieval", "realistic") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Kunitsu-Gami: Path of the Goddess VR"; VideoUrl="https://youtu.be/J1gSrZenM0w?t=120"; Quip="Cleanse the defilement by day, defend the maiden by night."; SteamId="2510710"; Mod="REF (auto-update)"; SteamFolder="KUNITSU-GAMI"; FallbackPaths=@("STEAM:Kunitsu-Gami", "STEAM:KunitsuGami", "STEAM:Kunitsu-Gami Path of the Goddess", "XBOX:Kunitsu-Gami- Path of the Goddess"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="KunitsuGami.exe"; Color="#1a0a00"; Accent="#cc2244"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("kunitsu-gami", "reframework", "praydog", "action", "rpg", "strategy", "japanese"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Lunistice VR"; VideoUrl="https://www.youtube.com/watch?v=tQTkUIKj3tw"; VideoLabel="Watch gameplay"; SteamId="1701800"; Mod="Lunistice_VR v1.0.0"; SteamFolder="Lunistice"; FallbackPaths=@("STEAM:Lunistice Demo", "GOG:Lunistice"); Description="Discord login required."; Author="Astienth"; Bat="LunisticeVR\START_INSTALLER.bat"; Color="#1a0820"; Accent="#ff77cc"; InfoUrl="https://discord.com/channels/1001138422972432597/1465598630382669916/1465598630382669916"; Tags=@("lunistice", "astienth", "cute", "kawaii", "retro", "platformer", "indie", "fast paced", "anime"); ModFile="BepInEx\plugins\Lunistice_VR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "Delete the renamed file plus 'BepInEx\' and 'winhttp_bak.dll' for a full uninstall.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{
        Controls    = "VRGP"
        Title       = "Mario Kart 64 VR"
        VideoUrl    = "https://www.youtube.com/watch?v=tPl0OxPvUaQ"
        VideoLabel  = "Watch gameplay"
        SteamId     = ""
        PortraitUrl = "Assets/MarioKart64_portrait.jpg"
        HeaderUrl   = "Assets/MarioKart64_header.jpg"
        ScreenshotUrl = "Assets/MarioKart64_screenshot.jpg"
        Quip        = "Rainbow Road has no guardrails. Neither does karma."
        Mod         = "SpaghettiKart (auto-update)"
        GithubRepo  = "RaYRoD-TV/MarioKart64-VR"
        Description = "US (NTSC) .z64 ROM required"
        Author      = "RaYRoD"
        Bat         = "MarioKart64VR\START_INSTALLER.bat"
        Color       = "#0d0d2b"
        Accent      = "#4fd6ff"
        InfoUrl     = "https://github.com/RaYRoD-TV/MarioKart64-VR"
        ModPageUrl  = "https://github.com/RaYRoD-TV/MarioKart64-VR"
        DownloadUrl = "https://github.com/RaYRoD-TV/MarioKart64-VR/releases/latest"
        ModFile     = "Spaghettify.exe"
        LaunchExe   = "Spaghettify.exe"
        StandaloneVR = $true
        SteamFolder = "Mario Kart 64 VR"
        FallbackPaths=@("C:\Games\Mario Kart 64 VR", "D:\Games\Mario Kart 64 VR", "E:\Games\Mario Kart 64 VR", "C:\games\Mario Kart 64 VR")
        Tags=@("mario kart 64", "mario kart", "mk64", "spaghettikart", "spaghetti kart", "mario", "nintendo", "rayrod", "racing", "action", "retro", "kart racer", "arcade", "motion controls")
    },
    @{
        Controls    = "GP"
        Title       = "Mass Effect 1 LE VR"
        VideoUrl    = "https://youtu.be/zk1qG2ozU1k?t=34"
        SteamId     = "1328670"
        Quip        = "I'm Commander Shepard, and this is my favorite mod on the Citadel."
        Mod         = "MELE-VR V3"
        # Zeitstempel, den der V3-Build im Zip des Modders traegt
        # (aus MELE1-VR-V3.zip gelesen: dxgi.dll 1.250.304 B, 2026-08-12
        # 16:48). Wer noch auf V1 oder V2 sitzt, hat ein aelteres Datum
        # auf der Platte -> Update-Kennzeichen. Eine V3-Installation gilt
        # als aktuell, egal wann sie entpackt wurde.
        ModBuildStamp = "2026-08-12 16:48"
        Description = "Legendary Edition required"
        Author      = "dhalcyon"
        Bat         = "MassEffect1VR\START_INSTALLER.bat"
        Color       = "#0a0e1a"
        Accent      = "#d93a3a"
        InfoUrl     = "https://www.patreon.com/posts/166482031"
        ModPageUrl  = "https://www.patreon.com/posts/166482031"
        DownloadUrl = "https://www.patreon.com/posts/166482031"
        SteamFolder = "Mass Effect Legendary Edition"
        FallbackPaths=@("C:\Program Files\EA Games\Mass Effect Legendary Edition", "C:\Program Files (x86)\Origin Games\Mass Effect Legendary Edition", "C:\Program Files\Epic Games\Mass Effect Legendary Edition", "EPIC:Mass Effect Legendary Edition", "XBOX:Mass Effect Legendary Edition")
        ModFile     = "Game\ME1\Binaries\Win64\dxgi.dll"
        UninstallSteps = @(
            "Re-run MELE-VR.bat in ...\Game\ME1\Binaries\Win64 and follow its uninstall option - or simply delete 'dxgi.dll' and 'openxr_loader.dll' from that folder.",
            "The base game (Legendary Edition) is left untouched."
        )
        Tags=@("mass effect", "mass effect 1", "mele", "legendary edition", "shepard", "normandy", "citadel", "bioware", "dhalcyon", "rpg", "action", "sci-fi", "story", "space", "shooter")
    },
    @{
        Controls    = "GP"
        Title       = "Mass Effect 2 LE VR"
        VideoUrl    = "https://www.youtube.com/watch?v=U3i4GtCuPKE&t=228"
        SteamId     = "1328670"
        Quip        = "Assemble the team. The Omega-4 relay is a one-way trip."
        Mod         = "MELE2-VR"
        # ME2 hatte bisher KEIN Update-Signal - der Hub konnte dort nie
        # eine neue Fassung melden. Zeitstempel wie bei ME1: aus dem Zip
        # des Modders gelesen (dxgi.dll 849.408 B, 2026-08-01 20:29). Wer
        # eine aeltere Datei auf der Platte hat, bekommt das
        # Update-Kennzeichen.
        ModBuildStamp = "2026-08-01 20:29"
        Description = "Legendary Edition required"
        Author      = "dhalcyon"
        Bat         = "MassEffect2VR\START_INSTALLER.bat"
        Color       = "#0a0e1a"
        Accent      = "#e0862a"
        InfoUrl     = "https://www.patreon.com/dhalcyon/posts/suicide-mission-165506412"
        ModPageUrl  = "https://www.patreon.com/dhalcyon/posts/suicide-mission-165506412"
        DownloadUrl = "https://www.patreon.com/dhalcyon/posts/suicide-mission-165506412"
        SteamFolder = "Mass Effect Legendary Edition"
        FallbackPaths=@("C:\Program Files\EA Games\Mass Effect Legendary Edition", "C:\Program Files (x86)\Origin Games\Mass Effect Legendary Edition", "C:\Program Files\Epic Games\Mass Effect Legendary Edition", "EPIC:Mass Effect Legendary Edition", "XBOX:Mass Effect Legendary Edition")
        ModFile     = "Game\ME2\Binaries\Win64\dxgi.dll"
        UninstallSteps = @(
            "Re-run MELE2-VR.bat in ...\Game\ME2\Binaries\Win64 and follow its uninstall option - or simply delete 'dxgi.dll' and 'openxr_loader.dll' from that folder.",
            "The base game (Legendary Edition) is left untouched."
        )
        Tags=@("mass effect", "mass effect 2", "mele2", "legendary edition", "shepard", "normandy", "omega", "collectors", "suicide mission", "bioware", "dhalcyon", "rpg", "action", "sci-fi", "story", "space", "shooter")
    },
    @{ Controls="GP"; Title="Mega Man Star Force Legacy VR"; VideoUrl="https://youtu.be/oIjb5ArHI_M?t=33"; VideoLabel="Watch gameplay"; Quip="Transer online. EM Wave Change, Geo - ride on!"; SteamId="3500390"; PortraitUrl="Assets/MegaManStarForce_portrait.jpg"; HeaderUrl="Assets/MegaManStarForce_header.jpg"; Mod="REF (auto-update)"; SteamFolder="Mega Man Star Force Legacy Collection"; FallbackPaths=@("STEAM:MMSFLEGACYCOLLECTION", "STEAM:MegaManStarForceLegacyCollection"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="STARFORCE.exe"; Color="#001a1a"; Accent="#00cccc"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("mega man star force", "reframework", "praydog", "action", "rpg", "jrpg"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Mirage Feathers VR"; VideoUrl="https://www.youtube.com/watch?v=SSebsIfxrVk"; VideoLabel="Watch gameplay"; SteamId="2719060"; Mod="MirageFeathers_VR v1.0.0"; SteamFolder="Mirage Feathers"; FallbackPaths=@("STEAM:MirageFeathers", "STEAM:Mirage Feathers Demo", "STEAM:MirageFeathersDemo"); Description="Discord login, Demo or Full"; Author="Astienth"; Bat="MirageFeathersVR\START_INSTALLER.bat"; Color="#180814"; Accent="#88ccdd"; InfoUrl="https://discord.com/channels/1001138422972432597/1325853693530079232/1325853693530079232"; Tags=@("mirage feathers", "miragefeathers", "astienth", "rail shooter", "shmup", "after burner", "space harrier", "hang on", "super scaler", "anime", "arcade", "indie"); ModFile="BepInEx\plugins\MirageFeathers_VR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="Monster Hunter Rise VR"; VideoUrl="https://www.youtube.com/watch?v=O0cxLPaYzUE"; Quip="Wirebug up, monster down. The hunt is yours."; SteamId="1446780"; Mod="REF (auto-update)"; SteamFolder="MonsterHunterRise"; FallbackPaths=@("XBOX:Monster Hunter Rise"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="MonsterHunterRise.exe"; Color="#1a0a00"; Accent="#dd6600"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("monster hunter rise", "reframework", "praydog", "action", "coop", "rpg"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Monster Hunter Stories 3 VR"; VideoUrl="https://www.youtube.com/watch?v=Itzcp6_bWfM"; VideoLabel="Watch gameplay"; Quip="Hatch the egg, ride the monstie. Forge your kinship."; SteamId="2852190"; PortraitUrl="Assets/MonsterHunterStories3_portrait.jpg"; HeaderUrl="Assets/MonsterHunterStories3_header.jpg"; Mod="REF (auto-update)"; SteamFolder="MONSTER HUNTER STORIES 3"; FallbackPaths=@("STEAM:Monster Hunter Stories 3", "STEAM:MonsterHunterStories3", "STEAM:MONSTER_HUNTER_STORIES_3_TWISTED_REFLECTION"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="MHSTORIES3.exe"; Color="#0a1a0a"; Accent="#ee9933"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("monster hunter stories", "reframework", "praydog", "rpg", "story", "jrpg", "turn-based", "adventure"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Monster Hunter Wilds"; VideoUrl="https://www.youtube.com/watch?v=lLWE5328LPs"; VideoLabel="Watch gameplay"; Quip="Track the herd across the wilds, hunter. Bring your blade."; SteamId="2246340"; Mod="REF (auto-update)"; SteamFolder="MonsterHunterWilds"; Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="MonsterHunterWilds.exe"; Color="#1a0800"; Accent="#ff5500"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("monster hunter wilds", "reframework", "praydog", "action", "coop", "open world", "rpg"); ModFile="openxr_loader.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Moto Rush Reborn VR"
        VideoUrl    = "https://www.youtube.com/watch?v=pfVWgTii6gk"
        Pill        = "MotoRush_R_VR"
        SteamId     = "2990060"
        Mod         = "MotoRushReborn_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "MotoRushRebornVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "Delete the renamed file plus 'BepInEx\' and 'winhttp_bak.dll' for a full uninstall.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#1a1000"
        Accent      = "#dd2222"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1490989987708014672/1490990041382518785"
        ModFile     = "BepInEx\plugins\MotoRushReborn_VR.dll"
        SteamFolder = "Moto Rush Reborn"
        FallbackPaths=@("STEAM:MotoRushReborn", "STEAM:Moto Rush Reborn Demo")
        LaunchExe   = "Moto Rush Reborn.exe"
        Tags=@("moto rush reborn", "astienth", "racing", "sports", "fast paced", "indie")
    },
    @{ Controls="VRGP"; Title="New Star GP VR"; VideoUrl="https://youtu.be/fRQFt8Of38c?t=130"; VideoLabel="Watch gameplay"; Quip="Lights out and away you go, champ - chase that checkered flag."; SteamId="2217580"; Mod="New_Star_GP_VR"; Description="Discord login required"; Author="Astienth"; Bat="NewStarGPVR\START_INSTALLER.bat"; Color="#12100f"; Accent="#e85d3d"; InfoUrl="https://discord.com/channels/1001138422972432597/1522836877101629490/1522836922676940812"; ModFile="release\BepInEx\plugins\New_Star_GP_VR.dll"; SteamFolder="New Star GP"; FallbackPaths=@("STEAM:New Star GP", "C:\XboxGames\New Star GP\Content", "XBOX:New Star GP"); Tags=@("new star gp", "nsgp", "new star games", "f1", "formula", "motorsport", "racing", "arcade", "sports"); UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "Delete the renamed file plus 'BepInEx\\' and 'winhttp_bak.dll' for a full uninstall.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="No One Lives Forever 2 VR"; SteamFolder="No One Lives Forever 2"; VideoUrl="https://www.youtube.com/watch?v=hJhE84R74_0"; Pill="NOLF2-R3"; Quip="Slip into Cate Archer's shoes, outwit H.A.R.M., and make spycraft look effortless."; PortraitUrl="Assets/NOLF2_portrait.jpg"; HeaderUrl="Assets/NOLF2_header.jpg"; ScreenshotUrl="Assets/NOLF2_screenshot.jpg"; Mod="Release 3"; Description="NOLF2 1.3 EN required"; Author="Luke Ross"; Bat="NOLF2VR\START_INSTALLER.bat"; Color="#171109"; Accent="#e8923a"; LaunchExe="Lithtech.exe"; ModFile="VRlaunchcmds.txt"; InfoUrl="https://github.com/LukeRoss00/nolf2-real-mod"; ModPageUrl="https://www.patreon.com/realvr"; Tags=@("no one lives forever 2", "nolf2", "nolf", "cate archer", "spy", "stealth", "shooter", "fps", "retro", "adventure", "luke ross", "real") },
    @{ Controls="GP"; Title="Onimusha 2 VR"; VideoUrl="https://youtu.be/42jEMrshZzc?t=1590"; VideoLabel="Watch gameplay"; Quip="Oni gauntlet ready. The demons of Sengoku await."; SteamId="3046600"; Mod="REF (auto-update)"; SteamFolder="ONIMUSHA2"; FallbackPaths=@("STEAM:Onimusha 2", "STEAM:Onimusha2"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="Onimusha2.exe"; Color="#0a0a0a"; Accent="#cc6600"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("onimusha 2", "reframework", "praydog", "action", "story", "samurai", "horror"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="Outbound VR"; VideoUrl="https://www.youtube.com/watch?v=k_NeBB6iysY"; VideoLabel="Watch gameplay"; Quip="Chart the drift, trust your gut, and roll on into the unknown."; SteamId="2681030"; Mod="OutboundVR v1.0.1"; ModReleasedAt="2026-07-21"; ModBuildStamp="2026-07-21 03:24"; Description="Nexus download required"; Author="Destroyjevski"; Bat="OutboundVR\START_INSTALLER.bat"; Color="#12181a"; Accent="#4fb89a"; InfoUrl="https://www.nexusmods.com/outbound/mods/28"; ModFile="BepInEx\plugins\OutboundVR\OutboundVR.dll"; SteamFolder="Outbound"; FallbackPaths=@("STEAM:Outbound", "C:\XboxGames\Outbound\Content", "D:\XboxGames\Outbound\Content", "XBOX:Outbound", "EPIC:Outbound"); Tags=@("outbound", "destroyjevski", "survival", "crafting", "driving", "cozy", "sandbox", "open world", "roadtrip") },
    @{
        Controls    = "GP"
        Title       = "Outlast VR"
        Quip        = "You are not armed. You never were. Now you can look behind you."
        SteamId     = "238320"
        SteamFolder = "Outlast"
        VideoUrl    = "https://www.youtube.com/watch?v=odXzJC-JABM"
        Mod         = "Outlast VR by Halcyon"
        Description = "Stereo, VR cutscenes"
        Author      = "Halcyon"
        # Blaue Zeile auf der Kachel. Ersetzt dort automatisch die
        # "by <Modder>"-Zeile - genau wie bei Amnesia VR und den anderen
        # elf Eintraegen mit einem Zusatzmod.
        ImprovementTag = "+ remove film grain"
        Bat         = "OutlastVR\START_INSTALLER.bat"
        Color       = "#1a1c18"
        Accent      = "#8fa33f"
        InfoUrl     = "https://www.patreon.com/dhalcyon/posts/nowhere-to-hide-165840706"
        ModPageUrl  = "https://www.patreon.com/dhalcyon"
        DownloadUrl = "https://www.patreon.com/dhalcyon/posts/nowhere-to-hide-165840706"
        # !!! Binaries\Win64, NICHT der Spielordner - haeufigste Verwechslung.
        # Alle drei Laeden legen dieselbe Struktur an, nur an anderer Stelle.
        ModFile     = "Binaries\Win64\d3d9.dll"
        GameExe     = "Binaries\Win64\OLGame.exe"
        FallbackPaths=@("C:\GOG Games\Outlast", "C:\Program Files (x86)\GOG Galaxy\Games\Outlast", "EPIC:Outlast", "C:\Program Files\Epic Games\Outlast", "C:\Program Files (x86)\Epic Games\Outlast")
        UninstallSteps = @(
            "Close Outlast first - the mod's own script checks and refuses to run while it is open.",
            "Run 'Outlast-VR.bat' again from Outlast\Binaries\Win64 and choose [2] Uninstall. That is the author's own way and it puts the game config back.",
            "If you would rather do it by hand, delete d3d9.dll, openxr_loader.dll, outlastvr.ini and Outlast-VR.bat from that folder - no base game file is touched.",
            "Your VR tuning lives in outlastvr.ini beside the game, so it goes with those files."
        )
        Tags=@("outlast", "horror", "survival horror", "red barrels", "asylum", "halcyon", "stereo", "gamepad", "openxr", "patreon")
    },
    @{
        Controls    = "VRGP"
        Title       = "Paperklay VR"
        VideoUrl    = "https://www.youtube.com/watch?v=oezn9ILmY4k"
        SteamId     = "1350720"
        Mod         = "Paperklay_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "PaperklayVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
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
        VideoUrl    = "https://www.youtube.com/watch?v=TJDc_4fzpBI"
        SteamId     = "1592290"
        Mod         = "Paranoia_Place_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "ParanoiaPlaceVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#180a18"
        Accent      = "#9933cc"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1391728936039485450/1391728936039485450"
        ModFile     = "BepInEx\plugins\Paranoia_Place_VR.dll"
        SteamFolder = "Paranoia Place"
        FallbackPaths=@("STEAM:ParanoiaPlace", "STEAM:Paranoia Place Demo")
        Tags=@("paranoia place", "paranoiaplace", "astienth", "horror", "psychological", "atmospheric", "story", "indie")
    },
    @{
        Controls    = "VRGP"
        Title       = "Pokemon Gen 1 VR"
        VideoUrl    = "https://www.youtube.com/watch?v=mPyatutVRQ0"
        SteamId     = ""
        PortraitUrl = "Assets/Gen1RecompVR_portrait.jpg"
        HeaderUrl   = "Assets/Gen1RecompVR_header.jpg"
        ScreenshotUrl = "Assets/Gen1RecompVR_screenshot.jpg"
        Quip        = "That Snorlax is blocking the road at full size now. Still no flute."
        # Der Fork ist die lebende Quelle. Das alte Repo (und das Konto)
        # DramaticShape ist weg, GitHub antwortet mit 404.
        Mod         = "Voxel Mod - two versions"
        # !!! KEIN AUTO-UPDATE MEHR - MIT ABSICHT !!!
        # In DRAMALESS 2.0.0 hat der Autor die VR-Unterstuetzung KOMPLETT
        # entfernt (Changelog: "VR support was removed entirely for the time
        # being ... I have no equipment to test and debug it"; README: "The
        # removed OpenXR loader is not distributed in 2.0."). Aus dem Archiv
        # nachgezaehlt fehlen assets\vr\openxr_loader.dll und lib\VR.lua,
        # VRGL.lua, VRRig.lua, VRXR.lua.
        # Bliebe GithubRepo stehen, wuerde der Hub 2.0.0 als Update melden
        # und jeden, der es annimmt, seine VR-Fassung kosten. Der Eintrag
        # bleibt deshalb auf v1.6.4, der letzten Fassung MIT VR.
        # WIEDER EINSCHALTEN, sobald VR zurueck ist - der Autor nennt im
        # Changelog jemanden, der an einer neuen VR-Anbindung fuer Gen1Recomp
        # arbeitet.
        # DER INSTALLER BIETET SEIT 2026-08-13 ZWEI MODS ZUR AUSWAHL, beide
        # mit VR und beide fest gepinnt: die ORIGINALE Dramatic Shape v1.8.2
        # (gespiegelt bei scottcandy34, mit eingebautem First-Person-Modus
        # und den Kampf-Funktionen) und die schlankere Dramaless v1.6.4.
        # Immer nur eine darf in mods\ liegen - die andere wird ganz
        # herausbewegt, nicht umbenannt und nicht geloescht.
        Description = "US .gb or .gbc ROM required"
        Author      = "artyrambles"
        Bat         = "Gen1RecompVR\START_INSTALLER.bat"
        Color       = "#16321c"
        Accent      = "#e8c53c"
        InfoUrl     = "https://github.com/artyrambles/DRAMALESS_SHAPE"
        ModPageUrl  = "https://github.com/artyrambles/DRAMALESS_SHAPE"
        DownloadUrl = "https://github.com/artyrambles/DRAMALESS_SHAPE/releases"
        ModFile     = "gen1recomp.exe"
        # gen1recomp.exe gehoert zum FLACHEN Port - sie liegt auch dann da,
        # wenn die Installation der VR-Mod gescheitert ist. Die Mod selbst
        # liegt in %APPDATA%\pokemon-love2d\mods\ und damit ausserhalb des
        # Spielordners, laesst sich also nicht ueber ModFile pruefen.
        # Der Installer legt deshalb diesen Merker im Spielordner an - und
        # NUR, wenn die manifest.json der Mod wirklich im Mod-Ordner liegt.
        # Fehlt er, meldet die Kachel ein Update statt faelschlich VR Ready.
        # (Wer vor dem 2026-08-13 sauber installiert hat, sieht einmalig ein
        # Update; ein Lauf des Installers legt den Merker an.)
        ModRequiredFile = ".pcvrhub_voxelmod"
        LaunchExe   = "gen1recomp.exe"
        StandaloneVR = $true
        SteamFolder = "Pokemon Gen 1 VR"
        FallbackPaths=@("C:\Games\Pokemon Gen 1 VR", "D:\Games\Pokemon Gen 1 VR", "E:\Games\Pokemon Gen 1 VR")
        UninstallSteps = @(
            "Delete the game folder - C:\Games\Pokemon Gen 1 VR by default.",
            "Delete the mod folder as well: C:\Users\<you>\AppData\Roaming\pokemon-love2d\mods\DRAMALESS_SHAPE. That second path is fixed by the mod platform, not chosen by the Hub."
        )
        Tags=@("gen1 recomp", "gen1recomp", "voxel", "dramaless shape", "dramatic shape", "artyrambles", "diorama", "love2d", "game boy", "retro", "rpg", "adventure", "exploration", "puzzle", "openxr")
    },
    @{ Controls="GP"; Title="Pragmata VR"; VideoUrl="https://www.youtube.com/live/zyx9zEs2W4c?t=834"; Quip="Hack the moon. Hold her hand. Step into the unknown."; SteamId="3357650"; PortraitUrl="Assets/Pragmata_portrait.jpg"; HeaderUrl="Assets/Pragmata_header.jpg"; Mod="REF (auto-update)"; SteamFolder="PRAGMATA"; FallbackPaths=@("STEAM:PRAGMATA"); Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Notice="Pragmata is a brand-new title and this VR mod is early, community-made work built on praydog's REFramework - a genuinely impressive effort given how fresh the game is. Fair warning: it doesn't run smoothly for everyone yet, and the in-game hacking UI can misbehave on some setups. If you hit trouble, it's the early state of the mod, not something you did wrong. Pragmata is also very demanding in VR - see the AFW performance option offered during install, which can help a lot."; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="Pragmata.exe"; Color="#0a0a1a"; Accent="#dd5544"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("pragmata", "reframework", "praydog", "action", "sci-fi"); ModFile="openxr_loader.dll" },
    @{
        Controls    = "GP"
        Title       = "Rebel Galaxy VR"
        VideoUrl    = "https://youtu.be/IoxjXUKUxeM?t=38"
        VideoLabel  = "Watch gameplay"
        Quip        = "Broadside a pirate cruiser with the nebula wrapped around you."
        SteamId     = "290300"
        Mod         = "RebelGalaxyVR v1.1.2"
        # Nexus has no version API, so the tile flips to Update when the
        # installed hook is older than this date (minus the 7-day grace).
        # Bump it whenever Destroyjevski ships a newer build.
        ModReleasedAt = "2026-08-09"
        # EXACT update check, and the reason the Update badge actually
        # appears for people who installed an older build: the hook DLL
        # carries the modder's build time inside the ZIP, and extraction
        # keeps it. So every v1.1.2 install reads 2026-08-09 00:20 no
        # matter WHEN it was installed, and every older build reads
        # earlier. ModReleasedAt above cannot do that on its own - it
        # falls back on the install moment and its 7-day grace, so
        # someone who installed v1.0.0 in the week before this release
        # would never see the badge. Both DLLs (Steam and Epic download)
        # are byte-identical, 197120 bytes, same stamp - one value covers
        # both stores. Bump this with every new build.
        ModBuildStamp = "2026-08-09 00:20"
        Description = "Steam or Epic, Nexus download"
        Author      = "Destroyjevski"
        Bat         = "RebelGalaxyVR\START_INSTALLER.bat"
        Color       = "#0b0a1a"
        Accent      = "#ff8a3d"
        InfoUrl     = "https://www.nexusmods.com/rebelgalaxy/mods/11"
        DownloadUrl = "https://www.nexusmods.com/rebelgalaxy/mods/11?tab=files"
        # The mod IS the XINPUT1_3.dll proxy next to the game exe. Its own
        # switch bats rename it to .disabled for flat mode - same pair the
        # Hub's Flat/VR button uses. ModFileAlt keeps the tile "installed"
        # while flat, otherwise the switch button would disappear.
        ModFile        = "XINPUT1_3.dll"
        ModFileAlt     = "XINPUT1_3.dll.disabled"
        FlatVREnabled  = "XINPUT1_3.dll"
        FlatVRDisabled = "XINPUT1_3.dll.disabled"
        # Needed because of the EPIC build. Its Play in Flat.bat parks the
        # mod as XINPUT1_3.dll.disabled AND copies the game's own
        # xinput1_3_original.dll back under XINPUT1_3.dll - so both names
        # exist while the mod is OFF. Without this flag the switch would
        # read that as VR-on and the next click would rename the restored
        # original over the parked mod, deleting it. With it, the
        # .disabled marker decides: present means parked.
        FlatVRDisabledWins = $true
        SteamFolder = "RebelGalaxy"
        FallbackPaths=@(
            "STEAM:Rebel Galaxy", "GOG:Rebel Galaxy", "GOG:RebelGalaxy",
            "EPIC:RebelGalaxy", "EPIC:Rebel Galaxy",
            "C:\Program Files (x86)\GOG Galaxy\Games\Rebel Galaxy",
            "D:\Program Files (x86)\GOG Galaxy\Games\Rebel Galaxy",
            "C:\Program Files (x86)\Origin Games\Rebel Galaxy",
            "D:\Program Files (x86)\Origin Games\Rebel Galaxy",
            "C:\Program Files\EA Games\Rebel Galaxy",
            "D:\Program Files\EA Games\Rebel Galaxy"
        )
        UninstallSteps = @(
            "Close the game.",
            "Only want to play flat for a while? Do NOT uninstall - use the Flat / VR switch on this page instead.",
            "Open the Rebel Galaxy folder (the one with RebelGalaxySteam.exe on Steam, RebelGalaxy.exe on Epic, or RebelGalaxyGOG.exe) and delete the mod files: XINPUT1_3.dll (or XINPUT1_3.dll.disabled), openxr_loader.dll, RebelGalaxyVR.ini, Play in Flat.bat, Back to VR.bat, Set_Resolution_High.bat, Set_Resolution_Medium.bat, Set_Resolution_Low.bat, Set_Scale_Human_1to1.bat, Set_Scale_Diorama.bat, INSTALL_EN.txt, INSTALLATION_DE.txt, CHANGELOG.txt, the mod LICENSE.txt and RebelGalaxy_VR.ico (the shortcut icon the Hub copied there).",
            "EPIC ONLY: the Epic package also drops Epic_Repair_XInput.bat - delete that too, and rename xinput1_3_original.dll back to xinput1_3.dll. That file is the game's OWN dll, which the installer parked out of the way; leaving it renamed costs you gamepad input in the flat game.",
            "No original game file is touched by this mod, so the flat game is fully playable again afterwards - there is no need to verify or reinstall it.",
            "Delete the 'Rebel Galaxy VR' desktop shortcut if the installer created one (non-Steam installs only)."
        )
        Tags=@("rebel galaxy", "rebelgalaxy", "destroyjevski", "double damage games", "space", "space combat", "spaceship", "trading", "sim", "action", "rpg", "open world", "sci-fi")
    },
    @{
        Controls    = "VRGP"
        Title       = "Ring Racers VR"
        VideoUrl    = "https://youtu.be/F-jco6UCarw?t=19"
        VideoLabel  = "Watch gameplay"
        Quip        = "Lights out - drift the rings and leave Eggman in the dust."
        SteamId     = ""
        PortraitUrl = "Assets/RingRacersVR_portrait.jpg"
        HeaderUrl   = "Assets/RingRacersVR_header.jpg"
        ScreenshotUrl = "Assets/RingRacersVR_screenshot.jpg"
        Mod         = "RingRacers-VR"
        Pill        = "RR-VR"
        Description = "Free OpenXR port."
        Author      = "RaYRoD-TV"
        Bat         = "RingRacersVR\START_INSTALLER.bat"
        Color       = "#141026"
        Accent      = "#e8484c"
        InfoUrl     = "https://github.com/RaYRoD-TV/RingRacers-VR"
        ModPageUrl  = "https://github.com/RaYRoD-TV/RingRacers-VR"
        DownloadUrl = "https://api.github.com/repos/RaYRoD-TV/RingRacers-VR/releases/latest"
        # Background update check: the Hub compares the GitHub latest
        # tag against .installed_version (written verbatim by the
        # installer), so the tile flips to Update on a new release.
        GithubRepo  = "RaYRoD-TV/RingRacers-VR"
        ModFile     = "ringracers-vr.exe"
        LaunchExe   = "ringracers-vr.exe"
        SteamFolder = "Ring Racers VR"
        FallbackPaths=@("C:\Games\Ring Racers VR", "D:\Games\Ring Racers VR", "E:\Games\Ring Racers VR")
        Tags        = @("ring racers", "dr robotnik", "robotnik", "ringracers", "rrvr", "rayrod", "kart krew", "srb2 kart", "fan game", "free", "racing", "kart", "arcade", "openxr")
    },
    @{
        Controls    = "VRGP"
        Title       = "Road Redemption VR"
        VideoUrl    = "https://www.youtube.com/watch?v=1mc8WCVF9Yg"
        SteamId     = "300380"
        Mod         = "RoadRedemption_VR v1.0.0"
        Description = "Steam store version required"
        Author      = "Astienth"
        Bat         = "RoadRedemptionVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#1a0808"
        Accent      = "#dd4422"
        InfoUrl     = "https://github.com/AstienVR/Road_Redemption_VR_bHaptics"
        ModFile     = "BepInEx\plugins\RoadRedemption_VR.dll"
        SteamFolder = "Road Redemption"
        FallbackPaths=@("STEAM:RoadRedemption", "STEAM:Road Redemption Demo")
        Tags=@("road redemption", "roadredemption", "astienth", "road rash", "racing", "combat", "motorcycle", "fighting", "indie")
    },
    @{ Controls="VRGP"; Title="Rogue Flight VR"; VideoUrl="https://www.youtube.com/watch?v=0Bqa7dPUHrM"; SteamId="2784620"; Mod="RogueFlight_VR v1.0.0"; SteamFolder="Rogue Flight"; FallbackPaths=@("STEAM:RogueFlight", "STEAM:ROGUE FLIGHT", "STEAM:ROGUE_FLIGHT", "STEAM:Rogue Flight Demo"); Description="Discord login required."; Author="Astienth"; Bat="RogueFlightVR\START_INSTALLER.bat"; Color="#080820"; Accent="#66ccff"; InfoUrl="https://discord.com/channels/1001138422972432597/1443945389454528634/1443945389454528634"; Tags=@("rogue flight", "rogueflight", "astienth", "anime", "manga", "shooter", "space", "bullet hell", "fast paced", "arcade", "indie"); ModFile="BepInEx\plugins\RogueFlight_VR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="Sayonara Wild Hearts"; VideoUrl="https://www.youtube.com/watch?v=Zcg-dsjjyYs"; Pill="SAYONARAWH_VR"; SteamId="1122720"; Mod="SayonaraWH_VR v1.0.0"; SteamFolder="Sayonara Wild Hearts"; FallbackPaths=@("STEAM:SayonaraWildHearts", "GOG:Sayonara Wild Hearts", "EPIC:Sayonara Wild Hearts", "EPIC:SayonaraWildHearts"); Description="Discord login, depth + bHaptics"; Author="Astienth"; Bat="SayonaraWildHeartsVR\START_INSTALLER.bat"; Color="#180a18"; Accent="#cc44aa"; InfoUrl="https://discord.com/channels/1001138422972432597/1253317358735327354/1253317358735327354"; Tags=@("sayonara wild hearts", "sayonarawildhearts", "astienth", "simogo", "annapurna", "music", "rhythm", "arcade", "casual", "stylized", "indie", "lgbtq", "atmospheric", "bhaptics"); ModFile="BepInEx\plugins\UnityVRPlugin_SayonaraWildHearts.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "Delete the renamed file plus 'BepInEx\\' and 'winhttp_bak.dll' for a full uninstall.", "If you installed the mod into a copy of the game folder, you can also just delete the copy entirely.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{
        # NUR GAMEPAD: der Autor sagt ausdruecklich, dass VR-Motioncontroller
        # noch nicht unterstuetzt werden und ein Controller Pflicht ist.
        Controls    = "GP"
        Title       = "Shenmue I & II"
        VideoUrl    = "https://www.youtube.com/watch?v=tCwMbR1QdWI"
        Quip        = "The sailors are a lie. The forklift is real."
        SteamId     = "758330"
        Mod         = "ShenmueVR (auto-update)"
        Description = "30 FPS, motion smoothing"
        Author      = "Tensai37"
        Bat         = "ShenmueVR\START_INSTALLER.bat"
        Color       = "#101820"
        Accent      = "#c8a24a"
        InfoUrl     = "https://codeberg.org/Tensai37/Shenmue_1_and_2_VR_mod"
        ModPageUrl  = "https://codeberg.org/Tensai37/Shenmue_1_and_2_VR_mod"
        DownloadUrl = "https://codeberg.org/Tensai37/Shenmue_1_and_2_VR_mod/releases"
        DonateUrl   = "https://ko-fi.com/tensai37"
        DonateUrlAlt= "https://www.patreon.com/cw/Tensai37/membership"
        # ERSTER CODEBERG-EINTRAG IM HUB. Codeberg laeuft auf Forgejo und hat
        # dieselbe API-Form wie Gitea; Get-CodebergLatestTagCached in
        # Filter.ps1 fragt sie ab (API zuerst, RSS-Feed als Rueckfall) und
        # legt das Ergebnis in .cb_version_cache mit 6 Stunden Haltbarkeit.
        CodebergRepo = "Tensai37/Shenmue_1_and_2_VR_mod"
        # ERKENNUNG: aus einem echten Vorher/Nachher-Vergleich des
        # Spielordners, nicht geraten. Beide Marker noetig, weil man im
        # Setup auch nur EINES der beiden Spiele auswaehlen kann.
        ModFile     = "sm1\ShenmueVR.ini"
        ModFileAlt  = "sm2\ShenmueVR.ini"
        SteamFolder = "Shenmue I & II"
        FallbackPaths=@("STEAM:Shenmue I & II", "C:\XboxGames\Shenmue I & II\Content", "XBOX:Shenmue I & II")
        # KURZ HALTEN, siehe Konventionen: nur was vor dem Loslegen stehen
        # muss. Controller-Pflicht, Exe-Patch und die 1.07-Anforderung
        # stehen im README in eigenen Abschnitten.
        Notice      = "Both games are hard-capped at 30 FPS, and a faster PC does not lift that cap - frame interpolation is REQUIRED: Asynchronous Spacewarp on Quest over Link or Air Link, Synchronous Spacewarp on Virtual Desktop, Motion Smoothing on SteamVR headsets including PS VR2. Without it the picture judders and the game can crash."
        UninstallSteps = @(
            "Close both games and the Steam launcher.",
            "Open Windows Settings - Apps - Installed apps, search for 'Shenmue I & II VR Mod', open the three-dot menu and choose Uninstall. The mod's own uninstaller restores your game executables from the backup it made.",
            "That backup lives in sm1\.ShenmueVR-installer-backup\ and sm2\.ShenmueVR-installer-backup\ - do not delete those folders before uninstalling, they are the way back.",
            "If anything is left over afterwards, 'Verify integrity of game files' in Steam restores the original executables."
        )
        Tags        = @("shenmue", "sega", "dreamcast", "adventure", "story", "open world", "classic", "first person", "stereoscopic")
    },
    @{ Controls="GP"; Title="Skate Story VR"; VideoUrl="https://www.youtube.com/watch?v=mkGxh11NEuQ"; SteamId="1263240"; Mod="SkateStory_VR v1.0.0"; SteamFolder="Skate Story"; FallbackPaths=@("STEAM:SkateStory", "STEAM:Skate Story Demo", "GOG:Skate Story"); Description="Discord login, OpenVR"; Author="Astienth"; Bat="SkateStoryVR\START_INSTALLER.bat"; Color="#1a0a18"; Accent="#dd3344"; InfoUrl="https://discord.com/channels/1001138422972432597/1454427736327065655/1454427809203359774"; Tags=@("skate story", "skatestory", "astienth", "skate", "skateboarding", "sports", "stylized", "indie", "narrative"); ModFile="VRMod\SkateStoryVR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "For a full uninstall, delete the renamed file plus the 'VRMod\' folder and the extra DLLs the mod added under 'SkateStory_Data\Managed\' and 'SkateStory_Data\Plugins\x86_64\'.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="Sonic P-06 VR"; VideoUrl="https://www.youtube.com/watch?v=OTHkTsVUAXE"; SteamId=""; PortraitUrl="Assets/SonicP06_portrait.jpg"; HeaderUrl="Assets/SonicP06_header.jpg"; Mod="Sonic_P-06_VR v1.0.0"; SteamFolder="Sonic P-06 VR"; FallbackPaths=@("C:\Games\Sonic P-06 VR", "C:\Games\Sonic P06 VR", "C:\Games\SonicP06VR", "D:\Games\Sonic P-06 VR", "E:\Games\Sonic P-06 VR"); Description="Fan game, Discord login."; Author="Astienth"; Bat="SonicP06VR\START_INSTALLER.bat"; Color="#0a1018"; Accent="#3399ff"; InfoUrl="https://discord.com/channels/1001138422972432597/1267088216456953907/1316306250354524221"; Tags=@("sonic", "sonic 06", "sonic p-06", "sonicp06", "project 06", "chaosx", "astienth", "fan game", "platformer", "free", "action"); ModFile="BepInEx\plugins\UnityVRPlugin.dll"; LaunchExe="Sonic the Hedgehog.exe"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "Delete the renamed file plus 'BepInEx\\' and 'winhttp_bak.dll' for a full uninstall.", "To completely remove: delete the entire 'C:\Games\Sonic P-06 VR' (or wherever you extracted the game) folder.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{
        Controls    = "VRGP"
        Title       = "Sonic Robo Blast 2 VR"
        VideoUrl    = "https://www.youtube.com/watch?v=5444EPya_bM"
        Quip        = "Gotta go fast. The rings are RIGHT there now."
        SteamId     = ""
        PortraitUrl = "Assets/SRB2VR_portrait.jpg"
        HeaderUrl   = "Assets/SRB2VR_header.jpg"
        ScreenshotUrl = "Assets/SRB2VR_screenshot.jpg"
        Mod         = "SRB2VR"
        Pill        = "SRB2-VR"
        Description = "Up-to-date OpenXR port."
        Author      = "RaYRoD-TV"
        Bat         = "SonicRoboBlast2VR\START_INSTALLER.bat"
        Color       = "#0c1540"
        Accent      = "#f0b420"
        InfoUrl     = "https://github.com/RaYRoD-TV/SRB2-VR"
        ModPageUrl  = "https://github.com/RaYRoD-TV/SRB2-VR"
        DownloadUrl = "https://api.github.com/repos/RaYRoD-TV/SRB2-VR/releases/latest"
        # Background update check: the Hub compares the GitHub latest
        # tag against .installed_version (written verbatim by the
        # installer), so the tile flips to Update on a new release.
        GithubRepo  = "RaYRoD-TV/SRB2-VR"
        ModFile     = "srb2win.exe"
        LaunchExe   = "srb2win.exe"
        SteamFolder = "Sonic Robo Blast 2 VR"
        FallbackPaths=@("C:\Games\Sonic Robo Blast 2 VR", "D:\Games\Sonic Robo Blast 2 VR", "E:\Games\Sonic Robo Blast 2 VR")
        Tags        = @("sonic", "sonic robo blast", "srb2", "srb2vr", "robo blast", "rayrod", "sonic team junior", "stjr", "fan game", "free", "platformer", "action", "adventure", "openxr")
    },
    @{ Controls="GP"; Title="Spiderman 2 VR"; VideoUrl="https://www.youtube.com/live/WRQLvSJjPkE?t=331"; Quip="Two suits, one city. Swing through New York yourself."; SteamId="2651280";                  Mod="R.E.A.L."; SteamFolder="Marvel's Spider-Man 2"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#3a55cc"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, spider-man 2, marvel", "action", "open world", "story") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Spiderman Miles Morales VR"; VideoUrl="https://www.youtube.com/watch?v=gD-j2ydkENQ"; Quip="Take the leap, Miles. Harlem's skyline is yours."; SteamId="1817190";      Mod="R.E.A.L."; SteamFolder="Marvel's Spider-Man Miles Morales"; Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#aa2266"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, spider-man, miles morales, marvel", "action", "open world", "story") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Spiderman Remastered"; VideoUrl="https://youtu.be/1iIaCNRqJLs?t=395"; Quip="With great power... swing across New York yourself."; SteamId="1817070";         Mod="R.E.A.L."; SteamFolder="Marvel's Spider-Man Remastered"; Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc2233"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, spider-man, spiderman, marvel", "action", "open world", "story") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Star Fox 64 VR"
        VideoUrl    = "https://www.youtube.com/watch?v=Cq86bVrMojQ"
        VideoLabel  = "Watch gameplay"
        SteamId     = ""
        PortraitUrl = "Assets/StarFox64_portrait.jpg"
        HeaderUrl   = "Assets/StarFox64_header.jpg"
        ScreenshotUrl = "Assets/StarFox64_screenshot.jpg"
        Quip        = "Do a barrel roll, Fox - the Lylat System is counting on you."
        Mod         = "Starship VR (auto-update)"
        GithubRepo  = "RaYRoD-TV/StarFox64-VR"
        # DAS PROJEKT HAT AUSSCHLIESSLICH PRERELEASES (v0.1.2-beta bis
        # v0.1.6-beta, jede als Pre-release markiert). Ohne diese Flagge
        # fragt der Scan /releases/latest ab, und das gibt es dort nicht -
        # es kam also NIE eine Update-Kachel, egal wie alt der installierte
        # Stand war. Der Installer holt schon immer die neueste Ausgabe mit
        # einer .zip aus /releases, nur der Katalog wusste es nicht.
        GithubPrerelease = $true
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
        VideoUrl    = "https://youtu.be/9AwqfzRttlk?t=28"
        VideoLabel  = "Watch gameplay"
        SteamId     = "2626120"
        Mod         = "StarRacer_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "StarRacerVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#180a28"
        Accent      = "#ffcc22"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1424109526621360240/1424109638558679142"
        ModFile     = "BepInEx\plugins\StarRacer_VR.dll"
        SteamFolder = "Star Racer"
        FallbackPaths=@("STEAM:StarRacer", "STEAM:Star Racer Demo")
        Tags=@("star racer", "starracer", "astienth", "f-zero", "fzero", "racing", "arcade", "retro", "sci-fi", "indie")
    },
    @{
        Controls    = "GP"
        Title       = "Star Trucker VR"
        VideoUrl    = "https://youtu.be/ud_uGwMR4sU?t=424"
        VideoLabel  = "Watch gameplay"
        Quip        = "Big rig, bigger view - haul the void in stereo."
        SteamId     = "2380050"
        Mod         = "StarTruckerVR v1.1.0"
        Description = "Nexus download required"
        Author      = "Destroyjevski"
        Bat         = "StarTruckerVR\START_INSTALLER.bat"
        Color       = "#0b1020"
        Accent      = "#e0a83a"
        InfoUrl     = "https://www.nexusmods.com/startrucker/mods/17"
        ModFile     = "Mods\StarTruckerVR.dll"
        # Nexus has no version API the Hub can poll, so updates are tracked
        # by release date: if the installed StarTruckerVR.dll is older than
        # this (minus a 7-day grace), the tile flips to Update. Bump this
        # date whenever Destroyjevski ships a newer StarTruckerVR build.
        ModReleasedAt = "2026-08-09"
        # The exact check, and the one that actually makes the Update badge
        # show up for everyone still on an older build: StarTruckerVR.dll
        # carries the modder's build time inside the ZIP and extraction
        # keeps it, so every v1.1.0 install reads 2026-08-09 12:41 no matter
        # WHEN it was installed, and every older build reads earlier.
        # ModReleasedAt above cannot manage that on its own - it falls back
        # on the install moment and its 7-day grace, so someone who put
        # v1.0.2 on in the week before this release would never be told.
        # Bump this with every new build.
        ModBuildStamp = "2026-08-09 12:41"
        SteamFolder = "Star Trucker"
        FallbackPaths=@("STEAM:Star Trucker", "GOG:Star Trucker", "C:\XboxGames\Star Trucker\Content", "D:\XboxGames\Star Trucker\Content", "XBOX:Star Trucker")
        UninstallSteps = @(
            "Close the game.",
            "Remove the mod files: 'Mods\StarTruckerVR.dll' (or 'Mods\StarTruckerVR.dll.disabled' if you left it in flat mode), 'Play in Flat.bat', 'Back to VR.bat', the two OpenXR plugins under 'Star Trucker_Data\Plugins\x86_64' (UnityOpenXR.dll, openxr_loader.dll), and 'Star Trucker_Data\UnitySubsystems\UnityOpenXR'.",
            "Remove the mod's own paperwork in the game folder too: 'StarTruckerVR-README.txt', 'StarTruckerVR-CHANGELOG.txt', 'StarTruckerVR-SHA256SUMS.txt' and the 'StarTruckerVR-LICENSES' folder.",
            "To also remove the bundled MelonLoader: 'version.dll', 'dobby.dll', and the 'MelonLoader' folder.",
            "Only remove MelonLoader / OpenXR files if no other mod needs them, and don't delete whole 'Mods' / 'Plugins' / 'UserData' folders that hold other mods' files."
        )
        Tags=@("star trucker", "startrucker", "destroyjevski", "space", "trucking", "driving", "sim", "simulation", "sci-fi")
    },
    @{ Controls="GP"; Title="Star Wars Outlaws VR"; VideoUrl="https://www.youtube.com/watch?v=tOv5RlTEx9k"; Quip="Scoundrel's life in a galaxy far, far away - up close."; SteamId="2842040";            Mod="R.E.A.L."; SteamFolder="Star Wars Outlaws"; FallbackPaths=@("EPIC:StarWarsOutlaws", "UBI:Star Wars Outlaws"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc8844"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, star wars, outlaws", "open world", "action", "sci-fi") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Starfield VR"; VideoUrl="https://youtu.be/3KEH4H-wSI8?t=94"; Roomscale=$true; SteamId="1716740"; Mod="starfield2vr (auto-update)"; GithubRepo="mutars/starfield2vr"; SteamFolder="Starfield"; FallbackPaths=@("XBOX:Starfield", "C:\XboxGames\Starfield\Content", "EPIC:Starfield"); Description="KB&M or Gamepad VR"; Author="mutars"; Bat="StarfieldVR\START_INSTALLER.bat"; Color="#0a1020"; Accent="#4488dd"; InfoUrl="https://github.com/mutars/starfield2vr"; Tags=@("starfield", "bethesda", "space", "fps", "open world", "rpg", "sci-fi", "shooter") ; ModFile="dxgi.dll"; UninstallSteps=@("Delete the files the mod added to the game folder: dxgi.dll and openvr_api.dll (OpenVR version) or openxr_loader.dll (OpenXR version).", "On Steam, 'Verify integrity of game files' is the cleanest way back to the vanilla state.", "Your saves are untouched - Starfield keeps them outside the game folder.") },
    @{ Controls="GP"; Title="Stray VR"; VideoUrl="https://youtu.be/pxNbbUyfc9Y?t=20"; Quip="Be the cat. Knock things off ledges in the neon depths."; SteamId="1332010";                        Mod="R.E.A.L."; SteamFolder="Stray"; FallbackPaths=@("EPIC:Stray"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc8833"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, stray, cat", "adventure", "exploration", "cyberpunk") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Street Fighter 6 VR"; VideoUrl="https://www.youtube.com/watch?v=TqSGRPczCwc"; Quip="Round one. Fight! Throw hands face to face."; SteamId="1364780"; Mod="REF (auto-update)"; SteamFolder="Street Fighter 6"; Description="KB`&M or Gamepad VR"; Author="praydog"; GitHubNightly="praydog/REFramework-nightly"; Bat="REFrameworkVR\START_INSTALLER.bat"; GameExe="SF6.exe"; Color="#1a0000"; Accent="#ff2200"; InfoUrl="https://github.com/praydog/REFramework"; Tags=@("street fighter 6", "reframework", "praydog", "action", "fast paced", "fighting", "arcade", "competitive"); ModFile="openxr_loader.dll" },
    @{ Controls="GP"; Title="StreetDog BMX VR"; VideoUrl="https://www.youtube.com/watch?v=6n3lxLmrPPA"; SteamId="2707870"; Mod="StreetDogBMX_VR v1.0.0"; SteamFolder="Street Dog BMX"; FallbackPaths=@("STEAM:StreetDogBMX", "STEAM:Streetdog BMX", "STEAM:StreetDog BMX", "STEAM:Street Dog BMX Demo"); Description="Discord login required."; Author="Astienth"; Bat="StreetDogBMXVR\START_INSTALLER.bat"; Color="#1a0a08"; Accent="#ff7744"; InfoUrl="https://discord.com/channels/1001138422972432597/1481693413479944417/1481693511601357072"; Tags=@("streetdog bmx", "streetdog", "street dog", "astienth", "racing", "sports", "fast paced", "indie", "bmx", "cartoon"); ModFile="BepInEx\plugins\StreetDogBMX_VR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "Delete the renamed file plus 'BepInEx\' and 'winhttp_bak.dll' for a full uninstall.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="Sunrise GP VR"; VideoUrl="https://www.youtube.com/watch?v=yoUHwjvXzmM"; SteamId="2670800"; Mod="SunriseGP_VR v1.0.0"; SteamFolder="Sunrise GP"; FallbackPaths=@("STEAM:SunriseGP", "STEAM:Sunrise GP Demo"); Description="Discord login required."; Author="Astienth"; Bat="SunriseGPVR\START_INSTALLER.bat"; Color="#180a08"; Accent="#ffaa66"; InfoUrl="https://discord.com/channels/1001138422972432597/1362074365952528494/1362074365952528494"; Tags=@("sunrise gp", "sunrisegp", "astienth", "racing", "cell shading", "cel-shaded", "arcade", "indie", "cartoon"); ModFile="BepInEx\plugins\SunriseGP_VR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{
        Controls    = "VRGP"
        Title       = "Super Mario 64 VR"
        VideoUrl    = "https://youtu.be/ssNjE0aBPpY?t=736"
        VideoLabel  = "Watch gameplay"
        SteamId     = ""
        PortraitUrl = "Assets/SuperMario64_portrait.jpg"
        HeaderUrl   = "Assets/SuperMario64_header.jpg"
        ScreenshotUrl = "Assets/SuperMario64_screenshot.jpg"
        Quip        = "Wahoo! Grab your cap and go bag every last star."
        Mod         = "sm64coopdx VR (auto-update)"
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
    @{ Controls="VRGP"; Title="Super Polygon Grand Prix VR"; VideoUrl="https://www.youtube.com/live/feihSAnJVsU?t=259"; VideoLabel="Watch gameplay"; Pill="SPGP_VR"; SteamId="2459860"; Mod="SPGP_VR_1.0"; SteamFolder="SP-GP Super Polygon Grand Prix"; FallbackPaths=@("STEAM:Super Polygon Grand Prix", "STEAM:SuperPolygonGrandPrix", "STEAM:SPGP", "STEAM:SP-GP Super Polygon Grand Prix Demo"); Description="Discord login required."; Author="Astienth"; Bat="SuperPolygonGrandPrixVR\START_INSTALLER.bat"; Color="#0a0a18"; Accent="#5588ff"; InfoUrl="https://discord.com/channels/1001138422972432597/1492448070862901308/1492448247090778173"; Tags=@("super polygon grand prix", "spgp", "spgp_vr", "astienth", "racing", "sports", "fast paced", "indie", "arcade", "virtua racing"); ModFile="BepInEx\plugins\SPGP_VR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "Delete the renamed file plus 'BepInEx\' and 'winhttp_bak.dll' for a full uninstall.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="The Dark Mod VR"; VideoUrl="https://youtu.be/25vCsHJdeeo?t=214"; Mod="thedarkmodvr"; Description="Thief-like stealth, gamepad."; Author="Holger Frydrych"; Bat="TheDarkModVR\START_INSTALLER.bat"; Color="#0e0b07"; Accent="#c9a227"; InfoUrl="https://github.com/fholger/thedarkmodvr/wiki/Installation"; ModPageUrl="https://github.com/fholger/thedarkmodvr"; SupportUrl="https://ko-fi.com/fholger"; SupportText="fholger maintains these PC VR mods. If you enjoy them, consider supporting him:"; Quip="Stay to the shadows, taffer - the City has gone three-dimensional."; PortraitUrl="Assets/TheDarkModVR_portrait.png"; HeaderUrl="Assets/TheDarkModVR_header.png"; ScreenshotUrl="Assets/TheDarkModVR_screenshot.jpg"; LaunchExe="TheDarkModVRx64.exe"; ModFile="TheDarkModVRx64.exe"; SteamFolder="The Dark Mod VR"; FallbackPaths=@("C:\Games\The Dark Mod VR", "D:\Games\The Dark Mod VR", "E:\Games\The Dark Mod VR"); Tags=@("the dark mod", "dark mod", "darkmod", "tdm", "thief", "stealth", "frydrych", "fholger", "free", "open source", "gothic", "steampunk", "action", "adventure", "horror") },
    @{ Controls="GP"; Title="Tinykin VR"; VideoUrl="https://www.youtube.com/watch?v=YAD5O90SsFU"; SteamId="1599020"; Mod="TinykinVR v1.0.0"; SteamFolder="Tinykin"; FallbackPaths=@("STEAM:Tinykin Demo", "STEAM:TinykinDemo", "GOG:Tinykin"); Description="Discord login, depth only"; Author="Astienth"; Bat="TinykinVR\START_INSTALLER.bat"; Color="#0f180a"; Accent="#ff7733"; InfoUrl="https://discord.com/channels/1001138422972432597/1276919154678693908/1276919154678693908"; Tags=@("tinykin", "astienth", "tinybuild", "platformer", "3d platformer", "puzzle", "collectathon", "cute", "cartoon", "stylized", "indie", "story", "exploration", "depth"); ModFile="BepInEx\plugins\TinykinVR.dll"; UninstallSteps=@("To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.", "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into.") },
    @{ Controls="GP"; Title="TLOU Part I VR"; VideoUrl="https://youtu.be/8jTfVwXV9PQ?t=35"; Quip="Joel and Ellie's road through a cordyceps America."; SteamId="1888930";                  Mod="R.E.A.L."; SteamFolder="The Last of Us Part I"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#5a7a3a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, last of us, tlou", "action", "survival", "story") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="TLOU Part II VR"; VideoUrl="https://www.youtube.com/watch?v=vOIFCTiwinI"; Quip="The cycle of revenge, told at arm's length. Brace yourself."; SteamId="2531310";                 Mod="R.E.A.L."; SteamFolder="The Last of Us Part II Remastered"; FallbackPaths=@("STEAM:The Last of Us Part II"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#3a6a3a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, last of us, tlou", "action", "survival", "story") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Uncharted: Legacy of Thieves VR"; VideoUrl="https://youtu.be/lElCQV_S-4A?t=181"; Quip="Sic parvis magna. Nate's last climbs, life-size."; SteamId="1659420"; Mod="R.E.A.L."; SteamFolder="Uncharted Legacy of Thieves Collection"; FallbackPaths=@("EPIC:UnchartedLegacyOfThievesCollection", "EPIC:Uncharted Legacy of Thieves Collection"); Description="KB`&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#8a6a2a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, uncharted", "action", "adventure", "story") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{
        Controls    = "VRGP"
        Title       = "Unmourned VR"
        VideoUrl    = "https://www.youtube.com/watch?v=dHJtCVme-mw"
        SteamId     = "3528970"
        Mod         = "Unmourned_VR v1.0.0"
        Description = "Discord login required"
        Author      = "Astienth"
        Bat         = "UnmournedVR\START_INSTALLER.bat"
        UninstallSteps = @(
            "To play flat without removing anything, use the Flat / VR switch on this game's page in the Hub - it parks the mod's loader for you, and one click brings VR back.",
            "Delete the renamed file plus 'BepInEx\' and 'winhttp_bak.dll' for a full uninstall.",
            "To remove it completely, delete winhttp.dll and the BepInEx folder from the folder the mod was installed into."
        )
        Color       = "#180808"
        Accent      = "#cc3333"
        InfoUrl     = "https://discord.com/channels/1001138422972432597/1462781954570059990/1462781954570059990"
        ModFile     = "BepInEx\plugins\Unmourned_VR.dll"
        SteamFolder = "Unmourned"
        FallbackPaths=@("STEAM:Unmourned Demo")
        LaunchExe   = "Unmourned.exe"
        Tags=@("unmourned", "astienth", "horror", "story", "narrative", "atmospheric", "visage")
    },
    @{
        Controls    = "GP"
        Title       = "Warhammer 40K: Rogue Trader VR"
        VideoUrl    = "https://youtu.be/O9xcoE859MA?t=16"
        VideoLabel  = "Watch gameplay"
        Quip        = "Command your dynasty in true stereo 3D, Lord Captain."
        SteamId     = "2186680"
        Mod         = "RTVR v0.6.151"
        Pill        = "RTVR"
        Description = "Guided Nexus download."
        Author      = "SolemnScribe"
        Bat         = "RogueTraderVR\START_INSTALLER.bat"
        Color       = "#1a1210"
        Accent      = "#d4a017"
        InfoUrl     = "https://www.nexusmods.com/warhammer40kroguetrader/mods/518?tab=description"
        # Owlcat's built-in Unity Mod Manager loads mods ONLY from the
        # user profile, so detection roots there instead of the game dir.
        VrInstallRoot = "USERPROFILE:AppData\LocalLow\Owlcat Games\Warhammer 40000 Rogue Trader\UnityModManager"
        ModFile     = "RTVR\RTVR.dll"
        SteamFolder = "Warhammer 40,000 Rogue Trader"
        GameExe     = "WH40KRT.exe"
        Tags=@("warhammer", "40k", "rogue trader", "rtvr", "rpg", "story", "turn-based", "crpg", "strategy", "owlcat")
    },
    @{ Controls="GP"; Title="Watch Dogs VR"; VideoUrl="https://youtu.be/qUWwPB5by3s?t=504"; Quip="Hack Chicago from the inside. The city's in your palm."; SteamId="243470"; PortraitUrl="Assets/WatchDogs1_portrait.jpg"; Mod="R.E.A.L."; SteamFolder="Watch_Dogs"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#3a7aaa"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, watch dogs", "open world", "hacking", "action") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Watch Dogs 2 VR"; VideoUrl="https://www.youtube.com/watch?v=NDtGUJV4iMU"; Quip="DedSec needs you, Marcus. Hack all of San Francisco."; SteamId="447040";                 Mod="R.E.A.L."; SteamFolder="Watch_Dogs2"; Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#33aa6a"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, watch dogs", "open world", "hacking", "action") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Watch Dogs Legion VR"; VideoUrl="https://youtu.be/qCktuvWwys8?t=62"; Quip="Recruit anyone. Take back a near-future London."; SteamId="2239550";            Mod="R.E.A.L."; SteamFolder="Watch Dogs Legion"; FallbackPaths=@("STEAM:WatchDogs_Legion"); Description="KB&M or Gamepad VR"; Author="Luke Ross"; Bat="LukeRossVR\LukeRossVR-core.ps1"; Color="#1a1700"; Accent="#cc4488"; InfoUrl="https://www.patreon.com/realvr"; Tags=@("luke ross, watch dogs", "open world", "hacking", "sandbox") ; ModFile="RealRepo\RealVR64.dll"; ModFileAlt="RealRepo_\RealVR64.dll" },
    @{ Controls="GP"; Title="Witcher 3 VR"; VideoUrl="https://x.com/BadHostile/status/2082683764757426437/video/1"; Quip="Toss a coin to your Witcher - and stand in Velen yourself."; SteamId="292030"; Mod="Witcher3VR (auto-update)"; GithubRepo="tig3rmast3r/witcher3-vr"; GithubPrerelease=$true; Description="Gamepad or KB&M, DX12 only"; Author="tig3rmast3r"; Bat="Witcher3VR\START_INSTALLER.bat"; Color="#12100c"; Accent="#b8973f"; InfoUrl="https://github.com/tig3rmast3r/witcher3-vr"; DownloadUrl="https://github.com/tig3rmast3r/witcher3-vr/releases"; SteamFolder="The Witcher 3"; FallbackPaths=@("STEAM:The Witcher 3 Game of the Year Edition", "GOG:The Witcher 3 Wild Hunt", "GOG:The Witcher 3 Wild Hunt GOTY", "EPIC:TheWitcher3"); ModFile="bin\x64_dx12\dxgi.dll"; LaunchExe="bin\x64_dx12\Witcher3VRLauncher.exe"; Tags=@("witcher 3", "the witcher", "witcher3", "wild hunt", "geralt", "cd projekt", "tig3rmast3r", "rpg", "open world", "action", "story", "atmospheric", "fantasy", "medieval", "dx12") },
    @{ Controls="GP"; Title="Yooka-Laylee VR"; VideoUrl="https://youtu.be/6dPRxLQFETo?t=89"; SteamId="360830"; Mod="VookaRaylee v0.3"; SteamFolder="YookaLaylee"; FallbackPaths=@("C:\Games\Yooka-Laylee VR", "STEAM_CONTENT\YookaLaylee-VR", "GOG:Yooka-Laylee"); DepotInstall=$true; DualMode=$true; DepotPath="C:\Games\Yooka-Laylee VR"; DepotLaunchExe="YookaLaylee64.exe"; DepotLaunchArgs=""; Description="Optional Steam depot version."; Author="Eusth"; Bat="YookaLayleeVR\START_INSTALLER.bat"; Color="#0a1a10"; Accent="#44cc88"; InfoUrl="https://github.com/Eusth/VookaRaylee"; Tags=@("yooka", "laylee", "vooka", "raylee", "platformer", "collectathon", "cartoon") ; ModFile="IPA.exe"; LaunchExe="YookaLaylee64.exe"; UninstallSteps=@("If you modded your own Steam copy: run 'IPA.exe --revert' in the game folder, or use Steam's 'Verify integrity of game files'.", "If you used the separate depot copy: delete the 'Yooka-Laylee VR' folder and the desktop shortcut. Nothing of yours is in there.") }
)

# -------------------------------------------------------
# External installers - alphabetical (HL episodes under Half-Life)
# -------------------------------------------------------
$externalGames = @(
    @{
        Controls    = "MC"
        Title       = "Crysis VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=SBVVxYHqEZw"
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
        VideoUrl    = "https://youtu.be/si5ZRUxIkaA?t=19"
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
        Title       = "Far Cry VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/8sD5DVkP9vI?t=232"
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
        Title       = "Fallout 4 VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=Cd_PspM6Zv8"
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
        Title       = "Firewatch VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=IsogQcYer34"
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
        VideoUrl    = "https://www.youtube.com/watch?v=1WE2lalntY4"
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
        Title       = "Half-Life VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=vFLoijYWR0o"
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
        Title       = "Half-Life 2 VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=fvfzbTDBQo4"
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
        Title       = "HL2 VR Ep. One"; Roomscale=$true
        VideoUrl    = "https://youtu.be/_zYMxlv89tY?t=1046"
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
        Title       = "HL2 VR Ep. Two"; Roomscale=$true
        VideoUrl    = "https://youtu.be/RygwA7sekT8?t=327"
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
        VideoUrl    = "https://youtu.be/KV-SMBYu7IY?t=126"
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
        VideoUrl    = "https://www.youtube.com/watch?v=R49DOJ-8C3E"
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
        VideoUrl    = "https://www.youtube.com/watch?v=y45lFMFjPjk"
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
        Title       = "Morrowind VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/RkmQvMFXTC8?t=224"
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
        VideoUrl    = "https://youtu.be/ZrK9H13Ns0E?t=845"
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
        VideoUrl    = "https://www.youtube.com/watch?v=IDMlU4DRcRI"
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
        Title       = "Portal 2: Community Edition VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/TSAxFKKckes?t=101"
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
        VideoUrl    = "https://www.youtube.com/watch?v=596DdJhwrc4"
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
        Title       = "Resident Evil 2R VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/VtIgVsKPi4I?t=421"
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
        Title       = "Resident Evil 3R VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/a7tj5TUKZXk?t=145"
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
        Title       = "Resident Evil 4R VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=0c8DOFXCzyU"
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
        Title       = "Resident Evil 7 VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=rpYwsYfV0rY"
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
        Title       = "RE Village VR"; Roomscale=$true
        VideoUrl    = "https://youtu.be/dgVd2VWZP5Y?t=350"
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
        Title       = "RE Requiem VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=tKXprWFgPQE"
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
        VideoUrl    = "https://www.youtube.com/watch?v=UGGtz1lYMNw"
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
        Title       = "Skyrim VR"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=mDO7fpE7lf8"
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
        VideoUrl    = "https://youtu.be/iYt0YlLFjYI?t=88"
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
        VideoUrl    = "https://www.youtube.com/watch?v=xMQDxxXCUUQ"
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
        Title       = "UEVR Deluxe"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=CW60zLLo2fw"
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
        VideoUrl    = "https://www.youtube.com/watch?v=5JmIM0tmnCA"
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
        Title       = "Vivecraft"; Roomscale=$true
        VideoUrl    = "https://www.youtube.com/watch?v=eO1wKJpu53w"
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
$global:REALVR_NEWEST = "v2607"
foreach ($__lrg in $ownGamesGP) {
    if ($__lrg.Bat -like 'LukeRossVR*') { $__lrg.Mod = "R.E.A.L. $global:REALVR_NEWEST" }
}

# -------------------------------------------------------
# FREE games - SINGLE SOURCE OF TRUTH.
# A game is FREE when its catalog entry carries the "free" tag.
# This list is DERIVED from that tag right here, so adding "free"
# to a game's Tags is the ONLY edit needed: it drives the search,
# the green FREE pill on the tile (CardTile), the FREE run on the
# detail page (OverviewPage) and the FREE filter in Explore
# (BannerOvFilters) all at once. Do NOT hand-edit this list.
# (Catalog.ps1 loads before every consumer - see the module load
# order in VRModHub.ps1 - so the list exists when they need it.)
# -------------------------------------------------------
$global:FREE_GAME_TITLES = @()
foreach ($__fg in (@($ownGames) + @($ownGamesGP) + @($externalGames))) {
    if ($__fg.Tags -and (@($__fg.Tags) -contains "free")) {
        $global:FREE_GAME_TITLES += $__fg.Title
    }
}
