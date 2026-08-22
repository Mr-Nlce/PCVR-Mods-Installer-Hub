# Banjo-Kazooie VR Installer

Automated installer for **BanjoKazooie-VR** by RaYRoD - a native OpenXR VR build of **Lighthouse**, the Harbour Masters PC port of **Banjo-Kazooie** (Nintendo 64, 1998). The whole game renders per eye with head tracking. No headset answering? The same exe runs the flat game - `--vr` and `--novr` force either way.

## How this is installed

**RaYRoD-TV removed the downloads from GitHub.** In his own words on the project
page: *nothing to download here anymore, no PC builds and no Quest builds - the
hub is the one place it all lives now.*

So there is one route, and the installer takes it for you: it fetches
**RaYRoD-TV's Multiverse VR Hub**, one small app that carries all of his VR
ports and keeps them updated. You choose where it goes
(`C:\Games\Multiverse VR Hub` by default). Open it, pick the port, hit Play -
it pulls the official build and applies the VR patch itself.

**Start in VR** in the PCVR Hub opens that app from then on, not the game.

**The Hub checks the download for you.** RaYRoD-TV publishes a SHA-256 checksum
with every release and asks people to verify it with `certutil`. The installer
does that step itself: it reads the checksum out of his release note, hashes the
file it just downloaded, and shows both side by side. If they do not match it
stops and installs nothing.

The games stay on your own PC, and you still bring your own ROM where one is
needed.

## What it does
- Downloads the newest BanjoKazooie-VR release from GitHub, so the Hub can flag updates and re-running the installer updates in place (your saves, settings and generated game archive are kept).
- Installs to `C:\Games\Banjo-Kazooie VR` by default - you can pick any folder; no admin rights or UAC prompt needed at the default location.
- Lets you drop in your ROM right away, or leave it to the extraction wizard, which asks for it on the first start.
- Creates a **Banjo-Kazooie VR** desktop shortcut.

## You provide the ROM
Nothing from Nintendo is included or downloaded. You supply your own dump, and it never leaves your PC.

| | |
|---|---|
| Platform | **Nintendo 64** - not Xbox 360, not Rare Replay, not Nintendo Switch Online |
| File | a `.z64` ROM dump |
| Version | **US (NTSC) 1.0** |

**Where to put it:** place the `.z64` next to `Lighthouse.exe` (the install folder this Hub created). On the first launch the extraction wizard reads it once and builds `bk.o2r`; after that the ROM is no longer needed. If no ROM is there, the wizard asks you to pick one.

## View modes
Click the right stick to cycle:

- **Third Person** - the classic chase camera, at life size
- **First Person** - you are Banjo: head-directed movement, physical lean, the bear hidden from your own eyes
- **Diorama** - the level shrunk to a tabletop miniature in front of you
- **Theater** - the flat game on a big virtual screen, maximum comfort

## Controls
Motion controllers work on every major profile (Quest Touch / Touch Plus, Index, Reverb G2, WMR, Vive wands), mapped to the N64 pad. A gamepad or keyboard keeps working alongside.

- [[Right Trigger]] attack
- [[Left Trigger]] crouch
- [[Right Grip]] jump
- [[Left Grip]] camera modifier
- [[Menu]] pause
- [[R3]] cycle the four view modes
- [[L3]] open the port menu on a head-locked panel, drivable from the headset with a stick pointer
- [[Both Triggers]] hold about half a second to recenter (a haptic tick confirms)
- From pause, [[Right Trigger]] opens the in-headset VR options overlay; [[Grip]] turns its pages

## VR options
Every knob also lives in the port menu under **Enhancements -> VR**: world scale, stereo depth, eye height, camera distance, HUD size and distance, screen size and distance, fog, draw distance and more. The HUD rides a head-locked plane and can be hidden entirely. Mouse look is available for desktop play, with a sensitivity slider in both menus.

Cutscenes and the file select play on the virtual screen, because scripted camera sweeps read as motion sickness in stereo - a **Stereo Cutscenes** toggle opts back in. **Match Refresh Rate** defaults on, so the game paces at the headset's native rate. Comfort extras (turn vignette, horizon lock) are still planned.

## How to play
Start your VR runtime first - **Quest Link, Virtual Desktop or SteamVR** - then launch with **Start in VR** in the Hub, or the **Banjo-Kazooie VR** desktop shortcut.

## Updating
Re-run the installer. It fetches the newest release and replaces the app files; your saves, settings and the generated `bk.o2r` stay in place.

## Credits
Banjo-Kazooie is by **Rare**. The **Lighthouse** PC port is by **Harbour Masters** (lead developer Malkierian). The VR port is by **RaYRoD**, who has other open-source retro VR ports too (Super Mario 64, Mario Kart 64, Star Fox 64, Sonic Robo Blast 2, Ring Racers):

https://rayrodtv.com/

https://github.com/RaYRoD-TV/BanjoKazooie-VR
## Key points from updates
- The headset now paces to the headset's own refresh rate, not the monitor's.
  If you switched Vsync off by hand to reach 72 Hz, you can switch it back on.
- **View Bob** now really stops the walking bob - you no longer have to turn
  off Immersive Camera and lose crouching and attacks with it.
- Diorama tracks your head one to one; it used to lag and felt sickening.
- First person: doors and warp pads no longer drop you facing the wrong way,
  carried items no longer cover your eyes, and pickups in tight spots or over
  wading water collect again.
- Romhacks and texture packs render properly, and a hack's levels come up in
  3D instead of on a flat screen.
