import
  strutils

import
  bgfxdotnim
  , bgfxdotnim/platform
  , sdl2 as sdl

import 
  window

# Printable format: "$1.$2.$3" % [MAJOR, MINOR, PATCHLEVEL]
const
  MAJOR_VERSION* = 2
  MINOR_VERSION* = 0
  PATCHLEVEL* = 5

template version*(x: untyped) = ##  \
  ##  Template to determine SDL version program was compiled against.
  ##
  ##  This template fills in a Version object with the version of the
  ##  library you compiled against. This is determined by what header the
  ##  compiler uses. Note that if you dynamically linked the library, you might
  ##  have a slightly newer or older version at runtime. That version can be
  ##  determined with getVersion(), which, unlike version(),
  ##  is not a template.
  ##
  ##  ``x`` Version object to initialize.
  ##
  ##  See also:
  ##
  ##  ``Version``
  ##
  ##  ``getVersion``
  (x).major = MAJOR_VERSION
  (x).minor = MINOR_VERSION
  (x).patch = PATCHLEVEL

type
  Graphics* = ref TGraphics
  TGraphics* = object
    rootWindow: Window


when defined(macosx):
  type
    SysWMInfoCocoaObj = object
      window: pointer ## The Cocoa window

    SysWMInfoKindObj = object
      cocoa: SysWMInfoCocoaObj

when defined(linux):
  import 
    x, 
    xlib

  type
    SysWMmsgX11Obj* = object  ## when defined(SDL_VIDEO_DRIVER_X11)
      display*: ptr xlib.TXDisplay  ##  The X11 display
      window*: ptr x.TWindow            ##  The X11 window


    SysWMInfoKindObj* = object ## when defined(SDL_VIDEO_DRIVER_X11)
      x11*: SysWMMsgX11Obj

when defined(windows):
  type
    SysWMMsgWinObj* = object  ##  when defined(SDL_VIDEO_DRIVER_WINDOWS)
      window*: pointer

    SysWMInfoKindObj* = object ##  when defined(SDL_VIDEO_DRIVER_WINDOWS)
      win*: SysWMMsgWinObj  


template workaround_create[T]: ptr T = cast[ptr T](alloc0(sizeof(T)))

proc getTime(): float64 =
    return float64(sdl.getPerformanceCounter()*1000) / float64 sdl.getPerformanceFrequency()

proc initPlatformData(init: ptr bgfx_init_t, window: sdl.WindowPtr) =
  # init.platformData = bgfx_platform_data_t()
  var info: sdl.WMinfo
  version(info.version)
  assert sdl.getWMInfo(window, info)
  echo  "SDL2 version: $1.$2.$3 - Subsystem: $4".format(info.version.major.int, info.version.minor.int, info.version.patch.int,
  info.subsystem)

  case(info.subsystem):
      of SysWM_Windows:
        when defined(windows):
          let info = cast[ptr SysWMInfoKindObj](addr info.padding[0])
          init.platformData.nwh = cast[pointer](info.win.window)
        init.platformData.ndt = nil
      of SysWM_X11:
        when defined(linux):
          let info = cast[ptr SysWMInfoKindObj](addr info.padding[0])
          init.platformData.nwh = info.x11.window
          init.platformData.ndt = info.x11.display
      of SysWM_Cocoa:
        when defined(macosx):
          let info = cast[ptr SysWMInfoKindObj](addr info.padding[0])
          # init.`type` = BGFX_RENDERER_TYPE_METAL
          # use opengl
          # init.`type` = BGFX_RENDERER_TYPE_OPENGL
          # init.`type` = BGFX_RENDERER_TYPE_OPENGLES
          init.platformData.nwh = info.cocoa.window
        init.platformData.ndt = nil
      else:
        echo "SDL2 failed to get handle: $1".format(sdl.getError())
        raise newException(OSError, "No structure for subsystem type")

  init.platformData.backBuffer = nil
  init.platformData.backBufferDS = nil
  init.platformData.context = nil

proc newGraphics*(): Graphics =
  result = Graphics()

proc init*(graphics: Graphics, title: string, width, height: int, flags: uint32) =
  if not sdl.init(INIT_TIMER or INIT_VIDEO or INIT_JOYSTICK or INIT_HAPTIC or INIT_GAMECONTROLLER or INIT_EVENTS):
    echo "Error initializing SDL2."
    quit(QUIT_FAILURE)
  
  graphics.rootWindow = newWindow()

  graphics.rootWindow.init(title, width, height, flags)

  if graphics.rootWindow.isNil:
    echo "Error creating SDL2 window."
    quit(QUIT_FAILURE)

  # # Call bgfx::renderFrame before bgfx::init to signal to bgfx not to create a render thread.
  # # Most graphics APIs must be used on the same thread that created the window.
  # discard bgfx_render_frame(-1)

  var init: bgfx_init_t

  bgfx_init_ctor(addr init)

  initPlatformData(addr init, graphics.rootWindow.handle)

  # echo "Initializing BGFX........."
  if not bgfx_init(addr init):
    echo "Error initializng BGFX."
    quit(QUIT_FAILURE)

  # check renderer type
  var renderer = bgfx_get_renderer_name(bgfx_get_renderer_type())
  echo "Renderer: $1".format(renderer)

  bgfx_set_debug(BGFX_DEBUG_TEXT)

  bgfx_reset(uint32 width, uint32 height, BGFX_RESET_NONE, BGFX_TEXTURE_FORMAT_COUNT)

  bgfx_set_view_rect(0, 0, 0, uint16 width, uint16 height)

proc dispose*(graphics: Graphics) =
  sdl.destroyWindow(graphics.rootWindow.handle)
  sdl.quit()
  bgfx_shutdown()