# Vampire: The Masquerade – Bloodlines VR

## About the Game

Bloodlines is a vampire role-playing game set in a hidden supernatural Los Angeles. Atrblizzard's experimental VR preview adds stereoscopic first-person view, tracked weapons and hands, controller-operated dialogue and terminals, and comfort options while retaining the game's original quests and systems.

## What you need

- A complete Windows copy of Bloodlines from Steam, GOG or retail, with `vampire.exe` and its `Vampire` data folder.
- **Unofficial Patch 11.5 exactly.** The VR mod targets that patch's 32-bit hooks. The Hub checks the patch's actual loader and game files plus the first version in `VTMBup-readme.txt`; a `Unofficial_Patch` folder alone does not prove a complete 11.5 installation. If the patch is missing, the Hub downloads the [archived 11.5 publisher installer](https://github.com/Ghost2DLL/vtmb-vr-injector/releases/tag/up-11.5-archive) after Enter, then opens it with UAC approval after a second Enter. Select the game folder shown by the Hub. Back up saves and patch settings before changing an existing patch.
- A headset, tracked controllers and a Vulkan-capable graphics driver. SteamVR is the publisher-tested route. Native OpenXR and Virtual Desktop VDXR are experimental.
- The official [Bloodlines VR preview ZIP](https://github.com/atrblizzard/vtmb-vr/releases). The Hub resolves the prerelease channel and copies the complete payload beside `vampire.exe`. Existing root mod DLLs and VR bindings are backed up or preserved.

Unsigned VR files may trigger antivirus warnings. Missing files may also come from a copy, path or permissions problem; check the installer log and security history before naming a cause.

## Install, update and start

1. Choose [[Install]] or [[Update]]. Read each step and press Enter before locating the game, opening the patch page, downloading the current preview or writing files. Keep Bloodlines closed.
2. The Hub checks that the installed Unofficial Patch is **11.5**. If it is missing, the installer downloads and opens the archived publisher Setup. An incomplete or different installed patch must be reviewed before retrying. The patch publisher setup is separate from the Hub's VR file transaction.
3. **Use [[Start in VR]] in the Hub.** It starts `vampire.exe` with `-game Unofficial_Patch -vr -novid -window -w 1920 -h 1080`. The same route is in the **Bloodlines VR** desktop shortcut. The game folder contains `vampire.exe`; the VR settings and controller bindings live in `VR\`. The optional developer console is disabled in the Hub start route; add `-console` to a personal shortcut only if you need console commands.

To play flat, omit `-vr` or use your normal store launcher. Do not remove the Unofficial Patch just to leave VR mode. The preview is work in progress; SteamVR is the better-tested runtime.

## Controls

| Button | Action |
| --- | --- |
| [[Left Stick]] | Walk; navigate dialogue and menus. |
| [[Right Stick]] | Turn horizontally; select previous or next item vertically. |
| [[Weapon-hand Trigger]] | Attack, click a pointer or confirm dialogue. |
| [[Other Trigger]] | Secondary attack or melee block. |
| [[Left Grip]] / [[Right Grip]] | Reload or crouch, unless the offhand grip supports two-handed aim. |
| [[Left Stick Click]] | Feed in gameplay with the shipped binding; recenter in menus. |
| [[Right Stick Click]] | Switch weapon or discipline selection side. |
| [[F10]] | Open in-headset VR settings. |
| [[F11]] | Recenter the headset and panels. |

Controller bindings can be customized in SteamVR or `VR\config.txt`; inspect the [publisher's controls and configuration guide](https://github.com/atrblizzard/vtmb-vr) for the complete mapping.

## Support the developer

Supporting the modder is optional. [Atrblizzard on Ko-fi](https://ko-fi.com/atrblizzard) is linked directly from the publisher's project page.

## Links

- [Publisher project and full guide](https://github.com/atrblizzard/vtmb-vr)
- [Bloodlines VR website](https://vtmbvr.atrblizzard.com/)
- [Unofficial Patch 11.5 archive](https://github.com/Ghost2DLL/vtmb-vr-injector/releases/tag/up-11.5-archive)
- [VR gameplay](https://www.youtube.com/watch?v=Y_I8SJB4ISU)

>>> The Masquerade still applies, even when your hands give you away.
