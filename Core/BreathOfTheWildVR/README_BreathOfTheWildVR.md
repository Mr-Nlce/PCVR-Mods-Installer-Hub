# Breath of the Wild VR

**BetterVR** by **Crementif** (and team) - a PC-VR mode for **The Legend of Zelda: Breath of the Wild**, achieved by hooking the **Cemu** Wii U emulator. Fully stereo-rendered 6DOF with roomscale, hands and arms, weapon wielding and motion-based combat.

> You provide your own copy of BotW for the Wii U (plus your Wii U keys). This installer ships **no game files and no keys**. It sets up the free, open-source Cemu emulator, the community graphic packs, and the free BetterVR launcher for you, then walks you through the manual configuration.

## New in 0.9.23

- **Loading-screen crashes are fixed** - teleporting, dying or leaving a shrine no longer
  drops you out of the game. If you are on 0.9.21 or 0.9.22, this is the update you want.
- **One Hit Per Swing**, on by default. A swing now damages each enemy once; at high frame
  rates multi-hit swings could rack up absurd damage. You can turn it off in the menu, and
  then each successive hit does less damage than the last.
- The swing bonus still stands: a straight swing with enough force beats the game's own
  damage, so good form matters more than ever.

**From 0.9.21 / 0.9.22:** the big frame-rate drop caused by bad camera collision checks is
gone, swings and stabs register far more reliably, the menu was rebuilt and sorted by where
you would look for a setting, and there is a seated mode that calibrates your height on
load. Helmets and caps are hidden in first person so they stop blocking your view.

## Optional: a faster Cemu

The mod author measures **up to 35% more frames** in Breath of the Wild with the Cemu 2.7
test builds, and BetterVR benefits directly. They are experimental - Cemu's own page
recommends the normal release unless you have a reason otherwise - so the installer stays
on the verified 2.6 and only offers you this at the end.

1. Open https://cemu.info/ActionBuilds.php and take the **cemu-bin-windows-x64** row from
   the **top block** - that is the newest build.
2. Open the downloaded `cemu-bin-windows-x64.zip` - it lands in `Downloads`.
3. Move the `Cemu.exe` out of it into `...\Games\Breath of the Wild VR`, overwriting the
   old one. Rename the old one first if you want a way back.

The file has to be called **`Cemu.exe`** exactly - rename it if the archive calls it
anything else. Nothing else in the folder changes, so if the build turns out worse, put
your old `Cemu.exe` back and you are where you were.

> The installer opens the page and both folders for you at the end, so you can do this in
> one go. It does not download the build itself: the address on that page carries a build
> number that changes every time.

## What the installer does
1. Creates `C:\Games\Breath of the Wild VR` (with a `portable` folder so Cemu keeps its data there).
2. Downloads **Cemu 2.6** (Windows) and verifies it against a known-good SHA256 before extracting.
3. Tries to pre-load the **community graphic packs** into `graphicPacks`. If that optional download fails, use Cemu's **Download Community Graphic Packs** button, then enable FPS++.
4. Downloads the latest **BetterVR_Launcher.exe** next to `Cemu.exe`.
5. Creates a `Breath of the Wild VR.lnk` desktop shortcut with a custom icon. Launch with **Start in VR** in the Hub or that shortcut.

## Requirements
- A gaming PC with a strong single-thread CPU (recent Intel i5 / Ryzen 5 or better). The CPU is the bottleneck, not the GPU.
- Your own BotW Wii U dump + Wii U keys.
- An OpenXR headset + runtime (Valve Index, Vive, Rift, Quest, WMR). Controller bindings are provided for **Oculus Touch**.
- Windows only (no Linux/Wine for now).

## Manual setup (the installer shows these as boxes)
**A. Your game:** the installer opens the install folder and starts Cemu. Add your own BotW dump + your Wii U keys - put `keys.txt` into `C:\Games\Breath of the Wild VR\portable`. Add BotW to Cemu's game list. BotW must be on a recent version, or Cemu shows an **update** message; install the update and DLC via **Cemu menu -> File -> Install game title, update or DLC** (Update 1.5.0 and the DLC both work).

**B. Cemu settings:** Cemu **2.6+**; Debug -> **Accurate Barriers (Vulkan)** **off**; Options -> General Settings -> Graphics: **Vulkan**, correct GPU, **VSync off**. Setup tries to preload the Community Graphic Packs. If that optional download was skipped or failed, use Options -> Graphic Packs -> **Download Community Graphic Packs**; the same button refreshes existing packs.

**C. VR runtime:** set your OpenXR runtime (Virtual Desktop / SteamVR / Oculus). For Quest, prefer ALVR, Virtual Desktop or Steam Link over Meta Link (its frame interpolation hurts here).

**D. Enable FPS++ (required):** launch via **BetterVR_Launcher.exe**, then Options -> Graphic packs -> Breath of the Wild -> **Mods -> FPS++ = enabled** (the game **crashes without FPS++**). Recommended: VR Resolution Multiplier up for sharpness; AA = Nvidia FXAA or None at 2x+; FPS++ limit 120/144; anisotropic 16x; optional Clarity preset. Optional: download shader caches to avoid first-run stutter.

## Controls
Motion controls (Oculus Touch bindings provided). Open the in-game **BetterVR menu** any time to view and change controls/settings.

![BetterVR controller layout and equip gestures](botw-controls.jpg)

- Move with the left [[Stick]], rotate the camera with the right [[Stick]].
- Right [[Trigger]] uses weapon / bow / rune and throws bombs; [[A]] jumps and opens the paraglider.
- [[Grip]] grabs and interacts (long press = run). Hold [[X]] (left Touch) or [[A]] (Index) to open the BetterVR menu.
- **First person is the normal mode; third person is the optional one.** If you end up looking at Link from behind, switch back in the BetterVR menu - same menu, hold [[X]] / [[A]].
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

## Key points from updates
- **Physical bow drawing:** hold the arrow near the string, press the trigger
  and pull back. Your hand and the arrow follow the draw animation, and the
  bow arc only appears while you are (close to) drawing.
- The mod warns you when **FPS++ is not enabled** - that combination crashed
  the game before. It also forces *accurate pipeline barriers* off for you,
  so that is one setting less to get right.
- Quality options in the *Graphics (For BetterVR)* pack work again:
  **Normal** keeps the game's own effects, **Low** drops god rays (~4% more
  FPS), **Very Low** drops shadows as well (~10%). Your FPS may not move at
  all - a headset halves it once you cannot hold the full refresh rate.
- Camera fixes: no more clipping when climbing overhangs or ceilings, and no
  unwanted rotation when climbing onto walls (cutscenes and dialogue aside).
- Model, hands and equipment no longer lag behind while riding or
  shield-surfing, and horse riding height follows the player-height option
  the right way round.
- First-person now hides Link's hair too, not just his face.
- Throwing works in third person, and you can drop your right-hand weapon.
- Pico Ultra and Pico Neo 3 controllers are supported.

>>> Climb anything, cook questionable meals, and chase the next shrine on the horizon.
