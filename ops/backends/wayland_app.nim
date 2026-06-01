import std/unicode

import ops
import ops/backends/wayland
import ops/backends/wayland_keys
import ops/backends/wayland_wgpu

export wayland
export wayland_keys
export wayland_wgpu

{.push warning[HoleEnumConv]: off.}

type OpsWaylandApp* = ref object
  closed*: bool
  visible*: bool
  focused*: bool
  iconified*: bool
  title*: string
  pos*: tuple[x, y: int]
  width*: float
  height*: float
  surfaceWidth*: uint32
  surfaceHeight*: uint32
  scale*: float
  fixedSizeHint*: bool
  mouseX*: float
  mouseY*: float
  clipboard*: string
  display*: ptr OpsWaylandDisplay
  window*: ptr OpsWaylandWindow
  callbacks: OpsWaylandCallbacks

var gWaylandApp: OpsWaylandApp

proc waylandCursorShape*(shape: CursorShape): OpsWaylandCursorShape =
  case shape
  of csIBeam: kwcText
  of csCrosshair: kwcCrosshair
  of csHand: kwcPointer
  of csResizeEW: kwcResizeEW
  of csResizeNS: kwcResizeNS
  of csResizeNWSE: kwcResizeNWSE
  of csResizeNESW: kwcResizeNESW
  of csResizeAll: kwcResizeAll
  else: kwcDefault

proc onClose(userdata: pointer) {.cdecl.} =
  let app = cast[OpsWaylandApp](userdata)
  if app != nil:
    app.closed = true

proc onFocus(focused: bool, userdata: pointer) {.cdecl.} =
  let app = cast[OpsWaylandApp](userdata)
  if app != nil:
    app.focused = focused
  if not focused:
    clearInputState()

proc onResize(w, h: uint32, userdata: pointer) {.cdecl.} =
  let app = cast[OpsWaylandApp](userdata)
  if app != nil:
    app.width = w.float
    app.height = h.float
    app.surfaceWidth = w
    app.surfaceHeight = h

proc onKeyDown(keycode, mods: uint32, userdata: pointer) {.cdecl.} =
  queueKeyEvent(waylandKeycode(keycode), kaDown, waylandMods(mods))

proc onKeyRepeat(keycode, mods: uint32, userdata: pointer) {.cdecl.} =
  queueKeyEvent(waylandKeycode(keycode), kaRepeat, waylandMods(mods))

proc onKeyUp(keycode, mods: uint32, userdata: pointer) {.cdecl.} =
  queueKeyEvent(waylandKeycode(keycode), kaUp, waylandMods(mods))

proc onChar(codepoint: uint32, userdata: pointer) {.cdecl.} =
  if codepoint >= 32 and codepoint != 127:
    queueChar(Rune(codepoint))

proc onMouseMove(x, y: cdouble, userdata: pointer) {.cdecl.} =
  let app = cast[OpsWaylandApp](userdata)
  if app != nil:
    app.mouseX = x.float
    app.mouseY = y.float
  queueMouseMove(x.float, y.float)

proc onMouseButton(btn: uint32, pressed: bool, userdata: pointer) {.cdecl.} =
  let app = cast[OpsWaylandApp](userdata)
  if app != nil:
    queueMouseButtonEvent(waylandMouseButton(btn), pressed, app.mouseX,
        app.mouseY, {})

proc onScroll(dx, dy: cdouble, userdata: pointer) {.cdecl.} =
  queueScrollEvent(-dx / 10.0, -dy / 10.0)

proc onScale(scale: cdouble, userdata: pointer) {.cdecl.} =
  let app = cast[OpsWaylandApp](userdata)
  if app != nil:
    app.scale = max(1.0, scale.float)

proc installWaylandPlatformHooks*(app: OpsWaylandApp) =
  gWaylandApp = app
  let hooks = PlatformHooks(
    windowSize: proc(): tuple[w, h: float] =
      (gWaylandApp.width, gWaylandApp.height),
    surfaceSize: proc(): tuple[w, h: float] =
      (gWaylandApp.surfaceWidth.float, gWaylandApp.surfaceHeight.float),
    contentScale: proc(): tuple[x, y: float] =
      (gWaylandApp.scale, gWaylandApp.scale),
    cursorPos: proc(): tuple[x, y: float] =
      (gWaylandApp.mouseX, gWaylandApp.mouseY),
    setCursorPos: proc(x, y: float) =
      discard,
    setCursorShape: proc(shape: CursorShape) =
      if gWaylandApp.window != nil:
        opsWaylandSetCursorShape(gWaylandApp.window, waylandCursorShape(shape)),
    setCursorMode: proc(mode: PlatformCursorMode) =
      discard,
    clipboardGet: proc(): string =
      gWaylandApp.clipboard,
    clipboardSet: proc(text: string) =
      gWaylandApp.clipboard = text,
  )
  setPlatformHooks(hooks)

proc noGlfwProcAddress*() =
  discard

proc setAppId*(app: OpsWaylandApp, appId: string) =
  if app != nil and app.window != nil:
    opsWaylandSetAppId(app.window, appId)

proc setFixedSize*(app: OpsWaylandApp, fixed: bool) =
  if app == nil:
    return
  app.fixedSizeHint = fixed
  if app.window == nil:
    return
  if fixed:
    opsWaylandSetSizeLimits(
      app.window, app.surfaceWidth, app.surfaceHeight, app.surfaceWidth,
      app.surfaceHeight,
    )
  else:
    opsWaylandSetSizeLimits(app.window, 0, 0, 0, 0)

