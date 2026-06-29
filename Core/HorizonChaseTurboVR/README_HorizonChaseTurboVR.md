# Horizon Chase Turbo VR

The arcade racer with the Top Gear / Out Run vibes brought into VR. Stereoscopic 3D rendering only - controls stay flat, so you play with a gamepad or keyboard like the base game.

**Mod**: HorizonChaseTurboVR v1.0.0 - by Astienth, distributed by Astienth via Discord  
**Game**: Horizon Chase Turbo (Steam App 389140 / also on Epic Games Store)

## About this mod

A community VR mod for the arcade racer, distributed by Astienth via the FarmerTrueVR Discord server. **Discord login is required** to access the download. Ships with OpenVR by default; OpenXR is supported via a config edit.

There are **two separate mod ZIPs** on Discord, one for each store:
- **Steam** version (x86 mod ZIP)
- **Epic Store** version (x64 mod ZIP)

Pick the one that matches your copy of the game. The Hub installer asks which you have and links the right download post.

**No VR controller support** - this mod only renders the game in VR. Use a gamepad or keyboard for control input. There is no ViGEmBus dependency.

If you'd rather not use the in-Hub installer, the manual instructions live in the original mod post in the FarmerTrueVR Discord:
- https://discord.com/channels/1001138422972432597/1362072336827814020/1362072336827814020

## What this Hub installer does

The bundled installer walks you through:
1. Joining the FarmerTrueVR Discord server (skip if already in)
2. Reading and accepting the server rules (AK-47 reaction)
3. Picking your store version (Steam x86 vs Epic Store x64)
4. Downloading the matching mod ZIP from the right Discord post
5. Auto-locating your Horizon Chase Turbo install (Steam libraries scanned, Epic Games default paths + LauncherInstalled.dat manifest checked)
6. Extracting the mod files into the game folder

The installer soft-warns if the ZIP filename doesn't match the store you picked (e.g. you picked Steam but dropped in the `_x64_EpicStore_` ZIP), and lets you continue or pick a different file.

## Controls

Game controls are unchanged. Use a **gamepad** or **keyboard**. There is no motion-controller support and no VR-specific hotkeys; the mod just renders the racing game in VR with stereoscopic 3D.

## Switch to OpenXR (default is OpenVR)

In `BepInEx\config\UnityVR_Bepinex.cfg`, change:

```
vrApi = OpenXR
```

(Default is `OpenVR`. Both runtimes are supported.)

## Known issues

- Some menu UI glitches. The game itself stays fully playable.

## Uninstall / temporarily disable

**Important**: this mod uses a **Doorstop loader**, not the usual `winhttp.dll` proxy that the other Astienth mods use. To disable it, rename or delete `doorstop_config.ini` in the game root folder. The mod stops loading; BepInEx and the plugin DLL can stay on disk.

If you want to fully clean up, also delete the `BepInEx\` folder and the `doorstop_config.ini` file.

## Discord

- Server invite: https://discord.gg/G8zZBTGuhP
- Mod info post: https://discord.com/channels/1001138422972432597/1362072336827814020/1362072336827814020
- Steam version download (x86): https://discord.com/channels/1001138422972432597/1362072336827814020/1362073388008472717
- Epic Store version download (x64): https://discord.com/channels/1001138422972432597/1362072336827814020/1362073443733864508

## Support Astienth

If you want to show some support to Astienth, you can buy them a coffee:
- https://www.buymeacoffee.com/astienth4

>>> Synthwave on the speakers. Horizon on the dash.
