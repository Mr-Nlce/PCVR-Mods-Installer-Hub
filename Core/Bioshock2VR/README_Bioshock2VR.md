# BioShock 2 VR Installer

Automated installer for **bioshock-vr** by **mohamad-balouza** - native VR for
**BioShock 2 Remastered**: stereo rendering, 6DOF head tracking and motion
controllers, with the weapon in your right hand and the plasmid in your left,
each aiming from that hand.

Since v0.7.0 one release serves **both** BioShock games - the same two DLLs
detect which game loaded them. If you also use the Hub's BioShock entry, the
two installs are independent and do not share settings.

https://github.com/mohamad-balouza/bioshock-vr

## What the installer does
1. Finds BioShock 2 Remastered on Steam, GOG or Epic - the executable and
   mod files go in `Build\FinalEpic` on Epic, or `Build\Final` on Steam/GOG
2. Downloads the newest release from GitHub
3. Copies the two DLLs (`xinput1_3.dll`, `bioshockvr.dll`) next to
   `Bioshock2HD.exe`. No game file is changed.

If another mod's `xinput1_3.dll` is already there, a copy is kept as
`xinput1_3.dll.replaced-<date>`. Both mods use the same injection vector and
cannot run at the same time.

## Before you play: set a SQUARE resolution
In the game's video options pick something like **2700 x 2700**, not 16:9.
Headset panels are near square, so a widescreen picture renders a wide strip
that the headset throws away. A square image has fewer pixels overall, looks
sharper in the headset and runs faster.

## Playing
1. Start your runtime first. Virtual Desktop: set the OpenXR runtime to
   **VDXR** in the Streaming tab, connect, then launch the game from Steam
   inside Virtual Desktop. Steam Link and SteamVR work as well.
2. Load your save - you are in VR.
3. Press [[F10]] for the mod menu. **APPLY** at the top arms everything;
   **SAVE** keeps your slider changes across restarts.

## Controls
- Right hand: weapons - [[Right Trigger]] fires, [[Right Grip]] switches
  weapon (hold for the radial)
- Left hand: plasmids - [[Left Trigger]] casts, [[Left Grip]] switches
- [[Left Stick]] move (click to crouch), [[Right Stick]] turn
- [[A]] use, [[B]] jump, [[X]] reload / hack, [[Y]] first-aid kit
- [[Menu]] pause (hold for map and objectives)

Movement follows your view: pushing the stick forward walks where you look,
and both smooth and snap turn carry your body with you.

- [[X]] + [[Y]] together on the left controller = the menu button, on every
  runtime. Useful because Steam Link's overlay sometimes swallows the real one:
  tap for pause, hold for back / select
- Click **both sticks** at once to recenter the view - works anywhere, no trip
  into the [[F10]] menu needed

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

## Worth knowing in the F10 menu
- **During cutscenes:** *authored + look* (default) plays the scripted camera
  while you can still look around; *authored* locks the shot; *off* leaves you
  in control
- **VR camera:** world scale, snap turn on/off with angle, smooth turn speed,
  recenter, and the flat crosshair toggle (hidden by default - you aim with
  the mod's dot)
- **Hands and aim:** aim trim and position per hand; the values are saved
  **per weapon** automatically, so tune with a weapon drawn
- **VR HUD:** distance, width and height of the floating panel

## The calibration is built in
A fresh install needs no tuning - BioShock 2's calibration sits inside the DLL.
The release zip carries the author's own tuning as files as well, in
`preset-bs2\`. You only need those if you changed settings, pressed SAVE and
want the shipped tuning back: copy them into

    %LOCALAPPDATA%\BioshockVR\bs2\

(that is `%LOCALAPPDATA%\BioshockVR\bs2\`) and restart the game. The installer
deliberately does not write there. BioShock 2 keeps its settings in that `bs2`
subfolder - the two games never share files.

## A flicker in the left eye?

There is an open report about this and the author is hunting it. The mod now
carries an instrument that watches the layer the previous one could not see, so
**if you can reproduce it, your log is genuinely useful evidence** - attach an
up-to-date one when you report it.

## If it misbehaves
Close the game and delete the files in `%LOCALAPPDATA%\BioshockVR\bs2\`. They
override the built-in defaults key by key, so an old value keeps applying even
after an update fixes the default. You only lose your own tuning. The log for a
bug report is `bioshockvr.log` in `%LOCALAPPDATA%\BioshockVR\`.

## Requirements
- **BioShock 2 Remastered** - Steam AppID **409720**, GOG or Epic
- A PCVR headset with an OpenXR runtime
- Motion controllers

## Credits
- **bioshock-vr** by mohamad-balouza

  https://github.com/mohamad-balouza/bioshock-vr

- **BioShock 2** by 2K Games. This mod is not affiliated with 2K or Take-Two,
  and it distributes no game assets.

>>> Rapture never asked you to look away. Now you cannot.
