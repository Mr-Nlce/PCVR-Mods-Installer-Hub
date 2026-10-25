# Call of Duty (2003) VR

## About the Game

lambda-gab's VR mod brings the original Call of Duty single-player campaign into a headset with stereo rendering, head tracking, body holsters, tracked hands and controller aiming. It is in development, so visual glitches remain possible. Multiplayer and United Offensive are not supported.

## What you need

- Your own Call of Duty (2003) single-player game, version **1.5**, with CoDSP.exe and main\pak0.pk3. The Hub checks the Steam and original Activision retail folders. Otherwise drag CoDSP.exe or CoDMP.exe onto the installer; the latter identifies the folder only and is never the VR start target.
- A PC VR headset and **32-bit OpenXR runtime**. Virtual Desktop VDXR and Meta/Oculus runtimes are supported by the publisher; SteamVR requires its **beta** for the 32-bit runtime.
- The Hub downloads the current official ZIP (`cod-vr-manual-install.zip`), opens it, and copies only opengl32.dll, openxr_loader.dll, cod_vr.ini and CoD-VR-Launcher.exe next to CoDSP.exe. It preserves an existing cod_vr.ini and backs up other same-name files before replacing them. Game files and saves remain.

Unsigned VR files can trigger antivirus warnings. A missing file may also be caused by the installer, path or permissions; check the installer log and security history before assigning a cause.

## Install, update and start

1. Choose [[Install]] or [[Update]] on this tile. Read each screen and press Enter before the download and copy.
2. If neither listed location is found, drag or paste a game EXE or its folder. The installer confirms the single-player files before installing.
3. **Use [[Start in VR]] in the Hub.** It opens the publisher's CoD-VR-Launcher.exe. On Steam, the launcher's **PLAY** button starts the game through Steam as required by that build.

The desktop **Call of Duty VR** shortcut opens the same launcher. In it you can adjust render scale, controls, comfort and other settings. The launcher stores its choices under %APPDATA%\CoD-VR\settings.ini; these can override cod_vr.ini in the game folder. An existing cod_vr.ini stays intact when updating.

## Controls

| Button | Action |
| --- | --- |
| [[Left Stick]] | Move relative to your head. |
| [[Right Stick]] | Turn; up or down changes stance. |
| [[Left Stick Click]] | Recenter after standing upright. |
| [[Right Stick Click]] | Go prone. |
| [[Either Grip]] | Take a weapon from a body holster, or pick up and use an item with an empty hand. |
| [[Either Trigger]] | Fire; hold and release for a grenade throw. The other trigger zooms a scope. |
| [[A]] | Jump or confirm in menus. |
| [[B]] | Reload or go back in menus. |
| [[X]] | Show objectives. |
| [[Y]] | Melee. |
| [[Menu]] | Open the game menu. |

Body holsters: primary weapon at the right shoulder, secondary at the left shoulder, pistol at the hip and grenades behind the waist. Let go away from a holster to drop the weapon.

## Support LambdaGab

[Support the mod developer on Patreon](https://www.patreon.com/cw/LambdaGab)

>>> One rifle for two men. Looks like you got the ammo, comrade.
