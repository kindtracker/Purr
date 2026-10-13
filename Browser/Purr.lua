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
    local Message = select("#", ...) > 0 and string.format(...) or "Assertion failed"
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
  Window = {
    Size = Nya.Vector2.new(800, 600),
  },
  Running = false,
  Tab = {},
  TabFileName = "",
  TabRuntime = {},
  Renderer = {},
  Logger = Logger,
}

local TabRuntime = {}
Purr.TabRuntime = TabRuntime

TabRuntime.Purr = {
  Logger = {},
}

local function NewStyle(Options)
  Options = Options or {}

  return {
    Position = Options.Position or Nya.UDim2.new(0, 0, 0, 0),
    Size = Options.Size or Nya.UDim2.new(0, 0, 0, 0),
    AnchorPoint = Options.AnchorPoint or Nya.Vector2.new(0, 0),
    BackgroundColor = Options.BackgroundColor or Nya.Color4.new(1, 1, 1, 0),
    TextColor = Options.TextColor or Nya.Color4.new(0, 0, 0, 1),
    FontSize = Options.FontSize or 16,
    FontName = Options.FontName or "NotoSansRegular",
    BorderThickness = Options.BorderThickness or 4,
    BorderColor = Options.BorderColor or Nya.Color4.fromRGB(0, 0, 0),
  }
end

function TabRuntime.Purr.__NewStyle__(Options)
  return NewStyle(Options)
end

local InstanceModule = {}

function InstanceModule.new()
  return {
    Tags = {},
  }
end

local function NewStyledInstance()
  local Options = TabRuntime.__Options or {}

  return {
    Style = NewStyle(Options.Style),
  }
end

local TextModule = {}

function TextModule.new()
  local Instance = NewStyledInstance()
  local Options = TabRuntime.__Options or {}

  Instance.Text = Options.Body or ""

  return Instance
end

local FrameModule = {}

function FrameModule.new()
  return NewStyledInstance()
end

local TextButtonModule = {}

function TextButtonModule.new()
  local Instance = NewStyledInstance()
  local Options = TabRuntime.__Options or {}

  Instance.Text = Options.Body or ""

  return Instance
end

function TabRuntime.Purr.new(ClassName, Body, Options)
  Options = Options or {}
  Options.Body = Body
  TabRuntime.__Options = Options

  local Instance = Nya.Instance.new(ClassName)

  if type(Body) == "string" then
    Instance.Text = Body
  elseif ClassName == "Frame" and type(Body) == "table" then
    for _, Child in pairs(Body) do
      Child.Parent = Instance
    end
  end

  TabRuntime.__Options = nil

  return Instance
end

function TabRuntime.Purr.Logger:Log(Level, ...)
  io.stdout:write(
    string.format("Purr: %s: %s: %s\n", tostring(TabRuntime.FileName or "<unknown>"), Level, string.format(...))
  )
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
  Logger.PrintTable(self, Table, Indent, Seen)
end

function TabRuntime.Purr.Logger:Assert(Value, ...)
  if not Value then
    local Message = select("#", ...) > 0 and string.format(...) or "Assertion failed"
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
    Purr.Tab.Exit = true
  end

  return Value
end

function TabRuntime:Initialize()
  self.Nya = Nya

  Nya.Instance:RegisterClass("Text", TextModule, InstanceModule)
  Nya.Instance:RegisterClass("TextButton", TextButtonModule, InstanceModule)
  Nya.Instance:RegisterClass("Button", TextButtonModule, InstanceModule)
  Nya.Instance:RegisterClass("Frame", FrameModule, InstanceModule)
end

function Purr:InitializeCli()
  for Index, Value in pairs(arg or {}) do
    if type(Index) == "number" and Index > 0 then
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

  TabRuntime.FileName = self.TabFileName
  setfenv(TabFunction, TabRuntime)

  self.Tab = Logger:Assert(TabFunction(), "%s returned nil", self.TabFileName)

  Logger:Info("Loaded tab %s", self.TabFileName)
end

function Purr:Initialize()
  self:InitializeCli()
  self:InitializeRenderer()
  self:InitializeTab()
end

local LayoutEngine = {}

local Renderer = {
  Fonts = {},
  BuiltTexts = {},
}

Purr.Renderer = Renderer

