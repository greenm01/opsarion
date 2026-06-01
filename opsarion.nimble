# Package

version = "0.4.2"
author = "Mason Green <mason@greenm01.net>"
description = "Immediate-mode UI for Nim backed by Okys"
license = "MIT"

# Dependencies

requires "nim >= 2.2.4"

# Tasks

import std/os
import std/strutils

const
  CoreFlags =
    "--mm:orc --deepcopy:on -d:nimPreviewFloatRoundtrip " &
    "--path:. --hint:Name:off"
  GlfwFlags =
    CoreFlags & " -d:opsGlfwAdapter -d:glfwStaticLib -d:glStaticProcs"
  WgpuBaseFlags =
    "--mm:orc --deepcopy:on -d:nimPreviewFloatRoundtrip " &
    "-d:NoGLFW -d:opsWgpu " &
    "--path:. --passC:-Wno-incompatible-pointer-types --hint:Name:off"
  WaylandLinkFlags =
    "--passL:\"-Lops/wayland/zig-out/lib -lops_wayland\" " &
    "--passL:\"-lwayland-client -lxkbcommon\" --passC:-Iops/wayland"
  WaylandFlags =
    "--mm:orc --deepcopy:on -d:waylandBackend --path:. --hint:Name:off " &
    WaylandLinkFlags

proc sh(cmd: string) =
  exec cmd

proc glfwWgpuFlags(): string =
  var flags = WgpuBaseFlags & " -d:opsGlfwAdapter"
  when defined(linux):
    if existsEnv("WAYLAND_DISPLAY"):
      flags.add " -d:wayland"
  flags

proc nativeWaylandWgpuFlags(): string =
  WgpuBaseFlags & " -d:wayland -d:waylandBackend -d:glfwJustCdecl " & WaylandLinkFlags

proc wgpuBackend(): string =
  result = getEnv("OPS_BACKEND").toLowerAscii
  if result.len == 0:
    when defined(linux):
      result = if existsEnv("WAYLAND_DISPLAY"): "wayland" else: "glfw"
    else:
      result = "glfw"
  if result notin ["wayland", "glfw"]:
    quit "OPS_BACKEND must be 'wayland' or 'glfw'."
  when not defined(linux):
    if result == "wayland":
      quit "OPS_BACKEND=wayland is only supported on Linux."

proc wgpuFlags(): string =
  if wgpuBackend() == "wayland":
    nativeWaylandWgpuFlags()
  else:
    glfwWgpuFlags()

proc waylandWgpuFlags(): string =
  WgpuBaseFlags & " -d:waylandBackend " & WaylandLinkFlags

proc buildWaylandBackend() =
  sh "zig build -Doptimize=Debug --build-file ops/wayland/build.zig"

proc buildOkysForBackend(backend: string) =
  var cmd =
    "zig build -Doptimize=Debug -Dbackend=" & backend & " --build-file " &
    quoteShell(thisDir() / "../okys/build.zig")
  if backend == "wgpu":
    let includePath = getEnv("OKYS_WEBGPU_INCLUDE").strip()
    if includePath.len > 0:
      cmd.add " -Dwebgpu-include=" & quoteShell(includePath)
  sh cmd

proc buildOkysGl() =
  buildOkysForBackend("gl")

proc buildOkysWgpu() =
  quit "Ops-side WebGPU host tasks are disabled; use the Okys platform host ABI instead."
  buildOkysForBackend("wgpu")

proc buildWgpuBackendIfNeeded() =
  if wgpuBackend() == "wayland":
    buildWaylandBackend()

proc nimCompile(source: string, flags = "", outPath = "", nimcache = "") =
  var cmd = "nim c " & flags
  if nimcache.len > 0:
    cmd.add " --nimcache:" & quoteShell(nimcache)
  if outPath.len > 0:
    cmd.add " --out:" & quoteShell(outPath)
  cmd.add " " & quoteShell(source)
  sh cmd

proc nimRun(source: string, flags = "", outPath = "", nimcache = "") =
  var cmd = "nim r " & flags
  if nimcache.len > 0:
    cmd.add " --nimcache:" & quoteShell(nimcache)
  if outPath.len > 0:
    cmd.add " --out:" & quoteShell(outPath)
  cmd.add " " & quoteShell(source)
  sh cmd

proc compileGlApp(source, nimcache: string, release = false) =
  buildOkysGl()
  let mode = if release: " -d:release" else: " -d:debug"
  nimCompile(source, GlfwFlags & mode, nimcache = nimcache)

