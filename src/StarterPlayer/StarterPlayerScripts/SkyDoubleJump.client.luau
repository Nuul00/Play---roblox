-- Двойной прыжок на Sky Isles: ещё одно нажатие прыжка в воздухе подбрасывает вверх с облачным «пыхом».
-- Помогает перепрыгивать между облаками к островам с сундуками. Работает только в облачном мире
-- (атрибут CurrentWorld или высота персонажа), в остальных мирах прыжок обычный.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
-- Sky Isles висят на высоте ~300, остальные миры у земли.
local SKY_MIN_Y = 200
-- JumpRequest срабатывает каждый кадр, пока прыжок зажат: новое нажатие — после паузы.
local PRESS_GAP = 0.1
local BOOST = 1.05

local AIR = {
	[Enum.HumanoidStateType.Freefall] = true,
	[Enum.HumanoidStateType.Jumping] = true,
}
local GROUND = {
	[Enum.HumanoidStateType.Landed] = true,
	[Enum.HumanoidStateType.Running] = true,
	[Enum.HumanoidStateType.RunningNoPhysics] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Swimming] = true,
}

local function inSky(root: BasePart): boolean
	return player:GetAttribute("CurrentWorld") == "Sky Isles" or root.Position.Y > SKY_MIN_Y
end

-- Облачко под ногами: белые клубы разлетаются в стороны и тают.
local function puff(root: BasePart)
	local p = Instance.new("Part")
	p.Size = Vector3.new(2, 0.2, 2)
	p.CFrame = CFrame.new(root.Position - Vector3.new(0, 3, 0))
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 215, 240))
	e.LightEmission = 0.3
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.5, 0.8)
	e.Speed = NumberRange.new(6, 10)
	e.SpreadAngle = Vector2.new(180, 10)
	e.Drag = 6
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Parent = p
	e:Emit(14)
	Debris:AddItem(p, 1.5)
end

local connection: RBXScriptConnection?
local function setup(character: Model)
	if connection then
		connection:Disconnect()
		connection = nil
	end
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not humanoid or not root then
		return
	end
	local used = false
	local lastRequest = 0
	humanoid.StateChanged:Connect(function(_, new)
		if GROUND[new] then
			used = false
		end
	end)
	connection = UserInputService.JumpRequest:Connect(function()
		local now = os.clock()
		local fresh = now - lastRequest > PRESS_GAP
		lastRequest = now
		if not fresh or used or humanoid.Health <= 0 or not AIR[humanoid:GetState()] or not inSky(root) then
			return
		end
		used = true
		local v = root.AssemblyLinearVelocity
		local jump = humanoid.UseJumpPower and humanoid.JumpPower or math.sqrt(2 * workspace.Gravity * humanoid.JumpHeight)
		root.AssemblyLinearVelocity = Vector3.new(v.X, jump * BOOST, v.Z)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		puff(root)
	end)
end

player.CharacterAdded:Connect(setup)
if player.Character then
	task.spawn(setup, player.Character)
end
