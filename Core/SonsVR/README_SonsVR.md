# Sons of the Forest VR

Full VR through **SteamVR** for a game that never shipped a VR mode. By
**Anthony (iPowerTech)**, built on MelonLoader and Il2CppInterop, driving OpenVR
directly. Works with any OpenVR headset - Index, Vive, Quest over Link or
Virtual Desktop.

> **Alpha.** Expect rough edges and report what breaks.

**No game file is replaced** - verified by comparing the game folder before and
after: 172 files added, none removed, none changed in size. Existing saves and
other mods keep working.

## The first start takes several minutes - do not kill it

The window will look frozen. It is not. MelonLoader downloads the tools it reads
the game with, then **generates its assemblies from your copy** of the game.
Neither ships with the mod, and neither could: both belong to one install and one
game version. **You need an internet connection for that first run.** Every later
start is quick.

Start **SteamVR first**, then the game.

## Requirements

| | |
|---|---|
| Game | **Sons of the Forest** on Steam |
| Runtime | **SteamVR**, running before the game starts |
| Loader | MelonLoader 0.7.3 - the installer brings it |

## What you get
- **Stereo rendering** with per-eye offsets and projection matrices from OpenVR.
  The eye cameras copy the render configuration of the active game camera, HDRP
  volumes and post-processing included.
- **6DoF head tracking** - position as well as rotation, clamped so the view
  cannot drift off the character's head.
- **Hands follow the controllers**, driven through the Final IK rig the game
  already carries. Elbow goals keep the arms from folding across the chest.
- **Real body-turn detection.** The two controllers stand in for your shoulders:
  turn your whole body and the character follows, but a glance over the shoulder
  leaves it alone - which also keeps scripted animations intact.
- **Everything flat is put in the room** - menus, inventory, HUD and the loading
  screen on world-anchored panels.
- **Laser pointer** from either controller; the other trigger hands the beam
  across.
- **Settings panel in the headset** - around thirty settings, applied as you move
  the slider, with a Cancel that restores what was there.

## Controls

- [[Left Stick]] move
- [[Right Stick]] turn left and right
- [[Right Stick Up]] run
- [[Right Stick Down]] crouch
- [[Right Trigger]] primary action, interact, place - **and the menu click**
- [[Left Trigger]] secondary action, melee - or a fast right-hand swing. **In menus it hands the beam over, it does not click.**
- [[Left Grip]] / [[Right Grip]] take, use, save
- [[Left Grip]] / [[Right Grip]] **held** drop
- **Both controllers raised sharply** jump
- [[Y]] inventory
- [[B]] lighter
- [[A]] reload, rotate
- [[Left Grip]] **at your right shoulder** GPS tracker
- [[Right Grip]] **at your left shoulder** walkie-talkie
- [[Right Grip]] **at your right shoulder** book

Gestures and buttons are translated into the keyboard and mouse events the game
already understands, so no game code is changed.

## Menus: which trigger actually clicks

**The trigger means two different things depending on which hand holds it.**
The beam starts on your **right** hand, so:

- **Right trigger = click.** This is the one that presses what you are pointing at.
- **Left trigger = hand the beam over.** It does not click. That press is
  deliberately swallowed, so taking the beam never presses whatever it was
  resting on - which means the first squeeze after a swap does nothing at all.

Once the beam is on your left hand the roles swap: left clicks, right hands it
back. If nothing ever activates, you are almost certainly squeezing the trigger
of the hand that is *not* holding the beam, and each squeeze just passes the beam
back and forth.

The thumbstick moves the pointer when the beam is off the panel.

**If you would rather not think about it:** set `LaserPointer` to `false` in
`UserData/MelonPreferences.cfg` under `[SonsVR]`. With the beam off, **either**
trigger clicks and the thumbstick drives the pointer. You can also start the beam
on the left hand instead with `LaserLeftHand = true`.

## Fixed in v0.0.5-alpha

- **The world sheared when you turned your head.** On headsets with **canted
  (angled) displays - the Quest 3 among them** - a rectangle turned into a
  trapezium as you looked around. The projection is now taken from the runtime
  exactly as given instead of being rebuilt from field-of-view tangents, which
  could not describe the shear a tilted panel puts in. **Pico 4, Pimax Crystal
  and Index were never affected**, which is why it went unnoticed for so long.
