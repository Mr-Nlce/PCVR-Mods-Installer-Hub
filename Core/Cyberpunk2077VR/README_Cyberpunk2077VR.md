# Cyberpunk 2077 VR

**CyberpunkVRPort** by **dariulone** - a 6-DoF VR mod for **Cyberpunk 2077**, built as a
**RED4ext plugin**. `CyberpunkVR_Stereo` is now the **only** native plugin: it drives OpenXR
head tracking, real stereo, the in-headset overlay **and** the full-body VR avatar with
motion-controlled hands that used to live in a second DLL. A set of CET and redscript mods add
VR weapon aiming, the physical reload, motion melee and hand-to-holster equipping. Everything
is configured from the in-headset **F10** overlay.

Experimental community mod, not affiliated with CD PROJEKT RED. Keep backups of your saves.

https://github.com/dariulone/cyberpunk-vr-port

## New in 0.1.8

- The Hub resolves the current CyberpunkVRPort ZIP from the official release. If the release cannot be verified, Setup opens the publisher's releases page for manual handover; it never silently downloads an older build as the current version. A selected version older than the installed Hub version is refused before game files are copied.
- New rendering options include asymmetric per-eye projection, native NVIDIA DLSS Frame Generation, per-eye FSR/XeSS histories and OpenXR depth submission. Physical scopes, cyberware combat, crouching and controller haptics have been added.
- When upgrading from 0.1.7, the publisher requires removing `VRCigarette.archive.xl`, `vrport_basketball.archive` and `vrport_mag.archive` from `archive\pc\mod`. The Hub moves existing copies into `.pcvrhub_cyberpunkvrport_legacy_backup` outside the loadable mod path.

### Earlier 0.1.7 changes

- Native VR frame generation can use FidelityFX or NVIDIA optical flow, with an in-headset performance overlay and half-rate pacing. These are options, not a promise of stable performance on every system.
- The VR port now owns its HUD panels and settings overlay. The overlay includes HUD, driving, bindings and frame-generation pages; HUDitor is no longer required or supplied.
- New gameplay work includes roomscale/body alignment, swimming strokes, ladder grips, a tactical belt and camera support for surveillance, Basilisk and third-person scenes.
- The first launch merges VR graphics, bindings, HUD and comfort settings once into `UserSettings.json`. It backs up the old file and preserves language, audio, difficulty, telemetry, cloud saves and gallery favourites. See the first-launch note below before running the game.
- Updating from 0.1.6 removes the obsolete Loot UI and SettingsGuard scripts plus any old QuickBoot CET module. The Hub moves those paths into a game-local legacy backup rather than deleting them.

### Earlier 0.1.6 changes

- **Braindances are stereo**, including their colour grade, and the second eye now receives
  the scanner's green tint as well.
- **Taken-over cameras are driven from the actual lens**, including the AV turret. Three
  overlay sliders tune the special mission viewpoint without changing wall cameras.
- **Menus and braindances use the game's own bindings.** The port's remaps and gestures stay
  out of their way; with a weapon drawn, [[B]] can now close the phone, radio and vehicle list.
- **The square VR UI is fitted and centred.** Contacts, messages, radio, subtitles, dialogue,
  tutorials and the loot window no longer hang off the edges.
- **Two-handed weapon support is physical.** The free hand rests until it reaches the weapon,
  then takes a captured support grip for that weapon. Johnny's body now carries the stereo
  cameras and held-object slots too.
- Major render fixes cover missing indoor lights, the white second eye, the braindance ESC
  hang, invalid swapchain states and the too-small 32 mm stereo separation.

The 0.1.7 release requires Input Loader for the scanner HUD editor and separately requests **More Occluders (Scripted v0.3)** from Nexus. Choose the optional Scripted file on that page, not the ArchiveXL v0.4 main file. The Hub requires both files before copying the VR port.

## What changed with 0.1.0
- **No `dxgi.dll` any more.** The mod loads through the game's own mod loader, and uninstalling
  is deleting folders. Anything else that proxies dxgi - R.E.A.L. VR, for one - has to be out of
  `bin\x64`, or the two fight over the same engine hooks. The installer moves an old one aside.
- **Real stereo.** The second eye is an actual engine view: a camera on the player entity that
  renders the frame graph for its own eye, from its own position. It falls back to mono by
  itself where there is nothing fresh to show - menus and loading screens.
- The old alternate-eye reprojection (AER) is gone entirely, along with its artefacts. There is
  no Mono/AER choice left to make.
