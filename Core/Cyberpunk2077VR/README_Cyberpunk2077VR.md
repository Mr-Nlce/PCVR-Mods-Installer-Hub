# Cyberpunk 2077 VR

**CyberpunkVRPort** by **dariulone** - a 6-DoF VR mod for **Cyberpunk 2077**, built as a
**RED4ext plugin**. `CyberpunkVR_Stereo` is now the **only** native plugin: it drives OpenXR
head tracking, real stereo, the in-headset overlay **and** the full-body VR avatar with
motion-controlled hands that used to live in a second DLL. A set of CET and redscript mods add
VR weapon aiming, the physical reload, motion melee and hand-to-holster equipping. Everything
is configured from the in-headset **F10** overlay.

Experimental community mod, not affiliated with CD PROJEKT RED. Keep backups of your saves.

https://github.com/dariulone/cyberpunk-vr-port

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

| Input | Action |
|-------|--------|
| Left stick | Walk / strafe - push fully forward to sprint |
| Right stick X | Turn (snap or smooth) |
| Right stick fully down | Crouch |
| [[Right Trigger]] / [[Left Trigger]] | Fire / Aim |
| [[Right Grip]] | Hand-to-holster equip and unequip; melee power modifier |
| [[Left Grip]] | Crouch |
| [[A]] / [[B]] | Jump / Dodge |
| [[X]] / [[Y]] | Reload and interact / Weapon switch |
| Right thumb click | Crouch |
| [[Menu]] | Pause menu |
| Swinging a melee weapon | Native melee attack along the blade |

**D-pad chord:** hold the left stick clicked in, then pick the direction with the right stick.
While the chord is held the right stick is taken out of the camera, so choosing a direction
cannot snap-turn you. Let go without choosing and it sends the normal sprint press instead.

## The F10 overlay
Five tabs, live, saved to `vrport.ini` - nothing here needs a restart.

- **General** - world scale, IPD scale, stereo separation, VR menu FOV and quad size, motion
  prediction, head offset
- **Controls** - decoupled weapon aim and its laser dot, locomotion source (game / HMD / left
  hand / right hand), snap turn and angle, immersive holsters
- **Stereo** - which eye the second view is sent to, how stale its last frame may get before the
  submit falls back to mono, the HUD composite, and live counters showing whether the second
  view is producing and reaching the headset
- **VRIK** - start and stop tracking, IK calibration (reach scale, height, elbow swing and pole,
  wrist offset), diagnostics
- **HUD** - per-element X / Y / scale for every HUD group

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

The last four are fetched at their newest release: the installer reads the current tag from
GitHub and falls back to a known-good build if GitHub cannot be reached.

## Recommended companion mods
The mod author recommends four more mods. They live on Nexus, so the Hub cannot download them
automatically - **the installer offers them anyway**: it opens each page in turn, then takes the
file from your Downloads folder or from a drag & drop onto the window, and you can skip any of
them with Enter. Anything you already have is not offered at all.

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

## Requirements
- **Cyberpunk 2077** (PC) - Steam **AppID 1091500** or GOG
- An OpenXR runtime, started **before** the game. SteamVR (OpenVR) works alongside it.
- Motion controllers

## Logs
- `bin\x64\cyberpunkvrport.log` - the plugin's own log and the right file for a bug report.
  Quiet by default; tick DEBUG in the launcher for per-frame diagnostics.
- `red4ext\logs\` - script validation and plugin load errors. **If redscript compilation fails,
  every redscript mod is off, not just the one that failed** - check here first when several
  things stop working at once.

## Credits
- **CyberpunkVRPort** by dariulone

  https://github.com/dariulone/cyberpunk-vr-port

- **RED4ext** by WopsS

  https://github.com/wopss/RED4ext

- **Cyber Engine Tweaks** by maximegmd

  https://github.com/maximegmd/CyberEngineTweaks

- **Cyberpunk 2077** by CD PROJEKT RED

>>> Wake up, samurai. Night City won't burn itself down.
