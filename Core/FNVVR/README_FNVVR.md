# Fallout: New Vegas VR

## About the Game

Fallout: New Vegas is an open-world role-playing game set in the Mojave. FNVVR Reborn by df4l replaces Direct3D 9 rendering with a stereo SteamVR/OpenVR path and adds tracked hands, interactions, melee, a wrist HUD and VR options. It is still a prerelease; some combat and interface features remain unfinished.

## Requirements and installation

You need the original PC game with `FalloutNV.exe` and `Data/FalloutNV.esm`, SteamVR, a connected headset and a Vulkan-capable GPU. The publisher primarily tested Linux/Proton with a Quest 2; Windows and the listed non-Steam stores need live confirmation. The Windows installer does not use the Proton-only `WINEDLLOVERRIDES` launch option.

1. Close the game. Choose [[Get Installer]] and follow the Enter prompts. The Hub checks the newest GitHub release **including prereleases**.
2. The Hub stages the publisher ZIP, checks `d3d9.dll`, the 32-bit `openvr_api.dll`, `fnvvr` actions/bindings and `dxvk.conf`, then installs them beside `FalloutNV.exe`. It backs up earlier same-name files. If an existing `dxvk.conf` uses a conflicting VR backend, review it before retrying. Existing `fnvvr/vr_options.ini` remains untouched.
3. Start SteamVR, connect the headset, then choose [[Start in VR]]. The Steam edition uses the Steam launch route; other installed copies use their detected executable.

## Controls

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

Turn the back of your right hand toward your eyes to view health, compass, action points and ammunition. Melee hits follow the weapon's physical swing. The game's **Settings > VR** page stores choices in `fnvvr/vr_options.ini`; its Pip-Boy size option can enlarge the display. In v0.7.0, manual reload is on by default for supported weapons. Pull out the spent magazine or cell, take a new one from behind the left shoulder and insert it; rack an empty chamber when needed. Shotguns, lever guns and revolvers use their own physical reload actions. The new **Console** button in Settings opens an in-VR terminal with a laser-operated keyboard.

## Limits and troubleshooting

Manual reload for heavy weapons and launchers, unarmed combat, scopes, finger tracking and some HUD elements remain unfinished. v0.7.0 swaps the old [[Left Trigger]] and [[Left Grip]] binding roles and adds a magazine action. The Hub installs the new `fnvvr/actions.json` and Touch bindings while preserving your personal `fnvvr/vr_options.ini`; update any custom SteamVR bindings yourself. If VR does not start, confirm SteamVR, headset connection, a Vulkan GPU, that the 32-bit `openvr_api.dll` is beside `FalloutNV.exe`, and that `dxvk.conf` selects `d3d9.vrBackend = openvr`. The runtime writes `FalloutNV_d3d9.log` next to the game EXE. The publisher asks for about a minute of reproduction before collecting that log. Real Windows gameplay and headset output remain unverified by the Hub's isolated installer tests.

## Updates and removal

The Hub watches GitHub prereleases. It does not install an older archive if the current release cannot be obtained. [[Uninstall now]] removes unchanged files in the Hub ownership list and restores files that existed before setup. Saves, personal VR settings, later modified files and an existing `dxvk.conf` restored from backup remain. Close the game before updating or removing.

## Links

[Publisher](https://github.com/df4l/FNVVR) · [Releases](https://github.com/df4l/FNVVR/releases) · Join [Flat2VR Modding](https://discord.gg/uAeQkYBM4n), then read the [New Vegas thread](https://discord.com/channels/747967102895390741/1558480358427721798) · [VR gameplay](https://youtu.be/8A6W_p2Yl64)

>>> The Mojave looks different from inside the wasteland.
