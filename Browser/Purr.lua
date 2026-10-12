local Nya = require("Browser/Nya")
local SDL = require("SDL")
local SDLTtf = require("SDL.ttf")

local Logger = {}

function Logger:Log(Level, ...)
  io.stderr:write(string.format("Purr: %s: %s\n", Level, string.format(...)))
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

function Logger:PrintTable(Table, Indent, Seen)
  Indent = Indent or 0
  Seen = Seen or {}

  if type(Table) ~= "table" then
    print(string.rep("  ", Indent) .. tostring(Table))
    return
  end

  if Seen[Table] then
    print(string.rep("  ", Indent) .. "<cycle>")
    return
  end

  Seen[Table] = true

  print(string.rep("  ", Indent) .. "{")

  for Key, Value in pairs(Table) do
    local Prefix = string.rep("  ", Indent + 1) .. "[" .. tostring(Key) .. "] = "

    if type(Value) == "table" then
      io.write(Prefix)
      self:PrintTable(Value, Indent + 1, Seen)
    else
      print(Prefix .. tostring(Value) .. ",")
    end
  end

  print(string.rep("  ", Indent) .. "}")
  Seen[Table] = nil
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
  Window = {},
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
TabRuntime.Purr.Logger = {}

local InstanceModule = {}
function InstanceModule.new()
  return {
    Tags = {},
  }
end

local TextModule = {}
function TextModule.new()
  local Options = TabRuntime.__Options or {}

  return {
    Text = Options.Body,
    Style = TabRuntime.Purr.__NewStyle__(Options.Style),
  }
end

local FrameModule = {}
function FrameModule.new()
  local Options = TabRuntime.__Options or {}

  return {
    Style = TabRuntime.Purr.__NewStyle__(Options.Style),
  }
end

function TabRuntime.Purr.new(ClassName, Body, Options)
  Options = Options or {}
  Options.Body = Body
  TabRuntime.__Options = Options

  local Instance = Nya.Instance.new(ClassName)

  if ClassName == "Frame" then
    for _, Child in pairs(Body) do
      Child.Parent = Instance
    end
  end

  return Instance
end

function TabRuntime.Purr.__NewStyle__(Options)
  Options = Options or {}

  return {
    Position = Options.Position or Nya.UDim2.new(0, 0, 0, 0),
    Size = Options.Size or Nya.UDim2.new(0, 0, 0, 0),
    AnchorPoint = Options.AnchorPoint or Nya.Vector2.new(0, 0),
    BackgroundColor = Options.BackgroundColor or Nya.Color4.new(1, 1, 1, 0),
    TextColor = Options.TextColor or Nya.Color4.new(0, 0, 0, 1),
    FontSize = Options.FontSize or 16,
    FontName = Options.FontName or "NotoSansRegular",
  }
end

function TabRuntime.Purr.Logger:Log(Level, ...)
  io.stdout:write(string.format("Purr: %s: %s: %s\n", TabRuntime.FileName, Level, string.format(...)))
end

function TabRuntime.Purr.Logger:Info(...)
  self:Log("Info", ...)
end

function TabRuntime.Purr.Logger:Warning(...)
  self:Log("Warning", ...)
end

function TabRuntime.Purr.Logger:Error(...)
  self:Log("Error", ...)
end

function TabRuntime.Purr.Logger:PrintTable(Table, Indent, Seen)
  Indent = Indent or 0
  Seen = Seen or {}

  if type(Table) ~= "table" then
    print(string.rep("  ", Indent) .. tostring(Table))
    return
  end

  if Seen[Table] then
    print(string.rep("  ", Indent) .. "<cycle>")
    return
  end

  Seen[Table] = true

  print(string.rep("  ", Indent) .. "{")

  for Key, Value in pairs(Table) do
    local Prefix = string.rep("  ", Indent + 1) .. "[" .. tostring(Key) .. "] = "

    if type(Value) == "table" then
      io.write(Prefix)
      self:PrintTable(Value, Indent + 1, Seen)
    else
      print(Prefix .. tostring(Value) .. ",")
    end
  end

  print(string.rep("  ", Indent) .. "}")
  Seen[Table] = nil
end

function TabRuntime.Purr.Logger:Assert(Value, ...)
  if not Value then
    local Message = string.format(...)
    self:Error("%s", Message)
    Purr.Tab.Exit = true
  end

  return Value
