# Life is Strange: Before the Storm - DawnVR Installer

Automated installer for the DawnVR VR mod by TrevTV.

## What it installs
- MelonLoader 0.5.7 (required — no other version is supported)
- DawnVR v1.0.1 (Original or Remastered, your choice)

## How to use

1. Click **Install Mod** on the game tile or detail page
2. Choose your game edition (Original or Remastered)
3. The installer automatically handles the rest

## Requirements
- Windows 10/11
- Steam with **Life is Strange: Before the Storm** (Original or Remastered) owned and installed
- SteamVR installed
- Internet connection (for mod downloads)

## Important notes
- **ONLY MelonLoader 0.5.7 is supported** — do not upgrade
- First launch takes longer — MelonLoader configures itself on first run
- Make sure **SteamVR is running** before launching the game
- Add this to your Steam Launch Options (the installer guides you and copies
  it for you):

```
-vrmode OpenVR
```

To temporarily disable the mod, replace `OpenVR` with `None` in the launch
options — the game then loads normally.

## Controls

![Controller layout](ControllerLayout.jpg)

The image above shows the full button layout. The main ones:
- **[[Left Stick]]:** Movement / UI navigation
- **[[Left Stick]] press:** Select
- **[[Right Stick]]:** Turning
- **[[Right Stick]] press:** Start
- **[[RB]]:** Sprint

## Configurable options

The config file is at `<game folder>/UserData/MelonPreferences.cfg` (open
with any text editor). Highlights:
- **Movement/turning:** `MovementThumbstick` (dominant hand, default Left),
  `UseSmoothTurning` (default true), `SmoothTurnSpeed` (default 120),
  `UseSnapTurning` (default false), `SnapTurnAngle` (default 45)
- **Spectator camera:** `SpectatorEnabled` (separate higher-FOV monitor
  camera, default false), `SpectatorFOV` (default 90)
- **Misc:** `Use2DCutsceneViewer` (default true; disable to view cutscenes
  in full VR with free head movement), `AllowSkippingAnyCutscene` (default
  false), `DetachUIOnJournalOpen` (default true, easier journal reading),
  `CheckForUpdatesOnStart` (default true)

Note: resolution and FPS cap come from SteamVR and ignore the in-game
settings; other graphics options still affect visuals and performance.

## Troubleshooting
If you see an **Initialization Error** on startup:
1. Make sure `-vrmode OpenVR` is set in Launch Options
2. Make sure SteamVR is open before launching
3. Go into the game's `_Data` folder and delete `globalgamemanagers.bak`, then restart

## Source
DawnVR mod: https://github.com/TrevTV/DawnVR

>>> Life is strange... and now it's in VR!
