import ops/okys

import ops/types
import ops/core
import ops/drawing
import ops/layout
import ops/rect
import ops/defaults
import ops/utils

proc labelWithSlot*(
    slot: LayoutSlot,
    id: ItemId,
    labelText: string,
    state: WidgetState = wsNormal,
    style: LabelStyle = borrowDefaultLabelStyle(),
) =
  alias(ui, g_uiState)

  addLayoutDrawLayer(ui.currentLayer, slot.nodeId, vg, bounds):
    vg.drawLabel(bounds.x, bounds.y, bounds.w, bounds.h, labelText, state, style)

proc label*(
    id: ItemId,
    x, y, w, h: float,
    labelText: string,
    state: WidgetState = wsNormal,
    style: LabelStyle = borrowDefaultLabelStyle(),
) =
  let (x, y) = addDrawOffset(x, y)
  let slot = textLayoutSlot(id, rect(x, y, w, h), labelText, style)
  labelWithSlot(slot, id, labelText, state, style)

proc label*(
    x, y, w, h: float,
    labelText: string,
    state: WidgetState = wsNormal,
    style: LabelStyle = borrowDefaultLabelStyle(),
) =
  label(0, x, y, w, h, labelText, state, style)

proc label*(
    labelText: string,
    state: WidgetState = wsNormal,
    style: LabelStyle = borrowDefaultLabelStyle(),
) =
  alias(ui, g_uiState)

  autoLayoutPre()

  label(
    0,
    ui.autoLayoutState.x,
    autoLayoutNextY(),
    autoLayoutNextItemWidth(),
    autoLayoutNextItemHeight(),
    labelText,
    state,
    style,
  )

  autoLayoutPost()
