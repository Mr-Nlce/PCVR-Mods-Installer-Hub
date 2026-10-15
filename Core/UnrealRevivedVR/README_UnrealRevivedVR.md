# Unreal Revived

## About the Game

Unreal Gold is a classic first-person shooter bundle that combines the original 1998 *Unreal* campaign with its *Return to Na Pali* expansion pack. Powered by the groundbreaking Unreal Engine 1, it delivers atmosphere-rich sci-fi exploration, iconic weaponry, and fast-paced arena action as players fight to survive on the hostile alien world of Na Pali.

## VR conversion

[Unreal Revived](https://github.com/kwstasg/Unreal-Revived) by Kwstasg modernizes Unreal Gold with a DirectX 12 renderer and a native OpenXR VR mode. In VR you can select head-gaze or motion-controller aiming; movement, menus and the HUD also support gamepad input. It is a separate installation and does not change the original Unreal Gold source. A configured OpenXR runtime, headset, Windows x64 and DirectX 12 capable graphics are required. Actual performance depends on the PC and headset.

The source game is available through [OldUnreal's official full-game installer](https://www.oldunreal.com/downloads/unreal/full-game-installers/). Unreal Revived Setup links to it when no source is detected. The usual original game path is `C:\Unreal`; the separate VR installation defaults to `C:\Games\Unreal Revived`. Setup can also browse to another source folder containing `System\Unreal.exe`.

## Install or update

1. Click **Install** or **Update** in the Hub. Read the opening screen and press [Enter].
2. Choose the latest public GitHub Setup or explicitly select a local `UnrealRevived-Setup-*.exe`. The Hub will not silently pick an EXE from Downloads. It will not replace a newer installed build with an older public release.
3. Read the Setup instructions and press [Enter] before the publisher EXE opens. Windows may request administrator approval if that Setup build needs it.
4. In publisher Setup, select your original Unreal Gold installation. If needed, choose **Install via OldUnreal**, complete that installer, return to Unreal Revived Setup and select **Detect Again**. Keep the Revived destination separate from the source game.
5. If Setup finds an existing Unreal Revived installation, follow its uninstall/reinstall prompts. Choose to retain saves and back up settings. Publisher Setup does not automatically restore backed-up settings; restore the desired profile files manually afterward.
6. After Setup closes, the Hub checks the actual VR executable, OpenXR loader, renderer, menu component, source map and publisher metadata. If you chose a custom destination, provide that Unreal Revived folder when asked. Only then does the Hub record the installed version.

The Hub checks GitHub for newer stable Setup releases. The displayed installed version comes from the publisher's VR executable, including installations made outside the Hub. The supplied local 0.9.0 build is newer than the last publicly visible 0.8.0 GitHub release at the time this entry was prepared; it is never downgraded automatically.

If a download fails, use the recovery prompt to retry, open the release page after its [Enter] prompt, or select a Setup EXE manually. A missing installed file alone is not proof of antivirus quarantine. Check the destination and installer log; review antivirus history only if it reports a matching detection.

## Start in VR

**Start in VR** launches `System64\UnrealRevivedVR.exe` from the verified Unreal Revived folder. The separate `System64\UnrealRevived.exe` starts desktop mode. Start through the VR executable or the publisher's VR shortcut, with an OpenXR runtime configured and a headset connected.

## Controls

These are publisher-documented defaults. Bindings can be changed in the game's Input and VR preferences.

| Button | Action |
| --- | --- |
| [[Motion Controller]] | Aim when **Motion Controllers** is selected under Preferences → VR → Aiming Method. |
| [[Head Gaze]] | Aim when **Head Gaze** is selected. |
| [[Right Stick]] | Smooth turn. |
| [[Right Stick Click]] | Recenter the VR view. |
| [[F10]] | Recenter the VR view. |
| [[Q]] / [[E]] / [[F]] | Select and use inventory items with the updated default bindings. |
| [[F11]] | Toggle the FPS statistics display. |

## Remove

Run the publisher's `unins000.exe` in the Unreal Revived installation. Choose to retain saves and back up settings when prompted. This removes Unreal Revived; the separate OldUnreal or original Unreal Gold source is not removed by the Hub.

After launch, press [[Esc]] → **Options** → **Preferences** → **VR** to set player height and choose motion-controller aiming.

>>> Welcome to Na Pali. The Skaarj look bigger from here.
