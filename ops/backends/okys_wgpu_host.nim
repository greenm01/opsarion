import wgpu
import wgpu/extras/helpers
import wgpu/extras/strings

import ops/backends/surface

type
  OkysWgpuHost* = object
    instance: Instance
    surface: Surface
    adapter: Adapter
    device: Device
    queue: Queue
    surfaceKind: OpsWgpuSurfaceKind
    surfaceFormat: TextureFormat
    surfaceAlpha: CompositeAlphaMode
    config: SurfaceConfiguration
    depthTexture: Texture
    depthView: TextureView
    surfaceNeedsConfigure: bool

  OkysWgpuSurfaceFrame* = object
    texture: Texture
    view: TextureView
    colorTextureView*: pointer
    depthStencilTextureView*: pointer
    width*: uint32
    height*: uint32

proc adapterRequestCb(
    status: RequestAdapterStatus,
    adapter: Adapter,
    message: StringView,
    userdata1, userdata2: pointer,
) {.cdecl.} =
  cast[ptr Adapter](userdata1)[] = adapter

proc deviceRequestCb(
    status: RequestDeviceStatus,
    device: Device,
    message: StringView,
    userdata1, userdata2: pointer,
) {.cdecl.} =
  cast[ptr Device](userdata1)[] = device

func nonSrgbEquivalent(format: TextureFormat): TextureFormat =
  case format
  of TextureFormat.RGBA8UnormSrgb: TextureFormat.RGBA8Unorm
  of TextureFormat.BGRA8UnormSrgb: TextureFormat.BGRA8Unorm
  else: format

func chooseSurfaceFormat(
    formats: ptr UncheckedArray[TextureFormat], count: int
): TextureFormat =
  result = formats[0]
  let preferred = [TextureFormat.RGBA8Unorm, TextureFormat.BGRA8Unorm]

  for wanted in preferred:
    for i in 0 ..< count:
      if formats[i] == wanted:
        return wanted

  let linearDefault = nonSrgbEquivalent(result)
  if linearDefault != result:
    for i in 0 ..< count:
      if formats[i] == linearDefault:
        return linearDefault

proc requestAdapter(h: var OkysWgpuHost) =
  let future = h.instance.request(
    options = vaddr RequestAdapterOptions(
      nextInChain: nil,
      featureLevel: Core,
      powerPreference: HighPerformance,
      forceFallbackAdapter: false.uint32,
      backendType: Vulkan,
      compatibleSurface: h.surface,
    ),
    callbackInfo = RequestAdapterCallbackInfo(
      nextInChain: nil,
      mode: AllowSpontaneous,
      callback: adapterRequestCb,
      userdata1: h.adapter.addr,
      userdata2: nil,
    ),
  )
  var waitInfo = FutureWaitInfo(future: future, completed: 0)
  doAssert h.instance.wait(1, waitInfo.addr, uint64.high) == Success
  doAssert waitInfo.completed != 0 and not h.adapter.isNil

proc requestDevice(h: var OkysWgpuHost) =
  let future = h.adapter.request(
    options = vaddr DeviceDescriptor(
      nextInChain: nil,
      label: "Ops okys WebGPU device".toStringView(),
      requiredFeatureCount: 0,
      requiredFeatures: nil,
      requiredLimits: nil,
      defaultQueue:
        QueueDescriptor(nextInChain: nil, label: "Ops okys WebGPU queue".toStringView()),
      deviceLostCallbackInfo: DeviceLostCallbackInfo(
        nextInChain: nil, callback: nil, userdata1: nil, userdata2: nil
      ),
      uncapturedErrorCallbackInfo: UncapturedErrorCallbackInfo(
        nextInChain: nil, callback: nil, userdata1: nil, userdata2: nil
      ),
    ),
    callbackInfo = RequestDeviceCallbackInfo(
      nextInChain: nil,
      mode: AllowSpontaneous,
      callback: deviceRequestCb,
      userdata1: h.device.addr,
      userdata2: nil,
    ),
  )
  var waitInfo = FutureWaitInfo(future: future, completed: 0)
  doAssert h.instance.wait(1, waitInfo.addr, uint64.high) == Success
  doAssert waitInfo.completed != 0 and not h.device.isNil
  h.queue = h.device.getQueue()

proc releaseDepthTarget(h: var OkysWgpuHost) =
  if not h.depthView.isNil:
    h.depthView.release()
    h.depthView = nil
  if not h.depthTexture.isNil:
    h.depthTexture.release()
    h.depthTexture = nil

proc ensureDepthTarget(h: var OkysWgpuHost, width, height: uint32) =
  if width == 0 or height == 0:
    return
  if not h.depthTexture.isNil and h.depthTexture.getWidth() == width and
      h.depthTexture.getHeight() == height:
    return

  h.releaseDepthTarget()
  h.depthTexture = h.device.create(
    vaddr TextureDescriptor(
      nextInChain: nil,
      label: "Ops okys depth-stencil texture".toStringView(),
      usage: TextureUsage_RenderAttachment,
      dimension: TextureDimension.D2D,
      size: Extent3D(width: width, height: height, depthOrArrayLayers: 1),
      format: TextureFormat.Depth24PlusStencil8,
      mipLevelCount: 1,
      sampleCount: 1,
      viewFormatCount: 0,
      viewFormats: nil,
    )
  )
  h.depthView = h.depthTexture.create(
    vaddr TextureViewDescriptor(
      nextInChain: nil,
      label: "Ops okys depth-stencil view".toStringView(),
      format: TextureFormat.Depth24PlusStencil8,
      dimension: TextureViewDimension.D2D,
      baseMipLevel: 0,
      mipLevelCount: 1,
      baseArrayLayer: 0,
      arrayLayerCount: 1,
      aspect: TextureAspect.All,
    )
  )

