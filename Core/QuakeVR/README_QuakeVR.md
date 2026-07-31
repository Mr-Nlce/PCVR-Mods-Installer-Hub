# Quake VR Installer

Automated installer for **Quake VR v0.0.8.1** by Vittorio Romeo — a QuakeSpasm-based VR port of **Quake (Enhanced)** with full motion controls, room-scale movement, and SteamVR/OpenVR support.

## What it installs
- **Quake VR v0.0.8.1** — downloaded fresh from the official GitHub release (never bundled)
- Automatically copies **PAK0.PAK** and **PAK1.PAK** from your **Quake (Enhanced)** install (Steam or GOG)
- Optionally installs the Microsoft Visual C++ x64 Redistributable runtime
- Optionally copies the Enhanced soundtrack (`rerelease\id1\music`) if present

## Requirements
- **Quake (Enhanced)** owned and installed — Steam **AppID 2310** (folder `Quake`), or GOG
- SteamVR (the game uses the OpenVR runtime)
- Motion controllers (developed and tested primarily on Valve Index)

## Source verification
- Mod download: https://github.com/vittorioromeo/quakevr/releases/download/v0.0.8.1/quakevr_v0.0.8.1.7z
- Info / project page: https://github.com/vittorioromeo/quakevr
- Launch executable: `quakevr.exe` (confirmed in the release archive and the project README)
- Quake Steam AppID **2310** (Valve Steam Application IDs list, SteamDB, PCGamingWiki)
- GOG install folder **`Quake`** — default `C:\GOG Games\Quake` (GOG Support Center, GOG.com forum)

## Install layout
The installer creates a self-contained folder under `C:\Games` (or the first writable drive root — `D:\Games`, `E:\Games`), **not** inside the Steam library:

```
C:\Games\Quake VR\
  quakevr.exe              <- launch executable
  openvr_api.dll, SDL2.dll, ...
  actions.json, bindings_*.json
  Id1\
    pak10.pak  pak11.pak  pak12.pak   (shipped with Quake VR)
    PAK0.PAK   PAK1.PAK               (copied from your Quake install)
    maps\  textures\  config.cfg
```

> Load order is by PAK number — the base-game `PAK0`/`PAK1` load before the Quake VR `pak10`–`pak12`. You can add mission-pack PAKs (`PAK2`, `PAK3`) before the VR PAKs if you own them; the Enhanced release already bundles both mission packs.

## How to use
Click **Install Mod** on the Quake VR tile (or its detail page) and follow the prompts. The installer locates Quake, downloads the VR build, extracts it, copies the base PAKs, and creates a desktop shortcut.

## Launching
1. Start **SteamVR** first.
2. Launch with **Start in VR** in the Hub, or the **Quake VR** desktop shortcut.
3. On first run, open **SteamVR → Controller Bindings** and confirm both action sets (in-game + menu) are mapped to your controllers.
4. In **Quake VR Settings**: calibrate height, tune the VR torso + holster hotspots, and review Immersion Settings.

SteamVR Theatre Mode must be **OFF**: SteamVR → Settings → Dashboard → "Present Non-VR Applications as Floating Screens" → OFF.

## Controls (typical motion-control layout)

> Quake VR uses the **SteamVR Input API**, so every action is bound and rebound in **SteamVR → Controller Bindings** — there is no fixed hard-coded button map. The tables below show a typical, comfortable starting layout and the in-game actions you will assign. Adjust to taste.

### Right Controller
| Button | Action |
|--------|--------|
| [[Trigger]] | Fire equipped weapon |
| [[Grip]] | Grab / draw weapon from a holster |
| [[A]] | Jump |
| [[B]] | Next weapon |
| [[Stick]] | Snap / smooth turn |
| [[Stick]] click | Recenter / calibrate |

### Left Controller
| Button | Action |
|--------|--------|
| [[Trigger]] | Off-hand action (dual-wield / grab) |
| [[Grip]] | Grab / draw weapon from a holster |
| [[X]] | Quick melee |
| [[Y]] | Menu / console |
| [[Stick]] | Smooth locomotion (move / strafe) |
| Menu | Game menu |

> Tune holster hotspots, turn style, and comfort options in **Quake VR Settings** before a long session.

## Mission packs (optional)
The Enhanced release already includes both official mission packs. To play them in Quake VR, copy `PAK0.PAK` from the `hipnotic` folder (rename to `PAK2.PAK`) and/or from `rogue` (rename to `PAK3.PAK`) into the `Id1` folder, then use "Change Map" under Quake VR Settings.

## Credits
- **Quake VR** by Vittorio Romeo — built on QuakeSpasm / Quakespasm-Spiked and prior OpenVR ports (Fishbiter, Zackin5, Phoboslab)
- Hand models with finger tracking by CrazyHairGuy
- Support the project: https://ko-fi.com/vittorioromeo

## More info
https://github.com/vittorioromeo/quakevr

>>> The slipgate hums. Grab the shotgun — the Shamblers are waiting.
