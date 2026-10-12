local Nya = require("Browser/Nya")
local SDL = require("SDL")
local SDLTtf = require("SDL.ttf")

local Logger = {}

function Logger:Log(Level, ...)
  io.stderr:write(string.format("[%s] %s\n", Level, string.format(...)))
end

function Logger:Info(...)
  self:Log("Info", ...)
end

function Logger:Warning(...)
  self:Log("Warning", ...)
end

function Logger:Error(...)
  self:Log("Error", ...)
end

function Logger:Assert(Value, ...)
  if not Value then
    local Message = string.format(...)
    self:Error("%s", Message)
    error(Message, 2)
  end

  return Value
end

function Logger:AssertType(Value, ExpectedType, ...)
  if type(Value) ~= ExpectedType then
    local Message

    if select("#", ...) > 0 then
      Message = string.format(...)
    else
      Message = string.format("Expected %s, got %s", ExpectedType, type(Value))
    end

    self:Error("%s", Message)
    error(Message, 2)
  end

  return Value
end

local Purr = {
  SDLWindow = nil,
  SDLRenderer = nil,
  Running = false,
  Fps = math.floor(1000 / 60),
  Tab = {},
  TabFileName = "",
  TabRuntime = {},
  Renderer = {},
  Logger = Logger,
}

local TabRuntime = {}
Purr.TabRuntime = TabRuntime
TabRuntime.Purr = {}

local TextLabelModule = {}

function TextLabelModule.new()
  local Options = TabRuntime.__Options or {}

  return {
    ClassName = "TextLabel",
    Text = Options.Body,
    TextColor = Options.TextColor or Nya.Color4.new(0, 0, 0, 1),
    FontSize = Options.FontSize or 16,
    FontName = Options.FontName or "NotoSansRegular",
    X = Options.X or 0,
    Y = Options.Y or 0,
  }
end

function TabRuntime.Purr.TextLabel(Body, Options)
  Options = Options or {}
  Options.Body = Body
  TabRuntime.__Options = Options

  return Nya.Instance.new("TextLabel")
end

function TabRuntime:Initialize()
  self.Nya = Nya
  Nya.Instance:RegisterClass("TextLabel", TextLabelModule, Nya.Instance)
end

function Purr:Initialize()
  self:InitializeCli()
  self:InitializeRenderer()
  self:InitializeTab()
end

function Purr:InitializeCli()
  for Index, Value in pairs(arg) do
    if Index > 0 then
      self.TabFileName = Value
      break
    end
  end

  Logger:Assert(self.TabFileName ~= "", "Missing TabFileName. Usage: luajit Browser/Purr.lua <file>")
end

function Purr:InitializeTab()
  TabRuntime:Initialize()

  local TabFilePtr = Logger:Assert(io.open(self.TabFileName, "r"), "Couldn't open %s", self.TabFileName)

  local TabSource = TabFilePtr:read("*a")
  TabFilePtr:close()

  local TabFunction, LuaError = loadstring(TabSource)

  Logger:Assert(TabFunction, "Lua error in %s: %s", self.TabFileName, tostring(LuaError))

  setfenv(TabFunction, self.TabRuntime)

  self.Tab = Logger:Assert(TabFunction(), "%s returned nil", self.TabFileName)

  Logger:Info("Loaded tab %s", self.TabFileName)
end

local Renderer = {
  Fonts = {},
}

Purr.Renderer = Renderer

function Purr:InitializeRenderer()
  Renderer:Initialize()
end

function Renderer:Initialize()
  SDL.init(SDL.flags.Everything)

  local Window, WindowError = SDL.createWindow({
    title = "Purr",
    width = 800,
    height = 600,
    flags = { SDL.window.Resizable },
  })

  Logger:Assert(Window and type(Window) ~= "string", "Failed to create SDL window: %s", tostring(WindowError or Window))

  Purr.SDLWindow = Window

  local SDLRenderer, RendererError = SDL.createRenderer(Purr.SDLWindow, 0, 0)

  Logger:Assert(
    SDLRenderer and type(SDLRenderer) ~= "string",
    "Failed to create SDL renderer: %s",
    tostring(RendererError or SDLRenderer)
  )

  Purr.SDLRenderer = SDLRenderer

  SDLTtf.init(SDL.flags.Everything)

  Purr.Running = true

  Logger:Info("Renderer initialized")
end

function Renderer:LoadFont(FontName, FontSize)
  self.Fonts[FontName] = self.Fonts[FontName] or {}

  local FontPath = "/usr/share/fonts/noto/" .. FontName:gsub("NotoSans", "NotoSans-") .. ".ttf"

  local Font, FontError = SDLTtf.open(FontPath, FontSize)

  Logger:Assert(Font and type(Font) ~= "string", "Failed to load font %s: %s", FontPath, tostring(FontError or Font))

  self.Fonts[FontName][FontSize] = Font

  return Font
end

function Renderer:GetFont(FontName, FontSize)
  self.Fonts[FontName] = self.Fonts[FontName] or {}

  return self.Fonts[FontName][FontSize] or self:LoadFont(FontName, FontSize)
end

function Renderer:GetColorFromColor4(Color)
  local R = math.floor(Color.R * 255)
  local G = math.floor(Color.G * 255)
  local B = math.floor(Color.B * 255)
  local A = math.floor(Color.A * 255)

  return A * 16777216 + R * 65536 + G * 256 + B
end

function Renderer:Text(Text, FontName, TextColor, FontSize, X, Y)
  Logger:AssertType(Text, "string", "TextLabel.Text must be a string, got %s", type(Text))

  local Font = self:GetFont(FontName, FontSize)

  local Surface, SurfaceError = Font:renderUtf8(Text, "blended", self:GetColorFromColor4(TextColor))

  Logger:Assert(Surface and type(Surface) ~= "string", "Failed to render text: %s", tostring(SurfaceError or Surface))

  local Texture, TextureError = Purr.SDLRenderer:createTextureFromSurface(Surface)

  Logger:Assert(
    Texture and type(Texture) ~= "string",
    "Failed to create text texture: %s",
    tostring(TextureError or Texture)
  )

  local Format, Access, Width, Height = Texture:query()

  Purr.SDLRenderer:copy(Texture, nil, {
    x = X or 0,
    y = Y or 0,
    w = Width,
    h = Height,
  })
end

function Renderer:RenderInstance(Instance)
  Logger:AssertType(Instance, "table", "Expected an instance table, got %s", type(Instance))

  if Instance.ClassName == "TextLabel" then
    self:Text(Instance.Text, Instance.FontName, Instance.TextColor, Instance.FontSize, Instance.X, Instance.Y)
  else
    Logger:Warning("Unsupported instance class: %s", tostring(Instance.ClassName))
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

  self:RenderInstance(Purr.Tab)

  Purr.SDLRenderer:present()

  SDL.delay(Purr.Fps)
end

function Purr.Main()
  Purr:Initialize()

  while Purr.Running do
    Renderer:Frame()
  end
end

Purr.Main()

return Purr
