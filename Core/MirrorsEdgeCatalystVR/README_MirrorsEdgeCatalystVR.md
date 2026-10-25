# Mirror's Edge Catalyst VR

## About the Game

sqofer's Catalyst VR mod adds stereo VR to the original Mirror's Edge Catalyst. It is a gamepad and keyboard route; tracked hands are not advertised. The publisher requires game build **1.0.3.47248**. The Hub checks the game executable before opening the publisher Setup.

## Install or update

The Hub checks the stable GitHub releases, downloads `Mirror.s.Edge.Catalyst.VR-Setup.zip`, checks its archive paths and extracts its single publisher Setup EXE. Release **0.5** is the last reviewed fallback if GitHub resolution fails; the EXE's internal file version is different and must not be used for Hub update status. In Setup, select your game folder and choose **Install / Update**. The Hub marks completion only after the launcher and native adapter exist.

If you have **never started Catalyst**, launch the original game **flat once through Steam or EA App**, reach its menu, and close it **before opening the publisher VR launcher**. You may do this **after installing the VR mod**; Steam's normal Play route starts the flat game. This lets the store launcher and game finish first-run setup, especially on EA App. The publisher Setup may require administrator approval. Unsigned VR files can trigger antivirus warnings; missing runtime files can also result from an installer, path or permission error.

## Start in VR

**1. Use Start in VR in the Hub.** This opens the publisher's `mecxr_launcher.exe`. In its window, choose **Open Mod**, set the game path and resolution, **Save**, then **Launch game**. The publisher's default is 1920×1920 per eye. The game uses two rendered views; a strong GPU and lower settings may help. The publisher notes that AO and screen-space reflections are disabled; temporal AA can ghost and SMAA is unsupported.

## Controls

| Button | Action |
| --- | --- |
| [[F8]] | Recenter the VR view. |
| [[F9]] | Toggle VR during gameplay. |

Use the original game's gamepad or keyboard inputs for movement and actions.

## Removal

**Uninstall now** reopens the cached publisher Setup. Choose **Uninstall / Remove VR** there. The Hub clears its version receipt only after the publisher's runtime is absent. The original game and saves remain.

Publisher: https://github.com/sqofer/Mirror-s-Edge-Catalyst-VR

VR gameplay: https://youtu.be/oV-Qh79J0Sc?t=5
