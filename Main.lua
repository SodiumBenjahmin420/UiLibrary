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
    signals: {Signal},
    connections: {RBXScriptConnection}  -- New field to track connections
}

-- / Modules
local Signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/Quenty/NevermoreEngine/6ca66a994dba630ad9ac0e2208ac3b8b6630b053/Modules/Events/Signal.lua"))()
local Gossamer = loadstring(game:HttpGet("https://raw.githubusercontent.com/SodiumBenjahmin420/UiLibrary/refs/heads/Features/Gossamer"))()
local Spr = loadstring(game:HttpGet("https://raw.githubusercontent.com/Fraktality/spr/refs/heads/master/spr.lua"))()

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

-- / Module
local UiLibrary = {}
UiLibrary.__index = UiLibrary

function UiLibrary.new(Title: string)
    -- Clean up previous executions before creating new instance
    if env.Cleanup then
        env.Cleanup()
    end

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
        Connections = {}  -- Track connections here
    }
    
    local executionId = HttpService:GenerateGUID(false)
    print("Creating new execution:", executionId)
    
    -- Store both signals and connections in PreviousExecutions
    PreviousExecutions[executionId] = {
        gui = Gui,
        signals = self.Signals,
        connections = self.Connections
    }

    self.Signals.ToggleSignal:Connect(function(Boolean:boolean)
        DetermineToggle(Boolean)
    end)

    -- Store input connections
    self.Connections.began = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        
        if input.KeyCode == Active_ModifierBind then
            ContextActionService:BindAction(
                "BlockJumpAndToggle",
                handleJumpAction,
                false,
                Active_Keybind
            )
        end
    end)

    self.Connections.ended = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        
        if input.KeyCode == Active_ModifierBind then
            ContextActionService:UnbindAction("BlockJumpAndToggle")
            DetermineToggle(false)
        end
    end)

    LibraryInstance = setmetatable(self, UiLibrary)
    return LibraryInstance
end

-- / Module Environment

function DefaultToggle()
    local Gui = LibraryInstance.Ui
    local CanvasGroup = LibraryInstance.CanvasGroup
    local MousePos = UserInputService:GetMouseLocation()
    local MainFrame:Frame = Gui.UiHolder

    MainFrame.Position = UDim2.fromOffset(MousePos.X,MousePos.Y)
    Gui.Enabled = true
     Spr.target(CanvasGroup,1,4,{Value = 0})


end

function DefaultUntoggle()
    local Gui = LibraryInstance.Ui
    local CanvasGroup = LibraryInstance.CanvasGroup
     Spr.target(CanvasGroup,1,4,{Value = 1})
     Spr.Completed(CanvasGroup,function()
        Gui.Enabled = false
     end)

end

function DetermineToggle(Boolean:boolean)
    if typeof(Boolean) == "boolean" then
        if Boolean then
            DefaultToggle()
        else
            DefaultUntoggle()
        end
    else
         if env.GlobalActive then
            DefaultToggle()
         else
            DefaultUntoggle()
         end
    end
end

function UiLibrary:ChangeBinds(Keybind:Enum.KeyCode, ModifierBind:Enum.KeyCode)
    Active_Keybind = Keybind or Default_Keybind
    Active_ModifierBind = ModifierBind or Default_ModifierBind
end

function UiLibrary:Toggle(Boolean:boolean)
    self.Signals.ToggleSignal:Fire(Boolean or not env.GlobalActive)
    env.GlobalActive = not env.GlobalActive
end

function handleJumpAction(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        if not env.GlobalActive then
            LibraryInstance:Toggle(true)
        end
    end
    return Enum.ContextActionResult.Sink
end

-- Cleanup function
env.Cleanup = function()
    ContextActionService:UnbindAction("BlockJumpAndToggle")
    
    for executionId, previousExecution in pairs(PreviousExecutions) do
        print("Cleaning up execution:", executionId)
        
        -- Clean up connections
        if previousExecution.connections then
            for name, connection in pairs(previousExecution.connections) do
                if typeof(connection) == "RBXScriptConnection" and connection.Connected then
                    connection:Disconnect()
                    print("Disconnected connection:", name)
                end
            end
        end
        
        -- Clean up GUI
        if previousExecution.gui then
            previousExecution.gui:Destroy()
            print("Destroyed GUI:", previousExecution.gui.Name)
        end
        
        -- Clean up signals
        if previousExecution.signals then
            for signalName, signal in pairs(previousExecution.signals) do
                signal:Destroy()
                print("Destroyed signal:", signalName)
            end
        end
        
        PreviousExecutions[executionId] = nil
    end
    
    print("Cleanup complete, remaining executions:", table.getn(PreviousExecutions))
end

return UiLibrary
