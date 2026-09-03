# Cyberpunk 2077 VR

**CyberpunkVRPort** by **dariulone** - a 6-DoF VR mod for **Cyberpunk 2077**, built as a
**RED4ext plugin**. `CyberpunkVR_Stereo` is now the **only** native plugin: it drives OpenXR
head tracking, real stereo, the in-headset overlay **and** the full-body VR avatar with
motion-controlled hands that used to live in a second DLL. A set of CET and redscript mods add
VR weapon aiming, the physical reload, motion melee and hand-to-holster equipping. Everything
is configured from the in-headset **F10** overlay.

Experimental community mod, not affiliated with CD PROJEKT RED. Keep backups of your saves.

https://github.com/dariulone/cyberpunk-vr-port

## New in 0.1.6

- **Braindances are stereo**, including their colour grade, and the second eye now receives
  the scanner's green tint as well.
- **Taken-over cameras are driven from the actual lens**, including the AV turret. Three
  overlay sliders tune the special mission viewpoint without changing wall cameras.
- **Menus and braindances use the game's own bindings.** The port's remaps and gestures stay
  out of their way; with a weapon drawn, [[B]] can now close the phone, radio and vehicle list.
- **The square VR UI is fitted and centred.** Contacts, messages, radio, subtitles, dialogue,
  tutorials and the loot window no longer hang off the edges.
- **Two-handed weapon support is physical.** The free hand rests until it reaches the weapon,
  then takes a captured support grip for that weapon. Johnny's body now carries the stereo
  cameras and held-object slots too.
- Major render fixes cover missing indoor lights, the white second eye, the braindance ESC
  hang, invalid swapchain states and the too-small 32 mm stereo separation.

> **HUDitor and Input Loader are optional in 0.1.6.** Install them together if you want the
> supplied movable VR HUD and [[F11]] editor. The VR port itself runs without either one.

## What changed with 0.1.0
- **No `dxgi.dll` any more.** The mod loads through the game's own mod loader, and uninstalling
  is deleting folders. Anything else that proxies dxgi - R.E.A.L. VR, for one - has to be out of
  `bin\x64`, or the two fight over the same engine hooks. The installer moves an old one aside.
- **Real stereo.** The second eye is an actual engine view: a camera on the player entity that
  renders the frame graph for its own eye, from its own position. It falls back to mono by
  itself where there is nothing fresh to show - menus and loading screens.
- The old alternate-eye reprojection (AER) is gone entirely, along with its artefacts. There is
  no Mono/AER choice left to make.
- The game HUD is in **both** eyes, at a finite distance so icons fuse instead of doubling.

## Launching
1. **Start your OpenXR runtime first** - Virtual Desktop / VDXR, SteamVR, PICO - **before** the game.
2. Launch Cyberpunk 2077 normally, or use **Start in VR** in the Hub. A launcher window opens
   first: pick the render resolution there. Leave its **DEBUG** tick-box off for play - it arms
   every diagnostic probe at once and costs both frame time and a very large log.
3. In game: [[F10]] or [[Insert]] opens the settings overlay, [[F7]] recenters.

## Controls
VR controller input is merged into the native gamepad, so the game's own **Settings -> Key
Bindings -> Controller** applies. Buttons follow each runtime's interaction profile (Touch,
Index, Vive, WMR).

| Input | Action |
|-------|--------|
| Left stick | Move - **one speed** whatever the deflection, so a thumb tremor cannot change your pace |
| Left stick fully forward, held 0.2 s | **Sprint** - held, not toggled, and it survives a dash |
| Right stick X | Turn - a snap needs a **full** push, so a resting thumb cannot turn you |
| Right stick fully up | **Dash / dodge**, once per push |
| Right stick fully down | Crouch |
| Right stick click | **Slide release** - racks the weapon during a physical reload |
| [[Right Trigger]] / [[Left Trigger]] | Fire / Aim. Left trigger is also melee block |
| [[A]] | Jump - double and charge jump unchanged. **In a vehicle: confirms a dialogue line** |
| [[B]] | **Weapon in hand:** drop the magazine. **Phone, radio, vehicle list or a menu open:** the game's own B closes or backs out instead |
| [[X]] / [[Y]] | Reload / interact and weapon switch. Hold [[Y]] for the pouch. **In a car, hold [[X]] to get out** |
| [[Right Grip]] + reach to shoulder or hip | Hand-to-holster equip and unequip |
| [[Left Grip]] | Grab the magazine during a reload |
| Left hand to your **left ear** + [[Left Grip]] | **Scanner - a toggle since 0.1.5:** squeeze to open, squeeze again to close, hand free in between |
| Swinging a melee weapon | Native melee attack along the blade |

