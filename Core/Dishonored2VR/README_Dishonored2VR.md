# Dishonored 2 VR

## About the Game

Dishonored 2 follows Emily Kaldwin and Corvo Attano through Karnaca in a supernatural stealth adventure. The Cosmic Tangerine's mod brings tracked head movement, controller-held weapons and powers, physical sword strikes, grabbing and throwing to the current Steam game.

## Requirements and install

- **Current Steam edition only**, Steam app 403640, build 1.77.9.0. The publisher does not support GOG, Epic, Microsoft Store/Game Pass, other builds, or Death of the Outsider. The Hub checks the Steam installation and manifest; the publisher runtime performs the final build check when the game starts.
- Windows 10/11, a PC VR headset and the active OpenXR runtime used by that headset. Quest 3 through Link was publisher tested; Virtual Desktop, SteamVR, PS VR2 and Index paths have less testing.
- Choose [[Install]] on the Hub tile. The Hub resolves the current stable publisher ZIP and copies `dinput8.dll`, `DishonoredVR.dll` and `DishonoredVR.ini` beside `Dishonored2.exe`. It backs up any earlier files under those names. Other mods using `dinput8.dll` cannot run simultaneously with this drop-in.
- The publisher's INI enables `UnlockEverything = 1` and `InfiniteMana = 1` by default. Those options can permanently affect a save when the game autosaves. On a **fresh Hub install**, both are set to `0`; change them to `1` in `DishonoredVR.ini` only if wanted. Existing INI settings are preserved during updates.
- In game Options > Visuals, set **Display mode: Windowed**. Fullscreen and borderless can make the headset image blurry. Adjust headset resolution or `RenderScale` in the INI for image quality.
- Connect the headset, then use [[Start in VR]] in the Hub. The Hub launches through Steam; starting Dishonored 2 from the Steam Library is the alternative. Click the game's PC window once if controller input does not respond. VR activates after entering gameplay.

The publisher reset its numbering: **0.5.0 is newer than 1.0.0**. Fresh installs now use simultaneous stereo rendering (`Stereo3D = 1`); the older alternating-eye mode is `2`, and `0` is mono. Existing INI settings are preserved: after updating from 1.0.0, choose `Stereo3D = 1` yourself if you want the new 3D mode. Stereo costs roughly half the flat frame rate; lower headset resolution or `RenderScale` if needed.

On Meta Link/Air Link, `DisableMetaASW = 1` disables ASW for this game to reduce warped moving edges. Other runtimes keep their own smoothing settings. The mod's motion-blur setting also changes the game's graphics option until you turn it back on. Logs remain in the game folder or `%LOCALAPPDATA%\DishonoredVR`.

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move; click to sprint. |
| [[Right Stick]] | Turn; click to zoom. |
| [[Right Trigger]] | Sword or right-hand weapon. Swing the right arm to strike. |
| [[Left Trigger]] | Use a power or left-hand weapon; hold and throw for a grenade or springrazor. |
| [[Right Grip]] | Take, use or open the pointed-at object; block when pointing at nothing. |
| [[Left Grip]] | Hold to open the power wheel; release to equip. In the wheel, [[A]] drinks mana, [[B]] drinks health, and [[Y]] or [[X]] assigns a quick slot. |
| [[A]] | Jump; select in menus. |
| [[B]] | Toggle crouch; go back in menus. |
| [[Y]] | Quick slot 1; hold for slot 3. |
| [[X]] | Quick slot 2; hold for slot 4. |
| [[Left Menu]] | Journal; hold for pause, save and load. |
| [[Left Stick Click]] + [[Right Stick Click]] | Journal or pause on controllers without a menu button. |
| [[A]] | Hold for about three seconds to skip a cutscene. |
| [[X]] | Alternative: hold for about three seconds to skip a cutscene. |
| [[Left Grip]] / [[Right Grip]] | Switch menu tabs. |
| [[Left Trigger]] / [[Right Trigger]] | Switch menu sub-tabs. |

## Discord discussion & support

- [Flat2VR Dishonored 2 VR discussion](https://discord.com/channels/747967102895390741/1544020517831446528)

## Support the author

- [Patreon](https://www.patreon.com/CosmicTangerine)
- [Ko-fi](https://ko-fi.com/cosmictangerine)

## Links

- [Official mod and detailed troubleshooting](https://github.com/thecosmictangerine-cloud/dishonored-2-vr)
- [Publisher releases](https://github.com/thecosmictangerine-cloud/dishonored-2-vr/releases)
- [VR gameplay](https://youtu.be/29cmGRrJEmU?t=29)

## Uninstall guide

Close Dishonored 2 and choose [[Uninstall now]] in the Hub. The Hub removes unchanged files it installed, restores files that occupied those names before installation, and retains changed files for review. Saves, user-edited INI settings, generated logs and unrelated files remain. If you enabled the publisher's cheats and saved afterward, uninstalling cannot undo those save changes.

The Outsider did not mention the motion controllers.
