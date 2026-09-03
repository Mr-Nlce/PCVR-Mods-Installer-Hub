# GTA Vice City VR Installer

Automated installer for **Vice City VR** by #yevhen4817 - a native OpenXR VR adaptation of **Grand Theft Auto: Vice City (2003)**, built on the reverse-engineered **reVC** codebase and the **librw** RenderWare reimplementation. It keeps the original game, missions and data, and replaces the renderer while adding tracked-headset and motion-controller gameplay.

> **Early alpha.** The complete campaign has not been played through on the release configuration yet. Back up any saves you care about before you start.

## What it does
- Resolves the newest release from GitHub, so the Hub can flag updates and re-running the installer updates in place.
- Locates your Vice City install (Steam library, Rockstar/retail, GOG, with a manual drag & drop fallback), then merges `reVC.exe`, its runtime DLLs and `models\vrhands` into the game folder next to `gta-vc.exe`.
- Optionally installs the prebuilt **HD Models Pack** with a visible extraction percentage.
- **`gta-vc.exe` is never replaced or modified** - the flat game keeps working exactly as before.

## What works
- Native OpenXR with 6DOF head tracking and stereoscopic rendering
- Tracked VR hands with per-hand and per-weapon calibration
- Motion-controlled firearms: independent triggers, dual wielding, two-handed grips, hand-offs, and toss-and-catch weapon transfers
- Physical punching and melee with bats, blades, the chainsaw and other supported weapons
- Physical grenade and Molotov throwing with a trajectory preview, plus an opposite-hand remote detonator
- Physical scopes and a usable mission camera; scoped shots converge on the headset reticle
- Configurable body holsters and optional physical magazine reloads
- Motion-controller movement and vehicle controls, sprint, recentering, and an adjustable driving-height offset
- In-headset settings, weapon calibration, holster loadout, diagnostics and cheat menus
- World-locked theater presentation for startup movies, menus, loading transitions and cutscenes
- A Direct3D 12 renderer with single-pass stereo, fixed foveated rendering via D3D12 VRS, supersampling, and NVIDIA DLAA

## Requirements
- **Windows 10/11 64-bit**
- A **Direct3D 12-capable GPU**
- Your own **legal PC copy of Grand Theft Auto: Vice City (2003)**, including its original `anim`, `audio`, `data`, `models`, `movies` and `TEXT` folders. The mod ships no game data.
- A PC VR headset with an **active OpenXR runtime**
- **Microsoft Visual C++ 2015-2022 Redistributable (x64)** - the installer checks for it and links the official Microsoft download if it is missing

> **Meta Quest 3 through Quest Link or Air Link is the modder's primary tested setup.** The mod uses OpenXR and does not need the legacy Oculus PC SDK. Other PC OpenXR headsets may work but have not had the same testing. **NVIDIA DLAA** additionally needs a compatible RTX GPU and a current driver; a non-DLAA anti-aliasing path is available on other hardware.

## New in 0.5.2-alpha

**Cutscenes and menus run at full rate on SteamVR again.** They used to drop to
about 15 fps: SteamVR throttles a session that stops submitting stereo frames,
and flat content on the theatre screen counted as stopping. The screen is now
drawn through a real stereo pass, so the session is never throttled. Other
runtimes keep their proven path. If it causes trouble, set
`CinemaProjection=0` under `[VR]` in `vr_settings.ini` to go back.

**An experimental immersive HUD.** Minimap, status and clock can sit on real
stereo wrist panels, with separate placement per hand, side and for
foot/car/bike. The head-locked **Classic HUD stays the default**, and every
panel falls back to its Classic copy if its anchor is unavailable.
Motorcycles now use the **right trigger** for throttle by default; the physical
wrist-twist is still there, in Vehicle Settings.

