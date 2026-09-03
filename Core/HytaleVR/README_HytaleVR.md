# Hytale VR (HytaleVRInjector-mod)

Hytale in PCVR through **HytaleVRInjector-mod** by **heurazy** - a Windows x64 VR injector/dashboard. It renders the game to your headset through SteamVR with native motion-controlled hands, driven by an external camera dashboard.

**Version 1.0** - the AFW prototype has grown into a fuller, more comfortable VR experience. It is not affiliated with or endorsed by Hytale, Hypixel Studios, Valve, OpenVR, or MinHook.

## New in v1.0.4

- **SteamVR depth submission**, on by default. If your runtime turns it down, the mod falls
  back to colour-only by itself - nothing to configure.
- **Fixed SteamVR waiting with no image** when supersampling was switched off.
- Handles **full, half and quarter resolution** Hytale depth buffers.
- The AFW colour path is kept clear of the depth conversion, so normal rendering stays
  stable.

The author reports all three automated test suites passing, and the Windows x64 archive
verified through both PowerShell and Explorer extraction (77 of 77 files).

## What you need

| Requirement | Notes |
|---|---|
| **Hytale** | Your own copy, installed through the official Hytale Launcher (hytale.com). Nothing from the game is downloaded by this installer. |
| **SteamVR** | The injector talks to SteamVR - start it before playing. |
| **Windows x64** | The mod ships Windows x64 binaries only. |

## What the installer does

1. Downloads the newest `HytaleVRInjector-mod-*-windows-x64.zip` from the official GitHub releases (resolved live via the GitHub API, with a last-known-good fallback if the API is unreachable).
2. Unpacks it to `C:\Games\Hytale VR` (or a folder you pick). Installing under `C:\Games` is recommended - it avoids UAC / Program Files permission weirdness.
3. Sets up a combo launch that starts the **Hytale Launcher** and the **camera dashboard** together.
4. Creates a **Hytale VR** desktop shortcut - everything needed for a headset session is one double-click away. That shortcut (or **Start in VR** in the Hub) is how you start the game.

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

## New in 1.0

**VR hands and held items** - the mod detects the item Hytale renders
in either hand and rebuilds tools, weapons, blocks, decorations,
shields and torches from Hytale's own models and textures, anchored
to your tracked controllers. Items stay stable during attacks and
block placement, keep the correct hand assignment, and position and
scale are configurable.

**Sharper AFW rendering** - optional source supersampling with an
adjustable resolution percentage, optional sharpening after AFW
reconstruction, and a VR FXAA pass against jagged edges and foliage
shimmer. Supersampling and sharpening are OFF by default to preserve
performance.

**Anchored interface** - Hytale's interface is captured as a SteamVR
Standing-space overlay, so menus stay anchored in the world instead
of following your head. Center VR recenters both the camera and the
menu anchor.

**Built-in auto-updates** - the dashboard itself checks stable GitHub
releases at startup. Updates are always opt-in, and downloads are
checked for size, unsafe ZIP paths and SHA-256 integrity before a
helper swaps the files and restarts the dashboard. Day-to-day updates
can happen right in the dashboard; the Hub's Update tile and this
installer keep working as before.

## Important notes (from the 1.0 release)

- SteamVR must be running before starting VR
- Disable Hytale's built-in FXAA and use the dashboard's VR FXAA
  option instead
- Keep Hytale focused for controller inputs
- Supersampling costs GPU performance; start around 125% and adjust
  for your headset and GPU
- Restart Hytale before replacing a hook DLL that is already
  injected (i.e. close the game before running an update)

## Controls

![Controls](Hytale_controls.jpg)

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

## Credits & support

- **heurazy** - HytaleVRInjector-mod: <https://github.com/heurazy/HytaleVRInjector-mod>
- Problems with the mod? Contact `heurazy` on Discord.
