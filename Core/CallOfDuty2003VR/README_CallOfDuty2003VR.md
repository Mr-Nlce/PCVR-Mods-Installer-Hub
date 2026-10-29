# Call of Duty (2003) VR

## About the Game

lambda-gab's VR mod brings the original Call of Duty single-player campaign into a headset with stereo rendering, head tracking, body holsters, tracked hands and controller aiming. It is in development, so visual glitches remain possible. Multiplayer is not supported. United Offensive is also supported by v1.7.1 and has its own Hub entry.

## What you need

- Your own Call of Duty (2003) single-player game, EXE version **1.3**, with CoDSP.exe and main\pak0.pk3. The Hub checks the Steam and original Activision retail folders. Otherwise drag CoDSP.exe or CoDMP.exe onto the installer; the latter identifies the folder only and is never the VR start target.
- A PC VR headset and **32-bit OpenXR runtime**. Virtual Desktop VDXR and Meta/Oculus runtimes are supported by the publisher; SteamVR requires its **beta** for the 32-bit runtime.
- The Hub downloads the current official ZIP (`cod-vr-manual-install.zip`), opens it, and copies opengl32.dll, openxr_loader.dll, cod_vr.ini, supporters.ini and CoD-VR-Launcher.exe, plus a small game-specific start controller next to CoDSP.exe. It preserves an existing cod_vr.ini and backs up other same-name files before replacing them. Game files and saves remain.

Unsigned VR files can trigger antivirus warnings. A missing file may also be caused by the installer, path or permissions; check the installer log and security history before assigning a cause.

## Install, update and start

1. Choose [[Install]] or [[Update]] on this tile. Read each screen and press Enter before the download and copy.
2. If neither listed location is found, drag or paste a game EXE or its folder. The installer confirms the single-player files before installing.
3. **Use [[Start in VR]] in the Hub.** It opens the publisher's CoD-VR-Launcher.exe. On Steam, the launcher's **PLAY** button starts the game through Steam as required by that build.

The desktop **Call of Duty VR** shortcut selects the original campaign and opens the same launcher. Start in VR also selects the original game before opening the launcher. In it you can adjust render scale, controls, comfort and other settings. The launcher stores its choices under %APPDATA%\CoD-VR\settings.ini; these can override cod_vr.ini in the game folder. An existing cod_vr.ini stays intact when updating.

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
| [[X]] | Reload in the newly supplied v1.7.1 default configuration. |
| [[B]] or [[Y]] held + another face button | Configurable shortcuts; the new default uses [[B]] + [[X]] to switch weapons. |
| [[Free Hand]] facing your eyes | Show objectives. |
| [[Weapon Hand]] swung physically | Melee with the gun. |
| [[Menu]] | Open the game menu. |

Existing configurations are preserved and may use older bindings. The current publisher README lists different face-button defaults from its v1.7.1 ZIP; the table above follows the actual delivered cod_vr.ini. Check CONTROLS in your launcher for your own saved bindings.

Body holsters: primary weapon at the right shoulder, secondary at the left shoulder, pistol at the hip and grenades behind the waist. Let go away from a holster to drop the weapon.

## Flat / VR
Close the game and launcher before switching. Flat / VR parks the OpenGL proxy for normal flat play. Updates preserve that mode; Start in VR and the desktop shortcut prepare VR again before opening the publisher launcher. If the base game and United Offensive share a retail folder, they also share this one VR runtime. Updating or switching that folder affects both; the shared runtime is identified in the Uninstall guide.

## VR files
Start in VR uses the Hub's Start-CallOfDuty2003VR.ps1 controller to select SP in the publisher's Launcher > Game preference, then opens CoD-VR-Launcher.exe in the game folder. The standalone desktop shortcut runs Start CoD VR.ps1 in that same folder with -Game SP. Its icon comes from CoD-VR-Launcher.exe. The five publisher files stay beside CoDSP.exe; settings are in cod_vr.ini and %APPDATA%\CoD-VR\settings.ini. The Hub displays detected folders and start apps as links once the VR mod installation is present. If the Hub does not find your game, you can choose Locate Game and select CoDSP.exe.

## Help
The supported base executable is CoDSP.exe 1.3 (March 2004). The installer uses the same PE build timestamp as the publisher; the game's advertised patch number is not a substitute for that supported executable. An unsupported build is rejected before files are changed. Recovery can reopen the official release page, accept its current ZIP or accept the correct game path.

If the image appears twice side by side, verify that the active runtime supports 32-bit OpenXR. SteamVR requires its beta runtime. ABOUT > Problem starting in VR? in the publisher launcher creates its diagnostic report.

Optional: in the launcher's VR tab, Player hands > Hidden builds a pack from your own game files and can request administrator approval. The Hub preserves these generated and edited files.

## Support LambdaGab
- Support the mod developer on Patreon: https://www.patreon.com/cw/LambdaGab

## Links
- Publisher Discord support: https://discord.gg/SRsK2x5Tn
- Source and current instructions: https://github.com/lambda-gab/cod1-vr
- Publisher releases: https://github.com/lambda-gab/cod1-vr/releases
- Troubleshooting: https://github.com/lambda-gab/cod1-vr/blob/main/TROUBLESHOOTING.md

>>> One rifle for two men. Looks like you got the ammo, comrade.
