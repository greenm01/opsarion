when defined(opsWgpu):
  import wgpu
  import wgpu/extras/helpers
  import wgpu/extras/strings

type
  OpsWgpuSurfaceKind* = enum
    kwskWayland
    kwskX11
    kwskMetalLayer
    kwskWindowsHwnd

  OpsWgpuSurfaceHandle* = object
    case kind*: OpsWgpuSurfaceKind
    of kwskWayland:
      wlDisplay*: pointer
      wlSurface*: pointer
    of kwskX11:
      x11Display*: pointer
      x11Window*: uint64
    of kwskMetalLayer:
      metalLayer*: pointer
    of kwskWindowsHwnd:
      hwnd*: pointer
      hinstance*: pointer

func waylandSurfaceHandle*(display, surface: pointer): OpsWgpuSurfaceHandle =
  OpsWgpuSurfaceHandle(kind: kwskWayland, wlDisplay: display, wlSurface: surface)

func x11SurfaceHandle*(display: pointer, window: uint64): OpsWgpuSurfaceHandle =
  OpsWgpuSurfaceHandle(kind: kwskX11, x11Display: display, x11Window: window)

func metalLayerSurfaceHandle*(layer: pointer): OpsWgpuSurfaceHandle =
  OpsWgpuSurfaceHandle(kind: kwskMetalLayer, metalLayer: layer)

func windowsHwndSurfaceHandle*(hwnd, hinstance: pointer): OpsWgpuSurfaceHandle =
  OpsWgpuSurfaceHandle(kind: kwskWindowsHwnd, hwnd: hwnd, hinstance: hinstance)

when defined(opsWgpu):
  proc createSurface*(instance: Instance, handle: OpsWgpuSurfaceHandle): Surface =
    case handle.kind
    of kwskWayland:
      result = instance.create(
        vaddr SurfaceDescriptor(
          label: "Ops WebGPU Wayland surface".toStringView(),
          nextInChain: cast[ptr ChainedStruct](vaddr SurfaceSourceWaylandSurface(
            chain: ChainedStruct(next: nil, sType: SType.SurfaceSourceWaylandSurface),
            display: handle.wlDisplay,
            surface: handle.wlSurface,
          )),
        )
      )
    of kwskX11:
      result = instance.create(
        vaddr SurfaceDescriptor(
          label: "Ops WebGPU X11 surface".toStringView(),
          nextInChain: cast[ptr ChainedStruct](vaddr SurfaceSourceXlibWindow(
            chain: ChainedStruct(next: nil, sType: SType.SurfaceSourceXlibWindow),
            display: handle.x11Display,
            window: handle.x11Window,
          )),
        )
      )
    of kwskMetalLayer:
      result = instance.create(
        vaddr SurfaceDescriptor(
          label: "Ops WebGPU Metal layer surface".toStringView(),
          nextInChain: cast[ptr ChainedStruct](vaddr SurfaceSourceMetalLayer(
            chain: ChainedStruct(next: nil, sType: SType.SurfaceSourceMetalLayer),
            layer: handle.metalLayer,
          )),
        )
      )
    of kwskWindowsHwnd:
      result = instance.create(
        vaddr SurfaceDescriptor(
          label: "Ops WebGPU Win32 HWND surface".toStringView(),
          nextInChain: cast[ptr ChainedStruct](vaddr SurfaceSourceWindowsHWND(
            chain: ChainedStruct(next: nil, sType: SType.SurfaceSourceWindowsHWND),
            hwnd: handle.hwnd,
            hinstance: handle.hinstance,
          )),
        )
      )
