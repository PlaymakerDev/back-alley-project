-- Services
local PFS = game:GetService("PathfindingService")
local CS = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Modules
local Janitor = _G.Require("Janitor")
local Animate = _G.Require("Animate")
local Types = require(RS.Modules.Infomation.Types)

-- Constants
local NO_Y = Vector3.new(1, 0, 1)

-- Private Variables
local templateF = SS.NPCTemplates

-- Module
local BanditNPC = {}
BanditNPC.NPCID = "BanditNPC"
BanditNPC.AllNPCs = {}

BanditNPC.PathConfiguration = {
	AgentRadius = 2;
}
BanditNPC.FollowDistance = 3
BanditNPC.FollowDistanceMargin = 2
BanditNPC.AlwaysDetectRadius = 10
BanditNPC.MaxDetectionRadius = 50
BanditNPC.DetectionFOV = 75

BanditNPC.DetectPlayers = true
BanditNPC.DetectNPCs = false
BanditNPC.DetectOwnKind = false
BanditNPC.DetectionCooldown = .2

BanditNPC.RespawnEnabled = true
BanditNPC.RespawnTime = 3

function BanditNPC:__init()

	for _, npcModel in CS:GetTagged(self.NPCID) do
		if npcModel:IsDescendantOf(workspace) then
			self:new(npcModel)
		end
	end

end

function BanditNPC:__PostSimulation(dt: number)
	for char, npc in self.AllNPCs do
		npc:OnPostSimulationLoop(dt)
	end
end

-- Instantiating
function BanditNPC:new(char: Model): Types.Bandit

	-- Creating object
	local npc: Types.Bandit = setmetatable({}, {__index = self})
	npc.Janitor = Janitor.new()
	npc.Character = char
	npc.Animate = Animate.new(char) -- need to do animate script first
	npc.Path = PFS:CreatePath(self.PathConfiguration)
	npc.Loops = {}; npc.Janitor:GiveChore(function() table.clear(npc.Loops) end)

	-- Movement Properties
	npc.CurrentPathWaypoints = nil
	npc.CurrentDistination = nil

	-- Memory Properties
	npc.OriginalPosition = char:GetPivot()

	-- Other Janitors
	npc.MoveToJanitor = Janitor.new(); npc.Janitor:GiveChore(npc.MoveToJanitor)

	-- Initializing character
	char:SetAttribute("MoveDirection", Vector3.new()) -- used in Animate to determine walk direction

	for _, part in char:GetDescendants() do
		if part:IsA("BasePart") then
			part:SetNetworkOwner(nil)
		end
	end

	--- Setting up respawn
	local humanoid = char.Humanoid
	humanoid.Died:Connect(function()
		if npc.RespawnEnabled then
			-- delay
			task.wait(npc.RespawnTime)

			-- Create new
			local sample = templateF:FindFirstChild(npc.Character.Name)
			assert(sample, "No template npc was found for NPC model " ..npc.Character.Name)
			local clone = sample:Clone()
			clone.Parent = workspace
			clone:PivotTo(npc.OriginalPosition)
			self:new(clone)

			-- Remove old
			npc:Destroy()
			npc.Character:Destroy()
		end
	end)

	-- Returning
	self.AllNPCs[char] = npc
	npc.Janitor:GiveChore(function() self.AllNPCs[char] = nil end)
	return npc


end

function BanditNPC:OnPostSimulationLoop(dt: number)
	for loopName, loopConfig in self.Loops do
		loopConfig.Callback(dt, loopConfig.Properties)
	end
end

function BanditNPC:ConfigureLoop(
	loopName: string,
	properties: Types.LoopProperties,
	callback: (dt: number, properties: Types.LoopProperties) -> (),
	removeCallback: (Types.LoopProperties) -> ()
)

	local loop: Types.Loop = {
		Properties = properties;
		Callback = callback;
		RemoveCallback = removeCallback;
	}
	self.Loops[loopName] = loop

end

function BanditNPC:RemoveLoop(loopName: string)
	local loop = self.Loops[loopName]; if not loop then return end

	if loop then
		loop:RemoveCallback()
	end
	self.Loops[loopName] = nil
end

