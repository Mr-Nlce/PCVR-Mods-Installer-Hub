# Dishonored VR

## About the Game

Dishonored (2012) is Arkane's stealth adventure in Dunwall. Dishonored VR v1.0.4 adds stereo rendering, head tracking, tracked hands, motion aiming, physical leaning/crouching and full-arm IK. The current project is maintained by Pizza Parker (BioVRDev) and VOID at [VR-Stereo-Hub](https://github.com/VR-Stereo-Hub/Dishonored-VR). Gingas made the original mod through alpha 38.92; this continuation is with her permission.

## Install and update

The Hub downloads the latest stable `DishonoredVR-Launcher-v<version>.exe` from the [publisher releases](https://github.com/VR-Stereo-Hub/Dishonored-VR/releases). The launcher handles installation, updates, headset choice, render size, disabling VR and uninstalling. The separate `dishonored-vr-v<version>.zip` is the manual package, not the normal installer. The previously inspected v1.0.3 ZIP contains 32-bit VR DLLs, configuration, documentation, a `dvr_dlss` image-quality component and optional ReShade support; it has no `dxvk_d3d9.dll` or movie replacements from the old alpha. Some text inside that older ZIP says v1.0.1; use the matching publisher release notes and launcher for current instructions.

Close Dishonored before starting. Read the Hub's instructions and press Enter before the publisher launcher opens. Select your Steam or GOG Galaxy copy and headset in its window. The Hub records an installed version only after the publisher's `dishonored_vr_install.json` and required files are present and its DLL hash matches the record. If the Hub cannot download the launcher, it offers Retry or an explicit manual EXE path. It never selects a Downloads file silently.

Updating from the old Hub alpha: click Update once. Before the publisher launcher opens, the Hub verifies the old ownership list, temporarily removes the recorded alpha files and restores backed-up original game files in the same installer run. If the publisher run fails or does not prove a complete installation, the Hub restores the previous alpha files and version marker. If a recorded old mod file was changed, the Hub preserves a separate copy under `DishonoredVR-Legacy-Backup` in the game folder. An invalid ownership list or missing original backup stops migration without claiming success. You do not need to visit the separate Manage / remove action first. Do not use the old `d3d9.dll.flat` switch with the current launcher. The launcher has Disable VR and Uninstall actions.

If the antivirus removes a file, inspect its protection history and the launcher log. A missing file alone does not prove antivirus quarantine. The launcher can collect support logs for an issue report.

## Start in VR

Start the Steam copy through Steam; the Hub's Start in VR uses `steam://rungameid/205100` for a Steam installation. Start the GOG copy through GOG Galaxy or Launch via GOG in the publisher launcher. Do not launch `Dishonored.exe` directly for a Steam copy; the publisher notes that this may crash at the main menu. The Hub's GOG start route is not yet verified with a real GOG installation.

| Headset | Runtime |
|---|---|
| Quest via Virtual Desktop | Use VDXR as the OpenXR runtime; 120 Hz is recommended, SSW off. |
| Vive, Index and other SteamVR headsets | Start SteamVR first and select the launcher option for a SteamVR headset. It uses the bundled 32-bit bridge. |

The desktop mirror starts off. If SteamVR crashes at startup, switch the mirror on in the launcher and retry. Set a normal game window resolution; the old alpha's forced 4032×2268 setting should be reverted. The launcher configures the new release and backs up settings it changes. If you change video settings inside the game later, run the launcher again to restore the recommended game-side settings.

The F10 panel offers DLAA/DLSS for NVIDIA and FSR 3.1/4 for supported AMD hardware. HUD and objective markers remain sharp because they are drawn after upscaling. The launcher adds an Ultra quality tier up to 300% resolution; increase it only as GPU headroom permits. F10 also offers sharpening, experimental TAA, supersampling, per-eye object culling and snap turn; the v1.0.3 launcher can remap controller buttons before starting the game.

v1.0.3 rendering: Alternate Frame Warping (AFW) renders one eye per game frame and reconstructs the other from depth. Select it in the launcher, or use [[Left Stick Click]] + [[Right Stick Click]] to open F10 and choose Display > Stereo rendering > Alternate frame warping (AFW). It changes live without restarting. Full Stereo remains the default and can be selected again at any time. The publisher recommends pairing AFW with DLSS Ultra Quality; performance depends on your PC. Held objects can flicker in AFW. The mod's separate spacewarp option is currently broken and remains in Debug only.

The launcher also has an optional Mods section, ReShade 6.8 installation, texture-pack memory option and subtitle readability settings (the latter in the INI for now). [[Scroll Lock]] toggles installed ReShade effects. Presets that need depth require non-manual ReShade mode. These optional packages are separate from the Hub's required VR-file proof.

The v1.0.4 release adds full-arm IK and direct hand grabs for loot, books, doors, switches and throwable objects. Fit shoulder position and arm length in F10 > IK; turn IK off there if you prefer floating hands. Grab settings are in F10 > Interact. The launcher now puts DLSS and FSR beside resolution. It also fixes the view becoming flat or boxed when a shop conversation opens, along with several SteamVR, ReShade and eye-rendering faults.

## Controls

| Button | Action |
|---|---|
| [[Left Stick]] | Move. |
| [[Left Stick Click]] | Toggle sprint. |
| [[Right Stick]] | Turn. |
| [[Right Stick Click]] (hold) | Drink a health elixir. |
| [[Left Trigger]] | Use the equipped power or gadget; throw a carried object. |
| [[Right Trigger]] or a right-hand swing | Sword attack. |
| [[Left Grip]] (hold) | Open the weapon and power wheel; point with the left hand, then release to equip. |
| [[Right Grip]] | Block or choke from behind; grab a nearby interactable with the right hand. |
| [[Left Grip]] (near an object) | Grab a nearby interactable with the left hand. |
| [[A]] | Jump or climb. |
| [[B]] | Crouch; slide while running. |
| [[X]] | Interact; hold to sheathe weapons. |
| [[Y]] + [[Right Stick]] | Lean. [[Y]] also triggers the game's adrenaline action. |
| [[Menu]] | Pause; [[Right Thumbrest]] + [[Menu]] opens the journal. |
| [[Right Thumbrest]] + [[Left Stick]] | Use item shortcuts. |
| [[Left Stick Click]] + [[Right Stick Click]] (tap) | Open or close the F10 settings panel. |
| [[Left Stick Click]] + [[Right Stick Click]] (hold) | Recenter. |
| [[X]] + [[Y]] | Pause on SteamVR controllers without a Menu button. |
| [[F5]] | Recenter from the keyboard. |
| [[F10]] | Open the settings panel from the keyboard. |

In the settings panel, point with the right hand and use [[Right Trigger]] to click; [[Right Stick]] scrolls or adjusts sliders. The launcher's Bindings page and the in-headset Layout tab show the full controller diagram.

## Known limits and help

The publisher notes mention an upside-down view with SteamVR's native 32-bit OpenXR; use the bundled SteamVR bridge selected in the launcher. v1.0.2 fixed the small boxed view after death or menus, per-eye disappearing objects, a startup freeze and a lingering Steam process on quit. v1.0.3 fixed crashes after changing resolution or installing a texture pack; v1.0.4 fixed the boxed or flat view on shop conversations. A character can briefly appear as a dark silhouette with per-eye culling; F10 Advanced > Display > Object culling > Off avoids that at some GPU cost. See the included `KNOWN_ISSUES.txt` and `TROUBLESHOOTING.txt` for current details.

For support, use Collect logs in the publisher launcher and attach its ZIP to the [issue tracker](https://github.com/VR-Stereo-Hub/Dishonored-VR/issues). The mod contains no Dishonored game files. Dishonored is by Arkane Studios and Bethesda.

>>> The Empress is dead. Take the mask, take the city.
