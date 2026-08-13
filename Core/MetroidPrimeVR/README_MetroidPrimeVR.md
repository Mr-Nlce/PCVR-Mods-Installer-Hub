# Metroid Prime VR (PrimedGun)

PrimedGun is a **Dolphin XR Redux**-based build by **Nobbie** focused on a proper VR
experience for **Metroid Prime** (GameCube): 6DOF arm-cannon tracking, visor head
tracking with gesture input, full directional movement, improved gun-based targeting
and grapple, and an in-headset settings menu. It runs **standalone** - you do not need
Dolphin installed, and it is not a hook or injector.

> Metroid Prime is a critically acclaimed first-person action-adventure game developed
> by Retro Studios and published by Nintendo. Originally released for the GameCube in
> November 2002 and now fully playable in VR with 6DoF motion controls.

## Features

- Full directional movement and a modern VR control scheme.
- Visor head tracking with hand-gesture input.
- Improved gun-based targeting and grapple.
- 6DOF arm-cannon tracking; cannon position/rotation calibration.
- One-click height calibration.
- Easy cannon-texture swapping tool.
- In-headset settings menu.

## Requirements

- A **Metroid Prime - NTSC 1.0 (Revision 0)** GameCube disc image
  (`.iso` / `.rvz` / `.gcm`). **NTSC 1.0 / rev 0 only - not rev 1 or rev 2.**
  You can verify the disc revision in Dolphin.
- A PC VR headset with **SteamVR**. The Oculus/Meta runtime is **not recommended**.
- PC power tier: **Strong** (roughly RTX 4070 / R5 7600 class).

No game ROM is downloaded or shipped. Only the PrimedGun application is fetched from
the official GitHub releases.

**Standalone:** PrimedGun is not a Dolphin hook/injector - it ships as its own program.
The Hub installs it into its own clean folder, separate from any Dolphin install (do
not extract it on top of an existing Dolphin, that breaks things). To carry over a save
from Dolphin, copy your Dolphin memory-card data into PrimedGun's `User` folder.

## Install (via the Hub)

1. In the Hub, open Metroid Prime VR and run the installer.
2. Accept `C:\Games\Metroid Prime VR` or pick your own folder.
3. The installer downloads the latest PrimedGun release, enables Dolphin portable
   mode (`portable.txt`), creates a `ROM` subfolder and pre-points the game list at it.
4. Drop your **Metroid Prime NTSC 1.0 (rev 0)** ISO into:
   `C:\Games\Metroid Prime VR\ROM`

### Updates and reinstalls

Both modes preserve the complete `User` folder (game saves, Dolphin save states and
preferences) and the `ROM` folder. Update mode merges the new release files into the
existing installation. Reinstall mode rebuilds the application files, then restores
the preserved user data. The installer keeps an external safety backup until every
preserved file has been restored and verified; an interrupted run recovers that
backup automatically the next time the installer starts.

## How to play

1. Put your ISO in the `ROM` folder (see above).
2. Start **SteamVR** first.
3. Launch with **Start in VR** in the Hub, or the **Metroid Prime VR** desktop shortcut (or `PrimedGun.exe`).
4. Your ROM should already be listed - select it and press **Play**.
   If it is not listed, click **Select Game...**, pick the ISO once, then press **Play**.

## VR controls

![Controller layout](ControllerLayout.jpg)

Left controller:

- [[Stick]] Move
- [[Stick Click]] VR Settings
- [[Y]] Start / Pause
- [[X]] Morph Ball
- [[Grip]] Map
- [[Trigger]] Lock-on

Right controller:

- [[Stick]] Look / Jump
- [[Stick Click]] Set Height
- [[B]] Beam Select
- [[A]] Select
- [[Grip]] Missiles
- [[Trigger]] Shoot

Tip: place your off-hand near your head and use the control stick to change visors.

## Credits

- Created by **Nobbie**.
- Huge thanks to **iChris4** for Dolphin XR Redux development, and to the Dolphin team.
- Thanks to the Metroid Prime modding community and the early testers.
- Dolphin VR Discord: https://discord.gg/GdmffzCTrh

## Links

- Info / source: https://github.com/Nobbie248/PrimedGun
- Latest release: https://github.com/Nobbie248/PrimedGun/releases/latest
