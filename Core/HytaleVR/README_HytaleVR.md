# Hytale VR (HytaleVRInjector-mod)

Hytale in PCVR through **HytaleVRInjector-mod** by **heurazy** - an experimental Windows x64 VR injector/dashboard. It renders the game to your headset through SteamVR with native motion-controlled hands, driven by an external camera dashboard.

**Status: experimental / WIP.** The mod works but is early and rough around the edges. It is not affiliated with or endorsed by Hytale, Hypixel Studios, Valve, OpenVR, or MinHook.

## What you need

| Requirement | Notes |
|---|---|
| **Hytale** | Your own copy, installed through the official Hytale Launcher (hytale.com). Nothing from the game is downloaded by this installer. |
| **SteamVR** | The injector talks to SteamVR - start it before playing. |
| **Windows x64** | The mod ships Windows x64 binaries only. |

## What the installer does

1. Downloads the newest `HytaleVRInjector-mod-*-windows-x64.zip` from the official GitHub releases (resolved live via the GitHub API, with a last-known-good fallback if the API is unreachable).
2. Unpacks it to `C:\Games\Hytale VR` (or a folder you pick). Installing under `C:\Games` is recommended - it avoids UAC / Program Files permission weirdness.
3. Writes `Start Hytale VR.bat` - a combo launcher that starts the **Hytale Launcher** and the **camera dashboard** together.
4. Creates a **Hytale VR** desktop shortcut pointing at that combo launcher, so everything needed for a headset session is one double-click away.

Re-running the installer offers **Update** (re-download the latest build and replace the mod files) or a full reinstall. The Hub also flags updates on the game tile automatically once a newer release is published.

## One-time game setting

On the first launch of Hytale, open **Video settings** and set **Anti-aliasing: FXAA** to **Off**. The injector needs it disabled.

## Every session (takes ~10 seconds)

1. Start **SteamVR** and make sure your headset is connected.
2. Launch via the **Hytale VR** desktop shortcut - it starts the Hytale Launcher and `hytale_camera_dashboard.exe` together.
3. Enter a world or join a server.
4. Press **F7** in-game to show the player coordinate block.
5. In the dashboard, click **Scan player block** (takes about 5 seconds).
6. Select the detected coordinate block from the list.
7. Click **Center VR** to inject and align the headset view.

Keep SteamVR running while using the mod. Hytale must stay focused for the mod controls to work correctly.

## Controls

![Controls](../Assets/Hytale_controls.jpg)

Left controller:

- [[Stick]] Move player
- [[Stick Click]] Sprint
- [[X]] Interact (F)
- [[Y]] Open inventory
- [[Trigger]] Cycle hotbar left

Right controller:

- [[Stick]] Rotate view
- [[Stick Click]] Waypoint / sneak
- [[A]] Jump / gain altitude while flying
- [[B]] Ultimate ability
- [[Trigger]] Cycle hotbar right

## Troubleshooting

- **Black or frozen headset view:** re-run the dashboard steps - F7 in-game, Scan player block, Center VR. The view is centered per session.
- **Blurry or shimmering image:** confirm FXAA is Off in Hytale's Video settings.
- **Controls stop responding:** click the Hytale window - it must stay the focused window.
- **Hytale not found by the shortcut:** the combo launcher looks for the Hytale Launcher at `%LOCALAPPDATA%\Programs\Hypixel Studios\Hytale Launcher\hytale-launcher.exe`. If you installed it elsewhere, start the launcher yourself, then run `hytale_camera_dashboard.exe` from the mod folder.
- **Debug logs:** set `HYTALEVR_DEBUG_LOGS = "1"` in your environment; logs land under `%TEMP%\HytaleVR`.

## Uninstall

Delete the `Hytale VR` folder (default `C:\Games\Hytale VR`) and the desktop shortcut. The game itself is untouched - it lives in the Hytale Launcher's own location.

## Credits & support

- **heurazy** - HytaleVRInjector-mod: <https://github.com/heurazy/HytaleVRInjector-mod>
- Problems with the mod? Contact `heurazy` on Discord.
