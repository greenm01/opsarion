import std/options

import glad/gl
import glfw
from glfw/wrapper import showWindow
import ops/okys

import ops
import example_quit

type
  LineWidth = enum
    lwThin = (0, "Thin")
    lwNormal = (1, "Normal")

  GridStyle = enum
    gsNone = (0, "None")
    gsSolid = (1, "Solid")
    gsLoose = (2, "Loose")
    gsCross = (3, "Cross")

  OutlineStyle = enum
    osNone = (0, "None")
    osCell = (1, "Cell")
    osSquareEdges = (2, "Square Edges")
    osRoundedEdges = (3, "Rounded Edges")
    osRoundedEdgesFilled = (4, "Filled Rounded Edges")

  OutlineFillStyle = enum
    ofsSolid = (0, "Solid")
    ofsHatched = (1, "Hatched")

  Theme = object
    general: GeneralStyle
    widget: WidgetStyle
    textField: TextFieldStyle
    dialog: DialogStyle
    window: WindowStyle
    statusBar: StatusBarStyle
    levelDropDown: LevelDropDownStyle
    aboutButton: AboutButtonStyle
    level: LevelStyle
    notesPane: NotesPaneStyle
    toolbarPane: ToolbarPaneStyle

  GeneralStyle = object
    backgroundColor: Color
    highlightColor: Color

  WidgetStyle = object
    bgColor: Color
    bgColorHover: Color
    bgColorDisabled: Color
    textColor: Color
    textColorDisabled: Color

  TextFieldStyle = object
    bgColorActive: Color
    textColorActive: Color
    cursorColor: Color
    selectionColor: Color

  DialogStyle = object
    titleBarBgColor: Color
    titleBarTextColor: Color
    backgroundColor: Color
    textColor: Color
    warningTextColor: Color

  WindowStyle = object
    backgroundColor: Color
    bgColorUnfocused: Color
    textColor: Color
    textColorUnfocused: Color
    modifiedFlagColor: Color
    buttonColor: Color
    buttonColorHover: Color
    buttonColorDown: Color

  StatusBarStyle = object
    backgroundColor: Color
    textColor: Color
    commandBgColor: Color
    commandColor: Color
    coordsColor: Color

  LevelDropDownStyle = object
    buttonColor: Color
    buttonColorHover: Color
    textColor: Color
    itemListColor: Color
    itemColor: Color
    itemColorHover: Color

  AboutButtonStyle = object
    color: Color
    colorHover: Color
    colorActive: Color

  LevelStyle = object
    backgroundColor: Color
    drawColor: Color
    lightDrawColor: Color
    lineWidth: LineWidth
    coordsColor: Color
    coordsHighlightColor: Color
    cursorColor: Color
    cursorGuideColor: Color
    gridStyleBackground: GridStyle
    gridColorBackground: Color
    gridStyleFloor: GridStyle
    gridColorFloor: Color
    selectionColor: Color
    pastePreviewColor: Color
    linkMarkerColor: Color
    bgHatch: bool
    bgHatchColor: Color
    bgHatchStrokeWidth: float
    bgHatchSpacingFactor: float
    outlineStyle: OutlineStyle
    outlineFillStyle: OutlineFillStyle
    outlineOverscan: bool
    outlineColor: Color
    outlineWidthFactor: float
    innerShadowColor: Color
    innerShadowWidthFactor: float
    outerShadowColor: Color
    outerShadowWidthFactor: float
    floorColor: array[9, Color]
    noteMarkerColor: Color
    noteCommentColor: Color
    noteIndexColor: Color
    noteIndexBgColor: array[4, Color]
    noteTooltipBgColor: Color
    noteTooltipTextColor: Color

  NotesPaneStyle = object
    textColor: Color
    indexColor: Color
    indexBgColor: array[4, Color]

  ToolbarPaneStyle = object
    buttonBgColor: Color
    buttonBgColorHover: Color

# Global renderer context
var vg: OpsRenderContext

### UI DATA ##################################################################
var
  sectionUserInterface = true
  sectionUserInterfaceGeneral = false
  sectionWidget = false
  sectionTextField = false
  sectionDialog = false
  sectionTitleBar = false
  sectionStatusBar = false
  sectionLeveldropDown = true
  sectionAboutButton = false

  sectionLevel = true
  sectionLevelGeneral = true
  sectionOutline = true
  sectionShadow = true
  sectionBackgroundHatch = true
  sectionFloorColors = true
  sectionNotes = true

  sectionPanes = true
  sectionNotesPane = true
  sectionToolbarPane = true

