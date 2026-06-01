import std/os
import std/times

import ops/okys

import ops
import ops/backends/okys_wgpu_host

when defined(waylandBackend):
  import ops/backends/wayland_app
else:
  import std/options

  from glfw as glfwLib import nil
  import ops/backends/glfw_wgpu

type
  OpsWgpuAppConfig* = object
    title*: string
    width*: int
    height*: int
    resizable*: bool
    shouldClose*: OpsWgpuShouldCloseProc
    timeoutSecs*: float # quit after this many seconds; 0 = run forever

  OpsWgpuRenderProc* = proc(rc: OpsRenderContext) {.closure.}
  OpsWgpuShouldCloseProc* = proc(): bool {.closure.}

proc defaultOpsWgpuAppConfig*(
    title: string, width = 900, height = 600
): OpsWgpuAppConfig =
  OpsWgpuAppConfig(title: title, width: width, height: height, resizable: true)

proc configShouldClose(config: OpsWgpuAppConfig, startTime: float): bool =
  if config.shouldClose != nil and config.shouldClose():
    return true
  if config.timeoutSecs > 0 and epochTime() - startTime >= config.timeoutSecs:
    return true
  false

proc loadDefaultOpsFonts*(rc: OpsRenderContext) =
  let dataDir = currentSourcePath().parentDir().parentDir().parentDir() / "data"
  if rc.createFont("sans", dataDir / "Roboto-Regular.ttf") == NoFont:
    quit "Could not load regular font."
  if rc.createFont("sans-bold", dataDir / "Roboto-Bold.ttf") == NoFont:
    quit "Could not load bold font."

proc okysTextureFormat*(backend: OkysWgpuHost): WebGPUTextureFormat =
  case backend.okysSurfaceFormatCode()
  of 1:
    wgtfBGRA8Unorm
  of 2:
    wgtfRGBA8Unorm
  else:
    quit "Unsupported WebGPU surface format for okys."

when defined(waylandBackend):
  proc runOpsWgpuApp*(config: OpsWgpuAppConfig, render: OpsWgpuRenderProc) =
    let app = newOpsWaylandApp(config.title, config.width, config.height)
    app.updateSurfaceSize()

    var backend: OkysWgpuHost
    backend.initOkysWgpuHostWithSurface(
      app.surfaceHandle(), app.surfaceWidth, app.surfaceHeight
    )

    let rc = createRenderContext({rifSparseStrip})
    init(rc, noGlfwProcAddress)
    rc.setupWebGPU(backend.okysDeviceHandle(), backend.okysTextureFormat())
    loadDefaultOpsFonts(rc)

    let startTime = epochTime()
    while not app.shouldClose():
      app.pollEvents()
      if config.configShouldClose(startTime):
        app.shouldClose = true
        continue
      app.updateSurfaceSize()
      backend.resizeOkysWgpuHost(app.surfaceWidth, app.surfaceHeight)
      var frame = backend.beginOkysSurfaceFrame()
      if frame.colorTextureView.isNil:
        continue
      rc.setWebGPURenderTarget(
        frame.colorTextureView, frame.width.int, frame.height.int
      )
      render(rc)
      discard backend.presentOkysSurfaceFrame(frame)

    deinit()
    deleteRenderContext(rc)
    app.destroy()

else:
  proc createWgpuWindow(config: OpsWgpuAppConfig): Window =
    var cfg = defaultWgpuWindowConfig(config.title, config.width, config.height)
    cfg.size = (w: config.width, h: config.height)
    cfg.title = config.title
    cfg.resizable = config.resizable
    cfg.visible = true
    cfg.bits = (
      r: 8'i32.some,
      g: 8'i32.some,
      b: 8'i32.some,
      a: 8'i32.some,
      stencil: 8'i32.some,
      depth: 16'i32.some,
    )
    newWgpuWindow(cfg)

  proc runOpsWgpuApp*(config: OpsWgpuAppConfig, render: OpsWgpuRenderProc) =
    glfwLib.initialize()
    let win = createWgpuWindow(config)
    useWindow(win)

    let (initialWidth, initialHeight) = win.surfaceSize()

    var backend: OkysWgpuHost
    backend.initOkysWgpuHostWithSurface(
      win.wgpuSurfaceHandle(), initialWidth.uint32, initialHeight.uint32
    )

    let rc = createRenderContext({rifSparseStrip})
    init(rc, glfwLib.getProcAddress)
    rc.setupWebGPU(backend.okysDeviceHandle(), backend.okysTextureFormat())
    loadDefaultOpsFonts(rc)

    let startTime = epochTime()
    while not glfwLib.shouldClose(win):
      glfwLib.pollEvents()
      if config.configShouldClose(startTime):
        glfwLib.`shouldClose=`(win, true)
        continue
      let (surfaceWidth, surfaceHeight) = win.surfaceSize()
      backend.resizeOkysWgpuHost(surfaceWidth, surfaceHeight)
      var frame = backend.beginOkysSurfaceFrame()
      if frame.colorTextureView.isNil:
        continue
      rc.setWebGPURenderTarget(
        frame.colorTextureView, frame.width.int, frame.height.int
      )
      render(rc)
      discard backend.presentOkysSurfaceFrame(frame)

    deinit()
    deleteRenderContext(rc)
    glfwLib.destroy(win)
    glfwLib.terminate()
