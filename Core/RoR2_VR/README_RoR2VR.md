# Risk of Rain 2 VR Installer

Automated installer for **VRMod 2.9.2** by DrBibop — full VR with motion
controls for Risk of Rain 2. Because the live Steam build moves ahead of
the mod, this installs a pinned, mod-compatible Steam depot build into its
own folder, completely separate from your retail copy.

## What it installs

- **Steam depot build** — a pinned Risk of Rain 2 version compatible with
  VRMod, downloaded via the Steam Console
- **BepInEx + dependencies** — mod loader and required packages
- **VRMod 2.9.2** — the VR mod with motion controls

## Requirements

- Risk of Rain 2 owned on Steam
- SteamVR installed
- A PC ready for PCVR. Works with any Oculus or SteamVR-compatible headset,
  including WMR and Quest/Quest 2 via Link, Air Link or Virtual Desktop

## How to use

Click **Install Mod** on the game tile or detail page and follow the
prompts. The installer guides you through the Steam Console depot download,
then handles BepInEx and the mod automatically.

## Features

- **Full motion controls** — aim weapons and use equipment with your hands
- **First-person by default**, with a third-person option in the settings
- **Aim stabilisation** for better accuracy (extra positional stabilisation
  on two-handed weapons), adjustable in settings
- **Free SteamVR bindings** — every action can be bound to separate inputs;
  no need to download controller-specific binds
- **Comfort options**: snap turn, comfort vignette on high-mobility skills,
  seated mode, height multiplier, haptic feedback
- **Co-op friendly**: the mod is only needed by VR players — you can play
  alongside vanilla (non-VR) players in the same lobby

## Controls

Quest / Oculus Touch layout:

![Controller layout](ControllerLayout.jpg)

- **Left:** [[Stick]] = Move, press = Sprint; hold = Scoreboard; Pause/Vote
  Skip; Equipment; Utility & Secondary skills
- **Right:** [[Stick]] = Look, press = Ping / Recenter HMD; Jump; Interact;
  Primary & Special skills

Binds use SteamVR's binding system and can be remapped there (the in-game
icons won't change). There's currently no rebinding when using the Oculus
runtime instead of SteamVR. Some mods get dedicated binds too: ExtraSkill-
Slots (skills 1-4), VoiceChat (push-to-talk), SkillsPlusPlus (buy menu),
ProperSave (load).

## Launching

The VR build installs to its own folder (default `C:\Games\Risk of Rain 2
VR`) and is separate from your retail Steam copy. **Launch via the desktop
shortcut or the Hub's Start in VR button — not via Steam**, which would
start your flat retail version.

## Haptics

Supports the **bHaptics** and **Shockwave** suits. Enable in-game: Settings
-> VR tab -> scroll to the bottom -> "Haptics suit" -> pick your suit ->
relaunch.

## Custom characters

Custom survivors get full VR support via the VRAPI; without it they're
still playable but aim with a default pointer on the dominant hand. Fully
VR-supported examples (as of the mod's notes): Samus, Enforcer & Nemesis
Enforcer, Paladin, Tesla Trooper, and the playable Void Jailer.

## Tips

- **Disable game theatre mode** in the game's Steam properties, or VR may
  open on the flat theatre screen. Oculus users can instead enable "Use
  Oculus mode" in the config editor to bypass SteamVR entirely
- **Can't press buttons on launch?** The game window isn't focused — click
  it to bring it to the front (press the Windows key or Ctrl+Esc first if
  your cursor is stuck)
- VR Mod settings live in the in-game **"VR" tab**, or via the mod
  manager's Config Editor while the game is closed
- **Performance:** disabling SSAO and Bloom in the game settings helps; the
  VR Performance Toolkit (FSR/NIS upscaling) is another option
- **Motion sickness:** high-mobility characters like Loader and Mercenary
  move fast and can be intense — start with a slower character (Commando,
  Engineer) to find your VR legs. Keep the comfort vignette on for those
  fast skills

## More info

https://thunderstore.io/package/DrBibop/VRMod/

>>> Seek and destroy. It's raining again!