- The game HUD is in **both** eyes, at a finite distance so icons fuse instead of doubling.

## Launching
1. **Start your OpenXR runtime first** - Virtual Desktop / VDXR, SteamVR, PICO - **before** the game.
2. Launch Cyberpunk 2077 normally, or use **Start in VR** in the Hub. A launcher window opens
   first: pick the render resolution there. Leave its **DEBUG** tick-box off for play - it arms
   every diagnostic probe at once and costs both frame time and a very large log.
3. In game: [[F10]] or [[Insert]] opens the settings overlay, [[F7]] recenters.

## Controls
VR controller input is merged into the native gamepad, so the game's own **Settings -> Key
Bindings -> Controller** applies. Buttons follow each runtime's interaction profile (Touch,
Index, Vive, WMR).

| Button | Action |
|---|---|
| [[Left stick]] | Move - **one speed** whatever the deflection, so a thumb tremor cannot change your pace |
| [[Left stick fully forward, held 0.2 s]] | **Sprint** - held, not toggled, and it survives a dash |
| [[Right stick X]] | Turn - a snap needs a **full** push, so a resting thumb cannot turn you |
| [[Right stick fully up]] | **Dash / dodge**, once per push |
| [[Right stick fully down]] | Crouch |
| [[Right stick click]] | **Slide release** - racks the weapon during a physical reload |
| [[Right Trigger]] / [[Left Trigger]] | Fire / Aim. Left trigger is also melee block |
| [[A]] | Jump - double and charge jump unchanged. **In a vehicle: confirms a dialogue line** |
| [[B]] | **Weapon in hand:** drop the magazine. **Phone, radio, vehicle list or a menu open:** the game's own B closes or backs out instead |
| [[X]] / [[Y]] | Reload / interact and weapon switch. Hold [[Y]] for the pouch. **In a car, hold [[X]] to get out** |
| [[Right Grip]] + reach to shoulder or hip | Hand-to-holster equip and unequip |
| [[Left Grip]] | Grab the magazine during a reload |
| Left hand to your **left ear** + [[Left Grip]] | **Scanner - a toggle since 0.1.5:** squeeze to open, squeeze again to close, hand free in between |
| [[Swinging a melee weapon]] | Native melee attack along the blade |
| [[Left Stick Click]] + [[Right Stick Click]] hold 1 s | Toggle the VR overlay |
| [[Left Stick Click]] + [[Left Grip]] hold 0.5 s | Activate iconic cyberware in gameplay |

**Quickhacks (0.1.5):** the list moved off the face buttons onto the **left stick, pushed to
the stop**, with [[X]] as a plain apply. It presses the arrow keys rather than the D-pad,
because the D-pad is also the scanner's zoom.

**D-pad chord:** hold the left stick clicked in, then pick the direction with the right stick,
pushed to **0.90** - the same threshold every other gesture in the port uses since 0.1.5.
While the chord is held the right stick is taken out of the camera, so choosing a direction
cannot snap-turn you. Let go without choosing and it sends the normal sprint press instead.

## The F10 overlay
The overlay has controller-operated VR settings, HUD placement, driving, bindings and frame-generation pages. Personal settings are saved in `vrport.ini`; the publisher's first-launch graphics merge is a separate one-time action.

- **General** - world scale, IPD scale, stereo separation, VR menu FOV and quad size, motion
  prediction, head offset
- **Controls** - decoupled weapon aim and its laser dot, locomotion source (game / HMD / left
  hand / right hand), snap turn and angle, immersive holsters
- **Stereo** - which eye the second view is sent to, how stale its last frame may get before the
  submit falls back to mono, the HUD composite, and live counters showing whether the second
  view is producing and reaching the headset
- **VRIK** - start and stop tracking, physical body rotation and its free-look cone, the
  cutscene-suspend tier, IK calibration (reach scale, height, elbow swing and pole, wrist
  offset), diagnostics

HUDitor is not required for 0.1.7. Use the port's native HUD placement controls. The scanner editor's [[Right Shift]] binding needs Input Loader.

## Recommended settings
Cyberpunk is very demanding in VR.

- **Launcher:** do not pick a high resolution; the game is heavy.
- **Quick Preset:** Low, Medium at most. **Resolution Scaling:** off.
- Turn **off**: Ray Tracing, Frame Generation, Film Grain, Chromatic Aberration, Depth of Field,
  Lens Flare. Press **Apply**.
- **Video -> Gamma Correction:** nudge it down a little; the image is otherwise a bit bright.
- **F10 -> VRIK:** start hand tracking and calibrate. The hand overlay is on by default so you
  can line your hands up - turn it off once it fits.

