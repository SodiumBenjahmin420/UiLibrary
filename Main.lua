-- / Global
local env = getgenv()

env.GlobalActive = false

if not env.PreviousExecutions then
    env.PreviousExecutions = {}
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
local KeyCode = Enum.KeyCode
local LibraryInstance = nil

-- / Variables
local Bar = "|"
local CaseId = HttpService:GenerateGUID(false) .. Bar .. os.time() .. Bar .. LocalPlayer.UserId
local Default_Keybind = KeyCode.Space
local Default_ModifierBind = KeyCode.LeftControl
local Active_Keybind = Default_Keybind
local Active_ModifierBind = Default_ModifierBind
local IsModifierHeld = false

-- / Module
local UiLibrary = {}
UiLibrary.__index = UiLibrary

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
        CanvasGroup = Gossamer:Create(Gui.UiHolder,1,true),
    }
    local executionId = HttpService:GenerateGUID(false)
    print("Creating new execution:", executionId)
    print("Number of signals:", #self.Signals)
    
    PreviousExecutions[executionId] = {
        gui = Gui,
        signals = self.Signals
    }
    
    -- Print the current state of PreviousExecutions
    print("Current executions:", HttpService:JSONEncode(table.getn(PreviousExecutions)))


    self.Signals.ToggleSignal:Connect(function()
        DefaultToggle(self.Ui)
    end)

    ContextActionService:BindAction("BlockDefaultActions", function(_, state, _)
        if state == Enum.UserInputState.Begin then
            IsModifierHeld = true
        elseif state == Enum.UserInputState.End then
            IsModifierHeld = false
        end
        return Enum.ContextActionResult.Sink
    end, false, Active_ModifierBind)

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
    ContextActionService:UnbindAction("BlockDefaultActions")
    
    Active_Keybind = Keybind or Default_Keybind
    Active_ModifierBind = ModifierBind or Default_ModifierBind
    
    ContextActionService:BindAction("BlockDefaultActions", function(_, state, _)
        if state == Enum.UserInputState.Begin then
            IsModifierHeld = true
        elseif state == Enum.UserInputState.End then
            IsModifierHeld = false
        end
        return Enum.ContextActionResult.Sink
    end, false, Active_ModifierBind)
end

function UiLibrary:Toggle(Boolean:boolean) -- If nil will set to the opposite (ex. if true set to false if nil case)
    self.Signals.ToggleSignal:Fire(Boolean or not env.GlobalActive)
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Active_Keybind and IsModifierHeld then
        LibraryInstance:Toggle()
    end
end)

env.Cleanup = function()
    ContextActionService:UnbindAction("BlockDefaultActions")
    
    print("Starting cleanup, number of previous executions:", table.getn(PreviousExecutions))
    
    for executionId, previousExecution in pairs(PreviousExecutions) do
        print("Cleaning up execution:", executionId)
        
        if previousExecution.gui then
            print("GUI found:", previousExecution.gui.Name)
            previousExecution.gui:Destroy()
        else
            print("No GUI found for execution", executionId)
        end
        
        if previousExecution.signals then
            print("Number of signals to destroy:", table.getn(previousExecution.signals))
            for signalName, signal in pairs(previousExecution.signals) do
                print("Destroying signal:", signalName)
                signal:Destroy()
                print("Signal destroyed")
            end
        else
            print("No signals found for execution", executionId)
        end
        
        PreviousExecutions[executionId] = nil
    end
    
    print("Cleanup complete, remaining executions:", table.getn(PreviousExecutions))
end
env.Cleanup()

return UiLibrary
