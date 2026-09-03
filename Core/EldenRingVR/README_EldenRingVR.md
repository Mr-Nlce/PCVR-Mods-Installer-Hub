# Elden Ring VR — Motion Controls

This page contains **two independent VR mods**. The button you click in the Hub is
the final choice: **Play/Install Hotbite** never asks for ERVR, and
**Play/Install ERVR** never asks for Hotbite.

Before either mod:

1. Play **offline** with Easy Anti-Cheat disabled. Using either mod online risks a ban.
2. Select the matching **SAVE SET · Current / Depot 1.16.2** above. The Hub backs up
   and separates the incompatible saves.
3. Use the Hotbite or ERVR button — not Steam's normal Play button.

Patch 1.17 currently breaks both motion mods. Until they are updated, use the pinned
**Depot 1.16.2** copy. It is separate from the current Steam installation.

# Hotbite [WIP] — by Hotbite

Hotbite makes your head the camera and puts weapons, shields, bows and spell tools on
the tracked controllers. It runs through its own ModEngine installation outside the
game folder. This is an early alpha tested by the author only on Quest 3 with SteamVR.

[Hotbite on Nexus](https://www.nexusmods.com/eldenring/mods/10659?tab=description)

## Start Hotbite

1. Start SteamVR.
2. Select the correct save set above.
3. Click **Play Hotbite**. The Hub starts Hotbite directly and silently.

Steam's Play button starts the unmodded current game instead.

## First setup: enable real 3D

Hotbite can run in mono, which looks flat. Click **Hotbite 3D** in the **VR MODE** bar
above to enable stereoscopic 3D immediately. New installs start in 3D, and reinstalling
Hotbite now preserves an existing tuning file instead of resetting your choice.

For manual control, click **Hotbite config** and choose **Hotbite display / tuning**.
The relevant value is:

`global.vr_mono = 0` — stereo 3D  
`global.vr_mono = 1` — mono

Stereo alternates eyes and therefore needs a stable high frame rate. If it doubles or
shimmers, lower Elden Ring's resolution/settings first; mono is the performance fallback.

## Controls

- [[Left Stick]] move; [[Left Stick Click]] crouch.
- [[Right Stick Left]] / [[Right Stick Right]] turn.
- [[A]] jump; [[B]] roll; hold [[B]] to sprint.
- [[X]] use item; [[Y]] interact; hold [[Y]] for the pouch.
- [[Left Trigger]] Ash of War; [[Right Trigger]] fires or casts held tools.
- Bring both hands together and use [[Left Grip]] to two-hand a weapon.
- Hold both stick clicks to open Hotbite's tuning panel.

## Useful fixes

**Controllers do nothing:** click **Hotbite config**, choose **Hotbite input mapping**,
and place `#` before `ERVR_PAD_SLOT`. Save, close Elden Ring and start Hotbite again.

**Motion blur:** turn it off in Elden Ring's video settings.

**Combat expectations:** heavy weapons deliberately follow more slowly; whips are
trigger-only, and some weapon types remain incomplete in this alpha.

## Install and remove

Hotbite lives under Local AppData and does not replace files in the Elden Ring folder.
It can coexist with ERVR. Use the Hub uninstaller and choose Hotbite to remove only its
portable mod folder; the game, ERVR and all saves remain untouched.

---

# ERVR — by Ilyamez

ERVR uses native OpenXR, true stereo rendering, 6DoF head tracking and physical melee.
The visible blade is the hitbox; swing speed affects damage, shields block by posture,
and two-handing works by grabbing the weapon with the free hand.

[Ilya's ERVR on Nexus](https://www.nexusmods.com/eldenring/mods/10711?tab=description)

## Start ERVR

1. Make the intended OpenXR runtime active: Meta/Oculus for Link, VDXR for Virtual
   Desktop, or SteamVR for Index, Vive, WMR, Pico and Steam Link.
2. Select the correct save set above.
3. Click **Play ERVR**. The Hub starts that Elden Ring build directly.

## First setup: switch the window to Full 3D

The supplied ERVR config starts in `cinema`, which shows the flat game on a floating
screen. Click **ERVR Full 3D** in the **VR MODE** bar above to switch the selected
Current/Depot installation to real stereoscopic 3D. New Hub installs already set this.

For manual control, click **ERVR config** and change the `StereoMode` entry in the
`[VR]` section:

`StereoMode=full` — real stereoscopic VR  
`StereoMode=cinema` — flat game on a head-locked screen  
`StereoMode=off` — VR rendering disabled

Do not change the unrelated `Mode=quad`, `Mode=game` or combat `Mode` entries. If the
game is already running, restart it after changing the stereo mode.

## Combat and controls

- Fast committed swings do more; slow contact does little.
- Heavy weapons have more inertia than daggers.
- Put the shield between you and the hit; a fast defensive movement can deflect.
- Grab the hilt or shaft with the free hand to two-hand; move it away to release.
- Menu and crouch buttons use tap/hold layers for Map and quick slots.
- Controller-relative movement and snap turning are available in **ERVR config**.

## Performance and troubleshooting

- Full stereo renders the scene twice. Lower game resolution and graphics settings
  before reducing VR functionality. `RenderScale` increases clarity at extra GPU cost.
- If you still see only the floating screen, click **ERVR Full 3D**, confirm the correct
  Current/Depot config when asked, then restart the game.
- If the wrong runtime opens, make the intended OpenXR runtime active before launching.
- If ERVR does not load at all, antivirus may have quarantined its DLL or ReShade loader;
  reinstall from the Hub and keep the antivirus recovery check visible.

## Compatibility, install and remove

ERVR installs into the selected Elden Ring build as a ReShade add-on. It cannot coexist
with Luke Ross R.E.A.L. in the same build because both own the same graphics-loader slot;
the installer blocks that conflict before overwriting anything. Hotbite is separate and
can remain installed.

Use the Hub uninstaller and choose ERVR, then Current, Depot or both. The uninstaller
restores loader files that existed before ERVR and leaves the game, Hotbite and saves
untouched.

Elden Ring and all trademarks belong to their owners. These community mods are unofficial.