proc runGlApp(source, outPath, nimcache: string) =
  buildOkysGl()
  nimRun(source, CoreFlags & " -d:debug", outPath = outPath, nimcache = nimcache)

proc compileWgpuApp(source, nimcache: string) =
  buildOkysWgpu()
  buildWgpuBackendIfNeeded()
  nimCompile(source, wgpuFlags() & " -d:debug", nimcache = nimcache)

task test, "build test example":
  compileGlApp("examples/test", "/tmp/ops_example_test_d")

task paneltest, "build panel test example":
  compileGlApp("examples/paneltest", "/tmp/ops_paneltest_d")

task minimal, "build minimal wgpu example":
  compileWgpuApp("examples/minimal", "/tmp/ops_minimal_d")

task layoutInspectorDemo, "build layout inspector demo":
  compileGlApp("examples/layout_inspector_demo", "/tmp/ops_layout_inspector_demo_d")

task layoutAttachDemo, "build layout attach demo":
  compileGlApp("examples/layout_attach_demo", "/tmp/ops_layout_attach_demo_d")

task layoutAspectDemo, "build layout aspect-ratio demo":
  compileGlApp("examples/layout_aspect_demo", "/tmp/ops_layout_aspect_demo_d")

task layoutErrorsDemo, "build layout diagnostics demo":
  compileGlApp("examples/layout_errors_demo", "/tmp/ops_layout_errors_demo_d")

task layoutStressDemo, "build layout stress demo":
  compileGlApp("examples/layout_stress_demo", "/tmp/ops_layout_stress_demo_d")

task layoutDemos, "build every layout-focused demo":
  compileGlApp("examples/layout_inspector_demo", "/tmp/ops_layout_inspector_demo_d")
  compileGlApp("examples/layout_attach_demo", "/tmp/ops_layout_attach_demo_d")
  compileGlApp("examples/layout_aspect_demo", "/tmp/ops_layout_aspect_demo_d")
  compileGlApp("examples/layout_errors_demo", "/tmp/ops_layout_errors_demo_d")
  compileGlApp("examples/layout_stress_demo", "/tmp/ops_layout_stress_demo_d")

task waylandMinimal, "build native Wayland minimal example":
  buildWaylandBackend()
  nimCompile(
    "examples/wayland_minimal",
    WaylandFlags & " -d:debug",
    nimcache = "/tmp/ops_wayland_minimal_d",
  )

task waylandWgpuMinimal, "build native Wayland wgpu minimal example":
  buildOkysWgpu()
  buildWaylandBackend()
  nimCompile(
    "examples/wayland_wgpu_minimal",
    waylandWgpuFlags() & " -d:debug",
    nimcache = "/tmp/ops_wayland_wgpu_minimal_d",
  )

task testLayout, "run headless layout tests":
  runGlApp("tests/test_layout", "/tmp/ops_test_layout", "/tmp/ops_test_layout_d")

task testAlgorithms, "run headless algorithm tests":
  runGlApp(
    "tests/test_algorithms", "/tmp/ops_test_algorithms", "/tmp/ops_test_algorithms_d"
  )

task testSelection, "run headless item selection helper tests":
  buildOkysGl()
  nimRun(
    "tests/test_selection",
    CoreFlags & " -d:debug",
    outPath = "/tmp/ops_test_selection",
    nimcache = "/tmp/ops_test_selection_d",
  )

task testWidgetBehavior, "run headless widget behavior tests":
  runGlApp(
    "tests/test_widget_behavior", "/tmp/ops_test_widget_behavior",
    "/tmp/ops_test_widget_behavior_d",
  )

task testMenuMacro, "compile menu macro syntax smoke":
  buildOkysGl()
  nimCompile(
    "tests/test_menu_macro",
    CoreFlags & " -d:debug",
    outPath = "/tmp/ops_test_menu_macro",
    nimcache = "/tmp/ops_test_menu_macro_d",
  )

# Per-widget headless behaviour tests (share tests/widget_test_common.nim).

const WidgetBehaviorTests = [
  "popup", "dropdown", "menu", "slider", "scrollbar", "colorpicker", "textinput",
  "adversarial", "fuzz",
]

proc runHeadlessTest(name: string) =
  buildOkysGl()
  nimRun(
    "tests/test_" & name,
    CoreFlags & " -d:debug",
    outPath = "/tmp/ops_test_" & name,
    nimcache = "/tmp/ops_test_" & name & "_d",
  )

# Windowed integration tests run against a real (hidden) WebGPU window/context,
# so they use the wgpu flags and need a GPU/display.
const WindowTests = ["textinput", "textarea", "slider", "scrollbar"]

