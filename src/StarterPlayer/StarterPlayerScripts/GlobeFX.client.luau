-- Снежный шар на острове лидеров Frozen Peaks: пока камера внутри купола (тег SnowGlobe, атрибут Radius),
-- по экрану тянет ветер (полосы снега мимо камеры) и по краям экрана мягкий иней. Снаружи — ничего.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- иней по краям экрана: четыре полосы с градиентом
local gui = Instance.new("ScreenGui")
gui.Name = "GlobeFrost"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 2
gui.Parent = player:WaitForChild("PlayerGui")
local edges = {}
for i, e in {
	{ UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0), 90 },
	{ UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0.78), -90 },
	{ UDim2.fromScale(0.16, 1), UDim2.fromScale(0, 0), 0 },
	{ UDim2.fromScale(0.16, 1), UDim2.fromScale(0.84, 0), 180 },
} do
	local f = Instance.new("Frame")
	f.Size, f.Position = e[1], e[2]
	f.BackgroundColor3 = Color3.fromRGB(225, 245, 255)
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 1
	f.Parent = gui
	local g = Instance.new("UIGradient")
	g.Rotation = e[3]
	g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	g.Parent = f
	edges[i] = f
end

-- ветер: невидимая плита сбоку от камеры, частицы-полосы летят поперёк кадра
local windPart = Instance.new("Part")
windPart.Name = "GlobeWind"
windPart.Anchored, windPart.CanCollide, windPart.CanQuery, windPart.CanTouch = true, false, false, false
windPart.Transparency = 1
windPart.Size = Vector3.new(1, 18, 30)
local wind = Instance.new("ParticleEmitter")
wind.Texture = "rbxasset://textures/particles/sparkles_main.dds"
wind.Color = ColorSequence.new(Color3.new(1, 1, 1))
wind.LightEmission = 0.3
wind.Orientation = Enum.ParticleOrientation.VelocityParallel
wind.Squash = NumberSequence.new(-2.5)
wind.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0.08) })
wind.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.35), NumberSequenceKeypoint.new(0.8, 0.5), NumberSequenceKeypoint.new(1, 1) })
wind.Lifetime = NumberRange.new(0.9, 1.4)
wind.Speed = NumberRange.new(22, 32)
wind.EmissionDirection = Enum.NormalId.Right
wind.SpreadAngle = Vector2.new(6, 6)
wind.Acceleration = Vector3.new(0, -3, 0)
wind.Rate = 35
wind.Enabled = false
wind.Parent = windPart

local globes = {}
for _, g in CollectionService:GetTagged("SnowGlobe") do globes[g] = true end
CollectionService:GetInstanceAddedSignal("SnowGlobe"):Connect(function(g) globes[g] = true end)
CollectionService:GetInstanceRemovedSignal("SnowGlobe"):Connect(function(g) globes[g] = nil end)

local inside = false
local function setInside(v)
	if v == inside then return end
	inside = v
	for _, f in edges do
		TweenService:Create(f, TweenInfo.new(0.8), { BackgroundTransparency = v and 0.25 or 1 }):Play()
	end
	wind.Enabled = v
	windPart.Parent = v and workspace or nil
end

local acc, t = 0, 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	local cam = workspace.CurrentCamera
	if not cam then return end
	acc += dt
	if acc > 0.2 then
		acc = 0
		local p = cam.CFrame.Position
		local found = false
		for g in globes do
			if g.Parent and (g.Position - p).Magnitude < (g:GetAttribute("Radius") or 0) - 1 then
				found = true
				break
			end
		end
		setInside(found)
	end
	if inside then
		-- плита слева от камеры, ветер дует вправо и медленно гуляет по силе
		windPart.CFrame = cam.CFrame * CFrame.new(-14, 0, -10)
		wind.Rate = 30 + 15 * math.sin(t * 0.7)
	end
end)
