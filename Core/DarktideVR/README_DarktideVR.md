# Warhammer 40K: Darktide VR

DarktideVR adds native stereo OpenXR rendering, 6DoF roomscale head tracking, tracked hands, hand-aimed ranged weapons, controller-driven menus and optional third-person presentation in the Mourningstar hub.

## About the Game

Warhammer 40,000: Darktide is Fatshark's cooperative first-person action game set in the hive city of Tertium. The VR mod supports the hub, Psykhanium, SoloPlay and remote mission servers, while the base game remains demanding.

The Hub recognizes the standard Steam folder and `C:\XboxGames\Warhammer 40,000- Darktide\Content`. Connect the headset and select the intended OpenXR runtime before launching. For a current Steam installation, **Start in VR opens Darktide through Steam; press Play in the Fatshark launcher** so the game receives its normal backend sign-in. Do not launch `binaries\Darktide.exe` directly. The public build was developed against the Steam game on Quest 3 through Virtual Desktop/VDXR and NVIDIA hardware; Xbox App compatibility and other configurations remain externally unverified by the Hub.

## Controls

Current defaults can be rebound in Darktide's mod options.

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Right Stick]] | Turn |
| [[Left Stick Click]] | Sprint |
| [[Right Stick Click]] | Tag; tag empty space for a location marker |
| [[Right Trigger]] | Fire; hold to skip a cutscene or video; select pointed menu items |
| [[Left Trigger]] | Aim or weapon alternate |
| [[Right Grip]] | Weapon special |
| [[Left Grip]] | Combat ability |
| [[A]] | Jump / dodge |
| [[B]] | Blitz / menu back |
| [[X]] | Crouch |
| [[Y]] | Cycle device, ammo crate and stim; context menu action |
| [[Right Stick Up]] | Quick wield / return to the last weapon |
| [[Right Stick Down]] | Interact / reload |

The first calibration uses a T-pose and arms-at-sides pose to establish body and official character height. Text entry still needs a physical keyboard; the character-name Randomize button works with the pointer.

## Current v0.3.0-alpha.1 changes

The current build adds an optional full body, physical servo-skull grabbing and throwing, an item radial, hand-to-mouth push-to-talk, weapon charge display, aim zoom and an [[F8]] Psykhanium mirror. It also fixes loading/menu FOV, ADS vignette behavior, wheel conflicts, hand displays, skull positioning, calibrated height, smoothing and several item-radial and push-to-talk issues. Full body costs performance and still has cloth, feet and mirror limitations. Experimental two-hand support, virtual stock and ADS, holsters, wrist/team HUDs, ammo handling and haptics remain included and can still change.

## Current and pinned-depot setup

Installer option 1 follows the newest GitHub release, including prereleases, and installs missing Darktide Mod Loader and Darktide Mod Framework components before activating VR in the normal game. A new game update can temporarily break that route.

Option 2 creates a separate `C:\Games\Darktide VR 24735202` copy from Steam build **24735202**. It pins all three required Windows depots (`1361211`, `1361212`, `1361213`), DarktideVR **v0.1.0-alpha.3**, Darktide Mod Loader **26.06.24** and Darktide Mod Framework commit **fc08c1cb772f86248c7ae9e957543e801a0dbf64**. The download is about 96.4 GiB. The normal Steam installation is not replaced, `steam_appid.txt` is written beside the Fatshark launcher, and both routes can coexist as separate buttons in the Hub.

Keep Steam running and signed in for the depot. Its Hub button and desktop shortcut start the pinned copy's own Fatshark launcher; press Play there. They never open the current Steam game folder. Because Darktide is an online game, a future Fatshark backend update can still reject an old client even though the game and complete mod stack remain locally pinned.

The publisher's mode tool keeps a pristine executable recovery copy and swaps separate flat/VR settings profiles, installs its own `d3d12.dll` proxy and adds only `darktidevr` to the mod load order. The Hub isolates the depot's recovery state under `.pcvrhub_darktide_state` so a later Current build cannot overwrite the pinned copy's executable backup.

For Current, use `mods\darktidevr\Darktide VR Mode.bat` to switch back to flat mode. For the depot, use `Switch Darktide Depot Mode.bat`; this preserves its isolated recovery path. A Darktide update can disable the shared mod loader; rerun option 1 after an update. If the publisher has not added the new executable build yet, the mode tool deliberately refuses to patch it until a compatible DarktideVR release exists.

## Known limits

Presentation is currently right-hand dominant, independent weapon origins on mission servers are incomplete, movement speed follows aim direction, votes cannot yet be answered in VR, and ledge discovery can follow hand aim. Keep the game window focused: controller input and DLSS frame generation pause when focus is lost.

## Removal and support

**Uninstall now** restores flat mode first and removes only unchanged DarktideVR-owned files. If Current and Build 24735202 are both installed, it asks which independent copy to change. It leaves the shared Darktide Mod Loader and Darktide Mod Framework installed because other mods may use them, preserves per-mode settings and recovery data, and does not delete the large pinned base-game copy.

- [DarktideVR project and documentation](https://github.com/Brobert-in-aus/darktide-vr)
- [GitHub releases](https://github.com/Brobert-in-aus/darktide-vr/releases)
- [Nexus Mods page](https://www.nexusmods.com/warhammer40kdarktide/mods/1304?tab=files)
