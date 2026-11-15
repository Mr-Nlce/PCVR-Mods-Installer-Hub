# Fallout: New Vegas VR

## About the Game

Fallout: New Vegas is an open-world role-playing game set in the Mojave. FNVVR Reborn by df4l replaces Direct3D 9 rendering with a stereo SteamVR/OpenVR path and adds tracked hands, interactions, melee, a wrist HUD and VR options. It is still a prerelease; some combat and interface features remain unfinished.

## Requirements and installation

The installer offers **1. FNVVR** and **2. TTWVR**. Option 2 requires New Vegas Ultimate Edition, uses its own MO2 profile and guides you through the Tale of Two Realities Discord and Nexus downloads. For TTWVR, join the server when prompted, then download `TTWVR.zip` from the newest message at the bottom of **#announcements** and enter the version from that message. If setup offers a separate game copy, drop an empty folder into the installer, paste a full path, or press Enter for the suggested location. Follow the numbered MO2 checklist in the installer. Choose **A Tale of Two Realities** in the Hub to play both Fallout 3 and New Vegas.

You need the original PC game with `FalloutNV.exe` and `Data/FalloutNV.esm`, SteamVR, a connected headset and a Vulkan-capable GPU. The publisher primarily tested Linux/Proton with a Quest 2; Windows and the listed non-Steam stores need live confirmation. The Windows installer does not use the Proton-only `WINEDLLOVERRIDES` launch option.

To update **TTWVR**, choose **Update** for TTWVR or select **2. TTWVR** when you reopen the installer. With a verified MO2 profile, setup opens the TTWVR-only update. Supply the current Discord ZIP to keep the existing profile, dependencies, saves and calibration.

1. Close the game. Choose [[Get Installer]] and follow the Enter prompts. The Hub checks the newest GitHub release **including prereleases**.
2. The Hub stages the publisher ZIP, checks `d3d9.dll`, the 32-bit `openvr_api.dll`, `fnvvr` actions/bindings and `dxvk.conf`, then installs them beside `FalloutNV.exe`. It backs up earlier same-name files. If an existing `dxvk.conf` uses a conflicting VR backend, review it before retrying. Existing `fnvvr/vr_options.ini` remains untouched.
3. Start SteamVR, connect the headset, then choose [[Start in VR]]. The Steam edition uses the Steam launch route; other installed copies use their detected executable.

Version 0.17.0 adds a hand-operated slot machine lever, improves scope reticles, and fixes a crash when closing desk terminals. Setup installs the complete `fnvvr` directory, including Steam Frame bindings, while preserving your VR options. Start SteamVR before launching the game.

Version 0.10.0 expands physical object handling, remote grabbing, two-hand grips, body dragging and the chest inventory. These features remain work in progress; consult the publisher release notes before changing your bindings.

## Controls

Version 0.8.0 adds physical grenades, thrown weapons, heavy-weapon reloads and Touch finger sensing. The Hub replaces the publisher's action/binding files while preserving your VR options. After an update from 0.7.0, reload SteamVR's default bindings once; custom bindings need the two new hand-skeleton actions.

Arm grenades with your left hand, then throw with your right. Mines can be dropped while still; throwing knives, spears and axes need no arming. Heavy weapon ammunition boxes, cells and canisters reload like magazines; open the minigun box lock first. Push a new missile or mini-nuke into an empty launcher tube. Flamers and incinerators still reload with [[X]].

| Button | Action |
|---|---|
| [[Left Stick]] | Move. |
| [[Right Stick]] | Turn. |
| [[A]] | Interact with what the right hand points at. |
| [[X]] | Interact with what the left hand points at. |
| [[Right Grip]] near the left wrist | Toggle the Pip-Boy light. |
| [[Either Trigger]] while holding a melee weapon | Charge a power attack; the next hit consumes action points. |
| [[Left Grip]] near a weapon | Hold a rifle, pistol or two-handed melee weapon with both hands. |
| [[Left Trigger]] near a magazine, round or moving part | Grab it for manual reload. Take fresh ammunition from behind the left shoulder. |
| [[B]] or [[Esc]] | Close the new in-VR console terminal. |
| [[Right Stick]] in the console | Scroll terminal output. |
| [[Left Grip]] / [[Left Trigger]] near a grenade pin | Grab and pull the pin. |
| [[Left Trigger]] | Strike the lighter for a fuse; press near a grenade switch or mine light to arm it. |
| [[Right Trigger]] | Hold, swing and release to throw an armed grenade or thrown weapon; press to release a mine. |

Turn the back of your right hand toward your eyes to view health, compass, action points and ammunition. Melee hits follow the weapon's physical swing. The game's **Settings > VR** page stores choices in `fnvvr/vr_options.ini`; its Pip-Boy size option can enlarge the display. In v0.7.0, manual reload is on by default for supported weapons. Pull out the spent magazine or cell, take a new one from behind the left shoulder and insert it; rack an empty chamber when needed. Shotguns, lever guns and revolvers use their own physical reload actions. The new **Console** button in Settings opens an in-VR terminal with a laser-operated keyboard.

## Limits and troubleshooting

Unarmed combat, scopes, V.A.T.S. fixes and some HUD elements remain unfinished. v0.7.0 swaps the old [[Left Trigger]] and [[Left Grip]] binding roles and adds a magazine action. The Hub installs the new `fnvvr/actions.json` and Touch bindings while preserving your personal `fnvvr/vr_options.ini`; update any custom SteamVR bindings yourself. If VR does not start, confirm SteamVR, headset connection, a Vulkan GPU, that the 32-bit `openvr_api.dll` is beside `FalloutNV.exe`, and that `dxvk.conf` selects `d3d9.vrBackend = openvr`. The runtime writes `FalloutNV_d3d9.log` next to the game EXE. The publisher asks for about a minute of reproduction before collecting that log. Real Windows gameplay and headset output remain unverified by the Hub's isolated installer tests.

## Updates and removal

The Hub watches GitHub prereleases. It does not install an older archive if the current release cannot be obtained. [[Uninstall now]] removes unchanged files in the Hub ownership list and restores files that existed before setup. Saves, personal VR settings, later modified files and an existing `dxvk.conf` restored from backup remain. Close the game before updating or removing.

## Links

[Publisher](https://github.com/df4l/FNVVR) · [Releases](https://github.com/df4l/FNVVR/releases) · Join [Flat2VR Modding](https://discord.gg/uAeQkYBM4n), then read the [New Vegas thread](https://discord.com/channels/747967102895390741/1558480358427721798) · [VR gameplay](https://youtu.be/8A6W_p2Yl64)

For option 2, [join the Tale of Two Realities Discord](https://discord.gg/TrJyyZEds) and check the [TTWVR release channel](https://discord.com/channels/1570233209462194208/1570238629832564858).

>>> The Mojave looks different from inside the wasteland.
