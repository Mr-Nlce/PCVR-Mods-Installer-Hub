# Shenmue I & II VR

Stereoscopic VR with a first-person view for the **Steam release** of Shenmue I
and Shenmue II. By **Tensai37**, hosted on Codeberg.

> **A game controller is required.** VR motion controllers are not supported yet.

## Frame interpolation is required - read this first

Both games are hard-capped at **30 FPS**. A faster PC does not lift that cap, so
the mod needs frame interpolation to feel right. Turn on whichever your setup
offers, **before** you play:

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
clipboard and starts the setup for you. You answer two questions in it: the game
folder, and which of the two games to patch.

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

## What v1.1 changed
- Corrected the first-person player height in Shenmue I
- The left-trigger camera behaviour above, in both games
- v1.1 installs straight over v1.0 - no need to uninstall first, and it replaces
  the old `ShenmueVR.ini` files with the settings v1.1 needs

## Known limitations
- A controller is required; motion controllers are not supported
- Both games stay capped at 30 FPS
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
