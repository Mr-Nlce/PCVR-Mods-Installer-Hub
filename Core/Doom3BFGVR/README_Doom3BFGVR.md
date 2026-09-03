# DOOM 3 BFG VR Installer

Automated installer for the current **Fully Possessed** release maintained by
**CommanderKeen83** — native VR, motion controls and two-handed weapons for
DOOM 3 BFG Edition. It continues the earlier NPi2Loup/KozGit work.


## New maintainer, new features

NPi2Loup's Fully Possessed stopped at v0.021j. **CommanderKeen83 carries it on**, and the
installer now follows his releases:

- **Two-handed weapon gripping.** Hold the off-hand grip near a weapon's foregrip - shotgun,
  submachine gun, chaingun, plasma gun, rocket launcher, BFG 9000, chainsaw - for real
  two-handed stabilisation.
- **Dual shoulder holsters.** Stash and draw two separate primary weapons behind your left
  and right shoulders. Reach back with a weapon and press Grip to holster it; reach back
  empty-handed to draw. Pistols stay on the hip, the flashlight on your chest.
- **Off-hand terminal interaction.** Operate computer terminals, video disks, security doors
  and keypads with your free hand while still holding your gun. Your index finger extends
  automatically as you approach.
- **Holstered weapons survive saves** and level transitions.
- **Physical chest-holster flashlight** - reach to your chest and squeeze grip.
- **Full weapon cycling** fixed; thumbstick switching no longer skips weapons.

## The clipping fix is applied for you

Older builds put the camera inside the marine's chest armour when you looked down, crouched
or jumped. The fix is two values, `vr_nodalX` at `-11` and `vr_nodalZ` at `-5`, in
`Fully Possessed\vr_openvr_default.cfg` and `vr_oculus_default.cfg`.

**The installer sets them.** 1.1.0 already ships the right numbers, but an install carried
over from an older version still has the old ones - so both files are checked and only those
two lines are changed. Existing player configs at
`%UserProfile%\Saved Games\id Software\DOOM 3 BFG\Fully Possessed\vr_openvr.cfg`
and `vr_oculus.cfg` are corrected as well. Missing keys are added, and the first
original of every changed file is kept beside it as `.pre-vrfix`.

### Manual clipping fix for an older Hub installation

An older profile can still keep the previous offsets even after the Hub
updates the mod. If the marine's body or weapons still clip into your view,
open the in-game console with the `~` key and enter these commands one by one:

```text
set vr_nodalZ "-5"
set vr_nodalX "-11"
```

This is the direct fallback when the automatic config correction does not
take effect for an install carried over from an older Hub version.

For the best full-body alignment, set **VR Options > Character Options > Use Height** to
*Normal view height* in the game.

## Full package or update?

The releases page carries two kinds of download, and the installer picks for you:

| | Size | Contains |
|---|---|---|
| **Full package** | ~340 MB | the executable, the libraries **and** the `Fully Possessed` data folder |
| **Update** | ~29 MB | executable and libraries only |

An update alone is not enough for a fresh install. If you have nothing yet, the installer
fetches the newest **full package** and then applies a newer update on top if one exists.
If you already have it installed, it takes the newest download only.

## What it installs

- The newest complete **Fully Possessed** package available from CommanderKeen83.
- If the newest GitHub asset is only a small update, the required full package is
  fetched first on a fresh install and the update is applied afterwards.

## Requirements

- DOOM 3 BFG Edition owned on Steam or GOG
- SteamVR installed
- An OpenVR-compatible headset (native Oculus Rift/Touch support is also
  detected automatically)

## Features

- **Native VR**: detects and uses OpenVR (Vive/Index/WMR) or the Oculus
  SDK (Rift/Touch) automatically
- **Motion-controlled weapons** with full hand presence
- **Teleportation** with a parabolic aiming beam, plus smooth and snap
  (comfort) turning
- **Comfort options** to reduce sickness: snap turn, third-person
  movement, movement-based FOV reduction, slow-motion movement, and a
  Chaperone static reference
- **Voice commands** via Windows speech recognition — select and reload
  weapons by saying their name, and "talk" to NPCs by speaking to them.
  Trigger phrases live in a plaintext file you can edit
- **Fully rebindable**: every control can be remapped or disabled (e.g.
  remove turning or strafe from a controller entirely)

## VR settings

All VR-specific settings are reached **in-game via the PDA** (touch-screen
menus). The console (`~` key) also exposes the full set of VR console
variables, saved to:
`%UserProfile%\Saved Games\id Software\DOOM 3 BFG\Fully Possessed\`

## Controls

By default the flashlight (or PDA when active) is in the left hand and the
weapon is in the right. Everything below is rebindable in
Settings -> Controls -> Key Bindings.

**Left controller** (aims the flashlight):
- **[[Left Stick]]:** Move (default is controller-relative / Onward style)
- **[[Left Stick]] press:** Toggle flashlight
- **[[Left Grip]]:** Crouch
- **[[Left Trigger]]:** Hold to run
- **[[Y]]:** Recenter view / reset height
- **[[X]]:** Activate PDA (also skips the active cutscene)
- **Menu button:** in-game pause / system menu on the PDA

**Right controller** (weapon hand):
- **[[Right Stick]]** up/down: Next / Previous weapon
- **[[Right Stick]]** left/right: Snap turn 45°
- **[[Right Stick]] press:** Jump
- **[[Right Trigger]]:** Attack / fire
- **[[Right Grip]]:** Reload
- **[[A]]:** Reload
- **[[B]]:** Teleport

In menus / on the PDA: either stick highlights entries, either trigger
selects, **[[Y]]** or **[[Grip]]** goes back. You can also touch the PDA
directly with your virtual finger like a touchscreen.

## Teleporting

Hold **[[B]]** (or press the right stick in), aim the parabola, and release
to teleport. Pulling the **[[Right Trigger]]** while aiming cancels it. A red
target means you must crouch to fit; no circle means you can't reach there
from your current spot. Two modes in the menus: **Blink** (instant) and
**QuakeCon** (slows time and warps you there).

## Holster slots

Use motion controls to stash or grab items from slots on your body. When a
controller enters a slot the right controller buzzes — press **[[Grip]]** to
grab, place, or swap:
- Right hip = holster your weapon (swaps if one is already there)
- Behind your weapon-hand shoulder = next weapon; lower back = previous
- Left hip = the PDA; head or left shoulder = the flashlight

## Recommended setup

For a smoother first session, once in VR open the game settings and:
- Turn **off** the comfort camera modes and third-person camera (otherwise
  your character can walk out of his own body)
- Turn **on** controller-based walking
- Turn **off** full-body rendering (hands-with-weapons reads better)
- Increase the walking speed if it feels too slow

## Voice commands

Optional but recommended. Enable and train Windows Speech Recognition first
(Control Panel -> Speech recognition -> at least "Set up microphone"). Then
in-game you can select or reload weapons by saying their name, and "talk" to
NPCs just by speaking to them — but note speaking can wake nearby monsters.
The trigger phrases live in `Fully Possessed/dict/voice.dict` and can be
edited.

## Known issues / tips

- **iGPU systems:** if your PC has integrated graphics, add a rule in the
  NVIDIA Control Panel so `Doom3BFGVR.exe` runs on the dedicated GPU —
  otherwise the game may not load at all
- The base VR mod is stable on its own; layering large HD texture packs on top
  can cause crashes

## How to use

Click **Install Mod** on the game tile or detail page and follow the prompts.

## More info

https://github.com/CommanderKeen83/DOOM-3-BFG-VR

>>> The Mars facility breathes wrong. Trust your flashlight.
