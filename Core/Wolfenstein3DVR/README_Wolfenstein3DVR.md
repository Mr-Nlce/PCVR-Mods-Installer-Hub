# Wolfenstein 3D VR Installer

## What it does
**WolfSharp VR** by Ben McLean is a from-scratch re-implementation of id Software's 1992 *Wolfenstein 3-D* (id Tech 0) for virtual reality, rendered in true stereoscopic 3D on the Godot 4 engine. It keeps the original pixel art and Adlib/Sound Blaster soundtrack while presenting the game in the headset. It runs over **OpenXR** (SteamVR or Meta Quest Link).

The *Wolfenstein 3-D* **shareware** (episode 1) is bundled and plays out of the box. To play the full six-episode game, *Spear of Destiny* and its mission packs, you supply your own original game data.

It's a free itch.io download: https://benmclean.itch.io/wolfsharp

## How the installer works
1. It opens the itch.io page - download **`wolfsharp-windows-x64.zip`** (~68 MB) from the Download section.
2. Back in the installer, it auto-detects the ZIP in your **Downloads** folder, or you drag-and-drop it in.
3. It extracts to `C:\Games\Wolfenstein 3D` (or D:/E:), creates a desktop shortcut, and records the install so the Hub's **Start in VR** works.
4. Optionally, it copies your own full-game / *Spear of Destiny* data (see below).

## Adding your own game data (optional)
WolfSharp loads the original 1992 MS-DOS game files at runtime. Data goes in a subfolder under the `games` folder next to the executable. The installer can do this automatically by finding a Steam / GOG / Xbox / Bethesda install of *Wolfenstein 3D*, or you can add files by hand.

|Title|Subfolder|File extension|
|---|---|---|
|Wolfenstein 3-D Shareware (bundled)|`WL1`|`*.WL1`|
|Wolfenstein 3-D (full)|`WL6`|`*.WL6`|
|Spear of Destiny|`M1`|`*.SOD`|
|Spear of Destiny Mission 2: Return to Danger|`M2`|`*.SOD` (GOG) or `*.SD2` (retail)|
|Spear of Destiny Mission 3: Ultimate Challenge|`M3`|`*.SOD` (GOG) or `*.SD3` (retail)|
|Super 3D Noah's Ark|`N3D`|`*.N3D`|

To add data manually: drop the matching files into `C:\Games\Wolfenstein 3D\games\<SUBFOLDER>\` (create the subfolder if needed). Files from platforms other than the original MS-DOS releases are not supported. Adding `WL1` data overrides the bundled shareware.

Where the data usually lives:
- **Steam** (`Wolfenstein 3D`, App 2270): `...\steamapps\common\Wolfenstein 3D\base\*.WL6` and `...\base\m1\*.SOD`
- **GOG**: `C:\GOG Games\Wolfenstein 3D`
- **Xbox / PC Game Pass**: `C:\XboxGames\Wolfenstein 3D\Content\base`
- **Bethesda.net (legacy)**: `...\Bethesda.net Launcher\games\Wolfenstein 3D\base`

## Requirements
- A PC VR headset with an OpenXR runtime (SteamVR, or Meta Quest Link / Air Link).
- For anything beyond the bundled shareware: your own original *Wolfenstein 3-D* / *Spear of Destiny* game data.

## How to play
Start your OpenXR runtime first (SteamVR or Quest Link), then use **Start in VR** in the Hub, or the **Wolfenstein 3D VR** desktop shortcut. Pick the game/episode from WolfSharp's in-game menu; the bundled shareware is available immediately, and any data you added appears alongside it.

## Controls
WolfSharp uses standard VR motion controllers over OpenXR. Bindings and comfort options (movement, turning) are set inside the game's own menu - open it in the headset to review or change them.

## Credits
- **WolfSharp VR** by Ben McLean - https://benmclean.itch.io/wolfsharp
- *Wolfenstein 3-D* (1992) by id Software, published by Apogee. Shareware episode included under its original 1992 shareware redistribution permission.
