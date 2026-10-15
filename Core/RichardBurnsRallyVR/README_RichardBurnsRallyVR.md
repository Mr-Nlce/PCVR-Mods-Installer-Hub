# Richard Burns Rally VR (RBRvr)

## About the Game

Brings OpenVR support to the 2004 rally sim **Richard Burns Rally**
via the free community **RBRvr** mod by Kegetys. The mod supports headset
driving, seat adjustment and ViveDrive steering with motion controllers.

## What the installer does

- Asks you to drag your existing `RichardBurnsRally_SSE.exe` onto the
  window so it learns the exact install folder.
- Downloads the **RBRvr** mod from https://junk.kegetys.fi/RBRvr16.zip
  at install time (no game files are bundled).
- Verifies the required mod files before changing the game, then installs
  the publisher package with an ownership list and backups of replaced originals.
- Preserves an edited `rbrvr.cfg` during updates. A failed copy restores the
  previous game and VR files.
- Creates a desktop shortcut **Richard Burns Rally VR**. Launch with **Start in VR** in the Hub or that shortcut.

## Requirements

- Richard Burns Rally **v1.02 with `RichardBurnsRally_SSE.exe`**. You provide
  your own game copy; the Hub downloads no game files.
- An OpenVR headset/runtime such as SteamVR. Other runtime paths have not
  been confirmed here.

## Enabling motion controllers

The game is in the headset from the main menu. To steer with your motion
controllers (Vivedrive):

1. In game: **Options -> Plugins -> RBRvr Configuration -> Vivedrive**
2. Press the **[[Right Arrow]]** key, then **[[Enter]]**, then leave
   the menu.

## Controls

| Button | Action |
|---|---|
| [[Vive Touchpad]] | Navigate menus; change gears while driving with ViveDrive. |
| [[Vive Trigger]] | Select a menu item. |
| [[Vive Menu Button]] | Go back in menus; pause while driving. |
| [[Vive Grip]] twice | Recenter the seated position. |
| Hold [[Vive Grip]] | Adjust the seat position. |
| [[Right Trigger]] / [[Left Trigger]] | Throttle / brake with ViveDrive. |
| [[Vive Controllers]] | Hold both like a steering wheel and rotate to steer with ViveDrive. |
| [[Wheel]] / [[Gamepad]] / [[Keyboard]] | Use the base game's normal steering controls. |
| [[Numpad Arrow Keys]] / [[Numpad +]] / [[Numpad -]] | Adjust the seat; switch Num Lock on first. |
| [[Numpad Insert]] or [[Left Shift]] + [[Left Ctrl]] | Recenter the seated position. |
| [[Numpad *]] | Toggle the windshield hider. |
| [[Numpad /]] | Toggle debug information. |
| [[1]] | Switch to the driver camera if the game opens in another view. |
| [[Right Arrow]], then [[Enter]] | Enable Vivedrive in the RBRvr plugin menu. |

Render scale, gamma and co-driver mode are configured in the in-game RBRvr
menu or by editing `rbrvr.cfg`.

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
- The default camera may need to be changed to the in-car driver view; save
  the game profile after selecting it. Co-driver mode can show wrong cameras.
- Disable TrackIR while using RBRvr to avoid competing head tracking.

## Troubleshooting

- If VR does not start, confirm **v1.02 SSE**, try the unmodified game without
  other plugins, install the **32-bit DirectX 9.0c** runtime and try windowed
  mode (`Fullscreen = false` in `RichardBurnsRally.ini`).
- If other plugins cause crashes, test without their hooks. The publisher
  suggests Sysinternals DebugView for RBRvr debug output.
- If `steeringRotation` has no effect, check for an older
  `misc/LM_Driver.ini`. RBRvr will not replace a file it did not create.
- If edits to `rbrvr.cfg` seem ignored under Program Files, check Windows'
  per-user VirtualStore copy. RBRvr may be reading that copy instead.

The publisher permits free redistribution only of an unmodified package with
its README, and limits use to personal entertainment. The Hub downloads the
publisher archive and does not bundle it.

## Mod info

- RBRvr mods page: https://www.kegetys.fi/category/gaming/rbrmods/

## Credits

- **RBRvr** mod by **Kegetys** - https://www.kegetys.fi/category/gaming/rbrmods/
- Richard Burns Rally (2004) by Warthog / Gracious Gaming.

>>> Trust the pace notes, commit to the corner, and keep it pinned on the gravel.