proc configureSurface(h: var OkysWgpuHost, width, height: uint32) =
  var caps = SurfaceCapabilities()
  doAssert h.surface.get(h.adapter, caps.addr) == Status.Success
  doAssert caps.formatCount > 0
  doAssert caps.alphaModeCount > 0

  let formats = cast[ptr UncheckedArray[TextureFormat]](caps.formats)
  h.surfaceFormat = chooseSurfaceFormat(formats, caps.formatCount.int)
  h.surfaceAlpha = cast[ptr UncheckedArray[CompositeAlphaMode]](caps.alphaModes)[0]
  h.config = SurfaceConfiguration(
    nextInChain: nil,
    device: h.device,
    format: h.surfaceFormat,
    usage: TextureUsage_RenderAttachment,
    width: width,
    height: height,
    viewFormatCount: 0,
    viewFormats: nil,
    alphaMode: h.surfaceAlpha,
    presentMode: Fifo,
  )
  h.surface.configure(h.config.addr)
  h.ensureDepthTarget(width, height)
  caps.freeMembers()

proc initOkysWgpuHostWithSurface*(
    h: var OkysWgpuHost, handle: OpsWgpuSurfaceHandle, width, height: uint32
) =
  h.instance = wgpu.create(vaddr InstanceDescriptor(nextInChain: nil))
  doAssert not h.instance.isNil, "Could not initialize WebGPU"
  h.surfaceKind = handle.kind
  h.surface = h.instance.createSurface(handle)
  doAssert not h.surface.isNil, "Could not create WebGPU surface"
  h.requestAdapter()
  h.requestDevice()
  h.configureSurface(width, height)

proc initOkysWgpuHost*(
    h: var OkysWgpuHost, display, wlSurface: pointer, width, height: uint32
) =
  h.initOkysWgpuHostWithSurface(waylandSurfaceHandle(display, wlSurface), width, height)

proc resizeOkysWgpuHost*(h: var OkysWgpuHost, width, height: uint32) =
  if width == 0 or height == 0:
    return
  if h.config.width == width and h.config.height == height:
    return

  h.config.width = width
  h.config.height = height
  h.surfaceNeedsConfigure = false
  h.surface.configure(h.config.addr)
  h.ensureDepthTarget(width, height)

proc okysDeviceHandle*(h: OkysWgpuHost): pointer =
  cast[pointer](h.device)

proc okysSurfaceFormatCode*(h: OkysWgpuHost): int =
  case h.surfaceFormat
  of TextureFormat.BGRA8Unorm: 1
  of TextureFormat.RGBA8Unorm: 2
  else: 0

proc beginOkysSurfaceFrame*(h: var OkysWgpuHost): OkysWgpuSurfaceFrame =
  if h.surfaceNeedsConfigure:
    h.surface.configure(h.config.addr)
    h.surfaceNeedsConfigure = false

  var surfaceTexture = SurfaceTexture()
  h.surface.getCurrentTexture(surfaceTexture.addr)
  case surfaceTexture.status
  of SuccessOptimal, SuccessSuboptimal:
    discard
  of Timeout, Outdated, Lost:
    if not surfaceTexture.texture.isNil:
      surfaceTexture.texture.release()
    h.surface.configure(h.config.addr)
    return
  else:
    return

  let view = surfaceTexture.texture.create(
    vaddr TextureViewDescriptor(
      nextInChain: nil,
      label: "Ops okys swapchain texture view".toStringView(),
      format: h.surfaceFormat,
      dimension: TextureViewDimension.D2D,
      baseMipLevel: 0,
      mipLevelCount: 1,
      baseArrayLayer: 0,
      arrayLayerCount: 1,
      aspect: TextureAspect.All,
    )
  )
  result = OkysWgpuSurfaceFrame(
    texture: surfaceTexture.texture,
    view: view,
    colorTextureView: cast[pointer](view),
    depthStencilTextureView: cast[pointer](h.depthView),
    width: h.config.width,
    height: h.config.height,
  )

proc presentOkysSurfaceFrame*(
    h: var OkysWgpuHost, frame: var OkysWgpuSurfaceFrame
): bool =
  if not frame.view.isNil:
    frame.view.release()
    frame.view = nil

  let presentStatus = h.surface.present()
  if presentStatus != Status.Success:
    h.surfaceNeedsConfigure = true

  if not frame.texture.isNil:
    frame.texture.release()
    frame.texture = nil
  frame.colorTextureView = nil
  frame.depthStencilTextureView = nil
  result = presentStatus == Status.Success
