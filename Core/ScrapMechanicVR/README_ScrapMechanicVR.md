# Scrap Mechanic VR - Native VR

**Scrap Mechanic Native VR** by **21Suspect** - an experimental **native** OpenXR conversion for Scrap Mechanic Survival. Stereoscopic rendering, tracked hands and tools, Touch-controller locomotion, optical hand tracking, VR interaction rays and spatial menus.

> **The patcher does the patching.** The mod ships as a single guarded `ScrapMechanicVR-Patcher.exe`. The Hub installer fetches the newest one straight from the GitHub release, **checks its SHA-256 against the checksum published with that release**, and hands over to it. You still click **Install VR Mod** and approve the admin prompt yourself - the patcher is interactive by design.

## Build lock - read this first
The patcher supports **Steam build 22163681 only** and deliberately refuses unknown builds rather than applying renderer hooks that might not fit. That is a feature, not a limitation: a game update can invalidate native renderer hooks even when the Lua scripts look unchanged.

**Before you let Steam update Scrap Mechanic, run the patcher and choose Uninstall / Restore.** Otherwise you are left with patched files against an unpatched build.

## Requirements
- **Windows 10/11 x64**
- **Steam copy of Scrap Mechanic**, exact build **22163681**
- **Meta Quest 3** is the tested headset. Other OpenXR headsets are experimental.
- **Meta Quest Link or Air Link**, with **Meta Quest Link set as the active OpenXR runtime**
- A GPU that can render the game twice at your headset resolution

## Installing
1. Install or update Scrap Mechanic through Steam, then **close the game**.
2. Connect the Quest over Quest Link or Air Link and make **Meta Quest Link the active OpenXR runtime**.
3. Run the Hub installer. It finds the game, downloads the latest patcher into the game folder and verifies its checksum.
4. In the patcher window: select the Scrap Mechanic folder if it was not filled in, click ***Install VR Mod***, approve the administrator prompt, then close it.
5. Launch with ***Start in VR*** in the Hub.

The patcher is **unsigned**, so Windows SmartScreen may warn about an unknown publisher. That is expected for this mod. The Hub installer computes the SHA-256 of what it downloaded and compares it against the value the author publishes with the release - if they do not match it deletes the file and refuses to run it.

Worth knowing what that check is and is not: it proves the file arrived intact and is the one the author published, because the checksum comes from the release itself. It is not a signature and cannot prove who the author is.

## How to launch: "Start in VR" in the Hub
**Use **Start in VR** on the tile.** That is the whole point of the Hub installer: it wires the button straight to the mod's own launcher, so one click does the full VR startup.

The patcher's own **Start Scrap Mechanic VR** desktop shortcut does exactly the same thing and works just as well.

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

## Updating, repairing, uninstalling
Run `ScrapMechanicVR-Patcher.exe` again:

| Action | What it does |
|---|---|
| **Verify** | Checks every managed file |
| **Force Reset / Reinstall** | Restores a recognised older snapshot, then installs the current one |
| **Uninstall / Restore** | Restores the hash-verified original Steam files |
| **Open Logs** | Opens the installer diagnostics |

If you edited a managed file after installing, the patcher preserves your version under `%LOCALAPPDATA%\ScrapMechanicVR\conflicts` before restoring the original. Backups and transaction state live under `%LOCALAPPDATA%\ScrapMechanicVR`.

**To update, just re-run the Hub installer.** It always fetches the newest release, verifies it, and records the version - which is what drives the update badge on the tile.

## Performance
The game is rendered twice, once per eye, at your headset's resolution, on top of a game that was never built for it. Budget accordingly - this is the reason for the STRONG power rating rather than a gentler one.

## Uninstall
Run the patcher and choose **Uninstall / Restore**. It puts back the hash-verified original Steam files rather than guessing.

## Credits and legal
- **Scrap Mechanic Native VR** by 21Suspect
  https://github.com/21Suspect/Scrap-Mechanic-Native-VR
- Project code is MIT. Third-party components keep their own licences.
- Scrap Mechanic scripts, models, textures, names and screenshots remain the property of **Axolot Games** and are not relicensed.
- Unofficial community project - not affiliated with or endorsed by Axolot Games, Meta, Valve, Khronos or the ReShade project. You must own Scrap Mechanic.
