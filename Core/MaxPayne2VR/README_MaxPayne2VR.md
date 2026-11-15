# Max Payne 2 VR

## About the Game

*Max Payne 2: The Fall of Max Payne* is a noir action shooter built around bullet time, shoot dodges and Max and Mona's story. This Hub entry offers two separate VR mods. **MP2VR by evilSheep is option 1 and recommended.** MaxPayne2VR by betotron remains option 2 for Virtual Desktop users.

Both mods can stay installed in one game folder. Their loaders share the name `d3d8.dll`, so setup stores each loader set in its own Hub profile without switching the running game files. **Play SteamVR** and **Play Virtual Desktop** select the right set before launch; close the game before switching. Versions and ownership records remain separate. The detail page's **Uninstall guide** and **Remove** buttons cover removing either mod without deleting the other.

## MP2VR by evilSheep — option 1 (recommended)

This release adds full stereo VR, tracked hands, roomscale movement, Max and Mona support, physical weapon handling, manual reloading, dual wielding, holsters, bullet time, shoot dodges, melee and disarming, a wrist HUD, and a virtual screen for menus and cutscenes. The in-game VR Settings menu offers world scale, render resolution, grip modes, turning, comfort and HUD placement.

### Requirements and installation

- Setup supports the **English Steam version** and the verified **German Steam 1.1.102.0 executable** on Windows 10/11 with SteamVR and two tracked controllers. PSVR2 and Quest 3 through PC VR were used in development. German headset behaviour and other game builds remain unverified; this is not a standalone Quest app.
- Install your own game, start it once flat, reach the menu, then close it. The Hub's **Install / manage VR mods** opens a first choice for MP2VR or betotron. Option 1 downloads the latest GitHub prerelease ZIP and runs the publisher's local asset generator against your game. Setup stores the loader in profile A and places the generated game-specific content in the game folder; it saves the release only after both ownership records and required files pass. Generation can take several minutes. Game-derived assets stay on your PC. An existing active mod remains active until its matching Hub Play button is pressed.
- Start SteamVR before pressing **Play SteamVR**. For the Steam game, the Hub activates MP2VR and opens Max Payne 2 through Steam. In the startup window select **MP2VR_FirstPerson** and **D3D Hardware T&L** for Acceleration, then click Play. This follows the [publisher's installation guide](https://github.com/evilSheep/max-payne-2-vr/blob/main/INSTALLATION.md). The separate `Max Payne 2 VR.exe` launch path is used only for unverified non-Steam copies. Use **VR Settings** in the game's main menu to adjust the experience.
- The current reviewed release is **v1.0.3**. The port includes the optional weapon wheel and stick actions, adjustable trigger sensitivity and PSVR2 field-of-view improvements. The Hub follows GitHub releases, including prereleases. Existing old saves may already contain duplicated weapons from earlier builds.
- For a fixed per-eye resolution, close the game and edit `maxpayne2vr_settings.ini` beside `maxpayne2.exe`: add `RenderResolution=1800` under `[VR]`. Supported values are `1440`, `1800`, `2160`, `2400`, `2560`, `2880`, `3200`, `3456`; `0` uses the launcher's resolution. Restart the game after changing this setting.

### Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move |
| [[Left Stick Click]] | Shoot dodge or get up |
| [[Right Stick]] | Turn |
| [[Right Stick Click]] | Bullet time |
| [[Left Trigger]] / [[Right Trigger]] | Fire the weapon in that hand |
| [[Left Grip]] / [[Right Grip]] | Grab, hold or interact; release to let go unless toggle grip is enabled |
| [[Y]] / [[B]] | Eject a magazine; with an optional shoulder layout, switch a held grenade type |
| [[A]] | Jump |
| [[Y]] / [[B]] held, then release [[Grip]] | Spin the held gun; squeeze [[Grip]] to catch it. Release the eject button to drop it. |
| [[Right Stick Up]] / [[Right Stick Down]] | Jump / crouch when optional Stick Actions is enabled. |
| [[Right A]] + [[Left Stick]] | Shoot dodge with Stick Actions enabled; centred stick starts bullet time. |
| [[Left Stick Click]] / [[Right Stick Click]] held | Open that hand's optional weapon wheel with Stick Actions enabled. |
| [[X]] + [[Y]] / [[A]] + [[B]] held | Open that hand's optional Weapon Wheel; move over a gun and release to select. [[Square]] + [[Triangle]] / [[Cross]] + [[Circle]] are the matching Sense inputs. |
| [[X]] | Use a painkiller when Manual Painkillers is off |
| [[Options]] | Pause or open the game menu |
| [[Left Menu]] | SteamVR dashboard, which also pauses the game |
| Hold [[Square]] / [[Quest X]] / [[Index Left A]] for one second | Quick save while alive or quick load while dead |
| Double-tap [[Square]] / [[Quest X]] / [[Index Left A]] | Open or close the game menu |
| [[Steam Frame Right B]] / [[Steam Frame Left D-pad Left]] | Open the matching hand's optional weapon wheel after applying the publisher's Frame binding fix |

For Valve Index, close the game and SteamVR, then extract the complete publisher ZIP and run **Fix Index Controls.cmd** from its top folder with the adjacent `bindings` folder intact. Restart SteamVR and select the **Default** Max Payne 2 binding if you changed it. The publisher maps right A to jump, left A to painkillers and squeeze to grab. **Restore Index Controls.cmd** from the same ZIP reverses the binding fix; a SteamVR update may require running the fix again.

For Steam Frame's weapon wheel, close the game and SteamVR and run **Fix Frame Controls.cmd** from the complete ZIP. **Restore Frame Controls.cmd** reverses it. Repeat the fix if a SteamVR update resets those bindings.

Melee hits need a firm swing. Staggering an enemy can let you grab and disarm their weapon. The mod can also catch live grenades and bat airborne weapons. PSVR2 adaptive triggers require the optional, separately installed PSVR2 Toolkit; regular vibration does not.

### Limitations and help

This is a community mod for an old game; expect bugs and uneven performance. Keep the complete ZIP layout together during setup. If VR Settings is missing or a punch reports a missing `mp2vr_punch` or `mp2vr_gun_hit` sound, confirm **MP2VR_FirstPerson** is selected in the game's launcher and update option 1; rc.66 includes the publisher's archive-priority fix. If installation fails, read the installer log and use its recovery path. For gameplay bugs, note the mod version, headset, PC connection method, level and exact reproduction steps for [evilSheep's issue tracker](https://github.com/evilSheep/max-payne-2-vr/issues). [Publisher releases and documentation](https://github.com/evilSheep/max-payne-2-vr) provide current changes.

## MaxPayne2VR by betotron — option 2

MaxPayne2VR adds stereo OpenXR, roomscale and motion controls. It is also a WIP beta. **Virtual Desktop is the only runtime confirmed by this author.** Its 32-bit runtime does not support SteamVR; Meta Link did not work in the author's tests. Start Virtual Desktop before pressing **Play Virtual Desktop**. On first launch, a flat view can remain for roughly 10–30 seconds before VR starts; follow the T-pose calibration prompt.

### Installation and configuration

Choose option 2 in **Install / manage VR mods**. The Hub follows betotron's stable GitHub releases; the currently reviewed release is `v1.2`. Setup stores its four loader files in profile B without changing the active loader. It preserves `MaxPayne2VR.ini` beside `MaxPayne2.exe` because it contains calibration and comfort settings. Existing Hub-owned loader files and their original backups remain tracked separately during migration.

### Controls

| Button | Action |
|---|---|
| [[Right Trigger]] | Fire or confirm |
| [[Right Grip]] | Use |
| [[A]] | Reload |
| [[B]] | Jump |
| [[Right Stick Click]] | Painkiller |
| [[Left Stick]] | Move |
| [[Left Grip]] | Melee |
| [[X]] | Bullet time |
| [[Y]] | Weapon selector |
| [[Menu]] | Escape or pause |
| [[M]] / [[N]] | Adjust height |
| [[Comma]] / [[Period]] | Adjust IPD |

Performance and compatibility are still being refined. If it does not enter VR, confirm that Virtual Desktop is active, wait through the initial flat interval, and use the [publisher's release page](https://github.com/betotron/MaxPayne2VR-release) for notes and reports.

>>> Nothing was bulletproof. Not even the weather.
