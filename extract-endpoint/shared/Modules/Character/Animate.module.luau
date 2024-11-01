-- Services
local RunService								= game:GetService("RunService")
local Players									= game:GetService("Players")

-- Modules
local Janitor									= _G.Require("Janitor")
local AnimationPack_Default						= _G.Require("AnimationPack_Default")

-- Constants
local DEFAULT_ANIMATIONS 						= AnimationPack_Default
local LOOPED_ANIMATIONS 						= {"Idle", "Walk", "Run", "Fall", "Climb", "Sit"}
local NO_LOOPED_ANIMATIONS						= {"Landed", "Jump"}

local WALK_SPEED								= 6
local RUN_SPEED									= 16

-- Module
local Animate = {}
Animate.AllAnimates 							= {}

-- Initializing for player characters
--function Animate:__CharacterAdded(char: Model, hum: Humanoid, root: BasePart)
--	if RunService:IsClient() then
--		Animate.new(char)
--	end
--end

-- Removing upon character death
function Animate:__CharacterDied(char: Model)
	if RunService:IsClient() then
		local animate = Animate.AllAnimates[char]
		if animate then
			animate:Destroy()
		end
	end
end

-- Switching animate
function Animate.SwitchAnimate(char: Model, animatePath: string)
	local animate = Animate.AllAnimates[char]
	if animate then
		
		-- Finding animation pack
		local modName = "AnimationPack"
		local splitPath = animatePath:split(".")
		for i, index in pairs(splitPath) do
			modName ..= "_" .. index
		end
		local packModule = _G.Require(modName)
		
		-- Loading layer
		local unLoad = animate:LoadLayer(packModule, animatePath)
		return unLoad
		
	else
		NoAnimate(char)
	end
end

-- Playing a specific animation
function Animate.PlayAnimation(char: Model, animName: string, ...)
	local animate = Animate.AllAnimates[char]
	if animate then
		
		-- Finding animation
		local animations = animate:GetAnimations()
		local anim = animations[animName]
		assert(anim, "No animation was found by the name " .. animName)
		
		-- Playing animation
		table.insert(animate.OverlayAnimations, anim)
		anim.Priority = Enum.AnimationPriority.Action
		anim:Play(...)
		
		-- Removing from overlay
		local connection = nil
		connection = anim.Ended:Connect(function()
			connection:Disconnect()
			anim.Priority = Enum.AnimationPriority.Core
			local found = table.find(animate.OverlayAnimations, anim)
			if found then
				table.remove(animate.OverlayAnimations, found)
			end
		end)
		
		-- Returning animation
		return anim
		
	else
		NoAnimate(char)
	end
end

-- Getting specific animation track
function Animate.GetAnimationTrack(char: Model, animName: string)
	local animate = Animate.AllAnimates[char]
	if animate then
		
		-- Finding animation
		local animations = animate:GetAnimations()
		local anim = animations[animName]
		
		-- Returning
		return anim
		
	else
		NoAnimate(char)
	end
end

-- Instantiating
function Animate.new(char: Model)
	
	-- Clearing animate script
	if char:FindFirstChild("Animate") then
		char.Animate:Destroy()
	end
	
	-- Creating self
	local self = setmetatable({}, {__index = Animate})
	self.Player = Players:GetPlayerFromCharacter(char)
	self.Character = char
	
	-- Janitors
	self.Janitor = Janitor.new()
	
	-- Main properties
	self.BaseAnimations = {}; self:LoadAnimations(nil, nil, nil, "Base_")
	self.AnimationLayers = {}; self.Janitor:GiveChore(function() self:ClearLayers() end)
	self.OverlayAnimations = {}
	
	-- Starting loops
	self:StartStateTracking()
	
	-- Returning
	Animate.AllAnimates[char] = self
	return self
	
end

-- Creating a new animation layer
function Animate:LoadLayer(animations: {[string]: string}, layerName: string?)
	
	-- Validating animations
	for animName, animId in pairs(animations) do
		assert(self.BaseAnimations[animName], "The animation " .. animName .. " was not a valid animation name")
	end
	
	-- Creating layer
	local layer = {
		Animations = {};
		Janitor = Janitor.new();
		Name = layerName or "Layer"
	}
	
	-- Loading animations
	self:LoadAnimations(animations, layer.Animations, layer.Janitor, layer.Name .. "_")
	
	-- Inserting layer
	table.insert(self.AnimationLayers, layer)
	layer.Janitor:GiveChore(function()
		for animName, anim in pairs(layer.Animations) do
			anim:Stop()
		end
	end)
	layer.Janitor:GiveChore(function()
		local found = table.find(self.AnimationLayers, layer)
		if found then
			table.remove(self.AnimationLayers, found)
		end
	end)
	
	-- Returning remove function
	return function()
		layer.Janitor:Clean()
	end
	
end