function BanditNPC:DetectionLoop(
	detectionCallback: ({Model}) -> (),
	notDetectionCallback: () -> (),
	params: RaycastParams?
)

	self:ConfigureLoop("DetectionLoop",
		{
			DetectionCallback = detectionCallback,
			NotDetectionCallback = notDetectionCallback,
			RaycastParams = params,
			Debounce = false,
		},
		function(dt: number, properties: Types.LoopProperties)
			if properties.Debounce then return end
			properties.Debounce = true

			local allCharacters: {Model} = {}
			if self.DetectPlayers then
				for _, player: Player in Players:GetPlayers() do
					local char: Model = player.Character; if not char then continue end
					table.insert(allCharacters, char)
				end
			end

			if self.DetectNPCs then
				for _, npc: Types.Bandit in BanditNPC.AllNPCs do
					if npc == self then continue end
					if not self.DetectOwnKind and npc.NPCID == self.NPCID then continue end

					local char: Model = npc.Character
					table.insert(allCharacters, char)
				end
			end

			-- Checking detected character
			local detected: {Model} = {}
			for _, eChar: Model in allCharacters do

				local eRoot: BasePart = eChar:FindFirstChild("HumanoidRootPart"); if not eRoot then continue end
				local eHum: Humanoid = eChar:FindFirstChild("Humanoid"); if not eHum then continue end
				if eHum.Health <= 0 then continue end

				local inSight: boolean = self:IsPartInSight(eRoot, properties.RaycastParams, true)
				if inSight and eHum.Health > 0 then
					table.insert(detected, eChar)
				end

			end

			-- Running callback
			if #detected > 0 then
				properties.DetectionCallback(detected)
			else
				properties.NotDetectionCallback()
			end

			task.delay(self.DetectionCooldown, function()
				properties.Debounce = false
			end)
		end,
		function(properties: Types.LoopProperties)

		end
	)

end

function BanditNPC:IsPartInSight(part: BasePart, params: RaycastParams?, includeSibilings: boolean?): boolean

	local char: Model = self.Character
	local root: BasePart = char:FindFirstChild("HumanoidRootPart"); if not root then return end

	local distance: number = (part.Position - root.Position).Magnitude
	local inMinDistance: boolean = distance <= self.AlwaysDetectRadius
	local inDistance: boolean = distance <= self.MaxDetectionRadius
	if not inDistance then return false end

	local rootLook: Vector3 = root.CFrame.LookVector
	local toPart: Vector3 = (part.Position - root.Position).Unit
	local dot: number = rootLook:Dot(toPart)
	local angle: number = math.deg(math.acos(dot))
	local inFOV: boolean = angle <= self.DetectionFOV
	if not inFOV and not inMinDistance then return false end

	if not params then
		params = self:GetDefaultRaycastParams({part})
	end

	local result: RaycastResult = workspace:Raycast(root.Position, toPart * (distance + 5), params); if not result then return end
	local rayHit: boolean = result.Instance == part or (includeSibilings and result.Instance:IsDescendantOf(part.Parent))
	if not rayHit then return false end

	return true

end

function BanditNPC:GetDefaultRaycastParams(include: {}): RaycastParams
	include = include or {}

	local allNPCChars = {}
	for npcChar, npc in self.AllNPCs do

		local shouldInclude = false
		for i2, includeObj in include do
			if npcChar:IsAncestorOf(includeObj) then
				shouldInclude = true
				break
			end
		end

		if not shouldInclude then
			table.insert(allNPCChars, npcChar)
		end
	end


	local exclude = {self.Character}
	for _, npcChar in self.AllNPCs do
		table.insert(exclude, npcChar)
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = exclude
	params.FilterType = Enum.RaycastFilterType.Exclude

	return params
end

