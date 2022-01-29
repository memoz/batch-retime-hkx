# batch-retime-hkx
PowerShell wrapper around hkxpack-cli.jar to easily multiply animation timings by a factor
# Usage
1. Download `hkxpack-cli.jar` from https://github.com/Dexesttp/hkxpack/ if you don't already have it;
2. Put `hkxpack-cli.jar` together with `retime_hkx.bat` and `retime_hkx.ps1` from this repository in the same folder;
3. Drag hkx files onto `retime_hkx.bat` or run `retime_hkx.ps1` from PowerShell with hkx files as arguments.

The scale factor is hardcoded to 1.5 by default. Change `$scale_factor = 1.5` if you want.
# Background
Some Fallout 4 weapon mods on nexusmods.com don't come with proper first person power armor animations. They are either too fast or too slow. There are 2 ways to fix them:
1. Redo those animations in your preferred 3D software;
2. Do a naive multiplication on the timings.

1 is obviously the proper way, but takes a lot of know-how, so here's 2.

The batch file serves as a bootstrapper because there's no drag-and-drop handler for ps1 by default.
