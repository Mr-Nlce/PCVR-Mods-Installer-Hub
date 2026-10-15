# GTFO VR — Installer Notes

**Mod:** GTFO_VR 1.4.0 beta by DSprtn
**Game:** GTFO (Steam AppID 493520, by 10 Chambers)
**Engine:** Unity (IL2CPP, x64)
**Source:** https://github.com/DSprtn/GTFO_VR_Plugin
**Distribution:** flat2VRmods Discord (beta-build channel)

## About the Game

GTFO is a cooperative horror shooter built around coordinated expeditions, stealth, equipment planning and survival under pressure. This mod adds roomscale VR and motion-controller interaction to those expeditions.

## What this installer does

1. Walks you through joining the flat2VRmods Discord, opting into beta access, and downloading `GTFO_VR_Release_1_4_0.zip` from the mod channel.
2. Asks you to drag the downloaded ZIP into the installer window.
3. Auto-locates your `steamapps\common\GTFO` folder.
4. Downloads **BepInEx 6.0.0b670 (IL2CPP x64)** from `builds.bepinex.dev`. The VR mod ZIP does not include the loader, so this step is mandatory.
5. Checks both archives and copies their files together. If copying or verification fails, the installer restores the files it replaced.
6. Records the path and version only after the loader, plugin and bindings are present.

## Discord workflow (4 steps)

The walkthrough opens these in order:

1. **Server invite** — https://discord.gg/uAeQkYBM4n
2. **GTFO join channel** — click "Toggle Visibility" to make the GTFO category visible.
3. **Beta opt-in** — open the pinned message, click the warning icon under it to grant yourself beta-build access.
4. **Mod download post** — grab `GTFO_VR_Release_1_4_0.zip` (the file you'll then drop into the installer).

## First-run requirements

- **SteamVR must already be running** before you launch GTFO.
- In SteamVR, disable **"Present non-VR Applications on Theater screen upon Launch"** under VR Settings → Dashboard. Without this, GTFO will be stuck on the theater wall.
- The main menu shows on your desktop monitor — that's normal. The game switches to VR once you start a rundown.

## Performance tuning

The game is very VRAM-hungry in VR. Before you load a map:

- Lower texture resolution, fog resolution, fog diffusion quality.
- Disable SSAO, bloom, subsurface scattering, depth of field, motion blur, anti-aliasing.
- Consult the publisher's VRPerformanceKit guidance if you need upscaling; the archived beta ZIP does not include its files.
- If you crash mid-map, lower textures further — that's the typical cause.

## Controls

- Full SteamVR input binding support — works on Index, Quest, Vive, WMR.
- Set per-action bindings under **SteamVR → Settings → Controllers → Manage Controller Bindings → GTFO VR**.
- Tracking won't activate until you set an action pose for at least one hand (Tip works well for most users).

In-game features:

- Roomscale, motion-controller aiming, two-handed weapon grip.
- Radial menus for watch mode / weapon select.
- Customised melee (charge-based, with a haptic charge indicator).
- 3D UI for menus, map, terminal (floating keyboard for terminal typing).
- Watch with optional numeric ammo display.
- Optional BHaptics + ProtubeVR haptics support.

All of these are tweakable in-game (Settings → VR Settings) or in the config file:

```
GTFO\BepInEx\config\com.Spartan.GTFO_VR_Plugin.cfg
```

## Deactivating the mod

Rename `winhttp.dll` in the GTFO folder to `winhttp_bak.dll`. GTFO will then launch in flat mode again; this also disables other BepInEx mods using that loader. Rename it back to re-enable them.

Do not delete the whole `BepInEx` folder if another mod uses it. This Hub route does not yet have an ownership-safe **Uninstall now** action; back up your settings and inspect the installed files before removing the VR mod manually.

## Multiplayer

GTFO VR works in multiplayer. **Other players do not need the mod installed** — you can VR-host or VR-join any standard GTFO lobby.

## Support the dev

DSprtn maintains GTFO VR as a side project. If you enjoy the mod:

https://ko-fi.com/gtfovr

## Known issues

- **SteamVR crashes on Oculus v28** — workaround toggle exists in the config (`Oculus Crash workaround`).
- **WMR HMDs** may need `lkg_release` of the WMR Steam runtime (Steam → Windows Mixed Reality → Betas).
- **VRPerfKit upscaling** can crash some HMDs (Pimax, Quest 2). Turn it off first if you're crashing.
- **Dithering + fixed-foveated rendering** flickers. Turn dithering off in-game.
- If you crash, the dev would like the log:
  `%UserProfile%\AppData\LocalLow\10 Chambers Collective\GTFO\player.log` (or `player-prev.log` if you started another game after).

>>> The Warden has new orders. Get to the rendezvous.
