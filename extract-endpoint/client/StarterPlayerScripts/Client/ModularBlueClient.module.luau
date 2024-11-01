-- Services
local Players						= game:GetService("Players")
local UIS							= game:GetService("UserInputService")
local HS							= game:GetService("HttpService")

-- Modules
local Signal						= _G.Require("Signal")
local ModuleHandler					= _G.Require("ModuleHandler")
local StringUtil					= _G.Require("StringUtil")

-- Player Variables
local player						= Players.LocalPlayer
local char							= nil
local hum							= nil
local root							= nil

local playerGui 					= player.PlayerGui

-- Gui Variables
local gui							= nil
local backF							= nil
local outputF						= nil
local modulesF						= nil
local homeF							= nil

local functionsF					= nil
local propertiesF					= nil

local openB							= nil
local clientServerB					= nil
local funcRunB						= nil
local propSetB						= nil

local funcSample					= nil
local moduleSample					= nil
local propSample					= nil

local errorSample					= nil
local warnSample					= nil
local printSample					= nil

local funcArgsT						= nil
local propSetT						= nil

-- Constants
local OPEN_POS						= nil
local CLOSE_POS						= nil

local BLUE							= Color3.fromRGB(100, 200, 255)
local GREEN							= Color3.fromRGB(150, 255, 150)
local WHITE							= Color3.new(1, 1, 1)
local BLACK							= Color3.new(0, 0, 0)

-- Module
local MBClient = {}

-- Character Added
function MBClient.__CharacterAdded(_char, _hum, _root)
	char, hum, root = _char, _hum, _root
end

-- Character Died
function MBClient.__CharacterDied()
	char, hum, root = nil, nil, nil
end

-- Initializing
function MBClient.__init()
	
	-- Removing
	ModuleHandler.RequiredModules[script.Name] = nil
	
	-- Starting
	Signal.ListenRemote("ModularBlue:StartClient", Start)
	Signal.ListenRemote("ModularBlue:Destroy", function()
		script:Destroy()
	end)
	
end

-- [[ PRIVATE ]] --

-- Update UI Variables
function UpdateUIVariables()
	
	-- Gathering UI Variables
	gui 			= playerGui.ModularBlue
	backF			= gui.Background; backF.Visible = false
	outputF			= backF.OutputOutline.Output
	modulesF		= backF.ModulesOutline.Modules
	homeF			= backF.MainOutline.Main.Home
	
	functionsF		= homeF.Functions
	propertiesF		= homeF.Properties
	
	openB			= gui.OpenClose
	clientServerB	= homeF.ClientServer
	funcRunB		= functionsF.Run
	propSetB		= propertiesF.Run
	
	funcSample		= functionsF.ScrollingFrame.Sample; funcSample.Visible = false
	moduleSample	= modulesF.ScrollingFrame.Sample; moduleSample.Visible = false
	propSample		= propertiesF.ScrollingFrame.Sample; propSample.Visible = false
	
	errorSample		= outputF.ScrollingFrame.ErrorSample; errorSample.Visible = false
	warnSample		= outputF.ScrollingFrame.WarnSample; warnSample.Visible = false
	printSample		= outputF.ScrollingFrame.PrintSample; printSample.Visible = false
	
	funcArgsT		= functionsF.Arguments
	propSetT		= propertiesF.ToSet
	
end

-- Updating Constant Variables
function UpdateConstantVariables()
	
	-- Updating Constants
	OPEN_POS 		= backF.Position
	CLOSE_POS 		= OPEN_POS + UDim2.fromScale(0, -1)
	
end

-- Opening
function OpenWindow()
	if MBClient.OpenCloseDB then return end
	MBClient.OpenCloseDB = true
	
	-- Tweening Out
	backF.Position = CLOSE_POS
	backF.Visible = true
	backF:TweenPosition(OPEN_POS, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.5)
	task.wait(0.5)
	
	MBClient.MenuOpen = true
	MBClient.OpenCloseDB = false
end

-- Closing
function CloseWindow()
	if MBClient.OpenCloseDB then return end
	MBClient.OpenCloseDB = true
	
	-- Tweening In
	backF:TweenPosition(CLOSE_POS, Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.5)
	task.wait(0.5)
	backF.Visible = false
	
	MBClient.MenuOpen = false
	MBClient.OpenCloseDB = false
end

-- Toggling window
function ToggleWindow()
	if MBClient.MenuOpen then
		CloseWindow()
	else
		OpenWindow()
	end
end

