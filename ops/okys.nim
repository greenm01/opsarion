# Ops renderer bindings for the okys C API.

import std/math
import std/os

# ── build paths ───────────────────────────────────────────────────────────────

const okysRoot = currentSourcePath().parentDir().parentDir().parentDir() / "okys"

{.passC: "-I" & okysRoot / "zig-out" / "include".}
{.passL: "-L" & okysRoot / "zig-out" / "lib" & " -lokys".}
when defined(opsVulkan):
  {.
    passL:
      "-L" & okysRoot / "zig-out" / "lib" & " -lsokol_clib -lasound -lvulkan -lubsan"
  .}
else:
  {.
    passL:
      "-L" & okysRoot / "zig-out" / "lib" &
      " -lsokol_clib -lasound -lGL -lX11 -lXi -lXcursor -lubsan"
  .}

# ── low-level C types (matching okys.h exactly) ───────────────────────────────

const H = "okys.h"

type
  OKYctxObj {.importc: "OKYcontext", header: H, incompleteStruct.} = object

  OKYcolor {.importc: "OKYcolor", header: H, bycopy, union.} = object
    rgba {.importc: "rgba".}: array[4, cfloat]

  OKYpaint {.importc: "OKYpaint", header: H, bycopy.} = object
    xform {.importc: "xform".}: array[6, cfloat]
    extent {.importc: "extent".}: array[2, cfloat]
    radius {.importc: "radius".}: cfloat
    feather {.importc: "feather".}: cfloat
    inner_color {.importc: "inner_color".}: OKYcolor
    outer_color {.importc: "outer_color".}: OKYcolor
    image {.importc: "image".}: cint

  OKYglyphPos {.importc: "OKYglyphPosition", header: H, bycopy.} = object
    str {.importc: "str".}: cstring
    x {.importc: "x".}: cfloat
    minx {.importc: "minx".}: cfloat
    maxx {.importc: "maxx".}: cfloat

  OKYtextRow {.importc: "OKYtextRow", header: H, bycopy.} = object
    start {.importc: "start".}: cstring
    `end` {.importc: "end".}: cstring
    next {.importc: "next".}: cstring
    width {.importc: "width".}: cfloat
    minx {.importc: "minx".}: cfloat
    maxx {.importc: "maxx".}: cfloat

  OKYgraphicsDesc {.importc: "OKYgraphicsDesc", header: H, bycopy.} = object
    backend {.importc: "backend".}: cint
    colorFormat {.importc: "color_format".}: cint
    depthFormat {.importc: "depth_format".}: cint
    sampleCount {.importc: "sample_count".}: cint
    metalDevice {.importc: "metal_device".}: pointer
    d3d11Device {.importc: "d3d11_device".}: pointer
    d3d11DeviceContext {.importc: "d3d11_device_context".}: pointer
    vulkanInstance {.importc: "vulkan_instance".}: pointer
    vulkanPhysicalDevice {.importc: "vulkan_physical_device".}: pointer
    vulkanDevice {.importc: "vulkan_device".}: pointer
    vulkanQueue {.importc: "vulkan_queue".}: pointer
    vulkanQueueFamilyIndex {.importc: "vulkan_queue_family_index".}: uint32
    webgpuDevice {.importc: "webgpu_device".}: pointer

  OKYrenderTarget {.importc: "OKYrenderTarget", header: H, bycopy.} = object
    backend {.importc: "backend".}: cint
    widthPx {.importc: "width_px".}: cint
    heightPx {.importc: "height_px".}: cint
    colorFormat {.importc: "color_format".}: cint
    depthFormat {.importc: "depth_format".}: cint
    sampleCount {.importc: "sample_count".}: cint
    glFramebuffer {.importc: "gl_framebuffer".}: uint32
    metalCurrentDrawable {.importc: "metal_current_drawable".}: pointer
    metalDepthStencilTexture {.importc: "metal_depth_stencil_texture".}: pointer
    metalMsaaColorTexture {.importc: "metal_msaa_color_texture".}: pointer
    d3d11RenderView {.importc: "d3d11_render_view".}: pointer
    d3d11ResolveView {.importc: "d3d11_resolve_view".}: pointer
    d3d11DepthStencilView {.importc: "d3d11_depth_stencil_view".}: pointer
    vulkanRenderImage {.importc: "vulkan_render_image".}: pointer
    vulkanRenderView {.importc: "vulkan_render_view".}: pointer
    vulkanResolveImage {.importc: "vulkan_resolve_image".}: pointer
    vulkanResolveView {.importc: "vulkan_resolve_view".}: pointer
    vulkanDepthStencilImage {.importc: "vulkan_depth_stencil_image".}: pointer
    vulkanDepthStencilView {.importc: "vulkan_depth_stencil_view".}: pointer
    vulkanRenderFinishedSemaphore {.importc: "vulkan_render_finished_semaphore".}:
      pointer
    vulkanPresentCompleteSemaphore {.importc: "vulkan_present_complete_semaphore".}:
      pointer
    webgpuRenderView {.importc: "webgpu_render_view".}: pointer
    webgpuResolveView {.importc: "webgpu_resolve_view".}: pointer
    webgpuDepthStencilView {.importc: "webgpu_depth_stencil_view".}: pointer

# ── low-level C proc imports ──────────────────────────────────────────────────

proc okyCreate(flags: cint): ptr OKYctxObj {.importc, header: H.}
proc okyDelete(ctx: ptr OKYctxObj) {.importc, header: H.}
proc okyBeginFrame(ctx: ptr OKYctxObj, w, h, dpr: cfloat) {.importc, header: H.}
proc okyEndFrame(ctx: ptr OKYctxObj) {.importc, header: H.}
proc okyCancelFrame(ctx: ptr OKYctxObj) {.importc, header: H.}
proc okySetupGL(ctx: ptr OKYctxObj, sampleCount: cint): cint {.importc, header: H.}
proc okySetupGraphics(
  ctx: ptr OKYctxObj, desc: ptr OKYgraphicsDesc
): cint {.importc, header: H.}

