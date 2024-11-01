-- Services

-- Modules
local BanditNPC = _G.Require("BanditNPC")

-- Constants

-- Private Variables

-- Module
local AggressiveNPC = {}
AggressiveNPC.NPCID = "AggressiveNPC"
AggressiveNPC.AllAggressiveNPCs = {}
AggressiveNPC.StrafeDistance = 20
AggressiveNPC.InRangeDistance = 4

AggressiveNPC.AttackCooldown = 1
AggressiveNPC.AttackDamage = 5
setmetatable(AggressiveNPC, {__index = BanditNPC})

-- Instantiating
function AggressiveNPC:new(char: Model)

	-- Creating object
	local npc = BanditNPC.new(self, char)
	setmetatable(npc, {__index = self})

	npc.CurrentTarget = nil

	npc:DetectionLoop(function(...)
		npc:EnemiesDetected(...)
	end, function(...)
		npc:EnemiesNotDetected(...)
	end)

	-- Returning
	self.AllAggressiveNPCs[char] = npc
	npc.Janitor:GiveChore(function() self.AllAggressiveNPC[char] = nil end)
	return npc

end

function AggressiveNPC:EnemiesDetected(enemies: {Model})

	local char: Model = self.Character
	local root: BasePart = char:FindFirstChild("HumanoidRootPart"); if not root then return end

	local enemy: Model = nil
	local enemyDist: number = nil

	for i, eChar in enemies do
		local eRoot: BasePart = eChar:FindFirstChild("HumanoidRootPart"); if not eRoot then continue end
		local dist: number = (root.Position - eRoot.Position).Magnitude

		-- Checking distance
		if enemy == nil or dist < enemyDist then
			enemy = eChar
			enemyDist = dist
		end
	end

	-- Setting target
	self:SetAsTarget(enemy)

end

function AggressiveNPC:EnemiesNotDetected()
	if not self.CurrentTarget then return end

	local eChar: Model = self.CurrentTarget
	local eHum: Humanoid = eChar:FindFirstChild("Humanoid"); if not eHum then return end
	local eRoot: BasePart = eChar:FindFirstChild("HumanoidRootPart"); if not eRoot then return end

	local distance: number = self:CalculateWalkDistance()
	if distance > self.MaxDetectionRadius or eHum == nil or eHum.Health <= 0 then
		-- Ending Chase
		self:RemoveLoop("FollowPart")
		self.CurrentTarget = nil

		-- Return to origin
		self:MoveToLocation(self.OriginalPosition.Position)
		self.Character:PivotTo(self.OriginalPosition)
	end
end

function AggressiveNPC:SetAsTarget(eChar: Model)

	-- Character variable
	local char: Model = self.Character
	local root: BasePart = char:FindFirstChild("HumanoidRootPart"); if not root then return end
	local eRoot: BasePart = eChar:FindFirstChild("HumanoidRootPart"); if not eRoot then return end

	-- Check current target
	if self.CurrentTarget ~= eChar then
		self:FollowPart(eRoot)
		self.CurrentTarget = eChar
	end

	-- Check current distance
	local dist: number = (eRoot.Position - root.Position).Magnitude
	if dist <= self.StrafeDistance then
		self:StrafeToEnemy(eChar)
	end
end

function AggressiveNPC:StrafeToEnemy(eChar: Model)
	print("strafing")
end

-- Do something else here!
function AggressiveNPC:EnemyInRange(eChar: Model)
	self:AttemptAttack(eChar)
end

function AggressiveNPC:AttemptAttack(eChar: Model)
	print("attack")
end

-- Returning
return AggressiveNPC