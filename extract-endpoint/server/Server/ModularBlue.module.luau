-- Services
local Players 						= game:GetService("Players")

-- Modules
local Signal						= _G.Require("Signal")
local ModuleHandler					= _G.Require("ModuleHandler")
local StringUtil					= _G.Require("StringUtil")
local TableUtil						= _G.Require("TableUtil")

-- Module
local ModularBlue = {}
ModularBlue.Ops = {}

-- Initializing
function ModularBlue.__init()
	ModuleHandler.RequiredModules[script.Name] = nil
	
	-- Getting Players
	for i, player in pairs(Players:GetPlayers()) do
		task.spawn(PlayerAdded, player)
	end
	Players.PlayerAdded:Connect(PlayerAdded)
	
	-- Signals
	Signal.ListenRemote("ModularBlue:GetModules", GetModules)
	Signal.ListenRemote("ModularBlue:RunFunction", RunFunction)
	Signal.ListenRemote("ModularBlue:SetProperty", SetProperty)
	
end

-- [[ PRIVATE ]] --

-- Player Added
function PlayerAdded(player)
	if CheckPermissions(player) then
		
		-- Cloning UI
		local gui = script.ModularBlue:Clone()
		gui.Background.Visible = false
		gui.OpenClose.Visible = true
		gui.Parent = player.PlayerGui
		
		-- Starting Client
		Signal.FireClient(player, "ModularBlue:StartClient")
		
	else
		Signal.FireClient(player, "ModularBlue:Destroy")
	end
end

-- Getting Arguments
function GetArguments(player, argsText)
	
	-- Finding String Arguments
	local args = argsText:split(" ")
	
	-- Converting Strings
	local convertedArgs = {}
	for i, argString in pairs(args) do
		if not argString then continue end
		
		-- Global variables
		if argString == "_Player" then
			table.insert(convertedArgs, player)
			continue
		elseif argString == "_Character" then
			table.insert(convertedArgs, player.Character)
			continue
		end
		
		-- Inserting Argument
		local success, result = pcall(StringUtil.ConvertString, argString)
		local arg = nil
		if success then
			arg = result
		else
			return false, result
		end
		table.insert(convertedArgs, arg)
		
	end
	
	-- Returning
	return true, convertedArgs
	
end

-- Running Module Function
function RunFunction(player, modName, funcName, argsT)
	if not CheckPermissionsWithBan(player) then return end
	
	-- Function Variables
	local module = ModuleHandler.RequiredModules[modName] if not module then return false, "No module found by the name " .. modName end
	local func = module[funcName]; if not func then return false, "No function found by the name " .. funcName end
	local argsFound, argsResult = GetArguments(player, argsT); if not argsFound then return false, argsResult end
	local args = argsResult
	
	-- Running Function
	local success, result = pcall(function()
		func(table.unpack(args))
	end)
	
	-- Returning
	return success, result
	
end

-- Setting Module Property
function SetProperty(player, modName, propPath, toSetT)
	if not CheckPermissionsWithBan(player) then return end
	
	-- Getting variables
	local path = propPath:split(".")
	local parentTable = ModuleHandler.RequiredModules[modName] if not parentTable then return false, "No module found by the name " .. modName end
	local sSuccess, sResult = pcall(StringUtil.ConvertString, toSetT); if not sSuccess then return false, sResult end
	local toSet = sResult
	
	-- Setting property
	for i, index in pairs(path) do
		index = StringUtil.ConvertString(index)
		if i == #path then
			
			-- Setting Value
			local success, result = pcall(function()
				parentTable[index] = toSet
			end)
			if not success then
				return false, result
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
	
	-- Returning
	return true
	
end

-- Getting Modules Information
function GetModules(player)
	if not CheckPermissionsWithBan(player) then return end
	
	-- Returning
	local clone = TableUtil.DeepCopy(ModuleHandler.RequiredModules)
	for modName, module in pairs(clone) do
		for propName, value in pairs(module) do
			if typeof(value) == "function" then
				module[propName] = "ModularBlueIsAFunction"
			end
		end
	end
	return clone
	
end

-- Checking Permissions With Ban
function CheckPermissionsWithBan(player)
	if CheckPermissions(player) then
		return true
	else
		player:Kick("Something went wrong. Something went wrong alright.") -- TODO: implement ban
		return false
	end
end

-- Checking Permissions
function CheckPermissions(player)
	if table.find(ModularBlue.Ops, player.UserId) then
		return true
	else
		return false
	end
end

-- Returning
return ModularBlue