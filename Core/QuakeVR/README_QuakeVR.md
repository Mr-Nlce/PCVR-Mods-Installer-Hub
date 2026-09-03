# Quake VR Installer

<!-- hub:keep-order -->

**Two VR builds exist for Quake**, and the installer asks which one you want. They are
separate projects by separate authors, each in its own folder, so both can be installed.

| | |
|---|---|
| **1. Quake VR** by Vittorio Romeo | its own VR design - physical weapon handling, reworked feel |
| **2. Quake PCVR** by GameOrDie007 | Team Beef's QuakeQuest brought to PC, plays like the Quest version |

---

## Mod 1 — Quake VR — by Vittorio Romeo

Automated installer for **Quake VR** by Vittorio Romeo — a QuakeSpasm-based VR port of **Quake (Enhanced)** with full motion controls, room-scale movement, and SteamVR/OpenVR support.

### What it installs
- **Quake VR v0.0.8.1** — downloaded fresh from the official GitHub release (never bundled)
- Automatically copies **PAK0.PAK** and **PAK1.PAK** from your **Quake (Enhanced)** install (Steam or GOG)
- Optionally installs the Microsoft Visual C++ x64 Redistributable runtime
- Optionally copies the Enhanced soundtrack (`rerelease\id1\music`) if present

### Requirements
- **Quake (Enhanced)** owned and installed — Steam **AppID 2310** (folder `Quake`), or GOG
- SteamVR (the game uses the OpenVR runtime)
- Motion controllers (developed and tested primarily on Valve Index)

### Source verification
- Mod download: https://github.com/vittorioromeo/quakevr/releases/download/v0.0.8.1/quakevr_v0.0.8.1.7z
- Info / project page: https://github.com/vittorioromeo/quakevr
- Launch executable: `quakevr.exe` (confirmed in the release archive and the project README)
- Quake Steam AppID **2310** (Valve Steam Application IDs list, SteamDB, PCGamingWiki)
- GOG install folder **`Quake`** — default `C:\GOG Games\Quake` (GOG Support Center, GOG.com forum)

### Install layout
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

### How to use
Click **Install Mod** on the Quake VR tile (or its detail page) and follow the prompts. The installer locates Quake, downloads the VR build, extracts it, copies the base PAKs, and creates a desktop shortcut.

### Launching
1. Start **SteamVR** first.
2. Launch with **Start in VR** in the Hub, or the **Quake VR** desktop shortcut.
3. On first run, open **SteamVR → Controller Bindings** and confirm both action sets (in-game + menu) are mapped to your controllers.
4. In **Quake VR Settings**: calibrate height, tune the VR torso + holster hotspots, and review Immersion Settings.

SteamVR Theatre Mode must be **OFF**: SteamVR → Settings → Dashboard → "Present Non-VR Applications as Floating Screens" → OFF.

### Controls (typical motion-control layout)

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

### Mission packs (optional)
The Enhanced release already includes both official mission packs. To play them in Quake VR, copy `PAK0.PAK` from the `hipnotic` folder (rename to `PAK2.PAK`) and/or from `rogue` (rename to `PAK3.PAK`) into the `Id1` folder, then use "Change Map" under Quake VR Settings.

### Credits
- **Quake VR** by Vittorio Romeo — built on QuakeSpasm / Quakespasm-Spiked and prior OpenVR ports (Fishbiter, Zackin5, Phoboslab)
- Hand models with finger tracking by CrazyHairGuy
- Support the project: https://ko-fi.com/vittorioromeo

### More info
https://github.com/vittorioromeo/quakevr

>>> The slipgate hums. Grab the shotgun — the Shamblers are waiting.


---

## Mod 2 — Quake PCVR — by GameOrDie007

Team Beef's **QuakeQuest** - the standalone VR Quake for Quest headsets - ported to PCVR
over OpenXR. This is Simon Brown's VR work brought across from the exact DarkPlaces commit
his Android build forked, with nothing changed except what PC requires. If you have played
QuakeQuest on a Quest, this plays identically, at whatever resolution your PC can drive.

### What it does

Everything QuakeQuest does: stereo, head tracking, room scale, the weapon in hand, the
weapon wheel, haptics, the big-screen menus, snap and smooth turning.

**All six games reachable in the headset from Single Player** - Quake, Scourge of Armagon,
Dissolution of Eternity, Dimension of the Past, Dimension of the Machine and Dawn of the
Machine - without going back to the desktop.

A **PC Options page** adds supersampling, anti-aliasing, particle style (the red blood
switch), the door Z-fighting fix, HUD height and what the desktop window does. Every option
defaults to Team Beef's own value, so an untouched install behaves exactly as their game.

The **desktop mirror** is borderless full screen by default, Alt+Enter for a window,
resizable, and cropped to the shape of your monitor rather than squashed into it.

### What the installer does

It puts the build in a folder of its own - by default `C:\Games\Quake PCVR` - and never
writes into your Quake install. Config, saves and screenshots all live inside that folder,
so backing it up backs up everything.

The Hub then finds your owned Steam or GOG copy automatically and copies `pak0.pak`,
`pak1.pak`, every expansion it finds and the re-release soundtrack into the PCVR folder.
Nothing is downloaded and nothing leaves your machine. If automatic detection fails, it
asks once for the Quake folder and verifies both base PAKs before reporting success.

**Python 3 and Pillow are not required to play.** When they are already installed, the Hub
also runs the author's optional generators for decorated menu artwork and episode message
text. Without them the game is fully playable and uses plain-text menus.

### Before you launch

**Start Virtual Desktop and connect it first**, so VDXR is the running OpenXR runtime. The
author developed and confirmed this on a Quest 3 over Virtual Desktop at 3993x4243 per eye,
72 Hz. SteamVR and the Oculus runtime expose OpenXR too and should work, but he has not
tested them.

Then use **Start in VR** on the Quake page and choose the Team Beef port.
Use **Open in Steam** when you want the original flat Quake.

### Your own game data

**None is included and none ever will be.** The 2021 re-release on Steam or GOG is the
easiest source - it has Quake, both mission packs and the additional official episodes, and
the Hub finds and adds them for you.

### Known issues

- **The in-game Mods browser drops out of VR.** Changing gamedir ends in `vid_restart`,
  which destroys the GL context the OpenXR swapchain images belong to. Use the Single Player
  game list instead - it relaunches the process, which is why it works.
- **Sixteen messages in the MachineGames episodes** show a readable placeholder instead of
  their real wording; that text exists only inside the re-release's own engine. Everything
  else, including every ending, is real.
- **Black blood is Team Beef's own behaviour**, not a porting defect - the author verified
  it three ways, including against their standalone on a Quest. PC Options has a switch that
  turns blood back to classic red.

### Flat play and removal

Both Quake VR choices are self-contained and never install a loader into the
retail Quake folder. Consequently no game-folder Flat/VR toggle is necessary:
**Start in VR** launches the selected standalone build and **Open in Steam**
launches original flat Quake.

**Uninstall now** lists the Vittorio Romeo and Team Beef builds separately.
Only the selected build's audited runtime files and Hub markers are removed.
Copied licensed PAKs, saves, settings, screenshots, music, custom maps and
unknown files remain in the standalone folder.

### Credits

**Team Beef / Simon Brown** for all of the VR work. **LordHavoc and the Xonotic project**
for DarkPlaces. **id Software** for Quake. GPL v2, the same as both.
