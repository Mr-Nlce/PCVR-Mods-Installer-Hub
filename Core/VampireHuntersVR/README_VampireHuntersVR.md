# Vampire Hunters VR

## About the Game

Vampire Hunters is a fast arcade shooter built around a growing arsenal. Segadreamcat's VR mod places guns in both hands, adds head tracking, controller aiming, stereo menus and haptic feedback. This is a work-in-progress community mod.

## What you need

- The Windows **Steam** game. The publisher only documents and tests Steam; the Xbox App route is not offered as a confirmed installation.
- SteamVR and tracked controllers. The publisher tested Quest 3 through SteamVR.
- BepInEx 6 Bleeding Edge for **Unity IL2CPP win-x64**, tested build 788. The Hub downloads that official build for a clean game, installs it first, then guides you through one **flat** launch to the main menu so BepInEx generates its game interop. A complete existing IL2CPP loader is kept.
- The current [Vampire Hunters VR publisher ZIP](https://github.com/segadreamcat/VampireHuntersVR/releases). The Hub installs the plugin and its `openvr_api.dll` only after the flat first run.

Unsigned VR files may trigger antivirus warnings. Missing files may also result from a copy, path or permissions issue; check the installer log and security history before attributing a cause.

## Install, update and start

1. Choose [[Install]] or [[Update]]. Read each step and press Enter before locating the game, downloading files, starting the flat game or writing files. Keep the game closed except during the guided first launch.
2. On a new BepInEx installation, let the Hub install the official loader. Press Enter to start Vampire Hunters **flat** through Steam, wait until the normal main menu, close the game, then return to the installer. It checks that `BepInEx\interop` was generated before copying the VR plugin. Existing working loader installations skip this first-run step.
3. **Use [[Start in VR]] in the Hub** with SteamVR running. Starting the game from Steam is the same VR route. If the headset remains black, set the game's Steam Launch Options to `-force-d3d11` and retry.

The plugin settings appear after the first VR run in `BepInEx\config\local.vampirehunters.vr.cfg`. Update preserves your settings. The Hub removes only files it installed; an unrelated BepInEx installation is not removed.

## Controls

| Button | Action |
| --- | --- |
| [[Left Stick]] | Walk in the direction you look. |
| [[Right Stick]] | Smooth turn; scroll in menus. |
| [[Right Trigger]] | Fire the right gun or click a menu. |
| [[Left Trigger]] | Fire the left gun. |
| [[A]] | Jump or confirm in menus. |
| [[B]] | Reload. |
| [[X]] | Interact. |
| [[Y]] | Pause menu. |
| [[Left Grip]] / [[Right Grip]] | Bloody Rush dash. |
| [[Left Stick Click]] | Run or special action. |
| [[Right Stick Click]] | Level up. |
| [[Left Stick Click]] + [[Right Stick Click]] / [[F6]] | Recenter. |
| [[F8]] | Toggle VR. |
| [[F7]] | Flip an upside-down menu picture. |

Point the right-hand laser at menu items and use [[Right Trigger]] to click. The publisher's [README](https://github.com/segadreamcat/VampireHuntersVR) documents the full configuration.

## Discord discussion & support

- [Flat2VR Modding invite](https://discord.gg/flat2vr)
- [Vampire Hunters VR discussion](https://discord.com/channels/747967102895390741/1561052736047284334)

## Links

- [Publisher project](https://github.com/segadreamcat/VampireHuntersVR)
- [Official BepInEx Bleeding Edge builds](https://builds.bepinex.dev/projects/bepinex_be)
- [VR gameplay](https://www.youtube.com/watch?v=RhngOA8oRsI)

>>> Tonight, the hunters bring two hands to a gunfight.
