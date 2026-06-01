# Ops Backend Spec

This document specifies the windowing and rendering backend split for Ops.
The goal is a native Wayland path on Linux alongside optional platform adapters
such as GLFW. Ops hosts widget state and normalized input; consumers may host
their own windows and feed Ops events directly. Okys is the renderer and should
own graphics runtime integration behind its C ABI.

## Design constraints

- The existing GLFW/OpenGL examples must continue to compile and run through
  okys when the GLFW adapter is explicitly enabled.
- The Wayland windowing layer must not pull in any non-Wayland platform code.
- Ops core must not require GLFW; GLFW is a reference adapter, not a core
  dependency.
- Ops must not bind WebGPU packages directly. Platform handles cross into Okys
  through `okys.h`.
- No double evaluation of widget bodies. Layout and rendering constraints from
  `layout-model.md` are unaffected by this spec.
- Gridmonger must continue to build against the GLFW path without changes.

## Layer overview

```
┌─────────────────────────────────────────────────┐
│                   Ops (Nim)                     │
│           layout · widgets · input state        │
└───────────────────┬─────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼───────┐       ┌───────▼────────┐
│  Windowing    │       │   Windowing    │
│  Wayland      │       │   GLFW         │
│  (Zig · C ABI)│       │  (C · existing)│
└───────┬───────┘       └───────┬────────┘
        │                       │
        │  wl_display           │  GLFWwindow
        │  wl_surface           │
        └───────────┬───────────┘
                    │ native platform handles
          ┌─────────▼──────────┐
          │ Okys host ABI      │
          │ + renderer         │
          │ (okys.h)           │
          └────────────────────┘
```

The split has three seams:

1. **Windowing seam** — platform-specific. Either the Zig Wayland layer or
   GLFW provides a window and raw surface handle.
2. **Input seam** — platform adapters translate keyboard, text, mouse, scroll,
   focus, size, scale, cursor, and clipboard behavior into Ops's normalized event
   queue and `PlatformHooks`.
3. **Okys host seam** — Ops passes native handles through a small C-shaped
   wrapper. Graphics devices, swapchains, pipelines, and render passes are Okys
   concerns.

---

## Windowing layer A — Wayland (Zig)

### Purpose

Provides native Wayland windowing and input for Linux sessions running on
compositors that do not support OpenGL deprecation workarounds or where
Wayland-native behavior is required (Niri, Sway, future compositors).

### Dependencies

| Dependency | Source | Role |
| --- | --- | --- |
| `zig` compiler | system / ziglang.org | build tool |
| `zig-wayland` | isaacfreund/zig-wayland | Wayland protocol scanner + libwayland bindings |
| `zig-xkbcommon` | isaacfreund/zig-xkbcommon | keyboard input |
| `libwayland-client` | system | Wayland wire protocol |
| `libxkbcommon` | system | key symbol mapping |
| `libdecor` | system (optional) | client-side window decorations |

### Wayland protocols used

| Protocol | Role |
| --- | --- |
| `wl_compositor` | surface creation |
| `xdg_wm_base` / `xdg_surface` / `xdg_toplevel` | window management |
| `wl_seat` / `wl_pointer` / `wl_keyboard` | input |
| `xdg_decoration_manager_v1` | server-side decorations (Niri supports this) |
| `wp_cursor_shape_v1` | cursor icons (optional, graceful fallback) |
| `wl_output` | monitor info, HiDPI scale factor |

### C ABI surface

The Zig layer compiles to `libops_wayland.a` and exposes this interface:

