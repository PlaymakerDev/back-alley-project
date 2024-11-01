-- Services
local RunService			= game:GetService("RunService")
local Players				= game:GetService("Players")
local SP					= game:GetService("StarterPlayer")

-- Modules
local Janitor				= _G.Require("Janitor")
local Signal				= _G.Require("Signal")

-- Module
local MovementHandler = {}
MovementHandler.AllHandlers = {}

-- Initializing
function MovementHandler:__init()
	if RunService:IsClient() then
		Signal.ListenRemote("MovementHandler:AdjustMovement", self.AdjustMovement)
		Signal.ListenRemote("MovementHandler:RemoveAdjustments", self.RemoveAdjustments)
		Signal.ListenRemote("MovementHandler:GetWalkSpeed", function()
			local player = Players.LocalPlayer
			local char = player.Character; if not char then return 0 end
			local hum = char:FindFirstChild("Humanoid"); if not hum then return 0 end
			return hum.WalkSpeed
		end)
	end
end

-- Adding adjustment
function MovementHandler.AdjustMovement(char, ...)
	local adjustments = {...}
	
	-- Finding player
	local player = Players:GetPlayerFromCharacter(char)
	if player and RunService:IsServer() then
		Signal.FireClient(player, "MovementHandler:AdjustMovement", char, ...)
	else
		
		-- Adjusting movement
		local handler = MovementHandler.Get(char)
		for i, adjustment in pairs(adjustments) do
			handler:AddAdjustment(table.unpack(adjustment))
		end
		
	end
	
	-- Returning
	return function()
		MovementHandler.RemoveAdjustments(char, table.unpack(adjustments))
	end
	
end

-- Removing adjustments
function MovementHandler.RemoveAdjustments(char, ...)
	
	-- Finding player
	local player = Players:GetPlayerFromCharacter(char)
	if player and RunService:IsServer() then
		Signal.FireClient(player, "MovementHandler:RemoveAdjustments", char, ...)
	else
		
		-- Removing adjustments
		local handler = MovementHandler.Get(char)
		local adjustments = {...}
		
		for i, adjustment in pairs(adjustments) do
			handler:RemoveAdjustment(table.unpack(adjustment))
		end
		
	end
	
end

-- Getting movement handler
function MovementHandler.Get(char)
	if MovementHandler.AllHandlers[char] then
		return MovementHandler.AllHandlers[char]
	else
		return MovementHandler.new(char)
	end
end

-- Creating new handler
function MovementHandler.new(char)
	if MovementHandler.AllHandlers[char] then return MovementHandler.AllHandlers[char] end
	
	-- Character Variables
	local hum = char:WaitForChild("Humanoid")
	
	-- Creating Self
	local self = setmetatable({}, {__index = MovementHandler})
	self.Janitor = Janitor.new()
	self.Character = char
	
	self.BaseWalkSpeed = SP.CharacterWalkSpeed
	self.BaseJump = if SP.CharacterUseJumpPower then SP.CharacterJumpPower else SP.CharacterJumpHeight
	
	self.WalkAdjustments = {
		Set = {};
		Multiply = {};
	}
	self.JumpAdjustments = {
		Set = {};
		Multiply = {};
	}
	
	-- Inserting
	MovementHandler.AllHandlers[char] = self
	
	-- Adding Adjustment From Server
	if RunService:IsClient() then
		self.Janitor:GiveChore(Signal.ListenRemote("MovementHandler:AddAdjustment", function(...)
			self:AddAdjustment(...)
		end))
		self.Janitor:GiveChore(Signal.ListenRemote("MovementHandler:RemoveAdjustment", function(...)
			self:RemoveAdjustment(...)
		end))
	end
	
	-- Updating
	self.Janitor:GiveChore(RunService.PreSimulation:Connect(function()
		if hum:GetState() ~= Enum.HumanoidStateType.Dead then
			self:Update()
		else
			self:Destroy()
		end
	end))
	
	-- Returning
	return self
	
end

-- Adding Adjustment
function MovementHandler:AddAdjustment(adjustName: string, adjustType: string, adjustValue: number, lastTime: number?)
	
	-- Errors
	assert(self[adjustName], adjustName .. " is not a valid adjustment name. Use either 'JumpAdjustments' or 'WalkAdjustments'")
	assert(self[adjustName][adjustType], adjustType .. " is not a valid adjustment type. Use either 'Set' or 'Multiply'")
	assert(typeof(adjustValue) == "number", "The adjustment value must be a number, not " .. typeof(adjustValue))
	
	-- Inserting
	table.insert(self[adjustName][adjustType], adjustValue)
	
	-- Removing
	if lastTime then
		task.delay(lastTime, function()
			self:RemoveAdjustment(adjustName, adjustType, adjustValue)
		end)
	end
	
	-- Returning Remove
	return function()
		self:RemoveAdjustment(adjustName, adjustType, adjustValue)
	end
	
end

-- Removing Adjustment
function MovementHandler:RemoveAdjustment(adjustName, adjustType, adjustValue)
	local found = table.find(self[adjustName][adjustType], adjustValue)
	if found then
		table.remove(self[adjustName][adjustType], found)
	end
end

-- Updating
function MovementHandler:Update()
	
	-- Character Variables
	local hum = self.Character:FindFirstChild("Humanoid"); if not hum then return end
	
	-- Adjusting Walk Speed
	local walkSpeeds = {}
	if #self.WalkAdjustments.Set > 0 then
		table.insert(walkSpeeds, math.min(table.unpack(self.WalkAdjustments.Set)))
	end
	if #self.WalkAdjustments.Multiply > 0 then
		table.insert(walkSpeeds, self.BaseWalkSpeed * math.min(table.unpack(self.WalkAdjustments.Multiply)))
	end
	hum.WalkSpeed = if #walkSpeeds > 0 then math.min(table.unpack(walkSpeeds)) else self.BaseWalkSpeed
	
	-- Adjusting Jump
	local jumpName = if SP.CharacterUseJumpPower then "JumpPower" else "JumpHeight"
	local jumps = {}
	if #self.JumpAdjustments.Set > 0 then
		table.insert(jumps, math.min(table.unpack(self.JumpAdjustments.Set)))
	end
	if #self.JumpAdjustments.Multiply > 0 then
		table.insert(jumps, self.BaseJump * math.min(table.unpack(self.JumpAdjustments.Multiply)))
	end
	hum[jumpName] = if #jumps > 0 then math.min(table.unpack(jumps)) else self.BaseJump
	
end

-- Destroying
function MovementHandler:Destroy()
	self.Janitor:Clean()
	MovementHandler.AllHandlers[self.Character] = nil
end

-- Returning
return MovementHandler