var currTheme: Theme

var
  themeName = "Default"
  themeAuthor = "chaos"

  section1 = true
  section2 = true

  dropDownVal1 = 0
  dropDownVal2 = 0
  dropDownVal3 = 0

  checkBoxVal1 = false
  checkBoxVal2 = false
  checkBoxVal3 = false
  checkBoxVal4 = false
  checkBoxVal5 = false
  checkBoxVal6 = false

##############################################################################

proc createWindow(): glfw.Window =
  var cfg = DefaultOpenglWindowConfig
  cfg.size = (w: 1000, h: 800)
  cfg.title = "Ops Test"
  cfg.resizable = true
  cfg.visible = false
  cfg.bits = (
    r: 8'i32.some,
    g: 8'i32.some,
    b: 8'i32.some,
    a: 8'i32.some,
    stencil: 8'i32.some,
    depth: 16'i32.some,
  )
  cfg.debugContext = true
  cfg.nMultiSamples = 4

  when defined(macosx):
    cfg.version = glv32
    cfg.forwardCompat = true
    cfg.profile = opCoreProfile

  newWindow(cfg)

proc loadData(vg: OpsRenderContext) =
  let regularFont = vg.createFont("sans", "data/Roboto-Regular.ttf")
  if regularFont == NoFont:
    quit "Could not add font italic.\n"

  let boldFont = vg.createFont("sans-bold", "data/Roboto-Bold.ttf")
  if boldFont == NoFont:
    quit "Could not add font italic.\n"

var propsSliderStyle = defaultSliderStyle()
propsSliderStyle.trackCornerRadius = 8.0
propsSliderStyle.valueCornerRadius = 6.0

