-- THIRD
-- GET SERVICE
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")

local Promise = require(RS.Modules.Promise)

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator") -- Get the Animator object
local DashAnimsFolder = RS.MoveSet.Dash.Assets.Animations.Dash

local HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')

local sampleCharacter = script.Parent
local samplePlayer = game.Players:GetPlayerFromCharacter(sampleCharacter)
local swordName = "ClassicSword" -- Change this to the exact name of your sword
local swordName2 = "Katana"

local isWieldSword = false

local directions = {
	['Forward'] = Vector3.new(0, 0, -1),
	['Left'] = Vector3.new(-1, 0, 0),
	['Backward'] = Vector3.new(0, 0, 1),
	['Right'] = Vector3.new(1, 0, 0)
}

local anims = {}

local lastPressTime = 0
local isSprinting = false
local keysPressed = {} -- Table to track which keys are currently pressed

-- SETUP KEYBIND
local sprintSpeed = 35 -- Speed while sprinting
local walkSpeed = 16 -- Normal walking speed
local sprintInterval = 0.3 -- Time interval in seconds for double press
local sprintKeys = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D}
-- STOP RUNNING THRESHOLD
local stopSpeedThreshold = 8

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local runningTrack = Animator:LoadAnimation(RS.MoveSet.Sprint.Assets.Animations:WaitForChild("Sprint"))
local swordRunningTrack = Animator:LoadAnimation(RS.MoveSet.Sprint.Assets.Animations:WaitForChild("SwordSprint"))

local stopRunning = Animator:LoadAnimation(RS.PlayerAction.StopRunning.Assets.Animations:WaitForChild("StopRunning"))

Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

for index, animation in pairs(DashAnimsFolder:GetDescendants()) do
	if animation:IsA("Animation") then
		local anim = Humanoid:LoadAnimation(animation)
		anims[animation.Name] = anim
	end
end

local AnimationsFolder = script:WaitForChild('Animations')

local AnimationsTable = {
	['Idle'] = Humanoid:LoadAnimation( AnimationsFolder.Idle ),
	['WalkForward'] = Humanoid:LoadAnimation( AnimationsFolder.WalkForward ),
	['WalkRight'] = Humanoid:LoadAnimation( AnimationsFolder.WalkRight ),
	['WalkLeft'] = Humanoid:LoadAnimation( AnimationsFolder.WalkLeft ),
}

---- Initial playback of animations
--for _, Animation in pairs(AnimationsTable) do
--	Animation:Play(0, 0.01, 0)
--end

-- SPRINTING
local function startSprinting()
	Humanoid.WalkSpeed = sprintSpeed
	if not isSprinting then
		isSprinting = true
		
		if isWieldSword then
			swordRunningTrack:Play()
			if swordRunningTrack:Play() and isWieldSword == false then
				swordRunningTrack:Stop()
			else
				print('CHARACTER IS HOLDING SWORD')
			end
		else
			runningTrack:Play()
			if runningTrack:Play() and isWieldSword == true then
				runningTrack:Stop()
			else
				print('CHARACTER IS NOT HOLDING SWORD')
			end
		end
		
		
		--if isWieldSword and Humanoid.WalkSpeed == sprintSpeed then
		--	runningTrack:Stop()
		--	swordRunningTrack:Play()
		--elseif not isWieldSword and Humanoid.WalkSpeed == sprintSpeed then
		--	swordRunningTrack:Stop()
		--	runningTrack:Play()
		--else
		--	runningTrack:Play() -- Play the running animation
		--end
		--if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		--end
	end
end

-- Function to stop sprinting
local function stopSprinting()
	Humanoid.WalkSpeed = walkSpeed
	if isSprinting then        
		isSprinting = false

		if isWieldSword then
			stopRunning:Play()
			swordRunningTrack:Stop()
		else
			stopRunning:Play()
			runningTrack:Stop() -- Stop the running animation
		end
	end
end

-- Function to check if any sprint keys are still pressed
local function areSprintKeysPressed()
	for _, key in ipairs(sprintKeys) do
		if keysPressed[key] then
			return true
		end
	end
	return false
end

-- Key press detection
local function onKeyPress(input)
	if table.find(sprintKeys, input.KeyCode) then
		keysPressed[input.KeyCode] = true
		local currentTime = tick()

		if input.KeyCode == Enum.KeyCode.W then
			if currentTime - lastPressTime <= sprintInterval then
				-- Start sprinting if W is double-pressed within the interval
				startSprinting()
			elseif isSprinting then
				-- If already sprinting and W is pressed, do nothing (maintain sprint)
			else
				stopSprinting()  -- Revert to walking if only a single press
			end

			-- Update last press time
			lastPressTime = currentTime
		elseif isSprinting then
			-- Keep sprinting if other WASD keys are pressed while already sprinting
			startSprinting()
		end
	end