proc okySetRenderTarget(
  ctx: ptr OKYctxObj, target: ptr OKYrenderTarget
): cint {.importc, header: H.}

proc okySetupVulkan(
  ctx: ptr OKYctxObj,
  vulkanInstance: pointer,
  vulkanPhysicalDevice: pointer,
  vulkanDevice: pointer,
  vulkanQueue: pointer,
  vulkanQueueFamilyIndex: uint32,
  colorFormat: cint,
): cint {.importc, header: H.}

proc okySetupVulkanWithDepth(
  ctx: ptr OKYctxObj,
  vulkanInstance: pointer,
  vulkanPhysicalDevice: pointer,
  vulkanDevice: pointer,
  vulkanQueue: pointer,
  vulkanQueueFamilyIndex: uint32,
  colorFormat, depthFormat: cint,
): cint {.importc, header: H.}

proc okySetVulkanRenderTarget(
  ctx: ptr OKYctxObj,
  renderImage: pointer,
  renderView: pointer,
  renderFinishedSemaphore: pointer,
  presentCompleteSemaphore: pointer,
  widthPx, heightPx: cint,
  colorFormat: cint,
): cint {.importc, header: H.}

proc okySetVulkanRenderTargetWithDepth(
  ctx: ptr OKYctxObj,
  renderImage: pointer,
  renderView: pointer,
  depthStencilImage: pointer,
  depthStencilView: pointer,
  renderFinishedSemaphore: pointer,
  presentCompleteSemaphore: pointer,
  widthPx, heightPx: cint,
  colorFormat, depthFormat: cint,
): cint {.importc, header: H.}

proc okySetupWebGPU(
  ctx: ptr OKYctxObj, wgpuDevice: pointer, colorFormat: cint
) {.importc, header: H.}

proc okySetupWebGPUWithDepth(
  ctx: ptr OKYctxObj, wgpuDevice: pointer, colorFormat, depthFormat: cint
) {.importc, header: H.}

proc okySetWebGPURenderTarget(
  ctx: ptr OKYctxObj, colorTextureView: pointer, widthPx, heightPx: cint
) {.importc, header: H.}

proc okySetWebGPURenderTargetWithDepth(
  ctx: ptr OKYctxObj,
  colorTextureView: pointer,
  depthStencilTextureView: pointer,
  widthPx, heightPx: cint,
) {.importc, header: H.}

proc okySave(ctx: ptr OKYctxObj) {.importc, header: H.}
proc okyRestore(ctx: ptr OKYctxObj) {.importc, header: H.}
proc okyReset(ctx: ptr OKYctxObj) {.importc, header: H.}

proc okyStrokeWidth(ctx: ptr OKYctxObj, width: cfloat) {.importc, header: H.}
proc okyMiterLimit(ctx: ptr OKYctxObj, limit: cfloat) {.importc, header: H.}
proc okyLineCap(ctx: ptr OKYctxObj, cap: cint) {.importc, header: H.}
proc okyLineJoin(ctx: ptr OKYctxObj, join: cint) {.importc, header: H.}
proc okyLineDash(
  ctx: ptr OKYctxObj, pattern: ptr cfloat, count: cint
) {.importc, header: H.}

proc okyLineDashOffset(ctx: ptr OKYctxObj, offset: cfloat) {.importc, header: H.}
proc okyGlobalAlpha(ctx: ptr OKYctxObj, alpha: cfloat) {.importc, header: H.}

proc okyResetTransform(ctx: ptr OKYctxObj) {.importc, header: H.}
proc okyTransform(ctx: ptr OKYctxObj, a, b, c, d, e, f: cfloat) {.importc, header: H.}
proc okyTranslate(ctx: ptr OKYctxObj, x, y: cfloat) {.importc, header: H.}
proc okyRotate(ctx: ptr OKYctxObj, angle: cfloat) {.importc, header: H.}
proc okyScale(ctx: ptr OKYctxObj, x, y: cfloat) {.importc, header: H.}
proc okySkewX(ctx: ptr OKYctxObj, angle: cfloat) {.importc, header: H.}
proc okySkewY(ctx: ptr OKYctxObj, angle: cfloat) {.importc, header: H.}
proc okyCurrentTransform(ctx: ptr OKYctxObj, dst: ptr cfloat) {.importc, header: H.}

proc okyRGBAf(r, g, b, a: cfloat): OKYcolor {.importc, header: H.}

proc okyFillColor(ctx: ptr OKYctxObj, color: OKYcolor) {.importc, header: H.}
proc okyStrokeColor(ctx: ptr OKYctxObj, color: OKYcolor) {.importc, header: H.}
proc okyFillPaint(ctx: ptr OKYctxObj, paint: OKYpaint) {.importc, header: H.}
proc okyStrokePaint(ctx: ptr OKYctxObj, paint: OKYpaint) {.importc, header: H.}
proc okyLinearGradient(
  ctx: ptr OKYctxObj, sx, sy, ex, ey: cfloat, inner, outer: OKYcolor
): OKYpaint {.importc, header: H.}

proc okyRadialGradient(
  ctx: ptr OKYctxObj, cx, cy, inr, outr: cfloat, inner, outer: OKYcolor
): OKYpaint {.importc, header: H.}

proc okyBoxGradient(
  ctx: ptr OKYctxObj, x, y, w, h, radius, feather: cfloat, inner, outer: OKYcolor
): OKYpaint {.importc, header: H.}

proc okyImagePattern(
  ctx: ptr OKYctxObj, ox, oy, ex, ey, angle: cfloat, image: cint, alpha: cfloat
): OKYpaint {.importc, header: H.}

