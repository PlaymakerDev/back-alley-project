--local function applyForceField(character)
--	if not character:FindFirstChildOfClass("ForceField") then
--		local forceField = Instance.new("ForceField")
--		forceField.Parent = character
--	end
--end

--local function onPlayerAdded(player)
--	player.CharacterAdded:Connect(function(character)
--		applyForceField(character)
--	end)

--	-- Apply forcefield immediately if the character is already loaded
--	if player.Character then
--		applyForceField(player.Character)
--	end
--end

--game.Players.PlayerAdded:Connect(onPlayerAdded)

---- Apply to all existing players if the script is added after some players have joined
--for _, player in pairs(game.Players:GetPlayers()) do
--	onPlayerAdded(player)
--end