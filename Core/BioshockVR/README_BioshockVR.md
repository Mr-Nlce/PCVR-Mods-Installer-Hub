# BioShock Remastered VR

There are **two** VR mods for BioShock Remastered. The installer sets up either one - or both, with a switch between them.

*Would you kindly put the headset on and descend into Rapture.*

## The two mods

| | **balouza** | **BioVRDev** |
|---|---|---|
| Repo | https://github.com/mohamad-balouza/bioshock-vr | https://github.com/BioVRDev/Bioshock-Remastered-VR |
| Injector | `xinput1_3.dll` | `dxgi.dll` |
| Rendering | Stereo, 6DoF head tracking | Stereo, head tracking |
| Aiming | Motion-controller aim with a laser, weapons right / plasmids left, per-weapon aim profiles | Motion controllers, weapon follows the hand |
| Extras | Swing-to-melee, floating HUD panel, F10 tuning overlay, cutscene handling, snap turn | Straightforward - starts with the game, nothing to configure |
| Settings | `%LOCALAPPDATA%\BioshockVR\` | `BioshockVR.ini` next to the exe |

Both are actively developed and neither is a successor to the other - pick by the feature list above. The installer offers balouza first because it has the larger set of VR-specific features today.

## Install
The installer asks which one you want: **balouza**, **BioVRDev**, or **both**. It finds the game (Steam, GOG or Epic - the exe lives in `Build\Final`, on Epic in `Build\FinalEpic`), pulls the latest release straight from GitHub and puts the files in place.

## If you install both - the one thing to know
Both mods put their files in the **same folder**, and their payload DLLs are called `BioshockVR.dll` and `bioshockvr.dll` - on Windows that is the **same filename**. They physically cannot sit there together, so **only one can be active at a time**.

The installer handles it: each mod is parked in `Build\Final\_vrmods\<mod>\`, and only the active one has its files next to the exe. Two launchers in `Build\Final\VRLaunch\` do the swap and then start the game through Steam:

- `BioShock VR (balouza).bat`
- `BioShock VR (BioVRDev).bat`

The same two are the buttons on this game's page in the Hub. They only appear when **both** mods are actually installed - with a single mod there is nothing to switch between, so the page shows the normal start instead. **Close the game before switching.** Each mod keeps its own settings in its own place, so your tuning survives a swap.

The Flat/VR switch on that page works either way: it toggles whichever mod is currently active, `dxgi.dll` for BioVRDev or `xinput1_3.dll` for balouza.

## Coming from an earlier Hub install
Until now the Hub only offered BioVRDev, and it copied those files loose into `Build\Final`. If that is your situation, just run the installer and pick what you want - it takes the old files over into `_vrmods\biovrdev\` first, so the old injector cannot keep loading next to the new mod, and BioVRDev stays one click away through its launcher. Nothing of yours is thrown away.

## Playing - balouza
1. Start your OpenXR runtime (Virtual Desktop's VDXR, Steam Link / SteamVR, or any other) before launching.
2. Set the game's resolution to roughly **square**, e.g. 2700x2700 - not 16:9. Headset panels are near square, so a wide backbuffer renders a strip the headset throws away. On a 3840x2160 image only about half the width is inside the FOV; a square 2750x2850 has fewer pixels, looks sharper and runs faster.
3. Launch through Steam, load into the game (menus are still flat), press **F10** and click **VR PRESET 1**. That arms everything in the right order. No restart is needed.

Quest 3 controls:

| Action | Binding |
|---|---|
| Fire weapon | [[Right Trigger]] - the first pull raises it |
| Cast plasmid | [[Left Trigger]] - the first pull raises it |
| Switch weapon | [[Right Grip]], hold for the radial |
| Switch plasmid | [[Left Grip]], hold for the radial |
| Move | [[Left Stick]], crouch on click |
| Turn | [[Right Stick]] |
| Use / interact | [[A]] |
| Jump | [[B]] |
| Reload / hack / inject EVE | [[X]] |
| First-aid kit | [[Y]] |
| Pause (hold for map) | [[Left Menu]] |
| Swing the wrench | Swing your right hand while the wrench is equipped |
| Select ammo | Hold [[Left Thumbrest]] and push [[Right Stick]] |

Tuning lives in the F10 overlay - world scale, IPD, per-hand aim trim, per-weapon profiles, HUD placement, snap turn - and is saved with "Save preset values".

The author's own calibration files ship with the release and the installer keeps them in `_vrmods\balouza\`. You do **not** need them: the DLL defaults are identical. They are only useful if you want to overwrite your own tuning in `%LOCALAPPDATA%\BioshockVR\`.

**If it crashes or misbehaves:** close the game and delete `vrpreset.ini`, `hands.ini`, `weapons.ini` and `command.txt` from `%LOCALAPPDATA%\BioshockVR\`. Those files override the built-in defaults key by key, so an old value keeps applying even after an update fixes the default. You only lose your own tuning; VR PRESET 1 puts a working setup back immediately. The log for a bug report is `bioshockvr.log` in the same folder.

### Hands and weapon can be scaled (BioShock 1)

The hands and the held weapon scale independently - [[F10]], hands section (per
hand 0.2 to 4.0, weapon 0.3 to 2.5). The shipped defaults are already a
headset-tuned calibration and the aim calibration was re-baked to match, so
lasers and per-weapon profiles line up out of the box. Only change them if your
own proportions call for it.

### Two controls that work everywhere

- [[X]] + [[Y]] together on the left controller = the menu button, on every
  runtime. Useful because Steam Link's overlay sometimes swallows the real one:
  tap for pause, hold for back / select
- Click **both sticks** at once to recenter the view - no trip into the [[F10]]
  menu needed

## Playing - BioVRDev
Start the OpenXR runtime, then launch with **Start in VR** in the Hub or from your
storefront - **not** the `.exe` directly. No injector, no launcher.

> **`Setup.bat` has to have run, or the game starts flat.** The installer runs it
> for you, as administrator. It asks which headset and which runtime you have and
> installs the matching OpenXR loader - the package ships both under their own
> names and Setup puts your choice onto the name the mod actually loads. It also
> writes resolution and FOV into `Bioshock.ini` before the game can overwrite
> them. **Run it again if you change headset or OpenXR runtime.**

Native OpenXR is the default since v1.0.3; the SteamVR shim is the fallback for
headsets with no 32-bit OpenXR runtime, and Setup picks it automatically in that
case.

If the framerate is poor, lower `ResolutionX` and `ResolutionY` in
`BioshockVR.ini`, run Setup again, then relaunch.

### Tuning in the headset
Weapon position, angle and crosshair tune live on the **numpad** while you play
and write themselves back into `BioshockVR.ini` per weapon - one session can
calibrate the whole arsenal. Each plasmid keeps its own values too. About 130
settings live in that ini, each documented in it.

### If something breaks
Run `logs\CollectLogs.bat`. It gathers every log and config into one zip on your
Desktop, including the copies Windows can silently redirect your settings into -
that redirection is behind most "I changed it and nothing happened" reports. A
single `logs\BioshockVR.log` also helps: the block at the top lists every setting
the mod actually read.

`Uninstall.bat` restores your game config, keeps your tuned `BioshockVR.ini` as a
`.bak` instead of deleting it, and asks before removing `dxgi.dll`.

### What v1.0.3 brought
- **Both hands.** The off hand now appears and follows its controller, with a gun
  or a plasmid. Two-handed weapons can be gripped by the barrel, and recoil no
  longer shakes you off it.
- **The gun holds still.** The game animated the arm the weapon hangs off, so it
  drifted and iron sights were pointless. That is frozen while you hold a weapon,
  and every weapon carries its own grip, angle and crosshair. Crossbow, grenade
  launcher and chemical thrower are tuned for the first time.
- **Scripted scenes land where they should**, no longer depending on where you
  happened to look when they triggered.
- **The interface stays in the room** - map, manual, upgrade machine, Gene Bank
  and the plasmid/tonic flow are placed in the world instead of riding your head.
- **HUD on its own panel** at a comfortable depth; the game's flat reticle is
  disabled at the engine level and replaced by a VR dot that hides itself.
- Movement and aiming fully decoupled, four movement modes, snap turn, haptics.
- Bindings for Index, Vive and WMR; head bob removed at the source; the horizon
  stays level.

Known issues the author lists: pre-rendered cutscenes still follow your head, the
water effect draws as a square, the quest arrow drifts before settling, arms sit
slightly low in some scenes, and the desktop mirror runs at about half framerate
(that is how the game submits frames, not a performance problem). Only Meta Touch
controllers are tested by the author.

The installer also offers the community **fullscreen cutscenes** mod for this variant, which removes the black bars. balouza hides them itself.

## Known limitations (balouza)
- Full-screen effects (water, damage tints) sit on the HUD panel instead of covering your view.
- Cutscenes sit low with black borders; "Game FOV write" in the overlay makes them fill the view but is not recommended for normal play.
- Menus are still flat-screen, so load into the game before switching to VR.
- Melee changes **when** the attack fires, not **where** it lands - the game aims melee from your view, so point at what you want to hit.

## Conflicts
`itsloopyo`'s head-tracking mod uses the same `xinput1_3.dll` injection vector and cannot run alongside either mod - remove or back up its DLL first. `dxgi.dll` likewise can only be owned by one mod, so ReShade, DXVK and Special K conflict with the BioVRDev variant.

## Headsets

Quest over Virtual Desktop / VDXR is the primary and most-tested path.

**SteamVR and Steam Link now work too.** These games are 32-bit and SteamVR has
never shipped a 32-bit OpenXR runtime, so the mod brings its own bridge - that is
what `bvr_steamvr32.dll` and `openvr_api.dll` are for. Nothing to configure: the
mod tries the native runtime first and falls back automatically. Index, Vive and
WMR bindings ship as well; Vive and WMR defaults are partial (no face buttons) and
everything is rebindable in SteamVR's own binding UI.

Quitting SteamVR mid-game no longer kills the game - it drops to flat and keeps
running. While the SteamVR dashboard is open, controller input pauses by design.

## In the headset, but only a flat floating screen?

That is **not** a runtime problem - VR started, but stereo and head-tracking are
switched off. It is almost always an old `vrpreset.ini` that keeps overriding the
shipped defaults, which is why reinstalling never helps.

Fix it by copying the matching `preset-bs1` / `preset-bs2` / `preset-bsi`
`vrpreset.ini` from the mod's zip over the one in `%LOCALAPPDATA%\BioshockVR\`
(deleting yours works too), or arm it live in the [[F10]] menu.

## Credits
- **bioshock-vr** by mohamad-balouza - https://github.com/mohamad-balouza/bioshock-vr
- **Bioshock Remastered VR** by BioVRDev - https://github.com/BioVRDev/Bioshock-Remastered-VR
- BioShock and its assets by 2K / Irrational Games
## Key points from updates (BioVRDev build)
- **Epic is supported now.** The Epic binary sits at different addresses, so
  frame pacing, arm hiding and config detection used to be silently off there.
- **Vive, Vive Pro and Index work** through a bundled OpenXR-to-OpenVR shim.
  The setup script installs it by itself when the real loader cannot work.
- Run **Setup.bat as administrator**, and run it again after switching headset
  or OpenXR runtime - it picks the matching loader each time.
- Known on Epic: the stock crosshair still shows. Steam is unaffected.
- If the framerate is poor, lower ResolutionX / ResolutionY in BioshockVR.ini,
  run the setup script again and relaunch.
