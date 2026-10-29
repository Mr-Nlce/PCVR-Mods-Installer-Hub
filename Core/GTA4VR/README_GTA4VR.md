# GTA IV VR

Two independent mods bring Liberty City into VR. GTA4VR by bordplate is the first installer option and adds tracked hands, physical weapons and driving. The previous gtaiv-dxvk-vr mod remains available for gamepad play.

## About the Game
Niko Bellic arrives in Liberty City hoping for a fresh start. Explore its boroughs, follow the story and try to answer Roman's phone calls without getting into more trouble.

## Important
GTA4VR is experimental. Its author tested GTA IV Complete Edition 1.2.0.59 with a Vive Pro, Vive Wands and SteamVR as the active OpenXR runtime. Other controllers have no confirmed ready-to-use bindings. Custom bindings, pose adjustments or code changes may be required; other OpenXR runtimes are untested.

A complete VR campaign has not been verified. The Lost and Damned and The Ballad of Gay Tony are untested. Keep a keyboard/gamepad available and use flat mode for unsupported sections. Performance in busy city scenes can be demanding.

## What you need
- Your own Windows copy of GTA IV: The Complete Edition.
- SteamVR, a connected PC VR headset and controllers or a gamepad.
- For bordplate: make SteamVR the active OpenXR runtime. The package includes FusionFix, DXVK, ASI Loader and OpenXR Loader; no separate FusionFix download is needed.
- Close GTA IV and its launcher before installing, updating, switching or uninstalling. FirstPerson.asi conflicts with the VR camera; back it up and rename it to FirstPerson.asi.off before continuing.

## Install and start
1. Choose Install or Update in the Hub.
2. Choose GTA4VR by bordplate, the previous gamepad mod, or both. Locate Game and dropping GTAIV.exe or its folder are supported.
3. Finish setup. Each mod gets its own profile; an install or update keeps the other active mod selected.
4. Start SteamVR, then use the matching Start in VR button in the Hub. Alternatively, use the matching GTA IV VR desktop shortcut.
5. Steam copies start through Steam. Other copies use PlayGTAIV.exe or LaunchGTAIV.exe when available, otherwise GTAIV.exe. Store login/licensing still applies.

Choosing a mod's start button restores that profile and its settings before launching. The two mods must not load together. The Flat / VR switch applies on the next Hub/desktop-shortcut launch; flat mode restores the retained original files. Older imported installations keep their available .vrbak originals and recovery data.

## Controls - bordplate GTA4VR
These are the author's Vive Wand defaults. Rebind named actions in SteamVR for other controllers; compatibility is not confirmed.

| Button | Action |
|---|---|
| [[Left Trackpad]] touch | Move; the outer edge jogs |
| [[Left Trackpad Click]] hold | Sprint |
| [[Right Trackpad Center Click]] | Jump; handbrake while driving; confirm in phone |
| [[Right Trackpad Left Click]] / [[Right Trackpad Right Click]] | Select weapons |
| [[Left Menu]] tap | Pause or skip a cutscene |
| [[Left Menu]] hold | Open phone, including while driving |
| [[Right Trigger]] | Fire; accelerate while driving; select a pointed pause-menu item |
| [[Left Grip]] near weapon | Support the weapon with your second hand |
| [[Grip]] near an object | Grab; hold to retain it |
| [[Right Grip]] | Eject a supported magazine |
| [[Left Grip]] over shoulder | Retrieve ammunition; insert it and operate the weapon's slide, handle or pump |
| [[Right Menu]] | Enter/exit vehicle; back in phone or pause menus |
| [[Left Trigger]] while driving | Brake/reverse; fire a left-hand weapon during armed driving |
| [[Left Trackpad]] touch or [[Grip]] on steering wheel | Steer |
| [[Right Trackpad Upper Click]] | Horn |
| [[Left Trackpad Click]] during armed driving | Brake/reverse |
| [[Right Trackpad Directional Click]] in phone | Navigate |

