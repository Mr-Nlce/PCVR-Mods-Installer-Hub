# XIII Remake VR

**VR mod:** [XIII VR by CastleTroy28](https://github.com/CastleTroy28/XIII-VR)  
**Release:** [Publisher releases](https://github.com/CastleTroy28/XIII-VR/releases)  
**Gameplay:** [Watch XIII in VR](https://www.youtube.com/watch?v=cYY1gAdiMKk)

## About the Game

This entry is for the **2020 XIII Remake**, not the original XIII Classic. It is a comic-book first-person shooter. The VR mod adds tracked hands, physical interactions, manual weapon handling, room movement and OpenXR support. It is still in active development.

## Requirements and installation

Use the 64-bit Windows remake with Unity **2020.3.25**. The publisher tested Steam. The Hub can locate Epic, GOG and Xbox folders, but those builds have not been publisher-tested; the installer checks the required Unity build before changing files. Start your headset's OpenXR runtime first. The first game launch after setup can take several minutes while BepInEx prepares its files.

The Hub downloads the publisher's complete release ZIP and runs `Install-XIII-VR.ps1`. Before a first installation, the Hub tries the [direct BepInEx be.788 Windows IL2CPP x64 ZIP](https://builds.bepinex.dev/projects/bepinex_be/788/BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.788%2B5b766a3.zip) automatically. If that address fails, the Hub offers the [official BepInEx build index](https://builds.bepinex.dev/projects/bepinex_be): choose build **#788**, then the **Unity IL2CPP Windows x64** ZIP, and hand it to the Hub. The publisher backs up replaced files in `XIII-VR-backups` and keeps your settings. A publisher ZIP named `0.1.256` currently contains a script that reports `0.1.257`; the Hub records the published release version for update checks.

## Starting and settings

Select **Start in VR** on the Hub tile to run the installed `XIII.exe`. Use **VR settings** and **VR CONTROLS** in the game's pause menu. World scale, movement mode, snap or smooth turning, weapon inertia, cutscene camera, forearm display, aim dot and holster positions can be adjusted there. The configuration file is `BepInEx\config\xiii.vr.xrbootstrap.cfg`.

## Controls

These are the publisher's right-handed defaults. Left-handed mode mirrors them. The in-game **VR CONTROLS** page shows the active mappings.

| Button | Action |
| --- | --- |
| [[Left Stick]] | Move; climb a rope or swim. |
| [[Right Stick]] | Turn; push up to jump, down to crouch or dive. |
| [[Left Grip]] / [[Right Grip]] | Pick up, hold, holster, climb or throw by releasing the grip. |
| [[Trigger]] | Fire the held weapon, use a medkit or drag a body with an empty hand. |
| [[Right B]] | Reload; open a machine-gun cover when manual reloading is enabled. |
| [[Left Y]] | Next weapon. |
| [[Right A]] | Hold for the weapon and item wheel; choose with [[Left Stick]]. |
| [[Right Stick Click]] | Take out a key, keycard or lockpick. |
| [[Left Grip]] + [[Left X]] | Pause menu. |
| [[Left X]] | Tasks. |
| [[Right Trigger]] | Skip or fast-forward a cutscene. |
| [[F3]] | Toggle the performance overlay. |
| [[F6]] / [[F12]] | Take a screenshot. |

## Troubleshooting and removal

If VR does not load, check `BepInEx\LogOutput.log` for `Loading [XIII XR Bootstrap ...]`. The publisher's `Collect-XIII-Logs.cmd` in the game folder collects useful logs for a [bug report](https://github.com/CastleTroy28/XIII-VR/issues). The first launch can be slower than later launches. Close XIII before installing, updating or removing the mod.

**Uninstall now** runs the publisher restore script against its installed journal and returns backed-up originals. It keeps the game and user data. If a file has changed since setup, the publisher may retain it for review.

## Support the developer

If you enjoy the mod, [support CastleTroy28 on Ko-fi](https://ko-fi.com/castletroy).

>>> Follow the clues. Trust your hands.
