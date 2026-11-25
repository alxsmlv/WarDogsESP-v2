#include <windows.h>
#include "menu_bridge.h"
static BR_Config g_stub_cfg;
BR_Config* br_get(void) { return &g_stub_cfg; }
int  br_start_menu(void) { return 0; }
void br_stop_menu(void) {}
void br_request_toggle(void) {}
