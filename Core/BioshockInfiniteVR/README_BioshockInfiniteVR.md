# BioShock Infinite VR

Stereoscopic VR with motion controllers for **BioShock Infinite**. By
**mohamad-balouza** - the same mod as BioShock 1 and 2, now covering the third
game from the same zip.

> **Early access.** Playable and comfortable from the start of the game through
> the early city - that is the range the author tested. Later chapters, the
> Skyline and the DLCs have not had a VR pass yet.

## A different engine, a different folder

BioShock 1 and 2 are remasters and keep their binaries in `Build\Final`.
**Infinite does not.** It runs on Unreal Engine 3 and its binaries live in:

    ...\steamapps\common\BioShock Infinite\Binaries\Win32\

Both DLLs go **there**. This is the most common mistake with this mod, and the
installer looks in the right place by itself.

## Which store editions work

The mod is two DLLs dropped next to the game binaries, and **all three stores put
those in the same place**:

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

## Settings
Your tuning is stored **outside the game folder**, per game:

    %LOCALAPPDATA%\BioshockVR\bsi\

Upgrading keeps it: your values win key by key, and anything new arrives with
working defaults.

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
