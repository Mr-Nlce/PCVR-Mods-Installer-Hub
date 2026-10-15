# PowerWash Simulator 2 VR

**Mod:** Wet Reality XR Mod by onetin84  
**Status:** beta / prerelease, automatically updated from GitHub  
**Publisher-tested game:** PowerWash Simulator 2 on Steam (App 2968420)  
**VR gameplay:** https://youtu.be/57vS_Zzclpk  
**Mod page and support:** https://github.com/onetin84/Wet-Reality-XR-PWS2

## Current and pinned depot

Setup offers **[1] Current** for the normal game and newest prerelease mod, or
**[2] Depot** for a separate Steam build **23737596** (App 2968420, depot
2968422, manifest 2576393139753962022). This depot always installs Wet
Reality XR **v1.107.0-beta**, MelonLoader **0.7.3 x64**, portable .NET
**6.0.36** and Unity OpenXR **1.18.0** from fixed publisher URLs. It does not
follow future Current mod releases. Setup can copy an installed Steam build
only when its manifest and game files match; otherwise it guides an exact
Steam Console depot download. The copies can coexist and receive separate Hub
launch choices. The depot has its own `steam_appid.txt`.

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

For Current, the Hub downloads the newest GitHub release, including prereleases, and installs its two Wet Reality assemblies. The Depot route uses the fixed version above. Both routes install the runtime chain required by the mod:

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
| [[Right Stick Click]] | Open the equipment wheels; press again to accept and close. With `WasherWheel=false`, hold for the old washer-brand cycle |
| [[Left Stick]] | Walk; push fully to sprint; navigate menus |
| [[Left Trigger]] | Rotate nozzle/refill detergent, or interact while the hand touches an animated object |
| [[Left Grip]] | Highlight dirt; previous tab in menus |
| [[Left X]] | Pick up or put down an object |
| [[Left Y]] | Task list; hold for furniture inventory |
| [[Menu]] | Pause, back or close the current menu |
| [[Left Stick Click]] | Switch extension |
| [[F8]] | Start VR manually if automatic activation failed |
| [[F2]] | Hand the washer between VR controllers and mouse/keyboard control |
| [[Keypad 3]] | Recenter the washer and seated position |

Body-zone gestures and object-carrying controls are shown in the included publisher quick guide. `F6` is a disabled development hotkey in this release and is not the configurator shortcut.

## Current v1.123.2-beta update

The configurator adds **Vibration stops after** (0–15 seconds). The publisher
recommends 1.5 seconds to save controller battery; the default **never** keeps
the previous continuous vibration. Existing settings stay on update.
This includes the v1.123.1-beta nozzle fixes below.

The turbo nozzle spins again. Both jets of the double turbo and all three
trident jets now clean where they visibly land; the second double-turbo jet
also starts at the correct offset. The menu beam can select lower buttons in
the headset, and vibration follows the strength of each nozzle category.
[[F2]] now reliably hands the washer back to mouse and keyboard. The
adaptable nozzle width controlled with the washer-hand [[Stick]] up/down while
spraying has now been tested. Each new behavior can be disabled separately in
the configurator with `TurboSpin`, `JetPerNozzle`, `MenuEyeFrustum` or
`HapticByCategory`. Existing settings are retained on update.

### Earlier v1.121.1-beta changes

The game's equipment wheels now expose purchased washer tiers, nozzles and
extensions. Hold [[Right Stick Click]] to open them. Aim the selection beam and
press [[Right Trigger]] to choose; [[Grip]] steps between wheels. Press
[[Right Stick Click]] again to accept and close. While a wheel is open, the
trigger selects instead of spraying. Without beam aiming, [[Right Stick]]
selects a segment, [[Left Stick]] left/right changes the washer tier and
[[A]] accepts. Set `WasherWheel=false` in the configurator to restore the older
hold-to-cycle behavior. Set `AdaptableWidthStick=false` if you prefer the
earlier adaptable-nozzle behavior. Existing settings remain in place.

The previous v1.114.0-beta update

v1.114.0-beta fixes the billboard swing: point down at the occupied walkway
and press [[X]] to pick it up, then point at the other side and press [[X]]
again. [[Y]] continues through the job-complete prompt and other Escape-style
menus. The earlier build was a major comfort and navigation update. It adds target and
comfort teleport, snap turning, a comfort vignette, free-hand aiming, adjustable
washer-stick position, corrected range measurement and more reliable stair and
ramp paths. Hold and release [[Menu]] to toggle the UI; [[B]] closes Escape-style
popups. Ladder handling, pointer colors and target size are configurable. A
one-eye ground-brightness difference is still cosmetic; disable fog or light
scattering in the configurator if either effect is uncomfortable.

In v1.107.0-beta the grab pointer, menu pointer and teleport arc now stay at
the tracked hand while walking. The earlier v1.105 update also fixes hand
sliding on the washer grip. Existing settings remain in place on update.

>>> Every stubborn stain is now within arm's reach.