**`PREPARE_MODERN_MODELS.bat` does the HD model job for you.** It asks for your
legal Vice City install, fetches and verifies the two source packs, builds into
a staging folder, validates the result and only then replaces
`modelsets\modern`. The manual route below still works and is what the Hub
installer uses.

Also worth knowing: a save that cannot be written now **says so** instead of
reporting success into an empty slot list, and falls back to
`Documents\GTA Vice City User Files`. Nine memory leaks in the D3D12 backend
were fixed, so long sessions no longer creep upward.

### Three escape hatches in `vr_settings.ini`
| Key | When you need it |
|---|---|
| `CinemaProjection=0` | the new SteamVR cutscene path misbehaves |
| `StreamlineEnabled=0` | black frames from DLSS/Streamline (seen on some VDXR setups) - DLAA is off in that mode |
| `LegacyGamepad=1` | you have a real wheel or pad that the mod now ignores by default. It ignores legacy DirectInput devices because phantom HID gear fed constant input under the VR sticks |

## Optional HD Models Pack

At the end of installation, press **Enter** when the installer offers the HD
Models Pack. It opens the Google Drive page for
`GTA VC VR Prebuilt HD Models.zip`. Download the ZIP, wait until it has fully
finished, then return to the installer and press **Enter**. The Hub checks the
Downloads folder, asks before using the file it found, and otherwise accepts
the ZIP by drag and drop.

The required payload is two folders deep inside the archive:

    GTA VC VR Prebuilt HD Models\modelsets\modern\models
    GTA VC VR Prebuilt HD Models\modelsets\modern\txd

The installer extracts the ZIP with a visible percentage, then merges the
contents of those two folders into the matching folders beside the executable:

    models\
    txd\
    gta-vc.exe

The `modelsets` and `modern` wrapper folders are not copied. If an HD file
replaces an existing game file, the original is preserved once beside it as
`<name>.hubbak`.

Download page:
https://drive.google.com/file/d/1aYSgzPE3UeA2_zuA_66eSf1ZhzCEgFMe/view?usp=sharing

## How to play
1. Select your headset software as the **active OpenXR runtime**, and connect the headset (Quest Link, Air Link, SteamVR or the equivalent) **before** launching.
2. Launch with **Start in VR** in the Hub, or use the **GTA Vice City VR** desktop shortcut the installer creates. Both run `reVC.exe`, which is the only build carrying the mod - launching Vice City from Steam gives you the normal flat game.
3. If the initial viewpoint is misaligned, press **both grips + both thumbstick clicks** to recenter.

## Controls (motion controllers)
- [[L-Stick]] move
- [[R-Stick]] turn / look / vehicle steering
- [[R3]] sprint on foot
- [[A]] [[B]] [[X]] [[Y]] enter and exit vehicles plus the normal game actions
- [[Grip]] near a body holster grabs that weapon; releasing the grip drops or throws it unless Grip Lock is on
- [[Trigger]] on the weapon hand fires
- [[Grip]] with the free hand at the saved foregrip position adds two-handed support
- Grab a weapon with the other hand to transfer it, or toss it and catch it
- **Punch:** close a free fist with [[Grip]] + [[Trigger]], then swing
- **Melee:** grab the weapon from its holster and swing physically
- **Throwables:** grab the center-chest slot and hold that hand's [[Trigger]] to aim the trajectory preview, then release to throw
- **Remote charges:** use the [[Trigger]] on the controller that appears in the opposite hand
- **Scopes:** bring the aligned weapon to your eye; long guns also need the support hand
- **Mission camera:** bring it to your eye and press its [[Trigger]]

> **Optional manual reloading** (off by default): when a supported gun runs empty, grab a magazine from that weapon's body position with the free hand and insert it into the magazine well. Currently supported on the **Colt .45, TEC-9, Uzi and Ingram**; every other firearm keeps the game's automatic reload.

