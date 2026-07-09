# Grand Theft Auto V VR

Adds Luke Ross's **R.E.A.L. r7** VR mod (plus an optional **GTAVR
motion-controls overlay**) to your own copy of **Grand Theft Auto V**.
It uses the community **GTA-VRV-Patcher**, so it runs on the **current
game build (1.0.3788.0)** - **no downgrade needed**. No game files are
bundled: **ScriptHookV** (from dev-c.com) and the **patcher** (from
GitHub) are downloaded for you; the optional motion overlay is
downloaded by you from its page and dragged into the installer.

## Important - read first

- This is **not** GTA V Enhanced (the 2025 release, a separate game) -
  that one is incompatible with R.E.A.L. r7.
- **Experimental.** Gamepad (OpenXR) is the stable option. Motion
  controls (OpenVR) are **work-in-progress** and only start correctly in
  VR sometimes.

## Requirements

- **GTA V Legacy** (NOT GTA V Enhanced) - Steam, Epic, Rockstar or
  Xbox/Microsoft Store. No downgrade needed.
- A VR headset with a working **OpenXR** runtime (gamepad mode) and
  **SteamVR / OpenVR** (motion mode).
- A **gamepad** - R.E.A.L. is designed around it.

## What the installer does

1. **Finds your GTA V automatically** via your Steam/Epic/Rockstar/Xbox
   install (drag-drop fallback only if that fails).
2. Downloads **ScriptHookV** and extracts `ScriptHookV.dll` + `dinput8.dll`
   into the game folder.
3. Downloads the **GTA-VRV-Patcher** and extracts it into the game folder
   (`RealVR.asi`, the compatibility patch, 3DMigoto, `PlayGTAV.exe`, etc.).
4. Runs `RealConfig.bat` (pick Low / Medium / High) and then **locks
   `settings.xml` read-only** so GTA cannot reset the 1080x1080 VR
   resolution on the next launch.
5. **Optional:** opens the GTAVR motion-controls page; you download the
   package (`All we need.zip`) and drag it in, and the installer adds
   `GTAVR.asi`. Skip it for gamepad-only play.
6. Creates the launchers in a `VRLaunch` subfolder and **two desktop
   shortcuts** (the Motion one only if you added the overlay).

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

Launch with the desktop shortcut for the mode you want:

- **Grand Theft Auto V VR** - Gamepad, **OpenXR** (stable).
- **Grand Theft Auto V VR Motion (WIP)** - motion controls, **OpenVR**
  (only exists if you added the overlay).

**IMPORTANT:** in Steam (GTA V > Properties), turn **OFF** "Use Desktop
Game Theatre while SteamVR is active" - otherwise VR shows only a flat,
transparent screen instead of the real game.

1. **Aiming is head-driven (gaze aiming).** Use a **gamepad** (Xbox pad
   recommended) or **keyboard & mouse**. Tracked controllers are **not**
   supported by R.E.A.L. itself - that is what the optional GTAVR overlay
   adds.
2. **Recenter view / HUD:** briefly shake your head side to side, as if
   saying "no". Works anywhere (missions, menus, driving).
3. **In a vehicle**, to realign with the car without moving the HUD, tap
   **look behind** ( [[C]] on keyboard, or press in the right stick
   [[R3]] ).

## Hotkeys

The R.E.A.L. hotkeys are **disabled at startup**. Press **[[F11]]** once
to turn them on (it is an on/off toggle, like Caps Lock - not a key you
hold). Press [[F11]] again to turn them back off.

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
- **[[J]]** - cutscene pitch mode (absolute / relative / cut relative)
- **[[K]]** - full camera tracking in cutscenes on/off
- **[[-]]** - HUD tracking mode (normal / fixed / headlocked / developer)
- **[[End]]** - gyro stabilization of in-vehicle view on/off
- **[[']]** - slow motion on/off
- **[[N]]** - on-screen FPS counter on/off

## GTAVR motion overlay (optional, WIP)

Only relevant if you added the optional GTAVR overlay and use the
**Motion (WIP)** shortcut. Inside the game:

- **[[Num 0]]** - open the GTAVR menu
- **[[Num 8]]** - move up
- **[[Num 2]]** - move down
- **[[Num 5]]** - confirm

The overlay is a community add-on layered on top of R.E.A.L. Motion is
work-in-progress and does not always initialise in VR.

## Notes

- These graphics settings **must** be honored for the mod to work: Aspect
  Ratio = Auto, Shader Quality = Very High or High, Frame Scaling Mode =
  5/2 (x2.5) or 2/1 (x2.0); In-Game Depth Of Field is best Off.
- The game runs in a small **square window** on the monitor (1080x1080);
  that is normal. If it ever opens as a large window, GTA rewrote
  `settings.xml` - re-run `RealConfig.bat` (the installer re-locks it).
- Alternate-eye rendering means fast-moving objects can look slightly
  doubled - that is expected, not a bug.
- **No downgrade** is needed - the patcher runs R.E.A.L. on build
  1.0.3788.0. If GTA V later updates to a newer build, **ScriptHookV**
  and the **patcher** may need updating to match.

## Optional: immersive driving (Manual Transmission)

If you care about a realistic driving feel, **SanguShellz** is also reviving
**GTA V Manual Transmission** so it runs on this same GTA V Legacy build
(1.0.3788). It adds a manual gearbox (sequential or H-pattern), a working
clutch, tunable driving assists (launch/traction/stability/ABS), and full
**steering-wheel** support with force feedback and 1:1 hand-over-hand
animations. It is **work-in-progress** and does not yet match the newest
Patreon versions, but it is worth a look:

- https://github.com/SanguShellz/GTAVManualTransmission
- Original by ikt - https://www.patreon.com/ikt

This is a separate, optional mod - the Hub does not install it.

## Support & credits

- **R.E.A.L. VR mod** by Luke Ross - https://www.patreon.com/realvr
- Project page: https://github.com/LukeRoss00/gta5-real-mod
- **GTA-VRV-Patcher fork** by SanguShellz - the version this Hub currently
  pulls (more actively updated at the moment) -
  https://github.com/SanguShellz/GTA-VRV-Patcher
- **GTA-VRV-Patcher** originally by Francisco Manzanilla (the fork is based
  on his work) - https://github.com/FranciscoManzanilla/GTA-VRV-Patcher
- **ScriptHookV** by Alexander Blade - https://dev-c.com/gtav/scripthookv/
- **GTAVR motion-controls overlay** - community mod

>>> Pull off the heist, outrun the stars, and own the streets of Los Santos.
