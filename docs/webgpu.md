# WebGPU Host Notes

Ops should not own a WebGPU runtime. The Okys C ABI is the renderer and graphics
integration boundary; Ops passes native window/surface handles to Okys where the
Okys-owned platform host ABI exists.

The older Ops-side WebGPU helper path is legacy. Do not add `webgpu`,
`webgpu-nim`, WGVK, Dawn, or wgpu-native as Ops dependencies to make the release
path work. If Okys uses WebGPU internally, that stays behind `okys.h`.

## Current Position

- Ops owns widgets, layout, input, and native window handles.
- Okys owns vector/text rendering, GPU submission, and the platform host ABI.
- Linux Wayland now uses the Okys native Vulkan platform host through `okys.h`.
- Ops core is windowing-neutral; GLFW and Wayland are adapters over the
  normalized input queue and platform hooks.
- WebGPU-everywhere means one Okys C ABI path for consumers, not a Ops WebGPU
  binding.

## Follow-Up

- Extend the Okys platform host ABI to X11, macOS, and Windows handles.
- Retire or quarantine Ops's legacy WebGPU helper modules once release targets
  no longer need them.
- Keep Gridmonger in the smoke loop for splash images, theme edits, HSE picker
  rendering, quit confirmation input, and map rendering.
