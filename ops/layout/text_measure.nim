import std/math
import std/options
import std/strformat
import std/strutils
import std/tables
import std/unicode

import ops/okys
import ops/core
import ops/drawing
import ops/input
import ops/internal/layout_solver
import ops/rect
import ops/types
import ops/utils

export layout_solver

# Layout engine: standard auto-layout and hierarchical blocks

const LayoutTextBreakChars = [
  " ", "\u2000", "\u2001", "\u2002", "\u2003", "\u2004", "\u2005", "\u2006", "\u2008",
  "\u2009", "\u200a", "\u205f", "\u3000", "-", "\u00ad", "\u2010", "\u2012", "\u2013",
  "|", "\n",
]

func isLayoutTextBreak(r: Rune): bool =
  let s = $r
  for ch in LayoutTextBreakChars:
    if s == ch:
      return true

func textMeasureSegments(text: string): seq[string] =
  var segment = ""
  for rune in text.runes:
    if rune.isLayoutTextBreak:
      if segment.len > 0:
        result.add(segment)
        segment.setLen(0)
    else:
      segment.add($rune)

  if segment.len > 0:
    result.add(segment)

  if result.len == 0:
    result.add("")

func explicitLineCount(text: string): int =
  max(1, text.count("\n") + 1)

proc fallbackMeasureText(text: string, fontSize, maxWidth: float): TextMeasure =
  let
    fontSize = if fontSize > 0: fontSize else: 14.0
    advance = max(1.0, fontSize * 0.5)
    prefWidth = text.runeLen.float * advance
    lineHeight = fontSize * 1.4

  var longest = 0
  for segment in text.textMeasureSegments:
    longest = max(longest, segment.runeLen)

  let lineCount =
    if maxWidth <= 0 or maxWidth >= LayoutInfinity * 0.5:
      text.explicitLineCount
    else:
      max(text.explicitLineCount, ceil(prefWidth / maxWidth).int)

  TextMeasure(
    minWidth: longest.float * advance,
    prefWidth: prefWidth,
    lineHeight: lineHeight,
    lineCount: lineCount,
  )

# Memoize text measurement. The layout solver re-measures every text node each
# frame, but for static text the result is identical — measuring via okys is the
# dominant per-frame cost. Cache keyed by (text, fontSize, fontFace, maxWidth),
# invalidated whenever a font is loaded (g_fontGeneration).
var g_measureCache: Table[string, TextMeasure]
var g_measureCacheGen = -1

proc measureLayoutText*(
    text: string, fontSize: float, fontFace: string, maxWidth: float
): TextMeasure =
  let
    fontSize = if fontSize > 0: fontSize else: 14.0
    fontFace = if fontFace.len > 0: fontFace else: "sans-bold"

  if g_renderContext == nil:
    return fallbackMeasureText(text, fontSize, maxWidth)

  let gen = fontGeneration()
  if gen != g_measureCacheGen:
    g_measureCache.clear()
    g_measureCacheGen = gen
  let cacheKey = text & '\x00' & $fontSize & '\x00' & fontFace & '\x00' & $maxWidth
  g_measureCache.withValue(cacheKey, cached):
    return cached[]

  g_renderContext.useFont(fontSize, name = fontFace)

  # Use okys' real font line height so measured row heights match what is drawn
  # (textBox advances by textMetrics().lineHeight). Fall back to a ratio if the
  # font has no metrics yet.
  let metricsLineHeight = g_renderContext.textMetrics().lineHeight
  let lineHeight =
    if metricsLineHeight > 0:
      metricsLineHeight
    else:
      fontSize * 1.4

  var minWidth = 0.0
  for segment in text.textMeasureSegments:
    minWidth = max(minWidth, g_renderContext.textWidth(segment))

  let lineCount =
    if maxWidth <= 0 or maxWidth >= LayoutInfinity * 0.5:
      text.explicitLineCount
    else:
      max(1, textBreakLines(text, maxWidth).len)

  result = TextMeasure(
    minWidth: minWidth,
    prefWidth: g_renderContext.textWidth(text),
    lineHeight: lineHeight,
    lineCount: lineCount,
  )
  g_measureCache[cacheKey] = result
