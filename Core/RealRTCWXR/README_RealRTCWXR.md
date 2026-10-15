# Return to Castle Wolfenstein VR

## About the Game

RealRTCW XR is Team Beef Studios' OpenXR port of the RealRTCW 5.0 overhaul for Return to Castle Wolfenstein. It brings the original single-player campaign to PC VR with tracked weapon aiming. You must own the original Windows RTCW game; neither publisher Setup includes its commercial game files.

## Choose your Setup

| Option | Included | You provide |
| --- | --- | --- |
| **Full** (recommended) | VR build and RealRTCW overhaul data | Original RTCW game data |
| **Minimal** | VR build only | Original RTCW game data **and** RealRTCW 5.0 beta data |

The Full download is about 2 GB. Minimal is smaller, but the Steam RealRTCW installation must be switched to a 5.0 beta branch. In Steam, open **RealRTCW > Properties > Betas**, select the 5.0 beta and let Steam finish updating. The publisher Setup checks this branch when it copies Steam data. Do not choose Minimal merely to save download time if you do not already have that build.

## Installing

The Hub checks the current [publisher releases](https://github.com/Team-Beef-Studios/RealRTCWXR/releases), including prereleases, and downloads the chosen Setup. The publisher then installs a **separate VR copy**. It never edits your original Steam game. Choose the VR destination in the publisher window.

For Steam, choose **Copy the game data from my Steam installation**. The publisher finds Steam libraries, copies the five required original RTCW `Main` archives, and, for Minimal, copies the RealRTCW 5.0 beta data. For GOG, Xbox-App or PC disc, choose **I will provide the game files myself**. The Setup shows the missing filenames and the exact `Main` folder where you must copy them. Then press **Install** again. The original game folder must contain `WolfSP.exe` and `Main\pak0.pk3`, `sp_pak1.pk3`, `sp_pak2.pk3`, `sp_pak3.pk3` and `sp_pak4.pk3`.

The Hub verifies the dedicated VR executable, renderer, OpenXR game modules, overhaul data and original game data before recording a successful install. A publisher window that was only opened or closed does not count as installed. If the Setup needs files, use the Hub recovery screen to retry after supplying them. A full installation or repair can take several minutes.

## Start and troubleshooting

Set your headset's OpenXR runtime, then choose [[Start in VR]]. The Hub starts `RealRTCWXR.exe` in the separate VR folder. The publisher's **RealRTCW XR** desktop shortcut points to the same executable. Starting `WolfSP.exe` opens the original flat game and is not the VR route.

If the Setup cannot find the Steam copy, use the publisher's manual data option. If Minimal reports the wrong RealRTCW branch, switch to the 5.0 beta or rerun the Hub installer and choose Full. If the VR copy is incomplete, rerun the same publisher Setup into the same destination to repair it. Release v0.8.7 fixed a missing OpenAL dependency and a black screen after changing graphics settings.

The exact PC controller button mapping is not documented in the publisher README; check the game's control menu and the [Team Beef Discord](https://discord.gg/fA6m8SMZPA) for current bindings. [Watch VR gameplay](https://youtu.be/tZqX6i2lhLU).

## Support the creators

[Support Team Beef](https://www.patreon.com/teambeef). The RealRTCW overhaul is by WolfETPlayer; [support RealRTCW](https://ko-fi.com/realrtcwdev) separately if you wish.

>>> Castle Wolfenstein is waiting. Stay sharp.
