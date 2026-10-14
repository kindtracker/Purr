local StyleModule = require("Browser/Purr/Style")

local TabRuntime = {}
TabRuntime.__index = TabRuntime

local function CopyOptions(Options)
  local Copy = {}

  for Key, Value in pairs(Options or {}) do
    Copy[Key] = Value
  end

  return Copy
end

function TabRuntime.new(Purr, Nya, Logger)
  local Runtime = setmetatable({}, TabRuntime)

  Runtime.PurrApp = Purr
  Runtime.Nya = Nya
  Runtime.Logger = Logger
  Runtime.FileName = nil
  Runtime.__Options = nil

  Runtime.Purr = {
    Logger = {},
  }

  return Runtime
end

function TabRuntime:NewStyle(Options)
  return StyleModule.New(self.Nya, Options)
end

function TabRuntime:NewStyledInstance()
  local Options = self.__Options or {}

  return {
    Style = self:NewStyle(Options.Style),
  }
end

function TabRuntime:CreateInstanceModule()
  local Runtime = self

  local InstanceModule = {}

  function InstanceModule.new()
    return {
      Tags = {},
    }
  end

  local TextModule = {}

  function TextModule.new()
    local Instance = Runtime:NewStyledInstance()
    local Options = Runtime.__Options or {}

    Instance.Text = Options.Body or ""

    return Instance
  end

  local FrameModule = {}

  function FrameModule.new()
    return Runtime:NewStyledInstance()
  end

  local TextButtonModule = {}

  function TextButtonModule.new()
    local Instance = Runtime:NewStyledInstance()
    local Options = Runtime.__Options or {}

    Instance.Text = Options.Body or ""

    return Instance
  end

  return InstanceModule, TextModule, FrameModule, TextButtonModule
end

function TabRuntime:Initialize()
  local InstanceModule, TextModule, FrameModule, TextButtonModule = self:CreateInstanceModule()

  self.Nya.Instance:RegisterClass("Text", TextModule, InstanceModule)

  self.Nya.Instance:RegisterClass("TextButton", TextButtonModule, InstanceModule)

  self.Nya.Instance:RegisterClass("Button", TextButtonModule, InstanceModule)

  self.Nya.Instance:RegisterClass("Frame", FrameModule, InstanceModule)

  local Runtime = self
  local PurrApi = self.Purr

  function PurrApi.__NewStyle__(Options)
    return Runtime:NewStyle(Options)
  end

  function PurrApi.new(ClassName, Body, Options)
    Options = CopyOptions(Options)
    Options.Body = Body

    Runtime.__Options = Options

    local Success, Instance = pcall(Runtime.Nya.Instance.new, ClassName)

    Runtime.__Options = nil

    if not Success then
      error(Instance, 2)
    end

    if type(Body) == "string" then
      Instance.Text = Body
    elseif ClassName == "Frame" and type(Body) == "table" then
      for _, Child in pairs(Body) do
        Child.Parent = Instance
      end
    end

    return Instance
  end

  local RuntimeLogger = PurrApi.Logger

  function RuntimeLogger:Log(Level, ...)
    Runtime.Logger:Log(Level, "%s: %s", tostring(Runtime.FileName or "<unknown>"), string.format(...))
  end

  function RuntimeLogger:Info(...)
    self:Log("Info", ...)
  end

  function RuntimeLogger:Warning(...)
    self:Log("Warning", ...)
  end

  function RuntimeLogger:Error(...)
    self:Log("Error", ...)
  end

  function RuntimeLogger:PrintTable(Table, Indent, Seen)
    Runtime.Logger:PrintTable(Table, Indent, Seen)
  end

  function RuntimeLogger:Assert(Value, ...)
    if Value then
      return Value
    end

    local Message = select("#", ...) > 0 and string.format(...) or "Assertion failed"

    self:Error("%s", Message)
    Runtime.PurrApp.Tab.Exit = true

    return nil
  end

  function RuntimeLogger:AssertType(Value, ExpectedType, ...)
    if type(Value) == ExpectedType then
      return Value
    end

    local Message

    if select("#", ...) > 0 then
      Message = string.format(...)
    else
      Message = string.format("Expected %s, got %s", ExpectedType, type(Value))
    end

    self:Error("%s", Message)
    Runtime.PurrApp.Tab.Exit = true

    return nil
  end
end

function TabRuntime:Load(FileName)
  local File = self.Logger:Assert(io.open(FileName, "r"), "Couldn't open %s", FileName)

  local Source = File:read("*a")
  File:close()

  local TabFunction, LuaError = loadstring(Source)

  self.Logger:Assert(TabFunction, "Lua error in %s: %s", FileName, tostring(LuaError))

  self.FileName = FileName

  -- Preserve the existing LuaJIT sandbox environment.
  setfenv(TabFunction, self)

  local Tab = self.Logger:Assert(TabFunction(), "%s returned nil", FileName)

  self.Logger:Info("Loaded tab %s", FileName)

  return Tab
end

return TabRuntime
