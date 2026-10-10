local SDL = require("SDL")
local SDLTtf = require("SDL.ttf")

local Purr = {
  SDLWindow = nil,
  SDLRenderer = nil,
  Running = false,
  Fps = 1,
  Tab = {},
  TabFileName = "",
  Stop = false,

  TabRuntime = {},
  Renderer = {},
}

local TabRuntime = {}
local Renderer = {}

function TabRuntime.Text(Body, Options)
  Options = Options or {}

  return {
    ClassName = "Text",
    Text = Body,
    FontSize = Options.FontSize or 24,
    FontColor = Options.FontColor or 0xffffff,
    FontName = "NotoSansRegular",
  }
end

function Purr:Initialize()
  Purr:InitializeRenderer()
  if Purr.Stop then
    return
  end

  Purr:InitializeCli()
  if Purr.Stop then
    return
  end

  Purr:InitializeTab()
  if Purr.Stop then
    return
  end
end

function Purr:InitializeCli()
  for Index, Value in pairs(arg) do
    if Index > 0 then
      Purr.TabFileName = Value
    end
  end

  if Purr.TabFileName == nil then
    print("Purr: Need TabFileName")
    Purr.Stop = true
    return
  end
end

function Purr:InitializeRenderer()
  Renderer:Initialize()
end

function Purr:InitializeTab()
  local TabFilePtr = io.open(Purr.TabFileName, "r")

  if TabFilePtr == nil then
    print(string.format("Purr: Couldn't open %s", Purr.TabFileName))
    Purr.Stop = true
    return
  end

  local TabSource = TabFilePtr:read("*a")
  TabFilePtr:close()

  local TabFunction, LuaError = loadstring(TabSource)

  if LuaError or TabFunction == nil then
    print(string.format("Tab: Lua Error: %s", LuaError))
    Purr.Stop = true
    return
  end

  setfenv(TabFunction, Purr.TabRuntime)

  local Tab = TabFunction()

  Purr.Tab = Tab
end

function Renderer:Initialize()
  SDL.init(SDL.flags.Everything)

  Purr.SDLWindow = SDL.createWindow({
    title = "Purr",
    width = 800,
    height = 600,
    flags = { SDL.window.Resizable },
  })

  Purr.Running = true
  Purr.Fps = math.floor((1 / 60) * 1000)

  Purr.SDLRenderer = SDL.createRenderer(Purr.SDLWindow, 0, 0)

  SDLTtf.init(SDL.flags.Everything)

  Renderer.Fonts = {}
end

function Renderer:LoadFont(FontName, FontSize)
  Renderer.Fonts[FontName] = Renderer.Fonts[FontName] or {}

  local FontPath = "/usr/share/fonts/noto/" .. FontName:gsub("NotoSans", "NotoSans-") .. ".ttf"
  local Font, Error = SDLTtf.open(FontPath, FontSize)

  Renderer.Fonts[FontName][FontSize] = Font
  return Font
end

function Renderer:GetFont(FontName, FontSize)
  local BaseFonts = Renderer.Fonts[FontName]

  if BaseFonts then
    local Font = BaseFonts[FontSize]
    if Font then
      return Font
    else
      return Renderer:LoadFont(FontName, FontSize)
    end
  else
    return Renderer:LoadFont(FontName, FontSize)
  end
end

function Renderer:RenderInstance(Instance)
  if Instance.ClassName == "Text" then
    local Font = Renderer:GetFont(Instance.FontName, Instance.FontSize)

    Font:renderUtf8(Instance.Text, "solid", Instance.FontColor)
  end
end

function Purr:Frame()
  for Event in SDL.pollEvent() do
    if Event.type == SDL.event.Quit then
      Purr.Running = false
    end
  end

  Purr.SDLRenderer:setDrawColor(0xFFFFFF)
  Purr.SDLRenderer:clear()

  Renderer:RenderInstance(Purr.Tab)

  SDL.delay(Purr.Fps)
end

function Purr.Main()
  Purr:Initialize()
  if Purr.Stop then
    return
  end

  while Purr.Running do
    Purr:Frame()
  end
end

Purr.TabRuntime = TabRuntime
Purr.Renderer = Renderer

Purr.Main()
