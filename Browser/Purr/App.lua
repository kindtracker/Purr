local Nya = require("Browser/Nya")
local SDL = require("SDL")
local SDLTtf = require("SDL.ttf")

local Logger = require("Browser/Purr/Logger")
local TabRuntimeModule = require("Browser/Purr/TabRuntime")
local LayoutEngineModule = require("Browser/Purr/LayoutEngine")
local RendererModule = require("Browser/Purr/Renderer")

local Purr = {
  SDLWindow = nil,
  SDLRenderer = nil,

  Window = {
    Size = Nya.Vector2.new(800, 600),
  },

  Running = false,
  Tab = {},
  TabFileName = "",

  TabRuntime = nil,
  Renderer = nil,
  LayoutEngine = nil,

  Logger = Logger,
}

function Purr:InitializeCli(Arguments)
  Arguments = Arguments or arg or {}

  for Index, Value in ipairs(Arguments) do
    if type(Value) == "string" and Value ~= "" then
      self.TabFileName = Value
      break
    end
  end

  Logger:Assert(self.TabFileName ~= "", "Missing TabFileName. Usage: luajit Browser/Purr.lua <file>")
end

function Purr:InitializeRenderer()
  self.Renderer = RendererModule.new(self, Nya, SDL, SDLTtf, Logger)

  self.LayoutEngine = LayoutEngineModule.new(Nya, self, self.Renderer)

  self.Renderer.LayoutEngine = self.LayoutEngine
  self.Renderer:Initialize()
end

function Purr:InitializeTab()
  self.TabRuntime = TabRuntimeModule.new(self, Nya, Logger)

  self.TabRuntime:Initialize()

  self.Tab = self.TabRuntime:Load(self.TabFileName)
end

function Purr:Initialize(Arguments)
  self:InitializeCli(Arguments)
  self:InitializeRenderer()
  self:InitializeTab()
end

function Purr:Run()
  while self.Running do
    self.Renderer:Frame()
  end
end

function Purr.Main(Arguments)
  Purr:Initialize(Arguments)
  Purr:Run()
end

return Purr
