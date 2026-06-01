when defined(opsGlfwAdapter) and not defined(waylandBackend):
  from glfw as glfwLib import nil

  var
    g_glfwWindow: glfwLib.Window
    g_cursorArrow: glfwLib.Cursor
    g_cursorIBeam: glfwLib.Cursor
    g_cursorCrosshair: glfwLib.Cursor
    g_cursorHand: glfwLib.Cursor
    g_cursorResizeEW: glfwLib.Cursor
    g_cursorResizeNS: glfwLib.Cursor
    g_cursorResizeNWSE: glfwLib.Cursor
    g_cursorResizeNESW: glfwLib.Cursor
    g_cursorResizeAll: glfwLib.Cursor

  proc opsModifierKeys(mods: set[glfwLib.ModifierKey]): set[ModifierKey] =
    if glfwLib.mkShift in mods:
      result.incl(mkShift)
    if glfwLib.mkCtrl in mods:
      result.incl(mkCtrl)
    if glfwLib.mkAlt in mods:
      result.incl(mkAlt)
    if glfwLib.mkSuper in mods:
      result.incl(mkSuper)
    if glfwLib.mkCapsLock in mods:
      result.incl(mkCapsLock)
    if glfwLib.mkNumLock in mods:
      result.incl(mkNumLock)

  proc useWindow*(win: glfwLib.Window) =
    g_glfwWindow = win

  proc setWindow*(win: glfwLib.Window) =
    useWindow(win)

  proc activeGlfwWindow(): glfwLib.Window =
    if g_glfwWindow.isNil:
      g_glfwWindow = glfwLib.currentContext()
    g_glfwWindow

  proc createGlfwCursors() =
    g_cursorArrow = glfwLib.createStandardCursor(glfwLib.CursorShape(ord(csArrow)))
    g_cursorIBeam = glfwLib.createStandardCursor(glfwLib.CursorShape(ord(csIBeam)))
    g_cursorCrosshair =
      glfwLib.createStandardCursor(glfwLib.CursorShape(ord(csCrosshair)))
    g_cursorHand = glfwLib.createStandardCursor(glfwLib.CursorShape(ord(csHand)))
    g_cursorResizeEW =
      glfwLib.createStandardCursor(glfwLib.CursorShape(ord(csResizeEW)))
    g_cursorResizeNS =
      glfwLib.createStandardCursor(glfwLib.CursorShape(ord(csResizeNS)))
    g_cursorResizeNWSE =
      glfwLib.createStandardCursor(glfwLib.CursorShape(ord(csResizeNWSE)))
    g_cursorResizeNESW =
      glfwLib.createStandardCursor(glfwLib.CursorShape(ord(csResizeNESW)))
    g_cursorResizeAll =
      glfwLib.createStandardCursor(glfwLib.CursorShape(ord(csResizeAll)))

  proc destroyGlfwCursors() =
    if not g_cursorArrow.isNil:
      glfwLib.destroyCursor(g_cursorArrow)
    if not g_cursorIBeam.isNil:
      glfwLib.destroyCursor(g_cursorIBeam)
    if not g_cursorCrosshair.isNil:
      glfwLib.destroyCursor(g_cursorCrosshair)
    if not g_cursorHand.isNil:
      glfwLib.destroyCursor(g_cursorHand)
    if not g_cursorResizeEW.isNil:
      glfwLib.destroyCursor(g_cursorResizeEW)
    if not g_cursorResizeNS.isNil:
      glfwLib.destroyCursor(g_cursorResizeNS)
    if not g_cursorResizeNWSE.isNil:
      glfwLib.destroyCursor(g_cursorResizeNWSE)
    if not g_cursorResizeNESW.isNil:
      glfwLib.destroyCursor(g_cursorResizeNESW)
    if not g_cursorResizeAll.isNil:
      glfwLib.destroyCursor(g_cursorResizeAll)
    g_cursorArrow = nil
    g_cursorIBeam = nil
    g_cursorCrosshair = nil
    g_cursorHand = nil
    g_cursorResizeEW = nil
    g_cursorResizeNS = nil
    g_cursorResizeNWSE = nil
    g_cursorResizeNESW = nil
    g_cursorResizeAll = nil

  proc installGlfwPlatformHooks*() =
    let hooks = PlatformHooks(
      windowSize: proc(): tuple[w, h: float] =
        let win = activeGlfwWindow()
        if win.isNil:
          return (0.0, 0.0)
        let (w, h) = glfwLib.size(win)
        (w.float, h.float),
      surfaceSize: proc(): tuple[w, h: float] =
        let win = activeGlfwWindow()
        if win.isNil:
          return (0.0, 0.0)
        let (w, h) = glfwLib.framebufferSize(win)
        (w.float, h.float),
      contentScale: proc(): tuple[x, y: float] =
        let win = activeGlfwWindow()
        if win.isNil:
          return (1.0, 1.0)
        let (x, y) = glfwLib.contentScale(win)
        (x.float, y.float),
      cursorPos: proc(): tuple[x, y: float] =
        let win = activeGlfwWindow()
        if win.isNil:
          return (g_uiState.mx, g_uiState.my)
        let (x, y) = glfwLib.cursorPos(win)
        (x.float, y.float),
      setCursorPos: proc(x, y: float) =
        let win = activeGlfwWindow()
        if not win.isNil:
          glfwLib.`cursorPos=`(win, (x, y))
      ,
      setCursorShape: proc(shape: CursorShape) =
        let win = activeGlfwWindow()
        if win.isNil:
          return
        var c: glfwLib.Cursor
        if shape == csArrow:
          c = g_cursorArrow
        elif shape == csIBeam:
          c = g_cursorIBeam
        elif shape == csCrosshair:
          c = g_cursorCrosshair
        elif shape == csHand:
          c = g_cursorHand
        elif shape == csResizeEW:
          c = g_cursorResizeEW
        elif shape == csResizeNS:
          c = g_cursorResizeNS
        elif shape == csResizeNWSE:
          c = g_cursorResizeNWSE
        elif shape == csResizeNESW:
          c = g_cursorResizeNESW
        elif shape == csResizeAll:
          c = g_cursorResizeAll
        if not c.isNil:
          glfwLib.`cursor=`(win, c)
      ,
      setCursorMode: proc(mode: PlatformCursorMode) =
        let win = activeGlfwWindow()
        if not win.isNil:
          glfwLib.`cursorMode=`(
            win,
            case mode
            of pcmNormal: glfwLib.cmNormal
            of pcmHidden: glfwLib.cmHidden
            of pcmDisabled: glfwLib.cmDisabled
            ,
          )
      ,
      clipboardGet: proc(): string =
        let win = activeGlfwWindow()
        if win.isNil:
          ""
        else:
          $glfwLib.clipboardString(win),
      clipboardSet: proc(text: string) =
        let win = activeGlfwWindow()
        if not win.isNil:
          glfwLib.`clipboardString=`(win, text)
      ,
    )
    setPlatformHooks(hooks)

  proc installGlfwInputCallbacks*() =
    let win = activeGlfwWindow()
    if win.isNil:
      return
    win.keyCb = proc(
        win: glfwLib.Window,
        key: glfwLib.Key,
        scanCode: int32,
        action: glfwLib.KeyAction,
        mods: set[glfwLib.ModifierKey],
    ) =
      {.push warning[HoleEnumConv]: off.}
      discard scanCode
      queueKeyEvent(Key(ord(key)), KeyAction(ord(action)), opsModifierKeys(mods))
      {.pop.}
    win.charCb = proc(win: glfwLib.Window, codePoint: Rune) =
      queueChar(codePoint)
    win.mouseButtonCb = proc(
        win: glfwLib.Window,
        button: glfwLib.MouseButton,
        pressed: bool,
        mods: set[glfwLib.ModifierKey],
    ) =
      let (x, y) = platformCursorPos()
      queueMouseButtonEvent(
        MouseButton(ord(button)), pressed, x.float, y.float, opsModifierKeys(mods)
      )
    win.scrollCb = proc(win: glfwLib.Window, offset: tuple[x, y: float64]) =
      queueScrollEvent(offset.x, offset.y)
    win.cursorPositionCb = proc(win: glfwLib.Window, pos: tuple[x, y: float64]) =
      queueMouseMove(pos.x.float, pos.y.float)
      requestFrames(1)
    win.windowFocusCb = proc(win: glfwLib.Window, focus: bool) =
      if not focus:
        clearInputState()

  proc installGlfwPlatformAdapter*() =
    createGlfwCursors()
    installGlfwPlatformHooks()
    installGlfwInputCallbacks()

  proc deinitGlfwPlatformAdapter*() =
    destroyGlfwCursors()

  proc init*(vg: OpsRenderContext, glfwGetProcAddress: proc) =
    initWithPlatform(vg, glfwGetProcAddress)
    installGlfwPlatformAdapter()

    when not defined(opsWgpu) and not defined(opsVulkan):
      glfwLib.swapInterval(1)

  proc deinit*() =
    deinitGlfwPlatformAdapter()
    deinitCore()
