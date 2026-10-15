# Shenmue I & II VR

ShenmueVR 2.0 by Tensai37 adds stereoscopic VR, tracked hands, physical turning and gesture controlled fighting to the Steam edition of Shenmue I & II. The [publisher releases](https://github.com/Tensai30/ShenmueVR-Downloads/releases) now live on GitHub.

## About the Game

Shenmue I & II follow Ryo Hazuki through two story driven adventures. The mod lets you explore both games in first person and use their normal gamepad actions alongside the new tracked controls.

## Before you install

- Use the Steam v1.07 game executables. The publisher Setup rejects unknown executables, missing stock files and modified stock archives. Restore original files with Steam's Verify integrity function if Setup rejects them.
- Close both games, the Shenmue launcher and any controller bridge before starting Setup.
- Back up your game folder yourself if you want to keep other mods or their settings. ShenmueVR 2.0 removes other mods from each selected `sm1` or `sm2` folder and creates no automatic backup. An unselected game and saves outside the game folder remain untouched by the publisher Setup.
- Have an active OpenXR headset runtime. The mod includes the OpenComposite adapter named `openvr_api.dll`; that filename does not mean you should select OpenVR.

## Install and update

1. Select [[Install]] in the Hub. It locates the Steam game folder containing `SteamLauncher.exe`, `sm1` and `sm2`.
2. The Hub resolves the latest stable ShenmueVR Setup from the [GitHub releases](https://github.com/Tensai30/ShenmueVR-Downloads/releases), including its Setup EXE. If the live lookup is unavailable, its reviewed v2.0 Setup is the fallback.
3. Before the publisher Setup opens, the Hub shows the folder and asks you to confirm that you have backed up what you want to keep. Select the Shenmue I and/or Shenmue II components you own in Setup. Windows may request administrator approval.
4. Setup applies the supported executable patches, removes other mods from selected game folders, installs its OpenXR files and settings, and installs its bundled gamepad driver when needed. Restart Windows if Setup asks.
5. The Hub checks for `ShenmueVR.ini`, the OpenXR adapter, hand DLL and input actions in a selected game folder before recording the installed version. An older INI alone cannot count as a 2.0 install.

Setup 2.0 does not have OpenVR/OpenXR or motion-control selection pages. OpenXR and motion controls are enabled automatically. Virtual Desktop's gamepad-emulation option is not required for the included controller bridge.

## What changed in 2.0

The [v2.0 release](https://github.com/Tensai30/ShenmueVR-Downloads/releases/tag/v2.0) lists boosted frame rate in all scenarios, hands, fighting gestures and physical turning. The publisher's included README says its own interpolation can present up to 120 FPS while preserving the games' required timing. Start with external ASW, SSW and Motion Smoothing disabled; actual performance depends on your PC and headset settings.

Both games include first-person play and tracked hands. Fighting gestures activate during combat. Cutscenes retain the games' own camera behavior.

## Launch and controls

1. Connect your headset and start its OpenXR runtime.
2. Start Shenmue I or II normally.
3. If input does not respond, click the desktop game window once to give it focus.
4. Use tracked hands and normal controller buttons. The publisher has not documented an exact button and gesture map for 2.0, so the earlier v1.3 left-trigger mapping is not presented here as current.

## Installed files and removal

The 2.0 Setup contains separate payloads for `sm1` and `sm2`, including `ShenmueVR.ini`, `XINPUT1_3.dll`, an OpenXR adapter named `openvr_api.dll`, hand DLLs and bindings. It also includes the controller bridge and a signed gamepad bus driver. The selected game executables are patched by the publisher Setup.

Use the publisher's Shenmue I & II VR Mod uninstaller in Windows Installed apps. It removes its unchanged mod files and reverses supported executable patches. It cannot restore other mods or settings that Setup removed; restore your own game-folder backup for those. The shared gamepad driver remains installed so other apps using it continue to work. Do not treat backup folders left by older installers as a 2.0 recovery copy.

## Troubleshooting

- If Setup rejects the game, check Steam v1.07 and use Steam's Verify integrity function to restore stock files before trying again. Keep your own backup of custom files first.
- If the mod does not appear in the Hub after Setup, check whether `sm1\ShenmueVR.ini` or `sm2\ShenmueVR.ini` exists for the component you selected. A cancelled or rejected Setup is not marked complete.
- If Windows asks for a restart after installing the controller driver, restart before playing.
- If the game starts without headset output, make sure the OpenXR runtime is active before launch.

## Support Tensai37

Supporting the author is optional: [Ko-fi](https://ko-fi.com/tensai37) or [Patreon](https://www.patreon.com/cw/Tensai37/membership).

The sailors are a lie. The forklift is real.