proc okyCreateImageRGBA(
  ctx: ptr OKYctxObj, w, h: cint, data: ptr uint8
): cint {.importc, header: H.}

proc okyCreateImageRGBAEx(
  ctx: ptr OKYctxObj, w, h: cint, data: ptr uint8, strideBytes, flags: cint
): cint {.importc, header: H.}

proc okyUpdateImage(
  ctx: ptr OKYctxObj, image: cint, data: ptr uint8
) {.importc, header: H.}

proc okyDrawImage(
  ctx: ptr OKYctxObj, x, y, w, h: cfloat, image: cint, alpha: cfloat
) {.importc, header: H.}

proc okyImageSize(
  ctx: ptr OKYctxObj, image: cint, w, h: ptr cint
) {.importc, header: H.}

proc okyDeleteImage(ctx: ptr OKYctxObj, image: cint) {.importc, header: H.}

proc okyScissor(ctx: ptr OKYctxObj, x, y, w, h: cfloat) {.importc, header: H.}
proc okyIntersectScissor(ctx: ptr OKYctxObj, x, y, w, h: cfloat) {.importc, header: H.}
proc okyResetScissor(ctx: ptr OKYctxObj) {.importc, header: H.}

proc okyBeginPath(ctx: ptr OKYctxObj) {.importc, header: H.}
proc okyMoveTo(ctx: ptr OKYctxObj, x, y: cfloat) {.importc, header: H.}
proc okyLineTo(ctx: ptr OKYctxObj, x, y: cfloat) {.importc, header: H.}
proc okyBezierTo(
  ctx: ptr OKYctxObj, c1x, c1y, c2x, c2y, x, y: cfloat
) {.importc, header: H.}

proc okyQuadTo(ctx: ptr OKYctxObj, cx, cy, x, y: cfloat) {.importc, header: H.}
proc okyArcTo(ctx: ptr OKYctxObj, x1, y1, x2, y2, radius: cfloat) {.importc, header: H.}
proc okyClosePath(ctx: ptr OKYctxObj) {.importc, header: H.}
proc okyPathWinding(ctx: ptr OKYctxObj, dir: cint) {.importc, header: H.}
proc okyArc(
  ctx: ptr OKYctxObj, cx, cy, r, a0, a1: cfloat, dir: cint
) {.importc, header: H.}

proc okyRect(ctx: ptr OKYctxObj, x, y, w, h: cfloat) {.importc, header: H.}
proc okyRoundedRect(
  ctx: ptr OKYctxObj, x, y, w, h, radius: cfloat
) {.importc, header: H.}

proc okyRoundedRectVarying(
  ctx: ptr OKYctxObj, x, y, w, h, rtl, rtr, rbr, rbl: cfloat
) {.importc, header: H.}

proc okyEllipse(ctx: ptr OKYctxObj, cx, cy, rx, ry: cfloat) {.importc, header: H.}
proc okyCircle(ctx: ptr OKYctxObj, cx, cy, r: cfloat) {.importc, header: H.}

proc okyFill(ctx: ptr OKYctxObj) {.importc, header: H.}
proc okyStroke(ctx: ptr OKYctxObj) {.importc, header: H.}

proc okyCreateFont(
  ctx: ptr OKYctxObj, name: cstring, filename: cstring
): cint {.importc, header: H.}

proc okyCreateFontMem(
  ctx: ptr OKYctxObj, name: cstring, data: ptr uint8, ndata: cint, freeData: cint
): cint {.importc, header: H.}

proc okyFindFont(ctx: ptr OKYctxObj, name: cstring): cint {.importc, header: H.}
proc okyFontSize(ctx: ptr OKYctxObj, size: cfloat) {.importc, header: H.}
proc okyFontFaceId(ctx: ptr OKYctxObj, font: cint) {.importc, header: H.}
proc okyFontFace(ctx: ptr OKYctxObj, font: cstring) {.importc, header: H.}
proc okyTextAlign(ctx: ptr OKYctxObj, align: cint) {.importc, header: H.}
proc okyTextLetterSpacingRaw(
  ctx: ptr OKYctxObj, spacing: cfloat
) {.importc: "okyTextLetterSpacing", header: H.}

proc okyTextLineHeightRaw(
  ctx: ptr OKYctxObj, lineHeight: cfloat
) {.importc: "okyTextLineHeight", header: H.}

proc okyText(
  ctx: ptr OKYctxObj, x, y: cfloat, str: cstring, `end`: cstring
): cfloat {.importc, header: H.}

proc okyTextBox(
  ctx: ptr OKYctxObj, x, y, breakRowWidth: cfloat, str: cstring, `end`: cstring
) {.importc, header: H.}

proc okyTextBounds(
  ctx: ptr OKYctxObj, x, y: cfloat, str: cstring, `end`: cstring, bounds: ptr cfloat
): cfloat {.importc, header: H.}

proc okyTextGlyphPositions(
  ctx: ptr OKYctxObj,
  x, y: cfloat,
  str: cstring,
  `end`: cstring,
  positions: ptr OKYglyphPos,
  maxPositions: cint,
): cint {.importc, header: H.}

proc okyTextMetrics(
  ctx: ptr OKYctxObj, ascender, descender, lineh: ptr cfloat
) {.importc, header: H.}

proc okyTextBreakLines(
  ctx: ptr OKYctxObj,
  str: cstring,
  `end`: cstring,
  breakRowWidth: cfloat,
  rows: ptr OKYtextRow,
  maxRows: cint,
): cint {.importc, header: H.}

# ── public renderer types ─────────────────────────────────────────────────────

