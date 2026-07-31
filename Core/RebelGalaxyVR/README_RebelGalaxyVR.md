# Rebel Galaxy VR Installer

## About this mod
**RebelGalaxyVR** by Destroyjevski puts Rebel Galaxy into stereoscopic OpenXR VR: each eye gets its own correctly projected view, full 6DoF head tracking lets you lean and look around the cockpit, and the whole interface is rendered into a separate high-resolution OpenXR quad layer that stands in the world instead of being pinned to your face. World and HUD have their own supersampling, and there are two selectable world scales.

This is a custom VR implementation built from scratch by the author, after finding that the game's own leftover `VR:1` switch was less a feature toggle than a seance for a long-dead VR pipeline.

*Broadside a pirate cruiser with the nebula wrapped around you.*

https://www.nexusmods.com/rebelgalaxy/mods/11

## Controls
You play with a **gamepad**, exactly like the flat game. Motion controllers are not supported.

- [[LB]] + [[RB]] + [[A]] Recenter the VR view

## What you need first
- Rebel Galaxy. Only the **Steam** version has been tested; other stores may work but are unverified, so the Hub looks for the game across Steam, GOG, GOG Galaxy, Epic, Origin, the EA app and Humble installs.
- An OpenXR-compatible headset, with your preferred runtime active **before** you launch.
- A gamepad.
- The game running in **Borderless Window or Windowed** mode. A desktop resolution of 2560 x 1440 is recommended.

The game's own abandoned VR path must stay switched **off**. In `Documents\My Games\Double Damage Games\RebelGalaxy\local_settings.txt` the line has to read `<INTEGER>VR:0` - the mod supplies its own OpenXR path. `VR:1` must not be used with this mod. The installer checks the file and tells you if it finds `VR:1`.

## How the installer works
The mod is distributed through Nexus Mods behind a free login, so it cannot be downloaded automatically. The installer opens the Files page, then looks in your Downloads and Desktop folders for the archive - or you drag it onto the window. It locates the game (all stores above, plus drag & drop for anything custom), then copies the mod files **next to the game executable**, never into a subfolder. Steam installs keep launching through Steam; every other store also gets a desktop shortcut.

## Image quality presets
The preset files land in the game folder and change the internal per-eye render resolution without touching your desktop window size. Close the game before running one.

| File | Per eye | World | HUD | For |
|---|---|---|---|---|
| `Set_Resolution_High.bat` | 3840 x 4320 | 300% | 200% | Default, high-end GPUs |
| `Set_Resolution_Medium.bat` | 2560 x 2880 | 200% | 150% | Balanced starting point |
| `Set_Resolution_Low.bat` | 1280 x 1440 | 100% | 100% | Maximum performance |

Advanced users can edit `RenderScalePercent` and `HudRenderScalePercent` in `RebelGalaxyVR.ini` directly.

## World scale
| File | Result |
|---|---|
| `Set_Scale_Human_1to1.bat` | Default. Ships, stations, interiors and characters at imposing life size - especially effective inside stations and bars. |
| `Set_Scale_Diorama.bat` | A more compact presentation that still keeps much of the original sense of size. |

Manual equivalent: `EyeOffsetMilli` in `RebelGalaxyVR.ini`.

## Switching between VR and flat
Quit the game first. Use the **Flat / VR switch** on this game's page in the Hub - it highlights whichever mode is currently live. The mod also ships `Play in Flat.bat` and `Back to VR.bat` in the game folder, which do the same thing. Both routes only disable and re-enable the mod; neither removes it.

Either way it comes down to one rename: `XINPUT1_3.dll` is the mod, and `XINPUT1_3.dll.disabled` is it switched off. Note that the mod's own bats look for `RebelGalaxySteam.exe` when they check whether the game is still running, so on a non-Steam copy that guard does not fire - close the game yourself before switching.

## Known limitations
- The yellow planetary orbit circles on the galaxy map currently render in the right eye only. Navigation and normal play are unaffected.
- The menus are a semi-transparent spatial layer, so very bright objects behind them can reduce text readability.
- Targets, stations and waypoint indicators are projected onto the spatial HUD plane rather than attached to objects in the 3D world. Native world-space markers are planned for a future update.
- **Alt-Tab can kill the HUD layer** - a fix is under investigation. The last menu may stay frozen on screen while new menus and other HUD elements stop appearing. Avoid Alt-Tab while playing; if it happens, restart the game.

## Credits
- **RebelGalaxyVR** by Destroyjevski - https://www.nexusmods.com/rebelgalaxy/mods/11
- OpenXR SDK Loader by The Khronos Group, Apache License 2.0
- Rebel Galaxy and its assets by Double Damage Games

The author is also working on a separate VR mod for Rebel Galaxy Outlaw, still at an early stage.
