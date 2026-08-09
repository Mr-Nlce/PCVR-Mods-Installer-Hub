# Ready Or Not VR

Layers the free **Ready Or Not VRO Mod** by **Virtual Reality Oasis &
KITT** onto an existing, working Steam copy of **Ready Or Not** that
**you provide**. No game files are bundled. The mod is hosted on Nexus
Mods behind a free login, so you download one file and drag it into the
installer, which drops the VR `.pak` into the game's `Paks` folder.

## Important - read first

- You need an **already-installed, owned Steam copy of Ready Or Not**
  (Steam app **1144200**).
- The mod is a **Nexus Mods** download and needs a **free Nexus login**,
  so it cannot be fetched automatically.
- Ready Or Not is **very performance-intensive in VR**. Plan to run
  **DirectX 11**, a modern **DLSS**, and a **Medium** preset to start.
- You play in a **flat-then-VR** flow: launch flat from Steam, pick your
  loadout and mission, then press **U** to drop into VR.

## Requirements

- A working, owned **Ready Or Not** on Steam.
- A **VR runtime** running: Meta Quest Link or SteamVR. Launch it before the game to avoid it potentially starting sometimes out of focus.
- The **VRO Mod** `pakchunk98-VR_OR_NOT_P.zip` from Nexus Mods:
  https://www.nexusmods.com/readyornot/mods/6914
- Recommended: **DLSS Swapper** (NVIDIA GPUs) -
  https://github.com/beeradmoore/dlss-swapper/releases

## Two places it can go

The installer asks this first, and both routes end with the same VR mod:

| | Where the game lives | How it starts |
|---|---|---|
| **[1] Your Steam copy** | Your existing Steam install | Through Steam, with launch options |
| **[2] Pinned depot build** | `C:\Games\Ready or Not VR` | Desktop shortcut, or **Start Depot** in the Hub |

Route 2 pulls one exact version of the game straight from Steam with a
`download_depot` command - you still need to own the game, no game files
come from us. That build is **pinned**, so a game patch cannot break the
mod, and your normal Steam copy is left completely alone. Both can exist
side by side; with both installed the Hub tile gets a 3-way split button.

The one thing to know about route 2: the game then sits outside the Steam
library, so Steam's launch-options field and its DirectX dropdown do not
reach it. Everything rides on the desktop shortcut instead - the installer
puts it there for you.

## Which Nexus file you need

The Files page lists more than one, and only this one matches the build
the installer sets up:

    Version    1031
    Uploaded   15 June 2026
    Size       281.9 MB

Use **Manual download**. Nexus appends its own numbers to the file name, so
what lands in your Downloads folder looks like
`pakchunk98-VR_OR_NOT_P ... .zip` - the trailing numbers differ for everyone.
The installer therefore identifies the file by its **size and contents**, not
by its name: it checks your Downloads and Desktop folders, verifies that the
archive really holds `pakchunk98-VR_OR_NOT_P.pak`, and only then offers it.

## What the installer does

1. Asks which of the two routes you want. For route 1 it auto-detects your
   Steam **Ready Or Not** folder (or you drag it / `ReadyOrNot.exe` in);
   for route 2 it walks you through the depot download and moves the build
   to `C:\Games\Ready or Not VR`.
2. Opens the Nexus mod page so you can download
   `pakchunk98-VR_OR_NOT_P.zip` (Manual download).
3. You drag that `.zip` (or the extracted `.pak`) onto the window; the
   installer copies `pakchunk98-VR_OR_NOT_P.pak` into
   `ReadyOrNot\Content\Paks`.
4. Route 1: shows the exact **Steam launch options** to set.
   Route 2: creates the **Ready or Not VR** desktop shortcut with those
   options plus `-dx11` already on it.
5. Offers to fetch **DLSS Swapper** - always the newest release, resolved
   from GitHub at install time, not a version baked into the Hub - and
   prints the recommended in-game
   settings.

## Steam launch options (required)

In Steam: right-click **Ready Or Not** -> **Properties** -> **General**.
Set the launch-option dropdown to **DirectX 11**, then paste into the
Launch Options field (copy-paste, do not type):

    -usehmd -VRTweaks -VRMappings

