# Gunfire Reborn VR Installer

Automated installer for **GunfireRebornVR v1.0.9.1** (Astienth, based on
PureDark's port) — full VR with motion controls for the roguelite FPS
Gunfire Reborn. Because the live Steam build moves ahead of the mod, this
installs a pinned, mod-compatible Steam depot build into its own folder.

## What it installs

- **Steam depot build** — a pinned Gunfire Reborn version compatible with
  the VR mod
- **BepInEx** — the mod loader
- **GunfireRebornVR v1.0.9.1** — the VR mod with motion controls

## Requirements

- Gunfire Reborn owned on Steam
- SteamVR installed
- A PC ready for PCVR (no standalone/Quest-native support)

## Features

- **Full motion controls** — aim and fire your weapons with your hands;
  the port feels close to a native VR shooter
- **Decoupled head/body movement** — look one way while moving another
- A large world to explore across the game's roguelite runs
- Optional **bHaptics** vest/arms support is available separately from the
  mod author for haptic feedback

## Launching

The VR build installs to its own folder (default `C:\Games\Gunfire Reborn
VR`) and is completely separate from your retail Steam copy. **Always
launch via the `Gunfire Reborn VR` desktop shortcut or the Hub's Start in
VR button — not via Steam**, which would start your flat retail copy.

## First-launch quirk

On first launch BepInEx initialises itself and patches the game files —
**close and relaunch once** before playing in VR. The first time, you'll
also need to bypass the DLC/Roadmap screen manually.

## Multiplayer

You can play alongside flatscreen players. Note that **no players (VR or
flat) can see your hand movements** — there's no networked VR avatar.
Matchmaking unlocks after level 10. To join a friend by invite, have a
keyboard ready and press Shift+Tab when the invite arrives (or Alt+Tab to
the Steam page). Both players must already be in "New Adventure" — right-
click the name and Join Game; it won't work from the main menu.

## HUD on your wrists

Map sits on the back of your **left** hand; **copper and essence** on your
**right** hand — glance at them like a wristwatch. Secondary skill is bound
to the left hand, weapon skill to the right.

## Tips

- **Snap turn:** there's no teleport, but snap turn works via SteamVR
  bindings. The thumbstick can't be bound to anything but smooth turn, so
  set it to "Use as D-pad" instead of thumbstick, then bind snap-turn
  left/right to stick left/right. In-game turn speed is adjustable but
  still a touch slow
- **Drop a scroll / recycle a weapon:** select it in the menu, then tap [[B]]
  and hold [[B]] in quick succession — a circle fills up and releases when it
  completes. Takes a few tries; the same gesture recycles weapons (easy to
  fumble into a weapon swap)
- Movement can feel fast for a VR newcomer — ease in and use comfort
  turning if you're motion-sensitive
- There's a dedicated sprint button; the primary weapon is held in the
  dominant hand
- **No immersive throwing/gestures** — grenades and specials are button-
  triggered, not physically thrown
- The **Game Pass version does not work** (it's an outdated build)

## How to use

Click **Install Mod** on the game tile or detail page and follow the prompts.

## More info

https://github.com/Astienth/gunfire-reborn-bhaptics/releases/tag/1.0.0

>>> Lock and load. The dungeons await in VR!
