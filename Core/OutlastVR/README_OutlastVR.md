# Outlast VR

## Two mods, one page

There are two Outlast VR mods with different controls. The
installer offers either, or both.

| | **Halcyon** | **Hammerthis** |
|---|---|---|
| **Controls** | **gamepad only** | **tracked VR controllers + VR hands** |
| State | gamepad-focused option | **v1.0 drop-in** |
| Camcorder | raised with a button | reach out, grab it, raise it yourself |
| Night vision | button | R3 while holding the camcorder |
| Movement | gamepad sticks | left stick; click it while moving to sprint |
| How it works | a `d3d9.dll` next to the game exe | a different `d3d9.dll` in the same folder |
| Active files | four files | loaders, config and the body texture |
| Where to get it | Patreon | GitHub, free |

**This is why the tile shows both a gamepad and a controller icon.** Which one
you actually play with depends on the mod you install - the entry is not
gamepad-only any more, and it is not motion-controls-only either.

### Hammerthis controls in detail
- [[Left Stick]] move
- [[Left Stick Click]] while moving: sprint
- [[Right Stick]] horizontal only - turning. Vertical is suppressed, because
  pitch follows your head.
- [[A]] / [[B]] / [[X]] / [[Y]] and the triggers behave like Outlast's normal
  gamepad buttons
- **Grab the camcorder** with your hand and raise it to your face
- [[R3]] while the camcorder is up: Outlast's own night vision

Motion interactions with doors and pickups are in, but experimental.

**Close Outlast before switching.** Both mods now use `d3d9.dll`,
`openxr_loader.dll` and `outlastvr.ini` in `Binaries\Win64`. The installer
keeps separate copies under `_vrmods\halcyon` and `_vrmods\hammerthis`.
Launchers in `_vrmods\VRLaunch` save the active config, verify and copy the
chosen mod, then start the game. A failed switch restores the previous files
and does not start Outlast. With both installed, the Hub shows both Play buttons.

### Hammerthis, in short
Version 1.0 needs no injector or author-provided launcher. A Hammerthis-only
installation is activated immediately. Use the Hub or
`_vrmods\VRLaunch\Outlast VR (Hammerthis).bat` to play.
Its extra files are `openxr_loader_real.dll` and
`assets\miles\body_albedo.tga` below `Binaries\Win64`.

If upgrading from the old injector release, its files are retained in the
Hammerthis folder. `RESTORE_OUTLAST_SETTINGS.bat` belongs to that old release
and can undo its graphics changes; it is not required by the new drop-in mod.

Expect rough edges: props and documents can vanish at some angles
because Outlast's UE3 visibility system was built for a flat screen, shadows
can shift with head movement, and the framerate can drop.

---

## The Halcyon mod

**Everything from here on describes Halcyon's mod only** - the download, the
installation, the in-game settings and the known issues. Hammerthis' mod is
covered above and installs entirely through the Hub.

Stereoscopic VR with full head tracking for **Outlast**, by **Halcyon**. Cutscenes
play in VR too. You play with a **gamepad** - this is not a motion-control mod.

## Before you install

**Run Outlast once normally first.** The game creates its settings files on that
first launch, and the mod's own installer needs them to be there.

## Where the files go

Inside the game folder, two levels down in `Binaries\Win64`:

    ...\Outlast\Binaries\Win64\

That is where `OLGame.exe` lives, and all four mod files sit next to it. Steam,
GOG and Epic all use the same layout, just in different places:

- **Steam** - `steamapps\common\Outlast`
- **GOG** - `C:\GOG Games\Outlast`, or under GOG Galaxy's `Games\`
- **Epic** - `Epic Games\Outlast`

The Hub knows all of them and finds the game in each.

## The download

The mod is published as a Patreon post, but the **file link itself is public** -
no account needed. The installer fetches it directly; if the ZIP is already in
your Downloads it uses that instead.

After the files are in place the installer runs `Binaries\Win64\Outlast-VR.bat`
from that `Binaries\Win64` folder, which does the actual setup and adjusts Outlast's config
under your Documents folder.

## In the game

Press [[Insert]] to open the menu, then the **VR** tab. Tune **Eye Separation**
and **Convergence** until it sits right for you - those two are personal, there is
no correct value.

Turn **motion blur off** in Outlast's own settings.

### Optional: depth of field

You can switch depth of field off in
`Documents\My Games\Outlast\OLGame\Config\OLSystemSettings.ini` - find
`DepthOfField=True` under `[SystemSettings]` and set it to `False`.

> **This also turns off the game's colour grading.** That is not a bug: in this
> engine the two are tied together. The author says so himself.

## Known issues

The author names these openly:

- Light flares can pass through walls. Harmless, not fixed yet, and safe to
  ignore.
- Outlast has **film grain baked in**. That is the game, not the mod - see below.

## Optional: removing the film grain

The grain is part of Outlast itself. A Nexus mod removes it without touching the
other post-processing:

    https://www.nexusmods.com/outlast/mods/65

The Hub's installer fetches it and unpacks it into `_FilmGrainMod` beside your
game - but **copying those files does nothing.** They are not game files: it is a
UE3 texture pack (a `GameProfile.xml` plus a `.TFCMapping` and the mip data), and
a tool has to patch it into Outlast's own `.upk` packages.

### The Hub does this for you

The installer fetches the tool as well, unpacks it beside the mod folder and
**starts it** - with both paths on your clipboard, game folder first. You only
click three things:

1. **Game folder** - click the button, paste into the lower text field, then
   **Select Folder**. It is the Outlast folder, not `Binaries\Win64`
2. **Mod folder** - same button routine, same lower text field. It is
   `_FilmGrainMod`, the one holding `GameProfile.xml`
3. **Update Outlast + DLCs** - it simply skips the DLCs if you do not have them

The tool is **TFC Installer for UE2-UE3** (https://www.nexusmods.com/site/mods/588).
It **backs your original packages up inside the game folder** before it changes
anything, and *Restore Backup* / *Uninstall all* puts them back - so this is
reversible.

### If the tool does not open

It needs the **.NET Desktop Runtime 6**, which the tool names in its own
requirements. Without it the window simply never appears - no error, nothing.

The installer asks whether the tool opened. Answer **I** and it downloads and
installs the runtime for you (Windows asks for administrator rights), then starts
the tool again.

By hand: https://aka.ms/dotnet/6.0/windowsdesktop-runtime-win-x64.exe

## Uninstalling

Run `Outlast-VR.bat` again from `Binaries\Win64` and choose **[2] Uninstall**.
That is the author's own route and it restores the game config. By hand, delete
`d3d9.dll`, `openxr_loader.dll`, `outlastvr.ini` and `Outlast-VR.bat` from that
folder - no base game file is touched.

## Credits

Mod by **Halcyon** - https://www.patreon.com/dhalcyon

An unofficial fan project, not affiliated with Red Barrels.

>>> You are not armed. You never were. Now you can look behind you.
