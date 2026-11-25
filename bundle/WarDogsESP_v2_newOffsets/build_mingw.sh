#!/bin/bash
# Cross-compile CoreWD (WarDogs ESP overlay) on Linux with MinGW-w64.
# The official toolchain is MSVC (see 2_src_cheat/build_cheat.bat); this script
# mirrors it for environments without Visual Studio. Output: WarDogsESP_v2.exe
set -e
SRC=/workspace/extracted/CoreWD_package/2_src_cheat
OUT=/workspace/out
mkdir -p "$OUT"
cd "$SRC"

CC=x86_64-w64-mingw32-gcc
CXX=x86_64-w64-mingw32-g++
WV2="$SRC/WebView2SDK"

echo "[1/5] wd_esp_full.c"
$CC -O2 -D_CRT_SECURE_NO_WARNINGS -c wd_esp_full.c -o "$OUT/wdm_esp.obj"

echo "[2/5] chams/chams.c"
$CC -O2 -D_CRT_SECURE_NO_WARNINGS -c chams/chams.c -o "$OUT/wdm_chams.obj"

echo "[3/5] menu_webview.cpp  (needs full WebView2 SDK headers)"
if [ -f "$WV2/include/EventToken.h" ]; then
  $CXX -O2 -std=c++17 -fpermissive -I "$WV2/include" -c menu_webview.cpp -o "$OUT/wdm_wv2.obj"
else
  echo "  [SKIP] EventToken.h missing from bundled WebView2SDK -> building WITHOUT the WebView2 menu host."
  # Provide stubs of the bridge API (menu_bridge.h) so the link succeeds;
  # the F1 WebView2 menu is inactive until rebuilt on Windows/MSVC.
  cat > "$OUT/menu_stub.cpp" <<'EOF'
#include <windows.h>
#include "menu_bridge.h"
static BR_Config g_stub_cfg;
BR_Config* br_get(void) { return &g_stub_cfg; }
int  br_start_menu(void) { return 0; }
void br_stop_menu(void) {}
void br_request_toggle(void) {}
EOF
  $CXX -O2 -std=c++17 -I "$SRC" -I "$WV2/include" -c "$OUT/menu_stub.cpp" -o "$OUT/wdm_wv2.obj"
fi

echo "[4/5] gpu.cpp"
$CXX -O2 -std=c++17 -fpermissive -c gpu.cpp -o "$OUT/wdm_gpu.obj"

echo "[5/5] link"
# NOTE: no -municode — the entry is WinMain (ANSI), matching MSVC /SUBSYSTEM:WINDOWS.
$CXX -O2 -Wl,--subsystem,windows -o "$OUT/WarDogsESP_v2.exe" \
  "$OUT/wdm_esp.obj" "$OUT/wdm_chams.obj" "$OUT/wdm_wv2.obj" "$OUT/wdm_gpu.obj" \
  -ld3d11 -ldxgi -ld2d1 -ldwrite -ldcomp -ld3dcompiler \
  -lkernel32 -luser32 -lgdi32 -lcomctl32 -ladvapi32 -lole32 -loleaut32 -luuid \
  -lwinhttp -lshell32 -lwinmm -lntdll

cp -f "$SRC/menu.html" "$OUT/menu.html" 2>/dev/null || true
cp -f "$WV2/lib/x64/WebView2Loader.dll" "$OUT/WebView2Loader.dll" 2>/dev/null || true
echo "BUILD_OK -> $OUT/WarDogsESP_v2.exe"
