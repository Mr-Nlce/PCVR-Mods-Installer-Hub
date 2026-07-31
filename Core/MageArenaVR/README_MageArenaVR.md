# Mage Arena VR - MA VR

**MA VR** by **J_axon** - full room-scale VR for Mage Arena. Head and hand tracking, a real body you can look down at, motion controls, look-based aiming, and networking that lets VR and flatscreen players see each other move properly.

> **Beta.** Stable and playable, not finished. It is client-side only - your friends do not need it, and a lobby with one VR player and five flatscreen players works fine.

## What it does
- Room-scale head and hand tracking with a real in-game body, not floating hands
- Arms solved to your controllers with two-bone IK, hands measured to the knuckle
- Health and stamina ride your left wrist
- Game menus become world-space panels you point at with a laser from your right hand
- Cheap stand-ins for effects that were built out of volumetric fog, so a Dark Blast is never an invisible instant-kill lane

## Requirements
- **Mage Arena on Steam**
- **SteamVR - running before you launch the game.** Not optional: the mod renders through the OpenVR runtime and the OpenVR compositor **is** SteamVR. Without it the mod loads, logs the failure and leaves you on the desktop.
- A PC VR headset. Developed on a Quest 3 over Virtual Desktop; anything SteamVR drives should work - Quest over Link, Air Link, Steam Link or Virtual Desktop, Index, Vive, Pico, WMR through SteamVR.
- **BepInEx 5** - the installer places it for you. BepInEx 6 will **not** work: the mod ships a preloader patcher, and BepInEx 6 is a different architecture that cannot load it.

## Why OpenVR and not OpenXR
Mage Arena was not built with VR support. In Unity, OpenXR is an XR plugin that the engine wires in at startup, before any mod code runs - adding one to a shipped non-VR game means writing a manifest into the game's data folder, deploying loader DLLs beside the engine's own natives, and persuading Unity to initialise a display subsystem the build was never compiled to expect. The modder tried that route early on and it was fragile.

OpenVR needs none of it. `openvr_api.dll` is an ordinary native library the mod calls from a normal plugin, rendering each eye itself and handing the result to the SteamVR compositor. Nothing touches Unity's startup path. That control is what lets the mod fix per-eye lighting and hand every override back to the game when you leave a match.

The trade is the one already stated: SteamVR has to be running.

## VR or flatscreen, every launch
A dialog appears before the game draws anything:

- **Yes** - Virtual Reality
- **No** - Flatscreen companion mode

Flatscreen mode is not "the mod off". It changes nothing about how you play, but you see VR players move for real - driven by their actual tracking instead of walk-cycle animations - and you get tagged as a flatscreen player so VR players can tell at a glance.

Set `ForcedMode` to `VR` or `Flat` in the config to skip the dialog.

## Controls (motion controllers)
| Input | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Left Stick Click]] | Sprint (hold) |
| [[Right Stick]] left/right | Turn - snap or smooth |
| [[Right Stick Click]] | Crouch (toggle) |
| [[Right Trigger]] | Use item / attack |
| [[Left Trigger]] | Secondary / aim |
| [[A]] | Jump |
| [[B]] | Interact |
| [[X]] | Cycle inventory |
| [[Y]] | Pause / Escape |
| [[Left Grip]] | Map (hold) |
| [[Right Grip]] + [[Right Trigger]] | Drop held item |
| [[Right Grip]] + [[Right Stick]] | Flip spell book pages |
| [[Both Grips]] hold ~0.4s | Recall |
| [[F1]] or [[Both Stick Clicks]] | VR settings panel |
| [[F8]] | Re-calibrate height and arm reach |

Some combinations suppress each other on purpose - gripping to drop never also swings what you are holding, and holding both grips for recall cannot fire map or drop by accident.

Everything maps to whatever key is currently bound in the game's own settings, so rebinding jump or interact in-game carries over.

**Calibration:** the mod measures your height and arm reach automatically about 15 seconds after you enter a game. Press [[F8]] to re-run it - stand naturally with your arms out and let it settle.

## The F1 settings panel
Press [[F1]] or click both thumbsticks. The panel floats in front of you, works anywhere (menu, lobby, mid-match), and applies changes immediately. Point at it with the laser and click a row to cycle it.

| Setting | Notes |
|---|---|
| Turning | Snap (default, gentler on the stomach) or Smooth |
| Snap angle | 15-90 deg, default 45 deg |
| Smooth speed | 60-240 deg/s, default 120 |
| Shadow distance | 40-250 m. Shorter is **sharper**, not cheaper - same pixels over less ground |
| Desktop mirror | On by default; off saves a little performance |
| Volumetric clouds | On by default; the second biggest performance win when off |
| Cameras in match | **Two** (better visuals) or **One** (faster) |

