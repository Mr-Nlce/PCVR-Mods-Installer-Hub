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
| the mod | `C:\Users\<you>\AppData\Roaming\pokemon-love2d\mods\DRAMALESS_SHAPE` |

The second path is **fixed by the mod platform**, not by this Hub: the
port's mod loader scans `mods` through LÖVE's own filesystem, which is the
per-user save directory. A `mods` folder next to the exe is not on its read
path, and `portable.txt` does not move it either. This is the only entry in
this Hub that writes outside the game folder, and it is listed here so you
always know where it went.

## Versions
The installer offers two routes:

1. **Newest release of both** - it resolves the latest port and mod release
   from GitHub each time you run it.
2. **Pinned pair** - port `v0.1.60` with mod `v1.5.4`, a combination
   verified together.

They have to match: the mod's own manifest requires the port to be `0.1.37`
or newer. If a port update ever breaks the mod, re-run the installer and
take the pinned pair.

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

## Uninstall
Delete the game folder, and delete the mod folder:

    C:\Users\<you>\AppData\Roaming\pokemon-love2d\mods\DRAMALESS_SHAPE

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
