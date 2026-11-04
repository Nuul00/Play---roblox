-- Эффект прыжка: искры при отрыве от земли и облачко пыли при жёстком приземлении.
-- Только у самого игрока и только визуально.
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function setup(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not humanoid or not root then
		return
	end
	local feet = Instance.new("Attachment")
	feet.Name = "JumpFX"
	feet.Position = Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2) + 0.2, 0)
	feet.Parent = root

	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Enabled = false
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 245, 190), Color3.fromRGB(255, 190, 255))
	sparks.LightEmission = 0.8
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	sparks.Transparency = NumberSequence.new(0.1, 1)
	sparks.Lifetime = NumberRange.new(0.35, 0.6)
	sparks.Speed = NumberRange.new(6, 11)
	sparks.SpreadAngle = Vector2.new(70, 70)
	sparks.EmissionDirection = Enum.NormalId.Bottom
	sparks.Drag = 4
	sparks.Parent = feet

	local dust = Instance.new("ParticleEmitter")
	dust.Name = "Dust"
	dust.Enabled = false
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(235, 230, 245))
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3.2) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	dust.Lifetime = NumberRange.new(0.45, 0.7)
	dust.Speed = NumberRange.new(7, 12)
	dust.SpreadAngle = Vector2.new(180, 5)
	dust.EmissionDirection = Enum.NormalId.Top
	dust.Acceleration = Vector3.new(0, 4, 0)
	dust.Drag = 6
	dust.RotSpeed = NumberRange.new(-90, 90)
	dust.Parent = feet

	local fallSpeed = 0
	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			sparks:Emit(14)
		elseif new == Enum.HumanoidStateType.Freefall then
			fallSpeed = 0
		elseif new == Enum.HumanoidStateType.Landed then
			-- Пыль только после заметного падения, чтобы не дымить на каждой ступеньке.
			if fallSpeed > 28 then
				dust:Emit(math.clamp(math.floor(fallSpeed / 4), 8, 22))
			end
			fallSpeed = 0
		end
	end)
	task.spawn(function()
		while humanoid.Parent and root.Parent do
			if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				fallSpeed = math.max(fallSpeed, -root.AssemblyLinearVelocity.Y)
			end
			task.wait(0.05)
		end
	end)
end

player.CharacterAdded:Connect(setup)
if player.Character then
	task.spawn(setup, player.Character)
end