-- Updating Display
function UpdateDisplay()
	
	-- Update Variables
	MBClient.AllModules = if MBClient.CurrentMode == "Client" then ModuleHandler.RequiredModules
		elseif MBClient.CurrentMode == "Server" then Signal.InvokeServer("ModularBlue:GetModules")
		else nil
	
	-- Clearing Display
	ClearDisplay()
	
	-- Ordering Modules
	local orderedModules = {}
	for modName, module in pairs(MBClient.AllModules) do
		table.insert(orderedModules, modName)
	end
	table.sort(orderedModules, function(a, b)
		return a:lower() < b:lower()
	end)
	
	-- Updating Modules
	for i, modName in pairs(orderedModules) do
		local module = MBClient.AllModules[modName]
		if modName == "ModuleHandler" then continue end
		
		-- Formatting Name
		local index = 0
		local lastWasCap = false
		local formattedName = modName:gsub("%a", function(letter)
			
			-- Getting letter format
			index += 1
			local toReturn = letter
			if letter:upper() == letter and index ~= 1 and not lastWasCap then
				toReturn =  " " .. letter
			end
			
			-- Setting LastWasCap
			if letter:upper() == letter then
				lastWasCap = true
			else
				lastWasCap = false
			end
			
			-- Returning
			return toReturn
			
		end)
		
		-- Creating Module Button
		local modButton = moduleSample:Clone()
		modButton.Text = formattedName
		modButton.Name = modName
		modButton.Parent = moduleSample.Parent
		modButton.Visible = true
		
		-- Connecting Button Press
		modButton.MouseButton1Click:Connect(function()
			SelectModule(modName)
		end)
		
	end
	modulesF.ScrollingFrame.CanvasSize = UDim2.fromOffset(0, modulesF.ScrollingFrame.UIListLayout.AbsoluteContentSize.Y + 20)
	
end

-- Refreshing display
function RefreshDisplay()
	local mod = MBClient.SelectedModule
	local func = MBClient.SelectedFunction
	local prop = MBClient.SelectedProperty
	UpdateDisplay()
	if mod then SelectModule(mod) end
	if func then SelectFunction(func) end
	if prop then SelectProperty(prop) end
end

-- Clearing Display
function ClearDisplay()
	
	-- Clearing Scrolling Frames
	local frameSamplePairs = {
		[modulesF] = moduleSample;
		[functionsF] = funcSample;
		[propertiesF] = propSample;
	}
	for frame, sample in pairs(frameSamplePairs) do
		for i, button in pairs(frame.ScrollingFrame:GetChildren()) do
			if button.ClassName == "TextButton" and button ~= sample then
				button:Destroy()
			end
		end
	end
	
end

-- Selecting Module
function SelectModule(modName)
	UpdateDisplay()
	
	-- Updating selected module
	MBClient.SelectedModule = modName
	MBClient.SelectedFunction = nil
	MBClient.SelectedProperty = nil
	
	-- Updating module button colors
	for i, modButton in pairs(modulesF.ScrollingFrame:GetChildren()) do
		if modButton.ClassName == "TextButton" and modButton ~= moduleSample then
			if modButton.Name == modName then
				modButton.BackgroundColor3 = modButton:GetAttribute("SelectedColor")
			else
				modButton.BackgroundColor3 = modButton:GetAttribute("NormalColor")
			end
		end
	end
	
	--  Updating Functions & Properties
	local module = MBClient.AllModules[modName]
	for name, value in pairs(module) do
		if typeof(value) == "function" or value == "ModularBlueIsAFunction" then
			
			-- Creating Function Button
			local funcButton = funcSample:Clone()
			funcButton.Text = name
			funcButton.Name = name
			funcButton.Parent = funcSample.Parent
			funcButton.Visible = true
			
			-- Button Pressed
			funcButton.MouseButton1Click:Connect(function()
				SelectFunction(name)
			end)
			
		else
			
			-- Creating Property Button
			local function createPropButton(propName, propValue, path)
				
				-- Creating Button
				local propButton = propSample:Clone()
				propButton.Text = propName .. ": " .. typeof(propValue)
				propButton.Name = path or propName
				propButton.Parent = propSample.Parent
				propButton.Visible = true
				
				-- Button Pressed
				propButton.MouseButton1Click:Connect(function()
					SelectProperty(path or propName)
				end)
				
				-- Returning
				return propButton
				
			end
			local propButton = createPropButton(name, value)
			
			-- Configuring tables
			if typeof(value) == "table" then
				
				-- Looping table
				local function loopTable(t, depth, path)
					for k, v in pairs(t) do
						
						-- Creating Button
						local indentation = ""
						for i = 1, depth do
							indentation ..= "|--->"
						end
						local button = createPropButton(indentation .. tostring(k), v, path .. "." .. tostring(k))
						
						-- Looping
						if typeof(v) == "table" then
							loopTable(v, depth + 1, path .. "." .. tostring(k))
						end
						
					end
				end
				loopTable(value, 1, name)
				
			end
			
		end
	end
	
	-- Updating ScrollingFrame sizes
	local funcsList = functionsF.ScrollingFrame.UIListLayout
	local propsList = propertiesF.ScrollingFrame.UIListLayout
	functionsF.ScrollingFrame.CanvasSize = UDim2.fromOffset(0, funcsList.AbsoluteContentSize.Y + 20)
	propertiesF.ScrollingFrame.CanvasSize = UDim2.new(2, 0, 0, propsList.AbsoluteContentSize.Y + 20)
	