type
  OpsRenderContext* = ptr OKYctxObj

  Font* = distinct cint
  Image* = distinct cint

  # Binary-compatible with OKYcolor (r, g, b, a each cfloat).
  Color* {.byCopy.} = object
    r*, g*, b*, a*: cfloat

  # Binary-compatible with OKYpaint (76 bytes).
  Paint* {.byCopy.} = object
    xform*: array[6, cfloat]
    extent*: array[2, cfloat]
    radius*: cfloat
    feather*: cfloat
    innerColor*: Color
    outerColor*: Color
    image*: Image

  # Binary-compatible with OKYglyphPosition (cstring + 3 cfloat).
  # Field names keep the existing Ops text-layout ABI spelling.
  GlyphPosition* {.byCopy.} = object
    str*: cstring
    x*: cfloat
    minX*: cfloat
    maxX*: cfloat

  TransformMatrix* = object
    m*: array[6, cfloat]

  Bounds* {.byCopy.} = object
    x1*, y1*, x2*, y2*: cfloat

  HorizontalAlign* = enum
    haLeft = (1 shl 0, "Left")
    haCenter = (1 shl 1, "Center")
    haRight = (1 shl 2, "Right")

  VerticalAlign* = enum
    vaTop = (1 shl 3, "Top")
    vaMiddle = (1 shl 4, "Middle")
    vaBottom = (1 shl 5, "Bottom")
    vaBaseline = (1 shl 6, "Baseline")

  LineCapJoin* = enum
    lcjButt = (0, "Butt")
    lcjRound = (1, "Round")
    lcjSquare = (2, "Square")
    lcjBevel = (3, "Bevel")
    lcjMiter = (4, "Miter")

  PathWinding* = enum
    pwCCW = (1, "CCW")
    pwCW = (2, "CW")

  Solidity* = enum
    sSolid = (1, "Solid")
    sHole = (2, "Hole")

  ImageFlags* = enum
    ifGenerateMipmaps = (1 shl 0, "GenerateMipmaps")
    ifRepeatX = (1 shl 1, "RepeatX")
    ifRepeatY = (1 shl 2, "RepeatY")
    ifFlipY = (1 shl 3, "FlipY")
    ifPremultiplied = (1 shl 4, "Premultiplied")
    ifNearest = (1 shl 5, "Nearest")

  RenderInitFlag* = enum
    rifAntialias = 0 # → OKY_ANTIALIAS       (bit 0 = 1)
    rifStencilStrokes = 1 # → OKY_STENCIL_STROKES  (bit 1 = 2)
    rifSparseStrip = 2 # → OKY_SPARSE_STRIP     (bit 2 = 4)
    rifDebug = 3 # no okys flag at bit 3; silently ignored

  WebGPUTextureFormat* = enum
    wgtfNone = 0
    wgtfBGRA8Unorm = 1
    wgtfRGBA8Unorm = 2
    wgtfDepthStencil = 3

  GraphicsBackend* = enum
    gbGL = 1
    gbMetal = 2
    gbD3D11 = 3
    gbVulkan = 4
    gbWebGPU = 5

var
  NoFont* = Font(-1)
  NoImage* = Image(0)

proc `==`*(x, y: Font): bool {.borrow.}
proc `==`*(x, y: Image): bool {.borrow.}

# ── type converters ───────────────────────────────────────────────────────────

func toOky(c: Color): OKYcolor {.inline.} =
  OKYcolor(rgba: [c.r, c.g, c.b, c.a])

func toNim(c: OKYcolor): Color {.inline.} =
  Color(r: c.rgba[0], g: c.rgba[1], b: c.rgba[2], a: c.rgba[3])

func toOky(p: Paint): OKYpaint {.inline.} =
  OKYpaint(
    xform: p.xform,
    extent: p.extent,
    radius: p.radius,
    feather: p.feather,
    inner_color: p.innerColor.toOky,
    outer_color: p.outerColor.toOky,
    image: p.image.cint,
  )

func toNim(p: OKYpaint): Paint {.inline.} =
  Paint(
    xform: p.xform,
    extent: p.extent,
    radius: p.radius,
    feather: p.feather,
    innerColor: p.inner_color.toNim,
    outerColor: p.outer_color.toNim,
    image: Image(p.image),
  )

# ── context lifecycle ─────────────────────────────────────────────────────────

proc createRenderContext*(flags: set[RenderInitFlag] = {}): OpsRenderContext =
  let ctx = okyCreate(cast[cint](flags))
  if ctx == nil:
    raise newException(CatchableError, "Failed to create okys context")
  ctx

proc deleteRenderContext*(ctx: OpsRenderContext) =
  okyDelete(ctx)

# ── frame ─────────────────────────────────────────────────────────────────────

proc beginFrame*(
    ctx: OpsRenderContext, windowWidth, windowHeight, devicePixelRatio: float
) =
  okyBeginFrame(ctx, windowWidth.cfloat, windowHeight.cfloat, devicePixelRatio.cfloat)

proc endFrame*(ctx: OpsRenderContext) =
  okyEndFrame(ctx)

proc cancelFrame*(ctx: OpsRenderContext) =
  okyCancelFrame(ctx)

proc setupGL*(ctx: OpsRenderContext, sampleCount = 1) =
  if okySetupGL(ctx, sampleCount.cint) == 0:
    raise newException(CatchableError, "Failed to setup okys OpenGL backend")

proc setupVulkan*(
    ctx: OpsRenderContext,
    instance, physicalDevice, device, queue: pointer,
    queueFamilyIndex: uint32,
    colorFormat: WebGPUTextureFormat,
    depthFormat: WebGPUTextureFormat = wgtfDepthStencil,
) =
  let ok =
    if depthFormat == wgtfNone:
      okySetupVulkan(
        ctx, instance, physicalDevice, device, queue, queueFamilyIndex, colorFormat.cint
      )
    else:
      okySetupVulkanWithDepth(
        ctx, instance, physicalDevice, device, queue, queueFamilyIndex,
        colorFormat.cint, depthFormat.cint,
      )
  if ok == 0:
    raise newException(CatchableError, "Failed to setup okys Vulkan backend")