**Quickhacks (0.1.5):** the list moved off the face buttons onto the **left stick, pushed to
the stop**, with [[X]] as a plain apply. It presses the arrow keys rather than the D-pad,
because the D-pad is also the scanner's zoom.

**D-pad chord:** hold the left stick clicked in, then pick the direction with the right stick,
pushed to **0.90** - the same threshold every other gesture in the port uses since 0.1.5.
While the chord is held the right stick is taken out of the camera, so choosing a direction
cannot snap-turn you. Let go without choosing and it sends the normal sprint press instead.

## The F10 overlay
Four tabs, live, saved to `vrport.ini` - nothing here needs a restart.

- **General** - world scale, IPD scale, stereo separation, VR menu FOV and quad size, motion
  prediction, head offset
- **Controls** - decoupled weapon aim and its laser dot, locomotion source (game / HMD / left
  hand / right hand), snap turn and angle, immersive holsters
- **Stereo** - which eye the second view is sent to, how stale its last frame may get before the
  submit falls back to mono, the HUD composite, and live counters showing whether the second
  view is producing and reaching the headset
- **VRIK** - start and stop tracking, physical body rotation and its free-look cone, the
  cutscene-suspend tier, IK calibration (reach scale, height, elbow swing and pole, wrist
  offset), diagnostics

> **There is no HUD tab.** The port deleted its own HUD mod - it and HUDitor fought over the
> same widgets. HUD placement is HUDitor's job now, on [[F11]].

## Recommended settings
Cyberpunk is very demanding in VR.

- **Launcher:** do not pick a high resolution; the game is heavy.
- **Quick Preset:** Low, Medium at most. **Resolution Scaling:** off.
- Turn **off**: Ray Tracing, Frame Generation, Film Grain, Chromatic Aberration, Depth of Field,
  Lens Flare. Press **Apply**.
- **Video -> Gamma Correction:** nudge it down a little; the image is otherwise a bit bright.
- **F10 -> VRIK:** start hand tracking and calibrate. The hand overlay is on by default so you
  can line your hands up - turn it off once it fits.

## What the installer puts in place
An in-place mod: the files land in your existing Cyberpunk 2077 folder.

