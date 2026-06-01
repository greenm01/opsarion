type
  ItemSelectMode* = enum
    ismReplace
    ismToggle
    ismRange

  ItemSelection* = object
    active*: int
    anchor*: int
    selected*: seq[bool]

func initItemSelection*(itemCount: Natural = 0, selected: int = -1): ItemSelection =
  result.active = -1
  result.anchor = -1
  result.selected = newSeq[bool](itemCount)
  if selected >= 0 and selected < itemCount.int:
    result.active = selected
    result.anchor = selected
    result.selected[selected] = true

func itemCount*(selection: ItemSelection): Natural =
  selection.selected.len.Natural

func hasActiveItem*(selection: ItemSelection): bool =
  selection.active >= 0 and selection.active < selection.selected.len

func clampItemIndex*(selection: ItemSelection, index: int): int =
  if selection.selected.len == 0:
    -1
  else:
    max(0, min(index, selection.selected.high))

proc setItemCount*(selection: var ItemSelection, itemCount: Natural) =
  selection.selected.setLen(itemCount)
  if selection.active >= itemCount.int:
    selection.active = itemCount.int - 1
  if selection.anchor >= itemCount.int:
    selection.anchor = selection.active
  if itemCount == 0:
    selection.active = -1
    selection.anchor = -1

proc clear*(selection: var ItemSelection) =
  for item in selection.selected.mitems:
    item = false
  selection.active = -1
  selection.anchor = -1

func isSelected*(selection: ItemSelection, index: Natural): bool =
  index < selection.selected.len.Natural and selection.selected[index]

proc selectOnly*(selection: var ItemSelection, index: Natural) =
  if index >= selection.selected.len.Natural:
    return
  for i in 0 .. selection.selected.high:
    selection.selected[i] = i == index.int
  selection.active = index.int
  selection.anchor = index.int

proc toggle*(selection: var ItemSelection, index: Natural) =
  if index >= selection.selected.len.Natural:
    return
  selection.selected[index] = not selection.selected[index]
  selection.active = index.int
  selection.anchor = index.int

proc selectRange*(selection: var ItemSelection, index: Natural) =
  if index >= selection.selected.len.Natural:
    return
  let anchor =
    if selection.anchor >= 0 and selection.anchor < selection.selected.len:
      selection.anchor
    else:
      index.int
  let
    first = min(anchor, index.int)
    last = max(anchor, index.int)
  for i in 0 .. selection.selected.high:
    selection.selected[i] = i >= first and i <= last
  selection.active = index.int
  selection.anchor = anchor

proc select*(selection: var ItemSelection, index: Natural, mode: ItemSelectMode) =
  case mode
  of ismReplace:
    selection.selectOnly(index)
  of ismToggle:
    selection.toggle(index)
  of ismRange:
    selection.selectRange(index)

proc moveActive*(
    selection: var ItemSelection, delta: int, extend: bool = false, wrap: bool = false
) =
  if selection.selected.len == 0:
    selection.active = -1
    selection.anchor = -1
    return

  var next =
    if selection.hasActiveItem:
      selection.active + delta
    elif delta < 0:
      selection.selected.high
    else:
      0

  if wrap:
    let count = selection.selected.len
    next = ((next mod count) + count) mod count
  else:
    next = max(0, min(next, selection.selected.high))

  if extend:
    selection.selectRange(next.Natural)
  else:
    selection.selectOnly(next.Natural)

func selectedCount*(selection: ItemSelection): Natural =
  for item in selection.selected:
    if item:
      inc(result)

func selectedIndices*(selection: ItemSelection): seq[Natural] =
  for i, item in selection.selected:
    if item:
      result.add(i.Natural)
