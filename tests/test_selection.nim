import std/unittest

import ops/selection

suite "item selection helpers":
  test "initial selection marks active and anchor":
    let selection = initItemSelection(5, selected = 2)

    check selection.itemCount == 5
    check selection.active == 2
    check selection.anchor == 2
    check selection.selectedIndices == @[2.Natural]

  test "replace, toggle, and clear update the selected set":
    var selection = initItemSelection(4)

    selection.select(1, ismReplace)
    check selection.selectedIndices == @[1.Natural]

    selection.select(3, ismToggle)
    check selection.selectedIndices == @[1.Natural, 3.Natural]
    check selection.active == 3
    check selection.anchor == 3

    selection.select(3, ismToggle)
    check selection.selectedIndices == @[1.Natural]
    check selection.active == 3

    selection.clear()
    check selection.selectedCount == 0
    check selection.active == -1
    check selection.anchor == -1

  test "range selection uses a stable anchor":
    var selection = initItemSelection(8, selected = 2)

    selection.select(5, ismRange)
    check selection.selectedIndices == @[2.Natural, 3.Natural, 4.Natural, 5.Natural]
    check selection.active == 5
    check selection.anchor == 2

    selection.select(1, ismRange)
    check selection.selectedIndices == @[1.Natural, 2.Natural]
    check selection.active == 1
    check selection.anchor == 2

  test "active movement clamps and optionally wraps":
    var selection = initItemSelection(3, selected = 1)

    selection.moveActive(10)
    check selection.selectedIndices == @[2.Natural]
    check selection.active == 2

    selection.moveActive(1, wrap = true)
    check selection.selectedIndices == @[0.Natural]
    check selection.active == 0

    selection.moveActive(-1, wrap = true)
    check selection.selectedIndices == @[2.Natural]
    check selection.active == 2

  test "extended movement selects a range from the anchor":
    var selection = initItemSelection(5, selected = 1)

    selection.moveActive(2, extend = true)
    check selection.selectedIndices == @[1.Natural, 2.Natural, 3.Natural]
    check selection.active == 3
    check selection.anchor == 1

  test "resizing clamps active state":
    var selection = initItemSelection(5, selected = 4)

    selection.setItemCount(3)
    check selection.itemCount == 3
    check selection.active == 2
    check selection.anchor == 2

    selection.setItemCount(0)
    check selection.itemCount == 0
    check selection.active == -1
    check selection.anchor == -1
