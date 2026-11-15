# Agent 64: Spies Never Die VR

## About the Game

A retro spy shooter inspired by 1990s console classics. Complete objectives, steal plans and fight through guarded locations as secret agent John Walter.

## What you need

- The installed Windows game, an active OpenXR runtime and motion controllers.
- This test-build mod was tested by King-EJ on game v1004 with Quest 3. Later game versions and multiplayer are not confirmed.
- Use solo/offline mode without Easy Anti-Cheat. For the Steam edition, the Hub selects Offline mode without EAC through Steam.

## Install and start

1. Close the game and choose [[Install]] or [[Update]] in the Hub. Check the displayed game folder; Locate Game also accepts the game EXE or its folder.
2. Read the installer instructions and press [[Enter]]. Setup downloads the current official publisher ZIP, including its BepInEx IL2CPP loader, .NET runtime and OpenXR bridge. Existing settings, saves and other plugins remain.
3. Start your OpenXR runtime and use [[Start in VR]] in the Hub. First launch can take longer while BepInEx prepares the game.
4. Alternative: launch through Steam and select Offline mode without EAC.

If the automatic download fails, download the ZIP from the official release page and drag it onto the installer recovery window. Its included configuration identifies the installed VR version; no filename or historical size is required.

## Controls

Right-handed default. Keyboard and mouse still work.

| Button | Action |
| --- | --- |
| [[Left Stick]] | Walk; navigate menus. |
| [[Right Stick Left]] / [[Right Stick Right]] | Snap turn; smooth turn when SnapTurn is disabled. |
| [[Right Stick Up]] / [[Right Stick Down]] | Next / previous weapon; scroll menus. |
| [[Right Trigger]] | Fire; point the right hand at a menu and click. |
| [[Left Trigger]] | Secondary aim / zoom; publisher marks this untested. |
| [[A]] | Interact, use, open or confirm. |
| [[B]] | Reload; cancel or go back in menus. |
| [[Y]] | Pause / menu. |
| [[X]] | Score / objectives. |
| [[Right Grip]] | Hold for glaive / laser action. |
| [[Left Grip]] | Next gadget. |
| [[Left Stick Click]] | Tap to hide / show the floating screen during play. |
| [[Left Stick Click]] + [[Right Stick Click]] | Recenter. |

## Settings and help

Settings are in BepInEx/config/agent64.vr.cfg and can update live. GameAim selects hand, head or off; MovementDirection selects head, offhand or game direction. The mod supports left-handed mode, snap/smooth turning, world scale and eye-height adjustments.

Known publisher issue: bullet tracers can appear above an enemy even when hits register; the laser follows the aiming direction. Check BepInEx/LogOutput.log for loader/plugin errors when reporting a problem. Headset, aiming and performance depend on the installed game version and runtime.

## Remove or restore

Use [[Uninstall now]] on the Hub game page with the game closed. Unchanged Hub-owned VR files are removed and replaced originals restored. The shared loader is kept when other plugins need it. Saves, changed settings and unrelated files remain. For a failed installation, Retry remains available and the previous file set is restored.

## Links

[Official releases](https://github.com/King-EJ/Agent-64-Spies-Never-Die-VR-Mod/releases) · [Publisher documentation](https://github.com/King-EJ/Agent-64-Spies-Never-Die-VR-Mod) · [Flat2VR invite](https://discord.gg/flat2vr) · [Mod discussion](https://discord.com/channels/747967102895390741/1553985703858143332) · [VR gameplay](https://youtu.be/-ldkQB-IThQ?t=12)

For England? No, for stereoscopic depth.
