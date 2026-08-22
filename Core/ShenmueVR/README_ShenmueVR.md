# Shenmue I & II VR

Stereoscopic VR with a first-person view for the **Steam release** of Shenmue I
and Shenmue II. By **Tensai37**, hosted on Codeberg.

> **A controller is required.** Since v1.3 your VR controllers work too - but as
> a plain gamepad. There are no motion-tracked controls and nothing is held in
> your hands.

## Frame interpolation is required - read this first

Shenmue II is hard-capped at **30 FPS**, and so is Shenmue I outside normal
first-person play. A faster PC does not lift that cap, so the mod needs frame
interpolation to feel right. Turn on whichever your setup offers, **before** you
play:

| Setup | Turn on |
|---|---|
| Quest over Link or Air Link | Asynchronous Spacewarp (ASW) |
| Quest / Pico / Play For Dream over Virtual Desktop | Synchronous Spacewarp (SSW) |
| SteamVR headsets, including PS VR2 | Motion Smoothing |

Without it the picture judders, and the game can crash.

## Requirements
- **Shenmue I & II on Steam, version 1.07.** The setup checks your executable and
  refuses versions it does not recognise - it never patches something unknown.
- A PC VR headset and an active runtime or streaming connection
- A game controller

## What the installer does
The mod ships as its own **setup program**, not as a zip. The Hub fetches the
newest release from Codeberg, finds your game folder, puts that path on your
clipboard and starts the setup for you. You answer three questions in it: the
game folder, which of the two games to patch, and - new in v1.3 - **OpenVR or
OpenXR**. Pick OpenXR: the framerate boost for Shenmue I exists only on that
path.

> **About the folder name.** The author's instructions say to pick your
> `SMLaunch` folder. There is no such folder - the real one holds
> `SteamLauncher.exe` with `sm1\` and `sm2\` beside it. The Hub shows you the
> correct path, so just paste it.

Afterwards the Hub checks the result: it looks for `ShenmueVR.ini` in `sm1\` and
`sm2\` and tells you which game actually got the mod.

## What lands in the game folder
Ten files, and nothing is removed:

- `sm1\XINPUT1_3.dll` and `sm2\XINPUT1_3.dll` - the loader, a different build per game
- `sm1\openvr_api.dll` and `sm2\openvr_api.dll`
- `sm1\ShenmueVR.ini` and `sm2\ShenmueVR.ini` - the mod's settings
- `sm1\.ShenmueVR-installer-backup\` and the same under `sm2\` - the setup's own
  backup of your untouched game executable. **Leave those alone**, they are the
  way back.

The game executables themselves are patched in place. Their size does not change.

## How to launch - the order matters
1. Connect the headset to the desktop.
2. Start Link, Air Link, Virtual Desktop or SteamVR.
3. Turn frame interpolation on.
4. Launch Shenmue I or II as usual.
5. Once it is in VR, **click the game window on the desktop once** so it has input
   focus - otherwise the controller does nothing.
6. Put the headset back on and play.

If the controller stops responding, click the game window again.

## Controls
Hold the **left trigger** to bring the game's own camera back, so the zoom and
search functions work. Release it and you are in first person again. If the
native camera is already active, the trigger does not force a change.

## What v1.3 changed
- **OpenXR support.** The setup now asks for OpenVR or OpenXR.
- **An adaptive framerate boost for Shenmue I** - and it exists **only on the
  OpenXR path**. Pick OpenVR out of habit and you lose the boost without any
  warning - nothing on screen tells you.
- **VR controllers work** - but as a plain gamepad. There are no motion-tracked
  controls, and nothing is held in your hands.

**The boost does not replace frame interpolation.** It runs during normal
first-person play only; cutscenes and third-person sequences stay at 30 FPS,
and Shenmue II stays at 30 throughout. Leave the smoothing on.

v1.3 installs straight over an earlier version - no need to uninstall first.

## What v1.1 changed
- Corrected the first-person player height in Shenmue I
- The left-trigger camera behaviour above, in both games
- v1.1 installs straight over v1.0 - no need to uninstall first, and it replaces
  the old `ShenmueVR.ini` files with the settings v1.1 needs

## Known limitations
- **Seated play only.** You can look around freely, but turning your body or
  chair is not supported yet.
- A controller is required - a gamepad, or VR controllers acting as one.
  Motion-tracked controls do not exist in this mod.
- Shenmue II stays capped at 30 FPS; Shenmue I only lifts above it during
  normal first-person play, on OpenXR
- The headset and its runtime must be active **before** launching
- The desktop window has to be clicked once after the game enters VR
- Parts of the picture are cut off in the corners at times

## Windows warnings
SmartScreen may show "Unknown publisher" and Defender may flag the setup. It is
an unsigned fan tool; the author has reported the false positive to Microsoft.

## Credits and legal
Mod by **Tensai37** - https://codeberg.org/Tensai37/Shenmue_1_and_2_VR_mod

An unofficial fan project, not affiliated with or endorsed by SEGA. You need to
own the Steam version of Shenmue I & II.

## Support Tensai37

Reverse-engineering both games, building a stable first-person view and writing
an installer that patches your own game files safely took a lot of work. If you
want to show some support:
- https://ko-fi.com/tensai37
- https://www.patreon.com/cw/Tensai37/membership

>>> The sailors are a lie. The forklift is real.