proc runWindowTest(name: string) =
  buildOkysWgpu()
  nimRun(
    "tests/test_window_" & name,
    glfwWgpuFlags() & " -d:debug",
    outPath = "/tmp/ops_win_" & name,
    nimcache = "/tmp/ops_win_" & name & "_d",
  )

proc runAllHeadlessTests() =
  for name in [
    "algorithms", "input_backend", "layout", "selection", "widget_behavior",
  ]:
    buildOkysGl()
    nimRun(
      "tests/test_" & name,
      CoreFlags & " -d:debug",
      outPath = "/tmp/ops_test_" & name,
      nimcache = "/tmp/ops_test_" & name & "_d",
    )
  for name in WidgetBehaviorTests:
    runHeadlessTest(name)
  when defined(linux):
    buildWaylandBackend()
    nimRun(
      "tests/test_wayland_backend",
      WaylandFlags & " -d:debug",
      outPath = "/tmp/ops_test_wayland_backend",
      nimcache = "/tmp/ops_test_wayland_backend_d",
    )

task testPopup, "run headless popup tests":
  runHeadlessTest("popup")

task testDropdown, "run headless dropdown tests":
  runHeadlessTest("dropdown")

task testMenu, "run headless menu tests":
  runHeadlessTest("menu")

task testSlider, "run headless slider tests":
  runHeadlessTest("slider")

task testScrollbar, "run headless scrollbar tests":
  runHeadlessTest("scrollbar")

task testColorPicker, "run headless color picker tests":
  runHeadlessTest("colorpicker")

task testTextInput, "run headless text field/area tests":
  runHeadlessTest("textinput")

task testAdversarial, "run adversarial cross-widget tests":
  runHeadlessTest("adversarial")

task testFuzz, "run invariant-based randomized tests":
  runHeadlessTest("fuzz")

task benchTextEditing, "profile representative text editing workloads":
  buildOkysWgpu()
  nimRun(
    "tests/bench_text_editing",
    glfwWgpuFlags() & " -d:release",
    outPath = "/tmp/ops_bench_text_editing",
    nimcache = "/tmp/ops_bench_text_editing_r",
  )

task testWindowTextInput, "run windowed text field tests (wgpu)":
  runWindowTest("textinput")

task testWindowTextArea, "run windowed text area tests (wgpu)":
  runWindowTest("textarea")

task testWindowSlider, "run windowed slider cursor-capture tests (wgpu)":
  runWindowTest("slider")

task testWindowScrollbar, "run windowed scrollbar cursor-capture tests (wgpu)":
  runWindowTest("scrollbar")

task testWindow, "run every windowed (wgpu) integration test":
  for name in WindowTests:
    runWindowTest(name)

task testHeadless, "run every headless test suite":
  runAllHeadlessTests()

task testAll, "run every headless suite and every windowed (wgpu) test":
  runAllHeadlessTests()
  for name in WindowTests:
    runWindowTest(name)

task testRelease, "build release test example":
  compileGlApp("examples/test", "/tmp/ops_example_test_r", release = true)

task paneltestRelease, "build release panel test example":
  compileGlApp("examples/paneltest", "/tmp/ops_paneltest_r", release = true)

task tidy, "format sources and remove generated example binaries":
  for path in walkDirRec("."):
    if path.startsWith("./.git") or path.startsWith("./ops/wayland/.zig-cache"):
      continue
    if path.endsWith(".nim") or path.endsWith(".nims") or path.endsWith(".nimble"):
      sh "nph " & quoteShell(path)

  sh "zig fmt " & quoteShell("ops/wayland/build.zig") & " " &
    quoteShell("ops/wayland/ops_wayland.zig")

  var cleanup = "rm -f"
  for path in [
    "examples/test", "examples/test.exe", "examples/paneltest",
    "examples/paneltest.exe", "examples/minimal", "examples/minimal.exe",
    "examples/layout_inspector_demo", "examples/layout_inspector_demo.exe",
    "examples/layout_attach_demo", "examples/layout_attach_demo.exe",
    "examples/layout_aspect_demo", "examples/layout_aspect_demo.exe",
    "examples/layout_errors_demo", "examples/layout_errors_demo.exe",
    "examples/layout_stress_demo", "examples/layout_stress_demo.exe",
    "examples/wayland_minimal", "examples/wayland_minimal.exe",
    "examples/wayland_wgpu_minimal", "examples/wayland_wgpu_minimal.exe",
  ]:
    cleanup.add " " & quoteShell(path)
  sh cleanup
