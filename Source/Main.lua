local SDL2 = require("SDL")

local win = assert(SDL2.createWindow({
  title = "02 - Opening a window",
  width = 320,
  height = 320,
  flags = { SDL2.window.Resizable },
  x = 126,
  y = 126,
}))

local PurrRunning = true

while PurrRunning do
  for Event in SDL2.pollEvent() do
    if Event.type == SDL2.event.Quit then
      PurrRunning = false
    elseif Event.type == SDL2.event.KeyDown then
      print(string.format("Key down: %d -> %s", Event.keysym.sym, SDL2.getKeyName(Event.keysym.sym)))
    elseif Event.type == SDL2.event.MouseWheel then
      print(string.format("Mouse wheel: %d, x=%d, y=%d", Event.which, Event.x, Event.y))
    elseif Event.type == SDL2.event.MouseButtonDown then
      print(string.format("Mouse button down: %d, x=%d, y=%d", Event.button, Event.x, Event.y))
    elseif Event.type == SDL2.event.MouseMotion then
      print(string.format("Mouse motion: x=%d, y=%d", Event.x, Event.y))
    end
  end

  SDL2.delay(1)
end