proc setupWebGPU*(
    ctx: OpsRenderContext,
    device: pointer,
    colorFormat: WebGPUTextureFormat,
    depthFormat: WebGPUTextureFormat = wgtfNone,
) =
  if depthFormat == wgtfNone:
    okySetupWebGPU(ctx, device, colorFormat.cint)
  else:
    okySetupWebGPUWithDepth(ctx, device, colorFormat.cint, depthFormat.cint)

proc setWebGPURenderTarget*(
    ctx: OpsRenderContext, colorTextureView: pointer, widthPx, heightPx: int
) =
  okySetWebGPURenderTarget(ctx, colorTextureView, widthPx.cint, heightPx.cint)

proc setWebGPURenderTarget*(
    ctx: OpsRenderContext,
    colorTextureView: pointer,
    depthStencilTextureView: pointer,
    widthPx, heightPx: int,
) =
  okySetWebGPURenderTargetWithDepth(
    ctx, colorTextureView, depthStencilTextureView, widthPx.cint, heightPx.cint
  )

proc setVulkanRenderTarget*(
    ctx: OpsRenderContext,
    renderImage, renderView: pointer,
    depthStencilImage, depthStencilView: pointer,
    renderFinishedSemaphore, presentCompleteSemaphore: pointer,
    widthPx, heightPx: int,
    colorFormat: WebGPUTextureFormat,
    depthFormat: WebGPUTextureFormat = wgtfDepthStencil,
) =
  let ok =
    if depthFormat == wgtfNone:
      okySetVulkanRenderTarget(
        ctx, renderImage, renderView, renderFinishedSemaphore, presentCompleteSemaphore,
        widthPx.cint, heightPx.cint, colorFormat.cint,
      )
    else:
      okySetVulkanRenderTargetWithDepth(
        ctx, renderImage, renderView, depthStencilImage, depthStencilView,
        renderFinishedSemaphore, presentCompleteSemaphore, widthPx.cint, heightPx.cint,
        colorFormat.cint, depthFormat.cint,
      )
  if ok == 0:
    raise newException(CatchableError, "Failed to set okys Vulkan render target")

# ── state stack ───────────────────────────────────────────────────────────────

proc save*(ctx: OpsRenderContext) =
  okySave(ctx)

proc restore*(ctx: OpsRenderContext) =
  okyRestore(ctx)

proc reset*(ctx: OpsRenderContext) =
  okyReset(ctx)

# ── style ─────────────────────────────────────────────────────────────────────

proc strokeWidth*(ctx: OpsRenderContext, width: float) =
  okyStrokeWidth(ctx, width.cfloat)

proc miterLimit*(ctx: OpsRenderContext, limit: float) =
  okyMiterLimit(ctx, limit.cfloat)

proc lineCap*(ctx: OpsRenderContext, cap: LineCapJoin) =
  okyLineCap(ctx, cap.cint) # lcjButt=0, lcjRound=1, lcjSquare=2 map directly

proc lineJoin*(ctx: OpsRenderContext, join: LineCapJoin) =
  let j: cint =
    case join
    of lcjMiter: 0
    of lcjRound: 1
    of lcjBevel: 2
    else: 0
  okyLineJoin(ctx, j)

proc lineDash*(ctx: OpsRenderContext, pattern: openArray[float]) =
  if pattern.len == 0:
    okyLineDash(ctx, nil, 0)
    return
  var values: array[16, cfloat]
  let count = min(pattern.len, values.len)
  for i in 0 ..< count:
    values[i] = pattern[i].cfloat
  okyLineDash(ctx, values[0].addr, count.cint)

proc lineDashOffset*(ctx: OpsRenderContext, offset: float) =
  okyLineDashOffset(ctx, offset.cfloat)

proc globalAlpha*(ctx: OpsRenderContext, alpha: float) =
  okyGlobalAlpha(ctx, alpha.cfloat)

# ── transforms ────────────────────────────────────────────────────────────────

proc resetTransform*(ctx: OpsRenderContext) =
  okyResetTransform(ctx)

proc transform*(ctx: OpsRenderContext, a, b, c, d, e, f: float) =
  okyTransform(ctx, a.cfloat, b.cfloat, c.cfloat, d.cfloat, e.cfloat, f.cfloat)

proc translate*(ctx: OpsRenderContext, x, y: float) =
  okyTranslate(ctx, x.cfloat, y.cfloat)

proc rotate*(ctx: OpsRenderContext, angle: float) =
  okyRotate(ctx, angle.cfloat)

proc scale*(ctx: OpsRenderContext, x, y: float) =
  okyScale(ctx, x.cfloat, y.cfloat)

proc skewX*(ctx: OpsRenderContext, angle: float) =
  okySkewX(ctx, angle.cfloat)

proc skewY*(ctx: OpsRenderContext, angle: float) =
  okySkewY(ctx, angle.cfloat)

proc currentTransform*(ctx: OpsRenderContext): TransformMatrix =
  okyCurrentTransform(ctx, result.m[0].addr)

# ── color utilities ───────────────────────────────────────────────────────────

func clampByte(i: int): byte =
  clamp(i, 0, 255).byte

func rgb*(r, g, b: int): Color =
  Color(
    r: clampByte(r).float32 / 255,
    g: clampByte(g).float32 / 255,
    b: clampByte(b).float32 / 255,
    a: 1,
  )

func rgb*(r, g, b: float): Color =
  Color(r: r.cfloat, g: g.cfloat, b: b.cfloat, a: 1)

func rgba*(r, g, b, a: int): Color =
  Color(
    r: clampByte(r).float32 / 255,
    g: clampByte(g).float32 / 255,
    b: clampByte(b).float32 / 255,
    a: clampByte(a).float32 / 255,
  )

func rgba*(r, g, b, a: float): Color =
  Color(r: r.cfloat, g: g.cfloat, b: b.cfloat, a: a.cfloat)

