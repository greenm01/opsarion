import std/os

import ops/backends/surface

const okysRoot = currentSourcePath().parentDir().parentDir().parentDir().parentDir() / "okys"
const H = "okys.h"

{.passC: "-I" & okysRoot / "zig-out" / "include".}
{.passL: "-ldl".}

type
  OKYplatformHostObj {.importc: "OKYplatformHost", header: H,
      incompleteStruct.} = object

  OpsVkFrame* {.importc: "OKYplatformFrame", header: H, bycopy.} = object
    renderImage* {.importc: "render_image".}: pointer
    renderView* {.importc: "render_view".}: pointer
    depthStencilImage* {.importc: "depth_stencil_image".}: pointer
    depthStencilView* {.importc: "depth_stencil_view".}: pointer
    renderFinishedSemaphore* {.importc: "render_finished_semaphore".}: pointer
    presentCompleteSemaphore* {.importc: "present_complete_semaphore".}: pointer
    width*: uint32
    height*: uint32
    imageIndex* {.importc: "image_index".}: uint32

  OkysVulkanHost* = object
    raw: ptr OKYplatformHostObj

proc okyPlatformHostCreateWayland(
    wlDisplay, wlSurface: pointer, width, height: uint32
): ptr OKYplatformHostObj {.importc, header: H.}
proc okyPlatformHostDestroy(host: ptr OKYplatformHostObj) {.importc, header: H.}
proc okyPlatformHostResize(host: ptr OKYplatformHostObj, width,
    height: uint32): cint {.
  importc, header: H
.}
proc okyPlatformHostBeginFrame(host: ptr OKYplatformHostObj,
    frame: ptr OpsVkFrame): cint {.
  importc, header: H
.}
proc okyPlatformHostPresent(host: ptr OKYplatformHostObj,
    frame: ptr OpsVkFrame): cint {.
  importc, header: H
.}
proc okyPlatformHostVulkanInstance(host: ptr OKYplatformHostObj): pointer {.
  importc, header: H
.}
proc okyPlatformHostVulkanPhysicalDevice(
  host: ptr OKYplatformHostObj): pointer {.
  importc, header: H
.}
proc okyPlatformHostVulkanDevice(host: ptr OKYplatformHostObj): pointer {.
  importc, header: H
.}
proc okyPlatformHostVulkanQueue(host: ptr OKYplatformHostObj): pointer {.
  importc, header: H
.}
proc okyPlatformHostVulkanQueueFamilyIndex(
  host: ptr OKYplatformHostObj): uint32 {.
  importc, header: H
.}
proc okyPlatformHostColorFormatCode(host: ptr OKYplatformHostObj): cint {.
  importc, header: H
.}

proc initOkysVulkanHostWithSurface*(
    h: var OkysVulkanHost, handle: OpsWgpuSurfaceHandle, width, height: uint32
) =
  if handle.kind != kwskWayland:
    raise newException(CatchableError, "okys native Vulkan host currently supports Wayland surfaces")
  h.raw = okyPlatformHostCreateWayland(handle.wlDisplay, handle.wlSurface,
      width, height)
  if h.raw.isNil:
    raise newException(CatchableError, "Could not initialize okys native Vulkan host")

proc destroyOkysVulkanHost*(h: var OkysVulkanHost) =
  if not h.raw.isNil:
    okyPlatformHostDestroy(h.raw)
    h.raw = nil

proc resizeOkysVulkanHost*(h: var OkysVulkanHost, width, height: uint32) =
  if h.raw.isNil or width == 0 or height == 0:
    return
  if okyPlatformHostResize(h.raw, width, height) == 0:
    raise newException(CatchableError, "Could not resize okys native Vulkan host")

proc beginOkysVulkanFrame*(h: var OkysVulkanHost): OpsVkFrame =
  if h.raw.isNil:
    return
  if okyPlatformHostBeginFrame(h.raw, result.addr) == 0:
    result = OpsVkFrame()

proc presentOkysVulkanFrame*(h: var OkysVulkanHost,
    frame: var OpsVkFrame): bool =
  if h.raw.isNil:
    return false
  result = okyPlatformHostPresent(h.raw, frame.addr) != 0
  frame = OpsVkFrame()

proc okysInstanceHandle*(h: OkysVulkanHost): pointer =
  okyPlatformHostVulkanInstance(h.raw)

proc okysPhysicalDeviceHandle*(h: OkysVulkanHost): pointer =
  okyPlatformHostVulkanPhysicalDevice(h.raw)

proc okysDeviceHandle*(h: OkysVulkanHost): pointer =
  okyPlatformHostVulkanDevice(h.raw)

proc okysQueueHandle*(h: OkysVulkanHost): pointer =
  okyPlatformHostVulkanQueue(h.raw)

proc okysQueueFamilyIndex*(h: OkysVulkanHost): uint32 =
  okyPlatformHostVulkanQueueFamilyIndex(h.raw)

proc okysSurfaceFormatCode*(h: OkysVulkanHost): int =
  okyPlatformHostColorFormatCode(h.raw).int