end

function TabRuntime.Purr.Logger:AssertType(Value, ExpectedType, ...)
  if type(Value) ~= ExpectedType then
    local Message

    if select("#", ...) > 0 then
      Message = string.format(...)
    else
      Message = string.format("Expected %s, got %s", ExpectedType, type(Value))
    end

    self:Error("%s", Message)
  end

  return Value
end

function TabRuntime:Initialize()
  self.Nya = Nya
  Nya.Instance:RegisterClass("Text", TextModule, InstanceModule)
  Nya.Instance:RegisterClass("Frame", FrameModule, InstanceModule)
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

  TabRuntime.FileName = Purr.TabFileName
  setfenv(TabFunction, self.TabRuntime)

  self.Tab = Logger:Assert(TabFunction(), "%s returned nil", self.TabFileName)
  Logger:Info("Loaded tab %s", self.TabFileName)
end

local LayoutEngine = {}

function LayoutEngine:Calculate(Style, ParentSize)
  local Position = Style.Position or Nya.UDim2.new(0, 0, 0, 0)
  local Size = Style.Size or Nya.UDim2.new(0, 0, 0, 0)
  local AnchorPoint = Style.AnchorPoint or Nya.Vector2.new(0, 0)

  return {
    Position = Nya.Vector2.new(
      ParentSize.X * Position.X.Scale + Position.X.Offset,
      ParentSize.Y * Position.Y.Scale + Position.Y.Offset
    ),
    Size = Nya.Vector2.new(ParentSize.X * Size.X.Scale + Size.X.Offset, ParentSize.Y * Size.Y.Scale + Size.Y.Offset),
    AnchorPoint = AnchorPoint,
  }
end

local Renderer = {}
Renderer.Fonts = {}

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

function Renderer:Text(Text, FontName, TextColor, FontSize, X, Y, AnchorX, AnchorY)
  Logger:AssertType(Text, "string", "Text.Text must be a string, got %s", type(Text))

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

  X = X - (Width * (AnchorX or 0))
  Y = Y - (Height * (AnchorY or 0))

  Purr.SDLRenderer:copy(Texture, nil, {
    x = X or 0,
    y = Y or 0,
    w = Width,
    h = Height,
  })
end

function Renderer:RenderText(Instance)
  local Style = Instance.Style
  local Layout = LayoutEngine:Calculate(Style, Purr.Window.Size)

  self:Text(
    Instance.Text,
    Style.FontName or "NotoSansRegular",
    Style.TextColor or Color3.new(1, 1, 1, 0),
    Style.FontSize or 16,
    Layout.Position.X,
    Layout.Position.Y,
    Layout.AnchorPoint.X,
    Layout.AnchorPoint.Y
  )
end

function Renderer:RenderFrame(Instance)
  local Layout = LayoutEngine:Calculate(Instance.Style, Purr.Window.Size)
  local Position = Layout.Position
  local Size = Layout.Size
  local Color = self:GetColorFromColor4(Instance.BackgroundColor)

  Purr.SDLRenderer:setDrawColor(Color)
  Purr.SDLRenderer:fillRect({
    x = Position.X,
    y = Position.Y,
    w = Size.X,
    h = Size.Y,
  })
end

function Renderer:RenderInstance(Instance)
  Logger:AssertType(Instance, "table", "Expected an instance table, got %s", type(Instance))

  if Instance.ClassName == "Text" then
    Renderer:RenderText(Instance)
  elseif Instance.ClassName == "Frame" then
    Renderer:RenderFrame(Instance)
  else
    Logger:Warning("Unsupported instance class: %s", tostring(Instance.ClassName))
  end
end

function Renderer:Frame()
  if Purr.Tab.Exit then
    Purr.Running = false
  end

  for Event in SDL.pollEvent() do
    if Event.type == SDL.event.Quit then
      Purr.Running = false
    end
  end

  Purr.SDLWindow:setSize(800, 600)
  local WindowSizeX, WindowSizeY = Purr.SDLWindow:getSize()
  Purr.Window.Size = Nya.Vector2.new(WindowSizeX, WindowSizeY)

  Purr.SDLRenderer:setDrawColor(0xffffff)
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