Ejected magazine ammunition is discarded. The pump shotgun needs pumping after each shot. Physical reloading is on foot; vehicles retain native reload/ammunition handling.

## Controls - previous gamepad mod
Use the game's gamepad controls. The keyboard shortcuts below belong to gtaiv-dxvk-vr.

| Button | Action |
|---|---|
| [[F3]] | Open VR menu |
| [[F5]] | Cycle eye resolution |
| [[F6]] | Stereo scale |
| [[F8]] | IPD |
| [[F9]] | Recenter |
| [[F10]] | Set seated baseline |

The gamepad package supplies its own tuned settings. Choose DirectX 9 in its FusionFix graphics options, rather than FusionFix's Vulkan path. Its optional aCompleteEditionHook.asi can cause startup crashes on some installations; back it up and rename it to aCompleteEditionHook.asi.off if affected.

## Help
### Mission workarounds
Bordplate: enter and immediately leave the required bowling activity in Michelle's mission. Playing the minigame itself needs flat controls. In Bull in a China Shop, smash the window with your fist instead of trying to pick up the tutorial's cinder block.

### Known rendering limits
Traffic-light lamps, objective markers and water have reported stereo issues. Vehicle and UI coverage remain under development. These are mod limitations rather than proof of an installer error.

### Settings
Bordplate settings are in plugins/GTAIV.EFLC.FusionFix.ini; adjust PlayerHeight in the VR section to your height in metres. Weapon and vehicle profiles live in plugins/VRWeapons and plugins/VRVehicles. The Hub preserves edited INI/CFG files during updates.

The previous mod uses gtaiv_dxvk_vr.* text files beside GTAIV.exe. Its log is gtaiv_dxvk_vr.log. The optional commandline.txt.vr-square can be used as commandline.txt after backing up any existing file.

## VR files
Both retained mod profiles live under _vrmods in the folder containing GTAIV.exe. The Hub uses its current Core/GTA4VR/Start-GTA4VR.ps1 controller. Desktop shortcuts use the installed _vrmods/VRLaunch/Start-GTA4VR.ps1 through the matching hidden VBS launcher. The selected profile is activated there before the normal store/game start. Original game files and profile-specific settings are kept separately.

## Links & support
- [GTA4VR by bordplate](https://github.com/bordplate/GTA4VR)
- [GTA4VR releases](https://github.com/bordplate/GTA4VR/releases)
- [GTA4VR issues and mission workarounds](https://github.com/bordplate/GTA4VR/issues)
- [Previous gtaiv-dxvk-vr mod](https://github.com/Hochgeschwindigkeitsrennfahrer/Grand-Theft-Auto-IV-VR-Mod)
- [Previous mod releases](https://github.com/Hochgeschwindigkeitsrennfahrer/Grand-Theft-Auto-IV-VR-Mod/releases)
- [VR gameplay - bordplate motion controls](https://youtu.be/sXusIPAr8HY?t=286)
- [VR gameplay - previous gamepad mod](https://youtu.be/JkVdSyDpg78)

Roman has another bowling invitation.

### SteamVR runtime check

For bordplate, running SteamVR alone is insufficient: SteamVR must also be the active 32-bit OpenXR runtime. In SteamVR, open Settings > OpenXR > Set SteamVR as OpenXR Runtime. If Windows still selects Virtual Desktop or another runtime, Start in VR explains this before launching. The game would otherwise fall back to flat. The gamepad mod and intentional Flat mode keep their existing start routes.

If the mod logs Vulkan OpenVR bootstrap preload failed and stays flat, Start in VR supplies the absolute SteamVR bin/win32/openvr_api.dll path through VulkanOpenVRBootstrap. The former configuration is backed up beside the INI; existing valid custom paths are retained. This fixes the reproduced initialization failure and was confirmed in a real VR start.
