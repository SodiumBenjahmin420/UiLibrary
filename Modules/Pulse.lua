
local Pulse = {}
local env = getgenv()

local function createUUID()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local VariableTracker = {}
VariableTracker.__index = VariableTracker

function Pulse.new(initialValue)
    local self = setmetatable({
        _value = initialValue,
        _callbacks = {},
        _listenEnabled = true,
        _uuid = createUUID()
    }, VariableTracker)

    return self
end

function VariableTracker:Set(value)
    if self.listenEnabled then
        for _, callback in ipairs(self._callbacks) do
            pcall(callback, self._value, value)
        end
    end
    self._value = value
    return self
end

function VariableTracker:Get()
    return self._value
end

function VariableTracker:Update(value, fireCallback)
    fireCallback = fireCallback == nil and true or fireCallback

    if fireCallback then
        for _, callback in ipairs(self._callbacks) do
            pcall(callback, self._value, value)
        end
    end

    self._value = value
    return self
end

function VariableTracker:EnableListen(callback)
    if callback then
        table.insert(self._callbacks, callback)
    end
    self._listenEnabled = true
    return self
end

function VariableTracker:DisableListen(callback, shouldDestroy)
    if callback then
        for i, func in ipairs(self._callbacks) do
            if func == callback then
                table.remove(self._callbacks, i)
                break
            end
        end
    end

    self._listenEnabled = false

    if shouldDestroy then
        self:Destroy()
    end

    return self
end

function VariableTracker:ChangeCallback(newCallback)
    self._callbacks = {newCallback}
    return self
end

function VariableTracker:Destroy(fireCallback)
    if fireCallback then
        for _, callback in ipairs(self._callbacks) do
            pcall(callback, self._value, nil)
        end
    end

    env[self._uuid] = nil
    self._callbacks = {}
    self._value = nil

    return nil
end

function VariableTracker:__tostring()
    return tostring(self._value)
end

function VariableTracker:__call()
    return self._value
end

function Pulse.fromEnvironment(key)
    return env[key]
end

return Pulse
