# Final Fantasy XIV VR Installer

Guided installer for FFXIV VR v0.0.62 by WesleyLuk90, installed via
XIVLauncher and Dalamud. A VR plugin for FFXIV implemented in C# using the
Silk OpenXR bindings, based on the original xivr-Ex plugin.

## Features

- Final Fantasy XIV in VR
- First-person mode with body view
- Customizable VR controller bindings
- Move your character's hands using controllers, hand tracking or body tracking

## Compatibility

Should work with any OpenXR-compatible runtime and headset. Reported
working: Valve Index, Meta Quest 2/3; runtimes SteamVR, Quest Link, Air
Link, VDXR.

## What it does

1. Checks for XIVLauncher — downloads and installs it if missing
2. Automatically registers the FFXIV VR custom plugin repository in `dalamudConfig.json`
3. Guides you step-by-step through the in-game plugin installation

## Requirements

- Windows 10/11
- A licensed copy of **Final Fantasy XIV** (Steam or Square Enix)
- SteamVR installed

## IMPORTANT — Before running

Make sure you have:
- Launched XIVLauncher at least once so Dalamud is set up
- Enabled Dalamud in XIVLauncher settings

## In-game setup (guided by installer)

1. Log into FFXIV via XIVLauncher
2. Open Plugin Installer: type `/xlplugins` in chat (copied to clipboard)
3. In Settings (gear icon): enable **"Wait for plugins before the game is loaded"**
4. Open the **Experimental** tab
5. Paste the repo URL into row 1 of the empty URL field (copied to clipboard)
6. Check **Enabled**, click Save, then Refresh
7. Find **FFXIV VR** in All Plugins → install v0.0.62
8. Type `/vr` in chat to open VR settings — enable **"Start in VR automatically"**
9. Restart FFXIV

## Switching between first and third person

Press [[Home]] on your keyboard - that is the default binding and it is easy to
miss, because nothing in VR points at it.

There is a nicer way: in the game's own settings under **Character Configuration
> Movement > General**, enable *"Switch to 1st person view when fully zoomed
in."* Then zooming all the way in does the same job.

## Controls

Configure bindings in the **Controls** tab of the VR settings window.
**A regular controller connected to your PC is strongly recommended** over
VR controllers — VR controllers don't have enough buttons and make the game
hard to play. Switch FFXIV into controller mode under Character
Configuration. Keyboard & mouse works but targeting is awkward (use tab
targeting); VR controllers work but are the least comfortable option.

Advanced binding options to stretch the limited buttons:
- **Layers:** hold a button bound to a layer to activate a second set of
  bindings (e.g. hold [[Left Grip]] = Layer 2, then [[X]] = Select)
- **Left/Right Stick DPad:** hold a bound button to make a stick act as a
  D-pad
- **Mouse:** bind `EnableLeftMouseHold` / `EnableRightMouseHold` to aim the
  mouse by pointing a controller (or move it with your head, under Other);
  bind Mouse1/2/3 for clicks
- **Stick deadzones** are adjustable if your controllers drift

## Source

- Mod by WesleyLuk90
- GitHub: https://github.com/WesleyLuk90/ffxiv-vr

All mod files are downloaded at install time from the official
source. Nothing is bundled with this installer.

>>> Hydaelyn calls. Adventurer, the realm is reborn - in VR.