template gray*(g: float, a: float = 1.0): Color =
  rgba(g, g, g, a)

template gray*(g: int, a: int = 255): Color =
  rgba(g, g, g, a)

template black*(a: float = 1.0): Color =
  gray(0.0, a)

template black*(a: int): Color =
  black(a / 255)

template white*(a: float = 1.0): Color =
  gray(1.0, a)

template white*(a: int): Color =
  white(a / 255)

template red*(a: float = 1.0): Color =
  rgba(1.0, 0.0, 0.0, a)

template red*(a: int): Color =
  red(a / 255)

template green*(a: float = 1.0): Color =
  rgba(0.0, 1.0, 0.0, a)

template green*(a: int): Color =
  green(a / 255)

template blue*(a: float = 1.0): Color =
  rgba(0.0, 0.0, 1.0, a)

template blue*(a: int): Color =
  blue(a / 255)

template cyan*(a: float = 1.0): Color =
  rgba(0.0, 1.0, 1.0, a)

template cyan*(a: int): Color =
  cyan(a / 255)

template magenta*(a: float = 1.0): Color =
  rgba(1.0, 0.0, 1.0, a)

template magenta*(a: int): Color =
  magenta(a / 255)

template yellow*(a: float = 1.0): Color =
  rgba(1.0, 1.0, 0.0, a)

template yellow*(a: int): Color =
  yellow(a / 255)

func lerp*(c1, c2: Color, f: float): Color =
  let t = f.cfloat
  Color(
    r: c1.r + (c2.r - c1.r) * t,
    g: c1.g + (c2.g - c1.g) * t,
    b: c1.b + (c2.b - c1.b) * t,
    a: c1.a + (c2.a - c1.a) * t,
  )

func withAlpha*(c: Color, a: byte): Color =
  Color(r: c.r, g: c.g, b: c.b, a: a.float32 / 255)

func withAlpha*(c: Color, a: float): Color =
  Color(r: c.r, g: c.g, b: c.b, a: a.cfloat)

func hslToRgb(h, s, l: float): (float, float, float) =
  if s == 0.0:
    return (l, l, l)
  func hue2rgb(p, q, t: float): float =
    var tt = t
    if tt < 0:
      tt += 1
    if tt > 1:
      tt -= 1
    if tt < 1 / 6:
      return p + (q - p) * 6 * tt
    if tt < 1 / 2:
      return q
    if tt < 2 / 3:
      return p + (q - p) * (2 / 3 - tt) * 6
    p
  let q =
    if l < 0.5:
      l * (1 + s)
    else:
      l + s - l * s
  let p = 2 * l - q
  (hue2rgb(p, q, h + 1 / 3), hue2rgb(p, q, h), hue2rgb(p, q, h - 1 / 3))

func toHSV*(c: Color): (float, float, float) =
  let
    r = c.r.float
    g = c.g.float
    b = c.b.float
    xmax = max(r, max(g, b))
    xmin = min(r, min(g, b))
    v = xmax
    chroma = xmax - xmin
  let h =
    if chroma == 0:
      0.0
    elif v == r:
      ((60 * (g - b) / chroma + 360) mod 360) / 360
    elif v == g:
      ((60 * (b - r) / chroma + 120) mod 360) / 360
    else:
      ((60 * (r - g) / chroma + 240) mod 360) / 360
  let s =
    if v == 0.0:
      0.0
    else:
      chroma / v
  (h, s, v)

func hsva*(h, s, v, a: float): Color =
  var r, g, b: float
  if s == 0.0:
    r = v
    g = v
    b = v
  else:
    let hf =
      if h >= 1.0:
        0.0
      else:
        h * 6
    let i = hf.int
    let f = hf - i.float
    let m = v * (1 - s)
    let n = v * (1 - s * f)
    let k = v * (1 - s * (1 - f))
    (r, g, b) =
      if i == 0:
        (v, k, m)
      elif i == 1:
        (n, v, m)
      elif i == 2:
        (m, v, k)
      elif i == 3:
        (m, n, v)
      elif i == 4:
        (k, m, v)
      else:
        (v, m, n)
  rgba(r, g, b, a)

func luma*(c: Color): float =
  c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722

func isLight*(c: Color): bool =
  c.luma > 0.179
func isDark*(c: Color): bool =
  not c.isLight

func weightedEuclidanDistance*(c: Color): float =
  sqrt(c.r * c.r * 0.299 + c.g * c.g * 0.587 + c.b * c.b * 0.114)

func isLightEuclidan*(c: Color): bool =
  weightedEuclidanDistance(c) > 0.7
func isDarkEuclidan*(c: Color): bool =
  not c.isLightEuclidan

func hsl*(h, s, l: float): Color =
  let (r, g, b) = hslToRgb(h, s, l)
  Color(r: r.cfloat, g: g.cfloat, b: b.cfloat, a: 1)

func hsla*(h, s, l: float, a: float): Color =
  let (r, g, b) = hslToRgb(h, s, l)
  Color(r: r.cfloat, g: g.cfloat, b: b.cfloat, a: a.cfloat)

func hsla*(h, s, l: float, a: byte): Color =
  hsla(h, s, l, a.float / 255)

# ── paints ────────────────────────────────────────────────────────────────────

proc fillColor*(ctx: OpsRenderContext, color: Color) =
  okyFillColor(ctx, color.toOky)

proc strokeColor*(ctx: OpsRenderContext, color: Color) =
  okyStrokeColor(ctx, color.toOky)

proc fillPaint*(ctx: OpsRenderContext, paint: Paint) =
  okyFillPaint(ctx, paint.toOky)

proc strokePaint*(ctx: OpsRenderContext, paint: Paint) =
  okyStrokePaint(ctx, paint.toOky)

