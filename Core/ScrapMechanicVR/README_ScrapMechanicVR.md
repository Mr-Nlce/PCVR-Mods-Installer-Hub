# Scrap Mechanic VR - Native VR

**Scrap Mechanic Native VR** by **21Suspect** - an experimental **native** OpenXR conversion for Scrap Mechanic Survival. Stereoscopic rendering, tracked hands and tools, Touch-controller locomotion, optical hand tracking, VR interaction rays and spatial menus.

## Build lock

The mod only works on **Steam build 22163681** - its VR files hook the renderer
of that exact executable. That build was live from March until 24 July 2026, when
*Drilling Thunder* replaced it, and the mod came out one day before. On today's
Steam version it cannot work.

**So the Hub fetches that build as a separate copy** through the Steam Console,
into `C:\Games\Scrap Mechanic VR` or a folder of your choice, and puts the VR
files on it. **Your normal Steam install is not touched and keeps updating.**

The build comes in **two depots, both needed**, about 5 GB together - `387993`
has the executable, `387992` the data the game loads at startup. With only one
you get a half-sized folder that stops at *Failed to find game data directory*.
The installer walks you through both commands and merges them.

**No auto-update here.** The mod is tied to that one game build, so a newer mod
version will most likely need a different build and a new depot manifest - both
have to change together. The Hub pins **v1.17.0**.

## Requirements
- **Windows 10/11 x64**
- **Scrap Mechanic owned on Steam.** You do not need it installed - the installer
  downloads a separate copy of the exact build the mod needs (**22163681**)
  through the Steam Console. If you do have it installed, that copy is not touched.
- **Meta Quest 3** is the tested headset. Other OpenXR headsets are experimental.
- **Meta Quest Link or Air Link**, with **Meta Quest Link set as the active OpenXR runtime**
- A GPU that can render the game twice at your headset resolution

## Installing
1. Close Scrap Mechanic if it is running.
2. Connect the Quest over Quest Link or Air Link and make **Meta Quest Link the active OpenXR runtime**.
3. Run the Hub installer. It opens the Steam Console, hands you the two depot commands one after the other, merges the downloads, then copies the VR files onto that copy and writes the launcher.
4. Launch with ***Start in VR*** in the Hub, or from the **Scrap Mechanic VR** desktop shortcut the installer creates.

> **The mod's own patcher is not used.** It refuses any build other than
> 22163681 - sensible for it, pointless here, since the Hub brings exactly that
> build along. The VR payload is taken straight from the release archive and
> placed into that separate copy. Everything the mod changes - including nine of
> the game's own script files - lives in that one folder, which is why removing
> it later is just a matter of deleting the folder.

## How to launch: "Start in VR" in the Hub
**Use **Start in VR** on the tile.** That is the whole point of the Hub installer: it wires the button straight to the mod's own launcher, so one click does the full VR startup.

The **Scrap Mechanic VR** desktop shortcut the installer creates does exactly the same thing and works just as well.

What you must **not** do is launch Scrap Mechanic **from Steam**, or run `ScrapMechanic.exe` directly. Both skip the mod's launcher and give you the flat game. The launcher does several things the plain executable never will:

- Reads the **active OpenXR runtime** from the registry and refuses to continue if none is set
- **Starts the Meta client** and waits for Quest Link to come up (up to 90 seconds) - or starts SteamVR instead if a Steam runtime is active
- Sets **`VehicleCameraMode` to Strict Follow** in your Scrap Mechanic profile, backing up the original first
- Sets the Steam app-id environment variables the game expects, then starts the executable from its own `Release` folder

Skip that and you get the flat game, or nothing at all - which is why **Start in VR** points at the launcher and not at the executable.

## Controls
| Quest control | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Right Stick]] | Aim / turn; scroll an open menu |
| [[A]] | Jump; click / hold / drag in an open menu |
| [[B]] | Use / interact |
| [[Right Trigger]] | Primary action |
| [[Left Trigger]] | Secondary action |
| [[X]] / [[Y]] standing | Previous / next hotbar item |
| [[X]] + [[Y]] standing | Open backpack |
| [[X]] / [[Y]] seated | Zoom in / out |
| [[Left Menu]] | Pause / resume |
| [[Both Sticks]] hold 1s | Recenter view and floor |
| Optical pinch | Primary tool / menu interaction |
| Physical swing | Hammer attack |

## What works
- Native stereo OpenXR rendering with head tracking and a desktop eye mirror
- Quest Touch controllers **plus** Meta optical hand tracking
- Yaw-only, HMD-relative locomotion with snap or smooth turning
- Visible tracked hands, held tools, gun-barrel targeting, hammer swings, tool laser pointers
- Lift placement, block placement and removal, painting, welding, connection dragging, switches, buttons, guns, elevators
- Floating VR backpack; pause, options and the game's existing menus with pointer, click, hold and drag
- First-person seated play through Scrap Mechanic's Strict Follow Camera
- One-second two-thumbstick recenter for yaw, pitch, roll and floor alignment

The permanent health / food / water / hotbar HUD is **deliberately not** duplicated as a head-locked overlay.

## If something breaks

**There is nothing to update.** The mod is pinned to v1.17.0 and the game copy is
pinned to build 22163681 - that pairing is the whole point, so neither side moves.
The Hub does not check for newer releases here.

To **repair** a broken install, run the Hub installer again: it lays the VR files
back down over the copy in `C:\Games\Scrap Mechanic VR`. If the game copy itself
is damaged, delete that folder and run the installer again - it re-downloads both
depots.

## Performance
The game is rendered twice, once per eye, at your headset's resolution, on top of a game that was never built for it. Budget accordingly - this is the reason for the STRONG power rating rather than a gentler one.

## Credits and legal
- **Scrap Mechanic Native VR** by 21Suspect
  https://github.com/21Suspect/Scrap-Mechanic-Native-VR
- Project code is MIT. Third-party components keep their own licences.
- Scrap Mechanic scripts, models, textures, names and screenshots remain the property of **Axolot Games** and are not relicensed.
- Unofficial community project - not affiliated with or endorsed by Axolot Games, Meta, Valve, Khronos or the ReShade project. You must own Scrap Mechanic.
