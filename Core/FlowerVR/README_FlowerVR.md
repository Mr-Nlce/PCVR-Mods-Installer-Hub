# Flower VR

Mod: Flower VR, current stable GitHub release (v1.1 reviewed 3 October 2026), by jeffMeador  
Game: Flower for PC, Steam or GOG  
VR runtime: SteamVR through OpenXR  
Input: Motion controllers or thumbsticks

## About the Game

Flower lets you guide the wind through fields and other landscapes, collecting petals and changing the world around you. It is a short, atmospheric game built around movement, colour and music.

## About the VR mod

The [publisher's Flower VR project](https://github.com/jeffMeador/flower_vr) adds stereo 3D, head tracking and motion-controller steering. The camera sits behind and slightly above the petals. Grass and scene culling follow your gaze, while menus appear on a floating screen. The mod removes the fisheye lens effect and far-distance blur in VR. Level intro movies that are black on some PC setups are skipped.

The same current DLL supports the Steam and GOG PC builds. The Hub can find an Epic installation by its standard path, but Epic VR compatibility has not been verified. You need your own copy of Flower; no game files are provided. The publisher tested with a Steam Frame streamed from a PC. Other headsets and GPUs may need settings adjustments.

## Installation and launch

Use Install on this Hub page. The installer finds `Flower.exe`, obtains the stable `d3d11.dll` from the [official GitHub releases](https://github.com/jeffMeador/flower_vr/releases), and copies your machine's own 64-bit Windows `d3d11.dll` beside the game as `d3d11_orig.dll`. The Windows file is never included in the Hub or redistributed. Any files already occupying those two names are backed up by the Hub's ownership record.

Start SteamVR with the headset connected, then use Start in VR. Steam copies launch through Steam; GOG copies launch from their game folder. The publisher says the game runs flat if SteamVR or a headset is unavailable. The first VR launch creates `vrmod.ini`, `vrmod_Flower.cfg` and a game-derived override folder. Normal `Documents\Flower\Flower.cfg` and saves stay untouched.

With Virtual Desktop, set the runtime in VD to SteamVR and click "Switch to VR" once in the VD menu on the first start. After that, Flower starts in VR automatically.

If the first launch appears flat, confirm both DLLs are beside `Flower.exe`, check that SteamVR is running, and look for the publisher's optional `vrmod.log` in the game folder. A Hub file scan checks the installed files and version receipt; it does not prove a headset image.

## Controls

| Button | Action |
| --- | --- |
| [[Trigger]] or [[Grip]] or [[A]] or [[X]] | Hold to fly; about one third of the trigger press reaches full speed |
| [[Controller Tilt Left]] / [[Controller Tilt Right]] | Turn; about 45 degrees gives a full turn |
| [[Controller Nose Up]] / [[Controller Nose Down]] | Climb or dive; about 30 degrees from rest gives the full input |
| [[Thumbstick]] | Steer; up means dive in levels by default |
| [[B]] or [[Y]] held for one second | Switch between tilt and thumbstick steering |
| [[Menu]] | Pause |
| [[Controller Tilt]] in a menu | Select a level; use [[Trigger]] to choose it |
| [[F6]] | Recenter the view |
| [[Left Bracket]] / [[Right Bracket]] | Move the camera backward / forward |
| [[Comma]] / [[Period]] | Move the camera down / up |
| [[F1]] | Toggle depth of field |
| [[F2]] | Toggle the lens effect |
| [[F3]] | Toggle head-turned camera |
| [[F12]] | Save an image of each eye |

Tilt is measured against the horizon, so holding the controller level means straight flight and no tilt reset is needed. `pitchRestDegrees` controls the nose-up resting angle. Keyboard hotkeys require the Flower window to have focus.

## Quality and comfort settings

`vrmod.ini` sits beside `Flower.exe`. The mod generates usable defaults on first launch. `vrmod_Flower.cfg` is its separate game settings copy; keep the width and height square and adjust `maxSquare` to match. The publisher's high-quality example targets 2644 × 2644 per eye with 8× MSAA on an RTX 5090; the automatic starting setup uses a 2160-square window and 4× MSAA. Lower resolution, MSAA or grass density on slower GPUs.

Useful `vrmod.ini` options include `worldScale` (default 0.3), `cameraBack`, `cameraUp`, `cameraSide`, `cameraFlights`, `steering`, `tiltTurnDegrees`, `pitchRestDegrees` and `invertStickY`. Set `cameraFlights=0` if the scripted camera moves are uncomfortable. The release README explains every setting and includes high-quality example files.

## Limitations

- The chase camera can swing toward flower patches, which may be uncomfortable.
- The first title card can be clipped at its sides; sparkles can appear large.
- The publisher tested one desktop VR setup and does not claim broad headset compatibility.
- This mod uses the game's original virtual gamepad input. It does not add hand interactions with individual flowers.

## Sources

- [Publisher README and source](https://github.com/jeffMeador/flower_vr)
- [Stable releases](https://github.com/jeffMeador/flower_vr/releases)
- [VR gameplay](https://youtu.be/A30Fg2g_Vfo)

>>> Stop and smell the flowers. Then become the wind.