## What the installer puts in place
An in-place mod: the files land in your existing Cyberpunk 2077 folder.

- `red4ext\plugins\CyberpunkVR_Stereo\` - the VR plugin, its sight shaders, the settings template
  (the avatar, hand IK and weapon aim are **inside this one DLL** since the single-plugin build)
- `bin\x64\plugins\cyber_engine_tweaks\mods\CyberpunkVRPort_*\` - the CET mods
- `r6\scripts\CyberpunkVRPort_*\` - the redscript mods

> **Coming from an older build?** `CyberpunkVR_Hands.dll` no longer exists - its code moved
> into `CyberpunkVR_Stereo.dll`. A copy left behind from an earlier install makes **two plugins
> hook the same address**, and the game dies on launch with a fault at `FFFFFFFFFFFFFFFF`.
> Extracting the new build over the old one does **not** remove it. The Hub installer parks it
> for you - if it ever reports that it could not, rename that `.dll` yourself.

**Keep only one `.dll` in each `CyberpunkVR_*` folder.** RED4ext loads every DLL it finds there,
so a renamed backup next to the real build loads as a second copy of the plugin and the two
fight over the same hooks.

### Frameworks
The installer adds each one **only if its files are missing**, so an already-modded Cyberpunk
downloads nothing here:

- **RED4ext** - loads the VR plugins
- **Cyber Engine Tweaks (CET)** - runs the CET mods
- **redscript** - compiles the `.reds` scripts the mod ships
- **TweakXL** - applies its tweak files
- **ArchiveXL** - loads the packed assets
- **Codeware** - shared scripting library; **1.20 or newer**, older builds fail script compilation

The reviewed Codeware fallback is **1.20.4**. It adds fail-safe node and
appearance checks and fixes crashes around native type imports; the installer
still asks GitHub for the current release first.

The current ArchiveXL release is 1.27.4, which addresses occasional dynamic
material initialization crashes. The reviewed offline fallback is the older
1.27.3. The installer asks GitHub for the current stable release first.

The last four are fetched at their newest release: the installer reads the current tag from
GitHub and falls back to a known-good build if GitHub cannot be reached.

## What lands in your game folder

| Path | What |
|---|---|
| `red4ext\plugins\CyberpunkVR_Stereo\` | the plugin: OpenXR, stereo, overlay, the VR avatar and hands, weapon aim, sight shaders |
| `bin\x64\openvr_api.dll` | for the SteamVR (OpenVR) runtime path |
| `bin\x64\CyberpunkVR_*Grip*.ini` | captured hand poses - smoking, lighter, resting hands and the per-weapon two-handed support holds |
| `bin\x64\plugins\cyber_engine_tweaks\mods\CyberpunkVRPort_*\` | CET modules for camera control, VRIK, weapons, reload, HUD panels, driving, ladder and swimming actions |
| `r6\scripts\CyberpunkVRPort_*\` | redscript side, including DeviceCam and ScannerHud; obsolete Loot UI and SettingsGuard scripts are parked on update |
| `r6\input\CyberpunkVRPort_ScannerHud.xml` | scanner editor binding, merged by the required Input Loader |
| `r6\tweaks\vrcigarette\` | TweakXL entries for the smoking props |
| `archive\pc\mod\cyberpunkvrport.archive` / `vrport_mag.archive` | packed VR camera, body, held-prop, magazine and weapon assets |
| `engine\config\platform\pc\` | CPU tweaks tuned for two views |
| `r6\scripts\MoreOccluders.reds` | separate required Nexus Scripted v0.3 file |
| `UNINSTALL.bat` / `UNINSTALL.txt` | the port's own uninstaller, in the game folder |

> **`UserSettings.json` receives a one-time merge on the first VR launch.** Your previous file is saved
> beside it as `UserSettings.pre-vr-<date>-<time>-<id>.json`; language, audio, difficulty, cloud saves and gallery favourites stay in place. Later changes in the game's
> own menus stick. To skip the merge, create `bin\x64\vrport.ini` with
> `first_launch=0` before the first VR start.

## Keys outside the controller

| Button | Action |
|---|---|
| [[F10]] or [[Insert]] | the VR menu / settings overlay |
| [[F7]] | recentre |
| [[F8]] | switch the VR menu between the full headset view and a small panel |
| [[Right Shift]] | scanner HUD editor binding through Input Loader |

## Driving

| Button | Action |
|---|---|
| [[Grip]], hand at the wheel or handlebars | grab it - that arm returns to the driving animation |
| [[Left Controller]] + [[Right Controller]] tilt | steering. One hand: that controller against the wheel centre |
| [[Hand]] on the **middle** of the wheel | horn - no grip needed, and a hand that is grabbing never honks |
| [[Left Trigger]] / [[Right Trigger]] | throttle / brake |
| [[Right Trigger]], weapon drawn | **fire.** The throttle latches at the speed it had |
| [[Left Stick]] forward / back, weapon drawn | trim the latched throttle |
| [[X]] **held** | get out. B is never the exit in a car |

## Removing it
For a temporary flat launch, use the **Flat / VR switch** on this page. It parks only
`CyberpunkVR_Stereo.dll`; the port's CET and redscript modules
stay idle without that native plugin. One click restores VR.

For full removal, use **Uninstall Now** on this page. It starts the port's own
**`UNINSTALL.bat`** from the game folder, which removes the publisher's current package files
and offers your Cyberpunk settings back. The Hub's game-local legacy backup of superseded
0.1.6 scripts and QuickBoot remains available for manual recovery.

## Repair - when you cannot tell what is stale

The installer asks at the very start:

```
 >>> Press Enter to start the installation or Update
     or press R and Enter for Repair, in case of issues
