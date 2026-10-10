local SDL2 = require("SDL")

local Purr = {
  Window = nil,
  Running = false,
  Fps = 1,
}

function Purr:Initialize()
  SDL2.init(SDL2.flags.Everything)

  Purr.Window = SDL2.createWindow({
    title = "Purr",
    width = 800,
    height = 600,
    flags = { SDL2.window.Resizable },
  })

  Purr.Running = true
  Purr.Fps = math.floor((1 / 60) * 1000)
end

function Purr:Frame()
  for Event in SDL2.pollEvent() do
    if Event.type == SDL2.event.Quit then
      Purr.Running = false
    end
  end

  SDL2.delay(Purr.Fps)
end

function Purr.Main()
  Purr:Initialize()

  while Purr.Running do
    Purr:Frame()
  end
end

Purr.Main()
