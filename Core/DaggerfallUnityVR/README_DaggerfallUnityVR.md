# Daggerfall Unity VR

VR mod (**DFUVR** by LokiusV) for **Daggerfall Unity**, the open-source recreation of the classic 1996 RPG **The Elder Scrolls II: Daggerfall** in the Unity engine. Early access - fully playable but still a bit janky.

## About the mod
DFUVR brings full room-scale VR to Daggerfall Unity - the vast, procedurally generated province of the Iliac Bay with its thousands of dungeons, towns, and a main quest of genuinely enormous scope. You play in motion controls: draw your weapon from a sheath at your hip, cast spells with gestures, climb, and pick your way through the famously sprawling dungeons in first person. It's an early-access build - playable end to end, but expect a few rough edges.

## Requirements
- **Daggerfall (DOS)** on Steam (AppID 1812390, free) - supplies the original game data
- A working **Daggerfall Unity** install (the installer fetches it for you)
- A **1920x1080 monitor or higher** (see the display note below)
- SteamVR
- Motion controllers

## What the installer does
1. Checks for Daggerfall (DOS) on Steam; opens the free install prompt if missing.
2. Downloads the Daggerfall Unity engine and installs it to `C:\Games\Daggerfall Unity VR`.
3. Runs the engine once (flat) so it can find your game data and create its config, then backs up that config (the VR mod overwrites `KeyBinds.txt`).
4. Downloads the DFUVR mod and adds it on top (BepInEx).
5. Opens display settings and creates a desktop shortcut.

## How to launch
1. Set **all** monitors to **1920x1080** (the in-game UI won't render otherwise).
2. Start **SteamVR**.
3. Launch via the Hub's **Start in VR** button, or the desktop shortcut **Daggerfall Unity VR**.
4. First-run menu: pick your **Controller type** (Oculus/Meta, HTC Vive Wands, or other).

> Always keep the game window focused - the mod emulates mouse/keyboard input on your desktop, so an unfocused window can send clicks/keys to other apps.

## Controls
On first spawn, calibrate height and sheath position:
- Press and hold **X**, then **Y** on the **left** controller.
- Adjust height with the **right** thumbstick (up/down).
- Your sheath sits at your left hand: put your left hand on your waist, look straight ahead, then release the buttons.

The **X** button on the left controller is **SHIFT** - hold it for the red (alternate) actions in the diagram below. Bindings are fixed in this early-access build.

### Left controller
- **[[Thumbstick]]** — Move (click to sprint)
- **[[Y]]** — Inventory (SHIFT: Journal)
- **[[X]]** — SHIFT modifier
- **[[Menu]]** — Character sheet
- **[[Trigger]]** — Interact / Talk (SHIFT: Rest)
- **[[Grip]]** — Climb while crouching (SHIFT: Transport selection)

### Right controller
- **[[Thumbstick]]** — Click: Cast spell (SHIFT: Automap) / up: Jump / down: Steal mode
- **[[B]]** — Calibration mode
- **[[A]]** — Recast spell (SHIFT: Travel map)
- **[[Trigger]]** — Click UI / Shoot

### Layout reference

![Controller layout](ControllerLayout.jpg)

## Credits
- **DFUVR** VR mod by **LokiusV** - https://github.com/LokiusV/Daggerfall-Unity-VR
- Nexus page: https://www.nexusmods.com/daggerfallunity/mods/979
- **Daggerfall Unity** engine by **Daggerfall Workshop / Interkarma** - https://github.com/Interkarma/daggerfall-unity

>>> The Mantellan Crux awaits. Mind the spell reflection.
