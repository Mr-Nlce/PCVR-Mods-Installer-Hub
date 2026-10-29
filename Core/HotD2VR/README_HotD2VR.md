# The House of the Dead 2 (Original) VR

## About the Game

The original Windows PC release of The House of the Dead 2 is a fast on-rails arcade shooter. Follow the branching routes through a zombie outbreak, protect civilians and use quick, accurate shots to survive. This entry is for the original PC-CD game. The House of the Dead 2: Remake has its own separate Hub entry and is not a compatible source for HotD2VR.

## HotD2VR and requirements

HotD2VR by Icedomega13 adds an OpenXR headset view and two independently aimed pistols to the original game's logic. Its publisher Setup creates a separate VR copy; it does not patch your original installed game folder or source disc image. You must provide your own original Windows PC game: a disc-image ZIP with one IMG or ISO, a direct IMG/ISO, or an existing folder containing Hod2.exe plus cam, coli, evt, mot, pol, sound and tex. Do not use the remake or a console image. Modified repacks and other executable revisions have not been validated and may be rejected by publisher Setup.

The published alpha targets Windows 10/11 x64, .NET Framework 4.8, a D3D11-capable GPU and a 32-bit OpenXR runtime. The publisher tested Quest 3 through Virtual Desktop with VDXR. Other headsets and runtimes need user testing. Keep at least 3 GB free at the VR destination. Setup downloads its own OpenXR loader and dgVoodoo backend; keep internet available while it prepares the copy. No original game data or private HD texture pack is distributed with the Hub or the mod.

## Install and launch

