import ops/backends/wayland
import ops/backends/wayland_keys
from ops/types import keyC, keyQ

type AppState = object
  closed: bool

proc quitShortcut(keycode, mods: uint32): bool =
  let key = waylandKeycode(keycode)
  (mods and opsWaylandModCtrl) != 0 and (key == keyQ or key == keyC)

proc onClose(userdata: pointer) {.cdecl.} =
  let state = cast[ptr AppState](userdata)
  if state != nil:
    state.closed = true

proc onKeyDown(keycode, mods: uint32, userdata: pointer) {.cdecl.} =
  let state = cast[ptr AppState](userdata)
  if state != nil and quitShortcut(keycode, mods):
    state.closed = true

proc onResize(w, h: uint32, userdata: pointer) {.cdecl.} =
  discard w
  discard h
  discard userdata

when isMainModule:
  var state = AppState(closed: false)
  var callbacks = OpsWaylandCallbacks(
    onClose: onClose,
    onResize: onResize,
    onKeyDown: onKeyDown,
    onKeyRepeat: onKeyDown,
    userdata: addr state,
  )

  let display = opsWaylandInit()
  if display == nil:
    echo "No Wayland display available; native Wayland smoke skipped."
    quit 0

  let window = opsWaylandCreateWindow(display, 640, 420, "Ops Native Wayland")
  if window == nil:
    opsWaylandDestroy(display)
    quit "Could not create native Wayland window."

  opsWaylandSetCallbacks(window, addr callbacks)
  opsWaylandSetTitle(window, "Ops Native Wayland")
  opsWaylandSetSize(window, 640, 420)
  opsWaylandSetCursorShape(window, kwcDefault)

  if opsWaylandGetWlDisplay(display) == nil:
    opsWaylandDestroyWindow(window)
    opsWaylandDestroy(display)
    quit "Wayland display handle was nil."
  if opsWaylandGetWlSurface(window) == nil:
    opsWaylandDestroyWindow(window)
    opsWaylandDestroy(display)
    quit "Wayland surface handle was nil."

  for _ in 0 ..< 3:
    if state.closed or opsWaylandWindowShouldClose(window):
      break
    opsWaylandPollEvents(display)

  opsWaylandDestroyWindow(window)
  opsWaylandDestroy(display)
