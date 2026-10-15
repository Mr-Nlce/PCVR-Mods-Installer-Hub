# Virtua Cop 2 VR

Native VR for the **1997 PC port** of Virtua Cop 2, by **NeuralF**. Not a flat
screen floating in a headset: the mod intercepts the game's own renderer,
**rebuilds the real 3D scene** from the geometry the engine projects every frame,
and re-renders it through OpenXR - with the original textures, lighting and sky.
You can look around corners the flat game never showed you.

The current beta expands that reconstruction to **360 degrees**, adds a
revolver model with recoil/reload animation, corrected brightness and world
scale, a world-fixed sky dome and sharper zoom-aware HUD rendering.

Your motion controller is the light gun. **Where the laser points is where the
game registers the hit**, at any zoom level.

> **You need your own copy of the 1997 PC game.** It is not sold on Steam, GOG,
> Epic or anywhere else. No game files are included with the mod, and none ever
> will be.

## What the installer does
You **drag `PPJ2DD.EXE` into the window** - there is no store to ask, so that is
how the Hub learns where your copy lives. Then it:

1. creates a **`PROJECT`** folder inside your game folder,
2. copies the game's **loose files** into it - files only, never the folders,
3. puts the mod's renderer (`HGL_VIEW.DLL`, `HGL_VIEW.ini`) in there beside them,
4. and places the VR application somewhere of its own, under
   `%LOCALAPPDATA%\Programs\Virtua Cop 2 VR`.

**Nothing of your original install is changed.** The files in the game root stay
exactly where they are.

### Why a PROJECT folder at all
The 1997 loader reads its data from `..\BIN\` - **one level above** its working
directory. A stock install puts `PPJ2DD.EXE` in the game root, right *next to*
`BIN`, so started from there the game looks outside itself, finds nothing, goes
hunting for a CD and dies with `not found <drive>:\...\MOTCMN.BIN`.

Run it from inside `PROJECT` and `BIN` is exactly one level up, where the loader
expects it.

### Why the VR half sits somewhere else
The game is **32-bit**, the VR runtime is **64-bit**, and the two cannot live in
one process. `HGL_VIEW.DLL` rides inside the game and shares what it sees;
`VC2VR.exe` is a separate 64-bit program that renders for your headset. That is
why it does not belong in the game folder.

## Playing

**Use "Start in VR" on this page.** The Hub opens `VC2VR.exe`. The publisher's
v1.0 beta launcher starts `PROJECT\PPJ2DD.EXE`, selects the VR renderer and
sets windowed mode. The installer writes the full game path to `gameexe` in
`VC2VR.ini`, because the VR application lives outside the game folder.

If you still need the original game's pause screen, [[Alt]] opens it. The
publisher launcher normally selects the renderer without this manual step.

Put the headset on **facing your monitor** - that first head pose becomes the
camera.

The installer also offers a **Desktop shortcut** that does exactly the same as
"Start in VR" - one click, game and VR.

### If you would rather do it by hand
The Hub launcher lives at
`%LOCALAPPDATA%\Programs\Virtua Cop 2 VR\Play Virtua Cop 2 VR.bat`.
It opens the publisher's `VC2VR.exe`; that program starts the game:

| | |
|---|---|
| Game | `PROJECT\PPJ2DD.EXE` inside your game folder, specified by `gameexe` in `VC2VR.ini` |
| VR launcher | `%LOCALAPPDATA%\Programs\Virtua Cop 2 VR\VC2VR.exe` |

## Controls

| Button | Action |
|---|---|
| [[Right Trigger]] / [[Left Trigger]] | Fire; the last hand to fire holds the gun |
| [[A]] / [[X]] | Reload; Start / Enter in menus |
| [[B]] / [[Y]] | Back / Escape |
| [[Right Stick Up]] | Flick to toggle zoom; flick again to drop it |
| [[Right Stick Click]] | Set floating menu screen to auto / always / off |
| [[Right Grip]] / [[Left Grip]] | Recentre the view |

With **akimbo** enabled, the second controller is player 2. Press its [[A]] or
[[X]] to join. A second person can then play on the monitor while you use the
other controller in VR. The release ships with akimbo enabled; for the monitor
crosshair keep `akimbo=1` in both ini files and `hidexhair=3` in `HGL_VIEW.ini`.

The game's own cinematic zoom moments are mirrored in VR automatically. Menus,
cutscenes and score screens appear on a floating screen you click with the laser.

## Settings
| File | What is in it |
|---|---|
| `VC2VR.ini` (with the VR app) | `msaa`, `supersample`, `zoom`, `zoomspeed`, `autozoom`, gun model and `akimbo` |
| `HGL_VIEW.ini` (in `PROJECT`) | `units_per_metre` world scale, 360-degree capture, HUD, monitor window, `hidexhair` and `akimbo` |

Both files are commented.

## If something is wrong
| Symptom | Cause |
|---|---|
| Game dies with `not found ...BIN\MOTCMN.BIN` | Check the `gameexe` path in `VC2VR.ini`; its `PROJECT` folder must sit directly below the game folder with `BIN`. |
| VR input works but no picture (`--window` shows 0 triangles) | Check the renderer selected in the game and the `gameexe` path. |
| Headset says *"waiting for the game"* | Check that the publisher launcher started the game and that `share=1` in `HGL_VIEW.ini`. |
| The floating menu screen stays black | The capture cannot see an exclusive-fullscreen window. Check windowed mode. |

`VC2VR.exe --window` renders to a flat window instead of the headset, which is
the quickest way to tell a game-side problem from a VR-runtime one.

## Known issues
- Occasional **draw-order glitches** on some level sections - the engine's blend
  and fog flags are not fully decoded yet.
- **Magnified view amplifies head shake.** That is physics, not a bug; lower the
  zoom cap if it bothers you.

## Credits
**Virtua Cop 2** is by **SEGA AM2**. The VR mod is by **NeuralF**, unofficial and
not affiliated with SEGA.

https://github.com/NeuralF/Rea-Virtua-Cop-2-VR

>>> Point. Shoot. Reload with a flick. Just like the cabinet.
