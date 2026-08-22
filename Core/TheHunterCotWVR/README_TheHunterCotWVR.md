# theHunter: Call of the Wild VR

theHunter: Call of the Wild is a hunting simulation set in vast, quiet open
worlds - you track animals by their prints, droppings and calls, read the wind,
and take one careful shot rather than many. The reserves are enormous and mostly
empty on purpose.

**Native OpenXR stereo VR** by **Vaas993**. The world is drawn from the game's
own camera, once per eye - real depth, your head turns the view, you can lean and
step around inside it, and your weapon has depth.

## The game comes first, flat

The Hub's installer opens the game **before** it installs anything so you can set
the video options the mod expects:

| Setting | Value |
|---|---|
| Anti-aliasing | FXAA + TAA |
| Display mode | windowed |
| V-Sync | off |
| **Field of view** | **90** |
| Motion blur | off |

**Field of view 90 matters most.** 90 is the game's maximum.

Then close the game and let the installer carry on.

## Built for one game build

The mod targets **game update 9.2 (Peru Hunting Reserve)** and identifies the
game **by fingerprint**. On a newer build it refuses to guess and simply does
nothing at all - no error, no VR. That is the author's design decision, not a
fault, and it is the most common "nothing happens" report.

**Steam only.** Other storefronts are not supported.

**Single player only** - do not use it in multiplayer sessions.

## You do not need an RTX card

Three anti-aliasing choices, and the mod sets the game's own to match:

| Choice | Needs | What you get |
|---|---|---|
| NVIDIA DLSS | RTX card | Best picture, and the only one that buys frames back by upscaling |
| Per-eye smoothing | any card | The mod's own pass - keeps each eye's history separate, so no cross-eye ghosting |
| Off | - | The game's own. Sharp, aliased, foliage shimmers |

## Setting it up

Copying the files is only half of it: the mod brings **its own settings program**.
**Start in VR in the Hub opens that program** so you can change options.

Inside, set these options:

- **Field of View > Field of View given to the game: 90** (the game's maximum).
- **Picture > Anti-aliasing:** you can set it to **Off**. Other settings can cause
  a black screen.
- **Head tracking mode: 6-DoF.** This lets you lean and step around.

Then click **Save** and **Launch game**.

**Put the headset on before the game finishes loading.**

## Controls

| Key | |
|---|---|
| [[Insert]] | open the settings panel in the headset |
| [[Pause]] | recentre the view - use it whenever forward stops being forward |
| [[Delete]] | show the flat game screen, for menus and the map |
| [[Alt]] held | free look - the view turns, the weapon stays put |

Everything is rebindable in the panel, and the panel works with a gamepad. A
gamepad plays better here than mouse and keyboard.

## Known issues - all named by the author

- **Shimmer with DLSS on**, worst on close-up geometry and edges. Weapon depth
  makes it worse, and it reads as the *world* shaking rather than the weapon. Two
  things help: DLSS models M and L reduce it noticeably, and turning weapon depth
  off on the WEAPON tab removes its share entirely.
- **The HUD is drawn flat across the whole view** rather than at a comfortable
  distance. The switches that move it currently break more than they fix, which
  is why they carry a warning.
- **Leaning does not collide with anything.** 6DoF moves the camera, not the
  character - lean far enough and you lean through a wall. The travel limit in the
  panel is the guard.
- **The scope's magnified picture is positioned from your head**, not from the
  gun, so holding free-look while aimed slides it off the scope.
- Sizes are worked out for a **Quest 3**. Other headsets run fine but may lose
  some field or waste pixels - use the CUSTOM resolution and raise "How much
  wider" until it fills the view.

## If something goes wrong

**Black screen in the headset, game fine on the monitor:**

- In the mod settings, set *Picture > Anti-aliasing* to **Off**.
- Turn HDR off in Windows with **Win + Alt + B**.
- Windows 11: *Settings > System > Display > Use HDR*.
- Windows 10: *Settings > System > Display > Windows HD Color*.

Still black? Check `%LOCALAPPDATA%\theHunterCotWVR\cotwvr.log`.

**Nothing starts at all** - the game has most likely been updated past this build.
See the fingerprint note above.

**You want the game back to normal** without removing anything - set *VR mod* to
off in the settings program. Every file stays where it is.

The settings program also has an *Open log folder* button.

## Credits

Mod by **Vaas993** - https://github.com/vaas993/theHunterCotW-VR

Includes NVIDIA DLSS, the Khronos OpenXR loader and MinHook. theHunter: Call of
the Wild is a trademark of Expansive Worlds / Avalanche Studios; this mod is
unofficial and not affiliated with them.

>>> A bad shot in VR still counts. The elk knows.
