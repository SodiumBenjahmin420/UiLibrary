-- / Global
local env = getgenv()

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

-- / Environment
local LocalPlayer: Player = Players.LocalPlayer
local PlayerGui: PlayerGui = LocalPlayer.PlayerGui
local PreviousExecutions = env.PreviousExecutions
local KeyCode = Enum.KeyCode

-- / Variables
local Bar = "|"
local CaseId = HttpService:GenerateGUID(false) .. Bar .. os.time() .. Bar .. LocalPlayer.UserId
local Default_Keybind = KeyCode.Space
local Default_ModifierBind = KeyCode.LeftControl

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
    local Signal_For_Toggle = Signal.new()
    local self = {
        Title = Title,
        Signals = {
            ToggleSignal = Signal_For_Toggle,
        },
        Case_Id = CaseId,
        Ui = Gui,
        Keybind = Default_Keybind,
        ModifierBind = Default_ModifierBind,
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

function UiLibrary:SetToggleFunction(Callback: Function)
    print("no")
    if Callback then
        self.Signals.ToggleSignal:Connect(Callback)
    end

    print("yes")


end

function UiLibrary:ChangeBinds(Keybind:Enum.KeyCode, ModifierBind:Enum.KeyCode)
    self.Keybind = Keybind or self.Keybind
    self.ModifierBind = ModifierBind or self.ModifierBind
end

function UiLibrary:Toggle(Boolean:boolean) -- If nil will set to the opposite (ex. if true set to false if nil case)
    self.Signals.ToggleSignal:Fire(Boolean or nil)
end

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
                signal:Destroy()
            end
        end
        
        PreviousExecutions[executionId] = nil
    end
end
env.Cleanup()

return UiLibrary
