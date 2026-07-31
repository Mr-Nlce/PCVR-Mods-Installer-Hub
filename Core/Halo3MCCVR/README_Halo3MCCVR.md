# Halo 3 MCC VR Installer

Automated installer for **Halo MCC VR** by pancreations - a native OpenXR VR mod for **Halo: The Master Chief Collection** on Steam. The supported campaigns are **Halo 3**, **Halo 3: ODST** and **Halo: Reach**. Of the collection only **Halo 4** is still missing.

> **Early alpha.** Halo 4, online play, custom games, Forge, and long sessions are not validated. **Reach** is the newest addition and the roughest of the three; the author suggests holding off on it unless you want to help find bugs. The code was AI-written under a human modder's direction and is public, unaudited, and MIT-licensed. No game files are patched or redistributed - normal Steam launches stay unmodded.

## What it does
- Resolves the newest release from GitHub (**prerelease-aware** - the mod ships alpha pre-releases), so the Hub can flag updates and re-running updates in place.
- Downloads and unpacks the release, locates your MCC install (Steam library / Xbox / Microsoft Store, with a manual drag & drop fallback), copies the two mod files into a `Halo_MCC_VR` folder inside MCC, and creates the **Halo MCC VR** desktop shortcut. No game files are modified.

## What works
- True per-eye stereo and 6DOF head tracking
- Motion-controller input: snap/smooth turning, melee, grenades, menu control
- Controller-driven weapon aim with a floating VR reticle
- Articulated VR arms, with a free left support hand on the shotgun
- Native HUD with the centered flat reticle hidden
- Free picture-quality scale from 0.35 to 2.00 (supersampling above 1.00), set in `halomccvr.cfg` or the in-game F1 menu
- **Halo 3: ODST** (experimental): stereo rendering, 6DOF head tracking, motion-controller aim, arm IK, head-relative movement, stereo cutscenes, tested car and HUD controls, and a menu-stick fix so a straight up/down push in menus no longer registers as left/right

## Requirements
- **Windows 10/11 64-bit**
- The **Steam** version of MCC with **Halo 3** installed *(Xbox / Game Pass / MS Store paths are also detected - see the note below)*
- **SteamVR set as your default OpenXR runtime.** The mod requires this - the modder states it in the install steps and names it as the first thing to check when something misbehaves.
- **Steam Input turned OFF for the gamepad.** With it left on, your shots do not land where you aim and enemies become almost impossible to hit. In the Steam library, right-click **Halo: The Master Chief Collection** -> **Properties** -> **Controller**, then set the dropdown to **Disable Steam Input**. Older Steam builds label it **Steam Input Per-Game Setting** -> **Force Off**. If you launch MCC outside Steam (Game Pass), turn the controller support off globally instead: **Steam -> Settings -> Controller**.
- No compiler, CMake, or Visual C++ redistributable needed

> **Sign in to MCC in flat once before installing.** At some point before installing the VR mod, launch Halo: The Master Chief Collection normally (flat) and sign in to the Microsoft service, so it's done and out of the way. On that first flat sign-in, if the sign-in box is off-position on the desktop, click the game window and press **Alt+Enter** to re-center it.

- **SteamVR on its Beta branch**, and set as your default OpenXR runtime.
- **Halo 3, ODST and Reach all installed** in MCC - with any of them missing the 3D hook does not engage.
## Required MCC settings
Set these in MCC's own menus (you can change them with the headset on, from inside the VR session):

| Setting | Value |
|---|---|
| Settings > Video > Max Frame Rate | **120** |
| Settings > Video > V-Sync | **Off** |
| Halo 3 > Settings > Field of View | **120** |

> **Do not enable FSR** in MCC's video menu - it breaks the VR image scale. Use the mod's picture-quality presets instead. **FOV 120** is the one that visibly breaks the game if wrong: at a lower FOV the engine stops drawing geometry at the edges, so scenery pops in and out in the headset.

## Xbox / Game Pass / Microsoft Store builds
The Store build ships the same executable under a different name: `MCCWinStore-Win64-Shipping.exe` instead of `MCC-Win64-Shipping.exe` (343 renamed it in the Season 6 update). The mod's launcher looks for the Steam name, so on a Store install it would find nothing.

The installer handles this: it **copies** the Store executable to the expected name and leaves the original in place. Copying rather than renaming matters - the Xbox app still finds the file it expects, so it won't flag a missing file and start a repair download, and the game keeps launching normally outside VR. The copy is a second name for the same bytes; the only cost is disk space.

Those folders are often not writable without elevation, so you may get a UAC prompt. If the copy fails anyway, the installer prints the exact folder and file names so you can make the copy by hand - the rest of the installation still completes.

## Halo 3: ODST notes
ODST is playable but experimental. A few things are specific to it:

