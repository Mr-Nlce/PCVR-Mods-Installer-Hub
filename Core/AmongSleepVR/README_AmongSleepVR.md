# Among the Sleep VR

## About the Game
A frightened toddler and his talking teddy search for safety in a house that becomes stranger after dark. Crawl through childhood nightmares, solve environmental puzzles and discover what is hiding behind the bedtime story.

## Requirements
The Windows Steam game, Unity 5.6 Mono 32-bit, is the reviewed installation route. BepInEx 5 x86 and the mod's own atsxr OpenXR bridge are included in the publisher ZIP. Other stores and newer engine builds have not been tested for this Hub entry.

Connect your headset and start its active 32-bit OpenXR runtime first. The publisher lists Quest Link, Air Link, Virtual Desktop, SteamVR and WMR. A 64-bit-only runtime cannot serve this 32-bit game.

## Install and start
1. Close Among the Sleep. Choose Install in the Hub. The complete publisher ZIP is copied beside Among the Sleep.exe. Saves are kept; edited settings can be kept or replaced after a backup.
2. Use Start in VR in the Hub. Alternative: start the game through Steam after activating your headset runtime.
3. At the main menu, hold [[Right Stick Click]] to recenter at the correct toddler height. Hold [[Y]] + [[Left Stick Click]] for about one second to open VR settings.

Flat / VR changes the General > enabled value in doorstop_config.ini. Close the game before switching. Switch back to VR before starting a VR session; updates preserve your selected loader setting.

## Controls
The VR controllers emulate keyboard and mouse inputs because the game's gamepad mode is unreliable. Keep the game in keyboard and mouse mode. Aim the right controller at menus and interactive objects.

| Button | Action |
|---|---|
| [[Left Stick]] | Walk |
| [[Left Stick Click]] | Sprint |
| [[Right Trigger]] | Grab, use or click a menu item |
| [[Left Trigger]] | Throw |
| [[Left Trigger]] held + [[Right Stick]] | Move the mouse while holding an item with [[Right Trigger]]; helps open the Teddy chest |
| [[Right Grip]] | Lean right |
| [[Left Grip]] | Lean left; hold 1.7 seconds to toggle the added flashlight |
| [[A]] | Jump or climb |
| [[B]] | Crawl |
| [[X]] | Bring out Teddy |
| [[Y]] | Inventory |
| [[Y]] + [[X]] | Pause |
| [[Right Stick]] down | Rotate an item |
| [[Right Stick]] left or right | Turn |
| [[Right Stick Click]] | Switch first and third person |
| [[Right Stick Click]] held | Recenter |
| [[Y]] + [[Left Stick Click]] held | Open VR settings |

## Help
Version 0.2.2 includes publisher fixes for the black UI panel and characters blending through objects. These fixes have not been verified in a headset for this update round.

During an update or reinstall, Setup asks before replacing an edited VR settings file. Press Enter to keep your settings, or choose Y to use the defaults included with the new VR mod. Before replacing it, Setup saves your current file in .pcvrhub_amongthesleepvr_settings_backups inside the game folder. These backups remain after uninstalling.

Third-person view can reveal missing walls because the game was designed for first person. Return to first person if the view becomes confusing. Reach, flashlight brightness, world scale, HUD placement and rendering options are available in the mod settings.

Try the game first. If VR works, leave the Steam Launch Options unchanged. The optional -force-d3d11 option selects DirectX 11, which the VR mod needs. The additional -force-gfx-direct option uses single-threaded rendering as a compatibility workaround if the VR bridge cannot reach the render thread; performance may change. The publisher did not need these options on their own PC.

If needed, open Steam > Among the Sleep > Properties > General > Launch Options and add -force-d3d11 -force-gfx-direct, keeping any other options you need. The installer can guide this step. To undo it, remove only these two options from the same field.

Missing files alone do not prove antivirus removal. Check the game location, permissions, installer log and any matching protection-history event. Recovery can reopen the official release page and accept a manually downloaded ZIP.

## VR files
Start in VR uses Steam app 250620 to start Among the Sleep.exe. The VR files are BepInEx\plugins\ATSVR\ATSVR.dll and atsxr.dll, with the included BepInEx loader beside the game. Settings are in BepInEx\config\amongthesleep.vr.cfg; the loader log is BepInEx\LogOutput.log. The Hub displays the detected game folder and start app as links once the VR mod installation is present. If the Hub does not find your game, you can choose Locate Game and select the game EXE.

## Links
- Mod documentation and source page: https://github.com/King-EJ/Among-the-Sleep-VR
- Publisher releases: https://github.com/King-EJ/Among-the-Sleep-VR/releases

>>> Teddy said he would keep you safe. He did not mention bedtime overtime.