```

**Repair stops treating anything as already installed.** Every framework, every
mod and the VR mod itself are offered again, so whatever is on disk ends up
current.

It exists because **most of these mods carry no readable version at all** - an
`.archive` or a `.reds` file simply does not have one. If you installed months
ago, the installer cannot tell whether your Equipment-EX or Visual Holsters is
current; it would skip them as "already present" and leave a setup that is
broken in a way nobody can see. Repair sidesteps that question entirely.

It takes longer, and it is the right answer whenever something behaves oddly and
you do not know which piece is at fault.

## Run it again to update, or to add something later

The installer is also the updater. Running it on an existing setup:

- **skips what is already there** - frameworks and companion mods are offered when missing;
  Input Loader and More Occluders (Scripted v0.3) are required before the VR port,
- **re-applies the VR mod every time** and parks the three obsolete 0.1.6 paths,
- **checks for age where it can.** A framework that ships a DLL carries a file
  version, so those are compared against what is published and an older one is
  offered for update. **RED4ext and CET are recognised by their marker file
  only**, and **redscript's `scc.exe` reports no usable version at all** - those
  are kept as they are unless you run Repair. **The `.archive` and `.reds` mods carry no
  version at all** - for those the installer can only see whether the file is
  there, which is exactly what **Repair** exists for.

To add a companion mod later, run the installer again and answer its prompts.

## Required Nexus files

The 0.1.7 port handles HUD placement itself. It needs two additional Nexus packages:

| Mod | File to choose | Installed proof |
|---|---|---|
| [Input Loader](https://www.nexusmods.com/cyberpunk2077/mods/4575?tab=files) | v0.2.3 or newer compatible package | `red4ext\plugins\input_loader\input_loader.dll` |
| [More Occluders](https://www.nexusmods.com/cyberpunk2077/mods/33136?tab=files) | **Optional files → More Occluders (Scripted) v0.3** | `r6\scripts\MoreOccluders.reds` |

The Nexus page lists ArchiveXL v0.4 as its main file. That is a different download;
the publisher specifically asks for the **Scripted v0.3** optional file. The installer
opens each page after a reading prompt, searches Downloads and accepts a dropped archive.
Skipping either required file stops the VR installation without recording success.

More Occluders (Scripted) declares RED4ext, redscript and Codeware as dependencies on Nexus;
the Hub installs or checks those framework files before this step. If an older HUDitor is
already present, its own files are left alone; the current port does not require it.

## Recommended companion mods
These are the mods the Hub recommends alongside the port. Several of them need each other -
Visual Holsters needs Equipment-EX, the pistol holsters need Zenitex, the katana needs the
shop it is sold in - so **the installer works out the order for you** and offers each one in
a sequence that actually works.

They live on Nexus, so the Hub cannot download them automatically - **the installer offers
them anyway**: it opens each page in turn, then takes the file from your Downloads folder or
from a drag & drop onto the window. Type **s** and Enter to skip one. Anything you already
have is not offered at all.

> **Nothing is copied on trust.** After unpacking, the installer checks that the archive
> really contains the mod it is supposed to be. A wrong file is refused, and nothing goes
> into your game folder.

If you skipped them, you can add them by hand at any time. The downloads are here:

Visible Bullets - projectiles you can see in flight

https://www.nexusmods.com/cyberpunk2077/mods/22251?tab=files

Visual Holsters - the visible holster the hand-to-holster grip reaches for

https://www.nexusmods.com/cyberpunk2077/mods/21936?tab=files

Equipment EX - extra equipment slots

https://www.nexusmods.com/cyberpunk2077/mods/6945?tab=files

Nova Optics - reworked sights, which the collimated reflex shader draws into

https://www.nexusmods.com/cyberpunk2077/mods/29190?tab=files

All four are drop-in archives: their contents go into the Cyberpunk 2077 folder, the same one
the VR mod uses.

### Legacy VR UI Mods - only with an existing HUDitor installation

HUDitor cannot reach every HUD element. **VR UI Mods** is a set of redscript
files that moves the rest: the scanner and quickhack menu, the info popup, the
contacts list, unread texts, the notification popups and the tutorial window.

It is **not on Nexus** - it is a plain GitHub repository with no release, so the
installer fetches the repository zip directly instead of sending you to a page.
The scripts land in `r6\scripts`.

It only appears when HUDitor is already installed. The 0.1.7 port has its own
HUD controls, so this old optional combination is not required for a new setup.

### They need each other, and the installer knows the order

Several of these pull in others. You pick one; what it sits on comes with it,
prerequisites first:

| pick this | and these come with it |
|---|---|
| Visual Holsters | Equipment-EX |
| **Military Pistol Holsters** | Equipment-EX, Visual Holsters, Zenitex Core - **and the Phantom Liberty DLC** |
| **Hip Katana** | Mod Settings, Virtual Atelier, Shinobi's Black Market, Equipment-EX, Visual Holsters |

The DLC one is called out **before** the download, not after it fails to load.

## Requirements
- **Cyberpunk 2077 patch 2.31** (PC) - Steam **AppID 1091500** or GOG. **The version
  matters:** the port hooks the engine at fixed addresses, so another patch means it does
  nothing or crashes. The installer reads your game's version and warns before touching
  anything.
- An OpenXR runtime, started **before** the game. SteamVR (OpenVR) works alongside it.
- Motion controllers

### Steam: switch to the VR-supported game version

The current VR port needs **Patch 2.31**. Installing the latest GPU driver does not make another game patch compatible with this VR mod. A newer game version may request a driver update when started in flatscreen.

If Setup detects another game version in your Steam installation, choose **1 - Switch to version 2.31 supported by the VR mod**:

1. Close Cyberpunk 2077. Read the highlighted instructions, then press [[Enter]] to open its Steam Properties.
2. Choose **Game versions & betas** (Spielversionen und Betas), then scroll down the version list.
3. Select **2_31_old - Patch 2.31** and wait for Steam to finish downloading it.
4. Return to Setup and press [[Enter]]. Setup reads the installed EXE version again before continuing. If Steam is not finished, choose **Recheck**, **Open Steam Properties again**, or **Stop**.

This is your choice: you can also keep the current game version and stop Setup. **Install anyway** remains an explicitly unsupported alternative. The guided Steam switch does not apply to GOG or Epic copies.

If you already updated RED4ext or Cyber Engine Tweaks for a newer game patch, use **R - Repair** after returning to 2.31 so Setup offers the compatible framework versions again. Keep backups of your saves before changing game versions; the Hub does not modify your saves or select the Steam branch for you.

## Logs
- `bin\x64\cyberpunkvrport.log` - the plugin's own log and the right file for a bug report.
  Quiet by default; tick DEBUG in the launcher for per-frame diagnostics.
- `red4ext\logs\` - script validation and plugin load errors. **If redscript compilation fails,
  every redscript mod is off, not just the one that failed** - check here first when several
  things stop working at once.

## Credits
- **CyberpunkVRPort** by dariulone

  https://github.com/dariulone/cyberpunk-vr-port

- **VR driving** by **iPowerTech** - grabbing the wheel with your own hands, the steering
  geometry, the deadzone and lock-angle controls, the horn on the wheel hub, and shooting
  while you drive are all his work. The canted-lens projection fix and the pre-launch device
  list came from him too.

  https://github.com/iPowerTech

- **RED4ext** by WopsS

  https://github.com/wopss/RED4ext

- **Cyber Engine Tweaks** by maximegmd

  https://github.com/maximegmd/CyberEngineTweaks

- **Cyberpunk 2077** by CD PROJEKT RED

>>> Wake up, samurai. Night City won't burn itself down.
