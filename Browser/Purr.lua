local SDL2 = require("SDL")

local Purr = {
  Window = nil,
  Running = false,
  Fps = 1,
  Tab = {},
  TabFileName = "",
  TabRuntime = {},
  Stop = false,
}

function Purr.TabRuntime.Text(Text)
  print(Text)
end

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

  Purr:InitializeCli()
  if Purr.Stop then
    return
  end

  Purr:InitializeTab()
  if Purr.Stop then
    return
  end
end

function Purr:InitializeCli()
  for Index, Value in pairs(arg) do
    if Index > 0 then
      Purr.TabFileName = Value
    end
  end

  if Purr.TabFileName == nil then
    print("Need TabFileName")
    Purr.Stop = true
    return
  end
end

function Purr:InitializeTab()
  local TabFilePtr = io.open(Purr.TabFileName, "r")

  if TabFilePtr == nil then
    print(string.format("Couldn't open %s", Purr.TabFileName))
    Purr.Stop = true
    return
  end

  local TabSource = TabFilePtr:read("*a")
  TabFilePtr:close()

  local TabFunction, LuaError = loadstring(TabSource)

  if LuaError or TabFunction == nil then
    print(string.format("Tab: Lua Error: %s", LuaError))
    Purr.Stop = true
    return
  end

  setfenv(TabFunction, Purr.TabRuntime)

  local Tab = TabFunction()

  Purr.Tab = Tab
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
  if Purr.Stop then
    return
  end

  while Purr.Running do
    Purr:Frame()
  end
end

Purr.Main()
