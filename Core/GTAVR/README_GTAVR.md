# Grand Theft Auto V VR

Layers Luke Ross's **R.E.A.L. r7** VR mod (plus an optional **GTAVR
motion-controls overlay**) onto an existing, working copy of **Grand
Theft Auto V (Legacy)** that **you provide**. No game files are bundled
or downloaded - the free Luke Ross mod is fetched from his public GitHub
release, and the optional motion overlay is downloaded by you from its
official page and dragged into the installer.

## Important - read first

- You need an **already-installed, launchable GTA V (Legacy)** on build
  **1.0.2245.0**. The current/latest game build does **not** work with
  the mod.
- This is **not** GTA V Enhanced (the 2025 release, a separate game) -
  that one is incompatible with R.E.A.L. r7.
- A pinned Steam **depot** build of 1.0.2245.0 is conceivable, but the
  Rockstar launcher would most likely have to be bypassed, and no
  reliable tool for that exists right now. If you find a working method,
  please share it via the Hub's **Help & Feedback** button.

## Requirements

- A working, owned **GTA V (Legacy)** on build **1.0.2245.0**.
- **7-Zip** (https://www.7-zip.org) - the mod ships as a `.rar`.
- **SteamVR** (or a compatible OpenVR runtime) running before launch.
- A **gamepad** - R.E.A.L. is designed around it.

## What the installer does

1. You drag your **GTA V folder** (or `GTA5.exe` / `PlayGTAV.exe`) onto
   the window.
2. It checks the `GTA5.exe` build and warns if it is not 1.0.2245.0
   (it never blocks - your copy, your call).
3. Downloads `GTAV_REAL_mod_by_LukeRoss_r7.rar` from Luke Ross's GitHub.
4. Extracts it into your GTA V folder via 7-Zip (manual fallback if
   7-Zip is missing).
5. Sets `VRAPI=2` in `RealVR.ini` (SteamVR / OpenVR) and optionally opens
   `RealConfig.bat` so you can pick a graphics template.
6. **Optional:** opens the GTAVR motion-controls download page; you
   download the overlay and drag it in, and the installer copies
   `GTAVR.asi` + `openvr_api.dll` into the game folder. Skip it for
   gamepad-only play.
7. Creates a **Grand Theft Auto V VR** desktop shortcut.

## Before you install (do this first)

Boot GTA V normally on your monitor, set these, then exit the game. The
mod relies on them:

- **Gamepad > Targeting Mode:** Free Aim
- **Camera > First Person Head Bobbing:** Off
- **Camera > First Person Third Person Cover:** On
- **Camera > First Person Vehicle Hood:** Off

Also set your **Windows default audio device to the VR headset**, or you
will have no in-game sound.

## Playing & controls

1. Start **SteamVR**, put on the headset, then launch the game.
2. **Aiming is head-driven (gaze aiming).** Use a **gamepad** (Xbox pad
   recommended) or **keyboard & mouse**. Oculus Touch / tracked
   controllers are **not** supported by R.E.A.L. itself - that is what the
   optional GTAVR overlay adds.
3. **Recenter view / HUD:** briefly shake your head side to side, as if
   saying "no". Works anywhere (missions, menus, driving).
4. **In a vehicle**, to realign with the car without moving the HUD, tap
   **look behind** ( [[C]] on keyboard, or press in the right stick
   [[R3]] ).

## Hotkeys

The R.E.A.L. hotkeys are **disabled at startup**. Press **[[F11]]** once
to turn them on (it is an on/off toggle, like Caps Lock - not a key you
hold). Press [[F11]] again to turn them back off. Changed options last
until you quit; defaults can be preset by editing `RealVR.ini`.

- **[[F11]]** - enable / disable hotkeys (off at start)
- **[[Num /]]** - recenter the headset
- **[[Num 0]]** - position tracking on/off
- **[[Num 2]]** - stereo (alternate-eye) rendering on/off
- **[[Num .]]** - zoom override (never / cutscenes / except cutscenes / always)
- **[[Num 3]]** - darts/tennis FOV override on/off
- **[[T]]** - dominant eye for aiming down sights (none / left / right)
- **[[Y]]** - heading control (always / only when aiming / never)
- **[[U]]** - pitch control on/off
- **[[I]]** - decoupled 3rd-person camera on/off
- **[[O]]** - view-matrix fix on/off
- **[[0]]** - cutscene stereo mode (normal / dynamic / flat screen)
- **[[J]]** - cutscene pitch mode (absolute / relative / cut relative)
- **[[K]]** - full camera tracking in cutscenes on/off
- **[[-]]** - HUD tracking mode (normal / fixed / headlocked / developer)
- **[[End]]** - gyro stabilization of in-vehicle view on/off
- **[[']]** - slow motion on/off
- **[[N]]** - on-screen FPS counter on/off

## GTAVR motion overlay (optional)

Only relevant if you added the optional GTAVR overlay during install. The
game still **starts in R.E.A.L. head-aim mode**; switch modes with:

- **[[Num 0]]** - open the GTAVR motion-controls overlay
- **[[Num 8]]** - activate motion controls
- **[[Num 2]]** / **[[Num 5]]** - move the overlay up / down while it is open
- Back to **pure R.E.A.L. mode** (cleaner, no motion controls): press
  **[[F11]]** once, then **[[K]]** once. Do **not** use [[0]] for this -
  that triggers GTAVR's own legacy mode without proper R.E.A.L. support.

The overlay is a community add-on (GTAVR, an older standalone wrapper)
layered on top of R.E.A.L. - VorpX is neither involved nor required.

## Notes

- These graphics settings **must** be honored for the mod to work: Aspect
  Ratio = Auto, Shader Quality = Very High or High, Frame Scaling Mode =
  5/2 (x2.5) or 2/1 (x2.0); In-Game Depth Of Field is best Off.
- The game runs in a small **square window** on the monitor (e.g.
  1080x1080); that is normal - the headset gets a much higher internal
  resolution.
- Alternate-eye rendering means fast-moving objects can look slightly
  doubled - that is expected, not a bug.
- Keep **auto-updates off** for GTA V so the build stays at 1.0.2245.0;
  a game update will break the mod until re-applied.
- After a game update you may need a matching `ScriptHookV.dll` from
  Alexander Blade's page (http://www.dev-c.com/gtav/scripthookv/).

## Support & credits

- **R.E.A.L. VR mod** by Luke Ross - https://www.patreon.com/realvr
- Project page: https://github.com/LukeRoss00/gta5-real-mod
- **GTAVR motion-controls overlay** - community mod; download page:
  https://drive.google.com/file/d/1DiWVve3RK-FAD5awyo0RMHfe6nbZ8aBD/view

>>> Pull off the heist, outrun the stars, and own the streets of Los Santos.
