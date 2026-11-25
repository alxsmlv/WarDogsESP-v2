# WarDogs ESP v2 — new offsets (2026-11-25) — build & run guide

Offsets compiled into the source and this exe:
  GNames   = 0xD14DD40
  GObjects = 0xD220560
  GWorld   = 0xD3ACD08
  GEngine  = 0xD3AFFC0
  VitalityState = 0x814   (bleedout byte @ pawn+0x830, stance @ pawn+0x831)

All memory reads go through the kdmapper-mapped kernel driver (IOCTL backend);
the exe never uses ReadProcessMemory. If the driver is not mapped it shows
"Kernel backend unavailable - map the driver".

## Contents of this folder
  WarDogsESP_v2.exe    prebuilt overlay (MinGW cross-build; works as-is)
  WebView2Loader.dll   required next to the exe (F1 menu host)
  menu.html            F1 menu UI, loaded from disk at startup
  offsets.txt          the offset definitions used for this build
  src_and_run/         FULL source package (cheat, driver.c, driver.sys, kdmapper fork)
  build_mingw.sh       Linux/MinGW rebuild script (optional)

## Option A — just run it (recommended)
You already have a ready exe + prebuilt driver.sys in src_and_run/CoreWD_package/3_src_driver/.

1. Copy these files to one folder on your Windows 11 x64 machine:
     WarDogsESP_v2.exe
     WebView2Loader.dll
     menu.html
     src_and_run/CoreWD_package/3_src_driver/driver.sys
     src_and_run/kdmapper-master/kdmapper.exe (or build the mapper, see Option B step 3)
2. Disable Secure Boot (kdmapper needs to load an unsigned driver):
     reboot -> BIOS/UEFI -> Security -> Secure Boot -> Disabled
3. Start the game (War Dogs) and wait until you are in a match.
4. Open an elevated Command Prompt (Run as administrator) and map the driver:
     kdmapper.exe driver.sys
   (If the project ships its own mapper fork under 4_src_mapper\kd2_src, use that
    kdmapper build instead — it matches the driver's IOCTL ABI.)
5. Run WarDogsESP_v2.exe as administrator. It attaches via the mapped driver.
6. In-game: overlay draws boxes/skeleton/names/health/weapon. Press F1 for the
   settings menu (needs menu.html beside the exe). Hotkeys per README.md.

## Option B — build everything yourself on Windows (official toolchain)
Prereqs: Visual Studio 2022 (Desktop C++), Windows 11 SDK 10.0.26100, WDK (driver only).

1. Overlay:
     cd src_and_run\CoreWD_package\2_src_cheat
     build_cheat.bat
   -> WarDogsESP_v2.exe (+ WebView2Loader.dll + menu.html copied beside it)
   If build_cheat.bat can't find vcvars64.bat, edit the VS path at the top.

2. Driver (already prebuilt as driver.sys, but to rebuild):
     cd src_and_run\CoreWD_package\3_src_driver
     build_driver.bat
   -> x64\Release\driver.sys (copied to driver.sys)

3. Mapper (kdmapper fork):
     open src_and_run\kdmapper-master\kdmapper.sln in VS2022,
     build Release x64 -> kdmapper.exe
   (or use the one bundled in the original 1_run folder if present)

4. Deploy exactly 3+2 files together:
     WarDogsESP_v2.exe, WebView2Loader.dll, menu.html, driver.sys, kdmapper.exe

5. Run sequence = Option A steps 3-6.

## Notes
- Windows 11 x64 only (see README.md "Why Windows 11 only").
- The session key changes every time the driver is mapped; the exe re-reads it
  automatically, so order is: map driver -> start exe.
- Offsets must be updated after each game patch; they live in wd_esp_full.c
  lines 65-66 (GWorld/GEngine), 174 (GNames), 115 (VitalityState), 1516 (GObjects).