proc renderUI() =
  ops.beginFrame()

  vg.beginPath()
  vg.rect(0, 0, ops.winWidth(), ops.winHeight())
  vg.fillColor(gray(0.3))
  vg.fill()

  ############################################################################

  var w = 314.0
  ops.beginScrollView(x = 100, y = 100, w = w, h = 600)

  var ap = DefaultAutoLayoutParams
  ap.rowWidth = w
  ap.rightPad = 16

  initAutoLayout(ap)

  if ops.sectionHeader("User Interface", sectionUserInterface):
    if ops.subSectionHeader("General", sectionUserInterfaceGeneral):
      ops.label("Background")
      ops.colorPicker(currTheme.general.backgroundColor)

      ops.label("Highlight")
      ops.colorPicker(currTheme.general.highlightColor)

    if ops.subSectionHeader("Widget", sectionWidget):
      ops.label("Background")
      ops.colorPicker(currTheme.widget.bgColor)

      ops.label("Background Hover")
      ops.colorPicker(currTheme.widget.bgColorHover)

      ops.label("Background Disabled")
      ops.colorPicker(currTheme.widget.bgColorDisabled)

      ops.label("Text")
      ops.colorPicker(currTheme.widget.textColor)

      ops.label("Text Disabled")
      ops.colorPicker(currTheme.widget.textColorDisabled)

    if ops.subSectionHeader("Text Field", sectionTextField):
      ops.label("Background Active")
      ops.colorPicker(currTheme.textField.bgColorActive)

      ops.label("Text Active")
      ops.colorPicker(currTheme.textField.textColorActive)

      ops.label("Cursor")
      ops.colorPicker(currTheme.textField.cursorColor)

      ops.label("Selection")
      ops.colorPicker(currTheme.textField.selectionColor)

    if ops.subSectionHeader("Dialog", sectionDialog):
      ops.label("Title Bar Background")
      ops.nextItemHeight(81)
      ops.colorPicker(currTheme.dialog.titleBarBgColor)

      ops.label("Title Bar Text")
      ops.colorPicker(currTheme.dialog.titleBarTextColor)

      ops.label("Background")
      ops.nextItemHeight(61)
      ops.colorPicker(currTheme.dialog.backgroundColor)

      ops.label("Text")
      ops.colorPicker(currTheme.dialog.textColor)

      ops.label("Warning Text")
      ops.colorPicker(currTheme.dialog.warningTextColor)

    if ops.subSectionHeader("Title Bar", sectionTitleBar):
      ops.label("Background")
      ops.colorPicker(currTheme.window.backgroundColor)

      ops.label("Background Unfocused")
      ops.colorPicker(currTheme.window.bgColorUnfocused)

      ops.label("Text")
      ops.colorPicker(currTheme.window.textColor)

      ops.label("Text Unfocused")
      ops.colorPicker(currTheme.window.textColorUnfocused)

      ops.label("Modified Flag")
      ops.colorPicker(currTheme.window.modifiedFlagColor)

      ops.label("Button")
      ops.colorPicker(currTheme.window.buttonColor)

      ops.label("Button Hover")
      ops.colorPicker(currTheme.window.buttonColorHover)

      ops.label("Button Down")
      ops.colorPicker(currTheme.window.buttonColorDown)

    if ops.subSectionHeader("Status Bar", sectionStatusBar):
      ops.label("Background")
      ops.colorPicker(currTheme.statusBar.backgroundColor)

      ops.label("Text")
      ops.colorPicker(currTheme.statusBar.textColor)

      ops.label("Command Background")
      ops.colorPicker(currTheme.statusBar.commandBgColor)

      ops.label("Command")
      ops.colorPicker(currTheme.statusBar.commandColor)

      ops.label("Coordinates")
      ops.colorPicker(currTheme.statusBar.coordsColor)

    if ops.subSectionHeader("Level Drop Down", sectionLeveldropDown):
      ops.nextRowHeight(21)
      ops.label("Button")
      ops.colorPicker(currTheme.levelDropDown.buttonColor)

      ops.label("Button Hover")
      ops.colorPicker(currTheme.levelDropDown.buttonColorHover)

      ops.nextRowHeight(21)
      ops.label("Text")
      ops.colorPicker(currTheme.levelDropDown.textColor)

      ops.label("Item List")
      ops.colorPicker(currTheme.levelDropDown.itemListColor)

      ops.nextRowHeight(21)
      ops.label("Item")
      ops.colorPicker(currTheme.levelDropDown.itemColor)

      ops.label("Item Hover")
      ops.colorPicker(currTheme.levelDropDown.itemColorHover)

    if ops.subSectionHeader("About Button", sectionAboutButton):
      ops.label("Color")
      ops.colorPicker(currTheme.aboutButton.color)

      ops.label("Hover")
      ops.colorPicker(currTheme.aboutButton.colorHover)

      ops.label("Active")
      ops.colorPicker(currTheme.aboutButton.colorActive)

  if ops.sectionHeader("Level", sectionLevel):
    if ops.subSectionHeader("General", sectionLevelGeneral):
      group:
        ops.label("Background")
        ops.colorPicker(currTheme.level.backgroundColor)

        ops.label("Draw")
        ops.colorPicker(currTheme.level.drawColor)

        ops.label("Draw Light")
        ops.colorPicker(currTheme.level.lightDrawColor)

        ops.label("Line Width")
        ops.dropDown(currTheme.level.lineWidth)

      group:
        ops.label("Coordinates")
        ops.colorPicker(currTheme.level.coordsColor)

        ops.label("Coordinates Highlight")
        ops.colorPicker(currTheme.level.coordsHighlightColor)

        ops.label("Cursor")
        ops.colorPicker(currTheme.level.cursorColor)

        ops.label("Cursor Guides")
        ops.colorPicker(currTheme.level.cursorGuideColor)

      group:
        ops.label("Grid Style Background")
        ops.dropDown(currTheme.level.gridStyleBackground)

        ops.label("Grid Background")
        ops.colorPicker(currTheme.level.gridColorBackground)

        ops.label("Grid Style Floor")
        ops.dropDown(currTheme.level.gridStyleFloor)

        ops.label("Grid Floor")
        ops.colorPicker(currTheme.level.gridColorFloor)

      group:
        ops.label("Selection")
        ops.colorPicker(currTheme.level.selectionColor)

        ops.label("Paste Preview")
        ops.colorPicker(currTheme.level.pastePreviewColor)

      group:
        ops.label("Link Marker")
        ops.colorPicker(currTheme.level.linkMarkerColor)

    if ops.subSectionHeader("Background Hatch", sectionBackgroundHatch):
      ops.label("Background Hatch?")
      ops.checkBox(currTheme.level.bgHatch)

      ops.label("Hatch")
      ops.colorPicker(currTheme.level.bgHatchColor)

      ops.label("Hatch Stroke Width")
      ops.horizSlider(
        startVal = 0,
        endVal = 10,
        currTheme.level.bgHatchStrokeWidth,
        style = propsSliderStyle,
      )

      ops.label("Hatch Spacing")
      ops.horizSlider(
        startVal = 0,
        endVal = 10,
        currTheme.level.bgHatchSpacingFactor,
        style = propsSliderStyle,
      )

    if ops.subSectionHeader("Outline", sectionOutline):
      ops.label("Outline Style")
      ops.dropDown(currTheme.level.outlineStyle)

      ops.label("Outline Fill Style")
      ops.dropDown(currTheme.level.outlineFillStyle)

      ops.label("Outline Overscan")
      ops.checkBox(currTheme.level.outlineOverscan)

      ops.label("Outline")
      ops.colorPicker(currTheme.level.outlineColor)

      ops.label("Outline Width")
      ops.horizSlider(
        startVal = 0,
        endVal = 10,
        currTheme.level.outlineWidthFactor,
        style = propsSliderStyle,
      )

    if ops.subSectionHeader("Shadow", sectionShadow):
      group:
        ops.label("Inner Shadow")
        ops.colorPicker(currTheme.level.innerShadowColor)

        ops.label("Inner Shadow Width")
        ops.horizSlider(
          startVal = 0,
          endVal = 10,
          currTheme.level.innerShadowWidthFactor,
          style = propsSliderStyle,
        )

      group:
        ops.label("Outer Shadow")
        ops.colorPicker(currTheme.level.outerShadowColor)

        ops.label("Outer Shadow Width")
        ops.horizSlider(
          startVal = 0,
          endVal = 10,
          currTheme.level.outerShadowWidthFactor,
          style = propsSliderStyle,
        )

    if ops.subSectionHeader("Floor Colors", sectionFloorColors):
      ops.label("Floor 1")
      ops.colorPicker(currTheme.level.floorColor[0])

      ops.label("Floor 2")
      ops.colorPicker(currTheme.level.floorColor[1])

      ops.label("Floor 3")
      ops.colorPicker(currTheme.level.floorColor[2])

      ops.label("Floor 4")
      ops.colorPicker(currTheme.level.floorColor[3])

      ops.label("Floor 5")
      ops.colorPicker(currTheme.level.floorColor[4])

      ops.label("Floor 6")
      ops.colorPicker(currTheme.level.floorColor[5])

      ops.label("Floor 7")
      ops.colorPicker(currTheme.level.floorColor[6])

      ops.label("Floor 8")
      ops.colorPicker(currTheme.level.floorColor[7])

      ops.label("Floor 9")
      ops.colorPicker(currTheme.level.floorColor[8])

    if ops.subSectionHeader("Notes", sectionNotes):
      group:
        ops.label("Marker")
        ops.colorPicker(currTheme.level.noteMarkerColor)

        ops.label("Comment")
        ops.colorPicker(currTheme.level.noteCommentColor)

      group:
        ops.label("Index")
        ops.colorPicker(currTheme.level.noteIndexColor)

        ops.label("Index Background 1")
        ops.colorPicker(currTheme.level.noteIndexBgColor[0])

        ops.label("Index Background 2")
        ops.colorPicker(currTheme.level.noteIndexBgColor[1])

        ops.label("Index Background 3")
        ops.colorPicker(currTheme.level.noteIndexBgColor[2])

        ops.label("Index Background 4")
        ops.colorPicker(currTheme.level.noteIndexBgColor[3])

      group:
        ops.label("Tooltip Background")
        ops.colorPicker(currTheme.level.noteTooltipBgColor)

        ops.label("Tooltip Text")
        ops.colorPicker(currTheme.level.noteTooltipTextColor)

  if ops.sectionHeader("Panes", sectionPanes):
    if ops.subSectionHeader("Notes Pane", sectionNotesPane):
      ops.label("Text")
      ops.colorPicker(currTheme.notesPane.textColor)

      ops.label("Index")
      ops.colorPicker(currTheme.notesPane.indexColor)

      ops.label("Index Background 1")
      ops.colorPicker(currTheme.notesPane.indexBgColor[0])

      ops.label("Index Background 2")
      ops.colorPicker(currTheme.notesPane.indexBgColor[1])

      ops.label("Index Background 3")
      ops.colorPicker(currTheme.notesPane.indexBgColor[2])

      ops.label("Index Background 4")
      ops.colorPicker(currTheme.notesPane.indexBgColor[3])

    if ops.subSectionHeader("Toolbar Pane", sectionToolbarPane):
      ops.label("Button Background")
      ops.colorPicker(currTheme.toolbarPane.buttonBgColor)

      ops.label("Button Background Hover")
      ops.colorPicker(currTheme.toolbarPane.buttonBgColorHover)

  ops.endScrollView()

  #[


