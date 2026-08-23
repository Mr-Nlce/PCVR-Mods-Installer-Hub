# Red Faction VR Installer

Automated installer for **Alpine Faction VR** by CactusVRStudios - an experimental VR build of **Red Faction** (2001), built on top of **Alpine Faction**, the maintained Red Faction engine project. Native OpenXR, stereoscopic rendering, 6DOF head tracking, motion-controlled weapons and room-scale movement.

## This is a beta
As of **1.0 Beta** the mod has left alpha, but the author still asks for the same
care: back up your files and saves, and report crashes, visual problems or
gameplay regressions. Known right now: open mesh issues on some guns, and
two-handed weapon grips are buggy.

### New in 1.0 Beta
- The **bomb-defusal sequence and the end credits** now render through the
  VR-compatible OpenXR quad layer, so they are readable in the headset.
- The **defusal interface takes left-thumbstick directions**.
- **Menus and the native Precision/Sniper scope views stay fixed in tracking
  space** until you recentre - they no longer swim with your head.
- New save games get **automatic date-and-time names**.
- **Shake to reload is on by default**, triggered by a downward hand motion; the
  threshold is adjustable and sits at 80 cm/s.
- The laser sight is **half as thick**.
- The bundled **`VR` mod is selected automatically** whenever VR mode is enabled -
  one less thing to get wrong.
- `mods/VR/vr_weapons.vpp` now ships in **both** the installer and the manual ZIP.
- Includes the 0.9 swimming hotfix: **look up or down and push forward** to
  ascend or descend.

Singleplayer is the target. Multiplayer as a client is best-effort and unsupported; dedicated-server VR is not supported at all.

## Requirements

| | |
|---|---|
| Game | **Red Faction (2001)** - Steam, GOG or retail |
| Runtime | any active **OpenXR** runtime with a working PC VR setup |
| Controllers | **Oculus Touch** or **Valve Index Knuckles** - both are mapped |
| Renderer | VR forces Alpine Faction's **Direct3D 11** path |

## What it does
- Finds Red Faction (Steam, GOG or retail).
- Fetches the author's one-step setup, **checks its SHA-256 against the checksum in his own release note**, and stops without touching anything if the two disagree.
- Runs the setup, which brings a supported game version up to date, creates the folders it needs and installs the VR build in one pass.
- Records where the VR build landed, so **Start in VR** opens it and the Hub can flag new releases. Every build of this mod is published as a pre-release, and the Hub follows those.

The VR build gets its own folder rather than living inside Red Faction, and your Red Faction install is not modified. The Hub keeps track of where it went, so you never need that path yourself.

There is also an advanced ZIP with just the mod files, for people who already have Alpine Faction prepared. The author recommends the setup, so that is what this installer uses.

## Turning VR on
**VR is off until you switch it on.** Hit **Start in VR** on this game's page in the Hub, open **Options**, enable **VR / OpenXR** and pick your turn mode - snap or smooth. Make sure your headset's OpenXR runtime is running, then start the game from there.

The choice is stored in `alpine_settings.ini`, so this is a one-time setup. The `-vr` command line switch does the same job.

## Controls - Oculus Touch

**Left controller**

- [[Left Thumbstick]] move - on ladders, look up or down and push forward to climb
- [[L3]] holster weapon
- [[X]] reload
- [[Y]] flashlight / headlight - it points where you look
- [[Left Grip]] use and interact; also grabs the weapon support point for a two-handed grip when your hands are close enough
- [[Menu]] open / pause menu, on a native non-SteamVR OpenXR runtime

**Right controller**

- [[Right Thumbstick]] turn, snap or smooth
- [[Right Thumbstick Up]] previous weapon
- [[Right Thumbstick Down]] next weapon
- [[R3]] toggle the laser sight (off by default)
- [[A]] crouch
- [[B]] jump
- [[Right Trigger]] primary fire
- [[Right Grip]] + [[Right Trigger]] alternate fire

Aim by moving the right controller. In menus, point with the right controller and select with the right trigger; go back with [[B]] or the left menu button. On SteamVR, its menu is [[X]] + [[A]] held together for about 0.6 seconds.

## Controls - Valve Index Knuckles
Same layout with three differences: **reload** is left [[A]], **flashlight** is left [[B]], and **alternate fire** is the [[Left Trigger]] on its own instead of grip-plus-trigger. Menu back is [[B]] or both A buttons held for about 0.6 seconds.

![Controller layout](ControllerLayout.jpg)

## Turrets and vehicles
- Mounted turret and jeep gunner aim follows your **head** - yaw and pitch.
- Vehicle throttle is the left thumbstick, relative to the vehicle rather than to where you are looking. Steering and pitch are the right thumbstick.
- Enter and exit with [[Left Grip]].
- Weapon cycling is suspended while you are mounted, so the right stick keeps its pitch job.

## Room-scale
Physical movement uses Red Faction's own world collision with a 16 cm head volume - real walls, invisible collision faces and moving geometry all count. When you reach a wall, the whole tracked rig (both eyes, hands, weapon, muzzle and laser) is pushed back to the last safe spot. Turns pivot around where you are physically standing now, not around an old recentre point.

Opening or closing a VR menu recalibrates tracking yaw, your height and the room-scale origin from your current pose - that is the quickest way to reset yourself.

## Removing it
The author's own route: reinstall the regular Alpine Faction release, which restores its original files. Since the VR build sits in its own folder, deleting that folder removes it as well. Red Faction itself keeps working either way - it was never modified.

## Credits
Red Faction is by **Volition**. All credit for **Alpine Faction** goes to its development team - it is a fork of Dash Faction, and this VR work would not exist without it. The VR build is by **CactusVRStudios**, unofficial and fan-made.

https://github.com/CactusVRStudios/alpinefactionVR

>>> Mars is ours. Now swing the sledgehammer with your own arm.
