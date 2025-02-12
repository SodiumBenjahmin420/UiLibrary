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
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
-- / Environment
local LocalPlayer: Player = Players.LocalPlayer
local PreviousExecutions = env.PreviousExecutions
local KeyCode = Enum.KeyCode

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

function UiLibrary.new(Title: string)
    if not Title then
        Title = "Default Title"
    end

    local Gui: ScreenGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/SodiumBenjahmin420/UiLibrary/refs/heads/Features/GUI"))()
    Gui.Name = Gui.Name .. CaseId
    local Group = Gossamer:Create(Gui.UiHolder,1,true)
    local self = {
        Title = Title,
        Signals = {
            ToggleSignal = Signal.new(),
        },
        Case_Id = CaseId,
        Ui = Gui,
        CanvasGroup = Group,
    }
    local executionId = HttpService:GenerateGUID(false)
    PreviousExecutions[executionId] = {
        gui = Gui,
        signals = self.Signals
    }
    
    return setmetatable(self, UiLibrary)
end

-- / Module Environment

function UiLibrary:AnimateVisible()
    
end

local function DefaultToggle(Gui)
    
    local MousePos = UserInputService:GetMouseLocation()

    print(MousePos)

end

function UiLibrary:SetToggleFunction(Callback: Function)
    if Callback then
        self.Signals.ToggleSignal:Connect(Callback)
    else
        self.Signals.ToggleSignal:Connect(function()
            print("Done")
            DefaultToggle(self.Ui)
        end)
    end

end


function UiLibrary:ChangeBinds(Keybind:Enum.KeyCode, ModifierBind:Enum.KeyCode)
    Active_Keybind = Keybind or Default_Keybind
    Active_ModifierBind = ModifierBind or Default_ModifierBind
end

function UiLibrary:Toggle(Boolean:boolean) -- If nil will set to the opposite (ex. if true set to false if nil case)
    self.Signals.ToggleSignal:Fire(Boolean or not env.GlobalActive)
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Active_Keybind and UserInputService:IsKeyDown(Active_ModifierBind)then
        
        UiLibrary:Toggle()

    end

end)

env.Cleanup = function()
    for executionId, previousExecution in pairs(PreviousExecutions) do
        print("Cleaning up", executionId)
        if previousExecution.gui then
            print("GUI found:", previousExecution.gui)
            previousExecution.gui:Destroy()
        else
            print("No GUI found for execution", executionId)
        end
        
        if previousExecution.signals then
            for _, signal in ipairs(previousExecution.signals) do
                print("Destroying")
                signal:Destroy()
            end
        end
        
        PreviousExecutions[executionId] = nil
    end
end
env.Cleanup()

return UiLibrary
