# Borderlands GOTY Enhanced

**BL1GOTYVR** by **Mastersellz** adds native OpenXR stereo rendering, roomscale head tracking and tracked weapon aiming to the 2019 Enhanced release.

## Required game version

This mod supports **Borderlands: Game of the Year Enhanced (2019), Win64/D3D11 only**. It does not support the original 2009 Borderlands release.

## Setup and launch

Before installing, start the game once in **Flat mode**, reach the main menu, then close it. This creates the required `WillowEngine.ini` and `WillowGame.ini` files. The installer verifies both files before changing anything in the game folder.

The Hub downloads the current stable GitHub release and installs it beside `Binaries/Win64/BorderlandsGOTY.exe`. If another `dxgi.dll` already exists, it is backed up rather than discarded.

Choose one OpenXR runtime, then use **Start in VR** in the Hub or launch through Steam:

- Virtual Desktop: select **VDXR** and leave SteamVR closed.
- Steam Link or a SteamVR headset: make SteamVR the active OpenXR runtime.
- Meta Link: use the Oculus OpenXR runtime.

After the files are installed, setup explains the choices and waits for Enter before it opens `Binaries/Win64/BL1GOTYVRConfig.exe`. Keep the installer open, choose **Low**, **Medium**, **High**, **Ultra** or **Mega** under Render Options to suit your PC, press **Save Settings**, then return to the installer and confirm with Enter. The Hub does not silently choose a render preset. It only selects `SameFrameStereo=0` for a new configuration, or after its log proves that an experimental same-frame start stopped before OpenXR initialized; existing settings otherwise remain untouched.

Resolution changes require a restart. The medium preset is 2048 x 2048 per eye; use a lower preset first if performance is unstable. Keep **Same-frame stereo** off for the first successful VR launch. The configurator's **Defaults** button currently enables that experimental option again, so verify the checkbox before saving.

Start the game with the render preset you saved. If the left- and right-eye images appear too far apart, reopen the configurator and lower **Convergence Shift**. The tool labels `10.0` as recommended, but `1.0` or a lower value may fit your headset much better; this is a comfort and headset-dependent adjustment rather than a universal replacement default.

## Controls

| Input | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Right Stick]] | Smooth or snap turn |
| [[Right Trigger]] | Fire |
| [[Left Trigger]] | Aim down sights |
| [[A]] | Jump |
| [[B]] | Close, back or cancel |
| [[X]] | Use or reload |
| [[Y]] tap | Cycle weapon |
| [[Y]] hold | Echo menu or menu back |
| [[Y]] hold + [[Left Stick]] | D-pad or weapon slot |
| [[Left Grip]] | Left shoulder action |
| [[Right Grip]] | Right shoulder action |
| [[Right Stick Click]] | Crouch |
| [[Left Stick Click]] + [[Right Stick Click]] | Recenter |
| Physical controller swing | Melee attack |

Keyboard and gamepad input remain available.

## Current limitations

- First-person arm IK, body hiding, alternative capture and same-frame multiview remain experimental. If a previous same-frame run stopped before OpenXR initialization, reinstalling stores the old INI under `.pcvrhub_borderlandsgotyenhancedvr_user_backup` and returns only `SameFrameStereo` to the stable setting.
- Only one `dxgi.dll` proxy can be active beside the game executable.
- A future game update can invalidate the mod's signatures or offsets.

The mod writes diagnostics to `Binaries/Win64/BL1GOTYVR.log`. Existing `BL1GOTYVR.ini` settings are preserved across Hub updates.

## Playing flat

Use the **Flat / VR switch** on this detail page. It parks only BL1GOTYVR's active `dxgi.dll`; it does not delete the mod, configuration, game or saves.

## Uninstall

Use **Uninstall now** beside this guide. It checks the Hub ownership record, removes only unchanged BL1GOTYVR files and the mod-created `BL1GOTYVR.log`, and restores any `dxgi.dll` that existed before installation. Changed files are retained instead of guessed at. `BL1GOTYVR.ini` is kept so a later reinstall retains your settings; delete only that file manually if you want a complete VR-settings reset.

## Credits

- BL1GOTYVR by Mastersellz: https://github.com/Mastersellz/BL1GOTYVR
- Releases and changelog: https://github.com/Mastersellz/BL1GOTYVR/releases
