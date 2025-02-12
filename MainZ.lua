-- / Global
local env = getgenv()

env.GlobalActive = false

if not env.PreviousExecutions then
    env.PreviousExecutions = {}
end
if not env.InputConnections then
    env.InputConnections = {
        inputBegan = nil,
        inputEnded = nil
    }
end
-- / Types
type Function = (...any) -> any

type Signal = {
    Fire: (...any) -> nil,
    Connect: (handler: Function) -> RBXScriptConnection,
    Wait: () -> ...any,
    Destroy: () -> nil
}

type PreviousExecution = {
    gui: ScreenGui,
    signals: {Signal}
}

-- / Modules
local Signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/Quenty/NevermoreEngine/6ca66a994dba630ad9ac0e2208ac3b8b6630b053/Modules/Events/Signal.lua"))()
local Gossamer = loadstring(game:HttpGet("https://raw.githubusercontent.com/SodiumBenjahmin420/UiLibrary/refs/heads/Features/Gossamer"))()

-- / Services
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
-- / Environment
local LocalPlayer: Player = Players.LocalPlayer
local PreviousExecutions = env.PreviousExecutions
local InputConnections = env.InputConnections
local KeyCode = Enum.KeyCode
local LibraryInstance = nil

-- / Variables
local Bar = "|"
local CaseId = HttpService:GenerateGUID(false) .. Bar .. os.time() .. Bar .. LocalPlayer.UserId
local Default_Keybind = KeyCode.Space
local Default_ModifierBind = KeyCode.LeftControl
local Active_Keybind = Default_Keybind
local Active_ModifierBind = Default_ModifierBind

-- / Module
local UiLibrary = {}
UiLibrary.__index = UiLibrary

local InputSignals = {
    modifierPressed = Signal.new(),
    modifierReleased = Signal.new()
}

function UiLibrary.new(Title: string)
    if not Title then
        Title = "Default Title"
    end

    local Gui: ScreenGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/SodiumBenjahmin420/UiLibrary/refs/heads/Features/GUI"))()
    Gui.Name = Gui.Name .. CaseId
    
    local self = {
        Title = Title,
        Signals = {
            ToggleSignal = Signal.new(),
        },
        Case_Id = CaseId,
        Ui = Gui,
        CanvasGroup = Gossamer:Create(Gui.UiHolder, 1, true),
        contextActionBound = false
    }
    
    local executionId = HttpService:GenerateGUID(false)
    print("Creating new execution:", executionId)
    
    -- Clean up previous input connections if they exist
    if InputConnections.inputBegan then
        InputConnections.inputBegan:Disconnect()
    end
    if InputConnections.inputEnded then
        InputConnections.inputEnded:Disconnect()
    end
    
    -- Set up new input connections using signals
    InputConnections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if input.KeyCode == Active_ModifierBind then
            InputSignals.modifierPressed:Fire()
        end
    end)

    InputConnections.inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if input.KeyCode == Active_ModifierBind then
            InputSignals.modifierReleased:Fire()
        end
    end)
    
    -- Store execution data
    PreviousExecutions[executionId] = {
        gui = Gui,
        signals = self.Signals,
        contextActionBound = false
    }
    
    -- Set up toggle handling
    self.Signals.ToggleSignal:Connect(function()
        DefaultToggle(self.Ui)
    end)
    
    -- Set up input signal handling
    InputSignals.modifierPressed:Connect(function()
        if not PreviousExecutions[executionId].contextActionBound then
            ContextActionService:BindAction(
                "BlockJumpAndToggle",
                function(actionName, inputState, inputObject)
                    if inputState == Enum.UserInputState.Begin then
                        self:Toggle()
                    end
                    return Enum.ContextActionResult.Sink
                end,
                false,
                Active_Keybind
            )
            PreviousExecutions[executionId].contextActionBound = true
        end
    end)
    
    InputSignals.modifierReleased:Connect(function()
        if PreviousExecutions[executionId].contextActionBound then
            ContextActionService:UnbindAction("BlockJumpAndToggle")
            PreviousExecutions[executionId].contextActionBound = false
        end
    end)

    LibraryInstance = setmetatable(self, UiLibrary)

    return LibraryInstance
end

-- / Module Environment

function UiLibrary:AnimateVisible()
    
end

function DefaultToggle(Gui)
    
    local MousePos = UserInputService:GetMouseLocation()

    print(MousePos)

end



function UiLibrary:ChangeBinds(Keybind:Enum.KeyCode, ModifierBind:Enum.KeyCode)
    Active_Keybind = Keybind or Default_Keybind
    Active_ModifierBind = ModifierBind or Default_ModifierBind
end

function UiLibrary:Toggle(Boolean:boolean) -- If nil will set to the opposite (ex. if true set to false if nil case)
    self.Signals.ToggleSignal:Fire(Boolean or not env.GlobalActive)
end

local function handleJumpAction(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        LibraryInstance:Toggle()
    end
    return Enum.ContextActionResult.Sink
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Active_ModifierBind then
        -- when modifier is pressed, disable jumping and set up toggle handler
        ContextActionService:BindAction(
            "BlockJumpAndToggle",
            handleJumpAction,
            false,
            Active_Keybind
        )
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Active_ModifierBind then
        -- when modifier is released, restore default jump behavior
        ContextActionService:UnbindAction("BlockJumpAndToggle")
    end
end)

env.Cleanup = function()
    -- Unbind context action if it exists
    ContextActionService:UnbindAction("BlockJumpAndToggle")
    
    -- Clean up input connections
    if InputConnections.inputBegan then
        InputConnections.inputBegan:Disconnect()
    end
    if InputConnections.inputEnded then
        InputConnections.inputEnded:Disconnect()
    end
    
    -- Clean up input signals
    for _, signal in pairs(InputSignals) do
        signal:Destroy()
    end
    
    -- Clean up previous executions
    for executionId, previousExecution in pairs(PreviousExecutions) do
        if previousExecution.gui then
            previousExecution.gui:Destroy()
        end
        
        if previousExecution.signals then
            for _, signal in pairs(previousExecution.signals) do
                signal:Destroy()
            end
        end
        
        PreviousExecutions[executionId] = nil
    end
end
env.Cleanup()

return UiLibrary
