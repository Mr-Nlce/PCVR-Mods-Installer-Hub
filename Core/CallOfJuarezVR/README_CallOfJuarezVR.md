# Call of Juarez VR

## About the Game

The original 2006 western campaign gains tracked head and hands, native stereo, and experimental physical interactions through rubocopter's community pre-alpha. This Hub route supports only the publisher-confirmed **Steam D3D9 `CoJ.exe`** build. `CoJ_DX10.exe`, GOG, DVD and other editions are not supported by this package.

## Before installing

Back up your saves, run the Steam D3D9 game flat once, and exit. This creates `Documents\call of juarez\out\Settings\Video.scr`, which the publisher needs. Start SteamVR and leave it running. Close the game before installing, updating, preparing a session or removing the mod. Unsigned VR files can trigger antivirus warnings; a missing file is only a symptom until an actual protection event is found.

The Hub checks the current GitHub prerelease and downloads the **complete publisher ZIP**. It verifies the package layout, then invokes the publisher's own Install/Update action. The whole package is retained for later session preparation and uninstall. The game and saves are not bundled.

## Start in VR

**1. Use Start in VR in the Hub.** It runs the publisher's `PrepareSession` action and then starts the Steam D3D9 game. SteamVR must already be active. This preparation is required before every later play session. Avoid switching desktop focus during play; the original game can crash when it loses focus.

The publisher's `CoJ-VR.cmd` also offers resolution profiles, diagnostics, manual reload settings and recovery. Auto resolution uses SteamVR's recommended per-eye extent; you can select Preserve, percentages or Manual in the publisher menu. With an unsupported or unavailable headset extent, the selected game size is retained.

## Controls

Prealpha.5 adds physical bow draw, two-hand rifle support and virtual holsters. Support for the Remington was exercised by the publisher on PS VR2; Winchester and SawOff handling is experimental. Physical rifle and shotgun reloads are not implemented: use the game's normal reload action. Options > Game contains turn mode, cinematic mode and optional weapon guides.

| Button | Action |
| --- | --- |
| [[Left Stick]] | Move. |
| [[Right Stick]] | Turn outside duels. |
| [[Left Grip]] | Interact. |
| [[Right Grip]] | Kick. |
| [[Left Trigger]] / [[Right Trigger]] | The game's left and right hand actions; aim and fire in the native duel. |
| [[Left Stick Click]] / [[Right Stick Click]] | Crouch / focus on Touch, Index and WMR; use the center pad click on Vive. |
| [[Reload]] | Open or close an eligible revolver for manual reload. |
| [[Free-hand Trigger]] | Hold a round at the hip, move it to the gun and release. |
| [[Right Trigger]] | Near the bowstring, press, draw back and release to fire while aiming the bow with the left hand. |
| [[Left Grip]] | Press near a supported rifle's fore-end to attach the support hand; release to detach. |
| [[Right Grip]] / [[Left Grip]] | Press freshly at the matching hip to toggle its pistol; above the matching shoulder, toggle the long weapon / bow. Release between gestures. |

Manual reload is experimental and retains ordinary handling for unsupported weapons. The publisher's guide has controller-specific details, including Sense and Vive mappings.

## Update and removal

The Hub resolves prereleases and records the version inside the live publisher package. An update uses the same publisher Install/Update action while the game is closed. **Uninstall now** invokes the publisher's Uninstall/Restore action, which restores its tracked D3D9 files and recovery backups. Preserve the package and backup files until removal has completed.

## Support rubocopter

[Support the VR mod on Ko-fi](https://ko-fi.com/onitaku)

## Links

Publisher: https://github.com/rubocopter/call_of_juarez_vr

VR gameplay: https://www.youtube.com/watch?v=LPieKcmw3-k
