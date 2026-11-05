-- Каток Frozen Peaks: на льду (атрибут OnIce ставит WorldPolish.server и надевает коньки)
-- персонаж катается — разгоняется плавно, по инерции скользит, когда отпустил кнопки,
-- слегка наклоняется в повороты, а из-под коньков летит ледяная крошка.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local vel = Vector3.zero
local spray: ParticleEmitter? = nil
local lean = 0

local function sprayFor(root: BasePart)
	if spray and spray.Parent == root then
		return spray
	end
	local a = Instance.new("Attachment")
	a.Name = "SkateSprayAt"
	a.Position = Vector3.new(0, -2.8, 0.4)
	a.Parent = root
	local e = Instance.new("ParticleEmitter")
	e.Name = "SkateSpray"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(235, 248, 255), Color3.fromRGB(170, 220, 255))
	e.LightEmission = 0.5
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.3, 0.6)
	e.Speed = NumberRange.new(3, 6)
	e.SpreadAngle = Vector2.new(40, 40)
	e.EmissionDirection = Enum.NormalId.Back
	e.Acceleration = Vector3.new(0, -12, 0)
	e.Rate = 0
	e.Parent = a
	spray = e
	return e
end

RunService.Heartbeat:Connect(function(dt)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (root and hum) then
		return
	end
	local onIce = player:GetAttribute("OnIce") == true and hum.FloorMaterial ~= Enum.Material.Air
	if not onIce then
		vel = root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
		if spray then
			spray.Rate = 0
		end
		if lean ~= 0 then
			lean = 0
			hum.CameraOffset = Vector3.zero
		end
		return
	end
	local want = hum.MoveDirection * hum.WalkSpeed * 1.15
	-- разгон медленный, торможение ещё медленнее: лёд
	local k = want.Magnitude > 0.1 and 2.2 or 0.55
	vel = vel:Lerp(want, math.clamp(k * dt, 0, 1))
	local y = root.AssemblyLinearVelocity.Y
	root.AssemblyLinearVelocity = Vector3.new(vel.X, y, vel.Z)
	if vel.Magnitude > 4 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + vel.Unit) * CFrame.Angles(0, 0, 0)
	end
	local e = sprayFor(root)
	e.Rate = vel.Magnitude > 8 and math.min(vel.Magnitude * 1.5, 60) or 0
end)
