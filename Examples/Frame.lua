return Purr.new("Frame", {
  Purr.new("Frame", {
    Purr.new("Text", "Meow", {
      Style = {
        TextColor = Nya.Color4.fromRGB(255, 255, 255),
        Position = Nya.UDim2.new(0, 0, 0, 0),
      },
    }),
    Purr.new("Text", "Mrrrp", {
      Style = {
        TextColor = Nya.Color4.fromRGB(255, 255, 255),
        Position = Nya.UDim2.new(0.1, 0, 0, 0),
      },
    }),
  }, {
    Style = {
      Position = Nya.UDim2.new(0.025, 0, 0.025, 0),
      BackgroundColor = Nya.Color4.fromRGB(98, 62, 62),
      Size = Nya.UDim2.new(0.95, 0, 0.95, 0),
    },
  }),
}, {
  Style = {
    BackgroundColor = Nya.Color4.fromRGB(0, 0, 0),
    Size = Nya.UDim2.new(1, 0, 1, 0),
  },
})
