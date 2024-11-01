---- Variables
--local player = game.Players.LocalPlayer
--local character = player.Character or player.CharacterAdded:Wait()
--local humanoid = character:WaitForChild("Humanoid")
--local animator = humanoid:WaitForChild("Animator")

--local walkSpeed = 16 -- Normal walking speed
--local crouchSpeed = 8 -- Walking speed when C is pressed
--local crouchKey = Enum.KeyCode.C -- C key for crouching

--local UserInputService = game:GetService("UserInputService")
--local cHeld = false -- Track if C is being held down

----local walkingAnimationId = "rbxassetid://81402289231356" -- Replace with your animation ID
----local walkingAnimation = Instance.new("Animation")
----walkingAnimation.AnimationId = walkingAnimationId

----local walkingTrack = animator:LoadAnimation(walkingAnimation)

----local function animationByKeyUpdate()
----	if humanoid.WalkSpeed == crouchSpeed then
----		print("true")
----		walkingTrack:Play()
----	else
----		print("false")
----		walkingTrack:Stop()
----	end
----end

---- Function to handle key press
--local function onKeyPress(input, gameProcessedEvent)
--	if input.KeyCode == crouchKey and not gameProcessedEvent then
--		cHeld = true
--		humanoid.WalkSpeed = crouchSpeed
--		--animationByKeyUpdate()
--	end
--end

---- Function to handle key release
--local function onKeyRelease(input, gameProcessedEvent)
--	if input.KeyCode == crouchKey and not gameProcessedEvent then
--		cHeld = false
--		humanoid.WalkSpeed = walkSpeed
--		--animationByKeyUpdate()
--	end
--end

---- Ensure speed stays reduced while C is held, regardless of other keys
--local function onUpdate()
--	if cHeld then
--		humanoid.WalkSpeed = crouchSpeed
--		--animationByKeyUpdate()
--	end
--end

---- Connect key press, release, and update functions
--UserInputService.InputBegan:Connect(onKeyPress)
--UserInputService.InputEnded:Connect(onKeyRelease)
--game:GetService("RunService").RenderStepped:Connect(onUpdate)


-- Variables
local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Character = player.Character or player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

local walkSpeed = 16 -- Normal walking speed
local crouchSpeed = 8 -- Walking speed when C is pressed
local crouchKey = Enum.KeyCode.C -- C key for crouching
local cHeld = false -- Track if C is being held down

--local walkingAnimationId = "rbxassetid://140522746137798" -- Replace with your animation ID
local walkingAnimationId = "rbxassetid://112247243051168"
local walkingAnimation = Instance.new("Animation")
walkingAnimation.AnimationId = walkingAnimationId

local walkingTrack = Animator:LoadAnimation(walkingAnimation)

-- Function to update character references
local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	-- Function to handle key press
	local function onKeyPress(input, gameProcessedEvent)
		if input.KeyCode == crouchKey and not gameProcessedEvent then
			cHeld = true
			humanoid.WalkSpeed = crouchSpeed
			walkingTrack:Play()
			--animationByKeyUpdate()
		end
	end

	-- Function to handle key release
	local function onKeyRelease(input, gameProcessedEvent)
		if input.KeyCode == crouchKey and not gameProcessedEvent then
			cHeld = false
			humanoid.WalkSpeed = walkSpeed
			walkingTrack:Stop()
			--animationByKeyUpdate()
		end
	end

	-- Ensure speed stays reduced while C is held, regardless of other keys
	local function onUpdate()
		if cHeld then
			humanoid.WalkSpeed = crouchSpeed
			--animationByKeyUpdate()
		end
	end

	-- Connect key press, release, and update functions
	UserInputService.InputBegan:Connect(onKeyPress)
	UserInputService.InputEnded:Connect(onKeyRelease)
	RunService.RenderStepped:Connect(onUpdate)
end

-- Initial setup
setupCharacter(player.Character or player.CharacterAdded:Wait())

-- Listen for character respawn
player.CharacterAdded:Connect(setupCharacter)
