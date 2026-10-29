# Blood West VR

## About the Game

A restless gunslinger hunts grotesque creatures across a cursed frontier. King-EJ's mod adds stereo OpenXR, tracked weapons, physical melee and adjustable weapon grips to Blood West.

## What you need

- The Windows Steam Mono x64 game and an active OpenXR runtime. SteamVR, Virtual Desktop and Oculus runtimes are documented by the author.
- The publisher ZIP contains the complete BepInEx 5 x64 loader as well as BloodWestVR and its native OpenXR library. The Hub installs the full required runtime; no separate loader download is needed.
- Close the game before installing or updating. Existing IL2CPP loaders are incompatible with this Mono setup and must be resolved first.

## Install and start

1. Choose [[Install]] in the Hub. The installer shows the game folder, downloads the current publisher package and preserves existing configuration files and unrelated mods.
2. Connect the headset and activate its OpenXR runtime.
3. Choose [[Start in VR]] in the Hub. Starting Blood West through Steam is the alternative.

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move. |
| [[Right Stick Left]] / [[Right Stick Right]] | Turn. |
| [[Right Stick Down]] | Change ammunition. |
| [[Right Stick Up]] | Throw a stone. |
| [[Right Trigger]] | Attack or fire. Swing a melee weapon physically to strike. |
| [[Left Trigger]] | Aim or block. |
| [[Right Grip]] | Laser; right bumper in menus. |
| [[Left Grip]] | Hold the weapon wheel; left bumper in menus. Select with [[Right Stick]]. |
| [[X]] | Tap to use; hold 0.6 seconds for inventory. |
| [[A]] + [[B]] | Pause. |
| [[Left Stick Click]] + [[Right Stick Click]] | Tap to recenter; hold 1.2 seconds for VR settings. |
| [[Left Stick Click]] + [[Y]] | Adjust weapon position. |
| [[Left Stick Click]] + [[X]] | Adjust weapon hand. |
| [[Left Stick Click]] + [[B]] | Adjust free hand. |
| [[Right Stick Click]] + [[Y]] | Adjust the laser. |
| [[Opposite Grip]] | Grab and move the selected adjustment target. |
| [[A]] | Save adjustment or select a menu item. |
| [[B]] | Restore adjustment defaults; close VR settings. |
| [[Right Stick Up]] / [[Right Stick Down]] | Select a VR setting. |
| [[Right Stick Left]] / [[Right Stick Right]] | Change a VR setting. Changes save immediately. |

## Help

Menus use gamepad-style controller buttons rather than laser pointing. Weapon, hand and laser adjustments are saved per weapon; a weapon without its own setup inherits the last positions. Use the publisher's controls reference for the complete adjustment workflow.

If required files are missing, check the installer log and Windows Protection History before assuming antivirus removal. Keep the game closed while retrying.

## VR files

Blood West.exe remains the game executable; Steam starts it via steam://rungameid/1587130. The VR plugin and OpenXR.dll are under BepInEx\plugins\BloodWestVR in the game folder, with BepInEx\config\bloodwest.vr.cfg for personal settings. The complete BepInEx runtime uses winhttp.dll and BepInEx\core. Verified folder and start links appear after the VR mod installation. If the Hub does not find your game, you can choose [[Locate Game]].

## Discord discussion & support

- [Join Flat2VR](https://discord.gg/uAeQkYBM4n)
- [Blood West VR discussion](https://discord.com/channels/747967102895390741/1562299917735829597)

## Links

- [Official mod and full controls](https://github.com/King-EJ/Blood-West-VR)
- [Publisher package](https://github.com/King-EJ/Blood-West-VR/releases)
- [VR gameplay](https://www.youtube.com/watch?v=tUe3wmanhSQ)

## Uninstall guide

Close Blood West and choose [[Uninstall now]]. The Hub removes its unchanged plugin files and restores earlier files where applicable. It retains the shared BepInEx loader if other plugins are installed. User-edited configuration, saves, logs and unrelated files remain.

Even death could not get you out of this shift.
