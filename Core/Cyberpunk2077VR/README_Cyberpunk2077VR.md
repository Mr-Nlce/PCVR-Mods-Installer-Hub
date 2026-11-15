# Cyberpunk 2077 VR

CyberpunkVRPort by dariulone adds real stereo, head tracking, motion-controlled hands and a full-body avatar. Current and Depot are separate installations with their own Start in VR buttons.

## About the Game
Become V, a mercenary in Night City. Follow the story, explore the city and build your own combination of weapons, cyberware and questionable life choices.

## Important
Current requires game 2.5. Depot uses game 2.31 with CyberpunkVRPort 0.1.8 and fixed framework versions. A mod made for one does not work on the other.

The first VR launch merges a graphics, controls, HUD and comfort preset into the game's UserSettings.json after making a dated backup. Language, audio, difficulty and saves are preserved. Keep your GPU driver up to date for game 2.5. Start with a modest headset resolution and Low graphics; leave DEBUG off during normal play.

## What you need
- Your own PC copy of Cyberpunk 2077. Current supports Steam, GOG and Epic paths; the separate Depot download needs Steam ownership.
- An active OpenXR runtime, or the port's supported SteamVR runtime, before starting the game.
- Current only requires RED4ext 1.31.0 or newer. The VR port supplies its own script compiler and the functions it previously used CET, redscript, ArchiveXL, TweakXL, Codeware and Input Loader for. The Depot uses its pinned frameworks, including Input Loader 0.2.3.
- Current updates an existing Mod Settings installation to its current game-2.5 release while keeping your settings. The reviewed release is 0.2.30. Mod Settings 0.2.21 can cause a silent startup crash on 2.5.
- Depot requires More Occluders Scripted v0.3 from Nexus. Current does not install it: this script cannot compile on game 2.5 and prevents all scripts from loading. Setup backs up and disables this incompatible script; a future compatible script is kept. The 0.2.2 release and included INSTALL.txt explicitly retire this requirement for Current; some repository README requirement bullets are older.
- Enough free space for a second game copy if using Depot: about 62 GB, plus about 23 GB for Phantom Liberty and extra space for any additional voice language. Steam retains a download-cache copy as well, so allow roughly twice that space until the cache is removed.

## Install and start
1. Close Cyberpunk 2077 and choose Install or Update in the Hub.
2. Choose Current 2.5 or the separate Depot 2.31. The installer checks the selected game's actual executable version.
3. For Current, if you previously selected 2_31_old: open Game versions & betas in Steam Properties and choose the public default version at the very top. Wait for Steam to finish, then let the installer check the version again.
4. For Depot, choose a separate folder. The installer shows the pinned Steam Console commands before opening the console on Enter. It checks existing complete copies first. Phantom Liberty and other voice languages are optional pinned downloads.
5. Finish the guided mod downloads. Current obtains the latest stable VR port and RED4ext. Depot keeps its mod, all six frameworks and Input Loader fixed.
6. Use Start in VR in the Hub for the copy you want. Alternatively, use Cyberpunk 2077 VR or Cyberpunk 2077 VR 2.31 on your Desktop. In the mod's configuration window, choose your headset and resolution, then continue into the game.

Allow time for the VR configuration window to appear; it took about 20 seconds in the tested 2.5 setup. The Hub starts this copy directly, so REDlauncher does not need to appear.

## Saves between versions
Before Current changes the mod files, the installer makes a one-time verified copy of existing saves, including .bak files. It remains in PCVRHub-Cyberpunk-SaveProfiles/Backups. A backup does not prove that its saves are compatible with 2.31.

2.5 saves must not be assumed compatible with 2.31. The Hub launchers keep separate Current and Depot save profiles. On the first switch, your existing complete save folder, including backups, is preserved as Current and Depot starts with an empty profile. Switching back restores the other profile without overwriting an already parked set.

Before switching, disable Steam Cloud and the game's cross-platform cloud saves for both copies, as the launcher explains. Always use the matching Hub button or Desktop shortcut for switching. Starting a game executable directly bypasses this protection. Your parked saves remain under Saved Games/CD Projekt Red/PCVRHub-Cyberpunk-SaveProfiles. Keep your own backup before manually importing an older compatible save.

