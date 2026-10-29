# Tomb Raider: Legend VR

## About the Game
Follow Lara Croft across ancient ruins, mountain temples and modern cities in an acrobatic search for the fragments of a legendary sword.

## Requirements
Steam or GOG PC game, an active OpenXR runtime (or SteamVR fallback), tracked controllers and a Vulkan-capable GPU. Retail builds are not publisher-confirmed and are not advertised as supported here.

## Install and start
1. Run the game once in flat. In its Setup dialog turn Next Generation Content OFF, then quit. That renderer gives a black scene in VR.
2. Choose Install in the Hub. The complete Main payload is installed; your earlier GOG D3D9.dll or graphics wrapper is backed up.
3. Steam: follow the dedicated Launch Options step. Paste the complete quoted launcher path followed by %command%, as shown and copied by the installer.
4. Connect your headset and start its OpenXR runtime (or SteamVR), then use Start in VR in the Hub. Alternative: Tomb Raider Legend VR desktop shortcut. Steam copies start through Steam after configuring its launch options; GOG copies start the publisher launcher directly.

The launcher makes a large-address-aware trl_vr.exe copy. Your original trl.exe is never patched. Flat / VR parks the VR proxy; close the game before switching. Flat mode is preserved during a later update.

## Controls
| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Left Stick Click]] | Gear menu; double click recenters; hold pauses |
| [[Right Stick]] | Turn |
| [[Right Stick Click]] | Switch weapons; double click PDA; hold cycles camera styles with immersive controls |
| [[Left Trigger]] | Action, interact or pull the grapple |
| [[Right Trigger]] | Fire or select a menu item |
| [[Left Grip]] | Throw grapple; immersive mode grabs the left hand's nearby hold or gear |
| [[Right Grip]] | Lock-on; immersive mode grabs the right hand's nearby hold or gear |
| [[A]] | Jump, surface or confirm |
| [[B]] | Dive, crouch, roll or go back |
| [[X]] | Accurate aim in the classic layout |
| [[Y]] | Tap grenade/flare; hold personal light in the classic layout |
| [[Left Stick Click]] + [[Right Stick Click]] held 0.6 seconds | Open the headset VR settings panel |
| [[Left Menu]] or [[Insert]] | Open the headset VR settings panel |
| [[F1]] | Recenter |
| [[\]] | Switch first/third person during gameplay |

Immersive controls start enabled. In first person, draw weapons from your holsters and climb using your hands. The pause menu's VR Settings includes hand calibration and holster placement. The shipped VR CONTROLLER BINDINGS.txt covers Index, WMR and Reverb layouts.

## Help
Version 1.1.0 defaults to OpenXR and falls back to OpenVR if necessary. VR settings include the runtime preference, which is saved for later starts.

Black scene: confirm Next Generation Content is OFF. Blurry image: adjust SteamVR's per-game resolution. The mod disables depth of field/fullscreen effects and enables capped anti-aliasing by default. The original On/Off column in VR Settings is not authoritative; read the changed label. If required files are missing, inspect the installer log and chosen game folder first. Windows protection history can identify a matching detection; missing files alone do not establish an antivirus cause. Retry setup or hand over the official package on its recovery page.

## Technical details
The game folder contains d3d9.dll, d3d9_dxvk.dll, openvr_api.dll, trlvr_launcher.exe and its action/binding JSON files. The launcher-generated copy is trl_vr.exe. The mod creates trlvr.ini on first launch; existing settings are kept. Licences and publisher instructions are in TRLVR docs. Steam Launch Options: the quoted full path to trlvr_launcher.exe followed by %command%.

## Discord discussion & support
[Flat2VR invite](https://discord.gg/uAeQkYBM4n)
[Tomb Raider Legend discussion](https://discord.com/channels/747967102895390741/1547484010585002044)

## Links
[Mod source and full controls](https://github.com/RototRobot/Tomb-Raider-Legend-VR-Port)
[Publisher releases](https://github.com/RototRobot/Tomb-Raider-Legend-VR-Port/releases)
[VR gameplay](https://youtu.be/TGe_CxinSLc?t=433)

>>> A grappling hook is cheaper than another plane ticket.
