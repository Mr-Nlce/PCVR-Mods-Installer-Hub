# High Entropy: Challenges VR

## About the Game

High Entropy: Challenges is a free first-person action and puzzle game. Its
levels let you unlock doors, crawl through vents, use computers and find ways
around enemies. The VR mod adds full stereo OpenXR, head-tracked looking,
tracked-hand aiming and interaction, and a floating HUD.

## Mod and compatibility

King-EJ's current public package describes itself as version 0.1.5, a Quest 3
test build for the 64-bit Unity 2022.3.62f2 Mono game. It bundles BepInEx,
the HECVR plugin and its OpenXR bridge. The author lists SteamVR, Meta/Oculus,
Virtual Desktop and WMR OpenXR runtimes; the supplied release does not claim
that each headset has been independently tested. The package is free and its
OpenXR bridge license restricts commercial redistribution.

The game itself is free on [Steam](https://store.steampowered.com/app/1389630/).
Install and launch it flat once, then close it. The Hub looks for
`HighEntropy.exe` and Unity game data before writing VR files. The publisher
ZIP is copied beside that EXE. It contains its own BepInEx runtime; a second
Thunderstore BepInEx download is not needed. The Hub preserves existing
configuration, saves and unrelated files, and backs up filename collisions.

This publisher uses a constant GitHub release tag and ZIP filename. The Hub
reads the version printed inside the downloaded archive rather than treating
the constant tag as a version. A replacement under the same tag needs a manual
source check; do not infer a new package from the tag alone.

## Start and settings

Start the active OpenXR runtime, then launch High Entropy from Steam. In the
game's options, set Input device to Automatic or Gamepad rather than
Keyboard/Mouse. VR controllers are exposed to the game as an Xbox-style pad;
menu, inventory, weapon wheel and computer controls follow the game's own
gamepad mapping. Remap them under Options > Controls > Gamepad.

With the VR input active, keyboard and mouse cannot navigate the main menu.
If the game is still set to Keyboard/Mouse, use Virtual Desktop's Gamepad mode
to navigate Options > Controls, change Input device to Gamepad (or Automatic),
then return to the VR controllers.

The right-hand blue pointer targets doors, items and switches. The held weapon
follows the VR hand; bullets, bolts and melee use its aim. The left trigger
shows an aiming laser. The HUD and menus float in space and can also be placed
on a hand. Gamepad rumble drives controller vibration.

### Controls

These are the publisher's default right-handed Quest-style mappings. The
game's own gamepad remapping and the VR configuration can change them.

| Button | Action |
|---|---|
| [[Right Trigger]] | Fire |
| [[Left Trigger]] | Aim or zoom; show the laser |
| [[Right Grip]] | Reload |
| [[Left Grip]] | Grenade |
| [[A]] | Jump or confirm |
| [[B]] | Crouch or back |
| [[X]] | Interact; the author personally remaps this to B |
| [[Y]] | Secondary interaction |
| [[Left Stick]] | Move |
| [[Left Stick Click]] | Run; the author personally remaps this to LT |
| [[Left Stick Hold]] | Open the game menu |
| [[Right Stick]] left or right | Smooth turning; menu navigation in menus |
| [[Right Stick]] up or down | D-pad up/down: night vision or medkit |
| [[Right Stick Click]] tap | D-pad left: weapon wheel |
| [[Right Stick Click]] hold | Select: inventory |
| [[Left Stick Click]] + [[Right Stick Click]] | Recenter the view |
| [[Right Controller Pointer]] | Point at doors, items and switches |

## Configuration and recovery

On first launch, BepInEx creates or updates `BepInEx\config\hec.vr.cfg`; edits
apply live. Its `GamepadMapping` section sets VR-to-pad buttons. `Weapons` and
per-weapon sections tune hand position, laser and barrel alignment.
`Interaction` controls pointer use, `Camera` controls height and smoothing,
and `UI` controls floating-screen placement. Back up the file before editing.

To disable the mod temporarily, the publisher recommends renaming
`winhttp.dll` or setting `enabled = false` in `doorstop_config.ini`. The latter
can affect another BepInEx mod in the same game folder. The Hub's direct
Uninstall now action removes only unchanged Hub-owned files, restores
pre-existing files with the same names and keeps changed files, game data and
saves. The detail page's Uninstall guide explains that action.

If required files are missing after setup, use the installer's Recovery screen
to inspect its log and retry. A missing DLL alone does not prove antivirus
quarantine; also check target path, permissions and copy errors. For game-side
issues, examine `BepInEx\LogOutput.log` and the game's Unity player log.

Publisher package and instructions: https://github.com/King-EJ/High-Entropy-Challenges-VR

>>> When the doors will not open, the right answer is often a terminal.