## What's new in Current 0.2.45
- Physics hands are on by default. Hands can push props, grasp objects and climb ledges. Use **Hand physics** in the launcher or settings to turn it off.
- Motorcycle steering uses the handlebars and body lean. The route and minimap can appear above the hood or handlebars.
- 0.2.45 fixes HUD flicker when frame generation is disabled on Virtual Desktop, Quest Link and other affected OpenXR runtimes. The default frame generator is NVIDIA OFA with FidelityFX.
- The scanner now uses a left stick click with your hand by your left ear. Built-in holsters, room-scale mirrors and camera smoothing from 0.2.3 are still available.
- [Publisher release notes](https://github.com/dariulone/cyberpunk-vr-port/releases/tag/0.2.45)

## Current 0.2.2 features
- Immersive holsters carry equipped weapons on the body. Reach for a weapon and squeeze its grip; choose holster positions in the VR inventory. Both hands have their own holsters when dual wielding.
- Hands-only avatar mode, mirrored left-handed controls, optional stick-click sprint and additional HUD clearance settings are available in the VR menu.
- Optional finger tracking and Vive-tracker body tracking start disabled. They need supported hardware and calibration.
- The update includes single-pass stereo improvements and fixes for reflections, path-tracing crashes, climbing, holsters and starting a new game from the lobby.
- Keep Engine stereo for normal play. The publisher labels AFW/OSR experimental performance-test options; they are not recommended defaults.
- The package includes its DirectX compiler under red4ext/plugins/cyberpunkvrport/dxc. Setup and the start app verify both compiler DLLs for 0.2.2 and later.
- Camera selection, launcher preferences, calibration and saved Wrist HUD settings survive updates.

## Current package layout
- The native plugin and its scripts, Lua mods, archive and configuration now live together under red4ext/plugins/cyberpunkvrport. Updates back up superseded port code and keep user settings; the separate 2.31 Depot keeps its old layout.
- For Current, install the VR port and RED4ext 1.31.0 or newer. Keep optional frameworks if your other mods depend on them.

## Earlier Current features
- Built for game 2.5, using its own stereo renderer. Intro and loading screens are mono; stereo starts at the main menu.
- A controller-operated VR menu for inventory, equipment, crafting, cyberware, quests, map, saves and settings.
- Touch interaction with world screens, expanded physical reloading and dual wielding.
- HUD placement is built in. HUDitor, the old VR UI repositioning scripts and Visible Bullets are not required. Existing third-party mods are not silently deleted. Superseded port-owned menu files are backed up outside the active script paths.
- The tactical belt has its own slot. Visual Holsters, Equipment-EX, Nova Optics and More Occluders are optional on Current. Setup retains third-party files except for the incompatible More Occluders script described above.

## Controls
The table describes Current 0.2.45 with right-handed defaults. Mirror options and optional stick-click sprint can be selected in the VR settings. Depot retains the 0.1.8 mappings shown in its F10 settings.

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Left Stick Fully Forward]] hold 0.2 seconds / [[Left Stick Click]] in click-sprint mode | Sprint; click mode continues until the stick is released |
| [[Right Stick Left]] / [[Right Stick Right]] | Snap or smooth turn |
| [[Right Stick Up]] | Dash |
| [[Right Stick Down]] | Crouch |
| [[Right Stick Click]] | Rack the weapon / release its slide |
| [[Right Trigger]] / [[Left Trigger]] | Fire / aim; left trigger also blocks in melee |
| [[Right Grip]] / [[Left Grip]] at a holster | Draw or put away that hand's weapon; grip can also modify melee |
| [[Left Grip]] | Grab a magazine |
| [[Left Stick Click]] with your left hand at your left ear | Open the scanner; click again to close |
| [[Left Grip]] + [[Left Trigger]] | Pull the held magazine during a physical reload |
| [[Left Stick Click]] + [[Right Stick Click]] hold 0.5 seconds | Open or close the VR menu |
| [[Left Stick Click]] + [[Left Grip]] hold 0.5 seconds | Activate iconic cyberware |
| [[A]] | Jump; confirm vehicle dialogue |
| [[B]] | Drop the right weapon's magazine; close phone/radio/vehicle list while one is open |
| [[X]] | Interact / normal reload |
| [[Y]] tap | Next weapon |
| [[Y]] hold | Weapon switch / wheel |
| [[Menu]] | Pause |
| [[Left Stick Up]] / [[Left Stick Down]] fully, scanner open | Page the quickhack list |
| [[X]], scanner open | Apply quickhack |
| [[Right Trigger]], scanner open | Tag target |
| [[Right Stick Click]], scanner open | Change tab |
| [[Left Trigger]] + [[Right Stick]], scanner open | Zoom |
| [[Left Stick Click]] held + [[Right Stick Direction]] | D-pad chord |
| [[Left Trigger]] + [[Right Grip]], then release [[Right Grip]] while throwing | Throw a throwable melee weapon |
| [[Swing a Melee Weapon]] | Motion melee |
| [[Squat]] | Physical crouch |