-- Loading base animations
function Animate:LoadAnimations(animations: {[string]: string}?, insertTable: {[string]: AnimationTrack}?, janitor: {}?, namePrefix: string?)
	animations = animations or DEFAULT_ANIMATIONS
	insertTable = insertTable or self.BaseAnimations
	janitor = janitor or self.Janitor
	namePrefix = namePrefix or ""
	
	-- Loading new animations
	local hum = self.Character.Humanoid
	for animName, animId in pairs(animations) do
		
		-- Creating animation
		local anim = Instance.new("Animation"); janitor:GiveChore(anim)
		anim.AnimationId = animId
		anim.Name = namePrefix .. animName
		
		-- Clearing previous animation object
		if insertTable[animName] then
			insertTable[animName]:Destroy()
		end
		
		-- Loading new animation
		local loaded = hum.Animator:LoadAnimation(anim); janitor:GiveChore(loaded)
		loaded.Priority = if table.find(NO_LOOPED_ANIMATIONS, animName) then Enum.AnimationPriority.Movement
			else Enum.AnimationPriority.Core
		insertTable[animName] = loaded
		
	end
	
end

-- Cleaning layers
function Animate:ClearLayers()
	for i, layer in pairs(self.AnimationLayers) do
		layer.Janitor:Clean()
	end
end

-- Get current animations
function Animate:GetAnimations(): ({[string]: AnimationTrack})
	
	-- Piling together the highest layers
	local animations = {}
	for i = #self.AnimationLayers, 1, -1 do
		local layer = self.AnimationLayers[i]
		for animName, anim in pairs(layer.Animations) do
			if animations[animName] == nil then
				animations[animName] = anim
			end
		end
	end
	
	-- Defaulting to base animations if not found
	for animName, anim in pairs(self.BaseAnimations) do
		if animations[animName] == nil then
			animations[animName] = anim
		end
	end
	
	-- Returning
	return animations
	
end

-- Starting state tracking loop
function Animate:StartStateTracking()
	
	-- Starting loop
	self.Janitor:GiveChore(RunService.Stepped:Connect(function() self:UpdateState() end))
	
end

-- Updating current state
function Animate:UpdateState()
	
	-- Character variables
	local hum = self.Character.Humanoid
	
	-- Checking states
	local state = hum:GetState()
	if state == Enum.HumanoidStateType.Seated then
		self:ChangeAnimation("Sit")
	elseif state == Enum.HumanoidStateType.Jumping then
		self:ChangeAnimation("Jump")
	elseif state == Enum.HumanoidStateType.Landed then
		local animations = self:GetAnimations()
		for i, anim in animations do
			anim:Stop()
		end
	--	self:ChangeAnimation("Landed")
	elseif state == Enum.HumanoidStateType.Freefall then
		self:ChangeAnimation("Fall", 0.25)
	elseif state == Enum.HumanoidStateType.Climbing then
		self:ChangeAnimation("Climb")
	elseif state == Enum.HumanoidStateType.Running then
		
		-- Checking movement
		local moveDirection = if RunService:IsServer() then self.Character:GetAttribute("MoveDirection")
			elseif RunService:IsClient() then hum.MoveDirection
			else nil
		if moveDirection.Magnitude > 0 and hum.WalkSpeed > 1 then
			if hum.WalkSpeed >= RUN_SPEED then
				self:ChangeAnimation("Run")
			else
				self:ChangeAnimation("Walk")
			end
		else
			self:ChangeAnimation("Idle")
		end
		
	end
	
end

-- Changing the current playing animation
function Animate:ChangeAnimation(newAnim: string, ...)
	
	-- Character variables & other
	local hum = self.Character.Humanoid
	local round = 1000
	
	-- Finding animation
	local animations = self:GetAnimations()
	local goalAnim = animations[newAnim]
	
	-- Stopping previous animations
	for i, layer in pairs(self.AnimationLayers) do
		for animName, anim in pairs(layer.Animations) do
			if anim == goalAnim or table.find(self.OverlayAnimations, anim) or table.find(NO_LOOPED_ANIMATIONS, animName) then continue end
			anim:Stop()
		end
	end
	for animName, anim in pairs(self.BaseAnimations) do
		if anim == goalAnim or table.find(self.OverlayAnimations, anim) or table.find(NO_LOOPED_ANIMATIONS, animName) then continue end
		anim:Stop()
	end
	
	-- Playing animation
	if not goalAnim.IsPlaying then
		goalAnim:Play(...)
	end
	
	-- Calculating animation speed
	local goalSpeed = 1
	if newAnim == "Run" then
		goalSpeed = hum.WalkSpeed / RUN_SPEED
	elseif newAnim == "Walk" then
		goalSpeed = hum.WalkSpeed / WALK_SPEED
	end
	goalSpeed = math.round(goalSpeed * round) / round
	
	-- Adjusting animation speed
	if math.round(goalAnim.Speed * round) / round ~= goalSpeed then
		goalAnim:AdjustSpeed(goalSpeed)
	end
	
end

-- Destroying
function Animate:Destroy()
	Animate.AllAnimates[self.Character] = nil
	self.Janitor:Clean()
end

--[[ PRIVATE ]]--

-- No animate found error
function NoAnimate(char)
	error("No animate was found for " .. char.Name)
end

-- Returning
return Animate