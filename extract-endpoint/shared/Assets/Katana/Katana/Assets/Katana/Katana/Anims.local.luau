local Players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local weapon = rs.Assets.Katana.Katana

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local Sword = script.Parent

local Walk = Humanoid.Animator:LoadAnimation(weapon.Animations.Walk)
local Idle = Humanoid.Animator:LoadAnimation(weapon.Animations.Idle)

local isWalking = false

Humanoid.Running:Connect(function(speed)

	if Sword.Parent == Character then

		if speed > 0 and not isWalking then
			isWalking = true
			Walk:Play()

		elseif speed == 0 and isWalking then
			isWalking = false
			Walk:Stop()
		end
	end
end)

Sword.Equipped:Connect(function()
	Idle:Play()
	if Humanoid.MoveDirection.Magnitude > 0 then
		isWalking = true
		Walk:Play()
	end
end)

Sword.Unequipped:Connect(function()
	Idle:Stop()
	if Humanoid.MoveDirection.Magnitude > 0 then 
		isWalking = false
		Walk:Stop()
	end
end)