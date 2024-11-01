--local StarterPlayerScripts = game:GetService("StarterPlayerScripts")
--local Stamina = StarterPlayerScripts:WaitForChild("Stamina")

--local player = game.Players.LocalPlayer
--local character = player.Character
--local stamina = Stamina.Stamina
--local maxStamina = Stamina.MaxStamina
--local staminaRegenRate = Stamina.StaminaRegenRate

---- Update stamina regeneration rate based on player's activity level
--local function updateStaminaRegenRate()
--	local activityLevel = 0
--	if character:FindFirstChild("Humanoid"):FindFirstChild("State"):Get("Sprinting") then
--		activityLevel = 2 -- sprinting
--	elseif character:FindFirstChild("Humanoid"):FindFirstChild("State"):Get("Dashing") then
--		activityLevel = 1 -- dashing
--	end
--	staminaRegenRate = activityLevel * 10 -- adjust regeneration rate based on activity level
--end

---- Update stamina level whenever the player uses an action
--local function updateStamina()
--	stamina.Value = stamina.Value - 10 -- decrement stamina for dashing
--	staminaRegenRate = updateStaminaRegenRate() -- update regeneration rate
--	wait(1) -- wait for 1 second before regenerating stamina
--	stamina.Value = stamina.Value + staminaRegenRate -- regenerate stamina
--end

---- Dash script
--local Dash = StarterPlayerScripts:WaitForChild("Dash")
--local dashScript = Dash:WaitForChild("LocalScript")

--local function canDash()
--	if stamina.Value <= 0 then
--		return false
--	end
--	updateStamina() -- update stamina level
--	return true
--end

--dashScript.DashButton.Click:Connect(function()
--	if canDash() then
--		-- allow dash
--	else
--		-- prevent dash
--	end
--end)

---- Sprint script
--local Sprint = StarterPlayerScripts:WaitForChild("Sprint")
--local sprintScript = Sprint:WaitForChild("LocalScript")

--local function canSprint()
--	if stamina.Value <= 0 then
--		return false
--	end
--	updateStamina() -- update stamina level
--	return true
--end

--sprintScript.SprintButton.Click:Connect(function()
--	if canSprint() then
--		-- allow sprint
--	else
--		-- revert walking speed to default
--	end
--end)