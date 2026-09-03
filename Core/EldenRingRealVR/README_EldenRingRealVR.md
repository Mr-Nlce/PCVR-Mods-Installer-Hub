# Elden Ring VR - Gamepad (R.E.A.L.)

**Stereo VR with the camera on your head, and the game played on a gamepad.** Luke Ross's
R.E.A.L. covers the whole game front to back and is the steady option of the three Elden
Ring VR mods.

> Unofficial. Requires a Patreon membership for the R.E.A.L. build. Not affiliated with
> FromSoftware or Bandai Namco.

## Which Elden Ring VR mod do you want?

| | Controls | Where it lives |
|---|---|---|
| **R.E.A.L.** (this one) | Gamepad | in the game folder |
| **Hotbite** | Motion controls | its own folder, game untouched |
| **Ilya's ERVR** | Motion controls | in the game folder |

The two motion mods are on the separate **Elden Ring VR (Motion Controls)** tile.

> **R.E.A.L. and ERVR cannot both be installed.** Both use `dxgi.dll` in the game folder -
> ERVR's author says so himself. The installer blocks this collision; each tile has an
> uninstaller, so switching is a matter of removing one first.
>
> **Hotbite is fine alongside either.** It never writes into the game folder at all.

## What the installer does

It first asks for **Current Steam version** or the separate **1.16.2 depot copy**. It then
hands that exact path to the shared Luke Ross installer. Afterwards the Hub writes a
build-specific launcher, so Current and Depot can both be detected and launched.

## Requirements

- **Elden Ring on Steam.**
- **A Patreon membership** with Luke Ross for the R.E.A.L. build.
- **A PC VR headset** and a gamepad.
- **Play offline with Easy Anti-Cheat disabled.** Never launch a modded Elden Ring online.

## Current version or pinned depot

Patch 1.17 currently breaks the Elden Ring VR mods. The installer therefore recommends
the pinned **1.16.2 (build 22984413)** depots. They are merged into
`C:\Games\Elden Ring VR`; the live Steam copy is not overwritten, downgraded or deleted.
Choose Current only after the R.E.A.L. build supports the current game patch.

## Uninstall

The tile has an uninstaller. It removes `dxgi.dll`, `RealVR64.dll`, `openvr_api.dll`,
`cudart64_12.dll`, `RealVR.ini` and the `RealRepo` folder from your game folder, and leaves
your saves and the motion mods alone.

**One exception worth knowing:** if ERVR is also installed, `dxgi.dll` is left in place -
it may be ERVR's copy, and deleting it would break the mod you did not ask to remove.

## Credits

**Luke Ross** builds R.E.A.L. for a long list of games. If you enjoy it, his Patreon is
where the work is funded.
