local Renderer = {}
Renderer.__index = Renderer

function Renderer.new(Purr, Nya, SDL, SDLTtf, Logger)
  return setmetatable({
    Purr = Purr,
    Nya = Nya,
    SDL = SDL,
    SDLTtf = SDLTtf,
    Logger = Logger,

    LayoutEngine = nil,
    Fonts = {},
    BuiltTexts = {},
    WarnedClasses = {},
  }, Renderer)
end

function Renderer:GetColorFromColor4(Color)
  Color = Color or self.Nya.Color4.new(1, 1, 1, 1)

  local R = math.floor(Color.R * 255)
  local G = math.floor(Color.G * 255)
  local B = math.floor(Color.B * 255)
  local A = math.floor(Color.A * 255)

  return A * 16777216 + R * 65536 + G * 256 + B
end

function Renderer:Initialize()
  local SDL = self.SDL
  local Purr = self.Purr
  local Logger = self.Logger

  SDL.init(SDL.flags.Everything)

  local Window, WindowError = SDL.createWindow({
    title = "Purr",
    width = 800,
    height = 600,
    flags = { SDL.window.Resizable },
  })

  Logger:Assert(Window and type(Window) ~= "string", "Failed to create SDL window: %s", tostring(WindowError or Window))

  Purr.SDLWindow = Window

  local SDLRenderer, RendererError = SDL.createRenderer(Window, 0, 0)

  Logger:Assert(
    SDLRenderer and type(SDLRenderer) ~= "string",
    "Failed to create SDL renderer: %s",
    tostring(RendererError or SDLRenderer)
  )

  Purr.SDLRenderer = SDLRenderer

  self.SDLTtf.init(SDL.flags.Everything)

  Purr.Running = true

  Logger:Info("Renderer initialized")
end

function Renderer:LoadFont(FontName, FontSize)
  local Logger = self.Logger

  self.Fonts[FontName] = self.Fonts[FontName] or {}

  local FontFileName = FontName:gsub("NotoSans", "NotoSans-") .. ".ttf"

  local FontPath = "/usr/share/fonts/noto/" .. FontFileName

  local Font, FontError = self.SDLTtf.open(FontPath, FontSize)

  Logger:Assert(Font and type(Font) ~= "string", "Failed to load font %s: %s", FontPath, tostring(FontError or Font))

  self.Fonts[FontName][FontSize] = Font

  return Font
end

function Renderer:GetFont(FontName, FontSize)
  FontName = FontName or "NotoSansRegular"
  FontSize = FontSize or 16

  self.Fonts[FontName] = self.Fonts[FontName] or {}

  return self.Fonts[FontName][FontSize] or self:LoadFont(FontName, FontSize)
end

function Renderer:MeasureText(Text, FontName, FontSize)
  local Font = self:GetFont(FontName, FontSize)
  local Width, Height = Font:sizeUtf8(Text)

  return self.Nya.Vector2.new(Width, Height)
end

function Renderer:GetTextTexture(Text, FontName, TextColor, FontSize)
  local Purr = self.Purr
  local Logger = self.Logger

  FontName = FontName or "NotoSansRegular"
  FontSize = FontSize or 16
  TextColor = TextColor or self.Nya.Color4.new(0, 0, 0, 1)

  local ColorKey = self:GetColorFromColor4(TextColor)

  self.BuiltTexts[FontName] = self.BuiltTexts[FontName] or {}
  self.BuiltTexts[FontName][FontSize] = self.BuiltTexts[FontName][FontSize] or {}

  local FontCache = self.BuiltTexts[FontName][FontSize]
  FontCache[ColorKey] = FontCache[ColorKey] or {}

  local Texture = FontCache[ColorKey][Text]

  if Texture then
    return Texture
  end

  local Font = self:GetFont(FontName, FontSize)

  local Surface, SurfaceError = Font:renderUtf8(Text, "blended", ColorKey)

  Logger:Assert(Surface and type(Surface) ~= "string", "Failed to render text: %s", tostring(SurfaceError or Surface))

  local TextureError

  Texture, TextureError = Purr.SDLRenderer:createTextureFromSurface(Surface)

  Logger:Assert(
    Texture and type(Texture) ~= "string",
    "Failed to create text texture: %s",
    tostring(TextureError or Texture)
  )

  FontCache[ColorKey][Text] = Texture

  return Texture
end

