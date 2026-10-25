# Rustler VR

## About the Game

Rustler is a medieval open-world action game with absurd missions, horse riding and top-down combat. King-EJ's test build adds stereo OpenXR rendering, first- and third-person VR, tracked arms and hands, weapon aiming, and a hand-mounted HUD. The archive includes the BepInEx 5 loader and the Rustler VR plugin.

## What you need

- Rustler for Windows from Steam, Epic Games or GOG. The Hub looks for `Rustler.exe` and `UnityPlayer.dll` in the same game folder.
- A working headset and SteamVR, Quest Link or Virtual Desktop selected as the OpenXR runtime before launching the game.
- The complete `RustlerVR.zip` from the [publisher's release](https://github.com/King-EJ/Rustler-VR/releases/tag/Rustler_VR). The Hub downloads the current asset automatically and reads its plugin version from the package. If GitHub is unavailable, the guided recovery can use the same ZIP from Downloads.

## Install and start

1. Choose [[Install]] on the Rustler tile. The Hub downloads the publisher ZIP; if that fails, it opens the release page after Enter and checks Downloads after you return. Existing files with the same names are backed up. Your own BepInEx and Rustler configuration is retained on update.
2. Start your OpenXR runtime and connect the headset.
3. Choose [[Start in VR]] in the Hub. For the Steam edition, the Hub uses Steam to start the game. Epic and GOG installations launch their selected `Rustler.exe`.

If Steam asks whether to start the game, choose Play. If music plays in a brown empty view, press [[Esc]]. For low performance, lower **Picture > View distance** in the VR settings; the publisher notes that 100 m costs less than 175–250 m.

## Controls

The VR controllers emulate the game's gamepad layout. These are the publisher's default actions; you can change them in `BepInEx\config\rustler.vr.cfg`.

| Button | Action |
|---|---|
| [[Left Stick]] | Walk or ride in the direction you look. |
| [[Right Stick Left]] / [[Right Stick Right]] | Snap turn. |
| [[Right Trigger]] | Attack or fire. |
| [[Right Grip]] | Aim, show the laser or block. |
| [[Left Grip]] | Sprint. |
| [[Left Trigger]] | Back the horse up. |
| [[A]] | Roll or confirm. |
| [[B]] | Go back in menus. |
| [[Y]] | Mount. |
| [[X]] | Tap for the game X action; hold to show the map. |
| [[X]] + [[Y]] | Pause. |
| [[Right Grip]] + [[Right Stick Click]] | Switch first- and third-person view. |
| [[Left Stick Click]] + [[Right Stick Click]] | Recenter. |
| [[Y]] + [[Left Stick Click]] | Hold for 1.7 seconds to open the VR settings menu. |

## Removal and troubleshooting

Choose [[Uninstall now]] to remove only unchanged Hub-owned files and restore earlier files with the same names. Saves, the original game and unrelated mods remain. Files you changed after installation are preserved for review.

If the headset remains black, the publisher suggests the game launch option `-force-d3d11`. Check the OpenXR runtime first. For a mod problem, inspect `BepInEx\LogOutput.log`, including its Rustler VR diagnostics. A missing file alone is not proof of antivirus quarantine; inspect the installer log and protection history before changing security settings.

## Links

- [Publisher project and instructions](https://github.com/King-EJ/Rustler-VR)
- [Publisher release and ZIP](https://github.com/King-EJ/Rustler-VR/releases/tag/Rustler_VR)
- [Flat2VR community thread](https://discord.com/channels/747967102895390741/1560758573598908628)
- [VR gameplay](https://www.youtube.com/watch?v=ydHB8gqxOds)
