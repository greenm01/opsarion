proc isKeyDown*(key: Key): bool =
  if key == keyUnknown:
    false
  else:
    g_uiState.keyStates[ord(key)]

proc clearKeyStates*() =
  for pressed in mitems(g_uiState.keyStates):
    pressed = false

proc clearPointerState*() =
  g_uiState.mbLeftDown = false
  g_uiState.mbRightDown = false
  g_uiState.mbMiddleDown = false
  g_uiState.widgetMouseDrag = false

proc clearInputState*() =
  clearKeyStates()
  clearPointerState()

proc shiftDown*(): bool =
  isKeyDown(keyLeftShift) or isKeyDown(keyRightShift)

proc altDown*(): bool =
  isKeyDown(keyLeftAlt) or isKeyDown(keyRightAlt)

proc ctrlDown*(): bool =
  isKeyDown(keyLeftControl) or isKeyDown(keyRightControl)

proc superDown*(): bool =
  isKeyDown(keyLeftSuper) or isKeyDown(keyRightSuper)

# Text editing

const NoSelection* = TextSelection(startPos: -1, endPos: 0)
