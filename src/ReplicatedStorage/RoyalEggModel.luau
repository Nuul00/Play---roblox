-- Модель Royal Egg: из Tripo (ReplicatedStorage.TripoEggs.RoyalEgg, вставляется в Studio), а пока
-- её нет — золотое яйцо из деталей: золотой корпус, лента с камнями, маленькая корона сверху.
local RoyalEggModel = {}

local function part(m, shape, size, cf, color, mat)
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = m
	return p
end

-- stage: 1 — обычное Royal Egg, 2 — «треснувшее с кристаллами», 3 — божественное с крыльями и нимбом
-- (ступени эволюции при открытии, RoyalHatch). Нет модели ступени — берётся предыдущая.
local STAGE_NAME = { "RoyalEggPremium", "RoyalEggStage2", "RoyalEggStage3" }
function RoyalEggModel.Build(stage: number?): Model
	local folder = script.Parent:FindFirstChild("TripoEggs")
	local t
	for s = math.clamp(stage or 1, 1, 3), 1, -1 do
		t = folder and folder:FindFirstChild(STAGE_NAME[s])
		if t then
			break
		end
	end
	if not t and folder then
		t = folder:FindFirstChild("RoyalEgg") -- прежнее яйцо, если премиум-модели нет
	end
	if t then
		local m = t:Clone()
		if m:IsA("Model") then
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
				end
			end
			m.Name = "RoyalEgg"
			return m
		end
	end
	local m = Instance.new("Model")
	m.Name = "RoyalEgg"
	local GOLD, DARK = Color3.fromRGB(255, 200, 60), Color3.fromRGB(200, 120, 20)
	local body = part(m, Enum.PartType.Ball, Vector3.new(4, 5.2, 4), CFrame.new(0, 2.6, 0), GOLD, Enum.Material.Foil)
	m.PrimaryPart = body
	-- лента с камнями
	local band = part(m, Enum.PartType.Cylinder, Vector3.new(0.5, 4.15, 4.15), CFrame.new(0, 2.4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(150, 40, 170), Enum.Material.SmoothPlastic)
	band.Name = "Band"
	local GEMS = { Color3.fromRGB(255, 60, 90), Color3.fromRGB(70, 200, 255), Color3.fromRGB(90, 255, 140), Color3.fromRGB(255, 240, 120) }
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2
		part(m, Enum.PartType.Ball, Vector3.new(0.55, 0.55, 0.55), CFrame.new(math.cos(a) * 2.08, 2.4, math.sin(a) * 2.08), GEMS[i % 4 + 1], Enum.Material.Neon)
	end
	-- корона
	part(m, Enum.PartType.Cylinder, Vector3.new(0.35, 1.7, 1.7), CFrame.new(0, 5.15, 0) * CFrame.Angles(0, 0, math.rad(90)), DARK, Enum.Material.Foil)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		local spike = part(m, Enum.PartType.Block, Vector3.new(0.3, 0.75, 0.3), CFrame.new(math.cos(a) * 0.7, 5.6, math.sin(a) * 0.7), GOLD, Enum.Material.Foil)
		part(m, Enum.PartType.Ball, Vector3.new(0.28, 0.28, 0.28), spike.CFrame * CFrame.new(0, 0.45, 0), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
	end
	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 10
	light.Brightness = 1.2
	light.Parent = body
	local sp = Instance.new("Sparkles")
	sp.SparkleColor = Color3.fromRGB(255, 230, 140)
	sp.Parent = body
	return m
end

return RoyalEggModel