function Renderer:GetColorFromColor4(Color)
  Color = Color or Nya.Color4.new(1, 1, 1, 1)

  local R = math.floor(Color.R * 255)
  local G = math.floor(Color.G * 255)
  local B = math.floor(Color.B * 255)
  local A = math.floor(Color.A * 255)

  return A * 16777216 + R * 65536 + G * 256 + B
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

  local FontFileName = FontName:gsub("NotoSans", "NotoSans-") .. ".ttf"
  local FontPath = "/usr/share/fonts/noto/" .. FontFileName
  local Font, FontError = SDLTtf.open(FontPath, FontSize)

  Logger:Assert(Font and type(Font) ~= "string", "Failed to load font %s: %s", FontPath, tostring(FontError or Font))

  self.Fonts[FontName][FontSize] = Font

  return Font
end

function Renderer:GetFont(FontName, FontSize)
  self.Fonts[FontName] = self.Fonts[FontName] or {}

  return self.Fonts[FontName][FontSize] or self:LoadFont(FontName, FontSize)
end

function Renderer:Text(Text, FontName, TextColor, FontSize, X, Y, AnchorX, AnchorY)
  Logger:AssertType(Text, "string", "Text must be a string, got %s", type(Text))

  FontName = FontName or "NotoSansRegular"
  FontSize = FontSize or 16
  TextColor = TextColor or Nya.Color4.new(0, 0, 0, 1)

  local Font = self:GetFont(FontName, FontSize)

  self.BuiltTexts[FontName] = self.BuiltTexts[FontName] or {}
  self.BuiltTexts[FontName][FontSize] = self.BuiltTexts[FontName][FontSize] or {}

  local Texture = self.BuiltTexts[FontName][FontSize][Text]

  if not Texture then
    local Surface, SurfaceError = Font:renderUtf8(Text, "blended", self:GetColorFromColor4(TextColor))

    Logger:Assert(Surface and type(Surface) ~= "string", "Failed to render text: %s", tostring(SurfaceError or Surface))

    local TextureError
    Texture, TextureError = Purr.SDLRenderer:createTextureFromSurface(Surface)

    Logger:Assert(
      Texture and type(Texture) ~= "string",
      "Failed to create text texture: %s",
      tostring(TextureError or Texture)
    )

    self.BuiltTexts[FontName][FontSize][Text] = Texture
  end

  local _, _, Width, Height = Texture:query()

  X = (X or 0) - Width * (AnchorX or 0)
  Y = (Y or 0) - Height * (AnchorY or 0)

  Purr.SDLRenderer:copy(Texture, nil, {
    x = X,
    y = Y,
    w = Width,
    h = Height,
  })
end

function Renderer:Border(X, Y, Width, Height, Color, Thickness)
  Thickness = Thickness or 1

  if Width <= 0 or Height <= 0 or Thickness <= 0 then
    return
  end

  Thickness = math.min(Thickness, Width, Height)

  Purr.SDLRenderer:setDrawColor(self:GetColorFromColor4(Color))

  Purr.SDLRenderer:fillRect({
    x = X,
    y = Y,
    w = Width,
    h = Thickness,
  })

  Purr.SDLRenderer:fillRect({
    x = X,
    y = Y + Height - Thickness,
    w = Width,
    h = Thickness,
  })

  Purr.SDLRenderer:fillRect({
    x = X,
    y = Y + Thickness,
    w = Thickness,
    h = math.max(0, Height - Thickness * 2),
  })

  Purr.SDLRenderer:fillRect({
    x = X + Width - Thickness,
    y = Y + Thickness,
    w = Thickness,
    h = math.max(0, Height - Thickness * 2),
  })
end

function Renderer:MeasureText(Text, FontName, FontSize)
  FontName = FontName or "NotoSansRegular"
  FontSize = FontSize or 16

  local Font = self:GetFont(FontName, FontSize)
  local Width, Height = Font:sizeUtf8(Text)

  return Nya.Vector2.new(Width, Height)
end

function Renderer:RenderText(Instance)
  local Style = Instance.Style or {}
  local Layout = LayoutEngine:Calculate(Style, Instance.Parent, Instance.Text)

  Instance.AbsolutePosition = Layout.Position
  Instance.AbsoluteSize = Layout.Size

  self:Text(
    Instance.Text or "",
    Style.FontName or "NotoSansRegular",
    Style.TextColor or Nya.Color4.new(0, 0, 0, 1),
    Style.FontSize or 16,
    Layout.Position.X,
    Layout.Position.Y,
    Layout.AnchorPoint.X,
    Layout.AnchorPoint.Y
  )
end

function Renderer:RenderFrame(Instance)
  local Style = Instance.Style or {}
  local Layout = LayoutEngine:Calculate(Style, Instance.Parent)
  local Position = Layout.Position
  local Size = Layout.Size

  Instance.AbsolutePosition = Position
  Instance.AbsoluteSize = Size

  Purr.SDLRenderer:setDrawColor(self:GetColorFromColor4(Layout.BackgroundColor))
  Purr.SDLRenderer:fillRect({
    x = Position.X,
    y = Position.Y,
    w = Size.X,
    h = Size.Y,
  })

  for _, Child in pairs(Instance:GetChildren()) do
    self:RenderInstance(Child)
  end