end

-- Selecting Property
function SelectProperty(propPath)
	
	-- Updating selected property
	MBClient.SelectedProperty = propPath
	
	-- Updating property button colors
	for i, propButton in pairs(propertiesF.ScrollingFrame:GetChildren()) do
		if propButton.ClassName == "TextButton" and propButton ~= propSample then
			if propButton.Name == propPath then
				propButton.BackgroundColor3 = propButton:GetAttribute("SelectedColor")
			else
				propButton.BackgroundColor3 = propButton:GetAttribute("NormalColor")
			end
		end
	end
	
	-- Updating property value display
	local value = FindValue(propPath)
	propertiesF.CurrentValue.Text = tostring(value)
	
end

-- Selecting Function
function SelectFunction(funcName)
	
	-- Updating selected function
	MBClient.SelectedFunction = funcName
	
	-- Updating function button colors
	for i, funcButton in pairs(functionsF.ScrollingFrame:GetChildren()) do
		if funcButton.ClassName == "TextButton" and funcButton ~= funcSample then
			if funcButton.Name == funcName then
				funcButton.BackgroundColor3 = funcButton:GetAttribute("SelectedColor")
			else
				funcButton.BackgroundColor3 = funcButton:GetAttribute("NormalColor")
			end
		end
	end
	
end

-- Finding Value
function FindValue(propPath)
	
	-- Looping Module
	local obj = MBClient.AllModules[MBClient.SelectedModule]
	local indexes = propPath:split(".")
	
	for i, index in pairs(indexes) do
		local convertedIndex = nil
		
		-- Finding Index
		local success, result = pcall(StringUtil.ConvertString, index)
		if success then
			convertedIndex = result
		else
			OutputMessage("Error", result)
			return
		end
		
		-- Indexing
		if obj[index] then
			obj = obj[index]
		elseif obj[convertedIndex] then
			obj = obj[convertedIndex]
		else
			OutputMessage("Error", "No index " .. index .. " found in value path: " .. propPath)
			return
		end
		
	end
	
	-- Returning
	return obj
	
end

-- Output Messages
function OutputMessage(messageType: string, message: string, textProperties: {})
	textProperties = textProperties or {}
	
	-- Relaying to output window
	local relayAdd = "ModularBlue: "
	if messageType == "Print" then
		print(relayAdd .. message)
	elseif messageType == "Warn" then
		_G.Warn(relayAdd .. message)
	elseif messageType == "Error" then
		pcall(function()
			error(relayAdd .. message)
		end)
	end
	
	-- Adding Message Time
	local t = DateTime.now():ToLocalTime()
	local timeString = "<b>" .. ("%02d:%02d:%02d.%03d"):format(t.Hour, t.Minute, t.Second, t.Millisecond) .. "</b>"
	message = timeString .. ": " .. message
	
	-- Cloning Sample
	local sample = if messageType == "Print" then printSample
		elseif messageType == "Error" then errorSample
		elseif messageType == "Warn" then warnSample
		else printSample
	local clone = sample:Clone()
	
	-- Adjusting Properties
	for k, v in pairs(textProperties) do
		clone[k] = v
	end
	
	-- Adjusting Message
	clone.Text = message
	clone.Size = sample.Size + UDim2.fromOffset(0, math.floor(message:len() / 60) * sample.Size.Y.Offset)
	
	-- Sending Message
	clone.Parent = sample.Parent
	clone.Visible = true
	
	-- Adjusting Canvas Size
	outputF.ScrollingFrame.CanvasSize = UDim2.new(2, 0, 0, outputF.ScrollingFrame.UIListLayout.AbsoluteContentSize.Y + 20)
	
	-- Traceback
	if messageType == "Error" then
		OutputMessage("Print", debug.traceback(), {
			TextColor3 = BLUE;
		})
	end
	
end

-- Clearing Output
function ClearOutput()
	for i, child in pairs(outputF.ScrollingFrame:GetChildren()) do
		if child.ClassName == "TextLabel" and not table.find({errorSample, printSample, warnSample}, child) then
			child:Destroy()
		end
	end
	outputF.ScrollingFrame.CanvasSize = UDim2.new()
end

-- Getting Current Module
function GetCurrentModule()
	
	-- Finding Module
	if not MBClient.SelectedModule then return end
	local module = MBClient.AllModules[MBClient.SelectedModule]; if not module then return end
	
	-- Returning
	return module
	
end

