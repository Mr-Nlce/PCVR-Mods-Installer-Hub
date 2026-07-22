# Portal 2 VR

**Mod:** Portal2VR Roomscale v0.2.2
**Author:** Spencer0187 (based on Portal2VR by Gistix)
**More info:** https://github.com/Spencer0187/portal2vr-roomscale

## What this installer does

1. Reminds you to prepare a clean Portal 2 install
2. Downloads Portal2VR Roomscale v0.2.2 directly from GitHub
3. Copies the VR mod files into your Portal 2 folder (overwriting game files)
4. Copies the required Steam launch parameters to your clipboard
5. Opens Steam game properties so you can paste them in

## Before you install

- Back up your Portal 2 save files if you want to keep them
- Unsubscribe from any Steam Workshop mods
- Launch Portal 2 once to the main menu, then quit
- Disable the Steam Overlay for Portal 2 (Properties -> General tab, top)

## Steam Launch Parameters

```
-insecure -window -novid +mat_motion_blur_percent_of_screen_max 0 +mat_queue_mode 0 +mat_vsync 0 +mat_antialias 0 +mat_grain_scale_override 0 +snd_surround_speakers 5
```

## First launch notes

- The installer builds the sound cache for you during setup. If you ever need to redo it (e.g. after a Portal 2 update), the cache **must be built with VR disabled**, because the mod stops Portal 2 from reaching the main menu:
  1. In `<Portal 2>\bin`, rename `openvr_api.dll` to `openvr_api.dll-` (add a dash at the end)
  2. Start Portal 2, wait for the **main menu**, then quit
  3. Double-click `Fix-Sound-issue-VR` in your Portal 2 folder (points at the mod's `UpdateSoundCache.cmd`)
  4. Rename `openvr_api.dll-` back to `openvr_api.dll`
- For normal VR play: start SteamVR **before** launching Portal 2, then launch with **Start in VR** in the Hub or **from inside SteamVR**

## Mod settings

- Edit `<Portal 2>\VR\config.txt` for mod settings
- If portal rotation makes you motion-sick, change:
  ```
  CameraUprightRecoverySpeed=0.04  ->  CameraUprightRecoverySpeed=100
  ```
- Play flat for a while without uninstalling: in `<Portal 2>\bin`, add a `-` to the end of `openvr_api.dll` to turn VR off; remove the `-` to turn it back on

## Credits

- Portal2VR Mod by **Gistix**
- Roomscale / motion controls by **Spencer0187**
- Virtual Surround sound addon by **ThreeDeeJay**
- Replaced Portal Gun model by **SpiritedSpy**
- Camera pitch/roll adjustment by **vittorioromeo**
- `sp_a2_bts4` crash workaround fix by **pedesh**

>>> The cake is a lie. The VR is real.