- **Required aim settings (in ODST's own menu):** set **Look Sensitivity to maximum** and turn **Look Acceleration off**. To check it, point left and fire - bullets should snap to the motion-controller crosshair instead of trailing behind it. If they still trail after that, work through the aim checklist: turn **Steam Input** off (see Requirements above), and check the **gamepad layout in MCC's own Settings > Controls** - if a weapon or aim option is set to **inverted** there, un-invert it; that has fixed cases where nothing else did.
- **First cutscene is a black screen.** The very first opening cutscene (the one with captions) shows black. Skip that first cutscene - but do **not** spam skip, or you will also skip the drop-from-the-sky cutscene, which does work.
- **Brightness** intentionally stays at the game default in ODST.
- A hotfix for **controller rumble on the assist** is planned.

> **Switching titles:** if MCC drops a level load back to the menu after you switch between Halo 3 and ODST, fully **restart MCC** and try again.

## Halo: Reach notes
Reach gets the same treatment as the other two: per-eye stereo, 6DOF head tracking, motion-controller aim, hands and weapon, HUD, cutscenes and vibration. It is the newest of the three, so expect it to be the roughest.

- **One control difference:** on Reach the left trigger and [[X]] are swapped, so grenades sit on [[X]].
- The first mission was not built for 3D, but it still renders in 3D.
- `hud_curvature` and `hud_vertical_offset` have no effect on Reach.
- Only Halo 3 has weapon zoom.
- Night of Solace has a visual bug but is playable.

## The shipped config
From alpha 0.3.0 the package contains `halomccvr.cfg`, and it replaces any older one. The Hub installs the shipped file and keeps your previous one next to it as `halomccvr.cfg.previous`.

This matters: 0.3.0 added settings that older config files do not contain, and there is no migration - anything missing silently falls back to a built-in default instead of the author's tuned value. The most visible case is `fit_desktop_window`, whose built-in default is off while the shipped config turns it on, which can cap your headset frame rate. If you had your own tuning, re-apply it through the F1 menu rather than restoring the old file wholesale.

## How to play
1. Start **Steam** and **SteamVR**.
2. Launch with **Start in VR** in the Hub, or the **Halo MCC VR** desktop shortcut. Only that route loads the mod (with **anti-cheat OFF**); launching MCC from Steam gives the normal, unmodded game.
3. Press [[F1]] in game (click both thumbsticks) for all settings, including picture quality.

> **Never use this in anti-cheat-enabled matchmaking.**

## Controls (motion controllers)
- [[R-Stick]] snap/smooth turn; aiming and weapon control follow the right hand
- [[R3]] re-center the view
- [[L3]] + [[R3]] toggle the HUD
- Click **both thumbsticks** to open the [[F1]] settings menu (customize your VR experience)
- **Pause:** press the two face buttons on the **left** controller together to drop to 2D; press again to resume in VR
- **Vehicles** need sturdy VR legs - you steer by waving your **right hand** (the right aim stick is tied to that hand)
- Quad-view eye tracking is supported; you can hide the IK rig for floaty hands
- Dual-wield crosshair follows the right hand; two-handed weapon hand placement is adjustable

## Known alpha limitations
- **Halo 3**, **Halo 3: ODST** and **Halo: Reach** are the supported titles; loading Halo 4 breaks the 3D hook. All three must be installed in MCC or the 3D hook does not engage at all. If switching between titles drops you to the menu, fully restart MCC (see the ODST notes above).
- Right-stick click currently clips/hides your character instead of zooming
- Some toggles in the [[F1]] menu are still rough
- All third-person moments (cutscenes, vehicle riding, turrets, flamethrower) stay third-person
- Broader weapon, vehicle, turret, co-op, and headset coverage is still being worked on
- **Double vision?** A user reported that switching SteamVR to its **Beta** branch fixes it (Steam library > SteamVR > Properties > Betas > `beta`). Also confirm SteamVR is your default OpenXR runtime.

## Troubleshooting
- **Double vision or visual glitches on AMD GPUs:** open AMD Adrenalin, go to the MCC game profile and set **Gaming Experience** to **Default** so it stops overriding the game, then turn off any custom monitor resolutions defined in Adrenalin.
- **NVIDIA users:** check GeForce Experience and the NVIDIA Control Panel for similar global or per-game overrides.
- **Stuttering?** set the frame rate to **unlimited**.

## Safety note
The files are unsigned, so Windows or antivirus may flag them. Do not disable your security software globally - only allow these files if you trust the source. Checksums are published in the release's `BUILD-INFO.txt`.

## Credits
- **Halo MCC VR** by pancreations (a 3D animator; this mod came from a friend's request). The **code is AI-written** under the modder's direction (see the note above); only the visual art uses no generative AI.
- Inspired by **HaloCEVR** by LivingFray and the proof-of-concept **ReclaimerVR** by Nibre
- Halo is a Microsoft trademark; this project is not affiliated with Microsoft or Halo Studios.
