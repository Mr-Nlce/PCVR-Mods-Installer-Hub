# Tribes 2 VR

Tribes 2 VR adds stereoscopic OpenVR rendering, head tracking and tracked
motion-controller input to the free community-supported Tribes 2 release.
The mod is an early beta and the required base game is supplied by PlayT2.

## About the Game

Tribes 2 is a classic fast-paced sci-fi team shooter famed for its massive
open maps and iconic jetpack-assisted skiing mechanics. The PlayT2 release is
free and uses the TribesNEXT community patch to keep the game playable online.

## Important: about this mod

This is a promising but early beta. Stereo rendering, head tracking and motion
controls work, but the world scale may feel unusual, the rendered weapon does
not always line up exactly with the physical controller, and there is no
holster system or gesture-based grenade throwing yet. The current body model
works best seated or front-facing; it is not full-body room-scale VRIK.

The renderer uses depth reprojection, so motion can produce edge smearing and
other artifacts. Menus are presented as a flat panel and use pointer input.

## Installing the free game and community patch

If the Hub cannot find a patched installation, setup offers two routes:

1. Download and run the official PlayT2 configuration package. It proposes
   `C:\Dynamix\Tribes2`. Keep **Install community patch** checked. At the end,
   click **I Agree** and then **Apply Patch**. The official installer needs UAC.
2. If the patched game already exists elsewhere, drag `Tribes2.exe` from its
   `GameData` folder onto the installer. Setup verifies both the game and a
   TribesNEXT patch footprint before changing anything.

The VR package is downloaded by you from the Flat2VR Discord post. The
installer opens the server invite first and the exact download post only after
you return and press Enter again. When the download finishes, it searches the
Downloads folder and always offers drag-and-drop as a fallback.

The beta archive does not include `openvr_api.dll`. Setup obtains the official
32-bit Valve OpenVR 2.5.1 runtime from its pinned publisher tag, verifies that
it is a valid x86 Windows DLL, and installs it beside the three mod files in
`GameData`. Historical file names, sizes and hashes are audit information only;
they never block a later readable package with the required functional files.

## Starting in VR

Use **Start in VR** in the Hub or the **Tribes 2 VR** desktop shortcut. Both
launch `GameData\tribes2vr_launcher.exe`; do not start `Tribes2.exe` when you
want VR. The ordinary game executable remains available for flat play.

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move and ski direction |
| [[Left Stick Click]] | Escape / game menu |
| [[Left Trigger]] | Jump / jetpack |
| [[Left Grip]] | Hold the weapon with two hands |
| [[X]] | Use pack |
| [[Y]] | Use repair kit |
| [[Right Trigger]] | Fire |
| [[Right Grip]] | Ski |
| [[Right Stick Up / Down]] | Previous / next weapon |
| [[Right Stick Click]] | Inventory |
| [[A]] | Throw grenade |
| [[B]] | Place mine |
| [[F2]] | Toggle motion controls; mouse and keyboard remain available |
| [[F8]] | Toggle flat-panel mode |
| [[F9]] | Recenter body and hands |
| [[F10]] | Toggle VR camera injection |
| [[F11]] | Toggle head tracking |
| [[F12]] | Toggle the aiming crosshair |
| [[Page Up]] / [[Page Down]] | Move the weapon forward / backward |
| [[Home]] / [[End]] | Move the weapon up / down |
| [[Left Arrow]] / [[Right Arrow]] | Move the weapon left / right |
| [[Insert]] / [[Delete]] | Increase / decrease arm reach |
| [[Left Bracket]] / [[Right Bracket]] | Decrease / increase weapon size |
| [[Numpad +]] / [[Numpad -]] | Increase / decrease perceived world scale |

## Scale, FOV and visual tuning

There is no true FOV control in this beta. The practical tuning is
the live depth/world-scale adjustment on [[Numpad +]] and [[Numpad -]]. Higher
values make the world appear smaller; lower values flatten the scene and can
reduce reprojection smearing. Use [[Left Bracket]] and [[Right Bracket]] separately for weapon size.
Your chosen values are saved in `tribes2vr.ini`; setup preserves that file on
updates. Try the defaults before changing the commented `worldScale` value by
hand.

## Updates and version tracking

This Discord beta is a reviewed fixed package rather than a machine-readable
release feed. The Hub writes the exact receipt
`discord-0.1-beta+openvr-2.5.1` only after the full runtime, patch proof and
ownership manifest survive verification. A later Discord release receives a
new reviewed package identity before the Hub can show an update.

## Discord discussion & support

Join the [Flat2VR Modding community](https://discord.gg/uAeQkYBM4n), then open
the [Tribes 2 VR thread](https://discord.com/channels/747967102895390741/1548700072697528461).
The separate [PlayT2 community Discord](https://playt2.com/discord) covers the
base game and TribesNEXT patch.

## Uninstall

Use **Uninstall now** on the game page. It removes only unchanged Hub-owned VR
launcher, mod, OpenVR runtime and icon files, restores any files that existed
before setup, and preserves changed files for safety. Tribes 2, TribesNEXT,
profiles, downloaded maps and unrelated GameData files remain installed.

## Links and credits

- [Free game and community patch](https://playt2.com/config)
- [Tribes 2 VR Discord thread](https://discord.com/channels/747967102895390741/1548700072697528461)
- [Ordinary gameplay video](https://www.youtube.com/watch?v=_e3eIqFNRtI)
- [Valve OpenVR 2.5.1](https://github.com/ValveSoftware/openvr/releases/tag/v2.5.1)

*Shazbot. The skiing line now runs straight through your headset.*
