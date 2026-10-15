# Life is Strange: Before the Storm - DawnVR Installer

Automated installer for the DawnVR VR mod by TrevTV.

## About the Game

*Before the Storm* follows Chloe Price through a choice-driven story in Arcadia Bay, before the events of the first *Life is Strange*.

## What it installs
- MelonLoader 0.5.7 (required — no other version is supported)
- DawnVR v1.0.1 (Original or Remastered, your choice)

## How to use

1. Click **Install Mod** on the game tile or detail page
2. Choose your game edition (Original or Remastered)
3. Let setup download and validate both packages, then follow its Steam launch-option prompts. A failed download or incomplete package leaves no new success receipt.

## Requirements
- Windows 10/11
- A purchased, installed **Life is Strange: Before the Storm** Original or Remastered edition. The publisher documents Steam setup; other store launch behaviour has not been verified.
- SteamVR installed
- Internet connection (for mod downloads)

## Important notes
- **ONLY MelonLoader 0.5.7 is supported** — do not upgrade
- First launch takes longer — MelonLoader configures itself and DawnVR's enabler extracts required files
- Make sure **SteamVR is running** before launching the game
- Disable Steam's **Use Desktop Game Theatre while SteamVR is active** option for the game
- Add this to your Steam Launch Options (the installer guides you and copies
  it for you):

```
-vrmode OpenVR
```

To temporarily disable the mod, replace `OpenVR` with `None` in the launch
options — the game then loads normally.

## Controls

![Controller layout](ControllerLayout.jpg)

The publisher maps VR-controller buttons to Xbox One inputs; see the image for device-specific positions. The main controls are:

| Button | Action |
| --- | --- |
| [[Left Stick]] | Movement / UI navigation |
| [[Left Stick Click]] | Select |
| [[Right Stick]] | Turning |
| [[Right Stick Click]] | Start |
| [[RB]] | Sprint |

## Configurable options

The config file is `UserData\MelonPreferences.cfg` inside the game folder (open
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

The publisher describes DawnVR as being in maintenance mode: bug fixes may still arrive, but new features are not actively developed.

## Troubleshooting
If you see an **Initialization Error** on startup:
1. Make sure `-vrmode OpenVR` is set in Launch Options
2. Make sure SteamVR is open before launching
3. Next to the game executable, find the matching data folder (its name ends in `_Data`; the full name depends on the original/remastered edition). Delete `globalgamemanagers.bak` from that folder, then restart.

## Source
DawnVR mod: https://github.com/TrevTV/DawnVR

>>> Life is strange... and now it's in VR!