proc newOpsWaylandApp*(title: string, width, height: int): OpsWaylandApp =
  result = OpsWaylandApp(
    closed: false,
    visible: true,
    focused: true,
    iconified: false,
    title: title,
    pos: (x: 0, y: 0),
    width: width.float,
    height: height.float,
    surfaceWidth: width.uint32,
    surfaceHeight: height.uint32,
    scale: 1.0,
    fixedSizeHint: false,
  )
  result.callbacks = OpsWaylandCallbacks(
    onClose: onClose,
    onFocus: onFocus,
    onResize: onResize,
    onKeyDown: onKeyDown,
    onKeyRepeat: onKeyRepeat,
    onKeyUp: onKeyUp,
    onChar: onChar,
    onMouseMove: onMouseMove,
    onMouseButton: onMouseButton,
    onScroll: onScroll,
    onScale: onScale,
    userdata: cast[pointer](result),
  )

  result.display = opsWaylandInit()
  if result.display == nil:
    quit "No Wayland display available for native Wayland backend."

  result.window = opsWaylandCreateWindow(
    result.display, result.surfaceWidth, result.surfaceHeight, title
  )
  if result.window == nil:
    opsWaylandDestroy(result.display)
    quit "Could not create native Wayland window."

  opsWaylandSetCallbacks(result.window, addr result.callbacks)
  opsWaylandSetCursorShape(result.window, kwcDefault)
  installWaylandPlatformHooks(result)

proc updateSurfaceSize*(app: OpsWaylandApp) =
  let (width, height) = surfaceSize(app.window)
  app.surfaceWidth = width
  app.surfaceHeight = height
  app.width = width.float
  app.height = height.float

proc shouldClose*(app: OpsWaylandApp): bool =
  app.closed or opsWaylandWindowShouldClose(app.window)

proc `shouldClose=`*(app: OpsWaylandApp, closed: bool) =
  app.closed = closed

proc pollEvents*(app: OpsWaylandApp) =
  opsWaylandPollEvents(app.display)

proc roundtrip*(app: OpsWaylandApp) =
  opsWaylandRoundtrip(app.display)

proc waitEvents*(app: OpsWaylandApp) =
  app.pollEvents()

proc configured*(app: OpsWaylandApp): bool =
  app.window != nil and opsWaylandWindowConfigured(app.window)

proc waitUntilConfigured*(app: OpsWaylandApp, maxPolls = 16) =
  app.roundtrip()
  for _ in 0 ..< maxPolls:
    if app.configured:
      break
    app.roundtrip()

proc surfaceHandle*(app: OpsWaylandApp): OpsWgpuSurfaceHandle =
  wgpuSurfaceHandle(app.display, app.window)

proc wgpuSurfaceHandle*(app: OpsWaylandApp): OpsWgpuSurfaceHandle =
  app.surfaceHandle()

proc surfaceSize*(app: OpsWaylandApp): tuple[width, height: uint32] =
  (app.surfaceWidth, app.surfaceHeight)

proc framebufferSize*(app: OpsWaylandApp): tuple[w, h: int] =
  (app.surfaceWidth.int, app.surfaceHeight.int)

proc size*(app: OpsWaylandApp): tuple[w, h: int] =
  (app.width.int, app.height.int)

proc `size=`*(app: OpsWaylandApp, size: tuple[w, h: int]) =
  app.width = size.w.float
  app.height = size.h.float
  app.surfaceWidth = size.w.uint32
  app.surfaceHeight = size.h.uint32
  if app.window != nil:
    opsWaylandSetSize(app.window, app.surfaceWidth, app.surfaceHeight)
    if app.fixedSizeHint:
      opsWaylandSetSizeLimits(
        app.window, app.surfaceWidth, app.surfaceHeight, app.surfaceWidth,
        app.surfaceHeight,
      )

proc contentScale*(app: OpsWaylandApp): tuple[xScale, yScale: float] =
  (app.scale, app.scale)

proc cursorPos*(app: OpsWaylandApp): tuple[x, y: float64] =
  (app.mouseX.float64, app.mouseY.float64)

proc `title=`*(app: OpsWaylandApp, title: string) =
  app.title = title
  if app.window != nil:
    opsWaylandSetTitle(app.window, title)

proc show*(app: OpsWaylandApp) =
  app.visible = true

proc hide*(app: OpsWaylandApp) =
  app.visible = false

proc focus*(app: OpsWaylandApp) =
  app.focused = true

proc requestAttention*(app: OpsWaylandApp) =
  discard

proc restore*(app: OpsWaylandApp) =
  discard

proc iconify*(app: OpsWaylandApp) =
  discard

proc isKeyDown*(app: OpsWaylandApp, key: Key): bool =
  discard app
  ops.isKeyDown(key)

proc mouseButtonDown*(app: OpsWaylandApp, button: MouseButton): bool =
  discard app
  case button
  of mbLeft:
    ops.mbLeftDown()
  of mbRight:
    ops.mbRightDown()
  of mbMiddle:
    ops.mbMiddleDown()
  else:
    false

proc destroy*(app: OpsWaylandApp) =
  if app.window != nil:
    opsWaylandDestroyWindow(app.window)
    app.window = nil
  if app.display != nil:
    opsWaylandDestroy(app.display)
    app.display = nil
  if gWaylandApp == app:
    gWaylandApp = nil

{.pop.}
