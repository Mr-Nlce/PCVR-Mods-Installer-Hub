# Richard Burns Rally VR (RBRvr)

Brings OpenVR/OpenXR support to the 2004 rally sim **Richard Burns Rally**
via the free community **RBRvr** mod by Kegetys. From the main menu
onward the game runs in the headset, at high frame rates (90-120 FPS)
even on mid-range PCs.

## What the installer does

- Asks you to drag your existing `RichardBurnsRally_SSE.exe` onto the
  window so it learns the exact install folder.
- Downloads the **RBRvr** mod from https://junk.kegetys.fi/RBRvr16.zip
  at install time (no game files are bundled).
- Copies the mod files (`d3d9.dll`, `openvr_api.dll`,
  `Plugins\RBRvrConfig.dll`, `rbrvr.cfg`, redists) into your game folder.
- Creates a desktop shortcut **Richard Burns Rally VR**.

## Requirements

- An existing, working install of **Richard Burns Rally** (you provide
  your own copy - it is not sold on Steam/GOG/Epic).
- A PC VR headset with OpenVR (SteamVR) running.

## Enabling motion controllers

The game is in the headset from the main menu. To steer with your motion
controllers (Vivedrive):

1. In game: **Options -> Plugins -> RBRvr Configuration -> Vivedrive**
2. Press the **[[Right Arrow]]** key, then **[[Enter]]**, then leave
   the menu.

## Controls

- Steer with your **motion controllers** as a virtual wheel (Vivedrive),
  or use a wheel / gamepad / keyboard as usual.
- Toggle the windshield hider: [[Numpad *]] (hides the flat
  windshield texture that does not render right in stereo).
- Render scale, gamma and co-driver mode are configured in the in-game
  RBRvr menu or by editing `rbrvr.cfg`.

## Mod notes (from Kegetys)

- Default **render scale is 200%**. If you also raise the SteamVR pixel
  density you may see performance problems - lower the render scale in
  the in-game menu or in `rbrvr.cfg`.
- **Alt co-driver mode**: the driver wears the headset (`codriverMode=2`).
- **Gamma controls** in the cfg default to slightly increased contrast.
- **Windshield hider** (numpad `*`): hides parts of the windshield, which
  is a flat mapped texture that does not look right with stereo
  rendering (and is too dark on many mod cars).
- **Clip-plane tweaks** fix distant terrain being clipped on some tracks
  and improve in-car clipping. In-car replay views now render in VR.

## Mod info

- RBRvr mods page: https://www.kegetys.fi/category/gaming/rbrmods/

## Credits

- **RBRvr** mod by **Kegetys** - https://www.kegetys.fi/category/gaming/rbrmods/
- Richard Burns Rally (2004) by Warthog / Gracious Gaming.

>>> Trust the pace notes, commit to the corner, and keep it pinned on the gravel.
