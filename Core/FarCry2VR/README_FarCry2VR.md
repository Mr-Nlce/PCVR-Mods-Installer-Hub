# Far Cry 2 VR

## About the Game

Far Cry 2 puts you in a war-torn open world where weapons wear down, fire spreads, and every journey can turn into a fight. Braxus's mod renders both eyes natively in the Dunia engine and adds OpenXR head tracking, motion-controlled weapons, body holsters, hand-held map and GPS, and optional climbing. The publisher describes version 1.0.2 as mod build v231.

## What you need

- The **Steam or GOG** Windows edition of Far Cry 2 and an active OpenXR runtime. The publisher does not currently confirm Ubisoft Connect or DVD builds; the Hub does not install this release into those copies.
- **DirectX 10 mode is required.** In Steam choose the DirectX 10 launch option. In the game's video options, select DirectX 10 and restart. If the choice is unavailable, close the game and set `Platform="d3d10a"` in `Documents\My Games\Far Cry 2\GamerProfile.xml`. DirectX 9 can leave the game visible only on the monitor.
- [Far Cry 2 VR releases](https://github.com/Braxusx/FarCry2VR/releases). The Hub downloads the current publisher launcher or a complete older ZIP, reads its embedded runtime without running its installer, preserves an existing `fc2vr.ini`, and checks the installed files.

Unsigned VR files may cause antivirus warnings. Missing files can also mean a copy, permission or path error; check the installer log and security history before assigning a cause.

## Install, update and start

1. Choose [[Install]] or [[Update]] on the tile. After locating the game, the Hub explains the required DirectX 10 setting and waits for Enter before starting the normal flat game. In **Main Menu > Options > Display**, set **DirectX version 10**, save, close the game, and press Enter to continue. If Steam offers a launch choice, choose DirectX 10. The VR files are installed only after the flat game is closed.
2. The mod files belong in the game's `bin` folder next to `FarCry2.exe`. The publisher launcher, `FarCry2VR-Launcher.exe`, is in the Far Cry 2 game folder. An installed copy makes this path clickable on the detail page. If the Hub misses the base game, use [[Locate Game]] and select the original Steam or GOG game folder.
3. **Use [[Start in VR]] in the Hub.** It opens the publisher launcher, where you choose **Play**. Alternatively, use the **Far Cry 2 VR** desktop shortcut to that same launcher. Connect your headset and OpenXR runtime first.

The publisher launcher offers settings, controller bindings, installation checks and a 16-core launch limit for the Dunia engine. NVIDIA DLSS requires an RTX GPU; the mod can run without DLSS. Use the Hub installer for later mod updates so its ownership and version records stay consistent.

If the launcher reports **FarCryVR.exe missing**, select **Reinstall/Repair** once in that launcher. Its **Optional** tab contains extra VR features you can enable to taste.

## Controls

Version 1.0.2 adds **Room-scale walking** and **Walking direction** under **Settings > Controls > Movement**. Far Cry 2 is a 32-bit game: if it stays on the monitor, use **Overview > VR runtime** in the launcher and choose a compatible 32-bit runtime for this game. VDXR and SteamVR 2.17 or newer are documented choices; Pimax users can use SteamVR.

For a 64-65 FPS cap, set in-game **Anti-aliasing: None** (MSAA disables DLSS), check external frame limiters, and use **Collect logs** if it persists. The current runtime keeps its DLSS helper and NVIDIA DLL in `bin\fc2vr_dlss`; complete older installs used `bin` directly.

| Button | Action |
| --- | --- |
| [[Left Stick]] | Move; click to sprint; hold the click for one second to recenter. |
| [[Right Stick]] | Turn; pull down to crouch; click to heal. |
| [[Right Trigger]] | Fire; swing the machete physically instead. |
| [[Left Trigger]] | Reload or clear a jam; throw while holding [[Right Grip]]. |
| [[A]] | Jump; with [[Left Grip]], re-take the weapon's hold. |
| [[B]] | Tap for the next weapon; hold for grenade or molotov. |
| [[X]] | Use doors, turrets, items and vehicles. |
| [[Y]] | Open the map and GPS. |
| [[Left Grip]] | Two-handed weapon hold, grab and climb. |
| [[Right Grip]] | Draw from a body holster, aim through sights or use the monocular with the map open. |
| [[Menu]] | Pause. |
| [[F8]] | Recenter with the keyboard. |

## Discord discussion & support

- [Flat2VR Modding invite](https://discord.gg/flat2vr)
- [Far Cry 2 VR discussion](https://discord.com/channels/747967102895390741/1562896372573933698)

## Links

- [Publisher project and full guide](https://github.com/Braxusx/FarCry2VR)
- [Flat gameplay video](https://youtu.be/A6KRiAZvj8I?t=7)

>>> The Jackal has not planned for you to arrive in person.
