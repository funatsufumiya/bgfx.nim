import
  strutils

import
  bgfxdotnim
  , bgfxdotnim/platform
  , rgfw # using https://github.com/funatsufumiya/rgfw.nim

import
  ../graphics_rgfw,
  logo

const WIDTH = 1024
const HEIGHT = 768

var showStats = false

proc keyCallback(win: ptr RGFW_window, key: uint32, keyChar: uint32, keyName: array[16, char], 
                lockState: uint8, pressed: uint8) {.cdecl.} =
  if key == cast[uint32](RGFW_Escape) and pressed == 1:
    RGFW_window_setShouldClose(win)
  elif key == RGFW_F1 and pressed == 1:
    showStats = not showStats

var g = newGraphics()
g.init("bgfx.nim RGFW Example", WIDTH, HEIGHT)

RGFW_setKeyCallback(keyCallback)

while not RGFW_window_shouldClose(g.window):
  while RGFW_window_checkEvent(g.window): discard

  bgfx_touch(0)
  bgfx_dbg_text_clear(0, false)

  bgfx_dbg_text_image(
    max(uint16(WIDTH div 2 div 8), 20'u16) - 20'u16,
    max(uint16(HEIGHT div 2 div 16), 6'u16) - 6'u16,
    40, 12,
    addr logo[0],
    160
  )

  bgfx_dbg_text_printf(0, 0, 0x0f, "Press F1 to toggle stats.")
  bgfx_set_debug(if showStats: BGFX_DEBUG_STATS else: BGFX_DEBUG_TEXT)
  bgfx_set_view_clear(0, BGFX_CLEAR_COLOR, 0x303030ff, 1.0, 0)

  discard bgfx_frame(false)

g.dispose()