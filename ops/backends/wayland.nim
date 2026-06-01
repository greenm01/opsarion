type
  OpsWaylandDisplay* {.importc, incompleteStruct, header: "ops_wayland.h".} = object

  OpsWaylandWindow* {.importc, incompleteStruct, header: "ops_wayland.h".} = object

const
  opsWaylandModShift* = 1'u32 shl 0
  opsWaylandModCtrl* = 1'u32 shl 1
  opsWaylandModAlt* = 1'u32 shl 2
  opsWaylandModSuper* = 1'u32 shl 3

type OpsWaylandCursorShape* {.size: sizeof(cint).} = enum
  kwcDefault = 1
  kwcText = 2
  kwcCrosshair = 3
  kwcPointer = 4
  kwcResizeEW = 5
  kwcResizeNS = 6
  kwcResizeNWSE = 7
  kwcResizeNESW = 8
  kwcResizeAll = 9

type OpsWaylandCallbacks* {.bycopy, importc, header: "ops_wayland.h".} = object
  onClose* {.importc: "on_close".}: proc(userdata: pointer) {.cdecl.}
  onFocus* {.importc: "on_focus".}: proc(focused: bool, userdata: pointer) {.cdecl.}
  onResize* {.importc: "on_resize".}: proc(w, h: uint32, userdata: pointer) {.cdecl.}
  onKeyDown* {.importc: "on_key_down".}:
    proc(keycode, mods: uint32, userdata: pointer) {.cdecl.}
  onKeyRepeat* {.importc: "on_key_repeat".}:
    proc(keycode, mods: uint32, userdata: pointer) {.cdecl.}
  onKeyUp* {.importc: "on_key_up".}:
    proc(keycode, mods: uint32, userdata: pointer) {.cdecl.}
  onChar* {.importc: "on_char".}: proc(codepoint: uint32, userdata: pointer) {.cdecl.}
  onMouseMove* {.importc: "on_mouse_move".}:
    proc(x, y: cdouble, userdata: pointer) {.cdecl.}
  onMouseButton* {.importc: "on_mouse_button".}:
    proc(btn: uint32, pressed: bool, userdata: pointer) {.cdecl.}
  onScroll* {.importc: "on_scroll".}: proc(dx, dy: cdouble, userdata: pointer) {.cdecl.}
  onScale* {.importc: "on_scale".}: proc(scale: cdouble, userdata: pointer) {.cdecl.}
  userdata*: pointer

proc opsWaylandInit*(): ptr OpsWaylandDisplay {.
  cdecl, importc: "ops_wayland_init", header: "ops_wayland.h"
.}

proc opsWaylandCreateWindow*(
  display: ptr OpsWaylandDisplay, w, h: uint32, title: cstring
): ptr OpsWaylandWindow {.
  cdecl, importc: "ops_wayland_create_window", header: "ops_wayland.h"
.}

proc opsWaylandSetCallbacks*(
  window: ptr OpsWaylandWindow, callbacks: ptr OpsWaylandCallbacks
) {.cdecl, importc: "ops_wayland_set_callbacks", header: "ops_wayland.h".}

proc opsWaylandPollEvents*(
  display: ptr OpsWaylandDisplay
) {.cdecl, importc: "ops_wayland_poll_events", header: "ops_wayland.h".}

proc opsWaylandRoundtrip*(
  display: ptr OpsWaylandDisplay
) {.cdecl, importc: "ops_wayland_roundtrip", header: "ops_wayland.h".}

proc opsWaylandGetWlDisplay*(
  display: ptr OpsWaylandDisplay
): pointer {.cdecl, importc: "ops_wayland_get_wl_display", header: "ops_wayland.h".}

proc opsWaylandGetWlSurface*(
  window: ptr OpsWaylandWindow
): pointer {.cdecl, importc: "ops_wayland_get_wl_surface", header: "ops_wayland.h".}

proc opsWaylandGetWidth*(
  window: ptr OpsWaylandWindow
): uint32 {.cdecl, importc: "ops_wayland_get_width", header: "ops_wayland.h".}

proc opsWaylandGetHeight*(
  window: ptr OpsWaylandWindow
): uint32 {.cdecl, importc: "ops_wayland_get_height", header: "ops_wayland.h".}

proc opsWaylandWindowShouldClose*(
  window: ptr OpsWaylandWindow
): bool {.cdecl, importc: "ops_wayland_window_should_close", header: "ops_wayland.h".}

proc opsWaylandWindowConfigured*(
  window: ptr OpsWaylandWindow
): bool {.cdecl, importc: "ops_wayland_window_configured", header: "ops_wayland.h".}

proc opsWaylandSetTitle*(
  window: ptr OpsWaylandWindow, title: cstring
) {.cdecl, importc: "ops_wayland_set_title", header: "ops_wayland.h".}

proc opsWaylandSetAppId*(
  window: ptr OpsWaylandWindow, appId: cstring
) {.cdecl, importc: "ops_wayland_set_app_id", header: "ops_wayland.h".}

proc opsWaylandSetSize*(
  window: ptr OpsWaylandWindow, w, h: uint32
) {.cdecl, importc: "ops_wayland_set_size", header: "ops_wayland.h".}

proc opsWaylandSetSizeLimits*(
  window: ptr OpsWaylandWindow, minW, minH, maxW, maxH: uint32
) {.cdecl, importc: "ops_wayland_set_size_limits", header: "ops_wayland.h".}

proc opsWaylandSetCursorShape*(
  window: ptr OpsWaylandWindow, shape: OpsWaylandCursorShape
) {.cdecl, importc: "ops_wayland_set_cursor_shape", header: "ops_wayland.h".}

proc opsWaylandDestroyWindow*(
  window: ptr OpsWaylandWindow
) {.cdecl, importc: "ops_wayland_destroy_window", header: "ops_wayland.h".}

proc opsWaylandDestroy*(
  display: ptr OpsWaylandDisplay
) {.cdecl, importc: "ops_wayland_destroy", header: "ops_wayland.h".}