- `red4ext\plugins\CyberpunkVR_Stereo\` - the VR plugin, its sight shaders, the settings template
  (the avatar, hand IK and weapon aim are **inside this one DLL** since the single-plugin build)
- `bin\x64\plugins\cyber_engine_tweaks\mods\CyberpunkVRPort_*\` - the CET mods
- `r6\scripts\CyberpunkVRPort_*\` - the redscript mods

> **Coming from an older build?** `CyberpunkVR_Hands.dll` no longer exists - its code moved
> into `CyberpunkVR_Stereo.dll`. A copy left behind from an earlier install makes **two plugins
> hook the same address**, and the game dies on launch with a fault at `FFFFFFFFFFFFFFFF`.
> Extracting the new build over the old one does **not** remove it. The Hub installer parks it
> for you - if it ever reports that it could not, rename that `.dll` yourself.

**Keep only one `.dll` in each `CyberpunkVR_*` folder.** RED4ext loads every DLL it finds there,
so a renamed backup next to the real build loads as a second copy of the plugin and the two
fight over the same hooks.

### Frameworks
The installer adds each one **only if its files are missing**, so an already-modded Cyberpunk
downloads nothing here:

- **RED4ext** - loads the VR plugins
- **Cyber Engine Tweaks (CET)** - runs the CET mods
- **redscript** - compiles the `.reds` scripts the mod ships
- **TweakXL** - applies its tweak files
- **ArchiveXL** - loads the packed assets
- **Codeware** - shared scripting library; **1.20 or newer**, older builds fail script compilation

The last four are fetched at their newest release: the installer reads the current tag from
GitHub and falls back to a known-good build if GitHub cannot be reached.

## What lands in your game folder

| Path | What |
|---|---|
| `red4ext\plugins\CyberpunkVR_Stereo\` | the plugin: OpenXR, stereo, overlay, the VR avatar and hands, weapon aim, sight shaders |
| `bin\x64\openvr_api.dll` | for the SteamVR (OpenVR) runtime path |
| `bin\x64\CyberpunkVR_*Grip*.ini` | captured hand poses - smoking, lighter, resting hands and the per-weapon two-handed support holds |
| `bin\x64\plugins\cyber_engine_tweaks\mods\CyberpunkVRPort_*\` | the CET side, including the 0.1.6 Braindance HUD, camera control, VRIK, weapons, reload and wrist HUD |
| `r6\scripts\CyberpunkVRPort_*\` | the redscript side, including DeviceCam, ScannerHud and the 0.1.6 Loot UI module |
| `r6\input\CyberpunkVRPort_ScannerHud.xml` | a port input definition; Input Loader is only needed with the optional HUDitor setup |
| `r6\tweaks\vrcigarette\` | TweakXL entries for the smoking props |
| `archive\pc\mod\cyberpunkvrport.archive` / `vrport_mag.archive` | packed VR camera, body, held-prop, magazine and weapon assets |
| `engine\config\platform\pc\` | CPU tweaks tuned for two views |
| `r6\input\HUDitor.xml` | **REPLACES HUDitor's own** - a `.pre-vr` copy is kept |
| `bin\x64\plugins\...\HUDitor\persistency.json` | **REPLACES your HUD layout** - a `.pre-vr` copy is kept |
| `UNINSTALL.bat` / `UNINSTALL.txt` | the port's own uninstaller, in the game folder |

> **`UserSettings.json` is replaced once on the first VR launch.** Your previous file is saved
> beside it as `UserSettings.pre-vr-<date>-<time>.json`; after that, changes made in the game's
> own menus stick. To skip the replacement, create `bin\x64\vrport.ini` with
> `first_launch=0` before the first VR start.

## Keys outside the controller

| | |
|---|---|
| [[F10]] or [[Insert]] | the VR menu / settings overlay |
| [[F7]] | recentre |
| [[F8]] | switch the VR menu between the full headset view and a small panel |
| [[F11]] | HUDitor's editor, if you installed it |

## Driving

| | |
|---|---|
| [[Grip]], hand at the wheel or handlebars | grab it - that arm returns to the driving animation |
| Tilt of the line through both controllers | steering. One hand: that controller against the wheel centre |
| Hand on the **middle** of the wheel | horn - no grip needed, and a hand that is grabbing never honks |
| Triggers | throttle / brake |
| [[Right Trigger]], weapon drawn | **fire.** The throttle latches at the speed it had |
| Left stick fwd / back, weapon drawn | trim the latched throttle |
| [[X]] **held** | get out. B is never the exit in a car |

## Removing it
For a temporary flat launch, use the **Flat / VR switch** on this page. It parks only
`CyberpunkVR_Stereo.dll`; the author's own 0.1.6 notes confirm the CET and redscript modules
stay idle without that native plugin. One click restores VR.

For full removal, use **Uninstall Now** on this page. It starts the port's own
**`UNINSTALL.bat`** from the game folder, which removes every path in the 0.1.6 package and
then offers your Cyberpunk settings back. Your `.pre-vr` HUDitor copies stay where they are;
rename them back if you want your old layout.

## Repair - when you cannot tell what is stale

The installer asks at the very start:

```
 >>> Press Enter to start the installation or Update
     or press R and Enter for Repair, in case of issues
