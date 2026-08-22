# AWAY VR Installer

Automated installer for **AwayVR** by **Pk-c** - a VR conversion of **AWAY: Journey to the Unexpected** (Aurelien Regard Games). Not a screen in a headset: 6DOF with tracked hands, melee that you swing with your arm, grenades thrown as hard as you actually throw them, and the game's flat interface rebuilt as panels.

## Requirements

| | |
|---|---|
| Game | **AWAY: Journey to the Unexpected** on Steam or GOG |
| Runtime | **SteamVR**, running with the headset on **before** the game starts |
| Renderer | Direct3D 11 - the mod switches this for you |

## What it does
- Finds the game and unpacks the mod into its folder. That is the whole installation - the author's own instructions are "extract into the game folder and enjoy".
- Verifies afterwards that every file really arrived, including the backup of the file it replaces.
- Records the install so the Hub can flag new releases.

Two files in the archive deserve a mention, because they explain why this mod works at all:

**`globalgamemanagers` ships already patched.** Unity reads that file before the mono runtime exists, so no plugin could switch the VR device on in time. It holds build settings only - no assets, no code - and the original travels along as `.orig`. The same patch also puts **Direct3D 11** back at the head of the graphics API list, because Unity 2017's built-in VR fails *silently* under D3D12.

## Controls

- [[Right Trigger]] attack
- [[Swing your arm]] attack with melee weapons
- [[Right Grip]] guard
- [[Left Grip]] grenade: squeeze to arm, release to throw
- [[Left Trigger]] hold to show the HUD
- [[A]] jump, confirm, advance dialogue
- [[B]] next character, advance dialogue
- [[X]] open or close the diary
- [[Y]] pause menu, cancel
- [[Right Stick Down]] / [[Right Stick Up]] next / previous character
- [[Both Stick Clicks]] the mod's VR settings

No SteamVR configuration is needed. **A** and **X** are read from OpenVR directly - Unity's legacy input layer gives those two buttons no joystick index at all, which is why most Unity VR mods cannot use them.

The grenade leaves your hand in the direction of the throw, and as hard as you threw it. The robot is a lock-on weapon: look at an enemy to lock it, then fire.

## Settings menu
Click **both sticks**. Everything applies live.

| Section | What it holds |
|---|---|
| Controls | walking speed and dead zone, snap or smooth turn, turn angle and speed |
| Weapon | weapon size, swing threshold, trail, damage volume placement, knockback, throwing power |
| Graphics | world scale, colour grading |
| Effects | render scale, one switch per full-screen effect, shadows, level of detail |
| Interface | HUD always visible, HUD size and distance |
| Player | head centring, room-scale walking, camera blocked by walls, player height |
| System | frame-rate counter, reset everything |

**Two of them undo assumptions that only hold on a flat screen.** *Hit box* decides where a melee blow's damage volume goes - the game pins it two metres ahead of the headset, so it rides on your posture and sinks when you crouch. *Knockback* decides which way a struck enemy flies - the game pushes it along the body's forward, which is "away from you" only because on a screen you always face what you hit.

Everything is stored in `BepInEx/config/fr.awayvr.plugin.cfg`, which also holds the finer options that are not in the menu: grenade offsets, swing threshold, fade timings and the input bindings.

## If something is wrong
`BepInEx/LogOutput.log` says what happened.

| Message | Meaning |
|---|---|
| `is not in enabledVRDevices` | `globalgamemanagers` was not copied, or a game update replaced it - run this installer again |
| `Unity 2017 VR requires Direct3D 11` | add `-force-d3d11` to the Steam launch options |
| `XR activation failed` | SteamVR is not running, or the headset is not detected |

If input misbehaves, set `OpenVrBridge` to `false` in the config **with the game closed**: the mod falls back to Unity's own input and loses only A and X.

## Removing it
Double-click **`uninstall VR.bat`** in the game folder. It restores the original configuration file, removes every file the mod added, and deletes itself.

## Support the developer
Pk-c builds these mods to feel native rather than bolted on. If you enjoy the work, consider supporting him:
- Patreon: https://www.patreon.com/cw/ChromaticMod

## Credits
**AWAY: Journey to the Unexpected** is by **Aurelien Regard Games**. The VR mod is by **Pk-c**, is unofficial, and is not affiliated with the developer or publisher. No game assets or game code are redistributed.

https://github.com/Pk-c/AwayVR

>>> The narrator promised an adventure. He did not promise your arms would be this tired.
