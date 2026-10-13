return Purr.new("Frame", {
  Purr.new("TextButton", "Meow (TextButton)", {
    Style = {
      Position = Nya.UDim2.new((1 / 3) - 1 / 3 / 1.75, 0, 0.5, 0),
      AnchorPoint = Nya.Vector2.new(0.5, 0.5),
      BorderColor = Nya.Color4.fromRGB(255, 0, 0),
    },
  }),
  Purr.new("Text", "Meow (ImageButton) (Unimplemented)", {
    Style = {
      Position = Nya.UDim2.new((2 / 3) - 1 / 3 / 1.75, 0, 0.5, 0),
      AnchorPoint = Nya.Vector2.new(0.5, 0.5),
    },
  }),

  -- Button is TextButton and ImageButton
  Purr.new("Button", "Meow (Button)", {
    Style = {
      Position = Nya.UDim2.new((3 / 3) - 1 / 3 / 1.75, 0, 0.5, 0),
      AnchorPoint = Nya.Vector2.new(0.5, 0.5),
      BorderColor = Nya.Color4.fromRGBA(255, 0, 0, 255),
    },
  }),
}, {
  Style = {
    Position = Nya.UDim2.new(0, 0, 0, 0),
    Size = Nya.UDim2.new(1, 0, 1, 0),
  },
})
