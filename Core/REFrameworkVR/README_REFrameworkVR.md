# REFramework VR Installer

Automated installer for **REFramework VR** by praydog — generic 6DOF VR
support for all RE Engine games. Always downloads the latest nightly build
from GitHub automatically.

## Features

- **Generic 6DOF VR** with full head tracking for any supported RE Engine
  title — stereoscopic 3D with real depth
- **Free camera**, **FOV slider**, **vignette disabler** and **timescale**
  controls, configurable live in the REFramework overlay
- **Full motion controls on every modern Resident Evil**: RE2, RE3, RE7 and
  RE8 Village via REFramework directly; RE4 and RE9 Requiem via Talemann's
  RE4VR / RE9VR add-on mods. Non-RE titles (e.g. DMC5, Monster Hunter) are
  gamepad-driven 6DOF
- **Lua scripting API** — the framework hooks the RE Engine runtime without
  modifying core game files, so it's safe and removable

## What it installs
- **REFramework.zip** — monolithic mod loader + VR support (dinput8.dll + supporting files)
- **VR.zip** — VR configuration and runtime files

Both are extracted directly into the game folder. Running the installer again updates to the latest nightly.

## Requirements
- The game owned on Steam
- SteamVR installed

## How to use
Click **Install Mod** on the game tile or detail page and follow the prompts.

## First launch
1. Start SteamVR
2. Launch the game via Steam normally
3. REFramework loads automatically — configure VR settings in its overlay menu

## More info
https://github.com/praydog/REFramework

## Supported games

- Devil May Cry 5
- Monster Hunter Rise
- Monster Hunter Wilds
- Monster Hunter Stories 3
- Street Fighter 6
- Dragon's Dogma 2
- Pragmata
- Mega Man Star Force Legacy Collection
- Ghosts 'n Goblins Resurrection
- Apollo Justice: Ace Attorney Trilogy
- Kunitsu-Gami: Path of the Goddess
- Onimusha 2: Samurai's Destiny

## Support praydog

praydog develops REFramework and the underlying VR support. If you enjoy his work, consider supporting him:
- Patreon: https://www.patreon.com/c/praydog
- Site: https://praydog.com/

>>> Capcom's nightmares, now close enough to touch.
