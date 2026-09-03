# Retrowave 2 VR

A **preconfigured UUVR setup** - Raicuparta's Universal Unity VR mod, already
tuned for this game by **Jean-Francois**. Nothing here was compiled
for Retrowave 2 specifically; the work is in the configuration.

Neon roads at night, and a cockpit you can lean into.

> **You need a Discord account, and you must JOIN the server.** The download is a
> message attachment in the Flat2VR Modding server - without joining, the link
> shows you nothing. The installer opens both the invite and the post for you.

## THE TWO KEYS YOU ALWAYS NEED

| | |
|---|---|
| **[[F3]]** | **turns VR on.** The game starts FLAT - this is the key that puts it in your headset |
| **[[F5]]** | **shows the game's UI in VR.** Without it the menus stay on the flat screen |

Both are needed every session. UUVR does not switch itself on and does not
remember that you did.

1. **Start your VR runtime FIRST** - before the game. If it is not running when
   the game starts, the key does nothing.
2. Launch **Retrowave 2 as usual, from Steam.** No special launcher: the mod's
   `winhttp.dll` loads with the game and brings BepInEx and UUVR with it.
3. Once you are in the game, press **[[F3]]**, then **[[F5]]**.

> **If F3 does nothing:** the runtime was not running before the game started.
> Close the game, start the runtime, launch again.

> **If nothing at all happens - no BepInEx window, no log, no reaction:** then
> BepInEx never loaded. Check that **`doorstop_config.ini`** sits next to
> `Retrowave 2.exe`. The mod package does not include it, and `winhttp.dll`
> without it does nothing at all - the installer writes one for you, so if it is
> missing, run the installer again.

**UUVR is a viewing mod.** It gives you stereoscopic depth and head tracking -
you still play with the gamepad, exactly as the controls below describe. There
are no VR hands, and that is by design.

Turn **motion blur off** in the game's settings; it ghosts badly in stereo.

## What the installer does
1. Finds your Steam copy of Retrowave 2 (this game is Steam-only - no Epic, GOG
   or Microsoft Store edition exists).
2. Opens the Discord invite and the post with the download.
3. Picks the archive up from your **Downloads** folder - it **opens every zip
   there and takes the one that really contains `Uuvr.dll`**, so a renamed file
   or a neighbouring download cannot be mistaken for it.
4. Copies the mod into the game folder.

**Two things in the archive are deliberately left behind:** `BepInEx\LogOutput.log`
and `BepInEx\cache\`. Those are runtime leftovers from the author's own machine -
the cache in particular is built from one specific install and is rebuilt on your
first start anyway.

## Playing

**Use a gamepad.**

| | |
|---|---|
| [[Y]] | switch the view while driving - **including the steering wheel view** |
| Arrow keys | the **menus** take the keyboard, not the pad - the game has no controller support there |

> **Xbox pads are often not detected over Bluetooth.** Plug the pad in with a USB
> cable and it works.

## Uninstalling
Delete the `BepInEx` folder and `winhttp.dll` from the game folder. That is the
whole mod - no original game file was changed, so the flat game keeps working.

## Credits
**UUVR** is by **Raicuparta**. The configuration for this game is by
**Jean-Francois**, who posted it in the Flat2VR Modding Discord. **Retrowave 2**
is by its own developer, and this mod is unofficial.
