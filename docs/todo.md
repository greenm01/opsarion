# Ops Todo

This file tracks current follow-up work. Historical audit notes were folded down
to the deferred candidates that still look useful.

## Renderer Roadmap

Ops's renderer target is Okys. Ops owns widgets, layout, input, and window
hosting; Okys owns vector/text rendering, GPU submission, and platform-hosted
graphics setup. Linux Wayland now uses the Okys-owned host ABI; Ops does not
bind WebGPU packages.

## Active Items

- Keep user input backend-agnostic: Ops core now owns only normalized input
  state; GLFW and Wayland remain adapters over the event queue and
  `PlatformHooks`.
- Keep adapters lean: downstream consumers should own SDL/GLFW/custom engine
  adapters unless an adapter is needed as a reference implementation or smoke
  target.
- Extend the Okys host ABI seam to X11, macOS, and Windows native handles.
- Retire or quarantine legacy Ops WebGPU helper modules once all release targets
  use the Okys host ABI.
- Use `ItemSelection` for caller-owned list/table/tree active-row and range
  selection state instead of adding separate widget-local selection models.
- Keep Gridmonger in the Okys smoke checklist: theme edits, HSE picker
  rendering, quit confirmation mouse input, and map rendering.
- Keep a small benchmark history for text editing and representative okys
  render scenes.

## Notes

- Ops should consume Okys through `okys.h`; do not add a separate WebGPU runtime
  dependency to Ops.
- `import ops` should stay platform-neutral. Use `-d:opsGlfwAdapter` only for
  GLFW examples or apps that want Ops's bundled reference adapter.
- Rendering stays Okys-first for the first release; an abstract primitive command
  buffer is deferred until Ops needs a non-Okys renderer.
- Collection widgets remain data-model neutral. Ops provides selection helpers,
  but applications keep ownership of row objects, sort order, filtering, and
  persistence.
- Wayland cursor shape and close/resize polish are tracked by the native
  Wayland ABI and smoke/demo builds.
- Text-editing profiling is repeatable with `nimble benchTextEditing`; current
  profiling keeps the per-operation rune navigation approach until benchmark
  results justify a persistent cache.