Optional: add `-autoVR` to boot into VR ~3 seconds after a mission loads
(so you don't have to press **U**).

> A stray space (like `- usehmd`) stops VR from starting - always
> copy-paste the options.

**On the depot build there is no Steam field for this.** The shortcut the
installer creates carries the options itself:

    -dx11 -usehmd -VRTweaks -VRMappings

`-dx11` is what Steam's DirectX 11 entry does for this game, and it has to
be passed by hand here because that dropdown only exists inside Steam. If
you picked automatic VR entry during install, the shortcut gets `-autoVR`
as well - note that the Hub's **Start Depot** button always uses the plain
set above, so VR there comes with the **U** key.

## DLSS Swapper and the depot build

DLSS Swapper finds games through the Steam library, so it does **not** list
the depot build - that copy lives outside it. Add it once by hand: in DLSS
Swapper, top right, **Add game**, then pick your install folder
(`C:\Games\Ready or Not VR`, or wherever you put it). After that it behaves
like any other entry.

Then on the Ready Or Not tile: pick **v310.4 or newer** as the DLSS version
and set the **DLSS Preset to Preset J**.

## How to play (order matters)

1. Start your **VR runtime first** (Meta Quest Link or SteamVR).
2. Launch **Ready Or Not from Steam** in flat mode - not a desktop
   shortcut, not the in-VR dashboard, not the DLSS-Swapper menu.
3. Pick your loadout and mission in flat mode.
4. Once the mission has loaded, press **U** to enter VR. The game window
   must be **focused** for controllers to be detected (click it once if
   your hands don't respond).
5. Press **Home** to exit VR manually (then restart the mission).

## Loadout (body-anchored)

- **Main weapon:** over the **right shoulder**
- **Long tactical** (Optiwand, Ram, Shield, Grenade Launcher): over the
  **left shoulder**
- **Pistol:** **right hip / thigh**
- **Tablet** (objectives + VR settings): **left hip**
- **Taser:** under the **left arm**
- **Taser cartridge:** under the **right arm**
- **Accessory pouch:** **lower back**. With a multitool held, use
  **alt-fire mode** to switch between lock pick and wire cutters - wire
  cutters snip door-wired traps; a lock pick in a lock starts the
  lockpicking sequence.

## Hand gestures for squad commands

Move your hand fairly quickly for these to register:

- **Hold position:** [[Left Hand]] make a fist and hold
- **On me:** [[Left Hand]] up, index finger pointing, make a circle
- **Search the area:** [[Left Hand]] down, index finger pointing, make a
  circle
- **Default command:** [[Left Hand]] up flat, chopping motion

## Controls (notes)

- **Enter VR:** [[U]] (keyboard) once the mission has loaded
- **Exit VR:** [[Home]] (keyboard) - restart the mission afterwards
- **Multitool toggle:** alt-fire to switch lock pick / wire cutters
- Left-handed (dominant) support and its customisations were added in the
  June update; a fully polished left-hand-dominant mode is still in
  progress.

## Known issues & fixes

- **Black screen / missing textures:** make sure the game is on **DX11**;
  try removing `-AAMode1`; restart the PC; try adding `-d3d11`.
- **Crash on launch:** conflicts with other mods - remove some. Add a
  **Windows Defender exclusion** for the Ready Or Not folder (it can
  silently block the mod). Disable the OpenXR-Companion app if present.
  If you used **UEVR** before, it replaced files - do a full game
  reinstall (delete the game folder after uninstalling).
- **Hands show but buttons/grabbing/walking don't work:** the game lost
  focus - click the window once. Or you missed the `-VRMappings` param.
- **Shots don't go where you aim:** disable **Aim Assist** and restart;
  if already off, toggle it on and off again.
- **Stutter / camera jitter:** disable Discord and other overlays, drop
  settings, turn off OpenXR Toolkit, install a modern DLSS via DLSS
  Swapper (or try without DLSS), try `-AAMode0`, and confirm your default
  OpenXR runtime.
- **Press U, view changes flat but nothing in headset:** check the launch
  params (copy-paste, no stray spaces); start the VR runtime **before**
  the game; launch with **Start in VR** in the Hub or from the **Steam library**; set the correct default
  OpenXR runtime. If Steam doesn't pass the params, make a shortcut to
  `steamapps\common\Ready Or Not\ReadyOrNot.exe` with the params in the
  Target.
- **Spinning like crazy:** you pressed **U** multiple times - don't.
- **Virtual Desktop black bar between the eyes:** set Horizontal and
  Vertical FOV in advanced streamer settings to between **95 and 100**.
- **In VR but no hands (often Virtual Desktop):** click the Menu/Meta
  button a few times, suspend/resume the headset, and confirm the default
  OpenXR runtime.
- **Multiplayer with mixed VR runtimes crashes / checksum error:** use
  the **same runtime** for everyone (VD + Meta in one session mismatches).

Other rough edges the authors note: hands/gun can vanish while cuffing or
healing, occasional false melee hits, possible clipping through walls or
the map, the 6-shot launcher can jam if loaded from the bottom round
(cycle the chamber to reset), doorwedge and C2 are not implemented yet,
the laser drifts under magnified ADS, and some stairs need a
crouch-uncrouch to climb. Multiplayer is rough - treat it as a bonus.

## Support

Troubleshooting and feedback: https://discord.gg/7wHGztfgjM

Mod page: https://www.nexusmods.com/readyornot/mods/6914
