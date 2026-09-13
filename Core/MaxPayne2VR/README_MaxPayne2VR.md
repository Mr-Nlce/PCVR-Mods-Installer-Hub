# Max Payne 2 VR

**MaxPayne2VR** by **betotron** adds true stereo rendering, OpenXR, roomscale and motion controls to Max Payne 2.

> **WIP beta.** The full game is playable, but this is still being developed. Virtual Desktop is the only runtime currently confirmed by the author.

## Runtime and launch

Start **Virtual Desktop** first, then use **Start in VR** in the Hub or launch Max Payne 2 through Steam/GOG as usual. SteamVR is not supported by the 32-bit runtime used by this build; Meta Link did not work in the author's tests.

The first launch can remain flat for roughly 10-30 seconds while VR starts. Follow the T-pose calibration prompt before playing.

## Controls

| Input | Action |
|---|---|
| [[Right Trigger]] | Fire or confirm |
| [[Right Grip]] | Use |
| [[A]] | Reload |
| [[B]] | Jump |
| [[Right Stick Click]] | Painkiller |
| [[Left Stick]] | Move |
| [[Left Grip]] | Melee |
| [[X]] | Bullet time |
| [[Y]] | Weapon selector |
| [[Menu]] | Escape / pause |
| [[M]] / [[N]] | Adjust height |
| [[Comma]] / [[Period]] | Adjust IPD |

## Configuration

`MaxPayne2VR.ini` sits beside `MaxPayne2.exe`. The installer creates it only when absent; updates and **Uninstall now** preserve your calibration and comfort values.

## Playing flat

Use the **Flat / VR switch** on this page. It parks only `winmm.dll` as `winmm.dll.pcvrhub_off`; one click restores VR. The DXVK files remain installed, but the VR hook is not loaded.

## Updates

This project publishes its current build directly on GitHub's `main` branch instead of using Releases. The Hub records the exact commit timestamp and compares it with the current branch head, so a new commit produces the normal Update state without pretending a release tag exists.

## Known limitations

- Performance and compatibility are still being refined.
- Virtual Desktop is the confirmed path; other runtimes may fail.
- Expect a short flat delay before the headset activates.

## Uninstall

Before replacing an existing file, the installer copies the original into the dedicated hidden `.pcvrhub_maxpayne2vr_backup` subfolder inside the game folder. Its ownership manifest separately records every file added by the VR mod.

**Uninstall now** verifies each owned binary, restores pre-existing originals from that recovery folder, and preserves files changed after installation. `MaxPayne2VR.ini` is intentionally retained.

## Credits

- MaxPayne2VR by betotron: https://github.com/betotron/MaxPayne2VR-release
