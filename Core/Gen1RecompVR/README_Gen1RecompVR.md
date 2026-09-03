# Pokemon Gen 1 VR Installer

Automated installer for two things that belong together:

- **Gen1Recomp** by bryanthaboi - a native LÖVE2D recreation of the Gen 1
  games. It is not an emulator and ships no game data.
- **Dramaless Shape Voxel Mod** by artyrambles - the overworld as a
  voxelized 3D diorama, with experimental first-person and **PCVR**.

VR is a row in the game's own OPTIONS menu (**VR: OFF / ON**), not a
separate launch mode. It drives a PCVR headset through OpenXR on Windows -
SteamVR, Oculus or WMR. Standalone headsets are not supported.

## You provide the ROM
Nothing from Nintendo is included or downloaded. On first launch the game
asks for a **canonical US Red, Blue or Yellow `.gb` / `.gbc` ROM** you own,
verifies its SHA-1, builds its own private data, and then releases the ROM -
it is never copied into the cache. Later launches do not ask again.

## Two install locations - one of them is not the game folder
| what | where |
|---|---|
| the port | `C:\Games\Pokemon Gen 1 VR` (you can pick another root) |
| Dramatic Shape (when selected) | `%APPDATA%\pokemon-love2d\mods\DRAMATIC_SHAPE\` |
| Dramaless (when selected) | `%APPDATA%\pokemon-love2d\mods\DRAMALESS_SHAPE\` |
| inactive mod | `%APPDATA%\pokemon-love2d\mods-disabled\` |

The mod paths are **fixed by the mod platform**, not by this Hub: the
port's mod loader scans `mods` through LÖVE's own filesystem, which is the
per-user save directory. A `mods` folder next to the exe is not on its read
path, and `portable.txt` does not move it either. These mods live outside
the game folder; `%APPDATA%` points to your own Windows roaming profile.

## Two mods to choose from - and why

Two mods draw this game as a 3D voxel world. **Both still have VR**, and the
installer lets you pick. Only one can be active at a time.

**1. Dramatic Shape `v1.8.2` - the original, with everything in it.**
Built-in first person, the battle and Stadium features, VR. This is the fullest
version there is. It comes from a **mirror**, because the original repository may
not stay up - so it is pinned to `v1.8.2` and never auto-updates.

**2. Dramaless `v1.6.4` - the slimmed-down fork.**
Still has VR, but its author kept removing things. First person and the battle
features are among what went.

> **Do not take a newer Dramaless.** In `2.0.0` the author removed VR **entirely**
> - his own words: he has no headset to test and debug with. The OpenXR loader is
> not shipped any more and the four VR source files went with it. The Hub
> deliberately offers neither an update nor that version.

Both need the port below `2.0.0`, so the port stays pinned at `v0.1.81` either
way - the newest one that is still below that line.

### Only one may be active
Both mods install under `%APPDATA%\pokemon-love2d\mods\` with their own id - `DRAMATIC_SHAPE`
and `DRAMALESS_SHAPE` - and their manifests list each other as conflicting. If
both are there, neither loads properly.

Renaming the folder is **not** enough: the loader goes by the `manifest.json`
inside it, not by the folder name. So the installer **moves the other one right
out of the active mods directory** into `%APPDATA%\pokemon-love2d\mods-disabled\`. Nothing is deleted - switch
back any time by running the installer again and picking the other one.

## If Windows Defender eats the download
Defender's machine-learning heuristic sometimes flags the port with a
generic detection. This is a **documented false positive**: the exe is the
official LÖVE runtime with the game archive appended, which is how LÖVE
games normally ship, and unsigned executables built that way trip the
heuristic.

Both projects publish a `sha256sums.txt` next to their release files, and
the installer **checks every download against it**. If a hash does not
match, the archive is thrown away and fetched again instead of being
unpacked. Releases without a checksum list are simply installed without that
step, and the installer says so.

The installer also checks a few seconds after each extraction whether all
files are still there, because Defender removes them asynchronously. If something
is missing it explains the situation, opens the exclusion settings, waits
for you, and then unpacks again. If the ZIP disappears before that, the same
happens for your Downloads folder and the download is repeated.

## VR controls
Suggested onto Touch, Index and WMR controllers and rebindable in your
runtime's own binding UI. Pad, keyboard and mouse keep working alongside.

- [[Left Stick]] move - grid-walks the diorama, free-walks in first person
- [[A]] / [[B]] (X / Y on the left hand) the A and B buttons
- [[Trigger]] either one acts as START
- [[Left Stick Click]] step the VOXEL angle ladder (same as the `3` key)
- [[Right Stick]] up / down - zoom the model (diorama only)
- [[Right Stick]] left / right - snap-turn 45° in first person
- [[Grip]] squeeze and raise or lower that hand - drag the table's height
- **Head:** look around in first person and battles; FreeMove walks where
  you look
- **Left hand:** your Pokédex - menus, dialogs and the 2D battle screen
  live on its screen

**SMOOTH TURN** appears under the VR row while VR is on. It is off by
default on purpose: a software turn moves the world past a head that did not
move, which is the most reliable way to make somebody ill in a headset.

## Options rows worth knowing
- **VOXEL** (`3`): OFF → 15 → 35 → 50 → 75 → 1ST → OFF, the camera pitch
- **3D-BTL** (`8`): fight on the map instead of on a white field
- **WATER** (`9`): FULL / SKY / OFF - reflections on water
- **AA**: OFF / 2X / 4X, the most expensive row in the mod, off by default
- **DAYTIME**: SYNC / DAY / NIGHT / DUSK / DAWN / CYCLE
- **PERFORMANCE** (the port's own row): AUTO by default, scales the extras
  for weaker hardware without touching the game logic

## Playing
Start SteamVR (or your runtime) first, then launch with **Start in VR** in
the Hub or the **Pokemon Gen 1 VR** desktop shortcut.

Two places to set things:

- **Launcher window** (the one with *Import ROM* on the left): the gear icon
  at the top opens its settings - **Colors: SGB → ADVANCED**, **Max FPS 120**.
- **In-game OPTIONS menu**: press down a few times, then the **VOXEL** and
  **VR** rows appear. VR → ON.

## A word on sources
The project warns about a lookalike website that it does not run. Only the
GitHub repositories below and the project's own Discord are official, and
this installer downloads from GitHub only.

https://github.com/bryanthaboi/gen1recomp

https://github.com/artyrambles/DRAMALESS_SHAPE

## Licenses
The mod redistributes the Khronos OpenXR loader (Apache 2.0) as
`assets/vr/openxr_loader.dll` with its license text alongside it. Keep the
two files together.