end

-- Key release detection
local function onKeyRelease(input)
	if table.find(sprintKeys, input.KeyCode) then
		keysPressed[input.KeyCode] = nil

		-- Stop sprinting if no sprint keys are pressed
		if not areSprintKeysPressed() then
			stopSprinting()
		end
	end
end

function accelerateToVelo(lv: LinearVelocity, targetVelocity: Vector2, accel)
	local velocity: Vector2 = lv.PlaneVelocity
	local deltaV: Vector2 = targetVelocity - velocity

	local _, current_dt = game:GetService("RunService").Stepped:Wait()
	local maxAccel = deltaV / current_dt

	local finalAcc = (maxAccel.Magnitude < accel) and maxAccel or maxAccel.Unit * accel

	return Promise.new(function(resolve)
		local e
		local FRAMES_WITHIN_REACH = 1

		e = game:GetService("RunService").Stepped:Connect(function(time, dt)
			lv.PlaneVelocity = lv.PlaneVelocity + finalAcc * dt

			if ((targetVelocity - lv.PlaneVelocity).Magnitude <= finalAcc.Magnitude * dt * FRAMES_WITHIN_REACH) then
				lv.PlaneVelocity = targetVelocity
				e:Disconnect()
				resolve()
			end
		end)
	end)
end

function accelerateToDistance(targetVelocity: Vector2, accTime, totalDistance)
	local attachment = Instance.new("Attachment", HRP)

	local LV = Instance.new("LinearVelocity")
	--LV.MaxForce = math.huge
	LV.MaxForce = 15000
	LV.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	LV.PlaneVelocity = Vector2.zero
	LV.Attachment0 = attachment
	LV.RelativeTo = Enum.ActuatorRelativeTo.World
	LV.PrimaryTangentAxis = Vector3.xAxis
	LV.SecondaryTangentAxis = Vector3.zAxis
	LV.Parent = attachment

	local d1 = 0.5 * (targetVelocity.Magnitude) * accTime
	local d2 = totalDistance - d1
	local a2 = math.abs(-(targetVelocity.Magnitude * targetVelocity.Magnitude) / (2 * d2))

	return accelerateToVelo(LV, targetVelocity, targetVelocity.Magnitude / accTime):andThen(function()
		return accelerateToVelo(LV, Vector2.zero, a2):andThen(function()
			attachment:Destroy()
		end)
	end)
end

local isDashing = false
local staminaUsage = 1.5
local sprintStaminaUsage = 0.5
local staminaRecharge = 1
local canDash = false

local latestSprint = math.huge
local lastDashTime = 0 -- Track the last dash time
local dashCooldown = 0.4 -- Cooldown duration
local lastSpaceTime = 0 -- Track the last space bar press time
local spaceCooldown = 0.5 -- Time after space bar press where dash is disabled

function onDashKeyPressed(actionName, inputState, inputObject)
	local currentTime = tick()

	-- Check if the space bar was pressed recently
	if canDash and (currentTime - lastDashTime >= dashCooldown) and (currentTime - lastSpaceTime >= spaceCooldown) then
		if inputState == Enum.UserInputState.Begin and not isDashing then
			isDashing = true
			lastDashTime = currentTime -- Update the last dash time
			doDash():andThen(function()
				isDashing = false
			end)
		end
	end
end

CAS:BindAction("DASH_ACTION", onDashKeyPressed, true, Enum.KeyCode.Z)

-- Track space bar presses
UIS.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Space and not gameProcessed then
		lastSpaceTime = tick()
	end
end)

