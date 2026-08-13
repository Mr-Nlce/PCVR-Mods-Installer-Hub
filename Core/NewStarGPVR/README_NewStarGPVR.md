# New Star GP VR

A VR mod for New Star GP - the crisp, retro arcade motorsport game where you manage and race your own team through the decades, from the 1980s to today. Plays with a normal gamepad or keyboard in VR; VR motion controllers can optionally be mapped to a virtual gamepad.

**Mod**: New_Star_GP_VR - by Astienth, distributed via Discord
**Game**: New Star GP (Steam App 2217580)

## About this mod

A community VR mod for New Star GP, distributed by Astienth via Discord. **Discord login is required** to access the download. The mod runs on **OpenVR by default** (OpenXR is available via a config switch).

Mod info post:
- https://discord.com/channels/1001138422972432597/1522836877101629490/1522836922676940812

## What this Hub installer does

1. Joining the Discord server (skip if already in)
2. Reading and accepting the server rules
3. Downloading New_Star_GP_VR.zip from the mod channel
4. Auto-locating your New Star GP install (Steam libraries scanned)
5. Extracting the mod files next to the game exe (the `release` subfolder)
6. Optionally installing the bundled ViGEmBus driver - only needed if you want to use VR controllers as a gamepad

Note: the game exe lives in `New Star GP\release\NSGP.exe`, so the mod (winhttp.dll + BepInEx) is installed into that `release` folder.

## Requirements

- **New Star GP** on Steam (App 2217580)
- A VR headset with a working **OpenVR** runtime (OpenXR optional via config)
- **Keyboard or gamepad** - the default way to play
- **ViGEmBus** driver - **optional**, only if you want to use your VR motion controllers as a gamepad (the Hub installer offers it)

## Controls

Launch New Star GP normally via Steam - it starts in VR automatically. Keyboard or gamepad by default.

- **Recenter**: click [[Left Stick]] + [[Right Stick]] together, press [[F1]], or HOLD the gamepad [[Start]] button. Look forward and keep your head **horizontal** while recentering (pitch is decoupled off for this mod).
- **Hide / show UI**: [[F2]], HOLD the gamepad [[Back]]/[[Share]] button, or click [[Left Stick]] + press [[R1]]/[[RB]].

### Using VR controllers as a gamepad (optional)

1. Install **ViGEmBus** (the optional installer step, or run `release\BepInEx\redist\ViGEmBus_1.22.0_x64_x86_arm64.exe`).
2. In `release\BepInEx\config\UnityVR_Bepinex.cfg` set `vrControllersSupport = true`.

Prefer OpenXR over OpenVR? In the same file set `vrApi = OpenXR`.

## Mod configuration

After the first launch a `New_Star_GP_VR.cfg` is created in `release\BepInEx\config`:

```
worldScale = 1.0    # default 1.0; increase = world smaller, decrease = world bigger
```

## Known issues

- A few UI quirks - e.g. the "confirm to start a race" dialog box can appear under everything.
- Quickly made mod; if you hit a game-breaking issue, let Astienth know on Discord.

## Discord

- Mod info post: https://discord.com/channels/1001138422972432597/1522836877101629490/1522836922676940812
- Mod download: https://discord.com/channels/1001138422972432597/1522836877101629490/1524106963120816231

## Support the modder

Astienth makes these VR mods for free - you can support the work here: https://www.buymeacoffee.com/astienth4

>>> Lights out and away you go, champ - chase that checkered flag.
