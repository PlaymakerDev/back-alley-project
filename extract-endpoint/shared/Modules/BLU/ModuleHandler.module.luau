-- Services
local TestService		= game:GetService("TestService")
local RunService 		= game:GetService("RunService")
local Players 			= game:GetService("Players")
local RS 				= game:GetService("ReplicatedStorage")
local RF 				= game:GetService("ReplicatedFirst")
local SG				= game:GetService("StarterGui")

local SS 				= if RunService:IsServer() then game:GetService("ServerStorage") else nil
local SSS 				= if RunService:IsServer() then game:GetService("ServerScriptService") else nil

local UIS				= if RunService:IsClient() then game:GetService("UserInputService") else nil

-- Module
local ModuleHandler = {}
ModuleHandler.ModulesToRequire = {}
ModuleHandler.RequiredModules = {}
ModuleHandler.DelayedInits = {}
ModuleHandler.InitializeFirst = {}
ModuleHandler.Ready = false
ModuleHandler.InitsRan = false

-- Starting
function ModuleHandler.Start()
	print('-----------------')
	print('Starting modules . . .')
	
	-- Waiting for UI
	if RunService:IsClient() then
		for i, guiObj in pairs(SG:GetDescendants()) do
			while not Players.LocalPlayer.PlayerGui:FindFirstChild(guiObj.Name, true) do
				task.wait()
			end
		end
	end
	
	-- Requiring Shared Modules
	if RF:FindFirstChild("Modules") then
		for i, module in pairs(RF.Modules:GetDescendants()) do
			ModuleHandler.Require(module, true)
		end
	end
	if RS:FindFirstChild("Modules") then
		for i, module in pairs(RS.Modules:GetDescendants()) do
			ModuleHandler.Require(module)
		end
	end
	
	-- Requiring Player Scripts
	if RunService:IsClient() then
		local player = Players.LocalPlayer
		for i, module in pairs(player.PlayerScripts:WaitForChild("Client"):GetDescendants()) do
			ModuleHandler.Require(module)
		end
	end
	
	-- Requiring Server Storage & Server Script Service Modules
	if RunService:IsServer() then
		for i, module in pairs(SSS:WaitForChild("Server"):GetDescendants()) do
			ModuleHandler.Require(module)
		end
		if SS:FindFirstChild("Modules") then
			for i, module in pairs(SS.Modules:GetDescendants()) do
				ModuleHandler.Require(module)
			end
		end
	end
	
	-- Waiting For Completion
	local startTime = os.clock()
	local timeout = 10
	local hasWarned = false
	while #ModuleHandler.ModulesToRequire > 0 do
		task.wait()
		if not hasWarned and os.clock() - startTime >= timeout then
			hasWarned = true
			_G.Warn("The following modules have not yet finished loading after the timeout time:", ModuleHandler.ModulesToRequire, "\nRunning all init functions anyway")
			_G.Warn("Module likely failed to require:", ModuleHandler.ModulesToRequire[#ModuleHandler.ModulesToRequire])
			ModuleHandler.RunInits()
		end
	end
	
	-- Running Inits
	ModuleHandler.RunInits()
	
	-- Connecting Built-In Events
	ModuleHandler.SetUpEvents()
	
	print('Modules ready')
	print('-----------------')
	ModuleHandler.Ready = true
end

-- Connecting Built-In Events
function ModuleHandler.SetUpEvents()
	
	-- [[ SHARED EVENTS ]] --
	
	-- Player Added
	local charConnects = {}
	local function playerAdded(player)
		
		-- Calling Functions
		ModuleHandler.CallEventFunctions("__PlayerAdded", player)
		
		-- Character Added
		local function charAdded(char)
			
			-- Calling Functions
			local hum = char:WaitForChild("Humanoid")
			local root = char:WaitForChild("HumanoidRootPart")
			
			if RunService:IsClient() and char == Players.LocalPlayer.Character or RunService:IsServer() then
				
				-- Setting up character added an died
				ModuleHandler.CallEventFunctions("__CharacterAdded", char, hum, root)
				ModuleHandler.SetUpIndividualEvent(hum.Died, "__CharacterDied", char)
				
				-- Setting up humanoid events
				ModuleHandler.SetUpMultipleEvents({
					{hum.StateChanged, "__StateChanged"}
				})
				
			end
			
		end
		if player.Character then
			task.spawn(charAdded, player.Character)
		end
		charConnects[player.UserId] = player.CharacterAdded:Connect(charAdded)
		
	end
	for i, player in pairs(Players:GetPlayers()) do
		task.spawn(playerAdded, player)
	end
	Players.PlayerAdded:Connect(playerAdded)
	Players.PlayerRemoving:Connect(function(player)
		if charConnects[player.UserId] then
			charConnects[player.UserId]:Disconnect()
			charConnects[player.UserId] = nil
		end
	end)
	ModuleHandler.SetUpIndividualEvent(Players.PlayerRemoving, "__PlayerRemoving")
	
	-- RunService
	ModuleHandler.SetUpMultipleEvents({
		{RunService.PreSimulation, "__PreSimulation"},
		{RunService.PostSimulation, "__PostSimulation"},
		{RunService.PreAnimation, "__PreAnimation"}
	})
	
	-- [[ LOCALE-SPECIFIC EVENTS ]] --
	
	-- Checking Client-Server
	if RunService:IsServer() then
		
		
	elseif RunService:IsClient() then
		
		-- RunService
		ModuleHandler.SetUpIndividualEvent(RunService.PreRender, "__PreRender")
		
		-- UserInputService
		ModuleHandler.SetUpMultipleEvents({
			{UIS.InputBegan, "__InputBegan"},
			{UIS.InputEnded, "__InputEnded"},
			{UIS.InputChanged, "__InputChanged"},
			{UIS.TouchPan, "__TouchPan"},
			{UIS.TouchStarted, "__TouchStarted"},
			{UIS.TouchEnded, "__TouchEnded"},
			{UIS.JumpRequest, "__JumpRequest"}
		})
		
	end
	
end

-- Setting up specific events
function ModuleHandler.SetUpIndividualEvent(event, callbackName, ...)
	
	-- Finding event functions
	local isFound = false
	for modName, module in pairs(ModuleHandler.RequiredModules) do
		if module[callbackName] then
			isFound = true
			break
		end
	end
	
	-- Connecting event
	if isFound then
		local args = {...}
		event:Connect(function(...)
			
			-- Combining arguments
			local args2 = {...}
			for i, arg in pairs(args) do
				table.insert(args2, 1, arg)
			end
			
			-- Running functions
			ModuleHandler.CallEventFunctions(callbackName, table.unpack(args2))
			
		end)
	end
	
end
function ModuleHandler.SetUpMultipleEvents(argTables)
	for i, args in pairs(argTables) do
		ModuleHandler.SetUpIndividualEvent(table.unpack(args))
	end
end

-- Calling all functions for an event
function ModuleHandler.CallEventFunctions(callbackName, ...)
	for modName, module in pairs(ModuleHandler.RequiredModules) do
		if module[callbackName] then
			task.spawn(module[callbackName], module, ...)
		end
	end
end

-- Requiring
function ModuleHandler.Require(module, initFirst)
	if module.ClassName == "ModuleScript" then
		if module:GetAttribute("Enabled") == false then return end
		
		-- Inserting into list and starting require
		table.insert(ModuleHandler.ModulesToRequire, module)
		task.spawn(function()
			
			-- Requiring
			local success, result = pcall(function() return require(module) end)
			
			if success then
				print("✔️ Module loaded: " .. module.Name, result)
				local mod = result
				table.remove(ModuleHandler.ModulesToRequire, table.find(ModuleHandler.ModulesToRequire, module))
				ModuleHandler.RequiredModules[module.Name] = mod
				if mod.__init then
					if initFirst then
						ModuleHandler.InitializeFirst[module.Name] = mod.__init
					else
						ModuleHandler.DelayedInits[module.Name] = mod.__init
					end
				end
			else
				error("Failed to load module: " .. module.Name .. "\nError: " .. result)
			end
			
		end)
		
	end
end

-- Running Initialization Functions
function ModuleHandler.RunInits()
	if ModuleHandler.InitsRan then return end
	ModuleHandler.InitsRan = true
	
	-- Initializing First
	local initializedFirst = {}
	for modName, callback in pairs(ModuleHandler.InitializeFirst) do
		task.spawn(ModuleHandler.RunInit, modName, callback, initializedFirst)
	end
	while #initializedFirst < #ModuleHandler.InitializeFirst do task.wait() end
	
	-- Main initializaiton phase
	local initializedMain = {}
	for modName, callback in pairs(ModuleHandler.DelayedInits) do
		task.spawn(ModuleHandler.RunInit, modName, callback, initializedMain)
	end
	while #initializedMain < #ModuleHandler.DelayedInits do task.wait() end
	
end

-- Initializing a single module
function ModuleHandler.RunInit(modName, callback, completedTable)
	
	-- Timeout Warning
	task.delay(10, function()
		if not table.find(completedTable, modName) then
			_G.Warn("The module " .. modName .. " is taking a long time to complete initialiation, consider looking at the :__init function?")
		end
	end)
	
	-- Initializing
	callback(ModuleHandler.RequiredModules[modName])
	table.insert(completedTable, modName)
	
end

-- Setting Up Custom Require
function _G.Require(modName)
	
	-- Returning Module
	local mods = ModuleHandler.RequiredModules
	if mods[modName] ~= nil then
		return mods[modName]
	else
		
		-- Finding Module
		local hasWarned = false
		local startTime = os.clock()
		while not mods[modName] do
			task.wait()
			if not hasWarned and os.clock() - startTime >= 8 then
				hasWarned = true
				_G.Warn("Infinite yield possible on require of module " .. modName)
			end
		end
		
		-- Returning
		return mods[modName]
		
	end
	
end

-- Warning with traceback
function _G.Warn(...)
	warn(...)
	TestService:Message(debug.traceback())
end

-- Returning
return ModuleHandler