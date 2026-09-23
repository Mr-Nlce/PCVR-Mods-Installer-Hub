# SnowRunner VR

SnowRunner VR adds true stereo rendering and 6DoF head tracking to the Steam DirectX 11 version of SnowRunner. It is an early gamepad mod: keep the normal keyboard, mouse or gamepad controls nearby and expect a later game update to require a matching mod update.

## Option 1 — Current Steam version

This is the normal choice while the latest stable SnowRunner VR release supports the current Steam game. Setup finds the regular Steam installation and installs or updates only the VR proxy there. Steam continues to manage and update that copy normally.

### Setup and first launch

1. Close SnowRunner before installing or updating the mod.
2. Select **Windowed** mode in the game's display settings.
3. Disable temporal anti-aliasing. The author currently recommends **FXAA** only.
4. Start exactly one OpenXR runtime and connect the headset.
5. Use **Start Current** on this page or launch SnowRunner through Steam.
6. The first VR start detects the headset's native per-eye resolution and creates `Sources\Bin\Snowrunner_VR_config.txt`. Close the game once and launch it again before judging the image.

## Option 2 — Last confirmed working version 1.886173

Use this independent fallback if a later SnowRunner update breaks the current route. The installer downloads Steam app `1465360`, Windows depot `1465361`, manifest `1017218816943865737` — public build `25096372` — and verifies the `1.886173` executable before moving it to `C:\Games\SnowRunner VR` by default. A different full destination can be chosen before anything is moved.

The Steam Console command is:

```text
download_depot 1465360 1465361 1017218816943865737
```

The installer looks for an already completed depot before opening Steam Console, checks the game structure, executable version and expected depot size, then creates `Sources\Bin\steam_appid.txt` beside `SnowRunner.exe`. Your normal Steam installation is not changed. Start this copy with **Start 1.886173** on the detail page or the `SnowRunner VR 1.886173` desktop shortcut.

The frozen copy uses **SnowRunner VR v0.3**, the mod build confirmed with game version 1.886173. Current releases such as v0.4 are not mixed into this route. The depot route advances only after a newer game/mod pairing has actually been confirmed together.

## Controls

| Button | Action |
|---|---|
| [[Insert]] | Open or close the SnowRunner VR settings UI |
| [[L3]] + [[R3]] | Open or close the settings UI on a gamepad |
| [[Home]] | Recenter the VR view |

The settings UI and the game's ordinary menus are operated with the normal gamepad or mouse controls.

## Rendering choices

The default stereo method is alternating-eye rendering with stale-eye warp. It offers complete images for both eyes but needs a high, stable frame rate. DIBR is available as an alternative with a different performance and artifact trade-off. Change one option at a time in `Sources\Bin\Snowrunner_VR_config.txt`, then restart the game when the setting requires it.

The mod has been tested with Quest 3 through VDXR and with SteamVR. Other conforming OpenXR runtimes may work. Very wide or canted displays can still need tuning.

## Flat / VR switch

Use **Flat / VR** on this game's detail page for the copy currently resolved by the Hub. It parks `Sources\Bin\dxgi.dll` as `dxgi.dll.pcvrhub_off` for flat play and restores it for VR. Do not rename proxy DLLs by hand while SnowRunner is running.

## Uninstall

Use **Uninstall Now** on this page. If both copies contain SnowRunner VR, the uninstaller asks whether to clean the current Steam game or the last-confirmed `1.886173` copy. It follows only the selected copy's ownership manifest, removes only the installed VR payload and restores a proven pre-existing file when necessary.

The dedicated depot game folder is never deleted by mod uninstall. Generated `Snowrunner_VR_config.txt`, diagnostic `snowrunner_vr.log`, `steam_appid.txt`, game files and saves are retained.

## Current release notes

The verified v0.4 build keeps SnowRunner 1.886173 support and the VR cursor and Pimax rendering improvements from v0.3. It adds an experimental world-marker fix plus options for a 2D map and 2D garage. A later SnowRunner update can still require a newer mod build; the Hub tracks the author's latest stable GitHub release automatically.

## Credits and support

- SnowRunner VR by Timguin-87: https://github.com/Timguin-87/Snowrunner-VR
- Releases: https://github.com/Timguin-87/Snowrunner-VR/releases
- Flat2VR Modding Discord invite: https://discord.gg/flat2vr
- SnowRunner VR discussion and support channel: https://discord.com/channels/747967102895390741/1542980041061695598
