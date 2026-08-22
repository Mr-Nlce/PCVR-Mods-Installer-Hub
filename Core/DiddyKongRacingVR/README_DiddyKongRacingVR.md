# Diddy Kong Racing VR Installer

Automated installer for **DiddyKongRacing-VR** by RaYRoD - a native OpenXR VR build of **Golden Balloon**, akratch's PC port of **Diddy Kong Racing** (Nintendo 64, 1997). The whole game renders inside the headset with full head tracking. Headset on, it boots straight into VR; headset off, it is the normal flat game.

## How this is installed

**There are no downloads on the project page.** In the author's own words:
*no builds here, the hub is the one spot for all of it, source included.*

So there is one route, and the installer takes it for you: it fetches
**RaYRoD-TV's Multiverse VR Hub**, one small app that carries all of his VR
ports and keeps them updated. You choose where it goes
(`C:\Games\Multiverse VR Hub` by default). Open it, pick Diddy Kong Racing, hit
Play - it grabs the official Golden Balloon release, applies the VR patch
itself, and asks for your ROM once.

**Start in VR** in the PCVR Hub opens that app from then on, not the game.

**The Hub checks the download for you.** RaYRoD-TV publishes a SHA-256 checksum
with every release and asks people to verify it with `certutil`. The installer
does that step itself: it reads the checksum out of his release note, hashes the
file it just downloaded, and shows both side by side. If they do not match it
stops and installs nothing.

The game stays on your own PC, and you bring your own ROM.

## You provide the ROM
Nothing from Nintendo is included or downloaded. You supply your own dump, and it never leaves your PC.

| | |
|---|---|
| Platform | **Nintendo 64** - not Xbox 360, not Rare Replay, not Nintendo Switch Online |
| File | a `.z64`, `.v64` or `.n64` ROM dump |
| Version | **US 1.1** or **EU 1.1** |

Golden Balloon recognises the other revisions (JP, US 1.0, EU 1.0) and refuses them by name, so a wrong dump tells you what it is instead of failing oddly. Not sure which one you have? The port author's checker names the release in your browser, with nothing uploaded:

https://akratch.github.io/golden-balloon/rom-check.html

RaYRoD-TV's app asks for the ROM once and remembers it.

## View modes
[[D-Pad Up]] cycles them mid-race, and each mode keeps its own settings:

- **Third Person** - the classic chase camera, at life size
- **First Person** - you are in the driver's seat; seat height and slide are yours to move
- **Diorama** - the whole track shrunk to a tabletop sitting in front of you
- **Theater** - the flat game on a big virtual screen, maximum comfort

## Controls
Motion controllers are mapped to the N64 pad, rumble included. A gamepad or keyboard keeps working alongside them.

- [[D-Pad Up]] cycle the four view modes
- [[Y]] hold to look behind you in First Person ([[L3]] does the same)

## VR options
A VR menu sits inside the game's own pause menu: world size, stereo depth, seat height, camera distance, HUD size and distance, and more. Every knob moves the world live while you change it - nothing needs a restart.

Right next to it is a **cheats page**: unlock everything with one press, plus the magic codes (max power-ups, no banana limit, high speed, mirror tracks, brutal AI and the rest).

## How to play
Start your VR runtime first - it runs on any PCVR / OpenXR runtime (**Quest Link, Virtual Desktop or SteamVR**) - then launch with **Start in VR** in the Hub, which opens the Multiverse VR Hub, and hit Play there.

Put the headset on before the game finishes loading: with a headset answering it boots straight into VR, without one it starts flat.

## Updating
RaYRoD-TV's app keeps the port up to date itself - open it and it handles the rest. Re-running this installer only refreshes the app.

## Credits
Diddy Kong Racing is by **Rare**. The **Golden Balloon** PC port is by **akratch**, built on the community decompilation. The VR port is by **RaYRoD**, who has other retro VR ports too (Super Mario 64, Mario Kart 64, Star Fox 64, Banjo-Kazooie, Sonic Robo Blast 2, Ring Racers):

https://rayrodtv.com/

https://github.com/RaYRoD-TV/DiddyKongRacing-VR

https://github.com/akratch/goldenballoon

You bring your own legally owned ROM; nothing from Rare or Nintendo is included or distributed, and no ownership is claimed of their intellectual property.

>>> Car, hovercraft or plane - Wizpig laughs at all three.