proc linearGradient*(
    ctx: OpsRenderContext, sx, sy, ex, ey: float, inCol, outCol: Color
): Paint =
  okyLinearGradient(
    ctx, sx.cfloat, sy.cfloat, ex.cfloat, ey.cfloat, inCol.toOky, outCol.toOky
  ).toNim

proc radialGradient*(
    ctx: OpsRenderContext, cx, cy, inr, outr: float, inCol, outCol: Color
): Paint =
  okyRadialGradient(
    ctx, cx.cfloat, cy.cfloat, inr.cfloat, outr.cfloat, inCol.toOky, outCol.toOky
  ).toNim

proc boxGradient*(
    ctx: OpsRenderContext, x, y, w, h, r, f: float, inCol, outCol: Color
): Paint =
  okyBoxGradient(
    ctx, x.cfloat, y.cfloat, w.cfloat, h.cfloat, r.cfloat, f.cfloat, inCol.toOky,
    outCol.toOky,
  ).toNim

proc imagePattern*(
    ctx: OpsRenderContext, ox, oy, ex, ey, angle: float, image: Image, alpha: float
): Paint =
  okyImagePattern(
    ctx, ox.cfloat, oy.cfloat, ex.cfloat, ey.cfloat, angle.cfloat, image.cint,
    alpha.cfloat,
  ).toNim

# ── images ────────────────────────────────────────────────────────────────────

proc createImageRGBA*(
    ctx: OpsRenderContext, w, h: int, imageFlags: set[ImageFlags] = {}, data: ptr byte
): Image =
  Image(okyCreateImageRGBA(ctx, w.cint, h.cint, cast[ptr uint8](data)))

proc createImageRGBAEx*(
    ctx: OpsRenderContext, w, h: int, data: ptr byte, strideBytes = 0, flags = 0
): Image =
  Image(
    okyCreateImageRGBAEx(
      ctx, w.cint, h.cint, cast[ptr uint8](data), strideBytes.cint, flags.cint
    )
  )

proc updateImage*(ctx: OpsRenderContext, image: Image, data: ptr byte) =
  okyUpdateImage(ctx, image.cint, cast[ptr uint8](data))

proc drawImage*(ctx: OpsRenderContext, image: Image, x, y, w, h: float, alpha = 1.0) =
  okyDrawImage(ctx, x.cfloat, y.cfloat, w.cfloat, h.cfloat, image.cint, alpha.cfloat)

proc imageSize*(ctx: OpsRenderContext, image: Image): tuple[w, h: int] =
  var w, h: cint
  okyImageSize(ctx, image.cint, w.addr, h.addr)
  (w.int, h.int)

proc deleteImage*(ctx: OpsRenderContext, image: Image) =
  okyDeleteImage(ctx, image.cint)

# ── scissor ───────────────────────────────────────────────────────────────────

proc scissor*(ctx: OpsRenderContext, x, y, w, h: float) =
  okyScissor(ctx, x.cfloat, y.cfloat, w.cfloat, h.cfloat)

proc intersectScissor*(ctx: OpsRenderContext, x, y, w, h: float) =
  okyIntersectScissor(ctx, x.cfloat, y.cfloat, w.cfloat, h.cfloat)

proc resetScissor*(ctx: OpsRenderContext) =
  okyResetScissor(ctx)

# ── path building ─────────────────────────────────────────────────────────────

proc beginPath*(ctx: OpsRenderContext) =
  okyBeginPath(ctx)

proc moveTo*(ctx: OpsRenderContext, x, y: float) =
  okyMoveTo(ctx, x.cfloat, y.cfloat)

proc lineTo*(ctx: OpsRenderContext, x, y: float) =
  okyLineTo(ctx, x.cfloat, y.cfloat)

proc bezierTo*(ctx: OpsRenderContext, c1x, c1y, c2x, c2y, x, y: float) =
  okyBezierTo(ctx, c1x.cfloat, c1y.cfloat, c2x.cfloat, c2y.cfloat, x.cfloat, y.cfloat)

proc quadTo*(ctx: OpsRenderContext, cx, cy, x, y: float) =
  okyQuadTo(ctx, cx.cfloat, cy.cfloat, x.cfloat, y.cfloat)

proc arcTo*(ctx: OpsRenderContext, x1, y1, x2, y2, radius: float) =
  okyArcTo(ctx, x1.cfloat, y1.cfloat, x2.cfloat, y2.cfloat, radius.cfloat)

proc closePath*(ctx: OpsRenderContext) =
  okyClosePath(ctx)

proc pathWinding*(ctx: OpsRenderContext, dir: PathWinding | Solidity) =
  okyPathWinding(ctx, ord(dir).cint)

proc arc*(ctx: OpsRenderContext, cx, cy, r, a0, a1: float, dir: PathWinding) =
  okyArc(ctx, cx.cfloat, cy.cfloat, r.cfloat, a0.cfloat, a1.cfloat, ord(dir).cint)

proc rect*(ctx: OpsRenderContext, x, y, w, h: float) =
  okyRect(ctx, x.cfloat, y.cfloat, w.cfloat, h.cfloat)

proc roundedRect*(ctx: OpsRenderContext, x, y, w, h, radius: float) =
  okyRoundedRect(ctx, x.cfloat, y.cfloat, w.cfloat, h.cfloat, radius.cfloat)

proc roundedRect*(ctx: OpsRenderContext, x, y, w, h, rtl, rtr, rbr, rbl: float) =
  okyRoundedRectVarying(
    ctx, x.cfloat, y.cfloat, w.cfloat, h.cfloat, rtl.cfloat, rtr.cfloat, rbr.cfloat,
    rbl.cfloat,
  )

proc ellipse*(ctx: OpsRenderContext, cx, cy, rx, ry: float) =
  okyEllipse(ctx, cx.cfloat, cy.cfloat, rx.cfloat, ry.cfloat)

proc circle*(ctx: OpsRenderContext, cx, cy, r: float) =
  okyCircle(ctx, cx.cfloat, cy.cfloat, r.cfloat)

