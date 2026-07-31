# Forza Horizon 6 VR

Two community VR mods bring Forza Horizon 6 to the headset. You own the
game (Steam / Microsoft Store / Game Pass); the Hub installer lets you
pick a mod, opens its download, and you drag the downloaded `.zip` onto
the installer window - it extracts the mod into its **own subfolder**
under `C:\Games\Forza Horizon 6 VR` (deliberately **outside** the game
folder) and makes a desktop shortcut.

You can install **both** mods side by side to compare them - each lives
in its own subfolder (`\NALULUNA` and `\lufz`) so they never overwrite
each other. Re-run the installer and pick the other mod to switch which
one is the active "Start in VR" target.

There is no single "best" mod - opinions differ, so both are offered.

## The two mods

- **NALULUNA** **(recommended)** - free on ko-fi (set the amount to 0). The newest build is
  always on the page, named like `fh6vr_<version>.zip`. Launcher:
  `fh6vr.exe`.
- **lufz / VRMod** - shared in the **flat2VR Modding Discord**. Join via the
  invite (also in the Hub's Help & Feedback button), open the download
  post, grab `VRMod-v1_2_1.zip` (newest version). Launcher: `vrmod-launcher.exe`.

## Requirements

- An owned copy of **Forza Horizon 6** (Steam app 2483190, Microsoft
  Store, or Game Pass).
- A PC VR headset with an OpenXR / SteamVR runtime.
- **Do not** place the mod inside Forza Horizon 6's own install folder -
  the installer keeps it in `C:\Games\Forza Horizon 6 VR`.

## Playing - NALULUNA

1. Start from the desktop shortcut (or run `fh6vr.exe`) and press the
   **[[Launch]]** button to start Forza Horizon 6.
2. Once you are in a car, press **[[Tab]]** a few times to switch to
   cockpit view - that view is shown in the headset.
3. **[[Ctrl]] + [[Space]]** recenters the headset.

Settings: lower graphics, **V-Sync OFF**, frame rate unlimited, and turn
motion blur / DLSS / frame generation **off**. DIBR mode runs smoothest;
AFR looks cleaner but halves the frame rate.

**Can't see the in-car UI** (map, speedometer, etc.)? In **Settings > HUD & Gameplay**, set **HUD Safe Frame Vertical** to **25** (all the way right).

## Playing - lufz / VRMod

1. Start from the desktop shortcut (or run `vrmod-launcher.exe`).
2. **Browse** to your `ForzaHorizon6.exe` (or use **Auto-detect Running**),
   then click **[[Install VR Mod]]**.
3. Start SteamVR, start the game, then click **[[Play in VR]]** once you
   reach the main menu, garage, or are driving.

Settings: for **OpenXR 6DoF** turn HDR off and set in-game FOV to maximum;
**SimVR** allows frame generation. On NVIDIA you can try the experimental
**Frame Generation** toggle. Head tracking stuck? Press **[[F8]]** to
toggle it off and on again.

## Controls

- **Gamepad** is the expected scheme for both mods (wheel works too).
- Recenter (NALULUNA): **[[Ctrl]] + [[Space]]**.

## Notes & safety

- Both mods interfere with the running game (memory/camera/render hooks),
  so there is no guarantee against anti-cheat action. Use at your own risk.
- A Forza Horizon 6 game update can break a mod until the author ships an
  update - re-download the newest build when that happens. Do **not**
  contact the official Forza team about a broken mod.

## Support & credits

- **NALULUNA** - https://ko-fi.com/naluluna/shop
- **lufz / VRMod** - Lufz (https://x.com/djlufz); JP translation by Monkin.
- Forza Horizon 6 by Playground Games / Turn 10.

>>> Chase the horizon, feel every gear change, and let the festival roar.
