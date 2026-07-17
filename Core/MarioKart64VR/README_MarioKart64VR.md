# Mario Kart 64 VR Installer

Automated installer for Mario Kart 64 VR by RaYRoD - Mario Kart 64
in PCVR, built on SpaghettiKart, the Mario Kart 64 PC port. Put on a
headset and you are sitting in the kart in stereo 3D with full head
tracking. No headset? The same game runs flat on your monitor.

BETA - expect bugs. This port is early and still changing; not
everything is polished yet. Bug reports are welcome on the GitHub
page.

## What it does
1. Downloads the latest release from GitHub (auto-updates to
   whatever build is newest; falls back to a pinned release)
2. Extracts to C:\Games\Mario Kart 64 VR
3. Optional: installs the MK64 Reloaded HD texture pack (one .o2r
   file into the mods folder - always the newest 4k build)
4. Creates a desktop shortcut and records the release tag so the
   Hub's tile flips to Update when a new release lands

## Your ROM (required)
- Mario Kart 64, US version, .z64 format - a copy that you own
- SHA-1: 579C48E211AE952530FFC8738709F078D5DD215E
- Got an .n64 dump? Convert it: https://hack64.net/tools/swapper.php
- The game asks for the ROM ONCE on first launch. It is read locally
  and never leaves your PC. Nothing from Nintendo is included.

## How to play
1. Start your VR runtime - Virtual Desktop, SteamVR, Quest Link or
   Air Link. (Skip this to just play flat.)
2. Run the desktop shortcut or "Start in VR" in the Hub
3. The game finds your headset on its own and falls back to flat if
   there is none. Force it with Spaghettify.exe --vr or --novr.

## VR controls (motion controllers - a gamepad works alongside)
- **[[Left stick]]:** steer / move through menus
- **[[A]]:** gas (Select in menus)
- **[[B]]:** brake & reverse (Back in menus)
- **[[Left trigger]] / [[X]]:** use your item
- **[[Right trigger]] / [[Grip]]:** hop & drift - and, when paused,
  opens the VR menu
- **[[Menu]] (left):** pause
- **[[Y]] (hold):** look behind
- **[[Right stick]]:** C buttons; push up to change camera distance
- **[[Right-stick click]]:** switch view: Third Person, First
  Person, Theater, Diorama
- Your controllers rumble when you take a hit
- Profiles: Quest Touch, Index, Reverb G2, WMR, Vive

## Gamepad
- **[[Pause]] then [[R1]]:** open/close the in-game menu
- **[[D-Pad]]/stick:** move through menus; left & right change a setting
- **[[A]]:** select
- **[[D-Pad Up]] (racing):** switch view
- **[[D-Pad Down]] (hold):** look behind
- **[[Z]] (main menu):** quit (asks first)

## The in-game menu (VR OPTIONS)
Pause, then pull the right trigger (R1 on gamepad). In VR the menu
floats right in front of you: View Mode, World Scale, Cam Distance /
Eye Height, Stereo Depth, Menu Opacity / HUD Distance, Hide HUD, HUD
Lock (World parks it in the room, Head follows your face), plus
first-person camera tweaks, Default Settings, Restart Race and Race
Setup. Playing flat, the same menu appears as VIEW OPTIONS (or press
Esc: full set under Enhancements -> VR).

## Custom races
On the speed-class list (50/100/150/Extra) there is one extra row:
CUSTOM. The normal classes stay 100% stock - custom only changes
things when you pick it. Item modes (random, all-one-item, frantic,
triples, inverted, or off), CPU item behavior, item rain, track
hazards, prop swap, laps 1-5 or unlimited, 200/300/500cc or Turbo
Laps, mirror, kart size, CPU skill and catch-up - and game modes:
Normal, Knockout, Balloons, Tag, Treasure hunt and Infected. Press Z
on course select for track roulette. The one-player menu also has a
VS row - pick a rival and race them one-on-one through the cup.

## HD textures (optional)
The installer offers the MK64 Reloaded pack by GhostlyDark as a Y/N
step - always the newest .o2r (4k build preferred), dropped into the
mods folder next to Spaghettify.exe. It loads as a mod, no rebuild
needed. Skipped it? Rerun the installer any time.
Pack page: https://github.com/GhostlyDark/MK64-Reloaded

## Updates
The Hub checks the GitHub latest release in the background and flips
the game tile to Update when a new build lands. Rerun the installer
and pick Update - your ROM choice, settings and mods folder are kept.

## Mod page
https://github.com/RaYRoD-TV/MarioKart64-VR

## Credits
Built on SpaghettiKart, the Mario Kart 64 PC port. Mario Kart 64 is
a Nintendo game - you bring your own legally owned ROM; nothing from
Nintendo is included or distributed, and no ownership is claimed of
Nintendo's intellectual property.

>>> Rainbow Road has no guardrails. Neither does karma.