1. Close the original game. Choose [[Get Installer]] in the Hub. The Hub checks [GitHub Releases](https://github.com/Icedomega13/HouseOfTheDead2VROG/releases), including prereleases, and asks before downloading and opening the current publisher Setup EXE. The EXE is unsigned; Windows may ask you to review its publisher or approve a step such as ISO mounting. The Hub does not disable security software.
2. In publisher Setup, choose your original PC disc-image ZIP as-is or select an IMG/ISO. If the game is already installed, select Use an installed game folder instead and choose the folder with Hod2.exe. The usual location is C:\Program Files (x86)\SEGA\THE HOUSE OF THE DEAD 2. Check the separate HotD2VR destination, then choose Install / update.
3. Wait while Setup copies the game, prepares disc handling and downloads dependencies. The Hub checks the publisher's install.json and the VR runtime before recording success. If you kept the default Play HotD2VR desktop shortcut, the Hub adds the supplied game icon after a successful install.
4. Connect the headset and controllers. Set a working 32-bit OpenXR runtime; for the publisher-tested route, connect through Virtual Desktop and select VDXR in Streamer. Choose [[Start in VR]] in the Hub or the Play HotD2VR desktop shortcut. Both launch HotD2VR.exe /play from the separate VR destination. Do not start the original Hod2.exe for VR.

Publisher Setup defaults to %LOCALAPPDATA%\HotD2VR, but you may select another drive with enough room. The original PC-CD installation at C:\Program Files (x86)\SEGA\THE HOUSE OF THE DEAD 2 can help you find your game files. A source ZIP/ISO and your original install are never changed by the Hub. The VR copy has its own launcher, settings and copied game data.

## Controls

| Button | Action |
|---|---|
| [[Either Controller]] | Aim that hand's pistol. |
| [[Either Trigger]] | Fire that pistol; arcade mode gives each gun six rounds. |
| [[Right A]] | Start or confirm; the title transition can require another press. |
| [[Right B]] | Reload both guns; retains the original game's deliberate cutscene skip. |
| [[Lower One Gun]] | Reload that gun outside detected cinematics; raise it to rearm. |
| [[Left Stick]] | Navigate menus. |
| [[Left Stick Click]] | Recenter while facing forward. |
| [[Left X]] | Escape or go back. |
| [[Left Y]] | Show or hide both headset aiming markers. |

Fresh installations start with aiming markers hidden, leaving gun-only aiming. Arcade mode shows a floating ammo panel for each hand and one shared health display. Original mode keeps native shared ammo and item handling. Haptic feedback confirms input, not a guaranteed hit.

## Settings and limits

The VR copy stores graphics and comfort settings in pcvr\vr-settings.json. Restart the game after editing it. Defaults include 1200 pixels per eye, 4x MSAA and 8x anisotropic filtering. If performance is poor, try EyeSize 1000 or 800 and lower Antialiasing. AimingCursor controls the initial marker state; [[Left Y]] still toggles markers during play. DualWield, IndependentMagazines, AmmoGauges, HealthGauge, AimDownReload, Haptics and HapticStrength can also be adjusted there. Updates keep your values and add new defaults without replacing the original game.

The mod preserves the original game's speed; there is no gameplay FPS unlock. Optional authored PNG replacements belong in working\pcvr\game\hd-textures; the public release includes no HD texture pack. The publisher still lists occasional misplaced hit effects, brief black bars, scenery or backfaces missing when looking far from the original camera, and cinematics the reload guard may not recognise. Full campaign coverage and comfort on other hardware remain to be confirmed.

## Updates, removal and troubleshooting

The Hub tracks the actual publisher release, including prereleases. For an update, close the game, launch the newest Setup from the Hub and choose the same HotD2VR destination. Publisher Setup preserves copied game data, saves, settings and disc handling; it keeps backups of replaced mod files. Uninstall now calls the publisher's registered removal path. That removal keeps your copied game, saves, disc ISO, settings and update backups for later reuse. The original game remains untouched. The separate Uninstall guide on this page explains these retained files.

- Setup rejects the game: use the original Windows PC release, not a remake, console image or modified repack. The tested publisher executable revision is documented in [publisher installation help](https://github.com/Icedomega13/HouseOfTheDead2VROG/blob/main/INSTALL.md). Do not bypass its game validation.
- A ZIP has multiple disc images: extract it yourself and select the correct original Windows PC IMG/ISO directly. Unsupported disc layouts can use the installed-folder option instead.
- No 32-bit runtime appears: reconnect the headset and select a runtime that supports 32-bit OpenXR applications. A registry listing alone does not prove a ready headset session.
- A download or file copy fails: read the Hub and publisher logs. A missing file alone does not prove antivirus quarantine. Check protection history for a matching dated detection before treating security software as the cause.
- The game does not launch: keep working\pcvr\launcher.log, working\pcvr\game\hotd2-ddraw-probe.log and the latest working\pcvr\sessions record from your HotD2VR destination. Include the release, GPU and runtime when reporting it to the [publisher issues page](https://github.com/Icedomega13/HouseOfTheDead2VROG/issues).

## PC2VR by fjdiazt
PC2VR is a separate implementation for the original Windows PC game. It adds an in-headset settings menu, per-mode scene checkpoints, stage/scene selection, resolution/MSAA controls, optional cheats and independent two-hand gun controls. There is no independently verified performance comparison with Icedomega13 here.

Choose Install / update VR mods, then PC2VR. The Hub needs your own folder containing Hod2.exe and Config.exe; drag the game EXE into setup or use Locate Game. The Remake and emulated versions are not supported. Only the original EXE revision documented by this publisher is supported; its own launcher checks that game build.

Use the PC2VR Start in VR action in the Hub. Alternative: The House of the Dead 2 VR - PC2VR desktop shortcut. The publisher's vr\start.bat is also available in the original game folder. The PC2VR Flat / VR switch on this page chooses whether that controller starts PC2VR or the original flat game. Close both game and VR viewer before switching.

The complete PC2VR runtime stays in the original game's vr subfolder. The Hub start controller is vr\Start-PC2VR.ps1. It calls vr\HOTD2VR.exe with --game-exe pointing to this exact original Hod2.exe. It does not launch or change the Icedomega13 VR copy.

## PC2VR controls
| Button | Action |
|---|---|
| [[Either Trigger]] | Fire that hand's gun; confirm a menu selection |
| [[Either Grip]] | Reload that hand's gun |
| [[Either Stick]] | Navigate game menus |
| [[A]] / [[X]] | Start, pause or resume |
| [[B]] / [[Y]] | Skip a scene or go back |
| [[Right Stick Click]] | Recenter |
| [[Left Stick Click]] | Open/close VR Settings |
| [[F8]] | Desktop VR Settings menu |
| [[Arrow Keys]] | Desktop settings navigation |
| [[Enter]] | Desktop settings selection |
| [[Right Ctrl]] | Desktop settings back |

The right controller is Player 1; the left is Player 2. Akimbo joins both by default; turn it off in VR Settings > Controls to join independently. Settings do not pause the game: pause explicitly first. Quit game in VR Settings closes both the game and viewer.

PC2VR checkpoints save the chapter/scene, not a full snapshot of health, inventory or enemies. Keep vr\HOTD2VR.checkpoint.ini and vr\HOTD2VR.original.checkpoint.ini to preserve them. User settings are in vr\HOTD2VR.ini.

## Discord discussion & support
[Flat2VR invite](https://discord.gg/uAeQkYBM4n)
[Icedomega13 HotD2VR discussion](https://discord.com/channels/747967102895390741/1555671371160494150)

## Links
[HotD2VR source and help](https://github.com/Icedomega13/HouseOfTheDead2VROG)
[HotD2VR releases](https://github.com/Icedomega13/HouseOfTheDead2VROG/releases)
[PC2VR source and documentation](https://github.com/fjdiazt/hotd2-pc2vr)
[PC2VR releases](https://github.com/fjdiazt/hotd2-pc2vr/releases)
[VR gameplay (Icedomega13)](https://www.youtube.com/shorts/oheXumMrKMM)

>>> Reload one gun at a time; the dead will not wait for both.
