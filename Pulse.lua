local Pulse = {}
local env = getgenv()

local function createUUID()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function compressAndEncrypt(value)
    local stringValue = tostring(value)
    local compressed = lz4_compress(stringValue)
    local encrypted = crypt.encrypt(compressed, crypt.generatekey(stringValue))
    return encrypted
end

local function decryptAndDecompress(encryptedValue)
    local decrypted = crypt.decrypt(encryptedValue, crypt.generatekey(tostring(math.random())))
    local decompressed = lz4_decompress(decrypted)
    return decompressed
end

local VariableTracker = {}
VariableTracker.__index = VariableTracker

function Pulse.new(initialValue)
    local self = setmetatable({
        _uuid = createUUID(),
        _value = nil,
        _callbacks = {},
        _connections = {},
    }, VariableTracker)
    
    if initialValue ~= nil then
        self:Set(initialValue)
    end
    
    env[self._uuid] = self
    return self
end

function VariableTracker:Set(value)
    local oldValue = self._value
    self._value = compressAndEncrypt(value)
    
    for _, callback in ipairs(self._callbacks) do
        pcall(callback, oldValue, value)
    end
    
    return self
end

function VariableTracker:Get()
    return decryptAndDecompress(self._value)
end

function VariableTracker:Update(value, fireCallback)
    fireCallback = fireCallback == nil and true or fireCallback
    
    local oldValue = self:Get()
    self._value = compressAndEncrypt(value)
    
    if fireCallback then
        for _, callback in ipairs(self._callbacks) do
            pcall(callback, oldValue, value)
        end
    end
    
    return self
end

function VariableTracker:EnableListen(callback)
    table.insert(self._callbacks, callback)
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
            pcall(callback, self:Get(), nil)
        end
    end
    
    env[self._uuid] = nil
    self._callbacks = {}
    self._value = nil
    
    return nil
end

function VariableTracker:__tostring()
    return tostring(self:Get())
end

function VariableTracker:__call()
    return self:Get()
end

function Pulse.fromEnvironment(key)
    return env[key]
end



return Pulse