```

**Repair stops treating anything as already installed.** Every framework, every
mod and the VR mod itself are offered again, so whatever is on disk ends up
current.

It exists because **most of these mods carry no readable version at all** - an
`.archive` or a `.reds` file simply does not have one. If you installed months
ago, the installer cannot tell whether your Equipment-EX or Visual Holsters is
current; it would skip them as "already present" and leave a setup that is
broken in a way nobody can see. Repair sidesteps that question entirely.

It takes longer, and it is the right answer whenever something behaves oddly and
you do not know which piece is at fault.

## Run it again to update, or to add something later

The installer is also the updater. Running it on an existing setup:

- **skips what is already there** - the frameworks, HUDitor and the companion
  mods are only offered when they are actually missing,
- **re-applies the VR mod every time**, so its files win again. That is what
  makes adding HUDitor to an existing install work: HUDitor overwrites the two
  VR files, and the VR mod is laid back over the top in the same run,
- **checks for age where it can.** A framework that ships a DLL carries a file
  version, so those are compared against what is published and an older one is
  offered for update. **RED4ext and CET are recognised by their marker file
  only**, and **redscript's `scc.exe` reports no usable version at all** - those
  are kept as they are unless you run Repair. **The `.archive` and `.reds` mods carry no
  version at all** - for those the installer can only see whether the file is
  there, which is exactly what **Repair** exists for.

So if you want to add HUDitor, or the holsters, months after the first install:
just run it again and answer the questions for the parts you want.

## HUDitor - the one that must go in FIRST

In VR a lot of the HUD sits outside your view. **HUDitor** is what moves it, and
the VR mod ships a ready-made VR layout for it.

> **The order is not a preference.** The VR mod ships its own
> `r6\input\HUDitor.xml` and HUDitor's `persistency.json` and **replaces both**.
> Install HUDitor afterwards and it writes its files back over them - the F11
> editor binding is gone and the VR HUD layout with it.

The installer offers it **before** the VR mod, one page at a time - exactly like
every other Nexus download in this Hub: the page opens, you download the file,
and the installer either finds it in your **Downloads** folder or takes it when
you **drag it onto the window**. It unpacks and copies it for you. Enter alone
skips one.

What it needs, in order:

| | why |
|---|---|
| **Input Loader** | merges the supplied `r6\input\*.xml` files for HUDitor's VR layout and [[F11]] editor binding |
| **Mod Settings** | the settings panel HUDitor puts its key binding in |
| **HUDitor** | the editor itself |

The whole HUDitor chain is optional. The VR mod installs and runs without it - the unchanged
flat-screen HUD is still composited into both eyes, but you cannot move it without adding this
chain later.

## Recommended companion mods
These are the mods the Hub recommends alongside the port. Several of them need each other -
Visual Holsters needs Equipment-EX, the pistol holsters need Zenitex, the katana needs the
shop it is sold in - so **the installer works out the order for you** and offers each one in
a sequence that actually works.

They live on Nexus, so the Hub cannot download them automatically - **the installer offers
them anyway**: it opens each page in turn, then takes the file from your Downloads folder or
from a drag & drop onto the window. Type **s** and Enter to skip one. Anything you already
have is not offered at all.

> **Nothing is copied on trust.** After unpacking, the installer checks that the archive
> really contains the mod it is supposed to be. A wrong file is refused, and nothing goes
> into your game folder.

If you skipped them, you can add them by hand at any time. The downloads are here:

Visible Bullets - projectiles you can see in flight

https://www.nexusmods.com/cyberpunk2077/mods/22251?tab=files

Visual Holsters - the visible holster the hand-to-holster grip reaches for

https://www.nexusmods.com/cyberpunk2077/mods/21936?tab=files

Equipment EX - extra equipment slots

https://www.nexusmods.com/cyberpunk2077/mods/6945?tab=files

Nova Optics - reworked sights, which the collimated reflex shader draws into

https://www.nexusmods.com/cyberpunk2077/mods/29190?tab=files

All four are drop-in archives: their contents go into the Cyberpunk 2077 folder, the same one
the VR mod uses.

### VR UI Mods - offered only if you take HUDitor

HUDitor cannot reach every HUD element. **VR UI Mods** is a set of redscript
files that moves the rest: the scanner and quickhack menu, the info popup, the
contacts list, unread texts, the notification popups and the tutorial window.

It is **not on Nexus** - it is a plain GitHub repository with no release, so the
installer fetches the repository zip directly instead of sending you to a page.
The scripts land in `r6\scripts`.

It only appears when HUDitor is already installed, because on its own it would be
moving five stragglers and nothing else.

### They need each other, and the installer knows the order

Several of these pull in others. You pick one; what it sits on comes with it,
prerequisites first:

| pick this | and these come with it |
|---|---|
| Visual Holsters | Equipment-EX |
| **Military Pistol Holsters** | Equipment-EX, Visual Holsters, Zenitex Core - **and the Phantom Liberty DLC** |
| **Hip Katana** | Mod Settings, Virtual Atelier, Shinobi's Black Market, Equipment-EX, Visual Holsters |

The DLC one is called out **before** the download, not after it fails to load.

## Requirements
- **Cyberpunk 2077 patch 2.31** (PC) - Steam **AppID 1091500** or GOG. **The version
  matters:** the port hooks the engine at fixed addresses, so another patch means it does
  nothing or crashes. The installer reads your game's version and warns before touching
  anything.
- An OpenXR runtime, started **before** the game. SteamVR (OpenVR) works alongside it.
- Motion controllers

## Logs
- `bin\x64\cyberpunkvrport.log` - the plugin's own log and the right file for a bug report.
  Quiet by default; tick DEBUG in the launcher for per-frame diagnostics.
- `red4ext\logs\` - script validation and plugin load errors. **If redscript compilation fails,
  every redscript mod is off, not just the one that failed** - check here first when several
  things stop working at once.

## Credits
- **CyberpunkVRPort** by dariulone

  https://github.com/dariulone/cyberpunk-vr-port

- **VR driving** by **iPowerTech** - grabbing the wheel with your own hands, the steering
  geometry, the deadzone and lock-angle controls, the horn on the wheel hub, and shooting
  while you drive are all his work. The canted-lens projection fix and the pre-launch device
  list came from him too.

  https://github.com/iPowerTech

- **RED4ext** by WopsS

  https://github.com/wopss/RED4ext

- **Cyber Engine Tweaks** by maximegmd

  https://github.com/maximegmd/CyberEngineTweaks

- **Cyberpunk 2077** by CD PROJEKT RED

>>> Wake up, samurai. Night City won't burn itself down.
