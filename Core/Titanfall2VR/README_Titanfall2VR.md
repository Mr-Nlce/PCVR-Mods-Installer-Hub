# Titanfall 2 VR

**WIP — alpha, single-player campaign only.** titanfall2vr is a Northstar client plugin that adds OpenXR alternate-frame stereo, 6DoF head tracking and motion-controller weapon aim without modifying the base game's files.

## About the Game

Titanfall 2 is Respawn Entertainment's fast first-person campaign built around wall-running pilots and full-scale Titans. The Steam and EA App game builds are supported. The VR stack starts automatically when the campaign launches through Northstar.

Set the intended OpenXR runtime before launch. Quest 3 and Play For Dream MR were tested through Virtual Desktop/VDXR; other headsets and runtimes are untested rather than blocked. Steam users should disable the Steam Overlay because it injects into the same DirectX presentation path.

## First launch

EA App or Origin may need to update on the first launch. That update can consume the launch attempt; let it finish, then use **Start in VR** again to open Northstar and the campaign.

At the very beginning, Titanfall 2 asks you to look at lights for its basic controls tutorial. The VR view can remain frozen there like a cutscene, but the prompt can be completed on the flat monitor with the mouse while VR is running. Alternatively, play the opening and first tutorial course in flat once before starting the campaign in VR.

## Controls

The VR controllers are presented to Titanfall 2 as an Xbox pad, so the game's normal controller bindings still apply. Head tracking aims the view and the right hand aims the weapon.

| Button | Action |
|---|---|
| [[Right Trigger]] | Fire |
| [[Left Trigger]] | Aim down sights |
| [[A]] | Jump |
| [[B]] | Crouch |
| [[X Tap]] | Reload |
| [[X Hold]] | Use / select |
| [[Y Tap]] | Change weapon on release |
| [[Y Hold]] | Show the next objective / View |
| [[Left Grip]] | Tactical ability / cloak |
| [[Right Grip]] | Ordnance / grenade |
| [[Menu]] | Pause |
| [[Left Stick]] | Move |
| [[Left Stick Click]] | Sprint |
| [[Right Stick Left / Right]] | Turn |
| [[Right Stick Up / Down]] | Answer two-option prompts with D-pad up/down |
| [[Right Stick Click]] | Melee |
| [[Both Stick Clicks]] | Open or close the in-headset settings panel |

In the settings panel, either stick selects and adjusts rows, A activates, B goes back, the grips change category and both stick clicks close it. For a full D-pad, touch either controller's thumbrest or raise the left controller beside your head; the left stick then sends D-pad directions and X sends View.

## Picture and calibration

The mod deliberately starts at 75% render resolution because it cannot measure the GPU. Open the settings panel with both stick clicks and raise **Resolution** toward 100% while frame rate remains stable. Lower **World scale** if hands and weapons feel oversized. Grip forward/right/up can be adjusted live while holding the gun.

The first launch with previously unseen headset geometry can look badly magnified for about a minute while calibration is written. The installer can add the publisher's optional Quest 3 + VDXR cache; it is ignored unless the headset and requested resolution match exactly.

## Current v0.1.1 changes

Version 0.1.1 adds field-of-view controls and world scale, turns unsafe automatic FOV derivation off by default, removes roughly a third of redundant render pixels on the measured Quest 3 route and reports settings/cache write failures instead of silently losing them.

## Known alpha limits

The game can occasionally freeze and require Task Manager; progress since the last checkpoint may be lost. Cutscenes are head-locked and can cause discomfort, loading overlays can shrink or follow the hand, and the near-square headset main menu is cropped at the sides. If a view loads fully zoomed, open the settings panel and turn **Field of view: auto** off.

Do not load this plugin on official multiplayer servers. It is intended only for Northstar-launched single-player campaign use. Logs are stored in `%LOCALAPPDATA%\titanfall2vr\titanfall2vr.log`.

## Updates and removal

The Hub follows the newest GitHub release, including prereleases. If Northstar is missing, setup installs its current stable release; an existing functional Northstar installation is preserved. The personal `titanfall2vr.ini` is never overwritten. **Uninstall now** removes only the unchanged VR plugin and optional Hub-owned cache while leaving Northstar, settings, saves and unrelated plugins.

- [titanfall2vr project](https://github.com/TinyBlkDog/titanfall2vr)
- [GitHub releases](https://github.com/TinyBlkDog/titanfall2vr/releases)
- [Northstar](https://github.com/R2Northstar/Northstar/releases)
