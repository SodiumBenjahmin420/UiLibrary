--!nocheck

-- / Init

loadstring(game:HttpGet("https://raw.githubusercontent.com/SodiumBenjahmin420/UiLibrary/refs/heads/Features/Modules/Utils.lua"))()

-- / Global

local env = getgenv()

env.GlobalSixpineData = {
    ["Version"] = 'Dev_Build.1';
    ["Title"] = 'CommandRoot';
}

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

type FillAfterType = "Players" | "String" -- will add more, but for now players will need to predict users or overalls (the overalls would be "all" "others" "me" "random")

type Command = {
    Description: string,
    FillAfterType: FillAfterType | nil,
    Callback: Function
}

type CommandList = { [string]: Command }

-- / Modules
local Signal = require("Signal")
local Gossamer = require("Gossamer")
local Spr = require("Spr")

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

--ClonedRefs

-- / Variables
local Bar = " | "
local executionId = HttpService:GenerateGUID(false)
local CaseId = executionId .. Bar .. os.time() .. Bar .. LocalPlayer.UserId
local Default_Keybind = KeyCode.Space
local Default_ModifierBind = KeyCode.LeftControl
local Active_Keybind = Default_Keybind
local Active_ModifierBind = Default_ModifierBind
local FADE_DAMPENER = 1
local MOVE_DAMPENER = 0.8
local FADE_FREQUENCY = 2
local POP_DAMPENER = 0.9
local POP_FREQUENCY = 3
local PredictedCommand
local FinalCommand
local FinalArg
local PredictedCommand_StringValue = Instance.new("StringValue")
local SearchImageId = 'rbxassetid://14942740976'
local NoSearchImageId = 'rbxassetid://15197361635'
local LineImageId = 'rbxassetid://15084014255'

-- / Module
local UiLibrary = {}
UiLibrary.__index = UiLibrary

local DefaultCommands: CommandList = {

    ["print"]= {
        Description = "Prints String: (Arg)";
        FillAfterType = "String";
        Callback = function(ToPrint:string)
            if  typeof(ToPrint) ~= "string" or typeof(ToPrint) == "nil" then
                ToPrint = "Printed From: " .. GlobalSixpineData.Title .. Bar .. GlobalSixpineData.Version .. Bar .. CaseId
            end
            if ToPrint == string.lower("diagnostics") then
                local First_Sequence = executionId .. Bar .. "Diagnosing . . ."

            end
            print(ToPrint)
        end
},
    
}

