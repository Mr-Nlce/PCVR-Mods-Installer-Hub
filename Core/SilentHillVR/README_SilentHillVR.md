# Silent Hill (1999) VR

**Native stereoscopic VR inside the Silent Hill PC port.** Not a flat image on a floating
screen and not reprojection: the stereo is generated in the renderer itself, from the
game's own geometry, so the fog has real distance and the doorways occupy real space.

> **v1.0, free.** VRified Games developed this through a Patreon early-access period and
> released version 1.0 to everyone. Unofficial - not affiliated with Konami.

## What you have to bring

- **SteamVR** and a PC VR headset. Wireless is fine - Virtual Desktop, Air Link, Link or
  Steam Link, whatever you normally use.
- **A gamepad.** v1.0 is gamepad only (see below).
- **Your own `Silent Hill (USA).bin` disc image.** No game data ships with the mod and none
  is downloaded. If your Silent Hill PC port already runs, you already have this file.

## Where the .bin goes

The installer creates the folder and opens it for you. The disc image belongs here:

```
<install folder>\pc_port\build\gamedata\Silent Hill (USA).bin
```

The name has to match exactly - the build looks for that file and nothing else.

## Getting into VR

1. Start SteamVR and check your headset is tracking.
2. Launch the game. A virtual screen appears by itself.
3. Press **Numpad Enter** to cycle the view mode.
4. Choose **FULL**, then recenter yourself in your play space.
5. Adjust depth with **Numpad +** and **Numpad −** if you need to.

### The three view modes

| Mode | What you get |
|---|---|
| OFF | The standard flat game |
| 3D SCREEN | Stereoscopic gameplay on a floating virtual screen |
| FULL | Fully immersive stereoscopic VR |

You can switch at any time, so the virtual screen is always there as a comfort fallback.

## Hotkeys

| Key | Function |
|---|---|
| Numpad Enter | Cycle view mode - OFF / 3D SCREEN / FULL |
| Numpad 9 | Toggle the floating mono screen |
| Numpad + / − | Stereo depth (eye separation) |
| Insert / Delete / Home / End | Projection calibration |

> **Leave the PC port's debug controls off.** Its freecam uses the numpad as well, and the
> two will fight each other. This is the author's own warning.

No numpad on your keyboard? The hotkeys can be rebound in the config file - the author
confirmed that in the release comments.

## The world looks like a dollhouse

Several testers reported the scale feeling too small. The author's fix, which will be the
default in a later version:

**Options → PC Options → last page → VR convergence `1.0`, VR depth `0.3`**

## VR options in the game menu

A dedicated VR section lives under **PC Options**: stereo depth, convergence, subtitle size
and position, headset presets, view mode persistence, positional tracking, roomscale scale,
cutscene tracking and camera pitch flattening. Everything saves automatically, so your
setup is still there next launch.

**Flatten Camera Pitch is on by default.** Silent Hill's original camera tilts in ways that
feel wrong in VR; this keeps the horizon level while preserving the intended camera
movement. If you are sensitive to motion sickness, leave it on. If you want the original
framing, turn it off.

## What works, and what does not yet

- **6DOF head tracking** - lean in to examine something, peek round a corner, look over an
  obstacle. Positional tracking is camera-relative and works with the original camera system.
- **Roomscale movement with collision** - step through your play space and Harry moves with
  you, without walking through walls.
- **Automatic presentation** - cutscenes, FMVs, inventory, maps, save screens and item
  pickups each get an appropriate treatment, and gameplay presentation returns by itself.
- **VR-aware subtitles**, independently sized and positioned.
- **Resolution independent** - change the game resolution and the view recalibrates itself.

**Motion controllers are not wired up.** Your controllers still provide positional tracking,
but aiming and interaction run through the gamepad. Decoupled motion-controller aiming is
the author's next major goal - pointing the weapon where you point rather than where Harry
faces - but no date has been promised.

## Credits

**VRified Games** built the VR layer and released v1.0 free. The Patreon early-access
supporters and beta testers shaped it - headset reports, FOV feedback and bug reports from
people playing on hardware the author does not own.

The underlying Silent Hill PC port is a separate community project; this build includes it.
Silent Hill is Konami's. Bring your own disc image.
