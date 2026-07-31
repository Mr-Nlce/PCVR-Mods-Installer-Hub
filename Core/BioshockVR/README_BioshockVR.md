# BioShock Remastered VR Installer

Automated installer for **Bioshock Remastered VR** by BioVRDev - a native VR conversion of BioShock Remastered with real stereo rendering, full head tracking, motion controllers and 6-DOF weapon holding.

It hooks the game directly rather than wrapping it, so there is **no injector, no plugin folder and no launcher**: the mod loads when the game starts.

## What it installs
Five files next to `BioshockHD.exe` (in `Build\Final`, or `Build\FinalEpic` on Epic):
- **dxgi.dll** - loads the mod at startup
- **BioshockVR.dll** and **BioshockVR.ini** - the mod and its settings
- **openxr_loader.dll** - the OpenXR runtime loader
- **FirstTimeSetup.bat** - the one-time setup, run once by the installer

## Requirements
- **BioShock Remastered** on Steam, GOG or Epic
- Any **OpenXR** headset and runtime - Quest via Link or Air Link, SteamVR, or WMR
- Windows 10 or 11

## Launching
Launch with **Start in VR** in the Hub, or from Steam. Start your OpenXR runtime first and put the headset on - the mod loads on its own when the game starts.

## Why the setup step exists
BioShock reads its config at startup and **rewrites it on exit** with whatever it actually ran at. A fresh install therefore starts fullscreen at your desktop resolution and can never correct itself. `FirstTimeSetup.bat` sets the render resolution, FOV, windowed mode and anisotropic filtering *before* the game ever runs, which breaks that loop for good. It finds `Bioshock.ini` itself, backs it up first, changes ten keys in place, and restores the backup automatically if anything looks wrong.

Run it again any time you change **ResolutionX**, **ResolutionY** or **GameFovDegrees** in `BioshockVR.ini`.

## What VR adds
- **Rendering** - true stereo with both eyes locked to the same instant, and the reported field of view kept in sync with what the game renders, so turning doesn't warp
- **Head and camera** - full rotation and position tracking, pitch decoupled so the horizon stays level, walking head bob removed at the source, adjustable height and IPD
- **Hands and weapons** - the weapon follows your right controller; aim, crosshair and the actual shot all come from one value, so the dot is exactly where the bullet goes. Per-weapon grip is tunable live and saves itself.
- **Interface** - the HUD is lifted off the eye image onto its own layer at a comfortable depth; menus and the map sit on a screen fixed in the room
- **Cutscenes** - pre-rendered ones play on a screen anchored in the room instead of following your head

## Tuning in the headset
Everything below changes live, and every change writes a line you can keep.

- [[F11]] / [[F12]] make the HUD panel smaller or larger
- [[Del]] cycles which HUD property those two edit
- [[Home]] toggles the HUD panel off so you can compare
- [[Numpad 9]] cycles the weapon grip mode: position, angle, aim
- [[Numpad 8]] [[Numpad 2]] [[Numpad 4]] [[Numpad 6]] [[Numpad 0]] [[Numpad 5]] adjust the current mode
- [[Numpad 7]] changes the step size

To get a weapon exactly right, set the angle first, then switch to aim mode and fire at a flat wall until the dot sits on the bullet hole. The dot and the shot come from the same value, so that test is exact.

Weapon grip values write themselves into `BioshockVR.ini` as you go - edit that file with the game closed, or your changes get overwritten.

## Recommended alongside
The mod author suggests two community mods for the best result:

- **Fullscreen Cutscenes** - removes the black bars from cutscenes, which otherwise stay visible on the VR screen. **The installer offers to set this up for you** as an optional last step: https://www.nexusmods.com/bioshock/mods/81
- **HD Textures** - install this one yourself: https://www.nexusmods.com/bioshock/mods/54

The download contains two versions and the installer takes the **vanilla** one. The other is a combination with the author's *Deep Pockets HUD*, which only makes sense if you also run NewBlood's *Deep Pockets* mod - install that one by hand if you need it. Either way it replaces the game's `HUDPC.swf`, so it removes any other HUD mod; the original is kept as a backup.

## Known issues
- **dxgi.dll can only belong to one mod.** ReShade, DXVK, Special K and most injectors install under the same filename, so they can't be used together with this.
- Reticle removal and arm hiding use fixed addresses into the game executable. On a different build they detect the mismatch and do nothing - set `DisableReticle=0` and `HideArmSleeves=0` to silence the log. Everything else finds its targets by scanning.
- Grip offsets are tuned for 2750x2850 at FOV 100 and don't carry across resolutions - expect to re-tune if you change either.
- Crossbow, grenade launcher, chemical thrower and research camera aren't tuned yet and fall back to a generic offset. Usable, but they sit wrong in your hand.
- In-engine cutscenes still follow your head; only pre-rendered ones move to the flat screen.
- Weapon idle sway remains, because the weapon hangs off the arm mesh.

## Performance
**ResolutionX** and **ResolutionY** in `BioshockVR.ini` are the main dial - lower them and run the setup again. A field of view below 100 looks nearly identical in the headset but runs noticeably better, because the game stops rendering side content that never reaches the display.

## Removing it
Delete `dxgi.dll`, `BioshockVR.dll`, `BioshockVR.ini` and `openxr_loader.dll` from the build folder and the game is flat again. The setup kept a backup of your `Bioshock.ini` if you want the original video settings back.

## Credits
**Bioshock Remastered VR** by **BioVRDev** - https://github.com/BioVRDev/Bioshock-Remastered-VR