-- Getting Arguments
function GetArguments()
	
	-- Finding String Arguments
	local argsText = funcArgsT.Text
	local args = argsText:split(" ")
	
	-- Converting Strings
	local convertedArgs = {}
	for i, argString in pairs(args) do
		if not argString then continue end
		
		-- Inserting Argument
		local success, result = pcall(StringUtil.ConvertString, argString)
		local arg = nil
		if success then
			arg = result
		else
			OutputMessage("Error", result)
			return
		end
		
		table.insert(convertedArgs, arg)
		
	end
	
	-- Returning
	return convertedArgs
	
end

-- Running Function
function RunFunction()
	
	-- Function Variables
	local module = GetCurrentModule(); if not module then return end
	if not MBClient.SelectedFunction then return end
	local func = module[MBClient.SelectedFunction]; if not func then return end
	
	-- Checking Client-Server
	local success, result
	if MBClient.CurrentMode == "Client" then
		
		-- Running Function
		local args = GetArguments()
		success, result = pcall(function()
			func(table.unpack(args))
		end)
		
	elseif MBClient.CurrentMode == "Server" then
		
		-- Running Function
		success, result = Signal.InvokeServer("ModularBlue:RunFunction", MBClient.SelectedModule, MBClient.SelectedFunction, funcArgsT.Text)
		
	end
	
	-- Result
	if success and result and tostring(result) then
		OutputMessage("Print", tostring(result))
	elseif not success then
		OutputMessage("Error", result or "Is no ModularBlue mode currently selected?")
	end
	
	-- Updating Display & Reselecting
	RefreshDisplay()
	
end

-- Setting Properties
function SetProperty()
	
	-- Property Variables
	local module = GetCurrentModule(); if not module then return end
	if not MBClient.SelectedProperty then return end
	local success, result = pcall(StringUtil.ConvertString, propSetT.Text)
	local toSet = nil
	
	if success then
		toSet = result
	else
		OutputMessage("Error", result)
		return
	end
	
	-- Checking Client/Server
	if MBClient.CurrentMode == "Client" then
		
		-- Setting Property
		local path = MBClient.SelectedProperty:split(".")
		local parentTable = module
		
		for i, index in pairs(path) do
			index = StringUtil.ConvertString(index)
			if i == #path then
				
				-- Setting Value
				local success, result = pcall(function()
					parentTable[index] = toSet
				end)
				if not success then
					OutputMessage("Error", result)
				end
				
			else
				
				-- Indexing
				local success, result = pcall(function()
					parentTable = parentTable[index]
				end)
				if not success then
					return false, result
				end
				
			end
		end
		
	elseif MBClient.CurrentMode == "Server" then
		
		-- Invoking server
		local success, result = Signal.InvokeServer("ModularBlue:SetProperty", MBClient.SelectedModule, MBClient.SelectedProperty, propSetT.Text)
		if not success then
			OutputMessage("Error", result)
			return
		end
		
	end
	
	-- Updating Display & Reselecting
	RefreshDisplay()
	
end

-- Swapping Mode
function SwapMode()
	if MBClient.CurrentMode == "Client" then
		MBClient.CurrentMode = "Server"
	elseif MBClient.CurrentMode == "Server" then
		MBClient.CurrentMode = "Client"
	end
	clientServerB.Text = "Mode: " .. MBClient.CurrentMode
	clientServerB.BackgroundColor3 = clientServerB:GetAttribute(MBClient.CurrentMode .. "Color")
	UpdateDisplay()
end

-- Input began
function InputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then return end
	
	if input.KeyCode == Enum.KeyCode.L then
		ToggleWindow()
	end
end

-- Starting
function Start()
	
	-- Creating Properties
	MBClient.CurrentMode = "Client"
	MBClient.SelectedModule = nil
	MBClient.SelectedFunction = nil
	MBClient.SelectedProperty = nil
	
	-- Listening to events
	Signal.Listen("ModularBlueClient:OutputMessage", OutputMessage)
	UIS.InputBegan:Connect(InputBegan)
	
	-- Running Initial Methods
	UpdateUIVariables()
	UpdateConstantVariables()
	UpdateDisplay()
	
	-- Connecting Buttons
	openB.MouseButton1Click:Connect(ToggleWindow)
	funcRunB.MouseButton1Click:Connect(RunFunction)
	propSetB.MouseButton1Click:Connect(SetProperty)
	outputF.Parent.Clear.MouseButton1Click:Connect(ClearOutput)
	clientServerB.MouseButton1Click:Connect(SwapMode)
	
	-- Started Text
	OutputMessage("Print", "Modular Blue finished initiating.", {
		TextColor3 = GREEN;
	})
	OutputMessage("Print", "-----------------------", {
		TextColor3 = GREEN;
	})
	
end

-- Returning
return MBClient