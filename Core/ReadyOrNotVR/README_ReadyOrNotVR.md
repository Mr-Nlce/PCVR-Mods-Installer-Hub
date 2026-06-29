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
- A **VR runtime** running before launch: Meta Quest Link or SteamVR.
- The **VRO Mod** `pakchunk98-VR_OR_NOT_P.zip` from Nexus Mods:
  https://www.nexusmods.com/readyornot/mods/6914
- Recommended: **DLSS Swapper** (NVIDIA GPUs) -
  https://github.com/beeradmoore/dlss-swapper/releases

## What the installer does

1. Auto-detects your Steam **Ready Or Not** folder (or you drag it /
   `ReadyOrNot.exe` in).
2. Opens the Nexus mod page so you can download
   `pakchunk98-VR_OR_NOT_P.zip` (Manual download).
3. You drag that `.zip` (or the extracted `.pak`) onto the window; the
   installer copies `pakchunk98-VR_OR_NOT_P.pak` into
   `ReadyOrNot\Content\Paks`.
4. Shows the exact **Steam launch options** to set.
5. Offers to open **DLSS Swapper** and prints the recommended in-game
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
  the game; launch from the **Steam library**; set the correct default
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