```c
// ops_wayland.h

typedef struct OpsWaylandDisplay OpsWaylandDisplay;
typedef struct OpsWaylandWindow  OpsWaylandWindow;

typedef enum {
  OPS_WAYLAND_CURSOR_DEFAULT,
  OPS_WAYLAND_CURSOR_TEXT,
  OPS_WAYLAND_CURSOR_CROSSHAIR,
  OPS_WAYLAND_CURSOR_POINTER,
  OPS_WAYLAND_CURSOR_RESIZE_EW,
  OPS_WAYLAND_CURSOR_RESIZE_NS,
  OPS_WAYLAND_CURSOR_RESIZE_NWSE,
  OPS_WAYLAND_CURSOR_RESIZE_NESW,
  OPS_WAYLAND_CURSOR_RESIZE_ALL,
} OpsWaylandCursorShape;

typedef struct {
  void (*on_close)       (void* ud);
  void (*on_focus)       (bool focused, void* ud);
  void (*on_resize)      (uint32_t w, uint32_t h, void* ud);
  void (*on_key_down)    (uint32_t keycode, uint32_t mods, void* ud);
  void (*on_key_repeat)  (uint32_t keycode, uint32_t mods, void* ud);
  void (*on_key_up)      (uint32_t keycode, uint32_t mods, void* ud);
  void (*on_mouse_move)  (double x, double y, void* ud);
  void (*on_mouse_button)(uint32_t btn, bool pressed, void* ud);
  void (*on_scroll)      (double dx, double dy, void* ud);
  void (*on_scale)       (double scale, void* ud);
  void* userdata;
} OpsWaylandCallbacks;

// Key callbacks report physical Wayland keycodes for shortcuts. Text input
// uses on_char, which reports layout-aware UTF-32 codepoints from xkbcommon.

OpsWaylandDisplay* ops_wayland_init(void);
OpsWaylandWindow*  ops_wayland_create_window(OpsWaylandDisplay*, uint32_t w,
                                              uint32_t h, const char* title);
void               ops_wayland_set_callbacks(OpsWaylandWindow*,
                                              const OpsWaylandCallbacks*);
void               ops_wayland_poll_events(OpsWaylandDisplay*);
void               ops_wayland_roundtrip(OpsWaylandDisplay*);
void*              ops_wayland_get_wl_display(OpsWaylandDisplay*);
void*              ops_wayland_get_wl_surface(OpsWaylandWindow*);
bool               ops_wayland_window_should_close(OpsWaylandWindow*);
void               ops_wayland_set_title(OpsWaylandWindow*, const char*);
void               ops_wayland_set_size(OpsWaylandWindow*, uint32_t w, uint32_t h);
void               ops_wayland_set_cursor_shape(OpsWaylandWindow*,
                                                 OpsWaylandCursorShape);
void               ops_wayland_destroy_window(OpsWaylandWindow*);
void               ops_wayland_destroy(OpsWaylandDisplay*);
```

`ops_wayland_get_wl_display` and `ops_wayland_get_wl_surface` return opaque
pointers that Ops passes to Okys. Ops's Nim code never dereferences them.

`ops_wayland_set_cursor_shape` uses `wp_cursor_shape_v1` when the compositor
advertises it and is otherwise a no-op. `ops_wayland_window_should_close`
mirrors the close callback so direct event loops can poll close state without
maintaining separate userdata.

### Build

`build.zig` in the Ops repo root fetches `zig-wayland` and `zig-xkbcommon`
via the Zig package manager, generates protocol bindings at build time, and
produces `zig-out/lib/libops_wayland.a`. The build is invoked from Nim's
`config.nims` when `waylandBackend` is defined.

---

## Windowing layer B — GLFW reference adapter

Ops keeps a GLFW adapter for examples and cross-platform smoke coverage, but it
is opt-in via `-d:opsGlfwAdapter`. The adapter owns GLFW callbacks, cursor
objects, clipboard hooks, and window-size hooks, then translates them into
Ops's backend-neutral input queue and `PlatformHooks`.

The adapter can handle:

- X11 on Linux (GLFW 3.4, both Wayland and X11 enabled by default)
- macOS
- Windows

For Okys host setup on these platforms, GLFW exposes raw handles:

```c
// X11
Display* x11_display = glfwGetX11Display();
Window   x11_window  = glfwGetX11Window(window);

// macOS — CAMetalLayer via glfwGetCocoaWindow
// Windows — HWND via glfwGetWin32Window
```

These handles should be passed to Okys through the Okys-owned platform host ABI.
Ops should not bind a separate WebGPU package just to create devices or
swapchains.

Projects that already own a window/event loop do not need this adapter. They can
call `initWithPlatform`, install their own `PlatformHooks`, and push events with
`queueKeyEvent`, `queueChar`, `queueMouseMove`, `queueMouseButtonEvent`, and
`queueScrollEvent`.

---

## Rendering layer — okys hosted by platform ABI

### Purpose

Ops owns widgets, layout, input, and window handles. Okys owns vector/text
rendering and should own the graphics host boundary exposed through `okys.h`.
Linux Wayland now uses that boundary: Ops passes platform handles to Okys and
receives a frame lifecycle that requires no Nim WebGPU dependency.

### Dependencies

| Dependency | Source | Role |
| --- | --- | --- |
| `okys` | local dependency | Renderer, GPU submission, and platform host ABI |

Ops should not depend on `webgpu`, `webgpu-nim`, WGVK, Dawn, or wgpu-native
directly. If Okys uses WebGPU internally, that remains behind the Okys C ABI.

### Platform matrix

