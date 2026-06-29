# UEVR Deluxe

**UEVR Deluxe** (Unreal Easy Injector) by **ODuis** - a user-friendly frontend for **praydog's UEVR**, the Universal Unreal Engine VR mod. Plays a huge range of flat **Unreal Engine 4 & 5** games in 6DOF VR. UEVR Deluxe wraps praydog's engine module in an easy, automated app with an online profile database.

> This is an **external** tool: the Hub links you to uevrdeluxe.org. Download the UEVR Easy Injector setup from its releases - you do **not** need UEVR Classic; the backend is bundled.

## What you get (UEVR engine)
- Full 6DOF head tracking and stereoscopic 3D out of the box
- Native UE4/UE5 stereo rendering; three modes: Native Stereo, Synchronized Sequential, and Alternating/AFR
- Optional 3DOF motion controls and roomscale in many games
- Automatic handling of most in-game UI, projected into 3D space
- OpenVR and OpenXR runtime support

## What UEVR Deluxe adds
- Auto-scans your Steam / Epic / GOG / Xbox library and filters likely Unreal Engine games
- Online **profiles database** for one-click discovery and install (no more hunting Discord for configs and PAKs)
- Author notes on how to use each profile
- Voice commands and global hotkeys
- One-click UEVR Nightly backend updates and a profile editor

## Requirements
- A **powerful modern PC** - VR renders at very high resolution and is sensitive to low frame rates. If a game doesn't hit high FPS flat, it likely won't in VR.
- A game built on **Unreal Engine 4 or higher** (very newest UE versions can be problematic). Tip: google "<game name> Unreal Engine version".
- An OpenVR/OpenXR headset (Oculus, Index, Vive, WMR, Pimax, and more tested)
- DLSS is usually needed for acceptable VR performance

## How to install (external)
1. Open the info page (uevrdeluxe.org) and download the latest UEVR Easy Injector release.
2. Run it; it lists installed UE games that might work.
3. Pick a game, install a profile if one exists, and inject. Follow the in-app guidance and warnings.

Full beginner walkthrough: https://uevrdeluxe.org/UEVRTutorial.html

## Performance tips (from the tutorial)
- Find the FPS your PC sustains flat (use the streaming performance overlay), set the VR frame rate to ~double that and enable SSW - leaving VR FPS too low causes input lag despite a smooth-looking image.
- Consider enabling "Increase color vibrance" and disabling "Increase nominal range" to avoid blown-out shadows.

## Credits
- UEVR engine by **praydog** - https://github.com/praydog/UEVR
- UEVR Deluxe frontend by **ODuis** - https://github.com/oduis/UEVRDeluxe
- Profiles from the Flat2VR community and other sources

## Support the developer
praydog develops UEVR. If you enjoy his work, consider supporting him:
- Patreon: https://www.patreon.com/c/praydog

>>> Thousands of Unreal Engine games, one step into VR.
