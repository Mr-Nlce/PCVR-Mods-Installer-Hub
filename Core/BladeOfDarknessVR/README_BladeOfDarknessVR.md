# Blade of Darkness VR

## About the Game

Blade of Darkness is a demanding fantasy action game with four playable heroes, weapon-specific combat and an expedition against the forces of Chaos. This entry is for the 2021 Steam DirectX 11 remaster. The 2001 original is a different build and is not supported by this VR mod.

## The VR mod

BladeVR v1.6 by Efraim2704 adds stereoscopic 3D and six-degree head tracking through SteamVR/OpenVR. The normal adventure stays a gamepad or keyboard-and-mouse game. VR motion controllers manipulate the optional diorama, where the level becomes a miniature world on a table; they are not a replacement for the game's combat controls. Menus and HUD appear on a virtual screen. A Quest 2 over SteamVR is the publisher-tested headset. Other headsets are not proven by this Hub.

The mod hooks the game's DirectX 11 renderer with `dxgi.dll`. The official archive also contains `BladeVR.dll` and `openvr_api.dll`; all three belong beside `bin\bin\Blade.exe`. The Hub checks the actual game EXE, downloads a matching stable GitHub release, backs up name collisions, places all three DLLs and records the version only after their presence is verified. Saves and unrelated game files stay in place. See the publisher's [releases](https://github.com/Efraim2704/BladeOfDarknessVR/releases) and [complete documentation](https://github.com/Efraim2704/BladeOfDarknessVR).

## Before starting

1. Install the 2021 Steam remaster and finish its own first-run setup.
2. Run Get Installer in the Hub. Let the installer finish before using Start in VR.
3. Start SteamVR and connect the headset, then launch Blade of Darkness through Steam or the Hub.
4. If the SteamVR dashboard opens instead of the game, disable Use Desktop Game Theatre while SteamVR is active in the game's Steam Properties.

Before starting in VR, switch off anti-aliasing / edge smoothing in the game's graphics options. If it remains on, the headset shows only a small flat 2D window instead of the stereo game.

If SteamVR or the headset is absent, the publisher says the game starts flat. That is not a VR readiness test. The Hub has not executed the licensed game or checked a headset image.

## Required and recommended game settings

| Setting | Value | Reason |
|---|---|---|
| Edge smoothing / anti-aliasing | Off, required | Otherwise VR shows only a small flat 2D window instead of the stereo game. |
| Motion blur | Off | Avoids headset smearing. |
| Bloom | Off | Prevents one eye's glow from bleeding into the other. |
| Ambient occlusion | Off recommended | Avoids a seam and saves frame time. |
| Frame-rate limit | On | The publisher reports smoother camera movement. |
| Resolution | As high as the GPU can sustain | The side-by-side eye image is sharper at higher resolution. |
| HDR | Optional | It does not change the stereo composition. |
| In-game FOV | Leave it alone | BladeVR sets the needed wide FOV itself. |

## Normal VR view controls

| Button | Action |
|---|---|
| [[Page Up]] / [[Page Down]] | Increase or decrease eye separation and perceived world scale. |
| [[End]] | Cycle the virtual menu/HUD screen size. |
| [[Insert]] | Toggle head tracking; turning it back on also recentres. |
| [[Home]] | Recenter the camera at the character's eyes. |
| [[Delete]] | Toggle free look versus walking where the headset looks. |
| [[F5]] | Enter or leave the diorama. |

Game combat and menus use the original game's keyboard/mouse or gamepad mapping.

## Diorama controls

The model starts in front of you and may be viewed from any side. The game remains playable. Fixed, attached and behind-the-character model modes are available; the model can be scaled, moved, rotated or cut open. Cinematics temporarily follow the authored camera and return to the model afterwards.

| Button | Action |
|---|---|
| [[F5]] / [[R3]] in gamepad model layer | Toggle diorama. |
| [[Home]] / [[X]] in gamepad model layer | Recenter the model at a useful size. |
| [[Page Up]] / [[Page Down]] | Zoom the model. |
| [[F4]] | Cycle the view cone. |
| [[F6]] | Cycle visible-map area. |
| [[F7]] | Cycle game/magenta/green background for Virtual Desktop passthrough. |
| [[Pause]] | Toggle whether characters are affected by cuts. |
| [[Delete]] | Toggle movement relative to your view of the model. |
| [[L3]] | Switch the gamepad between game controls and model controls. |
| [[LB]] in gamepad model layer / [[Left Stick Click]] | Cycle fixed, attached and from-behind model modes. |
| [[RB]] in gamepad model layer / [[Right Stick Click]] | Cycle visible-map area. |
| [[D-pad Left]] / [[D-pad Right]] | Toggle the gamepad model-layer view cone. |
| [[D-pad Up]] / [[D-pad Down]] | Change view-cone width. |
| [[A]] / [[B]] in gamepad model layer | Toggle vertical or height cut. |
| [[Y]] in gamepad model layer / [[Y]] on left motion controller | Toggle passthrough background. |
| [[Right Stick]] in gamepad model layer | Turn or zoom the model. |
| [[Left Stick]] in gamepad model layer | Move the table. |
| [[One Grip]] | Make the model follow that hand. |
| [[Both Grips]] | Scale and turn the model with both hands. |
| [[One Trigger]] | Move a cut plane with the hand. |
| [[Both Triggers]] | Change the visible-map area. |
| [[X]] on left motion controller | Recenter the model. |
| [[B]] / [[A]] on right motion controller | Raise or lower the table. |

The controller table describes the publisher's v1.6 default mappings. The gamepad must be in its model layer for the listed model actions; press [[L3]] again to return to combat. Virtual Desktop passthrough needs its own colour-key configuration (Streaming → VR Passthrough → Environment); Link and Air Link do not offer that SteamVR passthrough route.

## Troubleshooting

- Flat game, no stereo: Start SteamVR and connect the headset before launching. Check that all three DLLs are present beside `Blade.exe` and that the 2021 remaster is installed. Disable desktop theatre if SteamVR opens the wrong screen.
- Two eyes show the same picture: Turn edge smoothing off in the game. This is the publisher's required setting.
- Jerky camera or low frame rate: Enable the game's frame-rate limit; lower resolution if your GPU cannot sustain stereo rendering. Turn off bloom and ambient occlusion.
- Model lost or misplaced: Press [[Home]] or model-layer [[X]] to recenter it.
- Unexpected gamepad behavior: Press [[L3]] to return from model controls to the game. Normal combat remains the game's own controls.
- After a game update: The publisher's native addresses target the Steam remaster build used for v1.6. A later game update can require a new mod release. Do not substitute files from the 2001 original.
- A changed DLL remains after Uninstall now: The Hub preserves files changed after it installed them and clears VR Ready. Review or back up that file yourself before reinstalling; setup will refuse to overwrite it silently.

>>> The sword was sharp enough before it gained a second viewpoint.
