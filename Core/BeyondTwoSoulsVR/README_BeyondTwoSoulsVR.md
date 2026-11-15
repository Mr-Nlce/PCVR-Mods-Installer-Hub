# Beyond: Two Souls VR

## About the Game

Beyond: Two Souls follows Jodie Holmes and the entity Aiden through a cinematic story. adore11s's PC VR mod renders the game in stereo with head tracking. The normal game cameras remain available; first-person views and tracked hands are experimental. The author has tested first-person hands with young Jodie in the green shirt and adult Jodie in the red dress. Other outfits and scenes may look wrong.

## Requirements and installation

The author verified the Steam PC build. Epic and other PC executables are found by signatures at runtime and may fall back to flat play if a critical game address is missing. The Hub checks for the game EXE and `BigFile_PC.dat`, downloads the current stable publisher ZIP and installs its VR runtime. Keep the game closed during setup. Review an existing non-Hub `dinput8.dll` before continuing.

1. Start the flat game once. In its graphics options, set **Windowed**, turn **Motion blur off** and **Depth of field off**.
2. On this page choose [[Get Installer]]. Read the setup notice, then press Enter to locate the game and again to check the current stable GitHub release. If GitHub cannot be checked, setup shows any official ZIP already in Downloads for your confirmation. Otherwise press Enter to open the release page, download its current `B2S_VR_MOD_v*.zip`, then press Enter to search Downloads. You can also drag the ZIP onto the installer window. The version is shown before installation; when the online check fails, compare it with the publisher page before confirming.
3. After setup, start SteamVR or your active OpenXR runtime, connect the headset and choose [[Start in VR]]. With v1.0.0 and later the Hub starts the game through Steam for Steam installations or uses the detected non-Steam executable. VR activates automatically. Older installations use their publisher Play script.

The publisher's `b2svr.ini` remains yours on update. Its VR picture-size and turning settings can be changed there. The Hub does not copy the included source tree into the game.

## Controls

| Button | Action |
|---|---|
| [[Both Stick Clicks]] | Toggle first person while controlling Jodie, equivalent to [[F1]]. |
| [[Both Stick Clicks]] hold | Show first person during cutscenes, equivalent to [[F3]]. |
| [[F1]] | Toggle first person during gameplay. |
| [[F3]] | Toggle first person in cutscenes. |
| [[F2]] | Recenter the VR view. |
| [[F9]] | Switch VR rendering off or on. |
| [[F10]] | Show Xbox button prompts. |
| [[F11]] | Show PlayStation button prompts. |

The game's other actions retain their normal controls. The publisher recommends using [[F1]] during gameplay and enabling [[F3]] only when desired, because some cutscene animation does not work well in first person.

## Limits and troubleshooting

The Party level can lose objects, shadows or the entire VR image. Press [[F9]] to play that section flat, then press it again afterward. First person can show missing geometry or poor lighting around transitions. If VR stays flat, check SteamVR, the Windowed setting and `b2svr_logs/b2svr.log` in the game folder. The publisher launcher writes `B2S_VR_MOD/setup_log.txt`. Crash reports are in `b2svr_logs/crash_reports`. Headset image and controller function still require a real game session.

## Updates and removal

The Hub checks stable GitHub releases and records a version only after the required files are present. [[Uninstall now]] removes unchanged Hub-owned files and restores any earlier same-name files. It leaves saves, personal VR settings, logs and later modified files in place. Close the game first.

The Hub keeps the publisher's install and removal scripts when supplied. Use the Hub's uninstall action to apply its ownership manifest and restore backed-up files.

## Links

[Publisher and guide](https://github.com/adore11s/Beyond-Two-Souls-VR-Mod) · [Releases](https://github.com/adore11s/Beyond-Two-Souls-VR-Mod/releases) · Join [Flat2VR Modding](https://discord.gg/uAeQkYBM4n), then read the [Beyond: Two Souls thread](https://discord.com/channels/747967102895390741/1559649298579456132) · [VR gameplay](https://youtu.be/ypxBPi9P-JY?t=377)

>>> Two souls. One new point of view.
