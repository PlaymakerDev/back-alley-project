local RS = game:GetService("ReplicatedStorage")

local playerConfig = require(RS.Configuration.PlayerConfig)

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		for stat, value in playerConfig do
			character.Humanoid:SetAttribute(stat, value)
		end
	end)
end)