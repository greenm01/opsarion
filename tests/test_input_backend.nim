import std/options
import std/unittest
import std/unicode

import ops/core
import ops/input
import ops/ringbuffer
import ops/types

proc resetInput() =
  g_uiState = UIState.default
  g_uiState.scale = 2.0
  g_eventBuf = initRingBuffer[Event](8)
  clearCharBuf()

suite "backend-neutral input queue":
  test "key events update key state and queue shortcut events":
    resetInput()

    queueKeyEvent(keyA, kaDown, {mkShift})

    check isKeyDown(keyA)
    check g_eventBuf.canRead()
    let ev = g_eventBuf.read().get
    check ev.kind == ekKey
    check ev.key == keyA
    check ev.action == kaDown
    check ev.mods == {mkShift}

    queueKeyEvent(keyA, kaUp, {})
    check not isKeyDown(keyA)

  test "text input is independent from key events":
    resetInput()

    queueChar(Rune(ord('o')))
    queueChar(Rune(ord('k')))

    check consumeCharBuf() == "ok"
    check charBufEmpty()
    check not g_eventBuf.canRead()

  test "mouse coordinates are normalized through the current scale":
    resetInput()

    queueMouseMove(20, 40)
    check g_uiState.mx == 10
    check g_uiState.my == 20

    queueMouseButtonEvent(mbLeft, true, 24, 44, {mkCtrl})
    check g_eventBuf.canRead()
    let ev = g_eventBuf.read().get
    check ev.kind == ekMouseButton
    check ev.button == mbLeft
    check ev.pressed
    check ev.x == 12
    check ev.y == 22
    check ev.mods == {mkCtrl}

  test "focus loss cleanup clears stuck keyboard and mouse state":
    resetInput()
    queueKeyEvent(keyA, kaDown, {})
    g_uiState.mbLeftDown = true
    g_uiState.mbRightDown = true
    g_uiState.widgetMouseDrag = true

    clearInputState()

    check not isKeyDown(keyA)
    check not g_uiState.mbLeftDown
    check not g_uiState.mbRightDown
    check not g_uiState.widgetMouseDrag

  test "scroll events pass through as abstract input":
    resetInput()

    queueScrollEvent(1.5, -2.25)

    check g_eventBuf.canRead()
    let ev = g_eventBuf.read().get
    check ev.kind == ekScroll
    check ev.ox == 1.5
    check ev.oy == -2.25