function UiLibrary.new(Title: string,Commands: CommandList)
    if env.Cleanup then
        env.Cleanup()
    end

    if not Title then
		Title = env.GlobalSixpineData.Title
    end

    -- combine default commands and command table (IF APPLICABLE TO COMMAND TABLE ARGUMENT DUE TO THEM MIGHT NOT WANTING CUSTOM COMMANDS AT CREATION)
    local CommandList: CommandList = {}
    for k, v in pairs(DefaultCommands) do
        CommandList[k] = v
    end
    if Commands then
        for k, v in pairs(Commands) do
            CommandList[k] = v
        end
    end

    local Gui: ScreenGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/SodiumBenjahmin420/UiLibrary/refs/heads/Features/Main/Gui"))()
    Gui.Name = Gui.Name .. CaseId
    Gui.UiHolder.TitleHolder.Title.Text = Title
    Gui.Enabled = false
    local self = {
        Title = Title,
        Signals = {
            ToggleSignal = Signal.new(),
            CommandSignal = Signal.new(),
        },
        Case_Id = CaseId,
        Ui = Gui,
        CanvasGroup = Gossamer:Create(Gui.UiHolder,1,true),
        Connections = {},
        Commands = CommandList
    }
    
    -- Store both signals and connections in PreviousExecutions
    PreviousExecutions[executionId] = {
        gui = Gui,
        signals = self.Signals,
        connections = self.Connections
    }

    self.Signals.ToggleSignal:Connect(function(Boolean:boolean)
        DetermineToggle(Boolean)
    end)

    self.Connections.CommandBoxChangedConnection = self.Ui.UiHolder.CommandBox:GetPropertyChangedSignal("Text"):Connect(function()
        local Text: string = self.Ui.UiHolder.CommandBox.Text
        local AutoComplete: TextLabel = self.Ui.UiHolder.AutoComplete
        local SearchIcon:ImageLabel = self.Ui.UiHolder.SearchIcon

        -- Get prediction first without player list
        local prediction, command, needsPlayerPrediction, isShorthanded = predictCommand(Text, self.Commands)
        
        -- Extract the command part from user input
        local userCommandPart = Text:match("^(%S+)")
        
        -- Check if there's a space after the command (indicating argument entry has started)
        local hasStartedArgument = Text:match("%S%s+") ~= nil
        
        -- Only fetch and process players if we need to
        if needsPlayerPrediction and command and command.FillAfterType == "Players" then
            local playerList = Players:GetPlayers()
            local inputArg = Text:match("%s+(.*)$") or ""
            
            -- Find matching player
            local foundMatch = false
            for _, player in ipairs(playerList) do
                if player.Name:lower():sub(1, #inputArg) == inputArg:lower() then
                    prediction = userCommandPart .. " " .. player.Name
                    FinalArg = player.Name
                    foundMatch = true
                    break
                end
            end
            
            -- If no match found, default to "me"
            if not foundMatch then
                prediction = userCommandPart .. " me"
                FinalArg = LocalPlayer.Name
            end
        elseif command then
            -- Set default argument based on FillAfterType
            if command.FillAfterType == "Players" then
                FinalArg = LocalPlayer.Name
            end
        end
        
        if prediction then
            SearchIcon.Image = SearchImageId
            if isShorthanded and hasStartedArgument then
                AutoComplete.Text = Text
            else
                AutoComplete.Text = prediction
            end
            PredictedCommand = command
            PredictedCommand_StringValue.Value = prediction
            FinalCommand = command
            -- Only modify FinalArg if it's a player command
            if command.FillAfterType == "Players" then
                FinalArg = LocalPlayer.Name -- Default to "me"
            end
        elseif Text == "" or Text == " " then
            SearchIcon.Image = LineImageId
            AutoComplete.Text = " Enter Command"
            PredictedCommand = nil
            PredictedCommand_StringValue.Value = ""
            FinalCommand = nil
            FinalArg = nil
        else
            SearchIcon.Image = NoSearchImageId
            AutoComplete.Text = ""
            PredictedCommand = nil
            PredictedCommand_StringValue.Value = ""
            FinalCommand = nil
            if not command then
                FinalArg = nil
            end
        end
    end)

    self.Signals.CommandSignal:Connect(function()
        if FinalCommand and FinalCommand.Callback then
            if FinalCommand.FillAfterType == "String" then
                local text = self.Ui.UiHolder.CommandBox.Text
                local extractedArg = text:match("%s+(.*)$")
                if extractedArg then
                    extractedArg = extractedArg:gsub("^%s*(.-)%s*$", "%1")
                    FinalArg = tostring(extractedArg)
                end
            end
            FinalCommand.Callback(FinalArg)
        end
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

   self.Connections.FocusLostConnection =  Gui.UiHolder.CommandBox.FocusLost:Connect(function()
    self.Signals.CommandSignal:Fire()
    DetermineToggle(false)
   end)

   self.Connections.PredictedCommand_StringValueChanged = PredictedCommand_StringValue:GetPropertyChangedSignal("Value"):Connect(function()
    if isValidCommand(PredictedCommand_StringValue.Value) then
        PopDownAndShowDescription(PredictedCommand_StringValue.Value)
    else
        PopUp()
    end
   end)


    LibraryInstance = setmetatable(self, UiLibrary)
    return LibraryInstance
end

-- / Module Environment

function FocusTextBox()
    local Gui = LibraryInstance.Ui
    local UiHolder = Gui.UiHolder
    local TextBox:TextBox = UiHolder.CommandBox
    TextBox:CaptureFocus()
    task.delay(0.02,function()
        TextBox.Text = ""
    end)
end



function DefaultToggle()
    local Gui = LibraryInstance.Ui
    local MainFrame:Frame = Gui.UiHolder
    local MousePos = UserInputService:GetMouseLocation()
    MainFrame.Position = UDim2.fromOffset(MousePos.X - 6,MousePos.Y)
    local CanvasGroup = LibraryInstance.CanvasGroup
    MainFrame.Rotation = -10
    MainFrame.UIScale.Scale = 1.1
    Gui.Enabled = true
    FocusTextBox()
     Spr.target(CanvasGroup,FADE_DAMPENER,FADE_FREQUENCY,{Value = 0})
     Spr.target(MainFrame,MOVE_DAMPENER,FADE_FREQUENCY,{Position = MainFrame.Position - UDim2.fromOffset(0,36), Rotation = 0})
     Spr.target(MainFrame.UIScale,MOVE_DAMPENER,FADE_FREQUENCY,{Scale = 1})
end 

function DefaultUntoggle()
    ContextActionService:UnbindAction("BlockJumpAndToggle")
    local Gui = LibraryInstance.Ui
    local CanvasGroup = LibraryInstance.CanvasGroup
    local MainFrame:Frame = Gui.UiHolder
     Spr.target(CanvasGroup,FADE_DAMPENER,FADE_FREQUENCY,{Value = 1})
     Spr.target(MainFrame,MOVE_DAMPENER,FADE_FREQUENCY,{Position = MainFrame.Position + UDim2.fromOffset(0,36)})
     Spr.completed(CanvasGroup,function()
        if CanvasGroup.Value == 1 then
            Gui.Enabled = false
        end
     end)

end

function DetermineToggle(Boolean:boolean)
    if typeof(Boolean) == "boolean" then
        if Boolean then
            DefaultToggle()
            env.GlobalActive = true
        else
            DefaultUntoggle()
            env.GlobalActive = false
        end
    else
         if env.GlobalActive then
            DefaultToggle()
            env.GlobalActive = true
         else
            DefaultUntoggle()
            env.GlobalActive = false
         end
    end
end

function UpdateTitle()
    LibraryInstance.Ui.UiHolder.TitleHolder.Title.Text = LibraryInstance.Title
end

function predictCommand(text: string, commands: {[string]: Command})
    local input = text:lower():gsub("^%s*(.-)%s*$", "%1")
    if input == "" then return nil, nil, false, false end
    
    local commandPart, argPart = input:match("^(%S+)%s*(.*)$")
    if not commandPart then commandPart = input end
    
    local matchedCommand, matchedName, originalName
    local isShorthanded = false
    
    for name, command in pairs(commands) do
        if name:lower():sub(1, #commandPart) == commandPart then
            matchedCommand = command
            matchedName = name:lower()
            originalName = name:sub(1,1):upper() .. name:sub(2):lower()
            if commandPart:lower() ~= name:lower() then
                isShorthanded = true
            end
            break
        end
    end
    
    if not matchedCommand then return nil, nil, false, false end
    
    local isOnArgument = text:match("%S%s+$") ~= nil
    
    if matchedCommand.FillAfterType and isOnArgument then
        local userArg = text:match("%s+(.*)$") or ""
        userArg = userArg:gsub("^%s*(.-)%s*$", "%1")
        
        return originalName .. " " .. userArg, matchedCommand, true, isShorthanded
    end
    
    if matchedCommand.FillAfterType and not isOnArgument then
        if matchedCommand.FillAfterType == "Players" then
            return originalName .. " me", matchedCommand, false, isShorthanded
        elseif matchedCommand.FillAfterType == "String" then
            return originalName .. " ", matchedCommand, false, isShorthanded
        end
    end
    
    return originalName, matchedCommand, false, isShorthanded
end

function printTable(t, indent)
    indent = indent or ""
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(indent .. tostring(k) .. ":")
            printTable(v, indent .. "  ")
        else
            print(indent .. tostring(k) .. ": " .. tostring(v))
        end
    end
end

function isValidCommand(PotentialCommandName: string)
    assert(typeof(PotentialCommandName) == "string", "Argument of IsValidCommand Func must be a string")
    
    local commandPart = PotentialCommandName:match("^(%S+)")
    if not commandPart then return false end
    
    local commandLower = commandPart:lower()
    

    for commandName, _ in pairs(LibraryInstance.Commands) do
        if commandName:lower():sub(1, #commandLower) == commandLower then
            return true
        end
    end
    
    return false
end

function PopDownAndShowDescription(CommandName)
    assert(typeof(CommandName) == "string", "Argument of IsValidCommand Func can not be "..typeof(CommandName).. " And must be a string")
    local Gui = LibraryInstance.Ui
    local UiHolder = Gui.UiHolder
    local Pattern = UiHolder.Pattern
    local DescriptionHolder = Pattern.DescriptionHolder
    local Description = DescriptionHolder.Description
    Description.Text = ""
    Spr.target(Pattern,POP_DAMPENER,POP_FREQUENCY,{Size = UDim2.new(1,1,2.5,1)})
    DescriptionHolder.Visible = true
    local commandPart = CommandName:match("^(%S+)")
    if not commandPart then return false end
    
    local commandLower = commandPart:lower()
    
    for commandName, Command in pairs(LibraryInstance.Commands) do
        if commandName:lower() == commandLower then
            Description.Text = Command.Description
            return
        end
    end
return
end

function PopUp()
    local Gui = LibraryInstance.Ui
    local UiHolder = Gui.UiHolder
    local Pattern = UiHolder.Pattern
    local DescriptionHolder = Pattern.DescriptionHolder
    local Description = DescriptionHolder.Description
    Description.Text = ""
    DescriptionHolder.Visible = false
    Spr.target(Pattern,POP_DAMPENER,POP_FREQUENCY,{Size = UDim2.new(1,1,1,1)})
end

function UiLibrary:ChangeBinds(Keybind:Enum.KeyCode, ModifierBind:Enum.KeyCode)
    Active_Keybind = Keybind or Default_Keybind
    Active_ModifierBind = ModifierBind or Default_ModifierBind
end

function UiLibrary:Toggle(Boolean:boolean)
    self.Signals.ToggleSignal:Fire(Boolean or not env.GlobalActive)
end

function UiLibrary:ChangeTitle(Title:string)
    LibraryInstance.Title = Title
    UpdateTitle()
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
    
    print("Cleanup complete")
end

return UiLibrary
