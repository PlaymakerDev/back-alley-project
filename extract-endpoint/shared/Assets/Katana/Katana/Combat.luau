local rs = game:GetService("ReplicatedStorage")
local ss = game:GetService("ServerStorage")

local CombatTable = require(ss.Modules.CombatTable)
local MuchachoHitbox = require(ss.Modules.MuchachoHitbox)
local HitService = require(ss.Modules.HitService)
local Animation = rs.Assets.Katana.Animations
local VFX = rs.Assets.Katana.VFX
local SFX = rs.Assets.Katana.SFX

local tool = script.Parent

local c

local function StopAnimation(h, a)
	for i, v in pairs(h:GetPlayingAnimationTracks()) do
		if v.Name == a then
			v:Stop()
		end
	end
end

local function SetCombo(CT)
	if CT.Combo < 5 then
		CT.Combo += 1
	else
		CT.Combo = 1
	end
end

local function ComboReset(CT, oldcombo)
	task.delay(1, function()
		local currentcombo = CT.Combo

		if oldcombo == 5 then return end

		if currentcombo-1 == oldcombo and not CT.Attacking then
			CT.Combo = 1
		end
	end)
end

local function fx(hum, combo)
		
	local attachment = Instance.new("Attachment")
	attachment.Parent = hum.RootPart

	local particle = VFX.Hit:Clone()
	particle.Parent = attachment
	particle:Emit(5)
	
	local particle2 = VFX.Lines:Clone()
	particle2.Parent = attachment
	particle2:Emit(5)
	
	local particle3 = VFX.Lines2:Clone()
	particle3.Parent = attachment
	particle3:Emit(5)
	
	local sound = SFX.HitSound:Clone()
	sound.Parent = hum.RootPart
	sound:Play()
	
	local hitAnims = Animation.HitAnimations:GetChildren()
	local hitAnim

	if combo == 1 or combo == 2 or combo == 5 then
		hitAnim = hum:LoadAnimation(hitAnims[2])
	elseif combo == 3 then
		hitAnim = hum:LoadAnimation(hitAnims[3])
	elseif combo == 4 then
		hitAnim = hum:LoadAnimation(hitAnims[1])
	end

	hitAnim:Play()
end

tool.Activated:Connect(function()
	c = tool.Parent
	local h = c:FindFirstChild("Humanoid")
	local rp = h.RootPart
	local a = h.Animator

	local CT = CombatTable[c]

	local combo = CT.Combo
	local attacking = CT.Attacking
	local stunned = CT.Stunned
	local blocking = CT.Blocking

	if attacking or stunned or blocking then return end
	CT.Attacking = true



	local animations = Animation.Attack:GetChildren()
	local animation = a:LoadAnimation(animations[combo])


	local hitbox = MuchachoHitbox.CreateHitbox()
	hitbox.Size	 = Vector3.new(6,6,6)
	hitbox.Offset = CFrame.new(0,0,-2.5)
	hitbox.CFrame = rp
	hitbox.Visualizer = false

	task.delay(.5, function()
		ComboReset(CT, combo)
		hitbox:Stop()

		if combo == 5 then
			h.WalkSpeed = 8
			task.wait(0.5)
		end

		h.WalkSpeed = 16
		CT.Attacking = nil
	end)

	hitbox.Touched:Connect(function(hit, hum)
		if hum == h then return end

		local kb
		local gb

		if combo < 5 then
			kb = rp.CFrame.LookVector * 10
			gb = false
		else
			kb = rp.CFrame.LookVector * 100
			gb = true
		end

		if HitService.Hit(hum, 4, .1, kb, gb) then
			fx(hum, combo)
		end

	end)

	animation:Play()
	task.wait(0.16)
	hitbox:Start()

	SetCombo(CT)

end)