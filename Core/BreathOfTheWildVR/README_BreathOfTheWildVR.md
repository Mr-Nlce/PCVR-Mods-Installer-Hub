# Breath of the Wild VR

**BetterVR** by **Crementif** (and team) - a PC-VR mode for **The Legend of Zelda: Breath of the Wild**, achieved by hooking the **Cemu** Wii U emulator. Fully stereo-rendered 6DOF with roomscale, hands and arms, weapon wielding and motion-based combat.

> You provide your own copy of BotW for the Wii U (plus your Wii U keys). This installer ships **no game files and no keys**. It sets up the free, open-source Cemu emulator, the community graphic packs, and the free BetterVR launcher for you, then walks you through the manual configuration.

## What the installer does
1. Creates `C:\Games\Breath of the Wild VR` (with a `portable` folder so Cemu keeps its data there).
2. Downloads **Cemu 2.6** (Windows) and verifies it against a known-good SHA256 before extracting.
3. Pre-loads the **community graphic packs** (so FPS++ is ready to enable) into `graphicPacks`.
4. Downloads the latest **BetterVR_Launcher.exe** next to `Cemu.exe`.
5. Creates a `Breath of the Wild VR.lnk` desktop shortcut with a custom icon. Launch with **Start in VR** in the Hub or that shortcut.

## Requirements
- A gaming PC with a strong single-thread CPU (recent Intel i5 / Ryzen 5 or better). The CPU is the bottleneck, not the GPU.
- Your own BotW Wii U dump + Wii U keys.
- An OpenXR headset + runtime (Valve Index, Vive, Rift, Quest, WMR). Controller bindings are provided for **Oculus Touch**.
- Windows only (no Linux/Wine for now).

## Manual setup (the installer shows these as boxes)
**A. Your game:** the installer opens the install folder and starts Cemu. Add your own BotW dump + your Wii U keys - put `keys.txt` into `C:\Games\Breath of the Wild VR\portable`. Add BotW to Cemu's game list. BotW must be on a recent version, or Cemu shows an **update** message; install the update and DLC via **Cemu menu -> File -> Install game title, update or DLC** (Update 1.5.0 and the DLC both work).

**B. Cemu settings:** Cemu **2.6+**; Debug -> **Accurate Barriers (Vulkan)** **off**; Options -> General Settings -> Graphics: **Vulkan**, correct GPU, **VSync off**. The Community Graphic Packs are **pre-installed** by the setup (optional: use Options -> Graphic Packs -> **Download Community Graphic Packs** to refresh them).

**C. VR runtime:** set your OpenXR runtime (Virtual Desktop / SteamVR / Oculus). For Quest, prefer ALVR, Virtual Desktop or Steam Link over Meta Link (its frame interpolation hurts here).

**D. Enable FPS++ (required):** launch via **BetterVR_Launcher.exe**, then Options -> Graphic packs -> Breath of the Wild -> **Mods -> FPS++ = enabled** (the game **crashes without FPS++**). Recommended: VR Resolution Multiplier up for sharpness; AA = Nvidia FXAA or None at 2x+; FPS++ limit 120/144; anisotropic 16x; optional Clarity preset. Optional: download shader caches to avoid first-run stutter.

## Controls
Motion controls (Oculus Touch bindings provided). Open the in-game **BetterVR menu** any time to view and change controls/settings.

![BetterVR controller layout and equip gestures](botw-controls.jpg)

- Move with the left [[Stick]], rotate the camera with the right [[Stick]].
- Right [[Trigger]] uses weapon / bow / rune and throws bombs; [[A]] jumps and opens the paraglider.
- [[Grip]] grabs and interacts (long press = run). Hold [[X]] (left Touch) or [[A]] (Index) to open the BetterVR menu.
- Equip: move a [[Grip]] to your shoulder or hip to equip weapons, bows and runes (hold for the quick menu); hold [[R-Trigger]] to throw the held weapon.

![Swing, parry, whistle and magnesis gestures](botw-controls2.jpg)

- Attack with a swing or stab motion. Hold your shield up to defend; hold [[Trigger]] while defending to lock on; bash or reflect to parry.
- Whistle: press both [[Grip]] near your mouth. Magnesis: hold [[Grip]] and push / pull / up / down.
- Xbox / PS pad: long-press [[Start]] to open the menu, use the mouse to change settings.

## Known issues (from the mod author)
- Small chance of a black screen after exiting menus - restart the game if it happens.
- Climbing ladders: jump up the ladder and look at it; keep moving at the start when climbing down.
- Bombs/barrels throw at an odd angle.
- Comfort options like snap-turn / left-handed mode are not in yet.

## Credits
- Mod: **Crementif** (main dev) and team. MIT-licensed. https://github.com/Crementif/BotW-BetterVR
- Emulator: **Cemu** (cemu-project), MPL-2.0. https://github.com/cemu-project/Cemu

## Support Crementif

BetterVR is the result of thousands of hours of reverse-engineering across five years of development. If you enjoy it, consider sponsoring Crementif:
- https://github.com/sponsors/Crementif

>>> Climb anything, cook questionable meals, and chase the next shrine on the horizon.
