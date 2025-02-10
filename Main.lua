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
    gui:ScreenGui,
    signals:Signal
}
-- / Modules

local Signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/Quenty/NevermoreEngine/6ca66a994dba630ad9ac0e2208ac3b8b6630b053/Modules/Events/Signal.lua"))()

-- / Services
local HttpService = game:GetService("HttpService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- / Environment
local LocalPlayer: Player = Players.LocalPlayer
local PlayerGui: PlayerGui = LocalPlayer.PlayerGui
local PreviousExecutions = env.PreviousExecutions

-- / Variables
local Bar = "|"
local CaseId = HttpService:GenerateGUID(false), Bar, os.time(), Bar, LocalPlayer.UserId

-- / Module

local UiLibrary = {}

UiLibrary.__index = UiLibrary

function UiLibrary.new(Title: string)
    assert(typeof(Title) ~= nil, "Argument #1 (title) of Dialogue can not be nil.")
    if not Title then
        Title = "Default Title"
    end

	local Gui: ScreenGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/SodiumBenjahmin420/UiLibrary/refs/heads/Features/Epic"))()

Gui.Name = Gui.Name .. CaseId

    local self = {
        Title = Title,
        Signals = {},
        Case_Id = CaseId,
		Ui = Gui
    }
	local executionId = HttpService:GenerateGUID(false)
	print(executionId)
   task.delay(1,function()
	env.PreviousExecutions[executionId] = {
        gui = self,
        signals = self.Signals
    }
   end)

    local Metatable = setmetatable(self, UiLibrary)

    return Metatable

end

-- / Module Environment
local function Visible(Boolean:boolean)

end

function UiLibrary:SetVisible(Boolean: boolean)
    Visible(Boolean)
end

env.Cleanup = function()
    for ExecutionId, Previous_Execution:PreviousExecution in PreviousExecutions do
		print("cleaning up", ExecutionId)
		Previous_Execution.gui:Destroy()
        for _, Signal:Signal in ipairs(Previous_Execution.signals) do
            Signal:Destroy()
        end
		PreviousExecutions[ExecutionId] = nil
    end
end
env.Cleanup()


return UiLibrary
