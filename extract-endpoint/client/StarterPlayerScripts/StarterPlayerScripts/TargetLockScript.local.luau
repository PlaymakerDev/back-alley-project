-- Service Variables
local player = game.Players.LocalPlayer -- Reference to the local player.
local userInputService = game:GetService("UserInputService") -- Service to handle user inputs.
local runService = game:GetService("RunService") -- Service for frame updates.
local players = game:GetService("Players") -- Service to manage all players.

-- Lock-On System Variables
local lockOnEnabled = false -- Is lock-on currently enabled?
local targetEnemy = nil -- The enemy currently targeted.
local enemiesList = {} -- List of enemies sorted by distance.
local minimumDistance = 5 -- Minimum distance to maintain when locked on.
local maxDistance = 50 -- Maximum distance to activate lock-on.

-- Highlight Variables
local highlightColor = Color3.fromRGB(255, 0, 0) -- Red color for highlighting the target.

-- Function to add a highlight effect to an enemy.
local function addHighlight(enemy)
	if not enemy:FindFirstChild("Highlight") then -- Check if already highlighted.
		local highlight = Instance.new("Highlight") -- Create a new highlight.
		highlight.Name = "Highlight" -- Name the highlight for identification.
		highlight.Adornee = enemy -- Attach the highlight to the enemy.
		highlight.FillColor = Color3.new(0, 0, 0) -- Transparent fill color.
		highlight.OutlineColor = highlightColor -- Red outline color.
		highlight.Parent = enemy -- Parent the highlight to the enemy.
	end
end

-- Function to remove the highlight effect from an enemy.
local function removeHighlight(enemy)
	if enemy and enemy:FindFirstChild("Highlight") then -- Ensure highlight exists.
		local highlight = enemy:FindFirstChild("Highlight") -- Find the highlight.
		if highlight then
			highlight:Destroy() -- Remove the highlight.
		end
	end
end

-- Function to find and sort enemies by distance from the player.
local function updateEnemiesList()
	local character = player.Character -- Get the player's character.
	if not character then
		return -- Exit if character doesn't exist.
	end

	enemiesList = {} -- Reset the enemies list.
	for _, obj in pairs(workspace:GetChildren()) do -- Loop through all objects.
		if obj:IsA("Model") and obj ~= character and obj:FindFirstChildOfClass("Humanoid") then -- Check if object is a valid enemy.
			local enemyHumanoid = obj:FindFirstChildOfClass("Humanoid") -- Get humanoid part.
			local enemyPrimaryPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") -- Get primary part.
			local lockableBool = obj:FindFirstChild("Lockable") -- Check if lockable.
			if enemyHumanoid and enemyPrimaryPart and enemyHumanoid.Health > 0 and lockableBool and lockableBool:IsA("BoolValue") and lockableBool.Value == true then
				local distance = (character.PrimaryPart.Position - enemyPrimaryPart.Position).magnitude -- Calculate distance.
				if distance <= maxDistance then
					table.insert(enemiesList, {enemy = obj, distance = distance}) -- Add to list.
				end
			end
		end
	end

	table.sort(enemiesList, function(a, b) -- Sort enemies by distance.
		return a.distance < b.distance
	end)
end

-- Function to switch to the next enemy in the sorted list.
local function cycleToNextEnemy()
	if lockOnEnabled and targetEnemy then
		updateEnemiesList() -- Refresh enemies list.
		if #enemiesList > 0 then
			local currentIndex = nil
			for i, entry in ipairs(enemiesList) do -- Find current target index.
				if entry.enemy == targetEnemy then
					currentIndex = i
					break
				end
			end

			if currentIndex then
				local nextIndex = (currentIndex % #enemiesList) + 1 -- Get next enemy index.
				removeHighlight(targetEnemy) -- Remove current highlight.
				targetEnemy = enemiesList[nextIndex].enemy -- Set next enemy as target.
				addHighlight(targetEnemy) -- Highlight new target.
			end
		end
	end
end

-- Function to update the lock-on status and player orientation.
local function updateLockOn()
	local character = player.Character -- Get player's character.
	if not character then
		lockOnEnabled = false -- Disable lock-on if character doesn't exist.
		removeHighlight(targetEnemy)
		targetEnemy = nil
		return
	end

	local primaryPart = character:FindFirstChild("HumanoidRootPart") -- Get primary part.
	if primaryPart then
		character.PrimaryPart = primaryPart -- Ensure primary part is set.
	end

	if lockOnEnabled and targetEnemy then
		local enemyPrimaryPart = targetEnemy.PrimaryPart or targetEnemy:FindFirstChild("HumanoidRootPart")
		if enemyPrimaryPart and targetEnemy:FindFirstChildOfClass("Humanoid") and targetEnemy.Humanoid.Health > 0 then
			local distance = (character.PrimaryPart.Position - enemyPrimaryPart.Position).magnitude
			if distance > maxDistance then
				lockOnEnabled = false -- Disable lock-on if target is too far.
				removeHighlight(targetEnemy)
				targetEnemy = nil
			else
				local direction = (enemyPrimaryPart.Position - character.PrimaryPart.Position)
				if direction.magnitude > minimumDistance then
					direction = Vector3.new(direction.X, 0, direction.Z).unit -- Ignore Y-axis difference.
					local newCFrame = CFrame.new(character.PrimaryPart.Position, character.PrimaryPart.Position + direction)
					character:SetPrimaryPartCFrame(newCFrame) -- Face character towards target.
				end
			end
		else
			lockOnEnabled = false -- Disable if target is invalid.
			removeHighlight(targetEnemy)
			targetEnemy = nil
			updateEnemiesList() -- Refresh enemies list.
			if #enemiesList > 0 then
				targetEnemy = enemiesList[1].enemy -- Select closest enemy.
				addHighlight(targetEnemy) -- Highlight new target.
				lockOnEnabled = true
			end
		end
	end
end

-- Function to toggle lock-on state and switch targets.
local function toggleLockOn()
	if lockOnEnabled then
		if #enemiesList > 0 and targetEnemy == enemiesList[#enemiesList].enemy then
			lockOnEnabled = false -- Disable lock-on if last enemy is targeted.
			removeHighlight(targetEnemy)
			targetEnemy = nil
		else
			cycleToNextEnemy() -- Switch to next enemy.
		end
	else
		lockOnEnabled = true -- Enable lock-on.
		updateEnemiesList() -- Update enemies list.
		if #enemiesList > 0 then
			targetEnemy = enemiesList[1].enemy -- Set closest enemy as target.
			addHighlight(targetEnemy) -- Highlight target.
		else
			lockOnEnabled = false -- Disable if no enemies available.
		end
	end
end

-- Connect user inputs to toggle the lock-on functionality.
userInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed then -- Ensure input is not processed by game UI.
		if input.KeyCode == Enum.KeyCode.LeftAlt then -- Toggle lock-on with Left Alt.
			toggleLockOn()
		elseif input.UserInputType == Enum.UserInputType.Touch then -- Toggle lock-on with touch.
			local gui = player:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")
			local button = gui:FindFirstChild("LockOnButton")
			if button and button:IsA("ImageButton") and button.InputBegan:Connect(function(touch)
					toggleLockOn()
				end) then
				toggleLockOn()
			end
		end
	end
end)

-- Continuously update the lock-on system every frame.
runService.RenderStepped:Connect(updateLockOn)

-- Reset lock-on state when the player's character changes.
player.CharacterAdded:Connect(function()
	lockOnEnabled = false -- Disable lock-on on character change.
	targetEnemy = nil
	enemiesList = {}
end)