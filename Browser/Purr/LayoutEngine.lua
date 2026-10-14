local LayoutEngine = {}
LayoutEngine.__index = LayoutEngine

function LayoutEngine.new(Nya, Purr, Renderer)
  return setmetatable({
    Nya = Nya,
    Purr = Purr,
    Renderer = Renderer,
  }, LayoutEngine)
end

function LayoutEngine:Calculate(Style, Parent, Text)
  local Nya = self.Nya

  Style = Style or {}

  local ParentPosition = Nya.Vector2.new(0, 0)
  local ParentSize = self.Purr.Window.Size or Nya.Vector2.new(800, 600)

  if Parent then
    local ParentLayout = self:Calculate(Parent.Style, Parent.Parent)

    ParentPosition = ParentLayout.Position
    ParentSize = ParentLayout.Size
  end

  local Position = Style.Position or Nya.UDim2.new(0, 0, 0, 0)

  local AnchorPoint = Style.AnchorPoint or Nya.Vector2.new(0, 0)

  local Size = Style.Size or Nya.UDim2.new(0, 0, 0, 0)

  local IsAutomaticSize = Size.X.Scale == 0 and Size.X.Offset == 0 and Size.Y.Scale == 0 and Size.Y.Offset == 0

  if Text and IsAutomaticSize then
    local TextSize = self.Renderer:MeasureText(Text, Style.FontName, Style.FontSize)

    Size = Nya.UDim2.new(0, TextSize.X, 0, TextSize.Y)
  end

  local AbsoluteSize =
    Nya.Vector2.new(ParentSize.X * Size.X.Scale + Size.X.Offset, ParentSize.Y * Size.Y.Scale + Size.Y.Offset)

  local AbsolutePosition =
    Nya.Vector2.new(ParentPosition.X + ParentSize.X * Position.X.Scale + Position.X.Offset, ParentPosition.Y + ParentSize.Y * Position.Y.Scale + Position.Y.Offset)

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

return LayoutEngine