function Renderer:Text(Text, FontName, TextColor, FontSize, X, Y, AnchorX, AnchorY)
  self.Logger:AssertType(Text, "string", "Text must be a string, got %s", type(Text))

  local Texture = self:GetTextTexture(Text, FontName, TextColor, FontSize)

  local _, _, Width, Height = Texture:query()

  X = (X or 0) - Width * (AnchorX or 0) / 4
  Y = (Y or 0) - Height * (AnchorY or 0) / 4

  self.Purr.SDLRenderer:copy(Texture, nil, {
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

  local SDLRenderer = self.Purr.SDLRenderer

  SDLRenderer:setDrawColor(self:GetColorFromColor4(Color))

  SDLRenderer:fillRect({
    x = X,
    y = Y,
    w = Width,
    h = Thickness,
  })

  SDLRenderer:fillRect({
    x = X,
    y = Y + Height - Thickness,
    w = Width,
    h = Thickness,
  })

  SDLRenderer:fillRect({
    x = X,
    y = Y + Thickness,
    w = Thickness,
    h = math.max(0, Height - Thickness * 2),
  })

  SDLRenderer:fillRect({
    x = X + Width - Thickness,
    y = Y + Thickness,
    w = Thickness,
    h = math.max(0, Height - Thickness * 2),
  })
end

function Renderer:RenderText(Instance)
  local Style = Instance.Style or {}

  local Layout = self.LayoutEngine:Calculate(Style, Instance.Parent, Instance.Text or "")

  Instance.AbsolutePosition = Layout.Position
  Instance.AbsoluteSize = Layout.Size

  self:Text(
    Instance.Text or "",
    Style.FontName or "NotoSansRegular",
    Style.TextColor or self.Nya.Color4.new(0, 0, 0, 1),
    Style.FontSize or 16,
    Layout.Position.X,
    Layout.Position.Y,
    Layout.AnchorPoint.X,
    Layout.AnchorPoint.Y
  )
end

function Renderer:RenderFrame(Instance)
  local Style = Instance.Style or {}
  local Layout = self.LayoutEngine:Calculate(Style, Instance.Parent)

  local Position = Layout.Position
  local Size = Layout.Size

  Instance.AbsolutePosition = Position
  Instance.AbsoluteSize = Size

  self.Purr.SDLRenderer:setDrawColor(self:GetColorFromColor4(Layout.BackgroundColor))

  self.Purr.SDLRenderer:fillRect({
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

  local Layout = self.LayoutEngine:Calculate(Style, Instance.Parent, Instance.Text or "")

  local Position = Layout.Position
  local Size = Layout.Size

  Instance.AbsolutePosition = Position
  Instance.AbsoluteSize = Size

  self.Purr.SDLRenderer:setDrawColor(self:GetColorFromColor4(Layout.BackgroundColor))

  self.Purr.SDLRenderer:fillRect({
    x = Position.X,
    y = Position.Y,
    w = Size.X,
    h = Size.Y,
  })

  self:Text(
    Instance.Text or "",
    Style.FontName or "NotoSansRegular",
    Style.TextColor or self.Nya.Color4.new(0, 0, 0, 1),
    Style.FontSize or 16,
    Position.X,
    Position.Y,
    Layout.AnchorPoint.X,
    Layout.AnchorPoint.Y
  )

  self:Border(Position.X, Position.Y, Size.X, Size.Y, Layout.BorderColor, Layout.BorderThickness)
end

function Renderer:RenderInstance(Instance)
  self.Logger:AssertType(Instance, "table", "Expected an instance table, got %s", type(Instance))

  local ClassName = Instance.ClassName

  if ClassName == "Text" then
    self:RenderText(Instance)
  elseif ClassName == "Frame" then
    self:RenderFrame(Instance)
  elseif ClassName == "TextButton" or ClassName == "Button" then
    self:RenderTextButton(Instance)
  elseif not self.WarnedClasses[ClassName] then
    self.WarnedClasses[ClassName] = true

    self.Logger:Warning("Unsupported instance class: %s", tostring(ClassName))
  end
end

function Renderer:Frame()
  local Purr = self.Purr
  local SDL = self.SDL

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

  local Width, Height = Purr.SDLWindow:getSize()

  Purr.Window.Size = self.Nya.Vector2.new(Width, Height)

  Purr.SDLRenderer:setDrawColor(0xff000000)
  Purr.SDLRenderer:clear()

  self:RenderInstance(Purr.Tab)

  Purr.SDLRenderer:present()
  SDL.delay(10)
end

return Renderer
