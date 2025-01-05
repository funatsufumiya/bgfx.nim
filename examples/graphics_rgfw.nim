import
  strutils

import
  bgfxdotnim
  , bgfxdotnim/platform
  , rgfw # using https://github.com/funatsufumiya/rgfw.nim

type
  Graphics* = ref TGraphics
  TGraphics* = object
    window*: ptr RGFW_window

proc initPlatformData(init: ptr bgfx_init_t, window: ptr RGFW_window) =
  when defined(windows):
    init.platformData.nwh = window.src.window
    init.platformData.ndt = nil
  when defined(linux):
    init.platformData.nwh = cast[pointer](window.src.window)
    init.platformData.ndt = window.src.display
  when defined(macosx):
    init.platformData.nwh = window.src.window
    init.platformData.ndt = nil

  init.platformData.backBuffer = nil
  init.platformData.backBufferDS = nil
  init.platformData.context = nil

proc newGraphics*(): Graphics =
  result = Graphics()

proc init*(graphics: Graphics, title: string, width, height: int) =
  graphics.window = RGFW_createWindow(title, RGFW_RECT(x:0, y:0, w:cast[cint](width), h:cast[cint](height)), RGFW_CENTER)
  if graphics.window == nil:
    raise newException(Exception, "Failed to create RGFW window")

  discard bgfx_render_frame(-1)

  var init: bgfx_init_t
  bgfx_init_ctor(addr init)
  initPlatformData(addr init, graphics.window)

  if not bgfx_init(addr init):
    raise newException(Exception, "Failed to initialize BGFX")

  var renderer = bgfx_get_renderer_name(bgfx_get_renderer_type())
  echo "Renderer: $1".format(renderer)

  bgfx_set_debug(BGFX_DEBUG_TEXT)
  bgfx_reset(uint32 width, uint32 height, BGFX_RESET_VSYNC, init.resolution.format)
  bgfx_set_view_rect(0, 0, 0, uint16 width, uint16 height)

proc dispose*(graphics: Graphics) =
  RGFW_window_close(graphics.window)
  bgfx_shutdown()