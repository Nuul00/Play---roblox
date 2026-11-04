-- Четвёртый мир Frozen Peaks: снежный остров с горами, кристаллами, ёлками, замёрзшим озером,
-- снеговиками, иглу и ледяным магазином. Строится кодом при запуске сервера (как Sky Isles).
-- Монеты Coin_N с атрибутом Value собирает GameServer; магазин UpgradeShop/ShopZone — тоже он.
-- Портал PortalToSky ведёт в Sky Isles, а BuildSkyPortal ставит портал сюда на острове Sky Isles.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local CoinTypes = require(ReplicatedStorage:WaitForChild("CoinTypes"))

local Frozen = {}
Frozen.Center = Vector3.new(3000, 60, 0)
local C = Frozen.Center
local M = Enum.Material
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local SNOW = rgb(244, 249, 255)
local ICE = rgb(170, 225, 255)
local DEEP = rgb(70, 130, 210)
local ROCK = rgb(145, 165, 200)
local PINE = rgb(40, 95, 80)
local rand = Random.new(4242)

local function L(x: number, y: number, z: number): Vector3
	return C + Vector3.new(x, y, z)
end
local function part(parent: Instance, name: string, size: Vector3, cf: CFrame | Vector3, color: Color3, material: Enum.Material?, props: { [string]: any }?): BasePart
	local cls = props and props.Class or "Part"
	local p = Instance.new(cls)
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = typeof(cf) == "Vector3" and CFrame.new(cf) or cf
	p.Color = color
	p.Material = material or M.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for k, v in pairs(props) do
			if k ~= "Class" then
				(p :: any)[k] = v
			end
		end
	end
	p.Parent = parent
	return p
end
local function ball(parent, name, d, pos, color, material, props)
	return part(parent, name, Vector3.new(d, d, d), pos, color, material, props and props or nil):: any
end
local function disc(parent, name, d, h, pos, color, material, props)
	local p = part(parent, name, Vector3.new(h, d, d), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), color, material, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
-- Пирамида из четырёх угловых клиньев: горы и ярусы ёлок.
local function pyramid(parent, name, w, h, base: Vector3, color, material, yaw)
	local m = Instance.new("Model")
	m.Name = name
	local half = w / 2
	local rot = CFrame.Angles(0, yaw or 0, 0)
	for k = 0, 3 do
		local a = k * math.pi / 2
		local wedge = part(m, name .. "Side", Vector3.new(half, h, half), CFrame.new(base) * rot * CFrame.Angles(0, a, 0) * CFrame.new(half / 2, h / 2, half / 2), color, material, { Class = "CornerWedgePart" })
		wedge.Name = name .. "Side"
	end
	m.Parent = parent
	return m
end
local function sign(parent, text, size: Vector3, cf: CFrame, fg: Color3, bg: Color3)
	local board = part(parent, "Sign", size, cf, bg, M.SmoothPlastic, { CanCollide = false })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(size.X * 40, size.Y * 40)
	gui.LightInfluence = 0
	gui.Parent = board
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = fg
	l.Parent = gui
	local s = Instance.new("UIStroke")
	s.Thickness = 4
	s.Color = rgb(30, 60, 110)
	s.Parent = l
	return board
end

