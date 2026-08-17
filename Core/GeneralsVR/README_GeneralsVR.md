# Command & Conquer Generals Zero Hour VR

**GeneralsVR** by **Gonzorro** - the original game running natively in a headset.
Not a remake and not a port to another engine.

You stand over the battlefield like a general at a war table: look around the
map, point a laser to select units, give orders with the motion controllers,
build your base, and resize yourself from *the whole war on a table* down to
*standing among the tanks*.

> **Early alpha.** Skirmish plays end to end, but expect rough edges. The author
> wants reports - see the bottom of this page.

## Your game is never touched

Everything lives in its own folder:

    %LOCALAPPDATA%\GeneralsVR

No game file is copied or changed. GeneralsVR just points the engine at your
existing Zero Hour installation. Uninstalling means deleting that folder.

## What you need

- **Your own copy of Zero Hour.** Steam, EA app, Origin, GOG or a retail disc all
  work. The mod contains none of the game's assets, so it does nothing without a
  real installation. Launch the game once normally first.
- **Meta Quest 3 with Quest Link** (cable or Air Link). Set Meta as the active
  OpenXR runtime in the Quest Link app under Settings, General. **Other PC VR
  headsets are untested.**
- A Vulkan-capable gaming PC.

## Two ways to install

**Either way the Hub's installer does the work** - you are only choosing which
file it fetches:

1. **The setup file.** A small `.cmd` that pulls the newest build down as it
   runs. Nothing is extracted.
2. **The full ZIP.** The complete package - the installer unpacks it for you and
   starts it. Same result, just a bigger download.

Either way it asks for administrator rights **once** (to write the registry
entries the engine needs) and puts a **GeneralsVR** shortcut on your desktop. Use
that shortcut from then on.

Windows SmartScreen may warn about an unrecognized app. That is normal for an
unsigned community mod - *More info*, then *Run anyway*.

**The launcher updates itself** to the newest build every time you play. If an
update ever breaks something, press [[V]] in the launcher and pick the previous
version; you stay on it until you switch back.

## The headset stays dark in the menus

That is **not** a fault. Only the battlefield is rendered - start a Skirmish
before you go looking for the picture.

## Controls

The right hand casts a laser and it **is** your reticle: it takes the colour of
whatever would happen if you pulled the trigger now.

| Beam | Meaning |
|---|---|
| Cyan | Nothing selected |
| Green | Move here |
| Red | Attack this |
| Amber | Capture, enter, repair, or a power waiting for a target |
| Violet | Attack move armed - release to send |
| Teal | Guard armed - release to place |

| Action | Control |
|---|---|
| Select | [[Right Trigger]] |
| Select many | Hold [[Right Trigger]] and sweep a box across the ground |
| Select all of a type | Double-tap one of your units |
| Cancel a pending order | [[Left Trigger]] |
| Command dial | Tap [[Left Stick]] - stop, attack move, guard, scatter, idle worker |
| Group dial | Hold [[B]] - your ten control groups |
| Move | [[Left Stick]], relative to where you look |
| Turn | [[Right Stick]] left / right |
| Resize yourself | [[Right Stick]] up to grow, down to shrink - or hold both grips and pull your hands apart |
| Jump to selection | [[Right Stick Click]] |
| Recenter | [[Menu]] on the left controller, short press |
| Summon the HUD panel | [[Y]] left hand, [[B]] right hand |

Mouse and keyboard keep working the whole time and the monitor mirrors
everything. Moving the mouse takes control instantly; squeeze the trigger three
times quickly to hand it back to the lasers.

**Left-handed?** Controls tab, Handedness - it mirrors the whole scheme.

### VR settings

Every in-game menu carries a **[VR]** badge in its top left corner. Click it to
open world scale, smooth motion, input mode, stick speed, left-handed mode,
shadows, sky and audio. Everything is remembered between sessions in
`%LOCALAPPDATA%\GeneralsVR\vr-settings.ini`.

## Known gaps

The author names these openly:

- Attack move from the dial can still behave like a plain move on some targets
- Unit shadows can blink at some head angles - the game's shadow volumes were
  built for one fixed camera. Turn shadows off if it bothers you
- **Do not leave the game paused with the headset off.** If the Quest sleeps
  while the game sits paused, the game can crash

## Reporting a bug

Attach the files from `%LOCALAPPDATA%\GeneralsVR\Debug`, mainly
`DebugLogFile.txt` and `xrhost_log.txt`. They hold no personal data.

## Credits and legal

Mod by **Gonzorro** - https://github.com/Gonzorro/GeneralsVR

This is legal and the author explains why: EA released the game's source under
the **GPL v3** in 2025, and GeneralsVR is a modification of that source published
under the same licence. It builds on **TheSuperHackers/GeneralsGameCode**, uses
**DXVK** to translate the game's DirectX 8 rendering to Vulkan, and the **OpenXR
SDK** to talk to the headset. No EA assets, art, audio or data are distributed -
all of that stays inside your own installation.

>>> Sir, the war table is ready. Mind the tanks near your boots.