end

function Renderer:RenderTextButton(Instance)
  local Style = Instance.Style or {}
  local Layout = LayoutEngine:Calculate(Style, Instance.Parent, Instance.Text)
  local Position = Layout.Position
  local Size = Layout.Size

  Instance.AbsolutePosition = Position
  Instance.AbsoluteSize = Size

  Purr.SDLRenderer:setDrawColor(self:GetColorFromColor4(Layout.BackgroundColor))
  Purr.SDLRenderer:fillRect({
    x = Position.X,
    y = Position.Y,
    w = Size.X,
    h = Size.Y,
  })

  self:RenderText(Instance)
  self:Border(Position.X, Position.Y, Size.X, Size.Y, Layout.BorderColor, Layout.BorderThickness)
end

function Renderer:RenderInstance(Instance)
  Logger:AssertType(Instance, "table", "Expected an instance table, got %s", type(Instance))

  if Instance.ClassName == "Text" then
    self:RenderText(Instance)
  elseif Instance.ClassName == "Frame" then
    self:RenderFrame(Instance)
  elseif Instance.ClassName == "TextButton" or Instance.ClassName == "Button" then
    self:RenderTextButton(Instance)
  else
    Logger:Warning("Unsupported instance class: %s", tostring(Instance.ClassName))
  end
end

function Renderer:Frame()
  if Purr.Tab.Exit then
    Purr.Running = false
    return
  end

  for Event in SDL.pollEvent() do
    if Event.type == SDL.event.Quit then
      Purr.Running = false
      return
    end
  end

  local WindowSizeX, WindowSizeY = Purr.SDLWindow:getSize()
  Purr.Window.Size = Nya.Vector2.new(WindowSizeX, WindowSizeY)

  Purr.SDLRenderer:setDrawColor(0xff000000)
  Purr.SDLRenderer:clear()

  self:RenderInstance(Purr.Tab)

  Purr.SDLRenderer:present()
  SDL.delay(10)
end

function LayoutEngine:Calculate(Style, Parent, Text)
  Style = Style or {}

  local ParentPosition = Nya.Vector2.new(0, 0)
  local ParentSize = Purr.Window.Size or Nya.Vector2.new(800, 600)

  if Parent then
    local ParentLayout = self:Calculate(Parent.Style, Parent.Parent)
    ParentPosition = ParentLayout.Position
    ParentSize = ParentLayout.Size
  end

  local Position = Style.Position or Nya.UDim2.new(0, 0, 0, 0)
  local AnchorPoint = Style.AnchorPoint or Nya.Vector2.new(0, 0)
  local Size = Style.Size

  if Text and Size.X.Scale == 0 and Size.X.Offset == 0 and Size.Y.Scale == 0 and Size.Y.Offset == 0 then
    local TextSize = Renderer:MeasureText(Text, Style.FontName, Style.FontSize)
    Size = Nya.UDim2.new(0, TextSize.X, 0, TextSize.Y)
  end

  if not Size then
    Size = Nya.UDim2.new(0, 0, 0, 0)
  end

  local AbsoluteSize =
    Nya.Vector2.new(ParentSize.X * Size.X.Scale + Size.X.Offset, ParentSize.Y * Size.Y.Scale + Size.Y.Offset)

  local AbsolutePosition = Nya.Vector2.new(
    ParentPosition.X + ParentSize.X * Position.X.Scale + Position.X.Offset,
    ParentPosition.Y + ParentSize.Y * Position.Y.Scale + Position.Y.Offset
  )

  AbsolutePosition = Nya.Vector2.new(
    AbsolutePosition.X - AbsoluteSize.X * AnchorPoint.X,
    AbsolutePosition.Y - AbsoluteSize.Y * AnchorPoint.Y
  )

  return {
    Position = AbsolutePosition,
    Size = AbsoluteSize,
    AnchorPoint = AnchorPoint,
    BackgroundColor = Style.BackgroundColor or Nya.Color4.new(1, 1, 1, 0),
    BorderThickness = Style.BorderThickness or 4,
    BorderColor = Style.BorderColor or Nya.Color4.fromRGB(0, 0, 0),
  }
end

function Purr:InitializeRenderer()
  Renderer:Initialize()
end

function Purr.Main()
  Purr:Initialize()

  while Purr.Running do
    Renderer:Frame()
  end
end

Purr.Main()

return Purr
