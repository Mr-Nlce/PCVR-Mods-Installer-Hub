# Alba: A Wildlife Adventure - VR

VR support for the cozy island wildlife adventure. Play the whole game
from start to finish as a seated VR experience.

## Features

- Play the game from start to finish as a stationary VR experience
- Optional full first-person mode (gamepad only) with snap turn or smooth turn
- HUD toggle for a more immersive view
- Works with the Steam and Epic versions (other versions likely work but are untested)
- Tested on Valve Index; should support all SteamVR and Oculus headsets

## How to use

Click **Install Mod** on the game tile or detail page and follow the
prompts. The installer downloads BepInEx and the VR mod, places them in
the game folder, and (on Steam) turns off Desktop Game Theatre for you.

After installing, launch the game in VR. The VR mode setting is
remembered, so later you can just launch the game normally. Use your VR
software's recenter function once in-game, then the in-game recenter key
(Home by default) to realign the view to your head when needed.

## Controls

Motion controls are **not** supported. Keyboard and mouse work, but a
gamepad is strongly recommended.

## What it installs

- **BepInEx 5.4.21** - the mod loader
- **AlbaVR v1.0.0** - the VR mod by Wouter Pleizier (Blueberry_pie)

## Requirements

- Alba: A Wildlife Adventure owned on Steam or Epic
- SteamVR installed

## Hotkeys

Default hotkeys (changeable in `AlbaVR.ini`, which appears in the game
folder after the first launch):

- **Home** - recenter VR position
- **Insert** - toggle full first-person view
- **H** - toggle HUD

## Full first-person view

By default the VR view follows the game's third- and first-person
cameras. For a more immersive feel you can force an always-on
first-person view (except during cutscenes, dialogs and certain
interactions), toggled with **Insert**. When enabled, snap turning is on
by default with a gamepad; turn speed and other behaviour can be tuned in
`AlbaVR.ini`.

## Performance

- The game renders at your headset's native resolution. To change render
  resolution, adjust the render scale/multiplier in your VR software and
  restart - the in-game resolution setting does nothing in VR.
- Most VR-ready systems run it well; expect some frame drops when using
  the phone camera in busy areas.
- For a performance boost, turn off **Shadows** in the in-game graphics
  menu (switches to prebaked shadows - much faster, little visual loss).
  Tweaking the LOD setting (in-game or in `AlbaVR.ini`) also helps.

## Known issues

The game is 100% completable in VR, but keep these in mind:

- There are no dedicated comfort options beyond the optional first-person
  view with snap turn. If you're prone to motion sickness, some camera
  movements may be hard to handle.
- Switching save slots mid-session breaks VR rendering - restart the game
  to use a different save slot.
- The outer edges of the map don't render correctly in the right eye; you
  may want to close that eye when reading the map.
- Some visual effects (like the screen fading to black) lack polish.

## Credits

- Original game by **Ustwo Games**
- VR mod by **Wouter Pleizier** (Blueberry_pie)
- VR patcher by **MrPurple6411**

If you enjoy the mod, consider supporting the VR modder:
https://www.paypal.com/paypalme/wouterpleizier

>>> Camera ready. The island is full of life worth saving.