function doDash()
	local animation = anims["ForwardDash"]
	local movingDir = (HRP.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Unit

	if Humanoid.MoveDirection == Vector3.zero then
		movingDir = (Vector3.new(1, 0, 1) * -HRP.CFrame.LookVector).Unit
		animation = anims["BackwardDash"]
	elseif UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
		local lastClosest = math.huge
		local animDirection

		for directionName, dirVec in directions do
			local closeness = 1 - (HRP.CFrame * dirVec):Dot(Humanoid.MoveDirection)

			if closeness < lastClosest then
				lastClosest = closeness
				animDirection = directionName
			end
		end

		animation = anims[animDirection .. "Dash"]
	end

	--animation:Play(.25, 2, 1.2)
	animation:Play(.3, 2.5, 1.7)

	local targetVel = 60

	accelerateToDistance(targetVel * Vector2.new(movingDir.X, movingDir.Z).Unit, 0.04, 18)

	return Promise.new(function(resolve)
		animation.Stopped:Wait()
		resolve()
	end)
end

RunService.RenderStepped:Connect(function(delta)
	local stamina = Humanoid:GetAttribute("InitStamina")
	if stamina < staminaUsage then
		isDashing = false
		canDash = false
		--Humanoid.WalkSpeed = Humanoid:GetAttribute("BaseWalkSpeed")
		stopSprinting()
	else
		canDash = true
	end

	if isDashing and stamina > 0 then
		Humanoid:SetAttribute("InitStamina", stamina - staminaUsage)
		latestSprint = tick()
	elseif isSprinting and stamina > 0 then
		Humanoid:SetAttribute("InitStamina", stamina - sprintStaminaUsage)
		latestSprint = tick()
	else
		if tick() - latestSprint >= staminaRecharge and stamina < Humanoid:GetAttribute("MaxStamina") then
			Humanoid:SetAttribute("InitStamina", stamina + staminaUsage)
		end
	end

	--print(stamina)
	--if stamina == Humanoid:GetAttribute("MaxStamina") then
	--print(stamina)
	--if (stamina - staminaUsage) > 0 then
	--	canDash = true
	--else
	--	print("failed", stamina)
	--end
end)

RunService.RenderStepped:Connect(function(input)
	if Humanoid.WalkSpeed == walkSpeed then

		local DirectionOfMovement = HumanoidRootPart.CFrame:VectorToObjectSpace( HumanoidRootPart.AssemblyLinearVelocity )

		local Forward = math.abs( math.clamp( DirectionOfMovement.Z / Humanoid.WalkSpeed, -1, -0.01 ) )
		local Backwards = math.abs( math.clamp( DirectionOfMovement.Z / Humanoid.WalkSpeed, 0.01, 1 ) )
		local Right = math.abs( math.clamp( DirectionOfMovement.X / Humanoid.WalkSpeed, 0.01, 1 ) )
		local Left = math.abs( math.clamp( DirectionOfMovement.X / Humanoid.WalkSpeed, -1, -0.01 ) )

		local SpeedUnit = (DirectionOfMovement.Magnitude / Humanoid.WalkSpeed)

		local State = Humanoid:GetState()

		local currentTime = tick()

		if DirectionOfMovement.Magnitude > 0.1 then
			if AnimationsTable.WalkForward.IsPlaying == false then		
				AnimationsTable.WalkForward:Play( 0,0.01,0 )
				AnimationsTable.WalkRight:Play( 0,0.01,0  )
				AnimationsTable.WalkLeft:Play( 0,0.01,0  )
			end	
		end

		if DirectionOfMovement.Z/Humanoid.WalkSpeed < 0.1 then

			AnimationsTable.WalkForward:AdjustWeight( Forward )
			AnimationsTable.WalkRight:AdjustWeight( Right )
			AnimationsTable.WalkLeft:AdjustWeight( Left )

			AnimationsTable.WalkForward:AdjustSpeed( SpeedUnit )
			AnimationsTable.WalkRight:AdjustSpeed( SpeedUnit )
			AnimationsTable.WalkLeft:AdjustSpeed( SpeedUnit )

			AnimationsTable.Idle:AdjustWeight(0.001)

		else

			AnimationsTable.WalkForward:AdjustWeight( Backwards )
			AnimationsTable.WalkRight:AdjustWeight( Left )
			AnimationsTable.WalkLeft:AdjustWeight( Right )

			AnimationsTable.WalkForward:AdjustSpeed( SpeedUnit * -1 )
			AnimationsTable.WalkRight:AdjustSpeed( SpeedUnit * -1 )
			AnimationsTable.WalkLeft:AdjustSpeed( SpeedUnit * -1 )

			AnimationsTable.Idle:AdjustWeight(0.001)

		end


		if DirectionOfMovement.Magnitude < 0.1 then
			AnimationsTable.Idle:AdjustWeight(1)
		end
	end
end)

-- Connect key press and release to the functions
game:GetService("UserInputService").InputBegan:Connect(onKeyPress)
game:GetService("UserInputService").InputEnded:Connect(onKeyRelease)

-- Listen for tool equipped in the character
sampleCharacter.ChildAdded:Connect(function(child)
	if child:IsA("Tool") and child.Name == swordName or child:IsA("Tool") and child.Name == swordName2 then
		print("Sword equipped!")
		isWieldSword = true
	end
end)

-- Listen for tool unequipped from the character
sampleCharacter.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") and child.Name == swordName or child:IsA("Tool") and child.Name == swordName2 then
		print("Sword unequipped!")
		isWieldSword = false
	end
end)

