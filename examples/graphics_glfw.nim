import
  strutils

import
  bgfxdotnim
  , bgfxdotnim/platform
  , staticglfw as glfw # using https://github.com/funatsufumiya/staticglfw

type
  Graphics* = ref TGraphics
  TGraphics* = object
    window*: glfw.Window

let COCOA_RETINA_FRAMEBUFFER: cint = 0x00023001
let GLFW_FALSE: cint = 0

proc initPlatformData(init: ptr bgfx_init_t, window: glfw.Window) =
  when defined(windows):
    init.platformData.nwh = cast[pointer](getWin32Window(window))
    init.platformData.ndt = nil
  when defined(linux):
    if getPlatform() == PLATFORM_WAYLAND:
      init.platformData.nwh = cast[pointer](getWaylandWindow(window))
      init.platformData.ndt = cast[pointer](getWaylandDisplay())
    #   init.`type` = BGFX_NATIVE_WINDOW_HANDLE_TYPE_WAYLAND
    else:
      init.platformData.nwh = cast[pointer](getX11Window(window))
      init.platformData.ndt = cast[pointer](getX11Display())
  when defined(macosx):
    init.platformData.nwh = cast[pointer](getCocoaWindow(window))
    init.platformData.ndt = nil
    # init.`type` = BGFX_RENDERER_TYPE_METAL

  init.platformData.backBuffer = nil
  init.platformData.backBufferDS = nil
  init.platformData.context = nil

proc newGraphics*(): Graphics =
  result = Graphics()

proc printSupportedRenderers() =
  echo "Supported renderers:"
  let max = cast[uint8](BGFX_RENDERER_TYPE_COUNT)
  var backends = newSeq[ptr bgfx_renderer_type_t](max)
  var numBackends = cast[int](bgfx_get_supported_renderers(max, cast[ptr bgfx_renderer_type_t](addr backends[0])))
  for i in 0..<(numBackends-1):
    var backend = backends[i]
    var backend_name = bgfx_get_renderer_name(cast[bgfx_renderer_type_t](backend))
    echo "- $2".format(i, backend_name)

proc init*(graphics: Graphics, title: string, width, height: int) =

  if glfw.init() == 0:
    raise newException(Exception, "Failed to initialize GLFW")

  
  # Set client API to no API since BGFX will handle it
  glfw.defaultWindowHints()
  glfw.windowHint(glfw.CLIENT_API, glfw.NO_API)
  when defined(macosx):
    glfw.windowHint(COCOA_RETINA_FRAMEBUFFER, GLFW_FALSE)

  graphics.window = createWindow(cast[cint](width), cast[cint](height), title, nil, nil)
  if graphics.window.isNil:
    raise newException(Exception, "Failed to create GLFW window")

  # Call bgfx::renderFrame before bgfx::init
  discard bgfx_render_frame(-1)

  printSupportedRenderers()

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
  destroyWindow(graphics.window)
  glfw.terminate()
  bgfx_shutdown()