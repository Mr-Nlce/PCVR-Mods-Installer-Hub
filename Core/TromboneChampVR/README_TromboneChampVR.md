# Trombone Champ VR - BaboonVR

**Mod:** BaboonVR 0.3.0 by Raicuparta (final - no further updates)
**Base game:** Trombone Champ (Steam App 1059990)
**Controls:** Motion controllers
**Power tier:** Basic

BaboonVR projects the Trombone Champ screen in front of you and lets you play
the trombone with your hands. A silly meme mod for a silly meme game.

## How the install works

1. **Steam Console depot download.** The mod only runs on an older build, so
   the installer pins the game to a known-good Steam manifest via
   `download_depot 1059990 1059991 8892575399251592659` (with an automatic
   DepotDownloader fallback).
2. **Move to a stable folder** (`C:\Games\Trombone Champ VR` by default) so a
   future Steam update can't overwrite it. Your normal install stays untouched.
3. **steam_appid.txt** is dropped next to the EXE so it launches directly.
4. **You add the mod.** BaboonVR is on itch.io and can't be auto-downloaded.
   The installer opens the page; you download `baboon-vr-win.zip` and point the
   installer at it. The BepInEx files inside are installed directly - the
   bundled `RaiManager.exe` is not used.
5. **Desktop shortcut** to `TromboneChamp.exe`.

You need to own Trombone Champ on Steam for the depot download.

## Launching

1. Start the **Steam** client.
2. Start **SteamVR**.
3. Launch with **Start in VR** in the Hub, or the **Trombone Champ VR** desktop shortcut.

## Controls

The trombone is held in your hands - move them to slide and aim, and press a
trigger or grip to toot.

- [[Trigger]] or [[Grip]] - Toot (either hand)
- [[Menu]] - Menu

## Troubleshooting

- **Game runs flat / no headset image:** start SteamVR before launching. Check
  that `BepInEx\plugins\BaboonVr\com.raicuparta.baboon-vr.dll` and `winhttp.dll`
  are in the game folder.
- **Steam tries to reinstall the game:** make sure `steam_appid.txt` (contents
  1059990) sits next to `TromboneChamp.exe`.
- **Mod ZIP not found:** re-run the installer and choose P to type the full
  path to `baboon-vr-win.zip`.
- **Manual mod install:** extract `baboon-vr-win.zip`, then copy `Mod\BepInEx`
  into the game folder and everything in `Mod\CopyToGame\` into the game root.
