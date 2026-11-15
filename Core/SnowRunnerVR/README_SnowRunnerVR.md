# SnowRunner VR

## About the Game

SnowRunner is an off-road driving simulation about moving cargo through mud, snow and difficult terrain. Timguin-87's OpenXR mod adds stereo rendering and tracked head movement. VR controllers can emulate a gamepad; a normal gamepad remains useful for the game's menus.

## Option 1 — Current Steam version

The Hub follows the publisher's latest stable Windows release. The reviewed Current package is v1.2. This Hub route uses the Steam DirectX 11 installation.

1. Close the game before installing or updating. Select [[Install]] or [[Update]] in the Hub.
2. Select Windowed mode in SnowRunner. Select TAA for the current motion-vector stale-eye warp. The old FXAA-only advice does not apply to this current rendering path.
3. Connect the headset and start the intended OpenXR runtime. Use [[Start Current]] on this page; the Steam edition can also start through Steam.
4. The first VR start writes the headset resolution and config. Current releases resize the window when possible and apply resolution changes live. Restart only if the mod asks because it could not resize the window.

The proxy is Sources/Bin/dxgi.dll. Tuning is in Sources/Bin/Snowrunner_VR_config.txt; diagnostics are in Sources/Bin/snowrunner_vr.log. Include the log, headset, runtime, game version and render method when requesting help.

### Optional DLSS on RTX cards

The current DLSS tab needs TAA and a separate NVIDIA runtime. If wanted, obtain nvngx_dlss.dll version 310.9.16 or newer from the [publisher-recommended NVIDIA file](https://github.com/NVIDIA/DLSS/blob/v310.9.16/lib/Windows_x86_64/rel/nvngx_dlss.dll), using Download raw file, and place it beside Sources/Bin/SnowRunner.exe. The ordinary VR mod runs without it. It is not a dependency of the frozen v0.3 route.

DLAA keeps the game resolution. Quality, Balanced, Performance and Ultra Performance render at smaller sizes and reconstruct the headset image. Changing the mode rebuilds render targets; allow it to finish. The menu also provides model presets and CAS sharpening. Change one option at a time.

## Option 2 — Last confirmed working version 1.886173

This separate fallback keeps Steam game build 25096372 and SnowRunner VR v0.3 together. It does not follow current mod releases or acquire their optional DLSS requirements. Its earlier image settings remain Windowed mode and FXAA only.

The exact Steam command is:

```text
download_depot 1465360 1465361 1017218816943865737
```

Setup checks for a completed depot before offering Steam Console. The default destination is C:\Games\SnowRunner VR; a separate destination can be chosen. Sources\Bin\steam_appid.txt contains 1465360 beside the executable. The normal Steam game and independent depot retain separate versions, paths and start buttons.

After the first VR start, close the frozen game once and launch it again. Use [[Start 1.886173]] on the detail page or its matching desktop shortcut.

## Controls

| Button | Action |
|---|---|
| [[Insert]] | Open or close the VR settings UI. |
| [[L3]] + [[R3]] | Open or close the settings UI with a gamepad. |
| [[Home]] | Recenter the view while facing forward. |
| [[Left Trigger]] / [[Right Trigger]] | Emulate the gamepad triggers. |
| [[Left Grip]] / [[Right Grip]] | Emulate the gamepad shoulder buttons. |
| [[A]] / [[B]] / [[X]] / [[Y]] | Corresponding gamepad face buttons. |
| [[Left Stick]] / [[Right Stick]] | Corresponding gamepad sticks. |
| [[Left Stick Click]] / [[Right Stick Click]] | Corresponding gamepad stick clicks. |
| [[Left Menu]] tap / hold for half a second | Gamepad Start / Back. |
| Hold [[Left Stick Click]] + [[Right Stick]] | Use the right stick as the D-pad. A quick left stick click still reaches the game. |
| [[F8]] | Switch the cursor between normal menus and world-space winch targets. |
| [[Page Up]] / [[Page Down]] | Adjust horizontal world-cursor alignment. |
| [[Shift]] + [[Page Up]] / [[Page Down]] | Adjust vertical world-cursor alignment. |

Controller emulation can be disabled in the mod menu. It does not add physical grabbing of truck controls. The frozen v0.3 copy keeps its original capabilities.

## Rendering and updates

Current Synched Sequential renders both eyes from the same game update and costs more performance. Alternating-eye rendering offers several stale-eye warp methods; its motion-vector option needs TAA and can also work with DLSS. DIBR supplies another reconstruction trade-off. Compare frame pacing and image artifacts with your headset before increasing resolution.

Publisher testing mainly covers Quest 3 with Virtual Desktop/VDXR and SteamVR. Other OpenXR headsets, particularly wide or canted displays, may need tuning. VR Ready proves the declared files, not headset performance or compatibility with every later game update.

The Hub updates only the selected copy and preserves generated settings. Flat / VR parks that copy's proxy. Use the detail page's Uninstall Guide for removal; the base game, saves and independent depot game data are retained.

## Credits and support

[SnowRunner VR project](https://github.com/Timguin-87/Snowrunner-VR) · [Publisher releases](https://github.com/Timguin-87/Snowrunner-VR/releases) · [Flat2VR Modding](https://discord.gg/flat2vr) · [SnowRunner VR discussion](https://discord.com/channels/747967102895390741/1542980041061695598)

The road ends here. The mud has other plans.
