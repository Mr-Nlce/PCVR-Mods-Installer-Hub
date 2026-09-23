# TrackMania Nations Forever in VR

## About the Game

TrackMania Nations Forever is Nadeo's free Stadium racer with 65 tracks, solo medals and online competition. TMFOXR adds native OpenXR stereo and headset tracking while the original keyboard and gamepad driving remain intact.

## What this setup installs

The installer always resolves the current stable release from [TrackManiaForeverOpenXR](https://github.com/jiink/TrackManiaForeverOpenXR). It offers two deliberately separate routes:

- **Direct:** installs `d3d9.dll`, `openxr_loader.dll` and `TMFOXR.defaults.ini` beside `TmForever.exe`. This is the quickest route.
- **TMLoader:** installs Tomashu's current TMLoader when needed and uses the dedicated `TMFOXR-...-for-TMLoader.zip` asset. TMLoader provides one-click enable/disable and its required CoreMod dependency makes TrackMania's pre-baked shadow computation much faster.

TMLoader is unsigned, must be installed outside the game folder and requests administrator permission for its game integration. The loader resolves the declared CoreMod dependency itself. The Hub never substitutes the direct ZIP for the TMLoader ZIP or vice versa.

### If TMLoader does not find the game immediately

This first-run sequence is not required on every PC, but it resolves the common detection loop:

1. Launch TrackMania through Steam once. If Steam starts a game update, close TrackMania, let the update finish and launch it again.
2. If the browser warns about the unsigned TMLoader download, keep it only when it came from the official TMLoader page opened by this setup.
3. Approve the installer's Windows permission request, finish the TMLoader update and launch TrackMania through Steam again.
4. Switch back to the Windows desktop. TMLoader may be waiting there with a confirmation dialog before it can register the game.
5. TMLoader also has an **Offline Play** button below the account fields; an online account is not required for that route.

## Required settings

Before playing, open the TrackMania launcher or Steam's **Settings** launch option, turn **Fullscreen off**, set **Advanced > Antialiasing** to **None**, save, and ensure the complete game window fits inside the monitor's usable area. Incompatible display settings make current TMFOXR builds remain on the desktop instead of initializing VR.

Set the active OpenXR runtime as well: Virtual Desktop users should select **VDXR**; SteamVR users should make SteamVR the OpenXR runtime. TMFOXR v8 currently crashes with Meta Horizon Link, so use Steam Link or Virtual Desktop instead. Other 32-bit OpenXR API layers can conflict with the mod.

## First race and shadows

TrackMania may spend a very long time computing pre-baked shadows. With the Direct route, let it work for a couple of seconds and then cancel if it stalls; do not cancel instantly. TMLoader with CoreMod substantially improves this stage.

TMFOXR v8 also adds a world-scaling slider and an option that controls whether VR recenters when your head moves too far from the car.

## Controls

TrackMania Nations Forever can accept gamepad input in its menus while leaving the driving axes unbound. When using Virtual Desktop, enable **Gamepad Mode before starting the game**, then open **Main menu > Profile > Inputs** and use these recommended bindings:

| Button | Action |
|---|---|
| [[Left Stick Up]] | Acceleration (analog) → Y Axis (Pad 1) |
| [[Left Stick Left]] | Steering (analog) → X Axis (Pad 1) |
| [[A]] | Camera 1 |
| [[B]] | Camera 2 |
| [[Right Stick Click]] | Camera 3 — first-person view |
| [[3]] | Switch to the first-person camera during a race |
| [[F10]] | Open TMFOXR settings in VR |

The three camera buttons are a recommended layout and can be reassigned. The car can still be driven with the game's normal keyboard controls instead.

## Updates, switching and removal

Run the installer again to update the route you choose. Direct and TMLoader installations have independent file evidence, and each update receives the matching publisher asset. Use **Uninstall now** to remove Hub-owned TMFOXR files. If both routes exist, the uninstaller asks which one to remove. Removing the shared TMLoader product affects both Forever games but keeps TMLoader, CoreMod, both games, profiles and generated settings.

Project, usage guide and issues: [TrackManiaForeverOpenXR](https://github.com/jiink/TrackManiaForeverOpenXR#usage). Gameplay video: [TrackMania Nations Forever in VR](https://www.youtube.com/watch?v=W-HBLOO175s).
