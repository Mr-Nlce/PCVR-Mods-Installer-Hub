# theHunter: Call of the Wild VR

theHunter: Call of the Wild is a hunting simulation set in vast, quiet open
worlds - you track animals by their prints, droppings and calls, read the wind,
and take one careful shot rather than many. The reserves are enormous and mostly
empty on purpose.

**Native OpenXR stereo VR** by **Vaas993**. The world is drawn from the game's
own camera, once per eye - real depth, your head turns the view, you can lean and
step around inside it, and your weapon has depth.

## Choose Current or Depot first

The installer's first choice is **Current** or the separate **9.2 depot**.
Current changes only the normal Steam installation and follows new publisher
releases. The menu reads Steam's local build and depot manifest. Publisher
v1.4.1 supports the September 2026 game update (9.3); the author tested it
in a headset with a Quest 3 and RTX 5090. The 9.2 build also remains available.
For a future unconfirmed game build, the separate 9.2 depot is the fallback.

Depot downloads Steam App `518790`, main-game depot `518791`, manifest
`6760390524926456616` (June 16, 2026, build `23311888`) with the Steam Console.
It keeps the game separate under `C:\Games\theHunterCotW VR 9.2` by default,
writes `steam_appid.txt` with `518790`, and installs the pinned publisher mod
**v1.3.1**. This is a large game download; leave enough disk space. The
normal Steam copy remains in its library. If a complete pinned depot is already
present, setup reuses it. If Steam cannot find the depot folder, the installer
offers retry, a manual `depot_518791` folder, or cancellation.

Use **Start 9.2 Depot** in the Hub to open that copy's settings launcher. When
both routes have the VR mod, the Hub shows separate Current and Depot launch
actions. Steam updates to the normal game do not update the pinned depot.

## The game comes first, flat

After the route choice, the Hub's installer can open that selected game copy
**before installing the VR mod** so you can set the video options it expects:

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

The pinned depot mod v1.3.1 targets **game update 9.2 (Peru Hunting Reserve)**.
Current v1.4.1 adds support for the September 2026 game update. Both builds
identify supported game versions rather than guessing; a later unsupported
build may start flat until the publisher updates the mod.

**The Hub's Current and Depot routes are Steam only.** The publisher describes
the v1.4.1 settings fix as working across Steam and Epic installations, but
the Hub does not currently install or track an Epic route.

**Single player only** - do not use it in multiplayer sessions.

## You do not need an RTX card

The settings launcher offers DLSS Quality, Balanced, Performance, Ultra
Performance, DLAA and Custom source sizes. Supported source-size changes can be
applied live; headset/output resolution still requires a restart.

Three anti-aliasing choices are available:

| Choice | Needs | What you get |
|---|---|---|
| NVIDIA DLSS | RTX card | Best picture, and the only one that buys frames back by upscaling |
| Per-eye smoothing | any card | The mod's own pass - keeps each eye's history separate, so no cross-eye ghosting |
| Off | - | The game's own. Sharp, aliased, foliage shimmers |

## Setting it up

Copying the files is only half of it: the mod brings **its own settings program**
at `VR Settings\theHunterCotW VR Settings.exe`. Its complete adjacent
`VR Settings\_internal` runtime must remain in place. **Start in VR in the Hub
opens that program** so you can change options.

If Windows reports that `_internal\python310.dll` cannot be loaded from the
game's main folder, an older root-level copy of the settings program was
started. Use **Start in VR** in the Hub, or open the EXE inside `VR Settings`;
keep its `_internal` folder beside it. If the nested runtime is missing, run
the Hub installer again.

Inside, set these options:

- **Field of View > Field of View given to the game: 90** (the game's maximum).
- **Picture > Anti-aliasing:** try the available settings. If one causes a black
  screen, set it to **Off**; the game will use its own DLSS instead.
- **Head tracking mode: 6-DoF.** This lets you lean and step around.

Then click **Save** and **Launch game**.

**Put the headset on before the game finishes loading.**

## Controls

| Button | Action |
|---|---|
| [[Insert]] | open the settings panel in the headset |
| [[Pause]] | recentre the view - use it whenever forward stops being forward |
| [[Delete]] | show the flat game screen, for menus and the map |
| [[Alt]] held | free look - the view turns, the weapon stays put |
| [[Enter]] / controller [[A]] | apply the selected live picture change |

Everything is rebindable in the panel, and the panel works with a gamepad. A
gamepad plays better here than mouse and keyboard.

## Known issues - all named by the author

- **Experimental Neural Rendering is optional and off by default.** Its separate
  NVIDIA `nvngx_dlssnr.dll` runtime is not bundled. Ordinary DLSS still works
  without it. NR adds GPU cost; it is not frame generation.
- **An unsafe NR/device fault requires a game restart.** Turning NR off does not
  clear that state. Lower NR scales can improve cost but may soften the image.

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

- Try the available *Picture > Anti-aliasing* settings. If one produces the
  black screen, set it to **Off**; the game will use its own DLSS instead.
- Turn HDR off in Windows with **Win + Alt + B**.
- Windows 11: *Settings > System > Display > Use HDR*.
- Windows 10: *Settings > System > Display > Windows HD Color*.

Still black? Check `%LOCALAPPDATA%\theHunterCotWVR\cotwvr.log`.

**Nothing starts at all** - check the menu's compatibility status and the
installed mod version. Version v1.3.1 belongs to the pinned 9.2 route; install
the current publisher release for the September 2026 game update. Future
unconfirmed builds can use the 9.2 depot while awaiting a compatible release.

**Removing the depot** - close the game, confirm that you selected the dedicated
`theHunterCotW VR 9.2` folder, and remove that separate copy after saving any
files you placed in it. Do not remove the normal Steam game or your saves.

**You want the game back to normal** without removing anything - set *VR mod* to
off in the settings program. Every file stays where it is.

The settings program also has an *Open log folder* button.

## Credits

Mod by **Vaas993** - https://github.com/vaas993/theHunterCotW-VR

Includes NVIDIA DLSS, the Khronos OpenXR loader and MinHook. theHunter: Call of
the Wild is a trademark of Expansive Worlds / Avalanche Studios; this mod is
unofficial and not affiliated with them.

Current reviewed release: **v1.4.1**, published 2026-09-28. It follows the
game's own opening of `settings.json` to apply resolution and FOV to the correct
copy, with a 30-second fallback to the earlier method. The `settings_from_game_open`
option in `cotwvr.ini` can revert to the v1.4.0 method. Version v1.4.0 added
September 2026 game support, full-rate and AER fixes, and smooth stick turning
in AER. The depot remains pinned to v1.3.1.

>>> A bad shot in VR still counts. The elk knows.
