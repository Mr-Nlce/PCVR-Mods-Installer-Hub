# Forza Horizon 5 VR

The lufz **VRMod** brings Forza Horizon 5 to the headset with OpenXR
per-eye rendering and experimental 6DoF head tracking. You own the game
(Steam / Microsoft Store / Game Pass); the free community mod is
downloaded automatically from the author's GitHub releases and the
installer sets it up under `C:\Games\Forza Horizon 5 VR` (deliberately
**outside** the game folder). The same VRMod launcher also supports Forza Horizon 6 - if you
install both, one launcher install per game folder is still required.

## Requirements

- An owned copy of **Forza Horizon 5** (Steam app 1551360, Microsoft
  Store, or PC Game Pass)
- A PC VR headset with a working OpenXR runtime (SteamVR or the
  headset's own runtime)
- **Do not** place the mod inside Forza Horizon 5's own install folder -
  the installer keeps it in `C:\Games\Forza Horizon 5 VR`.

## The VRMod launcher, at a glance

The launcher window has three columns:

1. **Games** (left) - your library. Use **+ Add Game** and pick the
   game's install **folder** - on Game Pass that is
   `C:\XboxGames\Forza Horizon 5\Content`, because Windows blocks
   opening `ForzaHorizon5.exe` there. On Steam you can also use
   **+ Add .exe**, or start the game first and click
   **Auto-detect Running**. Select the game's row, then click
   **Install VR Mod** (needed once per game install folder). The
   **Check My Setup** panel below flags conflicts (e.g. a missing
   proxy) with a **Re-check** button.
2. **Play in VR** (middle) - pick your headset (Auto / OpenXR works for
   most), then click **Play in VR**: it launches the game, or enables
   the headset if the game is already running (best from the main menu,
   the garage, or while driving). **Exit VR** returns to flat.
   The Options block below controls Stereo Strength, Game FOV, Render
   Scale, upscale quality and picture look.
3. **Tracking & Advanced** (right) - the experimental 6DoF block:
   head-look sensitivity, smoothing, lean amount/direction and seat
   position. **Re-acquire camera (re-hook)** fixes a warped or stuck
   view after a teleport.

## How to play

1. Start with **Start in VR** in the Hub, or the **Forza Horizon 5 VR** desktop shortcut (or run
   `vrmod-launcher.exe` from the install folder).
2. Add/select Forza Horizon 5 and click **Install VR Mod** (first run
   only).
3. Start SteamVR (or your OpenXR runtime), then click **Play in VR**.

## Controls

Driving uses a **gamepad or wheel**, exactly like flat Forza:

- [[LT]] Brake / reverse
- [[RT]] Accelerate
- [[Left Stick]] Steering
- [[A]] Handbrake (default layout)
- Head movement looks around the cockpit (6DoF is experimental - tune
  it in the Tracking & Advanced column)

## Tips & known quirks

- For OpenXR 6DoF, turn **HDR OFF** and set the in-game FOV slider to
  **maximum**.
- **Leave Frame Generation off.** The mod author asks for that with this
  version. The launcher's toggle stays there, but it is not the setting to
  experiment with right now.
- This version clears out a few old config values that could cause trouble.
  Only those are reset - the rest of your tuning stays as you set it.
- Lower in-game graphics, V-Sync OFF, frame rate unlimited, motion
  blur / DLSS / frame generation OFF is the smoothest starting point.
- A Forza Horizon 5 game update can break the mod until the author
  ships an update - re-run the installer, which always fetches the
  newest build. Do not contact the official Forza team about a broken
  mod.
- The launcher shows **"No supported games running"** until Forza is
  started or added to the library - that line is normal at first run.
