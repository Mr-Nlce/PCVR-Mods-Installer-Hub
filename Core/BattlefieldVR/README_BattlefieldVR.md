# Battlefield 1942 VR (BFVR)

Stereoscopic VR, tracked-controller aiming, VR menus and comfort options for
Battlefield 1942. By **JayBiggsGMG**.

> **You need your own copy of the game.** Battlefield 1942 is not sold anywhere
> any more. The Hub never provides game files. Known-good builds are listed in
> [this community guide](https://steamcommunity.com/sharedfiles/filedetails/?id=2721068159)
> - the Moongamers Vulkan or DgVoodoo packages are the safe picks.

## Requirements
- A working, legally installed Battlefield 1942 on 64-bit Windows 10 or 11,
  containing `BF1942.exe`
- A PC VR headset with an active OpenXR runtime - Meta Quest Link, SteamVR, or
  Virtual Desktop's VDXR
- **BF42++ 2.0 RC6** or newer. This is a separate prerequisite and is **not**
  bundled with BFVR.

## About BF42++
Three files go next to `BF1942.exe`: `bf42++.dll` (414.208 B), `bf42++.exe`
(14.848 B) and `bf42++BlackScreen.exe` (16.384 B). The installer fetches them for
you from ModDB and checks all three by size afterwards.

**Some community packages already ship BF42++** as a recognised `dsound.dll`
proxy. In that case do **not** add a second copy - the installer detects it and
leaves it alone. If both are present anyway, BFVR 1.0.1 uses the bundled proxy
and ignores the extra `bf42++.dll` for that launch.

If BFVR reports an obsolete BF42Plus 1.3.4, remove that old `dsound.dll` and
install current BF42++ from its official page. That warning is a security check,
not a claim that anything has already gone wrong.

## What lands in the game folder
Everything goes into a new `BFVR\` subfolder - **68 files, and not one existing
game file is touched or replaced**:

- `BFVR\BFVR.exe`, `BFVRClient.dll`, `BFVRD3D8To9.dll`, `BFVRPresenter.exe`
- `BFVR\runtime\openxr\win64\openxr_loader.dll`
- `BFVR\UserConfig.txt` - your settings, with explanations for every entry
- `BFVR\assets\`, `docs\`, `licenses\`, and the mod's own uninstaller

## If the game sits under Program Files

Windows will not let BF42++ load itself into the game from a protected
folder. You get this on every launch:

    Failed to inject 'bf42++.dll' into 'BF1942.exe'

The installer offers the fix at the end: it ticks Windows' own **Run as
administrator** setting for `BFVR.exe` and `bf42++.exe`. From then on you get
**one UAC prompt** when you start, and the mod loads.

That setting applies to your Windows account only and changes nothing about the
game. Undo it any time in the file's Properties, Compatibility tab.

Installing the game somewhere like `C:\Games\Battlefield 1942` avoids the whole
issue - but there is no need to move an existing install just for this.

## How to launch - the order matters
1. Connect the headset and start its OpenXR software **first**.
2. Start the game with **Start in VR** in the Hub, or
   `Battlefield 1942\BFVR\BFVR.exe` in the game folder - **not** `BF1942.exe`.
3. Pick a map in Battlefield 1942's normal menus.
4. Quit through the game's own menus. BFVR and its presenter stop with the
   session.

Mouse and keyboard keep working, menus included.

## Controls (Touch-style defaults)

![Controller layout](ControllerLayout.jpg)

| | |
|---|---|
| Left stick | Move. Click keeps the game's contextual vehicle action |
| Right stick left/right | Turn. Click keeps the other vehicle action |
| Right stick up / down | Jump and parachute / toggle crouch |
| Right trigger | Fire, or click a menu item |
| Right grip | Aim down sights, or the game's alternate fire |
| Left trigger | Use and interact while held |
| Left grip | Two-handed weapon hold, where the weapon supports it |
| Right A | Hold for the Quick Menu, point, release to select |
| Right B | Reload. Hold 2.5 s to recenter forward |
| Left X / Y | Prone / hold the scoreboard |
| Left Menu | Toggle the map |

Vehicle, aircraft, turret and mounted-gun stick behaviour follows whatever you
are controlling.

**Index and Vive.** BFVR ships OpenXR bindings for Touch, Index, Vive Wands and
the simple-controller profile. Index has no default Map button - the named Map
action can be bound in SteamVR. Vive Wands use their trackpads; the limited
button count leaves Prone, Scoreboard and Reload unbound by default, and SteamVR
can remap BFVR's named actions.

## VR Settings
Hold right A, then open the VR Settings panel from the strip. It holds
seated/standing mode and manual height, snap or smooth turning with speed and
movement direction, recenter and standing-height calibration, comfort vignette,
aim inversion for vehicles and aircraft, controller vibration, two-hand grip
style, crosshair choices, and FXAA, sharpening, ambient occlusion, water
reflections and bloom.

Two aircraft options sit under Flight Pitch: **Aircraft Pitch + Roll on Same
Stick** and **Swap Aircraft Sticks**. Together they allow pitch/yaw or pitch/roll
on either controller, and they work with every controller profile because they
rearrange the axes after input is read.

Choose **Save** to apply. Some graphics settings say a BFVR restart is needed.
**Defaults** loads the release defaults into the menu until you save.

`UserConfig.txt` sits beside `BFVR.exe` and explains every setting. Edit it with
BFVR closed. Deleting it makes BFVR write a fresh default file on the next start.

## Multiplayer
BFVR keeps Battlefield 1942's normal simulation and networking, but it is still a
client-side executable mod. **Use it only on servers whose rules permit client
mods.** It does not bypass anti-cheat or server restrictions.

## Troubleshooting
**The headset does not enter VR.** Check that the intended OpenXR runtime is
active: SteamVR's Settings > OpenXR page, the OpenXR setting in the Meta Quest
Link app, or VDXR selected in Virtual Desktop Streamer with the overlay reading
`Runtime: VDXR`.

**BFVR warns that the BF1942.exe build is unfamiliar.** It does not block the
game and will still try. Battlefield 1942 has many retail, digital and
community-modified executables. If yours works, say so on the mod's GitHub page
so it can be recorded.

**BFVR says elevation is required.** Windows is set to run `BF1942.exe` as
administrator. Close it, then right-click `BFVR.exe` and choose Run as
administrator.

**Windows or antivirus complains.** The installer is unsigned on purpose, and
BFVR has to load its DLL into an old game process. Only use files from the
official GitHub release, and do not switch antivirus off globally.

**Reset the settings.** Close BFVR and delete only
`Battlefield 1942\BFVR\UserConfig.txt`.

When reporting a problem, include the headset, graphics card, active OpenXR
runtime, where your game executable came from, the map or mod, and the steps that
reproduce it. **Never upload Battlefield game files.**

## Credits and legal
BFVR by **JayBiggsGMG** - https://github.com/JayBiggsGMG/BFVR-Battlefield-1942-VR-Mod

Thanks to 333hronos, Arkylien, Notagameaddict, Meurtreetbanane, Pande4360 and
SnickersDaBunny, and to the wider VR and Battlefield modding communities.

BFVR source is MIT licensed. An unofficial fan project, not affiliated with EA or
DICE.

>>> Someone already took the plane. They always do.
