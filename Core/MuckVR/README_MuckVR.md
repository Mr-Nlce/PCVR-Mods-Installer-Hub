# Muck VR

**MuckVR** by **Elektroney** adds a stereo VR view to Muck through SteamVR.

> **WIP alpha.** The current public build is intended for gamepad play. Motion controls are planned, not a finished feature. Body IK is unfinished and held-item offsets are incorrect.

## Controls

Start SteamVR before launching Muck. Use a gamepad for normal play. **Virtual Desktop Gamepad Mode can have input problems** with this build; if the menu or game does not respond, click the Muck desktop window once and use keyboard and mouse instead.

The experimental hands shown during development do not yet provide a finished motion-control scheme in the public package.

## Setup and launch

The Hub downloads the current Thunderstore releases of MuckVR and its exact `BepInExPack_Muck` dependency. Start with **Start in VR** in the Hub or through Steam.

The installer backs up the original `Muck_Data/globalgamemanagers` before placing the mod's replacement. That file is why the Hub does not offer a casual loader-only Flat / VR switch for this title.

## Update and deprecated status

The Hub compares the exact installed `Elektroney-MuckVR` version with Thunderstore. If Thunderstore marks it deprecated, setup says so prominently; that is the signal to test against the archived current depot before recommending a pinned build.

## Troubleshooting

- Start SteamVR before Muck.
- If Virtual Desktop Gamepad Mode does not respond, focus the Muck desktop window and use keyboard and mouse.
- Body IK is not final.
- Item offsets are currently wrong.
- Keep keyboard and mouse available as the reliable fallback while controller support is still being developed.
- If a game update breaks loading, use **Uninstall now** to restore the exact backed-up base-game file, then verify Muck in Steam.

## Uninstall

**Uninstall now** checks every owned file by SHA-256, restores the original `globalgamemanagers`, removes only unchanged MuckVR files, and leaves shared BepInEx in place. Any file changed after installation is preserved and reported.

## Credits

- MuckVR by Elektroney: https://thunderstore.io/c/muck/p/Elektroney/MuckVR/
- BepInExPack Muck: https://thunderstore.io/c/muck/p/BepInEx/BepInExPack_Muck/
