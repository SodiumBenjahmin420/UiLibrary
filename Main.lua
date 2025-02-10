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

-- / Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- / Environment
local LocalPlayer: Player = Players.LocalPlayer
local PlayerGui: PlayerGui = LocalPlayer.PlayerGui
local PreviousExecutions = env.PreviousExecutions

-- / Variables
local Bar = "|"
local CaseId = HttpService:GenerateGUID(false) .. Bar .. os.time() .. Bar .. LocalPlayer.UserId

-- / Module
local UiLibrary = {}
UiLibrary.__index = UiLibrary

function UiLibrary.new(Title: string)
    assert(Title ~= nil, "Argument #1 (title) of Dialogue can not be nil.")
    if not Title then
        Title = "Default Title"
    end

    local Gui: ScreenGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/SodiumBenjahmin420/UiLibrary/refs/heads/Features/GUI"))()
    Gui.Name = Gui.Name .. CaseId

    local self = {
        Title = Title,
        Signals = {},
        Case_Id = CaseId,
        Ui = Gui
    }
    
    local executionId = HttpService:GenerateGUID(false)
    PreviousExecutions[executionId] = {
        gui = Gui,
        signals = self.Signals
    }
    
    return setmetatable(self, UiLibrary)
end

-- / Module Environment
local function Visible(Boolean: boolean)
    -- Implementation here
end

function UiLibrary:SetVisible(Boolean: boolean)
    Visible(Boolean)
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
