# Legend of Zelda: Ocarina of Time VR Installer

Automated installer for **Shipwright-VR** by ShinyWindow - an OpenVR stereo-rendering mod for **Ship of Harkinian**, the PC port of **The Legend of Zelda: Ocarina of Time** (Nintendo 64, 1998). Ocarina of Time is a groundbreaking action-adventure and, per Metacritic, one of the highest-rated video games of all time - and this puts its 3D world into the headset with motion-controller input.

> **Alpha.** The mod renders the 3D geometry in VR; **menus, text and HUD icons stay on the flat game window** and do not line up in the headset yet. An internal framebuffer that removes the required window and MSAA settings is planned by the modder.

## What it does
- Downloads the newest Shipwright-VR release from GitHub, so the Hub can flag updates and re-running the installer updates in place (saves, settings and your generated game archives are kept).
- Installs to `C:\Games\Ocarina of Time VR` by default - you can pick any folder; no admin rights or UAC prompt needed at the default location.
- Lets you drop in your ROM right away, or leave it to `soh.exe`, which asks for the ROM on its first start.
- Creates an **Ocarina of Time VR** desktop shortcut.

## You provide the ROM
Nothing from Nintendo is included or downloaded. You supply your own dump, and it never leaves your PC.

**What exactly is needed:**

| | |
|---|---|
| Platform | **Nintendo 64** - not GameCube, not 3DS, not Virtual Console |
| File | a `.z64` ROM dump (big-endian), 32 MB / 33,554,432 bytes |
| Game | **Ocarina of Time** or **Ocarina of Time: Master Quest** - both work |
| Region | several regions and revisions are supported, so check yours rather than guessing |

Verify your dump before you start - this checker is the authoritative answer on whether a specific file is supported:

https://ship.equipment/

**Where to put it:** place the `.z64` in the same folder as `soh.exe` (the install folder this Hub created). If `soh.exe` finds no supported ROM there, it asks you to pick one on first launch.

**What happens then:** on first launch `soh.exe` extracts the copyrighted assets out of your ROM into an `.otr` archive - watch for **OTR Successfully Generated**. From then on the game runs from that archive and the ROM is no longer read. Regular Ocarina of Time produces `oot.otr`; Master Quest produces `oot-mq.otr`.

## Requirements
- **Windows 10/11 64-bit**
- **SteamVR** - Shipwright-VR is an OpenVR mod, so SteamVR is the runtime
- Your own **Nintendo 64 Ocarina of Time ROM**: a `.z64` dump, 32 MB. Ocarina of Time or Master Quest both work. Check yours at https://ship.equipment/ before you start.

## Required in-game setup
Without these the headset shows nothing or a broken image:

- **Graphics backend: DirectX11** (the Windows default) - OpenGL does not hook
- **Window aspect ratio: 4:3**
- **MSAA: disabled**
- **Internal Resolution: 100%**
- Do **not** toggle **Enable advanced settings** while playing

To size the window up without black regions: temporarily enable advanced settings under Settings > Graphics, set the aspect ratio to 4:3, adjust the window until the image fills it, then disable advanced settings again.

## The in-game menu (settings, VR input, cheats)
Ship of Harkinian keeps everything in its own custom menu. To open it in VR: **lift the headset slightly, click the game window on your desktop, and press [[Esc]]** (or [[Start]] + [[Select]] on a controller). Settings, VR controller input, quality-of-life toggles, HUD options and cheats all live there.

- **Remove letterboxing (black bars):** Settings > Enhancements > Graphics tab > set Aspect Ratio / Widescreen to fill the screen, and disable **Force Letterbox** if it is on.
- **Hide HUD elements:** Enhancements menu > Cosmetics Editor > HUD Placement - switch off individual elements or use the master HUD toggle.

## How to play
1. Start **SteamVR**.
2. Launch with **Start in VR** in the Hub, or use the **Ocarina of Time VR** desktop shortcut. Both run `soh.exe`.
3. On the very first start the game processes your ROM into its `.otr` archive, then Hyrule loads.

## Controls (motion controllers)
- [[L-Stick]] move
- [[R-Stick]] camera
- Buttons follow the gamepad layout of Ship of Harkinian; the exact VR controller bindings are configurable in the in-game menu under **VR controller input**
- **Slingshot aiming:** the pellets follow your **right controller**, not your head - aim with the right hand. Holding both controllers together like an actual slingshot makes it feel natural.

## Known alpha limitations
- **Indoor pre-rendered areas do not render properly.** Rooms that the original game draws with a pre-rendered backdrop come out broken in VR, so you have to feel your way to the exit. This is the mod's biggest open issue - expect it in houses, shops and similar interiors.
- Menus, text and HUD icons render on the flat window only and do not line up in the headset
- The required window settings (4:3, MSAA off, 100% internal resolution) stay mandatory until the planned internal framebuffer lands
- Switching the graphics backend away from DirectX11 breaks the VR output

## HD texture pack (optional)
The installer can add the **OoT Reloaded 4K** HD texture pack (from evilgames.eu) at the end of setup. It's a large download (**~4 GB**), so both the download and the extraction show a progress percentage. You can skip it and add it any time by re-running the installer.

What it does: the pack's `.o2r` file is placed in the game's `mods` folder, and Ship of Harkinian loads it as *alternate assets*.

Turn it on in-game:
- Press [[Esc]] to open the menu (lift the headset, click the flat game window first).
- Go to **Enhancements > Graphics / Mods** and tick **Use alternate assets**.
- Press [[Tab]] during play to toggle the custom textures on/off.

Manual install (if you grabbed the pack yourself): extract `oot-reloaded-v11.0.0-soh-o2r-4k.7z` and drop the `OoT_Reloaded_v11.0.0_4K.o2r` inside it into your game's `mods` folder, then use the same in-game steps.

## Credits
- **Shipwright-VR** by ShinyWindow
- **Ship of Harkinian** by the Harbour Masters team, built on libultraship and the OoT decompilation project
- The Legend of Zelda and Ocarina of Time are Nintendo trademarks; this project is not affiliated with Nintendo.

Project page:

https://github.com/ShinyWindow/Shipwright-VR
## Key points from updates
- **Physical melee combat** (v1.3) - your sword is a real object: swing speed
  decides the damage tier, the blade collides with enemies, walls and floor,
  and the shield blocks by geometry. It is **OFF by default**; switch it on
  under *VR Settings / Physical Combat*. The old button combat stays available.
- **Item selector** in the style of Half-Life: Alyx - hold the selector (right
  stick click by default) and a compass of your equipped items appears at your
  hand. Up = sword and shield, left/right/down = your three C items, release
  without moving = empty hands. Optionally the trigger then uses whatever you
  hold: draw the bow and squeeze to nock, release to loose.
- Motion aiming for slingshot, bow and hookshot; the firing angle is
  adjustable in the VR settings.
- **F9 swaps between VR and flat play** mid-game, and taking the headset off
  can switch you out automatically.
- World scale calibrates to your real height, and child/adult swaps rescale by
  themselves. Recentering recalibrates.
- Recommended: enable *Disable 2D Pre-Rendered Scenes* and *Disable Fixed
  Camera* under Enhancements/Graphics/Mods, and *Hide Link's Body* under VR
  Settings/Gameplay.