#-----------------------------------------------------------------------------

[toolbarPane]
]#
  w = 300.0
  ops.beginScrollView(x = 600, y = 150, w = w, h = 300)

  ap = DefaultAutoLayoutParams
  ap.rowWidth = w
  ap.rightPad = 16

  initAutoLayout(ap)

  if ops.sectionHeader("First section", section1):
    ops.beginGroup()
    ops.label("CheckBox 1")
    ops.checkBox(checkBoxVal1, tooltip = "Checkbox 1")

    ops.label("CheckBox 2")
    ops.checkBox(checkBoxVal2, tooltip = "Checkbox 2")

    ops.label("CheckBox 3")
    ops.checkBox(checkBoxVal3, tooltip = "Checkbox 3")

    ops.label("CheckBox 4")
    ops.checkBox(checkBoxVal4, tooltip = "Checkbox 4")
    ops.endGroup()

    ops.beginGroup()
    ops.label("dropDown 1")
    ops.dropDown(
      items = @["Orange", "Banana", "Blueberry", "Apricot", "Apple"],
      dropDownVal1,
      tooltip = "Select a fruit",
    )

    ops.label("dropDown 2")
    ops.dropDown(
      items = @["One", "Two", "Three"], dropDownVal2, tooltip = "Select a number"
    )
    ops.endGroup()

  if ops.sectionHeader("Second section", section2):
    ops.label("dropDown 1")
    ops.dropDown(
      items = @["Orange", "Banana", "Blueberry", "Apricot", "Apple"],
      dropDownVal3,
      tooltip = "Select a fruit",
    )

    ops.beginGroup()
    ops.label("CheckBox 1")
    ops.checkBox(checkBoxVal5, tooltip = "Checkbox 1")

    ops.label("CheckBox 2")
    ops.checkBox(checkBoxVal6, tooltip = "Checkbox 2")
    ops.endGroup()

  ops.endScrollView()

  ############################################################################

  ops.endFrame()

