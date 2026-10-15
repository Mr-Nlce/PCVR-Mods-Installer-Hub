# Outlast VR

## About the Game

Outlast (2013) is a first-person survival horror game. This page offers a
gamepad VR mod by Halcyon and a motion-control VR mod by T-Diamond. The Hub
keeps their overlapping runtime files in separate stores and switches them
when you choose the corresponding Play action.

## Two mods, one page

There are two Outlast VR mods with different controls. The
installer offers either, or both.

| | **Halcyon** | **Insanity Engine VR** |
|---|---|---|
| **Controls** | **gamepad only** | **tracked VR controllers + VR hands** |
| State | gamepad-focused option | **early beta, prerelease updates** |
| Camcorder | raised with a button | held and aimed with your hand |
| Night vision | button | use the camcorder; v0.1.1 fixes its grip behavior |
| Movement | gamepad sticks | room-scale 6DoF and motion controllers |
| How it works | a `d3d9.dll` next to the game exe | a different `d3d9.dll` in the same folder |
| Active files | four files | six runtime and setup files |
| Where to get it | Patreon | GitHub, free |

**This is why the tile shows both a gamepad and a controller icon.** Which one
you actually play with depends on the mod you install - the entry is not
gamepad-only any more, and it is not motion-controls-only either.

### Insanity Engine VR controls

| Button | Action |
|---|---|
| [[Right Grip]] | Hold and aim the camcorder. |
| [[X]] | Pick up the nearest item within 1.5 m. |
| [[F10]] | Open the mod settings menu on the monitor. |
| [[G]] | Recenter the view. |

Some story prompts appear only while crouched. Door interactions and physical
holsters are still being developed. The current README notes that the
camcorder/night-vision path is a work in progress even after the v0.1.1 fix.

**Close Outlast before switching.** Both mods now use `d3d9.dll`,
`openxr_loader.dll` and `outlastvr.ini` in `Binaries\Win64`. The installer
keeps separate copies under `_vrmods\halcyon` and `_vrmods\insanity`.
Use **Start in VR** for the chosen mod in the Hub. It saves the active config,
verifies and copies the chosen mod, then starts the game. A failed switch
restores the previous files and does not start Outlast. Each mod also keeps a
separate copy of Outlast's four Documents INIs under its own `GameConfig`
folder. Switching restores the
chosen profile; Insanity's door calibration and mod INI are kept as well. With
both installed, the Hub shows both Play buttons.

### Insanity Engine VR installation and updates

The installer resolves the newest installable GitHub release, including
prereleases; it excludes the `-source.zip` attachment. It copies the six
required files to its parked store and activates them under `Binaries\Win64`.
The publisher's `Outlast-VR.bat` then asks for your headset refresh rate and
backs up the game's Documents configuration. Run Outlast normally once before
installing. Do not turn off Depth of Field: the mod needs it for night vision.
Start your OpenXR runtime first, then use **Start in VR** in the Hub. Steam
installs use Steam's game launch route; other stores have not been publisher
tested. The mod needs a Vulkan-capable GPU.

If you installed Hammerthis through an older Hub, choosing Insanity Engine VR
replaces that motion-control route. After the new setup succeeds, the Hub
removes its known old binaries and old launcher. It keeps the old personal
`outlastvr.ini` and any unrecognized files under `_vrmods\Hammerthis`, so you
can retrieve them. The new mod uses its own INI format; do not reuse the old
one blindly. Halcyon's parked files remain available.

The official mod is still a beta. The publisher reports that headset hand
tracking may need adjustment in the [[F10]] menu. Current known issues include
a slightly visible night-vision light, an off-centre HUD dot, no VR pickup
prompts, and body-relative left/right aiming. Steam with Meta Quest via Quest
Link or Virtual Desktop is tested; GOG, Epic and SteamVR headsets are not.

[Insanity Engine VR releases](https://github.com/TdiamondOf/InsanityEngineVR/releases)

---

## The Halcyon mod

**Everything from here on describes Halcyon's mod only** - the download, the
installation, the in-game settings and the known issues. Insanity Engine VR is
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

The tool is **TFC Installer for UE2-UE3 2.5.6.0**
(https://www.nexusmods.com/site/mods/588). This release includes a nested
instruction-depth guard that prevents malformed script bytecode from causing
stack-overflow crashes.
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

For Insanity Engine VR, use **Uninstall now** on this page. The Hub activates
that mod, opens its publisher setup after you press Enter, and asks you to
choose **[2] Uninstall**. The publisher restores the original Documents game
settings and removes its game-folder files. The Hub then removes its parked
runtime and reactivates Halcyon if installed. Personal settings remain saved.

To remove Halcyon, activate it and run its `Outlast-VR.bat` from
`Binaries\Win64`, then choose **[2] Uninstall**.

## Credits

Mod by **Halcyon** - https://www.patreon.com/dhalcyon

Insanity Engine VR by **T-Diamond** - https://github.com/TdiamondOf/InsanityEngineVR

An unofficial fan project, not affiliated with Red Barrels.

>>> You are not armed. You never were. Now you can look behind you.
