import std/options
import std/math
import std/sets

import ops/okys

import ops/types
import ops/core
import ops/drawing
import ops/layout
import ops/rect
import ops/input
import ops/defaults
import ops/internal/widget_behavior
import ops/widgets/common
import ops/utils

# RadioButtonsDrawProc*
type RadioButtonsDrawProc* = proc(
  vg: OpsRenderContext,
  id: ItemId,
  x, y, w, h: float,
  buttonIdx, numButtons: Natural,
  label: string,
  state: WidgetState,
  style: RadioButtonsStyle,
)

# DefaultRadioButtonDrawProc
let DefaultRadioButtonDrawProc*: RadioButtonsDrawProc = proc(
    vg: OpsRenderContext,
    id: ItemId,
    x, y, w, h: float,
    buttonIdx, numButtons: Natural,
    label: string,
    state: WidgetState,
    style: RadioButtonsStyle,
) =
  alias(s, style)

  let (fillColor, strokeColor) =
    case state
    of wsNormal, wsDisabled:
      (s.buttonFillColor, s.buttonStrokeColor)
    of wsHover:
      (s.buttonFillColorHover, s.buttonStrokeColorHover)
    of wsDown, wsActiveDown:
      (s.buttonFillColorDown, s.buttonStrokeColorDown)
    of wsActive:
      (s.buttonFillColorActive, s.buttonStrokeColorActive)
    of wsActiveHover:
      (s.buttonFillColorActiveHover, s.buttonStrokeColorActiveHover)

  vg.fillColor(fillColor)
  vg.strokeColor(strokeColor)
  vg.strokeWidth(s.buttonStrokeWidth)

  vg.beginPath()

  let
    first = (buttonIdx == 0)
    last = (buttonIdx == numButtons - 1)

  let cr = s.buttonCornerRadius
  if first:
    vg.roundedRect(x, y, w, h, cr, 0, 0, cr)
  elif last:
    vg.roundedRect(x, y, w, h, 0, cr, cr, 0)
  else:
    vg.rect(x, y, w, h)

  vg.fill()
  vg.stroke()

  vg.drawLabel(x, y, w, h, label, state, s.label)
# DefaultRadioButtonGridDrawProc
let DefaultRadioButtonGridDrawProc*: RadioButtonsDrawProc = proc(
    vg: OpsRenderContext,
    id: ItemId,
    x, y, w, h: float,
    buttonIdx, numButtons: Natural,
    label: string,
    state: WidgetState,
    style: RadioButtonsStyle,
) =
  alias(s, style)

  let (x, y, w, h) = snapToGrid(x, y, w, h, s.buttonStrokeWidth)

  let (fillColor, strokeColor) =
    case state
    of wsNormal, wsDisabled:
      (s.buttonFillColor, s.buttonStrokeColor)
    of wsHover:
      (s.buttonFillColorHover, s.buttonStrokeColorHover)
    of wsDown, wsActiveDown:
      (s.buttonFillColorDown, s.buttonStrokeColorDown)
    of wsActive:
      (s.buttonFillColorActive, s.buttonStrokeColorActive)
    of wsActiveHover:
      (s.buttonFillColorActiveHover, s.buttonStrokeColorActiveHover)

  vg.fillColor(fillColor)
  vg.strokeColor(strokeColor)
  vg.strokeWidth(s.buttonStrokeWidth)

  vg.beginPath()
  vg.roundedRect(x, y, w, h, s.buttonCornerRadius)
  vg.fill()
  vg.stroke()

  vg.drawLabel(x, y, w, h, label, state, s.label)
# radioButtons()
