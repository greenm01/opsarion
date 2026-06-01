import ops/okys

import ops/backends/wayland
import ops/backends/wayland_keys
import ops/backends/wayland_wgpu
import ops/backends/okys_wgpu_host
from ops/types import keyC, keyQ

type AppState = object
  closed: bool
  width: uint32
  height: uint32

proc onClose(userdata: pointer) {.cdecl.} =
  let state = cast[ptr AppState](userdata)
  if state != nil:
    state.closed = true

proc quitShortcut(keycode, mods: uint32): bool =
  let key = waylandKeycode(keycode)
  (mods and opsWaylandModCtrl) != 0 and (key == keyQ or key == keyC)

proc onKeyDown(keycode, mods: uint32, userdata: pointer) {.cdecl.} =
  let state = cast[ptr AppState](userdata)
  if state != nil and quitShortcut(keycode, mods):
    state.closed = true

proc onResize(w, h: uint32, userdata: pointer) {.cdecl.} =
  let state = cast[ptr AppState](userdata)
  if state != nil:
    state.width = w
    state.height = h

proc draw(vg: OpsRenderContext, width, height: uint32) =
  let
    w = width.float
    h = height.float
    cardW = min(w - 48.0, 420.0)
    cardH = 180.0
    cardX = (w - cardW) * 0.5
    cardY = (h - cardH) * 0.5

  vg.beginFrame(w, h, 1.0)

  vg.beginPath()
  vg.rect(0, 0, w, h)
  vg.fillColor(rgb(0.12, 0.13, 0.14))
  vg.fill()

  vg.beginPath()
  vg.roundedRect(cardX, cardY, cardW, cardH, 8)
  vg.fillColor(rgb(0.20, 0.23, 0.26))
  vg.fill()

  vg.beginPath()
  vg.rect(cardX + 28, cardY + 34, cardW - 56, 28)
  vg.fillColor(rgb(0.20, 0.58, 0.78))
  vg.fill()

  vg.beginPath()
  vg.circle(cardX + 82, cardY + 116, 34)
  vg.fillColor(rgb(0.90, 0.42, 0.24))
  vg.fill()

  vg.beginPath()
  vg.roundedRect(cardX + 142, cardY + 88, cardW - 192, 56, 6)
  vg.fillColor(rgb(0.42, 0.68, 0.34))
  vg.fill()

  vg.endFrame()

when isMainModule:
  var state = AppState(closed: false, width: 640, height: 420)
  var callbacks = OpsWaylandCallbacks(
    onClose: onClose,
    onResize: onResize,
    onKeyDown: onKeyDown,
    onKeyRepeat: onKeyDown,
    userdata: addr state,
  )

  let display = opsWaylandInit()
  if display == nil:
    echo "No Wayland display available; native Wayland wgpu example skipped."
    quit 0

  let window = opsWaylandCreateWindow(
    display, state.width, state.height, "Ops Native Wayland wgpu"
  )
  if window == nil:
    opsWaylandDestroy(display)
    quit "Could not create native Wayland window."

  opsWaylandSetCallbacks(window, addr callbacks)
  opsWaylandSetCursorShape(window, kwcDefault)

  var backend: OkysWgpuHost
  let (surfaceW, surfaceH) = surfaceSize(window)
  backend.initOkysWgpuHostWithSurface(
    wgpuSurfaceHandle(display, window), surfaceW, surfaceH
  )
  let rc = createRenderContext({rifSparseStrip})
  let colorFormat =
    case backend.okysSurfaceFormatCode()
    of 1:
      wgtfBGRA8Unorm
    of 2:
      wgtfRGBA8Unorm
    else:
      quit "Unsupported WebGPU surface format for okys."
  rc.setupWebGPU(backend.okysDeviceHandle(), colorFormat)

  while not state.closed and not opsWaylandWindowShouldClose(window):
    opsWaylandPollEvents(display)
    let (width, height) = surfaceSize(window)
    backend.resizeOkysWgpuHost(width, height)
    var frame = backend.beginOkysSurfaceFrame()
    if frame.colorTextureView.isNil:
      continue
    rc.setWebGPURenderTarget(frame.colorTextureView, frame.width.int, frame.height.int)
    draw(rc, width, height)
    discard backend.presentOkysSurfaceFrame(frame)

  deleteRenderContext(rc)
  opsWaylandDestroyWindow(window)
  opsWaylandDestroy(display)