function BanditNPC:FollowPart(part: BasePart, includeSibilings: boolean?, params: RaycastParams?)

	self:ConfigureLoop("FollowPart", {
		Part = part;
		IncludeSibilings = includeSibilings;
		Debounce = false;
		RaycastParams = params;
	}, function(dt, properties)
		if properties.Debounce then return end
		properties.Debounce = true

		local char = self.Character
		local hum = char:FindFirstChild("Humanoid"); if not hum then return end
		local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end

		local goalPos = properties.Part.Position + (root.Position - properties.Part.Position).Unit * self.FollowDistance
		self.CurrentDistination = goalPos

		local params = properties.RaycastParams or self:GetDefaultRaycastParams({part})
		local goalDir = (goalPos - root.Position).Unit
		local goalMag = (goalPos - root.Position).Magnitude
		local result = workspace:Raycast(root.Position, goalDir * (goalMag + 5), params)

		self.MoveToJanitor:Clean()
		if result and (result.Instance == part or (includeSibilings and result.Instance:IsDescendantOf(part.Parent))) then


			hum:MoveTo(goalPos)

			if ((goalPos - root.Position) * NO_Y).Magnitude <= 0.2 then
				char:SetAttribute("MoveDirection", Vector3.new())
			else
				char:SetAttribute("MoveDirection", ((goalPos - root.Position) * NO_Y).Unit)
			end

		else

			local success, result = pcall(function()
				self.Path:ComputeAsync(root.Position, goalPos)
			end)
			if not success then
				warn("An error occured while pathfinding: " .. result)
				return
			end

			local waypoints = self.Path:GetWaypoints()
			self.CurrentPathWaypoints = waypoints
			local firstPoint: PathWaypoint = nil

			for i, waypoint in waypoints do
				if i ~= 1 and ((waypoint.Position - root.Position) * NO_Y).Magnitude > self.FollowDistanceMargin then
					firstPoint = waypoint
					break
				end
			end

			if firstPoint then
				char:SetAttribute("MoveDirection", ((firstPoint.Position - root.Position) * NO_Y).Unit)

				if firstPoint.Action == Enum.PathWaypointAction.Jump then
					hum:MoveTo(firstPoint.Position)
					hum.Jump = true
					hum.MoveToFinished:Wait()
				elseif firstPoint.Action == Enum.PathWaypointAction.Walk then
					hum:MoveTo(firstPoint.Position)
				end

			else
				char:SetAttribute("MoveDirection", Vector3.new())
			end
		end

		properties.Debounce = false
	end, function(properties)
		while properties.Debounce do task.wait() end
		self.Character:SetAttribute("MoveDirection", Vector3.new())
		self.CurrentPathWaypoints = nil
		self.CurrentDistination = nil
	end)

end

function BanditNPC:MoveToLocation(location: Vector3)
	self.MoveToJanitor:Clean()
	local pathCancelled = false; self.MoveToJanitor:GiveChore(function() pathCancelled = true end)

	local char = self.Character
	local hum = char:FindFirstChild("Humanoid"); if not hum then return end
	local root  = char:FindFirstChild("HumanoidRootPart"); if not root then return end

	local success, result = pcall(function() 
		self.Path:ComputeAsync(root.Position, location)	
	end)

	if not success then
		warn("An error occured while pathfinding: " .. result)
		return
	end

	local waypoints = self.Path:GetWaypoints()
	self.CurrentPathWaypoints = waypoints
	self.CurrentDistination = location

	for _, waypoint: PathWaypoint in waypoints do
		if pathCancelled then return end

		if waypoint.Action == Enum.PathWaypointAction.Walk then
			-- update move direction
			char:SetAttribute("MoveDirection", ((waypoint.Position - root.Position) * NO_Y).Unit)

			-- moving
			hum:MoveTo(waypoint.Position)
			hum.MoveToFinished:Wait()

		elseif waypoint.Action == Enum.PathWaypointAction.Jump then
			hum.Jump = true
		end
	end

	if not pathCancelled then
		char:SetAttribute("MoveDirection", Vector3.new())

		self.CurrentPathWaypoints = nil
		self.CurrentDistination = nil
	end
end

function BanditNPC:CalculateWalkDistance(): number?
	local char: Model = self.Character
	local root: BasePart = char.HumanoidRootPart

	if self.CurrentPathWaypoints ~= nil then

		-- Calculating total distance
		local distance = 0
		local lastPos: Vector3 = root.Position

		for i, waypoint: PathWaypoint in self.CurrentPathWaypoints do
			distance += (lastPos - waypoint.Position).Magnitude
			lastPos = waypoint.Position
		end

		return distance
	elseif self.CurrentDistination ~= nil then
		return (self.CurrentDistination - root.Position).Magnitude
	else
		warn("NPC has no current destination or path.")
		return 0
	end
end

-- Destroying
function BanditNPC:Destroy()
	self.Janitor:Destroy()
end

-- Returning
return BanditNPC