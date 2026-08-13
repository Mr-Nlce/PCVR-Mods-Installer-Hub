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

**And these four, which is what makes it play properly in the headset:**

| Where | Setting | |
|---|---|---|
| Enhancements > Graphics > Mods | **Disable 2D Pre-Rendered Scenes** | on |
| Enhancements > Graphics > Mods | **Disable Fixed Camera** | on |
| VR Settings > Gameplay | **Hide Link's Body** | on |
| VR Settings > Physical Combat | **Physical Combat** | on |

The menu layout differs between Ship of Harkinian builds - go by the setting
names, not the paths.

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
- **Indoor pre-rendered areas do not render properly.** Rooms that the original game draws with a pre-rendered backdrop come out broken in VR, so you have to feel your way to the exit. This is the mod's biggest open issue - expect it in houses, shops and similar interiors. The optional **Djipi's 3DS Experience** pack (see below) replaces those scenes with real 3D geometry and is the practical fix.
- Menus, text and HUD icons render on the flat window only and do not line up in the headset
- The required window settings (4:3, MSAA off, 100% internal resolution) stay mandatory until the planned internal framebuffer lands
- Switching the graphics backend away from DirectX11 breaks the VR output

## HD texture pack (optional)
The installer can add the **OoT Reloaded 4K** HD texture pack (from evilgames.eu) at the end of setup. It's a large download (**~4 GB**), so both the download and the extraction show a progress percentage. You can skip it and add it any time by re-running the installer.

What it does: the pack's `.o2r` file is placed in the game's `mods` folder. Current Ship of Harkinian builds load whatever is in there by themselves - older guides tell you to tick *Use alternate assets* first, but that entry is gone.

In-game:
- Nothing to switch on - the pack is active from the next start.
- Press [[Tab]] during play to toggle the custom textures on/off.

Manual install (if you grabbed the pack yourself): extract `oot-reloaded-v11.0.0-soh-o2r-4k.7z` and drop the `OoT_Reloaded_v11.0.0_4K.o2r` inside it into your game's `mods` folder, then use the same in-game steps.

## 3D backgrounds - Djipi's 3DS Experience (optional, but the fix for VR)
Castle Town and many interiors are drawn as flat pre-rendered backdrops. In VR they stand in front of you and block the view. **Djipi's 3DS Experience** ships real 3D geometry for those scenes, so the backdrops can be switched off and the rooms render normally - this is what makes those areas playable in the headset.

The installer offers it at the end of setup. The download runs in your browser (`djipi_s_3ds_experience_-_final_pack.zip`, about **500 MB**); the source limits the speed, so roughly **20 minutes** is normal. When it has finished, the installer picks the file up from your Downloads folder, or you can drag it onto the installer window.

**Two looks, pick one when asked:**

| | What lands in `mods\` | Combine with OoT Reloaded 4K? |
|---|---|---|
| **[2] Authentic Ocarina of Time - recommended** | only `Djipi's 3DE - 26 Background 3DS.o2r` and `Djipi's 3DE - 27 Background Textures.o2r` | yes - this is the pairing |
| **[1] 3DS look** | the whole pack - 3DS textures, NPCs, objects and the 3D backgrounds | no - it is a different art style for the same surfaces |

Both include the 3D backgrounds, which is the part VR needs. Everything else in
the full pack is cosmetic.

> **Take [2] unless you specifically want the 3DS art.** The full pack's
> character and world replacements have been seen to **crash cutscenes** -
> traced to Saria's model, and switching that one piece off stopped the crash.
> That is the pack, not the VR mod. If a cutscene crashes on you and you took
> [1], remove the full pack and install the backgrounds instead.

**Required in-game, otherwise nothing changes:** press [[Esc]], then

1. Turn **ON** **Disable 2D Pre-Rendered Scenes** (older builds: *Disable 2D Pre-rendered Backgrounds*). **The name reads backwards, the setting is right:** it switches the FLAT backdrops off so the pack's 3D rooms can show. The game's own tooltip says it plainly - *"Enable this when using a mod that implements 3D backdrops for these areas."*
2. It applies on the next **scene change** - leave the area and come back. A restart works too.

Also recommended with this pack: **Disable Grotto Fixed Rotation** and **Enable 3D dropped items / projectiles**. Both sit under *Enhancements > Graphics* in older builds; newer menus moved things around, so go by the setting name rather than the path.

**If the game crashes:** Enhancements > Fixes > leave **Out of Bounds Textures** unchecked. If it still crashes with cosmetic mods in play, drop the custom Link cosmetics.

**If Link's face looks wrong** next to another player model, delete `Djipi's 3DE - 02 Link's Textures (Delete if using a custom player model).o2r` from `mods\`.

**Skilar's Art Plus Link** sits in the same zip (folder `0001`) and is deliberately *not* installed: it changes Link himself, and custom Link cosmetics are the first suspect when Ship of Harkinian crashes. Copy those `.o2r` files into `mods\` yourself if you want them.

Mod page: https://gamebanana.com/mods/477979

## Credits
- **Shipwright-VR** by ShinyWindow
- **Ship of Harkinian** by the Harbour Masters team, built on libultraship and the OoT decompilation project
- The Legend of Zelda and Ocarina of Time are Nintendo trademarks; this project is not affiliated with Nintendo.

Project page:

https://github.com/ShinyWindow/Shipwright-VR
## Key points from updates
- **Physical melee combat** - your sword is a real object: swing speed
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
  Camera*, and *Hide Link's Body* under VR Settings/Gameplay. That first one
  belongs **on** together with Djipi's 3DS Experience - it takes the flat
  backdrops away so the pack's 3D rooms appear. Without a 3D-backdrop pack
  those areas end up with no background at all, which is the only reason to
  leave it off.