| Platform | Ops input/window path | Okys host target |
| --- | --- | --- |
| Linux / Wayland | native Wayland | Okys-owned host from `wl_display` + `wl_surface` |
| Linux / X11 | GLFW/X11 | Okys-owned host from X11 display + window |
| macOS | GLFW/Cocoa | Okys-owned host from Cocoa/Metal-compatible window handle |
| Windows | GLFW/Win32 | Okys-owned host from HWND + HINSTANCE |

Linux Wayland currently uses the Okys-owned native Vulkan host. Do not replace
it with a Nim WebGPU host.

## Input layer — normalized events

Ops core consumes input through backend-neutral queue calls:

- `queueKeyEvent` for shortcut/navigation key down, up, and repeat events
- `queueChar` for layout-aware Unicode text input
- `queueMouseMove`, `queueMouseButtonEvent`, and `queueScrollEvent` for pointer
  input
- `clearInputState` on focus loss so stuck keys/buttons do not leak across
  platforms

GLFW and Wayland are adapters over this API. Downstream projects can provide the
same adapter shape for SDL, custom Wayland, engine-owned event loops, or test
harnesses without pulling platform glue into Ops core. Renderer code is
intentionally not part of this layer; Ops still renders through Okys.

---

## Surface creation seam

This is the only platform-specific code in the Okys host path. It should live in
a small Nim module that converts window handles into Okys C ABI structs:

```nim
# backends/okys_host.nim

proc okysPlatformHandle*(win: Window): OkysPlatformHandle =
  when defined(waylandBackend):
    okysWaylandHandle(opsWaylandGetWlDisplay(gDisplay), opsWaylandGetWlSurface(gWindow))

  elif defined(linux):
    okysX11Handle(glfwGetX11Display(), glfwGetX11Window(gGlfwWindow))

  elif defined(macosx):
    # Cocoa handle/layer extraction stays platform glue; graphics ownership stays in Okys.
    ...

  elif defined(windows):
    # HWND/HINSTANCE extraction stays platform glue; graphics ownership stays in Okys.
    ...
```

Everything above this module remains Ops UI code. Adapter selection, device
creation, swapchain configuration, render pass recording, and pipeline
compilation belong behind Okys's C ABI.

---

## Nim module layout

```
ops/
├── backends/
│   ├── okys_vulkan_host.nim ← thin Nim wrapper over Okys host ABI
│   ├── wayland.nim        ← importc bindings to ops_wayland.h (new)
│   └── glfw.nim           ← existing GLFW bindings (unchanged)
├── wayland/
│   ├── build.zig          ← Zig build for libops_wayland.a (new)
│   ├── ops_wayland.zig    ← Zig windowing implementation (new)
│   └── ops_wayland.h      ← C header for Nim importc (new)
└── config.nims            ← build routing by compile-time define
```

---

## Build routing

```nim
# config.nims

when defined(waylandBackend):
  # Build the Zig windowing layer
  exec "zig build -Doptimize=ReleaseSafe --build-file wayland/build.zig"
  switch("passL", "-Lwayland/zig-out/lib -lops_wayland")
  switch("passL", "-lwayland-client -lxkbcommon")
  switch("define", "opsVulkan") # Okys platform host ABI currently backs Wayland

elif defined(opsGlfwAdapter):
  # Optional GLFW adapter: window/input plus native handles passed to Okys.
  switch("passL", "-lglfw")
  switch("define", "opsVulkan") # Linux Vulkan path until other hosts land
```

Ops is built with `-d:waylandBackend` to activate the Zig windowing layer.
GLFW examples build with `-d:opsGlfwAdapter`. Without either flag, Ops core is
windowing-neutral and expects the application to install platform hooks and feed
normalized input events. Rendering still goes through okys.

---

## Migration path

Linux Wayland has the first Okys host ABI slice. Remaining work extends the same
shape to other native handles.

1. **Wayland windowing first** — implement `ops_wayland.zig` and
   `backends/wayland.nim`. Wire input events to Ops's existing event model.
   Keep okys rendering through the existing GLFW/OpenGL examples while the
   native Wayland host matures.

2. **Okys platform host ABI** — extend the existing `okys.h` calls so Ops can
   pass X11, macOS, and Windows native handles without importing a WebGPU
   runtime.

3. **Wayland + Okys host combined** — wire `backends/okys_host.nim` to the Zig
   windowing layer. This is the final production path on Niri.

4. **Gridmonger fork validation** — build Gridmonger against Ops with
   `-d:waylandBackend` to validate the layout model and rendering pipeline
   against a real application before upstreaming layout changes.

---

## Non-goals

- No WebGPU bindings in Ops. Okys owns graphics runtime integration.
- No changes to Ops's widget API, row layout, or manual space API.
- No removal of the GLFW path. It remains a reference adapter and example path.
- No support for Wayland on macOS or Windows.
