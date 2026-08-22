# F-Zero X VR Installer

Automated installer for **FZeroX-VR** by RaYRoD - a VR build of **G-Diffuser**, Zorkats' native PC port of **F-Zero X** (Nintendo 64, 1998). Real stereo at 900 km/h, 6DoF head tracking, Quest Touch support, and the whole circuit drawn out to the horizon.

## How this is installed

**There are no downloads on the project page.** In the author's own words:
*no builds here, the hub is the one spot for all of it, source included.*

So there is one route, and the installer takes it for you: it fetches
**RaYRoD-TV's Multiverse VR Hub**, one small app that carries all of his VR
ports and keeps them updated. You choose where it goes
(`C:\Games\Multiverse VR Hub` by default). Open it, pick F-Zero X, hit Play -
it grabs the official G-Diffuser release, applies the VR patch itself, and asks
for your ROM once. The game sets itself up from there.

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
| Platform | **Nintendo 64** - not the Switch Online release, not an emulator image |
| File | a `.z64`, `.n64` or `.v64` ROM dump, **16 MiB**, unmodified |
| Version | **US Rev 0** |

Other regions, other revisions and ROM hacks are **not supported** and may not work properly.

One detail worth knowing if a dump gets rejected: G-Diffuser itself only reads big-endian `.z64`. A `.n64` or `.v64` that RaYRoD-TV's app cannot convert has to be byte-swapped to `.z64` first.

## Camera modes
The **right stick** switches between the two camera modes. Motion controllers work through Quest Touch support, with 6DoF head tracking throughout.

- [[Right Stick]] switch camera mode

## VR options
A VR settings menu is built in, and every slider moves the world live while you drag it - nothing needs a restart.

## How to play
Start your VR runtime first, then launch with **Start in VR** in the Hub, which opens the Multiverse VR Hub, and hit Play there.

## Updating
RaYRoD-TV's app keeps the port up to date itself - open it and it handles the rest. Re-running this installer only refreshes the app.

## Credits
F-Zero X is by **Nintendo**. The **G-Diffuser** PC port is by **Zorkats**, built on the `inspectredc/fzerox` matching decompilation and libultraship. The VR port is by **RaYRoD**, who has other retro VR ports too (Super Mario 64, Mario Kart 64, Star Fox 64, Banjo-Kazooie, Diddy Kong Racing, Sonic Robo Blast 2, Ring Racers):

https://rayrodtv.com/

https://github.com/RaYRoD-TV/FZeroX-VR

https://github.com/Zorkats/G-Diffuser

You bring your own legally owned ROM; nothing from Nintendo is included or distributed, and no ownership is claimed of their intellectual property.

>>> Thirty machines, no brakes, one energy bar.
