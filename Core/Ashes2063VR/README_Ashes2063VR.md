# Ashes 2063 VR

## About the Game

Ashes 2063 is a free post-apocalyptic total conversion for GZDoom by Vostyok and the Ashes team. The standalone pack includes the Enriched campaign, Afterglow and Hard Reset. This Hub entry runs the campaigns with motion controls through hh79's GZDoomVR fork. No Ashes game data is bundled with the Hub.

## What the installer needs

- Ashes Standalone 1.51 from [ModDB](https://www.moddb.com/mods/ashes-2063/downloads/ashes-stand-alone-version-101). Download the ZIP yourself and drag it into the installer. The installer puts the game under `C:\Games\Ashes 2063 VR` by default.
- A Windows PC VR headset and SteamVR for the optional 3D hand-weapons route. Start SteamVR and confirm the headset is detected before launching. The original hh79 route also works with its supported OpenVR setup.
- The installer downloads the hh79 GZDoomVR engine from [GitHub](https://github.com/hh79/gzdoomvr/releases). It creates the normal Ashes 2063, Afterglow and Hard Reset launchers and desktop shortcuts.

## Optional 3D content

The installer offers world items, hand weapons, both or neither. You can rerun it and choose an add-on without downloading the large Ashes standalone ZIP again. Both add-ons can remain installed together, but they use separate launchers.

### 3D world items

The [ModDB 3D models add-on](https://www.moddb.com/mods/ashes-2063/addons/ashes-3d-models-2063-afterglow) replaces ammo, quest items, powerups, props and weapons lying in the world. It covers Ashes 2063 and Afterglow; Hard Reset and the weapon held in your hand remain 2D. The installer opens its download page after an Enter prompt, then accepts the downloaded ZIP by drag and drop. It adds the matching PK3 files to the original Ashes and Afterglow launchers. Replaced world-item PK3 files are saved under `.pcvrhub-3dworld-backups`.

### 3D hand weapons by TefMeister

The [Ashes 2063 3D Weapons for VR release](https://github.com/TefMeister/ashes-2063-weapons/releases) supplies a separate `3DWeapons` folder, modified GZDoomVR engine and `Play Ashes 2063 VR - 3D Weapons.bat`. The installer downloads the newest stable release, verifies its required files and places it beside `Resources`. It also creates an Ashes 2063 VR - 3D Weapons desktop shortcut. It does not replace the original `gzdoomvr` folder or the normal Ashes launchers. Existing 3D-weapons settings in `3DWeapons\settings.ini` are retained on update; replaced add-on files are backed up under `.pcvrhub-3dweapons-backups`.

Use `Play Ashes 2063 VR - 3D Weapons.bat` to play with 3D hand weapons. The Hub's Start in VR button continues to use the original Ashes launcher. The add-on currently models the revolver, pistol, shotgun and lantern. The shotgun has two-handed aiming: the left hand steers the barrel and the shot follows it. Other weapons still use the game's flat pictures. The revolver has no hand model yet, and the left hand appears only for the lantern, shotgun and briefly during pistol reload. The lantern can trail behind the hand while walking. This is unfinished work and may cause severe motion discomfort; take breaks and stop playing if unwell.

At its first launch the weapon route copies existing buttons and comfort settings from `gzdoomvr\ashes-vr.ini` into its own `3DWeapons\settings.ini` if available. Otherwise it uses its VR defaults. Its launcher adjusts gun angle and two-handed grip settings for the models. For grip-only two-handed shotgun control, set `tefa_grip_required` to true in the console and bind `Grip fore-end + run (VR grip)` under Options > Customize Controls > Ashes 2063 VR (Tefa). See `3DWeapons\README.txt` for current publisher instructions and uninstall details.

## Controls

Bindings can be adjusted in SteamVR and in Options > Customize Controls. The original GZDoomVR route exposes comfort, turn and weapon-angle settings under Options > VR. Typical controls are:

| Button | Action |
| --- | --- |
| [[Trigger]] | Fire the aimed weapon |
| [[Grip]] | Secondary or configured grip action |
| [[Left Stick]] | Move |
| [[Right Stick]] | Turn |
| [[A]] | Jump |
| [[B]] | Use or open |
| [[Menu]] | Open the main menu |

The hand-weapons route adds the two-handed shotgun and a lantern held in the left hand. Its exact bindings can differ with your SteamVR profile; review them in the game.

## Launch, recovery and removal

Use Hub Start in VR for the original Ashes 2063 campaign. The Afterglow and Hard Reset desktop shortcuts start their respective episodes. Use the publisher's `Play Ashes 2063 VR - 3D Weapons.bat` for the hand-weapons route. That route does not cover Afterglow or Hard Reset.

If a route starts flat, check that SteamVR sees the headset before launch. If a 3D-weapons update does not work, inspect `3DWeapons\README.txt` and the saved files in `.pcvrhub-3dweapons-backups`. To remove only the hand-weapons add-on, move `3DWeapons` out of the game folder as a backup so your `settings.ini` and any custom files are retained, then remove `Play Ashes 2063 VR - 3D Weapons.bat` and its desktop shortcut. The original VR setup and game content remain. Remove the two world-item PK3 files from `Resources` and rerun the installer to regenerate the original launchers if you want to remove only world models.

Tune in to Spire Radio, scavenger - the wasteland is hungry tonight.
