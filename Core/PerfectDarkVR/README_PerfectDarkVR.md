# Perfect Dark VR

A **VR fork** of the Perfect Dark decompilation port by **Alex-LeTux**, targeting PCVR. Play Rare's classic 2000 secret-agent shooter starring **Joanna Dark** in first-person, motion-controlled VR.

**Motion controls.** You must own and provide your own **Perfect Dark NTSC v1.1 (US) ROM in `.z64` format** - exactly this version works with the VR build. No ROM is downloaded or shipped.

## What you get
- The Perfect Dark campaign and split-screen modes, running in VR
- Widescreen, configurable FOV, 60 FPS (and higher) support
- The latest PCVR build, pulled straight from the official GitHub releases

## How to install
1. The installer downloads the newest **PCVR** release ZIP from GitHub (never the `.apk`, which is the Quest standalone build) and unpacks it to `C:\Games\Perfect Dark VR`.
2. It then asks you to **drag your Perfect Dark NTSC v1.1 `.z64` ROM** onto the window (a `.zip` containing the ROM works too - it is unpacked automatically). It copies the ROM into the `data` folder and renames it to exactly `pd.ntsc-final.z64`.
3. A desktop shortcut to `pd.x86_64.exe` is created.

If you skip the ROM step, drop your NTSC v1.1 `.z64` ROM into `C:\Games\Perfect Dark VR\data` yourself and rename it to `pd.ntsc-final.z64`.

## How to launch
Start your **VR runtime** first, then either:
- Use the Hub's **Start in VR** button (runs `pd.x86_64.exe`), or
- Use the desktop shortcut **Perfect Dark VR**.

## Controls
Motion controls (VR is a work in progress - confirm the current mapping in-game). Typical bindings, based on the port's Xbox scheme:
- **[[Right Trigger]]:** fire / accept
- **[[Left Trigger]]:** aim mode
- **[[A]]:** use / accept
- **[[X]]:** reload
- **[[B]]:** previous weapon
- **[[Y]]:** next weapon
- **[[Right Grip]]:** alt-fire mode
- **[[Left Grip]]:** radial menu
- **[[Stick]]:** move / crouch cycle

Bindings can also be rebound in `pd.ini`.

## Credits
- VR fork by **Alex-LeTux** - https://github.com/Alex-LeTux/perfect_dark_VR
- Based on the Perfect Dark decompilation port. Perfect Dark is a trademark of Microsoft / Rare. This is an unofficial, non-commercial fan project; no game ROM is provided.

## Support Alex-LeTux
If you enjoy this VR fork, consider supporting Alex-LeTux:
- https://ko-fi.com/alexletux

>>> Joanna Dark goes hands-on - dataDyne never saw it coming.
## Key points from updates
- Two-handed weapons are now aimed with **both hands**, and the off-hand is a
  real fist instead of a placeholder.
- Menu and HUD moved onto XR layers: the menu rides your left hand, the weapon
  HUD sits on the hands, and the remaining HUD floats about a metre in front
  of you - the distance is adjustable in the options.
- The crouch button can be switched off entirely.
- CamSpy, DrugSpy and BombSpy: the HUD is fully visible again, their crosshair
  sits right, and you can look around with your head while using them.
- Head rotation no longer drags the controller transform along, and the aiming
  reticle colours red or blue for enemy and friendly again.
