# PowerWash Simulator 2 VR

**Mod:** Wet Reality XR Mod by onetin84  
**Status:** beta / prerelease, automatically updated from GitHub  
**Publisher-tested game:** PowerWash Simulator 2 on Steam (App 2968420)  
**VR gameplay:** https://youtu.be/57vS_Zzclpk  
**Mod page and support:** https://github.com/onetin84/Wet-Reality-XR-Mod

## About the Game

PowerWash Simulator 2 is a relaxing cleaning simulation built around detailed jobs, upgraded tools and satisfying before-and-after transformations. Wet Reality puts the washer directly in your hands with tracked motion controls, two-handed handling, haptics, head movement and roomscale support.

This mod is for **PowerWash Simulator 2 only**; the first PowerWash Simulator is unsupported. The mod publisher tests the Steam release. The Hub also recognizes complete Epic Games Store and Xbox App / Microsoft Store installations, but those builds remain publisher-unverified for VR. Detecting their game files is not a claim that headset operation has been confirmed on those storefront builds.

Recognized default locations:

- Steam: `C:\Program Files (x86)\Steam\steamapps\common\PowerWash Simulator 2\PowerWash Simulator 2.exe`
- Epic Games Store: `C:\Program Files\Epic Games\PowerWashSimulator2\PowerWash Simulator 2.exe`
- Xbox App / Microsoft Store: `C:\XboxGames\PowerWash Simulator 2\Content\PowerWash Simulator 2.exe`
- Protected WindowsApps fallback: `C:\Program Files\WindowsApps\<PowerWash-Simulator-2-Paketordner>\PowerWash Simulator 2.exe`

The WindowsApps package name varies. Setup searches accessible matching package folders and otherwise offers Locate Game; it never stores the placeholder as a real path. Windows may deny direct write access to a protected package, in which case setup stops before modifying the game.

## What setup installs

The Hub downloads the newest GitHub release, including prereleases, and installs its two Wet Reality assemblies. It also installs the publisher-pinned runtime chain required by the mod:

- MelonLoader x64 0.7.3 when no existing MelonLoader installation is present
- portable .NET 6.0.36 inside the game folder
- Unity OpenXR 1.18.0 files from Unity's public package registry
- the publisher configurator and English/German quick guide in `WetRealityXR`

Every copied file is recorded in a Hub ownership manifest. Existing collisions are backed up before replacement. Update, rollback and **Uninstall now** use the same manifest in reverse; a file changed after installation is preserved instead of being overwritten or deleted.

## Before the first VR launch

Have your OpenXR headset software running before starting the game. The mod author tested Meta Quest 3 with OpenXR/VDXR; other OpenXR headsets are not yet publisher-confirmed.

Remove UnityExplorer from the `Mods` folder while playing. The publisher reports that it prevents menu selection.

The first launch can remain quiet for about 30 seconds while MelonLoader prepares support files and requires an internet connection. This is expected.

## Start in VR

Use **Start in VR** in the Hub as the primary route. A detected Steam installation launches Steam App 2968420 so Steamworks and licensing initialize normally. A recognized non-Steam installation uses its recorded game executable; if that store requires its own bootstrap, use the normal Epic or Xbox launcher as the fallback. VR activates automatically after the game starts. Launching from the Steam Library is the secondary Steam route.

Use `WetRealityXR\Configurator.cmd` in the game folder for settings and the publisher quick guide.

## Controls

| Button | Action |
|---|---|
| [[Right Trigger]] | Spray while held; confirm in menus |
| [[Right Grip]] | Toggle continuous spray; next tab in menus |
| [[Right A]] | Jump; confirm in menus |
| [[Right B]] | Crouch |
| [[Right Stick]] | Turn; up/down changes nozzle |
| [[Right Stick Click]] | Switch nozzle category; hold to switch washer |
| [[Left Stick]] | Walk; push fully to sprint; navigate menus |
| [[Left Trigger]] | Rotate nozzle/refill detergent, or interact while the hand touches an animated object |
| [[Left Grip]] | Highlight dirt; previous tab in menus |
| [[Left X]] | Pick up or put down an object |
| [[Left Y]] | Task list; hold for furniture inventory |
| [[Menu]] | Pause, back or close the current menu |
| [[Left Stick Click]] | Switch extension |
| [[F8]] | Start VR manually if automatic activation failed |
| [[F2]] | Toggle motion-controlled washer mode; press twice if the left stick stops responding |
| [[Keypad 3]] | Recenter the washer and seated position |

Body-zone gestures and object-carrying controls are shown in the included publisher quick guide. `F6` is a disabled development hotkey in this release and is not the configurator shortcut.

## Current v1.86.0-beta update

The current build is a major comfort and navigation update. It adds target and
comfort teleport, snap turning, a comfort vignette, free-hand aiming, adjustable
washer-stick position, corrected range measurement and more reliable stair and
ramp paths. Hold and release [[Menu]] to toggle the UI; [[B]] closes Escape-style
popups. Ladder handling, pointer colors and target size are configurable. A
one-eye ground-brightness difference is still cosmetic; disable fog or light
scattering in the configurator if either effect is uncomfortable.

## Remove the mod

Use **Uninstall now** on the Hub detail page. It removes only unchanged Hub-owned files, restores pre-existing collisions and keeps the game, saves and `UserData\MelonPreferences.cfg`. If MelonLoader existed before this installation, it remains installed.