## In-headset menus and shortcuts
- [[Both Grips]] + [[Menu]] open or close the VR settings
- [[Both Grips]] + [[B]] open or close the cheat menu
- [[Both Grips]] + [[A]] toggle the debug overlay
- [[Both Grips]] + [[Y]] start or stop a performance capture
- [[Both Grips]] + [[L3]] + [[R3]] recenter the gameplay view
- [[Both Grips]] + [[L3]] + [[L2]] toggle the FULL and hybrid stereo diagnostic modes
- [[Both Grips]] + [[R3]] + [[R2]] cycle the fixed-foveated VRS profile

Inside a VR menu: [[L-Stick]] selects an entry, [[L2]] and [[R2]] decrease or increase a value, [[A]] opens or selects, [[B]] goes back or closes.

> **Defaults worth knowing.** The gameplay HUD is controlled only from VR settings and defaults to **off**, as do weapon lasers, body-holster highlights and manual reloading. Physical scopes default to **on**. The default driving Y offset is **+15 cm**.

## Settings files
VR configuration and per-weapon calibration live in `vr_settings.ini`; general reVC settings live in `reVC.ini`. Both are created beside the executable on first run and are **deliberately left out of the release archives**, so updating never erases your preferences. Do not copy either file from an older package over an existing install unless you intend to replace its settings and calibration.

## Known alpha limitations
- The complete campaign has not been played through on the release configuration
- Meta Quest 3 is the primary tested headset; bindings or runtime behaviour may need adjusting on other OpenXR devices
- Manual magazine reload covers only the four one-handed guns listed above
- Per-hand weapon calibration stays exposed because some headset/controller combinations need small alignment tweaks
- Original executable plugins (ASI modules, CLEO scripts, binary limit adjusters) are **not** compatible unless separately ported to reVC
- Save compatibility between unrelated reVC forks or substantially different builds is not guaranteed - keep backups during alpha testing

## Troubleshooting
- **Headset stays in the home environment or shows a black screen:** confirm your headset software is the active OpenXR runtime, and start Link / Air Link / the PC VR runtime **before** `reVC.exe`. Check `openxr_d3d12.log` next to the executable.
- **A runtime DLL is missing:** re-run this installer so the complete archive is extracted - never copy `reVC.exe` alone. If Windows names `MSVCP140.dll` or `VCRUNTIME140.dll`, install the Microsoft Visual C++ 2015-2022 Redistributable (x64).
- **DLAA unavailable:** update your NVIDIA driver and use a supported RTX GPU, or pick the fallback anti-aliasing option in VR settings.
- **Viewpoint offset:** recenter with both grips + [[L3]] + [[R3]], and adjust Driving Y Offset in VR settings for vehicle comfort.

## Credits
- **Vice City VR** by #yevhen4817 (Discord)
- **re3 / reVC** contributors for the reverse-engineered game code, and **librw** contributors for the RenderWare-compatible renderer
- Khronos Group for OpenXR, Microsoft for Direct3D 12, NVIDIA for Streamline and DLSS/DLAA
- OpenAL Soft and mpg123 contributors for audio support
- VRMADA for the UltimateXR hand assets, used under the MIT License
- Grand Theft Auto and Vice City are Rockstar Games trademarks; this project is not affiliated with Rockstar Games or Take-Two.

Project page:

https://github.com/dubrovskiy-yevhen-stakelogic/vice-city-vr
## Key points from updates
- **Head Directed locomotion** is now the default on fresh installs: Tommy
  faces where you actually move, without assisted camera turning or sideways
  running animations.
- Radio station names, mission instructions and objective updates are back as
  VR HUD messages.
- Optional weapon haptics with adjustable recoil strength, and separate
  driving modes for cars and motorcycles.
- Walking head bob can be switched off (off by default on fresh installs), and
  graphics settings have their own submenu.
- The RPG scope's black rectangle is replaced by a VR-safe reticle, and the
  PSG-1 centre dot is back.
- Existing settings and your weapon, HUD, holster, hand and vehicle
  calibrations survive the update.
