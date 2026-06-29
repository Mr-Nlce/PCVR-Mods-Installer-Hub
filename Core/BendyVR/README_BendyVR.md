# Bendy and the Ink Machine - VR

Full VR conversion with motion controls for the cartoon horror
adventure. This is Team Beef's first PCVR mod.

## Important: which game build

The current Steam build of Bendy and the Ink Machine no longer starts
with this mod (Team Beef, June 2025). The installer offers two options:

- **Depot version (recommended)** - downloads the mod-compatible build
  via Steam Console into `C:\Games\Bendy VR`, then installs the mod.
  Your retail Steam copy is left untouched.
- **Current game version** - installs the mod onto your existing copy
  (Steam or Epic). Use only if you specifically want the current build;
  on Steam it may not launch in VR. If it doesn't work, re-run and choose
  the depot version.

## Features

- Motion-controlled hands with melee combat
- VR comfort options (snap turn / smooth turn)
- Left-handed support (including switched sticks)
- Many game alterations to make it work and feel good in VR

## Requirements

- Bendy and the Ink Machine on Steam or Epic
- A PC ready for PCVR (no standalone/Quest-native support)
- An OpenVR-compatible headset: Quest 2 (via Link / Air Link / Virtual
  Desktop / ALVR), any Rift, Valve Index, any Vive, WMR devices
- **VR motion controllers are required** - not playable with a gamepad
- Steam and SteamVR installed

## How to use

Click **Install Mod** on the game tile or detail page and follow the
prompts. Pick option 1 (depot) or 2 (current build) when asked. The
installer downloads the mod and installs the files directly into the
game folder, and (for the depot build) creates a `Bendy VR` desktop
shortcut. Launch the depot build via that shortcut or through the Hub's
**Start in VR** button - not via Steam, which would run your retail copy.

## Controls

Default SteamVR Input bindings ship for the main headsets. In menus
there are no tracked hands - use UI Up / Down / Next / Previous /
Confirm / Cancel to navigate.

Sample Oculus Touch layout (Quest 2 / Rift S):

- **Non-dominant hand:** [[Stick]] = move; [[Stick]] click / [[Grip]] = run;
  [[Trigger]] = interact; [[Y]] = pause
- **Dominant hand:** [[Stick]] left/right = smooth/snap turn; [[B]] = Seeing
  Tool (Ch.5 / New Game+); [[A]] = jump; [[Trigger]] = attack (gun / thrown
  weapons)
- Melee weapons (axe etc.) are motion controlled - swing to attack

Interaction is based on your non-dominant hand. Turn on the laser sight
in the Advanced Menu if you're unsure what you're pointing at.

## VR settings

VR settings live in the **Advanced Menu** (via Main Menu or Pause).

## Performance

Aim for a smooth framerate. The game runs best with the optional effects
turned off (Anti-Aliasing, Depth of Field, Bloom, Ambient Occlusion), in
addition to the graphics quality setting and Steam resolution. Depth of
Field is especially heavy; Ambient Occlusion has small per-eye artifacts.

Bendy VR ships with **openvr_fsr**, already enabled on Ultra quality. To
adjust or disable FSR, edit:
`Bendy and the Ink Machine\Bendy and the Ink Machine_Data\Plugins\openvr_mod.cfg`

## Known issues

- The ending cinematic is screen-locked (Unity Video Player limitation).
- After the credits you must exit and restart for New Game+ / archives.
  Your progress is saved.
- You can't return to the main menu from the pause menu - Quit then
  Confirm exits the game completely.
- Fog and some post-processing effects rotate with your view (the engine
  version Bendy uses lacks the needed roll support).

## Credits & support

VR mod by **Team Beef Studios**, building on VR groundwork by
**Raicuparta**. If you'd like to support Team Beef's work and vote on
future ports, see their Patreon: https://www.patreon.com/teambeef

>>> Dreams come to life. So does the ink.
