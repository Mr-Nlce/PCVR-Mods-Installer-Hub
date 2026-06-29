# Selaco VR Installer

## About this mod

Selaco VR is a full motion-controlled VR port of **Selaco**, the
GZDoom-powered boomer shooter by Altered Orbit Studios. The VR
engine (SelacoVR 2.0 by emawind84) is built on QuestZDoom and
reuses your owned game's data, so you keep the full campaign in
roomscale VR with motion aiming.

You must **own Selaco on Steam** (App 1592280). The VR engine does
not include the game - it loads the game's own `Selaco.ipk3`.

## What this Hub installer does

- Finds your Steam Selaco folder automatically
- Downloads the SelacoVR engine and installs it into a `SelacoVR`
  subfolder inside the game folder (your Steam copy is left untouched)
- Copies `Selaco.ipk3` from the game into the engine folder
- Turns on the engine's Laser Sight aim dot by default
- Creates a **Selaco VR** desktop shortcut

## Requirements

- Selaco owned and installed on Steam (App 1592280)
- Selaco set to the **v0.89-bf** Steam beta branch (the only version
  SelacoVR 2.0 supports) - the installer walks you through this
- A PCVR headset with SteamVR / OpenVR
- Start SteamVR before launching

## Switch Selaco to v0.89-bf

SelacoVR 2.0 only works with Selaco **v0.89-bf**. In Steam, right-click
Selaco - Properties - Betas - Beta Participation, and select
**v0.89-bf - Burger Flipper Content Update**. Let Steam finish updating
before launching. Newer game versions will not load correctly. The
installer opens this window for you and waits.

## How to use

Click **Install Mod** on the game tile or detail page and follow
the prompts. When it finishes, start SteamVR, then launch with the
**Selaco VR** desktop shortcut.

## Controls

Selaco VR runs on the QuestZDoom VR engine: motion aiming with the weapon
hand, smooth locomotion and turning on the sticks.

**Aim dot:** the installer turns on the Laser Sight by default, so a dot
marks exactly where your weapon is pointing (where the bullet lands), at
all ranges, with the fire trigger left free. Tune or recolor it in-game
under VR Options - Laser Sight. To turn it off: console (`~`) -
`m8f_wm_ShowLaserSight 0`.

Default bindings (right-handed, `vr_joy_mode 1`):

- [[Right Trigger]] → Fire
- [[Left Trigger]] → Offhand fire
- [[Left Grip]] → Stabilize / two-hand the weapon
- [[A]] → Use / activate
- [[B]] → Next weapon (main hand)
- [[Y]] → Next weapon (offhand)
- [[X]] → Use inventory item
- [[Left Stick]] → Move
- [[Left Stick]] (click) → Run
- [[Right Stick]] up → Jump
- [[Right Stick]] down → Crouch
- [[Right Stick]] (click) → Kick

**Secondary layer:** hold [[Right Grip]] and press a button for its second
action. This is what trips people up - without the grip held, the buttons
do their primary action above.

- [[Right Grip]] + [[B]] → Toggle crouch
- [[Right Grip]] + [[Right Stick]] down → Reload
- [[Right Grip]] + [[Right Trigger]] → Main-hand alt fire
- [[Right Grip]] + [[Left Trigger]] → Offhand alt fire
- [[Right Grip]] + [[A]] → Throw grenade
- [[Right Grip]] + [[Y]] / [[X]] → Next / previous inventory item
- [[Right Grip]] + [[Left Stick]] (click) → Toggle laser sight
- [[Right Grip]] + [[Right Stick]] up → Toggle map

Every binding is remappable in the in-game menu (open with the **left
controller menu button**) - VR Options.

The installer sets up two launchers in the engine folder:

- **SelacoVR.bat** (default) - desktop shortcut points here, `vr_joy_mode 1`
- **SelacoVR_ValveIndex.bat** - `vr_joy_mode 0`; use this if your stick /
  button mapping feels off on Valve Index controllers

To play flat (2D) instead of VR, set the cvar `vr_mode` to `0`.

## Source

- SelacoVR engine: https://github.com/emawind84/SelacoVR/tree/selacovr2.0
- Selaco on Steam: https://store.steampowered.com/app/1592280/Selaco/

## Support the engine developer

If SelacoVR is worth a coffee: https://ko-fi.com/emanueledisco

>>> Lock and load, Security. ACE is watching.