-- ===== Декор =====
local function pine(parent, at: Vector3, h: number)
	local m = Instance.new("Model")
	m.Name = "SnowPine"
	disc(m, "Trunk", h * 0.12, h * 0.3, at + Vector3.new(0, h * 0.15, 0), rgb(110, 75, 50), M.Wood).CFrame = CFrame.new(at + Vector3.new(0, h * 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	local yaw = rand:NextNumber(0, math.pi)
	for i = 0, 2 do
		local w = h * (0.75 - i * 0.18)
		local y = h * (0.22 + i * 0.22)
		pyramid(m, "Leaves", w, h * 0.38, at + Vector3.new(0, y, 0), PINE:Lerp(rgb(70, 130, 110), i * 0.15), M.Grass, yaw + i * 0.4)
		pyramid(m, "SnowCap", w * 0.55, h * 0.18, at + Vector3.new(0, y + h * 0.22, 0), SNOW, M.Snow, yaw + i * 0.4)
	end
	m.Parent = parent
	return m
end
local function crystal(parent, at: Vector3, scale: number, color: Color3)
	local m = Instance.new("Model")
	m.Name = "CrystalCluster"
	for k = 1, 5 do
		local h = scale * rand:NextNumber(5, 11) * (k == 1 and 1.4 or 1)
		local w = scale * rand:NextNumber(1.2, 2)
		local tilt = k == 1 and 0 or rand:NextNumber(0.25, 0.6)
		local dir = rand:NextNumber(0, math.pi * 2)
		local cf = CFrame.new(at) * CFrame.Angles(0, dir, 0) * CFrame.Angles(tilt, 0, 0) * CFrame.new(0, h / 2, 0)
		local c = part(m, "Crystal", Vector3.new(w, h, w), cf * CFrame.Angles(0, math.pi / 4, 0), color, M.Glass, { Transparency = 0.15, CanCollide = k == 1, Reflectance = 0.2 })
		local tip = part(m, "CrystalTip", Vector3.new(w * 0.72, w * 0.9, w * 0.72), cf * CFrame.new(0, h / 2 + w * 0.3, 0) * CFrame.Angles(0, math.pi / 4, math.pi / 4), color:Lerp(rgb(255, 255, 255), 0.4), M.Neon, { CanCollide = false })
		CollectionService:AddTag(tip, "FrozenGlow")
		c.CastShadow = false
	end
	local core = ball(m, "Glow", scale * 2, at + Vector3.new(0, scale * 2, 0), color, M.Neon, { Transparency = 0.6, CanCollide = false })
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 14 * scale
	light.Brightness = 1.6
	light.Parent = core
	m.Parent = parent
	return m
end
local function snowman(parent, at: Vector3, yaw: number)
	local m = Instance.new("Model")
	m.Name = "Snowman"
	local rot = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	ball(m, "Bottom", 6, (rot * CFrame.new(0, 2.6, 0)).Position, SNOW, M.Snow)
	ball(m, "Middle", 4.4, (rot * CFrame.new(0, 6.6, 0)).Position, SNOW, M.Snow)
	ball(m, "Head", 3.2, (rot * CFrame.new(0, 9.8, 0)).Position, SNOW, M.Snow)
	part(m, "Nose", Vector3.new(0.5, 0.5, 1.8), rot * CFrame.new(0, 9.8, -2.2), rgb(255, 140, 40), M.SmoothPlastic, { Class = "WedgePart", CanCollide = false })
	for _, s in ipairs({ -1, 1 }) do
		ball(m, "Eye", 0.45, (rot * CFrame.new(s * 0.6, 10.4, -1.45)).Position, rgb(30, 30, 40), M.SmoothPlastic, { CanCollide = false })
		part(m, "Arm", Vector3.new(0.3, 0.3, 4), rot * CFrame.new(s * 3.2, 7.4, 0) * CFrame.Angles(0, math.pi / 2, s * 0.5), rgb(100, 70, 45), M.Wood, { CanCollide = false })
	end
	part(m, "Scarf", Vector3.new(3.6, 0.7, 3.6), rot * CFrame.new(0, 8.4, 0), rgb(90, 170, 255), M.Fabric, { CanCollide = false })
	disc(m, "HatBrim", 3.4, 0.3, (rot * CFrame.new(0, 11.3, 0)).Position, rgb(40, 50, 80), M.Fabric, { CanCollide = false }).CFrame = rot * CFrame.new(0, 11.3, 0) * CFrame.Angles(0, 0, math.pi / 2)
	disc(m, "HatTop", 2.2, 2, (rot * CFrame.new(0, 12.4, 0)).Position, rgb(40, 50, 80), M.Fabric, { CanCollide = false }).CFrame = rot * CFrame.new(0, 12.4, 0) * CFrame.Angles(0, 0, math.pi / 2)
	m.Parent = parent
	return m
end
local function igloo(parent, at: Vector3, yaw: number)
	local m = Instance.new("Model")
	m.Name = "Igloo"
	ball(m, "Dome", 18, at + Vector3.new(0, 1, 0), SNOW, M.Snow)
	local rot = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	local door = part(m, "Entrance", Vector3.new(7, 6.5, 6.5), rot * CFrame.new(0, 3, -9.5) * CFrame.Angles(0, 0, 0), ICE:Lerp(SNOW, 0.6), M.Snow)
	door.Shape = Enum.PartType.Cylinder
	door.CFrame = rot * CFrame.new(0, 3, -9.5) * CFrame.Angles(0, math.pi / 2, 0)
	disc(m, "Door", 4.6, 0.4, Vector3.zero, rgb(40, 70, 120), M.SmoothPlastic, { CanCollide = false }).CFrame = rot * CFrame.new(0, 3, -12.8) * CFrame.Angles(0, math.pi / 2, 0)
	for row = 0, 2 do
		part(m, "Brick", Vector3.new(17.6, 0.15, 17.6), at + Vector3.new(0, 2.5 + row * 2.8, 0), ICE, M.Ice, { Transparency = 0.7, CanCollide = false, Shape = Enum.PartType.Cylinder })
	end
	m.Parent = parent
	return m
end
local function mountain(parent, at: Vector3, w: number, h: number)
	local m = Instance.new("Model")
	m.Name = "Peak"
	local yaw = rand:NextNumber(0, math.pi)
	pyramid(m, "Rock", w, h, at, ROCK, M.Rock, yaw)
	pyramid(m, "SnowTop", w * 0.45, h * 0.45, at + Vector3.new(0, h * 0.55, 0), SNOW, M.Snow, yaw)
	pyramid(m, "Ridge", w * 0.6, h * 0.55, at + Vector3.new(w * 0.3, 0, w * 0.15), ROCK:Lerp(DEEP, 0.15), M.Rock, yaw + 0.7)
	pyramid(m, "RidgeSnow", w * 0.27, h * 0.25, at + Vector3.new(w * 0.3, h * 0.3, w * 0.15), SNOW, M.Snow, yaw + 0.7)
	m.Parent = parent
	return m
end

-- ===== Ледяной магазин =====
local function shop(parent, at: Vector3)
	local m = Instance.new("Model")
	m.Name = "UpgradeShop"
	disc(m, "Plinth", 22, 0.6, at + Vector3.new(0, 0.3, 2), SNOW, M.Snow)
	disc(m, "PlinthGlow", 22.8, 0.3, at + Vector3.new(0, 0.2, 2), ICE, M.Neon, { CanCollide = false })
	part(m, "Counter", Vector3.new(14, 4, 3), at + Vector3.new(0, 2.6, -2), ICE, M.Ice, { Transparency = 0.15 })
	part(m, "CounterTop", Vector3.new(15, 0.8, 4), at + Vector3.new(0, 5, -2), SNOW, M.Snow)
	part(m, "BackWall", Vector3.new(16, 11, 1), at + Vector3.new(0, 6, -6), DEEP:Lerp(ICE, 0.4), M.Glacier)
	for _, sx in ipairs({ -1, 1 }) do
		part(m, "Pillar", Vector3.new(1.6, 14, 1.6), at + Vector3.new(sx * 8, 7.5, 1.5), ICE, M.Ice, { Transparency = 0.1 })
		crystal(m, at + Vector3.new(sx * 8, 14.5, 1.5), 0.35, rgb(150, 220, 255))
	end
	for i = 1, 9 do
		local c = i % 2 == 0 and rgb(90, 170, 255) or SNOW
		part(m, "Awning", Vector3.new(1.9, 0.6, 11), CFrame.new(at + Vector3.new(-8 + (i - 1) * 2, 14.3, -2)) * CFrame.Angles(math.rad(10), 0, 0), c, M.SmoothPlastic, { CanCollide = false })
		-- Сосульки по краю навеса.
		local len = 1.5 + (i % 3) * 0.8
		part(m, "Icicle", Vector3.new(0.6, len, 0.6), CFrame.new(at + Vector3.new(-8 + (i - 1) * 2, 13.6 - len / 2, 3.6)) * CFrame.Angles(0, math.pi / 4, 0), ICE, M.Glass, { CanCollide = false, Transparency = 0.2 })
	end
	sign(m, "FROZEN SHOP", Vector3.new(15, 3.6, 0.5), CFrame.new(at + Vector3.new(0, 18.5, -2.6)) * CFrame.Angles(0, math.pi, 0), rgb(255, 255, 255), rgb(60, 130, 220))
	local zone = disc(m, "ShopZone", 24, 0.3, at + Vector3.new(0, 0.7, 10), rgb(150, 220, 255), M.SmoothPlastic, { Transparency = 0.55, CanCollide = false })
	zone.Size = Vector3.new(0.3, 24, 24)
	part(m, "VendorAnchor", Vector3.new(1, 1, 1), at + Vector3.new(0, 0.6, -5.5), rgb(255, 255, 255), M.SmoothPlastic, { Transparency = 1, CanCollide = false })
	m.Parent = parent
	return m
end

-- ===== Ледяная арка-портал =====
local function portalArch(parent, name: string, at: Vector3, yaw: number, targetName: string)
	local m = Instance.new("Model")
	m.Name = name .. "Arch"
	local rot = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	for i = 0, 16 do
		local a = math.pi * i / 16
		local p = rot * CFrame.new(math.cos(a) * 11, math.sin(a) * 13 + 1, 0)
		part(m, "ArchBlock", Vector3.new(3.4, 3.4, 3.4), p * CFrame.Angles(0, 0, a), i % 2 == 0 and ICE or SNOW, i % 2 == 0 and M.Ice or M.Snow, { Transparency = i % 2 == 0 and 0.1 or 0 })
	end
	for _, s in ipairs({ -1, 1 }) do
		crystal(m, (rot * CFrame.new(s * 14, 0, 0)).Position, 0.6, rgb(160, 200, 255))
	end
	-- Круглое поле портала (цилиндр, ось — поперёк арки), нижняя часть уходит под землю.
	local field = part(m, name, Vector3.new(1.5, 19, 19), rot * CFrame.new(0, 6.5, 0) * CFrame.Angles(0, math.pi / 2, 0), rgb(170, 210, 255), M.ForceField, { CanCollide = false, Transparency = 0.15, Shape = Enum.PartType.Cylinder })
	field.CanTouch = true
	local board = sign(m, targetName, Vector3.new(14, 3, 0.5), rot * CFrame.new(0, 17.5, 0) * CFrame.Angles(0, math.pi, 0), rgb(255, 255, 255), rgb(70, 120, 210))
	local back = board:FindFirstChildOfClass("SurfaceGui"):Clone() -- надпись видна с обеих сторон
	back.Face = Enum.NormalId.Back
	back.Parent = board
	m.Parent = parent
	return m, field
end

-- ===== Постройка мира =====
function Frozen.Build(world: Instance)
	local model = Instance.new("Model")
	model.Name = "FrozenPeaks"

	-- Остров: снежная плита, ледяная кромка, ледяные глыбы снизу.
	local ground = Instance.new("Model")
	ground.Name = "Ground"
	ground.Parent = model
	disc(ground, "Deck", 330, 6, L(0, -3, 0), SNOW, M.Snow)
	disc(ground, "Rim", 336, 4, L(0, -4.5, 0), ICE, M.Glacier)
	-- Снизу острова — перевёрнутые ледяные пики (как сосульки).
	for k = 1, 30 do
		local a = k / 30 * math.pi * 2 + rand:NextNumber(-0.1, 0.1)
		local r = rand:NextNumber(40, 150)
		local w = rand:NextNumber(30, 60)
		local h = w * rand:NextNumber(1.1, 2.2) * (1.3 - r / 200)
		local spike = pyramid(ground, "Underside", w, h, L(math.cos(a) * r, -5.5 - h, math.sin(a) * r), ICE:Lerp(DEEP, rand:NextNumber(0.1, 0.6)), M.Glacier, rand:NextNumber(0, 3))
		local center = spike:GetBoundingBox()
		spike:PivotTo(center * CFrame.Angles(math.pi, 0, 0))
		for _, d in ipairs(spike:GetChildren()) do
			d.CanCollide = false
		end
	end

	-- Дорожки из льда: от входа к центру, к магазину и к озеру.
	local paths = Instance.new("Model")
	paths.Name = "Paths"
	paths.Parent = model
	part(paths, "PathMain", Vector3.new(18, 0.3, 140), L(0, 0.15, 75), ICE, M.Ice, { Transparency = 0.05 })
	part(paths, "PathShop", Vector3.new(80, 0.3, 14), L(-45, 0.16, 40), ICE, M.Ice, { Transparency = 0.05 })
	disc(paths, "Plaza", 54, 0.32, L(0, 0.16, 0), ICE:Lerp(SNOW, 0.4), M.Ice)
	disc(paths, "PlazaRing", 56, 0.2, L(0, 0.1, 0), rgb(120, 200, 255), M.Neon, { CanCollide = false })

	-- Центр: огромный кристалл.
	crystal(model, L(0, 0, 0), 2.2, rgb(130, 210, 255))

	-- Магазин слева, озеро справа, иглу и снеговики.
	shop(model, L(-85, 0.3, 40))
	local lake = disc(model, "FrozenLake", 70, 0.4, L(75, 0.2, 20), rgb(150, 210, 245), M.Ice, { Transparency = 0.15, Reflectance = 0.25 })
	lake.Name = "FrozenLake"
	disc(model, "LakeEdge", 74, 0.25, L(75, 0.1, 20), SNOW, M.Snow)
	for k = 1, 7 do
		local a = rand:NextNumber(0, math.pi * 2)
		part(model, "LakeCrack", Vector3.new(rand:NextNumber(8, 20), 0.05, 0.25), CFrame.new(L(75 + math.cos(a) * 12, 0.45, 20 + math.sin(a) * 12)) * CFrame.Angles(0, a, 0), rgb(240, 250, 255), M.SmoothPlastic, { CanCollide = false })
	end
	igloo(model, L(-70, 0, -55), math.rad(30))
	snowman(model, L(30, 0, 95), math.rad(160))
	snowman(model, L(-30, 0, 90), math.rad(200))
	snowman(model, L(105, 0, 60), math.rad(220))

	-- Горы по дальнему краю.
	local peaks = Instance.new("Model")
	peaks.Name = "Peaks"
	peaks.Parent = model
	for _, p in ipairs({ { -120, -110, 70, 85 }, { -40, -140, 90, 120 }, { 55, -130, 80, 100 }, { 130, -90, 60, 70 }, { -150, -30, 50, 55 }, { 150, -20, 45, 50 } }) do
		mountain(peaks, L(p[1], 0, p[2]), p[3], p[4])
	end

	-- Ёлки и кристаллы вокруг.
	local decor = Instance.new("Model")
	decor.Name = "Decor"
	decor.Parent = model
	-- Занятые места: центр, магазин и площадка перед ним, проход к магазину, озеро, иглу, вход.
	local placedSpots = { { 0, 0, 34 }, { -85, 40, 26 }, { -85, 66, 20 }, { -45, 45, 14 }, { 75, 20, 42 }, { -70, -55, 16 }, { 0, 110, 14 } }
	local function free(x, z, r)
		if (Vector2.new(x, z)).Magnitude > 150 then
			return false
		end
		if math.abs(x) < 14 and z > 0 then
			return false -- главная дорожка
		end
		for _, s in ipairs(placedSpots) do
			if (Vector2.new(x - s[1], z - s[2])).Magnitude < s[3] + r then
				return false
			end
		end
		return true
	end
	local trees = 0
	for _ = 1, 400 do
		if trees >= 34 then
			break
		end
		local a, r = rand:NextNumber(0, math.pi * 2), rand:NextNumber(60, 148)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if free(x, z, 7) then
			pine(decor, L(x, 0, z), rand:NextNumber(14, 24))
			table.insert(placedSpots, { x, z, 7 })
			trees += 1
		end
	end
	local palette = { rgb(130, 210, 255), rgb(190, 150, 255), rgb(120, 240, 230) }
	local crystals = 0
	for _ = 1, 300 do
		if crystals >= 12 then
			break
		end
		local a, r = rand:NextNumber(0, math.pi * 2), rand:NextNumber(35, 140)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if free(x, z, 6) then
			crystal(decor, L(x, 0, z), rand:NextNumber(0.6, 1.1), palette[crystals % #palette + 1])
			table.insert(placedSpots, { x, z, 6 })
			crystals += 1
		end
	end

	-- Северное сияние: несколько слоёв светящихся лент (Beam) с мягкими краями; переливы делает FrozenFX.
	local aurora = Instance.new("Model")
	aurora.Name = "Aurora"
	aurora.Parent = model
	local anchor = part(aurora, "AuroraAnchor", Vector3.new(1, 1, 1), L(0, 150, -250), rgb(255, 255, 255), M.SmoothPlastic, { Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false })
	for k = 1, 3 do
		local y, z, span = 80 + k * 20, -150 - k * 40, 170 + k * 40
		local a0 = Instance.new("Attachment")
		a0.Parent = anchor
		a0.WorldCFrame = CFrame.new(L(-span, y - 10, z + 30)) * CFrame.Angles(0, math.pi / 2, 0)
		local a1 = Instance.new("Attachment")
		a1.Parent = anchor
		a1.WorldCFrame = CFrame.new(L(span, y + 6, z - 20)) * CFrame.Angles(0, math.pi / 2, 0)
		for layer, w in ipairs({ 16, 30, 46 }) do
			local beam = Instance.new("Beam")
			beam.Name = "AuroraBeam"
			beam.Attachment0, beam.Attachment1 = a0, a1
			beam.Width0, beam.Width1 = w, w * 0.8
			beam.CurveSize0, beam.CurveSize1 = 40 * (k % 2 == 0 and 1 or -1), -35 * (k % 2 == 0 and 1 or -1)
			beam.Segments = 40
			beam.FaceCamera = false
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.Brightness = 2
			beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.55 + layer * 0.12), NumberSequenceKeypoint.new(0.8, 0.55 + layer * 0.12), NumberSequenceKeypoint.new(1, 1) })
			beam:SetAttribute("Band", k)
			beam:SetAttribute("Layer", layer)
			beam.Parent = anchor
		end
	end

	-- Портал обратно в Sky Isles у входа.
	portalArch(model, "PortalToSky", L(0, 0, 152), 0, "TO SKY ISLES")

	-- Монеты: лёд 400 / кристалл 800 / сияние 1600 (CoinTypes.Worlds.Frozen).
	local placed = 0
	for _ = 1, 3000 do
		if placed >= 140 then
			break
		end
		local a, r = rand:NextNumber(0, math.pi * 2), math.sqrt(rand:NextNumber()) * 145
		local x, z = math.cos(a) * r, math.sin(a) * r
		if free(x, z, 3) or (math.abs(x) < 8 and z > 20 and z < 140) then
			placed += 1
			local kind, rarity = CoinTypes.Pick("Frozen", placed)
			local size = CoinTypes.BaseSize.Frozen * kind.Scale
			local coin = part(model, "Coin_" .. placed, Vector3.new(0.5, size, size), L(x, 2.6, z), kind.Color, M.Foil, { Shape = Enum.PartType.Cylinder, CanCollide = false })
			CoinTypes.Mark(coin, "Frozen", kind, rarity)
			CoinTypes.AddGlow(coin, kind.Color, rarity)
			-- Снежинка на обеих сторонах монеты (ось цилиндра — X).
			for _, face in ipairs({ Enum.NormalId.Left, Enum.NormalId.Right }) do
				local gui = Instance.new("SurfaceGui")
				gui.Face = face
				gui.CanvasSize = Vector2.new(100, 100)
				gui.LightInfluence = 0
				local flake = Instance.new("TextLabel")
				flake.BackgroundTransparency = 1
				flake.Size = UDim2.fromScale(1, 1)
				flake.Text = rarity >= 3 and "✦" or "❄"
				flake.TextScaled = true
				flake.Font = Enum.Font.GothamBold
				flake.TextColor3 = Color3.new(1, 1, 1)
				flake.Parent = gui
				gui.Parent = coin
			end
			table.insert(placedSpots, { x, z, 2 })
		end
	end

	-- Страховка: упавшего возвращаем на вход.
	local net = part(model, "SafetyNet", Vector3.new(900, 2, 900), L(0, -140, 0), rgb(255, 255, 255), M.SmoothPlastic, { Transparency = 1, CanCollide = false })
	local spawn = L(0, 4, 126)
	model:SetAttribute("Spawn", spawn)
	net.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and character.PrimaryPart then
			character:PivotTo(CFrame.new(spawn))
		end
	end)

	model.Parent = world
	return model
end

-- Портал в Frozen Peaks на острове Sky Isles.
function Frozen.BuildSkyPortal(sky: Model)
	local deck = sky:WaitForChild("Ground"):WaitForChild("Deck")
	local top = deck.Position.Y + deck.Size.X / 2 -- диск: ось цилиндра вертикальна, высота — Size.X
	-- В конце главной дороги, за радугой: дорога сама ведёт к ледяной арке.
	local at = Vector3.new(deck.Position.X, top, deck.Position.Z - 128)
	local hit = workspace:Raycast(at + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0))
	if hit then
		at = Vector3.new(at.X, hit.Position.Y, at.Z)
	end
	local _, field = portalArch(sky, "PortalToFrozen", at, 0, "FROZEN PEAKS")
	return field
end

return Frozen
