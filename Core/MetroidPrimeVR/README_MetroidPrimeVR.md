# Metroid Prime VR (PrimedGun 2.0)

## About the Game

Explore Tallon IV as Samus Aran: scan alien life, uncover the Space Pirates' experiments and discover new abilities that open the world around you.

PrimedGun 2.0 by Nobbie and iChris4 is a native OpenXR port with motion controls and optional roomscale. It uses a native game engine, replacing the earlier Dolphin-based application. The Hub follows Windows releases including prereleases from iChris4/MetroidPrimePortVR.

## What you need

- Your own supported Metroid Prime disc image. USA revisions 0, 1 and 2 are supported; PAL is experimental. No game content is downloaded or included.
- A connected PC VR headset and active OpenXR runtime.
- A separate writable installation folder. The default is C:\Games\Metroid Prime VR 2.

## Install and start

1. Choose Install in the Hub. Option 1 is recommended: the native PrimedGun 2.0 Windows build with auto-update including prereleases. Option 2 installs the separate Dolphin-based Legacy 1.1.7 build.
2. Use Start in VR in the Hub and select the installed variant. Metroid Prime VR is the native desktop shortcut; Metroid Prime VR - Legacy opens the older application.
3. In PrimedGun choose Select Game and select your own disc image.
4. Open Port Config, enable VR, choose Save Settings, then Play. For flat play, disable VR in Port Config.

The publisher's Layout tab shows the current bindings. Controller and Calibration provide input and arm-cannon settings.

## Existing saves and updates

The former Dolphin-based installation stays in its own folder, unchanged. Select your game in the new launcher, then use Transfer PrimedGun Memory Card / Settings and choose the old installation or its User folder.

Dolphin save states cannot transfer. Save normally in the old game before moving progress. Keep the old installation until you have checked your transferred save.

Native updates preserve the entire user folder, disc images and unrelated local files. The installer never substitutes the old emulator release if a native download fails; the recovery screen opens the current release page and accepts a manually downloaded Windows ZIP.

Both installations can coexist and have separate start buttons, folders, version records and removal actions. Native updates go directly to the native installer; they do not ask which variant to install. The general Install / update variants action shows the selection menu. Legacy is an explicit fixed download, not an automatic fallback.

### Legacy setup

The default Legacy folder remains C:\Games\Metroid Prime VR. Existing complete Legacy installations are retained and recognized, including custom folders remembered by the Hub. The Legacy installer preserves the complete User and ROM contents and seeds only missing publisher defaults. It uses Dolphin portable mode.

Legacy requires a powerful PC for Dolphin-based VR, your own USA NTSC 1.0 revision 0 image and SteamVR. Put the image in its ROM folder or select it inside PrimedGun. Native supports additional USA revisions; the two engines have different requirements.

## VR controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Left Stick Click]] | Open or close in-headset settings |
| [[Right Stick Click]] | Calibrate height |

Use the launcher's Layout tab for the complete current controller scheme; it can differ from the legacy build.

### Legacy controller layout

![Legacy PrimedGun controller layout](ControllerLayout.jpg)

| Button | Action |
|---|---|
| [[Left Stick]] | Legacy movement |
| [[Left Stick Click]] | Legacy VR settings |
| [[Left Grip]] | Legacy map |
| [[Left Trigger]] | Legacy lock on |
| [[Right Stick Click]] | Legacy height calibration |
| [[Right Grip]] | Legacy missiles |
| [[Right Trigger]] | Legacy shoot |

## VR files

Native Start in VR opens PrimedGun.exe in C:\Games\Metroid Prime VR 2 (or your chosen folder). Its game engine is metroid_prime_port.exe, and its saves and settings live in the user subfolder. Legacy opens its own PrimedGun.exe, normally in C:\Games\Metroid Prime VR, with its separate User and ROM folders. The Hub displays links to the detected installations and start apps when available. If the Hub does not find your game, you can choose Locate Game and select PrimedGun.exe from the installation you want to identify.

## Discord discussion & support

- Flat2VR Modding invite: https://discord.gg/flat2vr
- Dolphin VR community: https://discord.gg/GdmffzCTrh

## Links

- Mod source and current setup notes: https://github.com/iChris4/MetroidPrimePortVR
- Windows releases including prereleases: https://github.com/iChris4/MetroidPrimePortVR/releases
- Legacy application and save-transfer source: https://github.com/Nobbie248/PrimedGun

>>> Scan the unknown, lock on, and let the arm cannon do the talking.