**Cameras in match is the biggest performance lever in the mod.** Two gives each eye its own camera, which is what makes volumetric clouds render correctly and water resolve in both eyes. One renders the game's camera twice and is meaningfully cheaper, at the cost of a moving black grid in the clouds and water looking right in only one eye. If you are short on frames, try this before anything else.

## Performance and sharpness
The mod renders at **85%** of your headset's requested resolution by default (`EyeResolutionScale`). That is about 72% of the pixels, and every pixel is paid for twice because the scene renders once per eye. If you have headroom, set it to `1.0` in the config for a clear step up in clarity - it is config-only, because rebuilding the eye textures mid-session is a good way to get a black screen.

If sharpness matters more than frames, the order to try is: `EyeResolutionScale` to 1.0, then volumetric clouds off to pay for it, then One camera if you need more.

## Configuration
`BepInEx/config/com.jaxon.magearenavr.cfg`, generated on first launch. Every setting is documented in the file itself.

| Setting | Default | What it does |
|---|---|---|
| `ForcedMode` | Ask | `Ask`, `VR` or `Flat` |
| `EyeResolutionScale` | 0.85 | Render resolution per eye |
| `PlayerHeightOffset` | 1.2 | Raise or lower your viewpoint |
| `InteractRange` | 6 | How far you can interact |
| `TorchLightMultiplier` | 2 | Torch brightness |
| `WristHUDScale` | 2 | Size of the wrist health display |

> **After a mod update, delete the config.** BepInEx never overwrites an existing config file, so values saved by an older version silently override new defaults. Delete `com.jaxon.magearenavr.cfg` and relaunch - a fresh one is written immediately.

## Multiplayer
The mod is client-side and unmodded players are never sent any of its data, so a mixed lobby behaves exactly like vanilla for them.

| You are... | You see a VR player as... |
|---|---|
| VR (this mod) | Their real head and arm movement |
| Flatscreen (this mod) | Their real head and arm movement |
| Unmodded | The game's normal animations |

In the pre-game lobby, **VR Player** or **Flatscreen Player** is added to your rank, and everyone sees it whether or not they have the mod. The in-match `VR` / `FP-` name prefix needs the **host** to be running the mod - the lobby rank tag does not.

## Why the lighting looks the way it does
There is no automatic exposure in a manually rendered VR eye, so the mod pins exposure to fixed day and night values instead. Two consequences worth knowing:

- Areas authored much brighter or darker than average read washed out or murky - caves, deep shade and heavily fogged areas are where you notice it.
- Volumetric fog is off entirely (it costs roughly 7 FPS **per eye**). Areas built around thick atmosphere look clearer and plainer than intended.

Torches are boosted to compensate, and each eye renders slightly wider than it shows you so lights near the edge of view are not dropped from one eye's lighting.

## Known limitations
- No volumetric fog; affected spell effects use cheap stand-ins
- Controller models are not rendered - you see your in-game hands
- Water renders slightly differently between the eyes
- Some menu text can clip at the edges at certain angles
- The in-match name prefixes need a modded host
- No anti-aliasing, so high-contrast edges shimmer a little

## Troubleshooting
**Nothing appears in the headset.** SteamVR must already be running **before** you launch. If it was, check `BepInEx/LogOutput.log` for the `MageArenaVR.Preload` line - it reports where it found the OpenVR runtime or why it could not.

**Everything is black.** Set `CheapFrameSettings = false` in the config.

**A menu will not respond to the laser.** Set `LaserInputMode = Legacy` and report it with your log.

**Arms are too short, or the body sits wrong.** Press [[F8]] and stand naturally with your arms out.

**Settings changes do nothing.** Your config is stale after an update - delete it and relaunch.

**Frame rate is poor.** Cameras in match to One first, then volumetric clouds off, then lower `EyeResolutionScale`.

## Reporting a problem
`BepInEx/LogOutput.log` is the most useful thing to attach. The release build is deliberately quiet - a healthy session is a handful of lines - so if something went wrong, the log tends to contain the answer rather than burying it.

## Credits
- **MA VR** by J_axon
  https://thunderstore.io/c/mage-arena/p/J_axon/MAVR/
- Built on groundwork from the same author's earlier MuckVR
- Testers: Wakeyiscool, MinusNeptune94, MagicHead333, Abyxus, supersaiyanslyr
- MA VR redistributes `openvr_api.dll`, (c) Valve Corporation, under the BSD 3-Clause licence. It is not affiliated with or endorsed by Valve.
- The author notes that AI was used as part of the development process.
