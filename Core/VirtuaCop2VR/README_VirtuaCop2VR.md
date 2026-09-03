# Virtua Cop 2 VR

Native VR for the **1997 PC port** of Virtua Cop 2, by **NeuralF**. Not a flat
screen floating in a headset: the mod intercepts the game's own renderer,
**rebuilds the real 3D scene** from the geometry the engine projects every frame,
and re-renders it through OpenXR - with the original textures, lighting and sky.
You can look around corners the flat game never showed you.

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

**Use "Start in VR" on this page.** That runs a launcher the installer wrote,
which does the whole sequence for you: it starts the game from the right folder,
waits while you get into a level, then starts the VR half. You never have to find
either executable yourself.

> ## The one thing you have to know: press [[Alt]]
>
> When the game starts it accepts **no keyboard and no mouse input at all** -
> it just sits in the main menu and nothing you press does anything.
>
> **Press [[Alt]].** That opens the pause screen, and only from there can you
> change any setting. This is the game's own behaviour from 1997, not the mod.
>
> **On a virtual screen** - Virtual Desktop and the like - press **[[Alt]] twice**
> on the virtual keyboard.

Once the pause screen is open **the mouse works** - click **Device**, then pick
**`Direct 3D + 3D view`**. **That entry is the mod.** The choice is remembered,
so this is a one-time step.

After that you do nothing: **the VR half starts by itself 15 seconds later**, and
you can pick your level from inside the headset. No going back and forth between
the game and a console window. (Pressing a key in the launcher starts it right
away instead of waiting.)

Put the headset on **facing your monitor** - that first head pose becomes the
camera.

The installer also offers a **Desktop shortcut** that does exactly the same as
"Start in VR" - one click, game and VR.

### If you would rather do it by hand
The launcher lives at
`%LOCALAPPDATA%\Programs\Virtua Cop 2 VR\Play Virtua Cop 2 VR.bat`, and the two
programs it starts are:

| | |
|---|---|
| the game | `PROJECT\PPJ2DD.EXE` inside your game folder - working directory **must** be `PROJECT` |
| the VR half | `%LOCALAPPDATA%\Programs\Virtua Cop 2 VR\VC2VR.exe`, started **after** you are in a level |

## Controls
- [[Right Trigger]] / [[Left Trigger]] fire - the hand that fired last holds the gun
- [[A]] / [[X]] reload (Start / Enter in menus)
- [[B]] / [[Y]] back (Esc)
- [[Right Stick Up]] flick to toggle zoom - flick again to drop it
- [[Right Stick Click]] floating menu screen: auto / always / off
- [[Right Grip]] / [[Left Grip]] recentre the view

The game's own cinematic zoom moments are mirrored in VR automatically. Menus,
cutscenes and score screens appear on a floating screen you click with the laser.

## Settings
| File | What is in it |
|---|---|
| `VC2VR.ini` (with the VR app) | `msaa`, `supersample`, `zoom` (magnification cap), `zoomspeed`, `autozoom`, `hidecross` (hide the flat crosshair sprite - the laser replaces it), `aimreach`, `focusgame` |
| `HGL_VIEW.ini` (in `PROJECT`) | `units_per_metre` - **world scale**. Smaller if the world feels like a dollhouse, larger if everything is gigantic. Plus the capture and rendering keys. |

Both files are commented.

## If something is wrong
| Symptom | Cause |
|---|---|
| Game dies with `not found ...BIN\MOTCMN.BIN` | It is not running from `PROJECT`, or the shortcut's *"Start in"* is wrong. **This is the game's own loader, not the mod.** |
| VR input works but no picture (`--window` shows 0 triangles) | `Direct 3D + 3D view` is not the selected renderer. Pick it again in the selector. |
| Headset says *"waiting for the game"* | Same cause, or `share=0` in `HGL_VIEW.ini`. |
| The floating menu screen stays black | Run the game **windowed** - the capture cannot see an exclusive-fullscreen window. |

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
