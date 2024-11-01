local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local currentHealth = Humanoid.Health

local hurtAnims = {
	Humanoid:LoadAnimation(ReplicatedStorage.PlayerAction.TakeDamage.Assets.Animations:WaitForChild("TakeDamage1")),
	Humanoid:LoadAnimation(ReplicatedStorage.PlayerAction.TakeDamage.Assets.Animations:WaitForChild("TakeDamage2")),
	Humanoid:LoadAnimation(ReplicatedStorage.PlayerAction.TakeDamage.Assets.Animations:WaitForChild("TakeDamage3"))
}

--local hurtAnim = Humanoid:LoadAnimation(ReplicatedStorage.PlayerAction.TakeDamage.Assets.Animations:WaitForChild("TakeDamage1"))

--Humanoid.Changed:connect(function(property)
--	print()
--	if property == "Health" then
--		hurtAnim:Play()
--	end
--end)
	
	
Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
	if Humanoid.Health < currentHealth then
		--hurtAnim:Play()
		-- Play a random take-damage animation
		local randomAnim = hurtAnims[math.random(1, #hurtAnims)]
		randomAnim:Play()
	end
	
	currentHealth = Humanoid.Health
end)