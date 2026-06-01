import ops/okys

import ops/types
import ops/core
import ops/drawing
import ops/input
import ops/layout
import ops/rect
import ops/utils

proc image*(id: ItemId, x, y, w, h: float, paint: Paint) =
  alias(ui, g_uiState)
  let (x, y) = addDrawOffset(x, y)
  let slot = layoutSlot(id, rect(x, y, w, h))

  addLayoutDrawLayer(ui.currentLayer, slot.nodeId, vg, bounds):
    vg.drawImage(bounds.x, bounds.y, bounds.w, bounds.h, paint)

proc image*(x, y, w, h: float, paint: Paint) =
  alias(ui, g_uiState)
  let (x, y) = addDrawOffset(x, y)
  let slot = layoutDrawSlot(0, rect(x, y, w, h))

  addLayoutDrawLayer(ui.currentLayer, slot.nodeId, vg, bounds):
    vg.drawImage(bounds.x, bounds.y, bounds.w, bounds.h, paint)

template image*(paint: Paint) =
  let i = instantiationInfo(fullPaths = true)
  let id = nextId(i.filename, i.line)

  autoLayoutPre()
  image(
    id,
    g_uiState.autoLayoutState.x,
    autoLayoutNextY(),
    autoLayoutNextItemWidth(),
    autoLayoutNextItemHeight(),
    paint,
  )
  autoLayoutPost()
