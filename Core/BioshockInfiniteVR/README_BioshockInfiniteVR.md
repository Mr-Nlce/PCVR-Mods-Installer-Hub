# BioShock Infinite VR

Stereoscopic VR with motion controllers for **BioShock Infinite**. By
**mohamad-balouza** - the same mod as BioShock 1 and 2, now covering the third
game from the same zip.

> **Early access.** Playable and comfortable from the start of the game through
> the early city - that is the range the author tested. Later chapters, the
> Skyline and the DLCs have not had a VR pass yet.

## A different engine, a different folder

BioShock 1 and 2 Remastered use `Build\Final` on Steam/GOG and
`Build\FinalEpic` on Epic. **Infinite does not.** It runs on Unreal Engine 3
and uses the `Binaries\Win32` folder on all three stores:

    ...\steamapps\common\BioShock Infinite\Binaries\Win32\

Both DLLs go **there**. This is the most common mistake with this mod, and the
installer looks in the right place by itself.

## Which store editions work

The mod's DLLs go next to the game executable in `Binaries\Win32`, and
**all three stores use that same subfolder**:

    ...\BioShock Infinite\Binaries\Win32\

- **Steam** - `steamapps\common\BioShock Infinite`, exe `BioShockInfinite.exe`
- **GOG** - `C:\GOG Games\BioShock Infinite` or under GOG Galaxy's `Games\`,
  same exe name
- **Epic** - sold as *Complete Edition*, so the folder is
  `Epic Games\BioshockInfiniteCompleteEdition` and **the exe is named
  `ShippingPC-XGame.exe`** instead

That last difference is worth knowing: the folder layout below it is identical,
so dropping the files in works the same way. The Hub knows all three folder
names and finds the game in each. What has **not** been confirmed is whether the
mod itself is happy with Epic's differently-named executable - the author tested
against the Steam build. If you are on Epic and it does not hook, that is the
first thing to mention in a report.

## Requirements
- BioShock Infinite (Steam, GOG or Epic - see above)
- A PC VR headset with an active OpenXR runtime and a **32-bit loader** - the
  tested path is Quest 3 over Virtual Desktop / VDXR
- Motion controllers

## Performance - read this first
Infinite in VR is **heavier than the remasters**. If you see judder or jitter,
lower the load in this order:

1. Game resolution first - `resW` / `resH` in the F10 overlay, kept roughly square
2. Then your streaming quality

A clean 90 Hz at modest resolution beats a sharp stutter. If the image freezes
after taking the headset off and on, toggle **VR enabled** off and on in the F10
overlay - the session recovers instantly.

## What works today
- Full-rate stereo rendering and 6DOF head tracking
- Motion controllers: gun right, vigor left, aim laser and dot
- Interactions follow your **head** - USE prompts arm where you look, not where
  your body points
- Scripted sequences and cutscenes play correctly, including first-person
  vignettes; an F10 fallback per scene is there if one misbehaves
- Melee swings and executions; the sprint arm-pump is suppressed
- Game HUD on a readable floating panel, flat crosshair hidden for the laser
- Body-follows-head movement, stick pitch disabled, snap turn
- In-headset F10 tuning overlay

### Two controls that work everywhere

- [[X]] + [[Y]] together on the left controller = the menu button, on every
  runtime. Useful because Steam Link's overlay sometimes swallows the real one:
  tap for pause, hold for back / select
- Click **both sticks** at once to recenter the view - no trip into the [[F10]]
  menu needed

## Settings
Your tuning is stored **outside the game folder**, per game:

    %LOCALAPPDATA%\BioshockVR\bsi\

Upgrading keeps it: your values win key by key, and anything new arrives with
working defaults.

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

## The VR switches (the installer sets these for you)

Infinite is the odd one of the three BioShocks: it has **no one-click VR button**.
BioShock 1 has *VR PRESET 1* and BioShock 2 has *APPLY PRESET* - Infinite has
neither, and its stereo and head-tracking switches are not armed on their own.

That is what a flat panel with black borders in the headset means: VR started, but
stereo and head tracking are off, and the game is still rendering 16:9 into a
near-square headset panel.

**The Hub's installer handles it.** It writes the author's tested settings to:

    %APPDATA%\..\Local\BioshockVR\bsi\vrpreset.ini

Eight lines, and three of them are what matter: stereo on, head drive on, and a
near-square resolution of 2064x2208. If you already had settings there, the
installer asks first and backs yours up as `vrpreset.ini.bak`.

Note the folder: the three BioShocks **never share files**. BioShock 1 uses
`BioshockVR\`, BioShock 2 uses `BioshockVR\bs2\`, Infinite uses
`BioshockVR\bsi\`.

## In the headset, but only a flat floating screen?

That is **not** a runtime problem - VR started, but stereo and head-tracking are
switched off. It is almost always an old `vrpreset.ini` that keeps overriding the
shipped defaults, which is why reinstalling never helps.

Fix it by copying the matching `preset-bs1` / `preset-bs2` / `preset-bsi`
`vrpreset.ini` from the mod's zip over the one in `%LOCALAPPDATA%\BioshockVR\`
(deleting yours works too), or arm it live in the [[F10]] menu.

## Known issues
The author lists these openly for the early-access release:

- Brief visual artifacts where the game streams the world in - the bell tower at
  the very start is the clearest example; it passes once loading settles
- Hand and arm model jank in places; with a vigor and no gun the hand sits
  differently than with a gun
- Aim is not fully fine-tuned; per-weapon calibration is in progress
- A few cinematic beats: the tattoo-on-your-hand beat still hides the hand, some
  holds show hands a beat late. F10 "cutscene rig: always hide" is the
  per-session fallback
- Reload animation can look wrong on some weapons
- Near the view edge the hand model can drift slightly toward the camera
- Some hand effects - muzzle flash, tracers, vigor charge plume - can appear at
  the game's original hand position instead of at your controller

Reports help: include `%LOCALAPPDATA%\BioshockVR\bsi\bioshockvr.log`.

## Credits and legal
Mod by **mohamad-balouza** -
https://github.com/mohamad-balouza/bioshock-vr

An unofficial fan project, not affiliated with 2K or Irrational Games.

>>> Bring us the girl. Look up while you do it.
