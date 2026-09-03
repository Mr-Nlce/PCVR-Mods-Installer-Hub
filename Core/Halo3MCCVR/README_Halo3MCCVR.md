# Halo 3 MCC VR Installer

Automated installer for **Halo MCC VR** by pancreations - a native OpenXR VR mod for
**Halo: The Master Chief Collection**. The supported campaigns depend on the selected
release channel.

> **Alpha.** The author labels the five-game build a pre-release "for testing purposes".
> Launch MCC **without anti-cheat** and do not use the mod in matchmaking. The code was
> AI-written under a human modder's direction and is public, unaudited, and MIT-licensed.
> No game files are patched or redistributed - normal Steam launches stay unmodded.

## Stable or pre-release?

When the author's latest stable release and his newest pre-release differ, the installer
asks which one you want:

| | |
|---|---|
| **Stable 0.3.3** | the release the author marks Latest; Halo 3, ODST and Reach |
| **Pre-release 0.3.5** | test build adding Halo 2 Anniversary and Halo 4 |

Both install into the same folder, but they use different DLL/launcher names. The installer
detects the complete payload pair, removes the other channel's stale pair, writes one common
Hub launcher, and records the selected update channel. Switching later is safe: run the
installer again and choose the other channel.

## Known limitations in the five-game build

- **Halo 2 Anniversary** has no VR HUD yet, and its multiplayer is not compatible - campaign
  only, in both Anniversary and Classic graphics.
- **Halo 4** uses floating hands rather than full arm IK.
- **Reach** passenger seats draw no floating hands, though aiming and firing work, and
  character tags and navpoints can sit wrong in 3D.
- **ODST's** first captioned opening cutscene can appear black - skip that scene once and
  the drop sequence plays normally.
- The **Microsoft Store edition** can pause about nine seconds on its first loading screen.
- Co-op, headset and long-session coverage remain incomplete.

## What it does
- Resolves both the proper Latest release and the newest usable prerelease, excluding diagnostic/broken releases, and asks which channel to install.
- Downloads and unpacks the release, recognizes either supported payload layout, locates MCC, copies the files into `Halo_MCC_VR`, and creates the **Halo MCC VR** shortcut.

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
- MCC from **Steam** or the **Microsoft Store / Xbox app**, with the campaigns you want to play installed
- **SteamVR set as your default OpenXR runtime.** The mod requires this - the modder states it in the install steps and names it as the first thing to check when something misbehaves.
- **Steam Input turned OFF for the gamepad.** With it left on, your shots do not land where you aim and enemies become almost impossible to hit. In the Steam library, right-click **Halo: The Master Chief Collection** -> **Properties** -> **Controller**, then set the dropdown to **Disable Steam Input**. Older Steam builds label it **Steam Input Per-Game Setting** -> **Force Off**. If you launch MCC outside Steam (Game Pass), turn the controller support off globally instead: **Steam -> Settings -> Controller**.
- No compiler, CMake, or Visual C++ redistributable needed

> **Sign in to MCC in flat once before installing.** At some point before installing the VR mod, launch Halo: The Master Chief Collection normally (flat) and sign in to the Microsoft service, so it's done and out of the way. On that first flat sign-in, if the sign-in box is off-position on the desktop, click the game window and press **Alt+Enter** to re-center it.

- **SteamVR on its Beta branch**, and set as your default OpenXR runtime.
- **The campaigns you want to play installed** in MCC - the hook engages per title.
## Required MCC settings
Set these in MCC's own menus (you can change them with the headset on, from inside the VR session):

| Setting | Value |
|---|---|
| Settings > Video > Max Frame Rate | **Unlimited** |
| Settings > Video > V-Sync | **Off** |
| Settings > Video > MCC FSR | **Off** |
| Halo 3 > Settings > Field of View | **120** |
| ODST > Settings > Look Sensitivity | **Maximum** |
| ODST > Settings > Look Acceleration | **Off** |

> **Do not enable FSR** in MCC's video menu - it breaks the VR image scale. Use the mod's picture-quality presets instead. **FOV 120** is the one that visibly breaks the game if wrong: at a lower FOV the engine stops drawing geometry at the edges, so scenery pops in and out in the headset.

## Xbox / Game Pass / Microsoft Store builds
Both the stable and pre-release launchers support the Store/Xbox executable directly. The installer detects `MCCWinStore-Win64-Shipping.exe` and installs the same mod payload; it never renames, duplicates or patches an MCC executable. Start the Store edition through the Hub launcher and remain signed in to the Xbox app.

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
- **Vehicles are first person** since alpha 0.3.3, in all three games - Halo 3,
  ODST and Reach. You steer by waving your **right hand** (the right aim stick is
  tied to that hand), so they still need sturdy VR legs.

### You have to set up your own seats
Every seat ships with a **starting** camera position, not a finished one. Your
height, play space and headset all differ from the author's, so a seat that
looks right for him will sit too low or too far forward for you. It is a
one-time job per seat:

1. Get into the seat you want to fix - driver, passenger, gunner or turret
2. Press **F1**, open the **Vehicles** category
3. Adjust *Seat forward*, *Seat height* and *Seat left / right* until it fits
4. Get out - it saves into `halomccvr.cfg` by itself

While you sit in a seat those sliders move **that seat alone**. Driver,
passengers and gunner each remember their own position, in each game - so do the
ones you actually use and ignore the rest.
- Quad-view eye tracking is supported; you can hide the IK rig for floaty hands
- Dual-wield crosshair follows the right hand; two-handed weapon hand placement is adjustable

## Known alpha limitations
- On stable 0.3.3, **Halo 3**, **Halo 3: ODST** and **Halo: Reach** are supported; do not load Halo 4 there. The 0.3.5 prerelease additionally supports Halo 2 Anniversary and Halo 4, with the limitations listed above.
- Right-stick click currently clips/hides your character instead of zooming
- Some toggles in the [[F1]] menu are still rough
- Cutscenes play in a room-fixed theatre in stereo 3D; the flamethrower stays third-person
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