# ── render ────────────────────────────────────────────────────────────────────

proc fill*(ctx: OpsRenderContext) =
  okyFill(ctx)

proc stroke*(ctx: OpsRenderContext) =
  okyStroke(ctx)

# ── text ──────────────────────────────────────────────────────────────────────

func strPtr(s: string, bytePos: int): cstring {.inline.} =
  # Safe pointer into s at bytePos, including bytePos == s.len (null terminator).
  cast[cstring](cast[int](s[0].unsafeAddr) + bytePos)

proc text*(
    ctx: OpsRenderContext,
    x, y: float,
    s: string,
    startPos: Natural = 0,
    endPos: int = -1,
): float =
  if s == "" or startPos >= s.len:
    return x
  let startPtr = strPtr(s, startPos)
  let endPtr: cstring =
    if endPos < 0:
      nil
    else:
      strPtr(s, endPos + 1)
  okyText(ctx, x.cfloat, y.cfloat, startPtr, endPtr).float

proc textBox*(
    ctx: OpsRenderContext,
    x, y, breakRowWidth: float,
    s: string,
    startPos: Natural = 0,
    endPos: int = -1,
) =
  if s == "" or startPos >= s.len or breakRowWidth <= 0:
    return
  let startPtr = strPtr(s, startPos)
  let endPtr: cstring =
    if endPos < 0:
      nil
    else:
      strPtr(s, endPos + 1)
  okyTextBox(ctx, x.cfloat, y.cfloat, breakRowWidth.cfloat, startPtr, endPtr)

proc textGlyphPositions*(
    ctx: OpsRenderContext,
    x, y: float,
    s: string,
    startPos: Natural = 0,
    endPos: int = -1,
    positions: var openArray[GlyphPosition],
): int =
  if s == "" or positions.len == 0 or startPos >= s.len:
    return 0
  let startPtr = strPtr(s, startPos)
  let endPtr: cstring =
    if endPos < 0:
      nil
    else:
      strPtr(s, endPos + 1)
  # GlyphPosition and OKYglyphPos are binary-compatible (cstring + 3 cfloat).

  okyTextGlyphPositions(
    ctx,
    x.cfloat,
    y.cfloat,
    startPtr,
    endPtr,
    cast[ptr OKYglyphPos](positions[0].addr),
    positions.len.cint,
  ).int

template textGlyphPositions*(
    ctx: OpsRenderContext,
    x, y: float,
    s: string,
    startPos: Natural,
    positions: var openArray[GlyphPosition],
): int =
  textGlyphPositions(ctx, x, y, s, startPos, endPos = -1, positions)

template textGlyphPositions*(
    ctx: OpsRenderContext,
    x, y: float,
    s: string,
    positions: var openArray[GlyphPosition],
): int =
  textGlyphPositions(ctx, x, y, s, startPos = 0, endPos = -1, positions)

template textMetrics*(
    ctx: OpsRenderContext
): tuple[ascender, descender, lineHeight: float] =
  var asc, desc, lh: cfloat
  okyTextMetrics(ctx, asc.addr, desc.addr, lh.addr)
  (asc.float, desc.float, lh.float)

proc textWidth*(
    ctx: OpsRenderContext, s: string, startPos: Natural = 0, endPos: int = -1
): float =
  if s == "" or startPos >= s.len:
    return 0.0
  let startPtr = strPtr(s, startPos)
  let endPtr: cstring =
    if endPos < 0:
      nil
    else:
      strPtr(s, endPos + 1)
  # Measure-only: okyTextBounds returns the advance without drawing glyphs.
  # (okyText would render the run as a side effect — wrong for measurement.)
  okyTextBounds(ctx, 0, 0, startPtr, endPtr, nil).float

# ── font management ───────────────────────────────────────────────────────────

# Bumped whenever a font is loaded, so text-measurement caches can invalidate.
var g_fontGeneration*: int = 0

proc fontGeneration*(): int =
  g_fontGeneration

proc createFont*(ctx: OpsRenderContext, name: string, filename: string): Font =
  inc g_fontGeneration
  Font(okyCreateFont(ctx, name.cstring, filename.cstring))

proc createFontMem*(
    ctx: OpsRenderContext, name: string, data: var openArray[byte]
): Font =
  inc g_fontGeneration
  Font(
    okyCreateFontMem(ctx, name.cstring, cast[ptr uint8](data[0].addr), data.len.cint, 0)
  )

proc findFont*(ctx: OpsRenderContext, name: cstring): Font =
  Font(okyFindFont(ctx, name))

proc findFont*(ctx: OpsRenderContext, name: string): Font =
  Font(okyFindFont(ctx, name.cstring))

proc fontFace*(ctx: OpsRenderContext, font: Font) =
  okyFontFaceId(ctx, font.cint)

proc fontFace*(ctx: OpsRenderContext, fontName: cstring) =
  okyFontFace(ctx, fontName)

proc fontFace*(ctx: OpsRenderContext, fontName: string) =
  okyFontFace(ctx, fontName.cstring)

proc fontSize*(ctx: OpsRenderContext, size: float) =
  okyFontSize(ctx, size.cfloat)

proc textLetterSpacing*(ctx: OpsRenderContext, spacing: float) =
  okyTextLetterSpacingRaw(ctx, spacing.cfloat)

proc textLineHeight*(ctx: OpsRenderContext, lineHeight: float) =
  okyTextLineHeightRaw(ctx, lineHeight.cfloat)

proc textAlign*(
    ctx: OpsRenderContext,
    halign: HorizontalAlign = haLeft,
    valign: VerticalAlign = vaBaseline,
) =
  okyTextAlign(ctx, (halign.int or valign.int).cint)

proc textAlign*(ctx: OpsRenderContext, align: cint) =
  okyTextAlign(ctx, align)
