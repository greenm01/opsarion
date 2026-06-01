import std/strformat
import std/os

when defined(opsWgpu):
  import ops/backends/wgpu_app
else:
  import glad/gl
  import glfw

import ops/okys

import ops
import ops/rect
import example_quit

export rect

type DemoRenderProc* = proc(vg: OpsRenderContext) {.closure.}

proc loadDefaultDemoFonts(rc: OpsRenderContext) =
  let dataDir = currentSourcePath().parentDir().parentDir() / "data"
  if rc.createFont("sans", dataDir / "Roboto-Regular.ttf") == NoFont:
    quit "Could not load regular font."
  if rc.createFont("sans-bold", dataDir / "Roboto-Bold.ttf") == NoFont:
    quit "Could not load bold font."

proc runWgpuDemo*(title: string, width, height: int, render: DemoRenderProc) =
  when defined(opsWgpu):
    var config = defaultOpsWgpuAppConfig(title, width, height)
    config.shouldClose = exampleQuitShortcutDown
    runOpsWgpuApp(config, render)
  else:
    glfw.initialize()

    var cfg = DefaultOpenglWindowConfig
    cfg.size = (w: width, h: height)
    cfg.title = title
    cfg.resizable = true
    cfg.visible = true
    cfg.nMultiSamples = 4
    let win = newWindow(cfg)
    useWindow(win)

    if not gladLoadGL(glfw.getProcAddress):
      quit "Failed to load GL"

    let rc = createRenderContext({rifStencilStrokes, rifAntialias})
    rc.setupGL(sampleCount = 4)
    init(rc, glfw.getProcAddress)
    loadDefaultDemoFonts(rc)

    while not win.shouldClose:
      if shouldRenderNextFrame():
        glfw.pollEvents()
      else:
        glfw.waitEvents()
      if exampleQuitShortcutDown():
        win.shouldClose = true
        continue

      let size = win.size
      glViewport(0, 0, size.w.int32, size.h.int32)
      glClearColor(0.13, 0.15, 0.17, 1.0)
      glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)

      render(rc)
      win.swapBuffers()

    deinit()
    deleteRenderContext(rc)
    glfw.terminate()

proc handleInspectorShortcut*(wasDown: var bool) =
  let down = isKeyDown(keyF12)
  if down and not wasDown:
    toggleLayoutInspector()
  wasDown = down

proc beginDemoFrame*(
    vg: OpsRenderContext,
    title: string,
    inspectorKeyWasDown: var bool,
    background: Color = rgb(0.13, 0.15, 0.17),
) =
  handleInspectorShortcut(inspectorKeyWasDown)
  beginFrame()

  vg.beginPath()
  vg.rect(0, 0, winWidth(), winHeight())
  vg.fillColor(background)
  vg.fill()

  vg.fillColor(rgb(0.90, 0.93, 0.96))
  vg.useFont(19, "sans-bold")
  discard vg.text(24, 24, title)

  vg.fillColor(rgb(0.62, 0.68, 0.74))
  vg.useFont(12, "sans")
  discard vg.text(24, 46, fmt"F12 inspector | nodes {layoutInspectorTreeRows().len}")

proc endDemoFrame*() =
  endFrame()

proc fillRect*(vg: OpsRenderContext, r: Rect, fill, stroke: Color, strokeWidth = 1.0) =
  vg.beginPath()
  vg.roundedRect(r.x, r.y, r.w, r.h, 3)
  vg.fillColor(fill)
  vg.fill()
  vg.strokeColor(stroke)
  vg.strokeWidth(strokeWidth)
  vg.stroke()

proc drawSlotBox*(
    vg: OpsRenderContext,
    slot: LayoutSlot,
    fill, stroke: Color,
    caption: string = "",
    textColor: Color = rgb(0.92, 0.94, 0.96),
) =
  let capturedCaption = caption
  addLayoutDrawLayer(layerDefault, slot.nodeId, vg, bounds):
    vg.fillRect(bounds, fill, stroke)
    if capturedCaption.len > 0:
      vg.fillColor(textColor)
      vg.useFont(12, "sans")
      discard vg.text(bounds.x + 8, bounds.y + min(bounds.h * 0.5, 18), capturedCaption)

proc drawSlotOutline*(
    vg: OpsRenderContext, slot: LayoutSlot, stroke: Color, caption: string = ""
) =
  let capturedCaption = caption
  addLayoutDrawLayer(layerDefault, slot.nodeId, vg, bounds):
    vg.beginPath()
    vg.roundedRect(bounds.x, bounds.y, bounds.w, bounds.h, 3)
    vg.strokeColor(stroke)
    vg.strokeWidth(2)
    vg.stroke()
    if capturedCaption.len > 0:
      vg.fillColor(stroke)
      vg.useFont(12, "sans-bold")
      discard vg.text(bounds.x + 8, bounds.y + 16, capturedCaption)

proc drawMeasuredLabel*(vg: OpsRenderContext, slot: LayoutSlot, prefix: string) =
  let capturedPrefix = prefix
  addLayoutDrawLayer(layerDefault, slot.nodeId, vg, bounds):
    vg.fillColor(rgb(0.86, 0.88, 0.90))
    vg.useFont(11, "sans")
    discard vg.text(
      bounds.x + 8,
      bounds.y + bounds.h - 13,
      fmt"{capturedPrefix} {bounds.w:.0f} x {bounds.h:.0f}",
    )