- **The pause and save screens could not be clicked.** They were visible but the
  laser passed straight through them - they rode on a surface locked to your
  head, which is the one thing a pointer cannot aim at. While a menu is open that
  surface is now anchored in the room, and handed back the moment it closes.
- **A clean install had no controller input at all.** The SteamVR action manifest
  was missing from the package. Without it every action reads zero, and it looks
  like anything but a missing file: the headset tracks, the hands track, the
  laser is drawn - and no trigger, stick or button does anything. It ships with
  the release now.

## Thumbsticks changed in v0.0.5-alpha

| Control | Sends | Now needs |
|---|---|---|
| Right stick up | [[Left Shift]] - sprint | close to the end of its travel |
| Right stick down | [[Left Ctrl]] - crouch | close to the end of its travel |
| Left stick sideways | A / D | past half |

The right stick also turns you, and a turn is rarely a perfectly sideways push -
the stray forward or back picked up while sweeping the thumb was enough to break
into a run or drop into a crouch mid-look. **Sprint was not bound at all before
this release.**

Each direction lets go at a *lower* threshold than it took to engage, so a thumb
resting on the line does not make the key flicker.

Two new settings, on the headset panel under **Movement**:

| Setting | Default | Range |
|---|---|---|
| `RunCrouchThreshold` | 0.85 | 0.50 - 0.98 |
| `StrafeThreshold` | 0.50 | 0.20 - 0.90 |

**If you liked the old, much lighter crouch**, set `RunCrouchThreshold` to `0.30`.

## Settings worth knowing
Most are on the panel in the headset. All of them live in
`UserData/MelonPreferences.cfg` under `[SonsVR]`, each with a description. Values
in the file win over the defaults, so a file from an older version keeps yours.

| Setting | Default | What it does |
|---|---|---|
| `RenderScale` | 0.70 | Multiplier on the eye resolution SteamVR asks for. **The first thing to change** if it is too soft or too slow. |
| `FovTangentHorizontal` / `Vertical` | 0.90 / 0.86 | Render less than the full field of view, dropping the outer edge the lens barely shows - worth roughly a quarter of the pixels. Push further and a black border appears. |
| `DesktopMirror` | true | Mirror an eye to the monitor instead of rendering the game camera again. Removes a whole render pass. |
| `PositionalTrackingRange` | 0.30 | How far in metres the view may move off the character's head. 0 pins it. |
| `PlayerEyeHeightOffset` | 0.19 | Raises the viewpoint - the game hangs its camera nearer the neck than the eyes. |
| `HandTracking` | true | Arms follow the controllers. |
| `SmoothTurn` | false | Smooth turning instead of snap. |

## Known limitations
- **Held items are not aligned to your hands.** The arms follow the controllers,
  but a weapon still sits where the animation puts it.
- **Two full render passes per frame.** Single-pass stereo needs a native XR
  provider, which has to be present when the game is built and cannot be added to
  a shipped one. The mod's own code costs about 0.35 ms of a 20 ms frame - the
  rest is the engine drawing two cameras, shadows being the largest item.
- Individual screen-space overlays can still be missing from the headset. The
  pause and save screens were the worst of these and are fixed in v0.0.5; if you
  hit another one, **F9 and F10 write the whole interface state to the MelonLoader
  log** - two keys rather than one, so two screens can be captured and compared.
  That log is exactly what the author needs in a bug report.
- **Cutscenes take their heading from your headset**, so the framing a cutscene
  intended is not always what you are looking at. That is deliberate: inheriting
  a tumbling camera is the fastest way to make someone ill.

## Removing it
The one-click installer registers itself with Windows, so the clean way is
**Settings - Apps - Installed apps**, or `unins000.exe` in the game folder.

If you would rather do it by hand, delete `Mods\`, `UserLibs\`, `MelonLoader\`,
`UserData\MelonPreferences.cfg` and `version.dll`.

Either way there is nothing to restore: a before/after comparison of the game
folder shows the mod adds **172 files and changes none** - not one game file is
replaced, and not one changes size.

## Credits
**Sons of the Forest** is by **Endnight Games**. The VR mod is by **Anthony
(iPowerTech)**, unofficial and not affiliated with the developer, built on
MelonLoader, Il2CppInterop and the SteamVR Unity plugin.

https://github.com/iPowerTech/SonsVR_Mod

>>> No VR mode was ever shipped for this island. Someone built one anyway.
