# Dark Souls II VR

## About the Game

Dark Souls II: Scholar of the First Sin is a fantasy action RPG about exploring Drangleic, surviving demanding combat and piecing together a fallen kingdom. This entry needs the current Windows 64-bit Steam Scholar edition. The original Dark Souls II and console editions are different builds.

## DS2VR and requirements

DS2VR by MixtapeRomeo adds SteamVR headset tracking, tracked hands and weapons, gesture-driven combat, body weapon slots and an in-game settings panel. Index controllers are the publisher's physically tested baseline. Touch, Vive Cosmos, Vive wands, original WMR and PSVR2 Sense bindings are included; hardware-specific validation remains incomplete. Quest controllers need a PC VR connection that exposes them to SteamVR. Start SteamVR and connect both controllers before launching the game.

The mod is for offline play. It blocks the game's server-login hostname, but this is not a complete network sandbox or a guarantee against account penalties. Keep the game offline. DS2VR cannot be installed over a different mod's `Game\dinput8.dll`; the Hub stops before changing that file. Luke Ross's R.E.A.L. is a separate gamepad option in the Hub, not a dependency of DS2VR.

## Install and launch

1. Install the current Steam Scholar version and back up your saves and existing mods. Close the game.
2. Use Get Installer. Log into [Nexus Files](https://www.nexusmods.com/darksouls2/mods/1745?tab=files) and choose Manual download. The Hub asks before opening Nexus, then lets you choose a ZIP in your registered Downloads folder or drag/paste its path.
3. The installer checks the ZIP and places its complete publisher file set in the game's `Game` directory beside `DarkSoulsII.exe`. It keeps existing DS2VR INI settings during updates and records installed files for direct removal.
4. Start SteamVR, then launch Dark Souls II normally through Steam in offline mode. Open the in-game Start menu and press both grips to open or close the DS2VR settings panel.

Lighting Engine is optional. If using DS2LE 0.9.51, install it first and DS2VR last; the mod's five shader corrections target that precise version. A different or unknown Lighting Engine build needs manual compatibility review. Since DS2VR 1.0.3, FSR can use Lighting Engine's native backend. The Hub stops when it finds shader files that it cannot safely identify as DS2VR-owned.

## Controls

The table lists the shipped Touch layout. In native choice popups, the left stick selects options rather than moving the character; movement resumes when the popup closes. Other controller layouts have different face-button and pad mappings in the publisher's `docs/controller-support.md`.

| Button | Action |
|---|---|
| [[Left Stick]] | Move; navigate native choice popups and menus. |
| [[Right Stick]] | Turn. |
| [[Right A]] | Dodge, hold to sprint, or Back in a menu. |
| [[Right B]] | Jump while sprinting or toggle action. |
| [[Left X]] | Use an item or the alternate menu action. |
| [[Left Y]] | Open the Start menu or go Back. |
| [[Left Stick Click]] | Next item. |
| [[Right Stick Click]] | Next spell. |
| [[Left Grip]] / [[Right Grip]] | Interact and select a hip, chest or shoulder weapon slot. |
| [[Both Grips]] | Open or close the DS2VR panel while the Start menu or panel is open. |
| [[Left Trigger]] / [[Right Trigger]] | Heavy swing while swinging that hand; cast or fire when holding a catalyst or crossbow. In menus, right confirms and left is remove/alternate. |

Ordinary weapon swings request the game's native attacks; the game still determines damage, stamina, combo windows and recovery. Raise a shield toward chest height to guard. Bow use requires taking an arrow from a shoulder with the other hand, gripping it to the string, drawing and releasing. Secondary arrows and bolts have no VR modifier yet. Reaching hip, chest or shoulder zones selects weapon slots 1, 2 or 3 for either side. Grip sensitivity, zone boxes, hand rig, attack step and comfort can be adjusted in the in-game panel.

## Rendering, settings and limitations

The standalone renderer offers native resolution, DLSS/DLAA on supported NVIDIA hardware and FSR 3.1.4 upscaling. FSR has no frame generation; the 1.0.3 release also supports it with Lighting Engine 0.9.51. Version 1.0.4 adds PSVR2 Sense diagnostics in the existing `DS2VR.log` and changes the Arcade end-speed default to 3.5 m/s without replacing saved settings. Optional experimental Neural Rendering needs a separately obtained compatible 310.8 runtime; it is neither bundled nor required. Settings are saved in the DS2VR INI files and remain in place when the Hub updates or removes the mod.

DS2VR uses alternate-eye rendering: 120 game frames per second means roughly 60 newly rendered frames per eye. It cannot promise a headset refresh rate. The publisher reports that rotational drift can accumulate; use SteamVR recenter. Seamless Co-op compatibility and clean game/headset validation of this archive remain unconfirmed.

## Troubleshooting

- No VR or tracked hands: check SteamVR, both controllers, the matching SteamVR default binding, `Game\dinput8.dll`, `Game\DS2VR\openvr_api.dll` and all action/binding JSONs. Restart after an update; saved custom SteamVR bindings can override new defaults.
- Unsupported executable: verify the current 64-bit Steam Scholar build. Keep the exact game build and `Game\DS2VR.log` for a report. Do not bypass the version check.
- Unexpected attacks or grip activation: adjust swing travel/speed and grip squeeze/release in Hands and combat. Release must be below squeeze. Index analog grip settings do not create analog sensors on other controllers.
- FSR, DLSS or optional NR failure: choose native rendering, check supported GPU and `Game\DS2VR.log`, then retry after correcting the runtime. NR is optional.
- Lighting Engine shaders present: confirm DS2LE 0.9.51 before replacing any shader. Reapplying Lighting Engine later requires reapplying DS2VR's corrections while preserving the INIs.

The detail page's Uninstall now button removes unchanged Hub-owned DS2VR files, restores any same-name files that the Hub backed up, and leaves saves, settings and unrelated files. Changed files are preserved for review. The gamepad R.E.A.L. entry remains independent.

## Support the modder

[Donate to MixtapeRomeo](https://www.paypal.com/donate/?business=FBYDM2GKEUM3C&no_recurring=0&currency_code=USD)

>>> Seek souls, not a second dinput8.dll.
