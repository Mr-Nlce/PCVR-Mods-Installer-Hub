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

## Current v0.3.0-alpha.2 changes

This release supports game 1.13.1 and 1.13.2. It updates character-height and controller-menu handling and keeps Flat mode usable after an unsupported game update. Newer game builds still need explicit support from the mod publisher.

The current build adds an optional full body, physical servo-skull grabbing and throwing, an item radial, hand-to-mouth push-to-talk, weapon charge display, aim zoom and an [[F8]] Psykhanium mirror. It also fixes loading/menu FOV, ADS vignette behavior, wheel conflicts, hand displays, skull positioning, calibrated height, smoothing and several item-radial and push-to-talk issues. Full body costs performance and still has cloth, feet and mirror limitations. Experimental two-hand support, virtual stock and ADS, holsters, wrist/team HUDs, ammo handling and haptics remain included and can still change.

## Installation and updates

The installer follows the newest GitHub release, including prereleases. It installs missing Darktide Mod Loader and Darktide Mod Framework components before activating VR in your normal game.

With the matching 0.3.0-alpha.2 package, setup offers an optional Hub add-on for controller swings and touch interaction. Choose it at the prompt, then find the options under Mod Options → Darktide VR → Melee swing. The included experimental render-state workaround only applies in memory on its matching game build. Its effect on mission crashes is unverified. The separate experimental engine particle option is off by default. Run setup again and decline the add-on to restore the publisher scripts.

Darktide requires an internet connection and the current game client. Older game builds cannot sign in, so the Hub no longer offers a separate frozen game installation. Previously created copies are left on disk; setup does not remove your game files or settings.

The publisher's mode tool keeps a pristine executable recovery copy and swaps separate flat/VR settings profiles, installs its own d3d12.dll proxy and adds only darktidevr to the mod load order.

Use mods/darktidevr/Darktide VR Mode.bat to switch back to flat mode. A Darktide update can disable the shared mod loader; rerun setup after an update. Setup uses the newly downloaded publisher mode tool to prepare an update, so an older installed tool cannot block its own replacement. If the publisher has not added your executable build yet, setup leaves it unchanged and asks you to wait for a compatible DarktideVR release.

## Known limits

Presentation is currently right-hand dominant, independent weapon origins on mission servers are incomplete, movement speed follows aim direction, votes cannot yet be answered in VR, and ledge discovery can follow hand aim. Keep the game window focused: controller input and DLSS frame generation pause when focus is lost.

## Removal and support

**Uninstall now** restores flat mode first and removes only unchanged DarktideVR-owned files. It leaves the shared Darktide Mod Loader and Darktide Mod Framework installed because other mods may use them, preserves per-mode settings and recovery data.

- [DarktideVR project and documentation](https://github.com/Brobert-in-aus/darktide-vr)
- [GitHub releases](https://github.com/Brobert-in-aus/darktide-vr/releases)
- [Nexus Mods page](https://www.nexusmods.com/warhammer40kdarktide/mods/1304?tab=files)