proc renderFrame(win: glfw.Window, res: tuple[w, h: int32] = (0, 0)) =
  if win.iconified:
    return
  renderUI()
  glfw.swapBuffers(win)

proc windowPosCb(win: glfw.Window, pos: tuple[x, y: int32]) =
  renderFrame(win)

proc framebufSizeCb(win: glfw.Window, size: tuple[w, h: int32]) =
  renderFrame(win)

proc init(): glfw.Window =
  glfw.initialize()

  var win = createWindow()

  vg = createRenderContext({rifStencilStrokes, rifAntialias, rifDebug})

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  vg.setupGL(sampleCount = 4)
  loadData(vg)

  ops.init(vg, getProcAddress)

  #  ops.scale(1.5)
  win.windowPositionCb = windowPosCb
  win.framebufferSizeCb = framebufSizeCb

  win.pos = (400, 150)
  wrapper.showWindow(win.getHandle())

  result = win

proc cleanup() =
  ops.deinit()
  deleteRenderContext(vg)
  glfw.terminate()

proc main() =
  let win = init()

  currTheme.levelDropDown.buttonColor = red().withAlpha(0.5)

  while not win.shouldClose:
    if ops.shouldRenderNextFrame():
      glfw.pollEvents()
    else:
      glfw.waitEvents()
    if exampleQuitShortcutDown():
      win.shouldClose = true
      break
    renderFrame(win)

  cleanup()

main()

# vim: et:ts=2:sw=2:fdm=marker
