# Call of Duty 4 VR Installer

## About this mod
**KisakCOD VR** by jplakon is a single-player OpenXR VR conversion of the **original 2007** Call of Duty 4: Modern Warfare. It adds stereoscopic rendering, 6DoF headset tracking, motion-controller weapon aiming, physical sniper scopes, VR-placed HUD elements and a pile of campaign-specific compatibility fixes. It is built on [KisakCOD](https://github.com/SwagSoftware/KisakCOD), a reimplementation of the original engine, and ships no Call of Duty game data at all - maps, fastfiles and `iw3sp.exe` come from your own installation.

*Aim with your hands, shoulder the rifle, and go loud.*

https://github.com/jplakon/CallOfDuty4_VR

## What you need first
- The **original 2007** Call of Duty 4: Modern Warfare (Steam AppID 7940). Modern Warfare Remastered is a different game and does not work.
- The flat game started **once** before installing.
- Windows 10 or 11, a PC VR headset with motion controllers, and a working OpenXR runtime.
- A VR-capable GPU. The author's test rig is a Quest 3 over Virtual Desktop's OpenXR runtime on an RTX 3080 Ti; everything else is experimental until users report back.

## Controls
Quest Touch bindings. Other OpenXR controllers may map differently.

| Action | Binding |
|---|---|
| Move | [[Left Stick]] - movement follows where you look |
| Snap turn | [[Right Stick]] left / right |
| Fire | [[Right Trigger]] |
| Aim / scope | Hold [[Left Grip]] and physically shoulder the weapon |
| Reload | [[Left Trigger]] |
| Jump | [[A]] |
| Use / interact | [[X]] |
| Sprint | Click [[Left Stick]] |
| Crouch | Tap [[B]] |
| Prone | Hold [[B]] |
| Melee | Click [[Right Stick]] |
| Frag grenade | Hold [[Y]] for 0.3 s, release to throw |
| Flashbang / tactical | [[Right Grip]] |
| Next weapon | Tap [[Y]] |
| Night vision | [[Right Stick]] down |
| Rifle grenade launcher | [[Right Stick]] up |
| Pause / menu | [[Left Menu]] |

**Mission controls:** touch and hold the [[Right Thumbrest]], then push [[Left Stick]] - up for the grenade launcher, down for night vision, left for an airstrike, right for C4. Normal movement is suspended while you hold it.

**Javelin and Stinger:** aim with the right controller, hold [[Left Grip]], bring the weapon to eye level, wait for the lock, then fire with [[Right Trigger]]. Mounted and vehicle weapons work the same way.

## Launching
The VR build **only** starts through `Launch-KisakCOD-VR.bat`, which loads the settings and then runs `KisakCOD-sp.exe` with the console variables the mod needs. Starting the game from Steam does not start the VR build.

Use **Start in VR** in the Hub or the desktop shortcut the installer creates - both point at that launcher. Start your OpenXR runtime before launching.

## If the game says d3dx9d_43.dll is missing
This one is not your fault and not a broken install. The mod's binary links against `d3dx9d_43.dll` - the **debug** build of Microsoft's D3DX9 library (note the extra `d`). Microsoft does not put debug D3DX in the DirectX End-User Runtime and does not permit shipping it with a product, so no game, no DirectX installer and no Windows update ever places that file on your PC.

Two things that do **not** work, so you don't waste time on them:
- Renaming `d3dx9_43.dll` to `d3dx9d_43.dll`. Different library, different exports - the game still won't start.
- Reinstalling DirectX. The file is not in that package by design.

The installer handles it: it pulls the DLL out of **Microsoft's own `Microsoft.DXSDK.D3DX` NuGet package**, which contains the signed debug DLLs, and drops it next to `iw3sp.exe`. If that download fails it checks your Downloads and Desktop folders, and finally offers a manual route where you can drag the file or a ZIP containing it onto the window.

To do it by hand: put `d3dx9d_43.dll` (32-bit) into the Call of Duty 4 folder, next to `iw3sp.exe`.

## Performance and calibration

**Start in the configurator.** Since v0.10.0-beta.7 the package ships
`KisakCOD-VR-Configurator.exe` in the game folder - a graphical settings app.
Since v0.10.0-beta.12 a second tool sits beside it, `KisakCOD-VR-Input-Mapper.exe`: the configurator covers VR and graphics, the input mapper covers the controller layout.
Pick a preset (**Tested Quest 3**, Performance, Comfort Snap, Smooth Turn,
Seated, Minimal HUD) or set things individually: snap and smooth turning,
movement direction, graphics, HUD and game text, compass size, direction and
placement, weapon and hand fit, belt and grenade calibration, manual or
automatic reload, physical scope alignment, and the face-button roles. HUD
placement and the controller-local weapon, hand and belt changes have visual
previews, settings are checked before saving, and **Save & Launch** starts the
game straight from the app.

Your profile is stored under `%LOCALAPPDATA%`, not in the game folder, so a
package update keeps it. It is backed up automatically and can be exported and
imported.

Physical magazine reloading can be switched off there if you prefer COD4's own
automatic reload.

**The plain-text route still works.** `VR-Settings.bat` stays in the game folder
and the batch launcher uses the last saved profile. If you had hand-edited it
before an upgrade, the Hub installer keeps your old copy as
`VR-Settings.bat.hubprev` so you can import it in the configurator. Fully
restart the game after editing the file by hand.

| Setting | Default | What it does |
|---|---|---|
| `VR_CUSTOM_MODE` | `6016x2688` | Render mode. Demanding - the documented lower fallback is `3072x1536` |
| `KISAK_VR_BRIGHTNESS` | `0.60` | Image brightness |
| `KISAK_VR_SHADOWS` | `1` | Synchronised dynamic shadows. Set to 0 if they cost too much or corrupt |
| `KISAK_VR_FSR` | `0` | Upscaling |
| `KISAK_VR_SCOPE_*` | see file | Physical scope placement in metres - forward, left, up, radius |
| `KISAK_VR_HUD_SAFE_X/Y` | `0.50` / `1.0` | HUD placement; a lower X moves the ammo/action HUD right |
| `KISAK_VR_COMPASS_INSET_X/Y` | `220` / `48` | Compass inset in pixels |

`Launch-KisakCOD-VR-Diagnostics.bat` starts the same game with developer messages restored - useful when writing a bug report.

## New in beta.14 and beta.15
- **The legacy flat crosshair is gone in VR**, even on an older profile that kept
  `cg_drawCrosshair 1`. Mission Select artwork and text now use the same eye-local
  geometry, and the Quit dialogs are centred in both eyes.
- **Air support in Safehouse and Heat follows your right controller** - the
  targeting ray, the marker and the strike placement. The handheld device model
  itself stays invisible; that is cosmetic, the targeting works.
- **The Configurator can be resized**, maximised and restored, and asks for a real
  1160x750 client area so Windows DPI and theme metrics can no longer clip the
  controls along the right and bottom edges.
- A **Pimax Crystal Light Full FOV** preset was added (7924x4082 packed: two
  3450x4082 eyes plus the 1024-pixel scope panel). The older cropped preset stays,
  Quest modes are untouched. **Real Pimax confirmation is still pending** - the
  author asks testers for it.
- beta.15 adds Index/OpenVR hand and squeeze work, right-safe ammo and grenade
  counters, a suppressed oversized in-headset error overlay, canonical 4:3 menus,
  and **yaw-only startup and recentring that rejects an unstable pose instead of
  inventing one**.

**The author also ships a guided Windows Setup now.** The Hub keeps using the
portable ZIP: both are built from the same deterministic payload, and the ZIP
needs no installer, no elevation and no unsigned-publisher warning. Your settings
live under `%LOCALAPPDATA%\KisakCOD-VR` either way and survive an update.

## Known limitations
- **Death From Above is not playable in VR and must be skipped.** It looks unlocked - do not pick it. Open the console and run `/spmap bog_b` to continue with **War Pig**.
- New Game starts at **Crew Expendable** on purpose - the F.N.G. training mission performs poorly in VR.
- Some original post-processing and camera animation is suppressed because it is uncomfortable or wrong in VR.
- Scope alignment can need small headset-specific tweaks - the configurator has a physical scope alignment section for it.
- COD4 has scripted mission events that use the flat-screen view ray. Many are bridged, but an untested checkpoint can still misbehave.

## Reporting a bug
Use the GitHub issue form and include the mod version and the commit from `SOURCE.txt`, your headset and OpenXR runtime, GPU and CPU, the mission and checkpoint, reproduction steps, and the relevant lines from `main\console.log`. Death From Above is a known limitation, not a new bug.

## Credits
- **KisakCOD VR** by jplakon - https://github.com/jplakon/CallOfDuty4_VR
- Built on **KisakCOD** by SwagSoftware
- The Khronos OpenXR project, and the Tracy Profiler among the retained upstream dependencies
- Call of Duty 4 and its assets by Infinity Ward / Activision

KisakCOD and this derivative are distributed under the GNU General Public License version 3. This is an independently developed mod and not an official Call of Duty product.
## Key points from updates
- The Windows package now carries the matching 32-bit Steamworks, Bink and
  Miles runtimes, which fixes clean-install failures around steam_api.dll and
  the mss32.dll entry-point error.
- **Tracked left hand and physical reloading:** eject with right A, reach to
  your left hip, hold the left grip to draw a magazine, release it inside the
  magazine well to insert it. Shotguns, launchers and bolt-action rifles keep
  the classic reload on right A.
- Physical reloading can be switched off with `KISAK_VR_MANUAL_RELOAD=0` in
  `VR-Settings.bat`.
- Mission shortcuts sit on the right thumbrest: hold it and push the left
  stick for night vision, airstrike, C4 or the grenade launcher.
- Death From Above is still unsupported and has to be skipped.
