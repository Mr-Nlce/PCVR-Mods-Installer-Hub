# Ring Racers VR Installer

Automated installer for **RingRacers-VR** by RaYRoD-TV - a native OpenXR port of **Dr. Robotnik's Ring Racers**, the Kart Krew racer built on the SRB2 engine. Headset on = VR, headset off = the normal flat game. Free and standalone; no Steam copy needed.

## What it installs
- The **full Ring Racers VR game** into `C:\Games\Ring Racers VR` (first install pulls the full bundle; updates pull just the small VR exe and drop it over your game).
- A **Ring Racers VR** desktop shortcut pointing at `ringracers-vr.exe`.
- Auto-update aware: the Hub flags the tile when a newer release ships on GitHub.

## Highlights
- Full stereo VR - real geometry in both eyes at your headset's native resolution, not a screen-space trick
- Four view modes: **Third-person, First-person, Theater, Diorama** (the track shrunk to a miniature you race over) - click the right stick to cycle any time
- Diorama glides in close automatically instead of clipping through walls
- Culling and draw-distance limits are fully disabled in the headset - nothing pops in or vanishes
- 3D player models - the karts around you are solid, not cardboard
- HUD floats on its own panel parked in your room; full HUD or items-only
- MSAA, a render-resolution slider, and a desktop-mirror throttle for fps headroom
- Comfort sliders throughout: horizon lock on banked turns, stereo depth down to flat, head-motion damping

## Requirements
- A PCVR / OpenXR runtime: **Quest Link, Virtual Desktop, or SteamVR** (tested on Quest 3)
- No Steam copy required - the full bundle ships the exact game data this build was tested against

## How to play
Put your headset on, then launch with **Start in VR** in the Hub or the **Ring Racers VR** desktop shortcut. Headset on boots straight into VR; headset off, it's the normal flat game. All VR settings live in the pause menu under **VR** (world scale, stereo depth, head motion, HUD size and distance, diorama sliders).

## Controls
Play with VR controllers (Touch, Index, G2, Vive...), a gamepad, or keyboard - full kart controls with rumble on both hands.

- [[L-Stick]] steer / accelerate through the kart controls
- [[R-Stick]] camera; **click** [[R3]] to cycle the four view modes (Third-person / First-person / Theater / Diorama)
- [[Trigger]] drift / item, [[A]] accelerate, [[B]] brake (gamepad mapping; VR controllers mirror it)
- Everything is remappable and tunable in the in-game **VR** menu

## Updating
Re-run the installer and choose **[U] Update** - it fetches just the latest VR exe and drops it over your existing game, keeping your saves, addons, and settings. **[R] Reinstall** wipes the folder and sets up the full game fresh.

## Credits
Dr. Robotnik's Ring Racers is by **Kart Krew** - this is a fork of KartKrewDev/RingRacers and all credit for the game belongs to them. VR port by **RaYRoD-TV**, who has other retro VR ports too (Mario Kart 64, Star Fox 64, SM64 co-op, Sonic Robo Blast 2):

https://rayrodtv.com/

Kart Krew is not affiliated with SEGA; no ownership is claimed of SEGA's intellectual property.
