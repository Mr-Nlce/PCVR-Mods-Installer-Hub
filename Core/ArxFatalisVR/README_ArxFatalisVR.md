# Arx Fatalis VR

**VR port:** [Arx Libertatis VR by cmpayc](https://github.com/cmpayc/ArxLibertatisVR)  
**Release checked:** [v0.1.0](https://github.com/cmpayc/ArxLibertatisVR/releases/tag/v0.1.0)  
**VR gameplay:** [Watch the publisher's video](https://www.youtube.com/watch?v=_hC8KJUZ9v4)

## About the Game

Arx Fatalis is a first-person fantasy RPG set in an underground world. Arx Libertatis VR is a separate, open-source OpenXR port of its engine. You fight with physical weapon swings, block with a shield, draw spell runes in the air and handle the book, inventory and objects with tracked hands. This is an early beta; rough edges remain.

## Install and update

Select the folder with your original Arx Fatalis game data. Setup checks `data.pak`, `data2.pak` and the location, sound and speech archives. Names such as `loc_default.pak`, `sfx_default.pak` and `speech_default.pak`, including language variants, are accepted. The separate VR engine does not need the old Windows game executable. Steam, GOG and retail folders are searched; you can choose another folder. Game detection does not confirm that a demo or an incomplete data set meets the port's requirements.

The VR port installs into a separate folder. Its launcher reads the original game data through Arx Libertatis's `--data-dir` option; it does not copy the large PAK files or replace the original executable. Re-run the Hub installer to update the port. Saves and configuration remain under `%USERPROFILE%\Saved Games\Arx Libertatis` and are shared with ordinary Arx Libertatis. Starting the flat port may reset the `[vr]` configuration section to defaults.

## Start in VR

Start SteamVR or Meta Quest Link, then select **Start in VR** in the Hub. This runs the separate `START-ARX-VR.cmd` launcher and passes the saved original game-data folder to the VR `arx.exe`. With Virtual Desktop, use SteamVR; VDXR and the Windows Mixed Reality runtime do not supply the required OpenGL OpenXR path. If the headset or runtime is absent, Arx starts flat. `arx.exe --no-vr` deliberately forces flat mode.

Version 0.4.1 improves seated torch-belt access: reach in front of and above the hip when the chair blocks it. Optional publisher-recommended HD textures and enhanced models are tracked separately; they are not required or installed automatically.

## Controls

The following are the publisher's right-hand-main bindings. Change the main hand in **Options > VR settings**.

| Button | Action |
| --- | --- |
| [[Left Stick]] | Move |
| [[Right Stick]] | Smooth or snap turn |
| [[Right Stick Click]] | Crouch |
| [[Left Stick Click]] | Toggle sneak |
| [[A]] | Jump; change stair level when the wrist icon appears |
| [[B]] | Open the book; hold for spell pages |
| [[X]] | Open inventory above the left wrist |
| [[Y]] / [[Menu]] | Pause and open the game menu |
| [[Right Trigger]] | Point and click; tap in the world for magic mode |
| [[Right Grip]] | Activate doors, levers, dialogue and loot |
| [[Left Grip]] | Activate with the left hand; right click in panels |
| [[Grip]] | Take, hold, carry or throw an object |
| [[Trigger]] while holding an object | Put it into inventory |
| [[Left Trigger]] | Select and drink from the potion wheel |
| [[Grip]] + [[Trigger]] | Make a fist and punch; outside combat, take a whole item stack from the world or inventory |

Draw a weapon over a shoulder with [[Grip]], swing it to strike, and return it over the shoulder to stow. Draw a bow the same way; use the other hand and [[Trigger]] to pull the string. For magic, tap [[Right Trigger]], draw a rune while holding it, release and repeat, then tap again to cast. Hold [[Right Grip]] while drawing to precast.

## Settings and troubleshooting

**Options > VR settings** provides turning, comfort vignette, shield blocking, rune drawing, movement direction, hand choice, height and desktop-view settings. The log is `%USERPROFILE%\Saved Games\Arx Libertatis\arx.log`; its OpenXR lines show the selected runtime and why VR may have failed. If audio is missing, set the headset as the Windows audio output.

Known beta issues: an object held while saving can float after load; some armor can clip near the face; only English tutorial text names VR controls.

>>> The runes are in your hands now.
