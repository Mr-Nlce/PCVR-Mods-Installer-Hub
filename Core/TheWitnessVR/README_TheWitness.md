# The Witness

Witness VR Mod extends the game's existing VR mode with HMD-relative smooth locomotion, 45-degree snap turning, native puzzle interaction, improved subtitles and configurable per-eye rendering.

This is a WIP beta. The current release restores the native puzzle reticle, so puzzles can be solved naturally in the headset; the older note about peeking at the monitor no longer applies.

## Before installing

- The verified target is the Steam 64-bit DirectX 11 build and witness64_d3d11.exe.
- SteamVR and a working OpenVR headset setup are required.
- Epic may work when its executable is launched with -vr, but the author has not tested it. Use **Locate game** if the Hub does not find that copy.
- The package is hosted on Flat2VR Discord. Join the server when prompted, then use the linked download post.
- The current v1.0.0 ZIP imports `libwinpthread-1.dll` but does not contain it. The installer reuses a compatible x64 copy when present. Otherwise it automatically downloads the small official MSYS2 UCRT runtime package, checks that it is usable and supplies the required imported functions, extracts only that DLL and tracks it for safe removal. MSYS2 itself does not need to be installed.

## Install and launch

Run the installer from this page. It checks the exact Discord package and the required runtime, preserves the game's original openvr_api.dll, creates config.ini only when absent and records every owned file for recovery.

Start SteamVR first, then use **Start in VR** in the Hub. The Hub launches witness64_d3d11.exe with -vr automatically. Steam users can instead add -vr to the game's Steam launch options and launch through Steam.

Disable SteamVR Desktop Theater for this non-native SteamVR application if Steam opens it on a flat cinema screen.

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move relative to your headset direction |
| [[Left Stick Click]] | Toggle walking and running |
| [[Right Stick]] | Snap turn outside puzzles; move the native reticle while focused |
| [[A]] | Enter focus and start or operate a puzzle |
| [[B]] | Leave focus |
| [[Right Trigger]] | Forwarded to the matching native interaction where mapped |

Other controller inputs are forwarded to their equivalent native gamepad actions where mapped.

## Configuration

witness_vr_mod\config.ini contains movement speed, dead zone, snap-turn angle, subtitle position and rendering options. The installer and **Uninstall now** preserve it.

eye_resolution_scale defaults to 1.25. Use 1.0 for the runtime-recommended size if performance is insufficient. Leave eye_render_width and eye_render_height at zero for automatic headset sizing. The selected dimensions and hook status are written to witness_vr_mod.log.

## Flat / VR switch

Use the **Flat / VR switch** on this page. It parks the verified VR proxy, restores the preserved original openvr_api.dll for flat play, and reverses the swap when VR is enabled again.

## Uninstall

Use **Uninstall now** beside this guide. It removes only unchanged files listed in the Hub ownership record, restores the original game DLL and preserves changed files plus config.ini. The game and saves are never removed.

If the original DLL was already missing before installation, use Steam's **Verify integrity of game files** first.

## Troubleshooting

- Fully close and restart the game after installing or changing DLLs.
- Confirm SteamVR is running and -vr is present when launching outside the Hub.
- Check witness_vr_mod.log for signature and hook details.
- If the automatic runtime download fails, retry it or use the official MSYS2 package page opened by the installer. Never use an unofficial loose-DLL mirror.
- A future game update can require a new mod build; the DLL refuses unsafe address-sensitive patches when the executable does not match.

## Credits

- Witness VR Mod by the Flat2VR community.
- `libwinpthread-1.dll` is obtained from the official MSYS2 UCRT winpthreads package (MIT and BSD-3-Clause-Clear).
- The Witness and its game files are property of Thekla, Inc.; SteamVR and OpenVR are associated with Valve Corporation.
