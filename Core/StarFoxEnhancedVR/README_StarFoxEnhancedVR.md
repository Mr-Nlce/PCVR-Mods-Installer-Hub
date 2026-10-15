# Star Fox Enhanced PCVR

## About the Game

Star Fox is Nintendo's space combat game for the Super Nintendo Entertainment System. This independent native port by KandoWontU adds a PCVR/OpenXR development build with headset tracking and an optional standard gamepad. It is an alpha. You must supply your own supported, unmodified retail Star Fox or Starwing ROM; no game ROM, Nintendo assets or generated bundle are distributed by the Hub.

## Install and start

The reviewed Windows PCVR release is **v0.0.8.6**. It adds independent scene
effect controls, stereo and startup fixes, and safe migration of retired
visual settings. The asset builder and player must come from the same release;
the Hub selects the PCVR package rather than the separate builder-only ZIP.

The Hub downloads only the [publisher's Windows PCVR ZIP](https://github.com/kandowontu2/starfox-enhanced/releases). It contains the matching `starfox_pcvr.exe`, `starfox_asset_builder.exe`, `BUILD-ASSETS.bat` and `LAUNCH-PCVR.bat`. The installer asks for a writable standalone destination and your own ROM, then runs the matching builder to create `Starfox-Assets.BIN` beside the player. A new release rebuilds that bundle; do not carry an older BIN into a newer build. The ROM stays at the path you selected and is never copied into the delivery ZIP.

Connect and wake the headset before starting. Select an active OpenXR runtime and use a Vulkan-capable GPU; for Valve Index, start SteamVR and set it as the active OpenXR runtime. Hub Play runs the publisher's `LAUNCH-PCVR.bat`, which keeps missing-asset and runtime errors visible and writes `pcvr-log.txt` beside the launcher. The in-game start menu chooses Original or EX. The PCVR build launches the game, not a short runtime diagnostic.

The optional `Starfox-MSU1.PAK` may be placed beside the player or bundle for MSU-1 music. It is detected automatically; check `pcvr-log.txt` and the saved music setting if it stays silent. Saves, preferences and shader cache live in `vr-data` beside the executable unless you launch with the publisher's `--data-dir` option. Existing flat-game data is separate. Do not force-close the launcher while it is writing data; Ctrl+C requests a clean exit.

## Controls

The publisher documents an SDL-compatible Xbox, PlayStation or other standard gamepad. Head tracking still requires the OpenXR headset. Stick sensitivity can be changed in Options.

| Button | Action |
|---|---|
| [[Left Stick]] / [[D-pad]] | Steer. |
| [[A]] | Fire. |
| [[B]] | Bomb. |
| [[X]] | Boost. |
| [[Y]] | Brake. |
| [[Left Trigger]] / [[Right Trigger]] | Roll. |
| [[Start]] | Pause or open the menu. |
| [[Back]] | Change view. |

## Limits and troubleshooting

This is a PCVR development build. Physical Index tracking, controller comfort and sustained performance still need broader validation; successful extraction or asset generation is not proof of headset compatibility. If the builder rejects your ROM, verify that it is a supported, unmodified retail dump. If the headset does not start, verify the active OpenXR runtime, Vulkan GPU/driver and the `pcvr-log.txt` written by `LAUNCH-PCVR.bat`. The [publisher's project](https://github.com/kandowontu2/starfox-enhanced) carries current build notes.

The detail page has Uninstall guide and Uninstall now. The button removes unchanged Hub-owned player files and restores prior same-name files. Your original ROM is untouched; generated assets, saves, settings and optional music stay for review. Changed files are preserved.

>>> Good luck, Fox. Slippy promised to stay out of the way this time.
