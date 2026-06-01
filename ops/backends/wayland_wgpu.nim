import ops/backends/surface
import ops/backends/wayland

export surface.OpsWgpuSurfaceHandle

proc wgpuSurfaceHandle*(
    display: ptr OpsWaylandDisplay, window: ptr OpsWaylandWindow
): OpsWgpuSurfaceHandle =
  waylandSurfaceHandle(opsWaylandGetWlDisplay(display), opsWaylandGetWlSurface(window))

proc surfaceSize*(window: ptr OpsWaylandWindow): tuple[width, height: uint32] =
  (opsWaylandGetWidth(window), opsWaylandGetHeight(window))
