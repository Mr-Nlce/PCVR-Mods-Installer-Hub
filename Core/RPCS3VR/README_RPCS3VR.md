# RPCS3 VR

## About the Tool

RPCS3 VR is hookmanuk's experimental OpenXR fork of the PlayStation 3 emulator. Games with a shipped VR profile render in stereoscopic 3D with headset tracking; other games remain flat. The release includes the supported profiles and patches. It is a gamepad experience, not motion-controlled gameplay.

This Hub entry opens the publisher's current release page. The Hub does not install, launch, detect or update this portable emulator and does not supply PS3 firmware or games.

## Requirements

- Windows 10 or 11 (64-bit), Vulkan-capable GPU, an OpenXR headset and runtime, and the Microsoft Visual C++ Redistributable (x64).
- Official PS3 firmware `PS3UPDAT.PUP` from [PlayStation](https://www.playstation.com/support/hardware/ps3/system-software/).
- Your own legally dumped PS3 games and any game updates or licences that your copies require. No game images or firmware are bundled.

## Install and start

1. Select Get Installer to open the [VR fork releases](https://github.com/hookmanuk/rpcs3/releases/latest). Download the current Windows x64 portable ZIP, not the repository's source archive. At the time this entry was checked, the VR build was `v0.0.43-vr11`.
2. Extract the whole ZIP into a writable folder outside `Program Files`. Keep `rpcs3.exe`, `vr_profiles`, `patches` and the DLLs beside the executable together. This folder also holds your settings and installed firmware.
3. Run `rpcs3.exe`. Choose File > Install Firmware and select the official `PS3UPDAT.PUP`.
4. Use File > Add Games for a folder containing your own disc dumps, or File > Boot Game for one game. Use File > Install Packages/Raps/Edats for owned digital titles, licences and updates where applicable.
5. Start your OpenXR runtime, then boot a game listed below. A supported profile enables VR by default. To change one game's settings, right-click it, choose Create Custom Configuration From Global Settings, then use GPU > VR. Restart the game after changing Enable VR Support.

Do not use the standard RPCS3 auto-updater on this fork: it would replace the VR build. Check the [VR fork releases](https://github.com/hookmanuk/rpcs3/releases) manually for later builds.

## Supported games in the v0.0.43-vr11 package

The checked package has 22 playable profiles. vr11 fixes Gran Turismo 5 race
speed at different frame rates and adds a sharper-distance shadow patch. It
also fixes edge-of-view scenery in God of War and several God of War I/II menus.
The former Gran Turismo 5 Wider View setting is gone; MotorStorm: Pacific Rift
and SEGA Rally Revo retain their wider-view settings. Earlier builds added
single-pass stereo rendering and World Scale up to 1000%.

| Game | Required game ID / edition | Publisher note |
|---|---|---|
| WipEout HD Fury | BCES00664 | Disc version needs updates 2.10, 2.30, 2.50 and 2.51 in order. |
| Pure | BLUS30182 | VR profile includes an unlocked-frame-rate patch. |
| ICO | BCUS98259 | 30 FPS game limit; driver smoothing is recommended. |
| Shadow of the Colossus | BCUS98259 | 60 FPS default; several VR image fixes are enabled. |
| Ridge Racer 7 | BCAS20001 | Asian release; menu video can occasionally stall emulation. |
| Demon's Souls | BLUS30443 | US release; cutscenes and wider-view fixes are included. |
| Bayonetta | BLUS30367 | US release; some menus have VR visual glitches. |
| Killzone HD | BCES01743 | Enable Write Color Buffers and Read Color Buffers in the game's custom GPU configuration or the level may be black. |
| Tales of Xillia | BLUS31006 | US disc 01.00; the 60 FPS patch is bundled and enabled by default. |
| Super Stardust HD | NPUA80068 | PSN package and its own `.rap` licence required; the planet appears as a tabletop world. |
| God of War and God of War II | BCES00800 | UK God of War Collection disc; set the game's custom GPU resolution to 1280x720 and use the collection selector. The selector-to-game transition can occasionally crash; retry the launch. |
| Dante's Inferno | BLUS30405 | US disc; wider-view and camera-shake VR patches are enabled by default. |
| Asura's Wrath | BLUS30721 | US disc; wider-view and community image patches are bundled and enabled. |
| Dragon Age: Origins | BLUS30415 | See the publisher's bundled `vr-games.md` for profile settings. |
| Ratchet & Clank 1, 2 and 3 | BCUS98282 | Use the own-copy collection; each game has its own profile. |
| Sonic & All-Stars Racing Transformed | BLUS30839 | See the bundled per-game recommendations. |
| SEGA Rally Revo | BLUS30068 | Wider View setting is available. |
| MotorStorm: Pacific Rift | BCUS98155 | Wider View setting is available; 72 FPS profile. |
| Gran Turismo 5 | BCUS98114 | XL Edition disc 01.00; skip the offered 2.11 disc update on first boot. vr11 fixes race speed across frame rates; its former Wider View setting was removed. |

This is the publisher's supported-profile list for the checked package, not a promise that every PS3 game runs in VR. The included `vr-games.md` and `vr-settings.md` contain the current per-game recommendations, settings and known issues. Consult those files when using a newer release.

## Controls and VR settings

| Button | Action |
|---|---|
| [[PS Button]] | Open the emulator's in-game home menu. |
| [[Start]] + [[Select]] | Alternative way to open the home menu. |

In the home menu, the VR tab adjusts HUD size, HUD distance, world scale and frame rate. A game's custom GPU > VR settings also provide a fixed floating 3D screen, camera depth offset and reprojection margin. The game itself continues to use its normal controller mapping.

On supported NVIDIA RTX GPUs, vr11 adds experimental per-eye DLSS. RTX 40 and
newer GPUs can also use experimental DLSS Frame Generation; it adds roughly one
headset frame of latency and requires DLSS to be enabled before starting the
game. These options have mainly been tested with Gran Turismo 5. Keep the
included `rpcs3_ngx.dll`, `nvngx_dlss.dll` and `nvngx_dlssg.dll` alongside
`rpcs3.exe`. The VR home menu also has a gamepad binding to toggle the HUD.
See the included `vr-settings.md` for the available modes and limits.

## Performance and troubleshooting

- Start with the game's own recommended frame rate. ICO stays at 30 FPS; other profiles can use the headset refresh rate where the game and hardware permit it.
- Increase GPU > Resolution Scale gradually. Stereo draws each render target for both eyes, so a high scale can exhaust VRAM or make the game miss frames. Lower it if that happens.
- If the game stays flat, confirm that its exact ID appears in the shipped profile list, start the OpenXR runtime before booting, and inspect that game's Enable VR Support setting.
- For a black Killzone HD world with visible menus, enable both color-buffer options above.
- For game-specific patches, updates, limitations and configuration screenshots, read the `vr-games.md` and `vr-settings.md` files in the downloaded ZIP.

## Removal

Close RPCS3, preserve any games, saves or settings you want to keep, and remove the portable folder you chose. The Hub does not own that folder and therefore has no Uninstall now action for this external tool.

>>> The cell processor took one look at OpenXR and asked for another core.
