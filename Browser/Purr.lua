local Nya = require("Nya")
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

local Instance = {}

function TabRuntime.Text(Body, Options)
  Options = Options or {}

  return {
    ClassName = "Text",
    Text = Body,
    TextColor = Options.TextColor or Nya.Color4.new(0, 0, 0, 1),
    FontSize = Options.FontSize or 16,
    FontName = "NotoSansRegular",
  }
end

function TabRuntime:Initialize()
  TabRuntime.Nya = Nya
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
  TabRuntime:Initialize()

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
  Renderer.Fonts[FontName] = Renderer.Fonts[FontName] or {}

  local Font = Renderer.Fonts[FontName][FontSize]

  if Font then
    return Font
  end

  return Renderer:LoadFont(FontName, FontSize)
end

function Renderer:GetColorFromColor4(Color)
  local R = math.floor(Color.R * 255)
  local G = math.floor(Color.G * 255)
  local B = math.floor(Color.B * 255)
  local A = math.floor(Color.A * 255)

  return A * 16777216 + R * 65536 + G * 256 + B
end

function Renderer:Text(Text, FontName, TextColor, FontSize, X, Y)
  local Font = Renderer:GetFont(FontName, FontSize)

  local Surface = Font:renderUtf8(Text, "blended", Renderer:GetColorFromColor4(TextColor))
  local Texture = Purr.SDLRenderer:createTextureFromSurface(Surface)

  local Format, Access, Width, Height = Texture:query()

  Purr.SDLRenderer:copy(Texture, nil, {
    x = 0,
    y = 0,
    w = Width,
    h = Height,
  })
end

function Renderer:RenderInstance(Instance)
  if Instance.ClassName == "Text" then
    Renderer:Text(Instance.Text, Instance.FontName, Instance.TextColor, Instance.FontSize, Instance.X, Instance.Y)
  end
end

function Renderer:Frame()
  for Event in SDL.pollEvent() do
    if Event.type == SDL.event.Quit then
      Purr.Running = false
    end
  end

  Purr.SDLRenderer:setDrawColor(0xFFFFFF)
  Purr.SDLRenderer:clear()

  Renderer:RenderInstance(Purr.Tab)

  Purr.SDLRenderer:present()

  SDL.delay(Purr.Fps)
end

function Purr.Main()
  Purr:Initialize()
  if Purr.Stop then
    return
  end

  while Purr.Running do
    Renderer:Frame()
  end
end

Purr.TabRuntime = TabRuntime
Purr.Renderer = Renderer

Purr.Main()
