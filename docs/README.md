# Opsarion

**Opsarion** is a small immediate-mode UI library for Nim. Its public import
namespace is `ops`. It renders through
[okys](../../okys), with optional GLFW/OpenGL examples and Okys-hosted native
demos.

Ops core is windowing-neutral. It consumes normalized keyboard, text, mouse, and
scroll events plus platform hooks for size, scale, cursor, and clipboard
behavior. The repo includes a GLFW reference adapter for examples and a native
Zig Wayland path for Linux Wayland sessions. Graphics runtime ownership belongs
behind the Okys C ABI.

For first-release work, the stable center is `import ops`: widget/layout/input
APIs, `PlatformHooks`, and small caller-owned helpers such as `ItemSelection`.
Platform adapters are intentionally thin reference paths; applications can feed
normalized input directly and keep their own windowing or engine integration.

Layout, widget, and style references live in [toolset.md](./toolset.md),
[layout-model.md](./layout-model.md), and [theming.md](./theming.md). Renderer
context lives in [webgpu.md](./webgpu.md). Check the [examples](/examples)
and Gridmonger for complete usage.

Current follow-up work is tracked in [todo.md](./todo.md).

Support is currently *alpha level*, meaning that the API or the functionality might change without warning at any moment.

## Dependencies

Nim 2.2.4 or later is required for Ops core.

The GLFW examples additionally use [nim-glfw](https://github.com/johnnovak/nim-glfw).

You can install the example dependency with [Nimble](https://github.com/nim-lang/nimble):

```
nimble install glfw
```

## Building

To build the examples (the dependencies will be auto-installed if needed):

```
nimble minimal
nimble test
nimble paneltest
nimble layoutDemos
```

or

```
nimble testRelease
nimble paneltestRelease
```

Legacy Ops-side WebGPU demo tasks are disabled. Ops should not depend on a
separate WebGPU package; release paths should consume the Okys platform host ABI.

See [opsarion.nimble](/opsarion.nimble) for the `-d:opsGlfwAdapter` example flags and
the Okys-backed build tasks.

To format sources and remove generated example binaries:

```
nimble tidy
```

## License

Opsarion is released under the MIT License.

Copyright (c) 2026 Mason Austin Green.

Opsarion began as a fork of Koi by John Novak.


