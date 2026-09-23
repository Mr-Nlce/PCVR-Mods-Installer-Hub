# Prey (2006) VR

PreyVR PCVR brings the complete 2006 campaign to 64-bit Windows through
OpenXR, with room-scale movement, tracked motion controllers, two-handed
weapon support and a separate flatscreen launcher.

## About the Game

Prey (2006) is a first-person science-fiction shooter built around gravity
walkways, portals, spirit walking and a living alien ship. This is the original
Human Head game, not Arkane's 2017 title.

The port needs your own Prey (2006) data patched to version 1.4. Steam and GOG
already contain that patch. A retail-disc installation must be updated first.
The publisher release contains no commercial game data.

## Installation folder and owned data

The VR port is a separate portable installation. Setup proposes
`C:\Games\PreyVR`, but you may type or paste any other full folder path before
anything is installed. Updates reuse the folder you selected previously.

The installer finds the original game or accepts its install/base folder. It
requires `pak000.pk4` through `pak006.pk4`, copies those seven files into the
standalone `preybase` folder and uses the publisher's tool to build
`vr_support.pk4` locally. The original installation is never modified.

The Hub owns only the downloaded PreyVR runtime and the generated support
package. Your retail PK4 files, saves, settings and unrelated files remain
yours and are not deleted by the uninstaller.

## Starting and OpenXR

Activate the OpenXR runtime you want to use, then choose **Start in VR** in the
Hub or launch the **Prey (2006) VR** desktop shortcut. The publisher has tested
a Quest 3 through Virtual Desktop with VDXR. SteamVR's OpenXR runtime starts
the game and creates a session, but a complete headset playthrough there has
not yet been reported by the publisher; the Oculus runtime is untested.

`Play PreyVR flatscreen.bat` starts the same build in a window without opening
a VR runtime. Configuration, saves and `qconsole.log` are all stored below
`saves\preybase` inside the selected portable folder.

## Controls

| Button | Action |
|---|---|
| [[Right Trigger]] | Fire |
| [[Right Grip]] | Alternate fire |
| [[Right Stick Left / Right]] | Smooth turn; snap turning can be selected in VR options |
| [[Right Stick Up / Down]] | Hold the weapon wheel, choose, then release; optionally previous / next weapon |
| [[A]] | Crouch |
| [[B]] | Jump |
| [[Left Stick]] | Move in look direction; hand-directed movement is optional |
| [[Left Stick Click]] | Spirit walk |
| [[Left Trigger]] | Run |
| [[Left Grip]] | Two-handed weapon support and weapon zoom |
| [[X]] | Lighter |
| [[Y]] | Throw grenade |
| [[Either Menu Button]] | Pause menu |
| [[Either Trigger]] | Point and select in menus |

Handedness, height, movement direction, smooth/snap turning, portal distance,
desktop mirror and the other VR options are available on the in-game
**Options -> VR** page.

## Visual quality and known limitations

`vr_supersampling` is the main resolution control. The shipped `1.0` already
uses the resolution requested by your OpenXR runtime. If performance is low,
the publisher recommends reducing bloom range, then shadows, then
supersampling. `vr_msaa` has no effect on this PC renderer.

- World keypads and other in-world GUIs are aimed with your head, not a hand.
- Portals can turn black beyond roughly fifteen feet because the missing
  proprietary renderer code cannot open the original portal visibility link.
- Quest passthrough / mixed reality is unavailable on PC and its menu switch
  is inert.
- Some stock Prey warnings in `qconsole.log` are harmless. For a crash, keep
  both `crash.txt` beside the executable and `saves\preybase\qconsole.log`.

## Updates and version tracking

The installer follows stable GitHub releases automatically. A version is
committed only after the complete runtime, OpenXR loader, all seven owned game
data files, locally generated `vr_support.pk4` and both ownership manifests
have survived verification. Historical archive names, sizes and hashes are
documentation only and never block a later valid release.

## Discord discussion & support

Join the [Flat2VR Modding community](https://discord.gg/uAeQkYBM4n), use
**Join Channels** if needed, then open the
[Prey (2006) VR channel](https://discord.com/channels/747967102895390741/1549901041384947772).

## Uninstall

Use **Uninstall now** on the game page. It removes only unchanged Hub-owned
runtime files and the locally generated support package. Changed files are
preserved, and any files that existed before installation are restored. The
seven copied retail PK4 files, configuration, saves and unrelated files remain
in the standalone folder. Delete that folder manually only if you no longer
want those user-owned copies.

## Links and credits

- [PreyVR PCVR project and documentation](https://github.com/GameOrDie007/Prey-2006-VR)
- [Stable releases](https://github.com/GameOrDie007/Prey-2006-VR/releases)
- [VR gameplay](https://youtu.be/N3nXxGSVerI?t=295)
- Windows/OpenXR work by GameOrDie007, based on PreyVR by lvonasek and the
  credited id Tech / Team Beef project family. See the project README for the
  full contributor and license chain.

*The Sphere was never built for personal space.*