### Driving
| Button | Action |
|---|---|
| [[Grip]] at the steering wheel | Grab wheel; steer by the angle between your hands |
| [[Touch Wheel Centre]] | Horn |
| [[Right Trigger]] / [[Left Trigger]] | Throttle / brake; with a weapon out, right trigger fires |
| [[Left Stick Forward]] / [[Left Stick Back]], weapon out | Adjust latched throttle |
| [[X]] hold | Leave vehicle |
| [[Perspective Toggle]] | Change native camera view |
| [[A]] | Confirm a dialogue choice |

## The F10 overlay
| Button | Action |
|---|---|
| [[F7]] | Recenter headset |
| [[F8]] | Switch the flat menu panel size |
| [[F10]] / [[Insert]] | Open settings overlay |
| [[Trigger]] pointing at a VR menu item | Select |
| [[Grip]] on a panel | Drag panel |

Configure world scale, comfort, turning, HUD panels, driving, avatar and frame generation here. Current keeps its configuration in red4ext\plugins\cyberpunkvrport\config\vrport.ini; Depot uses bin\x64\vrport.ini. Start conservatively; resolution and ray tracing can be very demanding.

## VR files
The VR mod folder and start app will appear here as links once the VR mod installation is present. If the Hub does not find your game, you can choose Locate Game to select its game executable or start app.

Current keeps the native plugin under red4ext/plugins/cyberpunkvrport; Depot keeps it under red4ext/plugins/CyberpunkVR_Stereo. Each game copy has its own PCVR-Cyberpunk/Start VR.vbs. The Hub uses that copy's start app. It calls PCVR-Cyberpunk/Start-CyberpunkVR.ps1 without extra arguments; the script finds the game folder containing PCVR-Cyberpunk. The game executable is bin/x64/Cyberpunk2077.exe and runs with bin/x64 as its working directory.

The separate Depot defaults to C:/Games/Cyberpunk 2077 VR 2.31; you can choose another folder. It contains steam_appid.txt for app 1091500 in its root and bin/x64, and never receives Current mod/framework updates.

## Help
If the game will not start, check the actual game version and selected route first. Current needs 2.5; Depot needs 2.31. An old CyberpunkVR_Hands DLL or another dxgi.dll VR proxy can conflict with the port. The installer preserves disabled files outside active plugin paths.

If the redscript log reports an override error in `Codeware.Global.reds` or an ambiguous `GetActiveWeapon` call while Nova Optics and other scripts are present, update the affected third-party mods together or temporarily disable them and their dependants in your mod manager. Test the game with just RED4ext and CyberpunkVRPort, then re-enable the other mods one group at a time. Existing frameworks and gameplay mods are kept for the mods that still need them.

The Current mod log is red4ext/plugins/cyberpunkvrport/log/cyberpunkvrport.log; the older Depot uses bin/x64/cyberpunkvrport.log. RED4ext logs are in red4ext/logs. Missing files do not by themselves prove antivirus quarantine. The installer offers recheck, repair and manual-file recovery.

## Uninstall Guide
For temporary flat play, use the Hub Flat / VR switch. It parks only the selected native plugin (cyberpunkvrport.dll for Current, CyberpunkVR_Stereo.dll for Depot); the port's scripts remain idle without that native plugin.

For removal, choose Uninstall Now for the selected game copy. The owned-file uninstaller removes unchanged Hub-installed VR files and restores original backed-up files. User-modified files, shared frameworks, saves and the other game copy remain. Save profiles and their launcher are retained so you can return to your other profile. The publisher's UNINSTALL.bat is an alternative with its own removal rules; read its confirmation before using it.

Uninstall first restores the Current save profile if Depot saves are active. The matching Desktop shortcut is removed; both parked save profiles and their safety backup remain available.

## Donations
- [Support CyberpunkVRPort author dariulone on Boosty](https://boosty.to/dariulone)
- [Support dariulone on DonationAlerts](https://dalink.to/dariulone)
- [Support the Cyber Engine Tweaks framework developers on Patreon](https://www.patreon.com/tiltedphoques)

## Links
- [Mod source and documentation](https://github.com/dariulone/cyberpunk-vr-port)
- [Current releases](https://github.com/dariulone/cyberpunk-vr-port/releases)
- [Pinned Depot mod 0.1.8](https://github.com/dariulone/cyberpunk-vr-port/releases/tag/0.1.8)
- [Input Loader source and releases](https://github.com/jackhumbert/cyberpunk2077-input-loader)
- [More Occluders - Scripted v0.3 for Depot 2.31 only](https://www.nexusmods.com/cyberpunk2077/mods/33136)
- [Mod Settings - current game-2.5 releases](https://github.com/jackhumbert/mod_settings/releases)

>>> Wake up, samurai. Night City won't burn itself down.
