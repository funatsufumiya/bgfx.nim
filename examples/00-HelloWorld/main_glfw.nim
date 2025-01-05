import
  strutils

import
  bgfxdotnim
  , bgfxdotnim.platform
  , staticglfw as glfw # using https://github.com/funatsufumiya/staticglfw

import
  ../graphics_glfw,
  logo

const WIDTH = 960
const HEIGHT = 540

var g = newGraphics()
g.init("bgfx.nim Example00-HelloWorld GLFW", WIDTH, HEIGHT)

while not (windowShouldClose(g.window) == 1):
  glfw.pollEvents()

  bgfx_touch(0)
  bgfx_dbg_text_clear(0, false)

  # Display logo and debug text
  bgfx_dbg_text_image(
    max(uint16(WIDTH div 2 div 8), 20'u16) - 20'u16,
    max(uint16(HEIGHT div 2 div 16), 6'u16) - 6'u16,
    40, 12,
    addr logo[0],
    160
  )

  bgfx_set_view_clear(0, BGFX_CLEAR_COLOR or BGFX_CLEAR_DEPTH, 0x303030ff, 1.0, 0)

  discard bgfx_frame(false)

g.dispose()