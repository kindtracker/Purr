local Style = {}

function Style.New(Nya, Options)
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

return Style
