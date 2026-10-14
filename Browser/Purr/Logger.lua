local Logger = {}

local function FormatMessage(...)
  if select("#", ...) == 0 then
    return ""
  end

  return string.format(...)
end

function Logger:Log(Level, ...)
  local Message = FormatMessage(...)

  io.stderr:write(string.format("Purr: %s: %s\n", tostring(Level), Message))
end

function Logger:Info(...)
  self:Log("Info", ...)
end

function Logger:Warning(...)
  self:Log("Warning", ...)
end

function Logger:Error(...)
  self:Log("Error", ...)
end

function Logger:Assert(Value, ...)
  if Value then
    return Value
  end

  local Message = select("#", ...) > 0 and FormatMessage(...) or "Assertion failed"

  self:Error("%s", Message)
  error(Message, 2)
end

function Logger:AssertType(Value, ExpectedType, ...)
  if type(Value) == ExpectedType then
    return Value
  end

  local Message

  if select("#", ...) > 0 then
    Message = FormatMessage(...)
  else
    Message = string.format("Expected %s, got %s", ExpectedType, type(Value))
  end

  self:Error("%s", Message)
  error(Message, 2)
end

function Logger:PrintTable(Table, Indent, Seen)
  Indent = Indent or 0
  Seen = Seen or {}

  local Prefix = string.rep("  ", Indent)

  if type(Table) ~= "table" then
    print(Prefix .. tostring(Table))
    return
  end

  if Seen[Table] then
    print(Prefix .. "<cycle>")
    return
  end

  Seen[Table] = true
  print(Prefix .. "{")

  for Key, Value in pairs(Table) do
    io.write(string.rep("  ", Indent + 1))
    io.write("[" .. tostring(Key) .. "] = ")

    if type(Value) == "table" then
      self:PrintTable(Value, Indent + 1, Seen)
    else
      print(tostring(Value) .. ",")
    end
  end

  print(Prefix .. "}")
  Seen[Table] = nil
end

return Logger
